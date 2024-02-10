extends Label
class_name JudgeText

@onready var FLASH: TextureRect = $Flash
@onready var DISAPPEAR_TIMER: Timer = $DisappearTimer

var index: int
const COLORS := [
	Color(0.56, 1, 1),
	Color(1, 0.824, 0.827, 1),
	Color(1, 1, 0.572, 1),
	Color(1, 0.372, 0, 1),
	Color(0.41, 0.021, 0, 1)
]

func _ready() -> void:
	DISAPPEAR_TIMER.connect("timeout", disappear)
	FLASH.modulate = COLORS[index]
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale:y", 1.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	flash()

func slide() -> void:
	DISAPPEAR_TIMER.stop()
	DISAPPEAR_TIMER.start()
	modulate.a = 0.5
	FLASH.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.618, 0.618), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

func flash() -> void:
	DISAPPEAR_TIMER.start()
	var tween = create_tween()
	tween.tween_property(FLASH, "scale:x", 1.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(FLASH, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

func disappear() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
