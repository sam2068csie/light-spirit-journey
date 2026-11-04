extends "test_base.gd"
## 真的「玩」一次：每一步都用和玩家一樣的方式作答（點選項、按數字、拖到正確的位置、點河段……），
## 不直接呼叫 _step_done。每一步作答前、填好答案後都檢查版面：
##   ・右邊的卡片不能超出畫面、裡面的東西不能超出卡片、按鈕上的字不能超出按鈕
##   ・中間「正在作答」的框不能壓到下方的圖
##   ・作答之後一定要進到下一步（卡住就是題目或答案有問題）
## 環境變數 ONLY=P1,P2 只玩某幾關；SHOTS=資料夾 會把有問題的畫面存下來（需要有畫面，不能 --headless）

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
	print("  %s 玩完了" % lid)


# ---------------- 版面檢查 ----------------
func _check(lv, when: String) -> void:
	await frames(2)
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
	var fv = lv.fview
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
					if font.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > b.size.x - 4.0:
						_issue("%s：按鈕的字超出（%s）" % [when, ln.left(30)])
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
				lv._step_done(st, "")
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
			lv.slot_vals = Array(pb.get("answers", [pb.ans])).map(func(a): return String(a).replace("-", "−"))
			lv._refresh_fill()
			lv._fill_submit()
		await frames(2)
		if lv.sp_i == i0:
			_issue("速算第 %d 題答對了卻沒有前進（%s）" % [i0 + 1, String(pb.eq).replace("\n", " ")])
			break
