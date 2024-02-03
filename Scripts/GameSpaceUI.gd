extends CanvasLayer
class_name GameSpaceUI

@onready var LABEL: Label = $MarginContainer/PanelContainer/MarginContainer/Label
@onready var LABEL2: Label = $MarginContainer2/PanelContainer/MarginContainer/Label



func _process(_delta: float) -> void:
	if Scoring.current_score > int(LABEL.text):
		LABEL.text = str(int(LABEL.text)+10)
	LABEL2.text = Scoring.current_judge
