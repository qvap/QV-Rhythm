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
	var chart := ChartData.load_from(path+"/mapchart0.json")
	chart.resolve_slider_links()

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
	for note in chart.notes:
		match note.type:
			Global.NOTE_TYPE.TAPNOTE:
				ROADS_MASSIVE[note.road].ALL_NOTES.push_back(note)
			Global.NOTE_TYPE.HOLDNOTE:
				ROADS_MASSIVE[note.road].ALL_NOTES.push_back(note)
				setup_hold_controls(note)
			Global.NOTE_TYPE.SLIDER, Global.NOTE_TYPE.SLIDERTICK:
				match Settings.CHOSEN_GAMEPLAY_MODE:
					Settings.GAMEPLAY_MODE.SLIDERS:
						ROADS_MASSIVE[note.road].ALL_NOTES.push_back(note)
						setup_slider_controls(note)
					Settings.GAMEPLAY_MODE.STANDART:
						# В стандартном режиме слайдеры играются как холд ноты
						var hold_note := convert_slider_to_hold(note)
						ROADS_MASSIVE[hold_note.road].ALL_NOTES.push_back(hold_note)
						setup_hold_controls(hold_note)
			Global.NOTE_TYPE.SLIDEREND:
				if Settings.CHOSEN_GAMEPLAY_MODE == Settings.GAMEPLAY_MODE.SLIDERS:
					ROADS_MASSIVE[note.road].ALL_NOTES.push_back(note)

	for road in ROADS_MASSIVE:
		road.ALL_NOTES.sort_custom(sort_notes)
#endregion

	load_colors(chart.color_zones)
	
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
func sort_notes(a: ChartNote, b: ChartNote) -> bool:
	if a.quarter < b.quarter or (a.quarter == b.quarter and a.type < b.type):
		return true
	return false

# Конвертирует слайдер (голову или тик) в холд ноту для стандартного режима
func convert_slider_to_hold(note: ChartNote) -> ChartNote:
	var hold_note := ChartNote.new(Global.NOTE_TYPE.HOLDNOTE, note.quarter, note.next_road)
	hold_note.duration = note.next_quarter - note.quarter
	return hold_note

# Добавляет фантомные контроль-ноты для слайдера на дороге назначения (next_road)
func setup_slider_controls(note: ChartNote) -> void:
	var next_road: int = note.next_road
	var length_in_quarters: float = note.next_quarter - note.quarter
	var full_ticks := floori(length_in_quarters)
	var has_fraction := length_in_quarters != float(full_ticks)

	var control := ChartNote.make_control(Global.CONTROL_TYPE.SLIDERCONTROL, note.quarter, next_road)
	control.slider_id = note.slider_id
	ROADS_MASSIVE[next_road].ALL_NOTES.push_back(control)

	for tick in range(1, full_ticks + 1):
		var is_end := (tick == full_ticks) and not has_fraction
		var control_type: int = Global.CONTROL_TYPE.SLIDERCONTROLEND if is_end\
		else Global.CONTROL_TYPE.SLIDERCONTROLTICK
		ROADS_MASSIVE[next_road].ALL_NOTES.push_back(
			ChartNote.make_control(control_type, note.quarter + float(tick), next_road)
		)

	if has_fraction:
		ROADS_MASSIVE[next_road].ALL_NOTES.push_back(
			ChartNote.make_control(Global.CONTROL_TYPE.SLIDERCONTROLEND,
				note.quarter + length_in_quarters, next_road)
		)

# Фантомные контроль-ноты для холд ноты
func setup_hold_controls(note: ChartNote) -> void:
	var control := ChartNote.make_control(Global.CONTROL_TYPE.HOLDCONTROL, note.quarter, note.road)
	control.duration = note.duration
	ROADS_MASSIVE[note.road].ALL_NOTES.push_back(control)

	var full_ticks := floori(note.duration)
	var has_fraction := note.duration != float(full_ticks)

	for tick in range(1, full_ticks + 1):
		var is_end := (tick == full_ticks) and not has_fraction
		var control_type: int = Global.CONTROL_TYPE.HOLDCONTROLEND if is_end\
		else Global.CONTROL_TYPE.HOLDCONTROLTICK
		ROADS_MASSIVE[note.road].ALL_NOTES.push_back(
			ChartNote.make_control(control_type, note.quarter + float(tick), note.road)
		)

	if has_fraction:
		ROADS_MASSIVE[note.road].ALL_NOTES.push_back(
			ChartNote.make_control(Global.CONTROL_TYPE.HOLDCONTROLEND,
				note.quarter + note.duration, note.road)
		)

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

# Загружает цвета нот на каждую дорогу.
# Каждая зона цвета задаёт по одному цвету на дорогу; на дорогу кладётся
# расписание вида {"quarter": int, "color": Color}.
func load_colors(color_zones: Array[ColorZone]) -> void:
	for zone in color_zones:
		for color_index in range(zone.colors.size()):
			if color_index + 1 <= Global.CURRENT_CHART_SIZE:
				var color_code: String = zone.colors[color_index]
				if Color.html_is_valid(color_code):
					ROADS_MASSIVE[color_index].ALL_COLORS.push_back({
						"quarter": zone.quarter,
						"color": Color.html(color_code)
					})
				else:
					push_error("Не удалось загрузить html код цвета.")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Open_Editor"):
		LoadScene.transition("res://Scenes/Editor/ChartEditor.tscn")

func _ready() -> void:
	load_game(true, "БЭЙСЛАЙН_БИЗНЕС")
	Tools.create_user_directory()
