extends "res://tests/test_base.gd"
func measure(tag: String) -> void:
	await wait(1.0)
	var n := 0
	var proc := 0.0
	var dc := 0.0
	var t0 := Time.get_ticks_usec()
	var worst := 0.0
	while Time.get_ticks_usec() - t0 < 2000000:
		var f0 := Time.get_ticks_usec()
		await process_frame
		var dt := (Time.get_ticks_usec() - f0) / 1000.0
		worst = maxf(worst, dt)
		n += 1
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		dc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	print("BENCH %-14s frame=%.2fms" % [tag, 2000.0 / n])

func _initialize() -> void:
	Engine.max_fps = 0
	await setup()
	g.power_save = false
	g.story_seen = ["world/g10", "world/g11", "prologue", "trig/prologue", "L1","L2","L3","L4","L5","L6","L7","L8","epilogue"]
	var mm
	g.goto("main_menu.gd"); await wait(1.0); mm = current_scene
	await measure("main_menu")
	mm._show_page("units"); await measure("world_g11")
	mm._set_grade("高一"); await wait(1.0); await measure("world_g10")
	g.set_unit("exp"); mm._ensure_map(); mm._show_page("levels"); await measure("map_exp")
	g.set_unit("trig"); mm._ensure_map(); mm._show_page("levels"); await measure("map_trig")
	g.goto("house.gd"); await measure("house")
	g.goto("level_01_light_bridge.gd"); await wait(1.0)
	var lv = current_scene
	for n in lv.get_children():
		if n is Control and n.mouse_filter == Control.MOUSE_FILTER_STOP and n.get_index() > 3: n.queue_free()
	lv.journey_mode = true
	var B = load("res://data/levels/exp/level01_bank.gd")
	var s = B.slots()[0]
	lv.rounds = [lv.make_round(s, s.variants[0])]; lv.ri = 0; lv._start_round()
	await measure("L1 fit")
	g.goto("level_03_scale.gd"); await wait(1.0)
	lv = current_scene
	for n in lv.get_children():
		if n is Control and n.mouse_filter == Control.MOUSE_FILTER_STOP and n.get_index() > 3: n.queue_free()
	lv.journey_mode = true
	B = load("res://data/levels/exp/level03_bank.gd")
	s = B.slots()[3]
	lv.rounds = [lv.make_round(s, s.variants[0])]; lv.ri = 0; lv._start_round()
	await measure("L3 forge")
	quit()
