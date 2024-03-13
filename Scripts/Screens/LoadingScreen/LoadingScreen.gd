extends Control
class_name LoadingScreen

@onready var LOADING_ANIMATION: AnimationPlayer = $LoadingAnimation

signal animation_finished()

func anim_finished(anim_name: String) -> void:
	if anim_name == "default":
		emit_signal("animation_finished")

func exit() -> void:
	LOADING_ANIMATION.play("exit")
	await LOADING_ANIMATION.animation_finished
	queue_free()
