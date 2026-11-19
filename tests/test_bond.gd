extends "test_base.gd"
## 光靈的親密度（game_bond.gd）：怎麼增加、每天上限、只增不減、升級、歡迎回來、Lv 7 守護、存檔、小屋的摸頭和聊天
const DQ := preload("res://data/core/daily_quests.gd")


func _initialize() -> void:
	await setup()
	g.wipe_progress()
	await setup()
	g.bond = {}
	var b: Dictionary = g.bond_state()
	ok(int(b.pts) == 0 and g.bond_level() == 1, "新存檔：Lv 1、0 點")
	# 答對：+1，每天前 30 題；改對也是 +1（不會比一次答對多）
	for i in 40:
		g.quest_event("correct", {"stars": 1})
	ok(int(g.bond.today.learn) == 30, "答對只算前 30 題：%s" % str(g.bond.today))
	var after_learn := int(g.bond.pts)
	ok(after_learn >= 30 and after_learn <= 35, "答對 40 題的親密度（可能含每日任務全完成 +5）：%d" % after_learn)
	ok(g.bond_level() == 1 or g.bond_level() == 2, "等級跟著點數")
	# 第一次通過旅程 +5，重玩不再給
	var p0 := int(g.bond.pts)
	var rw: Dictionary = g.journey_reward("B1/test", 0, 2, false)
	ok(int(rw.get("bond", 0)) == 5 and int(g.bond.pts) == p0 + 5, "第一次通過旅程 +5")
	rw = g.journey_reward("B1/test", 1, 3, false)
	ok(not rw.has("bond") and int(g.bond.pts) == p0 + 5, "重玩不再給親密度")
	# 小屋：摸頭 3 次、聊天 1 次
	var p1 := int(g.bond.pts)
	var got := 0
	for i in 5:
		got += g.bond_gain("pet")
	ok(got == 3 and g.bond_left("pet") == 0, "摸頭每天 3 次：%d" % got)
	ok(g.bond_gain("chat") == 2 and g.bond_gain("chat") == 0, "聊天每天 1 次 +2")
	ok(int(g.bond.pts) == p1 + 5, "小屋互動一天最多 +5（還沒做教光靈、點心）")
	var line: String = g.bond_chat_line(true)
	ok(line != "" and line.find("%") < 0, "聊天說的話：%s" % line)
	# 升級：記下還沒播的升級，拿一次就清掉
	g.bond = {"pts": 35, "day": DQ.day_key(), "today": {}}
	g.bond_gain("journey")
	ok(g.bond_level() == 2 and g.bond_lvup_pending() == 2, "35 + 5 = 40 → 升到 Lv 2")
	ok(g.bond_take_levelup() == 2 and g.bond_lvup_pending() == 0, "升級畫面播一次就清掉")
	# Lv 4：限定頭飾
	g.owned.erase(g.FRIEND_STAR)
	g.bond = {"pts": 249, "day": DQ.day_key(), "today": {}}
	g.bond_gain("journey")
	ok(g.bond_level() == 4 and g.owned.has(g.FRIEND_STAR), "Lv 4 拿到友誼之星")
	ok(not preload("res://data/core/cosmetics.gd").item(g.FRIEND_STAR).get("pool", true), "友誼之星抽不到")
	# 換日：今天的次數歸零；3 天以上沒來 +5（只增不減）
	var day_n: int = g._day_n(DQ.day_key())
	var old := Time.get_date_string_from_unix_time((day_n - 4) * 86400)
	g.bond = {"pts": 100, "day": old, "today": {"pet": 3}}
	b = g.bond_state()
	ok(int(b.pts) == 105 and String(b.hello) == "welcome" and int(b.today.get("pet", 0)) == 0, "4 天沒來：+5、今天的次數歸零")
	ok(g.bond_take_hello() == "welcome" and g.bond_take_hello() == "", "歡迎回來只說一次")
	var yest := Time.get_date_string_from_unix_time((day_n - 1) * 86400)
	g.bond = {"pts": 100, "day": yest, "today": {}}
	ok(int(g.bond_state().pts) == 100, "昨天有來：不加也不扣")
	# Lv 7：簽到守護上限 +1
	g.bond = {"pts": 999, "day": DQ.day_key(), "today": {}}
	ok(g.guard_max() == g.GUARD_MAX, "Lv 6：守護上限不變")
	g.bond.pts = 1000
	ok(g.guard_max() == g.GUARD_MAX + 1, "Lv 7：守護上限 +1")
	# 滿級
	g.bond.pts = 99999
	var pr: Dictionary = g.bond_progress()
	ok(int(pr.lv) == 10 and (pr.next as Dictionary).is_empty() and float(pr.frac) == 1.0, "滿級")
	# 存檔、讀檔
	g.bond = {"pts": 321, "day": DQ.day_key(), "today": {"pet": 2}}
	g.save_review()
	g.bond = {}
	g._load_review()
	ok(int(g.bond.get("pts", 0)) == 321 and int(g.bond.today.get("pet", 0)) == 2, "存檔讀得回來：%s" % str(g.bond))
	# 壞掉的存檔：點數是負的、today 不是字典
	g.bond = {"pts": -5, "day": DQ.day_key(), "today": "壞掉"}
	b = g.bond_state()
	ok(int(b.pts) == 0 and b.today is Dictionary, "壞掉的存檔不會當掉")
	# 小屋：摸頭（按住來回摸）、聊天、左下角的親密度
	g.bond = {"pts": 119, "day": DQ.day_key(), "today": {}}
	g.goto("res://data/house/house.gd")
	await wait(1.2)
	var h = current_scene
	ok(h.get_script() == preload("res://data/house/house.gd"), "進得了小屋")
	await shot("bond_house")
	var sp: Vector2 = h._spirit
	h._gui_input(_btn(sp, true))
	for k in 12:
		h._gui_input(_motion(sp + Vector2(30 if k % 2 == 0 else -30, 0)))
	h._gui_input(_btn(sp, false))
	ok(int(g.bond.today.get("pet", 0)) == 1, "按住光靈來回摸 = 摸摸頭")
	await wait(0.4)
	await shot("bond_pet")
	await wait(1.4)
	ok(g.bond_level() == 3 and is_instance_valid(h._overlay), "119 + 1 = 120 → Lv 3，升級跳出視窗：Lv %d" % g.bond_level())
	await shot("bond_levelup")
	h.close_overlay()
	h._gui_input(_btn(h._spirit, true))
	h._gui_input(_btn(h._spirit, false))
	ok(is_instance_valid(h._menu), "點一下光靈：跳出摸摸頭／聊天")
	await wait(0.3)
	await shot("bond_menu")
	h._close_menu()
	h._chat()
	ok(int(g.bond.today.get("chat", 0)) == 1, "聊天")
	await wait(0.5)
	await shot("bond_chat")
	h._open_bond()
	ok(is_instance_valid(h._overlay), "左下角打開親密度說明")
	await wait(0.4)
	await shot("bond_detail")
	var info: Button = h._overlay.find_child("Info", true, false)
	ok(info != null and h._overlay.find_child("Tip", true, false) == null, "說明一開始藏起來")
	info.pressed.emit()
	await wait(0.5)
	var tipn: Control = h._overlay.find_child("Tip", true, false)
	ok(tipn != null, "點 i 跳出提示框")
	await shot("bond_detail_tip")
	var cl := InputEventMouseButton.new()
	cl.button_index = MOUSE_BUTTON_LEFT
	cl.pressed = true
	cl.position = Vector2(20, 20)
	tipn.gui_input.emit(cl)
	await wait(0.2)
	ok(not is_instance_valid(tipn) and is_instance_valid(h._overlay), "點提示框外面：只收起提示框，視窗還在")
	h.close_overlay()
	await _phase2(h)
	finish("BOND")


## 第二期：點心、回憶相簿、暱稱
func _phase2(h) -> void:
	# ---- 點心 ----
	g.bond = {"pts": 100, "day": DQ.day_key(), "today": {}, "seed": 12345}
	g.inv["dust"] = 100
	ok(not g.bond_feed("moon_cake").ok and int(g.inv.dust) == 100, "Lv 2：還不能餵點心，也不扣星塵")
	g.bond.pts = 120
	var likes: Array = g.bond_likes()
	ok(likes.size() == 2 and likes[0] != likes[1], "這週喜歡 2 種點心：%s" % str(likes))
	ok(g.bond_likes() == likes, "同一週口味不變")
	var seen := {}
	for sd in 30:
		g.bond.seed = 1000 + sd
		seen[str(g.bond_likes())] = true
	ok(seen.size() >= 6, "每個人的口味不一樣：30 個玩家有 %d 種組合" % seen.size())
	g.bond.seed = 12345
	var other := ""
	for sn in g.SNACKS:
		if not likes.has(sn.id):
			other = sn.id
			break
	var price := int(g.snack_info(other).price)
	var p0 := int(g.bond.pts)
	var r: Dictionary = g.bond_feed(other)
	ok(r.ok and not r.liked and int(r.pts) == 1 and int(g.inv.dust) == 100 - price and int(g.bond.pts) == p0 + 1, "不是喜歡的口味：+1、扣星塵 %d" % price)
	r = g.bond_feed(likes[0])
	ok(not r.ok and String(r.why) == "今日已餵食", "點心每天 1 次")
	g.bond.today = {}
	r = g.bond_feed(likes[0])
	ok(r.ok and r.liked and r.first and int(r.pts) == 3 and g.bond_found().has(likes[0]), "喜歡的口味：+3，這週發現 1 種")
	g.bond.today = {}
	r = g.bond_feed(likes[0])
	ok(r.ok and r.liked and not r.first, "同一種再餵：還是 +3，但不是新發現")
	g.inv["dust"] = 0
	g.bond.today = {}
	r = g.bond_feed(likes[1])
	ok(not r.ok and String(r.why) == "星塵不足", "星塵不夠不能餵")
	g.bond.found = {"week": g.bond_week() - 1, "ids": likes.duplicate()}
	ok(g.bond_found().is_empty(), "換週：發現的喜好重來")
	# ---- 回憶相簿 ----
	g.bond = {"pts": 449, "day": DQ.day_key(), "today": {}, "mem": []}
	g.bond_gain("journey")
	var ids := []
	for m in g.bond_memories():
		ids.append(String(m.id))
	ok(ids.has("lv:5"), "升到 Lv 5 自動拍一張：%s" % str(ids))
	ok(g.bond_photo() and not g.bond_photo(), "小屋合照每天 1 張")
	ok(g.bond_memory("x", "測試", "map") and not g.bond_memory("x", "測試", "map"), "同一個回憶只拍一次")
	for i in 90:
		g.bond.mem.append({"id": "photo:%d" % i, "title": "小屋合照", "scene": "house", "day": DQ.day_key(), "eq": {}})
	g.bond_memory("y", "測試", "map")
	ids = []
	for m in g.bond_memories():
		ids.append(String(m.id))
	ok(ids.size() <= g.MEM_MAX and ids.has("lv:5") and ids.has("y"), "相簿滿了先丟舊的合照：%d 張" % ids.size())
	# ---- 暱稱 ----
	g.bond = {"pts": 449, "day": DQ.day_key(), "today": {}}
	ok(not g.bond_set_nick("小明"), "Lv 4：還不能取暱稱")
	g.bond.pts = 450
	ok(g.bond_set_nick("  小明 ") and g.bond_nick() == "小明", "Lv 5：暱稱（去掉空白）")
	ok(not g.bond_set_nick("一二三四五六七") and not g.bond_set_nick("   "), "暱稱 1～6 字")
	ok(g.bond_chat_line(true).begins_with("小明，"), "聊天會叫暱稱：%s" % g.bond_chat_line(true))
	var called := false
	for i in 60:
		if preload("res://data/ui/buddy.gd").line("pass").begins_with("小明，"):
			called = true
	ok(called, "關卡裡的光靈有時會叫暱稱")
	# ---- 畫面 ----
	g.bond.mem = [
		{"id": "lv:2", "title": "親密度 Lv.2", "scene": "levelup", "day": "2026-11-02", "eq": {}},
		{"id": "first_star3", "title": "第一次三顆星", "scene": "map", "day": "2026-11-03", "eq": g.equipped.duplicate()},
		{"id": "sv:h1num", "title": "點亮　數與式", "scene": "unit:h1num", "day": "2026-11-08", "eq": {}},
		{"id": "tower:h1num", "title": "終焉之塔登頂", "scene": "tower", "day": "2026-11-12", "eq": {}},
		{"id": "photo:2026-11-18", "title": "小屋合照", "scene": "house", "day": "2026-11-18", "eq": g.equipped.duplicate()}]
	g.bond.today = {}
	g.inv["dust"] = 100
	h._refresh()
	h._toggle_menu()
	await wait(0.3)
	ok(is_instance_valid(h._menu) and h._menu.get_child_count() == 4, "Lv 3 以上：摸摸頭、聊天、點心、拍照")
	await shot("bond2_menu")
	h._close_menu()
	h._snack()
	await wait(0.5)
	await shot("bond2_snacks")
	var btn: Button = h._overlay.find_child("Snack_" + likes[0], true, false)
	ok(btn != null and not btn.disabled, "點心選單")
	btn.pressed.emit()
	await wait(0.6)
	ok(int(g.bond.today.get("snack", 0)) == 1 and int(g.inv.dust) == 100 - int(g.snack_info(likes[0]).price), "選了點心：餵食、扣星塵")
	await shot("bond2_feed")
	await wait(2.0)
	h.close_overlay()
	h._photo()
	await wait(0.1)
	await shot("bond2_photo")
	await wait(0.8)
	h._open_album()
	await wait(0.6)
	ok(is_instance_valid(h._overlay), "相簿")
	await shot("bond2_album")
	h.close_overlay()
	await wait(0.2)
	var lu: Control = preload("res://data/ui/bond_panel.gd").levelup(h, 5)
	await wait(0.6)
	ok(lu.find_children("*", "LineEdit", true, false).size() == 1, "升到 Lv 5：可以取暱稱")
	await shot("bond2_lv5")
	lu.queue_free()
	h._open_bond()
	await wait(0.4)
	ok(h._overlay.find_child("Nick", true, false) != null, "親密度視窗：暱稱")
	await shot("bond2_detail")
	h.close_overlay()


func _btn(p: Vector2, down: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = p
	return e


func _motion(p: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	return e
