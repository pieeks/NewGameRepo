class_name MovementController
extends Node
## Wählt je nach [member current_type] Direct/Path/Grid-Movement; stoppt PLAYER wenn Peer im Fight.

enum ControllerType {PLAYER, PATH, GRID}

@export var current_type: ControllerType
@onready var direct_movement: Node = $DirectMovement
@onready var path_movement: Node = $PathMovement
@onready var grid_movement: Node = $GridMovement
@onready var character: CharacterBody2D = get_parent()

func _physics_process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	if not character.is_multiplayer_authority():
		return
	var world := get_tree().current_scene
	if world and current_type == ControllerType.PLAYER:
		if world.has_method("is_peer_in_fight"):
			var peer_id: int = character.get_controlled_peer_id()
			if world.is_peer_in_fight(peer_id):
				return
	
	if current_type == ControllerType.PLAYER:
		direct_movement.process_movement(character, delta)
	elif current_type == ControllerType.PATH:
		path_movement.process_movement(character, delta)
	elif current_type == ControllerType.GRID:
		grid_movement.process_movement(character, delta)
