extends "level_trig4_tide.gd"
## 三角函數 第五大關「和角羅盤」（對應講義 1-2 重點一：和角公式）
## 繼承第四關（夜海背景、函數圖、旋鈕面板的小工具都一樣），題庫在 trig5_bank.gd。
##
## 這一關多了三種「動手」的步驟：
##   ・rot    雙層轉盤：拖動外盤 α、內盤 β，指針停在 α + β（或看兩根指針的弦 AB，α − β），即時看公式怎麼展開
##   ・tiles  拼公式：把 sin α、cos β、＋、－… 的積木一塊一塊接起來，旁邊的試算表用幾組角度檢查你的式子對不對
##   ・lines  兩直線夾角：拖動直線 L₂ 的斜率，看夾角 θ 和 tan θ = |(m₂ − m₁) ÷ (1 + m₁m₂)| 怎麼變，找出夾角剛好是指定值的直線
##   速算：用和差角公式「合併」，說出特殊角的值

const BankG5 := preload("trig5_bank.gd")
const COMPASS := UITheme.PINK

const CHAPTERS_G5 := [
	{"ch": 1, "name": "第一章．雙層轉盤", "topic": "和角、差角公式（sin、cos、tan）與合併", "color": UITheme.PINK},
	{"ch": 2, "name": "第二章．羅盤的應用", "topic": "象限與正負、求角度、三角形、兩直線夾角、幾何應用", "color": UITheme.PINK_LIGHT},
]

var rot_info: MathLabel
var tiles_fx: MathLabel
var tiles_part := 0              # 分數模式：0 填分子、1 填分母
var tiles_num: Array = []
var tiles_den: Array = []
var tiles_part_btns: Array = []
var lines_info: MathLabel
var _rot_sliders: Array = []


func level_id() -> String:
	return "G5"

func level_title() -> String:
	return "和角羅盤"

func level_subtitle() -> String:
	return "和角公式"

func level_chapters() -> Array:
	return CHAPTERS_G5

func bank_slots() -> Array:
	return BankG5.slots()

func step_color() -> Color:
	return COMPASS

func chapter_card() -> Dictionary:
	return {"title": "第二章．羅盤的應用", "button": "進入羅盤的應用  ▶",
		"text": "公式會背了，接下來真的拿來用：\n\n" \
			+ "・只知道 sin α，cos α 是正是負？看象限\n" \
			+ "・tan α、tan β 都知道，α + β 是幾度？\n" \
			+ "・三角形的內角和是 180°：tan C = −tan(A + B)\n" \
			+ "・兩條直線的夾角，其實是 tan 的差角公式\n" \
			+ "・把圖形拆成兩個角，再用和角公式\n\n" \
			+ "轉動羅盤吧！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = CompassView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "速算"
		_tv().tide_changed.connect(_on_tide_changed)
		_tv().tap_missed.connect(_on_tap_missed)


func _cv2() -> CompassView:
	return fview as CompassView


func _on_tide_changed() -> void:
	if fview == null:
		return
	match _tv().mode:
		"rot":
			_refresh_rot()
		"tiles":
			_refresh_tiles()
		"lines":
			_refresh_lines()
		_:
			super()


func _forge_step() -> void:
	super()
	if si >= steps.size():
		return
	var st: Dictionary = steps[si]
	match String(st.kind):
		"rot":
			_build_rot(st)
		"tiles":
			_build_tiles(st)
		"lines":
			_build_lines(st)


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size():
		match String(steps[si].kind):
			"rot":
				_rot_submit()
				return
			"tiles":
				_tiles_submit()
				return
			"lines":
				_lines_submit()
				return
	super()


# ================= 公式的小工具 =================

static func _trig(fn: String, x: float) -> float:
	match fn:
		"sin":
			return sin(x)
		"cos":
			return cos(x)
	return tan(x)


## 拼公式用：key 對應的「正確的式子」的值
static func tiles_target(key: String, a: float, b: float) -> float:
	match key:
		"sin_sum":
			return sin(a + b)
		"sin_diff":
			return sin(a - b)
		"cos_sum":
			return cos(a + b)
		"cos_diff":
			return cos(a - b)
		"tan_sum":
			return tan(a + b)
	return tan(a - b)


const TILE_VARS := ["sa", "ca", "ta", "sb", "cb", "tb"]
const TILE_MAP := {"sin α": "sa", "cos α": "ca", "tan α": "ta", "sin β": "sb", "cos β": "cb", "tan β": "tb",
	"+": "+", "−": "-", "×": "*", "÷": "/", "(": "(", ")": ")", "1": "1.0", "2": "2.0"}


## 積木序列 → 可以計算的式子（相鄰的兩個積木中間補乘號）
static func tiles_expr(seq: Array) -> String:
	var out := ""
	var prev := ""
	for t in seq:
		var s: String = TILE_MAP[t]
		var kind := "atom"
		if s in ["+", "-", "*", "/"]:
			kind = "op"
		elif s == "(" or s == ")":
			kind = s
		if (prev == "atom" or prev == ")") and (kind == "atom" or kind == "("):
			out += "*"
		out += s
		prev = kind
	return out


## 用 a、b（弧度）算積木式子的值；式子不完整就回傳 NAN
static func tiles_value(seq: Array, a: float, b: float) -> float:
	if seq.is_empty():
		return NAN
	var ex := Expression.new()
	if ex.parse(tiles_expr(seq), TILE_VARS) != OK:
		return NAN
	var res = ex.execute([sin(a), cos(a), tan(a), sin(b), cos(b), tan(b)], null, false)
	if ex.has_execute_failed() or not (res is float or res is int):
		return NAN
	return float(res)


# ================= rot：雙層轉盤 =================

func _build_rot(st: Dictionary) -> void:
	_prep_panel(st)
	var tv := _cv2()
	var card := _info_card(COMPASS)
	rot_info = _math_label(19, 330, 50, UITheme.TEXT)
	card.add_child(rot_info)
	_rot_sliders = []
	var step := float(st.get("step", 15.0))
	var start: Array = st.get("start", [0.0, 0.0])
	for spec in [["α 外盤", "a", st.get("arange", [0.0, 360.0]), UITheme.CYAN, float(start[0])],
			["β 內盤", "b", st.get("brange", [0.0, 360.0]), UITheme.PINK_LIGHT, float(start[1])]]:
		var rg: Array = spec[2]
		var n := int(round((float(rg[1]) - float(rg[0])) / step))
		var col: Color = spec[3]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		rank_box.add_child(row)
		var nm := Label.new()
		nm.text = String(spec[0])
		nm.custom_minimum_size = Vector2(64, 0)
		nm.add_theme_font_size_override("font_size", UITheme.fs(15))
		nm.add_theme_color_override("font_color", col)
		row.add_child(nm)
		var s := UITheme.touch_slider()
		s.min_value = 0
		s.max_value = n
		s.step = 1
		s.value = clampi(int(round((float(spec[4]) - float(rg[0])) / step)), 0, n)
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.custom_minimum_size = Vector2(0, 28)
		UITheme.tint_slider(s, col)
		row.add_child(s)
		UITheme.add_step_buttons(s, col)
		var vl := Label.new()
		vl.custom_minimum_size = Vector2(54, 0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.add_theme_font_size_override("font_size", UITheme.fs(15))
		vl.add_theme_color_override("font_color", col)
		row.add_child(vl)
		var which: String = spec[1]
		var lo: float = float(rg[0])
		vl.text = "%d°" % int(lo + s.value * step)
		s.value_changed.connect(func(v: float):
			if busy:
				return
			var deg := lo + v * step
			if which == "a":
				_cv2().rot_a = deg
			else:
				_cv2().rot_b = deg
			vl.text = "%d°" % int(deg)
			MoonView.dragged_ever = true
			Game.of(self).play("blip", 0.8 + 0.02 * v, -18.0)
			_refresh_rot())
		_rot_sliders.append(s)
	tv.rot_a = float(st.get("arange", [0.0, 360.0])[0]) + float(_rot_sliders[0].value) * step
	tv.rot_b = float(st.get("brange", [0.0, 360.0])[0]) + float(_rot_sliders[1].value) * step
	tv.rot_show_a = tv.rot_a
	tv.rot_show_b = tv.rot_b
	tv.mode = "rot"
	tv.spec = st
	tv.circ = {}
	tv.task_q = String(st.q)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_rot()


func _refresh_rot() -> void:
	if rot_info == null or not is_instance_valid(rot_info):
		return
	var st: Dictionary = steps[si]
	var tv := _cv2()
	var diff: bool = String(st.mode) == "diff"
	var res: float = tv.rot_a - tv.rot_b if diff else tv.rot_a + tv.rot_b
	rot_info.text = "α = %s°　β = %s°\nα %s β = %s°" % [_dg(tv.rot_a), _dg(tv.rot_b), "−" if diff else "+", _dg(res)]
	tv.queue_redraw()


static func _dg(v: float) -> String:
	return ("−" if roundi(v) < 0 else "") + str(absi(roundi(v)))


static func _deg_in(list: Array, v: float) -> bool:
	for x in list:
		if posmod(roundi(float(x)), 360) == posmod(roundi(v), 360):
			return true
	return false


func _rot_submit() -> void:
	var st: Dictionary = steps[si]
	var tv := _cv2()
	var diff: bool = String(st.mode) == "diff"
	var res: float = tv.rot_a - tv.rot_b if diff else tv.rot_a + tv.rot_b
	var sym := "α − β" if diff else "α + β"
	var off := absf(fposmod(res - float(st.target) + 180.0, 360.0) - 180.0)
	if st.get("abs", false):
		# ∠AOB 是兩根指針夾的角：α − β = −90° 和 90° 是同一個角
		off = minf(off, absf(fposmod(-res - float(st.target) + 180.0, 360.0) - 180.0))
	if off > 1e-6:
		_wrong(st, "現在 %s = %s°，目標是 %d°。提示：%s" % [sym, _dg(res), roundi(float(st.target)), String(st.nudge)])
		return
	var al: Array = st.get("alphas", [])
	var be: Array = st.get("betas", [])
	if not al.is_empty() and not _deg_in(al, tv.rot_a):
		_wrong(st, "%s 對了，但 α 要用特殊角：%s。" % [sym, "、".join(al.map(func(x): return "%d°" % int(x))) ])
		return
	if not be.is_empty() and not _deg_in(be, tv.rot_b):
		_wrong(st, "%s 對了，但 β 要用特殊角：%s。" % [sym, "、".join(be.map(func(x): return "%d°" % int(x))) ])
		return
	Game.of(self).sfx("correct")
	tv.burst_center()
	var keep := {}
	var ra := deg_to_rad(tv.rot_a)
	var rb := deg_to_rad(tv.rot_b)
	if diff:
		keep = {"angles": [ra, rb], "labels": ["A", "B"], "proj": "y"}
	else:
		keep = {"theta": ra + rb, "label": "%d°" % roundi(res)}
	_interact_done(st, keep)


# ================= tiles：拼公式 =================

func _build_tiles(st: Dictionary) -> void:
	_prep_panel(st)
	var tv := _cv2()
	var card := _info_card(COMPASS)
	tiles_fx = _math_label(18, 330, 54, UITheme.TEXT)
	card.add_child(tiles_fx)
	# 分數模式（tan 的和差角）：分數線已經畫好，積木分別放進分子、分母，不用自己打括號
	var frac: bool = st.get("frac", false)
	tiles_part = 0
	tiles_num = []
	tiles_den = []
	tiles_part_btns = []
	if frac:
		var prow := HBoxContainer.new()
		prow.add_theme_constant_override("separation", 6)
		rank_box.add_child(prow)
		for pi in 2:
			var pb := Button.new()
			pb.text = "放進分子" if pi == 0 else "放進分母"
			pb.toggle_mode = true
			pb.custom_minimum_size = Vector2(0, 32)
			pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_tint_button(pb, UITheme.GOLD, 15)
			var pk: int = pi
			pb.pressed.connect(func():
				tiles_part = pk
				_refresh_tiles())
			prow.add_child(pb)
			tiles_part_btns.append(pb)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	rank_box.add_child(grid)
	var toks: Array = st.tokens
	if frac:
		toks = toks.filter(func(x): return not (String(x) in ["÷", "(", ")"]))
	for t in toks:
		var b := Button.new()
		b.text = String(t)
		b.custom_minimum_size = Vector2(0, 32)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col: Color = UITheme.TEXT_SOFT
		if String(t).begins_with("sin"):
			col = UITheme.CYAN
		elif String(t).begins_with("cos"):
			col = UITheme.ORANGE
		elif String(t).begins_with("tan"):
			col = UITheme.LIME
		_tint_button(b, col, 16)
		var tt: String = t
		b.pressed.connect(func():
			_tiles_add(tt))
		grid.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	rank_box.add_child(row)
	for spec in [["退一步", 0], ["全部清除", 1]]:
		var b2 := Button.new()
		b2.text = spec[0]
		b2.custom_minimum_size = Vector2(0, 32)
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_tint_button(b2, UITheme.TEXT_SOFT, 15)
		var kind: int = spec[1]
		b2.pressed.connect(func():
			_tiles_back(kind))
		row.add_child(b2)
	tv.mode = "tiles"
	tv.spec = st
	tv.tiles_seq = []
	tv.tiles_rows = []
	tv.circ = {}
	tv.task_q = String(st.q)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_tiles()


func _tiles_add(t: String) -> void:
	if busy:
		return
	var tv := _cv2()
	if tv.tiles_seq.size() >= int(steps[si].get("max", 16)):
		_hint("積木太多了，按「退一步」整理一下。", "info")
		return
	MoonView.dragged_ever = true
	if steps[si].get("frac", false):
		(tiles_num if tiles_part == 0 else tiles_den).append(t)
		tv.tiles_seq = _frac_seq()
	else:
		tv.tiles_seq.append(t)
	Game.of(self).play("blip", 1.0 + 0.03 * tv.tiles_seq.size(), -14.0)
	_refresh_tiles()


func _tiles_back(kind: int) -> void:
	if busy:
		return
	var tv := _cv2()
	if steps[si].get("frac", false):
		if kind == 0:
			var cur_a: Array = tiles_num if tiles_part == 0 else tiles_den
			if cur_a.is_empty():
				cur_a = tiles_den if tiles_part == 0 else tiles_num
			if not cur_a.is_empty():
				cur_a.pop_back()
		else:
			tiles_num = []
			tiles_den = []
		tv.tiles_seq = _frac_seq()
		Game.of(self).play("blip", 0.8, -14.0)
		_refresh_tiles()
		return
	if tv.tiles_seq.is_empty():
		return
	if kind == 0:
		tv.tiles_seq.pop_back()
	else:
		tv.tiles_seq = []
	Game.of(self).play("blip", 0.8, -14.0)
	_refresh_tiles()


## 分數模式：分子、分母組成可以計算的積木序列 (分子) ÷ (分母)
func _frac_seq() -> Array:
	if tiles_num.is_empty() and tiles_den.is_empty():
		return []
	var out := ["("]
	out.append_array(tiles_num)
	out.append_array([")", "÷", "("])
	out.append_array(tiles_den if not tiles_den.is_empty() else ["1"])
	out.append(")")
	return out


const SAMPLES := [[30.0, 45.0], [110.0, 35.0], [60.0, 15.0], [20.0, 50.0]]


func _refresh_tiles() -> void:
	if tiles_fx == null or not is_instance_valid(tiles_fx):
		return
	var st: Dictionary = steps[si]
	var tv := _cv2()
	var rows := []
	var all_ok := not tv.tiles_seq.is_empty()
	for sm in SAMPLES:
		var a := deg_to_rad(float(sm[0]))
		var b := deg_to_rad(float(sm[1]))
		var want := tiles_target(String(st.target), a, b)
		var got := tiles_value(tv.tiles_seq, a, b)
		var ok := not is_nan(got) and absf(got - want) < 1e-6 * maxf(1.0, absf(want))
		if not ok:
			all_ok = false
		rows.append({"a": sm[0], "b": sm[1], "want": want, "got": got, "ok": ok})
	tv.tiles_rows = rows
	tv.matched = all_ok
	var body := "  ".join(tv.tiles_seq) if not tv.tiles_seq.is_empty() else "（還沒有積木）"
	if st.get("frac", false):
		# 分數：正在填的那一格用金色標出來
		var hi := "[color=#%s]" % UITheme.GOLD.to_html(false)
		var nt := " ".join(tiles_num) if not tiles_num.is_empty() else "□"
		var dt := " ".join(tiles_den) if not tiles_den.is_empty() else "□"
		if tiles_part == 0:
			nt = hi + nt + "[/color]"
		else:
			dt = hi + dt + "[/color]"
		body = "\\frac{%s}{%s}" % [nt, dt]
		for k in tiles_part_btns.size():
			(tiles_part_btns[k] as Button).set_pressed_no_signal(k == tiles_part)
		if tiles_den.is_empty():
			all_ok = false
			tv.matched = false
	tiles_fx.text = "%s = %s" % [String(st.expr), body] if st.get("frac", false) else "%s =\n%s" % [String(st.expr), body]
	tv.queue_redraw()


func _tiles_submit() -> void:
	var st: Dictionary = steps[si]
	var tv := _cv2()
	if tv.tiles_seq.is_empty():
		_wrong(st, "還沒有放積木喔！點下面的積木，把公式拼出來。")
		return
	if tv.matched:
		Game.of(self).sfx("correct")
		tv.burst_center()
		_interact_done(st, {})
		return
	var msg := "這個式子還不對。"
	for row in tv.tiles_rows:
		if not bool(row.ok):
			if is_nan(float(row.got)):
				msg += "式子還不完整（括號、運算符號要接好）。"
			else:
				msg += "代 α = %d°、β = %d°：你的式子 = %s，但 %s = %s。" % [int(row.a), int(row.b),
					CompassView.dec3(float(row.got)), String(st.expr), CompassView.dec3(float(row.want))]
			break
	_wrong(st, msg + "提示：" + String(st.nudge).replace(" ÷ ", " 除以 "))


# ================= lines：兩直線夾角 =================

static func line_theta(m1: float, m2: float) -> float:
	var t := absf(atan(m1) - atan(m2))
	if t > PI / 2.0:
		t = PI - t
	return t


func _build_lines(st: Dictionary) -> void:
	_prep_panel(st)
	var tv := _cv2()
	var card := _info_card(COMPASS)
	lines_info = _math_label(17, 330, 70, UITheme.TEXT)
	card.add_child(lines_info)
	var vals: Array = st.slopes
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	rank_box.add_child(row)
	var nm := Label.new()
	nm.text = "L₂ 斜率"
	nm.custom_minimum_size = Vector2(64, 0)
	nm.add_theme_font_size_override("font_size", UITheme.fs(15))
	nm.add_theme_color_override("font_color", UITheme.PINK_LIGHT)
	row.add_child(nm)
	var s := UITheme.touch_slider()
	s.min_value = 0
	s.max_value = vals.size() - 1
	s.step = 1
	var i0 := 0
	var best := 1e18
	for i in vals.size():
		var dd := absf(float(vals[i]) - float(st.get("start", 0.0)))
		if dd < best:
			best = dd
			i0 = i
	s.value = i0
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.custom_minimum_size = Vector2(0, 28)
	UITheme.tint_slider(s, UITheme.PINK_LIGHT)
	row.add_child(s)
	UITheme.add_step_buttons(s, UITheme.PINK_LIGHT)
	var vl := Label.new()
	vl.custom_minimum_size = Vector2(54, 0)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vl.add_theme_font_size_override("font_size", UITheme.fs(15))
	vl.add_theme_color_override("font_color", UITheme.PINK_LIGHT)
	row.add_child(vl)
	vl.text = TideView.fr(float(vals[i0]))
	s.value_changed.connect(func(v: float):
		if busy:
			return
		_cv2().line_m = float(vals[int(v)])
		vl.text = TideView.fr(float(vals[int(v)]))
		MoonView.dragged_ever = true
		Game.of(self).play("blip", 0.8 + 0.03 * v, -18.0)
		_refresh_lines())
	_tip("拖動 L₂ 的斜率，找出夾角剛好是目標的直線（可能不只一條）。")
	tv.mode = "lines"
	tv.spec = st
	tv.line_m = float(vals[i0])
	tv.found = []
	tv.circ = {}
	tv.task_q = String(st.q)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_lines()


func _refresh_lines() -> void:
	if lines_info == null or not is_instance_valid(lines_info):
		return
	var st: Dictionary = steps[si]
	var tv := _cv2()
	var m1 := float(st.m1)
	var m2: float = tv.line_m
	var n: int = st.targets.size()
	var found := "　已找到 %d／%d 條" % [tv.found.size(), n] if n > 1 else ""
	if absf(m1 - m2) < 1e-9:
		lines_info.text = "L₂ 和 L₁ 重合（夾角 0）%s" % found
	else:
		var den := 1.0 + m1 * m2
		var t := absf((m2 - m1) / den) if absf(den) > 1e-9 else INF
		var a1 := TideView.fr(m1)
		var a2 := TideView.fr(m2)
		var tt := TideView.fr(t) if t < 1e8 else "不存在（θ = 90°）"
		lines_info.text = "tan θ = \\frac{|%s − %s|}{|1 + %s × %s|}\n= %s%s" % [a2, a1, a1, a2, tt, found]
	tv.queue_redraw()


func _lines_submit() -> void:
	var st: Dictionary = steps[si]
	var tv := _cv2()
	var m1 := float(st.m1)
	var m2: float = tv.line_m
	var th := line_theta(m1, m2)
	var want := atan(float(st.tan))
	if absf(m1 - m2) < 1e-9 or absf(th - want) > 1e-6:
		var shown := "重合" if absf(m1 - m2) < 1e-9 else "tan θ = %s" % TideView.fr(tan(th))
		_wrong(st, "這條直線的夾角不對（%s），目標是 tan θ = %s。提示：%s" % [shown, TideView.fr(float(st.tan)), String(st.nudge)])
		return
	for f in tv.found:
		if absf(float(f) - m2) < 1e-9:
			_hint("這條已經找到了，再找找另一條！", "info")
			return
	tv.found.append(m2)
	Game.of(self).sfx("correct")
	tv.burst_center()
	_refresh_lines()
	if tv.found.size() < st.targets.size():
		_hint("✓ 找到一條！還有 %d 條。" % (st.targets.size() - tv.found.size()), "good")
		return
	_interact_done(st, {})


# ================= 速算 =================

func _speed_gen(kind: String, n: int) -> Array:
	if kind != "compass":
		return super(kind, n)
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 2000:
		guard += 1
		var pb := _gen_compass()
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		out.append(pb)
	return out


## 用和差角公式合併：sin A cos B ± cos A sin B、cos A cos B ∓ sin A sin B
static func _gen_compass() -> Dictionary:
	var kind: int = randi() % 4        # 0 sin 和、1 sin 差、2 cos 和、3 cos 差
	var res: int = [30, 45, 60, 90, 120, 135, 150].pick_random()
	var a := 0
	var b := 0
	if kind == 0 or kind == 2:
		a = randi_range(2, res / 5 - 2) * 5
		b = res - a
	else:
		b = randi_range(2, 14) * 5
		a = res + b
		if a > 175:
			return _gen_compass()
	var e := ""
	var f := "sin" if kind < 2 else "cos"
	match kind:
		0:
			e = "sin %d° cos %d° + cos %d° sin %d°" % [a, b, a, b]
		1:
			e = "sin %d° cos %d° − cos %d° sin %d°" % [a, b, a, b]
		2:
			e = "cos %d° cos %d° − sin %d° sin %d°" % [a, b, a, b]
		3:
			e = "cos %d° cos %d° + sin %d° sin %d°" % [a, b, a, b]
	var ans := ""
	for cand in [[0.0, "0"], [0.5, "1/2"], [1.0, "1"], [sqrt(3.0) / 2.0, "√3/2"], [sqrt(2.0) / 2.0, "√2/2"]]:
		for sg in [1.0, -1.0]:
			if absf(_trig(f, deg_to_rad(res)) - sg * float(cand[0])) < 1e-6:
				ans = ("−" if sg < 0.0 and cand[1] != "0" else "") + String(cand[1])
	return {"eq": e, "q": "合併成一個角，求值。", "template": "原式 = [0]", "ans": ans,
		"nudge": "看符號和順序：合併成 %s(%s)。" % [f, ("%d° %s %d°" % [a, "+" if kind % 2 == 0 else "−", b])],
		"tag": BankG5.T_MERGE}


# ================= 畫面 =================

class CompassView extends TideView:
	var rot_a := 0.0
	var rot_b := 0.0
	var rot_show_a := 0.0
	var rot_show_b := 0.0
	var tiles_seq: Array = []
	var tiles_rows: Array = []
	var line_m := 0.0

	func setup(round: Dictionary) -> void:
		super(round)
		tiles_seq = []
		tiles_rows = []

	static func dec3(v: float) -> String:
		if is_nan(v):
			return "—"
		return UITheme.num(v, 3).replace("-", "−")

	func _process(delta: float) -> void:
		if mode == "rot":
			rot_show_a = lerpf(rot_show_a, rot_a, 1.0 - exp(-12.0 * delta))
			rot_show_b = lerpf(rot_show_b, rot_b, 1.0 - exp(-12.0 * delta))
		super(delta)

	func _draw_mode(font: Font) -> void:
		if mode != "rot" and mode != "tiles" and mode != "lines":
			super(font)
			return
		var rc := _spin_rect()
		draw_style_box(UITheme.boxc(Color(0.03, 0.06, 0.14, 0.62), 14, Color(1.0, 0.6, 0.8, 0.28), 1, 0), rc)
		_draw_task(font, rc, "轉動羅盤")
		match mode:
			"rot":
				_draw_rot(font, rc)
			"tiles":
				_draw_tiles(font, rc)
			"lines":
				_draw_lines(font, rc)

	# --- rot ---

	## 右邊的算式：公式 → 代入數字 → 精確值
	func _rot_lines(a: float, b: float) -> Array:
		var fn := String(spec.get("fn", "sin"))
		var diff := String(spec.mode) == "diff"
		var ra := deg_to_rad(a)
		var rb := deg_to_rad(b)
		var res := a - b if diff else a + b
		var sa := sin(ra)
		var ca := cos(ra)
		var sb := sin(rb)
		var cb := cos(rb)
		var sg := "−" if diff else "+"
		var lines := []
		match fn:
			"sin":
				lines.append("sin(α %s β) = sin α cos β %s cos α sin β" % [sg, sg])
				lines.append("= %s × %s %s %s × %s" % [dec3(sa), dec3(cb), sg, dec3(ca), dec3(sb)])
				lines.append("= %s" % dec3(sin(deg_to_rad(res))))
			"cos":
				var s2 := "+" if diff else "−"
				lines.append("cos(α %s β) = cos α cos β %s sin α sin β" % [sg, s2])
				lines.append("= %s × %s %s %s × %s" % [dec3(ca), dec3(cb), s2, dec3(sa), dec3(sb)])
				lines.append("= %s" % dec3(cos(deg_to_rad(res))))
			_:
				lines.append("tan(α %s β) = \\frac{tan α %s tan β}{1 %s tan α tan β}" % [sg, sg, "+" if diff else "−"])
				if absf(ca) < 1e-9 or absf(cb) < 1e-9 or absf(cos(deg_to_rad(res))) < 1e-9:
					lines.append("有一個角的 tan 不存在")
					lines.append("")
				else:
					lines.append("= %s" % dec3(tan(deg_to_rad(res))))
					lines.append("")
		return lines

	func _draw_rot(font: Font, rc: Rect2) -> void:
		var diff := String(spec.mode) == "diff"
		var c := Vector2(rc.position.x + 132.0, rc.position.y + 170.0)
		var rad := 92.0
		# 單位圓與刻度
		draw_line(c - Vector2(rad + 14, 0), c + Vector2(rad + 14, 0), Color(1, 1, 1, 0.3), 1.2)
		draw_line(c - Vector2(0, rad + 14), c + Vector2(0, rad + 14), Color(1, 1, 1, 0.3), 1.2)
		draw_arc(c, rad, 0, TAU, 96, Color(1, 1, 1, 0.55), 2.0, true)
		for k in 24:
			var ang := k * PI / 12.0
			var dv := Vector2(cos(ang), -sin(ang))
			var l := 8.0 if k % 6 == 0 else (5.0 if k % 2 == 0 else 3.0)
			draw_line(c + dv * (rad - l), c + dv * (rad + l), Color(1, 1, 1, 0.45 if k % 6 == 0 else 0.22), 1.2)
		var a := deg_to_rad(rot_show_a)
		var b := deg_to_rad(rot_show_b)
		var pa := c + Vector2(cos(a), -sin(a)) * rad
		var cyan := UITheme.CYAN
		var pink := UITheme.PINK_LIGHT
		if diff:
			var pb := c + Vector2(cos(b), -sin(b)) * rad
			# 兩根指針與夾角
			_arc_between(c, 26.0, b, a, UITheme.GOLD, 3.0)
			draw_line(c, pb, pink, 3.0, true)
			draw_line(c, pa, cyan, 3.0, true)
			draw_line(pa, pb, UITheme.GOLD, 3.0, true)
			UITheme.dot(self, pa, 7.0, cyan)
			UITheme.dot(self, pb, 7.0, pink)
			MathLabel.draw_on(self, font, pa.x + 14.0 * cos(a), pa.y - 14.0 * sin(a), "A", UITheme.fs(15), cyan)
			MathLabel.draw_on(self, font, pb.x + 14.0 * cos(b), pb.y - 14.0 * sin(b), "B", UITheme.fs(15), pink)
			var ab2 := 2.0 - 2.0 * cos(a - b)
			var mid := (pa + pb) / 2.0
			MathLabel.draw_on(self, font, mid.x, mid.y - 12.0, "AB = %s" % dec3(sqrt(maxf(ab2, 0.0))), UITheme.fs(13), UITheme.GOLD)
		else:
			var ps := c + Vector2(cos(a + b), -sin(a + b)) * rad
			_arc_between(c, 24.0, 0.0, a, cyan, 3.0)
			_arc_between(c, 36.0, a, a + b, pink, 3.0)
			draw_line(c, c + Vector2(rad, 0), Color(1, 1, 1, 0.5), 2.0)
			draw_line(c, pa, cyan, 2.5, true)
			draw_line(c, ps, UITheme.GOLD, 3.5, true)
			UITheme.dot(self, pa, 6.0, cyan)
			UITheme.dot(self, ps, 8.0, UITheme.GOLD)
			UITheme.dot(self, ps, 3.5, Color.WHITE)
			MathLabel.draw_on(self, font, ps.x + 16.0 * cos(a + b), ps.y - 16.0 * sin(a + b), "P", UITheme.fs(15), UITheme.GOLD)
			draw_line(Vector2(ps.x, c.y), ps, Color(1, 0.85, 0.35, 0.6), 1.5)
			draw_dashed_line(ps, Vector2(c.x, ps.y), Color(1, 0.85, 0.35, 0.4), 1.2, 4.0)
		UITheme.dot(self, c, 3.5, Color(1, 1, 1, 0.8))
		# 右邊的算式
		var x0 := rc.position.x + 262.0
		var w := rc.end.x - x0 - 14.0
		var lines := _rot_lines(rot_a, rot_b)
		var y := rc.position.y + 66.0
		for i in lines.size():
			var s := String(lines[i])
			if s == "":
				continue
			var fs := UITheme.fs(15 if i != 2 else 17)
			var col := Color(0.9, 0.95, 1.0, 0.95) if i != 2 else UITheme.GOLD
			var tw := MathLabel.text_width(font, s, fs)
			while fs > UITheme.fs(11) and tw > w:
				fs -= 1
				tw = MathLabel.text_width(font, s, fs)
			var ex := MathLabel.line_extent(s, fs)
			MathLabel.draw_on(self, font, x0 + tw / 2.0, y + ex.x, s, fs, col)
			y += ex.x + ex.y + 10.0
		# 精確值
		var res := rot_a - rot_b if diff else rot_a + rot_b
		var fn := String(spec.get("fn", "sin"))
		var tx := "%s %d° = %s" % [fn, roundi(res), exact_text(fn, res)]
		var tfs := UITheme.fs(16)
		var tw2 := MathLabel.text_width(font, tx, tfs)
		while tfs > UITheme.fs(11) and tw2 > w:
			tfs -= 1
			tw2 = MathLabel.text_width(font, tx, tfs)
		var ex2 := MathLabel.line_extent(tx, tfs)
		draw_style_box(UITheme.boxc(Color(1, 0.85, 0.35, 0.08), 8, Color(1, 0.85, 0.35, 0.4), 1, 0),
			Rect2(x0 - 6.0, rc.end.y - 58.0, w + 12.0, 40.0))
		MathLabel.draw_on(self, font, x0 + tw2 / 2.0, rc.end.y - 38.0 + ex2.x * 0.3, tx, tfs, Color(1, 0.92, 0.7))

	## 特殊角（第一象限）的 [sin, cos, tan]
	const SV := {
		0: ["0", "1", "0"],
		15: ["(√{6} − √{2})/4", "(√{6} + √{2})/4", "2 − √{3}"],
		30: ["1/2", "√{3}/2", "√{3}/3"],
		45: ["√{2}/2", "√{2}/2", "1"],
		60: ["√{3}/2", "1/2", "√{3}"],
		75: ["(√{6} + √{2})/4", "(√{6} − √{2})/4", "2 + √{3}"],
		90: ["1", "0", ""],
	}

	## 15° 的倍數的 sin／cos／tan 的精確值（排版用的文字），不是特殊角就寫小數
	static func exact_text(fn: String, deg: float) -> String:
		var d := roundi(deg)
		if absf(deg - d) > 1e-6 or d % 15 != 0:
			var x := deg_to_rad(deg)
			return dec3(sin(x) if fn == "sin" else (cos(x) if fn == "cos" else tan(x)))
		d = posmod(d, 360)
		var ref := d
		var sg := 1
		if d > 270:
			ref = 360 - d
			sg = 1 if fn == "cos" else -1
		elif d > 180:
			ref = d - 180
			sg = 1 if fn == "tan" else -1
		elif d > 90:
			ref = 180 - d
			sg = 1 if fn == "sin" else -1
		var idx: int = {"sin": 0, "cos": 1, "tan": 2}[fn]
		var base: String = SV[ref][idx]
		if base == "":
			return "無定義"
		if base == "0":
			return "0"
		if sg > 0:
			return base
		if base.contains(" ") and not base.begins_with("("):
			return "−(" + base + ")"
		return "−" + base

	## 從角 a0 轉到 a1 的弧（弧度）
	func _arc_between(c: Vector2, r: float, a0: float, a1: float, col: Color, w: float) -> void:
		var n := maxi(4, int(absf(a1 - a0) / 0.08))
		var pts := PackedVector2Array()
		for i in n + 1:
			var a := lerpf(a0, a1, float(i) / n)
			pts.append(c + Vector2(cos(a), -sin(a)) * r)
		if pts.size() >= 2:
			draw_polyline(pts, Color(col.r, col.g, col.b, 0.3), w + 4.0, true)
			draw_polyline(pts, col, w, true)

	# --- tiles ---

	func _draw_tiles(font: Font, rc: Rect2) -> void:
		var x0 := rc.position.x + 20.0
		var y0 := rc.position.y + 56.0
		var colx := [x0, x0 + 150.0, x0 + 300.0, x0 + 450.0]
		var heads := ["α、β", "正確的值", "你的式子", ""]
		for i in 3:
			MathLabel.draw_on(self, font, colx[i] + 50.0, y0 + 10.0, heads[i], UITheme.fs(14), Color(1, 1, 1, 0.6))
		draw_line(Vector2(x0, y0 + 20.0), Vector2(rc.end.x - 20.0, y0 + 20.0), Color(1, 1, 1, 0.2), 1.0)
		var y := y0 + 48.0
		for row in tiles_rows:
			var ok := bool(row.ok)
			var col := UITheme.GOOD if ok else (UITheme.ROSE if not is_nan(float(row.got)) else Color(1, 1, 1, 0.35))
			MathLabel.draw_on(self, font, colx[0] + 50.0, y, "%d°、%d°" % [int(row.a), int(row.b)], UITheme.fs(16), Color(0.85, 0.92, 1.0))
			MathLabel.draw_on(self, font, colx[1] + 50.0, y, dec3(float(row.want)), UITheme.fs(16), UITheme.GOLD)
			MathLabel.draw_on(self, font, colx[2] + 50.0, y, dec3(float(row.got)), UITheme.fs(16), col)
			MathLabel.draw_on(self, font, colx[3] + 10.0, y, "✓" if ok else ("✗" if not is_nan(float(row.got)) else ""), UITheme.fs(20), col)
			y += 40.0
		if matched:
			MathLabel.draw_on(self, font, rc.end.x - 90.0, rc.end.y - 22.0, "全部吻合！按確定", UITheme.fs(16), UITheme.GOOD)
		else:
			MathLabel.draw_on(self, font, rc.position.x + 210.0, rc.end.y - 22.0, "每一列都要「正確的值＝你的式子」", UITheme.fs(13), Color(1, 1, 1, 0.55))

	# --- lines ---

	func _draw_lines(font: Font, rc: Rect2) -> void:
		var m1 := float(spec.m1)
		var m2 := line_m
		var pt: Array = spec.p
		var px := float(pt[0])
		var py := float(pt[1])
		var area := Rect2(rc.position.x + 54.0, rc.position.y + 52.0, 212.0, 212.0)
		var g := {"x": [px - 4.0, px + 4.0], "y": [py - 4.0, py + 4.0], "xu": "num", "xt": 1.0, "yt": 1.0, "area": area, "curves": []}
		var same := absf(m1 - m2) < 1e-9
		g.curves.append({"f": "line", "m": m1, "k": py - m1 * px, "col": UITheme.CYAN})
		if not same:
			g.curves.append({"f": "line", "m": m2, "k": py - m2 * px, "col": UITheme.PINK_LIGHT})
		_plot(font, rc, g, true)
		var p := _map(area, g, px, py)
		# 夾角的弧（x、y 的比例一樣，所以看到的角度就是真的角度）
		if not same:
			var u1 := Vector2(1.0, -m1).normalized()
			var u2 := Vector2(1.0, -m2).normalized()
			if u1.dot(u2) < 0.0:
				u2 = -u2
			var s1 := atan2(u1.y, u1.x)
			var dl := wrapf(atan2(u2.y, u2.x) - s1, -PI, PI)
			var pts := PackedVector2Array()
			for i in 17:
				var a := s1 + dl * i / 16.0
				pts.append(p + Vector2(cos(a), sin(a)) * 38.0)
			draw_polyline(pts, Color(1, 0.85, 0.35, 0.35), 7.0, true)
			draw_polyline(pts, UITheme.GOLD, 2.5, true)
			var th := absf(rad_to_deg(atan(m1) - atan(m2)))
			if th > 90.0:
				th = 180.0 - th
			var am := s1 + dl / 2.0
			MathLabel.draw_on(self, font, p.x + cos(am) * 56.0, p.y + sin(am) * 56.0 + 5.0, "θ", UITheme.fs(16), UITheme.GOLD)
		UITheme.dot(self, p, 9.0, Color(1, 0.85, 0.35, 0.3))
		UITheme.dot(self, p, 5.0, UITheme.GOLD)
		MathLabel.draw_on(self, font, p.x + 16.0, p.y - 10.0, "P(%s, %s)" % [fr(px), fr(py)], UITheme.fs(12), UITheme.GOLD)
		# 右邊：兩條直線的說明
		var x0 := rc.position.x + 310.0
		var y := rc.position.y + 70.0
		MathLabel.draw_on(self, font, x0 + 100.0, y, "L₁：斜率 %s" % fr(m1), UITheme.fs(17), UITheme.CYAN)
		MathLabel.draw_on(self, font, x0 + 100.0, y + 34.0, "L₂：斜率 %s" % fr(m2), UITheme.fs(17), UITheme.PINK_LIGHT)
		MathLabel.draw_on(self, font, x0 + 150.0, y + 76.0, "目標：tan θ = %s" % fr(float(spec.tan)), UITheme.fs(17), UITheme.GOLD)
		for i in found.size():
			MathLabel.draw_on(self, font, x0 + 120.0, y + 116.0 + 30.0 * i, "✓ 找到：斜率 %s" % fr(float(found[i])), UITheme.fs(15), UITheme.GOOD)
