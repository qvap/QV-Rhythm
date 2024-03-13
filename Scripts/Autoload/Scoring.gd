extends Node
class_name Score

# Скрипт для отслеживания попаданий по ноте в тайминг (и последующий счёт очков)

const JUDGE_OFFHITS := [
	"PERFECTION",
	"WONDERFUL",
	"FINE",
	"MISERABLE",
	"MISS"]
const JUDGE_OFFHITS_ARRAY := [2.8, 5.4, 7.7, 10]
const JUDGE_OFFHITS_SCORING := [1000, 700, 400, 100]
const EARLY_ZONE_MULTIPLIER := 0.8
const NOTE_ZONE := JUDGE_OFFHITS_ARRAY[len(JUDGE_OFFHITS_ARRAY) - 1] / 60.0 # значение будет плавать, если fps физики выставлен не 60, но и ладно
var current_score := 0 # Сохраняет в себя счёт за каждую игру
var ui_node : GameSpaceUI # При добавлении UI в сцену загружает сюда путь до неё

static func check_note_zone(note: Note, before_note: Note, after_note: Note) -> bool:
	var before_time: float
	var after_time: float
	var before_window: float
	var after_window: float
	var note_hit_time: float = Tools.get_note_hit_time(note)
	var before_note_hit_time: float = Tools.get_note_hit_time(before_note)
	var after_note_hit_time: float = Tools.get_note_hit_time(after_note)
	
	# Большое спасибо сурс-коду движка FNF Benjine за то, что я могу реализовать это
	# Учитывать только окно для обычных нот
	if note.NOTE_TYPE == Global.NOTE_TYPE.TAPNOTE:
		# Сначала устанавливает время до нот, которые идут до и после текущей
		if before_note:
			before_time = note_hit_time - before_note_hit_time
		else:
			before_time = 0.0
		if after_note:
			after_time = after_note_hit_time - note_hit_time
		else:
			after_time = 0.0
		
		# После чего настраивает размер окна, если ноты стоят ближе, чем NOTE_ZONE
		if before_note and before_note.NOTE_TYPE == Global.NOTE_TYPE.TAPNOTE and before_time <= NOTE_ZONE * EARLY_ZONE_MULTIPLIER:
			before_window = before_time
		else:
			before_window = NOTE_ZONE * EARLY_ZONE_MULTIPLIER
		
		if after_note and after_note.NOTE_TYPE == Global.NOTE_TYPE.TAPNOTE and after_time <= NOTE_ZONE:
			after_window = after_time
		else:
			after_window = NOTE_ZONE
	else:
		before_window = NOTE_ZONE * EARLY_ZONE_MULTIPLIER
		after_window = NOTE_ZONE
	
	if (note_hit_time - before_window < Conductor.chart_position - Conductor.note_speed) &&\
	(Conductor.chart_position - Conductor.note_speed < note_hit_time + after_window):
		return true
	return false

func judge(note: Note) -> void:
	var found : bool = false
	var offhit: float # погрешность удара в секундах
	offhit = abs(Conductor.chart_position - ((note.SPAWN_QUARTERS * Conductor.s_per_quarter) + Conductor.note_speed))
	for offhit_index in range(len(JUDGE_OFFHITS_ARRAY)):
		if offhit <= JUDGE_OFFHITS_ARRAY[offhit_index] / 60.0:
			found = true
			current_score += JUDGE_OFFHITS_SCORING[offhit_index]
			ui_node.add_judge_verdict(JUDGE_OFFHITS[offhit_index], offhit_index)
			break
	if !found:
		ui_node.add_judge_verdict(JUDGE_OFFHITS[4], 4)

func judge_miss(_note: Note) -> void:
	ui_node.add_judge_verdict(JUDGE_OFFHITS[4], 4)
