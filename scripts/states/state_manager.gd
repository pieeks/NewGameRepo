extends Node 

@onready var character: CharacterBody2D = get_parent()

var current_state: State 
var states: Dictionary = {}

func _ready() -> void:
	# Alle Child-Nodes durchgehen und typsicher registrieren
	for child in get_children():
		# Wir prüfen, ob der Node wirklich von unserer state.gd Klasse erbt
		if child is State:
			var state_node = child as State
			
			# Falls du im Editor keinen Namen vergeben hast, nehmen wir den Node-Namen
			if state_node.state_name == StringName():
				state_node.state_name = StringName(state_node.name)
			
			states[state_node.state_name] = state_node
			
			# Dem State sagen, wer sein Chef und wer sein Körper ist
			state_node.character = character
			state_node.state_controller = self
	
	print("StateManager: registered states = ", states.keys())
	
	# Standard-Startzustand aufrufen
	if states.has(&"Idle"):
		_change_state(&"Idle")
	elif states.size() > 0:
		var any_state_name: StringName = states.keys()[0]
		_change_state(any_state_name)


func _physics_process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer() or not character.is_multiplayer_authority():
		return
	
	# 2. Pure Delegation: Der Manager misst keine Geschwindigkeit mehr!
	# Er ruft einfach nur den aktiven State auf und lässt ihn die Arbeit machen.
	if current_state:
		current_state.physics_update(delta)


# Diese Funktion rufen die States (Arbeiter) auf, wenn sie fertig sind
func request_state_change(target_state_name: StringName) -> void:
	_change_state(target_state_name)


func _change_state(target_state_name: StringName) -> void:
	if not states.has(target_state_name):
		push_warning("StateManager: State '" + str(target_state_name) + "' existiert nicht!")
		return
	
	var new_state = states[target_state_name]
	var previous_state = current_state
	
	if current_state == new_state:
		return
	
	# 1. Dem alten State sagen, dass er aufräumen soll
	if current_state:
		current_state.exit(new_state)
	
	current_state = new_state
	
	# 2. Dem neuen State sagen, dass seine Schicht beginnt
	current_state.enter(previous_state)
	
	# Optionaler Debug-Print, um Wechsel im Auge zu behalten
	# print("State gewechselt zu: ", current_state.state_name)
