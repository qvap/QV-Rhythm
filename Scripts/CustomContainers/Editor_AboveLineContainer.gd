@tool
extends Container
class_name EditorAboveLineContainer

# Контейнер, настраивающий положение содержимого на линии середины экрана

func above_line_container() -> void:
	for child in self.get_children():
		child.position.x = get_viewport_rect().size.x/2.0 - (child.size.x/2.0)
		child.position.y = get_viewport_rect().size.y/2.0 - child.size.y - (get_child_count() - 1 - child.get_index()) *\
		child.size.y

func _process(_delta):
	above_line_container()
