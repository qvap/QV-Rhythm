extends Camera2D
class_name MainCamera

# Главная камера. Используется на игровом поле

@onready var VIDEO_PLAYER: VideoPlayer = $"../VideoLayer/VideoPlayer"
@export var bump_multiplier : float = 1.05

func _ready() -> void:
	Conductor.beat_hit.connect(bump_camera)

func bump_camera(_current_beat: int) -> void:
	var current_zoom : Vector2 = zoom
	var current_video_zoom : Vector2 = VIDEO_PLAYER.ZOOM
	var video_multiplier: float = bump_multiplier * 0.95
	zoom *= bump_multiplier
	VIDEO_PLAYER.ZOOM *= video_multiplier
	var tween = create_tween()
	tween.tween_property(self, "zoom", current_zoom, Conductor.s_per_beat - 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(VIDEO_PLAYER, "ZOOM", current_video_zoom, Conductor.s_per_beat - 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
