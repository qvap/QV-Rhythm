extends Node

# Всё, что может использоваться между элементами игры, хранится здесь

const NOTE_SPEED_CONSTANT := 1.0
const NOTE_CHART_STRUCTURE := {
	"type" : 0,
	"quarter_to_spawn" : 1,
	"road" : 2
}

# Подгружаются значения из mapdata
@export var CURRENT_CHART_SIZE := 4

const CORRESPONDING_INPUTS : Dictionary = { #в зависимости от chart_size
	2: ["2K_Left", "2K_Right"],
	3: ["3K_Left", "3K_Center", "3K_Left"],
	4: ["4K_Left", "4K_Center_Left", "4K_Center_Right", "4K_Right"]
}

const NOTE_TYPE : Dictionary = {
	0: "TapNote",
	1: "HoldNote",
	2: "SliderStart",
	3: "SliderHold",
	4: "SliderEnd"
}
