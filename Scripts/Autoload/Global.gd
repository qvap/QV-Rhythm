extends Node

# Всё, что может использоваться между элементами игры, хранится здесь

#region Константы
const NOTE_SPEED_CONSTANT := 1.0

enum NOTE_TYPE {
	TAPNOTE,
	HOLDNOTE,
	SLIDER,
	SLIDERTICK,
	SLIDEREND
	}
enum CONTROL_TYPE {
	HOLDCONTROL = 9,
	HOLDCONTROLTICK = 10,
	HOLDCONTROLEND = 11,
	SLIDERCONTROL = 12,
	SLIDERCONTROLTICK = 13,
	SLIDERCONTROLEND = 14
}
enum NOTE_CHART_STRUCTURE {TYPE, QUARTER_TO_SPAWN, ROAD, ADDITIONAL_INFO}

enum HOLD_NOTE_ADDITIONAL_INFO {DURATION}
enum SLIDER_NOTE_ADDITIONAL_INFO {ID, NEXT_ROAD, NEXT_SPAWN_QUARTER}
#endregion

# Подгружаются значения из mapdata
@export var CURRENT_CHART_SIZE := 4

const CORRESPONDING_INPUTS : Dictionary = { #в зависимости от chart_size
	1: ["1K_Center"],
	2: ["2K_Left", "2K_Right"],
	3: ["3K_Left", "3K_Center", "3K_Right"],
	4: ["4K_Left", "4K_Center_Left", "4K_Center_Right", "4K_Right"],
	5: ["5K_Left", "5K_Center_Left", "5K_Center", "5K_Center_Right", "5K_Right"],
	6: ["6K_Far_Left", "6K_Left", "6K_Center_Left", "6K_Center_Right", "6K_Right", "6K_Far_Right"]
}
