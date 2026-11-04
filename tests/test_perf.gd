extends "res://tests/test_base.gd"
## 效能守門：每個主要畫面一格要送幾次繪圖指令（draw calls）
##   ・數字超過預算就算失敗 → 代表有人把「每格重算／一個一個畫」的東西加回去了
##   ・需要真的有畫面才量得到（headless 模式會直接跳過）
##   ・CI 用 xvfb 跑：SHOTS=/tmp/shots xvfb-run -a tests/run_tests.sh perf

## 各畫面的預算（目前實測值再多留約 25% 空間）
const BUDGET := {
	"main_menu": 95, "world_g11": 400, "world_g10": 250, "map_exp": 600,
	"map_trig": 420, "house": 185, "L1": 230, "L3": 310,
}


func measure(tag: String) -> void:
	await wait(1.0)
	var n := 0
	var dc := 0.0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1000:
		await process_frame
		n += 1
		dc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var calls := int(dc / maxf(1, n))
	var cap: int = BUDGET.get(tag, 0)
	print("PERF %-10s draw calls = %4d（預算 %d）" % [tag, calls, cap])
	if cap > 0:
		ok(calls <= cap, "%s 的 draw calls %d 超過預算 %d" % [tag, calls, cap])
	await shot("perf_" + tag)


func _level(file: String, bank: String, slot: int) -> void:
	g.goto(file)
	await wait(1.0)
	var lv = current_scene
	for c in lv.get_children():
		if c is Control and c.mouse_filter == Control.MOUSE_FILTER_STOP and c.get_index() > 3:
			c.queue_free()
	lv.journey_mode = true
	var s = load(bank).slots()[slot]
	lv.rounds = [lv.make_round(s, s.variants[0])]
	lv.ri = 0
	lv._start_round()


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		print("（headless 模式量不到 draw calls，略過）")
		print("DONE perf skipped")
		quit()
		return
	await setup()
	g.power_save = false
	g.story_seen = ["world/g10", "world/g11", "prologue", "trig/prologue",
		"L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "epilogue"]
	g.goto("main_menu.gd")
	await wait(1.0)
	var mm = current_scene
	await measure("main_menu")
	mm._show_page("units")
	await measure("world_g11")
	mm._set_grade("高一")
	await wait(1.0)
	await measure("world_g10")
	g.set_unit("exp"); mm._ensure_map(); mm._show_page("levels")
	await measure("map_exp")
	g.set_unit("trig"); mm._ensure_map(); mm._show_page("levels")
	await measure("map_trig")
	g.goto("house.gd")
	await measure("house")
	await _level("level_01_light_bridge.gd", "res://data/levels/exp/level01_bank.gd", 0)
	await measure("L1")
	await _level("level_03_scale.gd", "res://data/levels/exp/level03_bank.gd", 3)
	await measure("L3")
	print("DONE perf %d/%d" % [checks - fails, checks])
	quit(1 if fails > 0 else 0)
