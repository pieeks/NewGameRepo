extends Node2D

@export var player_scene: PackedScene
@export var fight_scene: PackedScene

@onready var player_container: Node2D = $PlayerContainer

var is_fight_active: bool = false


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


func start_test_fight() -> void:
	if fight_scene == null:
		print("testWorld: Fehler - fight_scene ist nicht gesetzt.")
		return
	
	if $FightLayer.get_child_count() > 0:
		print("testWorld: Fight läuft bereits.")
		return
	
	var fight_instance: Node2D = fight_scene.instantiate()
	$FightLayer.add_child(fight_instance)
	is_fight_active = true
	print("testWorld: Test-Fight wurde instanziert.")


func end_test_fight() -> void:
	if $FightLayer.get_child_count() == 0:
		return
	for child in $FightLayer.get_children():
		child.queue_free()
	is_fight_active = false
	# Welt-Kamera des lokalen Spielers wieder aktivieren
	var my_id: int = multiplayer.get_unique_id()
	var my_char: Node = player_container.get_node_or_null(str(my_id))
	if my_char:
		var cam: Camera2D = my_char.get_node_or_null("Camera2D")
		if cam:
			cam.make_current()
	print("testWorld: Fight beendet.")


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("Menu"): 
		if $UILayer/CenterContainer/Lobby.visible == true:
			$UILayer/CenterContainer/Lobby.visible = false
		else:
			$UILayer/CenterContainer/Lobby.visible = true
	
	if event.is_action_pressed("action_button"):
		if is_fight_active:
			end_test_fight()
		else:
			start_test_fight()
