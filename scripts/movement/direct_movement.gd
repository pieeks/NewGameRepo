extends Node
## Top-Down-Freemove: Input-Vektor, velocity, move_and_slide.

@export var move_speed: float = 200.0

func process_movement(character: CharacterBody2D, _delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	character.velocity = input_dir * move_speed
	character.move_and_slide()
