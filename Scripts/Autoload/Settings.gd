extends Node

# Здесь хранятся настройки, которые может изменять игрок

@export var FPS_CAP : int = 60
@export var PHYSICS_FPS : int = 120
enum GAMEPLAY_MODE {STANDART, SLIDERS}
enum EDITOR_INPUTS {LEFT_CLICK, RIGHT_CLICK}
@export var CHOSEN_GAMEPLAY_MODE: GAMEPLAY_MODE = GAMEPLAY_MODE.SLIDERS
@export var DEBUG_LINES: bool = false
