extends Node2D
class_name EditorGrid

# Отрисовывает сетку ячеек в редакторе чарта

signal grid_changed(changed_cell: Vector2, click_type: int, grid_node: int)

# Переменные
@export var CHUNK_INDEX : int = 0
@export var CELL_SIZE : float = 96.0
@export var GRID_WIDTH : int = 0
@export var GRID_HEIGHT : int = 0
@export var MEASURE : int = 4
var GRID_DICTIONARY : Dictionary = {}
var SWIPE_ACTIVATED : bool = false

# Создаёт список со всеми ячейками
func generate_grid() -> void:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			GRID_DICTIONARY[Vector2(x, y)] = null

# Рисует ячейки
func _draw() -> void:
	var cell_color: Color = Color(0.941, 0.773, 0.6)
	var beat_cell_color: Color = Color(0.941, 0.773, 0.6, 0.25)
	for cell in GRID_DICTIONARY:
		if fmod(cell.y, float(MEASURE)) == 0.0:
			draw_rect(Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE),\
			beat_cell_color, true)
	for cell in GRID_DICTIONARY:
		draw_rect(Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE),\
		cell_color, false)

# Переводит координаты мира в номер ячейки
func world_to_grid(given_position: Vector2) -> Vector2:
	return (given_position / CELL_SIZE)

# Переводит номер ячейки в координаты мира
func grid_to_world(given_position: Vector2) -> Vector2:
	return (given_position * CELL_SIZE)

# Регистрирует нажатия
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Editor_Left_Click"):
		register_click(Settings.EDITOR_INPUTS.LEFT_CLICK)
	elif event.is_action_pressed("Editor_Right_Click"):
		register_click(Settings.EDITOR_INPUTS.RIGHT_CLICK)
	if event.is_action_pressed("Editor_Shift"):
		SWIPE_ACTIVATED = true
	if event.is_action_released("Editor_Shift"):
		SWIPE_ACTIVATED = false

# При нажатом Shift можно водить мышкой и сразу удалять много нот
func _physics_process(_delta: float) -> void:
	if SWIPE_ACTIVATED and Input.is_action_pressed("Editor_Left_Click"):
		register_click(Settings.EDITOR_INPUTS.LEFT_CLICK)
	elif SWIPE_ACTIVATED and Input.is_action_pressed("Editor_Right_Click"):
		register_click(Settings.EDITOR_INPUTS.RIGHT_CLICK)

func register_click(input : int) -> void:
	var mouse_position : Vector2 = get_local_mouse_position()
	if (mouse_position.x > CELL_SIZE * GRID_WIDTH) or (mouse_position.x < 0.0) or (mouse_position.y > CELL_SIZE * GRID_HEIGHT) or (mouse_position.y < 0.0):
		return
	var mouse_position_in_grid : Vector2 = floor(world_to_grid(mouse_position))
	if input == Settings.EDITOR_INPUTS.LEFT_CLICK:
		emit_signal("grid_changed", mouse_position_in_grid, Settings.EDITOR_INPUTS.LEFT_CLICK, self)
	elif input == Settings.EDITOR_INPUTS.RIGHT_CLICK:
		emit_signal("grid_changed", mouse_position_in_grid, Settings.EDITOR_INPUTS.RIGHT_CLICK, self)
