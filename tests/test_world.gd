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


## 高斯在高一地圖上到處亂晃：一直站在能走的地方、真的會走遠；光靈走近就停下來揮手、待久了笑
func _check_gauss() -> void:
	var w = await _world("高一")
	ok(w != null and w.has_method("_gauss_tick"), "高一：地圖上有高斯")
	w.pos = Vector2(6800, 600)                 # 光靈站遠一點，不要打擾他
	w._gauss = {}
	w._gauss_tick(0.0)
	var start: Vector2 = w._gauss.p
	ok(w._free(start), "高斯：一開始站在能走的地方")
	var bad := 0
	var far := 0.0
	var walked := false
	var stopped := false
	for i in 6000:                             # 模擬 5 分鐘
		w._gauss_tick(0.05)
		var gp: Vector2 = w._gauss.p
		if not w._free(gp):
			bad += 1
		far = maxf(far, gp.distance_to(start))
		walked = walked or float(w._gauss.step) >= 0.0
		stopped = stopped or float(w._gauss.wait) > 0.0
	ok(bad == 0, "高斯：一直走在能走的地方（%d 次不在）" % bad)
	ok(walked and stopped, "高斯：會走、也會停下來")
	ok(far > 900.0, "高斯：會晃到遠的地方（最遠 %.0f）" % far)
	var gp: Vector2 = w._gauss.p
	w.pos = gp + Vector2(-150, 0)
	w._gauss_tick(0.05)
	ok(String(w._gauss.mood) == "talk" and float(w._gauss.step) < 0.0 and bool(w._gauss.left), "高斯：光靈走近 → 停下來、轉向光靈揮手")
	for i in 60:
		w._gauss_tick(0.05)
	ok(String(w._gauss.mood) == "happy" and (w._gauss.p as Vector2) == gp, "高斯：光靈待久了 → 笑，而且不走開")
	w.cam = gp
	await wait(0.3)
	await shot("world_gauss")
	w.pos = Vector2(6800, 600)
	for i in 200:
		w._gauss_tick(0.05)
	ok(String(w._gauss.mood) != "talk", "高斯：光靈走開 → 繼續晃")
	await _check_gauss_talk(w)


## 跟高斯聊天：靠近出現「聊聊」、對話框一句一句說完會關掉；六個故事都聽得到，聽過的先不重複
func _check_gauss_talk(w) -> void:
	w._state().erase("gauss_heard")
	w._state().erase("gauss_last")
	var gp := Vector2.ZERO
	for q in w.GAUSS_STARTS:
		w._gauss = {}
		w._gauss_tick(0.0)
		if w._gauss_spot_ok(w._gauss.p):
			gp = w._gauss.p
			break
	ok(gp != Vector2.ZERO, "高斯：找得到一個不在入口旁邊的位置")
	w.pos = gp + Vector2(-120, 0)
	w.cam = w.pos
	w._gauss_tick(0.05)
	w._check_world(0.0)
	ok(String(w._near.get("kind", "")) == "gauss", "高斯：靠近 → 可以聊聊")
	await wait(0.2)
	ok(w._card.visible and w._card_btn.text == "聊聊", "高斯：下方卡片顯示「聊聊」")
	var seen := {}
	for n in 6:
		w._interact()
		var talk = w._overlay
		ok(talk != null and talk.has_method("say"), "高斯：第 %d 次聊天打開對話框" % (n + 1))
		if talk == null:
			return
		if n == 0:
			ok(String(talk.lines[0].text).contains("我是高斯"), "高斯：第一次見面先自我介紹")
			await wait(0.3)
			await shot("gauss_talk")
		var story := String(w._state().gauss_last)
		ok(not seen.has(story), "高斯：還沒聽過的故事先說（第 %d 個：%s）" % [n + 1, story])
		seen[story] = true
		var guard := 0
		while is_instance_valid(talk) and not talk.is_queued_for_deletion() and guard < 40:
			talk._next()
			talk._next()
			guard += 1
		await wait(0.05)
		ok(not is_instance_valid(w._overlay), "高斯：說完最後一句，對話框關掉")
	ok(seen.size() == 6 and (w._state().gauss_heard as Array).size() == 6, "高斯：六個故事都聽過了")
	var last := String(w._state().gauss_last)
	w._interact()
	ok(String(w._state().gauss_last) != last, "高斯：全部聽過之後，不會連續說同一個")
	w.close_overlay()
	# 每一句都放得進對話框（最多三行）
	var lab: Label = null
	var probe = w.NpcTalk.open(w, [{"who": "高斯", "mood": "talk", "text": "測試"}])
	await wait(0.1)
	lab = probe._label
	var font := lab.get_theme_font("font")
	var fs := lab.get_theme_font_size("font_size")
	var worst := 0
	for k in w.GaussNpc.TALKS:
		for ln in w.GaussNpc.TALKS[k]:
			var lines := int(ceil(font.get_string_size(String(ln[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x / lab.size.x))
			worst = maxi(worst, lines)
	ok(worst <= 3, "高斯：每一句最多三行（最長 %d 行）" % worst)
	probe.close()


func _initialize() -> void:
	await setup()
	g.power_save = false
	await _check("高二", "trig", "trig", Vector2(1500, 900), Vector2(5000, 3800))
	await _check("高一", "poly", "h1poly", Vector2(2760, 2600), Vector2(6000, 600))
	await _check_gauss()
	finish("WORLD")
