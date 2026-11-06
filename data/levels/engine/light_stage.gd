extends Control
## 光橋舞台：座標平面、曲線、寶石、光靈奔跑、作圖、交點、列表……（level_base.gd 的各種旅程共用）
## （從 level_base.gd 拆出來的；原本是裡面的 class Stage）
const UITheme := preload("res://data/ui/game_theme.gd")
const MathLabel := preload("res://data/ui/math_text.gd")
const Game := preload("res://data/core/game.gd")
const _BgLayer := preload("res://data/levels/engine/bg_layer.gd")
const Ambient := preload("res://data/ui/ambient.gd")

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
	if bad.is_empty() and mean > 16.0:
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
	# 5. 形狀：吻合度 60 分以上就算畫對
	if res.score < 60:
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
				{"op": "mark_below", "cap": "② x 軸上方（正的）不動，[color=#ff6b7a]x 軸下方是負的[/color]"},
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
		preload("res://data/ui/math_text.gd").draw_text(self, font, Vector2(w - 160, y0 - 8), "雷射牆  y = " + UITheme.num(ay, 2),
			HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(1, 0.5, 0.55, 0.9))

	var ax := asymptote_x()
	if (type == "fit" or type == "count" or (type == "draw" and draw_wall)) and not is_nan(ax) and ax > x_range.x and ax < x_range.y:
		var flick2 := 0.55 + 0.25 * sin(t * 9.0)
		var x0 := to_screen(Vector2(ax, 0)).x
		draw_line(Vector2(x0, 0), Vector2(x0, hh), Color(1, 0.3, 0.4, 0.12), 10.0)
		draw_dashed_line(Vector2(x0, 0), Vector2(x0, hh), Color(1, 0.35, 0.45, flick2), 2.0, 12.0)
		preload("res://data/ui/math_text.gd").draw_text(self, font, Vector2(x0 + 8, hh - 46), "雷射牆  x = " + UITheme.num(ax, 2),
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
		preload("res://data/ui/math_text.gd").draw_text(self, font, Vector2(size.x - 120, y0 - 10), "鏡子  x 軸", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15),
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

	var sp_eq: Dictionary = preload("res://data/ui/spirit_look.gd").eq_of(self)
	for tr in trails:
		if sp_eq.has("trail"):
			var rev: Array = tr.duplicate()
			rev.reverse()
			preload("res://data/ui/spirit_look.gd").draw_path_trail(self, rev.slice(0, 40), 9.0, sp_eq, t)
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
	preload("res://data/ui/math_text.gd").draw_text(self, font, lp + Vector2(12, -4), "鏡子  y = x", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(0.85, 0.9, 1.0, 0.8))

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
	var ML := preload("res://data/ui/math_text.gd")
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
		preload("res://data/ui/math_text.gd").draw_text(self, font, Vector2(cx - 30, 28), "x = %s" % x_text_s(table_xs[table_cur]),
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
	preload("res://data/ui/math_text.gd").draw_text(self, font, bot + Vector2(-50, -20), "x = " + UITheme.num(scan_x, 2),
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
	preload("res://data/ui/spirit_look.gd").draw_all(self, sp, 9.0, preload("res://data/ui/spirit_look.gd").eq_of(self), t, false)

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
		preload("res://data/ui/math_text.gd").draw_text(self, font, l1 + Vector2(-90, -10), "y = " + UITheme.num(probe_y, 2),
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
		preload("res://data/ui/math_text.gd").draw_text(self, font, bot + Vector2(-50, -10), "x = " + UITheme.num(probe_x, 2),
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
