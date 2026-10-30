extends "step_level.gd"
## 三角函數 第一大關「弧之渡口」（對應講義 1-1 重點一：弧度量）
## 引擎是 step_level.gd（一步一步推導），題庫在 trig1_bank.gd。
##
## 這一關多了：
##   ・spin 步驟：在單位圓上拖動終邊，轉出指定的角（逆時針為正、順時針為負，可以轉好幾圈；每格 π/12 = 15°）
##     右邊也有「−15°」「+15°」「歸零」的按鈕，手指不好拖的時候用。
##   ・下方的單位圓示意圖：轉好的角、題目給的角（例如 20 弧度），或比大小時的好幾個角
##   ・速算：度 ⇄ 弧度（conv）、特殊角的值（val）
##   ・月光的背景（不是熔爐的火光）

const BankG1 := preload("trig1_bank.gd")
const MOON := UITheme.CYAN
const STEP := PI / 12.0

const CHAPTERS_G1 := [
	{"ch": 1, "name": "第一章．弧與角", "topic": "度與弧度、有向角、同界角與象限", "color": UITheme.CYAN},
	{"ch": 2, "name": "第二章．月光刻度", "topic": "單位圓求值、奇變偶不變與比大小", "color": UITheme.BLUE},
]

var spin_info: MathLabel


func level_id() -> String:
	return "G1"

func level_title() -> String:
	return "弧之渡口"

func level_subtitle() -> String:
	return "弧度量"

func level_chapters() -> Array:
	return CHAPTERS_G1

func bank_slots() -> Array:
	return BankG1.slots()

func step_color() -> Color:
	return MOON

func stage_style() -> Dictionary:
	return {"sky_top": Color("0c1a3a"), "sky_bot": Color("08142b"), "scenery": "none", "ambient": "moonsea"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．月光刻度", "button": "進入月光刻度  ▶",
		"text": "月光照在單位圓上：\n\n" \
			+ "・終邊和單位圓的交點是 (cos θ, sin θ)\n" \
			+ "・求值三步：象限 → 參考角 → 正負號\n" \
			+ "・奇變偶不變，符號看象限\n" \
			+ "・沒有 π 的角是弧度：sin 1、sin 2、sin 3 誰大？\n\n" \
			+ "準備好了就出發吧！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = MoonView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "速算"
		_mv().spin_changed.connect(_refresh_spin)


func _mv() -> MoonView:
	return fview as MoonView


# ================= 轉角（spin） =================

func _forge_step() -> void:
	if fview != null:
		_mv().spin_on = false
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_update_circle()
	super()
	if si < steps.size() and String(steps[si].kind) == "spin":
		_build_spin(steps[si])


## 下方的單位圓：題目指定的（circle.after 這一步之後），或是剛剛轉好的角
func _update_circle() -> void:
	var spec: Dictionary = r.get("circle", {})
	if not spec.is_empty() and si > int(spec.get("after", -1)) and _mv().spun.is_empty():
		_mv().circ = spec


func _build_spin(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.box(Color(MOON.r, MOON.g, MOON.b, 0.08), 14,
		Color(MOON.r, MOON.g, MOON.b, 0.4), 1, 12))
	rank_box.add_child(card)
	spin_info = MathLabel.new()
	spin_info.font_size = UITheme.fs(24)
	spin_info.max_width = 320
	spin_info.align_center = true
	spin_info.color = UITheme.TEXT
	# 固定高度（以分數的高度為準），角度從 2π 變成 25π/12 時框框不會變高，下面的按鈕也不會跳
	spin_info.valign_center = true
	spin_info.custom_minimum_size = Vector2(0, 70)
	card.add_child(spin_info)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	rank_box.add_child(row)
	for spec in [["↻  −15°", -1], ["↺  +15°", 1], ["歸零", 0]]:
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
			_mv().set_spin(0 if d == 0 else _mv().spin_k + d)
			Game.of(self).play("blip", 1.0 + 0.02 * clampi(_mv().spin_k, -24, 24), -14.0))
		row.add_child(b)
	var tip := Label.new()
	tip.text = "拖動圓上的光點轉動：逆時針是正、順時針是負，可以轉超過一圈。"
	tip.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	tip.custom_minimum_size = Vector2(300, 0)
	tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(tip)
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "確定"
	var mv := _mv()
	mv.spin_on = true
	mv.spin_begin()
	mv.task_q = String(st.q)
	mv.circ = {}
	mv.set_spin(0)
	mv.mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_spin()


func _refresh_spin() -> void:
	if spin_info == null or not is_instance_valid(spin_info):
		return
	var k := _mv().spin_k
	spin_info.text = "θ = %s　（%s°）" % [angle_text(k, 12), _deg_text(k * 15)]


static func _deg_text(d: int) -> String:
	return ("−" if d < 0 else "") + str(absi(d))


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size() and String(steps[si].kind) == "spin":
		_spin_submit()
		return
	super()


func _spin_submit() -> void:
	var st: Dictionary = steps[si]
	var mv := _mv()
	var want := roundi(float(st.target) / STEP)
	if mv.spin_k == want:
		Game.of(self).sfx("correct")
		mv.spin_on = false
		mv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mv.spun = {"theta": want * STEP, "label": angle_text(want, 12)}
		mv.circ = mv.spun
		mv.burst_center()
		go_btn.visible = false
		_clear(rank_box)
		rank_box.visible = false
		_step_done(st, "")
		return
	var msg := "還不對。提示：" + String(st.nudge)
	if mv.spin_k == 0:
		msg = "還沒有轉喔！拖動圓上的光點（或用下面的按鈕）。"
	elif posmod(mv.spin_k - want, 24) == 0:
		msg = "終邊的位置對了，可是轉的圈數或方向不對。" + String(st.nudge)
	elif mv.spin_k == -want:
		msg = "方向反了：逆時針是正、順時針是負。"
	_wrong(st, msg)


func _custom_reveal(msg: String) -> void:
	if fview != null:
		_mv().spin_on = false
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	super(msg)


## k·π/den 寫成文字：π/6、−3π/4、2π、0
static func angle_text(k: int, den: int) -> String:
	if k == 0:
		return "0"
	var g := _gcd(absi(k), den)
	var n := absi(k) / g
	var d := den / g
	var s := ("π" if n == 1 else "%dπ" % n) + ("" if d == 1 else "/%d" % d)
	return ("−" if k < 0 else "") + s


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return maxi(a, 1)


static func _frac(num: int, den: int) -> String:
	if den < 0:
		num = -num
		den = -den
	var g := _gcd(absi(num), den)
	num /= g
	den /= g
	var t := str(absi(num)) if den == 1 else "%d/%d" % [absi(num), den]
	return ("−" if num < 0 and num != 0 else "") + t


# ================= 速算 =================

func _speed_show() -> void:
	var pb: Dictionary = problems[sp_i]
	fview.show_speed(pb.eq, sp_i, problems.size(), streak)
	step_label.text = UITheme.step_bar(_steps(), 0)
	if sp_i > 0:
		story_label.visible = false
	_build_fill({"name": "速算", "q": pb.q, "template": pb.template, "answers": [pb.ans], "mode": "ordered",
		"nudge": pb.nudge, "tag": pb.tag, "line": ""})


func _speed_tag() -> String:
	return BankG1.T_CONV


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


const DEGS := [15, 18, 30, 36, 45, 60, 72, 75, 90, 105, 120, 135, 150, 165, 180, 210, 225, 240, 270, 300, 315, 330,
	360, 390, 405, 450, 540, 720, -30, -45, -60, -90, -120, -135, -150, -180, -270]


## 速算題：{eq, q, template, ans, nudge, tag}
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 2000:
		guard += 1
		var pb := _gen_conv() if kind == "conv" else _gen_val()
		if pb.is_empty() or seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		out.append(pb)
	return out


static func _gen_conv() -> Dictionary:
	var d: int = DEGS.pick_random()
	var rad := _frac(d, 180) if d % 180 != 0 else str(d / 180)
	# 弧度的寫法：k·π/180 約分
	var g := _gcd(absi(d), 180)
	var ptext := angle_text(d / g, 180 / g) if d != 0 else "0"
	if randf() < 0.5:
		return {"eq": "%s°" % _deg_text(d), "q": "化成弧度（填 π 前面的係數，可以填負數或分數）。", "template": "[0]π",
			"ans": rad, "nudge": "乘 π/180：%s/180 約分。" % _deg_text(d), "tag": BankG1.T_CONV}
	return {"eq": ptext, "q": "化成度。", "template": "[0]°", "ans": str(d),
		"nudge": "乘 180/π：把 π 換成 180°。", "tag": BankG1.T_CONV}


static func _gen_val() -> Dictionary:
	var fn: String = ["sin", "cos", "tan"].pick_random()
	# 特殊角：π/6 和 π/4 的倍數（−2π ～ 2π）
	var den: int = [6, 4, 3].pick_random() if fn != "tan" else [6, 4, 3].pick_random()
	var k := randi_range(-2 * den, 2 * den)
	var th := PI * k / den
	var v := 0.0
	match fn:
		"sin":
			v = sin(th)
		"cos":
			v = cos(th)
		"tan":
			if absf(cos(th)) < 1e-9:
				return {}       # tan(π/2) 沒有定義
			v = tan(th)
	var ans := ""
	var r2 := sqrt(2.0)
	var r3 := sqrt(3.0)
	for cand in [[0.0, "0"], [0.5, "1/2"], [1.0, "1"], [r3 / 2.0, "√3/2"], [r2 / 2.0, "√2/2"], [r3, "√3"], [r3 / 3.0, "√3/3"]]:
		for sg in [1.0, -1.0]:
			if absf(v - sg * float(cand[0])) < 1e-6:
				ans = ("−" if sg < 0.0 and cand[1] != "0" else "") + String(cand[1])
	if ans == "" or (k == 0 and randf() < 0.8) or (ans == "0" and randf() < 0.6):
		return {}
	var g := _gcd(absi(k), den)
	var at := angle_text(k / g, den / g)
	return {"eq": "%s(%s)" % [fn, at], "q": "求值。", "template": "%s(%s) = [0]" % [fn, at],
		"ans": ans, "nudge": "先找參考角，再看終邊在哪個象限決定正負。", "tag": BankG1.T_SPEC}


## 這一關的填空都可以按「√」
func radicals_ok() -> bool:
	return true


# ================= 畫面：月光下的推導台 + 單位圓 =================

class MoonView extends ForgeView:
	signal spin_changed

	const MOONC := UITheme.CYAN
	const SILVER := UITheme.TEXT
	const PINK := UITheme.PINK_LIGHT
	const STEPA := PI / 12.0

	var spin_on := false
	var spin_k := 0              # 目前轉到第幾格（π/12 一格）
	var spin_raw := 0.0          # 拖動中的實際角度
	var spin_show := 0.0         # 畫面上的角度（慢慢追上 spin_k）
	var _drag := false
	var _last_a := 0.0
	# 拖動提示：還沒拖過（或這一步放著不動一陣子）時，一隻小手示範「按住光點、沿著圓轉」
	## 學生拖過一次（或按過 ±15° 按鈕）就記住：之後整個遊戲期間都不再示範（換題、換關卡也一樣）
	static var dragged_ever := false
	var hint_from := 0.0          # 這一步開始（或最後一次拖動）的時間

	func spin_begin() -> void:
		hint_from = t
	var task_q := ""             # 互動步驟（轉角、扇子、波浪）的題目要求：寫在互動框的上方，只看中間也知道要做什麼
	var circ := {}               # 下方的單位圓示意圖
	var spun := {}               # 這一題剛剛轉好的角（留在下方）

	func setup(round: Dictionary) -> void:
		super(round)
		spin_on = false
		spin_k = 0
		spin_raw = 0.0
		spin_show = 0.0
		_drag = false
		circ = {}
		spun = {}

	func set_spin(k: int) -> void:
		k = clampi(k, -72, 72)
		spin_k = k
		spin_raw = k * STEPA
		spin_changed.emit()

	func _process(delta: float) -> void:
		spin_show = lerpf(spin_show, spin_raw if _drag else spin_k * STEPA, 1.0 - exp(-14.0 * delta))
		super(delta)

	# ---------- 版面 ----------

	func _graph_on() -> bool:
		return (not circ.is_empty() and not spin_on) or super()

	func _bottom_limit() -> float:
		if spin_on:
			return size.y - 330.0
		return super()

	func _spin_rect() -> Rect2:
		return Rect2(36, size.y - 316, size.x - 72, 300)

	func _spin_geo() -> Array:
		var rc := _spin_rect()
		var c := rc.get_center() + Vector2(0, 8)
		var rad := minf(rc.size.x, rc.size.y) / 2.0 - 56.0
		return [c, rad]

	# ---------- 拖動 ----------

	func _gui_input(e: InputEvent) -> void:
		if not spin_on:
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
					hint_from = t
					_last_a = _ang(e.position, c)
					accept_event()
			elif _drag:
				_drag = false
				spin_raw = spin_k * STEPA
				accept_event()
		elif e is InputEventMouseMotion and _drag:
			if e.position.distance_to(c) < 8.0:
				return
			var a := _ang(e.position, c)
			spin_raw = clampf(spin_raw + wrapf(a - _last_a, -PI, PI), -6.0 * PI, 6.0 * PI)
			_last_a = a
			var k := roundi(spin_raw / STEPA)
			if k != spin_k:
				spin_k = k
				spin_changed.emit()
			accept_event()

	## 互動框上方的題目要求（靠左；太長就縮小字）
	func _draw_task(font: Font, rc: Rect2, fallback: String, max_w := 0.0) -> void:
		var s := task_q if task_q != "" else fallback
		if max_w <= 0.0:
			max_w = rc.size.x - 28.0
		var fs := UITheme.fs(17)
		while fs > UITheme.fs(12) and MathLabel.text_width(font, s, fs) > max_w:
			fs -= 1
		var w := MathLabel.text_width(font, s, fs)
		var ex := MathLabel.line_extent(s, fs)
		MathLabel.draw_on(self, font, rc.position.x + 14.0 + w / 2.0, rc.position.y + 14.0 + ex.x, s, fs, Color(1, 0.92, 0.7))

	static func _ang(p: Vector2, c: Vector2) -> float:
		return atan2(-(p.y - c.y), p.x - c.x)

	# ---------- 繪圖 ----------

	func _draw() -> void:
		super()
		if spin_on and kind == "forge" and intro < 0.0:
			_draw_spin(get_theme_default_font())

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if not circ.is_empty():
			_draw_circ(font, rect)
		else:
			super(font, rect)

	## 月光的背景：深藍的夜、右上角的月亮、慢慢閃的星星、底部的水光
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("0c1a3a"), Color("0c1a3a"), Color("071226"), Color("071226")]))
		var mc := Vector2(w - 70, 70)
		UITheme.dot(self, mc, 60.0, Color(0.85, 0.9, 1.0, 0.035))
		UITheme.dot(self, mc, 34.0, Color(0.85, 0.9, 1.0, 0.06))
		UITheme.dot(self, mc, 22.0, Color(0.92, 0.95, 1.0, 0.10))
		for i in 34:
			var p := Vector2(fposmod(i * 0.618, 1.0) * w, fposmod(i * 0.377, 1.0) * h * 0.8)
			var a := 0.10 + 0.12 * sin(t * (0.8 + fposmod(i * 0.29, 1.0)) + i)
			UITheme.dot(self, p, 1.0 + fposmod(i * 0.41, 1.0) * 1.2, Color(0.85, 0.92, 1.0, maxf(0.0, a)))
		var glow := 0.08 + 0.02 * sin(t * 1.3)
		draw_polygon(PackedVector2Array([Vector2(0, h * 0.7), Vector2(w, h * 0.7), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color(0.35, 0.75, 1.0, 0.0), Color(0.35, 0.75, 1.0, 0.0), Color(0.35, 0.6, 1.0, glow), Color(0.35, 0.6, 1.0, glow)]))
		for k in 4:
			var yy := h - 14.0 - 16.0 * k
			var pts := PackedVector2Array()
			for i in 25:
				var x := w * i / 24.0
				pts.append(Vector2(x, yy + 2.5 * sin(x * 0.03 + t * (0.6 + 0.2 * k) + k)))
			draw_polyline(pts, Color(0.6, 0.85, 1.0, 0.05), 1.2, true)
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	## 坐標軸、單位圓、刻度
	func _draw_frame(font: Font, c: Vector2, rad: float, big: bool) -> void:
		var axis := Color(1, 1, 1, 0.35)
		draw_line(c - Vector2(rad + 22, 0), c + Vector2(rad + 22, 0), axis, 1.5)
		draw_line(c - Vector2(0, rad + 18), c + Vector2(0, rad + 18), axis, 1.5)
		draw_arc(c, rad, 0, TAU, 96, Color(SILVER.r, SILVER.g, SILVER.b, 0.55), 2.0, true)
		for k in 24:
			var a := k * STEPA
			var d := Vector2(cos(a), -sin(a))
			var main := k % 6 == 0
			var mid := k % 2 == 0
			var l := (9.0 if main else (6.0 if mid else 3.5)) * (1.0 if big else 0.7)
			draw_line(c + d * (rad - l), c + d * (rad + l), Color(1, 1, 1, 0.5 if main else (0.3 if mid else 0.18)), 1.5 if main else 1.0)
		if big:
			var fs := UITheme.fs(15)
			for pr in [[0.0, "0"], [PI / 2.0, "π/2"], [PI, "π"], [3.0 * PI / 2.0, "3π/2"]]:
				var d2 := Vector2(cos(pr[0]), -sin(pr[0]))
				var p: Vector2 = c + d2 * (rad + (24.0 if absf(d2.y) > 0.5 else 30.0))
				MathLabel.draw_on(self, font, p.x + (10.0 if pr[0] == 0.0 else 0.0), p.y + 6.0, pr[1], fs, Color(1, 1, 1, 0.6))
			var qn := ["一", "二", "三", "四"]
			for q in 4:
				var a2 := PI / 4.0 + q * PI / 2.0
				var p2 := c + Vector2(cos(a2), -sin(a2)) * rad * 0.62
				draw_string(font, p2 + Vector2(-20, 6), qn[q], HORIZONTAL_ALIGNMENT_CENTER, 40, UITheme.fs(15), Color(1, 1, 1, 0.12))

	## 從 0 轉到 θ 的螺旋箭頭（每多轉一圈就往外一點）
	func _draw_turn(c: Vector2, r0: float, th: float, col: Color, width: float) -> void:
		if absf(th) < 1e-4:
			return
		var n := maxi(8, int(absf(th) / 0.06))
		var pts := PackedVector2Array()
		for i in n + 1:
			var a := th * i / n
			var rr := r0 + 7.0 * absf(a) / TAU
			pts.append(c + Vector2(cos(a), -sin(a)) * rr)
		draw_polyline(pts, Color(col.r, col.g, col.b, 0.25), width + 5.0, true)
		draw_polyline(pts, col, width, true)
		# 箭頭
		var tip: Vector2 = pts[pts.size() - 1]
		var prev: Vector2 = pts[maxi(0, pts.size() - 3)]
		var dv := (tip - prev).normalized()
		var nv := dv.orthogonal()
		draw_colored_polygon(PackedVector2Array([tip + dv * 8.0, tip - dv * 4.0 + nv * 6.0, tip - dv * 4.0 - nv * 6.0]), col)

	## 轉角步驟：大張的單位圓，可以拖動終邊
	func _draw_spin(font: Font) -> void:
		var rc := _spin_rect()
		draw_style_box(UITheme.boxc(Color(0.03, 0.06, 0.14, 0.6), 14, Color(0.55, 0.8, 1.0, 0.25), 1, 0), rc)
		_draw_task(font, rc, "拖動光點轉出角度", rc.size.x / 2.0 - 70.0)
		var g := _spin_geo()
		var c: Vector2 = g[0]
		var rad: float = g[1]
		_draw_frame(font, c, rad, true)
		var th := spin_show
		var col := UITheme.GOLD if spin_k >= 0 else PINK
		# 始邊
		draw_line(c, c + Vector2(rad, 0), Color(1, 1, 1, 0.55), 2.5)
		_draw_turn(c, rad * 0.26, th, col, 3.0)
		var p := c + Vector2(cos(th), -sin(th)) * rad
		draw_line(c, p, Color(col.r, col.g, col.b, 0.95), 3.0, true)
		UITheme.dot(self, p, 18.0 + 2.0 * sin(t * 4.0), Color(col.r, col.g, col.b, 0.22))
		UITheme.dot(self, p, 9.0, col)
		UITheme.dot(self, p, 4.0, Color.WHITE)
		UITheme.dot(self, c, 3.5, Color(1, 1, 1, 0.8))
		_draw_drag_hint(font, c, rad)
		var turns := int(floor(absf(spin_k) / 24.0))
		if turns > 0:
			draw_string(font, rc.end - Vector2(210, 14), "已經轉了 %d 圈多" % turns, HORIZONTAL_ALIGNMENT_RIGHT, 200, UITheme.fs(15),
				Color(col.r, col.g, col.b, 0.85))

	## 小手示範：從光點出發，沿著圓逆時針滑一段，再放開（一直重複）
	func _draw_drag_hint(font: Font, c: Vector2, rad: float, start := NAN, tip_at := Vector2(NAN, NAN)) -> void:
		if _drag:
			return
		if dragged_ever:
			return
		var since := t - hint_from
		if since < 0.6:
			return
		var u := fposmod(since - 0.6, 2.6) / 2.6
		var a0 := spin_show if is_nan(start) else start
		var a1 := a0 + 1.05
		var a := a0
		var alpha := 1.0
		var press := 0.0           # 按下去的程度（手指變小一點）
		if u < 0.18:
			alpha = u / 0.18
		elif u < 0.28:
			press = (u - 0.18) / 0.1
		elif u < 0.78:
			press = 1.0
			a = lerpf(a0, a1, smoothstep(0.0, 1.0, (u - 0.28) / 0.5))
		else:
			a = a1
			press = 1.0 - (u - 0.78) / 0.08 if u < 0.86 else 0.0
			alpha = 1.0 - (u - 0.78) / 0.22
		alpha = clampf(alpha, 0.0, 1.0)
		var gp := c + Vector2(cos(a), -sin(a)) * rad
		# 光點的分身＋拖過的軌跡
		if a > a0 + 0.01:
			var tr := PackedVector2Array()
			for i in 17:
				var aa := lerpf(a0, a, i / 16.0)
				tr.append(c + Vector2(cos(aa), -sin(aa)) * rad)
			draw_polyline(tr, Color(1, 1, 1, 0.35 * alpha), 4.0, true)
			UITheme.dot(self, gp, 9.0, Color(1, 0.82, 0.35, 0.55 * alpha))
		# 按下去時的漣漪
		if press > 0.0:
			draw_arc(gp, 14.0 + 6.0 * press, 0, TAU, 32, Color(1, 1, 1, 0.45 * alpha * press), 2.0, true)
		_draw_hand(gp + Vector2(4, 6), 1.3 * (1.0 - 0.12 * press), alpha)
		# 文字
		var tp := c + Vector2(rad + 120.0, -rad * 0.55) if is_nan(tip_at.x) else tip_at
		var msg := "按住光點，沿著圓轉"
		var w := font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15)).x
		var rc := _spin_rect()
		tp.x = clampf(tp.x, rc.position.x + w / 2.0 + 10.0, rc.end.x - w / 2.0 - 10.0)
		tp.y = clampf(tp.y, rc.position.y + 40.0, rc.end.y - 30.0)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 0.85, 0.4, 0.9 * alpha)
		sb.set_corner_radius_all(12)
		draw_style_box(sb, Rect2(tp.x - w / 2.0 - 10.0, tp.y - 18.0, w + 20.0, 26.0))
		draw_string(font, Vector2(tp.x - w / 2.0, tp.y), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(0.1, 0.08, 0.2, alpha))

	## 一隻小手（食指點在 tip）
	func _draw_hand(tip: Vector2, k: float, alpha: float) -> void:
		var skin := Color(1, 0.96, 0.9, 0.95 * alpha)
		var edge := Color(0.1, 0.1, 0.25, 0.8 * alpha)
		var fw := 9.0 * k
		var top := tip
		var bot := tip + Vector2(6, 22) * k
		var palm := tip + Vector2(12, 34) * k
		# 外框（描邊）
		draw_line(top, bot, edge, fw + 4.0, true)
		UITheme.dot(self, top, fw / 2.0 + 2.0, edge)
		UITheme.dot(self, palm, 14.0 * k + 2.0, edge)
		# 手
		draw_line(top, bot, skin, fw, true)
		UITheme.dot(self, top, fw / 2.0, skin)
		UITheme.dot(self, palm, 14.0 * k, skin)
		# 收起來的三根手指
		for j in 3:
			var q := palm + Vector2(-8 + 8 * j, -10) * k
			UITheme.dot(self, q, 5.0 * k, Color(0.85, 0.82, 0.78, 0.9 * alpha))

	## 下方的小單位圓：一個角（含交點 (cos θ, sin θ)）或好幾個角（比大小）
	func _draw_circ(font: Font, rect: Rect2) -> void:
		draw_style_box(UITheme.boxc(Color(0.03, 0.06, 0.14, 0.55), 12, Color(0.55, 0.8, 1.0, 0.22), 1, 0), rect.grow(6))
		draw_string(font, rect.position + Vector2(4, -10), "單位圓", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(0.75, 0.88, 1.0, 0.7))
		var rad := rect.size.y / 2.0 - 22.0
		var c := Vector2(rect.position.x + rect.size.x * 0.36, rect.get_center().y + 4.0)
		_draw_frame(font, c, rad, false)
		if circ.has("angles"):
			var cols := [UITheme.CYAN, UITheme.GOLD, UITheme.PINK_LIGHT, UITheme.LIME]
			var proj := String(circ.get("proj", "y"))
			var labels: Array = circ.get("labels", [])
			for i in circ.angles.size():
				var a: float = circ.angles[i]
				var col: Color = cols[i % cols.size()]
				var p := c + Vector2(cos(a), -sin(a)) * rad
				draw_line(c, p, Color(col.r, col.g, col.b, 0.8), 2.0, true)
				if proj == "y":
					draw_dashed_line(p, Vector2(c.x, p.y), Color(col.r, col.g, col.b, 0.7), 1.5, 5.0)
					draw_line(Vector2(c.x - 5, p.y), Vector2(c.x + 5, p.y), col, 3.0)
				else:
					draw_dashed_line(p, Vector2(p.x, c.y), Color(col.r, col.g, col.b, 0.7), 1.5, 5.0)
					draw_line(Vector2(p.x, c.y - 5), Vector2(p.x, c.y + 5), col, 3.0)
				UITheme.dot(self, p, 5.0, col)
				var lp := c + Vector2(cos(a), -sin(a)) * (rad + 16.0)
				MathLabel.draw_on(self, font, lp.x, lp.y + 5.0, String(labels[i]) if i < labels.size() else "", UITheme.fs(15), col)
			var cap := "比高度：sin = 縱坐標" if proj == "y" else "比左右：cos = 橫坐標"
			MathLabel.draw_on(self, font, rect.position.x + rect.size.x * 0.78, rect.get_center().y + 6.0, cap, UITheme.fs(15),
				Color(0.85, 0.92, 1.0, 0.85))
			return
		var th: float = circ.get("theta", 0.0)
		var col2 := UITheme.GOLD if th >= 0.0 else PINK
		draw_line(c, c + Vector2(rad, 0), Color(1, 1, 1, 0.5), 2.0)
		_draw_turn(c, rad * 0.3, th, Color(col2.r, col2.g, col2.b, 0.85), 2.0)
		var p2 := c + Vector2(cos(th), -sin(th)) * rad
		draw_line(c, p2, col2, 2.5, true)
		draw_dashed_line(p2, Vector2(p2.x, c.y), Color(0.55, 0.85, 1.0, 0.6), 1.5, 5.0)
		draw_dashed_line(p2, Vector2(c.x, p2.y), Color(1.0, 0.6, 0.75, 0.6), 1.5, 5.0)
		UITheme.dot(self, p2, 9.0 + 1.5 * sin(t * 4.0), Color(col2.r, col2.g, col2.b, 0.25))
		UITheme.dot(self, p2, 5.0, col2)
		var x0 := rect.position.x + rect.size.x * 0.66
		var y0 := rect.position.y + 40.0
		MathLabel.draw_on(self, font, x0 + 70.0, y0, "θ = " + String(circ.get("label", "")), UITheme.fs(20), Color(1, 0.92, 0.7))
		var qtext := _quad_name(th)
		MathLabel.draw_on(self, font, x0 + 70.0, y0 + 34.0, qtext, UITheme.fs(15), Color(0.85, 0.92, 1.0, 0.85))
		MathLabel.draw_on(self, font, x0 + 70.0, y0 + 64.0, "交點 (cos θ, sin θ)", UITheme.fs(15), Color(0.75, 0.85, 1.0, 0.65))

	static func _quad_name(th: float) -> String:
		var a := fposmod(th, TAU)
		var k := a / (PI / 2.0)
		if absf(k - roundf(k)) < 1e-6:
			return ["終邊在正 x 軸", "終邊在正 y 軸", "終邊在負 x 軸", "終邊在負 y 軸"][int(roundf(k)) % 4]
		return ["第一象限", "第二象限", "第三象限", "第四象限"][int(floor(k)) % 4]
