extends Node2D

@onready var grid_manager: Node2D = $GridManager
@onready var fight_camera: Camera2D = $FightCamera

@export var battle_character_scene: PackedScene
@export var owner_peer_id: int = 0

@export var camera_move_speed: float = 400.0
@export var camera_zoom_step: float = 0.1
@export var camera_min_zoom: float = 0.5
@export var camera_max_zoom: float = 2.0


func _ready() -> void:
	var my_id := multiplayer.get_unique_id()
	print("TestFight: _ready() auf Peer", my_id, " owner_peer_id =", owner_peer_id)
	
	# Nur der Besitzer-Peer soll diesen Fight visuell sehen und steuern.
	if my_id != owner_peer_id:
		visible = false
		return
	
	# Nur der Besitzer-Peer aktiviert die Kamera und spawnt seinen Battle-Character.
	if fight_camera:
		fight_camera.make_current()
	
	if owner_peer_id == 0:
		owner_peer_id = my_id
	
	_spawn_battle_character(owner_peer_id)


func set_owner_peer_id(peer_id: int) -> void:
	owner_peer_id = peer_id


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
	
	add_child(character)
	
	# Charakter-Kamera im Fight deaktivieren, FightCamera bleibt zuständig
	var char_cam: Camera2D = character.get_node_or_null("Camera2D")
	if char_cam:
		char_cam.enabled = false
	
	# Sicherstellen, dass nach dem Spawn die Fight-Kamera aktiv bleibt
	if fight_camera:
		fight_camera.make_current()
	
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


func _process(delta: float) -> void:
	if not fight_camera:
		return
	
	var move := Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		move.x -= 1.0
	if Input.is_action_pressed("move_right"):
		move.x += 1.0
	if Input.is_action_pressed("move_up"):
		move.y -= 1.0
	if Input.is_action_pressed("move_down"):
		move.y += 1.0
	
	if move != Vector2.ZERO:
		move = move.normalized() * camera_move_speed * delta
		fight_camera.position += move
