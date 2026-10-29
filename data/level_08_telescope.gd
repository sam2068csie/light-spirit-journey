extends "level_04_alchemy.gd"
## 第八大關「位數望遠鏡」（對應講義 2-4：首數與尾數、指數與對數的應用）
## 用法：主選單會自動開啟它。需要同資料夾的 level_04_alchemy.gd、level_03_scale.gd、level_02_forge.gd、
## level_01_light_bridge.gd（共用引擎）與 level08_bank.gd（題庫）。
##
## 新的步驟：
##   ruler  尾數尺：0 到 1 的尺上標著 log 2、log 3……，尾數是一根指針，選出最高位數字
##   grow   成長與衰退：拖動次數 n，病毒分裂、原子熄滅、金幣疊高、豆子長大、星星變亮
## 望遠鏡（舞台下方）會顯示：很大的數有幾位（數字條）、很小的數在小數點後第幾位、同尾數的一家人。

const Bank8 := preload("level08_bank.gd")
const CHAPTERS8 := [
	{"ch": 1, "name": "第一章．位數望遠鏡", "topic": "首數、尾數、位數與首位數字", "color": UITheme.BLUE},
	{"ch": 2, "name": "第二章．成長與衰退", "topic": "倍增、半衰期、複利與星等", "color": UITheme.GOLD},
]
const SKYB := UITheme.BLUE

var ruler_btns: Array = []
var grow_slider: HSlider
var grow_info: MathLabel


func level_id() -> String:
	return "L8"

func level_title() -> String:
	return "位數望遠鏡"

func level_subtitle() -> String:
	return "首數、尾數與應用"

func level_chapters() -> Array:
	return CHAPTERS8

func bank_slots() -> Array:
	return Bank8.slots()

func stage_style() -> Dictionary:
	return {"sky_top": Color("0b1230"), "sky_bot": Color("0a1a24"), "scenery": "none"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．成長與衰退", "button": "進入成長與衰退  ▶",
		"text": "指數成長、指數衰退，都靠 log 來數「要幾次」：\n\n" \
			+ "・病毒倍增：a × 2^{n} ≥ 目標\n" \
			+ "・半衰期：(1/2)^{n} < 目標（除以負數要變向）\n" \
			+ "・複利：本金 × (1 + r)^{n}\n" \
			+ "・星等：差 5 等 = 亮度差 100 倍\n\n" \
			+ "先用 log 算出 n，再拖動時間親眼驗證！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = ScopeView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.log_title = "觀測紀錄"
		fview.work_word = "觀測"
		fview.speed_title = "位數速算"
		(fview as ScaleView).line_toggled.connect(func(): Game.of(self).play("bell", Game.semi(7), -9.0))


func _tv() -> ScopeView:
	return fview as ScopeView


func _speed_gen(kind: String, n: int) -> Array:
	return Bank8.gen_problems(kind, n)


func _forge_step() -> void:
	super()
	if si >= steps.size():
		return
	var st: Dictionary = steps[si]
	if st.kind == "ruler" or st.kind == "grow":
		_clear(predict_box)
		predicting = false
		keypad_on = false
		rank_box.visible = true
		_clear(rank_box)
		task_label.visible = true
		task_label.text = st.q
		if st.kind == "ruler":
			go_btn.visible = false
			_build_ruler(st)
		else:
			go_btn.visible = true
			go_btn.disabled = false
			go_btn.text = "就是這裡！"
			_build_grow(st)


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size() and steps[si].kind == "grow":
		_grow_lock()
		return
	super()


func _step_done(st: Dictionary, why: String) -> void:
	if st.kind == "ruler":
		_tv().ruler_done()
	elif st.kind == "grow":
		_tv().grow_done()
	if st.has("show"):
		_tv().show_scope(st.show)
	super(st, why)


func _custom_reveal(msg: String) -> void:
	if r.type == "forge":
		for j in range(si, steps.size()):
			if steps[j].has("show"):
				_tv().show_scope(steps[j].show)
	super(msg)


# ---------- 尾數尺 ----------

func _build_ruler(st: Dictionary) -> void:
	_tv().begin_ruler(st)
	ruler_btns = []
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	rank_box.add_child(grid)
	for d in range(1, 10):
		var b := Button.new()
		b.text = str(d)
		b.custom_minimum_size = Vector2(0, 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", UITheme.fs(24))
		b.set_meta("silent", true)
		var dd: int = d
		b.pressed.connect(func(): _ruler_pick(dd))
		grid.add_child(b)
		ruler_btns.append(b)
	var tip := MathLabel.new()
	tip.font_size = UITheme.fs(15)
	tip.max_width = 330
	tip.color = UITheme.TEXT_DIM
	tip.text = "log 2 ≈ 0.3010、log 3 ≈ 0.4771、log 7 ≈ 0.8451\nlog 4 = 2log 2、log 5 = 1 − log 2、log 6 = log 2 + log 3……"
	rank_box.add_child(tip)


func _ruler_pick(d: int) -> void:
	if busy:
		return
	var st: Dictionary = steps[si]
	if d == int(st.ans):
		Game.of(self).sfx("correct")
		_step_done(st, "")
		return
	var b: Button = ruler_btns[d - 1]
	b.disabled = true
	b.modulate = Color(1.0, 0.55, 0.6)
	_tv().ruler_wrong(d)
	_wrong(st, "尾數不在 log %d 和 log %d 之間。提示：%s" % [d, d + 1, st.nudge])


# ---------- 成長與衰退 ----------

func _build_grow(st: Dictionary) -> void:
	_tv().begin_grow(st)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	rank_box.add_child(row)
	var nl := Label.new()
	nl.text = st.get("var", "n")
	nl.custom_minimum_size = Vector2(24, 0)
	nl.add_theme_color_override("font_color", SKYB)
	nl.add_theme_font_size_override("font_size", UITheme.fs(20))
	row.add_child(nl)
	grow_slider = UITheme.touch_slider()
	grow_slider.min_value = int(st.nmin)
	grow_slider.max_value = int(st.nmax)
	grow_slider.step = 1
	grow_slider.value = int(st.nmin)
	grow_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grow_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grow_slider.custom_minimum_size = Vector2(0, 28)
	UITheme.tint_slider(grow_slider, SKYB)
	row.add_child(grow_slider)
	UITheme.add_step_buttons(grow_slider, SKYB)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.box(Color(SKYB.r, SKYB.g, SKYB.b, 0.08), 12, Color(SKYB.r, SKYB.g, SKYB.b, 0.35), 1, 10))
	rank_box.add_child(card)
	grow_info = MathLabel.new()
	grow_info.font_size = UITheme.fs(17)
	grow_info.max_width = 320
	grow_info.align_center = true
	card.add_child(grow_info)
	grow_slider.value_changed.connect(_on_grow)
	_on_grow(grow_slider.value)


func _on_grow(v: float) -> void:
	var st: Dictionary = steps[si]
	var n := int(v)
	_tv().grow_n = n
	var val := grow_value(st, n)
	var head: String = st.nlabel % _numtext(n * float(st.get("k", 1.0)))
	if float(st.per) > 0.0:
		head += "（%s %s）" % [_numtext(n * float(st.per)), st.unit]
	var ok := grow_ok(st, val)
	var c := UITheme.GOOD if ok else UITheme.TEXT
	grow_info.text = "%s\n%s ≈ [color=#%s]%s[/color] %s\n[color=#%s]目標：%s %s[/color]" % [head, st.qty, c.to_html(false), sci(val, st), st.qunit,
		UITheme.TEXT_DIM.to_html(false), _cmp_text(st.cmp), sci(float(st.target), st)]
	Game.of(self).note(clampf(0.3 + 0.05 * (n - int(st.nmin)), 0.0, 1.0))


func _grow_lock() -> void:
	var st: Dictionary = steps[si]
	var n := int(grow_slider.value)
	if n == int(st.ans):
		Game.of(self).sfx("correct")
		_step_done(st, "")
		return
	mistakes += 1
	Game.of(self).sfx("wrong")
	_record(st.tag)
	fview.miss()
	story_label.visible = false
	var msg := ""
	if st.cmp == "near":
		msg = "還有更接近目標的。"
	elif grow_ok(st, grow_value(st, n)):
		msg = "已經達到目標了，但這不是「第一次」——往回找找看。"
	else:
		msg = "還沒達到目標喔。"
	_hint(msg + "\n提示：" + st.nudge, "bad")


static func grow_value(st: Dictionary, n: int) -> float:
	return float(st.a0) * pow(float(st.r), n)


static func grow_ok(st: Dictionary, v: float) -> bool:
	var tg := float(st.target)
	match st.cmp:
		"ge":
			return v >= tg * (1.0 - 1e-12)
		"gt":
			return v > tg * (1.0 + 1e-12)
		"le":
			return v <= tg * (1.0 + 1e-12)
		"lt":
			return v < tg * (1.0 - 1e-12)
	return false


## 第一次達到目標的 n（near：最接近的 n）
static func grow_answer(st: Dictionary) -> int:
	var best := int(st.nmin)
	var bd := INF
	for n in range(int(st.nmin), int(st.nmax) + 1):
		var v := grow_value(st, n)
		if st.cmp == "near":
			var d := absf(log(v) - log(float(st.target)))
			if d < bd - 1e-9:
				bd = d
				best = n
		elif grow_ok(st, v):
			return n
	return best if st.cmp == "near" else -1


static func _cmp_text(c: String) -> String:
	return {"ge": "≥", "gt": ">", "le": "≤", "lt": "<", "near": "≈"}.get(c, "")


static func _numtext(v: float) -> String:
	if absf(v - roundf(v)) < 1e-9:
		return str(int(roundf(v)))
	return "%.1f" % v


## 科學記號（不大不小的數就直接寫）
static func sci(v: float, st: Dictionary = {}) -> String:
	if v <= 0.0:
		return "0"
	if st.get("model", "") == "decay" and v >= 0.001 and v <= 1.0:
		return ("%.2f" % (v * 100.0)).rstrip("0").rstrip(".") + "%"
	var e := int(floor(log(v) / log(10.0) + 1e-9))
	if e >= -2 and e <= 4:
		var digits := clampi(2 - e, 0, 4)
		var s := ("%." + str(digits) + "f") % v
		if s.contains("."):
			s = s.rstrip("0").rstrip(".")
		return s
	var m := v / pow(10.0, e)
	return ("%.2f × 10^{%d}" % [m, e]).replace("-", "−")


# ================= 天文台（畫在舞台上） =================

class ScopeView extends AlchemyView:
	const SKYB := UITheme.BLUE
	const STARC := UITheme.GOLD_PALE
	const LOGS := [0.0, 0.3010, 0.4771, 0.6020, 0.6990, 0.7781, 0.8451, 0.9030, 0.9542, 1.0]

	var mode := ""                 # scope、ruler、grow
	var scope := {}
	var scope_t := -10.0
	var ruler_st := {}
	var ruler_ok_t := -10.0
	var ruler_bad: Array = []
	var grow_st := {}
	var grow_n := 0
	var grow_shown := 0.0
	var grow_t := -10.0

	func reset_alchemy() -> void:
		super()
		mode = ""
		scope = {}
		ruler_st = {}
		ruler_bad = []
		grow_st = {}

	func show_scope(d: Dictionary) -> void:
		scope = d
		scope_t = t
		mode = "scope"

	func begin_ruler(st: Dictionary) -> void:
		ruler_st = st
		ruler_ok_t = -10.0
		ruler_bad = []
		mode = "ruler"

	func ruler_wrong(d: int) -> void:
		ruler_bad.append(d)

	func ruler_done() -> void:
		ruler_ok_t = t
		var R := _rect()
		_burst(Vector2(_rx(R, float(ruler_st.alpha)), R.position.y + 90), GOLD, 22)

	func begin_grow(st: Dictionary) -> void:
		grow_st = st
		grow_n = int(st.nmin)
		grow_shown = float(grow_n)
		grow_t = -10.0
		mode = "grow"

	func grow_done() -> void:
		grow_t = t
		_burst(_rect().get_center(), GOLD, 28)

	func _process(delta: float) -> void:
		grow_shown = lerpf(grow_shown, float(grow_n), 1.0 - exp(-8.0 * delta))
		super(delta)

	func _rect() -> Rect2:
		return Rect2(36, size.y - 214, size.x - 72, 190)

	func _graph_on() -> bool:
		return mode != "" or super()

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		match mode:
			"scope":
				_draw_scope(font, rect)
			"ruler":
				_draw_ruler(font, rect)
			"grow":
				_draw_grow(font, rect)
			_:
				super(font, rect)

	## 天文台的夜空：星星、月亮、角落的望遠鏡
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("0a1030"), Color("0a1030"), Color("0b1c28"), Color("0b1c28")]))
		for i in 90:
			var p := Vector2(fposmod(i * 0.7548777, 1.0) * w, fposmod(i * 0.5698403 + 0.07, 1.0) * h * 0.9)
			# 星星避開中間寫算式的地方（不然會被看成小數點）
			if p.x > 56.0 and p.x < w - 56.0 and p.y > 56.0 and p.y < h - 230.0:
				continue
			var a := 0.15 + 0.25 * (0.5 + 0.5 * sin(t * (1.0 + fposmod(i * 0.13, 1.0)) + i))
			UITheme.dot(self, p, 0.8 + fposmod(i * 0.37, 1.0) * 1.2, Color(1, 1, 0.95, a))
		# 小山丘＋望遠鏡剪影
		var hill := PackedVector2Array([Vector2(0, h), Vector2(0, h - 26)])
		for i in 21:
			var x := w * i / 20.0
			hill.append(Vector2(x, h - 26 - 10.0 * sin(i * 0.7) - 6.0 * sin(i * 1.9)))
		hill.append(Vector2(w, h))
		draw_colored_polygon(hill, Color(0.05, 0.08, 0.12, 0.9))
		if mode == "":
			var base := Vector2(70, h - 32)
			draw_line(base, base + Vector2(-16, 26), Color(0.6, 0.7, 0.9, 0.5), 3.0)
			draw_line(base, base + Vector2(16, 26), Color(0.6, 0.7, 0.9, 0.5), 3.0)
			var dir := Vector2(cos(-0.9 + 0.05 * sin(t * 0.5)), sin(-0.9 + 0.05 * sin(t * 0.5)))
			draw_line(base - dir * 18, base + dir * 46, Color(0.7, 0.8, 1.0, 0.6), 9.0)
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	func _panel(font: Font, R: Rect2, title: String) -> void:
		draw_style_box(UITheme.boxc(Color(0.03, 0.05, 0.12, 0.72), 12, Color(SKYB.r, SKYB.g, SKYB.b, 0.3), 1, 0), R.grow(6))
		draw_string(font, R.position + Vector2(4, -10), title, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(0.8, 0.88, 1.0, 0.8))

	# ---------- 望遠鏡：數字條、小數、同尾數 ----------

	func _draw_scope(font: Font, R: Rect2) -> void:
		match scope.get("kind", ""):
			"strip":
				_draw_strip(font, R)
			"tiny":
				_draw_tiny(font, R)
			"family":
				_draw_family(font, R)

	func _box(font: Font, c: Vector2, w: float, ch: String, col: Color, a: float) -> void:
		draw_style_box(UITheme.boxc(Color(col.r, col.g, col.b, 0.12 * a), 6, Color(col.r, col.g, col.b, 0.7 * a), 2, 0),
			Rect2(c.x - w / 2.0, c.y - 18, w - 2, 36))
		draw_string(font, Vector2(c.x - w / 2.0, c.y + 8), ch, HORIZONTAL_ALIGNMENT_CENTER, w - 2, int(minf(UITheme.fs(24), w * 0.8)), Color(col.r, col.g, col.b, a))

	## 很大的數：一排數字格子，第一格是最高位數字
	func _draw_strip(font: Font, R: Rect2) -> void:
		var n: int = scope.digits
		var lead: String = scope.lead
		_panel(font, R, "位數望遠鏡：%s 有幾位？" % [scope.get("label", "N")] if lead == "?" else "位數望遠鏡")
		var full := n <= 24
		var shown := n if full else 18
		var bw := minf(36.0, (R.size.x - 140.0) / float(shown + (0 if full else 1)))
		var x0 := R.position.x + 120.0
		var y := R.position.y + 78
		MathLabel.draw_on(self, font, R.position.x + 60, y + 8, str(scope.get("label", "N")) + " =", UITheme.fs(20), Color(1, 1, 1, 0.9))
		var k := 0
		for i in shown + (0 if full else 1):
			var a := clampf((t - scope_t - i * 0.025) / 0.2, 0.0, 1.0)
			var c := Vector2(x0 + bw * (i + 0.5), y)
			if not full and i == 12:
				draw_string(font, Vector2(c.x - bw / 2.0, y + 8), "⋯", HORIZONTAL_ALIGNMENT_CENTER, bw, UITheme.fs(24), Color(1, 1, 1, 0.7 * a))
				continue
			if i == 0:
				var pop := clampf(1.0 - (t - scope_t) / 0.5, 0.0, 1.0)
				_box(font, c, bw, lead, GOLD if lead != "?" else Color(1, 1, 1, 0.8), a)
				if lead != "?" and pop > 0.0:
					UITheme.dot(self, c, 26.0 * (1.0 + pop), Color(GOLD.r, GOLD.g, GOLD.b, 0.25 * pop))
			else:
				_box(font, c, bw, "?", SKYB, a * 0.7)
			k += 1
		var x1 := x0 + bw * (shown + (0 if full else 1))
		draw_line(Vector2(x0, y + 30), Vector2(x0, y + 38), Color(1, 1, 1, 0.5), 1.5)
		draw_line(Vector2(x1 - 2, y + 30), Vector2(x1 - 2, y + 38), Color(1, 1, 1, 0.5), 1.5)
		draw_line(Vector2(x0, y + 38), Vector2(x1 - 2, y + 38), Color(1, 1, 1, 0.5), 1.5)
		draw_string(font, Vector2(x0, y + 62), "共 %d 位" % n, HORIZONTAL_ALIGNMENT_CENTER, x1 - x0, UITheme.fs(17), Color(1, 0.95, 0.75, 0.95))
		if lead != "?":
			draw_string(font, Vector2(x0 - 30, y - 30), "最高位數字 %s" % lead, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(GOLD.r, GOLD.g, GOLD.b, 0.9))

	## 很小的數：0.000…0d
	func _draw_tiny(font: Font, R: Rect2) -> void:
		var place: int = scope.place
		var lead: String = scope.lead
		_panel(font, R, "小數望遠鏡：第一個不是 0 的數字在第幾位？")
		var cells := place + 2
		var bw := minf(34.0, (R.size.x - 190.0) / float(cells + 1))
		var y := R.position.y + 78
		MathLabel.draw_on(self, font, R.position.x + 60, y + 8, str(scope.get("label", "N")) + " =", UITheme.fs(20), Color(1, 1, 1, 0.9))
		var x0 := R.position.x + 124.0
		draw_string(font, Vector2(x0, y + 8), "0.", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(24), Color(1, 1, 1, 0.9))
		x0 += 26.0
		for i in cells:
			var a := clampf((t - scope_t - i * 0.03) / 0.2, 0.0, 1.0)
			var c := Vector2(x0 + bw * (i + 0.5), y)
			if i < place - 1:
				_box(font, c, bw, "0", Color(1, 1, 1, 0.6), a)
			elif i == place - 1:
				_box(font, c, bw, lead, GOLD if lead != "?" else Color(1, 1, 1, 0.85), a)
				draw_string(font, Vector2(c.x - 40, y + 44), "第 %d 位" % place, HORIZONTAL_ALIGNMENT_CENTER, 80, UITheme.fs(15), Color(GOLD.r, GOLD.g, GOLD.b, a))
			else:
				_box(font, c, bw, "?", SKYB, a * 0.6)
			if i < place - 1 and (i == 0 or (i + 1) % 5 == 0):
				draw_string(font, Vector2(c.x - 20, y + 36), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 40, UITheme.fs(12), Color(1, 1, 1, 0.45))
		draw_string(font, Vector2(R.position.x, R.end.y - 14), "首數 −%d ⇒ 小數點後第 %d 位開始不為 0" % [place, place], HORIZONTAL_ALIGNMENT_CENTER, R.size.x, UITheme.fs(15),
			Color(1, 0.95, 0.75, 0.85))

	## 同一個尾數的一家人：數字一樣，只差小數點的位置
	func _draw_family(font: Font, R: Rect2) -> void:
		_panel(font, R, "同一家人：數字排列一樣 ⇒ 尾數一樣，只有首數不同")
		var rows: Array = scope.rows
		var dy := (R.size.y - 20.0) / float(rows.size())
		for i in rows.size():
			var a := clampf((t - scope_t - i * 0.15) / 0.3, 0.0, 1.0)
			var row: Array = rows[i]
			var y := R.position.y + 24 + dy * i + dy * 0.5
			draw_string(font, Vector2(R.position.x + 20, y), row[0], HORIZONTAL_ALIGNMENT_RIGHT, 150, UITheme.fs(20), Color(1, 1, 1, a))
			MathLabel.draw_on(self, font, R.position.x + 340, y, "log = [color=#%s]%s[/color] + [color=#%s]%s[/color]" % [
				SKYB.to_html(false), row[1], GOLD.to_html(false), row[2]], UITheme.fs(20), Color(1, 1, 1, a))
		draw_string(font, Vector2(R.end.x - 150, R.position.y + 20), "■ 首數", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), SKYB)
		draw_string(font, Vector2(R.end.x - 80, R.position.y + 20), "■ 尾數", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), GOLD)

	# ---------- 尾數尺 ----------

	func _rx(R: Rect2, v: float) -> float:
		return R.position.x + 30.0 + v * (R.size.x - 60.0)

	func _draw_ruler(font: Font, R: Rect2) -> void:
		_panel(font, R, "尾數尺：尾數落在哪兩個 log k 之間？")
		var done := ruler_ok_t > 0.0
		var y := R.position.y + 104
		var alpha: float = ruler_st.alpha
		var ans: int = ruler_st.ans
		# 每一格
		for k in range(1, 10):
			var a := _rx(R, LOGS[k - 1])
			var b := _rx(R, LOGS[k])
			var col := Color(1, 1, 1, 0.04 if k % 2 == 0 else 0.08)
			if ruler_bad.has(k):
				col = Color(UITheme.BAD.r, UITheme.BAD.g, UITheme.BAD.b, 0.2)
			if done and k == ans:
				col = Color(GOLD.r, GOLD.g, GOLD.b, 0.25 + 0.1 * sin(t * 5.0))
			draw_rect(Rect2(a, y - 16, b - a, 32), col)
			if done:
				draw_string(font, Vector2(a, y + 8), str(k), HORIZONTAL_ALIGNMENT_CENTER, b - a, UITheme.fs(17),
					GOLD if k == ans else Color(1, 1, 1, 0.55))
		draw_line(Vector2(_rx(R, 0.0), y + 16), Vector2(_rx(R, 1.0), y + 16), Color(1, 1, 1, 0.7), 2.0)
		# 刻度：log k
		for k in range(0, 10):
			var x := _rx(R, LOGS[k])
			draw_line(Vector2(x, y - 16), Vector2(x, y + 22), Color(1, 1, 1, 0.7), 1.5)
			var lab := "0" if k == 0 else ("1" if k == 9 else "log %d" % (k + 1))
			var up := k % 2 == 1
			draw_string(font, Vector2(x - 30, y + (40 if not up else -24)), lab, HORIZONTAL_ALIGNMENT_CENTER, 60, UITheme.fs(12), Color(0.85, 0.9, 1.0, 0.85))
			if k > 0 and k < 9:
				draw_string(font, Vector2(x - 30, y + (54 if not up else -38)), "%.3f" % LOGS[k], HORIZONTAL_ALIGNMENT_CENTER, 60, UITheme.fs(12), Color(1, 1, 1, 0.4))
		# 指針
		var px := _rx(R, alpha)
		var bob := 3.0 * sin(t * 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(px, y - 18), Vector2(px - 8, y - 32 + bob), Vector2(px + 8, y - 32 + bob)]), GOLD)
		draw_line(Vector2(px, y - 18), Vector2(px, y + 16), GOLD, 2.5)
		var tl := "尾數 %s" % str(snappedf(alpha, 0.0001))
		draw_string(font, Vector2(px - 60, R.position.y + 30 + bob), tl, HORIZONTAL_ALIGNMENT_CENTER, 120, UITheme.fs(15), GOLD)

	# ---------- 成長與衰退 ----------

	func _draw_grow(font: Font, R: Rect2) -> void:
		var st := grow_st
		var model: String = st.model
		var titles := {"cells": "顯微鏡：數量一次次翻倍", "decay": "原子：每次剩下一部分", "money": "存錢筒：利滾利", "plant": "魔法豆：每天長高",
			"star": "星空：星等越大越暗"}
		_panel(font, R, titles.get(model, ""))
		var S := Rect2(R.position.x + 8, R.position.y + 8, R.size.x * 0.56, R.size.y - 16)
		var G := Rect2(S.end.x + 18, R.position.y + 22, R.end.x - S.end.x - 34, R.size.y - 44)
		var n := grow_shown
		var ratio := pow(float(st.r), n - float(st.nmin))
		match model:
			"cells":
				_scene_cells(font, S, n, st)
			"decay":
				_scene_decay(font, S, n, st)
			"money":
				_scene_money(font, S, ratio)
			"plant":
				_scene_plant(font, S, n, st)
			"star":
				_scene_star(font, S, n, st)
		_draw_gauge(font, G, st)

	## 右邊的數量級刻度（log 尺）：目前的值和目標
	func _draw_gauge(font: Font, G: Rect2, st: Dictionary) -> void:
		var v0 := log(float(st.a0) * pow(float(st.r), int(st.nmin))) / log(10.0)
		var v1 := log(float(st.a0) * pow(float(st.r), int(st.nmax))) / log(10.0)
		var lo := minf(v0, v1)
		var hi := maxf(v0, v1)
		var tgl := log(float(st.target)) / log(10.0)
		lo = minf(lo, tgl)
		hi = maxf(hi, tgl)
		var to_x := func(lv: float) -> float:
			return G.position.x + (lv - lo) / maxf(hi - lo, 1e-6) * G.size.x
		var y := G.position.y + 58
		draw_line(Vector2(G.position.x, y), Vector2(G.end.x, y), Color(1, 1, 1, 0.5), 2.0)
		if hi - lo < 2.0:
			# 範圍不到兩格：標 1、2、3、5 × 10^{k} 這些好讀的數
			for k in range(int(floor(lo)) - 1, int(ceil(hi)) + 1):
				for m in [1.0, 2.0, 3.0, 5.0]:
					var lv := log(m) / log(10.0) + k
					if lv < lo - 1e-6 or lv > hi + 1e-6:
						continue
					var x2: float = to_x.call(lv)
					draw_line(Vector2(x2, y - 6), Vector2(x2, y + 6), Color(1, 1, 1, 0.6), 1.5)
					draw_string(font, Vector2(x2 - 30, y + 24), _short(m * pow(10.0, k)), HORIZONTAL_ALIGNMENT_CENTER, 60, UITheme.fs(12), Color(1, 1, 1, 0.6))
		else:
			var step := 1 if hi - lo <= 9 else 2
			for k in range(int(ceil(lo)), int(floor(hi)) + 1):
				if k % step != 0:
					continue
				var x: float = to_x.call(float(k))
				draw_line(Vector2(x, y - 6), Vector2(x, y + 6), Color(1, 1, 1, 0.6), 1.5)
				MathLabel.draw_on(self, font, x, y + 24, "10^{%d}" % k if k != 0 else "1", UITheme.fs(12), Color(1, 1, 1, 0.6))
		var tx: float = to_x.call(tgl)
		draw_dashed_line(Vector2(tx, y - 30), Vector2(tx, y + 30), Color(1, 0.55, 0.45, 0.9), 2.0, 5.0)
		draw_string(font, Vector2(tx - 40, y - 36), "目標", HORIZONTAL_ALIGNMENT_CENTER, 80, UITheme.fs(13), Color(1, 0.6, 0.5))
		var cur := log(float(st.a0) * pow(float(st.r), grow_shown)) / log(10.0)
		var cx: float = to_x.call(cur)
		UITheme.dot(self, Vector2(cx, y), 10.0 + 2.0 * sin(t * 5.0), Color(SKYB.r, SKYB.g, SKYB.b, 0.25))
		UITheme.dot(self, Vector2(cx, y), 6.0, GOLD if grow_t > 0.0 else SKYB)
		draw_string(font, Vector2(G.position.x, G.end.y - 4), "log 尺：每格 ×10", HORIZONTAL_ALIGNMENT_CENTER, G.size.x, UITheme.fs(12), Color(1, 1, 1, 0.45))

	func _scene_cells(font: Font, S: Rect2, n: float, st: Dictionary) -> void:
		var c := S.get_center() + Vector2(0, 4)
		var rr := minf(S.size.x, S.size.y) * 0.46
		UITheme.dot(self, c, rr, Color(0.4, 0.8, 0.9, 0.08))
		draw_arc(c, rr, 0, TAU, 64, Color(0.7, 0.95, 1.0, 0.5), 2.0, true)
		var mult := pow(float(st.r), n - float(st.nmin))
		var shown := clampi(int(roundf(mult)), 1, 128)
		for i in shown:
			var ang := i * 2.39996
			var rad := rr * 0.88 * sqrt((i + 0.5) / 128.0)
			var p := c + Vector2(cos(ang), sin(ang)) * rad + Vector2(sin(t * 2.0 + i), cos(t * 1.7 + i)) * 1.5
			var sz := 4.5 if shown < 40 else 3.2
			UITheme.dot(self, p, sz, Color(0.55, 1.0, 0.7, 0.9))
			UITheme.dot(self, p + Vector2(-1, -1), sz * 0.4, Color(1, 1, 1, 0.5))
		if mult > 128.5:
			MathLabel.draw_on(self, font, S.get_center().x, S.end.y - 4, "每一顆 ≈ %s %s" % [_short(mult / 128.0 * float(st.a0)), st.qunit], UITheme.fs(13),
				Color(1, 0.95, 0.7, 0.85))

	func _scene_decay(font: Font, S: Rect2, n: float, st: Dictionary) -> void:
		var frac := pow(float(st.r), n - float(st.nmin))
		var lit := frac * 100.0
		var cell := minf(S.size.x / 10.0, (S.size.y - 22.0) / 10.0)
		var o := Vector2(S.get_center().x - cell * 5.0, S.position.y + 4)
		for i in 100:
			var p := o + Vector2((i % 10 + 0.5) * cell, (i / 10 + 0.5) * cell)
			var on := float(i) < lit - 0.5
			var part := clampf(lit - float(i), 0.0, 1.0)
			if on or part > 0.0:
				var a := 1.0 if on else part
				UITheme.dot(self, p, cell * 0.34, Color(0.6, 1.0, 0.55, 0.25 * a))
				UITheme.dot(self, p, cell * 0.22, Color(0.75, 1.0, 0.6, a))
			else:
				UITheme.dot(self, p, cell * 0.2, Color(1, 1, 1, 0.10))
		draw_string(font, Vector2(S.position.x, S.end.y - 2), "亮著的原子：剩下 %s" % ("%.2f" % lit).rstrip("0").rstrip(".") + "%", HORIZONTAL_ALIGNMENT_CENTER,
			S.size.x, UITheme.fs(13), Color(1, 0.95, 0.7, 0.85))

	func _scene_money(font: Font, S: Rect2, ratio: float) -> void:
		var coins := clampi(int(roundf(ratio * 6.0)), 1, 22)
		var base := Vector2(S.get_center().x, S.end.y - 12)
		for i in coins:
			var y := base.y - i * 7.0
			var wob := 2.0 * sin(i * 1.3)
			draw_rect(Rect2(base.x - 34 + wob, y - 6, 68, 8), Color(1, 0.8, 0.3))
			draw_line(Vector2(base.x - 34 + wob, y - 6), Vector2(base.x + 34 + wob, y - 6), Color(1, 0.95, 0.6), 1.5)
		var ref := base.y - 12.0 * 7.0
		draw_dashed_line(Vector2(base.x - 60, ref), Vector2(base.x + 60, ref), Color(1, 0.55, 0.45, 0.8), 1.5, 5.0)
		draw_string(font, Vector2(base.x + 62, ref + 4), "2 倍", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(12), Color(1, 0.6, 0.5))
		draw_string(font, Vector2(S.position.x, S.position.y + 14), "本金的 %.2f 倍" % ratio, HORIZONTAL_ALIGNMENT_CENTER, S.size.x, UITheme.fs(15), Color(1, 0.95, 0.7, 0.9))

	func _scene_plant(font: Font, S: Rect2, n: float, st: Dictionary) -> void:
		var ratio := pow(float(st.r), n - float(st.nmin))
		var ground := S.end.y - 8
		var top := S.position.y + 16
		var hh := clampf(ratio / float(st.target) * 0.8, 0.02, 1.15) * (ground - top)
		var x := S.get_center().x
		draw_rect(Rect2(S.position.x, ground, S.size.x, 6), Color(0.45, 0.3, 0.2))
		var pts := PackedVector2Array()
		for i in 25:
			var u := i / 24.0
			pts.append(Vector2(x + 10.0 * sin(u * 9.0 + t), ground - hh * u))
		draw_polyline(UITheme.thin(pts), Color(0.4, 0.9, 0.4), 4.0, true)
		for i in range(1, 6):
			var p: Vector2 = pts[mini(i * 4, 24)]
			var sgn := 1.0 if i % 2 == 0 else -1.0
			draw_colored_polygon(PackedVector2Array([p, p + Vector2(18 * sgn, -6), p + Vector2(10 * sgn, 4)]), Color(0.5, 1.0, 0.5))
		var ty := ground - 0.8 * (ground - top)
		draw_dashed_line(Vector2(S.position.x + 10, ty), Vector2(S.end.x - 10, ty), Color(1, 0.55, 0.45, 0.8), 1.5, 5.0)
		draw_string(font, Vector2(S.end.x - 70, ty - 4), "10 倍", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(12), Color(1, 0.6, 0.5))
		draw_string(font, Vector2(S.position.x + 6, S.position.y + 14), "%.2f 倍" % ratio, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 0.95, 0.7, 0.9))

	func _scene_star(font: Font, S: Rect2, n: float, _st: Dictionary) -> void:
		var bright := float(_st.a0) * pow(float(_st.r), n)
		var vega := Vector2(S.position.x + S.size.x * 0.25, S.get_center().y)
		var cur := Vector2(S.position.x + S.size.x * 0.72, S.get_center().y)
		_star(vega, 1.0)
		draw_string(font, Vector2(vega.x - 50, S.end.y - 6), "織女星（0 等）", HORIZONTAL_ALIGNMENT_CENTER, 100, UITheme.fs(12), Color(1, 1, 1, 0.7))
		_star(cur, bright)
		draw_string(font, Vector2(cur.x - 60, S.end.y - 6), "%s 等星" % _numtext(roundf(n) * float(_st.get("k", 1.0))).replace("-", "−"), HORIZONTAL_ALIGNMENT_CENTER, 120, UITheme.fs(12), Color(1, 1, 1, 0.7))

	func _star(p: Vector2, b: float) -> void:
		var s := clampf(pow(b, 0.25), 0.15, 2.0)
		var a := clampf(0.15 + 0.85 * pow(b, 0.35), 0.12, 1.0)
		for k in 4:
			UITheme.dot(self, p, 34.0 * s * (1.0 - k * 0.22), Color(STARC.r, STARC.g, STARC.b, 0.08 * a * (k + 1)))
		var tw := 1.0 + 0.08 * sin(t * 6.0 + p.x)
		draw_line(p - Vector2(30 * s * tw, 0), p + Vector2(30 * s * tw, 0), Color(STARC.r, STARC.g, STARC.b, 0.7 * a), 2.0)
		draw_line(p - Vector2(0, 30 * s * tw), p + Vector2(0, 30 * s * tw), Color(STARC.r, STARC.g, STARC.b, 0.7 * a), 2.0)
		UITheme.dot(self, p, 7.0 * s, Color(1, 1, 0.95, a))

	static func _numtext(v: float) -> String:
		if absf(v - roundf(v)) < 1e-9:
			return str(int(roundf(v)))
		return "%.1f" % v

	static func _short(v: float) -> String:
		if v >= 1.0 and v < 1000.0:
			return str(int(roundf(v))) if absf(v - roundf(v)) < 0.05 else "%.1f" % v
		if v >= 0.001 and v < 1.0:
			return ("%.3f" % v).rstrip("0").rstrip(".")
		var e := int(floor(log(v) / log(10.0)))
		return ("%.1f × 10^{%d}" % [v / pow(10.0, e), e]).replace("-", "−")
