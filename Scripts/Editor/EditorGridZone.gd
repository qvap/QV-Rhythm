extends EditorGrid
class_name EditorGridZone

signal zone_changed(changed_cell: Vector2, click_type: int, grid_node: int, type: ZONE_TYPES)

# Дополнительный элемент чартинга. Нужен для настройки зон цвета и т.д.

@export_category("Editor Grid Zone")
enum ZONE_TYPES {COLOR, BPM}
@export var ZONE_TYPE: ZONE_TYPES = ZONE_TYPES.COLOR

func _draw() -> void:
	var cell_color: Color = Color(0.49, 0.88, 0.84, 0.6)
	for cell in GRID_DICTIONARY:
		draw_rect(Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE),\
		cell_color, false)

func register_click(input : int) -> void:
	var mouse_position : Vector2 = get_local_mouse_position()
	if (mouse_position.x > CELL_SIZE * GRID_WIDTH) or (mouse_position.x < 0.0) or (mouse_position.y > CELL_SIZE * GRID_HEIGHT) or (mouse_position.y < 0.0):
		return
	var mouse_position_in_grid : Vector2 = floor(world_to_grid(mouse_position))
	if input == Settings.EDITOR_INPUTS.LEFT_CLICK:
		emit_signal("zone_changed", mouse_position_in_grid, Settings.EDITOR_INPUTS.LEFT_CLICK, self, ZONE_TYPE)
	elif input == Settings.EDITOR_INPUTS.RIGHT_CLICK:
		emit_signal("zone_changed", mouse_position_in_grid, Settings.EDITOR_INPUTS.RIGHT_CLICK, self, ZONE_TYPE)
