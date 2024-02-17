extends Node2D
class_name EditorNoteIndicator

@onready var SPRITE: Sprite2D = $Sprite2D
@onready var LABEL: Label = $Label
@onready var CHART_EDITOR: ChartEditor

@export var TYPE: int
@export var SLIDER_ID: int
@export var HOLD_CONNECTED: bool = false

func _ready() -> void:
	CHART_EDITOR = get_parent().get_parent().get_parent()
	match TYPE:
		CHART_EDITOR.INDICATOR_TYPE.TAP:
			LABEL.text = ""
		CHART_EDITOR.INDICATOR_TYPE.HOLD:
			LABEL.text = "H"
		CHART_EDITOR.INDICATOR_TYPE.SLIDE:
			LABEL.text = str(SLIDER_ID)
			SPRITE.rotation_degrees = 45.0
