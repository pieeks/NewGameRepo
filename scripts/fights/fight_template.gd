extends Node2D

@onready var grid_manager: Node2D = $GridManager
@onready var player_container: Node = $PlayerContainer

@export var battle_character_scene: PackedScene
@export var owner_peer_id: int = 0

var participants: Array[int] = []

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
	
	# Character-Kamera bleibt an – character.gd setzt für Authority make_current(), sonst enabled = false
	
	_configure_battle_character(character)


func _configure_battle_character(character: CharacterBody2D) -> void:
	# Sicherstellen, dass der Character im Grid-Modus läuft
	character.movement_type = MovementController.ControllerType.GRID
	
	var controller: MovementController = character.get_node_or_null("MovementController")
	if controller == null:
		return
	
	controller.current_type = MovementController.ControllerType.GRID
	
	var grid_movement: Node = controller.get_node_or_null("GridMovement")
	if grid_movement == null:
		return
	
	# Direkt den GridManager setzen (Pfad ist hier fix die lokale Instanz)
	grid_movement.grid_manager = grid_manager
