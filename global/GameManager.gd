extends Node

#Consts
const WORLD_SCENE_PATH = "res://scene/world.tscn"
const MAIN_MENUE_PATH = "res://scene/lobby.tscn"


func _ready():
	NetworkManager.server_started.connect(_on_server_start)
	NetworkManager.connection_successful.connect(_on_conncetion_successful)
	NetworkManager.connection_lost.connect(_on_connection_lost)
	NetworkManager.handshake_recieved.connect(_on_network_handshake_received)
	
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

# =================================================================
# 🌍 ALLGEMEINE / CLIENT FUNKTIONEN (Für jeden zugänglich)
# =================================================================

func notify_world_is_ready() -> void:
	print("GameManager: Die Welt meldet sich bereit!")
	
	if multiplayer.is_server():
		print("GameManager: Ich bin der Host, spawn mich selbst.")
		_process_spawn_command(1, PlayerSession.current_character_data)
	else:
		print("GameManager: Ich bin Client, sende Handeshake...")
		NetworkManager.send_handshake(PlayerSession.current_character_data)


#Reaction of Singals
func _on_server_start() -> void: 
	print("GameManger: Server läuft. Starte Spiel für Host....")
	_change_scene(WORLD_SCENE_PATH)


func _on_conncetion_successful() -> void:
	print("GameManager: Verbindung steht. Starte Spiel für Client....")
	_change_scene(WORLD_SCENE_PATH)


func _on_connection_lost() -> void: 
	print("GameManager: Verbindung weg. Zurück ins Menü....")
	_change_scene(MAIN_MENUE_PATH)



#Help Func
func _change_scene(path:String) -> void:
	get_tree().change_scene_to_file.call_deferred(path)


# =================================================================
# 🖥️ SERVER ONLY FUNKTIONEN 
# =================================================================


func _on_network_handshake_received(peer_id: int ,data: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	
	print("GameManager(Server): Handshake-Signal empfangen für ID ", peer_id)
	_process_spawn_command(peer_id, data)
	


func _process_spawn_command(peer_id: int, data: Dictionary) -> void:
	if not multiplayer.is_server(): 
		return 
	
	var current_world: Node = get_tree().current_scene
	if current_world.has_method("spawn_character_to_stage"):
		current_world.spawn_character_to_stage(peer_id, data)
	else:
		print("GameManager(Server): Fehler - Die aktuelle Scene hat keine Spawn Funktion!")

func _on_player_disconnected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	
	var current_world: Node = get_tree().current_scene
	if current_world and current_world.has_method("remove_character_from_stage"):
		current_world.remove_character_from_stage(peer_id)
