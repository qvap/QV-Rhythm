extends Node
class_name Score

# Скрипт для отслеживания попаданий по ноте в тайминг (и последующий счёт очков)

const NOTE_ZONE_UNITS := 12 # количество фреймов (при 60 fps физики), при которых засчитывается попадание
const JUDGE_OFFHITS := [
	"PERFECTION",
	"WONDERFUL",
	"FINE",
	"MISERABLE",
	"MISS"]
const JUDGE_OFFHITS_ARRAY := [4, 6, 8, 10]
const JUDGE_OFFHITS_SCORING := [1000, 700, 400, 100]
const NOTE_ZONE := NOTE_ZONE_UNITS / 60.0 # значение будет плавать, если fps физики выставлен не 60, но и ладно
var current_score := 0 # Сохраняет в себя счёт за каждую игру
var ui_node : GameSpaceUI # При добавлении UI в сцену загружает сюда путь до неё

func check_note_zone(note_hit_time: float) -> bool:
	if sign(note_hit_time - Conductor.chart_position) == 1:
		return note_hit_time - Conductor.chart_position < NOTE_ZONE
	return Conductor.chart_position - note_hit_time < NOTE_ZONE

func judge(note: Note) -> void:
	var found : bool = false
	var offhit: float # погрешность удара в секундах
	var offhit_in_units : float # погрешность удара, но в юнитах
	offhit = (Conductor.chart_position - (note.SPAWN_TIME + Conductor.note_speed))
	offhit_in_units = abs(offhit * 60.0)
	for offhit_index in range(len(JUDGE_OFFHITS_ARRAY)):
		if offhit_in_units < JUDGE_OFFHITS_ARRAY[offhit_index]:
			found = true
			current_score += JUDGE_OFFHITS_SCORING[offhit_index]
			ui_node.add_judge_verdict(JUDGE_OFFHITS[offhit_index], offhit_index)
			break
	if !found:
		ui_node.add_judge_verdict(JUDGE_OFFHITS[4], 4)
