extends RefCounted
## 「這次段考考什麼？」：選年級（身分）＋這學期的段考範圍（可以複選）
##   ・學期看今天的日期：7/1～隔年 1/31 上學期，2/1～6/30 下學期（Units.term_now）
##   ・選好的單元排在主線的第一順位（world_story.next_goal）；「還不確定」＝照課本順序
##   ・什麼時候跳出來：第一次選完年級、每學期第一次打開大地圖、點地圖上方的金色主線橫幅
const UITheme := preload("res://data/ui/game_theme.gd")
const Game := preload("res://data/core/game.gd")
const Units := preload("res://data/core/units.gd")
const WS := preload("res://data/maps/world_story.gd")

const GRADE_COL := {"高一": Color("f5c84c"), "高二": Color("5fd4ff")}


## host：視窗放在哪裡；grade：一開始顯示哪個年級；on_done(grade)：按下確定（或還不確定）之後
static func open(host: Node, grade: String, on_done: Callable = Callable()) -> Control:
	var g = Game.of(host)
	var o := UITheme.modal(host, UITheme.ACCENT, 780)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 12)
	col.add_child(UITheme.title_label("這次段考考什麼？", 28, UITheme.ACCENT))
	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", UITheme.fs(15))
	sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	col.add_child(sub)
	# 年級（身分）
	var grow := HBoxContainer.new()
	grow.alignment = BoxContainer.ALIGNMENT_CENTER
	grow.add_theme_constant_override("separation", 12)
	col.add_child(grow)
	var cards := HFlowContainer.new()
	cards.alignment = FlowContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("h_separation", 12)
	cards.add_theme_constant_override("v_separation", 12)
	col.add_child(cards)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 16)
	col.add_child(btns)
	var unsure := Button.new()
	unsure.text = "還不確定"
	unsure.focus_mode = Control.FOCUS_NONE
	unsure.custom_minimum_size = Vector2(200, 54)
	UITheme.button_3d(unsure, UITheme.BTN, UITheme.BTN_LIP, UITheme.TEXT, 19, 6)
	btns.add_child(unsure)
	var okb := Button.new()
	okb.text = "確定"
	okb.focus_mode = Control.FOCUS_NONE
	okb.custom_minimum_size = Vector2(200, 54)
	UITheme.button_3d(okb, UITheme.ACCENT, UITheme.ACCENT_LIP, UITheme.GOLD_INK, 21, 6)
	btns.add_child(okb)

	var st := {"grade": grade if GRADE_COL.has(grade) else "高二", "sel": []}
	var rebuild := func(self_ref: Callable) -> void:
		var gr: String = st.grade
		var term := Units.term_now(gr)
		sub.text = "%s學期・可複選\n（之後點地圖上方的金色橫幅可修改）" % term
		for c in grow.get_children():
			c.queue_free()
		for c in cards.get_children():
			c.queue_free()
		var gl := Label.new()
		gl.text = "我是"
		gl.add_theme_font_size_override("font_size", UITheme.fs(17))
		gl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		grow.add_child(gl)
		for gname in ["高一", "高二"]:
			var on: bool = gname == gr
			var c: Color = GRADE_COL[gname]
			var b := Button.new()
			b.text = gname
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(110, 46)
			b.add_theme_font_override("font", UITheme.bold_font())
			b.add_theme_font_size_override("font_size", UITheme.fs(19))
			b.add_theme_color_override("font_color", c if on else UITheme.TEXT_DIM)
			b.add_theme_color_override("font_hover_color", c)
			for k in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(k, UITheme.box(Color(c.r, c.g, c.b, 0.22 if on else 0.06), 23, c if on else Color(1, 1, 1, 0.18), 2 if on else 1, 8))
			var gn: String = gname
			b.pressed.connect(func():
				if st.grade == gn:
					return
				st.grade = gn
				st.sel = WS.exam_units(g, gn).duplicate()
				g.sfx("click")
				self_ref.call(self_ref))
			grow.add_child(b)
		# 這學期的單元
		for u in Units.term_units(term):
			var open: bool = Units.is_open(u) and not (u.levels as Array).is_empty()
			var uid: String = u.id
			var on: bool = (st.sel as Array).has(uid)
			var c: Color = u.color
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(170, 104)
			b.disabled = not open
			for k in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(k, UITheme.box(Color(c.r, c.g, c.b, 0.26 if on else 0.08), 18,
					c if on else Color(c.r, c.g, c.b, 0.45), 3 if on else 1, 10))
			b.add_theme_stylebox_override("disabled", UITheme.box(Color(1, 1, 1, 0.03), 18, Color(1, 1, 1, 0.08), 1, 10))
			var v := VBoxContainer.new()
			v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			v.alignment = BoxContainer.ALIGNMENT_CENTER
			v.add_theme_constant_override("separation", 4)
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(v)
			var mark := "✓ " if on else ""
			var lit: Array = WS.lit_count(g, u) if open else [0, 0]
			for line in [[mark + String(u.title), 19 if String(u.title).length() <= 6 else 16, (c if on else UITheme.TEXT) if open else UITheme.TEXT_DIM, true],
					[("點亮 %d／%d" % [lit[0], lit[1]]) if open else "之後開放", 13, UITheme.TEXT_DIM, false]]:
				var l := Label.new()
				l.text = line[0]
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				l.custom_minimum_size = Vector2(150, 0)
				if line[3]:
					l.add_theme_font_override("font", UITheme.bold_font())
				l.add_theme_font_size_override("font_size", UITheme.fs(line[1]))
				l.add_theme_color_override("font_color", line[2])
				l.mouse_filter = Control.MOUSE_FILTER_IGNORE
				v.add_child(l)
			b.pressed.connect(func():
				var sel: Array = st.sel
				if sel.has(uid):
					sel.erase(uid)
				else:
					sel.append(uid)
				g.sfx("click")
				self_ref.call(self_ref))
			cards.add_child(b)
		okb.disabled = (st.sel as Array).is_empty()
	st.sel = WS.exam_units(g, st.grade).duplicate()
	rebuild.call(rebuild)

	var finish := func(units: Array) -> void:
		g.grade_pick = st.grade
		WS.set_exam_pick(g, st.grade, units)
		g.sfx("success")
		layer.queue_free()
		if on_done.is_valid():
			on_done.call(String(st.grade))
	unsure.pressed.connect(func(): finish.call([]))
	okb.pressed.connect(func(): finish.call((st.sel as Array).duplicate()))
	return layer
