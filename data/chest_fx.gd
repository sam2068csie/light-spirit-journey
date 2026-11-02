extends Control
## 章節寶箱的動畫（3/4 立體視角）：晃動 → 抖三下 → 蓋子翻開、光芒和星星
## （從 level_base.gd 拆出來的；原本是裡面的 class ChestFx）
const UITheme := preload("game_theme.gd")
const MathLabel := preload("math_text.gd")
const Game := preload("game.gd")

signal tapped
var glow := UITheme.GOLD
var gold := false       # 章節黃金寶箱：整個箱子是金色的
var t := 0.0
var phase := 0          # 0 等待（輕輕晃）、1 抖動、2 打開
var pt := 0.0           # 這個階段經過的時間
var lid := 0.0          # 0 關著、1 全開
var parts: Array = []
var _done: Callable

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP      # 點寶箱也能打開
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if phase == 0:
			tapped.emit()
		accept_event()

func shake_open(done: Callable) -> void:
	phase = 1
	pt = 0.0
	_done = done

func _process(dt: float) -> void:
	t += dt
	pt += dt
	if phase == 1 and pt >= 0.6:
		phase = 2
		pt = 0.0
		_burst()
		if _done.is_valid():
			_done.call()
	if phase == 2:
		lid = minf(1.0, lid + dt * 4.0)
		if pt < 1.2 and randf() < 0.5:
			_spawn(1)
	for p in parts:
		p.v.y += 260.0 * dt
		p.p += p.v * dt
		p.life -= dt * 0.7
	parts = parts.filter(func(p): return p.life > 0.0)
	queue_redraw()

func _mouth() -> Vector2:
	return Vector2(size.x / 2.0, size.y * 0.58)

func _burst() -> void:
	_spawn(26)

func _spawn(n: int) -> void:
	var cols := [UITheme.GOLD, UITheme.GOLD_PALE, UITheme.CYAN_LIGHT, UITheme.VIOLET_LIGHT, glow]
	for i in n:
		var ang := randf_range(-PI * 0.85, -PI * 0.15)
		var sp := randf_range(160.0, 330.0)
		parts.append({"p": _mouth() + Vector2(randf_range(-30, 30), 0), "v": Vector2(cos(ang), sin(ang)) * sp,
			"life": randf_range(0.7, 1.0), "r": randf_range(4.5, 8.5), "c": cols[randi() % cols.size()]})

func _draw() -> void:
	var m := _mouth()
	var W := 130.0
	# 晃動
	var off := Vector2.ZERO
	var rot := 0.0
	if phase == 0:
		rot = 0.05 * sin(t * 6.0) * maxf(0.0, sin(t * 1.7))
	elif phase == 1:
		off.x = sin(pt * 70.0) * 4.0 * (0.5 + pt)
		off.y = -absf(sin(pt * 16.0)) * 6.0
	# 打開後：背後旋轉的光芒
	if phase == 2:
		var k := clampf(pt / 0.4, 0.0, 1.0)
		var ra := 0.34 * k * (0.75 + 0.25 * sin(t * 3.0))
		for i in 12:
			var a := t * 0.6 + i * TAU / 12.0
			var L := 120.0 + 10.0 * sin(t * 2.0 + i)
			var tri := PackedVector2Array([m, m + Vector2(cos(a - 0.09), sin(a - 0.09)) * L, m + Vector2(cos(a + 0.09), sin(a + 0.09)) * L])
			draw_polygon(tri, PackedColorArray([Color(1, 0.85, 0.4, ra * (0.6 if i % 2 else 1.0)), Color(1, 0.85, 0.4, 0.0), Color(1, 0.85, 0.4, 0.0)]))
		for rr in [70.0, 48.0, 28.0]:
			UITheme.dot(self, m, rr * (0.6 + 0.4 * k), Color(1, 0.92, 0.6, 0.12 * k))
	draw_set_transform(off + m, rot, Vector2.ONE)
	_draw_chest()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if gold and phase < 2:
		for i in 4:
			var f := fmod(t * 0.7 + i * 0.25, 1.0)
			_star(m + Vector2(-70 + i * 46, 50 - f * 90), 3.0 + 4.0 * sin(f * PI), Color(1, 0.97, 0.8, sin(f * PI)))
	# 星星
	for p in parts:
		var a: float = clampf(p.life, 0.0, 1.0)
		_star(p.p, p.r * (0.6 + 0.4 * a), Color(p.c.r, p.c.g, p.c.b, a))


## 寶箱本體（3/4 視角）：正面＋右側面、木紋、金屬包角和鉚釘、弧形的蓋子
const CW := 130.0      # 正面寬
const CH := 62.0       # 箱身高
const LH := 34.0       # 蓋子的弧高
const DEP := Vector2(26, -16)    # 往後（右上）的深度

func _pal() -> Dictionary:
	if gold:
		return {"wood": Color("d9a52a"), "hi": Color("f7dc8a"), "lo": Color("9a6a14"), "side": Color("a8781c"),
			"in": Color("6a4410"), "band": Color("fff6d6"), "band_lo": Color("d8c48e"), "rivet": Color("ffffff"), "grain": Color(0.45, 0.28, 0.02, 0.35)}
	return {"wood": Color("8a4a22"), "hi": Color("b8703a"), "lo": Color("552810"), "side": Color("63321a"),
		"in": Color("2e1408"), "band": Color("f0c050"), "band_lo": Color("a8761c"), "rivet": Color("fff0b8"), "grain": Color(0.2, 0.08, 0.02, 0.45)}

## 蓋子弧面上的點：x 沿寬，th 從正面下緣（0）繞到後面（π）
func _lid_p(x: float, th: float, lift: float) -> Vector2:
	return Vector2(x, -lift) + DEP * (1.0 - cos(th)) / 2.0 + Vector2(0, -LH * sin(th))

func _grad_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, top: Color, bot: Color) -> void:
	draw_polygon(PackedVector2Array([a, b, c, d]), PackedColorArray([top, top, bot, bot]))

func _draw_chest() -> void:
	var P := _pal()
	var hw := CW / 2.0
	# 地上的影子
	var sh := PackedVector2Array()
	for k in 33:
		var a := TAU * k / 32.0
		sh.append(Vector2(10 + cos(a) * (hw + 26), CH + 4 + sin(a) * 12))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.32))
	# 打開的蓋子在箱子後面：先畫
	if lid >= 0.3:
		_draw_lid_open(P, (lid - 0.3) / 0.7)
	# ---- 箱身右側面 ----
	_grad_quad(Vector2(hw, 0), Vector2(hw, 0) + DEP, Vector2(hw, CH) + DEP, Vector2(hw, CH), P.side, P.side.darkened(0.35))
	for k in 3:
		var y := 16.0 + k * 16.0
		draw_line(Vector2(hw, y), Vector2(hw, y) + DEP, P.grain, 1.5)
	draw_line(Vector2(hw + 3, 2), Vector2(hw + 3, CH - 2), P.band_lo, 5.0)          # 側面的包角
	draw_line(Vector2(hw, 0) + DEP + Vector2(-3, 2), Vector2(hw, CH) + DEP + Vector2(-3, -2), P.band_lo.darkened(0.2), 5.0)
	# ---- 打開時：箱子裡面（暗色＋發光的寶物）----
	if lid > 0.0:
		var top := PackedVector2Array([Vector2(-hw, 0), Vector2(hw, 0), Vector2(hw, 0) + DEP, Vector2(-hw, 0) + DEP])
		draw_colored_polygon(top, P["in"])
		var gc := DEP / 2.0 + Vector2(0, 2)
		for r in [52.0, 36.0, 22.0]:
			UITheme.dot(self, gc, r * (0.4 + 0.6 * lid), Color(1, 0.88, 0.45, 0.18 * lid))
		for k in 7:
			var cp := gc + Vector2(-42 + k * 14, (k % 2) * 3 - 2)
			UITheme.dot(self, cp, 6.0, Color(1, 0.82, 0.3, lid))
			UITheme.dot(self, cp + Vector2(-1.5, -1.5), 2.5, Color(1, 1, 0.85, lid))
	# ---- 箱身正面：上亮下暗＋木板紋 ----
	_grad_quad(Vector2(-hw, 0), Vector2(hw, 0), Vector2(hw, CH), Vector2(-hw, CH), P.hi, P.lo)
	for k in 3:
		var y := 16.0 + k * 16.0
		draw_line(Vector2(-hw + 2, y), Vector2(hw - 2, y), P.grain, 2.0)
		draw_line(Vector2(-hw + 2, y + 2), Vector2(hw - 2, y + 2), Color(1, 1, 1, 0.06), 1.0)
	draw_line(Vector2(-hw, CH - 1), Vector2(hw, CH - 1), Color(0, 0, 0, 0.35), 3.0)
	# 金屬：上緣、底緣、兩條直帶、四個包角、鉚釘
	_band(Vector2(-hw, -1), Vector2(hw, -1), 7.0, P)
	_band(Vector2(-hw, CH - 4), Vector2(hw, CH - 4), 7.0, P)
	for bx in [-hw * 0.62, hw * 0.62]:
		_band(Vector2(bx, 0), Vector2(bx, CH), 12.0, P)
		for ry in [10.0, 30.0, 50.0]:
			_rivet(Vector2(bx, ry), P)
	for cx in [-hw, hw]:
		var sx := 1.0 if cx < 0 else -1.0
		draw_colored_polygon(PackedVector2Array([Vector2(cx, 0), Vector2(cx + sx * 16, 0), Vector2(cx, 16)]), P.band)
		draw_colored_polygon(PackedVector2Array([Vector2(cx, CH), Vector2(cx + sx * 16, CH), Vector2(cx, CH - 16)]), P.band_lo)
	# ---- 蓋子 ----
	var lift := 0.0
	if lid < 0.3:
		lift = lid / 0.3 * 10.0
		_draw_lid_closed(P, lift)
	# ---- 鎖 ----
	if lid < 0.5:
		var lc := Vector2(0, 6 - lift)
		var plate := PackedVector2Array([lc + Vector2(-13, -12), lc + Vector2(13, -12), lc + Vector2(13, 8), lc + Vector2(0, 18), lc + Vector2(-13, 8)])
		draw_colored_polygon(plate, P.band_lo.darkened(0.15))
		var inner := PackedVector2Array()
		for q in plate:
			inner.append(lc + (q - lc) * 0.82 + Vector2(0, -1))
		draw_colored_polygon(inner, P.band)
		draw_line(lc + Vector2(-9, -9), lc + Vector2(9, -9), Color(1, 1, 1, 0.55), 1.5)
		if gold:
			draw_colored_polygon(PackedVector2Array([lc + Vector2(0, -6), lc + Vector2(6, 0), lc + Vector2(0, 6), lc + Vector2(-6, 0)]), Color("5fd4ff"))
			draw_line(lc + Vector2(-2, -3), lc + Vector2(1, -5), Color(1, 1, 1, 0.8), 1.5)
		else:
			UITheme.dot(self, lc + Vector2(0, -1), 3.2, Color("3a1a08"))
			draw_colored_polygon(PackedVector2Array([lc + Vector2(-2, 0), lc + Vector2(2, 0), lc + Vector2(3, 8), lc + Vector2(-3, 8)]), Color("3a1a08"))

func _band(a: Vector2, b: Vector2, w: float, P: Dictionary) -> void:
	var d := (b - a).normalized()
	var n := d.orthogonal() * w / 2.0
	draw_polygon(PackedVector2Array([a + n, b + n, b - n, a - n]), PackedColorArray([P.band, P.band, P.band_lo, P.band_lo]))
	draw_line(a + n * 0.8, b + n * 0.8, Color(1, 1, 1, 0.35), 1.0)

func _rivet(c: Vector2, P: Dictionary) -> void:
	UITheme.dot(self, c + Vector2(0.8, 1), 2.6, Color(0, 0, 0, 0.35))
	UITheme.dot(self, c, 2.4, P.band_lo)
	UITheme.dot(self, c + Vector2(-0.7, -0.7), 1.2, P.rivet)

## 關著（或剛要打開、往上抬一點）的弧形蓋子
func _draw_lid_closed(P: Dictionary, lift: float) -> void:
	var hw := CW / 2.0
	var N := 14
	var TH_MAX := PI * 0.82
	# 右邊的端蓋
	var cap := PackedVector2Array()
	for k in N + 1:
		cap.append(_lid_p(hw, PI * k / N, lift))
	draw_colored_polygon(cap, P.side.darkened(0.1))
	draw_polyline(cap, P.band_lo, 4.0, true)
	# 弧面：一條一條，越往上越亮
	for k in N:
		var t0 := TH_MAX * k / N
		var t1 := TH_MAX * (k + 1) / N
		var shade := 0.5 + 0.5 * sin(lerpf(t0, t1, 0.5) + 0.3)
		var c0: Color = P.lo.lerp(P.hi, shade)
		draw_colored_polygon(PackedVector2Array([_lid_p(-hw, t0, lift), _lid_p(hw, t0, lift), _lid_p(hw, t1, lift), _lid_p(-hw, t1, lift)]), c0)
		if k % 3 == 2:
			draw_line(_lid_p(-hw + 2, t1, lift), _lid_p(hw - 2, t1, lift), P.grain, 1.5)
	# 金屬帶沿著弧面
	for bx in [-hw * 0.62, hw * 0.62]:
		var pts := PackedVector2Array()
		for k in N + 1:
			pts.append(_lid_p(bx, PI * 0.56 * k / N, lift))     # 只畫到弧面的最高點（後面那段被擋住）
		draw_polyline(pts, P.band_lo, 13.0, true)
		draw_polyline(pts, P.band, 9.0, true)
		_rivet(_lid_p(bx, TH_MAX * 0.45, lift), P)
	var edge := PackedVector2Array()
	for k in N + 1:
		edge.append(_lid_p(hw, PI * k / N, lift))
	_band(Vector2(-hw, -lift - 2), Vector2(hw, -lift - 2), 8.0, P)
	var ridge := PackedVector2Array([_lid_p(-hw, TH_MAX, lift), _lid_p(hw, TH_MAX, lift)])
	draw_line(ridge[0], ridge[1], Color(1, 1, 1, 0.18), 2.0)
	if lift > 0.0:
		draw_rect(Rect2(-hw + 6, -lift, CW - 12, lift), Color(1, 0.95, 0.7, 0.9))

## 打開的蓋子：把關著的弧形蓋子，繞著後緣的鉸鏈往後轉 φ（立體地算，再投影到畫面）
##   截面座標：z 往後（鉸鏈在 z = DEPTH）、y 往上；x 沿寬
const DEPTH := 70.0     # 實際的深度（畫面上斜斜地縮成 DEP）

func _lid3(x: float, th: float, phi: float, r_scale := 1.0) -> Vector2:
	var z := DEPTH * (1.0 - cos(th)) / 2.0
	var y := LH * sin(th) * r_scale
	var zr := z - DEPTH
	var z2 := zr * cos(phi) + y * sin(phi) + DEPTH
	var y2 := -zr * sin(phi) + y * cos(phi)
	return Vector2(x, 0) + DEP * (z2 / DEPTH) + Vector2(0, -y2)

func _draw_lid_open(P: Dictionary, k: float) -> void:
	var hw := CW / 2.0
	var phi := deg_to_rad(15.0 + 85.0 * clampf(k, 0.0, 1.0))
	var N := 14
	# 外殼的厚度：先畫一層稍微大一點的外殼（看起來是蓋子的木頭邊）
	var outer := PackedVector2Array()
	for j in N + 1:
		outer.append(_lid3(-hw, PI * j / N, phi, 1.0))
	# 裡面那一面（凹進去，看得到）：一條一條，靠近開口比較亮
	for j in N:
		var t0 := PI * j / N
		var t1 := PI * (j + 1) / N
		var shade := 0.25 + 0.5 * sin(lerpf(t0, t1, 0.5))
		var c: Color = P["in"].lerp(P.side, shade)
		draw_colored_polygon(PackedVector2Array([_lid3(-hw, t0, phi), _lid3(hw, t0, phi), _lid3(hw, t1, phi), _lid3(-hw, t1, phi)]), c)
		if j % 3 == 1:
			draw_line(_lid3(-hw + 3, t1, phi), _lid3(hw - 3, t1, phi), P.grain, 1.2)
	# 寶物的光映在蓋子裡面
	var glow_c := _lid3(0, PI * 0.5, phi)
	UITheme.dot(self, glow_c, 40.0, Color(1, 0.85, 0.4, 0.10 * k))
	# 左右兩片端蓋（有厚度）：左邊那片被擋住一部分，只畫邊；右邊那片看得到
	var capL := PackedVector2Array()
	var capR := PackedVector2Array()
	for j in N + 1:
		capL.append(_lid3(-hw, PI * j / N, phi))
		capR.append(_lid3(hw, PI * j / N, phi))
	draw_polyline(capL, P.band_lo, 5.0, true)
	var capR_o := PackedVector2Array()
	for q in capR:
		capR_o.append(q + Vector2(5, 0))
	var thick := PackedVector2Array(capR)
	var rev := capR_o.duplicate()
	rev.reverse()
	thick.append_array(rev)
	draw_colored_polygon(thick, P.side.darkened(0.15))
	draw_colored_polygon(capR_o, P.side)
	draw_polyline(capR_o, P.band_lo, 4.0, true)
	# 蓋子的邊緣（關著時的下緣，現在翻到最上面）：金屬條＋厚度
	var rim0 := _lid3(-hw, 0.0, phi)
	var rim1 := _lid3(hw, 0.0, phi)
	var up := (_lid3(0, 0.0, phi) - _lid3(0, 0.25, phi)).normalized() * 7.0
	draw_colored_polygon(PackedVector2Array([rim0, rim1, rim1 + up, rim0 + up]), P.lo)
	_band(rim0 + up * 0.5, rim1 + up * 0.5, 8.0, P)
	# 外側的金屬帶從邊緣繞過去（看得到一小截）
	for bx in [-hw * 0.62, hw * 0.62]:
		var a1 := _lid3(bx, 0.0, phi)
		draw_line(a1, a1 + up * 1.4, P.band, 10.0)
	# 鉸鏈
	var h0 := _lid3(-hw, PI, phi)
	var h1 := _lid3(hw, PI, phi)
	draw_line(h0, h1, P.band_lo, 6.0)
	for hx in [-hw * 0.62, hw * 0.62]:
		var hp := _lid3(hx, PI, phi)
		draw_rect(Rect2(hp - Vector2(7, 4), Vector2(14, 8)), P.band)
		_rivet(hp, P)

func _star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 8:
		var a := k * PI / 4.0 + t * 2.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.4))
	draw_colored_polygon(pts, col)
