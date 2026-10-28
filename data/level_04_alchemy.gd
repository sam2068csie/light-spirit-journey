extends "level_03_scale.gd"
## 第四大關「對數鍊金術」（對應講義 重點一：對數基本性質）
## 用法：主選單會自動開啟它。需要同資料夾的 level_03_scale.gd、level_02_forge.gd、level_01_light_bridge.gd
## （共用引擎）與 level04_bank.gd（題庫）。
##
## 沿用前兩關「一步一步算」的方式（選擇、數字鍵盤填空、數線），再加上兩種新步驟：
##   rule   施放法則：從對數律秘笈裡挑出這一步該用的法則，選對了就在鍊金陣裡施放
##   chain  連鎖之環：依序點選 log_{a} b，讓上一環的真數接上下一環的底數，鍊子只剩頭和尾
## 以及「鍊金速算」：連續算出 log 的值、合併相加相減。

const Bank4 := preload("level04_bank.gd")
const CHAPTERS4 := [
	{"ch": 1, "name": "第一章．鍊金基礎", "topic": "定義、有意義的條件與對數律", "color": Color("c792ff")},
	{"ch": 2, "name": "第二章．大師的配方", "topic": "互換、代換、指對互換與應用", "color": Color("6ee7c8")},
]
const VIOLET := Color("c792ff")

# 連鎖
var chain_btns: Array = []
var chain_preview: MathLabel
# 數量級實驗室
var mag_i := 0               # 第幾個任務
var mag_phase := 0           # 0 任務、1 小測驗
var mag_q := 0
var mag_s := 0.0             # 目前的狀態：喇叭數量、規模或 pH
var mag_quiz_wrong := 0
var mag_info: MathLabel


func level_id() -> String:
	return "L4"

func level_title() -> String:
	return "對數鍊金術"

func level_subtitle() -> String:
	return "對數的定義與運算性質"

func level_chapters() -> Array:
	return CHAPTERS4

func bank_slots() -> Array:
	return Bank4.slots()

func stage_style() -> Dictionary:
	return {"sky_top": Color("1c1233"), "sky_bot": Color("0f1a2e"), "scenery": "none"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．大師的配方", "button": "進入大師的配方  ▶",
		"text": "大師的四帖配方：\n\n" \
			+ "・a^{log_{c} b} = b^{log_{c} a}　底數和真數互換\n" \
			+ "・代號問題：換底 → 質因數分解 → 連鎖\n" \
			+ "・卡住了？指數式和對數式互換\n" \
			+ "・地震、分貝、酸鹼值：k 倍 ⇔ log 加上 log k\n\n" \
			+ "秘笈裡的法則，全部都會派上用場！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = AlchemyView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.log_title = "鍊成紀錄"
		fview.work_word = "鍊成"
		fview.speed_title = "鍊金速算"
		(fview as ScaleView).line_toggled.connect(func(): Game.of(self).play("bell", Game.semi(7), -9.0))


func _av() -> AlchemyView:
	return fview as AlchemyView


# ================= 新的步驟 =================

func _forge_step() -> void:
	super()
	if si >= steps.size():
		return
	var st: Dictionary = steps[si]
	match st.kind:
		"rule":
			_clear(rank_box)
			rank_box.visible = false
			keypad_on = false
			var opts := []
			var correct := 0
			for i in st.rules.size():
				var rl: Dictionary = Bank4.RULES[st.rules[i]]
				opts.append("[color=#%s]%s[/color]　%s" % [VIOLET.to_html(false), rl.name, rl.f])
				if st.rules[i] == st.correct:
					correct = i
			_show_question(shuffle_q({"q": "✦ " + st.q, "options": opts, "correct": correct, "why": st.why,
				"nudge": st.nudge, "tag": st.tag, "cols": 1}))
			_step_text()
		"chain":
			_clear(predict_box)
			predicting = false
			keypad_on = false
			rank_box.visible = true
			_clear(rank_box)
			task_label.visible = true
			task_label.text = st.q
			go_btn.visible = true
			go_btn.disabled = true
			_build_chain(st)


func _custom_type(t: String) -> bool:
	return t == "mag" or super(t)


func _custom_steps() -> Array:
	if r.type == "mag":
		var names := []
		for i in r.missions.size():
			names.append("任務%d" % (i + 1))
		names.append("測驗")
		return names
	return super()


func _custom_step_index() -> int:
	if r.type == "mag":
		return mag_i if mag_phase == 0 else r.missions.size()
	return super()


func _custom_answered() -> void:
	if r.type == "mag":
		_mag_answered()
		return
	super()


func _custom_go() -> void:
	if r.type == "mag":
		_mag_lock()
		return
	if r.type == "forge" and si < steps.size() and steps[si].kind == "chain":
		_chain_submit()
		return
	super()


func _step_done(st: Dictionary, why: String) -> void:
	if st.kind == "rule":
		_av().cast(Bank4.RULES[st.correct].f)
		Game.of(self).play("bell", Game.semi(12), -8.0)
	super(st, why)


func _custom_start() -> void:
	# 先清掉上一段旅程的鍊金台，再開始（第一步就可能是連鎖、羅盤或守門）
	_ensure_fview()
	_av().reset_alchemy()
	super()
	if r.type == "mag":
		_mag_begin()


func _custom_reveal(msg: String) -> void:
	for j in range(si, steps.size()):
		if steps[j].kind == "chain":
			_av().begin_chain(steps[j])
			_av().chain_seq = chain_solution(steps[j])
			_av().chain_lock = true
	super(msg)


# ---------- 連鎖之環 ----------

func _build_chain(st: Dictionary) -> void:
	go_btn.text = "確認"
	_av().begin_chain(st)
	chain_btns = []
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.box(Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.08), 14,
		Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.4), 1, 6))
	rank_box.add_child(card)
	chain_preview = MathLabel.new()
	chain_preview.font_size = UITheme.fs(20)
	chain_preview.max_width = 320
	chain_preview.align_center = true
	card.add_child(chain_preview)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	rank_box.add_child(grid)
	for i in st.items.size():
		var b := MathLabel.make_button(st.items[i].text, 19, Vector2(0, 40))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.set_meta("silent", true)
		var idx: int = i
		b.pressed.connect(func(): _chain_pick(idx))
		grid.add_child(b)
		chain_btns.append(b)
	if st.items.size() % 2 == 1:
		grid.add_child(Control.new())
	var reset := UITheme.ghost_button("重新接", 15)
	for st_name in ["normal", "hover", "pressed"]:
		var sb: StyleBox = reset.get_theme_stylebox(st_name).duplicate()
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		reset.add_theme_stylebox_override(st_name, sb)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reset.pressed.connect(func():
		_av().chain_seq = []
		_refresh_chain())
	rank_box.add_child(reset)
	_refresh_chain()


func _chain_pick(idx: int) -> void:
	var av := _av()
	if av.chain_seq.has(idx) or av.chain_lock:
		return
	av.chain_seq.append(idx)
	var ok := av.joint_ok(av.chain_seq.size() - 1)
	if ok:
		Game.of(self).play("bell", Game.semi(Game.scale_semi(2 + av.chain_seq.size())), -8.0)
	else:
		Game.of(self).play("bonk", 1.0, -10.0)
	av.link_flash(av.chain_seq.size() - 1, ok)
	_refresh_chain()


func _refresh_chain() -> void:
	var st: Dictionary = steps[si]
	var av := _av()
	var parts := PackedStringArray()
	for k in av.chain_seq.size():
		var c := UITheme.GOOD if av.joint_ok(k) else UITheme.BAD
		parts.append("[color=#%s]%s[/color]" % [c.to_html(false), st.items[av.chain_seq[k]].text])
	for k in st.items.size() - av.chain_seq.size():
		parts.append("[color=#%s]□[/color]" % UITheme.TEXT_DIM.to_html(false))
	chain_preview.text = " · ".join(parts)
	for i in chain_btns.size():
		var b: Button = chain_btns[i]
		b.disabled = av.chain_seq.has(i)
		b.modulate = Color(1, 1, 1, 0.35) if av.chain_seq.has(i) else Color.WHITE
	go_btn.disabled = av.chain_seq.size() < st.items.size()


func _chain_submit() -> void:
	var st: Dictionary = steps[si]
	var av := _av()
	if av.chain_seq.size() < st.items.size():
		return
	if chain_valid(st, av.chain_seq):
		Game.of(self).sfx("correct")
		av.chain_lock = true
		av.chain_done()
		# 紀錄照學生接的順序寫
		var st2: Dictionary = st.duplicate()
		var texts := PackedStringArray()
		for k in av.chain_seq:
			texts.append(st.items[k].text)
		var first: String = st.items[av.chain_seq[0]].a
		var last: String = st.items[av.chain_seq[-1]].b
		st2.line = " · ".join(texts) + " = log_{%s} %s" % [first, last] + (" = 1" if first == last else "")
		_step_done(st2, "")
		return
	av.chain_seq = []
	_refresh_chain()
	_wrong(st, "鍊子斷掉了（紅色的接口）：上一環的真數要等於下一環的底數。\n提示：" + st.nudge)


## 這個順序接得起來嗎（closed 還要繞回起點）
static func chain_valid(st: Dictionary, seq: Array) -> bool:
	var items: Array = st.items
	if seq.size() != items.size():
		return false
	for k in range(1, seq.size()):
		if items[seq[k - 1]].b != items[seq[k]].a:
			return false
	if st.closed and items[seq[-1]].b != items[seq[0]].a:
		return false
	return true


## 找一個接得起來的順序（示範、測試用）
static func chain_solution(st: Dictionary) -> Array:
	var n: int = st.items.size()
	# 先試題目紀錄裡寫在最前面的那一環
	var starts: Array = range(n)
	var line: String = st.get("line", "")
	starts.sort_custom(func(x, y):
		var px := line.find(st.items[x].text)
		var py := line.find(st.items[y].text)
		return (px if px >= 0 else 9999) < (py if py >= 0 else 9999))
	for start in starts:
		var seq := [start]
		var used := {start: true}
		while seq.size() < n:
			var nxt := -1
			for j in n:
				if not used.has(j) and st.items[seq[-1]].b == st.items[j].a:
					nxt = j
					break
			if nxt < 0:
				break
			seq.append(nxt)
			used[nxt] = true
		if chain_valid(st, seq):
			return seq
	return range(n)


# ---------- 數量級實驗室 ----------

func _mag_begin() -> void:
	steps = []
	si = 0
	mag_i = 0
	mag_phase = 0
	mag_q = 0
	mislocks = 0
	mag_quiz_wrong = 0
	mag_s = float(r.start)
	_av().mag_setup(r, mag_s)
	energy_label.visible = false     # 這裡按錯不扣能量
	rank_box.visible = true
	_clear(rank_box)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.box(Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.08), 14,
		Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.4), 1, 10))
	rank_box.add_child(card)
	mag_info = MathLabel.new()
	mag_info.font_size = UITheme.fs(19)
	mag_info.max_width = 320
	mag_info.align_center = true
	card.add_child(mag_info)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.columns = mini(r.ops.size(), 4)
	rank_box.add_child(grid)
	for i in r.ops.size():
		var b := MathLabel.make_button(r.ops[i][0], 22, Vector2(0, 52))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.set_meta("silent", true)
		var idx: int = i
		b.pressed.connect(func(): _mag_op(idx))
		grid.add_child(b)
	var tip := Label.new()
	tip.text = "調到目標之後，按「就是這裡！」"
	tip.add_theme_font_size_override("font_size", UITheme.fs(14))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(tip)
	task_label.visible = true
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "就是這裡！"
	_mag_task()
	_mag_refresh()


func _mag_task() -> void:
	task_label.text = "任務 %d／%d：%s" % [mag_i + 1, r.missions.size(), r.missions[mag_i].text]
	_step_text()


func _mag_op(idx: int) -> void:
	if busy or mag_phase != 0:
		return
	var ns := AlchemyView.mag_apply(r, mag_s, idx)
	if is_nan(ns):
		Game.of(self).play("bonk", 1.0, -10.0)
		_hint("到頭了，不能再" + ("大" if r.ops[idx][1] in ["mul", "add"] and float(r.ops[idx][2]) > 0 else "小") + "了。", "info")
		return
	mag_s = ns
	var k := AlchemyView.mag_exp(r, mag_s)
	Game.of(self).play("bell", Game.semi(Game.scale_semi(clampi(int(round(k * 1.4)) + 4, 0, 14))), -8.0)
	_av().mag_set(mag_s)
	_mag_refresh()


func _mag_refresh() -> void:
	if mag_info != null and is_instance_valid(mag_info):
		mag_info.text = AlchemyView.mag_readout(r, mag_s)


func _mag_lock() -> void:
	if busy or mag_phase != 0:
		return
	var m: Dictionary = r.missions[mag_i]
	if absf(AlchemyView.mag_measure(r, mag_s) - float(m.target)) < 0.15:
		Game.of(self).sfx("correct")
		fview.burst_center()
		mag_i += 1
		if mag_i >= r.missions.size():
			mag_phase = 1
			rank_box.visible = false
			go_btn.visible = false
			task_label.visible = false
			_show_question(shuffle_q(r.quiz[0]))
			_hint("✓ " + m.why, "good")
			return
		_mag_task()
		_hint("✓ " + m.why, "good")
		return
	mislocks += 1
	Game.of(self).sfx("wrong")
	_record(r.get("tag", "loglaw_apply"))
	fview.miss()
	story_label.visible = false
	_hint("還沒到目標喔。\n提示：" + m.nudge, "bad")


func _mag_answered() -> void:
	mag_quiz_wrong += predict_tries - 1
	var why: String = cur_q.get("why", "")
	mag_q += 1
	if mag_q < r.quiz.size():
		_show_question(shuffle_q(r.quiz[mag_q]))
		_hint("✓ " + why, "good")
		return
	_finish_round(mislocks == 0 and mag_quiz_wrong == 0, 1 + mislocks + mag_quiz_wrong)


## 從 s 走到 target 的按鈕順序（示範、測試用）
static func mag_solve(rd: Dictionary, s: float, target: float) -> Array:
	var queue := [[s, []]]
	var seen := {}
	while not queue.is_empty():
		var cur: Array = queue.pop_front()
		var st: float = cur[0]
		if absf(AlchemyView.mag_measure(rd, st) - target) < 0.15:
			return cur[1]
		if cur[1].size() >= 12:
			continue
		for i in rd.ops.size():
			var ns := AlchemyView.mag_apply(rd, st, i)
			if is_nan(ns):
				continue
			var key := snappedf(ns, 0.001)
			if seen.has(key):
				continue
			seen[key] = true
			var path: Array = cur[1].duplicate()
			path.append(i)
			queue.append([ns, path])
	return []


# ---------- 鍊金速算 ----------

func _speed_begin() -> void:
	problems = _speed_gen(r.gen, int(r.count))
	sp_i = 0
	sp_wrong = 0
	streak = 0
	_speed_show()


## 速算題目的來源（後面的關卡可以換掉）
func _speed_gen(kind: String, n: int) -> Array:
	return Bank4.gen_problems(kind, n)


func _speed_show() -> void:
	var pb: Dictionary = problems[sp_i]
	fview.show_speed(pb.eq, sp_i, problems.size(), streak)
	step_label.text = UITheme.step_bar(_steps(), 0)
	if sp_i > 0:
		story_label.visible = false
	_build_fill({"name": "速算", "q": pb.get("q", "算出它的值（可以填負數或分數）。"), "template": pb.get("template", pb.eq + " = [0]"),
		"answers": [pb.ans], "mode": "ordered", "nudge": pb.nudge,
		"tag": pb.get("tag", "loglaw_def" if pb.kind == "val" else "loglaw_law"), "line": ""})


# ================= 鍊金工房（畫在舞台上） =================

class AlchemyView extends ScaleView:
	const VIOLET := Color("c792ff")
	const TEAL := Color("6ee7c8")

	# 施放法則
	var cast_text := ""
	var cast_t := -10.0
	# 連鎖
	var chain_on := false
	var chain_lock := false
	var chain_items: Array = []
	var chain_closed := false
	var chain_seq: Array = []
	var chain_done_t := -10.0
	var flash_k := -1
	var flash_ok := true
	var flash_t := -10.0

	# 數量級實驗室
	var mag_rd := {}
	var mag_s := 0.0
	var mag_k := 0.0              # 畫面上的指數（慢慢追上真正的值）
	var mag_pop := -10.0

	func mag_setup(rd: Dictionary, s: float) -> void:
		mag_rd = rd
		mag_s = s
		mag_k = mag_exp(rd, s)
		mag_pop = -10.0

	func mag_set(s: float) -> void:
		mag_s = s
		mag_pop = t
		var p := _ladder_point(mag_exp(mag_rd, s))
		_burst(p, GOLD if mag_exp(mag_rd, s) >= mag_k else TEAL, 12)

	func _process(delta: float) -> void:
		if not mag_rd.is_empty():
			mag_k = lerpf(mag_k, mag_exp(mag_rd, mag_s), 1.0 - exp(-7.0 * delta))
		super(delta)

	func reset_alchemy() -> void:
		cast_text = ""
		cast_t = -10.0
		chain_on = false
		chain_lock = false
		chain_seq = []
		chain_done_t = -10.0

	func cast(formula: String) -> void:
		cast_text = formula
		cast_t = t
		_burst(Vector2(size.x / 2.0, size.y * 0.46), VIOLET, 26)

	func begin_chain(st: Dictionary) -> void:
		chain_on = true
		chain_lock = false
		chain_items = st.items
		chain_closed = st.closed
		chain_seq = []
		chain_done_t = -10.0
		flash_k = -1

	func end_chain() -> void:
		chain_on = false
		chain_lock = false

	func chain_done() -> void:
		chain_done_t = t
		var r2 := _chain_rect()
		_burst(Vector2(r2.get_center().x, r2.position.y + 70), GOLD, 30)

	func link_flash(k: int, ok: bool) -> void:
		flash_k = k
		flash_ok = ok
		flash_t = t

	## 第 k 環有沒有接上前一環（第 0 環一定算接上）
	func joint_ok(k: int) -> bool:
		if k <= 0 or k >= chain_seq.size():
			return true
		return chain_items[chain_seq[k - 1]].b == chain_items[chain_seq[k]].a

	func _graph_on() -> bool:
		return chain_on or super()

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if chain_on:
			_draw_chain(font, rect)
		else:
			super(font, rect)

	func _draw() -> void:
		super()
		if kind == "mag" and not mag_rd.is_empty():
			_draw_mag(get_theme_default_font())
		_draw_cast(get_theme_default_font())

	# ---------- 背景：鍊金工房 ----------

	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("170f2c"), Color("170f2c"), Color("0d1b2c"), Color("0d1b2c")]))
		# 地上的鍊金陣（慢慢轉）
		var c := Vector2(w / 2.0, h * 0.56)
		var rad := minf(w, h) * 0.40
		var col := Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.07 + 0.015 * sin(t * 1.2))
		draw_arc(c, rad, 0, TAU, 96, col, 2.0, true)
		draw_arc(c, rad * 0.86, 0, TAU, 96, col, 1.2, true)
		draw_arc(c, rad * 0.42, 0, TAU, 64, col, 1.2, true)
		var rot := t * 0.06
		for k in 2:
			var tri := PackedVector2Array()
			for j in 4:
				var ang := rot + k * PI / 3.0 + j * TAU / 3.0 - PI / 2.0
				tri.append(c + Vector2(cos(ang), sin(ang)) * rad * 0.86)
			draw_polyline(tri, col, 1.4, true)
		for j in 12:
			var ang := -rot * 1.5 + j * TAU / 12.0
			var p := c + Vector2(cos(ang), sin(ang)) * rad * 0.93
			UITheme.dot(self, p, 3.0, col)
		# 底部的光暈
		var glow := 0.10 + 0.03 * sin(t * 1.6)
		draw_polygon(PackedVector2Array([Vector2(0, h * 0.62), Vector2(w, h * 0.62), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color(0.55, 0.4, 1.0, 0.0), Color(0.55, 0.4, 1.0, 0.0), Color(0.45, 0.35, 0.95, glow),
				Color(0.3, 0.85, 0.75, glow)]))
		# 角落的燒瓶（下方有圖的時候讓開）
		if not _graph_on() and kind != "mag":
			_draw_flask(Vector2(52, h - 30), VIOLET, 0.0)
			_draw_flask(Vector2(w - 52, h - 30), TEAL, 1.7)
		# 飄浮的光點
		for i in 26:
			var sp := 0.03 + 0.03 * fposmod(i * 0.371, 1.0)
			var y := h - fposmod(t * sp + i * 0.137, 1.0) * h
			var x := fposmod(i * 0.618, 1.0) * w + 12.0 * sin(t * 0.8 + i)
			var pc := VIOLET if i % 3 else TEAL
			UITheme.dot(self, Vector2(x, y), 1.3 + fposmod(i * 0.29, 1.0) * 1.4, Color(pc.r, pc.g, pc.b, clampf(y / h, 0.0, 0.55)))
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	## 圓底燒瓶：瓶身、液體、往上冒的泡泡
	func _draw_flask(base: Vector2, col: Color, phase: float) -> void:
		var body := base + Vector2(0, -26)
		var glass := Color(0.85, 0.85, 1.0, 0.22)
		UITheme.dot(self, body, 24.0, Color(col.r, col.g, col.b, 0.10))
		# 液體（下半圓）
		var liquid := PackedVector2Array()
		var lv := 0.15 + 0.05 * sin(t * 1.3 + phase)
		for i in 25:
			var ang := lerpf(lv, PI - lv, i / 24.0)
			liquid.append(body + Vector2(cos(ang), sin(ang)) * 22.0)
		draw_colored_polygon(liquid, Color(col.r, col.g, col.b, 0.35))
		draw_arc(body, 24.0, -PI / 2.0 + 0.35, 1.5 * PI - 0.35, 40, glass, 2.0, true)
		draw_line(body + Vector2(-8, -22), body + Vector2(-8, -48), glass, 2.0)
		draw_line(body + Vector2(8, -22), body + Vector2(8, -48), glass, 2.0)
		draw_line(body + Vector2(-12, -48), body + Vector2(12, -48), glass, 2.5)
		for i in 4:
			var k := fposmod(t * 0.45 + i * 0.25 + phase, 1.0)
			var p := body + Vector2(5.0 * sin(t * 2.0 + i * 1.7), 8.0 - k * 70.0)
			draw_arc(p, 2.0 + 2.0 * k, 0, TAU, 12, Color(col.r, col.g, col.b, 0.6 * (1.0 - k)), 1.2, true)

	# ---------- 施放法則：鍊金陣亮起來，中間寫著法則 ----------

	func _draw_cast(font: Font) -> void:
		var age := t - cast_t
		if cast_text == "" or age > 1.6:
			return
		var a := clampf(age / 0.18, 0.0, 1.0) * clampf((1.6 - age) / 0.5, 0.0, 1.0)
		var c := Vector2(size.x / 2.0, size.y * 0.46)
		var rad := lerpf(60.0, 130.0, clampf(age / 0.5, 0.0, 1.0))
		UITheme.dot(self, c, rad, Color(0.07, 0.04, 0.14, 0.82 * a))
		draw_arc(c, rad, 0, TAU, 80, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.9 * a), 3.0, true)
		draw_arc(c, rad - 10.0, 0, TAU, 80, Color(GOLD.r, GOLD.g, GOLD.b, 0.5 * a), 1.5, true)
		for j in 8:
			var ang := age * 1.5 + j * TAU / 8.0
			UITheme.dot(self, c + Vector2(cos(ang), sin(ang)) * (rad - 5.0), 3.5, Color(GOLD.r, GOLD.g, GOLD.b, a))
		draw_string(font, Vector2(c.x - 100, c.y - 26), "✦ 施放法則 ✦", HORIZONTAL_ALIGNMENT_CENTER, 200, UITheme.fs(15),
			Color(VIOLET.r, VIOLET.g, VIOLET.b, a))
		var fs := mini(UITheme.fs(22), _fit_in(font, cast_text, UITheme.fs(22), rad * 2.0 - 30.0))
		MathLabel.draw_on(self, font, c.x, c.y + 12, cast_text, fs, Color(1, 0.93, 0.7, a))

	func _fit_in(font: Font, markup: String, fs: int, room: float) -> int:
		var w := _mw(font, markup, fs)
		return fs if w <= room else maxi(UITheme.fs(11), int(floor(fs * room / w)))

	# ---------- 連鎖之環 ----------

	func _chain_rect() -> Rect2:
		return Rect2(36, size.y - 214, size.x - 72, 190)

	func _draw_chain(font: Font, rect: Rect2) -> void:
		draw_style_box(UITheme.boxc(Color(0.06, 0.03, 0.10, 0.6), 12, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.3), 1, 0), rect.grow(6))
		draw_string(font, rect.position + Vector2(4, -10), "連鎖之環（上一環的真數 = 下一環的底數）",
			HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(0.85, 0.75, 1.0, 0.75))
		var n := chain_items.size()
		var y := rect.position.y + 62.0
		var x0 := rect.position.x + 34.0
		var dx := (rect.size.x - 68.0) / float(maxi(n, 1))
		var nodes := []
		for i in n + 1:
			nodes.append(Vector2(x0 + dx * i, y))
		var complete := chain_seq.size() == n and n > 0
		var all_ok := complete
		for k in chain_seq.size():
			if not joint_ok(k):
				all_ok = false
		if chain_closed and complete and chain_items[chain_seq[-1]].b != chain_items[chain_seq[0]].a:
			all_ok = false
		# 鍊環（兩個節點之間）
		for k in n:
			var a: Vector2 = nodes[k]
			var b: Vector2 = nodes[k + 1]
			var lr := Rect2(a.x + 6, y - 15, b.x - a.x - 12, 30)
			if k < chain_seq.size():
				var it: Dictionary = chain_items[chain_seq[k]]
				var ok := joint_ok(k)
				var lc := VIOLET if ok else UITheme.BAD
				var pop := 0.0
				if k == flash_k:
					pop = clampf(1.0 - (t - flash_t) / 0.35, 0.0, 1.0)
				draw_style_box(UITheme.boxc(Color(lc.r, lc.g, lc.b, 0.16 + 0.2 * pop), 15, lc, 3, 0), lr.grow(2.0 * pop))
				MathLabel.draw_on(self, font, lr.get_center().x, y - 26, it.text, UITheme.fs(17), Color(1, 0.95, 1.0))
			else:
				var pa := 0.18 + 0.08 * sin(t * 3.0 + k)
				draw_style_box(UITheme.boxc(Color(1, 1, 1, 0.03), 15, Color(1, 1, 1, pa), 1, 0), lr)
		# 節點：底數／真數
		for i in n + 1:
			var p: Vector2 = nodes[i]
			var lab := ""
			if i == 0 and chain_seq.size() > 0:
				lab = chain_items[chain_seq[0]].a
			elif i >= 1 and i <= chain_seq.size():
				lab = chain_items[chain_seq[i - 1]].b
			var good := i == 0 or i >= chain_seq.size() or joint_ok(i)
			var nc := TEAL if good else UITheme.BAD
			if lab == "":
				UITheme.dot(self, p, 16.0, Color(1, 1, 1, 0.05))
				draw_arc(p, 16.0, 0, TAU, 32, Color(1, 1, 1, 0.25), 1.2, true)
				continue
			UITheme.dot(self, p, 19.0, Color("140c24"))
			draw_arc(p, 18.0, 0, TAU, 32, nc, 2.5, true)
			draw_string(font, p + Vector2(-30, 7), lab, HORIZONTAL_ALIGNMENT_CENTER, 60, UITheme.fs(18) if lab.length() <= 2 else UITheme.fs(14), Color(1, 1, 1, 0.95))
			# 接不上：下面寫出下一環的底數
			if not good:
				var want: String = chain_items[chain_seq[i]].a
				draw_string(font, p + Vector2(-50, 42), "%s ≠ %s" % [lab, want], HORIZONTAL_ALIGNMENT_CENTER, 100, UITheme.fs(15), UITheme.BAD)
		# 繞回起點：底下畫一條弧線
		if complete and all_ok:
			var k2 := clampf((t - chain_done_t) / 0.6, 0.0, 1.0) if chain_done_t > 0 else 1.0
			var first: String = chain_items[chain_seq[0]].a
			var last: String = chain_items[chain_seq[-1]].b
			if chain_closed:
				var pts := PackedVector2Array()
				var a2: Vector2 = nodes[n]
				var b2: Vector2 = nodes[0]
				for i in 33:
					var u := float(i) / 32.0 * k2
					var px := lerpf(a2.x, b2.x, u)
					pts.append(Vector2(px, y + 22.0 + 34.0 * sin(u * PI)))
				if pts.size() >= 2:
					draw_polyline(UITheme.thin(pts), Color(GOLD.r, GOLD.g, GOLD.b, 0.8), 2.5, true)
			var res := "= log_{%s} %s" % [first, last]
			if first == last:
				res += " = 1"
			MathLabel.draw_on(self, font, rect.get_center().x, rect.end.y - 22, res, UITheme.fs(24), Color(GOLD.r, GOLD.g, GOLD.b, k2))
		elif chain_seq.is_empty():
			draw_string(font, Vector2(rect.position.x, rect.end.y - 26), "點右邊的鍊環，一環一環接起來",
				HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, UITheme.fs(16), Color(1, 1, 1, 0.45 + 0.15 * sin(t * 3.0)))

	# ---------- 數量級實驗室 ----------

	## 數量的指數 k（數量 = 參考值 × 10^{k}）
	static func mag_exp(rd: Dictionary, s: float) -> float:
		match rd.kind:
			"sound":
				return log(s) / log(10.0)
			"quake":
				return 1.5 * (s - 5.0)
		return 7.0 - s

	## 遊戲裡看到的刻度：分貝、規模或 pH
	static func mag_measure(rd: Dictionary, s: float) -> float:
		if rd.kind == "sound":
			return 60.0 + 10.0 * log(s) / log(10.0)
		return s

	## 按下第 i 個按鈕之後的狀態；超出範圍回傳 NAN
	static func mag_apply(rd: Dictionary, s: float, i: int) -> float:
		var op: Array = rd.ops[i]
		var ns := s
		match op[1]:
			"mul":
				ns = s * float(op[2])
			"div":
				ns = s / float(op[2])
			_:
				ns = s + float(op[2])
		if ns < float(rd.min) - 1e-9 or ns > float(rd.max) + 1e-6:
			return NAN
		return ns

	static func _kt(k: float) -> String:
		if absf(k - roundf(k)) < 1e-6:
			return str(int(roundf(k))).replace("-", "−")
		return ("%.1f" % k).replace("-", "−")

	## 10^{k} 寫成一般的數字（不大的時候）
	static func _times(k: float) -> String:
		if absf(k - roundf(k)) > 1e-6 or absf(k) > 4.0:
			return "10^{%s}" % _kt(k)
		var ki := int(roundf(k))
		if ki >= 0:
			return str(int(pow(10.0, ki)))
		return "1/%d" % int(pow(10.0, -ki))

	static func mag_readout(rd: Dictionary, s: float) -> String:
		var k := mag_exp(rd, s)
		var gold := "[color=#ffcf5a]%s[/color]"
		match rd.kind:
			"sound":
				var db := mag_measure(rd, s)
				var dbt := str(int(roundf(db))) if absf(db - roundf(db)) < 0.005 else "約 %d" % int(roundf(db))
				return "%d 支喇叭　⇒　%s" % [int(roundf(s)), gold % (dbt + " 分貝")]
			"quake":
				return "規模 %s　⇒　能量是規模 5 的 %s 倍" % [gold % _kt(s), gold % _times(k)]
		return "pH %s　⇒　[H^{+}] 是純水的 %s 倍" % [gold % _kt(s), gold % _times(k)]

	func _ladder_rect() -> Rect2:
		return Rect2(size.x - 226, 92, 200, size.y - 128)

	func _ladder_point(k: float) -> Vector2:
		var L := _ladder_rect()
		var lad: Array = mag_rd.ladder
		var u := (k - float(lad[0])) / (float(lad[1]) - float(lad[0]))
		return Vector2(L.position.x + 74, L.end.y - u * L.size.y)

	func _draw_mag(font: Font) -> void:
		draw_string(font, Vector2(22, 34), "數量級實驗室", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(0.85, 0.75, 1.0, 0.75))
		var pop := clampf(1.0 - (t - mag_pop) / 0.35, 0.0, 1.0)
		var scene := Rect2(24, 92, size.x - 272, size.y - 128)
		MathLabel.draw_on(self, font, scene.get_center().x, 66, mag_readout(mag_rd, mag_s), UITheme.fs(20 + 4 * pop), Color(1, 0.97, 0.9))
		_draw_mag_formula(font, scene)
		match mag_rd.kind:
			"sound":
				_draw_sound(font, scene)
			"quake":
				_draw_quake(font, scene)
			_:
				_draw_ph(font, scene)
		_draw_ladder(font)

	## 計算公式卡（題庫的 formula：一行一個字串），放在讀數下方
	func _draw_mag_formula(font: Font, scene: Rect2) -> void:
		var rows: Array = mag_rd.get("formula", [])
		if rows.is_empty():
			return
		var fs := UITheme.fs(16)
		var w := 0.0
		var hs := []
		for ln in rows:
			w = maxf(w, MathLabel.text_width(font, String(ln), fs))
			hs.append(MathLabel.line_extent(String(ln), fs))
		w = minf(w + 28.0, scene.size.x - 8.0)
		var h := 12.0
		for e in hs:
			h += e.x + e.y + 10.0
		var box := Rect2(scene.get_center().x - w / 2.0, 90.0, w, h)
		draw_style_box(UITheme.boxc(Color(0.06, 0.03, 0.12, 0.88), 12, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.55), 1, 0), box)
		var y := box.position.y + 6.0
		for i in rows.size():
			var e: Vector2 = hs[i]
			y += e.x + 5.0
			MathLabel.draw_on(self, font, box.get_center().x, y, String(rows[i]), fs,
				Color(1, 0.95, 0.8) if i == 0 else Color(0.85, 0.8, 1.0, 0.9))
			y += e.y + 5.0

	## 數量級之梯：左邊是倍數（每一格 ×10），右邊是分貝／規模／pH
	func _draw_ladder(font: Font) -> void:
		var L := _ladder_rect()
		draw_style_box(UITheme.boxc(Color(0.06, 0.03, 0.10, 0.6), 12, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.3), 1, 0), L.grow(8))
		draw_string(font, Vector2(L.position.x - 4, L.position.y - 16), "數量級之梯：每一格 ×10", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13),
			Color(0.85, 0.75, 1.0, 0.8))
		var lad: Array = mag_rd.ladder
		var ax := L.position.x + 74
		var top := _ladder_point(float(lad[1]))
		var bot := _ladder_point(float(lad[0]))
		draw_line(top, bot, Color(1, 1, 1, 0.35), 3.0)
		# 參考點（倍數 ×1）到目前位置：亮起來的那一段
		var p0 := _ladder_point(0.0)
		var pc := _ladder_point(mag_k)
		var up := mag_k >= 0.0
		var lc := GOLD if up else TEAL
		draw_line(p0, pc, Color(lc.r, lc.g, lc.b, 0.25), 14.0)
		draw_line(p0, pc, lc, 4.0)
		for k in range(int(ceil(float(lad[0]))), int(floor(float(lad[1]))) + 1):
			var p := _ladder_point(float(k))
			var lit := (up and k > 0 and k <= mag_k + 0.02) or (not up and k < 0 and k >= mag_k - 0.02)
			draw_line(p + Vector2(-10, 0), p + Vector2(10, 0), lc if lit else Color(1, 1, 1, 0.5), 2.0)
			var lab := "×" + _times(float(k))
			MathLabel.draw_on(self, font, ax - 42, p.y + 5, lab, UITheme.fs(13), lc.lightened(0.2) if lit else Color(1, 1, 1, 0.6))
		for mk in mag_rd.marks:
			var p := _ladder_point(float(mk[0]))
			var near := absf(float(mk[0]) - mag_exp(mag_rd, mag_s)) < 0.01
			UITheme.dot(self, p, 4.0, VIOLET if not near else GOLD)
			draw_string(font, p + Vector2(14, 5), str(mk[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13),
				GOLD if near else Color(0.9, 0.85, 1.0, 0.75))
		# 目前的位置
		UITheme.dot(self, pc, 13.0 + 2.0 * sin(t * 5.0), Color(lc.r, lc.g, lc.b, 0.25))
		UITheme.dot(self, pc, 7.5, lc)

	## 比純水少的時候：10 × 10 的方格 = 純水的 H⁺，亮的格子是現在的量。
	## 不到一格時，把第一格放大成另一個 10 × 10 的方格（每放大一次 ×100），最多放大兩次
	func _draw_ph_grids(font: Font, B: Rect2, lt: float, ratio: float) -> void:
		var bw := B.size.x
		var big := minf(118.0, bw * 0.46)
		var small := minf(96.0, bw * 0.38)
		var rects := [Rect2(B.position.x + 14, lt + 18, big, big),
			Rect2(B.end.x - 14 - small, lt + 18, small, small),
			Rect2(B.end.x - 14 - small, lt + 18 + small + 26, small, small)]
		var v := ratio * 100.0          # 以第一層的格數計
		var lit := Color(1, 0.95, 0.55)
		for lv in 3:
			var R: Rect2 = rects[lv]
			var c := R.size.x / 10.0
			draw_rect(R.grow(3), Color(0.05, 0.05, 0.12, 0.55))
			for i in 100:
				var cell := Rect2(R.position + Vector2((i % 10) * c, (i / 10) * c), Vector2(c, c)).grow(-1.0)
				var fill := clampf(v - i, 0.0, 1.0)
				draw_rect(cell, Color(1, 1, 1, 0.07))
				if fill > 0.0:
					var pulse := 0.85 + 0.15 * sin(t * 3.0 + i * 0.4)
					draw_rect(Rect2(cell.position, Vector2(cell.size.x * fill, cell.size.y)), Color(lit.r, lit.g, lit.b, pulse))
			var tag := "純水的量" if lv == 0 else "放大 %s 倍" % ("100" if lv == 1 else "10000")
			draw_string(font, R.position + Vector2(0, -5), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(12), Color(1, 1, 1, 0.75))
			if v >= 1.0 or lv == 2:
				break
			# 不到一格：把第一格框起來，拉線到下一個放大的方格
			var first := Rect2(R.position, Vector2(c, c))
			draw_rect(first.grow(1.5), Color(1, 0.6, 0.85, 0.95), false, 2.0)
			var nx: Rect2 = rects[lv + 1]
			draw_line(first.position + Vector2(c, 0), nx.position, Color(1, 0.6, 0.85, 0.6), 1.5, true)
			draw_line(first.end, nx.position + Vector2(0, nx.size.y), Color(1, 0.6, 0.85, 0.6), 1.5, true)
			draw_rect(nx.grow(3), Color(1, 0.6, 0.85, 0.8), false, 2.0)
			v *= 100.0

	## 喇叭：數量最多畫 100 個，再多就「一個圖示代表好幾支」
	func _draw_sound(font: Font, S: Rect2) -> void:
		var n := mag_s
		var db := mag_measure(mag_rd, n)
		var loud := clampf((db - 55.0) / 65.0, 0.0, 1.0)
		var shake := Vector2.ZERO
		if db >= 95.0:
			shake = Vector2(sin(t * 53.0), cos(t * 47.0)) * (db - 92.0) * 0.18
		draw_set_transform(shake)
		var shown := clampi(int(roundf(n)), 1, 100)
		var cols := 10
		var cell := minf(S.size.x / 10.0, (S.size.y - 70.0) / 10.0)
		var rows := int(ceil(shown / float(cols)))
		var gw := cell * mini(shown, cols)
		var gh := cell * rows
		var origin := Vector2(S.get_center().x - gw / 2.0, S.get_center().y - gh / 2.0 - 10.0)
		var center := origin + Vector2(gw, gh) / 2.0
		# 聲波
		var rings := 3 + int(loud * 5.0)
		for j in rings:
			var rr := fposmod(t * (50.0 + 90.0 * loud) + j * 42.0, 42.0 * rings) + maxf(gw, gh) * 0.4
			var a := (0.10 + 0.35 * loud) * (1.0 - rr / (42.0 * rings + maxf(gw, gh) * 0.4))
			draw_arc(center, rr, 0, TAU, 64, Color(VIOLET.r, VIOLET.g, VIOLET.b, maxf(a, 0.0)), 2.0, true)
		for i in shown:
			var c := origin + Vector2((i % cols + 0.5) * cell, (i / cols + 0.5) * cell)
			var sc := 1.0 + 0.10 * loud * sin(t * 12.0 + i * 0.7)
			_draw_speaker(c, cell * 0.36 * sc)
		draw_set_transform(Vector2.ZERO)
		if n > 100.5:
			draw_string(font, Vector2(S.position.x, S.end.y - 8), "每個圖示 = %d 支喇叭" % int(roundf(n / 100.0)),
				HORIZONTAL_ALIGNMENT_CENTER, S.size.x, UITheme.fs(16), Color(1, 0.9, 0.6, 0.85))

	func _draw_speaker(c: Vector2, r: float) -> void:
		var col := Color(0.85, 0.75, 1.0)
		draw_rect(Rect2(c.x - r, c.y - r * 0.45, r * 0.6, r * 0.9), col)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.4, -r * 0.45), c + Vector2(r * 0.5, -r),
			c + Vector2(r * 0.5, r), c + Vector2(-r * 0.4, r * 0.45)]), col)
		draw_arc(c + Vector2(r * 0.55, 0), r * 0.55, -0.9, 0.9, 10, Color(col.r, col.g, col.b, 0.6), 1.5, true)

	## 地震：大樓跟著搖，上面是地震儀的波形
	func _draw_quake(font: Font, S: Rect2) -> void:
		var M := mag_s
		var amp := clampf(0.004 * pow(10.0, 0.35 * (M - 2.0)), 0.0, 0.24)
		var gy := S.end.y - 46.0
		var jolt := sin(t * 38.0) * amp * 30.0
		# 地震儀
		var sy := S.position.y + (134.0 if not mag_rd.get("formula", []).is_empty() else 46.0)     # 上面有公式卡時往下移
		draw_style_box(UITheme.boxc(Color(1, 1, 1, 0.04), 8, Color(1, 1, 1, 0.12), 1, 0), Rect2(S.position.x, sy - 36, S.size.x, 72))
		var pts := PackedVector2Array()
		for i in 121:
			var x := lerpf(S.position.x + 6, S.end.x - 6, i / 120.0)
			var env := 0.5 + 0.5 * sin(i * 0.11 - t * 2.0)
			var y := sy + (sin(i * 1.7 + t * 30.0) * 0.6 + sin(i * 0.63 - t * 21.0) * 0.4) * clampf(amp * 150.0, 1.5, 32.0) * env
			pts.append(Vector2(x, y))
		draw_polyline(UITheme.thin(pts), Color(1, 0.55, 0.5, 0.9), 1.5, true)
		draw_string(font, Vector2(S.position.x + 8, sy - 20), "地震儀", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(12), Color(1, 1, 1, 0.5))
		# 地面
		draw_rect(Rect2(S.position.x, gy + jolt * 0.3, S.size.x, S.end.y - gy), Color(0.25, 0.18, 0.32, 0.9))
		if M >= 7.0:
			for c in 3:
				var cx := S.position.x + S.size.x * (0.25 + 0.25 * c)
				var crack := PackedVector2Array([Vector2(cx, gy), Vector2(cx + 8, gy + 12), Vector2(cx - 4, gy + 24), Vector2(cx + 6, gy + 40)])
				draw_polyline(crack, Color(0.05, 0.02, 0.08), 2.5)
		# 大樓
		var hs := [120.0, 170.0, 95.0, 145.0, 110.0]
		var bw := S.size.x / 7.0
		for i in hs.size():
			var bx := S.position.x + bw * (0.7 + i * 1.15)
			var h: float = hs[i]
			var ang := sin(t * (11.0 + i * 1.3) + i) * amp
			draw_set_transform(Vector2(bx + bw / 2.0, gy + jolt * 0.3), ang)
			var col := VIOLET.darkened(0.35) if i % 2 == 0 else TEAL.darkened(0.45)
			draw_rect(Rect2(-bw / 2.0, -h, bw, h), col)
			for wy in int(h / 22.0):
				for wx in 2:
					draw_rect(Rect2(-bw / 2.0 + 7 + wx * (bw / 2.0 - 2), -h + 8 + wy * 22.0, bw / 2.0 - 12, 10),
						Color(1, 0.9, 0.55, 0.55 if (wy + wx + i) % 3 else 0.2))
			draw_set_transform(Vector2.ZERO)

	## 燒杯：顏色跟著 pH 變，H⁺ 最多畫 100 顆
	func _draw_ph(font: Font, S: Rect2) -> void:
		var ph := mag_s
		var k := mag_exp(mag_rd, ph)
		var hue := 0.0 + (ph - 1.0) / 12.0 * 0.78
		var liquid := Color.from_hsv(hue, 0.7, 0.95, 0.82)
		var bw := minf(260.0, S.size.x * 0.7)
		var bh := minf(300.0, S.size.y - 50.0)
		var B := Rect2(S.get_center().x - bw / 2.0, S.end.y - bh - 24.0, bw, bh)
		var lt := B.position.y + bh * 0.18 + 3.0 * sin(t * 2.0)
		draw_rect(Rect2(B.position.x, lt, bw, B.end.y - lt), liquid)
		var glass := Color(0.9, 0.9, 1.0, 0.55)
		draw_line(B.position, Vector2(B.position.x, B.end.y), glass, 3.0)
		draw_line(Vector2(B.end.x, B.position.y), B.end, glass, 3.0)
		draw_line(Vector2(B.position.x, B.end.y), B.end, glass, 3.0)
		draw_line(B.position + Vector2(-10, 0), B.position + Vector2(8, 0), glass, 3.0)
		draw_line(Vector2(B.end.x - 8, B.position.y), Vector2(B.end.x + 10, B.position.y), glass, 3.0)
		var ratio := pow(10.0, k)
		if ratio < 0.999:
			_draw_ph_grids(font, B, lt, ratio)
		var shown := clampi(int(roundf(ratio)), 1, 100) if ratio >= 0.999 else 0
		var a := 1.0
		for i in shown:
			var hx := fposmod(i * 0.6180339 + 0.13, 1.0)
			var hy := fposmod(i * 0.4142135 + 0.37, 1.0)
			var p := Vector2(B.position.x + 14 + hx * (bw - 28), lt + 14 + hy * (B.end.y - lt - 28))
			p += Vector2(sin(t * 1.7 + i), cos(t * 1.3 + i * 0.7)) * 4.0
			UITheme.dot(self, p, 6.0, Color(1, 0.95, 0.6, a))
			draw_string(font, p + Vector2(-6, 5), "+", HORIZONTAL_ALIGNMENT_CENTER, 12, UITheme.fs(13), Color(0.35, 0.1, 0.1, a))
		# 泡泡
		for i in 6:
			var u := fposmod(t * 0.3 + i * 0.17, 1.0)
			var bp := Vector2(B.position.x + bw * (0.15 + 0.14 * i), B.end.y - 10 - u * (B.end.y - lt - 10))
			draw_arc(bp, 3.0 + 2.0 * u, 0, TAU, 10, Color(1, 1, 1, 0.35 * (1.0 - u)), 1.2, true)
		var cap := ""
		if ratio > 100.5:
			cap = "每一顆 = %s 個 H⁺" % _times(k - 2.0)
		elif ratio < 0.999:
			cap = "H⁺ 只剩純水的 %s（整個方格 = 純水的量）" % _times(k)
		else:
			cap = "黃色的小球是 H⁺"
		MathLabel.draw_on(self, font, S.get_center().x, S.end.y - 2, cap, UITheme.fs(15), Color(1, 0.9, 0.6, 0.85))
