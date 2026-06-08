class_name ChartData
extends Resource

# Единая модель чарта: ноты + зоны цвета + (де)сериализация.
# Это единственная точка загрузки/сохранения mapchart*.json — раньше
# GameSpace и ChartEditor парсили и собирали структуры независимо.

var notes: Array[ChartNote] = []
var color_zones: Array[ColorZone] = []

static func from_dict(d: Dictionary) -> ChartData:
	var chart := ChartData.new()
	for note_array in d.get("Notes", []):
		chart.notes.push_back(ChartNote.from_array(note_array))
	for zone_array in d.get("ColorZones", []):
		chart.color_zones.push_back(ColorZone.from_array(zone_array))
	return chart

func to_dict() -> Dictionary:
	var notes_out: Array = []
	for note in notes:
		notes_out.push_back(note.to_array())
	var zones_out: Array = []
	for zone in color_zones:
		zones_out.push_back(zone.to_array())
	return {"Notes": notes_out, "ColorZones": zones_out}

static func load_from(path: String) -> ChartData:
	return from_dict(Tools.parse_json(path))

func save_to(path: String) -> void:
	Tools.save_json(path, to_dict())

# Заполняет next_road / next_quarter у голов слайдеров и тиков, находя
# следующую ноту с тем же slider_id (не контроль-ноту).
# Логика перенесена из бывшей GameSpace.iterate_for_slider.
func resolve_slider_links() -> void:
	for i in range(notes.size()):
		var note := notes[i]
		if not (note.type == Global.NOTE_TYPE.SLIDER or note.type == Global.NOTE_TYPE.SLIDERTICK):
			continue
		for j in range(i + 1, notes.size()):
			var other := notes[j]
			if other.slider_id == note.slider_id and not (other.type in Global.CONTROL_TYPE.values()):
				note.next_road = other.road
				note.next_quarter = other.quarter
				break
