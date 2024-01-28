extends Node2D
class_name Note

@onready var SKIN := $Skin
var SPAWN_POSITION : Vector2
var SPAWN_TIME := Conductor.chart_position
var ROAD : Node2D
var DISTANCE_TO_HIT : float
var NOTE_SPEED : float # скорость в пикселях до удара
var DIRECTION := Vector2(0.0, 0.0)

func _ready() -> void:
	set_physics_process(false)
	ROAD = get_parent().get_parent()
	SPAWN_POSITION = ROAD.NOTESPAWN_POSITION
	position = SPAWN_POSITION
	DISTANCE_TO_HIT = abs(SPAWN_POSITION.y)
	
	# Проще говоря, считает скорость, с которой должна двигаться нота на каждом фрейме _physics_process
	NOTE_SPEED = (DISTANCE_TO_HIT / (Global.CURRENT_NOTE_SPEED * Global.NOTE_SPEED_CONSTANT))/\
	Engine.physics_ticks_per_second
	
	set_physics_process(true)

func _physics_process(_delta) -> void:
	DIRECTION.y = NOTE_SPEED
	position.y += DIRECTION.y

