extends "res://data/levels/line/line_level.gd"
## 數與式 R1～R8 共用的關卡底層。引擎是 line_level.gd（推導＋坐標方格、滑桿），這裡再加：
##   ・推導紀錄下方的「原野」（num_field.gd）：題目有 "field" 就畫風車、數線柵欄（繩子、珠子、跑者、地圖）、質因數積木
##   ・速算可以混用填空和按鈕：題目有 choices 就是大按鈕（數學排版），沒有就用數字鍵盤
##   ・背景：黎明的麥田（data/ui/scenery.gd 的 "meadow"）
##   ・在圖上作答（2026/11/14 試作，少讀字、看圖就能答）：
##       {"kind": "ltap", "name", "q", "line", "nudge", "tag", "item": 0, "snap": 0.5, "a", "b",
##        "regions": [[lo, hi], …], "wrong": "\ol{AC} {rel} \ol{BC}", "hits": [每一區的代表值（測試用）], "miss": 點錯的值（測試用）}
##         在數線上點出每一區各一次（區間不含端點）。點錯的地方出現紅點，標 wrong（{rel} 換成離 a、離 b 的比較 <、=、>）
##       {"kind": "ldrag", …, "a", "b", "beads": [["p", "p"], …], "goal": {"p": 1/3, …}, "snaps": [[比例, "標籤"], …], "why": {"p": 放錯的提示}}
##         把托盤裡的珠子拖到繩上，吸附到「a 往 b 走幾分之幾」，按「確定」。放錯的退回托盤
##       {"kind": "btap", …, "item": 0}   點一塊分子積木、再點一樣的分母積木就約掉，約到沒有一樣的為止
## 每一關只要寫 level_id、標題、章節、題庫、速算的題目產生器。

const NumField := preload("res://data/levels/num/num_field.gd")


func scene_theme() -> String:
	return "meadow"

func stage_style() -> Dictionary:
	return {"sky_top": Color("1d1a33"), "sky_bot": Color("0c0b18"), "scenery": "none", "ambient": ""}

## 數與式的填空大多用不到根號鍵（要根號的格子，根號會寫在式子裡）
func radicals_ok() -> bool:
	return false


func _ensure_fview() -> void:
	if fview == null:
		var v := NumView.new()
		v.theme_name = scene_theme()
		fview = v
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "速算"



# ================= 在圖上作答：ltap、ldrag、btap =================

var lt_found := {}
var pic_missed := false


func _nf() -> NumField:
	if fview != null and fview is NumView and fview.field != null:
		return fview.field as NumField
	return null


func _forge_step() -> void:
	if _nf() != null:
		_nf().end()
	super()
	if si >= steps.size() or r.get("type", "") != "forge":
		return
	var st: Dictionary = steps[si]
	match String(st.kind):
		"ltap", "ldrag", "btap":
			_clear(predict_box)
			predicting = false
			keypad_on = false
			rank_box.visible = true
			_clear(rank_box)
			task_label.visible = true
			task_label.text = st.q
			pic_missed = false
			go_btn.visible = false
	match String(st.kind):
		"ltap":
			lt_found = {}
			_nf().begin("tap", {"item": int(st.get("item", 0)), "snap": float(st.get("snap", 1.0))}, _ltap_event)
		"ldrag":
			_nf().begin("drag", {"item": int(st.get("item", 0)), "a": st.a, "b": st.b, "beads": st.beads, "snaps": st.snaps}, func(_e): pass)
			go_btn.visible = true
			go_btn.disabled = false
			go_btn.text = "確定"
		"btap":
			_nf().begin("blocks", {"item": int(st.get("item", 0))}, _btap_event)


func _pic_kind() -> String:
	if r.get("type", "") != "forge" or si >= steps.size():
		return ""
	return String(steps[si].kind)


## 圖上作答答錯：一步只扣一次能量（和 grids 一樣），之後只提示
func _pic_wrong(st: Dictionary, msg: String) -> void:
	if not pic_missed:
		pic_missed = true
		_wrong(st, msg)
	else:
		Game.of(self).sfx("wrong")
		fview.miss()
		_hint(msg, "bad")


func _pic_finish(at_si: int) -> void:
	if si != at_si or si >= steps.size():
		return
	Game.of(self).sfx("correct")
	_nf().end()
	go_btn.visible = false
	_clear(rank_box)
	rank_box.visible = false
	_step_done(steps[si], "")


func _ltap_event(ev: Dictionary) -> void:
	if _pic_kind() != "ltap":
		return
	var st: Dictionary = steps[si]
	var v := float(ev.v)
	for k in st.regions.size():
		var rg: Array = st.regions[k]
		if v > float(rg[0]) + 1e-6 and v < float(rg[1]) - 1e-6:
			if lt_found.has(k):
				_hint("這一邊找過了，還有一個。", "info")
				return
			lt_found[k] = true
			_nf().mark(v, true)
			Game.of(self).play("blip", 1.0 + 0.1 * lt_found.size(), -8.0)
			if lt_found.size() >= st.regions.size():
				_pic_finish.call_deferred(si)
			else:
				_hint("對！還有一個。", "good")
			return
	var da := absf(v - float(st.a))
	var db := absf(v - float(st.b))
	var rel := "="
	if da < db - 1e-6:
		rel = "<"
	elif da > db + 1e-6:
		rel = ">"
	_nf().mark(v, false, String(st.get("wrong", "")).replace("{rel}", rel))
	_pic_wrong(st, String(st.nudge))


func _ldrag_submit() -> void:
	var st: Dictionary = steps[si]
	var res: Dictionary = _nf().drag_result()
	var empty := []
	var bad := []
	for b in st.beads:
		var nm := String(b[0])
		if res.get(nm) == null:
			empty.append(nm)
		elif not is_equal_approx(float(res[nm]), float(st.goal[nm])):
			bad.append(nm)
	if not empty.is_empty():
		_hint("把 %s 也拖到繩上。" % "、".join(empty), "info")
		return
	if bad.is_empty():
		_pic_finish(si)
		return
	_nf().drag_reject(bad)
	var why: Dictionary = st.get("why", {})
	_pic_wrong(st, "%s 放錯了。%s" % ["、".join(bad), String(why.get(bad[0], st.nudge))])


func _btap_event(ev: Dictionary) -> void:
	if _pic_kind() != "btap":
		return
	var st: Dictionary = steps[si]
	if bool(ev.cut):
		Game.of(self).play("blip", 1.2, -8.0)
		if int(ev.left) == 0:
			_pic_finish.call_deferred(si)
		return
	var pr: Array = ev.get("pair", ["", ""])
	_pic_wrong(st, "%s 和 %s 不一樣，不能約。%s" % [pr[0], pr[1], String(st.nudge)])


func _custom_go() -> void:
	match _pic_kind():
		"ldrag":
			_ldrag_submit()
			return
		"ltap":
			if lt_found.size() >= steps[si].regions.size():
				_pic_finish(si)
			return
		"btap":
			if _nf().blocks_left(int(steps[si].get("item", 0))) == 0:
				_pic_finish(si)
			return
	super()


func _custom_reveal(msg: String) -> void:
	if _nf() != null:
		_nf().end()
	super(msg)


## 自動測試：把答案放好（之後測試會呼叫 _custom_go() 送出）
func test_answer(st: Dictionary) -> bool:
	match String(st.kind):
		"ltap":
			for k in st.regions.size():
				lt_found[k] = true
			return true
		"ldrag":
			for b in st.beads:
				_nf().drag_pos[String(b[0])] = float(st.goal[String(b[0])])
			return true
		"btap":
			var f := _nf()
			var it: Dictionary = f.items[int(st.get("item", 0))]
			var num: Array = f._rows(it.num, f._step())
			var den: Array = f._rows(it.den, f._step())
			var used := {}
			for a in num.size():
				for b in den.size():
					if not used.has(b) and String(num[a]) == String(den[b]):
						used[b] = true
						f.bcut.append([a, b])
						break
			return true
	return super(st)


# ================= 速算：填空或按鈕 =================

## 有 choices 的題目用大按鈕（數學排版），其他用數字鍵盤
func _speed_show() -> void:
	var pb: Dictionary = problems[sp_i]
	fview.speed_title = String(r.get("title", "速算"))
	fview.show_speed(pb.eq, sp_i, problems.size(), streak)
	step_label.text = UITheme.step_bar(_steps(), 0)
	if sp_i > 0:
		story_label.visible = false
	if not pb.has("choices"):
		_build_fill({"name": "速算", "q": pb.q, "template": pb.template, "answers": pb.answers, "mode": "ordered",
			"nudge": pb.nudge, "tag": pb.tag, "line": "", "paren": true})
		return
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = pb.q
	var row := GridContainer.new()
	row.columns = 2
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 10)
	rank_box.add_child(row)
	for i in pb.choices.size():
		var b := MathLabel.make_button(String(pb.choices[i]), 22, Vector2(0, 72))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
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



static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return absi(a)


static func _square(n: int) -> bool:
	var r := int(round(sqrt(float(n))))
	return r * r == n


static func _fr(n: int, d: int) -> String:
	return "\\frac{%d}{%d}" % [n, d]


# ================= 推導台：坐標方格＋原野 =================

class NumView extends PlaneView:
	var field: Control

	func setup(round: Dictionary) -> void:
		super(round)
		var fd: Array = round.get("field", [])
		if field == null:
			field = NumField.new()
			add_child(field)
		field.reset(fd, self)
		field.visible = not fd.is_empty() and kind == "forge"
		_place_plane()

	func _field_on() -> bool:
		return field != null and field.visible

	func _place_plane() -> void:
		super()
		if field != null:
			var rc := _plane_rect()
			field.position = rc.position
			field.size = rc.size

	func _plane_on() -> bool:
		return super() or _field_on()

	func _process(delta: float) -> void:
		super(delta)
		if _field_on() and (field.size != _plane_rect().size or field.position != _plane_rect().position):
			_place_plane()

