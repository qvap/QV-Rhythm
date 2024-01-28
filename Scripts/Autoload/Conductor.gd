extends Node
class_name ConductorScript

# Отвечает не только за синхронизацию игры и музыки, но и за саму музыку
# Принцип работы: за синхронизацию отвечают два параметра: song_position и chart_position
# Чтобы иметь возможность добавлять ноты до того, как заиграет музыка, существует
# функция play_song_with_offset(), которая запускает счёт, но не саму музыку,
# при этом до начала музыки chart_position высчитывается через часы ОС, а после начала
# подключается к методу через часы аудиосервера вместе с song_position

# Тем самым дублируются переменные для song_position и chart_position
# Да, это не очень хорошо, но тем самым мы можем репортить эти переменные асинхронно

# ЭКСПОРТЫ

# Экспорт переменных для удобной настройки
@export_group("Conductor")
@export var bpm := 114.0
@export var start_offset := 0.0
@export var measure := 4

# Поможет учесть задержку девайсов игроков
@export var offset := 0.0

# Указывает АудиоПлеер и таймер начала
@onready var MUSICSTREAMPLAYER := $Music
@onready var STARTTIMER := $StartTimer

# Сигналы для подключения
signal beat_hit(beat_count)
signal quarter_hit(quarter_count)
signal measure_hit(measure_count)
# Дупликаты для чарта
signal chart_beat_hit(beat_count)
signal chart_quarter_hit(quarter_count)
signal chart_measure_hit(measure_count)

# ПЕРЕМЕННЫЕ
var running := false
var playing := false
var song_occured := false

var s_per_beat: float
var s_per_quarter: float
var s_per_measure: float

var playback_time := 0.0

# Добавляю ещё одну переменную, так как хочу отделить время проигрывания от времени кондуктора
# (Это поможет использовать задержку начала отсчёта музыки)
# -1, потому что если выставлять ноль, то оно будет репортить первый бит сразу
var song_position := -1.0

# -100.0 чтобы учесть, что он должен начаться в первый фрейм запуска playing
var chart_position := -100.0

# Всё настроено на -1, чтобы репортить начальное значение 0
var current_beat := -1
var last_beat := -1

var current_quarter := -1
var last_quarter := -1

var current_measure := -1
var last_measure := -1

# Дупликаты для чартов
var current_chart_beat := -1
var last_chart_beat := -1

var current_chart_quarter := -1
var last_chart_quarter := -1

var current_chart_measure := -1
var last_chart_measure := -1

var song_length: float
var note_speed := Global.NOTE_SPEED_CONSTANT
var engine_time_last_update := 0.0

# ФУНКЦИИ

# Инициализирует модуль
func run() -> void:
	update()
	running = true

# Обновляет значения (используется, если поменялся BPM или Measure)
func update() -> void:
	s_per_beat = 60.0/bpm
	s_per_quarter = s_per_beat/4
	s_per_measure = s_per_beat*measure

# Загружает музыку по пути (is_custom_map_path просто сокращает передаваемый аргумент,
# ибо проверяет специально отведённую папку под кастомные карты)
func load_song(SONG_PATH: String, is_custom_map_path := false) -> void:
	if playing:
		stop_song()
	if !is_custom_map_path:
		MUSICSTREAMPLAYER.stream = load(SONG_PATH)
	else:
		MUSICSTREAMPLAYER.stream = load("res://CustomMaps/"+SONG_PATH+"/music.mp3")
	song_length = MUSICSTREAMPLAYER.stream.get_length()

# Облегчает загрузку музыки, если используется CustomMap JSON файл
func load_song_from_json(json_dictionary: Dictionary, folder_name: String) -> void:
	load_song(folder_name, true)
	bpm = json_dictionary["music_bpm"]
	measure = json_dictionary["music_measure"]
	start_offset = json_dictionary["music_offset"]
	note_speed = clamp(json_dictionary["note_speed"] * Global.NOTE_SPEED_CONSTANT, 0.25, 3.0) # ограничения скорости нот
	update()

# Запускает музыку если есть Stream и запускает процесс счёта в _physics_process
func play_song() -> void:
	song_occured = true
	playing = true
	MUSICSTREAMPLAYER.play()

# Запускает отсчёт, но запускает музыку с задержкой
func play_song_with_offset() -> void:
	chart_position -= offset + start_offset
	playing = true
	engine_time_last_update = Time.get_ticks_usec()
	STARTTIMER.wait_time = note_speed
	STARTTIMER.start()
	await STARTTIMER.timeout
	play_song()

# Просто останавливает Stream и отключает процесс счёта в _physics_process
func stop_song() -> void:
	MUSICSTREAMPLAYER.stop()
	MUSICSTREAMPLAYER.stream = null
	playing = false

# Выставляет стандартные значения (a little stupid чтобы знать как это сократить)
func reset_playback() -> void:
	song_position = -1.0
	chart_position = -100.0
	current_beat = -1
	last_beat = -1
	current_quarter = -1
	last_quarter = -1
	current_measure = -1
	last_measure = -1
	current_chart_beat = -1
	last_chart_beat = -1
	current_chart_quarter = -1
	last_chart_quarter = -1
	current_chart_measure = -1
	last_chart_measure = -1

func _physics_process(_delta) -> void:
	# Не идёт дальше, если модуль не запущен
	if !running: return
	
	# Считает только если играет музыка
	if playing:
		if song_occured:
			# Считает позицию музыки через часы аудиосистемы
			song_position = MUSICSTREAMPLAYER.get_playback_position() + AudioServer.get_time_since_last_mix()
			song_position -= AudioServer.get_output_latency() + offset + start_offset
		
			# Считает позицию чарта ПО АБСОЛЮТНО ДРУГОМУ МЕТОДУ ЧЕРЕЗ ЧАСЫ ОПЕРАЦИОНКИ
			# По идее это может мне потом сломать игру, т.к. не факт что оно будет хорошо синхронизировано
			# но вопрос: КАК ЕЩЁ ЭТО МНЕ РЕАЛИЗОВЫВАТЬ, Я ГОЛОВУ ЦЕЛЫЙ ДЕНЬ ЛОМАЮ
			chart_position = song_position + note_speed
		else:
			if chart_position <= -100.0:
				chart_position += 100.0
			chart_position += (Time.get_ticks_usec() - engine_time_last_update) / 1_000_000.0
			engine_time_last_update = Time.get_ticks_usec()
		
		playback_time = MUSICSTREAMPLAYER.get_playback_position()
		current_measure = floor(song_position/s_per_measure)
		report_measure()
		
		current_beat = floor(song_position/s_per_beat)
		report_beat()
		
		current_quarter = floor(song_position/s_per_quarter)
		report_quarter()
		
		# Дупликаты для чарта
		current_chart_measure = floor(chart_position/s_per_measure)
		report_chart_measure()
		
		current_chart_beat = floor(chart_position/s_per_beat)
		report_chart_beat()
		
		current_chart_quarter = floor(chart_position/s_per_quarter)
		report_chart_quarter()
		
		if playback_time > song_length: stop_song()

func report_beat() -> void:
	if last_beat < current_beat:
		last_beat = current_beat
		emit_signal("beat_hit", current_beat)
		$SFX.play() # временная вставка
	else: return

func report_quarter() -> void:
	if last_quarter < current_quarter:
		last_quarter = current_quarter
		emit_signal("quarter_hit", current_quarter)
	else: return

func report_measure() -> void:
	if last_measure < current_measure:
		last_measure = current_measure
		emit_signal("measure_hit", current_measure)
	else: return

# Дупликаты верхних функций, уже для chart_position
func report_chart_beat() -> void:
	if last_chart_beat < current_chart_beat:
		last_chart_beat = current_chart_beat
		emit_signal("chart_beat_hit", current_chart_beat)
	else: return

func report_chart_quarter() -> void:
	if last_chart_quarter < current_chart_quarter:
		last_chart_quarter = current_chart_quarter
		emit_signal("chart_quarter_hit", current_chart_quarter)
	else: return

func report_chart_measure() -> void:
	if last_chart_measure < current_chart_measure:
		last_chart_measure = current_chart_measure
		emit_signal("chart_measure_hit", current_chart_measure)
	else: return
