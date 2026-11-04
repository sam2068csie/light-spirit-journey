extends RefCounted
## 真的「玩」舊的光橋引擎（level_base.gd）的一段旅程：L1 光之橋、L5 鏡像之塔。
## 和學生一樣作答：點正確的選項、把滑桿拉到答案、點底數晶片、在舞台上點整數點／弦的端點、
## 沿著正確的曲線一筆一筆畫（滑鼠事件直接送進舞台），最後確認真的過關（三顆星）。
## 用法（tests/test_play.gd）：await load("res://tests/play_base.gd").play(self, lv, type)
##   t：正在跑的測試（提供 frames、wait、_check、_issue）
##   lv：關卡；呼叫前已經 make_round → _start_round

const Stage := preload("res://data/levels/engine/light_stage.gd")

const RUN_TIMEOUT := 10.0      # 光靈跑完一趟最多等幾秒
const CHORD_TIMEOUT := 4.0     # 弦的動畫最多等幾秒


static func play(t, lv, type: String) -> void:
	var r: Dictionary = lv.r
	match type:
		"fit":
			if not await _answer_all(t, lv, "預言"):
				return
			await _play_fit(t, lv, r)
		"rank":
			if not await _answer_all(t, lv, "預言"):
				return
			await _play_rank(t, lv, r)
		"quadrant":
			if not await _answer_all(t, lv, "預言"):
				return
			await _play_quadrant(t, lv, r)
		"count":
			await _play_count(t, lv, r)
		"chord":
			if not await _answer_all(t, lv, "判斷凹口"):
				return
			await _play_chord(t, lv, r)
		"draw":
			await _play_draw(t, lv, r)
		"cross":
			await _play_cross(t, lv, r)
		_:
			t._issue("play_base 不認得的題型：%s" % type)
			return
	await _verify(t, lv)


# ---------------- 共用 ----------------

## 目前的提示文字（去掉顏色標記），回報問題時附上
static func _hint_of(lv) -> String:
	if not lv.hint_panel.visible:
		return ""
	var s := String(lv.hint_label.text)
	var re := RegEx.new()
	re.compile("\\[/?[a-z]+(=[^\\]]*)?\\]")
	return re.sub(s, "", true).replace("\n", " ").strip_edges().left(90)


## 一直回答正確的選項，直到不再出選擇題（預言、連續預言、最終題）
static func _answer_all(t, lv, label: String) -> bool:
	var guard := 0
	while lv.predicting and guard < 8:
		guard += 1
		await t._check(lv, "%s %d 作答前" % [label, guard])
		var q: Dictionary = lv.cur_q
		var tries0: int = lv.predict_tries
		lv._on_answer(int(q.correct))
		await t.frames(2)
		if lv.predicting and lv.cur_q == q and lv.predict_tries > tries0:
			t._issue("%s %d：選了正確答案（%s）卻沒有前進" % [label, guard, str(q.options[int(q.correct)])])
			return false
	if lv.predicting:
		t._issue("%s：選擇題一直出不完" % label)
		return false
	return true


static func _verify(t, lv) -> void:
	await t.frames(3)
	await t._check(lv, "過關")
	if lv.revealing or not lv.next_btn.visible or int(lv.round_stars) <= 0:
		t._issue("全部照正確答案作答，卻沒有過關（%s）" % _hint_of(lv))
	elif int(lv.round_stars) < 3:
		t._issue("全部一次答對，卻只拿到 %d 星（%s）" % [int(lv.round_stars), _hint_of(lv)])


static func _click(stage, pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = pos
	e.global_position = stage.global_position + pos
	stage._gui_input(e)
	var u := InputEventMouseButton.new()
	u.button_index = MOUSE_BUTTON_LEFT
	u.pressed = false
	u.position = pos
	u.global_position = stage.global_position + pos
	stage._gui_input(u)


## 按住、沿著 pts 拖過去、放開（和手指畫一筆一樣）
static func _drag(stage, pts: PackedVector2Array) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = pts[0]
	stage._gui_input(e)
	for i in range(1, pts.size()):
		var mv := InputEventMouseMotion.new()
		mv.position = pts[i]
		mv.button_mask = MOUSE_BUTTON_MASK_LEFT
		stage._gui_input(mv)
	var u := InputEventMouseButton.new()
	u.button_index = MOUSE_BUTTON_LEFT
	u.pressed = false
	u.position = pts[pts.size() - 1]
	stage._gui_input(u)


## 把參數 p 拉到 v（透過滑桿）；拉不到就回報
static func _slide(t, lv, p: String, v: float) -> bool:
	if not lv.sliders.has(p):
		t._issue("沒有 %s 的滑桿" % p)
		return false
	var s: HSlider = lv.sliders[p]
	if not s.editable or not s.is_visible_in_tree():
		t._issue("%s 的滑桿不能拉（editable=%s）" % [p, str(s.editable)])
	lv.set_param(p, v)
	if absf(float(lv.vals[p]) - v) > 1e-6:
		t._issue("滑桿拉不到 %s = %s（最接近的是 %s）" % [p, str(v), str(lv.vals[p])])
		return false
	return true


# ---------------- fit：調滑桿、點亮光橋 ----------------

static func _play_fit(t, lv, r: Dictionary) -> void:
	if not lv.go_btn.visible:
		t._issue("預言答完了，卻沒有出現「點亮光橋」")
		return
	for p in r.params:
		if not await _slide(t, lv, String(p), float(r.answer[p])):
			return
	await t._check(lv, "滑桿調好之後")
	var res: Array = await _run(t, lv)
	if res.is_empty():
		t._issue("按了「點亮光橋」，光靈 %d 秒內沒有跑完" % int(RUN_TIMEOUT))
	elif not res[0]:
		t._issue("答案的光橋，光靈卻失敗了（%s）" % ("被黑洞吸走" if res[1] == "hole" else "沒接到寶石"))


## 按「點亮光橋」，等光靈跑完；回傳 [success, reason]，逾時回傳 []
static func _run(t, lv) -> Array:
	var got: Array = []
	var cb := func(ok: bool, reason: String) -> void:
		got.append(ok)
		got.append(reason)
	lv.stage.run_finished.connect(cb)
	lv._on_go()
	var t0 := Time.get_ticks_msec()
	while got.is_empty() and Time.get_ticks_msec() - t0 < int(RUN_TIMEOUT * 1000.0):
		await t.frames(1)
	lv.stage.run_finished.disconnect(cb)
	await t.frames(2)
	return got


# ---------------- rank：替每條曲線點選底數 ----------------

static func _play_rank(t, lv, r: Dictionary) -> void:
	if lv.rank_options.size() != r.bases.size():
		t._issue("底數辨識：有 %d 條曲線，卻只有 %d 列選項" % [r.bases.size(), lv.rank_options.size()])
		return
	for i in r.bases.size():
		var hit := false
		for chip in lv.rank_options[i]:
			if is_equal_approx(float(chip.get_meta("base")), float(r.bases[i])):
				chip.button_pressed = true
				hit = true
		if not hit:
			t._issue("底數辨識：第 %d 條曲線的選項裡沒有 %s" % [i + 1, str(r.bases[i])])
			return
	await t._check(lv, "底數配好之後")
	lv._on_go()
	await t.frames(2)


# ---------------- quadrant：調 h、k 讓指定象限亮起（或按「做不到！」） ----------------

static func _play_quadrant(t, lv, r: Dictionary) -> void:
	if r.get("impossible", false):
		await t._check(lv, "做不到之前")
		if not lv.alt_btn.visible:
			t._issue("這題做不到，卻沒有「做不到！」按鈕")
		lv._on_impossible()
		await t.frames(2)
		return
	var want: Array = r.target.duplicate()
	want.sort()
	var lit_now := func() -> Array:
		return Stage.quadrants_of(r.form, lv.vals.a, lv.vals.h, lv.vals.k, lv.vals.m)
	for p in r.params:
		lv.set_param(String(p), float(r.answer.get(p, lv.vals[p])))
	if lit_now.call() != want:
		# 題目給的答案不行：在滑桿的格點上找一組
		var found := false
		var rh: Array = lv._range("h")
		var rk: Array = lv._range("k")
		var hv := float(rh[0])
		while hv <= float(rh[1]) + 1e-6 and not found:
			var kv := float(rk[0])
			while kv <= float(rk[1]) + 1e-6:
				if Stage.quadrants_of(r.form, lv.vals.a, hv, kv, lv.vals.m) == want:
					lv.set_param("h", hv)
					lv.set_param("k", kv)
					found = true
					break
				kv += float(rk[2])
			hv += float(rh[2])
		t._issue("象限燈塔：題目的答案 h、k 點不亮第 %s 象限%s" % [str(want), "（改用滑桿上找到的一組）" if found else "，滑桿上也找不到"])
		if not found:
			return
	await t._check(lv, "h、k 調好之後")
	lv._on_go()
	await t.frames(2)


# ---------------- count：移動水平線完成每個任務，再回答範圍題 ----------------

static func _play_count(t, lv, r: Dictionary) -> void:
	var goals: Array = r.goals
	var rg: Array = lv._range("c")
	for gi in goals.size():
		await t._check(lv, "調頻任務 %d" % (gi + 1))
		var found := false
		var c := float(rg[0])
		while c <= float(rg[1]) + 1e-6:
			if lv.stage.roots_of(c).size() == int(goals[gi]):
				found = true
				break
			c += float(rg[2])
		if not found:
			t._issue("調頻任務 %d：c 怎麼拉都不會恰好有 %d 個交點" % [gi + 1, int(goals[gi])])
			return
		if not await _slide(t, lv, "c", snappedf(c, 1e-6)):
			return
		await t._check(lv, "調頻任務 %d 拉好之後" % (gi + 1))
		lv._on_go()
		await t.frames(2)
		if int(lv.goal_idx) != gi + 1:
			t._issue("調頻任務 %d：c = %s 時恰有 %d 個交點，按「鎖定」卻沒有過" % [gi + 1, str(c), int(goals[gi])])
			return
	if not lv.predicting:
		t._issue("調頻任務都完成了，卻沒有出現範圍題")
		return
	await _answer_all(t, lv, "範圍題")


# ---------------- chord：點 P、Q 連出弦，再比大小 ----------------

static func _play_chord(t, lv, r: Dictionary) -> void:
	var stage = lv.stage
	if int(lv.chord_phase) != 1 or not stage.chord_on:
		t._issue("凹口答完了，卻沒有進到「連出弦」")
		return
	await t._check(lv, "連弦之前")
	var rect := Rect2(Vector2.ZERO, stage.size)
	for key in ["x1", "x2"]:
		var x := float(r.chord[key])
		var y := Stage.fval(r.form, lv.vals.a, lv.vals.h, lv.vals.k, lv.vals.m, x, 0)
		var sp: Vector2 = stage.to_screen(Vector2(x, y))
		if is_nan(y) or not rect.grow(-4.0).has_point(sp):
			t._issue("凹口天秤：弦的端點 (%s, %s) 不在畫面裡，點不到" % [str(x), str(y)])
			return
		_click(stage, sp)
		await t.frames(1)
	var t0 := Time.get_ticks_msec()
	while int(lv.chord_phase) != 2 and Time.get_ticks_msec() - t0 < int(CHORD_TIMEOUT * 1000.0):
		await t.frames(1)
	if int(lv.chord_phase) != 2:
		t._issue("點了 P、Q，弦卻一直沒有畫完（chord_sel=%s）" % str(stage.chord_sel))
		return
	await _answer_all(t, lv, "比大小")


# ---------------- draw／cross：標整數點、沿著正確曲線畫 ----------------

static func _draw_curve(r: Dictionary) -> Callable:
	var ans: Dictionary = r.get("answer", {})
	var form := String(r.get("form", "exp"))
	var a := float(ans.get("a", 1.5))
	var h := float(ans.get("h", 0.0))
	var k := float(ans.get("k", 0.0))
	var m := float(ans.get("m", 1.0))
	return func(x: float) -> float:
		return Stage.fval(form, a, h, k, m, x, 0)


static func _play_draw(t, lv, r: Dictionary) -> void:
	var f := _draw_curve(r)
	if lv.marking:
		if not await _do_marks(t, lv, f, "整數點"):
			return
	await _sketch(t, lv, f, "畫圖")


static func _play_cross(t, lv, r: Dictionary) -> void:
	for side in [1, 2]:
		var sd = r.exp if side == 1 else r.quad
		var f := func(x: float) -> float:
			return Stage.side_val(sd, x)
		var nm := "第 %d 條" % side
		if int(lv.stage.cross_sketch) != side:
			t._issue("%s：沒有進到畫%s（cross_sketch=%d）" % [nm, nm, int(lv.stage.cross_sketch)])
			return
		if lv.marking:
			if not await _do_marks(t, lv, f, nm + "整數點"):
				return
		if not await _sketch(t, lv, f, nm):
			return
		if side == 1 and int(lv.stage.cross_sketch) != 2:
			t._issue("第 1 條畫對了，卻沒有進到第 2 條（%s）" % _hint_of(lv))
			return
	if not lv.predicting:
		t._issue("兩條都畫好了，卻沒有出現交點個數題（%s）" % _hint_of(lv))
		return
	await _answer_all(t, lv, "數交點")


## 在舞台上點出曲線經過的整數點（自己算），按「確認整數點」
static func _do_marks(t, lv, f: Callable, nm: String) -> bool:
	var stage = lv.stage
	await t._check(lv, nm + " 點之前")
	var mine := []
	for xi in range(int(ceil(stage.x_range.x)), int(floor(stage.x_range.y)) + 1):
		var y: float = f.call(float(xi))
		if is_nan(y) or absf(y - roundf(y)) > 1e-6:
			continue
		var p := Vector2(xi, roundf(y))
		if stage.markable(p):
			mine.append(p)
			_click(stage, stage.to_screen(p))
	await t.frames(1)
	if stage.mark_sel.size() != mine.size():
		t._issue("%s：點了 %d 個整數點，舞台只記到 %d 個" % [nm, mine.size(), stage.mark_sel.size()])
	await t._check(lv, nm + " 點好之後")
	if lv.go_btn.disabled or not lv.go_btn.visible:
		t._issue("%s：點好了，「確認整數點」卻不能按" % nm)
	lv._on_go()
	await t.frames(2)
	if lv.marking or int(lv.mark_errs) > 0:
		t._issue("%s：點了 %s，卻被判錯（答案 %s）（%s）" % [nm, str(mine), str(stage.mark_targets), _hint_of(lv)])
		return false
	return true


## 沿著 f 畫（在畫面外就斷開，分成好幾筆），按「確認送出」
static func _sketch(t, lv, f: Callable, nm: String) -> bool:
	var stage = lv.stage
	if not stage.draw_on:
		t._issue("%s：不能畫圖（draw_on 是 false）" % nm)
		return false
	await t._check(lv, nm + " 畫之前")
	var pieces := _pieces(stage, f)
	if pieces.is_empty():
		t._issue("%s：正確的圖形完全不在畫面裡" % nm)
		return false
	for pc in pieces:
		_drag(stage, pc)
		await t.frames(1)
	if not lv.stroke_pending:
		t._issue("%s：畫了 %d 筆，卻沒有出現「確認送出」" % [nm, pieces.size()])
		return false
	await t._check(lv, nm + " 畫好之後")
	var tries0: int = lv.tries
	lv._on_go()
	await t.frames(2)
	if int(lv.tries) == tries0:
		t._issue("%s：按了「確認送出」卻沒有評分" % nm)
		return false
	if lv.revealing or (int(lv.sketch_fails) > 0):
		t._issue("%s：沿著正確的曲線畫（%d 筆），卻被判錯（%s）" % [nm, pieces.size(), _hint_of(lv)])
		return false
	return true


## 正確的曲線在舞台上的樣子：每隔約 3.5 像素一點；跑出畫面（或沒有定義）就斷成另一筆
static func _pieces(stage, f: Callable) -> Array:
	var rect := Rect2(Vector2(4, 4), stage.size - Vector2(8, 8))
	var x0: float = stage.x_range.x
	var x1: float = stage.x_range.y
	var inside := func(x: float) -> bool:
		var y: float = f.call(x)
		if is_nan(y) or is_inf(y):
			return false
		return rect.has_point(stage.to_screen(Vector2(x, y)))
	var pt := func(x: float) -> Vector2:
		return stage.to_screen(Vector2(x, f.call(x)))
	var out := []
	var cur := PackedVector2Array()
	var n := 1400
	var px := x0
	var p_in := false
	for i in n + 1:
		var x := lerpf(x0, x1, float(i) / n)
		var now: bool = inside.call(x)
		if now and not p_in and i > 0:
			# 從畫面外進來：找出進入畫面的位置，從那裡開始畫
			var lo := px
			var hi := x
			for _j in 30:
				var mid := (lo + hi) / 2.0
				if inside.call(mid):
					hi = mid
				else:
					lo = mid
			cur.append(pt.call(hi))
			_fill(stage, f, hi, x, cur)
		elif now:
			if cur.is_empty():
				cur.append(pt.call(x))
			else:
				_fill(stage, f, px, x, cur)
		elif p_in:
			# 要離開畫面了：畫到邊緣為止
			var lo2 := px
			var hi2 := x
			for _j in 30:
				var mid2 := (lo2 + hi2) / 2.0
				if inside.call(mid2):
					lo2 = mid2
				else:
					hi2 = mid2
			_fill(stage, f, px, lo2, cur)
			if cur.size() >= 2:
				out.append(cur)
			cur = PackedVector2Array()
		px = x
		p_in = now
	if cur.size() >= 2:
		out.append(cur)
	return out


## 從 xa 畫到 xb：點距太大就再細分（陡的地方，例如貼近漸近線）
static func _fill(stage, f: Callable, xa: float, xb: float, cur: PackedVector2Array, depth := 0) -> void:
	var pb: Vector2 = stage.to_screen(Vector2(xb, f.call(xb)))
	var last: Vector2 = cur[cur.size() - 1]
	var d := last.distance_to(pb)
	if d <= 4.0 or depth > 14:
		if d >= 3.2:
			cur.append(pb)
		return
	var xm := (xa + xb) / 2.0
	_fill(stage, f, xa, xm, cur, depth + 1)
	_fill(stage, f, xm, xb, cur, depth + 1)
