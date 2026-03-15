extends Node2D

signal fight_ready_to_remove(owner_peer_id: int)

@onready var grid_manager: Node2D = $GridManager
@onready var player_container: Node = $PlayerContainer
@onready var npc_container: Node = $NpcContainer

@export var battle_character_scene: PackedScene
@export var owner_peer_id: int = 0

var participants: Array[int] = []
var _is_ending: bool = false


func _sync_player_container_visibility() -> void:
	for child in player_container.get_children():
		child.visible = visible


func _ready() -> void:
	var my_id := multiplayer.get_unique_id()
	print("TestFight: _ready() auf Peer", my_id, " owner_peer_id =", owner_peer_id)

	# Owner als ersten Teilnehmer eintragen
	if owner_peer_id != 0 and not participants.has(owner_peer_id):
		participants.append(owner_peer_id)

	# Sichtbarkeit: nur wer in participants ist, sieht den Fight (Kamera kommt vom Character)
	if participants.has(my_id):
		visible = true
	else:
		visible = false
	_sync_player_container_visibility()

	if owner_peer_id == 0:
		owner_peer_id = my_id

	# Battle-Character nur vom Host spawnen (für Owner; Joiner kommen in add_participant)
	if multiplayer.is_server():
		_spawn_battle_character(owner_peer_id)


func set_owner_peer_id(peer_id: int) -> void:
	owner_peer_id = peer_id


func get_owner_peer_id() -> int:
	return owner_peer_id


func set_participants(participants_list: Array) -> void:
	participants.clear()
	for p in participants_list:
		participants.append(int(p))


func has_participant(peer_id: int) -> bool:
	return participants.has(peer_id)


func add_participant(peer_id: int) -> void:
	if not participants.has(peer_id):
		participants.append(peer_id)
	print("fight_template: add_participant(", peer_id, "), participants jetzt: ", participants)
	# Wer gerade beitritt, soll sofort Fight sehen (Kamera übernimmt der Character beim Spawn)
	if peer_id == multiplayer.get_unique_id():
		visible = true
		_sync_player_container_visibility()
	
	# Nur Host spawnt Battle-Character; einen Frame verzögern, damit Client die Fight-Szene hat (Join-in-Progress).
	if multiplayer.is_server() and peer_id != owner_peer_id:
		call_deferred("_spawn_battle_character", peer_id)


func _spawn_battle_character(peer_id: int) -> void:
	if battle_character_scene == null:
		push_error("FightManager: battle_character_scene ist nicht gesetzt.")
		return
	
	print("TestFight: Spawne Battle-Character für Peer", peer_id, " (Host-ID:", multiplayer.get_unique_id(), ")")
	var character: CharacterBody2D = battle_character_scene.instantiate()
	
	# Authority und Name auf den Peer setzen, für den dieser Fight gedacht ist.
	character.name = str(peer_id)
	character.set_multiplayer_authority(peer_id)
	
	# Startposition grob in die Nähe des Grids legen
	character.global_position = grid_manager.global_position
	
	player_container.add_child(character)
	
	# Character-Kamera bleibt an – character_template.gd setzt für Authority make_current(), sonst enabled = false
	
	_configure_battle_character(character, peer_id)


func _configure_battle_character(character: CharacterBody2D, controlled_peer_id: int) -> void:
	# Sicherstellen, dass der Character im Grid-Modus läuft
	character.movement_type = MovementController.ControllerType.GRID
	character.controlled_by_peer_id = controlled_peer_id
	
	var controller: MovementController = character.get_node_or_null("MovementController")
	if controller == null:
		return
	
	controller.current_type = MovementController.ControllerType.GRID
	
	var grid_movement: Node = controller.get_node_or_null("GridMovement")
	if grid_movement == null:
		return
	
	# Direkt den GridManager setzen (Pfad ist hier fix die lokale Instanz)
	grid_movement.grid_manager = grid_manager


const _FREE_DELAY_SECONDS: float = 0.15

func _delayed_free_node(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


func request_end_fight() -> void:
	if not multiplayer.is_server():
		return
	if _is_ending:
		return
	_is_ending = true
	rpc_notify_fight_ending.rpc()
	# Freigabe verzögern, damit die Multiplayer-Engine keine get_node/get_cached_object
	# auf bereits freigegebene Nodes ausführt (vermeidet C++-Fehler beim Kampfende).
	for child in npc_container.get_children():
		get_tree().create_timer(_FREE_DELAY_SECONDS).timeout.connect(_delayed_free_node.bind(child))
	for child in player_container.get_children():
		get_tree().create_timer(_FREE_DELAY_SECONDS).timeout.connect(_delayed_free_node.bind(child))
	# Erste Prüfung erst nach der Verzögerung, damit Container dann leer sind.
	var timer: SceneTreeTimer = get_tree().create_timer(_FREE_DELAY_SECONDS + 0.05)
	timer.timeout.connect(_check_containers_empty_and_emit_ready)


func _check_containers_empty_and_emit_ready() -> void:
	if not multiplayer.is_server():
		return
	if player_container.get_child_count() > 0 or npc_container.get_child_count() > 0:
		var timer: SceneTreeTimer = get_tree().create_timer(0.05)
		timer.timeout.connect(_check_containers_empty_and_emit_ready)
		return
	fight_ready_to_remove.emit(owner_peer_id)


func request_leave_peer(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if not has_participant(peer_id):
		return
	participants.erase(peer_id)
	var char_node: Node = player_container.get_node_or_null(str(peer_id))
	if char_node:
		char_node.call_deferred("queue_free")
	_notify_fight_manager_peer_left(peer_id)
	if participants.size() == 0 and npc_container.get_child_count() == 0:
		request_end_fight()


func _notify_fight_manager_peer_left(peer_id: int) -> void:
	var world: Node = get_parent().get_parent()
	var fm: Node = world.get_node_or_null("FightManager")
	if fm != null and fm.has_method("notify_peer_left_fight"):
		fm.notify_peer_left_fight(peer_id)


@rpc("any_peer", "call_local")
func rpc_notify_fight_ending() -> void:
	visible = false
	_sync_player_container_visibility()
