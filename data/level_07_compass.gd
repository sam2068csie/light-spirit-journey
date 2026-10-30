extends "level_04_alchemy.gd"
## 第七大關「正負羅盤」（對應講義 重點四：對數不等式與極值）
## 用法：主選單會自動開啟它。需要同資料夾的 level_04_alchemy.gd、level_03_scale.gd、level_02_forge.gd、
## level_01_light_bridge.gd（共用引擎）與 level07_bank.gd（題庫）。
##
## 沿用前面的步驟（選擇、數字鍵盤、施放法則、排序、數線、符號表、拖動 t 找極值），再加上：
##   compass  正負判斷：左邊列出每個 log_{a} b 的底數、真數各和 1 比的結果，
##            學生用口訣「真、底同時大於 1 或同時小於 1 ⇒ 正，反之為負」判斷每個是正是負。

const Bank7 := preload("level07_bank.gd")
const CHAPTERS7 := [
	{"ch": 1, "name": "第一章．正負羅盤", "topic": "log 的正負、比大小與對數不等式", "color": UITheme.GOOD},
	{"ch": 2, "name": "第二章．極值羅盤", "topic": "換元、取對數與算幾求極值", "color": UITheme.CYAN},
]
const MINT := UITheme.GOOD

var compass_vals: Array = []
var compass_btns: Array = []


func level_id() -> String:
	return "L7"

func level_title() -> String:
	return "正負羅盤"

func level_subtitle() -> String:
	return "對數不等式與極值"

func level_chapters() -> Array:
	return CHAPTERS7

func bank_slots() -> Array:
	return Bank7.slots()

func stage_style() -> Dictionary:
	return {"sky_top": Color("0b1f2a"), "sky_bot": Color("0a1420"), "scenery": "none", "ambient": "currents"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．極值羅盤", "button": "進入極值羅盤  ▶",
		"text": "找極值的三種羅盤：\n\n" \
			+ "・令 t = log_{a} x：x 的範圍 ⇒ t 的範圍（底數 < 1 會顛倒）\n" \
			+ "・x^{(含 log x)}：先兩邊取 log\n" \
			+ "・log x + log y = log (xy)：用算幾不等式\n\n" \
			+ "拖動 t，親眼找到最高點和最低點！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = CompassView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		(fview as ScaleView).line_toggled.connect(func(): Game.of(self).play("bell", Game.semi(7), -9.0))
		(fview as ScaleView).t_dragged.connect(func(tv: float):
			if ex_slider != null and is_instance_valid(ex_slider):
				ex_slider.value = snappedf(tv, EX_STEP) if absf(tv - ScaleView.t_window(_sv().explore).x) > EX_STEP / 2.0 else tv)


func _cv() -> CompassView:
	return fview as CompassView


func _forge_step() -> void:
	super()
	if si >= steps.size():
		return
	var st: Dictionary = steps[si]
	if st.kind == "compass":
		_clear(predict_box)
		predicting = false
		keypad_on = false
		rank_box.visible = true
		_clear(rank_box)
		task_label.visible = true
		task_label.text = st.q
		go_btn.visible = true
		go_btn.disabled = false
		go_btn.text = "確認"
		_build_compass(st)


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size() and steps[si].kind == "compass":
		_compass_submit()
		return
	super()


func _custom_reveal(msg: String) -> void:
	if r.type == "forge":
		for j in range(si, steps.size()):
			if steps[j].kind == "compass":
				_cv().begin_compass(steps[j])
				_cv().compass_vals = compass_answers(steps[j])
				_cv().compass_done()
	super(msg)


## 每個 log_{a} b 的正負（1 或 −1）
static func compass_answers(st: Dictionary) -> Array:
	var out := []
	for it in st.items:
		out.append(1 if (float(it.a) - 1.0) * (float(it.b) - 1.0) > 0.0 else -1)
	return out


func _build_compass(st: Dictionary) -> void:
	compass_vals = []
	compass_btns = []
	_cv().begin_compass(st)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	rank_box.add_child(grid)
	for i in st.items.size():
		compass_vals.append(0)
		var b := MathLabel.make_button(st.items[i].text, 17, Vector2(0, 46))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.set_meta("silent", true)
		var idx: int = i
		b.pressed.connect(func():
			compass_vals[idx] = 1 if compass_vals[idx] != 1 else -1
			Game.of(self).play("bell", Game.semi(9 if compass_vals[idx] == 1 else 4), -10.0)
			_refresh_compass())
		grid.add_child(b)
		compass_btns.append(b)
	if st.items.size() % 2 == 1:
		grid.add_child(Control.new())
	var tip := Label.new()
	tip.text = "看左邊的表：底數、真數各和 1 比。同時大於 1 或同時小於 1 ⇒ 正，反之為負。"
	tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rank_box.add_child(tip)
	_refresh_compass()


func _refresh_compass(bad: Array = []) -> void:
	var st: Dictionary = steps[si]
	for i in compass_btns.size():
		var b: Button = compass_btns[i]
		var v: int = compass_vals[i]
		var mark := "？" if v == 0 else ("＋" if v == 1 else "−")
		var c := UITheme.TEXT_DIM if v == 0 else (UITheme.ACCENT if v == 1 else UITheme.CYAN)
		if bad.has(i):
			c = UITheme.BAD
		(b.get_node("Math") as MathLabel).text = "%s　[color=#%s]%s[/color]" % [st.items[i].text, c.to_html(false), mark]
		var sb := UITheme.box(Color(c.r, c.g, c.b, 0.10), 10, c, 2 if v != 0 or bad.has(i) else 1, 4)
		for s in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(s, sb)
	_cv().compass_vals = compass_vals.duplicate()


func _compass_submit() -> void:
	var st: Dictionary = steps[si]
	var ans := compass_answers(st)
	var bad := []
	for i in ans.size():
		if compass_vals[i] != ans[i]:
			bad.append(i)
	if bad.is_empty():
		Game.of(self).sfx("correct")
		_cv().compass_vals = compass_vals.duplicate()
		_cv().compass_done()
		go_btn.visible = false
		_step_done(st, "")
		return
	_refresh_compass(bad)
	_wrong(st, "紅色的判斷不對。提示：" + st.nudge)


# ================= 星空羅盤（畫在舞台上） =================

class CompassView extends AlchemyView:
	const MINT := UITheme.GOOD
	const SKY := UITheme.CYAN

	var compass_on := false
	var compass_items: Array = []
	var compass_vals: Array = []
	var compass_t := -10.0

	func reset_alchemy() -> void:
		super()
		compass_on = false
		compass_items = []
		compass_vals = []
		compass_t = -10.0

	func begin_compass(st: Dictionary) -> void:
		compass_on = true
		compass_items = st.items
		compass_vals = []
		compass_t = -10.0

	func compass_done() -> void:
		compass_t = t
		_burst(_plane_rect().get_center(), MINT, 26)

	func _graph_on() -> bool:
		return compass_on or super()

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if compass_on:
			_draw_compass_plane(font, rect)
		else:
			super(font, rect)

	func _plane_rect() -> Rect2:
		return Rect2(36, size.y - 214, size.x - 72, 190)

	## 星空背景＋慢慢轉的羅盤玫瑰
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("0a1a26"), Color("0a1a26"), Color("0b1f1c"), Color("0b1f1c")]))
		for i in 70:
			var p := Vector2(fposmod(i * 0.7548777, 1.0) * w, fposmod(i * 0.5698403 + 0.11, 1.0) * h)
			var a := 0.12 + 0.18 * (0.5 + 0.5 * sin(t * 1.5 + i * 2.3))
			UITheme.dot(self, p, 1.0 + fposmod(i * 0.29, 1.0), Color(0.8, 1, 0.95, a))
		var c := Vector2(w / 2.0, h * 0.55)
		var rad := minf(w, h) * 0.40
		var col := Color(MINT.r, MINT.g, MINT.b, 0.07)
		draw_arc(c, rad, 0, TAU, 96, col, 2.0, true)
		draw_arc(c, rad * 0.72, 0, TAU, 96, col, 1.2, true)
		var rot := t * 0.04
		for k in 8:
			var ang := rot + k * TAU / 8.0
			var long := rad * (0.95 if k % 2 == 0 else 0.6)
			var tip := c + Vector2(cos(ang), sin(ang)) * long
			var side := Vector2(cos(ang + PI / 2.0), sin(ang + PI / 2.0)) * rad * 0.06
			draw_polyline(PackedVector2Array([c + side, tip, c - side]), col, 1.4, true)
		for k in 4:
			var ang := rot + k * PI / 2.0 - PI / 2.0
			var p := c + Vector2(cos(ang), sin(ang)) * (rad + 16)
			draw_string(get_theme_default_font(), p + Vector2(-8, 6), ["N", "E", "S", "W"][k], HORIZONTAL_ALIGNMENT_CENTER, 16, UITheme.fs(15), col * 2.0)
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	## 角落的不等號羅盤：不畫（會壓到題目），變向的提示寫在推導紀錄裡
	func _draw_scale(_c: Vector2) -> void:
		pass

	## 「真底比 1」表：每個 log 的底數、真數各和 1 比，再用口訣判斷正負
	##   口訣：真、底同時大於 1 或同時小於 1 ⇒ 正；一個大於 1、一個小於 1 ⇒ 負
	static func _split_log(text: String) -> Array:
		var tx := text
		var eqi := tx.find("= ")
		if eqi >= 0 and tx.find("log") > eqi:
			tx = tx.substr(eqi + 2)
		var li := tx.find("log")
		if li < 0:
			return ["", ""]
		tx = tx.substr(li + 3)
		if tx.begins_with("_{"):
			var d := 0
			for k in range(1, tx.length()):
				if tx[k] == "{":
					d += 1
				elif tx[k] == "}":
					d -= 1
					if d == 0:
						return [tx.substr(2, k - 2), tx.substr(k + 1).strip_edges()]
		return ["10", tx.strip_edges()]

	func _cmp1(markup: String, v: float) -> String:
		return "%s %s 1" % [markup, ">" if v > 1.0 else "<"]

	func _draw_compass_plane(font: Font, R: Rect2) -> void:
		draw_style_box(UITheme.boxc(Color(0.03, 0.09, 0.10, 0.7), 12, Color(MINT.r, MINT.g, MINT.b, 0.3), 1, 0), R.grow(6))
		var ML := preload("math_text.gd")
		ML.draw_text(self, font, R.position + Vector2(4, -10),
			"口訣：真、底同時 > 1 或同時 < 1 ⇒ [color=#ffcf5a]正[/color]；一個 > 1、一個 < 1 ⇒ [color=#5ad8ff]負[/color]",
			HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(0.8, 1, 0.9, 0.9))
		var done := compass_t > 0.0
		var n := compass_items.size()
		var cols := [0.20, 0.47, 0.71, 0.90]
		var head_h := 30.0
		var rh := minf(36.0, (R.size.y - head_h - 6.0) / maxf(1.0, n))
		var hy := R.position.y + 21.0
		var heads := ["對數", "底數和 1 比", "真數和 1 比", "正負"]
		for k in 4:
			draw_string(font, Vector2(R.position.x + R.size.x * cols[k] - 70, hy), heads[k], HORIZONTAL_ALIGNMENT_CENTER, 140,
				UITheme.fs(13), Color(0.75, 1, 0.85, 0.75))
		draw_line(Vector2(R.position.x + 8, R.position.y + head_h), Vector2(R.end.x - 8, R.position.y + head_h), Color(1, 1, 1, 0.15), 1.0)
		for i in n:
			var it: Dictionary = compass_items[i]
			var y := R.position.y + head_h + rh * (i + 0.5) + 6.0
			if i % 2 == 1:
				draw_rect(Rect2(R.position.x + 4, y - rh / 2.0 - 5.0, R.size.x - 8, rh), Color(1, 1, 1, 0.03))
			var ab := _split_log(String(it.text))
			var a := float(it.a)
			var b := float(it.b)
			var same := (a - 1.0) * (b - 1.0) > 0.0
			var ca := UITheme.ACCENT if a > 1.0 else SKY
			var cb := UITheme.ACCENT if b > 1.0 else SKY
			ML.draw_on(self, font, R.position.x + R.size.x * cols[0], y, String(it.text), UITheme.fs(15), Color(1, 1, 1, 0.92))
			ML.draw_on(self, font, R.position.x + R.size.x * cols[1], y, _cmp1(ab[0], a), UITheme.fs(15), ca)
			ML.draw_on(self, font, R.position.x + R.size.x * cols[2], y, _cmp1(ab[1], b), UITheme.fs(15), cb)
			var v: int = compass_vals[i] if i < compass_vals.size() else 0
			var mark := "？" if v == 0 else ("＋" if v == 1 else "−")
			var mc := Color(1, 1, 1, 0.5) if v == 0 else (UITheme.ACCENT if v == 1 else SKY)
			if done:
				mark = ("＋" if same else "−") + "  ✓"
				mc = UITheme.ACCENT if same else SKY
			draw_string(font, Vector2(R.position.x + R.size.x * cols[3] - 40, y + 6), mark, HORIZONTAL_ALIGNMENT_CENTER, 80, UITheme.fs(17), mc)

	func _draw_star(p: Vector2, rr: float, c: Color) -> void:
		var pts := PackedVector2Array()
		for k in 10:
			var ang := -PI / 2.0 + k * PI / 5.0
			var rad := rr if k % 2 == 0 else rr * 0.45
			pts.append(p + Vector2(cos(ang), sin(ang)) * rad)
		UITheme.dot(self, p, rr * 1.6, Color(c.r, c.g, c.b, 0.15))
		draw_colored_polygon(pts, c)
