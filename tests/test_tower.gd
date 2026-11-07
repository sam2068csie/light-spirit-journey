extends "test_play.gd"
## 終焉之塔：真的爬一次
##   items：段考風格的每一題都一次答對（點選項、按真／假、劃掉根、點數線），每一步檢查版面，最後一定要三顆星
##   wrong：每一步先答錯一次再答對（看提示有沒有擠出畫面、心有沒有正確扣）
##   lose ：三顆心用完、時間到，都要示範完整解法並出現「看攀登結果」
##   run  ：從第 1 層爬到塔頂（舊題型也照正確答案玩），檢查樓層、心、試煉層、結算畫面
## 環境變數 TMODE=items,wrong 只跑某幾種；ONLY=j_rules,b_drug 只玩某幾題；UNITS=exp,h1poly 只測某幾個單元；SHOTS=資料夾 存截圖
## 題型：choice、judge、roots、line、sign（數線標正負號）、pick（選圖）、fill（數字鍵盤）都會照學生的方式操作

const Center := preload("res://data/core/review_center.gd")
const MathLabel := preload("res://data/ui/math_text.gd")
var Bank: Script
var unit := "exp"
const VP := Vector2(1152, 648)


func _initialize() -> void:
	await setup()
	_all_shots = OS.get_environment("ALLSHOTS") != ""
	var modes := OS.get_environment("TMODE")
	if modes == "":
		modes = "items,wrong,lose,run"
	var only := OS.get_environment("ONLY")
	var units := OS.get_environment("UNITS")
	for u in Units.UNITS:
		if String(u.get("tower", "")) == "" or (units != "" and not (String(u.id) in units.split(","))):
			continue
		unit = String(u.id)
		g.cur_unit = unit
		Bank = Center.tower_bank(unit)
		cur_tag = unit + " 題庫"
		_check_bank()
		for it in Bank.items():
			if only != "" and not (String(it.id) in only.split(",")):
				continue
			if "items" in modes:
				await _play_item(String(it.id), false)
			if "wrong" in modes:
				await _play_item(String(it.id), true)
		if "lose" in modes and only == "":
			await _lose_cases()
		if "run" in modes and only == "":
			await _climb()
	ok(issues == 0, "終焉之塔沒有發現問題（%d 個）" % issues)
	finish("TOWER")


# ================= 一題一題玩 =================

func _open(id: String, hearts := 3, time := 900.0):
	g.session = {}          # 不是真的在攀登：按「前往下一層」不會跳走
	g.goto("boss_tower.gd", {"review": {"level": "T", "slot": id}, "tower_floor": 7, "tower_hearts": hearts, "tower_time": time, "unit": unit})
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
		"sign":
			await _set_signs(bt, st.signs)
			await _bcheck(bt, "%02d 正負號標好" % bt.si)
			bt.action_btn.pressed.emit()
		"pick":
			var t := _pick_tile(bt, 0)
			if t == null:
				_issue("選圖題找不到正確的那張圖")
				return
			t.pressed.emit()
		"fill":
			await _type_fill(bt, st.ans)
			await _bcheck(bt, "%02d 數字填好" % bt.si)
			if bt.fill_send.disabled:
				_issue("每一格都填了，「送出」還是不能按")
			bt.fill_send.pressed.emit()


func _pick_tile(bt, k: int) -> Button:
	for t in bt.pick_tiles:
		if int(t.get_meta("k", -1)) == k and not t.disabled:
			return t
	return null


## 用數字鍵盤輸入（和學生一樣按鍵）
func _type_fill(bt, vals: Array) -> void:
	for i in vals.size():
		while int(bt.fill_cur) != i:
			bt._on_key("▶")
		while String(bt.fill_vals[i]) != "":
			bt._on_key("⌫")
		for ch in String(vals[i]).replace("-", "−"):
			if not ch in bt.KEYS:
				_issue("答案 %s 有鍵盤打不出來的字「%s」" % [vals[i], ch])
				return
			bt._on_key(ch)
	await frames(2)


## 數線的正負號：每點一下 空白 → ＋ → −
func _set_signs(bt, signs: Array) -> void:
	var nl = bt.numline
	await frames(2)
	var r: Dictionary = nl.rows.back()
	var xs: Array = nl._xs()
	var y: float = nl._row_y(nl.rows.size() - 1)
	for i in signs.size():
		var guard := 0
		while int(r.seg[i]) != int(signs[i]) and guard < 3:
			guard += 1
			var sp: Vector2 = nl._seg_span(i, xs)
			_click(nl, Vector2((sp.x + sp.y) / 2.0, y))
		if int(r.seg[i]) != int(signs[i]):
			_issue("數線第 %d 段點不出 %s" % [i + 1, "＋" if int(signs[i]) > 0 else "−"])
	await frames(1)


## 題庫本身的檢查：選項不重複、正解在選項裡、填空答案打得出來、排版正確
func _check_bank() -> void:
	var ids := {}
	for it in Bank.items():
		var id := String(it.id)
		if ids.has(id):
			_issue("題目代號重複：%s" % id)
		ids[id] = true
		if not Bank.KIND_NAME.has(it.kind):
			_issue("%s 的題型 %s 沒有名字" % [id, it.kind])
		for st in it.steps:
			var t := String(st.t)
			if t == "choice":
				var seen := {}
				for o in st.opts:
					if seen.has(String(o)):
						_issue("%s：選項重複「%s」" % [id, o])
					seen[String(o)] = true
			if t == "pick" and st.graphs.size() != st.get("whys", st.graphs).size():
				_issue("%s：選圖題的 whys 數量和圖不一樣" % id)
			if t == "fill":
				for i in st.ans.size():
					if not String(st.template).contains("[%d]" % i):
						_issue("%s：填空的格子 [%d] 不在 template 裡" % [id, i])
			if t == "sign" and st.signs.size() != st.marks.size() + 1:
				_issue("%s：正負號的段數不對" % id)
			if t == "line" and (st.seg.size() != st.marks.size() + 1 or st.pt.size() != st.marks.size()):
				_issue("%s：數線的段數或端點數不對" % id)
			if st.has("col") and not it.get("routes", {}).has(st.col):
				_issue("%s：路線 %s 沒有名字" % [id, st.col])
		_lint(it, id)
		_no_cjk_on_plot(it.get("plot", {}), id)
		for st in it.steps:
			for gph in st.get("graphs", []):
				_no_cjk_on_plot(gph, id)


## 圖上不標中文：點的 label、幾何圖的文字 s
func _no_cjk_on_plot(v, where: String) -> void:
	if v is Dictionary:
		for k in v:
			if (k == "label" or k == "s") and v[k] is String:
				for ch in String(v[k]):
					if ch.unicode_at(0) >= 0x3000:
						_issue("%s：圖上有中文「%s」" % [where, v[k]])
						break
			else:
				_no_cjk_on_plot(v[k], where)
	elif v is Array:
		for e in v:
			_no_cjk_on_plot(e, where)


func _lint(v, where: String) -> void:
	if v is Dictionary:
		for k in v:
			if not (str(k) in ["id", "kind", "f", "c", "t", "col"]):
				_lint(v[k], where)
	elif v is Array:
		for e in v:
			_lint(e, where)
	elif v is String:
		for p in MathLabel.lint(v):
			_issue("%s 排版：%s ⇐「%s」" % [where, p, String(v).left(50)])


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
		"sign":
			var sg: Array = st.signs.map(func(v): return -int(v))
			await _set_signs(bt, sg)
			bt.action_btn.pressed.emit()
			await frames(2)
			if bt.hearts != h0 - 1:
				_issue("正負號標錯了卻沒有扣心")
		"pick":
			var t := _pick_tile(bt, 1)
			if t == null:
				_issue("選圖題找不到錯的圖")
				return
			t.pressed.emit()
			await frames(2)
			if bt.hearts != h0 - 1:
				_issue("選錯圖卻沒有扣心")
		"fill":
			var bad: Array = st.ans.map(func(v): return "98765")
			await _type_fill(bt, bad)
			bt.fill_send.pressed.emit()
			await frames(2)
			if bt.hearts != h0 - 1:
				_issue("填錯數字卻沒有扣心")


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
	# 選項不能折成兩行
	for b in bt.opts_box.get_children():
		if b is Button and b.has_meta("one_line_w") and float(b.get_meta("one_line_w")) > bt.CARD_W - 28.0 + 0.5:
			_issue("%s：選項太長會折成兩行（%s）" % [when, String(b.get_node("Math").text).left(40)])
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

## 第一次進塔的教學：跳一次（遊戲暫停），之後不再跳
func _tutorial_case() -> void:
	cur_tag = unit + "（第一次進塔的教學）"
	g.tut.erase("tower")
	var bt = await _open(String(Bank.items()[0].id))
	if bt == null:
		return
	await wait(0.6)
	var tut: Node = null
	for c in bt.get_children():
		if c is CanvasLayer and c.get_script() != null and String(c.get_script().resource_path).ends_with("tutorial.gd"):
			tut = c
	if tut == null:
		_issue("第一次進終焉之塔沒有跳教學")
		return
	if not paused:
		_issue("教學進行時遊戲沒有暫停（計時會跑）")
	var texts := []
	for k in tut.steps.size():
		await wait(0.5)
		await shot("%s_tower_tut_%d" % [unit, k])
		texts.append(String(tut.steps[k].text))
		if int(tut.i) != k:
			_issue("教學第 %d 句被跳過了" % (k + 1))
		var i0: int = tut.i
		while is_instance_valid(tut) and int(tut.i) == i0 and not tut._ended:
			tut._advance()      # 字還在跑時第一下是「顯示完」
			await frames(1)
	await wait(0.6)
	if not "".join(texts).contains("手寫計算"):
		_issue("教學沒有提到右上角的手寫計算功能")
	if paused:
		_issue("教學結束後遊戲還是暫停的")
	if not bool(g.tut.get("tower", false)):
		_issue("教學看過了，存檔卻沒有記下來")
	var bt2 = await _open(String(Bank.items()[0].id))
	await wait(0.6)
	for c in bt2.get_children():
		if c is CanvasLayer and c.get_script() != null and String(c.get_script().resource_path).ends_with("tutorial.gd"):
			_issue("看過教學了，第二次進塔又跳出來")


## 數字鍵盤的規則要和八大關一樣
func _keypad_case() -> void:
	var fid := ""
	for it in Bank.items():
		for st in it.steps:
			if String(st.t) == "fill" and fid == "" and not String(st.ans[0]).contains("."):
				fid = String(it.id)
	if fid == "":
		return
	cur_tag = unit + "（數字鍵盤 " + fid + "）"
	var bt = await _open(fid, 3)
	if bt == null:
		return
	var guard := 0
	while String(bt.steps[bt.si].t) != "fill" and guard < 10:
		guard += 1
		var si0: int = bt.si
		await _answer(bt, bt.steps[si0])
		await _wait_step(bt, si0)
		if bt.waiting:
			bt.action_btn.pressed.emit()
			await frames(3)
	var press := func(keys: Array) -> String:
		for k in keys:
			bt._on_key(k)
		return String(bt.fill_vals[bt.fill_cur])
	var checks := [
		[["1", "−"], "−1", "先按 1 再按 − 要變成 −1"],
		[["−"], "1", "再按一次 − 要變回 1"],
		[["/", "2", "/"], "1/2", "/ 只能按一次"],
		[["⌫", "⌫", "⌫", "/"], "", "空的時候不能按 /"],
		[["−", "/"], "−", "只有負號時不能按 /"],
		[["⌫", "1", "2", "3", "4", "5", "6", "7", "8"], "1234567", "最多 7 個字"]]
	for c in checks:
		var got: String = press.call(c[0])
		if got != String(c[1]):
			_issue("%s：按出「%s」，應該是「%s」" % [c[2], got, c[1]])
	if bt.KEY_ROWS[2].has(".") or bt.opts_box.find_children("*", "Button", true, false).any(func(b): return b.text == "."):
		_issue("答案沒有小數的題目卻有「.」鍵")
	while String(bt.fill_vals[bt.fill_cur]) != "":
		bt._on_key("⌫")
	press.call(["3", "/"])
	var h0: int = bt.hearts
	bt.fill_send.pressed.emit()
	await frames(2)
	if bt.hearts != h0:
		_issue("格子沒填好（「3/」）就送出，不該扣心")
	if not String(bt.hint_label.text).contains("還沒填好"):
		_issue("格子沒填好就送出，沒有提醒")
	await shot(unit + "_keypad_unfinished")


func _lose_cases() -> void:
	await _tutorial_case()
	await _keypad_case()
	# 1. 只剩一顆心時答錯：示範解法、看攀登結果
	var lose_ids: Array = {"exp": ["r_logsum", "j_rules", "l_twolog", "b_ineq"], "h1poly": ["pr_two", "pj_coef", "pl_sign", "pb_garden", "pg_shift"],
		"trig": ["tc_half", "tj_sign", "tq_tide", "tb_gun", "tg_pick"]}[unit]
	for id in lose_ids:
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
		await shot(unit + "_lose_" + id)
	# 2. 時間到
	for id in {"exp": ["e_closed", "q_bact"], "h1poly": ["pp_twoway", "pg_pair"], "trig": ["te_quad", "tq_wheel"]}[unit]:
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
		await shot(unit + "_timeout_" + id)
	# 3. 審判錯一張不扣心、錯兩張扣一顆
	var jid: String = {"exp": "j_value", "h1poly": "pj_tworem", "trig": "tj_period"}[unit]
	cur_tag = jid + "（錯一張）"
	var bj = await _open(jid)
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
		await shot(unit + "_judge_one_wrong")
		bj.action_btn.pressed.emit()
		await frames(3)
		if not bj.done or int(bj._stars) != 2:
			_issue("錯一張之後應該通過且 2 星（done=%s、星=%d）" % [str(bj.done), int(bj._stars)])


# ================= 從第 1 層爬到塔頂 =================

func _climb() -> void:
	var top := Center.tower_top(unit)
	cur_tag = unit + " 攀登"
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
				await shot(unit + "_climb_floor1")
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
	await shot(unit + "_climb_result")
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
		await shot(unit + "_climb_floor2_hearts")
		s2.pause_menu.list_action.call()
		await wait(1.0)
		if String(current_scene.get_script().resource_path).get_file() != "main_menu.gd":
			_issue("放棄攀登沒有回到結算畫面")
		else:
			await wait(1.0)
			await shot(unit + "_climb_abort_result")


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
