extends Control
## 終焉之塔：段考風格的題目（題庫在 tower_bank.gd）
##   左邊「題目板」：題目、推導板（每答對一步就寫上一行）、互動區（真假卡片／候選根／數線封印）
##   右邊「作答區」：步驟進度、這一步要做什麼、選項、提示
## 整趟攀登共用三顆心（由 Game 傳進來），每層限時。

const UITheme := preload("game_theme.gd")
const MathLabel := preload("math_text.gd")
const Game := preload("game.gd")
const PauseMenu := preload("pause_menu.gd")
const Buddy := preload("buddy.gd")
const Bank := preload("tower_bank.gd")

const STAGE_W := 700.0
const STAGE_H := 556.0
const INNER_W := 652.0      # 題目板內容寬（扣掉左右內距）
const CARD_W := 348.0       # 右邊作答區內容寬
const MAX_HEARTS := 3

var item: Dictionary = {}
var steps: Array = []
var si := 0                 # 目前第幾步
var floor_n := 1
var hearts := MAX_HEARTS
var time_left := 120.0
var time_total := 120.0
var penalty := 0            # 扣星用：答錯幾次
var done := false
var waiting := false        # 看完解說，等學生按「繼續」（這時計時暫停）
var kind_col := Color.WHITE
var test_mode := false      # 沒有從塔進來（直接開這個場景測試）

# 介面
var pause_menu: CanvasLayer
var buddy
var heart_label: Label
var timer_label: Label
var floor_label: Label
var stage_panel: PanelContainer
var stem_label: MathLabel
var board: VBoxContainer
var board_scroll: ScrollContainer
var widget_box: VBoxContainer
var plot: Plot
var step_label: MathLabel
var part_label: Label
var prompt_label: MathLabel
var opts_box: VBoxContainer
var action_btn: Button
var hint_panel: PanelContainer
var hint_label: MathLabel
var next_btn: Button
var card_plot_holder: Control

# 各題型的狀態
var judge_rows: Array = []      # [{row, pick, btns, why, card}]
var root_tokens: Array = []     # [{btn, struck, cand, why}]
var numline: NumLine = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.shared()
	randomize()
	var a: Dictionary = Game.of(self).take_args()
	if a.has("review"):
		item = Bank.by_id(String(a.review.slot))
		floor_n = int(a.get("tower_floor", 1))
		hearts = int(a.get("tower_hearts", MAX_HEARTS))
		time_total = float(a.get("tower_time", 120.0))
	else:
		test_mode = true
		var all := Bank.items()
		item = all.pick_random() if not a.has("id") else Bank.by_id(String(a.id))
		time_total = 150.0 * float(item.get("tmul", 1.0))
	if item.is_empty():
		item = Bank.items()[0]
	steps = item.steps
	kind_col = Bank.KIND_COLOR.get(item.kind, UITheme.ACCENT)
	time_left = time_total
	_build_ui()
	buddy = Buddy.new()
	add_child(buddy)
	pause_menu = PauseMenu.new()
	pause_menu.list_label = "放棄攀登"
	pause_menu.list_action = func():
		if not test_mode:
			Game.of(self).tower_abort()
	pause_menu.report_info = func() -> String:
		return "終焉之塔大題 %s「%s」，第 %d 步" % [item.get("id", "?"), item.get("title", ""), si + 1]
	add_child(pause_menu)
	_start()


# ================= 介面 =================

func _build_ui() -> void:
	var bg := TowerBg.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var top := HBoxContainer.new()
	top.position = Vector2(24, 12)
	top.custom_minimum_size = Vector2(1104, 48)
	top.add_theme_constant_override("separation", 16)
	add_child(top)
	var title := Label.new()
	title.text = "終焉之塔"
	title.add_theme_font_size_override("font_size", UITheme.fs(26))
	title.add_theme_color_override("font_color", Color("ff8fa0"))
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)
	floor_label = Label.new()
	floor_label.add_theme_font_size_override("font_size", UITheme.fs(19))
	floor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	floor_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(floor_label)
	heart_label = Label.new()
	heart_label.add_theme_font_size_override("font_size", UITheme.fs(24))
	heart_label.add_theme_color_override("font_color", UITheme.PINK)
	heart_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(heart_label)
	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", UITheme.fs(22))
	timer_label.custom_minimum_size = Vector2(96, 0)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(timer_label)
	var pb := UITheme.round_button("pause", 44)
	pb.tooltip_text = "暫停（Esc）"
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pb.pressed.connect(func(): pause_menu.open())
	top.add_child(pb)

	# 左：題目板
	stage_panel = PanelContainer.new()
	stage_panel.position = Vector2(24, 70)
	stage_panel.custom_minimum_size = Vector2(STAGE_W, STAGE_H)
	stage_panel.size = Vector2(STAGE_W, STAGE_H)
	stage_panel.clip_contents = true
	var sb := UITheme.box(Color(0.07, 0.08, 0.18, 0.94), 18, Color(kind_col.r, kind_col.g, kind_col.b, 0.35), 1, 24)
	stage_panel.add_theme_stylebox_override("panel", sb)
	add_child(stage_panel)
	var scol := VBoxContainer.new()
	scol.add_theme_constant_override("separation", 12)
	stage_panel.add_child(scol)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	scol.add_child(head)
	var chip := Label.new()
	chip.text = Bank.KIND_NAME.get(item.kind, "")
	chip.add_theme_font_size_override("font_size", UITheme.fs(15))
	chip.add_theme_color_override("font_color", kind_col)
	chip.add_theme_stylebox_override("normal", UITheme.box(Color(kind_col.r, kind_col.g, kind_col.b, 0.14), 12,
		Color(kind_col.r, kind_col.g, kind_col.b, 0.6), 1, 6))
	head.add_child(chip)
	var tl := Label.new()
	tl.text = item.title
	tl.add_theme_font_size_override("font_size", UITheme.fs(17))
	tl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(tl)
	stem_label = MathLabel.new()
	stem_label.font_size = UITheme.fs(20)
	stem_label.max_width = INNER_W
	stem_label.color = UITheme.TEXT
	scol.add_child(stem_label)
	# 推導板：寫的行數多了可以上下捲動（新寫的一行會自動捲到看得見）
	board_scroll = ScrollContainer.new()
	board_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER   # 不佔寬度；用手指拖動或滾輪捲
	scol.add_child(board_scroll)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_scroll.add_child(body)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	board = VBoxContainer.new()
	board.add_theme_constant_override("separation", 2)
	left.add_child(board)
	widget_box = VBoxContainer.new()
	widget_box.add_theme_constant_override("separation", 6)
	left.add_child(widget_box)
	var has_plot: bool = item.has("plot")
	if has_plot:
		plot = Plot.new()
		plot.data = item.plot
		if item.kind == "judge":
			plot.custom_minimum_size = Vector2(CARD_W, 210)
		else:
			plot.custom_minimum_size = Vector2(270, 250)
			plot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			plot.mouse_filter = Control.MOUSE_FILTER_PASS
			body.add_child(plot)

	# 右：作答區
	var card := PanelContainer.new()
	card.position = Vector2(744, 70)
	card.custom_minimum_size = Vector2(384, STAGE_H)
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	step_label = MathLabel.new()
	step_label.font_size = UITheme.fs(15)
	step_label.max_width = CARD_W
	step_label.color = UITheme.TEXT_DIM
	col.add_child(step_label)
	part_label = Label.new()
	part_label.add_theme_font_size_override("font_size", UITheme.fs(16))
	part_label.add_theme_color_override("font_color", kind_col)
	part_label.visible = false
	col.add_child(part_label)
	prompt_label = MathLabel.new()
	prompt_label.font_size = UITheme.fs(18)
	prompt_label.max_width = CARD_W
	prompt_label.color = UITheme.ACCENT
	col.add_child(prompt_label)
	if has_plot and item.kind == "judge":
		col.add_child(plot)
	opts_box = VBoxContainer.new()
	opts_box.add_theme_constant_override("separation", 8)
	col.add_child(opts_box)
	action_btn = Button.new()
	action_btn.custom_minimum_size = Vector2(0, 52)
	UITheme.accent_button(action_btn, 20)
	action_btn.visible = false
	action_btn.pressed.connect(_on_action)
	col.add_child(action_btn)
	hint_panel = PanelContainer.new()
	hint_panel.add_theme_stylebox_override("panel", UITheme.box(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 12))
	hint_panel.visible = false
	hint_label = MathLabel.new()
	hint_label.font_size = UITheme.fs(15)
	hint_label.max_width = CARD_W - 24
	hint_panel.add_child(hint_label)
	col.add_child(hint_panel)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)
	next_btn = Button.new()
	next_btn.custom_minimum_size = Vector2(0, 52)
	UITheme.accent_button(next_btn, 20)
	next_btn.visible = false
	next_btn.pressed.connect(_on_next)
	col.add_child(next_btn)


func _hint(text: String, kind: String = "info") -> void:
	hint_panel.visible = true
	var c := {"info": UITheme.CYAN, "good": UITheme.GOOD, "bad": UITheme.BAD}[kind] as Color
	hint_panel.add_theme_stylebox_override("panel",
		UITheme.box(Color(c.r, c.g, c.b, 0.10), 12, Color(c.r, c.g, c.b, 0.55), 1, 12))
	hint_label.text = text


func _clear(box: Node) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _update_hud() -> void:
	floor_label.text = "第 %d 層" % floor_n if not test_mode else "測試模式"
	heart_label.text = "♥".repeat(clampi(hearts, 0, MAX_HEARTS)) + "♡".repeat(clampi(MAX_HEARTS - hearts, 0, MAX_HEARTS))
	timer_label.text = "◷ %d" % ceili(maxf(0.0, time_left))
	timer_label.add_theme_color_override("font_color", UITheme.BAD if time_left < 10.0 and not done else UITheme.TEXT)


func _step_bar() -> String:
	var parts := PackedStringArray()
	var nums := ["①", "②", "③", "④", "⑤", "⑥", "⑦"]
	for i in steps.size():
		var nm: String = nums[mini(i, nums.size() - 1)]
		if i < si or done:
			parts.append("[color=#6ee7a0]✓[/color]")
		elif i == si:
			parts.append("[color=#ffcf5a]%s[/color]" % nm)
		else:
			parts.append(nm)
	return "  ›  ".join(parts)


# ================= 流程 =================

func _start() -> void:
	_update_hud()
	stem_label.text = item.stem
	stem_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(stem_label, "modulate:a", 1.0, 0.45)
	buddy.say("第 %d 層：「%s」！" % [floor_n, item.title] if not test_mode else "「%s」！" % item.title, "happy", 2.6)
	_show_step()


## 這一步開始前先寫上推導板的「已知」（例如「令 t = 2^{x}（t > 0）」），不是這一步的答案
var _pre_done := {}


func _write_pre(i: int, dim := false) -> void:
	if _pre_done.has(i) or i >= steps.size():
		return
	_pre_done[i] = true
	var pre = steps[i].get("pre", [])
	if pre is String:
		pre = [pre]
	for ln in pre:
		_write(String(ln), dim)


func _show_step() -> void:
	waiting = false
	var s: Dictionary = steps[si]
	_write_pre(si)
	step_label.text = _step_bar()
	part_label.visible = s.has("part")
	part_label.text = "小題 %s" % s.get("part", "")
	prompt_label.text = s.q
	_clear(opts_box)
	hint_panel.visible = false
	action_btn.visible = false
	action_btn.disabled = false
	if plot:
		plot.stage = si
	match s.t:
		"choice":
			_clear(widget_box)
			_build_choice(s)
		"judge":
			_build_judge(s)
		"roots":
			_build_roots(s)
		"line":
			_build_line(s)


func _advance() -> void:
	si += 1
	if plot:
		plot.stage = si
	if si >= steps.size():
		_finish(true)
	else:
		_show_step()


func _write(line: String, dim := false) -> void:
	if line == "":
		return
	var l := MathLabel.new()
	l.font_size = UITheme.fs(19)
	l.max_width = INNER_W - (284.0 if plot and plot.get_parent() != null and item.kind != "judge" else 0.0)
	l.color = UITheme.TEXT_DIM if dim else Color("cfe9ff")
	l.text = line
	l.mouse_filter = Control.MOUSE_FILTER_PASS     # 手指按在字上也能拖動捲動
	board.add_child(l)
	l.modulate.a = 0.0
	l.position.x = -12
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.3)
	_scroll_board_end()


## 捲到推導板最下面（等排版算好再捲）
func _scroll_board_end() -> void:
	if board_scroll == null:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(board_scroll):
		var sb := board_scroll.get_v_scroll_bar()
		board_scroll.create_tween().tween_property(board_scroll, "scroll_vertical", int(sb.max_value), 0.25)


## 答錯：扣一顆心
func _lose_heart() -> void:
	hearts -= 1
	penalty += 1
	Game.of(self).sfx("wrong")
	_update_hud()
	var hl := heart_label
	var tw := create_tween()
	tw.tween_property(hl, "scale", Vector2(1.25, 1.25), 0.08)
	tw.tween_property(hl, "scale", Vector2.ONE, 0.15)
	hl.pivot_offset = hl.size / 2.0
	if hearts <= 0:
		buddy.say("心用完了……我們看一下完整的解法吧！", "worried", 3.0)
	else:
		buddy.say(Buddy.line("wrong"), "worried", 2.0)


func _out_of_hearts() -> bool:
	if hearts > 0:
		return false
	_reveal_all("三顆心都用完了……左邊是完整的解法。")
	return true


## 結束這一層：把剩下的推導都寫上去
func _reveal_all(msg: String) -> void:
	for i in range(si, steps.size()):
		_write_pre(i, true)
		_write(String(steps[i].get("write", "")), true)
	_lock_widgets()
	_hint(msg, "bad")
	si = steps.size()
	if plot:
		plot.stage = 99
	_finish(false)


func _lock_widgets() -> void:
	for b in opts_box.get_children():
		if b is Button:
			b.disabled = true
	action_btn.visible = false
	if numline:
		numline.locked = true
	for t in root_tokens:
		t.btn.disabled = true
	for jr in judge_rows:
		for b in jr.btns:
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _finish(ok: bool) -> void:
	done = true
	waiting = false
	step_label.text = _step_bar()
	var stars := 0
	if ok:
		stars = clampi(3 - penalty, 1, 3)
		Game.of(self).sfx("success" if stars < 3 else "fanfare")
		Game.of(self).quest_event("correct", {"stars": stars})
		_hint("通過！ " + "★".repeat(stars) + "☆".repeat(3 - stars), "good")
		buddy.say(Buddy.line("perfect" if stars == 3 else "pass"), "happy", 2.6)
	_set_meta_stars(stars)
	prompt_label.text = ""
	part_label.visible = false
	_clear(opts_box)
	action_btn.visible = false
	next_btn.text = ("前往第 %d 層  ▲" % (floor_n + 1)) if hearts > 0 else "看攀登結果  ▶"
	if test_mode:
		next_btn.text = "再來一題"
	next_btn.visible = true
	_update_hud()


var _stars := 0


func _set_meta_stars(s: int) -> void:
	_stars = s


func _on_next() -> void:
	if test_mode:
		Game.of(self).goto("boss_tower.gd")
		return
	Game.of(self).tower_report(_stars, hearts)


func _process(delta: float) -> void:
	if done or waiting or get_tree().paused:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		hearts -= 1
		Game.of(self).sfx("wrong")
		_update_hud()
		_reveal_all("時間到！扣一顆心。左邊是完整的解法。")
		return
	if int(time_left * 4.0) != int((time_left + delta) * 4.0):
		_update_hud()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") and not pause_menu.is_open():
		pause_menu.open()
		get_viewport().set_input_as_handled()


## 右邊大按鈕：送出審判／確認／繼續
func _on_action() -> void:
	if done:
		return
	if waiting:
		_advance()
		return
	match String(steps[si].t):
		"judge":
			_check_judge()
		"roots":
			_check_roots()
		"line":
			_check_line()


func _wait_continue() -> void:
	waiting = true
	action_btn.text = "繼續  ▶" if si + 1 < steps.size() else "完成這一層  ✓"
	action_btn.visible = true
	action_btn.disabled = false


# ================= 選擇題 =================

func _build_choice(s: Dictionary) -> void:
	var order := range(s.opts.size())
	order.shuffle()
	for k in order:
		var b := MathLabel.make_button(String(s.opts[k]), 19, Vector2(0, 50))
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_choice.bind(k, b))
		opts_box.add_child(b)
		b.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.05 * opts_box.get_child_count())
		tw.tween_property(b, "modulate:a", 1.0, 0.2)


func _on_choice(k: int, b: Button) -> void:
	if done or waiting:
		return
	var s: Dictionary = steps[si]
	if k == 0:
		Game.of(self).sfx("correct")
		b.add_theme_stylebox_override("normal", UITheme.box(Color(UITheme.GOOD.r, UITheme.GOOD.g, UITheme.GOOD.b, 0.25), 14, UITheme.GOOD, 2, 12))
		b.add_theme_stylebox_override("disabled", b.get_theme_stylebox("normal"))
		for o in opts_box.get_children():
			o.disabled = true
		_write(String(s.get("write", "")))
		_hint("答對了！", "good")
		var gen := si
		await get_tree().create_timer(0.7).timeout
		if gen == si and not done:
			_advance()
	else:
		b.disabled = true
		b.modulate = Color(1, 0.6, 0.65, 0.6)
		_lose_heart()
		if _out_of_hearts():
			return
		_hint("不對喔。" + String(s.get("hint", "")), "bad")


# ================= 真假審判 =================

func _build_judge(s: Dictionary) -> void:
	_clear(widget_box)
	judge_rows.clear()
	var letters := ["A", "B", "C", "D", "E", "F"]
	var cards: Array = s.cards
	for i in cards.size():
		var c: Dictionary = cards[i]
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UITheme.box(Color(1, 1, 1, 0.04), 12, Color(1, 1, 1, 0.08), 1, 4))
		panel.mouse_filter = Control.MOUSE_FILTER_PASS      # 手指按在卡片上也能上下拖動捲動（理由展開後常超出畫面）
		widget_box.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.add_child(row)
		var lt := Label.new()
		lt.text = letters[i]
		lt.add_theme_font_size_override("font_size", UITheme.fs(17))
		lt.add_theme_color_override("font_color", kind_col)
		lt.custom_minimum_size = Vector2(18, 0)
		lt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(lt)
		var mid := VBoxContainer.new()
		mid.add_theme_constant_override("separation", 0)
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(mid)
		var st := MathLabel.new()
		st.font_size = UITheme.fs(17)
		st.max_width = INNER_W - 18 - 2 * 58 - 50
		st.text = c.s
		st.mouse_filter = Control.MOUSE_FILTER_PASS
		mid.mouse_filter = Control.MOUSE_FILTER_PASS
		mid.add_child(st)
		var why := MathLabel.new()
		why.font_size = UITheme.fs(14)
		why.max_width = st.max_width
		why.color = UITheme.TEXT_DIM
		why.visible = false
		why.mouse_filter = Control.MOUSE_FILTER_PASS
		mid.add_child(why)
		var btns := []
		for v in [true, false]:
			var b := Button.new()
			b.text = "真" if v else "假"
			b.toggle_mode = true
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(52, 34)
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			b.add_theme_font_size_override("font_size", UITheme.fs(17))
			UITheme.tight(b, 2)
			var on := UITheme.GOOD if v else UITheme.BAD
			b.add_theme_stylebox_override("pressed", UITheme.box(Color(on.r, on.g, on.b, 0.3), 10, on, 2, 6))
			b.add_theme_stylebox_override("hover_pressed", UITheme.box(Color(on.r, on.g, on.b, 0.38), 10, on, 2, 6))
			row.add_child(b)
			btns.append(b)
		var jr := {"panel": panel, "pick": 0, "btns": btns, "why": why, "card": c}
		judge_rows.append(jr)
		for bi in 2:
			btns[bi].pressed.connect(_on_judge_pick.bind(jr, bi))
		panel.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.08 * i + 0.2)
		tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	action_btn.text = "送出審判"
	action_btn.visible = true
	_refresh_judge_btn()


func _on_judge_pick(jr: Dictionary, bi: int) -> void:
	Game.of(self).sfx("click")
	var want := 1 if bi == 0 else -1
	jr.pick = want if jr.btns[bi].button_pressed else 0
	jr.btns[1 - bi].set_pressed_no_signal(false)
	_refresh_judge_btn()


func _refresh_judge_btn() -> void:
	var n := 0
	for jr in judge_rows:
		if jr.pick != 0:
			n += 1
	action_btn.disabled = n < judge_rows.size()
	action_btn.text = "送出審判" if n == judge_rows.size() else "送出審判（還有 %d 張）" % (judge_rows.size() - n)


func _check_judge() -> void:
	var wrong := 0
	for jr in judge_rows:
		var truth: bool = jr.card.ok
		var right: bool = (jr.pick == 1) == truth
		if not right:
			wrong += 1
		var c := UITheme.GOOD if right else UITheme.BAD
		jr.panel.add_theme_stylebox_override("panel", UITheme.box(Color(c.r, c.g, c.b, 0.10), 12, Color(c.r, c.g, c.b, 0.7), 1, 8))
		jr.why.text = ("✓ " if right else "✗ ") + ("[color=#6ee7a0]真[/color]" if truth else "[color=#ff6b7a]假[/color]") + "：" + String(jr.card.why)
		jr.why.visible = true
		for b in jr.btns:
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if not b.button_pressed:
				b.modulate.a = 0.35
	if wrong == 0:
		Game.of(self).sfx("correct")
		_hint("全部判斷正確！", "good")
	elif wrong == 1:
		penalty += 1
		Game.of(self).sfx("tick")
		_hint("錯了 1 張，不扣心。看一下紅色那張的理由。", "info")
	else:
		_lose_heart()
		if _out_of_hearts():
			return
		_hint("錯了 %d 張，扣一顆心。每張卡片下面都有理由。" % wrong, "bad")
	_wait_continue()


# ================= 驗根之刃 =================

func _build_roots(s: Dictionary) -> void:
	_clear(widget_box)
	root_tokens.clear()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	widget_box.add_child(row)
	for c in s.cands:
		var b := MathLabel.make_button(String(c.v), 22, Vector2(150, 64))
		b.focus_mode = Control.FOCUS_NONE
		var strike := Strike.new()
		strike.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(strike)
		row.add_child(b)
		var tok := {"btn": b, "struck": false, "cand": c, "strike": strike}
		root_tokens.append(tok)
		b.pressed.connect(func():
			if waiting or done:
				return
			tok.struck = not tok.struck
			strike.on = tok.struck
			strike.queue_redraw()
			Game.of(self).sfx("click"))
	var whys := VBoxContainer.new()
	whys.name = "Whys"
	widget_box.add_child(whys)
	var tip := Label.new()
	tip.text = "點一下劃掉，再點一下復原"
	tip.add_theme_font_size_override("font_size", UITheme.fs(14))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	whys.add_child(tip)
	action_btn.text = "確認"
	action_btn.visible = true


func _check_roots() -> void:
	var all_right := true
	var whys: VBoxContainer = widget_box.get_node("Whys")
	_clear(whys)
	for t in root_tokens:
		var keep: bool = t.cand.ok
		var right: bool = keep != t.struck
		if not right:
			all_right = false
		t.strike.on = not keep
		t.strike.bad = not right
		t.strike.queue_redraw()
		var c := UITheme.GOOD if right else UITheme.BAD
		t.btn.add_theme_stylebox_override("disabled", UITheme.box(Color(c.r, c.g, c.b, 0.14), 14, c, 2, 8))
		t.btn.disabled = true
		var l := MathLabel.new()
		l.font_size = UITheme.fs(15)
		l.max_width = INNER_W
		l.color = UITheme.TEXT_DIM
		l.text = String(t.cand.v) + ("　保留：" if keep else "　不合：") + String(t.cand.why)
		whys.add_child(l)
	if all_right:
		Game.of(self).sfx("correct")
		_hint("驗根完成！", "good")
	else:
		_lose_heart()
		if _out_of_hearts():
			return
		_hint("判斷有誤，扣一顆心。看看每個根的理由。", "bad")
	_write(String(steps[si].get("write", "")))
	_wait_continue()


# ================= 數線封印 =================

func _build_line(s: Dictionary) -> void:
	var prev_line := si > 0 and String(steps[si - 1].t) == "line" and numline != null
	if not prev_line:
		_clear(widget_box)
		numline = NumLine.new()
		numline.marks = s.marks
		widget_box.add_child(numline)
		numline.changed.connect(func(): Game.of(self).sfx("click"))
	numline.add_row(String(s.row), s.seg.size(), kind_col)
	action_btn.text = "封印！"
	action_btn.visible = true
	_hint("點數線上的「區段」選範圍，點「端點」決定要不要包含（實心＝包含）。", "info")


func _check_line() -> void:
	var s: Dictionary = steps[si]
	var ok := numline.check(s.seg, s.pt)
	if ok:
		Game.of(self).sfx("correct")
		_hint("封印成功！", "good")
		_write(String(s.get("write", "")))
		var gen := si
		await get_tree().create_timer(0.8).timeout
		if gen == si and not done:
			_advance()
		return
	_lose_heart()
	numline.show_answer(s.seg, s.pt)
	if _out_of_hearts():
		return
	_hint("位置不對，扣一顆心。正確的範圍已經畫出來了。", "bad")
	_write(String(s.get("write", "")))
	_wait_continue()


# ================= 小元件 =================

## 背景：深色夜空＋塔磚的淡紋
class TowerBg extends Control:
	var t := 0.0
	var stars: Array = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for i in 70:
			stars.append({"p": Vector2(rng.randf() * 1152.0, rng.randf() * 648.0), "s": rng.randf_range(0.6, 1.6), "ph": rng.randf() * TAU})

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("0b0d20"))
		for s in stars:
			UITheme.dot(self, s.p, s.s, Color(1, 0.85, 0.9, 0.12 + 0.12 * sin(t * 1.3 + s.ph)))
		# 底部一點點暖色的光
		for i in 6:
			var a := 0.03 - i * 0.004
			draw_rect(Rect2(0, size.y - 40 - i * 20, size.x, 40 + i * 20), Color(1, 0.5, 0.6, maxf(a, 0.0)))


## 劃掉的那條斜線
class Strike extends Control:
	var on := false
	var bad := false

	func _draw() -> void:
		if not on:
			return
		var c := UITheme.BAD if not bad else Color("ffb454")
		draw_line(Vector2(12, size.y - 14), Vector2(size.x - 12, 14), c, 4.0, true)


## 數線封印：同一條數線，可以有好幾列（定義域、不等式、交集…）
class NumLine extends Control:
	signal changed
	const ROW_H := 50.0
	const LABEL_W := 74.0
	var marks: Array = []
	var rows: Array = []          # {name, seg: Array[int], pt: Array[int], col, done, ans_seg, ans_pt}
	var locked := false
	var hover := -99

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func add_row(nm: String, nseg: int, col: Color) -> void:
		for r in rows:
			r.done = true
		var seg := []
		seg.resize(nseg)
		seg.fill(0)
		var pt := []
		pt.resize(maxi(0, nseg - 1))
		pt.fill(0)
		rows.append({"name": nm, "seg": seg, "pt": pt, "col": col, "done": false, "bad": false})
		custom_minimum_size = Vector2(0, rows.size() * ROW_H + 46)
		update_minimum_size()
		queue_redraw()

	func _xs() -> Array:
		var x0 := LABEL_W + 40.0
		var x1 := size.x - 30.0
		var n := marks.size()
		var out := []
		for i in n:
			out.append(x0 + (x1 - x0) * (i + 0.5) / n)
		return out

	func _seg_span(i: int, xs: Array) -> Vector2:
		var a: float = LABEL_W + 14.0 if i == 0 else xs[i - 1]
		var b: float = size.x - 8.0 if i == xs.size() else xs[i]
		return Vector2(a, b)

	func _row_y(ri: int) -> float:
		return 18.0 + ri * ROW_H + ROW_H * 0.5

	func check(seg: Array, pt: Array) -> bool:
		var r: Dictionary = rows.back()
		for i in seg.size():
			if int(r.seg[i]) != int(seg[i]):
				return false
		for i in pt.size():
			if int(r.pt[i]) != int(pt[i]):
				return false
		r.done = true
		queue_redraw()
		return true

	func show_answer(seg: Array, pt: Array) -> void:
		var r: Dictionary = rows.back()
		r.seg = seg.duplicate()
		r.pt = pt.duplicate()
		r.done = true
		r.bad = true
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if locked or rows.is_empty() or rows.back().done:
			return
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var p: Vector2 = e.position
			var xs := _xs()
			var r: Dictionary = rows.back()
			# 先看是不是點在端點附近
			for i in xs.size():
				if absf(p.x - xs[i]) < 18.0:
					r.pt[i] = 1 - int(r.pt[i])
					changed.emit()
					queue_redraw()
					return
			for i in xs.size() + 1:
				var sp := _seg_span(i, xs)
				if p.x > sp.x and p.x < sp.y:
					r.seg[i] = 1 - int(r.seg[i])
					changed.emit()
					queue_redraw()
					return

	func _draw() -> void:
		var font := get_theme_default_font()
		var xs := _xs()
		var axis_y := rows.size() * ROW_H + 18.0
		# 每一列
		for ri in rows.size():
			var r: Dictionary = rows[ri]
			var y := _row_y(ri)
			var active: bool = not r.done
			var col: Color = r.col if active else (Color("ffb454") if r.bad else Color("5ad8ff"))
			if r.done and not r.bad and ri == rows.size() - 1:
				col = UITheme.GOOD
			if active:
				draw_rect(Rect2(LABEL_W, y - ROW_H * 0.5 + 3, size.x - LABEL_W, ROW_H - 6), Color(col.r, col.g, col.b, 0.07))
			draw_string(font, Vector2(0, y + 6), r.name, HORIZONTAL_ALIGNMENT_RIGHT, LABEL_W - 8, UITheme.fs(15),
				col if active else Color(col.r, col.g, col.b, 0.85))
			# 每一段的底線（可以點的地方）
			for i in xs.size() + 1:
				var sp := _seg_span(i, xs)
				var on: bool = int(r.seg[i]) == 1
				var a := sp.x + 9.0
				var b := sp.y - 9.0
				if on:
					draw_line(Vector2(a, y), Vector2(b, y), col, 8.0, true)
					if i == 0:
						draw_colored_polygon(PackedVector2Array([Vector2(a - 10, y), Vector2(a + 2, y - 8), Vector2(a + 2, y + 8)]), col)
					if i == xs.size():
						draw_colored_polygon(PackedVector2Array([Vector2(b + 10, y), Vector2(b - 2, y - 8), Vector2(b - 2, y + 8)]), col)
				elif active:
					draw_dashed_line(Vector2(a, y), Vector2(b, y), Color(1, 1, 1, 0.18), 2.0, 6.0)
			# 端點
			for i in xs.size():
				var c := Vector2(xs[i], y)
				var on_p: bool = int(r.pt[i]) == 1
				if on_p:
					UITheme.dot(self, c, 8.0, col)
				else:
					UITheme.dot(self, c, 8.0, Color("0b0d20"))
					draw_arc(c, 8.0, 0, TAU, 24, col if active else Color(col.r, col.g, col.b, 0.8), 2.0, true)
		# 底下的數線
		draw_line(Vector2(LABEL_W + 6, axis_y), Vector2(size.x - 4, axis_y), Color(1, 1, 1, 0.45), 2.0, true)
		draw_colored_polygon(PackedVector2Array([Vector2(size.x - 2, axis_y), Vector2(size.x - 12, axis_y - 5), Vector2(size.x - 12, axis_y + 5)]), Color(1, 1, 1, 0.45))
		for i in xs.size():
			draw_line(Vector2(xs[i], axis_y - 6), Vector2(xs[i], axis_y + 6), Color(1, 1, 1, 0.6), 2.0)
			for ri in rows.size():
				draw_line(Vector2(xs[i], _row_y(ri) + 11), Vector2(xs[i], _row_y(ri) + ROW_H - 11 if ri < rows.size() - 1 else axis_y - 8), Color(1, 1, 1, 0.08), 1.0)
			MathLabel.draw_on(self, font, xs[i], axis_y + 26, String(marks[i]), UITheme.fs(17), UITheme.TEXT)


## 小座標圖：曲線（f 用 x 當變數，Godot 的 Expression 語法）、範圍色帶、點、鉛直虛線。
## 每個圖層可以有 at：完成第幾步之後才出現。
class Plot extends Control:
	var data: Dictionary = {}
	var stage := 0:
		set(v):
			stage = v
			queue_redraw()
	var _cache := {}
	var t := 0.0

	func _ready() -> void:
		clip_contents = true

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _vis(layer: Dictionary) -> bool:
		return stage >= int(layer.get("at", 0))

	func _to(p: Vector2) -> Vector2:
		var xr: Array = data.x
		var yr: Array = data.y
		var r := Rect2(Vector2(10, 10), size - Vector2(20, 20))
		return Vector2(r.position.x + (p.x - xr[0]) / (xr[1] - xr[0]) * r.size.x,
			r.end.y - (p.y - yr[0]) / (yr[1] - yr[0]) * r.size.y)

	func _sample(f: String) -> Array:
		if _cache.has(f):
			return _cache[f]
		var ex := Expression.new()
		var pts := []
		if ex.parse(f, ["x"]) != OK:
			_cache[f] = pts
			return pts
		var xr: Array = data.x
		var n := 240
		for i in n + 1:
			var x: float = lerpf(xr[0], xr[1], float(i) / n)
			var v = ex.execute([x])
			if ex.has_execute_failed() or not (v is float or v is int):
				pts.append(null)
				continue
			var y := float(v)
			pts.append(Vector2(x, y) if is_finite(y) else null)
		_cache[f] = pts
		return pts

	static func _col(nm: String) -> Color:
		return {"cyan": UITheme.CYAN, "pink": UITheme.PINK, "orange": Color("ffb454"), "lime": UITheme.LIME,
			"dim": Color(1, 1, 1, 0.55), "faint": Color(1, 1, 1, 0.22)}.get(nm, UITheme.CYAN)

	func _draw() -> void:
		draw_style_box(UITheme.boxc(Color(0.04, 0.05, 0.12, 0.9), 14, Color(1, 1, 1, 0.08), 1, 0), Rect2(Vector2.ZERO, size))
		var font := get_theme_default_font()
		var xr: Array = data.x
		var yr: Array = data.y
		# 格線
		var step := 1.0 if (xr[1] - xr[0]) <= 10.0 else 2.0
		var gx := ceilf(xr[0] / step) * step
		while gx <= xr[1]:
			var a := _to(Vector2(gx, yr[0]))
			var b := _to(Vector2(gx, yr[1]))
			draw_line(a, b, Color(1, 1, 1, 0.05), 1.0)
			gx += step
		var ystep := 1.0 if (yr[1] - yr[0]) <= 10.0 else 2.0
		var gy := ceilf(yr[0] / ystep) * ystep
		while gy <= yr[1]:
			draw_line(_to(Vector2(xr[0], gy)), _to(Vector2(xr[1], gy)), Color(1, 1, 1, 0.05), 1.0)
			gy += ystep
		# 範圍色帶
		if data.has("band") and _vis(data.band):
			var lo: float = data.band.get("lo", xr[0])
			var hi: float = data.band.get("hi", xr[1])
			var p0 := _to(Vector2(maxf(lo, xr[0]), yr[1]))
			var p1 := _to(Vector2(minf(hi, xr[1]), yr[0]))
			var pulse := 0.10 + 0.04 * sin(t * 3.0)
			draw_rect(Rect2(p0, p1 - p0), Color(1, 0.71, 0.33, pulse))
			for xv in [lo, hi]:
				if xv > xr[0] and xv < xr[1]:
					draw_dashed_line(_to(Vector2(xv, yr[0])), _to(Vector2(xv, yr[1])), Color(1, 0.71, 0.33, 0.7), 1.5, 5.0)
		# 坐標軸
		if xr[0] < 0.0 and xr[1] > 0.0:
			draw_line(_to(Vector2(0, yr[0])), _to(Vector2(0, yr[1])), Color(1, 1, 1, 0.4), 1.5)
		if yr[0] < 0.0 and yr[1] > 0.0:
			draw_line(_to(Vector2(xr[0], 0)), _to(Vector2(xr[1], 0)), Color(1, 1, 1, 0.4), 1.5)
			preload("math_text.gd").draw_text(self, font, _to(Vector2(xr[1], 0)) + Vector2(-14, -6), String(data.get("var", "x")), HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14), Color(1, 1, 1, 0.6))
		# 鉛直虛線（漸近線）
		for v in data.get("vlines", []):
			if _vis(v):
				draw_dashed_line(_to(Vector2(v.x, yr[0])), _to(Vector2(v.x, yr[1])), Color(1, 1, 1, 0.5), 1.5, 6.0)
		# 曲線
		for c in data.get("curves", []):
			if not _vis(c):
				continue
			var col := _col(String(c.get("c", "cyan")))
			var dom: Array = c.get("dom", [-1e9, 1e9])
			var pts := _sample(String(c.f))
			var faint := PackedVector2Array()
			var bright := PackedVector2Array()
			for p in pts:
				var span: float = yr[1] - yr[0]
				var ok: bool = p != null and p.y > yr[0] - span and p.y < yr[1] + span
				if not ok:
					if faint.size() > 1:
						draw_polyline(UITheme.thin(faint), Color(col.r, col.g, col.b, 0.25), 2.0, true)
					if bright.size() > 1:
						draw_polyline(UITheme.thin(bright), col, 3.0, true)
					faint = PackedVector2Array()
					bright = PackedVector2Array()
					continue
				var sp := _to(p)
				faint.append(sp)
				if p.x >= dom[0] and p.x <= dom[1]:
					bright.append(sp)
				elif bright.size() > 1:
					draw_polyline(UITheme.thin(bright), col, 3.0, true)
					bright = PackedVector2Array()
				else:
					bright = PackedVector2Array()
			if faint.size() > 1:
				draw_polyline(UITheme.thin(faint), Color(col.r, col.g, col.b, 0.25), 2.0, true)
			if bright.size() > 1:
				draw_polyline(UITheme.thin(bright), col, 3.0, true)
		# 點
		for p in data.get("pts", []):
			if not _vis(p):
				continue
			var sp := _to(Vector2(p.x, p.y))
			UITheme.dot(self, sp, 9.0, Color(1, 0.85, 0.45, 0.2))
			UITheme.dot(self, sp, 5.0, UITheme.ACCENT)
			var lbl := String(p.get("label", ""))
			if lbl != "":
				var right := sp.x < size.x - 70.0
				var off := Vector2(8, -8) if right else Vector2(-8 - font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14)).x, -8)
				if p.has("off"):
					off = Vector2(p.off[0], p.off[1])
				var tp := sp + off
				draw_string_outline(font, tp, lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UITheme.fs(4), Color(0.04, 0.05, 0.12, 0.9))
				draw_string(font, tp, lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14), UITheme.ACCENT)
