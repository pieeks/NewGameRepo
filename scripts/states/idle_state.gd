extends State

func _ready() -> void:
	if state_name == StringName():
		state_name = &"Idle"


func enter(_previous_state) -> void:
	if character:
		character.net_anim_name = &"idle"


func physics_update(_delta: float) -> void:
	if character.velocity.length() > 0.1:
		#Wir rufen den Manager an und fordern den Wechsel
		state_controller.request_state_change(&"Move")
