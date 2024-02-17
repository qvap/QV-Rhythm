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
var SLIDER := preload("res://Scenes/Notes/SliderNote.tscn")

@onready var NOTESPAWN := $NoteSpawn
@onready var NOTEHOLDER := $NoteHolder
var GAMESPACE: Node2D
var ROADS : Array # get_parent().get_children()

var NOTESPAWN_POSITION : Vector2
var ROAD_POSITION_MARKER : Marker2D

var ALL_NOTES : Array # Список всех нот
var PENDING_NOTE_INDEX := 0 # Индекс ноты, которую нужно заспавнить
var ALL_SPAWNED_NOTES: Array # Список всех появляющихся нот
var NOTES_TO_HIT : Array # Список нот, которые находятся в зоне удара

var PRESSED := false # Проверяет, нажата ли клавиша

# ХОЛД НОТЫ
var PENDING_HOLD_NOTE : HoldNote # Ставит в очередь нажатую холд ноту
var CURRENT_HOLD_NOTE : HoldNote # Холд нота, нажатая сейчас
var RELEASE_HOLDING_NOTE := false # Говорит о том, что холд ноту нужно удалить

var CONNECT_HOLD_TO_CONTROL : HoldNote # Чтобы подключать холд ноты к контроллерам
var PASS_HOLD_NODE: Array # не придумал ничего лучше

# СЛАЙДЕР НОТЫ
var PENDING_CONTROL_SLIDER : SliderNote # Ставит в очередь нажатый слайдер
var CURRENT_CONTROL_SLIDER : SliderNote # Слайдер, который идёт сейчас
var RELEASE_SLIDER : bool = false

var PASS_SLIDER_NODE : Array # Нужно передавать слайдер с одной дорожки на другой
var CONNECT_SLIDER_TO_CONTROL : SliderNote # Чтобы подключать слайдеры к контроллерам
var QUEUE_ENDPOINTS_TO_DELETE : Array # Пихает сюда конечные точки слайдеров, чтобы потом их удалить

var QUEUE_HITSOUND := false # ставит в очередь проигрывание хитсаунда
var QUEUE_HITSOUND_TIME : float # время ноты, для которой играет хитсаунд
#endregion

func _ready() -> void:
	GAMESPACE = get_parent().get_parent()
	HOLDNOTE = load("res://Scenes/Notes/HoldNote.tscn") # ещё раз спасибо
	NOTESPAWN_POSITION = NOTESPAWN.position

func get_roads_array() -> void:
	ROADS = GAMESPACE.ROADS_MASSIVE

#region process
func _process(_delta) -> void:
	if Input.is_action_pressed(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		$Sprite2D.modulate.a = 0.25
	else: $Sprite2D.modulate.a = 0.5
	position = ROAD_POSITION_MARKER.position
	if !RELEASE_HOLDING_NOTE:
		holding_line_animation_check()
	if !RELEASE_SLIDER:
		sliding_line_animation_check()
	
	# Хитсаунды
	if QUEUE_HITSOUND and Conductor.playback_time > QUEUE_HITSOUND_TIME:
		Conductor.play_hitsound()
		QUEUE_HITSOUND = false
#endregion

#region physics_process
func _physics_process(_delta) -> void:
	
	# Спавнит ноты
	if PENDING_NOTE_INDEX < len(ALL_NOTES):
		
		var pending_note = ALL_NOTES[PENDING_NOTE_INDEX]
		
		if (pending_note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] *\
		Conductor.s_per_quarter) <= Conductor.chart_position:
			spawn_note(pending_note)
			PENDING_NOTE_INDEX += 1
	
	# При первой возможности пушит слайдер из очереди в нажатый
	if CURRENT_CONTROL_SLIDER == null:
		CURRENT_CONTROL_SLIDER = PENDING_CONTROL_SLIDER
		PENDING_CONTROL_SLIDER = null
	# Так же и с холд нотами
	if CURRENT_HOLD_NOTE == null:
		CURRENT_HOLD_NOTE = PENDING_HOLD_NOTE
		PENDING_HOLD_NOTE = null
	
	# Смотрит, какие ноты есть в зоне
	if len(ALL_SPAWNED_NOTES) != 0:
		var array_front_note: Note = ALL_SPAWNED_NOTES[0]
		if Scoring.check_note_zone((array_front_note.SPAWN_QUARTERS * Conductor.s_per_quarter)\
		+ Conductor.note_speed):
			NOTES_TO_HIT.push_back(array_front_note)
			ALL_SPAWNED_NOTES.pop_front() #ALL_SPAWNED_NOTES.remove_at(0)
	
	# Считывает нажатия
	if Input.is_action_just_pressed(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		PRESSED = true
		road_input()
	elif Input.is_action_just_released(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		PRESSED = false
		road_input()
	
	# Смотрит, какие ноты уже пролетели и вызывает у них miss_note
	if len(NOTES_TO_HIT) != 0:
		var note = NOTES_TO_HIT[0]
		if !Scoring.check_note_zone((note.SPAWN_QUARTERS * Conductor.s_per_quarter)\
		+ Conductor.note_speed):
			NOTES_TO_HIT.erase(note)
			if (note.NOTE_TYPE == Global.NOTE_TYPE.TAPNOTE) or\
			(note.NOTE_TYPE == Global.CONTROL_TYPE.HOLDCONTROL) or\
			(note.NOTE_TYPE == Global.CONTROL_TYPE.SLIDERCONTROL):
				note.miss_note()
				Scoring.judge(note)
			else:
				note.miss_note()
	
	# Проверка для начала холд нот (ОНО РАБОТАЕТ УРА)
	# Я забыл почему я это закомментил
	# UPD: А, это если вдруг я захочу сделать удерживание ноты после пропуска начала
	#if len(NOTES_TO_HIT) != 0 and NOTES_TO_HIT[0].NOTE_TYPE == Global.NOTE_TYPE.HOLDNOTE and !HOLDING_NOTE:
	#	var note = NOTES_TO_HIT[0]
	#	if ((note.SPAWN_TIME + Conductor.note_speed) < Conductor.chart_position):
	#		pass
			#init_holding_note(note) # на случай, если нужно будет удерживать холд ноту даже после её пропуска
	
	
	release_holding_note()
	
	release_sliding_note()
	
	holding_note_check()
	
	sliding_note_check()
	
	connect_holding_note()
	
	connect_sliding_note()
#endregion

# Вызывается, когда срабатывает изменение PRESSED
func check_note_hit() -> void:
	var note = NOTES_TO_HIT[0]
	match note.NOTE_TYPE:
		Global.NOTE_TYPE.TAPNOTE:
			if PRESSED:
				NOTES_TO_HIT.erase(note)
				Scoring.judge(note)
				QUEUE_HITSOUND = true
				QUEUE_HITSOUND_TIME = note.SPAWN_QUARTERS * Conductor.s_per_quarter
				note.queue_free()
		Global.CONTROL_TYPE.HOLDCONTROL:
			if PRESSED:
				NOTES_TO_HIT.erase(note)
				Scoring.judge(note)
				init_holding_note(note)
				QUEUE_HITSOUND = true
				QUEUE_HITSOUND_TIME = note.SPAWN_QUARTERS * Conductor.s_per_quarter
				note.HOLD_TO_CONTROL.SKIN.visible = false
		Global.CONTROL_TYPE.SLIDERCONTROL:
			if PRESSED:
				NOTES_TO_HIT.erase(note)
				Scoring.judge(note)
				init_sliding_note(note)
				QUEUE_HITSOUND = true
				QUEUE_HITSOUND_TIME = note.SPAWN_QUARTERS * Conductor.s_per_quarter
				note.SLIDER_TO_CONTROL.SKIN.visible = false

func spawn_note(note: Array) -> void:
	var spawn_quarters = note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]
	var note_type: int = note[Global.NOTE_CHART_STRUCTURE.TYPE]
	var note_instantiate
	
	match note_type:
		Global.NOTE_TYPE.TAPNOTE:
			note_instantiate = TAPNOTE.instantiate()
		Global.NOTE_TYPE.HOLDNOTE:
			note_instantiate = HOLDNOTE.instantiate()
			note_instantiate.NOTE_TYPE = Global.NOTE_TYPE.HOLDNOTE
			note_instantiate.NOTE_LENGTH = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]
			PASS_HOLD_NODE.push_back(note_instantiate)
		Global.CONTROL_TYPE.HOLDCONTROL:
			note_instantiate = HOLDNOTE.instantiate()
			note_instantiate.NOTE_TYPE = Global.CONTROL_TYPE.HOLDCONTROL
			note_instantiate.NOTE_LENGTH = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]
			CONNECT_HOLD_TO_CONTROL = note_instantiate
		Global.CONTROL_TYPE.HOLDCONTROLTICK:
			note_instantiate = HOLDNOTE.instantiate()
			note_instantiate.NOTE_TYPE = Global.CONTROL_TYPE.HOLDCONTROLTICK
		Global.CONTROL_TYPE.HOLDCONTROLEND:
			note_instantiate = HOLDNOTE.instantiate()
			note_instantiate.NOTE_TYPE = Global.CONTROL_TYPE.HOLDCONTROLEND
		Global.NOTE_TYPE.SLIDER:
			note_instantiate = SLIDER.instantiate()
			var next_road = ROADS[note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_ROAD]]
			note_instantiate.NOTE_TYPE = Global.NOTE_TYPE.SLIDER
			note_instantiate.ID = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.ID]
			note_instantiate.NEXT_ROAD = next_road
			note_instantiate.NEXT_NOTE_SPAWN_QUARTER = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_SPAWN_QUARTER]
			next_road.PASS_SLIDER_NODE.push_back(note_instantiate)
		Global.NOTE_TYPE.SLIDERTICK:
			note_instantiate = SLIDER.instantiate()
			var next_road = ROADS[note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_ROAD]]
			note_instantiate.NOTE_TYPE = Global.NOTE_TYPE.SLIDERTICK
			note_instantiate.ID = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.ID]
			note_instantiate.NEXT_ROAD = next_road
			note_instantiate.NEXT_NOTE_SPAWN_QUARTER = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_SPAWN_QUARTER]
			next_road.PASS_SLIDER_NODE.push_back(note_instantiate)
		Global.NOTE_TYPE.SLIDEREND:
			note_instantiate = SLIDER.instantiate()
			note_instantiate.NOTE_TYPE = Global.NOTE_TYPE.SLIDEREND
			note_instantiate.ID = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.ID]
		Global.CONTROL_TYPE.SLIDERCONTROL:
			note_instantiate = SLIDER.instantiate()
			note_instantiate.NOTE_TYPE = Global.CONTROL_TYPE.SLIDERCONTROL
			CONNECT_SLIDER_TO_CONTROL = note_instantiate
		Global.CONTROL_TYPE.SLIDERCONTROLTICK:
			note_instantiate = SLIDER.instantiate()
			note_instantiate.NOTE_TYPE = Global.CONTROL_TYPE.SLIDERCONTROLTICK
		Global.CONTROL_TYPE.SLIDERCONTROLEND:
			note_instantiate = SLIDER.instantiate()
			note_instantiate.NOTE_TYPE = Global.CONTROL_TYPE.SLIDERCONTROLEND
	
	note_instantiate.SPAWN_QUARTERS = spawn_quarters
	if (note_type != Global.NOTE_TYPE.SLIDER) and (note_type != Global.NOTE_TYPE.SLIDERTICK) and (note_type != Global.NOTE_TYPE.HOLDNOTE):
		# Не нужно, чтобы оно считывало попадания по не контроллерам
		ALL_SPAWNED_NOTES.push_back(note_instantiate)
	NOTEHOLDER.add_child(note_instantiate)

#region ХОЛД НОТЫ
func connect_holding_note() -> void:
	if CONNECT_HOLD_TO_CONTROL != null and len(PASS_HOLD_NODE) != 0:
		CONNECT_HOLD_TO_CONTROL.HOLD_TO_CONTROL = PASS_HOLD_NODE[0]
		CONNECT_HOLD_TO_CONTROL = null
		PASS_HOLD_NODE.pop_front()

# Просто функция для удержанной ноты, чтобы избежать дублирования повторяющихся строк в этом коде
func init_holding_note(note: HoldNote) -> void:
	PENDING_HOLD_NOTE = note

# Считает HoldNoteTick и HoldNoteEnd если удержана холд нота
func holding_note_check() -> void:
	if len(NOTES_TO_HIT) == 0 or CURRENT_HOLD_NOTE == null:
		return
	var delete := [] # в доках написано не удалять значения в списке когда идёт цикл, поэтому я добавил это
	for notetick in NOTES_TO_HIT:
		match notetick.NOTE_TYPE:
			Global.CONTROL_TYPE.HOLDCONTROLTICK:
				match PRESSED:
					true:
						Scoring.current_score += 50
						delete.push_back(notetick)
						notetick.queue_free()
					false:
						continue
			Global.CONTROL_TYPE.HOLDCONTROLEND:
				if PRESSED:
					Scoring.current_score += 50
					delete.push_back(notetick)
					notetick.queue_free()
					RELEASE_HOLDING_NOTE = true
	for notetick in delete:
		NOTES_TO_HIT.erase(notetick)
	delete = []

# Обнуляет значения после удерживания ноты
func release_holding_note() -> void:
	if CURRENT_HOLD_NOTE != null:
		if ((CURRENT_HOLD_NOTE.SPAWN_QUARTERS + CURRENT_HOLD_NOTE.NOTE_LENGTH) *\
		Conductor.s_per_quarter) < Conductor.song_position:
			if RELEASE_HOLDING_NOTE:
				QUEUE_HITSOUND_TIME = (CURRENT_HOLD_NOTE.SPAWN_QUARTERS + CURRENT_HOLD_NOTE.NOTE_LENGTH) *\
				Conductor.s_per_quarter
				QUEUE_HITSOUND = true
			CURRENT_HOLD_NOTE.HOLD_TO_CONTROL.HOLDING = false
			CURRENT_HOLD_NOTE.HOLD_TO_CONTROL.queue_free()
			CURRENT_HOLD_NOTE.queue_free()
			CURRENT_HOLD_NOTE = null
			RELEASE_HOLDING_NOTE = false

func holding_line_animation_check() -> void:
	if CURRENT_HOLD_NOTE == null:
		return
	match PRESSED:
			true:
				CURRENT_HOLD_NOTE.HOLD_TO_CONTROL.HOLDING = true
				CURRENT_HOLD_NOTE.HOLD_TO_CONTROL.LINE_NODE.modulate.a = 1.0
			false:
				CURRENT_HOLD_NOTE.HOLD_TO_CONTROL.HOLDING = false
				CURRENT_HOLD_NOTE.HOLD_TO_CONTROL.LINE_NODE.modulate.a = 0.5
#endregion

#region СЛАЙДЕР НОТЫ
# Передаёт контроллеру слайдер с другой дорожки
func connect_sliding_note() -> void:
	if CONNECT_SLIDER_TO_CONTROL != null and len(PASS_SLIDER_NODE) > 0:
		CONNECT_SLIDER_TO_CONTROL.SLIDER_TO_CONTROL = PASS_SLIDER_NODE[0]
		CONNECT_SLIDER_TO_CONTROL = null
		PASS_SLIDER_NODE.pop_front()

func init_sliding_note(note: SliderNote) -> void:
	PENDING_CONTROL_SLIDER = note

func sliding_note_check() -> void:
	if CURRENT_CONTROL_SLIDER == null or len(NOTES_TO_HIT) == 0:
		return
	var delete = []
	for notetick in NOTES_TO_HIT:
		match notetick.NOTE_TYPE:
			Global.CONTROL_TYPE.SLIDERCONTROLTICK:
				match PRESSED:
					true:
						Scoring.current_score += 50
						delete.push_back(notetick)
						notetick.queue_free()
					false:
						continue
			Global.CONTROL_TYPE.SLIDERCONTROLEND:
				match PRESSED:
					true:
						Scoring.current_score += 50
						delete.push_back(notetick)
						notetick.queue_free()
						RELEASE_SLIDER = true
					false:
						continue
			Global.NOTE_TYPE.SLIDEREND:
				match PRESSED:
					true:
						QUEUE_ENDPOINTS_TO_DELETE.push_back(notetick)
						delete.push_back(notetick)
					false:
						continue
	for notetick in delete:
		NOTES_TO_HIT.erase(notetick)
	delete = []

func release_sliding_note() -> void:
	if CURRENT_CONTROL_SLIDER != null:
		if (CURRENT_CONTROL_SLIDER.SLIDER_TO_CONTROL.NEXT_NOTE_SPAWN_QUARTER * Conductor.s_per_quarter) < Conductor.song_position:
			if RELEASE_SLIDER:
				QUEUE_HITSOUND_TIME = CURRENT_CONTROL_SLIDER.SLIDER_TO_CONTROL.NEXT_NOTE_SPAWN_QUARTER * Conductor.s_per_quarter
				QUEUE_HITSOUND = true
			CURRENT_CONTROL_SLIDER.SLIDER_TO_CONTROL.SLIDING = false
			CURRENT_CONTROL_SLIDER.SLIDER_TO_CONTROL.LINE_NODE.queue_free()
			CURRENT_CONTROL_SLIDER.SLIDER_TO_CONTROL.queue_free()
			CURRENT_CONTROL_SLIDER.queue_free()
			CURRENT_CONTROL_SLIDER = null
			RELEASE_SLIDER = false
			delete_slider_endpoint()

# Удаляет конечную точку слайдера
func delete_slider_endpoint() -> void:
	if len(QUEUE_ENDPOINTS_TO_DELETE) > 0:
		QUEUE_ENDPOINTS_TO_DELETE[0].queue_free()
		QUEUE_ENDPOINTS_TO_DELETE.pop_front()

func sliding_line_animation_check() -> void:
	if CURRENT_CONTROL_SLIDER != null:
		match PRESSED:
			true:
				CURRENT_CONTROL_SLIDER.SLIDER_TO_CONTROL.SLIDING = true
				CURRENT_CONTROL_SLIDER.SLIDER_TO_CONTROL.modulate.a = 1.0
			false:
				CURRENT_CONTROL_SLIDER.SLIDER_TO_CONTROL.SLIDING = false
				CURRENT_CONTROL_SLIDER.SLIDER_TO_CONTROL.modulate.a = 0.5
#endregion

# Если нажата кнопка, вызывает функцию на удар по ноте
func road_input() -> void:
	if len(NOTES_TO_HIT) == 0:
		return
	check_note_hit()
