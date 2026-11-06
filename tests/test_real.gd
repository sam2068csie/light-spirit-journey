extends "res://tests/test_base.gd"
## 真的「玩」一關（直線與圓的推導關卡）：從大地圖點進去，一路點畫面上的按鈕過完整關
##   ・所有操作都是滑鼠事件（root.push_input）：點選項、點數字鍵、點格子點、按滑桿兩邊的 ‹ ›、點排序的項目……
##     按鈕被別的東西蓋住、點不到，就會卡住並回報
##   ・每一題的第一步先故意答錯一次，看答錯的回饋
##   ・每個畫面都截圖（SHOTS），之後一張一張看
## 用法：ONLY=C2 SHOTS=/tmp/r xvfb-run -a tests/run_tests.sh real

const Units := preload("res://data/core/units.gd")

var lid := "C2"
var n_shot := 0
var issues := []
var lv
var stop := false


func _issue(msg: String) -> void:
	issues.append(msg)
	print("  ✗ " + msg)


func snap(tag: String) -> void:
	n_shot += 1
	await shot("%03d_%s" % [n_shot, tag.replace("/", "_")])


# ---------------- 滑鼠 ----------------

func _send_mouse(p: Vector2, down: bool, mask := MOUSE_BUTTON_MASK_LEFT) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.button_mask = mask if down else 0
	e.position = p
	e.global_position = p
	root.push_input(e)


func _move(p: Vector2, held := false) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(e)


func click_at(p: Vector2) -> void:
	_move(p)
	await frames(1)
	_send_mouse(p, true)
	await frames(1)
	_send_mouse(p, false)
	await frames(3)


## 點一個按鈕：點它的正中間。點下去之後按鈕沒有反應（被蓋住），就回報
func click(b: Control, what := "") -> bool:
	if b == null or not is_instance_valid(b) or not b.is_visible_in_tree():
		_issue("%s：找不到「%s」" % [_where(), what])
		return false
	if b is BaseButton and (b as BaseButton).disabled:
		_issue("%s：「%s」不能按" % [_where(), what])
		return false
	var hit := [false]
	var cb := func(): hit[0] = true
	if b is BaseButton:
		(b as BaseButton).pressed.connect(cb, CONNECT_ONE_SHOT)
	await click_at(b.get_global_rect().get_center())
	if not hit[0] and is_instance_valid(b) and b is BaseButton:
		if true:
			if (b as BaseButton).pressed.is_connected(cb):
				(b as BaseButton).pressed.disconnect(cb)
			_issue("%s：點「%s」沒有反應（可能被蓋住）" % [_where(), what])
			await snap("blocked")
			return false
	return true


func _where() -> String:
	if lv != null and is_instance_valid(lv) and lv.get("r") != null and lv.r is Dictionary and lv.r.has("id"):
		return "%s/%s 第 %d 步" % [lid, String(lv.r.id), int(lv.si) + 1]
	return lid


# ---------------- 找按鈕 ----------------

func _label_of(b: Node) -> String:
	var s := String(b.get("text")) if b is Button else ""
	for c in b.get_children():
		if c is Button:
			continue
		if c is Label or (c.get("text") != null and c.has_method("_get_minimum_size") and not c is Button):
			s += " " + String(c.text)
		s += _label_of_kids(c)
	return s


func _label_of_kids(n: Node) -> String:
	var s := ""
	for c in n.get_children():
		if c is Button:
			continue
		if c.get("text") != null and c is Control:
			s += " " + String(c.text)
		s += _label_of_kids(c)
	return s


func find_btn(root_n: Node, pred: Callable) -> Button:
	if root_n is Button and root_n.is_visible_in_tree() and pred.call(root_n):
		return root_n
	for c in root_n.get_children():
		var b := find_btn(c, pred)
		if b != null:
			return b
	return null


func btn_text(root_n: Node, txt: String) -> Button:
	return find_btn(root_n, func(b): return String(b.text).strip_edges().begins_with(txt) if String(b.text) != "" else _label_of(b).strip_edges().begins_with(txt))


# ---------------- 作答 ----------------

## 數字鍵盤輸入一個答案（"−3/2"、"2√13"）
func type_answer(s: String) -> void:
	s = s.replace("-", "−")
	for ch in s:
		var key := btn_text(lv.rank_box, ch)
		if key == null:
			_issue("%s：鍵盤上找不到「%s」" % [_where(), ch])
			return
		await click(key, "鍵盤 " + ch)


func fill_all(vals: Array) -> void:
	for i in vals.size():
		if lv.slot_btns.size() > 1 and i < lv.slot_btns.size():
			await click(lv.slot_btns[i], "第 %d 格" % (i + 1))
		# 清掉原本的內容（上一次答錯留下來的）
		var gk := 0
		while String(lv.slot_vals[i]) != "" and gk < 12:
			gk += 1
			var bk := btn_text(lv.rank_box, "⌫")
			if bk == null:
				break
			await click(bk, "⌫")
		await type_answer(String(vals[i]))


func submit_fill() -> void:
	await click(btn_text(lv.rank_box, "送出"), "送出")


func go() -> void:
	await click(lv.go_btn, String(lv.go_btn.text))


## 坐標方格上點一個格子點
func click_plane(p: Vector2) -> void:
	var pl = lv._pv().plane
	var sp: Vector2 = pl.get_global_transform() * pl._to(p)
	await click_at(sp)


## 滑桿：按 ‹ › 調到目標值
func slide_to(name: String, v: float) -> void:
	for row in lv.rank_box.get_children():
		if not row is HBoxContainer:
			continue
		var s: HSlider = null
		for c in row.get_children():
			if c is HSlider:
				s = c
		if s == null:
			continue
		var nl = row.get_child(0)
		if String(nl.text) != name:
			continue
		var guard := 0
		while absf(s.value - v) > 1e-6 and guard < 40:
			guard += 1
			var dir := "›" if v > s.value else "‹"
			var b := find_btn(row, func(x): return x.text == dir)
			if b == null or b.disabled:
				_issue("%s：滑桿 %s 的 %s 按不了" % [_where(), name, dir])
				return
			# ‹ › 是按下去就調一格（調到底之後按鈕馬上變成不能按，所以不看 pressed）
			var v0 := s.value
			await click_at(b.get_global_rect().get_center())
			if is_equal_approx(s.value, v0):
				_issue("%s：按滑桿 %s 的 %s 沒有反應" % [_where(), name, dir])
				await snap("blocked")
				return
		if absf(s.value - v) > 1e-6:
			_issue("%s：滑桿 %s 調不到 %s（停在 %s）" % [_where(), name, v, s.value])
		return
	_issue("%s：找不到滑桿 %s" % [_where(), name])


func answer_step(st: Dictionary, wrong: bool) -> void:
	match String(st.kind):
		"choice":
			var grid: Node = lv.predict_box.get_child(1)
			var idx: int = int(lv.cur_q.correct)
			if wrong:
				idx = (idx + 1) % grid.get_child_count()
			await click(grid.get_child(idx), "選項")
		"fill":
			var vals: Array = Array(st.answers).duplicate()
			if wrong:
				vals[0] = _bump(String(vals[0]))
			await fill_all(vals)
			await snap(String(lv.r.id) + "_填好")
			await submit_fill()
		"grid":
			var p := Vector2(float(st.target[0]), float(st.target[1]))
			if wrong:
				p += Vector2(1, 0)
			await click_plane(p)
			await go()
		"slide":
			if st.get("free", false):
				if not wrong:
					var p0: Dictionary = st.params[0]
					var tv := float(p0.v) + float(p0.step) * 2.0
					if tv > float(p0.max) - 1e-6:
						tv = float(p0.v) - float(p0.step) * 2.0
					await slide_to(String(p0.n), tv)
			else:
				for k in st.goal.keys():
					var v := float(st.goal[k])
					if wrong:
						for p in st.params:
							if String(p.n) == k:
								v += float(p.step) * (1.0 if v + float(p.step) <= float(p.max) else -1.0)
						wrong = false
					await slide_to(k, v)
			await snap(String(lv.r.id) + "_調好")
			await go()
		"order":
			var idx: Array = range(st.items.size())
			idx.sort_custom(func(a, b): return float(st.items[a].v) < float(st.items[b].v))
			if wrong:
				idx.reverse()
			for i in idx:
				var it: Dictionary = st.items[i]
				var b := find_btn(lv.rank_box, func(x): return not x.disabled and _label_of(x).contains(String(it.text)) and not _label_of(x).contains("<"))
				await click(b, "排序 " + String(it.text))
			await go()
		"filter":
			for i in st.keep.size():
				if not st.keep[i] and not wrong:
					await click(lv.filter_btns[i], "篩選 %d" % i)
			await go()
		_:
			_issue("%s：不認得的步驟 %s" % [_where(), st.kind])


func _bump(s: String) -> String:
	var q: Array = lv.parse_q(s.replace("−", "-"))
	if q.is_empty():
		return "7"
	return str(int(q[0] / q[1]) + 1) if q[1] == 1 else str(q[0] + 1) + "/" + str(q[1])


# ---------------- 一關 ----------------

func _initialize() -> void:
	await setup()
	lid = OS.get_environment("ONLY") if OS.get_environment("ONLY") != "" else "C2"
	g.power_save = false
	g.dev_unlock_all = true
	g.tut = {"basic": true}
	g.grade_pick = "高一"
	var unit := ""
	for u in Units.UNITS:
		for l in u.levels:
			if String(l.id) == lid:
				unit = String(u.id)
	g.cur_unit = unit
	for k in g.cleared.keys():
		if String(k).begins_with(lid + "/"):
			g.cleared.erase(k)
	for k in g.stars.keys():
		if String(k).begins_with(lid):
			g.stars.erase(k)
	for k in g.main_rw.chests.keys():
		if String(k).contains(lid):
			g.main_rw.chests.erase(k)
	# 1. 大地圖：點兩下聖地進去
	g.goto("main_menu.gd")
	await wait(1.0)
	var mm = current_scene
	mm._grade = "高一"
	mm._show_page("levels")
	await wait(1.2)
	# 劇情（序章、其他關點亮的劇情）：一直按「略過」到沒有為止
	for k in 8:
		var skip := btn_text(current_scene, "略過")
		if skip == null:
			break
		await click(skip, "略過")
		await wait(1.2)
	var map = mm._map
	var si := -1
	for i in map.m_sites.size():
		if String(map.m_sites[i].id) == lid:
			si = i
	var sp: Vector2 = (map._site_p(si) + Vector2(0, -24) - map.cam) * map.zoom + map.SCREEN_C
	await click_at(sp)
	await wait(0.6)
	await snap("map_selected")
	await click_at(sp)
	await wait(1.2)
	lv = current_scene
	if lv == null or not lv.has_method("make_round"):
		_issue("從地圖點不進 %s" % lid)
		finish_real()
		return
	await snap("level_open")
	# 2. 像學生一樣：看畫面上有什麼就按什麼，直到這一關每一題、每一種題型都玩過
	var guard := 0
	var rounds := 0
	while guard < 300:
		guard += 1
		await wait(0.3)
		if lv.get("intro_block") != null:
			continue
		if await _tutorial():
			continue
		if await _round_active():
			await _play_round()
			rounds += 1
			if stop:
				break
			continue
		var b: Button = await _pick_button()
		if b == null:
			await snap("nothing")
			_issue("不知道下一步要按什麼（玩了 %d 題）" % rounds)
			break
		var t := _label_of(b).strip_edges()
		if t.contains("返回關卡列表"):
			break
		await snap("menu")
		await click(b, t.left(20))
		await wait(0.8)
	print("  玩了 %d 題" % rounds)
	finish_real()


func _round_active() -> bool:
	if lv.get("r") == null or not (lv.r is Dictionary) or not lv.r.has("type"):
		return false
	var on := false
	if String(lv.r.type) == "speed":
		on = lv.keypad_on
	elif String(lv.r.type) == "forge":
		on = lv.si < lv.steps.size()
	if not on or not lv.side_card.is_visible_in_tree():
		return false
	# 作答區沒有被別的視窗蓋住
	_move(lv.step_label.get_global_rect().get_center())
	await frames(1)
	var c = root.gui_get_hovered_control()
	return c != null and lv.side_card.is_ancestor_of(c) or c == lv.side_card


## 教學的「下一步」：一直按到教學結束
func _tutorial() -> bool:
	var b := find_btn(current_scene, func(x): return not x.disabled and String(x.text).begins_with("下一步"))
	if b == null:
		b = find_btn(current_scene, func(x): return not x.disabled and String(x.text).begins_with("開始吧"))
	if b == null:
		return false
	await snap("tutorial")
	await click(b, String(b.text))
	await wait(0.5)
	return true


## 不在作答時，畫面上該按的按鈕（照優先順序）
func _pick_button() -> Button:
	var all := []
	_collect(current_scene, all)
	var pri := ["打開", "收下", "領取", "再玩一次", "下一題", "看結果", "▶", "繼續", "知道了", "開始"]
	# 結算畫面：還有沒玩過的題型就「再玩一次」，否則「下一題」
	var more := false
	for n in current_scene.find_children("*", "Label", true, false):
		if n.is_visible_in_tree() and String(n.text).contains("等你挑戰"):
			more = true
	for p in pri:
		if p == "再玩一次" and not more:
			continue
		for b in all:
			var t := _label_of(b)
			if t.contains(p) and not t.contains("觀念整理") and await _on_top(b):
				return b
	# 旅程列表：還沒過的題目／章節
	for b in all:
		var t := _label_of(b)
		if t.contains("%") and not t.contains("100%") and not t.contains("寶箱") and await _on_top(b):
			return b
	for b in all:
		if _label_of(b).contains("返回章節") and await _on_top(b):
			return b
	for b in all:
		if _label_of(b).contains("返回關卡列表") and await _on_top(b):
			return b
	return null


func _collect(n: Node, out: Array) -> void:
	if n is Button and n.is_visible_in_tree() and not (n as Button).disabled:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)


## 這個按鈕在最上層嗎（中間沒有被別的視窗擋住）：把滑鼠移過去，看滑鼠停在誰身上
func _on_top(b: Control) -> bool:
	_move(b.get_global_rect().get_center())
	await frames(1)
	var c = root.gui_get_hovered_control()
	return c != null and (c == b or b.is_ancestor_of(c))


func finish_real() -> void:
	ok(issues.is_empty(), "真的玩過一遍沒有問題（%d 個）" % issues.size())
	finish("REAL")


func _play_round() -> void:
	var rid := String(lv.r.get("id", "?"))
	# 開場題目一個字一個字浮現：等它跑完（學生也是讀完題目才作答）
	var gw := 0
	while lv.get("intro_block") != null and gw < 40:
		gw += 1
		await wait(0.2)
	await wait(0.6)
	await snap(rid + "_start")
	if String(lv.r.type) == "speed":
		await _play_speed()
	else:
		var guard := 0
		var first := true
		while lv.si < lv.steps.size() and guard < 40:
			guard += 1
			while await _tutorial():
				pass
			var si0: int = lv.si
			var st: Dictionary = lv.steps[si0]
			await snap("%s_%d_%s" % [rid, si0, st.name])
			if first:
				await answer_step(st, true)
				await snap("%s_%d_答錯" % [rid, si0])
				first = false
				if lv.si != si0:
					_issue("%s：故意答錯卻過了" % _where())
					continue
			await answer_step(st, false)
			await wait(0.3)
			if lv.si == si0:
				await snap("%s_%d_stuck" % [rid, si0])
				_issue("%s：答對了卻沒有進到下一步（%s）提示：%s" % [_where(), st.kind, _hint()])
				stop = true
				return
	await wait(0.6)
	await snap(rid + "_done")


func _hint() -> String:
	return String(lv.hint_label.text).left(80) if lv.hint_panel.visible else ""


func _play_speed() -> void:
	var guard := 0
	var first := true
	while String(lv.r.type) == "speed" and lv.keypad_on and guard < 30:
		guard += 1
		while await _tutorial():
			pass
		var pb: Dictionary = lv.problems[lv.sp_i]
		var i0: int = lv.sp_i
		var ans: Array = Array(pb.get("answers", [pb.get("ans", "")]))
		if first:
			var bad := ans.duplicate()
			bad[0] = _bump(String(bad[0]))
			await fill_all(bad)
			await submit_fill()
			await snap(String(lv.r.id) + "_答錯")
			first = false
		await fill_all(ans)
		await submit_fill()
		await wait(0.5)
		if lv.sp_i == i0 and lv.keypad_on:
			_issue("%s：速算答對沒有換題（%s = %s）" % [_where(), pb.eq, ans])
			return
	await snap(String(lv.r.id) + "_speed_end")

