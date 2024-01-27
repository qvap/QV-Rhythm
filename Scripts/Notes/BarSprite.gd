extends Sprite2D
class_name BarSprite

# Анимации BarSprite и их удаление после достижения конечной точки

@onready var ANIMATION := $AnimationPlayer

func _process(_delta) -> void:
	if position.y == 0.0:
		ANIMATION.play("disappear")
