extends "res://scripts/states/state.gd"


func _ready() -> void:
	if state_name == StringName():
		state_name = &"Move"


func enter(previous_state) -> void:
	# Beim Betreten sofort eine passende Laufanimation wählen
	_update_animation()


func physics_update(_delta: float) -> void:
	_update_animation()


func _update_animation() -> void:
	if not character:
		return
	
	var v: Vector2 = character.velocity
	if v.length() <= 0.1:
		# StateController entscheidet normalerweise, aber hier können wir
		# einen expliziten Rückfall zu Idle anfragen.
		if state_controller and state_controller.has_method("request_state_change"):
			state_controller.request_state_change(&"Idle")
		return
	
	var anim: String = "run_right"
	if abs(v.x) >= abs(v.y):
		# Horizontal dominiert
		anim = "run_right" if v.x >= 0.0 else "run_left"
	else:
		# Vertikal dominiert
		anim = "run_down" if v.y >= 0.0 else "run_up"
	
	character.play_animation(anim)
