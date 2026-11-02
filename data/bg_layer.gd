extends Control
## 關卡背景層
## （從 level_base.gd 拆出來的；原本是裡面的 class _BgLayer）
const UITheme := preload("game_theme.gd")
const MathLabel := preload("math_text.gd")
const Game := preload("game.gd")

var painter: Callable

func _ready() -> void:
	show_behind_parent = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	painter.call(self)
