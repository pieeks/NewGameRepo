extends CharacterBody2D

@onready var camera_2d: Camera2D = $Camera2D



func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	if is_multiplayer_authority():
		camera_2d.make_current()
		z_index = 1
	else:
		camera_2d.enabled = false
		z_index = 0
