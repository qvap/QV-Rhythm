extends Node2D
class_name MapScene

# Все ноды, которыми нужно управлять в gamespace
@onready var CAMERA: Camera2D = $Camera2D
@onready var ROAD_MARKERS: Node2D = $RoadMarkers
@onready var ANIMATION_PLAYER: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	init_scene_functions()

func play_animation() -> void:
	if ANIMATION_PLAYER != null:
		ANIMATION_PLAYER.play("default")
	else:
		print("Нет анимации в сцене!")

func init_scene_functions() -> void:
	Conductor.music_started.connect(play_animation)
