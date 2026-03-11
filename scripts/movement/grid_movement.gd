extends Node

@export var speed: float = 150.0
@export var arrival_tolerance: float = 2.0 # Wie nah muss er am Punkt sein?

var current_path: PackedVector2Array = []
var target_point: Vector2 = Vector2.ZERO
var is_moving: bool = false
var grid_manager: Node2D

func _ready() -> void:
	# Wir suchen den GridManager einmalig in der Kampf-Szene
	grid_manager = get_tree().current_scene.find_child("GridManager")

# Dies wird vom MovementController in jedem Frame aufgerufen, wenn current_type == GRID
func process_movement(character: CharacterBody2D, delta: float) -> void:
	# 1. Input-Abfrage (Nur wenn wir noch nicht laufen)
	if not is_moving:
		_check_for_input(character)
	
	# 2. Logik für die eigentliche Bewegung
	if is_moving:
		_move_along_path(character, delta)

func _check_for_input(character: CharacterBody2D) -> void:
	# Wir nutzen die Standard-Input-Abfrage für den Linksklick
	if Input.is_action_just_pressed("left_click"):
		var mouse_pos = character.get_global_mouse_position()
		
		if grid_manager:
			# Wir holen uns die Liste der Waben-Mittelpunkte
			var path = grid_manager.get_action_path(character.global_position, mouse_pos)
			
			if path.size() > 1:
				current_path = path
				current_path.remove_at(0) # Aktuelle Position überspringen
				target_point = current_path[0]
				is_moving = true
				character.net_anim_name = &"walk" # Animation via Character.gd Setter

func _move_along_path(character: CharacterBody2D, _delta: float) -> void:
	# Richtung zum nächsten Waben-Mittelpunkt
	var direction = character.global_position.direction_to(target_point)
	
	# Wir nutzen velocity und move_and_slide für saubere Physik/Kollision
	character.velocity = direction * speed
	character.move_and_slide()
	
	# Haben wir den aktuellen Mittelpunkt erreicht?
	if character.global_position.distance_to(target_point) < arrival_tolerance:
		current_path.remove_at(0) # Punkt als erledigt markieren
		
		if current_path.size() > 0:
			target_point = current_path[0] # Nächster Punkt im Hex-Pfad
		else:
			# Ziel der gesamten Reise erreicht
			_stop_movement(character)

func _stop_movement(character: CharacterBody2D) -> void:
	is_moving = false
	character.velocity = Vector2.ZERO
	character.net_anim_name = &"idle" # Zurück in den Idle-Zustand
