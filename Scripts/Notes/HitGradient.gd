extends Sprite2D
class_name HitGradient

@onready var HIT_ANIMATION: AnimationPlayer = $HitAnimation

func play_anim(color: Color) -> void:
	HIT_ANIMATION.stop()
	modulate = color
	HIT_ANIMATION.play("hit")

func play_holding_anim(color: Color) -> void:
	modulate = color
	HIT_ANIMATION.play("hit")
