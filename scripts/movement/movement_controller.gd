extends Node

enum ControllerType {PLAYER, AI}

@export var current_type : ControllerType
@onready var direct_movement: Node = $DirectMovement
@onready var ai_movement: Node = $AIMovement
@onready var character: CharacterBody2D = get_parent()

func _physics_process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	if not character.is_multiplayer_authority():
		return
	
	if current_type == ControllerType.PLAYER:
		direct_movement.process_movement(character, delta)
	elif current_type == ControllerType.AI:
		ai_movement.process_movement(character, delta)
