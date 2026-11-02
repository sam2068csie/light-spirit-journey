extends "test_base.gd"
## 3. 主要畫面都能打開（有設定 SHOTS 時順便截圖，方便看畫面有沒有跑掉）


func _open(file: String, args := {}) -> Node:
	g.goto(file, args)
	await wait(1.0)
	var sc = current_scene
	ok(sc != null and String(sc.get_script().resource_path).ends_with(file), "打開 %s" % file)
	return sc


func _initialize() -> void:
	await setup()
	var mm = await _open("main_menu.gd")
	await shot("main_menu")
	if mm:
		mm._show_page("units")
		await wait(0.8)
		await shot("world_g11")
		mm._set_grade("高一")
		await wait(1.2)
		await shot("world_g10")
		g.set_unit("exp")
		mm._ensure_map()
		mm._show_page("levels")
		await wait(0.8)
		await shot("map_exp")
		g.set_unit("trig")
		mm._ensure_map()
		mm._show_page("levels")
		await wait(0.8)
		await shot("map_trig")
	await _open("house.gd")
	await shot("house")
	await _open("main_menu.gd", {"page": "review"})
	await shot("review")
	finish("SCENES")
