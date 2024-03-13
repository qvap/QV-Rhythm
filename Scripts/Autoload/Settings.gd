extends Node

# Здесь хранятся настройки, которые может изменять игрок

#region Меню настроек
@export var FPS_CAP : int = 60
@export var PHYSICS_FPS : int = 120
enum GAMEPLAY_MODE {STANDART, SLIDERS}
enum EDITOR_INPUTS {LEFT_CLICK, RIGHT_CLICK}
@export var CHOSEN_GAMEPLAY_MODE: GAMEPLAY_MODE = GAMEPLAY_MODE.SLIDERS
@export var DEBUG_LINES: bool = false
@export var BOT_PLAY: bool = false
@export var ENABLE_SLIDER_HINTS: bool = true
@export var ENABLE_BEAT_LINES: bool = false

#region Редактор
@export var EDITOR_DOWNSCROLL: bool = false
#endregion

#endregion
