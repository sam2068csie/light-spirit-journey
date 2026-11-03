extends "res://data/levels/poly/level_poly3_echo.gd"
## 多項式 第五大關「拋物鏡湖」（對應講義 4-2 重點二：二次函數的圖形）
## 引擎是 step_level.gd（拼積木沿用第三關），題庫在 poly5_bank.gd。
##
## 這一關多了 graph 步驟：在下方的湖面座標圖上直接操作（湖面就是 x 軸）
##   match  拖頂點、調開口 a，讓拋物線和虛線重合　　gems   開口固定，拖頂點穿過寶石
##   quad   只經過指定的象限（燈塔），也有做不到的題目　roots  在湖面上拖兩個根
##   slide  轉動 k，標記剛好碰到湖面（或直線）的 k　　hline  y = |f(x)| 和水平線 y = k 的交點個數
## 題目帶 "lake" 時，整段旅程的下方都畫著那條拋物線（看圖判斷係數、對稱比大小），步驟的 "hl" 標出這一步要看的地方。
## 每一步中間的推導紀錄都寫出「求：…」，右邊有 ◀ ▶ 可以一格一格調（手機上拖不準時用）。

const BankP5 := preload("res://data/levels/poly/poly5_bank.gd")
const LAKE_C := Color("7fd4ff")

const CHAPTERS_P5 := [
	{"ch": 1, "name": "第一章．鏡湖的倒影", "topic": "標準式、配方、平移、看圖判斷係數、象限、對稱", "color": Color("7fd4ff")},
	{"ch": 2, "name": "第二章．湖面的秘密", "topic": "根與係數、判別式、恆正恆負、求二次函數、y = |f(x)|", "color": UITheme.GOOD},
]

var g_lbl: Label
var g_impossible: Button


func level_id() -> String:
	return "P5"

func level_title() -> String:
	return "拋物鏡湖"

func level_subtitle() -> String:
	return "二次函數的圖形"

func level_chapters() -> Array:
	return CHAPTERS_P5

func bank_slots() -> Array:
	return BankP5.slots()

func step_color() -> Color:
	return LAKE_C

func stage_style() -> Dictionary:
	return {"sky_top": Color("0b1630"), "sky_bot": Color("08101f"), "scenery": "none", "ambient": "currents"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．湖面的秘密", "button": "潛入湖面的秘密  ▶",
		"text": "湖面下藏著更多線索：\n\n" \
			+ "・兩根和 −\\frac{b}{a}、兩根積 \\frac{c}{a}：不用解方程式也能算\n" \
			+ "・判別式：和湖面交幾點、恆正還是恆負\n" \
			+ "・拋物線在直線上方或下方：相減之後看判別式\n" \
			+ "・y = |f(x)|：湖面下的部分翻上來\n\n" \
			+ "準備下潛！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = LakeView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "鏡湖速算"
		fview.speed_y = 0.42


func _lv() -> LakeView:
	return fview as LakeView


# ================= graph 步驟 =================

func _forge_step() -> void:
	if fview != null:
		_lv().graph_off()
		_lv().hl = ""
	super()
	if r.get("type", "") == "forge" and si < steps.size():
		_lv().hl = String(steps[si].get("hl", ""))
		if String(steps[si].kind) == "graph":
			_build_graph(steps[si])


func _build_graph(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	story_label.visible = false
	var lv := _lv()
	lv.start_graph(st, _on_graph_move)
	g_lbl = Label.new()
	g_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g_lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	g_lbl.custom_minimum_size = Vector2(300, 0)
	g_lbl.add_theme_font_size_override("font_size", UITheme.fs(20))
	g_lbl.add_theme_color_override("font_color", LAKE_C.lightened(0.3))
	rank_box.add_child(g_lbl)
	var mode := String(st.mode)
	var rows := []
	match mode:
		"match", "quad":
			rows = [["開口 a", "a"], ["頂點", "hk"]]
		"gems":
			rows = [["頂點", "hk"]]
		"roots":
			rows = [["α", "r0"], ["β", "r1"]]
		"slide", "hline":
			rows = [["k", "k"]]
	for rw in rows:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		rank_box.add_child(row)
		var cap := Label.new()
		cap.text = rw[0]
		cap.custom_minimum_size = Vector2(56, 0)
		cap.add_theme_font_size_override("font_size", UITheme.fs(17))
		cap.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		row.add_child(cap)
		var what: String = rw[1]
		var btns := []
		if what == "hk":
			btns = [["◀", "h", -1], ["▲", "k", 1], ["▼", "k", -1], ["▶", "h", 1]]
		elif what == "k" and mode == "hline":
			btns = [["▼", "k", -1], ["▲", "k", 1]]
		else:
			btns = [["◀", what, -1], ["▶", what, 1]]
		for bd in btns:
			var b := Button.new()
			b.text = bd[0]
			b.custom_minimum_size = Vector2(0, 46)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", UITheme.fs(20))
			var key: String = bd[1]
			var d: int = bd[2]
			b.pressed.connect(func():
				if not busy:
					lv.nudge_graph(key, d))
			row.add_child(b)
	g_impossible = null
	if mode == "quad":
		g_impossible = Button.new()
		g_impossible.text = "做不到"
		g_impossible.custom_minimum_size = Vector2(0, 42)
		g_impossible.focus_mode = Control.FOCUS_NONE
		g_impossible.add_theme_font_size_override("font_size", UITheme.fs(17))
		g_impossible.pressed.connect(func():
			if not busy:
				_graph_impossible(st))
		rank_box.add_child(g_impossible)
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = {"match": "對準了", "gems": "穿過了", "quad": "就是這樣", "roots": "就是這兩根", "slide": "標記這個 k", "hline": "確定"}.get(mode, "確定")
	fview.live_q = "在下方的湖面上拖動（或按右邊的按鈕），再按「%s」。" % go_btn.text
	_on_graph_move()


func _on_graph_move() -> void:
	var lv := _lv()
	if lv.gst.is_empty():
		return
	if g_lbl != null and is_instance_valid(g_lbl):
		g_lbl.text = lv.readout()
	fview.live_fill = lv.center_text()
	fview.queue_redraw()
	Game.of(self).play("blip", 1.0, -18.0)


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size() and String(steps[si].kind) == "graph":
		_graph_submit(steps[si])
		return
	super()


func _graph_done(st: Dictionary) -> void:
	Game.of(self).sfx("correct")
	go_btn.visible = false
	_clear(rank_box)
	rank_box.visible = false
	_lv().graph_off()
	fview.live_fill = ""
	_step_done(st, "")


func _graph_impossible(st: Dictionary) -> void:
	if not bool(st.get("possible", true)):
		_graph_done(st)
		return
	_wrong(st, "做得到喔！再試試看。提示：%s" % st.nudge)


func _graph_submit(st: Dictionary) -> void:
	var lv := _lv()
	match String(st.mode):
		"match":
			var tg: Dictionary = st.target
			if lv.same(lv.ga, LakeView.q(tg.a)) and lv.same(lv.gh, LakeView.q(tg.h)) and lv.same(lv.gk, LakeView.q(tg.k)):
				_graph_done(st)
				return
			var msg := "還沒重合。"
			if not (lv.same(lv.gh, LakeView.q(tg.h)) and lv.same(lv.gk, LakeView.q(tg.k))):
				msg = "頂點還沒對準。"
			elif lv.ga * LakeView.q(tg.a) < 0:
				msg = "頂點對了，但開口方向相反。"
			else:
				msg = "頂點對了，開口的寬窄還不一樣。"
			_wrong(st, msg + "提示：" + String(st.nudge))
		"gems":
			if lv.gems_hit() == st.gems.size():
				_graph_done(st)
				return
			_wrong(st, "還有寶石沒穿過（穿過 %d／%d 顆）。提示：%s" % [lv.gems_hit(), st.gems.size(), st.nudge])
		"quad":
			if not bool(st.get("possible", true)):
				_wrong(st, "這樣經過的象限不只第一、第三。想想看：拋物線有可能只經過這兩個象限嗎？")
				return
			var want: Array = st.quads.duplicate()
			want.sort()
			var got := lv.quads_now()
			if got == want:
				_graph_done(st)
				return
			_wrong(st, "現在經過的是 %s，還不對。提示：%s" % [LakeView.quad_names(got), st.nudge])
		"roots":
			var tg2: Array = st.target
			var a := float(tg2[0])
			if lv.same(-a * (lv.r0 + lv.r1), float(tg2[1])) and lv.same(a * lv.r0 * lv.r1, float(tg2[2])):
				_graph_done(st)
				return
			_wrong(st, "現在是 %s，還不一樣。提示：%s" % [lv.roots_eq(), st.nudge])
		"slide":
			var hit := -1
			for i in st.goals.size():
				if lv.same(lv.gk, LakeView.q(st.goals[i])):
					hit = i
			if hit < 0:
				_wrong(st, "k = %s 時有 %d 個交點，不是剛好碰到（1 個交點）。提示：%s" % [LakeView.qs(lv.gk), lv.cross_count(), st.nudge])
				return
			for m in lv.gmarks:
				if lv.same(float(m), lv.gk):
					_hint("這個 k 已經標記過了，還有別的。", "info")
					return
			lv.gmarks.append(lv.gk)
			Game.of(self).sfx("correct")
			if lv.gmarks.size() >= st.goals.size():
				_graph_done(st)
			else:
				_hint("✓ k = %s 剛好碰到！還有 %d 個。" % [LakeView.qs(lv.gk), st.goals.size() - lv.gmarks.size()], "good")
				_on_graph_move()
		"hline":
			var goal: int = int(st.goals[lv.gstage])
			var n := lv.cross_count()
			if n != goal:
				_wrong(st, "k = %s 時有 %d 個交點，要找 %d 個的位置。提示：%s" % [LakeView.qs(lv.gk), n, goal, st.nudge])
				return
			Game.of(self).sfx("correct")
			lv.gstage += 1
			lv.gmarks.append(lv.gk)
			if lv.gstage >= st.goals.size():
				_graph_done(st)
			else:
				_hint("✓ k = %s：%d 個交點！下一個：找 %d 個交點。" % [LakeView.qs(lv.gk), goal, int(st.goals[lv.gstage])], "good")
				_on_graph_move()


func _custom_reveal(msg: String) -> void:
	if fview != null:
		_lv().graph_off()
	super(msg)


# ================= 速算 =================

func _speed_tag() -> String:
	return BankP5.T_VTX


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算（一步）：讀頂點、對稱軸 −b/(2a)、y 截距
static func gen_problems(_kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var a: int = [-3, -2, -1, 1, 2, 3].pick_random()
		var h := randi_range(-4, 4)
		var k := randi_range(-6, 6)
		if h == 0:
			continue
		var pb := {}
		match out.size() % 3:
			0:
				var ask_x := randf() < 0.5
				pb = {"eq": "%s\n頂點的 %s 坐標 = ？" % [LakeView.vtx_eq(a, h, k), "x" if ask_x else "y"], "ans": str(h if ask_x else k),
					"template": ("頂點 x = [0]" if ask_x else "頂點 y = [0]"), "q": "y = a(x − h)^{2} + k 的頂點是 (h, k)。", "nudge": "x + 3 = x − (−3)。"}
			1:
				var b := -2 * a * h
				var c := randi_range(-6, 6)
				pb = {"eq": "y = %s\n對稱軸 x = ？" % LakeView.poly2(a, b, c), "ans": str(h), "template": "x = [0]",
					"q": "對稱軸 x = −\\frac{b}{2a}。", "nudge": "−b 除以 2a。"}
			2:
				pb = {"eq": "%s\n和 y 軸交點的 y 坐標 = ？" % LakeView.vtx_eq(a, h, k), "ans": str(a * h * h + k), "template": "y = [0]",
					"q": "和 y 軸的交點：x 代入 0。", "nudge": "a × h^{2} + k。"}
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		pb["tag"] = BankP5.T_VTX
		out.append(pb)
	return out


# ================= 畫面：月光鏡湖 + 座標圖 =================

class LakeView extends EchoView:
	const LAKE := Color("7fd4ff")
	const WATER := Color("2a6fb0")
	const CURVE := Color("ffe08a")
	const GHOST := Color("9fd8ff")

	var lake := {}               # 整段旅程下方的圖 {coef, show, view, axis, marks, labels}
	var hl := ""                 # 這一步要標出的地方
	var gst := {}                # 目前的 graph 步驟
	var ga := 1.0
	var gh := 0.0
	var gk := 0.0
	var r0 := 0.0
	var r1 := 1.0
	var gmarks: Array = []
	var gstage := 0
	var gcb: Callable
	var gpad: Control
	var drag_root := -1
	var _quads_cache := []
	var _quads_key := ""

	func setup(round: Dictionary) -> void:
		super(round)
		lake = round.get("lake", {}) if String(round.get("type", "")) == "forge" else {}
		hl = ""
		graph_off()

	static func q(v) -> float:
		var s := str(v).strip_edges().replace("−", "-")
		if s.contains("/"):
			var pr := s.split("/")
			return float(pr[0]) / float(pr[1])
		return float(s)

	static func qs(v: float) -> String:
		for d in [1, 2, 3, 4]:
			if absf(v * d - roundf(v * d)) < 1e-6:
				var n := int(roundf(v * d))
				if d == 1:
					return str(n).replace("-", "−")
				return ("−" if n < 0 else "") + "%d/%d" % [absi(n), d]
		return str(snappedf(v, 0.01)).replace("-", "−")

	## 圖上用的分數寫法（\frac）
	static func qm(v: float) -> String:
		var s := qs(v)
		if s.contains("/"):
			var neg := s.begins_with("−")
			var pr := s.replace("−", "").split("/")
			return ("−" if neg else "") + "\\frac{%s}{%s}" % [pr[0], pr[1]]
		return s

	static func same(x: float, y: float) -> bool:
		return absf(x - y) < 1e-6

	## y = a(x − h)^{2} + k 的寫法
	static func vtx_eq(a: float, h: float, k: float) -> String:
		var sa := "" if same(a, 1.0) else ("−" if same(a, -1.0) else qm(a))
		var sx := "x^{2}" if same(h, 0.0) else ("(x − %s)^{2}" % qm(h) if h > 0 else "(x + %s)^{2}" % qm(-h))
		var sk := "" if same(k, 0.0) else (" + %s" % qm(k) if k > 0 else " − %s" % qm(-k))
		return "y = " + sa + sx + sk

	## ax^{2} + bx + c 的寫法
	static func poly2(a: float, b: float, c: float) -> String:
		var out := ""
		for t in [[a, "x^{2}"], [b, "x"], [c, ""]]:
			var v: float = t[0]
			if same(v, 0.0):
				continue
			var mag := qm(absf(v))
			var body: String = (("" if same(absf(v), 1.0) else mag) + t[1]) if t[1] != "" else mag
			if out == "":
				out = ("−" if v < 0 else "") + body
			else:
				out += (" − " if v < 0 else " + ") + body
		return out if out != "" else "0"

	# ---------- graph 步驟 ----------
	func start_graph(st: Dictionary, cb: Callable) -> void:
		gst = st
		gcb = cb
		gmarks = []
		gstage = 0
		var sv: Dictionary = st.get("start", {}) if st.get("start") is Dictionary else {}
		ga = q(st.get("a", sv.get("a", "1")))
		gh = q(sv.get("h", "0"))
		gk = q(sv.get("k", "0"))
		if String(st.mode) == "roots":
			var s2: Array = st.get("start", [0, 1])
			r0 = float(s2[0])
			r1 = float(s2[1])
		if String(st.mode) in ["slide", "hline"]:
			gk = 0.0
		if gpad == null:
			gpad = Control.new()
			gpad.mouse_filter = Control.MOUSE_FILTER_STOP
			gpad.gui_input.connect(_gpad_input)
			add_child(gpad)
		gpad.visible = true
		_place_gpad()
		queue_redraw()

	func graph_off() -> void:
		gst = {}
		if gpad != null:
			gpad.visible = false

	func _grect() -> Rect2:
		return Rect2(92, size.y - 262, size.x - 116, 248)

	func _place_gpad() -> void:
		if gpad != null:
			var rc := _grect()
			gpad.position = rc.position
			gpad.size = rc.size

	func _process(delta: float) -> void:
		super(delta)
		if gpad != null and gpad.visible and gpad.size != _grect().size:
			_place_gpad()

	func _graph_on() -> bool:
		return not gst.is_empty() or not lake.is_empty() or super()

	func _bottom_limit() -> float:
		if not gst.is_empty() or not lake.is_empty():
			return size.y - 276.0
		return super()

	func _view() -> Dictionary:
		var vw: Dictionary = gst.get("view", lake.get("view", {}))
		return {"x": Vector2(float(vw.get("x", [-5, 5])[0]), float(vw.get("x", [-5, 5])[1])),
			"y": Vector2(float(vw.get("y", [-5, 5])[0]), float(vw.get("y", [-5, 5])[1]))}

	func _area() -> Rect2:
		var rc := _grect()
		return Rect2(rc.position + Vector2(14, 30), rc.size - Vector2(28, 42))

	func _to(x: float, y: float) -> Vector2:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var vy_: Vector2 = vw.y
		var ar := _area()
		return Vector2(ar.position.x + (x - vx_.x) / (vx_.y - vx_.x) * ar.size.x,
			ar.end.y - (y - vy_.x) / (vy_.y - vy_.x) * ar.size.y)

	func _from(p: Vector2) -> Vector2:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var vy_: Vector2 = vw.y
		var ar := _area()
		return Vector2(vx_.x + (p.x - ar.position.x) / ar.size.x * (vx_.y - vx_.x),
			vy_.x + (ar.end.y - p.y) / ar.size.y * (vy_.y - vy_.x))

	func _snap_of(key: String) -> float:
		if key == "k" and String(gst.get("mode", "")) == "hline":
			return q(gst.get("step", "1"))
		return q(gst.get("snap", "1"))

	func nudge_graph(key: String, d: int) -> void:
		match key:
			"a":
				var lst: Array = gst.get("a_list", ["1"])
				var idx := 0
				for i in lst.size():
					if same(q(lst[i]), ga):
						idx = i
				ga = q(lst[clampi(idx + d, 0, lst.size() - 1)])
			"h":
				gh += d * _snap_of("h")
			"k":
				gk += d * _snap_of("k")
			"r0":
				r0 += d
			"r1":
				r1 += d
		_clamp_graph()
		_moved()

	func _clamp_graph() -> void:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var vy_: Vector2 = vw.y
		gh = clampf(gh, vx_.x, vx_.y)
		match String(gst.get("mode", "")):
			"slide", "hline":
				var rg: Array = gst.get("range", [-5, 5])
				gk = clampf(gk, float(rg[0]), float(rg[1]))
			_:
				gk = clampf(gk, vy_.x, vy_.y)
		r0 = clampf(r0, vx_.x, vx_.y)
		r1 = clampf(r1, vx_.x, vx_.y)

	func _moved() -> void:
		queue_redraw()
		if gcb.is_valid():
			gcb.call()

	func _gpad_input(e: InputEvent) -> void:
		if gst.is_empty():
			return
		var pos := Vector2.INF
		var pressed := false
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				pos = e.position
				pressed = true
			else:
				drag_root = -1
		elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
			pos = e.position
		if pos == Vector2.INF:
			return
		var w := _from(pos + gpad.position)
		var before := [ga, gh, gk, r0, r1]
		match String(gst.mode):
			"match", "quad", "gems":
				var s := _snap_of("h")
				gh = roundf(w.x / s) * s
				gk = roundf(w.y / s) * s
			"roots":
				var x := roundf(w.x)
				if pressed or drag_root < 0:
					drag_root = 0 if absf(w.x - r0) <= absf(w.x - r1) else 1
				if drag_root == 0:
					r0 = x
				else:
					r1 = x
			"slide":
				var rg: Array = gst.get("range", [-5, 5])
				var ar := _area()
				gk = roundf(lerpf(float(rg[0]), float(rg[1]), clampf((pos.x + gpad.position.x - ar.position.x) / ar.size.x, 0.0, 1.0)))
			"hline":
				var st := _snap_of("k")
				gk = roundf(w.y / st) * st
		_clamp_graph()
		if [ga, gh, gk, r0, r1] != before:
			_moved()
		gpad.accept_event()

	## 目前畫的拋物線係數 [a, b, c]
	func cur_coef() -> Array:
		match String(gst.get("mode", "")):
			"match", "quad", "gems":
				return [ga, -2.0 * ga * gh, ga * gh * gh + gk]
			"roots":
				var a := q(gst.get("a", "1"))
				return [a, -a * (r0 + r1), a * r0 * r1]
			"slide":
				var fam: Array = gst.fam
				return [float(fam[0][0]) + float(fam[0][1]) * gk, float(fam[1][0]) + float(fam[1][1]) * gk, float(fam[2][0]) + float(fam[2][1]) * gk]
			"hline":
				return gst.coef.map(func(v): return float(v))
		if not lake.is_empty():
			return lake.coef.map(func(v): return float(v))
		return [1.0, 0.0, 0.0]

	static func fv(c: Array, x: float) -> float:
		return float(c[0]) * x * x + float(c[1]) * x + float(c[2])

	func gems_hit() -> int:
		var n := 0
		var c := cur_coef()
		for g in gst.get("gems", []):
			if absf(fv(c, float(g[0])) - float(g[1])) < 1e-6:
				n += 1
		return n

	## 目前經過的象限（排好序）
	func quads_now() -> Array:
		var c := cur_coef()
		var key := str(c)
		if key == _quads_key:
			return _quads_cache
		var got := {}
		var xs := []
		for i in 4001:
			xs.append(lerpf(-60.0, 60.0, i / 4000.0))
		xs.append_array([-1e4, 1e4, -0.001, 0.001])
		for x in xs:
			var y := fv(c, x)
			if absf(y) < 1e-9 or absf(x) < 1e-12:
				continue
			if x > 0 and y > 0:
				got[1] = true
			elif x < 0 and y > 0:
				got[2] = true
			elif x < 0 and y < 0:
				got[3] = true
			elif x > 0 and y < 0:
				got[4] = true
		var out := got.keys()
		out.sort()
		_quads_key = key
		_quads_cache = out
		return out

	static func quad_names(qs_: Array) -> String:
		if qs_.is_empty():
			return "沒有象限"
		var nm := ["", "第一", "第二", "第三", "第四"]
		return "、".join(qs_.map(func(i): return nm[i])) + "象限"

	static func quad_roman(qs_: Array) -> String:
		if qs_.is_empty():
			return "無"
		var nm := ["", "Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ"]
		return "、".join(qs_.map(func(i): return nm[i]))

	## 和湖面（x 軸）、直線或水平線的交點個數
	func cross_count() -> int:
		var c := cur_coef()
		match String(gst.get("mode", "")):
			"slide":
				var cc: Array = c.duplicate()
				if String(gst.get("show", "x")) == "line":
					var ln: Array = gst.bline
					cc = [c[0], c[1] - float(ln[0]), c[2] - float(ln[1])]
				return _nroots(cc)
			"hline":
				if gk < -1e-9:
					return 0
				if absf(gk) < 1e-9:
					return _nroots(c)
				return _nroots([c[0], c[1], c[2] - gk]) + _nroots([c[0], c[1], c[2] + gk])
		return _nroots(c)

	static func _nroots(c: Array) -> int:
		var d := float(c[1]) * float(c[1]) - 4.0 * float(c[0]) * float(c[2])
		if absf(d) < 1e-9:
			return 1
		return 2 if d > 0 else 0

	func roots_eq() -> String:
		var c := cur_coef()
		return "y = " + poly2(c[0], c[1], c[2])

	## 右邊的讀數
	func readout() -> String:
		match String(gst.get("mode", "")):
			"match", "quad":
				return "a = %s　頂點 (%s, %s)" % [qs(ga), qs(gh), qs(gk)]
			"gems":
				return "頂點 (%s, %s)　穿過 %d／%d" % [qs(gh), qs(gk), gems_hit(), gst.gems.size()]
			"roots":
				return "α = %s，β = %s" % [qs(r0), qs(r1)]
			"slide":
				return "k = %s：交點 %d 個" % [qs(gk), cross_count()]
			"hline":
				return "k = %s：交點 %d 個" % [qs(gk), cross_count()]
		return ""

	## 中間的推導紀錄寫的「求：…」
	func center_text() -> String:
		match String(gst.get("mode", "")):
			"match":
				return "求：和虛線重合　現在 " + vtx_eq(ga, gh, gk)
			"gems":
				return "求：穿過所有寶石　現在 " + vtx_eq(ga, gh, gk)
			"quad":
				var want: Array = gst.quads.duplicate()
				want.sort()
				return "求：只亮 %s　現在亮 %s" % [quad_roman(want), quad_roman(quads_now())]
			"roots":
				return "α + β = %s，αβ = %s ⇒ %s" % [qs(r0 + r1), qs(r0 * r1), roots_eq()]
			"slide":
				if String(gst.get("show", "")) == "pq":
					return "求：轉到你算出的 k，看 \\ol{PQ} 是不是 4"
				return "求：剛好碰到%s的 k（標記 %d／%d 個）" % ["直線" if String(gst.get("show", "")) == "line" else "湖面", gmarks.size(), gst.goals.size()]
			"hline":
				var goal: int = int(gst.goals[mini(gstage, gst.goals.size() - 1)])
				return "求：交點恰有 %d 個的 k（第 %d／%d 個任務）" % [goal, gstage + 1, gst.goals.size()]
		return ""

	# ---------- 背景：月光下的湖 ----------
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		if w < 100.0 or h < 100.0:
			return
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("0b1630"), Color("0b1630"), Color("08101f"), Color("08101f")]))
		var moon := Vector2(w - 26.0, 18.0)
		UITheme.dot(self, moon, 16.0, Color(0.85, 0.92, 1.0, 0.06))
		UITheme.dot(self, moon, 8.0, Color(0.95, 0.97, 1.0, 0.35))
		var stars := PackedVector2Array()
		for i in 22:
			var p := Vector2(fposmod(i * 97.3, w), fposmod(i * 41.7, h * 0.4))
			stars.append_array([p, p + Vector2(1.5, 0)])
		draw_multiline(stars, Color(1, 1, 1, 0.35 + 0.15 * sin(t * 1.3)), 1.5)
		var shim := PackedVector2Array()
		for i in 10:
			var y := h * 0.78 + i * 11.0
			var x := fposmod(t * 18.0 + i * 61.0, w)
			shim.append_array([Vector2(x, y), Vector2(x + 26.0, y)])
		draw_multiline(shim, Color(0.6, 0.8, 1.0, 0.12), 2.0)
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	# ---------- 座標圖 ----------
	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if gst.is_empty() and lake.is_empty():
			super(font, rect)
			return
		_draw_lake(font)

	func _draw_lake(font: Font) -> void:
		var rc := _grect()
		var vw := _view()
		var vx_: Vector2 = vw.x
		var vy_: Vector2 = vw.y
		var ar := _area()
		var mode := String(gst.get("mode", ""))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.08, 0.16, 0.82)
		sb.border_color = Color(LAKE.r, LAKE.g, LAKE.b, 0.4)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(14)
		sb.anti_aliasing = true
		draw_style_box(sb, rc)
		var head: String = {"match": "對準虛線", "gems": "穿過寶石", "quad": "四座燈塔：經過的象限會亮", "roots": "湖面上的兩顆根石",
			"slide": "轉動 k", "hline": "y = |f(x)| 和水平線 y = k"}.get(mode, "湖面")
		MathLabel.draw_text(self, font, rc.position + Vector2(4, -10), head, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(0.75, 0.88, 1.0, 0.85))
		# 湖水（x 軸下方）
		var y0 := clampf(_to(0.0, 0.0).y, ar.position.y, ar.end.y)
		if y0 < ar.end.y:
			draw_polygon(PackedVector2Array([Vector2(ar.position.x, y0), Vector2(ar.end.x, y0), ar.end, Vector2(ar.position.x, ar.end.y)]),
				PackedColorArray([Color(WATER.r, WATER.g, WATER.b, 0.28), Color(WATER.r, WATER.g, WATER.b, 0.28), Color(WATER.r, WATER.g, WATER.b, 0.08), Color(WATER.r, WATER.g, WATER.b, 0.08)]))
		# 格線
		var grid := PackedVector2Array()
		for xi in range(int(ceil(vx_.x)), int(floor(vx_.y)) + 1):
			grid.append_array([_to(xi, vy_.x), _to(xi, vy_.y)])
		for yi in range(int(ceil(vy_.x)), int(floor(vy_.y)) + 1):
			grid.append_array([_to(vx_.x, yi), _to(vx_.y, yi)])
		draw_multiline(grid, Color(1, 1, 1, 0.05), 1.0)
		# 坐標軸（x 軸就是湖面）
		draw_line(_to(vx_.x, 0.0), _to(vx_.y, 0.0), Color(0.7, 0.9, 1.0, 0.75), 2.0)
		if vx_.x < 0 and vx_.y > 0:
			draw_line(_to(0.0, vy_.x), _to(0.0, vy_.y), Color(1, 1, 1, 0.35), 1.5)
		var fs := UITheme.fs(11)
		for xi in range(int(ceil(vx_.x)), int(floor(vx_.y)) + 1):
			if xi != 0:
				var p := _to(xi, 0.0)
				MathLabel.draw_on(self, font, p.x, p.y + 14.0, str(xi).replace("-", "−"), fs, Color(1, 1, 1, 0.45))
		var c := cur_coef()
		match mode:
			"match":
				var tg: Dictionary = gst.target
				var ta := q(tg.a)
				var th := q(tg.h)
				var tk := q(tg.k)
				_curve([ta, -2.0 * ta * th, ta * th * th + tk], GHOST, 2.0, true)
				UITheme.dot(self, _to(th, tk), 5.0, Color(GHOST.r, GHOST.g, GHOST.b, 0.6))
			"hline":
				# 原本湖面下的部分（虛線）和翻上來的部分
				_curve(c, Color(1, 1, 1, 0.25), 1.5, true)
				_curve(c, CURVE, 2.5, false, true)
				_draw_hline(font)
				return
			"slide":
				if String(gst.get("show", "")) == "line":
					var ln: Array = gst.bline
					draw_line(_to(vx_.x, float(ln[0]) * vx_.x + float(ln[1])), _to(vx_.y, float(ln[0]) * vx_.y + float(ln[1])), Color(0.7, 1.0, 0.8, 0.85), 2.5)
		if lake.is_empty() or not gst.is_empty():
			_curve(c, CURVE, 2.5, false)
		elif String(lake.get("show", "curve")) == "curve":
			_curve(c, CURVE, 2.5, false)
		match mode:
			"match", "quad", "gems":
				var vp := _to(gh, gk)
				UITheme.dot(self, vp, 13.0, Color(CURVE.r, CURVE.g, CURVE.b, 0.25 + 0.1 * sin(t * 4.0)))
				UITheme.dot(self, vp, 7.0, CURVE)
		if mode == "gems":
			for g in gst.gems:
				var gp := _to(float(g[0]), float(g[1]))
				var on := absf(fv(c, float(g[0])) - float(g[1])) < 1e-6
				var col: Color = UITheme.GOOD if on else Color("ff8ad8")
				draw_colored_polygon(PackedVector2Array([gp + Vector2(0, -8), gp + Vector2(7, 0), gp + Vector2(0, 8), gp + Vector2(-7, 0)]), col)
				MathLabel.draw_on(self, font, gp.x + 24.0, gp.y - 8.0, "(%s, %s)" % [qm(float(g[0])), qm(float(g[1]))], fs, col.lightened(0.3))
		if mode == "quad":
			_draw_quads(font, ar)
		if mode == "roots":
			for i in 2:
				var rx := r0 if i == 0 else r1
				var rp := _to(rx, 0.0)
				UITheme.dot(self, rp, 12.0, Color(1, 0.6, 0.9, 0.3))
				UITheme.dot(self, rp, 7.0, Color("ff9ad8"))
				MathLabel.draw_on(self, font, rp.x, rp.y - 14.0, "α" if i == 0 else "β", UITheme.fs(15), Color("ffc4ea"))
		if mode == "slide":
			_draw_slide(font, c)
		if not lake.is_empty() and gst.is_empty():
			_draw_lake_hints(font, c)

	## 拋物線（湖面下的部分顏色比較暗）；abs：畫 |f(x)|
	func _curve(c: Array, col: Color, wdt: float, dashed: bool, abs_: bool = false) -> void:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var ar := _area()
		var prev := Vector2.INF
		var prev_y := 0.0
		for i in 241:
			var x := lerpf(vx_.x, vx_.y, i / 240.0)
			var y := fv(c, x)
			if abs_:
				y = absf(y)
			var p := _to(x, y)
			if prev != Vector2.INF:
				var under := (y + prev_y) * 0.5 < 0.0
				var cc := Color(col.r, col.g, col.b, col.a * (0.45 if under else 1.0))
				var sg := clip_seg(prev, p, ar)
				if sg.size() == 2 and (not dashed or i % 4 < 2):
					draw_line(sg[0], sg[1], cc, wdt, true)
			prev = p
			prev_y = y

	## 把線段切到圖的上下邊界裡（超出去的部分不畫，不會在邊上留下水平的一小段）
	static func clip_seg(a: Vector2, b: Vector2, ar: Rect2) -> PackedVector2Array:
		var top := ar.position.y
		var bot := ar.end.y
		if (a.y < top and b.y < top) or (a.y > bot and b.y > bot):
			return PackedVector2Array()
		var p := a
		var q2 := b
		for e in [top, bot]:
			var edge: float = e
			if (p.y - edge) * (q2.y - edge) < 0.0:
				var k: float = (edge - p.y) / (q2.y - p.y)
				var m := p.lerp(q2, k)
				if (edge == top and p.y < top) or (edge == bot and p.y > bot):
					p = m
				else:
					q2 = m
		return PackedVector2Array([p, q2])

	func _draw_quads(font: Font, ar: Rect2) -> void:
		var got := quads_now()
		var want: Array = gst.quads
		var pos := {1: Vector2(ar.end.x - 26, ar.position.y + 20), 2: Vector2(ar.position.x + 26, ar.position.y + 20),
			3: Vector2(ar.position.x + 26, ar.end.y - 20), 4: Vector2(ar.end.x - 26, ar.end.y - 20)}
		var nm := ["", "Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ"]
		for i in [1, 2, 3, 4]:
			var p: Vector2 = pos[i]
			var lit := got.has(i)
			if want.has(i):
				draw_arc(p, 17.0, 0, TAU, 24, Color(1, 0.85, 0.4, 0.8), 2.0, true)
			UITheme.dot(self, p, 13.0, Color(1, 0.85, 0.4, 0.85) if lit else Color(1, 1, 1, 0.12))
			MathLabel.draw_on(self, font, p.x, p.y + 6.0, nm[i], UITheme.fs(15), Color(0.15, 0.1, 0.02) if lit else Color(1, 1, 1, 0.5))

	func _draw_slide(font: Font, c: Array) -> void:
		var rg: Array = gst.get("range", [-5, 5])
		var ar := _area()
		var rc := _grect()
		var ty := rc.end.y - 8.0
		var tx0 := ar.position.x
		var tx1 := ar.end.x
		draw_line(Vector2(tx0, ty), Vector2(tx1, ty), Color(1, 1, 1, 0.25), 2.0)
		var kx := lerpf(tx0, tx1, (gk - float(rg[0])) / (float(rg[1]) - float(rg[0])))
		UITheme.dot(self, Vector2(kx, ty), 7.0, CURVE)
		for m in gmarks:
			var mx := lerpf(tx0, tx1, (float(m) - float(rg[0])) / (float(rg[1]) - float(rg[0])))
			UITheme.dot(self, Vector2(mx, ty), 5.0, UITheme.GOOD)
		# 交點
		var cc: Array = c.duplicate()
		var line := String(gst.get("show", "")) == "line"
		if line:
			var ln: Array = gst.bline
			cc = [c[0], c[1] - float(ln[0]), c[2] - float(ln[1])]
		var xs := _real_roots(cc)
		for x in xs:
			var y := fv(c, x)
			UITheme.dot(self, _to(x, y), 6.0, UITheme.GOOD if xs.size() == 1 else Color(1, 0.6, 0.6))
		var n := xs.size()
		var msg := "k = %s：交點 %d 個" % [qs(gk), n]
		if n == 1:
			msg += "（剛好碰到！）"
		if String(gst.get("show", "")) == "pq" and n == 2:
			msg = "k = %s：\\ol{PQ} = %s" % [qs(gk), qs(absf(xs[1] - xs[0]))]
		MathLabel.draw_on(self, font, rc.get_center().x, rc.position.y + 20.0, msg, UITheme.fs(15), UITheme.GOOD.lightened(0.2) if n == 1 else Color(0.9, 0.95, 1.0))

	static func _real_roots(c: Array) -> Array:
		var a := float(c[0])
		var b := float(c[1])
		var d := b * b - 4.0 * a * float(c[2])
		if absf(d) < 1e-9:
			return [-b / (2.0 * a)]
		if d < 0:
			return []
		var s := sqrt(d)
		var xs := [(-b - s) / (2.0 * a), (-b + s) / (2.0 * a)]
		xs.sort()
		return xs

	func _draw_hline(font: Font) -> void:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var vy_: Vector2 = vw.y
		var rc := _grect()
		var c := cur_coef()
		var col := Color(0.7, 1.0, 0.8, 0.9)
		draw_line(_to(vx_.x, gk), _to(vx_.y, gk), col, 2.5)
		MathLabel.draw_on(self, font, _to(vx_.y, gk).x - 30.0, _to(vx_.y, gk).y - 8.0, "y = " + qm(gk), UITheme.fs(13), col)
		var xs := []
		if gk > 1e-9:
			xs = _real_roots([c[0], c[1], c[2] - gk]) + _real_roots([c[0], c[1], c[2] + gk])
		elif absf(gk) < 1e-9:
			xs = _real_roots(c)
		for x in xs:
			UITheme.dot(self, _to(x, gk), 6.0, Color(1, 0.85, 0.4))
		var msg := "k = %s：交點 %d 個" % [qs(gk), cross_count()]
		MathLabel.draw_on(self, font, rc.get_center().x, rc.position.y + 20.0, msg, UITheme.fs(15), Color(0.9, 0.95, 1.0))
		for i in gmarks.size():
			MathLabel.draw_on(self, font, rc.position.x + 60.0, rc.position.y + 20.0 + 18.0 * i, "✓ k = %s" % qm(float(gmarks[i])), UITheme.fs(12), UITheme.GOOD)

	## 看圖判斷係數、對稱比大小：依這一步的 hl 標出要看的地方
	func _draw_lake_hints(font: Font, c: Array) -> void:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var vy_: Vector2 = vw.y
		var fs := UITheme.fs(12)
		var hlc := Color(1, 0.6, 0.85)
		var vx := -float(c[1]) / (2.0 * float(c[0]))
		if String(lake.get("show", "")) == "axis":
			var ax := float(lake.get("axis", vx))
			var a1 := _to(ax, vy_.x)
			var a2 := _to(ax, vy_.y)
			draw_dashed_line(a1, a2, Color(1, 0.85, 0.4, 0.7), 2.0, 6.0)
			MathLabel.draw_on(self, font, a2.x, a2.y + 14.0, "x = " + qm(ax), UITheme.fs(13), Color(1, 0.85, 0.4))
			var labels: Array = lake.get("labels", [])
			var marks: Array = lake.get("marks", [])
			var order: Array = range(marks.size())
			order.sort_custom(func(u, v): return float(marks[u]) < float(marks[v]))
			for i in marks.size():
				var p := _to(float(marks[i]), 0.0)
				UITheme.dot(self, p, 5.0, LAKE)
				MathLabel.draw_on(self, font, p.x, p.y - 10.0 - 16.0 * (order.find(i) % 2), String(labels[i]) if i < labels.size() else "", UITheme.fs(13), LAKE.lightened(0.3))
				draw_line(p, _to(ax, 0.0), Color(LAKE.r, LAKE.g, LAKE.b, 0.25), 1.0)
			MathLabel.draw_on(self, font, _grect().get_center().x, _grect().position.y + 20.0,
				"開口向上" if float(c[0]) > 0 else "開口向下", UITheme.fs(14), Color(0.9, 0.95, 1.0))
			return
		match hl:
			"open":
				for sx in [vx_.x + 0.4, vx_.y - 0.4]:
					var p := _to(sx, clampf(fv(c, sx), vy_.x, vy_.y))
					UITheme.dot(self, p, 9.0, Color(hlc.r, hlc.g, hlc.b, 0.5 + 0.3 * sin(t * 5.0)))
			"yint":
				var p0 := _to(0.0, float(c[2]))
				UITheme.dot(self, p0, 10.0, Color(hlc.r, hlc.g, hlc.b, 0.5 + 0.3 * sin(t * 5.0)))
				MathLabel.draw_on(self, font, p0.x + 34.0, p0.y + 4.0, "(0, c)", fs, hlc)
			"axis":
				draw_dashed_line(_to(vx, vy_.x), _to(vx, vy_.y), Color(hlc.r, hlc.g, hlc.b, 0.8), 2.0, 6.0)
				UITheme.dot(self, _to(vx, fv(c, vx)), 8.0, hlc)
				MathLabel.draw_on(self, font, _to(vx, vy_.y).x, _to(vx, vy_.y).y + 14.0, "頂點 x = −\\frac{b}{2a}", fs, hlc)
			"roots":
				for x in _real_roots(c):
					UITheme.dot(self, _to(x, 0.0), 9.0, Color(hlc.r, hlc.g, hlc.b, 0.5 + 0.3 * sin(t * 5.0)))
				MathLabel.draw_on(self, font, _grect().get_center().x, _grect().position.y + 20.0, "和湖面（x 軸）的交點", UITheme.fs(14), hlc)
			"x-1", "x1", "x2":
				var xv := {"x-1": -1.0, "x1": 1.0, "x2": 2.0}[hl] as float
				draw_dashed_line(_to(xv, vy_.x), _to(xv, vy_.y), Color(hlc.r, hlc.g, hlc.b, 0.7), 1.5, 5.0)
				UITheme.dot(self, _to(xv, fv(c, xv)), 8.0, hlc)
				MathLabel.draw_on(self, font, _to(xv, vy_.y).x, _to(xv, vy_.y).y + 14.0, "x = " + qm(xv), fs, hlc)
