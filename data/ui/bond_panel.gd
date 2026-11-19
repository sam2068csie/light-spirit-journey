extends RefCounted
## 光靈親密度的兩個視窗（資料在 game_bond.gd）
##   levelup(host, lv)：升級了！（小屋、主畫面、大地圖都可能跳出來；每次升級只播一次）
##   snacks(host, on_pick)：點心選單（第二期）
##   nick_editor(host, on_done)：取暱稱（Lv 5）
##   detail(host)：小屋左下角點開：現在幾級、進度條；右上角的「i」點了才展開（怎麼增加＋今天的次數、每一級的獎勵）
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

## 怎麼增加（「i」的提示框）：[種類, 名稱]；有每日上限的，同一行右邊寫今天做了幾次
const WAYS := [["learn", "答對一題"], ["journey", "第一次通過旅程"], ["card", "觀念卡片"], ["daily", "今日修煉"],
	["quests", "每日任務全完成"], ["pet", "摸摸頭"], ["chat", "聊天"], ["snack", "點心"]]


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
	col.add_child(_text(("解鎖　" + un) if info.ready else ("解鎖　%s（未開放）" % un), 16, Color("ffd36e") if info.ready else UITheme.TEXT_DIM, true))
	# Lv 5：直接在這裡取暱稱（可以留空，之後在親密度視窗裡再取）
	var nick_in: LineEdit = null
	var warn: Label = null
	if lv == Bond.NICK_LV:
		nick_in = _nick_input(String(g.bond.get("nick", "")))
		col.add_child(nick_in)
		warn = _text("", 14, UITheme.BAD, true)
		col.add_child(warn)
	var ok := Button.new()
	ok.text = "好耶！"
	ok.focus_mode = Control.FOCUS_NONE
	ok.custom_minimum_size = Vector2(0, 48)
	UITheme.accent_button(ok, 18)
	ok.pressed.connect(func():
		if nick_in != null and nick_in.text.strip_edges() != "" and not g.bond_set_nick(nick_in.text):
			warn.text = "暱稱 1～%d 字" % Bond.NICK_MAX
			return
		layer.queue_free())
	col.add_child(ok)
	g.sfx("fanfare")
	return layer


static func _nick_input(cur: String) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = "暱稱（1～%d 字）" % Bond.NICK_MAX
	le.max_length = Bond.NICK_MAX
	le.text = cur
	le.alignment = HORIZONTAL_ALIGNMENT_CENTER
	le.custom_minimum_size = Vector2(260, 46)
	le.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	le.add_theme_font_size_override("font_size", UITheme.fs(18))
	le.add_theme_stylebox_override("normal", UITheme.box(Color(1, 1, 1, 0.06), 12, PINK, 2, 10))
	le.add_theme_stylebox_override("focus", UITheme.box(Color(1, 1, 1, 0.1), 12, Color.WHITE, 2, 10))
	return le


## 取暱稱／改暱稱
static func nick_editor(host: Node, on_done: Callable) -> Control:
	var g = Game.of(host)
	var o := UITheme.modal(host, PINK, 420)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 12)
	var title := UITheme.title_label("暱稱", 24, PINK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var le := _nick_input(g.bond_nick())
	col.add_child(le)
	var warn := _text("", 14, UITheme.BAD, true)
	col.add_child(warn)
	var ok := Button.new()
	ok.text = "確定"
	ok.focus_mode = Control.FOCUS_NONE
	ok.custom_minimum_size = Vector2(0, 46)
	UITheme.accent_button(ok, 17)
	ok.pressed.connect(func():
		if not g.bond_set_nick(le.text):
			warn.text = "暱稱 1～%d 字" % Bond.NICK_MAX
			return
		layer.queue_free()
		on_done.call())
	col.add_child(ok)
	le.text_submitted.connect(func(_t): ok.pressed.emit())
	return layer


## 點心選單：6 種點心＋價格；這週已經發現的喜好打愛心。on_pick(id)
static func snacks(host: Node, on_pick: Callable) -> Control:
	var g = Game.of(host)
	var o := UITheme.modal(host, PINK, 640)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	var title := UITheme.title_label("點心", 26, PINK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var found: Array = g.bond_found()
	col.add_child(_text("本週喜好　%d／2　　持有星塵　%d" % [found.size(), int(g.inv.get("dust", 0))], 15, UITheme.TEXT_DIM, true))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(grid)
	var can_feed: bool = g.bond_left("snack") > 0
	for sn in Bond.SNACKS:
		var id: String = sn.id
		var afford := int(g.inv.get("dust", 0)) >= int(sn.price)
		var b := Button.new()
		b.name = "Snack_" + id
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(176, 132)
		b.disabled = not (can_feed and afford)
		b.add_theme_stylebox_override("normal", UITheme.box(Color(1, 1, 1, 0.05), 14, Color(1, 0.56, 0.75, 0.4), 1, 8))
		b.add_theme_stylebox_override("hover", UITheme.box(Color(1, 0.56, 0.75, 0.15), 14, PINK, 2, 8))
		b.add_theme_stylebox_override("pressed", UITheme.box(Color(1, 0.56, 0.75, 0.25), 14, PINK, 2, 8))
		b.add_theme_stylebox_override("disabled", UITheme.box(Color(1, 1, 1, 0.02), 14, Color(1, 1, 1, 0.1), 1, 8))
		var ic := SnackIcon.new()
		ic.id = id
		ic.liked = found.has(id)
		ic.dim = b.disabled
		ic.position = Vector2(48, 6)
		ic.size = Vector2(80, 70)
		b.add_child(ic)
		var nm := _text(String(sn.name), 15, UITheme.TEXT if not b.disabled else UITheme.TEXT_DIM, true)
		nm.position = Vector2(0, 78)
		nm.size = Vector2(176, 24)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(nm)
		var pr := _text("%d 星塵" % int(sn.price), 13, Color("ffe7a3") if afford else UITheme.BAD, true)
		pr.position = Vector2(0, 102)
		pr.size = Vector2(176, 22)
		pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pr)
		b.pressed.connect(func():
			layer.queue_free()
			on_pick.call(id))
		grid.add_child(b)
	if not can_feed:
		col.add_child(_text("今日已餵食", 15, UITheme.TEXT_DIM, true))
	var close := Button.new()
	close.text = "關閉"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 44)
	UITheme.accent_button(close, 16)
	close.pressed.connect(func(): layer.queue_free())
	col.add_child(close)
	g.sfx("open")
	return layer


## 點心的樣子（程式畫的）：c 中心、s 大小
static func draw_snack(ci: CanvasItem, id: String, c: Vector2, s: float, dim := false) -> void:
	var k := 0.45 if dim else 1.0
	var f := func(col: Color) -> Color: return Color(col.r * k + 0.15 * (1 - k), col.g * k + 0.15 * (1 - k), col.b * k + 0.2 * (1 - k), col.a)
	match id:
		"moon_cake":
			UITheme.dot(ci, c, s * 0.42, f.call(Color("d99a4e")))
			UITheme.dot(ci, c, s * 0.34, f.call(Color("f0c27a")))
			UITheme.dot(ci, c + Vector2(-s * 0.04, 0), s * 0.16, f.call(Color("fff1c9")))
			UITheme.dot(ci, c + Vector2(s * 0.04, -s * 0.03), s * 0.14, f.call(Color("f0c27a")))
		"star_candy":
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2 + i * PI / 5
				pts.append(c + Vector2(cos(a), sin(a)) * (s * 0.44 if i % 2 == 0 else s * 0.2))
			ci.draw_colored_polygon(pts, f.call(Color("ffcf5a")))
			UITheme.dot(ci, c + Vector2(-s * 0.08, -s * 0.1), s * 0.06, Color(1, 1, 1, 0.8 * k))
		"dew_jelly":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, s * 0.3), c + Vector2(s * 0.4, s * 0.3), c + Vector2(s * 0.32, -s * 0.1), c + Vector2(0, -s * 0.34), c + Vector2(-s * 0.32, -s * 0.1)]), f.call(Color("6fd3f5")))
			UITheme.dot(ci, c + Vector2(-s * 0.14, -s * 0.08), s * 0.08, Color(1, 1, 1, 0.75 * k))
			ci.draw_line(c + Vector2(-s * 0.44, s * 0.32), c + Vector2(s * 0.44, s * 0.32), f.call(Color("c9a46e")), 3.0)
		"rainbow_puff":
			UITheme.dot(ci, c + Vector2(-s * 0.18, s * 0.08), s * 0.22, f.call(Color("ffb3d9")))
			UITheme.dot(ci, c + Vector2(s * 0.18, s * 0.08), s * 0.22, f.call(Color("a6e1ff")))
			UITheme.dot(ci, c + Vector2(0, -s * 0.14), s * 0.24, f.call(Color("fff2a6")))
		"honey_orb":
			UITheme.dot(ci, c, s * 0.46, Color(1, 0.7, 0.3, 0.25 * k))
			UITheme.dot(ci, c, s * 0.34, f.call(Color("ffb347")))
			UITheme.dot(ci, c + Vector2(0, s * 0.36), s * 0.08, f.call(Color("ffb347")))
			UITheme.dot(ci, c + Vector2(-s * 0.1, -s * 0.12), s * 0.08, Color(1, 1, 1, 0.75 * k))
		"comet_pudding":
			ci.draw_line(c + Vector2(s * 0.18, -s * 0.3), c + Vector2(s * 0.46, -s * 0.46), f.call(Color("ffe7a3")), 3.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.36, s * 0.32), c + Vector2(s * 0.36, s * 0.32), c + Vector2(s * 0.24, -s * 0.2), c + Vector2(-s * 0.24, -s * 0.2)]), f.call(Color("c9a6ff")))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.26, -s * 0.12), c + Vector2(s * 0.26, -s * 0.12), c + Vector2(s * 0.22, -s * 0.24), c + Vector2(-s * 0.22, -s * 0.24)]), f.call(Color("8a5a2b")))
			UITheme.dot(ci, c + Vector2(s * 0.18, -s * 0.3), s * 0.06, f.call(Color("fff6c9")))


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
	info.tooltip_text = "增加方式、等級獎勵"
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
	col.add_child(_text("已達最高等級" if nxt.is_empty() else "下一級　%s" % nxt.name, 15, UITheme.TEXT_DIM, true))
	# Lv 5 起：暱稱（點一下修改）
	if int(pr.lv) >= Bond.NICK_LV:
		var nk := Button.new()
		nk.name = "Nick"
		nk.flat = true
		nk.focus_mode = Control.FOCUS_NONE
		nk.text = "暱稱　%s　✎" % (g.bond_nick() if g.bond_nick() != "" else "未設定")
		nk.add_theme_font_size_override("font_size", UITheme.fs(15))
		nk.add_theme_color_override("font_color", PINK)
		nk.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		nk.pressed.connect(func():
			nick_editor(layer, func(): nk.text = "暱稱　%s　✎" % g.bond_nick()))
		col.add_child(nk)
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
		vb.add_child(_text("親密度　%d／%d" % [pr.pts, nxt.need], 14, UITheme.TEXT_DIM))
	vb.add_child(_section("增加方式（今日次數）"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 2)
	vb.add_child(grid)
	for it in WAYS:
		var k: String = it[0]
		var name := _text(String(it[1]), 14, UITheme.TEXT)
		name.autowrap_mode = TextServer.AUTOWRAP_OFF
		name.custom_minimum_size = Vector2(170, 0)
		grid.add_child(name)
		var pl := _text("+1～3" if k == "snack" else "+%d" % int(Bond.BOND_PTS[k]), 14, PINK)
		pl.autowrap_mode = TextServer.AUTOWRAP_OFF
		pl.custom_minimum_size = Vector2(40, 0)
		grid.add_child(pl)
		var cnt := ""
		if Bond.BOND_CAP.has(k):
			var cap := int(Bond.BOND_CAP[k])
			cnt = "%d／%d" % [cap - g.bond_left(k), cap]
		var cl := _text(cnt, 14, UITheme.TEXT_DIM)
		cl.autowrap_mode = TextServer.AUTOWRAP_OFF
		grid.add_child(cl)
	vb.add_child(_section("等級獎勵"))
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
		var un := _text(String(l.unlock) + ("" if l.ready else "（未開放）"), 13, UITheme.TEXT if got else UITheme.TEXT_DIM)
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


## 點心圖示（點心選單用）：liked = 這週已經發現是喜歡的口味（右上角一顆愛心）
class SnackIcon extends Control:
	const BP := preload("res://data/ui/bond_panel.gd")
	const SL := preload("res://data/ui/spirit_look.gd")
	var id := ""
	var liked := false
	var dim := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		BP.draw_snack(self, id, size / 2.0, minf(size.x, size.y), dim)
		if liked:
			SL.heart(self, Vector2(size.x - 8, 10), 9.0, Color("ff8fbf"))
