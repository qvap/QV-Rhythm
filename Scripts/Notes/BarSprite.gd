extends Sprite2D
class_name BarSprite

# Анимации падающих полосок и их удаление после достижения конечной точки

@export var opacity: float = 0.25

const bar_size := {
	1: 1.5,
	2: 1.5,
	3: 2.35,
	4: 3.2,
	5: 4.05,
	6: 4.95
}

func disappear() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale:x", scale.x * 2, Conductor.s_per_beat).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(self, "modulate:a", 0.0, Conductor.s_per_beat).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	queue_free()

func _ready() -> void:
	scale.x = bar_size[Global.CURRENT_CHART_SIZE]
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "position:y", 0.0, Conductor.note_speed).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "modulate:a", opacity, Conductor.note_speed)
	await tween.finished
	disappear()
