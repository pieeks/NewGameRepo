extends Node2D

@export_group("Grid Settings")
@export var width: int = 10:
	set(v): width = v; setup_grid()
@export var height: int = 8:
	set(v): height = v; setup_grid()
@export var spacing: float = 40.0:
	set(v): spacing = v; setup_grid()

var astar = AStar2D.new()

func _ready() -> void:
	setup_grid()



func setup_grid() -> void:
	astar.clear()
	var points_dict = {} #Hilfsspeicher: Vector2i(x, y) -> ID
	
	var id = 0
	
	for y in height:
		for x in width:
			var grid_pos = Vector2i(x, y)
			var pos = Vector2(x * spacing, y * spacing * 0.75)
			
			#Versatz für jede ungerade Reihe
			if y % 2 == 1:
				pos.x += spacing / 2
				
			astar.add_point(id, pos)
			points_dict[grid_pos] = id
			id += 1
			
	
	for y in height:
		for x in width:
			var current_id = points_dict[Vector2i(x, y)]
			var neighbor_coords = []
			
			# Die 6 Nachbarn eines Hexagons hängen davon ab, ob die Reihe gerade/ungerade ist
			if y % 2 == 0: # Gerade Reihe
				neighbor_coords = [
					Vector2i(x, y-1), Vector2i(x+1, y-1), # Oben
					Vector2i(x-1, y), Vector2i(x+1, y),     # Seiten
					Vector2i(x, y+1), Vector2i(x+1, y+1)  # Unten
				]
			else: # Ungerade Reihe
				neighbor_coords = [
					Vector2i(x-1, y-1), Vector2i(x, y-1),
					Vector2i(x-1, y), Vector2i(x+1, y),
					Vector2i(x-1, y+1), Vector2i(x, y+1)
				]
			
			for n_coord in neighbor_coords:
				if points_dict.has(n_coord):
					astar.connect_points(current_id, points_dict[n_coord])
	
	##Verbindungen erstellen
	queue_redraw()


func _draw() -> void:
	#Nur zur Visualisierung der Punkte im Game
	if not astar: 
		return
	
	for id in astar.get_point_ids():
		var pos = astar.get_point_position(id)
		draw_circle(pos, 3.0, Color.CYAN)


func get_action_path(start_world_pos: Vector2, target_world_pos: Vector2) -> PackedVector2Array:
	var start_id = astar.get_closest_point(start_world_pos)
	var target_id = astar.get_closest_point(target_world_pos)
	
	# Gibt ein Array von Vector2-Positionen (Mittelpunkten) zurück
	return astar.get_point_path(start_id, target_id)
