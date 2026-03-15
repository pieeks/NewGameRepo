class_name State
extends Node
## Basis für Idle/Move etc.; [method enter]/[method exit]/[method physics_update].

var character: CharacterBody2D
var state_controller: Node
var state_name: StringName


func enter(_previous_state) -> void:
	pass


func exit(_next_state) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
