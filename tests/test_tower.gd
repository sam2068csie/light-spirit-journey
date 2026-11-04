extends "test_play.gd"
## 終焉之塔：真的爬一次
##   items：段考風格的每一題都一次答對（點選項、按真／假、劃掉根、點數線），每一步檢查版面，最後一定要三顆星
##   wrong：每一步先答錯一次再答對（看提示有沒有擠出畫面、心有沒有正確扣）
##   lose ：三顆心用完、時間到，都要示範完整解法並出現「看攀登結果」
##   run  ：從第 1 層爬到塔頂（舊題型也照正確答案玩），檢查樓層、心、試煉層、結算畫面
## 環境變數 TMODE=items,wrong 只跑某幾種；ONLY=j_rules,b_drug 只玩某幾題；SHOTS=資料夾 存截圖

const Bank := preload("res://data/levels/tower/tower_bank.gd")
const Center := preload("res://data/core/review_center.gd")
const VP := Vector2(1152, 648)

var _all_shots := false


func _initialize() -> void:
	await setup()
	g.cur_unit = "exp"
	_all_shots = OS.get_environment("ALLSHOTS") != ""
	var modes := OS.get_environment("TMODE")
	if modes == "":
		modes = "items,wrong,lose,run"
	var only := OS.get_environment("ONLY")
	for it in Bank.items():
		if only != "" and not (String(it.id) in only.split(",")):
			continue
		if "items" in modes:
			await _play_item(String(it.id), false)
		if "wrong" in modes:
			await _play_item(String(it.id), true)
	if "lose" in modes:
		await _lose_cases()
	if "run" in modes:
		await _climb()
	ok(issues == 0, "終焉之塔沒有發現問題（%d 個）" % issues)
	finish("TOWER")


# ================= 一題一題玩 =================

func _open(id: String, hearts := 3, time := 900.0):
	g.session = {}          # 不是真的在攀登：按「前往下一層」不會跳走
	g.goto("boss_tower.gd", {"review": {"level": "T", "slot": id}, "tower_floor": 7, "tower_hearts": hearts, "tower_time": time})
	await wait(0.9)
	var bt = current_scene
	if bt == null or bt.get("steps") == null or String(bt.item.get("id", "")) != id:
		_issue("%s 開不起來" % id)
		return null
	return bt


func _play_item(id: String, wrong: bool) -> void:
	cur_tag = id + ("（先答錯）" if wrong else "")
	var bt = await _open(id)
	if bt == null:
		return
	if wrong:
		bt.hearts = 99
	var guard := 0
	while not bt.done and guard < 40:
		guard += 1
		var si0: int = bt.si
		var st: Dictionary = bt.steps[si0]
		var nm := "%02d%s" % [si0, String(st.t)]
		await _bcheck(bt, nm + " 作答前")
		if _all_shots and not wrong:
			await shot("%s_%s" % [id, nm])
		if wrong:
			await _answer_wrong(bt, st)
			await _bcheck(bt, nm + " 答錯之後")
			if _all_shots:
				await shot("%s_%s_wrong" % [id, nm])
			if bt.waiting:
				bt.action_btn.pressed.emit()
				await frames(3)
				continue
		await _answer(bt, st)
		await _wait_step(bt, si0)
		if bt.waiting:
			await _bcheck(bt, nm + " 看理由")
			if _all_shots and not wrong:
				await shot("%s_%s_why" % [id, nm])
			bt.action_btn.pressed.emit()
			await frames(3)
		if bt.si == si0 and not bt.done:
			_issue("%s：照正確答案作答卻沒有前進" % nm)
			await shot("%s_stuck_%02d" % [id, si0])
			return
	await frames(3)
	await _bcheck(bt, "完成")
	if _all_shots and not wrong:
		await shot("%s_zz_done" % id)
	if not bt.done or not bt.next_btn.visible:
		_issue("全部作答完卻沒有結束這一層")
	elif not wrong and int(bt._stars) != 3:
		_issue("全部一次答對，卻只拿到 %d 星" % int(bt._stars))
	elif not wrong and int(bt.hearts) != 3:
		_issue("全部一次答對，心卻變成 %d" % int(bt.hearts))


func _wait_step(bt, si0: int) -> void:
	var t0 := Time.get_ticks_msec()
	while bt.si == si0 and not bt.done and not bt.waiting and Time.get_ticks_msec() - t0 < 3000:
		await frames(1)
	await frames(2)


## 照正確答案作答（和學生一樣按按鈕）
func _answer(bt, st: Dictionary) -> void:
	match String(st.t):
		"choice":
			var b := _choice_btn(bt, String(st.opts[0]))
			if b == null:
				_issue("選項裡找不到正確答案 %s" % String(st.opts[0]))
				return
			b.pressed.emit()
		"judge":
			for jr in bt.judge_rows:
				var bi := 0 if bool(jr.card.ok) else 1
				jr.btns[bi].button_pressed = true
				jr.btns[bi].pressed.emit()
			await frames(2)
			if bt.action_btn.disabled:
				_issue("每張卡片都選了，「送出審判」還是不能按（%s）" % bt.action_btn.text)
			await _bcheck(bt, "%02d 卡片都選好" % bt.si)
			bt.action_btn.pressed.emit()
		"roots":
			for tok in bt.root_tokens:
				if not bool(tok.cand.ok):
					tok.btn.pressed.emit()
			await frames(2)
			bt.action_btn.pressed.emit()
		"line":
			await _set_line(bt, st.seg, st.pt)
			await _bcheck(bt, "%02d 數線點好" % bt.si)
			bt.action_btn.pressed.emit()


## 故意答錯一次
func _answer_wrong(bt, st: Dictionary) -> void:
	var h0: int = bt.hearts
	match String(st.t):
		"choice":
			var b := _choice_btn(bt, String(st.opts[1]))
			if b == null:
				_issue("選項裡找不到 %s" % String(st.opts[1]))
				return
			b.pressed.emit()
			await frames(2)
			if bt.hearts != h0 - 1:
				_issue("答錯選擇題卻沒有扣心")
			if not bt.hint_panel.visible:
				_issue("答錯選擇題卻沒有提示")
		"judge":
			for jr in bt.judge_rows:
				var bi := 1 if bool(jr.card.ok) else 0
				jr.btns[bi].button_pressed = true
				jr.btns[bi].pressed.emit()
			await frames(2)
			bt.action_btn.pressed.emit()
			await frames(2)
			if bt.hearts != h0 - 1:
				_issue("真假全部判錯卻沒有扣心")
		"roots":
			for tok in bt.root_tokens:
				if bool(tok.cand.ok):
					tok.btn.pressed.emit()
			await frames(2)
			bt.action_btn.pressed.emit()
			await frames(2)
			if bt.hearts != h0 - 1:
				_issue("驗根判錯卻沒有扣心")
		"line":
			var seg: Array = st.seg.map(func(v): return 1 - int(v))
			await _set_line(bt, seg, st.pt)
			bt.action_btn.pressed.emit()
			await frames(2)
			if bt.hearts != h0 - 1:
				_issue("數線封印錯了卻沒有扣心")


func _choice_btn(bt, markup: String) -> Button:
	for b in bt.opts_box.get_children():
		var m = b.get_node_or_null("Math")
		if m != null and String(m.text) == markup and not b.disabled:
			return b
	return null


## 在數線上點：先點區段、再點端點，讓最後一列變成 seg、pt
func _set_line(bt, seg: Array, pt: Array) -> void:
	var nl = bt.numline
	await frames(2)
	var r: Dictionary = nl.rows.back()
	var xs: Array = nl._xs()
	var y: float = nl._row_y(nl.rows.size() - 1)
	for i in seg.size():
		if int(r.seg[i]) != int(seg[i]):
			var sp: Vector2 = nl._seg_span(i, xs)
			var x := (sp.x + sp.y) / 2.0
			if absf(sp.y - sp.x) < 50.0:
				_issue("數線第 %d 段太窄（%d px），手指不好點" % [i + 1, int(sp.y - sp.x)])
			_click(nl, Vector2(x, y))
			if int(r.seg[i]) != int(seg[i]):
				_issue("點數線第 %d 段的正中間，卻沒有選到" % [i + 1])
	for i in pt.size():
		if int(r.pt[i]) != int(pt[i]):
			_click(nl, Vector2(xs[i], y))
			if int(r.pt[i]) != int(pt[i]):
				_issue("點數線的端點 %s，卻沒有切換" % String(nl.marks[i]))
	await frames(1)


# ================= 版面 =================

func _card_of(bt) -> Control:
	for c in bt.get_children():
		if c is PanelContainer and c != bt.stage_panel:
			return c
	return null


func _bcheck(bt, when: String) -> void:
	await frames(2)
	var card := _card_of(bt)
	var cr := card.get_global_rect()
	if cr.end.y > VP.y + 1.0 or cr.end.x > VP.x + 1.0:
		_issue("%s：右邊作答區超出畫面（%d×%d，下緣 %d）" % [when, int(cr.size.x), int(cr.size.y), int(cr.end.y)])
		await shot("%s_%s" % [cur_tag, when])
	await _check_node(card, cr, when)
	var sr: Rect2 = bt.stage_panel.get_global_rect()
	if sr.size.x > bt.STAGE_W + 1.0 or sr.size.y > bt.STAGE_H + 1.0:
		_issue("%s：左邊題目板被撐大了（%d×%d）" % [when, int(sr.size.x), int(sr.size.y)])
		await shot("%s_%s" % [cur_tag, when])
	await _check_node(bt.stage_panel, sr, when)
	# 要操作的東西（卡片、候選根、數線）必須一開始就看得到，不用捲動
	var sc: ScrollContainer = bt.board_scroll
	var vis := sc.get_global_rect()
	if vis.size.y < 120.0:
		_issue("%s：推導板只剩 %d px 高（題目太長？）" % [when, int(vis.size.y)])
	if when.ends_with("作答前") and bt.widget_box.get_child_count() > 0 and not bt.waiting and not bt.done:
		await wait(0.4)      # 等自動捲動跑完
		var wr: Rect2 = bt.widget_box.get_global_rect()
		if wr.size.y > 2.0 and wr.end.y > vis.end.y + 2.0 and int(bt.board_scroll.scroll_vertical) + vis.size.y < bt.board_scroll.get_v_scroll_bar().max_value - 2.0:
			_issue("%s：操作區有 %d px 在推導板下面看不到" % [when, int(wr.end.y - vis.end.y)])
	# 數線的標籤不能互相重疊
	if bt.numline and bt.numline.is_visible_in_tree():
		var xs: Array = bt.numline._xs()
		for i in range(1, xs.size()):
			if float(xs[i]) - float(xs[i - 1]) < 56.0:
				_issue("%s：數線上 %s 和 %s 擠在一起" % [when, bt.numline.marks[i - 1], bt.numline.marks[i]])


# ================= 失敗 =================

func _lose_cases() -> void:
	# 1. 只剩一顆心時答錯：示範解法、看攀登結果
	for id in ["r_logsum", "j_rules", "l_twolog", "b_ineq"]:
		cur_tag = id + "（心用完）"
		var bt = await _open(id, 1)
		if bt == null:
			continue
		await _answer_wrong(bt, bt.steps[0])
		await frames(4)
		if not bt.done:
			_issue("心用完了卻沒有結束")
		elif bt.next_btn.text.find("攀登結果") < 0:
			_issue("心用完後按鈕是「%s」" % bt.next_btn.text)
		if bt.board.get_child_count() < bt.steps.size() - 1:
			_issue("心用完後，推導板只寫了 %d 行" % bt.board.get_child_count())
		await _bcheck(bt, "心用完")
		await shot("lose_" + id)
	# 2. 時間到
	for id in ["e_closed", "q_bact"]:
		cur_tag = id + "（時間到）"
		var bt = await _open(id, 3, 2.0)
		if bt == null:
			continue
		await wait(2.6)
		if not bt.done or bt.hearts != 2:
			_issue("時間到：done=%s、心=%d" % [str(bt.done), int(bt.hearts)])
		elif bt.next_btn.text.find("第 8 層") < 0:
			_issue("時間到但還有心，按鈕卻是「%s」" % bt.next_btn.text)
		await _bcheck(bt, "時間到")
		await shot("timeout_" + id)
	# 3. 審判錯一張不扣心、錯兩張扣一顆
	cur_tag = "j_value（錯一張）"
	var bj = await _open("j_value")
	if bj != null:
		for k in bj.judge_rows.size():
			var jr: Dictionary = bj.judge_rows[k]
			var bi := 0 if (bool(jr.card.ok) != (k == 0)) else 1
			jr.btns[bi].button_pressed = true
			jr.btns[bi].pressed.emit()
		bj.action_btn.pressed.emit()
		await frames(3)
		if bj.hearts != 3:
			_issue("錯一張卻扣了心")
		await _bcheck(bj, "錯一張")
		await shot("judge_one_wrong")
		bj.action_btn.pressed.emit()
		await frames(3)
		if not bj.done or int(bj._stars) != 2:
			_issue("錯一張之後應該通過且 2 星（done=%s、星=%d）" % [str(bj.done), int(bj._stars)])


# ================= 從第 1 層爬到塔頂 =================

func _climb() -> void:
	var top := Center.tower_top()
	cur_tag = "攀登"
	g.tower_best = 0
	g.start_tower()
	await wait(1.0)
	var seen := {}
	var last_floor := 0
	var guard := 0
	while guard < top * 3 + 10:
		guard += 1
		var sc = current_scene
		var file := String(sc.get_script().resource_path).get_file()
		if file == "main_menu.gd":
			break
		if file == "tower_climb.gd":
			if int(sc.to_floor) != last_floor + 1:
				_issue("爬塔動畫從 %d 到 %d，但剛過第 %d 層" % [int(sc.from_floor), int(sc.to_floor), last_floor])
			sc._go()
			await wait(1.0)
			continue
		var f := int(g.session.get("floor", 0))
		var it: Dictionary = g.session.cur
		var key := String(it.level) + "/" + String(it.slot)
		cur_tag = "第 %d 層 %s" % [f, key]
		if f % 5 == 0 and String(it.get("type", "")) != "boss":
			_issue("第 %d 層應該是試煉大題，卻出了 %s" % [f, str(it.get("type", ""))])
		if f % 5 != 0 and String(it.get("type", "")) == "boss":
			_issue("第 %d 層不是試煉層，卻出了試煉大題" % f)
		if seen.has(key) and String(it.level) == "T":
			_issue("同一輪攀登裡重複出了 %s（第 %d 層和第 %d 層）" % [key, int(seen[key]), f])
		seen[key] = f
		if file == "boss_tower.gd":
			if String(sc.item.id) != String(it.slot):
				_issue("塔要出 %s，畫面上卻是 %s" % [it.slot, sc.item.id])
			if int(Center.tower_max_tier(f)) < int(sc.item.tier) and String(sc.item.kind) != "boss":
				_issue("第 %d 層出了難度 %d 的題目" % [f, int(sc.item.tier)])
			if sc.floor_label.text != "第 %d 層" % f:
				_issue("樓層顯示「%s」" % sc.floor_label.text)
			await _play_bt_quick(sc)
			if f == 1:
				await shot("climb_floor1")
		else:
			await _play_old(sc, it)
		last_floor = f
		var nb: Button = sc.next_btn
		var want := "看攀登結果" if f >= top else "前往第 %d 層" % (f + 1)
		if f < top and nb.text.find(want) < 0:
			_issue("按鈕是「%s」，應該是「%s」" % [nb.text, want])
		nb.pressed.emit()
		await wait(1.0)
	var mm = current_scene
	if String(mm.get_script().resource_path).get_file() != "main_menu.gd":
		_issue("爬完 %d 層還沒回到結算畫面" % last_floor)
		return
	if last_floor != top:
		_issue("只爬到第 %d 層就結束了（塔頂 %d）" % [last_floor, top])
	if g.tower_best != top:
		_issue("最高紀錄是 %d，應該是 %d" % [g.tower_best, top])
	await wait(1.2)
	await shot("climb_result")
	# 心會一層一層帶上去：第 1 層答錯一次，第 2 層開始只剩兩顆
	cur_tag = "帶心"
	g.start_tower()
	await wait(1.0)
	var b1 = current_scene
	if String(b1.get_script().resource_path).get_file() == "boss_tower.gd":
		await _answer_wrong(b1, b1.steps[b1.si])
		await frames(2)
		if b1.waiting:
			b1.action_btn.pressed.emit()
		await _play_bt_quick(b1)
		b1.next_btn.pressed.emit()
		await wait(1.0)
		current_scene._go()
		await wait(1.0)
		var s2 = current_scene
		var h2 = s2.get("hearts") if s2.get("hearts") != null else s2.get("energy")
		if int(h2) != 2:
			_issue("第 1 層扣了一顆心，第 2 層卻有 %d 顆" % int(h2))
		await shot("climb_floor2_hearts")
		s2.pause_menu.list_action.call()
		await wait(1.0)
		if String(current_scene.get_script().resource_path).get_file() != "main_menu.gd":
			_issue("放棄攀登沒有回到結算畫面")
		else:
			await wait(1.0)
			await shot("climb_abort_result")


func _play_bt_quick(bt) -> void:
	var guard := 0
	while not bt.done and guard < 40:
		guard += 1
		var si0: int = bt.si
		await _answer(bt, bt.steps[si0])
		await _wait_step(bt, si0)
		if bt.waiting:
			bt.action_btn.pressed.emit()
			await frames(3)
	if not bt.done:
		_issue("沒有玩完")


## 八大關的舊題型（塔裡的版本）：照正確答案玩，確認是三顆星、心和限時都對
func _play_old(lv, it: Dictionary) -> void:
	await frames(3)
	if lv.get("intro_block") != null:
		lv._intro_finish()
	await frames(2)
	if not bool(lv.tower_mode):
		_issue("舊題型沒有進入塔的模式")
	if not lv.journey_label.text.contains("第 %d 層" % int(g.session.floor)):
		_issue("舊題型的標題是「%s」" % lv.journey_label.text)
	if int(lv.energy) != int(g.session.hearts):
		_issue("舊題型的心是 %d，應該是 %d" % [int(lv.energy), int(g.session.hearts)])
	if not lv.r.has("time"):
		_issue("舊題型在塔裡沒有限時")
	var type := String(lv.r.type)
	if type == "forge":
		await _play_forge(lv)
	else:
		await _play_base(lv, type)
	await frames(4)
	if not lv.next_btn.visible:
		_issue("%s 照正確答案玩完，卻沒有出現下一步的按鈕" % type)
		await shot("old_" + cur_tag)
		lv._end_round()
	elif int(lv.round_stars) < 3:
		_issue("%s 一次答對卻只有 %d 星" % [type, int(lv.round_stars)])


func _click(ctl: Control, pos: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = pos
		e.global_position = ctl.global_position + pos
		ctl._gui_input(e)
