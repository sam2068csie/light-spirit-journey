extends Control
## 所有關卡共用的引擎（指數與對數 L1～L8、三角函數 G1～G7 都繼承它）
##   ・流程：章節選單 → 題目列表 → 一段旅程（預言、各種操作、推導）→ 結算、星塵、章節寶箱
##   ・計時、愛心、提示、光靈陪伴、暫停、計算紙、新手教學
##   ・光橋類的旅程（fit、rank、quadrant、count、table、cross、draw、chord）也在這裡；舞台本身在 light_stage.gd
## 一個大關＝繼承這個腳本，覆寫下面「這一大關的設定」那幾個函式（例：level_01_light_bridge.gd）。
## 推導題型的大關改繼承 step_level.gd（它也繼承這個腳本）。

signal level_cleared(stars: int)

const UITheme := preload("res://data/ui/game_theme.gd")
const MathLabel := preload("res://data/ui/math_text.gd")
const Game := preload("res://data/core/game.gd")
const PauseMenu := preload("res://data/ui/pause_menu.gd")
const Tut := preload("res://data/ui/tutorial.gd")
const Concepts := preload("res://data/ui/concept_cards.gd")
const ConceptDeck := preload("res://data/ui/concept_deck.gd")
const Buddy := preload("res://data/ui/buddy.gd")
const Ambient := preload("res://data/ui/ambient.gd")
const QP := preload("res://data/ui/quest_panel.gd")
const ChestFx := preload("res://data/levels/engine/chest_fx.gd")
const ConceptIcon := preload("res://data/ui/concept_icon.gd")
const Stage := preload("res://data/levels/engine/light_stage.gd")
const Pips := preload("res://data/levels/engine/level_pips.gd")
const _BgLayer := preload("res://data/levels/engine/bg_layer.gd")       # 物品圖示（星塵、寶箱…）
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
	return ""

func level_title() -> String:
	return ""

func level_subtitle() -> String:
	return ""

func level_chapters() -> Array:
	return []

func bank_slots() -> Array:
	return []

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

## 進入第二章時跳出的說明卡（{title, button, text}）
func chapter_card() -> Dictionary:
	return {"title": "", "button": "出發  ▶", "text": ""}


# ================= 初始化 =================

var scratch: Control      # 計算紙

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
	pause_menu.help_action = func(): _tut_show(["basic", "type:" + _tut_kind()])
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
	scratch = preload("res://data/ui/scratch_pad.gd").attach(self, top, pb)     # 計算紙（暫停鍵左邊的筆）
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
	hint_label.text = preload("res://data/levels/engine/step_bank.gd").root_markup(text)     # √3、√(a² + b²) 上面都要有橫線
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
	if scratch:
		scratch.clear()      # 換下一題：清掉計算紙
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
	_tut_check.call_deferred(round_gen)


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
	# 限時的試煉：預言時也要看得到愛心和倒數秒數
	energy_label.visible = r.has("time")
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
		# 限時的試煉：預言答錯也扣一顆心（終焉之塔已經在 _record 扣過）
		if r.has("time") and not tower_mode:
			energy -= 1
			_update_hud()
			if energy <= 0:
				_reveal("三顆心都用完了…")
				return
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
	task_label.text = "先在左圖點出%s經過的整數點（共 %d 個），再按「確認整數點」。" % [what, stage.mark_targets.size()]
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
			predicting = false
			_clear(predict_box)
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
	# 限時題：一進入題目就開始倒數（預言、推理步驟也算在內）
	if r.is_empty() or not r.has("time") or busy:
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
	elif _gold_ready(ch):
		_open_chest(ch, true)


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
	elif _gold_ready(ch):
		# 這一章所有題型都答對過了：打開章節黃金寶箱
		get_tree().create_timer(0.7).timeout.connect(func():
			if is_instance_valid(layer):
				_open_chest(ch, true))


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
	var eq := String(r.get("eq", "")).replace("\n", " ").replace("表|", "").replace("|", " ")     # 表格寫法換成一般文字
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


## 章節黃金寶箱：這一章完成度 100%（每段旅程的每一種題型都答對過）
func _gold_key(ch: int) -> String:
	return _chest_key(ch) + "_gold"


func _gold_ready(ch: int) -> bool:
	return not review_mode and _chapter_completion(ch) >= 0.999 and not Game.of(self).chest_claimed(_gold_key(ch))


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
	# 兩個寶箱排在同一行，省下垂直空間（題目列表才不會超出畫面）
	var v := HBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 28)
	v.add_child(_chest_status_row(ch, false))
	v.add_child(_chest_status_row(ch, true))
	return v


func _chest_status_row(ch: int, gold: bool) -> Control:
	var g = Game.of(self)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var ic := QP.ItemIcon.new()
	ic.kind = "chest"
	ic.custom_minimum_size = Vector2(34, 34)
	row.add_child(ic)
	if gold:
		ic.modulate = Color(1.0, 0.85, 0.3)
		var gl := Label.new()
		gl.add_theme_font_size_override("font_size", UITheme.fs(15))
		var pc := roundi(100.0 * _chapter_completion(ch))
		if g.chest_claimed(_gold_key(ch)):
			gl.text = "章節黃金寶箱　已打開 ✓"
			gl.add_theme_color_override("font_color", UITheme.GOOD)
			ic.modulate = Color(1.0, 0.85, 0.3, 0.45)
		else:
			gl.text = "章節黃金寶箱：完成度 %d%%／100%%" % pc
			gl.add_theme_color_override("font_color", Color("ffd36e") if pc >= 100 else UITheme.TEXT_DIM)
		row.add_child(gl)
		return row
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
		l.text = "章節大寶箱：通過 %d／%d 段旅程" % [done, sl.size()]
		l.add_theme_color_override("font_color", UITheme.ACCENT if done >= sl.size() else UITheme.TEXT_DIM)
	row.add_child(l)
	return row


## 章節大寶箱：寶箱跳一跳 → 點「打開」→ 東西飛出來、加進持有物品
var _chest_showing := false


func _open_chest(ch: int, gold := false) -> void:
	var g = Game.of(self)
	if _chest_showing or not (_gold_ready(ch) if gold else _chest_ready(ch)):
		return
	_chest_showing = true
	var item_name := level_title()
	var c: Color = UITheme.ACCENT
	for it in level_chapters():
		if it.ch == ch:
			item_name = it.name
			c = it.color
	g.sfx("open")
	var o := UITheme.modal(self, c, 440)
	var layer: Control = o[0]
	layer.tree_exited.connect(func(): _chest_showing = false)
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(_big_label(item_name, 26, c))
	col.add_child(_big_label("完成度 100%！獲得章節黃金寶箱" if gold else "全部通過！獲得章節大寶箱", 17, Color("ffd36e") if gold else UITheme.TEXT))
	var holder := CenterContainer.new()
	col.add_child(holder)
	var box := ChestFx.new()
	box.custom_minimum_size = Vector2(400, 190)
	box.glow = c
	box.gold = gold
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
			_chest_showing = false
			_refresh_journey_list(ch)
			if not gold and _gold_ready(ch):
				_open_chest(ch, true)      # 一次就 100%：大寶箱之後接著開黃金寶箱
			return
		if state[0] == 1:
			return
		state[0] = 1
		btn.disabled = true
		var got: Dictionary = g.claim_chest(_gold_key(ch) if gold else _chest_key(ch), _chest_final(ch), gold)
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






# ================= 上方的進度點 =================





# ================= 新手教學 =================
## 第一次進關卡：介紹畫面（basic）；第一次遇到某一種題型：介紹那種題型的操作（type:xxx）
## 看過的記在 Game.tut；暫停選單的「操作說明」可以再看一次。

func _tut_kind() -> String:
	return String(r.get("type", "")) if not r.is_empty() else ""


func _tut_check(gen: int) -> void:
	if tower_mode or r.is_empty():
		return
	var g = Game.of(self)
	var keys := []
	if not g.tut.get("basic", false):
		keys.append("basic")
	var tk := "type:" + _tut_kind()
	if not _tut_steps(tk).is_empty() and not g.tut.get(tk, false):
		keys.append(tk)
	if keys.is_empty():
		return
	await get_tree().create_timer(0.8).timeout
	# 推導題的開場（題目一個字一個字浮現）跑完再開始
	while is_inside_tree() and get("intro_block") != null:
		await get_tree().create_timer(0.2).timeout
	if not is_inside_tree() or gen != round_gen:
		return
	await get_tree().create_timer(0.45).timeout
	if not is_inside_tree() or gen != round_gen or get_tree().paused:
		return
	for k in keys:
		g.tut[k] = true
	g.save_review()
	_tut_show(keys)


func _tut_show(keys: Array) -> void:
	var st := []
	for k in keys:
		st.append_array(_tut_steps(k))
	if not st.is_empty():
		Tut.run(self, st)


func _grect(c: Control) -> Rect2:
	return c.get_global_rect() if is_instance_valid(c) and c.is_visible_in_tree() else Rect2()


func _union(list: Array) -> Rect2:
	var out := Rect2()
	for rc in list:
		if rc.size == Vector2.ZERO:
			continue
		out = rc if out.size == Vector2.ZERO else out.merge(rc)
	return out


func _tut_steps(key: String) -> Array:
	var side := func(): return _grect(side_card)
	var stg := func(): return _grect(stage)
	match key:
		"basic":
			return [
				{"text": "嗨！我是光靈～第一次來這裡嗎？我帶你看一下畫面，很快就好！"},
				{"rect": stg, "text": "左邊是「舞台」：圖形、題目和推導紀錄都在這裡。有些題目要直接在舞台上點、拖或畫。"},
				{"rect": func(): return _union([_grect(story_label), _grect(step_label)]),
				 "text": "右邊卡片最上面是這一題的故事，和你現在走到第幾步。"},
				{"rect": side, "text": "作答都在這張卡片裡：照著金色的字做，選擇、填空、拖滑桿都在這裡。"},
				{"rect": func(): return _grect(side_btns) if _grect(go_btn).size.x > 2.0 else Rect2(),
				 "text": UITheme.kb("需要送出的時候，按最下面的金色按鈕（也可以按 Enter）。", "需要送出的時候，按最下面的金色按鈕。")},
				{"rect": func(): return _grect(pips) if _grect(pips).size.x > 40.0 else Rect2(), "text": "上面這排圓點是這一關的旅程：一個圓點一題，答對會亮起來。"},
				{"rect": func(): return Rect2(score_label.global_position - Vector2(44, 2), Vector2(1128 - score_label.global_position.x + 44, 52)),
				 "text": UITheme.kb("右上角是你的星塵和暫停鍵（Esc）。暫停選單裡的「操作說明」可以再看一次教學。", "右上角是你的星塵和暫停鍵。暫停選單裡的「操作說明」可以再看一次教學。")},
				{"rect": func(): return _grect(scratch._btn) if scratch else Rect2(),
				 "text": "暫停鍵左邊的筆是「計算紙」：按下去整個畫面都能手寫，寫完按「收起」就能作答（計時不會停喔）。"},
				{"text": "答錯也沒關係，我會在卡片裡給你提示，太久沒動我也會跑出來幫忙。準備好了就出發吧！"},
			]
		"type:fit":
			return [
				{"rect": side, "text": "這種題目先回答預言題，想一想參數是多少。"},
				{"rect": func(): return _grect(sliders_box) if _grect(sliders_box).size.y > 10.0 else _grect(side_card),
				 "text": "接著拖動滑桿調整參數，讓舞台上的光橋穿過所有寶石，再按按鈕點亮光橋！"},
			]
		"type:draw":
			return [
				{"rect": stg, "text": "徒手作圖：先在舞台上點出曲線經過的整數點（卡片會告訴你共有幾個）。"},
				{"rect": stg, "text": "接著用滑鼠或手指，在舞台上一筆畫出整條曲線。畫歪了可以重畫，吻合度 60 分就過關！"},
			]
		"type:cross":
			return [
				{"rect": stg, "text": "交點獵人：在舞台上先後畫出兩個函數的圖形。"},
				{"rect": side, "text": "兩條都畫對之後，在卡片裡回答它們交了幾次。"},
			]
		"type:table":
			return [{"rect": side, "text": "列表作圖：一格一格比較兩個函數的大小，找出交點在哪個區間，最後數交點。"}]
		"type:rank":
			return [{"rect": stg, "text": "幫舞台上的每一條曲線配上正確的底數：底數越大，越陡（或越平）？"}]
		"type:quadrant":
			return [{"rect": side, "text": "調整參數，讓燈塔的光只經過題目指定的象限。"}]
		"type:count":
			return [{"rect": side, "text": "先拖動滑桿完成調頻任務，看看交點個數怎麼變，最後回答範圍題。"}]
		"type:chord":
			return [{"rect": stg, "text": "先判斷圖形的凹口方向，再在舞台上連出弦，最後比大小。"}]
		"type:forge":
			return [
				{"rect": side, "text": UITheme.kb("推導題：一步一步往下做。選擇題直接點選項；填空題用卡片上的數字鍵盤，也可以用實體鍵盤打字。", "推導題：一步一步往下做。選擇題直接點選項；填空題用卡片上的數字鍵盤。")},
				{"rect": stg, "text": "每答對一步，就會寫進左邊的推導紀錄。全部做完，就是一份完整的計算過程！"},
			]
		"type:speed":
			return [{"rect": side, "text": "速算挑戰：時間內連續作答，答對越多、連對越多，分數越高！答錯會扣 5 秒喔。"}]
		"type:tune":
			return [{"rect": stg, "text": "拖動參數，看圖形怎麼變，再回答範圍題。"}]
	return []
