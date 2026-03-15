extends Node2D

@export var player_scene: PackedScene
@export var fight_menu_scene: PackedScene

@onready var player_container: Node2D = $PlayerContainer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var fight_manager: Node = $FightManager

var fight_menu: Control


func _ready() -> void:
	print("world: _ready()")
	GameManager.notify_world_is_ready.call_deferred()
	if fight_manager.has_signal("fight_ended_for_peer"):
		fight_manager.fight_ended_for_peer.connect(_on_fight_ended_for_peer)


func _on_fight_ended_for_peer(peer_id: int) -> void:
	var my_id := multiplayer.get_unique_id()
	if peer_id != my_id:
		return
	var my_char: Node = player_container.get_node_or_null(str(my_id))
	if my_char:
		var cam: Camera2D = my_char.get_node_or_null("Camera2D")
		if cam:
			cam.make_current()


func spawn_character_to_stage(peer_id: int, data: Dictionary) -> void:
	if player_scene == null:
		print("world: Fehler - player_scene ist nicht zugewiesen")
		return
	print("world: Setze Character ", data.get("name", "Unbekannt"))
	var player_instance: Node = player_scene.instantiate()
	player_instance.name = str(peer_id)
	player_instance.set_multiplayer_authority(peer_id)
	player_instance.position = Vector2(randf_range(-150, 150), randf_range(-150, 150))
	player_container.add_child(player_instance, true)


func remove_character_from_stage(peer_id: int) -> void:
	var node_to_remove: Node = player_container.get_node_or_null(str(peer_id))
	if node_to_remove:
		print("world: Spieler ", peer_id, " hat das Spiel verlassen")
		node_to_remove.queue_free()
	else:
		print("world: Konnte keinen Character für ID ", peer_id, " finden.")


func sync_active_fights_to_peer(peer_id: int) -> void:
	fight_manager.sync_active_fights_to_peer(peer_id)


func is_peer_in_fight(peer_id: int) -> bool:
	return fight_manager.is_peer_in_fight(peer_id)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("Menu"):
		if $UILayer/CenterContainer/Lobby.visible == true:
			$UILayer/CenterContainer/Lobby.visible = false
		else:
			$UILayer/CenterContainer/Lobby.visible = true
	if event.is_action_pressed("action_button"):
		_toggle_fight_menu()


func _toggle_fight_menu() -> void:
	if fight_menu and is_instance_valid(fight_menu):
		fight_menu.queue_free()
		fight_menu = null
		return
	if fight_menu_scene == null:
		print("world: fight_menu_scene ist nicht gesetzt.")
		return
	fight_menu = fight_menu_scene.instantiate()
	ui_layer.add_child(fight_menu)
	if fight_menu.has_signal("start_fight_pressed"):
		fight_menu.start_fight_pressed.connect(_on_fight_menu_start_fight)
	if fight_menu.has_signal("join_fight_pressed"):
		fight_menu.join_fight_pressed.connect(_on_fight_menu_join_fight)
	if fight_menu.has_signal("leave_fight_pressed"):
		fight_menu.leave_fight_pressed.connect(_on_fight_menu_leave_fight)


func _on_fight_menu_start_fight() -> void:
	if fight_menu and is_instance_valid(fight_menu):
		fight_menu.queue_free()
		fight_menu = null
	if multiplayer.is_server():
		fight_manager.start_fight_for_peer(multiplayer.get_unique_id())
	else:
		fight_manager.rpc_id(1, "rpc_request_start_fight")


func _on_fight_menu_join_fight() -> void:
	if fight_menu and is_instance_valid(fight_menu):
		fight_menu.queue_free()
		fight_menu = null
	if multiplayer.is_server():
		fight_manager._process_join_request(multiplayer.get_unique_id())
	else:
		fight_manager.rpc_id(1, "rpc_request_join_fight")


func _on_fight_menu_leave_fight() -> void:
	if fight_menu and is_instance_valid(fight_menu):
		fight_menu.queue_free()
		fight_menu = null
	if multiplayer.is_server():
		fight_manager.end_fight_for_peer(multiplayer.get_unique_id())
	else:
		fight_manager.rpc_id(1, "rpc_request_end_fight_for_peer")
