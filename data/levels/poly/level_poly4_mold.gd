extends "res://data/levels/poly/level_poly3_echo.gd"
## 多項式 第四大關「根之鑄模」（對應講義 4-1 重點四：求多項式）
## 引擎是 step_level.gd，畫面沿用第三關的 EchoView（代數時的回音動畫），題庫在 poly4_bank.gd。
##
## 這一關多了：
##   ・鑄模（題目帶 "mold"）：選好「怎麼假設」之後，下方出現模具，上面刻著假設式，未知數是空的模穴。
##     每算出一個未知數，熔液就倒進那一格；全部填滿時整個式子「鑄成」。
##   ・看圖題（題目帶 "cubic"）：下方左邊畫出三次函數的部分圖形，標出和 x 軸的交點與另一個點，右邊是鑄模。
##   ・圖形操作（題庫的 probe 步驟，引擎沿用第三關）：
##       pins     游標移到圖形和 x 軸的交點，標記根
##       stretch  轉動首項係數 k，曲線即時跟著變，讓它通過指定的點（驗算自己算的 k）
##       shift    調 m，畫出 f(x) − m 的點：幾個一樣高的點一起往下，落在 x 軸上就變成根
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
	return {"sky_top": Color("3a170f"), "sky_bot": Color("170807"), "scenery": "none", "ambient": ""}     # 粒子畫在 Scenery 背景裡

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
		(fview as MoldView).echo_word = ""
		(fview as MoldView).echo_head = "代入："


# ================= 圖形操作（pins、stretch、shift） =================

func _probe_btn(mode: String) -> String:
	match mode:
		"pins":
			return "標記這個根"
		"stretch":
			return "就是這個 k"
		"shift":
			return "就是這個 m"
	return super(mode)


func _probe_hint() -> String:
	return "拖動下方的數線（或右邊的滑桿），再按「%s」。"


func _probe_var(mode: String) -> String:
	match mode:
		"stretch":
			return "k"
		"shift":
			return "m"
	return super(mode)


func _probe_center(ev: EchoView) -> String:
	var st := ev.probe
	match String(st.get("mode", "")):
		"pins":
			return "求：圖形和 x 軸的所有交點（找到 %d／%d 個根）" % [ev.marks.size(), st.roots.size()]
		"stretch":
			return "驗算：k 是多少時，曲線通過 (%s, %s)？" % [BankP4._n(st.pt[0]), BankP4._n(st.pt[1])]
		"shift":
			return "求：f(x) − m 在這幾個點都是 0 的 m"
	return ""


func _probe_submit(st: Dictionary) -> void:
	var ev := _ev()
	var den := int(st.get("den", 1))
	match String(st.mode):
		"pins":
			var v := ev.probe_value()
			if absf(v) > 1e-9:
				_wrong(st, "x = %s 不是交點：圖形在這裡不在 x 軸上（f(%s) ≠ 0）。提示：%s" % [EchoView.xs(ev.px, den), EchoView.xs(ev.px, den), st.nudge])
				return
			for m in ev.marks:
				if absf(float(m) - ev.px) < 1e-6:
					_hint("這個根已經標記過了，找找別的交點。", "info")
					return
			ev.marks.append(ev.px)
			Game.of(self).sfx("correct")
			_on_probe_move()
			if ev.marks.size() >= st.roots.size():
				_probe_done(st, "", "")
			else:
				_hint("✓ f(%s) = 0：x = %s 是根，%s 是因式！還有 %d 個。" % [EchoView.xs(ev.px, den), EchoView.xs(ev.px, den),
					EchoView.divisor_of(ev.px, den), st.roots.size() - ev.marks.size()], "good")
		"stretch", "shift":
			var goal := EchoView.parse(String(st.goal))
			if absf(ev.px - goal) < 1e-9:
				Game.of(self).sfx("correct")
				_probe_done(st, "", "")
				return
			var what := "曲線還沒有通過 (%s, %s)" % [BankP4._n(st.pt[0]), BankP4._n(st.pt[1])] if String(st.mode) == "stretch" else "點還沒有全部落在 x 軸上"
			_wrong(st, "%s = %s 時%s。提示：%s" % [_probe_var(String(st.mode)), EchoView.xs(ev.px, den), what, st.nudge])
		_:
			super(st)


# ================= 速算 =================

func _speed_tag() -> String:
	return BankP4.T_ROOT


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算題：中間是題目，下面的填空寫出算式的「架子」，學生自己填代入的數再算（{eq, q, template, answers, ans, mode, nudge, tag}）
##   0：已知首項係數 k 和兩根 ⇒ f(r) = k × (r − p) × (r − q)
##   1：已知兩根和 f(0) ⇒ k × (0 − p) × (0 − q) = f(0)
##   2：首項係數 1 的三次式，已知三根 ⇒ 常數項 = f(0) = (0 − p)(0 − q)(0 − r)
##   括號的順序不限、最後一格是答案（mode = "perm"）；右邊的提示只講觀念，不直接寫出式子
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
		var pb := {}
		match kind:
			0:
				var k: int = [-2, -1, 2, 3].pick_random()
				var r := randi_range(-2, 4)
				if r == p or r == q:
					continue
				var v := k * (r - p) * (r - q)
				pb = {"eq": "二次式 f(x) 的首項係數為 %s，f(%s) = f(%s) = 0\nf(%s) = ？" % [_n(k), _n(p), _n(q), _n(r)],
					"answers": [str(r - p), str(r - q), str(v)], "ans": str(v),
					"template": "%s × ([0]) × ([1]) = [2]" % _paren(k),
					"q": "f(a) = 0 ⇒ x − a 是因式。把 x = %s 代入每個因式。" % _n(r),
					"nudge": "f(x) = 首項係數 × (x − 根) × (x − 根)，再代入 x = %s。" % _n(r)}
			1:
				if p == 0 or q == 0:
					continue
				var k2: int = [-2, -1, 1, 2, 3].pick_random()
				var v2 := k2 * p * q
				pb = {"eq": "二次式 f(x)：f(%s) = f(%s) = 0，f(0) = %s\n首項係數 k = ？" % [_n(p), _n(q), _n(v2)],
					"answers": [str(-p), str(-q), str(k2)], "ans": str(k2),
					"template": "k([0])([1]) = %s，k = [2]" % _n(v2),
					"q": "f(a) = 0 ⇒ x − a 是因式。設 f(x) = k(x − 根)(x − 根)，代入 x = 0。",
					"nudge": "代入 x = 0：每個因式變成 0 − 根。"}
			2:
				var r3 := randi_range(-3, 3)
				if r3 <= q or p == 0 or q == 0 or r3 == 0:
					continue
				var c := -p * q * r3
				pb = {"eq": "三次式 f(x) 的首項係數為 1，三個根是 %s、%s、%s\n常數項 = ？" % [_n(p), _n(q), _n(r3)],
					"answers": [str(-p), str(-q), str(-r3), str(c)], "ans": str(c),
					"template": "([0]) × ([1]) × ([2]) = [3]",
					"q": "根 a ⇒ 因式 x − a。常數項 = f(0)，把 x = 0 代入每個因式。",
					"nudge": "代入 x = 0：每個因式變成 0 − 根。"}
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		pb["mode"] = "perm"
		pb["tag"] = BankP4.T_ROOT
		out.append(pb)
	return out


## 首項係數寫在乘號前面：負數加括號
static func _paren(v: int) -> String:
	return "(%s)" % _n(v) if v < 0 else str(v)


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
		# 這一關自己的背景（data/ui/scenery.gd）
		Scenery.paint(self, "mold", size, t)
		if size.x >= 100.0 and size.y >= 100.0:
			_draw_waves()
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	# ---------- 下方：看圖 + 鑄模 ----------
	func probe_value() -> float:
		if not probe.is_empty() and String(probe.mode) == "pins":
			return _curve_y(probe.curve, float(probe.curve.k), 0.0, px)
		return super()

	static func _curve_y(cv: Dictionary, k: float, m: float, x: float) -> float:
		var v := k
		for r in cv.roots:
			v *= x - float(r)
		return v + m

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if not probe.is_empty() and kind == "forge" and String(probe.mode) in ["pins", "stretch", "shift"]:
			_draw_graph_probe(font, _probe_rect())
			return
		if not probe.is_empty():
			super(font, rect)
			return
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

	## 圖形操作的畫面：pins（游標找交點）、stretch（轉動 k）、shift（f(x) − m）
	func _draw_graph_probe(font: Font, rc: Rect2) -> void:
		var mode := String(probe.mode)
		var den := int(probe.get("den", 1))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.05, 0.03, 0.7)
		sb.border_color = Color(HOT.r, HOT.g, HOT.b, 0.45)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(14)
		sb.anti_aliasing = true
		draw_style_box(sb, rc)
		var head: String = {"pins": "圖形和 x 軸的交點 = 根", "stretch": "轉動首項係數 k", "shift": "f(x) − m 的點"}.get(mode, "")
		MathLabel.draw_text(self, font, rc.position + Vector2(4, -10), head, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(1, 0.8, 0.6, 0.85))
		var fs := UITheme.fs(13)
		var ax := Color(1, 1, 1, 0.4)
		if mode == "pins":
			# 圖形的 x 和數線一樣（拖動的位置就是 x）
			var cv: Dictionary = probe.curve
			var rg := _range()
			var ys := []
			for i in 61:
				ys.append(_curve_y(cv, float(cv.k), 0.0, lerpf(float(cv.roots.min()), float(cv.roots.max()), i / 60.0)))
			var top: float = maxf(float(ys.max()), 1.0) * 1.3
			var bot: float = minf(float(ys.min()), -1.0) * 1.3
			var y0 := rc.position.y + 14.0
			var y1 := rc.end.y - 30.0
			var to := func(x: float, y: float) -> Vector2: return Vector2(_x_at(x), lerpf(y1, y0, (y - bot) / (top - bot)))
			var yl: float = to.call(0.0, 0.0).y
			draw_line(Vector2(_line_x0() - 14.0, yl), Vector2(_line_x1() + 14.0, yl), ax, 1.5)
			for i in int(rg.y - rg.x) + 1:
				var v := rg.x + i
				var p: Vector2 = to.call(v, 0.0)
				draw_line(p - Vector2(0, 5), p + Vector2(0, 5), ax, 1.5)
				MathLabel.draw_on(self, font, p.x, rc.end.y - 10.0, xs(v, 1), fs, Color(1, 1, 1, 0.6))
			var seg := PackedVector2Array()
			for i in 121:
				var x := lerpf(rg.x, rg.y, i / 120.0)
				var y := _curve_y(cv, float(cv.k), 0.0, x)
				if y < bot or y > top:
					if seg.size() > 1:
						draw_polyline(seg, Color(1, 0.7, 0.35, 0.95), 2.5, true)
					seg = PackedVector2Array()
					continue
				seg.append(to.call(x, y))
			if seg.size() > 1:
				draw_polyline(seg, Color(1, 0.7, 0.35, 0.95), 2.5, true)
			for m in marks:
				var mp: Vector2 = to.call(float(m), 0.0)
				draw_line(mp + Vector2(0, -16), mp + Vector2(0, 6), GLOWC, 3.0)
				UITheme.dot(self, mp + Vector2(0, -16), 5.0, GLOWC)
				MathLabel.draw_on(self, font, mp.x, mp.y - 26.0, divisor_of(float(m), 1), fs, GLOWC)
			# 游標
			var cx := _x_at(px)
			draw_dashed_line(Vector2(cx, y0), Vector2(cx, y1), Color(1, 1, 1, 0.5), 1.5, 6.0)
			var cy := _curve_y(cv, float(cv.k), 0.0, px)
			var on_axis := absf(cy) < 1e-9
			UITheme.dot(self, Vector2(cx, yl), 8.0, UITheme.GOOD if on_axis else Color(1, 1, 1, 0.8))
			var tag := "x = %s：碰到 x 軸 ⇒ 是根" % xs(px, den) if on_axis else "x = %s：不在 x 軸上" % xs(px, den)
			var tw := MathLabel.text_width(font, tag, UITheme.fs(15))
			var tx := clampf(cx, rc.position.x + tw / 2.0 + 10.0, rc.end.x - tw / 2.0 - 10.0)
			MathLabel.draw_on(self, font, tx, rc.position.y + 22.0, tag, UITheme.fs(15), UITheme.GOOD.lightened(0.2) if on_axis else Color(1, 0.9, 0.8))
			return
		# stretch / shift：上面是圖，下面是調 k（或 m）的數線
		var yl2 := rc.end.y - 30.0
		var rg2 := _range()
		draw_line(Vector2(_line_x0() - 10.0, yl2), Vector2(_line_x1() + 10.0, yl2), Color(1, 1, 1, 0.35), 2.0)
		var nt := int(roundf((rg2.y - rg2.x) * den))
		for i in nt + 1:
			var v := rg2.x + float(i) / den
			var tx2 := _x_at(v)
			var major := absf(v - roundf(v)) < 1e-6
			draw_line(Vector2(tx2, yl2 - (5.0 if major else 3.0)), Vector2(tx2, yl2 + (5.0 if major else 3.0)), Color(1, 1, 1, 0.4), 1.5)
			if major:
				MathLabel.draw_on(self, font, tx2, yl2 + 18.0, xs(v, 1), UITheme.fs(11), Color(1, 1, 1, 0.5))
		UITheme.dot(self, Vector2(_x_at(px), yl2), 9.0, GLOWC)
		MathLabel.draw_on(self, font, _line_x1() + 20.0, yl2 + 4.0, _var_name(), UITheme.fs(14), GOLD)
		var area := Rect2(rc.position.x + 20.0, rc.position.y + 30.0, rc.size.x - 40.0, yl2 - rc.position.y - 44.0)
		if mode == "stretch":
			var cv2: Dictionary = probe.curve
			var pt: Array = probe.pt
			var lo: float = float(cv2.roots.min()) - 1.0
			var hi: float = float(cv2.roots.max()) + 1.0
			var lim := maxf(absf(float(pt[1])) * 2.2, 6.0)
			var to2 := func(x: float, y: float) -> Vector2:
				return Vector2(lerpf(area.position.x, area.end.x, (x - lo) / (hi - lo)), lerpf(area.end.y, area.position.y, (y + lim) / (2.0 * lim)))
			draw_line(to2.call(lo, 0.0), to2.call(hi, 0.0), ax, 1.5)
			if lo < 0.0 and hi > 0.0:
				draw_line(to2.call(0.0, -lim), to2.call(0.0, lim), ax, 1.5)
			var seg2 := PackedVector2Array()
			for i in 121:
				var x := lerpf(lo, hi, i / 120.0)
				var y := _curve_y(cv2, px, float(cv2.m), x)
				if absf(y) > lim:
					if seg2.size() > 1:
						draw_polyline(seg2, Color(1, 0.7, 0.35, 0.95), 2.5, true)
					seg2 = PackedVector2Array()
					continue
				seg2.append(to2.call(x, y))
			if seg2.size() > 1:
				draw_polyline(seg2, Color(1, 0.7, 0.35, 0.95), 2.5, true)
			for r in cv2.roots:
				UITheme.dot(self, to2.call(float(r), float(cv2.m)), 4.0, GLOWC)
			var yv := _curve_y(cv2, px, float(cv2.m), float(pt[0]))
			var hit := absf(yv - float(pt[1])) < 1e-9
			var pp: Vector2 = to2.call(float(pt[0]), float(pt[1]))
			UITheme.dot(self, pp, 10.0 if hit else 7.0, UITheme.GOOD if hit else UITheme.CYAN)
			MathLabel.draw_on(self, font, pp.x + 40.0, pp.y + 4.0, "(%s, %s)" % [_num(float(pt[0])), _num(float(pt[1]))], fs, UITheme.CYAN.lightened(0.3))
			var msg := "k = %s：曲線通過 (%s, %s) ✓" % [xs(px, den), _num(float(pt[0])), _num(float(pt[1]))] if hit else \
				"k = %s：x = %s 時 y = %s" % [xs(px, den), _num(float(pt[0])), fmt(yv)]
			MathLabel.draw_on(self, font, rc.get_center().x, rc.position.y + 22.0, msg, UITheme.fs(15), UITheme.GOOD.lightened(0.2) if hit else Color(1, 0.9, 0.8))
		else:
			var pts: Array = probe.pts
			var xs_ := pts.map(func(q): return float(q[0]))
			var lo2: float = float(xs_.min()) - 1.5
			var hi2: float = float(xs_.max()) + 1.5
			var hmax := 0.0
			for q in pts:
				hmax = maxf(hmax, absf(float(q[1])))
			var lim2 := maxf(hmax * 1.4, 4.0)
			var to3 := func(x: float, y: float) -> Vector2:
				return Vector2(lerpf(area.position.x, area.end.x, (x - lo2) / (hi2 - lo2)), lerpf(area.end.y, area.position.y, (y + lim2 * 0.4) / (lim2 * 1.4)))
			draw_line(to3.call(lo2, 0.0), to3.call(hi2, 0.0), ax, 1.5)
			MathLabel.draw_on(self, font, to3.call(hi2, 0.0).x - 8.0, to3.call(hi2, 0.0).y - 8.0, "x", fs, Color(1, 1, 1, 0.5))
			var all_on := true
			for q in pts:
				var y := float(q[1]) - px
				var on0 := absf(y) < 1e-9
				all_on = all_on and on0
				var p0: Vector2 = to3.call(float(q[0]), float(q[1]))
				var p1: Vector2 = to3.call(float(q[0]), y)
				draw_dashed_line(p0, p1, Color(1, 0.8, 0.5, 0.35), 1.5, 5.0)
				UITheme.dot(self, p0, 3.5, Color(1, 1, 1, 0.3))
				UITheme.dot(self, p1, 7.0, UITheme.GOOD if on0 else GLOWC)
				MathLabel.draw_on(self, font, p1.x, p1.y - 12.0, "x = %s" % _num(float(q[0])), fs, UITheme.GOOD.lightened(0.2) if on0 else Color(1, 0.9, 0.7))
			var msg2 := "m = %s：f(x) − %s 在這些點都是 0 ⇒ 都是根 ✓" % [xs(px, den), xs(px, den)] if all_on else "m = %s：f(x) − m 的值是 %s" % [xs(px, den), fmt(float(pts[0][1]) - px)]
			MathLabel.draw_on(self, font, rc.get_center().x, rc.position.y + 22.0, msg2, UITheme.fs(15), UITheme.GOOD.lightened(0.2) if all_on else Color(1, 0.9, 0.8))

	func _var_name() -> String:
		return "m" if String(probe.get("mode", "")) == "shift" else "k"

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
			MathLabel.draw_on(self, font, cx, rect.get_center().y, "拼好假設，模具就會出現", UITheme.fs(16), Color(1, 0.85, 0.7, 0.55))
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
