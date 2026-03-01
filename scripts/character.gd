extends CharacterBody2D

@onready var camera_2d: Camera2D = $Camera2D
@onready var animation_player: AnimationPlayer = get_node_or_null("CharacterVisuals/AnimationPlayer")

# Netzwerk-sichtbarer Animationszustand (wird später repliziert).
# Interner Speicher (_net_anim_name) + Property mit Setter/Getters.
var _net_anim_name: StringName = StringName()

var net_anim_name: StringName:
	set(value):
		# Nichts tun, wenn sich der Wert nicht ändert.
		if _net_anim_name == value:
			return
		
		var old_value := _net_anim_name
		_net_anim_name = value
		
		# Debug: Anzeigen, wann und wo sich der Netz-Animationszustand ändert.
		var peer_id := multiplayer.get_unique_id() if multiplayer else -1
		print("Character(", name, ") peer=", peer_id, " is_authority=", is_multiplayer_authority(),
			" net_anim_name: ", old_value, " -> ", value)
		
		# Wenn ein gültiger Name gesetzt ist, passende Animation abspielen.
		if value != StringName():
			play_animation(String(value))
	get:
		return _net_anim_name


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	if is_multiplayer_authority():
		camera_2d.make_current()
		z_index = 1
	else:
		camera_2d.enabled = false
		z_index = 0


func play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		# Fallback: Nur ein Log ausgeben, bis echte Animationen vorhanden sind.
		print("Character: Animation '", anim_name, "' nicht gefunden oder kein AnimationPlayer vorhanden.")
