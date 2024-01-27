extends Node
class_name ConductorScript

# Отвечает не только за синхронизацию игры и музыки, но и за саму музыку

# ЭКСПОРТЫ

# Впихну в начало кода все переменные для нот
const NOTE_FRAMES := 10
const NOTE_ZONE := NOTE_FRAMES / 60.0 # если 60 fps (но в _physics_process и так)

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
var song_position := 0.0

var chart_position := 0.0

var current_beat := -1
var last_beat := -1

var current_quarter := -1
var last_quarter := -1

var current_measure := -1
var last_measure := -1

var song_length: float
var note_speed := Global.NOTE_SPEED_CONSTANT

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

# Запускает музыку если есть Stream и запускает процесс счёта в _physics_process
func play_song() -> void:
	song_occured = true
	playing = true
	MUSICSTREAMPLAYER.play()

# Запускает отсчёт, но запускает музыку с задержкой
func play_song_with_offset() -> void:
	playing = true
	STARTTIMER.wait_time = note_speed
	STARTTIMER.start()
	await STARTTIMER.timeout
	play_song()

# Выставляет стандартные значения (a little stupid чтобы знать как это сократить)
func reset_playback() -> void:
	song_position = 0.0
	current_beat = -1
	last_beat = -1
	current_quarter = -1
	last_quarter = -1
	current_measure = -1
	last_measure = -1

# Просто останавливает Stream и отключает процесс счёта в _physics_process
func stop_song() -> void:
	MUSICSTREAMPLAYER.stop()
	MUSICSTREAMPLAYER.stream = null
	playing = false

# Облегчает загрузку музыки, если используется CustomMap JSON файл
func load_song_from_json(json_dictionary: Dictionary, folder_name: String) -> void:
	load_song(folder_name, true)
	bpm = json_dictionary["music_bpm"]
	measure = json_dictionary["music_measure"]
	start_offset = json_dictionary["music_offset"]
	note_speed = json_dictionary["note_speed"] * Global.NOTE_SPEED_CONSTANT
	update()

func _physics_process(_delta) -> void:
	# Не идёт дальше, если модуль не запущен
	if !running: return
	
	# Считает только если играет музыка
	if playing:
		if song_occured:
			song_position = MUSICSTREAMPLAYER.get_playback_position() + AudioServer.get_time_since_last_mix()
			song_position -= AudioServer.get_output_latency() + offset + start_offset
		else:
			song_position -= AudioServer.get_time_to_next_mix()
			song_position -= AudioServer.get_output_latency() + offset + start_offset
		chart_position = song_position + note_speed
		playback_time = MUSICSTREAMPLAYER.get_playback_position()
		
		current_measure = floor(song_position/s_per_measure)
		report_measure()
		
		current_beat = floor(chart_position/s_per_beat)
		report_beat()
		
		current_quarter = floor(song_position/s_per_quarter)
		report_quarter()
		
		if playback_time > song_length: stop_song()

func report_beat() -> void:
	if last_beat < current_beat:
		last_beat = current_beat
		emit_signal("beat_hit", current_beat)
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
