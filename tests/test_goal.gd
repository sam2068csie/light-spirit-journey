extends "res://tests/test_base.gd"
## 主線目標
##   ・主線只在自己的年級裡找：高一不會被帶去光潮群島；高二一進來不會被帶去曦光大陸
##   ・這次段考範圍（可以複選）排在主線第一順位，其他照課本順序
##   ・學期看日期：7/1～隔年 1/31 上學期、2/1～6/30 下學期；換學期要再問一次段考範圍
##   ・「這次段考考什麼？」視窗：選了就存起來；地圖這學期還沒問過會自動跳出來；切換地圖分頁不會改身分

const Center := preload("res://data/core/review_center.gd")
const Units := preload("res://data/core/units.gd")
const WS := preload("res://data/maps/world_story.gd")
const ExamPick := preload("res://data/ui/exam_pick.gd")
const FirstRun := preload("res://data/core/first_run.gd")

var _added := []


func _light_unit(uid: String) -> void:
	Center.build()
	for l in Units.unit(uid).levels:
		for sid in Center._slots.get(String(l.id), []):
			var k := String(l.id) + "/" + String(sid)
			if g.mark_cleared(k, 0):
				_added.append(k)


func _cleanup() -> void:
	for k in _added:
		g.cleared.erase(k)
	var cf := ConfigFile.new()
	for k in g.cleared:
		cf.set_value("cleared", k, g.cleared[k])
	cf.save("user://cleared.cfg")
	_added.clear()


func _find_text(n: Node, txt: String) -> Control:
	if (n is Label or n is Button) and String(n.text).begins_with(txt) and (n as Control).is_visible_in_tree():
		return n
	for c in n.get_children():
		var f := _find_text(c, txt)
		if f != null:
			return f
	return null


func _initialize() -> void:
	await setup()
	# 學期
	ok(Units.term_now("高二", 7) == "高二上" and Units.term_now("高二", 12) == "高二上" and Units.term_now("高二", 1) == "高二上", "7 月～隔年 1 月是上學期")
	ok(Units.term_now("高一", 2) == "高一下" and Units.term_now("高一", 6) == "高一下", "2 月～6 月是下學期")
	var t2 := Units.term_now("高二")
	var t1 := Units.term_now("高一")

	# 主線只看自己的年級
	g.exam_pick = {"高一": {"term": t1, "units": []}, "高二": {"term": t2, "units": []}}
	var first2 := ""
	for u in Units.term_units(t2) + Units.UNITS:
		if Units.grade_of(u.id) == "高二" and Units.is_open(u) and not u.levels.is_empty() and not WS.unit_lit(g, u):
			first2 = u.id
			break
	ok(String(WS.next_goal(g, "高二").get("uid", "")) == first2 and Units.grade_of(first2) == "高二", "高二：主線不會帶去曦光大陸（%s）" % first2)
	ok(Units.grade_of(String(WS.next_goal(g, "高一").get("uid", "h1poly"))) == "高一", "高一：主線在曦光大陸")
	# 高一把自己年級開放的單元都點亮了：主線不會跑去高二
	for u in Units.UNITS:
		if Units.grade_of(u.id) == "高一" and Units.is_open(u) and not u.levels.is_empty():
			_light_unit(u.id)
	ok(WS.next_goal(g, "高一").is_empty(), "高一全部點亮：主線不會帶去光潮群島")
	g.grade_pick = "高一"
	ok(WS.goal_text(g, "高一").contains("曦光大陸開放的聖地全部點亮了") and not WS.goal_text(g, "高一").contains("光潮群島"), "高一全部點亮：橫幅不提預習")
	_cleanup()

	# 段考範圍排第一順位
	g.grade_pick = "高二"
	WS.set_exam_pick(g, "高二", ["exp"])
	ok(String(WS.next_goal(g, "高二").get("uid", "")) == "exp", "段考範圍選指對數：主線先去指對數")
	ok(WS.goal_text(g, "高二").begins_with("★ 段考範圍：點亮「指數與對數」"), "橫幅寫「段考範圍」")
	ok(WS.goal_text(g, "高一").contains("搭船到光潮群島"), "在曦光大陸看：提示搭船回光潮群島")
	_light_unit("exp")
	ok(String(WS.next_goal(g, "高二").get("uid", "")) == "trig" and not bool(WS.next_goal(g, "高二").exam), "段考範圍點亮了：接著照課本順序（三角函數）")
	_cleanup()
	# 上學期選的，到下學期不算數
	g.exam_pick["高二"] = {"term": "高二下" if t2 == "高二上" else "高二上", "units": ["exp"]}
	ok(WS.exam_units(g, "高二").is_empty() and WS.needs_exam_pick(g, "高二"), "換學期：之前選的段考範圍不算，要再問一次")

	# 先跳出什麼的順序（first_run.gd）
	var keep := [g.grade_pick, g.stars, g.cleared, g.story_seen.duplicate()]
	g.grade_pick = ""
	g.stars = {}
	g.cleared = {}
	ok(FirstRun.menu_step(g, {}) == "grade", "第一次打開主畫面：先選身分")
	g.grade_pick = keep[0]
	g.stars = keep[1]
	g.cleared = keep[2]
	g.story_seen.erase("world/g11")
	ok(FirstRun.map_step(g, "g11", "高二") == "prologue", "第一次打開光潮群島：先播序章")
	g.story_seen.append("world/g11")
	var want := "souvenir" if WS.pending_souvenir(g, "高二") != "" else "exam"
	ok(FirstRun.map_step(g, "g11", "高二") == want, "看過序章、換學期：接著是 %s" % want)
	g.story_seen = keep[3]

	# 視窗：選指對數 → 確定
	g.goto("main_menu.gd")
	await wait(0.8)
	var mm = current_scene
	var layer := ExamPick.open(mm, "高二")
	await frames(2)
	ok(_find_text(layer, "這次段考考什麼？") != null, "視窗打開")
	var okb := _find_text(layer, "確定") as Button
	ok(okb != null and okb.disabled, "還沒選單元：確定按不下去")
	var eb := _find_text(layer, "指數與對數")
	if eb == null:
		eb = _find_text(layer, "✓ 指數與對數")
	var ebtn: Button = eb.get_parent().get_parent() if eb != null else null
	ok(ebtn is Button, "看得到這學期的單元「指數與對數」")
	if ebtn is Button and not ebtn.disabled:
		ebtn.pressed.emit()
		await frames(2)
	okb = _find_text(layer, "確定") as Button
	ok(okb != null and not okb.disabled, "選了單元：確定可以按")
	if okb != null:
		okb.pressed.emit()
	await frames(2)
	ok(not is_instance_valid(layer) or layer.is_queued_for_deletion(), "按確定：視窗關掉")
	ok(g.grade_pick == "高二" and WS.exam_units(g, "高二") == ["exp"], "存下身分和段考範圍")

	# 地圖：這學期還沒問過 → 自動跳出來；切換分頁不改身分
	g.exam_pick.erase("高二")
	mm._grade = "高二"
	mm._show_page("units")
	await wait(2.5)
	var pop := _find_text(mm, "這次段考考什麼？")
	ok(pop != null, "這學期還沒選段考範圍：打開地圖會問")
	var us := _find_text(mm, "還不確定") as Button
	if us != null:
		us.pressed.emit()
	await frames(3)
	ok(not WS.needs_exam_pick(g, "高二") and WS.exam_units(g, "高二").is_empty(), "還不確定：照課本順序，這學期不再問")
	mm._set_grade("高一")
	await wait(0.6)
	ok(g.grade_pick == "高二", "切換到高一的地圖看看：身分還是高二")
	g.exam_pick = {"高一": {"term": t1, "units": []}, "高二": {"term": t2, "units": []}}
	g.save_review()
	finish("GOAL")
