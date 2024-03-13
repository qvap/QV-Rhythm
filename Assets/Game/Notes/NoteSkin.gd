extends Node2D
class_name NoteSkin

# Настраивает цвет ноты

@onready var BASE: Sprite2D = $Base
@onready var MIDDLE: Sprite2D = $Middle
@onready var TOP: Sprite2D = $Top

func set_color(color: Color) -> void:
	BASE.modulate = color
