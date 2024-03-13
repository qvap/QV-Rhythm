extends Note
class_name HoldNote

# Нота, которую нужно удерживать. Как обычная нота, только отрисовывает дорожку

var LINE := preload("res://Scenes/Notes/HoldNoteLine.tscn")
@export var NOTE_LENGTH := 0 # в четвертях
var LINE_INITIALIZED := false
var HOLDING := false
var LINE_NODE : Line2D
var HOLD_TO_CONTROL: HoldNote

func _ready() -> void:
	DISAPPEAR_TIMER = $Disappear
	SKIN = $TapNoteSkin
	initialize_note()
	if NOTE_TYPE == Global.NOTE_TYPE.HOLDNOTE:
		setup_line()
	else:
		SKIN.modulate.a = 0.0

func setup_line() -> void:
	LINE_NODE = LINE.instantiate()
	LINE_NODE.modulate = COLOR
	add_child(LINE_NODE)
	LINE_NODE.top_level = true
	LINE_NODE.points[0] = Vector2(0.0, 0.0)
	LINE_NODE.points[1] = Vector2(0.0, 0.0 - (NOTE_SPEED * (Conductor.s_per_quarter * NOTE_LENGTH)))
	LINE_INITIALIZED = true

func _process(delta: float) -> void:
	process_note(delta)
	if !LINE_INITIALIZED:
		return
	LINE_NODE.global_position = global_position
	if HOLDING:
		if !(LINE_NODE.points[0].y <= LINE_NODE.points[1].y):
			LINE_NODE.points[0] = Vector2(0.0, ROAD_POSITION.y - global_position.y)
		else:
			LINE_NODE.points[0] = Vector2(0.0, LINE_NODE.points[1].y)

func miss_note() -> void:
	match NOTE_TYPE:
		Global.NOTE_TYPE.HOLDNOTE:
			if !Settings.BOT_PLAY:
				LINE_NODE.modulate.a = 0.5
				modulate.a = 0.5
				DISAPPEAR_TIMER.start()
		Global.CONTROL_TYPE.HOLDCONTROL:
			HOLD_TO_CONTROL.miss_note()
			queue_free()
		Global.CONTROL_TYPE.HOLDCONTROLTICK:
			queue_free()
		Global.CONTROL_TYPE.HOLDCONTROLEND:
			queue_free()

func hit_note() -> void:
	HOLD_TO_CONTROL.SKIN.visible = false
