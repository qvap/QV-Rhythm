extends Node
class_name Score

# Скрипт для отслеживания попаданий по ноте в тайминг (и последующий счёт очков)

const NOTE_ZONE_UNITS := 10 # количество фреймов (при 60 fps физики), при которых засчитывается попадание
const JUDGE_OFFHITS := [
	"PERFECTION",
	"WONDERFUL",
	"FINE",
	"MISERABLE"]
const JUDGE_OFFHITS_ARRAY := [2, 3, 5, 10]
const NOTE_ZONE := NOTE_ZONE_UNITS / 60.0 # значение будет плавать, если fps физики выставлен не 60, но и ладно
var current_score := 0 # Сохраняет в себя счёт за каждую игру
var current_judge := "NONE"

func check_note_zone(note_hit_time: float) -> bool:
	if sign(note_hit_time - Conductor.chart_position) == 1:
		return note_hit_time - Conductor.chart_position < NOTE_ZONE
	return Conductor.chart_position - note_hit_time < NOTE_ZONE

func judge(note: Note) -> void:
	var offhit: float # погрешность удара в секундах
	var offhit_in_units : float # погрешность удара, но в юнитах
	var judge_offhit : float # подходящий тайминг
	offhit = (Conductor.chart_position - (note.SPAWN_TIME + Conductor.note_speed))
	offhit_in_units = abs(offhit * 60.0)
	for offhit_index in range(len(JUDGE_OFFHITS_ARRAY)):
		if offhit_in_units < JUDGE_OFFHITS_ARRAY[offhit_index]:
			current_judge = JUDGE_OFFHITS[offhit_index]
			break
