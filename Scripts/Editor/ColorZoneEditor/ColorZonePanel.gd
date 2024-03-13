extends PanelContainer
class_name ColorZonePanel

@onready var NOTE_SKINS: Array = [
	$HBoxContainer/Notes/Note1,
	$HBoxContainer/Notes/Note2,
	$HBoxContainer/Notes/Note3,
	$HBoxContainer/Notes/Note4,
	$HBoxContainer/Notes/Note5,
	$HBoxContainer/Notes/Note6
]
@onready var NAMING_LINE: LineEdit = $HBoxContainer/LineEdit
@onready var NAMING_LABEL: Label = $HBoxContainer/Label
@onready var EDIT_BUTTON: Button = $HBoxContainer/EditButtons/Edit
@onready var DELETE_BUTTON: Button = $HBoxContainer/EditButtons/Delete
@onready var SELECT_BUTTON: Button = $HBoxContainer/EditButtons/Select


enum TYPE {EDITOR, LIST}
@export var PANEL_TYPE: TYPE = TYPE.EDITOR

@export var COLORWAY: Array = []
@export var NAME: String = ""
@export var CHART_SIZE: int

# Настраивает панель при создании
func setup_panel(chart_size: int, colorway: Array) -> void:
	# Прячет ненужные ноты
	for note_index in range(chart_size, len(NOTE_SKINS)):
		NOTE_SKINS[note_index].visible = false
	# Сохраняет colorway в COLORWAY
	COLORWAY = colorway
	set_colors()

# Сохраняет в переменную значение из LineEdit
func rename(text: String) -> void:
	NAME = text

# Настраивает цвета скинов нот
func set_colors() -> void:
	for color_index in len(COLORWAY):
		if NOTE_SKINS[color_index]:
			ColorZoneEditor.get_note_skin(NOTE_SKINS[color_index]).set_color(COLORWAY[color_index])

# Убирает фокус с наименования если нажат Enter / нажата мышь вне поля
func _input(event: InputEvent) -> void:
	if NAMING_LINE.has_focus() and ((event is InputEventMouseButton and\
	!NAMING_LINE.get_global_rect().has_point(event.position)) or event.is_action_pressed("Enter")):
		NAMING_LINE.release_focus()

# Меняет цвет панели
func selected_modulate(value: bool) -> void:
	self_modulate = Color(0.5, 0.5, 0.5) if value else Color(1, 1, 1)
	match PANEL_TYPE:
		TYPE.EDITOR:
			EDIT_BUTTON.text = "Save" if value else "Edit"
		TYPE.LIST:
			SELECT_BUTTON.text = "Selected!" if value else "Select"

func setup_type() -> void:
	match PANEL_TYPE:
		TYPE.EDITOR:
			if NAME != "":
				NAMING_LINE.text = NAME
			else:
				NAMING_LINE.grab_focus()
			NAMING_LABEL.visible = false
			SELECT_BUTTON.visible = false
		TYPE.LIST:
			if NAME != "":
				NAMING_LABEL.text = NAME
			NAMING_LINE.visible = false
			DELETE_BUTTON.visible = false
			EDIT_BUTTON.visible = false
			NAMING_LABEL.visible = true
			SELECT_BUTTON.visible = true

func _ready() -> void:
	setup_panel(CHART_SIZE, COLORWAY)
	setup_type()
