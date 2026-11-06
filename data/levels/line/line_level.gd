extends "res://data/levels/engine/step_level.gd"
## 直線與圓（C1～C8）共用的關卡引擎：一步一步推導（step_level.gd）＋下方的坐標方格
##
## 題目（variant）可以多一個 "plane"：推導紀錄下方畫一塊坐標方格（x、y 同比例，有格線和刻度）
##   {"x": [−2, 10], "y": [−2, 8], "shapes": [...]}
##   shapes 和終焉之塔的幾何圖一樣（seg、poly、circle、dot、label、angle、right…），多一種 line（整條直線）：
##     {"k": "line", "p": [x1, y1], "q": [x2, y2]}（過兩點）或 {"k": "line", "abc": [a, b, c]}（ax + by + c = 0）
##   每個圖層都可以寫 "at"：第幾步開始出現（0 = 一開始就有）、"until"：第幾步之後消失
##
## 新的步驟（kind）：
##   grid  點選格子點：在坐標方格上點一下，放下一個點（再點別的地方可以移動），按「確定位置」
##         {"kind": "grid", "name", "q", "target": [x, y], "label": "D", "line", "nudge", "tag",
##          "traps": [[x, y, "點到這裡時的提示"], …]（可省略）, "snap": 1（格子點；0.5 = 半格）, "off": [dx, dy]（答對後標籤的位置，可省略）}
##         答對之後那一點會留在方格上
##         點選的時候可以縮放：手機雙指捏合（兩指一起移動 = 平移），電腦用滑鼠滾輪（右鍵或中鍵拖曳 = 平移），
##         放大之後右上角有「還原」
##   slide 滑桿調參數：拉動滑桿，坐標方格上的直線即時跟著動
##         {"kind": "slide", "name", "q", "line", "nudge", "tag",
##          "params": [{"n": "m", "min": −3, "max": 3, "step": 0.5, "v": 1}, …],
##          "lines": [{"abc": ["m", "-1", "k"], "c": "cyan", "s": "L"}, …]（ax + by + c = 0，係數是含參數的算式）,
##          "eq": "y = {m}x + {k}"（右邊顯示目前的方程式，{…} 裡是算式；可省略）,
##          "goal": {"m": 0.5, "k": −2}（調到這裡才算對）或 "free": true（自由觀察，拉過就可以按「看好了」）,
##          "traps": [[{"k": −2}, "調到這裡時的提示"], …], "keep": true（做完把那條線留在方格上）}
##         lines 裡也可以放會動的點和線段（拖動點）：{"k": "dot", "p": ["t", "0"], "s": "P"}、{"k": "seg", "a": ["t", "0"], "b": ["1", "1"]}
##         eq 的 {…} 可以用 sqrt、abs、pow：例如 "\\ol{PA} + \\ol{PB} ≈ {sqrt(pow(t - 1, 2) + 1) + …}"（不是分數時顯示到小數第二位）
##   grids 點出所有格子點：{"kind": "grids", "name", "q", "targets": [[x, y], …], "line", "nudge", "tag"}
##         點一下就判斷：點對的亮起來留著，點錯的熄掉（第一次點錯才扣一顆心）。全部找到就過關
##   slide 也可以畫會動的圓：lines 裡放 {"k": "circle", "o": ["h", "k"], "r": "r"}（半徑算出來是 0 畫成一點，負的或不是數字就不畫）
##         "drag": ["h", "k"]：在坐標方格上點一下或拖動，就把這兩個參數（圓心）移到那裡，滑桿跟著動（和多項式的平移一樣）
##         圓也有看得到的後果：調對了圓規轉一圈把圓畫出來，調錯了圓晃一下就散掉
##   region 點選區域：直線把方格切成好幾塊，點一下塗色、再點一次取消，按「確定」
##         {"kind": "region", "name", "q", "line", "nudge", "tag",
##          "ineq": [[a, b, c, "<="], …]（要塗的地方：每一條 ax + by + c 和 0 的關係，"<" "<=" ">" ">="）,
##          "lines": [[a, b, c], …]（切開方格的直線，省略就用 ineq 的邊界）, "names": ["2x + y ≤ 4", …]（答錯時提示用）}
##         答對之後塗色的地方留在方格上
## 交點漣漪：plane 寫 "hits": true，直線碰到圓（或圓弧 arc）的地方會濺起一圈一圈的漣漪
##   滑桿的 eq 可以寫 {#hits}：目前的交點個數。圖層寫 "nohit": true 就不算它
##   plane 再寫 "lamps": true：直線剛好和圓相切時，切點亮起一盞燈（C7 切線燈環起）
## 足跡：滑桿裡會動的點寫 "trail": true，走過的地方留下一串光點（一直留到這一題做完，C8 軌跡）
## 會動的圖層可以寫 "when": "算式"：算式成立才畫（例如 "abs(k + 1) < 0.001" 時才畫公共弦）
## 點可以寫 "hole": true：空心的點（軌跡要去掉的點）
## 不等式的圖層：
##   {"k": "region", "ineq": [[a, b, c, op], …], "c": "lime", "alpha": 0.22}  塗出聯立不等式的區域（係數也可以是含參數的算式，給滑桿用）
##   {"k": "lattice", "ineq": [[a, b, c, op], …], "c": "gold"}  區域裡的格子點
## 動畫圖層（at 那一步出現時才開始播）：
##   {"k": "path", "pts": [[x, y], …], "c", "dur": 1.5}  光線：沿著折線一段一段畫出來，最後有箭頭
##   {"k": "fold", "pts": [[x, y], …], "to": [[x, y], …], "dur": 1.2, "marks": [[從, 到], …]}  摺紙：多邊形從 pts 慢慢翻到 to，marks 的點跟著翻
## 點選區域的步驟可以加 "bloom": true：塗對了，田裡的稻子一株一株長出來；塗錯的那幾塊會枯掉（變紅褐色）。
## 看得到的後果（自動，不用在題庫寫）：
##   點選格子點：放對了，那一點像燈標一樣亮起來（光圈擴散）。放錯了，那一點閃一下就熄掉，提示說 x、y 坐標偏大還是偏小
##   滑桿：調對了，直線上一塊一塊鋪上木板（keep 的直線木板留著）、會動的點亮起來。調錯了，直線閃紅、木板掉進水裡
##   直線圖層可以寫 "from_p"、"from_q"：出現的時候從那裡滑過來（平移）
## 延後到終焉之塔的題型記在 docs/line_tower_backlog.md（每做完一關都要更新）
##
## 每一關覆寫 scene_theme()（背景，data/ui/scenery.gd）和平常的關卡資訊（level_id()…，見 step_level.gd）。

const TowerPlot := preload("res://data/levels/tower/boss_tower.gd")
const PLANE_BIG := 290.0          # 點選格子點、做完的時候：坐標方格大一點
const PLANE_SMALL := 206.0        # 其他步驟：小一點，讓上面的推導紀錄和填空放得下

var grid_tip: Label


## 這一關的背景（data/ui/scenery.gd 的主題）
func scene_theme() -> String:
	return "lakeside"


## 距離、半徑常常有根號：這一單元的填空都有「√」鍵
func radicals_ok() -> bool:
	return true


func _ensure_fview() -> void:
	if fview == null:
		var v := PlaneView.new()
		v.theme_name = scene_theme()
		fview = v
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "速算"


func _pv() -> PlaneView:
	return fview as PlaneView


# ================= 點選格子點（grid） =================

func _forge_step() -> void:
	if fview != null and _pv().plane != null:
		_pv().plane.pick_off()
		_pv().plane.region_off()
	super()
	if si < steps.size() and String(steps[si].kind) == "grid":
		_build_grid(steps[si])
	elif si < steps.size() and String(steps[si].kind) == "slide":
		_build_slide(steps[si])
	elif si < steps.size() and String(steps[si].kind) == "region":
		_build_region(steps[si])
	elif si < steps.size() and String(steps[si].kind) == "grids":
		_build_grids(steps[si])


func _build_grid(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	var lab := String(st.get("label", "P"))
	_pv().plane.pick_on(lab, float(st.get("snap", 1.0)), func(_p): _refresh_grid())
	grid_tip = Label.new()
	grid_tip.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	grid_tip.custom_minimum_size = Vector2(300, 0)
	grid_tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	grid_tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(grid_tip)
	_tip_gap()
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "確定位置"
	_refresh_grid()


func _refresh_grid() -> void:
	if grid_tip == null or not is_instance_valid(grid_tip) or si >= steps.size():
		return
	var st: Dictionary = steps[si]
	var lab := String(st.get("label", "P"))
	var p: Vector2 = _pv().plane.pick
	if not _pv().plane.has_pick():
		grid_tip.text = "在左下的坐標方格上點一下，放下 %s 點。\n（雙指或滑鼠滾輪可以放大）" % lab
	else:
		grid_tip.text = "%s 點放在 %s。\n要換位置就再點一次。" % [lab, CoordPlane.pt_text(p)]


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size() and String(steps[si].kind) == "grid":
		_grid_submit()
		return
	if r.type == "forge" and si < steps.size() and String(steps[si].kind) == "slide":
		_slide_submit()
		return
	if r.type == "forge" and si < steps.size() and String(steps[si].kind) == "region":
		_region_submit()
		return
	if r.type == "forge" and si < steps.size() and String(steps[si].kind) == "grids":
		_grids_check_done()
		return
	super()


func _grid_submit() -> void:
	var st: Dictionary = steps[si]
	var pl: CoordPlane = _pv().plane
	var lab := String(st.get("label", "P"))
	if not pl.has_pick():
		_hint("先在坐標方格上點一下，放下 %s 點。" % lab, "info")
		return
	var want := Vector2(float(st.target[0]), float(st.target[1]))
	var p: Vector2 = pl.pick
	if p.is_equal_approx(want):
		Game.of(self).sfx("correct")
		pl.add_dot(want, lab, String(st.get("c", "gold")), false, st.get("off", [8, -8]))
		pl.fx_burst(want)
		pl.pick_off()
		go_btn.visible = false
		_clear(rank_box)
		rank_box.visible = false
		_step_done(st, "")
		return
	var msg := "還不對。提示：" + String(st.nudge)
	var trapped := false
	for tr in st.get("traps", []):
		if p.is_equal_approx(Vector2(float(tr[0]), float(tr[1]))):
			msg = String(tr[2])
			trapped = true
	pl.fx_miss(p)
	if not trapped:
		# 只說方向，不說差多少（還是要自己算）
		var parts := []
		if not is_equal_approx(p.x, want.x):
			parts.append("x 坐標太%s" % ("大" if p.x > want.x else "小"))
		if not is_equal_approx(p.y, want.y):
			parts.append("y 坐標太%s" % ("大" if p.y > want.y else "小"))
		msg = "、".join(parts) + "。" + msg
	_wrong(st, "你放在 %s，燈沒有亮。%s" % [CoordPlane.pt_text(p), msg])


func _custom_reveal(msg: String) -> void:
	if fview != null and r.type == "forge" and _pv().plane != null:
		var pl: CoordPlane = _pv().plane
		pl.pick_off()
		pl.dyn = []
		for j in range(si, steps.size()):
			var st: Dictionary = steps[j]
			if String(st.kind) == "grid":
				pl.add_dot(Vector2(float(st.target[0]), float(st.target[1])), String(st.get("label", "P")), String(st.get("c", "gold")), false, st.get("off", [8, -8]))
			elif String(st.kind) == "grids":
				for tg in st.targets:
					pl.add_dot(Vector2(float(tg[0]), float(tg[1])), "", "gold", true)
			elif String(st.kind) == "region":
				pl.add_region(st.ineq, String(st.get("c", "lime")), false)
		pl.region_off()
	super(msg)


## 自動測試（tests/test_play.gd）：把這一步的答案放好，之後呼叫 _custom_go() 送出。認得的步驟回傳 true
func test_answer(st: Dictionary) -> bool:
	if String(st.kind) == "grid":
		_pv().plane.pick = Vector2(float(st.target[0]), float(st.target[1]))
		_refresh_grid()
		return true
	if String(st.kind) == "grids":
		for tg in st.targets:
			var p := Vector2(float(tg[0]), float(tg[1]))
			if not grids_found.has(p):
				grids_found.append(p)
		return true
	if String(st.kind) == "region":
		var pl: CoordPlane = _pv().plane
		pl.cell_sel = {}
		for key in region_targets(st):
			pl.cell_sel[key] = true
		pl.queue_redraw()
		return true
	if String(st.kind) == "slide":
		for k in st.get("goal", {}).keys():
			slide_vals[k] = float(st.goal[k])
		slide_moved = true
		_refresh_slide()
		return true
	return false


## 說明文字下面留一點空：右邊提示框的光靈頭像會往上凸，不要蓋到說明的第二行
func _tip_gap() -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	rank_box.add_child(gap)


# ================= 點出所有格子點（grids） =================

var grids_found: Array = []
var grids_missed := false
var grids_tip: Label


func _build_grids(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	grids_found = []
	grids_missed = false
	_pv().plane.pick_on("", 1.0, _grids_tap, "tap")
	grids_tip = Label.new()
	grids_tip.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	grids_tip.custom_minimum_size = Vector2(300, 0)
	grids_tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	grids_tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(grids_tip)
	_tip_gap()
	go_btn.visible = false
	_refresh_grids()


func _refresh_grids() -> void:
	if grids_tip == null or not is_instance_valid(grids_tip) or si >= steps.size():
		return
	var n: int = steps[si].targets.size()
	grids_tip.text = "在坐標方格上點出每一個符合的格子點。\n已經找到 %d 個。" % grids_found.size() if grids_found.size() < n else "全部找到了！"


func _grids_tap(p: Vector2) -> void:
	if si >= steps.size() or String(steps[si].kind) != "grids" or busy:
		return
	var st: Dictionary = steps[si]
	var pl: CoordPlane = _pv().plane
	pl.pick = Vector2(INF, INF)
	if grids_found.has(p):
		return
	var hit := false
	for tg in st.targets:
		if p.is_equal_approx(Vector2(float(tg[0]), float(tg[1]))):
			hit = true
	if hit:
		grids_found.append(p)
		pl.add_dot(p, "", String(st.get("c", "gold")), true)
		pl.fx_burst(p)
		Game.of(self).play("blip", 1.0 + 0.05 * grids_found.size(), -8.0)
		_refresh_grids()
		_grids_check_done()
		return
	pl.fx_miss(p)
	var msg := "%s 不符合，燈沒有亮。%s" % [CoordPlane.pt_text(p), String(st.nudge)]
	if not grids_missed:
		grids_missed = true
		_wrong(st, msg)
	else:
		Game.of(self).sfx("wrong")
		_hint(msg, "bad")


func _grids_check_done() -> void:
	var st: Dictionary = steps[si]
	if grids_found.size() < st.targets.size():
		_hint("還有 %d 個沒找到。" % (st.targets.size() - grids_found.size()), "info")
		return
	Game.of(self).sfx("correct")
	_pv().plane.pick_off()
	_clear(rank_box)
	rank_box.visible = false
	_step_done(st, "")


# ================= 點選區域（region） =================

var region_tip: Label


func _region_lines(st: Dictionary) -> Array:
	if st.has("lines"):
		return st.lines
	var out := []
	for q in st.ineq:
		out.append([q[0], q[1], q[2]])
	return out


## 這一步要塗的那幾塊（每一塊用正負號的組合當名字，例如 "+-+"）
func region_targets(st: Dictionary) -> Array:
	var pl: CoordPlane = _pv().plane
	var out := []
	for key in pl.all_cells():
		if CoordPlane.ineq_ok(st.ineq, pl.cell_rep(key), false):
			out.append(key)
	return out


func _build_region(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	_pv().plane.region_on(_region_lines(st), String(st.get("c", "lime")), func(): _refresh_region())
	region_tip = Label.new()
	region_tip.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	region_tip.custom_minimum_size = Vector2(300, 0)
	region_tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	region_tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rank_box.add_child(region_tip)
	_tip_gap()
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "確定"
	_refresh_region()


func _refresh_region() -> void:
	if region_tip == null or not is_instance_valid(region_tip):
		return
	var n: int = _pv().plane.cell_sel.size()
	if n == 0:
		region_tip.text = "在坐標方格上點一下要塗色的地方。\n再點一次可以取消。"
	else:
		region_tip.text = "塗了 %d 塊。再點一次可以取消。" % n


func _region_submit() -> void:
	var st: Dictionary = steps[si]
	var pl: CoordPlane = _pv().plane
	if pl.cell_sel.is_empty():
		_hint("先在坐標方格上點一下要塗色的地方。", "info")
		return
	var want := region_targets(st)
	var extra := []
	for key in pl.cell_sel.keys():
		if not want.has(key):
			extra.append(key)
	var missing := []
	for key in want:
		if not pl.cell_sel.has(key):
			missing.append(key)
	if extra.is_empty() and missing.is_empty():
		Game.of(self).sfx("correct")
		pl.add_region(st.ineq, String(st.get("c", "lime")), st.get("bloom", false))
		pl.region_off()
		go_btn.visible = false
		_clear(rank_box)
		rank_box.visible = false
		_step_done(st, "")
		return
	var msg := "還不對。提示：" + String(st.nudge)
	var names: Array = st.get("names", [])
	if not extra.is_empty():
		# 塗錯的那一塊不符合哪一個條件
		var p: Vector2 = pl.cell_rep(extra[0])
		for i in st.ineq.size():
			if not CoordPlane.ineq_ok([st.ineq[i]], p, false):
				msg = "有一塊不符合「%s」。代一個那裡的點進去看看。" % names[i] if i < names.size() else "有一塊塗錯了。提示：" + String(st.nudge)
				break
	elif not missing.is_empty():
		msg = "還有符合條件的地方沒有塗到。"
	if st.get("bloom", false) and not extra.is_empty():
		pl.wither(extra)
		msg = "塗錯的田枯掉了！" + msg
	_wrong(st, msg)


# ================= 滑桿調參數（slide） =================

var slide_vals := {}
var slide_moved := false
var slide_eq: Control
var slide_val_labels := {}
var slide_sliders := {}


func _build_slide(st: Dictionary) -> void:
	_clear(predict_box)
	predicting = false
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = st.q
	slide_vals = {}
	slide_val_labels = {}
	slide_sliders = {}
	slide_moved = false
	for p in st.params:
		slide_vals[String(p.n)] = float(p.v)
	var col := step_color()
	if st.has("eq"):
		slide_eq = _wrap_label(18, UITheme.ACCENT)
		slide_eq.max_width = 320
		rank_box.add_child(slide_eq)
	else:
		slide_eq = null
	for p in st.params:
		var nm := String(p.n)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		rank_box.add_child(row)
		var nl = _wrap_label(18, col)
		nl.max_width = 28
		nl.text = nm
		nl.custom_minimum_size = Vector2(22, 0)
		row.add_child(nl)
		var s := UITheme.touch_slider()
		s.min_value = float(p.min)
		s.max_value = float(p.max)
		s.step = float(p.step)
		s.value = float(p.v)
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.custom_minimum_size = Vector2(0, 28)
		UITheme.tint_slider(s, col)
		row.add_child(s)
		UITheme.add_step_buttons(s, col)
		var vl = _wrap_label(17, col)
		vl.max_width = 64
		vl.custom_minimum_size = Vector2(64, 0)
		row.add_child(vl)
		slide_val_labels[nm] = vl
		slide_sliders[nm] = s
		s.value_changed.connect(func(v: float):
			slide_vals[nm] = v
			slide_moved = true
			_refresh_slide())
	go_btn.visible = true
	go_btn.disabled = false
	go_btn.text = "看好了" if st.get("free", false) else "確定"
	_pv().plane.dyn = st.get("lines", [])
	_pv().plane.dyn_vals = slide_vals
	if st.has("drag"):
		var ps: Dictionary = {}
		for p in st.params:
			ps[String(p.n)] = p
		var hx := String(st.drag[0])
		var hy := String(st.drag[1])
		_pv().plane.pick_on("", minf(float(ps[hx].step), float(ps[hy].step)), func(w: Vector2):
			for pair in [[hx, w.x], [hy, w.y]]:
				var p: Dictionary = ps[pair[0]]
				var v: float = clampf(snappedf(float(pair[1]), float(p.step)), float(p.min), float(p.max))
				slide_vals[pair[0]] = v
				if slide_sliders.has(pair[0]) and is_instance_valid(slide_sliders[pair[0]]):
					(slide_sliders[pair[0]] as HSlider).set_value_no_signal(v)
			slide_moved = true
			_refresh_slide(), "drag")
	_refresh_slide()


func _refresh_slide() -> void:
	if si >= steps.size():
		return
	var st: Dictionary = steps[si]
	for nm in slide_val_labels.keys():
		var vl = slide_val_labels[nm]
		if is_instance_valid(vl):
			vl.text = "= " + CoordPlane.frac(float(slide_vals.get(nm, 0.0)))
	_pv().plane.dyn_vals = slide_vals
	_pv().plane.record_trails()
	if slide_eq != null and is_instance_valid(slide_eq):
		var tpl := String(st.eq)
		if tpl.contains("{#hits}"):
			tpl = tpl.replace("{#hits}", str(_pv().plane.hit_points().size()))
		slide_eq.text = CoordPlane.fill_eq(tpl, slide_vals)
	_pv().plane.queue_redraw()


func _slide_submit() -> void:
	var st: Dictionary = steps[si]
	if st.get("free", false):
		if not slide_moved:
			_hint("先拉動滑桿，看看圖會怎麼變。", "info")
			return
		_slide_done(st)
		return
	var goal: Dictionary = st.get("goal", {})
	var ok := true
	for k in goal.keys():
		if absf(float(slide_vals.get(k, INF)) - float(goal[k])) > 1e-6:
			ok = false
	if ok:
		_slide_done(st)
		return
	var msg := "還不對。提示：" + String(st.nudge)
	for tr in st.get("traps", []):
		var hit := true
		for k in (tr[0] as Dictionary).keys():
			if absf(float(slide_vals.get(k, INF)) - float(tr[0][k])) > 1e-6:
				hit = false
		if hit:
			msg = String(tr[1])
	var pl: CoordPlane = _pv().plane
	for ln in st.get("lines", []):
		var sh := pl.eval_line(ln, slide_vals)
		if sh.is_empty():
			continue
		if String(sh.k) == "line":
			pl.fx_fall(sh)
		elif String(sh.k) == "circle":
			pl.fx_wobble(sh)
		elif String(sh.k) == "dot":
			pl.fx_miss(pl._v(sh.p))
	_wrong(st, msg)


func _slide_done(st: Dictionary) -> void:
	Game.of(self).sfx("correct")
	var pl: CoordPlane = _pv().plane
	var keep: bool = st.get("keep", false)
	_fill_trails(st)
	for ln in st.get("lines", []):
		var sh := pl.eval_line(ln, slide_vals)
		if sh.is_empty():
			continue
		if String(sh.k) == "line":
			if keep:
				pl.kept.append(sh)
			if not st.get("free", false):
				pl.fx_lay(sh, keep)
		elif String(sh.k) == "circle":
			if not st.get("free", false):
				pl.fx_sweep(sh, keep)
			elif keep:
				pl.kept.append(sh)
		elif String(sh.k) == "dot" and not st.get("free", false):
			pl.fx_burst(pl._v(sh.p))
	pl.dyn = []
	pl.pick_off()
	go_btn.visible = false
	_clear(rank_box)
	rank_box.visible = false
	_step_done(st, "")


## 足跡：只有一條滑桿時，做完把整段範圍走一遍，足跡連成完整的圖形（沒拉滿也看得到軌跡的樣子）
func _fill_trails(st: Dictionary) -> void:
	if st.params.size() != 1:
		return
	var has_trail := false
	for ln in st.get("lines", []):
		if ln is Dictionary and ln.get("trail", false):
			has_trail = true
	if not has_trail:
		return
	var pl: CoordPlane = _pv().plane
	var p: Dictionary = st.params[0]
	var nm := String(p.n)
	var keep_v: float = slide_vals.get(nm, float(p.v))
	var stp := maxf(float(p.step), 1e-3)
	var n := int(round((float(p.max) - float(p.min)) / stp))
	for i in n + 1:
		slide_vals[nm] = float(p.min) + stp * i
		pl.dyn_vals = slide_vals
		pl.record_trails()
	slide_vals[nm] = keep_v
	pl.dyn_vals = slide_vals


# ================= 畫面：推導紀錄＋坐標方格 =================

class PlaneView extends ForgeView:
	var plane: CoordPlane
	var theme_name := "lakeside"

	func setup(round: Dictionary) -> void:
		super(round)
		var pd: Dictionary = round.get("plane", {})
		if plane == null:
			plane = CoordPlane.new()
			add_child(plane)
		plane.reset(pd)
		plane.visible = not pd.is_empty() and kind == "forge"
		ph = PLANE_BIG if _want_big() else PLANE_SMALL
		_place_plane()

	var ph := PLANE_SMALL          # 目前的高度（大小之間慢慢變）

	## 這一步要不要大張的坐標方格（點選格子點、全部做完）
	func _want_big() -> bool:
		var sts: Array = rd.get("steps", [])
		return done or step >= sts.size() or String(sts[step].get("kind", "")) in ["grid", "slide", "region", "grids"]

	## 左下角留給光靈和對話框
	func _plane_rect() -> Rect2:
		return Rect2(92, size.y - ph - 12.0, size.x - 116, ph)

	func _place_plane() -> void:
		if plane == null:
			return
		var rc := _plane_rect()
		plane.position = rc.position
		plane.size = rc.size

	func _process(delta: float) -> void:
		super(delta)
		if plane != null and plane.visible:
			var want := PLANE_BIG if _want_big() else PLANE_SMALL
			if absf(ph - want) > 0.5:
				ph = lerpf(ph, want, 1.0 - exp(-10.0 * delta))
				if absf(ph - want) <= 0.5:
					ph = want
				queue_redraw()
			if plane.size != _plane_rect().size or plane.position != _plane_rect().position:
				_place_plane()
			if plane.stage != step:
				plane.stage = step

	func _plane_on() -> bool:
		return plane != null and plane.visible

	func _bottom_limit() -> float:
		if _plane_on():
			return size.y - ph - 22.0
		return super()

	## 空的一行不寫進推導紀錄（直接挑戰做完時，答案已經在補上的步驟裡）
	func push_line(text: String) -> void:
		if text == "":
			return
		super(text)

	func _draw_forge_bg() -> void:
		Scenery.paint(self, theme_name, size, t)
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))


## 坐標方格：終焉之塔的幾何圖（x、y 同比例）＋格線、坐標軸、刻度，可以點選格子點
class CoordPlane extends TowerPlot.Plot:
	const SnapCol := Color(1.0, 0.86, 0.42)

	var dots: Array = []                 # 答對之後留下的點：{p, s, c}
	var dyn: Array = []                  # 滑桿步驟：跟著參數動的直線 {"abc": [算式…], "c", "s"}
	var dyn_vals := {}
	var kept: Array = []                 # 滑桿步驟做完留下來的直線（已經算好的 line 圖層）
	var kept_regions: Array = []         # 點選區域做完留下來的塗色（region 圖層）
	var trail_pts: Array = []            # 足跡：會動的點走過的位置 [Vector2, 顏色名稱]
	var cells_on := false                # 點選區域的步驟
	var cell_lines: Array = []           # 切開方格的直線 [a, b, c]
	var cell_sel := {}                   # 塗了哪幾塊（正負號的組合 → true）
	var cell_col := "lime"
	var withered := {}                   # 塗錯、枯掉的那幾塊 → 枯掉的時間
	var _on_cell := Callable()
	var _anim0 := {}                     # 動畫圖層第一次出現的時間（path、fold）
	var fx: Array = []                   # 看得到的後果：{"k": burst／miss／lay／fall, "t0", …}
	var pick := Vector2(INF, INF)        # 正在放的點（INF：還沒放）
	var picking := false
	var pick_label := "P"
	var pick_mode := "point"             # point：放一個點，tap：點一下就判斷（點出所有格子點），drag：拖動參數（圓心）
	var snap := 1.0
	var _on_pick := Callable()

	# ---------- 縮放、平移（只在點選格子點的時候） ----------
	const ZOOM_MAX := 3.0
	var zoom := 1.0
	var pan := Vector2.ZERO              # 視野中心偏移了多少（坐標單位）
	var _touches := {}                   # 手指編號 → 位置
	var _pinch_d := 0.0                  # 雙指一開始的距離、中點
	var _pinch_c := Vector2.ZERO
	var _pinched := false                # 這次手指放下之後有沒有捏合過（捏合中的手指不能拿來放點）
	var _pick_before := Vector2(INF, INF)

	func reset(d: Dictionary) -> void:
		data = d.duplicate(true)
		data["geo"] = true
		data["axes"] = false            # 坐標軸自己畫（有刻度）
		if not data.has("x"):
			data["x"] = [-5, 5]
			data["y"] = [-5, 5]
		dots = []
		dyn = []
		kept = []
		kept_regions = []
		trail_pts = []
		region_off()
		_anim0 = {}
		fx = []
		_cache = {}
		stage = 0
		pick_off()
		reset_view()

	func pick_on(label: String, sn: float, cb: Callable, mode := "point") -> void:
		picking = true
		pick_mode = mode
		pick_label = label
		snap = sn if sn > 0.0 else 1.0
		pick = Vector2(INF, INF)
		_on_pick = cb
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		queue_redraw()

	func pick_off() -> void:
		picking = false
		_touches = {}
		_pinched = false
		zoom = 1.0
		pan = Vector2.ZERO
		pick = Vector2(INF, INF)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		queue_redraw()

	# ---------- 點選區域 ----------

	func region_on(lines: Array, col: String, cb: Callable) -> void:
		pick_on("", 1.0, func(_p): pass)
		withered = {}
		cells_on = true
		cell_lines = lines
		cell_sel = {}
		cell_col = col
		_on_cell = cb

	## 留在方格上的塗色（bloom：稻子一株一株長出來）
	func add_region(ineq: Array, col: String, bloom: bool) -> void:
		var rg := {"k": "region", "ineq": ineq, "c": col}
		if bloom:
			rg["bloom_t"] = t
		kept_regions.append(rg)
		queue_redraw()

	## 塗錯的幾塊：枯掉（紅褐色，慢慢淡掉），選取也取消
	func wither(keys: Array) -> void:
		for k in keys:
			withered[k] = t
			cell_sel.erase(k)
		if _on_cell.is_valid():
			_on_cell.call()
		queue_redraw()

	func region_off() -> void:
		cells_on = false
		cell_sel = {}
		cell_lines = []
		_on_cell = Callable()

	## p 在哪一塊（每一條直線代入的正負號，在線上的話含 "0"）
	func cell_key(p: Vector2) -> String:
		var k := ""
		for l in cell_lines:
			var v := float(l[0]) * p.x + float(l[1]) * p.y + float(l[2])
			k += "0" if absf(v) < 1e-6 else ("+" if v > 0.0 else "-")
		return k

	## 畫面上看得到的每一塊（在方格上取樣）
	func all_cells() -> Array:
		var out := []
		var wr := _frame_world()
		for i in 49:
			for j in 31:
				var p := wr.position + Vector2(wr.size.x * (i + 0.5) / 49.0, wr.size.y * (j + 0.5) / 31.0)
				var k := cell_key(p)
				if not k.contains("0") and not out.has(k):
					out.append(k)
		return out

	## 題目的範圍（不含下面光靈對話框那一條）換成坐標
	func _frame_world() -> Rect2:
		var f := _frame()
		var a := from_px(Vector2(f.position.x, f.end.y))
		var b := from_px(Vector2(f.end.x, f.position.y))
		return Rect2(a, b - a)

	## 一塊在畫面上的多邊形（坐標），rect 是要裁切的範圍
	func cell_poly(key: String, rect: Rect2) -> PackedVector2Array:
		var poly := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
		for i in cell_lines.size():
			var l: Array = cell_lines[i]
			var sg := 1.0 if key[i] == "+" else -1.0
			poly = clip_half(poly, float(l[0]) * sg, float(l[1]) * sg, float(l[2]) * sg)
		return poly

	## 這一塊的代表點（看得到的範圍裡、多邊形的中心）
	func cell_rep(key: String) -> Vector2:
		var poly := cell_poly(key, _frame_world())
		if poly.is_empty():
			return Vector2(INF, INF)
		var c := Vector2.ZERO
		for p in poly:
			c += p
		return c / poly.size()

	## 多邊形和半平面 ax + by + c ≥ 0 的交集（Sutherland–Hodgman）
	static func clip_half(poly: PackedVector2Array, a: float, b: float, c: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		var n := poly.size()
		for i in n:
			var p := poly[i]
			var q := poly[(i + 1) % n]
			var vp := a * p.x + b * p.y + c
			var vq := a * q.x + b * q.y + c
			if vp >= 0.0:
				out.append(p)
			if (vp >= 0.0) != (vq >= 0.0):
				out.append(p.lerp(q, vp / (vp - vq)))
		return out

	## p 符不符合這些不等式（strict = true：在邊界上要看等號）
	static func ineq_ok(ineq: Array, p: Vector2, strict: bool) -> bool:
		for q in ineq:
			var v := float(q[0]) * p.x + float(q[1]) * p.y + float(q[2])
			match String(q[3]):
				"<":
					if v >= (0.0 if strict else 1e-9):
						return false
				"<=":
					if v > 1e-9:
						return false
				">":
					if v <= (0.0 if strict else -1e-9):
						return false
				">=":
					if v < -1e-9:
						return false
		return true

	## 聯立不等式的區域（畫在畫面範圍裡）
	func region_poly(ineq: Array) -> PackedVector2Array:
		var wr := _world()
		var poly := PackedVector2Array([wr.position, Vector2(wr.end.x, wr.position.y), wr.end, Vector2(wr.position.x, wr.end.y)])
		for q in ineq:
			var sg := 1.0 if String(q[3]).begins_with(">") else -1.0
			poly = clip_half(poly, float(q[0]) * sg, float(q[1]) * sg, float(q[2]) * sg)
		return poly

	## 稻子：區域裡每個格子點長一小叢（k：長到多高 0～1，dead：枯掉、倒下來）
	func _draw_stalks(poly: PackedVector2Array, col: Color, k: float, dead: bool) -> void:
		if poly.size() < 3:
			return
		var bb := Rect2(poly[0], Vector2.ZERO)
		for p in poly:
			bb = bb.expand(p)
		var stp := 1.0 if _unit() > 22.0 else 2.0
		var x := ceilf(bb.position.x / stp) * stp + stp * 0.5
		while x < bb.end.x:
			var y := ceilf(bb.position.y / stp) * stp + stp * 0.5
			while y < bb.end.y:
				var wp := Vector2(x, y)
				if Geometry2D.is_point_in_polygon(wp, poly):
					var sp := _to(wp)
					var delay := fposmod(x * 0.37 + y * 0.61, 1.0) * 0.4
					var kk := clampf((k - delay) / 0.6, 0.0, 1.0)
					if kk > 0.0:
						var ht := 9.0 * kk
						var sway := 1.2 * sin(t * 1.8 + x * 1.3 + y)
						for lean in [-0.45, 0.0, 0.45]:
							var tip := sp + Vector2(lean * ht + sway, -ht * (1.0 - absf(lean) * 0.3))
							if dead:
								tip = sp + Vector2(lean * 4.0 + 4.0, -2.0)
							draw_line(sp, tip, Color(0.5, 0.7, 0.35, 0.55 * col.a) if not dead else col, 1.1, true)
							if not dead:
								UITheme.dot(self, tip, 1.6 * kk, Color(col.r, col.g, col.b, 0.75 * col.a))
				y += stp
			x += stp

	func _fill_world(poly: PackedVector2Array, col: Color) -> void:
		if poly.size() < 3:
			return
		var sp := PackedVector2Array()
		for p in poly:
			sp.append(_to(p))
		draw_colored_polygon(sp, col)

	func reset_view() -> void:
		zoom = 1.0
		pan = Vector2.ZERO
		queue_redraw()

	## 以畫面上的 sp 為中心縮放 f 倍（放大後的視野不會跑出原本的範圍）
	func zoom_at(sp: Vector2, f: float) -> void:
		var before := from_px(sp)
		zoom = clampf(zoom * f, 1.0, ZOOM_MAX)
		pan += before - from_px(sp)
		_clamp_pan()
		queue_redraw()

	func pan_px(d: Vector2) -> void:
		pan -= Vector2(d.x, -d.y) / _scale()
		_clamp_pan()
		queue_redraw()

	func _clamp_pan() -> void:
		var half := _frame().size / (_base_scale() * 2.0)
		var k := 1.0 - 1.0 / zoom
		pan = Vector2(clampf(pan.x, -half.x * k, half.x * k), clampf(pan.y, -half.y * k, half.y * k))

	## 放大之後右上角的「還原」按鈕
	func _reset_rect() -> Rect2:
		return Rect2(size.x - 62.0, 8.0, 54.0, 26.0)

	func has_pick() -> bool:
		return is_finite(pick.x) and is_finite(pick.y)

	func add_dot(p: Vector2, s: String, c := "gold", bare := false, off = [8, -8]) -> void:
		for d in dots:
			if (d.p as Vector2).is_equal_approx(p) and String(d.s) == s:
				return
		dots.append({"p": p, "s": s, "c": c, "bare": bare, "off": off})
		queue_redraw()

	## 足跡：把會動的點（"trail": true）現在的位置記下來
	func record_trails() -> void:
		for ln in dyn:
			if not ln.get("trail", false):
				continue
			var e := eval_line(ln, dyn_vals)
			if e.is_empty() or String(e.k) != "dot":
				continue
			var q := _v(e.p)
			if not (is_finite(q.x) and is_finite(q.y)):
				continue
			var dup := false
			for tp in trail_pts:
				if (tp[0] as Vector2).distance_to(q) < 1e-3:
					dup = true
					break
			if not dup:
				trail_pts.append([q, String(ln.get("c", "gold"))])

	## 含參數的直線 → 算好係數的 line 圖層（a、b 都是 0 時回傳空的）
	func eval_line(ln: Dictionary, vals: Dictionary) -> Dictionary:
		var kk := String(ln.get("k", "line"))
		if ln.has("when") and absf(calc(String(ln.when), vals)) < 0.5:
			return {}
		if kk == "region":
			var out := ln.duplicate()
			var iq := []
			for q in ln.ineq:
				iq.append([calc(str(q[0]), vals), calc(str(q[1]), vals), calc(str(q[2]), vals), q[3]])
			out["ineq"] = iq
			out.erase("at")
			return out
		if kk == "circle":
			var o := [calc(str(ln.o[0]), vals), calc(str(ln.o[1]), vals)]
			var rr := calc(str(ln.r), vals)
			if not is_finite(rr) or rr < -1e-9 or not is_finite(o[0]) or not is_finite(o[1]):
				return {}
			if rr < 1e-6:
				return {"k": "dot", "p": o, "c": String(ln.get("c", "cyan")), "s": ""}
			var oc := ln.duplicate()
			oc["o"] = o
			oc["r"] = rr
			oc.erase("at")
			return oc
		if kk == "dot" or kk == "seg":
			var out := ln.duplicate()
			for key in ["p", "a", "b"]:
				if ln.has(key):
					out[key] = [calc(str(ln[key][0]), vals), calc(str(ln[key][1]), vals)]
			out.erase("at")
			return out
		var abc := []
		for e in ln.abc:
			abc.append(calc(String(e), vals))
		for v in abc:
			if not is_finite(v):
				return {}
		if absf(abc[0]) < 1e-9 and absf(abc[1]) < 1e-9:
			return {}
		var sh := {"k": "line", "abc": abc, "c": String(ln.get("c", "cyan")), "s": String(ln.get("s", "")), "w": float(ln.get("w", 2.5))}
		if ln.has("dash"):
			sh["dash"] = ln.dash
		return sh

	## 算式（可以用參數名稱）→ 數值
	static func calc(e: String, vals: Dictionary) -> float:
		var ex := Expression.new()
		var names := PackedStringArray(vals.keys())
		if ex.parse(e, names) != OK:
			return 0.0
		var v = ex.execute(vals.values())
		if ex.has_execute_failed():
			return 0.0
		if v is bool:
			return 1.0 if v else 0.0
		return float(v) if (v is float or v is int) else 0.0

	## 分數的寫法：0.5 → \\frac{1}{2}、−1.5 → −\\frac{3}{2}
	static func frac(v: float) -> String:
		if not is_finite(v):
			return "—"
		for d in range(1, 13):
			var n := v * d
			if absf(n - roundf(n)) < 1e-6:
				var ni := int(roundf(n))
				if d == 1:
					return num(ni)
				return ("−" if ni < 0 else "") + "\\frac{%d}{%d}" % [absi(ni), d]
		return num(v)

	## "y = {m}x + {k}" 把 {…} 換成數值：「+ −2」寫成「− 2」，x、y 前面的係數 1 不寫
	static func fill_eq(tpl: String, vals: Dictionary) -> String:
		var out := ""
		var i := 0
		while i < tpl.length():
			var ch := tpl[i]
			# 排版用的大括號（\ol{PA}、\frac{1}{2}、m_{AB}、x^{2}）照抄，前面是字母、_、^、} 的都是
			var prev := tpl[i - 1] if i > 0 else ""
			var lit := prev != "" and (prev == "_" or prev == "^" or prev == "}" or (prev.to_lower() != prev.to_upper() and prev.unicode_at(0) < 128))
			if ch != "{" or lit:
				if ch == "{" and lit:
					var j0 := tpl.find("}", i)
					out += tpl.substr(i, j0 - i + 1)
					i = j0 + 1
					continue
				out += ch
				i += 1
				continue
			var j := tpl.find("}", i)
			var v := calc(tpl.substr(i + 1, j - i - 1), vals)
			i = j + 1
			var nxt := tpl[i] if i < tpl.length() else ""
			var coef := nxt == "x" or nxt == "y"
			if out.ends_with("+ ") and v < -1e-9:
				out = out.substr(0, out.length() - 2) + "− "
				v = -v
			elif out.ends_with("− ") and v < -1e-9:
				out = out.substr(0, out.length() - 2) + "+ "
				v = -v
			# 係數是 0：整項不寫（例如 0y、+ 0）
			if absf(v) < 1e-9 and (coef or out.ends_with("+ ") or out.ends_with("− ")):
				if out.ends_with("+ ") or out.ends_with("− "):
					out = out.substr(0, out.length() - 2).rstrip(" ")
				if coef:
					i += 1
				continue
			if coef and absf(v - 1.0) < 1e-9:
				continue
			if coef and absf(v + 1.0) < 1e-9:
				out += "−"
				continue
			out += frac(v)
		# 圓心在原點：(x)^{2} 寫成 x^{2}
		out = out.replace("(x)^{2}", "x^{2}").replace("(y)^{2}", "y^{2}")
		# 第一項被省掉時，開頭的「+ 」「− 」整理一下
		var re := RegEx.new()
		re.compile("(^|：|= |\\n) ?\\+ ")
		out = re.sub(out, "$1", true)
		re.compile("(^|：|= |\\n) ?− ")
		out = re.sub(out, "$1−", true)
		return out

	## (3, −2) 這種寫法（負號用 −）
	static func pt_text(p: Vector2) -> String:
		return "(%s, %s)" % [num(p.x), num(p.y)]

	static func num(v: float) -> String:
		var r := snappedf(v, 0.01)
		var s := str(int(round(r))) if is_equal_approx(r, round(r)) else str(r)
		return s.replace("-", "−")

	# ---------- 坐標換算 ----------

	## 題目的範圍（data.x、data.y）放在這個框裡：下面留一條給左下角光靈的對話框（那裡只有格線，不放點）
	const BOTTOM_PAD := 40.0

	func _frame() -> Rect2:
		return Rect2(Vector2(10, 10), size - Vector2(20, 20 + BOTTOM_PAD))

	func _base_scale() -> float:
		var xr: Array = data.x
		var yr: Array = data.y
		var r := _frame()
		return minf(r.size.x / (float(xr[1]) - float(xr[0])), r.size.y / (float(yr[1]) - float(yr[0])))

	func _scale() -> float:
		return _base_scale() * zoom

	## 視野中心的坐標
	func _mid() -> Vector2:
		var xr: Array = data.x
		var yr: Array = data.y
		return Vector2((float(xr[0]) + float(xr[1])) / 2.0, (float(yr[0]) + float(yr[1])) / 2.0) + pan

	func _to(p: Vector2) -> Vector2:
		var sc := _scale()
		var c := _frame().get_center()
		var m := _mid()
		return Vector2(c.x + (p.x - m.x) * sc, c.y - (p.y - m.y) * sc)

	## 畫面上的位置 → 坐標
	func from_px(sp: Vector2) -> Vector2:
		var sc := _scale()
		var c := _frame().get_center()
		var m := _mid()
		return Vector2((sp.x - c.x) / sc + m.x, -(sp.y - c.y) / sc + m.y)

	## 畫面上看得到的坐標範圍（比 data.x、data.y 大一點，因為兩軸同比例）
	func _world() -> Rect2:
		var a := from_px(Vector2(0, size.y))
		var b := from_px(Vector2(size.x, 0))
		return Rect2(a, b - a)

	# ---------- 點選 ----------

	func _gui_input(e: InputEvent) -> void:
		if not picking:
			return
		if _view_input(e):
			accept_event()
			return
		# 捏合中（或剛捏合完、手指還沒全部放開）：不放點
		if _pinched or _touches.size() >= 2:
			return
		if cells_on:
			# 點選區域：點一下切換那一塊（在線上不算）
			if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
				var key := cell_key(from_px(e.position))
				if not key.contains("0"):
					if cell_sel.has(key):
						cell_sel.erase(key)
					else:
						cell_sel[key] = true
					queue_redraw()
					if _on_cell.is_valid():
						_on_cell.call()
				accept_event()
			return
		var press: bool = e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed
		if press:
			_pick_before = pick
		var drag: bool = e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		if pick_mode == "tap":
			drag = false
		if not (press or drag):
			return
		var w := from_px(e.position)
		var wr := _world()
		var p := Vector2(snappedf(w.x, snap), snappedf(w.y, snap))
		p.x = clampf(p.x, ceilf(wr.position.x / snap) * snap, floorf(wr.end.x / snap) * snap)
		p.y = clampf(p.y, ceilf(wr.position.y / snap) * snap, floorf(wr.end.y / snap) * snap)
		if pick_mode == "tap" or not has_pick() or not p.is_equal_approx(pick):
			pick = p
			queue_redraw()
			if _on_pick.is_valid():
				_on_pick.call(p)
		accept_event()

	## 縮放、平移、還原。處理掉了就回傳 true
	func _view_input(e: InputEvent) -> bool:
		if e is InputEventMouseButton and e.pressed:
			if e.button_index == MOUSE_BUTTON_LEFT and zoom > 1.001 and _reset_rect().has_point(e.position):
				reset_view()
				return true
			if e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				var f := 1.15 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15
				zoom_at(e.position, pow(f, maxf(e.factor, 1.0)) if e.factor > 0.0 else f)
				return true
			if e.button_index == MOUSE_BUTTON_RIGHT or e.button_index == MOUSE_BUTTON_MIDDLE:
				return true
		if e is InputEventMouseMotion and (e.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)) != 0:
			pan_px(e.relative)
			return true
		if e is InputEventMagnifyGesture:
			zoom_at(e.position, e.factor)
			return true
		if e is InputEventPanGesture:
			pan_px(-e.delta * 8.0)
			return true
		if e is InputEventScreenTouch:
			if e.pressed:
				if _touches.is_empty():
					_pinched = false
				_touches[e.index] = e.position
			else:
				_touches.erase(e.index)
				if _touches.is_empty():
					_pinched = false
			if _touches.size() >= 2:
				# 第二根手指放下：第一根手指剛剛放的點不算，改成捏合
				if not _pinched:
					_pinched = true
					if pick != _pick_before:
						pick = _pick_before
						if _on_pick.is_valid():
							_on_pick.call(pick)
				_pinch_start()
			return _pinched
		if e is InputEventScreenDrag:
			_touches[e.index] = e.position
			if _touches.size() >= 2:
				var ks: Array = _touches.keys()
				var a: Vector2 = _touches[ks[0]]
				var b: Vector2 = _touches[ks[1]]
				var d := a.distance_to(b)
				var c := (a + b) / 2.0
				if _pinch_d > 1.0:
					zoom_at(c, d / _pinch_d)
				pan_px(c - _pinch_c)
				_pinch_d = d
				_pinch_c = c
				return true
			return _pinched
		return false

	func _pinch_start() -> void:
		var ks: Array = _touches.keys()
		var a: Vector2 = _touches[ks[0]]
		var b: Vector2 = _touches[ks[1]]
		_pinch_d = a.distance_to(b)
		_pinch_c = (a + b) / 2.0

	# ---------- 繪圖 ----------

	func _draw_geo(font: Font) -> void:
		_draw_grid(font)
		# 塗色在最下面（直線、點畫在上面）
		for rg in kept_regions:
			var c := _col(String(rg.get("c", "lime")))
			_fill_world(region_poly(rg.ineq), Color(c.r, c.g, c.b, 0.2))
			if rg.has("bloom_t"):
				var k := clampf((t - float(rg.bloom_t)) / 1.4, 0.0, 1.0)
				_draw_stalks(region_poly(rg.ineq), Color(1.0, 0.85, 0.45, 0.9), k, false)
		for ln in dyn:
			if String(ln.get("k", "")) == "region":
				var rg := eval_line(ln, dyn_vals)
				var c := _col(String(rg.get("c", "lime")))
				_fill_world(region_poly(rg.ineq), Color(c.r, c.g, c.b, float(rg.get("alpha", 0.24))))
		if cells_on:
			var c := _col(cell_col)
			var wr := _world()
			for key in cell_sel.keys():
				_fill_world(cell_poly(key, wr), Color(c.r, c.g, c.b, 0.3 + 0.06 * sin(t * 3.0)))
			for key in withered.keys():
				var age := t - float(withered[key])
				if age > 2.2:
					continue
				var fa := clampf(1.0 - age / 2.2, 0.0, 1.0)
				_fill_world(cell_poly(key, wr), Color(0.55, 0.25, 0.15, 0.45 * fa))
				_draw_stalks(cell_poly(key, wr), Color(0.6, 0.35, 0.2, 0.8 * fa), 1.0, true)
		super(font)
		_draw_trails()
		for ln in kept:
			_shape(ln, Vector2.ZERO, 0.0, font)
		for ln in dyn:
			if String(ln.get("k", "")) == "region":
				continue
			var sh := eval_line(ln, dyn_vals)
			if not sh.is_empty():
				_shape(sh, Vector2.ZERO, 0.0, font)
		for d in dots:
			_shape({"k": "dot", "p": [d.p.x, d.p.y], "s": "" if d.get("bare", false) else "%s%s" % [d.s, pt_text(d.p)], "c": d.c,
				"off": d.get("off", [8, -8])}, Vector2.ZERO, 0.0, font)
		if picking and has_pick() and pick_mode == "point":
			_draw_pick(font)
		if bool(data.get("hits", false)):
			_draw_hits()
		_draw_fx()
		if picking:
			_draw_zoom_ui(font)

	# ---------- 交點漣漪 ----------

	## 畫面上所有直線和圓（圓弧）的交點
	func hit_points() -> Array:
		return _hits().map(func(h): return h[0])

	## 交點和它是不是切點：[[Vector2, 是切點], …]
	func _hits() -> Array:
		var lines := []
		var circs := []
		var add := func(sh: Dictionary):
			if sh.is_empty() or sh.get("nohit", false):
				return
			match String(sh.get("k", "")):
				"line":
					lines.append(sh)
				"circle", "arc":
					circs.append(sh)
		for sh in data.get("shapes", []):
			if _vis(sh):
				add.call(sh)
		for sh in kept:
			add.call(sh)
		for ln in dyn:
			if String(ln.get("k", "")) == "region":
				continue
			var e := eval_line(ln, dyn_vals)
			if not e.is_empty():
				e["nohit"] = ln.get("nohit", false)
			add.call(e)
		var out := []
		for ln in lines:
			var pd := _line_pd(ln)
			var p: Vector2 = pd[0]
			var d: Vector2 = pd[1]
			for c in circs:
				var o := _v(c.get("o", [0, 0]))
				var r := float(c.r)
				var w := p - o
				var b := d.dot(w)
				var disc := b * b - (w.length_squared() - r * r)
				var pts := []
				var tangent := absf(disc) < 1e-6 * maxf(r * r, 1.0)
				if tangent:
					pts.append(p - d * b)
				elif disc > 0.0:
					var sq := sqrt(disc)
					pts.append(p + d * (-b + sq))
					pts.append(p + d * (-b - sq))
				for q in pts:
					if String(c.k) == "arc":
						var ang := fposmod(rad_to_deg(atan2(q.y - o.y, q.x - o.x)), 360.0)
						var a0 := float(c.get("a0", 0.0))
						var a1 := float(c.get("a1", 360.0))
						if ang < a0 - 0.01 or ang > a1 + 0.01:
							if not (absf(ang - 360.0) < 0.01 and a0 < 0.01):
								continue
					var dup := false
					for e in out:
						if (e[0] as Vector2).distance_to(q) < 1e-4:
							dup = true
							if tangent:
								e[1] = true
					if not dup:
						out.append([q, tangent])
		return out

	## 直線 → [線上一點, 單位方向]
	func _line_pd(sh: Dictionary) -> Array:
		if sh.has("abc"):
			var a := float(sh.abc[0])
			var b := float(sh.abc[1])
			var c := float(sh.abc[2])
			return [Vector2(-a * c, -b * c) / (a * a + b * b), Vector2(b, -a).normalized()]
		var p := _v(sh.p)
		return [p, (_v(sh.q) - p).normalized()]

	func _draw_hits() -> void:
		var i := 0
		var lamps: bool = data.get("lamps", false)
		for h in _hits():
			var sp := _to(h[0])
			i += 1
			if lamps and h[1]:
				_draw_lamp(sp, i)
				continue
			for k in 2:
				var ph := fposmod(t * 0.8 + k * 0.5 + i * 0.17, 1.0)
				draw_arc(sp, 5.0 + 22.0 * ph, 0.0, TAU, 32, Color(0.6, 0.95, 1.0, 0.6 * (1.0 - ph)), 1.6, true)
			UITheme.dot(self, sp, 9.0, Color(0.6, 0.95, 1.0, 0.3))
			UITheme.dot(self, sp, 4.0, Color(0.85, 1.0, 1.0, 0.95))

	## 切點的燈：暖黃色的光暈、一閃一閃的光芒
	func _draw_lamp(sp: Vector2, i: int) -> void:
		var pulse := 0.5 + 0.5 * sin(t * 2.4 + i)
		UITheme.dot(self, sp, 22.0 + 4.0 * pulse, Color(1.0, 0.82, 0.4, 0.12))
		UITheme.dot(self, sp, 12.0, Color(1.0, 0.85, 0.45, 0.3))
		var rays := PackedVector2Array()
		for k in 8:
			var a := TAU * k / 8.0 + t * 0.4
			var dv := Vector2(cos(a), sin(a))
			rays.append(sp + dv * 9.0)
			rays.append(sp + dv * (15.0 + 4.0 * pulse))
		draw_multiline(rays, Color(1.0, 0.88, 0.5, 0.55), 1.4)
		UITheme.dot(self, sp, 5.0, Color(1.0, 0.95, 0.75, 1.0))

	## 足跡：走過的地方留下一串小光點
	##   一次畫完（很短的粗線段當成小光點），不然點一多 draw call 就太多
	func _draw_trails() -> void:
		if trail_pts.is_empty():
			return
		var glow := PackedVector2Array()
		var core := PackedVector2Array()
		var gc := PackedColorArray()
		var cc := PackedColorArray()
		for tp in trail_pts:
			var c := _col(String(tp[1]))
			var sp := _to(tp[0])
			glow.append(sp - Vector2(3.0, 0))
			glow.append(sp + Vector2(3.0, 0))
			gc.append(Color(c.r, c.g, c.b, 0.18))
			core.append(sp - Vector2(1.4, 0))
			core.append(sp + Vector2(1.4, 0))
			cc.append(Color(c.r, c.g, c.b, 0.9))
		draw_multiline_colors(glow, gc, 6.0)
		draw_multiline_colors(core, cc, 2.8)

	# ---------- 看得到的後果 ----------

	func fx_burst(p: Vector2) -> void:
		fx.append({"k": "burst", "t0": t, "p": p})

	func fx_miss(p: Vector2) -> void:
		fx.append({"k": "miss", "t0": t, "p": p})

	## 鋪木板：沿著直線一塊一塊鋪上去（stay：鋪好的木板留著）
	func fx_lay(sh: Dictionary, stay: bool) -> void:
		fx.append({"k": "lay", "t0": t, "sh": sh, "stay": stay})

	## 圓規畫圓：沿著圓轉一圈畫出來（stay：畫好的圓留著）
	func fx_sweep(sh: Dictionary, stay: bool) -> void:
		fx.append({"k": "sweep", "t0": t, "sh": sh, "stay": stay})

	## 圓晃一下就散掉
	func fx_wobble(sh: Dictionary) -> void:
		fx.append({"k": "wobble", "t0": t, "sh": sh})

	## 斷掉：直線閃紅，木板掉進水裡
	func fx_fall(sh: Dictionary) -> void:
		fx.append({"k": "fall", "t0": t, "sh": sh})

	## 直線在畫面範圍裡的那一段（坐標），沒有的話回傳空的
	func _visible_seg(sh: Dictionary) -> PackedVector2Array:
		var a := float(sh.abc[0]) if sh.has("abc") else 0.0
		var p: Vector2
		var d: Vector2
		if sh.has("abc"):
			var b := float(sh.abc[1])
			var c := float(sh.abc[2])
			d = Vector2(b, -a).normalized()
			p = Vector2(-a * c, -b * c) / (a * a + b * b)
		else:
			p = _v(sh.p)
			d = (_v(sh.q) - p).normalized()
		var wr := _frame_world()
		var lo := -INF
		var hi := INF
		for ax in 2:
			var pv := p.x if ax == 0 else p.y
			var dv := d.x if ax == 0 else d.y
			var mn := wr.position.x if ax == 0 else wr.position.y
			var mx := wr.end.x if ax == 0 else wr.end.y
			if absf(dv) < 1e-9:
				if pv < mn or pv > mx:
					return PackedVector2Array()
				continue
			var s1 := (mn - pv) / dv
			var s2 := (mx - pv) / dv
			lo = maxf(lo, minf(s1, s2))
			hi = minf(hi, maxf(s1, s2))
		if lo >= hi:
			return PackedVector2Array()
		return PackedVector2Array([p + d * lo, p + d * hi])

	func _draw_fx() -> void:
		var keep := []
		for e in fx:
			var age := t - float(e.t0)
			match String(e.k):
				"burst":
					if age > 1.2:
						continue
					var sp := _to(e.p)
					var k := age / 1.2
					var gc := Color(1.0, 0.86, 0.42)
					UITheme.dot(self, sp, 26.0 * (1.0 - k) + 6.0, Color(gc.r, gc.g, gc.b, 0.35 * (1.0 - k)))
					draw_arc(sp, 8.0 + 42.0 * k, 0.0, TAU, 40, Color(gc.r, gc.g, gc.b, 0.8 * (1.0 - k)), 2.5, true)
					draw_arc(sp, 4.0 + 24.0 * k, 0.0, TAU, 32, Color(1, 1, 1, 0.6 * (1.0 - k)), 1.5, true)
					for i in 8:
						var dir := Vector2.RIGHT.rotated(TAU * i / 8.0 + 0.3)
						draw_line(sp + dir * (10.0 + 20.0 * k), sp + dir * (16.0 + 30.0 * k), Color(gc.r, gc.g, gc.b, 0.7 * (1.0 - k)), 2.0, true)
				"miss":
					if age > 1.6:
						continue
					var sp := _to(e.p)
					var fl := 1.0 if age < 0.35 else clampf(1.0 - (age - 0.35) / 1.25, 0.0, 1.0)
					var blink := 0.5 + 0.5 * cos(age * 28.0) if age < 0.35 else 1.0
					var rc := Color(1.0, 0.35, 0.4, fl * blink)
					UITheme.dot(self, sp, 10.0, Color(rc.r, rc.g, rc.b, 0.25 * rc.a))
					draw_line(sp + Vector2(-6, -6), sp + Vector2(6, 6), rc, 2.5, true)
					draw_line(sp + Vector2(-6, 6), sp + Vector2(6, -6), rc, 2.5, true)
				"sweep":
					var oc := _to(_v(e.sh.o))
					var rp := float(e.sh.r) * _unit()
					var k := clampf(age / 1.0, 0.0, 1.0)
					var col := _col(String(e.sh.get("c", "cyan")))
					var fade := 1.0 if e.stay else clampf(1.0 - (age - 1.4) / 0.8, 0.0, 1.0)
					if fade <= 0.0:
						continue
					var n := maxi(8, int(96 * k))
					var pts := PackedVector2Array()
					for i in n + 1:
						var a := -PI / 2.0 + TAU * k * i / n
						pts.append(oc + Vector2(cos(a), sin(a)) * rp)
					draw_polyline(pts, Color(1.0, 0.86, 0.42, 0.25 * fade), 8.0, true)
					draw_polyline(pts, Color(col.r, col.g, col.b, 0.95 * fade), 2.6, true)
					if k < 1.0:
						# 圓規：針插在圓心，筆尖跟著畫
						var tip := pts[pts.size() - 1]
						draw_line(oc, tip, Color(1, 1, 1, 0.35), 1.5, true)
						UITheme.dot(self, oc, 4.0, Color(1, 1, 1, 0.8))
						UITheme.dot(self, tip, 9.0, Color(1.0, 0.86, 0.42, 0.4))
						UITheme.dot(self, tip, 4.0, Color(1.0, 0.95, 0.7, 1.0))
					elif age < 1.6:
						draw_arc(oc, rp, 0.0, TAU, 96, Color(1.0, 0.95, 0.7, 0.6 * (1.0 - (age - 1.0) / 0.6)), 5.0, true)
				"wobble":
					if age > 1.1:
						continue
					var oc := _to(_v(e.sh.o))
					var rp := float(e.sh.r) * _unit()
					var fl := clampf(1.0 - age / 1.1, 0.0, 1.0)
					var pts := PackedVector2Array()
					for i in 97:
						var a := TAU * i / 96.0
						var jr := rp * (1.0 + 0.06 * sin(a * 7.0 + age * 30.0) * fl) + 14.0 * age
						pts.append(oc + Vector2(cos(a), sin(a)) * jr)
					draw_polyline(pts, Color(1.0, 0.35, 0.4, 0.8 * fl), 2.5, true)
				"lay":
					var seg := _visible_seg(e.sh)
					if seg.is_empty():
						continue
					var a := _to(seg[0])
					var b := _to(seg[1])
					var L := a.distance_to(b)
					var dir := (b - a) / maxf(L, 1.0)
					var nrm := Vector2(-dir.y, dir.x)
					var n := int(L / 16.0)
					var k := clampf(age / 1.0, 0.0, 1.0)
					var fade := 1.0 if e.stay else clampf(1.0 - (age - 1.3) / 0.8, 0.0, 1.0)
					if fade <= 0.0:
						continue
					for i in n:
						var u := (i + 0.5) / n
						if u > k:
							break
						var c := a.lerp(b, u)
						var fresh := clampf((k - u) * 6.0, 0.0, 1.0)
						var al := (0.5 + 0.45 * fresh) * fade if e.stay else 0.85 * fade
						draw_line(c - nrm * 7.0, c + nrm * 7.0, Color(0.85, 0.62, 0.35, al), 4.5, true)
					if k < 1.0:
						UITheme.dot(self, a.lerp(b, k), 7.0, Color(1.0, 0.86, 0.42, 0.7))
				"fall":
					if age > 1.6:
						continue
					var seg := _visible_seg(e.sh)
					if seg.is_empty():
						continue
					var a := _to(seg[0])
					var b := _to(seg[1])
					var fl := clampf(1.0 - age / 1.0, 0.0, 1.0)
					if fl > 0.0:
						draw_line(a, b, Color(1.0, 0.3, 0.35, 0.75 * fl), 5.0, true)
					var dir := (b - a).normalized()
					var nrm := Vector2(-dir.y, dir.x)
					for i in 7:
						var u := (i + 0.5) / 7.0
						var c := a.lerp(b, u) + Vector2(sin(i * 2.3) * 8.0 * age, 220.0 * age * age)
						var rot := age * (3.0 + i)
						var hn := nrm.rotated(rot) * 8.0
						draw_line(c - hn, c + hn, Color(0.8, 0.55, 0.32, clampf(1.0 - age / 1.6, 0.0, 1.0)), 4.5, true)
			keep.append(e)
		# 鋪好留著的木板永遠保留，其他播完就丟掉
		var still := []
		for e in fx:
			if (String(e.k) == "lay" or String(e.k) == "sweep") and e.stay:
				still.append(e)
			elif keep.has(e):
				still.append(e)
		fx = still

	## 放大之後：右上角的「還原」按鈕和倍率
	func _draw_zoom_ui(font: Font) -> void:
		var fs := UITheme.fs(12)
		if zoom <= 1.001:
			return
		var rc := _reset_rect()
		draw_style_box(UITheme.boxc(Color(0.08, 0.1, 0.2, 0.92), 8, Color(SnapCol.r, SnapCol.g, SnapCol.b, 0.7), 1, 0), rc)
		var s2 := "還原"
		var w2 := font.get_string_size(s2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, rc.position + Vector2((rc.size.x - w2) / 2.0, 18.0), s2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, SnapCol)
		var z := "%.1f×" % zoom
		var wz := font.get_string_size(z, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(rc.position.x - wz - 8.0, 26.0), z, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.45))

	## 格線、坐標軸（有箭頭）、刻度數字、x、y、O
	func _draw_grid(font: Font) -> void:
		var wr := _world()
		var u := _unit()
		var tick := 1 if u >= 30.0 else (2 if u >= 15.0 else (5 if u >= 7.0 else 10))
		var fs := UITheme.fs(11)
		for ix in range(int(ceilf(wr.position.x)), int(floorf(wr.end.x)) + 1):
			var a := _to(Vector2(ix, wr.position.y))
			var b := _to(Vector2(ix, wr.end.y))
			draw_line(a, b, Color(1, 1, 1, 0.10 if ix % 5 == 0 else 0.05), 1.0)
		for iy in range(int(ceilf(wr.position.y)), int(floorf(wr.end.y)) + 1):
			var a := _to(Vector2(wr.position.x, iy))
			var b := _to(Vector2(wr.end.x, iy))
			draw_line(a, b, Color(1, 1, 1, 0.10 if iy % 5 == 0 else 0.05), 1.0)
		var ax := Color(1, 1, 1, 0.5)
		var o := _to(Vector2.ZERO)
		var has_x := wr.position.y <= 0.0 and wr.end.y >= 0.0
		var has_y := wr.position.x <= 0.0 and wr.end.x >= 0.0
		if has_x:
			var xa := _to(Vector2(wr.position.x, 0))
			var xb := _to(Vector2(wr.end.x, 0))
			draw_line(xa, xb, ax, 1.5, true)
			draw_colored_polygon(PackedVector2Array([xb, xb + Vector2(-9, -4.5), xb + Vector2(-9, 4.5)]), ax)
			draw_string(font, xb + Vector2(-14, -8), "x", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14), Color(1, 1, 1, 0.7))
			for ix in range(int(ceilf(wr.position.x)), int(floorf(wr.end.x))):
				if ix == 0 or ix % tick != 0:
					continue
				var p := _to(Vector2(ix, 0))
				draw_line(p + Vector2(0, -3), p + Vector2(0, 3), ax, 1.0)
				var s := num(ix)
				var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string(font, p + Vector2(-w / 2.0, 15), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.45))
		if has_y:
			var ya := _to(Vector2(0, wr.position.y))
			var yb := _to(Vector2(0, wr.end.y))
			draw_line(ya, yb, ax, 1.5, true)
			draw_colored_polygon(PackedVector2Array([yb, yb + Vector2(-4.5, 9), yb + Vector2(4.5, 9)]), ax)
			draw_string(font, yb + Vector2(8, 14), "y", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14), Color(1, 1, 1, 0.7))
			for iy in range(int(ceilf(wr.position.y)), int(floorf(wr.end.y))):
				if iy == 0 or iy % tick != 0:
					continue
				var p := _to(Vector2(0, iy))
				draw_line(p + Vector2(-3, 0), p + Vector2(3, 0), ax, 1.0)
				var s := num(iy)
				var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string(font, p + Vector2(-w - 6, 4), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.45))
		if has_x and has_y:
			draw_string(font, o + Vector2(-13, 14), "O", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(12), Color(1, 1, 1, 0.55))

	## 正在放的點：到兩軸的虛線、一圈一圈的光、名字和坐標
	func _draw_pick(font: Font) -> void:
		var sp := _to(pick)
		var wr := _world()
		var oy := clampf(0.0, wr.position.y, wr.end.y)
		var ox := clampf(0.0, wr.position.x, wr.end.x)
		_pl(PackedVector2Array([sp, _to(Vector2(pick.x, oy))]), Color(SnapCol.r, SnapCol.g, SnapCol.b, 0.45), 1.2, true)
		_pl(PackedVector2Array([sp, _to(Vector2(ox, pick.y))]), Color(SnapCol.r, SnapCol.g, SnapCol.b, 0.45), 1.2, true)
		var ph := fmod(t * 1.4, 1.0)
		draw_arc(sp, 8.0 + 14.0 * ph, 0.0, TAU, 32, Color(SnapCol.r, SnapCol.g, SnapCol.b, 0.6 * (1.0 - ph)), 2.0, true)
		UITheme.dot(self, sp, 9.0, Color(SnapCol.r, SnapCol.g, SnapCol.b, 0.25))
		UITheme.dot(self, sp, 5.5, SnapCol)
		_label(font, sp, "%s%s" % [pick_label, pt_text(pick)], [10, -10], SnapCol)

	## 放大之後跑到畫面外的點：名字也不要畫（原本會被夾到邊上，看起來像是別的點）
	func _label(font: Font, sp: Vector2, s: String, off, c: Color, center := false) -> void:
		if not Rect2(Vector2.ZERO, size).grow(2.0).has_point(sp):
			return
		super(font, sp, s, off, c, center)

	## 動畫圖層：從第一次出現開始算，0 → 1
	func _anim_k(sh: Dictionary) -> float:
		var key := str(sh.get("pts", [])) + str(sh.get("p", "")) + str(sh.get("q", "")) + str(sh.get("abc", "")) + String(sh.k)
		if not _anim0.has(key):
			_anim0[key] = t
		return clampf((t - float(_anim0[key])) / float(sh.get("dur", 1.4)), 0.0, 1.0)

	func _shape(sh: Dictionary, o: Vector2, rot: float, font: Font) -> void:
		if String(sh.k) == "dot" and sh.get("hole", false):
			# 空心的點（軌跡要去掉的點）
			var sp := _to(_v(sh.p))
			var hc := _col(String(sh.get("c", "text")))
			UITheme.dot(self, sp, 6.0, Color(0.04, 0.05, 0.12, 1.0))
			draw_arc(sp, 6.0, 0.0, TAU, 24, hc, 2.0, true)
			if String(sh.get("s", "")) != "":
				_label(font, sp, String(sh.s), sh.get("off", [8, -8]), hc)
			return
		if String(sh.k) == "region":
			var c := _col(String(sh.get("c", "lime")))
			_fill_world(region_poly(sh.ineq), Color(c.r, c.g, c.b, float(sh.get("alpha", 0.2))))
			return
		if String(sh.k) == "lattice":
			var c := _col(String(sh.get("c", "gold")))
			var wr := _world()
			for ix in range(int(ceilf(wr.position.x)), int(floorf(wr.end.x)) + 1):
				for iy in range(int(ceilf(wr.position.y)), int(floorf(wr.end.y)) + 1):
					if ineq_ok(sh.ineq, Vector2(ix, iy), true):
						var sp := _to(Vector2(ix, iy))
						UITheme.dot(self, sp, 7.0, Color(c.r, c.g, c.b, 0.25))
						UITheme.dot(self, sp, 3.5, c)
			return
		if String(sh.k) == "path":
			# 光線：沿著折線畫出來
			var pts: Array = sh.pts
			var total := 0.0
			for i in range(1, pts.size()):
				total += _v(pts[i]).distance_to(_v(pts[i - 1]))
			var left := total * _anim_k(sh)
			var col := _col(String(sh.get("c", "gold")))
			var drawn := PackedVector2Array([_to(_v(pts[0]))])
			var tip := _v(pts[0])
			var dir := Vector2.RIGHT
			for i in range(1, pts.size()):
				var a := _v(pts[i - 1])
				var b := _v(pts[i])
				var L := a.distance_to(b)
				if left <= 0.0:
					break
				var e := b if left >= L else a.lerp(b, left / L)
				left -= L
				drawn.append(_to(e))
				tip = e
				dir = (_to(b) - _to(a)).normalized()
			if drawn.size() > 1:
				draw_polyline(drawn, Color(col.r, col.g, col.b, 0.18), 9.0, true)
				_pl(drawn, col, 2.5, false)
			if drawn.size() > 1:
				var tp := _to(tip)
				var nrm := Vector2(-dir.y, dir.x)
				draw_colored_polygon(PackedVector2Array([tp, tp - dir * 11.0 + nrm * 5.0, tp - dir * 11.0 - nrm * 5.0]), col)
			return
		if String(sh.k) == "fold":
			# 摺紙：多邊形從 pts 翻到 to（先慢後快再慢）
			var k := _anim_k(sh)
			k = k * k * (3.0 - 2.0 * k)
			var poly := PackedVector2Array()
			for i in sh.pts.size():
				poly.append(_to(_v(sh.pts[i]).lerp(_v(sh.to[i]), k)))
			var fc := _col(String(sh.get("c", "cyan")))
			draw_colored_polygon(poly, Color(fc.r, fc.g, fc.b, 0.16 + 0.1 * sin(k * PI)))
			poly.append(poly[0])
			_pl(poly, Color(fc.r, fc.g, fc.b, 0.7), 1.5, false)
			# 紙上的點跟著翻過去
			for mk in sh.get("marks", []):
				var mp := _to(_v(mk[0]).lerp(_v(mk[1]), k))
				UITheme.dot(self, mp, 9.0, Color(fc.r, fc.g, fc.b, 0.25))
				UITheme.dot(self, mp, 4.0, fc.lightened(0.3))
			return
		if String(sh.k) == "right":
			# 直角記號：比終焉之塔的大一點（不然會被頂點的圓點蓋住）
			var cp := _to(_v(sh.p))
			var u := (_to(_v(sh.p) + _v(sh.u)) - cp).normalized() * 15.0
			var v := (_to(_v(sh.p) + _v(sh.v)) - cp).normalized() * 15.0
			_pl(PackedVector2Array([cp + u, cp + u + v, cp + v]), _col(String(sh.get("c", "gold"))), 1.8, false)
			return
		if String(sh.k) != "line":
			super(sh, o, rot, font)
			return
		# 整條直線：過兩點 p、q，或 ax + by + c = 0
		var p: Vector2
		var d: Vector2
		if sh.has("abc"):
			var a := float(sh.abc[0])
			var b := float(sh.abc[1])
			var c := float(sh.abc[2])
			d = Vector2(b, -a).normalized()
			p = Vector2(-a * c, -b * c) / (a * a + b * b)
		else:
			p = _v(sh.p)
			var q := _v(sh.q)
			if sh.has("from_p"):
				# 平移：從 from_p、from_q 滑過來
				var k := _anim_k(sh)
				k = k * k * (3.0 - 2.0 * k)
				p = _v(sh.from_p).lerp(p, k)
				q = _v(sh.from_q).lerp(q, k)
			d = (q - p).normalized()
		var wr := _world().grow(1.0)
		var big := wr.size.length() + (p - wr.get_center()).length()
		var col := _col(String(sh.get("c", "cyan")))
		_pl(PackedVector2Array([_to(p - d * big), _to(p + d * big)]), col, float(sh.get("w", 2.0)), sh.get("dash", false))
		if String(sh.get("s", "")) != "":
			# 名字標在畫面裡、靠右上那一端
			var e := p + d * big
			var s0 := p - d * big
			var end_w := e if (e.x > s0.x or (is_equal_approx(e.x, s0.x) and e.y > s0.y)) else s0
			var dir := (end_w - p).normalized()
			var lp := p
			for k in 80:
				var q := p + dir * (k * 0.25)
				if not _world().grow(-0.8).has_point(q):
					break
				lp = q
			_label(font, _to(lp), String(sh.s), sh.get("off", [6, -6]), col)
