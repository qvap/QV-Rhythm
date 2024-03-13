extends Control
class_name ColorZoneList

#@onready var SIDEBAR: ChartEditorSideBar = get_parent()

@onready var PANEL_BUTTON: Button = $HBoxContainer/PanelContainer/ContentContainer/Button
@onready var PANEL_BUTTON_SIZE_Y: float = PANEL_BUTTON.custom_minimum_size.y

@onready var PANEL_CONTAINER: PanelContainer = $HBoxContainer/PanelContainer

@onready var SAVED_ZONES_CONTAINER: VBoxContainer = $HBoxContainer/PanelContainer/ContentContainer/SmoothScrollContainer/SavedZonesContainer
var COLORWAY_PANELS_ARRAY: Array = []
var COLORWAYS: Array = []
var SELECTED_COLORWAY: Array = []
var SELECTED_PANEL: ColorZonePanel

@onready var CONTENT_POSITION_Y: float = -(PANEL_CONTAINER.size.y - PANEL_BUTTON_SIZE_Y)

var COLOR_ZONE_EDITOR: Resource = preload("res://Scenes/Editor/ColorZoneEditor/ColorZoneEditor.tscn")
var COLOR_PANEL: Resource = preload("res://Scenes/Editor/ColorZoneEditor/ColorZonePanel.tscn")

@onready var CHART_SIZE: int = get_parent().get_parent().CHART_SIZE
var CLOSED: bool = true

# Закрывает или открывает панельку
func toggle_panel():
	CLOSED = !CLOSED
	update_position()

func _process(_delta: float) -> void:
	# Плавно меняет положение контейнера на CONTENT_POSITION_Y
	PANEL_CONTAINER.position.y = lerp(PANEL_CONTAINER.position.y, CONTENT_POSITION_Y, 0.1)

func update_position() -> void:
	CONTENT_POSITION_Y = -(PANEL_CONTAINER.size.y - PANEL_BUTTON_SIZE_Y) if CLOSED else 0.0

func _draw() -> void:
	await get_tree().process_frame
	update_position()

func open_color_editor() -> void:
	var color_zone_editor_init: ColorZoneEditor = COLOR_ZONE_EDITOR.instantiate()
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.layer = 100
	color_zone_editor_init.editing_finished.connect(update_list)
	color_zone_editor_init.COLOR_PANEL = COLOR_PANEL.duplicate()
	color_zone_editor_init.CHART_SIZE = CHART_SIZE
	color_zone_editor_init.LOAD_COLORWAYS = COLORWAYS
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(color_zone_editor_init)

func select_colorway(panel: ColorZonePanel) -> void:
	if SELECTED_PANEL != null:
		SELECTED_PANEL.selected_modulate(false)
	SELECTED_PANEL = panel
	SELECTED_PANEL.selected_modulate(true)
	SELECTED_COLORWAY = [panel.NAME, panel.COLORWAY.duplicate()]

func update_list(colorways_array: Array) -> void:
	COLORWAYS = colorways_array.duplicate()
	for panel in COLORWAY_PANELS_ARRAY:
		panel.queue_free()
	COLORWAY_PANELS_ARRAY.clear()
	SELECTED_COLORWAY = []
	SELECTED_PANEL = null
	for colorway_index in len(COLORWAYS):
		var panel_name: String = COLORWAYS[colorway_index][0]
		var panel_colorway: Array = COLORWAYS[colorway_index][1]
		var color_panel_init: ColorZonePanel = COLOR_PANEL.instantiate()
		color_panel_init.NAME = panel_name
		color_panel_init.COLORWAY = panel_colorway.duplicate()
		color_panel_init.CHART_SIZE = CHART_SIZE
		color_panel_init.PANEL_TYPE = ColorZonePanel.TYPE.LIST
		SAVED_ZONES_CONTAINER.add_child(color_panel_init)
		color_panel_init.SELECT_BUTTON.pressed.connect(select_colorway.bind(color_panel_init))
		COLORWAY_PANELS_ARRAY.push_back(color_panel_init)
	queue_redraw()
