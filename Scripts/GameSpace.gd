extends Node2D
class_name GameSpace

# Отвечает за то, чтобы соединить JSON-чарты с игрой

@onready var CAMERA := $MainCamera # А тут нод камеры
var ROAD := preload("res://Scenes/Notes/Road.tscn")
var ROADS_MASSIVE : Array
@onready var ROADS_HOLDER := $Roads
var MAPDATA # Информация о карте (map_name, creator_name, difficulty, chart_size)

# Загружает абсолютно ВСЁ связанное с картой
func load_game(custom_map_folder_name: String) -> void:
	var mapdata = Tools.parse_json("res://CustomMaps/"+custom_map_folder_name+"/mapdata.json")
	
	# Добавляет нужные значения в Global для простого отслеживания
	Global.CURRENT_NOTE_SPEED = mapdata["note_speed"]
	Global.CURRENT_CHART_SIZE = mapdata["chart_size"]
	
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
		ROADS_MASSIVE.push_back(road_node)
		ROADS_HOLDER.add_child(road_node)

func _ready() -> void:
	Conductor.connect("chart_beat_hit", chart_beat_hit)
	Conductor.connect("chart_measure_hit", chart_measure_hit)
	load_game("TestMap")

func chart_beat_hit(_dull) -> void:
	ROADS_MASSIVE[0].spawn_note()
func chart_measure_hit(_dull) -> void:
	ROADS_MASSIVE[3].spawn_note()
