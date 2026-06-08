class_name ColorZone
extends Resource

# Типизированная модель зоны цвета чарта.
# Заменяет «магический массив» [QUARTER_TO_SPAWN, COLORWAY].
# Цвета хранятся html-строками — ровно как в JSON; разбор в Color
# делает потребитель (GameSpace/ChartEditor) при необходимости.

@export var quarter: float = 0.0
@export var colors: PackedStringArray = PackedStringArray()

func _init(p_quarter: float = 0.0, p_colors: PackedStringArray = PackedStringArray()) -> void:
	quarter = p_quarter
	colors = p_colors

static func from_array(a: Array) -> ColorZone:
	var zone := ColorZone.new(float(a[Global.COLORWAY_CHART_STRUCTURE.QUARTER_TO_SPAWN]))
	for color_code in a[Global.COLORWAY_CHART_STRUCTURE.COLORWAY]:
		zone.colors.push_back(color_code)
	return zone

func to_array() -> Array:
	var color_array: Array = []
	for color_code in colors:
		color_array.push_back(color_code)
	return [quarter, color_array]
