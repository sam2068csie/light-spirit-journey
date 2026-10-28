extends Control
## 碎片兌換所：用光之碎片（抽到重複裝扮換來的）指定換一件還沒有的裝扮
## 價格：普通 30、稀有 80、史詩 250、傳說 600（cosmetics.gd 的 EXCHANGE）
## 左邊是選中裝扮的大預覽和「兌換」按鈕，右邊是五類裝扮的格子

signal closed

const UITheme := preload("game_theme.gd")
const Game := preload("game.gd")
const Cos := preload("cosmetics.gd")
const SL := preload("spirit_look.gd")
const QP := preload("quest_panel.gd")

var _cat := "hat"
var _sel := ""
var _tabs: HBoxContainer
var _grid: GridContainer
var _preview
var _name: Label
var _desc: Control
var _price: Label
var _buy: Button
var _shards: Label
var _toast: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color("0c1428")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var back := UITheme.ghost_button("返回", 18)
	back.icon = UITheme.icon("back", 18, UITheme.TEXT_DIM)
	back.custom_minimum_size = Vector2(96, 44)
	back.position = Vector2(16, 14)
	back.pressed.connect(_close)
	add_child(back)
	var title := UITheme.title_label("碎片兌換所", 30, Color("7fe3ff"))
	title.position = Vector2(376, 14)
	title.size = Vector2(400, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var hold := HBoxContainer.new()
	hold.position = Vector2(930, 20)
	hold.add_theme_constant_override("separation", 6)
	add_child(hold)
	var ii := QP.ItemIcon.new()
	ii.kind = "shard"
	ii.custom_minimum_size = Vector2(28, 28)
	hold.add_child(ii)
	_shards = Label.new()
	_shards.add_theme_font_size_override("font_size", UITheme.fs(18))
	_shards.add_theme_color_override("font_color", Color("7fe3ff"))
	hold.add_child(_shards)

	# 左：預覽與兌換
	var stage := PanelContainer.new()
	stage.add_theme_stylebox_override("panel", UITheme.box(Color(0.07, 0.11, 0.2, 0.92), 20, Color(0.5, 0.9, 1.0, 0.18), 1, 16))
	stage.position = Vector2(30, 78)
	stage.custom_minimum_size = Vector2(400, 548)
	add_child(stage)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 10)
	stage.add_child(sv)
	_preview = SL.Preview.new()
	_preview.radius = 58.0
	_preview.custom_minimum_size = Vector2(0, 260)
	sv.add_child(_preview)
	_name = Label.new()
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_override("font", UITheme.bold_font())
	_name.add_theme_font_size_override("font_size", UITheme.fs(22))
	sv.add_child(_name)
	var ds := preload("math_text.gd").new()
	ds.font_size = UITheme.fs(15)
	ds.max_width = 360
	ds.align_center = true
	ds.color = UITheme.TEXT_DIM
	_desc = ds
	sv.add_child(ds)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sv.add_child(sp)
	_price = Label.new()
	_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_price.add_theme_font_size_override("font_size", UITheme.fs(17))
	sv.add_child(_price)
	_buy = Button.new()
	_buy.text = "兌換"
	_buy.custom_minimum_size = Vector2(220, 54)
	_buy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UITheme.button_3d(_buy, Color("5ad8ff"), Color("1f7fa8"), Color("082436"), 19, 6, 14, 6)
	_buy.pressed.connect(_do_buy)
	sv.add_child(_buy)

	# 右：分類＋格子
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", UITheme.box(Color(0.07, 0.11, 0.2, 0.92), 20, Color(0.5, 0.9, 1.0, 0.18), 1, 16))
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

	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_override("font", UITheme.bold_font())
	_toast.add_theme_font_size_override("font_size", UITheme.fs(20))
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.1, 0.95))
	_toast.position = Vector2(30, 300)
	_toast.size = Vector2(400, 40)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)
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
	_shards.text = "光之碎片  %d" % int(g.inv.shard)
	for c in _tabs.get_children():
		c.queue_free()
	for cat in Cos.CATS:
		var b := Button.new()
		b.text = cat.name
		b.custom_minimum_size = Vector2(0, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", UITheme.fs(15))
		var on: bool = cat.id == _cat
		var sb := UITheme.box(Color("5ad8ff") if on else Color(1, 1, 1, 0.05), 12, Color(1, 1, 1, 0.12), 1, 6)
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, sb)
		for k in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(k, Color("082436") if on else UITheme.TEXT)
		var cid: String = cat.id
		b.pressed.connect(func():
			_cat = cid
			_sel = ""
			_refresh())
		_tabs.add_child(b)
	for c in _grid.get_children():
		c.queue_free()
	var list := Cos.items_of(_cat).filter(func(x): return x.get("pool", true))   # 簽到限定的換不到
	list.sort_custom(func(a, b): return int(a.r) < int(b.r))
	if _sel == "":
		for it in list:
			if not g.owned.has(it.id):
				_sel = it.id
				break
		if _sel == "" and not list.is_empty():
			_sel = list[0].id
	for it in list:
		_grid.add_child(_tile(it, g))
	_show_sel(g)


func _show_sel(g) -> void:
	var it := Cos.item(_sel)
	if it.is_empty():
		return
	var r := int(it.r)
	var eq: Dictionary = g.equipped.duplicate()
	eq[it.cat] = it.id
	_preview.eq = eq
	_name.text = "%s　%s" % [it.name, Cos.RARITY[r].name]
	_name.add_theme_color_override("font_color", Cos.RARITY[r].color if r > 0 else UITheme.TEXT)
	_desc.text = it.desc
	var cost: int = g.exchange_cost(it.id)
	if g.owned.has(it.id):
		_price.text = "已經擁有了"
		_price.add_theme_color_override("font_color", UITheme.GOOD)
		_buy.disabled = true
		_buy.text = "已擁有"
	else:
		var enough: bool = int(g.inv.shard) >= cost
		_price.text = "需要 光之碎片 %d　（目前 %d）" % [cost, int(g.inv.shard)]
		_price.add_theme_color_override("font_color", Color("7fe3ff") if enough else UITheme.BAD)
		_buy.disabled = not enough
		_buy.text = "兌換" if enough else "碎片不夠"


func _tile(it: Dictionary, g) -> Control:
	var own: bool = g.owned.has(it.id)
	var r := int(it.r)
	var rc: Color = Cos.RARITY[r].color
	var sel: bool = it.id == _sel
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 136)
	b.focus_mode = Control.FOCUS_NONE
	var edge := Color("5ad8ff") if sel else Color(rc.r, rc.g, rc.b, 0.5)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, UITheme.box(Color(0.1, 0.14, 0.28, 0.95).lightened(0.05 if st == "hover" else 0.0), 14, edge, 3 if sel else 1, 0))
	var pv := SL.Preview.new()
	pv.eq = {it.cat: it.id}
	pv.radius = 18.0
	pv.position = Vector2(0, 2)
	pv.size = Vector2(150, 82)
	pv.animate = sel
	b.add_child(pv)
	var nl := Label.new()
	nl.text = it.name
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.position = Vector2(0, 84)
	nl.size = Vector2(150, 24)
	nl.add_theme_font_size_override("font_size", UITheme.fs(15))
	nl.add_theme_color_override("font_color", rc if r > 0 else UITheme.TEXT)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nl)
	var sub := Label.new()
	sub.text = "✓ 已擁有" if own else "◆ %d" % int(Cos.EXCHANGE[r])
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 108)
	sub.size = Vector2(150, 20)
	sub.add_theme_font_size_override("font_size", UITheme.fs(13))
	sub.add_theme_color_override("font_color", UITheme.GOOD if own else Color("7fe3ff"))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(sub)
	if own:
		pv.modulate = Color(1, 1, 1, 0.55)
	var id: String = it.id
	b.pressed.connect(func():
		_sel = id
		_refresh())
	return b


func _do_buy() -> void:
	var g = Game.of(self)
	var it := Cos.item(_sel)
	if not g.exchange(_sel):
		return
	g.sfx("fanfare" if int(it.r) >= 2 else "success")
	_toast.text = "換到了：%s！到衣櫃穿上吧" % it.name
	_toast.add_theme_color_override("font_color", Color("7fe3ff"))
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_refresh()
