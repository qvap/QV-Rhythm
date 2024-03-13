extends Node2D
class_name Bars

# Визуальный элемент. На каждый бит спускается полоска

var BARSPRITE = preload("res://Scenes/Notes/BarSprite.tscn")
@onready var BARSPAWN = $BarSpawn
@onready var BARSHOLDER = $BarsHolder

func _ready() -> void:
	if Settings.ENABLE_BEAT_LINES:
		Conductor.connect("chart_beat_hit", chart_beat_hit)

func chart_beat_hit(_beat) -> void:
	var barsprite_init = BARSPRITE.instantiate()
	barsprite_init.position = BARSPAWN.position
	BARSHOLDER.add_child(barsprite_init)
