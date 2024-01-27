extends Node2D
class_name Road

@export_group("Road")
@export_enum("First", "Second", "Third", "Fourth", "Fifth", "Sixth") var road_index: int

@onready var NOTESPAWN := $NoteSpawn
var NOTESPAWN_POSITION : Vector2
var ROAD_POSITION_MARKER : Marker2D

func _ready() -> void:
	NOTESPAWN_POSITION = NOTESPAWN.position

func _process(_delta) -> void:
	position = ROAD_POSITION_MARKER.position
