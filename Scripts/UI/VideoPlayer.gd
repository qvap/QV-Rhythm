extends Container
class_name VideoPlayer

# Видео-плеер. Если у карты есть видео, то отображает его
# Отображается через кастомный контейнер

@onready var VIDEO_STREAM_PLAYER: VideoStreamPlayer = $VideoStreamPlayer
@onready var BLUR: ColorRect = $VideoStreamPlayer/Blur
@export var ZOOM: Vector2 = Vector2(1.0, 1.0)

var start_video := false
@export var opacity := 0.5
@export var blur := 0.0

func _ready() -> void:
	modulate.a = 0.0

func load_video(video_path: String) -> void:
	BLUR.material.set_shader_parameter("blur", blur)
	if FileAccess.file_exists(video_path):
		var video_file: FFmpegVideoStream = FFmpegVideoStream.new()
		video_file.file = video_path
		VIDEO_STREAM_PLAYER.stream = video_file
	else:
		push_error("Не найдено видео! Путь: "+video_path)

func play_video() -> void:
	if VIDEO_STREAM_PLAYER.stream != null:
		start_video = true

func play_video_with_offset(offset: float) -> void:
	if VIDEO_STREAM_PLAYER.stream != null:
		await get_tree().create_timer(offset).timeout
		start_video = true

func _process(_delta: float) -> void:
	if start_video and Conductor.song_occured:
		VIDEO_STREAM_PLAYER.play()
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", opacity, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		start_video = false
	
	# Центрирование и увеличение видео при изменении размеров viewport
	VIDEO_STREAM_PLAYER.scale = Vector2(size.x / VIDEO_STREAM_PLAYER.size.x, size.x / VIDEO_STREAM_PLAYER.size.x) * ZOOM
	VIDEO_STREAM_PLAYER.position.x = size.x/2.0 - (VIDEO_STREAM_PLAYER.size.x/2.0) * VIDEO_STREAM_PLAYER.scale.x
	VIDEO_STREAM_PLAYER.position.y = size.y/2.0 - (VIDEO_STREAM_PLAYER.size.y/2.0) * VIDEO_STREAM_PLAYER.scale.y
