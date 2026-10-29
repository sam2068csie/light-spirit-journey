extends "level_trig1_arc.gd"
## 三角函數 第三大關「浪之階梯」（對應講義 1-1 重點二前半：三角函數的圖形與週期）
## 繼承第一關（月光背景、單位圓、√ 鍵），題庫在 trig3_bank.gd。
##
## 這一關多了：
##   ・wave 步驟（捲出波浪）：左邊單位圓、右邊座標平面。拖動圓上的點，點的高度（sin）或左右（cos）
##     被帶到右邊，把波浪一段一段畫出來。要找的角（targets）每找到一個按一次「確定」。
##   ・下方的函數圖（graph）：sin、cos、tan 和它們的變形，可以標週期、平移副本、最高最低點、對稱軸、對稱中心、遞增區間
##   ・速算：週期、最大值、最小值

const BankG3 := preload("trig3_bank.gd")
const WAVEC := UITheme.LIME

const CHAPTERS_G3 := [
	{"ch": 1, "name": "第一章．波的形狀", "topic": "sin、cos、tan 的圖形與週期", "color": UITheme.LIME},
	{"ch": 2, "name": "第二章．波的性質", "topic": "最大最小、對稱、遞增遞減", "color": UITheme.GOOD},
]

var wave_info: MathLabel


func level_id() -> String:
	return "G3"

func level_title() -> String:
	return "浪之階梯"

func level_subtitle() -> String:
	return "三角函數的圖形"

func level_chapters() -> Array:
	return CHAPTERS_G3

func bank_slots() -> Array:
	return BankG3.slots()

func step_color() -> Color:
	return WAVEC

func chapter_card() -> Dictionary:
	return {"title": "第二章．波的性質", "button": "進入波的性質  ▶",
		"text": "波浪的形狀看熟了，接下來看它的個性：\n\n" \
			+ "・最高、最低在哪裡\n" \
			+ "・對稱軸在波峰波谷、對稱中心在中線上\n" \
			+ "・哪一段爬坡、哪一段下坡\n" \
			+ "・段考最愛的「下列何者為真」\n\n" \
			+ "衝浪去吧！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = WaveView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "速算"
		_mv().spin_changed.connect(_on_view_changed)


func _wv() -> WaveView:
	return fview as WaveView


func _on_view_changed() -> void:
	if fview != null and _wv().wave_on:
		_refresh_wave()
	else:
		_refresh_spin()


## 下方的示意圖隨步驟換（題目寫 "circles"）
func _update_circle() -> void:
	var lst: Array = r.get("circles", [])
	if lst.is_empty():
		super()
		return
	var pick := {}
	for sp in lst:
		if si > int(sp.get("after", -1)):
			pick = sp
	_mv().circ = pick


# ================= 捲出波浪（wave） =================

func _forge_step() -> void:
	if fview != null:
		_wv().wave_on = false
	super()
	if si < steps.size() and String(steps[si].kind) == "wave":
		_build_wave(steps[si])


func _build_wave(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.box(Color(WAVEC.r, WAVEC.g, WAVEC.b, 0.08), 14,
		Color(WAVEC.r, WAVEC.g, WAVEC.b, 0.4), 1, 12))
	rank_box.add_child(card)
	wave_info = MathLabel.new()
	wave_info.font_size = UITheme.fs(20)
	wave_info.max_width = 320
	wave_info.align_center = true
	wave_info.valign_center = true
	wave_info.custom_minimum_size = Vector2(0, 100)
	wave_info.color = UITheme.TEXT
	card.add_child(wave_info)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	rank_box.add_child(row)
	for spec in [["↻  −15°", -1], ["↺  +15°", 1]]:
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
			_wv().set_wave(_wv().wave_k + d)
			Game.of(self).play("blip", 1.0 + 0.04 * _wv().wave_k, -14.0))
		row.add_child(b)
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "確定"
	var wv := _wv()
	wv.circ = {}
	wv.begin_wave(String(st.fn))
	wv.task_q = String(st.q)
	wv.mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_wave()


func _refresh_wave() -> void:
	if wave_info == null or not is_instance_valid(wave_info):
		return
	var wv := _wv()
	var st: Dictionary = steps[si] if si < steps.size() else {}
	var th: float = wv.wave_k * STEP
	var fn: String = wv.wave_fn
	var v := sin(th) if fn == "sin" else cos(th)
	var n: int = st.get("targets", []).size()
	var found := "　已找到 %d／%d" % [wv.found.size(), n] if n > 1 else ""
	wave_info.text = "x = %s\n%s x ≈ %s%s" % [angle_text(wv.wave_k, 12), fn, _v2(v), found]


## 兩位小數（−0.00 寫成 0）
static func _v2(v: float) -> String:
	if absf(v) < 0.005:
		return "0"
	return ("−" if v < 0.0 else "") + "%.2f" % absf(v)


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size() and String(steps[si].kind) == "wave":
		_wave_submit()
		return
	super()


func _wave_submit() -> void:
	var st: Dictionary = steps[si]
	var wv := _wv()
	var th: float = wv.wave_k * STEP
	var hit := -1.0
	for tg in st.targets:
		if absf(float(tg) - th) < 1e-6:
			hit = float(tg)
	if hit < 0.0:
		_wrong(st, "這裡不是喔（%s x ≈ %s）。提示：%s" % [wv.wave_fn, _v2(sin(th) if wv.wave_fn == "sin" else cos(th)), String(st.nudge)])
		return
	if wv.found.has(hit):
		_hint("這個已經找到了，再找找看別的位置！", "info")
		return
	wv.found.append(hit)
	Game.of(self).sfx("correct")
	wv.mark_burst()
	_refresh_wave()
	if wv.found.size() < st.targets.size():
		_hint("✓ 找到一個！還有 %d 個。" % (st.targets.size() - wv.found.size()), "good")
		return
	wv.wave_on = false
	wv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	go_btn.visible = false
	_clear(rank_box)
	rank_box.visible = false
	_step_done(st, "")


func _custom_reveal(msg: String) -> void:
	if fview != null:
		_wv().wave_on = false
	super(msg)


# ================= 速算 =================

func _speed_gen(kind: String, n: int) -> Array:
	if kind != "wave":
		return super(kind, n)
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 2000:
		guard += 1
		var pb := _gen_wave()
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		out.append(pb)
	return out


## y = a·f(bx) + d 的文字
static func _fx_text(fn: String, a: int, bn: int, bd: int, d: int) -> String:
	var arg := ""
	if bd == 1:
		arg = " %s" % ("x" if bn == 1 else "%dx" % bn)
	else:
		arg = "(%s/%d)" % ["x" if bn == 1 else "%dx" % bn, bd]
	var co := "" if a == 1 else ("−" if a == -1 else ("%d " % a if a > 0 else "−%d " % -a))
	var s := "y = %s%s%s" % [co, fn, arg]
	if d > 0:
		s += " + %d" % d
	elif d < 0:
		s += " − %d" % -d
	return s


static func _gen_wave() -> Dictionary:
	var fn: String = ["sin", "cos", "tan"].pick_random()
	var bs := [[1, 1], [2, 1], [3, 1], [4, 1], [1, 2], [1, 3], [2, 3], [3, 2], [1, 4]]
	var b: Array = bs.pick_random()
	var a: int = [1, 2, 3, 4, 5, -1, -2, -3].pick_random()
	var d: int = randi_range(-3, 4)
	var eq := _fx_text(fn, a, b[0], b[1], d)
	if fn == "tan" or randf() < 0.45:
		# 週期：2π/b（tan：π/b）= (2·bd/bn)π
		var num := (1 if fn == "tan" else 2) * int(b[1])
		var den := int(b[0])
		return {"eq": eq + " 的週期", "q": "求週期。", "template": "週期 = [0]π", "ans": _frac(num, den),
			"nudge": ("π" if fn == "tan" else "2π") + " ÷ |x 的係數|。", "tag": BankG3.T_PER}
	if randf() < 0.5:
		return {"eq": eq + " 的最大值", "q": "求最大值。", "template": "最大值 = [0]", "ans": str(d + absi(a)),
			"nudge": "%s 在 −1 和 1 之間：最大值 = %d + |%d|。" % [fn, d, a], "tag": BankG3.T_PROP}
	return {"eq": eq + " 的最小值", "q": "求最小值。", "template": "最小值 = [0]", "ans": str(d - absi(a)),
		"nudge": "%s 在 −1 和 1 之間：最小值 = %d − |%d|。" % [fn, d, a], "tag": BankG3.T_PROP}


# ================= 畫面 =================

class WaveView extends MoonView:
	const GREEN := UITheme.LIME
	const BLUEC := UITheme.CYAN
	const ORANGE := UITheme.ORANGE

	var wave_on := false
	var wave_fn := "sin"
	var wave_k := 0
	var wave_raw := 0.0
	var wave_show := 0.0
	var wave_max := 0.0          # 畫到哪裡了（曲線會留著）
	var found: Array = []
	var _mark_t := -10.0

	func setup(round: Dictionary) -> void:
		super(round)
		wave_on = false

	func begin_wave(fn: String) -> void:
		wave_on = true
		wave_fn = fn
		wave_k = 0
		wave_raw = 0.0
		wave_show = 0.0
		wave_max = 0.0
		found = []
		hint_from = t
		spin_changed.emit()

	func set_wave(k: int) -> void:
		wave_k = clampi(k, 0, 24)
		wave_raw = wave_k * STEPA
		wave_max = maxf(wave_max, wave_raw)
		spin_changed.emit()

	func mark_burst() -> void:
		_mark_t = t
		var g := _wave_geo()
		var gp: Vector2 = _gpt(g, wave_k * STEPA)
		_burst(gp, UITheme.GOLD, 22)

	func _process(delta: float) -> void:
		wave_show = lerpf(wave_show, wave_raw if _drag else wave_k * STEPA, 1.0 - exp(-14.0 * delta))
		if wave_on:
			wave_max = maxf(wave_max, wave_show)
		super(delta)

	func _graph_on() -> bool:
		if wave_on:
			return false
		return super()

	func _bottom_limit() -> float:
		if wave_on:
			return size.y - 330.0
		return super()

	## 版面：[圓心, 半徑, 圖的原點, 每弧度多少像素, 每單位高度多少像素]
	func _wave_geo() -> Array:
		var rc := _spin_rect()
		var rad := 78.0
		var c := Vector2(rc.position.x + 24.0 + rad, rc.get_center().y + 10.0)
		var o := Vector2(c.x + rad + 46.0, c.y)
		var sx := (rc.end.x - 24.0 - o.x) / TAU
		return [c, rad, o, sx, rad]

	func _gpt(g: Array, th: float) -> Vector2:
		var v := sin(th) if wave_fn == "sin" else cos(th)
		return Vector2(g[2].x + th * float(g[3]), g[2].y - v * float(g[4]))

	func _gui_input(e: InputEvent) -> void:
		if not wave_on:
			super(e)
			return
		var g := _wave_geo()
		var c: Vector2 = g[0]
		var rad: float = g[1]
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				var dd: float = e.position.distance_to(c)
				if dd > 10.0 and dd < rad + 40.0:
					_drag = true
					dragged_ever = true
					_last_a = _ang(e.position, c)
					accept_event()
			elif _drag:
				_drag = false
				wave_raw = wave_k * STEPA
				accept_event()
		elif e is InputEventMouseMotion and _drag:
			if e.position.distance_to(c) < 8.0:
				return
			var a := _ang(e.position, c)
			wave_raw = clampf(wave_raw + wrapf(a - _last_a, -PI, PI), 0.0, TAU)
			_last_a = a
			var k := roundi(wave_raw / STEPA)
			if k != wave_k:
				wave_k = k
				spin_changed.emit()
			accept_event()

	func _draw() -> void:
		super()
		if wave_on and kind == "forge" and intro < 0.0:
			_draw_wave(get_theme_default_font())

	func _draw_wave(font: Font) -> void:
		var rc := _spin_rect()
		draw_style_box(UITheme.boxc(Color(0.03, 0.06, 0.14, 0.6), 14, Color(0.65, 0.95, 0.4, 0.25), 1, 0), rc)
		_draw_task(font, rc, "拖動圓上的點，把波浪畫出來")
		var g := _wave_geo()
		var c: Vector2 = g[0]
		var rad: float = g[1]
		var o: Vector2 = g[2]
		var sx: float = g[3]
		var sy: float = g[4]
		var col := BLUEC if wave_fn == "sin" else ORANGE
		# 單位圓
		draw_line(c - Vector2(rad + 12, 0), c + Vector2(rad + 12, 0), Color(1, 1, 1, 0.3), 1.2)
		draw_line(c - Vector2(0, rad + 12), c + Vector2(0, rad + 12), Color(1, 1, 1, 0.3), 1.2)
		draw_arc(c, rad, 0, TAU, 72, Color(1, 1, 1, 0.5), 1.5, true)
		var th := wave_show
		var p := c + Vector2(cos(th), -sin(th)) * rad
		_draw_turn(c, rad * 0.3, th, Color(1, 0.85, 0.45, 0.7), 2.0)
		draw_line(c, p, Color(1, 1, 1, 0.7), 2.0, true)
		# 座標平面
		draw_line(Vector2(o.x - 6, o.y), Vector2(o.x + TAU * sx + 10, o.y), Color(1, 1, 1, 0.45), 1.5)
		draw_line(Vector2(o.x, o.y - sy - 16), Vector2(o.x, o.y + sy + 16), Color(1, 1, 1, 0.45), 1.5)
		for k in 5:
			var xx := o.x + k * PI / 2.0 * sx
			draw_line(Vector2(xx, o.y - 4), Vector2(xx, o.y + 4), Color(1, 1, 1, 0.5), 1.5)
			var lab: String = ["0", "π/2", "π", "3π/2", "2π"][k]
			MathLabel.draw_on(self, font, xx, o.y + 26.0, lab, UITheme.fs(13), Color(1, 1, 1, 0.55))
		for yv in [1.0, -1.0]:
			draw_dashed_line(Vector2(o.x, o.y - yv * sy), Vector2(o.x + TAU * sx, o.y - yv * sy), Color(1, 1, 1, 0.12), 1.0, 5.0)
			draw_string(font, Vector2(o.x - 24, o.y - yv * sy + 5), "1" if yv > 0 else "−1", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(12), Color(1, 1, 1, 0.5))
		# 畫過的曲線
		var pts := PackedVector2Array()
		var n := maxi(2, int(wave_max / 0.04))
		for i in n + 1:
			pts.append(_gpt(g, wave_max * i / n))
		if wave_max > 0.01:
			draw_polyline(pts, Color(col.r, col.g, col.b, 0.25), 7.0, true)
			draw_polyline(pts, col, 2.5, true)
		var q := _gpt(g, th)
		# 圓上的點 → 圖上的點
		if wave_fn == "sin":
			draw_dashed_line(p, Vector2(q.x, p.y), Color(col.r, col.g, col.b, 0.6), 1.5, 5.0)
			draw_line(Vector2(p.x, c.y), p, Color(col.r, col.g, col.b, 0.9), 3.0)
		else:
			# cos：橫坐標的長度，轉到圖上變成高度
			draw_line(c, Vector2(p.x, c.y), Color(col.r, col.g, col.b, 0.9), 3.0)
			draw_line(Vector2(q.x, o.y), q, Color(col.r, col.g, col.b, 0.9), 3.0)
		draw_line(Vector2(q.x, o.y), q, Color(col.r, col.g, col.b, 0.35), 1.5)
		# 已找到的點
		for f in found:
			var fp := _gpt(g, float(f))
			UITheme.dot(self, fp, 10.0, Color(1, 0.85, 0.35, 0.3))
			UITheme.dot(self, fp, 5.5, UITheme.GOLD)
		UITheme.dot(self, q, 6.0, col)
		UITheme.dot(self, p, 16.0 + 2.0 * sin(t * 4.0), Color(1, 0.85, 0.45, 0.22))
		UITheme.dot(self, p, 8.0, UITheme.GOLD)
		UITheme.dot(self, p, 3.5, Color.WHITE)
		UITheme.dot(self, c, 3.0, Color(1, 1, 1, 0.8))
		_draw_drag_hint(font, c, rad, th, Vector2(rc.end.x - 110.0, rc.end.y - 14.0))

	# ---------- 下方的函數圖 ----------

	func _draw_circ(font: Font, rect: Rect2) -> void:
		if String(circ.get("kind", "")) != "graph":
			super(font, rect)
			return
		draw_style_box(UITheme.boxc(Color(0.03, 0.06, 0.14, 0.55), 12, Color(0.65, 0.95, 0.4, 0.22), 1, 0), rect.grow(6))
		_draw_graph(font, rect)

	static func _eval(fn: Dictionary, x: float) -> float:
		var a: float = fn.get("a", 1.0)
		var b: float = fn.get("b", 1.0)
		var d: float = fn.get("d", 0.0)
		var v := 0.0
		match String(fn.get("f", "sin")):
			"sin":
				v = sin(b * x)
			"cos":
				v = cos(b * x)
			"tan":
				if absf(cos(b * x)) < 1e-3:
					return NAN
				v = tan(b * x)
			"tanabs":
				if absf(cos(x)) < 1e-3:
					return NAN
				return tan(x) + absf(tan(x))
			"abssc":
				return absf(sin(x)) + absf(cos(x))
			"sum23":
				return sin(2.0 * x) + cos(3.0 * x)
		var y := a * v + d
		if fn.get("abs", false):
			y = absf(y)
		if fn.get("sq", false):
			y = y * y
		return y

	func _draw_graph(font: Font, rect: Rect2) -> void:
		var xr: Array = circ.get("x", [0.0, 2.0])
		var x0 := float(xr[0]) * PI
		var x1 := float(xr[1]) * PI
		var yr: Array = circ.get("y", [-1.5, 1.5])
		var y0 := float(yr[0])
		var y1 := float(yr[1])
		var area := Rect2(rect.position.x + 14.0, rect.position.y + 10.0, rect.size.x * 0.66, rect.size.y - 34.0)
		var to_px := func(x: float, y: float) -> Vector2:
			return Vector2(area.position.x + (x - x0) / (x1 - x0) * area.size.x, area.end.y - (y - y0) / (y1 - y0) * area.size.y)
		# 遞增遞減的亮區
		for iv in circ.get("inc", []):
			var pa: Vector2 = to_px.call(float(iv[0]) * PI, y1)
			var pb: Vector2 = to_px.call(float(iv[1]) * PI, y0)
			draw_rect(Rect2(pa, pb - pa), Color(1, 0.85, 0.35, 0.12 + 0.04 * sin(t * 3.0)))
		# 座標軸與 π/2 刻度
		var oy: float = clampf(to_px.call(0.0, 0.0).y, area.position.y, area.end.y)
		draw_line(Vector2(area.position.x, oy), Vector2(area.end.x, oy), Color(1, 1, 1, 0.4), 1.5)
		var ox: Vector2 = to_px.call(0.0, 0.0)
		if ox.x >= area.position.x and ox.x <= area.end.x:
			draw_line(Vector2(ox.x, area.position.y), Vector2(ox.x, area.end.y), Color(1, 1, 1, 0.4), 1.5)
		var step := PI / 2.0 if x1 - x0 <= 3.0 * PI else PI
		var k0 := int(ceil(x0 / step))
		var k1 := int(floor(x1 / step))
		for k in range(k0, k1 + 1):
			if k == 0:
				continue
			var tx: Vector2 = to_px.call(k * step, 0.0)
			draw_line(Vector2(tx.x, oy - 3), Vector2(tx.x, oy + 3), Color(1, 1, 1, 0.5), 1.2)
			var lab := angle_text_s(k * (6 if step < PI else 12), 12)
			MathLabel.draw_on(self, font, tx.x, oy + 20.0, lab, UITheme.fs(12), Color(1, 1, 1, 0.5))
		# 對稱軸、對稱中心
		for vx in circ.get("vlines", []):
			var p0: Vector2 = to_px.call(float(vx) * PI, y1)
			var p1: Vector2 = to_px.call(float(vx) * PI, y0)
			draw_dashed_line(p0, p1, Color(1, 0.6, 0.75, 0.7), 1.5, 5.0)
		# 曲線
		var fns: Array = circ.get("fns", [])
		var labels := []
		for fn in fns:
			var colr: Color = fn.get("c", Color.WHITE)
			var seg := PackedVector2Array()
			var N := 240
			for i in N + 1:
				var x := lerpf(x0, x1, float(i) / N)
				var y := _eval(fn, x)
				if is_nan(y) or y > y1 + 0.5 or y < y0 - 0.5:
					if seg.size() >= 2:
						draw_polyline(seg, colr, 2.5, true)
					seg = PackedVector2Array()
					continue
				seg.append(to_px.call(x, clampf(y, y0 - 0.5, y1 + 0.5)))
			if seg.size() >= 2:
				draw_polyline(seg, colr, 2.5, true)
			if String(fn.get("label", "")) != "":
				labels.append([String(fn.label), colr])
			# tan 的漸近線
			if String(fn.get("f", "")) in ["tan", "tanabs"]:
				var bb: float = fn.get("b", 1.0)
				var per := PI / bb
				var kk := int(ceil((x0 - per / 2.0) / per))
				while per * kk + per / 2.0 <= x1:
					var ax: float = per * kk + per / 2.0
					if ax >= x0:
						draw_dashed_line(to_px.call(ax, y1), to_px.call(ax, y0), Color(1, 1, 1, 0.3), 1.2, 4.0)
					kk += 1
		# 平移副本
		if circ.has("shift") and not fns.is_empty():
			var sh := float(circ.shift) * PI
			var fn0: Dictionary = fns[0]
			var pts := PackedVector2Array()
			for i in 241:
				var x := lerpf(x0, x1, i / 240.0)
				var y := _eval(fn0, x - sh)
				if not is_nan(y):
					pts.append(to_px.call(x, y))
			var u := 0.5 + 0.5 * sin(t * 2.0)
			draw_polyline(pts, Color(1, 0.85, 0.35, 0.35 + 0.35 * u), 2.0, true)
			labels.append(["往右平移 π/2（虛線）", Color(1, 0.85, 0.35)])
		# 週期的括號
		if circ.has("period"):
			var pl := float(circ.period) * PI
			var px0 := float(circ.get("x0", 0.0)) * PI
			var by := area.position.y + 4.0
			var a0: Vector2 = to_px.call(px0, 0.0)
			var a1: Vector2 = to_px.call(px0 + pl, 0.0)
			var pc := Color(1, 0.85, 0.35, 0.85)
			draw_line(Vector2(a0.x, by), Vector2(a1.x, by), pc, 2.0)
			draw_line(Vector2(a0.x, by - 5), Vector2(a0.x, by + 5), pc, 2.0)
			draw_line(Vector2(a1.x, by - 5), Vector2(a1.x, by + 5), pc, 2.0)
			draw_dashed_line(Vector2(a0.x, by), Vector2(a0.x, area.end.y), Color(1, 0.85, 0.35, 0.25), 1.0, 4.0)
			draw_dashed_line(Vector2(a1.x, by), Vector2(a1.x, area.end.y), Color(1, 0.85, 0.35, 0.25), 1.0, 4.0)
			labels.append(["一個週期", pc])
		for pt in circ.get("pts", []):
			var pp: Vector2 = to_px.call(float(pt[0]) * PI, float(pt[1]))
			UITheme.dot(self, pp, 8.0 + 1.5 * sin(t * 4.0), Color(1, 0.85, 0.35, 0.25))
			UITheme.dot(self, pp, 4.5, UITheme.GOLD)
		for cpt in circ.get("centers", []):
			var cp: Vector2 = to_px.call(float(cpt[0]) * PI, float(cpt[1]))
			draw_arc(cp, 6.0, 0, TAU, 16, Color(1, 0.6, 0.75), 2.0, true)
		# 右邊的標籤
		var lx := rect.position.x + rect.size.x * 0.85
		var ly := rect.position.y + 40.0
		for lb in labels:
			MathLabel.draw_on(self, font, lx, ly, String(lb[0]), UITheme.fs(15), lb[1])
			ly += 30.0

	## k·π/den 的文字（畫刻度用；和關卡的 angle_text 一樣）
	static func angle_text_s(k: int, den: int) -> String:
		if k == 0:
			return "0"
		var a := absi(k)
		var g := a
		var h := den
		while h != 0:
			var tt := g % h
			g = h
			h = tt
		var n := a / g
		var d := den / g
		var s := ("π" if n == 1 else "%dπ" % n) + ("" if d == 1 else "/%d" % d)
		return ("−" if k < 0 else "") + s
