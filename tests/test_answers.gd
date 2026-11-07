extends "test_base.gd"
## 「其實也對」的答案要算對：直接在關卡裡跳到那一步，填入另一種寫法，按送出，看有沒有進到下一步
##   ・平方、±、絕對值裡的格子：正負號都可以（[0]^{2}、k = ±[0]、|[0]m|）
##   ・分點公式的權重：成比例就對（\frac{2A + 6B}{8} = \frac{A + 3B}{4}）
##   ・點斜式：用直線上的任何一點都對（不一定要用題目說的那一點）
##   ・共線：用另一個已知點列斜率也對
##   ・相乘的兩格可以互換、方程式的係數成比例
## 同時確認錯的答案還是會被判錯（不要放得太寬）。新增「另一種也對的寫法」之後，把它加進 CASES。

const Units := preload("res://data/core/units.gd")
const Paths := preload("res://data/core/paths.gd")
const SL := preload("res://data/levels/engine/step_level.gd")

## [關卡, 題組 id, 題目編號, 第幾步, 填的答案, 應該算對嗎]
const CASES := [
	# 平方的格子：正負號都可以
	["C1", "mid", 0, 2, ["−6", "4"], true],
	["C1", "mid", 0, 2, ["−4", "−6"], true],
	["C1", "mid", 0, 2, ["5", "4"], false],
	["C1", "mid", 1, 2, ["−6", "−8"], true],
	["C1", "circum", 0, 2, ["−4", "−2", "6"], true],
	["C1", "circum", 0, 2, ["4", "2", "−6"], false],
	["C5", "arch", 0, 1, ["−24"], true],
	# k = ±[0]、|[0]m|
	["C2", "system", 0, 2, ["4", "−2"], true],
	["C6", "rel", 0, 2, ["−25"], true],
	["C6", "rel", 0, 2, ["5"], false],
	["C7", "shadow", 0, 0, ["−5"], true],
	# 分點公式的權重成比例
	["C1", "divide", 0, 1, ["2", "6", "8"], true],
	["C1", "divide", 0, 1, ["3", "1", "4"], false],
	["C1", "centroid", 1, 1, ["2", "4", "6"], true],
	["C1", "bisector", 0, 2, ["4", "2", "6"], true],
	["C1", "bisector", 0, 2, ["1", "2", "3"], false],
	# 3 × 6 和 6 × 3
	["C1", "divide", 1, 1, ["4", "2", "6", "3"], true],
	["C1", "divide", 1, 1, ["4", "3", "2", "6"], false],
	# 共線：用 B 列斜率也對
	["C1", "collinear", 0, 2, ["−1", "2", "0"], true],
	["C1", "collinear", 0, 2, ["5", "−1", "1"], false],
	["C1", "collinear", 1, 2, ["6", "−1", "3", "−2"], true],
	["C1", "collinear", 1, 2, ["6", "−1", "3", "−4"], false],
	# 點斜式：直線上的任何一點
	["C2", "pointslope", 0, 0, ["4", "4"], true],
	["C2", "pointslope", 0, 0, ["4", "3"], false],
	["C2", "pointslope", 1, 1, ["2", "2", "3"], true],
	["C2", "pointslope", 1, 1, ["2", "3", "3"], false],
	["C2", "twopoint", 0, 1, ["−2", "3"], true],
	["C2", "shift", 0, 2, ["−7", "0", "7"], true],
	["C2", "shift", 0, 2, ["−7", "0", "6"], false],
	["C3", "perpbis", 0, 2, ["0", "1", "0"], true],
	["C3", "perpbis", 0, 2, ["3", "−1", "3"], false],
	["C3", "light", 0, 2, ["2", "6", "5"], true],
	["C3", "light", 0, 2, ["2", "6", "4"], false],
	# 方程式的係數成比例
	["C8", "chord2", 0, 2, ["1", "1"], true],
	["C8", "chord2", 0, 2, ["1", "2"], false],
	# 三角函數：兩項相加可以換順序、方程式的係數成比例
	["G2", "wheel", 1, 1, ["20√3", "40"], true],
	["G2", "wheel", 1, 1, ["20√3", "20"], false],
	["G6", "ratio", 0, 1, ["4", "6", "−4"], true],
	["G6", "ratio", 0, 1, ["−2", "−3", "2"], true],
	["G6", "ratio", 0, 1, ["2", "3", "2"], false],
	# 原本就有的：分數、小數、沒化簡的根號
	["C3", "parallel", 0, 2, ["7.5", "5/2"], true],
	["C6", "chord", 1, 4, ["√80"], true],
	["C1", "mid", 0, 3, ["52", "√52"], true],
]

## 多項式的拼積木：另一種也對的拼法不扣能量（只提醒照題目的順序），錯的還是扣
## [關卡, 題組 id, 題目編號, 第幾步, 積木（用 "+" 分項）, "ok" 算對／"alt" 只提醒／"bad" 算錯]
const BLOCKS := [
	["P3", "ladder", 2, 0, ["A", "(x − 3)", "(x + 2)", "+", "3x + 7"], "alt"],
	["P3", "ladder", 2, 0, ["x + 3", "+", "(x^{2} + x − 2)", "A"], "ok"],
	["P3", "ladder", 2, 0, ["A", "(x − 3)", "+", "3x + 7"], "bad"],
	["P4", "twodiv", 0, 0, ["(x^{2} − x + 2)", "(ax + b)", "+", "−x + 1"], "alt"],
	["P4", "twodiv", 0, 0, ["(x^{2} − x + 2)", "(ax + b)", "+", "2x + 3"], "bad"],
	["P4", "twodiv", 1, 0, ["(ax + b)", "(x^{2} + 1)", "+", "5x + 3"], "alt"],
	["P4", "twodiv", 1, 0, ["(x^{2} + 1)", "(ax + b)", "+", "x − 1"], "bad"],
	["P4", "newton", 0, 0, ["P", "(x − 201)", "(x − 202)", "+", "Q", "(x − 202)", "+", "R"], "alt"],
]


func _initialize() -> void:
	await setup()
	_check_static()
	var files := {}
	for u in Units.UNITS:
		for l in u.levels:
			files[String(l.id)] = [String(l.get("file", "")), String(l.get("bank", ""))]
	var cur := ""
	var lv = null
	var bank = null
	for c in CASES:
		var lid := String(c[0])
		if lid != cur:
			g.goto(String(files[lid][0]))
			await wait(0.8)
			lv = current_scene
			for n in lv.get_children():
				if n is Control and n.mouse_filter == Control.MOUSE_FILTER_STOP and n.get_index() > 3:
					n.queue_free()
			await frames()
			lv.journey_mode = true
			bank = load(Paths.of(String(files[lid][1])))
			cur = lid
		var slot := {}
		for s in bank.slots():
			if String(s.id) == String(c[1]):
				slot = s
		var tag := "%s/%s#%d 第 %d 步 填 %s" % [lid, c[1], c[2], c[3], str(c[4])]
		if slot.is_empty():
			ok(false, "%s：找不到題組" % tag)
			continue
		lv.rounds = [lv.make_round(slot, slot.variants[int(c[2])])]
		lv.ri = 0
		lv._start_round()
		await frames(3)
		if lv.get("intro_block") != null:
			lv._intro_finish()
		await frames(2)
		var k := int(c[3])
		lv.si = k
		lv._forge_step()
		await frames(2)
		ok(String(lv.steps[k].kind) == "fill", "%s：這一步是填空" % tag)
		lv.slot_vals = Array(c[4]).duplicate()
		lv._fill_submit()
		await frames(2)
		var accepted: bool = lv.si > k
		ok(accepted == bool(c[5]), "%s：%s" % [tag, "應該算對" if c[5] else "應該算錯"])
		# 正解本來就要算對
		lv.si = k
		lv._forge_step()
		await frames(1)
		lv.slot_vals = Array(lv.steps[k].answers).map(func(a): return String(a).replace("-", "−"))
		lv._fill_submit()
		await frames(2)
		ok(lv.si > k, "%s：正解也要算對" % tag)
	for c in BLOCKS:
		var lid := String(c[0])
		if lid != cur:
			g.goto(String(files[lid][0]))
			await wait(0.8)
			lv = current_scene
			for n in lv.get_children():
				if n is Control and n.mouse_filter == Control.MOUSE_FILTER_STOP and n.get_index() > 3:
					n.queue_free()
			await frames()
			lv.journey_mode = true
			bank = load(Paths.of(String(files[lid][1])))
			cur = lid
		var slot := {}
		for s in bank.slots():
			if String(s.id) == String(c[1]):
				slot = s
		var tag := "%s/%s#%d 第 %d 步 拼 %s" % [lid, c[1], c[2], c[3], " ".join(PackedStringArray(c[4]))]
		if slot.is_empty():
			ok(false, "%s：找不到題組" % tag)
			continue
		lv.rounds = [lv.make_round(slot, slot.variants[int(c[2])])]
		lv.ri = 0
		lv._start_round()
		await frames(3)
		if lv.get("intro_block") != null:
			lv._intro_finish()
		await frames(2)
		var k := int(c[3])
		lv.si = k
		lv._forge_step()
		await frames(2)
		ok(String(lv.steps[k].kind) == "blocks", "%s：這一步是拼積木" % tag)
		var m0: int = lv.mistakes
		lv.blk_seq = Array(c[4]).duplicate()
		lv._blocks_submit(lv.steps[k])
		await frames(2)
		var want := String(c[5])
		var got := "ok" if lv.si > k else ("bad" if lv.mistakes > m0 else "alt")
		ok(got == want, "%s：應該是 %s，結果是 %s" % [tag, want, got])
	finish("ANSWERS")


## 不用開關卡就能測的：哪些格子不管正負號、速算的方程式係數成比例也對
func _check_static() -> void:
	ok(SL._sign_free("\\ol{AB}^{2} = [0]^{2} + [1]^{2}") == [0, 1], "平方的格子")
	ok(SL._sign_free("k = ±[1]") == [1], "± 的格子")
	ok(SL._sign_free("\\frac{|[0]m|}{√{m^{2} + 1}}") == [0], "絕對值裡的格子")
	ok(SL._sign_free("(x − [0])^{2} + (y − [1])^{2} = [2]").is_empty(), "(x − [0])^{2} 的正負號有差")
	ok(SL._sign_free("\\frac{|3k − 6|}{[0]} = 3").is_empty(), "分母不是絕對值")
	for e in [["level_line7_lamp.gd", "tan"], ["level_line8_star.gd", "chord"]]:
		var scr: Script = load(Paths.of(String(e[0])))
		var good := true
		for pb in scr.gen_problems(String(e[1]), 12):
			if String(pb.get("mode", "")) != "prop":
				good = false
				continue
			var ans := Array(pb.answers).map(func(a): return SL.parse_q(String(a)))
			var dbl := ans.map(func(q): return [int(q[0]) * -2, int(q[1])])
			if not SL.q_prop(dbl, ans):
				good = false
		ok(good, "%s 速算：方程式乘上一個數也算對" % e[0])
	# 終焉之塔的填空：± 裡的格子正負號都可以
	var BT: Script = load("res://data/levels/tower/boss_tower.gd")
	var pm := {"template": "(cos α, cos β) = (±[0], ∓[1])", "ans": ["3/5", "12/13"]}
	ok(BT.fill_slots_ok(pm, ["−3/5", "12/13"]) == [true, true], "終焉之塔：±[0] 填 −3/5 也對")
	ok(BT.fill_slots_ok(pm, ["3/5", "−5/13"]) == [true, false], "終焉之塔：±[1] 填錯的數還是錯")
	ok(BT.fill_slots_ok({"template": "a = [0]", "ans": ["3/5"]}, ["−3/5"]) == [false], "終焉之塔：一般的格子正負號有差")
	# 對數的「施放法則」：用換底也算得出來的題目，換底不能當錯的選項
	var b4 = load(Paths.of("level04_bank.gd"))
	var bad := []
	for slot in b4.slots():
		for v in slot.get("variants", []):
			for st in v.get("steps", []):
				if String(st.get("kind", "")) == "rule" and String(st.correct) in ["mpow", "recip"] and Array(st.rules).has("base"):
					bad.append(String(st.q))
	ok(bad.is_empty(), "對數法則：次方、倒數的題目不能拿換底當錯的選項 %s" % str(bad))
