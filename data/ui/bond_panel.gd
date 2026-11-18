extends RefCounted
## 光靈親密度的兩個視窗（資料在 game_bond.gd）
##   levelup(host, lv)：升級了！（小屋、主畫面、大地圖都可能跳出來；每次升級只播一次）
##   detail(host)：小屋左下角點開：現在幾級、今天拿了多少、怎麼增加、每一級解鎖什麼
## 兩個都回傳視窗的根節點（關掉時會 queue_free，可以等 tree_exited）
const UITheme := preload("res://data/ui/game_theme.gd")
const Game := preload("res://data/core/game.gd")
const Bond := preload("res://data/core/game_bond.gd")
const SL := preload("res://data/ui/spirit_look.gd")

const PINK := Color("ff8fbf")

## 升級時光靈說的話
const LV_LINES := {
	2: "以後看到你，我都會先跟你打招呼喔！",
	3: "被你摸摸頭的時候……我會有一點害羞。",
	4: "我們是好朋友了！這顆星星送給你～",
	5: "一起讀書的時間，是我最喜歡的時間。",
	6: "你的想法，我好像越來越懂了。",
	7: "就算你漏簽了，我也會多守護你一天。",
	8: "有你在，我一點都不怕黑。",
	9: "你看，我的光變大了！是你讓我長大的。",
	10: "謝謝你一路陪著我。我們的光，會一直亮著。",
}

## 今天的進度（說明視窗）：[種類, 名稱]
const TODAY := [["learn", "答對題目"], ["pet", "摸摸頭"], ["chat", "聊天"], ["daily", "今日修煉"], ["quests", "每日任務全完成"]]


static func levelup(host: Node, lv: int) -> Control:
	var g = Game.of(host)
	var info: Dictionary = Bond.bond_info(lv)
	var o := UITheme.modal(host, PINK, 640)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 12)
	var pic := Portrait.new()
	pic.mood = "shy" if lv == 3 else "happy"
	pic.custom_minimum_size = Vector2(0, 170)
	col.add_child(pic)
	var title := UITheme.title_label("親密度 Lv.%d「%s」" % [lv, info.name], 28, PINK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	col.add_child(_text("「%s」" % LV_LINES.get(lv, "謝謝你陪著我！"), 18, UITheme.TEXT, true))
	var un := String(info.unlock)
	col.add_child(_text(("解鎖：" + un) if info.ready else ("下一次更新開放：" + un), 16, Color("ffd36e") if info.ready else UITheme.TEXT_DIM, true))
	var ok := Button.new()
	ok.text = "好耶！"
	ok.focus_mode = Control.FOCUS_NONE
	ok.custom_minimum_size = Vector2(0, 48)
	UITheme.accent_button(ok, 18)
	ok.pressed.connect(func(): layer.queue_free())
	col.add_child(ok)
	g.sfx("fanfare")
	return layer


static func detail(host: Node) -> Control:
	var g = Game.of(host)
	var pr: Dictionary = g.bond_progress()
	var o := UITheme.modal(host, PINK, 720)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	col.add_child(head)
	var pic := Portrait.new()
	pic.custom_minimum_size = Vector2(110, 96)
	head.add_child(pic)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 6)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(hv)
	hv.add_child(UITheme.title_label("光靈的親密度　Lv.%d %s" % [pr.lv, pr.name], 24, PINK))
	hv.add_child(bar(pr.frac, Vector2(0, 12)))
	var nxt: Dictionary = pr.next
	hv.add_child(_text("已經是最高等級了！" if nxt.is_empty() else "下一級：Lv.%d %s（目前 %d／%d 點）" % [nxt.lv, nxt.name, pr.pts, nxt.need], 14, UITheme.TEXT_DIM))
	# 今天
	var parts := []
	for it in TODAY:
		var cap := int(Bond.BOND_CAP[it[0]])
		parts.append("%s %d／%d" % [it[1], cap - g.bond_left(it[0]), cap])
	col.add_child(_section("今天"))
	col.add_child(_text("、".join(parts), 15, UITheme.TEXT))
	col.add_child(_section("怎麼增加"))
	col.add_child(_text("答對一題 +1（答錯後改對也算）、第一次通過一段旅程 +5、完成觀念卡片 +3、做完今日修煉 +5、每日任務全完成 +5；小屋裡摸摸頭 +1、聊天 +2。親密度只會增加，好幾天沒來也不會變少。", 14, UITheme.TEXT))
	col.add_child(_section("每一級解鎖"))
	for l in Bond.BOND_LEVELS:
		var got := int(l.lv) <= int(pr.lv)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lab := Label.new()
		lab.text = "Lv.%d %s" % [l.lv, l.name]
		lab.custom_minimum_size = Vector2(150, 0)
		lab.add_theme_font_override("font", UITheme.bold_font())
		lab.add_theme_font_size_override("font_size", UITheme.fs(15))
		lab.add_theme_color_override("font_color", PINK if got else UITheme.TEXT_DIM)
		row.add_child(lab)
		var un := _text(String(l.unlock) + ("" if l.ready else "（之後開放）"), 14, UITheme.TEXT if got else UITheme.TEXT_DIM)
		un.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(un)
		col.add_child(row)
	var ok := Button.new()
	ok.text = "關閉"
	ok.focus_mode = Control.FOCUS_NONE
	ok.custom_minimum_size = Vector2(0, 46)
	UITheme.accent_button(ok, 17)
	ok.pressed.connect(func(): layer.queue_free())
	col.add_child(ok)
	g.sfx("open")
	return layer


## 粉紅色的進度條
static func bar(frac: float, sz: Vector2) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 1.0
	b.step = 0.0
	b.value = frac
	b.custom_minimum_size = sz
	b.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.1), 6, Color(0, 0, 0, 0), 0, 0))
	b.add_theme_stylebox_override("fill", UITheme.box(PINK, 6, Color(0, 0, 0, 0), 0, 0))
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


static func _section(s: String) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_override("font", UITheme.bold_font())
	l.add_theme_font_size_override("font_size", UITheme.fs(16))
	l.add_theme_color_override("font_color", Color("ffd36e"))
	return l


static func _text(s: String, fs: int, c: Color, center := false) -> Label:
	var l := Label.new()
	l.text = s
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", UITheme.fs(fs))
	l.add_theme_color_override("font_color", c)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## 光靈的大頭照：開心的臉＋身邊繞著小愛心
class Portrait extends Control:
	var mood := "happy"
	var t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var r := minf(size.y * 0.24, 40.0)
		var c := size / 2.0 + Vector2(-r * 0.2, sin(t * 2.4) * 3.0 + r * 0.1)
		SL.draw_mood(self, c, r, SL.eq_of(self), t, mood)
		for k in 4:
			var a := t * 1.1 + k * TAU / 4.0
			var p := c + Vector2(r * 0.45, 0) + Vector2(cos(a) * r * 1.7, sin(a) * r * 0.75 - r * 0.2)
			SL.heart(self, p, r * 0.16, Color(PINK.r, PINK.g, PINK.b, 0.55 + 0.35 * sin(a)))
