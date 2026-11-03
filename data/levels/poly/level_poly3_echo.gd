extends "res://data/levels/poly/level_poly2_wheel.gd"
## 多項式 第三大關「回音石廊」（對應講義 4-1 重點三：餘式定理、因式定理）
## 引擎是 step_level.gd，畫面沿用第二關的 WheelView（綜合除法、長除法的算式），題庫在 poly3_bank.gd。
##
## 這一關多了：
##   ・喊話（題庫的 _shout，畫面上是選擇題）：答對時聲波從左邊飛向深谷，波上寫著喊出去的 x = a
##   ・回音（填空帶 "echo"）：答對時回音帶著 f(a) 的值彈回來；f(a) = 0 時谷底一片安靜，跳出「x − a 是因式」
##   ・峽谷石廊的背景（兩側的岩壁、垂下來的鐘乳石）
##   ・回音石（題庫的 probe 步驟）：下方有一條數線，學生拖動喊話點（或按右邊的 ◀ ▶），石壁即時顯示回音 f(x)。
##     算術由遊戲來做，學生只要決定「在哪裡喊」：
##       find  喊對除式要的那個數　roots  找出所有安靜的地方（因式）　tune  x 固定，轉動 k 讓回音變成要的值
##   ・速算：看除式喊出要代的數、x = ±1 的餘式（一步就能算完）

const BankP3 := preload("res://data/levels/poly/poly3_bank.gd")
const ECHO_C := Color("c8a8ff")

const CHAPTERS_P3 := [
	{"ch": 1, "name": "第一章．回音入門", "topic": "餘式定理、因式定理、用綜合除法求值", "color": Color("c8a8ff")},
	{"ch": 2, "name": "第二章．雙重回音", "topic": "除式是二次式、三次式，階梯假設法、餘式的運算、餘式定理的推廣", "color": UITheme.PINK},
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
			+ "・沒有直接給 f(a)：代入別的除法的餘式\n" \
			+ "・階梯假設法：除式多一個因式，餘式就多一階 A × 原來的除式\n" \
			+ "・兩個多項式的餘式也可以相乘\n" \
			+ "・令除式 = 0：高次項一路換下去，換完就是餘式\n\n" \
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
		fview.speed_y = 0.42


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


# ================= 回音石（probe） =================

var probe_lbl: Label
var probe_found: Label

func _forge_step() -> void:
	if fview != null:
		_ev().probe_off()
	super()
	if r.get("type", "") == "forge" and si < steps.size() and String(steps[si].kind) == "probe":
		_build_probe(steps[si])


func _build_probe(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	var ev := _ev()
	ev.start_probe(st, _on_probe_move)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	rank_box.add_child(row)
	var mk := func(txt: String, d: int) -> Button:
		var b := Button.new()
		b.text = txt
		b.custom_minimum_size = Vector2(64, 56)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", UITheme.fs(22))
		b.pressed.connect(func():
			if not busy:
				ev.nudge_probe(d))
		return b
	row.add_child(mk.call("◀", -1))
	probe_lbl = Label.new()
	probe_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	probe_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	probe_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	probe_lbl.add_theme_font_size_override("font_size", UITheme.fs(26))
	probe_lbl.add_theme_color_override("font_color", ECHO_C.lightened(0.3))
	row.add_child(probe_lbl)
	row.add_child(mk.call("▶", 1))
	probe_found = Label.new()
	probe_found.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	probe_found.custom_minimum_size = Vector2(300, 0)
	probe_found.add_theme_font_size_override("font_size", UITheme.fs(17))
	probe_found.add_theme_color_override("font_color", UITheme.GOOD.lightened(0.2))
	probe_found.visible = String(st.mode) in ["roots", "pins"]
	rank_box.add_child(probe_found)
	var tip := Label.new()
	tip.text = "在數線上拖動，或按 ◀ ▶ 移動一格。"
	tip.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	tip.custom_minimum_size = Vector2(300, 0)
	tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(tip)
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = _probe_btn(String(st.mode))
	fview.live_q = _probe_hint() % go_btn.text
	_on_probe_move()


func _on_probe_move() -> void:
	var ev := _ev()
	if probe_lbl == null or not is_instance_valid(probe_lbl) or ev.probe.is_empty():
		return
	probe_lbl.text = _probe_var(String(ev.probe.mode)) + " = " + EchoView.xs(ev.px, int(ev.probe.get("den", 1)))
	if probe_found != null and is_instance_valid(probe_found) and String(ev.probe.mode) in ["roots", "pins"]:
		var need: int = ev.probe.roots.size()
		var got := ev.marks.map(func(m): return "x = " + EchoView.xs(m, int(ev.probe.get("den", 1))))
		probe_found.text = "找到 %d／%d 個：%s" % [got.size(), need, "、".join(got) if not got.is_empty() else "還沒有"]
	# 中間的推導紀錄也寫出這一步要求什麼
	match String(ev.probe.mode):
		"find":
			fview.live_fill = "求：除以 %s 的餘式 ⇒ 代入 x = ?" % ev.probe.div
		"roots":
			fview.live_fill = "求：所有回音是 0 的 x（找到 %d／%d 個）" % [ev.marks.size(), ev.probe.roots.size()]
		"tune":
			fview.live_fill = "求：讓 f(%s) = %s 的 k" % [ev.probe.x0, ev.probe.goal]
		_:
			fview.live_fill = _probe_center(ev)
	fview.queue_redraw()
	Game.of(self).play("blip", 0.9 + 0.04 * clampf(ev.px, -6.0, 6.0), -16.0)


## 右邊按鈕的字、拖動的變數、中間「求：…」的文字（下一關可以加新的 mode）
func _probe_btn(mode: String) -> String:
	return {"find": "喊！", "roots": "標記這裡", "tune": "就是這個 k"}.get(mode, "確定")

func _probe_hint() -> String:
	return "拖動下方的喊話點（或按右邊的 ◀ ▶），再按「%s」。"

func _probe_var(mode: String) -> String:
	return "k" if mode == "tune" else "x"

func _probe_center(_ev_: EchoView) -> String:
	return ""


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size() and String(steps[si].kind) == "probe":
		_probe_submit(steps[si])
		return
	super()


func _probe_submit(st: Dictionary) -> void:
	var ev := _ev()
	var den := int(st.get("den", 1))
	var v := ev.probe_value()
	var vs := EchoView.fmt(v)
	match String(st.mode):
		"find":
			var want := EchoView.parse(String(st.target))
			if absf(ev.px - want) < 1e-6:
				Game.of(self).sfx("correct")
				_probe_done(st, "", "")
				ev.shout(EchoView.xs(ev.px, den))
				return
			_wrong(st, "代入 x = %s 時，除式 %s 不是 0，這樣得到的回音不是它的餘式。提示：%s" % [EchoView.xs(ev.px, den), st.div, st.nudge])
		"roots":
			if absf(v) > 1e-9:
				_wrong(st, "x = %s 這裡有回音 %s：除以 %s 的餘式不是 0，所以它不是因式。提示：%s" % [EchoView.xs(ev.px, den), vs, EchoView.divisor_of(ev.px, den), st.nudge])
				return
			for m in ev.marks:
				if absf(float(m) - ev.px) < 1e-6:
					_hint("這裡已經標記過了，找找別的地方。", "info")
					return
			ev.marks.append(ev.px)
			ev.echo(EchoView.xs(ev.px, den), "0")
			Game.of(self).sfx("correct")
			_on_probe_move()
			if ev.marks.size() >= st.roots.size():
				_probe_done(st, "", "")
			else:
				_hint("✓ x = %s 安靜：除以 %s 的餘式是 0，所以 %s 是因式！還有 %d 個。" % [EchoView.xs(ev.px, den), EchoView.divisor_of(ev.px, den),
					EchoView.divisor_of(ev.px, den), st.roots.size() - ev.marks.size()], "good")
		"tune":
			var goal := EchoView.parse(String(st.goal))
			if absf(v - goal) < 1e-9:
				Game.of(self).sfx("correct")
				_probe_done(st, String(st.x0), vs)
				return
			_wrong(st, "k = %d 時，x = %s 的回音是 %s，還不是 %s。提示：%s" % [int(ev.px), st.x0, vs, EchoView.fmt(goal), st.nudge])


func _probe_done(st: Dictionary, x: String, val: String) -> void:
	var ev := _ev()
	go_btn.visible = false
	_clear(rank_box)
	rank_box.visible = false
	ev.probe_off()
	if x != "":
		ev.echo(x, val)
	fview.live_fill = ""
	_step_done(st, "")


func _custom_reveal(msg: String) -> void:
	if fview != null:
		_ev().probe_off()
	super(msg)


# ================= 速算 =================

func _speed_tag() -> String:
	return BankP3.T_REM


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算題（一步就能算完）：{eq, q, template, ans, nudge, tag}
##   ・看除式喊出要代的數：x − a、ax + b
##   ・除以 x − 1（係數和）、x + 1 的餘式（小小的三次式）
static func gen_problems(kind: String, n: int) -> Array:
	if kind == "swap":
		return _gen_swap(n)
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var pb := {}
		if randf() < 0.6:
			var a := randi_range(1, 4)
			var b := randi_range(-7, 7)
			if b == 0 or (a > 1 and BankP2._gcd(a, absi(b)) != 1):
				continue
			var div := ("%dx" % a if a > 1 else "x") + (" + %d" % b if b > 0 else " − %d" % -b)
			var ans := BankP2._q(-b, a)
			pb = {"eq": "f(x) 除以 %s\n要喊 x = ？" % div, "ans": BankP2._qa(ans), "template": "x = [0]",
				"q": "讓 %s = 0 的數。" % div, "nudge": "%s = 0 ⇒ x = ?" % div}
		else:
			var coef := [1, randi_range(-3, 3), randi_range(-4, 4), randi_range(-5, 5)]
			var a2: int = [1, -1].pick_random()
			var row := BankP2.synth_row(coef, [a2, 1])
			pb = {"eq": "%s 除以 %s\n餘式 = ？" % [BankP2.poly_text(coef), BankP2.divisor_text([a2, 1])], "ans": BankP2._qa(row[3]),
				"template": "餘式 = [0]",
				"q": "餘式 = f(1) = 係數和。" if a2 == 1 else "餘式 = f(−1)：奇次項變號。",
				"nudge": "把係數加起來。" if a2 == 1 else "偶次項係數和 − 奇次項係數和。"}
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		pb["tag"] = BankP3.T_REM
		out.append(pb)
	return out


## 第二章的速算「換換看」：令除式 = 0，高次項換成什麼（一步）
##   ・除以 x^{2} ∓ c：x^{2} 換成 ±c　・除以 x^{2} − c：x^{2k} 換成 c^{k}　・除以 x^{2} + x + 1：x^{n} 換成 x 的幾次
static func _gen_swap(n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var pb := {}
		match out.size() % 3:
			0:
				var c: int = [1, 2, 3, 4, 5, 7, 9].pick_random()
				var plus := randf() < 0.5
				var div := "x^{2} %s %d" % ["+" if plus else "−", c]
				pb = {"eq": "除以 %s\n令除式 = 0：x^{2} 換成？" % div, "ans": str(-c if plus else c), "template": "x^{2} → [0]",
					"q": "%s = 0，移項。" % div, "nudge": "x^{2} = %s。" % ("−%d" % c if plus else str(c))}
			1:
				var c2: int = [2, 3].pick_random()
				var k := randi_range(2, 3)
				pb = {"eq": "除以 x^{2} − %d\nx^{%d} 換成？" % [c2, 2 * k], "ans": str(int(pow(c2, k))), "template": "x^{%d} → [0]" % (2 * k),
					"q": "x^{2} 換成 %d：x^{%d} = (x^{2})^{%d}。" % [c2, 2 * k, k], "nudge": "%d 的 %d 次方。" % [c2, k]}
			2:
				var m := randi_range(10, 60)
				pb = {"eq": "除以 x^{2} + x + 1（x^{3} 換成 1）\nx^{%d} 換成 x 的幾次？" % m, "ans": str(m % 3), "template": "x^{%d} → x^{[0]}" % m,
					"q": "%d 除以 3 的餘數。" % m, "nudge": "x^{3} 換成 1，只看 %d 除以 3 的餘數。" % m}
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		pb["tag"] = BankP3.T_POW
		out.append(pb)
	return out


# ================= 畫面：峽谷石廊 + 回音 =================

class EchoView extends WheelView:
	const ECHO := Color("c8a8ff")

	var shout_t := -10.0
	var shout_x := ""
	var echo_t := -10.0
	var echo_x := ""
	var echo_val := ""
	var _walls := []             # 岩壁（快取）
	var echo_head := "回音"
	var echo_word := "（餘式）"    # 回音後面的說明（第四關代入的不一定是餘式，就不寫）
	# 回音石（probe）
	var probe := {}              # 這一步的 probe 步驟（空的：沒有在用）
	var px := 0.0                # 喊話點的位置（tune 時是 k）
	var marks: Array = []        # roots：已經標記的安靜位置
	var probe_cb: Callable       # 喊話點移動時通知關卡（更新右邊的數字）
	var move_t := -10.0
	var pad: Control             # 接收拖動的透明區域（畫面本身不接收滑鼠，推導紀錄才能捲動）

	func setup(round: Dictionary) -> void:
		super(round)
		shout_t = -10.0
		echo_t = -10.0
		probe_off()

	# ---------- 回音石 ----------
	func start_probe(st: Dictionary, cb: Callable) -> void:
		probe = st
		probe_cb = cb
		marks = []
		px = 0.0
		if pad == null:
			pad = Control.new()
			pad.mouse_filter = Control.MOUSE_FILTER_STOP
			pad.gui_input.connect(_pad_input)
			add_child(pad)
		pad.visible = true
		_place_pad()
		queue_redraw()

	func probe_off() -> void:
		probe = {}
		if pad != null:
			pad.visible = false

	func _probe_rect() -> Rect2:
		return Rect2(36, size.y - 214, size.x - 72, 190)

	func _place_pad() -> void:
		if pad != null:
			var rc := _probe_rect()
			pad.position = rc.position
			pad.size = rc.size

	func _process(delta: float) -> void:
		super(delta)
		if pad != null and pad.visible and pad.size != _probe_rect().size:
			_place_pad()

	func _range() -> Vector2:
		var rg: Array = probe.get("range", [-4, 4])
		return Vector2(float(rg[0]), float(rg[1]))

	func _line_x0() -> float:
		return _probe_rect().position.x + 34.0

	func _line_x1() -> float:
		return _probe_rect().end.x - 34.0

	func _x_at(v: float) -> float:
		var rg := _range()
		return lerpf(_line_x0(), _line_x1(), (v - rg.x) / (rg.y - rg.x))

	func set_probe(v: float) -> void:
		var den := float(probe.get("den", 1))
		var rg := _range()
		v = clampf(roundf(v * den) / den, rg.x, rg.y)
		if absf(v - px) < 1e-9:
			return
		px = v
		move_t = t
		queue_redraw()
		if probe_cb.is_valid():
			probe_cb.call()

	func nudge_probe(d: int) -> void:
		set_probe(px + d / float(probe.get("den", 1)))

	func _pad_input(e: InputEvent) -> void:
		if probe.is_empty():
			return
		var pos := Vector2.INF
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			pos = e.position
		elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
			pos = e.position
		if pos == Vector2.INF:
			return
		var gx := pos.x + pad.position.x
		var rg := _range()
		set_probe(lerpf(rg.x, rg.y, (gx - _line_x0()) / (_line_x1() - _line_x0())))
		pad.accept_event()

	## 目前喊話點的回音
	func probe_value() -> float:
		if probe.is_empty():
			return 0.0
		if String(probe.mode) == "tune":
			return eval_fk(probe.fk, parse(String(probe.x0)), px)
		return eval_fx(probe.fx, px)

	## fx：積的和，每個因式是 [[係數, 次方]…]
	static func eval_fx(fx: Array, x: float) -> float:
		var total := 0.0
		for term in fx:
			var prod := 1.0
			for fac in term:
				var s := 0.0
				for cp in fac:
					s += float(cp[0]) * pow(x, float(cp[1]))
				prod *= s
			total += prod
		return total

	## fk：[[常數, k 的係數]…]（由高次到低次）
	static func eval_fk(fk: Array, x: float, k: float) -> float:
		var v := 0.0
		for c in fk:
			v = v * x + float(c[0]) + float(c[1]) * k
		return v

	static func parse(s: String) -> float:
		var v := s.strip_edges().replace("−", "-")
		if v.contains("/"):
			var pr := v.split("/")
			return float(pr[0]) / float(pr[1])
		return float(v)

	static func _gcd(a: int, b: int) -> int:
		a = absi(a)
		b = absi(b)
		while b != 0:
			var t2 := a % b
			a = b
			b = t2
		return maxi(a, 1)

	## 數線上的位置寫成「1/2」「−3」
	static func xs(x: float, den: int) -> String:
		var n := int(roundf(x * den))
		var g := _gcd(n, den)
		var nn := n / g
		var dd := den / g
		var body := str(absi(nn)) if dd == 1 else "%d/%d" % [absi(nn), dd]
		return ("−" if nn < 0 else "") + body

	## x = a 安靜 ⇒ 因式的寫法：x − 2、x + 3、2x − 1
	static func divisor_of(x: float, den: int) -> String:
		var n := int(roundf(x * den))
		var g := _gcd(n, den)
		var nn := n / g
		var dd := den / g
		if nn == 0:
			return "x"
		var lead := "x" if dd == 1 else "%dx" % dd
		return lead + (" − %d" % nn if nn > 0 else " + %d" % -nn)

	## 回音的數值（分數、太大聲）
	static func fmt(v: float) -> String:
		if is_nan(v) or is_inf(v) or absf(v) >= 1e9:
			return "震耳欲聾！"
		if absf(v) < 1e-9:
			return "0"
		for d in [1, 2, 3, 4, 6, 8, 9, 12, 16, 18, 27, 32, 54, 64, 81]:
			var nv: float = v * d
			if absf(nv - roundf(nv)) < 1e-6 * d:
				var n := int(roundf(nv))
				var body := str(absi(n)) if d == 1 else "\\frac{%d}{%d}" % [absi(n), d]
				return ("−" if n < 0 else "") + body
		return str(snappedf(v, 0.01)).replace("-", "−")

	func _draw_probe(font: Font) -> void:
		var rc := _probe_rect()
		var mode := String(probe.mode)
		var den := int(probe.get("den", 1))
		var tune := mode == "tune"
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.06, 0.16, 0.78)
		sb.border_color = Color(ECHO.r, ECHO.g, ECHO.b, 0.45)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(14)
		sb.anti_aliasing = true
		draw_style_box(sb, rc)
		var head: String = {"find": "回音石：喊出除以 %s 的餘式" % String(probe.get("div", "")), "roots": "回音石：找出所有安靜（回音 = 0）的地方",
			"tune": "調音石：在 x = %s 喊，轉動 k" % String(probe.get("x0", ""))}.get(mode, "")
		MathLabel.draw_text(self, font, rc.position + Vector2(4, -10), head, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(0.85, 0.75, 1.0, 0.85))
		# 數線
		var rg := _range()
		var yl := rc.end.y - 58.0
		draw_line(Vector2(_line_x0() - 14.0, yl), Vector2(_line_x1() + 14.0, yl), Color(1, 1, 1, 0.45), 2.0)
		var n := int(roundf((rg.y - rg.x) * den))
		var tick := PackedVector2Array()
		for i in n + 1:
			var v := rg.x + float(i) / den
			var xx := _x_at(v)
			var major := absf(v - roundf(v)) < 1e-6
			tick.append_array([Vector2(xx, yl - (7.0 if major else 4.0)), Vector2(xx, yl + (7.0 if major else 4.0))])
			if major:
				MathLabel.draw_on(self, font, xx, yl + 26.0, xs(v, 1), UITheme.fs(14), Color(1, 1, 1, 0.65))
		draw_multiline(tick, Color(1, 1, 1, 0.45), 1.5)
		MathLabel.draw_on(self, font, _line_x1() + 24.0, yl + 26.0, "k" if tune else "x", UITheme.fs(14), Color(1, 1, 1, 0.5))
		# 已經標記的安靜位置
		for m in marks:
			var mx := _x_at(float(m))
			UITheme.dot(self, Vector2(mx, yl), 12.0, Color(UITheme.GOOD.r, UITheme.GOOD.g, UITheme.GOOD.b, 0.3))
			UITheme.dot(self, Vector2(mx, yl), 6.0, UITheme.GOOD)
			MathLabel.draw_on(self, font, mx, yl - 18.0, divisor_of(float(m), den), UITheme.fs(13), UITheme.GOOD.lightened(0.3))
		# 喊話點與回音：回音越大聲，聲波越大；安靜時沒有聲波
		var v := probe_value()
		var hide := mode == "find"           # 喊對的數之後，回音要學生自己算（這裡先不顯示）
		var quiet := absf(v) < 1e-9 and not hide
		var ox := _x_at(px)
		var orb := Vector2(ox, yl)
		if not quiet:
			var amp := 0.4 if hide else (clampf(log(absf(v) + 1.0) / log(10.0) / 3.0, 0.15, 1.0) if not is_inf(v) else 1.0)
			for k in 3:
				var ph := fposmod(t * 1.2 + k / 3.0, 1.0)
				draw_arc(orb, 10.0 + ph * (16.0 + 46.0 * amp), PI * 1.05, PI * 1.95, 18,
					Color(ECHO.r, ECHO.g, ECHO.b, 0.55 * (1.0 - ph)), 2.0, true)
		var oc: Color = UITheme.GOOD if quiet else GOLD
		UITheme.dot(self, orb, 16.0, Color(oc.r, oc.g, oc.b, 0.25 + 0.1 * sin(t * 4.0)))
		UITheme.dot(self, orb, 9.0, oc)
		# 回音的泡泡：第一行是回音 f(x)，第二行寫出它代表的意思（餘式、因式）
		var xs_ := xs(px, den)
		var txt := ""
		var sub := ""
		var dv := divisor_of(parse(String(probe.x0)), 1) if tune else divisor_of(px, den)
		if tune:
			txt = "k = %s：f(%s) = %s" % [xs_, String(probe.x0), fmt(v)]
			sub = "回音 = 除以 %s 的餘式" % dv
		else:
			txt = "代入 x = %s" % xs_ if hide else "回音 f(%s) = %s" % [xs_, fmt(v)]
			if hide:
				sub = "回音 f(%s) = 除以 %s 的餘式" % [xs_, dv]
			else:
				sub = "除以 %s 的餘式是 0 ⇒ %s 是因式" % [dv, dv] if quiet else "= 除以 %s 的餘式" % dv
		if quiet:
			txt += "　……安靜"
		var fs := UITheme.fs(20)
		var fs2 := UITheme.fs(15)
		var tw := maxf(MathLabel.text_width(font, txt, fs), MathLabel.text_width(font, sub, fs2))
		var bx := clampf(ox, rc.position.x + tw / 2.0 + 16.0, rc.end.x - tw / 2.0 - 16.0)
		var pop := clampf(1.0 - (t - move_t) / 0.25, 0.0, 1.0)
		var box := Rect2(bx - tw / 2.0 - 12.0, rc.position.y + 10.0 - 3.0 * pop, tw + 24.0, fs + fs2 + 26.0)
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color(0.12, 0.09, 0.22, 0.92)
		bsb.border_color = UITheme.GOOD if quiet else Color(ECHO.r, ECHO.g, ECHO.b, 0.8)
		bsb.set_border_width_all(2)
		bsb.set_corner_radius_all(12)
		bsb.anti_aliasing = true
		draw_style_box(bsb, box)
		draw_line(Vector2(clampf(ox, box.position.x + 12.0, box.end.x - 12.0), box.end.y), orb - Vector2(0, 12), Color(oc.r, oc.g, oc.b, 0.5), 1.5)
		MathLabel.draw_on(self, font, bx, box.position.y + fs + 4.0, txt, fs, UITheme.GOOD.lightened(0.3) if quiet else Color(1, 0.95, 1.0))
		MathLabel.draw_on(self, font, bx, box.position.y + fs + fs2 + 14.0, sub, fs2, UITheme.GOOD.lightened(0.2) if quiet else Color(0.85, 0.78, 1.0, 0.9))

	func shout(x: String) -> void:
		shout_x = x
		shout_t = t
		echo_t = -10.0

	func echo(x: String, val: String) -> void:
		echo_x = x
		echo_val = val
		echo_t = t

	## 讓除式等於 0 的 x = a → 除式 x − a 的寫法（a 可以是 −3、1/2）
	static func _divisor(x: String) -> String:
		var s := x.strip_edges()
		if s.begins_with("−") or s.begins_with("-"):
			return "x + " + s.substr(1)
		return "x − " + s if s != "0" else "x"

	func _graph_on() -> bool:
		return not probe.is_empty() or super()

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if not probe.is_empty() and kind == "forge":
			_draw_probe(font)
			return
		super(font, rect)

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
				MathLabel.draw_on(self, font, x2, y, "%s f(%s) = %s%s" % [echo_head, echo_x, echo_val, echo_word], UITheme.fs(18), Color(ECHO.r, ECHO.g, ECHO.b, a).lightened(0.2))
