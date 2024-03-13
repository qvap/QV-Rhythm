extends Node2D
class_name GameSpace

# Игровое поле, которое заодно загружает чарты и карту

@onready var CAMERA : MainCamera # А тут нод камеры
@onready var ROAD_MARKERS: Node2D

@onready var VIDEO_PLAYER: VideoPlayer = $VideoLayer/VideoPlayer # Плеер видео
@onready var ROADS_HOLDER := $Roads
@onready var MAP_SCENE_HOLDER: Node2D = $MapSceneHolder


var ROAD := preload("res://Scenes/Notes/Road.tscn")
var ROADS_MASSIVE : Array[Road]
var MAP_SCENE : MapScene
var MAP_SCENE_LOADED : bool = false
var ROADMARKERS_INDEX : int

signal roads_loaded()

func _draw() -> void:
	if Settings.DEBUG_LINES == true:
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
		ROAD_MARKERS = map_scene_init.get_node("RoadMarkers")
		CAMERA = map_scene_init.get_node("MainCamera")
		CAMERA.VIDEO_PLAYER = VIDEO_PLAYER
		MAP_SCENE_HOLDER.add_child(map_scene_init)
		MAP_SCENE_LOADED = true
	else:
		var base_scene_resource = load("res://Scenes/Game/BaseScene.tscn")
		var base_scene_init = base_scene_resource.instantiate()
		MAP_SCENE = base_scene_init
		ROAD_MARKERS = base_scene_init.get_node("RoadMarkers")
		CAMERA = base_scene_init.get_node("MainCamera")
		CAMERA.VIDEO_PLAYER = VIDEO_PLAYER
		MAP_SCENE_HOLDER.add_child(base_scene_init)
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
						var structured_hold_note: Array = Tools.create_structured_note_array(true)
						var structured_hold_note_additional_info: Array = []
						structured_hold_note_additional_info.resize(len(Global.HOLD_NOTE_ADDITIONAL_INFO.values()))
						structured_hold_note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION] = duration
						structured_hold_note[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.NOTE_TYPE.HOLDNOTE
						structured_hold_note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = spawn_quarters
						structured_hold_note[Global.NOTE_CHART_STRUCTURE.ROAD] = next_road
						structured_hold_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO] = structured_hold_note_additional_info
						ROADS_MASSIVE[next_road].ALL_NOTES.push_back(structured_hold_note)
						setup_hold_controls(structured_hold_note)
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
						var structured_hold_note: Array = Tools.create_structured_note_array(true)
						var structured_hold_note_additional_info: Array = []
						structured_hold_note_additional_info.resize(len(Global.HOLD_NOTE_ADDITIONAL_INFO.values()))
						structured_hold_note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION] = duration
						structured_hold_note[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.NOTE_TYPE.HOLDNOTE
						structured_hold_note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = spawn_quarters
						structured_hold_note[Global.NOTE_CHART_STRUCTURE.ROAD] = next_road
						structured_hold_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO] = structured_hold_note_additional_info
						ROADS_MASSIVE[next_road].ALL_NOTES.push_back(structured_hold_note)
						setup_hold_controls(structured_hold_note)
			Global.NOTE_TYPE.SLIDEREND:
				if Settings.CHOSEN_GAMEPLAY_MODE == Settings.GAMEPLAY_MODE.SLIDERS:
					ROADS_MASSIVE[note_road].ALL_NOTES.push_back(note)
					
	for road in ROADS_MASSIVE:
		road.ALL_NOTES.sort_custom(sort_notes)
#endregion
	
	load_colors(mapchart["ColorZones"])
	
	if mapdata["has_video"]:
		VIDEO_PLAYER.blur = mapdata["video_blur_amount"]
		VIDEO_PLAYER.load_video(path+"/video.mp4")
	
	Conductor.load_song_from_json(mapdata, custom_map_folder_name)
	Conductor.run()
	await get_tree().create_timer(0.01).timeout # я не должен так делать, но так проще всего
	# Если перед start_game нету паузы, то первая четверть в сильном рассинхроне, не знаю,
	# почему так получается. Пока что не буду это фиксить, так как после создания меню и загрузки
	# игры через это меню такой проблемы быть не должно
	start_game()

# Появилась потребность сортировать порядок нот в списке, т.к. из-за неправильного
# порядка полностью ломается спавн слайдеров, ибо спавн нот не предусматривает расположение
# нескольких нот в одном месте (в случае слайдеров - контроллеров)
func sort_notes(a: Array, b: Array) -> bool:
	if a[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] < b[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]\
	or (a[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] == b[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]\
	and a[Global.NOTE_CHART_STRUCTURE.TYPE] < b[Global.NOTE_CHART_STRUCTURE.TYPE]):
		return true
	return false

# Функция, которая ищет слайдер ноты с соответствующим id
func iterate_for_slider(mapchart: Dictionary, note_index: int) -> Array:
	var note : Array = mapchart["Notes"][note_index]
	var note_additional_info : Array = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]
	for slider_note_index in range(note_index + 1, len(mapchart["Notes"])):
		var slider_note: Array = mapchart["Notes"][slider_note_index]
		var slider_additional_info: Array = slider_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]
		var slider_type: int = slider_note[Global.NOTE_CHART_STRUCTURE.TYPE]
		if (slider_additional_info[Global.SLIDER_NOTE_ADDITIONAL_INFO.ID] == note_additional_info[Global.SLIDER_NOTE_ADDITIONAL_INFO.ID])\
		and !(slider_type in Global.CONTROL_TYPE):
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
	var note_id: int = note_additional_info[Global.SLIDER_NOTE_ADDITIONAL_INFO.ID]
	var note_spawn_quarter: int = note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]
	var next_road = iterated_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_ROAD]
	var length_in_quarters: int = note_additional_info\
	[Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_SPAWN_QUARTER] - note_spawn_quarter
	var first_structured_note_array: Array = Tools.create_structured_note_array(true)
	
	# Мне это нужно для того, чтобы добавлять в контрол ноты айди слайдеров
	var structured_note_additional_info_array: Array = []
	structured_note_additional_info_array.resize(len(Global.SLIDER_NOTE_ADDITIONAL_INFO.values()))
	structured_note_additional_info_array[Global.SLIDER_NOTE_ADDITIONAL_INFO.ID] = note_id
	
	first_structured_note_array[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.CONTROL_TYPE.SLIDERCONTROL
	first_structured_note_array[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = note_spawn_quarter
	first_structured_note_array[Global.NOTE_CHART_STRUCTURE.ROAD] = next_road
	first_structured_note_array[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]\
	= structured_note_additional_info_array
	ROADS_MASSIVE[next_road].ALL_NOTES.push_back(first_structured_note_array)
	for tick in range(length_in_quarters + 1):
		if tick == length_in_quarters:
			var structured_note_array: Array = Tools.create_structured_note_array(false)
			structured_note_array[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.CONTROL_TYPE.SLIDERCONTROLEND
			structured_note_array[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = note_spawn_quarter+tick
			structured_note_array[Global.NOTE_CHART_STRUCTURE.ROAD] = next_road
			ROADS_MASSIVE[next_road].ALL_NOTES.push_back(structured_note_array)
		elif tick != 0:
			var structured_note_array: Array = Tools.create_structured_note_array(false)
			structured_note_array[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.CONTROL_TYPE.SLIDERCONTROLTICK
			structured_note_array[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = note_spawn_quarter+tick
			structured_note_array[Global.NOTE_CHART_STRUCTURE.ROAD] = next_road
			ROADS_MASSIVE[next_road].ALL_NOTES.push_back(structured_note_array)
		else:
			continue

# Фантомные ноты для холд нот
func setup_hold_controls(note: Array) -> void:
	var note_additional_info : Array = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]
	var note_spawn_quarter : int = note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]
	var note_road : int = note[Global.NOTE_CHART_STRUCTURE.ROAD]
	for tick in range(note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]+1):
		if tick == note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]:
			var structured_note_array: Array = Tools.create_structured_note_array(false)
			structured_note_array[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.CONTROL_TYPE.HOLDCONTROLEND
			structured_note_array[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = note_spawn_quarter+tick
			structured_note_array[Global.NOTE_CHART_STRUCTURE.ROAD] = note_road
			ROADS_MASSIVE[note_road].ALL_NOTES.push_back(structured_note_array)
		elif tick != 0:
			var structured_note_array: Array = Tools.create_structured_note_array(false)
			structured_note_array[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.CONTROL_TYPE.HOLDCONTROLTICK
			structured_note_array[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = note_spawn_quarter+tick
			structured_note_array[Global.NOTE_CHART_STRUCTURE.ROAD] = note_road
			ROADS_MASSIVE[note_road].ALL_NOTES.push_back(structured_note_array)
		else:
			var structured_note_array: Array = Tools.create_structured_note_array(true)
			structured_note_array[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.CONTROL_TYPE.HOLDCONTROL
			structured_note_array[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = note_spawn_quarter
			structured_note_array[Global.NOTE_CHART_STRUCTURE.ROAD] = note_road
			var structured_note_additional_info: Array = []
			structured_note_additional_info.resize(len(Global.HOLD_NOTE_ADDITIONAL_INFO))
			structured_note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]\
			= note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]
			structured_note_array[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO] = structured_note_additional_info
			ROADS_MASSIVE[note_road].ALL_NOTES.push_back(structured_note_array)

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
			CHARTMARKERS = MAP_SCENE.get_node("RoadMarkers/1KChartRoadMarkers")
		2:
			CHARTMARKERS = MAP_SCENE.get_node("RoadMarkers/2KChartRoadMarkers")
		3:
			CHARTMARKERS = MAP_SCENE.get_node("RoadMarkers/3KChartRoadMarkers")
		4:
			CHARTMARKERS = MAP_SCENE.get_node("RoadMarkers/4KChartRoadMarkers")
		5:
			CHARTMARKERS = MAP_SCENE.get_node("RoadMarkers/5KChartRoadMarkers")
		6:
			CHARTMARKERS = MAP_SCENE.get_node("RoadMarkers/6KChartRoadMarkers")
	ROADMARKERS_INDEX = CHARTMARKERS.get_index()
	for index in range(chart_size):
		var road_node = ROAD.instantiate()
		road_node.road_index = index
		road_node.name = "Road"+str(index)
		if MAP_SCENE_LOADED:
			road_node.ROAD_POSITION_MARKER = CHARTMARKERS.get_child(index)
		roads_loaded.connect(road_node.get_roads_array)
		ROADS_MASSIVE.push_back(road_node)
		ROADS_HOLDER.add_child(road_node)
	emit_signal("roads_loaded")

# Загружает цвета нот на каждую дорогу
func load_colors(colorways: Array) -> void:
	for colorway in colorways:
		var color_quarter_to_spawn: int = colorway[Global.COLORWAY_CHART_STRUCTURE.QUARTER_TO_SPAWN]
		var colorway_array: Array = colorway[Global.COLORWAY_CHART_STRUCTURE.COLORWAY]
		for color_index in range(len(colorway_array)):
			if color_index + 1 <= Global.CURRENT_CHART_SIZE:
				var color: String = colorway_array[color_index]
				var structured_colorway_array: Array = Tools.create_structured_colorway_array()
				structured_colorway_array[Global.COLORWAY_CHART_STRUCTURE.QUARTER_TO_SPAWN]\
				= color_quarter_to_spawn
				if Color.html_is_valid(color):
					structured_colorway_array[Global.COLORWAY_CHART_STRUCTURE.COLORWAY]\
					= Color.html(color)
				else:
					push_error("Не удалось загрузить html код цвета.")
				ROADS_MASSIVE[color_index].ALL_COLORS.push_back(structured_colorway_array)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Open_Editor"):
		LoadScene.transition("res://Scenes/Editor/ChartEditor.tscn")

func _ready() -> void:
	load_game(true, "Shiawase")
	Tools.create_user_directory()
