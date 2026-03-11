extends Control

## Standalone-Hauptmenü. Buttons sind vorbereitet; Logik später einhängen.


func _on_start_button_pressed() -> void:
	# TODO: z.B. Lobby laden oder Host starten
	pass


func _on_join_button_pressed() -> void:
	# TODO: Join-Dialog / Lobby beitreten
	pass


func _on_options_button_pressed() -> void:
	# TODO: Options-Szene öffnen
	pass


func _on_status_button_pressed() -> void:
	# TODO: Status-Anzeige (z.B. Verbindungsinfo)
	pass


func _on_exit_button_pressed() -> void:
	get_tree().quit()
