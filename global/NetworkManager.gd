extends Node
## ENet-Multiplayer: Host/Client, Handshake, Signale für Verbindung/Verlust.

signal server_started
signal connection_successful
signal connection_lost
signal handshake_received

const PORT = 7000
const DEFAULT_IP = "127.0.0.1"  # Localhost

var peer = null


func _ready():
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)



func host_game() -> void: 
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 2)
	
	if error != OK:
		print("fehler: Kann nicht hosten! " + str(error))
		return
	
	multiplayer.multiplayer_peer = peer
	print("Host gestartet! Wartet auf Spieler...")
	server_started.emit()
	


func join_game() -> void: 
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(DEFAULT_IP, PORT)
	
	if error != OK: 
		print("fehler: Kann nicht beitreten! " + str(error))
		return
	
	multiplayer.multiplayer_peer = peer
	print("Versuch zu Verbinden...")


func stop_connection() -> void:
	if peer != null:
		peer.close()
	
	multiplayer.multiplayer_peer = null
	peer = null
	print("Verbindung wurde manuell beendet.")
	connection_lost.emit()


func send_handshake(data: Dictionary) -> void:
	print("NetworkManger: Sende Handshake an Server... ") 
	
	_rpc_receive_handshake.rpc_id(1, data)


func _on_connected_ok() -> void:
	print("Client: Erfolgreich mit dem Server verbunden.")
	connection_successful.emit()

func _on_connection_failed() -> void: 
	print("Client: Verbindung fehlgeschlagen.")
	connection_lost.emit()

func _on_server_disconnected() -> void:
	print("Client: Verbindung verloren.")
	connection_lost.emit()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_receive_handshake(data: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	
	print("NetworkManager(Server): Handshake von ID ", sender_id, "empfangen!")
	print("NetworkManager(Server): Inhalt: " , data)
	
	handshake_received.emit(sender_id, data)


func _on_peer_connected(id) -> void: 
	if multiplayer.is_server():
		print("Host: Neuer Client wurde verbunden. " + str(id))

func _on_peer_disconnected(id) -> void: 
	if multiplayer.is_server():
		print("Host: Client hat die Sitzung verlassen. " + str(id))
