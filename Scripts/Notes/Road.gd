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
@onready var PRESS_ANIMATION: AnimationPlayer = $PressAnimation
@onready var HIT_GRADIENT: HitGradient = $HitGradient

var GAMESPACE: Node2D
var ROADS : Array # get_parent().get_children()

var NOTESPAWN_POSITION : Vector2
var ROAD_POSITION_MARKER : Marker2D

var ALL_COLORS : Array # Список всех цветов
var CURRENT_COLOR : Color # Цвет, который необходимо выбирать в данный момент времени
var PENDING_COLOR_INDEX : int = 0 # Индекс цвета, который должен быть выбран CURRENT_COLOR

var ALL_NOTES : Array # Список всех нот
var MAX_SPAWN_CYCLES: int = 6 # Кол-во элементов, которые нужно проходить в один момент в spawn_notes
var PENDING_NOTE_INDEX : int = 0 # Индекс ноты, которую нужно заспавнить
var ALL_SPAWNED_NOTES: Array # Список всех появляющихся нот
var NOTES_TO_HIT : Array # Список нот, которые находятся в зоне удара

var PRESSED := false # Проверяет, нажата ли клавиша

var BOT_SHOULD_HOLD := false # Указывает, нужно ли боту задержать клавишу

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
	
	release_holding_note()
	
	release_sliding_note()
	
	connect_holding_note()
	
	connect_sliding_note()
	
	holding_note_check()
	
	sliding_note_check()
	
	#region Тут важна последовательность
	update_colors()
	
	spawn_notes()
	#endregion
	
	# При первой возможности пушит слайдер из очереди в нажатый
	if CURRENT_CONTROL_SLIDER == null and PENDING_CONTROL_SLIDER != null:
		CURRENT_CONTROL_SLIDER = PENDING_CONTROL_SLIDER
		PENDING_CONTROL_SLIDER = null
	# Так же и с холд нотами
	if CURRENT_HOLD_NOTE == null and PENDING_HOLD_NOTE != null:
		CURRENT_HOLD_NOTE = PENDING_HOLD_NOTE
		PENDING_HOLD_NOTE = null
	
	update_notes()
	
	bot_monitor()

	# Проверка для начала холд нот (ОНО РАБОТАЕТ УРА)
	# Я забыл почему я это закомментил
	# UPD: А, это если вдруг я захочу сделать удерживание ноты после пропуска начала
	#if len(NOTES_TO_HIT) != 0 and NOTES_TO_HIT[0].NOTE_TYPE == Global.NOTE_TYPE.HOLDNOTE and !HOLDING_NOTE:
	#	var note = NOTES_TO_HIT[0]
	#	if ((note.SPAWN_TIME + Conductor.note_speed) < Conductor.chart_position):
	#		pass
			#init_holding_note(note) # на случай, если нужно будет удерживать холд ноту даже после её пропуска
#endregion

# Спавнит ноты
func spawn_notes() -> void:
	if len(ALL_NOTES) != 0 and PENDING_NOTE_INDEX <= len(ALL_NOTES):
		for pending_note_index in range(PENDING_NOTE_INDEX, PENDING_NOTE_INDEX + MAX_SPAWN_CYCLES):
			if pending_note_index < len(ALL_NOTES):
				var pending_note: Array = ALL_NOTES[pending_note_index]
				if (pending_note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] *\
				Conductor.s_per_quarter) + Conductor.bpm_change_time <= Conductor.chart_position:
					spawn_note(pending_note)
					PENDING_NOTE_INDEX += 1
	# Коммент снизу - быстрофикс проблемы неправильного порядка спавна нот
	#if len(ALL_NOTES) != 0:
	#	for pending_note in ALL_NOTES:
	#		if (pending_note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN] *\
	#		Conductor.s_per_quarter) + Conductor.bpm_change_time <= Conductor.chart_position:
	#			spawn_note(pending_note)
	#			ALL_NOTES.erase(pending_note)

func update_notes() -> void:
	# Смотрит, какие ноты есть в зоне и удаляет те, которые уже пролетели
	if len(ALL_SPAWNED_NOTES) != 0:
		var delete: Array = []
		for note_index in range(len(ALL_SPAWNED_NOTES)):
			var note: Note = ALL_SPAWNED_NOTES[note_index]
			var before_note: Note
			var after_note: Note
			if note_index > 0 and !(ALL_SPAWNED_NOTES[note_index - 1] in delete):
				before_note = ALL_SPAWNED_NOTES[note_index - 1]
			if note_index < len(ALL_SPAWNED_NOTES) - 1 and !(ALL_SPAWNED_NOTES[note_index + 1] in delete):
				after_note = ALL_SPAWNED_NOTES[note_index + 1]
			if Score.check_note_zone(note, before_note, after_note):
				if !(note in NOTES_TO_HIT):
					NOTES_TO_HIT.push_back(note)
			else:
				if (Conductor.song_position > (note.SPAWN_QUARTERS * Conductor.s_per_quarter)) and\
				(note in NOTES_TO_HIT):
					delete.push_back(note)
					if (note.NOTE_TYPE == Global.NOTE_TYPE.TAPNOTE) or\
					(note.NOTE_TYPE == Global.CONTROL_TYPE.HOLDCONTROL) or\
					(note.NOTE_TYPE == Global.CONTROL_TYPE.SLIDERCONTROL):
						note.miss_note()
						Scoring.judge_miss(note)
					else:
						note.miss_note()
		for note in delete:
			ALL_SPAWNED_NOTES.erase(note)
			NOTES_TO_HIT.erase(note)

func update_colors() -> void:
	if len(ALL_COLORS) != 0 and PENDING_COLOR_INDEX < len(ALL_COLORS):
		var color_array: Array = ALL_COLORS[PENDING_COLOR_INDEX]
		var color_quarter_to_spawn: int = color_array[Global.COLORWAY_CHART_STRUCTURE.QUARTER_TO_SPAWN]
		var color: Color = color_array[Global.COLORWAY_CHART_STRUCTURE.COLORWAY]
		if (color_quarter_to_spawn * Conductor.s_per_quarter) <= Conductor.chart_position:
			CURRENT_COLOR = color
			PENDING_COLOR_INDEX += 1

#region Функции бота
func bot_play_press() -> void:
	PRESSED = true
	road_input()
	if BOT_SHOULD_HOLD:
		return
	PRESSED = false

func bot_play_release() -> void:
	if Settings.BOT_PLAY:
		BOT_SHOULD_HOLD = false
		PRESSED = false

func bot_monitor() -> void:
	if len(NOTES_TO_HIT) != 0:
		for note in NOTES_TO_HIT:
			if (Settings.BOT_PLAY) and ((note.SPAWN_QUARTERS * Conductor.s_per_quarter) <= Conductor.song_position)\
			and !(note.NOTE_TYPE in Global.CONTROL_TYPE):
				bot_play_press()
#endregion

# Вызывается, когда срабатывает изменение PRESSED
func check_note_hit() -> void:
	var one_hit: bool = false # тап и холд ноты можно нажать только первыми в списке
	var one_slider_hit: bool = false # слайдер отдельно, т.к. нужно учесть,
									#что слайдер может быть на дороге с обычной нотой
	var delete: Array = []
	for note in NOTES_TO_HIT:
		match note.NOTE_TYPE:
			Global.NOTE_TYPE.TAPNOTE:
				if one_hit:
					continue
				delete.push_back(note)
				ALL_SPAWNED_NOTES.pop_front()
				Scoring.judge(note)
				note.hit_note()
				QUEUE_HITSOUND = true
				QUEUE_HITSOUND_TIME = note.SPAWN_QUARTERS * Conductor.s_per_quarter
				HIT_GRADIENT.play_anim(note.COLOR)
				one_hit = true
			Global.CONTROL_TYPE.HOLDCONTROL:
				if one_hit:
					continue
				BOT_SHOULD_HOLD = true
				delete.push_back(note)
				ALL_SPAWNED_NOTES.pop_front()
				Scoring.judge(note)
				init_holding_note(note)
				note.hit_note()
				QUEUE_HITSOUND = true
				QUEUE_HITSOUND_TIME = note.SPAWN_QUARTERS * Conductor.s_per_quarter
				HIT_GRADIENT.play_anim(note.COLOR)
				one_hit = true
			Global.CONTROL_TYPE.SLIDERCONTROL:
				if one_slider_hit:
					continue
				BOT_SHOULD_HOLD = true
				delete.push_back(note)
				ALL_SPAWNED_NOTES.pop_front()
				Scoring.judge(note)
				init_sliding_note(note)
				note.hit_note()
				QUEUE_HITSOUND = true
				QUEUE_HITSOUND_TIME = note.SPAWN_QUARTERS * Conductor.s_per_quarter
				one_slider_hit = true
	if len(delete) != 0:
		for note in delete:
			NOTES_TO_HIT.erase(note)
		delete = []

func _unhandled_input(event: InputEvent) -> void:
	if Settings.BOT_PLAY:
		return
	if event.is_action_pressed(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		PRESSED = true
		road_input()
	elif event.is_action_released(Global.CORRESPONDING_INPUTS[Global.CURRENT_CHART_SIZE][road_index]):
		PRESSED = false

func spawn_note(note: Array) -> void:
	var spawn_quarters = note[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]
	var note_type: int = note[Global.NOTE_CHART_STRUCTURE.TYPE]
	var note_instantiate
	
	match note_type:
		Global.NOTE_TYPE.TAPNOTE:
			note_instantiate = TAPNOTE.instantiate()
			note_instantiate.COLOR = CURRENT_COLOR
		Global.NOTE_TYPE.HOLDNOTE:
			note_instantiate = HOLDNOTE.instantiate()
			note_instantiate.NOTE_TYPE = Global.NOTE_TYPE.HOLDNOTE
			note_instantiate.NOTE_LENGTH = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION]
			note_instantiate.COLOR = CURRENT_COLOR
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
			note_instantiate.COLOR = CURRENT_COLOR
			next_road.PASS_SLIDER_NODE.push_back(note_instantiate)
		Global.NOTE_TYPE.SLIDERTICK:
			note_instantiate = SLIDER.instantiate()
			var next_road = ROADS[note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_ROAD]]
			note_instantiate.NOTE_TYPE = Global.NOTE_TYPE.SLIDERTICK
			note_instantiate.ID = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.ID]
			note_instantiate.NEXT_ROAD = next_road
			note_instantiate.NEXT_NOTE_SPAWN_QUARTER = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.NEXT_SPAWN_QUARTER]
			note_instantiate.COLOR = CURRENT_COLOR
			next_road.PASS_SLIDER_NODE.push_back(note_instantiate)
		Global.NOTE_TYPE.SLIDEREND:
			note_instantiate = SLIDER.instantiate()
			note_instantiate.NOTE_TYPE = Global.NOTE_TYPE.SLIDEREND
			note_instantiate.ID = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.ID]
			note_instantiate.COLOR = CURRENT_COLOR
		Global.CONTROL_TYPE.SLIDERCONTROL:
			note_instantiate = SLIDER.instantiate()
			note_instantiate.ID = note[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO][Global.SLIDER_NOTE_ADDITIONAL_INFO.ID]
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
		CONNECT_HOLD_TO_CONTROL.COLOR = PASS_HOLD_NODE[0].COLOR
		CONNECT_HOLD_TO_CONTROL = null
		PASS_HOLD_NODE.pop_front()

# Просто функция для удержанной ноты, чтобы избежать дублирования повторяющихся строк в этом коде
func init_holding_note(note: HoldNote) -> void:
	PENDING_HOLD_NOTE = note

# Считает HoldNoteTick и HoldNoteEnd если удержана холд нота
func holding_note_check() -> void:
	if CURRENT_HOLD_NOTE == null:
		return
	HIT_GRADIENT.play_holding_anim(CURRENT_HOLD_NOTE.COLOR)
	if len(NOTES_TO_HIT) == 0:
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
		ALL_SPAWNED_NOTES.erase(notetick)
		NOTES_TO_HIT.erase(notetick)
	delete = []

# Обнуляет значения после удерживания ноты
func release_holding_note() -> void:
	if CURRENT_HOLD_NOTE != null:
		if ((CURRENT_HOLD_NOTE.SPAWN_QUARTERS + CURRENT_HOLD_NOTE.NOTE_LENGTH) *\
		Conductor.s_per_quarter) <= Conductor.song_position:
			CURRENT_HOLD_NOTE.HOLD_TO_CONTROL.HOLDING = false
			CURRENT_HOLD_NOTE.HOLD_TO_CONTROL.queue_free()
			CURRENT_HOLD_NOTE.queue_free()
			CURRENT_HOLD_NOTE = null
			RELEASE_HOLDING_NOTE = false
			bot_play_release()

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
	if CONNECT_SLIDER_TO_CONTROL != null and len(PASS_SLIDER_NODE) > 0 and\
	PASS_SLIDER_NODE[0].ID == CONNECT_SLIDER_TO_CONTROL.ID:
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
		ALL_SPAWNED_NOTES.erase(notetick)
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
			bot_play_release()

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
	if PRESSED:
		PRESS_ANIMATION.stop()
		PRESS_ANIMATION.play("press")
		if len(NOTES_TO_HIT) == 0:
			return
		check_note_hit()
