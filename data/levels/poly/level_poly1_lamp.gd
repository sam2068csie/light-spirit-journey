extends "res://data/levels/engine/step_level.gd"
## 多項式 第一大關「係數礦燈」（對應講義 4-1 重點一：多項式與係數問題）
## 引擎是 step_level.gd（一步一步推導），題庫在 poly1_bank.gd。
##
## 這一關多了：
##   ・lamp 步驟：選礦燈要照在 x = 多少（右邊的按鈕），下方的係數水晶跟著變：
##       x = 1 → 每一顆都是「+」，加起來是係數和
##       x = −1 → 奇次項的水晶翻成藍色的「−」
##       x = 0 → 只剩常數項 a₀ 亮著
##     答對之後，那一排水晶會留在下方，讓學生對照接下來的計算。
##   ・洞窟的背景（鐘乳石、地上的水晶、飄著的光塵），不是熔爐的火光
##   ・速算：(ax + b)^{n} 的係數和、常數項、f(−1)

const BankP1 := preload("res://data/levels/poly/poly1_bank.gd")
const CRYSTAL := UITheme.VIOLET

const CHAPTERS_P1 := [
	{"ch": 1, "name": "第一章．礦脈入門", "topic": "多項式、次數、係數和與恆等", "color": UITheme.VIOLET},
	{"ch": 2, "name": "第二章．深層礦脈", "topic": "奇偶次項、變數代換、待定係數與次數", "color": UITheme.BLUE},
]

var lamp_btns: Array = []


func level_id() -> String:
	return "P1"

func level_title() -> String:
	return "係數礦燈"

func level_subtitle() -> String:
	return "多項式與係數"

func level_chapters() -> Array:
	return CHAPTERS_P1

func bank_slots() -> Array:
	return BankP1.slots()

func step_color() -> Color:
	return CRYSTAL

func stage_style() -> Dictionary:
	return {"sky_top": Color("1a1230"), "sky_bot": Color("100a1e"), "scenery": "none", "ambient": "dust"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．深層礦脈", "button": "進入深層礦脈  ▶",
		"text": "越往下走，礦燈的用法越多：\n\n" \
			+ "・x = 1 和 x = −1 一起照：分出偶次項和奇次項\n" \
			+ "・礦脈用 (x − h) 排列時：讓括號變成 1 或 0\n" \
			+ "・每次只留下一項：代特殊值解待定係數\n" \
			+ "・兩條礦脈相加、相乘之後有多深？\n\n" \
			+ "點亮礦燈，出發吧！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = MineView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "礦燈速算"


func _mv() -> MineView:
	return fview as MineView


# ================= 礦燈（lamp） =================

func _forge_step() -> void:
	if fview != null:
		_mv().lamp_on = false
	super()
	if si < steps.size() and String(steps[si].kind) == "lamp":
		_build_lamp(steps[si])


func _build_lamp(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	var mv := _mv()
	mv.lamp_on = true
	mv.lamp_deg = int(st.deg)
	mv.lamp_x = NAN
	mv.task_q = String(st.q)
	lamp_btns = []
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	rank_box.add_child(row)
	for v in st.get("opts", [-1, 0, 1]):
		var b := Button.new()
		b.text = "x = %s" % _num(int(v))
		b.custom_minimum_size = Vector2(0, 54)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", UITheme.fs(19))
		var xv: int = int(v)
		b.pressed.connect(func():
			if busy:
				return
			_mv().set_lamp(xv)
			_refresh_lamp()
			Game.of(self).play("blip", 1.0 + 0.08 * (xv + 1), -12.0))
		b.set_meta("x", xv)
		row.add_child(b)
		lamp_btns.append(b)
	var tip := Label.new()
	tip.text = "選一個 x，看看下面的係數水晶會變成什麼樣子，再按「點亮礦燈」。"
	tip.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	tip.custom_minimum_size = Vector2(300, 0)
	tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(tip)
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "點亮礦燈"
	_refresh_lamp()


func _refresh_lamp() -> void:
	var cur := _mv().lamp_x
	for b in lamp_btns:
		var on := not is_nan(cur) and int(b.get_meta("x")) == int(cur)
		var c := CRYSTAL if on else Color(1, 1, 1, 0.25)
		var sb := UITheme.box(Color(c.r, c.g, c.b, 0.22 if on else 0.06), 12, c, 2 if on else 1, 6)
		for s in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(s, sb)
		b.add_theme_color_override("font_color", c.lightened(0.4) if on else UITheme.TEXT)


## 「是不是多項式」的篩選：按鈕上只寫代號（A）、（B）…，式子寫在左邊（排版比較清楚）
func _refresh_filter() -> void:
	super()
	var st: Dictionary = steps[si]
	if not st.get("bare", false):
		return
	for i in filter_btns.size():
		var keep: bool = filter_keep[i]
		filter_btns[i].text = "%s\n%s" % [st.cands[i], st.get("keep_word", "✓ 保留") if keep else st.get("drop_word", "✗ 丟掉")]


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size() and String(steps[si].kind) == "lamp":
		_lamp_submit()
		return
	super()


func _lamp_submit() -> void:
	var st: Dictionary = steps[si]
	var mv := _mv()
	if is_nan(mv.lamp_x):
		_hint("先選礦燈要照在 x = 多少（上面的按鈕）。", "info")
		return
	var want := int(st.target)
	if int(mv.lamp_x) == want:
		Game.of(self).sfx("correct")
		mv.lamp_on = false
		mv.lit = {"deg": int(st.deg), "x": want}
		mv.burst_center()
		go_btn.visible = false
		_clear(rank_box)
		rank_box.visible = false
		_step_done(st, "")
		return
	var x := int(mv.lamp_x)
	var msg := "還不對。提示：" + String(st.nudge)
	if want == 1 and x == -1:
		msg = "x = −1 會讓奇次項變號，加起來不是全部的係數和喔。" + String(st.nudge)
	elif want == 1 and x == 0:
		msg = "x = 0 只會留下常數項。" + String(st.nudge)
	elif want == 0:
		msg = "看看下面的水晶：還有好幾顆亮著。" + String(st.nudge)
	elif want == -1 and x == 1:
		msg = "x = 1 時每一項都是正的，沒有變號。" + String(st.nudge)
	_wrong(st, msg)


func _custom_reveal(msg: String) -> void:
	if fview != null and r.type == "forge":
		var mv := _mv()
		mv.lamp_on = false
		for j in range(si, steps.size()):
			if String(steps[j].kind) == "lamp":
				mv.lit = {"deg": int(steps[j].deg), "x": int(steps[j].target)}
	super(msg)


static func _num(v: int) -> String:
	return ("−" if v < 0 else "") + str(absi(v))


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
	return BankP1.T_SUM


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算題：(ax + b)^{n} 的係數和、常數項、f(−1)。{eq, q, template, ans, nudge, tag}
static func gen_problems(_kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 2000:
		guard += 1
		var a := randi_range(1, 3)
		var b := randi_range(-3, 3)
		var p := randi_range(2, 5)
		if b == 0:
			continue
		var what := randi() % 3
		var base: int = [a + b, b, b - a][what]
		var ans := int(pow(base, p))
		if absi(ans) > 400 or (what == 0 and absi(base) <= 1 and randf() < 0.5):
			continue
		var eq := "(%s %s %d)^{%d}" % ["x" if a == 1 else "%dx" % a, "+" if b > 0 else "−", absi(b), p]
		if seen.has(eq + str(what)):
			continue
		seen[eq + str(what)] = true
		var pb := {"eq": eq + "\n" + ["展開後的各項係數和 = ？", "展開後的常數項 = ？", "a_{0} − a_{1} + a_{2} − a_{3} + … = ？"][what],
			"ans": str(ans), "tag": BankP1.T_SUM}
		match what:
			0:
				pb.q = "展開後的各項係數和是多少？"
				pb.template = "f(1) = [0]"
				pb.nudge = "x 代 1：(%d %s %d)^{%d}。" % [a, "+" if b > 0 else "−", absi(b), p]
			1:
				pb.q = "展開後的常數項是多少？"
				pb.template = "f(0) = [0]"
				pb.nudge = "x 代 0：只剩 (%s)^{%d}。" % [_num(b), p]
			_:
				pb.q = "a_{0} − a_{1} + a_{2} − …（奇次項變號）是多少？"
				pb.template = "f(−1) = [0]"
				pb.nudge = "x 代 −1：(%s %s %d)^{%d}。" % [_num(-a), "+" if b > 0 else "−", absi(b), p]
		out.append(pb)
	return out


# ================= 畫面：洞窟裡的推導台 + 係數水晶 =================

class MineView extends ForgeView:
	const VIO := UITheme.VIOLET
	const GOLDC := UITheme.GOLD
	const BLUEC := UITheme.CYAN

	var lamp_on := false
	var lamp_deg := 3
	var lamp_x := NAN            # 目前礦燈照的 x（NAN：還沒選）
	var lamp_show := 0.0         # 礦燈擺動的動畫
	var lamp_t := -10.0          # 換 x 的時間（水晶翻面的動畫）
	var lit := {}                # 答對之後留在下方的那一排水晶 {deg, x}
	var task_q := ""

	func setup(round: Dictionary) -> void:
		super(round)
		lamp_on = false
		lamp_x = NAN
		lit = {}

	func set_lamp(v: int) -> void:
		if is_nan(lamp_x) or int(lamp_x) != v:
			lamp_t = t
		lamp_x = v

	func _process(delta: float) -> void:
		var want := 0.0 if is_nan(lamp_x) else clampf(float(lamp_x), -1.5, 1.5) * 0.18
		lamp_show = lerpf(lamp_show, want, 1.0 - exp(-8.0 * delta))
		super(delta)

	# ---------- 版面 ----------

	func _graph_on() -> bool:
		return (not lit.is_empty() and not lamp_on) or super()

	func _bottom_limit() -> float:
		if lamp_on:
			return size.y - 330.0
		return super()

	func _lamp_rect() -> Rect2:
		return Rect2(36, size.y - 316, size.x - 72, 300)

	# ---------- 繪圖 ----------

	func _draw() -> void:
		super()
		if lamp_on and kind == "forge" and intro < 0.0:
			var font := get_theme_default_font()
			var rc := _lamp_rect()
			_draw_task(font, rc)
			_draw_crystals(font, rc, lamp_deg, lamp_x, true)

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if not lit.is_empty():
			_draw_crystals(font, rect, int(lit.deg), float(lit.x), false)
		else:
			super(font, rect)

	func _draw_task(font: Font, rc: Rect2) -> void:
		var s := task_q
		var fs := UITheme.fs(17)
		while fs > UITheme.fs(12) and MathLabel.text_width(font, s, fs) > rc.size.x - 28.0:
			fs -= 1
		var w := MathLabel.text_width(font, s, fs)
		var ex := MathLabel.line_extent(s, fs)
		MathLabel.draw_on(self, font, rc.position.x + 14.0 + w / 2.0, rc.position.y + 14.0 + ex.x, s, fs, Color(1, 0.92, 0.7))

	## 洞窟：上方的鐘乳石、地上一排小水晶、慢慢飄的光塵
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("1a1230"), Color("1a1230"), Color("0f0a1c"), Color("0f0a1c")]))
		# 鐘乳石
		var tops := PackedVector2Array()
		var tcol := PackedColorArray()
		for i in 14:
			var x := (i + 0.5) * w / 14.0 + 10.0 * sin(i * 2.3)
			var hh := 18.0 + 26.0 * fposmod(i * 0.618, 1.0)
			var hw := 10.0 + 6.0 * fposmod(i * 0.37, 1.0)
			var c := Color("2a2148")
			tops.append_array([Vector2(x - hw, 0), Vector2(x + hw, 0), Vector2(x, hh)])
			tcol.append_array([c, c, c])
		var idx := PackedInt32Array()
		for i in tops.size():
			idx.append(i)
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, tops, tcol)
		# 地上的水晶（微微發光）
		for i in 9:
			var x := (i + 0.5) * w / 9.0 + 14.0 * sin(i * 1.7)
			var hh := 10.0 + 12.0 * fposmod(i * 0.43, 1.0)
			var pulse := 0.5 + 0.5 * sin(t * 1.4 + i * 1.3)
			var c := Color(0.77, 0.6, 1.0, 0.10 + 0.08 * pulse)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 5, h), Vector2(x, h - hh), Vector2(x + 5, h)]), c)
		# 光塵
		for i in 26:
			var sp := 0.02 + 0.02 * fposmod(i * 0.371, 1.0)
			var y := h - fposmod(t * sp + i * 0.137, 1.0) * h
			var x := fposmod(i * 0.618, 1.0) * w + 10.0 * sin(t * 0.7 + i)
			var a := 0.12 + 0.12 * sin(t * 1.1 + i)
			UITheme.dot_n(self, Vector2(x, y), 1.2 + fposmod(i * 0.29, 1.0) * 1.2, Color(0.85, 0.75, 1.0, maxf(0.0, a)), 16)
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	## 要畫哪幾顆水晶：太多的時候畫 a₀～a₃、…、a_{n−1}、a_{n}（−1 是「⋯」）
	static func shown_ks(deg: int) -> Array:
		if deg + 1 <= 7:
			return range(deg + 1)
		return [0, 1, 2, 3, -1, deg - 1, deg]

	## 第 k 顆水晶在 x 處的值：x^{k}
	static func term_val(k: int, x: float) -> float:
		return 1.0 if k == 0 else pow(x, k)

	## 水晶上方的小標：+、−、0 或 ×x^{k}
	static func chip(k: int, x: float) -> String:
		var v := term_val(k, x)
		if is_zero_approx(v):
			return "0"
		if is_equal_approx(v, 1.0):
			return "+"
		if is_equal_approx(v, -1.0):
			return "−"
		return ("×" if v > 0 else "×(−") + str(absi(int(v))) + ("" if v > 0 else ")")

	## 下方的式子：f(1) = a_{0} + a_{1} + … 這種
	static func sum_text(deg: int, x: float) -> String:
		var xs := ("−" if x < 0 else "") + str(absi(int(x)))
		if is_zero_approx(x):
			return "f(0) = a_{0}"
		var out := ""
		var ks := shown_ks(deg)
		if deg + 1 > 7:
			ks = [0, 1, 2, -1, deg]
		for i in ks.size():
			var k: int = ks[i]
			if k < 0:
				out += " ⋯"
				continue
			var v := term_val(k, x)
			var name := "a_{%d}" % k
			var mag := absf(v)
			var body := name if is_equal_approx(mag, 1.0) else "%d%s" % [int(mag), name]
			if i == 0:
				out = ("−" if v < 0 else "") + body
			else:
				out += (" − " if v < 0 else " + ") + body
		return "f(%s) = %s" % [xs, out]

	## 一排係數水晶：每顆水晶代表一項 a_{k}x^{k}，礦燈照在 x 時，上方標出這一項變成 +、− 還是 0
	func _draw_crystals(font: Font, rc: Rect2, deg: int, x: float, big: bool) -> void:
		var has_x := not is_nan(x)
		var ks := shown_ks(deg)
		var top := rc.position.y + (44.0 if big else 4.0)
		var base_y := rc.end.y - (58.0 if big else 46.0)
		var ch := 64.0 if big else 44.0
		# 礦燈
		var lamp_c := Vector2(rc.get_center().x, top + (26.0 if big else 14.0))
		var sw := lamp_show if big else 0.0
		var lp := lamp_c + Vector2(sin(sw) * 30.0, 0)
		draw_line(Vector2(lamp_c.x, top - (10.0 if big else 4.0)), lp, Color(0.7, 0.6, 0.5, 0.7), 2.0, true)
		var glow := 1.0 if has_x else 0.25 + 0.1 * sin(t * 3.0)
		if has_x:
			var cone := PackedVector2Array([lp, Vector2(rc.position.x + 20.0, base_y + 6.0), Vector2(rc.end.x - 20.0, base_y + 6.0)])
			draw_polygon(cone, PackedColorArray([Color(1, 0.9, 0.6, 0.28), Color(1, 0.9, 0.6, 0.0), Color(1, 0.9, 0.6, 0.0)]))
		draw_rect(Rect2(lp + Vector2(-8, -6), Vector2(16, 18)), Color(1, 0.82, 0.4, 0.4 + 0.6 * glow))
		draw_rect(Rect2(lp + Vector2(-10, -9), Vector2(20, 4)), Color("8a7a6a"))
		var xt := "x = ?" if not has_x else "x = %s" % (("−" if x < 0 else "") + str(absi(int(x))))
		UITheme.text_ol(self, font, lp + Vector2(18, 10), xt, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(16 if big else 14), Color(1, 0.9, 0.6))
		# 水晶
		var n := ks.size()
		var gap := minf(78.0 if big else 60.0, (rc.size.x - 40.0) / n)
		var x0 := rc.get_center().x - gap * (n - 1) / 2.0
		var flip := clampf((t - lamp_t) / 0.35, 0.0, 1.0) if big else 1.0
		for i in n:
			var k: int = ks[i]
			var cx := x0 + gap * i
			if k < 0:
				UITheme.text_ol(self, font, Vector2(cx - 20, base_y - ch * 0.4), "⋯", HORIZONTAL_ALIGNMENT_CENTER, 40, UITheme.fs(22), Color(1, 1, 1, 0.6))
				continue
			var v := term_val(k, x) if has_x else NAN
			var col := Color(0.55, 0.5, 0.75, 0.55)
			if has_x:
				if is_zero_approx(v):
					col = Color(0.35, 0.32, 0.45, 0.7)
				elif v > 0:
					col = GOLDC
				else:
					col = BLUEC
			# 換 x 的時候水晶翻一下（寬度縮放）
			var sx := absf(cos(PI * (1.0 - flip))) if has_x else 1.0
			var hw := 15.0 * maxf(0.15, sx) * (1.0 if big else 0.75)
			var tip := Vector2(cx, base_y - ch)
			var pts := PackedVector2Array([Vector2(cx - hw, base_y - ch * 0.25), tip, Vector2(cx + hw, base_y - ch * 0.25),
				Vector2(cx + hw * 0.7, base_y), Vector2(cx - hw * 0.7, base_y)])
			draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.35 if has_x else 0.2))
			var outl := pts.duplicate()
			outl.append(pts[0])
			draw_polyline(outl, col.lightened(0.2), 2.0, true)
			draw_line(tip, Vector2(cx, base_y), Color(1, 1, 1, 0.18), 1.0)
			# 下面：a_{k}x^{k}
			var lab := "a_{%d}" % k + ("" if k == 0 else ("x" if k == 1 else "x^{%d}" % k))
			MathLabel.draw_on(self, font, cx, base_y + (22.0 if big else 18.0), lab, UITheme.fs(15 if big else 12), Color(0.85, 0.82, 0.95))
			# 上面：這一項變成什麼
			var chip_t := chip(k, x) if has_x else "?"
			UITheme.text_ol(self, font, Vector2(cx - 30, base_y - ch - 8), chip_t, HORIZONTAL_ALIGNMENT_CENTER, 60,
				UITheme.fs(18 if big else 14), col.lightened(0.35) if has_x else Color(1, 1, 1, 0.45))
		# 最下面的式子
		if has_x:
			var s := sum_text(deg, x)
			var fs := UITheme.fs(18 if big else 15)
			while fs > UITheme.fs(12) and MathLabel.text_width(font, s, fs) > rc.size.x - 20.0:
				fs -= 1
			MathLabel.draw_on(self, font, rc.get_center().x, rc.end.y - (8.0 if big else 2.0), s, fs, Color(1, 0.92, 0.7))
