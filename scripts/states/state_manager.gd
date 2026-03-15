extends Node
## Registriert State-Child-Nodes und delegiert [method Node._physics_process] an den aktiven State.

@onready var character: CharacterBody2D = get_parent()

var current_state: State
var states: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is State:
			var state_node: State = child as State
			if state_node.state_name == StringName():
				state_node.state_name = StringName(state_node.name)
			states[state_node.state_name] = state_node
			state_node.character = character
			state_node.state_controller = self
	if states.has(&"Idle"):
		_change_state(&"Idle")
	elif states.size() > 0:
		var any_state_name: StringName = states.keys()[0]
		_change_state(any_state_name)


func _physics_process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer() or not character.is_multiplayer_authority():
		return
	if current_state:
		current_state.physics_update(delta)


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
	if current_state:
		current_state.exit(new_state)
	current_state = new_state
	current_state.enter(previous_state)
