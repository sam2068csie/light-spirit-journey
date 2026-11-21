extends RefCounted
## 平面向量 第二大關「斜紋麥田」題庫（上冊 3-1 重點三、四：共線、係數的範圍、坐標表示法）
## 設計稿：docs/vec2_v2_design.md。數字都用程式驗算過（tools/vec2/verify_v2.py）。
##
## 引擎見 vec_level.gd（箭頭畫布、在圖上作答），圖層見 vec_board.gd。這一關多用了：
##   vpick 的 "skew"（斜格子點選）、region（點區域、長稻子，直線與圓的引擎）、vplace 沙盒的 "pull"（加權拉力）、
##   圖層 beam（光束）、ruler（刻度尺）、plant（種子），滑桿的 lines 裡放 skew（會動的斜格子）和 "when"（條件成立才畫）。
## 第一章的三角形都是 A 在原點：P = x\vec{AB} + y\vec{AC} 在畫布上是 x·B + y·C（_at）。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/vec2/vec1_bank.gd")

const T_COL := "vec_collinear"     # 三點共線、係數和
const T_INT := "vec_intersect"     # 兩線交點、分線段的比
const T_REG := "vec_region"        # 斜坐標的區域、面積
const T_CRD := "vec_coord"         # 坐標表示、單位向量、角平分向量
const T_WGT := "vec_weight"        # 加權平均、最小值


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return B1._f(name, q, template, answers, line, nudge, tag, mode)


static func _j(name: String, statement: String, ok: bool, why: String, line: String, tag: String) -> Dictionary:
	return B1._j(name, statement, ok, why, line, tag)


static func _p(v: Vector2) -> Array:
	return [v.x, v.y]


static func _ar(a: Vector2, b: Vector2, c := "cyan", s := "", extra := {}) -> Dictionary:
	return B1._ar(a, b, c, s, extra)


static func _dot(p: Vector2, s: String, c := "gold", extra := {}) -> Dictionary:
	return B1._dot(p, s, c, extra)


static func _tag(p: Vector2, s: String, c := "text", extra := {}) -> Dictionary:
	return B1._tag(p, s, c, extra)


static func _seg(a: Vector2, b: Vector2, c := "dim", extra := {}) -> Dictionary:
	return B1._seg(a, b, c, extra)


static func _poly(pts: Array, c := "dim", extra := {}) -> Dictionary:
	return B1._poly(pts, c, extra)


static func _walk(pts: Array, at: int, c := "gold", arrows := true, extra := {}) -> Dictionary:
	return B1._walk(pts, at, c, arrows, extra)


static func _plane(x: Array, y: Array, shapes: Array, named := {}, extra := {}) -> Dictionary:
	return B1._plane(x, y, shapes, named, extra)


static func _dots(pts: Dictionary, c := "text", offs := {}) -> Array:
	return B1._dots(pts, c, offs)


static func _beam(a: Vector2, b: Vector2, at: int, c := "gold", extra := {}) -> Dictionary:
	var d := {"k": "beam", "a": _p(a), "b": _p(b), "c": c, "at": at}
	d.merge(extra, true)
	return d


static func _ruler(a: Vector2, b: Vector2, n: int, m: int, at: int, extra := {}) -> Dictionary:
	var d := {"k": "ruler", "a": _p(a), "b": _p(b), "n": n, "m": m, "at": at}
	d.merge(extra, true)
	return d


static func _plant(p: Vector2, state: String, at: int, s := "") -> Dictionary:
	return {"k": "plant", "p": _p(p), "state": state, "at": at, "s": s}


static func _lamp(p: Vector2, at: int) -> Array:
	return [{"k": "circle", "o": _p(p), "r": 0.22, "c": "gold", "fill": "gold", "alpha": 0.5, "at": at}, _dot(p, "P", "gold", {"at": at, "off": [10, -8]})]


static func _fr(n: int, d: int) -> String:
	return B1._fr(n, d)


static func _frs(s: String) -> String:
	return B1._frs(s)


static func _n(v: float) -> String:
	return B1._n(v)


static func slots() -> Array:
	var out := _slots()
	for slot in out:
		slot["plain"] = true
		if String(slot.type) == "forge":
			slot["type_name"] = "逐步推導"
		SB.fix_roots(slot)
		slot["params"] = slot.get("params", [])
	return out


static func _slots() -> Array:
	return [
		_scarecrow(), _xy_line(), _beams(), _cut(), _shadow(), _fence(), _sow(), _seven(), _area(),
		{"id": "speed1", "chapter": 1, "type": "speed", "title": "田地速算", "time": 120.0,
		 "story": "稻草人站在哪一邊？看 x + y 就知道！",
		 "insight": "\\vec{AP} = x\\vec{AB} + y\\vec{AC}：x + y = 1 在直線 BC 上\nx + y < 1 和 A 同一側，x + y > 1 在另一側。",
		 "variants": [{"gen": "side", "count": 8}]},
		_address(), _hidden(), _fourth(), _bands(), _collapse(), _midpts(), _pull_min(), _unit(), _bisect(), _coord_bead(),
		{"id": "speed2", "chapter": 2, "type": "speed", "title": "坐標速算", "time": 120.0,
		 "story": "烽台一座一座點亮，坐標分量對應算！",
		 "insight": "m\\vec{a} + n\\vec{b}：x 分量、y 分量各自乘、各自加。",
		 "variants": [{"gen": "coord", "count": 8}]},
	]


# ======================= 第一章．斜紋麥田 =======================

## 三角形 A(0, 0)、B、C 上斜坐標 (x, y) 的位置
static func _at(B: Vector2, C: Vector2, x: float, y: float) -> Vector2:
	return B * x + C * y


## 1 一條直線上的稻草人（A13）
static func _scarecrow() -> Dictionary:
	var A := Vector2(-2, 1)
	var B := Vector2(1, 1)
	var vars := []
	for cfg in [
			{"O": Vector2(0, -1), "cards": [
				["\\vec{AB} = −2\\vec{AC}", A + (A - B) / 2.0, true, "C 在 A 的另一邊，\\vec{AC} 和 \\vec{AB} 平行。"],
				["\\vec{OC} = 2\\vec{OA} + \\vec{OB}", "c2", false, "係數和是 3，不是 1：C 跑到直線外面。"],
				["2\\vec{OA} − 3\\vec{OB} + \\vec{OC} = \\vec{0}", "c3", true, "寫成 = \\vec{0} 時係數和是 0：\\vec{OC} = −2\\vec{OA} + 3\\vec{OB}，−2 + 3 = 1。"],
				["\\vec{OA} + \\vec{OB} + \\vec{OC} = \\vec{0}", "c4", false, "係數和是 3：O 是 △ABC 的重心，三點不共線。"]]},
			{"O": Vector2(0, -3), "cards": [
				["\\vec{BC} = \\frac{1}{2}\\vec{AB}", B + (B - A) / 2.0, true, "\\vec{BC} 和 \\vec{AB} 平行，B 是共同的點。"],
				["\\vec{OC} = \\frac{1}{3}\\vec{OA} + \\frac{2}{3}\\vec{OB}", "d2", true, "係數和 \\frac{1}{3} + \\frac{2}{3} = 1：C 是 \\ol{AB} 的分點。"],
				["\\vec{OC} = \\frac{1}{2}\\vec{OA} + \\frac{1}{3}\\vec{OB}", "d3", false, "係數和是 \\frac{5}{6}，不是 1。"],
				["|\\vec{AB}| = |\\vec{AC}|", A + Vector2(0, 3), false, "一樣長不一定共線：C 可以在以 A 為圓心的圓上任何地方。"]]}]:
		var O: Vector2 = cfg.O
		var shapes := [_tag(O, "O", "dim", {"off": [-14, 14]}),
			_beam(A, B, 1, "gold", {"w": 1}), _beam(B, A, 1, "gold")]
		shapes += _dots({"A": A, "B": B}, "text", {"A": [-6, -12], "B": [4, -12]})
		var steps := []
		var k := 0
		for cd in cfg.cards:
			k += 1
			var C: Vector2
			match str(cd[1]):
				"c2":
					C = 2.0 * A + B - 2.0 * O
				"c3":
					C = -2.0 * A + 3.0 * B
				"c4":
					C = 3.0 * O - A - B
				"d2":
					C = A / 3.0 + B * 2.0 / 3.0
				"d3":
					C = O / 6.0 + A / 2.0 + B / 3.0
				_:
					C = cd[1]
			var ok: bool = cd[2]
			shapes.append(_dot(C, "C", "lime" if ok else "pink", {"at": k, "until": k + 1, "off": [8, 14]}))
			if String(cd[0]).begins_with("|"):
				shapes.append({"k": "circle", "o": _p(A), "r": (B - A).length(), "c": "faint", "dash": true, "at": k, "until": k + 1})
			steps.append(_j(["審判一", "審判二", "審判三", "審判四"][k - 1], String(cd[0]), ok, String(cd[3]),
				("%s ⇒ 共線" if ok else "%s 不保證共線") % cd[0], T_COL))
		for st in steps:
			st["big"] = true
		vars.append({"eq": "下面哪些條件保證 A、B、C 共線？", "plane": _plane([-6, 8], [-5.2, 5.2], shapes), "steps": steps})
	return {"id": "crow", "chapter": 1, "type": "forge", "title": "一條直線上的稻草人",
		"story": "照條件把稻草人 C 插下去，看它在不在光上。",
		"insight": "\\vec{OC} = α\\vec{OA} + β\\vec{OB}：A、B、C 共線 ⇔ α + β = 1\n寫成 a\\vec{OA} + b\\vec{OB} + c\\vec{OC} = \\vec{0}：係數和 a + b + c = 0。",
		"variants": vars}


## 2 斜線上的 x + y（新）
static func _xy_line() -> Dictionary:
	var vars := []
	for cfg in [{"B": Vector2(6, 0), "C": Vector2(2, 4), "m": 1}, {"B": Vector2(3, 0), "C": Vector2(1, 2), "m": 2}]:
		var B: Vector2 = cfg.B
		var C: Vector2 = cfg.C
		var m: int = cfg.m
		var Bm := B * m
		var Cm := C * m
		var shapes := [_poly([Vector2.ZERO, B, C], "dim"), _ar(Vector2.ZERO, B, "cyan", "\\vec{AB}", {"ls": -1, "w": 2.5}),
			_ar(Vector2.ZERO, C, "pink", "\\vec{AC}", {"w": 2.5})]
		shapes += _dots({"A": Vector2.ZERO, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [6, -6]})
		var nm := "BC"
		if m == 2:
			shapes += [_seg(B, Bm, "faint", {"dash": true}), _seg(C, Cm, "faint", {"dash": true})]
			shapes += _dots({"B'": Bm, "C'": Cm}, "dim", {"B'": [6, 14], "C'": [6, -6]})
			nm = "B'C'"
		shapes.append(_seg(Bm + (Bm - Cm) * 0.6, Cm + (Cm - Bm) * 0.6, "gold", {"dash": true, "w": 1.5}))
		var px := "%f + s * (%f)" % [Bm.x, Cm.x - Bm.x]
		var py := "%f + s * (%f)" % [Bm.y, Cm.y - Bm.y]
		var slide := {"kind": "slide", "name": "拖拖看", "q": "拖 P 沿著直線 %s 走" % nm, "tag": T_COL, "free": true,
			"params": [{"n": "s", "min": -0.5, "max": 1.5, "step": 0.25, "v": 0.25}],
			"lines": [{"k": "dot", "p": [px, py], "c": "gold", "s": "P"}, {"k": "arrow", "a": [0, 0], "b": [px, py], "c": "gold", "w": 2.5}],
			"eq": "x = {%d * (1 - s)}，y = {%d * s}\nx + y = {%d * (1 - s) + %d * s}" % [m, m, m, m],
			"line": "P 在直線 %s 上：x、y 一直變，x + y 一直是 %d" % [nm, m], "nudge": "拉動滑桿，看 x + y。"}
		# 斜坐標換成畫布坐標的不等式：x = (wx + kx·wy) / b、y = wy / c.y（kx = −c.x / c.y）
		# x + y = 定值 ⇔ wx + (kx + b / c.y)·wy − m·b = 0
		var b_w := B.x
		var kx := -C.x / C.y
		var sum_l := [1, kx + b_w / C.y, -m * b_w]
		var lines := [[0, 1, 0], [1, kx, 0], sum_l]
		var region: Dictionary
		if m == 1:
			region = {"kind": "region", "name": "長稻子", "q": "點出 x + y > 1 的地方", "tag": T_REG, "bloom": true, "lines": lines,
				"ineq": [[sum_l[0], sum_l[1], sum_l[2], ">"]], "names": ["x + y > 1"],
				"nudge": "x + y > 1：在直線 BC 的哪一邊？", "line": "x + y > 1：直線 BC 的另一側（不和 A 同一側）"}
		else:
			region = {"kind": "region", "name": "長稻子", "q": "點出 x、y > 0，x + y < 2 的地方", "tag": T_REG, "bloom": true, "lines": lines,
				"ineq": [[0, 1, 0, ">"], [1, kx, 0, ">"], [sum_l[0], sum_l[1], sum_l[2], "<"]], "names": ["y > 0", "x > 0", "x + y < 2"],
				"nudge": "三個條件都要成立。", "line": "x > 0、y > 0、x + y < 2：△AB'C' 的內部"}
		vars.append({"eq": ("P 在直線 BC 上，\\vec{AP} = x\\vec{AB} + y\\vec{AC}" if m == 1 else "P 在直線 B'C' 上，\\vec{AP} = x\\vec{AB} + y\\vec{AC}") \
				+ "\nx + y 是多少？哪裡的 x + y 比較大？",
			"plane": _plane([-1.5, Bm.x + 3.0], [-0.9, Cm.y + 0.8], shapes),
			"steps": [slide,
				_c("x + y", "P 在直線 %s 上，x + y = ？" % nm, [str(m), "0", "不一定"], 0,
					("\\vec{AP} = (1 − s)\\vec{AB} + s\\vec{AC} 的係數和永遠是 1，所以 x + y = 1。" if m == 1
						else "\\vec{AP} = (1 − s)\\vec{AB'} + s\\vec{AC'} = 2(1 − s)\\vec{AB} + 2s\\vec{AC}，x + y = 2。"),
					"看剛才的讀數。", "P 在直線 %s 上 ⇔ x + y = %d" % [nm, m], T_COL),
				region]})
	return {"id": "xyline", "chapter": 1, "type": "forge", "title": "斜線上的 x + y",
		"story": "沿著田埂走，x、y 一直變，有一個東西不變。",
		"insight": "P 在直線 BC 上 ⇔ x + y = 1\nx + y < 1 和 A 在同一側，x + y > 1 在另一側。",
		"variants": vars}


## 3 兩道光束（A14、A16、A18）
static func _beams() -> Dictionary:
	var B := Vector2(8, 0)
	var C := Vector2(2.5, 4.5)
	var A := Vector2.ZERO
	var base := func() -> Array:
		var s := [_poly([A, B, C], "dim")]
		s += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [6, -6]})
		return s
	# 變化 A：DE ∩ AQ
	var D := B / 3.0
	var E := C / 2.0
	var Q := B.lerp(C, 1.0 / 3.0)
	var Pa := _at(B, C, 0.25, 0.125)
	var sa: Array = base.call()
	sa += _dots({"D": D, "E": E, "Q": Q}, "dim", {"D": [-4, 18], "E": [-18, -4], "Q": [8, 4]})
	sa += [_seg(D, E, "faint"), _seg(A, Q, "faint"), _beam(A, Q, 1, "cyan"), _beam(D, E, 3, "pink")] + _lamp(Pa, 4)
	var va := {"eq": "\\ol{AD} : \\ol{DB} = 1 : 2，\\ol{AE} = \\ol{EC}，\\ol{BQ} : \\ol{QC} = 1 : 2\n\\ol{DE} 交 \\ol{AQ} 於 P，\\vec{AP} = x\\vec{AB} + y\\vec{AC}，求 (x, y)",
		"plane": _plane([-1, 9.5], [-0.9, 5.2], sa),
		"steps": [
			_f("光束一", "P 在 AQ 上", "x : y = [0] : [1]", ["2", "1"], "P 在 AQ 上：\\vec{AQ} = \\frac{2}{3}\\vec{AB} + \\frac{1}{3}\\vec{AC}，x : y = 2 : 1",
				"\\vec{AQ} 的兩個係數是多少？", T_INT, "prop"),
			_f("換基底", "換成 \\vec{AD}、\\vec{AE}", "\\vec{AP} = [0]x\\vec{AD} + [1]y\\vec{AE}", ["3", "2"],
				"\\vec{AB} = 3\\vec{AD}、\\vec{AC} = 2\\vec{AE} ⇒ \\vec{AP} = 3x\\vec{AD} + 2y\\vec{AE}", "\\vec{AD} 是 \\vec{AB} 的幾分之幾？", T_INT),
			_f("光束二", "D、P、E 共線", "3x + 2y = [0]", ["1"], "D、P、E 共線：3x + 2y = 1", "係數和是多少？", T_COL),
			_f("交點", "聯立", "(x, y) = ([0], [1])", ["1/4", "1/8"], "x = 2y、3x + 2y = 1 ⇒ (x, y) = (\\frac{1}{4}, \\frac{1}{8})",
				"x = 2y 代進去。", T_INT),
		]}
	# 變化 B、C：兩條線都不過 A，各寫一個「係数和 = 1」
	var vbc := []
	for cfg in [{"d": 3, "e": [3, 4], "c1": "3", "c2": "4/3", "xy": ["1/9", "2/3"], "lines": ["CD", "BE"],
			"eq": "\\ol{AD} : \\ol{DB} = 1 : 2，\\ol{AE} : \\ol{EC} = 3 : 1\n\\ol{CD} 交 \\ol{BE} 於 P，\\vec{AP} = x\\vec{AB} + y\\vec{AC}，求 (x, y)"},
			{"d": 4, "e": [2, 3], "c1": "4", "c2": "3/2", "xy": ["1/10", "3/5"], "lines": ["CD", "BE"],
			"eq": "\\vec{AD} = \\frac{1}{4}\\vec{AB}，\\vec{AE} = \\frac{2}{3}\\vec{AC}\n\\ol{BE} 交 \\ol{CD} 於 P，\\vec{AP} = x\\vec{AB} + y\\vec{AC}，求 (x, y)"}]:
		var Dd := B / float(cfg.d)
		var Ee := C * float(cfg.e[0]) / float(cfg.e[1])
		var P := _at(B, C, B1._frv(cfg.xy[0]), B1._frv(cfg.xy[1]))
		var sb: Array = base.call()
		sb += _dots({"D": Dd, "E": Ee}, "dim", {"D": [8, 16], "E": [-18, -4]})
		sb += [_seg(C, Dd, "faint"), _seg(B, Ee, "faint"), _beam(C, Dd, 1, "cyan"), _beam(B, Ee, 2, "pink")] + _lamp(P, 3)
		vbc.append({"eq": cfg.eq, "plane": _plane([-1, 9.5], [-0.9, 5.2], sb),
			"steps": [
				_f("光束一", "P 在 CD 上，係數和 = 1", "[0]x + y = 1", [cfg.c1],
					"\\vec{AB} = %d\\vec{AD} ⇒ \\vec{AP} = %dx\\vec{AD} + y\\vec{AC}，%dx + y = 1" % [cfg.d, cfg.d, cfg.d],
					"\\vec{AB} 換成幾倍的 \\vec{AD}？", T_INT),
				_f("光束二", "P 在 BE 上，係數和 = 1", "x + [0]y = 1", [cfg.c2],
					"\\vec{AC} = %s\\vec{AE} ⇒ x + %sy = 1" % [_frs(cfg.c2), _frs(cfg.c2)], "\\vec{AC} 換成幾倍的 \\vec{AE}？", T_INT),
				_f("交點", "聯立", "(x, y) = ([0], [1])", cfg.xy,
					"(x, y) = (%s, %s)" % [_frs(cfg.xy[0]), _frs(cfg.xy[1])], "第一式 y = 1 − %sx 代進第二式。" % cfg.c1, T_INT),
			]})
	return {"id": "beams", "chapter": 1, "type": "forge", "title": "兩道光束",
		"story": "一個條件是一道光束，兩道光交會的地方就是 P。",
		"insight": "P 在直線 DE 上：把 \\vec{AP} 寫成 \\vec{AD}、\\vec{AE} 的組合，係數和 = 1\n兩條線各寫一個式子，聯立就是交點。",
		"variants": [va] + vbc}


## 4 光束分線段（A15、A19）
static func _cut() -> Dictionary:
	var A := Vector2.ZERO
	var B := Vector2(8, 0)
	var C := Vector2(2.5, 4.5)
	var D := B.lerp(C, 0.25)
	var E := B * (2.0 / 3.0)
	var F := D * (8.0 / 11.0)
	var sa := [_poly([A, B, C], "dim")]
	sa += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [6, -6]})
	sa += _dots({"D": D, "E": E}, "dim", {"D": [8, 4], "E": [-4, 18]})
	sa += [_seg(A, D, "faint"), _seg(C, E, "faint"), _seg(A, D, "cyan", {"at": 1, "w": 2.5}),
		_seg(C, E, "pink", {"at": 2, "w": 2.5}), {"k": "circle", "o": _p(F), "r": 0.2, "c": "gold", "fill": "gold", "alpha": 0.5, "at": 2},
		_dot(F, "F", "gold", {"at": 2, "off": [6, -10]}), _ruler(A, D, 11, 8, 3, {"c": "gold"})]
	var va := {"eq": "\\ol{BD} : \\ol{DC} = 1 : 3，\\ol{BE} : \\ol{EA} = 1 : 2\n\\ol{CE} 交 \\ol{AD} 於 F，求 \\ol{AF} : \\ol{FD}",
		"plane": _plane([-1, 9.5], [-0.9, 5.2], sa),
		"steps": [
			_f("設 t", "\\vec{AF} = t\\vec{AD}", "\\vec{AF} = [0]t\\vec{AB} + [1]t\\vec{AC}", ["3/4", "1/4"],
				"\\vec{AD} = \\frac{3}{4}\\vec{AB} + \\frac{1}{4}\\vec{AC} ⇒ \\vec{AF} = \\frac{3}{4}t\\vec{AB} + \\frac{1}{4}t\\vec{AC}", "\\ol{BD} : \\ol{DC} = 1 : 3，係數交叉。", T_INT),
			_f("係數和", "換成 \\vec{AE}，係數和 = 1", "[0]t + \\frac{1}{4}t = 1，t = [1]", ["9/8", "8/11"],
				"\\vec{AB} = \\frac{3}{2}\\vec{AE} ⇒ \\frac{9}{8}t + \\frac{1}{4}t = 1，t = \\frac{8}{11}", "\\frac{3}{4} × \\frac{3}{2} = ？", T_INT),
			_f("比", "t 換成比", "\\ol{AF} : \\ol{FD} = [0] : [1]", ["8", "3"], "\\ol{AF} : \\ol{FD} = 8 : 3", "\\ol{AF} = \\frac{8}{11}\\ol{AD}。", T_INT, "prop"),
		]}
	var u := Vector2(6, 0)
	var v := Vector2(2, 4)
	var Pc := u + v
	var Eb := u + v * 0.5
	var Fb := Pc - u / 3.0
	var Pb := Fb * 0.75
	var sb := [_poly([A, u, Pc, v], "dim")]
	sb += _dots({"A": A, "B": u, "C": Pc, "D": v}, "text", {"A": [-14, 14], "B": [6, 14], "C": [6, -6], "D": [-14, -6]})
	sb += _dots({"E": Eb, "F": Fb}, "dim", {"E": [8, 4], "F": [-4, -10]})
	sb += [_seg(A, Fb, "faint"), _seg(v, Eb, "faint"), _seg(A, Fb, "cyan", {"at": 1, "w": 2.5}), _seg(v, Eb, "pink", {"at": 2, "w": 2.5}),
		{"k": "circle", "o": _p(Pb), "r": 0.2, "c": "gold", "fill": "gold", "alpha": 0.5, "at": 2},
		_dot(Pb, "P", "gold", {"at": 2, "off": [8, 14]}), _ruler(A, Fb, 4, 3, 3, {"c": "gold"})]
	var vb := {"eq": "平行四邊形 ABCD，\\ol{BE} = \\ol{EC}，\\ol{CF} : \\ol{FD} = 1 : 2\n\\ol{DE} 交 \\ol{AF} 於 P，求 \\ol{AP} : \\ol{PF}",
		"plane": _plane([-1, 9], [-0.9, 4.8], sb),
		"steps": [
			_f("AF", "\\vec{AF} 用 \\vec{AB}、\\vec{AD}", "\\vec{AF} = [0]\\vec{AB} + \\vec{AD}", ["2/3"],
				"\\vec{AF} = \\vec{AD} + \\vec{DF} = \\frac{2}{3}\\vec{AB} + \\vec{AD}", "\\ol{DF} 是 \\ol{DC} 的幾分之幾？", T_INT),
			_f("係數和", "\\vec{AB} = \\vec{AE} − \\frac{1}{2}\\vec{AD}，係數和 = 1",
				"\\vec{AP} = [0]t\\vec{AE} + [1]t\\vec{AD}，t = [2]", ["2/3", "2/3", "3/4"],
				"\\vec{AP} = t\\vec{AF} = \\frac{2}{3}t\\vec{AE} + \\frac{2}{3}t\\vec{AD}，\\frac{4}{3}t = 1，t = \\frac{3}{4}",
				"t\\vec{AD} − \\frac{1}{3}t\\vec{AD} = ？", T_INT),
			_f("比", "t 換成比", "\\ol{AP} : \\ol{PF} = [0] : [1]", ["3", "1"], "\\ol{AP} : \\ol{PF} = 3 : 1", "\\ol{AP} = \\frac{3}{4}\\ol{AF}。", T_INT, "prop"),
		]}
	return {"id": "cut", "chapter": 1, "type": "forge", "title": "光束分線段",
		"story": "光束停在交點，把線段切成兩段。",
		"insight": "設 \\vec{AF} = t\\vec{AD}，再換成另一條線兩端的向量，係數和 = 1 求 t\nt 就是 \\ol{AF} 占 \\ol{AD} 的比例。",
		"variants": [va, vb]}


## 5 稻草人的影子比（A17）
static func _shadow() -> Dictionary:
	var A := Vector2.ZERO
	var B := Vector2(8, 0)
	var C := Vector2(2.5, 4.5)
	var vars := []
	for cfg in [
			{"am": [2, 1], "an": [1, 1], "c": ["3/2", "2"], "xy": ["1/2", "1/4"],
			 "cards": [["\\ol{BD} : \\ol{DC} = 2 : 1", false, "\\vec{AD} = \\frac{2}{3}\\vec{AB} + \\frac{1}{3}\\vec{AC}：\\ol{BD} : \\ol{DC} = 1 : 2。", "BC", 3, 1],
				["\\ol{AP} : \\ol{PD} = 3 : 1", true, "\\vec{AP} = \\frac{3}{4}\\vec{AD}。", "AD", 4, 3],
				["\\ol{BP} : \\ol{PN} = 1 : 1", true, "\\vec{AP} = \\frac{1}{2}\\vec{AB} + \\frac{1}{2}\\vec{AN}：P 是 \\ol{BN} 的中點。", "BN", 2, 1]]},
			{"am": [1, 1], "an": [2, 1], "c": ["2", "3/2"], "xy": ["1/4", "1/2"],
			 "cards": [["\\ol{BD} : \\ol{DC} = 2 : 1", true, "\\vec{AD} = \\frac{1}{3}\\vec{AB} + \\frac{2}{3}\\vec{AC}：\\ol{BD} : \\ol{DC} = 2 : 1。", "BC", 3, 2],
				["\\ol{AP} : \\ol{PD} = 2 : 1", false, "\\vec{AP} = \\frac{3}{4}\\vec{AD}：\\ol{AP} : \\ol{PD} = 3 : 1。", "AD", 4, 3],
				["\\ol{CP} : \\ol{PM} = 1 : 1", true, "\\vec{AP} = \\frac{1}{2}\\vec{AC} + \\frac{1}{2}\\vec{AM}：P 是 \\ol{CM} 的中點。", "CM", 2, 1]]}]:
		var M := B * float(cfg.am[0]) / float(cfg.am[0] + cfg.am[1])
		var N := C * float(cfg.an[0]) / float(cfg.an[0] + cfg.an[1])
		var x0: float = B1._frv(cfg.xy[0])
		var y0: float = B1._frv(cfg.xy[1])
		var P := _at(B, C, x0, y0)
		var D := P / (x0 + y0)
		var pts := {"A": A, "B": B, "C": C, "D": D, "M": M, "N": N, "P": P}
		var shapes := [_poly([A, B, C], "dim")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [6, -6]})
		shapes += _dots({"M": M, "N": N}, "dim", {"M": [-4, 18], "N": [-18, -4]})
		shapes += [_seg(B, N, "faint"), _seg(C, M, "faint"), _seg(B, N, "cyan", {"at": 1, "w": 2.0}), _seg(C, M, "pink", {"at": 1, "w": 2.0})]
		shapes += _lamp(P, 2)
		shapes += [_seg(A, D, "gold", {"at": 2, "dash": true}), _dot(D, "D", "gold", {"at": 2, "off": [8, 4]})]
		var steps := [
			_f("兩道光束", "兩條線各寫係數和 = 1", "[0]x + y = 1，x + [1]y = 1", cfg.c,
				"P 在 CM 上：%sx + y = 1，P 在 BN 上：x + %sy = 1" % [_frs(cfg.c[0]), _frs(cfg.c[1])],
				"\\vec{AB} 換成幾倍的 \\vec{AM}？\\vec{AC} 換成幾倍的 \\vec{AN}？", T_INT),
			_f("交點", "聯立", "(x, y) = ([0], [1])", cfg.xy, "\\vec{AP} = %s\\vec{AB} + %s\\vec{AC}" % [_frs(cfg.xy[0]), _frs(cfg.xy[1])],
				"把一式代進另一式。", T_INT)]
		var k := 2
		for cd in cfg.cards:
			k += 1
			var seg := String(cd[3])
			steps.append(_j(["審判一", "審判二", "審判三"][k - 3], String(cd[0]), bool(cd[1]), String(cd[2]),
				"%s %s" % [cd[0], "○" if cd[1] else "✕"], T_INT))
			shapes.append(_ruler(pts[seg[0]], pts[seg[1]], int(cd[4]), int(cd[5]), k, {"c": "lime" if cd[1] else "pink", "until": k + 1}))
		for i in range(2, steps.size()):
			steps[i]["big"] = true
		vars.append({"eq": "\\ol{AM} : \\ol{MB} = %d : %d，\\ol{AN} : \\ol{NC} = %d : %d，\\ol{BN} 交 \\ol{CM} 於 P\n直線 AP 交 \\ol{BC} 於 D，下面哪些正確？" % [cfg.am[0], cfg.am[1], cfg.an[0], cfg.an[1]],
			"plane": _plane([-1, 9.5], [-0.9, 5.2], shapes), "steps": steps})
	return {"id": "shadow", "chapter": 1, "type": "forge", "title": "稻草人的影子比",
		"story": "兩根竹竿交叉，把田切成好幾段。",
		"insight": "先求 \\vec{AP} = x\\vec{AB} + y\\vec{AC}，所有的比都從係數讀\n\\vec{AD}：係數和 = 1（把 \\vec{AP} 放大），\\ol{AP} : \\ol{PD} 就是 (x + y) : (1 − x − y)。",
		"variants": vars}


## 6 圍籬裡的稻草人（A20）
static func _fence() -> Dictionary:
	var B := Vector2(6, 0)
	var C := Vector2(2, 5)
	var vars := []
	for cfg in [
			{"eq": "P 在 △ABC 內部（不含邊）\n6\\vec{AP} = (2 − k)\\vec{AB} + 3\\vec{AC}，求 k 的範圍",
			 "x": "(2 - k) / 6.0", "y": "0.5", "lo": -1, "hi": 2, "kmin": -3, "kmax": 4, "k0": 3.5,
			 "eqr": "\\vec{AP} = {(2 - k) / 6.0}\\vec{AB} + \\frac{1}{2}\\vec{AC}",
			 "why": "x = \\frac{2 − k}{6} > 0 ⇒ k < 2，x + y = \\frac{2 − k}{6} + \\frac{1}{2} < 1 ⇒ k > −1。"},
			{"eq": "P 在 △ABC 內部（不含邊）\n5\\vec{AP} = 2\\vec{AB} + (k − 1)\\vec{AC}，求 k 的範圍",
			 "x": "0.4", "y": "(k - 1) / 5.0", "lo": 1, "hi": 4, "kmin": -1, "kmax": 6, "k0": 5.0,
			 "eqr": "\\vec{AP} = \\frac{2}{5}\\vec{AB} + {(k - 1) / 5.0}\\vec{AC}",
			 "why": "y = \\frac{k − 1}{5} > 0 ⇒ k > 1，x + y = \\frac{2}{5} + \\frac{k − 1}{5} < 1 ⇒ k < 4。"}]:
		var px := "6.0 * (%s) + 2.0 * (%s)" % [cfg.x, cfg.y]
		var py := "5.0 * (%s)" % cfg.y
		var inside := "k > %d and k < %d" % [cfg.lo, cfg.hi]
		var lo_p := Vector2(6.0 * _ev(cfg.x, cfg.lo) + 2.0 * _ev(cfg.y, cfg.lo), 5.0 * _ev(cfg.y, cfg.lo))
		var hi_p := Vector2(6.0 * _ev(cfg.x, cfg.hi) + 2.0 * _ev(cfg.y, cfg.hi), 5.0 * _ev(cfg.y, cfg.hi))
		var shapes := [_poly([Vector2.ZERO, B, C], "lime", {"fill": "lime", "alpha": 0.08})]
		shapes += _dots({"A": Vector2.ZERO, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [6, -6]})
		shapes += [_seg(lo_p, hi_p, "gold", {"at": 3, "w": 4.0})]
		var y_lo := minf(-0.9, 5.0 * _ev(cfg.y, cfg.kmin) - 0.5)
		var y_hi := maxf(5.6, 5.0 * _ev(cfg.y, cfg.kmax) + 0.5)
		vars.append({"eq": cfg.eq, "plane": _plane([-2, 9], [y_lo, y_hi], shapes),
			"steps": [
				{"kind": "slide", "name": "拖 k", "q": "拖 k，P 什麼時候在裡面？", "tag": T_REG, "free": true,
				 "params": [{"n": "k", "min": cfg.kmin, "max": cfg.kmax, "step": 0.5, "v": cfg.k0}],
				 "lines": [{"k": "dot", "p": [px, py], "c": "gold", "s": "P"},
					{"k": "plant", "p": [px, py], "state": "grow", "when": inside}],
				 "eq": "k = {k}\n" + cfg.eqr,
				 "line": "P 沿著一條直線走，只有一段在三角形裡面", "nudge": "拉動滑桿，看 P 什麼時候冒芽。"},
				_c("條件", "P 在內部的條件是？", ["x > 0、y > 0、x + y < 1", "x > 0、y > 0", "x + y < 1"], 0,
					"三條邊各一個條件：在 AB 上面（y > 0）、在 AC 右邊（x > 0）、在 BC 和 A 同一側（x + y < 1）。",
					"三條邊都要管到。", "內部 ⇔ x > 0、y > 0、x + y < 1", T_REG),
				_f("範圍", "解不等式", "[0] < k < [1]", [str(cfg.lo), str(cfg.hi)],
					"%d < k < %d" % [cfg.lo, cfg.hi], String(cfg.why), T_REG),
			]})
	return {"id": "fence", "chapter": 1, "type": "forge", "title": "圍籬裡的稻草人",
		"story": "稻草人只能沿著一條田埂走，哪一段在圍籬裡？",
		"insight": "P 在 △ABC 內部 ⇔ x > 0、y > 0、x + y < 1\n含參數的係數代進去，三個不等式一起解。",
		"variants": vars}


## 小數寫成最簡分數（分母到 12）
static func _fv(v: float) -> String:
	for d in range(1, 13):
		if absf(v * d - roundf(v * d)) < 1e-6:
			return _fr(int(roundf(v * d)), d).replace("-", "−")
	return str(v).replace("-", "−")


## 填空的答案：最簡分數寫成 "n/d"（數字鍵盤比對用）
static func _ans(v: float) -> String:
	for d in range(1, 13):
		if absf(v * d - roundf(v * d)) < 1e-6:
			var n := int(roundf(v * d))
			return str(n) if d == 1 else "%d/%d" % [n, d]
	return str(v)


static func _ev(e: String, k: float) -> float:
	var ex := Expression.new()
	ex.parse(e, ["k"])
	return float(ex.execute([k]))


## 7 菱形田播種（A21）
static func _sow() -> Dictionary:
	var vars := []
	for cfg in [
			{"m": 2, "a": Vector2(1.5, 0), "div": 4,
			 "cond": ["u < 2、v < 1、\\frac{u}{2} + v > 1", "u > 0、v > 0、u + v < 1", "u < 2、v < 1"],
			 "plants": [[[1.5, 0.5], "grow", "\\frac{3}{2}\\vec{OA} + \\frac{1}{2}\\vec{OB}", "內部"],
				[[0.5, 0.75], "edge", "\\frac{1}{2}\\vec{OA} + \\frac{3}{4}\\vec{OB}", "在邊 BD 上"],
				[[1.0, 1.0], "edge", "\\vec{OA} + \\vec{OB}", "在邊 BC 上"]]},
			{"m": 3, "a": Vector2(1.0, 0), "div": 6,
			 "cond": ["u < 3、v < 1、\\frac{u}{3} + v > 1", "u > 0、v > 0、u + v < 1", "u < 3、v < 1"],
			 "plants": [[[2.0, 2.0 / 3.0], "grow", "2\\vec{OA} + \\frac{2}{3}\\vec{OB}", "內部"],
				[[1.0, 0.5], "dead", "\\vec{OA} + \\frac{1}{2}\\vec{OB}", "在 △OBD 裡（外面）"],
				[[1.5, 0.5], "edge", "\\frac{3}{2}\\vec{OA} + \\frac{1}{2}\\vec{OB}", "在邊 BD 上"]]}]:
		var m: int = cfg.m
		var a: Vector2 = cfg.a
		var b := Vector2(1.8, 2.4)
		var D := a * m
		var C := b + D
		var shapes := [{"k": "skew", "o": [0, 0], "a": _p(a), "b": _p(b), "i": [0, m], "j": [0, 1], "div": cfg.div, "c": "cyan"},
			_poly([Vector2.ZERO, b, C, D], "dim"), _poly([b, C, D], "lime", {"fill": "lime", "alpha": 0.12}),
			_ar(Vector2.ZERO, a, "cyan", "\\vec{OA}", {"ls": -1, "w": 3.0}), _ar(Vector2.ZERO, b, "pink", "\\vec{OB}", {"w": 2.5})]
		shapes += _dots({"O": Vector2.ZERO, "B": b, "C": C, "D": D}, "text", {"O": [-14, 14], "B": [-14, -6], "C": [6, -6], "D": [6, 14]})
		shapes.append(_tag(a, "A", "cyan", {"off": [-2, -8]}))
		var skew := {"o": [0, 0], "a": _p(a), "b": _p(b), "div": cfg.div}
		var steps := [_c("條件", "△BCD 內部（u 沿 \\vec{OA}、v 沿 \\vec{OB}）", cfg.cond, 0,
			"\\ol{BD} 的方程式是 \\frac{u}{%d} + v = 1，內部在它的 C 那一側。" % m,
			"B(0, 1)、D(%d, 0)、C(%d, 1)。" % [m, m], "△BCD 內部：%s" % cfg.cond[0], T_REG)]
		var k := 1
		for pl in cfg.plants:
			var w: Vector2 = a * float(pl[0][0]) + b * float(pl[0][1])
			steps.append({"kind": "vpick", "name": "播種 %d" % k, "q": "種下 " + String(pl[2]), "target": _p(w), "skew": skew,
				"tag": T_REG, "nudge": "沿 \\vec{OA} 走 %s 格、沿 \\vec{OB} 走 %s 格。" % [_fv(float(pl[0][0])), _fv(float(pl[0][1]))],
				"why": "%s：%s。" % [pl[2], pl[3]], "line": "%s %s" % [pl[2], pl[3]], "big": true})
			shapes.append(_plant(w, String(pl[1]), k + 1))
			k += 1
		vars.append({"eq": "菱形 OBCD，O、A、D 共線，|\\vec{OB}| = %d|\\vec{OA}|\n哪些點在 △BCD 內部（不含邊）？" % m,
			"plane": _plane([-1, C.x + 1.0], [-0.8, 3.2], shapes), "steps": steps})
	return {"id": "sow", "chapter": 1, "type": "forge", "title": "菱形田播種",
		"story": "照斜坐標把種子種下去，看哪些長得出來。",
		"insight": "用 \\vec{OA}、\\vec{OB} 當斜坐標，先寫出 △BCD 的三條邊\n內部要三個不等式都成立，剛好在邊上的不算。",
		"variants": vars}


## 8 七塊田（A22）
static func _seven() -> Dictionary:
	var B := Vector2(3, 0)
	var C := Vector2(1, 2)
	var lines := [[0, 1, 0], [2, -1, 0], [1, 1, -3]]
	var shapes := [_poly([Vector2.ZERO, B, C], "gold", {"w": 2.5}),
		_seg(B * -3.0, B * 3.0, "faint", {"dash": true}), _seg(C * -3.0, C * 3.0, "faint", {"dash": true}),
		_seg(B + (B - C) * 3.0, C + (C - B) * 3.0, "faint", {"dash": true})]
	shapes += _dots({"A": Vector2.ZERO, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [6, -6]})
	var vars := []
	for pts in [[["\\frac{1}{2}\\vec{AB} + \\frac{1}{5}\\vec{AC}", 0.5, 0.2], ["2\\vec{AB} + \\vec{AC}", 2.0, 1.0], ["−\\vec{AB} − 2\\vec{AC}", -1.0, -2.0]],
			[["−\\frac{1}{2}\\vec{AB} + \\vec{AC}", -0.5, 1.0], ["3\\vec{AB} − \\vec{AC}", 3.0, -1.0], ["\\frac{1}{3}\\vec{AB} + \\frac{1}{3}\\vec{AC}", 1.0 / 3.0, 1.0 / 3.0]]]:
		var sh := shapes.duplicate(true)
		var steps := []
		var k := 0
		for pt in pts:
			var x: float = pt[1]
			var y: float = pt[2]
			var ineq := [[2, -1, 0, ">" if x > 0 else "<"], [0, 1, 0, ">" if y > 0 else "<"], [1, 1, -3, "<" if x + y < 1 else ">"]]
			var w := _at(B, C, x, y)
			var desc := "x %s 0、y %s 0、x + y %s 1" % [">" if x > 0 else "<", ">" if y > 0 else "<", "<" if x + y < 1 else ">"]
			steps.append({"kind": "region", "name": "第 %d 顆" % (k + 1), "q": "\\vec{AP} = %s 在哪一塊？" % pt[0], "tag": T_REG,
				"bloom": true, "lines": lines, "ineq": ineq, "names": ["x %s 0" % ineq[0][3], "y %s 0" % ineq[1][3], "x + y %s 1" % ineq[2][3]],
				"nudge": "先看 x、y 的正負，再看 x + y 和 1 比。", "line": "%s：%s" % [pt[0], desc]})
			sh.append(_plant(w, "grow", k + 1, "P"))
			k += 1
		vars.append({"eq": "△ABC 三邊延長，把平面分成七塊\n\\vec{AP} = x\\vec{AB} + y\\vec{AC}，P 在哪一塊？",
			"plane": _plane([-5, 7], [-3.2, 4.2], sh), "steps": steps})
	return {"id": "seven", "chapter": 1, "type": "forge", "title": "七塊田",
		"story": "三條田埂延長，把田切成七塊。",
		"insight": "七塊田就是 x、y、x + y − 1 的正負組合（全部同號的組合不存在）\nx > 0 在 AC 的 B 那一側，y > 0 在 AB 的 C 那一側，x + y < 1 和 A 同一側。",
		"variants": vars}


## 9 稻田的面積（A23）
static func _area() -> Dictionary:
	var vars := []
	for cfg in [{"B": Vector2(5, 0), "C": Vector2(1.4, 4.8), "tri": 12, "xr": [-1, 2], "yr": [0, 2], "sides": "\\ol{AB} = 5、\\ol{BC} = 6、\\ol{CA} = 5",
				"nt": "等腰：底 \\ol{BC} = 6，高 = √(25 − 9)。"},
			{"B": Vector2(4, 0), "C": Vector2(0, 3), "tri": 6, "xr": [0, 3], "yr": [-1, 1], "sides": "\\ol{AB} = 4、\\ol{AC} = 3、∠A = 90°",
				"nt": "直角三角形：兩股相乘除以 2。"}]:
		var B: Vector2 = cfg.B
		var C: Vector2 = cfg.C
		var xr: Array = cfg.xr
		var yr: Array = cfg.yr
		var cnt := [xr[1] - xr[0], yr[1] - yr[0]]
		var cs := [_at(B, C, xr[0], yr[0]), _at(B, C, xr[1], yr[0]), _at(B, C, xr[1], yr[1]), _at(B, C, xr[0], yr[1])]
		var shapes := [{"k": "skew", "o": [0, 0], "a": _p(B), "b": _p(C), "i": [xr[0] - 1, xr[1] + 1], "j": [yr[0] - 1, yr[1] + 1], "div": 1, "c": "cyan"},
			_poly(cs, "lime", {"fill": "lime", "alpha": 0.22, "at": 3}), _poly(cs, "gold", {"dash": true}),
			_poly([Vector2.ZERO, B, C], "pink", {"fill": "pink", "alpha": 0.3})]
		shapes += _dots({"A": Vector2.ZERO, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [6, -6]})
		var mn := Vector2(INF, INF)
		var mx := Vector2(-INF, -INF)
		for p in cs:
			mn = Vector2(minf(mn.x, p.x), minf(mn.y, p.y))
			mx = Vector2(maxf(mx.x, p.x), maxf(mx.y, p.y))
		var tri: int = cfg.tri
		var total: int = cnt[0] * cnt[1] * 2 * tri
		vars.append({"eq": "%s，\\vec{AP} = x\\vec{AB} + y\\vec{AC}\n%s ≤ x ≤ %s、%s ≤ y ≤ %s，P 圍出的面積？" % [cfg.sides, _fv(xr[0]), _fv(xr[1]), _fv(yr[0]), _fv(yr[1])],
			"plane": _plane([mn.x - 1.0, mx.x + 1.0], [mn.y - 0.8, mx.y + 0.8], shapes),
			"steps": [
				_f("三角形", "先算 △ABC 的面積", "△ABC = [0]", [str(tri)], "△ABC 的面積 = %d" % tri, String(cfg.nt), T_REG),
				_f("一格", "一小格平行四邊形", "一格 = [0] 個 △ABC = [1]", ["2", str(2 * tri)],
					"以 \\vec{AB}、\\vec{AC} 為邊的平行四邊形 = 2△ABC = %d" % (2 * tri), "平行四邊形被對角線切成兩個三角形。", T_REG),
				SB.fill("格數", "數一數稻田有幾格", "[0] × [1] 格", [str(cnt[0]), str(cnt[1])],
					"x 方向 %d 格、y 方向 %d 格" % cnt, "x 從 %d 到 %d 是幾格？" % [xr[0], xr[1]], T_REG),
				_f("面積", "格數 × 一格", "面積 = [0]", [str(total)], "面積 = %d × %d × %d = %d" % [cnt[0], cnt[1], 2 * tri, total],
					"%d 格，每格 %d。" % [cnt[0] * cnt[1], 2 * tri], T_REG),
			]})
		vars[-1].steps[2]["groups"] = [[0, 1]]
	return {"id": "area", "chapter": 1, "type": "forge", "title": "稻田的面積",
		"story": "x、y 各有範圍，稻田圍成一塊平行四邊形。",
		"insight": "x、y 的範圍圍出平行四邊形：邊長是 \\vec{AB}、\\vec{AC} 的倍數\n面積 = x 的範圍長 × y 的範圍長 × 2△ABC。",
		"variants": vars}


# ======================= 第二章．烽台的坐標 =======================

static func _axes(x: Array, y: Array, shapes: Array, named := {}) -> Dictionary:
	return _plane(x, y, shapes, named, {"grid": "axes"})


static func _pt(v: Vector2) -> String:
	return "(%s, %s)" % [_fv(v.x), _fv(v.y)]


## 11 烽台的斜地址（A24）
static func _address() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(2, 1), "b": Vector2(-1, 2), "p": Vector2(3, 4), "xy": [2, 1], "g": 0},
			{"a": Vector2(1, 3), "b": Vector2(2, -1), "p": Vector2(-1, 4), "xy": [1, -1], "g": 1}]:
		var a: Vector2 = cfg.a
		var b: Vector2 = cfg.b
		var p: Vector2 = cfg.p
		var x: int = cfg.xy[0]
		var y: int = cfg.xy[1]
		var shapes := [{"k": "skew", "o": [0, 0], "a": _p(a), "b": _p(b), "i": [-3, 4], "j": [-3, 4], "div": 1, "c": "cyan"},
			_ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"ls": -1, "w": 3.0}), _ar(Vector2.ZERO, b, "pink", "\\vec{b}", {"w": 3.0}),
			_ar(Vector2.ZERO, p, "gold", "\\vec{p}", {"w": 3.5}), _walk([Vector2.ZERO, a * x, a * x + b * y], 3, "lime", true)]
		var opts := ["(%s, %s)" % [_fv(x), _fv(y)], "(%s, %s)" % [_fv(y), _fv(x)], "(%s, %s)" % [_fv(x + 1), _fv(y)], "(%s, %s)" % [_fv(x), _fv(y + 1)]]
		var guess := _c("先猜", "看斜格子猜 (x, y)", opts, 0, "", "", "先猜：{guess}", T_CRD)
		guess["guess"] = true
		vars.append({"eq": "\\vec{a} = %s、\\vec{b} = %s、\\vec{p} = %s\n\\vec{p} = x\\vec{a} + y\\vec{b}，求 (x, y)" % [_pt(a), _pt(b), _pt(p)],
			"plane": _axes([-4, 6], [-2.6, 5.2], shapes),
			"steps": [guess,
				_f("分量", "x 分量、y 分量各一式", "[0]x + [1]y = %s，[2]x + [3]y = %s" % [_n(p.x), _n(p.y)], [str(int(a.x)), str(int(b.x)), str(int(a.y)), str(int(b.y))],
					"%sx + %sy = %s、%sx + %sy = %s" % [_n(a.x), _n(b.x), _n(p.x), _n(a.y), _n(b.y), _n(p.y)], "x\\vec{a} 的 x 分量是 %sx。" % _n(a.x), T_CRD),
				_f("解", "解聯立", "(x, y) = ([0], [1])", [str(x), str(y)], "\\vec{p} = %s\\vec{a} %s %s\\vec{b}" % [
					"" if x == 1 else _n(x), "+" if y >= 0 else "−", "" if absi(y) == 1 else str(absi(y))], "消掉一個未知數。", T_CRD),
			]})
	return {"id": "addr", "chapter": 2, "type": "forge", "title": "烽台的斜地址",
		"story": "同一座烽台，換一組斜格子，地址就不一樣。",
		"insight": "\\vec{p} = x\\vec{a} + y\\vec{b}：x 分量、y 分量各列一式，再解聯立\n斜格子可以先猜大概幾格，算完再對。",
		"variants": vars}


## 12 拼出看不見的箭頭（A25）
static func _hidden() -> Dictionary:
	var vars := []
	for cfg in [{"PA": Vector2(2, -1), "PQ": Vector2(1, 1), "k": 2, "eq": "Q 是 \\ol{AC} 中點，P 是 \\ol{BC} 中點", "x": [-3, 3], "y": [-3.6, 3.6]},
			{"PA": Vector2(1, -2), "PQ": Vector2(1, 0), "k": 3, "eq": "Q 是 \\ol{AC} 中點，P 在 \\ol{BC} 上，\\ol{BP} = 2\\ol{CP}", "x": [-3, 2.5], "y": [-4.6, 3]}]:
		var P := Vector2.ZERO
		var A: Vector2 = cfg.PA
		var Q: Vector2 = cfg.PQ
		var C := 2.0 * Q - A
		var k: int = cfg.k
		var B := P - (k - 1) * C
		var shapes := [_ar(P, A, "cyan", "\\vec{PA}", {"w": 2.5}), _ar(P, Q, "pink", "\\vec{PQ}", {"w": 2.5})]
		shapes += _dots({"P": P, "A": A, "Q": Q}, "text", {"P": [-16, 4], "A": [8, 4], "Q": [8, -6]})
		shapes += [_dot(C, "C", "gold", {"at": 1, "off": [8, -6]}), _seg(A, C, "dim", {"at": 1}),
			_dot(B, "B", "gold", {"at": 3, "off": [8, 4]}), _ar(B, C, "gold", "\\vec{BC}", {"at": 3, "ls": -1, "lt": 0.3}), _seg(A, B, "dim", {"at": 3})]
		var PC := C - P
		var BC := C - B
		vars.append({"eq": "%s\n\\vec{PA} = %s、\\vec{PQ} = %s，求 \\vec{BC}" % [cfg.eq, _pt(A), _pt(Q)],
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vpath", "name": "鋪到 C", "q": "只用 \\vec{PA}、\\vec{PQ} 從 P 鋪到 C", "from": [0, 0], "to": _p(C),
				 "tiles": [{"s": "\\vec{PA}", "v": _p(A)}, {"s": "\\vec{PQ}", "v": _p(Q)}], "sol": [[0, -1], [1, 1], [1, 1]], "tag": T_CRD,
				 "nudge": "Q 是中點：從 A 走到 Q，再走一樣遠就到 C。", "line": "\\vec{PC} = 2\\vec{PQ} − \\vec{PA}（Q 是 \\ol{AC} 的中點）"},
				_f("PC", "算出 \\vec{PC}", "\\vec{PC} = ([0], [1])", [_ans(PC.x), _ans(PC.y)], "\\vec{PC} = %s" % _pt(PC), "2\\vec{PQ} − \\vec{PA}，分量各自算。", T_CRD),
				_f("BC", "\\vec{BC} 是 \\vec{PC} 的幾倍？", "\\vec{BC} = [0]\\vec{PC} = ([1], [2])", [str(k), _ans(BC.x), _ans(BC.y)],
					"\\vec{BC} = %d\\vec{PC} = %s" % [k, _pt(BC)], "\\ol{BC} = \\ol{BP} + \\ol{PC}。", T_CRD),
			]})
	return {"id": "hidden", "chapter": 2, "type": "forge", "title": "拼出看不見的箭頭",
		"story": "只知道兩支箭頭，拼出第三支。",
		"insight": "中點：\\vec{PQ} = \\frac{1}{2}(\\vec{PA} + \\vec{PC}) ⇒ \\vec{PC} = 2\\vec{PQ} − \\vec{PA}\n再用 P 分 \\ol{BC} 的比，放大成 \\vec{BC}。",
		"variants": vars}


## 13 第四座烽台（A26）
static func _fourth() -> Dictionary:
	var vars := []
	for cfg in [{"B": Vector2(8, 6), "C": Vector2(9, -1), "u": ["4/5", "3/5"], "x": [-1.5, 14.5], "y": [-5.5, 7.5]},
			{"B": Vector2(-6, 8), "C": Vector2(2, 12), "u": ["-3/5", "4/5"], "x": [-8, 8], "y": [-1, 17]}]:
		var A := Vector2.ZERO
		var B: Vector2 = cfg.B
		var C: Vector2 = cfg.C
		var u := (B - A) / 10.0
		var D := C - u * 5.0
		var Dbad := C + u * 5.0
		var shapes := [_seg(A, B, "gold", {"w": 2.5}), _seg(B, C, "dim"),
			{"k": "circle", "o": _p(C), "r": 5, "c": "faint", "dash": true, "at": 1},
			_seg(C - u * 7.0, C + u * 7.0, "faint", {"dash": true, "at": 1}),
			_poly([A, B, C, D], "lime", {"fill": "lime", "alpha": 0.15, "at": 2})]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [8, -4], "C": [8, 4]})
		shapes.append(_dot(D, "D", "lime", {"at": 2, "off": [8, 4]}))
		vars.append({"eq": "梯形 ABCD，\\ol{AB} ∥ \\ol{CD}，A%s、B%s、C%s\n\\ol{CD} = 5，求 D" % [_pt(A), _pt(B), _pt(C)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("方向", "\\vec{AB} 方向的單位向量", "\\frac{\\vec{AB}}{|\\vec{AB}|} = ([0], [1])", cfg.u,
					"|\\vec{AB}| = 10，單位向量 (%s, %s)" % [_frs(cfg.u[0]), _frs(cfg.u[1])], "|\\vec{AB}| = √(%s^{2} + %s^{2})。" % [_n(B.x), _n(B.y)], T_CRD),
				{"kind": "vpick", "name": "點出 D", "q": "點出 D（圓和虛線交兩點）", "target": _p(D), "snap": 1, "tag": T_CRD,
				 "traps": [[Dbad.x, Dbad.y, "這樣 ABCD 會交叉：\\vec{DC} 要和 \\vec{AB} 同方向。"]],
				 "nudge": "D 在圓和虛線的交點上。", "line": "\\vec{DC} 和 \\vec{AB} 同方向：D = C − 5 × 單位向量 = %s" % _pt(D)},
			]})
	return {"id": "fourth", "chapter": 2, "type": "forge", "title": "第四座烽台",
		"story": "梯形的上底和下底平行，方向要一樣。",
		"insight": "平行又知道長度：先求單位向量，再乘長度\n方向有兩個（同向、反向），用圖形決定是哪一個。",
		"variants": vars}


## 14 三條橡皮筋（A27）
static func _bands() -> Dictionary:
	var vars := []
	for cfg in [{"pts": [Vector2(-4, 3), Vector2(2, -1), Vector2(4, 3)], "w": [1, 2, 1], "P": Vector2(1, 1), "x": [-6, 7], "y": [-3, 5],
				"eq": "\\vec{PA} + 2\\vec{PB} + \\vec{PC} = \\vec{0}", "opts": ["\\frac{A + 2B + C}{4}", "\\frac{A + B + C}{3}", "\\frac{2A + B + 2C}{5}"]},
			{"pts": [Vector2(1, 3), Vector2(-5, -1), Vector2(7, -5)], "w": [2, 1, 1], "P": Vector2(1, 0), "x": [-7, 9], "y": [-6, 4],
				"eq": "2\\vec{PA} + \\vec{PB} + \\vec{PC} = \\vec{0}", "opts": ["\\frac{2A + B + C}{4}", "\\frac{A + B + C}{3}", "\\frac{A + 2B + 2C}{5}"]}]:
		var pts: Array = cfg.pts
		var w: Array = cfg.w
		var P: Vector2 = cfg.P
		var shapes := [_poly(pts, "faint")]
		for i in 3:
			shapes.append(_seg(P, pts[i], "faint", {"at": 1}))
		shapes += _dots({"A": pts[0], "B": pts[1], "C": pts[2]}, "text", {"A": [8, -6] if pts[0].x > 0 else [-14, -6], "B": [8, 14], "C": [8, -6]})
		shapes.append(_dot(P, "P", "gold", {"at": 1, "off": [8, 16]}))
		var pull := []
		for i in 3:
			pull.append([pts[i].x, pts[i].y, w[i]])
		var sbx := {"label": "P", "lit": [_p(P)], "pull": pull, "start": [P.x - 3, P.y - 2] if P.y - 2 > float(cfg.y[0]) + 0.5 else [P.x - 3, P.y + 2]}
		vars.append({"eq": "A%s、B%s、C%s\n%s，求 P" % [_pt(pts[0]), _pt(pts[1]), _pt(pts[2]), cfg.eq],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "拖 P", "q": "拖 P，讓合力變成 \\vec{0}", "sandbox": sbx, "goal": "lit", "ans": _p(P), "tag": T_WGT,
				 "nudge": "金色的合力箭頭指向 P 該去的方向。", "line": "P%s：三條橡皮筋拉平衡" % _pt(P)},
				_c("公式", "為什麼是這一點？P = ？", cfg.opts, 0,
					"%s ⇒ (A − P) 這種式子展開，P 的係數加起來是 %d。" % [cfg.eq, w[0] + w[1] + w[2]],
					"把 \\vec{PA} 寫成 A − P，整理出 P。", "P = %s = %s" % [cfg.opts[0], _pt(P)], T_WGT),
			]})
	return {"id": "bands", "chapter": 2, "type": "forge", "title": "三條橡皮筋",
		"story": "三條橡皮筋拉著 P，拉平衡的地方在哪裡？",
		"insight": "w_{A}\\vec{PA} + w_{B}\\vec{PB} + w_{C}\\vec{PC} = \\vec{0} ⇒ P = \\frac{w_{A}A + w_{B}B + w_{C}C}{w_{A} + w_{B} + w_{C}}\n就是加權平均：權重大的那一點拉得比較用力。",
		"variants": vars}


## 15 塌掉的斜格子（A28、A29）
static func _collapse() -> Dictionary:
	var A := Vector2(2, 0)
	var B := Vector2(0, 1)
	var sa := [_seg(A + (A - B) * 1.5, Vector2(-4, 3) + (B - A) * 1.5, "faint", {"dash": true, "at": 1}),
		_dot(A, "A", "text", {"off": [8, 16]}), _dot(B, "B", "text", {"off": [-16, -4]}), _dot(Vector2(-4, 3), "C", "pink", {"at": 1, "off": [8, -6]})]
	var va := {"eq": "A(2, 0)、B(0, 1)、C(k, 3)，有一點 P 不能寫成 x\\vec{AB} + y\\vec{AC}\n求 k",
		"plane": _axes([-9, 7], [-2, 4.5], sa),
		"steps": [
			{"kind": "slide", "name": "拖 k", "q": "拖 k，讓斜格子塌成一條線", "tag": T_COL,
			 "params": [{"n": "k", "min": -8, "max": 6, "step": 1, "v": 3}],
			 "lines": [{"k": "skew", "o": [2, 0], "a": [-2, 1], "b": ["k - 2", "3"], "i": [-3, 3], "j": [-2, 2], "div": 1, "c": "cyan"},
				{"k": "arrow", "a": [2, 0], "b": [0, 1], "c": "cyan", "w": 3.0},
				{"k": "arrow", "a": [2, 0], "b": ["k", "3"], "c": "pink", "w": 3.0},
				{"k": "dot", "p": ["k", "3"], "c": "pink", "s": "C"}],
			 "eq": "k = {k}，格子面積 = {abs(-6 - (k - 2))}", "goal": {"k": -4},
			 "line": "k = −4：格子面積變成 0，斜格子塌成一條線", "nudge": "格子面積是 0 的時候。"},
			_f("共線", "\\vec{AC} = t\\vec{AB}", "\\vec{AC} = (k − 2, 3) = t(−2, 1)：t = [0]，k = [1]", ["3", "-4"],
				"A、B、C 共線：\\vec{AC} = 3\\vec{AB}，k = −4", "先看 y 分量。", T_COL),
		]}
	var px := "6 - 3 * t"
	var qy := "8 - 2 * t"
	var when := "abs(t * t - 4 * t + 3) < 0.001"
	var vb := {"eq": "P 從 (6, 0) 每秒 3 往 O、Q 從 (0, 8) 每秒 2 往 O\nR 從 O 每秒 2√2 往 (10, 10) 走，幾秒後三點共線？",
		"plane": _axes([-4, 8], [-1, 8.5], [_seg(Vector2(0, 0), Vector2(8, 8), "faint", {"dash": true}),
			_dot(Vector2(3, 0), "", "lime", {"at": 3}), _dot(Vector2(0, 6), "", "lime", {"at": 3}), _dot(Vector2(2, 2), "", "lime", {"at": 3}),
			_seg(Vector2(4.5, -3), Vector2(-1, 8), "lime", {"at": 3, "dash": true}),
			_dot(Vector2(-3, 0), "", "violet", {"at": 3}), _dot(Vector2(0, 2), "", "violet", {"at": 3}), _dot(Vector2(6, 6), "", "violet", {"at": 3}),
			_seg(Vector2(-4, -2.0 / 3.0), Vector2(8, 22.0 / 3.0), "violet", {"at": 3, "dash": true}),
			_tag(Vector2(3, 0), "t = 1", "lime", {"at": 3, "off": [8, -8]}), _tag(Vector2(-3, 0), "t = 3", "violet", {"at": 3, "off": [-40, -8]})]),
		"steps": [
			{"kind": "slide", "name": "拖時間", "q": "拖 t，數一數共線幾次", "tag": T_COL, "free": true,
			 "params": [{"n": "t", "min": 0, "max": 4, "step": 0.25, "v": 0}],
			 "lines": [{"k": "dot", "p": [px, "0"], "c": "cyan", "s": "P"}, {"k": "dot", "p": ["0", qy], "c": "pink", "s": "Q"},
				{"k": "dot", "p": ["2 * t", "2 * t"], "c": "lime", "s": "R"},
				{"k": "beam", "a": [px, "0"], "b": ["0", qy], "c": "gold", "when": when},
				{"k": "beam", "a": ["0", qy], "b": [px, "0"], "c": "gold", "when": when}],
			 "eq": "t = {t} 秒", "line": "t 從 0 拖到 4，三點排成一直線兩次", "nudge": "從頭拖到尾，看光束亮了幾次。"},
			SB.with_pre(_f("列式", "\\vec{PQ} ∥ \\vec{PR}", "[0]t^{2} − [1]t + [2] = 0", ["16", "64", "48"],
				"(3t − 6)(2t) − (8 − 2t)(5t − 6) = 0 ⇒ t^{2} − 4t + 3 = 0", "交叉相乘相減，再整理。", T_COL, "prop"),
				"\\vec{PQ} = (3t − 6, 8 − 2t)、\\vec{PR} = (5t − 6, 2t)"),
			_f("解", "解方程式", "t = [0] 或 [1]", ["1", "3"], "t = 1 或 3 秒", "因式分解。", T_COL),
		]}
	vb.steps[2]["groups"] = [[0, 1]]
	return {"id": "collapse", "chapter": 2, "type": "forge", "title": "塌掉的斜格子",
		"story": "三點排成一直線時，斜格子就撐不開了。",
		"insight": "\\vec{AB}、\\vec{AC} 共線（平行）時，平面上的點不能都寫成 x\\vec{AB} + y\\vec{AC}\n判斷共線：兩個向量的分量成比例（交叉相乘相等）。",
		"variants": [va, vb]}


## 16 中點烽台（A30）
static func _midpts() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(1, 5), "B": Vector2(-1, 1), "C": Vector2(5, 1), "x": [-3, 7], "y": [-1, 6.2]},
			{"A": Vector2(0, 6), "B": Vector2(-4, 0), "C": Vector2(6, 2), "x": [-6, 8], "y": [-1, 7.8]}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var C: Vector2 = cfg.C
		var D := (B + C) / 2.0
		var E := (C + A) / 2.0
		var F := (A + B) / 2.0
		var G := (D + E + F) / 3.0
		var shapes := [_poly([D, E, F], "cyan", {"fill": "cyan", "alpha": 0.15})]
		shapes += _dots({"D": D, "E": E, "F": F}, "cyan", {"D": [-4, 18], "E": [8, -4], "F": [-16, -4]})
		shapes += [_poly([A, B, C], "gold", {"at": 1}), _dot(A, "A", "gold", {"at": 1, "off": [8, -4]}), _dot(C, "C", "gold", {"at": 1, "off": [8, 4]}),
			_dot(B, "B", "gold", {"at": 1, "off": [-16, 4]}), {"k": "circle", "o": _p(G), "r": 0.18, "c": "gold", "fill": "gold", "alpha": 0.6, "at": 2}]
		vars.append({"eq": "D%s、E%s、F%s 是 \\ol{BC}、\\ol{CA}、\\ol{AB} 的中點\n求 B 和 △DEF 的重心" % [_pt(D), _pt(E), _pt(F)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vpick", "name": "點出 B", "q": "BDEF 是平行四邊形，點出 B", "target": _p(B), "snap": 1, "tag": T_CRD,
				 "traps": [[A.x, A.y, "這是 A：B 要和 E 隔著 \\ol{DF} 相對。"], [C.x, C.y, "這是 C：B 要和 E 隔著 \\ol{DF} 相對。"]],
				 "nudge": "\\vec{FB} = \\vec{ED}。", "line": "B = D + F − E = %s" % _pt(B)},
				_f("重心", "△DEF 的重心", "([0], [1])", [_ans(G.x), _ans(G.y)], "△DEF 的重心 = △ABC 的重心 = %s" % _pt(G),
					"三個頂點的坐標相加除以 3。", T_CRD),
			]})
	return {"id": "midpts", "chapter": 2, "type": "forge", "title": "中點烽台",
		"story": "只剩三邊中點的烽台，找回原本的三角形。",
		"insight": "中點三角形：BDEF、CEFD、AFDE 都是平行四邊形，B = D + F − E\n中點三角形和原三角形的重心是同一點。",
		"variants": vars}


## 17 合力指向哪裡（A31）
static func _pull_min() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(4, 1), "B": Vector2(-2, 4), "G": Vector2(2, 2), "m": 6}, {"A": Vector2(3, -2), "B": Vector2(0, 7), "G": Vector2(2, 1), "m": 3}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var G: Vector2 = cfg.G
		var shapes := _dots({"A": A, "B": B}, "text", {"A": [8, -4], "B": [-16, -4]})
		shapes += [_dot(G, "G", "gold", {"at": 3, "off": [8, -6]}), _seg(G, Vector2(G.x, 0), "gold", {"at": 4, "dash": true}),
			_dot(Vector2(G.x, 0), "P", "gold", {"at": 4, "off": [6, 18]})]
		var tipx := "t + 2 * (%s - t) + (%s - t)" % [A.x, B.x]
		var tipy := "2 * %s + %s" % [A.y, B.y]
		var y_lo := minf(-1.5, minf(A.y, B.y) - 1.0)
		vars.append({"eq": "A%s、B%s，P 在 x 軸上\n求 |2\\vec{PA} + \\vec{PB}| 的最小值" % [_pt(A), _pt(B)],
			"plane": _axes([-5, 9], [y_lo, maxf(A.y, B.y) + 3.0], shapes),
			"steps": [
				{"kind": "slide", "name": "拖 P", "q": "拖 P，看合力箭頭", "tag": T_WGT, "free": true,
				 "params": [{"n": "t", "min": -4, "max": 8, "step": 0.5, "v": -3}],
				 "lines": [{"k": "arrow", "a": ["t", "0"], "b": ["t + 2 * (%s - t)" % A.x, "2 * %s" % A.y], "c": "cyan", "w": 2.0},
					{"k": "arrow", "a": ["t + 2 * (%s - t)" % A.x, "2 * %s" % A.y], "b": [tipx, tipy], "c": "pink", "w": 2.0},
					{"k": "arrow", "a": ["t", "0"], "b": [tipx, tipy], "c": "gold", "w": 3.5},
					{"k": "dot", "p": ["t", "0"], "c": "gold", "s": "P"}],
				 "eq": "P = ({t}, 0)\n|2\\vec{PA} + \\vec{PB}| ≈ {round(sqrt(pow(%s, 2) + pow(%s, 2)) * 100) / 100}" % [tipx + " - t", tipy],
				 "line": "不管 P 在哪裡，合力箭頭都穿過同一點", "nudge": "拉動滑桿，看金色箭頭。"},
				_c("合力", "G = \\frac{2A + B}{3}，2\\vec{PA} + \\vec{PB} = ？", ["3\\vec{PG}", "\\vec{PG}", "3\\vec{GP}"], 0,
					"2(A − P) + (B − P) = (2A + B) − 3P = 3(G − P)。", "把 \\vec{PA} 寫成 A − P。", "2\\vec{PA} + \\vec{PB} = 3\\vec{PG}", T_WGT),
				_f("G", "求 G", "G = ([0], [1])", [_ans(G.x), _ans(G.y)], "G = \\frac{2A + B}{3} = %s" % _pt(G), "2A + B 再除以 3。", T_WGT),
				_f("最小", "|3\\vec{PG}| 最小：P 在 G 正下方", "最小值 = 3 × [0] = [1]", [_ans(absf(G.y)), str(cfg.m)],
					"P = (%s, 0) 時最小：3 × %s = %d" % [_fv(G.x), _fv(absf(G.y)), cfg.m], "G 到 x 軸的距離是多少？", T_WGT),
			]})
	return {"id": "pullmin", "chapter": 2, "type": "forge", "title": "合力指向哪裡",
		"story": "兩條橡皮筋一起拉，合力總是指向同一點。",
		"insight": "2\\vec{PA} + \\vec{PB} = 3\\vec{PG}，G = \\frac{2A + B}{3}（加權平均）\n|3\\vec{PG}| 最小：P 是 G 在 x 軸上的投影。",
		"variants": vars}


## 18 單位圓的鏡框（A32）
static func _unit() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(3, -4), "k": 0.2, "st": 0.1, "e": ["3/5", "-4/5"], "x": [-3, 4], "y": [-4.6, 1.6]},
			{"a": Vector2(-8, 6), "k": 0.1, "st": 0.05, "e": ["-4/5", "3/5"], "x": [-9, 3], "y": [-1.6, 6.6]}]:
		var a: Vector2 = cfg.a
		var L := a.length()
		var shapes := [{"k": "circle", "o": [0, 0], "r": 1, "c": "gold", "w": 2.5}, _ar(Vector2.ZERO, a, "faint", "\\vec{a}", {"w": 2.0})]
		var arrow := {"k": "arrow", "a": [0, 0], "b": ["%s * k" % a.x, "%s * k" % a.y], "c": "cyan", "w": 3.0}
		var sl := func(name: String, q: String, goal: float, line: String) -> Dictionary:
			return {"kind": "slide", "name": name, "q": q, "tag": T_CRD, "params": [{"n": "k", "min": -1, "max": 1, "step": cfg.st, "v": 1}],
				"lines": [arrow], "eq": "k = {k}，|k\\vec{a}| = {abs(k) * %s}" % L, "goal": {"k": goal}, "line": line,
				"nudge": "|\\vec{a}| = %s，k 要是多少才變成 1？" % _n(L), "keep": true}
		var ks := _fv(float(cfg.k))
		var e := Vector2(B1._frv(cfg.e[0]), B1._frv(cfg.e[1]))
		vars.append({"eq": "\\vec{a} = %s，求和 \\vec{a} 平行的單位向量" % _pt(a),
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				sl.call("縮短", "拖 k，縮到單位圓上", cfg.k, "k = %s：%s\\vec{a} 長度是 1" % [ks, ks]),
				sl.call("反方向", "反方向也有一個", -cfg.k, "k = −%s：反方向也是單位向量" % ks),
				_f("單位向量", "同方向的那一個", "\\vec{e} = ([0], [1])", cfg.e,
					"\\vec{e} = ±%s" % _pt(e), "\\frac{\\vec{a}}{|\\vec{a}|}，|\\vec{a}| = %s。" % _n(L), T_CRD),
			]})
		vars[-1].steps[2]["alts"] = [[_ans(-e.x), _ans(-e.y)]]
	return {"id": "unit", "chapter": 2, "type": "forge", "title": "單位圓的鏡框",
		"story": "把箭頭縮到剛好碰到單位圓的鏡框。",
		"insight": "和 \\vec{a} 平行的單位向量：±\\frac{\\vec{a}}{|\\vec{a}|}（兩個方向）\n|k\\vec{a}| = |k||\\vec{a}|。",
		"variants": vars}


## 19 菱形的對角線（A33）
static func _bisect() -> Dictionary:
	var vars := []
	for cfg in [{"la": 4, "lb": 3, "a": Vector2(4, 0), "b": Vector2(1.8, 2.4),
				"opts": ["3\\vec{a} + 4\\vec{b}", "4\\vec{a} + 3\\vec{b}", "\\vec{a} + \\vec{b}", "\\frac{1}{3}\\vec{a} + \\frac{1}{4}\\vec{b}"]},
			{"la": 2, "lb": 5, "a": Vector2(2, 0), "b": Vector2(-3, 4),
				"opts": ["5\\vec{a} + 2\\vec{b}", "2\\vec{a} + 5\\vec{b}", "\\vec{a} + \\vec{b}", "\\frac{1}{5}\\vec{a} + \\frac{1}{2}\\vec{b}"]}]:
		var a: Vector2 = cfg.a
		var b: Vector2 = cfg.b
		var ua := a / float(cfg.la)
		var ub := b / float(cfg.lb)
		var d := (ua + ub).normalized()
		var shapes := [_ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"ls": -1, "w": 2.5}), _ar(Vector2.ZERO, b, "pink", "\\vec{b}", {"w": 2.5}),
			_poly([Vector2.ZERO, ua, ua + ub, ub], "gold", {"fill": "gold", "alpha": 0.15, "at": 1}),
			_ar(Vector2.ZERO, ua, "cyan", "", {"at": 1, "w": 3.5}), _ar(Vector2.ZERO, ub, "pink", "", {"at": 1, "w": 3.5}),
			_ar(Vector2.ZERO, d * 4.2, "gold", "\\vec{v}", {"at": 2, "w": 3.0})]
		vars.append({"eq": "|\\vec{a}| = %d、|\\vec{b}| = %d，\\vec{v} 和 \\vec{a}、\\vec{b} 的夾角一樣大\n\\vec{v} 可能是哪一個？" % [cfg.la, cfg.lb],
			"plane": _plane([-4, 5.5], [-0.8, 4.6], shapes),
			"steps": [
				_f("單位向量", "都縮成長度 1", "\\frac{\\vec{a}}{[0]}、\\frac{\\vec{b}}{[1]}", [str(cfg.la), str(cfg.lb)],
					"\\frac{\\vec{a}}{%d}、\\frac{\\vec{b}}{%d} 都是單位向量，相加是菱形的對角線" % [cfg.la, cfg.lb], "除以自己的長度。", T_CRD),
				_c("選", "\\vec{v} 可能是？", cfg.opts, 0,
					"\\frac{\\vec{a}}{%d} + \\frac{\\vec{b}}{%d} 乘 %d 就是 %s。" % [cfg.la, cfg.lb, cfg.la * cfg.lb, cfg.opts[0]],
					"要是 \\frac{\\vec{a}}{%d} + \\frac{\\vec{b}}{%d} 的倍數。" % [cfg.la, cfg.lb], "\\vec{v} ∥ \\frac{\\vec{a}}{%d} + \\frac{\\vec{b}}{%d}，選 %s" % [cfg.la, cfg.lb, cfg.opts[0]], T_CRD),
			]})
	return {"id": "bisect", "chapter": 2, "type": "forge", "title": "菱形的對角線",
		"story": "兩支一樣長的箭頭，相加剛好在正中間。",
		"insight": "角平分向量：\\frac{\\vec{a}}{|\\vec{a}|} + \\frac{\\vec{b}}{|\\vec{b}|}（兩支單位向量是菱形的兩邊）\n\\vec{a} + \\vec{b} 只有在 |\\vec{a}| = |\\vec{b}| 時才平分夾角。",
		"variants": vars}


## 20 坐標的珠子（A34）
static func _coord_bead() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(4, -1), "B": Vector2(-6, 4), "den": 5, "goal": 3, "max": 5, "P": Vector2(-2, 2),
				"eq": "A(4, −1)、B(−6, 4)，P 在 \\ol{AB} 上，\\ol{AP} : \\ol{PB} = 3 : 2\n求 P", "tpl": "P = \\frac{[0]A + [1]B}{5}", "ans": ["2", "3"],
				"r": "{n} : {5 - n}", "x": [-7, 5], "y": [-2, 5]},
			{"A": Vector2(-3, 2), "B": Vector2(1, 4), "den": 4, "goal": 6, "max": 8, "P": Vector2(3, 5),
				"eq": "A(−3, 2)、B(1, 4)，P 在直線 AB 上、B 的外面\n\\ol{AP} : \\ol{PB} = 3 : 1，求 P", "tpl": "P = \\frac{[0]B − A}{[1]}", "ans": ["3", "2"],
				"r": "{n} : {abs(4 - n)}", "x": [-4, 5], "y": [0, 6.5]}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var P: Vector2 = cfg.P
		var den: int = cfg.den
		var shapes := [_seg(A, B, "gold", {"w": 3.0}), _seg(B, B + (B - A) * 0.6, "faint", {"dash": true})]
		shapes += _dots({"A": A, "B": B}, "text", {"A": [-6, 18], "B": [-6, -10]})
		shapes.append(_dot(P, "P", "gold", {"at": 1, "off": [8, -6]}))
		vars.append({"eq": cfg.eq, "plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "slide", "name": "拖珠子", "q": "拖珠子到對的位置", "tag": T_CRD,
				 "params": [{"n": "n", "min": 0, "max": cfg.max, "step": 1, "v": 1}],
				 "lines": [{"k": "dot", "p": ["%s + n / %d.0 * (%s)" % [A.x, den, B.x - A.x], "%s + n / %d.0 * (%s)" % [A.y, den, B.y - A.y]], "c": "gold", "s": "P"}],
				 "eq": "\\ol{AP} : \\ol{PB} = " + String(cfg.r), "goal": {"n": cfg.goal},
				 "line": "P 的位置：\\ol{AP} : \\ol{PB} = %s" % ("3 : 2" if den == 5 else "3 : 1（在 B 外面）"), "nudge": "看讀數的比。"},
				_f("公式", "分點公式", cfg.tpl, cfg.ans, cfg.tpl.replace("[0]", cfg.ans[0]).replace("[1]", cfg.ans[1]),
					"靠近誰，誰的權重大。" if den == 5 else "外分點：\\frac{mB − nA}{m − n}。", T_CRD),
				_f("坐標", "算出 P", "P = ([0], [1])", [_ans(P.x), _ans(P.y)], "P = %s" % _pt(P), "x、y 分量各自算。", T_CRD),
			]})
	return {"id": "cbead", "chapter": 2, "type": "forge", "title": "坐標的珠子",
		"story": "繩橋搬到坐標方格上，珠子也有坐標了。",
		"insight": "內分點 P = \\frac{nA + mB}{m + n}（\\ol{AP} : \\ol{PB} = m : n）\n外分點 P = \\frac{mB − nA}{m − n}：分量各自代進去。",
		"variants": vars}
