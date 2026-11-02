extends Control
## 關卡上方的旅程進度點
## （從 level_base.gd 拆出來的；原本是裡面的 class Pips）
const UITheme := preload("game_theme.gd")
const MathLabel := preload("math_text.gd")
const Game := preload("game.gd")

var total := 0
var current := 0
var breaks: Array = []

func setup(n: int, cur: int, br: Array) -> void:
	total = n
	current = cur
	breaks = br
	custom_minimum_size.x = n * 15.0 + br.size() * 10.0 + 6.0
	queue_redraw()

func _draw() -> void:
	var x := 9.0
	var cy := size.y / 2.0
	for i in total:
		if breaks.has(i):
			x += 10.0
		var c := Vector2(x, cy)
		if i < current:
			UITheme.dot(self, c, 4.0, UITheme.ACCENT)
		elif i == current:
			UITheme.dot(self, c, 9.0, Color(1, 1, 1, 0.15))
			UITheme.dot(self, c, 5.5, Color.WHITE)
		else:
			UITheme.dot(self, c, 3.5, Color(1, 1, 1, 0.2))
		x += 15.0
