extends Note
class_name HoldNote

# Нота, которую нужно удерживать. Как обычная нота, только отрисовывает дорожку

var LINE := preload("res://Scenes/Notes/HoldNoteLine.tscn")
@export var NOTE_LENGTH := 2 # в четвертях

func _ready() -> void:
	NOTE_TYPE = 1
	initialize_note()
	setup_line()

func setup_line() -> void:
	var line_init := LINE.instantiate()
	add_child(line_init)
	line_init.points[0] = Vector2(0.0, 0.0)
	line_init.points[1] = Vector2(0.0, 0.0 - (NOTE_SPEED *\
	(Conductor.s_per_quarter * NOTE_LENGTH)))
