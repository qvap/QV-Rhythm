extends Node
class_name AudioManager

# Отвечает за создание пула аудио и переключение музыки

@onready var MUSIC_POOL: Node = $MusicPool
@onready var SFX_POOL: Node = $SFXPool
var MUSIC_STREAM: AudioStream
var SFX_STREAM: AudioStream
enum AUDIO_NODE_TYPE {MUSIC, SFX}
enum SFX {HITSOUND}
@onready var SFX_LIST: Dictionary = {
	SFX.HITSOUND : load("res://Assets/SFX/Hitsound.wav")
}
@onready var SFX_MAX_INSTANCES: Dictionary = {
	SFX.HITSOUND : 2
}
var current_music_node: AudioStreamPlayer

# Учитывается кроссфейд если музыка уже играла
func play_music(start_offset: float = 0.0, music_path: String = "", do_crossfade: bool = true, loop: bool = false) -> void:
	var audio_node: AudioStreamPlayer
	audio_node = create_audio_node(AUDIO_NODE_TYPE.MUSIC)
	if music_path != "":
		MUSIC_STREAM = load(music_path)
	audio_node.stream = MUSIC_STREAM
	if current_music_node != null:
		audio_node.play(start_offset)
		if do_crossfade:
			crossfade(audio_node, current_music_node)
		current_music_node.queue_free()
		current_music_node = audio_node
	else:
		audio_node.play(start_offset)
		current_music_node = audio_node
	audio_node.finished.connect(release_music.bind(audio_node, loop))

# Удаляет ноду по запросу
func stop_music() -> void:
	if current_music_node != null:
		release_music(current_music_node, false)

func pause_music() -> void:
	current_music_node.stream_paused = true

func resume_music() -> void:
	current_music_node.stream_paused = false

# Удаляет или перезапускает ноду если музыка закончилась
func release_music(audio_node: AudioStreamPlayer, loop: bool) -> void:
	if loop:
		audio_node.play()
	else:
		audio_node.queue_free()
		current_music_node = null

func play_sfx(sfx_type: SFX, volume: float = 0.0) -> void:
	var counter: int = 0
	for instance in SFX_POOL.get_children():
		var meta: SFX = instance.get_meta("type")
		if sfx_type == meta:
			counter += 1
	if counter > SFX_MAX_INSTANCES[sfx_type]:
		for instance in SFX_POOL.get_children():
			var meta: SFX = instance.get_meta("type")
			if sfx_type == meta:
				instance.queue_free()
				counter -= 1
				if counter <= SFX_MAX_INSTANCES[sfx_type]:
					break
	var audio_node = create_audio_node(AUDIO_NODE_TYPE.SFX)
	audio_node.set_meta("type", sfx_type)
	audio_node.stream = SFX_LIST[sfx_type]
	audio_node.volume_db = volume
	audio_node.play()
	audio_node.finished.connect(release_sfx.bind(audio_node))

# Освобождает ноду со спецэффектом после того, как она проиграется
func release_sfx(audio_node: AudioStreamPlayer) -> void:
	audio_node.queue_free()

# Плавно убавляет прошлый трек и плавно прибавляет новый
func crossfade(new: AudioStreamPlayer, old: AudioStreamPlayer, time: float = 0.25) -> void:
	var tween = create_tween()
	tween.tween_property(old, "volume_db", -50.0, time)
	tween.parallel().tween_property(new, "volume_db", 0.0, time)
	await tween.finished

# Создаёт ноду, которая пойдёт в соответствующий пул
func create_audio_node(type: AUDIO_NODE_TYPE) -> AudioStreamPlayer:
	var audio_node: AudioStreamPlayer
	match type:
		AUDIO_NODE_TYPE.MUSIC:
			audio_node = AudioStreamPlayer.new()
			MUSIC_POOL.add_child(audio_node)
			audio_node.bus = "Music"
		AUDIO_NODE_TYPE.SFX:
			audio_node = AudioStreamPlayer.new()
			SFX_POOL.add_child(audio_node)
			audio_node.bus = "SFX"
	return audio_node

# Возвращает позицию трека
func return_playback_position() -> float:
	if current_music_node != null:
		return current_music_node.get_playback_position()
	else:
		return -100.0
