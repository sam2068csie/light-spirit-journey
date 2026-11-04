extends "res://data/levels/poly/level_poly7_crystal.gd"
## 多項式 第八大關「符號地下河」（對應講義 4-3 重點二：二次不等式、重點三：特殊不等式）
## 引擎是 step_level.gd，畫面沿用第五～七關的座標圖，題庫在 poly8_bank.gd。
##
## 新的 graph 步驟（寫法見 poly8_bank.gd 開頭）：
##   pick   點亮河段、切換閘門的實心／空心　　wave   奇穿偶彈：決定出發的位置、每一道閘門穿過或彈回
##   pgate  拖動含參數的閘門，讓指定的數落在河段裡
## 數線就是地下河：f(x) > 0 的地方浮在地上（亮），f(x) < 0 的地方沉在地下（暗）。圖上不寫中文。

const BankP8 := preload("res://data/levels/poly/poly8_bank.gd")
const RIVER_C := Color("6fe3d0")

const CHAPTERS_P8 := [
	{"ch": 1, "name": "第一章．二次的河", "topic": "解二次不等式、無解、含參數、反推係數、聯立、變數變換", "color": Color("6fe3d0")},
	{"ch": 2, "name": "第二章．高次與分式的河", "topic": "奇穿偶彈、重根、反推、看圖解不等式、分式、應用、相同解", "color": UITheme.PINK},
]

const MODES_P8 := ["pick", "wave", "pgate"]

var wave_box: HBoxContainer


func level_id() -> String:
	return "P8"

func level_title() -> String:
	return "符號地下河"

func level_subtitle() -> String:
	return "多項式不等式"

func level_chapters() -> Array:
	return CHAPTERS_P8

func bank_slots() -> Array:
	return BankP8.slots()

func step_color() -> Color:
	return RIVER_C

func stage_style() -> Dictionary:
	return {"sky_top": Color("07141a"), "sky_bot": Color("040a0e"), "scenery": "none", "ambient": "currents"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．高次與分式的河", "button": "潛入更深的河  ▶",
		"text": "更深的地方，閘門更多了：\n\n" \
			+ "・奇穿偶彈：奇次穿過、偶次彈回\n" \
			+ "・恆正的因式可以直接拿掉\n" \
			+ "・分母的根是禁區，一定空心\n" \
			+ "・看圖、換閘門、應用題\n\n" \
			+ "準備下潛！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = RiverView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "河道速算"
		fview.speed_y = 0.42


func _rv() -> RiverView:
	return fview as RiverView


# ================= graph 步驟 =================

func _build_graph(st: Dictionary) -> void:
	super(st)
	var mode := String(st.mode)
	if not (mode in MODES_P8):
		return
	var lv := _rv()
	wave_box = null
	match mode:
		"pick":
			go_btn.text = "就是這些河段"
			_pick_guard()
			fview.live_q = "點河段亮起來，點閘門切換 ●／○，再按確定。"
		"pgate":
			var rg: Array = st.get("arange", [-6, 6])
			_add_slider("a", "a", float(rg[0]), float(rg[1]), 1)
			go_btn.text = "都在裡面了"
			fview.live_q = "拖動閘門（在圖上拖或拉右邊的滑桿），再按「都在裡面了」。"
		"wave":
			go_btn.visible = false
			wave_box = HBoxContainer.new()
			wave_box.add_theme_constant_override("separation", 10)
			rank_box.add_child(wave_box)
			_wave_buttons()
			fview.live_q = "從最右邊開始放水，一道一道決定。"
	_on_graph_move()


## 奇穿偶彈的兩顆大按鈕：一開始是「地上／地下」，之後是「穿過／彈回」
func _wave_buttons() -> void:
	if wave_box == null or not is_instance_valid(wave_box):
		return
	for ch in wave_box.get_children():
		ch.queue_free()
	var lv := _rv()
	var opts := ["↑ 地上", "↓ 地下"] if lv.wstage == 0 else ["穿過", "彈回"]
	for i in 2:
		var b := Button.new()
		b.text = opts[i]
		b.custom_minimum_size = Vector2(0, 64)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", UITheme.fs(20))
		var idx: int = i
		b.pressed.connect(func(): _wave_pick(idx))
		wave_box.add_child(b)


func _wave_pick(i: int) -> void:
	if busy or si >= steps.size():
		return
	var st: Dictionary = steps[si]
	if String(st.get("kind", "")) != "graph" or String(st.mode) != "wave":
		return
	var lv := _rv()
	var n: int = st.pts.size()
	if lv.wstage == 0:
		var want := 0 if int(st.lead) > 0 else 1
		if i != want:
			_wrong(st, "最高次係數%s，x 很大的時候 f(x) 是%s的：最右邊要從%s出發。" % ["為正" if want == 0 else "為負", "正" if want == 0 else "負", "地上" if want == 0 else "地下"])
			return
	else:
		var gi := n - lv.wstage
		var m: int = int(st.mult[gi])
		var want2 := 0 if m % 2 == 1 else 1
		if i != want2:
			_wrong(st, "閘門 %s 是 %d 次：%s。提示：%s" % [String(st.labels[gi]), m, "奇數次要穿過" if want2 == 0 else "偶數次要彈回", st.nudge])
			return
	Game.of(self).sfx("correct")
	lv.wstage += 1
	lv.queue_redraw()
	if lv.wstage > n:
		_graph_done(st)
		return
	_wave_buttons()
	_on_graph_move()


func _graph_submit(st: Dictionary) -> void:
	var lv := _rv()
	match String(st.mode):
		"pick":
			var seg_ok := true
			for j in st.segs.size():
				if bool(lv.sel_seg[j]) != bool(st.segs[j]):
					seg_ok = false
			var pt_ok := true
			for j in st.ptsin.size():
				if bool(lv.sel_pt[j]) != bool(st.ptsin[j]):
					pt_ok = false
			if seg_ok and pt_ok:
				_graph_done(st)
				return
			if not seg_ok:
				_wrong(st, "河段還不對（亮的地方要剛好是符合的地方）。提示：%s" % st.nudge)
			else:
				_wrong(st, "河段對了！閘門的 ●（取）／○（不取）還不對：有等號的才取得到。提示：%s" % st.nudge)
		"pgate":
			if lv.marks_inside() == st.marks.size():
				_graph_done(st)
				return
			_wrong(st, "還有數不在河段裡（%d／%d）。提示：%s" % [lv.marks_inside(), st.marks.size(), st.nudge])
		_:
			super(st)


## 防呆：還沒點亮任何河段、也沒點任何閘門時，按鈕先灰掉（題目本來就沒有解時例外）
func _pick_guard() -> void:
	if si >= steps.size():
		return
	var st: Dictionary = steps[si]
	if String(st.get("kind", "")) != "graph" or String(st.get("mode", "")) != "pick":
		return
	var lv := _rv()
	var any: bool = lv.sel_seg.has(true) or lv.sel_pt.has(true)
	var need: bool = st.segs.has(true) or st.ptsin.has(true)
	go_btn.disabled = not any and need
	go_btn.text = "就是這些河段" if (any or not need) else "先點亮河段"


func _on_graph_move() -> void:
	super()
	_pick_guard()


# ================= 速算 =================

func _speed_tag() -> String:
	return BankP8.T_Q2


func _speed_gen(kind: String, n: int) -> Array:
	return gen_river(kind, n)


static func _lin(r: int) -> String:
	return xh(r)


## 速算：
##   river1  (x − α)(x − β) 的解直接讀出端點；(x − h)^{2} 的四種情形用按鈕
##   river2  某個數是不是解（只看正負），用「是／不是」兩顆按鈕
static func gen_river(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	var ops := ["<", "≤", ">", "≥"]
	while out.size() < n and guard < 4000:
		guard += 1
		var pb := {}
		if kind == "river2":
			var k := randi_range(2, 3)
			var roots := []
			while roots.size() < k:
				var rr := randi_range(-4, 4)
				if not roots.has(rr):
					roots.append(rr)
			roots.sort()
			var pw := []
			for i in k:
				pw.append(2 if randf() < 0.3 else 1)
			var frac := randf() < 0.3
			var op: String = ops.pick_random()
			var t: int = roots.pick_random() if randf() < 0.3 else randi_range(-5, 5)
			var txt := ""
			for i in k:
				if frac and i == k - 1:
					continue
				txt += xh(int(roots[i])) + ("^{2}" if int(pw[i]) == 2 else "")
			var ftxt := txt
			if frac:
				var num := txt
				if k == 2 and int(pw[0]) == 1:
					num = num.trim_prefix("(").trim_suffix(")")
				ftxt = "\\frac{%s}{%s}" % [num, xh(int(roots[k - 1])).trim_prefix("(").trim_suffix(")")]
			# 判斷
			var val := 1.0
			var undefined := false
			for i in k:
				var d := float(t - int(roots[i]))
				if frac and i == k - 1:
					if absf(d) < 1e-9:
						undefined = true
					val *= d
				else:
					val *= pow(d, int(pw[i]))
			var yes := false
			if not undefined:
				match op:
					"<":
						yes = val < 0
					"≤":
						yes = val <= 0
					">":
						yes = val > 0
					"≥":
						yes = val >= 0
			pb = {"eq": "%s %s 0\nx = %d 是它的解嗎？" % [ftxt, op, t], "choices": ["是", "不是"], "correct": 0 if yes else 1, "ans": "",
				"q": "代進去只看每個因式的正負。", "nudge": "分母是 0 不行；偶次方 ≥ 0；等於 0 要看有沒有等號。", "tag": BankP8.T_HIGH}
		else:
			if out.size() % 3 == 2:
				var h := randi_range(-5, 5)
				if h == 0:
					continue
				var op2: String = ops.pick_random()
				var ch := ["所有實數", "無解", "x = %d" % h, "x ≠ %d" % h]
				var cor: int = {"<": 1, "≤": 2, ">": 3, "≥": 0}[op2]
				pb = {"eq": "%s^{2} %s 0 的解是？" % [xh(h), op2], "choices": ch, "correct": cor, "ans": "",
					"q": "平方一定 ≥ 0。", "nudge": "只有 x = %d 時平方是 0。" % h, "tag": BankP8.T_NOSOL}
			else:
				var a := randi_range(-6, 5)
				var b := randi_range(a + 1, 6)
				if a == 0 or b == 0:
					continue
				var lt := out.size() % 3 == 0
				pb = {"eq": "%s%s %s 0" % [xh(a), xh(b), "<" if lt else ">"], "answers": [str(a), str(b)], "ans": str(a),
					"template": "[0] < x < [1]" if lt else "x < [0] 或 x > [1]",
					"q": "開口向上：< 0 在兩根之間，> 0 在兩根之外。", "nudge": "兩根是 %s 和 %s 的根。" % [xh(a), xh(b)], "tag": BankP8.T_Q2}
		pb.eq = String(pb.eq).replace("-", "−")
		if pb.has("answers"):
			pb.answers = pb.answers.map(func(v): return String(v).replace("-", "−"))
		if pb.has("choices"):
			pb.choices = pb.choices.map(func(v): return String(v).replace("-", "−"))
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		out.append(pb)
	return out


# ================= 畫面：地下河 =================

class RiverView extends CrystalView:
	const RIVER := Color("6fe3d0")
	const UNDER := Color("2a5f8a")
	const LIT := Color("7dffb2")
	const GATE := Color("ffe08a")
	const RMODES := ["pick", "wave", "pgate"]

	var rplot := {}
	var sel_seg: Array = []
	var sel_pt: Array = []
	var wstage := 0

	func setup(round: Dictionary) -> void:
		super(round)
		rplot = round.get("rplot", {}) if String(round.get("type", "")) == "forge" else {}

	func _rmine() -> bool:
		return String(gst.get("mode", "")) in RMODES

	func _mine() -> bool:
		return _rmine() or super()

	func _graph_on() -> bool:
		return not rplot.is_empty() or super()

	func _bottom_limit() -> float:
		if not rplot.is_empty() and gst.is_empty():
			return size.y - 276.0
		return super()

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if _rmine() or (gst.is_empty() and not rplot.is_empty()):
			_draw_river(font)
			return
		super(font, rect)

	func _src() -> Dictionary:
		return gst if _rmine() else rplot

	func _view() -> Dictionary:
		if _rmine() or (gst.is_empty() and not rplot.is_empty()):
			var vw: Dictionary = _src().get("view", {})
			var vx: Array = vw.get("x", [-5, 5])
			var vy: Array = vw.get("y", [-1, 1])
			return {"x": Vector2(float(vx[0]), float(vx[1])), "y": Vector2(float(vy[0]), float(vy[1]))}
		return super()

	func start_graph(st: Dictionary, cb: Callable) -> void:
		super(st, cb)
		match String(st.mode):
			"pick":
				sel_seg = []
				for i in st.pts.size() + 1:
					sel_seg.append(false)
				sel_pt = []
				for i in st.pts.size():
					sel_pt.append(false)
			"wave":
				wstage = 0
			"pgate":
				ga = float(st.get("start", 0))
				if marks_inside_at(ga) == st.marks.size():
					ga = float(st.get("arange", [-6, 6])[0])
		queue_redraw()

	# ---------- pgate ----------
	func gate_pos() -> float:
		var gk_: Array = gst.get("gate", [1, 0])
		return float(gk_[0]) * ga + float(gk_[1])

	func marks_inside_at(a: float) -> int:
		var gk_: Array = gst.get("gate", [1, 0])
		var g := float(gk_[0]) * a + float(gk_[1])
		var f := float(gst.get("fixed", 0))
		var lo := minf(g, f)
		var hi := maxf(g, f)
		var n := 0
		for m in gst.get("marks", []):
			var x := float(m)
			if bool(gst.get("strict", true)):
				if x > lo + 1e-9 and x < hi - 1e-9:
					n += 1
			elif x >= lo - 1e-9 and x <= hi + 1e-9:
				n += 1
		return n

	func marks_inside() -> int:
		return marks_inside_at(ga)

	func get_param(key: String) -> float:
		if _rmine() and key == "a":
			return ga
		return super(key)

	func set_param(key: String, v: float) -> void:
		if _rmine() and key == "a":
			ga = v
			_moved()
			return
		super(key, v)

	# ---------- 數線的位置 ----------
	func _river_y() -> float:
		var ar := _area()
		var src := _src()
		if src.has("poly"):
			return clampf(_to(0, 0).y, ar.position.y + 10.0, ar.end.y - 10.0)
		var nl: int = src.get("layers", []).size()
		if nl == 0:
			return ar.position.y + ar.size.y * 0.55
		return minf(ar.position.y + 18.0 + 30.0 * nl + 30.0, ar.end.y - 34.0)

	func _gpad_input(e: InputEvent) -> void:
		if not _rmine():
			super(e)
			return
		var pos := Vector2.INF
		var pressed := false
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			pos = e.position
			pressed = true
		elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
			pos = e.position
		if pos == Vector2.INF:
			return
		var p := pos + gpad.position
		match String(gst.mode):
			"pick":
				if not pressed:
					return
				var pts: Array = gst.pts
				var forbid: Array = gst.get("forbid", [])
				for i in pts.size():
					var gp := _to(float(pts[i]), 0)
					if absf(p.x - gp.x) < 14.0:
						if not forbid.has(i):
							sel_pt[i] = not bool(sel_pt[i])
							_moved()
						gpad.accept_event()
						return
				var x := _from(p).x
				var j := 0
				for i in pts.size():
					if x > float(pts[i]):
						j = i + 1
				sel_seg[j] = not bool(sel_seg[j])
				_moved()
			"pgate":
				var gk_: Array = gst.get("gate", [1, 0])
				var x2 := _from(p).x
				var rg: Array = gst.get("arange", [-6, 6])
				var a := clampf(roundf((x2 - float(gk_[1])) / float(gk_[0])), float(rg[0]), float(rg[1]))
				if not same(a, ga):
					ga = a
					_moved()
		gpad.accept_event()

	# ---------- 讀數、求 ----------
	func readout() -> String:
		match String(gst.get("mode", "")):
			"pick":
				var n := 0
				for s in sel_seg:
					if bool(s):
						n += 1
				return "亮了 %d 段" % n
			"wave":
				var n2: int = gst.pts.size()
				if wstage == 0:
					return "最右邊從哪裡出發？"
				if wstage > n2:
					return "放水完成"
				return "第 %d／%d 道閘門（%d 次）" % [wstage, n2, int(gst.mult[n2 - wstage])]
			"pgate":
				var g := gate_pos()
				var f := float(gst.get("fixed", 0))
				return "a = %s：%s %s x %s %s" % [qs(ga), qs(minf(g, f)), "<" if bool(gst.get("strict", true)) else "≤", "<" if bool(gst.get("strict", true)) else "≤", qs(maxf(g, f))]
		return super()

	func center_text() -> String:
		match String(gst.get("mode", "")):
			"pick":
				return "點亮符合的河段"
			"wave":
				var n: int = gst.pts.size()
				if wstage == 0:
					return "求：最右邊從地上還是地下出發？"
				if wstage > n:
					return "放水完成"
				return "求：閘門 %s 要穿過還是彈回？" % String(gst.labels[n - wstage])
			"pgate":
				return "求：讓所有的數都落在河段裡（%d／%d）" % [marks_inside(), gst.marks.size()]
		return super()

	# ---------- 背景：地下河 ----------
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		if w < 100.0 or h < 100.0:
			return
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("07141a"), Color("07141a"), Color("040a0e"), Color("040a0e")]))
		var drops := PackedVector2Array()
		for i in 16:
			var x := fposmod(i * 89.3, w)
			var y := fposmod(t * 30.0 + i * 47.0, h * 0.6)
			drops.append_array([Vector2(x, y), Vector2(x, y + 6.0)])
		draw_multiline(drops, Color(RIVER.r, RIVER.g, RIVER.b, 0.18), 1.5)
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	# ---------- 地下河 ----------
	## 第 j 段（由左到右，0 ～ n）的正負
	static func seg_sign(j: int, mult: Array, lead: int) -> int:
		var s := lead
		for i in range(j, mult.size()):
			if int(mult[i]) % 2 == 1:
				s = -s
		return s

	static func fpoly(c: Array, x: float) -> float:
		var v := 0.0
		for a in c:
			v = v * x + float(a)
		return v

	func _draw_river(font: Font) -> void:
		var rc := _grect()
		if rc.size.x < 120.0:
			return
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.03, 0.09, 0.12, 0.88)
		sb.border_color = Color(RIVER.r, RIVER.g, RIVER.b, 0.4)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(14)
		sb.anti_aliasing = true
		draw_style_box(sb, rc)
		var src := _src()
		var ar := _area()
		var vw := _view()
		var vx_: Vector2 = vw.x
		var ly := _river_y()
		var fs := UITheme.fs(13)
		var pts: Array = src.get("pts", [])
		var labels: Array = src.get("labels", [])
		var mode := String(gst.get("mode", ""))
		# 地下（數線下方）
		draw_rect(Rect2(ar.position.x, ly, ar.size.x, ar.end.y - ly), Color(UNDER.r, UNDER.g, UNDER.b, 0.16))
		# 圖形
		if src.has("poly"):
			_grid_poly()
			_curvep(src.poly, CURVE, 2.6)
		# 參考的河（上方幾層）
		var layers: Array = src.get("layers", [])
		for li in layers.size():
			var lay: Dictionary = layers[li]
			var yy := ar.position.y + 18.0 + 30.0 * li
			_line_bar(yy, lay.pts, lay.segs, lay.ptsin, [], 5.0, Color(RIVER.r, RIVER.g, RIVER.b, 0.75), true)
			MathLabel.draw_on(self, font, ar.position.x + 12.0, yy + 5.0, String(lay.label), fs, RIVER.lightened(0.3))
			var llb: Array = lay.get("labels", [])
			for k in llb.size():
				var lp := _to(float(lay.pts[k]), 0)
				MathLabel.draw_on(self, font, lp.x, yy - 8.0, String(llb[k]), UITheme.fs(11), Color(1, 1, 1, 0.6))
			for k in lay.pts.size():
				draw_dashed_line(Vector2(_to(float(lay.pts[k]), 0).x, yy + 6.0), Vector2(_to(float(lay.pts[k]), 0).x, ly - 8.0), Color(1, 1, 1, 0.12), 1.0, 4.0)
		# 水流（奇穿偶彈）
		if src.has("mult") and (mode == "wave" or mode == "pick"):
			_draw_wave(src, ly, mode == "wave")
		# 數線
		draw_line(Vector2(ar.position.x, ly), Vector2(ar.end.x, ly), Color(0.75, 0.95, 1.0, 0.7), 2.0, true)
		MathLabel.draw_on(self, font, ar.end.x - 6.0, ly - 8.0, "x", UITheme.fs(13), Color(0.8, 0.95, 1.0, 0.8))
		match mode:
			"pick":
				_line_bar(ly, pts, sel_seg, sel_pt, gst.get("forbid", []), 9.0, LIT, false)
			"pgate":
				_draw_pgate(font, ly)
			_:
				if src.has("segs"):
					_line_bar(ly, pts, src.segs, src.ptsin, src.get("forbid", []), 9.0, LIT, false)
				else:
					for i in pts.size():
						_gate(_to(float(pts[i]), 0).x, ly, false, false)
		# 閘門的數
		if mode != "pgate":
			# 閘門的數太靠近時，下一個往下錯開一排
			var prev_r := -INF
			var low := false
			for i in labels.size():
				var p := _to(float(pts[i]), 0)
				var lb := String(labels[i])
				var hw := MathLabel.text_width(font, lb, fs) * 0.5
				low = (p.x - hw < prev_r + 6.0) and not low
				var yy := ly + (24.0 if not low else 50.0)
				if low:
					draw_line(Vector2(p.x, ly + 8.0), Vector2(p.x, yy - 16.0), Color(1, 1, 1, 0.25), 1.0)
				MathLabel.draw_on(self, font, p.x, yy, lb, fs, Color(1, 1, 1, 0.85))
				prev_r = p.x + hw
		for d in src.get("dots", []):
			var dp := _to(float(d[0]), 0)
			UITheme.dot(self, Vector2(dp.x, ly), 5.0, Color(1, 1, 1, 0.9))
			MathLabel.draw_on(self, font, dp.x, ly + 22.0, String(d[1]), UITheme.fs(12), Color(1, 1, 1, 0.85))
		if src.has("ydot"):
			var yd: Array = src.ydot
			var yp := _to(0, float(yd[0]))
			UITheme.dot(self, yp, 5.0, Color(1, 1, 1, 0.9))
			MathLabel.draw_on(self, font, yp.x + 30.0, yp.y - 4.0, String(yd[1]), UITheme.fs(12), Color(1, 1, 1, 0.85))
		if not src.has("poly") and vx_.x < 0 and vx_.y > 0 and not pts.has(0) and not pts.has(0.0):
			var zp := _to(0, 0).x
			draw_line(Vector2(zp, ly - 4.0), Vector2(zp, ly + 4.0), Color(1, 1, 1, 0.4), 1.5)

	func _grid_poly() -> void:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var vy_: Vector2 = vw.y
		var grid := PackedVector2Array()
		for xi in range(int(ceil(vx_.x)), int(floor(vx_.y)) + 1):
			grid.append_array([_to(xi, vy_.x), _to(xi, vy_.y)])
		draw_multiline(grid, Color(1, 1, 1, 0.05), 1.0)
		if vx_.x < 0 and vx_.y > 0:
			draw_line(_to(0, vy_.x), _to(0, vy_.y), Color(1, 1, 1, 0.3), 1.5)

	func _curvep(c: Array, col: Color, wdt: float) -> void:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var ar := _area()
		var prev := Vector2.INF
		for i in 361:
			var x := lerpf(vx_.x, vx_.y, i / 360.0)
			var p := _to(x, fpoly(c, x))
			if prev != Vector2.INF:
				var sg := clip_seg(prev, p, ar)
				if sg.size() == 2:
					draw_line(sg[0], sg[1], col, wdt, true)
			prev = p

	## 一條河：亮的河段、閘門（● 取、○ 不取、✕ 禁區）
	func _line_bar(y: float, pts: Array, segs: Array, ptsin: Array, forbid: Array, wdt: float, col: Color, small: bool) -> void:
		var ar := _area()
		var xs := [ar.position.x + (26.0 if small else 0.0)]
		for p in pts:
			xs.append(_to(float(p), 0).x)
		xs.append(ar.end.x)
		for j in segs.size():
			if j + 1 >= xs.size():
				break
			var x0: float = xs[j]
			var x1: float = xs[j + 1]
			if bool(segs[j]):
				draw_line(Vector2(x0, y), Vector2(x1, y), col, wdt, true)
				if not small:
					draw_rect(Rect2(x0, ar.position.y, x1 - x0, ar.size.y), Color(col.r, col.g, col.b, 0.05))
			elif not small:
				draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.08), wdt, true)
		for i in pts.size():
			var gx: float = xs[i + 1]
			if forbid.has(i):
				var r := 7.0
				draw_arc(Vector2(gx, y), r, 0, TAU, 24, Color(1, 0.5, 0.5), 2.0, true)
				draw_line(Vector2(gx - 4, y - 4), Vector2(gx + 4, y + 4), Color(1, 0.5, 0.5), 2.0, true)
				draw_line(Vector2(gx - 4, y + 4), Vector2(gx + 4, y - 4), Color(1, 0.5, 0.5), 2.0, true)
				continue
			_gate(gx, y, i < ptsin.size() and bool(ptsin[i]), small)

	func _gate(x: float, y: float, filled: bool, small: bool) -> void:
		var r := 4.5 if small else 7.5
		if filled:
			UITheme.dot(self, Vector2(x, y), r, GATE if not small else Color(1, 1, 1, 0.9))
		else:
			UITheme.dot(self, Vector2(x, y), r, Color(0.03, 0.09, 0.12))
			draw_arc(Vector2(x, y), r, 0, TAU, 24, GATE if not small else Color(1, 1, 1, 0.9), 2.0, true)

	## 水流：從最右邊開始，穿過或彈回每一道閘門
	func _draw_wave(src: Dictionary, ly: float, progressive: bool) -> void:
		var ar := _area()
		var pts: Array = src.pts
		var mult: Array = src.mult
		var lead := int(src.lead)
		var n := pts.size()
		var amp := minf(34.0, (ly - ar.position.y) * 0.5 - 6.0)
		if not src.get("layers", []).is_empty() or src.has("poly"):
			return
		var xs := [ar.position.x + 6.0]
		for p in pts:
			xs.append(_to(float(p), 0).x)
		xs.append(ar.end.x - 6.0)
		var shown := n + 1
		if progressive:
			shown = wstage   # 已經決定好的段數（從右邊算）
			if wstage == 0:
				# 還沒決定：最右邊畫一個水滴提示
				var p0 := Vector2(ar.end.x - 20.0, ly)
				UITheme.dot(self, p0, 9.0 + 2.0 * sin(t * 5.0), Color(RIVER.r, RIVER.g, RIVER.b, 0.6))
				return
		for j in range(n, n - shown, -1):
			if j < 0:
				break
			var s := seg_sign(j, mult, lead)
			var x0: float = xs[j]
			var x1: float = xs[j + 1]
			var pl := PackedVector2Array()
			for k in 25:
				var u := k / 24.0
				var hgt := sin(PI * u)
				if j == n and j == 0:
					hgt = 1.0
				elif j == n:
					hgt = sin(PI * 0.5 * minf(u * 2.0, 1.0))
				elif j == 0:
					hgt = sin(PI * 0.5 * minf((1.0 - u) * 2.0, 1.0))
				pl.append(Vector2(lerpf(x0, x1, u), ly - s * amp * hgt))
			var col := LIT if s > 0 else Color(UNDER.r * 1.6, UNDER.g * 1.6, UNDER.b * 1.6)
			draw_polyline(pl, col, 2.6, true)
		# 正在決定的閘門
		if progressive and wstage >= 1 and wstage <= n:
			var gx: float = xs[n - wstage + 1]
			UITheme.dot(self, Vector2(gx, ly), 13.0 + 2.0 * sin(t * 5.0), Color(GATE.r, GATE.g, GATE.b, 0.35))

	func _draw_pgate(font: Font, ly: float) -> void:
		var g := gate_pos()
		var f := float(gst.get("fixed", 0))
		var lo := minf(g, f)
		var hi := maxf(g, f)
		var strict := bool(gst.get("strict", true))
		var ar := _area()
		var x0 := clampf(_to(lo, 0).x, ar.position.x, ar.end.x)
		var x1 := clampf(_to(hi, 0).x, ar.position.x, ar.end.x)
		draw_line(Vector2(x0, ly), Vector2(x1, ly), LIT, 9.0, true)
		draw_rect(Rect2(x0, ar.position.y, x1 - x0, ar.size.y), Color(LIT.r, LIT.g, LIT.b, 0.05))
		var fs := UITheme.fs(13)
		for e in [[f, qs(f), false], [g, String(gst.get("glabel", "a")), true]]:
			var gx := _to(float(e[0]), 0).x
			if gx < ar.position.x - 2.0 or gx > ar.end.x + 2.0:
				continue
			if bool(e[2]):
				UITheme.dot(self, Vector2(gx, ly), 13.0 + 2.0 * sin(t * 4.0), Color(GATE.r, GATE.g, GATE.b, 0.3))
			_gate(gx, ly, not strict, false)
			MathLabel.draw_on(self, font, gx, ly + 24.0, String(e[1]), fs, GATE if bool(e[2]) else Color(1, 1, 1, 0.85))
		# 要裝進去的數
		for m in gst.get("marks", []):
			var mx := float(m)
			var inside := (mx > lo + 1e-9 and mx < hi - 1e-9) if strict else (mx >= lo - 1e-9 and mx <= hi + 1e-9)
			var p := Vector2(_to(mx, 0).x, ly - 30.0)
			var col: Color = UITheme.GOOD if inside else Color("ff8ad8")
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -8), p + Vector2(7, 0), p + Vector2(0, 8), p + Vector2(-7, 0)]), col)
			MathLabel.draw_on(self, font, p.x, p.y - 12.0, qs(mx), fs, col.lightened(0.3))
		# 刻度
		var vw := _view()
		var vx_: Vector2 = vw.x
		for xi in range(int(ceil(vx_.x)), int(floor(vx_.y)) + 1):
			var tx := _to(xi, 0).x
			draw_line(Vector2(tx, ly - 3.0), Vector2(tx, ly + 3.0), Color(1, 1, 1, 0.3), 1.0)
