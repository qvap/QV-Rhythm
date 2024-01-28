extends Node

# Всё, что может использоваться между элементами игры, хранится здесь

const NOTE_SPEED_CONSTANT := 1.0

# Подгружаются значения из mapdata
@export var CURRENT_NOTE_SPEED := 1.0
@export var CURRENT_CHART_SIZE := 4

@export var CORRESPONDING_INPUTS : Dictionary = { #в зависимости от chart_size
	2: ["2K_Left", "2K_Right"],
	3: ["3K_Left", "3K_Center", "3K_Left"],
	4: ["4K_Left", "4K_Center_Left", "4K_Center_Right", "4K_Right"]
}
