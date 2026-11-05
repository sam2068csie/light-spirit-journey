extends "res://tests/test_base.gd"
## 美術檢查用的截圖（不判斷對錯，存下來給人看）：SHOTS=/tmp/s xvfb-run -a tests/run_tests.sh shots
##   ・level_<單元>_<關>.png：每一關第一段旅程的第一題（背景、粒子、題目有沒有被擋到）
##   ・world_<年級>_<地區>_<0|5|10>.png：大地圖每個開放的地區／島，完成度 0%、50%、100% 的樣子
##   ONLY=levels 或 ONLY=worlds 只拍其中一種

const Units := preload("res://data/core/units.gd")
const Paths := preload("res://data/core/paths.gd")


func _levels() -> void:
	for u in Units.UNITS:
		for l in u.levels:
			if String(l.get("file", "")) == "" or String(l.get("bank", "")) == "":
				continue
			g.goto(String(l.file))
			await wait(0.8)
			var lv = current_scene
			for n in lv.get_children():
				if n is Control and n.mouse_filter == Control.MOUSE_FILTER_STOP and n.get_index() > 3:
					n.queue_free()
			await frames()
			if lv.has_method("make_round"):
				var bank = load(Paths.of(String(l.bank)))
				lv.journey_mode = true
				var slot = bank.slots()[0]
				lv.rounds = [lv.make_round(slot, slot.variants[0])]
				lv.ri = 0
				lv._start_round()
				await frames(3)
				if lv.get("intro_block") != null:
					lv._intro_finish()
			await wait(1.5)
			await shot("level_%s_%s" % [u.id, l.id])
			ok(true, "")


func _worlds() -> void:
	for grade in ["高一", "高二"]:
		g.grade_pick = grade
		g.goto("main_menu.gd")
		await wait(0.8)
		var mm = current_scene
		mm._grade = grade
		mm._show_page("units")
		await wait(1.0)
		var w = mm._units_body.get_child(0)
		w._zoom_lock = true
		for key in w._light_keys():
			if not w._lit_mat.has(key) or not w._open.has(key):
				continue
			var c: Vector2 = (w._light_box(key) as Rect2).get_center()
			for k in [0.0, 0.5, 1.0]:
				w.debug_lit = k
				w._apply_light()
				w.pos = c
				w.cam = c
				w.zoom = 0.3
				await wait(0.8)
				await shot("world_%s_%s_%d" % ["g10" if grade == "高一" else "g11", key, int(k * 10)])
				ok(true, "")
		w.debug_lit = -1.0


func _initialize() -> void:
	await setup()
	g.power_save = false
	if OS.get_environment("SHOTS") == "" or DisplayServer.get_name() == "headless":
		print("（沒有設定 SHOTS 或是 headless：不拍）")
		finish("SHOTS")
		return
	var only := OS.get_environment("ONLY")
	if only == "" or only == "levels":
		await _levels()
	if only == "" or only == "worlds":
		await _worlds()
	finish("SHOTS")
