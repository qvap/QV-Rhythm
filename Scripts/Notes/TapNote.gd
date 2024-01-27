extends Node2D
class_name Note

@onready var SKIN := $Skin
var SPAWN_POSITION : Vector2
var ROAD : Node2D

func _ready() -> void:
	ROAD = get_parent()
	SPAWN_POSITION = ROAD.NOTESPAWN_POSITION

func spawn_note() -> void:
	pass
