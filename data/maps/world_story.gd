extends RefCounted
## 大地圖（曦光大陸、光潮群島）的主線故事、教學引導和「主線目標」
##   ・第一次打開某個年級的大地圖：播放那張地圖的序章，接著光靈帶你看操作（聚光燈教學）
##   ・點亮一個單元的所有聖地之後，回到大地圖會播一小段（紀念品送到小屋）
##   ・畫面上方的「主線」橫幅＋金色箭頭：告訴學生下一步該去哪裡
## 劇情的 key 都加上 "world/"，存在 Game.story_seen。
const Game := preload("res://data/core/game.gd")
const Units := preload("res://data/core/units.gd")
const Center := preload("res://data/core/review_center.gd")
const SA := preload("res://data/house/souvenir_art.gd")
const UITheme := preload("res://data/ui/game_theme.gd")
const StoryPlayer := preload("res://data/maps/story_player.gd")

## 每一句：{text, who（"光靈" 或空白＝旁白）, focus（鏡頭看哪裡：地圖座標；可以是字串，由地圖自己解讀）}
const STORY := {
	"g10": [
		{"text": "數學世界原本由無數座「聖地」照亮，每座都守著一個數學祕密。", "focus": "wide"},
		{"text": "直到某天，混亂之霧湧來。曲線斷裂、數字失序，聖地的光一盞一盞熄滅了……", "focus": "wide"},
		{"text": "曦光大陸的西南角，有一間小木屋。屋裡還亮著一顆小小的光——", "focus": "house"},
		{"text": "……嗯？早、早安！我是光靈！外面怎麼霧濛濛的？", "who": "光靈", "focus": "house"},
		{"text": "解開聖地的謎題，光就會回來。我們一起把世界點亮吧！", "who": "光靈", "focus": "house"},
		{"text": "曦光大陸的九個地區，就是高一的九個單元，想先去哪都可以。", "focus": "zones"},
		{"text": "東南邊的渡口可以搭船到高二的光潮群島。", "focus": "ferry"},
		{"text": "點亮一個單元的聖地，就能帶回一件紀念品喔！", "who": "光靈", "focus": "house"},
	],
	"g11": [
		{"text": "渡船穿過晨霧，駛進一片閃著微光的海——光潮群島。", "focus": "harbor"},
		{"text": "七座島各守著高二的一個單元，想先去哪座都可以。", "focus": "wide"},
		{"text": "哇，好多島！開船過去吧～", "who": "光靈", "focus": "harbor"},
		{"text": "你看，雙島那邊還有一點點光在閃……先去那裡看看好不好？", "who": "光靈", "focus": "goal"},
	],
}
const TITLES := {"g10": "序章．熄滅的世界", "g11": "第二章．光潮群島"}


static func seen(g, key: String) -> bool:
	return g.story_seen.has("world/" + key)


## 單元的聖地點亮了幾座（每個大關的旅程都至少通過一次 = 一座）
static func lit_count(g, u: Dictionary) -> Array:
	var n := 0
	for l in u.levels:
		if Center.level_progress(g, l.id) >= 0.999:
			n += 1
	return [n, u.levels.size()]


static func unit_lit(g, u: Dictionary) -> bool:
	var c := lit_count(g, u)
	return c[1] > 0 and c[0] >= c[1]


## 玩家的年級（身分）：沒選過就當作現在看的那張地圖的年級
static func my_grade(g, here_grade: String) -> String:
	return String(g.grade_pick) if String(g.grade_pick) != "" else here_grade


## 這學期的段考範圍（單元 id）；還沒選、或選的是別的學期 → []
static func exam_units(g, grade: String) -> Array:
	var ep: Dictionary = g.exam_pick.get(grade, {})
	if String(ep.get("term", "")) != Units.term_now(grade):
		return []
	return ep.get("units", [])


## 這學期還沒問過段考範圍（換學期了也要再問）
static func needs_exam_pick(g, grade: String) -> bool:
	var ep: Dictionary = g.exam_pick.get(grade, {})
	return String(ep.get("term", "")) != Units.term_now(grade)


static func set_exam_pick(g, grade: String, units: Array) -> void:
	g.exam_pick[grade] = {"term": Units.term_now(grade), "units": units.duplicate()}
	g.save_review()


## 主線目標：只在自己的年級裡找「開放了、但還沒全部點亮」的單元
##   先找這次段考範圍裡的（照課本順序），再照課本順序找其他的；全部點亮回傳 {}
static func next_goal(g, grade: String) -> Dictionary:
	var exam := exam_units(g, grade)
	for pass_i in 2:
		for u in Units.UNITS:
			if Units.grade_of(u.id) != grade or (pass_i == 0) != exam.has(u.id):
				continue
			if Units.is_open(u) and not u.levels.is_empty() and not unit_lit(g, u):
				var c := lit_count(g, u)
				return {"uid": u.id, "title": u.title, "grade": grade, "lit": c[0], "total": c[1], "exam": pass_i == 0}
	return {}


static func world_name(grade: String) -> String:
	return "光潮群島" if grade == "高二" else "曦光大陸"


static func goal_text(g, here_grade: String) -> String:
	var grade := my_grade(g, here_grade)
	var gl := next_goal(g, grade)
	if gl.is_empty():
		return "★ %s開放的聖地全部點亮了！　▾" % world_name(grade)
	var head := "★ 段考範圍：" if bool(gl.exam) else "★ 主線："
	# 結尾的 ▾：點橫幅可以改段考範圍
	if gl.grade != here_grade:
		return head + "搭船到%s，點亮「%s」的聖地（%d／%d）　▾" % [world_name(gl.grade), gl.title, gl.lit, gl.total]
	return head + "點亮「%s」的聖地（%d／%d）　▾" % [gl.title, gl.lit, gl.total]


## 有沒有剛拿到紀念品、還沒播過的小劇情（這個年級的單元）
static func pending_souvenir(g, grade: String) -> String:
	for u in Units.UNITS:
		if Units.grade_of(u.id) != grade or u.levels.is_empty():
			continue
		if unit_lit(g, u) and not seen(g, "sv_" + u.id):
			return u.id
	return ""


static func souvenir_lines(uid: String) -> Array:
	var u := Units.unit(uid)
	var sv := SA.info(uid)
	return [
		{"text": "「%s」的聖地全部點亮了！光回到了這片土地。" % u.title, "focus": "unit"},
		{"text": "拿到紀念品「%s」！已經送到小屋囉～" % sv.name, "who": "光靈", "focus": "unit"},
		{"text": "每種題型都答對，紀念品還會發光喔！", "who": "光靈", "focus": "unit"},
	]


## 播放一段劇情：host 是大地圖（world_base.gd），要有 set_story_playing(on)、story_focus（Vector2，(-1, -1) = 跟著玩家）和 focus_point(name, uid) -> Vector2
static func play(host: Control, key: String, lines: Array, title: String, uid := "") -> void:
	var g = Game.of(host)
	var layer := CanvasLayer.new()
	layer.layer = 40
	host.add_child(layer)
	host.call("set_story_playing", true)
	if host.has_signal("story_changed"):
		host.emit_signal("story_changed", true)
	var pl = StoryPlayer.new()
	pl.title = title
	layer.add_child(pl)
	await pl.intro()
	for st in lines:
		var f = st.get("focus", "")
		host.set("story_focus", host.call("focus_point", String(f), uid))
		await pl.say(String(st.text), String(st.get("who", "")))
		if not is_instance_valid(pl) or pl.skipped:
			break
	if is_instance_valid(pl):
		await pl.outro()
	layer.queue_free()
	host.set("story_focus", Vector2(-1, -1))
	host.call("set_story_playing", false)
	if host.has_signal("story_changed"):
		host.emit_signal("story_changed", false)
	g.mark_story("world/" + key)


## 畫面上方的主線橫幅＋指向目標的金色箭頭（target：螢幕座標；(-1, -1) = 不畫箭頭）
## avoid：畫面上不要蓋到的地方（例如小地圖）；畫面外的箭頭落在裡面時，沿著邊緣讓開
static func draw_goal(ci: CanvasItem, text: String, target: Vector2, t: float, avoid := Rect2()) -> void:
	var font := UITheme.bold_font()
	var fs := 16
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var r := Rect2(Vector2((1152.0 - tw) / 2.0 - 16, 72), Vector2(tw + 32, 32))
	ci.draw_style_box(UITheme.box(Color(0.05, 0.06, 0.16, 0.86), 16, Color(0.96, 0.78, 0.3, 0.7), 2, 0), r)
	ci.draw_string(font, r.position + Vector2(16, 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("ffe7a3"))
	if target.x < -0.5:
		return
	var view := Rect2(40, 120, 1152 - 80, 648 - 170)
	var gold := Color("f5c84c")
	if view.has_point(target):
		# 目標在畫面裡：上方一個上下彈跳的箭頭
		var p := target + Vector2(0, -60 - 8 * absf(sin(t * 3.0)))
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-14, -12), p + Vector2(14, -12), p + Vector2(0, 10)]), gold)
		ci.draw_arc(target, 26 + 6 * sin(t * 3.0), 0, TAU, 32, Color(gold.r, gold.g, gold.b, 0.6), 3.0, true)
	else:
		# 目標在畫面外：畫面邊緣一個指向它的箭頭
		var c := Vector2(576, 380)
		var d := (target - c).normalized()
		var k := INF
		if absf(d.x) > 0.001:
			k = minf(k, ((view.end.x if d.x > 0 else view.position.x) - c.x) / d.x)
		if absf(d.y) > 0.001:
			k = minf(k, ((view.end.y if d.y > 0 else view.position.y) - c.y) / d.y)
		var p := c + d * k - d * (6.0 * absf(sin(t * 4.0)))
		if avoid.has_area() and avoid.grow(30.0).has_point(p):
			if p.x > avoid.position.x:
				p = Vector2(clampf(p.x, view.position.x, view.end.x), avoid.end.y + 36.0)
			else:
				p.x = avoid.position.x - 36.0
		var n := d.orthogonal()
		ci.draw_circle(p - d * 8.0, 24.0, Color(0.05, 0.06, 0.16, 0.7))
		ci.draw_colored_polygon(PackedVector2Array([p + d * 14.0, p - d * 10.0 + n * 13.0, p - d * 10.0 - n * 13.0]), gold)
