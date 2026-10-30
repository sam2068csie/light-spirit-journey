extends "level_01_light_bridge.gd"
## 通用的「步驟推導」關卡引擎（所有單元共用）
## 指數與對數的 L2～L8、之後的平面向量、空間向量…都繼承它，只要寫題庫和關卡資訊。
##
## 怎麼做一個新關卡（例如平面向量第一關 V1）：
##   extends "step_level.gd"
##   func level_id() -> String: return "V1"            ← 和 units.gd 裡的 id 一樣
##   func level_title() / level_subtitle() / level_chapters() / bank_slots() / chapter_card() / stage_style()
##   題庫用 step_bank.gd 的小工具寫（choice、fill、filter、order、forge…），不用自己拼字典。
##
## 旅程種類（r.type）：
##   forge  一步一步推導。每一步（steps 裡的一個字典，kind 決定作法）：
##            choice  選擇題            fill    數字鍵盤填空（整數、分數、負數；可多格）
##            filter  篩掉不合的候選值    order   由小到大排序
##          答對的步驟寫進左邊的「推導紀錄」（line），最後是一份完整的計算過程。
##          步驟的 pre：開始這一步之前先寫進紀錄的已知條件。
##   speed  速算爐：限時連續填答。子類別覆寫 _speed_gen() 產生題目、_speed_tag() 給觀念標籤。
##   tune   參數調頻：拖動參數，看圖形的變化，再回答範圍題（目前的圖是 t 的拋物線，給指數換元用）。
## 想加新的步驟種類：覆寫 _forge_step()（先 super()，再處理自己的 kind）、_custom_go()、_custom_reveal()。
## 也可以用實體鍵盤輸入：數字、−、/、Backspace、Enter（送出）、Tab（下一格）。

const FIRE := UITheme.ORANGE

var fview: ForgeView
# 開場動畫：題目逐字出現，出現完才顯示右邊的引導作答區
var intro_tw: Tween
var intro_block: Control

# 鍛造
var steps: Array = []
var si := 0
var mistakes := 0
# 數字鍵盤填空
var keypad_on := false
var fill_step: Dictionary = {}
var fill_tpl := ""          # 顯示用的填空模板（太寬時已經換行）
var slot_vals: Array = []
var slot_bad: Array = []
var cur_slot := 0
var fill_preview: MathLabel
var slot_btns: Array = []
# 篩選
var filter_keep: Array = []
var filter_btns: Array = []
# 速算
var problems: Array = []
var sp_i := 0
var sp_wrong := 0
var streak := 0
# 調頻
var tp := 0.0
var tune_slider: HSlider
var tune_val: Label
var tune_last := -1
var tune_phase := 0          # 0 調頻任務、1 計算步驟（判別式、根與係數…）、2 最後的範圍題


# 排序
var order_seq: Array = []
var order_btns: Array = []
var order_preview: MathLabel


## 這一關的主題色（排序卡片等）。子類別可以覆寫
func step_color() -> Color:
	return FIRE


## 選單打開時，舞台只畫背景（不要露出第一大關的曲線）
func _show_menu() -> void:
	stage.plain = true
	stage.type = "plain"
	super()


func _custom_type(t: String) -> bool:
	return t == "forge" or t == "speed" or t == "tune"


func _ensure_fview() -> void:
	if fview == null:
		fview = ForgeView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true


func _start_round() -> void:
	_intro_cancel()
	super()


## 開場：左邊的題目一個字一個字浮現，右邊的作答區先藏起來（點畫面可以跳過）
func _intro_begin() -> void:
	_intro_cancel()
	var total := fview.intro_total()
	if total <= 0.0:
		return
	fview.intro = 0.0
	side_card.modulate.a = 0.0
	intro_block = Control.new()
	intro_block.position = stage.position
	intro_block.size = Vector2(side_card.position.x + side_card.size.x - stage.position.x, stage.size.y)
	intro_block.mouse_filter = Control.MOUSE_FILTER_STOP
	intro_block.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_intro_finish())
	add_child(intro_block)
	var skip := Label.new()
	skip.text = "點一下畫面可以跳過  ▸▸"
	skip.add_theme_font_size_override("font_size", UITheme.fs(13))
	skip.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	skip.position = Vector2(stage.size.x - 190, stage.size.y - 30)
	intro_block.add_child(skip)
	var dur := clampf(total / 14.0, 1.0, 4.5)   # 大約一秒 14 個字，讓學生跟著讀
	var last := [0]
	intro_tw = create_tween()
	intro_tw.tween_method(func(v: float):
		if fview == null:
			return
		fview.intro = v
		fview.queue_redraw()
		if int(v) >= last[0] + 3:
			last[0] = int(v)
			Game.of(self).play("blip", 1.5 + 0.2 * randf(), -24.0), 0.0, total, dur)
	intro_tw.tween_interval(0.3)
	intro_tw.tween_callback(_intro_finish)


func _intro_finish() -> void:
	if intro_block == null:
		return
	if intro_tw != null:
		intro_tw.kill()
		intro_tw = null
	intro_block.queue_free()
	intro_block = null
	if fview != null:
		fview.intro = -1.0
		fview.queue_redraw()
	# 右邊作答區滑進來
	var x0 := 744.0
	side_card.position.x = x0 + 30.0
	side_card.modulate.a = 0.0
	var tw := side_card.create_tween().set_parallel(true)
	tw.tween_property(side_card, "modulate:a", 1.0, 0.3)
	tw.tween_property(side_card, "position:x", x0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	Game.of(self).play("blip", 1.2, -12.0)


func _intro_cancel() -> void:
	if intro_tw != null:
		intro_tw.kill()
		intro_tw = null
	if intro_block != null:
		intro_block.queue_free()
		intro_block = null
	if fview != null:
		fview.intro = -1.0
	if side_card != null:
		side_card.modulate.a = 1.0
		side_card.position.x = 744.0


func _custom_start() -> void:
	_ensure_fview()
	_ensure_log_drag()
	fview.setup(r)
	pre_done = {}
	mistakes = 0
	predicting = false
	_clear(predict_box)       # 上一段旅程留下的選擇題（例如能量用完時）
	keypad_on = false
	story_label.visible = true
	formula_label.visible = false
	sliders_box.visible = false
	energy_label.visible = true
	go_btn.visible = false
	alt_btn.visible = false
	match r.type:
		"forge":
			steps = r.steps
			si = 0
			_forge_step()
			_intro_begin()
		"speed":
			_speed_begin()
		"tune":
			_tune_begin()
			_intro_begin()
	_update_hud()


func _custom_steps() -> Array:
	match r.type:
		"forge":
			return r.steps.map(func(st): return st.name)
		"speed":
			return ["連續速算", "結算"]
	var names := ["調頻任務"]
	for st in r.get("steps", []):
		names.append(st.name)
	names.append("判斷範圍")
	return names


func _custom_step_index() -> int:
	match r.type:
		"forge":
			return si
		"tune":
			return 0 if tune_phase == 0 else (1 + si if tune_phase == 1 else _custom_steps().size() - 1)
	return 0


func _update_hud() -> void:
	super()
	if r.is_empty():
		return
	if r.type == "speed":
		energy_label.text = "◷ %d 秒　　連對 ×%d" % [ceili(time_left), streak]
	elif _hearts_in_step():
		# 鍛造步驟：能量放到步驟列右邊，把空間留給鍵盤和提示
		energy_label.visible = false
		if not busy:
			_step_text()


func _hearts_in_step() -> bool:
	return r.type == "forge" or (r.type == "tune" and tune_phase >= 1)


# ================= 鍛造 =================

func _forge_step() -> void:
	if si >= steps.size():
		_forge_done()
		return
	var st: Dictionary = steps[si]
	if si > 0:
		story_label.visible = false
	_push_pre(si)
	fview.cur_name = st.name
	fview.live_fill = ""
	fview.live_q = st.get("q", "")
	fview.step = si
	_step_text()
	match st.kind:
		"choice":
			rank_box.visible = false
			_show_question(shuffle_q({"q": st.q, "options": st.options, "correct": st.correct,
				"why": st.why, "nudge": st.nudge, "tag": st.tag}))
			_step_text()          # 步驟多的時候用精簡的進度列，免得換行
		"fill":
			_clear(predict_box)
			predicting = false
			_build_fill(st)
		"filter":
			_build_filter(st)
		"order":
			_clear(predict_box)
			predicting = false
			keypad_on = false
			rank_box.visible = true
			_clear(rank_box)
			task_label.visible = true
			task_label.text = st.q
			go_btn.visible = true
			go_btn.disabled = false
			_build_order(st)


## 步驟太多時只顯示「目前第幾步」，免得進度列換行把下面擠出畫面
func _step_text() -> void:
	var names := _steps()
	var si_ := mini(_custom_step_index(), names.size() - 1)
	# 名稱夠短才用完整的進度列，太長會換行（愛心被擠到第二行）
	var plain := "　".join(names) + ("　♥♥♥" if _hearts_in_step() else "")
	if names.size() <= 4 and ForgeView._mw(get_theme_default_font(), plain, 16) + 30.0 * names.size() <= 340.0:
		step_label.text = UITheme.step_bar(names, si_) + _hearts_text()
		return
	var dots := ""
	for i in names.size():
		var c := UITheme.GOOD if i < si_ else (UITheme.ACCENT if i == si_ else UITheme.TEXT_DIM)
		dots += "[color=#%s]%s[/color]" % [c.to_html(false), "●" if i <= si_ else "○"]
	step_label.text = "%s　[color=#%s]步驟 %d／%d：%s[/color]" % [dots, UITheme.ACCENT.to_html(false),
		si_ + 1, names.size(), names[si_]] + _hearts_text()


## 步驟列右邊的能量（有時間限制時也顯示秒數）
func _hearts_text() -> String:
	if not _hearts_in_step():
		return ""
	var hs := "♥".repeat(clampi(energy, 0, MAX_ENERGY)) + "♡".repeat(clampi(MAX_ENERGY - energy, 0, MAX_ENERGY))
	var tt := ("　◷ %d" % ceili(time_left)) if r.has("time") else ""
	return "　[color=#%s]%s%s[/color]" % [UITheme.PINK.to_html(false), hs, tt]


func _custom_answered() -> void:
	if r.type == "tune" and tune_phase == 2:
		var extra := mislocks + mistakes
		_finish_round(predict_tries == 1 and extra == 0, predict_tries + extra)
		return
	mistakes += predict_tries - 1
	_step_done(steps[si], cur_q.get("why", ""))


func _step_done(st: Dictionary, why: String) -> void:
	if st.kind == "filter":
		var rej := []
		for i in st.cands.size():
			if not st.keep[i]:
				rej.append(_to_f(st.cands[i]))
		fview.rejected = rej
	fview.live_fill = ""
	fview.push_line(st.line)
	si += 1
	fview.step = si
	if why != "":
		_hint("✓ " + why, "good")
	else:
		hint_panel.visible = false
	_forge_step()


func _forge_done() -> void:
	if r.type == "tune":
		_tune_final()
		return
	keypad_on = false
	_clear(rank_box)
	rank_box.visible = false
	go_btn.visible = false
	fview.finish()
	_finish_round(mistakes == 0, mistakes + 1)


func _custom_go() -> void:
	if r.type == "tune":
		_tune_lock()
	elif r.type == "forge" and si < steps.size() and steps[si].kind == "filter":
		_filter_submit()
	elif r.type == "forge" and si < steps.size() and steps[si].kind == "order":
		_order_submit()


## 這一步開始前先寫進推導紀錄的「已知」（例如「令 t = log_{3} x：2/t − t = 1」），只看中間也不會跳步
var pre_done := {}


func _push_pre(i: int) -> void:
	if pre_done.has(i) or i >= steps.size():
		return
	pre_done[i] = true
	var pre = steps[i].get("pre", [])
	if pre is String:
		pre = [pre]
	for ln in pre:
		fview.push_line(String(ln))


func _custom_reveal(msg: String) -> void:
	keypad_on = false
	_clear(rank_box)
	match r.type:
		"forge":
			for j in range(si, steps.size()):
				var st: Dictionary = steps[j]
				if st.kind == "filter":
					var rej := []
					for i in st.cands.size():
						if not st.keep[i]:
							rej.append(_to_f(st.cands[i]))
					fview.rejected = rej
				_push_pre(j)
				fview.push_line(st.line)
			si = steps.size()
			fview.step = si
			fview.finish()
			_hint(msg + " 完整的過程已經寫在左邊了。\n\n" + r.insight, "info")
		_:
			if r.type == "tune":
				var all_st: Array = r.get("steps", [])
				var from := si if tune_phase == 1 else (0 if tune_phase == 0 else all_st.size())
				for j in range(from, all_st.size()):
					fview.push_line(all_st[j].line)
				fview.tune_calc = true
				fview.mouse_filter = Control.MOUSE_FILTER_STOP
				_tune_calc_range()
			_hint(msg + "\n\n" + r.insight, "info")
	_end_round()


func _custom_timeout() -> void:
	if r.type == "speed" and sp_i * 2 >= problems.size():
		_speed_end(true)
	else:
		_reveal("時間到！")


# ================= 數字鍵盤填空 =================

func _slot_count(template: String) -> int:
	var n := 0
	while template.contains("[%d]" % n):
		n += 1
	return n


func _build_fill(st: Dictionary) -> void:
	fill_step = st
	keypad_on = true
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	var n := _slot_count(st.template)
	slot_vals = []
	slot_bad = []
	for i in n:
		slot_vals.append("")
		slot_bad.append(false)
	cur_slot = 0
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.box(Color(FIRE.r, FIRE.g, FIRE.b, 0.08), 14,
		Color(FIRE.r, FIRE.g, FIRE.b, 0.4), 1, 12))
	rank_box.add_child(card)
	# 敘述題：填空直接寫在中間的推導紀錄裡（學生只要看中間），右邊只留按鍵
	card.visible = not _inline_fill()
	if _inline_fill():
		var tip := Label.new()
		tip.text = "空格在左邊的推導紀錄裡，用下面的按鍵填入。"
		tip.add_theme_font_size_override("font_size", UITheme.fs(15))
		tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		rank_box.add_child(tip)
		rank_box.move_child(tip, 0)
	fill_preview = MathLabel.new()
	fill_tpl = _wrap_template(st.template)
	fill_preview.font_size = UITheme.fs(20) if fill_tpl.contains("\n") else UITheme.fs(24)
	fill_preview.max_width = 320
	fill_preview.align_center = true
	fill_preview.color = UITheme.TEXT
	card.add_child(fill_preview)
	slot_btns = []
	if n > 1:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		rank_box.add_child(row)
		# 格子列和下面的按鍵之間多留一點空隙
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 4)
		rank_box.add_child(gap)
		for i in n:
			var b := Button.new()
			b.clip_text = true
			b.custom_minimum_size = Vector2(0, 32)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", UITheme.fs(17))
			var idx := i
			b.pressed.connect(func():
				cur_slot = idx
				_refresh_fill())
			row.add_child(b)
			slot_btns.append(b)
	_build_keypad(n > 1)
	_refresh_fill()


## 填空寫在中間（推導紀錄）而不是右邊：一步一步的敘述題都這樣（速算爐的題目本來就在中間，不用）
func _inline_fill() -> bool:
	return fview != null and (r.type == "forge" or (r.type == "tune" and tune_phase == 1))


## 填空模板太寬就在合適的地方換行：兩段各自的推導分兩行，「⇒」之前斷開
func _wrap_template(tpl: String) -> String:
	var out := tpl.replace("　　", "\n")
	var font := get_theme_default_font()
	var too_wide := false
	for ln in out.split("\n"):
		if ForgeView._mw(font, ln.replace("[0]", "□□").replace("[1]", "□□").replace("[2]", "□□").replace("[3]", "□□"), 24) > 300.0:
			too_wide = true
	if too_wide and out.contains(" ⇒ "):
		out = out.replace(" ⇒ ", "\n⇒ ")
	return out


func _build_keypad(multi: bool) -> void:
	var pad := VBoxContainer.new()
	pad.add_theme_constant_override("separation", 6)
	rank_box.add_child(pad)
	# 小數題（首數、尾數）把「/」換成「.」
	var frac_key := "." if fill_step.get("dec", false) else "/"
	# 「下一格」不放按鈕：點上面的格子（①②③）就能換格子
	var last_row := ["−", frac_key, "⌫", "送出"]
	if _rad_on():
		last_row.insert(2, "√")
	var rows := [["1", "2", "3", "4", "5"], ["6", "7", "8", "9", "0"], last_row]
	for keys in rows:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		pad.add_child(row)
		for k in keys:
			if k == "":
				continue
			var b := Button.new()
			b.text = "下一格" if k == "→" else k
			b.custom_minimum_size = Vector2(0, 40)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_size_override("font_size", UITheme.fs(20) if k.length() == 1 else UITheme.fs(15))
			if k == "√":
				b.add_theme_color_override("font_color", UITheme.CYAN)
			if k == "→":
				b.size_flags_stretch_ratio = 1.4
			if k == "送出":
				UITheme.accent_button(b, 18)
				b.size_flags_stretch_ratio = 2.2 if _rad_on() else 3.0
			var key: String = k
			b.pressed.connect(func(): _key(key))
			row.add_child(b)


func _key(k: String) -> void:
	if not keypad_on or busy:
		return
	var v: String = slot_vals[cur_slot]
	match k:
		"⌫":
			v = v.substr(0, maxi(0, v.length() - 1))
		"−":
			v = v.substr(1) if v.begins_with("−") else "−" + v
		"/":
			if not v.contains("/") and not v.contains(".") and v.replace("−", "") != "" and not v.ends_with("√"):
				v += "/"
		"√":
			# 分子、分母各自最多一個根號：2√3、√3/2、1/√3
			var part := v.substr(v.find("/") + 1) if v.contains("/") else v
			if _rad_on() and not part.contains("√") and not v.contains("."):
				v += "√"
		".":
			if not v.contains(".") and not v.contains("/"):
				v += "." if v.replace("−", "") != "" else "0."
		"→":
			cur_slot = (cur_slot + 1) % slot_vals.size()
			_refresh_fill()
			return
		"送出":
			_fill_submit()
			return
		_:
			if v.length() < (10 if _rad_on() else 7):
				v += k
	slot_vals[cur_slot] = v
	slot_bad[cur_slot] = false
	_refresh_fill()


func _refresh_fill() -> void:
	if fill_preview == null or not is_instance_valid(fill_preview):
		return
	var t: String = fill_tpl
	for i in slot_vals.size():
		var shown: String = slot_vals[i]
		# 「+ □」裡填了負數：顯示成「− 3」而不是「+ −3」
		if shown.begins_with("−"):
			if t.contains("+ [%d]" % i):
				t = t.replace("+ [%d]" % i, "− [%d]" % i)
				shown = shown.substr(1)
			elif t.contains("− [%d]" % i):
				t = t.replace("− [%d]" % i, "+ [%d]" % i)
				shown = shown.substr(1)
		if shown.contains("√"):
			shown = rad_markup(shown)
		var col: Color
		if shown == "":
			shown = "▢" if i == cur_slot else "□"
			col = UITheme.ACCENT if i == cur_slot else UITheme.TEXT_DIM
		else:
			col = UITheme.BAD if slot_bad[i] else (UITheme.ACCENT if i == cur_slot else UITheme.CYAN)
		t = t.replace("[%d]" % i, "[color=#%s]%s[/color]" % [col.to_html(false), shown])
	fill_preview.text = t
	if _inline_fill():
		fview.live_fill = t
		fview.scroll_rows = 0     # 開始填答：推導紀錄回到最下面
		fview.live_slot = cur_slot
		fview.queue_redraw()
	for i in slot_btns.size():
		var b: Button = slot_btns[i]
		# 用 ①②③ 標格子（字放大後「第 1 格：…」兩個並排就放不下）
		b.text = "%s %s" % ["①②③④⑤⑥"[mini(i, 5)], slot_vals[i] if slot_vals[i] != "" else "＿"]
		var c := UITheme.BAD if slot_bad[i] else (UITheme.ACCENT if i == cur_slot else Color(1, 1, 1, 0.15))
		b.add_theme_stylebox_override("normal", UITheme.box(UITheme.PANEL_LIGHT, 10, c, 2 if i == cur_slot or slot_bad[i] else 1, 6))
		b.add_theme_stylebox_override("hover", UITheme.box(UITheme.PANEL_LIGHT.lightened(0.08), 10, c, 2, 6))
		# 按下時也用一樣大小的框（主題預設的按下樣式內距比較大，按下去格子會變高、壓到下面的按鍵）
		var pr := UITheme.box(UITheme.PANEL_LIGHT.lightened(0.14), 10, UITheme.ACCENT, 2, 6)
		b.add_theme_stylebox_override("pressed", pr)
		b.add_theme_stylebox_override("hover_pressed", pr)


func _fill_submit() -> void:
	if not keypad_on:
		return
	var ins := []
	var rad: bool = _rad_on() and fill_step.get("mode", "ordered") in ["ordered", "set"]
	for i in slot_vals.size():
		var q := parse_r(slot_vals[i]) if rad else parse_q(slot_vals[i])
		if q.is_empty():
			cur_slot = i
			_refresh_fill()
			var how := "可填整數、負數或分數，例如 −3/2"
			if fill_step.get("dec", false):
				how = "可填整數、負數或小數，例如 0.301"
			elif rad:
				how = "可填整數、分數或根號，例如 −√3/2、2√3"
			_hint("%s 格還沒填好（%s）。" % ["①②③④⑤⑥"[mini(i, 5)], how], "info")
			return
		ins.append(q)
	var ans := []
	for a in fill_step.answers:
		ans.append(parse_r(str(a)) if rad else parse_q(str(a)))
	var ok := false
	if rad:
		# 有根號：化成最簡（a√b / c）再比
		for i in slot_bad.size():
			slot_bad[i] = false
		if fill_step.get("mode", "ordered") == "set":
			var used := []
			used.resize(ans.size())
			used.fill(false)
			ok = ins.size() == ans.size()
			for x in ins:
				var hit := false
				for j in ans.size():
					if not used[j] and x == ans[j]:
						used[j] = true
						hit = true
						break
				if not hit:
					ok = false
			if not ok:
				for i in slot_bad.size():
					slot_bad[i] = true
		else:
			ok = true
			for i in ins.size():
				if ins[i] != ans[i]:
					slot_bad[i] = true
					ok = false
		_fill_judge(ok)
		return
	for i in slot_bad.size():
		slot_bad[i] = false
	match fill_step.get("mode", "ordered"):
		"set":
			ok = q_same_set(ins, ans)
			if not ok:
				for i in slot_bad.size():
					slot_bad[i] = true
		"approx":
			# 近似值：和答案相差不超過 tol
			ok = true
			for i in ins.size():
				if absf(float(ins[i][0]) / ins[i][1] - float(ans[i][0]) / ans[i][1]) > float(fill_step.get("tol", 0.01)) + 1e-9:
					slot_bad[i] = true
					ok = false
		"prop":
			ok = q_prop(ins, ans)
			if not ok:
				for i in slot_bad.size():
					slot_bad[i] = true
		_:
			ok = true
			for i in ins.size():
				if not q_eq(ins[i], ans[i]):
					slot_bad[i] = true
					ok = false
	_fill_judge(ok)


func _fill_judge(ok: bool) -> void:
	if ok:
		keypad_on = false
		Game.of(self).sfx("correct")
		if r.type == "speed":
			_speed_correct()
		else:
			_step_done(fill_step, "")
		return
	Game.of(self).sfx("wrong")
	_record(fill_step.get("tag", "exp_eq_calc"))
	_refresh_fill()
	if r.type == "speed":
		_speed_wrong()
		return
	mistakes += 1
	fview.miss()
	story_label.visible = false
	_fail("還不對（紅色的格子）。提示：" + fill_step.nudge)


# ---------- 有理數 ----------

## "−3/2" → [−3, 2]；看不懂就回傳 []
static func parse_q(s: String) -> Array:
	var v := s.strip_edges().replace("−", "-")
	if v == "":
		return []
	var neg := v.begins_with("-")
	if neg:
		v = v.substr(1)
	# 小數：0.7185 → 7185/10000
	if v.contains("."):
		var dp := v.split(".")
		if dp.size() != 2 or (dp[0] != "" and not dp[0].is_valid_int()) or dp[1] == "" or not dp[1].is_valid_int() or dp[1].length() > 8:
			return []
		var den := int(pow(10, dp[1].length()))
		var num := int(dp[0] if dp[0] != "" else "0") * den + int(dp[1])
		return [-num if neg else num, den]
	var parts := v.split("/")
	if parts.size() > 2:
		return []
	for p in parts:
		if not p.is_valid_int():
			return []
	var n := int(parts[0])
	var d := int(parts[1]) if parts.size() == 2 else 1
	if d == 0:
		return []
	return [-n if neg else n, d]


## 這一格可以按根號嗎：步驟寫 "rad": true，或整個關卡開啟（覆寫 radicals_ok()）
func _rad_on() -> bool:
	return bool(fill_step.get("rad", radicals_ok()))


## 子類別覆寫成 true：這一關所有的填空都有「√」鍵（三角函數的值常常有根號）
func radicals_ok() -> bool:
	return false


## 含根號的數："−√3/2"、"2√3"、"1/√3"、"3√2/4"、"−3/2"、"5" → 最簡的 [a, b, c]，代表 a√b / c
##   （b 沒有平方因數、c > 0、a 和 c 互質；分母的根號會有理化：1/√3 = √3/3）。看不懂就回傳 []
static func parse_r(s: String) -> Array:
	var v := s.strip_edges().replace("−", "-")
	if v == "":
		return []
	var neg := v.begins_with("-")
	if neg:
		v = v.substr(1)
	if not v.contains("√"):
		var q := parse_q(v)
		if q.is_empty():
			return []
		return _r_norm((-1 if neg else 1) * int(q[0]), 1, int(q[1]), 1)
	var parts := v.split("/")
	if parts.size() > 2:
		return []
	var top := _r_part(parts[0])
	if top.is_empty():
		return []
	var bot := [1, 1] if parts.size() == 1 else _r_part(parts[1])
	if bot.is_empty() or bot[0] == 0:
		return []
	return _r_norm((-1 if neg else 1) * int(top[0]), int(top[1]), int(bot[0]), int(bot[1]))


## "2√3" → [2, 3]、"√3" → [1, 3]、"5" → [5, 1]
static func _r_part(t: String) -> Array:
	if t == "":
		return []
	if not t.contains("√"):
		return [int(t), 1] if t.is_valid_int() else []
	var pr := t.split("√")
	if pr.size() != 2 or pr[1] == "" or not pr[1].is_valid_int():
		return []
	if pr[0] != "" and not pr[0].is_valid_int():
		return []
	var co := 1 if pr[0] == "" else int(pr[0])
	var rd := int(pr[1])
	if rd <= 0:
		return []
	return [co, rd]


## (a√b) / (c√d) 化成最簡
static func _r_norm(a: int, b: int, c: int, d: int) -> Array:
	# 有理化：乘上 √d / √d
	var rad := b * d
	var den := c * d
	if c < 0:
		a = -a
		den = -den
	# 把平方因數提出來
	var k := 2
	while k * k <= rad:
		while rad % (k * k) == 0:
			rad /= k * k
			a *= k
		k += 1
	if a == 0:
		return [0, 1, 1]
	var g := absi(a)
	var h := absi(den)
	while h != 0:
		var tt := g % h
		g = h
		h = tt
	return [a / g, rad, den / g]


## 顯示用："−√3/2" → "−\frac{√{3}}{2}"、"2√3" → "2√{3}"（還沒打完的根號顯示成空格）
static func rad_markup(s: String) -> String:
	var neg := s.begins_with("−")
	var v := s.substr(1) if neg else s
	var parts := v.split("/")
	var outs := []
	for pp in parts:
		var p: String = pp
		if p.contains("√"):
			var pr := p.split("√")
			p = pr[0] + "√{" + (pr[1] if pr[1] != "" else "　") + "}"
		outs.append(p if p != "" else "　")
	var m: String = outs[0] if outs.size() == 1 else "\\frac{%s}{%s}" % [outs[0], outs[1]]
	return ("−" if neg else "") + m


static func q_eq(a: Array, b: Array) -> bool:
	return a[0] * b[1] == b[0] * a[1]


static func q_same_set(ins: Array, ans: Array) -> bool:
	if ins.size() != ans.size():
		return false
	var used := []
	used.resize(ans.size())
	used.fill(false)
	for x in ins:
		var hit := false
		for j in ans.size():
			if not used[j] and q_eq(x, ans[j]):
				used[j] = true
				hit = true
				break
		if not hit:
			return false
	return true


## 成比例（而且不全為 0）：x_i·y_j = x_j·y_i
static func q_prop(ins: Array, ans: Array) -> bool:
	var any := false
	for x in ins:
		if x[0] != 0:
			any = true
	if not any:
		return false
	for i in ins.size():
		for j in ins.size():
			var lhs: int = ins[i][0] * ans[j][0] * ins[j][1] * ans[i][1]
			var rhs: int = ins[j][0] * ans[i][0] * ins[i][1] * ans[j][1]
			if lhs != rhs:
				return false
	return true


static func _to_f(s) -> float:
	var q := parse_q(str(s))
	return float(q[0]) / q[1] if not q.is_empty() else NAN


# ================= 篩選 =================

func _build_filter(st: Dictionary) -> void:
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	filter_keep = []
	filter_btns = []
	# 候選值太多時排成兩行以上（一行最多 3 個），才不會超出右邊的卡片
	var many: bool = st.cands.size() > 3
	var row := GridContainer.new()
	row.columns = 3 if many else maxi(1, st.cands.size())
	row.add_theme_constant_override("h_separation", 8 if many else 10)
	row.add_theme_constant_override("v_separation", 8)
	rank_box.add_child(row)
	for i in st.cands.size():
		filter_keep.append(true)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 64)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.clip_text = true
		b.add_theme_font_size_override("font_size", UITheme.fs(15 if many else 18))
		var idx: int = i
		b.pressed.connect(func():
			filter_keep[idx] = not filter_keep[idx]
			_refresh_filter())
		row.add_child(b)
		filter_btns.append(b)
	var tip := Label.new()
	tip.text = st.get("tip", "點一下可以切換「保留」或「丟掉」。")
	tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(tip)
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "確認"
	_refresh_filter()


func _refresh_filter() -> void:
	var st: Dictionary = steps[si]
	for i in filter_btns.size():
		var b: Button = filter_btns[i]
		var keep: bool = filter_keep[i]
		b.text = "%s = %s\n%s" % [st.get("var", "t"), _plain_root(str(st.cands[i])).replace("-", "−"),
			st.get("keep_word", "✓ 保留") if keep else st.get("drop_word", "✗ 丟掉")]
		var c := UITheme.GOOD if keep else UITheme.BAD
		var sb := UITheme.box(Color(c.r, c.g, c.b, 0.14), 12, c, 2, 6)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_color_override("font_color", c.lightened(0.3))
		b.add_theme_color_override("font_hover_color", c.lightened(0.3))
		b.add_theme_color_override("font_pressed_color", c.lightened(0.3))


## 按鈕是一般文字：把 √{6} 寫成 √6
static func _plain_root(s: String) -> String:
	var re := RegEx.new()
	re.compile("√\\{([^{}]+)\\}")
	return re.sub(s, "√$1", true)


func _filter_submit() -> void:
	var st: Dictionary = steps[si]
	if filter_keep == Array(st.keep):
		Game.of(self).sfx("correct")
		go_btn.visible = false
		_step_done(st, "")
		return
	mistakes += 1
	Game.of(self).sfx("wrong")
	_record(st.tag)
	fview.miss()
	_fail("還不對。提示：" + st.nudge)


# ================= 排序（由小到大） =================

## 步驟答錯：扣能量、記錄錯題（有 tag 才記）、鍛造台抖一下
func _wrong(st: Dictionary, msg: String) -> void:
	mistakes += 1
	Game.of(self).sfx("wrong")
	if st.has("tag"):
		_record(st.tag)
	fview.miss()
	story_label.visible = false
	_fail(msg)


# ---------- 排序 ----------

var order_undo: Button
var order_reset: Button


func _build_order(st: Dictionary) -> void:
	go_btn.text = "確認順序"
	order_seq = []
	order_btns = []
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.box(Color(step_color().r, step_color().g, step_color().b, 0.08), 14,
		Color(step_color().r, step_color().g, step_color().b, 0.4), 1, 10))
	rank_box.add_child(card)
	order_preview = MathLabel.new()
	order_preview.font_size = UITheme.fs(24)
	order_preview.max_width = 320
	order_preview.align_center = true
	card.add_child(order_preview)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	rank_box.add_child(grid)
	for i in st.items.size():
		var it: Dictionary = st.items[i]
		var b := MathLabel.make_button(it.text, 17, Vector2(0, 44))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.set_meta("silent", true)
		var idx: int = i
		b.pressed.connect(func():
			if order_seq.has(idx):
				# 點已經選過的：把它（和它後面的）拿回來，可以反悔
				order_seq = order_seq.slice(0, order_seq.find(idx))
				Game.of(self).play("bell", Game.semi(Game.scale_semi(1)), -12.0)
				_refresh_order()
				return
			order_seq.append(idx)
			Game.of(self).play("bell", Game.semi(Game.scale_semi(2 + order_seq.size())), -8.0)
			_refresh_order())
		grid.add_child(b)
		order_btns.append(b)
	if st.items.size() % 2 == 1:
		grid.add_child(Control.new())
	# 反悔用：退回一個、整個重排
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	rank_box.add_child(row)
	var undo := Button.new()
	undo.text = "⌫ 退回一個"
	order_undo = undo
	var reset := Button.new()
	reset.text = "↺ 重新排"
	order_reset = reset
	for rb in [undo, reset]:
		rb.custom_minimum_size = Vector2(0, 40)
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rb.focus_mode = Control.FOCUS_NONE
		rb.add_theme_font_size_override("font_size", UITheme.fs(15))
		UITheme.tight(rb, 6)
		row.add_child(rb)
	undo.pressed.connect(func():
		if not order_seq.is_empty():
			order_seq.pop_back()
			_refresh_order())
	reset.pressed.connect(func():
		order_seq = []
		_refresh_order())
	var tip := Label.new()
	tip.text = "點已選的項目也可以把它拿回來。"
	tip.add_theme_font_size_override("font_size", UITheme.fs(13))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(tip)
	_refresh_order()


func _refresh_order() -> void:
	var st: Dictionary = steps[si]
	var parts := PackedStringArray()
	for idx in order_seq:
		parts.append("[color=#%s]%s[/color]" % [step_color().to_html(false), st.items[idx].k])
	for k in st.items.size() - order_seq.size():
		parts.append("[color=#%s]□[/color]" % UITheme.TEXT_DIM.to_html(false))
	order_preview.text = "  <  ".join(parts)
	for i in order_btns.size():
		var b: Button = order_btns[i]
		# 已選的不鎖住（點了可以拿回來），只是變淡
		b.modulate = Color(1, 1, 1, 0.4) if order_seq.has(i) else Color.WHITE
	if is_instance_valid(order_undo):
		order_undo.disabled = order_seq.is_empty()
		order_reset.disabled = order_seq.is_empty()
	go_btn.disabled = order_seq.size() < st.items.size()


func _order_submit() -> void:
	var st: Dictionary = steps[si]
	if order_seq.size() < st.items.size():
		return
	var ok := true
	for i in range(1, order_seq.size()):
		if float(st.items[order_seq[i - 1]].v) >= float(st.items[order_seq[i]].v):
			ok = false
	if ok:
		Game.of(self).sfx("correct")
		_step_done(st, "")
		return
	order_seq = []
	_refresh_order()
	_wrong(st, "順序不對，再排一次。提示：" + st.nudge)



# ================= 速算爐 =================

func _speed_begin() -> void:
	problems = _speed_gen(r.gen, int(r.count))
	sp_i = 0
	sp_wrong = 0
	streak = 0
	_speed_show()


## 速算題目產生器：子類別覆寫，回傳 [{eq, ans, nudge}, …]（ans 是答案字串，例如 "−3/2"）
func _speed_gen(_kind: String, _n: int) -> Array:
	return []


## 速算題目記錄錯題用的觀念標籤
func _speed_tag() -> String:
	return ""


func _speed_show() -> void:
	var pb: Dictionary = problems[sp_i]
	fview.show_speed(pb.eq, sp_i, problems.size(), streak)
	step_label.text = UITheme.step_bar(_steps(), 0)
	if sp_i > 0:
		story_label.visible = false
	_build_fill({"name": "速算", "q": "解出 x（可以填負數或分數，例如 −3/2）。", "template": "x = [0]",
		"answers": [pb.ans], "mode": "ordered", "nudge": pb.nudge, "tag": _speed_tag(), "line": ""})


func _speed_correct() -> void:
	streak += 1
	score += 10 * streak
	sp_i += 1
	fview.speed_hit(streak)
	hint_panel.visible = false
	if sp_i >= problems.size():
		_speed_end(false)
	else:
		_speed_show()
	_update_hud()


func _speed_wrong() -> void:
	streak = 0
	sp_wrong += 1
	time_left = maxf(1.0, time_left - 5.0)
	fview.miss()
	keypad_on = true
	story_label.visible = false
	_hint("不對喔，再算一次！（−5 秒）\n" + fill_step.nudge, "bad")
	_update_hud()


func _speed_end(timeout: bool) -> void:
	keypad_on = false
	_clear(rank_box)
	rank_box.visible = false
	fview.finish()
	if timeout:
		_finish_round(false, 3)
		hint_label.text = "時間到！完成 %d / %d 題。\n" % [sp_i, problems.size()] + hint_label.text
	else:
		_finish_round(sp_wrong == 0, sp_wrong + 1)


# ================= 參數調頻 =================

func _tune_begin() -> void:
	tune_phase = 0
	steps = []
	si = 0
	tp = float(r.param.start)
	goal_idx = 0
	mislocks = 0
	tune_last = -1
	rank_box.visible = true
	_clear(rank_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	rank_box.add_child(row)
	var name_l := Label.new()
	name_l.text = "參數 " + r.param.name
	name_l.add_theme_color_override("font_color", FIRE)
	name_l.custom_minimum_size = Vector2(72, 0)
	row.add_child(name_l)
	tune_slider = UITheme.touch_slider()
	var rg: Array = r.param.range
	tune_slider.min_value = rg[0]
	tune_slider.max_value = rg[1]
	tune_slider.step = rg[2]
	tune_slider.value = tp
	tune_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tune_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tune_slider.custom_minimum_size = Vector2(0, 28)
	UITheme.tint_slider(tune_slider, FIRE)
	row.add_child(tune_slider)
	UITheme.add_step_buttons(tune_slider, FIRE)
	tune_val = Label.new()
	tune_val.custom_minimum_size = Vector2(56, 0)
	tune_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tune_val.add_theme_color_override("font_color", FIRE)
	row.add_child(tune_val)
	tune_slider.value_changed.connect(_on_tune)
	task_label.visible = true
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "鎖定"
	step_label.text = UITheme.step_bar(_steps(), 0)
	fview.tp = tp
	_on_tune(tp)
	_tune_goal_text()


## 調頻任務完成後：先一步步算判別式、根與係數，最後才選範圍
func _tune_after_goals() -> void:
	tune_phase = 1
	steps = r.get("steps", [])
	si = 0
	pre_done = {}
	mistakes = 0
	story_label.visible = false
	fview.tune_calc = true
	fview.mouse_filter = Control.MOUSE_FILTER_STOP   # 計算過程可以上下拖動捲動
	_tune_calc_range()
	hint_panel.visible = false
	go_btn.visible = false
	if steps.is_empty():
		_tune_final()
	else:
		_forge_step()


## 計算步驟用的示意圖：找出「合格的根最多」的參數範圍，讓拋物線在裡面來回（不再停在最後一個任務的狀態）
func _tune_calc_range() -> void:
	var rg: Array = r.param.range
	var want := 0
	for g in r.goals:
		want = maxi(want, int(g))
	var good := []
	var stp := float(rg[2]) / 4.0
	var v := float(rg[0])
	while v <= float(rg[1]) + 1e-9:
		if tune_valid(r, v) == want:
			good.append(v)
		v += stp
	if good.is_empty():
		fview.calc_lo = NAN
		fview.calc_hi = NAN
		return
	var lo: float = good.min()
	var hi: float = good.max()
	var pad := (hi - lo) * 0.12
	fview.calc_lo = lo + pad
	fview.calc_hi = hi - pad


func _tune_final() -> void:
	tune_phase = 2
	fview.cur_name = ""
	keypad_on = false
	_clear(rank_box)
	rank_box.visible = false
	go_btn.visible = false
	task_label.visible = false
	_show_question(r.final)
	_step_text()


func _tune_goal_text() -> void:
	task_label.text = ("任務 %d／%d：" % [goal_idx + 1, r.goals.size()]) + (r.goal_text % r.goals[goal_idx])


func _on_tune(v: float) -> void:
	tp = v
	fview.tp = v
	tune_val.text = UITheme.num(v, 2).replace("-", "−")
	var n := tune_valid(r, v)
	if tune_last != -1 and n != tune_last:
		Game.of(self).sfx("count", n)
	tune_last = n
	fview.queue_redraw()


## 參數為 p 時，t 的二次方程式在合格區（t > region）的相異根
static func tune_roots(rd: Dictionary, p: float) -> Array:
	var c: Array = rd.coef
	var A: float = c[0][0] + c[0][1] * p
	var B: float = c[1][0] + c[1][1] * p
	var C: float = c[2][0] + c[2][1] * p
	var D := B * B - 4.0 * A * C
	if D < -1e-9:
		return []
	if absf(D) <= 1e-9:
		return [-B / (2.0 * A)]
	var sq := sqrt(D)
	var r1 := (-B - sq) / (2.0 * A)
	var r2 := (-B + sq) / (2.0 * A)
	return [minf(r1, r2), maxf(r1, r2)]


static func tune_valid(rd: Dictionary, p: float) -> int:
	var n := 0
	for t in tune_roots(rd, p):
		if t > float(rd.region) + 1e-9:
			n += 1
	return n


func _tune_lock() -> void:
	if busy or predicting:
		return
	var n := tune_valid(r, tp)
	var goals: Array = r.goals
	if n == goals[goal_idx]:
		Game.of(self).sfx("correct")
		fview.burst_center()
		goal_idx += 1
		if goal_idx >= goals.size():
			go_btn.visible = false
			rank_box.visible = false
			task_label.visible = false
			_tune_after_goals()
			return
		_hint("✓ 任務完成！%s = %s 時恰有 %d 個%s。" % [r.param.name, UITheme.num(tp, 2), n, r.unit], "good")
		_tune_goal_text()
		return
	mislocks += 1
	Game.of(self).sfx("wrong")
	_record("exp_eq_param")
	if mislocks >= 4:
		var rg: Array = r.param.range
		var v := float(rg[0])
		while v <= float(rg[1]) + 1e-6:
			if tune_valid(r, v) == goals[goal_idx]:
				tune_slider.value = v
				break
			v += float(rg[2])
		_hint("%s = %s 時有 %d 個%s。只算亮區（%s）裡的交點。" % [
			r.param.name, UITheme.num(tp, 2), goals[goal_idx], r.unit, r.region_label], "info")
		return
	_hint("現在 %d 個%s，目標 %d 個。只算亮區（%s）裡的交點。" % [n, r.unit, goals[goal_idx], r.region_label], "bad")


# ================= 實體鍵盤 =================

func _unhandled_input(e: InputEvent) -> void:
	if intro_block != null and e is InputEventKey and e.pressed and not e.echo and e.keycode != KEY_ESCAPE:
		_intro_finish()       # 開場動畫中按任何鍵：直接顯示完整題目
		get_viewport().set_input_as_handled()
		return
	if not keypad_on or not (e is InputEventKey) or not e.pressed or e.echo:
		return
	var k := ""
	var code: int = e.keycode
	if code >= KEY_0 and code <= KEY_9:
		k = str(code - KEY_0)
	elif code >= KEY_KP_0 and code <= KEY_KP_9:
		k = str(code - KEY_KP_0)
	else:
		match code:
			KEY_MINUS, KEY_KP_SUBTRACT:
				k = "−"
			KEY_PERIOD, KEY_KP_PERIOD:
				k = "." if fill_step.get("dec", false) else ""
			KEY_SLASH, KEY_KP_DIVIDE:
				k = "/"
			KEY_R, KEY_V:
				k = "√" if _rad_on() else ""
			KEY_BACKSPACE:
				k = "⌫"
			KEY_ENTER, KEY_KP_ENTER:
				k = "送出"
			KEY_TAB, KEY_RIGHT:
				k = "→"
			KEY_LEFT:
				cur_slot = (cur_slot - 1 + slot_vals.size()) % slot_vals.size()
				_refresh_fill()
				get_viewport().set_input_as_handled()
				return
	if k == "" or (k == "→" and slot_vals.size() < 2):
		return
	get_viewport().set_input_as_handled()
	_key(k)


# ================= 推導紀錄的捲動 =================

var log_drag: LogDrag


## 在推導紀錄上面蓋一層透明的觸控區：上下拖動（或滾輪）可以往回看前面的步驟
func _ensure_log_drag() -> void:
	if log_drag != null and is_instance_valid(log_drag) and log_drag.view == fview:
		stage.move_child(log_drag, -1)
		return
	if log_drag != null and is_instance_valid(log_drag):
		log_drag.queue_free()
	log_drag = LogDrag.new()
	log_drag.view = fview
	stage.add_child(log_drag)


class LogDrag extends Control:
	const ROW := 36.0          # 拖動多少像素算一行
	var view                   # ForgeView
	var _acc := 0.0
	var _down := false

	func _ready() -> void:
		position = Vector2.ZERO
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_dt: float) -> void:
		if view == null or not is_instance_valid(view):
			return
		var on: bool = view.visible and view.can_scroll() and view.mouse_filter == Control.MOUSE_FILTER_IGNORE
		size = Vector2(view.size.x, maxf(0.0, view._bottom_limit()))
		mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
		if not on:
			_down = false

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			match e.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					if e.pressed:
						view.scroll_by(1)
					accept_event()
				MOUSE_BUTTON_WHEEL_DOWN:
					if e.pressed:
						view.scroll_by(-1)
					accept_event()
				MOUSE_BUTTON_LEFT:
					_down = e.pressed
					_acc = 0.0
					accept_event()
		elif e is InputEventMouseMotion and _down:
			# 手指往下拖：看上面（前面）的步驟；往上拖：回到最新
			_acc += e.relative.y
			while _acc >= ROW:
				_acc -= ROW
				view.scroll_by(1)
			while _acc <= -ROW:
				_acc += ROW
				view.scroll_by(-1)
			accept_event()


# ================= 鍛造台（畫在舞台上） =================

class ForgeView extends Control:
	const UITheme := preload("game_theme.gd")
	const Ambient := preload("ambient.gd")
	const MathLabel := preload("math_text.gd")
	const FIRE := UITheme.ORANGE
	const GOLD := UITheme.GOLD

	var intro := -1.0        # ≥ 0：開場動畫中，題目出現到第幾個字
	var t := 0.0
	var kind := "forge"
	var eq := ""
	var lines: Array = []           # {text, born}
	var cur_name := ""
	var step := 0
	var graph := {}
	var rejected: Array = []
	var done := false
	var done_t := 0.0
	var particles: Array = []
	var miss_t := -10.0
	# 速算
	var sp_eq := ""
	var sp_i := 0
	var sp_total := 0
	var streak := 0
	var hit_t := -10.0
	# 調頻
	var rd := {}
	var tp := 0.0
	var tune_calc := false        # 調頻任務完成後：圖縮小，下方寫計算過程
	var xt := {}                  # 「檢查 t」步驟改看 x–t 圖：{base, sign, sum, fi, cands, region, label}
	var live_fill := ""           # 正在作答的填空（直接畫在推導紀錄裡）
	var live_q := ""              # 這一步在問什麼（寫在填空框的上方）
	var live_slot := 0
	var calc_lo := NAN            # 計算步驟時的示意圖：參數在這個範圍內慢慢來回（兩個根都在亮區）
	var calc_hi := NAN
	var scroll := 0.0             # 參數調頻計算步驟：內容往上捲了多少
	var scroll_to := 0.0
	var _content_h := 0.0
	var _drag_y := NAN
	var log_title := "鍛造紀錄"
	var work_word := "鍛造"
	var speed_title := "速算爐"

	## 題目一共有幾個字（逐字出現用）
	func intro_total() -> float:
		var n := 0
		for ln in _eq_lines():
			n += MathLabel.glyph_count(ln)
		if kind == "tune":
			n += MathLabel.glyph_count(String(rd.get("ask", "")))
		return float(n)

	## 參數調頻的計算步驟：可以上下拖動（或滾輪）捲動
	func _gui_input(e: InputEvent) -> void:
		if not (kind == "tune" and tune_calc):
			return
		var mx := _max_scroll()
		if e is InputEventMouseButton:
			if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
				scroll_to = clampf(scroll_to - 50.0, 0.0, mx)
			elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
				scroll_to = clampf(scroll_to + 50.0, 0.0, mx)
			elif e.button_index == MOUSE_BUTTON_LEFT:
				_drag_y = e.position.y if e.pressed else NAN
			accept_event()
		elif e is InputEventMouseMotion and not is_nan(_drag_y) and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
			scroll_to = clampf(scroll_to - e.relative.y, 0.0, mx)
			scroll = scroll_to
			accept_event()

	func _max_scroll() -> float:
		return maxf(0.0, _content_h + 24.0 - size.y)

	func setup(round: Dictionary) -> void:
		rd = round
		intro = -1.0
		kind = round.type
		eq = round.get("eq", "")
		lines = []
		cur_name = ""
		step = 0
		graph = round.get("graph", {}).duplicate()
		# 拋物線（會露出根）要等學生自己解出 t 之後才出現
		if not graph.is_empty():
			var steps_: Array = round.get("steps", [])
			for i in steps_.size():
				if steps_[i].name == "解 t":
					graph["after"] = maxi(int(graph.get("after", 0)), i)
		rejected = []
		live_fill = ""
		xt = _xt_spec(round)
		done = false
		particles = []
		miss_t = -10.0
		streak = 0
		tune_calc = false
		scroll = 0.0
		scroll_to = 0.0
		_content_h = 0.0
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func push_line(text: String) -> void:
		scroll_rows = 0          # 有新的一行：自動回到最下面
		lines.append({"text": text, "born": t})
		_burst(Vector2(size.x / 2.0, _line_y(lines.size() - 1)), FIRE, 18)

	func finish() -> void:
		live_fill = ""
		scroll_rows = 0
		done = true
		done_t = t
		for i in 3:
			_burst(Vector2(size.x * (0.3 + 0.2 * i), size.y * 0.45), GOLD, 26)

	func miss() -> void:
		miss_t = t

	func burst_center() -> void:
		_burst(size / 2.0, GOLD, 30)

	func show_speed(e: String, i: int, total: int, s: int) -> void:
		sp_eq = e
		sp_i = i
		sp_total = total
		streak = s

	func speed_hit(s: int) -> void:
		streak = s
		hit_t = t
		_burst(Vector2(size.x / 2.0, size.y * 0.42), GOLD if s >= 3 else FIRE, 16 + 4 * mini(s, 6))

	func _burst(pos: Vector2, c: Color, n: int) -> void:
		for i in n:
			var ang := randf() * TAU
			particles.append({"p": pos, "v": Vector2(cos(ang), sin(ang)) * randf_range(60, 240) + Vector2(0, -90),
				"life": 1.0, "c": c, "r": randf_range(2.0, 4.5)})

	func _process(delta: float) -> void:
		t += delta
		if absf(scroll - scroll_to) > 0.5 and is_nan(_drag_y):
			scroll = lerpf(scroll, scroll_to, minf(1.0, delta * 10.0))
		for p in particles:
			p.p += p.v * delta
			p.v.y += 240.0 * delta
			p.life -= delta * 1.2
		particles = particles.filter(func(p): return p.life > 0.0)
		queue_redraw()

	# ---------- 版面 ----------

	var _eql_src := ""
	var _eql := PackedStringArray()

	func _eq_lines() -> PackedStringArray:
		if eq != _eql_src or _eql.is_empty():
			_eql_src = eq
			_eql = eq.split("\n")
		return _eql

	func _top_y() -> float:
		var eql := _eq_lines()
		var last := eql.size() - 1
		return _eq_y(last) + 50.0 + _extra(eql[last], _eq_fs(eql[last])).y     # 多留一點：上標高的算式才不會碰到分隔線

	## 題目第 i 行的基線：有分數的行會多留空間
	func _eq_y(i: int) -> float:
		var eql := _eq_lines()
		var y := 78.0
		for k in i + 1:
			var e := _extra(eql[k], _eq_fs(eql[k]))
			if k > 0:
				y += 38.0 + _extra(eql[k - 1], _eq_fs(eql[k - 1])).y
			y += e.x
		return y

	func _eq_fs(line: String) -> int:
		var given := line.begins_with("（")
		return _fit_fs(get_theme_default_font(), line, UITheme.fs(20) if given else UITheme.fs(24))

	func _extra(markup: String, fs: float) -> Vector2:
		return MathLabel.line_extra(get_theme_default_font(), markup, fs)

	## 鍛造紀錄每一行占的高度（有分數的行比較高）
	func _row_h(i: int) -> float:
		var tx: String = lines[i].text
		var e := _extra(tx, _fit_fs(get_theme_default_font(), tx, UITheme.fs(20)))
		return 40.0 + e.x + e.y

	func _graph_on() -> bool:
		return (not graph.is_empty() and step > int(graph.after)) or _xt_on()

	## 「檢查 t」那一步開始，下方的圖換成 t 和 x 的關係圖（t = a^{x}），強調 t 能落在哪裡
	func _xt_on() -> bool:
		return not xt.is_empty() and step >= int(xt.fi)

	static func _num_of(s: String) -> float:
		var u := s.strip_edges().replace("−", "-")
		if u.contains("/"):
			var pr := u.split("/")
			return float(pr[0]) / float(pr[1])
		return float(u)

	## 從題目步驟找出換元的式子：t = a^{x}、t = a^{−x}、t = a^{x} + a^{−x}
	static func _xt_spec(round: Dictionary) -> Dictionary:
		var steps_: Array = round.get("steps", [])
		var fi := -1
		for i in steps_.size():
			if steps_[i].get("kind", "") == "filter":
				fi = i
				break
		if fi < 0:
			return {}
		# 底數不是整數（例如 (2 + √3)^{x}）：題庫直接給曲線資料
		var gx: Dictionary = round.get("graph", {}).get("xt", {})
		if not gx.is_empty():
			return {"base": float(gx.base), "sign": 1.0, "sum": false, "fi": fi, "cands": gx.vals,
				"tags": gx.get("tags", []), "region": 0.0, "label": gx.label}
		var re := RegEx.new()
		re.compile("t = (\\d+)\\^\\{(−?)x\\}(\\s*\\+\\s*\\d+\\^\\{−x\\})?")
		var m: RegExMatch = null
		for i in fi + 1:
			var txt: String = String(steps_[i].get("line", "")) + " " + String(steps_[i].get("q", ""))
			m = re.search(txt)
			if m:
				break
		if m == null:
			# _tpos 的題目文字是「2^{x} 一定大於 0」：沒有「t =」
			var re2 := RegEx.new()
			re2.compile("^(\\d+)\\^\\{(−?)x\\}")
			m = re2.search(String(steps_[fi].get("q", "")))
			if m == null:
				return {}
		var base := float(m.get_string(1))
		var neg := m.get_string(2) == "−"
		var sum := m.get_string(3) != "" if m.get_group_count() >= 3 else false
		var cands := []
		for c in steps_[fi].cands:
			cands.append(_num_of(String(c)))
		var bt := m.get_string(1)
		var label := "t = %s^{%s}" % [bt, "−x" if neg else "x"]
		if sum:
			label = "t = %s^{x} + %s^{−x}" % [bt, bt]
		return {"base": base, "sign": -1.0 if neg else 1.0, "sum": sum, "fi": fi, "cands": cands,
			"region": 2.0 if sum else 0.0, "label": label}

	func _xt_f(x: float) -> float:
		var b: float = xt.base
		if xt.sum:
			return pow(b, x) + pow(b, -x)
		return pow(b, float(xt.sign) * x)

	## x–t 圖：曲線 t = f(x)、t 的範圍（亮帶）、每個候選的 t 畫成一條水平線，碰得到曲線才有 x
	func _draw_xt(font: Font, rect: Rect2) -> void:
		var cands: Array = xt.cands
		var region: float = xt.region
		var lo := 0.0
		var hi := region + 1.0
		for c in cands:
			lo = minf(lo, c)
			hi = maxf(hi, c)
		var pad := 0.22 * (hi - lo)
		var yr := Vector2(lo - pad, hi + pad)
		var xr := Vector2(-2.6, 2.6)
		var to_px := func(p: Vector2) -> Vector2:
			return Vector2(rect.position.x + (p.x - xr.x) / (xr.y - xr.x) * rect.size.x,
				rect.position.y + rect.size.y - (p.y - yr.x) / (yr.y - yr.x) * rect.size.y)
		draw_style_box(UITheme.boxc(Color(0.05, 0.03, 0.06, 0.55), 12, Color(1, 0.7, 0.4, 0.25), 1, 0), rect.grow(6))
		MathLabel.draw_on(self, font, rect.position.x + 4 + _mw(font, "x 和 t 的關係：" + xt.label, UITheme.fs(13)) / 2.0, rect.position.y - 10,
			"x 和 t 的關係：" + xt.label, UITheme.fs(13), Color(1, 0.8, 0.6, 0.75))
		# t 能落在的範圍：亮帶；以下是「不可能」的暗區
		var ry: float = clampf(to_px.call(Vector2(0, region)).y, rect.position.y, rect.end.y)
		draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, ry - rect.position.y), Color(0.43, 0.9, 0.63, 0.10))
		draw_rect(Rect2(rect.position.x, ry, rect.size.x, rect.end.y - ry), Color(1, 0.3, 0.4, 0.07))
		draw_dashed_line(Vector2(rect.position.x, ry), Vector2(rect.end.x, ry), Color(0.43, 0.9, 0.63, 0.75), 1.5, 6.0)
		var rlab := ("t ≥ %s" % UITheme.num(region, 2)) if xt.sum else "t > 0"
		var pulse := 0.8 + 0.2 * sin(t * 3.0)
		MathLabel.draw_on(self, font, rect.position.x + 14 + _mw(font, "t 的範圍：" + rlab, UITheme.fs(17)) / 2.0, rect.position.y + 24,
			"t 的範圍：[color=#6ee7a0]" + rlab + "[/color]", UITheme.fs(17), Color(1, 1, 1, pulse))
		if ry < rect.end.y - 18:
			draw_string(font, Vector2(rect.position.x + 14, rect.end.y - 8), "曲線到不了這裡", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13),
				Color(1, 0.5, 0.55, 0.75))
		# 座標軸
		var o: Vector2 = to_px.call(Vector2(0, 0))
		if o.y >= rect.position.y and o.y <= rect.end.y:
			draw_line(Vector2(rect.position.x, o.y), Vector2(rect.end.x, o.y), Color(1, 1, 1, 0.45), 1.5)
			preload("math_text.gd").draw_text(self, font, Vector2(rect.end.x - 14, o.y - 6), "x", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 1, 1, 0.7))
		draw_line(Vector2(o.x, rect.position.y), Vector2(o.x, rect.end.y), Color(1, 1, 1, 0.35), 1.0)
		preload("math_text.gd").draw_text(self, font, Vector2(o.x + 6, rect.position.y + 14), "t", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 1, 1, 0.7))
		# 曲線
		var pts := PackedVector2Array()
		var segs := []
		for i in 241:
			var x := lerpf(xr.x, xr.y, i / 240.0)
			var y := _xt_f(x)
			if y > yr.y:
				if pts.size() >= 2:
					segs.append(pts)
				pts = PackedVector2Array()
				continue
			pts.append(to_px.call(Vector2(x, y)))
		if pts.size() >= 2:
			segs.append(pts)
		var cc := UITheme.CYAN
		for sg in segs:
			draw_polyline(UITheme.thin(sg), Color(cc.r, cc.g, cc.b, 0.2), 8.0)
			draw_polyline(UITheme.thin(sg), cc, 2.5, true)
		# 候選的 t：水平線
		var decided := step > int(xt.fi)
		var tags: Array = xt.get("tags", [])
		for ci in cands.size():
			var c: float = cands[ci]
			var y: float = to_px.call(Vector2(0, c)).y
			var ok: bool = c > region + 1e-9 or (xt.sum and absf(c - region) < 1e-9)
			var col := Color(1, 0.95, 0.8, 0.8)
			if decided:
				col = GOLD if ok else Color(1, 0.4, 0.5)
			draw_dashed_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(col.r, col.g, col.b, 0.85), 2.0, 8.0)
			var tag := "t = " + (String(tags[ci]) if ci < tags.size() else _ftext(c))
			if decided:
				tag += "  ✓" if ok else "  ✗ 碰不到曲線"
			draw_string(font, Vector2(rect.end.x - 210, y - 6), tag, HORIZONTAL_ALIGNMENT_RIGHT, 200, UITheme.fs(15), col)
			if decided and ok:
				# 交點：這個 t 對應到的 x
				var xs := []
				if xt.sum:
					var u := log((c + sqrt(maxf(0.0, c * c - 4.0))) / 2.0) / log(float(xt.base))
					xs = [u, -u] if u > 1e-6 else [0.0]
				else:
					xs = [log(c) / log(float(xt.base)) * float(xt.sign)]
				for xv in xs:
					var p: Vector2 = to_px.call(Vector2(xv, c))
					UITheme.dot(self, p, 9.0 + 1.5 * sin(t * 4.0), Color(GOLD.r, GOLD.g, GOLD.b, 0.25))
					UITheme.dot(self, p, 5.0, GOLD)

	func _line_y(i: int) -> float:
		var first := _first_shown()
		var y := _top_y()
		for k in range(first, mini(i, lines.size())):
			y += _row_h(k)
		if i < lines.size():
			y += _extra(lines[i].text, _fit_fs(get_theme_default_font(), lines[i].text, UITheme.fs(20))).x
		return y

	func _bottom_limit() -> float:
		return size.y - (232.0 if _graph_on() else 30.0)

	## 「正在作答」那一塊的高度（填空寫在中間時比較高）
	func _live_h() -> float:
		if live_fill == "":
			return 40.0
		var font := get_theme_default_font()
		var he := _extra(_live_head(), UITheme.fs(15))
		var h := 40.0 + he.x + he.y + (6.0 if he.x > 0.0 else 0.0)
		for ln in live_fill.split("\n"):
			var e := _extra(ln, _fit_fs(font, ln, UITheme.fs(24)))
			h += 40.0 + e.x + e.y
		return h

	func _live_head() -> String:
		return "✎ " + (live_q if live_q != "" else cur_name)

	func _base_first() -> int:
		# 從最後一行往回放，放到放不下為止（還在作答時要留一行給「正在…」）
		var avail := _bottom_limit() - _top_y() - (0.0 if done else _live_h())
		var first := lines.size()
		var used := 0.0
		while first > 0:
			var h := _row_h(first - 1)
			if used + h > avail and first < lines.size():
				break
			used += h
			first -= 1
		return first

	## 推導紀錄可以往上捲（拖動或滾輪）：scroll_rows = 往回多看幾行
	var scroll_rows := 0

	func _first_shown() -> int:
		return maxi(0, _base_first() - scroll_rows)

	func can_scroll() -> bool:
		return kind == "forge" and intro < 0.0 and _base_first() > 0

	func scroll_by(d: int) -> void:
		var n := clampi(scroll_rows + d, 0, _base_first())
		if n != scroll_rows:
			scroll_rows = n
			queue_redraw()

	## 右邊的細捲軸：看得出來上面還有內容、目前在哪裡
	func _draw_log_bar() -> void:
		var base := _base_first()
		if base <= 0:
			return
		var y0 := _top_y() - 24.0
		var y1 := _bottom_limit() - 6.0
		var x := size.x - 14.0
		draw_line(Vector2(x, y0), Vector2(x, y1), Color(1, 1, 1, 0.08), 5.0, true)
		var total := float(lines.size())
		var vis := float(lines.size() - base)
		var h := maxf(24.0, (y1 - y0) * vis / total)
		var top := y0 + (y1 - y0 - h) * float(base - scroll_rows) / float(base)
		draw_line(Vector2(x, top), Vector2(x, top + h), Color(1, 0.85, 0.6, 0.45 if scroll_rows > 0 else 0.28), 5.0, true)

	# ---------- 繪圖 ----------

	func _draw() -> void:
		var font := get_theme_default_font()
		_draw_forge_bg()
		# 每關自己的氣氛粒子（stage_style 的 ambient，存在外層舞台上）
		var amb = get_parent().get("ambient") if get_parent() != null else null
		if amb is String and amb != "":
			Ambient.paint(self, amb, size, t)
		match kind:
			"forge":
				_draw_log(font)
				if _xt_on():
					_draw_xt(font, Rect2(36, size.y - 214, size.x - 72, 190))
				elif _graph_on():
					_draw_mini_graph(font, Rect2(36, size.y - 214, size.x - 72, 190))
			"speed":
				_draw_speed(font)
			"tune":
				_draw_tune(font)
		for p in particles:
			UITheme.dot(self, p.p, p.r * p.life, Color(p.c.r, p.c.g, p.c.b, p.life))

	## 熔爐的背景：底部的火光和往上飄的火星
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		var heat := 0.16 + 0.04 * sin(t * 2.0) + (0.02 * mini(streak, 8) if kind == "speed" else 0.0)
		draw_polygon(PackedVector2Array([Vector2(0, h * 0.55), Vector2(w, h * 0.55), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color(1, 0.5, 0.2, 0.0), Color(1, 0.5, 0.2, 0.0), Color(1, 0.45, 0.15, heat), Color(1, 0.45, 0.15, heat)]))
		var n := 26 + (3 * mini(streak, 8) if kind == "speed" else 0)
		for i in n:
			var sp := 0.05 + 0.04 * fposmod(i * 0.371, 1.0)
			var y := h - fposmod(t * sp + i * 0.137, 1.0) * h
			var x := fposmod(i * 0.618, 1.0) * w + 12.0 * sin(t * 1.3 + i)
			var a := clampf((y / h) * 0.9, 0.0, 0.8)
			UITheme.dot(self, Vector2(x, y), 1.6 + fposmod(i * 0.29, 1.0) * 1.6, Color(1, 0.65, 0.3, a))
		# 失誤時整個畫面閃一下紅光
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	## 鍛造紀錄：原方程式＋每一步寫下的算式
	func _draw_log(font: Font) -> void:
		var cx := size.x / 2.0
		draw_string(font, Vector2(22, 34), log_title, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 0.8, 0.6, 0.7))
		var eql := _eq_lines()
		var acc := 0.0
		for i in eql.size():
			# 開場：題目逐字出現（intro = 目前出現到第幾個字）
			var rev := -1.0 if intro < 0.0 else intro - acc
			acc += MathLabel.glyph_count(eql[i])
			if intro >= 0.0 and rev <= 0.0:
				break
			# 括號開頭的那一行是給的數值（例如 log 2 ≈ 0.3010）：字小一點、顏色淡一點
			var given := eql[i].begins_with("（")
			MathLabel.draw_on(self, font, cx, _eq_y(i) - (4.0 if given else 0.0), eql[i],
				_fit_fs(font, eql[i], UITheme.fs(20) if given else UITheme.fs(24)), Color(1, 0.9, 0.7, 0.85) if given else GOLD, rev)
		var sep_y := _eq_y(eql.size() - 1) + 22.0 + _extra(eql[-1], _eq_fs(eql[-1])).y
		# 分隔線放在「題目最下緣」和「第一行紀錄最上緣」的正中間（有上標、分數時兩邊都會長高，不會壓到字）
		if intro < 0.0 and not lines.is_empty():
			var f0 := _first_shown()
			if f0 < lines.size():
				var fs_e := _eq_fs(eql[-1])
				var bot := _eq_y(eql.size() - 1) + MathLabel.line_extent(eql[-1], fs_e).y
				var tx: String = lines[f0].text
				var top := _line_y(f0) - MathLabel.line_extent(tx, _fit_fs(font, tx, UITheme.fs(20))).x
				if f0 > 0:
					top = minf(top, _top_y() - 30.0)      # 上面還有「⋯」
				sep_y = (bot + top) / 2.0
		var sep_k := 1.0 if intro < 0.0 else clampf(intro / maxf(1.0, intro_total()), 0.0, 1.0)
		var half := (size.x - 120.0) / 2.0 * sep_k
		draw_line(Vector2(cx - half, sep_y), Vector2(cx + half, sep_y), Color(1, 0.7, 0.4, 0.25), 1.0)
		if intro >= 0.0:
			return
		var first := _first_shown()
		if first > 0:
			draw_string(font, Vector2(cx - 20, _top_y() - 16), "⋯", HORIZONTAL_ALIGNMENT_CENTER, 40, UITheme.fs(17), Color(1, 1, 1, 0.4))
		var cut := false
		for i in range(first, lines.size()):
			var ln: Dictionary = lines[i]
			var a := clampf((t - float(ln.born)) / 0.35, 0.0, 1.0)
			var y := _line_y(i) + (1.0 - a) * 10.0
			# 往上捲的時候，超出下緣的行先不畫（下面顯示「往下還有」）
			if scroll_rows > 0 and _line_y(i) + _extra(ln.text, _fit_fs(font, ln.text, UITheme.fs(20))).y + 10.0 > _bottom_limit() - (0.0 if done else 30.0):
				cut = true
				break
			var last := i == lines.size() - 1
			var c := Color(1, 0.95, 0.85, a) if not (done and last) else Color(GOLD.r, GOLD.g, GOLD.b, a)
			if last and t - float(ln.born) < 0.8:
				var g := 1.0 - (t - float(ln.born)) / 0.8
				draw_rect(Rect2(40, y - 24, size.x - 80, 34), Color(1, 0.6, 0.25, 0.12 * g))
			MathLabel.draw_on(self, font, cx, y, ln.text, _fit_fs(font, ln.text, UITheme.fs(20)), c)
		_draw_log_bar()
		if scroll_rows > 0:
			if cut or not done:
				var yb := _bottom_limit() - 20.0
				draw_string(font, Vector2(0, yb), "▼ 往下拉，回到最新的步驟", HORIZONTAL_ALIGNMENT_CENTER, size.x, UITheme.fs(15),
					Color(1, 0.85, 0.6, 0.6 + 0.2 * sin(t * 3.0)))
		elif not done and cur_name != "" and live_fill != "":
			_draw_live_fill(font, _line_y(lines.size()))
		elif not done and cur_name != "":
			var y2 := _line_y(lines.size())
			var pa := 0.4 + 0.3 * sin(t * 4.0)
			draw_string(font, Vector2(0, y2), "▸ 正在%s：%s ⋯" % [work_word, cur_name], HORIZONTAL_ALIGNMENT_CENTER, size.x, UITheme.fs(17),
				Color(FIRE.r, FIRE.g, FIRE.b, pa))
		if done:
			var k := clampf((t - done_t) / 0.4, 0.0, 1.0)
			var sc := 1.4 - 0.4 * k
			var txt := work_word + "完成！"
			var fs := UITheme.fs(20 * sc)
			# 放在右上角，和「鍛造紀錄」同一列，才不會壓到第一行算式
			draw_string(font, Vector2(size.x - 236, 36), txt, HORIZONTAL_ALIGNMENT_RIGHT, 220, fs, Color(GOLD.r, GOLD.g, GOLD.b, k))

	## 正在作答的填空：一個發光的框，裡面是這一步的式子和空格（目前的空格是金色的 ▢）
	func _draw_live_fill(font: Font, y_top: float) -> void:
		var cx := size.x / 2.0
		var rows := live_fill.split("\n")
		var h := _live_h() - 10.0
		var box := Rect2(40, y_top - 20, size.x - 80, h)     # 上緣離分隔線留一點空隙
		var pulse := 0.55 + 0.3 * sin(t * 4.0)
		draw_style_box(UITheme.boxc(Color(FIRE.r, FIRE.g, FIRE.b, 0.10), 12, Color(FIRE.r, FIRE.g, FIRE.b, pulse), 2, 0), box)
		var head := _live_head()
		var hfs := UITheme.fs(15)
		while hfs > UITheme.fs(12) and _mw(font, head, hfs) > box.size.x - 24.0:
			hfs -= 1
		# 標題裡有分數時（例如 log (1/3^{20})）往下多留空間，免得和框線、下面的算式疊在一起
		var he := _extra(head, UITheme.fs(15))
		if he.x > 0.0:
			he.x += 6.0
		MathLabel.draw_on(self, font, box.position.x + 12.0 + _mw(font, head, hfs) / 2.0, box.position.y + 20.0 + he.x, head, hfs,
			Color(1, 0.85, 0.6, 0.95))
		var y := box.position.y + 30.0 + he.x + he.y
		for ln in rows:
			var fs := _fit_fs(font, ln, UITheme.fs(24))
			var e := _extra(ln, fs)
			y += e.x + 26.0
			MathLabel.draw_on(self, font, cx, y, ln, fs, Color(1, 0.95, 0.85))
			y += e.y + 14.0

	static func _ftext(v: float) -> String:
		for d in [1, 2, 3, 4, 5, 6, 8, 9]:
			var n: float = v * d
			if absf(n - roundf(n)) < 1e-6:
				var ni := int(roundf(n))
				if d == 1:
					return str(ni).replace("-", "−")
				return ("−" if ni < 0 else "") + "%d/%d" % [absi(ni), d]
		return UITheme.num(v, 2).replace("-", "−")

	## 太長的一行縮小字級，免得超出畫面
	func _fit_fs(font: Font, markup: String, fs: int) -> int:
		var w := _mw(font, markup, fs)
		var room := size.x - 56.0
		if w <= room or w <= 0.0:
			return fs
		return maxi(UITheme.fs(12), int(floor(fs * room / w)))

	## 數學式的寬度
	static func _mw(font: Font, markup: String, fs: int) -> float:
		return MathLabel.text_width(font, markup, fs)

	static func _quad_roots(A: float, B: float, C: float) -> Array:
		var D := B * B - 4.0 * A * C
		if D < -1e-9:
			return []
		if absf(D) <= 1e-9:
			return [-B / (2.0 * A)]
		var sq := sqrt(maxf(D, 0.0))
		return [(-B - sq) / (2.0 * A), (-B + sq) / (2.0 * A)]

	## 畫 y = At² + Bt + C 在 rect 裡（region 以右是合格區）；回傳根的螢幕位置
	func _plot_quad(font: Font, rect: Rect2, A: float, B: float, C: float, region: float, closed: bool,
			label: String, xr: Vector2, yr: Vector2, show_rej: bool, labels := true) -> void:
		var to_px := func(p: Vector2) -> Vector2:
			return Vector2(rect.position.x + (p.x - xr.x) / (xr.y - xr.x) * rect.size.x,
				rect.position.y + rect.size.y - (p.y - yr.x) / (yr.y - yr.x) * rect.size.y)
		draw_style_box(UITheme.boxc(Color(0.05, 0.03, 0.06, 0.55), 12, Color(1, 0.7, 0.4, 0.25), 1, 0), rect.grow(6))
		# 合格區
		var rx: float = to_px.call(Vector2(region, 0)).x
		rx = clampf(rx, rect.position.x, rect.end.x)
		draw_rect(Rect2(rx, rect.position.y, rect.end.x - rx, rect.size.y), Color(0.43, 0.9, 0.63, 0.08))
		draw_dashed_line(Vector2(rx, rect.position.y), Vector2(rx, rect.end.y), Color(0.43, 0.9, 0.63, 0.6), 1.5, 6.0)
		MathLabel.draw_on(self, font, rx + 8 + _mw(font, label, UITheme.fs(13)) / 2.0, rect.position.y + 18, label, UITheme.fs(13), Color(0.6, 1, 0.75, 0.9))
		# 座標軸
		var y0: float = to_px.call(Vector2(0, 0)).y
		if y0 >= rect.position.y and y0 <= rect.end.y:
			draw_line(Vector2(rect.position.x, y0), Vector2(rect.end.x, y0), Color(1, 1, 1, 0.5), 1.5)
			preload("math_text.gd").draw_text(self, font, Vector2(rect.end.x - 14, y0 - 6), "t", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 1, 1, 0.7))
		var x0: float = to_px.call(Vector2(0, 0)).x
		if x0 >= rect.position.x and x0 <= rect.end.x:
			draw_line(Vector2(x0, rect.position.y), Vector2(x0, rect.end.y), Color(1, 1, 1, 0.25), 1.0)
		# 拋物線
		# 超出框的部分不畫（不要在框邊拉出一條平線）
		var segs := []
		var pts := PackedVector2Array()
		for i in 241:
			var tt := lerpf(xr.x, xr.y, i / 240.0)
			var yy := A * tt * tt + B * tt + C
			if yy < yr.x or yy > yr.y:
				if pts.size() >= 2:
					segs.append(pts)
				pts = PackedVector2Array()
				continue
			pts.append(to_px.call(Vector2(tt, yy)))
		if pts.size() >= 2:
			segs.append(pts)
		for sg in segs:
			draw_polyline(UITheme.thin(sg), Color(FIRE.r, FIRE.g, FIRE.b, 0.2), 8.0)
			draw_polyline(UITheme.thin(sg), FIRE, 2.5, true)
		# 根
		for root in _quad_roots(A, B, C):
			var p: Vector2 = to_px.call(Vector2(root, 0))
			if p.x < rect.position.x - 2 or p.x > rect.end.x + 2:
				continue
			var ok: bool = root > region + 1e-9 or (closed and absf(root - region) < 1e-9)
			var rej := show_rej and (not ok or _in_rejected(root))
			if rej:
				UITheme.dot(self, p, 7.0, Color(1, 0.35, 0.45, 0.35))
				draw_line(p + Vector2(-7, -7), p + Vector2(7, 7), Color(1, 0.4, 0.5), 2.5)
				draw_line(p + Vector2(-7, 7), p + Vector2(7, -7), Color(1, 0.4, 0.5), 2.5)
			else:
				UITheme.dot(self, p, 10.0 + 1.5 * sin(t * 4.0), Color(GOLD.r, GOLD.g, GOLD.b, 0.25))
				UITheme.dot(self, p, 5.5, GOLD)
			if labels:
				preload("math_text.gd").draw_text(self, font, p + Vector2(-40, 24), "t = " + _ftext(root), HORIZONTAL_ALIGNMENT_CENTER, 80, UITheme.fs(13),
					Color(1, 0.5, 0.55) if rej else Color(1, 0.95, 0.8))

	func _in_rejected(v: float) -> bool:
		for x in rejected:
			if absf(float(x) - v) < 1e-6:
				return true
		return false

	## 鍛造台下方的小圖：t 的二次函數
	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if graph.get("vieta", false):
			_draw_vieta(font, rect)
			return
		var c: Array = graph.coef
		var A: float = c[0]
		var B: float = c[1]
		var C: float = c[2]
		var rs := _quad_roots(A, B, C)
		var region: float = graph.get("region", 0.0)
		var lo := region
		var hi := region
		for root in rs:
			lo = minf(lo, root)
			hi = maxf(hi, root)
		lo = minf(lo, 0.0)
		var pad := maxf(0.6, 0.18 * (hi - lo))
		var xr := Vector2(lo - pad, hi + pad)
		var ymin := INF
		var ymax := -INF
		for i in 61:
			var tt := lerpf(xr.x, xr.y, i / 60.0)
			var yy := A * tt * tt + B * tt + C
			ymin = minf(ymin, yy)
			ymax = maxf(ymax, yy)
		ymin = minf(ymin, 0.0)
		ymax = maxf(ymax, 0.0)
		var yp := 0.15 * (ymax - ymin)
		var yr := Vector2(ymin - yp, ymax + yp)
		var show_rej: bool = graph.has("filter") and step > int(graph.filter)
		preload("math_text.gd").draw_text(self, font, rect.position + Vector2(4, -10), "t 的二次函數", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(1, 0.8, 0.6, 0.7))
		_plot_quad(font, rect, A, B, C, region, graph.get("closed", false), graph.get("label", "t > 0"), xr, yr, show_rej)

	## 根與係數的題目：下方不畫拋物線，改成「根與係數的關係式」提示卡
	## graph 寫 {"vieta": true, "coef": [A, B, C], "after": 第幾步之後出現, "map": "t₁ = 2^{α}、t₂ = 2^{β}"}
	func _draw_vieta(font: Font, rect: Rect2) -> void:
		var ML := preload("math_text.gd")
		var c: Array = graph.coef
		ML.draw_text(self, font, rect.position + Vector2(4, -10), "根與係數", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(1, 0.8, 0.6, 0.7))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.05, 0.03, 0.55)
		sb.border_color = Color(FIRE.r, FIRE.g, FIRE.b, 0.45)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(14)
		sb.anti_aliasing = true
		draw_style_box(sb, rect)
		var cx := rect.position.x + rect.size.x / 2.0
		var dim := Color(1, 0.88, 0.75, 0.85)
		var head := "At^{2} + Bt + C = 0 的兩根 t₁、t₂"
		var mp := String(graph.get("map", ""))
		if mp != "":
			head = mp + " 是 At^{2} + Bt + C = 0 的兩根"
		var fs := UITheme.fs(17)
		var y := rect.position.y + 34.0
		ML.draw_on(self, font, cx, y, head, fs, dim)
		y += 50.0
		ML.draw_on(self, font, cx, y, "兩根之和　t₁ + t₂ = −\\frac{B}{A}", UITheme.fs(20), Color.WHITE)
		y += 50.0
		ML.draw_on(self, font, cx, y, "兩根之積　t₁t₂ = \\frac{C}{A}", UITheme.fs(20), Color.WHITE)
		y += 40.0
		ML.draw_on(self, font, cx, y, "這一題：A = %s，B = %s，C = %s" % [_vnum(c[0]), _vnum(c[1]), _vnum(c[2])], fs, GOLD)

	static func _vnum(v) -> String:
		var f := float(v)
		var t := str(int(f)) if is_equal_approx(f, roundf(f)) else str(snappedf(f, 0.01))
		return t.replace("-", "−")

	## 速算爐：大大的題目＋進度＋連對
	func _draw_speed(font: Font) -> void:
		var cx := size.x / 2.0
		draw_string(font, Vector2(22, 34), speed_title, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 0.8, 0.6, 0.7))
		var gap := 30.0
		var x0 := cx - gap * (sp_total - 1) / 2.0
		for i in sp_total:
			var p := Vector2(x0 + gap * i, 78)
			if i < sp_i or (done and i <= sp_i):
				UITheme.dot(self, p, 8.0, FIRE)
			elif i == sp_i:
				UITheme.dot(self, p, 11.0, Color(1, 1, 1, 0.15))
				UITheme.dot(self, p, 7.0, Color.WHITE)
			else:
				UITheme.dot(self, p, 6.0, Color(1, 1, 1, 0.2))
		if done:
			MathLabel.draw_on(self, font, cx, size.y * 0.42, "全部完成！", UITheme.fs(40), GOLD)
			return
		var shake := 0.0
		var ma := clampf(1.0 - (t - miss_t) / 0.4, 0.0, 1.0)
		if ma > 0.0:
			shake = sin(t * 60.0) * 10.0 * ma
		var pop := clampf(1.0 - (t - hit_t) / 0.3, 0.0, 1.0)
		var y := size.y * 0.42
		draw_string(font, Vector2(0, y - 70), "第 %d 題" % (sp_i + 1), HORIZONTAL_ALIGNMENT_CENTER, size.x, UITheme.fs(17), Color(1, 1, 1, 0.55))
		MathLabel.draw_on(self, font, cx + shake, y, sp_eq, _fit_fs(font, sp_eq, UITheme.fs(40)), Color(1, 0.97, 0.9))
		if streak >= 2:
			var fc := GOLD if streak >= 4 else FIRE
			draw_string(font, Vector2(0, y + 70), "連對 ×%d" % streak, HORIZONTAL_ALIGNMENT_CENTER, size.x, UITheme.fs(24 + 8 * pop),
				Color(fc.r, fc.g, fc.b, 0.9))

	## 參數調頻：大張的 t 平面
	func _draw_tune(font: Font) -> void:
		var c: Array = rd.coef
		var cx := size.x / 2.0
		var ask: String = rd.get("ask", "")
		# 開場：題目和問句逐字出現，圖等開場結束才畫
		if intro >= 0.0:
			var n_eq := float(MathLabel.glyph_count(rd.eq))
			MathLabel.draw_on(self, font, cx, 42, rd.eq, UITheme.fs(24), GOLD, intro)
			if ask != "" and intro > n_eq:
				MathLabel.draw_on(self, font, cx, 78, ask, _fit_fs(font, ask, UITheme.fs(17)), Color(1, 0.95, 0.88), intro - n_eq)
			return
		# 計算步驟：內容可能比畫面高，整塊往上捲
		MathLabel.set_xform(self, Transform2D(0.0, Vector2(0, -roundf(scroll))))
		# 計算步驟：參數已經不重要了，拋物線改成在「兩根都合格」的範圍內來回的示意圖
		var demo := tune_calc and not is_nan(calc_lo)
		var pv := lerpf(calc_lo, calc_hi, 0.5 + 0.5 * sin(t * 0.9)) if demo else tp
		var A: float = c[0][0] + c[0][1] * pv
		var B: float = c[1][0] + c[1][1] * pv
		var C: float = c[2][0] + c[2][1] * pv
		MathLabel.draw_on(self, font, cx, 42, rd.eq, UITheme.fs(24), GOLD)
		var top := 76.0
		if ask != "":
			MathLabel.draw_on(self, font, cx, 78, ask, _fit_fs(font, ask, UITheme.fs(17)), Color(1, 0.95, 0.88))
			top = 110.0
		var pname: String = rd.param.name
		var teq: String = rd.teq.replace(pname, "[color=#ffb454]%s[/color]" % pname)
		var tail := "" if tune_calc else "　（%s = %s）" % [pname, UITheme.num(tp, 2).replace("-", "−")]
		MathLabel.draw_on(self, font, cx, top, "令 %s：" % rd.get("tdef", "t = 2^{x}") + teq + tail, UITheme.fs(17), Color(1, 0.9, 0.8, 0.75))
		var rect := Rect2(34, top + 28.0, size.x - 68, 190.0 if tune_calc else size.y - top - 54.0)
		var view: Dictionary = rd.view
		_plot_quad(font, rect, A, B, C, float(rd.region), false, rd.region_label, view.x, view.y, true, not demo)
		var n := 0
		for root in _quad_roots(A, B, C):
			if root > float(rd.region) + 1e-9:
				n += 1
		if demo:
			preload("math_text.gd").draw_text(self, font, Vector2(rect.end.x - 330, rect.position.y + 40), "示意：兩個 t 都落在亮區",
				HORIZONTAL_ALIGNMENT_RIGHT, 320, UITheme.fs(17), Color(1, 0.9, 0.5, 0.9))
		else:
			draw_string(font, Vector2(rect.end.x - 220, rect.position.y + 44), "%s：%d 個" % [rd.unit, n],
				HORIZONTAL_ALIGNMENT_RIGHT, 210, UITheme.fs(24), Color(1, 0.9, 0.5))
		if tune_calc:
			var y0 := rect.end.y + 44.0
			for i in lines.size():
				var ln: Dictionary = lines[i]
				var a := clampf((t - float(ln.born)) / 0.35, 0.0, 1.0)
				MathLabel.draw_on(self, font, cx, y0 + 38.0 * i + (1.0 - a) * 10.0, ln.text, _fit_fs(font, ln.text, UITheme.fs(20)),
					Color(1, 0.95, 0.85, a))
			var yl := y0 + 38.0 * lines.size()
			var end_y := yl
			if not done and cur_name != "" and live_fill != "":
				_draw_live_fill(font, yl)
				end_y = yl - 20.0 + _live_h()
			elif not done and cur_name != "":
				var pa := 0.4 + 0.3 * sin(t * 4.0)
				draw_string(font, Vector2(0, yl), "▸ 正在%s：%s ⋯" % [work_word, cur_name],
					HORIZONTAL_ALIGNMENT_CENTER, size.x, UITheme.fs(17), Color(FIRE.r, FIRE.g, FIRE.b, pa))
				end_y = yl + 14.0
			# 內容變長（多了一行或出現填空）：自動捲到最下面
			if end_y > _content_h + 1.0:
				_content_h = end_y
				scroll_to = _max_scroll()
			else:
				_content_h = end_y
				scroll_to = minf(scroll_to, _max_scroll())
		MathLabel.set_xform(self, Transform2D.IDENTITY)
		# 捲軸：內容超出畫面時，右邊畫一條細細的位置指示
		var mx := _max_scroll() if tune_calc else 0.0
		if mx > 1.0:
			var track := size.y - 24.0
			var bar_h := maxf(40.0, track * size.y / (size.y + mx))
			var by := 12.0 + (track - bar_h) * clampf(scroll / mx, 0.0, 1.0)
			draw_style_box(UITheme.boxc(Color(1, 0.85, 0.6, 0.35), 3, Color(0, 0, 0, 0), 0, 0), Rect2(size.x - 9, by, 5, bar_h))
