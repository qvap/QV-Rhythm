extends Node2D
class_name GameSpace

# Отвечает за то, чтобы соединить JSON-чарты с игрой

@onready var CAMERA := $MainCamera # А тут нод камеры
var ROAD := preload("res://Scenes/Notes/Road.tscn")
@onready var ROADS_HOLDER := $Roads
var MAPDATA # Информация о карте (map_name, creator_name, difficulty, chart_size)

# Загружает абсолютно ВСЁ связанное с картой
func load_game(custom_map_folder_name: String) -> void:
	var mapdata = Tools.parse_json("res://CustomMaps/"+custom_map_folder_name+"/mapdata.json")
	instantiate_roads(mapdata["chart_size"])
	
	Conductor.load_song_from_json(mapdata, custom_map_folder_name)
	Conductor.run()
	start_game()

# Запускает кондуктор и саму игру
func start_game() -> void:
	Conductor.play_song_with_offset()

# В зависимости от chart_size выбирает нужные маркеры и расставляет дороги
# (не знаю, насколько плохо создавать множество нод с разными маркерами, но
# надеюсь, что Marker2D не слишком perfomance-impact)
func instantiate_roads(chart_size: int) -> void:
	var CHARTMARKERS : Node2D # Должен сохранить в себя ноду с маркерами карты
	match chart_size:
		2:
			CHARTMARKERS = get_node("RoadMarkers/2KChartRoadMarkers")
		3:
			CHARTMARKERS = get_node("RoadMarkers/3KChartRoadMarkers")
		4:
			CHARTMARKERS = get_node("RoadMarkers/4KChartRoadMarkers")
		5:
			CHARTMARKERS = get_node("RoadMarkers/5KChartRoadMarkers")
		6:
			CHARTMARKERS = get_node("RoadMarkers/6KChartRoadMarkers")
	for index in range(chart_size):
		var road_node = ROAD.instantiate()
		road_node.road_index = index
		road_node.name = "Road"+str(index)
		road_node.ROAD_POSITION_MARKER = CHARTMARKERS.get_child(index)
		ROADS_HOLDER.add_child(road_node)

func _ready() -> void:
	load_game("TestMap")
