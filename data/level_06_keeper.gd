extends "level_04_alchemy.gd"
## 第六大關「真數守門員」（對應講義 重點三：對數方程式）
## 用法：主選單會自動開啟它。需要同資料夾的 level_04_alchemy.gd、level_03_scale.gd、level_02_forge.gd、
## level_01_light_bridge.gd（共用引擎）與 level06_bank.gd（題庫）。
##
## 沿用前面「一步一步算」的方式（選擇、數字鍵盤、施放法則、t 的篩選），再加上：
##   gate   真數守門員：每個解都像一顆球射向球門，學生代回原式檢查，決定「放行」或「擋下」。
##          確認之後，合格的球進網，不合的被手套擋出去，下面寫出代進去的結果。

const Bank6 := preload("level06_bank.gd")
const CHAPTERS6 := [
	{"ch": 1, "name": "第一章．守門基本功", "topic": "同底比較、化同底、換元與檢查", "color": UITheme.GOLD},
	{"ch": 2, "name": "第二章．大師的球門", "topic": "取對數、根與係數、互換", "color": Color("ff9f5a")},
]


func level_id() -> String:
	return "L6"

func level_title() -> String:
	return "真數守門員"

func level_subtitle() -> String:
	return "對數方程式"

func level_chapters() -> Array:
	return CHAPTERS6

func bank_slots() -> Array:
	return Bank6.slots()

func stage_style() -> Dictionary:
	return {"sky_top": Color("0f2418"), "sky_bot": Color("0b1a2a"), "scenery": "none"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．大師的球門", "button": "進入大師的球門  ▶",
		"text": "大師的三記絕招：\n\n" \
			+ "・x^{log x} 這種次方上的 log：兩邊取 log\n" \
			+ "・只問兩根之積：根與係數，log α + log β = log αβ\n" \
			+ "・x^{log_{2} 3} = 3^{log_{2} x}：互換再換元\n\n" \
			+ "不管用哪一招，最後都要守好球門！"}


func _ensure_fview() -> void:
	if fview == null:
		fview = GoalView.new()
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.log_title = "解題紀錄"
		fview.work_word = "解題"
		fview.speed_title = "守門速算"
		(fview as ScaleView).line_toggled.connect(func(): Game.of(self).play("bell", Game.semi(7), -9.0))


func _gv() -> GoalView:
	return fview as GoalView


func _forge_step() -> void:
	super()
	if si >= steps.size():
		return
	var st: Dictionary = steps[si]
	if st.kind == "gate":
		_clear(predict_box)
		predicting = false
		keypad_on = false
		_build_filter(st)
		go_btn.text = "確認判決"
		_gv().begin_gate(st)
		_gv().gate_keep = filter_keep.duplicate()


func _refresh_filter() -> void:
	super()
	if si < steps.size() and steps[si].kind == "gate":
		_gv().gate_keep = filter_keep.duplicate()


func _custom_go() -> void:
	if r.type == "forge" and si < steps.size() and steps[si].kind == "gate":
		_filter_submit()
		return
	super()


func _step_done(st: Dictionary, why: String) -> void:
	if st.kind == "gate":
		_gv().gate_done()
		Game.of(self).play("bell", Game.semi(14), -8.0)
	super(st, why)


func _custom_reveal(msg: String) -> void:
	if r.type == "forge":
		for j in range(si, steps.size()):
			if steps[j].kind == "gate":
				_gv().begin_gate(steps[j])
				_gv().gate_keep = Array(steps[j].keep).duplicate()
				_gv().gate_done()
	super(msg)


func _speed_gen(kind: String, n: int) -> Array:
	return Bank6.gen_problems(kind, n)


# ================= 夜間球場（畫在舞台上） =================

class GoalView extends AlchemyView:
	const GRASS := Color("3fbf6a")
	const GOLDB := UITheme.GOLD

	var gate_on := false
	var gate_st := {}
	var gate_keep: Array = []
	var gate_t := -10.0

	func reset_alchemy() -> void:
		super()
		gate_on = false
		gate_st = {}
		gate_keep = []
		gate_t = -10.0

	func begin_gate(st: Dictionary) -> void:
		gate_on = true
		gate_st = st
		gate_keep = []
		gate_t = -10.0

	func gate_done() -> void:
		gate_t = t
		var R := _gate_rect()
		_burst(Vector2(R.end.x - 90, R.position.y + 90), GOLDB, 26)

	func _graph_on() -> bool:
		return gate_on or super()

	func _draw_mini_graph(font: Font, rect: Rect2) -> void:
		if gate_on:
			_draw_gate(font, rect)
		else:
			super(font, rect)

	func _gate_rect() -> Rect2:
		return Rect2(36, size.y - 214, size.x - 72, 190)

	## 夜間球場：探照燈、草皮條紋、看台上的燈點
	func _draw_forge_bg() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("0c1a24"), Color("0c1a24"), Color("0e2a1c"), Color("0e2a1c")]))
		# 看台的燈點
		for i in 60:
			var x := fposmod(i * 0.618, 1.0) * w
			var y := 26.0 + fposmod(i * 0.377, 1.0) * 70.0
			var a := 0.10 + 0.10 * (0.5 + 0.5 * sin(t * 2.0 + i * 1.7))
			UITheme.dot(self, Vector2(x, y), 1.4, Color(1, 0.95, 0.8, a))
		# 探照燈
		for k in 2:
			var src := Vector2(-20.0 if k == 0 else w + 20.0, -10.0)
			var sway := 0.06 * sin(t * 0.4 + k * 2.0)
			var dir := (Vector2(w * (0.62 if k == 0 else 0.38), h) - src).rotated(sway)
			var perp := dir.normalized().orthogonal() * 120.0
			draw_polygon(PackedVector2Array([src, src + dir + perp, src + dir - perp]),
				PackedColorArray([Color(1, 1, 0.85, 0.07), Color(1, 1, 0.85, 0.0), Color(1, 1, 0.85, 0.0)]))
		# 草皮
		var gy := h * 0.64
		for i in 7:
			var y0 := lerpf(gy, h, i / 7.0)
			var y1 := lerpf(gy, h, (i + 1) / 7.0)
			var c := GRASS if i % 2 == 0 else GRASS.darkened(0.15)
			draw_rect(Rect2(0, y0, w, y1 - y0), Color(c.r, c.g, c.b, 0.10 + 0.03 * i))
		draw_line(Vector2(0, gy), Vector2(w, gy), Color(1, 1, 1, 0.12), 2.0)
		var ma := clampf(1.0 - (t - miss_t) / 0.5, 0.0, 1.0)
		if ma > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.25, 0.16 * ma))

	## 球門＋候選解（足球）
	func _draw_gate(font: Font, R: Rect2) -> void:
		draw_style_box(UITheme.boxc(Color(0.03, 0.10, 0.06, 0.7), 12, Color(0.5, 1, 0.65, 0.3), 1, 0), R.grow(6))
		draw_string(font, R.position + Vector2(4, -10), "真數守門員：把解代回原式，合格才能進球門", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13),
			Color(0.75, 1, 0.8, 0.8))
		MathLabel.draw_on(self, font, R.position.x + (R.size.x - 190) / 2.0, R.position.y + 24, "條件：" + str(gate_st.get("conds", "")), UITheme.fs(15),
			Color(1, 0.95, 0.75, 0.9))
		# 球門
		var G := Rect2(R.end.x - 176, R.position.y + 30, 150, 130)
		for i in 7:
			var x := G.position.x + G.size.x * i / 6.0
			draw_line(Vector2(x, G.position.y), Vector2(x + 10, G.end.y), Color(1, 1, 1, 0.16), 1.0)
		for j in 6:
			var y := G.position.y + G.size.y * j / 5.0
			draw_line(Vector2(G.position.x, y), Vector2(G.end.x, y), Color(1, 1, 1, 0.16), 1.0)
		draw_line(G.position, Vector2(G.position.x, G.end.y), Color.WHITE, 5.0)
		draw_line(Vector2(G.end.x, G.position.y), G.end, Color.WHITE, 5.0)
		draw_line(G.position, Vector2(G.end.x, G.position.y), Color.WHITE, 5.0)
		# 守門員的手套
		var glove := Vector2(G.position.x - 24, G.get_center().y + 18 * sin(t * 2.2))
		_draw_glove(glove)
		var cands: Array = gate_st.get("cands", [])
		var n := cands.size()
		var done := gate_t > 0.0
		var u := clampf((t - gate_t) / 0.9, 0.0, 1.0) if done else 0.0
		var ease := 1.0 - pow(1.0 - u, 3.0)
		var lane := (G.position.x - 60.0 - R.position.x) / float(maxi(n, 1))
		for i in n:
			var home := Vector2(R.position.x + lane * (i + 0.5), R.position.y + 98)
			var keep := i < gate_keep.size() and bool(gate_keep[i])
			var pos := home
			var alpha := 1.0
			if done:
				if keep:
					var target := Vector2(G.position.x + 30 + 90.0 * (i + 0.5) / n, G.position.y + 70)
					pos = home.lerp(target, ease) + Vector2(0, -60.0 * sin(ease * PI))
				else:
					# 被手套擋出去：往左上飛走、淡出
					pos = home + Vector2(-50.0 * ease, -90.0 * ease + 30.0 * ease * ease)
					alpha = 1.0 - 0.85 * ease
			else:
				pos += Vector2(0, 3.0 * sin(t * 3.0 + i))
			var lab := "%s = %s" % [gate_st.get("var", "x"), str(cands[i]).replace("-", "−")]
			MathLabel.draw_on(self, font, home.x, home.y - 36, lab, UITheme.fs(17), Color(1, 1, 1, 0.95))
			_draw_ball(pos, 20.0, alpha, t * (4.0 if not done else 9.0) + i)
			if done and not keep:
				draw_line(home + Vector2(-14, 26), home + Vector2(14, 54), Color(UITheme.BAD.r, UITheme.BAD.g, UITheme.BAD.b, 0.9), 3.0)
				draw_line(home + Vector2(14, 26), home + Vector2(-14, 54), Color(UITheme.BAD.r, UITheme.BAD.g, UITheme.BAD.b, 0.9), 3.0)
			var tag := "放行" if keep else "擋下"
			var tc := UITheme.GOOD if keep else UITheme.BAD
			if i >= gate_keep.size():
				tag = "？"
				tc = UITheme.TEXT_DIM
			if not done:
				draw_string(font, home + Vector2(-40, 48), tag, HORIZONTAL_ALIGNMENT_CENTER, 80, UITheme.fs(15), tc)
			else:
				var checks: Array = gate_st.get("checks", [])
				if i < checks.size():
					MathLabel.draw_on(self, font, home.x, home.y + 72, checks[i], UITheme.fs(13), tc.lightened(0.2))
		if done and u >= 1.0:
			var pa := 0.6 + 0.4 * sin(t * 4.0)
			draw_string(font, Vector2(G.position.x - 10, G.end.y + 22), "合格的解進門！", HORIZONTAL_ALIGNMENT_CENTER, G.size.x + 20, UITheme.fs(15),
				Color(GOLDB.r, GOLDB.g, GOLDB.b, pa))

	func _draw_ball(p: Vector2, rr: float, a: float, spin: float) -> void:
		UITheme.dot(self, p + Vector2(3, 4), rr, Color(0, 0, 0, 0.25 * a))
		UITheme.dot(self, p, rr, Color(0.97, 0.97, 0.97, a))
		var dark := Color(0.12, 0.12, 0.15, a)
		UITheme.dot(self, p, rr * 0.32, dark)
		for k in 5:
			var ang := spin * 0.3 + k * TAU / 5.0
			UITheme.dot(self, p + Vector2(cos(ang), sin(ang)) * rr * 0.72, rr * 0.18, dark)
		draw_arc(p, rr, 0, TAU, 32, Color(0.6, 0.6, 0.65, a), 1.5, true)

	func _draw_glove(p: Vector2) -> void:
		var c := Color(1, 0.78, 0.35)
		draw_rect(Rect2(p.x - 11, p.y - 6, 22, 26), c)
		for k in 4:
			draw_rect(Rect2(p.x - 11 + k * 5.6, p.y - 20, 4.6, 16), c)
		draw_rect(Rect2(p.x - 18, p.y + 2, 8, 12), c)
		draw_rect(Rect2(p.x - 11, p.y + 16, 22, 6), Color(0.3, 0.6, 1.0))
