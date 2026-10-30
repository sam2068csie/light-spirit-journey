extends RefCounted
## 各大關背景會動的氣氛層（畫在星星那一層，所以在遠景剪影和題目內容的後面）
## 全部用時間 t 直接算位置（不存粒子狀態），每幀重畫也很便宜。
##   aurora    光之橋：極光帶在天空飄動
##   embers    換元鍛造所：爐火的火星往上飄
##   dust      天秤神殿：金色微塵緩緩浮動
##   motes     對數鍊金術：紫色魔法泡泡上升
##   fireflies 真數守門員：森林裡的螢火蟲
##   currents  正負羅盤：海風吹過的細長流線
##   meteors   位數望遠鏡：偶爾劃過的流星
##   moonsea   三角函數：大月亮與月光下的海波
##   rocks     終焉之塔：浮空石塊＋往上飄的紅紫光屑
const UITheme := preload("game_theme.gd")


static func paint(ci: CanvasItem, kind: String, sz: Vector2, t: float) -> void:
	match kind:
		"aurora":
			_aurora(ci, sz, t)
		"embers":
			_rise(ci, sz, t, 28, Color(1.0, 0.55, 0.2), 0.05, 2.4, 11)
		"dust":
			_float(ci, sz, t, 36, Color(1.0, 0.85, 0.5), 1.8, 0.35)
		"motes":
			_bubbles(ci, sz, t)
		"fireflies":
			_fireflies(ci, sz, t)
		"currents":
			_currents(ci, sz, t)
		"meteors":
			_meteors(ci, sz, t)
		"moonsea":
			_moonsea(ci, sz, t)
		"rocks":
			_rocks(ci, sz, t)


## 0～1 之間固定的亂數（同一個 i 每次都一樣）
static func h(i: int, k: float = 0.0) -> float:
	return fposmod(sin(i * 12.9898 + k * 78.233) * 43758.5453, 1.0)


static func _aurora(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var cols := [Color(0.35, 1.0, 0.7), Color(0.4, 0.85, 1.0), Color(0.75, 0.5, 1.0)]
	for k in 3:
		var pts := PackedVector2Array()
		var x := -20.0
		var y0 := sz.y * (0.16 + 0.07 * k)
		while x <= sz.x + 20.0:
			var y := y0 + sin(x * 0.0065 + t * (0.25 + 0.08 * k) + k * 1.7) * 26.0 + sin(x * 0.017 - t * 0.4 + k) * 9.0
			pts.append(Vector2(x, y))
			x += 24.0
		var c: Color = cols[k]
		var breathe := 0.75 + 0.25 * sin(t * 0.5 + k * 2.0)
		ci.draw_polyline(pts, Color(c.r, c.g, c.b, 0.035 * breathe), 70.0)
		ci.draw_polyline(pts, Color(c.r, c.g, c.b, 0.06 * breathe), 30.0)
		ci.draw_polyline(pts, Color(c.r, c.g, c.b, 0.10 * breathe), 8.0)
		# 往下垂的光幕
		for j in range(0, pts.size(), 2):
			var p: Vector2 = pts[j]
			var len := 40.0 + 30.0 * h(j + k * 50)
			var a := 0.05 * breathe * (0.5 + 0.5 * sin(t * 1.2 + j * 0.7 + k))
			ci.draw_line(p, p + Vector2(0, len), Color(c.r, c.g, c.b, a), 6.0)


## 往上飄、左右搖的小光點（火星）
static func _rise(ci: CanvasItem, sz: Vector2, t: float, n: int, c: Color, speed: float, r: float, seed_k: int) -> void:
	for i in n:
		var v := speed * (0.6 + 0.8 * h(i, seed_k))
		var y := 1.05 - fposmod(t * v + h(i, seed_k + 1), 1.15)
		var x := h(i, seed_k + 2) + 0.02 * sin(t * (1.0 + h(i, 3)) + i)
		var life := clampf(y / 0.9, 0.0, 1.0)
		var a := life * (0.5 + 0.4 * sin(t * 6.0 + i))
		var p := Vector2(x * sz.x, y * sz.y)
		UITheme.dot(ci, p, r * 2.4, Color(c.r, c.g, c.b, a * 0.18))
		UITheme.dot(ci, p, r * (0.6 + 0.4 * life), Color(c.r, c.g * 1.1, c.b, a))


## 原地緩緩漂浮的微塵
static func _float(ci: CanvasItem, sz: Vector2, t: float, n: int, c: Color, r: float, a0: float) -> void:
	for i in n:
		var p := Vector2((h(i, 5) + 0.03 * sin(t * 0.3 + i)) * sz.x, (h(i, 6) + 0.03 * sin(t * 0.23 + i * 1.3)) * sz.y)
		var a := a0 * (0.5 + 0.5 * sin(t * 1.1 + i * 2.1))
		UITheme.dot(ci, p, r * 2.2, Color(c.r, c.g, c.b, a * 0.25))
		UITheme.dot(ci, p, r * 0.7, Color(c.r, c.g, c.b, a))


static func _bubbles(ci: CanvasItem, sz: Vector2, t: float) -> void:
	for i in 16:
		var v := 0.025 * (0.6 + 0.8 * h(i, 21))
		var y := 1.08 - fposmod(t * v + h(i, 22), 1.2)
		var x := h(i, 23) + 0.025 * sin(t * 0.8 + i)
		var r := 4.0 + 7.0 * h(i, 24)
		var a := clampf(y / 0.8, 0.0, 1.0) * 0.32
		var c := Color(0.75, 0.55, 1.0, a) if i % 3 else Color(0.45, 0.95, 0.85, a)
		var p := Vector2(x * sz.x, y * sz.y)
		ci.draw_arc(p, r, 0.0, TAU, 20, c, 1.4, true)
		UITheme.dot(ci, p + Vector2(-r * 0.35, -r * 0.35), r * 0.22, Color(1, 1, 1, a * 0.9))


static func _fireflies(ci: CanvasItem, sz: Vector2, t: float) -> void:
	for i in 18:
		var cx := h(i, 31)
		var cy := 0.35 + 0.6 * h(i, 32)
		var p := Vector2((cx + 0.05 * sin(t * (0.3 + 0.2 * h(i, 33)) + i)) * sz.x,
			(cy + 0.04 * sin(t * (0.45 + 0.2 * h(i, 34)) + i * 2.0)) * sz.y)
		var blink := maxf(0.0, sin(t * (0.9 + 0.6 * h(i, 35)) + i * 1.7))
		var a := pow(blink, 2.0)
		UITheme.dot(ci, p, 9.0, Color(0.7, 1.0, 0.45, 0.12 * a))
		UITheme.dot(ci, p, 2.2, Color(0.85, 1.0, 0.6, 0.9 * a))


static func _currents(ci: CanvasItem, sz: Vector2, t: float) -> void:
	for i in 14:
		var y := (0.1 + 0.85 * h(i, 41)) * sz.y
		var v := 40.0 + 50.0 * h(i, 42)
		var len := 60.0 + 90.0 * h(i, 43)
		var x := fposmod(t * v + h(i, 44) * (sz.x + 300.0), sz.x + 300.0) - 150.0
		var a := 0.10 + 0.06 * sin(t + i)
		var pts := PackedVector2Array()
		for k in 9:
			var xx := x + len * k / 8.0
			pts.append(Vector2(xx, y + 4.0 * sin(xx * 0.03 + i)))
		ci.draw_polyline(pts, Color(0.45, 0.95, 0.9, a), 1.5, true)


static func _meteors(ci: CanvasItem, sz: Vector2, t: float) -> void:
	# 天空偏亮的星雲團
	for k in 3:
		var c := Vector2((0.2 + 0.3 * k) * sz.x, (0.18 + 0.08 * (k % 2)) * sz.y)
		var col := Color(0.4, 0.55, 1.0) if k != 1 else Color(0.8, 0.5, 1.0)
		for j in 5:
			UITheme.dot(ci, c, 60.0 + j * 22.0, Color(col.r, col.g, col.b, 0.018))
	var per := 2.6
	for lane in 2:
		var tt := t + lane * 1.3
		var n := int(floor(tt / per))
		var ph := fmod(tt, per) / 0.7
		if ph > 1.0:
			continue
		var start := Vector2((0.15 + 0.7 * h(n, 51 + lane)) * sz.x, (0.05 + 0.3 * h(n, 53 + lane)) * sz.y)
		var dir := Vector2(-1.0, 0.55).normalized()
		var head := start + dir * ph * 260.0
		var a := sin(ph * PI)
		for k in 10:
			var p := head - dir * k * 9.0
			UITheme.dot(ci, p, 2.4 - k * 0.2, Color(0.85, 0.92, 1.0, a * (1.0 - k / 10.0)))


static func _moonsea(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var mc := Vector2(sz.x - 70.0, 70.0)     # 月亮已經畫在背景裡（同一個位置），這裡只畫海波和月光倒影
	# 月光下的海波（正弦波，呼應三角函數）
	for k in 4:
		var y0 := sz.y - 70.0 + k * 18.0
		var pts := PackedVector2Array()
		var x := 0.0
		while x <= sz.x + 12.0:
			pts.append(Vector2(x, y0 + 5.0 * sin(x * (0.02 - k * 0.003) - t * (0.8 + 0.2 * k) + k)))
			x += 12.0
		ci.draw_polyline(pts, Color(0.55, 0.8, 1.0, 0.09 + 0.03 * k), 1.6, true)
	# 海面上的月光倒影
	for k in 6:
		var y := sz.y - 64.0 + k * 10.0
		var w := 30.0 - k * 3.0 + 6.0 * sin(t * 2.0 + k)
		ci.draw_line(Vector2(mc.x - w, y), Vector2(mc.x + w, y), Color(0.85, 0.92, 1.0, 0.14 - k * 0.015), 2.0)


## 終焉之塔：天空中的浮空石塊（上下慢慢浮動）
static func _rocks(ci: CanvasItem, sz: Vector2, t: float) -> void:
	var spots := [[0.07, 0.30, 34.0], [0.2, 0.72, 22.0], [0.88, 0.22, 40.0], [0.95, 0.62, 26.0], [0.42, 0.86, 16.0], [0.75, 0.82, 20.0],
		[0.3, 0.06, 13.0], [0.47, 0.075, 9.0], [0.58, 0.05, 15.0], [0.69, 0.08, 8.0]]     # 最後幾顆在上方標題列的空隙，畫面上看得到
	for i in spots.size():
		var sp: Array = spots[i]
		var c := Vector2(sp[0] * sz.x, sp[1] * sz.y + 8.0 * sin(t * 0.6 + i * 1.3))
		var r: float = sp[2]
		# 石塊：上面平、下面尖的不規則多邊形
		var top := PackedVector2Array()
		var n := 7
		for k in n:
			var a := PI + PI * k / (n - 1)
			top.append(c + Vector2(cos(a) * r, sin(a) * r * 0.32 * (0.8 + 0.4 * h(i * 10 + k, 61))))
		var body := PackedVector2Array(top)
		body.append(c + Vector2(r * 0.55, r * 0.35))
		body.append(c + Vector2(r * 0.1, r * (0.9 + 0.3 * h(i, 62))))
		body.append(c + Vector2(-r * 0.5, r * 0.4))
		ci.draw_colored_polygon(body, Color(0.16, 0.08, 0.2, 0.95))
		ci.draw_colored_polygon(top, Color(0.55, 0.25, 0.5, 0.95))
		ci.draw_polyline(top, Color(1.0, 0.55, 0.75, 0.55), 1.5, true)
		# 石塊底下的光屑
		var g := 0.5 + 0.5 * sin(t * 1.5 + i)
		UITheme.dot(ci, c + Vector2(r * 0.1, r * 1.1), 3.0, Color(1.0, 0.5, 0.75, 0.25 * g))
	_rise(ci, sz, t, 22, Color(1.0, 0.45, 0.65), 0.035, 2.0, 71)
