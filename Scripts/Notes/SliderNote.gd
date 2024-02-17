extends Note
class_name SliderNote

# Слайдер. Как холд, только покруче

var LINE := preload("res://Scenes/Notes/SliderLine.tscn")
var ID: int
var LINE_NODE: Line2D
var LINE_INITIALIZED := false
var NEXT_ROAD: Road
var SLIDING := false
var NEXT_NOTE_SPAWN_QUARTER: int
var SLIDER_TO_CONTROL: SliderNote # Чтобы подключать к контроллерам соответствующие слайдеры

func _ready() -> void:
	DISAPPEAR_TIMER = $Disappear
	SKIN = $Skin
	Conductor.beat_hit.connect(bump_skin_on_beat)
	if NOTE_TYPE in Global.CONTROL_TYPE.values():
		modulate.a = 0.0
	initialize_note()
	if (NOTE_TYPE == Global.NOTE_TYPE.SLIDER) or (NOTE_TYPE == Global.NOTE_TYPE.SLIDERTICK):
		setup_line()
	if NOTE_TYPE == Global.NOTE_TYPE.SLIDERTICK:
		SKIN.scale = Vector2(0.25, 0.25)

func setup_line() -> void:
	LINE_NODE = LINE.instantiate()
	add_child(LINE_NODE)
	LINE_NODE.top_level = true
	LINE_NODE.points[0] = Vector2(0.0, 0.0)
	LINE_INITIALIZED = true

func _process(delta: float) -> void:
	process_note(delta)
	if !LINE_INITIALIZED:
		return
	LINE_NODE.global_position = global_position
	var y_compensate : float = NEXT_ROAD.position.y - ROAD_POSITION.y # если дороги отличаются по высоте
	# (но изменять их расположение по y не советуется)
	LINE_NODE.points[1] = Vector2(NEXT_ROAD.global_position.x - global_position.x, y_compensate - (NOTE_SPEED * (Conductor.s_per_quarter *\
	(NEXT_NOTE_SPAWN_QUARTER - SPAWN_QUARTERS))))
	if SLIDING:
		# Здесь происходит жесть (математика)
		var k : float = clamp((Conductor.song_position - SPAWN_TIME) * NOTE_SPEED, 0.0, 100_000.0)
		var m : float = y_compensate - (NOTE_SPEED * (Conductor.s_per_quarter * (NEXT_NOTE_SPAWN_QUARTER - SPAWN_QUARTERS)))
		var n : float = NEXT_ROAD.global_position.x - global_position.x
		var b : float = -((n * k) / m)
		if !(LINE_NODE.points[0].y <= LINE_NODE.points[1].y):
			LINE_NODE.points[0].x = b
			LINE_NODE.points[0].y = clamp(0.0 - global_position.y, -1_000_000.0, 0.0)
		else:
			LINE_NODE.points[0] = LINE_NODE.points[1]

func bump_skin_on_beat(_current_beat: int) -> void:
	var current_scale = SKIN.scale
	var current_alpha = SKIN.modulate.a
	SKIN.scale *= 1.1
	SKIN.modulate.a = 0.5
	var tween = create_tween()
	tween.tween_property(SKIN, "scale", current_scale, Conductor.s_per_beat - 0.05)
	tween.parallel().tween_property(SKIN, "modulate:a", current_alpha, Conductor.s_per_beat - 0.05)

func miss_note() -> void:
	match NOTE_TYPE:
		Global.NOTE_TYPE.SLIDER:
			LINE_NODE.modulate.a = 0.5
			modulate.a = 0.5
			DISAPPEAR_TIMER.start()
		Global.NOTE_TYPE.SLIDERTICK:
			LINE_NODE.modulate.a = 0.5
			modulate.a = 0.5
			DISAPPEAR_TIMER.start()
		Global.CONTROL_TYPE.SLIDERCONTROL:
			SLIDER_TO_CONTROL.miss_note()
			queue_free()
		Global.CONTROL_TYPE.SLIDERCONTROLTICK:
			queue_free()
		Global.CONTROL_TYPE.SLIDERCONTROLEND:
			queue_free()
		Global.NOTE_TYPE.SLIDEREND:
			queue_free()
