extends Control
## 觀念整理按鈕上的小書本圖示
## （從 level_base.gd 拆出來的；原本是裡面的 class ConceptIcon）
const UITheme := preload("res://data/ui/game_theme.gd")
const MathLabel := preload("res://data/ui/math_text.gd")
const Game := preload("res://data/core/game.gd")

var color := Color.WHITE
var t := 0.0

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var c := size / 2.0
	var lift := 2.0 * sin(t * 2.5)
	var l := PackedVector2Array([c + Vector2(-15, -9 + lift), c + Vector2(-1, -6 + lift), c + Vector2(-1, 12), c + Vector2(-15, 9)])
	var r := PackedVector2Array([c + Vector2(15, -9 - lift), c + Vector2(1, -6 - lift), c + Vector2(1, 12), c + Vector2(15, 9)])
	draw_colored_polygon(l, Color(color.r, color.g, color.b, 0.35))
	draw_colored_polygon(r, Color(color.r, color.g, color.b, 0.55))
	draw_polyline(PackedVector2Array([l[0], l[1], l[2], l[3], l[0]]), color, 1.5, true)
	draw_polyline(PackedVector2Array([r[0], r[1], r[2], r[3], r[0]]), color, 1.5, true)
	var sp := c + Vector2(10, -14) + Vector2(0, -3.0 * absf(sin(t * 1.7)))
	UITheme.dot(self, sp, 2.2, Color(1, 0.95, 0.6))
