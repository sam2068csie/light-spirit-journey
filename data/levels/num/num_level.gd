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
##         點錯的區間有自己的說明就寫 "wrongs": [[lo, hi, "1 個負數"], …]（先找 wrongs，沒有才用 wrong）
##       {"kind": "btap", …, "item": 0}   點一塊分子積木、再點一樣的分母積木就約掉，約到沒有一樣的為止
##       {"kind": "mtap", …, "item": 0, "k": 3}   點風車的第 k 片扇葉（0 = 循環節的第一個數字），風車先停下來
##       {"kind": "lrange", …, "item": 0, "row": 燈條第幾排, "s": "x − y", "ans": [左, 右], "start": [左, 右], "snap": 1,
##        "demo": true（一隻手先示範）, "wrongs": [[左, 右, "常見錯誤的提示"], …]}
##         拉範圍（R3）：拖兩個把手到端點，按「確定」。錯的那一端閃紅，提示說太大還是太小
##       {"kind": "lsort", …, "item": 0, "why": {"種子": 放錯時的提示}}
##       {"kind": "rtap", …, "item": 0}   點長方形（R6）：rects 元件寫好哪一個是答案，點錯的標出長 + 寬
##         篩種子（R5）：把種子拖進兩個籃子（seeds 元件寫好每顆該放哪裡），按「確定」。放錯的退回種子袋
##       R7：
##       {"kind": "ctap", …, "item": 0}   點項的卡片（chips 元件）：點出每一對正負號相反的項，點錯的卡片搖一下
##       {"kind": "sqtap", …, "item": 0}  點兩塊麥田（sqs 元件）裡「拿掉的剛好是正方形」那一塊
##       {"kind": "gtap", …, "item": 0, "alts": [[要踩的階, …], …], "why": {"階": 點錯的提示}}
##         梯子點要踩的階：alts 裡任何一組都點到了就過（可以點的是 alts 裡出現的階，其他的算點錯）
##       天秤（scale 元件）：審判步驟時自動可以點數字卡（不扣分）
##       高一指數 E1：
##       {"kind": "pdrag", …, "item": 0, "nudge"}  光柱積木：把卡片拖到它的質數柱上（pillar 元件），全部放好就過；放錯的彈回來，提示寫卡片的 why
##       {"kind": "stack", …, "item": 0}  湊積木：點 +a、−a 的按鈕，湊到目標高度就過（不扣分，可以一直試）
##       {"kind": "etap", …, "item": 0}   點等號寶石（gems 元件）：點出第一顆錯的等號，點到沒問題的那顆寫出理由
##       choice 加 "guess": true：先猜，點哪一個都算（不扣分），line 裡的 {guess} 換成猜的那一個
##       slide 加 "line_vals": true：line 裡的 {…} 做完時換成滑桿的值（例如先猜的次數）
## 每一關只要寫 level_id、標題、章節、題庫、速算的題目產生器。

const NumField := preload("res://data/levels/num/num_field.gd")


func scene_theme() -> String:
	return "meadow"

func stage_style() -> Dictionary:
	return {"sky_top": Color("1d1a33"), "sky_bot": Color("0c0b18"), "scenery": "none", "ambient": ""}

## 數與式的填空大多用不到根號鍵（要根號的格子，根號會寫在式子裡）
func radicals_ok() -> bool:
	return false


## 排序題的按鈕打亂，不會剛好是答案的順序（數與式、指數的關卡都用這個底層）
func shuffle_order() -> bool:
	return true


## 每一題重新開始：上一題滑桿的值不要留下來（例如礦石的 t = 60 跑到賽跑去）
func _start_round() -> void:
	slide_vals = {}
	if fview != null and is_instance_valid(fview) and fview is PlaneView and (fview as PlaneView).plane != null:
		(fview as PlaneView).plane.dyn_vals = {}
	super()


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
		"ltap", "ldrag", "btap", "mtap", "lrange", "lsort", "rtap", "ctap", "sqtap", "gtap", "pdrag", "stack", "etap":
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
		"mtap":
			_nf().begin("sail", {"item": int(st.get("item", 0))}, _mtap_event)
		"rtap":
			_nf().begin("rect", {"item": int(st.get("item", 0))}, _rtap_event)
		"ctap":
			_nf().begin("chip", {"item": int(st.get("item", 0))}, _ctap_event)
		"sqtap":
			_nf().begin("sq", {"item": int(st.get("item", 0))}, _sqtap_event)
		"gtap":
			_nf().begin("rung", {"item": int(st.get("item", 0))}, _gtap_event)
		"pdrag":
			_nf().begin("pillar", {"item": int(st.get("item", 0))}, _pdrag_event)
		"stack":
			_nf().begin("stack", {"item": int(st.get("item", 0))}, _stack_event)
		"etap":
			_nf().begin("gem", {"item": int(st.get("item", 0))}, _etap_event)
		"choice":
			# 天秤（R7）：審判的時候數字卡可以隨便點
			var f := _nf()
			if f != null and f.visible:
				for k in f.items.size():
					if String(f.items[k].k) == "scale":
						f.begin("scale", {"item": k}, func(_e): pass)
		"lsort":
			_nf().begin("sort", {"item": int(st.get("item", 0))}, func(_e): pass)
			go_btn.visible = true
			go_btn.disabled = false
			go_btn.text = "確定"
		"lrange":
			_nf().begin("range", {"item": int(st.get("item", 0)), "row": st.get("row", 0), "s": st.get("s", ""),
				"start": st.start, "snap": float(st.get("snap", 1.0)), "demo": bool(st.get("demo", false))}, func(_e): pass)
			go_btn.visible = true
			go_btn.disabled = false
			go_btn.text = "確定"


## 坐標方格上點一個點（grid）：數與式少讀字，提示只寫一行（line_level 的版本有兩行說明）
func _refresh_grid() -> void:
	super()
	if grid_tip == null or not is_instance_valid(grid_tip) or si >= steps.size():
		return
	var pl: CoordPlane = _pv().plane
	grid_tip.text = "點好按「確定位置」" if not pl.has_pick() else "選了 %s" % CoordPlane.pt_text(pl.pick)


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


## 區間碰到數線的兩端：當作一直延伸出去（點在數線最邊邊也算在裡面）
func _lt_span(st: Dictionary, rg: Array) -> Array:
	var lo := float(rg[0])
	var hi := float(rg[1])
	var items: Array = _nf().items
	var k := int(st.get("item", 0))
	if k < items.size() and (items[k] as Dictionary).has("x"):
		var ax: Array = items[k].x
		if absf(lo - float(ax[0])) < 1e-6:
			lo = -1e9
		if absf(hi - float(ax[1])) < 1e-6:
			hi = 1e9
	return [lo, hi]


func _ltap_event(ev: Dictionary) -> void:
	if _pic_kind() != "ltap":
		return
	var st: Dictionary = steps[si]
	var v := float(ev.v)
	for k in st.regions.size():
		var rg: Array = _lt_span(st, st.regions[k])
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
	var txt := String(st.get("wrong", "")).replace("{rel}", rel)
	for w in st.get("wrongs", []):
		var wr := _lt_span(st, w)
		if v > float(wr[0]) + 1e-6 and v < float(wr[1]) - 1e-6:
			txt = String(w[2])
	_nf().mark(v, false, txt)
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


func _mtap_event(ev: Dictionary) -> void:
	if _pic_kind() != "mtap":
		return
	var st: Dictionary = steps[si]
	if int(ev.k) == int(st.k):
		_pic_finish.call_deferred(si)
		return
	_pic_wrong(st, "這一片是第 %d 個數字。%s" % [int(ev.k) + 1, String(st.nudge)])


var mtap_ok := false


func _ctap_event(ev: Dictionary) -> void:
	if _pic_kind() != "ctap":
		return
	var st: Dictionary = steps[si]
	var f := _nf()
	var it: Dictionary = f.items[int(st.get("item", 0))]
	var key: Array = f._geo[int(st.get("item", 0))].keys[int(ev.k)]
	var pairs: Array = it.pairs
	for pk in pairs.size():
		var pr: Array = pairs[pk]
		for e in [pr[0], pr[1]]:
			if int(e[0]) == int(key[0]) and int(e[1]) == int(key[1]):
				if bool(pr[2]):
					f.chip_found[pk] = true
					var left := 0
					for q in pairs:
						if bool(q[2]):
							left += 1
					if f.chip_found.size() >= left:
						_pic_finish.call_deferred(si)
					return
				f.chip_bad["%d_%d" % [int(key[0]), int(key[1])]] = f._t()
				_pic_wrong(st, String(pr[3]))
				return


func _sqtap_event(ev: Dictionary) -> void:
	if _pic_kind() != "sqtap":
		return
	var st: Dictionary = steps[si]
	var f := _nf()
	var it: Dictionary = f.items[int(st.get("item", 0))]
	if int(ev.k) == int(it.target):
		_pic_finish.call_deferred(si)
		return
	f.sq_bad[int(ev.k)] = f._t()
	var o: Dictionary = it.opts[int(ev.k)]
	_pic_wrong(st, "%d 格排不成正方形。%s" % [int(o.n), String(st.nudge)])


func _gtap_event(ev: Dictionary) -> void:
	if _pic_kind() != "gtap":
		return
	var st: Dictionary = steps[si]
	var f := _nf()
	var k := int(ev.k)
	var allowed := {}
	for alt in st.alts:
		for q in alt:
			allowed[int(q)] = true
	if allowed.has(k):
		f.rung_sel[k] = true
		if _gtap_done(st):
			_pic_finish.call_deferred(si)
		return
	f.rung_bad[k] = f._t()
	var it: Dictionary = f.items[int(st.get("item", 0))]
	var rg: Dictionary = it.rungs[k]
	if f._step() < int(rg.get("at", 0)):
		_pic_wrong(st, "這一階還沒爬到。" + String(st.nudge))
	else:
		_pic_wrong(st, String(st.get("why", {}).get(str(k), st.nudge)))


func _pdrag_event(ev: Dictionary) -> void:
	if _pic_kind() != "pdrag":
		return
	var st: Dictionary = steps[si]
	if bool(ev.ok):
		Game.of(self).play("blip", 1.0 + 0.08 * (8 - int(ev.left)), -8.0)
		if int(ev.left) == 0:
			_pic_finish.call_deferred(si)
		return
	var c: Dictionary = _nf().items[int(st.get("item", 0))].cards[int(ev.k)]
	_pic_wrong(st, String(c.get("why", st.nudge)))


func _stack_event(ev: Dictionary) -> void:
	if _pic_kind() != "stack":
		return
	var st: Dictionary = steps[si]
	var it: Dictionary = _nf().items[int(st.get("item", 0))]
	Game.of(self).play("blip", 1.0 + 0.3 * float(ev.h), -10.0)
	if absf(float(ev.h) - float(it.stack.goal)) < 1e-6:
		_pic_finish.call_deferred(si)


func _etap_event(ev: Dictionary) -> void:
	if _pic_kind() != "etap":
		return
	var st: Dictionary = steps[si]
	var f := _nf()
	var it: Dictionary = f.items[int(st.get("item", 0))]
	var k := int(ev.k)
	if k == int(it.bad):
		_pic_finish.call_deferred(si)
		return
	f.gem_ok[k] = f._t()
	f.gem_bad[k] = f._t()
	var why: Array = it.get("why", [])
	_pic_wrong(st, "這一顆沒問題：%s。%s" % [String(why[k]) if k < why.size() else "", String(st.nudge)])


## 先猜（choice 的 "guess": true）：點哪一個都算對，line 寫出猜的那一個
func _on_answer(idx: int) -> void:
	if predicting and r.get("type", "") == "forge" and si < steps.size() and bool(steps[si].get("guess", false)):
		cur_q["correct"] = idx
		var st: Dictionary = steps[si]
		if not st.has("line0"):
			st["line0"] = st.line
		st["line"] = String(st.line0).replace("{guess}", String(cur_q.options[idx]))
	super(idx)


## slide 做完：寫了 "line_vals": true 的，line 裡的 {…} 換成滑桿的值（例如「先猜：{g} 次」）
func _slide_done(st: Dictionary) -> void:
	if bool(st.get("line_vals", false)):
		if not st.has("line0"):
			st["line0"] = st.line
		st["line"] = CoordPlane.fill_eq(String(st.line0), slide_vals)
	super(st)


func _gtap_done(st: Dictionary) -> bool:
	for alt in st.alts:
		var all_in := true
		for q in alt:
			if not _nf().rung_sel.has(int(q)):
				all_in = false
		if all_in:
			return true
	return false


func _rtap_event(ev: Dictionary) -> void:
	if _pic_kind() != "rtap":
		return
	var st: Dictionary = steps[si]
	var it: Dictionary = _nf().items[int(st.get("item", 0))]
	if int(ev.k) == int(it.target):
		_pic_finish.call_deferred(si)
		return
	_nf().rect_mark(int(ev.k))
	var pr: Array = it.pairs[int(ev.k)]
	_pic_wrong(st, "%d + %d = %d。%s" % [int(pr[0]), int(pr[1]), int(pr[0]) + int(pr[1]), String(st.nudge)])


func _lsort_submit() -> void:
	var st: Dictionary = steps[si]
	var f := _nf()
	var res: Dictionary = f.drag_result()
	var empty := 0
	var bad := []
	for sd in f.items[int(st.get("item", 0))].seeds:
		var nm := String(sd[0])
		if res.get(nm) == null:
			empty += 1
		elif int(res[nm]) != int(sd[1]):
			bad.append(nm)
	if empty > 0:
		_hint("還有 %d 顆種子在袋子裡。" % empty, "info")
		return
	if bad.is_empty():
		_pic_finish(si)
		return
	f.drag_reject(bad)
	var why: Dictionary = st.get("why", {})
	_pic_wrong(st, "%s 放錯了。%s" % [bad[0], String(why.get(bad[0], st.nudge))])


func _lrange_submit() -> void:
	var st: Dictionary = steps[si]
	var res: Array = _nf().range_result()
	var lo := float(st.ans[0])
	var hi := float(st.ans[1])
	if is_equal_approx(res[0], lo) and is_equal_approx(res[1], hi):
		_pic_finish(si)
		return
	var msg := ""
	for w in st.get("wrongs", []):
		if is_equal_approx(res[0], float(w[0])) and is_equal_approx(res[1], float(w[1])):
			msg = String(w[2])
	var parts := []
	if not is_equal_approx(res[0], lo):
		_nf().range_flash(0)
		parts.append("左端太小" if res[0] < lo else "左端太大")
	if not is_equal_approx(res[1], hi):
		_nf().range_flash(1)
		parts.append("右端太大" if res[1] > hi else "右端太小")
	if msg == "":
		msg = "、".join(parts) + "。" + String(st.nudge)
	_pic_wrong(st, msg)


func _custom_go() -> void:
	match _pic_kind():
		"lrange":
			_lrange_submit()
			return
		"lsort":
			_lsort_submit()
			return
		"rtap", "sqtap":
			if mtap_ok:
				mtap_ok = false
				_pic_finish(si)
			return
		"ctap":
			var it: Dictionary = _nf().items[int(steps[si].get("item", 0))]
			var need := 0
			for q in it.pairs:
				if bool(q[2]):
					need += 1
			if _nf().chip_found.size() >= need:
				_pic_finish(si)
			return
		"gtap":
			if _gtap_done(steps[si]):
				_pic_finish(si)
			return
		"pdrag":
			var it: Dictionary = _nf().items[int(steps[si].get("item", 0))]
			var left := 0
			for q in it.cards.size():
				if not (it.cards[q] as Dictionary).has("at") and not _nf().pil_placed.has(q):
					left += 1
			if left == 0:
				_pic_finish(si)
			return
		"stack":
			var it: Dictionary = _nf().items[int(steps[si].get("item", 0))]
			if absf(_nf().stack_height(it) - float(it.stack.goal)) < 1e-6:
				_pic_finish(si)
			return
		"etap":
			if mtap_ok:
				mtap_ok = false
				_pic_finish(si)
			return
		"mtap":
			if mtap_ok:
				mtap_ok = false
				_pic_finish(si)
			return
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
		"mtap", "rtap", "sqtap", "etap":
			mtap_ok = true
			return true
		"pdrag":
			var it: Dictionary = _nf().items[int(st.get("item", 0))]
			for q in it.cards.size():
				if not (it.cards[q] as Dictionary).has("at"):
					_nf().pil_placed[q] = true
			return true
		"stack":
			var it: Dictionary = _nf().items[int(st.get("item", 0))]
			_nf().stk = (it.stack.sol as Dictionary).duplicate()
			return true
		"ctap":
			var it: Dictionary = _nf().items[int(st.get("item", 0))]
			for pk in it.pairs.size():
				if bool(it.pairs[pk][2]):
					_nf().chip_found[pk] = true
			return true
		"gtap":
			for q in st.alts[0]:
				_nf().rung_sel[int(q)] = true
			return true
		"lrange":
			_nf().rng = [float(st.ans[0]), float(st.ans[1])]
			return true
		"lsort":
			for sd in _nf().items[int(st.get("item", 0))].seeds:
				_nf().drag_pos[String(sd[0])] = int(sd[1])
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
		field_at = int(round.get("field_at", 0))
		field.visible = _field_want()
		_place_plane()

	## "field_at"：第幾步之後才出現原野（排序題的數線，排好之前空著沒有意義）
	var field_at := 0

	func _field_want() -> bool:
		return not rd.get("field", []).is_empty() and kind == "forge" and (done or step >= field_at)

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

	## 高一指數的圖上元件（拖卡片、湊積木、點寶石）要大張一點
	func _want_big() -> bool:
		var sts: Array = rd.get("steps", [])
		if not done and step < sts.size() and String(sts[step].get("kind", "")) in ["pdrag", "stack", "etap"]:
			return true
		# 十倍石階上點、分籃子：也大張（只限高一指數的圖上元件）
		if not done and step < sts.size() and String(sts[step].get("kind", "")) in ["ltap", "lsort"] and _big_field():
			return true
		return super()

	func _process(delta: float) -> void:
		super(delta)
		if field != null and field.visible != _field_want():
			field.visible = _field_want()
			_place_plane()
			queue_redraw()
		# 高一指數的圖上元件：拖、湊、點、滑桿的步驟原野大張一點（只有坐標方格時 PlaneView 自己會調）
		if _field_on() and (plane == null or not plane.visible) and _big_field():
			var want := PLANE_BIG if _want_big() else PLANE_SMALL
			if absf(ph - want) > 0.5:
				ph = lerpf(ph, want, 1.0 - exp(-10.0 * delta))
				if absf(ph - want) <= 0.5:
					ph = want
				queue_redraw()
		if _field_on() and (field.size != _plane_rect().size or field.position != _plane_rect().position):
			_place_plane()

	func _big_field() -> bool:
		for it in rd.get("field", []):
			if String(it.get("k", "")) in ["pillar", "gems", "fold", "glow", "race", "rule", "meter", "digits", "rope"] \
					or bool(it.get("stair", false)) or bool(it.get("logticks", false)) or bool(it.get("big", false)):
				return true
		return false

