extends "res://tests/test_base.gd"
## 防呆：章節寶箱
##   ・結算畫面出來、寶箱還在等那 0.7 秒時，按「回到題目列表」不會離開，而是先叫出寶箱
##   ・寶箱跳出來之前到開完之間，暫停選單（暫停鍵、Esc、手機返回鍵）打不開
##   ・開完以後寶箱有領到
## 坐標方格（直線與圓）：滾輪、雙指縮放之後，點下去的位置還是對的格子點；雙指捏合不會順便放點


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
	await _check_plane_zoom()
	finish("GUARDS")


const LineLevel := preload("res://data/levels/line/line_level.gd")


func _mb(btn: int, p: Vector2, down := true) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = btn
	e.pressed = down
	e.position = p
	e.factor = 1.0
	return e


func _touch(i: int, p: Vector2, down: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = i
	e.position = p
	e.pressed = down
	return e


func _tdrag(i: int, p: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = i
	e.position = p
	return e


func _check_plane_zoom() -> void:
	var pl = LineLevel.CoordPlane.new()
	root.add_child(pl)
	pl.size = Vector2(900, 290)
	pl.reset({"x": [-3, 8], "y": [-1, 8], "shapes": []})
	pl.pick_on("M", 1.0, func(_p): pass)
	await frames(2)
	# 滾輪放大兩格：以游標為中心
	var at: Vector2 = pl._to(Vector2(2, 4))
	pl._gui_input(_mb(MOUSE_BUTTON_WHEEL_UP, at))
	pl._gui_input(_mb(MOUSE_BUTTON_WHEEL_UP, at))
	ok(pl.zoom > 1.3, "滾輪放大（%.2f 倍）" % pl.zoom)
	ok(pl._to(Vector2(2, 4)).distance_to(at) < 0.5, "以游標的位置為中心放大")
	pl._gui_input(_mb(MOUSE_BUTTON_LEFT, pl._to(Vector2(3, 5)) + Vector2(4, -3)))
	ok(pl.pick.is_equal_approx(Vector2(3, 5)), "放大之後點下去：(3, 5)，實際 %s" % pl.pick)
	# 縮小回去不會比原本還小
	for k in 10:
		pl._gui_input(_mb(MOUSE_BUTTON_WHEEL_DOWN, at))
	ok(is_equal_approx(pl.zoom, 1.0) and pl.pan.length() < 1e-6, "縮小最多回到原本大小")
	# 手機：第一根手指放下（也會模擬成滑鼠）→ 第二根手指放下 → 張開 → 放開
	var before: Vector2 = pl.pick
	var a := pl._to(Vector2(0, 2))
	var b := pl._to(Vector2(1, 3))
	pl._gui_input(_touch(0, a, true))
	pl._gui_input(_mb(MOUSE_BUTTON_LEFT, a))
	pl._gui_input(_touch(1, b, true))
	ok(pl.pick.is_equal_approx(before), "第二根手指放下：第一根手指剛放的點不算")
	pl._gui_input(_tdrag(0, a + (a - b) * 0.5))
	pl._gui_input(_tdrag(1, b + (b - a) * 0.5))
	ok(pl.zoom > 1.5, "雙指張開放大（%.2f 倍）" % pl.zoom)
	var m := InputEventMouseMotion.new()
	m.position = a + Vector2(30, 30)
	m.button_mask = MOUSE_BUTTON_MASK_LEFT
	pl._gui_input(m)
	ok(pl.pick.is_equal_approx(before), "捏合中拖動手指不會移動點")
	pl._gui_input(_touch(1, b, false))
	pl._gui_input(_touch(0, a, false))
	pl._gui_input(_touch(0, pl._to(Vector2(4, 1)), true))
	pl._gui_input(_mb(MOUSE_BUTTON_LEFT, pl._to(Vector2(4, 1))))
	ok(pl.pick.is_equal_approx(Vector2(4, 1)), "手指都放開之後，再點一下可以放點：%s" % pl.pick)
	# 「還原」
	pl._gui_input(_mb(MOUSE_BUTTON_LEFT, pl._reset_rect().get_center()))
	ok(is_equal_approx(pl.zoom, 1.0), "按「還原」回到原本大小")
	pl.pick_off()
	pl.queue_free()
	await frames(2)
