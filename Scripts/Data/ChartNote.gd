class_name ChartNote
extends Resource

# Типизированная модель одной ноты чарта.
# Заменяет «магические массивы» вида note[Global.NOTE_CHART_STRUCTURE.TYPE],
# которые раньше передавались между GameSpace, Road и ChartEditor.
#
# Используется как для нот, записываемых в JSON (TAP/HOLD/SLIDER...),
# так и для фантомных контроль-нот (CONTROL_TYPE.*), создаваемых в рантайме.

@export var type: int = Global.NOTE_TYPE.TAPNOTE
@export var quarter: float = 0.0
@export var road: int = 0

# Доп. поля. Какое из них значимо — зависит от type:
@export var duration: float = 0.0   # HOLDNOTE / HOLDCONTROL: длина в четвертях
@export var slider_id: int = -1     # SLIDER*: идентификатор связки слайдера

# Вычисляются при загрузке через ChartData.resolve_slider_links().
# В JSON не сериализуются.
var next_road: int = -1
var next_quarter: float = -1.0

func _init(p_type: int = Global.NOTE_TYPE.TAPNOTE, p_quarter: float = 0.0, p_road: int = 0) -> void:
	type = p_type
	quarter = p_quarter
	road = p_road

# Создаёт ноту из JSON-массива формата [TYPE, QUARTER_TO_SPAWN, ROAD, ADDITIONAL_INFO].
# Это единственное место (вместе с to_array), где код знает о порядке полей в файле.
static func from_array(a: Array) -> ChartNote:
	var note := ChartNote.new(
		int(a[Global.NOTE_CHART_STRUCTURE.TYPE]),
		float(a[Global.NOTE_CHART_STRUCTURE.QUARTER_TO_SPAWN]),
		int(a[Global.NOTE_CHART_STRUCTURE.ROAD])
	)
	if a.size() > Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO:
		var info: Array = a[Global.NOTE_CHART_STRUCTURE.ADDITIONAL_INFO]
		match note.type:
			Global.NOTE_TYPE.HOLDNOTE:
				if info.size() > Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION:
					note.duration = float(info[Global.HOLD_NOTE_ADDITIONAL_INFO.DURATION])
			Global.NOTE_TYPE.SLIDER, Global.NOTE_TYPE.SLIDERTICK, Global.NOTE_TYPE.SLIDEREND:
				if info.size() > Global.SLIDER_NOTE_ADDITIONAL_INFO.ID:
					note.slider_id = int(info[Global.SLIDER_NOTE_ADDITIONAL_INFO.ID])
	return note

# Сериализует ноту обратно в JSON-массив того же формата, что читает from_array.
# Для TAP массив имеет длину 3 (без ADDITIONAL_INFO), как и раньше.
func to_array() -> Array:
	match type:
		Global.NOTE_TYPE.HOLDNOTE:
			return [type, quarter, road, [duration]]
		Global.NOTE_TYPE.SLIDER, Global.NOTE_TYPE.SLIDERTICK, Global.NOTE_TYPE.SLIDEREND:
			return [type, quarter, road, [slider_id]]
		_:
			return [type, quarter, road]

# Удобный конструктор фантомной контроль-ноты (в JSON не пишется).
static func make_control(control_type: int, p_quarter: float, p_road: int) -> ChartNote:
	return ChartNote.new(control_type, p_quarter, p_road)
