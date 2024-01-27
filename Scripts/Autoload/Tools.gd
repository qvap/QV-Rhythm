extends Node

# Содержит в себе полезные функции, которые могут пригодиться в любой момент

func parse_json(json_path: String):
	if FileAccess.file_exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		var err = JSON.parse_string(file.get_as_text())
		file.close()
		if err is Dictionary:
			return err
		else:
			printerr("Неожиданный формат JSON! Путь: "+json_path)
	else:
		printerr("Файл JSON не найден! Путь: "+json_path)
