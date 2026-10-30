extends "level_02_forge.gd"
## 第三大關「天秤神殿」（對應講義 重點三：指數不等式與極值）
## 用法：主選單會自動開啟它。需要同資料夾的 level_02_forge.gd、step_level.gd（步驟推導引擎）、level_01_light_bridge.gd（共用外殼）
## 與 level03_bank.gd（題庫）。
##
## 沿用第二大關「一步一步算」的方式（選擇、數字鍵盤填空、篩選），再加上四種新步驟：
##   order    高塔排序：依序點選，從小排到大
##   line     數線：點區間塗色、點分界點切換包含／不含——解不等式的最後一步
##   grid     符號表：每個因式在各區間的正負
##   explore  探索極值：直接拖動 t（滑桿或圖上），看點在拋物線上滑動，找到最大／最小值再鎖定

const Bank3 := preload("level03_bank.gd")
const CHAPTERS3 := [
	{"ch": 1, "name": "第一章．不等號的天秤", "topic": "比大小、指數不等式與數線", "color": UITheme.LIME},
	{"ch": 2, "name": "第二章．極值的祭壇", "topic": "換元求極值、成立條件與算幾", "color": UITheme.CYAN},
]
const LEAF := UITheme.LIME

# 排序
# 符號表
var grid_vals: Array = []
var grid_btns: Array = []
# 探索
var ex_slider: HSlider
var ex_info: MathLabel


func level_id() -> String:
	return "L3"

func level_title() -> String:
	return "天秤神殿"

func level_subtitle() -> String:
	return "指數不等式與極值"

func level_chapters() -> Array:
	return CHAPTERS3

## 天秤神殿：暖金色的神殿夜空，空中飄著金色微塵
func stage_style() -> Dictionary:
	return {"sky_top": Color("231a3a"), "sky_bot": Color("2a1d14"), "scenery": "none", "ambient": "dust"}


func bank_slots() -> Array:
	return Bank3.slots()

func chapter_card() -> Dictionary:
	return {"title": "第二章．極值的祭壇", "button": "進入極值的祭壇  ▶",
		"text": "求極值的三個關卡：\n\n" \
			+ "・t 的範圍：t = a^{x} > 0；x 有範圍時 t 也有範圍\n" \
			+ "・t = a^{x} + a^{−x} ≥ 2（算幾不等式）\n" \
			+ "・配方找頂點：頂點不在範圍內，就看端點\n\n" \
			+ "拖動 t，親眼看點在拋物線上滑到哪裡！"}


func step_color() -> Color:
	return LEAF


func _ensure_fview() -> void:
	if fview == null:
		fview = ScaleView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		(fview as ScaleView).line_toggled.connect(func(): Game.of(self).play("bell", Game.semi(7), -9.0))
		(fview as ScaleView).t_dragged.connect(func(tv: float):
			if ex_slider != null and is_instance_valid(ex_slider):
				ex_slider.value = snappedf(tv, EX_STEP) if absf(tv - ScaleView.t_window(_sv().explore).x) > EX_STEP / 2.0 else tv)


func _sv() -> ScaleView:
	return fview as ScaleView


# ================= 新的步驟 =================

func _forge_step() -> void:
	_sv().end_line()
	_sv().explore = {}
	fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	super()
	if si >= steps.size():
		return
	var st: Dictionary = steps[si]
	if not st.kind in ["line", "grid", "explore"]:
		return
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	go_btn.visible = true
	go_btn.disabled = false
	match st.kind:
		"line":
			go_btn.text = "確認"
			_sv().begin_line(st)
			fview.mouse_filter = Control.MOUSE_FILTER_STOP
			var tip := Label.new()
			tip.text = "在左邊的數線上點選。"
			tip.add_theme_font_size_override("font_size", UITheme.fs(15))
			tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
			rank_box.add_child(tip)
		"grid":
			_build_grid(st)
		"explore":
			_build_explore(st)


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size():
		match steps[si].kind:
			"line":
				_line_submit()
				return
			"grid":
				_grid_submit()
				return
			"explore":
				_explore_submit()
				return
	super()


func _step_done(st: Dictionary, why: String) -> void:
	if st.kind == "line":
		_sv().line_lock = true
	go_btn.visible = false
	# 配方完成：拋物線（含 t 的範圍、頂點）馬上出現，而且一直留到最後
	if st.get("name", "") == "配方" and r.type == "forge":
		_sv().qgraph = _first_explore()
	super(st, why)


## 這一題第一個「探索極值」步驟（拋物線的係數、t 的範圍都在裡面）
func _first_explore() -> Dictionary:
	for stp in steps:
		if stp.get("kind", "") == "explore":
			return stp
	return {}


func _custom_start() -> void:
	super()
	if r.has("tilt"):
		_sv().set_tilt(float(r.tilt))


func _custom_reveal(msg: String) -> void:
	# 示範：把剩下的數線答案也畫出來
	for j in range(si, steps.size()):
		if steps[j].kind == "line":
			_sv().begin_line(steps[j])
			_sv().line_seg = Array(steps[j].seg).duplicate()
			_sv().line_inc = Array(steps[j].inc).duplicate()
			_sv().line_lock = true
	_sv().explore = {}
	fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	go_btn.visible = false
	# 示範：拋物線和所有極值點都畫出來
	var fe := _first_explore()
	if not fe.is_empty() and _sv().line_pts.is_empty():
		_sv().qgraph = fe
		for stp in steps:
			if stp.get("kind", "") == "explore":
				var tt := ScaleView.t_of(stp.tmap, float(stp.targets[0]))
				if not _sv().has_mark(tt):
					_sv().marks.append({"t": tt, "goal": stp.goal})
	super(msg)


## 沒寫觀念標籤的步驟，錯題算在「指數不等式」
func _wrong(st: Dictionary, msg: String) -> void:
	if not st.has("tag"):
		st = st.duplicate()
		st["tag"] = "exp_ineq"
	super(st, msg)


# ---------- 數線 ----------

func _line_submit() -> void:
	var st: Dictionary = steps[si]
	var sv := _sv()
	var seg_ok: bool = sv.line_seg == Array(st.seg)
	var inc_ok: bool = sv.line_inc == Array(st.inc)
	if seg_ok and inc_ok:
		Game.of(self).sfx("correct")
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_step_done(st, "")
		return
	var msg := "塗色的區間不對。" if not seg_ok else "區間對了，但端點的「包含／不含」不對（≥、≤ 才包含）。"
	_wrong(st, msg + "\n提示：" + st.nudge)


# ---------- 符號表 ----------

func _build_grid(st: Dictionary) -> void:
	go_btn.text = "確認"
	grid_vals = []
	grid_btns = []
	var g := GridContainer.new()
	g.columns = st.cols.size() + 1
	g.add_theme_constant_override("h_separation", 5)
	g.add_theme_constant_override("v_separation", 5)
	rank_box.add_child(g)
	g.add_child(Control.new())
	for c in st.cols:
		var l := Label.new()
		l.text = c
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_font_size_override("font_size", UITheme.fs(12))
		l.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		g.add_child(l)
	for i in st.rows.size():
		var cc := CenterContainer.new()
		cc.custom_minimum_size = Vector2(92, 40)
		var m := MathLabel.new()
		m.font_size = UITheme.fs(15)
		m.text = st.rows[i]
		m.color = UITheme.ACCENT if i == st.rows.size() - 1 else UITheme.TEXT
		cc.add_child(m)
		g.add_child(cc)
		var row_vals := []
		var row_btns := []
		for j in st.cols.size():
			row_vals.append(0)
			var b := Button.new()
			b.custom_minimum_size = Vector2(0, 40)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", UITheme.fs(20))
			b.set_meta("silent", true)
			var ii: int = i
			var jj: int = j
			b.pressed.connect(func():
				grid_vals[ii][jj] = 1 if grid_vals[ii][jj] != 1 else -1
				Game.of(self).play("bell", Game.semi(9 if grid_vals[ii][jj] == 1 else 4), -10.0)
				_refresh_grid())
			g.add_child(b)
			row_btns.append(b)
		grid_vals.append(row_vals)
		grid_btns.append(row_btns)
	_refresh_grid()


func _refresh_grid(bad: Array = []) -> void:
	for i in grid_btns.size():
		for j in grid_btns[i].size():
			var b: Button = grid_btns[i][j]
			var v: int = grid_vals[i][j]
			b.text = "?" if v == 0 else ("＋" if v == 1 else "−")
			var c := UITheme.TEXT_DIM if v == 0 else (UITheme.GOOD if v == 1 else UITheme.PINK)
			if bad.has(Vector2i(i, j)):
				c = UITheme.BAD
			var sb := UITheme.box(Color(c.r, c.g, c.b, 0.12), 10, c, 2 if v != 0 else 1, 4)
			for state in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(state, sb)
			for fc in ["font_color", "font_hover_color", "font_pressed_color"]:
				b.add_theme_color_override(fc, c.lightened(0.25))


func _grid_submit() -> void:
	var st: Dictionary = steps[si]
	var bad := []
	for i in st.ans.size():
		for j in st.ans[i].size():
			if grid_vals[i][j] != int(st.ans[i][j]):
				bad.append(Vector2i(i, j))
	if bad.is_empty():
		Game.of(self).sfx("correct")
		_step_done(st, "")
		return
	_refresh_grid(bad)
	_wrong(st, "紅色的格子不對。提示：" + st.nudge)


# ---------- 探索極值 ----------

const EX_STEP := 0.05


func _build_explore(st: Dictionary) -> void:
	go_btn.text = "鎖定"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	rank_box.add_child(row)
	var nl := Label.new()
	nl.text = "t"
	nl.custom_minimum_size = Vector2(24, 0)
	nl.add_theme_color_override("font_color", LEAF)
	nl.add_theme_font_size_override("font_size", UITheme.fs(20))
	row.add_child(nl)
	# 滑桿直接控制 t（和圖上的橫軸一樣）；範圍是 t 能到的區間
	var w := ScaleView.t_window(st)
	ex_slider = UITheme.touch_slider()
	ex_slider.min_value = floorf(w.x / EX_STEP) * EX_STEP
	ex_slider.max_value = ceilf(w.y / EX_STEP - 1e-6) * EX_STEP
	ex_slider.step = EX_STEP
	ex_slider.value = clampf(snappedf(lerpf(w.x, w.y, 0.12), EX_STEP), w.x, w.y)
	ex_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ex_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ex_slider.custom_minimum_size = Vector2(0, 28)
	UITheme.tint_slider(ex_slider, LEAF)
	row.add_child(ex_slider)
	UITheme.add_step_buttons(ex_slider, LEAF)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.box(Color(LEAF.r, LEAF.g, LEAF.b, 0.08), 12,
		Color(LEAF.r, LEAF.g, LEAF.b, 0.35), 1, 10))
	rank_box.add_child(card)
	ex_info = MathLabel.new()
	ex_info.font_size = UITheme.fs(17)
	ex_info.max_width = 320
	ex_info.align_center = true
	card.add_child(ex_info)
	var tip := Label.new()
	tip.text = "也可以直接在左邊的圖上拖動。"
	tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(tip)
	_sv().explore = st
	_sv().ex_trail = []
	fview.mouse_filter = Control.MOUSE_FILTER_STOP
	ex_slider.value_changed.connect(_on_explore)
	_on_explore(ex_slider.value)


## 目前的 t（限制在 t 能到的範圍內）
func _ex_t() -> float:
	var w := ScaleView.t_window(_sv().explore)
	return clampf(ex_slider.value, w.x, w.y)


func _on_explore(_v: float) -> void:
	var st: Dictionary = _sv().explore
	if st.is_empty():
		return
	var tt := _ex_t()
	_sv().ex_t = tt
	var c: Array = st.coef
	var y: float = c[0] * tt * tt + c[1] * tt + c[2]
	_sv().ex_trail.append(Vector2(tt, y))
	var bs := ForgeView._ftext(st.tmap.b)
	var tdef := "%s^{x}" % bs if st.tmap.kind == "exp" else "%s^{x} + %s^{−x}" % [bs, bs]
	if st.tmap.kind == "log":
		tdef = "log_{%s} x" % bs
	var w := ScaleView.t_window(st)
	var rng: String = st.get("tlabel", "t ≥ 2" if st.tmap.kind == "sym" else "%s ≤ t ≤ %s" % [
		ForgeView._ftext(w.x), ForgeView._ftext(w.y)])
	ex_info.text = "t = %s　⇒　y = %s\n[color=#%s]t = %s，範圍 %s[/color]" % [_n(tt), _n(y),
		UITheme.TEXT_DIM.to_html(false), tdef, rng]
	Game.of(self).note(clampf(0.5 + y / 40.0, 0.0, 1.0))


static func _n(v: float) -> String:
	return UITheme.num(v, 2).replace("-", "−")


func _explore_submit() -> void:
	var st: Dictionary = steps[si]
	var tt := _ex_t()
	for tx in st.targets:
		var target_t := ScaleView.t_of(st.tmap, float(tx))
		if absf(tt - target_t) <= EX_STEP / 2.0 + 1e-6:
			Game.of(self).sfx("correct")
			_sv().marks.append({"t": target_t, "goal": st.goal})
			if _sv().qgraph.is_empty():
				_sv().qgraph = st
			_sv().explore = {}
			fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_step_done(st, "")
			return
	mistakes += 1
	Game.of(self).sfx("wrong")
	_record(st.tag)
	fview.miss()
	story_label.visible = false
	_hint(("還不是最大值，y 還能更大。" if st.goal == "max" else "還不是最小值，y 還能更小。") + "\n提示：" + st.nudge, "bad")


# ================= 神殿的推導台 =================

class ScaleView extends ForgeView:
	signal line_toggled

	const LEAF := UITheme.LIME

	# 數線
	var line_on := false
	var line_lock := false
	var line_pts: Array = []
	var line_seg: Array = []
	var line_inc: Array = []
	# 探索
	var explore := {}
	var ex_t := 1.0
	var ex_map := {}              # 上一次畫圖時的座標換算（拖動時要反推 t）
	var ex_trail: Array = []
	var qgraph := {}              # 配方之後一直顯示的拋物線（探索步驟的資料）
	var marks: Array = []         # 已經鎖定的極值點 {t, goal}
	# 天秤
	var scale_on := false
	var tilt := 0.0
	var tilt_target := 0.0

	func setup(round: Dictionary) -> void:
		super(round)
		line_lock = false
		line_on = false
		explore = {}
		ex_trail = []
		qgraph = {}
		marks = []
		scale_on = false
		tilt = 0.0
		tilt_target = 0.0

	func set_tilt(v: float) -> void:
		scale_on = true
		tilt = v
		tilt_target = v

	func push_line(text: String) -> void:
		super(text)
		# 天秤：寫下「不等號變向」時翻過去
		if scale_on and text.contains("變向"):
			tilt_target = -tilt_target
			_burst(Vector2(size.x - 80, 70), LEAF, 20)

	func begin_line(st: Dictionary) -> void:
		line_on = true
		line_lock = false
		line_pts = Array(st.pts).duplicate()
		line_seg = []
		line_seg.resize(line_pts.size() + 1)
		line_seg.fill(false)
		line_inc = []
		line_inc.resize(line_pts.size())
		line_inc.fill(false)

	func end_line() -> void:
		if not line_lock:
			line_on = false

	## t 能到的範圍（由 x 的範圍算出；a^{x} + a^{−x} 的最小值是 2）
	static func t_window(st: Dictionary) -> Vector2:
		var d: Array = st.xdom
		var a := t_of(st.tmap, float(d[0]))
		var b := t_of(st.tmap, float(d[1]))
		if st.tmap.kind == "sym":
			return Vector2(2.0, maxf(a, b))
		return Vector2(minf(a, b), maxf(a, b))

	static func t_of(tmap: Dictionary, x: float) -> float:
		var b: float = tmap.b
		if tmap.kind == "log":
			return log(x) / log(b)
		return pow(b, x) + pow(b, -x) if tmap.kind == "sym" else pow(b, x)

	func _process(delta: float) -> void:
		tilt = lerpf(tilt, tilt_target, 1.0 - exp(-4.0 * delta))
		super(delta)

	func _graph_on() -> bool:
		return line_on or not explore.is_empty() or not qgraph.is_empty() or super()

	func has_mark(tv: float) -> bool:
		for mk in marks:
			if absf(float(mk.t) - tv) < 1e-6:
				return true
		return false

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if line_on:
			_draw_line(font, rect)
		elif not explore.is_empty() or not qgraph.is_empty():
			_draw_explore(font, rect)
		else:
			super(font, rect)

	func _draw() -> void:
		super()
		if scale_on:
			_draw_scale(Vector2(size.x - 82, 58))

	## 冷色調的神殿背景：底部的綠光和緩緩上升的光點
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("10202e"), Color("10202e"), Color("0c2a26"), Color("0c2a26")]))
		var glow := 0.14 + 0.03 * sin(t * 1.5)
		draw_polygon(PackedVector2Array([Vector2(0, h * 0.6), Vector2(w, h * 0.6), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color(0.4, 0.9, 0.6, 0.0), Color(0.4, 0.9, 0.6, 0.0), Color(0.4, 0.9, 0.6, glow), Color(0.4, 0.9, 0.6, glow)]))
		# 柱子
		for i in 2:
			var x := 18.0 if i == 0 else w - 46.0
			draw_rect(Rect2(x, 40, 28, h - 40), Color(0.7, 0.9, 0.85, 0.05))
			draw_rect(Rect2(x - 6, 32, 40, 10), Color(0.7, 0.9, 0.85, 0.07))
		for i in 24:
			var sp := 0.03 + 0.03 * fposmod(i * 0.371, 1.0)
			var y := h - fposmod(t * sp + i * 0.137, 1.0) * h
			var x := fposmod(i * 0.618, 1.0) * w + 10.0 * sin(t * 0.9 + i)
			UITheme.dot(self, Vector2(x, y), 1.4 + fposmod(i * 0.29, 1.0) * 1.4, Color(0.7, 1.0, 0.8, clampf(y / h, 0.0, 0.6)))
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	## 角落的小天秤：不等號變向時會翻過去
	func _draw_scale(c: Vector2) -> void:
		var col := Color(0.85, 1.0, 0.9, 0.85)
		draw_line(c + Vector2(0, -6), c + Vector2(0, 34), col, 3.0)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-16, 40), c + Vector2(16, 40), c + Vector2(0, 30)]), col)
		var ang := 0.32 * tilt
		var d := Vector2(cos(ang), sin(ang)) * 40.0
		var l := c - d + Vector2(0, -6)
		var r2 := c + d + Vector2(0, -6)
		draw_line(l, r2, col, 3.0, true)
		for p in [l, r2]:
			draw_line(p, p + Vector2(-12, 16), Color(col.r, col.g, col.b, 0.5), 1.5)
			draw_line(p, p + Vector2(12, 16), Color(col.r, col.g, col.b, 0.5), 1.5)
			draw_arc(p + Vector2(0, 16), 13.0, 0.0, PI, 16, col, 2.5, true)
		UITheme.dot(self, c + Vector2(0, -6), 4.0, LEAF)

	# ---------- 數線 ----------

	func _nl_x(rect: Rect2, i: int) -> float:
		return rect.position.x + rect.size.x * float(i + 1) / float(line_pts.size() + 1)

	func _nl_y(rect: Rect2) -> float:
		return rect.position.y + rect.size.y * 0.52

	func _line_rect() -> Rect2:
		return Rect2(36, size.y - 214, size.x - 72, 190)

	func _draw_line(font: Font, rect: Rect2) -> void:
		draw_style_box(UITheme.boxc(Color(0.03, 0.08, 0.08, 0.55), 12, Color(0.6, 1, 0.75, 0.25), 1, 0), rect.grow(6))
		draw_string(font, rect.position + Vector2(4, -10), "數線（點區間塗色、點分界點切換 ● 包含／○ 不含）",
			HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(0.7, 1, 0.8, 0.7))
		var y := _nl_y(rect)
		var x0 := rect.position.x + 14.0
		var x1 := rect.end.x - 14.0
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.6), 2.0)
		draw_polyline(PackedVector2Array([Vector2(x1 - 10, y - 7), Vector2(x1, y), Vector2(x1 - 10, y + 7)]), Color(1, 1, 1, 0.6), 2.0)
		preload("math_text.gd").draw_text(self, font, Vector2(x1 - 8, y - 12), "x", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 1, 1, 0.7))
		var n := line_pts.size()
		for i in n + 1:
			var a := x0 if i == 0 else _nl_x(rect, i - 1)
			var b := x1 - 12.0 if i == n else _nl_x(rect, i)
			if line_seg[i]:
				draw_line(Vector2(a, y), Vector2(b, y), Color(LEAF.r, LEAF.g, LEAF.b, 0.25), 18.0)
				draw_line(Vector2(a, y), Vector2(b, y), LEAF, 6.0)
				if i == 0:
					draw_colored_polygon(PackedVector2Array([Vector2(a - 4, y), Vector2(a + 10, y - 9), Vector2(a + 10, y + 9)]), LEAF)
				if i == n:
					draw_colored_polygon(PackedVector2Array([Vector2(b + 4, y), Vector2(b - 10, y - 9), Vector2(b - 10, y + 9)]), LEAF)
			elif not line_lock:
				var pa := 0.06 + 0.04 * sin(t * 3.0 + i)
				draw_rect(Rect2(a + 6, y - 26, b - a - 12, 52), Color(1, 1, 1, pa))
		for i in n:
			var p := Vector2(_nl_x(rect, i), y)
			if line_inc[i]:
				UITheme.dot(self, p, 9.0, LEAF)
			else:
				UITheme.dot(self, p, 9.0, Color("0c2a26"))
				draw_arc(p, 8.0, 0, TAU, 24, LEAF if (i < line_seg.size() and (line_seg[i] or line_seg[i + 1])) else Color(1, 1, 1, 0.8), 2.5, true)
			var lab := _ftext(float(line_pts[i]))
			draw_string(font, p + Vector2(-40, 34), lab, HORIZONTAL_ALIGNMENT_CENTER, 80, UITheme.fs(17), Color(1, 1, 1, 0.9))

	signal t_dragged(t: float)

	func _gui_input(e: InputEvent) -> void:
		if not explore.is_empty() and not ex_map.is_empty():
			var drag: bool = (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
				or (e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0)
			if drag:
				var rect: Rect2 = ex_map.rect
				if e is InputEventMouseButton and not rect.grow(20).has_point(e.position):
					return
				var xr: Vector2 = ex_map.xr
				var tv := lerpf(xr.x, xr.y, (e.position.x - rect.position.x) / rect.size.x)
				t_dragged.emit(clampf(tv, ex_map.win.x, ex_map.win.y))
				accept_event()
			return
		if not line_on or line_lock:
			return
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var rect := _line_rect()
			var y := _nl_y(rect)
			if absf(e.position.y - y) > 44.0:
				return
			for i in line_pts.size():
				if absf(e.position.x - _nl_x(rect, i)) <= 16.0:
					line_inc[i] = not line_inc[i]
					line_toggled.emit()
					accept_event()
					return
			var k := 0
			for i in line_pts.size():
				if e.position.x > _nl_x(rect, i):
					k = i + 1
			line_seg[k] = not line_seg[k]
			line_toggled.emit()
			accept_event()

	# ---------- 探索 ----------

	func _draw_explore(font: Font, rect: Rect2) -> void:
		var live := not explore.is_empty()      # 正在拖動找極值（否則只是配方後的示意圖）
		var st := explore if live else qgraph
		var c: Array = st.coef
		var A: float = c[0]
		var B: float = c[1]
		var C: float = c[2]
		var win := t_window(st)
		var tl := win.x
		var th := win.y
		var tv := -B / (2.0 * A)
		var lo := minf(minf(tl, tv), 0.0)
		var hi := maxf(th, tv)
		var pad := maxf(0.5, 0.12 * (hi - lo))
		var xr := Vector2(lo - pad, hi + pad)
		var ymin := INF
		var ymax := -INF
		for i in 81:
			var tt := lerpf(tl, th, i / 80.0)
			var yy := A * tt * tt + B * tt + C
			ymin = minf(ymin, yy)
			ymax = maxf(ymax, yy)
		ymin = minf(ymin, minf(A * tv * tv + B * tv + C, 0.0))
		ymax = maxf(ymax, maxf(A * tv * tv + B * tv + C, 0.0))
		var yp := 0.18 * (ymax - ymin) + 0.5
		var yr := Vector2(ymin - yp, ymax + yp)
		var to_px := func(p: Vector2) -> Vector2:
			return Vector2(rect.position.x + (p.x - xr.x) / (xr.y - xr.x) * rect.size.x,
				rect.position.y + rect.size.y - (p.y - yr.x) / (yr.y - yr.x) * rect.size.y)
		ex_map = {"rect": rect, "xr": xr, "win": win} if live else {}
		draw_style_box(UITheme.boxc(Color(0.03, 0.08, 0.08, 0.55), 12, Color(0.6, 1, 0.75, 0.25), 1, 0), rect.grow(6))
		preload("math_text.gd").draw_text(self, font, rect.position + Vector2(4, -10), "y 是 t 的二次函數（亮的部分是 t 能到的範圍" + ("，可以直接拖動）" if live else "）"),
			HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(0.7, 1, 0.8, 0.7))
		var ax: float = to_px.call(Vector2(tl, 0)).x
		var bx: float = to_px.call(Vector2(th, 0)).x
		draw_rect(Rect2(ax, rect.position.y, bx - ax, rect.size.y), Color(0.43, 0.9, 0.63, 0.09))
		var y0: float = to_px.call(Vector2(0, 0)).y
		if y0 > rect.position.y and y0 < rect.end.y:
			draw_line(Vector2(rect.position.x, y0), Vector2(rect.end.x, y0), Color(1, 1, 1, 0.4), 1.5)
			preload("math_text.gd").draw_text(self, font, Vector2(rect.end.x - 14, y0 - 6), "t", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 1, 1, 0.7))
		var x0: float = to_px.call(Vector2(0, 0)).x
		if x0 > rect.position.x and x0 < rect.end.x:
			draw_line(Vector2(x0, rect.position.y), Vector2(x0, rect.end.y), Color(1, 1, 1, 0.25), 1.0)
		# 拋物線：範圍外暗、範圍內亮
		for part in 2:
			var pts := PackedVector2Array()
			var a0 := xr.x if part == 0 else tl
			var a1 := xr.y if part == 0 else th
			for i in 161:
				var tt := lerpf(a0, a1, i / 160.0)
				var yy := A * tt * tt + B * tt + C
				if yy < yr.x or yy > yr.y:
					if pts.size() >= 2:
						draw_polyline(UITheme.thin(pts), Color(LEAF.r, LEAF.g, LEAF.b, 0.25 if part == 0 else 1.0), 2.0 if part == 0 else 3.0, true)
					pts = PackedVector2Array()
					continue
				pts.append(to_px.call(Vector2(tt, yy)))
			if pts.size() >= 2:
				draw_polyline(UITheme.thin(pts), Color(LEAF.r, LEAF.g, LEAF.b, 0.25 if part == 0 else 1.0), 2.0 if part == 0 else 3.0, true)
		# 頂點
		var pv: Vector2 = to_px.call(Vector2(tv, A * tv * tv + B * tv + C))
		draw_dashed_line(Vector2(pv.x, rect.position.y), Vector2(pv.x, rect.end.y), Color(1, 1, 1, 0.3), 1.0, 5.0)
		preload("math_text.gd").draw_text(self, font, Vector2(pv.x - 50, rect.position.y + 16), "頂點 t = " + _ftext(tv), HORIZONTAL_ALIGNMENT_CENTER, 100, UITheme.fs(12),
			Color(1, 1, 1, 0.6))
		# t 的範圍端點
		for e in [tl, th]:
			var ep: Vector2 = to_px.call(Vector2(e, 0))
			if ep.x > rect.position.x + 4 and ep.x < rect.end.x - 4 and not has_mark(e):
				preload("math_text.gd").draw_text(self, font, Vector2(ep.x - 40, rect.end.y - 6), "t = " + _ftext(e), HORIZONTAL_ALIGNMENT_CENTER, 80, UITheme.fs(12),
					Color(0.6, 1, 0.75, 0.75))
		# 已經鎖定的極值點
		for mk in marks:
			var mt: float = mk.t
			var mp: Vector2 = to_px.call(Vector2(mt, A * mt * mt + B * mt + C))
			var mc := UITheme.PINK if mk.goal == "max" else UITheme.CYAN
			UITheme.dot(self, mp, 11.0, Color(mc.r, mc.g, mc.b, 0.25))
			UITheme.dot(self, mp, 6.0, mc)
			var up := 28.0 if mk.goal == "max" else -16.0
			preload("math_text.gd").draw_text(self, font, mp + Vector2(-70, up), ("最大" if mk.goal == "max" else "最小") + "（t = " + _ftext(mt) + "）",
				HORIZONTAL_ALIGNMENT_CENTER, 140, UITheme.fs(13), mc)
		if not live:
			return
		# 走過的軌跡＋目前的點
		for q in ex_trail:
			UITheme.dot(self, to_px.call(q), 2.0, Color(1, 0.9, 0.5, 0.25))
		var tt2 := ex_t
		var cur: Vector2 = to_px.call(Vector2(tt2, A * tt2 * tt2 + B * tt2 + C))
		UITheme.dot(self, cur, 13.0 + 2.0 * sin(t * 5.0), Color(1, 0.85, 0.4, 0.25))
		UITheme.dot(self, cur, 7.0, GOLD)
		draw_line(Vector2(cur.x, cur.y), Vector2(cur.x, clampf(y0, rect.position.y, rect.end.y)), Color(1, 0.85, 0.4, 0.4), 1.0)
