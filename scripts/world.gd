extends Node2D

@export var player_scene: PackedScene
@export var fight_scene: PackedScene
@export var fight_menu_scene: PackedScene

@onready var player_container: Node2D = $PlayerContainer
@onready var ui_layer: CanvasLayer = $UILayer

var fight_menu: Control

var is_fight_active: bool = false
# Tracking, welche Peers aktuell in einem Fight sind (für Movement-Block in der Open World)
var peers_in_fight: = {}


func _ready() -> void:
	print("!!! testWorld.gd: Mein _ready() Funktion Läuft!")
	GameManager.notify_world_is_ready.call_deferred()


func spawn_character_to_stage(peer_id: int, data: Dictionary) -> void:
	if player_scene == null: 
		print("testWorld: Fehler - player_scene is nicht zugewiesen")
		return
	
	print("testWorld: -> Setze Character ", data.get("name", "Unbekannt"))
	
	var player_instance : Node = player_scene.instantiate()
	
	player_instance.name = str(peer_id)
	player_instance.set_multiplayer_authority(peer_id)
	player_instance.position = Vector2(randf_range(-150, 150), randf_range(-150, 150))
	player_container.add_child(player_instance, true)


func remove_character_from_stage(peer_id: int) -> void:
	var player_node_name: String = str(peer_id)
	var node_to_remove: Node = player_container.get_node_or_null(player_node_name)
	
	if node_to_remove:
		print("testWorld: Spieler: ", peer_id, "hat das Spiel verlassen")
		node_to_remove.queue_free()
	else:
		print("testWorld: Konnte keinen Charcter für ID: ", peer_id, " finden.") 


func start_fight_for_peer(peer_id: int) -> void:
	# Fight-Start immer vom Host aus steuern und dann per RPC
	# auf alle Peers (inkl. Host selbst) spiegeln.
	if not multiplayer.is_server():
		return
	
	peers_in_fight[peer_id] = true
	rpc_start_fight.rpc(peer_id)


func end_fight_for_peer(peer_id: int) -> void:
	# Fight-Ende immer vom Host aus steuern
	if not multiplayer.is_server():
		return
	
	if peers_in_fight.has(peer_id):
		peers_in_fight[peer_id] = false
	
	rpc_end_fight_for_peer.rpc(peer_id)


func end_fight() -> void:
	# Fight-Ende ebenfalls nur vom Host anstoßen
	if not multiplayer.is_server():
		return
	
	rpc_end_fight.rpc()


@rpc("any_peer", "call_local")
func rpc_start_fight(owner_peer_id: int) -> void:
	if fight_scene == null:
		print("testWorld: Fehler - fight_scene ist nicht gesetzt.")
		return

	var fight_instance: Node2D = fight_scene.instantiate()
	fight_instance.name = "Fight_%d" % owner_peer_id
	# Peer-ID in die Fight-Szene übergeben, falls das Script sie unterstützt.
	if fight_instance.has_method("set_owner_peer_id"):
		fight_instance.set_owner_peer_id(owner_peer_id)
	$FightLayer.add_child(fight_instance)
	is_fight_active = true
	# Sicherstellen, dass auf allen Peers der passende Spieler
	# als "im Fight" markiert wird, damit sein Open-World-Movement stoppt.
	peers_in_fight[owner_peer_id] = true
	print("testWorld: Test-Fight wurde instanziert (RPC).")


func is_peer_in_fight(peer_id: int) -> bool:
	return peers_in_fight.has(peer_id) and peers_in_fight[peer_id]


@rpc("any_peer")
func rpc_request_start_fight() -> void:
	# Wird von Clients aufgerufen; nur der Host verarbeitet diese Anfrage.
	if not multiplayer.is_server():
		return
	
	var requester_id := multiplayer.get_remote_sender_id()
	print("testWorld: Start-Fight-Request von Peer ", requester_id)
	start_fight_for_peer(requester_id)


@rpc("any_peer")
func rpc_request_join_fight() -> void:
	if not multiplayer.is_server():
		return
	
	var requester_id := multiplayer.get_remote_sender_id()
	print("world: Join-Fight-Request von Peer ", requester_id)
	
	for child in $FightLayer.get_children():
		if child.has_method("add_participant"):
			if child.has_method("has_participant") and child.has_participant(requester_id):
				print("world: Peer ", requester_id, " ist bereits Teilnehmer.")
				return
			
			var owner_id := 0
			if child.has_method("get_owner_peer_id"):
				owner_id = child.get_owner_peer_id()
			
			# Nur RPC auslösen – add_participant (und ggf. Spawn) passiert in rpc_sync_join_fight auf allen Peers
			rpc_sync_join_fight.rpc(owner_id, requester_id)
			print("world: Peer ", requester_id, " als Teilnehmer hinzugefügt.")
			return
	
	print("world: Kein aktiver Fight zum Beitreten gefunden.")


@rpc("any_peer", "call_local")
func rpc_sync_join_fight(owner_peer_id: int, peer_id: int) -> void:
	# Auf allen Peers: Teilnehmehrliste und Movement-Block aktualisieren
	peers_in_fight[peer_id] = true
	
	for child in $FightLayer.get_children():
		if child.has_method("get_owner_peer_id") and child.get_owner_peer_id() == owner_peer_id:
			child.add_participant(peer_id)
			return


@rpc("any_peer")
func rpc_request_end_fight_for_peer() -> void:
	# Wird von Clients aufgerufen; nur der Host verarbeitet diese Anfrage.
	if not multiplayer.is_server():
		return
	
	var requester_id := multiplayer.get_remote_sender_id()
	print("testWorld: End-Fight-Request von Peer ", requester_id)
	end_fight_for_peer(requester_id)


@rpc("any_peer", "call_local")
func rpc_end_fight() -> void:
	if $FightLayer.get_child_count() == 0:
		return
	for child in $FightLayer.get_children():
		child.queue_free()
	is_fight_active = false
	peers_in_fight.clear()


@rpc("any_peer", "call_local")
func rpc_end_fight_for_peer(peer_id: int) -> void:
	# Konkreten Fight für einen bestimmten Peer schließen
	for child in $FightLayer.get_children():
		if child.has_method("get_owner_peer_id") and child.get_owner_peer_id() == peer_id:
			child.queue_free()
	
	if peers_in_fight.has(peer_id):
		peers_in_fight[peer_id] = false
	
	if $FightLayer.get_child_count() == 0:
		is_fight_active = false
	# Welt-Kamera des lokalen Spielers wieder aktivieren
	var my_id: int = multiplayer.get_unique_id()
	var my_char: Node = player_container.get_node_or_null(str(my_id))
	if my_char:
		var cam: Camera2D = my_char.get_node_or_null("Camera2D")
		if cam:
			cam.make_current()
	print("testWorld: Fight beendet (RPC).")


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("Menu"): 
		if $UILayer/CenterContainer/Lobby.visible == true:
			$UILayer/CenterContainer/Lobby.visible = false
		else:
			$UILayer/CenterContainer/Lobby.visible = true
	
	# Taste F (oder die zugeordnete Action) öffnet das Kampf-Menü,
	# anstatt direkt einen Kampf zu starten/beenden.
	if event.is_action_pressed("action_button"):
		_toggle_fight_menu()


func _toggle_fight_menu() -> void:
	if fight_menu and is_instance_valid(fight_menu):
		fight_menu.queue_free()
		fight_menu = null
		return
	
	if fight_menu_scene == null:
		print("testWorld: fight_menu_scene ist nicht gesetzt.")
		return
	
	fight_menu = fight_menu_scene.instantiate()
	ui_layer.add_child(fight_menu)
	
	# Signale verbinden
	if fight_menu.has_signal("start_fight_pressed"):
		fight_menu.start_fight_pressed.connect(_on_fight_menu_start_fight)
	if fight_menu.has_signal("join_fight_pressed"):
		fight_menu.join_fight_pressed.connect(_on_fight_menu_join_fight)
	if fight_menu.has_signal("leave_fight_pressed"):
		fight_menu.leave_fight_pressed.connect(_on_fight_menu_leave_fight)


func _on_fight_menu_start_fight() -> void:
	# Menü schließen und Kampf starten
	if fight_menu and is_instance_valid(fight_menu):
		fight_menu.queue_free()
		fight_menu = null
	
	if multiplayer.is_server():
		# Host startet direkt einen Fight für sich selbst
		var my_id := multiplayer.get_unique_id()
		start_fight_for_peer(my_id)
	else:
		# Client sendet nur eine Anfrage an den Host,
		# der dann einen neuen Fight für diesen Peer startet.
		rpc_id(1, "rpc_request_start_fight")


func _on_fight_menu_join_fight() -> void:
	#Menü schließen
	if fight_menu and is_instance_valid(fight_menu):
		fight_menu.queue_free()
		fight_menu = null
	
	var my_id := multiplayer.get_unique_id()

	if multiplayer.is_server():
		print("world: Host móchte einem Fight beitreten (Peer ID: ", my_id, ")")
	else:
		#Client: Anfrage an den Host senden
		rpc_id(1, "rpc_request_join_fight")


func _on_fight_menu_leave_fight() -> void:
	# Menü schließen
	if fight_menu and is_instance_valid(fight_menu):
		fight_menu.queue_free()
		fight_menu = null
	
	var my_id := multiplayer.get_unique_id()
	if multiplayer.is_server():
		# Host beendet eigenen Fight direkt
		end_fight_for_peer(my_id)
	else:
		# Client sendet nur eine Anfrage an den Host,
		# der dann den Fight für diesen Peer beendet.
		rpc_id(1, "rpc_request_end_fight_for_peer")
