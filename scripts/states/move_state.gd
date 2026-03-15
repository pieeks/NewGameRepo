extends State


func _ready() -> void:
	if state_name == StringName():
		state_name = &"Move"


func enter(_previous_state) -> void:
	_update_animation()


func physics_update(_delta: float) -> void:
	if character.velocity.length() <= 0.1:
		state_controller.request_state_change(&"Idle")
		return
	_update_animation()


func _update_animation() -> void:
	if not character:
		return
	
	var v: Vector2 = character.velocity
	if v.length() <= 0.1:
		if state_controller and state_controller.has_method("request_state_change"):
			state_controller.request_state_change(&"Idle")
		return
	var anim: String = "run_right"
	if abs(v.x) >= abs(v.y):
		anim = "run_right" if v.x >= 0.0 else "run_left"
	else:
		anim = "run_down" if v.y >= 0.0 else "run_up"
	character.net_anim_name = StringName(anim)
