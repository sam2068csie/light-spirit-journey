extends "res://data/levels/engine/step_level.gd"
## 直線與圓（C1～C8）共用的關卡引擎：一步一步推導（step_level.gd）＋下方的坐標方格
##
## 題目（variant）可以多一個 "plane"：推導紀錄下方畫一塊坐標方格（x、y 同比例，有格線和刻度）
##   {"x": [−2, 10], "y": [−2, 8], "shapes": [...]}
##   shapes 和終焉之塔的幾何圖一樣（seg、poly、circle、dot、label、angle、right…），多一種 line（整條直線）：
##     {"k": "line", "p": [x1, y1], "q": [x2, y2]}（過兩點）或 {"k": "line", "abc": [a, b, c]}（ax + by + c = 0）
##   每個圖層都可以寫 "at"：第幾步開始出現（0 = 一開始就有）、"until"：第幾步之後消失
##
## 新的步驟（kind）：
##   grid  點選格子點：在坐標方格上點一下，放下一個點（再點別的地方可以移動），按「確定位置」
##         {"kind": "grid", "name", "q", "target": [x, y], "label": "D", "line", "nudge", "tag",
##          "traps": [[x, y, "點到這裡時的提示"], …]（可省略）, "snap": 1（格子點；0.5 = 半格）}
##         答對之後那一點會留在方格上
##         點選的時候可以縮放：手機雙指捏合（兩指一起移動 = 平移），電腦用滑鼠滾輪（右鍵或中鍵拖曳 = 平移），
##         放大之後右上角有「還原」
##   slide 滑桿調參數：拉動滑桿，坐標方格上的直線即時跟著動
##         {"kind": "slide", "name", "q", "line", "nudge", "tag",
##          "params": [{"n": "m", "min": −3, "max": 3, "step": 0.5, "v": 1}, …],
##          "lines": [{"abc": ["m", "-1", "k"], "c": "cyan", "s": "L"}, …]（ax + by + c = 0，係數是含參數的算式）,
##          "eq": "y = {m}x + {k}"（右邊顯示目前的方程式，{…} 裡是算式；可省略）,
##          "goal": {"m": 0.5, "k": −2}（調到這裡才算對）或 "free": true（自由觀察，拉過就可以按「看好了」）,
##          "traps": [[{"k": −2}, "調到這裡時的提示"], …], "keep": true（做完把那條線留在方格上）}
##
## 每一關覆寫 scene_theme()（背景，data/ui/scenery.gd）和平常的關卡資訊（level_id()…，見 step_level.gd）。

const TowerPlot := preload("res://data/levels/tower/boss_tower.gd")
const PLANE_BIG := 290.0          # 點選格子點、做完的時候：坐標方格大一點
const PLANE_SMALL := 206.0        # 其他步驟：小一點，讓上面的推導紀錄和填空放得下

var grid_tip: Label


## 這一關的背景（data/ui/scenery.gd 的主題）
func scene_theme() -> String:
	return "lakeside"


## 距離、半徑常常有根號：這一單元的填空都有「√」鍵
func radicals_ok() -> bool:
	return true


func _ensure_fview() -> void:
	if fview == null:
		var v := PlaneView.new()
		v.theme_name = scene_theme()
		fview = v
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "速算"


func _pv() -> PlaneView:
	return fview as PlaneView


# ================= 點選格子點（grid） =================

func _forge_step() -> void:
	if fview != null and _pv().plane != null:
		_pv().plane.pick_off()
	super()
	if si < steps.size() and String(steps[si].kind) == "grid":
		_build_grid(steps[si])
	elif si < steps.size() and String(steps[si].kind) == "slide":
		_build_slide(steps[si])


func _build_grid(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	var lab := String(st.get("label", "P"))
	_pv().plane.pick_on(lab, float(st.get("snap", 1.0)), func(_p): _refresh_grid())
	grid_tip = Label.new()
	grid_tip.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	grid_tip.custom_minimum_size = Vector2(300, 0)
	grid_tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	grid_tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(grid_tip)
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "確定位置"
	_refresh_grid()


func _refresh_grid() -> void:
	if grid_tip == null or not is_instance_valid(grid_tip) or si >= steps.size():
		return
	var st: Dictionary = steps[si]
	var lab := String(st.get("label", "P"))
	var p: Vector2 = _pv().plane.pick
	if not _pv().plane.has_pick():
		grid_tip.text = "在左下的坐標方格上點一下，放下 %s 點。\n（雙指或滑鼠滾輪可以放大）" % lab
	else:
		grid_tip.text = "%s 點放在 %s。\n要換位置就再點一次。" % [lab, CoordPlane.pt_text(p)]


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size() and String(steps[si].kind) == "grid":
		_grid_submit()
		return
	if r.type == "forge" and si < steps.size() and String(steps[si].kind) == "slide":
		_slide_submit()
		return
	super()


func _grid_submit() -> void:
	var st: Dictionary = steps[si]
	var pl: CoordPlane = _pv().plane
	var lab := String(st.get("label", "P"))
	if not pl.has_pick():
		_hint("先在坐標方格上點一下，放下 %s 點。" % lab, "info")
		return
	var want := Vector2(float(st.target[0]), float(st.target[1]))
	var p: Vector2 = pl.pick
	if p.is_equal_approx(want):
		Game.of(self).sfx("correct")
		pl.add_dot(want, lab, String(st.get("c", "gold")))
		pl.pick_off()
		go_btn.visible = false
		_clear(rank_box)
		rank_box.visible = false
		_step_done(st, "")
		return
	var msg := "還不對。提示：" + String(st.nudge)
	for tr in st.get("traps", []):
		if p.is_equal_approx(Vector2(float(tr[0]), float(tr[1]))):
			msg = String(tr[2])
	_wrong(st, "你放在 %s。%s" % [CoordPlane.pt_text(p), msg])


func _custom_reveal(msg: String) -> void:
	if fview != null and r.type == "forge" and _pv().plane != null:
		var pl: CoordPlane = _pv().plane
		pl.pick_off()
		pl.dyn = []
		for j in range(si, steps.size()):
			var st: Dictionary = steps[j]
			if String(st.kind) == "grid":
				pl.add_dot(Vector2(float(st.target[0]), float(st.target[1])), String(st.get("label", "P")), String(st.get("c", "gold")))
	super(msg)


## 自動測試（tests/test_play.gd）：把這一步的答案放好，之後呼叫 _custom_go() 送出。認得的步驟回傳 true
func test_answer(st: Dictionary) -> bool:
	if String(st.kind) == "grid":
		_pv().plane.pick = Vector2(float(st.target[0]), float(st.target[1]))
		_refresh_grid()
		return true
	if String(st.kind) == "slide":
		for k in st.get("goal", {}).keys():
			slide_vals[k] = float(st.goal[k])
		slide_moved = true
		_refresh_slide()
		return true
	return false


# ================= 滑桿調參數（slide） =================

var slide_vals := {}
var slide_moved := false
var slide_eq: Control
var slide_val_labels := {}


func _build_slide(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	slide_vals = {}
	slide_val_labels = {}
	slide_moved = false
	for p in st.params:
		slide_vals[String(p.n)] = float(p.v)
	var col := step_color()
	if st.has("eq"):
		slide_eq = _wrap_label(18, UITheme.ACCENT)
		slide_eq.max_width = 320
		rank_box.add_child(slide_eq)
	else:
		slide_eq = null
	for p in st.params:
		var nm := String(p.n)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		rank_box.add_child(row)
		var nl = _wrap_label(18, col)
		nl.max_width = 28
		nl.text = nm
		nl.custom_minimum_size = Vector2(22, 0)
		row.add_child(nl)
		var s := UITheme.touch_slider()
		s.min_value = float(p.min)
		s.max_value = float(p.max)
		s.step = float(p.step)
		s.value = float(p.v)
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.custom_minimum_size = Vector2(0, 28)
		UITheme.tint_slider(s, col)
		row.add_child(s)
		UITheme.add_step_buttons(s, col)
		var vl = _wrap_label(17, col)
		vl.max_width = 64
		vl.custom_minimum_size = Vector2(64, 0)
		row.add_child(vl)
		slide_val_labels[nm] = vl
		s.value_changed.connect(func(v: float):
			slide_vals[nm] = v
			slide_moved = true
			_refresh_slide())
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "看好了" if st.get("free", false) else "確定"
	_pv().plane.dyn = st.get("lines", [])
	_pv().plane.dyn_vals = slide_vals
	_refresh_slide()


func _refresh_slide() -> void:
	if si >= steps.size():
		return
	var st: Dictionary = steps[si]
	for nm in slide_val_labels.keys():
		var vl = slide_val_labels[nm]
		if is_instance_valid(vl):
			vl.text = "= " + CoordPlane.frac(float(slide_vals.get(nm, 0.0)))
	if slide_eq != null and is_instance_valid(slide_eq):
		slide_eq.text = CoordPlane.fill_eq(String(st.eq), slide_vals)
	_pv().plane.dyn_vals = slide_vals
	_pv().plane.queue_redraw()


func _slide_submit() -> void:
	var st: Dictionary = steps[si]
	if st.get("free", false):
		if not slide_moved:
			_hint("先拉動滑桿，看看直線怎麼動。", "info")
			return
		_slide_done(st)
		return
	var goal: Dictionary = st.get("goal", {})
	var ok := true
	for k in goal.keys():
		if absf(float(slide_vals.get(k, INF)) - float(goal[k])) > 1e-6:
			ok = false
	if ok:
		_slide_done(st)
		return
	var msg := "還不對。提示：" + String(st.nudge)
	for tr in st.get("traps", []):
		var hit := true
		for k in (tr[0] as Dictionary).keys():
			if absf(float(slide_vals.get(k, INF)) - float(tr[0][k])) > 1e-6:
				hit = false
		if hit:
			msg = String(tr[1])
	_wrong(st, msg)


func _slide_done(st: Dictionary) -> void:
	Game.of(self).sfx("correct")
	var pl: CoordPlane = _pv().plane
	if st.get("keep", false):
		for ln in st.get("lines", []):
			var sh := pl.eval_line(ln, slide_vals)
			if not sh.is_empty():
				pl.kept.append(sh)
	pl.dyn = []
	go_btn.visible = false
	_clear(rank_box)
	rank_box.visible = false
	_step_done(st, "")


# ================= 畫面：推導紀錄＋坐標方格 =================

class PlaneView extends ForgeView:
	var plane: CoordPlane
	var theme_name := "lakeside"

	func setup(round: Dictionary) -> void:
		super(round)
		var pd: Dictionary = round.get("plane", {})
		if plane == null:
			plane = CoordPlane.new()
			add_child(plane)
		plane.reset(pd)
		plane.visible = not pd.is_empty() and kind == "forge"
		ph = PLANE_BIG if _want_big() else PLANE_SMALL
		_place_plane()

	var ph := PLANE_SMALL          # 目前的高度（大小之間慢慢變）

	## 這一步要不要大張的坐標方格（點選格子點、全部做完）
	func _want_big() -> bool:
		var sts: Array = rd.get("steps", [])
		return done or step >= sts.size() or String(sts[step].get("kind", "")) in ["grid", "slide"]

	## 左下角留給光靈和對話框
	func _plane_rect() -> Rect2:
		return Rect2(92, size.y - ph - 12.0, size.x - 116, ph)

	func _place_plane() -> void:
		if plane == null:
			return
		var rc := _plane_rect()
		plane.position = rc.position
		plane.size = rc.size

	func _process(delta: float) -> void:
		super(delta)
		if plane != null and plane.visible:
			var want := PLANE_BIG if _want_big() else PLANE_SMALL
			if absf(ph - want) > 0.5:
				ph = lerpf(ph, want, 1.0 - exp(-10.0 * delta))
				if absf(ph - want) <= 0.5:
					ph = want
				queue_redraw()
			if plane.size != _plane_rect().size or plane.position != _plane_rect().position:
				_place_plane()
			if plane.stage != step:
				plane.stage = step

	func _plane_on() -> bool:
		return plane != null and plane.visible

	func _bottom_limit() -> float:
		if _plane_on():
			return size.y - ph - 22.0
		return super()

	func _draw_forge_bg() -> void:
		Scenery.paint(self, theme_name, size, t)
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))


## 坐標方格：終焉之塔的幾何圖（x、y 同比例）＋格線、坐標軸、刻度，可以點選格子點
class CoordPlane extends TowerPlot.Plot:
	const SnapCol := Color(1.0, 0.86, 0.42)

	var dots: Array = []                 # 答對之後留下的點：{p, s, c}
	var dyn: Array = []                  # 滑桿步驟：跟著參數動的直線 {"abc": [算式…], "c", "s"}
	var dyn_vals := {}
	var kept: Array = []                 # 滑桿步驟做完留下來的直線（已經算好的 line 圖層）
	var pick := Vector2(INF, INF)        # 正在放的點（INF：還沒放）
	var picking := false
	var pick_label := "P"
	var snap := 1.0
	var _on_pick := Callable()

	# ---------- 縮放、平移（只在點選格子點的時候） ----------
	const ZOOM_MAX := 3.0
	var zoom := 1.0
	var pan := Vector2.ZERO              # 視野中心偏移了多少（坐標單位）
	var _touches := {}                   # 手指編號 → 位置
	var _pinch_d := 0.0                  # 雙指一開始的距離、中點
	var _pinch_c := Vector2.ZERO
	var _pinched := false                # 這次手指放下之後有沒有捏合過（捏合中的手指不能拿來放點）
	var _pick_before := Vector2(INF, INF)

	func reset(d: Dictionary) -> void:
		data = d.duplicate(true)
		data["geo"] = true
		data["axes"] = false            # 坐標軸自己畫（有刻度）
		if not data.has("x"):
			data["x"] = [-5, 5]
			data["y"] = [-5, 5]
		dots = []
		dyn = []
		kept = []
		_cache = {}
		stage = 0
		pick_off()
		reset_view()

	func pick_on(label: String, sn: float, cb: Callable) -> void:
		picking = true
		pick_label = label
		snap = sn if sn > 0.0 else 1.0
		pick = Vector2(INF, INF)
		_on_pick = cb
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		queue_redraw()

	func pick_off() -> void:
		picking = false
		_touches = {}
		_pinched = false
		zoom = 1.0
		pan = Vector2.ZERO
		pick = Vector2(INF, INF)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		queue_redraw()

	func reset_view() -> void:
		zoom = 1.0
		pan = Vector2.ZERO
		queue_redraw()

	## 以畫面上的 sp 為中心縮放 f 倍（放大後的視野不會跑出原本的範圍）
	func zoom_at(sp: Vector2, f: float) -> void:
		var before := from_px(sp)
		zoom = clampf(zoom * f, 1.0, ZOOM_MAX)
		pan += before - from_px(sp)
		_clamp_pan()
		queue_redraw()

	func pan_px(d: Vector2) -> void:
		pan -= Vector2(d.x, -d.y) / _scale()
		_clamp_pan()
		queue_redraw()

	func _clamp_pan() -> void:
		var half := _frame().size / (_base_scale() * 2.0)
		var k := 1.0 - 1.0 / zoom
		pan = Vector2(clampf(pan.x, -half.x * k, half.x * k), clampf(pan.y, -half.y * k, half.y * k))

	## 放大之後右上角的「還原」按鈕
	func _reset_rect() -> Rect2:
		return Rect2(size.x - 62.0, 8.0, 54.0, 26.0)

	func has_pick() -> bool:
		return is_finite(pick.x) and is_finite(pick.y)

	func add_dot(p: Vector2, s: String, c := "gold") -> void:
		for d in dots:
			if (d.p as Vector2).is_equal_approx(p) and String(d.s) == s:
				return
		dots.append({"p": p, "s": s, "c": c})
		queue_redraw()

	## 含參數的直線 → 算好係數的 line 圖層（a、b 都是 0 時回傳空的）
	func eval_line(ln: Dictionary, vals: Dictionary) -> Dictionary:
		var abc := []
		for e in ln.abc:
			abc.append(calc(String(e), vals))
		if absf(abc[0]) < 1e-9 and absf(abc[1]) < 1e-9:
			return {}
		var sh := {"k": "line", "abc": abc, "c": String(ln.get("c", "cyan")), "s": String(ln.get("s", "")), "w": float(ln.get("w", 2.5))}
		if ln.has("dash"):
			sh["dash"] = ln.dash
		return sh

	## 算式（可以用參數名稱）→ 數值
	static func calc(e: String, vals: Dictionary) -> float:
		var ex := Expression.new()
		var names := PackedStringArray(vals.keys())
		if ex.parse(e, names) != OK:
			return 0.0
		var v = ex.execute(vals.values())
		return float(v) if not ex.has_execute_failed() and (v is float or v is int) else 0.0

	## 分數的寫法：0.5 → \\frac{1}{2}、−1.5 → −\\frac{3}{2}
	static func frac(v: float) -> String:
		for d in range(1, 13):
			var n := v * d
			if absf(n - roundf(n)) < 1e-6:
				var ni := int(roundf(n))
				if d == 1:
					return num(ni)
				return ("−" if ni < 0 else "") + "\\frac{%d}{%d}" % [absi(ni), d]
		return num(v)

	## "y = {m}x + {k}" 把 {…} 換成數值：「+ −2」寫成「− 2」，x、y 前面的係數 1 不寫
	static func fill_eq(tpl: String, vals: Dictionary) -> String:
		var out := ""
		var i := 0
		while i < tpl.length():
			var ch := tpl[i]
			if ch != "{":
				out += ch
				i += 1
				continue
			var j := tpl.find("}", i)
			var v := calc(tpl.substr(i + 1, j - i - 1), vals)
			i = j + 1
			var nxt := tpl[i] if i < tpl.length() else ""
			var coef := nxt == "x" or nxt == "y"
			if out.ends_with("+ ") and v < -1e-9:
				out = out.substr(0, out.length() - 2) + "− "
				v = -v
			elif out.ends_with("− ") and v < -1e-9:
				out = out.substr(0, out.length() - 2) + "+ "
				v = -v
			# 係數是 0：整項不寫（例如 0y、+ 0）
			if absf(v) < 1e-9 and (coef or out.ends_with("+ ") or out.ends_with("− ")):
				if out.ends_with("+ ") or out.ends_with("− "):
					out = out.substr(0, out.length() - 2).rstrip(" ")
				if coef:
					i += 1
				continue
			if coef and absf(v - 1.0) < 1e-9:
				continue
			if coef and absf(v + 1.0) < 1e-9:
				out += "−"
				continue
			out += frac(v)
		# 第一項被省掉時，開頭的「+ 」「− 」整理一下
		var re := RegEx.new()
		re.compile("(^|：|= |\\n) ?\\+ ")
		out = re.sub(out, "$1", true)
		re.compile("(^|：|= |\\n) ?− ")
		out = re.sub(out, "$1−", true)
		return out

	## (3, −2) 這種寫法（負號用 −）
	static func pt_text(p: Vector2) -> String:
		return "(%s, %s)" % [num(p.x), num(p.y)]

	static func num(v: float) -> String:
		var s := str(int(round(v))) if is_equal_approx(v, round(v)) else str(snappedf(v, 0.01))
		return s.replace("-", "−")

	# ---------- 坐標換算 ----------

	## 題目的範圍（data.x、data.y）放在這個框裡：下面留一條給左下角光靈的對話框（那裡只有格線，不放點）
	const BOTTOM_PAD := 40.0

	func _frame() -> Rect2:
		return Rect2(Vector2(10, 10), size - Vector2(20, 20 + BOTTOM_PAD))

	func _base_scale() -> float:
		var xr: Array = data.x
		var yr: Array = data.y
		var r := _frame()
		return minf(r.size.x / (float(xr[1]) - float(xr[0])), r.size.y / (float(yr[1]) - float(yr[0])))

	func _scale() -> float:
		return _base_scale() * zoom

	## 視野中心的坐標
	func _mid() -> Vector2:
		var xr: Array = data.x
		var yr: Array = data.y
		return Vector2((float(xr[0]) + float(xr[1])) / 2.0, (float(yr[0]) + float(yr[1])) / 2.0) + pan

	func _to(p: Vector2) -> Vector2:
		var sc := _scale()
		var c := _frame().get_center()
		var m := _mid()
		return Vector2(c.x + (p.x - m.x) * sc, c.y - (p.y - m.y) * sc)

	## 畫面上的位置 → 坐標
	func from_px(sp: Vector2) -> Vector2:
		var sc := _scale()
		var c := _frame().get_center()
		var m := _mid()
		return Vector2((sp.x - c.x) / sc + m.x, -(sp.y - c.y) / sc + m.y)

	## 畫面上看得到的坐標範圍（比 data.x、data.y 大一點，因為兩軸同比例）
	func _world() -> Rect2:
		var a := from_px(Vector2(0, size.y))
		var b := from_px(Vector2(size.x, 0))
		return Rect2(a, b - a)

	# ---------- 點選 ----------

	func _gui_input(e: InputEvent) -> void:
		if not picking:
			return
		if _view_input(e):
			accept_event()
			return
		# 捏合中（或剛捏合完、手指還沒全部放開）：不放點
		if _pinched or _touches.size() >= 2:
			return
		var press: bool = e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed
		if press:
			_pick_before = pick
		var drag: bool = e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		if not (press or drag):
			return
		var w := from_px(e.position)
		var wr := _world()
		var p := Vector2(snappedf(w.x, snap), snappedf(w.y, snap))
		p.x = clampf(p.x, ceilf(wr.position.x / snap) * snap, floorf(wr.end.x / snap) * snap)
		p.y = clampf(p.y, ceilf(wr.position.y / snap) * snap, floorf(wr.end.y / snap) * snap)
		if not has_pick() or not p.is_equal_approx(pick):
			pick = p
			queue_redraw()
			if _on_pick.is_valid():
				_on_pick.call(p)
		accept_event()

	## 縮放、平移、還原。處理掉了就回傳 true
	func _view_input(e: InputEvent) -> bool:
		if e is InputEventMouseButton and e.pressed:
			if e.button_index == MOUSE_BUTTON_LEFT and zoom > 1.001 and _reset_rect().has_point(e.position):
				reset_view()
				return true
			if e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				var f := 1.15 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15
				zoom_at(e.position, pow(f, maxf(e.factor, 1.0)) if e.factor > 0.0 else f)
				return true
			if e.button_index == MOUSE_BUTTON_RIGHT or e.button_index == MOUSE_BUTTON_MIDDLE:
				return true
		if e is InputEventMouseMotion and (e.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)) != 0:
			pan_px(e.relative)
			return true
		if e is InputEventMagnifyGesture:
			zoom_at(e.position, e.factor)
			return true
		if e is InputEventPanGesture:
			pan_px(-e.delta * 8.0)
			return true
		if e is InputEventScreenTouch:
			if e.pressed:
				if _touches.is_empty():
					_pinched = false
				_touches[e.index] = e.position
			else:
				_touches.erase(e.index)
				if _touches.is_empty():
					_pinched = false
			if _touches.size() >= 2:
				# 第二根手指放下：第一根手指剛剛放的點不算，改成捏合
				if not _pinched:
					_pinched = true
					if pick != _pick_before:
						pick = _pick_before
						if _on_pick.is_valid():
							_on_pick.call(pick)
				_pinch_start()
			return _pinched
		if e is InputEventScreenDrag:
			_touches[e.index] = e.position
			if _touches.size() >= 2:
				var ks: Array = _touches.keys()
				var a: Vector2 = _touches[ks[0]]
				var b: Vector2 = _touches[ks[1]]
				var d := a.distance_to(b)
				var c := (a + b) / 2.0
				if _pinch_d > 1.0:
					zoom_at(c, d / _pinch_d)
				pan_px(c - _pinch_c)
				_pinch_d = d
				_pinch_c = c
				return true
			return _pinched
		return false

	func _pinch_start() -> void:
		var ks: Array = _touches.keys()
		var a: Vector2 = _touches[ks[0]]
		var b: Vector2 = _touches[ks[1]]
		_pinch_d = a.distance_to(b)
		_pinch_c = (a + b) / 2.0

	# ---------- 繪圖 ----------

	func _draw_geo(font: Font) -> void:
		_draw_grid(font)
		super(font)
		for ln in kept:
			_shape(ln, Vector2.ZERO, 0.0, font)
		for ln in dyn:
			var sh := eval_line(ln, dyn_vals)
			if not sh.is_empty():
				_shape(sh, Vector2.ZERO, 0.0, font)
		for d in dots:
			_shape({"k": "dot", "p": [d.p.x, d.p.y], "s": "%s%s" % [d.s, pt_text(d.p)], "c": d.c}, Vector2.ZERO, 0.0, font)
		if picking and has_pick():
			_draw_pick(font)
		if picking:
			_draw_zoom_ui(font)

	## 放大之後：右上角的「還原」按鈕和倍率
	func _draw_zoom_ui(font: Font) -> void:
		var fs := UITheme.fs(12)
		if zoom <= 1.001:
			return
		var rc := _reset_rect()
		draw_style_box(UITheme.boxc(Color(0.08, 0.1, 0.2, 0.92), 8, Color(SnapCol.r, SnapCol.g, SnapCol.b, 0.7), 1, 0), rc)
		var s2 := "還原"
		var w2 := font.get_string_size(s2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, rc.position + Vector2((rc.size.x - w2) / 2.0, 18.0), s2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, SnapCol)
		var z := "%.1f×" % zoom
		var wz := font.get_string_size(z, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(rc.position.x - wz - 8.0, 26.0), z, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.45))

	## 格線、坐標軸（有箭頭）、刻度數字、x、y、O
	func _draw_grid(font: Font) -> void:
		var wr := _world()
		var u := _unit()
		var tick := 1 if u >= 30.0 else (2 if u >= 15.0 else 5)
		var fs := UITheme.fs(11)
		for ix in range(int(ceilf(wr.position.x)), int(floorf(wr.end.x)) + 1):
			var a := _to(Vector2(ix, wr.position.y))
			var b := _to(Vector2(ix, wr.end.y))
			draw_line(a, b, Color(1, 1, 1, 0.10 if ix % 5 == 0 else 0.05), 1.0)
		for iy in range(int(ceilf(wr.position.y)), int(floorf(wr.end.y)) + 1):
			var a := _to(Vector2(wr.position.x, iy))
			var b := _to(Vector2(wr.end.x, iy))
			draw_line(a, b, Color(1, 1, 1, 0.10 if iy % 5 == 0 else 0.05), 1.0)
		var ax := Color(1, 1, 1, 0.5)
		var o := _to(Vector2.ZERO)
		var has_x := wr.position.y <= 0.0 and wr.end.y >= 0.0
		var has_y := wr.position.x <= 0.0 and wr.end.x >= 0.0
		if has_x:
			var xa := _to(Vector2(wr.position.x, 0))
			var xb := _to(Vector2(wr.end.x, 0))
			draw_line(xa, xb, ax, 1.5, true)
			draw_colored_polygon(PackedVector2Array([xb, xb + Vector2(-9, -4.5), xb + Vector2(-9, 4.5)]), ax)
			draw_string(font, xb + Vector2(-14, -8), "x", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14), Color(1, 1, 1, 0.7))
			for ix in range(int(ceilf(wr.position.x)), int(floorf(wr.end.x))):
				if ix == 0 or ix % tick != 0:
					continue
				var p := _to(Vector2(ix, 0))
				draw_line(p + Vector2(0, -3), p + Vector2(0, 3), ax, 1.0)
				var s := num(ix)
				var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string(font, p + Vector2(-w / 2.0, 15), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.45))
		if has_y:
			var ya := _to(Vector2(0, wr.position.y))
			var yb := _to(Vector2(0, wr.end.y))
			draw_line(ya, yb, ax, 1.5, true)
			draw_colored_polygon(PackedVector2Array([yb, yb + Vector2(-4.5, 9), yb + Vector2(4.5, 9)]), ax)
			draw_string(font, yb + Vector2(8, 14), "y", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14), Color(1, 1, 1, 0.7))
			for iy in range(int(ceilf(wr.position.y)), int(floorf(wr.end.y))):
				if iy == 0 or iy % tick != 0:
					continue
				var p := _to(Vector2(0, iy))
				draw_line(p + Vector2(-3, 0), p + Vector2(3, 0), ax, 1.0)
				var s := num(iy)
				var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string(font, p + Vector2(-w - 6, 4), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.45))
		if has_x and has_y:
			draw_string(font, o + Vector2(-13, 14), "O", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(12), Color(1, 1, 1, 0.55))

	## 正在放的點：到兩軸的虛線、一圈一圈的光、名字和坐標
	func _draw_pick(font: Font) -> void:
		var sp := _to(pick)
		var wr := _world()
		var oy := clampf(0.0, wr.position.y, wr.end.y)
		var ox := clampf(0.0, wr.position.x, wr.end.x)
		_pl(PackedVector2Array([sp, _to(Vector2(pick.x, oy))]), Color(SnapCol.r, SnapCol.g, SnapCol.b, 0.45), 1.2, true)
		_pl(PackedVector2Array([sp, _to(Vector2(ox, pick.y))]), Color(SnapCol.r, SnapCol.g, SnapCol.b, 0.45), 1.2, true)
		var ph := fmod(t * 1.4, 1.0)
		draw_arc(sp, 8.0 + 14.0 * ph, 0.0, TAU, 32, Color(SnapCol.r, SnapCol.g, SnapCol.b, 0.6 * (1.0 - ph)), 2.0, true)
		UITheme.dot(self, sp, 9.0, Color(SnapCol.r, SnapCol.g, SnapCol.b, 0.25))
		UITheme.dot(self, sp, 5.5, SnapCol)
		_label(font, sp, "%s%s" % [pick_label, pt_text(pick)], [10, -10], SnapCol)

	## 放大之後跑到畫面外的點：名字也不要畫（原本會被夾到邊上，看起來像是別的點）
	func _label(font: Font, sp: Vector2, s: String, off, c: Color, center := false) -> void:
		if not Rect2(Vector2.ZERO, size).grow(2.0).has_point(sp):
			return
		super(font, sp, s, off, c, center)

	func _shape(sh: Dictionary, o: Vector2, rot: float, font: Font) -> void:
		if String(sh.k) == "right":
			# 直角記號：比終焉之塔的大一點（不然會被頂點的圓點蓋住）
			var cp := _to(_v(sh.p))
			var u := (_to(_v(sh.p) + _v(sh.u)) - cp).normalized() * 15.0
			var v := (_to(_v(sh.p) + _v(sh.v)) - cp).normalized() * 15.0
			_pl(PackedVector2Array([cp + u, cp + u + v, cp + v]), _col(String(sh.get("c", "gold"))), 1.8, false)
			return
		if String(sh.k) != "line":
			super(sh, o, rot, font)
			return
		# 整條直線：過兩點 p、q，或 ax + by + c = 0
		var p: Vector2
		var d: Vector2
		if sh.has("abc"):
			var a := float(sh.abc[0])
			var b := float(sh.abc[1])
			var c := float(sh.abc[2])
			d = Vector2(b, -a).normalized()
			p = Vector2(-a * c, -b * c) / (a * a + b * b)
		else:
			p = _v(sh.p)
			d = (_v(sh.q) - p).normalized()
		var wr := _world().grow(1.0)
		var big := wr.size.length() + (p - wr.get_center()).length()
		var col := _col(String(sh.get("c", "cyan")))
		_pl(PackedVector2Array([_to(p - d * big), _to(p + d * big)]), col, float(sh.get("w", 2.0)), sh.get("dash", false))
		if String(sh.get("s", "")) != "":
			# 名字標在畫面裡、靠右上那一端
			var e := p + d * big
			var s0 := p - d * big
			var end_w := e if (e.x > s0.x or (is_equal_approx(e.x, s0.x) and e.y > s0.y)) else s0
			var dir := (end_w - p).normalized()
			var lp := p
			for k in 80:
				var q := p + dir * (k * 0.25)
				if not _world().grow(-0.8).has_point(q):
					break
				lp = q
			_label(font, _to(lp), String(sh.s), sh.get("off", [6, -6]), col)
