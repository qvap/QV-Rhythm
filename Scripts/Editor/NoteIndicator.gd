extends Node2D
class_name EditorIndicator

@onready var SPRITE: Sprite2D = $Sprite2D
@onready var LABEL: Label = $Label
@onready var CHART_EDITOR: ChartEditor

@export var TYPE: int
@export var SLIDER_ID: int
@export var HOLD_CONNECTED: bool = false
@export var COLOR: Color = Color(1, 1, 1)
@export var COLOR_ZONE_NAME: String = "Color"

func _ready() -> void:
	CHART_EDITOR = get_parent().get_parent().get_parent().get_parent()
	if !Settings.EDITOR_DOWNSCROLL:
		scale = Vector2(1.0, -1.0)
	match TYPE:
		CHART_EDITOR.INDICATOR_TYPE.TAP:
			LABEL.text = ""
		CHART_EDITOR.INDICATOR_TYPE.HOLD:
			LABEL.text = "H"
		CHART_EDITOR.INDICATOR_TYPE.SLIDE:
			LABEL.text = str(SLIDER_ID)
			SPRITE.rotation_degrees = 45.0
		CHART_EDITOR.INDICATOR_TYPE.ZONE_COLOR:
			LABEL.text = COLOR_ZONE_NAME
		CHART_EDITOR.INDICATOR_TYPE.ZONE_BPM:
			LABEL.text = "BPM"
	SPRITE.texture.gradient.colors[1] = COLOR
