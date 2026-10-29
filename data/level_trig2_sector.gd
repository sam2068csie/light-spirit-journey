extends "level_trig1_arc.gd"
## 三角函數 第二大關「扇形潟湖」（對應講義 1-1 重點一後半：扇形問題）
## 繼承第一關（月光背景、單位圓、spin 步驟、√ 鍵都一樣），題庫在 trig2_bank.gd。
##
## 這一關多了：
##   ・fan 步驟：拖動扇子的邊把扇子打開，即時看到弧長、面積（任務：弧長 = 半徑、面積 = 指定值）
##   ・下方的示意圖：扇形、時鐘、滾動的車輪、捆罐頭的繩子、弓形、兩圓重疊、扇形捲成圓錐、螞蟻的最短路徑、面積的拋物線
##   ・速算：已知 r、θ 求弧長、面積，或已知弧長求 θ

const BankG2 := preload("trig2_bank.gd")
const LAGOON := UITheme.ORANGE

const CHAPTERS_G2 := [
	{"ch": 1, "name": "第一章．扇子展開", "topic": "弧長與面積、周長與面積、最大面積", "color": UITheme.ORANGE},
	{"ch": 2, "name": "第二章．潟湖深處", "topic": "時鐘、滾動、弓形與圓錐", "color": Color("ff9f6b")},
]

var fan_info: MathLabel


func level_id() -> String:
	return "G2"

func level_title() -> String:
	return "扇形潟湖"

func level_subtitle() -> String:
	return "扇形弧長與面積"

func level_chapters() -> Array:
	return CHAPTERS_G2

func bank_slots() -> Array:
	return BankG2.slots()

func step_color() -> Color:
	return LAGOON

func chapter_card() -> Dictionary:
	return {"title": "第二章．潟湖深處", "button": "進入潟湖深處  ▶",
		"text": "扇形藏在各種地方：\n\n" \
			+ "・時鐘：指針掃過的就是扇形\n" \
			+ "・車輪：滾過的距離 = 弧長\n" \
			+ "・弓形 = 扇形 − 三角形\n" \
			+ "・扇形捲起來變成圓錐：弧長 = 底圓周長\n\n" \
			+ "潛下去看看吧！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = SectorView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "速算"
		_mv().spin_changed.connect(_on_view_changed)


func _sv() -> SectorView:
	return fview as SectorView


func _on_view_changed() -> void:
	if fview != null and _sv().fan_on:
		_refresh_fan()
	else:
		_refresh_spin()


# ================= 打開扇子（fan） =================

func _forge_step() -> void:
	if fview != null:
		_sv().fan_on = false
	super()
	if si < steps.size() and String(steps[si].kind) == "fan":
		_build_fan(steps[si])


## 下方的示意圖可以隨步驟換：題目寫 "circles": [{…, "after": −1}, {…, "after": 1}]，用「after 比目前步驟小」的最後一張
func _update_circle() -> void:
	var lst: Array = r.get("circles", [])
	if lst.is_empty():
		super()
		return
	var pick := {}
	for sp in lst:
		if si > int(sp.get("after", -1)):
			pick = sp
	if not pick.is_empty():
		_mv().circ = pick


func _build_fan(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.box(Color(LAGOON.r, LAGOON.g, LAGOON.b, 0.08), 14,
		Color(LAGOON.r, LAGOON.g, LAGOON.b, 0.4), 1, 12))
	rank_box.add_child(card)
	fan_info = MathLabel.new()
	fan_info.font_size = UITheme.fs(20)
	fan_info.max_width = 320
	fan_info.align_center = true
	fan_info.valign_center = true
	fan_info.custom_minimum_size = Vector2(0, 104)       # 固定高度：數字變成分數時下面的按鈕不會跳
	fan_info.color = UITheme.TEXT
	card.add_child(fan_info)
	var snap: float = st.get("snap", STEP)
	if snap > 0.0:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		rank_box.add_child(row)
		for spec in [["收  −15°", -1], ["開  +15°", 1]]:
			var b := Button.new()
			b.text = spec[0]
			b.custom_minimum_size = Vector2(0, 46)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", UITheme.fs(17))
			var d: int = spec[1]
			b.pressed.connect(func():
				if busy:
					return
				MoonView.dragged_ever = true
				_sv().set_fan(_sv().fan_theta + d * snap)
				Game.of(self).play("blip", 1.0 + 0.1 * _sv().fan_theta, -14.0))
			row.add_child(b)
	var tip := Label.new()
	tip.text = "拖動扇子邊上的光點，把扇子打開或收起來。"
	tip.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	tip.custom_minimum_size = Vector2(300, 0)
	tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(tip)
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "確定"
	var sv := _sv()
	sv.circ = {}
	sv.begin_fan(float(st.r), snap)
	sv.task_q = String(st.q)
	sv.mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_fan()


## 扇子目前的角、弧長、面積（π 的倍數時寫成 kπ/12 的樣子，不是的時候寫小數）
func _refresh_fan() -> void:
	if fan_info == null or not is_instance_valid(fan_info):
		return
	var sv := _sv()
	var th: float = sv.fan_theta
	var r: float = sv.fan_r
	var ri := int(r)
	if sv.fan_snap > 0.0:
		var k := roundi(th / STEP)
		fan_info.text = "θ = %s\n弧長 = %s　面積 = %s" % [angle_text(k, 12), angle_text(ri * k, 12), angle_text(ri * ri * k, 24)]
	else:
		fan_info.text = "θ ≈ %s 弧度（%s°）\n弧長 ≈ %s　面積 ≈ %s" % [_dec(th), _dec(rad_to_deg(th), 1), _dec(r * th), _dec(0.5 * r * r * th)]


static func _dec(v: float, n := 2) -> String:
	return String.num(v, n)


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size() and String(steps[si].kind) == "fan":
		_fan_submit()
		return
	super()


func _fan_submit() -> void:
	var st: Dictionary = steps[si]
	var sv := _sv()
	var th: float = sv.fan_theta
	var rr: float = st.r
	var val := rr * th if st.goal == "arc" else 0.5 * rr * rr * th
	if absf(val - float(st.target)) <= float(st.get("tol", 0.001)) + 1e-6:
		Game.of(self).sfx("correct")
		sv.fan_on = false
		sv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sv.spun = {"kind": "sector", "r": rr, "theta": th, "after": -1}
		sv.circ = sv.spun
		sv.burst_center()
		go_btn.visible = false
		_clear(rank_box)
		rank_box.visible = false
		_step_done(st, "")
		return
	var what := "弧長" if st.goal == "arc" else "面積"
	var msg := "%s還不對（現在 ≈ %s）。" % [what, _dec(val)]
	msg += "再打開一點。" if val < float(st.target) else "收回來一點。"
	_wrong(st, msg + "提示：" + String(st.nudge))


func _custom_reveal(msg: String) -> void:
	if fview != null:
		_sv().fan_on = false
	super(msg)


# ================= 速算 =================

func _speed_gen(kind: String, n: int) -> Array:
	if kind != "sector":
		return super(kind, n)
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 2000:
		guard += 1
		var pb := _gen_sector()
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		out.append(pb)
	return out


static func _gen_sector() -> Dictionary:
	var r: int = [2, 3, 4, 5, 6, 8, 9, 10, 12].pick_random()
	var k: int = [1, 2, 3, 4, 6, 8, 9, 10, 15, 16, 18].pick_random()      # θ = kπ/12
	var th := angle_text(k, 12)
	match randi() % 3:
		0:
			return {"eq": "r = %d，θ = %s 的扇形弧長" % [r, th], "q": "扇形弧長 l = rθ。", "template": "l = [0]π",
				"ans": _frac(r * k, 12), "nudge": "%d × %s，約分。" % [r, th], "tag": BankG2.T_FORM}
		1:
			return {"eq": "r = %d，θ = %s 的扇形面積" % [r, th], "q": "扇形面積 A = \\frac{1}{2}r²θ。", "template": "A = [0]π",
				"ans": _frac(r * r * k, 24), "nudge": "\\frac{1}{2} × %d² × %s，約分。" % [r, th], "tag": BankG2.T_FORM}
	var arc := angle_text(r * k, 12)
	return {"eq": "扇形 r = %d，弧長 = %s，圓心角是？" % [r, arc], "q": "θ = l/r。", "template": "θ = [0]π",
		"ans": _frac(k, 12), "nudge": "%s ÷ %d。" % [arc, r], "tag": BankG2.T_FORM}


# ================= 畫面 =================

class SectorView extends MoonView:
	const AMBER := UITheme.ORANGE
	const CYANC := UITheme.CYAN

	var fan_on := false
	var fan_r := 4.0              # 題目的半徑（數字）
	var fan_snap := PI / 12.0     # 0 = 連續
	var fan_theta := PI / 6.0
	var fan_raw := PI / 6.0
	var fan_show := PI / 6.0

	func setup(round: Dictionary) -> void:
		super(round)
		fan_on = false

	func begin_fan(r: float, snap: float) -> void:
		fan_on = true
		fan_r = r
		fan_snap = snap
		fan_theta = PI / 6.0
		fan_raw = fan_theta
		fan_show = fan_theta
		hint_from = t
		spin_changed.emit()

	func set_fan(th: float) -> void:
		fan_raw = clampf(th, 0.04, TAU)
		fan_theta = _snap(fan_raw)
		spin_changed.emit()

	func _snap(th: float) -> float:
		if fan_snap <= 0.0:
			return clampf(th, 0.04, TAU)
		return clampf(roundf(th / fan_snap) * fan_snap, fan_snap, TAU)

	func _process(delta: float) -> void:
		fan_show = lerpf(fan_show, fan_raw if _drag else fan_theta, 1.0 - exp(-14.0 * delta))
		super(delta)

	func _graph_on() -> bool:
		if fan_on:
			return false
		return super()

	func _bottom_limit() -> float:
		if fan_on:
			return size.y - 330.0
		return super()

	func _gui_input(e: InputEvent) -> void:
		if not fan_on:
			super(e)
			return
		var g := _spin_geo()
		var c: Vector2 = g[0]
		var rad: float = g[1]
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				var d: float = e.position.distance_to(c)
				if d > 14.0 and d < rad + 56.0:
					_drag = true
					dragged_ever = true
					_last_a = _ang(e.position, c)
					accept_event()
			elif _drag:
				_drag = false
				fan_raw = fan_theta
				accept_event()
		elif e is InputEventMouseMotion and _drag:
			if e.position.distance_to(c) < 8.0:
				return
			var a := _ang(e.position, c)
			fan_raw = clampf(fan_raw + wrapf(a - _last_a, -PI, PI), 0.04, TAU)
			_last_a = a
			var nt := _snap(fan_raw)
			if not is_equal_approx(nt, fan_theta):
				fan_theta = nt
				spin_changed.emit()
			accept_event()

	func _draw() -> void:
		super()
		if fan_on and kind == "forge" and intro < 0.0:
			_draw_fan(get_theme_default_font())

	## 打開扇子：大張的扇形，弧是藍色、面積是橘色
	func _draw_fan(font: Font) -> void:
		var rc := _spin_rect()
		draw_style_box(UITheme.boxc(Color(0.03, 0.06, 0.14, 0.6), 14, Color(1.0, 0.75, 0.45, 0.25), 1, 0), rc)
		_draw_task(font, rc, "拖動光點打開扇子")
		var g := _spin_geo()
		var c: Vector2 = g[0]
		var rad: float = g[1]
		draw_arc(c, rad, 0, TAU, 96, Color(1, 1, 1, 0.12), 1.5, true)
		var th := fan_show
		var poly := PackedVector2Array([c])
		var n := maxi(6, int(th / 0.05))
		for i in n + 1:
			var a := th * i / n
			poly.append(c + Vector2(cos(a), -sin(a)) * rad)
		draw_colored_polygon(poly, Color(AMBER.r, AMBER.g, AMBER.b, 0.22))
		# 扇骨
		for i in 9:
			var a2 := th * i / 8.0
			draw_line(c, c + Vector2(cos(a2), -sin(a2)) * rad, Color(AMBER.r, AMBER.g, AMBER.b, 0.25), 1.0, true)
		draw_polyline(poly.slice(1), Color(CYANC.r, CYANC.g, CYANC.b, 0.3), 9.0, true)
		draw_polyline(poly.slice(1), CYANC, 3.5, true)
		draw_line(c, c + Vector2(rad, 0), Color(1, 1, 1, 0.8), 2.5)
		var p := c + Vector2(cos(th), -sin(th)) * rad
		draw_line(c, p, Color(1, 1, 1, 0.8), 2.5, true)
		# 半徑的標示
		MathLabel.draw_on(self, font, c.x + rad / 2.0, c.y + 22.0, "r = %d" % int(fan_r), UITheme.fs(15), Color(1, 1, 1, 0.8))
		var mid := c + Vector2(cos(th / 2.0), -sin(th / 2.0)) * (rad + 22.0)
		MathLabel.draw_on(self, font, mid.x, mid.y + 6.0, "弧長", UITheme.fs(15), CYANC)
		UITheme.dot(self, p, 18.0 + 2.0 * sin(t * 4.0), Color(1, 0.85, 0.45, 0.22))
		UITheme.dot(self, p, 9.0, UITheme.GOLD)
		UITheme.dot(self, p, 4.0, Color.WHITE)
		UITheme.dot(self, c, 4.0, Color(1, 1, 1, 0.8))
		_draw_drag_hint(font, c, rad, th)

	# ---------- 下方的示意圖 ----------

	func _draw_circ(font: Font, rect: Rect2) -> void:
		if not circ.has("kind"):
			super(font, rect)
			return
		draw_style_box(UITheme.boxc(Color(0.03, 0.06, 0.14, 0.55), 12, Color(1.0, 0.75, 0.45, 0.22), 1, 0), rect.grow(6))
		_draw_kind(font, rect, String(circ.kind))

	func _txt(font: Font, x: float, y: float, s: String, col := Color(0.9, 0.93, 1.0, 0.85), fs := 15) -> void:
		MathLabel.draw_on(self, font, x, y, s, UITheme.fs(fs), col)

	func _sector_poly(c: Vector2, rad: float, a0: float, a1: float, with_center := true) -> PackedVector2Array:
		var pts := PackedVector2Array()
		if with_center:
			pts.append(c)
		var n := maxi(6, int(absf(a1 - a0) / 0.05))
		for i in n + 1:
			var a := lerpf(a0, a1, float(i) / n)
			pts.append(c + Vector2(cos(a), -sin(a)) * rad)
		return pts

	func _draw_kind(font: Font, rect: Rect2, k: String) -> void:
		var cx := rect.position.x + rect.size.x * 0.34
		var cy := rect.get_center().y + 6.0
		var tx := rect.position.x + rect.size.x * 0.76
		var ty := rect.position.y + 44.0
		match k:
			"sector":
				var th: float = circ.get("theta", 1.0)
				var rad := rect.size.y / 2.0 - 20.0
				var c := Vector2(cx, cy + (rad * 0.35 if th <= PI else 0.0))
				if th <= PI:
					rad = minf(rad * 1.35, rect.size.y - 40.0)
				var poly := _sector_poly(c, rad, 0.0, th)
				draw_colored_polygon(poly, Color(AMBER.r, AMBER.g, AMBER.b, 0.25))
				draw_polyline(poly.slice(1), CYANC, 3.0, true)
				draw_line(c, c + Vector2(rad, 0), Color(1, 1, 1, 0.7), 2.0)
				draw_line(c, poly[poly.size() - 1], Color(1, 1, 1, 0.7), 2.0)
				draw_arc(c, 16.0, -th, 0.0, 16, Color(1, 0.85, 0.45), 1.5, true)
				_txt(font, tx, ty, "r = %s" % _num(float(circ.get("r", 0.0))), Color(1, 0.92, 0.7), 17)
				_txt(font, tx, ty + 34.0, "弧長 l = rθ", CYANC)
				_txt(font, tx, ty + 64.0, "面積 A = \\frac{1}{2}r^{2}θ", AMBER)
			"clock":
				_draw_clock(font, Vector2(cx, cy), rect.size.y / 2.0 - 16.0)
				var note := ""
				match String(circ.get("mode", "")):
					"sweep":
						note = "分針從 %d 分走到 %d 分" % [int(circ.m0), int(circ.m1)]
					"angle":
						note = "%d 點 %d 分" % [int(circ.h), int(circ.m0)]
					"hour":
						note = "時針從 %d 點走到 %d 點" % [int(circ.h0), int(circ.h1)]
				_txt(font, tx, ty + 30.0, note, Color(1, 0.92, 0.7), 16)
			"wheel":
				_draw_wheel(font, rect)
			"belt":
				_draw_belt(font, rect)
			"seg":
				var th2: float = circ.get("theta", 1.0)
				var rad2 := rect.size.y / 2.0 - 18.0
				var c2 := Vector2(cx, cy)
				draw_arc(c2, rad2, 0, TAU, 72, Color(1, 1, 1, 0.35), 1.5, true)
				var a0 := PI / 2.0 - th2 / 2.0
				var a1 := PI / 2.0 + th2 / 2.0
				var arc := _sector_poly(c2, rad2, a0, a1, false)
				draw_colored_polygon(_sector_poly(c2, rad2, a0, a1), Color(AMBER.r, AMBER.g, AMBER.b, 0.12))
				var segp := arc.duplicate()
				draw_colored_polygon(segp, Color(1.0, 0.55, 0.7, 0.45))
				draw_polyline(arc, CYANC, 2.5, true)
				var pa: Vector2 = arc[0]
				var pb: Vector2 = arc[arc.size() - 1]
				draw_line(pa, pb, Color(1, 1, 1, 0.8), 2.0, true)
				draw_line(c2, pa, Color(1, 1, 1, 0.5), 1.5, true)
				draw_line(c2, pb, Color(1, 1, 1, 0.5), 1.5, true)
				_txt(font, tx, ty, "弓形 = 扇形 − 三角形", Color(1.0, 0.7, 0.8), 16)
				_txt(font, tx, ty + 34.0, "扇形 = \\frac{1}{2}r^{2}θ", AMBER)
				_txt(font, tx, ty + 64.0, "三角形 = \\frac{1}{2}r^{2} sin θ", Color(0.9, 0.93, 1.0, 0.85))
			"lens":
				var rad3 := rect.size.y / 2.0 - 22.0
				var d := rad3
				var ca := Vector2(cx - d / 2.0, cy)
				var cb := Vector2(cx + d / 2.0, cy)
				var pa1 := _sector_poly(ca, rad3, -PI / 3.0, PI / 3.0, false)
				var pb1 := _sector_poly(cb, rad3, 2.0 * PI / 3.0, 4.0 * PI / 3.0, false)
				var lens := pa1.duplicate()
				lens.append_array(pb1)
				draw_colored_polygon(lens, Color(1.0, 0.55, 0.7, 0.4))
				draw_arc(ca, rad3, 0, TAU, 72, Color(1, 1, 1, 0.45), 1.5, true)
				draw_arc(cb, rad3, 0, TAU, 72, Color(1, 1, 1, 0.45), 1.5, true)
				var top: Vector2 = pa1[pa1.size() - 1]
				var bot: Vector2 = pa1[0]
				draw_line(top, bot, Color(1, 1, 1, 0.7), 1.5, true)
				for q in [ca, cb]:
					draw_line(q, top, Color(1, 0.85, 0.45, 0.6), 1.5, true)
					draw_line(q, bot, Color(1, 0.85, 0.45, 0.6), 1.5, true)
					UITheme.dot(self, q, 3.5, Color.WHITE)
				_txt(font, tx, ty + 10.0, "重疊 = 兩個弓形", Color(1.0, 0.7, 0.8), 16)
				_txt(font, tx, ty + 44.0, "每個圓心角 2π/3", Color(1, 0.85, 0.45))
			"cone":
				_draw_cone(font, rect)
			"ant":
				_draw_ant(font, rect)
			"ant3d":
				_draw_ant3d(font, rect)
			"parab":
				_draw_parab(font, rect)

	static func _num(v: float) -> String:
		return str(int(v)) if is_equal_approx(v, roundf(v)) else String.num(v, 2)

	## 時鐘：分針掃過的扇形（sweep）、兩根指針的夾角（angle）、時針掃過的扇形（hour）
	func _draw_clock(font: Font, c: Vector2, rad: float) -> void:
		UITheme.dot(self, c, rad + 4.0, Color(0.95, 0.9, 0.8, 0.10))
		draw_arc(c, rad, 0, TAU, 72, Color(1, 1, 1, 0.55), 2.0, true)
		for i in 60:
			var a := TAU * i / 60.0
			var d := Vector2(sin(a), -cos(a))
			var big := i % 5 == 0
			draw_line(c + d * (rad - (8.0 if big else 4.0)), c + d * rad, Color(1, 1, 1, 0.5 if big else 0.2), 1.5 if big else 1.0)
		for nmb in [12, 3, 6, 9]:
			var a2: float = TAU * nmb / 12.0
			var p := c + Vector2(sin(a2), -cos(a2)) * (rad - 18.0)
			draw_string(font, p + Vector2(-12, 6), str(nmb), HORIZONTAL_ALIGNMENT_CENTER, 24, UITheme.fs(13), Color(1, 1, 1, 0.55))
		var mode := String(circ.get("mode", "sweep"))
		var hand := func(frac: float, l: float, col: Color, w: float):
			var a3 := TAU * frac
			draw_line(c, c + Vector2(sin(a3), -cos(a3)) * l, col, w, true)
		# 時鐘角度 a（從 12 點順時針）→ 畫圖用的數學角度
		var to_math := func(frac: float) -> float:
			return PI / 2.0 - TAU * frac
		match mode:
			"sweep":
				var f0: float = float(circ.m0) / 60.0
				var f1: float = f0 + 0.0
				var m1: float = float(circ.m1)
				var prog := clampf(fposmod(t * 0.35, 1.4), 0.0, 1.0)
				f1 = lerpf(f0, m1 / 60.0, prog)
				if f1 > f0 + 0.001:
					var poly := _sector_poly(c, rad - 6.0, to_math.call(f0), to_math.call(f1))
					draw_colored_polygon(poly, Color(AMBER.r, AMBER.g, AMBER.b, 0.3))
					draw_polyline(poly.slice(1), CYANC, 3.0, true)
				var hf: float = (float(circ.h) + m1 / 60.0) / 12.0
				hand.call(hf, rad * 0.5, Color(1, 1, 1, 0.6), 4.0)
				hand.call(f1, rad - 8.0, UITheme.GOLD, 3.0)
			"hour":
				var g0: float = float(circ.h0) / 12.0
				var g1: float = float(circ.h1) / 12.0
				var prog2 := clampf(fposmod(t * 0.35, 1.4), 0.0, 1.0)
				var gf := lerpf(g0, g1, prog2)
				if gf > g0 + 0.001:
					var poly2 := _sector_poly(c, rad * 0.62, to_math.call(g0), to_math.call(gf))
					draw_colored_polygon(poly2, Color(AMBER.r, AMBER.g, AMBER.b, 0.3))
					draw_polyline(poly2.slice(1), CYANC, 3.0, true)
				hand.call(0.0, rad - 8.0, Color(1, 1, 1, 0.45), 2.0)
				hand.call(gf, rad * 0.62, UITheme.GOLD, 4.5)
			"angle":
				var mf: float = float(circ.m0) / 60.0
				var hf2: float = (float(circ.h) + float(circ.m0) / 60.0) / 12.0
				var lo := minf(mf, hf2)
				var hi := maxf(mf, hf2)
				if hi - lo > 0.5:
					var tmp := lo
					lo = hi
					hi = tmp + 1.0
				var poly3 := _sector_poly(c, rad * 0.4, to_math.call(lo), to_math.call(hi))
				draw_colored_polygon(poly3, Color(1.0, 0.55, 0.7, 0.35))
				hand.call(hf2, rad * 0.55, UITheme.PINK_LIGHT, 4.5)
				hand.call(mf, rad - 8.0, UITheme.GOLD, 3.0)
		UITheme.dot(self, c, 4.0, Color.WHITE)

	## 車輪：左邊是一開始（A 貼地），右邊是滾過之後，A 的高度
	func _draw_wheel(font: Font, rect: Rect2) -> void:
		var th: float = circ.get("theta", PI)
		var rad := rect.size.y / 2.0 - 30.0
		var gy := rect.end.y - 18.0
		draw_line(Vector2(rect.position.x + 10, gy), Vector2(rect.end.x - 10, gy), Color(1, 1, 1, 0.5), 2.0)
		var x0 := rect.position.x + rad + 30.0
		var roll := rad * th
		var maxroll := rect.size.x - 2.0 * rad - 80.0
		var k := minf(1.0, maxroll / maxf(roll, 1.0))
		var prog := clampf(fposmod(t * 0.3, 1.5), 0.0, 1.0)
		var c0 := Vector2(x0, gy - rad)
		draw_arc(c0, rad, 0, TAU, 48, Color(1, 1, 1, 0.2), 1.5, true)
		UITheme.dot(self, c0 + Vector2(0, rad), 4.0, Color(1, 1, 1, 0.35))
		var cur := th * prog
		var c1 := Vector2(x0 + roll * k * prog, gy - rad)
		draw_arc(c1, rad, 0, TAU, 48, Color(1, 1, 1, 0.7), 2.0, true)
		# 已經滾過的距離（地上）和轉過的弧（輪子上）
		draw_line(Vector2(x0, gy), Vector2(c1.x, gy), Color(CYANC.r, CYANC.g, CYANC.b, 0.9), 4.0)
		var a_math := -PI / 2.0 - cur            # 向右滾 = 順時針轉
		var arc := _sector_poly(c1, rad, -PI / 2.0, a_math, false)
		draw_polyline(arc, CYANC, 3.0, true)
		var pa := c1 + Vector2(cos(a_math), -sin(a_math)) * rad
		draw_line(c1, pa, Color(1, 1, 1, 0.6), 1.5, true)
		draw_dashed_line(pa, Vector2(pa.x, gy), UITheme.GOLD, 2.0, 5.0)
		UITheme.dot(self, pa, 6.0, UITheme.GOLD)
		draw_string(font, pa + Vector2(8, -6), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), UITheme.GOLD)
		UITheme.dot(self, c1, 3.0, Color.WHITE)
		_txt(font, rect.end.x - 110.0, rect.position.y + 36.0, "滾過的距離 = 弧長", CYANC, 14)

	## 捆罐頭：圓 + 外面一圈繩子（直線段 + 弧）
	func _draw_belt(font: Font, rect: Rect2) -> void:
		var n: int = circ.get("n", 2)
		var rad := 30.0
		var centers := []
		var cc := Vector2(rect.position.x + rect.size.x * 0.36, rect.get_center().y + 4.0)
		if String(circ.get("layout", "row")) == "square":
			for q in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				centers.append(cc + q * rad)
		else:
			for i in n:
				centers.append(cc + Vector2((i - (n - 1) / 2.0) * 2.0 * rad, 0))
		var rope: Array
		if centers.size() >= 3:
			rope = Geometry2D.offset_polygon(PackedVector2Array(centers), rad + 2.0, Geometry2D.JOIN_ROUND)
		else:
			rope = Geometry2D.offset_polyline(PackedVector2Array(centers), rad + 2.0, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
		for q in centers:
			UITheme.dot(self, q, rad, Color(0.8, 0.85, 0.95, 0.18))
			draw_arc(q, rad, 0, TAU, 48, Color(1, 1, 1, 0.6), 1.5, true)
			UITheme.dot(self, q, 2.5, Color(1, 1, 1, 0.7))
		for i in range(centers.size()):
			var j := (i + 1) % centers.size()
			if centers.size() == 2 and i == 1:
				break
			draw_line(centers[i], centers[j], Color(1, 0.85, 0.45, 0.5), 1.0, true)
		for poly in rope:
			var pl: PackedVector2Array = poly
			pl.append(pl[0])
			draw_polyline(pl, CYANC, 3.0, true)
		_txt(font, rect.position.x + rect.size.x * 0.78, rect.position.y + 50.0, "繩長 = 直線段 + 一整圈", CYANC, 15)

	## 扇形捲成圓錐：左邊的扇形 → 右邊的圓錐（弧長 = 底圓周長，一閃一閃地對應）
	func _draw_cone(font: Font, rect: Rect2) -> void:
		var R: float = circ.get("R", 9.0)
		var th: float = circ.get("theta", PI)
		var pulse := 0.6 + 0.4 * sin(t * 3.0)
		var srad := rect.size.y / 2.0 - 16.0
		var sc := Vector2(rect.position.x + rect.size.x * 0.24, rect.get_center().y + 4.0)
		var a0 := PI / 2.0 - th / 2.0
		var poly := _sector_poly(sc, srad, a0, a0 + th)
		draw_colored_polygon(poly, Color(AMBER.r, AMBER.g, AMBER.b, 0.25))
		draw_polyline(poly.slice(1), Color(CYANC.r, CYANC.g, CYANC.b, pulse), 3.5, true)
		draw_line(sc, poly[1], Color(1, 1, 1, 0.7), 2.0)
		draw_line(sc, poly[poly.size() - 1], Color(1, 1, 1, 0.7), 2.0)
		_txt(font, sc.x, sc.y + 22.0, "半徑 %s" % _num(R), Color(1, 1, 1, 0.75), 13)
		# 箭頭
		var mx := rect.position.x + rect.size.x * 0.5
		draw_line(Vector2(mx - 26, sc.y), Vector2(mx + 18, sc.y), Color(1, 1, 1, 0.5), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(mx + 26, sc.y), Vector2(mx + 16, sc.y - 6), Vector2(mx + 16, sc.y + 6)]), Color(1, 1, 1, 0.5))
		# 圓錐（底半徑 r = Rθ/2π）
		var rr := R * th / TAU
		var hh := sqrt(maxf(0.0, R * R - rr * rr))
		var s := (rect.size.y - 46.0) / maxf(hh, 1.0)
		s = minf(s, 70.0 / maxf(rr, 0.1))
		var apex := Vector2(rect.position.x + rect.size.x * 0.72, rect.position.y + 18.0)
		var base := apex + Vector2(0, hh * s)
		var bw := rr * s
		draw_colored_polygon(PackedVector2Array([apex, base + Vector2(-bw, 0), base + Vector2(bw, 0)]), Color(AMBER.r, AMBER.g, AMBER.b, 0.22))
		draw_line(apex, base + Vector2(-bw, 0), Color(1, 1, 1, 0.7), 2.0, true)
		draw_line(apex, base + Vector2(bw, 0), Color(1, 1, 1, 0.7), 2.0, true)
		var ell := PackedVector2Array()
		for i in 49:
			var a := TAU * i / 48.0
			ell.append(base + Vector2(cos(a) * bw, sin(a) * bw * 0.28))
		draw_polyline(ell, Color(CYANC.r, CYANC.g, CYANC.b, pulse), 3.0, true)
		draw_dashed_line(apex, base, Color(1, 1, 1, 0.35), 1.2, 4.0)
		_txt(font, rect.end.x - 64.0, rect.position.y + 40.0, "弧長", CYANC, 14)
		_txt(font, rect.end.x - 64.0, rect.position.y + 62.0, "= 底圓周長", CYANC, 14)

	## 螞蟻：攤開的扇形，兩端點 A、A′ 的弦就是最短路徑（螞蟻沿著弦走）
	func _draw_ant(font: Font, rect: Rect2) -> void:
		var th: float = circ.get("theta", PI)
		var srad := rect.size.y - 46.0
		var sc := Vector2(rect.position.x + rect.size.x * 0.36, rect.position.y + 16.0)
		# 扇形開口朝下
		var a0 := -PI / 2.0 - th / 2.0
		var poly := _sector_poly(sc, srad, a0, a0 + th)
		if th > PI * 0.9:
			srad = rect.size.y / 2.0 - 10.0
			sc = Vector2(sc.x, rect.get_center().y)
			poly = _sector_poly(sc, srad, a0, a0 + th)
		draw_colored_polygon(poly, Color(AMBER.r, AMBER.g, AMBER.b, 0.2))
		draw_polyline(poly.slice(1), Color(1, 1, 1, 0.5), 2.0, true)
		var pa: Vector2 = poly[1]
		var pb: Vector2 = poly[poly.size() - 1]
		draw_line(sc, pa, Color(1, 1, 1, 0.7), 2.0)
		draw_line(sc, pb, Color(1, 1, 1, 0.7), 2.0)
		draw_line(pa, pb, UITheme.GOLD, 3.0, true)
		var u := fposmod(t * 0.3, 1.0)
		UITheme.dot(self, pa.lerp(pb, u), 5.0, Color(1, 0.5, 0.6))
		draw_string(font, pa + Vector2(-16, 18), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 1, 1, 0.8))
		draw_string(font, pb + Vector2(6, 18), "A′", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 1, 1, 0.8))
		_txt(font, rect.position.x + rect.size.x * 0.8, rect.position.y + 44.0, "攤開側面", Color(1, 0.92, 0.7), 15)
		_txt(font, rect.position.x + rect.size.x * 0.8, rect.position.y + 72.0, "最短 = 弦 AA′", UITheme.GOLD, 15)

	## 立體的圓錐：螞蟻從底圓上的 A 出發，沿著側面繞一圈回到 A（前面實線、後面虛線），路線就是攤開後的那條直線
	func _draw_ant3d(font: Font, rect: Rect2) -> void:
		var L: float = circ.get("R", 3.0)
		var rr: float = circ.get("r", 1.0)
		var hh := sqrt(maxf(0.01, L * L - rr * rr))
		# 示意圖不照比例：高度固定、底圓至少有一定的寬度（細長的圓錐也看得清楚路線）
		var s := (rect.size.y - 78.0) / hh
		var apex := Vector2(rect.position.x + rect.size.x * 0.42, rect.position.y + 10.0)
		var base := apex + Vector2(0, hh * s)
		var bw := clampf(rr * s, rect.size.x * 0.13, rect.size.x * 0.2)
		var ey := 0.3
		# 圓錐本體
		draw_colored_polygon(PackedVector2Array([apex, base + Vector2(-bw, 0), base + Vector2(bw, 0)]), Color(AMBER.r, AMBER.g, AMBER.b, 0.18))
		var back := PackedVector2Array()
		var front := PackedVector2Array()
		for i in 25:
			var a := PI * i / 24.0
			back.append(base + Vector2(cos(a) * bw, -sin(a) * bw * ey))
			front.append(base + Vector2(cos(a) * bw, sin(a) * bw * ey))
		draw_polyline(back, Color(1, 1, 1, 0.3), 1.5, true)
		draw_polyline(front, Color(1, 1, 1, 0.75), 2.0, true)
		draw_line(apex, base + Vector2(-bw, 0), Color(1, 1, 1, 0.75), 2.0, true)
		draw_line(apex, base + Vector2(bw, 0), Color(1, 1, 1, 0.75), 2.0, true)
		# 螞蟻的路線：攤開後是直線，離頂點的距離 d(ψ) = L cos(θ/2) / cos(ψ − θ/2)，ψ 從 0 到 θ
		var th := TAU * rr / L
		var to3 := func(psi: float) -> Vector2:
			var d := L * cos(th / 2.0) / cos(psi - th / 2.0)
			var phi := psi * L / rr                  # 繞著軸轉的角度（從正前方開始）
			var k := d / L
			var p := apex + Vector2(0, hh * s * k)
			return p + Vector2(sin(phi) * bw * k, cos(phi) * bw * k * ey)
		var n := 72
		var prev: Vector2 = to3.call(0.0)
		for i in range(1, n + 1):
			var psi := th * i / n
			var q: Vector2 = to3.call(psi)
			var phi2 := psi * L / rr
			var front_side := cos(phi2 - (th * 0.5 / n) * L / rr) > 0.0
			if front_side:
				draw_line(prev, q, UITheme.GOLD, 2.5, true)
			elif i % 2 == 0:
				draw_line(prev, q, Color(1, 0.81, 0.35, 0.55), 1.8, true)
			prev = q
		var pa: Vector2 = to3.call(0.0)
		UITheme.dot(self, pa, 5.0, Color.WHITE)
		draw_string(font, pa + Vector2(-22, 18), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 1, 1, 0.85))
		# 爬行中的螞蟻
		var u := fposmod(t * 0.18, 1.0)
		UITheme.dot(self, to3.call(th * u), 5.0, Color(1, 0.5, 0.6))
		draw_dashed_line(apex, base, Color(1, 1, 1, 0.25), 1.2, 4.0)
		_txt(font, rect.position.x + rect.size.x * 0.78, rect.position.y + 44.0, "螞蟻繞側面一圈", Color(1, 0.92, 0.7), 15)
		_txt(font, rect.position.x + rect.size.x * 0.78, rect.position.y + 76.0, "攤開來看是直線", UITheme.GOLD, 15)

	## 周長固定的扇形面積：A(r) = \\frac{1}{2}r(L − 2r) 的拋物線，頂點在 r = L/4
	func _draw_parab(font: Font, rect: Rect2) -> void:
		var L: float = circ.get("L", 20.0)
		var area := Rect2(rect.position.x + 30.0, rect.position.y + 18.0, rect.size.x * 0.56, rect.size.y - 40.0)
		var amax := L * L / 16.0
		var to_px := func(r: float, a: float) -> Vector2:
			return Vector2(area.position.x + r / (L / 2.0) * area.size.x, area.end.y - a / (amax * 1.15) * area.size.y)
		draw_line(Vector2(area.position.x, area.end.y), Vector2(area.end.x + 10, area.end.y), Color(1, 1, 1, 0.45), 1.5)
		draw_line(Vector2(area.position.x, area.end.y), Vector2(area.position.x, area.position.y - 6), Color(1, 1, 1, 0.45), 1.5)
		draw_string(font, Vector2(area.end.x + 12, area.end.y + 4), "r", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 1, 1, 0.6))
		draw_string(font, Vector2(area.position.x - 18, area.position.y), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 1, 1, 0.6))
		var pts := PackedVector2Array()
		for i in 41:
			var r := L / 2.0 * i / 40.0
			pts.append(to_px.call(r, 0.5 * r * (L - 2.0 * r)))
		draw_polyline(pts, Color(AMBER.r, AMBER.g, AMBER.b, 0.25), 8.0, true)
		draw_polyline(pts, AMBER, 2.5, true)
		var v: Vector2 = to_px.call(L / 4.0, amax)
		draw_dashed_line(v, Vector2(v.x, area.end.y), Color(1, 1, 1, 0.4), 1.2, 4.0)
		UITheme.dot(self, v, 8.0 + 1.5 * sin(t * 4.0), Color(1, 0.85, 0.45, 0.25))
		UITheme.dot(self, v, 4.5, UITheme.GOLD)
		_txt(font, rect.position.x + rect.size.x * 0.82, rect.position.y + 44.0, "A = \\frac{1}{2}r(%s − 2r)" % _num(L), AMBER, 15)
		_txt(font, rect.position.x + rect.size.x * 0.82, rect.position.y + 76.0, "頂點：面積最大", Color(1, 0.92, 0.7), 15)
