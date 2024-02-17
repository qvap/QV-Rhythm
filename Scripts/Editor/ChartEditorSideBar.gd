extends Control
class_name ChartEditorSideBar

# Панель с выбором индикатора ноты

@onready var SIDE_BAR: VBoxContainer = $SideBar
@onready var UP_CORNER: HBoxContainer = $SideBar/UpCorner
@onready var PANEL_CONTAINER: PanelContainer = $SideBar/PanelContainer
@onready var BUTTON_CONTAINER: VBoxContainer = $SideBar/PanelContainer/ButtonContainer
@onready var TAP_NOTE_BUTTON: Button = $SideBar/PanelContainer/ButtonContainer/TapNoteButton
@onready var HOLD_NOTE_BUTTON: Button = $SideBar/PanelContainer/ButtonContainer/HoldNoteButton
@onready var SLIDER_NOTE_CONTAINER: VBoxContainer = $SideBar/PanelContainer/ButtonContainer/SliderNoteContainer
@onready var SLIDER_NOTE_BUTTON: Button = $SideBar/PanelContainer/ButtonContainer/SliderNoteContainer/SliderNoteButton
@onready var SLIDER_NOTE_ID_CONTAINER: HBoxContainer = $SideBar/PanelContainer/ButtonContainer/SliderNoteContainer/SliderNoteIdContainer
@onready var SLIDER_NOTE_ID_LEFT_BUTTON: Button = $SideBar/PanelContainer/ButtonContainer/SliderNoteContainer/SliderNoteIdContainer/SliderNoteIdLeftButton
@onready var SLIDER_NOTE_ID_LABEL: Label = $SideBar/PanelContainer/ButtonContainer/SliderNoteContainer/SliderNoteIdContainer/SliderNoteIdLabel
@onready var SLIDER_NOTE_ID_RIGHT_BUTTON: Button = $SideBar/PanelContainer/ButtonContainer/SliderNoteContainer/SliderNoteIdContainer/SliderNoteIdRightButton
@onready var DOWN_CORNER: HBoxContainer = $SideBar/DownCorner
@onready var CURRENT_PANEL: Panel = $CurrentPanel


@onready var CHART_EDITOR: ChartEditor
enum BUTTON_INDEX {TAP, HOLD, SLIDE, ID_LEFT, ID_RIGHT}
var CURRENT_SLIDER_ID: int = 0
@onready var CURRENT_BUTTON: Button = TAP_NOTE_BUTTON

@export var PANEL_COLOR: Color = Color(0.15, 0.15, 0.15)

func _ready() -> void:
	CHART_EDITOR = get_parent().get_parent()
	
	# Настраивает цвет задней панели
	UP_CORNER.modulate = PANEL_COLOR
	DOWN_CORNER.modulate = PANEL_COLOR
	PANEL_CONTAINER.self_modulate = PANEL_COLOR

func button_pressed(button: int) -> void:
	SLIDER_NOTE_ID_CONTAINER.visible = false
	match button:
		BUTTON_INDEX.TAP:
			CHART_EDITOR.CURRENT_INDICATOR_TYPE = CHART_EDITOR.INDICATOR_TYPE.TAP
			CURRENT_BUTTON = TAP_NOTE_BUTTON
		BUTTON_INDEX.HOLD:
			CHART_EDITOR.CURRENT_INDICATOR_TYPE = CHART_EDITOR.INDICATOR_TYPE.HOLD
			CURRENT_BUTTON = HOLD_NOTE_BUTTON
		BUTTON_INDEX.SLIDE:
			SLIDER_NOTE_ID_CONTAINER.visible = true
			CHART_EDITOR.CURRENT_INDICATOR_TYPE = CHART_EDITOR.INDICATOR_TYPE.SLIDE
			CURRENT_BUTTON = SLIDER_NOTE_BUTTON
		BUTTON_INDEX.ID_LEFT:
			SLIDER_NOTE_ID_CONTAINER.visible = true
			CURRENT_SLIDER_ID -= 1
			CURRENT_SLIDER_ID = clamp(CURRENT_SLIDER_ID, 0, 1_000_000)
			SLIDER_NOTE_ID_LABEL.text = str(CURRENT_SLIDER_ID)
		BUTTON_INDEX.ID_RIGHT:
			SLIDER_NOTE_ID_CONTAINER.visible = true
			CURRENT_SLIDER_ID += 1
			CURRENT_SLIDER_ID = clamp(CURRENT_SLIDER_ID, 0, 1_000_000)
			SLIDER_NOTE_ID_LABEL.text = str(CURRENT_SLIDER_ID)

func _process(_delta: float) -> void:
	# Учитывает угловые вставки и меняет размер
	PANEL_CONTAINER.custom_minimum_size.x = SIDE_BAR.custom_minimum_size.x - 50.0
	CURRENT_PANEL.global_position = CURRENT_BUTTON.global_position
