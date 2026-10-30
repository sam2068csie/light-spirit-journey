extends Control
## 全遊戲共用的回饋特效層（掛在遊戲管家的 CanvasLayer 上，蓋在所有畫面上面，不擋點擊）
##   good(pos)   答對：從點的位置炸出一圈金色星星＋擴散光環，畫面邊緣微微亮綠光
##   bad()       答錯：畫面輕輕左右晃一下，邊緣泛紅
##   big(pos)    過關、大獎：彩色紙片從上方灑下＋大光環
## 由 game.gd 的 sfx() 自動呼叫，關卡不用自己寫。
const UITheme := preload("game_theme.gd")

var parts: Array = []      # [{p, v, life, max, col, r, kind, rot, spin}]
var rings: Array = []      # [{p, t, max, col, r}]
var edge_col := Color(0, 0, 0, 0)
var edge_a := 0.0

const GOOD_COLS := [UITheme.GOLD, UITheme.GOLD_LIGHT, UITheme.GOOD, UITheme.CYAN_LIGHT]
const CONFETTI := [UITheme.GOLD, UITheme.CYAN, UITheme.PINK, UITheme.LIME, UITheme.VIOLET, UITheme.ORANGE]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(false)


func good(pos: Vector2) -> void:
	for i in 14:
		var a := randf() * TAU
		var sp := randf_range(160.0, 340.0)
		parts.append({"p": pos, "v": Vector2(cos(a), sin(a)) * sp, "life": 0.0, "max": randf_range(0.45, 0.7),
			"col": GOOD_COLS[i % GOOD_COLS.size()], "r": randf_range(4.0, 7.5), "kind": "star", "rot": randf() * TAU, "spin": randf_range(-6.0, 6.0)})
	rings.append({"p": pos, "t": 0.0, "max": 0.45, "col": UITheme.GOLD_LIGHT, "r": 70.0})
	_edge(UITheme.GOOD, 0.22)
	_go()


func bad() -> void:
	_edge(UITheme.BAD, 0.4)
	var sc := get_tree().current_scene as Control
	if sc != null:
		var tw := sc.create_tween()
		for k in [10.0, -8.0, 6.0, -3.0, 0.0]:
			tw.tween_property(sc, "position:x", k, 0.045)
	_go()


func big(pos: Vector2) -> void:
	var w := size.x
	for i in 46:
		parts.append({"p": Vector2(randf() * w, randf_range(-60.0, -10.0)), "v": Vector2(randf_range(-40.0, 40.0), randf_range(120.0, 260.0)),
			"life": 0.0, "max": randf_range(1.6, 2.4), "col": CONFETTI[i % CONFETTI.size()], "r": randf_range(4.0, 7.0),
			"kind": "paper", "rot": randf() * TAU, "spin": randf_range(-8.0, 8.0)})
	rings.append({"p": pos, "t": 0.0, "max": 0.7, "col": UITheme.GOLD, "r": 160.0})
	_edge(UITheme.GOLD, 0.3)
	_go()


func _edge(c: Color, a: float) -> void:
	edge_col = c
	edge_a = a


func _go() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	for p in parts:
		p.life += delta
		p.p += p.v * delta
		p.rot += p.spin * delta
		if p.kind == "star":
			p.v *= exp(-4.0 * delta)
			p.v.y += 260.0 * delta
		else:
			p.v.x += sin(p.life * 4.0 + p.rot) * 60.0 * delta     # 紙片左右飄
	parts = parts.filter(func(p): return p.life < p.max)
	for r in rings:
		r.t += delta
	rings = rings.filter(func(r): return r.t < r.max)
	edge_a = maxf(0.0, edge_a - delta * 0.9)
	if parts.is_empty() and rings.is_empty() and edge_a <= 0.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if edge_a > 0.0:
		_draw_edge()
	for r in rings:
		var k: float = r.t / r.max
		var e: float = 1.0 - pow(1.0 - k, 3.0)
		var c: Color = r.col
		c.a = (1.0 - k) * 0.7
		draw_arc(r.p, r.r * (0.25 + e), 0.0, TAU, 48, c, 4.0 * (1.0 - k) + 1.0, true)
	for p in parts:
		var k: float = p.life / p.max
		var c: Color = p.col
		c.a = 1.0 - k * k
		if p.kind == "star":
			_star(p.p, p.r * (1.0 - 0.5 * k), p.rot, c)
		else:
			var d: Vector2 = Vector2(cos(p.rot), sin(p.rot))
			var w: float = absf(sin(p.life * 7.0 + p.rot)) * p.r + 1.0    # 翻轉：寬度忽大忽小
			var n: Vector2 = Vector2(-d.y, d.x)
			draw_colored_polygon(PackedVector2Array([p.p + d * p.r + n * w * 0.5, p.p - d * p.r + n * w * 0.5,
				p.p - d * p.r - n * w * 0.5, p.p + d * p.r - n * w * 0.5]), c)


## 畫面四邊往內漸淡的一圈光
func _draw_edge() -> void:
	var c := edge_col
	var band := 70.0
	var steps := 7
	for i in steps:
		var a := edge_a * pow(1.0 - float(i) / steps, 2.0) * 0.55
		var col := Color(c.r, c.g, c.b, a)
		var o := band * i / steps
		var t := band / steps
		draw_rect(Rect2(0, o, size.x, t), col)
		draw_rect(Rect2(0, size.y - o - t, size.x, t), col)
		draw_rect(Rect2(o, 0, t, size.y), col)
		draw_rect(Rect2(size.x - o - t, 0, t, size.y), col)


func _star(c: Vector2, r: float, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := rot + i * PI / 4.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.38))
	draw_colored_polygon(pts, col)
