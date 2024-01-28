extends Node
class_name Score

# Скрипт для отслеживания попаданий по ноте в тайминг (и последующий счёт очков)

const NOTE_ZONE_UNITS := 5 # количество фреймов (при 60 fps физики), при которых засчитывается попадание
const NOTE_ZONE := NOTE_ZONE_UNITS / 60.0 # значение будет плавать, если fps физики выставлен не 60, но и ладно

func check_note_zone(note_hit_time: float) -> bool:
	if sign(note_hit_time - Conductor.chart_position) == 1:
		return note_hit_time - Conductor.chart_position < NOTE_ZONE
	return Conductor.chart_position - note_hit_time < NOTE_ZONE
