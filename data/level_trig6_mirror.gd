extends "level_trig5_compass.gd"
## 三角函數 第六大關「倍角鏡池」（對應講義 1-2 重點二：二倍角與半角公式）
## 繼承第五關（夜海背景、函數圖、積木面板的小工具都一樣），題庫在 trig6_bank.gd。
##
## 這一關多了兩種「動手」的步驟：
##   ・mirror 鏡池：轉動鏡面 φ，把橫軸那條線反射出去，反射線剛好在 2φ——二倍角就是鏡子裡的角。
##             double／half：轉鏡面，讓反射線對準金色的目標角（半角就是「找鏡面在哪裡」）
##             sweep：拖動 θ 掃過整個範圍，看 θ/2 落在哪個象限、sin、cos、tan 的正負怎麼變
##   ・eq     拼公式：像第五關的積木，但只有一個角 θ（sin θ、cos θ、tan θ、sin² θ、cos² θ…），
##             用 4 個角度檢查你的式子（例如 cos 2θ 可以用 cos θ 拼，也可以用 sin θ 拼）
##   速算：已知 sin θ、cos θ 或 tan θ 與象限，說出 sin 2θ、cos 2θ、tan 2θ
##   介面引導：第一次進來，控制項會閃動，畫面上有箭頭提示；右邊卡片放不下時會自動收起不重要的字，不會超出畫面

const BankG6 := preload("trig6_bank.gd")
const POOL := UITheme.GOLD

const CHAPTERS_G6 := [
	{"ch": 1, "name": "第一章．鏡面倍角", "topic": "二倍角公式、cos 2θ 的三種樣子、求值與合併", "color": UITheme.GOLD},
	{"ch": 2, "name": "第二章．半角與化簡", "topic": "半角公式與象限、根號化簡、以切表弦、連乘積、極值", "color": UITheme.GOLD_LIGHT},
]

var mir_info: MathLabel
var _pulse_tw: Tween
var _pulse_ctl: Control


func level_id() -> String:
	return "G6"

func level_title() -> String:
	return "倍角鏡池"

func level_subtitle() -> String:
	return "二倍角與半角公式"

func level_chapters() -> Array:
	return CHAPTERS_G6

func bank_slots() -> Array:
	return BankG6.slots()

func step_color() -> Color:
	return POOL

func chapter_card() -> Dictionary:
	return {"title": "第二章．半角與化簡", "button": "進入半角與化簡  ▶",
		"text": "倍角會了，把鏡子倒著看就是半角：\n\n" \
			+ "・半角公式：sin²(θ/2)、cos²(θ/2)、tan(θ/2)\n" \
			+ "・θ/2 在哪個象限？正負號靠它決定\n" \
			+ "・1 ± sin 2θ 是完全平方：根號化簡\n" \
			+ "・只知道 tan θ：用「以切表弦」求 sin 2θ\n" \
			+ "・連乘積、最大最小值\n\n" \
			+ "潛下去看看吧！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = MirrorView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "速算"
		_tv().tide_changed.connect(_on_tide_changed)
		_tv().tap_missed.connect(_on_tap_missed)


func _mv() -> MirrorView:
	return fview as MirrorView


func _on_tide_changed() -> void:
	if fview == null:
		return
	match _tv().mode:
		"mirror":
			_refresh_mirror()
		"eq":
			_refresh_eq()
		_:
			super()


func _forge_step() -> void:
	_stop_attract()
	super()
	if si >= steps.size():
		return
	var st: Dictionary = steps[si]
	match String(st.kind):
		"mirror":
			_build_mirror(st)
		"eq":
			_build_eq(st)


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size():
		match String(steps[si].kind):
			"mirror":
				_mirror_submit()
				return
			"eq":
				_eq_submit()
				return
	super()


func _custom_reveal(msg: String) -> void:
	_stop_attract()
	super(msg)


# ================= 引導：閃動的控制項 =================

## 第一次看到這個控制項時閃一閃，提醒學生「從這裡開始」；一動就停
func _attract(c: Control) -> void:
	_stop_attract()
	_pulse_ctl = c
	_pulse_tw = c.create_tween().set_loops()
	_pulse_tw.tween_property(c, "modulate", Color(1.45, 1.45, 1.1, 1.0), 0.55).set_trans(Tween.TRANS_SINE)
	_pulse_tw.tween_property(c, "modulate", Color.WHITE, 0.55).set_trans(Tween.TRANS_SINE)


func _stop_attract() -> void:
	if _pulse_tw != null:
		_pulse_tw.kill()
		_pulse_tw = null
	if _pulse_ctl != null and is_instance_valid(_pulse_ctl):
		_pulse_ctl.modulate = Color.WHITE
	_pulse_ctl = null
	if fview != null:
		_mv().guide_text = ""


# ================= mirror：鏡池 =================

func _build_mirror(st: Dictionary) -> void:
	_prep_panel(st)
	var tv := _mv()
	var sweep: bool = String(st.mode) == "sweep"
	var card := _info_card(POOL)
	mir_info = _math_label(19, 330, 50, UITheme.TEXT)
	card.add_child(mir_info)
	var rg: Array = st.get("range", [0.0, 180.0])
	var step := float(st.get("step", 15.0))
	var n := int(round((float(rg[1]) - float(rg[0])) / step))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	rank_box.add_child(row)
	var nm := Label.new()
	nm.text = "θ 角" if sweep else "φ 鏡面"
	nm.custom_minimum_size = Vector2(64, 0)
	nm.add_theme_font_size_override("font_size", UITheme.fs(15))
	nm.add_theme_color_override("font_color", UITheme.CYAN)
	row.add_child(nm)
	var s := UITheme.touch_slider()
	s.min_value = 0
	s.max_value = n
	s.step = 1
	var i0 := clampi(int(round((float(st.get("start", rg[0])) - float(rg[0])) / step)), 0, n)
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
	var lo := float(rg[0])
	vl.text = "%s°" % TideView.dec(lo + i0 * step)
	s.value_changed.connect(func(v: float):
		if busy:
			return
		var deg := lo + v * step
		_mv().mir_phi = deg
		_mv().mir_lo = minf(_mv().mir_lo, deg)
		_mv().mir_hi = maxf(_mv().mir_hi, deg)
		vl.text = "%s°" % TideView.dec(deg)
		MoonView.dragged_ever = true
		_stop_attract()
		Game.of(self).play("blip", 0.8 + 0.03 * v, -18.0)
		_refresh_mirror())
	tv.mir_phi = lo + i0 * step
	tv.mir_show = tv.mir_phi
	tv.mir_lo = tv.mir_phi
	tv.mir_hi = tv.mir_phi
	tv.mode = "mirror"
	tv.spec = st
	tv.circ = {}
	tv.task_q = String(st.q)
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_attract(row)
	tv.guide_text = "① 拖動右邊的滑桿" if not sweep else "① 拖動右邊的 θ 滑桿"
	_refresh_mirror()


func _refresh_mirror() -> void:
	if mir_info == null or not is_instance_valid(mir_info):
		return
	var st: Dictionary = steps[si]
	var tv := _mv()
	if String(st.mode) == "sweep":
		mir_info.text = "θ = %s°\nθ/2 = %s°" % [TideView.dec(tv.mir_phi), TideView.dec(tv.mir_phi / 2.0)]
	else:
		mir_info.text = "鏡面 φ = %s°\n反射線 2φ = %s°" % [TideView.dec(tv.mir_phi), TideView.dec(tv.mir_phi * 2.0)]
	tv.queue_redraw()


func _mirror_submit() -> void:
	var st: Dictionary = steps[si]
	var tv := _mv()
	if String(st.mode) == "sweep":
		var band: Array = st.band
		var lo := float(band[0]) + float(st.get("step", 15.0))
		var hi := float(band[1]) - float(st.get("step", 15.0))
		if tv.mir_lo > lo + 1e-6 or tv.mir_hi < hi - 1e-6:
			var need := "θ 拖到 %s°（最小那頭）" % TideView.dec(lo) if tv.mir_lo > lo + 1e-6 else "θ 拖到 %s°（最大那頭）" % TideView.dec(hi)
			_hint("還沒有走完整個範圍：把 %s，看看 θ/2 會走到哪裡。" % need, "info")
			return
		Game.of(self).sfx("correct")
		tv.burst_center()
		_interact_done(st, {})
		return
	var res := tv.mir_phi * 2.0
	if absf(fposmod(res - float(st.target) + 180.0, 360.0) - 180.0) > 1e-6:
		var d := fposmod(float(st.target) - res + 180.0, 360.0) - 180.0
		_wrong(st, "現在反射線在 %s°，離目標還差 %s°（%s）。提示：%s" % [TideView.dec(res), TideView.dec(absf(d)),
			"鏡面轉大一點" if d > 0.0 else "鏡面轉小一點", String(st.nudge)])
		return
	Game.of(self).sfx("correct")
	tv.burst_center()
	var rad := deg_to_rad(float(st.target))
	_interact_done(st, {"theta": rad, "label": "%s°" % TideView.dec(float(st.target))})


# ================= eq：拼公式（一個角 θ） =================

const EQ_VARS := ["s", "c", "t"]
const EQ_MAP := {"sin θ": "s", "cos θ": "c", "tan θ": "t", "sin² θ": "(s*s)", "cos² θ": "(c*c)",
	"+": "+", "−": "-", "×": "*", "÷": "/", "(": "(", ")": ")", "1": "1.0", "2": "2.0"}
const EQ_SAMPLES := [30.0, 50.0, 110.0, 200.0]


static func eq_target(key: String, th: float) -> float:
	match key:
		"sin2":
			return sin(2.0 * th)
		"cos2":
			return cos(2.0 * th)
		"tan2":
			return tan(2.0 * th)
		"half_sin2":
			return sin(th / 2.0) * sin(th / 2.0)
		"half_cos2":
			return cos(th / 2.0) * cos(th / 2.0)
	return tan(th / 2.0)


static func eq_expr(seq: Array) -> String:
	var out := ""
	var prev := ""
	for t in seq:
		var s: String = EQ_MAP[t]
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


static func eq_value(seq: Array, th: float) -> float:
	if seq.is_empty():
		return NAN
	var ex := Expression.new()
	if ex.parse(eq_expr(seq), EQ_VARS) != OK:
		return NAN
	var res = ex.execute([sin(th), cos(th), tan(th)], null, false)
	if ex.has_execute_failed() or not (res is float or res is int):
		return NAN
	return float(res)


func _build_eq(st: Dictionary) -> void:
	_build_tiles(st)
	var tv := _mv()
	tv.mode = "eq"
	tv.guide_text = "① 點右邊的積木"
	_refresh_eq()


## 第五關的積木按鈕按下去會呼叫 _refresh_tiles：這裡改成算 θ 的
func _refresh_tiles() -> void:
	if si < steps.size() and String(steps[si].kind) == "eq":
		_refresh_eq()
		return
	super()


func _refresh_eq() -> void:
	if tiles_fx == null or not is_instance_valid(tiles_fx) or si >= steps.size():
		return
	var st: Dictionary = steps[si]
	var tv := _mv()
	if not tv.tiles_seq.is_empty():
		tv.guide_text = ""
	var rows := []
	var all_ok := not tv.tiles_seq.is_empty()
	for d in EQ_SAMPLES:
		var th := deg_to_rad(float(d))
		var want := eq_target(String(st.target), th)
		var got := eq_value(tv.tiles_seq, th)
		var ok := not is_nan(got) and absf(got - want) < 1e-6 * maxf(1.0, absf(want))
		if not ok:
			all_ok = false
		rows.append({"a": d, "b": 0.0, "want": want, "got": got, "ok": ok})
	tv.tiles_rows = rows
	tv.matched = all_ok
	var body := "  ".join(tv.tiles_seq) if not tv.tiles_seq.is_empty() else "（還沒有積木）"
	tiles_fx.text = "%s =\n%s" % [String(st.expr), body]
	tv.queue_redraw()


func _eq_submit() -> void:
	var st: Dictionary = steps[si]
	var tv := _mv()
	if tv.tiles_seq.is_empty():
		_wrong(st, "還沒有放積木喔！點右邊的積木，把公式拼出來。")
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
				msg += "代 θ = %d°：你的式子 = %s，但 %s = %s。" % [int(row.a), CompassView.dec3(float(row.got)),
					String(st.expr), CompassView.dec3(float(row.want))]
			break
	_wrong(st, msg + "提示：" + String(st.nudge).replace(" ÷ ", " 除以 "))


# ================= 速算 =================

func _speed_gen(kind: String, n: int) -> Array:
	if kind != "mirror":
		return super(kind, n)
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 2000:
		guard += 1
		var pb := _gen_mirror()
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		out.append(pb)
	return out


const TRIPLES := [[3, 4, 5], [5, 12, 13], [8, 15, 17], [7, 24, 25], [20, 21, 29]]
const QNAME := ["第一", "第二", "第三", "第四"]


## 已知 sin θ（或 cos θ、tan θ）和象限，求 sin 2θ、cos 2θ、tan 2θ
static func _gen_mirror() -> Dictionary:
	var tr: Array = TRIPLES.pick_random()
	var a: int = tr[0]          # sin θ 的分子
	var b: int = tr[1]          # cos θ 的分子
	if randi() % 2 == 0:
		var tmp := a
		a = b
		b = tmp
	var c: int = tr[2]
	var q: int = randi() % 4
	var sa: int = 1 if q < 2 else -1
	var sb: int = 1 if (q == 0 or q == 3) else -1
	var given: String = ["sin", "cos", "tan"].pick_random()
	var gtext := ""
	match given:
		"sin":
			gtext = "sin θ = %s" % _frac(sa * a, c)
		"cos":
			gtext = "cos θ = %s" % _frac(sb * b, c)
		_:
			gtext = "tan θ = %s" % _frac(sa * sb * a, b)
	var ask: String = ["sin", "cos", "tan"].pick_random()
	if ask == "tan" and a == b:
		ask = "sin"
	var ans := ""
	var hint := ""
	match ask:
		"sin":
			ans = _frac(2 * a * b * sa * sb, c * c)
			hint = "先用象限定另一個值的正負，再 sin 2θ = 2 sin θ cos θ。"
		"cos":
			ans = _frac(b * b - a * a, c * c)
			hint = "cos 2θ = cos²θ − sin²θ（平方之後正負號不重要）。"
		_:
			ans = _frac(2 * a * b * sa * sb, b * b - a * a)
			hint = "tan 2θ = sin 2θ ÷ cos 2θ。"
	return {"eq": "%s（θ 在%s象限）" % [gtext, QNAME[q]], "q": "求 %s 2θ。" % ask, "template": "%s 2θ = [0]" % ask,
		"ans": ans, "nudge": hint, "tag": BankG6.T_DBL}


# ================= 畫面 =================

class MirrorView extends CompassView:
	var mir_phi := 0.0
	var mir_show := 0.0
	var mir_lo := 0.0
	var mir_hi := 0.0
	var guide_text := ""

	func _process(delta: float) -> void:
		if mode == "mirror":
			mir_show = lerpf(mir_show, mir_phi, 1.0 - exp(-12.0 * delta))
		super(delta)

	func _draw_mode(font: Font) -> void:
		if mode != "mirror" and mode != "eq":
			super(font)
			return
		var rc := _spin_rect()
		draw_style_box(UITheme.boxc(Color(0.03, 0.06, 0.14, 0.62), 14, Color(1.0, 0.85, 0.4, 0.28), 1, 0), rc)
		_draw_task(font, rc, "鏡池")
		if mode == "mirror":
			_draw_mirror(font, rc)
		else:
			_draw_eq(font, rc)
		_draw_guide(font, rc)

	## 閃動的箭頭提示：「從哪裡開始」（右上角，箭頭指向右邊的控制面板）
	func _draw_guide(font: Font, rc: Rect2) -> void:
		if guide_text == "":
			return
		var fs := UITheme.fs(14)
		var w := MathLabel.text_width(font, guide_text, fs) + 30.0
		var k := 0.5 + 0.5 * sin(t * 5.0)
		var x := rc.end.x - w - 18.0 + 5.0 * k
		var y := rc.position.y + 38.0
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 0.85, 0.4, 0.92)
		sb.set_corner_radius_all(14)
		draw_style_box(sb, Rect2(x, y, w, 26.0))
		draw_colored_polygon(PackedVector2Array([Vector2(x + w - 2.0, y + 3.0), Vector2(x + w + 12.0, y + 13.0), Vector2(x + w - 2.0, y + 23.0)]),
			Color(1, 0.85, 0.4, 0.92))
		MathLabel.draw_on(self, font, x + w / 2.0, y + 19.0, guide_text, fs, Color(0.12, 0.08, 0.2))

	func _unit_circle(c: Vector2, rad: float) -> void:
		draw_line(c - Vector2(rad + 16, 0), c + Vector2(rad + 16, 0), Color(1, 1, 1, 0.3), 1.2)
		draw_line(c - Vector2(0, rad + 16), c + Vector2(0, rad + 16), Color(1, 1, 1, 0.3), 1.2)
		draw_arc(c, rad, 0, TAU, 96, Color(1, 1, 1, 0.5), 2.0, true)
		for k in 24:
			var ang := k * PI / 12.0
			var dv := Vector2(cos(ang), -sin(ang))
			var l := 8.0 if k % 6 == 0 else (5.0 if k % 2 == 0 else 3.0)
			draw_line(c + dv * (rad - l), c + dv * (rad + l), Color(1, 1, 1, 0.45 if k % 6 == 0 else 0.22), 1.2)

	func _wedge(c: Vector2, rad: float, a0: float, a1: float, col: Color) -> void:
		var pts := PackedVector2Array([c])
		var n := maxi(4, int(absf(a1 - a0) / 0.06))
		for i in n + 1:
			var a := lerpf(a0, a1, float(i) / n)
			pts.append(c + Vector2(cos(a), -sin(a)) * rad)
		draw_colored_polygon(pts, col)

	## 負數加括號：× (−0.5)、1 − (−0.7)
	static func pn(v: float) -> String:
		var t := dec3(v)
		return "(%s)" % t if v < -0.0005 else t

	func _line_text(font: Font, x0: float, y: float, w: float, s: String, fs0: int, col: Color) -> float:
		var fs := UITheme.fs(fs0)
		var tw := MathLabel.text_width(font, s, fs)
		while fs > UITheme.fs(11) and tw > w:
			fs -= 1
			tw = MathLabel.text_width(font, s, fs)
		var ex := MathLabel.line_extent(s, fs)
		MathLabel.draw_on(self, font, x0 + tw / 2.0, y + ex.x, s, fs, col)
		return y + ex.x + ex.y + 9.0

	func _draw_mirror(font: Font, rc: Rect2) -> void:
		var c := Vector2(rc.position.x + 132.0, rc.position.y + 170.0)
		var rad := 90.0
		_unit_circle(c, rad)
		var cyan := UITheme.CYAN
		var gold := UITheme.GOLD
		var x0 := rc.position.x + 264.0
		var w := rc.end.x - x0 - 14.0
		if String(spec.mode) == "sweep":
			var band: Array = spec.band
			var b0 := deg_to_rad(float(band[0]))
			var b1 := deg_to_rad(float(band[1]))
			_wedge(c, rad, b0, b1, Color(1, 0.5, 0.75, 0.13))
			_wedge(c, rad, b0 / 2.0, b1 / 2.0, Color(0.35, 0.85, 1.0, 0.13))
			var th := deg_to_rad(mir_show)
			var ph := th / 2.0
			var pt := c + Vector2(cos(th), -sin(th)) * rad
			var pp := c + Vector2(cos(ph), -sin(ph)) * rad
			_arc_between(c, 26.0, 0.0, ph, cyan, 2.5)
			_arc_between(c, 38.0, 0.0, th, gold, 2.5)
			draw_line(c, c + Vector2(rad, 0), Color(1, 1, 1, 0.5), 2.0)
			draw_line(c, pt, gold, 3.0, true)
			draw_line(c, pp, cyan, 3.0, true)
			UITheme.dot(self, pt, 7.0, gold)
			UITheme.dot(self, pp, 7.0, cyan)
			MathLabel.draw_on(self, font, pt.x + 15.0 * cos(th), pt.y - 15.0 * sin(th), "θ", UITheme.fs(15), gold)
			MathLabel.draw_on(self, font, pp.x + 15.0 * cos(ph), pp.y - 15.0 * sin(ph), "θ/2", UITheme.fs(14), cyan)
			var y := rc.position.y + 60.0
			y = _line_text(font, x0, y, w, "粉色：θ 的範圍　藍色：θ/2 的範圍", 12, Color(1, 1, 1, 0.65))
			var sh := sin(ph)
			var ch := cos(ph)
			var th2 := tan(ph)
			var items := [["sin(θ/2)", sh], ["cos(θ/2)", ch], ["tan(θ/2)", th2]]
			for i in 3:
				var v: float = items[i][1]
				MathLabel.draw_on(self, font, x0 + 52.0 + 118.0 * i, y + 16.0, "%s" % String(items[i][0]), UITheme.fs(14), Color(1, 1, 1, 0.75))
				MathLabel.draw_on(self, font, x0 + 52.0 + 118.0 * i, y + 42.0, "＋" if v > 0.0 else "－", UITheme.fs(26), UITheme.GOOD if v > 0.0 else UITheme.ROSE)
			y += 62.0
			var q := int(floor(fposmod(mir_show / 2.0, 360.0) / 90.0))
			y = _line_text(font, x0, y, w, "θ/2 在第%s象限" % ["一", "二", "三", "四"][q], 18, gold)
			var step := float(spec.get("step", 15.0))
			var lo := float(band[0]) + step
			var hi := float(band[1]) - step
			var done_lo := mir_lo <= lo + 1e-6
			var done_hi := mir_hi >= hi - 1e-6
			var msg := "走訪：%s 小端 %s　大端 %s" % ["✓" if done_lo and done_hi else "…", "✓" if done_lo else "○", "✓" if done_hi else "○"]
			_line_text(font, x0, rc.end.y - 70.0, w, msg, 14, UITheme.GOOD if done_lo and done_hi else Color(1, 0.92, 0.7))
			return
		# 鏡面：把橫軸反射到 2φ
		var ph2 := deg_to_rad(mir_show)
		var th2r := ph2 * 2.0
		var dv := Vector2(cos(ph2), -sin(ph2))
		# 鏡子
		draw_line(c - dv * (rad + 22.0), c + dv * (rad + 22.0), Color(cyan.r, cyan.g, cyan.b, 0.35), 8.0)
		draw_line(c - dv * (rad + 22.0), c + dv * (rad + 22.0), cyan, 2.5, true)
		var nv := Vector2(-dv.y, dv.x)
		for i in range(-6, 7):
			var p0 := c + dv * (float(i) * 14.0)
			draw_line(p0, p0 + (nv + dv) * 6.0, Color(cyan.r, cyan.g, cyan.b, 0.5), 1.2)
		if spec.has("target"):
			var tr := deg_to_rad(float(spec.target))
			var pt := c + Vector2(cos(tr), -sin(tr)) * rad
			draw_dashed_line(c, c + Vector2(cos(tr), -sin(tr)) * (rad + 18.0), Color(1, 0.6, 0.8, 0.9), 2.5, 6.0)
			UITheme.dot(self, pt, 9.0, Color(1, 0.6, 0.8, 0.4))
			UITheme.dot(self, pt, 4.5, Color(1, 0.6, 0.8))
			MathLabel.draw_on(self, font, pt.x + 22.0 * cos(tr), pt.y - 22.0 * sin(tr), "目標 %s°" % dec(float(spec.target)), UITheme.fs(12), Color(1, 0.75, 0.88))
		_arc_between(c, 30.0, 0.0, ph2, cyan, 2.5)
		_arc_between(c, 42.0, ph2, th2r, Color(cyan.r, cyan.g, cyan.b, 0.55), 2.5)
		draw_line(c, c + Vector2(rad, 0), Color(1, 1, 1, 0.6), 2.5)
		var pr := c + Vector2(cos(th2r), -sin(th2r)) * rad
		draw_line(c, pr, gold, 3.5, true)
		UITheme.dot(self, pr, 8.0, gold)
		UITheme.dot(self, pr, 3.5, Color.WHITE)
		MathLabel.draw_on(self, font, c.x + 40.0 * cos(ph2 / 2.0) + 4.0, c.y - 40.0 * sin(ph2 / 2.0) + 4.0, "φ", UITheme.fs(13), cyan)
		if absf(ph2) > 0.3:
			var am := ph2 * 1.5
			MathLabel.draw_on(self, font, c.x + 56.0 * cos(am), c.y - 56.0 * sin(am) + 4.0, "φ", UITheme.fs(13), Color(cyan.r, cyan.g, cyan.b, 0.7))
		# 右邊：公式與數字
		var phd := mir_show
		var P := deg_to_rad(phd)
		var sp := sin(P)
		var cp := cos(P)
		var th := 2.0 * P
		var y := rc.position.y + 62.0
		if String(spec.get("show", "dbl")) == "dbl":
			y = _line_text(font, x0, y, w, "sin 2φ = 2 sin φ cos φ", 15, Color(0.9, 0.95, 1.0))
			y = _line_text(font, x0, y, w, "= 2 × %s × %s = %s" % [pn(sp), pn(cp), dec3(sin(th))], 15, gold)
			y = _line_text(font, x0, y + 2.0, w, "cos 2φ = cos²φ − sin²φ", 15, Color(0.9, 0.95, 1.0))
			y = _line_text(font, x0, y, w, "= %s − %s = %s" % [dec3(cp * cp), dec3(sp * sp), dec3(cos(th))], 15, gold)
		else:
			y = _line_text(font, x0, y, w, "θ = 2φ = %s°" % dec(phd * 2.0), 16, gold)
			y = _line_text(font, x0, y, w, "sin²φ = \\frac{1}{2}(1 − cos θ)", 15, Color(0.9, 0.95, 1.0))
			y = _line_text(font, x0, y, w, "= \\frac{1}{2}(1 − %s) = %s" % [pn(cos(th)), dec3(sp * sp)], 15, gold)
			y = _line_text(font, x0, y + 2.0, w, "cos²φ = \\frac{1}{2}(1 + cos θ)", 15, Color(0.9, 0.95, 1.0))
			y = _line_text(font, x0, y, w, "= \\frac{1}{2}(1 + %s) = %s" % [pn(cos(th)), dec3(cp * cp)], 15, gold)
		# 接近度：離目標還差多少
		if spec.has("target"):
			var d := absf(fposmod(deg_to_rad(float(spec.target)) - th + PI, TAU) - PI)
			var k := clampf(1.0 - rad_to_deg(d) / 180.0, 0.0, 1.0)
			var bar := Rect2(x0, rc.end.y - 84.0, w, 10.0)
			draw_rect(bar, Color(1, 1, 1, 0.1))
			var ok := d < 1e-6
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), UITheme.GOOD if ok else Color(1, 0.75, 0.4))
			var lab := "對準了！按「確定」" if ok else "反射線離目標還差 %s°" % dec(rad_to_deg(d))
			_line_text(font, x0, rc.end.y - 70.0, w, lab, 14, UITheme.GOOD if ok else Color(1, 0.92, 0.7))

	# --- eq：拼公式（θ） ---

	func _draw_eq(font: Font, rc: Rect2) -> void:
		var x0 := rc.position.x + 20.0
		var y0 := rc.position.y + 58.0
		var colx := [x0, x0 + 170.0, x0 + 340.0, x0 + 500.0]
		var heads := ["θ", "正確的值", "你的式子"]
		for i in 3:
			MathLabel.draw_on(self, font, colx[i] + 50.0, y0 + 10.0, heads[i], UITheme.fs(14), Color(1, 1, 1, 0.6))
		draw_line(Vector2(x0, y0 + 20.0), Vector2(rc.end.x - 20.0, y0 + 20.0), Color(1, 1, 1, 0.2), 1.0)
		var y := y0 + 48.0
		for row in tiles_rows:
			var ok := bool(row.ok)
			var col := UITheme.GOOD if ok else (UITheme.ROSE if not is_nan(float(row.got)) else Color(1, 1, 1, 0.35))
			MathLabel.draw_on(self, font, colx[0] + 50.0, y, "%d°" % int(row.a), UITheme.fs(16), Color(0.85, 0.92, 1.0))
			MathLabel.draw_on(self, font, colx[1] + 50.0, y, dec3(float(row.want)), UITheme.fs(16), UITheme.GOLD)
			MathLabel.draw_on(self, font, colx[2] + 50.0, y, dec3(float(row.got)), UITheme.fs(16), col)
			MathLabel.draw_on(self, font, colx[3] + 20.0, y, "✓" if ok else ("✗" if not is_nan(float(row.got)) else ""), UITheme.fs(20), col)
			y += 40.0
		if matched:
			MathLabel.draw_on(self, font, rc.end.x - 90.0, rc.end.y - 22.0, "全部吻合！按確定", UITheme.fs(16), UITheme.GOOD)
		else:
			MathLabel.draw_on(self, font, rc.position.x + 200.0, rc.end.y - 22.0, "每一列都要「正確的值＝你的式子」", UITheme.fs(13), Color(1, 1, 1, 0.55))
