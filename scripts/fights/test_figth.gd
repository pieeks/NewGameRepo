extends Node2D

@onready var hex_grid_layer: TileMapLayer = $HexGridLayer

var astar: AStarGrid2D

func _ready() -> void:
	astar = AStarGrid2D.new()
	astar.region = hex_grid_layer.get_used_rect()
	astar.cell_size = hex_grid_layer.tile_set.tile_size
	astar.set_cell_shape(2)
	astar.update()
	
	print("AStarGrid vollautomatisch initialisiert!")
	print("Region: ", astar.region)
	print("Zellengröße: ", astar.cell_size)
