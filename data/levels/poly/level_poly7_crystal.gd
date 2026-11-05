extends "res://data/levels/poly/level_poly5_lake.gd"
## 多項式 第七大關「對稱水晶」（對應講義 4-3 重點一：多項式函數的圖形，三次函數）
## 引擎是 step_level.gd，座標圖沿用第五關的湖面圖，題庫在 poly7_bank.gd。
##
## 新的 graph 步驟（寫法見 poly7_bank.gd 開頭）：cmatch、mirror、far、tangent、chline
## 題目帶 "plots" 時，整段旅程的下方都畫著那張圖（看圖判斷用）。
## 每一步中間的推導紀錄都寫出「求：…」；圖上不寫中文，只標字母、坐標。

const BankP7 := preload("res://data/levels/poly/poly7_bank.gd")
const CRYSTAL_C := Color("c9a6ff")

const CHAPTERS_P7 := [
	{"ch": 1, "name": "第一章．水晶的對稱", "topic": "單項函數、y = ax³ + px、對稱中心、轉半圈、看圖判斷", "color": Color("c9a6ff")},
	{"ch": 2, "name": "第二章．遠看與近看", "topic": "廣域特徵、局部特徵與一次近似、求三次函數、水平線交點", "color": UITheme.CYAN},
]

const MODES_P7 := ["cmatch", "mirror", "far", "tangent", "chline"]


func level_id() -> String:
	return "P7"

func level_title() -> String:
	return "對稱水晶"

func level_subtitle() -> String:
	return "三次函數的圖形"

func level_chapters() -> Array:
	return CHAPTERS_P7

func bank_slots() -> Array:
	return BankP7.slots()

func step_color() -> Color:
	return CRYSTAL_C

func stage_style() -> Dictionary:
	return {"sky_top": Color("281040"), "sky_bot": Color("100720"), "scenery": "none", "ambient": ""}     # 粒子畫在 Scenery 背景裡

func chapter_card() -> Dictionary:
	return {"title": "第二章．遠看與近看", "button": "拿起望遠鏡  ▶",
		"text": "同一條曲線，遠看和近看不一樣：\n\n" \
			+ "・遠看：只剩 ax^{3}\n" \
			+ "・近看：像直線 y = c(x − h) + d\n" \
			+ "・用線索寫出三次函數\n" \
			+ "・和水平線一定有交點\n\n" \
			+ "準備出發！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = CrystalView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "水晶速算"
		fview.speed_y = 0.42


func _cv() -> CrystalView:
	return fview as CrystalView


# ================= graph 步驟 =================

func _build_graph(st: Dictionary) -> void:
	super(st)
	var mode := String(st.mode)
	if not (mode in MODES_P7):
		return
	var lv := _cv()
	var vw := lv._view()
	var vx_: Vector2 = vw.x
	var vy_: Vector2 = vw.y
	match mode:
		"cmatch":
			_add_slider("a", "a", 0, 0, 1, st.get("a_list", []))
			_add_slider("p", "p", 0, 0, 1, st.get("p_list", []))
			if not bool(st.get("lock", false)):
				_add_slider("h", "h", ceilf(vx_.x), floorf(vx_.y), 1)
				_add_slider("k", "k", ceilf(vy_.x), floorf(vy_.y), 1)
		"mirror":
			_add_slider("B 的 x", "bx", ceilf(vx_.x), floorf(vx_.y), 1)
			_add_slider("B 的 y", "by", ceilf(vy_.x), floorf(vy_.y), 1)
		"far":
			_add_slider("拉遠", "z", 0, int(st.get("zmax", 4)), 1)
		"tangent":
			_add_slider("m", "m", -8, 8, LakeView.q(st.get("mstep", "1")))
			_add_slider("放大", "z", 0, int(st.get("zmax", 4)), 1)
		"chline":
			var rg: Array = st.get("range", [-5, 5])
			_add_slider("k", "k", float(rg[0]), float(rg[1]), 1)
	go_btn.text = {"cmatch": "就是這條" if bool(st.get("sign_only", false)) else "對準了", "mirror": "轉到了", "far": "確定",
		"tangent": "貼住了", "chline": "確定"}[mode]
	fview.live_q = "在下方的圖上拖動（或拉右邊的滑桿），再按「%s」。" % go_btn.text
	_on_graph_move()


func _graph_submit(st: Dictionary) -> void:
	var lv := _cv()
	match String(st.mode):
		"cmatch":
			var tg: Dictionary = st.target
			var ta := LakeView.q(tg.a)
			var tp := LakeView.q(tg.p)
			if bool(st.get("sign_only", false)):
				if signf(lv.ga) == signf(ta) and signf(lv.gp) == signf(tp):
					_graph_done(st)
					return
				_wrong(st, "a、p 的正負還不對。提示：%s" % st.nudge)
				return
			if LakeView.same(lv.ga, ta) and LakeView.same(lv.gp, tp) and LakeView.same(lv.gh, LakeView.q(tg.h)) and LakeView.same(lv.gk, LakeView.q(tg.k)):
				_graph_done(st)
				return
			var msg := ""
			if not (LakeView.same(lv.gh, LakeView.q(tg.h)) and LakeView.same(lv.gk, LakeView.q(tg.k))):
				msg = "水晶還沒對準虛線的中心。"
			elif lv.ga * ta < 0:
				msg = "水晶對了，但右邊的方向相反（a 的正負不對）。"
			elif not LakeView.same(lv.ga, ta):
				msg = "水晶對了，陡的程度不一樣（|a| 不對）。"
			else:
				msg = "水晶和 a 都對了，中間的起伏不一樣（p 不對）。"
			_wrong(st, msg + "提示：" + String(st.nudge))
		"mirror":
			var tg2: Array = st.target
			if LakeView.same(lv.bx, float(tg2[0])) and LakeView.same(lv.by, float(tg2[1])):
				_graph_done(st)
				return
			_wrong(st, "B = (%s, %s) 還不是轉半圈的位置：A、B 的中點要剛好是水晶。提示：%s" % [LakeView.qs(lv.bx), LakeView.qs(lv.by), st.nudge])
		"far":
			if lv.gz >= int(st.get("zmax", 4)):
				_graph_done(st)
				return
			_wrong(st, "再拉遠一點，拉到最遠再看。")
		"tangent":
			if LakeView.same(lv.gm, float(st.target)):
				_graph_done(st)
				return
			_wrong(st, "m = %s 的直線還沒貼住：拉「放大」滑桿湊近看，曲線從哪一邊離開直線？提示：%s" % [LakeView.qs(lv.gm), st.nudge])
		"chline":
			var goal: int = int(st.goals[lv.gstage])
			var ks: Array = st.get("ks", [])
			if not ks.is_empty() and not LakeView.same(lv.gk, LakeView.q(ks[lv.gstage])):
				_wrong(st, "先把光線拖到 y = %s。" % String(ks[lv.gstage]).replace("-", "−"))
				return
			var n := lv.line_count()
			if n != goal:
				_wrong(st, "k = %s 時有 %d 個交點，要找 %d 個的位置。提示：%s" % [LakeView.qs(lv.gk), n, goal, st.nudge])
				return
			Game.of(self).sfx("correct")
			lv.gmarks.append(lv.gk)
			lv.gstage += 1
			if lv.gstage >= st.goals.size():
				_graph_done(st)
			else:
				_hint("✓ k = %s：%d 個交點！下一個。" % [LakeView.qs(lv.gk), goal], "good")
				_on_graph_move()
		_:
			super(st)


# ================= 速算 =================

func _speed_tag() -> String:
	return BankP7.T_CENTER


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 正／負這種題目用兩顆大按鈕，其他題目用數字鍵盤
func _speed_show() -> void:
	var pb: Dictionary = problems[sp_i]
	fview.speed_title = String(r.get("title", "水晶速算"))
	if not pb.has("choices"):
		super()
		return
	fview.show_speed(pb.eq, sp_i, problems.size(), streak)
	step_label.text = UITheme.step_bar(_steps(), 0)
	if sp_i > 0:
		story_label.visible = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = pb.q
	# 兩個選項排一排；三、四個選項排成兩欄（免得超出右邊的卡片）
	var many: bool = pb.choices.size() > 2
	var row := GridContainer.new()
	row.columns = 2
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 10)
	rank_box.add_child(row)
	for i in pb.choices.size():
		var b := Button.new()
		b.text = pb.choices[i]
		b.custom_minimum_size = Vector2(0, 56 if many else 72)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.clip_text = true
		b.add_theme_font_size_override("font_size", UITheme.fs(22 if many else 28))
		# ○（紅）、✕（藍）：判斷是不是解，比大大的「是／不是」輕鬆
		var mark := String(pb.choices[i])
		if mark == "○" or mark == "✕":
			var mc: Color = Color("ff6b6b") if mark == "○" else Color("5aa9ff")
			b.add_theme_font_size_override("font_size", UITheme.fs(40))
			for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				b.add_theme_color_override(key, mc)
		var idx: int = i
		b.pressed.connect(func(): _speed_pick(idx))
		row.add_child(b)


func _speed_pick(i: int) -> void:
	if busy or r.get("type", "") != "speed" or sp_i >= problems.size():
		return
	var pb: Dictionary = problems[sp_i]
	if i == int(pb.correct):
		Game.of(self).sfx("correct")
		_speed_correct()
		return
	Game.of(self).sfx("wrong")
	_record(String(pb.get("tag", _speed_tag())))
	streak = 0
	sp_wrong += 1
	time_left = maxf(1.0, time_left - 5.0)
	fview.miss()
	_hint("不對喔，再想一次！（−5 秒）\n" + String(pb.nudge), "bad")
	_update_hud()


## 一般式的寫法：[a, b, c, d] → ax^{3} + bx^{2} + cx + d
static func polyn(c: Array) -> String:
	var out := ""
	var n := c.size() - 1
	for i in c.size():
		var v := float(c[i])
		if LakeView.same(v, 0.0):
			continue
		var pw := n - i
		var xs := "" if pw == 0 else ("x" if pw == 1 else "x^{%d}" % pw)
		var mag := LakeView.qm(absf(v))
		var body := (("" if LakeView.same(absf(v), 1.0) else mag) + xs) if xs != "" else mag
		if out == "":
			out = ("−" if v < 0 else "") + body
		else:
			out += (" − " if v < 0 else " + ") + body
	return out if out != "" else "0"


## (x − h) 的寫法
static func xh(h: int) -> String:
	if h == 0:
		return "x"
	return "(x − %d)" % h if h > 0 else "(x + %d)" % -h


## 係數 × 某個東西：a = 1 不寫、−1 寫負號
static func _term(v: int, body: String, first: bool) -> String:
	if v == 0:
		return ""
	var mag := "" if absi(v) == 1 else str(absi(v))
	if first:
		return ("−" if v < 0 else "") + mag + body
	return (" − " if v < 0 else " + ") + mag + body


static func _const(v: int) -> String:
	if v == 0:
		return ""
	return (" − %d" % -v) if v < 0 else (" + %d" % v)


static func _cube(h: int) -> String:
	return "x^{3}" if h == 0 else xh(h) + "^{3}"


## 速算：
##   crystal  由一般式求 h、讀出標準式的中心、求對稱點的坐標
##   farnear  x = 0 附近的一次近似、x = h 附近的一次近似、遠處的正負（兩顆按鈕）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		var pb := {}
		var t := out.size() % 3
		if kind == "farnear":
			match t:
				0:
					var c := [[1, 2, -1, -2, 3].pick_random(), randi_range(-5, 5), randi_range(-6, 6), randi_range(-7, 7)]
					if c[2] == 0 or c[3] == 0:
						continue
					pb = {"eq": "f(x) = %s\nx = 0 附近近似哪一條直線？" % polyn(c), "answers": [str(c[2]), str(c[3])], "ans": str(c[2]),
						"template": "y = [0]x + [1]", "q": "x = 0 附近：看最後兩項 cx + d。", "nudge": "一次項的係數、常數項。", "tag": BankP7.T_NEAR}
				1:
					var h := randi_range(-3, 3)
					var a: int = [1, 2, -1, -2].pick_random()
					var b := randi_range(-4, 4)
					var cc := randi_range(-6, 6)
					var d := randi_range(-6, 6)
					if h == 0 or cc == 0 or b == 0:
						continue
					var ftxt := _term(a, _cube(h), true) + _term(b, xh(h) + "^{2}", false) + _term(cc, xh(h), false) + _const(d)
					pb = {"eq": "f(x) = %s\nx = %d 附近近似哪一條直線？" % [ftxt, h], "answers": [str(cc), str(d)], "ans": str(cc),
						"template": "y = [0]%s + [1]" % xh(h), "q": "x = h 附近：取 c(x − h) + d。", "nudge": "%s 的係數和最後的常數。" % xh(h), "tag": BankP7.T_NEAR}
				2:
					var a2: int = [1, 2, 3, -1, -2, -3].pick_random()
					var b2: int = [-900, -500, -300, -100, 100, 300, 500, 900].pick_random()
					var c2 := randi_range(-50, 50)
					var e := randi_range(5, 9)
					var neg := randf() < 0.5
					var sgn := signi(a2) * (-1 if neg else 1)
					var xtxt := ("−" if neg else "") + "10^{%d}" % e
					pb = {"eq": "f(x) = %s\nx = %s 時，f(x) 是正還是負？" % [polyn([a2, b2, c2, randi_range(1, 99)]), xtxt],
						"choices": ["正", "負"], "correct": 0 if sgn > 0 else 1, "ans": "",
						"q": "x 很大（或很小）時，只看最高次項 ax^{3}。", "nudge": "ax^{3} 的正負：a 的正負 × x^{3} 的正負。", "tag": BankP7.T_FAR}
		else:
			match t:
				0:
					var a: int = [1, 2, 3, -1, -2, -3].pick_random()
					var h := randi_range(-3, 3)
					if h == 0:
						continue
					var c := [a, -3 * a * h, randi_range(-6, 6), randi_range(-6, 6)]
					pb = {"eq": "y = %s\n對稱中心的 x 坐標 = ？" % polyn(c), "ans": str(h), "template": "h = [0]",
						"q": "h = −\\frac{b}{3a}。", "nudge": "−b 除以 3a。", "tag": BankP7.T_CENTER}
				1:
					var a: int = [1, 2, -1, -2].pick_random()
					var p := randi_range(-3, 3)
					var h := randi_range(-3, 3)
					var k := randi_range(-6, 6)
					if h == 0 or k == 0:
						continue
					var ask_h := randf() < 0.5
					var ftxt := "y = " + _term(a, _cube(h), true) + _term(p, xh(h), false) + _const(k)
					pb = {"eq": "%s\n對稱中心的 %s 坐標 = ？" % [ftxt, "x" if ask_h else "y"], "ans": str(h if ask_h else k),
						"template": "h = [0]" if ask_h else "k = [0]", "q": "a(x − h)^{3} + p(x − h) + k 的對稱中心是 (h, k)。",
						"nudge": "x + 2 = x − (−2)。" if ask_h else "最後的常數就是 k。", "tag": BankP7.T_CENTER}
				2:
					var h := randi_range(-3, 3)
					var k := randi_range(-4, 4)
					var s := randi_range(-5, 5)
					var tt := randi_range(-6, 6)
					if s == h:
						continue
					var ask_x := randf() < 0.5
					pb = {"eq": "對稱中心 (%d, %d)，(%d, %d) 在圖形上\n它的對稱點的 %s 坐標 = ？" % [h, k, s, tt, "x" if ask_x else "y"],
						"ans": str(2 * h - s if ask_x else 2 * k - tt), "template": "x = [0]" if ask_x else "y = [0]",
						"q": "(s, t) 的對稱點是 (2h − s, 2k − t)。", "nudge": "兩點的中點是對稱中心。", "tag": BankP7.T_SYM}
		pb.eq = String(pb.eq).replace("-", "−")
		if pb.has("template"):
			pb.template = String(pb.template)
		pb.ans = String(pb.ans).replace("-", "−")
		if pb.has("answers"):
			pb.answers = pb.answers.map(func(v): return String(v).replace("-", "−"))
		if seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		out.append(pb)
	return out


# ================= 畫面：水晶洞 + 座標圖 =================

class CrystalView extends LakeView:
	const GEM := Color("c9a6ff")
	const GEM_LIGHT := Color("efe2ff")
	const LINE_C := Color("8fe3ff")
	const MODES := ["cmatch", "mirror", "far", "tangent", "chline"]

	var plots := {}
	var gp := 0.0       # cmatch 的 p
	var bx := 0.0       # mirror 的 B
	var by := 0.0
	var gz := 0         # far、tangent 的遠近
	var gm := 0.0       # tangent 的斜率

	func setup(round: Dictionary) -> void:
		super(round)
		plots = round.get("plots", {}) if String(round.get("type", "")) == "forge" else {}

	func _mine() -> bool:
		return String(gst.get("mode", "")) in MODES

	func _graph_on() -> bool:
		return not plots.is_empty() or super()

	func _bottom_limit() -> float:
		if not plots.is_empty() and gst.is_empty():
			return size.y - 276.0
		return super()

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if _mine() or (gst.is_empty() and not plots.is_empty()):
			_draw_crystal_graph(font)
			return
		super(font, rect)

	static func f3(c: Array, x: float) -> float:
		return ((float(c[0]) * x + float(c[1])) * x + float(c[2])) * x + float(c[3])

	func coef3() -> Array:
		match String(gst.get("mode", "")):
			"cmatch":
				return std_coef(ga, gp, gh, gk)
		return gst.get("coef", [0, 0, 0, 0]).map(func(v): return float(v))

	## a(x − h)^{3} + p(x − h) + k 展開
	static func std_coef(a: float, p: float, h: float, k: float) -> Array:
		return [a, -3.0 * a * h, 3.0 * a * h * h + p, -a * h * h * h - p * h + k]

	static func center_of(c: Array) -> Vector2:
		var h := -float(c[1]) / (3.0 * float(c[0]))
		return Vector2(h, f3(c, h))

	# ---------- 狀態 ----------
	func start_graph(st: Dictionary, cb: Callable) -> void:
		super(st, cb)
		var sv: Dictionary = st.get("start", {}) if st.get("start") is Dictionary else {}
		gz = 0
		match String(st.mode):
			"cmatch":
				ga = q(sv.get("a", "1"))
				gp = q(sv.get("p", "0"))
				gh = q(sv.get("h", "0"))
				gk = q(sv.get("k", "0"))
			"mirror":
				bx = 0.0
				by = 0.0
				if same(bx, float(st.target[0])) and same(by, float(st.target[1])):
					bx = 1.0
			"tangent":
				gm = float(st.get("start", 0))
			"chline":
				gk = float(st.get("start", 0))
		queue_redraw()

	func _view() -> Dictionary:
		match String(gst.get("mode", "")):
			"far":
				var b: Array = gst.get("base", [4, 30])
				var xw := float(b[0]) * pow(2.0, gz)
				var yw := float(b[1]) * pow(8.0, gz)
				return {"x": Vector2(-xw, xw), "y": Vector2(-yw, yw)}
			"tangent":
				var b2: Array = gst.get("base", [3, 4])
				var hx := float(gst.h)
				var hy := f3(coef3(), hx)
				var s := pow(2.0, gz)
				return {"x": Vector2(hx - float(b2[0]) / s, hx + float(b2[0]) / s), "y": Vector2(hy - float(b2[1]) / s, hy + float(b2[1]) / s)}
		if gst.is_empty() and not plots.is_empty():
			var vw: Dictionary = plots.get("view", {})
			return {"x": Vector2(float(vw.x[0]), float(vw.x[1])), "y": Vector2(float(vw.y[0]), float(vw.y[1]))}
		return super()

	func _list_step(key: String, val: float, d: int) -> float:
		var lst: Array = gst.get(key, ["1"])
		var idx := 0
		for i in lst.size():
			if same(q(lst[i]), val):
				idx = i
		return q(lst[clampi(idx + d, 0, lst.size() - 1)])

	func nudge_graph(key: String, d: int) -> void:
		if not _mine():
			super(key, d)
			return
		var vw := _view()
		var vx_: Vector2 = vw.x
		var vy_: Vector2 = vw.y
		match key:
			"a":
				ga = _list_step("a_list", ga, d)
			"p":
				gp = _list_step("p_list", gp, d)
			"h":
				gh = clampf(gh + d, vx_.x, vx_.y)
			"k":
				if String(gst.mode) == "chline":
					var rg: Array = gst.get("range", [-5, 5])
					gk = clampf(gk + d, float(rg[0]), float(rg[1]))
				else:
					gk = clampf(gk + d, vy_.x, vy_.y)
			"bx":
				bx = clampf(bx + d, ceilf(vx_.x), floorf(vx_.y))
			"by":
				by = clampf(by + d, ceilf(vy_.x), floorf(vy_.y))
			"z":
				var zmax := int(gst.get("zmax", 4))
				gz = clampi(gz + d, 0, zmax)
			"m":
				gm = clampf(gm + d * q(gst.get("mstep", "1")), -8.0, 8.0)
		_moved()

	func get_param(key: String) -> float:
		if not _mine():
			return super(key)
		match key:
			"a":
				return ga
			"p":
				return gp
			"h":
				return gh
			"k":
				return gk
			"bx":
				return bx
			"by":
				return by
			"z":
				return float(gz)
			"m":
				return gm
		return 0.0

	func set_param(key: String, v: float) -> void:
		if not _mine():
			super(key, v)
			return
		match key:
			"a":
				ga = v
			"p":
				gp = v
			"h":
				gh = v
			"k":
				gk = v
			"bx":
				bx = v
			"by":
				by = v
			"z":
				gz = int(roundf(v))
			"m":
				gm = v
		_moved()

	func _gpad_input(e: InputEvent) -> void:
		if not _mine():
			super(e)
			return
		var pos := Vector2.INF
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			pos = e.position
		elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
			pos = e.position
		if pos == Vector2.INF:
			return
		var w := _from(pos + gpad.position)
		var vw := _view()
		var vx_: Vector2 = vw.x
		var vy_: Vector2 = vw.y
		var before := [ga, gp, gh, gk, bx, by, gz, gm]
		match String(gst.mode):
			"cmatch":
				if not bool(gst.get("lock", false)):
					gh = clampf(roundf(w.x), ceilf(vx_.x), floorf(vx_.y))
					gk = clampf(roundf(w.y), ceilf(vy_.x), floorf(vy_.y))
			"mirror":
				bx = clampf(roundf(w.x), ceilf(vx_.x), floorf(vx_.y))
				by = clampf(roundf(w.y), ceilf(vy_.x), floorf(vy_.y))
			"far":
				var ar := _area()
				var fr := clampf((pos.x + gpad.position.x - ar.position.x) / ar.size.x, 0.0, 1.0)
				gz = int(roundf(fr * int(gst.get("zmax", 4))))
			"tangent":
				var hx := float(gst.h)
				var dx := w.x - hx
				if absf(dx) > (vx_.y - vx_.x) * 0.04:
					var st := q(gst.get("mstep", "1"))
					gm = clampf(roundf((w.y - f3(coef3(), hx)) / dx / st) * st, -8.0, 8.0)
			"chline":
				var rg: Array = gst.get("range", [-5, 5])
				gk = clampf(roundf(w.y), float(rg[0]), float(rg[1]))
		if [ga, gp, gh, gk, bx, by, gz, gm] != before:
			_moved()
		gpad.accept_event()

	## 和水平線 y = k 的交點個數（判別式）
	func line_count() -> int:
		var c := coef3()
		var A := float(c[0])
		var B := float(c[1])
		var C := float(c[2])
		var D := float(c[3]) - gk
		var disc := 18.0 * A * B * C * D - 4.0 * B * B * B * D + B * B * C * C - 4.0 * A * C * C * C - 27.0 * A * A * D * D
		if absf(disc) < 1e-6:
			return 1 if absf(B * B - 3.0 * A * C) < 1e-9 else 2
		return 3 if disc > 0 else 1

	## 水平線的交點（畫點用）
	func line_points() -> Array:
		var c := coef3()
		var vw := _view()
		var vx_: Vector2 = vw.x
		var out := []
		var prev := f3(c, vx_.x) - gk
		for i in range(1, 801):
			var x := lerpf(vx_.x, vx_.y, i / 800.0)
			var v := f3(c, x) - gk
			if absf(v) < 1e-9 or prev * v < 0:
				out.append(x)
			prev = v
		# 碰一下（重根）：極值剛好在 y = k
		var A := 3.0 * float(c[0])
		var B := 2.0 * float(c[1])
		var C := float(c[2])
		var dd := B * B - 4.0 * A * C
		if dd > 0:
			for sx in [(-B - sqrt(dd)) / (2.0 * A), (-B + sqrt(dd)) / (2.0 * A)]:
				if absf(f3(c, sx) - gk) < 1e-6:
					out.append(sx)
		return out

	func readout() -> String:
		match String(gst.get("mode", "")):
			"cmatch":
				var s := "a = %s　p = %s" % [qs(ga), qs(gp)]
				if not bool(gst.get("lock", false)):
					s += "\n水晶 (%s, %s)" % [qs(gh), qs(gk)]
				return s
			"mirror":
				return "B = (%s, %s)" % [qs(bx), qs(by)]
			"far":
				return "拉遠 %d／%d" % [gz, int(gst.get("zmax", 4))]
			"tangent":
				return "m = %s　放大 ×%d" % [qs(gm), int(pow(2.0, gz))]
			"chline":
				return "k = %s：交點 %d 個" % [qs(gk), line_count()]
		return super()

	func center_text() -> String:
		match String(gst.get("mode", "")):
			"cmatch":
				if bool(gst.get("sign_only", false)):
					var tg: Dictionary = gst.target
					return "拼出 a %s 0、p %s 0 的水晶曲線" % [">" if q(tg.a) > 0 else "<", ">" if q(tg.p) > 0 else "<"]
				return "求：和虛線重合"
			"mirror":
				return "求：A 繞水晶轉半圈後的位置 B"
			"far":
				return "一直拉遠，看曲線像哪一條虛線"
			"tangent":
				return "轉動直線，貼住曲線"
			"chline":
				var i := mini(gstage, gst.goals.size() - 1)
				var ks: Array = gst.get("ks", [])
				if not ks.is_empty():
					return "把光線拖到 y = %s，數交點（第 %d／%d 道）" % [String(ks[i]).replace("-", "−"), gstage + 1, gst.goals.size()]
				return "求：交點恰有 %d 個的 k（第 %d／%d 個任務）" % [int(gst.goals[i]), gstage + 1, gst.goals.size()]
		return super()

	# ---------- 背景：水晶洞 ----------
	func _draw_forge_bg() -> void:
		# 這一關自己的背景（data/ui/scenery.gd）
		Scenery.paint(self, "crystal", size, t)
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	# ---------- 座標圖 ----------
	static func nice_step(span: float) -> float:
		var raw := span / 8.0
		var p := pow(10.0, floorf(log(raw) / log(10.0)))
		for m in [1.0, 2.0, 5.0, 10.0]:
			if m * p >= raw:
				return m * p
		return 10.0 * p

	static func tick_text(v: float) -> String:
		if absf(v) >= 10000.0:
			var e := int(floorf(log(absf(v)) / log(10.0) + 1e-9))
			var m := v / pow(10.0, e)
			var ms := qs(snappedf(m, 0.1))
			return ("10^{%d}" % e if ms == "1" else ("−10^{%d}" % e if ms == "−1" else ms + "×10^{%d}" % e))
		return qs(v)

	func _axes(font: Font) -> void:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var vy_: Vector2 = vw.y
		var ar := _area()
		var tx := nice_step(vx_.y - vx_.x) if vx_.y - vx_.x > 12.0 or vx_.y - vx_.x < 3.0 else 1.0
		var ty := nice_step(vy_.y - vy_.x) if vy_.y - vy_.x > 14.0 or vy_.y - vy_.x < 3.0 else 1.0
		var grid := PackedVector2Array()
		var xi := ceilf(vx_.x / tx) * tx
		while xi <= vx_.y + 1e-9:
			grid.append_array([_to(xi, vy_.x), _to(xi, vy_.y)])
			xi += tx
		var yi := ceilf(vy_.x / ty) * ty
		while yi <= vy_.y + 1e-9:
			grid.append_array([_to(vx_.x, yi), _to(vx_.y, yi)])
			yi += ty
		draw_multiline(grid, Color(1, 1, 1, 0.05), 1.0)
		var ybase := clampf(0.0, vy_.x, vy_.y)
		var xbase := clampf(0.0, vx_.x, vx_.y)
		draw_line(_to(vx_.x, ybase), _to(vx_.y, ybase), Color(0.85, 0.8, 1.0, 0.6), 2.0)
		draw_line(_to(xbase, vy_.x), _to(xbase, vy_.y), Color(1, 1, 1, 0.3), 1.5)
		var fs := UITheme.fs(11)
		if gst.is_empty() and not bool(plots.get("ticks", true)):
			MathLabel.draw_on(self, font, ar.end.x - 6.0, _to(vx_.y, ybase).y - 6.0, "x", UITheme.fs(13), Color(0.9, 0.85, 1.0, 0.8))
			return
		xi = ceilf(vx_.x / tx) * tx
		while xi <= vx_.y + 1e-9:
			if absf(xi) > tx * 0.01:
				var p := _to(xi, ybase)
				if p.x > ar.position.x + 10.0 and p.x < ar.end.x - 10.0:
					MathLabel.draw_on(self, font, p.x, p.y + 14.0, tick_text(xi), fs, Color(1, 1, 1, 0.45))
			xi += tx
		yi = ceilf(vy_.x / ty) * ty
		var lx := _to(xbase, 0).x
		while yi <= vy_.y + 1e-9:
			if absf(yi) > ty * 0.01:
				var p2 := _to(xbase, yi)
				if p2.y > ar.position.y + 8.0 and p2.y < ar.end.y - 8.0:
					var tt := tick_text(yi)
					var tw := MathLabel.text_width(font, tt, fs)
					MathLabel.draw_on(self, font, lx - tw * 0.5 - 6.0 if lx - tw - 8.0 > ar.position.x else lx + tw * 0.5 + 6.0, p2.y + 4.0, tt, fs, Color(1, 1, 1, 0.4))
			yi += ty
		MathLabel.draw_on(self, font, ar.end.x - 6.0, _to(vx_.y, ybase).y - 6.0, "x", UITheme.fs(13), Color(0.9, 0.85, 1.0, 0.8))

	func _curve3(c: Array, col: Color, wdt: float, dashed: bool) -> void:
		var vw := _view()
		var vx_: Vector2 = vw.x
		var ar := _area()
		var prev := Vector2.INF
		for i in 361:
			var x := lerpf(vx_.x, vx_.y, i / 360.0)
			var p := _to(x, f3(c, x))
			if prev != Vector2.INF:
				var sg := clip_seg(prev, p, ar)
				if sg.size() == 2 and (not dashed or i % 6 < 3):
					draw_line(sg[0], sg[1], col, wdt, true)
			prev = p

	func _gem(p: Vector2, big: bool) -> void:
		var r := 11.0 if big else 8.0
		var fl := 0.5 + 0.5 * sin(t * 3.0)
		UITheme.dot(self, p, r + 8.0 + 2.0 * fl, Color(GEM.r, GEM.g, GEM.b, 0.18))
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.7, 0), p + Vector2(0, r), p + Vector2(-r * 0.7, 0)]), GEM)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.7, 0), p + Vector2(0, -r * 0.1)]), GEM_LIGHT)

	func _inside(p: Vector2) -> bool:
		return _area().grow(2.0).has_point(p)

	func _draw_crystal_graph(font: Font) -> void:
		var rc := _grect()
		if rc.size.x < 120.0:
			return
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.05, 0.14, 0.85)
		sb.border_color = Color(GEM.r, GEM.g, GEM.b, 0.4)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(14)
		sb.anti_aliasing = true
		draw_style_box(sb, rc)
		_axes(font)
		var fs := UITheme.fs(13)
		if gst.is_empty():
			_draw_plots(font)
			return
		var c := coef3()
		match String(gst.mode):
			"cmatch":
				var tg: Dictionary = gst.target
				if not bool(gst.get("sign_only", false)):
					_curve3(std_coef(q(tg.a), q(tg.p), q(tg.h), q(tg.k)), Color(GHOST.r, GHOST.g, GHOST.b, 0.8), 2.0, true)
				_curve3(c, CURVE, 2.8, false)
				_gem(_to(gh, gk), true)
			"mirror":
				_curve3(c, CURVE, 2.6, false)
				var cen := center_of(c)
				var pa: Array = gst.pa
				var A := _to(float(pa[0]), float(pa[1]))
				var B := _to(bx, by)
				var cp := _to(cen.x, cen.y)
				var ok := same(bx, float(gst.target[0])) and same(by, float(gst.target[1]))
				draw_dashed_line(A, cp, Color(LINE_C.r, LINE_C.g, LINE_C.b, 0.6), 1.5, 5.0)
				draw_dashed_line(cp, B, Color(UITheme.GOOD.r, UITheme.GOOD.g, UITheme.GOOD.b, 0.9) if ok else Color(1, 1, 1, 0.3), 1.5, 5.0)
				_gem(cp, true)
				UITheme.dot(self, A, 6.0, LINE_C)
				MathLabel.draw_on(self, font, A.x + 12.0, A.y - 8.0, "A", fs, LINE_C)
				UITheme.dot(self, B, 12.0, Color(1, 0.85, 0.4, 0.3 + 0.1 * sin(t * 4.0)))
				UITheme.dot(self, B, 6.0, Color(1, 0.85, 0.4))
				MathLabel.draw_on(self, font, B.x + 12.0, B.y - 8.0, "B", fs, Color(1, 0.9, 0.6))
			"far":
				var gh3: Array = gst.get("ghost", [float(c[0]), 0, 0, 0])
				_curve3(gh3, Color(GHOST.r, GHOST.g, GHOST.b, 0.85), 2.0, true)
				_curve3(c, CURVE, 2.6, false)
			"tangent":
				_curve3(c, CURVE, 2.6, false)
				var hx := float(gst.h)
				var hy := f3(c, hx)
				var vw := _view()
				var vx_: Vector2 = vw.x
				var ar := _area()
				var p0 := _to(vx_.x, hy + gm * (vx_.x - hx))
				var p1 := _to(vx_.y, hy + gm * (vx_.y - hx))
				var sg := clip_seg(p0, p1, ar)
				if sg.size() == 2:
					draw_line(sg[0], sg[1], LINE_C, 2.4, true)
				var P := _to(hx, hy)
				UITheme.dot(self, P, 7.0, LINE_C)
				var lbl := "m = " + qm(gm)
				var tw := MathLabel.text_width(font, lbl, fs)
				MathLabel.draw_on(self, font, ar.end.x - tw * 0.5 - 8.0, ar.position.y + 16.0, lbl, fs, LINE_C)
			"chline":
				_curve3(c, CURVE, 2.6, false)
				var vw2 := _view()
				var vx2: Vector2 = vw2.x
				var ar2 := _area()
				var y0 := _to(0, gk).y
				if y0 >= ar2.position.y and y0 <= ar2.end.y:
					draw_line(Vector2(ar2.position.x, y0), Vector2(ar2.end.x, y0), LINE_C, 2.4, true)
					var lbl2 := "y = " + qm(gk)
					var tw2 := MathLabel.text_width(font, lbl2, fs)
					MathLabel.draw_on(self, font, ar2.end.x - tw2 * 0.5 - 30.0, y0 - 8.0, lbl2, fs, LINE_C)
				for x in line_points():
					if x >= vx2.x and x <= vx2.y:
						UITheme.dot(self, _to(x, gk), 6.0, Color(1, 0.85, 0.4))

	## 看圖判斷的圖：曲線、標記的點、水晶（不寫中文）
	func _draw_plots(font: Font) -> void:
		var fs := UITheme.fs(13)
		var ar := _area()
		for cv in plots.get("curves", []):
			var c: Array = cv.c
			var dash := bool(cv.get("dash", false))
			_curve3(c, LINE_C if dash else CURVE, 2.6, dash)
			if cv.has("label"):
				var lx := float(cv.get("lx", 0))
				var p := _to(lx, f3(c, lx))
				p.y = clampf(p.y, ar.position.y + 14.0, ar.end.y - 6.0)
				MathLabel.draw_on(self, font, p.x + float(cv.get("dx", 0)), p.y - 12.0, String(cv.label), fs, LINE_C if dash else CURVE)
		for pt in plots.get("pts", []):
			var pp := _to(float(pt[0]), float(pt[1]))
			UITheme.dot(self, pp, 5.0, Color(1, 1, 1, 0.9))
			var tw := MathLabel.text_width(font, String(pt[2]), UITheme.fs(12))
			var dx := tw * 0.5 + 8.0
			MathLabel.draw_on(self, font, pp.x + (dx if pp.x < ar.get_center().x + 40.0 else -dx), pp.y - 8.0, String(pt[2]), UITheme.fs(12), Color(1, 1, 1, 0.85))
		if plots.has("crystal"):
			var cr: Array = plots.crystal
			_gem(_to(float(cr[0]), float(cr[1])), false)
