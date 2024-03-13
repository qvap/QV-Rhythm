extends Control
class_name ColorZoneEditor

signal editing_finished(colorways: Array)

@onready var NOTE_COLOR_BUTTONS: Array = [
	$CenterContainer/AllContainer/WindowsContainer/ContentPanel/LeftWindowContainer/MainLeftWindowContainer/NotePanelContainer/NotesContainer/Note1,
	$CenterContainer/AllContainer/WindowsContainer/ContentPanel/LeftWindowContainer/MainLeftWindowContainer/NotePanelContainer/NotesContainer/Note2,
	$CenterContainer/AllContainer/WindowsContainer/ContentPanel/LeftWindowContainer/MainLeftWindowContainer/NotePanelContainer/NotesContainer/Note3,
	$CenterContainer/AllContainer/WindowsContainer/ContentPanel/LeftWindowContainer/MainLeftWindowContainer/NotePanelContainer/NotesContainer/Note4,
	$CenterContainer/AllContainer/WindowsContainer/ContentPanel/LeftWindowContainer/MainLeftWindowContainer/NotePanelContainer/NotesContainer/Note5,
	$CenterContainer/AllContainer/WindowsContainer/ContentPanel/LeftWindowContainer/MainLeftWindowContainer/NotePanelContainer/NotesContainer/Note6
]
@onready var COLOR_PICKER_PANEL: PanelContainer = $CenterContainer/AllContainer/WindowsContainer/ColorPickerPanel
@onready var COLOR_PICKER: ColorPicker = $CenterContainer/AllContainer/WindowsContainer/ColorPickerPanel/ColorPicker
@onready var UNACTIVE_PANEL: Panel = $CenterContainer/AllContainer/WindowsContainer/ColorPickerPanel/UnactivePanel
# ^^^ Надеюсь так легально делать?

@onready var CREATE_COLORWAY_BUTTON: Button = $CenterContainer/AllContainer/WindowsContainer/ContentPanel/LeftWindowContainer/MainLeftWindowContainer/SmoothScrollContainer/ListContainer/CreateButton
@onready var COLORWAY_PANELS_CONTAINER: VBoxContainer = $CenterContainer/AllContainer/WindowsContainer/ContentPanel/LeftWindowContainer/MainLeftWindowContainer/SmoothScrollContainer/ListContainer
var COLOR_PANEL: Resource

var COLORWAY_PANELS: Array = []
var LOAD_COLORWAYS: Array = []
@export var CURRENT_COLORWAY: Array = []
var FOCUSED_COLORWAY_PANEL: ColorZonePanel

@export var CHART_SIZE: int
var FOCUSED_NOTE: NoteSkin

# Подключает все кнопки из списка к функции note_button_pressed
func connect_note_buttons() -> void:
	for button_index in range(len(NOTE_COLOR_BUTTONS)):
		var button: Button = ColorZoneEditor.get_note_button(NOTE_COLOR_BUTTONS[button_index])
		button.pressed.connect(note_button_pressed.bind(button))

# По нажатию на иконку ноты показывает ColorPicker и ставит в фокус нажатую иконку
func note_button_pressed(button: Button) -> void:
	var note: Control2D = button.get_parent()
	var noteskin: NoteSkin = ColorZoneEditor.get_note_skin(note)
	if noteskin == FOCUSED_NOTE:
		UNACTIVE_PANEL.visible = true
		ColorZoneEditor.get_note_selected_indicator(note).visible = false
		FOCUSED_NOTE = null
		return
	if FOCUSED_NOTE != null:
		ColorZoneEditor.get_note_selected_indicator(FOCUSED_NOTE.get_parent()).visible = false
	FOCUSED_NOTE = noteskin
	COLOR_PICKER.color = FOCUSED_NOTE.BASE.modulate
	ColorZoneEditor.get_note_selected_indicator(note).visible = true
	UNACTIVE_PANEL.visible = false

# Либо выбирает, либо сохраняет пресет
func panel_edit_button_pressed(panel: ColorZonePanel) -> void:
	if FOCUSED_COLORWAY_PANEL == panel:
		panel.COLORWAY = CURRENT_COLORWAY
		panel.setup_panel(CHART_SIZE, CURRENT_COLORWAY)
		return
	if FOCUSED_COLORWAY_PANEL != null:
		FOCUSED_COLORWAY_PANEL.selected_modulate(false)
	FOCUSED_COLORWAY_PANEL = panel
	FOCUSED_COLORWAY_PANEL.selected_modulate(true)
	CURRENT_COLORWAY = FOCUSED_COLORWAY_PANEL.COLORWAY.duplicate()
	setup_colors()

# Удаляет пресет
func panel_delete_button_pressed(panel: ColorZonePanel) -> void:
	if FOCUSED_COLORWAY_PANEL == panel:
		FOCUSED_COLORWAY_PANEL = null
	COLORWAY_PANELS.erase(panel)
	panel.queue_free()

func exit_button_pressed() -> void:
	var construct_colorways_array: Array = []
	for panel in COLORWAY_PANELS:
		var colorway_array: Array = panel.COLORWAY.duplicate()
		construct_colorways_array.push_back([panel.NAME, colorway_array])
	emit_signal("editing_finished", construct_colorways_array)
	get_parent().queue_free()

# Прячет ненужные иконки в зависимости от CHART_SIZE
func hide_unused_buttons() -> void:
	for button_index in range(CHART_SIZE, len(NOTE_COLOR_BUTTONS)):
		NOTE_COLOR_BUTTONS[button_index].visible = false

# Меняет цвет скина ноты когда выбирается цвет
func color_changed(color: Color) -> void:
	FOCUSED_NOTE.set_color(color)
	CURRENT_COLORWAY[FOCUSED_NOTE.get_parent().get_index()] = color

# Создаёт новую панель с пресетом цветов
func create_new_colorway() -> void:
	var color_panel_init: ColorZonePanel = COLOR_PANEL.instantiate()
	color_panel_init.CHART_SIZE = CHART_SIZE
	color_panel_init.COLORWAY = CURRENT_COLORWAY.duplicate()
	color_panel_init.PANEL_TYPE = ColorZonePanel.TYPE.EDITOR
	COLORWAY_PANELS_CONTAINER.add_child(color_panel_init)
	COLORWAY_PANELS.push_back(color_panel_init)
	color_panel_init.EDIT_BUTTON.pressed.connect(panel_edit_button_pressed.bind(color_panel_init))
	color_panel_init.DELETE_BUTTON.pressed.connect(panel_delete_button_pressed.bind(color_panel_init))
	panel_edit_button_pressed(color_panel_init)

# То же самое, что сверху, только загружает из списка (мне лень менять функцию сверху)
func load_colorway(colorway_array: Array) -> void:
	var color_panel_init: ColorZonePanel = COLOR_PANEL.instantiate()
	color_panel_init.CHART_SIZE = CHART_SIZE
	color_panel_init.NAME = colorway_array[0]
	color_panel_init.COLORWAY = colorway_array[1].duplicate()
	color_panel_init.PANEL_TYPE = ColorZonePanel.TYPE.EDITOR
	COLORWAY_PANELS_CONTAINER.add_child(color_panel_init)
	COLORWAY_PANELS.push_back(color_panel_init)
	color_panel_init.EDIT_BUTTON.pressed.connect(panel_edit_button_pressed.bind(color_panel_init))
	color_panel_init.DELETE_BUTTON.pressed.connect(panel_delete_button_pressed.bind(color_panel_init))

# Настраивает цвет скинов нот
func setup_colors() -> void:
	for color_index in len(CURRENT_COLORWAY):
		ColorZoneEditor.get_note_skin(NOTE_COLOR_BUTTONS[color_index]).set_color(CURRENT_COLORWAY[color_index])

#region Обращение к child
static func get_note_skin(control_node: Control) -> NoteSkin:
	return control_node.get_child(0)

static func get_note_button(control_node: Control) -> Button:
	return control_node.get_child(1)

static func get_note_selected_indicator(control_node: Control) -> Panel:
	return control_node.get_child(2)
#endregion

# Заполняет CURRENT_COLORWAY чёрным цветом
func fill_current_colorway() -> void:
	CURRENT_COLORWAY.clear()
	for i in range(CHART_SIZE):
		CURRENT_COLORWAY.push_back(Color(0, 0, 0))

func load_colorways() -> void:
	if len(LOAD_COLORWAYS) != 0:
		for colorway in LOAD_COLORWAYS:
			load_colorway(colorway)

func _ready() -> void:
	fill_current_colorway()
	connect_note_buttons()
	hide_unused_buttons()
	load_colorways()
	setup_colors()
