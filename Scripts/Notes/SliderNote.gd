extends Note
class_name SliderNote

# Слайдер. Как холд, только покруче

@onready var HIT_GRADIENT: HitGradient = $HitGradient

var LINE := preload("res://Scenes/Notes/SliderLine.tscn")
var SKIN_LEFT := preload("res://Assets/Game/Notes/SliderNote/SliderNoteTopLeft.png")
var SKIN_RIGHT := preload("res://Assets/Game/Notes/SliderNote/SliderNoteTopRight.png")
var HINT_SKIN_BASE := preload("res://Assets/Game/Notes/SliderNote/SliderNoteHintBase.png")
var HINT_SKIN_MIDDLE := preload("res://Assets/Game/Notes/SliderNote/SliderNoteHintMiddle.png")
var HINT_SKIN_TOP := preload("res://Assets/Game/Notes/SliderNote/SliderNoteHintTop.png")
var SLIDER_SKIN := preload("res://Assets/Game/Notes/SliderNote/SliderNoteSkin.tscn")
var ID: int
var LINE_NODE: Line2D
var LINE_INITIALIZED := false
var NEXT_ROAD: Road
var SLIDING := false
var NEXT_NOTE_SPAWN_QUARTER: int
var HINT: NoteSkin # содержит в себе ноду подсказки
var SLIDER_TO_CONTROL: SliderNote # Чтобы подключать к контроллерам соответствующие слайдеры

func _ready() -> void:
	DISAPPEAR_TIMER = $Disappear
	SKIN = $SliderNoteSkin
	if NOTE_TYPE in Global.CONTROL_TYPE.values():
		modulate.a = 0.0
	initialize_note()
	if (NOTE_TYPE == Global.NOTE_TYPE.SLIDER) or (NOTE_TYPE == Global.NOTE_TYPE.SLIDERTICK):
		setup_line()
		if Settings.ENABLE_SLIDER_HINTS:
			place_hint()
	if NOTE_TYPE == Global.NOTE_TYPE.SLIDERTICK:
		if NEXT_ROAD.road_index > ROAD.road_index:
			SKIN.TOP.texture = SKIN_RIGHT
		else:
			SKIN.TOP.texture = SKIN_LEFT

func setup_line() -> void:
	LINE_NODE = LINE.instantiate()
	LINE_NODE.modulate = COLOR
	add_child(LINE_NODE)
	LINE_NODE.top_level = true
	LINE_NODE.points[0] = Vector2(0.0, 0.0)
	LINE_INITIALIZED = true

# Расставляет точки линии
func draw_slider_line_end() -> void:
	await get_tree().process_frame
	var _y_compensate : float = NEXT_ROAD.position.y - ROAD_POSITION.y
	LINE_NODE.points[1] = Vector2(NEXT_ROAD.global_position.x - global_position.x, _y_compensate - (NOTE_SPEED * Conductor.s_per_quarter *\
	(NEXT_NOTE_SPAWN_QUARTER - SPAWN_QUARTERS)))

# Ставит подсказку, куда удерживать слайдер (экспериментально)
func place_hint() -> void:
	var skin_init: NoteSkin = SLIDER_SKIN.instantiate()
	HINT = skin_init
	add_child(skin_init)
	skin_init.scale = Vector2(0.06, 0.06)
	skin_init.TOP.texture = HINT_SKIN_TOP
	skin_init.MIDDLE.texture = HINT_SKIN_MIDDLE
	skin_init.BASE.texture = HINT_SKIN_BASE
	skin_init.modulate.a = 0.5
	skin_init.global_position.x = NEXT_ROAD.position.x
	skin_init.TOP.modulate = COLOR
	skin_init.set_color(COLOR)

func _process(delta: float) -> void:
	process_note(delta)
	if !LINE_INITIALIZED:
		return
	LINE_NODE.global_position = global_position
	var _y_compensate : float = NEXT_ROAD.position.y - ROAD_POSITION.y # если дороги отличаются по высоте
	# (но изменять их расположение по y не советуется)
	draw_slider_line_end()
	if SLIDING:
		# Здесь происходит жесть (математика)
		var k : float = maxf((Conductor.song_position - SPAWN_TIME) * NOTE_SPEED, 0.0)
		var m : float = _y_compensate - (NOTE_SPEED * (Conductor.s_per_quarter * (NEXT_NOTE_SPAWN_QUARTER - SPAWN_QUARTERS)))
		var n : float = NEXT_ROAD.global_position.x - global_position.x
		var b : float = -((n * k) / m)
		if !(LINE_NODE.points[0].y <= LINE_NODE.points[1].y):
			LINE_NODE.points[0].x = b
			LINE_NODE.points[0].y = minf(0.0 - global_position.y, 0.0)
		else:
			LINE_NODE.points[0] = LINE_NODE.points[1]
		HIT_GRADIENT.position = LINE_NODE.points[0]
		HIT_GRADIENT.play_holding_anim(COLOR)

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

func hit_note() -> void:
	SLIDER_TO_CONTROL.SKIN.visible = false
	if SLIDER_TO_CONTROL.HINT:
		SLIDER_TO_CONTROL.HINT.visible = false
