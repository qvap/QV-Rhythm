extends Node
class_name SceneLoader

# Отвечает за переключение экранов и загрузку

@onready var LOADING_SCREEN_LAYER: CanvasLayer = $LoadingScreenLayer
@onready var LOADING_SCREEN: Resource = preload("res://Scenes/Screens/Loading/LoadingScreen.tscn")
var SCENE_PATH: String
var LOADING: bool = false
var LOADING_SCREEN_NODE: LoadingScreen


func transition(next_scene_path: String) -> void:
	SCENE_PATH = next_scene_path
	var loading_screen_init: LoadingScreen = LOADING_SCREEN.instantiate()
	LOADING_SCREEN_LAYER.add_child(loading_screen_init)
	LOADING_SCREEN_NODE = loading_screen_init
	await LOADING_SCREEN_NODE.animation_finished
	ResourceLoader.load_threaded_request(SCENE_PATH)
	LOADING = true

func _process(_delta: float) -> void:
	if LOADING:
		var load_status: int = ResourceLoader.load_threaded_get_status(SCENE_PATH)
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			var scene: Resource = ResourceLoader.load_threaded_get(SCENE_PATH)
			get_tree().change_scene_to_packed(scene)
			LOADING = false
			SCENE_PATH = ""
			LOADING_SCREEN_NODE.exit()
			LOADING_SCREEN_NODE = null
