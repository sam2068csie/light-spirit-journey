extends "res://tests/test_base.gd"
## 效能守門：每個主要畫面一格要送幾次繪圖指令（draw calls）
##   ・數字超過預算就算失敗 → 代表有人把「每格重算／一個一個畫」的東西加回去了
##   ・需要真的有畫面才量得到（headless 模式會直接跳過）
##   ・CI 用 xvfb 跑：SHOTS=/tmp/shots xvfb-run -a tests/run_tests.sh perf

## 各畫面的預算（目前實測值再多留約 25% 空間）
const BUDGET := {
	"main_menu": 95, "world_g11": 150, "world_g10": 220, "map_exp": 600,
	"map_trig": 420, "house": 185, "L1": 230, "L3": 310,
	# 多項式、三角函數各關（每關自己的背景 data/ui/scenery.gd）
	"P1": 190, "P2": 170, "P3": 220, "P4": 250, "P5": 285, "P6": 245, "P7": 300, "P8": 320,
	"G1": 225, "G2": 335, "G3": 245, "G4": 215, "G5": 170, "G6": 190, "G7": 190,
	"C1": 270,          # 直線與圓：下方有坐標方格（格線、刻度）
	"C2": 290, "C3": 290, "C4": 300, "C5": 300,
}
## 多項式、三角函數各關：[編號, 關卡檔, 題庫檔]（每關第一段旅程的第一題）
const STEP_LEVELS := [
	["P1", "level_poly1_lamp.gd", "poly1_bank.gd"], ["P2", "level_poly2_wheel.gd", "poly2_bank.gd"],
	["P3", "level_poly3_echo.gd", "poly3_bank.gd"], ["P4", "level_poly4_mold.gd", "poly4_bank.gd"],
	["P5", "level_poly5_lake.gd", "poly5_bank.gd"], ["P6", "level_poly6_wick.gd", "poly6_bank.gd"],
	["P7", "level_poly7_crystal.gd", "poly7_bank.gd"], ["P8", "level_poly8_river.gd", "poly8_bank.gd"],
	["G1", "level_trig1_arc.gd", "trig1_bank.gd"], ["G2", "level_trig2_sector.gd", "trig2_bank.gd"],
	["G3", "level_trig3_wave.gd", "trig3_bank.gd"], ["G4", "level_trig4_tide.gd", "trig4_bank.gd"],
	["G5", "level_trig5_compass.gd", "trig5_bank.gd"], ["G6", "level_trig6_mirror.gd", "trig6_bank.gd"],
	["G7", "level_trig7_lighthouse.gd", "trig7_bank.gd"],
	["C1", "level_line1_coord.gd", "line1_bank.gd"], ["C2", "level_line2_pier.gd", "line2_bank.gd"], ["C3", "level_line3_mirror.gd", "line3_bank.gd"], ["C4", "level_line4_paddy.gd", "line4_bank.gd"], ["C5", "level_line5_compass.gd", "line5_bank.gd"],
]


## 重疊塗色（overdraw）：畫面上每個像素平均被畫了幾層。手機的 GPU 很怕這個（解析度高，每多一層全螢幕就多一次填色）
##   ・量法：把每個畫布換成「加法混色、每畫一次加一點亮度」的材質，截圖看平均亮度
const OD_BUDGET := {"world_g11": 6.0, "world_g10": 11.0}


func measure_od(tag: String) -> void:
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nrender_mode blend_add;\nvoid fragment(){ COLOR = vec4(4.0/255.0, 4.0/255.0, 4.0/255.0, 1.0); }"
	mat.shader = sh
	var old := {}
	_swap_mat(get_root(), mat, old)
	var clear := RenderingServer.get_default_clear_color()
	RenderingServer.set_default_clear_color(Color.BLACK)
	await wait(0.3)
	var img := get_root().get_texture().get_image()
	var sum := 0.0
	var cnt := 0
	for y in range(0, img.get_height(), 6):
		for x in range(0, img.get_width(), 6):
			sum += img.get_pixel(x, y).r * 255.0 / 4.0
			cnt += 1
	for n in old:
		if is_instance_valid(n):
			n.material = old[n]
	RenderingServer.set_default_clear_color(clear)
	var od := sum / maxf(1, cnt)
	var cap: float = OD_BUDGET.get(tag, 0.0)
	print("PERF %-10s overdraw   = %4.1f（預算 %.0f）" % [tag, od, cap])
	ok(od <= cap, "%s 的 overdraw %.1f 超過預算 %.0f" % [tag, od, cap])
	await wait(0.2)


func _swap_mat(n: Node, mat: Material, old: Dictionary) -> void:
	if n is CanvasItem:
		old[n] = (n as CanvasItem).material
		(n as CanvasItem).material = mat
	for c in n.get_children():
		_swap_mat(c, mat, old)


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
	await measure_od("world_g11")
	mm._set_grade("高一")
	await wait(1.0)
	await measure("world_g10")
	await measure_od("world_g10")
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
	var Paths := preload("res://data/core/paths.gd")
	for e in STEP_LEVELS:
		await _level(String(e[1]), Paths.of(String(e[2])), 0)
		await measure(String(e[0]))
	print("DONE perf %d/%d" % [checks - fails, checks])
	quit(1 if fails > 0 else 0)
