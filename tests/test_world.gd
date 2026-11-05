extends "res://tests/test_base.gd"
## 大地圖的「點亮」：完成度 0% 的地區／島是暗的；完成度變高後回到地圖，那一區出現在畫面上就播點亮動畫，最後亮度 = 完成度
##   高一（曦光大陸）用「根之洞窟」（多項式）、高二（光潮群島）用「月輪島」（三角函數）

const Center := preload("res://data/core/review_center.gd")
const Units := preload("res://data/core/units.gd")


func _clear_level(lid: String) -> void:
	Center.build()
	for sid in Center._slots.get(lid, []):
		g.mark_cleared(lid + "/" + sid, 0)


func _world(grade: String):
	g.grade_pick = grade
	g.goto("main_menu.gd")
	await wait(0.8)
	var mm = current_scene
	mm._grade = grade
	mm._show_page("units")
	await wait(0.8)
	return mm._units_body.get_child(0)


func _lit_param(w, key: String) -> float:
	return float((w._lit_mat[key] as ShaderMaterial).get_shader_parameter("lit"))


## 這個單元回到「還沒玩過、地圖沒看過」（存檔在 user://：本機重跑、接著跑別的測試都要乾淨）
func _reset(unit: String) -> void:
	var u: Dictionary = Units.unit(unit)
	for l in u.levels:
		for k in g.cleared.keys():
			if String(k).begins_with(String(l.id) + "/"):
				g.cleared.erase(k)
	var cf := ConfigFile.new()
	for k in g.cleared:
		cf.set_value("cleared", k, g.cleared[k])
	cf.save("user://cleared.cfg")
	g.world10.erase("lit_seen")
	g.world11.erase("lit_seen")
	g.save_review()


func _check(grade: String, key: String, unit: String, focus: Vector2, far: Vector2) -> void:
	_reset(unit)
	var u: Dictionary = Units.unit(unit)
	var w = await _world(grade)
	ok(w != null and w.has_method("_apply_light"), "%s：找得到大地圖" % grade)
	w._apply_light()
	ok(w.light_k(key) < 0.001 and _lit_param(w, key) < 0.001, "%s：還沒點亮的「%s」是暗的" % [grade, key])
	ok(absf(float(w._lit_seen().get(key, -1.0))) < 0.001, "%s：第一次看到就記下亮度（不播動畫）" % grade)
	# 先把鏡頭移到別處：完成度變高了，但那一區不在畫面上 → 動畫先等著
	w.pos = far
	w.cam = far
	_clear_level(String(u.levels[0].id))
	w._apply_light()
	ok(w._lit_anim.has(key), "%s：完成度變高 → 排一段點亮動畫" % grade)
	await wait(0.5)
	ok(w.light_k(key) < 0.001, "%s：那一區不在畫面上時先不亮" % grade)
	# 走過去：動畫播完，亮度 = 完成度
	w.pos = focus
	w.cam = focus
	await wait(0.6)
	ok(w._lit_anim.has(key) and float(w._lit_anim[key].t) >= 0.0, "%s：那一區出現在畫面上 → 開始點亮" % grade)
	await shot("world_%s_burst" % key)
	await wait(w.LIGHT_DUR + 0.6)
	var want: float = w._light_target(key)
	ok(not w._lit_anim.has(key), "%s：點亮動畫播完" % grade)
	ok(absf(w.light_k(key) - want) < 0.01 and want > 0.05, "%s：亮度 = 完成度（%.2f）" % [grade, want])
	ok(absf(float(w._lit_seen().get(key, -1.0)) - want) < 0.01, "%s：存檔記下看過的亮度" % grade)
	# 全部點亮：恢復原本的樣子（shader 的 lit = 1）
	for l in u.levels:
		_clear_level(String(l.id))
	w._apply_light()
	await wait(w.LIGHT_DUR + 0.8)
	ok(_lit_param(w, key) > 0.999, "%s：全部點亮 → 原本的顏色" % grade)
	ok(absf(float((w._lit_fx[key] as CanvasItem).modulate.a) - 1.0) < 0.001, "%s：全部點亮 → 動態恢復" % grade)
	await shot("world_%s_full" % key)
	_reset(unit)


func _initialize() -> void:
	await setup()
	g.power_save = false
	await _check("高二", "trig", "trig", Vector2(1500, 900), Vector2(5000, 3800))
	await _check("高一", "poly", "h1poly", Vector2(2760, 2600), Vector2(6000, 600))
	finish("WORLD")
