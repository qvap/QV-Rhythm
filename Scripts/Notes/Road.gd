extends Node2D
class_name Road

# Скрипт дороги, отвечающий за засчитывание ударов по нотам

@export_group("Road")
@export_enum("First", "Second", "Third", "Fourth", "Fifth", "Sixth") var road_index: int

var TAPNOTE := preload("res://Scenes/Notes/TapNote.tscn")
var HOLDNOTE := preload("res://Scenes/Notes/HoldNote.tscn")
@onready var NOTESPAWN := $NoteSpawn
@onready var NOTEHOLDER := $NoteHolder
var NOTESPAWN_POSITION : Vector2
var ROAD_POSITION_MARKER : Marker2D
var ALL_NOTES : Array # Список всех нот
var PENDING_NOTE_INDEX := 0 # Индекс ноты, которую нужно заспавнить
var ALL_SPAWNED_NOTES: Array # Список всех появляющихся нот
var NOTES_TO_HIT : Array # Список нот, которые находятся в зоне удара
var PRESSED := false # Проверяет, нажата ли клавиша

func _ready() -> void:
	NOTESPAWN_POSITION = NOTESPAWN.position

func _process(_delta) -> void:
	if Input.is_action_pressed(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		$Sprite2D.modulate.a = 0.5
	else: $Sprite2D.modulate.a = 1.0
	position = ROAD_POSITION_MARKER.position

func _physics_process(_delta) -> void:
	
	# Спавнит ноты
	if PENDING_NOTE_INDEX < len(ALL_NOTES):
		var pending_note = ALL_NOTES[PENDING_NOTE_INDEX]
		if (pending_note[Global.NOTE_CHART_STRUCTURE["quarter_to_spawn"]] *\
		Conductor.s_per_quarter) <= Conductor.chart_position:
			spawn_note(pending_note[Global.NOTE_CHART_STRUCTURE["type"]])
			PENDING_NOTE_INDEX += 1
	
	# Смотрит, какие ноты есть в зоне и какие нужно удалять
	if len(ALL_SPAWNED_NOTES) != 0:
		if Scoring.check_note_zone(ALL_SPAWNED_NOTES[0].SPAWN_TIME + Conductor.note_speed):
			NOTES_TO_HIT.push_back(ALL_SPAWNED_NOTES[0])
			ALL_SPAWNED_NOTES.remove_at(0)
	if len(NOTES_TO_HIT) != 0:
		if !Scoring.check_note_zone(NOTES_TO_HIT[0].SPAWN_TIME + Conductor.note_speed):
			var note = NOTES_TO_HIT[0]
			NOTES_TO_HIT.remove_at(0)
			note.queue_free()
			print('miss')

func check_note_hit() -> void:
	print('hit')
	var note = NOTES_TO_HIT[0]
	match note.NOTE_TYPE:
		0:
			NOTES_TO_HIT.remove_at(0)
			note.queue_free()
		1:
			pass

func spawn_note(note_type: int) -> void:
	var note_instantiate
	match note_type:
		0: note_instantiate = TAPNOTE.instantiate()
		1: note_instantiate = HOLDNOTE.instantiate()
	ALL_SPAWNED_NOTES.push_back(note_instantiate)
	NOTEHOLDER.add_child(note_instantiate)

func _unhandled_input(event) -> void:
	if event.is_action_pressed(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		PRESSED = true
		road_input()
	if event.is_action_released(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		PRESSED = false

func road_input() -> void:
	if PRESSED:
		if len(NOTES_TO_HIT) == 0:
			return
		check_note_hit()
