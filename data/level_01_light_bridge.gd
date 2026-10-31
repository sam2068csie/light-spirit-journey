extends Control
## 第一大關「光之橋」v3（對應講義 2-1 重點一：指數函數之圖形與性質）
## 用法：根節點選 Control，掛上這個腳本。需要同資料夾的
##   game_theme.gd、math_text.gd、level01_bank.gd（題庫）。
##
## 每次遊玩會從題庫隨機抽題：旅程順序固定（由易到難），但每段旅程的題目、
## 預言題與選項順序都會隨機變化。開頭先選章節，完成後回到章節選單。
##
## 五種旅程：
##   fit       ① 預言 → ② 調參數，光靈沿光橋奔跑收集寶石（音高跟著高度變化）
##   rank      ① 預言 → ② 對照 x = 1 的參考線，替曲線配上底數
##   quadrant  ① 預言 → ② 調 h、k 點亮指定的象限燈塔（或判斷做不到）
##   count     ① 移動水平線完成交點任務 → ② 判斷 c 的範圍
##   table     ① 代入整數列表比大小（點畫上棋盤） → ② 點出大小相反的區間 → ③ 判斷交點總數
##   cross     ① 徒手畫左邊的函數 → ② 徒手畫右邊的函數 → ③ 兩條都畫對了，數交點個數
## 另需同資料夾的 game.gd（音樂音效、換場景）與 pause_menu.gd、settings_panel.gd。

signal level_cleared(stars: int)

const UITheme := preload("game_theme.gd")
const MathLabel := preload("math_text.gd")
const Bank := preload("level01_bank.gd")
const Game := preload("game.gd")
const PauseMenu := preload("pause_menu.gd")
const Concepts := preload("concept_cards.gd")
const ConceptDeck := preload("concept_deck.gd")
const Buddy := preload("buddy.gd")
const Ambient := preload("ambient.gd")
const QP := preload("quest_panel.gd")       # 物品圖示（星塵、寶箱…）
const QUAD_COL := UITheme.ORANGE

const PARAM_INFO := {
	"a": {"name": "底數 a", "range": [0.1, 4.0, 0.05], "start": 1.5},
	"h": {"name": "左右 h", "range": [-3.0, 3.0, 0.5], "start": 0.0},
	"k": {"name": "上下 k", "range": [-2.0, 4.0, 0.5], "start": 0.0},
	"m": {"name": "係數 M", "range": [50.0, 2000.0, 50.0], "start": 500.0},
	"c": {"name": "水平線 c", "range": [-1.0, 6.0, 0.25], "start": 3.0},
	"p": {"name": "探測線 x", "range": [-3.0, 3.0, 0.25], "start": -2.0},
	"s": {"name": "掃描線 x", "range": [-6.0, 6.0, 0.05], "start": 0.0},
}
const MAX_ENERGY := 3
const RANK_COLORS := [UITheme.PINK, UITheme.CYAN, UITheme.LIME, UITheme.ORANGE]
const RANK_TAGS := ["A", "B", "C", "D"]
const ROMAN := ["", "Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ"]

## −1 = 開頭顯示章節選單；1、2 = 直接進入該章（方便測試）
@export var start_chapter := -1

var rounds: Array = []
var ri := 0
var r: Dictionary = {}
var vals := {}
var energy := MAX_ENERGY
var tries := 0
var predicted_ok := false
var predicting := false
var predict_tries := 0
var cur_q: Dictionary = {}       # 目前顯示中的選擇題（預言或 count 的最終題）
var revealing := false
var busy := false
var time_left := 0.0
var score := 0
var total_stars := 0
var goal_idx := 0
var mislocks := 0
var chapter_now := 0
var table_mist := 0            # 列表作圖：這一段的錯誤次數
var table_done: Array = []     # 列表作圖：每一格是否已答對
var table_cells: Array = []    # 列表作圖：每一格的 {head, e, q, cmp}
var table_ask: Control         # 列表作圖：目前這一格的比較題卡片
var table_q_label: Label
var table_line: MathLabel
var table_chips: Array = []
var last_count := -1
var cross_done := false
var journey_mode := false      # true：從題目列表點進來，只玩一段旅程
var chapter_slots: Array = []  # 目前這一章的所有旅程（依難度排序）
var cur_slot_idx := -1
var round_stars := 0           # 這段旅程拿到的星數（示範答案時是 0）
var review_mode := false       # 今日修煉／自由練習：從修煉之間點進來，只玩指定的一題
var review_i := 0
var review_n := 0
var review_kind := ""
var tower_mode := false        # 終焉之塔：整趟只有三顆心（用 energy 當心），每層限時
var tower_floor := 0
var _recorded_frame := -1      # 這一幀已經因為答錯扣過心了（避免 _record 和 _fail 重複扣）

# UI
var stage: Stage
var pause_menu: CanvasLayer
var journey_label: Label
var pips: Pips
var side_card: PanelContainer   # 右邊的引導作答區
var side_scroll: ScrollContainer
const SIDE_BAR_GAP := 11      # 右邊卡片：捲軸和內容之間留的空間
var side_col: VBoxContainer
var side_frame: VBoxContainer     # 卡片內：捲動區＋固定在底部的按鈕
var side_btns: HBoxContainer
var buddy                        # 光靈：舞台左下角冒出來說話
var hint_face                    # 光靈的臉：趴在提示框左上角，跟著提示變表情
var wrong_streak := 0            # 這一題連續答錯幾次
var perfect_run := 0             # 連續幾題全對
var idle_t := 0.0                # 多久沒動了（太久光靈會打瞌睡）
var idle_shown := false
var prev_q_btn: Button
var next_q_btn: Button
var chain_i := 0              # 連續預言題（chain）：已經問到第幾題
var chord_phase := 0          # 凹口比大小：0 判斷凹口、1 連弦、2 比大小
var chord_errs := 0           # 凹口比大小：這一題答錯幾次
var round_gen := 0            # 每開始一題就 +1；等待中的動畫用它判斷題目是不是已經換了
var score_label: Label
var _dust_anim := false       # 星塵數字正在往上跳
var story_label: MathLabel
var step_label: MathLabel
var formula_label: MathLabel
var predict_box: VBoxContainer
var task_label: MathLabel
var rank_box: VBoxContainer
var sliders_box: VBoxContainer
var energy_label: Label
var go_btn: Button
var alt_btn: Button
var hint_panel: PanelContainer
var hint_label: MathLabel
var next_btn: Button
var sliders := {}
var value_labels := {}
var rank_options: Array = []


# ================= 這一大關的設定（其他大關繼承這個腳本時覆寫） =================

func level_id() -> String:
	return "L1"

func level_title() -> String:
	return "光之橋"

func level_subtitle() -> String:
	return "指數函數 y = a^{x} 的圖形與性質"

func level_chapters() -> Array:
	return CHAPTERS

func bank_slots() -> Array:
	return Bank.slots()

## ---- 子類別自訂的旅程類型（例如第二大關的鍛造、速算、調頻）----
func _custom_type(_t: String) -> bool:
	return false

func _custom_start() -> void:
	pass

func _custom_steps() -> Array:
	return []

func _custom_step_index() -> int:
	return 0

## 自訂旅程裡的選擇題答對了
func _custom_answered() -> void:
	pass

func _custom_go() -> void:
	pass

func _custom_reveal(_msg: String) -> void:
	_end_round()

func _custom_timeout() -> void:
	_reveal("時間到！")

func _custom_formula() -> String:
	return r.get("eq", "")

## 舞台外觀（天空顏色、遠景）
func stage_style() -> Dictionary:
	return {"ambient": "aurora"}     # 光之橋：極光

## 進入第二章時跳出的說明卡
func chapter_card() -> Dictionary:
	return {"title": "第二章．鏡之谷", "button": "進入鏡之谷  ▶",
		"text": "絕對值會讓光橋「照鏡子」：\n\n" \
			+ "・y = a^{|x|}　右半邊對 y 軸翻過去\n" \
			+ "・|y| = a^{x}　上半部對 x 軸翻下來\n" \
			+ "・y = |a^{x} + k|　x 軸下方翻到上方\n\n" \
			+ "就看絕對值包住了誰！"}


# ================= 初始化 =================

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.shared()
	randomize()
	var g = Game.of(self)
	_build_ui()
	get_tree().node_added.connect(_wrap_side_text)
	for key in stage_style():
		stage.set(key, stage_style()[key])
	buddy = Buddy.new()
	add_child(buddy)
	hint_face = Buddy.Face.new()
	hint_face.size = Vector2(44, 44)
	hint_face.radius = 12.0
	hint_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_face.visible = false
	add_child(hint_face)
	pause_menu = PauseMenu.new()
	pause_menu.list_action = _back_to_list
	pause_menu.report_info = _report_context
	add_child(pause_menu)
	stage.run_finished.connect(_on_run_finished)
	stage.step_note.connect(func(t): Game.of(self).note(t))
	stage.gem_hit.connect(func(i): Game.of(self).sfx("gem", i))
	stage.fell.connect(func(reason): Game.of(self).sfx("hole" if reason == "hole" else "fall"))
	stage.root_found.connect(_on_root_found)
	stage.stroke_done.connect(_on_stroke)
	stage.chord_tap.connect(func(i): Game.of(self).sfx("gem", i * 2))
	stage.chord_drawn.connect(_on_chord_drawn)
	stage.band_toggled.connect(func(i):
		Game.of(self).play("bell", Game.semi(9 if stage.band_sel[i] else 2), -9.0)
		_update_band_ui())
	var a: Dictionary = g.take_args()
	if a.has("review"):
		_review_begin(a)
	elif a.has("chapter"):
		_begin(int(a.chapter))
	elif start_chapter >= 0:
		_begin(start_chapter)
	else:
		_show_menu()


func _begin(chapter: int) -> void:
	chapter_now = chapter
	build_rounds(chapter)
	ri = 0
	score = 0
	total_stars = 0
	_start_round()


## 依章節組出這次要玩的旅程：每個 slot 隨機抽一個變體
func build_rounds(chapter: int, pick: Callable = Callable()) -> void:
	rounds.clear()
	var used_eq := {}
	for slot in bank_slots():
		if chapter != 0 and slot.chapter != chapter:
			continue
		var vi: int = pick.call(slot) if pick.is_valid() else _pick_variant(slot.variants, used_eq)
		var v: Dictionary = slot.variants[vi]
		if v.has("lhs"):
			used_eq[v.lhs + "=" + v.rhs] = true
		rounds.append(make_round(slot, v))


## 依 weight 加權抽一個變體；盡量避開這一輪已經出現過的方程式
static func _pick_variant(vs: Array, used_eq: Dictionary) -> int:
	var cands := []
	for i in vs.size():
		if not (vs[i].has("lhs") and used_eq.has(vs[i].lhs + "=" + vs[i].rhs)):
			cands.append(i)
	if cands.is_empty():
		cands = range(vs.size())
	var total := 0.0
	for i in cands:
		total += float(vs[i].get("weight", 1))
	var t := randf() * total
	for i in cands:
		t -= float(vs[i].get("weight", 1))
		if t <= 0.0:
			return i
	return cands.back()


## 把 slot 與變體合併成一段旅程（view、ranges、fixed 會逐項合併）
static func make_round(slot: Dictionary, v: Dictionary) -> Dictionary:
	var rd: Dictionary = slot.duplicate(true)
	rd.erase("variants")
	for key in v:
		if rd.has(key) and rd[key] is Dictionary and v[key] is Dictionary and key != "answer" and key != "final":
			rd[key] = rd[key].duplicate(true)
			rd[key].merge(v[key], true)
		else:
			rd[key] = v[key].duplicate(true) if (v[key] is Dictionary or v[key] is Array) else v[key]
	rd["view_x"] = rd.get("view", {}).get("x", Vector2(-4, 5))
	rd["view_y"] = rd.get("view", {}).get("y", Vector2(-1.5, 7.0))
	var pool: Array = rd.get("predicts", [])
	rd["predict"] = shuffle_q(pool[randi() % pool.size()]) if not pool.is_empty() else {}
	if rd.has("final"):
		rd["final"] = shuffle_q(rd.final)
	if rd.get("square", false):
		# x、y 同比例（鏡子 y = x 才會是 45°）：舞台 700 × 556
		var vy: Vector2 = rd.view_y
		var cx: float = (rd.view_x.x + rd.view_x.y) / 2.0
		var half := (vy.y - vy.x) * 700.0 / 556.0 / 2.0
		rd["view_x"] = Vector2(cx - half, cx + half)
	if rd.type == "fit":
		_make_gems(rd)
	if rd.type == "table":
		var signs := []
		var ev := []
		var qv := []
		for x in rd.xs:
			var a: float = Stage.side_val(rd.exp, float(x))
			var b: float = Stage.side_val(rd.quad, float(x))
			ev.append(a)
			qv.append(b)
			signs.append(0 if absf(a - b) < 1e-9 else (1 if a > b else -1))
		var flips := []
		for i in signs.size() - 1:
			flips.append(signs[i] * signs[i + 1] < 0)
		rd["signs"] = signs
		rd["e_vals"] = ev
		rd["q_vals"] = qv
		rd["flips"] = flips
		rd["roots"] = Stage.cross_roots_of(rd)
		rd["final"] = {"q": "表格外還會不會再相交？%s = %s 共有幾個實數解？" % [rd.lhs, rd.rhs],
			"options": ["0", "1", "2", "3", "4"], "correct": int(rd.n), "keep_order": true, "cols": 5,
			"why": rd.why, "nudge": rd.nudge, "tag": rd.get("tag", "exp_quad_cross")}
	if rd.type == "cross":
		# 交點獵人：先徒手畫出兩個函數，畫對了再數交點（不用滑桿）
		rd["params"] = []
		rd["roots"] = Stage.cross_roots_of(rd)
		rd["final"] = {"q": "兩條圖形都畫好了！方程式 %s = %s 有幾個實數解？" % [rd.lhs, rd.rhs],
			"options": ["0", "1", "2", "3", "4"], "correct": int(rd.n), "keep_order": true, "cols": 5,
			"why": rd.why, "nudge": rd.nudge, "tag": rd.get("tag", "exp_quad_cross")}
	return rd


## 打亂選擇題的選項順序（keep_order 的題目保持原順序）
static func shuffle_q(q0: Dictionary) -> Dictionary:
	var q: Dictionary = q0.duplicate(true)
	if q.get("keep_order", false):
		return q
	var idx := range(q.options.size())
	idx.shuffle()
	var opts := []
	for n in idx.size():
		opts.append(q0.options[idx[n]])
		if idx[n] == int(q0.correct):
			q.correct = n
	q.options = opts
	return q


static func _p(rd: Dictionary, key: String, default: float) -> float:
	return float(rd.get("answer", {}).get(key, rd.get("fixed", {}).get(key, default)))


## 由答案與 xs 算出寶石；霧中旅程自動放一個黑洞在常見錯誤會經過的位置
static func _make_gems(rd: Dictionary) -> void:
	var a := _p(rd, "a", 2.0)
	var h := _p(rd, "h", 0.0)
	var k := _p(rd, "k", 0.0)
	var m := _p(rd, "m", 1.0)
	var nb := 2 if rd.form == "abs_y" else 1
	var gems := []
	for x in rd.xs:
		for b in nb:
			var y := Stage.fval(rd.form, a, h, k, m, float(x), b)
			gems.append(Vector2(float(x), snappedf(y, 0.0001)))
	rd["gems"] = gems
	if rd.has("holes"):
		return
	rd["holes"] = []
	if rd.live or rd.form == "abs_y":
		return
	_place_hole(rd, a, h, k, m)


## 在常見錯誤會經過、但離正確光橋夠遠的地方放黑洞（找不到合適位置就不放）
static func _place_hole(rd: Dictionary, a: float, h: float, k: float, m: float) -> void:
	var vx: Vector2 = rd.view_x
	var vy: Vector2 = rd.view_y
	var span := vy.y - vy.x
	var xs: Array = rd.xs
	var cand := [float(xs.min()) - 1.0, float(xs.max()) + 1.0, float(xs.min()) - 0.5, float(xs.max()) + 0.5]
	for i in xs.size() - 1:
		cand.append((float(xs[i]) + float(xs[i + 1])) / 2.0)
	for hx in cand:
		if hx < vx.x + 0.4 or hx > vx.y - 0.4:
			continue
		var fy := Stage.fval(rd.form, a, h, k, m, hx, 0)
		if is_nan(fy):
			continue
		for mult in [0.16, -0.16, 0.24, -0.24]:
			var hp := Vector2(hx, fy + mult * span)
			if hp.y < vy.x + 0.06 * span or hp.y > vy.y - 0.06 * span:
				continue
			if _clearance_px(rd, a, h, k, m, hp) >= 48.0:
				rd.holes.append(hp)
				return


## 黑洞到正確光橋與寶石的最近距離（以 700×556 的舞台像素計）
static func _clearance_px(rd: Dictionary, a: float, h: float, k: float, m: float, hp: Vector2) -> float:
	var vx: Vector2 = rd.view_x
	var vy: Vector2 = rd.view_y
	var to_px := func(p: Vector2) -> Vector2:
		return Vector2((p.x - vx.x) / (vx.y - vx.x) * 700.0, (p.y - vy.x) / (vy.y - vy.x) * 556.0)
	var hs: Vector2 = to_px.call(hp)
	var best := INF
	for i in 801:
		var x := lerpf(vx.x, vx.y, i / 800.0)
		var y := Stage.fval(rd.form, a, h, k, m, x, 0)
		if is_nan(y) or y < vy.x - span_pad(vy) or y > vy.y + span_pad(vy):
			continue
		best = minf(best, hs.distance_to(to_px.call(Vector2(x, y))))
	for g in rd.gems:
		best = minf(best, hs.distance_to(to_px.call(g)))
	return best


static func span_pad(vy: Vector2) -> float:
	return 0.1 * (vy.y - vy.x)


# ================= 介面 =================

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var top := HBoxContainer.new()
	top.position = Vector2(24, 12)
	top.custom_minimum_size = Vector2(1104, 48)
	top.add_theme_constant_override("separation", 16)
	add_child(top)
	var title := Label.new()
	title.text = level_title()
	title.add_theme_font_size_override("font_size", UITheme.fs(24))
	title.add_theme_color_override("font_color", UITheme.ACCENT)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)
	journey_label = Label.new()
	journey_label.add_theme_font_size_override("font_size", UITheme.fs(20))
	journey_label.add_theme_color_override("font_color", UITheme.TEXT)
	journey_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journey_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(journey_label)
	prev_q_btn = _nav_q_button("‹", "上一題")
	prev_q_btn.pressed.connect(func(): _jump_journey(-1))
	top.add_child(prev_q_btn)
	pips = Pips.new()
	pips.custom_minimum_size = Vector2(0, 48)
	top.add_child(pips)
	next_q_btn = _nav_q_button("›", "下一題")
	next_q_btn.pressed.connect(func(): _jump_journey(1))
	top.add_child(next_q_btn)
	# 右上角：持有的星塵（和主畫面、扭蛋機同一種貨幣）
	var dust_ic := QP.ItemIcon.new()
	dust_ic.kind = "dust"
	dust_ic.custom_minimum_size = Vector2(30, 30)
	dust_ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(dust_ic)
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", UITheme.fs(24))
	score_label.add_theme_color_override("font_color", UITheme.ACCENT)
	score_label.custom_minimum_size = Vector2(64, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(score_label)
	var pb := UITheme.round_button("pause", 44)
	pb.tooltip_text = "暫停（Esc）"
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pb.pressed.connect(func(): pause_menu.open())
	top.add_child(pb)
	top.add_theme_constant_override("separation", 12)

	stage = Stage.new()
	stage.position = Vector2(24, 70)
	stage.size = Vector2(700, 556)
	add_child(stage)

	var card := PanelContainer.new()
	card.position = Vector2(744, 70)
	card.custom_minimum_size = Vector2(384, 556)
	# 右邊內距縮小，讓捲軸貼近卡片右緣；內容和按鈕另外往左留 SIDE_BAR_GAP，不會和捲軸重疊
	var csb := UITheme.box(UITheme.PANEL, 18, Color(1, 1, 1, 0.07), 1, 18)
	csb.content_margin_right = 18 - SIDE_BAR_GAP
	card.add_theme_stylebox_override("panel", csb)
	add_child(card)
	side_card = card
	# 內容太長時在卡片裡上下捲動（卡片本身不會被撐出螢幕）
	side_scroll = ScrollContainer.new()
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	side_frame = VBoxContainer.new()
	side_frame.add_theme_constant_override("separation", 9)
	card.add_child(side_frame)
	var vsb := side_scroll.get_v_scroll_bar()
	vsb.custom_minimum_size = Vector2(5, 0)
	vsb.add_theme_stylebox_override("scroll", UITheme.box(Color(1, 1, 1, 0.04), 3, Color(0, 0, 0, 0), 0, 0))
	for st in ["grabber", "grabber_highlight", "grabber_pressed"]:
		vsb.add_theme_stylebox_override(st, UITheme.box(Color(1, 1, 1, 0.25), 3, Color(0, 0, 0, 0), 0, 0))
	side_frame.add_child(side_scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", SIDE_BAR_GAP)
	for m in ["margin_left", "margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(m, 0)
	side_scroll.add_child(pad)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 9)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(col)
	side_col = col

	story_label = _wrap_label(15, UITheme.TEXT_DIM)
	col.add_child(story_label)
	step_label = _wrap_label(16, UITheme.TEXT)
	col.add_child(step_label)

	formula_label = MathLabel.new()
	formula_label.font_size = UITheme.fs(30)
	formula_label.max_width = 340
	col.add_child(formula_label)

	predict_box = VBoxContainer.new()
	predict_box.add_theme_constant_override("separation", 6)
	col.add_child(predict_box)

	task_label = _wrap_label(17, UITheme.ACCENT)
	col.add_child(task_label)

	rank_box = VBoxContainer.new()
	rank_box.add_theme_constant_override("separation", 5)
	col.add_child(rank_box)

	sliders_box = VBoxContainer.new()
	sliders_box.add_theme_constant_override("separation", 4)
	col.add_child(sliders_box)

	energy_label = Label.new()
	energy_label.add_theme_color_override("font_color", UITheme.PINK)
	col.add_child(energy_label)

	hint_panel = PanelContainer.new()
	hint_panel.add_theme_stylebox_override("panel", UITheme.box(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 12))
	hint_panel.visible = false     # 預設的面板內距比較大，一開始就顯示會把右邊的卡片撐寬
	hint_label = _wrap_label(15, UITheme.TEXT)
	hint_label.max_width = 340 - 24      # 扣掉提示框左右各 12 的內距，才不會把卡片撐寬
	hint_panel.add_child(hint_label)
	col.add_child(hint_panel)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	side_frame.add_child(btn_row)
	side_btns = btn_row
	go_btn = Button.new()
	go_btn.custom_minimum_size = Vector2(0, 52)
	go_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.accent_button(go_btn)
	go_btn.pressed.connect(_on_go)
	btn_row.add_child(go_btn)
	alt_btn = Button.new()
	alt_btn.text = "做不到！"
	alt_btn.custom_minimum_size = Vector2(110, 52)
	alt_btn.pressed.connect(_on_impossible)
	btn_row.add_child(alt_btn)

	next_btn = Button.new()
	next_btn.custom_minimum_size = Vector2(0, 48)
	UITheme.accent_button(next_btn, 20)
	next_btn.pressed.connect(_on_next)
	side_frame.add_child(next_btn)
	# 底部按鈕和上面的內容對齊（右邊也留 SIDE_BAR_GAP）
	btn_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	next_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	side_frame.resized.connect(func():
		var w := side_frame.size.x - SIDE_BAR_GAP
		btn_row.custom_minimum_size.x = w
		next_btn.custom_minimum_size.x = w)


## 右邊卡片裡直排的文字、按鈕一律自動換行（字放大之後，單行的長句會把卡片撐寬、超出螢幕）
func _wrap_side_text(n: Node) -> void:
	if not is_instance_valid(side_col) or not side_col.is_ancestor_of(n):
		return
	# 手指按在按鈕上拖動也能捲動卡片（滑桿自己會處理拖動，不受影響）
	if n is BaseButton and n.mouse_filter == Control.MOUSE_FILTER_STOP:
		n.mouse_filter = Control.MOUSE_FILTER_PASS
	var par := n.get_parent()
	if not (par is VBoxContainer or par is GridContainer):
		return
	if n is Label and n.autowrap_mode == TextServer.AUTOWRAP_OFF:
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	elif n is Button and n.autowrap_mode == TextServer.AUTOWRAP_OFF and n.get_node_or_null("Math") == null:
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


const SIDE_INNER_H := 556.0 - 36.0    # 卡片內可用的高度（扣掉上下內距）

## 捲動區可以用的高度（扣掉固定在底部的按鈕）
func _side_avail() -> float:
	var h := SIDE_INNER_H
	var sep := 9.0
	for c in [side_btns, next_btn]:
		if c.visible:
			h -= c.get_combined_minimum_size().y + sep
	return maxf(60.0, h)


func _fit_side() -> void:
	if not is_instance_valid(side_scroll):
		return
	var show_row: bool = go_btn.visible or alt_btn.visible
	if side_btns.visible != show_row:
		side_btns.visible = show_row
	var want := minf(side_col.get_combined_minimum_size().y, _side_avail())
	if absf(side_scroll.custom_minimum_size.y - want) > 0.5:
		side_scroll.custom_minimum_size.y = want
	# 卡片被暫時的內容撐寬後不會自己縮回來：內容已經不需要那麼寬時，恢復原本的寬度
	var w0 := side_card.custom_minimum_size.x
	if side_card.size.x > w0 + 0.5 and side_card.get_combined_minimum_size().x <= w0 + 0.5:
		side_card.size.x = w0


## 右邊卡片捲到看得見這個元件（版面要等一個畫格才量好）
func _scroll_to(c: Control) -> void:
	if not is_inside_tree():
		return          # 換畫面的瞬間：已經離開場景，不用捲了
	await get_tree().process_frame
	if is_instance_valid(side_scroll) and is_instance_valid(c) and c.is_visible_in_tree():
		side_scroll.ensure_control_visible(c)


func _wrap_label(font_size: int, c: Color) -> MathLabel:
	var l := MathLabel.new()
	l.max_width = 340
	l.font_size = UITheme.fs(font_size)
	l.color = c
	return l


func _hint(text: String, kind: String = "info") -> void:
	_buddy_react(kind)
	hint_panel.visible = true
	var c := {"info": UITheme.CYAN, "good": UITheme.GOOD, "bad": UITheme.BAD}[kind] as Color
	hint_panel.add_theme_stylebox_override("panel",
		UITheme.box(Color(c.r, c.g, c.b, 0.10), 12, Color(c.r, c.g, c.b, 0.55), 1, 12))
	hint_label.font_size = UITheme.fs(15)
	hint_label.text = text
	_fit_hint.call_deferred()


## 右邊卡片快放不下時（例如提示裡有好幾個分數），提示字縮小一點；還是放不下就捲到提示
func _fit_hint() -> void:
	if not is_instance_valid(side_col):
		return
	var limit := _side_avail() + 1.0
	for i in 5:
		# 版面要等一個畫格才會重新量好
		await get_tree().process_frame
		if not is_instance_valid(side_col) or hint_label.font_size <= UITheme.fs(12):
			break
		if side_col.get_combined_minimum_size().y <= limit:
			break
		hint_label.font_size -= 1
	_scroll_to(hint_panel)


static func param_color(p: String) -> Color:
	return {"a": UITheme.CYAN, "h": UITheme.PINK, "k": UITheme.LIME,
		"m": UITheme.ACCENT, "c": UITheme.ACCENT, "p": UITheme.ACCENT, "s": UITheme.ACCENT}[p]


func _clear(box: Container) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _overlay(border: Color, width: int = 0) -> Array:
	Game.of(self).sfx("open")
	return UITheme.modal(self, border, width)


func _big_label(text: String, size: int, c: Color) -> Label:
	return UITheme.title_label(text, size, c)


# ================= 章節選單與章節卡 =================

const CHAPTERS := [
	{"ch": 1, "name": "第一章．指數之光", "topic": "圖形、平移、象限與交點", "color": UITheme.CYAN},
	{"ch": 2, "name": "第二章．鏡之谷", "topic": "絕對值：對稱與翻折", "color": UITheme.PINK},
]


func _show_menu() -> void:
	for b in [go_btn, alt_btn, next_btn]:
		b.visible = false       # 選單後面的面板保持乾淨
	var o := _overlay(Color(1, 1, 1, 0.14), 500)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_child(_big_label(level_title(), 36, UITheme.ACCENT))
	var d := MathLabel.new()
	d.max_width = 440
	d.font_size = UITheme.fs(17)
	d.color = UITheme.TEXT_DIM
	d.align_center = true
	d.text = level_subtitle()
	col.add_child(d)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	col.add_child(gap)
	if not concept_cards().is_empty():
		var cb := _concept_button()
		cb.pressed.connect(func():
			layer.queue_free()
			_show_concepts(0))
		col.add_child(cb)
	var g = Game.of(self)
	for item in level_chapters():
		var b := _chapter_button(item, int(g.stars.get(level_id() + "_c%d" % item.ch, 0)))
		var ch: int = item.ch
		b.pressed.connect(func():
			layer.queue_free()
			_show_journeys(ch))
		col.add_child(b)
	var back := UITheme.ghost_button("返回關卡列表", 16)
	back.icon = UITheme.icon("back", 16, UITheme.TEXT_DIM)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): Game.of(self).goto("main_menu.gd", {"page": "levels"}))
	col.add_child(back)


## 章節按鈕：右邊顯示這一章的最佳星數
func _chapter_button(item: Dictionary, best: int) -> Button:
	var c: Color = item.color
	var b := Button.new()
	b.custom_minimum_size = Vector2(440, 84)
	var normal := UITheme.box(UITheme.PANEL_LIGHT, 14, Color(1, 1, 1, 0.08), 1, 14)
	normal.border_width_left = 5
	normal.border_color = c
	var hover := UITheme.box(UITheme.PANEL_LIGHT.lightened(0.1), 14, c, 2, 14)
	hover.border_width_left = 5
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_theme_constant_override("margin_left", 22)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 10)      # 文字和上下邊框留一點距離
	m.add_theme_constant_override("margin_bottom", 10)
	b.add_child(m)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(row)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var name_l := Label.new()
	name_l.text = item.name
	name_l.add_theme_font_size_override("font_size", UITheme.fs(20))
	col.add_child(name_l)
	var topic := Label.new()
	topic.text = item.topic
	topic.add_theme_font_size_override("font_size", UITheme.fs(15))
	topic.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	topic.clip_text = true
	topic.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(topic)
	# 右邊：星數和完成度（字放大後放在同一行會擠出按鈕）
	var side := VBoxContainer.new()
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	side.add_theme_constant_override("separation", 0)
	row.add_child(side)
	var cnt := Label.new()
	cnt.text = _star_text(best, 3)
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cnt.add_theme_font_size_override("font_size", UITheme.fs(20))
	cnt.add_theme_color_override("font_color", UITheme.ACCENT if best > 0 else Color(1, 1, 1, 0.22))
	side.add_child(cnt)
	var pct := Label.new()
	pct.text = "完成 %d%%" % roundi(100.0 * _chapter_completion(item.ch))
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.add_theme_font_size_override("font_size", UITheme.fs(13))
	pct.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	side.add_child(pct)
	for node in [name_l, topic, cnt, pct, side]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _show_chapter_card() -> void:
	var cc := chapter_card()
	var col2: Color = level_chapters()[1].color if level_chapters().size() > 1 else UITheme.PINK
	var o := _overlay(col2, 500)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_child(_big_label(cc.title, 34, col2))
	var d := MathLabel.new()
	d.max_width = 440
	d.font_size = UITheme.fs(20)
	d.text = cc.text
	col.add_child(d)
	var go := Button.new()
	go.text = cc.button
	go.custom_minimum_size = Vector2(0, 52)
	UITheme.accent_button(go, 20)
	go.pressed.connect(func(): layer.queue_free())
	col.add_child(go)


# ================= 一段旅程 =================

## 右邊的大公式盡量放在同一行：放不下就縮小字（同一題只縮不放大，拖滑桿時字不會一下大一下小）
var formula_fs := 30

func _fit_formula() -> void:
	var font := formula_label.get_theme_default_font()
	var fs := formula_fs
	while fs > 18 and MathLabel.text_width(font, formula_label.text, UITheme.fs(fs)) > formula_label.max_width - 4.0:
		fs -= 1
	formula_fs = fs
	if formula_label.font_size != UITheme.fs(fs):
		formula_label.font_size = UITheme.fs(fs)


func _start_round() -> void:
	formula_fs = 30
	round_gen += 1
	wrong_streak = 0
	idle_t = 0.0
	idle_shown = false
	if buddy:
		var title: String = rounds[ri].get("title", "")
		get_tree().create_timer(0.5).timeout.connect(func():
			if is_instance_valid(buddy):
				buddy.say(Buddy.line("start", title), "happy", 2.4))
	round_stars = 0
	# 右邊卡片回到原本的寬度（上一題的內容清掉之後才量，所以延後一下）
	side_card.call_deferred("reset_size")
	r = rounds[ri]
	vals = {}
	for p in PARAM_INFO:
		vals[p] = float(PARAM_INFO[p].start)
	vals["m"] = 1.0
	for key in r.get("fixed", {}):
		vals[key] = float(r.fixed[key])
	for key in r.get("answer", {}):
		if not r.params.has(key):
			vals[key] = float(r.answer[key])   # 不是滑桿的參數（例如平移變身的底數）直接用題目給的值
	for p in r.params:
		var rg: Array = _range(p)
		vals[p] = float(r.get("start", {}).get(p, clampf(PARAM_INFO[p].start, rg[0], rg[1])))
	_avoid_answer_start()
	energy = MAX_ENERGY
	tries = 0
	mislocks = 0
	goal_idx = 0
	predicted_ok = false
	revealing = false
	busy = false
	time_left = r.get("time", 0.0)
	last_count = -1
	cross_done = false
	chord_phase = 0
	chord_errs = 0
	stroke_pending = false
	chain_i = 0
	marking = false
	story_label.text = r.story
	story_label.visible = true
	if r.type == "quadrant":
		story_label.text = "讓光橋只經過第 %s 象限。" % "、".join(r.target.map(func(q): return ROMAN[q]))
	next_btn.visible = false
	alt_btn.visible = false
	task_label.visible = false
	hint_panel.visible = false
	_clear(rank_box)
	rank_box.visible = false

	stage.setup(r)
	_build_sliders()
	_sync()
	_update_hud()
	if r.type == "count":
		_enter_step2()      # 交點調頻：先做任務，最後才回答範圍題
	elif r.type == "table":
		_table_start()      # 列表作圖：先列表，最後才回答個數
	elif r.type == "draw":
		_sketch_start()     # 徒手作圖：沒有預言，直接一筆畫
	elif r.type == "cross":
		_cross_start()      # 交點獵人：先畫兩條圖形，再數交點
	elif _custom_type(r.type):
		_custom_start()
	else:
		_show_question(r.predict)
	if not journey_mode and not review_mode and r.chapter == 2 and (ri == 0 or rounds[ri - 1].chapter == 1):
		_show_chapter_card()


func _steps() -> Array:
	if _custom_type(r.type):
		return _custom_steps()
	match r.type:
		"rank":
			return ["預言", "替曲線配上底數"]
		"quadrant":
			return ["預言", "調整並點亮燈塔"]
		"count":
			return ["調頻任務", "判斷範圍"]
		"cross":
			return ["畫第一條", "畫第二條", "數交點"]
		"table":
			return ["列表比大小", "找區間", "數交點"]
		"draw":
			return ["標出整數點", "畫出圖形", "評分"]
		"chord":
			return ["判斷凹口", "連出弦", "比大小"]
	return ["預言", "調整並點亮光橋"]


func _range(p: String) -> Array:
	return r.get("ranges", {}).get(p, PARAM_INFO[p].range)


func _build_sliders() -> void:
	_clear(sliders_box)
	sliders.clear()
	value_labels.clear()
	for p in r.params:
		var rg: Array = _range(p)
		var row := HBoxContainer.new()
		var name_l := Label.new()
		name_l.text = PARAM_INFO[p].name
		name_l.custom_minimum_size = Vector2(74, 0)
		name_l.add_theme_color_override("font_color", param_color(p))
		var s := UITheme.touch_slider()
		var ch := _choices(p)
		if ch.is_empty():
			s.min_value = rg[0]
			s.max_value = rg[1]
			s.step = rg[2]
			s.value = vals[p]
		else:
			s.min_value = 0
			s.max_value = ch.size() - 1
			s.step = 1
			s.tick_count = ch.size()
			s.ticks_on_borders = true
			vals[p] = float(ch[_nearest_idx(ch, vals[p])])
			s.value = _nearest_idx(ch, vals[p])
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.custom_minimum_size = Vector2(0, 28)
		UITheme.tint_slider(s, param_color(p))
		s.value_changed.connect(_on_slider.bind(p))
		var val_l := Label.new()
		val_l.custom_minimum_size = Vector2(48, 0)
		val_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_l.add_theme_color_override("font_color", param_color(p))
		row.add_child(name_l)
		row.add_child(s)
		UITheme.add_step_buttons(s, param_color(p))
		row.add_child(val_l)
		sliders_box.add_child(row)
		sliders[p] = s
		value_labels[p] = val_l
	_set_sliders(false)


func _set_sliders(on: bool) -> void:
	for p in sliders:
		sliders[p].editable = on


## 有些參數只能選固定的幾個值（例如對數的底數 1/4、1/2、2、3…），滑桿就在這些值之間跳
## 滑桿一開始剛好停在答案上，就換到別的值（不然學生什麼都不用做就過關了）
func _avoid_answer_start() -> void:
	var ans_d: Dictionary = r.get("answer", {})
	for p in r.params:
		if not ans_d.has(p):
			continue
		var ans := float(ans_d[p])
		if absf(float(vals[p]) - ans) > 1e-6:
			continue
		var ch := _choices(p)
		if not ch.is_empty():
			var i := _nearest_idx(ch, ans)
			vals[p] = float(ch[(i + 2) % ch.size()]) if ch.size() > 2 else float(ch[(i + 1) % ch.size()])
			continue
		var rg: Array = _range(p)
		var stp := float(rg[2])
		for d in [1.0, -1.0, 2.0, -2.0, 0.5, -0.5]:
			var v := snappedf(ans + d, stp)
			if v >= float(rg[0]) - 1e-6 and v <= float(rg[1]) + 1e-6 and absf(v - ans) > 1e-6:
				vals[p] = v
				break


func _choices(p: String) -> Array:
	return r.get("choices", {}).get(p, [])


static func _nearest_idx(list: Array, v: float) -> int:
	var best := 0
	for i in list.size():
		if absf(float(list[i]) - v) < absf(float(list[best]) - v):
			best = i
	return best


## 把參數 p 設成 v（透過滑桿，所以畫面會一起更新）
func set_param(p: String, v: float) -> void:
	var ch := _choices(p)
	sliders[p].value = _nearest_idx(ch, v) if not ch.is_empty() else v


func _on_slider(v: float, p: String) -> void:
	var ch := _choices(p)
	vals[p] = float(ch[clampi(int(roundf(v)), 0, ch.size() - 1)]) if not ch.is_empty() else v
	_sync()


func _sync() -> void:
	stage.a = vals.a
	stage.h = vals.h
	stage.k = vals.k
	stage.m = vals.m
	stage.line_c = vals.c if r.type == "count" else NAN
	var rlog: bool = r.get("rank_form", "exp") == "log"
	stage.probe_x = 1.0 if r.type == "rank" and not rlog else NAN    # 底數辨識：指數看 x = 1
	stage.probe_y = 1.0 if r.type == "rank" and rlog else NAN        # 對數看 y = 1
	for p in value_labels:
		value_labels[p].text = UITheme.nice_text(vals[p]) if not _choices(p).is_empty() else UITheme.num(vals[p], 2)
	formula_label.text = _formula()
	_fit_formula()
	if r.type == "count" and not predicting:
		var n: int = stage.roots_of(vals.c).size()
		if last_count != -1 and n != last_count:
			Game.of(self).sfx("count", n)
		last_count = n
	if r.type == "cross" and stage.scan_on:
		stage.set_scan(vals.s)
		_check_cross_done()
	if stage.demo_btn and (r.type == "fit" or r.type == "count"):
		stage.demo = _abs_demo_params()
	stage.queue_redraw()


## 絕對值圖形：要示範的那條曲線（交點題是左邊的指數／對數函數）
func _abs_demo_params() -> Dictionary:
	if r.type == "cross" or r.type == "table":
		var e: Dictionary = r.get("exp", {})
		if e.is_empty():
			return {}
		return {"form": e.form, "a": float(e.a), "h": float(e.get("h", 0.0)), "k": float(e.get("k", 0.0)), "m": float(e.get("m", 1.0))}
	return {"form": r.get("form", "exp"), "a": vals.a, "h": vals.h, "k": vals.k, "m": vals.m}


## 絕對值圖形的由來：顯示「圖形怎麼來的？」按鈕，auto = 直接播一次
func _abs_demo(auto: bool) -> void:
	var p := _abs_demo_params()
	if not Stage.is_abs_form(String(p.get("form", ""))):
		return
	stage.demo = p
	stage.demo_btn = true
	if auto:
		stage.play_abs_demo(p)


# ---------- 公式顯示 ----------

func _nice(v: float) -> String:
	for pair in [[0.5, "(1/2)"], [0.25, "(1/4)"], [0.2, "(1/5)"], [1.0 / 3.0, "(1/3)"]]:
		if is_equal_approx(v, pair[0]):
			return pair[1]
	return UITheme.num(v, 2)


func _col(text: String, p: String) -> String:
	return "[color=#%s]%s[/color]" % [param_color(p).to_html(false), text]


## 曲線本身的式子（不含 y =），參數上色、固定值照常顯示
func _expr() -> String:
	if Stage.is_log(r.form):
		return _log_expr()
	var A := _col(UITheme.num(vals.a, 2), "a") if r.params.has("a") else _nice(vals.a)
	var inner := "x"
	var hv: float = vals.h
	if r.params.has("h") or not is_zero_approx(hv):
		var hs := UITheme.num(absf(hv), 2)
		if r.params.has("h"):
			hs = _col(hs, "h")
		inner = ("x − %s" if hv >= 0.0 else "x + %s") % hs
	var core := "%s^{|%s|}" % [A, inner] if r.form == "abs_in" else "%s^{%s}" % [A, inner]
	if r.params.has("m"):
		core = _col(UITheme.num(vals.m, 2), "m") + "·" + core
	elif not is_equal_approx(float(vals.get("m", 1.0)), 1.0):
		core = UITheme.num(vals.m, 2) + "·" + core      # 固定的係數（例如 y = 2·(1/2)^{|x|}）
	var kv: float = vals.k
	if r.params.has("k") or not is_zero_approx(kv):
		var ks := UITheme.num(absf(kv), 2)
		if r.params.has("k"):
			ks = _col(ks, "k")
		core += (" + %s" if kv >= 0.0 else " − %s") % ks
	if r.form == "abs_out":
		core = "|%s|" % core
	return core


## 對數曲線的式子：log_{a}(x − h) + k、log_{a}|x − h| + k、|log_{a}(x − h) + k|
func _log_expr() -> String:
	var A := _col(UITheme.nice_text(vals.a), "a") if r.params.has("a") else UITheme.nice_text(vals.a)
	var hv: float = vals.h
	var inner := "x"
	if r.params.has("h") or not is_zero_approx(hv):
		var hs := UITheme.num(absf(hv), 2)
		if r.params.has("h"):
			hs = _col(hs, "h")
		inner = ("x − %s" if hv >= 0.0 else "x + %s") % hs
	var core: String
	if r.form == "log_abs_in" or r.form == "log_abs_both":
		core = "log_{%s}|%s|" % [A, inner]
	elif inner == "x":
		core = "log_{%s} x" % A
	else:
		core = "log_{%s}(%s)" % [A, inner]
	var kv: float = vals.k
	if r.params.has("k") or not is_zero_approx(kv):
		var ks := UITheme.num(absf(kv), 2)
		if r.params.has("k"):
			ks = _col(ks, "k")
		core += (" + %s" if kv >= 0.0 else " − %s") % ks
	if r.form == "log_abs_out" or r.form == "log_abs_both":
		core = "|%s|" % core
	return core


func _formula() -> String:
	if _custom_type(r.type):
		return _custom_formula()
	if r.type == "rank":
		return ""
	if r.type == "chord":
		return r.get("eq", "y = " + _expr())
	if r.type == "cross" or r.type == "table":
		return "[color=#%s]%s[/color] = [color=#%s]%s[/color]" % [
			Stage.CURVE_COL.to_html(false), r.lhs, QUAD_COL.to_html(false), r.rhs]
	if r.type == "count":
		return "%s = %s" % [_expr(), _col(UITheme.num(vals.c, 2), "c")]
	if r.form == "abs_y":
		return "|y| = " + _expr()
	return "y = " + _expr()


# ================= 選擇題（預言／最終題） =================

func _show_question(q: Dictionary) -> void:
	cur_q = q
	predicting = true
	stage.hide_curve = r.type == "fit" and not busy
	predict_tries = 0
	sliders_box.visible = false
	energy_label.visible = false
	go_btn.visible = false
	alt_btn.visible = false
	rank_box.visible = false
	task_label.visible = false
	formula_label.visible = r.type == "count" or r.type == "table" or r.type == "cross" or r.type == "chord"
	hint_panel.visible = false
	var stp := 1 if r.type == "count" else (2 if r.type == "table" or r.type == "cross" else 0)
	if r.type == "chord":
		stp = 2 if chord_phase == 2 else 0
	if _custom_type(r.type):
		stp = _custom_step_index()
	step_label.text = UITheme.step_bar(_steps(), stp)
	_clear(predict_box)
	var ql := _wrap_label(18, UITheme.ACCENT)
	ql.text = q.q
	predict_box.add_child(ql)
	var cols: int = q.get("cols", 2)
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	predict_box.add_child(grid)
	for idx in q.options.size():
		var b: Button
		if cols >= 4:
			b = MathLabel.make_button(q.options[idx], 22, Vector2(60, 50))
		else:
			b = MathLabel.make_button(q.options[idx], 16, Vector2(160, 42))
		b.set_meta("silent", true)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_answer.bind(idx))
		grid.add_child(b)
	# 有選項太長、兩欄放不下時，改成一欄
	if cols == 2:
		var half := (348.0 - 8.0) / 2.0
		for b in grid.get_children():
			if b.get_node("Math").get_combined_minimum_size().x + 28.0 > half:
				grid.columns = 1
				break


func _on_answer(idx: int) -> void:
	if not predicting:
		return
	predict_tries += 1
	if idx != int(cur_q.correct):
		var grid := predict_box.get_child(1)
		var b: Button = grid.get_child(idx)
		b.disabled = true
		b.modulate = Color(1.0, 0.55, 0.6)
		Game.of(self).sfx("wrong")
		_record(cur_q.tag)
		if r.type == "chord":
			chord_errs += 1
		_hint("還不對，再想想：\n" + cur_q.nudge, "bad")
		return

	predicting = false
	_clear(predict_box)
	Game.of(self).sfx("correct")
	if _custom_type(r.type):
		_custom_answered()
		return
	if r.type == "table":
		_table_reveal()
		return
	if r.type == "count":
		_finish_round(predict_tries == 1 and mislocks == 0, predict_tries + mislocks)
		return
	if r.type == "cross":
		stage.reveal_roots()
		_finish_round(cross_fails == 0 and predict_tries == 1, cross_fails + predict_tries)
		return
	if r.type == "chord" and chord_phase == 2:
		_finish_round(chord_errs == 0, 1 + chord_errs)
		return
	# 連續預言題：一題一題把參數問出來（例如第一章試煉：先 a、再 k、再 h）
	if r.has("chain") and chain_i < r.chain.size():
		if chain_i == 0:
			predicted_ok = predict_tries == 1
		_hint("答對了！\n" + cur_q.why, "good")
		var nq: Dictionary = shuffle_q(r.chain[chain_i])
		chain_i += 1
		_show_question(nq)
		hint_panel.visible = true
		return
	if not r.has("chain"):
		predicted_ok = predict_tries == 1
	if predicted_ok:
		score += 50
		_hint("預言正確！+50\n" + cur_q.why, "good")
	else:
		_hint("答對了！\n" + cur_q.why, "good")
	_enter_step2()


# ================= 步驟 2：各類型的操作 =================

func _enter_step2() -> void:
	stage.ghost_on = true
	stage.hide_curve = false
	step_label.text = UITheme.step_bar(_steps(), 1 if r.type != "count" else 0)
	formula_label.visible = r.type != "rank"
	sliders_box.visible = true
	energy_label.visible = r.type != "count" and r.type != "cross"
	go_btn.visible = r.type != "cross"
	go_btn.disabled = false
	_set_sliders(true)
	match r.type:
		"fit":
			go_btn.text = "點亮光橋"
			if r.get("live", false):
				_abs_demo(time_left <= 0.0)
		"rank":
			go_btn.text = "確認配對"
			story_label.text = "替每條曲線選出正確的底數。"
			_build_rank_rows()
		"quadrant":
			go_btn.text = "點亮燈塔"
			alt_btn.text = "做不到！"
			alt_btn.visible = true
			alt_btn.disabled = false
			stage.lamp_target = r.target
		"count":
			go_btn.text = "鎖定"
			task_label.visible = true
			_show_goal()
			_abs_demo(time_left <= 0.0)
		"cross":
			task_label.visible = true
			var n: int = r.roots.size()
			task_label.text = "左右拖動掃描線，找出全部 %d 個交點。" % n if n > 0 \
				else "左右拖動掃描線，看看兩條光橋會不會相交。"
			stage.scan_on = true
			stage.set_scan(vals.s)
		"chord":
			# 凹口比大小：不用滑桿，在舞台上點 P、Q 連出弦
			chord_phase = 1
			sliders_box.visible = false
			energy_label.visible = false
			go_btn.visible = false
			formula_label.visible = true
			task_label.visible = true
			task_label.text = "在左邊點一下 P、再點一下 Q，把兩點連成一條弦。"
			stage.chord_on = true
	_update_hud()


## 凹口比大小：弦畫好了，接著比大小
func _on_chord_drawn() -> void:
	if revealing or chord_phase != 1:
		return
	chord_phase = 2
	task_label.visible = false
	Game.of(self).sfx("ping")
	_hint("[color=#ff7eb6]M[/color]：函數值的平均；[color=#5ad8ff]N[/color]：中點的函數值。", "info")
	var q: Dictionary = r.final
	_show_question(q)
	hint_panel.visible = true


## 底數辨識：每條曲線一列，點選底數晶片（手機也好按）
func _build_rank_rows() -> void:
	rank_box.visible = true
	_clear(rank_box)
	rank_options.clear()
	var sorted_b: Array = r.bases.duplicate()
	sorted_b.sort()
	for i in r.bases.size():
		var c: Color = RANK_COLORS[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var tag := Label.new()
		tag.text = RANK_TAGS[i]
		tag.custom_minimum_size = Vector2(36, 42)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag.add_theme_font_size_override("font_size", UITheme.fs(20))
		tag.add_theme_color_override("font_color", Color("1a1530"))
		tag.add_theme_stylebox_override("normal", UITheme.box(c, 12, Color(0, 0, 0, 0), 0, 0))
		row.add_child(tag)
		var group := ButtonGroup.new()
		var chips := []
		for b in sorted_b:
			var chip := Button.new()
			chip.text = UITheme.nice_text(b)
			chip.toggle_mode = true
			chip.button_group = group
			chip.focus_mode = Control.FOCUS_NONE
			chip.custom_minimum_size = Vector2(0, 42)
			chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			chip.add_theme_font_size_override("font_size", UITheme.fs(17))
			UITheme.tight(chip)
			var on := UITheme.box(c.darkened(0.55), 12, c, 2, 4)
			chip.add_theme_stylebox_override("pressed", on)
			chip.add_theme_stylebox_override("hover_pressed", on)
			chip.set_meta("base", b)
			row.add_child(chip)
			chips.append(chip)
		rank_box.add_child(row)
		rank_options.append(chips)


func _show_goal() -> void:
	var goals: Array = r.goals
	task_label.text = "任務 %d／%d：讓交點恰好有 %d 個" % [goal_idx + 1, goals.size(), goals[goal_idx]]


func _on_go() -> void:
	if marking:
		_check_marks()
		return
	if stroke_pending:
		_submit_stroke()
		return
	if busy or predicting:
		return
	match r.type:
		"fit":
			busy = true
			tries += 1
			go_btn.disabled = true
			_set_sliders(false)
			stage.start_run()
		"rank":
			_check_rank()
		"quadrant":
			_check_quadrant(false)
		"count":
			_check_goal()
		"table":
			_check_table_bands()
		_:
			if _custom_type(r.type):
				_custom_go()


func _on_impossible() -> void:
	if stroke_pending:
		_redraw_stroke()
		return
	if busy or predicting or r.type != "quadrant":
		return
	_check_quadrant(true)


# ---------- fit：光靈奔跑結束 ----------

func _on_run_finished(success: bool, reason: String) -> void:
	if revealing:
		_hint("這是正確的光橋：\n" + _formula() + "\n\n" + r.insight, "info")
		_end_round()
		_abs_demo(true)
		return
	if success:
		stage.celebrate()
		_finish_round(tries == 1 and predicted_ok, tries)
		_abs_demo(not stage.demo_btn)
		return
	var head := "光靈被黑洞吸走了！" if reason == "hole" else "光靈在寶石前掉下去了！"
	_fail(head + "\n" + _diagnose())


# ---------- table：列表作圖 ----------

const SIGN_TEXT := {1: "＞", 0: "＝", -1: "＜"}


func _table_start() -> void:
	table_mist = 0
	predicting = false
	_clear(predict_box)
	step_label.text = UITheme.step_bar(_steps(), 0)
	formula_label.visible = true
	task_label.visible = false
	sliders_box.visible = false
	energy_label.visible = false
	go_btn.visible = false
	_build_table()
	_table_focus(0)


## 上面：這一格的比較題（主角）；下面：紀錄表（x／左邊／右邊／比較）
func _build_table() -> void:
	rank_box.visible = true
	_clear(rank_box)
	table_cells.clear()
	table_done.clear()
	# 比較題卡片
	var card := PanelContainer.new()
	var g := UITheme.ACCENT
	card.add_theme_stylebox_override("panel", UITheme.box(Color(g.r, g.g, g.b, 0.08), 14, Color(g.r, g.g, g.b, 0.45), 1, 12))
	rank_box.add_child(card)
	table_ask = card
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	table_q_label = Label.new()
	table_q_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_q_label.add_theme_font_size_override("font_size", UITheme.fs(17))
	table_q_label.add_theme_color_override("font_color", UITheme.ACCENT)
	v.add_child(table_q_label)
	table_line = MathLabel.new()
	table_line.font_size = UITheme.fs(24)
	table_line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(table_line)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	table_chips.clear()
	for sg in [1, 0, -1]:
		var chip := Button.new()
		chip.text = {1: "左大 ＞", 0: "相等 ＝", -1: "右大 ＜"}[sg]
		chip.custom_minimum_size = Vector2(0, 46)
		UITheme.tight(chip)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.focus_mode = Control.FOCUS_NONE
		chip.add_theme_font_size_override("font_size", UITheme.fs(17))
		chip.set_meta("silent", true)
		chip.pressed.connect(func(): _on_table_pick(_table_cur(), sg))
		row.add_child(chip)
		table_chips.append(chip)
	# 紀錄表
	var cap := Label.new()
	cap.text = "紀錄表"
	cap.add_theme_font_size_override("font_size", UITheme.fs(13))
	cap.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(cap)
	var grid := GridContainer.new()
	grid.columns = r.xs.size() + 1
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	rank_box.add_child(grid)
	var rows := [[], [], [], []]
	var heads := [_row_head_text("x"), _row_head_math(r.lhs, Stage.CURVE_COL),
		_row_head_math(r.rhs, QUAD_COL), _row_head_text("比較")]
	var spec := [[UITheme.TEXT, 15], [Stage.CURVE_COL, 13], [QUAD_COL, 13], [UITheme.GOOD, 16]]
	for k in 4:
		grid.add_child(heads[k])
		for i in r.xs.size():
			var c := _cell(x_text(r.xs[i]) if k == 0 else "", spec[k][0], spec[k][1])
			rows[k].append(c)
			grid.add_child(c)
	for i in r.xs.size():
		table_cells.append({"head": rows[0][i], "e": rows[1][i], "q": rows[2][i], "cmp": rows[3][i]})
		table_done.append(false)


func _row_head_text(t: String) -> Control:
	var l := Label.new()
	l.text = t
	l.custom_minimum_size = Vector2(52, 26)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", UITheme.fs(13))
	l.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	return l


func _row_head_math(expr: String, c: Color) -> Control:
	var cc := CenterContainer.new()
	cc.custom_minimum_size = Vector2(52, 26)
	var m := MathLabel.new()
	m.font_size = UITheme.fs(15)
	m.color = c
	m.text = expr
	cc.add_child(m)
	return cc


func _cell(t: String, c: Color, fs: int) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(0, maxi(26, UITheme.fs(fs) + 8))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	l.add_theme_font_size_override("font_size", UITheme.fs(fs))
	l.add_theme_color_override("font_color", c)
	l.add_theme_stylebox_override("normal", UITheme.box(Color(1, 1, 1, 0.05), 6, Color(0, 0, 0, 0), 0, 1))
	return l


func _table_cur() -> int:
	return table_done.find(false)


## 表格裡 x 的寫法：整數照寫，0.25 寫成 1/4
static func x_text(x) -> String:
	var v := float(x)
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v))) if v >= 0.0 else "−%d" % int(-roundf(v))
	for d in [2, 3, 4, 5, 8, 9]:
		var n: float = v * d
		if is_equal_approx(n, roundf(n)):
			return ("%d/%d" if v > 0 else "−%d/%d") % [absi(int(roundf(n))), d]
	return UITheme.num(v, 2)


## 把 x 代進式子：2^{x} → 2^{−2}、x^{2} → (−2)^{2}、log_{2} x → log_{2} (1/4)
static func _sub_x(expr: String, x) -> String:
	var v := x_text(x)
	var plain := float(x) >= 0.0 and is_equal_approx(float(x), roundf(float(x)))
	var out := expr.replace("{x}", "{%s}" % v)
	return out.replace("x", v if plain else "(%s)" % v)


func _table_focus(i: int) -> void:
	for j in table_cells.size():
		var h: Label = table_cells[j].head
		var on := j == i
		var g := UITheme.ACCENT
		h.add_theme_stylebox_override("normal", UITheme.box(
			Color(g.r, g.g, g.b, 0.22) if on else Color(1, 1, 1, 0.07), 6, g, 2 if on else 0, 1))
		h.add_theme_color_override("font_color", g if on else UITheme.TEXT)
	if i < 0:
		return
	var xs := x_text(r.xs[i])
	table_q_label.text = "x = %s 時，哪一邊比較大？" % xs
	table_q_label.add_theme_color_override("font_color", UITheme.ACCENT)
	var g2 := UITheme.ACCENT
	table_ask.add_theme_stylebox_override("panel", UITheme.box(Color(g2.r, g2.g, g2.b, 0.08), 14, Color(g2.r, g2.g, g2.b, 0.45), 1, 12))
	table_line.text = "[color=#%s]%s[/color]   ？   [color=#%s]%s[/color]" % [
		Stage.CURVE_COL.to_html(false), _sub_x(r.lhs, r.xs[i]),
		QUAD_COL.to_html(false), _sub_x(r.rhs, r.xs[i])]
	for chip in table_chips:
		chip.disabled = false
		chip.modulate = Color.WHITE
	table_cells[i].cmp.text = "?"
	table_cells[i].cmp.add_theme_color_override("font_color", UITheme.ACCENT)
	stage.table_cur = i


func _on_table_pick(i: int, sg: int) -> void:
	if i < 0 or table_done[i]:
		return
	if i != _table_cur():
		return
	var cell: Dictionary = table_cells[i]
	var want: int = r.signs[i]
	var ev: float = r.e_vals[i]
	var qv: float = r.q_vals[i]
	if sg != want:
		table_mist += 1
		var bad: Button = table_chips[[1, 0, -1].find(sg)]
		bad.disabled = true
		bad.modulate = Color(1.0, 0.55, 0.6)
		Game.of(self).sfx("wrong")
		_record(r.get("tag", "exp_quad_cross"))
		table_q_label.text = "算算看：左邊 = %s，右邊 = %s。再選一次！" % [UITheme.nice_text(ev), UITheme.nice_text(qv)]
		table_q_label.add_theme_color_override("font_color", UITheme.BAD)
		var bc := UITheme.BAD
		table_ask.add_theme_stylebox_override("panel", UITheme.box(Color(bc.r, bc.g, bc.b, 0.08), 14, Color(bc.r, bc.g, bc.b, 0.6), 1, 12))
		return
	hint_panel.visible = false
	table_done[i] = true
	cell.e.text = UITheme.nice_text(ev)
	cell.q.text = UITheme.nice_text(qv)
	cell.cmp.text = SIGN_TEXT[want]
	cell.cmp.add_theme_color_override("font_color", Color.WHITE if want == 0 else UITheme.GOOD)
	if want == 0:
		var gold := Color(1, 0.85, 0.4)
		cell.cmp.add_theme_stylebox_override("normal", UITheme.box(Color(gold.r, gold.g, gold.b, 0.25), 6, gold, 1, 1))
	stage.show_table_point(i)
	Game.of(self).play("bell", Game.semi(Game.scale_semi(3 + i)), -7.0)
	var nxt := _table_cur()
	_table_focus(nxt)
	if nxt < 0:
		_table_step2()


func _table_step2() -> void:
	table_ask.visible = false
	stage.table_cur = -1
	step_label.text = UITheme.step_bar(_steps(), 1)
	story_label.visible = false
	task_label.visible = true
	task_label.text = "選出交點所在的區間（整數點上的交點不用選）。"
	stage.bands_on = true
	if stage.reveal_t < 0.0:
		stage.reveal_curves()        # 選區間時就把兩條曲線畫出來
	go_btn.visible = true
	go_btn.disabled = false
	hint_panel.visible = false
	_update_band_ui()


## 依目前選了幾個區間，更新按鈕文字，並在紀錄表上框出對應的兩格
func _update_band_ui() -> void:
	if r.type != "table" or not stage.bands_on:
		return
	var n: int = stage.band_sel.count(true)
	go_btn.text = "確認送出" if n == 0 else "確認送出（已選 %d 個）" % n
	var gold := Color(1, 0.85, 0.4)
	for j in table_cells.size():
		var inside: bool = (j < stage.band_sel.size() and stage.band_sel[j]) or (j > 0 and stage.band_sel[j - 1])
		var cell: Label = table_cells[j].cmp
		if inside:
			cell.add_theme_stylebox_override("normal", UITheme.box(Color(gold.r, gold.g, gold.b, 0.18), 6, gold, 2, 1))
		elif r.signs[j] == 0:
			cell.add_theme_stylebox_override("normal", UITheme.box(Color(gold.r, gold.g, gold.b, 0.25), 6, gold, 1, 1))
		else:
			cell.add_theme_stylebox_override("normal", UITheme.box(Color(1, 1, 1, 0.05), 6, Color(0, 0, 0, 0), 0, 1))


func _check_table_bands() -> void:
	var want: Array = r.flips
	if stage.band_sel == want:
		Game.of(self).sfx("correct")
		stage.bands_on = false
		go_btn.visible = false
		story_label.visible = false
		task_label.visible = false
		_show_question(r.final)
		rank_box.visible = true          # 表格留著，判斷個數時還用得到
		return
	table_mist += 1
	Game.of(self).sfx("wrong")
	_record(r.get("tag", "exp_quad_cross"))
	_hint("還不對：看圖上兩條曲線交叉的地方，落在哪幾格之間？", "bad")


## 答對個數後，把兩條曲線從左到右畫出來
func _table_reveal() -> void:
	var total := table_mist + predict_tries - 1
	rank_box.visible = false
	story_label.visible = true
	_finish_round(total == 0, total + 1)
	step_label.text = UITheme.step_bar(_steps(), 3)
	if stage.reveal_t < 0.0:
		stage.reveal_curves()


# ---------- draw：徒手作圖 ----------

var sketch_fails := 0


func _sketch_start() -> void:
	predicting = false
	sketch_fails = 0
	_clear(predict_box)
	formula_label.visible = true
	task_label.visible = true
	sliders_box.visible = false
	energy_label.visible = true
	go_btn.visible = false
	if stage.begin_mark():
		_mark_ui("曲線")
	else:
		_sketch_draw_ui()
	_update_hud()


func _sketch_draw_ui() -> void:
	step_label.text = UITheme.step_bar(_steps(), 1)
	task_label.text = "在左圖畫出這個函數（畫滿畫面，可分多筆），再按「確認送出」。"
	go_btn.visible = false
	stage.draw_on = true


# ---------- 找整數點：畫圖之前，先標出曲線經過的整數點 ----------

var marking := false
var mark_errs := 0


func _mark_ui(what: String) -> void:
	marking = true
	mark_errs = 0
	stage.draw_on = false
	if r.type == "draw":
		step_label.text = UITheme.step_bar(_steps(), 0)
	task_label.text = "先在左圖點出%s經過的整數點，再按「確認整數點」。" % what
	go_btn.text = "確認整數點"
	go_btn.visible = true
	go_btn.disabled = true      # 至少點選一個整數點才能確認（見 _process）
	hint_panel.visible = false


func _check_marks() -> void:
	var targets: Array = stage.mark_targets
	var wrong := []
	for p in stage.mark_sel:
		if not targets.has(p):
			wrong.append(p)
	var missing := 0
	for p in targets:
		if not stage.mark_sel.has(p):
			missing += 1
	if wrong.is_empty() and missing == 0:
		Game.of(self).sfx("correct")
		_mark_finish("整數點都找到了！接著把它們連成圖形。")
		return
	mark_errs += 1
	if r.type == "cross":
		cross_fails += 1
	for p in wrong:
		stage.mark_sel.erase(p)
	stage.mark_bad = wrong
	stage.queue_redraw()
	var msg := ""
	if not wrong.is_empty():
		msg += "有 %d 個點不在曲線上（紅色的）。" % wrong.size()
	if missing > 0:
		msg += "還少 %d 個點。" % missing
	_record(r.get("draw_tag", r.get("tag", "draw_graph")))
	if mark_errs >= 2:
		# 錯兩次：直接把整數點標出來，繼續畫圖
		Game.of(self).sfx("wrong")
		stage.mark_sel = targets.duplicate()
		stage.mark_bad = []
		_mark_finish("看這裡：金色的點就是曲線經過的整數點。把它們連起來畫出圖形。")
		return
	_fail(msg + "\n代幾個整數 x 進去算算看，y 也是整數的點才算。")


func _mark_finish(msg: String) -> void:
	marking = false
	stage.mark_on = false
	stage.mark_done = true
	stage.queue_redraw()
	_hint(msg, "good" if mark_errs < 2 else "info")
	if r.type == "cross":
		_cross_draw_ui(stage.cross_sketch)
	else:
		_sketch_draw_ui()


var stroke_pending := false              # 徒手作圖：畫好了，等學生按「確認送出」或「重畫一次」
var pending_pts := PackedVector2Array()


## 放開手指：先不評分，讓學生自己決定要送出還是重畫
func _on_stroke(pts: PackedVector2Array) -> void:
	if r.type != "draw" and r.type != "cross":
		return
	if busy or not stage.draw_on or (r.type == "cross" and stage.cross_sketch == 0):
		return
	if _accidental(pts):
		return
	stroke_pending = true
	stage.stroke_bad = []
	_pending_ui()
	Game.of(self).play("blip", 1.1, -12.0)
	_hint("可以繼續畫下一筆。\n畫完按「確認送出」；畫錯按「擦掉上一筆」。", "info")


## 已經畫了幾筆：送出／擦掉上一筆
func _pending_ui() -> void:
	go_btn.text = "確認送出  ✓"
	go_btn.visible = true
	go_btn.disabled = false
	alt_btn.text = "擦掉上一筆"
	alt_btn.visible = true
	alt_btn.disabled = false


func _submit_stroke() -> void:
	stroke_pending = false
	go_btn.visible = false
	alt_btn.visible = false
	stage.draw_on = true
	var all: Array = stage.strokes.duplicate()
	stage.clear_on_next = true       # 評分後再落筆，就是重新畫一次
	if r.type == "cross":
		_on_cross_stroke(all)
	else:
		_judge_sketch(all)


## 擦掉上一筆（全部擦完就回到還沒畫的狀態）
func _redraw_stroke() -> void:
	if not stage.strokes.is_empty():
		stage.strokes.pop_back()
	stage.stroke_bad = []
	stage.queue_redraw()
	Game.of(self).play("blip", 0.9, -12.0)
	if stage.strokes.is_empty():
		stroke_pending = false
		go_btn.visible = false
		alt_btn.visible = false
		_hint("擦掉了。重新畫吧，這次不算作答，也不扣能量。", "info")
	else:
		_pending_ui()
		_hint("擦掉上一筆了。還剩 %d 筆。" % stage.strokes.size(), "info")


func _judge_sketch(all: Array) -> void:
	if r.type != "draw" or busy or not stage.draw_on:
		return
	var res: Dictionary = stage.judge_strokes(all)
	stage.stroke_bad = res.bad
	tries += 1
	if res.ok:
		stage.draw_on = false
		stage.draw_reveal = true
		stage.celebrate()
		_finish_round(tries == 1, tries)
		_abs_demo(true)
		hint_label.text = "吻合度 %d%%\n" % res.score + hint_label.text
		return
	sketch_fails += 1
	Game.of(self).sfx("wrong")
	_record(r.get("tag", "draw_graph"))
	var extra := ""
	if sketch_fails == 1:
		stage.hint_keys = stage.keys_for_hint()
	if sketch_fails == 1 and not stage.hint_keys.is_empty():
		stage.draw_show_keys = true
		extra = "\n提示：圖上標出了一些一定會經過的點。"
	elif sketch_fails >= 2 and stage.has_asymptote():
		if stage.hint_keys.is_empty():
			stage.hint_keys = stage.keys_for_hint()
		stage.draw_show_keys = true
		stage.draw_show_asym = true
		extra = "\n提示：紅色虛線是漸近線，曲線會貼著它但不會碰到。"
	_fail("吻合度 %d%%：%s%s" % [res.score, res.reason, extra])


## 防誤觸：只是點一下、或畫得很短就放開，不算一次作答，也不扣能量
func _accidental(pts: PackedVector2Array) -> bool:
	var why: String = stage.accidental_reason(pts)
	if why == "":
		return false
	if not stage.strokes.is_empty() and stage.strokes.back() == pts:
		stage.strokes.pop_back()
	stage.stroke_bad = []
	stage.queue_redraw()
	Game.of(self).play("blip", 0.8, -14.0)
	_hint("沒關係，這次不算、也不扣能量。\n" + why, "info")
	return true


# ---------- cross：先畫兩條圖形，再數交點 ----------

var cross_fails := 0   # 這一題畫錯的總次數


func _cross_side_name(side: int) -> String:
	var c: Color = Stage.CURVE_COL if side == 1 else QUAD_COL
	return "[color=#%s]y = %s[/color]" % [c.to_html(false), r.lhs if side == 1 else r.rhs]


func _cross_start() -> void:
	predicting = false
	sketch_fails = 0
	cross_fails = 0
	_clear(predict_box)
	sliders_box.visible = false
	go_btn.visible = false
	alt_btn.visible = false
	energy_label.visible = true
	formula_label.visible = true
	task_label.visible = true
	_cross_begin_side(1)


func _cross_begin_side(side: int) -> void:
	sketch_fails = 0
	stage.begin_cross_sketch(side)
	step_label.text = UITheme.step_bar(_steps(), side - 1)
	stage.guide_pts = []
	if stage.begin_mark():
		_mark_ui(" " + _cross_side_name(side) + " ")
	else:
		for g in r.get("guides", {}).get(side, []):
			stage.guide_pts.append([Vector2(g[0], g[1]), String(g[2])])
		_cross_draw_ui(side)
		if not stage.guide_pts.is_empty():
			task_label.text += "\n圖形會通過畫面上標出的三個點。"
	_update_hud()


func _cross_draw_ui(side: int) -> void:
	go_btn.visible = false
	stage.draw_on = true
	task_label.text = ("第 %d 步：在左邊畫出 " % side) + _cross_side_name(side) + "（畫滿整個畫面，可以分好幾筆）。畫好後按「確認送出」。"
	if stage.cross_seg_count() > 1:
		task_label.text += "\n這個圖形有兩支：兩支都畫好再一起送出。"


func _on_cross_stroke(all: Array) -> void:
	if busy or not stage.draw_on or stage.cross_sketch == 0:
		return
	var side: int = stage.cross_sketch
	stage.seg_target = -1
	var res: Dictionary = stage.judge_strokes(all)
	stage.stroke_bad = res.bad
	tries += 1
	if res.ok:
		Game.of(self).sfx("correct")
		stage.finish_cross_side(side)
		if side == 1:
			# 徒手作圖題不播絕對值翻轉示範（學生已經自己畫出來了）
			_hint("畫對了！吻合度 %d%%\n接下來畫第二條。" % res.score, "good")
			_cross_begin_side(2)
		else:
			_hint("兩條都畫對了！吻合度 %d%%\n看看它們交在哪裡、交了幾次。" % res.score, "good")
			_show_question(r.final)
			hint_panel.visible = true
		return
	sketch_fails += 1
	cross_fails += 1
	Game.of(self).sfx("wrong")
	_record(r.get("draw_tag", "draw_graph"))
	var extra := ""
	if sketch_fails == 1:
		stage.hint_keys = stage.keys_for_hint()
	if sketch_fails == 1 and not stage.hint_keys.is_empty():
		stage.draw_show_keys = true
		extra = "\n提示：圖上標出了一些一定會經過的點。"
	elif sketch_fails >= 2 and stage.has_asymptote():
		if stage.hint_keys.is_empty():
			stage.hint_keys = stage.keys_for_hint()
		stage.draw_show_keys = true
		stage.draw_show_asym = true
		extra = "\n提示：紅色虛線是漸近線，曲線會貼著它但不會碰到。"
	_fail("吻合度 %d%%：%s%s" % [res.score, res.reason, extra])


func _on_root_found(_i: int, _x: float) -> void:
	Game.of(self).sfx("ping")


func _check_cross_done() -> void:
	if cross_done or busy:
		return
	var done := false
	if r.roots.is_empty():
		var need: Vector2 = r.get("need", Vector2(-3.0, 3.0))
		done = stage.swept.x <= need.x and stage.swept.y >= need.y
	else:
		done = not stage.cross_found.has(false)
	if not done:
		return
	cross_done = true
	_set_sliders(false)
	var gen := round_gen
	await get_tree().create_timer(0.7, false).timeout
	if gen != round_gen:
		return
	stage.celebrate()
	_finish_round(predicted_ok, predict_tries)


# ---------- rank ----------

func _check_rank() -> void:
	var wrong := []
	var picked := []
	for i in rank_options.size():
		var sel: Button = null
		for chip in rank_options[i]:
			chip.modulate = Color.WHITE
			if chip.button_pressed:
				sel = chip
		if sel == null:
			_hint("每條曲線都要選一個底數喔！", "bad")
			return
		picked.append(sel)
		if not is_equal_approx(float(sel.get_meta("base")), float(r.bases[i])):
			wrong.append(i)
	tries += 1
	if wrong.is_empty():
		stage.reveal_bases = true
		stage.celebrate()
		_finish_round(tries == 1 and predicted_ok, tries)
		return
	for i in wrong:
		picked[i].modulate = Color(1.0, 0.55, 0.6)
	Game.of(self).sfx("wrong")
	_record("exp_base_compare")
	_fail("有 %d 條曲線配錯了（紅色）。\n" % wrong.size() + r.get("rank_fail", "比一比 x = 1 那條線上的高度：越高，底數越大。"))


# ---------- quadrant ----------

func _check_quadrant(said_impossible: bool) -> void:
	tries += 1
	var lit: Array = Stage.quadrants_of(r.form, vals.a, vals.h, vals.k, vals.m)
	stage.lamp_lit = lit
	if not said_impossible:
		for n in lit.size():
			Game.of(self).play("bell", Game.semi(Game.scale_semi(4 + n)), -6.0, 0.09 * n)
	var impossible: bool = r.get("impossible", false)
	if said_impossible:
		if impossible:
			stage.celebrate()
			_finish_round(tries == 1 and predicted_ok, tries)
		else:
			_record("quadrant")
			Game.of(self).sfx("wrong")
			_fail("做得到喔！k 的正負決定是否進 Ⅲ；y 截距決定過 Ⅱ 或 Ⅳ。")
		return
	var target: Array = r.target.duplicate()
	target.sort()
	if not impossible and lit == target:
		stage.celebrate()
		_finish_round(tries == 1 and predicted_ok, tries)
		return
	_record("quadrant")
	Game.of(self).sfx("wrong")
	if impossible:
		_fail("曲線一直往上：左貼 y = k、右進 Ⅰ。真能四個都過嗎？")
		return
	var msg := "亮的是第 %s 象限，還不對。\n" % "、".join(lit.map(func(q): return ROMAN[q]))
	if target.has(3) and not lit.has(3):
		msg += "要進 Ⅲ，漸近線 y = k 要小於 0。"
	elif lit.has(3) and not target.has(3):
		msg += "左邊貼著 y = k。k < 0 時就會跑進第三象限。"
	else:
		msg += "y 截距 2^{−h} + k 的正負，決定過 Ⅱ 或 Ⅳ。"
	_fail(msg)


# ---------- count ----------

func _check_goal() -> void:
	var n: int = stage.roots_of(vals.c).size()
	var goals: Array = r.goals
	if n == goals[goal_idx]:
		stage.celebrate()
		Game.of(self).sfx("correct")
		goal_idx += 1
		if goal_idx >= goals.size():
			_set_sliders(false)
			go_btn.visible = false
			task_label.visible = false
			_show_question(r.final)
			return
		_hint("✓ 任務完成！c = %s 時恰有 %d 個交點。" % [UITheme.num(vals.c, 2), n], "good")
		_show_goal()
		return
	mislocks += 1
	Game.of(self).sfx("wrong")
	_record("solution_count")
	if mislocks >= 4:
		# 卡太久：直接示範一個可行的 c
		var rg: Array = _range("c")
		var c := float(rg[0])
		while c <= float(rg[1]) + 1e-6:
			if stage.roots_of(c).size() == goals[goal_idx]:
				sliders["c"].value = c
				break
			c += float(rg[2])
		_hint("c = %s 時有 %d 個交點。注意它和頂點、雷射牆的位置。" % [UITheme.num(vals.c, 2), goals[goal_idx]], "info")
		return
	_hint("現在 %d 個交點，目標 %d 個。水平線該在頂點或雷射牆的哪一側？" % [n, goals[goal_idx]], "bad")


# ---------- 共用：失敗、示範、結算 ----------

## 終焉之塔：心用完了，示範答案後結束攀登
func _tower_out() -> void:
	if not revealing and not busy:
		_reveal("三顆心都用完了…")
	elif not revealing:
		_end_round()


func _fail(msg: String) -> void:
	# 終焉之塔：同一次答錯已經在 _record 扣過心了
	if not (tower_mode and _recorded_frame == Engine.get_process_frames()):
		energy -= 1
	if energy <= 0:
		_reveal("能量用完了…")
		return
	_hint(msg, "bad")
	busy = false
	_set_sliders(true)
	go_btn.disabled = false
	_update_hud()


## 能量用完或時間到：直接示範正解
func _reveal(msg: String) -> void:
	if tower_mode and msg.begins_with("時間到"):
		energy -= 1          # 終焉之塔：超時也扣一顆心
	busy = true
	revealing = true
	perfect_run = 0
	stroke_pending = false
	marking = false
	stage.mark_on = false
	alt_btn.visible = false
	if buddy:
		buddy.say(Buddy.line("reveal"), "worried", 2.8)
	_set_sliders(false)
	go_btn.disabled = true
	alt_btn.disabled = true
	if _custom_type(r.type):
		_custom_reveal(msg)
		_update_hud()
		return
	match r.type:
		"chord":
			stage.chord_on = false
			stage.chord_t = maxf(stage.chord_t, 1.0)
			chord_phase = 2
			_clear(predict_box)
			_hint(msg + "\n\n" + r.insight, "info")
			_end_round()
		"cross":
			stage.draw_on = false
			stage.cross_sketch = 0
			stage.cross_drawn = [true, true]
			stage.reveal_roots()
			_hint(msg + " 兩條圖形都畫出來了：共 %d 個交點。\n\n%s" % [r.roots.size(), r.insight], "info")
			_end_round()
		"draw":
			stage.draw_on = false
			stage.draw_reveal = true
			_hint(msg + " 金色的是正確的圖形。\n\n" + r.insight, "info")
			_end_round()
			_abs_demo(true)
		"fit":
			for p in r.params:
				set_param(p, r.answer[p])
			_hint(msg + " 看光靈示範正確的光橋…", "bad")
			stage.start_run()
		"rank":
			stage.reveal_bases = true
			_hint(msg + " 正確的底數已標在曲線上。\n\n" + r.insight, "info")
			_end_round()
		"quadrant":
			for p in r.params:
				set_param(p, r.answer[p])
			stage.lamp_lit = Stage.quadrants_of(r.form, vals.a, vals.h, vals.k, vals.m)
			var extra := "這個任務做不到：遞增的指數曲線最多只過 3 個象限。" if r.get("impossible", false) \
				else "例如 h = %s、k = %s 就能達成。" % [UITheme.num(vals.h, 2), UITheme.num(vals.k, 2)]
			_hint(msg + " " + extra + "\n\n" + r.insight, "info")
			_end_round()
	_update_hud()


func _finish_round(perfect: bool, attempts: int) -> void:
	var stars := 3 if perfect else (2 if attempts <= 2 else 1)
	round_stars = stars
	var gain := stars * 100
	if r.has("time"):
		gain += int(time_left) * 3
	score += gain
	total_stars += stars
	perfect_run = perfect_run + 1 if stars == 3 else 0
	if buddy:
		if perfect_run >= 2:
			buddy.say(Buddy.line("streak", perfect_run), "happy", 2.6)
		else:
			buddy.say(Buddy.line("perfect" if stars == 3 else "pass"), "happy", 2.6)
	Game.of(self).sfx("success")
	Game.of(self).quest_event("correct", {"stars": stars, "review": review_mode, "timed": r.has("time")})
	_hint("過關！%s  +%d\n\n%s" % [_star_text(stars, 3), gain, r.insight], "good")
	_end_round()


func _end_round() -> void:
	busy = true
	predicting = false
	step_label.text = UITheme.step_bar(_steps(), _steps().size())
	go_btn.visible = false
	alt_btn.visible = false
	_set_sliders(false)
	sliders_box.visible = false
	energy_label.visible = false
	rank_box.visible = false
	task_label.visible = false
	next_btn.visible = true
	if tower_mode:
		next_btn.text = ("前往第 %d 層  ▲" % (tower_floor + 1)) if energy > 0 else "看攀登結果  ▶"
	elif review_mode:
		next_btn.text = "下一題  ▶" if review_i < review_n - 1 else "看修煉結果  ▶"
	elif journey_mode:
		next_btn.text = "看結果  ▶"
	else:
		next_btn.text = "完成關卡  ★" if ri == rounds.size() - 1 else "下一段旅程  ▶"
	_update_hud()


## fit 旅程：根據學生目前的參數，指出最可能的錯誤類型
func _diagnose() -> String:
	var ans: Dictionary = r.answer
	var form: String = r.form
	var get_ans := func(p): return float(ans.get(p, r.get("fixed", {}).get(p, vals[p])))
	if r.params.has("m") and not is_equal_approx(vals.m, get_ans.call("m")):
		_record("exp_ratio")
		return "起始值不對：M 是 x = 0 時的高度。"
	if r.params.has("a"):
		var a: float = vals.a
		if is_equal_approx(a, 1.0):
			if Stage.is_log(form):
				return "對數的底數不能是 1（1 的幾次方都是 1）！"
			return "a = 1 時曲線是水平線，不是指數函數喔！"
		if (a > 1.0) != (get_ans.call("a") > 1.0):
			_record("exp_monotonic")
			if form == "abs_in":
				return "形狀反了！a > 1 是山谷，0 < a < 1 是山峰。"
			return "方向反了！a > 1 往右上升，0 < a < 1 往右下降。"
	var h_wrong: bool = r.params.has("h") and not is_equal_approx(vals.h, get_ans.call("h"))
	var k_wrong: bool = r.params.has("k") and not is_equal_approx(vals.k, get_ans.call("k"))
	if r.has("diagnose") and (h_wrong or k_wrong):
		_record(r.diagnose.tag)
		return r.diagnose.text
	if Stage.is_log(form):
		var lmsg := _diagnose_log(form, h_wrong, k_wrong)
		if lmsg != "":
			return lmsg
	if r.id == "absorb" and (h_wrong or k_wrong):
		_record("exp_shift_coef")
		return "係數寫成底數的次方（4·2^{x} = 2^{x+2}），再讀平移量。"
	match form:
		"abs_in":
			if h_wrong:
				_record("abs_symmetry")
				return "對稱軸不對：等高兩寶石的中點就是 x = h。"
			if k_wrong:
				_record("asymptote_shift")
				return "高度不對：頂點是 (h, 1 + k)。"
		"abs_out":
			if k_wrong:
				_record("abs_reflect")
				return "反彈點是 a^{x} + k = 0 的解；漸近線是 y = |k|。"
		_:
			if k_wrong:
				_record("asymptote_shift")
				if r.params.has("h"):
					return "高度不對：恆過點 (h, 1 + k)，漸近線 y = k。"
				return "高度不對：一定過 (0, 1 + k)。"
			if h_wrong:
				_record("exp_fixed_point")
				return "左右位置不對。恆過點 (h, 1 + k) 的 x 座標就是 h。"
	var g: Vector2 = r.gems.back()
	if r.params.has("m"):
		return "起始值對了！倍率差一點：相鄰兩顆寶石的高度比，就是 a 的幾次方。"
	return "快對了！把寶石 (%s, %s) 代入算 a。" \
		% [UITheme.num(g.x, 2), UITheme.num(g.y, 2)]


func _diagnose_log(form: String, h_wrong: bool, k_wrong: bool) -> String:
	match form:
		"log_abs_in", "log_abs_both":
			if h_wrong:
				_record("log_abs")
				return "對稱軸不對：等高兩寶石的中點就是 x = h。"
			if k_wrong:
				_record("log_abs")
				return "高度不對。|x − h| = 1 的兩顆寶石高度就是 k。"
		"log_abs_out":
			if k_wrong or h_wrong:
				_record("log_abs")
				return "反彈點是 log_{a}(x − h) + k = 0 的解；雷射牆 x = h。"
		_:
			if h_wrong:
				_record("log_asymptote")
				return "左右不對：雷射牆 x = h 在寶石左邊，過 (1 + h, k)。"
			if k_wrong:
				_record("log_fixed_point")
				return "高度不對：一定過 (1 + h, k)。"
	if r.params.has("a"):
		var g: Vector2 = r.gems.back()
		return "底數差一點：y = 1 時 x = a，或代入寶石 (%s, %s)。" \
			% [UITheme.num(g.x, 2), UITheme.num(g.y, 2)]
	return ""


## 光靈對提示的反應：提示框上的臉換表情；答錯時從舞台左下角冒出來說一句
func _buddy_react(kind: String) -> void:
	if hint_face == null:
		return
	hint_face.mood = {"good": "happy", "bad": "worried"}.get(kind, "normal")
	hint_face.jump()
	if kind == "bad":
		wrong_streak += 1
		if wrong_streak == 3:
			buddy.say(Buddy.line("wrong3"), "worried", 3.0)
		elif not revealing:
			buddy.say(Buddy.line("wrong"), "worried", 1.8)
	elif kind == "good":
		wrong_streak = 0


func _input(e: InputEvent) -> void:
	if (e is InputEventMouseButton or e is InputEventKey) and e.pressed:
		idle_t = 0.0


func _buddy_process(delta: float) -> void:
	if hint_face == null:
		return
	# 臉跟著提示框
	var show: bool = hint_panel.is_visible_in_tree() and side_card.modulate.a > 0.5
	hint_face.visible = show
	if show:
		hint_face.position = hint_panel.global_position + Vector2(-20, -22)
	# 太久沒動：打瞌睡
	if r.is_empty() or busy or get_tree().paused or idle_shown:
		return
	idle_t += delta
	if idle_t > 40.0:
		idle_shown = true
		buddy.say(Buddy.line("idle"), "sleepy", 3.4)


func _process(delta: float) -> void:
	_buddy_process(delta)
	_fit_side()
	# 找整數點：一個點都還沒選時，「確認整數點」是暗的、不能按
	if marking and stage.mark_on and go_btn.visible:
		var none: bool = stage.mark_sel.is_empty()
		if go_btn.disabled != none:
			go_btn.disabled = none
	# 終焉之塔：連預言題也在計時
	if r.is_empty() or not r.has("time") or busy or (predicting and not _custom_type(r.type) and not tower_mode):
		return
	time_left -= delta
	_update_hud()
	if time_left <= 0.0:
		time_left = 0.0
		if r.type == "fit" or r.type == "quadrant" or (tower_mode and r.type in ["rank", "draw", "cross"]):
			_reveal("時間到！")
		elif _custom_type(r.type):
			_custom_timeout()


func _update_hud() -> void:
	if r.is_empty():
		return
	journey_label.text = r.title
	var breaks := []
	for i in range(1, rounds.size()):
		if rounds[i].chapter != rounds[i - 1].chapter:
			breaks.append(i)
	if tower_mode:
		journey_label.text = "終焉之塔　第 %d 層" % tower_floor
		pips.setup(0, 0, [])
	elif review_mode:
		journey_label.text = ("今日修煉　" if review_kind == "daily" else "弱點練習　") + r.title
		pips.setup(review_n, review_i, [])
	elif journey_mode:
		pips.setup(chapter_slots.size(), cur_slot_idx, [])
	else:
		pips.setup(rounds.size(), ri, breaks)
	_update_q_nav()
	if not _dust_anim:
		score_label.text = str(int(Game.of(self).inv.dust))
	var t := "能量  " + "♥".repeat(clampi(energy, 0, MAX_ENERGY)) + "♡".repeat(clampi(MAX_ENERGY - energy, 0, MAX_ENERGY))
	if r.has("time"):
		t += "　　◷ %d 秒" % ceili(time_left)
	energy_label.text = t


func _on_next() -> void:
	if tower_mode:
		Game.of(self).tower_report(round_stars, energy)
		return
	if review_mode:
		Game.of(self).session_report(round_stars)
		return
	ri += 1
	if ri < rounds.size():
		_start_round()
	elif journey_mode:
		_finish_journey()
	else:
		_finish()


func _star_text(n: int, total: int) -> String:
	return "★".repeat(n) + "☆".repeat(total - n)


# ================= 題目列表（每段旅程的完成度與解鎖） =================

const TYPE_NAMES := {"fit": "調整光橋", "rank": "底數辨識", "quadrant": "象限燈塔", "count": "交點調頻",
	"table": "列表作圖", "cross": "交點獵人", "draw": "徒手作圖",
	"forge": "逐步鍛造", "speed": "連續速算", "tune": "參數調頻"}


func _chapter_slots(ch: int) -> Array:
	return bank_slots().filter(func(sl): return sl.chapter == ch)


func _jkey(slot: Dictionary) -> String:
	return level_id() + "/" + slot.id


## 這段旅程有幾種題型答對過（0 ～ 1）
func _completion(slot: Dictionary) -> float:
	var n := 0
	for vi in Game.of(self).cleared_of(_jkey(slot)):
		if int(vi) < slot.variants.size():
			n += 1
	return float(n) / maxf(1.0, slot.variants.size())


func _chapter_completion(ch: int) -> float:
	var sl := _chapter_slots(ch)
	var sum := 0.0
	for slot in sl:
		sum += _completion(slot)
	return sum / maxf(1.0, sl.size())


## 第一題一開始就開放；之後每一題要等前一題答對過才解鎖
func _unlocked(slots: Array, i: int) -> bool:
	return i == 0 or Game.of(self).dev_unlock_all or not Game.of(self).cleared_of(_jkey(slots[i - 1])).is_empty()


func _show_journeys(ch: int) -> void:
	journey_mode = true
	chapter_now = ch
	chapter_slots = _chapter_slots(ch)
	for b in [go_btn, alt_btn, next_btn]:
		b.visible = false
	var item: Dictionary = level_chapters()[0]
	for it in level_chapters():
		if it.ch == ch:
			item = it
	var c: Color = item.color
	var o := _overlay(c, 1010)
	var layer: Control = o[0]
	layer.set_meta("journey_list", true)
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 12)
	col.add_child(_big_label(item.name, 30, c))
	col.add_child(_big_label("完成度 %d%%" % roundi(100.0 * _chapter_completion(ch)), 16, UITheme.TEXT_DIM))
	col.add_child(_chest_status(ch, layer))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	col.add_child(grid)
	for i in chapter_slots.size():
		var open := _unlocked(chapter_slots, i)
		var card := _journey_card(chapter_slots[i], i, open, c)
		if open:
			var idx := i
			card.pressed.connect(func():
				layer.queue_free()
				_play_journey(ch, idx))
		grid.add_child(card)
	var back := UITheme.ghost_button("返回章節", 16)
	back.icon = UITheme.icon("back", 16, UITheme.TEXT_DIM)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func():
		layer.queue_free()
		_show_menu())
	col.add_child(back)
	# 第一次進入第二章：先看說明卡
	if ch == 2 and _chapter_completion(ch) == 0.0:
		_show_chapter_card()
	elif _chest_ready(ch):
		_open_chest(ch)      # 以前就全部通過、還沒開過寶箱的章節（更新前的存檔）


## 一張旅程卡：編號、名稱、題型、最佳星數、完成度條；鎖住的卡片變暗
func _journey_card(slot: Dictionary, i: int, open: bool, c: Color) -> Button:
	var g = Game.of(self)
	var comp := _completion(slot)
	var full := comp >= 0.999
	var b := Button.new()
	b.custom_minimum_size = Vector2(228, 114)
	b.focus_mode = Control.FOCUS_NONE
	var edge := UITheme.ACCENT if full else (Color(c.r, c.g, c.b, 0.55) if open else Color(1, 1, 1, 0.08))
	var normal := UITheme.box(UITheme.PANEL_LIGHT if open else UITheme.PANEL, 14, edge, 2 if full else 1, 12)
	var hover := UITheme.box(UITheme.PANEL_LIGHT.lightened(0.1), 14, c, 2, 12)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover if open else normal)
	b.add_theme_stylebox_override("pressed", hover if open else normal)
	b.add_theme_stylebox_override("disabled", normal)
	if not open:
		b.disabled = true
		b.set_meta("silent", true)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top"]:
		m.add_theme_constant_override("margin_" + side, 12)
	m.add_theme_constant_override("margin_bottom", 18)     # 進度條和下邊框多留一點距離
	b.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	var num := Label.new()
	num.text = str(i + 1)
	num.custom_minimum_size = Vector2(28, 28)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", UITheme.fs(15))
	var nc := c if open else Color(0.42, 0.44, 0.56)
	num.add_theme_color_override("font_color", nc)
	var nb := UITheme.box(Color(nc.r, nc.g, nc.b, 0.14), 12, nc, 2, 0)
	nb.corner_detail = 16
	num.add_theme_stylebox_override("normal", nb)
	top.add_child(num)
	var name_l := Label.new()
	name_l.text = slot.title
	name_l.add_theme_font_size_override("font_size", UITheme.fs(17))
	name_l.add_theme_color_override("font_color", UITheme.TEXT if open else UITheme.TEXT_DIM)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.clip_text = true
	# 名字長（五個字以上）時字縮小一點，整個名字都放得下
	var nfs := UITheme.fs(17)
	var name_w := 228.0 - 24.0 - 28.0 - 8.0
	var nfont := name_l.get_theme_font("font")
	while nfs > UITheme.fs(13) and nfont.get_string_size(slot.title, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x > name_w:
		nfs -= 1
	name_l.add_theme_font_size_override("font_size", nfs)
	top.add_child(name_l)
	var tp := Label.new()
	tp.add_theme_font_size_override("font_size", UITheme.fs(13))
	tp.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	v.add_child(tp)
	if open:
		tp.text = slot.get("type_name", TYPE_NAMES.get(slot.type, "")) + ("　·　限時" if slot.has("time") else "")
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		v.add_child(row)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = 100
		bar.value = 100.0 * comp
		bar.custom_minimum_size = Vector2(0, 8)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.08), 4, Color(0, 0, 0, 0), 0, 0))
		bar.add_theme_stylebox_override("fill", UITheme.box(UITheme.ACCENT if full else c, 4, Color(0, 0, 0, 0), 0, 0))
		row.add_child(bar)
		var pct := Label.new()
		pct.text = "%d%%" % roundi(100.0 * comp)
		pct.custom_minimum_size = Vector2(44, 0)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pct.add_theme_font_size_override("font_size", UITheme.fs(15))
		pct.add_theme_color_override("font_color", UITheme.ACCENT if full else UITheme.TEXT)
		row.add_child(pct)
		# 星星放在進度條這一行最右邊，讓上面的名字可以用整行
		var best := int(g.stars.get(_jkey(slot), 0))
		var st := Label.new()
		st.text = _star_text(best, 3)
		st.add_theme_font_size_override("font_size", UITheme.fs(15))
		st.add_theme_color_override("font_color", UITheme.ACCENT if best > 0 else Color(1, 1, 1, 0.22))
		row.add_child(st)
	else:
		tp.text = "完成上一題解鎖"
		var lock := TextureRect.new()
		lock.texture = UITheme.icon("lock", 16, UITheme.TEXT_DIM)
		lock.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		lock.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		v.add_child(lock)
	for node in b.find_children("*", "Control", true, false):
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## 只玩一段旅程：優先抽還沒答對過的題型
func _play_journey(ch: int, i: int) -> void:
	journey_mode = true
	chapter_now = ch
	chapter_slots = _chapter_slots(ch)
	cur_slot_idx = i
	var slot: Dictionary = chapter_slots[i]
	var done: Array = Game.of(self).cleared_of(_jkey(slot))
	var cands := []
	for vi in slot.variants.size():
		if not done.has(vi):
			cands.append(vi)
	if cands.is_empty():
		cands = range(slot.variants.size())
	var total := 0.0
	for vi in cands:
		total += float(slot.variants[vi].get("weight", 1))
	var t := randf() * total
	var pick: int = cands.back()
	for vi in cands:
		t -= float(slot.variants[vi].get("weight", 1))
		if t <= 0.0:
			pick = vi
			break
	var rd := make_round(slot, slot.variants[pick])
	rd["vi"] = pick
	rounds = [rd]
	ri = 0
	score = 0
	total_stars = 0
	round_stars = 0
	_start_round()


## 從修煉之間進來：只玩指定的那一題
func _review_begin(a: Dictionary) -> void:
	var it: Dictionary = a.review
	review_mode = true
	review_i = int(a.get("review_i", 0))
	review_n = int(a.get("review_n", 1))
	review_kind = String(a.get("review_kind", "daily"))
	tower_mode = review_kind == "tower"
	tower_floor = int(a.get("tower_floor", 0))
	pause_menu.list_label = "放棄攀登" if tower_mode else "結束修煉"
	var slot: Dictionary = {}
	for sl in bank_slots():
		if sl.id == it.slot:
			slot = sl
	if slot.is_empty():
		Game.of(self).session_report(0)
		return
	var vi := clampi(int(it.vi), 0, slot.variants.size() - 1)
	journey_mode = false
	chapter_now = slot.chapter
	chapter_slots = _chapter_slots(slot.chapter)
	var rd := make_round(slot, slot.variants[vi])
	rd["vi"] = vi
	if tower_mode:
		rd["time"] = minf(float(rd.get("time", 999.0)), float(a.get("tower_time", 120.0)))
	rounds = [rd]
	ri = 0
	score = 0
	total_stars = 0
	_start_round()
	if tower_mode:
		energy = int(a.get("tower_hearts", 3))
		_update_hud()


## 上方白點兩側的「上一題／下一題」小按鈕
func _nav_q_button(text: String, tip: String) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(36, 36)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", UITheme.fs(24))
	b.add_theme_color_override("font_color", UITheme.TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.25))
	for st in [["normal", Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.12)],
			["hover", Color(1, 1, 1, 0.14), UITheme.CYAN.darkened(0.1)],
			["pressed", UITheme.CYAN.darkened(0.5), UITheme.CYAN],
			["disabled", Color(1, 1, 1, 0.03), Color(1, 1, 1, 0.06)]]:
		var sb := UITheme.box(st[1], 16, st[2], 1, 0)
		sb.corner_detail = 16
		b.add_theme_stylebox_override(st[0], sb)
	b.visible = false
	return b


func _update_q_nav() -> void:
	if prev_q_btn == null:
		return
	prev_q_btn.visible = journey_mode
	next_q_btn.visible = journey_mode
	if not journey_mode:
		return
	prev_q_btn.disabled = cur_slot_idx <= 0
	var has_next := cur_slot_idx + 1 < chapter_slots.size()
	var open := has_next and _unlocked(chapter_slots, cur_slot_idx + 1)
	next_q_btn.disabled = not open
	if open or not has_next:
		next_q_btn.text = "›"
		next_q_btn.icon = null
		next_q_btn.tooltip_text = "下一題" if has_next else "已經是最後一題"
	else:
		next_q_btn.text = ""
		next_q_btn.icon = UITheme.icon("lock", 14, Color(1, 1, 1, 0.45))
		next_q_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		next_q_btn.tooltip_text = "答對這一題才會解鎖下一題"


## 直接換到上一題／下一題（這一題目前的進度不保留）
func _jump_journey(d: int) -> void:
	if not journey_mode:
		return
	var i := cur_slot_idx + d
	if i < 0 or i >= chapter_slots.size() or not _unlocked(chapter_slots, i):
		return
	Game.of(self).play("blip", 1.1 if d > 0 else 0.9, -10.0)
	_close_modals()
	_play_journey(chapter_now, i)


## 關掉關卡畫面上開著的視窗（選單、結算、說明卡…）
func _close_modals() -> void:
	for c in get_children():
		if c is Control and c.get_child_count() == 2 and c.get_child(0) is ColorRect and c.get_child(1) is CenterContainer:
			c.queue_free()


## 暫停選單的「返回關卡列表」：停下這一題，回到這一章的題目列表
func _back_to_list() -> void:
	if tower_mode:
		Game.of(self).tower_abort()
		return
	if review_mode:
		Game.of(self).session_abort()
		return
	round_gen += 1
	busy = true
	stage.running = false
	_close_modals()
	if journey_mode:
		_show_journeys(chapter_now)
	else:
		_show_menu()


func _finish_journey() -> void:
	var g = Game.of(self)
	var slot: Dictionary = chapter_slots[cur_slot_idx]
	var key := _jkey(slot)
	var has_next := cur_slot_idx + 1 < chapter_slots.size()
	var next_was_locked := has_next and not _unlocked(chapter_slots, cur_slot_idx + 1)
	var passed := round_stars > 0
	var new_type := false
	var rw := {"dust": 0, "lines": []}
	if passed:
		new_type = g.mark_cleared(key, int(r.get("vi", 0)))
		g.record_stars(key, round_stars)
		_record_level_stars()
		rw = g.journey_reward(key, int(r.get("vi", 0)), round_stars, slot.has("time"))
	var comp := _completion(slot)
	g.sfx("fanfare" if passed else "open")
	var item_color: Color = UITheme.ACCENT
	for it in level_chapters():
		if it.ch == chapter_now:
			item_color = it.color
	var o := UITheme.modal(self, item_color, 480)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(_big_label(slot.title, 30, UITheme.ACCENT))
	if passed:
		var big := _big_label(_star_text(round_stars, 3), 54, UITheme.ACCENT)
		big.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.1, 0.5))
		big.add_theme_constant_override("shadow_offset_y", 4)
		col.add_child(big)
	else:
		col.add_child(_big_label("這次是看示範過關的，再挑戰一次吧！", 18, UITheme.TEXT))
	if int(rw.dust) > 0:
		col.add_child(_reward_row({"dust": int(rw.dust)}, "（" + "、".join(rw.lines) + "）"))
		_dust_count_up(int(rw.dust))
	# 完成度
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	var cap := Label.new()
	cap.text = "完成度"
	cap.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	row.add_child(cap)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 100
	bar.value = 100.0 * comp
	bar.custom_minimum_size = Vector2(0, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.08), 6, Color(0, 0, 0, 0), 0, 0))
	bar.add_theme_stylebox_override("fill", UITheme.box(UITheme.ACCENT, 6, Color(0, 0, 0, 0), 0, 0))
	row.add_child(bar)
	var pct := Label.new()
	pct.text = "%d%%" % roundi(100.0 * comp)
	pct.add_theme_font_size_override("font_size", UITheme.fs(17))
	pct.add_theme_color_override("font_color", UITheme.ACCENT)
	row.add_child(pct)
	var left: int = slot.variants.size() - roundi(comp * slot.variants.size())
	var msg := ""
	if comp >= 0.999:
		msg = "這段旅程的每一種題型都答對了！"
	elif new_type:
		msg = "答對一種新題型！還有 %d 種等你挑戰。" % left
	else:
		msg = "還有 %d 種題型等你挑戰。" % left
	if next_was_locked and _unlocked(chapter_slots, cur_slot_idx + 1):
		msg += "\n解鎖下一題：「%s」" % chapter_slots[cur_slot_idx + 1].title
	var ml := _big_label(msg, 16, UITheme.TEXT)
	ml.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	ml.custom_minimum_size = Vector2(420, 0)
	col.add_child(ml)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	col.add_child(gap)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	col.add_child(btns)
	var mk := func(text: String, accent: bool, cb: Callable) -> Button:
		var bt := Button.new()
		bt.text = text
		bt.custom_minimum_size = Vector2(0, 50)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if accent:
			UITheme.accent_button(bt, 18)
		else:
			bt.add_theme_font_size_override("font_size", UITheme.fs(17))
		bt.pressed.connect(func():
			layer.queue_free()
			cb.call())
		btns.add_child(bt)
		return bt
	var ch := chapter_now
	var idx := cur_slot_idx
	var can_next := has_next and _unlocked(chapter_slots, idx + 1)
	if can_next:
		mk.call("題目列表", false, func(): _show_journeys(ch))
		mk.call("再玩一次", not passed, func(): _play_journey(ch, idx))
		mk.call("下一題  ▶", true, func(): _play_journey(ch, idx + 1))
	else:
		# 這一章的最後一題：重玩在左、回到題目列表在右（往前走的方向）
		mk.call("再玩一次", not passed, func(): _play_journey(ch, idx))
		mk.call("回到題目列表  ▶", passed, func(): _show_journeys(ch))
	level_cleared.emit(round_stars)
	# 這一章的旅程全部通過了：打開章節大寶箱
	if passed and _chest_ready(ch):
		get_tree().create_timer(0.7).timeout.connect(func():
			if is_instance_valid(layer):
				_open_chest(ch))


## 回報問題用：現在是哪一關、哪一題、第幾種題型、第幾步
func _report_context() -> String:
	if r.is_empty():
		return "%s %s（選單）" % [level_id(), level_title()]
	var parts := PackedStringArray([level_id() + " " + level_title(), "旅程 %s「%s」" % [r.get("id", "?"), r.get("title", "")],
		"題型 %d" % (int(r.get("vi", 0)) + 1)])
	var st = get("si")
	if st != null and r.get("type", "") == "forge":
		parts.append("第 %d 步" % (int(st) + 1))
	if tower_mode:
		parts.append("終焉之塔第 %d 層" % tower_floor)
	var eq := String(r.get("eq", "")).replace("\n", " ")
	if eq != "":
		parts.append("題目：" + eq.left(80))
	return "，".join(parts)


# ================= 主線獎勵：星塵與章節大寶箱 =================

func _chest_key(ch: int) -> String:
	return level_id() + "_c%d" % ch


func _chest_final(ch: int) -> bool:
	var chs := level_chapters()
	return not chs.is_empty() and int(chs.back().ch) == ch


## 這一章的每段旅程都至少通過一次
func _chapter_all_cleared(ch: int) -> bool:
	var g = Game.of(self)
	for slot in _chapter_slots(ch):
		if g.cleared_of(_jkey(slot)).is_empty():
			return false
	return true


func _chest_ready(ch: int) -> bool:
	return not review_mode and _chapter_all_cleared(ch) and not Game.of(self).chest_claimed(_chest_key(ch))


## 一排物品：圖示＋數量（例如 星塵 ×200、光之碎片 ×30）；note 是小字說明
func _reward_row(got: Dictionary, note: String = "") -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	var names := {"dust": "星塵", "shard": "光之碎片", "crystal": "光之結晶"}
	for k in ["dust", "shard", "crystal"]:
		if not got.has(k):
			continue
		var ic := QP.ItemIcon.new()
		ic.kind = k
		ic.custom_minimum_size = Vector2(30, 30)
		row.add_child(ic)
		var l := Label.new()
		l.text = "%s +%d　" % [names[k], int(got[k])]
		l.add_theme_font_override("font", UITheme.bold_font())
		l.add_theme_font_size_override("font_size", UITheme.fs(20))
		l.add_theme_color_override("font_color", UITheme.ACCENT if k == "dust" else (UITheme.CYAN_LIGHT if k == "shard" else UITheme.VIOLET_LIGHT))
		row.add_child(l)
	if note != "":
		v.add_child(_big_label(note, 13, UITheme.TEXT_DIM))
	return v


## 右上角的星塵數字從舊的值跳到新的值
func _dust_count_up(gain: int) -> void:
	var to := int(Game.of(self).inv.dust)
	var from := to - gain
	_dust_anim = true
	score_label.text = str(from)
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_method(func(v: float): score_label.text = str(int(round(v))), float(from), float(to), 0.8)
	tw.parallel().tween_property(score_label, "scale", Vector2(1.25, 1.25), 0.2)
	tw.tween_property(score_label, "scale", Vector2.ONE, 0.2)
	tw.tween_callback(func(): _dust_anim = false)
	score_label.pivot_offset = score_label.size / 2.0


## 題目列表上方：這一章的寶箱狀態
func _chest_status(ch: int, list_layer: Control) -> Control:
	var g = Game.of(self)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var ic := QP.ItemIcon.new()
	ic.kind = "chest"
	ic.custom_minimum_size = Vector2(34, 34)
	row.add_child(ic)
	var sl := _chapter_slots(ch)
	var done := 0
	for slot in sl:
		if not g.cleared_of(_jkey(slot)).is_empty():
			done += 1
	var l := Label.new()
	l.add_theme_font_size_override("font_size", UITheme.fs(15))
	if g.chest_claimed(_chest_key(ch)):
		l.text = "章節大寶箱　已打開 ✓"
		l.add_theme_color_override("font_color", UITheme.GOOD)
		ic.modulate = Color(1, 1, 1, 0.45)
	else:
		l.text = "章節大寶箱：通過這一章全部 %d 段旅程就能打開（%d／%d）" % [sl.size(), done, sl.size()]
		l.add_theme_color_override("font_color", UITheme.ACCENT if done >= sl.size() else UITheme.TEXT_DIM)
	row.add_child(l)
	return row


## 章節大寶箱：寶箱跳一跳 → 點「打開」→ 東西飛出來、加進持有物品
func _open_chest(ch: int) -> void:
	var g = Game.of(self)
	if not _chest_ready(ch):
		return
	var item_name := level_title()
	var c: Color = UITheme.ACCENT
	for it in level_chapters():
		if it.ch == ch:
			item_name = it.name
			c = it.color
	g.sfx("open")
	var o := UITheme.modal(self, c, 440)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(_big_label(item_name, 26, c))
	col.add_child(_big_label("全部通過！獲得章節大寶箱", 17, UITheme.TEXT))
	var holder := CenterContainer.new()
	col.add_child(holder)
	var box := ChestFx.new()
	box.custom_minimum_size = Vector2(400, 190)
	box.glow = c
	holder.add_child(box)
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(0, 52)
	col.add_child(info)
	var btn := Button.new()
	btn.text = "打開寶箱！"
	btn.custom_minimum_size = Vector2(240, 54)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UITheme.accent_button(btn, 19)
	col.add_child(btn)
	var state := [0]      # 0 還沒開、1 動畫中、2 開好了
	box.tapped.connect(func():
		if state[0] == 0:
			btn.pressed.emit())
	btn.pressed.connect(func():
		if state[0] == 2:
			layer.queue_free()
			_refresh_journey_list(ch)
			return
		if state[0] == 1:
			return
		state[0] = 1
		btn.disabled = true
		var got: Dictionary = g.claim_chest(_chest_key(ch), _chest_final(ch))
		# 1) 寶箱抖三下（音越來越高）
		for i in 3:
			g.play("bell", Game.semi(Game.scale_semi(2 + i * 2)), -10.0, 0.18 * i)
		box.shake_open(func():
			# 2) 蓋子彈開、光芒和星星噴出來
			g.sfx("fanfare")
			# 3) 物品一個一個跳出來
			var row := _reward_row(got, "可以到扭蛋機抽裝扮、或到碎片兌換所換指定的裝扮")
			info.add_child(row)
			_pop_in_row(row)
			if got.has("dust"):
				_dust_count_up(int(got.dust))
			btn.disabled = false
			btn.text = "收下"
			state[0] = 2))


## 獎勵那一排：每個物品依序從小彈到正常大小
func _pop_in_row(row: Control) -> void:
	var items: Array = []
	var line: Node = row.get_child(0)
	for n in line.get_children():
		items.append(n)
	for i in items.size():
		var n: Control = items[i]
		n.modulate.a = 0.0
		var tw := n.create_tween()
		tw.tween_interval(0.12 * int(i / 2))
		tw.tween_callback(func():
			n.pivot_offset = n.size / 2.0
			n.scale = Vector2(0.3, 0.3)
			if i % 2 == 0:
				Game.of(self).play("bell", Game.semi(Game.scale_semi(5 + i)), -12.0))
		tw.tween_property(n, "modulate:a", 1.0, 0.12)
		tw.parallel().tween_property(n, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if row.get_child_count() > 1:
		var note: Control = row.get_child(1)
		note.modulate.a = 0.0
		note.create_tween().tween_property(note, "modulate:a", 1.0, 0.4).set_delay(0.5)


## 章節大寶箱的動畫：晃動 → 抖三下 → 蓋子打開、光芒旋轉、星星噴出
class ChestFx extends Control:
	signal tapped
	const UITheme := preload("game_theme.gd")
	var glow := UITheme.GOLD
	var t := 0.0
	var phase := 0          # 0 等待（輕輕晃）、1 抖動、2 打開
	var pt := 0.0           # 這個階段經過的時間
	var lid := 0.0          # 0 關著、1 全開
	var parts: Array = []
	var _done: Callable

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP      # 點寶箱也能打開
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if phase == 0:
				tapped.emit()
			accept_event()

	func shake_open(done: Callable) -> void:
		phase = 1
		pt = 0.0
		_done = done

	func _process(dt: float) -> void:
		t += dt
		pt += dt
		if phase == 1 and pt >= 0.6:
			phase = 2
			pt = 0.0
			_burst()
			if _done.is_valid():
				_done.call()
		if phase == 2:
			lid = minf(1.0, lid + dt * 4.0)
			if pt < 1.2 and randf() < 0.5:
				_spawn(1)
		for p in parts:
			p.v.y += 260.0 * dt
			p.p += p.v * dt
			p.life -= dt * 0.7
		parts = parts.filter(func(p): return p.life > 0.0)
		queue_redraw()

	func _mouth() -> Vector2:
		return Vector2(size.x / 2.0, size.y * 0.58)

	func _burst() -> void:
		_spawn(26)

	func _spawn(n: int) -> void:
		var cols := [UITheme.GOLD, UITheme.GOLD_PALE, UITheme.CYAN_LIGHT, UITheme.VIOLET_LIGHT, glow]
		for i in n:
			var ang := randf_range(-PI * 0.85, -PI * 0.15)
			var sp := randf_range(160.0, 330.0)
			parts.append({"p": _mouth() + Vector2(randf_range(-30, 30), 0), "v": Vector2(cos(ang), sin(ang)) * sp,
				"life": randf_range(0.7, 1.0), "r": randf_range(4.5, 8.5), "c": cols[randi() % cols.size()]})

	func _draw() -> void:
		var m := _mouth()
		var W := 130.0
		# 晃動
		var off := Vector2.ZERO
		var rot := 0.0
		if phase == 0:
			rot = 0.05 * sin(t * 6.0) * maxf(0.0, sin(t * 1.7))
		elif phase == 1:
			off.x = sin(pt * 70.0) * 4.0 * (0.5 + pt)
			off.y = -absf(sin(pt * 16.0)) * 6.0
		# 打開後：背後旋轉的光芒
		if phase == 2:
			var k := clampf(pt / 0.4, 0.0, 1.0)
			var ra := 0.34 * k * (0.75 + 0.25 * sin(t * 3.0))
			for i in 12:
				var a := t * 0.6 + i * TAU / 12.0
				var L := 120.0 + 10.0 * sin(t * 2.0 + i)
				var tri := PackedVector2Array([m, m + Vector2(cos(a - 0.09), sin(a - 0.09)) * L, m + Vector2(cos(a + 0.09), sin(a + 0.09)) * L])
				draw_polygon(tri, PackedColorArray([Color(1, 0.85, 0.4, ra * (0.6 if i % 2 else 1.0)), Color(1, 0.85, 0.4, 0.0), Color(1, 0.85, 0.4, 0.0)]))
			for rr in [70.0, 48.0, 28.0]:
				UITheme.dot(self, m, rr * (0.6 + 0.4 * k), Color(1, 0.92, 0.6, 0.12 * k))
		draw_set_transform(off + m, rot, Vector2.ONE)
		var o := Vector2.ZERO
		# 箱身
		var body := Rect2(o.x - W / 2.0, o.y, W, 66)
		draw_rect(Rect2(body.position + Vector2(4, 6), body.size), Color(0, 0, 0, 0.25))
		draw_rect(body, Color("7a3d1c"))
		draw_rect(Rect2(body.position, Vector2(W, 10)), UITheme.GOLD_DEEP)
		draw_rect(Rect2(body.position.x + W * 0.17, body.position.y, 12, 66), UITheme.GOLD_DEEP)
		draw_rect(Rect2(body.position.x + W * 0.83 - 12, body.position.y, 12, 66), UITheme.GOLD_DEEP)
		# 開口的光
		if lid > 0.0:
			draw_rect(Rect2(o.x - W / 2.0 + 6, o.y - 4, W - 12, 10), Color(1, 0.95, 0.7, 0.9 * lid))
		# 蓋子：關著時是正面（往下蓋），打開時往後翻、看到裡面（比較暗）
		var lh := 40.0
		var front := lh * (1.0 - lid)
		if front > 0.5:
			var lp := PackedVector2Array([Vector2(o.x - W / 2.0, o.y), Vector2(o.x - W / 2.0 + 8, o.y - front),
				Vector2(o.x + W / 2.0 - 8, o.y - front), Vector2(o.x + W / 2.0, o.y)])
			draw_colored_polygon(lp, Color("9a5228"))
			draw_rect(Rect2(o.x - W / 2.0, o.y - 6, W, 6), UITheme.GOLD_DEEP)
			draw_rect(Rect2(o.x - W * 0.33, o.y - front, 12, front), UITheme.GOLD_DEEP)
			draw_rect(Rect2(o.x + W * 0.33 - 12, o.y - front, 12, front), UITheme.GOLD_DEEP)
		if lid > 0.0:
			var back := lh * 1.1 * lid
			var ip := PackedVector2Array([Vector2(o.x - W / 2.0 + 4, o.y - 2), Vector2(o.x - W / 2.0 + 12, o.y - 2 - back),
				Vector2(o.x + W / 2.0 - 12, o.y - 2 - back), Vector2(o.x + W / 2.0 - 4, o.y - 2)])
			draw_colored_polygon(ip, Color("4e2410"))
			draw_rect(Rect2(o.x - W / 2.0 + 12, o.y - 2 - back, W - 24, 6), UITheme.GOLD_DEEP)
		# 鎖
		if lid < 0.5:
			draw_rect(Rect2(o.x - 11, o.y - 8, 22, 26), UITheme.GOLD_LIGHT)
			UITheme.dot(self, o + Vector2(0, 4), 3.5, Color("5a2c10"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# 星星
		for p in parts:
			var a: float = clampf(p.life, 0.0, 1.0)
			_star(p.p, p.r * (0.6 + 0.4 * a), Color(p.c.r, p.c.g, p.c.b, a))

	func _star(c: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for k in 8:
			var a := k * PI / 4.0 + t * 2.0
			pts.append(c + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.4))
		draw_colored_polygon(pts, col)


## 寶箱打開後，題目列表上的寶箱狀態跟著更新（列表開著的話重開一次）
func _refresh_journey_list(ch: int) -> void:
	for n in get_children():
		if n.has_meta("journey_list"):
			n.queue_free()
			_show_journeys.call_deferred(ch)
			return


## 章節星數 = 這一章每段旅程最佳星數的平均；大關星數 = 各章平均（都無條件捨去）
func _record_level_stars() -> void:
	var g = Game.of(self)
	var lid := level_id()
	var sum_ch := 0
	for item in level_chapters():
		var sl := _chapter_slots(item.ch)
		var sum := 0
		for slot in sl:
			sum += int(g.stars.get(_jkey(slot), 0))
		var ch_stars := int(floor(float(sum) / maxf(1.0, sl.size())))
		g.record_stars(lid + "_c%d" % item.ch, ch_stars)
		sum_ch += int(g.stars.get(lid + "_c%d" % item.ch, 0))
	g.record_stars(lid, int(floor(float(sum_ch) / level_chapters().size())))


# ================= 結算畫面 =================

func _finish() -> void:
	var max_stars := rounds.size() * 3
	var stars := 3 if total_stars >= max_stars * 0.85 else (2 if total_stars >= max_stars * 0.6 else 1)
	var g = Game.of(self)
	var lid := level_id()
	g.record_stars(lid + "_c%d" % chapter_now, stars)
	# 關卡列表上顯示的星數 = 各章最佳星數的平均（無條件捨去）
	var sum := 0
	for item in level_chapters():
		sum += int(g.stars.get(lid + "_c%d" % item.ch, 0))
	g.record_stars(lid, int(floor(float(sum) / level_chapters().size())))
	g.sfx("fanfare")
	var chapter_name := level_title()
	for item in level_chapters():
		if item.ch == chapter_now:
			chapter_name = item.name
	var o := UITheme.modal(self, UITheme.ACCENT, 460)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(_big_label(chapter_name, 30, UITheme.ACCENT))
	col.add_child(_big_label("完成！", 18, UITheme.TEXT_DIM))
	var big := _big_label(_star_text(stars, 3), 60, UITheme.ACCENT)
	big.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.1, 0.5))
	big.add_theme_constant_override("shadow_offset_x", 0)
	big.add_theme_constant_override("shadow_offset_y", 4)
	col.add_child(big)
	var info := _big_label("收集星星 %d / %d　·　總分 %d" % [total_stars, max_stars, score], 17, UITheme.TEXT)
	col.add_child(info)
	var qm = get_node_or_null("/root/QuizManager")
	if qm:
		var weak: Array = qm.weakest(2)
		if not weak.is_empty():
			var names := PackedStringArray()
			for item in weak:
				names.append(item.name)
			var w := _big_label("可以再加強\n" + "、".join(names), 15, UITheme.TEXT_DIM)
			w.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
			w.custom_minimum_size = Vector2(400, 0)
			col.add_child(w)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	col.add_child(gap)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var again := Button.new()
	again.text = "再挑戰一次"
	again.custom_minimum_size = Vector2(0, 52)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.add_theme_font_size_override("font_size", UITheme.fs(17))
	again.pressed.connect(func():
		layer.queue_free()
		_begin(chapter_now))
	row.add_child(again)
	var back := Button.new()
	back.text = "選擇章節"
	back.custom_minimum_size = Vector2(0, 52)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.accent_button(back, 19)
	back.pressed.connect(func():
		layer.queue_free()
		_show_menu())
	row.add_child(back)
	level_cleared.emit(stars)


func _record(tag: String) -> void:
	Game.of(self).record_mistake(tag)     # 錯題本（修煉之間用）
	if tower_mode and not busy:
		# 終焉之塔：每答錯一次就扣一顆心
		_recorded_frame = Engine.get_process_frames()
		energy -= 1
		_update_hud()
		if energy <= 0:
			call_deferred("_tower_out")
	var qm = get_node_or_null("/root/QuizManager")
	if qm:
		qm.record_mistake(tag)


# ================= 舞台 =================


# ================= 觀念整理（章節選單上方） =================

## 這一大關的觀念卡片（後面的關卡會自動用自己的 level_id）
func concept_cards() -> Array:
	return Concepts.cards(level_id())


func _concept_color() -> Color:
	var chs := level_chapters()
	return chs[0].color if not chs.is_empty() else UITheme.ACCENT


func _concept_button() -> Button:
	var c := _concept_color()
	var b := Button.new()
	b.custom_minimum_size = Vector2(440, 78)
	b.focus_mode = Control.FOCUS_NONE
	var normal := UITheme.box(Color(c.r, c.g, c.b, 0.12), 14, Color(c.r, c.g, c.b, 0.55), 2, 14)
	var hover := UITheme.box(Color(c.r, c.g, c.b, 0.22), 14, c, 2, 14)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18
	row.offset_right = -18
	row.offset_top = 10        # 文字和上下邊框留一點距離
	row.offset_bottom = -10
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var ic := ConceptIcon.new()
	ic.color = c
	ic.custom_minimum_size = Vector2(34, 34)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(ic)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	var t := Label.new()
	t.text = "觀念整理"
	t.add_theme_font_size_override("font_size", UITheme.fs(20))
	t.add_theme_color_override("font_color", c.lightened(0.25))
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(t)
	var sub := Label.new()
	sub.text = "先猜再揭曉、答題、拼流程：%d 張卡片" % concept_cards().size()
	sub.add_theme_font_size_override("font_size", UITheme.fs(13))
	sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(sub)
	var go := Label.new()
	go.text = "▶"
	go.add_theme_font_size_override("font_size", UITheme.fs(17))
	go.add_theme_color_override("font_color", c)
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	go.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(go)
	return b


var _concept_progress := {}   # 觀念整理：每張卡片揭開到哪裡（同一次遊玩中保留）


func _show_concepts(idx: int = 0) -> void:
	var c := _concept_color()
	var o := UITheme.modal(self, Color(c.r, c.g, c.b, 0.5), 820)
	Game.of(self).sfx("open")
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	var deck := ConceptDeck.new()
	deck.setup(level_title(), concept_cards(), c, _concept_progress, idx)
	deck.closed.connect(func(_start: bool):
		layer.queue_free()
		_show_menu())
	col.add_child(deck)


## 觀念整理按鈕上的小書本
class ConceptIcon extends Control:
	var color := Color.WHITE
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var lift := 2.0 * sin(t * 2.5)
		var l := PackedVector2Array([c + Vector2(-15, -9 + lift), c + Vector2(-1, -6 + lift), c + Vector2(-1, 12), c + Vector2(-15, 9)])
		var r := PackedVector2Array([c + Vector2(15, -9 - lift), c + Vector2(1, -6 - lift), c + Vector2(1, 12), c + Vector2(15, 9)])
		draw_colored_polygon(l, Color(color.r, color.g, color.b, 0.35))
		draw_colored_polygon(r, Color(color.r, color.g, color.b, 0.55))
		draw_polyline(PackedVector2Array([l[0], l[1], l[2], l[3], l[0]]), color, 1.5, true)
		draw_polyline(PackedVector2Array([r[0], r[1], r[2], r[3], r[0]]), color, 1.5, true)
		var sp := c + Vector2(10, -14) + Vector2(0, -3.0 * absf(sin(t * 1.7)))
		UITheme.dot(self, sp, 2.2, Color(1, 0.95, 0.6))


class Stage extends Control:
	signal run_finished(success: bool, reason: String)
	signal step_note(t: float)          # 光靈每走一小步：t = 高度（0 底 ～ 1 頂）
	signal gem_hit(i: int)              # 收集到第 i 顆寶石
	signal fell(reason: String)         # 光靈掉下去
	signal root_found(i: int, x: float) # 交點獵人：找到交點
	signal band_toggled(i: int)         # 列表作圖：點了某個區間
	signal stroke_done(pts: PackedVector2Array)  # 徒手作圖：畫完一筆
	signal chord_tap(i: int)            # 凹口比大小：點到弦的端點（0 = P、1 = Q）
	signal mark_changed                 # 找整數點：點選或取消了一個點
	signal chord_drawn                  # 凹口比大小：弦畫完了

	const CROSS_HW := 3.25
	const CROSS_DOMAIN := Vector2(-6.0, 6.0)

	const RUN_SPEED := 0.4      # 光靈每秒跑過畫面寬度的比例
	const HOLE_PX := 26.0
	const CURVE_COL := UITheme.CYAN
	const GOLD := UITheme.GOLD
	const MIRROR_COL := UITheme.PINK

	var type := "fit"
	var form := "exp"
	var x_range := Vector2(-4, 5)
	var y_range := Vector2(-1.5, 7.0)
	var a := 1.5
	var h := 0.0
	var k := 0.0
	var m := 1.0
	var gems: Array = []
	var gem_state: Array = []
	var holes: Array = []
	var live := true
	var bases: Array = []
	var probe_x := NAN
	var reveal_bases := false
	var line_c := NAN
	var lamp_target: Array = []
	var lamp_lit: Array = []
	var plain := false            # true：只畫天空和遠景，內容交給子節點（例如鍛造台）
	var sky_top := Color("1b1650")
	var sky_bot := Color("0b2a3f")
	var scenery := "mountains"    # 遠景："mountains" 山、"towers" 水晶塔、"lake" 水晶塔＋湖面倒影
	var ambient := ""             # 會動的氣氛層（每關不同）："aurora" 極光、"embers" 火星、"dust" 金塵、
								  # "motes" 魔法泡泡、"fireflies" 螢火蟲、"currents" 海風、"meteors" 流星、"moonsea" 月海
	var mirror := false           # 畫出鏡子 y = x
	var ghost_on := false         # 分身只在預言答完後出現（免得預言時提示和題目不符）
	var ghost := ""               # 鏡中分身："inverse" 對 y = x（反函數）、"x_axis" 對 x 軸；"" 不畫
	var source := {}              # 鏡像配對：給定的原曲線（寶石是它的鏡像）
	var rank_log := false         # 底數辨識：對數曲線（參考線改成 y = 1）
	var probe_y := NAN

	var t := 0.0
	var sky_stars: Array = []
	var particles: Array = []
	var trails: Array = []
	var running := false
	var falling := false
	var show_spirit := false
	var spirits: Array = []
	var spirit_vel := Vector2.ZERO
	var fail_reason := ""
	var curve_gold := 0.0
	var last_step := -1
	var gems_got := 0

	# 交點獵人
	var cross_exp := {}
	var cross_quad = [1.0, 0.0, 0.0]         # 陣列（二次／一次函數）或字典（另一條曲線）
	var cross_dom := CROSS_DOMAIN
	var cross_sketch := 0            # 交點獵人：正在畫第幾條（1 = 左邊的函數、2 = 右邊；0 = 沒在畫）
	var cross_drawn := [false, false]
	var seg_target := -1             # 有兩支的圖形（例如 log|x|）：這一筆只對照第幾支；−1 = 整條
	var segs_done: Array = []        # 這一條已經畫對的支
	var cross_roots: Array = []
	var cross_found: Array = []
	var scan_on := false
	var scan_x := 0.0
	var swept := Vector2(INF, -INF)
	var cam := 0.0
	var cam_target := 0.0

	# 列表作圖
	var table_xs: Array = []
	var table_e: Array = []
	var table_q: Array = []
	var table_signs: Array = []
	var table_shown: Array = []
	var bands_on := false
	var band_sel: Array = []
	var band_hover := -1
	var table_cur := -1           # 目前正在比較的那一格
	var reveal_t := -1.0          # 曲線揭曉進度（−1 = 還沒開始）

	# 徒手作圖
	var draw_on := false
	var drawing := false
	var stroke := PackedVector2Array()
	var strokes: Array = []           # 這次作答已經畫好的每一筆（可以分好幾筆畫，最後一起送出）
	var clear_on_next := false        # 評分過了：下一次落筆時先把舊的筆跡清掉
	var stroke_bad: Array = []
	var draw_keys: Array = []
	var draw_show_keys := false
	var draw_show_asym := false
	var draw_reveal := false
	var hint_keys: Array = []        # 畫錯後顯示的提示點（必經點＋自動挑的漂亮座標點）

	# 找整數點（徒手作圖之前）
	var mark_on := false             # 正在點選整數點
	var guide_pts: Array = []        # 徒手畫圖前先給的參考點 [[Vector2, 標籤], …]（沒有整數點可以標時用）
	var mark_targets: Array = []     # 曲線經過的整數點（答案）
	var mark_sel: Array = []         # 學生點選的點
	var mark_bad: Array = []         # 點錯的點（紅色）
	var mark_done := false           # 找完了：正確的點留在圖上當畫圖的參考

	# 凹口比大小
	var chord := {}                  # {x1, x2}
	var chord_on := false            # 可以點端點了
	var chord_sel: Array = []        # 已經點過的端點
	var chord_t := -1.0              # 弦的動畫進度（−1 = 還沒開始，≥ 1 = 畫完）
	var _chord_emitted := false

	# 絕對值圖形的由來：分步動畫（先畫原本的圖形 → 留一半 → 對稱／翻折）
	const DEMO_STEP := 2.9           # 每一步的秒數（動畫＋停留）
	const DEMO_ANIM := 1.4           # 每一步動畫的秒數
	const DEMO_END := 3.2            # 最後一張停留的秒數（之後淡出）
	const ABS_FORMS := ["abs_in", "abs_out", "abs_y", "log_abs_in", "log_abs_out", "log_abs_both"]
	var demo := {}                   # {form, a, h, k, m}
	var demo_steps: Array = []       # [{op, c, cap}]
	var demo_final := ""
	var demo_t := -1.0               # 播放時間；−1 = 沒在播
	var demo_btn := false            # 顯示「圖形怎麼來的？」按鈕
	var demo_btn_rect := Rect2()
	var hide_curve := false          # 預言題時先不畫光橋（題目問的是這一題的寶石，不是滑桿的預設曲線）

	func _ready() -> void:
		clip_contents = true
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 80:
			sky_stars.append({"p": Vector2(rng.randf(), rng.randf() * 0.75),
				"s": rng.randf_range(0.6, 2.0), "ph": rng.randf() * TAU})

	## 背景分層（手機效能）：天空、遠景這些不會動的多邊形只在大小／場景改變時重畫，
	## 不用每一幀重建 GPU 緩衝區；星星和塔尖的微光是圓點，每幀畫也很便宜。
	var _bg_layers: Array = []
	var _bg_key := []

	## 背景各層：每一幀確認大小、天空顏色、遠景有沒有變，變了才重畫不會動的那幾層
	func _update_bg() -> void:
		if _bg_layers.is_empty():
			for painter in [_paint_sky, _paint_stars, _paint_back, _paint_glow, _paint_front]:
				var layer := _BgLayer.new()
				layer.painter = painter
				add_child(layer, false, Node.INTERNAL_MODE_FRONT)
				_bg_layers.append(layer)
		var key := [size, sky_top, sky_bot, scenery, ambient]
		if key != _bg_key:
			_bg_key = key
			for i in [0, 2, 4]:
				_bg_layers[i].queue_redraw()
		_bg_layers[1].queue_redraw()
		if scenery == "towers" or scenery == "lake":
			_bg_layers[3].queue_redraw()

	func _paint_sky(ci: CanvasItem) -> void:
		var w := size.x
		var hh := size.y
		ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, hh), Vector2(0, hh)]),
			PackedColorArray([sky_top, sky_top, sky_bot, sky_bot]))

	func _paint_stars(ci: CanvasItem) -> void:
		for s in sky_stars:
			var alpha: float = 0.35 + 0.35 * sin(t * 1.6 + s.ph)
			UITheme.dot(ci, Vector2(s.p.x * size.x, s.p.y * size.y), s.s, Color(1, 1, 1, alpha))
		if ambient != "":
			Ambient.paint(ci, ambient, size, t)

	func _paint_back(ci: CanvasItem) -> void:
		if scenery == "towers":
			_tower_row(ci, 0, "shape")
		elif scenery == "lake":
			_tower_row(ci, 0, "shape", LAKE_H)
		elif scenery == "mountains":
			_mountain_on(ci, size.y - 70, 40.0, 0.010, Color(0.12, 0.13, 0.30, 0.9))
			_mountain_on(ci, size.y - 30, 26.0, 0.018, Color(0.06, 0.08, 0.18, 1.0))

	func _paint_glow(ci: CanvasItem) -> void:
		if scenery == "towers":
			_tower_row(ci, 0, "glow")
		elif scenery == "lake":
			_tower_row(ci, 0, "glow", LAKE_H)
			_lake(ci)

	func _paint_front(ci: CanvasItem) -> void:
		if scenery == "towers":
			_tower_row(ci, 1, "shape")
		elif scenery == "lake":
			_tower_row(ci, 1, "shape", LAKE_H)

	## 鏡像之塔的湖：水晶塔倒映在水面上（呼應 y = x 的鏡射），水波會慢慢晃
	const LAKE_H := 40.0
	func _lake(ci: CanvasItem) -> void:
		var hh := size.y
		var wl := hh - LAKE_H
		ci.draw_rect(Rect2(0, wl, size.x, LAKE_H), Color(0.07, 0.09, 0.22, 0.9))
		# 倒影：兩排塔對水面翻下來，越下面越淡、左右輕輕扭動
		for row in 2:
			var c := Color(0.55, 0.38, 0.9, 0.26) if row == 0 else Color(0.4, 0.28, 0.7, 0.34)
			var x := -20.0 + row * 37.0
			var i := 0
			while x < size.x + 40.0:
				var w := 26.0 + 18.0 * fposmod(i * 0.618 + row * 0.3, 1.0)
				var tall := (62.0 if row == 0 else 30.0) * (0.55 + 0.75 * fposmod(i * 0.437 + row * 0.21, 1.0))
				var base := wl
				var k := 0.55          # 倒影壓扁一點
				var sway := 2.0 * sin(t * 1.4 + i)
				var bot := base + (tall + (8.0 if row == 1 else 16.0)) * k
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x, base), Vector2(x + sway, bot),
					Vector2(x + w / 2.0 + sway * 1.5, minf(bot + w * 0.8 * k, hh)), Vector2(x + w + sway, bot), Vector2(x + w, base)]), c)
				x += w + 12.0 + 20.0 * fposmod(i * 0.29, 1.0)
				i += 1
		# 水面亮線與水波
		ci.draw_line(Vector2(0, wl), Vector2(size.x, wl), Color(0.75, 0.6, 1.0, 0.35), 1.5)
		for j in 7:
			var yy := wl + 6.0 + j * 5.0
			var off := fmod(t * (14.0 + j * 3.0) + j * 97.0, 160.0)
			var xx := -160.0 + off
			while xx < size.x:
				ci.draw_line(Vector2(xx, yy), Vector2(xx + 26.0 + 10.0 * (j % 3), yy), Color(0.8, 0.7, 1.0, 0.10 - j * 0.01), 1.2)
				xx += 160.0

	func setup(rd: Dictionary) -> void:
		type = rd.type
		hide_curve = false
		demo_t = -1.0
		demo_btn = false
		chord = rd.get("chord", {})
		mark_on = false
		mark_done = false
		mark_sel = []
		mark_bad = []
		mark_targets = []
		chord_on = false
		chord_sel = []
		chord_t = -1.0
		_chord_emitted = false
		form = rd.get("form", "exp")
		x_range = rd.view_x
		y_range = rd.view_y
		gems = rd.get("gems", [])
		holes = rd.get("holes", [])
		live = rd.get("live", false)
		bases = rd.get("bases", [])
		reveal_bases = false
		plain = rd.get("plain", false)
		mirror = rd.get("mirror", false)
		ghost_on = false
		var gh = rd.get("ghost", "")
		ghost = "inverse" if gh is bool and gh else (gh if gh is String else "")
		source = rd.get("source", {})
		rank_log = rd.get("rank_form", "exp") == "log"
		gem_state = []
		gem_state.resize(gems.size())
		gem_state.fill(0)
		lamp_target = []
		lamp_lit = []
		running = false
		falling = false
		show_spirit = false
		spirits.clear()
		trails.clear()
		curve_gold = 0.0
		scan_on = false
		particles.clear()
		reveal_t = -1.0
		bands_on = false
		band_hover = -1
		table_cur = -1
		draw_on = false
		drawing = false
		stroke = PackedVector2Array()
		strokes = []
		clear_on_next = false
		stroke_bad = []
		draw_show_keys = false
		draw_show_asym = false
		draw_reveal = false
		hint_keys = []
		draw_keys = rd.get("keys", [])
		if type == "table":
			cross_exp = rd.exp
			cross_quad = rd.quad
			cross_roots = rd.roots
			gems = []
			table_xs = rd.xs
			table_e = rd.e_vals
			table_q = rd.q_vals
			table_signs = rd.signs
			table_shown = []
			table_shown.resize(table_xs.size())
			table_shown.fill(false)
			band_sel = []
			band_sel.resize(table_xs.size() - 1)
			band_sel.fill(false)
		if type == "cross":
			cross_exp = rd.exp
			cross_quad = rd.quad
			cross_roots = rd.roots
			cross_found = []
			cross_found.resize(cross_roots.size())
			cross_found.fill(false)
			swept = Vector2(INF, -INF)
			cross_dom = rd.get("domain", CROSS_DOMAIN)
			cross_sketch = 0
			cross_drawn = [false, false]
			# 整個畫面固定（要畫完整的圖形），所有交點都要在畫面裡
			x_range = rd.get("view", {}).get("x", rd.get("domain", rd.view_x))

	# ---------- 數學 ----------

	static func fval(f_form: String, fa: float, fh: float, fk: float, fm: float, x: float, b: int) -> float:
		match f_form:
			"log":
				return fm * log(x - fh) / log(fa) + fk if x - fh > 0.0 else NAN
			"log_abs_in":
				return fm * log(absf(x - fh)) / log(fa) + fk if absf(x - fh) > 0.0 else NAN
			"log_abs_out":
				return absf(fm * log(x - fh) / log(fa) + fk) if x - fh > 0.0 else NAN
			"log_abs_both":
				return absf(fm * log(absf(x - fh)) / log(fa) + fk) if absf(x - fh) > 0.0 else NAN
			"abs_in":
				return fm * pow(fa, absf(x - fh)) + fk
			"abs_out":
				return absf(fm * pow(fa, x - fh) + fk)
			"abs_y":
				var v := fm * pow(fa, x - fh) + fk
				return v if b == 0 else -v
		return fm * pow(fa, x - fh) + fk

	static func is_log(f_form: String) -> bool:
		return f_form.begins_with("log")

	## 反函數（對 y = x 的鏡像）：a^{x − h} + k ↔ log_{a}(x − k) + h
	static func inverse_of(f_form: String) -> String:
		return {"exp": "log", "log": "exp"}.get(f_form, "")

	## 一邊的函數值：陣列 [p, q, r] 表 px² + qx + r；字典 {form, a, h, k, m} 表一條指數／對數曲線
	static func side_val(side, x: float) -> float:
		if side is Array:
			return side[0] * x * x + side[1] * x + side[2]
		return fval(side.form, side.a, side.get("h", 0.0), side.get("k", 0.0), side.get("m", 1.0), x, 0)

	## 曲線通過哪些象限（座標軸上的點不算）
	static func quadrants_of(f_form: String, fa: float, fh: float, fk: float, fm: float) -> Array:
		var lit := {}
		for i in range(-4000, 4001):
			var x := i / 100.0
			if is_zero_approx(x):
				continue
			for b in (2 if f_form == "abs_y" else 1):
				var y := fval(f_form, fa, fh, fk, fm, x, b)
				if is_nan(y) or absf(y) < 1e-9 or absf(y) > 1e12:
					continue
				var q := (1 if y > 0 else 4) if x > 0 else (2 if y > 0 else 3)
				lit[q] = true
		var out := lit.keys()
		out.sort()
		return out

	func branch_count() -> int:
		return 2 if form == "abs_y" else 1

	func fb(x: float, b: int) -> float:
		return fval(form, a, h, k, m, x, b)

	func tol() -> float:
		return 0.015 * (y_range.y - y_range.x)

	func passes(p: Vector2) -> bool:
		for b in branch_count():
			if absf(fb(p.x, b) - p.y) < tol():
				return true
		return false

	## 交點獵人畫圖時，評分要看的是「正在畫的那一條」
	func _cross_side():
		return cross_exp if cross_sketch == 1 else cross_quad

	func _cur_form() -> String:
		if cross_sketch == 0:
			return form
		var sd = _cross_side()
		return sd.form if sd is Dictionary else "poly"

	func _tf(x: float) -> float:
		return fb(x, 0) if cross_sketch == 0 else side_val(_cross_side(), x)

	func asymptote_x() -> float:
		if cross_sketch > 0:
			var sd = _cross_side()
			return float(sd.get("h", 0.0)) if sd is Dictionary and is_log(sd.form) else NAN
		return h if is_log(form) else NAN

	func asymptote_y() -> float:
		if is_log(form):
			return NAN
		match form:
			"abs_in":
				return k if a < 1.0 else NAN
			"abs_out":
				return absf(k)
		return k

	## 方程式 f(x) = c 的所有實根（x 每 0.01 取樣，正好落在格點的根也算）
	var _roots_key := ""
	var _roots_val := []

	func roots_of(c: float) -> Array:
		# 每一幀都會問：曲線和水平線沒變就沿用上次的結果（掃 3000 點在手機上很花時間）
		var key := "%s|%s|%s|%s|%s|%s" % [c, form, fb(0.37, 0), fb(-1.93, 0), fb(2.71, 0), fb(-6.1, 0)]
		if key == _roots_key:
			return _roots_val
		_roots_val = _roots_scan(c)
		_roots_key = key
		return _roots_val

	func _roots_scan(c: float) -> Array:
		var out := []
		var prev_g := NAN
		var after_zero := false
		for i in range(-1500, 1501):
			var x := i / 100.0
			var g := fb(x, 0) - c
			if absf(g) < 1e-9:
				if not after_zero:
					out.append(x)
				after_zero = true
				continue
			if not after_zero and not is_nan(prev_g) and prev_g * g < 0.0:
				var x0 := x - 0.01
				out.append(x0 + 0.01 * prev_g / (prev_g - g))
			after_zero = false
			prev_g = g
		return out

	func f_exp(x: float) -> float:
		return side_val(cross_exp, x)

	func f_quad(x: float) -> float:
		return side_val(cross_quad, x)

	## 指數函數與二次函數在 CROSS_DOMAIN 內的所有交點
	static func cross_roots_of(rd: Dictionary) -> Array:
		var e = rd.exp
		var q = rd.quad
		var dom: Vector2 = rd.get("domain", CROSS_DOMAIN)
		var out := []
		var prev_g := NAN
		var after_zero := false
		for i in range(int(dom.x * 100), int(dom.y * 100) + 1):
			var x := i / 100.0
			var g: float = side_val(e, x) - side_val(q, x)
			if absf(g) < 1e-9:
				if not after_zero:
					out.append(x)
				after_zero = true
				continue
			if not after_zero and not is_nan(prev_g) and prev_g * g < 0.0:
				out.append(x - 0.01 + 0.01 * prev_g / (prev_g - g))
			after_zero = false
			prev_g = g
		return out

	## 移動掃描線：掃過的範圍會留下顏色，碰到交點就標記；鏡頭跟著掃描線走
	func set_scan(x: float) -> void:
		scan_x = x
		swept = Vector2(minf(swept.x, x), maxf(swept.y, x))
		for i in cross_roots.size():
			var rx: float = cross_roots[i]
			if not cross_found[i] and rx >= swept.x - 1e-6 and rx <= swept.y + 1e-6:
				cross_found[i] = true
				_burst(to_screen(Vector2(rx, f_exp(rx))), Color.WHITE, 22)
				root_found.emit(i, rx)
		var margin := CROSS_HW - 1.0
		if x > cam_target + margin:
			cam_target = x - margin
		elif x < cam_target - margin:
			cam_target = x + margin
		cam_target = clampf(cam_target, cross_dom.x + CROSS_HW, cross_dom.y - CROSS_HW)

	func show_table_point(i: int) -> void:
		table_shown[i] = true
		_burst(to_screen(Vector2(table_xs[i], table_e[i])), CURVE_COL, 8)
		_burst(to_screen(Vector2(table_xs[i], table_q[i])), UITheme.ORANGE, 8)

	## 曲線從左畫到右（約 1.6 秒）
	func reveal_curves() -> void:
		reveal_t = 0.0
		for rx in cross_roots:
			get_tree().create_timer(1.6 * (rx - x_range.x) / (x_range.y - x_range.x)).timeout.connect(
				func(): _burst(to_screen(Vector2(rx, f_exp(rx))), GOLD, 22))

	func _band_at(px: float) -> int:
		for i in table_xs.size() - 1:
			var a := to_screen(Vector2(table_xs[i], 0)).x
			var b := to_screen(Vector2(table_xs[i + 1], 0)).x
			if px > a + 6.0 and px < b - 6.0:
				return i
		return -1

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if demo_t >= 0.0:
				# 播放中點一下：還沒播完就跳到最後一張，已經在最後一張就關掉
				var total := demo_steps.size() * DEMO_STEP
				demo_t = total + DEMO_END if demo_t >= total else total
				accept_event()
				return
			if demo_btn and demo_btn_rect.has_point(e.position):
				play_abs_demo(demo)
				accept_event()
				return
		if demo_t >= 0.0:
			return
		if mark_on:
			_mark_input(e)
			return
		if type == "draw" or (type == "cross" and cross_sketch > 0):
			_draw_input(e)
			return
		if type == "chord":
			_chord_input(e)
			return
		if type != "table" or not bands_on:
			return
		if e is InputEventMouseMotion:
			band_hover = _band_at(e.position.x)
		elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var i := _band_at(e.position.x)
			if i >= 0:
				band_sel[i] = not band_sel[i]
				band_toggled.emit(i)
				accept_event()

	# ---------- 找整數點 ----------

	func to_world(sp: Vector2) -> Vector2:
		return Vector2(x_range.x + sp.x / size.x * (x_range.y - x_range.x),
			y_range.x + (size.y - sp.y) / size.y * (y_range.y - y_range.x))

	## 目前要畫的曲線經過哪些整數點（x、y 都是整數，而且在畫面裡）
	func lattice_targets() -> Array:
		var out := []
		for xi in range(int(ceil(x_range.x)), int(floor(x_range.y)) + 1):
			var ys := []
			if cross_sketch > 0:
				ys.append(_tf(float(xi)))
			else:
				for b in branch_count():
					ys.append(fb(float(xi), b))
			for yv in ys:
				if is_nan(yv) or absf(yv - roundf(yv)) > 1e-6:
					continue
				var p := Vector2(xi, roundf(yv))
				if not markable(p):
					continue
				if not out.has(p):
					out.append(p)
		return out

	## 這個整數點能不能點選：太靠近畫面邊界的不算（答案裡也沒有它，點了會被判錯）
	func markable(p: Vector2) -> bool:
		var sp := to_screen(p)
		return sp.x >= 16.0 and sp.x <= size.x - 16.0 and sp.y >= 16.0 and sp.y <= size.y - 16.0

	## 開始找整數點；整數點太少（不到 2 個）就不做這一步，回傳 false
	func begin_mark() -> bool:
		mark_targets = lattice_targets()
		mark_sel = []
		mark_bad = []
		mark_done = false
		mark_on = mark_targets.size() >= 2
		if mark_on:
			draw_on = false
		queue_redraw()
		return mark_on

	func _mark_input(e: InputEvent) -> void:
		if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
			return
		var wp := to_world(e.position)
		var p := Vector2(roundf(wp.x), roundf(wp.y))
		if to_screen(p).distance_to(e.position) > 20.0 or not markable(p):
			return
		if mark_sel.has(p):
			mark_sel.erase(p)
		else:
			mark_sel.append(p)
		mark_bad.erase(p)
		mark_changed.emit()
		accept_event()
		queue_redraw()

	func _draw_marks(font: Font) -> void:
		if mark_on:
			# 淡淡的格點：可以點的地方
			var ux := size.x / (x_range.y - x_range.x)
			var uy := size.y / (y_range.y - y_range.x)
			if ux >= 9.0 and uy >= 9.0:
				for xi in range(int(ceil(x_range.x)), int(floor(x_range.y)) + 1):
					for yi in range(int(ceil(y_range.x)), int(floor(y_range.y)) + 1):
						if markable(Vector2(xi, yi)):     # 邊界上的點不能選，也不畫格點
							UITheme.dot(self, to_screen(Vector2(xi, yi)), 2.2, Color(1, 1, 1, 0.28))
			for p in mark_bad:
				var c := to_screen(p)
				draw_line(c + Vector2(-7, -7), c + Vector2(7, 7), UITheme.BAD, 3.0, true)
				draw_line(c + Vector2(-7, 7), c + Vector2(7, -7), UITheme.BAD, 3.0, true)
			for p in mark_sel:
				var c2 := to_screen(p)
				UITheme.dot(self, c2, 12.0, Color(1, 0.85, 0.4, 0.18))
				UITheme.dot(self, c2, 6.0, GOLD)
				draw_string(font, c2 + Vector2(-40, -14), "(%d, %d)" % [int(p.x), int(p.y)], HORIZONTAL_ALIGNMENT_CENTER, 80, UITheme.fs(13), Color(1, 0.92, 0.65))
		elif mark_done:
			for p in mark_targets:
				var c3 := to_screen(p)
				draw_arc(c3, 9.0, 0, TAU, 24, Color(1, 0.85, 0.4, 0.8), 2.0, true)
				UITheme.dot(self, c3, 3.5, GOLD)
				draw_string(font, c3 + Vector2(-40, -13), "(%d, %d)" % [int(p.x), int(p.y)], HORIZONTAL_ALIGNMENT_CENTER, 80, UITheme.fs(12), Color(1, 0.9, 0.6, 0.8))

	# ---------- 凹口比大小 ----------

	func chord_pts() -> Array:
		var x1: float = chord.get("x1", 1.0)
		var x2: float = chord.get("x2", 3.0)
		var p := Vector2(x1, fb(x1, 0))
		var q := Vector2(x2, fb(x2, 0))
		var xm := (x1 + x2) / 2.0
		return [p, q, (p + q) / 2.0, Vector2(xm, fb(xm, 0))]

	func _chord_input(e: InputEvent) -> void:
		if not chord_on or not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
			return
		var pts := chord_pts()
		for i in 2:
			if chord_sel.has(i):
				continue
			if to_screen(pts[i]).distance_to(e.position) < 40.0:
				chord_sel.append(i)
				chord_tap.emit(i)
				_burst(to_screen(pts[i]), GOLD, 10)
				if chord_sel.size() == 2:
					chord_on = false
					chord_t = 0.0
				accept_event()
				queue_redraw()
				return

	func _draw_chord(font: Font) -> void:
		var pts := chord_pts()
		var sp: Vector2 = to_screen(pts[0])
		var sq: Vector2 = to_screen(pts[1])
		var names := ["P", "Q"]
		# 弦：從先點的那一點拉到另一點
		if chord_t >= 0.0:
			var a0 := sp if chord_sel.is_empty() or chord_sel[0] == 0 else sq
			var b0 := sq if a0 == sp else sp
			var e0 := a0.lerp(b0, minf(chord_t, 1.0))
			draw_line(a0, e0, Color(GOLD.r, GOLD.g, GOLD.b, 0.18), 10.0, true)
			draw_line(a0, e0, GOLD, 3.0, true)
		# 端點
		for i in 2:
			var c := sp if i == 0 else sq
			var picked := chord_sel.has(i)
			if chord_on and not picked:
				var pr := 16.0 + 6.0 * (0.5 + 0.5 * sin(t * 5.0))
				draw_arc(c, pr, 0, TAU, 32, Color(GOLD.r, GOLD.g, GOLD.b, 0.8), 2.5, true)
			UITheme.dot(self, c, 9.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.25))
			UITheme.dot(self, c, 6.0, GOLD if picked or chord_t >= 0.0 else Color(1, 1, 1, 0.9))
			var lp: Vector2 = pts[i]
			var txt := "%s(%s, %s)" % [names[i], UITheme.num(lp.x, 2), UITheme.num(lp.y, 2)]
			var below := i == 0 and sp.y < sq.y or i == 1 and sq.y < sp.y
			draw_string(font, c + Vector2(-60, 30 if below else -16), txt, HORIZONTAL_ALIGNMENT_CENTER, 120, UITheme.fs(15), Color(1, 0.92, 0.7))
		if chord_t < 1.0:
			return
		# 弦畫好了：M 弦的中點、N 曲線上的點，中間的落差發亮
		var k := clampf((chord_t - 1.0) / 0.6, 0.0, 1.0)
		var m: Vector2 = to_screen(pts[2])
		var n: Vector2 = to_screen(pts[3])
		var x_axis := to_screen(Vector2(pts[2].x, 0)).y
		draw_dashed_line(Vector2(m.x, x_axis), Vector2(m.x, minf(m.y, n.y) - 20.0), Color(1, 1, 1, 0.25 * k), 1.5, 6.0)
		draw_line(m, n, Color(1, 0.85, 0.45, 0.25 * k), 12.0, true)
		draw_line(m, n, Color(1, 0.9, 0.5, 0.9 * k), 3.0, true)
		var mc := Color(1.0, 0.49, 0.71, k)
		var nc := Color(0.35, 0.85, 1.0, k)
		var ms := 9.0
		draw_colored_polygon(PackedVector2Array([m + Vector2(0, -ms), m + Vector2(ms, 0), m + Vector2(0, ms), m + Vector2(-ms, 0)]), mc)
		UITheme.dot(self, n, 8.0, nc)
		UITheme.dot(self, n, 3.5, Color(1, 1, 1, k))
		var m_up := m.y < n.y
		_tag(font, m + Vector2(16, -14 if m_up else 22), "M　弦的中點（函數值的平均）", mc)
		_tag(font, n + Vector2(16, 22 if m_up else -14), "N　中點代入函數", nc)
		var n1 := UITheme.num(pts[0].x, 2).replace("-", "−")
		var n2 := UITheme.num(pts[1].x, 2).replace("-", "−")
		if pts[1].x < 0.0:
			n2 = "(" + n2 + ")"
		var xm_txt := "x = (%s + %s) / 2" % [n1, n2]
		var ly := x_axis + 38.0 if x_axis + 46.0 < size.y else x_axis - 12.0
		draw_string(font, Vector2(m.x - 80, ly), xm_txt, HORIZONTAL_ALIGNMENT_CENTER, 160, UITheme.fs(13), Color(1, 1, 1, 0.6 * k))

	func _tag(font: Font, at: Vector2, text: String, c: Color) -> void:
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15)).x
		var x := clampf(at.x, 6.0, size.x - w - 18.0)
		var box := Rect2(Vector2(x - 6, at.y - 17), Vector2(w + 12, 23))
		draw_style_box(UITheme.boxc(Color(0.05, 0.06, 0.14, 0.85 * c.a), 8, Color(c.r, c.g, c.b, 0.7 * c.a), 1, 0), box)
		draw_string(font, Vector2(x, at.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), c)

	# ---------- 徒手作圖：輸入與評分 ----------

	func _draw_input(e: InputEvent) -> void:
		if not draw_on:
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				if clear_on_next:
					strokes = []
					clear_on_next = false
				drawing = true
				stroke = PackedVector2Array([e.position])
				stroke_bad = []
			elif drawing:
				drawing = false
				var done := stroke
				stroke = PackedVector2Array()
				if done.size() >= 2:
					strokes.append(done)
				stroke_done.emit(done)
			accept_event()
		elif e is InputEventMouseMotion and drawing:
			var p: Vector2 = e.position.clamp(Vector2.ZERO, size)
			if stroke.is_empty() or p.distance_to(stroke[stroke.size() - 1]) >= 3.0:
				stroke.append(p)
			accept_event()

	func has_asymptote() -> bool:
		return not is_nan(asymptote_x()) or not is_nan(_floor_y())

	## 圖形一定在這條水平線的上方（漸近線或最低點）；沒有就回傳 NAN
	func _floor_y() -> float:
		var ff := form
		var fa := a
		var fk := k
		var fm := m
		if cross_sketch > 0:
			var sd = _cross_side()
			if not (sd is Dictionary):
				return NAN
			ff = sd.form
			fa = float(sd.a)
			fk = float(sd.get("k", 0.0))
			fm = float(sd.get("m", 1.0))
		match ff:
			"exp":
				return fk if fm > 0.0 else NAN
			"abs_in":
				return fk if fa < 1.0 else NAN
			"abs_out", "log_abs_out", "log_abs_both":
				return 0.0
		return NAN

	## 畫到不可能的地方：越過鉛直漸近線、跑到水平漸近線（或 x 軸）的另一側
	func _forbidden(p: Vector2, margin: float) -> bool:
		var ax := asymptote_x()
		var ff := _cur_form()
		if ff == "log" or ff == "log_abs_out":
			if not is_nan(ax) and p.x < to_screen(Vector2(ax, 0)).x - margin:
				return true
		var fy := _floor_y()
		if not is_nan(fy) and p.y > to_screen(Vector2(0, fy)).y + margin:
			return true
		return false

	static func _resample(poly: PackedVector2Array, step: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		if poly.is_empty():
			return out
		out.append(poly[0])
		var carry := 0.0
		for i in range(1, poly.size()):
			var a0 := poly[i - 1]
			var b0 := poly[i]
			var seg := a0.distance_to(b0)
			var d := step - carry
			while d <= seg:
				out.append(a0.lerp(b0, d / seg))
				d += step
			carry = seg - (d - step)
		return out

	static func _nearest(p: Vector2, pts: PackedVector2Array) -> float:
		var best := INF
		for q in pts:
			best = minf(best, p.distance_squared_to(q))
		return sqrt(best)

	## 嚴格評分（單位：舞台像素）。回傳 {ok, score, reason, bad}
	func judge_stroke(raw: PackedVector2Array) -> Dictionary:
		return judge_strokes([raw])

	## 好幾筆一起評分（例如有兩支的圖形分兩筆畫）
	func judge_strokes(list: Array) -> Dictionary:
		var res := {"ok": false, "score": 0, "reason": "", "bad": []}
		var st := PackedVector2Array()
		var parts := []
		for one in list:
			var rs := _resample(one, 5.0)
			if rs.size() >= 2:
				parts.append(rs)
				st.append_array(rs)
		# 正確圖形在畫面內的部分（依弧長取樣）
		var tgt := PackedVector2Array()
		var rect := Rect2(Vector2(3, 3), size - Vector2(6, 6))
		var tsegs := _segments(func(x): return _tf(x))
		for si in tsegs.size():
			if seg_target >= 0 and si != seg_target:
				continue
			for p in _resample(tsegs[si], 5.0):
				if rect.has_point(p):
					tgt.append(p)
		var length := 0.0
		for one in list:
			for i in range(1, one.size()):
				length += one[i - 1].distance_to(one[i])
		if length < 80.0 or st.size() < 8:
			res.reason = "畫得太短了。按住拖曳，把整個圖形畫出來。"
			return res
		# 每點離正確圖形多遠
		var dist := []
		for p in st:
			dist.append(_nearest(p, tgt))
		var sorted_d := dist.duplicate()
		sorted_d.sort()
		var mean := 0.0
		for d in dist:
			mean += d
		mean /= dist.size()
		var p90: float = sorted_d[int(0.9 * (sorted_d.size() - 1))]
		var bad := []
		for i in st.size():
			if dist[i] > 26.0:
				bad.append(st[i])
		# 整體形狀不夠準、但沒有哪一點偏超過 26：改標「偏最多的那一成」，紅色提示才看得到
		if bad.is_empty() and (mean > 12.0 or p90 > 24.0):
			var cut := maxf(10.0, float(sorted_d[int(0.88 * (sorted_d.size() - 1))]))
			for i in st.size():
				if dist[i] >= cut:
					bad.append(st[i])
		res.bad = bad
		# 正確圖形有多少被畫到
		var covered := 0
		for q in tgt:
			if _nearest(q, st) <= 24.0:
				covered += 1
		var coverage := float(covered) / maxf(1.0, tgt.size())
		res.score = int(round(100.0 * clampf(1.0 - mean / 40.0, 0.0, 1.0) * clampf(coverage, 0.0, 1.0)))
		# 1. 函數：一個 x 只能對到一個 y（不能往回畫）
		# 往回退了多少：目前走到最遠的位置，減掉現在的位置（手抖的小幅度來回不算）
		var back := 0.0
		for one in parts:
			var dir := 1.0 if one[one.size() - 1].x >= one[0].x else -1.0
			var far: float = one[0].x * dir
			for p in one:
				far = maxf(far, p.x * dir)
				back = maxf(back, far - p.x * dir)
		if back > 18.0:
			res.reason = "函數圖形不能往回畫：每個 x 只能對到一個 y。"
			return res
		# 2. 越過漸近線
		var forb := 0
		for p in st:
			if _forbidden(p, 10.0):
				forb += 1
		if forb > 2:
			var ax := asymptote_x()
			var ff := _cur_form()
			if not is_nan(ax) and (ff == "log" or ff == "log_abs_out"):
				res.reason = "越過了鉛直漸近線 x = %s：真數必須大於 0，左邊沒有圖形。" % UITheme.num(ax, 2)
			elif ff.contains("abs_out") or ff == "log_abs_both":
				res.reason = "加了絕對值，y 不可能是負的，圖形不會跑到 x 軸下方。"
			else:
				res.reason = "跑到漸近線 y = %s 的下方了：曲線只會貼近它，不會穿過去。" % UITheme.num(_floor_y(), 2)
			return res
		# 3. 必經點
		for kp in draw_keys:
			var kpx := to_screen(kp)
			if seg_target >= 0 and _nearest(kpx, tgt) > 20.0:
				continue      # 這個必經點在另一支上
			if rect.has_point(kpx) and _nearest(kpx, st) > 16.0:
				res.reason = "沒有經過 (%s, %s)。" % [UITheme.num(kp.x, 2), UITheme.num(kp.y, 2)]
				return res
		# 4. 有沒有畫滿
		if coverage < 0.85:
			res.reason = "還有一段沒畫到：要畫滿整個畫面。"
			return res
		# 5. 形狀
		if mean > 12.0 or p90 > 24.0:
			res.reason = "紅色部分偏差最大。每往右一格，y 怎麼變？"
			return res
		res.ok = true
		return res

	## 交點獵人：開始畫第 side 條
	func begin_cross_sketch(side: int) -> void:
		cross_sketch = side
		seg_target = -1
		segs_done = []
		draw_on = true
		drawing = false
		stroke = PackedVector2Array()
		strokes = []
		clear_on_next = false
		stroke_bad = []
		draw_show_keys = false
		draw_show_asym = false
		hint_keys = []
		draw_keys = side_keys(side)
		queue_redraw()

	## 誤觸判斷：太短、或左右幅度太小的一筆。回傳理由；正常的一筆回傳 ""
	func accidental_reason(raw: PackedVector2Array) -> String:
		var length := 0.0
		var lo := INF
		var hi := -INF
		for i in raw.size():
			lo = minf(lo, raw[i].x)
			hi = maxf(hi, raw[i].x)
			if i > 0:
				length += raw[i - 1].distance_to(raw[i])
		if raw.size() < 5 or length < 30.0:
			return "只是輕輕點到了畫面？要按住不放，拖曳著畫過去。"
		return ""

	## 畫錯後的提示點：必經點，再補上曲線上座標漂亮（整數或 .5）的點，盡量分散在整個畫面（最多 7 個）
	func keys_for_hint() -> Array:
		var cands := []
		var xs := []
		for i in range(int(ceil(x_range.x * 2.0)), int(floor(x_range.y * 2.0)) + 1):
			xs.append(i / 2.0)
		for xv in [0.25, 0.125, -0.25, -0.125]:
			xs.append(xv)
		var inner := Rect2(Vector2(26, 26), size - Vector2(52, 52))
		for xv in xs:
			var yv := _tf(xv)
			if is_nan(yv) or absf(yv * 2.0 - roundf(yv * 2.0)) > 1e-6:
				continue
			var p := Vector2(xv, roundf(yv * 2.0) / 2.0)
			if inner.has_point(to_screen(p)):
				cands.append(p)
		var out: Array = []
		for kp in draw_keys:
			if inner.has_point(to_screen(kp)):
				out.append(kp)
		# 最遠點取樣：每次挑離已選的點最遠的那一個，讓提示點散開
		while out.size() < 7 and not cands.is_empty():
			var best_i := -1
			var best_d := -1.0
			for i in cands.size():
				var d := INF
				for q in out:
					d = minf(d, to_screen(cands[i]).distance_to(to_screen(q)))
				if out.is_empty():
					d = -absf(cands[i].x - (x_range.x + x_range.y) / 2.0)
				if d > best_d:
					best_d = d
					best_i = i
			if best_i < 0 or (not out.is_empty() and best_d < 60.0):
				break
			out.append(cands[best_i])
			cands.remove_at(best_i)
		return out

	## 正在畫的這一條在畫面裡分成幾支
	func cross_seg_count() -> int:
		return _segments(func(x): return _tf(x)).size()

	## 這一筆最接近哪一支
	func best_seg(raw: PackedVector2Array) -> int:
		var st := _resample(raw, 8.0)
		var segs := _segments(func(x): return _tf(x))
		var best := 0
		var best_d := INF
		for i in segs.size():
			var pts := _resample(segs[i], 6.0)
			var d := 0.0
			for p in st:
				d += _nearest(p, pts)
			if d < best_d:
				best_d = d
				best = i
		return best

	## 這一條畫對了：把正確的圖形亮出來
	func finish_cross_side(side: int) -> void:
		guide_pts = []
		cross_drawn[side - 1] = true
		var f: Callable = f_exp if side == 1 else f_quad
		for seg in _segments(f):
			for i in range(0, seg.size(), 12):
				_burst(seg[i], CURVE_COL if side == 1 else UITheme.ORANGE, 3)
		cross_sketch = 0
		draw_on = false
		stroke = PackedVector2Array()
		strokes = []
		clear_on_next = false
		stroke_bad = []
		draw_show_keys = false
		draw_show_asym = false
		draw_keys = []

	## 畫錯時給的提示點：畫面裡座標漂亮（整數或 .5）的點，挑靠中間的 3 個
	func side_keys(side: int) -> Array:
		var sd = cross_exp if side == 1 else cross_quad
		var cands := []
		var xs := []
		for i in range(int(ceil(x_range.x * 2.0)), int(floor(x_range.y * 2.0)) + 1):
			xs.append(i / 2.0)
		for xv in [0.25, 0.125]:
			xs.append(xv)
		for xv in xs:
			var yv := side_val(sd, xv)
			if is_nan(yv) or yv < y_range.x + 0.3 or yv > y_range.y - 0.3:
				continue
			if absf(yv * 2.0 - roundf(yv * 2.0)) > 1e-6:
				continue
			cands.append(Vector2(xv, roundf(yv * 2.0) / 2.0))
		var cx := (x_range.x + x_range.y) / 2.0
		cands.sort_custom(func(p, q): return absf(p.x - cx) < absf(q.x - cx))
		var out := []
		for p in cands:
			var ok := true
			for q in out:
				if absf(p.x - q.x) < 0.9:
					ok = false
			if ok:
				out.append(p)
			if out.size() >= 3:
				break
		return out

	## 數完交點：一個一個亮起來
	func reveal_roots() -> void:
		for i in cross_found.size():
			cross_found[i] = true
		for rx in cross_roots:
			_burst(to_screen(Vector2(rx, f_exp(rx))), GOLD, 22)

	func to_screen(p: Vector2) -> Vector2:
		return Vector2((p.x - x_range.x) / (x_range.y - x_range.x) * size.x,
			size.y - (p.y - y_range.x) / (y_range.y - y_range.x) * size.y)

	# ---------- 絕對值圖形的由來（分步動畫） ----------

	static func _dn(v: float) -> String:
		return UITheme.num(v, 2)

	## 不含絕對值的原本式子（例如 2^{x − 1} + 1、log_{2}(x − 1)）
	static func demo_base_expr(p: Dictionary) -> String:
		var f: String = p.form
		var hv := float(p.get("h", 0.0))
		var kv := float(p.get("k", 0.0))
		var mv := float(p.get("m", 1.0))
		var inner := "x"
		if not is_zero_approx(hv):
			inner = ("x − %s" if hv > 0.0 else "x + %s") % _dn(absf(hv))
		var core: String
		if is_log(f):
			core = "log_{%s} x" % UITheme.nice_text(p.a) if inner == "x" else "log_{%s}(%s)" % [UITheme.nice_text(p.a), inner]
		else:
			var base := UITheme.nice_text(p.a)
			if base.contains("/"):
				base = "(%s)" % base
			core = "%s^{%s}" % [base, inner]
		if is_equal_approx(mv, -1.0):
			core = "−" + core
		elif not is_equal_approx(mv, 1.0):
			core = _dn(mv) + "·" + core
		if not is_zero_approx(kv):
			core += (" + %s" if kv > 0.0 else " − %s") % _dn(absf(kv))
		return core

	## 有絕對值的完整式子
	static func demo_full_expr(p: Dictionary) -> String:
		var f: String = p.form
		var hv := float(p.get("h", 0.0))
		var inner := "x" if is_zero_approx(hv) else (("x − %s" if hv > 0.0 else "x + %s") % _dn(absf(hv)))
		var q := p.duplicate()
		match f:
			"abs_in", "log_abs_in", "log_abs_both":
				q.h = 0.0
				var s := demo_base_expr(q)
				s = s.replace("^{x}", "^{|%s|}" % inner).replace("log_{%s} x" % UITheme.nice_text(p.a), "log_{%s}|%s|" % [UITheme.nice_text(p.a), inner])
				return "y = |%s|" % s if f == "log_abs_both" else "y = " + s
			"abs_out", "log_abs_out":
				return "y = |%s|" % demo_base_expr(p)
			"abs_y":
				return "|y| = " + demo_base_expr(p)
		return "y = " + demo_base_expr(p)

	static func is_abs_form(f: String) -> bool:
		return f in ABS_FORMS

	## 播放：p = {form, a, h, k, m}；不是絕對值圖形就不播
	func play_abs_demo(p: Dictionary) -> bool:
		if p.is_empty() or not is_abs_form(String(p.get("form", ""))):
			return false
		demo = p.duplicate()
		var f: String = p.form
		var hv := float(p.get("h", 0.0))
		var hs := _dn(hv)
		var base := "y = " + demo_base_expr(p)
		var B := "[color=#5ad8ff]%s[/color]" % base
		var inner := "x" if is_zero_approx(hv) else (("x − %s" if hv > 0.0 else "x + %s") % _dn(absf(hv)))
		match f:
			"abs_in":
				demo_steps = [
					{"op": "draw", "cap": "① 先畫原本的 " + B},
					{"op": "keep_right", "c": hv, "cap": "② x ≥ %s 時 |%s| = %s，和原本一樣：留下右半邊" % [hs, inner, inner]},
					{"op": "mirror_x", "c": hv, "cap": "③ 左邊和右邊對稱：把右半邊對 [color=#ffcf5a]x = %s[/color] 翻到左邊" % hs}]
			"log_abs_in":
				demo_steps = [
					{"op": "draw", "cap": "① 先畫原本的 " + B + "（只有 x > %s）" % hs},
					{"op": "mirror_x", "c": hv, "cap": "② |%s| 讓左右對稱：把它對 [color=#ffcf5a]x = %s[/color] 翻到左邊" % [inner, hs]}]
			"abs_out", "log_abs_out":
				demo_steps = [
					{"op": "draw", "cap": "① 先畫原本的 " + B},
					{"op": "mark_below", "cap": "② x 軸上方（正的）不動；[color=#ff6b7a]x 軸下方是負的[/color]"},
					{"op": "fold_up", "cap": "③ |負數| 變成正數：把下方那段[color=#ffcf5a]沿 x 軸往上翻[/color]"}]
			"abs_y":
				demo_steps = [
					{"op": "draw", "cap": "① 先畫 " + B},
					{"op": "keep_above", "cap": "② |y| 不能是負的：[color=#ff6b7a]x 軸下方那段不要[/color]"},
					{"op": "mirror_down", "cap": "③ y 可正可負：把上方那段[color=#ffcf5a]對 x 軸翻下去[/color]"}]
			"log_abs_both":
				demo_steps = [
					{"op": "draw", "cap": "① 先畫原本的 " + B},
					{"op": "mirror_x", "c": hv, "cap": "② 裡面的 |%s|：對 [color=#ffcf5a]x = %s[/color] 翻到左邊" % [inner, hs]},
					{"op": "mark_below", "cap": "③ 外面的 | |：[color=#ff6b7a]x 軸下方是負的[/color]"},
					{"op": "fold_up", "cap": "④ 把下方那段[color=#ffcf5a]沿 x 軸往上翻[/color]"}]
		# 原本的圖形整條都在 x 軸上方：第二步改說「整條都留著」
		if f in ["abs_out", "abs_y"]:
			var neg := false
			for pl in _demo_base():
				for q in pl:
					if q.y < -1e-6 and q.x >= x_range.x and q.x <= x_range.y:
						neg = true
			if not neg:
				var pos := "%s 永遠是正的" % demo_base_expr(p)
				demo_steps[1].cap = ("② %s：沒有負的部分，整條都留著" % pos) if f == "abs_y" else ("② %s：|正數| = 正數，圖形不變" % pos)
		demo_final = demo_full_expr(p)
		demo_t = 0.0
		return true

	## 原本（不含絕對值）的圖形，世界座標
	func _demo_base() -> Array:
		var p := demo
		var span := y_range.y - y_range.x
		var lo := y_range.x - 1.5 * span
		var hi := y_range.y + 1.5 * span
		var f: String = p.form
		var lg := is_log(f)
		var hv := float(p.get("h", 0.0))
		var out := []
		var cur := PackedVector2Array()
		var n := 900
		var xs := []
		var xw := x_range.y - x_range.x
		for i in n + 1:
			xs.append(lerpf(x_range.x - xw, x_range.y + xw, float(i) / n))   # 畫面外也取：鏡射過來才不會斷掉
		if lg:
			for e in [0.002, 0.005, 0.01, 0.02, 0.04]:
				xs.append(hv + e)
			xs.sort()
		for x in xs:
			var y: float
			if lg:
				y = fval("log", p.a, hv, p.get("k", 0.0), p.get("m", 1.0), x, 0)
			else:
				y = fval("exp", p.a, hv, p.get("k", 0.0), p.get("m", 1.0), x, 0)
			if is_nan(y):
				if cur.size() >= 2:
					out.append(cur)
				cur = PackedVector2Array()
				continue
			cur.append(Vector2(x, clampf(y, lo, hi)))
		if cur.size() >= 2:
			out.append(cur)
		return out

	## 依 g(p) 的正負把折線切開（在邊界上補一個內插點）
	static func _split(pts: PackedVector2Array, g: Callable) -> Array:
		var pos := []
		var neg := []
		var cur := PackedVector2Array()
		var side := 0
		for i in pts.size():
			var v: float = g.call(pts[i])
			var s := 1 if v >= 0.0 else -1
			if i > 0 and s != side:
				var v0: float = g.call(pts[i - 1])
				var q := pts[i - 1].lerp(pts[i], v0 / (v0 - v)) if not is_equal_approx(v0, v) else pts[i]
				cur.append(q)
				if cur.size() >= 2:
					(pos if side > 0 else neg).append(cur)
				cur = PackedVector2Array([q])
			side = s
			cur.append(pts[i])
		if cur.size() >= 2:
			(pos if side > 0 else neg).append(cur)
		return [pos, neg]

	static func _map(pts: PackedVector2Array, f: Callable) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in pts:
			out.append(f.call(p))
		return out

	## 第 si 步、進度 u 的畫面：[{p: 折線, s: main／gone／hot／copy}]
	func _demo_pieces(si: int, u: float) -> Array:
		var pieces := []
		for pl in _demo_base():
			pieces.append({"p": pl, "s": "main"})
		for j in si + 1:
			var st: Dictionary = demo_steps[j]
			var uj := 1.0 if j < si else u
			var e := uj * uj * (3.0 - 2.0 * uj)
			var nxt := []
			match st.op:
				"draw":
					var cut := lerpf(x_range.x, x_range.y, e) if e < 1.0 else INF
					for pc in pieces:
						for part in _split(pc.p, func(q): return cut - q.x)[0]:
							nxt.append({"p": part, "s": pc.s})
				"keep_right", "keep_above":
					var gfn := (func(q): return q.x - float(st.c)) if st.op == "keep_right" else (func(q): return q.y)
					for pc in pieces:
						if pc.s != "main":
							nxt.append(pc)
							continue
						var sp := _split(pc.p, gfn)
						for part in sp[0]:
							nxt.append({"p": part, "s": "main"})
						for part in sp[1]:
							nxt.append({"p": part, "s": "gone", "f": e})
				"mirror_x", "mirror_down":
					var c := float(st.get("c", 0.0))
					var cs := cos(PI * e)
					for pc in pieces:
						nxt.append(pc)
						if pc.s == "main":
							var mf := (func(q): return Vector2(c + (q.x - c) * cs, q.y)) if st.op == "mirror_x" \
								else (func(q): return Vector2(q.x, q.y * cs))
							nxt.append({"p": _map(pc.p, mf), "s": "copy" if j == si else "main"})
				"mark_below":
					for pc in pieces:
						if pc.s != "main":
							nxt.append(pc)
							continue
						var sp := _split(pc.p, func(q): return q.y)
						for part in sp[0]:
							nxt.append({"p": part, "s": "main"})
						for part in sp[1]:
							nxt.append({"p": part, "s": "hot", "f": e})
				"fold_up":
					var cs := cos(PI * e)
					for pc in pieces:
						if pc.s == "hot":
							nxt.append({"p": pc.p, "s": "gone", "f": 1.0})
							nxt.append({"p": _map(pc.p, func(q): return Vector2(q.x, q.y * cs)), "s": "copy" if j == si else "main"})
						else:
							nxt.append(pc)
			pieces = nxt
		return pieces

	func _draw_demo(font: Font) -> void:
		var n := demo_steps.size()
		var total := n * DEMO_STEP
		var fade := clampf((total + DEMO_END + 0.5 - demo_t) / 0.5, 0.0, 1.0) * clampf(demo_t / 0.3, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.09, 0.88 * fade))
		var ws := func(p: Vector2) -> Vector2: return to_screen(p)
		# 座標軸
		var o := to_screen(Vector2(0, 0))
		var axc := Color(1, 1, 1, 0.45 * fade)
		if o.y > 0 and o.y < size.y:
			draw_line(Vector2(0, o.y), Vector2(size.x, o.y), axc, 2.0)
		if o.x > 0 and o.x < size.x:
			draw_line(Vector2(o.x, 0), Vector2(o.x, size.y), axc, 2.0)
		var si := mini(int(demo_t / DEMO_STEP), n - 1)
		var u := clampf((demo_t - si * DEMO_STEP) / DEMO_ANIM, 0.0, 1.0)
		var ending := demo_t >= total
		# 對稱軸／x 軸的高亮
		var op: String = demo_steps[si].op
		if op in ["keep_right", "mirror_x"]:
			var cx := to_screen(Vector2(float(demo_steps[si].c), 0)).x
			draw_line(Vector2(cx, 0), Vector2(cx, size.y), Color(1, 0.81, 0.35, 0.12 * fade), 12.0)
			draw_dashed_line(Vector2(cx, 0), Vector2(cx, size.y), Color(1, 0.81, 0.35, 0.9 * fade), 2.0, 10.0)
		elif op in ["mark_below", "fold_up", "keep_above", "mirror_down"] and o.y > 0 and o.y < size.y:
			draw_line(Vector2(0, o.y), Vector2(size.x, o.y), Color(1, 0.81, 0.35, 0.14 * fade), 12.0)
			draw_line(Vector2(0, o.y), Vector2(size.x, o.y), Color(1, 0.81, 0.35, 0.8 * fade), 2.0)
		for pc in _demo_pieces(si, u):
			var sp: PackedVector2Array = _map(pc.p, ws)
			var kind: String = "main" if ending and pc.s == "copy" else pc.s
			match kind:
				"main":
					var col := CURVE_COL.lerp(GOLD, clampf((demo_t - total) / 0.6, 0.0, 1.0)) if ending else CURVE_COL
					col.a = fade
					_glow_line(sp, col)
				"copy":
					var cc := MIRROR_COL
					cc.a = fade
					_glow_line(sp, cc)
				"hot":
					var hc := CURVE_COL.lerp(UITheme.BAD, float(pc.f))
					hc.a = fade * (0.75 + 0.25 * sin(t * 8.0))
					_glow_line(sp, hc)
				"gone":
					var a0 := lerpf(0.9, 0.25, float(pc.f)) * fade
					var acc := 0.0
					for i in sp.size() - 1:
						var d := sp[i].distance_to(sp[i + 1])
						if fmod(acc, 14.0) < 8.0 and d < 200.0:
							draw_line(sp[i], sp[i + 1], Color(0.75, 0.85, 1.0, a0), 2.0, true)
						acc += d
		# 說明文字
		var cap: String = ("[color=#ffcf5a]%s[/color]" % demo_final) if ending else demo_steps[si].cap
		var fs := UITheme.fs(17)
		var tw := MathLabel.text_width(font, cap, fs)
		var bw := minf(size.x - 24.0, tw + 40.0)
		var fs2 := fs if tw + 40.0 <= size.x - 24.0 else maxi(UITheme.fs(12), int(fs * (size.x - 64.0) / tw))
		var box := Rect2((size.x - bw) / 2.0, 14, bw, 46)
		draw_style_box(UITheme.boxc(Color(0.06, 0.07, 0.16, 0.92 * fade), 14, Color(1, 0.81, 0.35, 0.5 * fade), 1, 0), box)
		var tin := demo_t - (total if ending else si * DEMO_STEP)
		var ccol := Color(0.93, 0.95, 1.0, fade)
		MathLabel.draw_on(self, font, size.x / 2.0, box.position.y + 30, cap, fs2, ccol, tin * 40.0)
		# 步驟點＋跳過提示
		for i in n + 1:
			var on := i <= si or ending
			var dc := Color(1, 0.81, 0.35, (0.95 if on else 0.3) * fade)
			UITheme.dot(self, Vector2(size.x / 2.0 - n * 9.0 + i * 18.0, box.end.y + 12), 4.0 if on else 3.0, dc)
		draw_string(font, Vector2(size.x - 272, size.y - 14), "點一下畫面：" + ("關閉" if ending else "跳到最後"),
			HORIZONTAL_ALIGNMENT_RIGHT, 260, UITheme.fs(13), Color(1, 1, 1, 0.5 * fade))

	# ---------- 光靈 ----------

	func start_run() -> void:
		gem_state.fill(0)
		last_step = -1
		gems_got = 0
		running = true
		falling = false
		show_spirit = true
		spirits.clear()
		trails.clear()
		var x0 := run_start_x()
		for b in branch_count():
			spirits.append(Vector2(x0, fb(x0, b)))
			trails.append([])

	## 光靈的起點：畫面左緣；對數曲線則從曲線進入畫面的地方出發
	func run_start_x() -> float:
		var pad := 0.04 * (y_range.y - y_range.x)
		for i in 2001:
			var x := lerpf(x_range.x, x_range.y, i / 2000.0)
			var y := fb(x, 0)
			if not is_nan(y) and y > y_range.x - pad and y < y_range.y + pad:
				return x
		return x_range.x

	func celebrate() -> void:
		var pts := []
		for g in gems:
			pts.append(to_screen(g))
		if pts.is_empty():
			pts = [size / 2.0]
		for p in pts:
			_burst(p, GOLD, 26)
		var tw := create_tween()
		tw.tween_property(self, "curve_gold", 1.0, 0.6)

	func _start_fall(reason: String) -> void:
		falling = true
		fail_reason = reason
		fell.emit(reason)
		for b in spirits.size():
			spirits[b].y = clampf(spirits[b].y, y_range.x, y_range.y + 0.05 * (y_range.y - y_range.x))
		spirit_vel = Vector2(0.1, 0.25) * (y_range.y - y_range.x)

	func _process(delta: float) -> void:
		t += delta
		if demo_t >= 0.0:
			demo_t += delta
			if demo_t > demo_steps.size() * DEMO_STEP + DEMO_END + 0.5:
				demo_t = -1.0
		if reveal_t >= 0.0 and reveal_t < 1.0:
			reveal_t = minf(1.0, reveal_t + delta / 1.6)
		if chord_t >= 0.0 and chord_t < 1.6:
			chord_t = minf(1.6, chord_t + delta / 0.7)
			if chord_t >= 1.6 and not _chord_emitted:
				_chord_emitted = true
				chord_drawn.emit()
		if running and not falling:
			var px: float = spirits[0].x
			var nx := px + RUN_SPEED * (x_range.y - x_range.x) * delta
			for i in gems.size():
				var gx: float = gems[i].x
				if gem_state[i] == 0 and px < gx and nx >= gx:
					if passes(gems[i]):
						gem_state[i] = 1
						_burst(to_screen(gems[i]), GOLD, 16)
						gem_hit.emit(gems_got)
						gems_got += 1
					else:
						gem_state[i] = 2
						_burst(to_screen(gems[i]), UITheme.BAD, 10)
						for b in spirits.size():
							spirits[b] = Vector2(gx, fb(gx, b))
						_start_fall("miss")
						break
			if not falling:
				# 每走 1/20 個畫面寬就發一個音，音高對應光靈的高度
				var stp := int(floor((nx - x_range.x) / (x_range.y - x_range.x) * 20.0))
				if stp != last_step:
					last_step = stp
					for b in spirits.size():
						var y := fb(nx, b)
						if not is_nan(y):
							step_note.emit(clampf((y - y_range.x) / (y_range.y - y_range.x), 0.0, 1.0))
				for b in spirits.size():
					var ny := fb(nx, b)
					if is_nan(ny):
						ny = y_range.x - (y_range.y - y_range.x)   # 漸近線上：先潛到畫面下方
					spirits[b] = Vector2(nx, clampf(ny, y_range.x - 2.0 * (y_range.y - y_range.x), y_range.y + 2.0 * (y_range.y - y_range.x)))
					var sp := to_screen(spirits[b])
					for ho in holes:
						if sp.distance_to(to_screen(ho)) < HOLE_PX:
							_start_fall("hole")
							break
					if falling:
						break
			if not falling and nx >= x_range.y:
				running = false
				run_finished.emit(true, "")
		elif falling:
			spirit_vel.y -= 2.0 * (y_range.y - y_range.x) * delta
			var all_gone := true
			for b in spirits.size():
				spirits[b] += spirit_vel * delta
				if spirits[b].y >= y_range.x - 0.1 * (y_range.y - y_range.x):
					all_gone = false
			if all_gone:
				running = false
				falling = false
				show_spirit = false
				run_finished.emit(false, fail_reason)

		if show_spirit:
			for b in spirits.size():
				trails[b].append(to_screen(spirits[b]))
				if trails[b].size() > 26:
					trails[b].pop_front()

		for p in particles:
			p.p += p.v * delta
			p.v.y += 260.0 * delta
			p.life -= delta * 1.3
		particles = particles.filter(func(p): return p.life > 0.0)
		queue_redraw()

	func _burst(pos: Vector2, c: Color, n: int) -> void:
		for i in n:
			var ang := randf() * TAU
			particles.append({"p": pos, "v": Vector2(cos(ang), sin(ang)) * randf_range(60, 220) + Vector2(0, -80),
				"life": 1.0, "c": c, "r": randf_range(2.0, 4.5)})

	# ---------- 繪圖 ----------

	static func nice_step(span: float) -> float:
		for s in [0.25, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0]:
			if span / s <= 12.0:
				return s
		return 2000.0

	func _draw() -> void:
		var font := get_theme_default_font()
		var w := size.x
		var hh := size.y

		# 天空、星星、遠景畫在背後的分層裡（見 _ready）
		_update_bg()
		if plain:
			draw_style_box(UITheme.boxc(Color(0, 0, 0, 0), 4, Color(1, 1, 1, 0.10), 1, 0), Rect2(Vector2.ZERO, size))
			return

		_draw_grid(font)
		if type == "quadrant":
			_draw_lamps(font)

		# 雷射牆（漸近線）
		var ay := asymptote_y()
		var draw_wall := type != "draw" or draw_show_asym or draw_reveal
		if draw_wall and type != "rank" and type != "cross" and type != "table" and type != "chord" and not is_nan(ay) and ay > y_range.x and ay < y_range.y:
			var flick := 0.55 + 0.25 * sin(t * 9.0)
			var y0 := to_screen(Vector2(0, ay)).y
			draw_line(Vector2(0, y0), Vector2(w, y0), Color(1, 0.3, 0.4, 0.12), 10.0)
			draw_dashed_line(Vector2(0, y0), Vector2(w, y0), Color(1, 0.35, 0.45, flick), 2.0, 12.0)
			preload("math_text.gd").draw_text(self, font, Vector2(w - 160, y0 - 8), "雷射牆  y = " + UITheme.num(ay, 2),
				HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(1, 0.5, 0.55, 0.9))

		var ax := asymptote_x()
		if (type == "fit" or type == "count" or (type == "draw" and draw_wall)) and not is_nan(ax) and ax > x_range.x and ax < x_range.y:
			var flick2 := 0.55 + 0.25 * sin(t * 9.0)
			var x0 := to_screen(Vector2(ax, 0)).x
			draw_line(Vector2(x0, 0), Vector2(x0, hh), Color(1, 0.3, 0.4, 0.12), 10.0)
			draw_dashed_line(Vector2(x0, 0), Vector2(x0, hh), Color(1, 0.35, 0.45, flick2), 2.0, 12.0)
			preload("math_text.gd").draw_text(self, font, Vector2(x0 + 8, hh - 46), "雷射牆  x = " + UITheme.num(ax, 2),
				HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(1, 0.5, 0.55, 0.9))
		if mirror:
			_draw_mirror(font)
		if not source.is_empty():
			_draw_source(font)
		var gf := Callable()
		var ghost_label := "鏡中分身"
		if not ghost_on:
			pass
		elif type == "fit" and ghost == "inverse" and inverse_of(form) != "":
			var inv := inverse_of(form)
			gf = func(x): return fval(inv, a, k, h, 1.0, x, 0)
		elif type == "fit" and ghost == "x_axis":
			# 鏡子換成 x 軸：分身是 −f(x)（對數時就是 log_{1/a} x）
			gf = func(x): return -fb(x, 0)
			ghost_label = "x 軸倒影"
			var y0 := to_screen(Vector2(0, 0)).y
			draw_line(Vector2(0, y0), Vector2(size.x, y0), Color(0.85, 0.9, 1.0, 0.08), 14.0)
			preload("math_text.gd").draw_text(self, font, Vector2(size.x - 120, y0 - 10), "鏡子  x 軸", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15),
				Color(0.85, 0.9, 1.0, 0.8))
		if gf.is_valid():
			# 分身的線段也快取：底數、範圍沒變就不用每一幀重算
			var gkey := [ghost, form, a, h, k, m, x_range, y_range, size]
			if _ghost_cache.is_empty() or _ghost_cache[0] != gkey:
				var gs := []
				for seg in _segments(gf):
					gs.append(UITheme.thin(seg))
				_ghost_cache = [gkey, gs]
			for seg in _ghost_cache[1]:
				draw_polyline(seg, Color(MIRROR_COL.r, MIRROR_COL.g, MIRROR_COL.b, 0.10), 12.0)
				draw_polyline(seg, Color(MIRROR_COL.r, MIRROR_COL.g, MIRROR_COL.b, 0.55), 2.0, true)
			_ghost_tag(font, gf, ghost_label + "　" + _ghost_eq(),
				"光橋對鏡子 y = x 翻過去的圖形（反函數）" if ghost == "inverse" else "光橋對 x 軸上下翻過去的圖形",
				Color(MIRROR_COL.r, MIRROR_COL.g, MIRROR_COL.b, 0.95))

		for i in holes.size():
			var c := to_screen(holes[i])
			UITheme.dot(self, c, HOLE_PX + 8, Color(0.5, 0.2, 0.9, 0.12))
			UITheme.dot(self, c, HOLE_PX, Color(0.04, 0.02, 0.08))
			for j in 3:
				var st := t * 2.2 + j * TAU / 3.0
				draw_arc(c, HOLE_PX - 4 - j * 5, st, st + 2.2, 24, Color(0.7, 0.4, 1.0, 0.8 - j * 0.2), 2.5)

		if type == "rank":
			_draw_rank(font)
		elif type == "cross":
			_draw_cross(font)
		elif type == "table":
			_draw_table(font)
		elif type == "draw":
			_draw_sketch(font)
		elif not hide_curve:
			var col := CURVE_COL.lerp(GOLD, curve_gold)
			for b in branch_count():
				for seg in _curve_segs(b):
					_glow_line(seg, col, true)

		if type == "count" and not is_nan(line_c):
			_draw_count(font)
		if type == "chord":
			_draw_chord(font)

		for i in gems.size():
			var gp: Vector2 = gems[i]
			var c := to_screen(gp) + Vector2(0, sin(t * 3.0 + i) * 3.0)
			var lit: bool = gem_state[i] == 1 or (live and not running and passes(gp))
			var gc := GOLD if lit else Color(0.75, 0.85, 1.0)
			if gem_state[i] == 2:
				gc = UITheme.BAD
			UITheme.dot(self, c, 18.0 if lit else 13.0, Color(gc.r, gc.g, gc.b, 0.18))
			var sz := 11.0
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -sz), c + Vector2(sz * 0.75, 0),
				c + Vector2(0, sz), c + Vector2(-sz * 0.75, 0)]), gc)
			draw_line(c + Vector2(-3, -4), c + Vector2(1, -7), Color(1, 1, 1, 0.8), 2.0)
			draw_string(font, c + Vector2(-40, 30), "(%s, %s)" % [UITheme.num(gp.x, 2), UITheme.num(gp.y, 2)],
				HORIZONTAL_ALIGNMENT_CENTER, 80, UITheme.fs(13), Color(1, 1, 1, 0.75))

		var sp_eq: Dictionary = preload("spirit_look.gd").eq_of(self)
		for tr in trails:
			if sp_eq.has("trail"):
				var rev: Array = tr.duplicate()
				rev.reverse()
				preload("spirit_look.gd").draw_path_trail(self, rev.slice(0, 40), 9.0, sp_eq, t)
				continue
			for i in tr.size():
				var f_: float = float(i) / tr.size()
				UITheme.dot(self, tr[i], 2.0 + 5.0 * f_, Color(1.0, 0.95, 0.7, 0.25 * f_))
		if show_spirit:
			for spw in spirits:
				_draw_spirit(to_screen(spw))

		for p in particles:
			UITheme.dot(self, p.p, p.r * p.life, Color(p.c.r, p.c.g, p.c.b, p.life))

		if demo_t >= 0.0:
			_draw_demo(font)
			draw_style_box(UITheme.boxc(Color(0, 0, 0, 0), 4, Color(1, 1, 1, 0.10), 1, 0), Rect2(Vector2.ZERO, size))
			return
		if demo_btn and not demo.is_empty():
			var bt := "▶ 圖形怎麼來的？"
			var bw := font.get_string_size(bt, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15)).x + 28.0
			demo_btn_rect = Rect2(size.x - bw - 12.0, 12, bw, 32)
			var pulse := 0.5 + 0.5 * sin(t * 3.0)
			draw_style_box(UITheme.boxc(Color(1, 0.81, 0.35, 0.16 + 0.08 * pulse), 16, Color(1, 0.81, 0.35, 0.55 + 0.35 * pulse), 2, 0), demo_btn_rect)
			draw_string(font, demo_btn_rect.position + Vector2(14, 22), bt, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), GOLD)

		if type == "fit":
			_pill(font, "練習模式" if live else "霧中模式",
				UITheme.GOOD if live else UITheme.VIOLET)
		elif type == "cross" and cross_sketch > 0:
			_pill(font, ("找整數點：第 %d 條" if mark_on else "徒手作圖：第 %d 條") % cross_sketch, CURVE_COL if cross_sketch == 1 else UITheme.ORANGE)
		elif type == "draw" and not draw_reveal:
			_pill(font, "找整數點" if mark_on else "徒手作圖", Color(1, 0.85, 0.4))
		elif type == "table" and bands_on:
			_pill(font, "點選交點所在的區間", Color(1, 0.85, 0.4))
		draw_style_box(UITheme.boxc(Color(0, 0, 0, 0), 4, Color(1, 1, 1, 0.10), 1, 0), Rect2(Vector2.ZERO, size))

	func _draw_grid(font: Font) -> void:
		var sx := nice_step(x_range.y - x_range.x)
		var sy := nice_step(y_range.y - y_range.x)
		var gx := ceilf(x_range.x / sx) * sx
		while gx <= x_range.y + 1e-6:
			var axis := is_zero_approx(gx)
			draw_line(to_screen(Vector2(gx, y_range.x)), to_screen(Vector2(gx, y_range.y)),
				Color(1, 1, 1, 0.55) if axis else Color(1, 1, 1, 0.06), 2.0 if axis else 1.0)
			if not axis:
				draw_string(font, to_screen(Vector2(gx, clampf(0, y_range.x, y_range.y))) + Vector2(-14, 18),
					UITheme.num(gx, 2), HORIZONTAL_ALIGNMENT_CENTER, 28, UITheme.fs(12), Color(1, 1, 1, 0.5))
			gx += sx
		var gy := ceilf(y_range.x / sy) * sy
		while gy <= y_range.y + 1e-6:
			var axis := is_zero_approx(gy)
			draw_line(to_screen(Vector2(x_range.x, gy)), to_screen(Vector2(x_range.y, gy)),
				Color(1, 1, 1, 0.55) if axis else Color(1, 1, 1, 0.06), 2.0 if axis else 1.0)
			if not axis:
				draw_string(font, to_screen(Vector2(clampf(0, x_range.x, x_range.y), gy)) + Vector2(-44, 5),
					UITheme.num(gy, 2), HORIZONTAL_ALIGNMENT_RIGHT, 40, UITheme.fs(12), Color(1, 1, 1, 0.5))
			gy += sy

	## 鏡子 y = x：銀色虛線＋淡淡的光帶
	func _draw_mirror(font: Font) -> void:
		var lo := maxf(x_range.x, y_range.x)
		var hi := minf(x_range.y, y_range.y)
		if lo >= hi:
			return
		var p0 := to_screen(Vector2(lo, lo))
		var p1 := to_screen(Vector2(hi, hi))
		draw_line(p0, p1, Color(0.85, 0.9, 1.0, 0.07), 14.0)
		draw_dashed_line(p0, p1, Color(0.85, 0.9, 1.0, 0.55), 2.0, 10.0)
		var lp := p1 + (p0 - p1).normalized() * 110.0
		lp.x = clampf(lp.x, 10.0, size.x - 110.0)
		preload("math_text.gd").draw_text(self, font, lp + Vector2(12, -4), "鏡子  y = x", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(0.85, 0.9, 1.0, 0.8))

	## 鏡像配對：原曲線（粉紅）＋每顆寶石和它在原曲線上的「本尊」之間的虛線
	func _draw_source(font: Font) -> void:
		var sf: Callable = func(x): return side_val(source, x)
		for seg in _segments(sf):
			_glow_line(seg, MIRROR_COL)
		for g in gems:
			var orig := Vector2(g.y, g.x)
			var a2 := to_screen(orig)
			var b2 := to_screen(g)
			draw_dashed_line(a2, b2, Color(1, 1, 1, 0.35), 1.5, 6.0)
			UITheme.dot(self, a2, 6.0, Color(MIRROR_COL.r, MIRROR_COL.g, MIRROR_COL.b, 0.3))
			UITheme.dot(self, a2, 4.0, MIRROR_COL)
		_curve_label(font, sf, "原曲線", MIRROR_COL)

	## 在曲線靠右、還在畫面內的地方寫上名字
	func _curve_label(font: Font, f: Callable, text: String, c: Color) -> void:
		var span := y_range.y - y_range.x
		var x := x_range.y - 0.12 * (x_range.y - x_range.x)
		while x > x_range.x:
			var y: float = f.call(x)
			if not is_nan(y) and y > y_range.x + 0.12 * span and y < y_range.y - 0.08 * span:
				draw_string(font, to_screen(Vector2(x, y)) + Vector2(-60, -16), text,
					HORIZONTAL_ALIGNMENT_CENTER, 120, UITheme.fs(15), c)
				return
			x -= 0.02 * (x_range.y - x_range.x)

	## 鏡中分身的方程式（跟著底數 a 即時變）
	func _ghost_eq() -> String:
		var A := UITheme.nice_text(a)
		var tail := func(v: float) -> String:
			if is_zero_approx(v):
				return ""
			return (" + %s" if v > 0.0 else " − %s") % UITheme.num(absf(v), 2)
		var inner := func(v: float) -> String:
			if is_zero_approx(v):
				return "x"
			return ("x − %s" if v > 0.0 else "x + %s") % UITheme.num(absf(v), 2)
		if ghost == "x_axis":
			if form == "log" and is_zero_approx(h) and is_zero_approx(k):
				return "y = −log_{%s} x = log_{%s} x" % [A, UITheme.nice_text(1.0 / a)]
			if form == "log":
				return "y = −[log_{%s} (%s)%s]" % [A, inner.call(h), tail.call(k)]
			return "y = −(%s^{%s}%s)" % [A, inner.call(h), tail.call(k)]
		# 反函數：x、y 互換
		if form == "log":
			return "y = %s^{%s}%s" % [A, inner.call(k), tail.call(h)]
		return "y = log_{%s} (%s)%s" % [A, inner.call(k), tail.call(h)]

	## 鏡中分身的標籤：方程式＋一行說明，有底色的框，放在曲線旁邊
	func _ghost_tag(font: Font, f: Callable, title: String, note: String, c: Color) -> void:
		var ML := preload("math_text.gd")
		var fs1 := UITheme.fs(15)
		var fs2 := UITheme.fs(12)
		var w := maxf(ML.text_width(font, title, fs1), ML.text_width(font, note, fs2)) + 20.0
		var e1 := ML.line_extent(title, fs1)
		var h := e1.x + e1.y + fs2 + 18.0
		# 寶石（含底下的座標文字）占的地方：標籤盡量不要蓋到
		var busy := []
		for gp in gems:
			var sp := to_screen(gp)
			busy.append(Rect2(sp.x - 44.0, sp.y - 22.0, 88.0, 58.0))
		var span := y_range.y - y_range.x
		var best := Rect2()
		var found := false
		var x := x_range.y - 0.1 * (x_range.y - x_range.x)
		while x > x_range.x and not found:
			var y: float = f.call(x)
			if not is_nan(y) and y > y_range.x + 0.1 * span and y < y_range.y - 0.06 * span:
				var p := to_screen(Vector2(x, y))
				for off in [Vector2(-w - 10.0, -h - 12.0), Vector2(12.0, -h - 12.0), Vector2(12.0, 12.0), Vector2(-w - 10.0, 12.0)]:
					var r := Rect2(p + off, Vector2(w, h))
					if r.position.x < 6.0 or r.position.y < 6.0 or r.end.x > size.x - 6.0 or r.end.y > size.y - 70.0:
						continue
					if best.size == Vector2.ZERO:
						best = r
					var ok := true
					for bz in busy:
						if r.intersects(bz):
							ok = false
							break
					if ok:
						best = r
						found = true
						break
			x -= 0.02 * (x_range.y - x_range.x)
		if best.size == Vector2.ZERO:
			return
		draw_style_box(UITheme.boxc(Color(0.08, 0.03, 0.12, 0.82), 10, Color(c.r, c.g, c.b, 0.6), 1, 0), best)
		ML.draw_on(self, font, best.get_center().x, best.position.y + 6.0 + e1.x, title, fs1, c)
		ML.draw_on(self, font, best.get_center().x, best.end.y - 8.0, note, fs2, Color(c.r, c.g, c.b, 0.75))

	func _tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
		draw_primitive(PackedVector2Array([a, b, c]), PackedColorArray([Color(col.r, col.g, col.b, 0.24)]),
			PackedVector2Array())

	## 角落的小徽章（right = true 放右上角）
	func _pill(font: Font, text: String, c: Color, right: bool = false) -> void:
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15)).x + 26.0
		var x0 := size.x - w - 12.0 if right else 12.0
		draw_style_box(UITheme.boxc(Color(c.r, c.g, c.b, 0.16), 15, Color(c.r, c.g, c.b, 0.6), 1, 0), Rect2(x0, 12, w, 30))
		draw_string(font, Vector2(x0 + 13, 32), text, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), c)

	## 徒手作圖：玩家的筆跡（偏離太遠的地方標紅）、提示點、揭曉的正確圖形
	func _draw_sketch(font: Font) -> void:
		if draw_reveal:
			for seg in _segments(func(x): return fb(x, 0)):
				_glow_line(seg, GOLD)
		_draw_stroke_layer(font, Color.WHITE)

	## 筆跡、提示點、「按住拖曳」的提示（徒手作圖與交點獵人共用）
	func _draw_stroke_layer(font: Font, ink: Color) -> void:
		_draw_marks(font)
		for g in guide_pts:
			var gc := to_screen(g[0])
			UITheme.dot(self, gc, 11.0, Color(0.55, 0.85, 1.0, 0.2))
			UITheme.dot(self, gc, 5.5, UITheme.CYAN_LIGHT)
			var gl := String(g[1])
			var gw := font.get_string_size(gl, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15)).x
			var gx := 10.0 if gc.x + 10.0 + gw < size.x - 4.0 else -10.0 - gw     # 太靠右就寫在點的左邊
			draw_string(font, gc + Vector2(gx + 1, -9), gl, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(0, 0, 0, 0.7))
			draw_string(font, gc + Vector2(gx, -10), gl, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), UITheme.CYAN_PALE)
		if draw_show_keys or draw_reveal:
			for kp in (hint_keys if draw_show_keys and not hint_keys.is_empty() else draw_keys):
				var c := to_screen(kp)
				draw_arc(c, 10.0, 0, TAU, 28, Color(1, 0.85, 0.4, 0.9), 2.0, true)
				UITheme.dot(self, c, 3.0, Color(1, 0.85, 0.4))
				if mark_done and mark_sel.has(kp):
					continue      # 找整數點時已經標過座標了，不要寫兩次
				draw_string(font, c + Vector2(-40, 26), "(%s, %s)" % [UITheme.nice_text(kp.x), UITheme.nice_text(kp.y)],
					HORIZONTAL_ALIGNMENT_CENTER, 80, UITheme.fs(13), Color(1, 0.9, 0.6, 0.9))
		for one in strokes + [stroke]:
			if one.size() >= 2:
				draw_polyline(one, Color(ink.r, ink.g, ink.b, 0.12), 14.0, true)
				draw_polyline(one, Color(ink.r, ink.g, ink.b, 0.9).lerp(Color.WHITE, 0.4), 3.5, true)
		for p in stroke_bad:
			UITheme.dot(self, p, 11.0, Color(1.0, 0.3, 0.4, 0.22))
		for p in stroke_bad:
			UITheme.dot(self, p, 5.5, Color(1.0, 0.35, 0.45, 0.95))
		if draw_on and stroke.is_empty() and strokes.is_empty():
			var a2 := 0.45 + 0.3 * sin(t * 3.0)
			draw_string(font, Vector2(0, size.y / 2.0 - 60), "按住拖曳畫出圖形（可以分好幾筆）", HORIZONTAL_ALIGNMENT_CENTER, size.x, UITheme.fs(24),
				Color(1, 1, 1, a2))

	## 列表作圖：已比較過的點、可點選的區間、「＝」的交點、最後揭曉的曲線
	func _draw_table(font: Font) -> void:
		var exp_col := CURVE_COL
		var q_col := UITheme.ORANGE
		var gold := Color(1, 0.85, 0.4)
		# 區間
		for i in band_sel.size():
			var xa := to_screen(Vector2(table_xs[i], 0)).x + 6.0
			var xb := to_screen(Vector2(table_xs[i + 1], 0)).x - 6.0
			var rect := Rect2(xa, 0, xb - xa, size.y)
			if band_sel[i]:
				draw_rect(rect, Color(gold.r, gold.g, gold.b, 0.16))
				draw_rect(rect, Color(gold.r, gold.g, gold.b, 0.7), false, 2.0)
				var mid := Vector2((xa + xb) * 0.5, 66.0)
				UITheme.dot(self, mid, 11.0, gold)
				_star(mid, 6.0, Color(0.1, 0.08, 0.2))
				draw_string(font, Vector2(xa, 98), "有交點", HORIZONTAL_ALIGNMENT_CENTER, xb - xa, UITheme.fs(15), gold)
			elif bands_on:
				var a := 0.10 if i == band_hover else 0.04
				draw_rect(rect, Color(1, 1, 1, a))
				var mid := Vector2((xa + xb) * 0.5, 66.0)
				var pulse := 0.45 + 0.25 * sin(t * 3.0 + i)
				draw_arc(mid, 11.0, 0, TAU, 28, Color(1, 0.85, 0.4, pulse), 2.0, true)
		# 目前這一格：一條虛線＋問號
		if table_cur >= 0:
			var cx := to_screen(Vector2(table_xs[table_cur], 0)).x
			var yy := 0.0
			while yy < size.y:
				draw_line(Vector2(cx, yy), Vector2(cx, yy + 8), Color(1, 0.85, 0.4, 0.55), 2.0)
				yy += 16.0
			preload("math_text.gd").draw_text(self, font, Vector2(cx - 30, 28), "x = %s" % x_text_s(table_xs[table_cur]),
				HORIZONTAL_ALIGNMENT_CENTER, 60, UITheme.fs(15), Color(1, 0.85, 0.4))
		# 揭曉的曲線
		if reveal_t >= 0.0:
			var x_end := lerpf(x_range.x, x_range.y, reveal_t)
			for seg in _segments_in(f_quad, x_range.x, x_end):
				_glow_line(seg, q_col)
			for seg in _segments_in(f_exp, x_range.x, x_end):
				_glow_line(seg, exp_col)
			for rx in cross_roots:
				if rx <= x_end:
					var p := to_screen(Vector2(rx, f_exp(rx)))
					UITheme.dot(self, p, 15.0 + 2.0 * sin(t * 4.0), Color(1, 1, 1, 0.15))
					UITheme.dot(self, p, 7.0, Color.WHITE)
					UITheme.dot(self, p, 3.5, GOLD)
		# 點與「＝」交點
		for i in table_xs.size():
			if not table_shown[i]:
				continue
			var pe := to_screen(Vector2(table_xs[i], table_e[i]))
			var pq := to_screen(Vector2(table_xs[i], table_q[i]))
			if table_signs[i] == 0:
				UITheme.dot(self, pe, 14.0, Color(1, 1, 1, 0.18))
				draw_arc(pe, 12.0, 0, TAU, 32, Color.WHITE, 2.0, true)
				UITheme.dot(self, pe, 6.0, gold)
				draw_string(font, pe + Vector2(-40, -20), "交點", HORIZONTAL_ALIGNMENT_CENTER, 80, UITheme.fs(15), Color.WHITE)
			else:
				UITheme.dot(self, pq, 7.0, Color(q_col.r, q_col.g, q_col.b, 0.25))
				UITheme.dot(self, pq, 5.0, q_col)
				UITheme.dot(self, pe, 7.0, Color(exp_col.r, exp_col.g, exp_col.b, 0.25))
				UITheme.dot(self, pe, 5.0, exp_col)

	static func x_text_s(x) -> String:
		var v := float(x)
		if is_equal_approx(v, roundf(v)):
			return str(int(roundf(v)))
		return UITheme.nice_text(v)

	func _star(c: Vector2, r0: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for k in 8:
			var ang := -PI / 2 + k * PI / 4
			pts.append(c + Vector2(cos(ang), sin(ang)) * (r0 if k % 2 == 0 else r0 * 0.4))
		draw_colored_polygon(pts, col)

	static var _fog: GradientTexture2D

	static func _fog_tex() -> GradientTexture2D:
		if _fog == null:
			var g := Gradient.new()
			g.set_color(0, Color(0.78, 0.65, 1.0, 0.10))
			g.set_color(1, Color(0.78, 0.65, 1.0, 0.0))
			_fog = GradientTexture2D.new()
			_fog.gradient = g
			_fog.fill = GradientTexture2D.FILL_RADIAL
			_fog.fill_from = Vector2(0.5, 0.5)
			_fog.fill_to = Vector2(1.0, 0.5)
			_fog.width = 128
			_fog.height = 128
		return _fog

	## 霧：沒掃過的地方飄著幾團淡紫色的雲
	func _draw_fog() -> void:
		for k in 14:
			var fx := fposmod(k * 0.173 + t * 0.012 * (1 + k % 3), 1.0)
			var wx := lerpf(x_range.x, x_range.y, fx)
			if scan_on and wx >= swept.x - 0.3 and wx <= swept.y + 0.3:
				continue
			var p := Vector2(fx * size.x, size.y * fposmod(k * 0.379 + 0.1, 0.85))
			var rr := 80.0 + 50.0 * fposmod(k * 0.61, 1.0)
			draw_texture_rect(_fog_tex(), Rect2(p - Vector2(rr * 1.4, rr), Vector2(rr * 2.8, rr * 2.0)), false)

	## 交點獵人：兩條曲線、掃過的區域上色、掃描線、找到的交點
	func _draw_cross(font: Font) -> void:
		var exp_col := CURVE_COL
		var q_col := UITheme.ORANGE
		# 漸近線提示（畫錯兩次以上）
		if draw_show_asym and cross_sketch > 0:
			var axv := asymptote_x()
			var fy := _floor_y()
			var flick := 0.55 + 0.25 * sin(t * 9.0)
			if not is_nan(axv):
				var x0 := to_screen(Vector2(axv, 0)).x
				draw_dashed_line(Vector2(x0, 0), Vector2(x0, size.y), Color(1, 0.35, 0.45, flick), 2.0, 12.0)
			if not is_nan(fy):
				var y0 := to_screen(Vector2(0, fy)).y
				draw_dashed_line(Vector2(0, y0), Vector2(size.x, y0), Color(1, 0.35, 0.45, flick), 2.0, 12.0)
		# 已經畫對的圖形
		if cross_drawn[1]:
			for seg in _segments(f_quad):
				_glow_line(seg, q_col)
		if cross_drawn[0]:
			for seg in _segments(f_exp):
				_glow_line(seg, exp_col)
		if cross_sketch > 0:
			var cc := exp_col if cross_sketch == 1 else q_col
			if not segs_done.is_empty():
				var segs := _segments(func(x): return _tf(x))
				for i in segs_done:
					if i < segs.size():
						_glow_line(segs[i], cc)
			_draw_stroke_layer(font, cc)
		# 掃過的區域：誰在上面就塗誰的顏色
		if scan_on and swept.x <= swept.y:
			var x0 := maxf(swept.x, x_range.x)
			var x1 := minf(swept.y, x_range.y)
			var n := int(ceil((x1 - x0) / ((x_range.y - x_range.x) / 240.0)))
			var pad := 0.05 * (y_range.y - y_range.x)
			for i in n:
				var xa := lerpf(x0, x1, float(i) / n)
				var xb := lerpf(x0, x1, float(i + 1) / n)
				var ea := clampf(f_exp(xa), y_range.x - pad, y_range.y + pad)
				var eb := clampf(f_exp(xb), y_range.x - pad, y_range.y + pad)
				var qa := clampf(f_quad(xa), y_range.x - pad, y_range.y + pad)
				var qb := clampf(f_quad(xb), y_range.x - pad, y_range.y + pad)
				var da := f_exp(xa) - f_quad(xa)
				var db := f_exp(xb) - f_quad(xb)
				if is_nan(da) or is_nan(db):
					continue
				var pa := to_screen(Vector2(xa, ea))
				var pb := to_screen(Vector2(xb, eb))
				var qa2 := to_screen(Vector2(xa, qa))
				var qb2 := to_screen(Vector2(xb, qb))
				if da * db < 0.0:
					# 這一小段裡兩條曲線交叉：在交點切成兩個三角形，各塗各的顏色
					var f := da / (da - db)
					var pm := pa.lerp(pb, f)
					_tri(pa, pm, qa2, exp_col if da > 0.0 else q_col)
					_tri(pm, pb, qb2, exp_col if db > 0.0 else q_col)
				else:
					var c := exp_col if da + db > 0.0 else q_col
					_tri(pa, pb, qb2, c)
					_tri(pa, qb2, qa2, c)
		if scan_on and swept.x <= swept.y:
			var band_y := size.y - 10.0
			var bx0 := maxf(swept.x, x_range.x)
			var bx1 := minf(swept.y, x_range.y)
			var steps := int(ceil((bx1 - bx0) / ((x_range.y - x_range.x) / 350.0)))
			for i in steps:
				var xa := lerpf(bx0, bx1, float(i) / steps)
				var xb := lerpf(bx0, bx1, float(i + 1) / steps)
				var dm := f_exp((xa + xb) / 2.0) - f_quad((xa + xb) / 2.0)
				if is_nan(dm):
					continue
				var up := dm > 0.0
				var bc := exp_col if up else q_col
				draw_rect(Rect2(to_screen(Vector2(xa, 0)).x, band_y, to_screen(Vector2(xb, 0)).x - to_screen(Vector2(xa, 0)).x + 0.5, 6.0), bc)
		if scan_on and swept.x <= swept.y:
			for seg in _segments_in(f_quad, swept.x, swept.y):
				_glow_line(seg, q_col)
			for seg in _segments_in(f_exp, swept.x, swept.y):
				_glow_line(seg, exp_col)
		# 找到的交點
		for i in cross_roots.size():
			if not cross_found[i]:
				continue
			var rx: float = cross_roots[i]
			var p := to_screen(Vector2(rx, f_exp(rx)))
			UITheme.dot(self, p, 16.0 + 2.0 * sin(t * 4.0 + i), Color(1, 1, 1, 0.14))
			UITheme.dot(self, p, 8.0, Color.WHITE)
			UITheme.dot(self, p, 4.0, GOLD)
			var lab := "x = %d" % roundi(rx) if absf(rx - roundf(rx)) < 0.005 else "x ≈ %s" % UITheme.num(rx, 2)
			var lx := clampf(p.x - 50.0, 4.0, size.x - 104.0)
			var ly := p.y - 18.0 if p.y > 60.0 else p.y + 32.0
			draw_string(font, Vector2(lx, ly), lab, HORIZONTAL_ALIGNMENT_CENTER, 100, UITheme.fs(15), Color(1, 1, 1, 0.95))
		if not scan_on:
			return
		# 掃描線
		var top := to_screen(Vector2(scan_x, y_range.y))
		var bot := to_screen(Vector2(scan_x, y_range.x))
		draw_line(top, bot, Color(1, 0.85, 0.4, 0.22), 8.0)
		draw_dashed_line(top, bot, Color(1, 0.85, 0.4, 0.95), 2.0, 8.0)
		preload("math_text.gd").draw_text(self, font, bot + Vector2(-50, -20), "x = " + UITheme.num(scan_x, 2),
			HORIZONTAL_ALIGNMENT_CENTER, 100, UITheme.fs(15), Color(1, 0.85, 0.4))
		# 還能往左右走的提示箭頭
		var a := 0.35 + 0.25 * sin(t * 3.0)
		var cy := size.y / 2.0
		if cam > cross_dom.x + CROSS_HW + 0.05:
			draw_polyline(PackedVector2Array([Vector2(26, cy - 16), Vector2(14, cy), Vector2(26, cy + 16)]),
				Color(1, 1, 1, a), 3.0, true)
		if cam < cross_dom.y - CROSS_HW - 0.05:
			draw_polyline(PackedVector2Array([Vector2(size.x - 26, cy - 16), Vector2(size.x - 14, cy),
				Vector2(size.x - 26, cy + 16)]), Color(1, 1, 1, a), 3.0, true)

	## 主曲線的線段（已精簡點數）：參數和畫面範圍沒變就沿用，不用每一幀重算 480 個點
	var _cseg_cache := {}
	var _ghost_cache := []

	func _curve_segs(b: int) -> Array:
		var key := [form, a, h, k, m, b, x_range, y_range, size]
		if _cseg_cache.has(b) and _cseg_cache[b][0] == key:
			return _cseg_cache[b][1]
		var segs := []
		for seg in _segments(func(x): return fb(x, b)):
			segs.append(UITheme.thin(seg))
		_cseg_cache[b] = [key, segs]
		return segs

	func _glow_line(seg: PackedVector2Array, col: Color, thinned := false) -> void:
		# 外兩層是半透明的光暈，邊緣本來就柔，不用抗鋸齒；點數先精簡（手機效能）
		if not thinned:
			seg = UITheme.thin(seg)
		draw_polyline(seg, Color(col.r, col.g, col.b, 0.08), 16.0)
		draw_polyline(seg, Color(col.r, col.g, col.b, 0.20), 8.0)
		draw_polyline(seg, col, 3.0, true)

	func _draw_spirit(sp: Vector2) -> void:
		# 沿光橋奔跑的光靈（含扭蛋抽到的裝扮；拖尾另外畫）
		preload("spirit_look.gd").draw_all(self, sp, 9.0, preload("spirit_look.gd").eq_of(self), t, false)

	## 底數辨識：多條曲線 + 名牌 + x = 1 的參考線
	func _draw_rank(font: Font) -> void:
		var cols: Array = [UITheme.PINK, UITheme.CYAN, UITheme.LIME, UITheme.ORANGE]
		var tags := ["A", "B", "C", "D"]
		for i in bases.size():
			var ba: float = bases[i]
			var rf: Callable = (func(x): return log(x) / log(ba) if x > 0.0 else NAN) if rank_log \
				else (func(x): return pow(ba, x))
			for seg in _segments(rf):
				_glow_line(seg, cols[i])
			var tp: Vector2
			if rank_log:
				# 名牌放在曲線離開畫面（右緣或上下緣）之前
				var tx2 := x_range.y - 0.3
				var span := y_range.y - y_range.x
				while tx2 > 0.2 and (rf.call(tx2) > y_range.y - 0.1 * span or rf.call(tx2) < y_range.x + 0.1 * span):
					tx2 -= 0.02
				tp = to_screen(Vector2(tx2, rf.call(tx2)))
			else:
				# 名牌放在曲線接近畫面上緣的地方
				var ty := y_range.y - 0.12 * (y_range.y - y_range.x)
				var tx := clampf(log(ty) / log(ba), x_range.x + 0.3, x_range.y - 0.3)
				tp = to_screen(Vector2(tx, pow(ba, tx)))
			tp.y = clampf(tp.y, 18.0, size.y - 18.0)
			if reveal_bases:
				# 答案揭曉：名牌直接換成底數
				var txt := UITheme.nice_text(ba)
				var tw := maxf(font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15)).x + 14.0, 26.0)
				draw_style_box(UITheme.boxc(cols[i], 13, Color(0, 0, 0, 0), 0, 0), Rect2(tp.x - tw / 2.0, tp.y - 13, tw, 26))
				draw_string(font, Vector2(tp.x - tw / 2.0, tp.y + 6), txt, HORIZONTAL_ALIGNMENT_CENTER, tw, UITheme.fs(15), Color("1a1530"))
			else:
				UITheme.dot(self, tp, 13.0, cols[i])
				draw_string(font, tp + Vector2(-13, 6), tags[i], HORIZONTAL_ALIGNMENT_CENTER, 26, UITheme.fs(15), Color("1a1530"))
		if not is_nan(probe_y):
			var l0 := to_screen(Vector2(x_range.x, probe_y))
			var l1 := to_screen(Vector2(x_range.y, probe_y))
			draw_line(l0, l1, Color(1, 0.85, 0.4, 0.25), 8.0)
			draw_dashed_line(l0, l1, Color(1, 0.85, 0.4, 0.9), 2.0, 8.0)
			preload("math_text.gd").draw_text(self, font, l1 + Vector2(-90, -10), "y = " + UITheme.num(probe_y, 2),
				HORIZONTAL_ALIGNMENT_RIGHT, 80, UITheme.fs(15), Color(1, 0.85, 0.4))
			for i in bases.size():
				var xb := pow(float(bases[i]), probe_y)
				if xb >= x_range.x and xb <= x_range.y:
					var p := to_screen(Vector2(xb, probe_y))
					UITheme.dot(self, p, 9.0, Color(1, 1, 1, 0.9))
					UITheme.dot(self, p, 6.0, cols[i])
		if not is_nan(probe_x):
			var top := to_screen(Vector2(probe_x, y_range.y))
			var bot := to_screen(Vector2(probe_x, y_range.x))
			draw_line(top, bot, Color(1, 0.85, 0.4, 0.25), 8.0)
			draw_dashed_line(top, bot, Color(1, 0.85, 0.4, 0.9), 2.0, 8.0)
			preload("math_text.gd").draw_text(self, font, bot + Vector2(-50, -10), "x = " + UITheme.num(probe_x, 2),
				HORIZONTAL_ALIGNMENT_CENTER, 100, UITheme.fs(15), Color(1, 0.85, 0.4))
			for i in bases.size():
				var y := pow(float(bases[i]), probe_x)
				if y <= y_range.y and y >= y_range.x:
					var p := to_screen(Vector2(probe_x, y))
					UITheme.dot(self, p, 9.0, Color(1, 1, 1, 0.9))
					UITheme.dot(self, p, 6.0, cols[i])

	## 象限燈塔
	func _draw_lamps(font: Font) -> void:
		var cx := clampf(0, x_range.x, x_range.y)
		var cy := clampf(0, y_range.x, y_range.y)
		var centers := {1: Vector2((cx + x_range.y) / 2, (cy + y_range.y) / 2),
			2: Vector2((cx + x_range.x) / 2, (cy + y_range.y) / 2),
			3: Vector2((cx + x_range.x) / 2, (cy + y_range.x) / 2),
			4: Vector2((cx + x_range.y) / 2, (cy + y_range.x) / 2)}
		var roman := ["", "Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ"]
		for q in [1, 2, 3, 4]:
			var p := to_screen(centers[q])
			var on: bool = lamp_lit.has(q)
			var want: bool = lamp_target.has(q)
			if on:
				UITheme.dot(self, p, 46.0, Color(1, 0.85, 0.4, 0.18))
				UITheme.dot(self, p, 30.0, Color(1, 0.85, 0.4, 0.55))
			if want:
				draw_arc(p, 36.0, 0, TAU, 48, Color(1, 0.85, 0.4, 0.8), 2.0)
			draw_string(font, p + Vector2(-30, 12), roman[q], HORIZONTAL_ALIGNMENT_CENTER, 60, UITheme.fs(30),
				Color(1, 0.95, 0.75) if on else Color(1, 1, 1, 0.25))

	## 交點調頻：水平線與交點
	func _draw_count(font: Font) -> void:
		var y0 := to_screen(Vector2(0, line_c)).y
		draw_line(Vector2(0, y0), Vector2(size.x, y0), Color(1, 0.85, 0.4, 0.2), 8.0)
		draw_line(Vector2(0, y0), Vector2(size.x, y0), Color(1, 0.85, 0.4, 0.95), 2.0)
		var rs := roots_of(line_c)
		for x in rs:
			if x >= x_range.x and x <= x_range.y:
				var p := to_screen(Vector2(x, line_c))
				UITheme.dot(self, p, 12.0 + 2.0 * sin(t * 6.0), Color(1, 0.85, 0.4, 0.3))
				UITheme.dot(self, p, 6.0, Color.WHITE)
		draw_string(font, Vector2(size.x - 170, 92), "交點：%d 個" % rs.size(),
			HORIZONTAL_ALIGNMENT_RIGHT, 150, UITheme.fs(24), Color(1, 0.9, 0.5))

	## 遠景的水晶塔：兩排剪影，塔尖有一點微光
	##   part = "shape"：塔身（不會動）；"glow"：後排塔尖的微光（會閃）
	func _tower_row(ci: CanvasItem, row: int, part: String, lift: float = 0.0) -> void:
		var hh := size.y - lift
		var c := Color(0.17, 0.10, 0.33, 0.45) if row == 0 else Color(0.08, 0.05, 0.18, 0.8)
		var x := -20.0 + row * 37.0
		var i := 0
		while x < size.x + 40.0:
			var w := 26.0 + 18.0 * fposmod(i * 0.618 + row * 0.3, 1.0)
			var tall := (62.0 if row == 0 else 30.0) * (0.55 + 0.75 * fposmod(i * 0.437 + row * 0.21, 1.0))
			var base := hh - (8.0 if row == 1 else 16.0)
			var top := base - tall
			if part == "shape":
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x, hh), Vector2(x, top),
					Vector2(x + w / 2.0, top - w * 0.8), Vector2(x + w, top), Vector2(x + w, hh)]), c)
				if row == 0:
					ci.draw_line(Vector2(x + w / 2.0, top - w * 0.8 + 4), Vector2(x + w / 2.0, hh), Color(1, 0.6, 0.9, 0.05), 2.0)
			elif row == 0:
				var glow := 0.25 + 0.2 * sin(t * 1.3 + i)
				UITheme.dot(ci, Vector2(x + w / 2.0, top - w * 0.8), 3.0, Color(1.0, 0.6, 0.85, glow))
			x += w + 12.0 + 20.0 * fposmod(i * 0.29, 1.0)
			i += 1

	func _mountain_on(ci: CanvasItem, base: float, amp: float, freq: float, c: Color) -> void:
		var pts := PackedVector2Array()
		var x := 0.0
		while x <= size.x + 20.0:
			pts.append(Vector2(x, base - amp * (0.6 + 0.4 * sin(x * freq + 1.3)) - amp * 0.35 * sin(x * freq * 2.7)))
			x += 20.0
		pts.append(Vector2(size.x, size.y))
		pts.append(Vector2(0, size.y))
		ci.draw_colored_polygon(pts, c)

	## 只取 lo ≤ x ≤ hi 的那一段
	func _segments_in(f: Callable, lo: float, hi: float) -> Array:
		var out := []
		for seg in _segments(f):
			var cur := PackedVector2Array()
			for p in seg:
				var wx := lerpf(x_range.x, x_range.y, p.x / size.x)
				if wx >= lo - 1e-6 and wx <= hi + 1e-6:
					cur.append(p)
				elif cur.size() >= 2:
					out.append(cur)
					cur = PackedVector2Array()
				else:
					cur = PackedVector2Array()
			if cur.size() >= 2:
				out.append(cur)
		return out

	## 把 y = f(x) 切成畫面內的線段；超出畫面就斷開
	func _segments(f: Callable) -> Array:
		var segs := []
		var cur := PackedVector2Array()
		var steps := 480
		var pad := 0.08 * (y_range.y - y_range.x)
		for i in steps + 1:
			var x := lerpf(x_range.x, x_range.y, float(i) / steps)
			var y: float = f.call(x)
			if is_nan(y) or y < y_range.x - pad or y > y_range.y + pad:
				if cur.size() >= 2:
					segs.append(cur)
				cur = PackedVector2Array()
				continue
			cur.append(to_screen(Vector2(x, y)))
		if cur.size() >= 2:
			segs.append(cur)
		return segs


# ================= 上方的進度點 =================

class Pips extends Control:
	var total := 0
	var current := 0
	var breaks: Array = []

	func setup(n: int, cur: int, br: Array) -> void:
		total = n
		current = cur
		breaks = br
		custom_minimum_size.x = n * 15.0 + br.size() * 10.0 + 6.0
		queue_redraw()

	func _draw() -> void:
		var x := 9.0
		var cy := size.y / 2.0
		for i in total:
			if breaks.has(i):
				x += 10.0
			var c := Vector2(x, cy)
			if i < current:
				UITheme.dot(self, c, 4.0, UITheme.ACCENT)
			elif i == current:
				UITheme.dot(self, c, 9.0, Color(1, 1, 1, 0.15))
				UITheme.dot(self, c, 5.5, Color.WHITE)
			else:
				UITheme.dot(self, c, 3.5, Color(1, 1, 1, 0.2))
			x += 15.0


## Stage 背景的一層：把 _draw 交給 Stage 的函式來畫（畫在 Stage 本身的內容後面）
class _BgLayer extends Control:
	var painter: Callable

	func _ready() -> void:
		show_behind_parent = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		painter.call(self)
