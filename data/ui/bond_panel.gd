extends RefCounted
## 光靈親密度的兩個視窗（資料在 game_bond.gd）
##   levelup(host, lv)：升級了！（小屋、主畫面、大地圖都可能跳出來；每次升級只播一次）
##   detail(host)：小屋左下角點開：現在幾級、進度條；右上角的「i」點了才展開（今天拿了多少、怎麼增加、每一級的獎勵）
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


## 一打開只看到：光靈、等級、進度條、下一級叫什麼。說明和獎勵藏在右上角的「i」裡，點了才展開
static func detail(host: Node) -> Control:
	var g = Game.of(host)
	var pr: Dictionary = g.bond_progress()
	var o := UITheme.modal(host, PINK, 460)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	# 右上角的資訊按鈕
	var top := HBoxContainer.new()
	col.add_child(top)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var info := Button.new()
	info.name = "Info"
	info.text = "i"
	info.tooltip_text = "親密度怎麼增加、每一級的獎勵"
	info.focus_mode = Control.FOCUS_NONE
	info.custom_minimum_size = Vector2(38, 38)
	info.add_theme_font_override("font", UITheme.bold_font())
	info.add_theme_font_size_override("font_size", UITheme.fs(18))
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		var on: bool = String(st).contains("pressed")
		info.add_theme_stylebox_override(st, UITheme.box(Color(1, 0.56, 0.75, 0.3 if on else 0.08), 19, PINK, 2, 0))
	info.add_theme_color_override("font_color", PINK)
	info.add_theme_color_override("font_hover_color", Color.WHITE)
	info.add_theme_color_override("font_pressed_color", Color.WHITE)
	info.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	top.add_child(info)
	var pic := Portrait.new()
	pic.custom_minimum_size = Vector2(0, 120)
	col.add_child(pic)
	var title := UITheme.title_label("Lv.%d %s" % [pr.lv, pr.name], 26, PINK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	col.add_child(bar(pr.frac, Vector2(0, 12)))
	var nxt: Dictionary = pr.next
	col.add_child(_text("已經是最高等級了！" if nxt.is_empty() else "下一級：%s" % nxt.name, 15, UITheme.TEXT_DIM, true))
	# 說明和獎勵：點 i 才從 i 的位置跳出提示框（原本的視窗不變），點提示框外面就收起來
	info.pressed.connect(func(): tip(layer, info, g, pr))
	var ok := Button.new()
	ok.text = "關閉"
	ok.focus_mode = Control.FOCUS_NONE
	ok.custom_minimum_size = Vector2(0, 46)
	UITheme.accent_button(ok, 17)
	ok.pressed.connect(func(): layer.queue_free())
	col.add_child(ok)
	g.sfx("open")
	return layer


## 「i」的提示框：蓋在整個畫面上一層透明的底（點到就收起來），框從 i 的右下方長出來
static func tip(layer: Control, anchor: Control, g, pr: Dictionary) -> Control:
	var old := layer.find_child("Tip", true, false)
	if old != null:
		old.queue_free()
		return null
	var back := Control.new()
	back.name = "Tip"
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(back)
	back.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			back.queue_free())
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := UITheme.box(Color(0.1, 0.07, 0.2, 0.98), 16, PINK, 2, 16)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 16
	box.add_theme_stylebox_override("panel", sb)
	back.add_child(box)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(sc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.custom_minimum_size = Vector2(500, 0)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(vb)
	var nxt: Dictionary = pr.next
	if not nxt.is_empty():
		vb.add_child(_text("目前 %d 點，Lv.%d 要 %d 點" % [pr.pts, nxt.lv, nxt.need], 14, UITheme.TEXT_DIM))
	var parts := []
	for it in TODAY:
		var cap := int(Bond.BOND_CAP[it[0]])
		parts.append("%s %d／%d" % [it[1], cap - g.bond_left(it[0]), cap])
	vb.add_child(_section("今天"))
	vb.add_child(_text("、".join(parts), 14, UITheme.TEXT))
	vb.add_child(_section("怎麼增加"))
	vb.add_child(_text("答對一題 +1（改對也算）、第一次通過旅程 +5、觀念卡片 +3、今日修煉 +5、每日任務全完成 +5、摸摸頭 +1、聊天 +2。只會增加，不會變少。", 14, UITheme.TEXT))
	vb.add_child(_section("每一級的獎勵"))
	for l in Bond.BOND_LEVELS:
		var got := int(l.lv) <= int(pr.lv)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var lab := Label.new()
		lab.text = "Lv.%d %s" % [l.lv, l.name]
		lab.custom_minimum_size = Vector2(140, 0)
		lab.add_theme_font_override("font", UITheme.bold_font())
		lab.add_theme_font_size_override("font_size", UITheme.fs(14))
		lab.add_theme_color_override("font_color", PINK if got else UITheme.TEXT_DIM)
		row.add_child(lab)
		var un := _text(String(l.unlock) + ("" if l.ready else "（之後開放）"), 13, UITheme.TEXT if got else UITheme.TEXT_DIM)
		un.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(un)
		vb.add_child(row)
	# 放在 i 的下面、右邊對齊 i；太高就捲動，不超出畫面
	var place := func() -> void:
		if not is_instance_valid(box):
			return
		var vp := back.get_viewport_rect().size
		var ar := anchor.get_global_rect()
		var top := ar.end.y + 10.0
		var need := vb.get_combined_minimum_size().y
		sc.custom_minimum_size = Vector2(500, minf(need, vp.y - top - 52.0))
		box.reset_size()
		var x := clampf(ar.end.x - box.size.x + 8.0, 12.0, vp.x - box.size.x - 12.0)
		box.position = Vector2(x, top) - back.get_global_rect().position
		box.pivot_offset = Vector2(ar.get_center().x - x, 0)
		box.scale = Vector2(0.85, 0.85)
		box.modulate.a = 0.0
		var tw := box.create_tween().set_parallel(true)
		tw.tween_property(box, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(box, "modulate:a", 1.0, 0.12)
	place.call_deferred()
	g.sfx("click")
	return back


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
