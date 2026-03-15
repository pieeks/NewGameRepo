extends CharacterBody2D
## Spieler- und Battle-Character: Bewegung (Direct/Path/Grid), Kamera, Animation.
## Unter FightTemplate wird automatisch Grid-Modus und Sichtbarkeit an die Fight-Node gekoppelt.

@onready var camera_2d: Camera2D = $Camera2D
@onready var animation_player: AnimationPlayer = get_node_or_null("CharacterVisuals/AnimationPlayer")
@onready var movement_controller: Node2D = $MovementController

@export var movement_type: MovementController.ControllerType
@export var free_camera_pan_speed: float = 400.0
@export var is_player_controlled: bool = true
@export var controlled_by_peer_id: int = -1

var _grid_camera_world_pos: Vector2 = Vector2.ZERO
var _net_anim_name: StringName = StringName()

var net_anim_name: StringName:
	set(value):
		if _net_anim_name == value:
			return
		_net_anim_name = value
		if value != StringName():
			play_animation(String(value))
	get:
		return _net_anim_name


func _enter_tree() -> void:
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())


func _ready() -> void:
	if is_player_controlled and is_multiplayer_authority():
		camera_2d.make_current()
		z_index = 1
	else:
		camera_2d.enabled = false
		z_index = 0
	
	movement_controller.current_type = movement_type
	_configure_for_fight_if_needed()


func _configure_for_fight_if_needed() -> void:
	var container := get_parent()
	if container == null:
		return
	var fight_root := container.get_parent()
	if fight_root == null or not fight_root.has_method("get_owner_peer_id"):
		return
	var grid_mgr := fight_root.get_node_or_null("GridManager") as Node2D
	if grid_mgr == null:
		return
	visible = fight_root.visible
	movement_type = MovementController.ControllerType.GRID
	movement_controller.current_type = MovementController.ControllerType.GRID
	var grid_movement_node := movement_controller.get_node_or_null("GridMovement")
	if grid_movement_node != null:
		grid_movement_node.set("grid_manager", grid_mgr)
	_grid_camera_world_pos = global_position


func get_controlled_peer_id() -> int:
	if controlled_by_peer_id >= 0:
		return controlled_by_peer_id
	if name.is_valid_int():
		return name.to_int()
	return -1


func _process(delta: float) -> void:
	if not is_player_controlled or not is_multiplayer_authority():
		return
	if not camera_2d or not camera_2d.is_current():
		return
	
	if movement_controller.current_type == MovementController.ControllerType.GRID:
		if _grid_camera_world_pos == Vector2.ZERO:
			_grid_camera_world_pos = global_position
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
			_grid_camera_world_pos += move.normalized() * free_camera_pan_speed * delta
		camera_2d.global_position = _grid_camera_world_pos
	else:
		camera_2d.position = Vector2.ZERO


func play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		print("Character: Animation '", anim_name, "' nicht gefunden oder kein AnimationPlayer vorhanden.")
