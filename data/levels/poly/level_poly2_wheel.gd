extends "res://data/levels/engine/step_level.gd"
## 多項式 第二大關「綜合除法水車」（對應講義 4-1 重點二：多項式的除法）
## 引擎是 step_level.gd（一步一步推導），題庫在 poly2_bank.gd。
##
## 這一關多了：
##   ・綜合除法的填空（題庫的 _synth）：下方照課本的寫法畫出三排的綜合除法（k 寫在右邊、帶正負號、餘式圈起來）。
##     學生用數字鍵盤填最下面一排；每填一格，水就流上去算出「a × 這一格」放到下一行的中間那排，
##     下一格 = 上面的係數 + 中間的數。填錯的格子變紅。答對後算式留在下方，接著讀商式和餘式。
##   ・水車洞窟的背景（兩側的小瀑布、水面的波光）
##   ・速算：三次式除以 x − a 的餘式或商式的常數項

const BankP2 := preload("res://data/levels/poly/poly2_bank.gd")
const WATER := UITheme.CYAN

const CHAPTERS_P2 := [
	{"ch": 1, "name": "第一章．水車入門", "topic": "綜合除法、除式 ax − b、除法原理", "color": UITheme.CYAN},
	{"ch": 2, "name": "第二章．深層水車", "topic": "除式是二次式、三步驟求值、連續綜合除法", "color": UITheme.BLUE},
]


func level_id() -> String:
	return "P2"

func level_title() -> String:
	return "綜合除法水車"

func level_subtitle() -> String:
	return "多項式的除法"

func level_chapters() -> Array:
	return CHAPTERS_P2

func bank_slots() -> Array:
	return BankP2.slots()

func step_color() -> Color:
	return WATER

func radicals_ok() -> bool:
	return true

func stage_style() -> Dictionary:
	return {"sky_top": Color("0f1a33"), "sky_bot": Color("0a1224"), "scenery": "none", "ambient": "currents"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．深層水車", "button": "進入深層水車  ▶",
		"text": "深層的水車更大、水道更多：\n\n" \
			+ "・除式是二次式：長除法，餘式最多一次\n" \
			+ "・兩根都是根 ⇒ 能整除（餘式是 0）\n" \
			+ "・x = √2 − 1 代進五次式：先除，再代餘式\n" \
			+ "・連續綜合除法：把多項式改用 (x − h) 來寫\n\n" \
			+ "水車轉起來囉！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = WheelView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "水車速算"


func _wv() -> WheelView:
	return fview as WheelView


# ================= 綜合除法的填空 =================

func _forge_step() -> void:
	if fview != null:
		_wv().on = false
	super()


func _refresh_fill() -> void:
	super()
	if fview == null or r.get("type", "") != "forge" or not fill_step.has("synth"):
		return
	var wv := _wv()
	wv.on = true
	wv.spec = fill_step.synth
	wv.vals = slot_vals.duplicate()
	wv.bad = slot_bad.duplicate()
	wv.cur = cur_slot
	wv.queue_redraw()


func _step_done(st: Dictionary, why: String) -> void:
	if fview != null and st.has("synth"):
		var wv := _wv()
		wv.on = false
		wv.done_spec = st.synth
		wv.done_vals = Array(st.answers).map(func(s): return String(s).replace("-", "−"))
		wv.burst_center()
	super(st, why)


func _custom_reveal(msg: String) -> void:
	if fview != null and r.type == "forge":
		for j in range(si, steps.size()):
			if steps[j].has("synth"):
				_wv().on = false
				_wv().done_spec = steps[j].synth
				_wv().done_vals = Array(steps[j].answers).map(func(s): return String(s).replace("-", "−"))
	super(msg)


# ================= 速算 =================

func _speed_show() -> void:
	var pb: Dictionary = problems[sp_i]
	fview.show_speed(pb.eq, sp_i, problems.size(), streak)
	step_label.text = UITheme.step_bar(_steps(), 0)
	if sp_i > 0:
		story_label.visible = false
	_build_fill({"name": "速算", "q": pb.q, "template": pb.template, "answers": [pb.ans], "mode": "ordered",
		"nudge": pb.nudge, "tag": pb.tag, "line": ""})


func _speed_tag() -> String:
	return BankP2.T_SYN


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算題：三次式除以 x − a。{eq, q, template, ans, nudge, tag}
static func gen_problems(_kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var coef := [randi_range(1, 2), randi_range(-5, 5), randi_range(-6, 6), randi_range(-8, 8)]
		var a: int = [-2, -1, 1, 2, 3].pick_random()
		var row := BankP2.synth_row(coef, [a, 1])
		var what := randi() % 2
		var ans: Array = row[3] if what == 0 else row[2]
		if absi(ans[0]) > 60 or coef[1] == 0 and randf() < 0.7:
			continue
		var eq := "%s 除以 %s" % [BankP2.poly_text(coef), BankP2.divisor_text([a, 1])]
		if seen.has(eq + str(what)):
			continue
		seen[eq + str(what)] = true
		var pb := {"eq": eq + "\n" + ["餘式 = ？", "商式的常數項 = ？"][what], "ans": BankP2._qa(ans), "tag": BankP2.T_SYN}
		pb.q = ["用綜合除法算出餘式。", "用綜合除法算出商式的常數項（最下面一排的倒數第二格）。"][what]
		pb.template = ["餘式 = [0]", "商式的常數項 = [0]"][what]
		pb.nudge = "左邊寫 %d；每一格 = 上面的係數 + %d × 前一格。" % [a, a]
		out.append(pb)
	return out


# ================= 畫面：水車洞窟的推導台 + 綜合除法 =================

class WheelView extends ForgeView:
	const AQUA := UITheme.CYAN
	const GOLDC := UITheme.GOLD

	var on := false              # 正在填綜合除法
	var spec := {}               # {coef, a}
	var vals: Array = []         # 學生填的最下面一排（字串）
	var bad: Array = []
	var cur := 0
	var done_spec := {}          # 答對之後留在下方的算式
	var done_vals: Array = []

	func setup(round: Dictionary) -> void:
		super(round)
		on = false
		spec = {}
		done_spec = {}
		done_vals = []

	func _graph_on() -> bool:
		return on or not done_spec.is_empty() or super()

	func _draw() -> void:
		super()
		if on and kind == "forge" and intro < 0.0:
			var h := _table_h()
			_draw_table(get_theme_default_font(), Rect2(36, size.y - h - 12.0, size.x - 72, h), spec, vals, true)

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if on:
			return
		if not done_spec.is_empty():
			if done_spec.has("base") or done_spec.has("m"):
				var h := _table_h(done_spec)
				rect = Rect2(36, size.y - h - 12.0, size.x - 72, h)
			_draw_table(font, rect, done_spec, done_vals, false)
		else:
			super(font, rect)

	## 水車洞窟：深藍的底、兩側的小瀑布、底部的水光
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("0f1a33"), Color("0f1a33"), Color("0a1224"), Color("0a1224")]))
		var falls := PackedVector2Array()
		for side in [14.0, w - 14.0]:
			for k in 18:
				var y := fposmod(t * 160.0 + k * 41.0, h + 40.0) - 20.0
				falls.append_array([Vector2(side + 3.0 * sin(k * 1.7), y), Vector2(side + 3.0 * sin(k * 1.7), y + 16.0)])
		draw_multiline(falls, Color(0.5, 0.8, 1.0, 0.18), 2.0)
		var glow := 0.07 + 0.02 * sin(t * 1.3)
		draw_polygon(PackedVector2Array([Vector2(0, h * 0.75), Vector2(w, h * 0.75), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color(0.3, 0.7, 1.0, 0.0), Color(0.3, 0.7, 1.0, 0.0), Color(0.3, 0.6, 1.0, glow), Color(0.3, 0.6, 1.0, glow)]))
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	## 「3」「−2」「1/2」→ [分子, 分母]；看不懂就回傳空陣列
	static func _pq(s: String) -> Array:
		var v := s.strip_edges().replace("−", "-")
		if v == "" or v == "-":
			return []
		var neg := v.begins_with("-")
		if neg:
			v = v.substr(1)
		var parts := v.split("/")
		if parts.size() > 2:
			return []
		for p in parts:
			if not p.is_valid_int():
				return []
		var d := int(parts[1]) if parts.size() == 2 else 1
		if d == 0:
			return []
		return [-int(parts[0]) if neg else int(parts[0]), d]

	static func _txt(q: Array) -> String:
		var P := preload("res://data/levels/poly/poly2_bank.gd")
		return P._qs(P._q(q[0], q[1]))

	## 帶正負號的寫法（課本的寫法）：+5、−2、+1/2、+0
	static func _sg(q: Array) -> String:
		var t := _txt(q)
		return t if t.begins_with("−") else "+" + t

	## 第一排（分數也可以）除以 x − k 的第三排
	static func _row(top: Array, k: Array) -> Array:
		var P := preload("res://data/levels/poly/poly2_bank.gd")
		var b := [top[0]]
		for i in range(1, top.size()):
			b.append(P._qadd(top[i], P._qmul(k, b[i - 1])))
		return b

	## 這個算式一共有幾排
	static func rows_of(sp: Dictionary) -> int:
		return 1 + 2 * (int(sp.get("chain", 0)) + 1) + (1 if sp.has("m") else 0)

	## 填綜合除法時，下方算式的高度（排數越多越高）
	func _table_h(sp: Dictionary = {}) -> float:
		var n := rows_of(spec if sp.is_empty() else sp)
		return clampf((30.0 + n * 44.0) if n <= 4 else (24.0 + n * 37.0), 180.0, 300.0)

	func _bottom_limit() -> float:
		if on:
			return size.y - _table_h() - 24.0
		if done_spec.has("base") or done_spec.has("m"):
			return size.y - _table_h(done_spec) - 24.0       # 疊起來的算式比較高，下方留大一點
		return super()

	## 綜合除法的算式（課本的寫法）：
	##   第一排：被除式的係數（帶正負號）　｜ k 寫在右邊、對齊第二排
	##   第二排：前一格的第三排 × k（往右一格）
	##   ─────────（橫線）
	##   第三排：上下相加；最後一個是餘式（用直線隔開、圈起來）
	##   連續使用：商繼續往下除，算式一路往下疊；除式是 mx + n：左邊寫 m，第四排是商除以 m
	func _draw_table(font: Font, rc: Rect2, sp: Dictionary, row: Array, live: bool) -> void:
		var P := preload("res://data/levels/poly/poly2_bank.gd")
		var k: Array = sp.a
		var chain := int(sp.get("chain", 0))
		var divrow: bool = sp.get("divrow", false)
		var base: Array = sp.get("base", sp.coef)
		var nrows := rows_of(sp)
		var rh := clampf((rc.size.y - 30.0) / nrows, 20.0, 44.0)
		var fs := int(clampf(rh * 0.56, 12.0, 22.0))
		var L0 := base.size()
		var cw := minf(72.0, (rc.size.x - 200.0) / (L0 + 0.5))
		# 算式放在中間（左邊留給水車和 mx + n 的 m）
		var x0 := rc.get_center().x - cw * L0 / 2.0 + cw / 2.0 + 10.0
		var y_of := func(r: int) -> float: return rc.position.y + 6.0 + rh * (r + 0.78)
		var line_c := Color(1, 1, 1, 0.55)
		# 水車（裝飾）：填得越多轉得越快
		var filled := 0
		for v in row:
			if String(v) != "":
				filled += 1
		var wr := clampf(rh * 0.9, 18.0, 30.0)
		var wc := Vector2(x0 - cw * 1.6 - wr, rc.position.y + rc.size.y * 0.4)
		var rot := t * (0.4 + 0.5 * filled) if live else t * 0.5
		draw_arc(wc, wr, 0, TAU, 36, Color(0.6, 0.45, 0.3, 0.85), 3.0, true)
		var spokes := PackedVector2Array()
		for q in 8:
			var ang := rot + q * PI / 4.0
			spokes.append_array([wc, wc + Vector2(cos(ang), sin(ang)) * wr])
		draw_multiline(spokes, Color(0.6, 0.45, 0.3, 0.75), 2.0)
		UITheme.dot(self, wc, 3.5, GOLDC)
		# 第一排
		var top: Array = base.map(func(c): return P._q(int(c)))
		for i in top.size():
			MathLabel.draw_on(self, font, x0 + cw * i, y_of.call(0), _sg(top[i]), fs, Color(1, 0.97, 0.9))
		var r := 0
		var last_bot: Array = []
		for j in chain + 1:
			var L := top.size()
			var exact := _row(top, k)
			var cur_live := live and j == chain and not divrow
			var bot: Array = []          # 這一次的第三排：[字串, 數值或空陣列]
			for i in L:
				if cur_live:
					var sv := String(row[i]) if i < row.size() else ""
					var q := _pq(sv)
					bot.append([sv, q])
				else:
					bot.append([_sg(exact[i]), exact[i]])
			var y_top: float = y_of.call(r)
			var y_mid: float = y_of.call(r + 1)
			var y_bot: float = y_of.call(r + 2)
			var y_line := y_mid + rh * 0.28
			# 第二排：前一格 × k
			for i in range(1, L):
				var prev: Array = bot[i - 1][1]
				if not prev.is_empty():
					MathLabel.draw_on(self, font, x0 + cw * i, y_mid, _sg(P._qmul(k, P._q(prev[0], prev[1]))), fs, Color(0.55, 0.85, 1.0))
					if cur_live:
						draw_line(Vector2(x0 + cw * (i - 1) + cw * 0.25, y_bot - fs * 0.9), Vector2(x0 + cw * i - cw * 0.25, y_mid + 4.0),
							Color(0.45, 0.75, 1.0, 0.4), 1.5, true)
			# 右邊的直線和 k
			var xb := x0 + cw * (L - 0.5) + 4.0
			draw_line(Vector2(xb, y_top - rh * 0.85), Vector2(xb, y_line), line_c, 2.0)
			MathLabel.draw_on(self, font, xb + 10.0 + MathLabel.text_width(font, _sg(k), fs) / 2.0, y_mid, _sg(k), fs, GOLDC)
			# 橫線
			draw_line(Vector2(x0 - cw * 0.5, y_line), Vector2(xb, y_line), line_c, 2.0)
			# 餘式：左邊用直線隔開，圈起來
			var xr := x0 + cw * (L - 1)
			draw_line(Vector2(xr - cw * 0.5, y_line), Vector2(xr - cw * 0.5, y_bot + rh * 0.25), line_c, 1.5)
			# 第三排
			for i in L:
				var x := x0 + cw * i
				var sv2: String = bot[i][0]
				var q2: Array = bot[i][1]
				var shown := (_sg(q2) if not q2.is_empty() else sv2.replace("-", "−")) if sv2 != "" else ""
				if cur_live:
					var bc := UITheme.BAD if (i < bad.size() and bad[i]) else (GOLDC if i == cur else Color(1, 1, 1, 0.25))
					var box := Rect2(x - cw * 0.42, y_bot - rh * 0.6, cw * 0.84, rh * 0.8)
					if sv2 == "":
						draw_rect(box, Color(bc.r, bc.g, bc.b, 0.08))
					draw_rect(box, bc, false, 2.0 if i == cur else 1.0)
				if shown != "":
					var col := UITheme.BAD if (cur_live and i < bad.size() and bad[i]) else (AQUA.lightened(0.3) if i < L - 1 else GOLDC)
					MathLabel.draw_on(self, font, x, y_bot, shown, fs, col)
				var circ := i == L - 1 or (sp.has("base") and j == chain and L == 2 and i == 0 and not cur_live)
				if circ and shown != "":
					draw_arc(Vector2(x, y_bot - fs * 0.32), minf(cw * 0.46, rh * 0.55), 0, TAU, 28, Color(1, 0.85, 0.45, 0.85), 1.5, true)
			last_bot = exact
			top = exact.slice(0, L - 1)
			r += 2
		# 除式是 mx + n：左邊寫 m、框住第三排的商，第四排 = 商 ÷ m
		if sp.has("m"):
			var m := int(sp.m)
			var y3: float = y_of.call(r)
			var y4: float = y_of.call(r + 1)
			var nq := last_bot.size() - 1
			MathLabel.draw_on(self, font, x0 - cw * 0.9, y3, "+%d" % m, fs, GOLDC)
			draw_rect(Rect2(x0 - cw * 0.5, y3 - rh * 0.78, cw * nq, rh * 0.98), Color(1, 0.85, 0.45, 0.6), false, 1.5)
			for i in nq:
				var x := x0 + cw * i
				var want: Array = P._qmul(last_bot[i], P._q(1, m))
				var sv3 := ""
				var q3: Array = []
				if divrow and live:
					sv3 = String(row[i]) if i < row.size() else ""
					q3 = _pq(sv3)
					var bc2 := UITheme.BAD if (i < bad.size() and bad[i]) else (GOLDC if i == cur else Color(1, 1, 1, 0.25))
					var box2 := Rect2(x - cw * 0.42, y4 - rh * 0.6, cw * 0.84, rh * 0.8)
					if sv3 == "":
						draw_rect(box2, Color(bc2.r, bc2.g, bc2.b, 0.08))
					draw_rect(box2, bc2, false, 2.0 if i == cur else 1.0)
				elif divrow:
					q3 = want
					sv3 = _sg(want)
				var shown3 := (_sg(q3) if not q3.is_empty() else sv3.replace("-", "−")) if sv3 != "" else ""
				if shown3 != "":
					MathLabel.draw_on(self, font, x, y4, shown3, fs, UITheme.GOOD.lightened(0.2))
		# 說明（只有一次的時候）
		if chain == 0 and not sp.has("m"):
			var cap_fs := UITheme.fs(13)
			var yc: float = y_of.call(2) + rh * 0.55
			var L1 := base.size()
			UITheme.text_ol(self, font, Vector2(x0 + cw * (L1 - 2) / 2.0 - 60.0, yc), "商式的係數", HORIZONTAL_ALIGNMENT_CENTER, 120, cap_fs, Color(0.6, 0.85, 1.0, 0.8))
			UITheme.text_ol(self, font, Vector2(x0 + cw * (L1 - 1) - 30.0, yc), "餘式", HORIZONTAL_ALIGNMENT_CENTER, 60, cap_fs, Color(1, 0.85, 0.5, 0.85))
