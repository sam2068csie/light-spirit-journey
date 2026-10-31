extends "level_trig6_mirror.gd"
## 三角函數 第七大關「疊合燈塔」（對應講義 1-2 重點三：正餘弦函數的疊合）
## a sin x + b cos x = r sin(x + φ)　（r = √(a² + b²)，cos φ = a/r，sin φ = b/r）
## 繼承第六關（夜海背景、積木面板、引導閃動），題庫在 trig7_bank.gd。
##
## 這一關多了三種「動手」的步驟：
##   phasor 相位指針：平面上金色的點是 (a, b)。拖動 r（箭頭長度）和 φ（箭頭角度），讓箭頭尖端壓在目標點上；
##                  同時右邊兩條波（目標 a sin x + b cos x 和你的 r sin(x + φ)）也會跟著重合。
##                  form "sin"：r sin(x + φ)　form "cos"：r cos(x − θ)
##   peak   找亮點：拖動 x，看 a sin x、b cos x 和合成後的光束亮度 f(x)，找最亮（max）、最暗（min）或熄滅（zero）的位置。
##                  dom 可以限制 x 的範圍（限制範圍的最大最小值）。
##   wave   拼光束：像第五、六關的積木，但積木是 sin x、cos x、sin(x + 30°)… 和數字（√3 等），
##                  用 5 個 x 檢查你拼出的式子和目標的 a sin x + b cos x 一不一樣，畫面上兩條曲線也會重合。
##   速算：已知 a sin x ± b cos x，說出最大值或最小值

const BankG7 := preload("trig7_bank.gd")
const LAMP := UITheme.GOLD_LIGHT

const CHAPTERS_G7 := [
	{"ch": 1, "name": "第一章．合成一道光", "topic": "疊合的公式、φ 在哪個象限、最大值最小值、拆開再合起來", "color": UITheme.GOLD},
	{"ch": 2, "name": "第二章．疊合的變身", "topic": "非特殊角、齊次型、參數型、限制範圍、生活應用", "color": UITheme.GOLD_LIGHT},
]

## r 滑桿的選項（值，顯示的文字），由小到大
const R_LIST := [[1.0, "1"], [1.4142135623730951, "√2"], [1.7320508075688772, "√3"], [2.0, "2"],
	[2.8284271247461903, "2√2"], [3.0, "3"], [3.4641016151377544, "2√3"], [4.0, "4"],
	[4.242640687119285, "3√2"], [5.0, "5"], [5.196152422706632, "3√3"], [6.0, "6"]]

const WV_SAMPLES := [0.0, 40.0, 100.0, 230.0, 310.0]

var lh_info: MathLabel


func level_id() -> String:
	return "G7"

func level_title() -> String:
	return "疊合燈塔"

func level_subtitle() -> String:
	return "正餘弦函數的疊合"

func level_chapters() -> Array:
	return CHAPTERS_G7

func bank_slots() -> Array:
	return BankG7.slots()

func step_color() -> Color:
	return LAMP

func chapter_card() -> Dictionary:
	return {"title": "第二章．疊合的變身", "button": "進入疊合的變身  ▶",
		"text": "特殊角會合成了，接下來把燈塔搬到更多地方：\n\n" \
			+ "・非特殊角：r 是整數，φ 只能用 cos φ、sin φ 表示\n" \
			+ "・齊次型：先用倍角、降冪變成 sin 2x、cos 2x\n" \
			+ "・參數型：令 k = sin x + cos x，變成二次函數\n" \
			+ "・限制範圍：最大最小值可能在端點\n" \
			+ "・生活應用：周長、長度的最大值\n\n" \
			+ "光束再亮一點！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = LightView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "速算"
		_tv().tide_changed.connect(_on_tide_changed)
		_tv().tap_missed.connect(_on_tap_missed)


func _lv() -> LightView:
	return fview as LightView


func _on_tide_changed() -> void:
	if fview == null:
		return
	match _tv().mode:
		"phasor":
			_refresh_phasor()
		"peak":
			_refresh_peak()
		"wave":
			_refresh_wave()
		_:
			super()


func _forge_step() -> void:
	super()
	if si >= steps.size():
		return
	var st: Dictionary = steps[si]
	match String(st.kind):
		"phasor":
			_build_phasor(st)
		"peak":
			_build_peak(st)
		"wave":
			_build_wave(st)


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size():
		match String(steps[si].kind):
			"phasor":
				_phasor_submit()
				return
			"peak":
				_peak_submit()
				return
			"wave":
				_wave_submit()
				return
	super()


## 一排「名字 + 滑桿 + 數值」：on_change(i) 在滑桿動的時候呼叫，回傳要顯示的文字
func _slider_row(parent: Control, name: String, n: int, i0: int, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var nm := Label.new()
	nm.text = name
	nm.custom_minimum_size = Vector2(64, 0)
	nm.add_theme_font_size_override("font_size", UITheme.fs(15))
	nm.add_theme_color_override("font_color", UITheme.CYAN)
	row.add_child(nm)
	var s := UITheme.touch_slider()
	s.min_value = 0
	s.max_value = n
	s.step = 1
	s.value = i0
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.custom_minimum_size = Vector2(0, 30)
	UITheme.tint_slider(s, UITheme.CYAN)
	row.add_child(s)
	UITheme.add_step_buttons(s, UITheme.CYAN)
	var vl := Label.new()
	vl.custom_minimum_size = Vector2(62, 0)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vl.add_theme_font_size_override("font_size", UITheme.fs(15))
	vl.add_theme_color_override("font_color", UITheme.CYAN)
	row.add_child(vl)
	vl.text = String(on_change.call(i0, true))
	s.value_changed.connect(func(v: float):
		if busy:
			return
		vl.text = String(on_change.call(int(v), false))
		MoonView.dragged_ever = true
		_stop_attract()
		Game.of(self).play("blip", 0.8 + 0.03 * v, -18.0)
		_refresh_cur())
	return row


func _refresh_cur() -> void:
	match _lv().mode:
		"phasor":
			_refresh_phasor()
		"peak":
			_refresh_peak()


# ================= phasor：相位指針 =================

func _build_phasor(st: Dictionary) -> void:
	_prep_panel(st)
	var tv := _lv()
	var card := _info_card(LAMP)
	lh_info = _math_label(16, 330, 52, UITheme.TEXT)
	card.add_child(lh_info)
	var cosf := String(st.get("form", "sin")) == "cos"
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	rank_box.add_child(vb)
	var rmax := float(st.get("rmax", 4.5))
	var opts := []
	for o in R_LIST:
		if float(o[0]) <= rmax + 1e-9:
			opts.append(o)
	tv.ph_r = float(opts[0][0])
	tv.ph_rt = String(opts[0][1])
	tv.ph_ang = 0.0
	tv.ph_sr = tv.ph_r
	tv.ph_sa = 0.0
	_slider_row(vb, "r 長度", opts.size() - 1, 0, func(i: int, _first: bool):
		_lv().ph_r = float(opts[i][0])
		_lv().ph_rt = String(opts[i][1])
		return opts[i][1])
	_slider_row(vb, "θ 角度" if cosf else "φ 角度", 24, 12, func(j: int, _first: bool):
		var d := -180.0 + 15.0 * j
		_lv().ph_ang = d
		return "%s°" % TideView.dec(d))
	tv.mode = "phasor"
	tv.spec = st
	tv.circ = {}
	tv.task_q = String(st.q)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_attract(vb)
	tv.guide_text = "① 拖動 r、角度 兩個滑桿"
	_refresh_phasor()


func _refresh_phasor() -> void:
	if lh_info == null or not is_instance_valid(lh_info) or si >= steps.size():
		return
	var st: Dictionary = steps[si]
	var tv := _lv()
	var a := float(st.a)
	var b := float(st.b)
	var tip := tv.ph_tip(String(st.get("form", "sin")))
	var okx := absf(tip.x - a) < 1e-4
	var oky := absf(tip.y - b) < 1e-4
	if String(st.get("form", "sin")) == "cos":
		lh_info.text = "r sin θ = %s　（a = %s）%s\nr cos θ = %s　（b = %s）%s" % [
			CompassView.dec3(tip.x), String(st.a_txt), "  ✓" if okx else "", CompassView.dec3(tip.y), String(st.b_txt), "  ✓" if oky else ""]
	else:
		lh_info.text = "r cos φ = %s　（a = %s）%s\nr sin φ = %s　（b = %s）%s" % [
			CompassView.dec3(tip.x), String(st.a_txt), "  ✓" if okx else "", CompassView.dec3(tip.y), String(st.b_txt), "  ✓" if oky else ""]
	tv.queue_redraw()


func _phasor_submit() -> void:
	var st: Dictionary = steps[si]
	var tv := _lv()
	var tip := tv.ph_tip(String(st.get("form", "sin")))
	var a := float(st.a)
	var b := float(st.b)
	if tip.distance_to(Vector2(a, b)) > 1e-4:
		var msg := "箭頭尖端在 (%s, %s)，目標點在 (%s, %s)。" % [CompassView.dec3(tip.x), CompassView.dec3(tip.y),
			CompassView.dec3(a), CompassView.dec3(b)]
		if absf(tip.length() - Vector2(a, b).length()) > 1e-4:
			msg += "長度還不對：目標點離原點 √(a² + b²)。"
		else:
			msg += "長度對了，轉一轉角度。"
		_wrong(st, msg + "提示：" + String(st.nudge))
		return
	Game.of(self).sfx("correct")
	tv.burst_center()
	_interact_done(st, {})


# ================= peak：找亮點 =================

func _build_peak(st: Dictionary) -> void:
	_prep_panel(st)
	var tv := _lv()
	var card := _info_card(LAMP)
	lh_info = _math_label(17, 330, 50, UITheme.TEXT)
	card.add_child(lh_info)
	var dom: Array = st.get("dom", [0.0, 360.0])
	var lo := float(dom[0])
	var n := int(round((float(dom[1]) - lo) / 15.0))
	var i0 := clampi(int(round((float(st.get("start", lo)) - lo) / 15.0)), 0, n)
	var vb := VBoxContainer.new()
	rank_box.add_child(vb)
	tv.pk_x = lo + 15.0 * i0
	tv.pk_show = tv.pk_x
	_slider_row(vb, "x 角度", n, i0, func(i: int, _first: bool):
		var d := lo + 15.0 * i
		_lv().pk_x = d
		return "%s°" % TideView.dec(d))
	tv.mode = "peak"
	tv.spec = st
	tv.circ = {}
	tv.task_q = String(st.q)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_attract(vb)
	tv.guide_text = "① 拖動 x 滑桿"
	_refresh_peak()


func _refresh_peak() -> void:
	if lh_info == null or not is_instance_valid(lh_info) or si >= steps.size():
		return
	var st: Dictionary = steps[si]
	var tv := _lv()
	var x := deg_to_rad(tv.pk_x)
	var f := float(st.a) * sin(x) + float(st.b) * cos(x)
	lh_info.text = "x = %s°\nf(x) = %s" % [TideView.dec(tv.pk_x), CompassView.dec3(f)]
	tv.queue_redraw()


func _peak_submit() -> void:
	var st: Dictionary = steps[si]
	var tv := _lv()
	var hit := false
	for xd in st.xs:
		if absf(fposmod(tv.pk_x - float(xd) + 180.0, 360.0) - 180.0) < 1e-6:
			hit = true
	if not hit:
		var x := deg_to_rad(tv.pk_x)
		var f := float(st.a) * sin(x) + float(st.b) * cos(x)
		_wrong(st, "現在 f(x) = %s，還不是%s的位置。提示：%s" % [CompassView.dec3(f), String(st.word), String(st.nudge)])
		return
	Game.of(self).sfx("correct")
	tv.burst_center()
	_interact_done(st, {})


# ================= wave：拼光束 =================

func _build_wave(st: Dictionary) -> void:
	_build_tiles(st)
	var tv := _lv()
	tv.mode = "wave"
	tv.guide_text = "① 點右邊的積木"
	tiles_fx.font_size = UITheme.fs(16)
	# 積木比較長，一排放三個
	for ch in rank_box.get_children():
		if ch is GridContainer:
			ch.columns = int(st.get("cols", 3))
	_refresh_wave()


func _refresh_tiles() -> void:
	if si < steps.size() and String(steps[si].kind) == "wave":
		_refresh_wave()
		return
	super()


func _refresh_wave() -> void:
	if tiles_fx == null or not is_instance_valid(tiles_fx) or si >= steps.size():
		return
	var st: Dictionary = steps[si]
	var tv := _lv()
	if not tv.tiles_seq.is_empty():
		tv.guide_text = ""
	var rows := []
	var all_ok := not tv.tiles_seq.is_empty()
	for d in WV_SAMPLES:
		var want := float(st.a) * sin(deg_to_rad(d)) + float(st.b) * cos(deg_to_rad(d))
		var got := LightView.wv_value(tv.tiles_seq, d)
		var ok := not is_nan(got) and absf(got - want) < 1e-6 * maxf(1.0, absf(want))
		if not ok:
			all_ok = false
		rows.append({"a": d, "b": 0.0, "want": want, "got": got, "ok": ok})
	tv.tiles_rows = rows
	tv.matched = all_ok
	var body := " ".join(tv.tiles_seq) if not tv.tiles_seq.is_empty() else "（還沒有積木）"
	tiles_fx.text = "%s =\n%s" % [String(st.expr), body]
	tv.queue_redraw()


func _wave_submit() -> void:
	var st: Dictionary = steps[si]
	var tv := _lv()
	if tv.tiles_seq.is_empty():
		_wrong(st, "還沒有放積木喔！點右邊的積木，把光束拼出來。")
		return
	if tv.matched:
		Game.of(self).sfx("correct")
		tv.burst_center()
		_interact_done(st, {})
		return
	var msg := "曲線還沒重合。"
	for row in tv.tiles_rows:
		if not bool(row.ok):
			if is_nan(float(row.got)):
				msg += "式子還不完整，積木要接好。"
			else:
				msg += "代 x = %d°：你的式子 = %s，目標 = %s。" % [int(row.a), CompassView.dec3(float(row.got)), CompassView.dec3(float(row.want))]
			break
	_wrong(st, msg + "提示：" + String(st.nudge).replace(" ÷ ", " 除以 "))


# ================= 速算 =================

func _speed_gen(kind: String, n: int) -> Array:
	if kind != "light":
		return super(kind, n)
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 2000:
		guard += 1
		var pb := _gen_light()
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		out.append(pb)
	return out


static func _coef(k: int, root: String) -> String:
	if k == 1 and root != "":
		return root
	return "%d%s" % [k, root]


## a sin x ± b cos x：三四五型（最大值是整數）或特殊角型（√ 的倍數）
static func _gen_light() -> Dictionary:
	var sa := 1 if randi() % 2 == 0 else -1
	var sb := 1 if randi() % 2 == 0 else -1
	var ta := ""
	var tb := ""
	var rmax := ""
	var hint := ""
	if randi() % 2 == 0:
		var tr: Array = TRIPLES.pick_random()
		var p: int = tr[0]
		var q: int = tr[1]
		if randi() % 2 == 0:
			var tmp := p
			p = q
			q = tmp
		ta = "%d" % p
		tb = "%d" % q
		rmax = "%d" % tr[2]
		hint = "r = √(a² + b²)：%d² + %d² = %d²。" % [p, q, tr[2]]
	else:
		var k := 1 + randi() % 3
		match randi() % 3:
			0:
				ta = _coef(k, "")
				tb = _coef(k, "√3")
				rmax = "%d" % (2 * k)
				hint = "a² + b² = %d + %d = %d，開根號。" % [k * k, 3 * k * k, 4 * k * k]
			1:
				ta = _coef(k, "√3")
				tb = _coef(k, "")
				rmax = "%d" % (2 * k)
				hint = "a² + b² = %d + %d = %d，開根號。" % [3 * k * k, k * k, 4 * k * k]
			_:
				ta = _coef(k, "")
				tb = _coef(k, "")
				rmax = "%d√2" % k if k > 1 else "√2"
				hint = "a² + b² = %d + %d = %d，開根號。" % [k * k, k * k, 2 * k * k]
	var f := "%s sin x %s %s cos x" % [ta, "+" if sb > 0 else "−", tb]
	if sa < 0:
		f = "−" + f
	var ask_max := randi() % 2 == 0
	var ans := rmax if ask_max else "-" + rmax
	return {"eq": "f(x) = %s" % f, "q": "求 f(x) 的%s。" % ("最大值" if ask_max else "最小值"),
		"template": "%s = [0]" % ("最大值" if ask_max else "最小值"), "ans": ans,
		"nudge": hint + "最大值是 r，最小值是 −r。", "tag": BankG7.T_LIGHT}


# ================= 畫面 =================

class LightView extends MirrorView:
	var ph_r := 1.0
	var ph_ang := 0.0
	var ph_rt := "1"
	var ph_sr := 1.0
	var ph_sa := 0.0
	var pk_x := 0.0
	var pk_show := 0.0

	func ph_tip(form: String) -> Vector2:
		var d := deg_to_rad(ph_ang)
		if form == "cos":
			return Vector2(ph_r * sin(d), ph_r * cos(d))
		return Vector2(ph_r * cos(d), ph_r * sin(d))

	func _process(delta: float) -> void:
		if mode == "phasor":
			ph_sr = lerpf(ph_sr, ph_r, 1.0 - exp(-12.0 * delta))
			ph_sa = lerpf(ph_sa, ph_ang, 1.0 - exp(-12.0 * delta))
		elif mode == "peak":
			pk_show = lerpf(pk_show, pk_x, 1.0 - exp(-14.0 * delta))
		super(delta)

	func _draw_mode(font: Font) -> void:
		if mode != "phasor" and mode != "peak" and mode != "wave":
			super(font)
			return
		var rc := _spin_rect()
		draw_style_box(UITheme.boxc(Color(0.03, 0.06, 0.14, 0.62), 14, Color(1.0, 0.85, 0.4, 0.28), 1, 0), rc)
		_draw_task(font, rc, "燈塔")
		match mode:
			"phasor":
				_draw_phasor(font, rc)
			"peak":
				_draw_peak(font, rc)
			_:
				_draw_wave(font, rc)
		_draw_guide(font, rc)

	## 度 → "π/6"、"π"、"2π"
	static func pdeg(d: float) -> String:
		var n := int(round(d))
		if n == 0:
			return "0"
		var g := 1
		for k in range(180, 0, -1):
			if n % k == 0 and 180 % k == 0:
				g = k
				break
		var num := absi(n) / g
		var den := 180 / g
		var s := "π" if num == 1 else "%dπ" % num
		if den != 1:
			s += "/%d" % den
		return ("−" if n < 0 else "") + s

	## 畫曲線座標：area 是畫的位置，x 從 x0 到 x1（度），y 從 −ymax 到 ymax
	func _plot_box(font: Font, area: Rect2, x0: float, x1: float, ymax: float, tick: float) -> void:
		draw_rect(area, Color(0, 0, 0, 0.2))
		var ystep := 1.0 if ymax <= 4.6 else 2.0
		var yv := -floorf(ymax / ystep) * ystep
		while yv <= ymax + 1e-6:
			var py := _py(area, ymax, yv)
			draw_line(Vector2(area.position.x, py), Vector2(area.end.x, py),
				Color(1, 1, 1, 0.5 if absf(yv) < 1e-9 else 0.1), 1.4 if absf(yv) < 1e-9 else 1.0)
			yv += ystep
		var xv := ceilf(x0 / tick) * tick
		while xv <= x1 + 1e-6:
			var px := _px(area, x0, x1, xv)
			draw_line(Vector2(px, area.position.y), Vector2(px, area.end.y), Color(1, 1, 1, 0.08), 1.0)
			MathLabel.draw_on(self, font, px, area.end.y - 4.0, pdeg(xv), UITheme.fs(11), Color(1, 1, 1, 0.5))
			xv += tick

	static func _px(area: Rect2, x0: float, x1: float, xd: float) -> float:
		return area.position.x + (xd - x0) / (x1 - x0) * area.size.x

	static func _py(area: Rect2, ymax: float, y: float) -> float:
		return area.get_center().y - clampf(y / ymax, -1.05, 1.05) * area.size.y / 2.0 * 0.9

	func _curve(area: Rect2, x0: float, x1: float, ymax: float, fn: Callable, col: Color, w: float) -> void:
		var pts := PackedVector2Array()
		var n := 96
		for i in n + 1:
			var xd := lerpf(x0, x1, float(i) / n)
			var y: float = fn.call(xd)
			if is_nan(y):
				continue
			pts.append(Vector2(_px(area, x0, x1, xd), _py(area, ymax, y)))
		if pts.size() >= 2:
			draw_polyline(pts, Color(col.r, col.g, col.b, 0.25), w + 3.0, true)
			draw_polyline(pts, col, w, true)

	static func fab(a: float, b: float, xd: float) -> float:
		return a * sin(deg_to_rad(xd)) + b * cos(deg_to_rad(xd))

	# --- phasor ---

	func _draw_phasor(font: Font, rc: Rect2) -> void:
		var a := float(spec.a)
		var b := float(spec.b)
		var cosf := String(spec.get("form", "sin")) == "cos"
		var rmax := float(spec.get("rmax", 4.5))
		var cyan := UITheme.CYAN
		var pink := Color(1, 0.6, 0.8)
		var c := Vector2(rc.position.x + 128.0, rc.position.y + 168.0)
		var sc := 88.0 / rmax
		draw_line(c - Vector2(106, 0), c + Vector2(106, 0), Color(1, 1, 1, 0.35), 1.4)
		draw_line(c - Vector2(0, 106), c + Vector2(0, 106), Color(1, 1, 1, 0.35), 1.4)
		for i in range(1, int(rmax) + 1):
			for sg in [-1.0, 1.0]:
				var o: float = sg * i * sc
				draw_line(c + Vector2(o, -3), c + Vector2(o, 3), Color(1, 1, 1, 0.45), 1.2)
				draw_line(c + Vector2(-3, o), c + Vector2(3, o), Color(1, 1, 1, 0.45), 1.2)
		MathLabel.draw_on(self, font, c.x + 100.0, c.y + 18.0, "a", UITheme.fs(15), UITheme.CYAN)
		MathLabel.draw_on(self, font, c.x - 12.0, c.y - 100.0, "b", UITheme.fs(15), UITheme.ORANGE)
		# 目標點
		var tp := c + Vector2(a * sc, -b * sc)
		draw_dashed_line(c, tp, Color(pink.r, pink.g, pink.b, 0.8), 2.0, 6.0)
		UITheme.dot(self, tp, 10.0, Color(pink.r, pink.g, pink.b, 0.35))
		UITheme.dot(self, tp, 5.0, pink)
		var lab := "(%s, %s)" % [String(spec.a_txt), String(spec.b_txt)]
		var lw := MathLabel.text_width(font, lab, UITheme.fs(13))
		var lx := clampf(tp.x + (18.0 + lw / 2.0) * (1.0 if a >= 0.0 else -1.0), rc.position.x + 6.0 + lw / 2.0, rc.position.x + 252.0 - lw / 2.0)
		var ly := tp.y + (-14.0 if b >= 0.0 else 22.0)
		MathLabel.draw_on(self, font, lx, ly, lab, UITheme.fs(13), Color(1, 0.8, 0.9))
		# 你的箭頭
		var d := deg_to_rad(ph_sa)
		var tipv := Vector2(ph_sr * sin(d), ph_sr * cos(d)) if cosf else Vector2(ph_sr * cos(d), ph_sr * sin(d))
		var P := c + Vector2(tipv.x * sc, -tipv.y * sc)
		draw_arc(c, ph_sr * sc, 0, TAU, 64, Color(cyan.r, cyan.g, cyan.b, 0.22), 1.4, true)
		var ok := P.distance_to(tp) < 0.6
		if cosf:
			_arc_between(c, 30.0, PI / 2.0, PI / 2.0 - d, cyan, 2.2)
			MathLabel.draw_on(self, font, c.x + 18.0 * sin(d / 2.0) + 6.0, c.y - 40.0 * cos(d / 2.0) - 2.0, "θ", UITheme.fs(13), cyan)
		else:
			_arc_between(c, 30.0, 0.0, d, cyan, 2.2)
			MathLabel.draw_on(self, font, c.x + 44.0 * cos(d / 2.0), c.y - 44.0 * sin(d / 2.0) + 4.0, "φ", UITheme.fs(13), cyan)
		draw_line(c, P, UITheme.GOOD if ok else cyan, 3.5, true)
		UITheme.dot(self, P, 8.0, UITheme.GOOD if ok else cyan)
		UITheme.dot(self, P, 3.5, Color.WHITE)
		# 右邊：兩條波
		var x0 := rc.position.x + 264.0
		var w := rc.end.x - x0 - 14.0
		var y := rc.position.y + 66.0
		y = _line_text(font, x0, y, w, "金色：目標　藍色：你的", 12, Color(1, 1, 1, 0.65))
		var area := Rect2(x0, y - 6.0, w, 74.0)
		_plot_box(font, area, 0.0, 360.0, rmax, 90.0)
		_curve(area, 0.0, 360.0, rmax, func(xd: float): return fab(a, b, xd), UITheme.GOLD, 3.2)
		var rr := ph_sr
		var phd := ph_sa
		if cosf:
			_curve(area, 0.0, 360.0, rmax, func(xd: float): return rr * cos(deg_to_rad(xd - phd)), cyan, 2.2)
		else:
			_curve(area, 0.0, 360.0, rmax, func(xd: float): return rr * sin(deg_to_rad(xd + phd)), cyan, 2.2)
		y = area.end.y + 3.0
		y = _line_text(font, x0, y, w, "目標：%s" % String(spec.ftxt), 14, Color(0.95, 0.85, 0.5))
		var sgn := "−" if ph_ang < 0.0 or (cosf and ph_ang > 0.0) else "+"
		var mag := TideView.dec(absf(ph_ang))
		var yours := "你的：%s cos(x %s %s°)" % [ph_rt, "−" if ph_ang > 0.0 else "+", mag] if cosf else "你的：%s sin(x %s %s°)" % [ph_rt, sgn, mag]
		y = _line_text(font, x0, y, w, yours, 14, Color(0.6, 0.9, 1.0))
		var dd := (Vector2(tipv.x, tipv.y) - Vector2(a, b)).length() / maxf(Vector2(a, b).length(), 0.001)
		var k := clampf(1.0 - dd, 0.0, 1.0)
		var done := dd * Vector2(a, b).length() < 1e-4
		var bar := Rect2(x0, rc.end.y - 84.0, w, 9.0)
		draw_rect(bar, Color(1, 1, 1, 0.1))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), UITheme.GOOD if done else Color(1, 0.75, 0.4))
		_line_text(font, x0, rc.end.y - 70.0, w, "重合了！按「確定」" if done else "箭頭尖端離目標點還有距離", 14,
			UITheme.GOOD if done else Color(1, 0.92, 0.7))

	# --- peak ---

	func _draw_peak(font: Font, rc: Rect2) -> void:
		var a := float(spec.a)
		var b := float(spec.b)
		var dom: Array = spec.get("dom", [0.0, 360.0])
		var d0 := float(dom[0])
		var d1 := float(dom[1])
		var rm := Vector2(a, b).length()
		var ymax := rm * 1.12
		var area := Rect2(rc.position.x + 16.0, rc.position.y + 98.0, rc.size.x - 32.0, 104.0)
		var tick := 90.0 if d1 - d0 > 200.0 else 30.0
		_plot_box(font, area, d0, d1, ymax, tick)
		_curve(area, d0, d1, ymax, func(xd: float): return a * sin(deg_to_rad(xd)), Color(UITheme.CYAN.r, UITheme.CYAN.g, UITheme.CYAN.b, 0.55), 1.6)
		_curve(area, d0, d1, ymax, func(xd: float): return b * cos(deg_to_rad(xd)), Color(UITheme.ORANGE.r, UITheme.ORANGE.g, UITheme.ORANGE.b, 0.55), 1.6)
		_curve(area, d0, d1, ymax, func(xd: float): return fab(a, b, xd), UITheme.GOLD, 3.2)
		var xs := clampf(pk_show, d0, d1)
		var px := _px(area, d0, d1, xs)
		draw_line(Vector2(px, area.position.y), Vector2(px, area.end.y), Color(1, 1, 1, 0.45), 1.5)
		var xr := deg_to_rad(xs)
		var va := a * sin(xr)
		var vb := b * cos(xr)
		var f := va + vb
		UITheme.dot(self, Vector2(px, _py(area, ymax, va)), 5.0, UITheme.CYAN)
		UITheme.dot(self, Vector2(px, _py(area, ymax, vb)), 5.0, UITheme.ORANGE)
		var pf := Vector2(px, _py(area, ymax, f))
		UITheme.dot(self, pf, 12.0, Color(1, 0.85, 0.4, 0.3))
		UITheme.dot(self, pf, 6.0, UITheme.GOLD)
		var s := "x = %s°　　a sin x = %s　＋　b cos x = %s　＝　f(x) = %s" % [TideView.dec(pk_x), dec3(va), pn(vb), dec3(f)]
		_line_text(font, rc.position.x + 14.0, rc.position.y + 70.0, rc.size.x - 28.0, s, 15, Color(1, 0.95, 0.8))
		# 亮度
		var goal := String(spec.get("goal", "max"))
		var k := 0.0
		match goal:
			"max":
				k = f / rm * 0.5 + 0.5
			"min":
				k = -f / rm * 0.5 + 0.5
			_:
				k = 1.0 - absf(f) / rm
		k = clampf(k, 0.0, 1.0)
		var hit := false
		for xd in spec.xs:
			if absf(fposmod(pk_x - float(xd) + 180.0, 360.0) - 180.0) < 1e-6:
				hit = true
		var word: String = {"max": "光束亮度（越亮越接近最大）", "min": "光束暗度（越暗越接近最小）", "zero": "光束熄滅程度"}[goal]
		var bar := Rect2(rc.position.x + 16.0, rc.position.y + 230.0, rc.size.x - 32.0, 9.0)
		draw_rect(bar, Color(1, 1, 1, 0.1))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), UITheme.GOOD if hit else Color(1, 0.75, 0.4))
		var msg := "就是這裡！按「確定」" if hit else String(word)
		_line_text(font, rc.position.x + 14.0, rc.position.y + 208.0, rc.size.x - 28.0, msg, 13, UITheme.GOOD if hit else Color(1, 0.92, 0.7))

	# --- wave ---

	func _draw_wave(font: Font, rc: Rect2) -> void:
		var a := float(spec.a)
		var b := float(spec.b)
		var rm := Vector2(a, b).length()
		var ymax := rm * 1.25
		var area := Rect2(rc.position.x + 16.0, rc.position.y + 70.0, rc.size.x - 32.0, 138.0)
		_plot_box(font, area, 0.0, 360.0, ymax, 90.0)
		_curve(area, 0.0, 360.0, ymax, func(xd: float): return fab(a, b, xd), UITheme.GOLD, 3.4)
		var seq := tiles_seq.duplicate()
		if not seq.is_empty():
			_curve(area, 0.0, 360.0, ymax, func(xd: float): return wv_value(seq, xd), UITheme.CYAN, 2.2)
		for row in tiles_rows:
			var xd := float(row.a)
			var p := Vector2(_px(area, 0.0, 360.0, xd), _py(area, ymax, float(row.want)))
			var ok := bool(row.ok)
			UITheme.dot(self, p, 7.0, Color(0.2, 0.2, 0.3, 0.9))
			UITheme.dot(self, p, 4.0, UITheme.GOOD if ok else (UITheme.ROSE if not is_nan(float(row.got)) else Color(1, 1, 1, 0.4)))
		var n_ok := 0
		for row in tiles_rows:
			if bool(row.ok):
				n_ok += 1
		var msg := "全部吻合！按「確定」" if matched else "檢查點 %d / %d 吻合（金色是目標，藍色是你的）" % [n_ok, tiles_rows.size()]
		_line_text(font, rc.position.x + 14.0, rc.position.y + 216.0, rc.size.x - 28.0, msg, 14, UITheme.GOOD if matched else Color(1, 0.92, 0.7))

	const WV_NUM := {"√2": 1.4142135623730951, "√3": 1.7320508075688772}

	static func wv_tok(t: String) -> Array:
		match t:
			"+":
				return ["+", "op"]
			"−":
				return ["-", "op"]
			"×":
				return ["*", "op"]
			"÷":
				return ["/", "op"]
			"(":
				return ["(", "("]
			")":
				return [")", ")"]
			"sin x":
				return ["sin(x)", "atom"]
			"cos x":
				return ["cos(x)", "atom"]
		if t.begins_with("sin(x") or t.begins_with("cos(x"):
			var fn := t.substr(0, 3)
			var inner := t.substr(4, t.length() - 5)          # x+30°
			var sg := 1.0 if inner.substr(1, 1) == "+" else -1.0
			var num := float(inner.substr(2).trim_suffix("°"))
			return ["%s(x%+.15f)" % [fn, sg * deg_to_rad(num)], "atom"]
		# 數字："2"、"√3"、"1/2"、"√3/2"
		var parts := t.split("/")
		var vals := []
		for p in parts:
			vals.append(float(WV_NUM[p]) if WV_NUM.has(p) else float(p))
		if vals.size() == 2:
			return ["(%.15f/%.15f)" % [vals[0], vals[1]], "atom"]
		return ["%.15f" % vals[0], "atom"]


	static func wv_expr(seq: Array) -> String:
		var out := ""
		var prev := ""
		for t in seq:
			var tk := wv_tok(String(t))
			var kind: String = tk[1]
			if (prev == "atom" or prev == ")") and (kind == "atom" or kind == "("):
				out += "*"
			out += String(tk[0])
			prev = kind
		return out


	static func wv_value(seq: Array, xdeg: float) -> float:
		if seq.is_empty():
			return NAN
		var ex := Expression.new()
		if ex.parse(wv_expr(seq), ["x"]) != OK:
			return NAN
		var res = ex.execute([deg_to_rad(xdeg)], null, false)
		if ex.has_execute_failed() or not (res is float or res is int):
			return NAN
		return float(res)
