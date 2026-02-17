extends Node2D

@export var player_scene: PackedScene

@onready var player_container: Node2D = $PlayerContainer



func _ready() -> void:
	print("!!! testWorld.gd: Mein _ready() Funktion Läuft!")
	GameManager.notify_world_is_ready.call_deferred()


func spawn_character_to_stage(peer_id: int, data: Dictionary) -> void:
	if player_scene == null: 
		print("testWorld: Fehler - player_scene is nicht zugewiesen")
		return
	
	print("testWorld: -> Setze Character ", data.get("name", "Unbekannt"))
	
	var player_instance : Node = player_scene.instantiate()
	
	player_instance.name = str(peer_id)
	player_instance.set_multiplayer_authority(peer_id)
	player_instance.position = Vector2(randf_range(-150, 150), randf_range(-150, 150))
	player_container.add_child(player_instance, true)


func remove_character_from_stage(peer_id: int) -> void:
	var player_node_name: String = str(peer_id)
	var node_to_remove: Node = player_container.get_node_or_null(player_node_name)
	
	if node_to_remove:
		print("testWorld: Spieler: ", peer_id, "hat das Spiel verlassen")
		node_to_remove.queue_free()
	else:
		print("testWorld: Konnte keinen Charcter für ID: ", peer_id, " finden.") 


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("Menu"): 
		if $UILayer/CenterContainer/Lobby.visible == true:
			$UILayer/CenterContainer/Lobby.visible = false
		else:
			$UILayer/CenterContainer/Lobby.visible = true
