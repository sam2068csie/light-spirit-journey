extends "test_base.gd"
## 真的「玩」一次：每一步都用和玩家一樣的方式作答（點選項、按數字、拖到正確的位置、點河段……），
## 不直接呼叫 _step_done。每一步作答前、填好答案後都檢查版面：
##   ・右邊的卡片不能超出畫面、裡面的東西不能超出卡片、按鈕上的字不能超出按鈕
##   ・中間「正在作答」的框不能壓到下方的圖
##   ・作答之後一定要進到下一步（卡住就是題目或答案有問題）
## 環境變數 ONLY=P1,P2 只玩某幾關；SHOTS=資料夾 會把有問題的畫面存下來（需要有畫面，不能 --headless）
## ALLSHOTS=1（加上 SHOTS）：每一步作答前、作答後都截圖，用來一張一張檢查排版

const Units := preload("res://data/core/units.gd")

var issues := 0
var cur_tag := ""


func _initialize() -> void:
	await setup()
	var only := OS.get_environment("ONLY")
	for u in Units.UNITS:
		for l in u.levels:
			if String(l.get("bank", "")) == "" or String(l.get("file", "")) == "":
				continue
			if only != "" and not (String(l.id) in only.split(",")):
				continue
			var bank = load(preload("res://data/core/paths.gd").of(String(l.bank)))
			await _play_level(String(l.id), String(l.file), bank)
	ok(issues == 0, "玩過的關卡沒有發現問題（%d 個）" % issues)
	finish("PLAY")


func _issue(msg: String) -> void:
	issues += 1
	print("  ✗ %s：%s" % [cur_tag, msg])


func _play_level(lid: String, file: String, bank) -> void:
	g.goto(file)
	await wait(0.8)
	var lv = current_scene
	if lv == null or not lv.has_method("make_round"):
		_issue("%s 開不起來" % lid)
		return
	for n in lv.get_children():
		if n is Control and n.mouse_filter == Control.MOUSE_FILTER_STOP and n.get_index() > 3:
			n.queue_free()
	await frames()
	lv.journey_mode = true
	for slot in bank.slots():
		for vi in slot.variants.size():
			cur_tag = "%s/%s#%d" % [lid, slot.id, vi]
			lv.rounds = [lv.make_round(slot, slot.variants[vi])]
			lv.ri = 0
			lv._start_round()
			await frames(3)
			if lv.get("intro_block") != null:
				lv._intro_finish()
			await frames(2)
			if String(slot.type) == "speed":
				await _play_speed(lv)
			elif String(slot.type) == "forge":
				await _play_forge(lv)
			elif String(slot.type) == "tune":
				await _play_tune(lv)
			elif String(slot.type) == "mag":
				await _play_mag(lv)
			elif lv.get("steps") == null and lv.has_method("_on_go"):
				await _play_base(lv, String(slot.type))
			elif not _no_play.has("type:" + String(slot.type)):
				_no_play["type:" + String(slot.type)] = true
				print("  （%s：%s 題型沒有實際操作）" % [lid, String(slot.type)])
	print("  %s 玩完了" % lid)


# ---------------- 版面檢查 ----------------
var _all_shots := OS.get_environment("ALLSHOTS") != ""      # ALLSHOTS=1：每一步都截圖（檢查排版用）
var _shot_n := 0


func _check(lv, when: String) -> void:
	await frames(2)
	if _all_shots:
		_shot_n += 1
		await wait(0.35)
		await shot("%03d_%s_%s" % [_shot_n, cur_tag.replace("/", "_").replace("#", "_"), when])
	var vp := (lv as Control).get_viewport_rect().size
	var card: Control = lv.side_card
	var cr := card.get_global_rect()
	if cr.end.x > vp.x + 1.0:
		_issue("%s：右邊卡片超出畫面（右緣 %d > %d）" % [when, int(cr.end.x), int(vp.x)])
	await _check_node(card, cr, when)
	var gb: Button = lv.go_btn
	if gb.is_visible_in_tree():
		var r: Rect2 = gb.get_global_rect()
		if r.end.y > vp.y + 1.0:
			_issue("%s：「%s」按鈕超出畫面下緣" % [when, gb.text])
	# 中間：作答框不能壓到下方的圖
	var fv = lv.get("fview")
	if fv != null and fv.get("live_fill") != null and String(fv.live_fill) != "" and fv.kind == "forge" and not fv.done:
		var y_top: float = fv._line_y(fv.lines.size())
		var bottom: float = y_top - 20.0 + fv._live_h() - 10.0
		if bottom > fv._bottom_limit() + 4.0:
			_issue("%s：作答框（下緣 %d）壓到下面（界線 %d）" % [when, int(bottom), int(fv._bottom_limit())])
			await shot("%s_%s" % [cur_tag.replace("/", "_").replace("#", "_"), when])


func _check_node(n: Node, cr: Rect2, when: String) -> void:
	for c in n.get_children():
		if not (c is Control) or not (c as Control).is_visible_in_tree():
			continue
		var ctl: Control = c
		if ctl is ScrollBar:
			continue
		var r := ctl.get_global_rect()
		if r.size.x > 1.0 and (r.position.x < cr.position.x - 2.0 or r.end.x > cr.end.x + 2.0):
			var txt := ""
			if ctl is Button:
				txt = (ctl as Button).text
			elif ctl is Label:
				txt = (ctl as Label).text
			elif ctl.get("text") != null:
				txt = str(ctl.get("text"))
			_issue("%s：%s 超出右邊卡片（%s）" % [when, ctl.get_class(), txt.left(30)])
			continue
		if ctl is Button:
			var b: Button = ctl
			var m: Control = b.get_node_or_null("Math")
			if m != null:
				if m.get_combined_minimum_size().x > b.size.x + 2.0:
					_issue("%s：按鈕上的式子太長（%s）" % [when, str(m.get("text")).left(30)])
			elif b.text != "" and not b.clip_text:
				var font: Font = b.get_theme_font("font")
				var fs: int = b.get_theme_font_size("font_size")
				for ln in b.text.split("\n"):
					var tw := font.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
					if tw > b.size.x - 4.0:
						_issue("%s：按鈕的字超出（%s：字寬 %d、按鈕 %d）" % [when, ln.left(30), int(tw), int(b.size.x)])
		await _check_node(ctl, cr, when)


# ---------------- 推導題 ----------------
func _play_forge(lv) -> void:
	var guard := 0
	while lv.si < lv.steps.size() and guard < 60:
		guard += 1
		var si0: int = lv.si
		var st: Dictionary = lv.steps[si0]
		var nm := "%02d%s" % [si0, String(st.get("name", ""))]
		await _check(lv, nm + " 作答前")
		var kind := String(st.kind)
		match kind:
			"choice":
				lv._on_answer(int(lv.cur_q.correct))
			"fill":
				lv.slot_vals = Array(st.answers).map(func(a): return String(a).replace("-", "−"))
				lv._refresh_fill()
				await _check(lv, nm + " 填好之後")
				lv._fill_submit()
			"filter":
				lv.filter_keep = Array(st.keep).duplicate()
				lv._filter_submit()
			"order":
				var idx: Array = range(st.items.size())
				idx.sort_custom(func(a, b): return float(st.items[a].v) < float(st.items[b].v))
				lv.order_seq = idx
				lv._refresh_order()
				await _check(lv, nm + " 排好之後")
				lv._order_submit()
			"blocks":
				lv.blk_seq = lv._flatten_terms(st.terms)
				lv._refresh_blocks()
				await _check(lv, nm + " 拼好之後")
				lv._blocks_submit(st)
			"probe":
				await _do_probe(lv, st)
			"graph":
				await _do_graph(lv, st)
			_:
				await _do_custom(lv, st, nm)
		await frames(3)
		if lv.si == si0:
			_issue("%s：答對了卻沒有進到下一步（%s）" % [nm, kind])
			await shot("%s_stuck_%02d" % [cur_tag.replace("/", "_").replace("#", "_"), si0])
			lv._step_done(st, "")
			await frames(2)
	await _check(lv, "完成")


func _do_probe(lv, st: Dictionary) -> void:
	var ev = lv.fview
	match String(st.mode):
		"find":
			ev.px = ev.parse(String(st.target))
			lv._on_probe_move()
			lv._probe_submit(st)
		"roots", "pins":
			for r in st.roots:
				ev.px = ev.parse(str(r))
				lv._on_probe_move()
				lv._probe_submit(st)
				await frames(1)
		"tune":
			var goal: float = ev.parse(String(st.goal))
			var found := false
			for k in range(-60, 61):
				ev.px = float(k)
				if absf(ev.probe_value() - goal) < 1e-9:
					found = true
					break
			if not found:
				_issue("tune 找不到符合的 k")
			lv._on_probe_move()
			lv._probe_submit(st)
		"stretch", "shift":
			ev.px = ev.parse(String(st.goal))
			lv._on_probe_move()
			lv._probe_submit(st)
		_:
			_issue("不認得的 probe：%s" % st.mode)
			lv._step_done(st, "")


# ---------------- 三角函數（G1～G7）的互動步驟 ----------------
var _no_play := {}

## 右邊卡片裡的滑桿（照畫面上的順序）
func _sliders(lv) -> Array:
	var out := []
	var stack: Array = [lv.rank_box]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		for c in n.get_children():
			if c is HSlider:
				out.append(c)
			stack.append(c)
	return out


## 找出第一個在 list 裡、值等於 v 的位置
func _idx_of(list: Array, v: float) -> int:
	for i in list.size():
		if absf(float(list[i]) - v) < 1e-6:
			return i
	return -1


## 送出這一步（各關的 _custom_go 依步驟種類分派）
func _go(lv) -> void:
	lv._custom_go()
	await frames(2)


func _do_custom(lv, st: Dictionary, nm: String) -> void:
	var kind := String(st.kind)
	var tv = lv.fview
	var lid := String(lv.level_id())
	# 關卡自己會放答案的步驟（直線與圓的 grid…）：放好之後照一般的方式送出
	if lv.has_method("test_answer") and lv.test_answer(st):
		await _check(lv, nm + " 放好之後")
		await _go(lv)
		return
	if lid.begins_with("L"):
		await _do_exp(lv, st, nm)
		return
	match kind:
		"spin":
			if lid == "G1":
				tv.set_spin(roundi(float(st.target) / lv.STEP))
				lv._refresh_spin()
			else:
				var sl := _sliders(lv)
				var lo := float(st.lo)
				sl[0].value = roundi((float(st.umax) - lo) / 15.0)
				tv.sp_max = tv.sp_u
				sl[0].value = roundi((float(st.umin) - lo) / 15.0)
				tv.sp_min = tv.sp_u
				lv._refresh_spin()
			await _check(lv, nm + " 轉好之後")
			await _go(lv)
		"fan":
			var rr := float(st.r)
			var th := float(st.target) / rr if String(st.goal) == "arc" else 2.0 * float(st.target) / (rr * rr)
			tv.set_fan(th)
			await _check(lv, nm + " 打開之後")
			await _go(lv)
		"wave":
			if st.has("targets"):
				for tg in st.targets:
					tv.set_wave(roundi(float(tg) / lv.STEP))
					await _go(lv)
			else:
				await _solve_tiles(lv, st, nm)
		"tiles", "eq":
			await _solve_tiles(lv, st, nm)
		"dial":
			var knobs: Array = st.knobs
			var vals := []
			var muls := []
			for k in knobs:
				vals.append(lv._knob_vals(k))
				muls.append(PI if String(k.get("unit", "")) == "pi" else 1.0)
			var idx := []
			idx.resize(knobs.size())
			idx.fill(0)
			var hit := false
			var guard := 0
			while guard < 400000:
				guard += 1
				var cur: Dictionary = tv.cur.duplicate()
				for i in knobs.size():
					cur[String(knobs[i].p)] = float(vals[i][idx[i]]) * float(muls[i])
				if lv._dial_match(st, cur):
					hit = true
					break
				var j := 0
				while j < knobs.size():
					idx[j] += 1
					if idx[j] < vals[j].size():
						break
					idx[j] = 0
					j += 1
				if j >= knobs.size():
					break
			if not hit:
				_issue("%s：旋鈕怎麼轉都對不上目標" % nm)
				lv._step_done(st, "")
				return
			var sl2 := _sliders(lv)
			for i in knobs.size():
				sl2[i].value = idx[i]
			await _check(lv, nm + " 轉好之後")
			await _go(lv)
		"chain":
			var ops: Array = st.ops
			var fn := String(st.get("fn", "sin"))
			var tg: Dictionary = st.target
			var want := {"f": fn, "a": tg.a, "b": tg.b, "c": tg.c, "d": tg.d}
			var TV = load("res://data/levels/trig/level_trig4_tide.gd").TideView
			var best: Array = []
			var frontier: Array = [[]]
			for depth in mini(int(st.get("max", 6)), 5):
				var nxt: Array = []
				for seq in frontier:
					for i in ops.size():
						var s2: Array = seq.duplicate()
						s2.append(i)
						var o2: Array = s2.map(func(k): return ops[k])
						if TV.same_curve(lv.chain_curve(fn, lv.chain_state(o2)), want):
							best = s2
							break
						nxt.append(s2)
					if not best.is_empty():
						break
				if not best.is_empty():
					break
				frontier = nxt
			if best.is_empty():
				_issue("%s：零件怎麼接都接不出目標" % nm)
				lv._step_done(st, "")
				return
			for i in best:
				lv._chain_add(i)
				await frames(1)
			await _check(lv, nm + " 接好之後")
			await _go(lv)
		"ride":
			for tg2 in st.targets:
				tv.ride_t = float(tg2)
				lv._refresh_ride()
				await _go(lv)
		"hunt":
			tv.found = range(tv.hunt_pts.size())
			lv._refresh_hunt()
			await _check(lv, nm + " 點好之後")
			await _go(lv)
		"rot":
			var sl3 := _sliders(lv)
			var stp := float(st.get("step", 15.0))
			var ar: Array = st.get("arange", [0.0, 360.0])
			var br: Array = st.get("brange", [0.0, 360.0])
			var diff := String(st.mode) == "diff"
			var al: Array = st.get("alphas", [])
			var be: Array = st.get("betas", [])
			var ok := false
			for i in int(sl3[0].max_value) + 1:
				for j in int(sl3[1].max_value) + 1:
					var a := float(ar[0]) + i * stp
					var b := float(br[0]) + j * stp
					var res := a - b if diff else a + b
					var off := absf(fposmod(res - float(st.target) + 180.0, 360.0) - 180.0)
					if st.get("abs", false):
						off = minf(off, absf(fposmod(-res - float(st.target) + 180.0, 360.0) - 180.0))
					if off < 1e-6 and (al.is_empty() or lv._deg_in(al, a)) and (be.is_empty() or lv._deg_in(be, b)):
						sl3[0].value = i
						sl3[1].value = j
						ok = true
						break
				if ok:
					break
			if not ok:
				_issue("%s：α、β 怎麼轉都到不了目標" % nm)
				lv._step_done(st, "")
				return
			await _check(lv, nm + " 轉好之後")
			await _go(lv)
		"lines":
			var sl4 := _sliders(lv)
			for tg3 in st.targets:
				var k3 := _idx_of(st.slopes, float(tg3))
				if k3 < 0:
					_issue("%s：滑桿上沒有斜率 %s" % [nm, str(tg3)])
					continue
				sl4[0].value = k3
				await _go(lv)
		"mirror":
			var sl5 := _sliders(lv)
			var s5: HSlider = sl5[0]
			if String(st.mode) == "sweep":
				s5.value = s5.min_value
				await frames(1)
				s5.value = s5.max_value
				await frames(1)
				if st.has("ask"):
					lv.mir_pick = int(st.ask.get("correct", 0))
			else:
				var ok5 := false
				for v in int(s5.max_value) + 1:
					s5.value = v
					if absf(fposmod(tv.mir_phi * 2.0 - float(st.target) + 180.0, 360.0) - 180.0) < 1e-6:
						ok5 = true
						break
				if not ok5:
					_issue("%s：鏡面怎麼轉都到不了目標" % nm)
			await _check(lv, nm + " 轉好之後")
			await _go(lv)
		"phasor":
			var sl6 := _sliders(lv)
			var want6 := Vector2(float(st.a), float(st.b))
			var ok6 := false
			for i in int(sl6[0].max_value) + 1:
				sl6[0].value = i
				for j in int(sl6[1].max_value) + 1:
					sl6[1].value = j
					if tv.ph_tip(String(st.get("form", "sin"))).distance_to(want6) < 1e-4:
						ok6 = true
						break
				if ok6:
					break
			if not ok6:
				_issue("%s：r、角度怎麼轉都對不上" % nm)
			await _check(lv, nm + " 轉好之後")
			await _go(lv)
		"peak":
			var sl7 := _sliders(lv)
			var lo7 := float(st.get("dom", [0.0, 360.0])[0])
			sl7[0].value = roundi((float(st.xs[0]) - lo7) / 15.0)
			await _check(lv, nm + " 轉好之後")
			await _go(lv)
		_:
			if not _no_play.has(kind):
				_no_play[kind] = true
				print("  （%s 步驟沒有實際操作，直接當作答對）" % kind)
			lv._step_done(st, "")


# ---------------- 指對數（L2～L8）的互動步驟 ----------------
func _do_exp(lv, st: Dictionary, nm: String) -> void:
	var kind := String(st.kind)
	var fv = lv.get("fview")
	match kind:
		"line":
			fv.line_seg = Array(st.seg).duplicate()
			fv.line_inc = Array(st.inc).duplicate()
			fv.queue_redraw()
			await _check(lv, nm + " 塗好之後")
			await _go(lv)
		"grid":
			var vals := []
			for row in st.ans:
				vals.append(Array(row).map(func(v): return int(v)))
			lv.grid_vals = vals
			lv._refresh_grid()
			await _check(lv, nm + " 填好之後")
			await _go(lv)
		"explore":
			var tt: float = fv.t_of(st.tmap, float(st.targets[0]))
			lv.ex_slider.value = tt
			await _check(lv, nm + " 移好之後")
			await _go(lv)
		"chain":
			for idx in lv.chain_solution(st):
				lv._chain_pick(idx)
				await frames(1)
			await _check(lv, nm + " 接好之後")
			await _go(lv)
		"rule":
			lv._on_answer(int(lv.cur_q.correct))
		"gate":
			lv.filter_keep = Array(st.keep).duplicate()
			lv._refresh_filter()
			await _check(lv, nm + " 選好之後")
			await _go(lv)
		"compass":
			lv.compass_vals = lv.compass_answers(st)
			lv._refresh_compass()
			await _check(lv, nm + " 判斷好之後")
			await _go(lv)
		"ruler":
			lv._ruler_pick(int(st.ans))
		"grow":
			lv.grow_slider.value = int(st.ans)
			await _check(lv, nm + " 移好之後")
			await _go(lv)
		_:
			if not _no_play.has(kind):
				_no_play[kind] = true
				print("  （%s 步驟沒有實際操作，直接當作答對）" % kind)
			lv._step_done(st, "")


## 舊的光橋引擎（L1、L5）：交給 play_base.gd
func _play_base(lv, type: String) -> void:
	if not FileAccess.file_exists("res://tests/play_base.gd"):
		if not _no_play.has("base"):
			_no_play["base"] = true
			print("  （光橋題型還沒有實際操作）")
		return
	await load("res://tests/play_base.gd").play(self, lv, type)


## 參數調頻（L2）：每個任務找出合格的參數 → 一步步計算 → 最後的範圍題
func _play_tune(lv) -> void:
	var rd: Dictionary = lv.r
	var rg: Array = rd.param.range
	for gi in rd.goals.size():
		await _check(lv, "調頻任務 %d" % (gi + 1))
		var ok := false
		var v := float(rg[0])
		while v <= float(rg[1]) + 1e-6:
			if lv.tune_valid(rd, v) == int(rd.goals[gi]):
				lv.tune_slider.value = v
				ok = true
				break
			v += float(rg[2])
		if not ok:
			_issue("調頻任務 %d 找不到合格的參數" % (gi + 1))
			return
		lv._tune_lock()
		await frames(2)
	if int(lv.tune_phase) == 1:
		await _play_forge(lv)
	await frames(2)
	if int(lv.tune_phase) == 2:
		await _check(lv, "範圍題")
		lv._on_answer(int(lv.cur_q.correct))
	else:
		_issue("調頻：算完之後沒有進到範圍題")


## 數量級實驗室（L4）：每個任務用按鈕走到目標 → 測驗
func _play_mag(lv) -> void:
	var rd: Dictionary = lv.r
	for mi in rd.missions.size():
		await _check(lv, "數量級任務 %d" % (mi + 1))
		var path: Array = lv.mag_solve(rd, lv.mag_s, float(rd.missions[mi].target))
		if path.is_empty() and absf(lv.fview.mag_measure(rd, lv.mag_s) - float(rd.missions[mi].target)) >= 0.15:
			_issue("數量級任務 %d 走不到目標" % (mi + 1))
			return
		for op in path:
			lv._mag_op(op)
		await frames(1)
		lv._mag_lock()
		await frames(2)
	var guard := 0
	while int(lv.mag_phase) == 1 and int(lv.mag_q) < rd.quiz.size() and guard < 10:
		guard += 1
		await _check(lv, "數量級測驗 %d" % guard)
		lv._on_answer(int(lv.cur_q.correct))
		await frames(2)


## 拼積木（tiles／eq／拼光束）：用關卡自己的算式，找出和目標相等的積木組合
func _solve_tiles(lv, st: Dictionary, nm: String) -> void:
	var kind := String(st.kind)
	var tv = lv.fview
	var lid := String(lv.level_id())
	var samples: Array = []
	var evalf: Callable
	var want: Array = []
	if kind == "tiles":
		for sm in lv.SAMPLES:
			var a := deg_to_rad(float(sm[0]))
			var b := deg_to_rad(float(sm[1]))
			samples.append([a, b])
			want.append(lv.tiles_target(String(st.target), a, b))
		evalf = func(seq: Array) -> Array:
			return samples.map(func(p): return lv.tiles_value(seq, p[0], p[1]))
	elif kind == "eq":
		for d in lv.EQ_SAMPLES:
			var th := deg_to_rad(float(d))
			samples.append(th)
			want.append(lv.eq_target(String(st.target), th))
		evalf = func(seq: Array) -> Array:
			return samples.map(func(th): return lv.eq_value(seq, th))
	else:
		for d in lv.WV_SAMPLES:
			samples.append(float(d))
			want.append(float(st.a) * sin(deg_to_rad(d)) + float(st.b) * cos(deg_to_rad(d)))
		evalf = func(seq: Array) -> Array:
			return samples.map(func(d): return tv.wv_value(seq, d))
	var toks: Array = Array(st.tokens).filter(func(t): return not (String(t) in ["(", ")", "÷"]))
	var frac := bool(st.get("frac", false))
	var near := func(xs: Array, ys: Array) -> bool:
		for i in xs.size():
			var x: float = xs[i]
			var y: float = ys[i]
			if is_nan(x) or is_nan(y) or absf(x - y) > 1e-6 * maxf(1.0, absf(y)):
				return false
		return true
	var found_num: Array = []
	var found_den: Array = []
	var key := func(vs: Array) -> String:
		return ",".join(vs.map(func(x): return "nan" if is_nan(x) else str(snappedf(float(x), 1e-5))))
	var nums := {}
	var layer: Array = [[]]
	for L in 5:
		var nx: Array = []
		for sq in layer:
			for t in toks:
				var s2: Array = sq.duplicate()
				s2.append(t)
				nx.append(s2)
				var v2: Array = evalf.call(s2)
				if not frac:
					if near.call(v2, want):
						found_num = s2
						break
					continue
				if L < 3 and not nums.has(key.call(v2)):
					nums[key.call(v2)] = s2
				# 分數：把 s2 當分母，看需要的分子有沒有出現過
				if v2.any(func(x): return is_nan(x) or absf(x) < 1e-9):
					continue
				var need: Array = []
				for i in want.size():
					need.append(float(want[i]) * float(v2[i]))
				var kk: String = key.call(need)
				if nums.has(kk):
					found_num = nums[kk]
					found_den = s2
					break
			if not found_num.is_empty():
				break
		if not found_num.is_empty():
			break
		layer = nx
	if found_num.is_empty():
		_issue("%s：積木怎麼拼都拼不出 %s" % [nm, String(st.get("expr", ""))])
		lv._step_done(st, "")
		return
	if frac:
		lv.tiles_num = found_num.duplicate()
		lv.tiles_den = found_den.duplicate()
		tv.tiles_seq = lv._frac_seq()
	else:
		tv.tiles_seq = found_num.duplicate()
	lv._refresh_tiles()
	await _check(lv, nm + " 拼好之後")
	if not tv.matched:
		_issue("%s：拼出 %s 但關卡判定不對" % [nm, " ".join(found_num)])
	await _go(lv)


func _q(v) -> float:
	var s := str(v).strip_edges().replace("−", "-")
	if s.contains("/"):
		var pr := s.split("/")
		return float(pr[0]) / float(pr[1])
	return float(s)


func _do_graph(lv, st: Dictionary) -> void:
	var w = lv.fview
	var mode := String(st.mode)
	match mode:
		"match":
			w.ga = _q(st.target.a); w.gh = _q(st.target.h); w.gk = _q(st.target.k)
		"gems":
			var vw: Dictionary = w._view()
			var s := _q(st.get("snap", "1"))
			var hit := false
			var h: float = vw.x.x
			while h <= vw.x.y + 1e-9 and not hit:
				var k: float = vw.y.x
				while k <= vw.y.y + 1e-9:
					w.gh = h; w.gk = k
					if w.gems_hit() == st.gems.size():
						hit = true
						break
					k += s
				h += s
			if not hit:
				_issue("gems 找不到頂點")
		"quad":
			if not bool(st.get("possible", true)):
				lv._graph_impossible(st)
				return
			var want: Array = st.quads.duplicate()
			want.sort()
			var hit2 := false
			for a in st.get("a_list", ["1"]):
				for hh in range(-5, 6):
					for kk in range(-5, 6):
						w.ga = _q(a); w.gh = hh; w.gk = kk
						if w.quads_now() == want:
							hit2 = true
							break
					if hit2: break
				if hit2: break
			if not hit2:
				_issue("quad 找不到")
		"roots":
			var a := float(st.target[0]); var b := float(st.target[1]); var c := float(st.target[2])
			var d := sqrt(b * b - 4 * a * c)
			w.r0 = (-b - d) / (2 * a); w.r1 = (-b + d) / (2 * a)
		"slide":
			for gl in st.goals:
				w.gk = _q(gl)
				lv._on_graph_move()
				lv._graph_submit(st)
				await frames(1)
			return
		"hline", "chline":
			var ks: Array = st.get("ks", [])
			for i in st.goals.size():
				var found := false
				if not ks.is_empty():
					w.gk = _q(ks[i]); found = true
				else:
					var rg: Array = st.get("range", [-5, 5])
					var stp := _q(st.get("step", "1"))
					var k2 := float(rg[0])
					while k2 <= float(rg[1]) + 1e-9:
						w.gk = k2
						var n: int = w.cross_count() if mode == "hline" else w.line_count()
						if n == int(st.goals[i]):
							found = true
							break
						k2 += stp
				if not found:
					_issue("%s 找不到 %d 個交點的 k" % [mode, int(st.goals[i])])
				lv._on_graph_move()
				lv._graph_submit(st)
				await frames(1)
			return
		"wick":
			for gl in st.goals:
				w.gh = _q(gl[1][0])
				lv._on_graph_move()
				await _check(lv, "燈芯")
				lv._graph_submit(st)
				await frames(1)
			return
		"cmatch":
			w.ga = _q(st.target.a); w.gp = _q(st.target.p); w.gh = _q(st.target.h); w.gk = _q(st.target.k)
		"mirror":
			w.bx = float(st.target[0]); w.by = float(st.target[1])
		"far":
			w.gz = int(st.get("zmax", 4))
		"tangent":
			w.gm = float(st.target)
		"pick":
			w.sel_seg = Array(st.segs).duplicate()
			w.sel_pt = Array(st.ptsin).duplicate()
		"wave":
			var n2: int = st.pts.size()
			lv._wave_pick(0 if int(st.lead) > 0 else 1)
			for kk in range(1, n2 + 1):
				await frames(1)
				lv._wave_pick(0 if int(st.mult[n2 - kk]) % 2 == 1 else 1)
			return
		"pgate":
			var rg2: Array = st.get("arange", [-6, 6])
			var okk := false
			for a2 in range(int(rg2[0]), int(rg2[1]) + 1):
				w.ga = float(a2)
				if w.marks_inside() == st.marks.size():
					okk = true
					break
			if not okk:
				_issue("pgate 找不到 a")
		_:
			_issue("不認得的 graph：%s" % mode)
			lv._step_done(st, "")
			return
	lv._on_graph_move()
	await _check(lv, "%s 對準之後" % mode)
	lv._graph_submit(st)


# ---------------- 速算 ----------------
func _play_speed(lv) -> void:
	var guard := 0
	while lv.sp_i < lv.problems.size() and guard < 20:
		guard += 1
		var i0: int = lv.sp_i
		await _check(lv, "速算第 %d 題" % (i0 + 1))
		var pb: Dictionary = lv.problems[i0]
		if pb.has("choices"):
			lv._speed_pick(int(pb.correct))
		else:
			lv.slot_vals = (Array(pb.answers) if pb.has("answers") else [pb.ans]).map(func(a): return String(a).replace("-", "−"))
			lv._refresh_fill()
			lv._fill_submit()
		await frames(2)
		if lv.sp_i == i0:
			_issue("速算第 %d 題答對了卻沒有前進（%s）" % [i0 + 1, String(pb.eq).replace("\n", " ")])
			break
