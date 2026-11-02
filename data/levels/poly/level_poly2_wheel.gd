extends "res://data/levels/engine/step_level.gd"
## 多項式 第二大關「綜合除法水車」（對應講義 4-1 重點二：多項式的除法）
## 引擎是 step_level.gd（一步一步推導），題庫在 poly2_bank.gd。
##
## 這一關多了：
##   ・綜合除法的填空（題庫的 _synth）：下方畫出綜合除法的算式，左邊有一座水車。
##     學生用數字鍵盤填最下面一排；每填一格，水就流上去算出「a × 這一格」放到下一行的中間那排，
##     下一格 = 上面的係數 + 中間的數。填錯的格子變紅。答對後算式留在下方，接著讀商式和餘式。
##   ・水車洞窟的背景（兩側的小瀑布、水面的波光）
##   ・速算：三次式除以 x − a 的餘式或商式的常數項

const BankP2 := preload("res://data/levels/poly/poly2_bank.gd")
const WATER := UITheme.CYAN

const CHAPTERS_P2 := [
	{"ch": 1, "name": "第一章．水車入門", "topic": "綜合除法、除式 ax − b、除法原理", "color": UITheme.CYAN},
	{"ch": 2, "name": "第二章．深層水車", "topic": "除式是二次式、三步驟求值、連續綜合除法", "color": UITheme.BLUE},
]


func level_id() -> String:
	return "P2"

func level_title() -> String:
	return "綜合除法水車"

func level_subtitle() -> String:
	return "多項式的除法"

func level_chapters() -> Array:
	return CHAPTERS_P2

func bank_slots() -> Array:
	return BankP2.slots()

func step_color() -> Color:
	return WATER

func radicals_ok() -> bool:
	return true

func stage_style() -> Dictionary:
	return {"sky_top": Color("0f1a33"), "sky_bot": Color("0a1224"), "scenery": "none", "ambient": "currents"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．深層水車", "button": "進入深層水車  ▶",
		"text": "深層的水車更大、水道更多：\n\n" \
			+ "・除式是二次式：長除法，餘式最多一次\n" \
			+ "・兩根都是根 ⇒ 能整除（餘式是 0）\n" \
			+ "・x = √2 − 1 代進五次式：先除，再代餘式\n" \
			+ "・連續綜合除法：把多項式改用 (x − h) 來寫\n\n" \
			+ "水車轉起來囉！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = WheelView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "水車速算"


func _wv() -> WheelView:
	return fview as WheelView


# ================= 綜合除法的填空 =================

func _forge_step() -> void:
	if fview != null:
		_wv().on = false
	super()


func _refresh_fill() -> void:
	super()
	if fview == null or r.get("type", "") != "forge" or not fill_step.has("synth"):
		return
	var wv := _wv()
	wv.on = true
	wv.spec = fill_step.synth
	wv.vals = slot_vals.duplicate()
	wv.bad = slot_bad.duplicate()
	wv.cur = cur_slot
	wv.queue_redraw()


func _step_done(st: Dictionary, why: String) -> void:
	if fview != null and st.has("synth"):
		var wv := _wv()
		wv.on = false
		wv.done_spec = st.synth
		wv.done_vals = Array(st.answers).map(func(s): return String(s).replace("-", "−"))
		wv.burst_center()
	super(st, why)


func _custom_reveal(msg: String) -> void:
	if fview != null and r.type == "forge":
		for j in range(si, steps.size()):
			if steps[j].has("synth"):
				_wv().on = false
				_wv().done_spec = steps[j].synth
				_wv().done_vals = Array(steps[j].answers).map(func(s): return String(s).replace("-", "−"))
	super(msg)


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
	return BankP2.T_SYN


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算題：三次式除以 x − a。{eq, q, template, ans, nudge, tag}
static func gen_problems(_kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var coef := [randi_range(1, 2), randi_range(-5, 5), randi_range(-6, 6), randi_range(-8, 8)]
		var a: int = [-2, -1, 1, 2, 3].pick_random()
		var row := BankP2.synth_row(coef, [a, 1])
		var what := randi() % 2
		var ans: Array = row[3] if what == 0 else row[2]
		if absi(ans[0]) > 60 or coef[1] == 0 and randf() < 0.7:
			continue
		var eq := "%s 除以 %s" % [BankP2.poly_text(coef), BankP2.divisor_text([a, 1])]
		if seen.has(eq + str(what)):
			continue
		seen[eq + str(what)] = true
		var pb := {"eq": eq + "\n" + ["餘式 = ？", "商式的常數項 = ？"][what], "ans": BankP2._qa(ans), "tag": BankP2.T_SYN}
		pb.q = ["用綜合除法算出餘式。", "用綜合除法算出商式的常數項（最下面一排的倒數第二格）。"][what]
		pb.template = ["餘式 = [0]", "商式的常數項 = [0]"][what]
		pb.nudge = "左邊寫 %d；每一格 = 上面的係數 + %d × 前一格。" % [a, a]
		out.append(pb)
	return out


# ================= 畫面：水車洞窟的推導台 + 綜合除法 =================

class WheelView extends ForgeView:
	const AQUA := UITheme.CYAN
	const GOLDC := UITheme.GOLD

	var on := false              # 正在填綜合除法
	var spec := {}               # {coef, a}
	var vals: Array = []         # 學生填的最下面一排（字串）
	var bad: Array = []
	var cur := 0
	var done_spec := {}          # 答對之後留在下方的算式
	var done_vals: Array = []

	func setup(round: Dictionary) -> void:
		super(round)
		on = false
		spec = {}
		done_spec = {}
		done_vals = []

	func _graph_on() -> bool:
		return on or not done_spec.is_empty() or super()

	func _bottom_limit() -> float:
		if on:
			return size.y - 300.0
		return super()

	func _draw() -> void:
		super()
		if on and kind == "forge" and intro < 0.0:
			_draw_table(get_theme_default_font(), Rect2(36, size.y - 290, size.x - 72, 276), spec, vals, true)

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if on:
			return
		if not done_spec.is_empty():
			_draw_table(font, rect, done_spec, done_vals, false)
		else:
			super(font, rect)

	## 水車洞窟：深藍的底、兩側的小瀑布、底部的水光
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("0f1a33"), Color("0f1a33"), Color("0a1224"), Color("0a1224")]))
		var falls := PackedVector2Array()
		for side in [14.0, w - 14.0]:
			for k in 18:
				var y := fposmod(t * 160.0 + k * 41.0, h + 40.0) - 20.0
				falls.append_array([Vector2(side + 3.0 * sin(k * 1.7), y), Vector2(side + 3.0 * sin(k * 1.7), y + 16.0)])
		draw_multiline(falls, Color(0.5, 0.8, 1.0, 0.18), 2.0)
		var glow := 0.07 + 0.02 * sin(t * 1.3)
		draw_polygon(PackedVector2Array([Vector2(0, h * 0.75), Vector2(w, h * 0.75), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color(0.3, 0.7, 1.0, 0.0), Color(0.3, 0.7, 1.0, 0.0), Color(0.3, 0.6, 1.0, glow), Color(0.3, 0.6, 1.0, glow)]))
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	## 「3」「−2」「1/2」→ [分子, 分母]；看不懂就回傳空陣列
	static func _pq(s: String) -> Array:
		var v := s.strip_edges().replace("−", "-")
		if v == "" or v == "-":
			return []
		var neg := v.begins_with("-")
		if neg:
			v = v.substr(1)
		var parts := v.split("/")
		if parts.size() > 2:
			return []
		for p in parts:
			if not p.is_valid_int():
				return []
		var d := int(parts[1]) if parts.size() == 2 else 1
		if d == 0:
			return []
		return [-int(parts[0]) if neg else int(parts[0]), d]

	static func _txt(q: Array) -> String:
		var P := preload("res://data/levels/poly/poly2_bank.gd")
		return P._qs(P._q(q[0], q[1]))

	## 綜合除法的算式：左邊水車和寫的數，上面一排是係數，中間是 a × 前一格，最下面是學生填的（最後一格是餘式）
	func _draw_table(font: Font, rc: Rect2, sp: Dictionary, row: Array, live: bool) -> void:
		var P := preload("res://data/levels/poly/poly2_bank.gd")
		var coef: Array = sp.coef
		var a: Array = sp.a
		var n := coef.size()
		var fs := UITheme.fs(22 if live else 17)
		var wheel_r := 34.0 if live else 24.0
		var left := rc.position.x + wheel_r * 2.0 + 30.0
		var cw := minf(78.0 if live else 64.0, (rc.end.x - left - 40.0) / n)
		var x0 := left + 40.0 + cw / 2.0
		var hh := rc.size.y
		var y_top := rc.position.y + hh * (0.24 if live else 0.20)
		var y_mid := rc.position.y + hh * (0.48 if live else 0.46)
		var y_line := y_mid + (16.0 if live else 12.0)
		var y_bot := rc.position.y + hh * (0.74 if live else 0.76)
		# 水車：填得越多轉得越快
		var filled := 0
		for v in row:
			if String(v) != "":
				filled += 1
		var wc := Vector2(rc.position.x + wheel_r + 8.0, (y_top + y_bot) / 2.0)
		var rot := t * (0.4 + 0.5 * filled) if live else t * 0.6
		draw_arc(wc, wheel_r, 0, TAU, 40, Color(0.6, 0.45, 0.3, 0.9), 4.0, true)
		var spokes := PackedVector2Array()
		for k in 8:
			var ang := rot + k * PI / 4.0
			spokes.append_array([wc, wc + Vector2(cos(ang), sin(ang)) * wheel_r])
			draw_rect(Rect2(wc + Vector2(cos(ang), sin(ang)) * wheel_r - Vector2(4, 4), Vector2(8, 8)), Color(0.45, 0.75, 1.0, 0.7))
		draw_multiline(spokes, Color(0.6, 0.45, 0.3, 0.8), 2.0)
		UITheme.dot(self, wc, 4.0, GOLDC)
		# 寫的數（a）
		var ax := left + 6.0
		MathLabel.draw_on(self, font, ax, y_top + 8.0, _txt(a), fs, GOLDC)
		draw_line(Vector2(ax + 22.0, y_top - fs), Vector2(ax + 22.0, y_line), Color(1, 1, 1, 0.5), 2.0)
		# 上面一排：係數
		for i in n:
			MathLabel.draw_on(self, font, x0 + cw * i, y_top + 8.0, _txt([int(coef[i]), 1]), fs, Color(1, 0.97, 0.9))
		# 橫線
		draw_line(Vector2(ax + 22.0, y_line), Vector2(x0 + cw * (n - 0.5), y_line), Color(1, 1, 1, 0.5), 2.0)
		# 餘式的框（最後一格）
		var rx := x0 + cw * (n - 1)
		draw_line(Vector2(rx - cw / 2.0, y_line), Vector2(rx - cw / 2.0, y_bot + 16.0), Color(1, 1, 1, 0.35), 1.5)
		# 中間一排：a × 前一格；最下面一排：學生填的
		for i in n:
			var x := x0 + cw * i
			var s := (String(row[i]) if i < row.size() else "").replace("-", "−")
			if i > 0:
				var prev := _pq(String(row[i - 1])) if i - 1 < row.size() else []
				if not prev.is_empty():
					var m := P._qmul(a, P._q(prev[0], prev[1]))
					MathLabel.draw_on(self, font, x, y_mid + 6.0, _txt(m), UITheme.fs(18 if live else 14), Color(0.55, 0.85, 1.0))
					# 水流：前一格 → 往右上 → 中間這格
					draw_line(Vector2(x - cw + 14.0, y_bot - fs * 0.9), Vector2(x - 14.0, y_mid + 12.0), Color(0.45, 0.75, 1.0, 0.45), 1.5, true)
			var box := Rect2(x - cw / 2.0 + 6.0, y_bot - fs - 6.0, cw - 12.0, fs + 16.0)
			if live:
				var bc := UITheme.BAD if (i < bad.size() and bad[i]) else (GOLDC if i == cur else Color(1, 1, 1, 0.25))
				if s == "":
					draw_rect(box, Color(bc.r, bc.g, bc.b, 0.08))
				draw_rect(box, bc, false, 2.0 if i == cur else 1.0)
			if s != "":
				var col := UITheme.BAD if (live and i < bad.size() and bad[i]) else (AQUA.lightened(0.3) if i < n - 1 else GOLDC)
				MathLabel.draw_on(self, font, x, y_bot + 4.0, s, fs, col)
		# 說明
		var cap_fs := UITheme.fs(13)
		var qx := (x0 + x0 + cw * (n - 2)) / 2.0
		UITheme.text_ol(self, font, Vector2(qx - 80, y_bot + (34.0 if live else 26.0)), "商式的係數", HORIZONTAL_ALIGNMENT_CENTER, 160, cap_fs, Color(0.6, 0.85, 1.0, 0.8))
		UITheme.text_ol(self, font, Vector2(rx - 40, y_bot + (34.0 if live else 26.0)), "餘式", HORIZONTAL_ALIGNMENT_CENTER, 80, cap_fs, Color(1, 0.85, 0.5, 0.85))
