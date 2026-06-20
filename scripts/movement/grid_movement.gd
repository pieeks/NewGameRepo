extends Node
## Grid-Bewegung: Linksklick setzt Pfad, Bewegung entlang Hex-Punkten.

@export var speed: float = 150.0
@export var arrival_tolerance: float = 2.0
@export var grid_manager_path: NodePath

var current_path: PackedVector2Array = []
var target_point: Vector2 = Vector2.ZERO
var is_moving: bool = false
var grid_manager: GridManager


func _ready() -> void:
	if grid_manager_path != NodePath():
		grid_manager = get_node(grid_manager_path) as GridManager
	else:
		grid_manager = null


func process_movement(character: CharacterBody2D, delta: float) -> void:
	if not is_moving:
		_check_for_input(character)
	if is_moving:
		_move_along_path(character, delta)


func _check_for_input(character: CharacterBody2D) -> void:
	if Input.is_action_just_pressed("left_click") and grid_manager:
		var path := grid_manager.get_action_path(character.global_position, character.get_global_mouse_position())
		if path.size() > 1:
			current_path = path
			current_path.remove_at(0)
			target_point = current_path[0]
			is_moving = true
			character.net_anim_name = &"walk"


func _move_along_path(character: CharacterBody2D, _delta: float) -> void:
	var direction := character.global_position.direction_to(target_point)
	character.velocity = direction * speed
	character.move_and_slide()
	if character.global_position.distance_to(target_point) < arrival_tolerance:
		current_path.remove_at(0)
		if current_path.size() > 0:
			target_point = current_path[0]
		else:
			_stop_movement(character)


func _stop_movement(character: CharacterBody2D) -> void:
	is_moving = false
	character.velocity = Vector2.ZERO
	character.net_anim_name = &"idle"
