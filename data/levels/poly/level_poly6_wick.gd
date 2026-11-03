extends "res://data/levels/poly/level_poly5_lake.gd"
## 多項式 第六大關「極值燈芯」（對應講義 4-2 重點三：二次函數的極值）
## 引擎是 step_level.gd，畫面沿用第五關的湖面座標圖，題庫在 poly6_bank.gd。
##
## 新的 graph 步驟：
##   wick    燈芯沿著拋物線走（可以有燈罩 win、不能走的 gap、只停整數 int），依序點亮 goals 指定的最高／最低點
##   window  拖動燈罩 [p, p + width]：依序讓罩子裡的最小值（或最大值）發生在 left／vertex／right
## 每一步中間的推導紀錄都寫出「求：…」，右邊有 ◀ ▶ 可以一格一格調。

const BankP6 := preload("res://data/levels/poly/poly6_bank.gd")
const WICK_C := Color("ffd27a")
const HI_C := "ff6b9d"    # 「最高」的顏色
const LO_C := "4fd8ff"    # 「最低」的顏色


## 把「最高」「最低」上色，一眼就看得到要找哪一個
static func hl_word(s: String) -> String:
	return s.replace("最高", "[color=#%s]最高[/color]" % HI_C).replace("最低", "[color=#%s]最低[/color]" % LO_C)

const CHAPTERS_P6 := [
	{"ch": 1, "name": "第一章．點亮燈芯", "topic": "配方求極值、平移、整數、限制範圍、反推係數", "color": Color("ffd27a")},
	{"ch": 2, "name": "第二章．換一盞燈", "topic": "代換、算幾、參數式、根與係數、加權平均、應用題", "color": UITheme.LIME},
]


func level_id() -> String:
	return "P6"

func level_title() -> String:
	return "極值燈芯"

func level_subtitle() -> String:
	return "二次函數的極值"

func level_chapters() -> Array:
	return CHAPTERS_P6

func bank_slots() -> Array:
	return BankP6.slots()

func step_color() -> Color:
	return WICK_C

func stage_style() -> Dictionary:
	return {"sky_top": Color("140f24"), "sky_bot": Color("0a0814"), "scenery": "none", "ambient": "currents"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．換一盞燈", "button": "換一盞燈  ▶",
		"text": "有些燈芯藏在別的式子裡：\n\n" \
			+ "・代換：t = x^{2} − 2x、t = x + \\frac{1}{x}，先找 t 的範圍\n" \
			+ "・兩個變數：用直線或根與係數換成一個變數\n" \
			+ "・加權平均數：一群平方和的最小值\n" \
			+ "・應用題：利潤、面積的最大值\n\n" \
			+ "準備換燈！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = WickView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "燈芯速算"
		fview.speed_y = 0.42


func _wv() -> WickView:
	return fview as WickView


# ================= graph 步驟 =================

func _build_graph(st: Dictionary) -> void:
	super(st)
	var mode := String(st.mode)
	if mode == "match" and st.get("a_list", []).size() <= 1:
		for ch in rank_box.get_children():
			if ch is HBoxContainer and ch.get_child_count() > 0 and ch.get_child(0) is Label and (ch.get_child(0) as Label).text == "開口 a":
				ch.queue_free()
	if not (mode in ["wick", "window"]):
		return
	var lv := _wv()
	var cap_txt := "燈罩" if mode == "window" else String(st.get("xname", "x"))
	var key := "p" if mode == "window" else "x"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	rank_box.add_child(row)
	var cap := Label.new()
	cap.text = cap_txt
	cap.custom_minimum_size = Vector2(56, 0)
	cap.add_theme_font_size_override("font_size", UITheme.fs(17))
	cap.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	row.add_child(cap)
	for bd in [["◀", -1], ["▶", 1]]:
		var b := Button.new()
		b.text = bd[0]
		b.custom_minimum_size = Vector2(0, 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", UITheme.fs(20))
		var d: int = bd[1]
		b.pressed.connect(func():
			if not busy:
				lv.nudge_graph(key, d))
		row.add_child(b)
	go_btn.text = "就是這裡" if mode == "window" else "點亮"
	if mode == "wick":
		task_label.text = hl_word(String(st.q))
	fview.live_q = "在下方的湖面上拖動（或按右邊的按鈕），再按「%s」。" % go_btn.text
	_on_graph_move()


func _graph_submit(st: Dictionary) -> void:
	var lv := _wv()
	match String(st.mode):
		"wick":
			var goal: Array = st.goals[lv.gstage]
			var hit := false
			for x in goal[1]:
				if LakeView.same(lv.gh, LakeView.q(x)):
					hit = true
			var word := "最高" if String(goal[0]) == "max" else "最低"
			if not hit:
				_wrong(st, hl_word("%s = %s 這裡還不是%s的地方。提示：%s" % [String(st.get("xname", "x")), LakeView.qs(lv.gh), word, st.nudge]))
				return
			Game.of(self).sfx("correct")
			lv.gmarks.append([lv.gh, String(goal[0])])
			lv.gstage += 1
			if lv.gstage >= st.goals.size():
				_graph_done(st)
			else:
				var nxt: Array = st.goals[lv.gstage]
				_hint(hl_word("✓ 點亮了%s的地方！接著找%s的地方。" % [word, "最高" if String(nxt[0]) == "max" else "最低"]), "good")
				_on_graph_move()
		"window":
			var want := String(st.goals[lv.gstage])
			if not lv.win_locs().has(want):
				_wrong(st, "現在%s在%s，要的是%s。提示：%s" % [lv.ext_word(), lv.loc_text(), WickView.LOC_NAME[want], st.nudge])
				return
			if not lv.gmarks.is_empty() and LakeView.same(float(lv.gmarks.back()), lv.gh):
				_hint("頂點剛好在端點上，%s和%s都算對——但這個位置剛剛用過了，搬動燈罩換一個位置。" % [WickView.LOC_NAME[lv.win_locs()[0]], WickView.LOC_NAME[lv.win_locs()[-1]]], "info")
				return
			Game.of(self).sfx("correct")
			lv.gmarks.append(lv.gh)
			lv.gstage += 1
			if lv.gstage >= st.goals.size():
				_graph_done(st)
			else:
				_hint("✓ 對了！下一個：讓%s發生在%s。" % [lv.ext_word(), WickView.LOC_NAME[String(st.goals[lv.gstage])]], "good")
				_on_graph_move()
		_:
			super(st)


# ================= 速算 =================

func _speed_tag() -> String:
	return BankP6.T_EXT


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算（一步）：標準式讀極值、一般式求極值、範圍裡有頂點時的另一個極值
static func gen_problems(_kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var a: int = [-3, -2, -1, 1, 2, 3].pick_random()
		var h := randi_range(-4, 4)
		var k := randi_range(-6, 6)
		var word := "最小值" if a > 0 else "最大值"
		var pb := {}
		match out.size() % 3:
			0:
				if h == 0:
					continue
				pb = {"eq": "%s\n%s = ？" % [LakeView.vtx_eq(a, h, k), word], "ans": str(k), "template": word + " = [0]",
					"q": "y = a(x − h)^{2} + k 的極值是 k。", "nudge": "頂點的 y 坐標。"}
			1:
				var s: int = [-1, 1].pick_random()
				if h == 0:
					continue
				var c := randi_range(-5, 9)
				var w2 := "最小值" if s > 0 else "最大值"
				pb = {"eq": "y = %s\n%s = ？" % [LakeView.poly2(s, -2 * s * h, c), w2], "ans": str(c - s * h * h), "template": w2 + " = [0]",
					"q": "配方：x^{2} − 2hx + c = (x − h)^{2} + c − h^{2}。", "nudge": "對稱軸代回去。"}
			2:
				var aa: int = [1, 2, -1, -2].pick_random()
				var lo := h - randi_range(1, 3)
				var hi := h + randi_range(1, 3)
				if hi - h == h - lo:
					continue
				var far := maxi(hi - h, h - lo)
				var other := "最大值" if aa > 0 else "最小值"
				pb = {"eq": "%s，%d ≤ x ≤ %d\n%s = ？" % [LakeView.vtx_eq(aa, h, k), lo, hi, other], "ans": str(aa * far * far + k), "template": other + " = [0]",
					"q": "頂點在範圍裡：另一個極值在離對稱軸最遠的端點。", "nudge": "哪個端點離 x = h 比較遠？"}
		pb.eq = String(pb.eq).replace("-", "−")
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		pb["tag"] = BankP6.T_EXT
		out.append(pb)
	return out


# ================= 畫面：燈芯 =================

class WickView extends LakeView:
	const FLAME := Color("ffd27a")
	const SHADE := Color("ffe9a8")
	const LOC_NAME := {"left": "左端點", "vertex": "頂點", "right": "右端點"}
	const HI := "ff6b9d"
	const LO := "4fd8ff"

	static func hlw(s: String) -> String:
		return s.replace("最高", "[color=#%s]最高[/color]" % HI).replace("最低", "[color=#%s]最低[/color]" % LO)

	var figure := ""     # 整段旅程都畫在下方的示意圖（trap、square）

	func setup(round: Dictionary) -> void:
		super(round)
		figure = String(round.get("figure", "")) if String(round.get("type", "")) == "forge" else ""

	func _graph_on() -> bool:
		return figure != "" or super()

	func _bottom_limit() -> float:
		if figure != "" and gst.is_empty():
			return size.y - 276.0
		return super()

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if gst.is_empty() and figure != "":
			_draw_figure(font)
			return
		super(font, rect)

	## 示意圖（只標字母、長度和角度，不寫中文）
	func _draw_figure(font: Font) -> void:
		var rc := _grect()
		if rc.size.x < 120.0:
			return
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.05, 0.12, 0.85)
		sb.border_color = Color(FLAME.r, FLAME.g, FLAME.b, 0.4)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(14)
		sb.anti_aliasing = true
		draw_style_box(sb, rc)
		var fs := UITheme.fs(15)
		var wall := Color(0.72, 0.72, 0.8)
		var fence := FLAME
		var ink := Color(1, 1, 1, 0.85)
		match figure:
			"trap":
				# 高 h = 8 的樣子：BC = 20、PQ = 28（只是示意）
				var hh := 8.0
				var bc := 20.0
				var sc := minf((rc.size.x - 200.0) / (hh + bc + 4.0), (rc.size.y - 70.0) / (hh + 3.0))
				var w := (hh + bc + 2.5) * sc
				var B := Vector2(rc.get_center().x + 50.0 - w * 0.5 + (hh + 2.5) * sc, rc.end.y - 34.0)
				var C := B + Vector2(bc * sc, 0)
				var P := B + Vector2(-hh * sc, -hh * sc)
				var Q := C + Vector2(0, -hh * sc)
				var A := B + Vector2(-(hh + 2.5) * sc, -(hh + 2.5) * sc)
				draw_colored_polygon(PackedVector2Array([P, Q, C, B]), Color(fence.r, fence.g, fence.b, 0.12))
				# 原本的牆（灰色，外側畫斜線）
				draw_line(A, B, wall, 4.0, true)
				draw_line(B, C + Vector2(18, 0), wall, 4.0, true)
				var hatch := PackedVector2Array()
				for k in 9:
					var u := (k + 0.5) / 9.0
					var m := A.lerp(B, u)
					hatch.append_array([m, m + Vector2(-9, 4)])
				for k in 12:
					var m2 := B.lerp(C + Vector2(18, 0), (k + 0.5) / 12.0)
					hatch.append_array([m2, m2 + Vector2(-6, 8)])
				draw_multiline(hatch, Color(wall.r, wall.g, wall.b, 0.5), 1.5)
				# 新的牆 PQ、QR
				draw_line(P, Q, fence, 3.5, true)
				draw_line(Q, C, fence, 3.5, true)
				# 135° 與直角記號
				draw_arc(B, 18.0, -0.75 * PI, 0.0, 24, Color(1, 0.7, 0.9, 0.9), 2.0, true)
				MathLabel.draw_on(self, font, B.x + 18.0, B.y - 22.0, "135°", UITheme.fs(13), Color(1, 0.75, 0.9))
				var s9 := 10.0
				draw_polyline(PackedVector2Array([C + Vector2(-s9, 0), C + Vector2(-s9, -s9), C + Vector2(0, -s9)]), ink, 1.5)
				draw_dashed_line(P + Vector2(hh * sc, 0), B, Color(1, 1, 1, 0.35), 1.5, 5.0)
				MathLabel.draw_on(self, font, A.x - 12.0, A.y + 4.0, "A", fs, ink)
				MathLabel.draw_on(self, font, B.x - 4.0, B.y + 22.0, "B", fs, ink)
				MathLabel.draw_on(self, font, C.x + 4.0, C.y + 22.0, "C(R)", fs, ink)
				MathLabel.draw_on(self, font, P.x - 14.0, P.y - 2.0, "P", fs, fence)
				MathLabel.draw_on(self, font, Q.x + 12.0, Q.y - 4.0, "Q", fs, fence)
				MathLabel.draw_on(self, font, Q.x + 14.0, (Q.y + C.y) * 0.5 + 5.0, "h", fs, fence)
			"square":
				var side := minf(rc.size.y - 64.0, rc.size.x - 160.0)
				var o := Vector2(rc.get_center().x + 50.0 - side * 0.5, rc.position.y + 28.0)
				var u := side / 6.0
				var x := 1.5
				var A := o
				var Bq := o + Vector2(0, 6) * u
				var Cq := o + Vector2(6, 6) * u
				var D := o + Vector2(6, 0) * u
				var E := o + Vector2(0, 2.0 * x) * u
				var F := o + Vector2(x, 0) * u
				draw_colored_polygon(PackedVector2Array([Bq, Cq, F, E]), Color(fence.r, fence.g, fence.b, 0.18))
				draw_polyline(PackedVector2Array([A, Bq, Cq, D, A]), wall, 2.0, true)
				draw_polyline(PackedVector2Array([E, F, Cq]), fence, 2.5, true)
				for pt in [E, F]:
					UITheme.dot(self, pt, 4.0, fence)
				MathLabel.draw_on(self, font, A.x - 14.0, A.y + 2.0, "A", fs, ink)
				MathLabel.draw_on(self, font, Bq.x - 14.0, Bq.y + 14.0, "B", fs, ink)
				MathLabel.draw_on(self, font, Cq.x + 14.0, Cq.y + 14.0, "C", fs, ink)
				MathLabel.draw_on(self, font, D.x + 14.0, D.y + 2.0, "D", fs, ink)
				MathLabel.draw_on(self, font, E.x - 14.0, E.y + 6.0, "E", fs, fence)
				MathLabel.draw_on(self, font, F.x + 12.0, F.y + 18.0, "F", fs, fence)
				MathLabel.draw_on(self, font, (A.x + F.x) * 0.5, A.y - 6.0, "x", fs, Color("9fd8ff"))
				MathLabel.draw_on(self, font, A.x - 20.0, (A.y + E.y) * 0.5 + 6.0, "2x", fs, Color("9fd8ff"))
				MathLabel.draw_on(self, font, (Bq.x + Cq.x) * 0.5, Bq.y + 20.0, "6", fs, ink)

	func _wmode() -> bool:
		return String(gst.get("mode", "")) in ["wick", "window"]

	func start_graph(st: Dictionary, cb: Callable) -> void:
		super(st, cb)
		match String(st.mode):
			"wick":
				var vw := _view()
				var vx_: Vector2 = vw.x
				var lo := maxf(_lo(), vx_.x)
				var hi := minf(_hi(), vx_.y)
				var goals := []
				for g in st.goals:
					for x in g[1]:
						goals.append(q(x))
				var s := _step()
				for fr in [0.15, 0.85, 0.3, 0.7, 0.5, 0.05, 0.95]:
					gh = _wclamp(roundf(lerpf(lo, hi, fr) / s) * s, 1)
					var clash := false
					for gx in goals:
						if same(gx, gh):
							clash = true
					if not clash:
						break
			"window":
				gh = float(st.get("start_p", 0))
		queue_redraw()

	# ---------- 燈罩、能走的範圍 ----------
	func _lo() -> float:
		var vw := _view()
		var win: Array = gst.get("win", [null, null])
		return q(win[0]) if win[0] != null else vw.x.x

	func _hi() -> float:
		var vw := _view()
		var win: Array = gst.get("win", [null, null])
		return q(win[1]) if win[1] != null else vw.x.y

	func _step() -> float:
		if bool(gst.get("int", false)):
			return maxf(1.0, q(gst.get("snap", "1")))
		return q(gst.get("snap", "1"))

	## 把燈芯放回能走的地方（d：往哪個方向跳過不能走的區域）
	func _wclamp(x: float, d: int) -> float:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var lo := maxf(_lo(), vx_.x)
		var hi := minf(_hi(), vx_.y)
		x = clampf(x, lo, hi)
		if gst.has("gap"):
			var g0 := q(gst.gap[0])
			var g1 := q(gst.gap[1])
			if x > g0 + 1e-9 and x < g1 - 1e-9:
				if d > 0:
					x = g1
				elif d < 0:
					x = g0
				else:
					x = g0 if x - g0 < g1 - x else g1
		return x

	func nudge_graph(key: String, d: int) -> void:
		match key:
			"x":
				gh = _wclamp(gh + d * _step(), d)
				_moved()
			"p":
				gh = _pclamp(gh + d * q(gst.get("snap", "1")))
				_moved()
			_:
				super(key, d)

	func _pclamp(p: float) -> float:
		var vw := _view()
		var vx_: Vector2 = vw.x
		return clampf(p, vx_.x, vx_.y - float(gst.get("width", 2)))

	func _gpad_input(e: InputEvent) -> void:
		if not _wmode():
			super(e)
			return
		var pos := Vector2.INF
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			pos = e.position
		elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
			pos = e.position
		if pos == Vector2.INF:
			return
		var w := _from(pos + gpad.position)
		var before := gh
		if String(gst.mode) == "wick":
			var s := _step()
			gh = _wclamp(roundf(w.x / s) * s, 0)
		else:
			var s2 := q(gst.get("snap", "1"))
			gh = _pclamp(roundf((w.x - float(gst.get("width", 2)) * 0.5) / s2) * s2)
		if not same(before, gh):
			_moved()
		gpad.accept_event()

	func cur_coef() -> Array:
		if _wmode():
			return gst.coef.map(func(v): return q(v))
		return super()

	func axis_x() -> float:
		var c := cur_coef()
		return -float(c[1]) / (2.0 * float(c[0]))

	## window：罩子裡的極值在哪裡
	func win_loc() -> String:
		var ax := axis_x()
		var lo := gh
		var hi := gh + float(gst.get("width", 2))
		if ax < lo - 1e-9:
			return "left"
		if ax > hi + 1e-9:
			return "right"
		return "vertex"

	## 頂點剛好在端點上時，兩個說法都對：["vertex", "left"]
	func win_locs() -> Array:
		var ax := axis_x()
		var lo := gh
		var hi := gh + float(gst.get("width", 2))
		if same(ax, lo):
			return ["vertex", "left"]
		if same(ax, hi):
			return ["vertex", "right"]
		return [win_loc()]

	func loc_text() -> String:
		var ls := win_locs()
		if ls.size() > 1:
			return "%s（也是%s）" % [LOC_NAME[ls[0]], LOC_NAME[ls[1]]]
		return LOC_NAME[ls[0]]

	func ext_word() -> String:
		return "最大值" if String(gst.get("ext", "min")) == "max" else "最小值"

	func readout() -> String:
		match String(gst.get("mode", "")):
			"wick":
				var xn := String(gst.get("xname", "x"))
				if bool(gst.get("show_val", false)):
					return "%s = %s：%s = %s" % [xn, qs(gh), String(gst.get("fname", "y")), qs(fv(cur_coef(), gh))]
				return "%s = %s" % [xn, qs(gh)]
			"window":
				return "燈罩：%s ≤ x ≤ %s" % [qs(gh), qs(gh + float(gst.get("width", 2)))]
		return super()

	func center_text() -> String:
		match String(gst.get("mode", "")):
			"wick":
				var goal: Array = gst.goals[mini(gstage, gst.goals.size() - 1)]
				var word := "最高" if String(goal[0]) == "max" else "最低"
				var n: int = gst.goals.size()
				var tail := "（第 %d／%d 盞）" % [gstage + 1, n] if n > 1 else ""
				return "點亮%s的地方%s" % [hlw(word), tail]
			"window":
				var want := String(gst.goals[mini(gstage, gst.goals.size() - 1)])
				return "%s在%s　現在在%s" % [ext_word(), LOC_NAME[want], loc_text()]
		return super()

	# ---------- 背景：夜裡的燈坊 ----------
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		if w < 100.0 or h < 100.0:
			return
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("140f24"), Color("140f24"), Color("0a0814"), Color("0a0814")]))
		for i in 9:
			var p := Vector2(fposmod(i * 131.7 + t * 6.0, w), h * 0.15 + fposmod(i * 57.3, h * 0.5) - fposmod(t * 9.0 + i * 40.0, h * 0.5))
			var a := 0.10 + 0.06 * sin(t * 2.0 + i)
			UITheme.dot(self, p, 7.0, Color(FLAME.r, FLAME.g, FLAME.b, a * 0.5))
			UITheme.dot(self, p, 2.5, Color(FLAME.r, FLAME.g, FLAME.b, a * 2.0))
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	# ---------- 座標圖 ----------
	func _draw_lake(font: Font) -> void:
		if not _wmode():
			super(font)
			return
		var rc := _grect()
		var vw := _view()
		var vx_: Vector2 = vw.x
		var vy_: Vector2 = vw.y
		var ar := _area()
		var mode := String(gst.mode)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.05, 0.12, 0.85)
		sb.border_color = Color(FLAME.r, FLAME.g, FLAME.b, 0.4)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(14)
		sb.anti_aliasing = true
		draw_style_box(sb, rc)
		var tx := float(gst.get("tx", 1))
		var ty := float(gst.get("ty", 1))
		# 格線
		var grid := PackedVector2Array()
		var xi := ceilf(vx_.x / tx) * tx
		while xi <= vx_.y + 1e-9:
			grid.append_array([_to(xi, vy_.x), _to(xi, vy_.y)])
			xi += tx
		var yi := ceilf(vy_.x / ty) * ty
		while yi <= vy_.y + 1e-9:
			grid.append_array([_to(vx_.x, yi), _to(vx_.y, yi)])
			yi += ty
		draw_multiline(grid, Color(1, 1, 1, 0.05), 1.0)
		# 坐標軸
		var ybase := clampf(0.0, vy_.x, vy_.y)
		draw_line(_to(vx_.x, ybase), _to(vx_.y, ybase), Color(1, 0.92, 0.75, 0.6), 2.0)
		if vx_.x < 0 and vx_.y > 0:
			draw_line(_to(0.0, vy_.x), _to(0.0, vy_.y), Color(1, 1, 1, 0.3), 1.5)
		var fs := UITheme.fs(11)
		xi = ceilf(vx_.x / tx) * tx
		while xi <= vx_.y + 1e-9:
			if absf(xi) > 1e-9:
				var p := _to(xi, ybase)
				MathLabel.draw_on(self, font, p.x, p.y + 14.0, qs(xi), fs, Color(1, 1, 1, 0.45))
			xi += tx
		var xn := String(gst.get("xname", "x"))
		MathLabel.draw_on(self, font, ar.end.x - 6.0, _to(vx_.y, ybase).y - 6.0, xn, UITheme.fs(13), Color(1, 0.92, 0.75, 0.8))
		if absf(ybase) > 1e-9:
			MathLabel.draw_on(self, font, ar.position.x + 14.0, _to(vx_.x, ybase).y - 6.0, qs(ybase), fs, Color(1, 1, 1, 0.45))
		var c := cur_coef()
		if mode == "window":
			_draw_window(font, c)
		else:
			_draw_wick(font, c)

	## 燈罩（[lo, hi]）的光
	func _shade(lo: float, hi: float, strong: bool) -> void:
		var ar := _area()
		var x0 := clampf(_to(lo, 0.0).x, ar.position.x, ar.end.x)
		var x1 := clampf(_to(hi, 0.0).x, ar.position.x, ar.end.x)
		if x1 - x0 < 1.0:
			return
		draw_rect(Rect2(x0, ar.position.y, x1 - x0, ar.size.y), Color(SHADE.r, SHADE.g, SHADE.b, 0.10 if strong else 0.06))
		for xe in [[lo, x0], [hi, x1]]:
			var vw := _view()
			if float(xe[0]) >= vw.x.x - 1e-9 and float(xe[0]) <= vw.x.y + 1e-9:
				draw_dashed_line(Vector2(xe[1], ar.position.y), Vector2(xe[1], ar.end.y), Color(SHADE.r, SHADE.g, SHADE.b, 0.55), 1.5, 5.0)

	## 拋物線：燈罩裡亮、外面暗；不能走的地方畫虛線
	func _wcurve(c: Array, lo: float, hi: float) -> void:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var ar := _area()
		var g0 := INF
		var g1 := -INF
		if gst.has("gap"):
			g0 = q(gst.gap[0])
			g1 = q(gst.gap[1])
		var prev := Vector2.INF
		for i in 301:
			var x := lerpf(vx_.x, vx_.y, i / 300.0)
			var p := _to(x, fv(c, x))
			if prev != Vector2.INF:
				var ok_ := x >= lo - 1e-9 and x <= hi + 1e-9 and not (x > g0 and x < g1)
				var col := Color(CURVE.r, CURVE.g, CURVE.b, 1.0 if ok_ else 0.45)
				var sg := clip_seg(prev, p, ar)
				if sg.size() == 2 and (ok_ or i % 4 < 2):
					draw_line(sg[0], sg[1], col, 2.8 if ok_ else 1.6, true)
			prev = p

	func _ypos(y: float) -> Vector2:
		var ar := _area()
		var p := _to(0.0, y)
		return Vector2(p.x, clampf(p.y, ar.position.y, ar.end.y))

	func _wick_at(x: float, c: Array, big: bool, font: Font = null) -> void:
		var ar := _area()
		var p := _to(x, fv(c, x))
		var fl := 0.5 + 0.5 * sin(t * 7.0)
		if p.y < ar.position.y - 1.0 or p.y > ar.end.y + 1.0:
			# 燈芯在畫面外：在邊上畫一個會跳動的箭頭，告訴玩家它在上面（下面）
			var up := p.y < ar.position.y
			var ey := ar.position.y + 4.0 if up else ar.end.y - 4.0
			var bob := 3.0 * fl * (-1.0 if up else 1.0)
			var tip := Vector2(p.x, ey + bob)
			var dir := -1.0 if up else 1.0
			var col := Color("ff6b9d")
			UITheme.dot(self, tip + Vector2(0, -dir * 10.0), 14.0, Color(col.r, col.g, col.b, 0.18 + 0.12 * fl))
			draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-9, -dir * 13.0), tip + Vector2(9, -dir * 13.0)]), col)
			draw_line(tip + Vector2(0, -dir * 12.0), tip + Vector2(0, -dir * 26.0), col, 3.0, true)
			return
		UITheme.dot(self, p, (18.0 if big else 12.0) + 2.0 * fl, Color(FLAME.r, FLAME.g, FLAME.b, 0.18))
		UITheme.dot(self, p, 7.0, FLAME)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -5), p + Vector2(0, -16 - 3.0 * fl), p + Vector2(4, -5)]), Color(1, 0.75, 0.35, 0.9))

	func _draw_wick(font: Font, c: Array) -> void:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var vy_: Vector2 = vw.y
		var ar := _area()
		var lo := _lo()
		var hi := _hi()
		if gst.has("win"):
			_shade(lo, hi, true)
			var wl := "燈罩：" + ("%s ≤ %s" % [qm(lo), String(gst.get("xname", "x"))] if gst.win[0] != null else "") \
				+ (" ≤ %s" % qm(hi) if gst.win[1] != null else "")
			MathLabel.draw_on(self, font, clampf((_to(lo, 0).x + _to(minf(hi, vx_.y), 0).x) * 0.5, ar.position.x + 70.0, ar.end.x - 70.0), ar.position.y + 14.0, wl, UITheme.fs(12), Color(SHADE.r, SHADE.g, SHADE.b, 0.9))
		if gst.has("gap"):
			var g0 := q(gst.gap[0])
			var g1 := q(gst.gap[1])
			var x0 := _to(g0, 0).x
			var x1 := _to(g1, 0).x
			draw_rect(Rect2(x0, ar.position.y, x1 - x0, ar.size.y), Color(0.5, 0.5, 0.55, 0.22))
			MathLabel.draw_on(self, font, (x0 + x1) * 0.5, ar.position.y + 14.0, "沒有實根", UITheme.fs(12), Color(0.85, 0.85, 0.9, 0.9))
		for m in gst.get("marks", []):
			var mp := _to(float(m[0]), clampf(0.0, vy_.x, vy_.y))
			UITheme.dot(self, mp, 5.0, Color("9fd8ff"))
			draw_line(mp, _to(gh, clampf(0.0, vy_.x, vy_.y)), Color(0.62, 0.85, 1.0, 0.35), 1.5)
			MathLabel.draw_on(self, font, mp.x, mp.y - 10.0, String(m[1]), UITheme.fs(13), Color("bfe6ff"))
		_wcurve(c, lo, hi)
		if bool(gst.get("int", false)):
			var xi := ceilf(maxf(lo, vx_.x))
			while xi <= minf(hi, vx_.y) + 1e-9:
				var y := fv(c, xi)
				if y >= vy_.x and y <= vy_.y:
					UITheme.dot(self, _to(xi, y), 4.5, Color(1, 0.9, 0.7, 0.55))
				xi += _step()
		# 已經點亮的地方
		for m in gmarks:
			var mx := float(m[0])
			var mp := _to(mx, fv(c, mx))
			mp.y = clampf(mp.y, ar.position.y, ar.end.y)
			UITheme.dot(self, mp, 9.0, Color(UITheme.GOOD.r, UITheme.GOOD.g, UITheme.GOOD.b, 0.35))
			UITheme.dot(self, mp, 5.0, UITheme.GOOD)
			var top := String(m[1]) == "max"
			MathLabel.draw_on(self, font, mp.x, mp.y + (-14.0 if top else 22.0), "最高" if top else "最低", UITheme.fs(13), Color(HI if top else LO))
		# 燈芯：往下畫一條虛線到橫軸
		var wp := _to(gh, fv(c, gh))
		var by := _to(gh, clampf(0.0, vy_.x, vy_.y)).y
		draw_dashed_line(Vector2(wp.x, clampf(wp.y, ar.position.y, ar.end.y)), Vector2(wp.x, by), Color(FLAME.r, FLAME.g, FLAME.b, 0.4), 1.5, 4.0)
		_wick_at(gh, c, true, font)
		if gst.has("fig"):
			_draw_fig(font)

	func _draw_window(font: Font, c: Array) -> void:
		var ar := _area()
		var vw := _view()
		var vy_: Vector2 = vw.y
		var w := float(gst.get("width", 2))
		var lo := gh
		var hi := gh + w
		_shade(lo, hi, true)
		var ax := axis_x()
		draw_dashed_line(_to(ax, vy_.x), _to(ax, vy_.y), Color(1, 0.6, 0.85, 0.7), 2.0, 6.0)
		MathLabel.draw_on(self, font, _to(ax, vy_.y).x, _to(ax, vy_.y).y + 14.0, "x = " + qm(ax), UITheme.fs(12), Color(1, 0.7, 0.9))
		_wcurve(c, lo, hi)
		var loc := win_loc()
		var ex := {"left": lo, "vertex": ax, "right": hi}[loc] as float
		_wick_at(ex, c, true, font)
		var ep := _to(ex, fv(c, ex))
		var is_max := String(gst.get("ext", "min")) == "max"
		var right_side := ep.x < ar.get_center().x
		var lbl := "%s在%s" % [ext_word(), loc_text()]
		var half := MathLabel.text_width(font, lbl, UITheme.fs(13)) * 0.5 + 16.0
		MathLabel.draw_on(self, font, clampf(ep.x + (half if right_side else -half), ar.position.x + half - 10.0, ar.end.x - half + 10.0), clampf(ep.y + (10.0 if is_max else -6.0), ar.position.y + 30.0, ar.end.y - 4.0),
			lbl, UITheme.fs(13), FLAME)

	# ---------- 旁邊的小圖 ----------
	func _fig_rect() -> Rect2:
		var ar := _area()
		var sz := Vector2(132, 92)
		match String(gst.get("fig_at", "tl")):
			"tr":
				return Rect2(Vector2(ar.end.x - sz.x - 6, ar.position.y + 24), sz)
			"bl":
				return Rect2(Vector2(ar.position.x + 6, ar.end.y - sz.y - 6), sz)
			"br":
				return Rect2(Vector2(ar.end.x - sz.x - 6, ar.end.y - sz.y - 6), sz)
		return Rect2(ar.position + Vector2(6, 24), sz)

	func _draw_fig(font: Font) -> void:
		var fr := _fig_rect()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.05, 0.04, 0.09, 0.92)
		sb.border_color = Color(FLAME.r, FLAME.g, FLAME.b, 0.35)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(8)
		draw_style_box(sb, fr)
		var inner := fr.grow(-12)
		var fs := UITheme.fs(11)
		var wall := Color(0.7, 0.7, 0.78)
		var fence := FLAME
		match String(gst.fig):
			"trap":
				# B 在左下，BC 往右；牆 AB 往左上 45°
				var hh := gh
				var bc := 36.0 - 2.0 * hh
				var sc := minf(inner.size.x / 36.0, inner.size.y / 18.0)
				var B := Vector2(inner.position.x + hh * sc, inner.end.y)
				var C := B + Vector2(bc * sc, 0)
				var P := B + Vector2(-hh * sc, -hh * sc)
				var Q := C + Vector2(0, -hh * sc)
				if hh > 0.01:
					draw_colored_polygon(PackedVector2Array([P, Q, C, B]), Color(fence.r, fence.g, fence.b, 0.18))
				draw_line(B + Vector2(-1, -1) * (hh * sc + 6.0), B, wall, 3.0)
				draw_line(B, C + Vector2(6, 0), wall, 3.0)
				draw_line(P, Q, fence, 2.5)
				draw_line(Q, C, fence, 2.5)
				MathLabel.draw_on(self, font, B.x, B.y + 12.0, "B", fs, wall)
				MathLabel.draw_on(self, font, Q.x + 8.0, (Q.y + C.y) * 0.5 + 4.0, "h", fs, fence)
			"square":
				var x := gh
				var sc2 := inner.size.y / 6.0
				var o := Vector2(inner.get_center().x - 3.0 * sc2, inner.position.y)
				var A := o
				var Bq := o + Vector2(0, 6) * sc2
				var Cq := o + Vector2(6, 6) * sc2
				var D := o + Vector2(6, 0) * sc2
				var E := o + Vector2(0, 2.0 * x) * sc2
				var F := o + Vector2(x, 0) * sc2
				draw_colored_polygon(PackedVector2Array([Bq, Cq, F, E]), Color(fence.r, fence.g, fence.b, 0.25))
				draw_polyline(PackedVector2Array([A, Bq, Cq, D, A]), wall, 1.5)
				draw_polyline(PackedVector2Array([E, F, Cq]), fence, 2.0)
				for lb in [[A, "A", Vector2(-8, 0)], [Bq, "B", Vector2(-8, 8)], [Cq, "C", Vector2(8, 8)], [D, "D", Vector2(8, 0)], [E, "E", Vector2(-9, 4)], [F, "F", Vector2(0, -3)]]:
					MathLabel.draw_on(self, font, lb[0].x + lb[2].x, lb[0].y + lb[2].y + 4.0, lb[1], fs, Color(1, 1, 1, 0.75))
			"seg":
				var sg: Array = gst.seg
				var m := maxf(float(sg[1]), float(sg[2]))
				var sc3 := minf(inner.size.x, inner.size.y) / m
				var o2 := Vector2(inner.get_center().x - m * sc3 * 0.5, inner.end.y)
				var p0 := o2 + Vector2(float(sg[0]), -float(sg[1])) * sc3
				var p1 := o2 + Vector2(float(sg[2]), -float(sg[3])) * sc3
				draw_line(o2 + Vector2(-6, 0), o2 + Vector2(m * sc3 + 8, 0), Color(1, 1, 1, 0.35), 1.0)
				draw_line(o2 + Vector2(0, 6), o2 + Vector2(0, -m * sc3 - 6), Color(1, 1, 1, 0.35), 1.0)
				draw_line(p0, p1, wall, 2.5)
				var u := (gh - float(sg[0])) / (float(sg[2]) - float(sg[0]))
				var P2 := p0.lerp(p1, clampf(u, 0.0, 1.0))
				UITheme.dot(self, P2, 5.0, fence)
				MathLabel.draw_on(self, font, P2.x + 10.0, P2.y - 6.0, "P", fs, fence)
