@tool
extends Control
class_name Control2D

# Центрирует внутри себя 2D-элементы

func control_2d() -> void:
	if get_child_count() != 0:
		for child in get_children():
			if child is Node2D:
				child.position = size / 2.0

func _process(_delta: float) -> void:
	control_2d()
