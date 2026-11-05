extends Control
## 終焉之塔：段考風格的題目（每個單元一份題庫：指對數 tower_bank.gd、多項式 poly_tower_bank.gd）
##   左邊「題目板」：題目、推導板（每答對一步就寫上一行）、互動區（真假卡片／候選根／數線封印）
##   右邊「作答區」：步驟進度、這一步要做什麼、選項、提示
## 步驟種類：choice 選擇、judge 真假審判、roots 驗根、line 數線封印、sign 數線標正負號、
##           pick 選圖（選項是小座標圖）、fill 用數字鍵盤填答案
## 分類討論：步驟寫 "col": "A"／"B"，推導板分成左右兩欄（欄名在題目的 "routes"）
## 整趟攀登共用三顆心（由 Game 傳進來），每層限時。

const UITheme := preload("res://data/ui/game_theme.gd")
const MathLabel := preload("res://data/ui/math_text.gd")
const Game := preload("res://data/core/game.gd")
const PauseMenu := preload("res://data/ui/pause_menu.gd")
const Buddy := preload("res://data/ui/buddy.gd")
const Center := preload("res://data/core/review_center.gd")
var Bank: Script           # 這個單元的題庫（units.gd 的 "tower"：指對數 tower_bank.gd、多項式 poly_tower_bank.gd）

const STAGE_W := 700.0
const STAGE_H := 556.0
const INNER_W := 652.0      # 題目板內容寬（扣掉左右內距）
const CARD_W := 348.0       # 右邊作答區內容寬
const PLOT_W := 250.0       # 題目板右邊小座標圖的寬
const CARD_MAX_H := 556.0   # 右邊作答區最高多高（再高就超出畫面）
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
var more_btn: Button          # 推導板下面還有東西時的「▼ 往下滑還有」
var answer_card: PanelContainer
var fail_at := -1             # 沒通過時從第幾步開始是示範的（步驟列顯示 ✗）

# 各題型的狀態
var judge_rows: Array = []      # [{row, pick, btns, why, card}]
var root_tokens: Array = []     # [{btn, struck, cand, why}]
var numline: NumLine = null
var pick_tiles: Array = []      # 選圖題的每一張圖（按鈕）
var fill_on := false            # 數字鍵盤正在作答
var fill_vals: Array = []       # 每一格目前填的字
var fill_cur := 0               # 正在填第幾格
var fill_label: MathLabel


var scratch: Control      # 計算紙

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.shared()
	randomize()
	var a: Dictionary = Game.of(self).take_args()
	Bank = Center.tower_bank(String(a.get("unit", Game.of(self).cur_unit)))
	if Bank == null:
		Bank = Center.tower_bank("exp")
	if a.has("review"):
		item = Bank.by_id(String(a.review.slot))
		floor_n = int(a.get("tower_floor", 1))
		hearts = int(a.get("tower_hearts", MAX_HEARTS))
		time_total = float(a.get("tower_time", 120.0))
	else:
		test_mode = true
		var all: Array = Bank.items()
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
	title.add_theme_font_size_override("font_size", UITheme.fs(24))
	title.add_theme_color_override("font_color", UITheme.ROSE)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)
	floor_label = Label.new()
	floor_label.add_theme_font_size_override("font_size", UITheme.fs(20))
	floor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	floor_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(floor_label)
	heart_label = Label.new()
	heart_label.add_theme_font_size_override("font_size", UITheme.fs(24))
	heart_label.add_theme_color_override("font_color", UITheme.PINK)
	heart_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(heart_label)
	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", UITheme.fs(24))
	timer_label.custom_minimum_size = Vector2(96, 0)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(timer_label)
	var pb := UITheme.round_button("pause", 44)
	pb.tooltip_text = "暫停（Esc）"
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pb.pressed.connect(func(): pause_menu.open())
	top.add_child(pb)
	scratch = preload("res://data/ui/scratch_pad.gd").attach(self, top, pb)     # 計算紙（暫停鍵左邊的筆）

	# 左：題目板
	stage_panel = PanelContainer.new()
	stage_panel.position = Vector2(24, 70)
	stage_panel.custom_minimum_size = Vector2(STAGE_W, STAGE_H)
	stage_panel.size = Vector2(STAGE_W, STAGE_H)
	stage_panel.clip_contents = true
	var sb := UITheme.box(Color(0.07, 0.05, 0.16, 0.8), 18, Color(kind_col.r, kind_col.g, kind_col.b, 0.35), 1, 24)
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
	# 推導板：寫的行數多了可以上下捲動（新寫的一行會自動捲到看得見）；
	# 右邊的小座標圖固定不動，不跟著推導板一起捲走
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scol.add_child(body)
	var scroll_box := Control.new()      # 推導板＋「往下還有」的提示
	scroll_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_box.mouse_filter = Control.MOUSE_FILTER_PASS
	body.add_child(scroll_box)
	board_scroll = ScrollContainer.new()
	board_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER   # 不佔寬度；用手指拖動或滾輪捲
	scroll_box.add_child(board_scroll)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_scroll.add_child(left)
	board = VBoxContainer.new()
	board.add_theme_constant_override("separation", 2)
	left.add_child(board)
	widget_box = VBoxContainer.new()
	widget_box.add_theme_constant_override("separation", 6)
	left.add_child(widget_box)
	# 下面還有東西（被捲到看不到）時，底部中間出現「▼ 往下滑」，點一下往下捲
	more_btn = Button.new()
	more_btn.text = "▼ 下面還有"
	more_btn.focus_mode = Control.FOCUS_NONE
	more_btn.add_theme_font_size_override("font_size", UITheme.fs(15))
	more_btn.add_theme_color_override("font_color", UITheme.ACCENT)
	var mb := UITheme.box(Color(0.1, 0.07, 0.22, 0.94), 14, Color(UITheme.ACCENT.r, UITheme.ACCENT.g, UITheme.ACCENT.b, 0.6), 1, 6)
	mb.content_margin_left = 14
	mb.content_margin_right = 14
	for st in ["normal", "hover", "pressed"]:
		more_btn.add_theme_stylebox_override(st, mb)
	more_btn.anchor_left = 1.0         # 右下角（左下角是光靈說話的地方）
	more_btn.anchor_right = 1.0
	more_btn.anchor_top = 1.0
	more_btn.anchor_bottom = 1.0
	more_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	more_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	more_btn.offset_right = -2
	more_btn.offset_bottom = -4
	more_btn.visible = false
	more_btn.pressed.connect(func():
		var sb2 := board_scroll.get_v_scroll_bar()
		var to := mini(int(sb2.max_value - sb2.page), board_scroll.scroll_vertical + int(board_scroll.size.y * 0.7))
		board_scroll.create_tween().tween_property(board_scroll, "scroll_vertical", to, 0.25))
	scroll_box.add_child(more_btn)
	var has_plot: bool = item.has("plot")
	if has_plot:
		plot = Plot.new()
		plot.data = item.plot
		if item.kind == "judge":
			plot.custom_minimum_size = Vector2(CARD_W, 210)
		else:
			plot.custom_minimum_size = Vector2(PLOT_W, 250)
			plot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			body.add_child(plot)

	# 右：作答區
	var card := PanelContainer.new()
	answer_card = card
	card.position = Vector2(744, 70)
	card.custom_minimum_size = Vector2(384, STAGE_H)
	card.add_theme_stylebox_override("panel", UITheme.box(Color(UITheme.PANEL.r, UITheme.PANEL.g, UITheme.PANEL.b, 0.86), 18, Color(1, 1, 1, 0.07), 1, 18))
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
	part_label.add_theme_font_size_override("font_size", UITheme.fs(15))
	part_label.add_theme_color_override("font_color", kind_col)
	part_label.visible = false
	col.add_child(part_label)
	prompt_label = MathLabel.new()
	prompt_label.font_size = UITheme.fs(17)
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
	var nums := ["①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩", "⑪", "⑫"]
	for i in steps.size():
		var nm: String = nums[i] if i < nums.size() else str(i + 1)
		if fail_at >= 0 and i >= fail_at:
			parts.append("[color=#ff6b7a]✗[/color]")      # 沒通過：示範的步驟
		elif i < si or done:
			parts.append("[color=#6ee7a0]✓[/color]")
		elif i == si:
			parts.append("[color=#ffcf5a]%s[/color]" % nm)
		else:
			parts.append(nm)
	# 步驟多的大題：箭頭間距縮小，一行放得下
	return (" › " if steps.size() > 7 else "  ›  ").join(parts)


# ================= 流程 =================

func _start() -> void:
	if scratch:
		scratch.clear()      # 換下一題：清掉計算紙
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
		_write(String(ln), dim, i)


func _show_step() -> void:
	waiting = false
	var s: Dictionary = steps[si]
	_write_pre(si)
	step_label.text = _step_bar()
	part_label.visible = s.has("part") or s.has("col")
	part_label.text = "小題 %s" % s.get("part", "")
	if s.has("col"):
		part_label.text = ("小題 %s　" % s.part if s.has("part") else "") + "路線 %s：%s" % [s.col, String(item.get("routes", {}).get(s.col, ""))]
	prompt_label.text = s.q
	_clear(opts_box)
	_unfit_card()
	hint_panel.visible = false
	action_btn.visible = false
	action_btn.disabled = false
	if plot:
		plot.stage = si
	match s.t:
		"choice":
			# 數線留著當參考（例如最後算「範圍內有幾個整數」）；其他互動區清掉
			if numline == null or not is_instance_valid(numline):
				_clear(widget_box)
			_build_choice(s)
		"judge":
			_build_judge(s)
		"roots":
			_build_roots(s)
		"line", "sign":
			_build_line(s)
		"pick":
			if numline == null or not is_instance_valid(numline):
				_clear(widget_box)
			_build_pick(s)
		"fill":
			if numline == null or not is_instance_valid(numline):
				_clear(widget_box)
			_build_fill(s)


func _advance() -> void:
	si += 1
	if plot:
		plot.stage = si
	if si >= steps.size():
		_finish(true)
	else:
		_show_step()


func _write(line: String, dim := false, at := -1) -> void:
	if line == "":
		return
	var idx := si if at < 0 else at
	var col := String(steps[idx].get("col", "")) if idx >= 0 and idx < steps.size() else ""
	var l := MathLabel.new()
	l.font_size = UITheme.fs(20)
	var w := INNER_W - (PLOT_W + 14.0 if plot and plot.get_parent() != null and item.kind != "judge" else 0.0)
	l.max_width = w if col == "" else (w - 14.0) / 2.0
	l.color = UITheme.TEXT_DIM if dim else UITheme.CYAN_PALE
	l.text = line
	l.mouse_filter = Control.MOUSE_FILTER_PASS     # 手指按在字上也能拖動捲動
	if col == "":
		board.add_child(l)
	else:
		_route_box(col).add_child(l)
	l.modulate.a = 0.0
	l.position.x = -12
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.3)
	_scroll_board_end()


## 分類討論：推導板分成左右兩欄（第一次用到時才建立）
var _routes: HBoxContainer
var _route_cols := {}


func _route_box(col: String) -> VBoxContainer:
	if _routes == null:
		_routes = HBoxContainer.new()
		_routes.add_theme_constant_override("separation", 14)
		board.add_child(_routes)
		var names: Dictionary = item.get("routes", {})
		var keys := names.keys()
		keys.sort()
		for k in keys:
			var v := VBoxContainer.new()
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_theme_constant_override("separation", 2)
			var hd := MathLabel.new()
			hd.font_size = UITheme.fs(16)
			hd.color = kind_col
			hd.max_width = (INNER_W - 14.0) / 2.0
			hd.text = "路線 %s：%s" % [k, String(names[k])]
			hd.mouse_filter = Control.MOUSE_FILTER_PASS
			v.add_child(hd)
			_routes.add_child(v)
			_route_cols[String(k)] = v
	if not _route_cols.has(col):
		return board
	return _route_cols[col]


## 捲到推導板最下面（等排版算好再捲）
func _scroll_board_end() -> void:
	if board_scroll == null:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(board_scroll):
		var sb := board_scroll.get_v_scroll_bar()
		board_scroll.create_tween().tween_property(board_scroll, "scroll_vertical", int(sb.max_value), 0.25)


## 捲到看得見某個東西（等排版算好再捲）
func _scroll_to(ctl: Control) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(ctl) or not is_instance_valid(board_scroll):
		return
	var top := ctl.global_position.y - board_scroll.global_position.y + board_scroll.scroll_vertical
	var bottom := top + ctl.size.y
	var to := board_scroll.scroll_vertical
	if bottom > board_scroll.scroll_vertical + board_scroll.size.y:
		to = int(bottom - board_scroll.size.y + 8.0)
	if top < to:
		to = int(maxf(0.0, top - 8.0))
	board_scroll.create_tween().tween_property(board_scroll, "scroll_vertical", to, 0.25)


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
	fail_at = si
	for i in range(si, steps.size()):
		_write_pre(i, true)
		_write(String(steps[i].get("write", "")), true, i)
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
	for t in pick_tiles:
		if is_instance_valid(t):
			t.disabled = true
	fill_on = false


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
	_update_more()
	_fit_card()
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


## 推導板下面還有看不到的東西：顯示「▼ 往下滑還有」
func _update_more() -> void:
	if more_btn == null:
		return
	var sb := board_scroll.get_v_scroll_bar()
	var hidden := sb.max_value - sb.page - float(board_scroll.scroll_vertical)
	more_btn.visible = hidden > 24.0


## 右邊作答區太高（選項是分數、提示又很長）會超出畫面：先縮小間距，再把選項按鈕壓矮一點
func _fit_card() -> void:
	if answer_card == null:
		return
	var over := answer_card.get_combined_minimum_size().y - CARD_MAX_H
	if over <= 0.5:
		if answer_card.size.y > CARD_MAX_H + 0.5:
			answer_card.reset_size()
		return
	var col := answer_card.get_child(0) as Control
	if opts_box.get_theme_constant("separation") > 4:
		opts_box.add_theme_constant_override("separation", 4)
		col.add_theme_constant_override("separation", 6)
		return
	var btns := opts_box.get_children().filter(func(b): return b is Button and b.custom_minimum_size.y > 42.0)
	if not btns.is_empty():
		var cut := ceilf(over / btns.size())
		for bt in btns:
			bt.custom_minimum_size.y = maxf(42.0, bt.custom_minimum_size.y - cut)
		return
	# 數字鍵盤：每一列壓矮一點（最矮 34）
	var pad := opts_box.get_node_or_null("Pad")
	if pad:
		var cut2 := ceilf(over / maxf(1.0, pad.get_child_count()))
		for row in pad.get_children():
			for k in row.get_children():
				k.custom_minimum_size.y = maxf(34.0, k.custom_minimum_size.y - cut2)


## 換下一步：作答區的間距恢復原樣
func _unfit_card() -> void:
	opts_box.add_theme_constant_override("separation", 8)
	if answer_card:
		(answer_card.get_child(0) as Control).add_theme_constant_override("separation", 10)
		answer_card.reset_size()


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
		"line", "sign":
			_check_line()
		"fill":
			_check_fill()


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
		# 太長的選項折成兩行（按鈕跟著變高）
		var m: Control = b.get_node("Math")
		m.max_width = CARD_W - 28.0
		b.custom_minimum_size.y = maxf(50.0, m.get_combined_minimum_size().y + 16.0)
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
		why.font_size = UITheme.fs(15)
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
	# 捲到第一張判錯的卡片，讓學生看得到理由
	for jr in judge_rows:
		if (jr.pick == 1) != bool(jr.card.ok):
			_scroll_to(jr.panel)
			break
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
	tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	whys.add_child(tip)
	action_btn.text = "確認"
	action_btn.visible = true
	_scroll_board_end()


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
	# 同一題的數線共用：前面封印過的列（例如定義域）留著，中間隔了選擇題也一樣
	var prev_line: bool = numline != null and is_instance_valid(numline) and numline.get_parent() == widget_box \
		and numline.marks == s.marks
	if not prev_line:
		_clear(widget_box)
		numline = NumLine.new()
		numline.marks = s.marks
		widget_box.add_child(numline)
		numline.changed.connect(func(): Game.of(self).sfx("click"))
	if String(s.t) == "sign":
		numline.add_row(String(s.row), s.signs.size(), kind_col, "sign")
		action_btn.text = "標好了！"
		action_btn.visible = true
		_hint("點數線上的每一段，標上 ＋ 或 −（再點一下換成另一個）。", "info")
		_scroll_board_end()
		return
	numline.add_row(String(s.row), s.seg.size(), kind_col)
	action_btn.text = "封印！"
	action_btn.visible = true
	_hint("點數線上的「區段」選範圍，點「端點」決定要不要包含（實心＝包含）。", "info")
	_scroll_board_end()


func _check_line() -> void:
	var s: Dictionary = steps[si]
	var is_sign := String(s.t) == "sign"
	var ok := numline.check_signs(s.signs) if is_sign else numline.check(s.seg, s.pt)
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
	if is_sign:
		numline.show_signs(s.signs)
	else:
		numline.show_answer(s.seg, s.pt)
	if _out_of_hearts():
		return
	_hint(("正負號不對，扣一顆心。正確的正負號已經標出來了。" if is_sign else "位置不對，扣一顆心。正確的範圍已經畫出來了。")
		+ ("\n" + String(s.hint) if s.has("hint") else ""), "bad")
	_write(String(s.get("write", "")))
	_wait_continue()



# ================= 選圖題 =================
## {t: "pick", q, graphs: [正確的圖, 錯誤的圖…], hint, write}
##   每張圖是一份 Plot 的資料（x、y 範圍、curves、pts…），畫面上會打亂成 (A)～(E)
##   curves 可以加 "dash": true 畫成虛線（例如題目給的原圖）

func _build_pick(s: Dictionary) -> void:
	pick_tiles.clear()
	var grid := GridContainer.new()
	var n: int = s.graphs.size()
	grid.columns = 3 if n > 4 else 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	widget_box.add_child(grid)
	var tw_w := (INNER_W - 10.0 * (grid.columns - 1)) / grid.columns
	var tw_h := 150.0 if grid.columns == 3 else 170.0
	var order := range(n)
	order.shuffle()
	var letters := ["A", "B", "C", "D", "E", "F"]
	for j in order.size():
		var k: int = order[j]
		var b := Button.new()
		b.custom_minimum_size = Vector2(tw_w, tw_h)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", UITheme.box(Color(1, 1, 1, 0.03), 12, Color(1, 1, 1, 0.12), 1, 4))
		b.add_theme_stylebox_override("hover", UITheme.box(Color(1, 1, 1, 0.07), 12, Color(kind_col.r, kind_col.g, kind_col.b, 0.7), 2, 4))
		b.add_theme_stylebox_override("pressed", b.get_theme_stylebox("hover"))
		var pl := Plot.new()
		pl.data = s.graphs[k]
		pl.stage = 99
		pl.small = true
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pl.offset_left = 4
		pl.offset_top = 4
		pl.offset_right = -4
		pl.offset_bottom = -4
		b.add_child(pl)
		var lt := Label.new()
		lt.text = "(%s)" % letters[j]
		lt.position = Vector2(10, 6)
		lt.add_theme_font_size_override("font_size", UITheme.fs(16))
		lt.add_theme_color_override("font_color", kind_col)
		lt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lt)
		b.set_meta("k", k)
		b.pressed.connect(_on_pick.bind(k, b))
		grid.add_child(b)
		pick_tiles.append(b)
		b.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(0.06 * j)
		tw.tween_property(b, "modulate:a", 1.0, 0.2)
	_scroll_to(grid)


func _on_pick(k: int, b: Button) -> void:
	if done or waiting:
		return
	var s: Dictionary = steps[si]
	if k == 0:
		Game.of(self).sfx("correct")
		var gb := UITheme.box(Color(UITheme.GOOD.r, UITheme.GOOD.g, UITheme.GOOD.b, 0.16), 12, UITheme.GOOD, 3, 4)
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, gb)
		for t in pick_tiles:
			t.disabled = true
			if t != b:
				t.modulate.a = 0.45
		_write(String(s.get("write", "")))
		_hint("答對了！", "good")
		var gen := si
		await get_tree().create_timer(0.9).timeout
		if gen == si and not done:
			_advance()
	else:
		b.disabled = true
		b.add_theme_stylebox_override("disabled", UITheme.box(Color(UITheme.BAD.r, UITheme.BAD.g, UITheme.BAD.b, 0.12), 12, UITheme.BAD, 2, 4))
		b.modulate = Color(1, 0.75, 0.78, 0.7)
		_lose_heart()
		if _out_of_hearts():
			return
		var why: Array = s.get("whys", [])
		var extra := String(why[k]) if k < why.size() else ""
		_hint("不對喔。" + (extra + "\n" if extra != "" else "") + String(s.get("hint", "")), "bad")


# ================= 數字鍵盤填答案 =================
## {t: "fill", q, template: "f(4) = [0]", ans: ["24"], hint, write}
##   template 裡的 [0]、[1]… 是要填的格子；ans 是每一格的答案（分數寫 a/b，比較時看數值，2/4 和 1/2 都算對）

## 鍵盤和八大關一樣分三列：1～5／6～0／− . / ⌫ 送出（好幾格時多一個「下一格」）
const KEY_ROWS := [["1", "2", "3", "4", "5"], ["6", "7", "8", "9", "0"], ["−", ".", "/", "⌫", "送出"]]
const KEYS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "−", ".", "/", "⌫", "▶", "◀"]   # 能打的鍵（測試用）
var fill_send: Button


func _build_fill(s: Dictionary) -> void:
	var n: int = s.ans.size()
	fill_vals = []
	fill_vals.resize(n)
	fill_vals.fill("")
	fill_cur = 0
	fill_on = true
	var disp := PanelContainer.new()
	disp.add_theme_stylebox_override("panel", UITheme.box(Color(0, 0, 0, 0.28), 12, Color(kind_col.r, kind_col.g, kind_col.b, 0.5), 1, 10))
	disp.mouse_filter = Control.MOUSE_FILTER_STOP
	disp.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and fill_vals.size() > 1:
			fill_cur = (fill_cur + 1) % fill_vals.size()
			_refresh_fill())
	opts_box.add_child(disp)
	fill_label = MathLabel.new()
	fill_label.font_size = UITheme.fs(22)
	fill_label.max_width = CARD_W - 24
	fill_label.align_center = true
	fill_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disp.add_child(fill_label)
	var pad := VBoxContainer.new()
	pad.name = "Pad"
	pad.add_theme_constant_override("separation", 6)
	opts_box.add_child(pad)
	for keys in KEY_ROWS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		pad.add_child(row)
		var ks: Array = keys.duplicate()
		if ks.has("送出") and n > 1:
			ks.insert(ks.find("送出"), "▶")
		for key in ks:
			var b := Button.new()
			b.text = "下一格" if key == "▶" else key
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(0, 44)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_font_size_override("font_size", UITheme.fs(20) if String(key).length() == 1 else UITheme.fs(15))
			if key != "送出":
				UITheme.tight(b, 2)
			if key == "▶":
				b.size_flags_stretch_ratio = 1.5
			if key == "送出":
				UITheme.accent_button(b, 18)
				b.size_flags_stretch_ratio = 2.0 if n > 1 else 2.6
				fill_send = b
				b.pressed.connect(func(): _on_action())
			else:
				b.pressed.connect(_on_key.bind(key))
			row.add_child(b)
	action_btn.visible = false
	_refresh_fill()


func _on_key(key: String) -> void:
	if not fill_on or done or waiting:
		return
	Game.of(self).sfx("click")
	var v: String = fill_vals[fill_cur]
	match key:
		"⌫":
			v = v.left(v.length() - 1)
		"◀", "▶":
			# 換格子：不改任何一格的內容
			fill_cur = (fill_cur + (1 if key == "▶" else -1) + fill_vals.size()) % fill_vals.size()
			_refresh_fill()
			return
		_:
			if v.length() < 9:
				v += key
	fill_vals[fill_cur] = v
	_refresh_fill()


func _refresh_fill() -> void:
	var s: Dictionary = steps[si]
	var t := String(s.template)
	for i in fill_vals.size():
		var v: String = fill_vals[i]
		var shown := v if v != "" else "□"
		# 每一格長得一樣，正在填的那一格是金色
		var c := "ffcf5a" if i == fill_cur and fill_on else "9be7ff"
		t = t.replace("[%d]" % i, "[color=#%s]%s[/color]" % [c, shown])
	fill_label.text = t
	var ready := fill_vals.all(func(x): return String(x) != "")
	if is_instance_valid(fill_send):
		fill_send.disabled = not ready or not fill_on


## 把「−3/4」「2.5」這種字串變成數值；看不懂回傳 NAN
static func _num(v: String) -> float:
	var t := v.replace("−", "-").replace(" ", "")
	var re := RegEx.new()
	re.compile("^(-?)(\\d+(?:\\.\\d+)?)(?:/(\\d+(?:\\.\\d+)?))?$")
	var m := re.search(t)
	if m == null:
		return NAN
	var x := float(m.get_string(2))
	if m.get_string(3) != "":
		var d := float(m.get_string(3))
		if d == 0.0:
			return NAN
		x /= d
	return -x if m.get_string(1) == "-" else x


static func fill_match(got: String, want: String) -> bool:
	var a := _num(got)
	var b := _num(want)
	if not is_nan(a) and not is_nan(b):
		return absf(a - b) < 1e-9 * maxf(1.0, absf(b))
	return got.replace(" ", "").replace("-", "−") == want.replace(" ", "").replace("-", "−")


func _check_fill() -> void:
	var s: Dictionary = steps[si]
	var ok := true
	for i in fill_vals.size():
		if not fill_match(String(fill_vals[i]), String(s.ans[i])):
			ok = false
	if ok:
		fill_on = false
		Game.of(self).sfx("correct")
		_refresh_fill()
		action_btn.visible = false
		var pad := opts_box.get_node_or_null("Pad")
		if pad:
			for row in pad.get_children():
				for k in row.get_children():
					k.disabled = true
		_write(String(s.get("write", "")))
		_hint("答對了！", "good")
		var gen := si
		await get_tree().create_timer(0.8).timeout
		if gen == si and not done:
			_advance()
		return
	_lose_heart()
	if _out_of_hearts():
		return
	_hint("不對喔。" + String(s.get("hint", "")), "bad")


func _unhandled_key_input(e: InputEvent) -> void:
	if not fill_on or not (e is InputEventKey) or not e.pressed:
		return
	var k: InputEventKey = e
	var map := {KEY_MINUS: "−", KEY_KP_SUBTRACT: "−", KEY_SLASH: "/", KEY_KP_DIVIDE: "/", KEY_PERIOD: ".",
		KEY_KP_PERIOD: ".", KEY_BACKSPACE: "⌫", KEY_LEFT: "◀", KEY_RIGHT: "▶", KEY_TAB: "▶"}
	if k.keycode >= KEY_0 and k.keycode <= KEY_9:
		_on_key(str(k.keycode - KEY_0))
	elif k.keycode >= KEY_KP_0 and k.keycode <= KEY_KP_9:
		_on_key(str(k.keycode - KEY_KP_0))
	elif map.has(k.keycode):
		_on_key(map[k.keycode])
	elif k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
		if is_instance_valid(fill_send) and not fill_send.disabled:
			_on_action()
	else:
		return
	get_viewport().set_input_as_handled()


# ================= 小元件 =================

## 背景：深色夜空＋塔磚的淡紋
class TowerBg extends Control:
	const Ambient := preload("res://data/ui/ambient.gd")
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
		# 紅紫色的天空：上深紫、下暗紅
		var w := size.x
		var hh := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, hh), Vector2(0, hh)]),
			PackedColorArray([Color("140a26"), Color("140a26"), Color("2e0f24"), Color("2e0f24")]))
		for s in stars:
			UITheme.dot(self, s.p, s.s, Color(1, 0.85, 0.9, 0.12 + 0.12 * sin(t * 1.3 + s.ph)))
		# 底部一點點暖色的光
		for i in 6:
			var a := 0.035 - i * 0.004
			draw_rect(Rect2(0, hh - 40 - i * 20, w, 40 + i * 20), Color(1, 0.35, 0.5, maxf(a, 0.0)))
		# 浮空石塊與往上飄的紅紫光屑
		Ambient.paint(self, "rocks", size, t)


## 劃掉的那條斜線
class Strike extends Control:
	var on := false
	var bad := false

	func _draw() -> void:
		if not on:
			return
		var c := UITheme.BAD if not bad else UITheme.ORANGE
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

	## kind："range" 選區段和端點；"sign" 每一段標 ＋／−（穿根）
	func add_row(nm: String, nseg: int, col: Color, kind := "range") -> void:
		for r in rows:
			r.done = true
		var seg := []
		seg.resize(nseg)
		seg.fill(0)
		var pt := []
		pt.resize(maxi(0, nseg - 1))
		pt.fill(0)
		rows.append({"name": nm, "seg": seg, "pt": pt, "col": col, "done": false, "bad": false, "kind": kind})
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

	func check_signs(signs: Array) -> bool:
		var r: Dictionary = rows.back()
		for i in signs.size():
			if int(r.seg[i]) != int(signs[i]):
				return false
		r.done = true
		queue_redraw()
		return true

	func show_signs(signs: Array) -> void:
		var r: Dictionary = rows.back()
		r.seg = signs.duplicate()
		r.done = true
		r.bad = true
		queue_redraw()

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
			if String(r.get("kind", "range")) == "sign":
				# 正負號：空白 → ＋ → − → ＋ …
				for i in xs.size() + 1:
					var sp0 := _seg_span(i, xs)
					if p.x > sp0.x and p.x < sp0.y:
						r.seg[i] = 1 if int(r.seg[i]) != 1 else -1
						changed.emit()
						queue_redraw()
						return
				return
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
			var col: Color = r.col if active else (UITheme.ORANGE if r.bad else UITheme.CYAN)
			if r.done and not r.bad and ri == rows.size() - 1:
				col = UITheme.GOOD
			if active:
				draw_rect(Rect2(LABEL_W, y - ROW_H * 0.5 + 3, size.x - LABEL_W, ROW_H - 6), Color(col.r, col.g, col.b, 0.07))
			draw_string(font, Vector2(0, y + 6), r.name, HORIZONTAL_ALIGNMENT_RIGHT, LABEL_W - 8, UITheme.fs(15),
				col if active else Color(col.r, col.g, col.b, 0.85))
			if String(r.get("kind", "range")) == "sign":
				for i in xs.size() + 1:
					var sp := _seg_span(i, xs)
					var c := Vector2((sp.x + sp.y) / 2.0, y)
					var v := int(r.seg[i])
					var sc: Color = (UITheme.GOOD if v > 0 else UITheme.BAD) if v != 0 else Color(1, 1, 1, 0.3)
					if not active and not r.bad:
						sc = Color(sc.r, sc.g, sc.b, 0.85)
					UITheme.dot(self, c, 15.0, Color(sc.r, sc.g, sc.b, 0.18))
					draw_arc(c, 15.0, 0, TAU, 28, sc, 2.0, true)
					var txt := "＋" if v > 0 else ("−" if v < 0 else "?")
					draw_string(font, c + Vector2(-14, 7), txt, HORIZONTAL_ALIGNMENT_CENTER, 28, UITheme.fs(20), sc)
				for i in xs.size():
					draw_line(Vector2(xs[i], y - 14), Vector2(xs[i], y + 14), Color(1, 1, 1, 0.35), 2.0)
				continue
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
	var small := false        # 選圖題的小圖：線細一點、不動畫

	func _ready() -> void:
		clip_contents = true
		set_process(not small)

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	## 折線（dash = 虛線）
	func _pl(pts: PackedVector2Array, col: Color, w: float, dash: bool) -> void:
		if pts.size() < 2:
			return
		if not dash:
			draw_polyline(UITheme.thin(pts), col, w, true)
			return
		var on := true
		var left := 7.0
		var cur := PackedVector2Array([pts[0]])
		for i in range(1, pts.size()):
			var a: Vector2 = pts[i - 1]
			var b: Vector2 = pts[i]
			var d := a.distance_to(b)
			var pos := 0.0
			while d - pos > left:
				pos += left
				var q := a.lerp(b, pos / d)
				if on:
					cur.append(q)
					draw_polyline(cur, col, w, true)
				cur = PackedVector2Array([q])
				on = not on
				left = 7.0 if on else 5.0
			left -= d - pos
			if on:
				cur.append(b)
			else:
				cur = PackedVector2Array([b])
		if on and cur.size() > 1:
			draw_polyline(cur, col, w, true)

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
		return {"cyan": UITheme.CYAN, "pink": UITheme.PINK, "orange": UITheme.ORANGE, "lime": UITheme.LIME,
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
			preload("res://data/ui/math_text.gd").draw_text(self, font, _to(Vector2(xr[1], 0)) + Vector2(-14, -6), String(data.get("var", "x")), HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 1, 1, 0.6))
		# 鉛直虛線（漸近線）
		for v in data.get("vlines", []):
			if _vis(v):
				draw_dashed_line(_to(Vector2(v.x, yr[0])), _to(Vector2(v.x, yr[1])), Color(1, 1, 1, 0.5), 1.5, 6.0)
		# 曲線
		for c in data.get("curves", []):
			if not _vis(c):
				continue
			var col := _col(String(c.get("c", "cyan")))
			var dash: bool = c.get("dash", false)
			var lw := 2.4 if small else 3.0
			var dom: Array = c.get("dom", [-1e9, 1e9])
			var pts := _sample(String(c.f))
			var faint := PackedVector2Array()
			var bright := PackedVector2Array()
			for p in pts:
				var span: float = yr[1] - yr[0]
				var ok: bool = p != null and p.y > yr[0] - span and p.y < yr[1] + span
				if not ok:
					if faint.size() > 1:
						_pl(faint, Color(col.r, col.g, col.b, 0.25), 2.0, dash)
					if bright.size() > 1:
						_pl(bright, col, lw, dash)
					faint = PackedVector2Array()
					bright = PackedVector2Array()
					continue
				var sp := _to(p)
				faint.append(sp)
				if p.x >= dom[0] and p.x <= dom[1]:
					bright.append(sp)
				elif bright.size() > 1:
					_pl(bright, col, lw, dash)
					bright = PackedVector2Array()
				else:
					bright = PackedVector2Array()
			if faint.size() > 1:
				_pl(faint, Color(col.r, col.g, col.b, 0.25), 2.0, dash)
			if bright.size() > 1:
				_pl(bright, col, lw, dash)
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
				var off := Vector2(8, -8) if right else Vector2(-8 - font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15)).x, -8)
				if p.has("off"):
					off = Vector2(p.off[0], p.off[1])
				var tp := sp + off
				draw_string_outline(font, tp, lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UITheme.fs(4), Color(0.04, 0.05, 0.12, 0.9))
				draw_string(font, tp, lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), UITheme.ACCENT)
