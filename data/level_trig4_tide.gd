extends "level_trig1_arc.gd"
## 三角函數 第四大關「潮汐調音盤」（對應講義 1-1 重點二後半：圖形的伸縮與平移、看圖求式、應用題、作圖求解）
## 繼承第一關（月光背景、√ 鍵都一樣），題庫在 trig4_bank.gd。
##
## 這一關多了四種「動手」的步驟（和選擇、填空、篩選一樣是 forge 旅程裡的一步）：
##   ・dial  調音旋鈕：拖動 a（高低）、b（快慢）、c（左右）、d（水位）的滑桿，讓你的波對上金色的目標波（或穿過資料點）
##   ・chain 變換鏈：把 y = sin x 一步一步變成目標。按下伸縮、平移的零件，順序不同結果就不同（先伸縮再平移！）
##   ・ride  摩天輪：拖動時間，看車廂的高度怎麼變成 y = a sin(bt + c) + d，找出指定高度的時刻
##   ・hunt  找交點：在圖上點出兩條曲線相交的每一個地方（解的個數、水位線與潮汐的交點）
## 下方的示意圖（"circles"）用 kind = "tide" 的圖，可以標中線、振幅、週期、平移量、資料點、水平線。
##   速算：看到 y = a sin(bx + c) + d，說出週期、平移量、最大值、最小值

const BankG4 := preload("trig4_bank.gd")
const TIDE := UITheme.VIOLET

const CHAPTERS_G4 := [
	{"ch": 1, "name": "第一章．旋鈕調音", "topic": "振幅、週期、平移，先伸縮再平移", "color": UITheme.VIOLET},
	{"ch": 2, "name": "第二章．潮汐與摩天輪", "topic": "看圖求式、潮汐與摩天輪、作圖求解", "color": UITheme.VIOLET_LIGHT},
]

const KNOB_COL := {"a": UITheme.PINK, "b": UITheme.CYAN, "c": UITheme.LIME, "d": UITheme.ORANGE}
const KNOB_NAME := {"a": "a 高低", "b": "b 快慢", "c": "c 左右", "d": "d 水位"}
const OP_COL := {"v": UITheme.PINK, "h": UITheme.CYAN, "x": UITheme.LIME, "y": UITheme.ORANGE}

var dial_fx: MathLabel
var dial_sub: MathLabel
var chain_fx: MathLabel
var chain_list: MathLabel
var ride_info: MathLabel
var ride_slider: HSlider
var ride_btn: Button
var hunt_info: MathLabel
var _knobs: Array = []         # 目前這一步的旋鈕：[{p, vals, mul, unit, fmt, label, slider, value_label}]
var _dial_start := {}
var _last_miss_hint := 0
var _tips: Array = []          # 這一步的小提示（放不下的時候會先收起來）


func level_id() -> String:
	return "G4"

func level_title() -> String:
	return "潮汐調音盤"

func level_subtitle() -> String:
	return "圖形的伸縮與平移"

func level_chapters() -> Array:
	return CHAPTERS_G4

func bank_slots() -> Array:
	return BankG4.slots()

func step_color() -> Color:
	return TIDE

func chapter_card() -> Dictionary:
	return {"title": "第二章．潮汐與摩天輪", "button": "進入潮汐與摩天輪  ▶",
		"text": "旋鈕都會調了，接下來把它用在真實的海浪上：\n\n" \
			+ "・看一張波形圖，反推出 a、b、c、d\n" \
			+ "・港口的潮汐表：什麼時候水夠深？\n" \
			+ "・摩天輪的車廂：離地高度就是一條正弦波\n" \
			+ "・作圖找解：兩條曲線到底交在幾個地方？\n\n" \
			+ "出海吧！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = TideView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "速算"
		_tv().tide_changed.connect(_on_tide_changed)
		_tv().tap_missed.connect(_on_tap_missed)


func _tv() -> TideView:
	return fview as TideView


## 下方的示意圖隨步驟換（題目寫 "circles"：用 after 比目前步驟小的最後一張）
func _update_circle() -> void:
	var lst: Array = r.get("circles", [])
	if lst.is_empty():
		return
	var pick := {}
	for sp in lst:
		if si > int(sp.get("after", -1)):
			pick = sp
	_tv().circ = pick


func _on_tide_changed() -> void:
	if fview == null:
		return
	match _tv().mode:
		"dial":
			_refresh_dial()
		"chain":
			_refresh_chain()
		"ride":
			_refresh_ride()
		"hunt":
			_refresh_hunt()


func _on_tap_missed() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_miss_hint < 1200:
		return
	_last_miss_hint = now
	_hint("那裡不是兩條曲線相交的位置。再看仔細一點！", "info")


# ================= 步驟分派 =================

func _forge_step() -> void:
	if fview != null:
		_tv().mode = ""
		_tv().play = false
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	super()
	if si >= steps.size():
		return
	var st: Dictionary = steps[si]
	match String(st.kind):
		"dial":
			_build_dial(st)
		"chain":
			_build_chain(st)
		"ride":
			_build_ride(st)
		"hunt":
			_build_hunt(st)
		_:
			_compact_panel.call_deferred()


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size():
		match String(steps[si].kind):
			"dial":
				_dial_submit()
				return
			"chain":
				_chain_submit()
				return
			"ride":
				_ride_submit()
				return
			"hunt":
				_hunt_submit()
				return
	super()


func _custom_reveal(msg: String) -> void:
	if fview != null:
		_tv().mode = ""
		_tv().play = false
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	super(msg)


## 互動步驟共用的右邊面板：清掉上一步、寫題目、準備「確定」鈕
func _prep_panel(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	rank_box.add_theme_constant_override("separation", 5)
	side_col.add_theme_constant_override("separation", 9)
	_tips = []
	# 題目已經寫在左邊畫面上方（task_q），右邊不重複寫，省出空間給控制項和提示
	task_label.visible = false
	task_label.text = st.q
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "確定"
	_compact_panel.call_deferred()


## 右邊卡片放不下時，依序收掉：開場的故事 → 小提示 → 題目。（答錯的提示出現時也會再收一次）
func _compact_panel() -> void:
	for stage_i in 5:
		await get_tree().process_frame
		if not is_instance_valid(side_col):
			return
		if side_col.get_combined_minimum_size().y <= _side_avail() + 1.0:
			return
		match stage_i:
			0:
				story_label.visible = false
			1:
				for t in _tips:
					if is_instance_valid(t):
						t.visible = false
			2:
				task_label.visible = false
			3:
				rank_box.add_theme_constant_override("separation", 2)
				side_col.add_theme_constant_override("separation", 5)


func _hint(text: String, kind: String = "info") -> void:
	super(text, kind)
	_compact_panel.call_deferred()


## 互動步驟答對：收起面板、寫進推導紀錄，下方留一張結果圖
func _interact_done(st: Dictionary, keep: Dictionary) -> void:
	var tv := _tv()
	tv.mode = ""
	tv.play = false
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not keep.is_empty():
		tv.circ = keep
	go_btn.visible = false
	_clear(rank_box)
	rank_box.visible = false
	_step_done(st, "")


func _info_card(color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.box(Color(color.r, color.g, color.b, 0.08), 14,
		Color(color.r, color.g, color.b, 0.4), 1, 7))
	rank_box.add_child(card)
	return card


func _math_label(fs: int, w: float, h: float, col: Color) -> MathLabel:
	var m := MathLabel.new()
	m.font_size = UITheme.fs(fs)
	m.max_width = int(w)
	m.align_center = true
	m.valign_center = true
	m.custom_minimum_size = Vector2(0, h)
	m.color = col
	return m


func _tip(text: String) -> void:
	var tip := Label.new()
	tip.text = text
	tip.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	tip.custom_minimum_size = Vector2(300, 0)
	tip.add_theme_font_size_override("font_size", UITheme.fs(14))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(tip)
	_tips.append(tip)


func _tint_button(b: Button, c: Color, fs: int) -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", UITheme.fs(fs))
	b.add_theme_stylebox_override("normal", UITheme.box(Color(c.r, c.g, c.b, 0.12), 10, Color(c.r, c.g, c.b, 0.5), 1, 6))
	b.add_theme_stylebox_override("hover", UITheme.box(Color(c.r, c.g, c.b, 0.22), 10, c, 1, 6))
	b.add_theme_stylebox_override("pressed", UITheme.box(Color(c.r, c.g, c.b, 0.34), 10, c, 2, 6))
	b.add_theme_stylebox_override("disabled", UITheme.box(Color(1, 1, 1, 0.03), 10, Color(1, 1, 1, 0.10), 1, 6))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(key, c)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.25))


# ================= dial：調音旋鈕 =================

static func _knob_vals(k: Dictionary) -> Array:
	if k.has("vals"):
		return k.vals
	var out := []
	var lo: float = k.lo
	var hi: float = k.hi
	var stp: float = k.step
	var n := int(round((hi - lo) / stp))
	for i in n + 1:
		out.append(snappedf(lo + i * stp, 1e-9))
	return out


func _knob_text(k: Dictionary, real: float) -> String:
	if k.has("names"):
		# 指定了每一格要顯示的字（例如斜率 1/π）
		var vals: Array = k.vals
		var mul: float = PI if String(k.get("unit", "")) == "pi" else 1.0
		for i in vals.size():
			if absf(float(vals[i]) * mul - real) < 1e-9:
				return String(k.names[i])
	if String(k.get("unit", "")) == "pi":
		return TideView.pi_text(real)
	if String(k.get("fmt", "dec")) == "frac":
		return TideView.fr(real)
	return TideView.dec(real)


func _build_dial(st: Dictionary) -> void:
	_prep_panel(st)
	var tv := _tv()
	var cur := {"a": 1.0, "b": 1.0, "c": 0.0, "d": 0.0}
	for key in st.get("fixed", {}):
		cur[key] = float(st.fixed[key])
	_knobs = []
	var card := _info_card(TIDE)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	card.add_child(box)
	dial_fx = _math_label(21, 330, 34, UITheme.TEXT)
	box.add_child(dial_fx)
	dial_sub = _math_label(13, 330, 22, UITheme.TEXT_DIM)
	box.add_child(dial_sub)
	for k in st.knobs:
		var p: String = k.p
		var vals := _knob_vals(k)
		var mul: float = PI if String(k.get("unit", "")) == "pi" else 1.0
		var start_native: float = float(k.get("start", vals[0]))
		var idx := 0
		var best := 1e18
		for i in vals.size():
			var dd := absf(float(vals[i]) - start_native)
			if dd < best:
				best = dd
				idx = i
		cur[p] = float(vals[idx]) * mul
		var col: Color = KNOB_COL[p]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		rank_box.add_child(row)
		var nm := Label.new()
		nm.text = String(k.get("label", KNOB_NAME[p]))
		nm.custom_minimum_size = Vector2(60, 0)
		nm.add_theme_font_size_override("font_size", UITheme.fs(15))
		nm.add_theme_color_override("font_color", col)
		row.add_child(nm)
		var s := UITheme.touch_slider()
		s.min_value = 0
		s.max_value = vals.size() - 1
		s.step = 1
		s.value = idx
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.custom_minimum_size = Vector2(0, 28)
		UITheme.tint_slider(s, col)
		row.add_child(s)
		UITheme.add_step_buttons(s, col)
		var vl := Label.new()
		vl.custom_minimum_size = Vector2(56, 0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.add_theme_font_size_override("font_size", UITheme.fs(15))
		vl.add_theme_color_override("font_color", col)
		row.add_child(vl)
		vl.text = _knob_text(k, float(vals[idx]) * mul)
		var kk: Dictionary = k
		s.value_changed.connect(func(v: float):
			if busy:
				return
			var real := float(vals[int(v)]) * mul
			_tv().cur[p] = real
			vl.text = _knob_text(kk, real)
			MoonView.dragged_ever = true
			Game.of(self).play("blip", 0.8 + 0.03 * v, -18.0)
			_refresh_dial())
		_knobs.append({"p": p, "slider": s})
	_dial_start = cur.duplicate()
	tv.mode = "dial"
	tv.spec = st
	tv.cur = cur
	tv.circ = {}
	tv.task_q = String(st.q)
	tv.matched = false
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if st.get("hide_target", false) and not st.has("dots"):
		_tip("沒有目標可以對：自己判斷旋鈕要調到多少，畫好了按「確定」。")
	elif _knobs.size() < 3:
		_tip("拖動旋鈕（或按 ‹ › 微調），讓你的波和金色的目標重合。")
	_refresh_dial()


func _refresh_dial() -> void:
	if dial_fx == null or not is_instance_valid(dial_fx):
		return
	var st: Dictionary = steps[si]
	var tv := _tv()
	var fn := String(st.get("fn", "sin"))
	var v := String(st.get("var", "x"))
	var c: Dictionary = tv.cur
	if fn == "line":
		dial_fx.text = TideView.ltext(c.a, c.d, String(st.get("slope_txt", "")), _slope_name(st, c.a))
		dial_sub.text = "斜率 %s　y 截距 %s" % [_slope_name(st, c.a), TideView.dec(c.d)]
	else:
		dial_fx.text = TideView.ftext(fn, c.a, c.b, c.c, c.d, v)
		dial_sub.text = TideView.decomp(fn, c.a, c.b, c.c, c.d)
	tv.matched = _dial_match(st, c)
	tv.queue_redraw()


## 直線斜率旋鈕的顯示文字
func _slope_name(st: Dictionary, m: float) -> String:
	for k in st.knobs:
		if String(k.p) == "a":
			return _knob_text(k, m)
	return TideView.dec(m)


func _dial_match(st: Dictionary, c: Dictionary) -> bool:
	var fn := String(st.get("fn", "sin"))
	if fn == "line":
		var tl: Dictionary = st.target
		return absf(float(c.a) - float(tl.a)) < 1e-9 and absf(float(c.d) - float(tl.d)) < 1e-9
	if st.has("dots"):
		var u := 1.0 if String(st.view.get("xu", "pi")) == "num" else PI
		var cv := {"f": fn, "a": c.a, "b": c.b, "c": c.c, "d": c.d}
		for dt in st.dots:
			if absf(TideView.fv(cv, float(dt[0]) * u) - float(dt[1])) > 1e-6:
				return false
		return true
	var tg: Dictionary = st.target
	if st.get("strict", false):
		for key in ["a", "b", "c", "d"]:
			if absf(float(c[key]) - float(tg[key])) > 1e-6:
				return false
		return true
	return TideView.same_curve({"f": fn, "a": c.a, "b": c.b, "c": c.c, "d": c.d},
		{"f": fn, "a": tg.a, "b": tg.b, "c": tg.c, "d": tg.d})


func _dial_submit() -> void:
	var st: Dictionary = steps[si]
	var tv := _tv()
	if _dial_match(st, tv.cur):
		Game.of(self).sfx("correct")
		tv.burst_center()
		var tg: Dictionary = st.get("target", tv.cur)
		var keep := {}
		if not st.get("no_keep", false):
			var cv := {"f": String(st.get("fn", "sin")), "a": tg.a, "b": tg.b, "c": tg.c, "d": tg.d,
				"col": TIDE, "label": TideView.ftext(String(st.get("fn", "sin")), tg.a, tg.b, tg.c, tg.d, String(st.get("var", "x")))}
			if String(st.get("fn", "")) == "line":
				cv = {"f": "line", "m": tg.a, "k": tg.d, "col": UITheme.PINK_LIGHT, "label": String(st.get("line_label", ""))}
			keep = st.view.duplicate()
			keep["kind"] = "tide"
			keep["curves"] = [cv]
			keep["aid"] = true
			if st.has("dots"):
				keep["pts"] = st.dots
			keep.merge(st.get("keep", {}), true)
		_interact_done(st, keep)
		return
	var untouched := true
	for key in ["a", "b", "c", "d"]:
		if absf(float(tv.cur[key]) - float(_dial_start[key])) > 1e-9:
			untouched = false
	if untouched:
		_wrong(st, "旋鈕還沒有動喔！拖動滑桿，看看波形怎麼變。")
		return
	var msgs := _dial_diag(st, tv.cur)
	var msg := "還沒有對上。"
	if not msgs.is_empty():
		msg += "".join(msgs.slice(0, 2))
	_wrong(st, msg + "提示：" + String(st.nudge))


## 目前的波和目標差在哪裡（只檢查有旋鈕的參數）
func _dial_diag(st: Dictionary, c: Dictionary) -> Array:
	var out := []
	var tg: Dictionary = st.get("target", {})
	if tg.is_empty():
		return ["資料點還沒有全部穿過。"]
	var active := {}
	for k in st.knobs:
		active[k.p] = true
	var fn := String(st.get("fn", "sin"))
	if fn == "line":
		if absf(float(c.a) - float(tg.a)) > 1e-9:
			out.append("斜率不對：直線每往右走一格，要升高多少？")
		if active.has("d") and absf(float(c.d) - float(tg.d)) > 1e-9:
			out.append("高度不對：直線和 y 軸交在哪裡？")
		return out
	if active.has("a"):
		if absf(absf(float(c.a)) - absf(float(tg.a))) > 1e-6:
			out.append("高低（振幅）還不對：你的波比目標%s。" % ("矮" if absf(float(c.a)) < absf(float(tg.a)) else "高"))
		elif float(c.a) * float(tg.a) < 0.0:
			out.append("波的上下顛倒了：目標在 x 軸的另一邊先出發。")
	if active.has("b") and absf(absf(float(c.b)) - absf(float(tg.b))) > 1e-6:
		out.append("快慢（週期）還不對：你的波比目標%s。" % ("慢（週期太長）" if absf(float(c.b)) < absf(float(tg.b)) else "快（週期太短）"))
	if active.has("c") or active.has("b"):
		if absf(absf(float(c.b)) - absf(float(tg.b))) < 1e-6 and active.has("c"):
			var per: float = (PI if fn == "tan" else TAU) / absf(float(c.b))
			var sc := -float(c.c) / float(c.b)
			var st_ := -float(tg.c) / float(tg.b)
			var dl := fposmod(sc - st_ + per / 2.0, per) - per / 2.0
			if absf(dl) > 1e-6:
				out.append("左右的位置還不對：你的波比目標%s。" % ("偏右" if dl > 0.0 else "偏左"))
	if active.has("d") and absf(float(c.d) - float(tg.d)) > 1e-6:
		out.append("水位（中線）還不對：你的中線比目標%s。" % ("低" if float(c.d) < float(tg.d) else "高"))
	return out


# ================= chain：變換鏈 =================

static func chain_apply(s: Dictionary, op: Dictionary) -> Dictionary:
	var out := s.duplicate()
	var v: float = op.v
	match String(op.t):
		"v":
			out.A = float(s.A) * v
			out.D = float(s.D) * v
		"h":
			out.B = float(s.B) / v
			out.H = float(s.H) * v
		"x":
			out.H = float(s.H) + v
		"y":
			out.D = float(s.D) + v
	return out


static func chain_state(ops: Array) -> Dictionary:
	var s := {"A": 1.0, "B": 1.0, "H": 0.0, "D": 0.0}
	for op in ops:
		s = chain_apply(s, op)
	return s


## 狀態 → 曲線的 a、b、c、d（H 的單位是 π）
static func chain_curve(fn: String, s: Dictionary) -> Dictionary:
	return {"f": fn, "a": s.A, "b": s.B, "c": -float(s.B) * float(s.H) * PI, "d": s.D}


## 零件的短名字（放在算式卡裡，不佔空間）
static func op_short(op: Dictionary) -> String:
	var v: float = op.v
	match String(op.t):
		"v":
			return "上下翻轉" if absf(v + 1.0) < 1e-9 else "鉛直×%s" % TideView.fr(v)
		"h":
			return "水平×%s" % TideView.fr(v)
		"x":
			return ("右移%s" if v > 0.0 else "左移%s") % TideView.pi_text(absf(v) * PI)
	return ("上移%s" if v > 0.0 else "下移%s") % TideView.fr(absf(v))


static func op_text(op: Dictionary) -> String:
	var v: float = op.v
	match String(op.t):
		"v":
			if absf(v + 1.0) < 1e-9:
				return "上下翻轉"
			return ("鉛直拉伸 ×%s" if absf(v) > 1.0 else "鉛直壓縮 ×%s") % TideView.fr(v)
		"h":
			return ("水平拉伸 ×%s" if v > 1.0 else "水平壓縮 ×%s") % TideView.fr(v)
		"x":
			return ("右移 %s" if v > 0.0 else "左移 %s") % TideView.pi_text(absf(v) * PI)
	return ("上移 %s" if v > 0.0 else "下移 %s") % TideView.fr(absf(v))


func _build_chain(st: Dictionary) -> void:
	_prep_panel(st)
	var tv := _tv()
	var card := _info_card(TIDE)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	card.add_child(box)
	chain_fx = _math_label(21, 330, 30, UITheme.TEXT)
	box.add_child(chain_fx)
	chain_list = _math_label(13, 330, 22, UITheme.TEXT_DIM)
	box.add_child(chain_list)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	rank_box.add_child(grid)
	var ops: Array = st.ops
	for i in ops.size():
		var op: Dictionary = ops[i]
		var b := Button.new()
		b.text = op_text(op)
		b.custom_minimum_size = Vector2(0, 32)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_tint_button(b, OP_COL[String(op.t)], 16)
		var idx := i
		b.pressed.connect(func():
			_chain_add(idx))
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
			_chain_back(kind))
		row.add_child(b2)
	tv.mode = "chain"
	tv.spec = st
	tv.ch_ops = []
	var s0 := chain_state([])
	tv.ch_from = s0
	tv.ch_to = s0
	tv.ch_k = 1.0
	tv.circ = {}
	tv.task_q = String(st.q)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_chain()


func _chain_add(i: int) -> void:
	if busy:
		return
	var st: Dictionary = steps[si]
	var tv := _tv()
	if tv.ch_ops.size() >= int(st.get("max", 6)):
		_hint("最多只能用 %d 個零件。按「退一步」再換一個吧。" % int(st.get("max", 6)), "info")
		return
	MoonView.dragged_ever = true
	tv.ch_from = tv.ch_to
	tv.ch_ops.append(st.ops[i])
	tv.ch_to = chain_state(tv.ch_ops)
	tv.ch_k = 0.0
	Game.of(self).play("blip", 1.0 + 0.05 * tv.ch_ops.size(), -12.0)
	_refresh_chain()


func _chain_back(kind: int) -> void:
	if busy:
		return
	var tv := _tv()
	if tv.ch_ops.is_empty():
		return
	tv.ch_from = tv.ch_to
	if kind == 0:
		tv.ch_ops.pop_back()
	else:
		tv.ch_ops = []
	tv.ch_to = chain_state(tv.ch_ops)
	tv.ch_k = 0.0
	Game.of(self).play("blip", 0.8, -14.0)
	_refresh_chain()


func _refresh_chain() -> void:
	if chain_fx == null or not is_instance_valid(chain_fx):
		return
	var st: Dictionary = steps[si]
	var tv := _tv()
	var fn := String(st.get("fn", "sin"))
	var cv := chain_curve(fn, tv.ch_to)
	chain_fx.text = TideView.ftext(fn, cv.a, cv.b, cv.c, cv.d, "x")
	var tg: Dictionary = st.target
	tv.matched = not tv.ch_ops.is_empty() and TideView.same_curve(cv, {"f": fn, "a": tg.a, "b": tg.b, "c": tg.c, "d": tg.d})
	if tv.ch_ops.is_empty():
		chain_list.text = "還沒有零件，從 y = %s x 開始！" % fn
	else:
		var names := []
		for i in tv.ch_ops.size():
			names.append("%s%s" % [["①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧"][mini(i, 7)], op_short(tv.ch_ops[i])])
		chain_list.text = " ".join(names)
	tv.queue_redraw()


func _chain_submit() -> void:
	var st: Dictionary = steps[si]
	var tv := _tv()
	var fn := String(st.get("fn", "sin"))
	var tg: Dictionary = st.target
	var got := chain_curve(fn, tv.ch_to)
	var want := {"f": fn, "a": tg.a, "b": tg.b, "c": tg.c, "d": tg.d}
	if tv.ch_ops.size() > 0 and TideView.same_curve(got, want):
		Game.of(self).sfx("correct")
		tv.burst_center()
		var keep: Dictionary = st.view.duplicate()
		keep["kind"] = "tide"
		keep["curves"] = [{"f": fn, "a": tg.a, "b": tg.b, "c": tg.c, "d": tg.d, "col": TIDE,
			"label": TideView.ftext(fn, tg.a, tg.b, tg.c, tg.d, "x")}]
		keep["aid"] = true
		_interact_done(st, keep)
		return
	if tv.ch_ops.is_empty():
		_wrong(st, "還沒有放任何零件喔！點下面的零件，一個一個接上去。")
		return
	var msgs := []
	var same_a := absf(float(got.a) - float(want.a)) < 1e-6
	var same_b := absf(float(got.b) - float(want.b)) < 1e-6
	var same_c := absf(float(got.c) - float(want.c)) < 1e-6
	var same_d := absf(float(got.d) - float(want.d)) < 1e-6
	if not same_a:
		msgs.append("高低（振幅）還不對：你的波是 %s 倍，目標是 %s 倍。" % [TideView.fr(absf(float(got.a))), TideView.fr(absf(float(want.a)))])
		if absf(float(got.a)) == absf(float(want.a)):
			msgs[0] = "波的上下顛倒了。"
	if not same_b:
		msgs.append("週期還不對：你的波週期是 %s，目標是 %s。" % [TideView.pi_text(TAU / absf(float(got.b))), TideView.pi_text(TAU / absf(float(want.b)))])
	if same_a and same_b and same_d and not same_c:
		msgs.append("水平平移要放在水平伸縮「之後」，平移量才不會被一起壓縮。")
	elif same_a and same_b and same_c and not same_d:
		msgs.append("上下平移要放在鉛直伸縮「之後」，不然高度會被一起拉伸。")
	elif same_a and same_b and not same_c and not same_d:
		msgs.append("先伸縮、再平移：伸縮完才能量平移的距離。")
	var trap := (not msgs.is_empty()) and (String(msgs[0]).begins_with("水平平移") or String(msgs[0]).begins_with("上下平移") or String(msgs[0]).begins_with("先伸縮"))
	_wrong(st, "".join(msgs.slice(0, 1)) + ("" if trap else "提示：" + String(st.nudge)))


# ================= ride：摩天輪 =================

func _build_ride(st: Dictionary) -> void:
	_prep_panel(st)
	var tv := _tv()
	var card := _info_card(TIDE)
	ride_info = _math_label(19, 330, 56, UITheme.TEXT)
	card.add_child(ride_info)
	var snap: float = float(st.get("snap", 0.5))
	var n := int(round(float(st.T) / snap))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	rank_box.add_child(row)
	var nm := Label.new()
	nm.text = "時間 t"
	nm.custom_minimum_size = Vector2(60, 0)
	nm.add_theme_font_size_override("font_size", UITheme.fs(15))
	nm.add_theme_color_override("font_color", UITheme.CYAN)
	row.add_child(nm)
	ride_slider = UITheme.touch_slider()
	ride_slider.min_value = 0
	ride_slider.max_value = n
	ride_slider.step = 1
	ride_slider.value = 0
	ride_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ride_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ride_slider.custom_minimum_size = Vector2(0, 28)
	UITheme.tint_slider(ride_slider, UITheme.CYAN)
	row.add_child(ride_slider)
	UITheme.add_step_buttons(ride_slider, UITheme.CYAN)
	ride_slider.value_changed.connect(func(v: float):
		if busy:
			return
		var t2 := _tv()
		t2.play = false
		t2.ride_t = v * snap
		MoonView.dragged_ever = true
		Game.of(self).play("blip", 0.9 + 0.02 * v, -18.0)
		_refresh_ride())
	ride_btn = Button.new()
	ride_btn.text = "自動播放"
	ride_btn.custom_minimum_size = Vector2(0, 38)
	_tint_button(ride_btn, UITheme.CYAN, 16)
	ride_btn.pressed.connect(func():
		var t3 := _tv()
		if t3.play:
			t3.play = false
			t3.ride_t = clampf(snappedf(t3.ride_t, snap), 0.0, float(st.T))
		else:
			if t3.ride_t >= float(st.T) - 1e-6:
				t3.ride_t = 0.0
				t3.ride_max = 0.0
			t3.play = true
		MoonView.dragged_ever = true
		_refresh_ride())
	rank_box.add_child(ride_btn)
	ride_btn.visible = false          # 不需要自動播放：學生自己拖時間找答案
	_tip("拖動時間（或直接拖右邊的圖），找到了就按「確定」。")
	tv.mode = "ride"
	tv.spec = st
	tv.ride_t = 0.0
	tv.ride_show = 0.0
	tv.ride_max = 0.0
	tv.play = false
	tv.found = []
	tv.circ = {}
	tv.task_q = String(st.q)
	tv.mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_ride()


func _refresh_ride() -> void:
	if ride_info == null or not is_instance_valid(ride_info):
		return
	var st: Dictionary = steps[si]
	var tv := _tv()
	var snap: float = float(st.get("snap", 0.5))
	if ride_slider != null and is_instance_valid(ride_slider):
		ride_slider.set_value_no_signal(roundf(tv.ride_t / snap))
	if ride_btn != null and is_instance_valid(ride_btn):
		ride_btn.text = "暫停" if tv.play else "自動播放"
	var h := TideView.ride_height(st, tv.ride_t)
	var n: int = st.targets.size()
	var found := "　已找到 %d／%d" % [tv.found.size(), n] if n > 1 else ""
	ride_info.text = "t = %s %s\n高度 = %s %s%s" % [TideView.dec(snappedf(tv.ride_t, 0.01)), String(st.get("unit_t", "分")),
		TideView.dec(snappedf(h, 0.1)), String(st.get("unit_h", "公尺")), found]


func _ride_submit() -> void:
	var st: Dictionary = steps[si]
	var tv := _tv()
	var snap: float = float(st.get("snap", 0.5))
	if tv.play:
		tv.play = false
		tv.ride_t = clampf(snappedf(tv.ride_t, snap), 0.0, float(st.T))
		_refresh_ride()
	var t := snappedf(tv.ride_t, snap)
	var hit := -1.0
	for tg in st.targets:
		if absf(float(tg) - t) < snap / 2.0 + 1e-6:
			hit = float(tg)
	var h := TideView.ride_height(st, t)
	if hit < 0.0:
		var msg := "這個時刻不對喔（t = %s，高度 %s）。" % [TideView.dec(t), TideView.dec(snappedf(h, 0.1))]
		if st.has("level") and absf(h - float(st.level)) < 0.06:
			msg = "高度對了，不過題目要的是另一個時刻！"
		elif st.has("level"):
			msg += "目標高度是 %s。" % TideView.dec(float(st.level))
		_wrong(st, msg + "提示：" + String(st.nudge))
		return
	if tv.found.has(hit):
		_hint("這個時刻已經找到了，再找找看別的！", "info")
		return
	tv.found.append(hit)
	Game.of(self).sfx("correct")
	tv.burst_center()
	_refresh_ride()
	if tv.found.size() < st.targets.size():
		_hint("✓ 找到一個！還有 %d 個。" % (st.targets.size() - tv.found.size()), "good")
		return
	var keep := {}
	if st.get("keep", true):
		var cvr := TideView.ride_curve(st)
		cvr["col"] = TIDE
		cvr["label"] = TideView.ftext("sin", cvr.a, cvr.b, cvr.c, cvr.d, "t")
		keep = {"kind": "tide", "curves": [cvr], "x": [0.0, float(st.T)], "xu": "num",
			"y": [0.0, float(st.cy) + float(st.r) + 4.0], "xt": TideView.ride_xt(float(st.T)),
			"yt": 10.0 if float(st.r) >= 15.0 else 5.0, "aid": true, "xl": "t（%s）" % String(st.get("unit_t", "分"))}
		if st.has("level"):
			keep["hlines"] = [[float(st.level), "", UITheme.GOLD]]
		var pts := []
		for tg in st.targets:
			pts.append([float(tg), TideView.ride_height(st, float(tg))])
		keep["pts"] = pts
	_interact_done(st, keep)


# ================= hunt：找交點 =================

func _build_hunt(st: Dictionary) -> void:
	_prep_panel(st)
	var tv := _tv()
	var card := _info_card(TIDE)
	hunt_info = _math_label(19, 330, 40, UITheme.TEXT)
	card.add_child(hunt_info)
	_tip("直接點圖上兩條曲線相交的地方。找齊了就按「確定」。")
	var u := 1.0 if String(st.view.get("xu", "pi")) == "num" else PI
	tv.hunt_pts = TideView.intersections(st.curves[0], st.curves[1], float(st.view.x[0]) * u, float(st.view.x[1]) * u)
	tv.found = []
	tv.flashes = []
	tv.mode = "hunt"
	tv.spec = st
	tv.circ = {}
	tv.task_q = String(st.q)
	tv.mouse_filter = Control.MOUSE_FILTER_STOP
	if st.has("count") and int(st.count) != tv.hunt_pts.size():
		push_warning("hunt 步驟「%s」的 count = %d，但算出來有 %d 個交點" % [st.name, int(st.count), tv.hunt_pts.size()])
	_refresh_hunt()


func _refresh_hunt() -> void:
	if hunt_info == null or not is_instance_valid(hunt_info):
		return
	var tv := _tv()
	hunt_info.text = "已找到 %d 個交點" % tv.found.size()


func _hunt_submit() -> void:
	var st: Dictionary = steps[si]
	var tv := _tv()
	if tv.found.is_empty():
		_wrong(st, "還沒有點任何交點喔！直接點圖上兩條曲線相交的地方。")
		return
	if tv.found.size() < tv.hunt_pts.size():
		_wrong(st, "還沒找齊：目前找到 %d 個，圖上還有交點沒點到。提示：%s" % [tv.found.size(), String(st.nudge)])
		return
	Game.of(self).sfx("correct")
	tv.burst_center()
	var keep: Dictionary = st.view.duplicate()
	keep["kind"] = "tide"
	keep["curves"] = st.curves
	var pts := []
	var u := 1.0 if String(st.view.get("xu", "pi")) == "num" else PI
	for p in tv.hunt_pts:
		pts.append([p.x / u, p.y])
	keep["pts"] = pts
	_interact_done(st, keep)


# ================= 速算 =================

func _speed_gen(kind: String, n: int) -> Array:
	if kind != "tide":
		return super(kind, n)
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 2000:
		guard += 1
		var pb := _gen_tide()
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		out.append(pb)
	return out


static func _gen_tide() -> Dictionary:
	var fn: String = ["sin", "cos"].pick_random()
	var bs := [[1, 1], [2, 1], [3, 1], [4, 1], [1, 2], [1, 3], [2, 3], [3, 2], [3, 4]]
	var b: Array = bs.pick_random()
	var a: int = [1, 2, 3, 4, 5, -1, -2, -3].pick_random()
	var d: int = randi_range(-3, 4)
	# c 只用最簡分數、−π < c < π（不會出現 −2π 這種等於沒平移的寫法）
	var cs := [[1, 6], [1, 4], [1, 3], [1, 2], [2, 3], [3, 4], [5, 6]]
	var cp: Array = cs.pick_random()
	var cn: int = int(cp[0]) * (1 if randf() < 0.5 else -1)
	var cd: int = int(cp[1])
	var bv := float(b[0]) / float(b[1])
	var cv := PI * float(cn) / float(cd)
	var eq := TideView.ftext(fn, float(a), bv, cv, float(d), "x")
	match randi() % 4:
		0:
			# 週期 = 2π ÷ b = (2·bd/bn)π
			return {"eq": eq + " 的週期", "q": "求週期。", "template": "週期 = [0]π", "ans": _frac(2 * int(b[1]), int(b[0])),
				"nudge": "2π ÷ x 的係數 b；平移和高低都不影響週期。", "tag": BankG4.T_FREQ}
		1:
			# 向右平移量 = −c/b（π 的倍數）
			# 寫出「沒有平移」的那一條（同樣的 a、b、d），比較清楚是跟誰比
			var base := TideView.ftext(fn, float(a), bv, 0.0, float(d), "x")
			return {"eq": eq + "\n的圖形，比 " + base + " 的圖形向右平移多少？",
				"q": "平移量（向右為正、向左為負）。", "template": "平移 = [0]π",
				"ans": _frac(-cn * int(b[1]), cd * int(b[0])),
				"nudge": "先把括號提出 b：sin(bx + c) = sin b(x + c/b)，平移量是 −c/b。", "tag": BankG4.T_SHIFT}
		2:
			return {"eq": eq + " 的最大值", "q": "求最大值。", "template": "最大值 = [0]", "ans": str(d + absi(a)),
				"nudge": "最大值 = d + |a|。平移、週期都不影響。", "tag": BankG4.T_AMP}
	return {"eq": eq + " 的最小值", "q": "求最小值。", "template": "最小值 = [0]", "ans": str(d - absi(a)),
		"nudge": "最小值 = d − |a|。", "tag": BankG4.T_AMP}


# ================= 畫面 =================

class TideView extends MoonView:
	signal tide_changed
	signal tap_missed

	var mode := ""                 # "dial"、"chain"、"ride"、"hunt"（空字串：沒有互動，只畫下方的示意圖）
	var spec := {}                 # 目前這一步的設定
	var cur := {"a": 1.0, "b": 1.0, "c": 0.0, "d": 0.0}
	var matched := false
	# chain
	var ch_ops: Array = []
	var ch_from := {"A": 1.0, "B": 1.0, "H": 0.0, "D": 0.0}
	var ch_to := {"A": 1.0, "B": 1.0, "H": 0.0, "D": 0.0}
	var ch_k := 1.0
	# ride
	var ride_t := 0.0
	var ride_show := 0.0
	var ride_max := 0.0
	var play := false
	var _ride_drag := false
	# ride、hunt 共用：已找到的（ride：目標時刻；hunt：交點的編號）
	var found: Array = []
	var hunt_pts: Array = []
	var flashes: Array = []

	func setup(round: Dictionary) -> void:
		super(round)
		mode = ""
		spec = {}
		matched = false
		play = false
		found = []
		hunt_pts = []
		flashes = []
		ch_ops = []

	# ---------- 數學小工具（關卡檔也會用） ----------

	## 有理數：回傳 [分子, 分母]，不是（分母 ≤ 24）就回傳空陣列
	static func rat(v: float) -> Array:
		for dn in range(1, 25):
			var n := v * dn
			if absf(n - roundf(n)) < 1e-7:
				return [int(roundf(n)), dn]
		return []

	static func dec(v: float) -> String:
		return UITheme.num(v, 2).replace("-", "−")

	## 整數、分數（−3/2）；不是有理數就寫小數
	static func fr(v: float) -> String:
		var q := rat(v)
		if q.is_empty():
			return dec(v)
		var n: int = q[0]
		var dn: int = q[1]
		var s := str(absi(n)) if dn == 1 else "%d/%d" % [absi(n), dn]
		return ("−" if n < 0 else "") + s

	## π 的倍數：π/6、−3π/4、2π；不是 π 的倍數就寫小數
	static func pi_text(v: float) -> String:
		var q := rat(v / PI)
		if q.is_empty():
			return dec(v)
		var n: int = q[0]
		var dn: int = q[1]
		if n == 0:
			return "0"
		var core := "π" if absi(n) == 1 else "%dπ" % absi(n)
		return ("−" if n < 0 else "") + core + ("" if dn == 1 else "/%d" % dn)

	## y = a·sin(b·x + c) + d 的文字（x 可以換成 t）
	static func ftext(fn: String, a: float, b: float, c: float, d: float, v: String) -> String:
		var co := "" if absf(a - 1.0) < 1e-9 else ("−" if absf(a + 1.0) < 1e-9 else (dec(a) + " "))
		var bt := ""
		var qb := rat(b)
		if absf(b - 1.0) < 1e-9:
			bt = v
		elif not qb.is_empty():
			var n: int = qb[0]
			var dn: int = qb[1]
			var nn := "" if absi(n) == 1 else str(absi(n))
			bt = ("−" if n < 0 else "") + (nn + v if dn == 1 else (nn + v + "/%d" % dn))
		else:
			var qp := rat(b / PI)
			if qp.is_empty():
				bt = dec(b) + v
			else:
				var n2: int = qp[0]
				var d2: int = qp[1]
				var nn2 := "" if absi(n2) == 1 else str(absi(n2))
				bt = ("−" if n2 < 0 else "") + nn2 + "π" + v + ("" if d2 == 1 else "/%d" % d2)
		var arg := bt
		if absf(c) > 1e-9:
			arg += (" + " if c > 0.0 else " − ") + pi_text(absf(c))
		var s := "y = %s%s(%s)" % [co, fn, arg]
		if absf(c) < 1e-9 and not arg.contains("/"):
			s = "y = %s%s %s" % [co, fn, arg]       # 沒有平移：sin 2x 不用括號
		if absf(d) > 1e-9:
			s += (" + " if d > 0.0 else " − ") + dec(absf(d))
		return s

	## 直線 y = mx + k 的文字；mt 是斜率的寫法（例如 1/π）
	static func ltext(m: float, k: float, _unused: String, mt: String) -> String:
		var s := "y = "
		if absf(m) < 1e-12:
			return s + dec(k)
		if mt == "1":
			s += "x"
		elif mt == "−1":
			s += "−x"
		elif mt.contains("/"):
			var neg := mt.begins_with("−")
			var core := mt.substr(1) if neg else mt
			var parts := core.split("/")
			var num := "x" if parts[0] == "1" else parts[0] + "x"
			s += ("−" if neg else "") + num + "/" + parts[1]
		else:
			s += mt + "x"
		if absf(k) > 1e-12:
			s += (" + " if k > 0.0 else " − ") + dec(absf(k))
		return s

	## 「振幅、週期、平移、中線」四個數字（一行）
	static func decomp(fn: String, a: float, b: float, c: float, d: float) -> String:
		var per := (PI if fn == "tan" else TAU) / absf(b)
		var sh := -c / b
		var st := "平移 0"
		if absf(sh) > 1e-9:
			st = ("向右 %s" if sh > 0.0 else "向左 %s") % pi_text(absf(sh))
		if fn == "tan":
			return "週期 %s　%s　中線 %s" % [pi_text(per), st, dec(d)]
		return "振幅 %s　週期 %s　%s　中線 %s" % [fr(absf(a)), pi_text(per), st, dec(d)]

	static func fv(c: Dictionary, x: float) -> float:
		var a: float = c.get("a", 1.0)
		var b: float = c.get("b", 1.0)
		var cc: float = c.get("c", 0.0)
		var d: float = c.get("d", 0.0)
		match String(c.get("f", "sin")):
			"sin":
				return a * sin(b * x + cc) + d
			"cos":
				return a * cos(b * x + cc) + d
			"tan":
				if absf(cos(b * x + cc)) < 1e-3:
					return NAN
				return a * tan(b * x + cc) + d
			"line":
				return float(c.get("m", 0.0)) * x + float(c.get("k", 0.0))
		return NAN

	## 兩條曲線（只看 sin、cos）是不是同一條
	static func same_curve(c1: Dictionary, c2: Dictionary) -> bool:
		for i in 97:
			var x := -2.0 * PI + 4.0 * PI * i / 96.0 + 0.0137
			if absf(fv(c1, x) - fv(c2, x)) > 1e-6:
				return false
		return true

	## 兩條曲線在 [xa, xb]（實際的 x）的所有交點：[Vector2(x, y), …]
	## 差剛好是 0 的取樣點（例如 x = 0）也算交點；相鄰兩點異號就用二分法找
	static func intersections(c1: Dictionary, c2: Dictionary, xa: float, xb: float) -> Array:
		var out := []
		var n := 6000
		var xs := PackedFloat64Array()
		var ds := PackedFloat64Array()
		for i in n + 1:
			var x := lerpf(xa, xb, float(i) / n)
			xs.append(x)
			ds.append(fv(c1, x) - fv(c2, x))
		for i in n + 1:
			if is_nan(ds[i]):
				continue
			if absf(ds[i]) < 1e-9:
				out.append(Vector2(xs[i], fv(c1, xs[i])))
				continue
			if i == n or is_nan(ds[i + 1]) or absf(ds[i + 1]) < 1e-9:
				continue
			if ds[i] * ds[i + 1] < 0.0:
				var lo := xs[i]
				var hi := xs[i + 1]
				var flo := ds[i]
				for k in 60:
					var mid := (lo + hi) / 2.0
					var fm := fv(c1, mid) - fv(c2, mid)
					if flo * fm <= 0.0:
						hi = mid
					else:
						lo = mid
						flo = fm
				var xr := (lo + hi) / 2.0
				out.append(Vector2(xr, fv(c1, xr)))
		return out

	static func ride_curve(st: Dictionary) -> Dictionary:
		var w := TAU / float(st.T)
		return {"f": "sin", "a": float(st.r), "b": w, "c": float(st.get("phi", -PI / 2.0)), "d": float(st.cy)}

	static func ride_height(st: Dictionary, t: float) -> float:
		return fv(ride_curve(st), t)

	static func ride_xt(T: float) -> float:
		return maxf(1.0, roundf(T / 6.0))

	static func _unit(g: Dictionary) -> float:
		return 1.0 if String(g.get("xu", "pi")) == "num" else PI

	# ---------- 版面 ----------

	func _graph_on() -> bool:
		if mode != "":
			return false
		return super()

	func _bottom_limit() -> float:
		if mode != "":
			return size.y - 330.0
		return super()

	func _process(delta: float) -> void:
		if mode == "chain" and ch_k < 1.0:
			ch_k = minf(1.0, ch_k + delta / 0.5)
		if mode == "ride":
			if play:
				var T: float = float(spec.T)
				ride_t = minf(T, ride_t + delta * T / 7.0)
				if ride_t >= T - 1e-6:
					play = false
				tide_changed.emit()
			ride_show = lerpf(ride_show, ride_t, 1.0 - exp(-14.0 * delta))
			ride_max = maxf(ride_max, ride_show)
		flashes = flashes.filter(func(f): return t - float(f.t) < 0.9)
		super(delta)

	# ---------- 輸入 ----------

	func _gui_input(e: InputEvent) -> void:
		if mode == "hunt":
			if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
				_hunt_tap(e.position)
				accept_event()
			return
		if mode == "ride":
			var ar: Rect2 = _ride_geo(_spin_rect()).area
			if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
				_ride_drag = e.pressed and ar.grow(14.0).has_point(e.position)
				if _ride_drag:
					_ride_scrub(e.position.x, ar)
					accept_event()
			elif e is InputEventMouseMotion and _ride_drag:
				_ride_scrub(e.position.x, ar)
				accept_event()
			return
		super(e)

	func _ride_scrub(x: float, ar: Rect2) -> void:
		var T: float = float(spec.T)
		var snap: float = float(spec.get("snap", 0.5))
		var nt := clampf(snappedf((x - ar.position.x) / ar.size.x * T, snap), 0.0, T)
		if not is_equal_approx(nt, ride_t):
			ride_t = nt
			play = false
			dragged_ever = true
			tide_changed.emit()

	func _hunt_tap(pos: Vector2) -> void:
		var g: Dictionary = spec.view
		var area := _plot_area(_spin_rect(), g, true)
		if not area.grow(8.0).has_point(pos):
			return
		var u := _unit(g)
		var best := -1
		var bd := 1e9
		var bp := Vector2.ZERO
		for i in hunt_pts.size():
			var p: Vector2 = _map(area, g, hunt_pts[i].x / u, hunt_pts[i].y)
			var dd := p.distance_to(pos)
			if dd < bd:
				bd = dd
				best = i
				bp = p
		if best >= 0 and bd <= 26.0:
			if not found.has(best):
				found.append(best)
				flashes.append({"pos": bp, "t": t, "ok": true})
				_burst(bp, UITheme.GOLD, 20)
				tide_changed.emit()
			return
		flashes.append({"pos": pos, "t": t, "ok": false})
		tap_missed.emit()

	# ---------- 背景：夜裡的海，水面隨潮汐起伏 ----------

	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("120f35"), Color("120f35"), Color("07192e"), Color("07192e")]))
		var mc := Vector2(w - 70, 70)
		UITheme.dot(self, mc, 60.0, Color(0.85, 0.82, 1.0, 0.035))
		UITheme.dot(self, mc, 34.0, Color(0.85, 0.82, 1.0, 0.06))
		UITheme.dot(self, mc, 22.0, Color(0.95, 0.93, 1.0, 0.10))
		for i in 30:
			var p := Vector2(fposmod(i * 0.618, 1.0) * w, fposmod(i * 0.377, 1.0) * h * 0.7)
			var a := 0.10 + 0.12 * sin(t * (0.8 + fposmod(i * 0.29, 1.0)) + i)
			UITheme.dot(self, p, 1.0 + fposmod(i * 0.41, 1.0) * 1.2, Color(0.9, 0.88, 1.0, maxf(0.0, a)))
		# 潮汐：整片水面慢慢漲落，上面疊著三層波紋
		var tide := 8.0 * sin(t * 0.35)
		for k in 3:
			var yy := h - 20.0 - 15.0 * k + tide * (1.0 - 0.25 * k)
			var pts := PackedVector2Array()
			for i in 33:
				var x := w * i / 32.0
				pts.append(Vector2(x, yy + 3.0 * sin(x * 0.02 + t * (0.7 + 0.2 * k) + k * 1.7)))
			var fill := PackedVector2Array(pts)
			fill.append(Vector2(w, h))
			fill.append(Vector2(0, h))
			draw_colored_polygon(fill, Color(0.45, 0.4, 1.0, 0.035 + 0.01 * k))
			draw_polyline(pts, Color(0.75, 0.7, 1.0, 0.10), 1.2, true)
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	# ---------- 繪圖 ----------

	func _draw() -> void:
		super()
		if mode != "" and kind == "forge" and intro < 0.0:
			_draw_mode(get_theme_default_font())

	func _draw_circ(font: Font, rect: Rect2) -> void:
		if String(circ.get("kind", "")) == "fig":
			draw_style_box(UITheme.boxc(Color(0.03, 0.06, 0.14, 0.55), 12, Color(0.78, 0.6, 1.0, 0.22), 1, 0), rect.grow(6))
			_draw_fig(font, rect, circ)
			return
		if String(circ.get("kind", "")) != "tide":
			super(font, rect)
			return
		draw_style_box(UITheme.boxc(Color(0.03, 0.06, 0.14, 0.55), 12, Color(0.78, 0.6, 1.0, 0.22), 1, 0), rect.grow(6))
		_plot(font, rect, circ, false)

	## 幾何示意圖（kind = "fig"）：
	##   pts {名稱: [x, y]}、segs [[P, Q, 標籤]]、right [[頂點, P, Q]]（直角記號）、
	##   angles [[頂點, P, Q, 標籤]]（角的小弧）、carcs [[圓心, P, Q]]（圓弧）、axes（畫坐標軸）、hide [不標名字的點]
	func _draw_fig(font: Font, rect: Rect2, f: Dictionary) -> void:
		var pts: Dictionary = f.get("pts", {})
		if pts.is_empty():
			return
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for k in pts:
			var v := Vector2(float(pts[k][0]), float(pts[k][1]))
			lo = Vector2(minf(lo.x, v.x), minf(lo.y, v.y))
			hi = Vector2(maxf(hi.x, v.x), maxf(hi.y, v.y))
		var span := (hi - lo)
		span = Vector2(maxf(span.x, 1e-6), maxf(span.y, 1e-6))
		var pad := 26.0
		# 下緣多留一點：光靈的對話泡泡在左下角，不要蓋到圖
		var area := Rect2(rect.position, rect.size - Vector2(0, 30))
		var sc := minf((area.size.x - 2.0 * pad) / span.x, (area.size.y - 2.0 * pad) / span.y)
		var mid := (lo + hi) / 2.0
		var c0 := area.get_center()
		var to := func(v: Vector2) -> Vector2:
			return Vector2(c0.x + (v.x - mid.x) * sc, c0.y - (v.y - mid.y) * sc)
		var P := {}
		var cen := Vector2.ZERO
		for k in pts:
			P[k] = to.call(Vector2(float(pts[k][0]), float(pts[k][1])))
			cen += P[k]
		cen /= float(pts.size())
		var line_c := Color(0.85, 0.9, 1.0, 0.85)
		var dim := Color(1, 1, 1, 0.5)
		if f.get("axes", false):
			var o2: Vector2 = to.call(Vector2.ZERO)
			draw_line(Vector2(rect.position.x + 6.0, o2.y), Vector2(rect.end.x - 6.0, o2.y), Color(1, 1, 1, 0.3), 1.2)
			draw_line(Vector2(o2.x, rect.position.y + 6.0), Vector2(o2.x, rect.end.y - 6.0), Color(1, 1, 1, 0.3), 1.2)
			MathLabel.draw_on(self, font, rect.end.x - 12.0, o2.y - 6.0, "x", UITheme.fs(12), dim)
			MathLabel.draw_on(self, font, o2.x + 10.0, rect.position.y + 16.0, "y", UITheme.fs(12), dim)
		# 塗色的多邊形（例如以切表弦的三角形）
		if f.has("fill"):
			var fp := PackedVector2Array()
			for k in f.fill:
				fp.append(P[k])
			draw_colored_polygon(fp, Color(UITheme.PINK.r, UITheme.PINK.g, UITheme.PINK.b, 0.55))
		# 圓弧
		for ca in f.get("carcs", []):
			var cc: Vector2 = P[ca[0]]
			var a1: float = (P[ca[1]] - cc).angle()
			var a2: float = (P[ca[2]] - cc).angle()
			var r: float = cc.distance_to(P[ca[1]])
			var d: float = wrapf(a2 - a1, -PI, PI)
			draw_arc(cc, r, a1, a1 + d, 48, Color(UITheme.ORANGE.r, UITheme.ORANGE.g, UITheme.ORANGE.b, 0.85), 2.0, true)
		# 角的小弧
		for an in f.get("angles", []):
			var v: Vector2 = P[an[0]]
			var b1: float = (P[an[1]] - v).angle()
			var b2: float = (P[an[2]] - v).angle()
			var dd: float = wrapf(b2 - b1, -PI, PI)
			var ac: Color = UITheme.GOLD
			draw_arc(v, 24.0, b1, b1 + dd, 24, ac, 2.0, true)
			if an.size() > 3 and String(an[3]) != "":
				var bm := b1 + dd / 2.0
				MathLabel.draw_on(self, font, v.x + cos(bm) * 40.0, v.y + sin(bm) * 40.0 + 5.0, String(an[3]), UITheme.fs(13), ac)
		# 線段與長度
		for sg in f.get("segs", []):
			var a: Vector2 = P[sg[0]]
			var b: Vector2 = P[sg[1]]
			draw_line(a, b, line_c, 2.0, true)
			if sg.size() > 2 and String(sg[2]) != "":
				var m: Vector2 = (a + b) / 2.0
				var nrm: Vector2 = Vector2(-(b - a).y, (b - a).x).normalized()
				if nrm.dot(m - cen) < 0.0:
					nrm = -nrm
				MathLabel.draw_on(self, font, m.x + nrm.x * 14.0, m.y + nrm.y * 14.0 + 5.0 + maxf(nrm.y, 0.0) * 8.0, String(sg[2]), UITheme.fs(13), UITheme.CYAN_LIGHT)
		# 直角記號
		for rt in f.get("right", []):
			var v2: Vector2 = P[rt[0]]
			var u1: Vector2 = (P[rt[1]] - v2).normalized() * 9.0
			var u2: Vector2 = (P[rt[2]] - v2).normalized() * 9.0
			draw_polyline(PackedVector2Array([v2 + u1, v2 + u1 + u2, v2 + u2]), Color(1, 1, 1, 0.75), 1.5, true)
		# 點與名稱
		var hide: Array = f.get("hide", [])
		for k in pts:
			if k in f.get("ghost", []):     # 只用來撐開版面的點：不畫
				continue
			var q: Vector2 = P[k]
			UITheme.dot(self, q, 3.5, UITheme.GOLD)
			if k in hide:
				continue
			var away: Vector2 = (q - cen)
			away = away.normalized() if away.length() > 1.0 else Vector2(0, -1)
			MathLabel.draw_on(self, font, q.x + away.x * 15.0, q.y + away.y * 15.0 + 5.0, String(k), UITheme.fs(14), UITheme.GOLD)

	func _draw_mode(font: Font) -> void:
		var rc := _spin_rect()
		draw_style_box(UITheme.boxc(Color(0.03, 0.06, 0.14, 0.62), 14, Color(0.78, 0.6, 1.0, 0.28), 1, 0), rc)
		_draw_task(font, rc, "調音")
		match mode:
			"dial":
				_draw_dial(font, rc)
			"chain":
				_draw_chain(font, rc)
			"ride":
				_draw_ride(font, rc)
			"hunt":
				_draw_hunt(font, rc)

	# --- dial ---

	func _draw_dial(font: Font, rc: Rect2) -> void:
		var fn := String(spec.get("fn", "sin"))
		var curves := []
		var legend := []
		if spec.get("base", false):
			curves.append({"f": fn, "a": 1.0, "b": 1.0, "c": 0.0, "d": 0.0, "col": Color(1, 1, 1, 0.3)})
			legend.append(["y = %s x" % fn, Color(1, 1, 1, 0.5)])
		# 同一張圖上先前畫好的曲線（作圖求解：先畫三角函數，再在同一張圖上畫直線）
		for uc in spec.get("under", []):
			curves.append(uc)
			if String(uc.get("label", "")) != "":
				legend.append([String(uc.label), uc.col])
		if spec.has("target") and not spec.get("hide_target", false) and not spec.has("dots"):
			var tc: Dictionary = spec.target.duplicate()
			tc["f"] = fn
			tc["ghost"] = true
			tc["col"] = UITheme.GOLD
			curves.append(tc)
			legend.append(["目標", UITheme.GOLD])
		var pc := cur.duplicate()
		pc["f"] = fn
		pc["col"] = UITheme.GOOD if matched else (UITheme.CYAN if fn == "sin" else UITheme.VIOLET_LIGHT)
		pc["aid"] = spec.get("aid", true)
		if fn == "line":
			pc = {"f": "line", "m": cur.a, "k": cur.d, "col": UITheme.GOOD if matched else UITheme.PINK_LIGHT}
		curves.append(pc)
		legend.append(["你的直線" if fn == "line" else "你的波", pc.col])
		var g: Dictionary = spec.view.duplicate()
		g["curves"] = curves
		g["legend"] = legend
		var area := _plot(font, rc, g, true)
		var u := _unit(g)
		for dt in spec.get("dots", []):
			var p := _map(area, g, float(dt[0]), float(dt[1]))
			var ok := absf(fv(pc, float(dt[0]) * u) - float(dt[1])) < 1e-6
			var col: Color = UITheme.GOOD if ok else UITheme.GOLD
			UITheme.dot(self, p, 11.0 + 1.5 * sin(t * 4.0), Color(col.r, col.g, col.b, 0.25))
			UITheme.dot(self, p, 6.0, col)
		if matched:
			MathLabel.draw_on(self, font, area.end.x - MathLabel.text_width(font, "✓ 吻合！按確定", UITheme.fs(15)) / 2.0, area.position.y - 9.0, "✓ 吻合！按確定", UITheme.fs(15), UITheme.GOOD)

	# --- chain ---

	func _draw_chain(font: Font, rc: Rect2) -> void:
		var fn := String(spec.get("fn", "sin"))
		var e := ch_k * ch_k * (3.0 - 2.0 * ch_k)
		var s := {}
		for key in ["A", "B", "H", "D"]:
			s[key] = lerpf(float(ch_from[key]), float(ch_to[key]), e)
		var base := {"f": fn, "a": 1.0, "b": 1.0, "c": 0.0, "d": 0.0, "col": Color(1, 1, 1, 0.3)}
		var tg: Dictionary = spec.target.duplicate()
		tg["f"] = fn
		tg["ghost"] = true
		tg["col"] = UITheme.GOLD
		var cc := {"f": fn, "a": s.A, "b": s.B, "c": -float(s.B) * float(s.H) * PI, "d": s.D,
			"col": UITheme.GOOD if matched else (UITheme.CYAN if fn == "sin" else UITheme.VIOLET_LIGHT)}
		var g: Dictionary = spec.view.duplicate()
		g["curves"] = [base, tg, cc]
		g["legend"] = [["y = %s x" % fn, Color(1, 1, 1, 0.5)], ["目標", UITheme.GOLD], ["現在", cc.col]]
		var area := _plot(font, rc, g, true)
		if matched and ch_k >= 1.0:
			MathLabel.draw_on(self, font, area.end.x - MathLabel.text_width(font, "✓ 吻合！按確定", UITheme.fs(15)) / 2.0, area.position.y - 9.0, "✓ 吻合！按確定", UITheme.fs(15), UITheme.GOOD)

	# --- ride ---

	func _ride_geo(rc: Rect2) -> Dictionary:
		var r: float = float(spec.r)
		var cy: float = float(spec.cy)
		var T: float = float(spec.T)
		var top := cy + r + 4.0
		var s := minf(76.0 / r, (rc.size.y - 108.0) / top)
		var ground := rc.end.y - 40.0
		var cen := Vector2(rc.position.x + 118.0, ground - cy * s)
		var gx := rc.position.x + 262.0
		var area := Rect2(gx, ground - top * s, rc.end.x - gx - 18.0, top * s)
		var g := {"x": [0.0, T], "y": [0.0, top], "xu": "num", "xt": ride_xt(T), "yt": 10.0 if r >= 15.0 else 5.0, "area": area}
		return {"s": s, "ground": ground, "cen": cen, "area": area, "g": g}

	func _draw_ride(font: Font, rc: Rect2) -> void:
		var geo := _ride_geo(rc)
		var s: float = geo.s
		var ground: float = geo.ground
		var cen: Vector2 = geo.cen
		var area: Rect2 = geo.area
		var g: Dictionary = geo.g
		var r: float = float(spec.r)
		var T: float = float(spec.T)
		var cv := ride_curve(spec)
		var unit_t := String(spec.get("unit_t", "分"))
		var unit_h := String(spec.get("unit_h", "公尺"))
		# 右邊：高度對時間的圖
		g["xl"] = "t（%s）" % unit_t
		g["yl"] = "高度（%s）" % unit_h
		_plot(font, rc, g, true)
		# 地面與摩天輪
		draw_line(Vector2(rc.position.x + 20.0, ground), Vector2(area.position.x - 6.0, ground), Color(1, 1, 1, 0.35), 2.0)
		draw_line(Vector2(cen.x - 26.0, ground), cen, Color(1, 1, 1, 0.22), 3.0)
		draw_line(Vector2(cen.x + 26.0, ground), cen, Color(1, 1, 1, 0.22), 3.0)
		draw_arc(cen, r * s, 0, TAU, 72, Color(0.8, 0.7, 1.0, 0.55), 2.0, true)
		for k in 8:
			var a := k * TAU / 8.0
			draw_line(cen, cen + Vector2(cos(a), -sin(a)) * r * s, Color(0.8, 0.7, 1.0, 0.14), 1.0)
		MathLabel.draw_on(self, font, rc.position.x + 52.0, ground + 18.0, "地面", UITheme.fs(12), Color(1, 1, 1, 0.5))
		# 目標高度的水平線（橫跨摩天輪和圖）
		if spec.has("level"):
			var ly := ground - float(spec.level) * s
			draw_dashed_line(Vector2(rc.position.x + 20.0, ly), Vector2(area.end.x, ly), Color(1, 0.85, 0.35, 0.65), 1.6, 6.0)
			MathLabel.draw_on(self, font, rc.position.x + 52.0, ly - 8.0, "高度 %s" % TideView.dec(float(spec.level)), UITheme.fs(13), UITheme.GOLD)
		# 曲線：淡淡的全貌＋已經掃過的部分
		var px := func(tt: float, hh: float) -> Vector2:
			return Vector2(area.position.x + tt / T * area.size.x, ground - hh * s)
		var full := PackedVector2Array()
		for i in 121:
			var tt := T * i / 120.0
			full.append(px.call(tt, fv(cv, tt)))
		draw_polyline(full, Color(0.8, 0.7, 1.0, 0.16), 2.0, true)
		var n := maxi(2, int(ride_max / T * 120.0))
		var seen := PackedVector2Array()
		for i in n + 1:
			var tt2 := ride_max * i / n
			seen.append(px.call(tt2, fv(cv, tt2)))
		if ride_max > 0.01:
			draw_polyline(seen, Color(0.78, 0.6, 1.0, 0.28), 7.0, true)
			draw_polyline(seen, UITheme.VIOLET, 2.6, true)
		for f in found:
			var fp: Vector2 = px.call(float(f), fv(cv, float(f)))
			UITheme.dot(self, fp, 11.0, Color(1, 0.85, 0.35, 0.3))
			UITheme.dot(self, fp, 6.0, UITheme.GOLD)
		# 車廂（逆時針轉）與它在圖上的點
		var th := TAU * ride_show / T + float(spec.get("phi", -PI / 2.0))
		var cab := cen + Vector2(cos(th), -sin(th)) * r * s
		var gp: Vector2 = px.call(ride_show, fv(cv, ride_show))
		draw_dashed_line(cab, Vector2(gp.x, cab.y), Color(0.6, 0.9, 1.0, 0.6), 1.5, 5.0)
		draw_line(Vector2(gp.x, ground), gp, Color(0.6, 0.9, 1.0, 0.35), 1.5)
		UITheme.dot(self, gp, 6.0, UITheme.CYAN)
		UITheme.dot(self, cab, 16.0 + 2.0 * sin(t * 4.0), Color(1, 0.85, 0.45, 0.22))
		UITheme.dot(self, cab, 8.0, UITheme.GOLD)
		UITheme.dot(self, cab, 3.5, Color.WHITE)
		UITheme.dot(self, cen, 3.5, Color(1, 1, 1, 0.8))
		if not dragged_ever and not play:
			MathLabel.draw_on(self, font, area.position.x + area.size.x / 2.0, area.position.y + 14.0, "拖動這張圖（或用右邊的滑桿）", UITheme.fs(14), Color(1, 0.92, 0.7))

	# --- hunt ---

	func _draw_hunt(font: Font, rc: Rect2) -> void:
		var g: Dictionary = spec.view.duplicate()
		var curves := []
		var legend := []
		for c in spec.curves:
			curves.append(c)
			if String(c.get("label", "")) != "":
				legend.append([String(c.label), c.get("col", UITheme.CYAN)])
		g["curves"] = curves
		g["legend"] = legend
		var area := _plot(font, rc, g, true)
		var u := _unit(g)
		for i in found:
			var p := _map(area, g, hunt_pts[i].x / u, hunt_pts[i].y)
			UITheme.dot(self, p, 12.0 + 2.0 * sin(t * 4.0), Color(1, 0.85, 0.35, 0.28))
			UITheme.dot(self, p, 6.5, UITheme.GOLD)
			UITheme.dot(self, p, 2.5, Color.WHITE)
		for f in flashes:
			var k := (t - float(f.t)) / 0.9
			if bool(f.ok):
				draw_arc(f.pos, 10.0 + 26.0 * k, 0, TAU, 32, Color(1, 0.85, 0.35, 0.8 * (1.0 - k)), 2.0, true)
			else:
				var cx: Vector2 = f.pos
				var col := Color(1, 0.45, 0.5, 0.9 * (1.0 - k))
				draw_line(cx + Vector2(-8, -8), cx + Vector2(8, 8), col, 3.0)
				draw_line(cx + Vector2(-8, 8), cx + Vector2(8, -8), col, 3.0)
		var fstr := "已找到 %d 個" % found.size()
		MathLabel.draw_on(self, font, area.end.x - MathLabel.text_width(font, fstr, UITheme.fs(15)) / 2.0, area.position.y - 9.0, fstr, UITheme.fs(15), UITheme.GOLD)

	# ---------- 畫函數圖 ----------

	func _plot_area(rc: Rect2, g: Dictionary, big: bool) -> Rect2:
		if g.has("area"):
			return g.area
		if big:
			# 圖例在圖的上方；圖例有直式分數（比較高）就再往下讓一點
			var top := 64.0
			for lg in g.get("legend", []):
				if String(lg[0]).contains("/"):
					top = 78.0
			return Rect2(rc.position.x + 52.0, rc.position.y + top, rc.size.x - 52.0 - 18.0, rc.size.y - top - 38.0)
		return Rect2(rc.position.x + 34.0, rc.position.y + 10.0, rc.size.x * 0.68, rc.size.y - 34.0)

	func _map(area: Rect2, g: Dictionary, xn: float, y: float) -> Vector2:
		var xr: Array = g.get("x", [0.0, 2.0])
		var yr: Array = g.get("y", [-1.5, 1.5])
		return Vector2(area.position.x + (xn - float(xr[0])) / (float(xr[1]) - float(xr[0])) * area.size.x,
			area.end.y - (y - float(yr[0])) / (float(yr[1]) - float(yr[0])) * area.size.y)

	func _xlabel(g: Dictionary, xv: float) -> String:
		if _unit(g) == PI:
			return pi_text(xv * PI)
		return dec(xv)

	## 畫一張函數圖，回傳繪圖區（互動時用來換算位置）。
	## g：curves（每條 {f, a, b, c, d, col, label, ghost, aid}）、x、y、xu（"pi" 或 "num"）、xt、yt、
	##    pts（[x, y, 標籤]）、hlines（[y, 標籤, 顏色]）、vlines（[x, 標籤]）、period（[x0, x1, 標籤]）、
	##    amp（[x, y0, y1, 標籤]）、shift（[x0, x1, y, 標籤]）、legend、xl、yl；
	##    x 方向的數字：xu 是 "pi" 就以 π 為單位，是 "num" 就是原本的數字
	func _plot(font: Font, rc: Rect2, g: Dictionary, big: bool) -> Rect2:
		var area := _plot_area(rc, g, big)
		var u := _unit(g)
		var xr: Array = g.get("x", [0.0, 2.0])
		var yr: Array = g.get("y", [-1.5, 1.5])
		var x0 := float(xr[0])
		var x1 := float(xr[1])
		var y0 := float(yr[0])
		var y1 := float(yr[1])
		var xt: float = g.get("xt", 0.5 if u == PI else 1.0)
		var yt: float = g.get("yt", 1.0)
		var dim := Color(1, 1, 1, 0.5)
		# 格線與刻度
		var k0 := int(ceil(x0 / xt - 1e-9))
		var k1 := int(floor(x1 / xt + 1e-9))
		var per_lab := area.size.x / maxf(1.0, float(k1 - k0 + 1))
		var every := 1 if per_lab >= 40.0 else (2 if per_lab >= 20.0 else 4)
		var ay := clampf(_map(area, g, x0, 0.0).y, area.position.y, area.end.y)
		var lab_y := ay + 17.0 if ay < area.end.y - 14.0 else area.end.y + 17.0
		for k in range(k0, k1 + 1):
			var xv := k * xt
			var p := _map(area, g, xv, y0)
			draw_line(Vector2(p.x, area.position.y), Vector2(p.x, area.end.y), Color(1, 1, 1, 0.09 if k % 2 == 0 else 0.05), 1.0)
			if k != 0 and k % every == 0:
				# 刻度數字（π/2 這種直式分數比較高）：整個放在 x 軸下面，後面墊一小塊底色，曲線經過也看得清楚
				var xs := _xlabel(g, xv)
				var tfs := UITheme.fs(12)
				var te := MathLabel.line_extent(xs, tfs)
				var tb := (ay + 5.0 + te.x) if ay < area.end.y - 14.0 else lab_y
				var tw := MathLabel.text_width(font, xs, tfs)
				draw_rect(Rect2(p.x - tw / 2.0 - 3.0, tb - te.x - 1.0, tw + 6.0, te.x + te.y + 2.0), Color(0.03, 0.05, 0.12, 0.75))
				MathLabel.draw_on(self, font, p.x, tb, xs, tfs, dim)
		var j0 := int(ceil(y0 / yt - 1e-9))
		var j1 := int(floor(y1 / yt + 1e-9))
		for j in range(j0, j1 + 1):
			var yv := j * yt
			var p2 := _map(area, g, x0, yv)
			draw_line(Vector2(area.position.x, p2.y), Vector2(area.end.x, p2.y), Color(1, 1, 1, 0.09 if j % 2 == 0 else 0.05), 1.0)
			draw_string(font, Vector2(area.position.x - 34.0, p2.y + 5.0), dec(yv), HORIZONTAL_ALIGNMENT_RIGHT, 28.0, UITheme.fs(12), dim)
		draw_rect(area, Color(1, 1, 1, 0.14), false, 1.0)
		if y0 <= 0.0 and y1 >= 0.0:
			draw_line(Vector2(area.position.x, ay), Vector2(area.end.x, ay), Color(1, 1, 1, 0.45), 1.5)
		if x0 <= 0.0 and x1 >= 0.0:
			var ox := _map(area, g, 0.0, y0).x
			draw_line(Vector2(ox, area.position.y), Vector2(ox, area.end.y), Color(1, 1, 1, 0.45), 1.5)
		if String(g.get("xl", "")) != "":
			MathLabel.draw_on(self, font, area.end.x - 30.0, lab_y + 15.0, String(g.xl), UITheme.fs(12), dim)
		if String(g.get("yl", "")) != "":
			var ylw := MathLabel.text_width(font, String(g.yl), UITheme.fs(12))
			MathLabel.draw_on(self, font, area.position.x + 4.0 + ylw / 2.0, area.position.y - 9.0, String(g.yl), UITheme.fs(12), dim)
		# 水平線、垂直線
		for hl in g.get("hlines", []):
			var hc: Color = hl[2] if hl.size() > 2 else Color(1, 0.6, 0.75)
			var a1 := _map(area, g, x0, float(hl[0]))
			var a2 := _map(area, g, x1, float(hl[0]))
			if float(hl[0]) >= y0 and float(hl[0]) <= y1:
				draw_dashed_line(a1, a2, Color(hc.r, hc.g, hc.b, 0.75), 1.6, 6.0)
				if hl.size() > 1 and String(hl[1]) != "":
					MathLabel.draw_on(self, font, area.end.x - 40.0, a1.y - 9.0, String(hl[1]), UITheme.fs(13), hc)
		for vl in g.get("vlines", []):
			var b1 := _map(area, g, float(vl[0]), y1)
			var b2 := _map(area, g, float(vl[0]), y0)
			draw_dashed_line(b1, b2, Color(1, 0.6, 0.75, 0.7), 1.5, 5.0)
			if vl.size() > 1 and String(vl[1]) != "":
				MathLabel.draw_on(self, font, b1.x, b1.y + 14.0, String(vl[1]), UITheme.fs(12), Color(1, 0.7, 0.8))
		# 曲線
		var labels := []
		for c in g.get("curves", []):
			_draw_curve(area, g, c, x0, x1, y0, y1)
			if String(c.get("label", "")) != "":
				labels.append([String(c.label), c.get("col", UITheme.CYAN)])
			if c.get("aid", false):
				_draw_aids(font, area, g, c, x0, x1, y0, y1)
		# 標出來的括號、箭頭
		if g.has("period"):
			var pr: Array = g.period
			var ya := area.position.y + 8.0
			var pa := _map(area, g, float(pr[0]), 0.0).x
			var pb := _map(area, g, float(pr[1]), 0.0).x
			var pcol := Color(1, 0.85, 0.35, 0.9)
			draw_line(Vector2(pa, ya), Vector2(pb, ya), pcol, 2.0)
			draw_line(Vector2(pa, ya - 5), Vector2(pa, ya + 5), pcol, 2.0)
			draw_line(Vector2(pb, ya - 5), Vector2(pb, ya + 5), pcol, 2.0)
			draw_dashed_line(Vector2(pa, ya), Vector2(pa, area.end.y), Color(1, 0.85, 0.35, 0.25), 1.0, 4.0)
			draw_dashed_line(Vector2(pb, ya), Vector2(pb, area.end.y), Color(1, 0.85, 0.35, 0.25), 1.0, 4.0)
			labels.append([String(pr[2]) if pr.size() > 2 else "一個週期", pcol])
		if g.has("amp"):
			var am: Array = g.amp
			var q1 := _map(area, g, float(am[0]), float(am[1]))
			var q2 := _map(area, g, float(am[0]), float(am[2]))
			_arrow(q1, q2, Color(1, 0.85, 0.35, 0.95))
			if am.size() > 3:
				MathLabel.draw_on(self, font, q1.x + 26.0, (q1.y + q2.y) / 2.0 + 5.0, String(am[3]), UITheme.fs(13), UITheme.GOLD)
		if g.has("shift"):
			var sh: Array = g.shift
			var s1 := _map(area, g, float(sh[0]), float(sh[2]))
			var s2 := _map(area, g, float(sh[1]), float(sh[2]))
			_arrow(s1, s2, Color(0.65, 0.95, 0.4, 0.95))
			if sh.size() > 3:
				MathLabel.draw_on(self, font, (s1.x + s2.x) / 2.0, s1.y - 10.0, String(sh[3]), UITheme.fs(13), UITheme.LIME)
		for pt in g.get("pts", []):
			var pp := _map(area, g, float(pt[0]), float(pt[1]))
			UITheme.dot(self, pp, 8.0 + 1.5 * sin(t * 4.0), Color(1, 0.85, 0.35, 0.25))
			UITheme.dot(self, pp, 4.5, UITheme.GOLD)
			if pt.size() > 2 and String(pt[2]) != "":
				MathLabel.draw_on(self, font, pp.x, pp.y - 12.0, String(pt[2]), UITheme.fs(12), UITheme.GOLD)
		# 圖例或右邊的標籤
		if big:
			# 圖例排成一列，放在圖的上方（不蓋住曲線）；左邊留給 y 軸的單位
			var lfs := UITheme.fs(13)
			var lx0 := area.position.x + 4.0
			if String(g.get("yl", "")) != "":
				lx0 += MathLabel.text_width(font, String(g.yl), UITheme.fs(12)) + 16.0
			var ly := area.position.y - 9.0
			for lg in g.get("legend", []):
				if String(lg[0]).contains("/"):
					ly = area.position.y - 12.0
				var lc: Color = lg[1]
				var lab := String(lg[0])
				var lw := MathLabel.text_width(font, lab, lfs)
				draw_line(Vector2(lx0, ly - 4.0), Vector2(lx0 + 16.0, ly - 4.0), lc, 3.0)
				MathLabel.draw_on(self, font, lx0 + 21.0 + lw / 2.0, ly, lab, lfs, Color(lc.r, lc.g, lc.b, 0.95))
				lx0 += 21.0 + lw + 16.0
		else:
			var lx := rc.position.x + rc.size.x * 0.865
			var ly2 := rc.position.y + 36.0
			for lb in labels:
				MathLabel.draw_on(self, font, lx, ly2, String(lb[0]), UITheme.fs(14), lb[1])
				ly2 += 28.0
		return area

	func _arrow(p1: Vector2, p2: Vector2, col: Color) -> void:
		draw_line(p1, p2, col, 2.0, true)
		var dv := (p2 - p1).normalized()
		var nv := dv.orthogonal()
		draw_colored_polygon(PackedVector2Array([p2, p2 - dv * 9.0 + nv * 4.5, p2 - dv * 9.0 - nv * 4.5]), col)
		draw_colored_polygon(PackedVector2Array([p1, p1 + dv * 9.0 + nv * 4.5, p1 + dv * 9.0 - nv * 4.5]), col)

	func _draw_curve(area: Rect2, g: Dictionary, c: Dictionary, x0: float, x1: float, y0: float, y1: float) -> void:
		var u := _unit(g)
		var col: Color = c.get("col", UITheme.CYAN)
		var ghost: bool = c.get("ghost", false)
		var N := 320
		var seg := PackedVector2Array()
		var idx := 0
		for i in N + 1:
			var xn := lerpf(x0, x1, float(i) / N)
			var y := fv(c, xn * u)
			if is_nan(y) or y > y1 + 1e-6 or y < y0 - 1e-6:
				_flush(seg, col, ghost)
				seg = PackedVector2Array()
				continue
			if ghost and (i / 4) % 2 == 1:
				_flush(seg, col, ghost)
				seg = PackedVector2Array()
				continue
			seg.append(_map(area, g, xn, y))
			idx += 1
		_flush(seg, col, ghost)
		# tan 的漸近線
		if String(c.get("f", "")) == "tan":
			var bb: float = c.get("b", 1.0)
			var per := PI / absf(bb)
			var kk := int(ceil((x0 * u - float(c.get("c", 0.0)) / bb - per / 2.0) / per))
			var ax := per * kk + per / 2.0 - float(c.get("c", 0.0)) / bb
			while ax <= x1 * u + 1e-9:
				if ax >= x0 * u:
					draw_dashed_line(_map(area, g, ax / u, y1), _map(area, g, ax / u, y0), Color(1, 1, 1, 0.3), 1.2, 4.0)
				ax += per

	func _flush(seg: PackedVector2Array, col: Color, ghost: bool) -> void:
		if seg.size() < 2:
			return
		if ghost:
			var a := 0.55 + 0.25 * sin(t * 3.0)
			draw_polyline(seg, Color(col.r, col.g, col.b, 0.18), 7.0, true)
			draw_polyline(seg, Color(col.r, col.g, col.b, a), 2.6, true)
		else:
			draw_polyline(seg, Color(col.r, col.g, col.b, 0.22), 6.0, true)
			draw_polyline(seg, col, 2.6, true)

	## 中線、振幅、週期（sin、cos 才有）
	func _draw_aids(font: Font, area: Rect2, g: Dictionary, c: Dictionary, x0: float, x1: float, y0: float, y1: float) -> void:
		var fn := String(c.get("f", "sin"))
		if fn != "sin" and fn != "cos":
			return
		var a: float = c.get("a", 1.0)
		var b: float = c.get("b", 1.0)
		var cc: float = c.get("c", 0.0)
		var d: float = c.get("d", 0.0)
		if absf(b) < 1e-9 or absf(a) < 1e-9:
			return
		var u := _unit(g)
		if d >= y0 and d <= y1:
			var m1 := _map(area, g, x0, d)
			var m2 := _map(area, g, x1, d)
			draw_dashed_line(m1, m2, Color(1, 1, 1, 0.38), 1.3, 6.0)
			MathLabel.draw_on(self, font, area.end.x - 46.0, m1.y - 9.0, "中線 y = %s" % dec(d), UITheme.fs(12), Color(1, 1, 1, 0.6))
		var phi := (PI / 2.0 if a > 0.0 else -PI / 2.0) if fn == "sin" else (0.0 if a > 0.0 else PI)
		var per := TAU / absf(b)
		var xp0 := (phi - cc) / b
		var kk := ceilf((x0 * u - xp0) / per - 1e-9)
		var xp := xp0 + kk * per
		if xp > x1 * u + 1e-9 or d + absf(a) > y1 + 1e-9:
			return
		var top := _map(area, g, xp / u, d + absf(a))
		var bot := _map(area, g, xp / u, d)
		_arrow(bot, top, Color(1, 0.85, 0.35, 0.9))
		MathLabel.draw_on(self, font, top.x + 30.0, (top.y + bot.y) / 2.0 + 5.0, "振幅 %s" % fr(absf(a)), UITheme.fs(12), UITheme.GOLD)
		if xp + per <= x1 * u + 1e-9:
			var ya := maxf(area.position.y + 6.0, top.y - 14.0)
			var pb := _map(area, g, (xp + per) / u, 0.0).x
			var pcol := Color(0.65, 0.95, 0.4, 0.9)
			draw_line(Vector2(top.x, ya), Vector2(pb, ya), pcol, 2.0)
			draw_line(Vector2(top.x, ya - 4), Vector2(top.x, ya + 4), pcol, 2.0)
			draw_line(Vector2(pb, ya - 4), Vector2(pb, ya + 4), pcol, 2.0)
			var plab := "週期 " + (pi_text(per) if u == PI else dec(per))
			MathLabel.draw_on(self, font, (top.x + pb) / 2.0, ya + 15.0, plab, UITheme.fs(12), UITheme.LIME)
