extends RefCounted
## 回憶相簿（親密度第二期）：資料在 game_bond.gd 的 bond.mem
##   自動拍：親密度升級、第一次三顆星、點亮單元（紀念品）、終焉之塔登頂；小屋每天可以合照 1 張
##   照片 = 當時的場景背景＋當時穿的裝扮（只存資料，打開相簿時重畫）。圖上不寫字，標題和日期寫在照片下面
##   open(host)：相簿（新的在前面），點一張放大
const UITheme := preload("res://data/ui/game_theme.gd")
const Game := preload("res://data/core/game.gd")
const SL := preload("res://data/ui/spirit_look.gd")
const SA := preload("res://data/house/souvenir_art.gd")

const PINK := Color("ff8fbf")


static func open(host: Node) -> Control:
	var g = Game.of(host)
	var mem: Array = g.bond_memories()
	var o := UITheme.modal(host, PINK, 800)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 12)
	var title := UITheme.title_label("回憶相簿　%d 張" % mem.size(), 26, PINK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	if mem.is_empty():
		var l := _label("尚無回憶", 16, UITheme.TEXT_DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(grid)
	for i in range(mem.size() - 1, -1, -1):
		var m: Dictionary = mem[i]
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.flat = true
		b.custom_minimum_size = Vector2(164, 124)
		var ph := Photo.new()
		ph.mem = m
		ph.position = Vector2.ZERO
		ph.size = Vector2(164, 124)
		b.add_child(ph)
		b.pressed.connect(func(): _big(layer, m))
		cell.add_child(b)
		cell.add_child(_label(String(m.get("title", "")), 14, UITheme.TEXT))
		cell.add_child(_label(String(m.get("day", "")), 12, UITheme.TEXT_DIM))
		grid.add_child(cell)
	var close := Button.new()
	close.text = "關閉"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 44)
	UITheme.accent_button(close, 16)
	close.pressed.connect(func(): layer.queue_free())
	col.add_child(close)
	g.sfx("open")
	return layer


## 放大一張
static func _big(host: Node, m: Dictionary) -> void:
	var o := UITheme.modal(host, PINK, 560)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 8)
	var ph := Photo.new()
	ph.mem = m
	ph.custom_minimum_size = Vector2(500, 375)
	ph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(ph)
	var t := _label(String(m.get("title", "")), 20, PINK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var d := _label(String(m.get("day", "")), 14, UITheme.TEXT_DIM)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(d)
	var close := Button.new()
	close.text = "關閉"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 44)
	UITheme.accent_button(close, 16)
	close.pressed.connect(func(): layer.queue_free())
	col.add_child(close)


static func _label(s: String, fs: int, c: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", UITheme.fs(fs))
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## 一張照片：白色相框＋場景＋光靈（開心的臉、當時的裝扮）
class Photo extends Control:
	const UITheme := preload("res://data/ui/game_theme.gd")
	const SL := preload("res://data/ui/spirit_look.gd")
	const SA := preload("res://data/house/souvenir_art.gd")
	var mem := {}

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true                # 畫不出照片外面
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var fr := maxf(4.0, w * 0.035)
		draw_rect(Rect2(Vector2.ZERO, size), Color("f4efe6"))
		var r := Rect2(Vector2(fr, fr), Vector2(w - fr * 2.0, h - fr * 2.0))
		var scene := String(mem.get("scene", "house"))
		var u := r.size.x / 100.0          # 以 100 寬為單位畫
		var o := r.position
		match scene:
			"levelup":
				draw_rect(r, Color(0.36, 0.16, 0.34))
				_glow(r.get_center(), r.size.y * 0.6, Color(1, 0.55, 0.75, 0.25))
				for p in [Vector2(14, 16), Vector2(84, 22), Vector2(20, 60), Vector2(88, 62), Vector2(70, 10)]:
					SL.heart(self, o + p * u, 3.2 * u, Color(1, 0.62, 0.8, 0.7))
			"map":
				draw_rect(r, Color(0.08, 0.1, 0.26))
				_stars(r, 9)
				draw_circle(o + Vector2(50, 118) * u, 62 * u, Color(0.2, 0.42, 0.3))
				draw_circle(o + Vector2(10, 92) * u, 26 * u, Color(0.16, 0.34, 0.26))
				_star5(o + Vector2(80, 18) * u, 5 * u, Color("ffcf5a"))
				_star5(o + Vector2(90, 26) * u, 3 * u, Color("ffcf5a"))
				_star5(o + Vector2(72, 26) * u, 3 * u, Color("ffcf5a"))
			"tower":
				draw_rect(r, Color(0.12, 0.08, 0.22))
				_stars(r, 8)
				draw_rect(Rect2(o + Vector2(66, 8) * u, Vector2(22, 70) * u), Color(0.36, 0.34, 0.48))
				draw_rect(Rect2(o + Vector2(62, 4) * u, Vector2(30, 6) * u), Color(0.46, 0.44, 0.6))
				for y in [16, 30, 44, 58]:
					draw_rect(Rect2(o + Vector2(73, y) * u, Vector2(8, 5) * u), Color("ffe7a3"))
				_star5(o + Vector2(77, 2) * u, 4 * u, Color("ffcf5a"))
			_:
				if scene.begins_with("unit:"):
					draw_rect(r, Color(0.1, 0.12, 0.26))
					_stars(r, 6)
					_glow(o + Vector2(72, 44) * u, 26 * u, Color(1, 0.9, 0.6, 0.18))
					SA.draw(self, scene.substr(5), o + Vector2(72, 66) * u, 34 * u, 0.0, 2)
				else:
					# 小屋：牆、地板、窗戶
					draw_rect(r, Color(0.27, 0.21, 0.42))
					draw_rect(Rect2(o + Vector2(0, 52) * u, Vector2(100, r.size.y / u - 52) * u), Color(0.42, 0.3, 0.24))
					draw_rect(Rect2(o + Vector2(64, 8) * u, Vector2(24, 20) * u), Color(0.12, 0.14, 0.32))
					draw_rect(Rect2(o + Vector2(64, 8) * u, Vector2(24, 20) * u), Color("c9a46e"), false, 1.5 * u)
					draw_circle(o + Vector2(80, 14) * u, 3 * u, Color("ffe7a3"))
		var c := o + Vector2(36, 44) * u if scene.begins_with("unit:") or scene == "tower" else r.get_center() + Vector2(0, 4 * u)
		SL.draw_mood(self, c, 13.0 * u, mem.get("eq", {}), 0.6, "happy")
		# 相框最後再畫一次：場景裡超出照片的部分（山丘、光暈）蓋掉
		var paper := Color("f4efe6")
		draw_rect(Rect2(0, 0, w, fr), paper)
		draw_rect(Rect2(0, h - fr, w, fr), paper)
		draw_rect(Rect2(0, 0, fr, h), paper)
		draw_rect(Rect2(w - fr, 0, fr, h), paper)

	func _glow(c: Vector2, rad: float, col: Color) -> void:
		for i in 4:
			draw_circle(c, rad * (1.0 - i * 0.2), Color(col.r, col.g, col.b, col.a * 0.5))

	func _stars(r: Rect2, n: int) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(String(mem.get("id", "")))
		for i in n:
			var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y * 0.5)
			draw_circle(p, 0.6 + rng.randf() * 1.2, Color(1, 1, 1, 0.5 + rng.randf() * 0.4))

	func _star5(c: Vector2, rad: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 10:
			var a := -PI / 2 + i * PI / 5
			pts.append(c + Vector2(cos(a), sin(a)) * (rad if i % 2 == 0 else rad * 0.45))
		draw_colored_polygon(pts, col)
