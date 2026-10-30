extends Control
## 衣櫃：左邊是大大的光靈（即時預覽穿上的樣子），右邊是五類裝扮的格子
## 點有的裝扮：穿上／脫下；沒拿到的顯示「？」剪影，讓學生知道還有什麼可以收集

signal closed

const UITheme := preload("game_theme.gd")
const Game := preload("game.gd")
const Cos := preload("cosmetics.gd")
const SL := preload("spirit_look.gd")

var _cat := "hat"
var _preview
var _tabs: HBoxContainer
var _grid: GridContainer
var _info_name: Label
var _info_desc: Control
var _sel := ""
var _count: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color("0f0d27")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var back := UITheme.ghost_button("返回", 18)
	back.icon = UITheme.icon("back", 18, UITheme.TEXT_DIM)
	back.custom_minimum_size = Vector2(96, 44)
	back.position = Vector2(16, 14)
	back.pressed.connect(_close)
	add_child(back)
	var title := UITheme.title_label("光靈的衣櫃", 30, UITheme.ACCENT)
	title.position = Vector2(376, 14)
	title.size = Vector2(400, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	_count = Label.new()
	_count.position = Vector2(900, 24)
	_count.size = Vector2(230, 30)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count.add_theme_font_size_override("font_size", UITheme.fs(15))
	_count.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	add_child(_count)

	# 左：預覽
	var stage := PanelContainer.new()
	stage.add_theme_stylebox_override("panel", UITheme.box(Color(0.08, 0.09, 0.22, 0.9), 20, Color(1, 1, 1, 0.1), 1, 16))
	stage.position = Vector2(30, 78)
	stage.custom_minimum_size = Vector2(400, 548)
	add_child(stage)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 10)
	stage.add_child(sv)
	_preview = SL.Preview.new()
	_preview.radius = 64.0
	_preview.custom_minimum_size = Vector2(0, 290)
	sv.add_child(_preview)
	_info_name = Label.new()
	_info_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_name.add_theme_font_override("font", UITheme.bold_font())
	_info_name.add_theme_font_size_override("font_size", UITheme.fs(24))
	sv.add_child(_info_name)
	var ds := preload("math_text.gd").new()
	ds.font_size = UITheme.fs(15)
	ds.max_width = 360
	ds.align_center = true
	ds.color = UITheme.TEXT_DIM
	_info_desc = ds
	sv.add_child(ds)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sv.add_child(sp)
	var off := Button.new()
	off.text = "全部卸下"
	off.custom_minimum_size = Vector2(160, 46)
	off.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UITheme.button_3d(off, Color("2c3170"), Color("15183f"), UITheme.TEXT, 16, 6, 14, 6)
	off.pressed.connect(func():
		Game.of(self).unequip_all()
		_sel = ""
		_refresh())
	sv.add_child(off)

	# 右：分類＋格子
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", UITheme.box(Color(0.08, 0.09, 0.22, 0.9), 20, Color(1, 1, 1, 0.1), 1, 16))
	right.position = Vector2(450, 78)
	right.custom_minimum_size = Vector2(672, 548)
	add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 14)
	right.add_child(rv)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	rv.add_child(_tabs)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	rv.add_child(_grid)
	_refresh()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()


func _refresh() -> void:
	var g = Game.of(self)
	_preview.eq = g.equipped.duplicate()
	_count.text = "已收集  %d / %d" % [g.owned.size(), Cos.ITEMS.size()]
	# 分類頁籤
	for c in _tabs.get_children():
		c.queue_free()
	for cat in Cos.CATS:
		var b := Button.new()
		var have := 0
		for it in Cos.items_of(cat.id):
			if g.owned.has(it.id):
				have += 1
		b.text = "%s %d/%d" % [cat.name, have, Cos.items_of(cat.id).size()]
		b.custom_minimum_size = Vector2(0, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", UITheme.fs(15))
		var on: bool = cat.id == _cat
		var sb := UITheme.box(UITheme.ACCENT if on else Color(1, 1, 1, 0.05), 12, Color(1, 1, 1, 0.12), 1, 6)
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, sb)
		for k in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(k, UITheme.GOLD_INK if on else UITheme.TEXT)
		var cid: String = cat.id
		b.pressed.connect(func():
			_cat = cid
			_refresh())
		_tabs.add_child(b)
	# 格子
	for c in _grid.get_children():
		c.queue_free()
	for it in Cos.by_rarity(Cos.items_of(_cat)):      # 依稀有度排：普通 → 傳說
		_grid.add_child(_tile(it, g))
	# 說明
	var show_id := _sel
	if show_id == "" or Cos.item(show_id).cat != _cat:
		show_id = String(g.equipped.get(_cat, ""))
	if show_id != "":
		var it := Cos.item(show_id)
		var r := int(it.r)
		_info_name.text = "%s　%s" % [it.name, Cos.RARITY[r].name]
		_info_name.add_theme_color_override("font_color", Cos.RARITY[r].color if r > 0 else UITheme.TEXT)
		_info_desc.text = it.desc
	else:
		_info_name.text = "點右邊的裝扮試穿看看"
		_info_name.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		_info_desc.text = "沒有的裝扮可以到扭蛋機抽抽看！"


func _tile(it: Dictionary, g) -> Control:
	var own: bool = g.owned.has(it.id)
	var worn: bool = g.equipped.get(it.cat, "") == it.id
	var r := int(it.r)
	var rc: Color = Cos.RARITY[r].color
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 136)
	b.focus_mode = Control.FOCUS_NONE
	var edge := UITheme.ACCENT if worn else (Color(rc.r, rc.g, rc.b, 0.6) if own else Color(1, 1, 1, 0.08))
	var face := Color(0.12, 0.13, 0.3, 0.95) if own else Color(0.07, 0.07, 0.16, 0.95)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, UITheme.box(face.lightened(0.06 if st == "hover" and own else 0.0), 14, edge, 3 if worn else 1, 0))
	var pv := SL.Preview.new()
	pv.eq = {it.cat: it.id}
	pv.radius = 20.0
	pv.silhouette = not own
	pv.position = Vector2(0, 4)
	pv.size = Vector2(150, 84)
	pv.animate = own
	b.add_child(pv)
	var nl := Label.new()
	nl.text = it.name if own else "？？？"
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.position = Vector2(0, 84)
	nl.size = Vector2(150, 24)
	nl.add_theme_font_size_override("font_size", UITheme.fs(15))
	nl.add_theme_color_override("font_color", (rc if r > 0 else UITheme.TEXT) if own else UITheme.TEXT_DIM)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nl)
	var sub := Label.new()
	sub.text = ("穿著中" if worn else Cos.RARITY[r].name) if own \
		else ("簽到限定" if it.has("how") else Cos.RARITY[r].name)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 108)
	sub.size = Vector2(150, 20)
	sub.add_theme_font_size_override("font_size", UITheme.fs(12))
	sub.add_theme_color_override("font_color", UITheme.ACCENT if worn else UITheme.TEXT_DIM)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(sub)
	var id: String = it.id
	b.pressed.connect(func():
		if not own:
			_sel = ""
			_info_name.text = "還沒拿到：" + Cos.RARITY[r].name + "的" + _cat_name(it.cat)
			_info_name.add_theme_color_override("font_color", UITheme.TEXT_DIM)
			_info_desc.text = ("限定裝扮：" + String(it.how) + "。") if it.has("how") else "到扭蛋機抽抽看吧！"
			return
		g.toggle_equip(id)
		g.play("bell", 1.2, -10.0)
		_sel = id
		_refresh())
	return b


func _cat_name(c: String) -> String:
	for x in Cos.CATS:
		if x.id == c:
			return x.name
	return ""
