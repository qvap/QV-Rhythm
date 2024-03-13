extends CanvasLayer
class_name GameSpaceUI

# Интерфейс игрового поля

@onready var LABEL: Label = $MarginContainer/PanelContainer/MarginContainer/Label
@onready var BOT_PLAY_LABEL: Label = $MarginContainer2/PanelContainer/MarginContainer/Label
@onready var JUDGE_VERDICTS_CONTAINER: Control = $Container/JudgeVerdictsContainer
@onready var CONTAINER: Container = $Container

var ROADS : Node2D
var JUDGE_TEXT = preload("res://Scenes/UI/JudgeText.tscn")

func _ready() -> void:
	BOT_PLAY_LABEL.visible = Settings.BOT_PLAY
	ROADS = get_parent().get_node("Roads")
	Scoring.ui_node = self

func _process(_delta: float) -> void:
	if Scoring.current_score > int(LABEL.text):
		LABEL.text = str(int(LABEL.text) + 50)
	JUDGE_VERDICTS_CONTAINER.position.x = CONTAINER.size.x / 2 - JUDGE_VERDICTS_CONTAINER.size.x / 2
	JUDGE_VERDICTS_CONTAINER.position.y = ROADS.get_global_transform_with_canvas()[2].y + 35.0

func add_judge_verdict(verdict : String, index: int) -> void:
	var judge_text_init: JudgeText = JUDGE_TEXT.instantiate()
	judge_text_init.text = verdict
	judge_text_init.index = index
	
	if len(JUDGE_VERDICTS_CONTAINER.get_children()) > 0:
		for label in range(JUDGE_VERDICTS_CONTAINER.get_child_count()):
			if label == JUDGE_VERDICTS_CONTAINER.get_child_count() - 1:
				JUDGE_VERDICTS_CONTAINER.get_children()[label].slide()
				JUDGE_VERDICTS_CONTAINER.get_children()[label].position.y += 40.0
			else:
				JUDGE_VERDICTS_CONTAINER.get_children()[label].queue_free()
	JUDGE_VERDICTS_CONTAINER.add_child(judge_text_init)
