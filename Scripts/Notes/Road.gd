extends Node2D
class_name Road

@export_group("Road")
@export_enum("First", "Second", "Third", "Fourth", "Fifth", "Sixth") var road_index: int

var TAPNOTE := preload("res://Scenes/Notes/TapNote.tscn")
@onready var NOTESPAWN := $NoteSpawn
@onready var NOTEHOLDER := $NoteHolder
var NOTESPAWN_POSITION : Vector2
var ROAD_POSITION_MARKER : Marker2D

func _ready() -> void:
	NOTESPAWN_POSITION = NOTESPAWN.position

func _process(_delta) -> void:
	position = ROAD_POSITION_MARKER.position

func spawn_note() -> void:
	var note_instantiate = TAPNOTE.instantiate()
	NOTEHOLDER.add_child(note_instantiate)
