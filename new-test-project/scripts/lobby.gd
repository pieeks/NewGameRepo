extends Control


func _ready(): 
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	var available_saves: Array = PlayerSession.get_available_savegames()
	print("Lobby: Gefundene Savegames: ", available_saves)
	
	if available_saves.size() > 0:
		print("lobby.gd: available_saves größer 0")
		var selected_file: String = available_saves[0]["file"]
		PlayerSession.load_character(selected_file)

func _on_start_button_button_down() -> void:
	NetworkManager.host_game()


func _on_join_button_button_down() -> void:
	NetworkManager.join_game()


func _on_leave_button_button_down() -> void:
	NetworkManager.stop_connection()


func _on_status_button_button_down() -> void:
	if NetworkManager.peer == null:
		print("STATUS: Offline")
		return
	
	var status = multiplayer.multiplayer_peer.get_connection_status()
	
	match status:
		MultiplayerPeer.CONNECTION_DISCONNECTED:
			print("STATUS: Peer existiert, aber ist getrennt.")
		MultiplayerPeer.CONNECTION_CONNECTING:
			print("STATUS: Versuche zu verbinden")
		MultiplayerPeer.CONNECTION_CONNECTED:
			var my_id = multiplayer.get_unique_id()
			if multiplayer.is_server():
				print("STATUS: Online als Host.")
			else:
				print("STATUS: Online als client mit der ID: " + str(my_id))

func _on_connected_ok() -> void:
	print("Lobby: Erfolgreich verbunden!")


func _on_connected_failed() -> void: 
	print("Lobby: Verbindung gescheitert.")
	NetworkManager.stop_connection()


func _on_server_disconnected() -> void:
	print("Lobby: Server hat die Verbindung getrennt.")
	NetworkManager.stop_connection()
