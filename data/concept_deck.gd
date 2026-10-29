extends VBoxContainer
## 觀念整理：互動式卡片
##   一般卡片：一行一行揭開；有「?{…}」的地方先藏起來，學生想一想再點開
##   隨堂小測：每張卡片揭開完，答對一題才能往下
##   解題流程：把思考步驟按照順序點出來（拼積木）
## 內容寫在各單元的卡片檔（指數與對數是 concepts_exp.gd，入口 concept_cards.gd）

const UITheme := preload("game_theme.gd")
const MathLabel := preload("math_text.gd")
const Game := preload("game.gd")

signal closed(start: bool)   # start = true：按了最後的「開始挑戰」

var cards: Array = []
var color := Color.WHITE
var level_name := ""
var progress: Dictionary = {}   # 卡片編號 -> {"n": 已揭開幾行, "check": 小測答對, "order": 流程完成}
var idx := 0
var mode := "card"              # card / check / order

var _body: PanelContainer
var _slide: MarginContainer
var _deco: ConceptGlyph
var _dots: ConceptDots
var _primary: Button
var _prev: Button
var _counter: Label
var _feedback: MathLabel
var _items: Array = []
var _rows: Array = []
var _rows_box: VBoxContainer
var _order_next := 0
var _pointer: ConceptPointer     # 新手引導：在主要按鈕上方上下浮動的提示
var _idle := 0.0                 # 多久沒操作了
static var _taps := 0            # 這次開遊戲以來按過幾次「繼續」（前幾次一定會顯示引導）
const GUIDE_TAPS := 3            # 前 3 次操作一直顯示引導
const GUIDE_IDLE := 5.0          # 之後只要 5 秒沒動，引導又會出現


func setup(title: String, deck: Array, c: Color, prog: Dictionary, start := 0) -> void:
	level_name = title
	cards = deck
	color = c
	progress = prog
	idx = clampi(start, 0, cards.size() - 1)


func _ready() -> void:
	add_theme_constant_override("separation", 12)
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
	var sb := UITheme.box(UITheme.PANEL_LIGHT, 18, Color(color.r, color.g, color.b, 0.35), 1, 20)
	sb.border_width_left = 6
	sb.border_color = color
	_body.add_theme_stylebox_override("panel", sb)
	_body.custom_minimum_size = Vector2(760, 0)
	_body.gui_input.connect(_on_body_input)
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
	var back := UITheme.ghost_button("回到章節", 15)
	back.icon = UITheme.icon("back", 15, UITheme.TEXT_DIM)
	back.pressed.connect(func(): closed.emit(false))
	nav.add_child(back)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(sp)
	_counter = Label.new()
	_counter.add_theme_font_size_override("font_size", UITheme.fs(15))
	_counter.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nav.add_child(_counter)
	_prev = UITheme.ghost_button("‹ 上一張", 16)
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
	_pointer.top_level = true          # 不參與排版，自己定位在按鈕上方
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.z_index = 10
	add_child(_pointer)
	_show(idx, 0)


func _process(delta: float) -> void:
	_idle += delta
	_update_guide()


## 引導：下一行要揭開的地方發亮；主要按鈕上方的浮標告訴學生現在該做什麼
func _update_guide() -> void:
	if _pointer == null or not is_instance_valid(_primary):
		return
	var text := ""
	if mode == "card":
		var cur := _current_item()
		if cur >= 0:
			text = "先想一想，再揭曉答案" if _items[cur].state == 1 else "點這裡，揭開下一行"
		elif cards[idx].has("check") and not _prog(idx).check:
			text = "最後來一題小測驗"
		else:
			text = "看完了，前往下一張" if idx < cards.size() - 1 else "準備好就開始挑戰！"
	elif mode == "order":
		text = ""
	var show := text != "" and not _primary.disabled and (_taps < GUIDE_TAPS or _idle >= GUIDE_IDLE)
	_pointer.target = _primary.get_global_rect()
	_pointer.set_text(text)
	_pointer.want = show
	# 浮標出現時，主要按鈕也跟著呼吸發光
	var glow := 0.0
	if _pointer.alpha > 0.01:
		glow = (0.5 + 0.5 * sin(_pointer.t * 4.0)) * 0.22 * _pointer.alpha
	_primary.self_modulate = Color(1 + glow, 1 + glow, 1 + glow)


func _guide_tap() -> void:
	_taps += 1
	_idle = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_DOWN):
		if not _primary.disabled:
			_on_primary()
		get_viewport().set_input_as_handled()


# ───────────────────────── 換頁 ─────────────────────────

func _prog(i: int) -> Dictionary:
	if not progress.has(i):
		progress[i] = {"n": 0, "check": false, "order": false}
	return progress[i]


func card_done(i: int) -> bool:
	var cd: Dictionary = cards[i]
	var p := _prog(i)
	if cd.get("kind", "") == "order":
		return p.order
	return p.n >= _item_count(cd) and (not cd.has("check") or p.check)


static func _item_count(cd: Dictionary) -> int:
	var n: int = cd.get("formulas", []).size() + cd.get("notes", []).size()
	for k in ["example", "trap"]:
		if cd.has(k):
			n += 1
	return n


func _show(i: int, dir: int, as_check := false) -> void:
	idx = i
	var cd: Dictionary = cards[idx]
	for ch in _slide.get_children():
		ch.queue_free()
	_items.clear()
	_rows.clear()
	_feedback = null
	_deco.text = "" if cd.get("kind", "") == "order" else cd.get("glyph", "")
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
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


func _head(inner: VBoxContainer, badge: String, title: String, tag: String) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	inner.add_child(head)
	var num := Label.new()
	num.text = badge
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.custom_minimum_size = Vector2(40, 40)
	num.add_theme_font_size_override("font_size", UITheme.fs(20))
	num.add_theme_color_override("font_color", UITheme.PANEL)
	num.add_theme_stylebox_override("normal", UITheme.box(color, 20, Color(0, 0, 0, 0), 0, 0))
	head.add_child(num)
	var tl := MathLabel.new()
	tl.font_size = UITheme.fs(24)
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
	return "下一張 ›" if idx < cards.size() - 1 else "開始挑戰  ▶"


func _update_nav() -> void:
	_dots.queue_redraw()
	_prev.visible = idx > 0 or mode == "check"
	_prev.text = "‹ 回卡片" if mode == "check" else "‹ 上一張"
	_primary.disabled = false
	_counter.text = ""
	var cd: Dictionary = cards[idx]
	match mode:
		"card":
			var cur := _current_item()
			var total := _items.size()
			_counter.text = "已揭開 %d / %d 行" % [_prog(idx).n, total]
			for i in total:
				_items[i].veil.active = i == cur and _items[i].state == 0
			if cur >= 0:
				_primary.text = "揭曉答案  ？" if _items[cur].state == 1 else "繼續  ▼"
			elif cd.has("check") and not _prog(idx).check:
				_primary.text = "隨堂小測  ✦"
				_counter.text = ""
			else:
				_primary.text = _next_label()
				_counter.text = "✔ 完成" if cd.has("check") else ""
		"check":
			_primary.text = _next_label() if _prog(idx).check else "選出答案"
			_primary.disabled = not _prog(idx).check
		"order":
			_primary.text = _next_label() if _prog(idx).order else "排好才能繼續"
			_primary.disabled = not _prog(idx).order
			if not _prog(idx).order:
				_counter.text = "%d / %d" % [_order_next, _rows.size()]


func _on_primary() -> void:
	_guide_tap()
	match mode:
		"card":
			var cur := _current_item()
			if cur >= 0:
				if _items[cur].state == 1:
					_reveal(cur)
				else:
					_reach(cur)
				_update_nav()
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
		closed.emit(true)


func _on_prev() -> void:
	Game.of(self).play("blip", 0.9, -12.0)
	if mode == "check":
		_show(idx, -1)
	elif idx > 0:
		_show(idx - 1, -1)


func _on_body_input(event: InputEvent) -> void:
	# 點卡片任何地方也可以往下揭開
	if event is InputEventMouseButton and event.pressed:
		_idle = 0.0
	if mode == "card" and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _current_item() >= 0:
			_on_primary()


# ───────────────────────── 一般卡片：一行一行揭開 ─────────────────────────

func _build_card(inner: VBoxContainer, cd: Dictionary) -> void:
	_head(inner, str(idx + 1), cd.title, cd.get("tag", ""))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	inner.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(left)
	var has_plot: bool = cd.has("plot")
	var wmax := 470.0 if has_plot else 690.0
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
		var fw := (wmax - 40) / (2.0 if fgrid.columns == 2 else 1.0)
		# 公式盡量一行放完：太長就把字縮小一點，不要在框裡換行
		var fsz := 21
		while fsz > 15 and _text_w(_full(f, color), fsz) > fw - 24.0:
			fsz -= 1
		var it := _swap(f, fsz, true, fw, Color(1, 0.96, 0.85))
		fp.add_child(it.stack)
		_add_item(fgrid, fp, it, true)
	for n in cd.get("notes", []):
		var nr := HBoxContainer.new()
		nr.add_theme_constant_override("separation", 8)
		nr.mouse_filter = Control.MOUSE_FILTER_PASS
		var bullet := Label.new()
		bullet.text = "▸"
		bullet.add_theme_color_override("font_color", color)
		bullet.add_theme_font_size_override("font_size", UITheme.fs(15))
		nr.add_child(bullet)
		var it := _swap(n, 17, false, wmax - 30, UITheme.TEXT)
		nr.add_child(it.stack)
		_add_item(left, nr, it, false)
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
		br.add_child(badge)
		var it := _swap(cd[key], 16, false, wmax - 70, UITheme.TEXT)
		br.add_child(it.stack)
		_add_item(left, bp, it, false)
	if has_plot:
		var pl := ConceptPlot.new()
		pl.curves = cd.plot
		pl.custom_minimum_size = Vector2(240, 220)
		pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(pl)
	# 回復進度：已揭開的直接顯示，接著自動打開下一行
	var p := _prog(idx)
	for i in _items.size():
		if i < p.n:
			_set_state(i, 2, false)
	if p.n < _items.size():
		_reach(p.n, false)


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


## 一行內容：B = 完整的字，A = 前半段 + 「？」按鈕（疊在同一格，高度取大的）
func _swap(m: String, fs: int, centered: bool, max_w: float, base: Color) -> Dictionary:
	fs = UITheme.fs(fs)
	var segs := _parse(m)
	var hidden := false
	for sg in segs:
		if sg.h:
			hidden = true
	var stack := MarginContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_PASS
	if not centered:
		stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var b := MathLabel.new()
	b.font_size = fs
	b.color = base
	b.align_center = centered
	b.max_width = max_w
	b.text = _full(m, color)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(b)
	var a: HBoxContainer = null
	var chips: Array = []
	if hidden:
		a = HBoxContainer.new()
		a.add_theme_constant_override("separation", 6)
		a.alignment = BoxContainer.ALIGNMENT_CENTER if centered else BoxContainer.ALIGNMENT_BEGIN
		a.mouse_filter = Control.MOUSE_FILTER_PASS
		stack.add_child(a)
		for sg in segs:
			if sg.h:
				var chip := Button.new()
				chip.text = "？"
				chip.focus_mode = Control.FOCUS_NONE
				chip.custom_minimum_size = Vector2(58, int(fs * 1.6))
				chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				chip.add_theme_font_size_override("font_size", fs)
				chip.add_theme_color_override("font_color", _ans_color(color))
				chip.add_theme_color_override("font_hover_color", Color.WHITE)
				chip.add_theme_stylebox_override("normal", UITheme.box(Color(color.r, color.g, color.b, 0.18), 10, Color(color.r, color.g, color.b, 0.8), 1, 4))
				chip.add_theme_stylebox_override("hover", UITheme.box(Color(color.r, color.g, color.b, 0.32), 10, Color.WHITE, 1, 4))
				chip.add_theme_stylebox_override("pressed", UITheme.box(Color(color.r, color.g, color.b, 0.45), 10, Color.WHITE, 1, 4))
				a.add_child(chip)
				chips.append(chip)
			else:
				var l := MathLabel.new()
				l.font_size = fs
				l.color = base
				l.text = _hl(sg.t.strip_edges(), color)
				l.mouse_filter = Control.MOUSE_FILTER_IGNORE
				l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				a.add_child(l)
	return {"stack": stack, "b": b, "a": a, "chips": chips, "hidden": hidden}


## 包一層：內容 + 還沒揭開時的虛線框
func _add_item(parent: Control, content: Control, it: Dictionary, expand: bool) -> void:
	var root := MarginContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	if expand:
		root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(root)
	root.add_child(content)
	var veil := ConceptVeil.new()
	veil.color = color
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(veil)
	var i := _items.size()
	it["root"] = root
	it["content"] = content
	it["veil"] = veil
	it["state"] = 0
	_items.append(it)
	for chip in it.chips:
		chip.pressed.connect(func():
			if _items.size() > i and _items[i].state == 1:
				_guide_tap()
				_reveal(i)
				_update_nav())
	content.modulate.a = 0.0
	if it.a != null:
		it.a.modulate.a = 0.0
		it.a.visible = false


func _current_item() -> int:
	for i in _items.size():
		if _items[i].state < 2:
			return i
	return -1


func _reach(i: int, anim := true) -> void:
	var it: Dictionary = _items[i]
	if anim:
		Game.of(self).play("blip", 1.0 + 0.04 * i, -14.0)
	_set_state(i, 1 if it.hidden else 2, anim)


func _reveal(i: int) -> void:
	Game.of(self).play("blip", 1.35, -9.0)
	_set_state(i, 2, true)
	var it: Dictionary = _items[i]
	_burst(it.b.get_global_rect().get_center(), 10)


func _set_state(i: int, s: int, anim: bool) -> void:
	var it: Dictionary = _items[i]
	var old: int = it.state
	it.state = s
	var content: Control = it.content
	var veil: Control = it.veil
	var a: Control = it.a
	var b: Control = it.b
	if s >= 1 and old == 0:
		if anim:
			var tw := content.create_tween().set_parallel(true)
			tw.tween_property(veil, "modulate:a", 0.0, 0.15)
			tw.tween_property(content, "modulate:a", 1.0, 0.25)
		else:
			veil.modulate.a = 0.0
			content.modulate.a = 1.0
	if s == 1:
		b.modulate.a = 0.0
		a.visible = true
		a.modulate.a = 1.0
		for chip in it.chips:
			var c2: Button = chip
			var tw2 := c2.create_tween().set_loops()
			tw2.tween_property(c2, "modulate", Color(1.25, 1.25, 1.25), 0.55)
			tw2.tween_property(c2, "modulate", Color(1, 1, 1), 0.55)
	if s == 2:
		if a != null:
			a.visible = false
		b.modulate.a = 1.0
		if anim and old == 1:
			b.pivot_offset = b.size / 2.0
			b.scale = Vector2(1.08, 1.08)
			b.modulate = Color(1.6, 1.6, 1.6, 1.0)
			var tw3 := b.create_tween().set_parallel(true)
			tw3.tween_property(b, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw3.tween_property(b, "modulate", Color(1, 1, 1, 1), 0.4)
		var p := _prog(idx)
		p.n = maxi(p.n, i + 1)


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
	else:
		Game.of(self).sfx("wrong")
		_style_row(rb, UITheme.BAD)
		rb.disabled = true
		_wobble(rb)
		_feedback.text = "[color=#ff6b7a]✘ 不是這個，再想想！[/color]　" + _hl(ck.get("hint", "回卡片看一下也可以。"), color)
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


# ───────────────────────── 解題流程：拼積木 ─────────────────────────

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
	pq.font_size = UITheme.fs(20)
	pq.color = Color(1, 0.96, 0.85)
	pq.max_width = 650
	pq.text = _hl(cd.prompt, color)
	br.add_child(pq)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 6)
	inner.add_child(_rows_box)
	var steps: Array = cd.steps
	var done: bool = _prog(idx).order
	var order: Array = range(steps.size()) if done else _shuffled(steps.size(), idx * 13 + steps.size())
	_order_next = steps.size() if done else 0
	for k in order:
		var si: int = k
		var rb := _row_button("?", steps[si])
		rb.custom_minimum_size = Vector2(0, 40)
		rb.set_meta("step", si)
		_rows_box.add_child(rb)
		_rows.append(rb)
		if done:
			_lock_row(rb, si, false)
		rb.pressed.connect(func(): _on_order(rb))
	_feedback = MathLabel.new()
	_feedback.font_size = UITheme.fs(15)
	_feedback.color = UITheme.TEXT
	_feedback.max_width = 700
	_feedback.custom_minimum_size = Vector2(0, 26)
	_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback.text = ("[color=#6ee7a0]✔ 流程完成！[/color]　" + _hl(cd.get("done", ""), color)) if done \
		else "[color=#9aa3c7]照思考順序，一塊一塊點出來。[/color]"
	inner.add_child(_feedback)


func _on_order(rb: Button) -> void:
	if _prog(idx).order or rb.has_meta("locked"):
		return
	var si: int = rb.get_meta("step")
	var cd: Dictionary = cards[idx]
	if _order_ok(cd, si):
		Game.of(self).play("blip", 1.0 + 0.1 * _order_next, -8.0)
		_rows_box.move_child(rb, _order_next)
		_lock_row(rb, _order_next, true)
		_order_next += 1
		if _order_next >= _rows.size():
			_prog(idx).order = true
			Game.of(self).sfx("correct")
			_feedback.text = "[color=#6ee7a0]✔ 流程完成！[/color]　" + _hl(cd.get("done", ""), color)
			_burst(_rows_box.get_global_rect().get_center(), 24)
		else:
			_feedback.text = "[color=#6ee7a0]第 %d 步 ✔[/color]　[color=#9aa3c7]接下來呢？[/color]" % _order_next
	else:
		Game.of(self).sfx("wrong")
		_wobble(rb)
		var old: StyleBox = rb.get_theme_stylebox("normal")
		_style_row(rb, UITheme.BAD)
		get_tree().create_timer(0.45).timeout.connect(func():
			if is_instance_valid(rb) and not rb.has_meta("locked"):
				rb.add_theme_stylebox_override("normal", old)
				_style_row(rb, Color(0, 0, 0, 0)))
		_feedback.text = "[color=#ff6b7a]還不是這一步！[/color]　[color=#9aa3c7]第 %d 步要先做什麼？[/color]" % (_order_next + 1)
	_update_nav()


## 這一步現在可以放嗎：卡片有 "pre"（每一步要先完成哪幾步）時照它判斷，
## 例如「右移」和「上移」誰先都可以；沒有的話就要照順序
func _order_ok(cd: Dictionary, si: int) -> bool:
	var placed := {}
	for r in _rows:
		if r.has_meta("locked"):
			placed[int(r.get_meta("step"))] = true
	if placed.has(si):
		return false
	if not cd.has("pre"):
		return si == _order_next
	for need in cd.pre[si]:
		if not placed.has(int(need)):
			return false
	return true


func _lock_row(rb: Button, si: int, anim: bool) -> void:
	rb.set_meta("locked", true)
	_style_row(rb, color)
	var bl: Label = rb.find_child("Badge", true, false)
	bl.text = str(si + 1)
	bl.add_theme_color_override("font_color", UITheme.PANEL)
	bl.add_theme_stylebox_override("normal", UITheme.box(color, 13, Color(0, 0, 0, 0), 0, 0))
	rb.mouse_default_cursor_shape = Control.CURSOR_ARROW
	if anim:
		_pop(rb)


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


# ───────────────────────── 繪圖小元件 ─────────────────────────

## 上方的進度點：完成的實心、目前的變成長條
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
			var cur: bool = i == deck.idx
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


## 還沒揭開的那一行：淡淡的虛線框
class ConceptVeil extends Control:
	var color := Color.WHITE
	var active := false:          # 下一行要揭開的就是這一行：邊框發亮、寫上「點一下揭開」
		set(v):
			active = v
			queue_redraw()
	var t := 0.0

	func _process(delta: float) -> void:
		if active and modulate.a > 0.01:
			t += delta
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2(1, 1), size - Vector2(2, 2))
		var pulse := 0.5 + 0.5 * sin(t * 3.2) if active else 0.0
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(color.r, color.g, color.b, 0.04 + 0.08 * pulse if active else 0.04)
		sb.set_corner_radius_all(10)
		sb.anti_aliasing = true
		if active:
			sb.border_color = Color(color.r, color.g, color.b, 0.45 + 0.4 * pulse)
			sb.set_border_width_all(2)
		draw_style_box(sb, r)
		var cy := r.get_center().y
		if active:
			var font := get_theme_default_font()
			var c := Color(color.r, color.g, color.b, 0.75 + 0.25 * pulse)
			draw_string(font, Vector2(r.position.x + 18, cy + 6), "點一下，揭開這一行", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), c)
			# 右邊一個往下點的小箭頭
			var ax := r.end.x - 26.0
			var ay := cy - 3.0 + 3.0 * sin(t * 4.0)
			draw_colored_polygon(PackedVector2Array([Vector2(ax - 7, ay - 3), Vector2(ax + 7, ay - 3), Vector2(ax, ay + 5)]), c)
			return
		var col := Color(color.r, color.g, color.b, 0.28)
		var dash := 7.0
		var gap := 6.0
		var x := r.position.x + 10.0
		while x < r.end.x - 10.0:
			var x2 := minf(x + dash, r.end.x - 10.0)
			draw_line(Vector2(x, r.position.y), Vector2(x2, r.position.y), col, 1.0)
			draw_line(Vector2(x, r.end.y), Vector2(x2, r.end.y), col, 1.0)
			x += dash + gap
		for k in 3:
			UITheme.dot(self, Vector2(r.position.x + 22 + k * 12, cy), 2.5, Color(color.r, color.g, color.b, 0.35))


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
	const MathLabel := preload("math_text.gd")
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
	const UITheme := preload("game_theme.gd")
	const MathLabel := preload("math_text.gd")
	const LABEL_FS := 16     # 設計字級 13 × 1.2
	const SCENE_T := 5.0
	var curves = []            # spec（沿用舊名字）
	var t := 0.0
	var _xr := Vector2(-3.2, 3.2)
	var _yr := Vector2(-2.6, 3.6)
	var _ga := 1.0             # 這一幕的整體透明度（換幕時淡入淡出）
	var _ph := 0.0             # 圖的高度（有說明文字時，底下留一條給文字）

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

	## 示意圖 shape：
	##   "cone"  左邊是扇形、右邊是捲好的圓錐：扇形半徑 ↔ 斜高 ℓ（白）、弧長 ↔ 底圓周長（藍，一起閃）
	func _draw_shape(font: Font, kind: String) -> void:
		match kind:
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
