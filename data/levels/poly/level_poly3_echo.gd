extends "res://data/levels/poly/level_poly2_wheel.gd"
## 多項式 第三大關「回音石廊」（對應講義 4-1 重點三：餘式定理、因式定理）
## 引擎是 step_level.gd，畫面沿用第二關的 WheelView（綜合除法、長除法的算式），題庫在 poly3_bank.gd。
##
## 這一關多了：
##   ・喊話（題庫的 _shout，畫面上是選擇題）：答對時聲波從左邊飛向深谷，波上寫著喊出去的 x = a
##   ・回音（填空帶 "echo"）：答對時回音帶著 f(a) 的值彈回來；f(a) = 0 時谷底一片安靜，跳出「x − a 是因式」
##   ・回音圖（題目帶 "echograph"）：下方的座標圖，回音點 (a, f(a)) 一個一個亮起來，最後畫出餘式的圖形
##   ・峽谷石廊的背景（兩側的岩壁、垂下來的鐘乳石）
##   ・速算：f(x) 除以 x − a 的餘式（三次式附綜合除法的格式；大次方的式子除以 x ± 1）

const BankP3 := preload("res://data/levels/poly/poly3_bank.gd")
const ECHO_C := Color("c8a8ff")

const CHAPTERS_P3 := [
	{"ch": 1, "name": "第一章．回音入門", "topic": "餘式定理、因式定理、用綜合除法求值", "color": Color("c8a8ff")},
	{"ch": 2, "name": "第二章．雙重回音", "topic": "除式是二次式、三次式，餘式的運算、大次方的餘式", "color": UITheme.PINK},
]


func level_id() -> String:
	return "P3"

func level_title() -> String:
	return "回音石廊"

func level_subtitle() -> String:
	return "餘式定理與因式定理"

func level_chapters() -> Array:
	return CHAPTERS_P3

func bank_slots() -> Array:
	return BankP3.slots()

func step_color() -> Color:
	return ECHO_C

func stage_style() -> Dictionary:
	return {"sky_top": Color("1a1430"), "sky_bot": Color("0e0b1c"), "scenery": "none", "ambient": "currents"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．雙重回音", "button": "走進雙重回音  ▶",
		"text": "石廊深處，一次要喊兩聲、三聲：\n\n" \
			+ "・除以 (x − a)(x − b)：餘式設 px + q，代 a、b 兩個數\n" \
			+ "・沒有直接給的回音：從別的除法借過來\n" \
			+ "・兩個多項式的餘式也可以相乘\n" \
			+ "・x^{100} 除以二次式：1、−1、0 的次方都很好算\n\n" \
			+ "仔細聽回音！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = EchoView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "回音速算"
		fview.speed_y = 0.30


func _ev() -> EchoView:
	return fview as EchoView


# ================= 喊話、回音 =================

func _step_done(st: Dictionary, why: String) -> void:
	if fview != null and r.get("type", "") == "forge":
		if st.has("shout"):
			_ev().shout(String(st.shout))
			Game.of(self).play("blip", 0.8, -6.0)
		elif st.has("echo"):
			_ev().echo(String(st.echo.x), String(st.echo.val))
			Game.of(self).play("blip", 1.5 if String(st.echo.val) != "0" else 0.6, -6.0)
	super(st, why)


# ================= 速算 =================

func _speed_tag() -> String:
	return BankP3.T_REM


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算題：f(x) 除以 x − a 的餘式。{eq, q, template, ans, nudge, tag}（三次式多帶 synth：下方畫綜合除法的格式）
static func gen_problems(_kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var pb := {}
		if randf() < 0.6:
			var coef := [randi_range(1, 2), randi_range(-4, 4), randi_range(-5, 5), randi_range(-6, 6)]
			var a: int = [-2, -1, 1, 2, 3].pick_random()
			var row := BankP2.synth_row(coef, [a, 1])
			var v: Array = row[3]
			if absi(v[0]) > 50 or coef[1] == 0 and randf() < 0.7:
				continue
			pb = {"eq": "%s 除以 %s\n餘式 = ？" % [BankP2.poly_text(coef), BankP2.divisor_text([a, 1])], "ans": BankP2._qa(v),
				"synth": {"coef": coef, "a": [a, 1], "ask": 3},
				"q": "餘式 = f(%s)：代進去，或用綜合除法。" % BankP2._qs([a, 1]),
				"nudge": "除以 %s ⇒ 代 x = %s。" % [BankP2.divisor_text([a, 1]), BankP2._qs([a, 1])]}
		else:
			# 大次方：x^{n} + bx^{m} + c 除以 x ± 1
			var a2: int = [1, -1].pick_random()
			var n1 := randi_range(20, 99)
			var m1 := randi_range(3, n1 - 5)
			var b := [-3, -2, 2, 3].pick_random() as int
			var c := randi_range(-5, 5)
			if c == 0:
				continue
			var pn := 1 if (a2 == 1 or n1 % 2 == 0) else -1
			var pm := 1 if (a2 == 1 or m1 % 2 == 0) else -1
			var v2 := pn + b * pm + c
			var txt := "x^{%d} %s %dx^{%d} %s %d" % [n1, "−" if b < 0 else "+", absi(b), m1, "−" if c < 0 else "+", absi(c)]
			pb = {"eq": "%s 除以 %s\n餘式 = ？" % [txt, "x − 1" if a2 == 1 else "x + 1"], "ans": str(v2),
				"q": "餘式 = f(%s)：看次方是奇數還是偶數。" % ("1" if a2 == 1 else "−1"),
				"nudge": "1 的任何次方是 1。" if a2 == 1 else "(−1) 的偶數次方是 1，奇數次方是 −1。"}
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		pb["template"] = "餘式 = [0]"
		pb["tag"] = BankP3.T_REM
		out.append(pb)
	return out


# ================= 畫面：峽谷石廊 + 回音 =================

class EchoView extends WheelView:
	const ECHO := Color("c8a8ff")

	var eg := {}                 # 回音圖 {pts, curve, after}
	var shout_t := -10.0
	var shout_x := ""
	var echo_t := -10.0
	var echo_x := ""
	var echo_val := ""
	var _walls := []             # 岩壁（快取）

	func setup(round: Dictionary) -> void:
		super(round)
		eg = round.get("echograph", {}) if String(round.get("type", "")) == "forge" else {}
		shout_t = -10.0
		echo_t = -10.0

	func shout(x: String) -> void:
		shout_x = x
		shout_t = t
		echo_t = -10.0

	func echo(x: String, val: String) -> void:
		echo_x = x
		echo_val = val
		echo_t = t

	func _graph_on() -> bool:
		return not eg.is_empty() or super()

	## 讓除式等於 0 的 x = a → 除式 x − a 的寫法（a 可以是 −3、1/2）
	static func _divisor(x: String) -> String:
		var s := x.strip_edges()
		if s.begins_with("−") or s.begins_with("-"):
			return "x + " + s.substr(1)
		return "x − " + s if s != "0" else "x"

	# ---------- 背景 ----------
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("1a1430"), Color("1a1430"), Color("0e0b1c"), Color("0e0b1c")]))
		if w < 100.0 or h < 100.0:
			return
		if _walls.is_empty() or not is_equal_approx(float(_walls[0]), w + h):
			_walls = [w + h, _wall_polys(w, h)]
		for p in _walls[1]:
			draw_colored_polygon(p, Color(0.16, 0.12, 0.26, 0.9))
		# 石廊裡慢慢擴散的回音環
		var rings := 3
		for k in rings:
			var ph := fposmod(t * 0.25 + k / float(rings), 1.0)
			draw_arc(Vector2(w - 30.0, h * 0.5), 40.0 + ph * w * 0.5, PI * 0.7, PI * 1.3, 24,
				Color(ECHO.r, ECHO.g, ECHO.b, 0.07 * (1.0 - ph)), 2.0, true)
		_draw_waves()
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	## 兩側的岩壁和上方的鐘乳石
	static func _wall_polys(w: float, h: float) -> Array:
		var out := []
		for side in [0, 1]:
			var pts := PackedVector2Array()
			var x_edge := 0.0 if side == 0 else w
			var dir := 1.0 if side == 0 else -1.0
			pts.append(Vector2(x_edge, 0))
			for i in 13:
				var y := h * i / 12.0
				var d := 16.0 + 6.0 * sin(i * 1.9 + side * 2.0) + 4.0 * sin(i * 0.7)
				pts.append(Vector2(x_edge + dir * d, y))
			pts.append(Vector2(x_edge, h))
			out.append(pts)
		for i in 9:
			var x := w * (i + 0.5) / 9.0 + 14.0 * sin(i * 2.3)
			var len := 16.0 + 14.0 * absf(sin(i * 1.3))
			out.append(PackedVector2Array([Vector2(x - 9.0, 0), Vector2(x + 9.0, 0), Vector2(x + 1.0, len)]))
		return out

	## 聲波：喊出去（往右的弧）、回音（往左的弧）。畫在最上面「推導紀錄」那一列的右邊（不擋住推導）
	const WAVE_Y := 26.0
	const WAVE_X0 := 170.0

	func _draw_waves() -> void:
		var w := size.x
		var y := WAVE_Y
		var st := t - shout_t
		if st >= 0.0 and st < 1.4:
			var x := lerpf(WAVE_X0, w - 40.0, st / 1.4)
			for k in 4:
				var xx := x - k * 12.0
				if xx > WAVE_X0:
					draw_arc(Vector2(xx - 18.0, y), 18.0, -0.7, 0.7, 10, Color(1, 0.9, 0.6, 0.5 * (1.0 - st / 1.4) * (1.0 - k * 0.2)), 3.0, true)
		var et := t - echo_t
		if et >= 0.0 and et < 1.4 and echo_val != "0":
			var x2 := lerpf(w - 40.0, WAVE_X0, et / 1.4)
			for k in 4:
				var xx2 := x2 + k * 12.0
				if xx2 < w - 40.0:
					draw_arc(Vector2(xx2 + 18.0, y), 18.0, PI - 0.7, PI + 0.7, 10, Color(ECHO.r, ECHO.g, ECHO.b, 0.6 * (1.0 - et / 1.4) * (1.0 - k * 0.2)), 3.0, true)

	# ---------- 前景：波上的字 ----------
	func _draw() -> void:
		super()
		if kind != "forge" or done:      # 推導完成時，上面那一列是「推導完成！」，不要疊字
			return
		var font := get_theme_default_font()
		var w := size.x
		var y := WAVE_Y + 8.0
		var st := t - shout_t
		if st >= 0.0 and st < 1.4:
			var x := lerpf(WAVE_X0 + 40.0, w - 80.0, st / 1.4)
			MathLabel.draw_on(self, font, x, y, "喊 x = " + shout_x, UITheme.fs(18), Color(1, 0.9, 0.6, 1.0 - st / 1.4))
		var et := t - echo_t
		if et >= 0.0 and et < 2.4:
			var a := clampf(2.4 - et, 0.0, 1.0)
			if echo_val == "0":
				# 安靜的回音：沒有聲音傳回來 ⇒ 除式是因式
				var c := UITheme.GOOD
				MathLabel.draw_on(self, font, w - 170.0, y, "……沒有回音：%s 是因式" % _divisor(echo_x), UITheme.fs(17),
					Color(c.r, c.g, c.b, a))
			else:
				var x2 := lerpf(w - 60.0, w - 150.0, clampf(et / 1.0, 0.0, 1.0))
				MathLabel.draw_on(self, font, x2, y, "回音 f(%s) = %s" % [echo_x, echo_val], UITheme.fs(18), Color(ECHO.r, ECHO.g, ECHO.b, a).lightened(0.2))

	# ---------- 回音圖 ----------
	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if eg.is_empty() or on or not done_spec.is_empty():
			super(font, rect)
			return
		_draw_echograph(font, rect)

	func _draw_echograph(font: Font, rect: Rect2) -> void:
		var pts: Array = eg.pts
		var cv: Array = eg.get("curve", [0.0, 0.0, 0.0])
		var show_curve := step > int(eg.get("after", 99))
		var xs := []
		var ys := [0.0]
		for p in pts:
			xs.append(float(p[0]))
			ys.append(float(p[1]))
		var lo := minf(xs.min(), 0.0)
		var hi := maxf(xs.max(), 0.0)
		var pad := maxf(0.8, 0.25 * (hi - lo))
		var xr := Vector2(lo - pad, hi + pad)
		var fx := func(x: float) -> float: return float(cv[0]) * x * x + float(cv[1]) * x + float(cv[2])
		for i in 41:
			ys.append(fx.call(lerpf(xr.x, xr.y, i / 40.0)) if show_curve else 0.0)
		var ymin: float = ys.min()
		var ymax: float = ys.max()
		var yp := maxf(1.0, 0.15 * (ymax - ymin))
		var yr := Vector2(ymin - yp, ymax + yp)
		var area := Rect2(rect.position + Vector2(10, 4), rect.size - Vector2(20, 12))
		var to := func(x: float, yv: float) -> Vector2:
			return Vector2(area.position.x + (x - xr.x) / (xr.y - xr.x) * area.size.x,
				area.position.y + area.size.y - (yv - yr.x) / (yr.y - yr.x) * area.size.y)
		draw_rect(rect, Color(0.08, 0.06, 0.16, 0.6))
		draw_rect(rect, Color(ECHO.r, ECHO.g, ECHO.b, 0.35), false, 1.0)
		MathLabel.draw_text(self, font, rect.position + Vector2(4, -10), "回音圖：點 (a, f(a))", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(0.85, 0.75, 1.0, 0.8))
		# 座標軸
		var ax := Color(1, 1, 1, 0.35)
		draw_line(to.call(xr.x, 0.0), to.call(xr.y, 0.0), ax, 1.5)
		if xr.x < 0.0 and xr.y > 0.0:
			draw_line(to.call(0.0, yr.x), to.call(0.0, yr.y), ax, 1.5)
		var fs := UITheme.fs(13)
		# 餘式的圖形
		if show_curve:
			var poly := PackedVector2Array()
			for i in 61:
				var x := lerpf(xr.x, xr.y, i / 60.0)
				poly.append(to.call(x, fx.call(x)))
			draw_polyline(poly, Color(UITheme.CYAN.r, UITheme.CYAN.g, UITheme.CYAN.b, 0.9), 2.5, true)
			var ci: Array = [int(round(float(cv[0]))), int(round(float(cv[1]))), int(round(float(cv[2])))]
			while ci.size() > 1 and ci[0] == 0:
				ci.pop_front()
			MathLabel.draw_on(self, font, area.position.x + area.size.x * 0.22, area.position.y + 16.0,
				"餘式 y = " + BankP2.poly_text(ci), UITheme.fs(16), UITheme.CYAN.lightened(0.3))
		# 回音點
		for p in pts:
			if step <= int(p[2]):
				continue
			var pp: Vector2 = to.call(float(p[0]), float(p[1]))
			var base: Vector2 = to.call(float(p[0]), 0.0)
			draw_dashed_line(base, pp, Color(ECHO.r, ECHO.g, ECHO.b, 0.5), 1.5, 5.0)
			var pulse := 1.0 + 0.15 * sin(t * 3.0)
			UITheme.dot(self, pp, 9.0 * pulse, Color(ECHO.r, ECHO.g, ECHO.b, 0.25))
			UITheme.dot(self, pp, 5.0, UITheme.GOLD)
			var lab := "(%s, %s)" % [_num(float(p[0])), _num(float(p[1]))]
			var lw := MathLabel.text_width(font, lab, fs)
			var lx := pp.x + 12.0 + lw / 2.0
			if lx + lw / 2.0 > area.end.x:
				lx = pp.x - 12.0 - lw / 2.0
			MathLabel.draw_on(self, font, lx, pp.y + fs * 0.35, lab, fs, Color(1, 0.9, 0.6))

	static func _num(v: float) -> String:
		var s := ""
		if is_equal_approx(v, roundf(v)):
			s = str(absi(int(roundf(v))))
		elif is_equal_approx(v * 2.0, roundf(v * 2.0)):
			s = "%d/2" % absi(int(roundf(v * 2.0)))
		else:
			s = str(absf(snappedf(v, 0.01)))
		return ("−" if v < -0.001 else "") + s
