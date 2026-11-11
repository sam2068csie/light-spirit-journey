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
		# 版本號連點 7 次：打開開發者功能；點 6 次還不會
		g.dev_mode = false
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		var ver: Label = mm._title_page.find_children("*", "Label", true, false).filter(func(l): return String(l.text).begins_with("版本"))[0]
		for k in 6:
			mm._on_version_tap(ev, ver)
		ok(not g.dev_mode, "版本號點 6 次：開發者功能還沒打開")
		mm._on_version_tap(ev, ver)
		ok(g.dev_mode, "版本號點 7 次：打開開發者功能")
		g.dev_mode = false
		g.save_settings()
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
	var rv = await _open("main_menu.gd", {"page": "review"})
	await wait(0.5)
	await shot("review")
	# 修煉之間的三塊面板都要在畫面裡（沒有錯題紀錄時，右下那塊曾經被撐出畫面）
	if rv:
		for c in rv._review_body.get_children():
			if c is PanelContainer:
				var rc: Rect2 = c.get_global_rect()
				ok(Rect2(0, 0, 1152, 648).encloses(rc), "修煉之間的面板超出畫面：%s" % rc)
	finish("SCENES")
