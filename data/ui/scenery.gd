extends RefCounted
## 多項式（根之洞窟）、三角函數（月輪島與正弦海岸）每一關自己的背景：天空漸層＋遠景剪影＋會動的粒子
## 和指對數各關的背景一樣畫在題目的後面：顏色有主題感，但都很淡，不搶題目和圖形。
## 全部用時間 t 直接算位置（不存粒子狀態），每幀重畫也很便宜。
##   多項式：mine 係數礦燈、wheel 綜合除法水車、echo 回音石廊、mold 根之鑄模、
##           lake 拋物鏡湖、wick 極值燈芯、crystal 對稱水晶、river 符號地下河
##   直線與圓：lakeside 圓規湖岸（C1 坐標燈標）
##   三角函數：ferry 弧之渡口、lagoon 扇形潟湖、steps 浪之階梯、tide 潮汐調音盤、
##             compass 和角羅盤、pool 倍角鏡池、lighthouse 疊合燈塔
const UITheme := preload("res://data/ui/game_theme.gd")
const Ambient := preload("res://data/ui/ambient.gd")


static func paint(ci: CanvasItem, theme: String, sz: Vector2, t: float) -> void:
	if sz.x < 100.0 or sz.y < 100.0:
		return
	match theme:
		"mine":
			_mine(ci, sz, t)
		"wheel":
			_wheel(ci, sz, t)
		"echo":
			_echo(ci, sz, t)
		"mold":
			_mold(ci, sz, t)
		"lake":
			_lake(ci, sz, t)
		"wick":
			_wick(ci, sz, t)
		"crystal":
			_crystal(ci, sz, t)
		"river":
			_river(ci, sz, t)
		"ferry":
			_ferry(ci, sz, t)
		"lagoon":
			_lagoon(ci, sz, t)
		"steps":
			_steps(ci, sz, t)
		"tide":
			_tide(ci, sz, t)
		"compass":
			_compass(ci, sz, t)
		"pool":
			_pool(ci, sz, t)
		"lighthouse":
			_lighthouse(ci, sz, t)
		"lakeside":
			_lakeside(ci, sz, t)


static func h(i: int, k: float = 0.0) -> float:
	return Ambient.h(i, k)


# ---------------- 共用的小畫法 ----------------

## 上下兩色的漸層
static func _grad(ci: CanvasItem, sz: Vector2, top: Color, bot: Color) -> void:
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(sz.x, 0), Vector2(sz.x, sz.y), Vector2(0, sz.y)]),
		PackedColorArray([top, top, bot, bot]))


## 從 y0 往下越來越亮的光（爐火、湖面…）
static func _glow(ci: CanvasItem, sz: Vector2, y0: float, c: Color, a: float) -> void:
	ci.draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(sz.x, y0), Vector2(sz.x, sz.y), Vector2(0, sz.y)]),
		PackedColorArray([Color(c.r, c.g, c.b, 0.0), Color(c.r, c.g, c.b, 0.0), Color(c.r, c.g, c.b, a), Color(c.r, c.g, c.b, a)]))


## 上方垂下來的鐘乳石
static func _stalactites(ci: CanvasItem, sz: Vector2, n: int, c: Color, len0: float, len1: float, seed_k: int) -> void:
	for i in n:
		var x := (i + 0.5) * sz.x / n + 14.0 * (h(i, seed_k) - 0.5)
		var hw := 7.0 + 8.0 * h(i, seed_k + 1)
		var ln := len0 + (len1 - len0) * h(i, seed_k + 2)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - hw, 0), Vector2(x + hw, 0), Vector2(x + 1.5, ln)]), c)


## 一層起伏的剪影（山、岩石、沙洲）：底部填滿
static func _ridge(ci: CanvasItem, sz: Vector2, y0: float, amp: float, freq: float, ph: float, c: Color) -> void:
	var pts := PackedVector2Array()
	var x := 0.0
	while x <= sz.x + 20.0:
		pts.append(Vector2(x, y0 - amp * (0.55 * sin(x * freq + ph) + 0.45 * sin(x * freq * 2.3 + ph * 1.7))))
		x += 20.0
	pts.append(Vector2(sz.x, sz.y))
	pts.append(Vector2(0, sz.y))
	ci.draw_colored_polygon(pts, c)


## 一閃一閃的星星
static func _stars(ci: CanvasItem, sz: Vector2, t: float, n: int, ymax: float, c: Color, seed_k: int) -> void:
	for i in n:
		var p := Vector2(h(i, seed_k) * sz.x, h(i, seed_k + 1) * sz.y * ymax)
		var a := 0.18 + 0.22 * sin(t * (0.8 + h(i, seed_k + 2)) + i * 1.9)
		UITheme.dot(ci, p, 0.9 + 1.3 * h(i, seed_k + 3), Color(c.r, c.g, c.b, maxf(0.0, a)))


## 四芒的閃光
static func _glint(ci: CanvasItem, p: Vector2, r: float, c: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.22, -r * 0.22), p + Vector2(r, 0),
		p + Vector2(r * 0.22, r * 0.22), p + Vector2(0, r), p + Vector2(-r * 0.22, r * 0.22), p + Vector2(-r, 0), p + Vector2(-r * 0.22, -r * 0.22)]), c)
	UITheme.dot(ci, p, r * 0.9, Color(c.r, c.g, c.b, c.a * 0.25))


## 一條橫向的波浪線
static func _wave_line(ci: CanvasItem, sz: Vector2, y0: float, amp: float, k: float, sp: float, ph: float, c: Color, w: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var x := 0.0
	while x <= sz.x + 12.0:
		pts.append(Vector2(x, y0 + amp * sin(x * k - sp + ph)))
		x += 12.0
	ci.draw_polyline(pts, c, w, true)
	return pts


## 月亮（三角函數各關的月輪）
static func _moon(ci: CanvasItem, c: Vector2, r: float, a: float) -> void:
	UITheme.dot(ci, c, r * 2.8, Color(0.85, 0.9, 1.0, 0.035 * a))
	UITheme.dot(ci, c, r * 1.6, Color(0.85, 0.9, 1.0, 0.07 * a))
	UITheme.dot(ci, c, r, Color(0.93, 0.95, 1.0, 0.16 * a))


# ================= 多項式：根之洞窟 =================

## P1 係數礦燈：礦坑的木架、搖晃的礦燈、飄落的礦塵
static func _mine(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	_grad(ci, sz, Color("2c1d18"), Color("120c0b"))
	_stalactites(ci, sz, 12, Color(0.10, 0.06, 0.05, 0.75), 14.0, 34.0, 3)
	# 礦坑的木架：兩側柱子＋上方橫樑
	var wood := Color(0.42, 0.27, 0.16, 0.42)
	for x: float in [26.0, w - 40.0]:
		ci.draw_rect(Rect2(x, 46.0, 14.0, hh - 46.0), wood)
		ci.draw_line(Vector2(x + 3, 60), Vector2(x + 3, hh), Color(0.6, 0.42, 0.25, 0.18), 1.5)
	ci.draw_rect(Rect2(16.0, 38.0, w - 32.0, 12.0), Color(0.42, 0.27, 0.16, 0.36))
	# 掛在橫樑下的礦燈（左右輕輕晃）
	for i in 4:
		var ax: float = [62.0, 104.0, w - 104.0, w - 62.0][i]
		var sw := 0.12 * sin(t * (0.9 + 0.15 * i) + i * 1.7)
		var ln := 26.0 + 10.0 * h(i, 7)
		var lp := Vector2(ax, 50.0) + Vector2(sin(sw), cos(sw)) * ln
		ci.draw_line(Vector2(ax, 50.0), lp, Color(0.6, 0.45, 0.3, 0.35), 1.2)
		var fl := 0.85 + 0.15 * sin(t * 7.0 + i * 2.3)
		UITheme.dot(ci, lp + Vector2(0, 6), 46.0, Color(1.0, 0.72, 0.35, 0.045 * fl))
		UITheme.dot(ci, lp + Vector2(0, 6), 18.0, Color(1.0, 0.75, 0.4, 0.13 * fl))
		ci.draw_rect(Rect2(lp + Vector2(-5, 0), Vector2(10, 12)), Color(0.55, 0.38, 0.22, 0.75))
		UITheme.dot(ci, lp + Vector2(0, 6), 3.2, Color(1.0, 0.88, 0.55, 0.9 * fl))
	# 地上的礦石堆
	_ridge(ci, sz, hh - 10.0, 9.0, 0.03, 0.4, Color(0.09, 0.06, 0.05, 0.85))
	for i in 7:
		var p := Vector2(h(i, 11) * w, hh - 8.0 - 6.0 * h(i, 12))
		UITheme.dot(ci, p, 2.0, Color(1.0, 0.8, 0.4, 0.25 + 0.2 * sin(t * 1.5 + i)))
	# 從頂上飄落的礦塵
	for i in 30:
		var v := 0.018 + 0.02 * h(i, 13)
		var y := fposmod(t * v + h(i, 14), 1.0) * hh
		var x := h(i, 15) * w + 8.0 * sin(t * 0.8 + i)
		UITheme.dot(ci, Vector2(x, y), 1.0 + h(i, 16) * 1.3, Color(1.0, 0.82, 0.55, 0.30 * (1.0 - y / hh) + 0.06))


## P2 綜合除法水車：左下角慢慢轉的水車、右邊的瀑布、底下的水道
static func _wheel(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	_grad(ci, sz, Color("10243f"), Color("071425"))
	_stalactites(ci, sz, 10, Color(0.04, 0.09, 0.18, 0.7), 12.0, 30.0, 21)
	# 水車
	var c := Vector2(70.0, hh - 30.0)
	var r := 120.0
	var col := Color(0.55, 0.8, 1.0, 0.16)
	ci.draw_arc(c, r, 0.0, TAU, 64, col, 4.0, true)
	ci.draw_arc(c, r * 0.72, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.10), 2.0, true)
	var rot := -t * 0.35
	for k in 10:
		var a := rot + k * TAU / 10.0
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(c, c + d * r, Color(col.r, col.g, col.b, 0.10), 2.0)
		var p0 := c + d * r
		ci.draw_line(p0, p0 + d * 18.0 + Vector2(-d.y, d.x) * 10.0, Color(col.r, col.g, col.b, 0.22), 5.0)
	UITheme.dot(ci, c, 10.0, Color(0.55, 0.8, 1.0, 0.25))
	# 右邊的瀑布
	var fx := w - 46.0
	ci.draw_rect(Rect2(fx, 0, 30.0, hh), Color(0.45, 0.75, 1.0, 0.06))
	var falls := PackedVector2Array()
	for k in 26:
		var y := fposmod(t * 190.0 + k * 53.0, hh + 40.0) - 20.0
		var x := fx + 4.0 + 22.0 * h(k, 22)
		falls.append_array([Vector2(x, y), Vector2(x, y + 18.0 + 10.0 * h(k, 23))])
	ci.draw_multiline(falls, Color(0.7, 0.9, 1.0, 0.22), 2.0)
	for i in 8:
		var ph := fposmod(t * 0.9 + h(i, 24), 1.0)
		UITheme.dot(ci, Vector2(fx + 15.0 + (h(i, 25) - 0.5) * 60.0 * ph, hh - 18.0 - 30.0 * ph), 6.0 * (1.0 - ph) + 1.0, Color(0.8, 0.95, 1.0, 0.18 * (1.0 - ph)))
	# 底下的水道
	_glow(ci, sz, hh * 0.78, Color(0.3, 0.65, 1.0), 0.14)
	for k in 3:
		_wave_line(ci, sz, hh - 16.0 - 12.0 * k, 3.0, 0.025, t * (1.2 + 0.3 * k), k * 1.3, Color(0.6, 0.85, 1.0, 0.12), 1.4)
	# 濺起的水滴
	for i in 16:
		var v := 0.05 + 0.04 * h(i, 26)
		var y := fposmod(t * v + h(i, 27), 1.0)
		UITheme.dot(ci, Vector2(h(i, 28) * w, y * hh), 1.6, Color(0.7, 0.9, 1.0, 0.25 * (1.0 - y)))


## P3 回音石廊：一排往後退的石拱、擴散的回音環、紫色的光點
static func _echo(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	_grad(ci, sz, Color("221a3e"), Color("0e0b1c"))
	# 往後退的石拱（遠的小、淡）
	for k in 4:
		var s := 1.0 - 0.18 * k
		var cx := w * 0.5
		var aw := w * 0.46 * s
		var top := hh * (0.16 + 0.07 * k)
		var base := hh * (0.98 - 0.04 * k)
		var c := Color(0.62, 0.5, 0.9, 0.10 - 0.018 * k)
		for side: float in [-1.0, 1.0]:
			ci.draw_line(Vector2(cx + side * aw, base), Vector2(cx + side * aw, top + aw * 0.35), c, 6.0 * s)
		ci.draw_arc(Vector2(cx, top + aw * 0.35), aw, PI, TAU, 40, c, 6.0 * s, true)
	# 兩側的岩壁
	for side: int in [0, 1]:
		var pts := PackedVector2Array()
		var xe := 0.0 if side == 0 else w
		var dir := 1.0 if side == 0 else -1.0
		pts.append(Vector2(xe, 0))
		for i in 13:
			var y := hh * i / 12.0
			pts.append(Vector2(xe + dir * (18.0 + 7.0 * sin(i * 1.9 + side * 2.0) + 4.0 * sin(i * 0.7)), y))
		pts.append(Vector2(xe, hh))
		ci.draw_colored_polygon(pts, Color(0.17, 0.13, 0.30, 0.95))
	_stalactites(ci, sz, 9, Color(0.17, 0.13, 0.30, 0.95), 14.0, 30.0, 31)
	# 回音環：從右邊往左擴散
	for k in 4:
		var ph := fposmod(t * 0.22 + k / 4.0, 1.0)
		ci.draw_arc(Vector2(w - 30.0, hh * 0.52), 40.0 + ph * w * 0.6, PI * 0.72, PI * 1.28, 32,
			Color(0.8, 0.66, 1.0, 0.13 * (1.0 - ph)), 2.0, true)
	for i in 18:
		var p := Vector2((h(i, 33) + 0.02 * sin(t * 0.4 + i)) * w, (h(i, 34) + 0.03 * sin(t * 0.3 + i)) * hh)
		var a := 0.22 * (0.5 + 0.5 * sin(t * 1.3 + i * 2.1))
		UITheme.dot(ci, p, 5.0, Color(0.78, 0.62, 1.0, a * 0.25))
		UITheme.dot(ci, p, 1.6, Color(0.88, 0.78, 1.0, a))


## P4 根之鑄模：熔爐的紅光、兩側的坩堝與熔液、往上飄的火星
static func _mold(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	_grad(ci, sz, Color("3a170f"), Color("170807"))
	_glow(ci, sz, hh * 0.6, Color(1.0, 0.42, 0.12), 0.24 + 0.05 * sin(t * 1.7))
	# 背後的煙囪與鍋爐剪影
	ci.draw_rect(Rect2(w * 0.12, 0, 46.0, hh * 0.55), Color(0.08, 0.03, 0.02, 0.45))
	ci.draw_rect(Rect2(w * 0.82, 0, 40.0, hh * 0.48), Color(0.08, 0.03, 0.02, 0.45))
	# 兩個下角的坩堝（口上發亮）
	for side: int in [0, 1]:
		var cx := 64.0 if side == 0 else w - 64.0
		var top := hh - 64.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 46, top), Vector2(cx + 46, top), Vector2(cx + 34, hh), Vector2(cx - 34, hh)]), Color(0.12, 0.05, 0.03, 0.9))
		var gl := 0.6 + 0.3 * sin(t * 2.2 + side)
		ci.draw_line(Vector2(cx - 44, top + 2), Vector2(cx + 44, top + 2), Color(1.0, 0.6, 0.2, 0.7 * gl), 4.0)
		UITheme.dot(ci, Vector2(cx, top), 46.0, Color(1.0, 0.5, 0.15, 0.10 * gl))
	# 從上面滴下來的熔液
	var lines := PackedVector2Array()
	for side: float in [22.0, w - 22.0]:
		for k in 6:
			var y := fposmod(t * 70.0 + k * 97.0 + side, hh + 30.0) - 15.0
			var x: float = side + 6.0 * sin(k * 2.1)
			lines.append_array([Vector2(x, y), Vector2(x, y + 10.0)])
	ci.draw_multiline(lines, Color(1.0, 0.55, 0.2, 0.45), 3.0)
	# 火星
	for i in 30:
		var v := 0.05 * (0.6 + 0.8 * h(i, 41))
		var y := 1.05 - fposmod(t * v + h(i, 42), 1.15)
		var x := h(i, 43) + 0.02 * sin(t * (1.0 + h(i, 44)) + i)
		var life := clampf(y / 0.9, 0.0, 1.0)
		var a := life * (0.55 + 0.35 * sin(t * 6.0 + i))
		var p := Vector2(x * w, y * hh)
		UITheme.dot(ci, p, 5.0, Color(1.0, 0.55, 0.2, a * 0.18))
		UITheme.dot(ci, p, 1.8, Color(1.0, 0.7, 0.3, a))


## P5 拋物鏡湖：地底的湖、洞頂垂下來發光的螢火蟲絲、湖面的倒影和水紋
static func _lake(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	var wl := hh * 0.8
	_grad(ci, sz, Color("0c2a3c"), Color("061722"))
	_stalactites(ci, sz, 13, Color(0.03, 0.10, 0.14, 0.85), 16.0, 42.0, 51)
	# 洞頂垂下來的發光絲（像螢火蟲洞）
	for i in 16:
		var x := (i + 0.5) * w / 16.0 + 10.0 * (h(i, 52) - 0.5)
		var ln := 24.0 + 70.0 * h(i, 53)
		var sw := 2.0 * sin(t * 0.7 + i)
		ci.draw_line(Vector2(x, 0), Vector2(x + sw, ln), Color(0.6, 0.95, 1.0, 0.08), 1.0)
		var tw := 0.6 + 0.4 * sin(t * (1.1 + h(i, 54)) + i * 2.0)
		UITheme.dot(ci, Vector2(x + sw, ln), 7.0, Color(0.45, 1.0, 0.95, 0.10 * tw))
		UITheme.dot(ci, Vector2(x + sw, ln), 1.8, Color(0.7, 1.0, 0.98, 0.75 * tw))
	# 湖面
	ci.draw_rect(Rect2(0, wl, w, hh - wl), Color(0.04, 0.16, 0.22, 0.85))
	ci.draw_line(Vector2(0, wl), Vector2(w, wl), Color(0.55, 0.95, 1.0, 0.30), 1.5)
	# 倒影：發光絲的光點在水裡晃
	for i in 16:
		var x := (i + 0.5) * w / 16.0 + 10.0 * (h(i, 52) - 0.5) + 3.0 * sin(t * 1.3 + i)
		var y := wl + 10.0 + 22.0 * h(i, 53)
		UITheme.dot(ci, Vector2(x, y), 1.6, Color(0.6, 1.0, 0.98, 0.22 + 0.12 * sin(t * 2.0 + i)))
	for j in 6:
		var yy := wl + 8.0 + j * 7.0
		var off := fmod(t * (16.0 + j * 4.0) + j * 97.0, 150.0)
		var xx := -150.0 + off
		while xx < w:
			ci.draw_line(Vector2(xx, yy), Vector2(xx + 30.0, yy), Color(0.7, 0.95, 1.0, 0.11 - j * 0.012), 1.2)
			xx += 150.0
	# 偶爾滴進湖裡的水滴漣漪
	for k in 3:
		var per := 3.4 + k
		var ph := fposmod(t + k * 1.1, per) / per
		var cx := (0.2 + 0.3 * k) * w
		ci.draw_arc(Vector2(cx, wl + 18.0), 4.0 + ph * 60.0, 0.0, TAU, 32, Color(0.7, 1.0, 1.0, 0.18 * (1.0 - ph)), 1.2, true)


## P6 極值燈芯：底下一排燭台、搖曳的火光、往上飄的煙和火花
static func _wick(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	_grad(ci, sz, Color("1e1632"), Color("1c1108"))
	_glow(ci, sz, hh * 0.55, Color(1.0, 0.7, 0.3), 0.12)
	# 燭台架
	ci.draw_rect(Rect2(0, hh - 14.0, w, 14.0), Color(0.25, 0.16, 0.08, 0.8))
	var n := 9
	for i in n:
		var x := (i + 0.5) * w / n
		var ch := 26.0 + 34.0 * h(i, 61)
		var top := hh - 14.0 - ch
		ci.draw_rect(Rect2(x - 7.0, top, 14.0, ch), Color(0.92, 0.86, 0.72, 0.22))
		ci.draw_line(Vector2(x, top), Vector2(x, top - 5.0), Color(0.2, 0.15, 0.1, 0.8), 1.5)
		var fl := 0.8 + 0.2 * sin(t * (8.0 + h(i, 62) * 4.0) + i * 3.0)
		var sway := 1.5 * sin(t * 3.0 + i)
		var fp := Vector2(x + sway, top - 11.0)
		UITheme.dot(ci, fp, 34.0 * fl, Color(1.0, 0.72, 0.3, 0.05))
		UITheme.dot(ci, fp, 12.0 * fl, Color(1.0, 0.75, 0.35, 0.14))
		ci.draw_colored_polygon(PackedVector2Array([fp + Vector2(0, -9.0 * fl), fp + Vector2(4.0, 2.0), fp + Vector2(0, 6.0), fp + Vector2(-4.0, 2.0)]), Color(1.0, 0.8, 0.4, 0.85))
		UITheme.dot(ci, fp + Vector2(0, 2), 1.8, Color(1, 1, 0.9, 0.9))
		# 煙
		for k in 3:
			var ph := fposmod(t * 0.25 + h(i, 63) + k / 3.0, 1.0)
			var sp := fp + Vector2(6.0 * sin(t * 0.8 + i + k * 2.0) * ph, -20.0 - ph * 120.0)
			UITheme.dot(ci, sp, 4.0 + 8.0 * ph, Color(0.8, 0.75, 0.9, 0.05 * (1.0 - ph)))
	# 飄起來的火花
	for i in 18:
		var v := 0.035 * (0.6 + 0.8 * h(i, 64))
		var y := 0.95 - fposmod(t * v + h(i, 65), 1.0)
		var x := h(i, 66) + 0.02 * sin(t * 1.2 + i)
		var a := clampf(y, 0.0, 1.0) * (0.5 + 0.4 * sin(t * 5.0 + i))
		UITheme.dot(ci, Vector2(x * w, y * hh), 1.5, Color(1.0, 0.82, 0.45, a * 0.7))


## P7 對稱水晶：兩邊的大水晶簇、頂上的小水晶、四芒閃光、斜斜的折射光
static func _crystal(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	_grad(ci, sz, Color("281040"), Color("100720"))
	# 斜斜的折射光帶
	for k in 3:
		var x0 := w * (0.2 + 0.3 * k) + 30.0 * sin(t * 0.2 + k)
		var a := 0.035 + 0.015 * sin(t * 0.6 + k * 2.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 50, 0), Vector2(x0 - 90, hh), Vector2(x0 - 160, hh)]),
			Color(0.85, 0.6, 1.0, a))
	# 下角的大水晶簇（左右對稱，呼應對稱中心）
	for side: float in [-1.0, 1.0]:
		var bx := w * 0.5 + side * (w * 0.5 - 50.0)
		for k in 5:
			var off := (k - 2) * 22.0
			var ht := 70.0 + 50.0 * h(k, 71) + (30.0 if k == 2 else 0.0)
			var tilt := (k - 2) * 0.18
			var base := Vector2(bx + off, hh)
			var tip := base + Vector2(sin(tilt) * ht, -cos(tilt) * ht)
			var hw := 11.0 + 4.0 * h(k, 72)
			var nrm := Vector2(cos(tilt), sin(tilt)) * hw
			var c := Color(0.85, 0.5, 1.0, 0.20) if k % 2 == 0 else Color(0.5, 0.85, 1.0, 0.18)
			var body := PackedVector2Array([base - nrm, base + nrm, tip + nrm * 0.6 + (base - tip).normalized() * 12.0, tip, tip - nrm * 0.6 + (base - tip).normalized() * 12.0])
			ci.draw_colored_polygon(body, c)
			ci.draw_line(base, tip, Color(1, 1, 1, 0.10), 1.0)
			ci.draw_polyline(PackedVector2Array([base - nrm, tip - nrm * 0.6 + (base - tip).normalized() * 12.0, tip, tip + nrm * 0.6 + (base - tip).normalized() * 12.0, base + nrm]), Color(c.r, c.g, c.b, 0.45), 1.2, true)
	# 頂上的小水晶
	for i in 10:
		var x := (i + 0.5) * w / 10.0 + 12.0 * (h(i, 73) - 0.5)
		var ln := 14.0 + 22.0 * h(i, 74)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, 0), Vector2(x + 6, 0), Vector2(x, ln)]), Color(0.75, 0.5, 1.0, 0.16))
	# 閃光
	for i in 14:
		var ph := fposmod(t * (0.35 + 0.2 * h(i, 75)) + h(i, 76), 1.0)
		var a := maxf(0.0, sin(ph * PI)) * 0.55
		var p := Vector2(h(i, 77) * w, h(i, 78) * hh)
		_glint(ci, p, 3.0 + 4.0 * a, Color(1.0, 0.85, 1.0, a))


## P8 符號地下河：底下流動的地下河、河岸的石頭、岩壁上的青苔光、洞頂滴水
static func _river(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	var top := hh * 0.76
	_grad(ci, sz, Color("0b2822"), Color("041311"))
	_stalactites(ci, sz, 11, Color(0.02, 0.08, 0.07, 0.85), 14.0, 34.0, 81)
	# 岩壁上的青苔光點
	for i in 14:
		var p := Vector2(h(i, 82) * w, (0.1 + 0.55 * h(i, 83)) * hh)
		var a := 0.12 + 0.08 * sin(t * 1.2 + i)
		UITheme.dot(ci, p, 10.0, Color(0.4, 1.0, 0.6, a * 0.25))
		UITheme.dot(ci, p, 2.0, Color(0.6, 1.0, 0.7, a * 2.0))
	# 河：一整條往右流的水
	ci.draw_rect(Rect2(0, top, w, hh - top), Color(0.04, 0.2, 0.18, 0.8))
	ci.draw_line(Vector2(0, top), Vector2(w, top), Color(0.45, 1.0, 0.8, 0.28), 1.5)
	for i in 18:
		var y := top + 6.0 + (hh - top - 12.0) * h(i, 84)
		var v := 50.0 + 60.0 * h(i, 85)
		var ln := 40.0 + 60.0 * h(i, 86)
		var x := fposmod(t * v + h(i, 87) * (w + 200.0), w + 200.0) - 100.0
		var pts := PackedVector2Array()
		for k in 7:
			var xx := x + ln * k / 6.0
			pts.append(Vector2(xx, y + 2.5 * sin(xx * 0.04 + i)))
		ci.draw_polyline(pts, Color(0.55, 1.0, 0.85, 0.20), 1.4, true)
	# 河岸的石頭
	for i in 6:
		var x := (i + 0.5) * w / 6.0 + 30.0 * (h(i, 88) - 0.5)
		var r := 10.0 + 10.0 * h(i, 89)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - r, top + 4), Vector2(x - r * 0.6, top - r * 0.6), Vector2(x + r * 0.5, top - r * 0.7), Vector2(x + r, top + 4)]), Color(0.03, 0.1, 0.09, 0.9))
	# 洞頂滴下的水
	var drops := PackedVector2Array()
	for i in 14:
		var x := h(i, 90) * w
		var y := fposmod(t * 60.0 + i * 47.0, top)
		drops.append_array([Vector2(x, y), Vector2(x, y + 7.0)])
	ci.draw_multiline(drops, Color(0.55, 1.0, 0.85, 0.22), 1.5)


# ================= 三角函數：月輪島與正弦海岸 =================

## 海面：幾條正弦波（三角函數的招牌）
static func _sea(ci: CanvasItem, sz: Vector2, t: float, y0: float, c: Color, n: int) -> void:
	for k in n:
		var yy := y0 + 16.0 * k
		var pts := _wave_line(ci, sz, yy, 3.0 + 1.0 * k, 0.02 + 0.004 * k, t * (0.7 + 0.2 * k), k * 1.7, Color(c.r, c.g, c.b, 0.0), 1.0)
		var fill := PackedVector2Array(pts)
		fill.append(Vector2(sz.x, sz.y))
		fill.append(Vector2(0, sz.y))
		ci.draw_colored_polygon(fill, Color(c.r, c.g, c.b, 0.04 + 0.012 * k))
		ci.draw_polyline(pts, Color(c.r, c.g, c.b, 0.16), 1.3, true)


## G1 弧之渡口：月光下的海、左下角的渡口棧橋與提燈、靠岸的小船
static func _ferry(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	_grad(ci, sz, Color("0c1a3c"), Color("071226"))
	_moon(ci, Vector2(w - 70, 70), 22.0, 1.0)
	_stars(ci, sz, t, 34, 0.7, Color(0.85, 0.92, 1.0), 101)
	_sea(ci, sz, t, hh * 0.78, Color(0.45, 0.7, 1.0), 4)
	# 月光倒影
	for k in 6:
		var yy := hh * 0.8 + k * 9.0
		var hw := 26.0 - k * 3.0 + 4.0 * sin(t * 1.5 + k)
		ci.draw_line(Vector2(w - 70 - hw, yy), Vector2(w - 70 + hw, yy), Color(0.9, 0.95, 1.0, 0.12), 2.0)
	# 棧橋：木板＋柱子
	var deck := hh * 0.8
	ci.draw_rect(Rect2(0, deck - 6.0, w * 0.26, 7.0), Color(0.35, 0.25, 0.18, 0.75))
	for i in 5:
		var x := 10.0 + i * w * 0.06
		ci.draw_rect(Rect2(x, deck - 6.0, 5.0, hh - deck + 6.0), Color(0.25, 0.18, 0.13, 0.75))
	# 提燈
	var lp := Vector2(w * 0.24, deck - 34.0)
	ci.draw_line(Vector2(w * 0.24, deck - 6.0), lp, Color(0.3, 0.22, 0.16, 0.85), 2.0)
	var fl := 0.85 + 0.15 * sin(t * 6.0)
	UITheme.dot(ci, lp, 40.0, Color(1.0, 0.8, 0.45, 0.05 * fl))
	UITheme.dot(ci, lp, 12.0, Color(1.0, 0.82, 0.5, 0.18 * fl))
	UITheme.dot(ci, lp, 3.5, Color(1.0, 0.92, 0.65, 0.95))
	# 小船（跟著浪上下）
	var bob := 3.0 * sin(t * 1.1)
	var bx := w * 0.36
	var by := deck + 10.0 + bob
	ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 34, by - 8), Vector2(bx + 34, by - 8), Vector2(bx + 24, by + 4), Vector2(bx - 24, by + 4)]), Color(0.3, 0.22, 0.16, 0.8))
	ci.draw_line(Vector2(bx, by - 8), Vector2(bx, by - 40), Color(0.35, 0.27, 0.2, 0.7), 2.0)


## G2 扇形潟湖：淺淺的潟湖、沙洲上的扇貝、往上冒的泡泡、水底的光紋
static func _lagoon(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	_grad(ci, sz, Color("0c2d46"), Color("0a3a3e"))
	_moon(ci, Vector2(w - 70, 64), 18.0, 0.8)
	_stars(ci, sz, t, 20, 0.4, Color(0.85, 0.95, 1.0), 111)
	# 水底的光紋（網狀）
	for k in 7:
		var y0 := hh * (0.35 + 0.09 * k)
		_wave_line(ci, sz, y0, 6.0, 0.018 + 0.003 * k, t * (0.5 + 0.1 * k), k * 2.1, Color(0.55, 1.0, 0.95, 0.05), 1.5)
	# 沙洲
	_ridge(ci, sz, hh - 26.0, 12.0, 0.012, 0.6, Color(0.55, 0.48, 0.32, 0.20))
	# 扇貝（扇形！）
	for i in 7:
		var c := Vector2((i + 0.5) * w / 7.0 + 16.0 * (h(i, 112) - 0.5), hh - 14.0 - 8.0 * h(i, 113))
		var r := 12.0 + 8.0 * h(i, 114)
		var a0 := PI + 0.35
		var a1 := TAU - 0.35
		var col := Color(1.0, 0.8, 0.7, 0.30) if i % 2 == 0 else Color(0.8, 0.95, 1.0, 0.28)
		var pts := PackedVector2Array([c])
		for k in 9:
			var a := lerpf(a0, a1, k / 8.0)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		ci.draw_colored_polygon(pts, Color(col.r, col.g, col.b, col.a * 0.6))
		for k in 5:
			var a := lerpf(a0, a1, (k + 0.5) / 5.0)
			ci.draw_line(c, c + Vector2(cos(a), sin(a)) * r, Color(col.r, col.g, col.b, col.a), 1.0)
	# 泡泡
	for i in 18:
		var v := 0.03 * (0.6 + 0.8 * h(i, 115))
		var y := 1.05 - fposmod(t * v + h(i, 116), 1.1)
		var x := h(i, 117) + 0.015 * sin(t * 1.0 + i)
		var r := 2.0 + 4.0 * h(i, 118)
		var a := clampf((y - 0.3) / 0.7, 0.0, 1.0) * 0.35
		ci.draw_arc(Vector2(x * w, y * hh), r, 0.0, TAU, 16, Color(0.75, 1.0, 1.0, a), 1.2, true)


## G3 浪之階梯：一層一層像階梯往上疊的浪、浪花、月亮
static func _steps(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	_grad(ci, sz, Color("0d1838"), Color("06142a"))
	_moon(ci, Vector2(w - 70, 70), 20.0, 0.9)
	_stars(ci, sz, t, 28, 0.55, Color(0.85, 0.92, 1.0), 121)
	# 五層浪：越下面越近、越大，像階梯
	for k in 5:
		var y0 := hh * (0.5 + 0.1 * k)
		var amp := 4.0 + 3.0 * k
		var c := Color(0.4 + 0.08 * k, 0.75, 1.0)
		var pts := _wave_line(ci, sz, y0, amp, 0.03 - 0.004 * k, t * (0.6 + 0.15 * k), k * 1.3, Color(c.r, c.g, c.b, 0.0), 1.0)
		var fill := PackedVector2Array(pts)
		fill.append(Vector2(w, hh))
		fill.append(Vector2(0, hh))
		ci.draw_colored_polygon(fill, Color(0.12, 0.3, 0.55, 0.12))
		ci.draw_polyline(pts, Color(c.r, c.g, c.b, 0.20 + 0.03 * k), 1.6, true)
		# 浪峰上的浪花
		for i in 5:
			var x := fposmod(i * w / 5.0 + t * (10.0 + 6.0 * k), w)
			var y := y0 + amp * sin(x * (0.03 - 0.004 * k) - t * (0.6 + 0.15 * k) + k * 1.3)
			UITheme.dot(ci, Vector2(x, y - 2.0), 2.0, Color(0.9, 0.97, 1.0, 0.25))


## G4 潮汐調音盤：左上角的月相、跟著月亮漲落的潮水
static func _tide(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	_grad(ci, sz, Color("140f38"), Color("07192e"))
	_moon(ci, Vector2(w - 70, 70), 22.0, 1.0)
	_stars(ci, sz, t, 30, 0.6, Color(0.9, 0.88, 1.0), 131)
	# 月相：八個小月亮圍著大月亮排一圈（亮的部分隨相位變）
	var mc := Vector2(w - 70, 70)
	for i in 8:
		var ph := i / 8.0
		var ang := PI / 2.0 + ph * TAU
		var c := mc + Vector2(cos(ang), sin(ang)) * 50.0
		ci.draw_arc(c, 6.0, 0.0, TAU, 16, Color(0.9, 0.9, 1.0, 0.22), 1.0, true)
		if i == 0:
			continue      # 新月：只有外框
		var sg := 1.0 if ph < 0.5 else -1.0
		var lit := cos(ph * TAU)
		var pts := PackedVector2Array()
		for k in 13:
			var a := -PI / 2.0 + PI * k / 12.0
			pts.append(c + Vector2(cos(a) * sg, sin(a)) * 6.0)
		for k in range(1, 12):
			var a := PI / 2.0 - PI * k / 12.0
			pts.append(c + Vector2(cos(a) * lit * sg, sin(a)) * 6.0)
		ci.draw_colored_polygon(pts, Color(0.95, 0.95, 1.0, 0.34))
	# 潮水：整片水面慢慢漲落
	var tide := 12.0 * sin(t * 0.35)
	for k in 3:
		var yy := hh - 30.0 - 18.0 * k + tide * (1.0 - 0.25 * k)
		var pts := _wave_line(ci, sz, yy, 3.0, 0.02, t * (0.7 + 0.2 * k), k * 1.7, Color(0, 0, 0, 0), 1.0)
		var fill := PackedVector2Array(pts)
		fill.append(Vector2(w, hh))
		fill.append(Vector2(0, hh))
		ci.draw_colored_polygon(fill, Color(0.45, 0.4, 1.0, 0.05 + 0.015 * k))
		ci.draw_polyline(pts, Color(0.78, 0.72, 1.0, 0.16), 1.3, true)
	# 潮位刻度（右邊）
	for k in 7:
		var y := hh - 20.0 - k * 14.0
		ci.draw_line(Vector2(w - 18, y), Vector2(w - (10 if k % 2 else 4), y), Color(0.8, 0.75, 1.0, 0.25), 1.5)


## G5 和角羅盤：慢慢轉的大羅盤刻度、星座連線
static func _compass(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	_grad(ci, sz, Color("0c1434"), Color("0a0d22"))
	_stars(ci, sz, t, 40, 1.0, Color(0.85, 0.9, 1.0), 141)
	# 星座：幾組星星連成線
	var groups := [[[0.08, 0.14], [0.14, 0.08], [0.2, 0.13], [0.24, 0.06]], [[0.72, 0.2], [0.78, 0.12], [0.86, 0.17], [0.82, 0.26], [0.72, 0.2]],
		[[0.1, 0.62], [0.16, 0.7], [0.22, 0.64]]]
	for g in groups:
		var pts := PackedVector2Array()
		for q in g:
			pts.append(Vector2(q[0] * w, q[1] * hh))
		ci.draw_polyline(pts, Color(0.7, 0.8, 1.0, 0.12), 1.0, true)
		for p in pts:
			UITheme.dot(ci, p, 2.2, Color(0.9, 0.95, 1.0, 0.5 + 0.2 * sin(t * 1.5 + p.x)))
	# 大羅盤（中心在畫面中間偏下，只露出淡淡的刻度）
	var c := Vector2(w * 0.5, hh * 0.62)
	var r := minf(w, hh) * 0.46
	var rot := t * 0.05
	ci.draw_arc(c, r, 0.0, TAU, 96, Color(1.0, 0.85, 0.5, 0.08), 2.0, true)
	ci.draw_arc(c, r * 0.82, 0.0, TAU, 96, Color(1.0, 0.85, 0.5, 0.05), 1.0, true)
	for k in 36:
		var a := rot + k * TAU / 36.0
		var d := Vector2(cos(a), sin(a))
		var l := 14.0 if k % 9 == 0 else (8.0 if k % 3 == 0 else 4.0)
		ci.draw_line(c + d * (r - l), c + d * r, Color(1.0, 0.85, 0.5, 0.16 if k % 9 == 0 else 0.08), 1.5)
	for k in 4:
		var a := rot + k * PI / 2.0
		var d := Vector2(cos(a), sin(a))
		var n := Vector2(-d.y, d.x)
		ci.draw_colored_polygon(PackedVector2Array([c + d * r * 0.78, c + n * 10.0, c - n * 10.0]), Color(1.0, 0.85, 0.5, 0.05))


## G6 倍角鏡池：遠山和蘆葦倒映在平靜的水池裡，水面一閃一閃
static func _pool(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	var wl := hh * 0.62
	_grad(ci, sz, Color("101a3e"), Color("0a1530"))
	_moon(ci, Vector2(w - 80, 64), 18.0, 0.9)
	_stars(ci, sz, t, 26, 0.5, Color(0.85, 0.92, 1.0), 151)
	# 遠山（水面上）
	var hill := PackedVector2Array()
	var x := 0.0
	while x <= w + 20.0:
		hill.append(Vector2(x, wl - 30.0 - 26.0 * (0.6 * sin(x * 0.008 + 0.5) + 0.4 * sin(x * 0.019 + 1.2))))
		x += 20.0
	var up := PackedVector2Array(hill)
	up.append(Vector2(w, wl))
	up.append(Vector2(0, wl))
	ci.draw_colored_polygon(up, Color(0.08, 0.12, 0.28, 0.85))
	# 倒影（對水面翻下來，淡一點、輕輕晃）
	var down := PackedVector2Array()
	for p in hill:
		down.append(Vector2(p.x + 2.0 * sin(t * 1.2 + p.x * 0.05), 2.0 * wl - p.y))
	down.append(Vector2(w, wl))
	down.append(Vector2(0, wl))
	ci.draw_colored_polygon(down, Color(0.12, 0.18, 0.38, 0.45))
	ci.draw_line(Vector2(0, wl), Vector2(w, wl), Color(0.8, 0.9, 1.0, 0.25), 1.5)
	# 蘆葦（左右兩邊）與倒影
	for i in 12:
		var bx := (8.0 + 9.0 * i) if i < 6 else (w - 8.0 - 9.0 * (i - 6))
		var ht := 40.0 + 30.0 * h(i, 152)
		var sw := 3.0 * sin(t * 0.9 + i)
		ci.draw_line(Vector2(bx, wl), Vector2(bx + sw, wl - ht), Color(0.3, 0.45, 0.4, 0.55), 2.0)
		ci.draw_line(Vector2(bx, wl), Vector2(bx - sw, wl + ht * 0.8), Color(0.3, 0.45, 0.4, 0.2), 2.0)
	# 月亮的倒影與水面閃光
	for k in 5:
		var yy := 2.0 * wl - 64.0 + k * 8.0
		var hw := 20.0 - k * 3.0 + 3.0 * sin(t * 1.4 + k)
		ci.draw_line(Vector2(w - 80 - hw, yy), Vector2(w - 80 + hw, yy), Color(0.9, 0.95, 1.0, 0.10), 2.0)
	for i in 12:
		var ph := fposmod(t * (0.4 + 0.2 * h(i, 153)) + h(i, 154), 1.0)
		var a := maxf(0.0, sin(ph * PI)) * 0.4
		_glint(ci, Vector2(h(i, 155) * w, wl + 10.0 + (hh - wl - 20.0) * h(i, 156)), 2.0 + 3.0 * a, Color(0.85, 0.95, 1.0, a))


## G7 疊合燈塔：右邊岩岸上的燈塔、掃過夜空的光束、海浪
static func _lighthouse(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	_grad(ci, sz, Color("0e1838"), Color("081428"))
	_stars(ci, sz, t, 34, 0.6, Color(0.85, 0.92, 1.0), 161)
	var base := Vector2(w - 64.0, hh * 0.78)
	var lamp := base + Vector2(0, -150.0)
	# 光束：繞著燈慢慢轉的兩道光（往左邊海面掃）
	var ang := PI + 0.55 * sin(t * 0.45)
	for k in 2:
		var a := ang + (k - 0.5) * 0.06
		var d := Vector2(cos(a), sin(a))
		var n := Vector2(-d.y, d.x)
		var far := lamp + d * w * 1.1
		ci.draw_colored_polygon(PackedVector2Array([lamp + n * 3.0, lamp - n * 3.0, far - n * 70.0, far + n * 70.0]),
			Color(1.0, 0.92, 0.6, 0.045))
	# 岩岸
	ci.draw_colored_polygon(PackedVector2Array([Vector2(w - 150, hh), Vector2(w - 120, base.y + 8), Vector2(w - 70, base.y - 4),
		Vector2(w - 20, base.y + 6), Vector2(w, base.y + 2), Vector2(w, hh)]), Color(0.05, 0.07, 0.14, 0.95))
	# 燈塔（紅白相間）
	var bw := 22.0
	var tw := 14.0
	for k in 5:
		var y0 := base.y - k * 26.0
		var y1 := y0 - 26.0
		var w0 := lerpf(bw, tw, k / 5.0)
		var w1 := lerpf(bw, tw, (k + 1) / 5.0)
		var c := Color(0.85, 0.85, 0.9, 0.30) if k % 2 == 0 else Color(0.9, 0.35, 0.35, 0.30)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(base.x - w0, y0), Vector2(base.x + w0, y0), Vector2(base.x + w1, y1), Vector2(base.x - w1, y1)]), c)
	ci.draw_rect(Rect2(lamp.x - 12, lamp.y - 4, 24, 12), Color(0.2, 0.22, 0.3, 0.7))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(lamp.x - 14, lamp.y - 4), Vector2(lamp.x + 14, lamp.y - 4), Vector2(lamp.x, lamp.y - 20)]), Color(0.25, 0.25, 0.35, 0.8))
	var fl := 0.85 + 0.15 * sin(t * 4.0)
	UITheme.dot(ci, lamp + Vector2(0, 2), 40.0, Color(1.0, 0.9, 0.55, 0.08 * fl))
	UITheme.dot(ci, lamp + Vector2(0, 2), 6.0, Color(1.0, 0.95, 0.7, 0.95))
	# 海浪
	_sea(ci, sz, t, hh * 0.82, Color(0.45, 0.7, 1.0), 3)


# ================= 直線與圓：圓規湖 =================

## C1 坐標燈標：清晨的湖岸。遠山、湖面一圈一圈的圓形漣漪、右邊一排沿著直線排開的燈標、慢慢飄的光點
static func _lakeside(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var w := sz.x
	var hh := sz.y
	var wl := hh * 0.64
	_grad(ci, sz, Color("1b2c4a"), Color("0c1628"))
	_stars(ci, sz, t, 22, 0.45, Color(0.85, 0.95, 1.0), 171)
	# 遠山
	_ridge(ci, Vector2(w, wl + 2.0), wl - 24.0, 18.0, 0.011, 0.8, Color(0.09, 0.14, 0.26, 0.9))
	# 湖面
	ci.draw_rect(Rect2(0, wl, w, hh - wl), Color(0.05, 0.12, 0.22, 0.85))
	ci.draw_line(Vector2(0, wl), Vector2(w, wl), Color(0.6, 0.85, 1.0, 0.25), 1.5)
	# 湖面上一圈一圈擴散的圓（橢圓：從斜上方看）
	for k in 3:
		var per := 4.5 + k * 1.3
		var ph := fposmod(t + k * 1.7, per) / per
		var c := Vector2(w * (0.22 + 0.28 * k), wl + 26.0 + 14.0 * k)
		var rx := 10.0 + ph * 120.0
		var pts := PackedVector2Array()
		for i in 33:
			var a := TAU * i / 32.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * rx * 0.22))
		ci.draw_polyline(pts, Color(0.7, 0.92, 1.0, 0.2 * (1.0 - ph)), 1.3, true)
	for j in 5:
		var yy := wl + 10.0 + j * 9.0
		var off := fmod(t * (10.0 + j * 3.0) + j * 71.0, 120.0)
		var xx := -120.0 + off
		while xx < w:
			ci.draw_line(Vector2(xx, yy), Vector2(xx + 26.0, yy), Color(0.7, 0.9, 1.0, 0.08), 1.2)
			xx += 120.0
	# 一排燈標：沿著一條直線（往右上）排開，燈光倒映在水裡
	for i in 6:
		var u := i / 5.0
		var base := Vector2(w * (0.58 + 0.38 * u), wl + 6.0 - 64.0 * u)
		var ht := 46.0 - 14.0 * u
		var lp := base + Vector2(0, -ht)
		ci.draw_line(base, lp, Color(0.45, 0.55, 0.72, 0.3), 2.0)
		var fl := 0.85 + 0.15 * sin(t * 3.0 + i * 1.3)
		UITheme.dot(ci, lp, 22.0 * fl, Color(0.55, 0.9, 1.0, 0.05))
		UITheme.dot(ci, lp, 3.0, Color(0.75, 0.95, 1.0, 0.55 * fl))
		if base.y < wl + 8.0:
			ci.draw_line(Vector2(lp.x, wl + (wl - lp.y) * 0.35), Vector2(lp.x, wl + (wl - lp.y) * 0.5), Color(0.6, 0.9, 1.0, 0.12 * fl), 2.0)
	# 慢慢飄的光點
	for i in 16:
		var p := Vector2(fposmod(h(i, 172) * w + t * (4.0 + 6.0 * h(i, 173)), w), (0.15 + 0.45 * h(i, 174)) * hh + 6.0 * sin(t * 0.7 + i))
		var a := 0.14 + 0.12 * sin(t * 1.3 + i * 2.1)
		UITheme.dot(ci, p, 5.0, Color(0.6, 0.9, 1.0, a * 0.3))
		UITheme.dot(ci, p, 1.5, Color(0.8, 0.95, 1.0, a * 2.0))
