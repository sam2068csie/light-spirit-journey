extends "test_base.gd"
## 5. 遊戲管家各層的功能真的跑得動（存檔、音效、星塵獎勵、寶箱、每日任務、扭蛋、簽到、換場景）
##    管家分成好幾層，有些呼叫要到執行時才知道對不對，所以每一層都實際呼叫一次


func _initialize() -> void:
	await setup()
	g.wipe_progress()
	await setup()
	# 第 2 層：音效
	g.sfx("correct")
	g.play("bell", 1.2, -10.0)
	g.set_volume("sfx", 0.5)
	ok(absf(g.sfx_vol - 0.5) < 0.001, "音量設定")
	# 第 3 層：主線獎勵
	var rw: Dictionary = g.journey_reward("L1/rise", 0, 3, false)
	ok(int(rw.dust) == g.RW_FIRST + g.RW_STAR3, "第一次通過＋三星的星塵：%s" % str(rw))
	var rw2: Dictionary = g.journey_reward("L1/rise", 0, 3, false)
	ok(int(rw2.dust) == 0, "同一題重玩不再給星塵")
	var before := int(g.inv.dust)
	var got: Dictionary = g.claim_chest("L1_c1", false)
	ok(int(got.get("dust", 0)) == int(g.CHEST.dust) and int(g.inv.dust) == before + int(g.CHEST.dust), "章節寶箱")
	ok(g.claim_chest("L1_c1", false).is_empty(), "寶箱只能開一次")
	var gold: Dictionary = g.claim_chest("L1_c1_gold", false, true)
	ok(int(gold.get("crystal", 0)) == int(g.GOLD_CHEST.crystal), "黃金寶箱")
	var tr: Dictionary = g.tower_reward(5)
	ok(int(tr.dust) > 0, "終焉之塔獎勵")
	# 每日任務
	g.quest_event("correct", {"stars": 3, "review": false, "timed": false})
	ok(g.quest_list().size() > 0, "每日任務清單")
	# 扭蛋
	g.inv.dust = 10000
	g.inv.crystal = 100
	var res: Array = g.gacha_pull("one")
	ok(res.size() == 1, "單抽")
	ok(g.gacha_pull("ten").size() == 10, "十連")
	ok(not g.owned.is_empty(), "抽到的裝扮有記下來")
	# 簽到
	var sc: Dictionary = g.streak_claim()
	ok(not sc.is_empty() and int(g.streak.count) >= 1, "連續簽到")
	# 存檔：剛剛的星塵、裝扮讀回來
	g.save_review()
	var dust := int(g.inv.dust)
	g.inv.dust = 0
	g._load_review()
	ok(int(g.inv.dust) == dust, "存檔讀回來")
	# 第 4 層：換場景
	g.goto("main_menu.gd")
	await wait(1.0)
	ok(current_scene != null and String(current_scene.get_script().resource_path).ends_with("main_menu.gd"), "換場景")
	# 扭蛋機的貨幣：點一下跳出中文名稱，點別的地方收起來
	var m = current_scene
	m._open_gacha()
	await wait(1.0)
	var gp = m.get_child(m.get_child_count() - 1)
	var NT := preload("res://data/ui/name_tip.gd")
	var names := []
	for chip in gp._hold.get_children():
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = true
		chip.gui_input.emit(e)
		await wait(0.3)
		names.append(NT._cur.text if is_instance_valid(NT._cur) else "")
		if chip == gp._hold.get_child(1):
			await shot("gacha_currency_tip")
	ok(names == ["星塵", "光之碎片", "光之結晶"], "點貨幣顯示中文名稱：%s" % str(names))
	var far := InputEventMouseButton.new()
	far.button_index = MOUSE_BUTTON_LEFT
	far.pressed = true
	far.position = Vector2(300, 400)
	NT._cur._input(far)
	await wait(0.1)
	ok(not is_instance_valid(NT._cur), "點別的地方：名稱收起來")
	await _wardrobe_scroll(m)
	finish("ECONOMY")


## 衣櫃：一類超過 12 件（第 4 排）要捲得到；滾輪能捲；穿上裝扮停在原位；換分類回到最上面
func _wardrobe_scroll(m) -> void:
	var Cos := preload("res://data/core/cosmetics.gd")
	for it in Cos.ITEMS:
		g.owned[it.id] = 1
	for c in m.get_children():
		if c.get_script() == preload("res://data/ui/gacha_page.gd"):
			c.queue_free()
	await wait(0.3)
	m._open_wardrobe()
	await wait(1.0)
	var w = null
	for c in m.get_children():
		if c.get_script() == preload("res://data/ui/wardrobe.gd"):
			w = c
	ok(w != null, "打開衣櫃")
	for cat in Cos.CATS:
		w._cat = cat.id
		w._refresh()
		await wait(0.4)
		var sc: ScrollContainer = w._scroll
		var n: int = w._grid.get_child_count()
		var vb := sc.get_v_scroll_bar()
		var need_scroll := n > 12
		ok(sc.scroll_vertical == 0, "%s：換分類從最上面開始" % cat.name)
		ok((vb.max_value - vb.page > 1.0) == need_scroll, "%s %d 件：%s" % [cat.name, n, "要捲動" if need_scroll else "不用捲"])
		# 滾輪往下捲到底
		for k in 8:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_WHEEL_DOWN
			e.pressed = true
			e.position = sc.get_global_rect().get_center()
			e.global_position = e.position
			get_root().push_input(e)
			var e2: InputEventMouseButton = e.duplicate()
			e2.pressed = false
			get_root().push_input(e2)
			await wait(0.03)
		await wait(0.3)
		var last: Control = w._grid.get_child(n - 1)
		var vis := sc.get_global_rect().grow(1.0).encloses(last.get_global_rect())
		ok(vis, "%s：最後一件「%s」捲得到、看得完整" % [cat.name, last.get_child(1).text if last.get_child_count() > 1 else ""])
		if need_scroll:
			ok(sc.scroll_vertical > 0, "%s：滾輪捲得動" % cat.name)
			await shot("wardrobe_%s_bottom" % cat.id)
			# 穿上第 4 排的裝扮：重畫後停在原位
			var before := sc.scroll_vertical
			last.pressed.emit()
			await wait(0.4)
			ok(abs(w._scroll.scroll_vertical - before) <= 2, "%s：穿上第 4 排的裝扮，畫面停在原位（%d → %d）" % [cat.name, before, w._scroll.scroll_vertical])
	w._close()
	await wait(0.2)
