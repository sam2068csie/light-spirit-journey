extends "res://tests/test_base.gd"
var lv
func _go(file: String) -> void:
	g.goto(file)
	await wait(0.8)
	lv = current_scene
	for n in lv.get_children():
		if n is Control and n.mouse_filter == Control.MOUSE_FILTER_STOP and n.get_index() > 3:
			n.queue_free()
	await frames()
	lv.journey_mode = true
func _start(bank, id: String, vi: int, skip: int) -> void:
	var slot
	for s in bank.slots():
		if s.id == id:
			slot = s
	lv.rounds = [lv.make_round(slot, slot.variants[vi])]
	lv.ri = 0
	lv._start_round()
	await frames(3)
	lv._intro_finish()
	await wait(0.4)
	for k in skip:
		var st: Dictionary = lv.steps[lv.si]
		if st.kind == "choice":
			lv._on_answer(int(lv.cur_q.correct))
		elif st.kind == "fill":
			lv.slot_vals = Array(st.answers).map(func(a): return String(a).replace("-", "−"))
			lv._fill_submit()
		else:
			lv.test_answer(st)
			lv._custom_go()
		await wait(0.3)
func _initialize() -> void:
	await setup()
	await _go("res://data/levels/line/level_line1_coord.gd")
	var B1 = load("res://data/levels/line/line1_bank.gd")
	await _start(B1, "mid", 0, 1)
	lv._pv().plane.pick = Vector2(4, 3)
	lv._custom_go()
	await wait(0.2)
	await shot("f1_miss")
	lv._pv().plane.pick = Vector2(2, 4)
	lv._custom_go()
	await wait(0.3)
	await shot("f2_burst")
	await _go("res://data/levels/line/level_line2_pier.gd")
	var B2 = load("res://data/levels/line/line2_bank.gd")
	await _start(B2, "slopeint", 0, 0)
	lv.slide_vals["m"] = 1.0
	lv.slide_vals["k"] = 1.0
	lv._refresh_slide()
	lv._custom_go()
	await wait(0.4)
	await shot("f3_fall")
	lv.slide_vals["m"] = 0.5
	lv.slide_vals["k"] = -2.0
	lv._refresh_slide()
	lv._custom_go()
	await wait(0.6)
	await shot("f4_lay")
	await wait(1.2)
	await shot("f5_laid")
	await _start(B2, "shift", 0, 3)
	await wait(0.5)
	await shot("f6_shift")
	finish("TMP")
