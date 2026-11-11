extends VBoxContainer
## 觀念整理：互動式卡片
##   先看到卡片清單（像選關畫面），想看哪張就點哪張
##   一般卡片：內容一開始就全部亮出來；空格要填的東西變成積木，散在下面的積木區，要拖進對應的空格
##     有一兩塊是「干擾積木」（卡片的 decoys），放哪裡都不對；放錯不扣分，積木彈回去，那一行亮起來提醒再讀一次
##     同一張卡片裡可以互換的空格寫在 swap（例如 cos 2θ 的三種寫法），答案一樣的積木放哪一格都可以
##   隨堂小測：積木填完之後，答對一題才算完成
##   解題流程：把步驟積木照順序拖進編號格子（decoys 是一個錯的步驟）
##   第一次完成一張卡片：星塵 +5（記在 Game.concepts，不會重複領）
## 內容寫在各單元的卡片檔（指數與對數是 concepts_exp.gd，入口 concept_cards.gd）

const UITheme := preload("res://data/ui/game_theme.gd")
const MathLabel := preload("res://data/ui/math_text.gd")
const Game := preload("res://data/core/game.gd")
const Gen := preload("res://data/core/gen_token.gd")

signal closed(start: bool)   # start = true：按了清單上的「開始挑戰」

const REWARD := 5            # 第一次完成一張卡片的星塵
const HINTS := [
	"這一塊不是放這裡——再讀一次亮起來的這一行，前後的條件是什麼？",
	"看看這一行前半句在說什麼，再想想哪一塊才會讓它成立。",
	"先別急著放：把亮起來的這一行完整讀一遍。",
	"有一兩塊積木是多出來的陷阱，不是每一塊都用得到喔！",
]

var cards: Array = []
var color := Color.WHITE
var level_name := ""
var lid := ""                   # 大關的代號（存檔用）
var progress: Dictionary = {}   # 卡片編號 -> {"fill": {空格編號: 放進去的積木}, "check": 小測答對, "order": [依序放好的步驟]}
var idx := 0
var mode := "list"              # list / card / check / order

var _body: PanelContainer
var _slide: MarginContainer
var _deco: ConceptGlyph
var _dots: ConceptDots
var _primary: Button
var _prev: Button
var _back: Button
var _redo: Button
var _counter: Label
var _feedback: MathLabel
var _rows: Array = []
var _slots: Array = []          # 這張卡片的空格
var _tiles: Array = []          # 積木區裡的積木
var _tray: Control
var _drag: ConceptTile
var _gen := Gen.new()           # 世代號碼（gen_token.gd）：換頁就 bump（非同步排版時用來判斷還是不是同一張）
var _hint_i := 0
var _pointer: ConceptPointer
var _idle := 0.0
static var _taps := 0
const GUIDE_TAPS := 3
const GUIDE_IDLE := 5.0


func setup(title: String, deck: Array, c: Color, prog: Dictionary, start := -1, level_id := "") -> void:
	level_name = title
	cards = deck
	color = c
	progress = prog
	lid = level_id
	idx = start


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	# 外框留白少一點：卡片內容、積木區都要放得下
	var card := get_parent().get_parent() as PanelContainer if get_parent() != null else null
	if card != null and card.get_theme_stylebox("panel") is StyleBoxFlat:
		var csb: StyleBoxFlat = card.get_theme_stylebox("panel").duplicate()
		csb.content_margin_top = 14
		csb.content_margin_bottom = 12
		csb.content_margin_left = 20
		csb.content_margin_right = 20
		card.add_theme_stylebox_override("panel", csb)
	var top := HBoxContainer.new()
	add_child(top)
	var lt := Label.new()
	lt.text = level_name + "　·　觀念整理"
	lt.add_theme_font_size_override("font_size", UITheme.fs(15))
	lt.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	lt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(lt)
	_dots = ConceptDots.new()
	_dots.deck = self
	_dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_dots)

	_body = PanelContainer.new()
	var sb := UITheme.box(UITheme.PANEL_LIGHT, 18, Color(color.r, color.g, color.b, 0.35), 1, 14)
	sb.border_width_left = 6
	sb.border_color = color
	_body.add_theme_stylebox_override("panel", sb)
	_body.custom_minimum_size = Vector2(1040, 0)
	_body.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _idle = 0.0)
	add_child(_body)
	_deco = ConceptGlyph.new()
	_deco.color = color
	_deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_deco)
	_slide = MarginContainer.new()
	_slide.mouse_filter = Control.MOUSE_FILTER_PASS
	_body.add_child(_slide)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 12)
	add_child(nav)
	_back = UITheme.ghost_button("回到章節", 15)
	_back.icon = UITheme.icon("back", 15, UITheme.TEXT_DIM)
	_back.pressed.connect(_on_back)
	nav.add_child(_back)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(sp)
	_counter = Label.new()
	_counter.add_theme_font_size_override("font_size", UITheme.fs(15))
	_counter.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nav.add_child(_counter)
	_redo = UITheme.ghost_button("↺ 重新練習", 15)
	_redo.pressed.connect(_on_redo)
	nav.add_child(_redo)
	_prev = UITheme.ghost_button("‹ 回卡片", 16)
	_prev.pressed.connect(_on_prev)
	nav.add_child(_prev)
	_primary = Button.new()
	_primary.focus_mode = Control.FOCUS_NONE
	UITheme.accent_button(_primary, 17)
	_primary.custom_minimum_size = Vector2(190, 46)
	_primary.pressed.connect(_on_primary)
	nav.add_child(_primary)
	_pointer = ConceptPointer.new()
	_pointer.color = UITheme.ACCENT
	_pointer.top_level = true
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.z_index = 10
	add_child(_pointer)
	if idx >= 0 and idx < cards.size():
		_show(idx, 0)
	else:
		_show_list()


func _process(delta: float) -> void:
	_idle += delta
	_fit()
	_update_guide()


## 卡片內容比畫面高的時候（例如空格很多的卡片）：整個視窗等比例縮小到放得下
func _fit() -> void:
	var card := get_parent().get_parent() as Control if get_parent() != null else null
	if card == null or not (card is PanelContainer):
		return
	var need := card.get_combined_minimum_size().y
	var avail := get_viewport_rect().size.y - 10.0
	var f := clampf(avail / maxf(1.0, need), 0.7, 1.0)
	# 縮小之後要剛好在畫面正中間：放大縮小的支點照卡片現在的位置算
	var vh := get_viewport_rect().size.y
	var py := card.size.y / 2.0
	if f < 0.999:
		py = ((vh - card.size.y * f) / 2.0 - card.position.y) / (1.0 - f)
	card.pivot_offset = Vector2(card.size.x / 2.0, py)
	if absf(card.scale.x - f) > 0.002:
		card.scale = Vector2(f, f)


## 現在整個視窗縮放了多少（拖曳中的積木要跟著）
func _sc() -> float:
	var card := get_parent().get_parent() as Control if get_parent() != null else null
	return card.scale.x if card != null else 1.0


## 引導：主要按鈕上方的浮標告訴學生現在該做什麼
func _update_guide() -> void:
	if _pointer == null or not is_instance_valid(_primary):
		return
	var text := ""
	match mode:
		"list":
			text = ""
		"card":
			if not _filled_all():
				text = ""
			elif cards[idx].has("check") and not _prog(idx).check:
				text = "最後來一題小測驗"
			else:
				text = "完成了！前往下一張" if idx < cards.size() - 1 else "回清單看看還有哪幾張"
	var show := text != "" and not _primary.disabled and (_taps < GUIDE_TAPS or _idle >= GUIDE_IDLE)
	_pointer.target = _primary.get_global_rect()
	_pointer.set_text(text)
	_pointer.want = show
	var glow := 0.0
	if _pointer.alpha > 0.01:
		glow = (0.5 + 0.5 * sin(_pointer.t * 4.0)) * 0.22 * _pointer.alpha
	_primary.self_modulate = Color(1 + glow, 1 + glow, 1 + glow)


func _guide_tap() -> void:
	_taps += 1
	_idle = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		if not _primary.disabled:
			_on_primary()
		get_viewport().set_input_as_handled()


# ───────────────────────── 進度、存檔 ─────────────────────────

func _key(i: int) -> String:
	return "%s|%s" % [lid, String(cards[i].title)]


func _saved(i: int) -> bool:
	var g = Game.of(self)
	return g != null and (g.concepts as Dictionary).has(_key(i))


func _prog(i: int) -> Dictionary:
	if not progress.has(i):
		progress[i] = {"fill": {}, "check": false, "order": []}
	var p: Dictionary = progress[i]
	for k in [["fill", {}], ["check", false], ["order", []]]:
		if not p.has(k[0]):
			p[k[0]] = k[1]
	return p


func card_done(i: int) -> bool:
	if _saved(i):
		return true
	var cd: Dictionary = cards[i]
	var p := _prog(i)
	if cd.get("kind", "") == "order":
		return (p.order as Array).size() >= (cd.steps as Array).size()
	return (p.fill as Dictionary).size() >= blank_count(cd) and (not cd.has("check") or p.check)


static func blank_count(cd: Dictionary) -> int:
	var n := 0
	for m in _lines(cd):
		for sg in _parse(m):
			if sg.h:
				n += 1
	return n


static func _lines(cd: Dictionary) -> Array:
	var out: Array = []
	out.append_array(cd.get("formulas", []))
	out.append_array(cd.get("notes", []))
	for k in ["example", "trap"]:
		if cd.has(k):
			out.append(cd[k])
	return out


## 第一次完成：存檔、給星塵
func _complete(i: int) -> void:
	if _saved(i):
		return
	var g = Game.of(self)
	if g == null:
		return
	g.concepts[_key(i)] = true
	g.inv["dust"] = int(g.inv.get("dust", 0)) + REWARD
	g.save_review()
	g.sfx("success")
	if _feedback != null:
		_feedback.text += "　[color=#ffd36e]星塵 +%d[/color]" % REWARD
	_burst(_primary.get_global_rect().get_center(), 22)
	# 卡片中間飄出「+5 星塵」
	var pop := Label.new()
	pop.text = "+%d" % REWARD
	var pop_ic := preload("res://data/ui/quest_panel.gd").ItemIcon.new()     # 星塵的圖示（全遊戲同一個）
	pop_ic.kind = "dust"
	pop_ic.size = Vector2(40, 40)
	pop_ic.position = Vector2(-44, 2)
	pop.add_child(pop_ic)
	pop.add_theme_font_size_override("font_size", UITheme.fs(30))
	pop.add_theme_color_override("font_color", Color("ffd36e"))
	pop.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.12))
	pop.add_theme_constant_override("outline_size", 10)
	pop.top_level = true
	pop.z_index = 60
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pop)
	var c := _body.get_global_rect().get_center()
	pop.global_position = c - Vector2(30, 20)
	var tw := pop.create_tween().set_parallel(true)
	tw.tween_property(pop, "global_position:y", c.y - 90.0, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(pop, "modulate:a", 0.0, 0.5).set_delay(0.8)
	tw.chain().tween_callback(pop.queue_free)


# ───────────────────────── 卡片清單 ─────────────────────────

func _clear_slide() -> void:
	_gen.bump()
	for ch in _slide.get_children():
		ch.queue_free()
	_rows.clear()
	_slots.clear()
	_tiles.clear()
	_feedback = null
	_tray = null
	_drag = null


func _show_list() -> void:
	mode = "list"
	_clear_slide()
	_deco.text = ""
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	_slide.add_child(inner)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	inner.add_child(head)
	var t := Label.new()
	t.text = "觀念卡片"
	t.add_theme_font_size_override("font_size", UITheme.fs(24))
	t.add_theme_color_override("font_color", UITheme.TEXT)
	head.add_child(t)
	var sub := Label.new()
	sub.text = "第一次完成一張：星塵 +%d" % REWARD
	sub.add_theme_font_size_override("font_size", UITheme.fs(14))
	sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(sub)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	inner.add_child(grid)
	for i in cards.size():
		var b := _list_tile(i)
		var ii: int = i
		b.pressed.connect(func():
			_guide_tap()
			Game.of(self).play("blip", 1.1, -12.0)
			_show(ii, 1))
		grid.add_child(b)
	_update_nav()


func _list_tile(i: int) -> Button:
	var cd: Dictionary = cards[i]
	var done := card_done(i)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(368, 70)
	var bc := UITheme.GOOD if done else color
	var normal := UITheme.box(Color(0.05, 0.06, 0.14, 0.6), 14, Color(bc.r, bc.g, bc.b, 0.35), 1, 12)
	normal.border_width_left = 5
	normal.border_color = bc
	var hover := UITheme.box(Color(bc.r, bc.g, bc.b, 0.16), 14, bc, 2, 12)
	hover.border_width_left = 5
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_right = -14
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var num := Label.new()
	num.text = "✔" if done else str(i + 1)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.custom_minimum_size = Vector2(36, 36)
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	num.add_theme_font_size_override("font_size", UITheme.fs(18))
	num.add_theme_color_override("font_color", UITheme.PANEL)
	num.add_theme_stylebox_override("normal", UITheme.box(bc, 18, Color(0, 0, 0, 0), 0, 0))
	row.add_child(num)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	var tl := MathLabel.new()
	tl.font_size = UITheme.fs(18)
	tl.color = UITheme.TEXT
	tl.max_width = 210
	tl.text = cd.title
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(tl)
	var tg := Label.new()
	tg.text = "拼出流程" if cd.get("kind", "") == "order" else String(cd.get("tag", ""))
	tg.add_theme_font_size_override("font_size", UITheme.fs(12))
	tg.add_theme_color_override("font_color", Color(bc.r, bc.g, bc.b, 0.9))
	tg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(tg)
	var st := Label.new()
	st.text = "已完成" if done else "+%d 星塵" % REWARD
	st.add_theme_font_size_override("font_size", UITheme.fs(13))
	st.add_theme_color_override("font_color", UITheme.GOOD if done else Color("ffd36e"))
	st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(st)
	return b


# ───────────────────────── 換頁、按鈕 ─────────────────────────

func _show(i: int, dir: int, as_check := false) -> void:
	idx = i
	var cd: Dictionary = cards[idx]
	_clear_slide()
	# 以前完成過的卡片：直接顯示填好的樣子（複習）
	if _saved(idx) and not _prog(idx).has("redo"):
		_fill_saved(idx)
	_deco.text = "" if cd.get("kind", "") == "order" else cd.get("glyph", "")
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	inner.mouse_filter = Control.MOUSE_FILTER_PASS
	_slide.add_child(inner)
	if cd.get("kind", "") == "order":
		mode = "order"
		_build_order(inner, cd)
	elif as_check:
		mode = "check"
		_build_check(inner, cd)
	else:
		mode = "card"
		_build_card(inner, cd)
	_update_nav()
	if dir != 0:
		_body.modulate.a = 0.0
		var tw := _body.create_tween().set_parallel(true)
		tw.tween_property(_body, "modulate:a", 1.0, 0.2)
		var sl := func(v: float) -> void:
			if is_instance_valid(_slide):
				_slide.add_theme_constant_override("margin_left", int(round(v)))
				_slide.add_theme_constant_override("margin_right", -int(round(v)))
		sl.call(36.0 * dir)
		tw.tween_method(sl, 36.0 * dir, 0.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## 完成過的卡片：每一格都填上正確答案、小測算答對
func _fill_saved(i: int) -> void:
	var cd: Dictionary = cards[i]
	var p := _prog(i)
	if cd.get("kind", "") == "order":
		if (p.order as Array).size() < (cd.steps as Array).size():
			p.order = range((cd.steps as Array).size())
		return
	var k := 0
	var fill := {}
	for m in _lines(cd):
		for sg in _parse(m):
			if sg.h:
				fill[k] = sg.t
				k += 1
	p.fill = fill
	p.check = true


func _head(inner: VBoxContainer, badge: String, title: String, tag: String) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	inner.add_child(head)
	var num := Label.new()
	num.text = badge
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.custom_minimum_size = Vector2(36, 36)
	num.add_theme_font_size_override("font_size", UITheme.fs(19))
	num.add_theme_color_override("font_color", UITheme.PANEL)
	num.add_theme_stylebox_override("normal", UITheme.box(color, 18, Color(0, 0, 0, 0), 0, 0))
	head.add_child(num)
	var tl := MathLabel.new()
	tl.font_size = UITheme.fs(22)
	tl.color = UITheme.TEXT
	tl.text = title
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(tl)
	if tag != "":
		var tg := Label.new()
		tg.text = tag
		tg.add_theme_font_size_override("font_size", UITheme.fs(13))
		tg.add_theme_color_override("font_color", color)
		tg.add_theme_stylebox_override("normal", UITheme.box(Color(color.r, color.g, color.b, 0.15), 10, Color(color.r, color.g, color.b, 0.5), 1, 8))
		tg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(tg)


func _next_label() -> String:
	return "下一張 ›" if idx < cards.size() - 1 else "回卡片清單"


func _update_nav() -> void:
	_dots.queue_redraw()
	_back.text = "回到章節" if mode == "list" else "☰ 卡片清單"
	_back.icon = UITheme.icon("back", 15, UITheme.TEXT_DIM) if mode == "list" else null
	_prev.visible = mode == "check"
	_redo.visible = mode in ["card", "order"] and _saved(idx)
	_primary.disabled = false
	_counter.text = ""
	match mode:
		"list":
			var n := 0
			for i in cards.size():
				if card_done(i):
					n += 1
			_counter.text = "完成 %d / %d 張" % [n, cards.size()]
			_primary.text = "開始挑戰  ▶"
		"card":
			var cd: Dictionary = cards[idx]
			var total := _slots.size()
			var got := (_prog(idx).fill as Dictionary).size()
			if got < total:
				_counter.text = "已填 %d / %d 格" % [got, total]
				_primary.text = "把積木拖進空格"
				_primary.disabled = true
			elif cd.has("check") and not _prog(idx).check:
				_primary.text = "隨堂小測  ✦"
			else:
				_primary.text = _next_label()
				_counter.text = "✔ 完成"
		"check":
			_primary.text = _next_label() if _prog(idx).check else "選出答案"
			_primary.disabled = not _prog(idx).check
		"order":
			var placed := (_prog(idx).order as Array).size()
			var n: int = (cards[idx].steps as Array).size()
			_primary.text = _next_label() if placed >= n else "排好才能繼續"
			_primary.disabled = placed < n
			if placed < n:
				_counter.text = "%d / %d 步" % [placed, n]


func _on_primary() -> void:
	_guide_tap()
	match mode:
		"list":
			closed.emit(true)
			return
		"card":
			if not _filled_all():
				return
			if cards[idx].has("check") and not _prog(idx).check:
				Game.of(self).play("blip", 1.25, -10.0)
				_show(idx, 1, true)
				return
	_go_next()


func _go_next() -> void:
	if idx < cards.size() - 1:
		Game.of(self).play("blip", 1.1, -12.0)
		_show(idx + 1, 1)
	else:
		Game.of(self).play("blip", 0.95, -12.0)
		_show_list()


func _on_prev() -> void:
	Game.of(self).play("blip", 0.9, -12.0)
	if mode == "check":
		_show(idx, -1)


func _on_back() -> void:
	if mode == "list":
		closed.emit(false)
	else:
		Game.of(self).play("blip", 0.9, -12.0)
		_show_list()


## 複習時想再練一次：清掉這張的進度重新排（不會再給星塵）
func _on_redo() -> void:
	progress[idx] = {"fill": {}, "check": false, "order": [], "redo": true}
	Game.of(self).play("blip", 1.0, -10.0)
	_show(idx, 0)


# ───────────────────────── 一般卡片：拖積木填空 ─────────────────────────

func _build_card(inner0: VBoxContainer, cd: Dictionary) -> void:
	_head(inner0, str(idx + 1), cd.title, cd.get("tag", ""))
	# 左邊是卡片內容，右邊是積木區（畫面是寬的，上下放不下）
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 18)
	split.mouse_filter = Control.MOUSE_FILTER_PASS
	inner0.add_child(split)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.mouse_filter = Control.MOUSE_FILTER_PASS
	split.add_child(inner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 9)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(left)
	var has_plot: bool = cd.has("plot")
	var wmax := 450.0 if has_plot else 660.0
	var fs: Array = cd.get("formulas", [])
	var short := true
	for f in fs:
		if _text_w(_full(f, color), 21) > (wmax - 40) / 2.0:
			short = false
	var fgrid := GridContainer.new()
	fgrid.columns = 2 if short and fs.size() > 1 else 1
	fgrid.add_theme_constant_override("h_separation", 10)
	fgrid.add_theme_constant_override("v_separation", 8)
	fgrid.mouse_filter = Control.MOUSE_FILTER_PASS
	left.add_child(fgrid)
	for f in fs:
		var fp := PanelContainer.new()
		fp.add_theme_stylebox_override("panel", UITheme.box(Color(0.05, 0.06, 0.14, 0.7), 12, Color(color.r, color.g, color.b, 0.45), 1, 10))
		fp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var fw := (wmax - 40) / (2.0 if fgrid.columns == 2 else 1.0)
		var fsz := 21
		while fsz > 15 and _text_w(_full(f, color), fsz) > fw - 24.0:
			fsz -= 1
		fp.add_child(_line(f, fsz, true, fw - 20.0, Color(1, 0.96, 0.85)))
		fgrid.add_child(fp)
	for n in cd.get("notes", []):
		var nr := HBoxContainer.new()
		nr.add_theme_constant_override("separation", 8)
		nr.mouse_filter = Control.MOUSE_FILTER_PASS
		var bullet := Label.new()
		bullet.text = "▸"
		bullet.add_theme_color_override("font_color", color)
		bullet.add_theme_font_size_override("font_size", UITheme.fs(15))
		bullet.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		nr.add_child(bullet)
		nr.add_child(_line(n, 17, false, wmax - 30, UITheme.TEXT))
		left.add_child(nr)
	for key in ["example", "trap"]:
		if not cd.has(key):
			continue
		var bc := UITheme.GOOD if key == "example" else UITheme.BAD
		var bp := PanelContainer.new()
		bp.add_theme_stylebox_override("panel", UITheme.box(Color(bc.r, bc.g, bc.b, 0.10), 12, Color(bc.r, bc.g, bc.b, 0.45), 1, 10))
		bp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var br := HBoxContainer.new()
		br.add_theme_constant_override("separation", 10)
		bp.add_child(br)
		var badge := Label.new()
		badge.text = "例" if key == "example" else "⚠ 小心"
		badge.add_theme_font_size_override("font_size", UITheme.fs(15))
		badge.add_theme_color_override("font_color", bc)
		badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		br.add_child(badge)
		br.add_child(_line(cd[key], 16, false, wmax - 70, UITheme.TEXT))
		left.add_child(bp)
	if has_plot:
		var pl := ConceptPlot.new()
		pl.curves = cd.plot
		pl.custom_minimum_size = Vector2(240, 220)
		pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(pl)
	# 回復進度：已經放好的格子
	var fill: Dictionary = _prog(idx).fill
	for k in fill:
		if int(k) < _slots.size():
			(_slots[int(k)] as ConceptSlot).set_filled(String(fill[k]), false)
	_feedback = MathLabel.new()
	_feedback.font_size = UITheme.fs(15)
	_feedback.color = UITheme.TEXT
	_feedback.max_width = 680
	_feedback.custom_minimum_size = Vector2(0, 24)
	_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_feedback)
	# 積木區（右邊一欄）：還沒放的答案 + 干擾積木
	var texts: Array = []
	for s in _slots:
		var sl: ConceptSlot = s
		if not sl.filled:
			texts.append([sl.answer, -1])
	if not texts.is_empty():
		for d in cd.get("decoys", []):
			texts.append([String(d), -1])
		_feedback.text = "[color=#9aa3c7]把積木拖進空格。小心有多出來的！[/color]"
		_make_tray(split, texts, 300.0)
	else:
		_feedback.text = "[color=#6ee7a0]✔ 全部填好了！[/color]" + ("" if not cd.has("check") or _prog(idx).check else "　[color=#9aa3c7]最後來一題小測驗。[/color]")


## 一行內容：文字和空格排在一起（太長會換行）
func _line(m: String, fs: int, centered: bool, max_w: float, base: Color) -> Control:
	fs = UITheme.fs(fs)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 4)
	flow.alignment = FlowContainer.ALIGNMENT_CENTER if centered else FlowContainer.ALIGNMENT_BEGIN
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.custom_minimum_size = Vector2(minf(max_w, 120.0), 0)
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for sg in _parse(m):
		var t: String = sg.t
		if sg.h:
			var s := ConceptSlot.new()
			s.answer = t
			s.fs = fs
			s.color = color
			s.line = flow
			s.index = _slots.size()
			s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			_slots.append(s)
			flow.add_child(s)
			continue
		t = t.strip_edges()
		if t == "":
			continue
		# 空格後面緊接著標點（，。、）：標點黏在空格後面一起換行，不會跑到下一行的開頭
		var head := ""
		while t != "" and NO_LINE_START.contains(t.substr(0, 1)):
			head += t.substr(0, 1)
			t = t.substr(1).strip_edges()
		if head != "":
			var last: Control = flow.get_child(flow.get_child_count() - 1) if flow.get_child_count() > 0 else null
			var pl := MathLabel.new()
			pl.font_size = fs
			pl.color = base
			pl.text = head
			pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if last != null:
				var glue := HBoxContainer.new()
				glue.add_theme_constant_override("separation", 2)
				glue.mouse_filter = Control.MOUSE_FILTER_IGNORE
				glue.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				flow.remove_child(last)
				glue.add_child(last)
				glue.add_child(pl)
				flow.add_child(glue)
			else:
				flow.add_child(pl)
			if t == "":
				continue
		var l := MathLabel.new()
		l.font_size = fs
		l.color = base
		l.text = _hl(t, color)
		if MathLabel.text_width(get_theme_default_font(), l.text, fs) > max_w:
			l.max_width = max_w
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		flow.add_child(l)
	return flow


## 不能放在一行開頭的標點（中文排版：避頭點）
##   （不用放全形分號：題目文字本來就不准出現它）
const NO_LINE_START := "，。、：！？）」』》〉,.:!?)"


func _filled_all() -> bool:
	return (_prog(idx).fill as Dictionary).size() >= _slots.size()


## 積木區：積木亂亂地散著（不重疊、不蓋到卡片內容）
func _make_tray(parent: Control, texts: Array, width: float) -> void:
	_tray = Control.new()
	_tray.custom_minimum_size = Vector2(width, 90)
	_tray.size_flags_vertical = Control.SIZE_FILL
	if width <= 0.0:
		_tray.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tray.mouse_filter = Control.MOUSE_FILTER_PASS
	_tray.draw.connect(_draw_tray.bind(_tray))
	parent.add_child(_tray)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var order := range(texts.size())
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = order[i]
		order[i] = order[j]
		order[j] = tmp
	for k in order:
		var tl := ConceptTile.new()
		tl.text = texts[k][0]
		tl.step = int(texts[k][1])
		tl.color = color
		tl.fs = UITheme.fs(17 if mode == "card" else 15)
		tl.deck = self
		tl.modulate.a = 0.0
		_tray.add_child(tl)
		_tiles.append(tl)
	_scatter(_gen.now(), rng)


func _draw_tray(tray: Control) -> void:
	if not is_instance_valid(tray):
		return
	var r := Rect2(Vector2.ZERO, tray.size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.04, 0.1, 0.45)
	sb.set_corner_radius_all(14)
	sb.border_color = Color(color.r, color.g, color.b, 0.25)
	sb.set_border_width_all(1)
	tray.draw_style_box(sb, r)
	var font := get_theme_default_font()
	tray.draw_string(font, Vector2(14, r.end.y - 10), "積木區", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(12), Color(color.r, color.g, color.b, 0.45))


func _scatter(gen: int, rng: RandomNumberGenerator) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _gen.stale(gen) or _tray == null or not is_instance_valid(_tray):
		return
	var w := maxf(_tray.size.x, _tray.custom_minimum_size.x)
	if w < 100.0:
		w = 980.0
	# 一排一排擺，但每塊之間的距離、高低、角度都隨機：看起來是散的，又不會太佔空間
	var rows: Array = []
	var cur: Array = []
	var x := 12.0
	for t in _tiles:
		var tl: ConceptTile = t
		tl.fit()
		var gap := rng.randf_range(14.0, 46.0)
		if x + tl.size.x > w - 12.0 and not cur.is_empty():
			rows.append(cur)
			cur = []
			x = 12.0
		cur.append([tl, x])
		x += tl.size.x + gap
	if not cur.is_empty():
		rows.append(cur)
	var y := 8.0
	var k := 0
	for row in rows:
		var rh := 0.0
		var used := 0.0
		for e in row:
			rh = maxf(rh, (e[0] as ConceptTile).size.y)
			used = float(e[1]) + (e[0] as ConceptTile).size.x
		var shift := rng.randf_range(0.0, maxf(0.0, w - 12.0 - used))     # 整排往右推一點，不要每排都貼齊左邊
		for e in row:
			var tl: ConceptTile = e[0]
			var jy := rng.randf_range(0.0, 6.0)
			tl.home = Vector2(float(e[1]) + shift, y + jy + (rh - tl.size.y) / 2.0)
			tl.home_rot = rng.randf_range(-0.06, 0.06)
			tl.position = tl.home
			tl.pivot_offset = tl.size / 2.0
			tl.rotation = tl.home_rot
			tl.scale = Vector2(0.7, 0.7)
			var tw := tl.create_tween().set_parallel(true)
			tw.tween_property(tl, "modulate:a", 1.0, 0.25).set_delay(0.04 * k)
			tw.tween_property(tl, "scale", Vector2.ONE, 0.3).set_delay(0.04 * k).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			k += 1
		y += rh + 12.0
	_tray.custom_minimum_size.y = y + 14.0
	_tray.queue_redraw()


# ───────────────────────── 拖曳 ─────────────────────────

func begin_drag(tl: ConceptTile) -> void:
	if _drag != null or tl.used:
		return
	_guide_tap()
	_drag = tl
	var gp := tl.global_position
	tl.rotation = 0.0
	tl.top_level = true
	tl.global_position = gp
	tl.z_index = 50
	tl.pivot_offset = Vector2.ZERO
	tl.scale = Vector2(1.06, 1.06) * _sc()
	Game.of(self).play("blip", 1.3, -16.0)


func end_drag(tl: ConceptTile, at: Vector2) -> void:
	if _drag != tl:
		return
	_drag = null
	for s in _slots:
		(s as ConceptSlot).hot = false
	var s := _slot_at(at)
	if s == null:
		_send_home(tl)
		return
	try_place(tl, s)


## 把積木放進這一格（測試也直接呼叫這個）：放對就填上，放錯就彈回去並提示
func try_place(tl: ConceptTile, s: ConceptSlot) -> bool:
	var ok := false
	var why := ""
	if mode == "order":
		var placed: Array = _prog(idx).order
		if s.index != placed.size():
			why = "[color=#ffb35a]先放第 %d 步喔！[/color]　[color=#9aa3c7]從最上面的空格開始，一步一步往下排。[/color]" % (placed.size() + 1)
		elif tl.step >= 0 and _order_ok(cards[idx], tl.step, placed):
			ok = true
		else:
			why = "[color=#ff9a7a]還不是這一步！[/color]　[color=#9aa3c7]第 %d 步要先做什麼？再讀一次題目。[/color]" % (placed.size() + 1)
	else:
		ok = _accepts(s, tl.text)
	if not ok:
		_send_home(tl)
		_wrong(s, why)
		return false
	tl.used = true
	_tiles.erase(tl)
	Game.of(self).play("blip", 1.0 + 0.06 * (_prog(idx).fill as Dictionary).size(), -8.0)
	if mode == "order":
		(_prog(idx).order as Array).append(tl.step)
		s.set_filled(tl.text, true)
		_refresh_order_slots()
	else:
		_prog(idx).fill[s.index] = tl.text
		s.set_filled(tl.text, true)
	_burst(s.get_global_rect().get_center(), 10)
	# 積木飛進格子裡消失
	if is_instance_valid(tl):
		if not tl.top_level:
			var gp := tl.global_position
			tl.top_level = true
			tl.global_position = gp
			tl.pivot_offset = Vector2.ZERO
			tl.scale = Vector2.ONE * _sc()
		var tw := tl.create_tween().set_parallel(true)
		tw.tween_property(tl, "global_position", s.get_global_rect().get_center() - tl.size * tl.scale / 2.0, 0.16)
		tw.tween_property(tl, "modulate:a", 0.0, 0.18)
		tw.chain().tween_callback(tl.queue_free)
	_after_place()
	return true


func _after_place() -> void:
	var cd: Dictionary = cards[idx]
	if mode == "order":
		var placed: Array = _prog(idx).order
		if placed.size() >= (cd.steps as Array).size():
			Game.of(self).sfx("correct")
			_feedback.text = "[color=#6ee7a0]✔ 流程完成！[/color]　" + _hl(cd.get("done", ""), color)
			_fade_extras()
			_complete(idx)
		else:
			_feedback.text = "[color=#6ee7a0]第 %d 步 ✔[/color]　[color=#9aa3c7]接下來呢？[/color]" % placed.size()
	elif (_prog(idx).fill as Dictionary).size() >= _slots.size():
		Game.of(self).sfx("correct")
		_fade_extras()
		if cd.has("check") and not _prog(idx).check:
			_feedback.text = "[color=#6ee7a0]✔ 全部填好了！[/color]　[color=#9aa3c7]最後來一題小測驗。[/color]"
		else:
			_feedback.text = "[color=#6ee7a0]✔ 全部填好了！[/color]"
			_complete(idx)
	else:
		_feedback.text = "[color=#6ee7a0]✔ 放對了！[/color]　[color=#9aa3c7]還有 %d 格。[/color]" % (_slots.size() - (_prog(idx).fill as Dictionary).size())
	_update_nav()


## 填完之後，剩下的（干擾）積木變淡
func _fade_extras() -> void:
	for t in _tiles:
		var tl: ConceptTile = t
		tl.used = true
		tl.create_tween().tween_property(tl, "modulate:a", 0.28, 0.4)


func _accepts(s: ConceptSlot, text: String) -> bool:
	if s.filled:
		return false
	if text == s.answer:
		return true
	for grp in cards[idx].get("swap", []):
		if (grp as Array).has(text) and (grp as Array).has(s.answer):
			# 可以互換的一組：還要確認這一塊沒有被別的格子「指定」用掉（數量要對得上）
			return true
	return false


func _send_home(tl: ConceptTile) -> void:
	if not is_instance_valid(tl) or _tray == null or not is_instance_valid(_tray):
		return
	tl.scale = Vector2.ONE * _sc()
	var target := _tray.get_global_transform() * tl.home
	var tw := tl.create_tween()
	tw.tween_property(tl, "global_position", target, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		if is_instance_valid(tl) and not tl.used:
			tl.top_level = false
			tl.scale = Vector2.ONE
			tl.position = tl.home
			tl.pivot_offset = tl.size / 2.0
			tl.z_index = 0
			tl.rotation = tl.home_rot)


## 放錯：不扣分，那一行亮起來、旁邊一句提示
func _wrong(s: ConceptSlot, why := "") -> void:
	Game.of(self).play("blip", 0.62, -12.0)
	s.flash = 1.0
	var line: Control = s.line if s.line != null else s
	if is_instance_valid(line):
		var tw := line.create_tween()
		for k in 2:
			tw.tween_property(line, "modulate", Color(1.45, 1.3, 0.8), 0.16)
			tw.tween_property(line, "modulate", Color.WHITE, 0.22)
	if _feedback != null:
		if why == "":
			why = "[color=#ffb35a]再想想！[/color]　[color=#c9d1f0]%s[/color]" % HINTS[_hint_i % HINTS.size()]
			_hint_i += 1
		_feedback.text = why


func _slot_at(at: Vector2) -> ConceptSlot:
	var best: ConceptSlot = null
	var bd := INF
	for s in _slots:
		var sl: ConceptSlot = s
		if sl.filled:
			continue
		var r := sl.get_global_rect().grow(16.0)
		if r.has_point(at):
			var d := r.get_center().distance_to(at)
			if d < bd:
				bd = d
				best = sl
	return best


func _drag_over(at: Vector2) -> void:
	var s := _slot_at(at)
	for t in _slots:
		(t as ConceptSlot).hot = t == s


# ───────────────────────── 解題流程：把步驟拖進編號格子 ─────────────────────────

func _build_order(inner: VBoxContainer, cd: Dictionary) -> void:
	_head(inner, str(idx + 1), cd.title, cd.get("tag", "思考"))
	var bp := PanelContainer.new()
	bp.add_theme_stylebox_override("panel", UITheme.box(Color(color.r, color.g, color.b, 0.10), 12, Color(color.r, color.g, color.b, 0.45), 1, 10))
	inner.add_child(bp)
	var br := HBoxContainer.new()
	br.add_theme_constant_override("separation", 10)
	bp.add_child(br)
	var badge := Label.new()
	badge.text = "題"
	badge.add_theme_font_size_override("font_size", UITheme.fs(15))
	badge.add_theme_color_override("font_color", color)
	br.add_child(badge)
	var pq := MathLabel.new()
	pq.font_size = UITheme.fs(19)
	pq.color = Color(1, 0.96, 0.85)
	pq.max_width = 940
	pq.text = _hl(cd.prompt, color)
	br.add_child(pq)
	# 解題流程：步驟很長，編號格子在上面、積木區在下面（積木一排可以放三塊）
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(left)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	left.add_child(col)
	var steps: Array = cd.steps
	var placed: Array = _prog(idx).order
	for k in steps.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		col.add_child(row)
		var nb := Label.new()
		nb.text = str(k + 1)
		nb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nb.custom_minimum_size = Vector2(30, 30)
		nb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nb.add_theme_font_size_override("font_size", UITheme.fs(15))
		nb.add_theme_color_override("font_color", UITheme.PANEL)
		nb.add_theme_stylebox_override("normal", UITheme.box(Color(color.r, color.g, color.b, 0.85), 15, Color(0, 0, 0, 0), 0, 0))
		row.add_child(nb)
		var s := ConceptSlot.new()
		s.answer = ""
		s.fs = UITheme.fs(16)
		s.color = color
		s.wide = true
		s.index = k
		s.line = row
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(s)
		_slots.append(s)
		if k < placed.size():
			s.set_filled(String(steps[int(placed[k])]), false)
	_refresh_order_slots()
	_feedback = MathLabel.new()
	_feedback.font_size = UITheme.fs(15)
	_feedback.color = UITheme.TEXT
	_feedback.max_width = 940
	_feedback.custom_minimum_size = Vector2(0, 24)
	_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_feedback)
	if placed.size() >= steps.size():
		_feedback.text = "[color=#6ee7a0]✔ 流程完成！[/color]　" + _hl(cd.get("done", ""), color)
		return
	_feedback.text = "[color=#9aa3c7]照順序把步驟拖進格子。有一塊是錯的！[/color]"
	var texts: Array = []
	for si in steps.size():
		if not placed.has(si):
			texts.append([String(steps[si]), si])
	for d in cd.get("decoys", []):
		texts.append([String(d), -1])
	_make_tray(inner, texts, 0.0)


func _refresh_order_slots() -> void:
	var n := (_prog(idx).order as Array).size()
	for s in _slots:
		var sl: ConceptSlot = s
		sl.active = sl.index == n and not sl.filled
		sl.queue_redraw()


## 這一步現在可以放嗎：卡片有 "pre"（每一步要先完成哪幾步）時照它判斷，
## 例如「右移」和「上移」誰先都可以；沒有的話就要照順序
func _order_ok(cd: Dictionary, si: int, placed: Array) -> bool:
	if placed.has(si):
		return false
	if not cd.has("pre"):
		return si == placed.size()
	for need in cd.pre[si]:
		if not placed.has(int(need)):
			return false
	return true


# ───────────────────────── 隨堂小測 ─────────────────────────

func _build_check(inner: VBoxContainer, cd: Dictionary) -> void:
	var ck: Dictionary = cd.check
	_head(inner, "✦", "隨堂小測", "第 %d 張" % (idx + 1))
	var q := MathLabel.new()
	q.font_size = UITheme.fs(20)
	q.color = UITheme.TEXT
	q.max_width = 700
	q.text = _hl(ck.q, color)
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(q)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	if ck.has("plot"):
		# 需要看圖作答的題目：選項在左、圖在右
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 18)
		inner.add_child(crow)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		crow.add_child(box)
		var pl := ConceptPlot.new()
		pl.curves = ck.plot
		pl.custom_minimum_size = Vector2(250, 200)
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crow.add_child(pl)
	else:
		inner.add_child(box)
	var letters := ["A", "B", "C", "D"]
	var order := _shuffled(ck.opts.size(), idx * 7 + 3)
	var solved: bool = _prog(idx).check
	for k in order.size():
		var oi: int = order[k]
		var rb := _row_button(letters[k], ck.opts[oi])
		box.add_child(rb)
		_rows.append(rb)
		if solved:
			rb.disabled = true
			if oi == ck.a:
				_style_row(rb, UITheme.GOOD)
		rb.pressed.connect(func(): _on_check(rb, oi == int(ck.a), ck))
	_feedback = MathLabel.new()
	_feedback.font_size = UITheme.fs(15)
	_feedback.color = UITheme.TEXT
	_feedback.max_width = 700
	_feedback.custom_minimum_size = Vector2(0, 52)
	_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback.text = ("[color=#6ee7a0]✔ 答對了！[/color]　" + ck.why) if solved else "[color=#9aa3c7]想一想，選出正確的答案。[/color]"
	inner.add_child(_feedback)


func _on_check(rb: Button, right: bool, ck: Dictionary) -> void:
	if _prog(idx).check:
		return
	if right:
		Game.of(self).sfx("correct")
		_prog(idx).check = true
		_style_row(rb, UITheme.GOOD)
		for r in _rows:
			r.disabled = true
		_pop(rb)
		_burst(rb.get_global_rect().get_center(), 18)
		_feedback.text = "[color=#6ee7a0]✔ 答對了！[/color]　" + _hl(ck.why, color)
		_complete(idx)
	else:
		Game.of(self).sfx("wrong")
		_style_row(rb, UITheme.BAD)
		rb.disabled = true
		_wobble(rb)
		_feedback.text = "[color=#ff6b7a]✘ 不是這個，再想想！[/color]　" + _hl(ck.get("hint", ""), color)
	_update_nav()


func _row_button(badge: String, markup: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 42)
	_style_row(b, Color(0, 0, 0, 0))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 10
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(hb)
	var bl := Label.new()
	bl.name = "Badge"
	bl.text = badge
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bl.custom_minimum_size = Vector2(28, 28)
	bl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bl.add_theme_font_size_override("font_size", UITheme.fs(15))
	bl.add_theme_color_override("font_color", color)
	bl.add_theme_stylebox_override("normal", UITheme.box(Color(color.r, color.g, color.b, 0.15), 13, Color(color.r, color.g, color.b, 0.6), 1, 0))
	hb.add_child(bl)
	var m := MathLabel.new()
	m.name = "Math"
	m.font_size = UITheme.fs(17)
	m.color = UITheme.TEXT
	m.valign_center = true
	m.text = _hl(markup, color)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.size_flags_vertical = Control.SIZE_FILL
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(m)
	return b


func _style_row(b: Button, tint: Color) -> void:
	var has := tint.a > 0.0
	var bg := Color(tint.r, tint.g, tint.b, 0.16) if has else Color(0.05, 0.06, 0.14, 0.6)
	var bd := tint if has else Color(1, 1, 1, 0.14)
	b.add_theme_stylebox_override("normal", UITheme.box(bg, 12, bd, 1, 8))
	b.add_theme_stylebox_override("hover", UITheme.box(bg.lightened(0.08), 12, color if not has else tint, 1, 8))
	b.add_theme_stylebox_override("pressed", UITheme.box(bg.lightened(0.15), 12, color if not has else tint, 1, 8))
	b.add_theme_stylebox_override("disabled", UITheme.box(bg, 12, bd if has else Color(1, 1, 1, 0.06), 1, 8))


static func _shuffled(n: int, seed_v: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var arr: Array = range(n)
	for i in range(n - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t
	if arr == range(n) and n > 1:
		arr.reverse()
	return arr


# ───────────────────────── 小動畫 ─────────────────────────

func _pop(c: Control) -> void:
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2(1.04, 1.04)
	c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _wobble(c: Control) -> void:
	c.pivot_offset = c.size / 2.0
	var tw := c.create_tween()
	for r in [0.02, -0.02, 0.012, -0.008, 0.0]:
		tw.tween_property(c, "rotation", r, 0.05)


func _burst(at: Vector2, n: int) -> void:
	var bu := ConceptBurst.new()
	bu.color = color
	bu.count = n
	bu.top_level = true
	bu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bu)
	bu.global_position = at


## 把 "a > 1：?{遞增}" 拆成段落：[{t, h}]，h = 要藏起來的部分
static func _parse(m: String) -> Array:
	var segs: Array = []
	var buf := ""
	var i := 0
	while i < m.length():
		if m.substr(i, 2) == "?{":
			if buf != "":
				segs.append({"t": buf, "h": false})
				buf = ""
			var depth := 1
			var j := i + 2
			while j < m.length() and depth > 0:
				if m[j] == "{":
					depth += 1
				elif m[j] == "}":
					depth -= 1
				j += 1
			segs.append({"t": m.substr(i + 2, j - i - 3), "h": true})
			i = j
		else:
			buf += m[i]
			i += 1
	if buf != "":
		segs.append({"t": buf, "h": false})
	return segs


static func _hl(text: String, c: Color) -> String:
	return text.replace("[b]", "[color=#%s]" % c.lightened(0.2).to_html(false)).replace("[/b]", "[/color]")


static func _ans_color(c: Color) -> Color:
	return c.lightened(0.45)


## 揭開後的完整文字（藏起來的部分用亮色）
static func _full(m: String, c: Color) -> String:
	var s := ""
	for sg in _parse(m):
		if sg.h:
			s += "[color=#%s]%s[/color]" % [_ans_color(c).to_html(false), sg.t.replace("[b]", "").replace("[/b]", "")]
		else:
			s += _hl(sg.t, c)
	return s


func _text_w(markup: String, fs: int) -> float:
	return MathLabel.text_width(get_theme_default_font(), markup, UITheme.fs(fs))



# ───────────────────────── 繪圖小元件 ─────────────────────────

## 上方的進度點：完成的實心打勾、目前的變成長條
class ConceptDots extends Control:
	var deck = null

	func _get_minimum_size() -> Vector2:
		if deck == null:
			return Vector2.ZERO
		return Vector2(deck.cards.size() * 16 + 14, 14)

	func _draw() -> void:
		if deck == null:
			return
		var x := 0.0
		var c: Color = deck.color
		var cy := 7.0
		for i in deck.cards.size():
			var cur: bool = i == deck.idx and deck.mode != "list"
			var done: bool = deck.card_done(i)
			if cur:
				draw_rect(Rect2(x + 5, cy - 5, 14, 10), c)
				UITheme.dot(self, Vector2(x + 5, cy), 5.0, c)
				UITheme.dot(self, Vector2(x + 19, cy), 5.0, c)
				x += 30.0
				continue
			if done:
				UITheme.dot(self, Vector2(x + 5, cy), 5.0, Color(c.r, c.g, c.b, 0.8))
				var dk := UITheme.PANEL
				draw_polyline(PackedVector2Array([Vector2(x + 2.6, cy), Vector2(x + 4.4, cy + 2.0), Vector2(x + 7.6, cy - 2.2)]), dk, 1.4, true)
			else:
				draw_arc(Vector2(x + 5, cy), 4.4, 0, TAU, 24, Color(c.r, c.g, c.b, 0.6), 1.2, true)
			x += 16.0


## 卡片裡的空格：還沒填是虛線框（拖著積木經過時發亮）；填好就顯示答案
class ConceptSlot extends Control:
	const MathLabel := preload("res://data/ui/math_text.gd")
	var answer := ""
	var fs := 17
	var color := Color.WHITE
	var index := 0
	var line: Control = null
	var wide := false            # 解題流程：一整行寬的格子
	var filled := false
	var active := false          # 解題流程：下一個要放的格子
	var hot := false:
		set(v):
			if v != hot:
				hot = v
				queue_redraw()
	var flash := 0.0
	var _label: MathLabel
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_filled(text: String, anim: bool) -> void:
		filled = true
		if _label == null:
			_label = MathLabel.new()
			_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(_label)
		_label.font_size = fs
		_label.color = color.lightened(0.45) if not wide else UITheme.TEXT
		_label.text = text
		if wide:
			_label.max_width = 900
		update_minimum_size()
		_place.call_deferred()
		if anim:
			pivot_offset = size / 2.0
			scale = Vector2(1.12, 1.12)
			modulate = Color(1.6, 1.6, 1.6)
			var tw := create_tween().set_parallel(true)
			tw.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(self, "modulate", Color.WHITE, 0.4)
		queue_redraw()

	func _place() -> void:
		if _label == null:
			return
		var ms := _label.get_combined_minimum_size()
		_label.size = ms
		_label.position = Vector2(12.0, (size.y - ms.y) / 2.0) if wide else (size - ms) / 2.0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_place()

	func _get_minimum_size() -> Vector2:
		var h := fs * 1.75
		if filled and _label != null:
			var ms := _label.get_combined_minimum_size()
			return Vector2(0.0 if wide else ms.x + 20.0, maxf(h, ms.y + 10.0))
		return Vector2(0.0 if wide else 96.0, h + (4.0 if wide else 0.0))

	func _process(delta: float) -> void:
		_t += delta
		if flash > 0.0:
			flash = maxf(0.0, flash - delta * 1.6)
			queue_redraw()
		elif active and not filled:
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2(1, 1), size - Vector2(2, 2))
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(9)
		sb.anti_aliasing = true
		if filled:
			sb.bg_color = Color(color.r, color.g, color.b, 0.16 if not wide else 0.12)
			sb.border_color = Color(color.r, color.g, color.b, 0.55)
			sb.set_border_width_all(1)
			draw_style_box(sb, r)
			return
		var pulse := 0.5 + 0.5 * sin(_t * 3.2)
		sb.bg_color = Color(color.r, color.g, color.b, 0.26 if hot else (0.08 + 0.06 * pulse if active else 0.06))
		if hot:
			sb.border_color = Color(1, 1, 1, 0.9)
			sb.set_border_width_all(2)
		elif flash > 0.0:
			sb.border_color = Color(1.0, 0.55, 0.4, flash)
			sb.set_border_width_all(2)
		elif active:
			sb.border_color = Color(color.r, color.g, color.b, 0.5 + 0.4 * pulse)
			sb.set_border_width_all(2)
		else:
			sb.border_color = Color(color.r, color.g, color.b, 0.6)
			sb.set_border_width_all(1)
		draw_style_box(sb, r)
		var font := get_theme_default_font()
		if wide:
			if active:
				draw_string(font, Vector2(14, r.get_center().y + 6), "把第 %d 步拖到這裡" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14), Color(color.r, color.g, color.b, 0.6 + 0.3 * pulse))
		else:
			draw_string(font, Vector2(0, r.get_center().y + fs * 0.35), "？", HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color(color.r, color.g, color.b, 0.55))


## 積木：按住就能拖；放對了吸進格子，放錯彈回原位
class ConceptTile extends Control:
	const MathLabel := preload("res://data/ui/math_text.gd")
	var text := ""
	var step := -1               # 解題流程：這是第幾個步驟（−1：干擾積木）
	var color := Color.WHITE
	var fs := 17
	var deck = null
	var home := Vector2.ZERO
	var home_rot := 0.0
	var used := false
	var _label: MathLabel
	var _grab := Vector2.ZERO
	var _down := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_DRAG
		_label = MathLabel.new()
		_label.font_size = fs
		_label.color = Color("1a1530")
		_label.text = text
		if deck.mode == "order":
			_label.max_width = 430
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)
		fit()

	func fit() -> void:
		if _label == null:
			return
		var ms := _label.get_combined_minimum_size()
		size = ms + Vector2(26, 14)
		_label.size = ms
		_label.position = Vector2(13, 7)

	func _gui_input(e: InputEvent) -> void:
		if used:
			return
		# 用事件本身帶的位置（觸控、沒有滑鼠的環境也一樣準）
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			var gp: Vector2 = _ev_pos(e)
			if e.pressed:
				_down = true
				_grab = gp - global_position
				deck.begin_drag(self)
				accept_event()
			elif _down:
				_down = false
				deck.end_drag(self, gp)
				accept_event()
		elif e is InputEventMouseMotion and _down and deck._drag == self:
			var gp := _ev_pos(e)
			global_position = gp - _grab
			deck._drag_over(gp)
			accept_event()

	## 事件在畫面上的位置（_gui_input 給的 position 是這個控制項自己的座標）
	func _ev_pos(e: InputEventMouse) -> Vector2:
		return get_global_transform() * e.position

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var sh := StyleBoxFlat.new()
		sh.bg_color = Color(0, 0, 0, 0.35)
		sh.set_corner_radius_all(10)
		draw_style_box(sh, Rect2(r.position + Vector2(0, 4), r.size))
		var sb := StyleBoxFlat.new()
		sb.bg_color = color.lightened(0.35)
		sb.set_corner_radius_all(10)
		sb.anti_aliasing = true
		sb.border_color = color.lightened(0.6)
		sb.set_border_width_all(1)
		draw_style_box(sb, r)
		# 積木上面的兩個小圓點（看起來像可以拿起來的積木）
		UITheme.dot(self, Vector2(8, 8), 2.2, Color(1, 1, 1, 0.55))
		UITheme.dot(self, Vector2(size.x - 8, 8), 2.2, Color(1, 1, 1, 0.55))


## 新手引導的浮標：一個往上指著按鈕的小對話框，在主要按鈕下方上下浮動，淡入淡出
## （放在按鈕下方，才不會蓋住卡片裡的圖形）
class ConceptPointer extends Control:
	var color := Color.WHITE
	var target := Rect2()
	var want := false
	var above := false
	var alpha := 0.0
	var t := 0.0
	var _text := ""

	func set_text(s: String) -> void:
		if s != "":
			_text = s

	func _process(delta: float) -> void:
		t += delta
		alpha = move_toward(alpha, 1.0 if want else 0.0, delta * 4.0)
		visible = alpha > 0.0
		if not visible:
			return
		var font := get_theme_default_font()
		var tw := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15)).x
		size = Vector2(tw + 32.0, 50.0)
		var bob := 4.0 * sin(t * 4.0)
		# 卡片內容比較多、按鈕很靠近畫面下緣時：浮標改放在按鈕上方（箭頭朝下），才不會跑出畫面
		var vh := get_viewport_rect().size.y
		above = target.end.y + 2.0 + size.y > vh - 2.0
		var y := target.position.y - size.y - 2.0 - bob if above else target.end.y + 2.0 + bob
		global_position = Vector2(target.get_center().x - size.x / 2.0, y)
		modulate.a = alpha
		queue_redraw()

	func _draw() -> void:
		var font := get_theme_default_font()
		var cx := size.x / 2.0
		# 箭頭指向按鈕（浮標在下方時朝上、在上方時朝下）
		var by := 2.0 if above else 12.0
		if above:
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 9, 37), Vector2(cx + 9, 37), Vector2(cx, 48)]), color)
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 9, 13), Vector2(cx + 9, 13), Vector2(cx, 2)]), color)
		var bubble := Rect2(Vector2(0, by), Vector2(size.x, 36))
		var sb := StyleBoxFlat.new()
		sb.bg_color = color
		sb.set_corner_radius_all(18)
		sb.anti_aliasing = true
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 8
		draw_style_box(sb, bubble)
		draw_string(font, Vector2(16, by + 24.0), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color("1a1530"))


## 揭曉、答對時噴出來的小光點
class ConceptBurst extends Control:
	var color := Color.WHITE
	var count := 12
	var t := 0.0
	var dirs: Array = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		for i in count:
			var ang := TAU * i / count + rng.randf_range(-0.25, 0.25)
			dirs.append([Vector2(cos(ang), sin(ang)), rng.randf_range(50, 110), rng.randf_range(2.0, 4.0)])

	func _process(delta: float) -> void:
		t += delta
		if t > 0.7:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var u := t / 0.7
		var e := 1.0 - pow(1.0 - u, 3.0)
		for d in dirs:
			var p: Vector2 = d[0] * d[1] * e
			var a := 1.0 - u
			UITheme.dot(self, p, d[2] * (1.0 - 0.5 * u), Color(color.r, color.g, color.b, a))
			UITheme.dot(self, p, d[2] * 0.45, Color(1, 1, 1, a))


## 卡片右上角淡淡的大字
class ConceptGlyph extends Control:
	const MathLabel := preload("res://data/ui/math_text.gd")
	var text := ""
	var color := Color.WHITE
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		if text == "":
			return
		var font := get_theme_default_font()
		var a := 0.07 + 0.02 * sin(t * 1.2)
		MathLabel.draw_on(self, font, size.x - 120, 92 + 4.0 * sin(t * 0.8), text, UITheme.fs(64), Color(color.r, color.g, color.b, a))


## 卡片裡的小圖：指數、對數、y = x
class ConceptPlot extends Control:
	## 觀念卡片右邊的小圖。spec 可以是：
	##   陣列：[曲線, …]（舊寫法）
	##   字典：{view: {x: [左, 右], y: [下, 上]}, curves: [曲線…], pts: [{x, y, c}], band: [x 左, x 右], hband: [y 下, y 上],
	##          hlines: [{y, c, label}], vlines: [{x, c, label}], caption: 說明文字, shift: {…}}
	##   或 {scenes: [字典, 字典…]}：每 SCENE_T 秒換下一個畫面（例如先示範鏡射、再示範翻折）
	## 曲線：{f: exp／log／absexp／poly／line, a: 底數, h, k, m, p: [二次項, 一次項, 常數], c: 顏色,
	##        lx, side, label, mirror: true（x ≥ 0 的部分對 y 軸鏡射過去）, fold: true（x 軸下方翻上來）, ghost: true（淡淡的參考線）}
	## shift：平移動畫 {f: exp／log, a, h, k, c, label, base_label}：原本的曲線留著當影子，新曲線先往右、再往上，漸近線和恆過點跟著走
	const UITheme := preload("res://data/ui/game_theme.gd")
	const MathLabel := preload("res://data/ui/math_text.gd")
	const LABEL_FS := 16     # 設計字級 13 × 1.2
	const SCENE_T := 5.0
	var curves = []            # spec（沿用舊名字）
	var t := 0.0
	var _xr := Vector2(-3.2, 3.2)
	var _yr := Vector2(-2.6, 3.6)
	var _ga := 1.0             # 這一幕的整體透明度（換幕時淡入淡出）
	var _ph := 0.0             # 圖的高度（有說明文字時，底下留一條給文字）
	var _spec := {}            # 這一幕的 spec（示意圖 shape 要用到裡面的資料）

	func _ready() -> void:
		clip_contents = true

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _scenes() -> Array:
		if curves is Array:
			return [{"curves": curves}]
		if curves.has("scenes"):
			return curves.scenes
		return [curves]

	func _to(p: Vector2) -> Vector2:
		return Vector2((p.x - _xr.x) / (_xr.y - _xr.x) * size.x, _ph - (p.y - _yr.x) / (_yr.y - _yr.x) * _ph)

	static func _fv(cv: Dictionary, x: float) -> float:
		var a: float = cv.get("a", 2.0)
		var h: float = cv.get("h", 0.0)
		var k: float = cv.get("k", 0.0)
		var m: float = cv.get("m", 1.0)
		match String(cv.get("f", "line")):
			"exp":
				return m * pow(a, x - h) + k
			"absexp":
				return m * pow(a, absf(x - h)) + k
			"log":
				return m * log(x - h) / log(a) + k if x - h > 0.0 else NAN
			"sin":
				return m * sin(a * (x - h)) + k
			"cos":
				return m * cos(a * (x - h)) + k
			"tan":
				var tc := cos(a * (x - h))
				return m * tan(a * (x - h)) + k if absf(tc) > 0.04 else NAN
			"abssin":
				return m * absf(sin(a * (x - h))) + k
			"poly", "line":
				var pp: Array = cv.get("p", [0.0, 1.0, 0.0])
				return float(pp[0]) * x * x + float(pp[1]) * x + float(pp[2])
		return x

	func _col(c: Color, a: float = 1.0) -> Color:
		return Color(c.r, c.g, c.b, c.a * a * _ga)

	func _poly(f: Callable, lo: float, hi: float, col: Color, w: float, dashed := false) -> void:
		var pts := PackedVector2Array()
		var n := 140
		for i in n + 1:
			var x := lerpf(lo, hi, float(i) / n)
			var y: float = f.call(x)
			if is_nan(y) or y < _yr.x - 3.0 or y > _yr.y + 3.0:
				_flush(pts, col, w, dashed)
				pts = PackedVector2Array()
				continue
			pts.append(_to(Vector2(x, y)))
		_flush(pts, col, w, dashed)

	func _flush(pts: PackedVector2Array, col: Color, w: float, dashed: bool) -> void:
		if pts.size() < 2:
			return
		if not dashed:
			draw_polyline(UITheme.thin(pts), col, w, true)
			return
		# 虛線：每兩點一段，合成一次繪製
		if pts.size() % 2 == 1:
			pts = pts.slice(0, pts.size() - 1)
		draw_multiline(pts, col, w * 0.7, true)

	func _draw() -> void:
		var R := Rect2(Vector2.ZERO, size)
		draw_style_box(UITheme.boxc(Color(0.04, 0.05, 0.12, 0.8), 14, Color(1, 1, 1, 0.12), 1, 0), R)
		var sc := _scenes()
		var si := int(t / SCENE_T) % sc.size() if sc.size() > 1 else 0
		var ts := fmod(t, SCENE_T) if sc.size() > 1 else t
		_ga = 1.0
		if sc.size() > 1:
			_ga = clampf(ts / 0.35, 0.0, 1.0) * clampf((SCENE_T - ts) / 0.35, 0.0, 1.0)
		var spec: Dictionary = sc[si]
		var vw: Dictionary = spec.get("view", {})
		_xr = Vector2(vw.get("x", [-3.2, 3.2])[0], vw.get("x", [-3.2, 3.2])[1])
		_yr = Vector2(vw.get("y", [-2.6, 3.6])[0], vw.get("y", [-2.6, 3.6])[1])
		var font := get_theme_default_font()
		var cap := String(spec.get("caption", ""))
		_ph = size.y - (30.0 if cap != "" else 0.0)
		if cap != "" and MathLabel.frac_markup(cap).contains("\\frac"):
			_ph -= 8.0
		# 不是函數圖形的示意圖（例如扇形捲成圓錐）：不畫格線和座標軸
		if spec.has("shape"):
			_spec = spec
			_draw_shape(font, String(spec.shape))
			_draw_caption(font, cap)
			return
		# 格線、座標軸
		var gs := 1.0 if _xr.y - _xr.x <= 10.0 else 2.0
		var gx := ceilf(_xr.x / gs) * gs
		while gx <= _xr.y:
			var px := _to(Vector2(gx, 0)).x
			draw_line(Vector2(px, 6), Vector2(px, _ph - 4), Color(1, 1, 1, 0.04), 1.0)
			gx += gs
		var o := _to(Vector2.ZERO)
		if o.y > 2.0 and o.y < _ph - 2.0:
			draw_line(Vector2(6, o.y), Vector2(size.x - 6, o.y), Color(1, 1, 1, 0.45), 1.5)
		draw_line(Vector2(o.x, 6), Vector2(o.x, _ph - 4), Color(1, 1, 1, 0.45), 1.5)
		# 範圍色帶（解的範圍）
		if spec.has("band"):
			var b: Array = spec.band
			var p0 := _to(Vector2(maxf(float(b[0]), _xr.x), _yr.y))
			var p1 := _to(Vector2(minf(float(b[1]), _xr.y), _yr.x))
			p1.y = minf(p1.y, _ph)
			draw_rect(Rect2(p0, p1 - p0), _col(Color(1, 0.81, 0.35), 0.10 + 0.05 * sin(t * 3.0)))
		if spec.has("hband"):
			var hb: Array = spec.hband
			var q0 := _to(Vector2(_xr.x, minf(float(hb[1]), _yr.y)))
			var q1 := _to(Vector2(_xr.y, maxf(float(hb[0]), _yr.x)))
			draw_rect(Rect2(q0, q1 - q0), _col(Color(0.43, 0.91, 0.63), 0.09 + 0.04 * sin(t * 3.0)))
		for hl in spec.get("hlines", []):
			var yy := _to(Vector2(0, hl.y)).y
			draw_dashed_line(Vector2(4, yy), Vector2(size.x - 4, yy), _col(hl.get("c", Color(1, 1, 1, 0.7))), 1.6, 6.0)
			if hl.has("label"):
				var rt: bool = hl.get("side", "l") == "r"
				_tag(font, Vector2(size.x - 8 if rt else 8.0, yy - 4), String(hl.label), hl.get("c", Color.WHITE), rt)
		for vl in spec.get("vlines", []):
			var xx := _to(Vector2(vl.x, 0)).x
			draw_dashed_line(Vector2(xx, 4), Vector2(xx, _ph - 4), _col(vl.get("c", Color(1, 1, 1, 0.7))), 1.6, 6.0)
			if vl.has("label"):
				_tag(font, Vector2(xx + 6, 22), String(vl.label), vl.get("c", Color.WHITE), false)
		# 曲線
		var grow := clampf(ts / 1.0, 0.0, 1.0)
		var labels := []
		for cv in spec.get("curves", []):
			var col: Color = cv.get("c", Color.WHITE)
			var f := func(x): return _fv(cv, x)
			if cv.get("ghost", false):
				_poly(f, _xr.x, _xr.y, _col(col, 0.35), 2.0, true)
				continue
			if cv.get("fold", false):
				# 翻折：先畫原本的曲線，x 軸下方那段再慢慢翻上來
				var fk := clampf((ts - 1.0) / 1.2, 0.0, 1.0)
				_poly(f, _xr.x, _xr.y, _col(col, 0.35), 2.0, true)
				var g := func(x):
					var y: float = _fv(cv, x)
					return y if y >= 0.0 else lerpf(y, -y, fk)
				_poly(g, _xr.x, _xr.y, _col(col), 2.6)
				labels.append([cv, g])
				continue
			if cv.get("mirror", false):
				# 鏡射：先畫 x ≥ 0 的半邊，再把它對 y 軸翻到左邊
				var mk := clampf((ts - 0.9) / 1.2, 0.0, 1.0)
				var right := func(x): return _fv(cv, x) if x >= 0.0 else NAN
				_poly(right, 0.0, _xr.y, _col(col), 2.6)
				var oy := _to(Vector2.ZERO)
				draw_line(Vector2(oy.x, 6), Vector2(oy.x, _ph - 6), _col(Color(1, 1, 1), 0.25 * (1.0 - mk) + 0.1), 6.0)
				if mk > 0.0:
					var left := func(x): return _fv(cv, -x) if x <= 0.0 else NAN
					_poly(left, lerpf(-0.001, _xr.x, mk), 0.0, _col(col, 0.9), 2.6)
				labels.append([cv, func(x): return _fv(cv, absf(x))])
				continue
			_poly(f, _xr.x, lerpf(_xr.x, _xr.y, grow), _col(col), 2.5)
			labels.append([cv, f])
		if spec.has("shift"):
			_draw_shift(font, spec.shift, ts, labels)
		if spec.has("sweep"):
			_draw_sweep(font, spec.sweep, ts)
		# 點
		for p in spec.get("pts", []):
			var pc: Color = p.get("c", Color(1, 0.85, 0.45))
			var sp := _to(Vector2(p.x, p.y))
			var pulse := 0.5 + 0.5 * sin(t * 4.0 + p.x)
			UITheme.dot(self, sp, 8.0 + 3.0 * pulse, _col(pc, 0.18 * grow))
			UITheme.dot(self, sp, 4.5, _col(pc, grow))
			if p.has("label"):
				_tag(font, sp + Vector2(8, -8), String(p.label), pc, false)
		# 曲線標籤（曲線畫完才淡入）
		var la := clampf((ts - 1.0) / 0.4, 0.0, 1.0)
		if la > 0.0:
			for pair in labels:
				_curve_label(font, pair[0], pair[1], la)
		# 說明文字：圖下方獨立一條，不會蓋到曲線
		if cap != "":
			draw_rect(Rect2(0, _ph, size.x, size.y - _ph), Color(0.02, 0.03, 0.08, 0.85))
			draw_line(Vector2(0, _ph), Vector2(size.x, _ph), Color(1, 1, 1, 0.08), 1.0)
			var by := _ph + (size.y - _ph) / 2.0 + (8.0 if MathLabel.frac_markup(cap).contains("\\frac") else 5.0)
			var cfs := UITheme.fs(13)
			var cw := MathLabel.text_width(font, cap, cfs)
			if cw > size.x - 12.0:      # 圖很窄時縮小說明文字，免得超出圖框
				cfs = maxi(12, int(cfs * (size.x - 12.0) / cw))
			MathLabel.draw_on(self, font, size.x / 2.0, by, cap, cfs, _col(Color(1, 0.92, 0.7), 0.95))

	func _draw_caption(font: Font, cap: String) -> void:
		if cap == "":
			return
		draw_rect(Rect2(0, _ph, size.x, size.y - _ph), Color(0.02, 0.03, 0.08, 0.85))
		draw_line(Vector2(0, _ph), Vector2(size.x, _ph), Color(1, 1, 1, 0.08), 1.0)
		var by := _ph + (size.y - _ph) / 2.0 + (8.0 if MathLabel.frac_markup(cap).contains("\\frac") else 5.0)
		var cfs := UITheme.fs(13)
		var cw := MathLabel.text_width(font, cap, cfs)
		if cw > size.x - 12.0:
			cfs = maxi(12, int(cfs * (size.x - 12.0) / cw))
		MathLabel.draw_on(self, font, size.x / 2.0, by, cap, cfs, _col(Color(1, 0.92, 0.7), 0.95))

	## 示意圖 "synth"：綜合除法的算式（課本的寫法）
	##   {"shape": "synth", "top": [第一排…], "k": "−3", "mid": [第二排…（第一格留 ""）], "bot": [第三排…（最後一格是餘式）],
	##    "m": "+2"（除式 mx + n 時，左邊寫的 m，可省略）, "q4": [第四排…（可省略）], "caption": …}
	##   格子寫 "?" 會用金色框起來（隨堂小測要學生找的那一格）
	func _draw_synth(font: Font) -> void:
		var sp := _spec
		var top: Array = sp.get("top", [])
		var mid: Array = sp.get("mid", [])
		var bot: Array = sp.get("bot", [])
		var q4: Array = sp.get("q4", [])
		var has_m := sp.has("m")
		var n := top.size()
		if n == 0:
			return
		var rows := 3 + (1 if has_m else 0)
		var w := size.x
		var rh := minf(40.0, _ph / (rows + 0.4))
		var fs := UITheme.fs(16)
		var cw := minf(46.0, (w - (78.0 if has_m else 52.0)) / n)
		var x0 := (w - cw * n) / 2.0 + cw / 2.0 - 14.0 + (12.0 if has_m else 0.0)
		var y0 := (_ph - rh * rows) / 2.0
		var y_of := func(r: int) -> float: return y0 + rh * (r + 0.72)
		var line_c := _col(Color(1, 1, 1), 0.6)
		var cols := [Color(1, 0.97, 0.9), UITheme.CYAN.lightened(0.2), UITheme.CYAN.lightened(0.35), UITheme.GOOD.lightened(0.2)]
		var all := [top, mid, bot, q4]
		for r in rows:
			var row: Array = all[r]
			for i in row.size():
				var s := String(row[i])
				if s == "":
					continue
				var x := x0 + cw * i
				var y: float = y_of.call(r)
				if s == "?":
					draw_rect(Rect2(x - cw * 0.4, y - rh * 0.62, cw * 0.8, rh * 0.8), _col(UITheme.GOLD, 0.95), false, 2.0)
					MathLabel.draw_on(self, font, x, y, "?", fs, _col(UITheme.GOLD, 0.95))
				else:
					var c: Color = cols[r]
					if r == 2 and i == n - 1:
						c = UITheme.GOLD
					MathLabel.draw_on(self, font, x, y, s, fs, _col(c, 0.95))
		# 右邊的直線和 k、橫線、餘式的直線和圈圈
		var xb := x0 + cw * (n - 0.5) + 2.0
		var y_line: float = y_of.call(1) + rh * 0.3
		draw_line(Vector2(xb, y0 + 2.0), Vector2(xb, y_line), line_c, 1.5)
		var ks := String(sp.get("k", ""))
		MathLabel.draw_on(self, font, xb + 8.0 + MathLabel.text_width(font, ks, fs) / 2.0, y_of.call(1), ks, fs, _col(UITheme.GOLD, 0.95))
		draw_line(Vector2(x0 - cw * 0.5, y_line), Vector2(xb, y_line), line_c, 1.5)
		var xr := x0 + cw * (n - 1)
		draw_line(Vector2(xr - cw * 0.5, y_line), Vector2(xr - cw * 0.5, y_of.call(2) + rh * 0.2), line_c, 1.2)
		if bot.size() == n and String(bot[n - 1]) not in ["", "?"]:
			draw_arc(Vector2(xr, y_of.call(2) - fs * 0.32), minf(cw * 0.48, rh * 0.5), 0, TAU, 24, _col(UITheme.GOLD, 0.8), 1.5, true)
		# mx + n：左邊寫 m，框住第三排的商
		if has_m:
			var y3: float = y_of.call(2)
			MathLabel.draw_on(self, font, x0 - cw * 0.95, y3, String(sp.m), fs, _col(UITheme.GOLD, 0.95))
			draw_rect(Rect2(x0 - cw * 0.5, y3 - rh * 0.66, cw * (n - 1), rh * 0.86), _col(UITheme.GOLD, 0.55), false, 1.2)

	## 示意圖 shape：
	##   "cone"  左邊是扇形、右邊是捲好的圓錐：扇形半徑 ↔ 斜高 ℓ（白）、弧長 ↔ 底圓周長（藍，一起閃）
	func _draw_shape(font: Font, kind: String) -> void:
		match kind:
			"synth":
				_draw_synth(font)
			"tantri":
				# 以切表弦的直角三角形：底 1 − t²、高 2t、斜邊 1 + t²，左下角 2θ
				var w := size.x
				var h := _ph
				var A := Vector2(w * 0.14, h * 0.78)
				var B := Vector2(w * 0.74, h * 0.78)
				var C := Vector2(w * 0.74, h * 0.22)
				draw_colored_polygon(PackedVector2Array([A, B, C]), _col(UITheme.PINK, 0.85))
				draw_polyline(PackedVector2Array([A, B, C, A]), _col(Color(1, 1, 1), 0.9), 2.0, true)
				var q := 12.0
				draw_polyline(PackedVector2Array([B + Vector2(-q, 0), B + Vector2(-q, -q), B + Vector2(0, -q)]), _col(Color(1, 1, 1), 0.8), 1.5)
				var ang := (C - A).angle()
				draw_arc(A, 34.0, ang, 0.0, 20, _col(UITheme.GOLD_LIGHT), 2.0, true)
				var yl := _col(UITheme.GOLD_LIGHT)
				var fz := UITheme.fs(17)
				MathLabel.draw_on(self, font, A.x + 58.0, A.y - 8.0, "2θ", UITheme.fs(15), yl)
				MathLabel.draw_on(self, font, (A.x + B.x) / 2.0, B.y + 26.0, "1 − t²", fz, yl)
				MathLabel.draw_on(self, font, B.x + 30.0, (B.y + C.y) / 2.0 + 6.0, "2t", fz, yl)
				MathLabel.draw_on(self, font, (A.x + C.x) / 2.0 - 22.0, (A.y + C.y) / 2.0 - 14.0, "1 + t²", fz, yl)
			"cone":
				var amber := UITheme.ORANGE
				var cyan := UITheme.CYAN
				var pulse := 0.55 + 0.45 * sin(t * 3.0)
				var w := size.x
				var h := _ph
				# 扇形（圓心角 4π/3，開口朝下）
				var R := minf(w * 0.22, h * 0.36)
				var sc := Vector2(w * 0.27, h * 0.42)
				var th := 4.0 * PI / 3.0
				var a0 := -PI / 2.0 - th / 2.0
				var poly := PackedVector2Array([sc])
				for i in 41:
					var a := a0 + th * i / 40.0
					poly.append(sc + Vector2(cos(a), -sin(a)) * R)
				draw_colored_polygon(poly, _col(amber, 0.22))
				draw_polyline(poly.slice(1), _col(cyan, pulse), 3.0, true)
				draw_line(sc, poly[1], _col(Color.WHITE, 0.85), 2.0, true)
				draw_line(sc, poly[poly.size() - 1], _col(Color.WHITE, 0.85), 2.0, true)
				MathLabel.draw_on(self, font, (sc.x + poly[1].x) / 2.0 - 8.0, (sc.y + poly[1].y) / 2.0 + 4.0, "ℓ", LABEL_FS, _col(Color.WHITE))
				MathLabel.draw_on(self, font, sc.x, sc.y + R + 18.0, "弧長", LABEL_FS - 2, _col(cyan))
				# 箭頭
				var ay := h * 0.5
				draw_line(Vector2(w * 0.5, ay), Vector2(w * 0.58, ay), _col(Color.WHITE, 0.5), 2.0)
				draw_colored_polygon(PackedVector2Array([Vector2(w * 0.6, ay), Vector2(w * 0.57, ay - 5), Vector2(w * 0.57, ay + 5)]), _col(Color.WHITE, 0.5))
				# 圓錐（斜高 ℓ = R，底半徑 r = Rθ/2π = 2R/3）
				var rr := R * th / TAU
				var hh := sqrt(R * R - rr * rr)
				var k := minf(1.45, (h - 60.0) / hh)        # 圓錐畫大一點（示意，不照比例）
				k = minf(k, (w * 0.19) / rr)
				var apex := Vector2(w * 0.8, h * 0.5 - hh * k / 2.0 - 6.0)
				var base := apex + Vector2(0, hh * k)
				var bw := rr * k
				draw_colored_polygon(PackedVector2Array([apex, base + Vector2(-bw, 0), base + Vector2(bw, 0)]), _col(amber, 0.22))
				draw_line(apex, base + Vector2(-bw, 0), _col(Color.WHITE, 0.85), 2.0, true)
				draw_line(apex, base + Vector2(bw, 0), _col(Color.WHITE, 0.85), 2.0, true)
				var ell := PackedVector2Array()
				for i in 49:
					var a2 := TAU * i / 48.0
					ell.append(base + Vector2(cos(a2) * bw, sin(a2) * bw * 0.3))
				draw_polyline(ell, _col(cyan, pulse), 3.0, true)
				draw_dashed_line(base, base + Vector2(bw, 0), _col(UITheme.GOLD, 0.9), 1.5, 4.0)
				draw_dashed_line(apex, base, _col(Color.WHITE, 0.3), 1.2, 4.0)
				MathLabel.draw_on(self, font, (apex.x + base.x - bw) / 2.0 - 10.0, (apex.y + base.y) / 2.0, "ℓ", LABEL_FS, _col(Color.WHITE))
				MathLabel.draw_on(self, font, base.x + bw / 2.0, base.y - 6.0, "r", LABEL_FS, _col(UITheme.GOLD))
				MathLabel.draw_on(self, font, base.x, base.y + bw * 0.3 + 20.0, "2πr", LABEL_FS - 2, _col(cyan))

	## 平移動畫：先停在原本的位置 → 往右 h → 往上 k → 停一下
	func _draw_shift(font: Font, sh: Dictionary, ts: float, labels: Array) -> void:
		var col: Color = sh.get("c", UITheme.CYAN)
		var H: float = sh.get("h", 0.0)
		var K: float = sh.get("k", 0.0)
		var uh := clampf((ts - 0.8) / 1.1, 0.0, 1.0)
		var uk := clampf((ts - 2.1) / 1.1, 0.0, 1.0)
		uh = uh * uh * (3.0 - 2.0 * uh)
		uk = uk * uk * (3.0 - 2.0 * uk)
		var base := {"f": sh.f, "a": sh.get("a", 2.0)}
		var cur := {"f": sh.f, "a": sh.get("a", 2.0), "h": H * uh, "k": K * uk}
		var is_log: bool = String(sh.f) == "log"
		# 原本的曲線（影子）
		_poly(func(x): return _fv(base, x), _xr.x, _xr.y, _col(col, 0.3), 2.0, true)
		# 漸近線跟著走
		var ac := Color(1, 0.42, 0.48)
		if is_log:
			var ax := _to(Vector2(cur.h, 0)).x
			draw_dashed_line(Vector2(ax, 4), Vector2(ax, _ph - 4), _col(ac, 0.85), 1.6, 6.0)
		else:
			var ay := _to(Vector2(0, cur.k)).y
			draw_dashed_line(Vector2(4, ay), Vector2(size.x - 4, ay), _col(ac, 0.85), 1.6, 6.0)
		# 移動中的曲線
		_poly(func(x): return _fv(cur, x), _xr.x, _xr.y, _col(col), 2.8)
		# 恆過點：指數 (0, 1)、對數 (1, 0) 跟著移動，留下一條軌跡
		var p0 := Vector2(1, 0) if is_log else Vector2(0, 1)
		var pc := p0 + Vector2(cur.h, cur.k)
		var a0 := _to(p0)
		var mid := _to(p0 + Vector2(cur.h, 0))
		var a1 := _to(pc)
		draw_line(a0, mid, _col(Color(1, 0.85, 0.45), 0.6), 2.0, true)
		draw_line(mid, a1, _col(Color(1, 0.85, 0.45), 0.6), 2.0, true)
		UITheme.dot(self, a0, 3.5, _col(Color(1, 1, 1), 0.5))
		UITheme.dot(self, a1, 5.0, _col(Color(1, 0.85, 0.45)))
		# 目前在做哪一步
		var step := ""
		if ts > 0.8 and ts < 2.1:
			step = ("往右 %s" % UITheme.num(absf(H), 2)) if H >= 0.0 else ("往左 %s" % UITheme.num(absf(H), 2))
		elif ts >= 2.1 and ts < 3.3:
			step = ("往上 %s" % UITheme.num(absf(K), 2)) if K >= 0.0 else ("往下 %s" % UITheme.num(absf(K), 2))
		elif ts >= 3.3:
			step = String(sh.get("label", ""))
		if step != "":
			_pill(font, size.x / 2.0, 26, step, UITheme.fs(15), _col(Color(1, 0.88, 0.5)))
		if ts < 0.8:
			_pill(font, size.x / 2.0, 26, String(sh.get("base_label", "")), UITheme.fs(15), _col(col, 0.9))

	## 底數掃描動畫：a 從 a0 慢慢變到 a1，畫 y = a^{x}、y = log_{a} x、y = x，即時算出交點並數個數
	## sweep：{a0, a1, c_exp, c_log}
	func _draw_sweep(font: Font, sw: Dictionary, ts: float) -> void:
		var u := clampf((ts - 0.5) / (SCENE_T - 1.4), 0.0, 1.0)
		u = u * u * (3.0 - 2.0 * u)
		var a := lerpf(float(sw.a0), float(sw.a1), u)
		var ce: Color = sw.get("c_exp", UITheme.CYAN)
		var cl: Color = sw.get("c_log", UITheme.PINK)
		var ev := {"f": "exp", "a": a, "c": ce, "lx": _xr.x + 0.25 * (_xr.y - _xr.x), "side": "a", "label": "y = a^{x}"}
		var lv := {"f": "log", "a": a, "c": cl, "lx": _xr.y - 0.18 * (_xr.y - _xr.x), "side": "b", "label": "y = log_{a} x"}
		_poly(func(x): return x, _xr.x, _xr.y, _col(Color(1, 1, 1), 0.45), 1.6, true)
		_poly(func(x): return _fv(ev, x), _xr.x, _xr.y, _col(ce), 2.6)
		_poly(func(x): return _fv(lv, x), _xr.x, _xr.y, _col(cl), 2.6)
		# 交點：a^{x} − log_{a} x 變號的地方（加上幾乎相切的地方）；a 沒變就沿用上次的結果
		var xs := _sweep_roots(a)
		for xv in xs:
			var sp := _to(Vector2(xv, pow(a, xv)))
			UITheme.dot(self, sp, 9.0 + 2.0 * sin(t * 5.0), _col(Color(1, 0.85, 0.45), 0.25))
			UITheme.dot(self, sp, 5.0, _col(Color(1, 0.85, 0.45)))
		_curve_label(font, ev, func(x): return _fv(ev, x), 1.0)
		_curve_label(font, lv, func(x): return _fv(lv, x), 1.0)
		var head := "a = %s：[color=#ffcf5a]%d 個交點[/color]" % [UITheme.num(a, 2), xs.size()]
		draw_rect(Rect2(size.x / 2.0 - 92, 6, 184, 26), _col(Color(0.04, 0.05, 0.12), 0.85))
		MathLabel.draw_on(self, font, size.x / 2.0, 24, head, UITheme.fs(15), _col(Color(1, 1, 1)))

	var _sweep_a := NAN
	var _sweep_xs := []

	func _sweep_roots(a: float) -> Array:
		if a == _sweep_a:
			return _sweep_xs
		var xs := []
		var n := 2400
		var x0 := 0.002
		var prev := NAN
		var px := 0.0
		for i in n + 1:
			var x := x0 + 40.0 * pow(float(i) / n, 2.0)     # 靠近 0 取得密、遠處取得疏（畫面外的交點也要數到）
			var d := pow(a, x) - log(x) / log(a)
			if not is_nan(prev) and signf(d) != signf(prev):
				var rx := lerpf(px, x, prev / (prev - d))
				# 兩個交點靠得很近（快要相切）就當成一個
				if not xs.is_empty() and absf(rx - float(xs.back())) < 0.3:
					xs[xs.size() - 1] = (float(xs.back()) + rx) / 2.0
				else:
					xs.append(rx)
			prev = d
			px = x
		_sweep_a = a
		_sweep_xs = xs
		return xs

	func _tag(font: Font, at: Vector2, text: String, c: Color, right: bool) -> void:
		var w := _text_w(font, text)
		var x := at.x - w - 12.0 if right else at.x
		x = clampf(x, 4.0, size.x - w - 16.0)
		# 框框的高度照字實際的高度量（有分數、上標時會變高）
		var ext := MathLabel.line_extent(text, LABEL_FS)
		var top := maxf(ext.x + 3.0, 15.0)
		var bot := maxf(ext.y + 3.0, 5.0)
		var box := Rect2(Vector2(x, at.y - top), Vector2(w + 12, top + bot))
		draw_style_box(UITheme.boxc(Color(0.04, 0.05, 0.12, 0.85 * _ga), 8, _col(c, 0.6), 1, 0), box)
		MathLabel.draw_on(self, font, x + 6 + w / 2.0, at.y, text, LABEL_FS, _col(c))

	## 置中的標籤（圖上方的說明，例如平移動畫的「往右 2」、最後的函數）：和曲線標籤一樣有框框
	func _pill(font: Font, cx: float, baseline: float, text: String, fs: int, c: Color) -> void:
		if text == "":
			return
		var w := MathLabel.text_width(font, text, fs)
		var ext := MathLabel.line_extent(text, fs)
		var box := Rect2(Vector2(cx - w / 2.0 - 7.0, baseline - ext.x - 4.0), Vector2(w + 14.0, ext.x + ext.y + 8.0))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.05, 0.12, 0.88 * _ga)
		sb.border_color = Color(c.r, c.g, c.b, 0.75 * c.a)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(9)
		sb.anti_aliasing = true
		draw_style_box(sb, box)
		MathLabel.draw_on(self, font, cx, baseline, text, fs, c)

	func _curve_label(font: Font, cv: Dictionary, f: Callable, la: float) -> void:
		var col: Color = cv.get("c", Color.WHITE)
		var text: String = cv.get("label", auto_label(cv))
		if text == "":
			return
		var lx: float = cv.get("lx", 1.0)
		var ly: float = f.call(lx)
		if is_nan(ly):
			return
		var anchor := _to(Vector2(lx, ly))
		var w := _text_w(font, text)
		# 框框的高度照字實際的高度量（有分數、上標時會變高），上下各留 4
		var ext := MathLabel.line_extent(text, LABEL_FS)
		var h := ext.x + ext.y + 8.0
		var pos := anchor
		match String(cv.get("side", "r")):
			"r":
				pos = anchor + Vector2(w / 2.0 + 12.0, 0)
			"l":
				pos = anchor - Vector2(w / 2.0 + 12.0, 0)
			"a":
				pos = anchor - Vector2(0, h / 2.0 + 10.0)
			"b":
				pos = anchor + Vector2(0, h / 2.0 + 10.0)
		pos.x = clampf(pos.x, w / 2.0 + 6.0, size.x - w / 2.0 - 6.0)
		pos.y = clampf(pos.y, h / 2.0 + 6.0, _ph - h / 2.0 - 6.0)
		var box := Rect2(pos - Vector2(w / 2.0 + 7.0, h / 2.0), Vector2(w + 14.0, h))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.05, 0.12, 0.88 * la * _ga)
		sb.border_color = Color(col.r, col.g, col.b, 0.75 * la * _ga)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(9)
		sb.anti_aliasing = true
		draw_style_box(sb, box)
		MathLabel.draw_on(self, font, pos.x, pos.y - h / 2.0 + 4.0 + ext.x, text, LABEL_FS, Color(col.r, col.g, col.b, la * _ga))

	## 沒有寫 label 時，依照函數種類和底數自動產生
	static func auto_label(cv: Dictionary) -> String:
		var a: float = cv.get("a", 2.0)
		var b := _base(a)
		match String(cv.get("f", "line")):
			"exp":
				return "y = %s^{x}" % (b if a >= 1.0 else "(" + b + ")")
			"absexp":
				return "y = %s^{|x|}" % b
			"log":
				return "y = log_{%s} x" % b
		return "y = x"

	static func _base(a: float) -> String:
		if a >= 1.0:
			return str(int(round(a))) if is_equal_approx(a, round(a)) else str(a)
		var inv := 1.0 / a
		if is_equal_approx(inv, round(inv)):
			return "1/%d" % int(round(inv))
		return str(a)

	func _text_w(font: Font, markup: String) -> float:
		return MathLabel.text_width(font, markup, LABEL_FS)
