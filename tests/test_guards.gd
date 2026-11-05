extends "res://tests/test_base.gd"
## 防呆：章節寶箱
##   ・結算畫面出來、寶箱還在等那 0.7 秒時，按「回到題目列表」不會離開，而是先叫出寶箱
##   ・寶箱跳出來之前到開完之間，暫停選單（暫停鍵、Esc、手機返回鍵）打不開
##   ・開完以後寶箱有領到


func _find_btn(n: Node, txt: String) -> Button:
	if n is Button and (n as Button).text.begins_with(txt) and n.is_visible_in_tree():
		return n
	for c in n.get_children():
		var b := _find_btn(c, txt)
		if b != null:
			return b
	return null


func _initialize() -> void:
	await setup()
	g.story_seen = ["world/g10", "world/g11", "L3"]
	g.goto("level_03_scale.gd")
	await wait(1.0)
	var lv = current_scene
	for c in lv.get_children():
		if c is Control and c.mouse_filter == Control.MOUSE_FILTER_STOP and c.get_index() > 3:
			c.queue_free()
	await frames(2)
	var ch := 1
	lv.journey_mode = true
	lv.chapter_now = ch
	lv.chapter_slots = lv._chapter_slots(ch)
	# 從頭開始（存檔在 user://，本機重跑也要乾淨）：寶箱還沒開過、這一章全部通過
	g.main_rw.chests.erase(lv._chest_key(ch))
	g.main_rw.chests.erase(lv._gold_key(ch))
	var added := []
	for s in lv.chapter_slots:
		if g.mark_cleared(lv._jkey(s), 0):
			added.append(lv._jkey(s))
	var s0: Dictionary = lv.chapter_slots[lv.chapter_slots.size() - 1]
	lv.rounds = [lv.make_round(s0, s0.variants[0])]
	lv.ri = 0
	lv.cur_slot_idx = lv.chapter_slots.size() - 1
	lv.round_stars = 3
	ok(lv._chest_ready(ch), "這一章全部通過、寶箱還沒開")
	lv._finish_journey()
	await frames(3)
	ok(lv._chest_pending, "結算畫面出來：寶箱在等著跳出來")
	lv.pause_menu.open()
	ok(not lv.pause_menu.is_open(), "寶箱跳出來之前：暫停選單打不開")
	var back := _find_btn(lv, "回到題目列表")
	ok(back != null, "結算畫面有「回到題目列表」")
	if back != null:
		back.pressed.emit()
	await frames(3)
	ok(lv._chest_showing, "先按返回：不離開，先叫出寶箱")
	lv.pause_menu.open()
	ok(not lv.pause_menu.is_open(), "寶箱還沒開完：暫停選單打不開")
	await wait(0.6)
	var ob := _find_btn(lv, "打開寶箱")
	ok(ob != null, "寶箱視窗有「打開寶箱！」")
	if ob != null:
		ob.pressed.emit()
	await wait(4.0)
	ok(g.chest_claimed(lv._chest_key(ch)), "寶箱有領到")
	# 收拾：存檔回到測試前（存檔在 user://，接著跑別的測試才不受影響）
	for k in added:
		g.cleared.erase(k)
	var cf := ConfigFile.new()
	for k in g.cleared:
		cf.set_value("cleared", k, g.cleared[k])
	cf.save("user://cleared.cfg")
	g.main_rw.chests.erase(lv._chest_key(ch))
	g.save_review()
	finish("GUARDS")
