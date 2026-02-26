extends "res://scripts/states/state.gd"


func _ready() -> void:
	if state_name == StringName():
		state_name = &"Idle"


func enter(previous_state) -> void:
	if character:
		character.play_animation("idle")


func physics_update(_delta: float) -> void:
	# Idle-State selbst ändert nichts an der Bewegung,
	# er reagiert nur auf Statuswechsel durch den StateController.
	pass
