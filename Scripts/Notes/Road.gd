extends Node2D
class_name Road

# Скрипт дороги, отвечающий за засчитывание ударов по нотам

@export_group("Road")
@export_enum("First", "Second", "Third", "Fourth", "Fifth", "Sixth") var road_index: int

var TAPNOTE := preload("res://Scenes/Notes/TapNote.tscn")
@onready var NOTESPAWN := $NoteSpawn
@onready var NOTEHOLDER := $NoteHolder
var NOTESPAWN_POSITION : Vector2
var ROAD_POSITION_MARKER : Marker2D
var NOTES_TO_HIT : Array # Список нот, которые находятся в зоне удара
var ALL_NOTES: Array # Список всех появляющихся нот

func _ready() -> void:
	NOTESPAWN_POSITION = NOTESPAWN.position

func _process(_delta) -> void:
	if Input.is_action_pressed(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		$Sprite2D.modulate.a = 0.5
	else: $Sprite2D.modulate.a = 1.0
	position = ROAD_POSITION_MARKER.position

func _physics_process(_delta) -> void:
	if len(ALL_NOTES) != 0:
		if Scoring.check_note_zone(ALL_NOTES[0].SPAWN_TIME + Conductor.note_speed):
			NOTES_TO_HIT.push_back(ALL_NOTES[0])
			ALL_NOTES.remove_at(0)
	if len(NOTES_TO_HIT) != 0:
		if !Scoring.check_note_zone(NOTES_TO_HIT[0].SPAWN_TIME + Conductor.note_speed):
			var note = NOTES_TO_HIT[0]
			NOTES_TO_HIT.remove_at(0)
			note.queue_free()
			print('miss')

func check_note_hit() -> void:
	print('hit')
	var note = NOTES_TO_HIT[0]
	NOTES_TO_HIT.remove_at(0)
	note.queue_free()

func spawn_note() -> void:
	var note_instantiate = TAPNOTE.instantiate()
	ALL_NOTES.push_back(note_instantiate)
	NOTEHOLDER.add_child(note_instantiate)

func _unhandled_input(event) -> void:
	if event.is_action_pressed(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		road_input(true)

func road_input(is_pressed: bool) -> void:
	if is_pressed:
		if len(NOTES_TO_HIT) == 0:
			return
		check_note_hit()
