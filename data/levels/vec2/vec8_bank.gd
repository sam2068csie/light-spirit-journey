extends RefCounted
## 平面向量 第八大關「雙線織坊」題庫（下冊 3-3 重點四：二階行列式與克拉瑪法則）
## 設計稿：docs/vec2_v8_design.md。數字都用程式驗算過（tools/vec2/verify_v8.py）。
##
## 引擎見 vec_level.gd（箭頭畫布、在圖上作答），圖層見 vec_board.gd。這一關多用了：
##   數學式的 \det{a}{b}{c}{d}（二階行列式，格子裡不放空格）、vplace 沙盒的 cloth（布：行列式正的金色、負的紫色）、
##   rect（從原點拉出的長方形）、圖層 cloth、curve（y = f(x) 的曲線）。
## 行列式和向量：\vec{a} = (a_{1}, a_{2})、\vec{b} = (b_{1}, b_{2}) 張成的布，行列式寫成 \det{a_{1}}{a_{2}}{b_{1}}{b_{2}}（兩支向量各一列）。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/vec2/vec1_bank.gd")
const B6 := preload("res://data/levels/vec2/vec6_bank.gd")

const T_DET := "vec_det"          # 二階行列式的值和面積
const T_DPR := "vec_detprop"      # 行列式的性質
const T_CRM := "vec_cramer"       # 克拉瑪法則
const T_SOL := "vec_solcount"     # 解的個數


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


static func _poly(pts: Array, c := "dim", extra := {}) -> Dictionary:
	return B1._poly(pts, c, extra)


static func _plane(x: Array, y: Array, shapes: Array, named := {}, extra := {}) -> Dictionary:
	return B1._plane(x, y, shapes, named, extra)


static func _axes(x: Array, y: Array, shapes: Array) -> Dictionary:
	return _plane(x, y, shapes, {}, {"grid": "axes"})


## 直線 ax + by = k
static func _Lk(a: float, b: float, k: float, col := "cyan", s := "", extra := {}) -> Dictionary:
	return B6._L(a, b, -k, col, s, extra)


static func _e(v: float) -> String:
	return B6._e(v)


static func _n(v: float) -> String:
	return B6._num(v)


static func _pt(v: Vector2) -> String:
	return B6._pt(v)


static func _ans(v: float) -> String:
	return B6._ans(v)


## 負數加括號：3 × (−1)
static func _par(v: float) -> String:
	return "(%s)" % _n(v) if v < 0 else _n(v)


## 二階行列式的寫法
static func _D(a, b, c, d) -> String:
	return "\\det{%s}{%s}{%s}{%s}" % [a if a is String else _n(a), b if b is String else _n(b), c if c is String else _n(c), d if d is String else _n(d)]


## 一塊布：o、o + a、o + a + b、o + b（正的金色、負的紫色）
static func _cloth(o: Vector2, a: Vector2, b: Vector2, s := "", extra := {}) -> Dictionary:
	var d := {"k": "cloth", "o": _p(o), "a": _p(a), "b": _p(b)}
	if s != "":
		d["s"] = s
	d.merge(extra, true)
	return d


static func _det2(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x


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
		_spread(), _big(), _ints(), _shear(), _stack(), _peg(), _ljudge(),
		{"id": "speed1", "chapter": 1, "type": "speed", "title": "織布速算", "time": 120.0,
		 "story": "二階行列式的值是多少？",
		 "insight": "\\det{a}{b}{c}{d} = ad − bc\n左上 × 右下，減掉右上 × 左下。",
		 "variants": [{"gen": "det", "count": 8}]},
		_cross(), _three(), _measure(), _swap(), _cjudge(), _count(), _turn(), _never(), _overlap(),
		{"id": "speed2", "chapter": 2, "type": "speed", "title": "交線速算", "time": 120.0,
		 "story": "兩條直線：交一點、平行、還是疊在一起？",
		 "insight": "Δ ≠ 0：恰有一組解\nΔ = 0：係數成比例，常數也成比例是無限多組，不然無解。",
		 "variants": [{"gen": "sol", "count": 8}]},
	]


# ======================= 第一章．二階行列式 =======================

## 1 張開的布（新）
static func _spread() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(3, 1), "b": Vector2(1, 2), "neg": Vector2(2, -1), "zero": Vector2(-3, -1), "x": [-5.5, 7.0], "y": [-1.8, 3.6]},
			{"a": Vector2(2, 3), "b": Vector2(-1, 2), "neg": Vector2(1, -2), "zero": Vector2(-2, -3), "x": [-7.5, 7.5], "y": [-3.6, 5.6]}]:
		var a: Vector2 = cfg.a
		var b: Vector2 = cfg.b
		var D := int(_det2(a, b))
		var dx := "(%s * y - %s * x)" % [_e(a.x), _e(a.y)]
		var shapes := [_cloth(Vector2.ZERO, a, b, "", {"until": 1}), _cloth(Vector2.ZERO, a, b, str(D), {"at": 1, "until": 4, "c": "faint"}),
			_cloth(Vector2.ZERO, a, cfg.neg, "", {"at": 2, "until": 3}),
			_ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"w": 3.5, "ls": -1}), _ar(Vector2.ZERO, b, "pink", "\\vec{b}", {"until": 1}),
			_cloth(Vector2.ZERO, a, cfg.zero, "", {"at": 4}), _ar(Vector2.ZERO, cfg.zero, "gold", "\\vec{b}", {"at": 4})]
		var sb := {"label": "", "cloth": {"o": [0, 0], "a": _p(a)}, "arrow": {"o": [0, 0], "c": "pink", "s": "\\vec{b}"}, "start": _p(b),
			"read": "Δ = {%s}" % dx}
		var s2 := sb.duplicate(true)
		s2["lit"] = "abs(%s + %d) < 0.01" % [dx, D]
		var s4 := sb.duplicate(true)
		s4["lit"] = "abs(%s) < 0.01 and abs(x) + abs(y) > 0.01" % dx
		var tmpl := "[0] × [1] − [2] × %s = [4]" % ("([3])" if b.x < 0 else "[3]")
		vars.append({"eq": "\\vec{a} = %s、\\vec{b} = %s 張成的布\n行列式 %s 的正負代表什麼？" % [_pt(a), _pt(b), _D(a.x, a.y, b.x, b.y)],
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				_f("行列式", "交叉相乘", tmpl, [_ans(a.x), _ans(b.y), _ans(a.y), _ans(b.x), str(D)],
					"%s = %s × %s − %s × %s = %d" % [_D(a.x, a.y, b.x, b.y), _n(a.x), _par(b.y), _n(a.y), _par(b.x), D], "左上 × 右下，減掉右上 × 左下。", T_DET),
				{"kind": "vplace", "name": "翻面", "q": "拖 \\vec{b}，讓 Δ = −%d" % D, "tag": T_DET, "goal": "lit", "ans": _p(cfg.neg), "big": true,
				 "sandbox": s2, "nudge": "把 \\vec{b} 拖到 \\vec{a} 的另一邊，布的大小不變。", "line": "\\vec{b} = %s：Δ = −%d，布翻面了" % [_pt(cfg.neg), D]},
				_c("負號", "Δ 是負的，代表？", ["\\vec{b} 在 \\vec{a} 的順時針那邊", "布的面積是負的", "兩支箭頭平行"], 0,
					"面積是 |Δ|，一樣是 %d：負號只說 \\vec{b} 轉到 \\vec{a} 的哪一邊。" % D, "布一樣大，只是翻過來了。",
					"Δ < 0：\\vec{b} 在 \\vec{a} 的順時針那邊（面積還是 %d）" % D, T_DET),
				{"kind": "vplace", "name": "壓扁", "q": "拖 \\vec{b}，讓 Δ = 0", "tag": T_DET, "goal": "lit", "ans": _p(cfg.zero), "big": true,
				 "sandbox": s4, "nudge": "布張不開的時候：\\vec{b} 和 \\vec{a} 在同一條線上。", "line": "\\vec{b} ∥ \\vec{a}：布壓成一條線，Δ = 0"},
			]})
	return {"id": "kspread", "chapter": 1, "type": "forge", "title": "張開的布",
		"story": "兩支箭頭張開，就是一塊布。",
		"insight": "\\det{a_{1}}{a_{2}}{b_{1}}{b_{2}} = a_{1}b_{2} − a_{2}b_{1}：\\vec{a}、\\vec{b} 張成的布\n正的金色（\\vec{b} 在逆時針那邊）、負的翻面、0 是平行。",
		"variants": vars}


## 2 大數字的布（B44、B45）
static func _big() -> Dictionary:
	var vars := []
	# 變化 A：大數字，拆成 200 加減一點（面積模型：中間的 200 × 200 一樣大，只差邊上的長條）
	var L := 6.0
	var g := [Vector2(0, 0), Vector2(L, 0), Vector2(L, L), Vector2(0, L)]
	var s1 := [_poly(g, "faint", {"dash": true, "at": 1}), _poly([Vector2(0, 0), Vector2(L - 0.4, 0), Vector2(L - 0.4, L - 1.0), Vector2(0, L - 1.0)], "dim", {"fill": "dim", "alpha": 0.25, "at": 1}),
		_poly([Vector2(L - 0.4, 0), Vector2(L, 0), Vector2(L, L), Vector2(L - 0.4, L)], "violet", {"fill": "violet", "alpha": 0.35, "at": 1}),
		_poly([Vector2(0, L - 1.0), Vector2(L - 0.4, L - 1.0), Vector2(L - 0.4, L), Vector2(0, L)], "violet", {"fill": "violet", "alpha": 0.35, "at": 1}),
		_tag(Vector2(L / 2.0, 0), "198", "text", {"at": 1, "off": [-12, 18]}), _tag(Vector2(0, L / 2.0), "195", "text", {"at": 1, "off": [-34, 4]})]
	var o2 := Vector2(9, 0)
	s1 += [_poly([o2, o2 + Vector2(L, 0), o2 + Vector2(L, L), o2 + Vector2(0, L)], "dim", {"fill": "dim", "alpha": 0.25, "at": 1}),
		_poly([o2 + Vector2(L, 0), o2 + Vector2(L + 1.0, 0), o2 + Vector2(L + 1.0, L + 0.4), o2 + Vector2(L, L + 0.4)], "gold", {"fill": "gold", "alpha": 0.35, "at": 1}),
		_poly([o2 + Vector2(0, L), o2 + Vector2(L, L), o2 + Vector2(L, L + 0.4), o2 + Vector2(0, L + 0.4)], "gold", {"fill": "gold", "alpha": 0.35, "at": 1}),
		_tag(o2 + Vector2(L / 2.0, 0), "205", "text", {"at": 1, "off": [-12, 18]}), _tag(o2 + Vector2(0, L / 2.0), "202", "text", {"at": 1, "off": [-34, 4]}),
		_tag(Vector2(L / 2.0, L / 2.0 - 0.5), "200^{2}", "dim", {"at": 1, "off": [-14, 4]}), _tag(o2 + Vector2(L / 2.0, L / 2.0), "200^{2}", "dim", {"at": 1, "off": [-14, 4]})]
	vars.append({"eq": "求 %s 的值" % _D(198, 205, 202, 195), "plane": _plane([-2.0, 18.0], [-1.0, 7.4], s1),
		"steps": [
			_f("拆開", "寫成 200 加減一點", "(200 − [0])(200 − [1]) − (200 + [2])(200 + [3])", ["2", "5", "5", "2"],
				"198 × 195 − 205 × 202 = (200 − 2)(200 − 5) − (200 + 5)(200 + 2)", "198 = 200 − 2，195 = 200 − 5……", T_DET),
			_f("消掉", "200^{2} 和 10 都消掉", "行列式 = [0]", ["-2800"], "40000 − 1400 + 10 − (40000 + 1400 + 10) = −2800",
				"−200 × 7 − 200 × 7。", T_DET),
		]})
	vars[0].steps[0]["alts"] = [["5", "2", "5", "2"], ["2", "5", "2", "5"], ["5", "2", "2", "5"]]
	# 變化 B：根號（平方差）
	vars.append({"eq": "求 %s 的值" % _D("3 + √{2}", "2√{2}", "√{2}", "3 − √{2}"),
		"steps": [
			_f("左上 × 右下", "平方差", "(3 + √{2})(3 − √{2}) = [0]", ["7"], "(3 + √{2})(3 − √{2}) = 9 − 2 = 7", "(a + b)(a − b) = a^{2} − b^{2}。", T_DET),
			_f("右上 × 左下", "根號相乘", "2√{2} × √{2} = [0]", ["4"], "2√{2} × √{2} = 2 × 2 = 4", "√{2} × √{2} = 2。", T_DET),
			_f("行列式", "相減", "行列式 = [0]", ["3"], "7 − 4 = 3", "左上 × 右下 − 右上 × 左下。", T_DET),
		]})
	return {"id": "kbig", "chapter": 1, "type": "forge", "title": "大數字的布",
		"story": "數字很大的布，先拆開再算。",
		"insight": "大數字：寫成整百加減一點，200^{2} 會消掉\n根號：先找平方差 (a + b)(a − b) = a^{2} − b^{2}。",
		"variants": vars}


## 3 整數的織法（B46）
static func _ints() -> Dictionary:
	var vars := []
	for cfg in [{"m": [3, 4], "v": 6, "ab": 6, "pts": [Vector2(1, 6), Vector2(2, 3), Vector2(3, 2), Vector2(6, 1)], "start": [4, 4], "x": [-1.0, 14.0], "y": [-0.8, 7.0]},
			{"m": [2, 9], "v": 9, "ab": 9, "pts": [Vector2(1, 9), Vector2(3, 3), Vector2(9, 1)], "start": [5, 5], "x": [-1.0, 20.0], "y": [-0.8, 9.8]}]:
		var m: Array = cfg.m
		var ab := int(cfg.ab)
		var pts: Array = cfg.pts
		var n := pts.size()
		var shapes := [{"k": "curve", "f": "%d / x" % ab, "x0": 0.3, "x1": float(cfg.x[1]), "c": "gold", "at": 2}]
		for q in pts:
			shapes.append(_dot(q, "", "gold", {"at": 2}))
		var tr := pts.map(func(q): return _p(q))
		var neg := pts.map(func(q): return _pt(-q))
		vars.append({"eq": "a、b 是整數，%s = %d\n(a, b) 有幾組？" % [_D(m[0], "a", "b", m[1]), cfg.v], "plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("展開", "交叉相乘", "[0] − ab = %d ⇒ ab = [1]" % cfg.v, [str(m[0] * m[1]), str(ab)], "%d × %d − ab = %d ⇒ ab = %d" % [m[0], m[1], cfg.v, ab],
					"左上 × 右下是 %d × %d。" % [m[0], m[1]], T_DET),
				{"kind": "vplace", "name": "找格子點", "q": "點出 ab = %d 的正整數點" % ab, "tag": T_DET, "goal": "trace", "need": n, "ans": tr[0], "trace_ans": tr, "big": true,
				 "sandbox": {"label": "(a, b)", "rect": true, "trace": true, "start": cfg.start,
					"lit": "x > 0 and y > 0 and abs(x * y - %d) < 0.01" % ab, "read": "ab = {x * y}"},
				 "nudge": "長方形的面積要剛好是 %d：寬 × 高 = %d。" % [ab, ab], "line": "第一象限有 %d 個：%s" % [n, "、".join(pts.map(func(q): return _pt(q)))]},
				_f("負的也行", "一共幾組", "一共 [0] 組", [str(2 * n)], "a、b 都是負的也可以（%s…）：%d × 2 = %d" % [neg[0], n, 2 * n],
					"負 × 負也是正的。", T_DET),
			]})
	return {"id": "kints", "chapter": 1, "type": "forge", "title": "整數的織法",
		"story": "行列式是固定的數，整數的 a、b 有幾種織法？",
		"insight": "先展開成 ab = k，再找 k 的因數\n正的、負的各一半（ab 的點都在反比的曲線上）。",
		"variants": vars}


## 4 拉長、推斜的布（B42、B43）
static func _shear() -> Dictionary:
	var vars := []
	for cfg in [{"u": Vector2(2, 1), "v": Vector2(-1, 2), "x": [-5.5, 7.0], "y": [-1.0, 4.6]},
			{"u": Vector2(2, 1), "v": Vector2(0, 2), "x": [-5.0, 7.5], "y": [-0.8, 5.2]}]:
		var u: Vector2 = cfg.u
		var v: Vector2 = cfg.v
		var D := int(_det2(u, v))
		var vb := ["%s + k * %s" % [_e(v.x), _e(u.x)], "%s + k * %s" % [_e(v.y), _e(u.y)]]
		var lines := [{"k": "cloth", "o": [0, 0], "a": _p(u), "b": vb}, {"k": "arrow", "a": [0, 0], "b": vb, "c": "pink", "s": "", "ls": -1}]
		var slide := {"kind": "slide", "name": "推斜", "q": "拖 k，把布推斜", "tag": T_DPR, "free": true,
			"params": [{"n": "k", "min": -1, "max": 1, "step": 0.25, "v": 0}], "lines": lines,
			"eq": "k = {k}：Δ = {%s * (%s + k * %s) - %s * (%s + k * %s)}" % [_e(u.x), _e(v.y), _e(u.y), _e(u.y), _e(v.x), _e(u.x)],
			"line": "推斜：底和高都不變，布一樣大", "nudge": "拉動滑桿，看讀數有沒有變。"}
		var ch := _c("性質", "加上另一列的 k 倍", ["行列式不變", "變成 k 倍", "變成 0"], 0, "推斜的布底一樣、高一樣。",
			"看剛剛的讀數。", "一列加上另一列的倍數，行列式不變", T_DPR)
		var shapes := [_ar(Vector2.ZERO, u, "cyan", "(a, b)", {"w": 3.5, "ls": -1}), _ar(Vector2.ZERO, v, "pink", "(c, d)", {"at": 1})]
		if vars.is_empty():
			shapes += [_cloth(Vector2.ZERO, u, v, str(D), {"at": 1})]
			vars.append({"eq": "%s = 5\n求 %s" % [_D("a", "b", "c", "d"), _D("2a + c", "2b + d", "a − 3c", "b − 3d")], "plane": _plane(cfg.x, cfg.y, shapes),
				"steps": [slide, ch,
					_f("倍數", "兩列都換掉", "新的 = ([0] × [1] − [2] × [3]) × 5", ["2", "-3", "1", "1"],
						"(2 × (−3) − 1 × 1) × 5：係數的行列式乘上原本的", "兩列各是 (a, b)、(c, d) 的幾倍相加？係數排成行列式。", T_DPR),
					_f("答案", "乘起來", "答案 [0]", ["-35"], "−7 × 5 = −35：布翻面、變成 7 倍大", "−7 × 5。", T_DPR),
				]})
		else:
			shapes += [_cloth(Vector2.ZERO, u, v, str(D), {"at": 1})]
			vars.append({"eq": "Δ = %s，%s\n+ %s = 20，求 Δ" % [_D("a", "b", "c", "d"), _D("−3a + b", "4a − b", "−3c + d", "4c − d"), _D("3d", "6c", "b", "2a")],
				"plane": _plane(cfg.x, cfg.y, shapes),
				"steps": [slide, ch,
					_f("第一個", "兩行都是組合", "第一個 = [0]Δ", ["-1"], "直的兩行也一樣：(−3) × (−1) − 4 × 1 = −1，第一個 = −Δ",
						"兩行各是 (a, c)、(b, d) 的幾倍相加？", T_DPR),
					_f("第二個", "提出倍數", "第二個 = [0]Δ", ["6"], "3d × 2a − 6c × b = 6(ad − bc) = 6Δ", "直接展開。", T_DPR),
					_f("Δ", "加起來", "Δ = [0]", ["4"], "−Δ + 6Δ = 5Δ = 20 ⇒ Δ = 4", "5Δ = 20。", T_DPR),
				]})
	return {"id": "kshear", "chapter": 1, "type": "forge", "title": "拉長、推斜的布",
		"story": "布的一邊拉長、推斜，面積怎麼變？",
		"insight": "一列（行）乘 k：行列式乘 k，加上另一列的倍數：不變\n兩列都換成組合：乘上係數排成的行列式。",
		"variants": vars}


## 5 疊起來的布（B61）
static func _stack() -> Dictionary:
	var vars := []
	# 第 1 組：c = 2a + 5b，c、b 的布 6
	var a := Vector2(3, 0)
	var b := Vector2(1, 1)
	var c := a * 2 + b * 5
	var s1 := [_ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"ls": -1}), _ar(Vector2.ZERO, b, "pink", "\\vec{b}"), _ar(Vector2.ZERO, c, "gold", "\\vec{c}"),
		_cloth(Vector2.ZERO, c, b, "6", {"until": 1}), _cloth(Vector2.ZERO, a * 2, b, "", {"at": 1, "c": "lime"}),
		_poly([a, a + b], "lime", {"at": 3, "dash": true}), _tag(a * 0.5 + b * 0.5, "3", "lime", {"at": 3, "off": [-4, 4]}), _tag(a * 1.5 + b * 0.5, "3", "lime", {"at": 3, "off": [-4, 4]})]
	vars.append({"eq": "\\vec{c} = 2\\vec{a} + 5\\vec{b}，\\vec{c}、\\vec{b} 的布面積是 6\n求 \\vec{a}、\\vec{b} 的布面積", "plane": _plane([-2.0, 12.5], [-1.0, 6.2], s1),
		"steps": [
			_f("拆開", "第一列拆成兩塊", "det(\\vec{c}, \\vec{b}) = [0]det(\\vec{a}, \\vec{b}) + [1]det(\\vec{b}, \\vec{b})", ["2", "5"],
				"det(2\\vec{a} + 5\\vec{b}, \\vec{b}) = 2det(\\vec{a}, \\vec{b}) + 5det(\\vec{b}, \\vec{b})", "\\vec{c} 換成 2\\vec{a} + 5\\vec{b}，一塊一塊拆。", T_DPR),
			_f("張不開", "自己和自己", "det(\\vec{b}, \\vec{b}) = [0]", ["0"], "\\vec{b}、\\vec{b} 平行：布壓成一條線，det = 0", "兩支一樣的箭頭張得開嗎？", T_DPR),
			_f("面積", "除以 2", "\\vec{a}、\\vec{b} 的布 [0]", ["3"], "2 × det(\\vec{a}, \\vec{b}) 的面積是 6 ⇒ 3", "6 = 2 × ?", T_DPR),
		]})
	# 第 2 組：c = 3a − 2b，a、c 的布 8
	a = Vector2(2, 0)
	b = Vector2(1, 2)
	c = a * 3 - b * 2
	var s2 := [_ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"ls": -1}), _ar(Vector2.ZERO, b, "pink", "\\vec{b}"), _ar(Vector2.ZERO, c, "gold", "\\vec{c}"),
		_cloth(Vector2.ZERO, a, c, "8", {"until": 1}), _cloth(Vector2.ZERO, a, b * -2, "", {"at": 1, "c": "lime"}),
		_cloth(Vector2.ZERO, a, b, "4", {"at": 3})]
	vars.append({"eq": "\\vec{c} = 3\\vec{a} − 2\\vec{b}，\\vec{a}、\\vec{c} 的布面積是 8\n求 \\vec{a}、\\vec{b} 的布面積", "plane": _plane([-6.0, 8.0], [-4.8, 2.6], s2),
		"steps": [
			_f("拆開", "第二列拆成兩塊", "det(\\vec{a}, \\vec{c}) = [0]det(\\vec{a}, \\vec{a}) + [1]det(\\vec{a}, \\vec{b})", ["3", "-2"],
				"det(\\vec{a}, 3\\vec{a} − 2\\vec{b}) = 3det(\\vec{a}, \\vec{a}) − 2det(\\vec{a}, \\vec{b})", "\\vec{c} 換成 3\\vec{a} − 2\\vec{b}，一塊一塊拆。", T_DPR),
			_f("張不開", "自己和自己", "det(\\vec{a}, \\vec{a}) = [0]", ["0"], "\\vec{a}、\\vec{a} 平行：布壓成一條線，det = 0", "兩支一樣的箭頭張得開嗎？", T_DPR),
			_f("面積", "除以 2", "\\vec{a}、\\vec{b} 的布 [0]", ["4"], "|−2| × det(\\vec{a}, \\vec{b}) 的面積是 8 ⇒ 4", "8 = 2 × ?", T_DPR),
		]})
	return {"id": "kstack", "chapter": 1, "type": "forge", "title": "疊起來的布",
		"story": "一塊布是另外兩支箭頭組合出來的，面積差幾倍？",
		"insight": "det(p\\vec{a} + q\\vec{b}, \\vec{b}) = p det(\\vec{a}, \\vec{b})\n和自己平行的那一塊張不開（是 0）。",
		"variants": vars}


## 6 第三根釘子（B47）
static func _peg() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(1, 1), "B": Vector2(3, 2), "cy": 0.0, "ks": [5, -7], "start": [0, 0], "co": [3, 1, 1, -1], "big": 24,
				"ac": ["1", "-1"], "acs": "(k − 1, −1)", "acd": ["k − 1", "−1"], "comb": "3\\vec{AB} + \\vec{AC}、\\vec{AB} − \\vec{AC}", "x": [-9.0, 12.0], "y": [-3.0, 5.0]},
			{"A": Vector2(3, 1), "B": Vector2(0, 2), "cy": 2.0, "ks": [6, -6], "start": [1, 2], "co": [2, 1, 1, 2], "big": 18,
				"ac": ["3", "1"], "acs": "(k − 3, 1)", "acd": ["k − 3", "1"], "comb": "2\\vec{AB} + \\vec{AC}、\\vec{AB} + 2\\vec{AC}", "x": [-9.0, 9.0], "y": [-1.6, 7.6]}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var ab := B - A
		var cy := float(cfg.cy)
		var dx := "(%s * (y - %s) - %s * (x - %s))" % [_e(ab.x), _e(A.y), _e(ab.y), _e(A.x)]
		var C1 := Vector2(cfg.ks[0], cy)
		var C2 := Vector2(cfg.ks[1], cy)
		var co: Array = cfg.co
		var ac1 := C1 - A
		var p: Vector2 = ab * co[0] + ac1 * co[1]
		var q: Vector2 = ab * co[2] + ac1 * co[3]
		var cdet := int(co[0] * co[3] - co[1] * co[2])
		var shapes := [_Lk(0, 1, cy, "faint", "", {"dash": true}), _ar(A, B, "cyan", "", {"at": 1}),
			_poly([A, B, C1], "gold", {"fill": "gold", "alpha": 0.2, "at": 3}), _poly([A, B, C2], "violet", {"fill": "violet", "alpha": 0.2, "at": 3}),
			_cloth(A, p, q, str(cfg.big), {"at": 4})]
		shapes += B1._dots({"A": A, "B": B}, "text", {"A": [-16, 16], "B": [8, -8]})
		shapes += [_dot(C1, "C", "gold", {"at": 3, "off": [6, 16]}), _dot(C2, "C", "violet", {"at": 3, "off": [6, 16]})]
		vars.append({"eq": "A%s、B%s、C(k, %s)，△ABC = 3，求 k\n和 %s 張成的平行四邊形" % [_pt(A), _pt(B), _n(cy), cfg.comb],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "釘釘子", "q": "拖 C，找面積 3 的位置", "tag": T_DPR, "goal": "trace", "need": 2, "ans": _p(C1),
				 "trace_ans": [_p(C1), _p(C2)], "big": true,
				 "sandbox": {"label": "C", "on": {"o": [0, cy], "d": [1, 0], "step": 1}, "sail": [_p(A), _p(B)], "trace": true, "start": cfg.start,
					"lit": "abs(abs(%s) - 6) < 0.01" % dx, "read": "△ = {abs(%s) / 2}" % dx},
				 "nudge": "\\ol{AB} 的兩邊各有一個：一個正面、一個翻面。", "line": "C 有兩個位置，在 \\ol{AB} 的兩邊"},
				_f("兩支箭頭", "從 A 出發", "\\vec{AB} = ([0], [1])、\\vec{AC} = (k − [2], [3])", [_ans(ab.x), _ans(ab.y), cfg.ac[0], cfg.ac[1]],
					"\\vec{AB} = %s、\\vec{AC} = %s" % [_pt(ab), cfg.acs], "終點減起點。", T_DPR),
				_f("k", "\\frac{1}{2}|行列式| = 3", "k = [0] 或 [1]", [str(cfg.ks[0]), str(cfg.ks[1])],
					"|%s| = 6 ⇒ k = %s 或 %s" % [_D(_n(ab.x), _n(ab.y), cfg.acd[0], cfg.acd[1]), _n(cfg.ks[0]), _n(cfg.ks[1])],
					"行列式是 6 或 −6。", T_DPR, "set"),
				_f("平行四邊形", "係數的行列式", "%s = [0]，面積 = [1]" % _D(co[0], co[1], co[2], co[3]), [str(cdet), str(cfg.big)],
					"|%d| × |det(\\vec{AB}, \\vec{AC})| = %d × 6 = %d" % [cdet, absi(cdet), cfg.big], "\\vec{AB}、\\vec{AC} 的布是 6。", T_DPR),
			]})
	return {"id": "kpeg", "chapter": 1, "type": "forge", "title": "第三根釘子",
		"story": "兩根釘子釘好了，第三根釘在哪裡，三角形才剛好那麼大？",
		"insight": "△ABC = \\frac{1}{2}|det(\\vec{AB}, \\vec{AC})|：行列式可正可負，所以 C 有兩個\n組合向量的布 = |係數的行列式| × 原本的布。",
		"variants": vars}


## 7 織布機的審判（B48、B49）
static func _ljudge() -> Dictionary:
	var vars := []
	var u := Vector2(2, 1)
	var v := Vector2(-1, 1)
	var s1 := [_cloth(Vector2.ZERO, u, v, "3", {"c": "faint"}),
		_cloth(Vector2.ZERO, Vector2(2, 3), Vector2(-1, 3), "9", {"at": 1, "until": 2}),
		_cloth(Vector2.ZERO, Vector2(4, 1), Vector2(1, 1), "3", {"at": 2, "until": 3}),
		_cloth(Vector2.ZERO, Vector2(4, 2), Vector2(-2, 2), "12", {"at": 3, "until": 4}),
		_cloth(Vector2.ZERO, Vector2(1, 2), Vector2(1, -1), "−3", {"at": 4})]
	vars.append({"eq": "下面哪些一定成立？", "plane": _plane([-6.0, 7.0], [-1.6, 4.6], s1),
		"steps": [
			_j("審判一", "%s = 3%s" % [_D("a", "3b", "c", "3d"), _D("a", "b", "c", "d")], true, "第二行乘 3：行列式乘 3。", "%s = 3%s ○" % [_D("a", "3b", "c", "3d"), _D("a", "b", "c", "d")], T_DPR),
			_j("審判二", "%s = %s" % [_D("a + 2b", "b", "c + 2d", "d"), _D("a", "b", "c", "d")], true, "第一行加上第二行的 2 倍：不變。", "加上另一行的倍數不變 ○", T_DPR),
			_j("審判三", "2%s = %s" % [_D("a", "b", "c", "d"), _D("2a", "2b", "2c", "2d")], false, "兩列都乘 2，是 4 倍：右邊 = 4%s。" % _D("a", "b", "c", "d"), "四個都乘 2 是 4 倍 ✕", T_DPR),
			_j("審判四", "%s = %s" % [_D("b", "a", "d", "c"), _D("a", "b", "c", "d")], false, "兩行交換變號：bc − ad。", "兩行交換變號 ✕", T_DPR),
		]})
	var O := Vector2.ZERO
	var s2 := [_poly([O, Vector2(1, 0), Vector2(0, 3)], "gold", {"fill": "gold", "alpha": 0.22, "at": 4}),
		_poly([O, Vector2(1, 0), Vector2(0, -3)], "violet", {"fill": "violet", "alpha": 0.22, "at": 4}),
		_dot(Vector2(1, 0), "X", "text", {"at": 4, "off": [8, 16]}), _dot(Vector2(0, -3), "Y", "violet", {"at": 4, "off": [8, -2]}),
		_dot(Vector2(0, 3), "Y", "gold", {"at": 4, "off": [8, 4]}), _dot(O, "O", "text", {"at": 4, "off": [-16, 16]})]
	vars.append({"eq": "下面哪些一定成立？", "plane": _plane([-6.0, 6.0], [-3.6, 3.6], s2),
		"steps": [
			_j("審判一", "%s = −2127" % _D(108, 2019, 109, 2018), true, "108 × 2018 − 2019 × 109 = 217944 − 220071 = −2127。", "%s = −2127 ○" % _D(108, 2019, 109, 2018), T_DPR),
			_j("審判二", "%s = 3 ⇒ %s = 9" % [_D("a", "b", "c", "d"), _D("a^{2}", "b^{2}", "c^{2}", "d^{2}")], false,
				"a = b = 1、c = −1、d = 2：行列式 3，平方的是 4 − 1 = 3。", "平方之後不一定是 9 ✕", T_DPR),
			_j("審判三", "%s = 3 ⇒ %s = 30" % [_D("a", "b", "c", "d"), _D("2a", "2c", "5b", "5d")], true, "列和行對調不變，再乘 2、乘 5。", "%s = 30 ○" % _D("2a", "2c", "5b", "5d"), T_DPR),
			_j("審判四", "△OXY = \\frac{3}{2} ⇒ %s = 3（X(a, b)、Y(c, d)）" % _D("a", "b", "c", "d"), false,
				"X(1, 0)、Y(0, −3)：面積 \\frac{3}{2}，行列式是 −3。", "面積只知道 |Δ| = 3，Δ 也可能是 −3 ✕", T_DPR),
		]})
	return {"id": "kljudge", "chapter": 1, "type": "forge", "title": "織布機的審判",
		"story": "行列式的性質，一張一張檢查。",
		"insight": "一列（行）乘 k 倍：乘 k，四個都乘 k：乘 k^{2}\n兩列（行）交換變號，列和行對調不變。",
		"variants": vars}


# ======================= 第二章．克拉瑪法則 =======================

## 9 交叉的線（B52）
static func _cross() -> Dictionary:
	var vars := []
	var s1 := [_Lk(2, 1, 7, "cyan", "2x + y = 7"), _Lk(1, -3, -7, "pink", "x − 3y = −7"), _dot(Vector2(2, 3), "", "gold", {"at": 3})]
	vars.append({"eq": "2x + y = 7、x − 3y = −7\n解聯立方程式", "plane": _axes([-8.0, 8.0], [-1.6, 6.0], s1),
		"steps": [
			_f("Δ", "係數的行列式", "Δ = [0]", ["-7"], "Δ = %s = −6 − 1 = −7" % _D(2, 1, 1, -3), "x、y 的係數排成行列式。", T_CRM),
			_f("Δ_{x}、Δ_{y}", "換掉一行", "Δ_{x} = [0]、Δ_{y} = [1]", ["-14", "-21"], "Δ_{x} = %s = −14、Δ_{y} = %s = −21" % [_D(7, 1, -7, -3), _D(2, 7, 1, -7)],
				"Δ_{x}：x 那一行換成常數，Δ_{y}：y 那一行換成常數。", T_CRM),
			_f("解", "相除", "(x, y) = ([0], [1])", ["2", "3"], "x = \\frac{−14}{−7} = 2、y = \\frac{−21}{−7} = 3", "x = \\frac{Δ_{x}}{Δ}、y = \\frac{Δ_{y}}{Δ}。", T_CRM),
		]})
	var s2 := [_Lk(2023, -2024, 2025, "cyan"), _Lk(2026, -2027, 2028, "pink"), _dot(Vector2(-1, -2), "", "gold", {"at": 3})]
	vars.append({"eq": "2023x − 2024y = 2025\n2026x − 2027y = 2028，解聯立方程式", "plane": _axes([-6.0, 5.0], [-4.6, 1.4], s2),
		"steps": [
			_f("Δ", "都用 2025 表示", "Δ = −(2025^{2} − [0]) + (2025^{2} − [1]) = [2]", ["4", "1", "3"],
				"Δ = −(2025^{2} − 4) + (2025^{2} − 1) = 3", "2023 × 2027 = (2025 − 2)(2025 + 2)。", T_CRM),
			_f("Δ_{x}、Δ_{y}", "一樣拆開", "Δ_{x} = [0]、Δ_{y} = [1]", ["-3", "-6"],
				"Δ_{x} = −3、Δ_{y} = −6（一樣用 2025 拆開）", "Δ_{x}：x 那一行換成常數，一樣用 2025 拆開。", T_CRM),
			_f("解", "相除", "(x, y) = ([0], [1])", ["-1", "-2"], "x = \\frac{−3}{3} = −1、y = \\frac{−6}{3} = −2（兩條線幾乎平行，Δ 很小）",
				"x = \\frac{Δ_{x}}{Δ}。", T_CRM),
		]})
	return {"id": "kcross", "chapter": 2, "type": "forge", "title": "交叉的線",
		"story": "兩條線交叉的地方，就是聯立方程式的解。",
		"insight": "Δ = \\det{a_{1}}{b_{1}}{a_{2}}{b_{2}}，Δ_{x}、Δ_{y} 把那一行換成常數\nΔ ≠ 0：x = \\frac{Δ_{x}}{Δ}、y = \\frac{Δ_{y}}{Δ}。",
		"variants": vars}


## 10 只知道三塊布（B53）
static func _three() -> Dictionary:
	var vars := []
	vars.append({"eq": "%s = 3、%s = 6、%s = −9\n解 ax + 2by + 3c = 0、dx + 2ey + 3f = 0" % [_D("a", "b", "d", "e"), _D("a", "c", "d", "f"), _D("b", "c", "e", "f")],
		"steps": [
			_f("移項", "常數移到右邊", "ax + 2by = [0]c", ["-3"], "ax + 2by = −3c、dx + 2ey = −3f", "3c 移過去變號。", T_CRM),
			_f("Δ", "係數的行列式", "Δ = %s = [0]" % _D("a", "2b", "d", "2e"), ["6"], "Δ = 2 × %s = 6" % _D("a", "b", "d", "e"), "第二行提出 2。", T_CRM),
			_f("解", "克拉瑪", "x = [0]、y = [1]", ["-9", "-3"],
				"Δ_{x} = %s = −6 × 9 = −54、Δ_{y} = %s = −18" % [_D("−3c", "2b", "−3f", "2e"), _D("a", "−3c", "d", "−3f")],
				"%s = −%s = 9。" % [_D("c", "b", "f", "e"), _D("b", "c", "e", "f")], T_CRM),
		]})
	vars.append({"eq": "%s = −2、%s = 4、%s = 6\n解 2ax + by + 2c = 0、2dx + ey + 2f = 0" % [_D("a", "b", "d", "e"), _D("a", "c", "d", "f"), _D("b", "c", "e", "f")],
		"steps": [
			_f("移項", "常數移到右邊", "2ax + by = [0]c", ["-2"], "2ax + by = −2c、2dx + ey = −2f", "2c 移過去變號。", T_CRM),
			_f("Δ", "係數的行列式", "Δ = %s = [0]" % _D("2a", "b", "2d", "e"), ["-4"], "Δ = 2 × %s = −4" % _D("a", "b", "d", "e"), "第一行提出 2。", T_CRM),
			_f("解", "克拉瑪", "x = [0]、y = [1]", ["-3", "4"],
				"Δ_{x} = %s = 12、Δ_{y} = %s = −16" % [_D("−2c", "b", "−2f", "e"), _D("2a", "−2c", "2d", "−2f")], "%s = −%s = −6。" % [_D("c", "b", "f", "e"), _D("b", "c", "e", "f")], T_CRM),
		]})
	return {"id": "kthree", "chapter": 2, "type": "forge", "title": "只知道三塊布",
		"story": "不知道係數，只知道三個行列式，也解得出來。",
		"insight": "先整理成 ax + by = c 的樣子，提出倍數\n兩行交換變號：\\det{c}{b}{f}{e} = −\\det{b}{c}{e}{f}。",
		"variants": vars}


## 11 用布量係數（B60）
static func _measure() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(2, 0), "b": Vector2(1, 1), "c": Vector2(5.5, 2.5), "ar": [2, 3, 5], "sg": 0, "xy": ["3/2", "5/2"], "xyv": [1.5, 2.5],
				"x": [-1.5, 8.5], "y": [-1.0, 3.6]},
			{"a": Vector2(2, 0), "b": Vector2(1, 2), "c": Vector2(0.5, 3), "ar": [4, 2, 6], "sg": 1, "xy": ["-1/2", "3/2"], "xyv": [-0.5, 1.5],
				"x": [-4.5, 5.5], "y": [-0.8, 4.0]}]:
		var a: Vector2 = cfg.a
		var b: Vector2 = cfg.b
		var c: Vector2 = cfg.c
		var ar: Array = cfg.ar
		var shapes := [_cloth(Vector2.ZERO, a, b, str(ar[0]), {"until": 2}),
			{"k": "skew", "o": [0, 0], "a": _p(a), "b": _p(b), "i": [-2, 4], "j": [-1, 4], "div": 1, "c": "cyan", "at": 1},
			_cloth(Vector2.ZERO, c, b, str(ar[1]), {"at": 2, "until": 3}), _cloth(Vector2.ZERO, a, c, str(ar[2]), {"at": 3}),
			_ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"ls": -1}), _ar(Vector2.ZERO, b, "pink", "\\vec{b}"), _ar(Vector2.ZERO, c, "gold", "\\vec{c}")]
		var where := "\\vec{c} 在 \\vec{a}、\\vec{b} 中間" if int(cfg.sg) == 0 else "\\vec{c} 在 \\vec{b} 的外側"
		vars.append({"eq": "\\vec{a}、\\vec{b} 的布面積 %d，\\vec{b}、\\vec{c} 的是 %d\n\\vec{a}、\\vec{c} 的是 %d，\\vec{c} = x\\vec{a} + y\\vec{b}，求 x、y" % ar,
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				_c("正負", "看圖：x、y 的正負", ["x 正、y 正", "x 負、y 正", "x 正、y 負", "x 負、y 負"], int(cfg.sg),
					"%s：沿 \\vec{a} 走%s、沿 \\vec{b} 走正的。" % [where, "正的" if int(cfg.sg) == 0 else "負的"], "\\vec{c} 落在斜格子的哪一區？",
					"%s：x %s、y 正" % [where, "正" if int(cfg.sg) == 0 else "負"], T_CRM),
				_f("x", "布的比", "x = [0]", [cfg.xy[0]], "|x| = \\frac{\\vec{c}、\\vec{b} 的布}{\\vec{a}、\\vec{b} 的布} = \\frac{%d}{%d}：x = %s" % [ar[1], ar[0], B6._fv(cfg.xyv[0])],
					"det(\\vec{c}, \\vec{b}) = x det(\\vec{a}, \\vec{b})：底一樣是 \\vec{b}，高是 x 倍。", T_CRM),
				_f("y", "布的比", "y = [0]", [cfg.xy[1]], "|y| = \\frac{\\vec{a}、\\vec{c} 的布}{\\vec{a}、\\vec{b} 的布} = \\frac{%d}{%d}：y = %s" % [ar[2], ar[0], B6._fv(cfg.xyv[1])],
					"det(\\vec{a}, \\vec{c}) = y det(\\vec{a}, \\vec{b})。", T_CRM),
			]})
	return {"id": "kmeasure", "chapter": 2, "type": "forge", "title": "用布量係數",
		"story": "只量得到布的面積，也算得出 \\vec{c} 在斜格子上的地址。",
		"insight": "\\vec{c} = x\\vec{a} + y\\vec{b}：x = \\frac{det(\\vec{c}, \\vec{b})}{det(\\vec{a}, \\vec{b})}、y = \\frac{det(\\vec{a}, \\vec{c})}{det(\\vec{a}, \\vec{b})}\n就是克拉瑪法則，正負看圖。",
		"variants": vars}


## 12 換一組線（B55、B56）
static func _swap() -> Dictionary:
	var vars := []
	var u := Vector2(2, 1)
	var v := Vector2(1, 3)
	for cfg in [{"s": Vector2(2, -1), "eq2": "3b_{1}x + 4a_{1}y = c_{1}\n3b_{2}x + 4a_{2}y = c_{2} 的解",
				"t2": "[0]y\\vec{u} + [1]x\\vec{v} = \\vec{w}", "a2": ["4", "3"], "l2": "x(3\\vec{v}) + y(4\\vec{u}) = \\vec{w} = 2\\vec{u} − \\vec{v}", "xy": ["-1/3", "1/2"],
				"l3": "4y = 2、3x = −1 ⇒ (x, y) = (−\\frac{1}{3}, \\frac{1}{2})", "x": [-5.0, 7.0], "y": [-2.6, 4.2]},
			{"s": Vector2(2, 1), "eq2": "2b_{1}x + (a_{1} − b_{1})y = c_{1}\n2b_{2}x + (a_{2} − b_{2})y = c_{2} 的解",
				"t2": "y = [0]、2x − y = [1]", "a2": ["2", "1"], "l2": "x(2\\vec{v}) + y(\\vec{u} − \\vec{v}) = y\\vec{u} + (2x − y)\\vec{v} = 2\\vec{u} + \\vec{v}", "xy": ["3/2", "2"],
				"l3": "y = 2、2x − 2 = 1 ⇒ (x, y) = (\\frac{3}{2}, 2)", "x": [-6.0, 9.0], "y": [-1.6, 5.8]}]:
		var s: Vector2 = cfg.s
		var w := u * s.x + v * s.y
		var shapes := [{"k": "skew", "o": [0, 0], "a": _p(u), "b": _p(v), "i": [-1, 3], "j": [-1, 2], "div": 1, "c": "cyan"},
			_ar(Vector2.ZERO, u, "cyan", "\\vec{u}", {"ls": -1}), _ar(Vector2.ZERO, v, "pink", "\\vec{v}"), _ar(Vector2.ZERO, w, "gold", "\\vec{w}", {"at": 1})]
		vars.append({"eq": "a_{1}x + b_{1}y = c_{1}、a_{2}x + b_{2}y = c_{2} 的解是 %s\n求 %s" % [_pt(s), cfg.eq2],
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				_f("寫成箭頭", "\\vec{w} 在斜格子上", "\\vec{w} = [0]\\vec{u} + [1]\\vec{v}", [_ans(s.x), _ans(s.y)],
					"\\vec{u} = (a_{1}, a_{2})、\\vec{v} = (b_{1}, b_{2})、\\vec{w} = (c_{1}, c_{2})：\\vec{w} = %s\\vec{u} %s \\vec{v}" % [_n(s.x), "+" if s.y > 0 else "−"],
					"x\\vec{u} + y\\vec{v} = \\vec{w}，x、y 就是解。", T_CRM),
				_f("新的方程組", "也寫成 \\vec{u}、\\vec{v}", cfg.t2, cfg.a2, cfg.l2, "把新的方程組寫成 \\vec{u}、\\vec{v} 的組合。", T_CRM),
				_f("解", "比係數", "(x, y) = ([0], [1])", cfg.xy, cfg.l3, "\\vec{u}、\\vec{v} 不平行：係數只有一種。", T_CRM),
			]})
	return {"id": "kswap", "chapter": 2, "type": "forge", "title": "換一組線",
		"story": "係數換來換去，看成箭頭就不怕。",
		"insight": "a_{1}x + b_{1}y = c_{1}、a_{2}x + b_{2}y = c_{2} 就是 x\\vec{u} + y\\vec{v} = \\vec{w}\n\\vec{u}、\\vec{v} 不平行：斜格子上的地址只有一個，比係數就好。",
		"variants": vars}


## 13 交線的審判（B51、B54）
static func _cjudge() -> Dictionary:
	var vars := []
	var a := Vector2(2, 0)
	var b := Vector2(0, 1)
	var c := a * 2 + b * 3
	var s1 := [_ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"ls": -1}), _ar(Vector2.ZERO, b, "pink", "\\vec{b}"), _ar(Vector2.ZERO, c, "lime", "\\vec{c}"),
		_poly([Vector2.ZERO, a, b], "gold", {"fill": "gold", "alpha": 0.2, "at": 2, "until": 3}),
		_ar(Vector2.ZERO, a * 2 - c, "gold", "2\\vec{a} − \\vec{c}", {"at": 3, "until": 4}),
		{"k": "skew", "o": [0, 0], "a": _p(a), "b": _p(b), "i": [-1, 3], "j": [-1, 4], "div": 1, "c": "cyan", "at": 4}, _dot(c, "(2, 3)", "gold", {"at": 4, "off": [10, -6]})]
	var e1 := "%s = 2、%s = −4\n%s = 6，下面哪些正確？" % [_D("a_{1}", "b_{1}", "a_{2}", "b_{2}"), _D("b_{1}", "c_{1}", "b_{2}", "c_{2}"), _D("a_{1}", "c_{1}", "a_{2}", "c_{2}")]
	vars.append({"eq": e1, "plane": _plane([-3.0, 7.0], [-3.6, 4.0], s1),
		"steps": [
			_j("審判一", "%s = 2" % _D("a_{1} + b_{1}", "c_{1}", "a_{2} + b_{2}", "c_{2}"), true,
				"拆成 %s + %s = 6 − 4。" % [_D("a_{1}", "c_{1}", "a_{2}", "c_{2}"), _D("b_{1}", "c_{1}", "b_{2}", "c_{2}")], "第一行拆開：6 − 4 = 2 ○", T_CRM),
			_j("審判二", "A(a_{1}, a_{2})、B(b_{1}, b_{2})：△OAB = 1", true, "\\frac{1}{2} × |2| = 1。", "△OAB = 1 ○", T_CRM),
			_j("審判三", "(2a_{1} − c_{1})x + b_{1}y = 0\n(2a_{2} − c_{2})x + b_{2}y = 0 有無限多組解", true,
				"Δ = 2 × 2 − %s = 4 − 4 = 0，又都過原點。" % _D("c_{1}", "b_{1}", "c_{2}", "b_{2}"), "Δ = 0 而且常數都是 0：無限多組 ○", T_CRM),
			_j("審判四", "a_{1}x + b_{1}y = c_{1}\na_{2}x + b_{2}y = c_{2} 的解是 (−2, 3)", false,
				"Δ_{x} = %s = 4，x = \\frac{4}{2} = 2。" % _D("c_{1}", "b_{1}", "c_{2}", "b_{2}"), "x = 2（不是 −2）、y = 3 ✕", T_CRM),
		]})
	a = Vector2(3, 0)
	b = Vector2(0, 1)
	c = b * 2
	var s2 := [_ar(Vector2.ZERO, a, "cyan", "\\vec{a}", {"ls": -1}), _ar(Vector2.ZERO, b, "pink", "\\vec{b}"),
		_poly([Vector2.ZERO, a, c], "violet", {"fill": "violet", "alpha": 0.2, "at": 2, "until": 3}),
		_ar(Vector2.ZERO, c, "lime", "\\vec{c} = 2\\vec{b}", {"at": 2, "w": 3.5}), _ar(Vector2.ZERO, a * 2, "gold", "\\vec{d} = 2\\vec{a}", {"at": 4, "dash": true})]
	var e2 := "%s = 3、%s = 6\n%s = 0，下面哪些正確？" % [_D("a_{1}", "b_{1}", "a_{2}", "b_{2}"), _D("a_{1}", "c_{1}", "a_{2}", "c_{2}"), _D("b_{1}", "c_{1}", "b_{2}", "c_{2}")]
	vars.append({"eq": e2, "plane": _plane([-3.0, 7.5], [-1.4, 3.6], s2),
		"steps": [
			_j("審判一", "%s = 75" % _D("5a_{1}", "5b_{1}", "5a_{2}", "5b_{2}"), true, "兩行各乘 5：25 × 3 = 75。", "25 × 3 = 75 ○", T_CRM),
			_j("審判二", "A(a_{1}, a_{2})、C(c_{1}, c_{2})：△OAC = 6", false, "\\frac{1}{2} × 6 = 3。", "△OAC = 3 ✕", T_CRM),
			_j("審判三", "a_{1}x + b_{1}y = c_{1}\na_{2}x + b_{2}y = c_{2} 的解是 (0, 2)", true,
				"Δ_{x} = %s = 0、Δ_{y} = 6：x = 0、y = 2。" % _D("c_{1}", "b_{1}", "c_{2}", "b_{2}"), "\\vec{c} = 2\\vec{b}：(0, 2) ○", T_CRM),
			_j("審判四", "x\\vec{a} + y\\vec{b} = \\vec{d} 恰一組解\n⇒ x\\vec{a} + y\\vec{d} = \\vec{b} 也恰一組解", false,
				"\\vec{d} = 2\\vec{a}：第一個恰一組，第二個 \\vec{a} ∥ \\vec{d}、\\vec{b} 不平行，無解。", "反例 \\vec{d} = 2\\vec{a} ✕", T_CRM),
		]})
	return {"id": "kcjudge", "chapter": 2, "type": "forge", "title": "交線的審判",
		"story": "只知道三個行列式，哪些說法對？",
		"insight": "Δ_{x}：x 那一行換成常數（注意交換變號）\nΔ = 0 又都過原點：無限多組解。",
		"variants": vars}


## 14 有幾組解（B50）
static func _count() -> Dictionary:
	var vars := []
	# 第 1 組：講義原題（每張卡畫一個例子）
	var ex := [[Vector2(2, 1), Vector2(-1, 2), Vector2(3, 4)], [Vector2(2, 1), Vector2(-4, -2), Vector2(1, 3)],
		[Vector2(2, 1), Vector2(4, 2), Vector2(-1, 3)], [Vector2(2, 1), Vector2(-4, -2), Vector2(4, 2)]]
	var s1 := []
	for k in 4:
		var e: Array = ex[k]
		var ext := {"at": k, "until": k + 1}
		s1 += [_ar(Vector2.ZERO, e[0], "cyan", "\\vec{a}", ext.merged({"ls": -1})), _ar(Vector2.ZERO, e[1], "pink", "\\vec{b}", ext.duplicate()),
			_ar(Vector2.ZERO, e[2], "gold", "\\vec{c}", ext.duplicate())]
		if k == 0:
			s1.append({"k": "skew", "o": [0, 0], "a": _p(e[0]), "b": _p(e[1]), "i": [-3, 3], "j": [-3, 3], "div": 1, "c": "cyan", "at": 0, "until": 1})
		else:
			s1.append(_Lk(1, -2, 0, "faint", "", {"at": k, "until": k + 1, "dash": true}))
	vars.append({"eq": "x\\vec{a} + y\\vec{b} = \\vec{c}（都不是 \\vec{0}）\n(x, y) 有幾組？下面哪些正確？", "plane": _plane([-7.0, 7.0], [-3.4, 5.0], s1),
		"steps": [
			_j("審判一", "\\vec{a}、\\vec{b} 不平行 ⇒ 恰有一組", true, "布張得開（Δ ≠ 0）：斜格子鋪滿整面，每一點的地址只有一個。", "不平行：恰一組 ○", T_SOL),
			_j("審判二", "\\vec{a} ∥ \\vec{b} ⇒ 有無限多組", false, "\\vec{c} 不在那條線上就無解。", "\\vec{c} 不平行就無解 ✕", T_SOL),
			_j("審判三", "\\vec{a} ∥ \\vec{b}、\\vec{a} 和 \\vec{c} 不平行 ⇒ 無解", true, "\\vec{a}、\\vec{b} 怎麼組合都在同一條線上，到不了 \\vec{c}。", "到不了 \\vec{c}：無解 ○", T_SOL),
			_j("審判四", "\\vec{a} ∥ \\vec{b} ∥ \\vec{c} ⇒ 無解", false, "\\vec{c} 在那條線上：有無限多種組合。", "都在同一條線上：無限多組 ✕", T_SOL),
		]})
	# 第 2 組：有坐標的
	var ex2 := [[Vector2(1, 2), Vector2(3, 1), Vector2(5, 5)], [Vector2(1, 2), Vector2(-2, -4), Vector2(3, 6)],
		[Vector2(1, 2), Vector2(2, 4), Vector2(2, 1)], [Vector2(2, 1), Vector2(-1, 2), Vector2(3, -4)]]
	var s2 := []
	for k in 4:
		var e: Array = ex2[k]
		var ext := {"at": k, "until": k + 1}
		s2 += [_ar(Vector2.ZERO, e[0], "cyan", "\\vec{a}", ext.merged({"ls": -1})), _ar(Vector2.ZERO, e[1], "pink", "\\vec{b}", ext.duplicate()),
			_ar(Vector2.ZERO, e[2], "gold", "\\vec{c}", ext.duplicate())]
		if k == 0 or k == 3:
			s2.append({"k": "skew", "o": [0, 0], "a": _p(e[0]), "b": _p(e[1]), "i": [-3, 4], "j": [-3, 4], "div": 1, "c": "cyan", "at": k, "until": k + 1})
		else:
			s2.append(_Lk(2, -1, 0, "faint", "", {"at": k, "until": k + 1, "dash": true}))
	vars.append({"eq": "x\\vec{a} + y\\vec{b} = \\vec{c}，(x, y) 有幾組？\n下面哪些正確？", "plane": _plane([-8.0, 8.0], [-4.6, 6.4], s2),
		"steps": [
			_j("審判一", "\\vec{a} = (1, 2)、\\vec{b} = (3, 1)、\\vec{c} = (5, 5)：恰有一組", true, "Δ = 1 − 6 = −5 ≠ 0：(x, y) = (2, 1)。", "Δ ≠ 0：恰一組 (2, 1) ○", T_SOL),
			_j("審判二", "\\vec{a} = (1, 2)、\\vec{b} = (−2, −4)、\\vec{c} = (3, 6)：無解", false, "\\vec{c} = 3\\vec{a}，三支都在同一條線上：無限多組。", "\\vec{c} = 3\\vec{a}：無限多組 ✕", T_SOL),
			_j("審判三", "\\vec{a} = (1, 2)、\\vec{b} = (2, 4)、\\vec{c} = (2, 1)：無解", true, "\\vec{a} ∥ \\vec{b}，\\vec{c} 不在那條線上。", "到不了 \\vec{c}：無解 ○", T_SOL),
			_j("審判四", "\\vec{a} = (2, 1)、\\vec{b} = (−1, 2)、\\vec{c} = (3, −4)：解不是整數，所以無解", false,
				"Δ = 5 ≠ 0：恰一組 (\\frac{2}{5}, −\\frac{11}{5})，解不一定是整數。", "恰一組 (\\frac{2}{5}, −\\frac{11}{5}) ✕", T_SOL),
		]})
	return {"id": "kcount", "chapter": 2, "type": "forge", "title": "有幾組解",
		"story": "\\vec{a}、\\vec{b} 張得開嗎？\\vec{c} 在哪裡？",
		"insight": "\\vec{a}、\\vec{b} 不平行（Δ ≠ 0）：恰一組\n平行：\\vec{c} 也在那條線上是無限多組，不然無解。",
		"variants": vars}


## 15 轉動的線（B57）
static func _turn() -> Dictionary:
	var vars := []
	for cfg in [{"L1": ["1", "2 - a", "a + 1"], "L2": ["2 - a", "1", "3 * a - 1"], "eq": "x + (2 − a)y = a + 1\n(2 − a)x + y = 3a − 1，下面哪些正確？",
				"f": ["1", "3"], "fl": "Δ = 1 − (2 − a)^{2} = (a − 1)(3 − a)", "fx": "(a - 1) * (3 - a)", "v0": 0,
				"cards": [[2, "恰有一組解", true, "Δ = 1 ≠ 0：(3, 5)。"], [1, "有無限多組解", true, "x + y = 2 兩條一樣。"],
					[3, "有無限多組解", false, "x − y = 4、−x + y = 8：平行，無解。"], [0, "無解", false, "Δ = −3 ≠ 0：恰一組 (−1, 1)。"]],
				"x": [-9.0, 9.0], "y": [-5.2, 6.6]},
			{"L1": ["3", "4 - a", "a + 2"], "L2": ["4 - a", "3", "2 * a + 1"], "eq": "3x + (4 − a)y = a + 2\n(4 − a)x + 3y = 2a + 1，下面哪些正確？",
				"f": ["1", "7"], "fl": "Δ = 9 − (4 − a)^{2} = (a − 1)(7 − a)", "fx": "(a - 1) * (7 - a)", "v0": 4,
				"cards": [[4, "恰有一組解", true, "Δ = 9 ≠ 0：(2, 3)。"], [7, "無解", true, "3x − 3y = 9、−3x + 3y = 15：平行。"],
					[1, "無解", false, "3x + 3y = 3 兩條一樣：無限多組。"], [3, "有無限多組解", false, "Δ = 8 ≠ 0：恰一組 (1, 2)。"]],
				"x": [-9.0, 9.0], "y": [-5.6, 6.4]}]:
		var shapes := []
		var st := [_f("Δ", "係數的行列式", "Δ = (a − [0])([1] − a)", cfg.f, cfg.fl, "平方差：1 − (2 − a)^{2} = (1 − (2 − a))(1 + (2 − a))。" if cfg.f[1] == "3" else "平方差：9 − (4 − a)^{2}。", T_SOL),
			{"kind": "slide", "name": "轉線", "q": "拖 a，看兩條線", "tag": T_SOL, "free": true,
			 "params": [{"n": "a", "min": -2, "max": 8, "step": 1, "v": cfg.v0}],
			 "lines": [{"abc": [cfg.L1[0], cfg.L1[1], "-(%s)" % cfg.L1[2]], "c": "cyan"}, {"abc": [cfg.L2[0], cfg.L2[1], "-(%s)" % cfg.L2[2]], "c": "pink"}],
			 "eq": "a = {a}：Δ = {%s}" % cfg.fx, "line": "Δ = 0 的時候，兩條線平行或疊在一起", "nudge": "拉到 Δ = 0 的地方看看。"}]
		for k in 4:
			var cd: Array = cfg.cards[k]
			var av := float(cd[0])
			var l1 := [_ev(cfg.L1[0], av), _ev(cfg.L1[1], av), _ev(cfg.L1[2], av)]
			var l2 := [_ev(cfg.L2[0], av), _ev(cfg.L2[1], av), _ev(cfg.L2[2], av)]
			var ext := {"at": k + 2, "until": k + 3}
			shapes += [_Lk(l1[0], l1[1], l1[2], "cyan", "", ext.duplicate()), _Lk(l2[0], l2[1], l2[2], "pink", "", ext.merged({"dash": true}))]
			st.append(_j("審判%s" % ["一", "二", "三", "四"][k], "a = %d 時%s" % [cd[0], cd[1]], cd[2], cd[3], "a = %d：%s" % [cd[0], cd[3]], T_SOL))
		vars.append({"eq": cfg.eq, "plane": _axes(cfg.x, cfg.y, shapes), "steps": st})
	return {"id": "kturn", "chapter": 2, "type": "forge", "title": "轉動的線",
		"story": "a 一變，兩條線跟著轉：什麼時候碰不到、什麼時候疊在一起？",
		"insight": "先找 Δ = 0 的 a：其他的 a 都恰一組\nΔ = 0 的 a 代回去：疊在一起（無限多組）或平行（無解）。",
		"variants": vars}


static func _ev(e: String, a: float) -> float:
	var ex := Expression.new()
	ex.parse(e, ["a"])
	return float(ex.execute([a]))


## 16 永遠碰不到（B58）
static func _never() -> Dictionary:
	var vars := []
	for cfg in [{"L1": ["a + 3", "5 - a", "2"], "L2": ["3 - a", "2", "2 - a"], "eq": "(a + 3)x + (5 − a)y = 2\n(3 − a)x + 2y = 2 − a 無解，求 a",
				"r": [1, 9], "fl": "Δ = 2(a + 3) − (5 − a)(3 − a) = −(a − 1)(a − 9) = 0", "l1": "4x + 4y = 2、2x + 2y = 1：同一條線，無限多組",
				"l2": "12x − 4y = 2、−6x + 2y = −7：平行，無解", "x": [-5.0, 5.0], "y": [-4.0, 3.0]},
			{"L1": ["a - 1", "3 - a", "4"], "L2": ["1 - a", "1", "3 - a"], "eq": "(a − 1)x + (3 − a)y = 4\n(1 − a)x + y = 3 − a 無解，求 a",
				"r": [1, 4], "fl": "Δ = (a − 1) − (3 − a)(1 − a) = −(a − 1)(a − 4) = 0", "l1": "2y = 4、y = 2：同一條線，無限多組",
				"l2": "3x − y = 4、−3x + y = −1：平行，無解", "x": [-5.0, 5.0], "y": [-3.0, 4.0]}]:
		var shapes := []
		for k in 2:
			var av := float(cfg.r[k])
			var l1 := [_ev(cfg.L1[0], av), _ev(cfg.L1[1], av), _ev(cfg.L1[2], av)]
			var l2 := [_ev(cfg.L2[0], av), _ev(cfg.L2[1], av), _ev(cfg.L2[2], av)]
			var ext := {"at": k + 2} if k == 1 else {"at": 2, "until": 3}
			shapes += [_Lk(l1[0], l1[1], l1[2], "cyan", "", ext.duplicate()), _Lk(l2[0], l2[1], l2[2], "pink", "", ext.merged({"dash": true}))]
		vars.append({"eq": cfg.eq, "plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("Δ = 0", "係數的行列式", "a = [0] 或 [1]", [str(cfg.r[0]), str(cfg.r[1])], cfg.fl, "無解一定 Δ = 0：先找候選的 a。", T_SOL, "set"),
				_c("a = %d" % cfg.r[0], "a = %d：兩條線" % cfg.r[0], ["疊在一起", "平行"], 0, cfg.l1, "代進去，看兩條式子是不是倍數。", "a = %d：%s" % [cfg.r[0], cfg.l1], T_SOL),
				_c("a = %d" % cfg.r[1], "a = %d：兩條線" % cfg.r[1], ["疊在一起", "平行"], 1, cfg.l2, "代進去，看兩條式子是不是倍數。", "a = %d：%s" % [cfg.r[1], cfg.l2], T_SOL),
				_f("無解", "只留平行的", "a = [0]", [str(cfg.r[1])], "Δ = 0 不一定無解：只有 a = %d 無解" % cfg.r[1], "平行的那一個。", T_SOL),
			]})
	return {"id": "knever", "chapter": 2, "type": "forge", "title": "永遠碰不到",
		"story": "兩條線永遠碰不到，a 是多少？",
		"insight": "無解 ⇒ Δ = 0，但 Δ = 0 不一定無解\n每個 a 都代回去：平行才無解，疊在一起是無限多組。",
		"variants": vars}


## 17 疊在一起（B59）
static func _overlap() -> Dictionary:
	var vars := []
	for cfg in [{"eq": "ax − 3y = y、2x + y = b − 2\n(0, 0) 是解，還有別的解，求 a、b", "b": "2", "bl": "(0, 0) 代進第二式：0 = b − 2", "L2": [2, 1], "a": "-8",
				"al": "ax − 4y = 0、2x + y = 0：Δ = a + 8 = 0", "L1": [-8, -4]},
			{"eq": "3x + ay = x、x − 3y = 2b + 4\n(0, 0) 是解，還有別的解，求 a、b", "b": "-2", "bl": "(0, 0) 代進第二式：0 = 2b + 4", "L2": [1, -3], "a": "-6",
				"al": "2x + ay = 0、x − 3y = 0：Δ = −6 − a = 0", "L1": [2, -6]}]:
		var shapes := [_dot(Vector2.ZERO, "", "gold"), _Lk(cfg.L2[0], cfg.L2[1], 0, "pink", "", {"at": 1}),
			_Lk(cfg.L1[0], cfg.L1[1], 0, "gold", "", {"at": 3, "w": 5.0})]
		vars.append({"eq": cfg.eq, "plane": _axes([-6.0, 6.0], [-3.0, 3.0], shapes),
			"steps": [
				_f("b", "(0, 0) 代進去", "b = [0]", [cfg.b], cfg.bl, "x = 0、y = 0 代進第二式。", T_SOL),
				_c("別的解", "還有別的交點", ["兩條線疊在一起", "兩條線平行", "兩條線垂直"], 0, "兩條線都過原點，還要有別的交點：只能疊在一起。",
					"平行的話連原點都只有一條線經過。", "都過原點、還有別的交點：疊在一起", T_SOL),
				_f("a", "Δ = 0", "a = [0]", [cfg.a], cfg.al, "疊在一起：係數成比例，Δ = 0。", T_SOL),
			]})
	return {"id": "koverlap", "chapter": 2, "type": "forge", "title": "疊在一起",
		"story": "原點是解，而且不只一個解：兩條線怎麼放？",
		"insight": "常數都是 0：(0, 0) 一定是解\n還有別的解 ⇔ 兩條線疊在一起 ⇔ Δ = 0。",
		"variants": vars}
