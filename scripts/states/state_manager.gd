extends Node2D

@onready var character: CharacterBody2D = get_parent()

var current_state
var states: Dictionary = {}


func _ready() -> void:
	# Alle Child-Nodes, die CharacterState sind, registrieren
	for child in get_children():
		# child soll von state.gd erben, aber wir verwenden hier
		# keine strikte Typprüfung, um Parse-Fehler zu vermeiden.
		if "state_name" in child:
			var state = child
			if state.state_name == StringName():
				state.state_name = StringName(state.name)
			
			states[state.state_name] = state
			state.character = character
			state.state_controller = self
	
	# Debug: Übersicht, welche States registriert wurden.
	print("StateManager: registered states = ", states.keys())
	
	# Standard-Startzustand: "Idle", falls vorhanden
	if states.has(&"Idle"):
		_change_state(&"Idle")
	elif states.size() > 0:
		var any_state_name: StringName = states.keys()[0]
		_change_state(any_state_name)


func _physics_process(delta: float) -> void:
	# Nur im Multiplayer laufen lassen (Singleplayer = Host hat auch einen Peer).
	if not multiplayer.has_multiplayer_peer():
		return
	# Im Multiplayer: nur die Authority darf den State/Animation steuern.
	if not character.is_multiplayer_authority():
		return
	
	# Bestimme gewünschten State anhand des Charakter-Zustands (hier: Geschwindigkeit)
	var speed: float = character.velocity.length()
	var desired_state: StringName = &"Idle"
	
	if speed > 0.1:
		desired_state = &"Move"
	

	if current_state == null or current_state.state_name != desired_state:
		print("StateManager: changing state on authority=", character.is_multiplayer_authority(),
			" from=", current_state.state_name if current_state else "null",
			" to=", desired_state)
		_change_state(desired_state)
	
	if current_state:
		current_state.physics_update(delta)


func request_state_change(target_state_name: StringName) -> void:
	_change_state(target_state_name)


func _change_state(target_state_name: StringName) -> void:
	if not states.has(target_state_name):
		return
	
	var new_state = states[target_state_name]
	var previous_state = current_state
	
	if current_state == new_state:
		return
	
	if current_state:
		current_state.exit(new_state)
	
	current_state = new_state
	current_state.enter(previous_state)
