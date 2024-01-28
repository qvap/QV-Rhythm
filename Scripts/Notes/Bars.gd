extends Node2D
class_name Bars

# Визуальный элемент. На каждый бит спускается полоска

var BARSPRITE = preload("res://Scenes/Notes/BarSprite.tscn")
@onready var BARSPAWN = $BarSpawn
@onready var BARSHOLDER = $BarsHolder

func _ready() -> void:
	Conductor.connect("chart_beat_hit", chart_beat_hit)

func chart_beat_hit(_beat) -> void:
	var barsprite_init = BARSPRITE.instantiate()
	barsprite_init.position = BARSPAWN.position
	BARSHOLDER.add_child(barsprite_init)
	var tween = create_tween()
	tween.tween_property(barsprite_init, "position:y", 0.0, Conductor.note_speed)
	tween.parallel().tween_property(barsprite_init, "modulate:a", 1.0, Conductor.note_speed)
