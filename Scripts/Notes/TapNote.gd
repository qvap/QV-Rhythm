extends Node2D
class_name Note

# Базовая нота. Имеет скин, расчёт и движение (Можно использовать как основу для других нот)

@onready var SKIN := $Skin
var SPAWN_POSITION : Vector2
var SPAWN_TIME := Conductor.chart_position
var SPAWN_QUARTERS: int
var ROAD : Road
var DISTANCE_TO_HIT : float
var NOTE_SPEED : float # скорость в пикселях до удара
var NOTE_TYPE := Global.NOTE_TYPE.TAPNOTE
var DIRECTION := Vector2(0.0, 0.0)

func _ready() -> void:
	initialize_note()

func initialize_note() -> void:
	set_process(false)
	ROAD = get_parent().get_parent()
	SPAWN_POSITION = ROAD.NOTESPAWN_POSITION
	position = SPAWN_POSITION
	DISTANCE_TO_HIT = abs(SPAWN_POSITION.y)
	
	# Проще говоря, считает скорость, с которой должна двигаться нота
	NOTE_SPEED = (DISTANCE_TO_HIT / (Conductor.note_speed * Global.NOTE_SPEED_CONSTANT))
	
	set_process(true)

# Поменял с _physics_process на _process, чтобы убрать джиттер
# Да и на счёт ноты никак не влияет, так что win win
func _process(delta: float) -> void:
	process_note(delta)

func process_note(delta: float) -> void:
	DIRECTION.y = NOTE_SPEED * delta
	position.y += DIRECTION.y

func miss_note() -> void:
	SKIN.modulate.a = 0.5
