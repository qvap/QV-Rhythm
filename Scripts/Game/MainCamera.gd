extends Camera2D
class_name MainCamera

# Главная камера. Используется на игровом поле

@onready var VIDEO_PLAYER: VideoPlayer = $"../VideoLayer/VideoPlayer"
@export var initial_bump_multiplier : float = 1.05
@export var fixed_zoom: Vector2 = Vector2(3.0, 3.0)
var bump_multiplier : float = 1.0
var video_multiplier: float = 1.0

func _ready() -> void:
	Conductor.beat_hit.connect(bump_camera)

func _process(_delta: float) -> void:
	zoom = fixed_zoom * bump_multiplier
	VIDEO_PLAYER.ZOOM = Vector2(video_multiplier, video_multiplier)

func bump_camera(_current_beat: int) -> void: # меняет коэффиценты зума под бит
	bump_multiplier = initial_bump_multiplier
	video_multiplier = initial_bump_multiplier * 0.95
	var tween = create_tween()
	tween.tween_property(self, "bump_multiplier", 1.0, Conductor.s_per_beat - 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(self, "video_multiplier", 1.0, Conductor.s_per_beat - 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
