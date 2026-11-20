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


## 散步的數學家（高斯、拉馬努金）在高一地圖上到處亂晃：一直站在能走的地方、真的會走遠；光靈走近就停下來揮手、待久了笑
func _check_npcs() -> void:
	var w = await _world("高一")
	ok(w != null and w.has_method("_npc_tick"), "高一：地圖上有散步的數學家")
	w.pos = Vector2(6800, 600)                 # 光靈站遠一點，不要打擾他們
	w._npcs = []
	w._npc_tick(0.0)
	ok(w._npcs.size() == 3 and w._npc("gauss").size() > 0 and w._npc("ramanujan").size() > 0 and w._npc("newton").size() > 0, "高斯、拉馬努金、牛頓都在")
	var start := {}
	for n in w._npcs:
		start[n.id] = n.p
		ok(w._free(n.p), "%s：一開始站在能走的地方" % n.script.NAME)
	var bad := 0
	var far := {"gauss": 0.0, "ramanujan": 0.0, "newton": 0.0}
	var walked := {}
	var close := 0
	for i in 6000:                             # 模擬 5 分鐘
		w._npc_tick(0.05)
		for n in w._npcs:
			if not w._free(n.p):
				bad += 1
			far[n.id] = maxf(far[n.id], (n.p as Vector2).distance_to(start[n.id]))
			if float(n.step) >= 0.0:
				walked[n.id] = true
		for a in w._npcs.size():
			for b in range(a + 1, w._npcs.size()):
				if (w._npcs[a].p as Vector2).distance_to(w._npcs[b].p) < 60.0:
					close += 1
	ok(bad == 0, "NPC：一直走在能走的地方（%d 次不在）" % bad)
	ok(walked.size() == 3, "NPC：三位都會走")
	ok(far.gauss > 900.0 and far.ramanujan > 900.0 and far.newton > 900.0, "NPC：都會晃到遠的地方（高斯 %.0f、拉馬努金 %.0f、牛頓 %.0f）" % [far.gauss, far.ramanujan, far.newton])
	ok(close < 450, "NPC：不會一直擠在一起（%d 幀）" % close)
	var g: Dictionary = w._npc("gauss")
	var gp: Vector2 = g.p
	w.pos = gp + Vector2(-150, 0)
	w._npc_tick(0.05)
	ok(String(g.mood) == "talk" and float(g.step) < 0.0 and bool(g.left), "高斯：光靈走近 → 停下來、轉向光靈揮手")
	for i in 60:
		w._npc_tick(0.05)
	ok(String(g.mood) == "happy" and (g.p as Vector2) == gp, "高斯：光靈待久了 → 笑，而且不走開")
	w.pos = Vector2(6800, 600)
	for i in 200:
		w._npc_tick(0.05)
	ok(String(g.mood) != "talk", "高斯：光靈走開 → 繼續晃")
	for id in ["gauss", "ramanujan", "newton"]:
		await _check_npc_talk(w, id)


## 跟 NPC 聊天：靠近出現「聊聊」、對話框一句一句說完會關掉；六個故事都聽得到，聽過的先不重複
func _check_npc_talk(w, id: String) -> void:
	for k in ["npc", "gauss_heard", "gauss_last"]:
		w._state().erase(k)
	w._npcs = []
	w._npc_tick(0.0)
	var n: Dictionary = w._npc(id)
	var nm: String = n.script.NAME
	# 找一個不在入口旁邊的位置，另一位移到遠處
	var gp := Vector2.ZERO
	for q in w.NPC_STARTS:
		if w._free(q) and w._npc_spot_ok(q, n):
			gp = q
			break
	ok(gp != Vector2.ZERO, "%s：找得到一個不在入口旁邊的位置" % nm)
	n.p = gp
	n.goal = gp
	for o in w._npcs:
		if o.id != id:
			o.p = gp + Vector2(1600, 0)
			o.goal = o.p
	w.pos = gp + Vector2(-120, 0)
	w.cam = w.pos
	w._npc_tick(0.05)
	w._check_world(0.0)
	ok(String(w._near.get("kind", "")) == "npc" and w._npcs[int(w._near.get("i", -1))].id == id, "%s：靠近 → 可以聊聊" % nm)
	await wait(0.2)
	ok(w._card.visible and w._card_btn.text == "聊聊" and w._card_title.text == nm, "%s：下方卡片顯示名字和「聊聊」" % nm)
	var seen := {}
	var total: int = n.script.TALKS.size()
	for k in total:
		w._interact()
		var talk = w._overlay
		ok(talk != null and talk.has_method("say"), "%s：第 %d 次聊天打開對話框" % [nm, k + 1])
		if talk == null:
			return
		if k == 0:
			ok(String(talk.lines[0].text).contains("我是" + nm) or String(talk.lines[0].text).contains("我叫" + nm), "%s：第一次見面先自我介紹" % nm)
			ok(talk.lines[0].get("npc") == n.script, "%s：頭像畫的是他自己" % nm)
			await wait(0.6)
			await shot("npc_talk_%s" % id)
		var story := String(w._state().npc[id].last)
		ok(not seen.has(story), "%s：還沒聽過的故事先說（第 %d 個：%s）" % [nm, k + 1, story])
		seen[story] = true
		var guard := 0
		while is_instance_valid(talk) and not talk.is_queued_for_deletion() and guard < 40:
			talk._next()
			talk._next()
			guard += 1
		await wait(0.05)
		ok(not is_instance_valid(w._overlay), "%s：說完最後一句，對話框關掉" % nm)
	ok(seen.size() == total and total == 6, "%s：六個故事都聽過了" % nm)
	var last := String(w._state().npc[id].last)
	w._interact()
	ok(String(w._state().npc[id].last) != last, "%s：全部聽過之後，不會連續說同一個" % nm)
	w.close_overlay()
	# 每一句都放得進對話框（最多三行）
	var probe = w.NpcTalk.open(w, [{"who": nm, "npc": n.script, "mood": "talk", "text": "測試"}])
	await wait(0.1)
	var lab: Label = probe._label
	var font := lab.get_theme_font("font")
	var fs := lab.get_theme_font_size("font_size")
	var worst := 0
	for key in n.script.TALKS:
		for ln in n.script.TALKS[key]:
			worst = maxi(worst, int(ceil(font.get_string_size(String(ln[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x / lab.size.x)))
	ok(worst <= 3, "%s：每一句最多三行（最長 %d 行）" % [nm, worst])
	probe.close()


func _initialize() -> void:
	await setup()
	g.power_save = false
	await _check("高二", "trig", "trig", Vector2(1500, 900), Vector2(5000, 3800))
	await _check("高一", "poly", "h1poly", Vector2(2760, 2600), Vector2(6000, 600))
	await _check_npcs()
	finish("WORLD")
