extends "test_base.gd"
## 觀念卡片：內容格式、拖積木填空、隨堂小測、解題流程、星塵獎勵
##   內容：每張一般卡片至少一個空格、至少一塊干擾積木，干擾積木不能剛好是這張卡片的某個答案；
##         可以互換的空格（swap）都要是這張卡片的答案；積木不能太寬；解題流程的干擾步驟不能是真的步驟
##   操作：用滑鼠事件真的拖一次積木；放錯會彈回去、不扣東西；全部填完＋小測答對 → 星塵 +5（只給一次）

const Units := preload("res://data/core/units.gd")
const Cards := preload("res://data/ui/concept_cards.gd")
const Deck := preload("res://data/ui/concept_deck.gd")
const MathLabel := preload("res://data/ui/math_text.gd")
const MAX_TILE_W := 300.0


func _initialize() -> void:
	await setup()
	_check_content()
	await _check_play()
	finish("CONCEPTS")


func _check_content() -> void:
	var font: Font = ThemeDB.fallback_font
	var n_cards := 0
	for u in Units.UNITS:
		for l in u.levels:
			var lid := String(l.id)
			var titles := {}
			for cd in Cards.cards(lid):
				n_cards += 1
				var where := "%s「%s」" % [lid, cd.title]
				ok(not titles.has(cd.title), "%s：同一大關的卡片標題重複（存檔用標題當記號）" % where)
				titles[cd.title] = true
				var decoys: Array = cd.get("decoys", [])
				ok(decoys.size() >= 1, "%s：沒有干擾積木" % where)
				if cd.get("kind", "") == "order":
					for d in decoys:
						ok(not (cd.steps as Array).has(d), "%s：干擾步驟「%s」是真的步驟" % [where, d])
					continue
				var answers := []
				for m in Deck._lines(cd):
					for sg in Deck._parse(m):
						if sg.h:
							answers.append(String(sg.t))
				ok(answers.size() >= 1, "%s：沒有空格" % where)
				for d in decoys:
					ok(not answers.has(d), "%s：干擾積木「%s」剛好是答案" % [where, d])
				for grp in cd.get("swap", []):
					for x in grp:
						ok(answers.has(x), "%s：swap 裡的「%s」不是這張卡片的答案" % [where, x])
				for x in answers + decoys:
					var w := MathLabel.text_width(font, String(x), 17)
					ok(w <= MAX_TILE_W, "%s：積木「%s」太寬（%d px）" % [where, x, int(w)])
	ok(n_cards > 50, "卡片數量 %d" % n_cards)


func _deck_for(lid: String) -> Array:
	# 和關卡裡一樣：放在 UITheme.modal 的卡片裡
	var UITheme = load("res://data/ui/game_theme.gd")
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(holder)
	var o: Array = UITheme.modal(holder, Color.WHITE, 1110, false)
	var d = Deck.new()
	d.setup("測試", Cards.cards(lid), Color("5fd4ff"), {}, -1, lid)
	(o[1] as Control).add_child(d)
	await frames(4)
	return [holder, d]


func _tile(d, text: String):
	for t in d._tiles:
		if t.text == text and not t.used:
			return t
	return null


func _check_play() -> void:
	g.concepts = {}
	g.inv["dust"] = 100
	var hd: Array = await _deck_for("L1")
	var holder: Control = hd[0]
	var d = hd[1]
	ok(d.mode == "list", "一打開是卡片清單")
	ok(d._primary.text.contains("開始挑戰"), "清單的主要按鈕是「開始挑戰」")
	# 第一張卡片
	d._show(0, 0)
	await frames(6)
	var cd: Dictionary = d.cards[0]
	ok(d.mode == "card", "點進卡片")
	ok(d._slots.size() == Deck.blank_count(cd), "空格數量 %d" % d._slots.size())
	ok(d._tiles.size() == d._slots.size() + (cd.decoys as Array).size(), "積木 = 答案 + 干擾積木（%d 塊）" % d._tiles.size())
	ok(d._primary.disabled, "還沒填完：主要按鈕不能按")
	# 干擾積木放到哪裡都不對，彈回去、不扣星塵
	var dz = _tile(d, String(cd.decoys[0]))
	ok(dz != null, "找得到干擾積木")
	var dust0 := int(g.inv.dust)
	ok(not d.try_place(dz, d._slots[0]), "干擾積木放不進去")
	ok(not dz.used and int(g.inv.dust) == dust0, "放錯不扣東西，積木還在")
	ok(String(d._feedback.text).contains("再想想"), "放錯有提示")
	# 用真的滑鼠事件拖第一塊（按下 → 移動 → 放開）
	var s0 = d._slots[0]
	var t0 = _tile(d, s0.answer)
	await frames(2)
	var from: Vector2 = t0.get_global_rect().get_center()
	var to: Vector2 = s0.get_global_rect().get_center()
	# 有畫面時從視窗送滑鼠事件；headless 沒辦法點到控制項，就把同樣的事件直接交給積木
	var direct := DisplayServer.get_name() == "headless"
	_mouse(t0, from, true, direct)
	await frames(2)
	for k in 6:
		_motion(t0, from.lerp(to, (k + 1) / 6.0), direct)
		await frames(1)
	_mouse(t0, to, false, direct)
	await frames(3)
	ok(s0.filled, "用滑鼠把積木拖進第一格")
	# 其他格
	for s in d._slots:
		if s.filled:
			continue
		var t = _tile(d, s.answer)
		if t == null:
			for grp in cd.get("swap", []):
				if (grp as Array).has(s.answer):
					for x in grp:
						if _tile(d, x) != null:
							t = _tile(d, x)
		ok(t != null, "找得到「%s」的積木" % s.answer)
		if t != null:
			ok(d.try_place(t, s), "放進「%s」" % s.answer)
	await frames(2)
	ok(not d._primary.disabled and d._primary.text.contains("小測"), "填完之後可以做小測")
	ok(int(g.inv.dust) == dust0, "小測還沒答對，還沒給星塵")
	d._on_primary()
	await frames(3)
	ok(d.mode == "check", "進入隨堂小測")
	var ck: Dictionary = cd.check
	# 找出正確的選項按鈕
	var right_btn = null
	for rb in d._rows:
		var lab = rb.find_child("Math", true, false)
		if lab != null and String(lab.text).contains(String(ck.opts[int(ck.a)]).substr(0, 3)):
			right_btn = rb
	d._on_check(right_btn if right_btn != null else d._rows[0], true, ck)
	await frames(2)
	ok(int(g.inv.dust) == dust0 + Deck.REWARD, "完成第一張：星塵 +%d" % Deck.REWARD)
	ok((g.concepts as Dictionary).has("L1|" + String(cd.title)), "完成記在存檔裡")
	# 重新練習：再完成一次不再給
	d._show(0, 0)
	await frames(4)
	ok(d._slots.size() > 0 and d._slots[0].filled, "完成過的卡片打開是填好的樣子（複習）")
	d._on_redo()
	await frames(6)
	ok(not d._slots[0].filled and d._tiles.size() > 0, "重新練習：空格清空、積木重新出現")
	for s in d._slots:
		var t = _tile(d, s.answer)
		if t == null:
			for grp in cd.get("swap", []):
				if (grp as Array).has(s.answer):
					for x in grp:
						if _tile(d, x) != null:
							t = _tile(d, x)
		if t != null:
			d.try_place(t, s)
	d._prog(0).check = true
	d._complete(0)
	ok(int(g.inv.dust) == dust0 + Deck.REWARD, "同一張卡片不會再給星塵")
	# 解題流程卡片
	var oi := -1
	for i in d.cards.size():
		if d.cards[i].get("kind", "") == "order":
			oi = i
	ok(oi >= 0, "L1 有解題流程卡片")
	d._show(oi, 0)
	await frames(6)
	var od: Dictionary = d.cards[oi]
	ok(d.mode == "order" and d._slots.size() == (od.steps as Array).size(), "流程卡片：格子數 = 步驟數")
	var wrong = _tile(d, String(od.decoys[0]))
	ok(not d.try_place(wrong, d._slots[0]), "錯的步驟放不進去")
	var later = _tile(d, String(od.steps[(od.steps as Array).size() - 1]))
	ok(not d.try_place(later, d._slots[(od.steps as Array).size() - 1]), "還不能先放最後一格")
	var placed := 0
	for k in (od.steps as Array).size():
		for si in (od.steps as Array).size():
			var t = _tile(d, String(od.steps[si]))
			if t != null and d._order_ok(od, si, d._prog(oi).order):
				ok(d.try_place(t, d._slots[placed]), "第 %d 步" % (placed + 1))
				placed += 1
				break
	ok(placed == (od.steps as Array).size(), "流程全部排好")
	ok(int(g.inv.dust) == dust0 + Deck.REWARD * 2, "完成流程卡片：星塵 +%d" % Deck.REWARD)
	# 回清單：完成的卡片打勾
	d._show_list()
	await frames(2)
	ok(d._counter.text.contains("完成 2"), "清單上顯示完成 2 張：%s" % d._counter.text)
	holder.queue_free()
	await frames(2)


func _mouse(t: Control, p: Vector2, down: bool, direct: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	_send(t, e, p, direct)


func _motion(t: Control, p: Vector2, direct: bool) -> void:
	var e := InputEventMouseMotion.new()
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	_send(t, e, p, direct)


func _send(t: Control, e: InputEventMouse, p: Vector2, direct: bool) -> void:
	if direct:
		e.position = t.get_global_transform().affine_inverse() * p
		e.global_position = p
		t._gui_input(e)
	else:
		e.position = p
		e.global_position = p
		root.push_input(e)
