extends Node2D
class_name GameSpace

# Игровое поле, которое заодно загружает чарты и карту

@onready var CAMERA := $MainCamera # А тут нод камеры
@onready var VIDEO_PLAYER: VideoPlayer = $VideoLayer/VideoPlayer # Плеер видео
@onready var ROADS_HOLDER := $Roads
@onready var MAP_SCENE_HOLDER: Node2D = $MapSceneHolder
@onready var ROAD_MARKERS: Node2D = $RoadMarkers


var ROAD := preload("res://Scenes/Notes/Road.tscn")
var ROADS_MASSIVE : Array[Road]
var MAP_SCENE : MapScene
var MAP_SCENE_LOADED : bool = false
var ROADMARKERS_INDEX : int

signal roads_loaded()

func _draw() -> void:
	if Settings.DEBUG_LINES == true:
		var before_distance_in_pixels: float = Scoring.SAFE_NOTE_ZONE * (450.0 / (Conductor.note_speed * Global.NOTE_SPEED_CONSTANT))
		var after_distance_in_pixels: float = Scoring.NOTE_ZONE * (450.0 / (Conductor.note_speed * Global.NOTE_SPEED_CONSTANT))
		draw_line(Vector2(-100.0, -before_distance_in_pixels), Vector2(100.0, -before_distance_in_pixels), Color(1, 0.27, 0.27, 0.5), 2.0)
		draw_line(Vector2(-100.0, after_distance_in_pixels), Vector2(100.0, after_distance_in_pixels), Color(1, 0.27, 0.27, 0.5), 2.0)
		for zone in Scoring.JUDGE_OFFHITS_ARRAY:
			var distance_in_pixels = (zone / 60.0) * (450.0 / (Conductor.note_speed * Global.NOTE_SPEED_CONSTANT))
			draw_line(Vector2(-100.0, -distance_in_pixels), Vector2(100.0, -distance_in_pixels), Color(1, 0.27, (zone / 10.0), 0.5), 2.0)
			draw_line(Vector2(-100.0, distance_in_pixels), Vector2(100.0, distance_in_pixels), Color(1, 0.27, (zone / 10.0), 0.5), 2.0)

func reset_game() -> void:
	Conductor.reset_playback()
	Scoring.current_score = 0

# Загружает абсолютно ВСЁ связанное с картой
func load_game(core_level: bool, custom_map_folder_name: String) -> void:
	reset_game()
	var path: String
	if core_level: path = "res://CustomMaps/"+custom_map_folder_name
	else: path = "user://Maps/"+custom_map_folder_name
	var mapdata = Tools.parse_json(path+"/mapdata.json")
	var mapchart = Tools.parse_json(path+"/mapchart0.json")
	
	# Добавляет нужные значения в Global для простого отслеживания
	Global.CURRENT_CHART_SIZE = mapdata["chart_size"]
	
	# Загрузка сцены внутри карты
	if mapdata["has_scene"] == true:
		var map_scene_resource = load(path+"/scene.tscn")
		var map_scene_init = map_scene_resource.instantiate()
		MAP_SCENE = map_scene_init
		MAP_SCENE_HOLDER.add_child(map_scene_init)
		MAP_SCENE_LOADED = true
	
	instantiate_roads(mapdata["chart_size"])
	
#region ЗАГРУЗКА НОТ
	# Загружает на каждую дорогу свойственные ей ноты
	for note_index in range(len(mapchart["Notes"])):
		var note = mapchart["Notes"][note_index]
		var note_type : int = note[Global.NOTE_CHART_STRUCTURE.TYPE]
		var note_road : int = note[Global.NOTE_CHART_STRUCTURE.ROAD]
		match note_type:
			Global.NOTE_TYPE.TAPNOTE:
				ROADS_MASSIVE[note_road].ALL_NOTES.push_back(note)
			Global.NOTE_TYPE.HOLDNOTE:
				ROADS_MASSIVE[note_road].ALL_NOTES.push_back(note)
				setup_hold_controls(note)
			Global.NOTE_TYPE.SLIDER:
				match Settings.CHOSEN_GAMEPLAY_MODE:
					Settings.GAMEPLAY_MODE.SLIDERS:
						var iterated_note : Array = iterate_for_slider(mapchart, note_index)
						ROADS_MASSIVE[note_road].ALL_NOTES.push_back(iterated_note)
						setup_slider_controls(iterated_note, mapchart, note_index)
					Settings.GAMEPLAY_MODE.STANDART:
						var iterated_note : Array = iterate_for_slider(mapchart, note_index)
						var next_road : int = iterated_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]\
						[Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_ROAD]
						var spawn_quarters : int = iterated_note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]
						var next_spawn_quarters : int = iterated_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]\
						[Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_SPAWN_QUARTER]
						var duration: int = next_spawn_quarters - spawn_quarters
						var converted_hold_note : Array = [Global.NOTE_TYPE.HOLDNOTE, spawn_quarters,\
						next_road,[duration]]
						ROADS_MASSIVE[next_road].ALL_NOTES.push_back(converted_hold_note)
						setup_hold_controls(converted_hold_note)
			Global.NOTE_TYPE.SLIDERTICK:
				match Settings.CHOSEN_GAMEPLAY_MODE:
					Settings.GAMEPLAY_MODE.SLIDERS:
						var iterated_note : Array = iterate_for_slider(mapchart, note_index)
						ROADS_MASSIVE[note_road].ALL_NOTES.push_back(iterated_note)
						setup_slider_controls(iterated_note, mapchart, note_index)
					Settings.GAMEPLAY_MODE.STANDART:
						var iterated_note : Array = iterate_for_slider(mapchart, note_index)
						var next_road : int = iterated_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]\
						[Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_ROAD]
						var spawn_quarters : int = iterated_note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]
						var next_spawn_quarters : int = iterated_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]\
						[Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_SPAWN_QUARTER]
						var duration: int = next_spawn_quarters - spawn_quarters
						var converted_hold_note : Array = [Global.NOTE_TYPE.HOLDNOTE, spawn_quarters,\
						next_road,[duration]]
						ROADS_MASSIVE[next_road].ALL_NOTES.push_back(converted_hold_note)
						setup_hold_controls(converted_hold_note)
			Global.NOTE_TYPE.SLIDEREND:
				if Settings.CHOSEN_GAMEPLAY_MODE == Settings.GAMEPLAY_MODE.SLIDERS:
					ROADS_MASSIVE[note_road].ALL_NOTES.push_back(note)
#endregion
	
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

# Фантомные ноты для холд нот
func setup_hold_controls(note: Array) -> void:
	var note_additional_info : Array = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]
	var note_spawn_quarter : int = note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]
	var note_road : int = note[Global.NOTE_CHART_STRUCTURE.ROAD]
	for tick in range(note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]+1):
		if tick == note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]:
			ROADS_MASSIVE[note_road].ALL_NOTES.push_back([Global.CONTROL_TYPE.HOLDCONTROLEND,\
			note_spawn_quarter+tick, note_road])
		elif tick != 0:
			ROADS_MASSIVE[note_road].ALL_NOTES.push_back([Global.CONTROL_TYPE.HOLDCONTROLTICK,\
			note_spawn_quarter+tick, note_road])
		else:
			ROADS_MASSIVE[note_road].ALL_NOTES.push_back([Global.CONTROL_TYPE.HOLDCONTROL,\
			note_spawn_quarter, note_road, [note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]]])

# Подключает все свойства в mapscene к оригинальным нодам в gamespace
func control_gamespace() -> void:
	if MAP_SCENE_LOADED:
		CAMERA.position = MAP_SCENE.CAMERA.position
		CAMERA.rotation = MAP_SCENE.CAMERA.rotation
		CAMERA.zoom = MAP_SCENE.CAMERA.zoom

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
	ROADMARKERS_INDEX = CHARTMARKERS.get_index()
	for index in range(chart_size):
		var road_node = ROAD.instantiate()
		road_node.road_index = index
		road_node.name = "Road"+str(index)
		if MAP_SCENE_LOADED:
			road_node.ROAD_POSITION_MARKER = MAP_SCENE.ROAD_MARKERS.get_child(chart_size - 1).get_child(index)
		else:
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

func _process(_delta: float) -> void:
	control_gamespace()
