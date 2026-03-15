extends Node
## Speicherort und geladene Character-Daten für Lobby/Spawn.

const SAVE_DIR = "user://saves/"

var current_character_data: Dictionary = {}


func verify_save_directory() -> void: 
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		print("PlayerSession: Save-Ordner nicht gefunden. Erstelle neuen.")
		DirAccess.make_dir_absolute(SAVE_DIR)
	else:
		print("PlayerSession: Save-Ordner existiert bereits.")


func get_available_savegames() -> Array:
	var savegames: Array = []
	var dir = DirAccess.open(SAVE_DIR)
	
	if dir: 
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var file_path: String = SAVE_DIR + file_name
				var file = FileAccess.open(file_path, FileAccess.READ)
				var json_string: String = file.get_as_text()
				var data: Dictionary = JSON.parse_string(json_string) 
				
				if data != null: 
					savegames.append({
						"file": file_name,
						"name": data.get("name", "Unbekannt"),
						"level": data.get("level", data.get("levl", 1))
					})
				
				file_name = dir.get_next()
	
	return savegames


func load_character(file_name: String) -> void:
	var file_path: String = SAVE_DIR + file_name
	if not FileAccess.file_exists(file_path):
		print("PlayerSession: Fehler - Speicherstand nicht gefunden.")
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string: String = file.get_as_text()
	
	var parsed_data = JSON.parse_string(json_string)
	
	if parsed_data != null and typeof(parsed_data) == TYPE_DICTIONARY:
		current_character_data = parsed_data
		
		print("PlayerSession: Character erfolgreich in den RAM geladen!")
		print("PlayerSession: Daten: ", current_character_data)
	else:
		print("PlayerSession: Fehler - Die JSON-Datei ist fehlerhaft oder leer.")
