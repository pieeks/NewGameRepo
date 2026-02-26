extends CharacterBody2D

@onready var camera_2d: Camera2D = $Camera2D
@onready var animation_player: AnimationPlayer = get_node_or_null("CharacterVisuals/AnimationPlayer")


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	if is_multiplayer_authority():
		camera_2d.make_current()
		z_index = 1
	else:
		camera_2d.enabled = false
		z_index = 0


func play_animation(name: String) -> void:
	if animation_player and animation_player.has_animation(name):
		animation_player.play(name)
	else:
		# Fallback: Nur ein Log ausgeben, bis echte Animationen vorhanden sind.
		print("Character: Animation '", name, "' nicht gefunden oder kein AnimationPlayer vorhanden.")
