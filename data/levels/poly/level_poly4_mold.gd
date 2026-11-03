extends "res://data/levels/poly/level_poly3_echo.gd"
## 多項式 第四大關「根之鑄模」（對應講義 4-1 重點四：求多項式）
## 引擎是 step_level.gd，畫面沿用第三關的 EchoView（代數時的回音動畫），題庫在 poly4_bank.gd。
##
## 這一關多了：
##   ・鑄模（題目帶 "mold"）：選好「怎麼假設」之後，下方出現模具，上面刻著假設式，未知數是空的模穴。
##     每算出一個未知數，熔液就倒進那一格；全部填滿時整個式子「鑄成」。
##   ・看圖題（題目帶 "cubic"）：下方左邊畫出三次函數的部分圖形，標出和 x 軸的交點與另一個點，右邊是鑄模。
##   ・鑄造工坊的背景（深紅褐色的岩壁、底部的熔爐、滴落的熔液）
##   ・速算：已知根和一個點，求首項係數或函數值

const BankP4 := preload("res://data/levels/poly/poly4_bank.gd")
const MOLTEN := UITheme.ORANGE

const CHAPTERS_P4 := [
	{"ch": 1, "name": "第一章．根的鑄模", "topic": "利用根令式、同值令式、牛頓階梯假設法", "color": UITheme.ORANGE},
	{"ch": 2, "name": "第二章．餘式的鑄模", "topic": "利用餘式令式", "color": UITheme.GOLD},
]


func level_id() -> String:
	return "P4"

func level_title() -> String:
	return "根之鑄模"

func level_subtitle() -> String:
	return "求多項式"

func level_chapters() -> Array:
	return CHAPTERS_P4

func bank_slots() -> Array:
	return BankP4.slots()

func step_color() -> Color:
	return MOLTEN

func stage_style() -> Dictionary:
	return {"sky_top": Color("2a1410"), "sky_bot": Color("140a08"), "scenery": "none", "ambient": "currents"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．餘式的鑄模", "button": "走進餘式的鑄模  ▶",
		"text": "這一章的模具是除式：\n\n" \
			+ "・f(x) 除以 g(x) 餘 r(x) ⇒ f(x) = g(x)·q(x) + r(x)\n" \
			+ "・商式 q(x) 的次數 = f 的次數 − g 的次數\n" \
			+ "・代點求商式的係數，解聯立用加減消去\n" \
			+ "・兩個除式只差一個常數：改寫之後比較餘式\n\n" \
			+ "熔爐點火！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = MoldView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "鑄模速算"
		fview.speed_y = 0.42


# ================= 速算 =================

func _speed_tag() -> String:
	return BankP4.T_ROOT


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算題：一步就能算完（{eq, q, template, ans, nudge, tag}）
##   0：已知首項係數 k 和兩根 ⇒ 代一個數
##   1：已知兩根和 f(0) ⇒ 求首項係數（f(0) = k·p·q）
##   2：首項係數 1 的三次式，已知三根 ⇒ 常數項（= f(0)）
static func gen_problems(_kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var kind := out.size() % 3
		var p := randi_range(-3, 3)
		var q := randi_range(-3, 3)
		if p >= q:
			continue
		var fx := ("f(x) = k(x %s)(x %s)" % [_sgn(-p), _sgn(-q)]).replace("(x )", "x")
		var pb := {}
		match kind:
			0:
				var k: int = [-2, -1, 1, 2, 3].pick_random()
				var r := randi_range(-2, 4)
				if r == p or r == q:
					continue
				var v := k * (r - p) * (r - q)
				pb = {"eq": "二次式 f(x) 的首項係數為 %s，f(%s) = f(%s) = 0\nf(%s) = ？" % [_n(k), _n(p), _n(q), _n(r)], "ans": str(v),
					"q": fx.replace("k", _n(k) if absi(k) != 1 else ("−" if k < 0 else "")) + "，代 x = %s。" % _n(r),
					"template": "f(%s) = [0]" % _n(r)}
			1:
				if p == 0 or q == 0:
					continue
				var k2: int = [-2, -1, 1, 2, 3].pick_random()
				var v2 := k2 * p * q
				pb = {"eq": "二次式 f(x)：f(%s) = f(%s) = 0，f(0) = %s\n首項係數 = ？" % [_n(p), _n(q), _n(v2)], "ans": str(k2),
					"q": fx + "，代 x = 0：k × (%s) × (%s) = %s。" % [_n(-p), _n(-q), _n(v2)], "template": "k = [0]"}
			2:
				var r3 := randi_range(-3, 3)
				if r3 <= q or p == 0 or q == 0 or r3 == 0:      # 三個根由小到大、都不是 0（常數項才不會是 0）
					continue
				var c := -p * q * r3
				pb = {"eq": "三次式 f(x) 的首項係數為 1，三個根是 %s、%s、%s\n常數項 = ？" % [_n(p), _n(q), _n(r3)], "ans": str(c),
					"q": "f(x) = (x − 根)(x − 根)(x − 根)，常數項 = f(0) = (%s) × (%s) × (%s)。" % [_n(-p), _n(-q), _n(-r3)], "template": "常數項 = [0]"}
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		pb["nudge"] = pb.q
		pb["tag"] = BankP4.T_ROOT
		out.append(pb)
	return out


static func _n(v: int) -> String:
	return str(v).replace("-", "−")


## x − p 的寫法：_sgn(−p) → "− 2"、"+ 3"、"+ 0"
static func _sgn(v: int) -> String:
	if v == 0:
		return ""
	return ("+ %d" % v) if v > 0 else ("− %d" % -v)


# ================= 畫面：鑄造工坊 + 鑄模 =================

class MoldView extends EchoView:
	const HOT := Color("ff8a3d")
	const GLOWC := Color("ffcf5a")

	var mold := {}               # {form, after, holes: [[名字, 值, 第幾步之後]…]}
	var cubic := {}              # {roots, k, pt}
	var pour_t := {}             # 未知數 → 熔液開始倒的時間
	var cast_t := -10.0          # 全部鑄成的時間
	var drips := []              # 熔液滴（快取的位置）

	func setup(round: Dictionary) -> void:
		super(round)
		var forge := String(round.get("type", "")) == "forge"
		mold = round.get("mold", {}) if forge else {}
		cubic = round.get("cubic", {}) if forge else {}
		pour_t = {}
		cast_t = -10.0

	func _graph_on() -> bool:
		return not mold.is_empty() or not cubic.is_empty() or super()

	# ---------- 背景 ----------
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		if w < 100.0 or h < 100.0:
			return
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("2a1410"), Color("2a1410"), Color("140a08"), Color("140a08")]))
		# 底部熔爐的光
		var glow := 0.16 + 0.04 * sin(t * 1.7)
		draw_polygon(PackedVector2Array([Vector2(0, h * 0.7), Vector2(w, h * 0.7), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color(1, 0.45, 0.15, 0.0), Color(1, 0.45, 0.15, 0.0), Color(1, 0.4, 0.1, glow), Color(1, 0.4, 0.1, glow)]))
		# 兩側滴落的熔液
		var lines := PackedVector2Array()
		for side in [18.0, w - 18.0]:
			for k in 6:
				var y := fposmod(t * 70.0 + k * 97.0 + side, h + 30.0) - 15.0
				var x: float = side + 6.0 * sin(k * 2.1)
				lines.append_array([Vector2(x, y), Vector2(x, y + 9.0)])
		draw_multiline(lines, Color(1, 0.55, 0.2, 0.35), 3.0)
		_draw_waves()
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	# ---------- 下方：看圖 + 鑄模 ----------
	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if on or not done_spec.is_empty() or (mold.is_empty() and cubic.is_empty()):
			super(font, rect)
			return
		if not cubic.is_empty() and not mold.is_empty():
			var half := rect.size.x * 0.5 - 6.0
			_draw_cubic(font, Rect2(rect.position, Vector2(half, rect.size.y)))
			_draw_mold(font, Rect2(rect.position + Vector2(half + 12.0, 0), Vector2(half, rect.size.y)))
		elif not cubic.is_empty():
			_draw_cubic(font, rect)
		else:
			_draw_mold(font, rect)

	func _cubic_y(x: float) -> float:
		var v := float(cubic.k)
		for r in cubic.roots:
			v *= x - float(r)
		return v

	## 看圖題：三次函數的部分圖形（標出和 x 軸的交點、另一個點），不寫出式子
	func _draw_cubic(font: Font, rect: Rect2) -> void:
		var roots: Array = cubic.roots
		var lo: float = float(roots.min()) - 1.2
		var hi: float = float(roots.max()) + 1.2
		var ys := [0.0]
		for i in 81:
			ys.append(_cubic_y(lerpf(lo, hi, i / 80.0)))
		var pt: Array = cubic.get("pt", [0.0, 0.0])
		# y 的範圍：兩個極值附近再放寬一點（兩端太大的部分剪掉）
		var inner := []
		for i in 81:
			var xx := lerpf(roots.min(), roots.max(), i / 80.0)
			inner.append(_cubic_y(xx))
		var ymax: float = maxf(float(inner.max()), float(pt[1])) * 1.35 + 1.0
		var ymin: float = minf(float(inner.min()), float(pt[1])) * 1.35 - 1.0
		var area := Rect2(rect.position + Vector2(8, 6), rect.size - Vector2(16, 14))
		var to := func(x: float, y: float) -> Vector2:
			return Vector2(area.position.x + (x - lo) / (hi - lo) * area.size.x,
				area.position.y + area.size.y - (y - ymin) / (ymax - ymin) * area.size.y)
		draw_rect(rect, Color(0.1, 0.05, 0.03, 0.6))
		draw_rect(rect, Color(HOT.r, HOT.g, HOT.b, 0.35), false, 1.0)
		MathLabel.draw_text(self, font, rect.position + Vector2(4, -10), "y = f(x) 的部分圖形", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(1, 0.8, 0.6, 0.8))
		var ax := Color(1, 1, 1, 0.4)
		draw_line(to.call(lo, 0.0), to.call(hi, 0.0), ax, 1.5)
		if lo < 0.0 and hi > 0.0:
			draw_line(to.call(0.0, ymin), to.call(0.0, ymax), ax, 1.5)
			MathLabel.draw_on(self, font, to.call(0.0, 0.0).x - 9.0, to.call(0.0, 0.0).y + 16.0, "O", UITheme.fs(12), Color(1, 1, 1, 0.6))
		# 曲線（超出範圍的地方斷開）
		var seg := PackedVector2Array()
		for i in 121:
			var x := lerpf(lo, hi, i / 120.0)
			var y := _cubic_y(x)
			if y < ymin or y > ymax:
				if seg.size() > 1:
					draw_polyline(seg, Color(1, 0.7, 0.35, 0.95), 2.5, true)
				seg = PackedVector2Array()
				continue
			seg.append(to.call(x, y))
		if seg.size() > 1:
			draw_polyline(seg, Color(1, 0.7, 0.35, 0.95), 2.5, true)
		var fs := UITheme.fs(12)
		for r in roots:
			var p: Vector2 = to.call(float(r), 0.0)
			UITheme.dot(self, p, 4.5, GLOWC)
			MathLabel.draw_on(self, font, p.x + 22.0, p.y + 16.0, "(%s, 0)" % _num(float(r)), fs, Color(1, 0.9, 0.7))
		var pp: Vector2 = to.call(float(pt[0]), float(pt[1]))
		UITheme.dot(self, pp, 4.5, UITheme.CYAN)
		MathLabel.draw_on(self, font, pp.x + 34.0, pp.y + 4.0, "(%s, %s)" % [_num(float(pt[0])), _num(float(pt[1]))], fs, UITheme.CYAN.lightened(0.3))

	static func _num(v: float) -> String:
		var s := str(absi(int(roundf(v)))) if is_equal_approx(v, roundf(v)) else str(absf(snappedf(v, 0.01)))
		return ("−" if v < -0.001 else "") + s

	## 鑄模：上面刻著假設式（未知數發光），下面一排模穴，算出來的未知數倒進熔液
	func _draw_mold(font: Font, rect: Rect2) -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.13, 0.07, 0.05, 0.85)
		var all_done := _all_cast()
		var bc := GLOWC if all_done else HOT
		var pulse := 0.55 + 0.25 * sin(t * 3.0) if all_done else 0.45
		sb.border_color = Color(bc.r, bc.g, bc.b, pulse)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(14)
		sb.anti_aliasing = true
		draw_style_box(sb, rect)
		MathLabel.draw_text(self, font, rect.position + Vector2(4, -10), "鑄模", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(1, 0.8, 0.6, 0.8))
		var cx := rect.get_center().x
		if step <= int(mold.after):
			MathLabel.draw_on(self, font, cx, rect.get_center().y, "選好「怎麼假設」，模具就會出現", UITheme.fs(16), Color(1, 0.85, 0.7, 0.55))
			return
		var holes: Array = mold.holes
		# 假設式：還沒算出來的未知數用橘色，算出來的用金色
		var form := String(mold.form)
		for hl in holes:
			var solved := step > int(hl[2])
			var c: Color = GLOWC if solved else HOT
			form = form.replace("{%s}" % hl[0], "[color=#%s]%s[/color]" % [c.to_html(false), hl[0]])
		var fs := UITheme.fs(20)
		while fs > 12 and MathLabel.text_width(font, form, fs) > rect.size.x - 24.0:
			fs -= 1
		MathLabel.draw_on(self, font, cx, rect.position.y + 46.0, form, fs, Color(1, 0.95, 0.88))
		# 模穴
		var n := holes.size()
		var bw := minf(120.0, (rect.size.x - 24.0 - 10.0 * (n - 1)) / n)
		var bh := 46.0
		var x0 := cx - (bw * n + 10.0 * (n - 1)) / 2.0
		var y0 := rect.position.y + 84.0
		for i in n:
			var hl: Array = holes[i]
			var box := Rect2(x0 + i * (bw + 10.0), y0, bw, bh)
			var solved := step > int(hl[2])
			draw_rect(box, Color(0.05, 0.03, 0.02, 0.9))
			if solved:
				if not pour_t.has(hl[0]):
					pour_t[hl[0]] = t
				var k := clampf((t - float(pour_t[hl[0]])) / 0.6, 0.0, 1.0)
				var fh := bh * k
				var top := Color(1, 0.8, 0.35, 0.95)
				var bot := Color(1, 0.45, 0.12, 0.95)
				draw_polygon(PackedVector2Array([Vector2(box.position.x, box.end.y - fh), Vector2(box.end.x, box.end.y - fh), box.end, Vector2(box.position.x, box.end.y)]),
					PackedColorArray([top, top, bot, bot]))
				draw_rect(box, GLOWC, false, 2.0)
				MathLabel.draw_on(self, font, box.get_center().x, box.get_center().y + 7.0, "%s = %s" % [hl[0], hl[1]], UITheme.fs(18),
					Color(0.2, 0.08, 0.02) if k >= 1.0 else Color(1, 1, 1, 0.9))
			else:
				draw_rect(box, Color(HOT.r, HOT.g, HOT.b, 0.6), false, 1.5)
				MathLabel.draw_on(self, font, box.get_center().x, box.get_center().y + 7.0, "%s = ?" % hl[0], UITheme.fs(18), Color(1, 0.75, 0.55, 0.8))
		if all_done:
			if cast_t < 0.0:
				cast_t = t
			var a := clampf((t - cast_t) / 0.5, 0.0, 1.0)
			MathLabel.draw_on(self, font, cx, rect.end.y - 18.0, "鑄成！", UITheme.fs(18), Color(GLOWC.r, GLOWC.g, GLOWC.b, a))

	func _all_cast() -> bool:
		if mold.is_empty() or step <= int(mold.after):
			return false
		for hl in mold.holes:
			if step <= int(hl[2]):
				return false
		return true
