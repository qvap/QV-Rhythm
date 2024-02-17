extends Node

# Содержит в себе полезные функции, которые могут пригодиться в любой момент

func parse_json(json_path: String) -> Dictionary:
	if FileAccess.file_exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		var err = JSON.parse_string(file.get_as_text())
		file.close()
		if err is Dictionary:
			return err
		else:
			printerr("Неожиданный формат JSON! Путь: "+json_path)
			return {}
	else:
		printerr("Файл JSON не найден! Путь: "+json_path)
		return {}

func save_json(json_path: String, content: Dictionary):
	var file = FileAccess.open(json_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(content))
	file.close()

# Создаёт пустой список, соответствующий структуре ноты в Global
func create_structured_note_array() -> Array:
	var structured_note: Array = []
	structured_note.resize(len(Global.NOTE_CHART_STRUCTURE.values()))
	return structured_note
