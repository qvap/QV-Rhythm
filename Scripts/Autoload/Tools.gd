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
func create_structured_note_array(with_additional_info: bool) -> Array:
	var structured_note: Array = []
	if with_additional_info:
		structured_note.resize(len(Global.NOTE_CHART_STRUCTURE.values()))
	else:
		structured_note.resize(len(Global.NOTE_CHART_STRUCTURE.values()) - 1)
	return structured_note

# Создаёт пустой список, соответствующий структуре colorway в Global
func create_structured_colorway_array() -> Array:
	var structured_colorway: Array = []
	structured_colorway.resize(len(Global.COLORWAY_CHART_STRUCTURE.values()))
	return structured_colorway

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
