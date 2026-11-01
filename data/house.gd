extends Control
## 光靈的小屋（Lv.1：一個房間＋固定格位擺設＋紀念品櫃）
##   ・紀念品櫃：每個單元一件紀念品，點亮整個單元的聖地就會出現（高一、高二、高三共用一個櫃子）
##   ・布告欄 → 每日任務（在小屋裡打開）
##   ・擺設模式：點格位 → 從抽屜挑家具放上去（只列出放得進那種格位的家具）
##   ・商店：用星塵買家具（小家具每天買得起、少量昂貴大家具）；彩蛋家具在地圖上解開才拿得到
##   ・小屋等級：點亮 10／25／50 座聖地升級（目前先做 Lv.1 的房間，等級和下一階段先顯示出來）
## 存檔：Game.house {owned: [家具 id], placed: {"格位編號": 家具 id}}
const UITheme := preload("game_theme.gd")
const Game := preload("game.gd")
const Units := preload("units.gd")
const Center := preload("review_center.gd")
const HI := preload("house_items.gd")
const SL := preload("spirit_look.gd")
const SA := preload("souvenir_art.gd")

const W := 1152.0
const H := 648.0
const WALL := Rect2(70, 64, 1012, 380)
const FLOOR_Y := 444.0
const SHELF := Rect2(104, 110, 250, 330)
const DESK := Rect2(780, 372, 230, 16)
const BOARD := Rect2(800, 104, 200, 128)
const WINDOW := Rect2(486, 92, 180, 136)
## 10 個格位（Lv.1）：種類、範圍
const SLOTS := [
	{"kind": "wall", "r": Rect2(380, 112, 90, 80)},
	{"kind": "wall", "r": Rect2(684, 112, 90, 80)},
	{"kind": "big", "r": Rect2(386, 270, 98, 174)},
	{"kind": "wide", "r": Rect2(494, 296, 166, 148)},
	{"kind": "sill", "r": Rect2(500, 198, 152, 36)},
	{"kind": "top", "r": Rect2(790, 334, 64, 38)},
	{"kind": "top", "r": Rect2(930, 334, 64, 38)},
	{"kind": "floor", "r": Rect2(380, 470, 110, 70)},
	{"kind": "rug", "r": Rect2(500, 552, 180, 42)},
	{"kind": "floor", "r": Rect2(860, 470, 110, 70)},
]
const KIND_NAME := {"wide": "窗下大型", "wall": "牆面", "big": "大型家具", "sill": "窗台", "top": "桌上", "floor": "地板", "rug": "地毯"}
const LINES := ["歡迎回家～", "今天也來點亮一座聖地吧！", "這裡好溫暖喔。", "紀念品櫃還有好多空位呢！", "星塵存夠了，就去商店逛逛吧～"]

var t := 0.0
var deco := false
var sel_slot := -1
var _spirit := Vector2(590, 510)
var _spirit_to := Vector2(590, 510)
var _wait := 2.0
var _face_left := false
var _say := ""
var _say_t := 0.0
var _overlay: Control
var _drawer: PanelContainer
var _top_lv: Label
var _top_dust: Label
var _bar: ProgressBar
var _bar_lab: Label
var _deco_btn: Button
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_refresh()
	_talk(LINES[0] if randf() < 0.5 else LINES[1])


# ================= 資料 =================

func _st() -> Dictionary:
	var g = Game.of(self)
	if not g.house.has("owned"):
		g.house["owned"] = []
	if not g.house.has("placed"):
		g.house["placed"] = {}
	# 格位種類改過：放不進去的家具收回抽屜
	for k in g.house.placed.keys():
		var i := int(k)
		var it := HI.item(String(g.house.placed[k]))
		if i < 0 or i >= SLOTS.size() or it.is_empty() or not (SLOTS[i].kind in it.slots):
			g.house.placed.erase(k)
	return g.house


## 這件家具有沒有：買過的、或是彩蛋解開了
func owns(id: String) -> bool:
	if (_st().owned as Array).has(id):
		return true
	var it := HI.item(id)
	var src := String(it.get("src", ""))
	var g = Game.of(self)
	if src.begins_with("egg10:"):
		return (g.world10.get("eggs", []) as Array).has(src.substr(6))
	if src.begins_with("egg11:"):
		return (g.world11.get("eggs", []) as Array).has(src.substr(6))
	return false


## 全部點亮了幾座聖地（所有單元）
func lit_sites() -> int:
	var g = Game.of(self)
	var n := 0
	for u in Units.UNITS:
		for l in u.levels:
			if Center.level_progress(g, l.id) >= 0.999:
				n += 1
	return n


func house_level() -> Dictionary:
	var lit := lit_sites()
	var cur: Dictionary = HI.LEVELS[0]
	for lv in HI.LEVELS:
		if lit >= int(lv.need):
			cur = lv
	return cur


func _unit_lit(u: Dictionary) -> bool:
	if u.levels.is_empty():
		return false
	var g = Game.of(self)
	for l in u.levels:
		if Center.level_progress(g, l.id) < 0.999:
			return false
	return true


## 全單元 100%（每段旅程的每一種題型都答對過）
func _unit_full(u: Dictionary) -> bool:
	if u.levels.is_empty():
		return false
	var g = Game.of(self)
	for l in u.levels:
		if Center.level_full(g, l.id) < 0.999:
			return false
	return true


func _sv_state(u: Dictionary) -> int:
	if not _unit_lit(u):
		return 0
	return 2 if _unit_full(u) else 1


func _save() -> void:
	Game.of(self).save_review()


# ================= 介面 =================

func _build_ui() -> void:
	var back := UITheme.ghost_button("返回", 18)
	back.icon = UITheme.icon("back", 18, UITheme.TEXT_DIM)
	back.custom_minimum_size = Vector2(96, 44)
	back.position = Vector2(12, 8)
	back.pressed.connect(_back)
	add_child(back)
	_top_lv = Label.new()
	_top_lv.position = Vector2(118, 14)
	_top_lv.add_theme_font_override("font", UITheme.bold_font())
	_top_lv.add_theme_font_size_override("font_size", UITheme.fs(20))
	_top_lv.add_theme_color_override("font_color", UITheme.ACCENT)
	add_child(_top_lv)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.position = Vector2(440, 14)
	_bar.size = Vector2(160, 10)
	_bar.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.1), 5, Color(0, 0, 0, 0), 0, 0))
	_bar.add_theme_stylebox_override("fill", UITheme.box(UITheme.ACCENT, 5, Color(0, 0, 0, 0), 0, 0))
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar)
	_bar_lab = Label.new()
	_bar_lab.position = Vector2(440, 28)
	_bar_lab.add_theme_font_size_override("font_size", UITheme.fs(13))
	_bar_lab.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	add_child(_bar_lab)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.position = Vector2(W - 18 - 470, 8)
	add_child(hb)
	_top_dust = Label.new()
	_top_dust.custom_minimum_size = Vector2(110, 44)
	_top_dust.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_top_dust.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_dust.add_theme_font_override("font", UITheme.bold_font())
	_top_dust.add_theme_font_size_override("font_size", UITheme.fs(15))
	_top_dust.add_theme_color_override("font_color", Color("ffe7a3"))
	hb.add_child(_top_dust)
	for spec in [["升級", _open_upgrade, Color("3a3360")], ["商店", _open_shop, Color("3a3360")], ["擺設模式", _toggle_deco, UITheme.ACCENT]]:
		var b := Button.new()
		b.text = spec[0]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 44)
		var gold: bool = spec[2] == UITheme.ACCENT
		UITheme.button_3d(b, spec[2], UITheme.ACCENT_LIP if gold else Color("231e40"), UITheme.GOLD_INK if gold else UITheme.TEXT, 16, 4, 14, 4)
		b.pressed.connect(spec[1])
		hb.add_child(b)
		if gold:
			_deco_btn = b
	_hint = Label.new()
	_hint.position = Vector2(0, H - 32)
	_hint.size = Vector2(W, 24)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", UITheme.fs(13))
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)


func _refresh() -> void:
	var lv := house_level()
	_top_lv.text = "光靈的小屋　Lv.%d %s" % [lv.lv, lv.name]
	var lit := lit_sites()
	var nxt := {}
	for l in HI.LEVELS:
		if int(l.need) > lit:
			nxt = l
			break
	if nxt.is_empty():
		_bar.value = 100
		_bar_lab.text = "已經是最高等級！"
	else:
		_bar.max_value = float(nxt.need)
		_bar.value = lit
		_bar_lab.text = "升級：點亮 %d／%d 座聖地" % [lit, nxt.need]
	_top_dust.text = "✦ %d" % int(Game.of(self).inv.get("dust", 0))
	_deco_btn.text = "完成擺設" if deco else "擺設模式"
	_hint.text = "點格位，再從下面挑家具放上去" if deco else "點紀念品櫃，或點布告欄看每日任務"
	queue_redraw()


func _talk(s: String) -> void:
	_say = s
	_say_t = 3.2


func _back() -> void:
	if is_instance_valid(_quest_panel):
		return
	if deco and is_instance_valid(_drawer) and not _drawer.is_queued_for_deletion():
		_close_drawer()
		return
	if close_overlay():
		return
	if deco:
		_toggle_deco()
		return
	var g = Game.of(self)
	g.goto("main_menu.gd", {"page": String(g.get_meta("house_from", "title"))})


func close_overlay() -> bool:
	if is_instance_valid(_overlay) and not _overlay.is_queued_for_deletion():
		_overlay.queue_free()
		_overlay = null
		return true
	return false


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()


func _modal(col: Color, w: int, title: String) -> VBoxContainer:
	var o := UITheme.modal(self, col, w)
	_overlay = o[0]
	var vb: VBoxContainer = o[1]
	vb.add_child(UITheme.title_label(title, 26, col))
	return vb


func _close_btn(vb: VBoxContainer, txt := "關閉") -> void:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 46)
	UITheme.accent_button(b, 17)
	b.pressed.connect(func(): close_overlay())
	vb.add_child(b)


# ================= 點擊房間 =================

func _gui_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	var p: Vector2 = e.position
	if deco:
		for i in SLOTS.size():
			if (SLOTS[i].r as Rect2).grow(6).has_point(p):
				_pick_slot(i)
				return
		return
	if SHELF.has_point(p):
		_open_shelf()
	elif BOARD.has_point(p):
		_open_quests()
	elif p.distance_to(_spirit) < 50.0:
		_talk(LINES[randi() % LINES.size()])
	else:
		for i in SLOTS.size():
			if (SLOTS[i].r as Rect2).has_point(p) and _placed(i) != "":
				_talk("這是%s！" % HI.item(_placed(i)).name)


var _quest_panel: Control


func _open_quests() -> void:
	if is_instance_valid(_quest_panel) or is_instance_valid(_overlay):
		return
	Game.of(self).sfx("click")
	_quest_panel = preload("quest_panel.gd").new()
	add_child(_quest_panel)
	_quest_panel.closed.connect(func():
		_quest_panel = null
		_refresh())
	_quest_panel.go.connect(func(dest: String):
		var g = Game.of(self)
		if dest == "tower":
			g.tower_from = "title"
		g.goto("main_menu.gd", {"page": dest}))


func _placed(i: int) -> String:
	return String(_st().placed.get(str(i), ""))


# ================= 擺設模式 =================

func _close_drawer() -> void:
	if is_instance_valid(_drawer):
		_drawer.queue_free()
	sel_slot = -1
	queue_redraw()


func _toggle_deco() -> void:
	deco = not deco
	sel_slot = -1
	if is_instance_valid(_drawer):
		_drawer.queue_free()
	Game.of(self).sfx("click")
	_refresh()


func _pick_slot(i: int) -> void:
	sel_slot = i
	Game.of(self).sfx("click")
	if is_instance_valid(_drawer):
		_drawer.queue_free()
	_drawer = PanelContainer.new()
	_drawer.add_theme_stylebox_override("panel", UITheme.box(Color(0.06, 0.08, 0.2, 0.97), 16, UITheme.ACCENT, 2, 12))
	# 選的是下面的格位（地板、地毯）→ 抽屜放上面，才不會蓋住格位
	_drawer.position = Vector2(20, 64) if (SLOTS[i].r as Rect2).position.y > 400.0 else Vector2(20, 448)
	_drawer.custom_minimum_size = Vector2(W - 40, 0)
	add_child(_drawer)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_drawer.add_child(vb)
	var kind: String = SLOTS[i].kind
	var hd := Label.new()
	hd.text = "第 %d 格（%s）可以放：" % [i + 1, KIND_NAME[kind]]
	hd.add_theme_font_override("font", UITheme.bold_font())
	hd.add_theme_font_size_override("font_size", UITheme.fs(15))
	hd.add_theme_color_override("font_color", UITheme.ACCENT)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	vb.add_child(top)
	top.add_child(hd)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	# 換格位：抽屜可能蓋住別的格位，直接在這裡切換
	var sw := Label.new()
	sw.text = "換格位"
	sw.add_theme_font_size_override("font_size", UITheme.fs(13))
	sw.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	top.add_child(sw)
	for k in SLOTS.size():
		var cb := Button.new()
		cb.text = str(k + 1)
		cb.focus_mode = Control.FOCUS_NONE
		cb.custom_minimum_size = Vector2(34, 30)
		var on := k == i
		UITheme.button_3d(cb, UITheme.ACCENT if on else Color("3a3360"), UITheme.ACCENT_LIP if on else Color("231e40"), UITheme.GOLD_INK if on else UITheme.TEXT, 13, 2, 4, 1)
		cb.tooltip_text = KIND_NAME[SLOTS[k].kind]
		var kk := k
		cb.pressed.connect(func(): _pick_slot(kk))
		top.add_child(cb)
	var xb := Button.new()
	xb.text = "✕ 收起"
	xb.focus_mode = Control.FOCUS_NONE
	xb.custom_minimum_size = Vector2(70, 30)
	UITheme.button_3d(xb, Color("5a3a4a"), Color("2e1e28"), UITheme.TEXT, 13, 2, 6, 1)
	xb.pressed.connect(_close_drawer)
	top.add_child(xb)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 120)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	sc.add_child(row)
	if _placed(i) != "":
		row.add_child(_drawer_card({"id": "", "name": "收起來"}, true, "清空這一格"))
	var any := false
	for it in HI.ITEMS:
		if not (kind in it.slots):
			continue
		var own := owns(it.id)
		var where := ""
		if not own:
			where = ("✦ %d（去商店買）" % it.price) if it.has("price") else String(it.get("how", ""))
		row.add_child(_drawer_card(it, own, where))
		any = true
	if not any:
		var l := Label.new()
		l.text = "還沒有可以放在這裡的家具。"
		row.add_child(l)


func _drawer_card(it: Dictionary, own: bool, sub: String) -> Control:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(128, 116)
	b.disabled = not own
	b.add_theme_stylebox_override("normal", UITheme.box(Color(0.12, 0.15, 0.32), 12, UITheme.GOOD if own else Color(1, 1, 1, 0.1), 2 if own else 1, 6))
	b.add_theme_stylebox_override("hover", UITheme.box(Color(0.16, 0.2, 0.4), 12, UITheme.ACCENT, 2, 6))
	b.add_theme_stylebox_override("disabled", UITheme.box(Color(0.08, 0.1, 0.2), 12, Color(1, 1, 1, 0.06), 1, 6))
	var pv := ItemPreview.new()
	pv.house = self
	pv.id = String(it.id)
	pv.dim = not own
	pv.position = Vector2(29, 6)
	pv.size = Vector2(70, 56)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(pv)
	var nm := Label.new()
	nm.text = it.name
	nm.position = Vector2(0, 64)
	nm.size = Vector2(128, 22)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", UITheme.bold_font())
	nm.add_theme_font_size_override("font_size", UITheme.fs(14))
	nm.add_theme_color_override("font_color", UITheme.TEXT if own else UITheme.TEXT_DIM)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nm)
	var sl := Label.new()
	sl.text = sub
	sl.position = Vector2(4, 86)
	sl.size = Vector2(120, 26)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sl.add_theme_font_size_override("font_size", UITheme.fs(10))
	sl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(sl)
	var iid := String(it.id)
	b.pressed.connect(func():
		var st := _st()
		if iid == "":
			st.placed.erase(str(sel_slot))
		else:
			# 一件家具只能擺一個地方：別格有的話先收起來
			for k in st.placed.keys():
				if String(st.placed[k]) == iid:
					st.placed.erase(k)
			st.placed[str(sel_slot)] = iid
		Game.of(self).sfx("success")
		_save()
		_pick_slot(sel_slot)
		queue_redraw())
	return b


# ================= 商店 =================

func _open_shop() -> void:
	if is_instance_valid(_overlay):
		return
	Game.of(self).sfx("click")
	var vb := _modal(UITheme.ACCENT, 900, "家具商店")
	var dl := Label.new()
	dl.text = "持有星塵 ✦ %d" % int(Game.of(self).inv.get("dust", 0))
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.add_theme_font_size_override("font_size", UITheme.fs(14))
	dl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	vb.add_child(dl)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(grid)
	for it in HI.ITEMS:
		if not it.has("price"):
			continue
		var own := owns(it.id)
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 2)
		var pv := ItemPreview.new()
		pv.house = self
		pv.id = it.id
		pv.custom_minimum_size = Vector2(130, 54)
		card.add_child(pv)
		var nm := Label.new()
		nm.text = it.name
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.add_theme_font_size_override("font_size", UITheme.fs(13))
		card.add_child(nm)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(130, 34)
		var price: int = it.price
		var big: bool = price >= 1000
		b.text = "已擁有" if own else "✦ %d" % price
		b.disabled = own or int(Game.of(self).inv.get("dust", 0)) < price
		UITheme.button_3d(b, Color("8a5ab8") if big else Color("2a6f9e"), Color("4a2a78") if big else Color("17405e"), Color("f0f4ff"), 14, 3, 10, 2)
		var iid: String = it.id
		var nmv: String = it.name
		b.pressed.connect(func():
			var g = Game.of(self)
			if int(g.inv.get("dust", 0)) < price:
				return
			g.inv["dust"] = int(g.inv.get("dust", 0)) - price
			(_st().owned as Array).append(iid)
			g.sfx("success")
			_save()
			close_overlay()
			_refresh()
			_talk("買到%s了！進擺設模式放上去吧～" % nmv))
		card.add_child(b)
		grid.add_child(card)
	_close_btn(vb)


# ================= 紀念品櫃 =================

func _open_shelf() -> void:
	if is_instance_valid(_overlay):
		return
	Game.of(self).sfx("click")
	var vb := _modal(Color("f0d29a"), 860, "紀念品櫃")
	var tip := Label.new()
	tip.text = "點亮一個單元的所有聖地，就會得到該單元的紀念品；全單元 100% 時，紀念品會發光並出現專屬特效"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", UITheme.fs(14))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	vb.add_child(tip)
	var detail := Label.new()
	var big := SouvenirView.new()
	big.s = 80.0
	big.custom_minimum_size = Vector2(130, 110)
	big.visible = false
	for gr in ["高一", "高二", "高三"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		vb.add_child(row)
		var gl := Label.new()
		gl.text = gr
		gl.custom_minimum_size = Vector2(56, 0)
		gl.add_theme_font_override("font", UITheme.bold_font())
		gl.add_theme_font_size_override("font_size", UITheme.fs(16))
		gl.add_theme_color_override("font_color", Color("f0d29a"))
		row.add_child(gl)
		var units := []
		for term in Units.GRADES.get(gr, []):
			units.append_array(Units.units_of_term(term))
		if units.is_empty():
			var l := Label.new()
			l.text = "（之後開放）"
			l.add_theme_color_override("font_color", UITheme.TEXT_DIM)
			row.add_child(l)
			continue
		for u in units:
			var stt := _sv_state(u)
			var lit := stt > 0
			var sv := HI.souvenir(u.id)
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(82, 74)
			var nl := Label.new()
			var tt := String(u.title)
			if tt.length() > 5:      # 太長：從中間斷成兩行
				var cut := (tt.length() + 1) / 2
				tt = tt.substr(0, cut) + "\n" + tt.substr(cut)
			nl.text = tt
			nl.position = Vector2(2, 36)
			nl.custom_minimum_size = Vector2(78, 36)
			nl.size = Vector2(78, 36)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			nl.add_theme_font_size_override("font_size", UITheme.fs(12))
			nl.add_theme_constant_override("line_spacing", -3)
			nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(nl)
			var c: Color = sv.col
			b.add_theme_stylebox_override("normal", UITheme.box(Color(c.r, c.g, c.b, 0.28) if lit else Color(0, 0, 0, 0.25), 10, c if lit else Color(1, 1, 1, 0.12), 2 if lit else 1, 4))
			b.add_theme_stylebox_override("hover", UITheme.box(Color(c.r, c.g, c.b, 0.36) if lit else Color(1, 1, 1, 0.06), 10, c, 2, 4))
			nl.add_theme_color_override("font_color", UITheme.TEXT if lit else UITheme.TEXT_DIM)
			var gem := SouvenirView.new()
			gem.uid = u.id
			gem.state = stt
			gem.s = 30.0
			gem.position = Vector2(16, 2)
			gem.size = Vector2(50, 36)
			gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(gem)
			if stt == 2:
				b.add_theme_stylebox_override("normal", UITheme.box(Color(c.r, c.g, c.b, 0.4), 10, Color("ffe7a3"), 3, 4))
			var uu: Dictionary = u
			b.pressed.connect(func():
				big.uid = uu.id
				big.state = stt
				big.visible = true
				if stt == 2:
					detail.text = "★ %s　%s（全單元 100%%）\n%s" % [uu.title, sv.name, sv.story]
				elif stt == 1:
					detail.text = "%s　%s\n%s\n把這個單元每一段旅程的所有題型都答對（100%%），它就會發光！" % [uu.title, sv.name, sv.story]
				else:
					detail.text = "%s：點亮這個單元的所有聖地就會出現。" % uu.title)
			row.add_child(b)
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 14)
	vb.add_child(drow)
	drow.add_child(big)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	detail.custom_minimum_size = Vector2(0, 60)
	detail.add_theme_font_size_override("font_size", UITheme.fs(14))
	detail.add_theme_color_override("font_color", UITheme.TEXT)
	detail.text = "點一件紀念品看看。"
	drow.add_child(detail)
	_close_btn(vb)


# ================= 升級 =================

func _open_upgrade() -> void:
	if is_instance_valid(_overlay):
		return
	Game.of(self).sfx("click")
	var vb := _modal(UITheme.ACCENT, 760, "小屋升級")
	var lit := lit_sites()
	var cur := house_level()
	var tip := Label.new()
	tip.text = "目前總共點亮 %d 座聖地" % lit
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", UITheme.fs(14))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	vb.add_child(tip)
	for lv in HI.LEVELS:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		vb.add_child(hb)
		var ok: bool = lit >= int(lv.need)
		var nm := Label.new()
		nm.text = "%s Lv.%d %s" % ["★" if lv.lv == cur.lv else ("✓" if ok else "·"), lv.lv, lv.name]
		nm.custom_minimum_size = Vector2(190, 0)
		nm.add_theme_font_override("font", UITheme.bold_font())
		nm.add_theme_font_size_override("font_size", UITheme.fs(17))
		nm.add_theme_color_override("font_color", UITheme.ACCENT if lv.lv == cur.lv else (UITheme.TEXT if ok else UITheme.TEXT_DIM))
		hb.add_child(nm)
		var d := Label.new()
		d.text = String(lv.desc)
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", UITheme.fs(14))
		d.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		hb.add_child(d)
		var need := Label.new()
		need.text = "一開始就有" if int(lv.need) == 0 else ("已達成" if ok else "點亮 %d 座" % lv.need)
		need.custom_minimum_size = Vector2(100, 0)
		need.add_theme_font_size_override("font_size", UITheme.fs(14))
		need.add_theme_color_override("font_color", UITheme.GOOD if ok else UITheme.TEXT_DIM)
		hb.add_child(need)
	var note := Label.new()
	note.text = "（閣樓、陽台、觀星塔的房間還在施工中）"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", UITheme.fs(13))
	note.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	vb.add_child(note)
	_close_btn(vb)


# ================= 每幀 =================

func _process(delta: float) -> void:
	t += delta
	_wait -= delta
	if _wait <= 0.0 and not deco:
		_spirit_to = Vector2(randf_range(470, 730), randf_range(500, 530))
		_wait = randf_range(3.0, 6.0)
	_spirit = _spirit.move_toward(_spirit_to, 60.0 * delta)
	if _say_t > 0.0:
		_say_t -= delta
	elif randf() < delta * 0.05 and not deco:
		_talk(LINES[randi() % LINES.size()])
	queue_redraw()


# ================= 畫圖 =================

func _draw() -> void:
	var font := UITheme.bold_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d1230"))
	_draw_room()
	_draw_window()
	_draw_shelf(font)
	_draw_board(font)
	_draw_desk(font)
	# 擺好的家具
	for i in SLOTS.size():
		var id := _placed(i)
		if id != "":
			var sr: Rect2 = SLOTS[i].r
			if SLOTS[i].kind in ["floor", "big", "wide"]:
				_shadow(Vector2(sr.get_center().x, sr.end.y - 2), sr.size.x * 0.48, 7.0, 0.3)
			_draw_item(self, id, sr)
	# 擺設模式：格位
	if deco:
		for i in SLOTS.size():
			var r: Rect2 = SLOTS[i].r
			var on := i == sel_slot
			var c := UITheme.ACCENT if on else Color(0.62, 0.85, 1.0)
			draw_rect(r, Color(c.r, c.g, c.b, 0.16 if on else 0.08))
			_dash_rect(r, c, 2.0)
			var lab := "%d %s" % [i + 1, KIND_NAME[SLOTS[i].kind]]
			draw_string_outline(font, r.position + Vector2(4, 16), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 5, Color(0.05, 0.05, 0.12))
			draw_string(font, r.position + Vector2(4, 16), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, c)
	else:
		for i in SLOTS.size():
			if _placed(i) == "":
				var r: Rect2 = SLOTS[i].r
				_dash_rect(r, Color(1, 0.95, 0.77, 0.22 + 0.08 * sin(t * 2.0 + i)), 1.5)
	# 光靈
	var bob := sin(t * 3.0) * 4.0
	var sp := _spirit + Vector2(0, bob)
	UITheme.dot(self, _spirit + Vector2(0, 34), 26.0, Color(0, 0, 0, 0.22))
	# 往左走就面向左（左右翻轉）
	if _spirit_to.x < _spirit.x - 1.0:
		_face_left = true
	elif _spirit_to.x > _spirit.x + 1.0:
		_face_left = false
	if _face_left:
		draw_set_transform(sp, 0.0, Vector2(-1, 1))
		SL.draw_all(self, Vector2.ZERO, 26.0, Game.of(self).equipped, t)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		SL.draw_all(self, sp, 26.0, Game.of(self).equipped, t)
	if _say_t > 0.0 and _say != "":
		var tw := font.get_string_size(_say, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var br := Rect2(sp + Vector2(-tw / 2.0 - 12, -78), Vector2(tw + 24, 30))
		draw_style_box(UITheme.box(Color("fff3c4"), 14, Color(0, 0, 0, 0), 0, 0), br)
		draw_string(font, br.position + Vector2(12, 21), _say, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("2a2440"))


func _dash_rect(r: Rect2, c: Color, w: float) -> void:
	draw_dashed_line(r.position, Vector2(r.end.x, r.position.y), c, w, 6.0)
	draw_dashed_line(Vector2(r.end.x, r.position.y), r.end, c, w, 6.0)
	draw_dashed_line(r.end, Vector2(r.position.x, r.end.y), c, w, 6.0)
	draw_dashed_line(Vector2(r.position.x, r.end.y), r.position, c, w, 6.0)


## 透視房間：天花板、左右側牆、往前展開的地板（消失點在畫面中間偏上）
const VP := Vector2(576, 250)


func _poly(pts: Array, c: Color) -> void:
	draw_colored_polygon(PackedVector2Array(pts), c)


func _draw_room() -> void:
	var L := WALL.position.x
	var R := WALL.end.x
	var T := WALL.position.y
	var B := FLOOR_Y
	var FL := Vector2(-90, H)          # 地板前緣（畫面外一點）
	var FR := Vector2(W + 90, H)
	# 地板往前到畫面底的直線：左右側牆的底線
	var lb := Vector2(0, B + (H - B) * (L / (L - FL.x)))
	var rb := Vector2(W, B + (H - B) * ((W - R) / (FR.x - R)))
	# 天花板
	_poly([Vector2(0, 0), Vector2(W, 0), Vector2(R, T), Vector2(L, T)], Color("221a36"))
	for k in 4:
		var f := (k + 1) / 5.0
		draw_line(Vector2(L * (1.0 - f) + 0, T * (1.0 - f)), Vector2(R + (W - R) * f, T * (1.0 - f)), Color(1, 1, 1, 0.03), 2.0)
	# 側牆（比後牆暗）
	_poly([Vector2(0, 0), Vector2(L, T), Vector2(L, B), lb], Color("2a2142"))
	_poly([Vector2(W, 0), Vector2(R, T), Vector2(R, B), rb], Color("2a2142"))
	# 後牆＋下半部牆裙
	draw_rect(WALL, Color("3a2f52"))
	draw_rect(Rect2(L, 300, R - L, B - 300), Color("33294a"))
	draw_rect(Rect2(L, 296, R - L, 6), Color("4a3d66"))
	for k in 12:
		var x := L + 40 + k * 84
		draw_line(Vector2(x, 302), Vector2(x, B - 4), Color(0, 0, 0, 0.08), 2.0)
	# 窗戶灑進來的月光（後牆上的光暈）
	for k in 5:
		UITheme.dot(self, WINDOW.get_center() + Vector2(0, 20), 150.0 - k * 26.0, Color(0.6, 0.7, 1.0, 0.025))
	# 側牆的牆裙
	_poly([Vector2(L, 300), Vector2(L, B), lb, Vector2(0, 300 + (300 - T) * 0.0 + (lb.y - B) * 0.55)], Color("261e3c"))
	_poly([Vector2(R, 300), Vector2(R, B), rb, Vector2(W, 300 + (rb.y - B) * 0.55)], Color("261e3c"))
	# 地板（梯形）
	_poly([Vector2(L, B), Vector2(R, B), FR, FL], Color("6b4f3e"))
	# 木板：往消失點收斂的縫
	for k in 15:
		var bx := L + (R - L) * k / 14.0
		var d := (Vector2(bx, B) - VP).normalized()
		var fx := VP + d * ((H - VP.y) / d.y)
		draw_line(Vector2(bx, B), fx, Color(0, 0, 0, 0.14), 2.0)
	# 橫向接縫：越前面間距越大
	var yy := B
	var gap := 14.0
	while yy < H:
		yy += gap
		gap *= 1.35
		draw_line(Vector2(0, yy), Vector2(W, yy), Color(0, 0, 0, 0.1), 1.5)
	# 窗光落在地板上
	var wl := WINDOW.position.x
	var wr := WINDOW.end.x
	_poly([Vector2(wl + 10, B + 6), Vector2(wr - 10, B + 6), Vector2(wr + 70, H - 20), Vector2(wl - 70, H - 20)], Color(0.65, 0.75, 1.0, 0.07))
	# 踢腳板（後牆＋兩側）
	draw_rect(Rect2(L, B - 10, R - L, 10), Color("4a3a2e"))
	_poly([Vector2(L, B - 10), Vector2(L, B), lb, lb + Vector2(0, -18)], Color("3e3026"))
	_poly([Vector2(R, B - 10), Vector2(R, B), rb, rb + Vector2(0, -18)], Color("3e3026"))
	# 牆角的陰影線
	draw_line(Vector2(L, T), Vector2(L, B), Color(0, 0, 0, 0.35), 3.0)
	draw_line(Vector2(R, T), Vector2(R, B), Color(0, 0, 0, 0.35), 3.0)
	draw_line(Vector2(L, T), Vector2(R, T), Color(0, 0, 0, 0.3), 3.0)
	draw_line(Vector2(L, B), Vector2(R, B), Color(0, 0, 0, 0.3), 2.0)
	# 前景暗角
	for k in 4:
		draw_rect(Rect2(0, H - 10 - k * 10, W, 10), Color(0, 0, 0, 0.06 * (4 - k)))


## 貼地的橢圓陰影
func _shadow(c: Vector2, rx: float, ry: float, a := 0.28) -> void:
	var pts := PackedVector2Array()
	for k in 24:
		var ang := TAU * k / 24.0
		pts.append(c + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(pts, Color(0, 0, 0, a))


func _draw_window() -> void:
	var r := WINDOW
	# 窗框內側的厚度（看得到牆的深度）
	draw_rect(r.grow(10), Color("2a2142"))
	_poly([r.position - Vector2(10, 10), Vector2(r.end.x + 10, r.position.y - 10), Vector2(r.end.x, r.position.y), r.position], Color("1e1830"))
	draw_rect(r, Color("142458"))
	var mc := r.position + Vector2(130, 36)
	UITheme.dot(self, mc, 20.0, Color("fff3d6"))
	UITheme.dot(self, mc + Vector2(9, -5), 18.0, Color("142458"))
	for k in 6:
		var sp := r.position + Vector2(20 + (k * 47) % 140, 20 + (k * 31) % 100)
		UITheme.dot(self, sp, 1.6 + 0.6 * sin(t * 2.0 + k), Color(1, 0.96, 0.85, 0.8))
	draw_rect(r, Color("c9a46e"), false, 6.0)
	draw_line(r.position + Vector2(r.size.x / 2.0, 0), r.position + Vector2(r.size.x / 2.0, r.size.y), Color("c9a46e"), 4.0)
	draw_line(r.position + Vector2(0, r.size.y / 2.0), r.position + Vector2(r.size.x, r.size.y / 2.0), Color("c9a46e"), 4.0)
	# 窗台：上面一塊往前凸的台面（看得到頂面）＋正面＋下方陰影
	var sy := r.end.y + 6
	_poly([Vector2(r.position.x - 14, r.end.y), Vector2(r.end.x + 14, r.end.y), Vector2(r.end.x + 26, sy + 6), Vector2(r.position.x - 26, sy + 6)], Color("a8865e"))
	draw_rect(Rect2(r.position.x - 26, sy + 6, r.size.x + 52, 10), Color("7a5a40"))
	draw_rect(Rect2(r.position.x - 22, sy + 16, r.size.x + 44, 6), Color(0, 0, 0, 0.22))


func _draw_shelf(font: Font) -> void:
	var r := SHELF
	var dp := Vector2(16, -12)     # 櫃子的深度：往後（右上，朝消失點）縮進牆裡
	_shadow(Vector2(r.get_center().x + 8, r.end.y + 4), r.size.x * 0.6, 10.0)
	var tr := Vector2(r.end.x, r.position.y)
	# 右側面（櫃子在消失點左邊，所以看得到右側）、頂面
	_poly([tr, r.end, r.end + dp, tr + dp], Color("4a3224"))
	_poly([r.position, tr, tr + dp, r.position + dp], Color("9a7a58"))
	# 正面
	draw_rect(r, Color("5a3f2e"))
	draw_rect(r.grow(-8), Color("3e2a1e"))   # 內部（比較暗，看起來凹進去）
	draw_rect(r, Color("8a6a4e"), false, 6.0)
	var title := "紀念品櫃"
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(font, Vector2(r.position.x + (r.size.x - tw) / 2.0, r.position.y - 8), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe7a3"))
	var rows := ["高一", "高二", "高三"]
	for k in 3:
		var y := r.position.y + 20 + k * 104
		draw_string(font, Vector2(r.position.x + 10, y + 12), rows[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f0d29a"))
		_poly([Vector2(r.position.x + 6, y + 80), Vector2(r.end.x - 6, y + 80), Vector2(r.end.x - 6, y + 84), Vector2(r.position.x + 6, y + 84)], Color("a8865e"))
		draw_rect(Rect2(r.position.x + 6, y + 84, r.size.x - 12, 7), Color("7a5a40"))
		draw_rect(Rect2(r.position.x + 6, y + 91, r.size.x - 12, 5), Color(0, 0, 0, 0.25))
		var units := []
		for term in Units.GRADES.get(rows[k], []):
			units.append_array(Units.units_of_term(term))
		var x := r.position.x + 16
		for u in units:
			if x > r.end.x - 24:
				break
			var base := Vector2(x + 12, y + 80)
			SA.draw(self, u.id, base, 34.0, t + x * 0.37, _sv_state(u))
			x += 25


func _draw_board(font: Font) -> void:
	var r := BOARD
	draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.25))
	draw_rect(r, Color("a07a4e"))
	draw_rect(r, Color("6b4f2e"), false, 6.0)
	var notes := [[Vector2(14, 14), Color("fff3d6")], [Vector2(104, 18), Color("d6f0ff")], [Vector2(54, 70), Color("ffd6ec")]]
	for n in notes:
		draw_rect(Rect2(r.position + n[0], Vector2(80, 46)), n[1])
		UITheme.dot(self, r.position + n[0] + Vector2(40, 4), 4.0, Color("c0392b"))
	var title := "布告欄 · 每日任務"
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(font, Vector2(r.position.x + (r.size.x - tw) / 2.0, r.position.y - 8), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffe7a3"))


func _draw_desk(font: Font) -> void:
	var r := DESK
	_shadow(Vector2(r.get_center().x, FLOOR_Y + 22), r.size.x * 0.58, 12.0)
	# 後腳（短、暗）
	draw_rect(Rect2(r.position.x + 22, r.end.y, 10, FLOOR_Y - r.end.y - 2), Color("4a3426"))
	draw_rect(Rect2(r.end.x - 32, r.end.y, 10, FLOOR_Y - r.end.y - 2), Color("4a3426"))
	# 桌面：頂面（梯形往後縮）＋正面
	_poly([r.position + Vector2(10, -16), Vector2(r.end.x - 10, r.position.y - 16), Vector2(r.end.x, r.position.y), r.position], Color("a8744a"))
	draw_rect(r, Color("7a4a2e"))
	draw_line(r.position, Vector2(r.end.x, r.position.y), Color(1, 0.85, 0.6, 0.35), 2.0)
	# 前腳
	draw_rect(Rect2(r.position.x + 8, r.end.y, 14, FLOOR_Y - r.end.y + 26), Color("6b4f2e"))
	draw_rect(Rect2(r.end.x - 22, r.end.y, 14, FLOOR_Y - r.end.y + 26), Color("6b4f2e"))
	# 檯燈和攤開的書
	var lp := Vector2(r.position.x + 120, r.position.y)
	UITheme.dot(self, lp + Vector2(0, -40), 34.0, Color(1, 0.85, 0.4, 0.12 + 0.04 * sin(t * 2.0)))
	draw_line(lp, lp + Vector2(0, -34), Color("c9a46e"), 3.0)
	draw_colored_polygon(PackedVector2Array([lp + Vector2(-16, -30), lp + Vector2(16, -30), lp + Vector2(8, -46), lp + Vector2(-8, -46)]), Color("f5c84c"))
	draw_rect(Rect2(r.position.x + 74, r.position.y - 8, 34, 8), Color("e8dcc0"))


## 畫一件家具：r 是格位（底部對齊格位的底）
static func _draw_item(ci: CanvasItem, id: String, r: Rect2, dim := false) -> void:
	var it := HI.item(id)
	if it.is_empty():
		return
	var c: Color = it.col
	if dim:
		c = Color(0.35, 0.38, 0.5)
	var b := Vector2(r.get_center().x, r.end.y)      # 底部中間
	var s := minf(r.size.x, r.size.y * 1.6)
	match String(it.draw):
		"moonlamp":
			UITheme.dot(ci, b + Vector2(0, -s * 0.45), s * 0.32, c)
			UITheme.dot(ci, b + Vector2(s * 0.12, -s * 0.5), s * 0.26, Color(0.2, 0.18, 0.32) if not dim else c.darkened(0.3))
			ci.draw_rect(Rect2(b + Vector2(-s * 0.2, -s * 0.12), Vector2(s * 0.4, s * 0.12)), Color("8a6a4e"))
		"cactus":
			ci.draw_rect(Rect2(b + Vector2(-s * 0.18, -s * 0.22), Vector2(s * 0.36, s * 0.22)), Color("c97b5a"))
			ci.draw_rect(Rect2(b + Vector2(-s * 0.08, -s * 0.75), Vector2(s * 0.16, s * 0.55)), c)
			ci.draw_rect(Rect2(b + Vector2(s * 0.08, -s * 0.6), Vector2(s * 0.12, s * 0.08)), c)
			ci.draw_rect(Rect2(b + Vector2(s * 0.14, -s * 0.72), Vector2(s * 0.07, s * 0.16)), c)
		"frame":
			var fr := r.grow(-6)
			ci.draw_rect(fr, Color("1a2a5a"))
			ci.draw_rect(fr, Color("c9a46e"), false, 4.0)
			for k in 4:
				UITheme.dot(ci, fr.position + Vector2(10 + k * 17, 14 + (k % 2) * 20), 2.5, c)
		"clock":
			var cc := r.get_center()
			UITheme.dot(ci, cc, s * 0.38, Color("f0e6d0") if not dim else c)
			ci.draw_arc(cc, s * 0.38, 0, TAU, 32, Color("8a6a4e"), 4.0, true)
			ci.draw_line(cc, cc + Vector2(0, -s * 0.25), Color("2a2440"), 3.0)
			ci.draw_line(cc, cc + Vector2(s * 0.18, 0), Color("2a2440"), 3.0)
		"books":
			var cols := [Color("ff9a5a"), Color("5fd4ff"), Color("6ee7a0")]
			for k in 3:
				ci.draw_rect(Rect2(b + Vector2(-s * 0.4 + k * 3, -s * 0.18 * (k + 1)), Vector2(s * 0.8, s * 0.17)), cols[k] if not dim else c)
		"candle":
			ci.draw_rect(Rect2(b + Vector2(-s * 0.14, -s * 0.5), Vector2(s * 0.28, s * 0.5)), c)
			UITheme.dot(ci, b + Vector2(0, -s * 0.62), s * 0.1, Color("ffd36e") if not dim else c)
		"starstring":
			ci.draw_line(r.position + Vector2(4, 10), Vector2(r.end.x - 4, r.position.y + 10), Color("c9a46e"), 2.0)
			for k in 4:
				var p := r.position + Vector2(12 + k * (r.size.x - 24) / 3.0, 26 + (k % 2) * 16)
				ci.draw_line(Vector2(p.x, r.position.y + 10), p, Color("c9a46e"), 1.0)
				_star(ci, p, 8.0, c)
		"rug":
			var pts := PackedVector2Array()
			for k in 32:
				var a := TAU * k / 32.0
				pts.append(r.get_center() + Vector2(cos(a) * r.size.x * 0.5, sin(a) * r.size.y * 0.5))
			ci.draw_colored_polygon(pts, c)
			pts.append(pts[0])
			ci.draw_polyline(pts, c.lightened(0.3), 3.0, true)
		"stool":
			ci.draw_rect(Rect2(b + Vector2(-s * 0.4, -s * 0.55), Vector2(s * 0.8, s * 0.14)), c)
			ci.draw_rect(Rect2(b + Vector2(-s * 0.32, -s * 0.42), Vector2(s * 0.1, s * 0.42)), c.darkened(0.2))
			ci.draw_rect(Rect2(b + Vector2(s * 0.22, -s * 0.42), Vector2(s * 0.1, s * 0.42)), c.darkened(0.2))
		"pottree":
			ci.draw_rect(Rect2(b + Vector2(-s * 0.2, -s * 0.25), Vector2(s * 0.4, s * 0.25)), Color("c97b5a"))
			ci.draw_rect(Rect2(b + Vector2(-3, -r.size.y * 0.7), Vector2(6, r.size.y * 0.5)), Color("6b4f2e"))
			UITheme.dot(ci, b + Vector2(0, -r.size.y * 0.72), s * 0.4, c)
		"cushion":
			UITheme.dot(ci, b + Vector2(0, -s * 0.3), s * 0.42, c)
			UITheme.dot(ci, b + Vector2(-s * 0.1, -s * 0.38), s * 0.2, c.lightened(0.2))
		"bookcase":
			ci.draw_rect(r, c)
			for k in 4:
				var y := r.position.y + 10 + k * (r.size.y - 14) / 4.0
				ci.draw_rect(Rect2(r.position.x + 4, y + (r.size.y - 14) / 4.0 - 6, r.size.x - 8, 5), c.darkened(0.3))
				for q in int((r.size.x - 12) / 10):
					ci.draw_rect(Rect2(r.position.x + 6 + q * 10, y + 6, 8, (r.size.y - 14) / 4.0 - 14), [Color("ff9a5a"), Color("5fd4ff"), Color("6ee7a0"), Color("ffd6ec")][(q + k) % 4] if not dim else c.lightened(0.1))
		"globe":
			var gc := b + Vector2(0, -s * 0.6)
			ci.draw_rect(Rect2(b + Vector2(-s * 0.2, -s * 0.1), Vector2(s * 0.4, s * 0.1)), Color("8a6a4e"))
			ci.draw_line(b + Vector2(0, -s * 0.1), gc, Color("8a6a4e"), 3.0)
			UITheme.dot(ci, gc, s * 0.32, c)
			UITheme.dot(ci, gc + Vector2(-s * 0.08, -s * 0.06), s * 0.12, Color("6ee7a0") if not dim else c.lightened(0.2))
		"sofa":
			ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.45), Vector2(r.size.x, r.size.y * 0.4)), c)
			ci.draw_rect(Rect2(r.position + Vector2(4, r.size.y * 0.25), Vector2(r.size.x - 8, r.size.y * 0.25)), c.darkened(0.15))
			ci.draw_rect(Rect2(r.position + Vector2(8, r.size.y * 0.85), Vector2(8, r.size.y * 0.15)), Color("4a3426"))
			ci.draw_rect(Rect2(r.end - Vector2(16, r.size.y * 0.15), Vector2(8, r.size.y * 0.15)), Color("4a3426"))
		"telescope":
			ci.draw_line(b, b + Vector2(-s * 0.3, -r.size.y * 0.35), Color("8a6a4e"), 3.0)
			ci.draw_line(b, b + Vector2(s * 0.3, -r.size.y * 0.35), Color("8a6a4e"), 3.0)
			var tp := b + Vector2(0, -r.size.y * 0.4)
			ci.draw_line(tp + Vector2(-s * 0.35, s * 0.2), tp + Vector2(s * 0.35, -s * 0.35), c, 12.0)
		"piano":
			var pr := Rect2(r.position + Vector2(0, r.size.y * 0.2), Vector2(r.size.x, r.size.y * 0.8))
			ci.draw_rect(pr, c)
			ci.draw_rect(Rect2(pr.position - Vector2(4, 6), Vector2(pr.size.x + 8, 8)), c.lightened(0.25))
			ci.draw_rect(pr, c.lightened(0.35), false, 2.0)
			ci.draw_rect(Rect2(r.position + Vector2(4, r.size.y * 0.55), Vector2(r.size.x - 8, 10)), Color("fffaf0"))
			for k in int((r.size.x - 10) / 8):
				ci.draw_rect(Rect2(r.position + Vector2(8 + k * 8, r.size.y * 0.55), Vector2(4, 6)), Color("2a2440"))
		"stonepot":
			ci.draw_rect(Rect2(b + Vector2(-s * 0.3, -s * 0.28), Vector2(s * 0.6, s * 0.28)), Color("c97b5a"))
			for k in 3:
				UITheme.dot(ci, b + Vector2(-s * 0.16 + k * s * 0.16, -s * 0.38), s * 0.11, c)
		"shell":
			var cc := b + Vector2(0, -s * 0.3)
			var sp := PackedVector2Array()
			for k in 40:
				var a := k * 0.35
				sp.append(cc + Vector2(cos(a), sin(a)) * (2.0 + k * s * 0.008))
			ci.draw_polyline(sp, c, 3.0, true)
		"dice":
			var dr := Rect2(b + Vector2(-s * 0.28, -s * 0.56), Vector2(s * 0.56, s * 0.56))
			ci.draw_rect(dr, c)
			ci.draw_rect(dr, Color("8a6a4a"), false, 2.0)
			for q in [Vector2(-0.12, -0.12), Vector2(0.12, 0.12), Vector2(0, 0)]:
				UITheme.dot(ci, dr.get_center() + q * s, s * 0.05, Color("2a2440"))
		"shipbottle":
			var bc := b + Vector2(0, -s * 0.28)
			ci.draw_rect(Rect2(bc - Vector2(s * 0.4, s * 0.22), Vector2(s * 0.8, s * 0.44)), Color(c.r, c.g, c.b, 0.35))
			ci.draw_rect(Rect2(bc - Vector2(s * 0.4, s * 0.22), Vector2(s * 0.8, s * 0.44)), c, false, 2.0)
			ci.draw_colored_polygon(PackedVector2Array([bc + Vector2(-s * 0.2, s * 0.06), bc + Vector2(s * 0.2, s * 0.06), bc + Vector2(s * 0.14, s * 0.14), bc + Vector2(-s * 0.14, s * 0.14)]), Color("8a5a3a"))
			ci.draw_line(bc + Vector2(0, s * 0.06), bc + Vector2(0, -s * 0.14), Color("fffaf0"), 2.0)
		"orb":
			UITheme.dot(ci, b + Vector2(0, -s * 0.42), s * 0.32, Color(c.r, c.g, c.b, 0.55))
			ci.draw_arc(b + Vector2(0, -s * 0.42), s * 0.18, 0, 4.5, 16, Color(1, 1, 1, 0.7), 2.0, true)
			ci.draw_rect(Rect2(b + Vector2(-s * 0.2, -s * 0.12), Vector2(s * 0.4, s * 0.12)), Color("8a6a4e"))
		_:
			UITheme.dot(ci, b + Vector2(0, -s * 0.3), s * 0.3, c)


static func _star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2.0 + k * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, col)


## 抽屜、商店裡的家具小圖
class ItemPreview extends Control:
	var house
	var id := ""
	var dim := false

	func _draw() -> void:
		if id == "":
			draw_line(Vector2(size.x * 0.3, size.y * 0.3), Vector2(size.x * 0.7, size.y * 0.7), Color(1, 1, 1, 0.5), 3.0)
			draw_line(Vector2(size.x * 0.7, size.y * 0.3), Vector2(size.x * 0.3, size.y * 0.7), Color(1, 1, 1, 0.5), 3.0)
			return
		var r := Rect2(Vector2(size.x / 2.0 - 30, 2), Vector2(60, size.y - 4))
		house._draw_item(self, id, r, dim)


## 紀念品（會動的：100% 的特效）
class SouvenirView extends Control:
	const SA := preload("souvenir_art.gd")
	var uid := ""
	var state := 0
	var s := 30.0
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		if uid != "":
			SA.draw(self, uid, Vector2(size.x / 2.0, size.y - 2.0), s, t, state)


## 紀念品櫃視窗裡的小寶石
class SouvenirIcon extends Control:
	const UITheme := preload("game_theme.gd")
	var col := Color.WHITE
	var lit := false

	func _draw() -> void:
		var c := size / 2.0
		if lit:
			UITheme.dot(self, c, 15.0, Color(col.r, col.g, col.b, 0.35))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -12), c + Vector2(10, 0), c + Vector2(0, 12), c + Vector2(-10, 0)]), col)
		else:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -12), c + Vector2(10, 0), c + Vector2(0, 12), c + Vector2(-10, 0)]), Color(1, 1, 1, 0.1))
