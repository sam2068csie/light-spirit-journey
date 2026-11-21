extends RefCounted
## 平面向量 第三大關「日晷影場」題庫（上冊 3-2 重點一、六：內積、垂直與平行、正射影）
## 設計稿：docs/vec2_v3_design.md。數字都用程式驗算過（tools/vec2/verify_v3.py）。
##
## 引擎見 vec_level.gd（箭頭畫布、在圖上作答），圖層見 vec_board.gd。這一關多用了：
##   圖層 shadow（影子：陽光、正射影、內積的長方形）、expand（展開田）、right（直角記號）、
##   vplace 沙盒的 ring（轉箭頭）、on（沿直線拖）、pole（影子＋竿子）、trace（光點描圖）、read（讀數），
##   新步驟 vorder（排隊點：照內積大小點頂點）。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/vec2/vec1_bank.gd")
const B2 := preload("res://data/levels/vec2/vec2_bank.gd")

const T_DOT := "vec_dot"           # 內積的意義、正負、性質
const T_BAS := "vec_dotbasis"      # 化成基底展開、圖形中的內積
const T_PERP := "vec_perp"         # 垂直、平行的條件
const T_PROJ := "vec_proj"         # 正射影


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


static func _seg(a: Vector2, b: Vector2, c := "dim", extra := {}) -> Dictionary:
	return B1._seg(a, b, c, extra)


static func _poly(pts: Array, c := "dim", extra := {}) -> Dictionary:
	return B1._poly(pts, c, extra)


static func _plane(x: Array, y: Array, shapes: Array, named := {}, extra := {}) -> Dictionary:
	return B1._plane(x, y, shapes, named, extra)


static func _axes(x: Array, y: Array, shapes: Array, named := {}) -> Dictionary:
	return _plane(x, y, shapes, named, {"grid": "axes"})


static func _dots(pts: Dictionary, c := "text", offs := {}) -> Array:
	return B1._dots(pts, c, offs)


static func _beam(a: Vector2, b: Vector2, at: int, c := "gold", extra := {}) -> Dictionary:
	return B2._beam(a, b, at, c, extra)


static func _lamp(p: Vector2, at: int, s := "P") -> Array:
	return [{"k": "circle", "o": _p(p), "r": 0.22, "c": "gold", "fill": "gold", "alpha": 0.5, "at": at},
		_dot(p, s, "gold", {"at": at, "off": [10, -8]})]


## 影子：o → a 的箭頭在過 o、方向 g 的地面上
static func _shadow(o: Vector2, a: Vector2, g: Vector2, extra := {}) -> Dictionary:
	var d := {"k": "shadow", "o": _p(o), "a": _p(a), "g": _p(g)}
	d.merge(extra, true)
	return d


static func _right(p: Vector2, u: Vector2, v: Vector2, extra := {}) -> Dictionary:
	var d := {"k": "right", "p": _p(p), "u": _p(u), "v": _p(v), "c": "gold"}
	d.merge(extra, true)
	return d


## 展開田
static func _expand(p: Vector2, rows: Array, cols: Array, cells: Array, sg: Array, at: int, extra := {}) -> Dictionary:
	var d := {"k": "expand", "p": _p(p), "rows": rows, "cols": cols, "cells": cells, "sg": sg, "at": at}
	d.merge(extra, true)
	return d


## 整條直線（過兩點）
static func _line(p: Vector2, q: Vector2, c := "faint", extra := {}) -> Dictionary:
	var d := {"k": "line", "p": _p(p), "q": _p(q), "c": c}
	d.merge(extra, true)
	return d


static func _fv(v: float) -> String:
	return B2._fv(v)


static func _ans(v: float) -> String:
	return B2._ans(v)


static func _pt(v: Vector2) -> String:
	return B2._pt(v)


static func _n(v: float) -> String:
	return B1._n(v)


## 算式裡的數字（Expression 看不懂「−」）
static func _e(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else str(v)


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
		_turn(), _judge(), _on_line(), _queue(), _tail(), _basis(), _foot(), _circle(),
		{"id": "speed1", "chapter": 1, "type": "speed", "title": "影子速算", "time": 120.0,
		 "story": "看影子落在哪一邊，內積的正負就知道！",
		 "insight": "夾角是銳角：影子同方向，內積 > 0\n直角：影子縮成一點，內積 = 0。鈍角：影子在反方向，內積 < 0。",
		 "variants": [{"gen": "sign", "count": 8}]},
		_coord(), _perp_t(), _par_t(), _two_cond(), _pole(), _formula(), _proj_cards(), _same_ray(), _pole_tap(),
		{"id": "speed2", "chapter": 2, "type": "speed", "title": "垂直平行速算", "time": 120.0,
		 "story": "日晷的指針一格一格轉，垂直還是平行？",
		 "insight": "垂直：a_{1}b_{1} + a_{2}b_{2} = 0\n平行：a_{1}b_{2} − a_{2}b_{1} = 0（分量成比例）。",
		 "variants": [{"gen": "perp", "count": 8}]},
	]


# ======================= 第一章．日晷影場 =======================

## 1 轉動的影子（新）：\vec{a} 躺在地上，轉 \vec{b}
static func _turn() -> Dictionary:
	var vars := []
	for cfg in [{"a": 4.0, "b": 2.0, "want": "max", "x": [-5.2, 5.6], "y": [-2.7, 2.7]},
			{"a": 3.0, "b": 4.0, "want": "min", "x": [-9.0, 9.0], "y": [-4.7, 4.7]}]:
		var la: float = cfg.a
		var lb: float = cfg.b
		var mx: bool = cfg.want == "max"
		var a := Vector2(la, 0)
		var dotx := "%s * x" % _e(la)
		var sbx := func(lit: String) -> Dictionary:
			return {"label": "", "ring": {"o": [0, 0], "r": lb, "step": 15}, "arrow": {"o": [0, 0], "c": "pink", "s": "\\vec{b}"},
				"shadow": {"o": [0, 0], "g": _p(a), "area": 1.0}, "lit": lit,
				"read": "\\vec{a} · \\vec{b} = {%s}" % dotx, "start": [lb * 0.5, lb * 0.8660254]}
		var best := lb if mx else -lb
		var shapes := [_line(Vector2.ZERO, a, "faint"), _ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"ls": -1, "w": 3.5}),
			{"k": "circle", "o": [0, 0], "r": lb, "c": "faint", "dash": true},
			{"k": "sector", "o": [0, 0], "r": lb, "a0": 90, "a1": 270, "c": "violet", "fill": "violet", "alpha": 0.22, "at": 3}]
		var val := la * lb * (1.0 if mx else -1.0)
		vars.append({"eq": "\\vec{a} 躺在地上，轉動等長的 \\vec{b}\n\\vec{a} · \\vec{b} 什麼時候%s？什麼時候是 0？" % ("最大" if mx else "最小"),
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "最大" if mx else "最小", "q": "轉 \\vec{b}，讓內積%s" % ("最大" if mx else "最小"),
				 "sandbox": sbx.call("abs(%s - (%s)) < 0.01" % [dotx, _e(val)]), "goal": "lit", "ans": [best, 0], "tag": T_DOT,
				 "nudge": "看地上的影子：和 \\vec{a} 同方向越長，內積越大。" if mx else "看地上的影子：往反方向越長，內積越小。",
				 "line": "夾角 %s：\\vec{b} 和 \\vec{a} %s，內積%s" % (["0°", "同方向", "最大"] if mx else ["180°", "反方向", "最小"])},
				{"kind": "vplace", "name": "內積是 0", "q": "轉 \\vec{b}，讓內積是 0", "sandbox": sbx.call("abs(%s) < 0.01" % dotx),
				 "goal": "lit", "ans": [0, lb], "tag": T_DOT, "nudge": "影子要縮成一點：陽光照下來剛好落在起點。",
				 "line": "夾角 90°：影子縮成一點，內積是 0"},
				_c("鈍角", "夾角是鈍角時，內積是？", ["負的", "正的", "0"], 0,
					"夾角超過 90°，影子跑到 \\vec{a} 的反方向：cos θ < 0，內積是負的。",
					"轉到左半邊，看影子是什麼顏色。", "夾角是鈍角 ⇒ 影子在反方向，內積 < 0", T_DOT),
				_f("最大值" if mx else "最小值", "內積的%s" % ("最大值" if mx else "最小值"),
					"\\vec{a} · \\vec{b} = [0]", [_ans(val)],
					"%s = %s|\\vec{a}||\\vec{b}| = %s" % ["最大值" if mx else "最小值", "" if mx else "−", _fv(val)],
					"|\\vec{a}||\\vec{b}|cos θ，cos θ 最%s是 %s。" % ["大" if mx else "小", "1" if mx else "−1"], T_DOT),
			]})
	return {"id": "turn", "chapter": 1, "type": "forge", "title": "轉動的影子",
		"story": "太陽從正上方照下來，轉動箭頭看影子。",
		"insight": "\\vec{a} · \\vec{b} = |\\vec{a}||\\vec{b}|cos θ = |\\vec{a}| × \\vec{b} 的影子長\n銳角是正的、直角是 0、鈍角是負的。",
		"variants": vars}


## 2 日晷的審判（A35、A36）
static func _judge() -> Dictionary:
	var O := Vector2.ZERO
	var vars := []
	# 第 1 組（A35）
	var s1 := [_line(O, Vector2(1, 0), "faint")]
	var st1 := []
	st1.append(_j("審判一", "\\vec{a} + \\vec{b} = \\vec{a} + \\vec{c} ⇒ \\vec{b} = \\vec{c}", true,
		"兩邊都減去 \\vec{a}，就得到 \\vec{b} = \\vec{c}。", "加法可以消去：\\vec{b} = \\vec{c}", T_DOT))
	st1.append(_j("審判二", "\\vec{a} · \\vec{b} = \\vec{a} · \\vec{c} ⇒ \\vec{b} = \\vec{c}", false,
		"內積只看影子：\\vec{c} 只要和 \\vec{b} 的影子一樣長就好，不一定等於 \\vec{b}。", "內積不能消去", T_DOT))
	var a1 := Vector2(4, 0)
	var b1 := Vector2(2, 3)
	st1.append({"kind": "vplace", "name": "反例", "q": "拖 \\vec{c}，找一個反例", "tag": T_DOT, "goal": "lit", "ans": [2, -1],
		"sandbox": {"label": "", "arrow": {"o": [0, 0], "c": "lime", "s": "\\vec{c}"}, "shadow": {"o": [0, 0], "g": _p(a1)},
			"lit": "abs(4 * x - 8) < 0.01 and (abs(x - 2) > 0.01 or abs(y - 3) > 0.01)", "start": [1, -2],
			"read": "\\vec{a} · \\vec{c} = {4 * x}"},
		"nudge": "\\vec{a} · \\vec{b} = 8：讓 \\vec{c} 的影子也落在 x = 2。", "line": "反例：\\vec{c} 和 \\vec{b} 在同一道陽光上，內積一樣，\\vec{c} ≠ \\vec{b}"})
	s1 += [_ar(O, a1, "cyan", "\\vec{a}", {"ls": -1, "at": 1, "until": 3}), _ar(O, b1, "pink", "\\vec{b}", {"at": 1, "until": 3}),
		_shadow(O, b1, a1, {"at": 1, "until": 3})]
	st1.append(_j("審判三", "(\\vec{b} · \\vec{c})\\vec{a} − (\\vec{c} · \\vec{a})\\vec{b} ⊥ \\vec{c}", true,
		"和 \\vec{c} 內積：(\\vec{b} · \\vec{c})(\\vec{a} · \\vec{c}) − (\\vec{c} · \\vec{a})(\\vec{b} · \\vec{c}) = 0。", "和 \\vec{c} 的內積是 0 ⇒ 垂直", T_DOT))
	st1.append(_j("審判四", "\\vec{a}、\\vec{b} 在 \\vec{c} 上的正射影相等 ⇒ (\\vec{a} − \\vec{b}) ∥ \\vec{c}", false,
		"影子一樣 ⇒ \\vec{a}、\\vec{b} 的頭在同一道陽光上：\\vec{a} − \\vec{b} 和 \\vec{c} 垂直，不是平行。", "正射影相等 ⇒ (\\vec{a} − \\vec{b}) ⊥ \\vec{c}", T_PROJ))
	var c1 := Vector2(4, 0)
	var a1b := Vector2(2, 3)
	st1.append({"kind": "vplace", "name": "反例", "q": "拖 \\vec{b}，影子和 \\vec{a} 一樣", "tag": T_PROJ, "goal": "lit", "ans": [2, -1],
		"sandbox": {"label": "", "arrow": {"o": [0, 0], "c": "lime", "s": "\\vec{b}"}, "shadow": {"o": [0, 0], "g": _p(c1)},
			"lit": "abs(x - 2) < 0.01 and abs(y - 3) > 0.01", "start": [-1, -2]},
		"nudge": "\\vec{a} 的影子落在 x = 2：讓 \\vec{b} 的頭也在那一道陽光上。",
		"line": "\\vec{a}、\\vec{b} 的頭在同一道陽光上：\\vec{a} − \\vec{b} 和 \\vec{c} 垂直"})
	s1 += [_ar(O, c1, "cyan", "\\vec{c}", {"ls": -1, "at": 4}), _ar(O, a1b, "pink", "\\vec{a}", {"at": 4}),
		_shadow(O, a1b, c1, {"at": 4}), _line(a1b, a1b + Vector2(0, 1), "gold", {"dash": true, "at": 6})]
	for st in st1:
		st["big"] = true
	vars.append({"eq": "\\vec{a}、\\vec{b}、\\vec{c} 是三個非零的相異向量\n下面哪些一定成立？", "plane": _plane([-5.5, 7.5], [-2.6, 3.8], s1), "steps": st1})
	# 第 2 組（A36，最後一張換成垂直）
	var s2 := [_line(O, Vector2(1, 0), "faint")]
	var st2 := []
	st2.append(_j("審判一", "||\\vec{a}| − |\\vec{b}|| ≤ |\\vec{a} − \\vec{b}|", true,
		"\\vec{a}、\\vec{b}、\\vec{a} − \\vec{b} 圍成三角形：兩邊的差小於第三邊（共線時相等）。", "三角形兩邊差 ≤ 第三邊", T_DOT))
	st2.append(_j("審判二", "|\\vec{a} · \\vec{b}| = |\\vec{a}||\\vec{b}| ⇒ \\vec{a} ∥ \\vec{b}", true,
		"|cos θ| = 1，θ 是 0° 或 180°：兩支平行。", "|cos θ| = 1 ⇒ 平行", T_DOT))
	st2.append(_j("審判三", "|\\vec{a} + \\vec{b}| = |\\vec{a} − \\vec{b}| ⇔ \\vec{a} ⊥ \\vec{b}", true,
		"兩邊平方：\\vec{a} · \\vec{b} = −\\vec{a} · \\vec{b}，所以內積是 0。平行四邊形的兩條對角線一樣長，是長方形。", "對角線一樣長 ⇔ 長方形 ⇔ 垂直", T_PERP))
	var A3 := Vector2(3, 0)
	var B3 := Vector2(0, 2)
	s2 += [_ar(O, A3, "cyan", "\\vec{a}", {"ls": -1, "at": 3}), _ar(O, B3, "pink", "\\vec{b}", {"at": 3}),
		_poly([O, A3, A3 + B3, B3], "faint", {"at": 3, "until": 4}),
		_seg(O, A3 + B3, "gold", {"at": 3, "until": 4}), _seg(A3, B3, "gold", {"at": 3, "until": 4}), _right(O, A3, B3, {"at": 3})]
	st2.append(_j("審判四", "\\vec{a} ⊥ \\vec{b}、\\vec{b} ⊥ \\vec{c} ⇒ \\vec{a} ⊥ \\vec{c}", false,
		"平面上和 \\vec{b} 垂直的方向只有一個：\\vec{c} 和 \\vec{a} 平行，不會垂直。", "\\vec{a} ⊥ \\vec{b}、\\vec{b} ⊥ \\vec{c} ⇒ \\vec{a} ∥ \\vec{c}", T_PERP))
	st2.append({"kind": "vplace", "name": "反例", "q": "拖 \\vec{c}，讓 \\vec{c} ⊥ \\vec{b}", "tag": T_PERP, "goal": "lit", "ans": [-2, 0],
		"sandbox": {"label": "", "arrow": {"o": [0, 0], "c": "lime", "s": "\\vec{c}"},
			"lit": "abs(y) < 0.01 and abs(x) > 0.01", "start": [-2, 2], "read": "\\vec{b} · \\vec{c} = {2 * y}"},
		"nudge": "\\vec{b} 是直的：\\vec{c} 要躺平。", "line": "反例：\\vec{c} ⊥ \\vec{b} 時 \\vec{c} 躺在 \\vec{a} 的直線上，\\vec{a} ∥ \\vec{c}"})
	for st in st2:
		st["big"] = true
	vars.append({"eq": "\\vec{a}、\\vec{b}、\\vec{c} 是平面上的非零向量\n下面哪些一定成立？", "plane": _plane([-5.5, 6.5], [-2.4, 3.2], s2), "steps": st2})
	return {"id": "judge", "chapter": 1, "type": "forge", "title": "日晷的審判",
		"story": "日晷前的審判：錯的那張，要拖出反例。",
		"insight": "內積不能消去：\\vec{a} · \\vec{b} = \\vec{a} · \\vec{c} 只能推出 \\vec{a} ⊥ (\\vec{b} − \\vec{c})\n|\\vec{a} + \\vec{b}| = |\\vec{a} − \\vec{b}| ⇔ \\vec{a} ⊥ \\vec{b}。",
		"variants": vars}


## 3 落在線上的影（A37）：O 在直線 AB 外，照條件插下 P
static func _on_line() -> Dictionary:
	var O := Vector2(0, -3)
	var A := Vector2(-2, 1)
	var B := Vector2(1, 1)
	var vars := []
	for cards in [
			[["3\\vec{OP} = 4\\vec{OA} − 2\\vec{OB}", Vector2(-10.0 / 3.0, -1.0 / 3.0), false, "\\vec{OP} = \\frac{4}{3}\\vec{OA} − \\frac{2}{3}\\vec{OB}，係數和是 \\frac{2}{3}，不是 1。"],
			 ["(\\vec{OA} · \\vec{AP})\\vec{AB} = (\\vec{OA} · \\vec{AB})\\vec{AP}", Vector2(2.8, 1), true, "括號裡的內積只是兩個數：\\vec{AB} 和 \\vec{AP} 平行，共用 A。"],
			 ["\\vec{AB} = 2\\vec{PA} + 3\\vec{PB}", Vector2(-0.8, 1), true, "\\vec{PB} = \\vec{PA} + \\vec{AB} 代進去：−2\\vec{AB} = 5\\vec{PA}，平行而且共用 A。"],
			 ["3\\vec{PB} = \\vec{OA} − \\vec{OB}", Vector2(2, 1), true, "\\vec{OA} − \\vec{OB} = \\vec{BA}：\\vec{PB} ∥ \\vec{BA}，共用 B。"]],
			[["2\\vec{OP} = 3\\vec{OA} − \\vec{OB}", Vector2(-3.5, 1), true, "\\vec{OP} = \\frac{3}{2}\\vec{OA} − \\frac{1}{2}\\vec{OB}，係數和是 1。"],
			 ["\\vec{OP} = \\vec{OA} + \\vec{OB}", Vector2(-1, 5), false, "係數和是 2，不是 1：P 是平行四邊形的第四個頂點。"],
			 ["\\vec{AB} = 3\\vec{PA} − \\vec{PB}", Vector2(-5, 1), true, "\\vec{PB} = \\vec{PA} + \\vec{AB} 代進去：2\\vec{AB} = 2\\vec{PA}，平行而且共用 A。"],
			 ["(\\vec{OB} · \\vec{BP})\\vec{BA} = (\\vec{OB} · \\vec{BA})\\vec{BP}", Vector2(-0.5, 1), true, "括號裡的內積只是兩個數：\\vec{BA} 和 \\vec{BP} 平行，共用 B。"]]]:
		var shapes := [_dot(O, "O", "dim", {"off": [-14, 14]}), _beam(A, B, 1, "gold"), _beam(B, A, 1, "gold")]
		shapes += _dots({"A": A, "B": B}, "text", {"A": [-6, -12], "B": [4, -12]})
		var steps := []
		var k := 0
		for cd in cards:
			k += 1
			var ok: bool = cd[2]
			shapes.append(_dot(cd[1], "P", "lime" if ok else "pink", {"at": k, "until": k + 1, "off": [8, 16]}))
			var st := _j(["審判一", "審判二", "審判三", "審判四"][k - 1], String(cd[0]), ok, String(cd[3]),
				("%s ⇒ 共線" if ok else "%s 不保證共線") % cd[0], T_DOT)
			st["big"] = true
			steps.append(st)
		vars.append({"eq": "A、B、P 是三個相異點，O 在直線 AB 外\n下面哪些條件保證 A、B、P 共線？", "plane": _plane([-6, 4.5], [-4, 5.8], shapes), "steps": steps})
	return {"id": "online", "chapter": 1, "type": "forge", "title": "落在線上的影",
		"story": "照條件把 P 插下去，看它在不在光上。",
		"insight": "\\vec{OP} = α\\vec{OA} + β\\vec{OB}：共線 ⇔ α + β = 1\n(\\vec{OA} · \\vec{AP})\\vec{AB} 裡的內積只是一個數：等式說的是兩支向量平行。",
		"variants": vars}


## 4 影子排隊（A38、A39）
static func _queue() -> Dictionary:
	var vars := []
	# 變化 A：六邊形，\vec{AB} 躺在地上
	for cfg in [{"pts": [Vector2(0, 0), Vector2(2, 0), Vector2(4, 2), Vector2(3, 5), Vector2(0, 4), Vector2(-2, 2)],
				"order": "CDBEF", "res": "b > c > a > d > e", "x": [-5.5, 8.5], "y": [-1.0, 5.8]},
			{"pts": [Vector2(0, 0), Vector2(3, 0), Vector2(5, 3), Vector2(2, 5), Vector2(-1, 4), Vector2(-2, 1)],
				"order": "CBDEF", "res": "b > a > c > d > e", "x": [-5.0, 9.0], "y": [-1.0, 5.8]}]:
		var pts: Array = cfg.pts
		var names := "ABCDEF"
		var dict := {}
		var offs := {"A": [-14, -8], "B": [8, -8], "C": [8, -2], "D": [6, -8], "E": [-14, -8], "F": [-16, -4]}
		for i in 6:
			dict[names[i]] = pts[i]
		var shapes := [_line(pts[0], pts[1], "faint"), _poly(pts, "dim")]
		for i in range(2, 6):
			shapes.append(_seg(pts[0], pts[i], "faint", {"dash": true}))
		shapes.append(_ar(pts[0], pts[1], "gold", "", {"w": 3.5}))
		shapes += _dots(dict, "text", offs)
		var order := []
		for ch in String(cfg.order):
			var q: Vector2 = dict[ch]
			order.append([q.x, q.y, ch])
		vars.append({"eq": "a = \\vec{AB} · \\vec{AB}，b = \\vec{AB} · \\vec{AC}，c = \\vec{AB} · \\vec{AD}\nd = \\vec{AB} · \\vec{AE}，e = \\vec{AB} · \\vec{AF}，比大小",
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				_c("比什麼", "比內積，其實是比？", ["影子長", "箭頭長", "夾角"], 0,
					"\\vec{AB} · \\vec{AX} = |\\vec{AB}| × \\vec{AX} 在 \\vec{AB} 上的影子長，|\\vec{AB}| 都一樣。",
					"內積 = |\\vec{AB}| × 影子長。", "都乘上 |\\vec{AB}|：只要比在 \\vec{AB} 方向上的影子長", T_DOT),
				{"kind": "vorder", "name": "排隊", "q": "照內積從大到小，點頂點", "tag": T_DOT,
				 "ground": [_p(pts[0]), _p(pts[1])], "order": order,
				 "nudge": "陽光從正上方照下來：影子落得越右邊（越往 \\vec{AB} 的方向），內積越大。",
				 "line": "%s（影子由右到左）" % cfg.res},
			]})
	# 變化 B：正五邊形（A39）
	var R := 3.0
	var P5 := {}
	var nm := "ABCDE"
	for k in 5:
		var ang := deg_to_rad(90.0 + 72.0 * k)
		P5[nm[k]] = Vector2(cos(ang), sin(ang)) * R
	var Pa: Vector2 = P5.A
	var Pb: Vector2 = P5.B
	var Pc: Vector2 = P5.C
	var Pd: Vector2 = P5.D
	var Pe: Vector2 = P5.E
	var I := Pb + Pe - Pa
	var shapes := [_poly([Pa, Pb, Pc, Pd, Pe], "dim")]
	for dg in [[Pa, Pc], [Pa, Pd], [Pb, Pd], [Pb, Pe], [Pc, Pe]]:
		shapes.append(_seg(dg[0], dg[1], "faint"))
	shapes += _dots(P5, "text", {"A": [-4, -12], "B": [-18, -4], "C": [-16, 14], "D": [8, 14], "E": [8, -4]})
	shapes.append(_dot(I, "I", "dim", {"off": [8, 14]}))
	var cd := Pd - Pc
	# 卡一：ABIE 是菱形
	shapes += [_ar(Pa, Pb, "cyan", "", {"at": 1, "until": 2}), _ar(Pa, Pe, "pink", "", {"at": 1, "until": 2}), _ar(Pa, I, "gold", "", {"at": 1, "until": 2})]
	# 卡二：\vec{EA}（從 C 出發）和 \vec{CB}（從 D 出發）在 CD 方向上的影子
	shapes += [_line(Pc, Pd, "faint", {"at": 2, "until": 4}),
		_ar(Pc, Pc + Pa - Pe, "cyan", "\\vec{EA}", {"at": 2, "until": 3}), _shadow(Pc, Pc + Pa - Pe, cd, {"at": 2, "until": 3}),
		_ar(Pd, Pd + Pb - Pc, "pink", "\\vec{CB}", {"at": 2, "until": 3, "ls": -1}), _shadow(Pd, Pd + Pb - Pc, cd, {"at": 2, "until": 3})]
	# 卡三：\vec{BA}（從 C 出發）和 \vec{DE}（從 D 出發）
	shapes += [_ar(Pc, Pc + Pa - Pb, "cyan", "\\vec{BA}", {"at": 3, "until": 4}), _shadow(Pc, Pc + Pa - Pb, cd, {"at": 3, "until": 4}),
		_ar(Pd, Pe, "pink", "\\vec{DE}", {"at": 3, "until": 4, "ls": -1}), _shadow(Pd, Pe, cd, {"at": 3, "until": 4})]
	# 卡四：\vec{AD} 在 \vec{AB} 上的影子落在中點
	shapes += [_line(Pa, Pb, "faint", {"at": 4}), _ar(Pa, Pd, "cyan", "", {"at": 4}), _shadow(Pa, Pd, Pb - Pa, {"at": 4}),
		_dot((Pa + Pb) / 2.0, "", "gold", {"at": 4})]
	var steps := [
		_j("審判一", "\\vec{AB} + \\vec{AE} = \\vec{AI}", true, "正五邊形的邊和對角線平行：\\ol{AB} ∥ \\ol{EI}、\\ol{AE} ∥ \\ol{BI}，ABIE 是菱形。", "ABIE 是菱形：\\vec{AB} + \\vec{AE} = \\vec{AI}", T_DOT),
		_j("審判二", "\\vec{CD} · \\vec{EA} < \\vec{CD} · \\vec{CB}", true, "兩個影子都在 \\vec{CD} 的反方向（負的），\\vec{EA} 的影子比較長，所以比較小。", "\\vec{CD} · \\vec{EA} < \\vec{CD} · \\vec{CB} < 0", T_DOT),
		_j("審判三", "\\vec{CD} · \\vec{BA} < \\vec{CD} · \\vec{DE}", false, "兩個影子都和 \\vec{CD} 同方向，\\vec{BA} 的影子比較長：\\vec{CD} · \\vec{BA} 比較大。", "\\vec{CD} · \\vec{BA} > \\vec{CD} · \\vec{DE}", T_DOT),
		_j("審判四", "\\vec{AB} · \\vec{AD} < \\vec{AB} · \\vec{AB}", true, "D 在 \\ol{AB} 的中垂線上：\\vec{AD} 的影子只有 \\vec{AB} 的一半。", "\\vec{AB} · \\vec{AD} = \\frac{1}{2}|\\vec{AB}|^{2} < \\vec{AB} · \\vec{AB}", T_DOT)]
	for st in steps:
		st["big"] = true
	steps[0]["ribbon"] = [_p(Pa), _p(Pb), _p(I), _p(Pe)]
	vars.append({"eq": "正五邊形 ABCDE，I 是 \\ol{BD}、\\ol{CE} 的交點\n下面哪些正確？", "plane": _plane([-5.2, 5.2], [-3.6, 3.8], shapes), "steps": steps})
	return {"id": "queue", "chapter": 1, "type": "forge", "title": "影子排隊",
		"story": "陽光從正上方照下來，影子越長，內積越大。",
		"insight": "\\vec{AB} · \\vec{AX} = |\\vec{AB}| × 影子長：同一支 \\vec{AB}，只要比影子\n影子在反方向是負的：越長越小。",
		"variants": vars}


## 5 頭尾相接的夾角（A40）
static func _tail() -> Dictionary:
	var vars := []
	for cfg in [{"ab": 4, "bc": 7, "ca": 3, "s": ["2", "√7", "√3"], "x": [-1.2, 5.2], "y": [-2.6, 2.4]},
			{"ab": 5, "bc": 9, "ca": 8, "s": ["√5", "3", "2√2"], "x": [-1.2, 5.6], "y": [-2.8, 3.2]}]:
		var ab := sqrt(float(cfg.ab))
		var cx := (float(cfg.ca) - float(cfg.bc) + float(cfg.ab)) / (2.0 * ab)
		var C := Vector2(cx, sqrt(float(cfg.ca) - cx * cx))
		var A := Vector2.ZERO
		var B := Vector2(ab, 0)
		var E := B + B
		var val := (float(cfg.ca) - float(cfg.ab) - float(cfg.bc)) / 2.0
		var degc := rad_to_deg((C - B).angle())
		var shapes := [_poly([A, B, C], "dim")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [4, 16], "C": [8, -6]})
		shapes += [_ar(B, C, "pink", "\\vec{BC}", {"w": 3.0}), _line(A, B, "faint", {"at": 1}),
			_ar(B, E, "cyan", "", {"at": 1, "dash": true}), {"k": "angle", "o": _p(B), "a0": 0, "a1": degc, "r": 22, "c": "gold", "at": 1},
			_shadow(B, C, B - A, {"at": 1, "area": ab})]
		var s: Array = cfg.s
		vars.append({"eq": "△ABC 中，\\ol{AB} = %s，\\ol{BC} = %s，\\ol{CA} = %s\n求 \\vec{AB} · \\vec{BC}" % s,
			"plane": _plane(cfg.x, cfg.y, shapes, {"A": A, "B": B, "C": C, "E": E}),
			"steps": [
				{"kind": "vdrag", "name": "尾接尾", "q": "把 \\vec{AB} 拖到 B 的後面", "fixed": ["A", "B"], "need": 1, "pairs": [["AB", "BE"]],
				 "tag": T_DOT, "nudge": "抓住 \\vec{AB} 的中間，讓它的尾巴停在 B。",
				 "line": "\\vec{AB}、\\vec{BC} 尾接尾：夾角是 180° − ∠B（鈍角），影子在反方向"},
				_f("平方", "|\\vec{AB} + \\vec{BC}|^{2} 展開", "[0] = [1] + 2\\vec{AB} · \\vec{BC} + [2]", [str(cfg.ca), str(cfg.ab), str(cfg.bc)],
					"|\\vec{AC}|^{2} = |\\vec{AB}|^{2} + 2\\vec{AB} · \\vec{BC} + |\\vec{BC}|^{2}：%d = %d + 2\\vec{AB} · \\vec{BC} + %d" % [cfg.ca, cfg.ab, cfg.bc],
					"\\vec{AC} = \\vec{AB} + \\vec{BC}，兩邊平方。", T_BAS),
				_f("內積", "\\vec{AB} · \\vec{BC} = ？", "\\vec{AB} · \\vec{BC} = [0]", [_ans(val)],
					"\\vec{AB} · \\vec{BC} = %s（紫色長方形的面積）" % _fv(val), "%d − %d − %d，再除以 2。" % [cfg.ca, cfg.ab, cfg.bc], T_BAS),
			]})
	return {"id": "tail", "chapter": 1, "type": "forge", "title": "頭尾相接的夾角",
		"story": "兩支箭頭頭尾相接，夾角是哪一個？",
		"insight": "\\vec{AB} · \\vec{BC} 的夾角是 180° − ∠B（要尾接尾）\n已知三邊：|\\vec{AC}|^{2} = |\\vec{AB} + \\vec{BC}|^{2} 展開。",
		"variants": vars}


## 6 化成兩支基底（A43、A44、A45、A46）
static func _basis() -> Dictionary:
	var vars := []
	# 變化 A（A43）：平行四邊形
	var A := Vector2.ZERO
	var B := Vector2(6, 0)
	var D := Vector2(2, 2.0 * sqrt(3.0))
	var C := B + D
	var P := D + B / 3.0
	var sa := [_poly([A, B, C, D], "dim")]
	sa += _dots({"A": A, "B": B, "C": C, "D": D}, "text", {"A": [-14, 14], "B": [6, 14], "C": [8, -6], "D": [-14, -6]})
	sa += [_dot(P, "P", "gold", {"off": [-4, -12]}), _ar(A, P, "cyan", "", {"at": 1}), _ar(B, P, "pink", "", {"at": 2}),
		_expand(Vector2(9.0, 4.4), ["\\vec{AD}", "\\frac{1}{3}\\vec{AB}"], ["\\vec{AD}", "−\\frac{2}{3}\\vec{AB}"],
			[["16", "−\\frac{2}{3}k"], ["\\frac{1}{3}k", "−8"]], [[1, -1], [1, -1]], 2)]
	vars.append({"eq": "平行四邊形 ABCD，\\ol{AB} = 6，\\ol{AD} = 4，3\\ol{PD} = \\ol{CD}\n\\vec{AP} · \\vec{BP} = 4，設 \\vec{AB} · \\vec{AD} = k，求 k",
		"plane": _plane([-1.2, 17.5], [-1.0, 5.0], sa),
		"steps": [
			_f("\\vec{AP}", "\\vec{AP} 換成基底", "\\vec{AP} = \\vec{AD} + [0]\\vec{AB}", ["1/3"], "\\vec{AP} = \\vec{AD} + \\frac{1}{3}\\vec{AB}", "\\vec{DP} 是 \\vec{DC} 的幾分之幾？", T_BAS),
			_f("\\vec{BP}", "\\vec{BP} 換成基底", "\\vec{BP} = \\vec{AD} − [0]\\vec{AB}", ["2/3"], "\\vec{BP} = \\vec{AP} − \\vec{AB} = \\vec{AD} − \\frac{2}{3}\\vec{AB}", "\\vec{BP} = \\vec{AP} − \\vec{AB}。", T_BAS),
			_f("展開田", "四格加起來", "16 − [0]k − [1] = 4", ["1/3", "8"], "\\vec{AP} · \\vec{BP} = 16 − \\frac{1}{3}k − 8 = 4", "中間兩格：−\\frac{2}{3}k + \\frac{1}{3}k。右下：\\frac{1}{3} × (−\\frac{2}{3}) × 36。", T_BAS),
			_f("k", "解 k", "k = [0]", ["12"], "\\vec{AB} · \\vec{AD} = 12", "8 − \\frac{1}{3}k = 4。", T_BAS),
		]})
	# 變化 B（A44）：正三角形邊長 3，M、N 三等分 \ol{BC}
	var Bb := Vector2.ZERO
	var Cb := Vector2(3, 0)
	var Ab := Vector2(1.5, 1.5 * sqrt(3.0))
	var M := Vector2(1, 0)
	var N := Vector2(2, 0)
	var sb := [_poly([Ab, Bb, Cb], "dim")]
	sb += _dots({"A": Ab, "B": Bb, "C": Cb}, "text", {"A": [-4, -12], "B": [-14, 14], "C": [6, 14]})
	sb += _dots({"M": M, "N": N}, "dim", {"M": [-4, 18], "N": [-4, 18]})
	sb += [_ar(Ab, M, "cyan", "", {"at": 1}), _ar(Ab, N, "pink", "", {"at": 2}),
		_expand(Vector2(4.4, 2.8), ["\\frac{2}{3}\\vec{AB}", "\\frac{1}{3}\\vec{AC}"], ["\\frac{1}{3}\\vec{AB}", "\\frac{2}{3}\\vec{AC}"],
			[["2", "2"], ["\\frac{1}{2}", "2"]], [[1, 1], [1, 1]], 3, {"hw": 70})]
	vars.append({"eq": "△ABC 是邊長 3 的正三角形\nM、N 把 \\ol{BC} 三等分，求 \\vec{AM} · \\vec{AN}",
		"plane": _plane([-1.0, 10.5], [-0.9, 3.4], sb),
		"steps": [
			_f("\\vec{AM}", "\\vec{AM} 換成基底", "\\vec{AM} = [0]\\vec{AB} + [1]\\vec{AC}", ["2/3", "1/3"], "\\vec{AM} = \\frac{2}{3}\\vec{AB} + \\frac{1}{3}\\vec{AC}", "M 靠近 B：係數交叉。", T_BAS),
			_f("\\vec{AN}", "\\vec{AN} 換成基底", "\\vec{AN} = [0]\\vec{AB} + [1]\\vec{AC}", ["1/3", "2/3"], "\\vec{AN} = \\frac{1}{3}\\vec{AB} + \\frac{2}{3}\\vec{AC}", "N 靠近 C。", T_BAS),
			_f("基底的內積", "\\vec{AB} · \\vec{AC}", "\\vec{AB} · \\vec{AC} = [0]", ["9/2"], "\\vec{AB} · \\vec{AC} = 3 × 3 × cos 60° = \\frac{9}{2}", "夾角 60°。", T_DOT),
			_f("展開田", "四格加起來", "\\vec{AM} · \\vec{AN} = [0]", ["13/2"], "\\vec{AM} · \\vec{AN} = 2 + 2 + \\frac{1}{2} + 2 = \\frac{13}{2}", "四格：2、2、\\frac{1}{2}、2。", T_BAS),
		]})
	# 變化 C（A45）：直角三角形向外作正方形，放上坐標
	var Ac := Vector2.ZERO
	var Bc := Vector2(2, 0)
	var Cc := Vector2(0, 4)
	var Ec := Vector2(6, 2)
	var Dc := Vector2(4, 6)
	var sc := [_poly([Ac, Bc, Cc], "dim")]
	sc += _dots({"A": Ac, "B": Bc, "C": Cc}, "text", {"A": [-14, 14], "B": [4, 16], "C": [-16, -4]})
	sc += [_poly([Bc, Cc, Dc, Ec], "gold", {"at": 1, "fill": "gold", "alpha": 0.12}), _dot(Dc, "D", "gold", {"at": 1, "off": [8, -6]}),
		_dot(Ec, "E", "gold", {"at": 1, "off": [8, 4]}), _ar(Ac, Dc, "cyan", "", {"at": 2}), _ar(Ac, Ec, "pink", "", {"at": 2})]
	vars.append({"eq": "△ABC 中 ∠A = 90°，\\ol{AB} = 2，\\ol{AC} = 4\n以 \\ol{BC} 向外作正方形 BCDE，A(0, 0)、B(2, 0)、C(0, 4)",
		"plane": _axes([-3.5, 8.0], [-3.0, 7.0], sc),
		"steps": [
			{"kind": "vpick", "name": "E", "q": "點出正方形的頂點 E", "target": _p(Ec), "snap": 1, "tag": T_BAS,
			 "traps": [[-2, -2, "這是往內作的：正方形蓋住 A 了，要往外。"], [2, 4, "這是 C + \\vec{BE} 的一半？\\vec{BE} 要和 \\vec{BC} 一樣長。"]],
			 "nudge": "\\vec{BC} = (−2, 4) 轉 90°：(4, 2) 或 (−4, −2)，哪一個是往外？", "line": "\\vec{BE} = (4, 2)：E(6, 2)、D(4, 6)"},
			_f("內積", "\\vec{AD} · \\vec{AE}", "\\vec{AD} · \\vec{AE} = [0]", ["36"], "\\vec{AD} · \\vec{AE} = (4, 6) · (6, 2) = 36", "D = C + \\vec{BE} = (4, 6)。", T_DOT),
			_f("分解", "\\vec{AE} 換成基底", "\\vec{AE} = [0]\\vec{AB} + [1]\\vec{AC}", ["3", "1/2"], "(6, 2) = 3(2, 0) + \\frac{1}{2}(0, 4)：(x, y) = (3, \\frac{1}{2})", "x 分量：6 = 2x，y 分量：2 = 4y。", T_BAS),
		]})
	# 變化 D（A46）：平行四邊形的對角線、等腰梯形
	var Pq := [Vector2(-9, -1), Vector2(-4, -1), Vector2(-2.97394, 1.81907), Vector2(-7.97394, 1.81907)]
	var Ad := Vector2.ZERO
	var Bd := Vector2(8, 0)
	var Cd := Vector2(6, 2.0 * sqrt(3.0))
	var Dd := Vector2(2, 2.0 * sqrt(3.0))
	var Md := (Bd + Cd) / 2.0
	var Nd := (Cd + Dd) / 2.0
	var sd := [_poly(Pq, "dim", {"until": 1}), _seg(Pq[0], Pq[2], "gold", {"until": 1}), _seg(Pq[1], Pq[3], "pink", {"until": 1})]
	sd += [_dot(Pq[0], "A", "text", {"until": 1, "off": [-14, 14]}), _dot(Pq[1], "B", "text", {"until": 1, "off": [6, 14]}),
		_dot(Pq[2], "C", "text", {"until": 1, "off": [8, -6]}), _dot(Pq[3], "D", "text", {"until": 1, "off": [-14, -6]}),
		_expand(Vector2(-9.2, 6.2), ["\\vec{AD}", "\\vec{AB}"], ["\\vec{AD}", "−\\vec{AB}"], [["9", "−k"], ["k", "−25"]], [[1, 0], [0, -1]], 0, {"until": 1})]
	sd += [_poly([Ad, Bd, Cd, Dd], "dim", {"at": 1})]
	sd += [_dot(Ad, "A", "text", {"at": 1, "off": [-14, 14]}), _dot(Bd, "B", "text", {"at": 1, "off": [6, 14]}),
		_dot(Cd, "C", "text", {"at": 1, "off": [8, -6]}), _dot(Dd, "D", "text", {"at": 1, "off": [-14, -6]}),
		_dot(Md, "M", "dim", {"at": 1, "off": [8, 4]}), _dot(Nd, "N", "dim", {"at": 1, "off": [-4, -12]}),
		_ar(Ad, Cd, "cyan", "", {"at": 2}), _ar(Md, Nd, "pink", "", {"at": 3}),
		_expand(Vector2(-9.21, 6.2), ["\\vec{AD}", "\\frac{1}{2}\\vec{AB}"], ["\\frac{1}{2}\\vec{AD}", "−\\frac{1}{2}\\vec{AB}"],
			[["8", "−8"], ["4", "−16"]], [[1, -1], [1, -1]], 3, {"hw": 70})]
	sd += [{"k": "label", "p": _p((Ad + Dd) / 2.0 + Vector2(-0.45, 0)), "s": "4", "c": "dim", "at": 1},
		{"k": "label", "p": _p((Dd + Cd) / 2.0 + Vector2(0, 0.4)), "s": "4", "c": "dim", "at": 1},
		{"k": "angle", "o": _p(Ad), "a0": 0, "a1": 60, "r": 22, "c": "gold", "s": "60°", "at": 1},
		{"k": "label", "p": _p(Pq[0].lerp(Pq[1], 0.5) + Vector2(0, -0.45)), "s": "5", "c": "dim", "until": 1},
		{"k": "label", "p": _p(Pq[0].lerp(Pq[3], 0.5) + Vector2(-0.4, 0)), "s": "3", "c": "dim", "until": 1}]
	vars.append({"eq": "① 平行四邊形 ABCD，求 \\vec{AC} · \\vec{BD}\n② 等腰梯形 ABCD，M、N 是 \\ol{BC}、\\ol{CD} 中點，求 \\vec{AC} · \\vec{MN}",
		"plane": _plane([-10.0, 9.5], [-1.8, 7.6], sd),
		"steps": [
			_f("①", "\\vec{AC} · \\vec{BD}", "(\\vec{AD} + \\vec{AB}) · (\\vec{AD} − \\vec{AB}) = [0]", ["-16"],
				"\\vec{AC} · \\vec{BD} = |\\vec{AD}|^{2} − |\\vec{AB}|^{2} = 9 − 25 = −16（不用知道夾角）", "中間兩格 k 和 −k 抵消。", T_BAS),
			_f("\\vec{AC}", "② \\vec{AC} 換成基底", "\\vec{AC} = \\vec{AD} + [0]\\vec{AB}", ["1/2"], "\\vec{DC} = \\frac{1}{2}\\vec{AB}：\\vec{AC} = \\vec{AD} + \\frac{1}{2}\\vec{AB}", "\\ol{DC} 是 \\ol{AB} 的幾分之幾？", T_BAS),
			_f("\\vec{MN}", "中點連線", "\\vec{MN} = [0](\\vec{AD} − \\vec{AB})", ["1/2"], "\\vec{MN} = \\frac{1}{2}\\vec{BD} = \\frac{1}{2}(\\vec{AD} − \\vec{AB})", "M、N 是中點：\\vec{MN} 是 \\vec{BD} 的一半。", T_BAS),
			_f("展開田", "四格加起來（\\vec{AB} · \\vec{AD} = 16）", "\\vec{AC} · \\vec{MN} = [0]", ["-12"], "\\vec{AC} · \\vec{MN} = 8 − 8 + 4 − 16 = −12", "\\vec{AB} · \\vec{AD} = 8 × 4 × cos 60° = 16。", T_BAS),
		]})
	return {"id": "basis", "chapter": 1, "type": "forge", "title": "化成兩支基底",
		"story": "每一支箭頭都換成兩支基底，再展開。",
		"insight": "圖形裡的內積：選兩支知道長度、夾角的向量當基底\n每一支都寫成基底的組合，再像乘法一樣展開（展開田）。",
		"variants": vars}


## 7 陽光下的垂足（A41）
static func _foot() -> Dictionary:
	var vars := []
	for cfg in [{"aa": 4.0, "cc": 9.0, "ac": 3.0, "ans": ["-1", "6"], "xy": ["6/7", "1/7"], "x": [-1.2, 3.6], "y": [-0.8, 3.0]},
			{"aa": 9.0, "cc": 4.0, "ac": -1.0, "ans": ["-10", "5"], "xy": ["1/3", "2/3"], "x": [-1.4, 3.8], "y": [-0.8, 2.6]}]:
		var la := sqrt(float(cfg.aa))
		var lc := sqrt(float(cfg.cc))
		var cs := float(cfg.ac) / (la * lc)
		var A := Vector2.ZERO
		var B := Vector2(la, 0)
		var C := Vector2(cs, sqrt(1.0 - cs * cs)) * lc
		var x := B1._frv(cfg.xy[0])
		var y := B1._frv(cfg.xy[1])
		var D := B * x + C * y
		var shapes := [_poly([A, B, C], "dim")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [-4, -12]})
		shapes += [_beam(B, C, 1, "cyan"), _beam(C, B, 1, "cyan"), _beam(A, D, 2, "gold")]
		shapes += _lamp(D, 3, "D")
		shapes.append(_right(D, C - B, A - D, {"at": 3}))
		var eqs := "|\\vec{AB}| = %s，|\\vec{AC}| = %s，\\vec{AB} · \\vec{AC} = %s" % [_n(la), _n(lc), _fv(float(cfg.ac))]
		vars.append({"eq": "△ABC 中，%s\n\\ol{AD} ⊥ \\ol{BC} 於 D，\\vec{AD} = x\\vec{AB} + y\\vec{AC}，求 (x, y)" % eqs,
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				_f("光束一", "D 在直線 BC 上", "x + y = [0]", ["1"], "D 在 BC 上：x + y = 1", "係數和是多少？", T_BAS),
				_f("光束二", "\\vec{AD} · \\vec{BC} = 0", "[0]x + [1]y = 0", cfg.ans,
					"(x\\vec{AB} + y\\vec{AC}) · (\\vec{AC} − \\vec{AB}) = 0 ⇒ %sx + %sy = 0" % [_fv(float(cfg.ans[0])), _fv(float(cfg.ans[1]))],
					"展開：x(\\vec{AB} · \\vec{AC} − |\\vec{AB}|^{2}) + y(|\\vec{AC}|^{2} − \\vec{AB} · \\vec{AC})。", T_PERP, "prop"),
				_f("交點", "聯立", "(x, y) = ([0], [1])", cfg.xy, "(x, y) = (%s, %s)" % [B1._frs(cfg.xy[0]), B1._frs(cfg.xy[1])], "第二式寫成 x、y 的比，再用 x + y = 1。", T_BAS),
			]})
	return {"id": "foot", "chapter": 1, "type": "forge", "title": "陽光下的垂足",
		"story": "從 A 垂直照下一道陽光，落在 BC 的哪裡？",
		"insight": "垂足 D：兩個條件，D 在 BC 上（x + y = 1）、\\vec{AD} · \\vec{BC} = 0\n\\vec{BC} = \\vec{AC} − \\vec{AB}，展開後聯立。",
		"variants": vars}


## 8 日晷的圓（A42）：\vec{PA} · \vec{PB} = k 是一個圓
static func _circle() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(4, 0), "B": Vector2(-4, 0), "k": 9, "L": [3, 4, 35], "d": 7, "x": [-7.0, 10.0], "y": [-6.0, 8.5]},
			{"A": Vector2(1, 3), "B": Vector2(1, -5), "k": 9, "L": [4, -3, 37], "d": 6, "x": [-5.5, 10.5], "y": [-8.5, 5.5]}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var M := (A + B) / 2.0
		var L: Array = cfg.L
		var nrm := Vector2(float(L[0]), float(L[1])).normalized()
		var dd := float(cfg.d)
		var foot := M + nrm * dd
		var far := M - nrm * 5.0
		var expr := "(%s - x) * (%s - x) + (%s - y) * (%s - y)" % [_e(A.x), _e(B.x), _e(A.y), _e(B.y)]
		var trace := []
		for q in [Vector2(5, 0), Vector2(3, 4), Vector2(0, 5), Vector2(-4, 3)]:
			trace.append(_p(M + q))
		var lstr := "%sx %s %sy = %d" % [_n(float(L[0])), "+" if int(L[1]) > 0 else "−", _n(absf(float(L[1]))), L[2]]
		var shapes := [{"k": "line", "abc": [L[0], L[1], -int(L[2])], "c": "cyan", "s": "L"}]
		shapes += _dots({"A": A, "B": B}, "text", {"A": [8, -8], "B": [8, -8]})
		shapes += [{"k": "circle", "o": _p(M), "r": 5, "c": "gold", "w": 2.0, "at": 1}, _dot(M, "M", "dim", {"at": 1, "off": [-16, 14]}),
			_seg(M, foot, "dim", {"dash": true, "at": 3}), _right(foot, nrm, Vector2(-nrm.y, nrm.x), {"at": 3}),
			_seg(far, foot, "gold", {"at": 4, "w": 2.5}), _dot(far, "P", "gold", {"at": 4, "off": [-16, 14]})]
		vars.append({"eq": "A%s、B%s，動點 P 滿足 \\vec{PA} · \\vec{PB} = %d\n求 P 到直線 L：%s 的最大距離" % [_pt(A), _pt(B), cfg.k, lstr],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "找光點", "q": "拖 P，找 4 個讓內積 = %d 的點" % cfg.k, "tag": T_DOT, "goal": "trace", "need": 4,
				 "sandbox": {"label": "P", "lit": "abs(%s - %d) < 0.01" % [expr, cfg.k], "trace": true, "start": _p(M),
					"read": "\\vec{PA} · \\vec{PB} = {%s}" % expr},
				 "ans": trace[0], "trace_ans": trace, "nudge": "離 \\ol{AB} 的中點越遠，內積越大。",
				 "line": "光點排成一個圓"},
				_f("半徑", "M 是 \\ol{AB} 中點", "|\\vec{PM}| = [0]", ["5"],
					"\\vec{PA} · \\vec{PB} = |\\vec{PM}|^{2} − |\\vec{MA}|^{2} = %d ⇒ |\\vec{PM}| = 5：以 M%s 為圓心、半徑 5 的圓" % [cfg.k, _pt(M)],
					"\\vec{PA} = \\vec{PM} + \\vec{MA}、\\vec{PB} = \\vec{PM} − \\vec{MA}，相乘。", T_BAS),
				_f("距離", "圓心 M 到 L", "距離 = [0]", [str(cfg.d)], "M 到 L 的距離 = %d" % cfg.d, "點到直線的距離公式。", T_DOT),
				_f("最大", "P 到 L 的最大距離", "最大距離 = [0]", [str(cfg.d + 5)], "最大距離 = %d + 5 = %d" % [cfg.d, cfg.d + 5], "圓心到 L 的距離再加上半徑。", T_DOT),
			]})
	return {"id": "dialcircle", "chapter": 1, "type": "forge", "title": "日晷的圓",
		"story": "內積一樣大的點排成什麼形狀？",
		"insight": "\\vec{PA} · \\vec{PB} = |\\vec{PM}|^{2} − |\\vec{MA}|^{2}（M 是 \\ol{AB} 中點）\n內積是定值 ⇒ P 在以 M 為圓心的圓上。",
		"variants": vars}


# ======================= 第二章．垂直、平行與正射影 =======================

## 10 方格上的內積（新）
static func _coord() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(3, 4), "b": Vector2(2, 1), "cells": [["6", "0"], ["0", "4"]], "sg": [[1, 0], [0, 1]], "dot": 10, "sh": "2",
				"rows": ["3\\vec{i}", "4\\vec{j}"], "cols": ["2\\vec{i}", "\\vec{j}"], "x": [-8.5, 5.5], "y": [-1.8, 5.2], "ep": Vector2(-8.2, 4.8)},
			{"a": Vector2(4, -3), "b": Vector2(-1, 3), "cells": [["−4", "0"], ["0", "−9"]], "sg": [[-1, 0], [0, -1]], "dot": -13, "sh": "-13/5",
				"rows": ["4\\vec{i}", "−3\\vec{j}"], "cols": ["−\\vec{i}", "3\\vec{j}"], "x": [-9.5, 5.5], "y": [-4.0, 3.8], "ep": Vector2(-10.6, 3.4)}]:
		var a: Vector2 = cfg.a
		var b: Vector2 = cfg.b
		var shapes := [_ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"ls": -1}), _ar(Vector2.ZERO, b, "pink", "\\vec{b}"),
			_expand(cfg.ep, cfg.rows, cfg.cols, cfg.cells, cfg.sg, 1),
			_shadow(Vector2.ZERO, b, a, {"at": 3, "ground": true})]
		vars.append({"eq": "\\vec{a} = %s，\\vec{b} = %s\n\\vec{b} 在 \\vec{a} 方向上的影子多長？" % [_pt(a), _pt(b)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("\\vec{i}、\\vec{j}", "\\vec{i}、\\vec{j} 的內積", "\\vec{i} · \\vec{i} = [0]，\\vec{i} · \\vec{j} = [1]", ["1", "0"],
					"\\vec{i} · \\vec{i} = \\vec{j} · \\vec{j} = 1，\\vec{i} · \\vec{j} = 0（垂直）：斜對角兩格是 0",
					"\\vec{i}、\\vec{j} 是長度 1、互相垂直的單位向量。", T_DOT),
				_f("內積", "\\vec{a} · \\vec{b} = ？", "\\vec{a} · \\vec{b} = [0]", [str(cfg.dot)],
					"\\vec{a} · \\vec{b} = a_{1}b_{1} + a_{2}b_{2} = %s" % _fv(float(cfg.dot)), "剩下的兩格加起來。", T_DOT),
				_f("影子長", "影子長 = \\frac{\\vec{a} · \\vec{b}}{|\\vec{a}|}", "影子長 = [0]", [cfg.sh],
					"影子長 = \\frac{\\vec{a} · \\vec{b}}{|\\vec{a}|} = %s%s" % [B1._frs(cfg.sh), "（負的：在反方向）" if int(cfg.dot) < 0 else ""],
					"|\\vec{a}| = 5。", T_PROJ),
			]})
	return {"id": "coord", "chapter": 2, "type": "forge", "title": "方格上的內積",
		"story": "石台刻上方格，內積可以直接算。",
		"insight": "(a_{1}, a_{2}) · (b_{1}, b_{2}) = a_{1}b_{1} + a_{2}b_{2}\n因為 \\vec{i} · \\vec{i} = \\vec{j} · \\vec{j} = 1、\\vec{i} · \\vec{j} = 0。",
		"variants": vars}


## 11 垂直的時刻（A47）
static func _perp_t() -> Dictionary:
	var vars := []
	for cfg in [{"uu": 4.0, "vv": 2.0, "uv": 2.0, "s": 1, "t": -3.0, "c": ["18", "6"], "rng": [-5, 3], "x": [-2.5, 7.5], "y": [-6.5, 3.2],
				"eq2": "(\\vec{u} + \\vec{v}) ⊥ (\\vec{u} + t\\vec{v})"},
			{"uu": 3.0, "vv": 2.0, "uv": 2.0, "s": -1, "t": 3.5, "c": ["7", "-2"], "rng": [-2, 5], "x": [-2.0, 7.5], "y": [-2.6, 7.4],
				"eq2": "(\\vec{u} − \\vec{v}) ⊥ (\\vec{u} + t\\vec{v})"}]:
		var lu: float = cfg.uu
		var lv: float = cfg.vv
		var cs := float(cfg.uv) / (lu * lv)
		var u := Vector2(lu, 0)
		var v := Vector2(cs, sqrt(1.0 - cs * cs)) * lv
		var s: int = cfg.s
		var w := u + v * s
		var tt: float = cfg.t
		var ans := u + v * tt
		var shapes := [_ar(Vector2.ZERO, u, "dim", "\\vec{u}", {"ls": -1, "w": 2.0}), _ar(Vector2.ZERO, v, "dim", "\\vec{v}", {"w": 2.0}),
			_ar(Vector2.ZERO, w, "gold", "\\vec{u} %s \\vec{v}" % ("+" if s > 0 else "−"), {"w": 3.0}),
			_ar(Vector2.ZERO, ans, "cyan", "\\vec{u} + t\\vec{v}", {"at": 3}), _right(Vector2.ZERO, w, ans, {"at": 3})]
		var line_arrow := {"k": "arrow", "a": [0, 0], "b": ["%s + t * %s" % [_e(u.x), str(v.x)], "t * %s" % str(v.y)], "c": "cyan", "w": 3.0}
		vars.append({"eq": "|\\vec{u}| = %s，|\\vec{v}| = %s，\\vec{u} · \\vec{v} = %s\n%s，求 t" % [_n(lu), _n(lv), _n(float(cfg.uv)), cfg.eq2],
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "slide", "name": "先猜", "q": "拖 t，猜什麼時候垂直", "tag": T_PERP, "free": true, "line_vals": true,
				 "params": [{"n": "t", "min": cfg.rng[0], "max": cfg.rng[1], "step": 0.5, "v": 1}],
				 "lines": [line_arrow], "eq": "t = {t}", "line": "先猜：t = {t}", "nudge": "拉動滑桿，看藍色箭頭什麼時候和金色的垂直。", "big": true},
				_f("展開田", "內積 = 0，展開", "[0] + [1]t = 0", cfg.c,
					"|\\vec{u}|^{2} + (%s + t)\\vec{u} · \\vec{v} + %st|\\vec{v}|^{2} = 0 ⇒ %s %s %st = 0" % [str(s), "" if s > 0 else "−", cfg.c[0],
						"+" if int(cfg.c[1]) > 0 else "−", str(absi(int(cfg.c[1])))],
					"|\\vec{u}|^{2} = %s，|\\vec{v}|^{2} = %s，t 的項：t\\vec{u} · \\vec{v} 和 %st|\\vec{v}|^{2}。" % [_n(lu * lu), _n(lv * lv), "" if s > 0 else "−"], T_PERP, "prop"),
				_f("t", "解 t", "t = [0]", [_ans(tt)], "t = %s：兩支箭頭垂直（直角記號亮起來）" % _fv(tt), "%s %s %st = 0。" % [cfg.c[0], "+" if int(cfg.c[1]) > 0 else "−", str(absi(int(cfg.c[1])))], T_PERP),
			]})
	return {"id": "perpt", "chapter": 2, "type": "forge", "title": "垂直的時刻",
		"story": "日晷的指針轉到哪一刻，兩支箭頭剛好垂直？",
		"insight": "垂直 ⇔ 內積 = 0\n(\\vec{u} + s\\vec{v}) · (\\vec{u} + t\\vec{v}) 像乘法一樣展開，用 |\\vec{u}|^{2}、|\\vec{v}|^{2}、\\vec{u} · \\vec{v} 代進去。",
		"variants": vars}


## 12 平行的時刻（A48）
static func _par_t() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(3, 1), "b": Vector2(6, 2), "t": "6", "eq": "\\vec{a} = (3, 1)，\\vec{b} = (t, 2)\n\\vec{a} + \\vec{b} ∥ \\vec{a} − 2\\vec{b}，求 t",
				"f1": ["\\vec{a} + \\vec{b} = ([0] + t, [1])", ["3", "3"]], "f2": ["\\vec{a} − 2\\vec{b} = ([0] − [1]t, [2])", ["3", "2", "-3"]],
				"m": [1, 1, 1, -2], "l1": "\\vec{a} + \\vec{b} = (3 + t, 3)", "l2": "\\vec{a} − 2\\vec{b} = (3 − 2t, −3)", "cross": "−3(3 + t) = 3(3 − 2t)", "x": [-11.0, 11.0], "y": [-4.6, 4.6]},
			{"a": Vector2(2, -1), "b": Vector2(1, -0.5), "t": "-1/2", "eq": "\\vec{a} = (2, −1)，\\vec{b} = (1, t)\n\\vec{a} + \\vec{b} ∥ 3\\vec{a} − \\vec{b}，求 t",
				"f1": ["\\vec{a} + \\vec{b} = ([0], t − [1])", ["3", "1"]], "f2": ["3\\vec{a} − \\vec{b} = ([0], [1] − t)", ["5", "-3"]],
				"m": [1, 1, 3, -1], "l1": "\\vec{a} + \\vec{b} = (3, t − 1)", "l2": "3\\vec{a} − \\vec{b} = (5, −3 − t)", "cross": "3(−3 − t) = 5(t − 1)", "x": [-6.5, 6.5], "y": [-3.2, 2.0]}]:
		var a: Vector2 = cfg.a
		var b: Vector2 = cfg.b
		var m: Array = cfg.m
		var p: Vector2 = a * float(m[0]) + b * float(m[1])
		var q: Vector2 = a * float(m[2]) + b * float(m[3])
		var d := a.normalized()
		var shapes := [_ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"ls": -1}),
			_beam(Vector2.ZERO, d, 3, "gold"), _beam(Vector2.ZERO, -d, 3, "gold"),
			_ar(Vector2.ZERO, p, "lime", "", {"at": 3}), _ar(Vector2.ZERO, q, "pink", "", {"at": 3}), _ar(Vector2.ZERO, b, "violet", "\\vec{b}", {"at": 3, "w": 2.0})]
		vars.append({"eq": cfg.eq, "plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("第一支", "用 t 表示", cfg.f1[0], cfg.f1[1], cfg.l1, "x 分量、y 分量各自算。", T_PERP),
				_f("第二支", "用 t 表示", cfg.f2[0], cfg.f2[1], cfg.l2, "x 分量、y 分量各自算。", T_PERP),
				_f("平行", "x_{1}y_{2} = x_{2}y_{1}", "t = [0]", [cfg.t], "%s ⇒ t = %s（這時 \\vec{a} ∥ \\vec{b}）" % [cfg.cross, B1._frs(cfg.t)],
					"%s。" % cfg.cross, T_PERP),
			]})
	return {"id": "part", "chapter": 2, "type": "forge", "title": "平行的時刻",
		"story": "兩支箭頭什麼時候落在同一道光上？",
		"insight": "\\vec{p} = (x_{1}, y_{1}) ∥ \\vec{q} = (x_{2}, y_{2}) ⇔ x_{1}y_{2} = x_{2}y_{1}\n兩個組合平行，其實就是 \\vec{a} ∥ \\vec{b}。",
		"variants": vars}


## 13 兩道條件的光（A49）
static func _two_cond() -> Dictionary:
	var vars := []
	for cfg in [{"OA": Vector2(2, 1), "OB": Vector2(-1, 1), "C": Vector2(3, 3), "c1": ["-1", "1"], "c2": "(x + 1) − [0](y − 1) = 0", "k2": "2", "x": [-4.5, 6.5], "y": [-2.6, 4.6]},
			{"OA": Vector2(3, 1), "OB": Vector2(1, 2), "C": Vector2(-2, 1), "c1": ["1", "2"], "c2": "(x − 1) − [0](y − 2) = 0", "k2": "3", "x": [-6.5, 4.5], "y": [-2.0, 3.6]}]:
		var OA: Vector2 = cfg.OA
		var OB: Vector2 = cfg.OB
		var C: Vector2 = cfg.C
		var OD := C - OA
		var pd := Vector2(-OB.y, OB.x)
		var O := Vector2.ZERO
		var shapes := [_ar(O, OA, "cyan", "\\vec{OA}", {"ls": -1}), _ar(O, OB, "pink", "\\vec{OB}")]
		shapes += [_dot(OA, "A", "text", {"off": [8, 4]}), _dot(OB, "B", "text", {"off": [-14, -4]})]
		shapes += [_beam(O, pd, 1, "lime"), _beam(O, -pd, 1, "lime"), _right(O, OB, pd, {"at": 1}),
			_beam(OB, OB + OA, 2, "gold"), _beam(OB, OB - OA, 2, "gold")]
		shapes += _lamp(C, 3, "C")
		shapes += [_ar(O, OD, "lime", "\\vec{OD}", {"at": 4}), _ar(OD, C, "cyan", "", {"at": 4, "dash": true}), _dot(OD, "D", "lime", {"at": 4, "off": [8, 14]})]
		vars.append({"eq": "\\vec{OA} = %s，\\vec{OB} = %s，\\vec{OC} ⊥ \\vec{OB}\n\\vec{BC} ∥ \\vec{OA}，\\vec{OD} + \\vec{OA} = \\vec{OC}，求 \\vec{OD}" % [_pt(OA), _pt(OB)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("光束一", "\\vec{OC} ⊥ \\vec{OB}，設 C(x, y)", "[0]x + [1]y = 0", cfg.c1, "\\vec{OC} · \\vec{OB} = 0：(x, y) · %s = 0" % _pt(OB), "內積 = 0：x 乘 x 分量、y 乘 y 分量。", T_PERP, "prop"),
				_f("光束二", "\\vec{BC} ∥ \\vec{OA}", cfg.c2, [cfg.k2], "\\vec{BC} = (x %s, y %s) ∥ %s：%s" % [
					"+ 1" if OB.x < 0 else "− 1", "− %s" % _n(OB.y), _pt(OA), String(cfg.c2).replace("[0]", cfg.k2)],
					"\\vec{BC} 的分量和 %s 成比例。" % _pt(OA), T_PERP),
				_f("交點", "聯立", "C = ([0], [1])", [_ans(C.x), _ans(C.y)], "C%s" % _pt(C), "第一式寫成 x 和 y 的關係，代進第二式。", T_PERP),
				_f("\\vec{OD}", "\\vec{OD} = \\vec{OC} − \\vec{OA}", "\\vec{OD} = ([0], [1])", [_ans(OD.x), _ans(OD.y)], "\\vec{OD} = %s" % _pt(OD), "分量相減。", T_PERP),
			]})
	return {"id": "twocond", "chapter": 2, "type": "forge", "title": "兩道條件的光",
		"story": "一個條件一道光，交會的地方就是 C。",
		"insight": "垂直：內積 = 0，平行：分量成比例\n兩個條件各寫一個一次式，聯立。",
		"variants": vars}


## 14 影子＋竿子（A50）
static func _pole() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(7, 4), "b": Vector2(1, 2), "k": 3, "ask": [1, 3], "x": [-2.5, 9.5], "y": [-2.6, 7.4], "start": 1},
			{"a": Vector2(1, 8), "b": Vector2(2, 1), "k": 2, "ask": [2, 1], "x": [-4.5, 7.5], "y": [-1.6, 8.6], "start": 1}]:
		var a: Vector2 = cfg.a
		var b: Vector2 = cfg.b
		var u := b * float(cfg.k)
		var v := a - u
		var ask: Array = cfg.ask
		var res: Vector2 = u * float(ask[0]) + v * float(ask[1])
		var lit := "abs((%s - x) * x + (%s - y) * y) < 0.01 and abs(x) + abs(y) > 0.01" % [_e(a.x), _e(a.y)]
		var shapes := [_line(Vector2.ZERO, b, "faint"), _ar(Vector2.ZERO, b, "pink", "\\vec{b}", {"w": 2.5}), _ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"ls": -1}),
			_ar(Vector2.ZERO, u, "gold", "\\vec{u}", {"at": 1, "ls": 1, "lt": 0.75}), _ar(u, a, "lime", "\\vec{v}", {"at": 1}), _right(u, -b, v, {"at": 1})]
		var comb := B1._lin(str(ask[0]), "u", str(ask[1]), "v")
		vars.append({"eq": "把 \\vec{a} = %s 拆成和 \\vec{b} = %s 平行的 \\vec{u}\n和垂直的 \\vec{v}，求 %s" % [_pt(a), _pt(b), comb],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "竿子站直", "q": "拖影子的頭 F，讓竿子站直", "tag": T_PROJ, "goal": "lit", "ans": _p(u), "big": true,
				 "sandbox": {"label": "F", "on": {"o": [0, 0], "d": _p(b), "step": 1}, "pole": {"o": [0, 0], "a": _p(a)}, "lit": lit, "start": _p(b * float(cfg.start))},
				 "nudge": "竿子往哪邊歪，F 就往那邊移。", "line": "竿子站直：\\vec{u} = %s（影子）" % _pt(u)},
				_f("竿子", "\\vec{v} = \\vec{a} − \\vec{u}", "\\vec{v} = ([0], [1])", [_ans(v.x), _ans(v.y)], "\\vec{v} = %s（竿子）" % _pt(v), "分量相減。", T_PROJ),
				_f("組合", "求 %s" % comb, "%s = ([0], [1])" % comb, [_ans(res.x), _ans(res.y)], "%s = %s" % [comb, _pt(res)], "分量各自算。", T_PROJ),
			]})
	return {"id": "pole", "chapter": 2, "type": "forge", "title": "影子＋竿子",
		"story": "一支箭頭 = 地上的影子 + 垂直的竿子。",
		"insight": "\\vec{a} = \\vec{u} + \\vec{v}：\\vec{u} ∥ \\vec{b}（影子，正射影）、\\vec{v} ⊥ \\vec{b}（竿子）\n竿子站直的條件：(\\vec{a} − \\vec{u}) · \\vec{b} = 0。",
		"variants": vars}


## 15 落在格子中間的影子（新）：正射影的公式
static func _formula() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(5, 2), "b": Vector2(1, 3), "fr": ["11", "10"], "sh": ["11/10", "33/10"], "x": [-2.5, 7.0], "y": [-1.4, 4.6]},
			{"a": Vector2(-3, 4), "b": Vector2(2, 1), "fr": ["-2", "5"], "sh": ["-4/5", "-2/5"], "x": [-5.0, 4.0], "y": [-1.6, 4.6]}]:
		var a: Vector2 = cfg.a
		var b: Vector2 = cfg.b
		var sh := Vector2(B1._frv(cfg.sh[0]), B1._frv(cfg.sh[1]))
		var lit := "abs((%s - x) * x + (%s - y) * y) < 0.01 and abs(x) + abs(y) > 0.01" % [_e(a.x), _e(a.y)]
		var shapes := [_line(Vector2.ZERO, b, "faint"), _ar(Vector2.ZERO, b, "pink", "\\vec{b}", {"w": 2.5}), _ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"ls": -1}),
			_ar(Vector2.ZERO, sh, "gold", "", {"at": 3}), _ar(sh, a, "lime", "", {"at": 3}), _right(sh, b, a - sh, {"at": 3}), _dot(sh, "", "gold", {"at": 3})]
		var ab := int(a.dot(b))
		var bb := int(b.dot(b))
		vars.append({"eq": "\\vec{a} = %s，\\vec{b} = %s\n求 \\vec{a} 在 \\vec{b} 上的正射影" % [_pt(a), _pt(b)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "choice", "name": "影子長", "q": "拖不準！影子長 = ？", "big": true,
				 "options": ["\\frac{\\vec{a} · \\vec{b}}{|\\vec{b}|}", "\\frac{\\vec{a} · \\vec{b}}{|\\vec{b}|^{2}}", "\\vec{a} · \\vec{b}"], "correct": 0,
				 "sandbox": {"label": "F", "on": {"o": [0, 0], "d": _p(b), "step": 1}, "pole": {"o": [0, 0], "a": _p(a)}, "lit": lit, "start": _p(b)},
				 "why": "影子長 = |\\vec{a}|cos θ = \\frac{|\\vec{a}||\\vec{b}|cos θ}{|\\vec{b}|} = \\frac{\\vec{a} · \\vec{b}}{|\\vec{b}|}。",
				 "nudge": "\\vec{a} · \\vec{b} = |\\vec{b}| × 影子長。", "line": "影子長 = |\\vec{a}|cos θ = \\frac{\\vec{a} · \\vec{b}}{|\\vec{b}|}", "tag": T_PROJ},
				_f("係數", "影子長 × \\frac{\\vec{b}}{|\\vec{b}|}", "\\vec{a} · \\vec{b} = [0]，|\\vec{b}|^{2} = [1]", cfg.fr,
					"正射影 = \\frac{\\vec{a} · \\vec{b}}{|\\vec{b}|^{2}}\\vec{b} = \\frac{%d}{%d}\\vec{b}" % [ab, bb] if ab > 0 else "正射影 = \\frac{\\vec{a} · \\vec{b}}{|\\vec{b}|^{2}}\\vec{b} = −\\frac{%d}{%d}\\vec{b}（負的：影子在反方向）" % [-ab, bb],
					"\\vec{a} · \\vec{b} = a_{1}b_{1} + a_{2}b_{2}，|\\vec{b}|^{2} = b_{1}^{2} + b_{2}^{2}。", T_PROJ),
				_f("正射影", "乘上 \\vec{b}", "正射影 = ([0], [1])", cfg.sh, "正射影 = %s" % _pt(sh), "\\vec{b} = %s 乘上係數。" % _pt(b), T_PROJ),
			]})
	return {"id": "formula", "chapter": 2, "type": "forge", "title": "落在格子中間的影子",
		"story": "這次影子落在格子中間，拖不準了。",
		"insight": "\\vec{a} 在 \\vec{b} 上的正射影 = \\frac{\\vec{a} · \\vec{b}}{|\\vec{b}|^{2}}\\vec{b}\n正射影長 = \\frac{|\\vec{a} · \\vec{b}|}{|\\vec{b}|}。係數是負的，影子在反方向。",
		"variants": vars}


## 16 影子和影子長（A78）
static func _proj_cards() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(-1, 2), "B": Vector2(9, 7), "C": Vector2(2, 6), "x": [-2.5, 11.0], "y": [0.5, 11.5],
				"cards": [["\\vec{AB} 在 \\vec{AC} 方向上的正射影是 (6, 8)", true, "proj"], ["\\vec{AB} 在 \\vec{AC} 方向上的正射影是 (3, 4)", false, "half"],
					["\\vec{AB} 在 \\vec{AC} 方向上的正射影長是 10", true, "len"], ["B 在直線 AC 上的投影點是 (5, 10)", true, "foot"]]},
			{"A": Vector2(1, -1), "B": Vector2(12, 1), "C": Vector2(5, 2), "x": [-0.5, 13.0], "y": [-2.6, 6.6],
				"cards": [["\\vec{AB} 在 \\vec{AC} 方向上的正射影是 (4, 3)", false, "half"], ["\\vec{AB} 在 \\vec{AC} 方向上的正射影長是 10", true, "len"],
					["\\vec{AB} 在 \\vec{AC} 方向上的正射影長是 5", false, "len5"], ["B 在直線 AC 上的投影點是 (9, 5)", true, "foot"]]}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var C: Vector2 = cfg.C
		var ab := B - A
		var ac := C - A
		var sh := ac * (ab.dot(ac) / ac.length_squared())
		var foot := A + sh
		var shapes := [_line(A, C, "faint"), _ar(A, B, "cyan", "\\vec{AB}", {"ls": -1}), _ar(A, C, "pink", "\\vec{AC}")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [8, -4], "C": [-16, -6]})
		var steps := []
		var k := 0
		for cd in cfg.cards:
			k += 1
			var ok: bool = cd[1]
			var kind := String(cd[2])
			shapes.append(_shadow(A, B, ac, {"at": k, "until": k + 1}))
			if kind == "half":
				shapes.append(_ar(A, A + sh / 2.0, "pink", "", {"at": k, "until": k + 1, "dash": true, "w": 2.0}))
			elif kind == "foot":
				shapes.append(_dot(foot, _pt(foot), "gold", {"at": k, "off": [8, 14]}))
			elif kind == "len" or kind == "len5":
				shapes.append({"k": "ruler", "a": _p(A), "b": _p(foot), "n": 10, "m": 10, "at": k, "until": k + 1, "c": "gold"})
			var why := ""
			match kind:
				"proj":
					why = "\\frac{\\vec{AB} · \\vec{AC}}{|\\vec{AC}|^{2}}\\vec{AC} = \\frac{%d}{25}%s = %s。" % [int(ab.dot(ac)), _pt(ac), _pt(sh)]
				"half":
					why = "正射影是 \\frac{%d}{25}%s = %s，%s。" % [int(ab.dot(ac)), _pt(ac), _pt(sh), "卡上的只有一半" if sh.is_equal_approx(ac * 2.0) else "卡上的是 \\vec{AC} 本身，太短了"]
				"len":
					why = "正射影長 = \\frac{\\vec{AB} · \\vec{AC}}{|\\vec{AC}|} = \\frac{%d}{5} = 10。" % int(ab.dot(ac))
				"len5":
					why = "正射影長是 \\frac{%d}{5} = 10，不是 5（5 是 |\\vec{AC}|）。" % int(ab.dot(ac))
				"foot":
					why = "投影點 = A + 正射影 = %s + %s = %s。" % [_pt(A), _pt(sh), _pt(foot)]
			var st := _j(["審判一", "審判二", "審判三", "審判四"][k - 1], String(cd[0]), ok, why, String(cd[0]) if ok else "%s ✕" % cd[0], T_PROJ)
			st["big"] = true
			steps.append(st)
		vars.append({"eq": "A%s、B%s、C%s\n下面哪些正確？" % [_pt(A), _pt(B), _pt(C)], "plane": _axes(cfg.x, cfg.y, shapes), "steps": steps})
	return {"id": "projc", "chapter": 2, "type": "forge", "title": "影子和影子長",
		"story": "影子是向量，影子長是數字，投影點是點。",
		"insight": "正射影 = \\frac{\\vec{a} · \\vec{b}}{|\\vec{b}|^{2}}\\vec{b}（向量）\n正射影長 = \\frac{|\\vec{a} · \\vec{b}|}{|\\vec{b}|}（數字），投影點 = 起點 + 正射影。",
		"variants": vars}


## 17 同一道陽光（A77）
static func _same_ray() -> Dictionary:
	var vars := []
	var O := Vector2.ZERO
	# 第 1 組：\vec{OA} · \vec{OB} = \vec{OB} · \vec{OC}，拖 C
	var A := Vector2(1, 3)
	var B := Vector2(4, 0)
	var s1 := [_line(O, B, "faint"), _ar(O, B, "pink", "\\vec{OB}", {"ls": -1}), _ar(O, A, "cyan", "\\vec{OA}"),
		_dot(A, "A", "text", {"off": [8, -4]}), _shadow(O, A, B), _line(A, A + Vector2(0, 1), "gold", {"dash": true, "at": 1})]
	var st1 := [
		{"kind": "vplace", "name": "找 C", "q": "拖 C，找 3 個讓燈亮的位置", "tag": T_PROJ, "goal": "trace", "need": 3,
		 "sandbox": {"label": "C", "arrow": {"o": [0, 0], "c": "lime", "s": "\\vec{OC}"}, "lit": "abs(4 * x - 4) < 0.01", "trace": true, "start": [3, 2],
			"read": "\\vec{OB} · \\vec{OC} = {4 * x}"},
		 "ans": [1, -1], "trace_ans": [[1, -1], [1, 2], [1, 1]], "nudge": "\\vec{OA} · \\vec{OB} = 4：C 的影子要和 A 的一樣長。",
		 "line": "燈亮的 C 排成一條線：A 的那一道陽光（垂直 \\vec{OB}）", "big": true},
		_j("審判一", "\\vec{OA} = \\vec{OC}", false, "C 可以在那一道陽光上的任何地方，不一定是 A。", "\\vec{OA} = \\vec{OC} ✕", T_PROJ),
		_j("審判二", "\\vec{OA} ⊥ \\vec{OB} 而且 \\vec{OC} ⊥ \\vec{OB}", false, "\\vec{OA} · \\vec{OB} = 4 ≠ 0，不垂直。", "不一定垂直 ✕", T_PROJ),
		_j("審判三", "\\vec{AC} ⊥ \\vec{OB}", true, "(\\vec{OC} − \\vec{OA}) · \\vec{OB} = 0：A、C 在同一道陽光上。", "\\vec{AC} ⊥ \\vec{OB} ○", T_PROJ),
		_j("審判四", "\\vec{OA}、\\vec{OC} 在 \\vec{OB} 上的正射影相同", true, "內積一樣、地面一樣：影子一樣。", "正射影相同 ○", T_PROJ)]
	for st in st1:
		st["big"] = true
	vars.append({"eq": "\\vec{OA}、\\vec{OB}、\\vec{OC} 是三支相異的非零向量\n\\vec{OA} · \\vec{OB} = \\vec{OB} · \\vec{OC}，下面哪些恆成立？", "plane": _plane([-2.5, 6.5], [-2.6, 4.6], s1), "steps": st1})
	# 第 2 組：\vec{OA} · \vec{OC} = \vec{OB} · \vec{OC}，拖 B
	var A2 := Vector2(2, 3)
	var C2 := Vector2(3, 0)
	var s2 := [_line(O, C2, "faint"), _ar(O, C2, "pink", "\\vec{OC}", {"ls": -1}), _ar(O, A2, "cyan", "\\vec{OA}"),
		_dot(A2, "A", "text", {"off": [8, -4]}), _shadow(O, A2, C2), _line(A2, A2 + Vector2(0, 1), "gold", {"dash": true, "at": 1})]
	var st2 := [
		{"kind": "vplace", "name": "找 B", "q": "拖 B，找 3 個讓燈亮的位置", "tag": T_PROJ, "goal": "trace", "need": 3,
		 "sandbox": {"label": "B", "arrow": {"o": [0, 0], "c": "lime", "s": "\\vec{OB}"}, "lit": "abs(3 * x - 6) < 0.01", "trace": true, "start": [-1, 2],
			"read": "\\vec{OB} · \\vec{OC} = {3 * x}"},
		 "ans": [2, -1], "trace_ans": [[2, -1], [2, 1], [2, -2]], "nudge": "\\vec{OA} · \\vec{OC} = 6：B 的影子要和 A 的一樣長。",
		 "line": "燈亮的 B 排成一條線：A 的那一道陽光（垂直 \\vec{OC}）", "big": true},
		_j("審判一", "|\\vec{OA}| = |\\vec{OB}|", false, "B 在陽光上越高越遠：長度不一定一樣。", "|\\vec{OA}| = |\\vec{OB}| ✕", T_PROJ),
		_j("審判二", "\\vec{AB} ⊥ \\vec{OC}", true, "(\\vec{OB} − \\vec{OA}) · \\vec{OC} = 0：A、B 在同一道陽光上。", "\\vec{AB} ⊥ \\vec{OC} ○", T_PROJ),
		_j("審判三", "\\vec{OA}、\\vec{OB} 在 \\vec{OC} 上的正射影相同", true, "內積一樣、地面一樣：影子一樣。", "正射影相同 ○", T_PROJ),
		_j("審判四", "\\vec{OA} ⊥ \\vec{OC}", false, "\\vec{OA} · \\vec{OC} = 6 ≠ 0，不垂直。", "\\vec{OA} ⊥ \\vec{OC} ✕", T_PROJ)]
	for st in st2:
		st["big"] = true
	vars.append({"eq": "\\vec{OA}、\\vec{OB}、\\vec{OC} 是三支相異的非零向量\n\\vec{OA} · \\vec{OC} = \\vec{OB} · \\vec{OC}，下面哪些恆成立？", "plane": _plane([-2.5, 5.5], [-2.6, 4.6], s2), "steps": st2})
	return {"id": "sameray", "chapter": 2, "type": "forge", "title": "同一道陽光",
		"story": "內積一樣大的點，都站在同一道陽光上。",
		"insight": "\\vec{OA} · \\vec{OB} = \\vec{OC} · \\vec{OB} ⇔ (\\vec{OA} − \\vec{OC}) · \\vec{OB} = 0\nA、C 在同一道垂直 \\vec{OB} 的陽光上：正射影相同。",
		"variants": vars}


## 18 竿子垂直地面（A79）
static func _pole_tap() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(23, 9), "b": Vector2(31, 5), "ask": "(\\vec{a} − \\vec{c}) · (5\\vec{b})", "x": [-3.0, 35.0], "y": [-3.0, 13.0]},
			{"a": Vector2(26, 7), "b": Vector2(12, 35), "ask": "(\\vec{a} − \\vec{c}) · (\\vec{b} + 2\\vec{c})", "x": [-4.0, 30.0], "y": [-3.0, 38.0]}]:
		var a: Vector2 = cfg.a
		var b: Vector2 = cfg.b
		var c := b * (a.dot(b) / b.length_squared())
		var O := Vector2.ZERO
		var shapes := [_ar(O, b, "pink", "\\vec{b}", {"id": "b", "ls": -1}), _ar(O, a, "cyan", "\\vec{a}", {"id": "a"}),
			_ar(O, c, "gold", "\\vec{c}", {"id": "c", "w": 4.0, "lt": 0.4}), _ar(c, a, "lime", "", {"id": "pole"}),
			_right(c, -b, a - c, {"at": 1})]
		vars.append({"eq": "\\vec{a} = %s，\\vec{b} = %s\n\\vec{c} 是 \\vec{a} 在 \\vec{b} 上的正射影，求 %s" % [_pt(a), _pt(b), cfg.ask],
			"plane": _plane(cfg.x, cfg.y, shapes, {}, {"grid": "none"}),
			"steps": [
				{"kind": "vtap", "name": "竿子", "q": "\\vec{a} − \\vec{c} 是哪一支？點它", "ref": "", "targets": ["pole"], "tag": T_PROJ, "big": true,
				 "why_bad": {"c": "這是 \\vec{c}（影子）。\\vec{a} − \\vec{c} 從 \\vec{c} 的頭指到 \\vec{a} 的頭。",
					"a": "這是 \\vec{a}。\\vec{a} − \\vec{c} 從 \\vec{c} 的頭指到 \\vec{a} 的頭。", "b": "這是 \\vec{b}（地面）。"},
				 "nudge": "\\vec{a} − \\vec{c}：終點減起點，從 \\vec{c} 的頭到 \\vec{a} 的頭。", "line": "\\vec{a} − \\vec{c} 是竿子：和地面 \\vec{b} 垂直"},
				_f("內積", "不用算！", "%s = [0]" % cfg.ask, ["0"], "竿子 ⊥ 地面，%s 也躺在地面上：內積是 0" % ("5\\vec{b}" if String(cfg.ask).contains("5") else "\\vec{b} + 2\\vec{c}"),
					"竿子和地面垂直：內積是多少？", T_PROJ),
			]})
	return {"id": "poletap", "chapter": 2, "type": "forge", "title": "竿子垂直地面",
		"story": "數字很大？先看看那是哪一支箭頭。",
		"insight": "\\vec{a} − \\vec{c}（竿子）永遠和 \\vec{b} 垂直\n和 \\vec{b} 平行的任何向量（5\\vec{b}、\\vec{b} + 2\\vec{c}）跟竿子的內積都是 0。",
		"variants": vars}
