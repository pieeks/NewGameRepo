extends Control

signal start_fight_pressed
signal join_fight_pressed


func _ready() -> void:
	# Buttons über ihre Namen suchen und Signale verbinden
	var host_button: Button = get_node_or_null("VBoxContainer/HostFightButton")
	var join_button: Button = get_node_or_null("VBoxContainer/JoinFightButton")
	
	if host_button:
		host_button.pressed.connect(_on_host_fight_pressed)
	if join_button:
		join_button.pressed.connect(_on_join_fight_pressed)


func _on_host_fight_pressed() -> void:
	start_fight_pressed.emit()


func _on_join_fight_pressed() -> void:
	join_fight_pressed.emit()
