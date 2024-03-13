extends Node
class_name ConductorScript

# Отвечает за синхронизацию игры
# Принцип работы: за синхронизацию отвечают два параметра: song_position и chart_position
# Чтобы иметь возможность добавлять ноты до того, как заиграет музыка, существует
# функция play_song_with_offset(), которая запускает счёт, но не саму музыку,
# при этом до начала музыки chart_position высчитывается через delta, а после начала
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
@onready var AUDIO_MANAGER: AudioManager = $AudioManager
@onready var STARTTIMER := $StartTimer


# Сигналы для подключения
signal beat_hit(beat_count)
signal quarter_hit(quarter_count)
signal measure_hit(measure_count)
# Дупликаты для чарта
signal chart_beat_hit(beat_count)
signal chart_quarter_hit(quarter_count)
signal chart_measure_hit(measure_count)
# Для сцены карты
signal music_started()

# ПЕРЕМЕННЫЕ
var running := false
var playing := false
var song_occured := false

var s_per_beat: float
var s_per_quarter: float
var s_per_measure: float

var playback_time := 0.0

# Время, в которое произошла смена BPM
var bpm_change_time: float

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

# Интерактивная музыка
var interactive_music_array: Array = []
var queue_auto_advance: Array = []
var queue_on_beat: Array = []

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
	bpm_change_time = maxf(0.0, song_position)

# Загружает музыку по пути (is_custom_map_path просто сокращает передаваемый аргумент,
# ибо проверяет специально отведённую папку под кастомные карты)
func load_song(SONG_PATH: String, is_custom_map_path := false) -> void:
	if playing:
		stop_song()
	if !is_custom_map_path:
		AUDIO_MANAGER.MUSIC_STREAM = load(SONG_PATH)
		#MUSICSTREAMPLAYER.stream = load(SONG_PATH)
	else:
		AUDIO_MANAGER.MUSIC_STREAM = load("res://CustomMaps/"+SONG_PATH+"/music.mp3")
		#MUSICSTREAMPLAYER.stream = load("res://CustomMaps/"+SONG_PATH+"/music.mp3")
	song_length = AUDIO_MANAGER.MUSIC_STREAM.get_length()

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
	AUDIO_MANAGER.play_music()
	#MUSICSTREAMPLAYER.play()
	emit_signal("music_started")

#region Функции для редактора
# Запускает музыку для эдитора
func editor_play_song() -> void:
	playing = true
	AUDIO_MANAGER.play_music(start_offset)
	song_occured = true

func editor_stop_song() -> void:
	playing = false
	AUDIO_MANAGER.stop_music()
	reset_playback()

func editor_play_song_from_position(position: float) -> void:
	playing = true
	AUDIO_MANAGER.play_music(position + start_offset)
	update_playback_to_current_pos(true)
	song_occured = true
#endregion

#region Функции для интерактивной музыки
# Загружает в список всю музыку, переданную в списке
func load_interactive_music(music_paths: Array):
	for music_path in music_paths:
		if music_path is String:
			interactive_music_array.push_back(load(music_path))
		else:
			push_error("Неправильно указан путь при загрузке интерактивной музыки!")

func play_interactive_music(music_resource_id: int, new_bpm: float, loop: bool = false) -> void:
	if music_resource_id < len(interactive_music_array):
		queue_auto_advance.clear()
		playing = false
		song_occured = false
		reset_playback()
		change_bpm(new_bpm)
		AUDIO_MANAGER.MUSIC_STREAM = interactive_music_array[music_resource_id]
		AUDIO_MANAGER.play_music(0.0, "", false, loop)
		playing = true
		song_occured = true

# Меняет музыку в бит
func change_on_beat() -> void:
	if !queue_on_beat.is_empty():
		play_interactive_music(
			queue_on_beat[Global.AUTO_ADVANCE_ARRAY_STRUCTURE.NEXT_MUSIC_ID],
			queue_on_beat[Global.AUTO_ADVANCE_ARRAY_STRUCTURE.NEXT_BPM],
			queue_on_beat[Global.AUTO_ADVANCE_ARRAY_STRUCTURE.NEXT_LOOP])
		queue_on_beat.clear()

# Если есть queue_auto_advance, то в конце музыки переходит на него
func auto_advance() -> void:
	if !queue_auto_advance.is_empty() and AUDIO_MANAGER.current_music_node == null:
		play_interactive_music(
			queue_auto_advance[Global.AUTO_ADVANCE_ARRAY_STRUCTURE.NEXT_MUSIC_ID],
			queue_auto_advance[Global.AUTO_ADVANCE_ARRAY_STRUCTURE.NEXT_BPM],
			queue_auto_advance[Global.AUTO_ADVANCE_ARRAY_STRUCTURE.NEXT_LOOP])
		queue_auto_advance.clear()
#endregion

# Запускает отсчёт, но запускает музыку с задержкой
func play_song_with_offset() -> void:
	chart_position -= offset + start_offset
	playing = true
	STARTTIMER.wait_time = note_speed
	STARTTIMER.start()
	await STARTTIMER.timeout
	play_song()

# Просто останавливает Stream и отключает процесс счёта в _physics_process
func stop_song() -> void:
	AUDIO_MANAGER.stop_music()
	#MUSICSTREAMPLAYER.stop()
	playing = false

func play_hitsound() -> void:
	AUDIO_MANAGER.play_sfx(AudioManager.SFX.HITSOUND, -10.0)

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

func update_playback_to_current_pos(at_play: bool = false) -> void:
	# Считает позицию музыки через часы аудиосистемы
	#song_position = MUSICSTREAMPLAYER.get_playback_position() + AudioServer.get_time_since_last_mix()
	song_position = AUDIO_MANAGER.return_playback_position() + AudioServer.get_time_since_last_mix()
	song_position -= AudioServer.get_output_latency() + offset + start_offset
	
	chart_position = song_position + note_speed
	# Подгоняет значения, если мы начинаем музыку не с её начала
	if at_play:
		last_measure = floor(song_position/s_per_measure)
		last_beat = floor(song_position/s_per_beat)
		last_quarter = floor(song_position/s_per_quarter)
		last_chart_measure = floor(chart_position/s_per_measure)
		last_chart_beat = floor(chart_position/s_per_beat)
		last_chart_quarter = floor(chart_position/s_per_quarter)

# Функция, глобально меняющая BPM
func change_bpm(new_bpm: float) -> void:
	var _last_bpm: float = bpm
	bpm = new_bpm
	update()

func _physics_process(delta) -> void:
	# Не идёт дальше, если модуль не запущен или если не играет музыка
	if !running or !playing: return
	
	if song_occured:
		update_playback_to_current_pos()
		playback_time = AUDIO_MANAGER.return_playback_position()
	else:
		if chart_position <= -100.0:
			chart_position += 100.0
		chart_position += delta
	
	#playback_time = MUSICSTREAMPLAYER.get_playback_position()
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
	
	auto_advance()

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
