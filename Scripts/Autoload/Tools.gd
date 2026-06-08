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

func get_note_hit_time(note: Note) -> float:
	if note:
		return note.SPAWN_QUARTERS * Conductor.s_per_quarter
	else:
		return 0.0

func create_user_directory() -> void:
	# Пока что скрипт на создание папки запихну сюда
	var usermap_dir = DirAccess.open("user://Maps")
	var usersettings_dir = DirAccess.open("user://UserPreferences")
	var editor_dir = DirAccess.open("user://EditorSaves")
	if !usermap_dir:
		DirAccess.make_dir_absolute("user://Maps")
	if !usersettings_dir:
		DirAccess.make_dir_absolute("user://UserPreferences")
		DirAccess.make_dir_absolute("user://UserPreferences/PerMapSettings")
	if !editor_dir:
		DirAccess.make_dir_absolute("user://EditorSaves")
