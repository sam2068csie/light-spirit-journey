extends Control
## 第 3 關「高塔排序」— 指對數比大小（主畫面的關卡列表會開啟這個腳本）
## 用法：新增場景，根節點選 Control，掛上這個腳本即可。介面全部由程式產生。
## 需要同資料夾的 game_theme.gd、math_text.gd、game.gd、pause_menu.gd、settings_panel.gd。
##
## 玩法（每題）：
##   ① 分區：判斷每座塔是「< 0（地底）」「0 ~ 1（地面層）」還是「> 1（高空）」
##   ② 排序：由低到高點選塔名；一樣高的用「＝」並列
##   ③ 送出：塔依你排的順序升起，真實高度一看就知道對不對
## 關卡結構：探索層 2 題 → 挑戰層 2 題 → Boss 限時題 → 段考層選擇題（讀 QuizManager 題庫）

signal level_cleared(stars: int)

# 共用元件（需與本檔放在同一個資料夾）
const UITheme := preload("game_theme.gd")
const MathLabel := preload("math_text.gd")
const Game := preload("game.gd")
const PauseMenu := preload("pause_menu.gd")

const EPS := 1e-6
const ZONE_NAMES := ["< 0", "0 ~ 1", "> 1"]
## 棋盤左上角的小徽章（一般題目不顯示）
const LAYER_BADGE := {"boss": "限時挑戰"}

var rounds: Array = []
var round_index := 0
var phase := "rounds"          # rounds → exam → done
var towers: Array = []         # 目前這題的塔 {label, value, why}
var zone_choice: Array = []    # 每座塔選的區，-1 = 還沒選
var order_groups: Array = []   # 學生排的順序，例：[[2], [0, 1]] 表示 2 < 0 = 1
var eq_pending := false
var step := 1                  # 1 = 分區、2 = 排序、0 = 其他（揭曉、段考、結算）
var zone_fails := 0            # 這題「確認分區」失敗的次數
var busy := false
var time_left := 0.0
var score := 0
var combo := 0
var correct_count := 0
var exam_questions: Array = []
var exam_index := 0

# UI
var pause_menu: CanvasLayer
var status_label: Label
var combo_label: Label
var score_label: Label
var hint_panel: PanelContainer
var view: TowerView
var step_label: MathLabel
var confirm_btn: Button
var sort_row: HBoxContainer
var cards_box: VBoxContainer
var order_label: MathLabel
var hint_label: MathLabel
var eq_btn: Button
var reset_btn: Button
var submit_btn: Button
var next_btn: Button
var zone_buttons: Array = []
var pick_buttons: Array = []


# ================= 題目資料 =================

static func lg(b: float, x: float) -> float:
	return log(x) / log(b)


func _make_rounds() -> Array:
	return [
		{"layer": "explore",
		 "tip": "三個數剛好落在三個不同區，分好區就排好了！這就是比大小的「三分法」。",
		 "towers": [
			{"label": "2^{0.3}", "value": pow(2.0, 0.3), "why": "底數 2 > 1、指數 0.3 > 0，所以大於 1"},
			{"label": "0.3^{2}", "value": pow(0.3, 2.0), "why": "0.3 × 0.3 = 0.09，介於 0 和 1"},
			{"label": "log_{2} 0.3", "value": lg(2, 0.3), "why": "底數 2 > 1、真數 0.3 < 1，所以小於 0"},
		]},
		{"layer": "explore",
		 "tip": "估範圍：1 < log_{3} 5 < 2；(1/2)^{−2} = 4。",
		 "towers": [
			{"label": "3^{−1}", "value": 1.0 / 3.0, "why": "負指數就是倒數：3^{−1} = 1/3"},
			{"label": "log_{3} 5", "value": lg(3, 5), "why": "3 < 5 < 9，所以 1 < log_{3} 5 < 2"},
			{"label": "(1/2)^{−2}", "value": 4.0, "why": "(1/2)^{−2} = 2^{2} = 4"},
		]},
		{"layer": "challenge",
		 "tip": "log_{4} 9 = log_{2} 3：一樣高，用「＝」並列！",
		 "towers": [
			{"label": "log_{2} 3", "value": lg(2, 3), "why": "底數 2 > 1、真數 3 > 底數，所以大於 1"},
			{"label": "log_{3} 2", "value": lg(3, 2), "why": "1 < 真數 2 < 底數 3，所以介於 0 和 1"},
			{"label": "log_{4} 9", "value": lg(4, 9), "why": "log_{4} 9 = log_{2} 3，大於 1"},
		]},
		{"layer": "challenge",
		 "tip": "底數 0.5 < 1 遞減：0.5^{0.6} < 0.5^{0.3}。",
		 "towers": [
			{"label": "0.5^{0.3}", "value": pow(0.5, 0.3), "why": "底數 0.5 < 1、指數 > 0，介於 0 和 1"},
			{"label": "0.5^{0.6}", "value": pow(0.5, 0.6), "why": "底數 0.5 < 1、指數 > 0，介於 0 和 1"},
			{"label": "log_{0.5} 3", "value": lg(0.5, 3), "why": "底數 < 1、真數 > 1，所以小於 0"},
		]},
		{"layer": "boss", "time": 160.0,
		 "tip": "同取 12 次方：16 < 27，所以 3^{1/4} 較大。",
		 "towers": [
			{"label": "2^{1/3}", "value": pow(2.0, 1.0 / 3.0), "why": "底數 > 1、指數 > 0，大於 1"},
			{"label": "3^{1/4}", "value": pow(3.0, 0.25), "why": "底數 > 1、指數 > 0，大於 1"},
			{"label": "log_{2} 0.5", "value": -1.0, "why": "0.5 = 2^{−1}，所以等於 −1"},
			{"label": "log 2", "value": lg(10, 2), "why": "1 < 2 < 10，所以 0 < log 2 < 1"},
		]},
	]


# ================= 初始化 =================

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.shared()   # 與第 1 關共用的視覺主題
	Game.of(self)
	_build_ui()
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	rounds = _make_rounds()
	_start_round()


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(cb)
	return b


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 上方標題列
	var top := HBoxContainer.new()
	top.position = Vector2(24, 12)
	top.custom_minimum_size = Vector2(1104, 48)
	top.add_theme_constant_override("separation", 16)
	add_child(top)
	var title := Label.new()
	title.text = "高塔排序"
	title.add_theme_font_size_override("font_size", UITheme.fs(24))
	title.add_theme_color_override("font_color", UITheme.ACCENT)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", UITheme.fs(20))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(status_label)
	combo_label = Label.new()
	combo_label.add_theme_font_size_override("font_size", UITheme.fs(17))
	combo_label.add_theme_color_override("font_color", UITheme.PINK)
	combo_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(combo_label)
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", UITheme.fs(24))
	score_label.add_theme_color_override("font_color", UITheme.ACCENT)
	score_label.custom_minimum_size = Vector2(84, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(score_label)
	var pb := UITheme.round_button("pause", 44)
	pb.tooltip_text = "暫停（Esc）"
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pb.pressed.connect(func(): pause_menu.open())
	top.add_child(pb)

	view = TowerView.new()
	view.position = Vector2(24, 70)
	view.size = Vector2(600, 556)
	add_child(view)

	var card := PanelContainer.new()
	card.position = Vector2(644, 70)
	card.custom_minimum_size = Vector2(484, 556)
	add_child(card)
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 12)
	card.add_child(panel)

	step_label = MathLabel.new()
	step_label.max_width = 448
	step_label.font_size = UITheme.fs(17)
	panel.add_child(step_label)

	cards_box = VBoxContainer.new()
	cards_box.add_theme_constant_override("separation", 8)
	panel.add_child(cards_box)

	# 步驟 1 的按鈕
	confirm_btn = _btn("確認分區", _on_confirm_zones)
	confirm_btn.custom_minimum_size = Vector2(0, 50)
	UITheme.accent_button(confirm_btn, 19)
	panel.add_child(confirm_btn)

	# 步驟 2 的元件
	order_label = MathLabel.new()
	order_label.font_size = UITheme.fs(20)
	order_label.max_width = 448
	panel.add_child(order_label)

	sort_row = HBoxContainer.new()
	sort_row.add_theme_constant_override("separation", 8)
	eq_btn = _btn("＝ 一樣高", _on_eq)
	reset_btn = _btn("重排", _on_reset_order)
	submit_btn = _btn("送出排序", _on_submit)
	UITheme.accent_button(submit_btn, 19)
	submit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for b in [eq_btn, reset_btn, submit_btn]:
		b.custom_minimum_size.y = 50
		sort_row.add_child(b)
	eq_btn.custom_minimum_size.x = 120
	reset_btn.custom_minimum_size.x = 84
	panel.add_child(sort_row)

	hint_panel = PanelContainer.new()
	hint_label = MathLabel.new()
	hint_label.max_width = 420
	hint_label.font_size = UITheme.fs(15)
	hint_panel.add_child(hint_label)
	panel.add_child(hint_panel)

	next_btn = _btn("下一題  ▶", _on_next)
	next_btn.custom_minimum_size = Vector2(0, 50)
	UITheme.accent_button(next_btn, 19)
	panel.add_child(next_btn)


## 回饋框：info 藍、good 綠、bad 紅；text 空白時隱藏
func _hint(text: String, kind: String = "info") -> void:
	hint_panel.visible = text != ""
	var c := {"info": UITheme.CYAN, "good": UITheme.GOOD, "bad": UITheme.BAD}[kind] as Color
	hint_panel.add_theme_stylebox_override("panel",
		UITheme.box(Color(c.r, c.g, c.b, 0.10), 12, Color(c.r, c.g, c.b, 0.55), 1, 12))
	hint_label.text = text


# ================= 一題的流程 =================

func _start_round() -> void:
	var r: Dictionary = rounds[round_index]
	busy = false
	towers = r.towers.duplicate()
	towers.shuffle()
	zone_choice = []
	zone_choice.resize(towers.size())
	zone_choice.fill(-1)
	order_groups = []
	eq_pending = false
	zone_fails = 0
	time_left = r.get("time", 0.0)
	_build_cards()
	view.waiting = towers
	_show_step(1)
	next_btn.visible = false
	view.message = LAYER_BADGE.get(r.layer, "")
	_hint("")
	_refresh_order()
	_update_status()


func _build_cards() -> void:
	_clear_cards()
	zone_buttons = []
	pick_buttons = []
	for i in towers.size():
		var row := HBoxContainer.new()
		var pick := MathLabel.make_button(towers[i].label, 22, Vector2(150, 48))
		pick.pressed.connect(_on_pick.bind(i))
		pick.disabled = true   # 步驟 2 才能點來排序
		row.add_child(pick)
		pick_buttons.append(pick)
		var group := ButtonGroup.new()
		var zb := []
		for z in 3:
			var b := Button.new()
			b.text = ZONE_NAMES[z]
			b.toggle_mode = true
			b.button_group = group
			b.custom_minimum_size = Vector2(88, 48)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(_on_zone.bind(i, z))
			row.add_child(b)
			zb.append(b)
		zone_buttons.append(zb)
		cards_box.add_child(row)


func _clear_cards() -> void:
	for c in cards_box.get_children():
		cards_box.remove_child(c)
		c.queue_free()


## 只顯示目前步驟需要的元件
func _show_step(s: int) -> void:
	step = s
	confirm_btn.visible = s == 1
	confirm_btn.disabled = zone_choice.has(-1)
	order_label.visible = s == 2
	sort_row.visible = s == 2
	for b in [eq_btn, reset_btn, submit_btn]:
		b.disabled = false
	step_label.visible = s != 0
	if s == 1:
		step_label.text = UITheme.step_bar(["分區", "排序"], 0) \
			+ "\n每座塔是 < 0、0 ~ 1 還是 > 1？"
	elif s == 2:
		step_label.text = UITheme.step_bar(["分區", "排序"], 1) \
			+ "\n由低到高點塔名；一樣高的先按「＝」。"


static func _zone(v: float) -> int:
	if v < 0.0:
		return 0
	if v < 1.0:
		return 1
	return 2


func _on_zone(i: int, z: int) -> void:
	if busy or step != 1:
		return
	zone_choice[i] = z
	confirm_btn.disabled = zone_choice.has(-1)
	for b in zone_buttons[i]:
		b.modulate = Color.WHITE
	if rounds[round_index].layer == "explore":
		var right := _zone(towers[i].value) == z
		zone_buttons[i][z].modulate = Color(0.55, 1.0, 0.55) if right else Color(1.0, 0.5, 0.5)
		if right:
			_hint("✓ %s 放對了！" % towers[i].label, "good")
			Game.of(self).play("bell", Game.semi(12), -10.0)
		else:
			_hint("✗ %s 不在這一區。\n%s" % [towers[i].label, towers[i].why], "bad")
			Game.of(self).sfx("wrong")
			_record("compare_split")


## 步驟 1 → 2：分區全對才進入排序；分錯的標紅、清掉，讓學生重選
func _on_confirm_zones() -> void:
	if busy or step != 1:
		return
	if zone_choice.has(-1):
		_hint("還有塔沒有分區喔！", "bad")
		return
	var wrong := []
	for i in towers.size():
		if zone_choice[i] != _zone(towers[i].value):
			wrong.append(i)
	if wrong.is_empty():
		_enter_step2()
		return

	zone_fails += 1
	Game.of(self).sfx("wrong")
	_record("compare_split")
	var show_why: bool = rounds[round_index].layer == "explore" or zone_fails >= 2
	var lines := PackedStringArray()
	lines.append("✗ 有 %d 座塔分錯區了（紅色）。" % wrong.size())
	var shown := 0
	for i in wrong:
		var b: Button = zone_buttons[i][zone_choice[i]]
		b.button_pressed = false
		b.modulate = Color(1.0, 0.5, 0.5)
		zone_choice[i] = -1
		if show_why and shown < 2:      # 一次最多解釋兩座，避免回饋太長
			lines.append("・%s：%s" % [towers[i].label, towers[i].why])
			shown += 1
	if not show_why:
		lines.append("問自己：它跟 0 比、跟 1 比，是大還是小？")
	_hint("\n".join(lines), "bad")
	confirm_btn.disabled = true


func _enter_step2() -> void:
	for i in towers.size():
		for z in 3:
			var b: Button = zone_buttons[i][z]
			b.disabled = true
			b.visible = z == zone_choice[i]   # 只留下選定的那一區
			b.modulate = Color.WHITE
			if z == zone_choice[i]:
				# 綠色徽章：清楚標示已確認的區域
				var g := UITheme.GOOD
				b.add_theme_stylebox_override("disabled", UITheme.box(Color(g.r, g.g, g.b, 0.16), 12, g, 1, 10))
				b.add_theme_color_override("font_disabled_color", g)
				b.text = "✓ " + ZONE_NAMES[z]
		pick_buttons[i].disabled = false
	_show_step(2)
	Game.of(self).sfx("correct")
	_hint("分區正確！只要比較同一區裡的塔。", "good")
	_refresh_order()


func _on_pick(i: int) -> void:
	if busy or step != 2:
		return
	if eq_pending and not order_groups.is_empty():
		order_groups.back().append(i)
	else:
		order_groups.append([i])
	eq_pending = false
	pick_buttons[i].disabled = true
	pick_buttons[i].modulate = Color(1, 1, 1, 0.4)
	_refresh_order()


func _on_eq() -> void:
	if busy or step != 2:
		return
	if order_groups.is_empty():
		_hint("先點一座塔，再按「＝」，接著點跟它一樣高的那座。", "info")
		return
	eq_pending = true
	_refresh_order()


func _on_reset_order() -> void:
	if busy or step != 2:
		return
	order_groups = []
	eq_pending = false
	for b in pick_buttons:
		b.disabled = false
		b.modulate = Color.WHITE
	_refresh_order()


func _refresh_order() -> void:
	var t := "由低到高：" + (_groups_text(order_groups) if not order_groups.is_empty() else "[color=#9aa3c7]點上方的塔名[/color]")
	if eq_pending:
		t += " = ?"
	order_label.text = t
	view.show_preview(towers, order_groups)


func _groups_text(groups: Array) -> String:
	var parts := PackedStringArray()
	for g in groups:
		var names := PackedStringArray()
		for i in g:
			names.append(towers[i].label)
		parts.append(" = ".join(names))
	return " < ".join(parts)


func _picked_count() -> int:
	var n := 0
	for g in order_groups:
		n += g.size()
	return n


func _on_submit() -> void:
	if busy or step != 2:
		return
	if _picked_count() < towers.size():
		_hint("還有塔沒有排進順序喔！", "bad")
		return

	var order_ok := _check_order()
	busy = true
	_show_step(0)
	_hint("")
	_play_towers()
	await view.reveal(towers, order_groups)

	var r: Dictionary = rounds[round_index]
	if order_ok:
		correct_count += 1
		var gain := 50
		var note := ""
		if zone_fails == 0:
			combo += 1
			gain = int(100 * (1.0 + 0.5 * (combo - 1)))
			note = "　連擊 ×%d" % combo if combo >= 2 else ""
		else:
			combo = 0
		if r.layer == "boss":
			gain += int(time_left) * 2   # 剩餘時間加分
		score += gain
		Game.of(self).sfx("success")
		_hint("✓ 排序正確！+%d%s\n\n%s" % [gain, note, r.tip], "good")
	else:
		combo = 0
		Game.of(self).sfx("wrong")
		_record("compare_base")
		var lines := PackedStringArray()
		lines.append("✗ 順序有誤：哪裡沒有一路升高？")
		lines.append("")
		lines.append("解法：" + r.tip)
		lines.append("正確順序：" + _groups_text(_true_groups()))
		_hint("\n".join(lines), "bad")
	_update_status()
	next_btn.visible = true


func _show_zone_answers() -> void:
	for i in towers.size():
		for b in zone_buttons[i]:
			b.modulate = Color.WHITE
			b.disabled = true
			b.visible = true
		zone_buttons[i][_zone(towers[i].value)].modulate = Color(0.55, 1.0, 0.55)


## 塔升起時，依學生排的順序、照每座塔的高度彈出音階（排對就是一路往上的旋律）
func _play_towers() -> void:
	var lo := INF
	var hi := -INF
	for t in towers:
		lo = minf(lo, t.value)
		hi = maxf(hi, t.value)
	var k := 0
	for g in order_groups:
		for i in g:
			var u: float = 0.5 if hi - lo < 1e-6 else (towers[i].value - lo) / (hi - lo)
			Game.of(self).play("bell", Game.semi(Game.scale_semi(2 + roundi(u * 8.0)) - 12), -6.0, 0.18 + 0.16 * k)
			k += 1


## 檢查學生的順序：同組必須相等，組與組之間必須嚴格遞增
func _check_order() -> bool:
	for g in order_groups:
		for i in g:
			if absf(towers[i].value - towers[g[0]].value) > EPS:
				return false
	for k in range(1, order_groups.size()):
		if towers[order_groups[k][0]].value <= towers[order_groups[k - 1][0]].value + EPS:
			return false
	return true


func _true_groups() -> Array:
	var idx := range(towers.size())
	idx.sort_custom(func(a, b): return towers[a].value < towers[b].value)
	var groups := []
	for i in idx:
		if not groups.is_empty() and absf(towers[i].value - towers[groups.back()[0]].value) < EPS:
			groups.back().append(i)
		else:
			groups.append([i])
	return groups


func _process(delta: float) -> void:
	if phase != "rounds" or busy or rounds.is_empty():
		return
	if rounds[round_index].layer != "boss":
		return
	time_left -= delta
	_update_status()
	if time_left <= 0.0:
		_on_timeout()


func _on_timeout() -> void:
	busy = true
	combo = 0
	time_left = 0.0
	_show_step(0)
	_show_zone_answers()
	order_groups = _true_groups()
	Game.of(self).sfx("wrong")
	await view.reveal(towers, order_groups)
	_hint("時間到！這是正確的高度。\n\n解法：" + rounds[round_index].tip, "info")
	_update_status()
	next_btn.visible = true


func _on_next() -> void:
	next_btn.visible = false
	if phase == "rounds":
		round_index += 1
		if round_index < rounds.size():
			_start_round()
		else:
			_start_exam()
	elif phase == "exam":
		exam_index += 1
		if exam_index < exam_questions.size():
			_show_question()
		else:
			_finish()


func _update_status() -> void:
	var t := ""
	if phase == "rounds":
		t = "第 %d / %d 題" % [round_index + 1, rounds.size()]
		if rounds[round_index].layer == "boss":
			t += "　◷ %d 秒" % ceili(maxf(time_left, 0.0))
	elif phase == "exam":
		t = "段考練習 %d / %d" % [exam_index + 1, exam_questions.size()]
	status_label.text = t
	combo_label.text = "連擊 ×%d" % combo if combo >= 2 else ""
	score_label.text = "✦ %d" % score


# ================= 段考層（選擇題） =================

func _start_exam() -> void:
	phase = "exam"
	var qm = get_node_or_null("/root/QuizManager")
	if qm:
		exam_questions = qm.get_questions_for_level(4, "exam")
	if exam_questions.is_empty():
		_finish()
		return
	exam_index = 0
	_show_step(0)
	view.message = "段考練習"
	view.waiting = []
	view.show_preview([], [])
	_show_question()


func _show_question() -> void:
	busy = false
	_clear_cards()
	var q: Dictionary = exam_questions[exam_index]
	var stem := MathLabel.new()
	stem.text = q.stem
	stem.max_width = 448
	stem.font_size = UITheme.fs(20)
	cards_box.add_child(stem)
	for k in q.options.size():
		var b := MathLabel.make_button("(%d)  %s" % [k + 1, q.options[k]], 18, Vector2(448, 48), false)
		b.set_meta("silent", true)
		b.pressed.connect(_on_answer.bind(k))
		cards_box.add_child(b)
	_hint("")
	_update_status()


func _on_answer(k: int) -> void:
	if busy:
		return
	busy = true
	var q: Dictionary = exam_questions[exam_index]
	var result: Dictionary = get_node("/root/QuizManager").grade(q, [k])
	var answers: Array = q.answer.map(func(v): return int(v))
	var buttons := cards_box.get_children().slice(1)  # 第 0 個是題幹
	for j in buttons.size():
		var b = buttons[j]
		b.disabled = true
		if answers.has(j):
			b.modulate = Color(0.55, 1.0, 0.55)
		elif j == k:
			b.modulate = Color(1.0, 0.5, 0.5)
	if result.correct:
		score += 100
		correct_count += 1
		Game.of(self).sfx("correct")
		_hint("✓ 正確！+100\n\n" + result.explain, "good")
	else:
		Game.of(self).sfx("wrong")
		_hint("✗ 再想想。\n\n" + result.explain, "bad")
	_update_status()
	next_btn.visible = true


# ================= 結算 =================

func _finish() -> void:
	phase = "done"
	busy = true
	_show_step(0)
	_clear_cards()
	_hint("")
	var total := rounds.size() + exam_questions.size()
	var ratio := float(correct_count) / total
	var stars := 3 if ratio >= 0.85 else (2 if ratio >= 0.6 else 1)
	var g = Game.of(self)
	g.record_stars("L3", stars)
	g.sfx("fanfare")
	var o := UITheme.modal(self, UITheme.ACCENT, 460)
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(UITheme.title_label("高塔排序．完成！", 32, UITheme.ACCENT))
	var big := UITheme.title_label("★".repeat(stars) + "☆".repeat(3 - stars), 60, UITheme.ACCENT)
	big.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.1, 0.5))
	big.add_theme_constant_override("shadow_offset_x", 0)
	big.add_theme_constant_override("shadow_offset_y", 4)
	col.add_child(big)
	col.add_child(UITheme.title_label("答對 %d / %d　·　總分 %d" % [correct_count, total, score], 17, UITheme.TEXT))
	var qm = get_node_or_null("/root/QuizManager")
	if qm:
		var weak: Array = qm.weakest(2)
		if not weak.is_empty():
			var names := PackedStringArray()
			for w in weak:
				names.append(w.name)
			var wl := UITheme.title_label("可以再加強\n" + "、".join(names), 15, UITheme.TEXT_DIM)
			wl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
			wl.custom_minimum_size = Vector2(400, 0)
			col.add_child(wl)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	col.add_child(gap)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var home := Button.new()
	home.text = "返回關卡列表"
	home.custom_minimum_size = Vector2(0, 52)
	home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.add_theme_font_size_override("font_size", UITheme.fs(17))
	home.pressed.connect(func(): Game.of(self).goto("main_menu.gd", {"page": "levels"}))
	row.add_child(home)
	var again := Button.new()
	again.text = "再挑戰一次"
	again.custom_minimum_size = Vector2(0, 52)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.accent_button(again, 19)
	again.pressed.connect(func(): Game.of(self).goto("level_04_tower_sort.gd"))
	row.add_child(again)
	_update_status()
	level_cleared.emit(stars)


func _record(tag: String) -> void:
	var qm = get_node_or_null("/root/QuizManager")
	if qm:
		qm.record_mistake(tag)


# ================= 塔的繪圖 =================

class TowerView extends Control:
	var towers: Array = []
	var groups: Array = []
	var waiting: Array = []      # 還沒排進順序的塔：只在底部列出名字
	var message := ""
	var progress := 0.0:
		set(v):
			progress = v
			queue_redraw()
	var lo := -2.0
	var hi := 2.0
	const TOP := 40.0
	const BOTTOM := 56.0

	func show_preview(t: Array, g: Array) -> void:
		towers = t
		groups = g
		progress = 0.0
		queue_redraw()

	## 依學生排的順序把塔升起來（TRANS_BACK 會有一點「彈」的效果）
	func reveal(t: Array, g: Array) -> void:
		towers = t
		groups = g
		var tw := create_tween()
		tw.tween_property(self, "progress", 1.0, 1.2).from(0.0) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw.finished

	func _y(v: float) -> float:
		return TOP + (hi - v) / (hi - lo) * (size.y - TOP - BOTTOM)

	const ZONE_COLS := [Color("ff9a6b"), UITheme.GOOD, UITheme.BLUE]

	func _draw() -> void:
		var font := get_theme_default_font()
		var w := size.x
		var hh := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, hh), Vector2(0, hh)]),
			PackedColorArray([Color("1b1650"), Color("1b1650"), Color("0b2a3f"), Color("0b2a3f")]))
		lo = -2.0
		hi = 2.0
		for t in towers:
			lo = minf(lo, t.value - 0.4)
			hi = maxf(hi, t.value + 0.4)

		# 三個區域：淡淡的底色 + 右側名稱
		var right := w - 14.0
		var zc: Array = ZONE_COLS
		draw_rect(Rect2(0, _y(0), w, _y(lo) - _y(0)), Color(zc[0].r, zc[0].g, zc[0].b, 0.07))
		draw_rect(Rect2(0, _y(1), w, _y(0) - _y(1)), Color(zc[1].r, zc[1].g, zc[1].b, 0.08))
		draw_rect(Rect2(0, _y(hi), w, _y(1) - _y(hi)), Color(zc[2].r, zc[2].g, zc[2].b, 0.07))
		draw_string(font, Vector2(right - 140, _y(lo) - 10), "地底  < 0", HORIZONTAL_ALIGNMENT_RIGHT, 140, UITheme.fs(15),
			Color(zc[0].r, zc[0].g, zc[0].b, 0.85))
		draw_string(font, Vector2(right - 140, _y(0) - 10), "地面層  0 ~ 1", HORIZONTAL_ALIGNMENT_RIGHT, 140, UITheme.fs(15),
			Color(zc[1].r, zc[1].g, zc[1].b, 0.85))
		draw_string(font, Vector2(right - 140, _y(hi) + 22), "高空  > 1", HORIZONTAL_ALIGNMENT_RIGHT, 140, UITheme.fs(15),
			Color(zc[2].r, zc[2].g, zc[2].b, 0.85))
		draw_line(Vector2(0, _y(0)), Vector2(w, _y(0)), Color(1, 1, 1, 0.75), 2.0)
		draw_dashed_line(Vector2(0, _y(1)), Vector2(w, _y(1)), Color(1, 1, 1, 0.45), 1.5, 8.0)
		draw_string(font, Vector2(10, _y(0) - 6), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color.WHITE)
		draw_string(font, Vector2(10, _y(1) - 6), "1", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color.WHITE)

		if message != "":
			var mw := font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15)).x + 24.0
			var pc := UITheme.GOLD
			draw_style_box(UITheme.boxc(Color(pc.r, pc.g, pc.b, 0.16), 14, Color(pc.r, pc.g, pc.b, 0.6), 1, 0),
				Rect2(12, 12, mw, 28))
			draw_string(font, Vector2(24, 31), message, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), pc)

		if groups.is_empty() and not waiting.is_empty():
			var nw := waiting.size()
			var sw := (w - 36.0 - 150.0) / nw
			for k in nw:
				var cx := 36.0 + sw * (k + 0.5)
				MathLabel.draw_on(self, font, cx, size.y - 20.0, waiting[k].label, UITheme.fs(17), Color(1, 1, 1, 0.75))
		if not towers.is_empty():
			var n := towers.size()
			var left := 36.0
			var slot := (w - left - 150.0) / n
			var tw := slot * 0.56
			var pos := 0
			for g in groups:
				for k in g.size():
					var i: int = g[k]
					_draw_tower(font, towers[i], left + pos * slot + (slot - tw) / 2.0, tw, slot, k > 0)
					pos += 1
		draw_style_box(UITheme.boxc(Color(0, 0, 0, 0), 4, Color(1, 1, 1, 0.10), 1, 0), Rect2(Vector2.ZERO, size))

	## 一座塔：揭曉前是所屬區域的虛框與問號；揭曉後是發光的水晶柱
	func _draw_tower(font: Font, t: Dictionary, x: float, tw: float, slot: float, eq_mark: bool) -> void:
		var col: Color = ZONE_COLS[_zone_of(t.value)]
		if progress <= 0.0:
			var zt := _zone_of(t.value)
			var by0 := _y(0) + 8.0
			var by1 := by0 + 56.0
			if zt == 2:
				by1 = _y(1) - 8.0
				by0 = by1 - 56.0
			elif zt == 1:
				by0 = _y(1) + 6.0
				by1 = _y(0) - 6.0
			draw_style_box(UITheme.boxc(Color(col.r, col.g, col.b, 0.08), 8, Color(col.r, col.g, col.b, 0.5), 2, 0),
				Rect2(x, by0, tw, by1 - by0))
			draw_string(font, Vector2(x, (by0 + by1) / 2.0 + 9.0), "?", HORIZONTAL_ALIGNMENT_CENTER, tw, UITheme.fs(24), Color(1, 1, 1, 0.7))
		else:
			var v: float = t.value * progress
			var top_y := minf(_y(v), _y(0))
			var h := maxf(absf(_y(v) - _y(0)), 2.0)
			var rect := Rect2(x, top_y, tw, h)
			draw_rect(rect.grow(6.0), Color(col.r, col.g, col.b, 0.10))
			var bright := col.lightened(0.25)
			var deep := col.darkened(0.35)
			var cols := PackedColorArray([bright, bright, deep, deep]) if v >= 0.0 else PackedColorArray([deep, deep, bright, bright])
			draw_polygon(PackedVector2Array([rect.position, rect.position + Vector2(tw, 0), rect.end,
				rect.position + Vector2(0, h)]), cols)
			draw_rect(Rect2(x + tw * 0.14, top_y, tw * 0.12, h), Color(1, 1, 1, 0.22))
			var cap_y := top_y if v >= 0.0 else top_y + h
			draw_line(Vector2(x, cap_y), Vector2(x + tw, cap_y), Color(1, 1, 1, 0.85), 2.0)
			if progress >= 0.99:
				var vy := _y(t.value) - 10.0 if t.value >= 0.0 else _y(t.value) + 22.0
				draw_string(font, Vector2(x - 20, vy), "%.3f" % t.value, HORIZONTAL_ALIGNMENT_CENTER, tw + 40, UITheme.fs(15), Color.WHITE)
		if eq_mark:
			draw_string(font, Vector2(x - slot + tw, _y(1) - 70), "=", HORIZONTAL_ALIGNMENT_CENTER, slot - tw, UITheme.fs(24), UITheme.GOLD)
		MathLabel.draw_on(self, font, x + tw / 2.0, size.y - 20.0, t.label, UITheme.fs(17), Color.WHITE)

	static func _zone_of(v: float) -> int:
		if v < 0.0:
			return 0
		if v < 1.0:
			return 1
		return 2
