extends Node2D
class_name GameSpace

# Отвечает за то, чтобы соединить JSON-чарты с игрой

@onready var CAMERA := $MainCamera # А тут нод камеры
var ROAD := preload("res://Scenes/Notes/Road.tscn")
var ROADS_MASSIVE : Array[Road]
@onready var ROADS_HOLDER := $Roads

# Загружает абсолютно ВСЁ связанное с картой
func load_game(custom_map_folder_name: String) -> void:
	Scoring.current_score = 0
	var mapdata = Tools.parse_json("res://CustomMaps/"+custom_map_folder_name+"/mapdata.json")
	var mapchart = Tools.parse_json("res://CustomMaps/"+custom_map_folder_name+"/mapchart0.json")
	
	# Добавляет нужные значения в Global для простого отслеживания
	Global.CURRENT_CHART_SIZE = mapdata["chart_size"]
	
	instantiate_roads(mapdata["chart_size"])
	
	# Загружает на каждую дорогу свойственные ей ноты
	for note in mapchart["Notes"]:
		var note_type : int = note[Global.NOTE_CHART_STRUCTURE.TYPE]
		var note_road : int = note[Global.NOTE_CHART_STRUCTURE.ROAD]
		var note_spawn_quarter : int = note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]
		var note_additional_info : int
		if len(note) > 3:
			note_additional_info = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]
		match note_type:
			Global.NOTE_TYPE.TAPNOTE:
				ROADS_MASSIVE[note_road].ALL_NOTES.push_back(note)
			Global.NOTE_TYPE.HOLDNOTE:
				ROADS_MASSIVE[note_road].ALL_NOTES.push_back(note)
				for tick in range(note_additional_info+1):
					if tick == note_additional_info:
						ROADS_MASSIVE[note_road].ALL_NOTES.push_back([Global.NOTE_TYPE.HOLDNOTEEND,\
						note_spawn_quarter+tick, note_road])
					elif tick != 0:
						ROADS_MASSIVE[note_road].ALL_NOTES.push_back([Global.NOTE_TYPE.HOLDNOTETICK,\
						note_spawn_quarter+tick, note_road])
					else:
						continue
	
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
	load_game("TestMap")
