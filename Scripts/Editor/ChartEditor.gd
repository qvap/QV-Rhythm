extends Node2D
class_name ChartEditor

# Редактор чартов

@onready var EDITOR_GRID_RESOURCE := load("res://Scenes/Editor/EditorGrid.tscn")
@onready var EDITOR_ZONE_RESOURCE := load("res://Scenes/Editor/EditorGridZone.tscn")
@onready var GRID_CONTAINER: Node2D = $GridContainer
@onready var GRID_HOLDER: Node2D = $GridContainer/GridHolder
@onready var GRID_COLOR_ZONE_HOLDER: Node2D = $GridContainer/GridColorZoneHolder
@onready var CHART_SLIDER: VSlider = $UI/MarginContainer/ChartSlider
@onready var CHART_SLIDER_CONTAINER: MarginContainer = $UI/MarginContainer
@onready var ABOVE_LINE_CONTAINER: Container = $UI/AboveLineContainer
@onready var CURRENT_CHUNK_LABEL: Label = $UI/AboveLineContainer/CurrentChunk
@onready var CURRENT_SONG_POSITION: Label = $UI/AboveLineContainer/CurrentSongPosition
@onready var SIDE_BAR: ChartEditorSideBar = $UI/ChartEditorSideBar
@onready var COLOR_ZONE_LIST: ColorZoneList = $UI/ColorZoneList
@onready var SAVE_CHART_LABEL: Label = $UI/SaveChartLabel
@onready var BPM_LABEL: Label = $UI/VBoxContainer/HBoxContainer/BPMLabel
@onready var CAMERA: Camera2D = $Camera2D

var CURRENT_MAPCHART : Dictionary # чарт, редактируемый сейчас
var CURRENT_MAPCHART_JSON_PATH: String # путь до файла чарта
enum CELL_DATA_STRUCTURE {INDICATOR_TYPE, INDICATOR_NODE}

@export var CHUNKS : int = 4
@export var CHART_SIZE : int = 4
@export var CHUNK_LENGTH : int = 4
@export var QUARTERS_IN_BEAT : int = 4
@export var PLAY_SPEED : float = 0.0
@export var SCROLL_SPEED : float = 56.0

enum INDICATOR_TYPE {TAP, HOLD, SLIDE, ZONE_COLOR, ZONE_BPM}
var INDICATOR_RESOURCE := load("res://Scenes/Editor/NoteIndicator.tscn")
var CURRENT_INDICATOR_TYPE : INDICATOR_TYPE = INDICATOR_TYPE.TAP

var UP_LIMIT : float = 0.0
var DOWN_LIMIT : float = 1000.0

var PLAYING : bool = false
var SCROLL_POSITION : float = 0.0

var CURRENT_CELL_SIZE : float = 0.0
var CURRENT_CHUNK : int = 0

var INPUT_SHIFT_LAYER : bool = false

var PLAY_METRONOME: bool = true

# Настраивает размеры сетки
func setup_grid(grid_instance: EditorGrid, chunk_index: int) -> void:
	grid_instance.GRID_WIDTH = CHART_SIZE
	grid_instance.GRID_HEIGHT = CHUNK_LENGTH
	grid_instance.CHUNK_INDEX = chunk_index
	grid_instance.position.y = CHUNK_LENGTH * grid_instance.CELL_SIZE * chunk_index
	grid_instance.generate_grid()
	grid_instance.queue_redraw()
	grid_instance.connect("grid_changed", grid_changed)
	grid_instance.modulate.a = 0.25

func setup_zone(zone_instance: EditorGridZone, chunk_index: int, type: EditorGridZone.ZONE_TYPES) -> void:
	zone_instance.ZONE_TYPE = type
	zone_instance.GRID_WIDTH = 1
	zone_instance.GRID_HEIGHT = CHUNK_LENGTH
	zone_instance.CHUNK_INDEX = chunk_index
	zone_instance.position.y = CHUNK_LENGTH * zone_instance.CELL_SIZE * chunk_index
	zone_instance.generate_grid()
	zone_instance.queue_redraw()
	zone_instance.connect("zone_changed", zone_changed)

# Генерирует дорогу из чанков сетки
func generate_editor_road() -> void:
	for chunk in range(CHUNKS):
		var grid_init: EditorGrid = EDITOR_GRID_RESOURCE.instantiate()
		var grid_color_zone_init: EditorGridZone = EDITOR_ZONE_RESOURCE.instantiate()
		setup_grid(grid_init, chunk)
		setup_zone(grid_color_zone_init, chunk, EditorGridZone.ZONE_TYPES.COLOR)
		GRID_HOLDER.add_child(grid_init)
		GRID_COLOR_ZONE_HOLDER.add_child(grid_color_zone_init)
		CURRENT_CELL_SIZE = grid_init.CELL_SIZE

# Меняет значение в выбранном чанке и ставит индикатор
func grid_changed(changed_cell: Vector2, click_type: int, chunk_grid_node: EditorGrid):
	var current_grid_dictionary : Dictionary = chunk_grid_node.GRID_DICTIONARY
	match click_type:
		Settings.EDITOR_INPUTS.LEFT_CLICK:
			if current_grid_dictionary[changed_cell] == null:
				var indicator_init: EditorIndicator = INDICATOR_RESOURCE.instantiate()
				indicator_init.TYPE = CURRENT_INDICATOR_TYPE
				if indicator_init.TYPE == INDICATOR_TYPE.SLIDE:
					indicator_init.SLIDER_ID = SIDE_BAR.CURRENT_SLIDER_ID
				current_grid_dictionary[changed_cell] = [CURRENT_INDICATOR_TYPE, indicator_init]
				indicator_init.position = chunk_grid_node.grid_to_world(changed_cell)
				indicator_init.position.x += CURRENT_CELL_SIZE / 2.0
				indicator_init.position.y += CURRENT_CELL_SIZE / 2.0
				chunk_grid_node.add_child(indicator_init)
		Settings.EDITOR_INPUTS.RIGHT_CLICK:
			if current_grid_dictionary[changed_cell] != null:
				current_grid_dictionary[changed_cell][1].queue_free()
				current_grid_dictionary[changed_cell] = null
	chunk_grid_node.queue_redraw()

func zone_changed(changed_cell: Vector2, click_type: int, chunk_zone_node: EditorGridZone, zone_type: int):
	var current_zone_dictionary : Dictionary = chunk_zone_node.GRID_DICTIONARY
	match click_type:
		Settings.EDITOR_INPUTS.LEFT_CLICK:
			if current_zone_dictionary[changed_cell] == null:
				var indicator_init: EditorIndicator = INDICATOR_RESOURCE.instantiate()
				match zone_type:
					EditorGridZone.ZONE_TYPES.COLOR:
						indicator_init.TYPE = INDICATOR_TYPE.ZONE_COLOR
						if len(COLOR_ZONE_LIST.SELECTED_COLORWAY) != 0:
							indicator_init.COLOR_ZONE_NAME = COLOR_ZONE_LIST.SELECTED_COLORWAY[0]
							current_zone_dictionary[changed_cell] = [indicator_init, COLOR_ZONE_LIST.SELECTED_COLORWAY[1]]
						else:
							return # надо будет сделать систему увед и сюда тоже вставить
					EditorGridZone.ZONE_TYPES.BPM:
						indicator_init.TYPE = INDICATOR_TYPE.ZONE_BPM
				
				indicator_init.position = chunk_zone_node.grid_to_world(changed_cell)
				indicator_init.position.x += CURRENT_CELL_SIZE / 2.0
				indicator_init.position.y += CURRENT_CELL_SIZE / 2.0
				chunk_zone_node.add_child(indicator_init)
		Settings.EDITOR_INPUTS.RIGHT_CLICK:
			if current_zone_dictionary[changed_cell] != null:
				current_zone_dictionary[changed_cell][0].queue_free()
				current_zone_dictionary[changed_cell] = null
	chunk_zone_node.queue_redraw()

# Листает всю дорогу и помечает чанк
func slider_changed(value: float) -> void:
	SCROLL_POSITION = -value
	change_chunk_opacity()

# Чтобы помечать чанк, ибо из-за process при быстрой прокрутке сбивается
func slider_released(_value: float) -> void:
	change_chunk_opacity()

# Все кнопки
func _unhandled_input(event: InputEvent) -> void:
	if !PLAYING:
		if event.is_action_pressed("Editor_Scroll_Up"):
			var scroll_speed: float
			if INPUT_SHIFT_LAYER:
				scroll_speed = SCROLL_SPEED * 10.0
			else:
				scroll_speed = SCROLL_SPEED
			if Settings.EDITOR_DOWNSCROLL:
				SCROLL_POSITION += scroll_speed
				SCROLL_POSITION = minf(SCROLL_POSITION, UP_LIMIT)
			else:
				SCROLL_POSITION -= scroll_speed
				SCROLL_POSITION = maxf(SCROLL_POSITION, DOWN_LIMIT)
			change_chunk_opacity()
			CHART_SLIDER.value = -SCROLL_POSITION
			update_song_position_text()
		if event.is_action_pressed("Editor_Scroll_Down"):
			var scroll_speed: float
			if INPUT_SHIFT_LAYER:
				scroll_speed = SCROLL_SPEED * 10.0
			else:
				scroll_speed = SCROLL_SPEED
			if Settings.EDITOR_DOWNSCROLL:
				SCROLL_POSITION -= scroll_speed
				SCROLL_POSITION = maxf(SCROLL_POSITION, DOWN_LIMIT)
			else:
				SCROLL_POSITION += scroll_speed
				SCROLL_POSITION = minf(SCROLL_POSITION, UP_LIMIT)
			change_chunk_opacity()
			CHART_SLIDER.value = -SCROLL_POSITION
			update_song_position_text()
	if event.is_action_pressed("Editor_Play"):
		if PLAYING:
			stop()
		else:
			if INPUT_SHIFT_LAYER:
				play_from_start()
			else:
				play_from_position(-SCROLL_POSITION / PLAY_SPEED)
	if event.is_action_pressed("Editor_Shift"):
		INPUT_SHIFT_LAYER = true # при зажатом шифте активирует ещё одни сочетания
	if event.is_action_released("Editor_Shift"):
		INPUT_SHIFT_LAYER = false

# Если playing, то листает само, если нет, то активирует ручное пролистывание
func _process(delta: float) -> void:
	if PLAYING:
		CHART_SLIDER.value = -GRID_HOLDER.position.y
		GRID_HOLDER.position.y -= PLAY_SPEED * delta
		change_chunk_opacity()
		update_song_position_text()
	else:
		# Шоб листалось храсиво
		GRID_HOLDER.position.y = lerp(GRID_HOLDER.position.y, SCROLL_POSITION, 0.2)
	GRID_COLOR_ZONE_HOLDER.position.y = GRID_HOLDER.position.y
	queue_redraw()

# Рисует линию посередине экрана
func _draw() -> void:
	draw_line(Vector2(0.0, CAMERA.get_screen_center_position().y),\
	Vector2(get_viewport_rect().size.x, CAMERA.get_screen_center_position().y),\
	Color(1, 0.23, 0.23), 4.0)

# Обновляет значение текста положения музыки
func update_song_position_text() -> void:
	CURRENT_SONG_POSITION.text = "Current song position (in seconds): " +\
	str(snapped(maxf(-SCROLL_POSITION / PLAY_SPEED, 0.0), 0.01))

#region Старт и стоп
# Запускает проигрывание песни
func play_from_start() -> void:
	Conductor.editor_play_song()
	queue_redraw()
	SCROLL_POSITION = UP_LIMIT
	GRID_HOLDER.position.y = SCROLL_POSITION
	PLAYING = true

func play_from_position(song_position: float) -> void:
	Conductor.editor_play_song_from_position(song_position)
	queue_redraw()
	SCROLL_POSITION = UP_LIMIT - song_position * PLAY_SPEED
	GRID_HOLDER.position.y = SCROLL_POSITION
	PLAYING = true

# Останавливает проигрывание
func stop() -> void:
	Conductor.editor_stop_song()
	queue_redraw()
	if GRID_HOLDER.position.y <= (-(CURRENT_CELL_SIZE * CHUNK_LENGTH * CHUNKS) + DOWN_LIMIT):
		SCROLL_POSITION = (-(CURRENT_CELL_SIZE * CHUNK_LENGTH * CHUNKS) + DOWN_LIMIT)
	else:
		SCROLL_POSITION = GRID_HOLDER.position.y
	PLAYING = false
#endregion

#region Current Chunk и настройка отображения
# Возвращает чанк, выбранный сейчас
func get_focused_chunk() -> int:
	return floor((abs(SCROLL_POSITION)) / (CURRENT_CELL_SIZE * CHUNK_LENGTH))

# Меняет прозрачность чанка
func change_chunk_opacity() -> void:
	for grid in GRID_HOLDER.get_children():
		var corresponding_zone: EditorGridZone = GRID_COLOR_ZONE_HOLDER.get_child(grid.get_index())
		grid.modulate.a = 0.25
		grid.visible = false
		corresponding_zone.modulate.a = 0.25
		corresponding_zone.visible = false
	var focused_chunk: int = get_focused_chunk()
	CURRENT_CHUNK = focused_chunk
	for grid in range(3):
		if focused_chunk - 1 + grid < len(GRID_HOLDER.get_children()):
			GRID_HOLDER.get_child(focused_chunk - 1 + grid).visible = true
			GRID_COLOR_ZONE_HOLDER.get_child(focused_chunk - 1 + grid).visible = true
	GRID_HOLDER.get_child(focused_chunk).modulate.a = 1.0
	GRID_COLOR_ZONE_HOLDER.get_child(focused_chunk).modulate.a = 1.0
	CURRENT_CHUNK_LABEL.text = "Current measure (chunk): "+str(focused_chunk + 1)
#endregion

# Как load_game в gamespace, только поменьше
func load_files(core_level: bool, custom_map_folder_name: String) -> void:
	var path: String
	if core_level: path = "res://CustomMaps/"+custom_map_folder_name
	else: path = "user://Maps/"+custom_map_folder_name
	var mapdata = Tools.parse_json(path+"/mapdata.json")
	var mapchart = Tools.parse_json(path+"/mapchart0.json")
	CURRENT_MAPCHART = mapchart
	CURRENT_MAPCHART_JSON_PATH = path+"/mapchart0.json"
	
	Conductor.load_song_from_json(mapdata, custom_map_folder_name)
	Conductor.run()
	BPM_LABEL.text = str(Conductor.bpm)
	
	CHUNKS = int(Conductor.song_length / Conductor.s_per_measure)
	CHUNK_LENGTH = Conductor.measure * QUARTERS_IN_BEAT
	CHART_SIZE = mapdata["chart_size"]
	generate_editor_road()
	adjust_grid_on_start_position()
	load_map(CURRENT_MAPCHART)
	PLAY_SPEED = CURRENT_CELL_SIZE / Conductor.s_per_quarter

# Загружает в сетку JSON файл чарта
func load_map(mapchart: Dictionary) -> void:
	var notes: Array = mapchart["Notes"]
	var colorways: Array = mapchart["ColorZones"]
	
	# ещё одна итерация, чтобы создать конечные точки холд нот
	for hold_note in notes:
		if hold_note[Global.NOTE_CHART_STRUCTURE.TYPE] == Global.NOTE_TYPE.HOLDNOTE and\
		len(hold_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]) != 0:
			var quarter_to_spawn: int = hold_note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] +\
			hold_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]
			var structured_note_array: Array = []
			structured_note_array.resize(len(Global.NOTE_CHART_STRUCTURE.values()))
			structured_note_array[Global.NOTE_CHART_STRUCTURE.TYPE] = hold_note[Global.NOTE_CHART_STRUCTURE.TYPE]
			structured_note_array[Global.NOTE_CHART_STRUCTURE.ROAD] = hold_note[Global.NOTE_CHART_STRUCTURE.ROAD]
			structured_note_array[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = quarter_to_spawn
			structured_note_array[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO] = []
			notes.push_back(structured_note_array)
	
	for note in notes:
		
		var indicator_init: EditorIndicator = INDICATOR_RESOURCE.instantiate()
		var chunk_index: int = floor(note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]/CHUNK_LENGTH)
		var corresponding_chunk: EditorGrid = GRID_HOLDER.get_child(chunk_index)
		var current_cell: Vector2 = Vector2(note[Global.NOTE_CHART_STRUCTURE.ROAD],\
		get_cell_in_quarter(note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN], chunk_index))
		var corresponding_dictionary: Dictionary = corresponding_chunk.GRID_DICTIONARY
		var note_type: int = note[Global.NOTE_CHART_STRUCTURE.TYPE]
		
		match note_type:
			Global.NOTE_TYPE.TAPNOTE:
				indicator_init.TYPE = INDICATOR_TYPE.TAP
			Global.NOTE_TYPE.HOLDNOTE:
				indicator_init.TYPE = INDICATOR_TYPE.HOLD
			Global.NOTE_TYPE.SLIDER:
				indicator_init.TYPE = INDICATOR_TYPE.SLIDE
				indicator_init.SLIDER_ID = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.ID]
			Global.NOTE_TYPE.SLIDERTICK:
				indicator_init.TYPE = INDICATOR_TYPE.SLIDE
				indicator_init.SLIDER_ID = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.ID]
			Global.NOTE_TYPE.SLIDEREND:
				indicator_init.TYPE = INDICATOR_TYPE.SLIDE
				indicator_init.SLIDER_ID = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.ID]
				SIDE_BAR.CURRENT_SLIDER_ID = maxi(indicator_init.SLIDER_ID, SIDE_BAR.CURRENT_SLIDER_ID)
			
		corresponding_dictionary[Vector2(note[Global.NOTE_CHART_STRUCTURE.ROAD],\
		get_cell_in_quarter(note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN], chunk_index))] =\
		[indicator_init.TYPE, indicator_init]
		
		indicator_init.position = corresponding_chunk.grid_to_world(current_cell)
		indicator_init.position.x += CURRENT_CELL_SIZE / 2.0
		indicator_init.position.y += CURRENT_CELL_SIZE / 2.0
		corresponding_chunk.add_child(indicator_init)
	
	var loading_colorways_array: Array = []
	
	for colorway in colorways:
		
		var colorway_array: Array = []
		for color in colorway[Global.COLORWAY_CHART_STRUCTURE.COLORWAY]:
			if Color.html_is_valid(color):
				colorway_array.push_back(Color.html(color))
			else:
				push_error("Неправильный код html цвета!")
		
		var colorway_quarter_to_spawn: int = colorway[Global.COLORWAY_CHART_STRUCTURE.QUARTER_TO_SPAWN]
		
		var indicator_init: EditorIndicator = INDICATOR_RESOURCE.instantiate()
		indicator_init.TYPE = INDICATOR_TYPE.ZONE_COLOR
		var chunk_index: int = floor(float(colorway_quarter_to_spawn)/CHUNK_LENGTH)
		var corresponding_chunk: EditorGridZone = GRID_COLOR_ZONE_HOLDER.get_child(chunk_index)
		var current_cell: Vector2 = Vector2(0, get_cell_in_quarter(colorway_quarter_to_spawn, chunk_index))
		var corresponding_dictionary: Dictionary = corresponding_chunk.GRID_DICTIONARY
		corresponding_dictionary[Vector2(0, get_cell_in_quarter(colorway_quarter_to_spawn, chunk_index))] =\
		[indicator_init, colorway_array]
		
		indicator_init.position = corresponding_chunk.grid_to_world(current_cell)
		indicator_init.position.x += CURRENT_CELL_SIZE / 2.0
		indicator_init.position.y += CURRENT_CELL_SIZE / 2.0
		
		var loading_colorway_array: Array = []
		loading_colorway_array.resize(2)
		loading_colorway_array[0] = "Color"
		loading_colorway_array[1] = colorway_array
		if !(loading_colorway_array in loading_colorways_array):
			loading_colorways_array.push_back(loading_colorway_array)
		
		corresponding_chunk.add_child(indicator_init)
	
	COLOR_ZONE_LIST.update_list(loading_colorways_array)

# Сохраняет сделанный чарт в JSON файл
func save_map() -> void:
	var saving_chart: Dictionary = {"Notes" : [], "ColorZones" : []}
	var saving_note_array: Array = saving_chart["Notes"]
	var saving_color_array: Array = saving_chart["ColorZones"]
	
	var hold_connected: bool = true # помечает холд ноты, которые уже сохранены
	var slider_indexes: Array = [] # будет держать в себе айди сохраняемых слайдеров
	
	#region Сохранение нот
	for grid_index in range(GRID_HOLDER.get_child_count()): # каждая сетка в холдере
		
		var grid: EditorGrid = GRID_HOLDER.get_child(grid_index)
		
		for cell in grid.GRID_DICTIONARY: # каждый элемент в списке сетки
			
			if grid.GRID_DICTIONARY[cell] != null: # если в клетке ничего нет, то скипает
			
				var current_cell_data: Array = grid.GRID_DICTIONARY[cell]
				var note_road: int = cell.x
				var note_quarter_to_spawn: int = get_quarter_in_cell(cell, grid_index)
				var structured_note_array: Array
				
				match current_cell_data[CELL_DATA_STRUCTURE.INDICATOR_TYPE]:
					
					INDICATOR_TYPE.TAP:
						structured_note_array = Tools.create_structured_note_array(false)
						structured_note_array[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.NOTE_TYPE.TAPNOTE
						structured_note_array[Global.NOTE_CHART_STRUCTURE.ROAD] = note_road
						structured_note_array[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = note_quarter_to_spawn
						saving_note_array.push_back(structured_note_array)
						
					INDICATOR_TYPE.HOLD:
						structured_note_array = Tools.create_structured_note_array(true)
						var hold_status: bool = current_cell_data[CELL_DATA_STRUCTURE.INDICATOR_NODE].HOLD_CONNECTED
						if hold_status == false:
							current_cell_data[CELL_DATA_STRUCTURE.INDICATOR_NODE].HOLD_CONNECTED = hold_connected
							var structured_note_additional_info: Array = []
							structured_note_additional_info.resize(len(Global.HOLD_NOTE_ADDITIONAL_INFO.values()))
							structured_note_array[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.NOTE_TYPE.HOLDNOTE
							structured_note_array[Global.NOTE_CHART_STRUCTURE.ROAD] = note_road
							structured_note_array[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = get_quarter_in_cell(cell, grid_index)
							structured_note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION] =\
							iterate_for_hold_note_save(grid_index, cell, hold_connected)
							if structured_note_additional_info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION] == null:
								push_error("Данный чарт не соответствует требованиям!")
								return
							structured_note_array[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO] = structured_note_additional_info
							saving_note_array.push_back(structured_note_array)
						else:
							continue
						
					INDICATOR_TYPE.SLIDE:
						structured_note_array = Tools.create_structured_note_array(true)
						var slider_id: int = current_cell_data[CELL_DATA_STRUCTURE.INDICATOR_NODE].SLIDER_ID
						if !(slider_id in slider_indexes):
							var structured_note_additional_info: Array = []
							structured_note_additional_info.resize(len(Global.SLIDER_NOTE_ADDITIONAL_INFO.values()) - 2)
							structured_note_array[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.NOTE_TYPE.SLIDER
							structured_note_array[Global.NOTE_CHART_STRUCTURE.ROAD] = note_road
							structured_note_array[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = note_quarter_to_spawn
							structured_note_additional_info[Global.SLIDER_NOTE_ADDITIONAL_INFO.ID] = slider_id
							structured_note_array[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO] = structured_note_additional_info
							saving_note_array.push_back(structured_note_array)
							var iterated_array: Array = iterate_for_slider_note_save(grid_index, cell, slider_id)
							for note in iterated_array:
								saving_note_array.push_back(note)
							slider_indexes.push_back(slider_id)
			else:
				continue
	
	reset_hold_notes_status()
	#endregion
	
	#region Сохранение зон цвета
	for zone_index in range(GRID_COLOR_ZONE_HOLDER.get_child_count()):
		
		var zone: EditorGridZone = GRID_COLOR_ZONE_HOLDER.get_child(zone_index)
		
		for cell in zone.GRID_DICTIONARY:
			
			if zone.GRID_DICTIONARY[cell] != null:
			
				var current_cell_data: Array = zone.GRID_DICTIONARY[cell]
				var current_colorway: Array = current_cell_data[1].duplicate()
				for color_index in len(current_colorway):
					current_colorway[color_index] = current_colorway[color_index].to_html(false)
				var colorway_quarter_to_spawn: int = get_quarter_in_cell(cell, zone_index)
				var structured_colorway_array: Array = Tools.create_structured_colorway_array()
				structured_colorway_array[Global.COLORWAY_CHART_STRUCTURE.QUARTER_TO_SPAWN] = colorway_quarter_to_spawn
				structured_colorway_array[Global.COLORWAY_CHART_STRUCTURE.COLORWAY] = current_colorway
				saving_color_array.push_back(structured_colorway_array)
	#endregion
	
	saving_chart["Notes"] = saving_note_array
	saving_chart["ColorZones"] = saving_color_array
	Tools.save_json(CURRENT_MAPCHART_JSON_PATH, saving_chart)
	save_chart_label_blink()

# Получает клетку с индикатором холд ноты, ищет следующий индикатор холд ноты
# и возвращает разницу времени спавна между ними
func iterate_for_hold_note_save(given_grid_index: int, given_cell: Vector2, given_status: bool):
	
	for grid_index in range(given_grid_index, GRID_HOLDER.get_child_count()):
		
		var grid: EditorGrid = GRID_HOLDER.get_child(grid_index)
		
		for cell in grid.GRID_DICTIONARY:
			
			if grid.GRID_DICTIONARY[cell] != null:
			
				var note_indicator_type: int = grid.GRID_DICTIONARY[cell][CELL_DATA_STRUCTURE.INDICATOR_TYPE]
				var indicator_node: EditorIndicator = grid.GRID_DICTIONARY[cell][CELL_DATA_STRUCTURE.INDICATOR_NODE]
				
				# проверка на нужную дорогу и разную четверть спавна
				if !indicator_node.HOLD_CONNECTED and note_indicator_type == INDICATOR_TYPE.HOLD and cell.x == given_cell.x\
				and get_quarter_in_cell(cell, grid_index) != get_quarter_in_cell(given_cell, given_grid_index):
					
					grid.GRID_DICTIONARY[cell][CELL_DATA_STRUCTURE.INDICATOR_NODE].HOLD_CONNECTED = given_status
					return get_quarter_in_cell(cell, grid_index) - get_quarter_in_cell(given_cell, given_grid_index)
					
				else:
					continue
			else:
				continue
	
	return null # если ничего не нашлось

# Сбрасывает значения у холд нот HOLD_CONNECTED
# (исправляет баг, при котором при сохранении из чарта пропадают холд ноты)
func reset_hold_notes_status() -> void:
	for grid_index in range(GRID_HOLDER.get_child_count()):
		var grid: EditorGrid = GRID_HOLDER.get_child(grid_index)
		for cell in grid.GRID_DICTIONARY:
			if grid.GRID_DICTIONARY[cell] != null and\
			grid.GRID_DICTIONARY[cell][CELL_DATA_STRUCTURE.INDICATOR_TYPE] == INDICATOR_TYPE.HOLD:
				grid.GRID_DICTIONARY[cell][CELL_DATA_STRUCTURE.INDICATOR_NODE].HOLD_CONNECTED = false

# Получает клетку с индикатором слайдер ноты и её айди, после чего ищет все появления
# слайдер индикаторов с этим айди и возвращает список со всеми найденными нотами
func iterate_for_slider_note_save(given_grid_index: int, given_cell: Vector2, given_slider_id: int) -> Array:
	
	var array_for_return: Array = []
	
	for grid_index in range(given_grid_index, GRID_HOLDER.get_child_count()):
		
		var grid: EditorGrid = GRID_HOLDER.get_child(grid_index)
		
		for cell in grid.GRID_DICTIONARY:
			
			if grid.GRID_DICTIONARY[cell] != null:
			
				var note_indicator_type: int = grid.GRID_DICTIONARY[cell][CELL_DATA_STRUCTURE.INDICATOR_TYPE]
				var note_slider_id: int = grid.GRID_DICTIONARY[cell][CELL_DATA_STRUCTURE.INDICATOR_NODE].SLIDER_ID
				
				if note_indicator_type == INDICATOR_TYPE.SLIDE and\
				note_slider_id == given_slider_id and\
				get_quarter_in_cell(cell, grid_index) != get_quarter_in_cell(given_cell, given_grid_index):
					
					var structured_note: Array = Tools.create_structured_note_array(true)
					var structured_note_additional_info: Array = []
					structured_note_additional_info.resize(len(Global.SLIDER_NOTE_ADDITIONAL_INFO.values()) - 2)
					# Если что, не забудь, что сверху -2, потому что остальные 2 элемента служебные
					
					structured_note[Global.NOTE_CHART_STRUCTURE.ROAD] = cell.x
					structured_note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] = get_quarter_in_cell(cell, grid_index)
					structured_note_additional_info[Global.SLIDER_NOTE_ADDITIONAL_INFO.ID] = given_slider_id
					structured_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO] = structured_note_additional_info
					
					array_for_return.push_back(structured_note)
			else:
				continue
	
	# Дополнительно проходится по списку, чтобы выставить нужные типы слайдера
	for note_index in range(len(array_for_return)):
		var note: Array = array_for_return[note_index]
		if note_index == len(array_for_return) - 1:
			note[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.NOTE_TYPE.SLIDEREND
		else:
			note[Global.NOTE_CHART_STRUCTURE.TYPE] = Global.NOTE_TYPE.SLIDERTICK
	
	return array_for_return

# Звук метронома
func metronome_sound(_current_beat: int) -> void:
	if PLAY_METRONOME:
		Conductor.play_hitsound()

# Очищает все сетки от нот
func clear_all() -> void:
	for grid_index in range(GRID_HOLDER.get_child_count()):
		
		var grid: EditorGrid = GRID_HOLDER.get_child(grid_index)
		
		for cell in grid.GRID_DICTIONARY:
			
			if grid.GRID_DICTIONARY[cell] != null:
				grid.GRID_DICTIONARY[cell][CELL_DATA_STRUCTURE.INDICATOR_NODE].queue_free()
				grid.GRID_DICTIONARY[cell] = null

# Возвращает глобальное значение Y данной клетки
func get_quarter_in_cell(cell: Vector2, grid_index: int) -> int:
	return int(cell.y) + (grid_index * CHUNK_LENGTH)

# Обратная функция
func get_cell_in_quarter(quarter: int, grid_index: int) -> int:
	return quarter - (grid_index * CHUNK_LENGTH)

# Мигающая плашка "Сохранено"
func save_chart_label_blink() -> void:
	SAVE_CHART_LABEL.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(SAVE_CHART_LABEL, "modulate:a", 0.0, 3.0)

# Настраивает BPM в кондукторе
func change_bpm(is_left: bool, is_double: bool) -> void:
	var amount: int
	if is_double:
		amount = 10
	else:
		amount = 1
	if is_left:
		Conductor.bpm -= amount
	else:
		Conductor.bpm += amount
	BPM_LABEL.text = str(Conductor.bpm)
	Conductor.update()

# Настраивает положение камеры и слайдера в зависимости от выбранной настройки
func downscroll() -> void:
	if Settings.EDITOR_DOWNSCROLL:
		CAMERA.zoom.y = 1.0
		CHART_SLIDER_CONTAINER.rotation_degrees = 180.0
	else:
		CAMERA.zoom.y = -1.0
		CHART_SLIDER_CONTAINER.rotation_degrees = 0.0

# Настраивает лимиты скролла сетки и слайдера
func adjust_grid_on_start_position() -> void:
	UP_LIMIT = 0.0
	DOWN_LIMIT = -(CURRENT_CELL_SIZE * CHUNK_LENGTH * CHUNKS) + 1.0 # без единицы всё ломается (буквально пиксель)
	SCROLL_POSITION = UP_LIMIT
	GRID_HOLDER.position.y = UP_LIMIT
	
	# Настраивает слайдер
	CHART_SLIDER.tick_count = CHUNKS
	CHART_SLIDER.max_value = -DOWN_LIMIT
	CHART_SLIDER.value = 0.0

func _ready() -> void:
	downscroll()
	Conductor.beat_hit.connect(metronome_sound)
	load_files(true, "Shiawase")
	change_chunk_opacity()
