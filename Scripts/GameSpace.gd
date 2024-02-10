extends Node2D
class_name GameSpace

# Игровое поле, которое заодно загружает чарты и карту

@onready var CAMERA := $MainCamera # А тут нод камеры
@onready var VIDEO_PLAYER: VideoPlayer = $VideoLayer/VideoPlayer # Плеер видео

var ROAD := preload("res://Scenes/Notes/Road.tscn")
var ROADS_MASSIVE : Array[Road]
@onready var ROADS_HOLDER := $Roads

signal roads_loaded()

# Загружает абсолютно ВСЁ связанное с картой
func load_game(core_level: bool, custom_map_folder_name: String) -> void:
	Scoring.current_score = 0
	var path: String
	if core_level: path = "res://CustomMaps/"+custom_map_folder_name
	else: path = "user://Maps/"+custom_map_folder_name
	var mapdata = Tools.parse_json(path+"/mapdata.json")
	var mapchart = Tools.parse_json(path+"/mapchart0.json")
	
	# Добавляет нужные значения в Global для простого отслеживания
	Global.CURRENT_CHART_SIZE = mapdata["chart_size"]
	
	instantiate_roads(mapdata["chart_size"])
	
	# Загружает на каждую дорогу свойственные ей ноты
	for note_index in range(len(mapchart["Notes"])):
		var note = mapchart["Notes"][note_index]
		var note_type : int = note[Global.NOTE_CHART_STRUCTURE.TYPE]
		var note_road : int = note[Global.NOTE_CHART_STRUCTURE.ROAD]
		var note_spawn_quarter : int = note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]
		var note_additional_info : Array
		if len(note) > 3:
			note_additional_info = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]
		match note_type:
			Global.NOTE_TYPE.TAPNOTE:
				ROADS_MASSIVE[note_road].ALL_NOTES.push_back(note)
			Global.NOTE_TYPE.HOLDNOTE:
				ROADS_MASSIVE[note_road].ALL_NOTES.push_back(note)
				for tick in range(note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]+1):
					if tick == note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]:
						ROADS_MASSIVE[note_road].ALL_NOTES.push_back([Global.CONTROL_TYPE.HOLDNOTEEND,\
						note_spawn_quarter+tick, note_road])
					elif tick != 0:
						ROADS_MASSIVE[note_road].ALL_NOTES.push_back([Global.CONTROL_TYPE.HOLDNOTETICK,\
						note_spawn_quarter+tick, note_road])
					else:
						continue
			Global.NOTE_TYPE.SLIDER:
				var iterated_note = iterate_for_slider(mapchart, note_index)
				ROADS_MASSIVE[note_road].ALL_NOTES.push_back(iterated_note)
				setup_slider_controls(iterated_note, mapchart, note_index)
			Global.NOTE_TYPE.SLIDERTICK:
				var iterated_note = iterate_for_slider(mapchart, note_index)
				ROADS_MASSIVE[note_road].ALL_NOTES.push_back(iterated_note)
				setup_slider_controls(iterated_note, mapchart, note_index)
			Global.NOTE_TYPE.SLIDEREND:
				ROADS_MASSIVE[note_road].ALL_NOTES.push_back(note)
	
	if mapdata["has_video"]:
		VIDEO_PLAYER.blur = mapdata["video_blur_amount"]
		VIDEO_PLAYER.load_video(path+"/video.ogv")
	
	Conductor.load_song_from_json(mapdata, custom_map_folder_name)
	Conductor.run()
	start_game()

# Функция, которая ищет слайдер ноты с соответствующим id
func iterate_for_slider(mapchart: Dictionary, note_index: int) -> Array:
	var note : Array = mapchart["Notes"][note_index]
	var note_additional_info : Array = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]
	for slider_note_index in range(note_index + 1, len(mapchart["Notes"])):
		var slider_note = mapchart["Notes"][slider_note_index]
		var slider_additional_info = slider_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]
		if slider_additional_info[Global.SLIDER_NOTE_ADDITIONAL_INFO.ID] == note_additional_info[Global.SLIDER_NOTE_ADDITIONAL_INFO.ID]:
			note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO].push_back(slider_note[Global.NOTE_CHART_STRUCTURE.ROAD])
			note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO].push_back(slider_note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN])
			return note
		else:
			continue
	return note

# Добавляет фантомные ноты для слайдеров
func setup_slider_controls(iterated_note: Array, mapchart: Dictionary, note_index: int) -> void:
	var note : Array = mapchart["Notes"][note_index]
	var note_additional_info : Array = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]
	var note_spawn_quarter: int = note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]
	var next_road = iterated_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_ROAD]
	var length_in_quarters: int = note_additional_info\
	[Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_SPAWN_QUARTER] - note_spawn_quarter
	ROADS_MASSIVE[next_road].ALL_NOTES.push_back([Global.CONTROL_TYPE.SLIDERCONTROL, note_spawn_quarter, next_road])
	for tick in range(length_in_quarters + 1):
		if tick == length_in_quarters:
			ROADS_MASSIVE[next_road].ALL_NOTES.push_back([Global.CONTROL_TYPE.SLIDERCONTROLEND,\
			note_spawn_quarter+tick, next_road])
		elif tick != 0:
			ROADS_MASSIVE[next_road].ALL_NOTES.push_back([Global.CONTROL_TYPE.SLIDERCONTROLTICK,\
			note_spawn_quarter+tick, next_road])
		else:
			continue

# Запускает кондуктор и саму игру
func start_game() -> void:
	VIDEO_PLAYER.play_video_with_offset(Conductor.offset)
	Conductor.play_song_with_offset()

# В зависимости от chart_size выбирает нужные маркеры и расставляет дороги
# (не знаю, насколько плохо создавать множество нод с разными маркерами, но
# надеюсь, что Marker2D не слишком perfomance-impact)
func instantiate_roads(chart_size: int) -> void:
	var CHARTMARKERS : Node2D # Должен сохранить в себя ноду с маркерами карты
	match chart_size:
		1:
			CHARTMARKERS = get_node("RoadMarkers/1KChartRoadMarkers")
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
		roads_loaded.connect(road_node.get_roads_array)
		ROADS_MASSIVE.push_back(road_node)
		ROADS_HOLDER.add_child(road_node)
	emit_signal("roads_loaded")

func _ready() -> void:
	load_game(true, "RobotLanguage")
	
	# Пока что скрипт на создание папки запихну сюда
	var usermap_dir = DirAccess.open("user://Maps")
	if !usermap_dir:
		DirAccess.make_dir_absolute("user://Maps")
