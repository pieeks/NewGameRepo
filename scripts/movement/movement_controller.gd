class_name MovementController
extends Node

enum ControllerType {PLAYER, PATH, GRID}

@export var current_type : ControllerType
@onready var direct_movement: Node = $DirectMovement
@onready var path_movement: Node = $PathMovement
@onready var grid_movement: Node = $GridMovement
@onready var character: CharacterBody2D = get_parent()

func _physics_process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	if not character.is_multiplayer_authority():
		return
	
	# Wenn wir uns in einer Welt befinden, die einen aktiven Fight markiert,
	# soll der Open-World-Character nicht weiter bewegt werden.
	var world := get_tree().current_scene
	if world and current_type == ControllerType.PLAYER:
		# In der TestWorld.gd gibt es is_fight_active; in anderen Szenen existieren keine Characters mit MovementController.
		# Daher können wir hier direkt darauf zugreifen.
		if "is_fight_active" in world and world.is_fight_active:
			return
	
	if current_type == ControllerType.PLAYER:
		direct_movement.process_movement(character, delta)
	elif current_type == ControllerType.PATH:
		path_movement.process_movement(character, delta)
	elif current_type == ControllerType.GRID:
		grid_movement.process_movement(character, delta)
