extends Node2D
class_name Road

# Скрипт дороги, отвечающий за засчитывание ударов по нотам
# Содержит в себе весь функционал считывания нот и передачи Scoring по попаданиям
# Силой моего ума здесь реализовано считывание обычных и холд нот
# Не могу сказать, что моя реализация холд нот хороша, может быть её рано или поздно стоит переделать
# Но пока что я не вижу проблем с ней, она считывается как надо, поэтому нет смысла делать лишнюю работу
# UPD: Поразмыслив ещё немного, я пришёл к выводу, что всё таки стоит учитывать окна на
# каждом такте холд ноты, поэтому всё таки использую фантомный спавн нот
# Благодаря этому холд ноты стали ощущаться лучше

#region Переменные на экспорт
@export_group("Road")
@export_enum("First", "Second", "Third", "Fourth", "Fifth", "Sixth") var road_index: int
#endregion

#region Внутрикодовые переменные
var TAPNOTE := preload("res://Scenes/Notes/TapNote.tscn")
var HOLDNOTE : Resource # Спасибо движку за то, что по приколу не даёт сделать preload холд ноты

@onready var NOTESPAWN := $NoteSpawn
@onready var NOTEHOLDER := $NoteHolder

var NOTESPAWN_POSITION : Vector2
var ROAD_POSITION_MARKER : Marker2D

var ALL_NOTES : Array # Список всех нот
var PENDING_NOTE_INDEX := 0 # Индекс ноты, которую нужно заспавнить
var ALL_SPAWNED_NOTES: Array # Список всех появляющихся нот
var NOTES_TO_HIT : Array # Список нот, которые находятся в зоне удара

var PRESSED := false # Проверяет, нажата ли клавиша

var CURRENT_HOLD_NOTE : HoldNote # Если холд нота, то сохраняется сюда
var HOLDING_NOTE := false # Зажата ли холд нота
#endregion

func _ready() -> void:
	HOLDNOTE = load("res://Scenes/Notes/HoldNote.tscn")
	NOTESPAWN_POSITION = NOTESPAWN.position

func _process(_delta) -> void:
	if Input.is_action_pressed(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		$Sprite2D.modulate.a = 0.5
	else: $Sprite2D.modulate.a = 1.0
	position = ROAD_POSITION_MARKER.position
	holding_line_animation_check()

func _physics_process(_delta) -> void:
	
	# Спавнит ноты
	if PENDING_NOTE_INDEX < len(ALL_NOTES):
		var pending_note = ALL_NOTES[PENDING_NOTE_INDEX]
		if (pending_note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] *\
		Conductor.s_per_quarter) <= Conductor.chart_position:
			if pending_note[Global.NOTE_CHART_STRUCTURE.TYPE] == Global.NOTE_TYPE.HOLDNOTE:
				spawn_note(pending_note[Global.NOTE_CHART_STRUCTURE.TYPE],\
				pending_note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO])
			else:
				spawn_note(pending_note[Global.NOTE_CHART_STRUCTURE.TYPE])
			PENDING_NOTE_INDEX += 1
	
	# Смотрит, какие ноты есть в зоне и какие нужно удалять
	if len(ALL_SPAWNED_NOTES) != 0:
		var array_front_note: Note = ALL_SPAWNED_NOTES[0]
		if Scoring.check_note_zone(array_front_note.SPAWN_TIME + Conductor.note_speed):
			NOTES_TO_HIT.push_back(array_front_note)
			ALL_SPAWNED_NOTES.pop_front() #ALL_SPAWNED_NOTES.remove_at(0)
	if len(NOTES_TO_HIT) != 0:
		if !Scoring.check_note_zone(NOTES_TO_HIT[0].SPAWN_TIME + Conductor.note_speed):
			var note = NOTES_TO_HIT[0]
			NOTES_TO_HIT.remove_at(0)
			note.miss_note()
	
	# Проверка для начала холд нот (ОНО РАБОТАЕТ УРА)
	#if len(NOTES_TO_HIT) != 0 and NOTES_TO_HIT[0].NOTE_TYPE == Global.NOTE_TYPE.HOLDNOTE and !HOLDING_NOTE:
	#	var note = NOTES_TO_HIT[0]
	#	if ((note.SPAWN_TIME + Conductor.note_speed) < Conductor.chart_position):
	#		pass
			#init_holding_note(note) # на случай, если нужно будет удерживать холд ноту даже после её пропуска
	# Проверка холд нот
	if HOLDING_NOTE:
		holding_note_check()

func check_note_hit() -> void:
	var note = NOTES_TO_HIT[0]
	match note.NOTE_TYPE:
		Global.NOTE_TYPE.TAPNOTE:
			if PRESSED:
				Scoring.current_score += 100
				Scoring.judge(note)
				NOTES_TO_HIT.remove_at(0)
				note.queue_free()
		Global.NOTE_TYPE.HOLDNOTE:
			if PRESSED:
				Scoring.current_score += 100
				Scoring.judge(note)
				NOTES_TO_HIT.remove_at(0)
				note.modulate.a = 0.0
				init_holding_note(note)

func spawn_note(note_type: int, duration := 0) -> void:
	var note_instantiate
	match note_type:
		Global.NOTE_TYPE.TAPNOTE:
			note_instantiate = TAPNOTE.instantiate()
		Global.NOTE_TYPE.HOLDNOTE:
			note_instantiate = HOLDNOTE.instantiate()
			note_instantiate.NOTE_TYPE = Global.NOTE_TYPE.HOLDNOTE
			note_instantiate.NOTE_LENGTH = duration
		Global.NOTE_TYPE.HOLDNOTETICK:
			note_instantiate = HOLDNOTE.instantiate()
			note_instantiate.NOTE_TYPE = Global.NOTE_TYPE.HOLDNOTETICK
		Global.NOTE_TYPE.HOLDNOTEEND:
			note_instantiate = HOLDNOTE.instantiate()
			note_instantiate.NOTE_TYPE = Global.NOTE_TYPE.HOLDNOTEEND
	ALL_SPAWNED_NOTES.push_back(note_instantiate)
	NOTEHOLDER.add_child(note_instantiate)

# Считает HoldNoteTick и HoldNoteEnd если удержана холд нота
func holding_note_check() -> void:
	if len(NOTES_TO_HIT) == 0:
		return
	for notetick in NOTES_TO_HIT:
		match notetick.NOTE_TYPE:
			Global.NOTE_TYPE.HOLDNOTETICK:
				match PRESSED:
					true:
						Scoring.current_score += 50
						NOTES_TO_HIT.erase(notetick)
						notetick.queue_free()
					false:
						continue
			Global.NOTE_TYPE.HOLDNOTEEND:
				if (notetick.SPAWN_TIME + Conductor.note_speed) > Conductor.chart_position:
					if !PRESSED:
						Scoring.current_score += 50
						NOTES_TO_HIT.erase(notetick)
						notetick.queue_free()
						release_holding_note()
				else:
					if PRESSED:
						Scoring.current_score += 50
						NOTES_TO_HIT.erase(notetick)
						notetick.queue_free()
						release_holding_note()

# Просто функция для удержанной ноты, чтобы избежать дублирования повторяющихся строк в этом коде
func init_holding_note(note: HoldNote) -> void:
	CURRENT_HOLD_NOTE = note
	HOLDING_NOTE = true

# Обнуляет значения после удерживания ноты
func release_holding_note() -> void:
	CURRENT_HOLD_NOTE.HOLDING = false
	CURRENT_HOLD_NOTE.queue_free()
	CURRENT_HOLD_NOTE = null
	HOLDING_NOTE = false

func holding_line_animation_check() -> void:
	if !HOLDING_NOTE:
		return
	match PRESSED:
			true:
				CURRENT_HOLD_NOTE.HOLDING = true
				CURRENT_HOLD_NOTE.LINE_NODE.modulate.a = 1.0
			false:
				CURRENT_HOLD_NOTE.HOLDING = false
				CURRENT_HOLD_NOTE.LINE_NODE.modulate.a = 0.5

# Переключает PRESSED в зависимости от нажатой кнопки
func _unhandled_input(event) -> void:
	if event.is_action_pressed(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		PRESSED = true
		road_input()
	if event.is_action_released(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		PRESSED = false
		road_input()

# Если нажата кнопка, вызывает функцию на удар по ноте
func road_input() -> void:
	if len(NOTES_TO_HIT) == 0:
		return
	check_note_hit()
