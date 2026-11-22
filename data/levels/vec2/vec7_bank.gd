extends RefCounted
## 平面向量 第七大關「弓帆工坊」題庫（下冊 3-3 重點二、三：柯西不等式、三角不等式、面積公式）
## 設計稿：docs/vec2_v7_design.md。數字都用程式驗算過（tools/vec2/verify_v7.py）。B41 整題記到終焉之塔（docs/vec2_tower_backlog.md）。
##
## 引擎見 vec_level.gd（箭頭畫布、在圖上作答），圖層見 vec_board.gd。這一關多用了：
##   vplace 沙盒的 sail（帆：拖的點和兩點張成三角形）、圖層 ellipse（等高線）、plot（滑桿旁的小函數圖）。
## 極值題的共通做法：先拖（滑桿或拖點，讀數跟著變）找到最小（大）的地方，再用柯西列式算出來。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/vec2/vec1_bank.gd")
const B6 := preload("res://data/levels/vec2/vec6_bank.gd")

const T_CAU := "vec_cauchy"       # 柯西不等式
const T_CAP := "vec_cauchyapp"    # 柯西的應用（配方、倒數、幾何）
const T_TRI := "vec_triineq"      # 三角不等式
const T_AREA := "vec_areaf"       # 面積公式


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return B1._f(name, q, template, answers, line, nudge, tag, mode)


static func _j(name: String, statement: String, ok: bool, why: String, line: String, tag: String) -> Dictionary:
	return B6._j(name, statement, ok, why, line, tag)


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


## 負數加括號：3 × (−1)
static func _par(v: float) -> String:
	return "(%s)" % B6._num(v) if v < 0 else B6._num(v)


static func _fillp(pts: Array, c := "lime", at := 0) -> Dictionary:
	return _poly(pts, c, {"fill": c, "alpha": 0.2, "at": at})


static func _plane(x: Array, y: Array, shapes: Array, named := {}, extra := {}) -> Dictionary:
	return B1._plane(x, y, shapes, named, extra)


static func _axes(x: Array, y: Array, shapes: Array) -> Dictionary:
	return _plane(x, y, shapes, {}, {"grid": "axes"})


static func _right(p: Vector2, u: Vector2, v: Vector2, extra := {}) -> Dictionary:
	return B6._right(p, u, v, extra)


static func _L(a: float, b: float, c: float, col := "cyan", s := "", extra := {}) -> Dictionary:
	return B6._L(a, b, c, col, s, extra)


static func _e(v: float) -> String:
	return B6._e(v)


static func _pt(v: Vector2) -> String:
	return B6._pt(v)


static func _circ(o: Vector2, r: float, c := "faint", extra := {}) -> Dictionary:
	var d := {"k": "ellipse", "o": _p(o), "rx": r, "ry": r, "c": c, "w": 1.6}
	d.merge(extra, true)
	return d


## 上半圓（半圓湖、只知道長度的那支箭頭）
static func _half(o: Vector2, r: float, c := "faint", extra := {}) -> Dictionary:
	var d := {"k": "arc", "o": _p(o), "r": r, "a0": 0, "a1": 180, "c": c}
	d.merge(extra, true)
	return d


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
		_bow(), _taut(), _tidy(), _ringbow(), _poles(), _inv(), _ineq(), _dist2(), _lake(),
		{"id": "speed1", "chapter": 1, "type": "speed", "title": "弓弦速算", "time": 120.0,
		 "story": "直線上離原點最近的點，平方距離是多少？",
		 "insight": "ax + by = k：(x^{2} + y^{2})(a^{2} + b^{2}) ≥ k^{2}\nx^{2} + y^{2} 的最小值是 \\frac{k^{2}}{a^{2} + b^{2}}。",
		 "variants": [{"gen": "cauchy", "count": 8}]},
		_sail(), _lenonly(), _csail(), _sjudge(), _squares(), _skewcloth(), _open(),
		{"id": "speed2", "chapter": 2, "type": "speed", "title": "帆布速算", "time": 120.0,
		 "story": "兩支箭頭張成的帆，面積是多少？",
		 "insight": "\\vec{a} = (a_{1}, a_{2})、\\vec{b} = (b_{1}, b_{2})\n三角形面積 = \\frac{1}{2}|a_{1}b_{2} − a_{2}b_{1}|。",
		 "variants": [{"gen": "area", "count": 8}]},
	]


# ======================= 第一章．柯西不等式與三角不等式 =======================

## 1 弓弦（B30＋新）
static func _bow() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(5, 0), "r": 3.0, "a0": 0.0, "mx": 15, "start": [0, 3], "dotx": "5 * x", "x": [-6.5, 6.5], "y": [-3.4, 3.4]},
			{"a": Vector2(3, 4), "r": 2.0, "a0": 53.130102, "mx": 10, "start": [-2, 0], "dotx": "3 * x + 4 * y", "x": [-7.0, 7.0], "y": [-2.6, 4.6]}]:
		var a: Vector2 = cfg.a
		var r: float = cfg.r
		var u := a.normalized() * r
		var mx := int(cfg.mx)
		var ring := {"o": [0, 0], "r": r, "step": 15, "a0": cfg.a0}
		var sb := {"label": "", "ring": ring, "arrow": {"o": [0, 0], "c": "lime", "s": "\\vec{b}", "ls": -1}, "start": cfg.start,
			"read": "\\vec{a} · \\vec{b} = {%s}" % cfg.dotx}
		var s1 := sb.duplicate(true)
		s1["lit"] = "abs(%s - %d) < 0.01" % [cfg.dotx, mx]
		var s2 := sb.duplicate(true)
		s2["lit"] = "abs(%s + %d) < 0.01" % [cfg.dotx, mx]
		var shapes := [_circ(Vector2.ZERO, r), _ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"w": 3.5}),
			_ar(Vector2.ZERO, u, "gold", "", {"at": 1, "until": 2, "w": 4.0}), _ar(Vector2.ZERO, -u, "violet", "", {"at": 2, "until": 3, "w": 4.0}),
			_ar(Vector2.ZERO, u, "gold", "", {"at": 3, "w": 3.0}), _ar(Vector2.ZERO, -u, "violet", "", {"at": 3, "w": 3.0})]
		var la := "|\\vec{a}| = %d、|\\vec{b}| = %d" % [int(a.length()), int(r)]
		vars.append({"eq": "%s\n\\vec{a} · \\vec{b} 最大、最小是多少？" % la, "plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "拉最緊", "q": "轉 \\vec{b}，讓內積最大", "tag": T_CAU, "goal": "lit", "ans": _p(u), "big": true,
				 "sandbox": s1, "nudge": "\\vec{b} 和 \\vec{a} 同方向的時候，影子最長。", "line": "同方向：\\vec{a} · \\vec{b} = %d × %d = %d" % [int(a.length()), int(r), mx]},
				{"kind": "vplace", "name": "放最鬆", "q": "轉 \\vec{b}，讓內積最小", "tag": T_CAU, "goal": "lit", "ans": _p(-u), "big": true,
				 "sandbox": s2, "nudge": "轉到和 \\vec{a} 反方向。", "line": "反方向：\\vec{a} · \\vec{b} = −%d" % mx},
				_f("範圍", "內積的範圍", "[0] ≤ \\vec{a} · \\vec{b} ≤ [1]", [str(-mx), str(mx)],
					"|\\vec{a} · \\vec{b}| ≤ |\\vec{a}||\\vec{b}| = %d" % mx, "|\\vec{a}||\\vec{b}| cos θ，cos θ 在 −1 到 1 之間。", T_CAU),
				_c("等號", "最大的時候兩支箭頭", ["同方向", "垂直", "反方向"], 0, "cos θ = 1：θ = 0°，同方向。", "看第一步燈亮的時候。",
					"等號成立：兩支向量平行（最大同向、最小反向）", T_CAU),
			]})
	return {"id": "kbow", "chapter": 1, "type": "forge", "title": "弓弦",
		"story": "兩支箭頭對齊的時候，弓弦拉得最緊。",
		"insight": "|\\vec{a} · \\vec{b}| ≤ |\\vec{a}||\\vec{b}|（柯西不等式）\n等號成立：\\vec{a} ∥ \\vec{b}（同方向最大、反方向最小）。",
		"variants": vars}


## 2 拉最緊的弓（B27）
static func _taut() -> Dictionary:
	var vars := []
	for cfg in [{"L": [2, 3, 10], "p": 2, "q": 3, "fx": "2*u*u + 3*pow((10 - 2*u)/3, 2)", "y": "(10 - 2 * t) / 3", "u": [-1, 5], "v0": 4,
				"goal": 2, "P": Vector2(2, 2), "mn": 20, "w": ["2", "3"], "lhs": "2x^{2} + 3y^{2}", "rx": sqrt(10.0), "ry": sqrt(20.0 / 3.0),
				"eqn": "2x + 3y = 10", "corner": "tr", "par": "(√2x, √3y) ∥ (√2, √3) ⇒ x = y", "x": [-5.0, 7.0], "y_": [-3.0, 4.2]},
			{"L": [1, -2, 9], "p": 1, "q": 2, "fx": "u*u + 2*pow((u - 9)/2, 2)", "y": "(t - 9) / 2", "u": [0, 6], "v0": 5,
				"goal": 3, "P": Vector2(3, -3), "mn": 27, "w": ["1", "2"], "lhs": "x^{2} + 2y^{2}", "rx": sqrt(27.0), "ry": sqrt(13.5),
				"eqn": "x − 2y = 9", "corner": "", "par": "(x, √2y) ∥ (1, −√2) ⇒ y = −x", "x": [-6.5, 9.5], "y_": [-4.6, 3.6]}]:
		var L: Array = cfg.L
		var P: Vector2 = cfg.P
		var k := int(L[2])
		var shapes := [_L(L[0], L[1], -L[2], "cyan", cfg.eqn),
			{"k": "ellipse", "o": [0, 0], "rx": cfg.rx, "ry": cfg.ry, "c": "gold", "fill": "gold", "alpha": 0.1, "at": 4},
			_dot(P, "P", "gold", {"at": 4, "off": [10, -8]})]
		var lines := [{"k": "dot", "p": ["t", cfg.y], "c": "gold", "s": "P"},
			{"k": "plot", "f": cfg.fx, "u0": cfg.u[0], "u1": cfg.u[1], "cur": "t", "corner": cfg.corner}]
		var fe := String(cfg.fx).replace("u", "t")
		vars.append({"eq": "%s，求 %s 的最小值\n和那時候的 (x, y)" % [cfg.eqn, cfg.lhs], "plane": _axes(cfg.x, cfg.y_, shapes),
			"steps": [
				{"kind": "slide", "name": "拖 P", "q": "拖 P，找最小的地方", "tag": T_CAU,
				 "params": [{"n": "t", "min": cfg.u[0], "max": cfg.u[1], "step": 0.5, "v": cfg.v0}], "lines": lines, "goal": {"t": cfg.goal},
				 "eq": "x = {t}：%s = {%s}" % [cfg.lhs, fe], "line": "P%s 的時候最小" % _pt(P), "nudge": "看角落的小圖：最低點在哪裡？"},
				_f("柯西", "湊成兩支向量", "(%s)([0] + [1]) ≥ %d^{2}" % [cfg.lhs, k], cfg.w,
					"(%s)(%s + %s) ≥ (%s)^{2} = %d" % [cfg.lhs, cfg.w[0], cfg.w[1], cfg.eqn.split(" = ")[0], k * k],
					"兩支向量的內積要剛好是 %s。" % cfg.eqn.split(" = ")[0], T_CAU, "set"),
				_f("最小值", "兩邊除過去", "最小值 [0]", [str(cfg.mn)], "%s ≥ \\frac{%d}{%d} = %d" % [cfg.lhs, k * k, int(cfg.w[0]) + int(cfg.w[1]), int(cfg.mn)],
					"%d 除以 %s + %s。" % [k * k, cfg.w[0], cfg.w[1]], T_CAU),
				_f("等號", "等號成立的點", "(x, y) = ([0], [1])", [B6._ans(P.x), B6._ans(P.y)], "等號：%s，代進去得 %s" % [cfg.par, _pt(P)],
					"兩支向量平行，再代回直線。", T_CAU),
			]})
	return {"id": "ktaut", "chapter": 1, "type": "forge", "title": "拉最緊的弓",
		"story": "沿著直線拉弓，哪裡拉得最緊？",
		"insight": "(px^{2} + qy^{2})(\\frac{a^{2}}{p} + \\frac{b^{2}}{q}) ≥ (ax + by)^{2}\n等號成立：兩支向量平行，橢圓剛好碰到直線。",
		"variants": vars}


## 3 先整理弓弦（B28）
static func _tidy() -> Dictionary:
	var vars := []
	for cfg in [{"L": [1, 2, 10], "Q": Vector2(2, -1), "P": Vector2(4, 3), "f": "x^{2} + y^{2} − 4x + 2y", "eqn": "x + 2y = 10",
				"t1": "(x − [0])^{2} + (y + [1])^{2} − [2]", "a1": ["2", "1", "5"], "l1": "(x − 2)^{2} + (y + 1)^{2} − 5",
				"t2": "u + 2v = [0]", "l2": "u = x − 2、v = y + 1：u + 2v = 10", "mn": 15, "l3": "(u^{2} + v^{2})(1 + 4) ≥ 100 ⇒ u^{2} + v^{2} ≥ 20，20 − 5 = 15",
				"l4": "(u, v) ∥ (1, 2) ⇒ u = 2、v = 4 ⇒ (4, 3)", "x": [-6.0, 12.0], "y": [-5.8, 5.6]},
			{"L": [2, -1, 3], "Q": Vector2(-3, 1), "P": Vector2(1, -1), "f": "x^{2} + y^{2} + 6x − 2y", "eqn": "2x − y = 3",
				"t1": "(x + [0])^{2} + (y − [1])^{2} − [2]", "a1": ["3", "1", "10"], "l1": "(x + 3)^{2} + (y − 1)^{2} − 10",
				"t2": "2u − v = [0]", "l2": "u = x + 3、v = y − 1：2u − v = 10", "mn": 10, "l3": "(u^{2} + v^{2})(4 + 1) ≥ 100 ⇒ u^{2} + v^{2} ≥ 20，20 − 10 = 10",
				"l4": "(u, v) ∥ (2, −1) ⇒ u = 4、v = −2 ⇒ (1, −1)", "x": [-10.0, 7.0], "y": [-3.8, 5.8]}]:
		var L: Array = cfg.L
		var Q: Vector2 = cfg.Q
		var P: Vector2 = cfg.P
		var shapes := [_L(L[0], L[1], -L[2], "cyan", cfg.eqn), _dot(Q, "Q", "pink", {"at": 1, "off": [-16, -6]}),
			_circ(Q, sqrt(20.0), "gold", {"at": 4, "w": 2.0}), _seg(Q, P, "gold", {"at": 4, "dash": true}),
			_right(P, Vector2(L[1], -L[0]), Q - P, {"at": 4}), _dot(P, "P", "gold", {"at": 4, "off": [10, -8]})]
		vars.append({"eq": "%s，求 %s 的最小值\n和那時候的 (x, y)" % [cfg.eqn, cfg.f], "plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("配方", "先配方", cfg.t1, cfg.a1, "%s = %s" % [cfg.f, cfg.l1], "x、y 各自湊成完全平方。", T_CAP),
				_f("換變數", "u、v 的條件", cfg.t2, ["10"], cfg.l2, "x、y 換成 u、v 代進 %s。" % cfg.eqn, T_CAP),
				_f("最小值", "柯西", "最小值 [0]", [str(cfg.mn)], cfg.l3, "先算 u^{2} + v^{2} 的最小值，再減回去。", T_CAP),
				_f("等號", "等號成立的點", "(x, y) = ([0], [1])", [B6._ans(P.x), B6._ans(P.y)], "等號：%s" % cfg.l4, "(u, v) 和係數平行。", T_CAP),
			]})
	return {"id": "ktidy", "chapter": 1, "type": "forge", "title": "先整理弓弦",
		"story": "弓弦纏在一起，先整理好再拉。",
		"insight": "先配方：(x − h)^{2} + (y − k)^{2} 是到 (h, k) 的距離平方\n再換成 u、v 用柯西：圓剛好碰到直線。",
		"variants": vars}


## 4 圓上的弓（B29）
static func _ringbow() -> Dictionary:
	var vars := []
	for cfg in [{"av": "(x, 3)", "bv": "(4, y)", "c": Vector2(4, 3), "r2": 25, "P": Vector2(-4, -3), "mn": -25, "x": [-10.0, 10.0], "y": [-6.0, 6.0], "start": [3, 4]},
			{"av": "(x, 2)", "bv": "(1, y)", "c": Vector2(1, 2), "r2": 5, "P": Vector2(-1, -2), "mn": -5, "x": [-5.0, 5.0], "y": [-3.0, 3.0], "start": [2, 1]}]:
		var c: Vector2 = cfg.c
		var P: Vector2 = cfg.P
		var r2 := int(cfg.r2)
		var lin := "%s * x + %s * y" % [_e(c.x), _e(c.y)]
		var lins := B6._lin2(c.x, c.y, 0.0)
		var shapes := [_circ(Vector2.ZERO, sqrt(r2), "cyan", {"w": 2.0}), _ar(Vector2.ZERO, c, "pink", _pt(c), {"at": 1}),
			_ar(Vector2.ZERO, P, "gold", "", {"at": 2, "w": 3.5}), _dot(P, "", "gold", {"at": 2})]
		vars.append({"eq": "\\vec{a} = %s、\\vec{b} = %s，x^{2} + y^{2} = %d\n求 \\vec{a} · \\vec{b} 的最小值" % [cfg.av, cfg.bv, r2],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("內積", "\\vec{a} · \\vec{b}", "\\vec{a} · \\vec{b} = [0]x + [1]y", [B6._ans(c.x), B6._ans(c.y)], "\\vec{a} · \\vec{b} = %s" % lins,
					"對應的坐標相乘再相加。", T_CAU),
				{"kind": "vplace", "name": "找最小", "q": "在圓上找最小", "tag": T_CAU, "goal": "lit", "ans": _p(P), "big": true,
				 "sandbox": {"label": "", "arrow": {"o": [0, 0], "c": "lime", "s": "(x, y)", "ls": -1}, "start": cfg.start,
					"lit": "x * x + y * y == %d and %s == %d" % [r2, lin, int(cfg.mn)],
					"read": "x^{2} + y^{2} = {x * x + y * y}   %s = {%s}" % [lins, lin]},
				 "nudge": "(x, y) 要在圓上，而且和 %s 反方向。" % _pt(c), "line": "(x, y) = %s 和 %s 反方向" % [_pt(P), _pt(c)]},
				_f("最小值", "柯西", "最小值 [0]", [str(cfg.mn)],
					"|%s| ≤ √{%s}√{%d} = %d" % [lins, B6._num(c.length_squared()), r2, -int(cfg.mn)], "|\\vec{a} · \\vec{b}| ≤ |(x, y)| × |%s|。" % _pt(c), T_CAU),
			]})
	return {"id": "kring", "chapter": 1, "type": "forge", "title": "圓上的弓",
		"story": "弓的一頭沿著圓走，弦什麼時候最鬆？",
		"insight": "(x, y) 在圓上：|ax + by| ≤ √{a^{2} + b^{2}} × 半徑\n最小在和 (a, b) 反方向的地方。",
		"variants": vars}


## 5 直角的兩根竿子（B31）
static func _poles() -> Dictionary:
	var vars := []
	for cfg in [{"P": Vector2(3, 1), "co": [3, 1, 10], "b": "10 - 3 * a", "a": [1.5, 3.25], "v0": 2, "goal": 3, "mn": "√10", "x": [-6.0, 8.0], "y": [-0.8, 6.2],
				"l2": "(a − 3, −1) · (−3, b − 1) = 0 ⇒ 3a + b = 10", "l3": "(a^{2} + b^{2})(9 + 1) ≥ 100 ⇒ \\ol{AB} ≥ √10"},
			{"P": Vector2(1, 2), "co": [1, 2, 5], "b": "(5 - a) / 2", "a": [0.25, 4.5], "v0": 3, "goal": 1, "mn": "√5", "x": [-4.0, 6.0], "y": [-0.8, 4.2],
				"l2": "(a − 1, −2) · (−1, b − 2) = 0 ⇒ a + 2b = 5", "l3": "(a^{2} + b^{2})(1 + 4) ≥ 25 ⇒ \\ol{AB} ≥ √5"}]:
		var P: Vector2 = cfg.P
		var co: Array = cfg.co
		var bx := String(cfg.b)
		var lines := [{"k": "dot", "p": ["a", "0"], "c": "gold", "s": "A"}, {"k": "dot", "p": ["0", bx], "c": "gold", "s": "B"},
			{"k": "seg", "a": ["a", "0"], "b": ["0", bx], "c": "gold"}, {"k": "seg", "a": [P.x, P.y], "b": ["a", "0"], "c": "pink"},
			{"k": "seg", "a": [P.x, P.y], "b": ["0", bx], "c": "pink"},
			{"k": "plot", "f": "u*u + pow(%s, 2)" % bx.replace("a", "u"), "u0": cfg.a[0], "u1": cfg.a[1], "cur": "a"}]
		var A := Vector2(cfg.goal, 0)
		var B := Vector2(0, (co[2] - co[0] * float(cfg.goal)) / co[1])
		var shapes := [_dot(P, "P", "text", {"off": [10, -8]}), _seg(A, B, "gold", {"at": 1, "w": 3.0}),
			_dot(A, "A", "gold", {"at": 1, "off": [-4, 18]}), _dot(B, "B", "gold", {"at": 1, "off": [-18, -6]}),
			_seg(Vector2.ZERO, P, "violet", {"at": 3, "dash": true, "w": 2.5}), _tag(P * 0.5, "\\ol{OP}", "violet", {"at": 3, "off": [10, 14]})]
		vars.append({"eq": "P%s，A 在 x 軸正向、B 在 y 軸正向\n\\vec{PA} ⊥ \\vec{PB}，求 \\ol{AB} 的最小值" % _pt(P), "plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "slide", "name": "拖 A", "q": "拖 A，找 \\ol{AB} 最短", "tag": T_CAP,
				 "params": [{"n": "a", "min": cfg.a[0], "max": cfg.a[1], "step": 0.25, "v": cfg.v0}], "lines": lines, "goal": {"a": cfg.goal},
				 "eq": "a = {a}：\\ol{AB}^{2} = {a * a + pow(%s, 2)}" % bx, "line": "A%s、B%s 的時候最短" % [_pt(A), _pt(B)],
				 "nudge": "B 會跟著 A 動，讓 \\vec{PA} ⊥ \\vec{PB}。看右下角的小圖。"},
				_f("垂直", "A(a, 0)、B(0, b)", "[0]a + [1]b = [2]", [str(co[0]), str(co[1]), str(co[2])], cfg.l2, "\\vec{PA} · \\vec{PB} = 0 展開。", T_CAP),
				_f("最短", "柯西", "\\ol{AB} 的最小值 [0]", [cfg.mn], cfg.l3, "\\ol{AB}^{2} = a^{2} + b^{2}。", T_CAP),
			]})
	return {"id": "kpoles", "chapter": 1, "type": "forge", "title": "直角的兩根竿子",
		"story": "兩根竿子在 P 拉成直角，竿腳之間最短多遠？",
		"insight": "\\vec{PA} ⊥ \\vec{PB} 變成 a、b 的一次式，再用柯西\n最小值剛好是 \\ol{OP}：O、P 都在以 \\ol{AB} 為直徑的圓上。",
		"variants": vars}


## 6 倒過來的弓（B32）
static func _inv() -> Dictionary:
	var vars := []
	for cfg in [{"co": [3, 1, 10], "uv": [3, 4], "a": [0.5, 3.0], "v0": 1, "goal": 2, "w": ["3", "2"], "mn": "5/2", "ab": ["2", "4"],
				"l3": "(3a + b) = 10 ⇒ \\frac{3}{a} + \\frac{4}{b} ≥ \\frac{25}{10} = \\frac{5}{2}", "l4": "\\frac{1}{a} = \\frac{2}{b} ⇒ b = 2a ⇒ a = 2、b = 4",
				"x": [-6.0, 8.0], "y": [-0.6, 8.6]},
			{"co": [1, 1, 3], "uv": [1, 4], "a": [0.25, 2.75], "v0": 2, "goal": 1, "w": ["1", "2"], "mn": "3", "ab": ["1", "2"],
				"l3": "(a + b) = 3 ⇒ \\frac{1}{a} + \\frac{4}{b} ≥ \\frac{9}{3} = 3", "l4": "\\frac{1}{a} = \\frac{2}{b} ⇒ b = 2a ⇒ a = 1、b = 2",
				"x": [-3.0, 5.0], "y": [-0.6, 3.4]}]:
		var co: Array = cfg.co
		var uv: Array = cfg.uv
		var bx := "(%s - %s * a) / %s" % [_e(co[2]), _e(co[0]), _e(co[1])]
		var fx := "%s / a + %s / (%s)" % [_e(uv[0]), _e(uv[1]), bx]
		var lin := B6._lin2(co[0], co[1], 0.0).replace("x", "a").replace("y", "b")
		var frac := "\\frac{%d}{a} + \\frac{%d}{b}" % [uv[0], uv[1]]
		var lines := [{"k": "dot", "p": ["a", bx], "c": "gold", "s": "(a, b)"}, {"k": "plot", "f": fx.replace("a", "u"), "u0": cfg.a[0], "u1": cfg.a[1], "cur": "a", "corner": "tr"}]
		var shapes := [_L(co[0], co[1], -co[2], "cyan", "%s = %d" % [lin, co[2]])]
		vars.append({"eq": "a、b > 0，%s = %d\n求 %s 的最小值" % [lin, co[2], frac], "plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "slide", "name": "拖 a", "q": "拖 a，找最小的地方", "tag": T_CAP,
				 "params": [{"n": "a", "min": cfg.a[0], "max": cfg.a[1], "step": 0.25, "v": cfg.v0}], "lines": lines, "goal": {"a": cfg.goal},
				 "eq": "a = {a}：%s = {%s}" % [frac, fx], "line": "a = %s、b = %s 的時候最小" % cfg.ab, "nudge": "看右上角的小圖：最低點在哪裡？"},
				_f("柯西", "a、b 消掉", "(%s)(%s) ≥ ([0] + [1])^{2}" % [frac, lin], cfg.w,
					"(√{\\frac{%d}{a}}, √{\\frac{%d}{b}}) · (√{%sa}, √{%sb}) = %s + %s" % [uv[0], uv[1], "" if co[0] == 1 else str(co[0]), "" if co[1] == 1 else str(co[1]), cfg.w[0], cfg.w[1]],
					"\\frac{%d}{a} × %sa 開根號。" % [uv[0], "" if co[0] == 1 else str(co[0])], T_CAP, "set"),
				_f("最小值", "除以 %d" % co[2], "最小值 [0]", [cfg.mn], cfg.l3, "\\frac{(%s + %s)^{2}}{%d}。" % [cfg.w[0], cfg.w[1], co[2]], T_CAP),
				_f("等號", "等號成立的 a、b", "a = [0]，b = [1]", cfg.ab, "等號：%s" % cfg.l4, "兩支向量平行。", T_CAP),
			]})
	return {"id": "kinv", "chapter": 1, "type": "forge", "title": "倒過來的弓",
		"story": "倒數加起來，也能用柯西拉緊。",
		"insight": "(\\frac{u}{a} + \\frac{v}{b})(pa + qb) ≥ (√{up} + √{vq})^{2}\na、b 消掉，右邊變成常數。",
		"variants": vars}


## 7 不等式的審判（B33）
static func _ineq() -> Dictionary:
	var vars := []
	var sets := [
		{"eq": "\\vec{a} = (m, 2)、\\vec{b} = (3, n)\nm、n 是任意實數，哪些一定成立？", "a": Vector2(1, 2), "b": Vector2(3, 1), "tri": 2,
		 "cards": [
			["(m^{2} + 4)(9 + n^{2}) ≥ (3m + 2n)^{2}", true, "柯西：|\\vec{a} · \\vec{b}| ≤ |\\vec{a}||\\vec{b}|。",
				"(x*x + 4) * (9 + y*y)", "pow(3*x + 2*y, 2)", T_CAU],
			["(m^{2} + 4)(9 + n^{2}) ≥ (3m − 2n)^{2}", true, "\\vec{b} 換成 (3, −n)：長度一樣，內積是 3m − 2n。",
				"(x*x + 4) * (9 + y*y)", "pow(3*x - 2*y, 2)", T_CAU],
			["√{m^{2} + 4} + √{9 + n^{2}} ≥ √{(m + 3)^{2} + (2 + n)^{2}}", true, "三角不等式：|\\vec{a}| + |\\vec{b}| ≥ |\\vec{a} + \\vec{b}|。",
				"sqrt(x*x + 4) + sqrt(9 + y*y)", "sqrt(pow(x + 3, 2) + pow(2 + y, 2))", T_TRI],
			["(m^{2} + 4) + (9 + n^{2}) ≥ (m + 3)^{2} + (2 + n)^{2}", false, "少了根號：m = n = 1 時 15 < 25。",
				"(x*x + 4) + (9 + y*y)", "pow(x + 3, 2) + pow(2 + y, 2)", T_TRI]]},
		{"eq": "\\vec{a} = (1, m)、\\vec{b} = (n, 2)\nm、n 是任意實數，哪些一定成立？", "a": Vector2(1, 1), "b": Vector2(2, 2), "tri": 3,
		 "cards": [
			["(1 + m^{2})(n^{2} + 4) ≥ (n + 2m)^{2}", true, "柯西：|\\vec{a} · \\vec{b}| ≤ |\\vec{a}||\\vec{b}|。",
				"(1 + x*x) * (y*y + 4)", "pow(y + 2*x, 2)", T_CAU],
			["1 + m^{2} ≥ n^{2} + 4", false, "m = n = 0 時 1 < 4：兩支長度沒有大小關係。", "1 + x*x", "y*y + 4", T_CAU],
			["√{1 + m^{2}}√{n^{2} + 4} ≥ |2m − n|", true, "\\vec{b} 換成 (−n, 2)：長度一樣，內積是 2m − n。",
				"sqrt(1 + x*x) * sqrt(y*y + 4)", "abs(2*x - y)", T_CAU],
			["√{1 + m^{2}} + √{n^{2} + 4} ≥ √{(1 + n)^{2} + (m + 2)^{2}}", true, "三角不等式：|\\vec{a}| + |\\vec{b}| ≥ |\\vec{a} + \\vec{b}|。",
				"sqrt(1 + x*x) + sqrt(y*y + 4)", "sqrt(pow(1 + y, 2) + pow(x + 2, 2))", T_TRI]]}]
	for cfg in sets:
		var a: Vector2 = cfg.a
		var b: Vector2 = cfg.b
		var tri := int(cfg.tri)
		var shapes := [_ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"at": tri, "ls": -1}), _ar(a, a + b, "pink", "\\vec{b}", {"at": tri}),
			_ar(Vector2.ZERO, a + b, "gold", "\\vec{a} + \\vec{b}", {"at": tri, "w": 3.5, "lt": 0.7})]
		var st := []
		for k in cfg.cards.size():
			var cd: Array = cfg.cards[k]
			var j := _j("審判%s" % ["一", "二", "三", "四"][k], cd[0], cd[1], cd[2], "%s：%s" % [cd[0], "○" if cd[1] else "✕"], cd[5])
			j["sandbox"] = {"label": "(m, n)", "start": [1, 1], "lit": "%s >= %s - 0.0001" % [cd[3], cd[4]],
				"read": "L = {%s}   R = {%s}" % [cd[3], cd[4]], "read_at": "tl"}
			st.append(j)
		vars.append({"eq": cfg.eq, "plane": _plane([-6.0, 6.0], [-3.0, 3.0], shapes), "steps": st})
	return {"id": "kineq", "chapter": 1, "type": "forge", "title": "不等式的審判",
		"story": "拖拖看 (m, n)：燈一直亮著，才是一定成立。",
		"insight": "柯西：|\\vec{a} · \\vec{b}| ≤ |\\vec{a}||\\vec{b}|\n三角不等式：|\\vec{a}| + |\\vec{b}| ≥ |\\vec{a} + \\vec{b}|（要開根號）。",
		"variants": vars}


## 8 三角形裡的距離（B34）
static func _dist2() -> Dictionary:
	var vars := []
	# 第 1 組：直角在 A
	var A := Vector2(0, 0)
	var B := Vector2(3, 0)
	var C := Vector2(0, 4)
	var Fo := Vector2(1.92, 1.44)
	var s1 := [_poly([A, B, C], "cyan")]
	s1 += B1._dots({"A": A, "B": B, "C": C}, "text", {"A": [-16, 16], "B": [8, 16], "C": [-16, -4]})
	s1 += [_tag(Vector2(1.5, 0), "3", "dim", {"off": [-4, 18]}), _tag(Vector2(0, 2), "4", "dim", {"off": [-18, 4]}), _tag(Vector2(1.5, 2), "5", "dim", {"off": [8, -4]}),
		_seg(A, Fo, "gold", {"at": 3, "w": 3.0}), _right(Fo, C - B, A - Fo, {"at": 3}), _tag(Fo * 0.5, "\\frac{12}{5}", "gold", {"at": 3, "off": [-30, -4]})]
	vars.append({"eq": "\\ol{AB} = 3、\\ol{AC} = 4、\\ol{BC} = 5，P 在 \\ol{BC} 上\n到 AB、AC 的距離 x、y，求 x^{2} + y^{2} 最小值",
		"plane": _plane([-4.0, 6.0], [-0.6, 4.6], s1),
		"steps": [
			{"kind": "vplace", "name": "拖 P", "q": "拖 P，找最小", "tag": T_CAP, "goal": "lit", "ans": _p(Fo), "big": true,
			 "sandbox": {"label": "P", "on": {"o": [3, 0], "d": [-3, 4], "step": 0.04}, "feet": [[0, 1, 0], [1, 0, 0]], "start": [1.5, 2],
				"lit": "abs(x - 1.92) < 0.001 and abs(y - 1.44) < 0.001", "read": "x^{2} + y^{2} = {x * x + y * y}"},
			 "nudge": "看讀數：兩根竿子的平方和最小在哪裡？", "line": "P(\\frac{48}{25}, \\frac{36}{25}) 的時候最小"},
			_f("面積", "兩塊三角形加起來", "[0]x + [1]y = [2]", ["3", "4", "12"], "\\frac{1}{2} × 3x + \\frac{1}{2} × 4y = 6 ⇒ 3x + 4y = 12",
				"△PAB + △PAC = △ABC = 6。", T_CAP),
			_f("最小值", "柯西", "最小值 [0]", ["144/25"], "(x^{2} + y^{2})(9 + 16) ≥ 144 ⇒ x^{2} + y^{2} ≥ \\frac{144}{25}", "\\frac{144}{25}。", T_CAP),
		]})
	# 第 2 組：等腰
	A = Vector2(0, 4)
	B = Vector2(-3, 0)
	C = Vector2(3, 0)
	var s2 := [_poly([A, B, C], "cyan")]
	s2 += B1._dots({"A": A, "B": B, "C": C}, "text", {"A": [-6, -10], "B": [-16, 16], "C": [8, 16]})
	s2 += [_tag(Vector2(-1.5, 2), "5", "dim", {"off": [-18, -4]}), _tag(Vector2(1.5, 2), "5", "dim", {"off": [10, -4]}), _tag(Vector2(0, 0), "6", "dim", {"off": [-4, 18]}),
		_dot(Vector2.ZERO, "P", "gold", {"at": 3, "off": [-4, 18]})]
	var dab := "(4 * x - 3 * y + 12) / 5"
	var dac := "(4 * x + 3 * y - 12) / 5"
	vars.append({"eq": "\\ol{AB} = \\ol{AC} = 5、\\ol{BC} = 6，P 在 \\ol{BC} 上\n到 AB、AC 的距離 x、y，求 x^{2} + y^{2} 最小值",
		"plane": _plane([-5.0, 5.0], [-0.8, 4.6], s2),
		"steps": [
			{"kind": "vplace", "name": "拖 P", "q": "拖 P，找最小", "tag": T_CAP, "goal": "lit", "ans": [0, 0], "big": true,
			 "sandbox": {"label": "P", "on": {"o": [-3, 0], "d": [6, 0], "step": 0.05}, "feet": [[4, -3, 12], [4, 3, -12]], "start": [-2.1, 0],
				"lit": "abs(x) < 0.001", "read": "x^{2} + y^{2} = {pow(%s, 2) + pow(%s, 2)}" % [dab, dac]},
			 "nudge": "看讀數：兩根竿子的平方和最小在哪裡？", "line": "P 在 \\ol{BC} 中點的時候最小"},
			_f("面積", "兩塊三角形加起來", "[0]x + [1]y = [2]", ["5", "5", "24"], "\\frac{1}{2} × 5x + \\frac{1}{2} × 5y = 12 ⇒ 5x + 5y = 24",
				"△ABC 的高是 4，面積 12。", T_CAP),
			_f("最小值", "柯西", "最小值 [0]", ["288/25"], "(x^{2} + y^{2})(25 + 25) ≥ 576 ⇒ x^{2} + y^{2} ≥ \\frac{288}{25}", "\\frac{576}{50}。", T_CAP),
		]})
	return {"id": "kdist2", "chapter": 1, "type": "forge", "title": "三角形裡的距離",
		"story": "P 在底邊上走，兩根竿子的平方和什麼時候最小？",
		"insight": "題目沒給 x、y 的關係：用面積湊出一次式\n△PAB + △PAC = △ABC，再用柯西。",
		"variants": vars}


## 9 半圓湖（B35）
static func _lake() -> Dictionary:
	var vars := []
	for cfg in [{"d": 10, "v": [5, 12], "w": ["2", "5/6"], "wv": [2.0, 5.0 / 6.0], "mx": "13/6", "ml": "√{2^{2} + (\\frac{5}{6})^{2}} = \\frac{13}{6}", "x": [-8.6, 8.6], "y": [-1.0, 7.4]},
			{"d": 6, "v": [3, 4], "w": ["2", "3/2"], "wv": [2.0, 1.5], "mx": "5/2", "ml": "√{2^{2} + (\\frac{3}{2})^{2}} = \\frac{5}{2}", "x": [-5.2, 5.2], "y": [-0.6, 4.45]}]:
		var d := int(cfg.d)
		var r := d / 2.0
		var A := Vector2(-r, 0)
		var B := Vector2(r, 0)
		var th := deg_to_rad(35.0)
		var C := A + Vector2(cos(th), sin(th)) * d * cos(th)
		var cx := "%s + %s * pow(cos(t * 0.0174533), 2)" % [_e(-r), _e(d)]
		var cy := "%s * cos(t * 0.0174533) * sin(t * 0.0174533)" % _e(d)
		var fx := "%s * cos(u * 0.0174533) + %s * sin(u * 0.0174533)" % [_e(cfg.wv[0]), _e(cfg.wv[1])]
		var lines := [{"k": "dot", "p": [cx, cy], "c": "gold", "s": "C"}, {"k": "seg", "a": [A.x, 0], "b": [cx, cy], "c": "lime"},
			{"k": "seg", "a": [cx, cy], "b": [B.x, 0], "c": "cyan"}, {"k": "plot", "f": fx, "u0": 0, "u1": 90, "cur": "t", "corner": "tr"}]
		var shapes := [_half(Vector2.ZERO, r, "cyan", {"w": 2.0}), _seg(A, B, "faint", {"dash": true})]
		shapes += B1._dots({"A": A, "B": B}, "text", {"A": [-16, 16], "B": [8, 16]})
		shapes += [_seg(A, C, "lime", {"until": 3}), _seg(C, B, "cyan", {"until": 3}), _dot(C, "C", "text", {"until": 3, "off": [-6, -10]}),
			_right(C, A - C, B - C, {"at": 1, "until": 3}), _tag(A, "θ", "gold", {"off": [22, -6], "until": 3})]
		vars.append({"eq": "半圓湖直徑 \\ol{AB} = %d\nA 走到 C（時速 %d）\nC 划船到 B（時速 %d），最多幾小時？" % [d, cfg.v[0], cfg.v[1]],
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				_f("兩段路", "θ = ∠CAB", "\\ol{AC} = [0]cos θ，\\ol{CB} = [1]sin θ", [str(d), str(d)], "∠ACB = 90°：\\ol{AC} = %dcos θ、\\ol{CB} = %dsin θ" % [d, d],
					"半圓上的圓周角是直角。", T_CAP),
				_f("時間", "距離除以速度", "時間 = [0]cos θ + [1]sin θ", cfg.w,
					"\\frac{%dcos θ}{%d} + \\frac{%dsin θ}{%d} = %scos θ + %ssin θ" % [d, cfg.v[0], d, cfg.v[1], cfg.w[0], B6._fv(cfg.wv[1])], "走路的時間 + 划船的時間。", T_CAP),
				{"kind": "slide", "name": "拖 θ", "q": "拖 θ，看時間", "tag": T_CAP, "free": true,
				 "params": [{"n": "t", "min": 0, "max": 90, "step": 1, "v": 60}], "lines": lines,
				 "eq": "θ = {t}°：時間 = {%s}" % fx.replace("u", "t"), "line": "時間會變，中間有一個最長的地方", "nudge": "拉動滑桿，看右上角的小圖。"},
				_f("最長", "柯西", "最長 [0] 小時", [cfg.mx], "(%scos θ + %ssin θ)^{2} ≤ (%s^{2} + %s^{2})(cos^{2} θ + sin^{2} θ)：%s" % [cfg.w[0], B6._fv(cfg.wv[1]), cfg.w[0], B6._fv(cfg.wv[1]), cfg.ml],
					"(cos θ, sin θ) 是單位向量。", T_CAP),
			]})
	return {"id": "klake", "chapter": 1, "type": "forge", "title": "半圓湖",
		"story": "先走路再划船，繞湖最多要多久？",
		"insight": "acos θ + bsin θ ≤ √{a^{2} + b^{2}}\n(a, b) · (cos θ, sin θ)，單位向量的柯西。",
		"variants": vars}


# ======================= 第二章．面積公式 =======================

## 11 張開的帆（新）
static func _sail() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(4, 1), "b": Vector2(1, 3), "sq": ["17", "10", "7"], "ar": "11/2", "det": "11",
				"l3": "\\frac{1}{2}√{17 × 10 − 7^{2}} = \\frac{1}{2}√{121} = \\frac{11}{2}", "l4": "4 × 3 − 1 × 1 = 11：一樣是 \\frac{11}{2}", "x": [-5.0, 7.0], "y": [-1.0, 5.0]},
			{"a": Vector2(3, -1), "b": Vector2(2, 2), "sq": ["10", "8", "4"], "ar": "4", "det": "8",
				"l3": "\\frac{1}{2}√{10 × 8 − 4^{2}} = \\frac{1}{2}√{64} = 4", "l4": "3 × 2 − (−1) × 2 = 8：一樣是 4", "x": [-5.0, 7.0], "y": [-2.0, 4.0]}]:
		var a: Vector2 = cfg.a
		var b: Vector2 = cfg.b
		var rb := b.length()
		var a0 := rad_to_deg(a.angle())
		var perp := Vector2(-a.y, a.x).normalized() * rb
		var dx := "(%s * y - %s * x)" % [_e(a.x), _e(a.y)]
		var big := a.length() * rb
		var shapes := [_circ(Vector2.ZERO, rb, "faint", {"until": 1}), _ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"w": 3.5}),
			_ar(Vector2.ZERO, perp, "faint", "", {"at": 1, "until": 2, "dash": true}),
			_ar(Vector2.ZERO, b, "pink", "\\vec{b}", {"at": 1}), _fillp([Vector2.ZERO, a, b], "lime", 3)]
		vars.append({"eq": "\\vec{a} = %s、\\vec{b} = %s\n張成的三角形帆，面積是多少？" % [_pt(a), _pt(b)], "plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "張帆", "q": "轉 \\vec{b}，讓帆最大", "tag": T_AREA, "goal": "lit", "ans": _p(perp), "big": true,
				 "sandbox": {"label": "", "ring": {"o": [0, 0], "r": rb, "step": 15, "a0": a0}, "sail": [[0, 0], _p(a)],
					"arrow": {"o": [0, 0], "c": "pink", "s": "", "ls": -1}, "start": _p(b),
					"lit": "abs(abs(%s) - %s) < 0.001" % [dx, _e(big)], "read": "△ = {abs(%s) / 2}" % dx},
				 "nudge": "\\frac{1}{2}|\\vec{a}||\\vec{b}| sin θ：sin θ 最大是 1。", "line": "垂直的時候帆最大：sin θ = 1"},
				_f("三個數", "長度平方和內積", "|\\vec{a}|^{2} = [0]，|\\vec{b}|^{2} = [1]，\\vec{a} · \\vec{b} = [2]", cfg.sq,
					"|\\vec{a}|^{2} = %s、|\\vec{b}|^{2} = %s、\\vec{a} · \\vec{b} = %s" % cfg.sq, "坐標平方相加、對應相乘相加。", T_AREA),
				_f("面積", "向量的面積公式", "面積 = [0]", [cfg.ar], cfg.l3, "\\frac{1}{2}√{|\\vec{a}|^{2}|\\vec{b}|^{2} − (\\vec{a} · \\vec{b})^{2}}。", T_AREA),
				_f("坐標", "交叉相乘", "a_{1}b_{2} − a_{2}b_{1} = [0]", [cfg.det], cfg.l4, "%s × %s − %s × %s。" % [B6._num(a.x), _par(b.y), _par(a.y), _par(b.x)], T_AREA),
			]})
	return {"id": "ksail", "chapter": 2, "type": "forge", "title": "張開的帆",
		"story": "兩支箭頭張開，張成一面三角形的帆。",
		"insight": "△ = \\frac{1}{2}|\\vec{a}||\\vec{b}| sin θ = \\frac{1}{2}√{|\\vec{a}|^{2}|\\vec{b}|^{2} − (\\vec{a} · \\vec{b})^{2}}\n用坐標：\\frac{1}{2}|a_{1}b_{2} − a_{2}b_{1}|，不用開根號。",
		"variants": vars}


## 12 只知道長度的帆（B36）
static func _lenonly() -> Dictionary:
	var vars := []
	for cfg in [{"ab": 3, "ac": 5, "AC": Vector2(3, 4), "cond": "|\\vec{AC} − 3\\vec{AB}| = |\\vec{AC} + \\vec{AB}|", "x": 9, "ar": 6,
				"l1": "25 − 6x + 81 = 25 + 2x + 9 ⇒ x = \\vec{AB} · \\vec{AC} = 9", "l2": "\\frac{1}{2}√{9 × 25 − 9^{2}} = \\frac{1}{2}√{144} = 6",
				"px": [-6.5, 6.5], "py": [-0.8, 5.6]},
			{"ab": 13, "ac": 5, "AC": Vector2(25.0 / 13.0, 60.0 / 13.0), "cond": "|\\vec{AB} − 3\\vec{AC}| = |\\vec{AB} + \\vec{AC}|", "x": 25, "ar": 30,
				"l1": "169 − 6x + 225 = 169 + 2x + 25 ⇒ x = \\vec{AB} · \\vec{AC} = 25", "l2": "\\frac{1}{2}√{169 × 25 − 25^{2}} = \\frac{1}{2} × 60 = 30",
				"px": [-6.0, 14.5], "py": [-0.8, 9.4]}]:
		var AB := Vector2(cfg.ab, 0)
		var AC: Vector2 = cfg.AC
		var O := Vector2.ZERO
		var shapes := [_ar(O, AB, "cyan", "\\vec{AB}", {"ls": -1}), _half(O, float(cfg.ac), "faint", {"until": 1, "dash": true}),
			_ar(O, AC, "pink", "\\vec{AC}", {"at": 1}), _fillp([O, AB, AC], "lime", 2), _dot(O, "A", "text", {"off": [-16, 16]})]
		vars.append({"eq": "|\\vec{AB}| = %d、|\\vec{AC}| = %d\n%s\n求 \\vec{AB} · \\vec{AC} 和 △ABC 的面積" % [cfg.ab, cfg.ac, cfg.cond],
			"plane": _plane(cfg.px, cfg.py, shapes),
			"steps": [
				_f("內積", "兩邊平方展開", "\\vec{AB} · \\vec{AC} = [0]", [str(cfg.x)], cfg.l1, "|\\vec{u}|^{2} = \\vec{u} · \\vec{u}，兩邊都展開。", T_AREA),
				_f("面積", "向量的面積公式", "△ABC = [0]", [str(cfg.ar)], cfg.l2, "\\frac{1}{2}√{|\\vec{AB}|^{2}|\\vec{AC}|^{2} − (\\vec{AB} · \\vec{AC})^{2}}。", T_AREA),
			]})
	return {"id": "klen", "chapter": 2, "type": "forge", "title": "只知道長度的帆",
		"story": "只知道兩根帆桿多長，帆張多大？",
		"insight": "長度的條件：兩邊平方，用 |\\vec{u}|^{2} = \\vec{u} · \\vec{u} 展開，找出內積\n有了長度和內積，就能算面積。",
		"variants": vars}


## 13 坐標的帆（新）
static func _csail() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(1, 1), "B": Vector2(5, 2), "C": Vector2(2, 4), "ar": "11/2", "k": 11.0, "tr": [Vector2(2, 4), Vector2(6, 5), Vector2(-2, 3)], "start": [3, 4],
				"x": [-8.0, 9.0], "y": [-2.0, 6.5]},
			{"A": Vector2(-2, 1), "B": Vector2(3, -1), "C": Vector2(1, 3), "ar": "8", "k": 16.0, "tr": [Vector2(1, 3), Vector2(6, 1), Vector2(-4, 5)], "start": [0, 0],
				"x": [-8.0, 9.0], "y": [-3.0, 6.5]}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var C: Vector2 = cfg.C
		var ab := B - A
		var ac := C - A
		var dx := "(%s * (y - %s) - %s * (x - %s))" % [_e(ab.x), _e(A.y), _e(ab.y), _e(A.x)]
		var k: float = cfg.k
		var tr := []
		for q in cfg.tr:
			tr.append(_p(q))
		# 和 AB 平行、面積剛好的兩條直線：ab.x(y − A.y) − ab.y(x − A.x) = ±k
		var shapes := [_seg(A, B, "cyan", {"w": 2.5})]
		for sg in [1.0, -1.0]:
			shapes.append(_L(-ab.y, ab.x, ab.y * A.x - ab.x * A.y - sg * k, "gold", "", {"at": 1, "dash": true}))
		shapes += B1._dots({"A": A, "B": B}, "text", {"A": [-16, 16], "B": [8, 16]})
		shapes += [_dot(C, "C", "text", {"at": 1, "off": [-6, -10]}), _ar(A, B, "cyan", "", {"at": 2}), _ar(A, C, "pink", "", {"at": 2}),
			_fillp([A, B, C], "lime", 3)]
		vars.append({"eq": "A%s、B%s、C%s\n求 △ABC 的面積" % [_pt(A), _pt(B), _pt(C)], "plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "一樣大的帆", "q": "拖 C，找 3 個一樣大的帆", "tag": T_AREA, "goal": "trace", "need": 3, "ans": _p(C), "trace_ans": tr, "big": true,
				 "sandbox": {"label": "C", "sail": [_p(A), _p(B)], "trace": true, "start": cfg.start,
					"lit": "abs(abs(%s) - %s) < 0.01" % [dx, _e(k)], "read": "△ = {abs(%s) / 2}" % dx},
				 "nudge": "讀數要是 %s：底 \\ol{AB} 一樣，高也要一樣。" % B6._fv(k / 2.0), "line": "光點排成和 \\ol{AB} 平行的直線：底一樣、高一樣"},
				_f("兩支箭頭", "從 A 出發", "\\vec{AB} = ([0], [1])，\\vec{AC} = ([2], [3])", [B6._ans(ab.x), B6._ans(ab.y), B6._ans(ac.x), B6._ans(ac.y)],
					"\\vec{AB} = %s、\\vec{AC} = %s" % [_pt(ab), _pt(ac)], "終點減起點。", T_AREA),
				_f("面積", "交叉相乘", "△ABC = [0]", [cfg.ar], "\\frac{1}{2}|%s × %s − %s × %s| = %s" % [B6._num(ab.x), _par(ac.y), _par(ab.y), _par(ac.x), B6._fv(k / 2.0)],
					"\\frac{1}{2}|a_{1}b_{2} − a_{2}b_{1}|。", T_AREA),
			]})
	return {"id": "kcsail", "chapter": 2, "type": "forge", "title": "坐標的帆",
		"story": "知道三個頂點，帆有多大？",
		"insight": "△ABC = \\frac{1}{2}|a_{1}b_{2} − a_{2}b_{1}|（\\vec{AB} = (a_{1}, a_{2})、\\vec{AC} = (b_{1}, b_{2})）\n一樣大的帆：C 在和 \\ol{AB} 平行的直線上。",
		"variants": vars}


## 14 帆布的審判（B37、B38）
static func _sjudge() -> Dictionary:
	var vars := []
	# 第 1 組：|a| = 3、|b| = 4、a · b = 6
	var O := Vector2.ZERO
	var a := Vector2(3, 0)
	var b := Vector2(2, 2.0 * sqrt(3.0))
	var a4 := a * (4.0 / 3.0)
	var s1 := [_ar(O, a, "cyan", "\\vec{a}", {"ls": -1}), _ar(O, b, "pink", "\\vec{b}"),
		_poly([O, a4, a4 + b, b], "faint", {"at": 1, "until": 2, "dash": true}), _ar(O, a4 + b, "gold", "", {"at": 1, "until": 2, "w": 3.0}),
		_fillp([O, a, b], "lime", 2), _ar(O, -(a + b), "violet", "\\vec{c}", {"at": 3, "until": 4}),
		_ar(O, Vector2(0, 2.0 * sqrt(3.0)), "gold", "", {"at": 4, "w": 3.0}), _seg(a * (-2.0 / 3.0), b, "gold", {"at": 4, "dash": true}),
		_tag(Vector2(0, sqrt(3.0)), "2√3", "gold", {"at": 4, "off": [-34, 4]})]
	vars.append({"eq": "|\\vec{a}| = 3、|\\vec{b}| = 4、\\vec{a} · \\vec{b} = 6\n下面哪些正確？", "plane": _plane([-7.0, 7.0], [-4.0, 4.4], s1),
		"steps": [
			_j("審判一", "4\\vec{a} + 3\\vec{b} 平分 \\vec{a}、\\vec{b} 的夾角", true, "|4\\vec{a}| = |3\\vec{b}| = 12：菱形的對角線平分夾角。", "4\\vec{a} + 3\\vec{b} 平分夾角 ○", T_AREA),
			_j("審判二", "\\vec{a}、\\vec{b} 張成的三角形面積是 3√3", true, "\\frac{1}{2}√{9 × 16 − 6^{2}} = \\frac{1}{2}√{108} = 3√3。", "面積 3√3 ○", T_AREA),
			_j("審判三", "\\vec{a} + \\vec{b} + \\vec{c} = \\vec{0} ⇒ |\\vec{c}| = √37", true, "|\\vec{c}|^{2} = |\\vec{a} + \\vec{b}|^{2} = 9 + 12 + 16 = 37。", "|\\vec{c}| = √37 ○", T_AREA),
			_j("審判四", "|t\\vec{a} + \\vec{b}| 的最小值是 12", false, "最小值的平方是 16 − \\frac{36}{9} = 12，最小值是 2√3。", "最小值是 2√3，不是 12 ✕", T_AREA),
		]})
	# 第 2 組：A(1, 0)、B(7, 2)、C(3, 6)
	var A := Vector2(1, 0)
	var B := Vector2(7, 2)
	var C := Vector2(3, 6)
	var G := (A + B + C) / 3.0
	var p1 := A + Vector2(1.2, 3.6)
	var p2 := A + Vector2(3.6, 1.2)
	var s2 := [_poly([A, B, C], "cyan")]
	s2 += B1._dots({"A": A, "B": B, "C": C}, "text", {"A": [-16, 16], "B": [8, 16], "C": [-6, -10]})
	s2 += [_dot(G, "G", "gold", {"at": 1, "until": 2, "off": [10, -6]}), _fillp([A, B, C], "lime", 2),
		_ar(A, p1, "violet", "", {"at": 3, "w": 3.5}), _seg(B, p1, "violet", {"at": 3, "dash": true}),
		_ar(A, p2, "lime", "", {"at": 4, "w": 3.5}), _seg(C, p2, "lime", {"at": 4, "dash": true})]
	vars.append({"eq": "A(1, 0)、B(7, 2)、C(3, 6)\n下面哪些正確？", "plane": _axes([-6.0, 12.0], [-0.8, 7.0], s2),
		"steps": [
			_j("審判一", "重心是 (\\frac{11}{3}, \\frac{8}{3})", true, "\\frac{1 + 7 + 3}{3}、\\frac{0 + 2 + 6}{3}。", "重心 (\\frac{11}{3}, \\frac{8}{3}) ○", T_AREA),
			_j("審判二", "△ABC 的面積是 16", true, "\\vec{AB} = (6, 2)、\\vec{AC} = (2, 6)：\\frac{1}{2}|36 − 4| = 16。", "面積 16 ○", T_AREA),
			_j("審判三", "\\vec{AB} 在 \\vec{AC} 上的正射影是 (\\frac{6}{5}, \\frac{18}{5})", true, "\\frac{24}{40}(2, 6) = (\\frac{6}{5}, \\frac{18}{5})。", "正射影 (\\frac{6}{5}, \\frac{18}{5}) ○", T_AREA),
			_j("審判四", "\\vec{AB} 在 \\vec{AC} 上的正射影等於 \\vec{AC} 在 \\vec{AB} 上的正射影", false,
				"\\vec{AC} 在 \\vec{AB} 上是 (\\frac{18}{5}, \\frac{6}{5})：一樣長，方向不同。", "兩個正射影一樣長、方向不同 ✕", T_AREA),
		]})
	return {"id": "ksjudge", "chapter": 2, "type": "forge", "title": "帆布的審判",
		"story": "帆布的尺寸都對嗎？一張一張檢查。",
		"insight": "有長度和內積就能算面積、夾角、合成的長度\n|t\\vec{a} + \\vec{b}| 的最小值：先算平方的最小值，再開根號。",
		"variants": vars}


## 15 兩面方帆（B39）
static func _squares() -> Dictionary:
	var vars := []
	for cfg in [{"oa": 2, "ob": 3, "ar": "21/2", "l3": "\\vec{BC} = (2, −5)、\\vec{BF} = (−3, −3)：\\frac{1}{2}|−6 − 15| = \\frac{21}{2}", "x": [-5.0, 5.0], "y": [-3.0, 4.0]},
			{"oa": 1, "ob": 4, "ar": "12", "l3": "\\vec{BC} = (1, −5)、\\vec{BF} = (−4, −4)：\\frac{1}{2}|−4 − 20| = 12", "x": [-6.5, 4.5], "y": [-2.0, 5.0]}]:
		var oa := float(cfg.oa)
		var ob := float(cfg.ob)
		var O := Vector2.ZERO
		var A := Vector2(oa, 0)
		var B := Vector2(0, ob)
		var C := Vector2(oa, -oa)
		var D := Vector2(0, -oa)
		var E := Vector2(-ob, ob)
		var F := Vector2(-ob, 0)
		var shapes := [_poly([O, A, C, D], "faint", {"dash": true}), _poly([O, B, E, F], "faint", {"dash": true}),
			_seg(O, A, "cyan", {"w": 3.0}), _seg(O, B, "cyan", {"w": 3.0}), _right(O, A, B)]
		shapes += B1._dots({"O": O, "A": A, "B": B}, "text", {"O": [8, -8], "A": [8, -8], "B": [8, -6]})
		shapes += [_ar(A, C, "gold", "", {"at": 1}), _dot(C, "C", "gold", {"at": 1, "off": [10, 14]}),
			_ar(O, F, "gold", "", {"at": 2}), _dot(F, "F", "gold", {"at": 2, "off": [-16, 16]}), _fillp([B, C, F], "lime", 3)]
		vars.append({"eq": "\\ol{OA} = %d、\\ol{OB} = %d、∠AOB = 90°\n往外作正方形 OACD、OBEF\n求 △BCF 的面積" % [cfg.oa, cfg.ob], "plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("C", "\\vec{OA} 轉 90°", "C = ([0], [1])", [B6._ans(C.x), B6._ans(C.y)], "\\vec{AC} 是 \\vec{OA} 轉 90°：C = A + %s = %s" % [_pt(C - A), _pt(C)], "從 A 往下走 \\ol{OA} 那麼長。", T_AREA),
				_f("F", "\\vec{OB} 轉 90°", "F = ([0], [1])", [B6._ans(F.x), B6._ans(F.y)], "\\vec{OF} 是 \\vec{OB} 轉 90°：F%s" % _pt(F), "從 O 往左走 \\ol{OB} 那麼長。", T_AREA),
				_f("面積", "交叉相乘", "△BCF = [0]", [cfg.ar], cfg.l3, "\\vec{BC}、\\vec{BF} 交叉相乘。", T_AREA),
			]})
	return {"id": "ksquare", "chapter": 2, "type": "forge", "title": "兩面方帆",
		"story": "兩面方帆靠在一起，中間夾出一塊三角形。",
		"insight": "正方形的頂點：邊轉 90°（(a, b) → (b, −a) 或 (−b, a)）\n有了坐標，交叉相乘算面積。",
		"variants": vars}


## 16 斜格子上的帆布（B40、B41）
static func _skewcloth() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(1, 1), "B": Vector2(3, 2), "C": Vector2(2, 4), "cond": "0 ≤ x + y ≤ 1、0 ≤ y ≤ 2", "xy": "2", "det": "5", "ar": "10",
				"l1": "每一個 y，x 從 −y 到 1 − y（寬 1），y 從 0 到 2：面積 2", "l2": "|2 × 3 − 1 × 1| = 5",
				"corners": [Vector2(0, 0), Vector2(1, 0), Vector2(-1, 2), Vector2(-2, 2)], "i": [-3, 2], "j": [-1, 3], "x": [-6.0, 8.0], "y": [-0.6, 6.6]},
			{"A": Vector2(1, 0), "B": Vector2(2, 1), "C": Vector2(0, 1), "cond": "−1 ≤ x ≤ 2、1 ≤ y ≤ 3", "xy": "6", "det": "2", "ar": "12",
				"l1": "x 寬 3、y 寬 2：面積 6", "l2": "|1 × 1 − 1 × (−1)| = 2",
				"corners": [Vector2(-1, 1), Vector2(2, 1), Vector2(2, 3), Vector2(-1, 3)], "i": [-2, 3], "j": [0, 4], "x": [-7.0, 7.0], "y": [-0.6, 5.8]}]:
		var A: Vector2 = cfg.A
		var ab: Vector2 = cfg.B - A
		var ac: Vector2 = cfg.C - A
		var reg := []
		for q in cfg.corners:
			reg.append(A + ab * q.x + ac * q.y)
		var shapes := [{"k": "skew", "o": _p(A), "a": _p(ab), "b": _p(ac), "i": cfg.i, "j": cfg.j, "div": 1, "c": "cyan", "at": 2},
			_ar(A, cfg.B, "cyan", "\\vec{AB}", {"ls": -1}), _ar(A, cfg.C, "pink", "\\vec{AC}"),
			_fillp([A, A + ab, A + ab + ac, A + ac], "gold", 2), _fillp(reg, "lime", 3)]
		shapes += B1._dots({"A": A}, "text", {"A": [-16, 16]})
		vars.append({"eq": "A%s、B%s、C%s\n\\vec{AP} = x\\vec{AB} + y\\vec{AC}，%s\n求 P 圍成的面積" % [_pt(A), _pt(cfg.B), _pt(cfg.C), cfg.cond],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("(x, y) 的面積", "先在 (x, y) 方格上", "面積 [0]", [cfg.xy], cfg.l1, "把 x、y 當成坐標，畫出範圍。", T_AREA),
				_f("一格多大", "\\vec{AB}、\\vec{AC} 張成的格子", "一格 [0]", [cfg.det], "一格斜格子：%s" % cfg.l2, "交叉相乘。", T_AREA),
				_f("P 的範圍", "每一格放大", "面積 [0]", [cfg.ar], "%s × %s = %s" % [cfg.xy, cfg.det, cfg.ar], "(x, y) 的面積 × 一格的面積。", T_AREA),
			]})
	return {"id": "kskew", "chapter": 2, "type": "forge", "title": "斜格子上的帆布",
		"story": "斜斜的格子上，帆布佔了多少格？",
		"insight": "\\vec{AP} = x\\vec{AB} + y\\vec{AC}：(x, y) 方格上的面積 × |det(\\vec{AB}, \\vec{AC})|\n一格斜格子就是 \\vec{AB}、\\vec{AC} 張成的平行四邊形。",
		"variants": vars}


## 17 帆張多開（新）
static func _open() -> Dictionary:
	var vars := []
	for cfg in [{"lb": 3.0, "step": 30, "ar": 3.0, "ars": "3", "sin": "1/2", "deg": ["30", "150"], "dot": "6√3",
				"l2": "\\frac{1}{2} × 4 × 3 × sin θ = 3 ⇒ sin θ = \\frac{1}{2}", "l4": "4 × 3 × cos θ = 12 × (±\\frac{√3}{2}) = ±6√3", "x": [-6.5, 6.5], "y": [-3.4, 3.4]},
			{"lb": 2.0, "step": 45, "ar": 2.0 * sqrt(2.0), "ars": "2√2", "sin": "√2/2", "deg": ["45", "135"], "dot": "4√2",
				"l2": "\\frac{1}{2} × 4 × 2 × sin θ = 2√2 ⇒ sin θ = \\frac{√2}{2}", "l4": "4 × 2 × cos θ = 8 × (±\\frac{√2}{2}) = ±4√2", "x": [-5.5, 5.5], "y": [-2.6, 2.8]}]:
		var lb: float = cfg.lb
		var a := Vector2(4, 0)
		var th := deg_to_rad(float(cfg.deg[0]))
		var tr := []
		for d in [th, PI - th, PI + th, TAU - th]:
			tr.append([snappedf(lb * cos(d), 1e-6), snappedf(lb * sin(d), 1e-6)])
		var b1 := Vector2(tr[0][0], tr[0][1])
		var b2 := Vector2(tr[1][0], tr[1][1])
		var shapes := [_circ(Vector2.ZERO, lb), _ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"w": 3.5, "ls": -1}),
			_fillp([Vector2.ZERO, a, b1], "lime", 3), _ar(Vector2.ZERO, b1, "pink", "", {"at": 3}),
			_fillp([Vector2.ZERO, a, b2], "gold", 3), _ar(Vector2.ZERO, b2, "pink", "", {"at": 3})]
		vars.append({"eq": "|\\vec{a}| = 4、|\\vec{b}| = %s\n\\vec{a}、\\vec{b} 張成的三角形面積是 %s\n求夾角 θ 和 \\vec{a} · \\vec{b}" % [B6._fv(lb), cfg.ars],
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "張帆", "q": "轉 \\vec{b}，找 2 個位置", "tag": T_AREA, "goal": "trace", "need": 2, "ans": tr[0], "trace_ans": tr, "big": true,
				 "sandbox": {"label": "", "ring": {"o": [0, 0], "r": lb, "step": cfg.step, "a0": 0}, "sail": [[0, 0], [4, 0]], "trace": true,
					"arrow": {"o": [0, 0], "c": "pink", "s": "\\vec{b}", "ls": -1}, "start": [0, lb],
					"lit": "abs(2 * abs(y) - %s) < 0.001" % _e(cfg.ar), "read": "△ = {2 * abs(y)}"},
				 "nudge": "帆的面積要剛好是 %s：上下各有兩個。" % cfg.ars, "line": "面積一樣的帆有好幾面：一個尖、一個鈍"},
				_f("sin θ", "面積公式", "sin θ = [0]", [cfg.sin], cfg.l2, "△ = \\frac{1}{2}|\\vec{a}||\\vec{b}| sin θ。", T_AREA),
				_f("θ", "兩個角", "θ = [0]° 或 [1]°", cfg.deg, "sin θ = %s：θ = %s° 或 %s°" % [B6._rad_frac(String(cfg.sin)), cfg.deg[0], cfg.deg[1]],
					"0° 到 180° 之間，sin 一樣的有兩個角。", T_AREA, "set"),
				_f("內積", "cos θ 有正有負", "\\vec{a} · \\vec{b} = ±[0]", [cfg.dot], cfg.l4, "|\\vec{a}||\\vec{b}| cos θ。", T_AREA),
			]})
	return {"id": "kopen", "chapter": 2, "type": "forge", "title": "帆張多開",
		"story": "知道帆有多大，反過來找帆張多開。",
		"insight": "面積 ⇒ sin θ ⇒ θ 有兩個（互補）\n內積 = |\\vec{a}||\\vec{b}| cos θ，一正一負。",
		"variants": vars}
