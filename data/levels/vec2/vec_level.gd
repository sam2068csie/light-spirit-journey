extends "res://data/levels/num/num_level.gd"
## 平面向量 V1～V8 共用的關卡底層。引擎是數與式的 num_level.gd（推導＋坐標方格、滑桿、先猜、速算按鈕），
## 下方的圖換成「箭頭畫布」（vec_board.gd），再加上在畫布上作答的步驟：
##   {"kind": "vtap", "name", "q", "line", "nudge", "tag", "ref": "a", "targets": ["p", "t"], "why": {"q": 點錯這一支的提示}}
##       點出和 ref 相等的箭頭（可以複選）。點到的箭頭飛過去疊在 ref 上：一樣的留下來發光，不一樣的露出差別再彈回去
##   {"kind": "vpick", …, "target": [x, y], "snap": 1, "traps": [[x, y, "提示"], …]}
##       點一個格子點（例如從 P 出發的 \vec{a} 指到哪裡）
##   {"kind": "vdrag", …, "fixed": ["A", "B"]（可省略）, "need": 4, "pairs": [["AB", "DC"], …]（全部的答案）,
##    "seed": [["AB", "DC"]]（上一步已經找到的）, "done_btn": true}
##       拖箭頭平移，頭尾都落在點上就找到一對。fixed：只能拖這一支。done_btn：按「找齊了」才判斷（太早按會說還剩幾對）
##   {"kind": "vpath", …, "from": [x, y], "to": [x, y], "tiles": [{"s": "\\vec{AB}", "v": [x, y]}, …], "flip": true, "sol": [[磁磚, ±1], …]}
##       鋪路：右邊點磁磚（＋、−），箭頭一支接一支從 from 鋪出去，按「確定」：終點是 to 就對，風箏沿著路飛過去
##   {"kind": "vplace", …, "sandbox": {"label": "D", "poly": ["A", "B", "C", "D"], "lit": [[x, y]] 或 "all", "start": [x, y]},
##    "goal": "lit" 或 "lit_not_para", "para": [x, y], "ans": [x, y]（測試用）}
##       拖一個點，條件成立時右上角的燈亮。goal：燈亮就對，或燈亮但不是平行四邊形（找反例）
##   {"kind": "vweigh", …, "b": [x, y], "c": [x, y], "p": [x, y], "ans": [B 掛幾個, C 掛幾個]}
##       秤桿：B、C 兩端掛砝碼，在 P 平衡（wb × \ol{BP} = wc × \ol{PC}）才算對
##   choice 加 "sandbox": {…}：判斷的時候可以隨便拖那個點看燈（不扣分）。"ribbon": [[x, y], …]：答對後彩帶圍成那個四邊形
##   slide（滑桿，見 line_level.gd）：lines 裡也可以放 arrow、poly、balloon、tag、walk（座標寫算式）；"keep": true 做完留在畫布上
## 圖層寫法見 vec_board.gd。速算的題目可以帶 "plane"：每一題換一張圖。

const VecBoard := preload("res://data/levels/vec2/vec_board.gd")
const VKINDS := ["vtap", "vpick", "vdrag", "vpath", "vplace", "vweigh"]

var vt_found := {}
var vd_found: Array = []
var vd_list: MathLabel
var vpath_expr: MathLabel
var vweigh_labels := {}
var vpick_ok := false


func scene_theme() -> String:
	return "plateau"


func stage_style() -> Dictionary:
	return {"sky_top": Color("16243d"), "sky_bot": Color("0a1020"), "scenery": "none", "ambient": ""}


func _ensure_fview() -> void:
	if fview == null:
		var v := VecView.new()
		v.theme_name = scene_theme()
		fview = v
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "速算"


func _vp() -> VecBoard:
	return _pv().plane as VecBoard


func _vkind() -> String:
	if r.get("type", "") != "forge" or si >= steps.size():
		return ""
	return String(steps[si].kind)


# ================= 步驟 =================

func _forge_step() -> void:
	if fview != null and _pv().plane != null:
		_vp().vec_off()
	super()
	if si >= steps.size() or r.get("type", "") != "forge":
		return
	var st: Dictionary = steps[si]
	var k := String(st.kind)
	if k in VKINDS:
		_clear(predict_box)
		predicting = false
		keypad_on = false
		rank_box.visible = true
		_clear(rank_box)
		task_label.visible = true
		task_label.text = st.q
		pic_missed = false
		go_btn.visible = false
	match k:
		"vtap":
			vt_found = {}
			_vp().arrows_on(String(st.ref), _vtap_event)
		"vpick":
			vpick_ok = false
			_vp().pts_on(float(st.get("snap", 1.0)), _vpick_event)
		"vdrag":
			vd_found = []
			for p in st.get("seed", []):
				vd_found.append(_pair_key(String(p[0]), String(p[1])))
			_vp().drag_on(st.get("fixed", []), _vdrag_event)
			for p in st.get("seed", []):
				_vp().found_pairs.append([String(p[0]), String(p[1])])
			vd_list = _wrap_label(17, UITheme.GOOD)
			vd_list.max_width = 330
			rank_box.add_child(vd_list)
			_vd_refresh()
			if bool(st.get("done_btn", false)):
				go_btn.visible = true
				go_btn.disabled = false
				go_btn.text = "找齊了"
		"vpath":
			_vp().path_on(_v2(st.from), _v2(st.to))
			_build_tiles(st)
			go_btn.visible = true
			go_btn.disabled = false
			go_btn.text = "確定"
		"vplace":
			_vp().place_on(st.sandbox, func(_p): pass)
			go_btn.visible = true
			go_btn.disabled = false
			go_btn.text = "確定"
		"vweigh":
			_vp().weigh_on({"b": st.b, "c": st.c, "p": st.p, "wb0": 1, "wc0": 1})
			_build_weigh()
			go_btn.visible = true
			go_btn.disabled = false
			go_btn.text = "確定"
		"choice":
			if st.has("sandbox"):
				_vp().place_on(st.sandbox, func(_p): pass)


static func _v2(a) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


func _vec_finish(at_si: int) -> void:
	if si != at_si or si >= steps.size():
		return
	var st: Dictionary = steps[si]
	Game.of(self).sfx("correct")
	_vp().vec_off()
	go_btn.visible = false
	_clear(rank_box)
	rank_box.visible = false
	_step_done(st, String(st.get("why", "")) if st.get("why") is String else "")


## 圖上作答答錯：一步只扣一次能量（和數與式一樣）
func _vwrong(st: Dictionary, msg: String) -> void:
	_pic_wrong(st, msg)


# ---------- 點箭頭 ----------

func _vtap_event(id: String) -> void:
	if _vkind() != "vtap":
		return
	var st: Dictionary = steps[si]
	if vt_found.has(id):
		_hint("這一支已經疊上去了。", "info")
		return
	if (st.targets as Array).has(id):
		vt_found[id] = true
		_vp().fx_merge(id, true)
		Game.of(self).play("blip", 1.0 + 0.1 * vt_found.size(), -8.0)
		if vt_found.size() >= (st.targets as Array).size():
			get_tree().create_timer(0.7).timeout.connect(_vec_finish.bind(si))
		else:
			_hint("一模一樣！還有。", "good")
		return
	_vp().fx_merge(id, false)
	var why: Dictionary = st.get("why_bad", {})
	_vwrong(st, String(why.get(id, st.nudge)))


# ---------- 點一個點 ----------

func _vpick_event(p: Vector2) -> void:
	if _vkind() != "vpick":
		return
	var st: Dictionary = steps[si]
	if p.is_equal_approx(_v2(st.target)):
		_vec_finish(si)
		return
	_vp().fx_x(p)
	var msg := String(st.nudge)
	for tr in st.get("traps", []):
		if p.is_equal_approx(Vector2(float(tr[0]), float(tr[1]))):
			msg = String(tr[2])
	_vwrong(st, msg)


# ---------- 拖箭頭找一樣的 ----------

static func _pair_key(a: String, b: String) -> String:
	return a + "=" + b if a < b else b + "=" + a


func _vd_refresh() -> void:
	if vd_list == null or not is_instance_valid(vd_list):
		return
	var rows := []
	for p in _vp().found_pairs:
		rows.append("\\vec{%s} = \\vec{%s}" % [p[0], p[1]])
	vd_list.text = "　".join(rows) if rows.size() <= 2 else "\n".join(_pairs_rows(rows))


static func _pairs_rows(rows: Array) -> Array:
	var out := []
	var i := 0
	while i < rows.size():
		out.append("　".join(rows.slice(i, i + 2)))
		i += 2
	return out


func _vdrag_event(d: Dictionary) -> void:
	if _vkind() != "vdrag":
		return
	var st: Dictionary = steps[si]
	var key := _pair_key(String(d.from), String(d.to))
	if vd_found.has(key):
		_hint("這一對找過了。", "info")
		_vp().drag_arrow.a = _vp().drag_arrow.oa
		_vp().drag_arrow.b = _vp().drag_arrow.ob
		return
	vd_found.append(key)
	_vp().drag_found(String(d.from), String(d.to))
	Game.of(self).play("blip", 1.0 + 0.08 * vd_found.size(), -8.0)
	_vd_refresh()
	if not bool(st.get("done_btn", false)) and vd_found.size() >= int(st.need):
		get_tree().create_timer(0.6).timeout.connect(_vec_finish.bind(si))
	else:
		_hint("找到一對！", "good")


func _vdrag_submit() -> void:
	var st: Dictionary = steps[si]
	var left := int(st.need) - vd_found.size()
	if left <= 0:
		_vec_finish(si)
		return
	_vwrong(st, "還有 %d 對躲著。%s" % [left, String(st.nudge)])


# ---------- 鋪路 ----------

func _build_tiles(st: Dictionary) -> void:
	var grid := GridContainer.new()
	var tiles: Array = st.tiles
	var flip: bool = st.get("flip", true)
	grid.columns = 2 if flip else mini(3, tiles.size())
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	rank_box.add_child(grid)
	for ti in tiles.size():
		for sg in ([1, -1] if flip else [1]):
			var lab := ("+ " if sg > 0 else "− ") + String(tiles[ti].s)
			var b := MathLabel.make_button(lab, 20, Vector2(0, 46))
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(_tile_add.bind(ti, sg))
			grid.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	rank_box.add_child(row)
	for spec in [["↶ 退一步", _tile_undo], ["重來", _tile_reset]]:
		var b := Button.new()
		b.text = spec[0]
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(spec[1])
		row.add_child(b)
	vpath_expr = _wrap_label(18, UITheme.ACCENT)
	vpath_expr.max_width = 330
	rank_box.add_child(vpath_expr)
	vpath_seq = []
	_tile_refresh()


var vpath_seq: Array = []      # [[磁磚, ±1], …]


func _tile_add(ti: int, sg: int) -> void:
	if _vkind() != "vpath" or vpath_seq.size() >= 8:
		return
	vpath_seq.append([ti, sg])
	Game.of(self).play("blip", 1.0 + 0.05 * vpath_seq.size(), -10.0)
	_tile_refresh()


func _tile_undo() -> void:
	if not vpath_seq.is_empty():
		vpath_seq.pop_back()
	_tile_refresh()


func _tile_reset() -> void:
	vpath_seq = []
	_tile_refresh()


func _tile_refresh() -> void:
	if _vkind() != "vpath":
		return
	var st: Dictionary = steps[si]
	var segs := []
	var coef := {}
	var order := []
	for e in vpath_seq:
		var ti := int(e[0])
		segs.append(_v2(st.tiles[ti].v) * float(e[1]))
		if not coef.has(ti):
			coef[ti] = 0
			order.append(ti)
		coef[ti] += int(e[1])
	_vp().path_segs = segs
	var terms := ""
	for ti in order:
		var c: int = coef[ti]
		if c == 0:
			continue
		var s := String(st.tiles[ti].s)
		var body := s if absi(c) == 1 else ("%d%s" % [absi(c), s] if not s.begins_with("\\frac") else "%d · %s" % [absi(c), s])
		if terms == "":
			terms = ("−" if c < 0 else "") + body
		else:
			terms += (" − " if c < 0 else " + ") + body
	vpath_expr.text = "鋪好的路：" + (terms if terms != "" else "（還沒有）")


func _vpath_submit() -> void:
	var st: Dictionary = steps[si]
	if vpath_seq.is_empty():
		_hint("先點右邊的箭頭，一支一支接起來。", "info")
		return
	var pl := _vp()
	var pts := pl.path_pts()
	if pl.path_end().distance_to(_v2(st.to)) < 1e-4:
		pl.fx_walk(pts, false)
		for i in range(1, pts.size()):
			pl.kept.append({"k": "arrow", "a": pts[i - 1], "b": pts[i], "c": "cyan", "w": 2.5})
		pl.path_segs = []
		_vec_finish(si)
		return
	pl.fx_walk(pts, true, "gold", st.to)
	_vwrong(st, String(st.nudge))


# ---------- 拖點 ----------

func _vplace_submit() -> void:
	var st: Dictionary = steps[si]
	var pl := _vp()
	var p := pl.place_p
	if not is_finite(p.x):
		_hint("先把 %s 拖到方格上。" % String(st.sandbox.get("label", "D")), "info")
		return
	var lit := pl.place_lit(p)
	var ok := lit
	if String(st.get("goal", "lit")) == "lit_not_para":
		ok = lit and not p.is_equal_approx(_v2(st.para))
		for nm in pl.named.keys():
			if p.is_equal_approx(pl.named[nm]):
				ok = false
	if ok:
		var poly := []
		for nm in st.sandbox.get("poly", []):
			var q: Vector2 = p if String(nm) == String(st.sandbox.get("label", "D")) else pl.named[nm]
			poly.append([q.x, q.y])
		if not poly.is_empty():
			pl.fx_ribbon(poly, "pink", false)      # 反例的形狀亮一下（下一張卡的條件不一樣，不留著）
		_vec_finish(si)
		return
	if not lit:
		_vwrong(st, "燈沒有亮：條件不成立。")
	else:
		_vwrong(st, String(st.nudge))


# ---------- 秤桿 ----------

func _build_weigh() -> void:
	vweigh_labels = {}
	for side in ["wb", "wc"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		rank_box.add_child(row)
		var nm := _wrap_label(19, UITheme.ACCENT)
		nm.max_width = 70
		nm.text = "B 掛" if side == "wb" else "C 掛"
		nm.custom_minimum_size = Vector2(70, 0)
		row.add_child(nm)
		for sg in [-1, 1]:
			var b := Button.new()
			b.text = "−" if sg < 0 else "＋"
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(56, 44)
			b.pressed.connect(_weigh_add.bind(side, sg))
			row.add_child(b)
			if sg < 0:
				var vl := _wrap_label(22, UITheme.TEXT)
				vl.max_width = 48
				vl.custom_minimum_size = Vector2(48, 0)
				row.add_child(vl)
				vweigh_labels[side] = vl
	_weigh_refresh()


func _weigh_add(side: String, sg: int) -> void:
	if _vkind() != "vweigh":
		return
	var pl := _vp()
	pl.weigh[side] = clampi(int(pl.weigh[side]) + sg, 1, 9)
	_weigh_refresh()


func _weigh_refresh() -> void:
	var pl := _vp()
	for side in vweigh_labels.keys():
		var vl = vweigh_labels[side]
		if is_instance_valid(vl):
			vl.text = "  %d" % int(pl.weigh.get(side, 1))


func _vweigh_submit() -> void:
	var st: Dictionary = steps[si]
	var tq := _vp().weigh_torque()
	if absf(tq) < 1e-6:
		_vec_finish(si)
		return
	_vwrong(st, ("B 那一邊太重了。" if tq > 0.0 else "C 那一邊太重了。") + String(st.nudge))


# ---------- 送出、測試 ----------

func _custom_go() -> void:
	match _vkind():
		"vtap":
			if vt_found.size() >= (steps[si].targets as Array).size():
				_vec_finish(si)
			return
		"vpick":
			if vpick_ok:
				vpick_ok = false
				_vec_finish(si)
			return
		"vdrag":
			_vdrag_submit()
			return
		"vpath":
			_vpath_submit()
			return
		"vplace":
			_vplace_submit()
			return
		"vweigh":
			_vweigh_submit()
			return
	super()


## 判斷題答對：拖點的題目，彩帶圍出平行四邊形（"ribbon"）
func _custom_answered() -> void:
	if r.get("type", "") == "forge" and si < steps.size() and steps[si].has("ribbon"):
		_vp().fx_ribbon(steps[si].ribbon)
	super()


func _custom_reveal(msg: String) -> void:
	if fview != null and _pv().plane != null:
		_vp().vec_off()
	super(msg)


## 滑桿做完：寫了 "keep": true 的箭頭、多邊形留在畫布上
func _slide_done(st: Dictionary) -> void:
	for ln in st.get("lines", []):
		if bool(ln.get("keep", false)) and String(ln.get("k", "")) in ["arrow", "poly", "tag", "balloon"]:
			var sh := _vp().eval_line(ln, slide_vals)
			if not sh.is_empty():
				_vp().kept.append(sh)
	super(st)


func test_answer(st: Dictionary) -> bool:
	match String(st.kind):
		"vtap":
			for id in st.targets:
				vt_found[String(id)] = true
			return true
		"vpick":
			vpick_ok = true
			return true
		"vdrag":
			vd_found = []
			for p in st.pairs:
				vd_found.append(_pair_key(String(p[0]), String(p[1])))
			return true
		"vpath":
			vpath_seq = []
			for e in st.sol:
				vpath_seq.append([int(e[0]), int(e[1])])
			_tile_refresh()
			return true
		"vplace":
			_vp().place_p = _v2(st.ans)
			return true
		"vweigh":
			_vp().weigh["wb"] = int(st.ans[0])
			_vp().weigh["wc"] = int(st.ans[1])
			_weigh_refresh()
			return true
	return super(st)


# ================= 速算：每一題可以換一張圖 =================

func _speed_show() -> void:
	super()
	var pb: Dictionary = problems[sp_i]
	if pb.has("plane") and fview is VecView:
		var pl := _vp()
		pl.reset(pb.plane)
		pl.visible = true
		fview.speed_y = 0.3
		(fview as VecView)._place_plane()


# ================= 推導台：推導紀錄＋箭頭畫布 =================

class VecView extends NumView:
	func setup(round: Dictionary) -> void:
		if plane == null:
			plane = VecBoard.new()
			add_child(plane)
		super(round)

	func _want_big() -> bool:
		var sts: Array = rd.get("steps", [])
		if kind == "speed":
			return plane != null and plane.visible
		if not done and step < sts.size():
			var st: Dictionary = sts[step]
			if String(st.get("kind", "")) in VKINDS or bool(st.get("big", false)) or st.has("sandbox"):
				return true
		return super()
