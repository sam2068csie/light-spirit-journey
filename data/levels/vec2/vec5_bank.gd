extends RefCounted
## 平面向量 第五大關「四心營火」題庫（上冊 3-2 重點四、五：三角形的四心、面積比）
## 設計稿：docs/vec2_v5_design.md。數字都用程式驗算過（tools/vec2/verify_v5.py）。
##
## 引擎見 vec_level.gd（箭頭畫布、在圖上作答），圖層見 vec_board.gd。這一關多用了：
##   vplace 沙盒的 ropes（繩子，外心）、feet（竿子，內心）、split（三分花圃）、snap 0.5（半格）、pull（V2 的加權拉力，重心）、
##   圖層 fire（營火）、split（三分花圃）、shadow（V3 的影子，外心的影子落在邊的中點）、expand（展開田）。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/vec2/vec1_bank.gd")
const B2 := preload("res://data/levels/vec2/vec2_bank.gd")
const B3 := preload("res://data/levels/vec2/vec3_bank.gd")

const T_GC := "vec_centroid"      # 重心
const T_CTR := "vec_centers"      # 外心、內心、垂心
const T_AREA := "vec_area"        # 面積比


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return B1._f(name, q, template, answers, line, nudge, tag, mode)


static func _j(name: String, statement: String, ok: bool, why: String, line: String, tag: String) -> Dictionary:
	var st := B1._j(name, statement, ok, why, line, tag)
	st["big"] = true
	return st


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


static func _pt(v: Vector2) -> String:
	return B2._pt(v)


static func _fire(p: Vector2, c: String, at: int, extra := {}) -> Dictionary:
	var d := {"k": "fire", "p": _p(p), "c": c, "at": at, "dur": 0.8}
	d.merge(extra, true)
	return d


static func _split(p: Vector2, A: Vector2, B: Vector2, C: Vector2, at: int, extra := {}) -> Dictionary:
	var d := {"k": "split", "p": _p(p), "tri": [_p(A), _p(B), _p(C)], "at": at}
	d.merge(extra, true)
	return d


static func _ruler(a: Vector2, b: Vector2, n: int, m: int, at: int, extra := {}) -> Dictionary:
	return B2._ruler(a, b, n, m, at, extra)


static func _shadow(o: Vector2, a: Vector2, g: Vector2, extra := {}) -> Dictionary:
	return B3._shadow(o, a, g, extra)


static func _expand(p: Vector2, rows: Array, cols: Array, cells: Array, sg: Array, at: int, extra := {}) -> Dictionary:
	return B3._expand(p, rows, cols, cells, sg, at, extra)


static func _e(v: float) -> String:
	return B3._e(v)


## 加權平均
static func _wavg(w: Array, pts: Array) -> Vector2:
	var s := 0.0
	var p := Vector2.ZERO
	for i in w.size():
		s += float(w[i])
		p += Vector2(pts[i]) * float(w[i])
	return p / s


## 拖點時的三塊面積（算式，x、y 是拖的點）
static func _area_ex(Q: Vector2, R: Vector2) -> String:
	return "abs((%s - x) * (%s - y) - (%s - y) * (%s - x)) / 2" % [_e(Q.x), _e(R.y), _e(Q.y), _e(R.x)]


static func _split_read(A: Vector2, B: Vector2, C: Vector2) -> String:
	return "△PBC : △PCA : △PAB = {%s} : {%s} : {%s}" % [_area_ex(B, C), _area_ex(C, A), _area_ex(A, B)]


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return absi(a)


## 權重的寫法：係數 1 不寫（6P = A + 2B + 3C）
static func _wsum(w: Array) -> String:
	var out := []
	for i in 3:
		var c := str(w[i])
		out.append(("" if c == "1" else c) + ["A", "B", "C"][i])
	return " + ".join(out)


static func _pull(pts: Array, w: Array) -> Array:
	var out := []
	for i in pts.size():
		out.append([pts[i].x, pts[i].y, w[i]])
	return out


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
		_centroid_cards(), _cen_dot(), _closed(), _small_g(), _seesaw(), _incenter_cards(), _four_fires(), _center_cards(), _calc(),
		{"id": "speed1", "chapter": 1, "type": "speed", "title": "四心速算", "time": 120.0,
		 "story": "看關係式，認出是哪一座營火！",
		 "insight": "重心：\\vec{PA} + \\vec{PB} + \\vec{PC} = \\vec{0}。外心：到三頂點一樣遠\n內心：權重是對邊長。垂心：\\vec{PA} · \\vec{BC} = 0（三條高）。",
		 "variants": [{"gen": "center", "count": 8}]},
		_split_garden(), _same_height(), _coef_height(), _pull_split(), _place_by_area(), _reverse(), _center_areas(),
		{"id": "speed2", "chapter": 2, "type": "speed", "title": "面積比速算", "time": 120.0,
		 "story": "花圃一塊一塊開花，權重就是對面那一塊！",
		 "insight": "w_{A}\\vec{PA} + w_{B}\\vec{PB} + w_{C}\\vec{PC} = \\vec{0} ⇒ △PBC : △PCA : △PAB = w_{A} : w_{B} : w_{C}\n某一塊佔全部的比 = 它的權重除以權重和。",
		 "variants": [{"gen": "area", "count": 8}]},
	]


# ======================= 第一章．四心營火 =======================

## 1 重心營火（A64）：重心那一張放第一張（可以拖 G），其他卡的證據在判完之後才畫
static func _centroid_cards() -> Dictionary:
	var vars := []
	# 第 1 組
	var A := Vector2(0, 4)
	var B := Vector2(-3, -2)
	var C := Vector2(6, 1)
	var G := Vector2(1, 1)
	var mid := (A + B) / 2.0
	var nrm := Vector2(2, -1)
	var D := mid - nrm
	var Q := [Vector2(-7, -2.6), Vector2(-2.5, -2.6), Vector2(-3.2, 1.0), Vector2(-6.4, 0.2)]
	var s1 := [_poly([A, B, C], "dim", {"until": 3})]
	s1 += [_dot(A, "A", "text", {"off": [-4, -12], "until": 3}), _dot(B, "B", "text", {"off": [-16, 4], "until": 3}), _dot(C, "C", "text", {"off": [8, 4], "until": 3})]
	s1 += [_fire(G, "gold", 1, {"s": "G", "until": 3}),
		_seg(mid + nrm * 1.6, mid - nrm * 1.6, "faint", {"dash": true, "at": 2, "until": 3}), _dot(D, "D", "pink", {"at": 2, "until": 3, "off": [-16, -4]}),
		_ar(A, D, "cyan", "\\vec{AD}", {"at": 2, "until": 3, "ls": 1}), _ar(B, D, "pink", "\\vec{BD}", {"at": 2, "until": 3, "ls": -1}),
		_ar(A, B, "gold", "\\vec{AB}", {"at": 2, "until": 3, "ls": -1, "lt": 0.6})]
	# 第四張的證據：一般的凸四邊形，四支箭加起來不是 \vec{0}
	var E := Vector2(-5.0599676, -0.7620746)
	s1 += [_poly(Q, "dim", {"at": 3}), _seg(Q[0], Q[2], "faint", {"at": 3}), _seg(Q[1], Q[3], "faint", {"at": 3}), _dot(E, "E", "dim", {"at": 3, "off": [-4, 18]})]
	s1 += _dots({"A": Q[0], "B": Q[1], "C": Q[2], "D": Q[3]}, "text", {"A": [-14, 12], "B": [6, 12], "C": [8, 4], "D": [-14, -6]}).map(func(d): d["at"] = 3; return d)
	var tot := Vector2.ZERO
	var cl := ["cyan", "pink", "lime", "violet"]
	for i in 4:
		s1.append(_ar(E, Q[i], cl[i], "", {"at": 4, "w": 2.0}))
		tot += Q[i] - E
	s1.append(_ar(E, E + tot, "gold", "", {"at": 4, "w": 3.5}))
	var sbx := {"label": "G", "lit": [_p(G)], "pull": _pull([A, B, C], [1, 1, 1]), "start": [3, -1]}
	var st1 := [
		_j("審判一", "G 是重心 ⇒ \\vec{GA} + \\vec{GB} + \\vec{GC} = \\vec{0}", true, "三條繩子拉著 G，剛好拉平衡。", "重心：\\vec{GA} + \\vec{GB} + \\vec{GC} = \\vec{0}", T_GC),
		_j("審判二", "\\vec{AB} + \\vec{BC} + \\vec{CA} = \\vec{0}", true, "首尾相接，繞一圈回到 A。", "首尾相接回到起點：\\vec{0}", T_GC),
		_j("審判三", "D 在 \\ol{AB} 的中垂線上 ⇒ \\vec{AD} − \\vec{BD} = \\vec{0}", false,
			"長度一樣，可是方向不一樣：\\vec{AD} − \\vec{BD} = \\vec{AD} + \\vec{DB} = \\vec{AB}。", "\\vec{AD} − \\vec{BD} = \\vec{AB} ≠ \\vec{0}", T_GC),
		_j("審判四", "凸四邊形 ABCD 的對角線交於 E ⇒ \\vec{EA} + \\vec{EB} + \\vec{EC} + \\vec{ED} = \\vec{0}", false,
			"要兩條對角線互相平分（平行四邊形）才成立。", "一般的凸四邊形不成立（金色的和不是 \\vec{0}）", T_GC)]
	st1[0]["sandbox"] = sbx
	vars.append({"eq": "下面哪些一定成立？（第一張可以拖 G）", "plane": _plane([-7.5, 8.0], [-3.2, 5.0], s1), "steps": st1})
	# 第 2 組：換一個小一點的三角形，\vec{AB} + \vec{AC} 才畫得進來
	var A2 := Vector2(-1, 4)
	var B2 := Vector2(-3, -1)
	var C2 := Vector2(4, 0)
	var G2 := Vector2(0, 1)
	var M := (B2 + C2) / 2.0
	var s2 := [_poly([A2, B2, C2], "dim")]
	s2 += _dots({"A": A2, "B": B2, "C": C2}, "text", {"A": [-4, -12], "B": [-16, 4], "C": [8, 4]})
	s2 += [_fire(G2, "gold", 1, {"s": "G", "off": [14, 2]}),
		_seg(A2, B2 + C2 - A2, "faint", {"at": 4, "dash": true}), _poly([A2, B2, B2 + C2 - A2, C2], "faint", {"at": 4}),
		_dot(M, "M", "dim", {"at": 4, "off": [10, 2]}),
		_ar(A2, B2 + C2 - A2, "pink", "\\vec{AB} + \\vec{AC}", {"at": 4, "lt": 0.82, "ls": -1}), _ar(A2, M, "gold", "\\vec{AM}", {"at": 4, "ls": -1, "lt": 0.3, "w": 3.5})]
	var sbx2 := {"label": "G", "lit": [_p(G2)], "pull": _pull([A2, B2, C2], [1, 1, 1]), "start": [2, 3]}
	var st2 := [
		_j("審判一", "G 是重心 ⇒ \\vec{AG} = \\frac{1}{3}(\\vec{AB} + \\vec{AC})", true, "\\vec{AG} = \\frac{2}{3}\\vec{AM}，\\vec{AM} = \\frac{1}{2}(\\vec{AB} + \\vec{AC})。", "\\vec{AG} = \\frac{1}{3}(\\vec{AB} + \\vec{AC})", T_GC),
		_j("審判二", "\\vec{a} ⊥ \\vec{b} ⇒ \\vec{a} · \\vec{b} = 0", true, "垂直時 cos 90° = 0。", "垂直 ⇒ 內積是 0", T_GC),
		_j("審判三", "D 在 \\ol{AB} 的中垂線上 ⇒ |\\vec{AD}| − |\\vec{BD}| = 0", true, "中垂線上的點到兩端一樣遠（這次是長度，不是向量）。", "|\\vec{AD}| = |\\vec{BD}|", T_GC),
		_j("審判四", "M 是 \\ol{BC} 中點 ⇒ \\vec{AM} = \\vec{AB} + \\vec{AC}", false, "\\vec{AB} + \\vec{AC} 是平行四邊形的對角線，是 \\vec{AM} 的 2 倍。", "\\vec{AM} = \\frac{1}{2}(\\vec{AB} + \\vec{AC})", T_GC)]
	st2[0]["sandbox"] = sbx2
	vars.append({"eq": "下面哪些一定成立？（第一張可以拖 G）", "plane": _plane([-6.5, 8.5], [-5.8, 5.0], s2), "steps": st2})
	return {"id": "gcards", "chapter": 1, "type": "forge", "title": "重心營火",
		"story": "三個人從頂點拉繩子，拉平衡的地方點營火。",
		"insight": "重心：\\vec{GA} + \\vec{GB} + \\vec{GC} = \\vec{0}，\\vec{AG} = \\frac{1}{3}(\\vec{AB} + \\vec{AC})\n向量相減和長度相減不一樣：|\\vec{AD}| = |\\vec{BD}| 不代表 \\vec{AD} = \\vec{BD}。",
		"variants": vars}


## 2 重心的內積（A65）
static func _cen_dot() -> Dictionary:
	var vars := []
	for cfg in [{"s": 3.0, "nm": "D", "k": 1.0 / 3.0, "q": ["2/3", "1/3"], "ans": "9/2", "ab": "\\frac{9}{2}",
				"cells": [["2", "1"], ["\\frac{1}{2}", "1"]], "rows": ["\\frac{2}{3}\\vec{AB}", "\\frac{1}{3}\\vec{AC}"]},
			{"s": 6.0, "nm": "E", "k": 2.0 / 3.0, "q": ["1/3", "2/3"], "ans": "18", "ab": "18",
				"cells": [["4", "2"], ["4", "8"]], "rows": ["\\frac{1}{3}\\vec{AB}", "\\frac{2}{3}\\vec{AC}"]}]:
		var s: float = cfg.s
		var B := Vector2.ZERO
		var C := Vector2(s, 0)
		var A := Vector2(s / 2.0, s * sqrt(3.0) / 2.0)
		var X := B.lerp(C, cfg.k)
		var G := (A + B + C) / 3.0
		var nm: String = cfg.nm
		var shapes := [_poly([A, B, C], "dim")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-4, -12], "B": [-14, 14], "C": [6, 14]})
		shapes += [_dot(X, nm, "pink", {"off": [-4, 18]}), _ruler(B, C, 3, 3, 0, {"c": "faint"}),
			_fire(G, "gold", 1, {"s": "G", "off": [12, -2]}), _seg(A, (B + C) / 2.0, "faint", {"at": 1, "dash": true}), _ar(A, G, "gold", "", {"at": 1}), _ar(A, X, "pink", "", {"at": 2}),
			_expand(Vector2(s * 1.4, s * 0.86), cfg.rows, ["\\frac{1}{3}\\vec{AB}", "\\frac{1}{3}\\vec{AC}"], cfg.cells, [[1, 1], [1, 1]], 2, {"hw": 72})]
		var q: Array = cfg.q
		vars.append({"eq": "正三角形 ABC 邊長 %s，G 是重心\n%s 是 \\ol{BC} 的三等分點（靠近 %s），求 \\vec{A%s} · \\vec{AG}" % [B1._n(s), nm, "B" if nm == "D" else "C", nm],
			"plane": _plane([-0.8, s * 2.85], [-0.6, s * 0.95], shapes),
			"steps": [
				_f("\\vec{AG}", "重心", "\\vec{AG} = [0]\\vec{AB} + [1]\\vec{AC}", ["1/3", "1/3"], "\\vec{AG} = \\frac{1}{3}\\vec{AB} + \\frac{1}{3}\\vec{AC}", "\\vec{AG} = \\frac{2}{3}\\vec{AM}，M 是 \\ol{BC} 中點。", T_GC),
				_f("\\vec{A%s}" % nm, "三等分點", "\\vec{A%s} = [0]\\vec{AB} + [1]\\vec{AC}" % nm, q,
					"\\vec{A%s} = %s" % [nm, B1._lin(q[0], "AB", q[1], "AC")], "係數交叉：靠近哪一個頂點，那一個的係數就大。", T_GC),
				_f("展開田", "四格加起來", "\\vec{A%s} · \\vec{AG} = [0]" % nm, [cfg.ans],
					"\\vec{AB} · \\vec{AC} = %s × %s × cos 60° = %s，四格加起來 = %s" % [B1._n(s), B1._n(s), cfg.ab, B2._fv(B1._frv(cfg.ans))], "|\\vec{AB}|^{2} = %s，\\vec{AB} · \\vec{AC} = %s。" % [B1._n(s * s), cfg.ab], T_GC),
			]})
	return {"id": "gdot", "chapter": 1, "type": "forge", "title": "重心的內積",
		"story": "重心營火和三等分點，換成基底再展開。",
		"insight": "\\vec{AG} = \\frac{1}{3}\\vec{AB} + \\frac{1}{3}\\vec{AC}\n圖形裡的內積：兩支都換成 \\vec{AB}、\\vec{AC}，再用展開田。",
		"variants": vars}


## 3 首尾相接的三支箭（A66）
static func _closed() -> Dictionary:
	var vars := []
	# 第 1 組：a + 2b + 3c = 0
	var a := Vector2(1, 2)
	var b := Vector2(2, 0)
	var c := -(a + b * 2.0) / 3.0
	var O := Vector2(-1.5, -0.5)
	var s1 := [_ar(O, O + a, "cyan", "\\vec{a}", {"ls": 1}), _ar(O + a, O + a + b * 2.0, "pink", "2\\vec{b}"), _ar(O + a + b * 2.0, O, "lime", "3\\vec{c}"),
		_ar(O, O + a, "gold", "√5", {"at": 3, "w": 4.0, "ls": -1})]
	vars.append({"eq": "\\vec{a} + 2\\vec{b} + 3\\vec{c} = \\vec{0}，\\vec{a} · \\vec{b} = 2，\\vec{c} · \\vec{a} = −3\n求 |\\vec{a}|",
		"plane": _plane([-3.5, 5.0], [-1.4, 2.4], s1),
		"steps": [
			_c("和誰內積", "等式兩邊和哪一支內積？", ["\\vec{a}", "\\vec{b}", "\\vec{c}"], 0,
				"和 \\vec{a} 內積：出現 |\\vec{a}|^{2}、\\vec{a} · \\vec{b}、\\vec{c} · \\vec{a}，都是已知或要求的。",
				"要求 |\\vec{a}|，就要出現 \\vec{a} · \\vec{a}。", "兩邊和 \\vec{a} 內積：|\\vec{a}|^{2} + 2\\vec{a} · \\vec{b} + 3\\vec{c} · \\vec{a} = 0", T_GC),
			_f("長度平方", "代進去", "|\\vec{a}|^{2} = [0]", ["5"], "|\\vec{a}|^{2} + 4 − 9 = 0 ⇒ |\\vec{a}|^{2} = 5", "2 × 2 + 3 × (−3)。", T_GC),
			_f("長度", "開根號", "|\\vec{a}| = [0]", ["√5"], "|\\vec{a}| = √5", "√5。", T_GC),
		]})
	# 第 2 組：a + b + 2c = 0
	var b2 := Vector2(sqrt(3.0), 0)
	var a2 := Vector2(-1.0 / sqrt(3.0), 1.7)
	var c2 := -(a2 + b2) / 2.0
	var O2 := Vector2(-0.6, -0.6)
	var s2 := [_ar(O2, O2 + a2, "cyan", "\\vec{a}", {"ls": 1}), _ar(O2 + a2, O2 + a2 + b2, "pink", "\\vec{b}"), _ar(O2 + a2 + b2, O2, "lime", "2\\vec{c}"),
		_ar(O2 + a2, O2 + a2 + b2, "gold", "√3", {"at": 3, "w": 4.0, "ls": -1})]
	vars.append({"eq": "\\vec{a} + \\vec{b} + 2\\vec{c} = \\vec{0}，\\vec{a} · \\vec{b} = −1，\\vec{b} · \\vec{c} = −1\n求 |\\vec{b}|",
		"plane": _plane([-2.4, 2.4], [-1.0, 1.5], s2),
		"steps": [
			_c("和誰內積", "等式兩邊和哪一支內積？", ["\\vec{a}", "\\vec{b}", "\\vec{c}"], 1,
				"和 \\vec{b} 內積：出現 \\vec{a} · \\vec{b}、|\\vec{b}|^{2}、\\vec{b} · \\vec{c}，都是已知或要求的。",
				"要求 |\\vec{b}|，就要出現 \\vec{b} · \\vec{b}。", "兩邊和 \\vec{b} 內積：\\vec{a} · \\vec{b} + |\\vec{b}|^{2} + 2\\vec{b} · \\vec{c} = 0", T_GC),
			_f("長度平方", "代進去", "|\\vec{b}|^{2} = [0]", ["3"], "−1 + |\\vec{b}|^{2} − 2 = 0 ⇒ |\\vec{b}|^{2} = 3", "−1 + |\\vec{b}|^{2} + 2 × (−1) = 0。", T_GC),
			_f("長度", "開根號", "|\\vec{b}| = [0]", ["√3"], "|\\vec{b}| = √3", "√3。", T_GC),
		]})
	return {"id": "closed", "chapter": 1, "type": "forge", "title": "首尾相接的三支箭",
		"story": "三支箭首尾相接回到起點，合起來是零。",
		"insight": "知道 x\\vec{a} + y\\vec{b} + z\\vec{c} = \\vec{0}：兩邊和要求的那一支內積\n|\\vec{a}|^{2} = \\vec{a} · \\vec{a}，其他的內積代進去。",
		"variants": vars}


## 4 小營地的重心（A67）
static func _small_g() -> Dictionary:
	var A := Vector2(0, 5)
	var B := Vector2(-4, 0)
	var C := Vector2(6, 0)
	var vars := []
	for cfg in [{"ap": 1.0 / 3.0, "bq": 0.5, "cr": 1.0 / 3.0, "t": ["\\frac{1}{3}", "\\frac{1}{2}", "\\frac{1}{3}"], "f1": ["1/3", "2/3"], "f2": ["1/2", "1/2"], "g": ["5/18", "7/18"]},
			{"ap": 0.5, "bq": 2.0 / 3.0, "cr": 0.25, "t": ["\\frac{1}{2}", "\\frac{2}{3}", "\\frac{1}{4}"], "f1": ["1/2", "3/4"], "f2": ["1/3", "2/3"], "g": ["5/18", "17/36"]}]:
		var P := A.lerp(B, cfg.ap)
		var Q := B.lerp(C, cfg.bq)
		var R := C.lerp(A, cfg.cr)
		var G := (P + Q + R) / 3.0
		var shapes := [_poly([A, B, C], "dim")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-4, -12], "B": [-16, 4], "C": [8, 4]})
		shapes += _dots({"P": P, "Q": Q, "R": R}, "pink", {"P": [-16, -4], "Q": [-4, 18], "R": [8, -4]})
		shapes += [_poly([P, Q, R], "pink", {"at": 3, "fill": "pink", "alpha": 0.1}), _seg(P, G, "gold", {"at": 3}), _seg(Q, G, "gold", {"at": 3}), _seg(R, G, "gold", {"at": 3}),
			_fire(G, "gold", 3, {"s": "G", "off": [12, -2]})]
		var t: Array = cfg.t
		vars.append({"eq": "\\vec{AP} = %s\\vec{AB}，\\vec{BQ} = %s\\vec{BC}，\\vec{CR} = %s\\vec{CA}\n△PQR 的重心 G，\\vec{AG} = x\\vec{AB} + y\\vec{AC}，求 (x, y)" % t,
			"plane": _plane([-6.0, 8.5], [-1.0, 6.0], shapes),
			"steps": [
				_f("P、R", "只差一個係數", "\\vec{AP} = [0]\\vec{AB}，\\vec{AR} = [1]\\vec{AC}", cfg.f1,
					"\\vec{AP} = %s\\vec{AB}，\\vec{AR} = %s\\vec{AC}" % [B1._frs(cfg.f1[0]), B1._frs(cfg.f1[1])], "\\vec{AR} = \\vec{AC} + \\vec{CR}。", T_GC),
				_f("Q", "分點", "\\vec{AQ} = [0]\\vec{AB} + [1]\\vec{AC}", cfg.f2, "\\vec{AQ} = %s" % B1._lin(cfg.f2[0], "AB", cfg.f2[1], "AC"), "\\vec{AQ} = \\vec{AB} + \\vec{BQ}。", T_GC),
				_f("重心", "三個的平均", "\\vec{AG} = [0]\\vec{AB} + [1]\\vec{AC}", cfg.g,
					"\\vec{AG} = \\frac{1}{3}(\\vec{AP} + \\vec{AQ} + \\vec{AR})：(x, y) = (%s, %s)" % [B1._frs(cfg.g[0]), B1._frs(cfg.g[1])], "三個 \\vec{AB} 係數加起來除以 3，\\vec{AC} 也一樣。", T_GC),
			]})
	return {"id": "smallg", "chapter": 1, "type": "forge", "title": "小營地的重心",
		"story": "營地裡圍出一個小營地，它的重心在哪裡？",
		"insight": "重心是三個頂點的平均：\\vec{AG} = \\frac{1}{3}(\\vec{AP} + \\vec{AQ} + \\vec{AR})\n三個點都先寫成 \\vec{AB}、\\vec{AC} 的組合。",
		"variants": vars}


## 5 過重心的蹺蹺板（A68）
static func _seesaw() -> Dictionary:
	var A := Vector2(0, 6)
	var B := Vector2(-4, 0)
	var C := Vector2(5, 0)
	var G := (A + B + C) / 3.0
	var vars := []
	for cfg in [{"s": 0.4, "step": 0.2, "max": 0.6, "n": 5, "ratio": "2 : 3", "f2": ["5/9", "1/3"], "t": "3/4", "r": ["4", "3"]},
			{"s": 1.0 / 3.0, "step": 1.0 / 6.0, "max": 0.5, "n": 3, "ratio": "1 : 2", "f2": ["1/2", "1/3"], "t": "2/3", "r": ["3", "2"]}]:
		var s: float = cfg.s
		var P := A.lerp(C, s)
		var t := B1._frv(cfg.t)
		var Q := C.lerp(B, t)
		var px := "5 * s"
		var py := "6 - 6 * s"
		var kk := "(6 - 6 * s) / (4 - 6 * s)"
		var qx := "5 * s + (0.3333333 - 5 * s) * %s" % kk
		var lines := [{"k": "dot", "p": [px, py], "c": "gold", "s": "P"}, {"k": "dot", "p": [qx, "0"], "c": "pink", "s": "Q"},
			{"k": "seg", "a": [px, py], "b": [qx, "0"], "c": "gold"}]
		var shapes := [_poly([A, B, C], "dim"), _ruler(A, C, int(cfg.n), 0, 0, {"c": "faint"})]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-4, -12], "B": [-16, 4], "C": [8, 4]})
		shapes += [_dot(G, "G", "gold", {"off": [-16, -4]}), _seg(P, Q, "gold", {"at": 1}), _dot(P, "P", "gold", {"at": 1, "off": [8, -4]}), _dot(Q, "Q", "pink", {"at": 1, "off": [-4, 18]}),
			_poly([A, Q, C], "pink", {"at": 4, "fill": "pink", "alpha": 0.18})]
		var f2: Array = cfg.f2
		var r: Array = cfg.r
		vars.append({"eq": "G 是 △ABC 的重心，直線 PQ 過 G，P 在 \\ol{AC} 上、Q 在 \\ol{BC} 上\n\\ol{AP} : \\ol{PC} = %s，求 △ABC 面積 : △AQC 面積" % cfg.ratio,
			"plane": _plane([-6.0, 7.0], [-1.0, 6.8], shapes),
			"steps": [
				{"kind": "slide", "name": "蹺蹺板", "q": "拖 P，讓 \\ol{AP} : \\ol{PC} = %s" % cfg.ratio, "tag": T_GC, "big": true,
				 "params": [{"n": "s", "min": 0, "max": cfg.max, "step": cfg.step, "v": cfg.step}], "lines": lines, "goal": {"s": s},
				 "line": "\\ol{AP} : \\ol{PC} = %s：過 G 的直線打到 BC 上的 Q" % cfg.ratio, "nudge": "看 \\ol{AC} 上的刻度。"},
				_f("以 C 為起點", "\\vec{CG} 換成 \\vec{CP}、\\vec{CB}", "\\vec{CG} = [0]\\vec{CP} + [1]\\vec{CB}", f2,
					"\\vec{CG} = \\frac{1}{3}\\vec{CA} + \\frac{1}{3}\\vec{CB} = %s" % B1._lin(f2[0], "CP", f2[1], "CB"), "\\vec{CA} 是 \\vec{CP} 的幾倍？", T_GC),
				_f("係數和 = 1", "\\vec{CQ} = t\\vec{CB}", "t = [0]", [cfg.t],
					"\\vec{CG} = %s\\vec{CP} + \\frac{1}{3t}\\vec{CQ}，P、G、Q 共線：%s + \\frac{1}{3t} = 1，t = %s" % [B1._frs(f2[0]), B1._frs(f2[0]), B1._frs(cfg.t)],
					"\\vec{CB} = \\frac{1}{t}\\vec{CQ}，兩個係數加起來是 1。", T_GC),
				_f("面積比", "同高：底的比", "△ABC : △AQC = [0] : [1]", r, "△ABC : △AQC = \\ol{CB} : \\ol{CQ} = %s : %s" % r, "兩個三角形都以 A 為頂點，高一樣。", T_AREA, "prop"),
			]})
	return {"id": "seesaw", "chapter": 1, "type": "forge", "title": "過重心的蹺蹺板",
		"story": "一條直線繞著重心轉，像蹺蹺板。",
		"insight": "過重心的直線：以一個頂點為起點，\\vec{CG} 換成直線上兩點的組合\n三點共線，係數和 = 1。",
		"variants": vars}


## 6 內心營火（A69）
static func _incenter_cards() -> Dictionary:
	var vars := []
	for cfg in [{"ab": 4.0, "bc": 5.0, "ac": 6.0,
				"cards": [["\\ol{BD} : \\ol{CD} = 2 : 3", true, "角平分線：\\ol{BD} : \\ol{DC} = \\ol{AB} : \\ol{AC} = 4 : 6。", "bd"],
					["\\vec{AI} = \\frac{1}{3}\\vec{AD}", false, "\\ol{AI} : \\ol{ID} = (\\ol{AB} + \\ol{AC}) : \\ol{BC} = 10 : 5，\\vec{AI} = \\frac{2}{3}\\vec{AD}。", "ai"],
					["△ABI : △BCI : △ACI = 4 : 5 : 6", true, "三塊的高都是內切圓半徑，面積比 = 底的比。", "area"],
					["O 是任一點 ⇒ \\vec{OI} = \\frac{4}{15}\\vec{OA} + \\frac{1}{3}\\vec{OB} + \\frac{2}{5}\\vec{OC}", false, "權重是對邊長：\\frac{5\\vec{OA} + 6\\vec{OB} + 4\\vec{OC}}{15} = \\frac{1}{3}\\vec{OA} + \\frac{2}{5}\\vec{OB} + \\frac{4}{15}\\vec{OC}。", ""]]},
			{"ab": 5.0, "bc": 8.0, "ac": 7.0,
				"cards": [["\\ol{BD} : \\ol{DC} = 5 : 7", true, "角平分線：\\ol{BD} : \\ol{DC} = \\ol{AB} : \\ol{AC}。", "bd"],
					["\\vec{AI} = \\frac{3}{5}\\vec{AD}", true, "\\ol{AI} : \\ol{ID} = (5 + 7) : 8 = 3 : 2。", "ai"],
					["\\vec{AI} = \\frac{7}{20}\\vec{AB} + \\frac{1}{4}\\vec{AC}", true, "\\vec{AI} = \\frac{3}{5}(\\frac{7}{12}\\vec{AB} + \\frac{5}{12}\\vec{AC})。", ""],
					["△ABI : △BCI : △ACI = 7 : 8 : 5", false, "面積比 = 底的比：\\ol{AB} : \\ol{BC} : \\ol{CA} = 5 : 8 : 7。", "area"]]}]:
		var ab: float = cfg.ab
		var bc: float = cfg.bc
		var ac: float = cfg.ac
		var A := Vector2.ZERO
		var B := Vector2(ab, 0)
		var cx := (ab * ab + ac * ac - bc * bc) / (2.0 * ab)
		var C := Vector2(cx, sqrt(ac * ac - cx * cx))
		var I := (A * bc + B * ac + C * ab) / (ab + bc + ac)
		var D := B.lerp(C, ab / (ab + ac))
		var area := absf((B - A).cross(C - A)) / 2.0
		var r := area / ((ab + bc + ac) / 2.0)
		var shapes := [_poly([A, B, C], "dim")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [-4, -12]})
		shapes += [_dot(D, "D", "dim", {"off": [8, -2]}), _seg(A, D, "faint", {"dash": true}), _dot(I, "I", "cyan", {"off": [-14, -6]})]
		var steps := []
		var k := 0
		for cd in cfg.cards:
			k += 1
			match String(cd[3]):
				"bd":
					var nb := int(ab)
					var nc := int(ac)
					var g := _gcd(nb, nc)
					shapes.append(_ruler(B, C, (nb + nc) / g, nb / g, k, {"until": k + 1}))
				"ai":
					var num := int(ab + ac)
					var den := int(ab + ac + bc)
					var g2 := _gcd(num, den)
					shapes.append(_ruler(A, D, den / g2, num / g2, k, {"until": k + 1}))
				"area":
					shapes.append(_split(I, A, B, C, k, {"until": k + 1}))
			steps.append(_j(["審判一", "審判二", "審判三", "審判四"][k - 1], String(cd[0]), cd[1], String(cd[2]), String(cd[0]) + ("" if cd[1] else " ✕"), T_CTR))
		shapes += [{"k": "circle", "o": _p(I), "r": r, "c": "cyan", "at": 4}, _fire(I, "cyan", 4, {"s": ""})]
		vars.append({"eq": "△ABC 中，\\ol{AB} = %s，\\ol{BC} = %s，\\ol{AC} = %s，I 是內心\n\\ol{AI} 延長交 \\ol{BC} 於 D，下面哪些正確？" % [B1._n(ab), B1._n(bc), B1._n(ac)],
			"plane": _plane([-1.5, ab + 1.5], [-0.8, C.y + 0.8], shapes), "steps": steps})
	return {"id": "icards", "chapter": 1, "type": "forge", "title": "內心營火",
		"story": "到三面圍籬一樣遠的地方，點內心營火。",
		"insight": "內心：\\vec{AI} = \\frac{b}{a + b + c}\\vec{AB} + \\frac{c}{a + b + c}\\vec{AC}（權重是對邊長 a、b、c）\n\\ol{AI} : \\ol{ID} = (b + c) : a，三塊面積比 = 三邊的比。",
		"variants": vars}


## 7 點起四座營火（新）
static func _four_fires() -> Dictionary:
	var vars := []
	for cfg in [{"B": Vector2(12, 0), "C": Vector2(0, 9), "G": Vector2(4, 3), "O": Vector2(6, 4.5), "I": Vector2(3, 3), "bc": [3, 4, -36], "x": [-2.0, 14.5], "y": [-1.2, 10.2]},
			{"B": Vector2(-12, 0), "C": Vector2(0, 9), "G": Vector2(-4, 3), "O": Vector2(-6, 4.5), "I": Vector2(-3, 3), "bc": [-3, 4, -36], "x": [-14.5, 2.0], "y": [-1.2, 10.2]}]:
		var A := Vector2.ZERO
		var B: Vector2 = cfg.B
		var C: Vector2 = cfg.C
		var G: Vector2 = cfg.G
		var O: Vector2 = cfg.O
		var I: Vector2 = cfg.I
		var bcl: Array = cfg.bc
		var nrm := Vector2(float(bcl[0]), float(bcl[1])).normalized()
		var footA := A + nrm * (-float(bcl[2]) / Vector2(float(bcl[0]), float(bcl[1])).length())
		var shapes := [_poly([A, B, C], "text")]
		var sx := signf(B.x)
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14 if sx > 0 else 6, 16], "B": [-4, 16], "C": [8 if sx > 0 else -18, -4]})
		shapes += [_fire(G, "gold", 1, {"s": "G", "off": [12, -2]}), _fire(O, "pink", 2, {"s": "O", "off": [12, -2]}),
			{"k": "circle", "o": _p(I), "r": 3, "c": "cyan", "at": 3}, _fire(I, "cyan", 3, {"s": "I", "off": [-20 * sx, 6]}),
			_seg(A, footA, "lime", {"at": 4, "dash": true}), _seg(B, A, "lime", {"at": 4, "w": 3.0}), _seg(C, A, "lime", {"at": 4, "w": 3.0}),
			_fire(A, "lime", 4, {"s": "H", "off": [10 * sx, -14]})]
		var ox := "(x * x + y * y)"
		var dB := "((x - (%s)) * (x - (%s)) + (y - %s) * (y - %s))" % [_e(B.x), _e(B.x), _e(B.y), _e(B.y)]
		var dC := "((x - %s) * (x - %s) + (y - %s) * (y - %s))" % [_e(C.x), _e(C.x), _e(C.y), _e(C.y)]
		var lbc := "abs((%s) * x + %s * y + (%s)) / 5" % [str(bcl[0]), str(bcl[1]), str(bcl[2])]
		vars.append({"eq": "直角三角形營地 A(0, 0)、B%s、C%s\n四座營火（四心）各在哪裡？" % [_pt(B), _pt(C)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "重心", "q": "拖 G，讓三條繩子拉平衡", "tag": T_GC, "goal": "lit", "ans": _p(G), "big": true,
				 "sandbox": {"label": "G", "lit": [_p(G)], "pull": _pull([A, B, C], [1, 1, 1]), "start": [1.0 * sx, 1]},
				 "nudge": "金色的合力指向該去的地方。", "line": "重心 G%s" % _pt(G)},
				{"kind": "vplace", "name": "外心", "q": "拖 O，讓三條繩子一樣長", "tag": T_CTR, "goal": "lit", "ans": _p(O), "big": true,
				 "sandbox": {"label": "O", "snap": 0.5, "ropes": [_p(A), _p(B), _p(C)], "start": [2.0 * sx, 2],
					"lit": "abs(%s - %s) < 0.01 and abs(%s - %s) < 0.01" % [ox, dB, ox, dC]},
				 "nudge": "外心可以在半格上。直角三角形的外心在哪一條邊上？", "line": "外心 O%s：斜邊的中點" % _pt(O)},
				{"kind": "vplace", "name": "內心", "q": "拖 I，讓三根竿子一樣長", "tag": T_CTR, "goal": "lit", "ans": _p(I), "big": true,
				 "sandbox": {"label": "I", "feet": [[0, 1, 0], [1, 0, 0], bcl], "start": [5.0 * sx, 2],
					"lit": "abs(abs(x) - y) < 0.01 and abs(y - %s) < 0.01" % lbc},
				 "nudge": "到 x 軸、y 軸一樣遠。再看到斜邊的竿子。", "line": "內心 I%s：內切圓半徑 3" % _pt(I)},
				{"kind": "vpick", "name": "垂心", "q": "點出三條高的交點", "target": [0, 0], "snap": 1, "tag": T_CTR,
				 "traps": [[G.x, G.y, "那是重心。垂心是三條高（從頂點垂直照到對邊）的交點。"], [I.x, I.y, "那是內心。直角三角形的兩條高就是兩股。"]],
				 "nudge": "從 B 垂直照到 AC 的高是哪一條？從 C 呢？", "line": "垂心 H = A(0, 0)：直角三角形的垂心是直角頂點"},
			]})
	return {"id": "fires", "chapter": 1, "type": "forge", "title": "點起四座營火",
		"story": "四座營火各有規矩：拉平衡、一樣遠、一樣高。",
		"insight": "重心：繩子拉平衡。外心：到三頂點一樣遠（直角三角形在斜邊中點）\n內心：到三邊一樣遠。垂心：三條高的交點（直角三角形在直角頂點）。",
		"variants": vars}


## 8 四心的審判（A70、A71）
static func _center_cards() -> Dictionary:
	var vars := []
	# 第 1 組：3、4、5 的直角三角形
	var A := Vector2.ZERO
	var B := Vector2(3, 0)
	var C := Vector2(0, 4)
	var I := Vector2(1, 1)
	var O := Vector2(1.5, 2)
	var s1 := [_poly([A, B, C], "dim")]
	s1 += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [8, -4]})
	s1 += [_fire(I, "cyan", 1, {"s": "I", "off": [-20, 4]}), _ar(A, O, "pink", "", {"at": 2, "until": 4}), _shadow(A, O, C - A, {"at": 2, "until": 3}), _shadow(A, O, B - A, {"at": 3, "until": 4}),
		_fire(O, "pink", 2, {"s": "O", "off": [12, -2]}), _fire(A, "lime", 4, {"s": "H", "off": [14, -12]})]
	var st1 := [
		_j("審判一", "\\vec{AI} = \\frac{1}{3}\\vec{AB} + \\frac{1}{4}\\vec{AC}", true, "權重是對邊長：\\frac{4}{12}\\vec{AB} + \\frac{3}{12}\\vec{AC}。", "\\vec{AI} = \\frac{1}{3}\\vec{AB} + \\frac{1}{4}\\vec{AC}", T_CTR),
		_j("審判二", "\\vec{AO} · \\vec{AC} = 8", true, "外心的影子落在 \\ol{AC} 的中點：\\vec{AO} · \\vec{AC} = \\frac{1}{2}|\\vec{AC}|^{2} = 8。", "\\vec{AO} · \\vec{AC} = \\frac{1}{2} × 16 = 8", T_CTR),
		_j("審判三", "\\vec{AO} · \\vec{AB} = 8", false, "影子落在 \\ol{AB} 的中點：\\vec{AO} · \\vec{AB} = \\frac{1}{2} × 9 = \\frac{9}{2}。", "\\vec{AO} · \\vec{AB} = \\frac{9}{2}", T_CTR),
		_j("審判四", "\\vec{AH} · \\vec{BC} = 0", true, "H 是垂心：\\vec{AH} ⊥ \\vec{BC}（這一題 H 就是 A）。", "\\vec{AH} ⊥ \\vec{BC}", T_CTR)]
	vars.append({"eq": "△ABC 中，\\ol{AB} = 3，\\ol{BC} = 5，\\ol{CA} = 4\nI、O、H 是內心、外心、垂心，下面哪些正確？", "plane": _plane([-1.4, 6.4], [-0.8, 4.6], s1), "steps": st1})
	# 第 2 組：一般的三角形
	var A2 := Vector2.ZERO
	var B2 := Vector2(6, 0)
	var C2 := Vector2(1, 4)
	var O2 := Vector2(3, 1.375)
	var H2 := A2 + B2 + C2 - O2 * 2.0
	var fB := A2 + C2 * ((B2 - A2).dot(C2 - A2) / (C2 - A2).length_squared())
	var fC := Vector2(C2.x, 0)
	var s2 := [_poly([A2, B2, C2], "dim")]
	s2 += _dots({"A": A2, "B": B2, "C": C2}, "text", {"A": [-14, 14], "B": [6, 14], "C": [-4, -12]})
	var fA := B2 + (C2 - B2) * ((A2 - B2).dot(C2 - B2) / (C2 - B2).length_squared())
	s2 += [_seg(B2, fB, "lime", {"at": 1, "dash": true}), _seg(C2, fC, "lime", {"at": 1, "dash": true}), _seg(A2, fA, "lime", {"at": 1, "dash": true}),
		_fire(H2, "lime", 1, {"s": "H", "off": [-20, 4]}),
		_ar(A2, O2, "pink", "", {"at": 3, "until": 4}), _shadow(A2, O2, B2 - A2, {"at": 3, "until": 4}), _shadow(A2, O2, C2 - A2, {"at": 3, "until": 4}),
		_fire(O2, "pink", 3, {"s": "O", "off": [12, -2]}), _ar(O2, H2, "gold", "\\vec{OH}", {"at": 4, "ls": -1})]
	var st2 := [
		_j("審判一", "\\vec{BH} · \\vec{AC} = \\vec{CH} · \\vec{AB}", true, "兩邊都是 0：\\vec{BH} ⊥ \\vec{AC}、\\vec{CH} ⊥ \\vec{AB}。", "兩邊都是 0", T_CTR),
		_j("審判二", "\\vec{AH} · \\vec{AB} = \\vec{AC} · \\vec{AB}", true, "移到同一邊：(\\vec{AH} − \\vec{AC}) · \\vec{AB} = \\vec{CH} · \\vec{AB} = 0。", "\\vec{CH} · \\vec{AB} = 0", T_CTR),
		_j("審判三", "\\vec{AO} · \\vec{AB} = \\vec{AO} · \\vec{AC}", false, "左邊是 \\frac{1}{2}|\\vec{AB}|^{2}、右邊是 \\frac{1}{2}|\\vec{AC}|^{2}：要 \\ol{AB} = \\ol{AC} 才相等。", "\\vec{AO} · \\vec{AB} = \\frac{1}{2}|\\vec{AB}|^{2}，不一定相等", T_CTR),
		_j("審判四", "\\vec{OH} · \\vec{AB} = \\vec{OH} · \\vec{AC}", false, "\\vec{OH} = \\vec{OA} + \\vec{OB} + \\vec{OC}，兩邊不一定一樣（畫面上的三角形就不相等）。", "不一定相等", T_CTR)]
	vars.append({"eq": "△ABC 的垂心是 H、外心是 O\n下面哪些一定正確？", "plane": _plane([-1.6, 7.6], [-0.8, 4.6], s2), "steps": st2})
	return {"id": "ccards", "chapter": 1, "type": "forge", "title": "四心的審判",
		"story": "外心的影子、垂心的陽光，判斷哪些成立。",
		"insight": "外心：\\vec{AO} · \\vec{AB} = \\frac{1}{2}|\\vec{AB}|^{2}（影子落在中點）\n垂心：\\vec{AH} · \\vec{BC} = 0，三條高各一個式子。",
		"variants": vars}


## 9 外心和垂心的計算（A72、A73、A74）
static func _calc() -> Dictionary:
	var vars := []
	# 變化 A：AB = 4、AC = 6、∠A = 60°
	var A := Vector2.ZERO
	var B := Vector2(4, 0)
	var C := Vector2(3, 3.0 * sqrt(3.0))
	var K := B / 6.0 + C * (4.0 / 9.0)
	var D := B * (3.0 / 11.0) + C * (8.0 / 11.0)
	var H := B * (2.0 / 3.0) + C / 9.0
	var sa := [_poly([A, B, C], "dim")]
	sa += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [8, -4]})
	sa += [_ar(A, K, "pink", "", {"at": 2}), _shadow(A, K, B, {"at": 2}), _shadow(A, K, C, {"at": 2}), _fire(K, "pink", 2, {"s": "K", "off": [-20, -4]}),
		_seg(K, D, "pink", {"at": 3, "dash": true}), _dot(D, "D", "pink", {"at": 3, "off": [8, -2]}),
		_seg(A, B + (C - B) * ((A - B).dot(C - B) / (C - B).length_squared()), "lime", {"at": 4, "dash": true}),
		_seg(B, C * ((B).dot(C) / C.length_squared()), "lime", {"at": 4, "dash": true}), _seg(C, Vector2(C.x, 0), "lime", {"at": 4, "dash": true}),
		_fire(H, "lime", 4, {"s": "H", "off": [12, 6]})]
	vars.append({"eq": "△ABC 中，\\ol{AB} = 4，\\ol{AC} = 6，\\ol{BC} = 2√7，K 是外心、H 是垂心\n\\vec{AK} = α\\vec{AB} + β\\vec{AC}，\\vec{AH} = u\\vec{AB} + v\\vec{AC}，\\ol{AK} 交 \\ol{BC} 於 D",
		"plane": _plane([-1.6, 7.6], [-0.9, 5.8], sa),
		"steps": [
			_f("基底的內積", "三邊求 \\vec{AB} · \\vec{AC}", "\\vec{AB} · \\vec{AC} = [0]", ["12"], "28 = 16 − 2\\vec{AB} · \\vec{AC} + 36 ⇒ \\vec{AB} · \\vec{AC} = 12（∠A = 60°）",
				"|\\vec{BC}|^{2} = |\\vec{AC} − \\vec{AB}|^{2}。", T_CTR),
			_f("外心", "影子落在中點：\\vec{AK} · \\vec{AB} = 8、\\vec{AK} · \\vec{AC} = 18", "(α, β) = ([0], [1])", ["1/6", "4/9"],
				"16α + 12β = 8、12α + 36β = 18 ⇒ (α, β) = (\\frac{1}{6}, \\frac{4}{9})", "\\vec{AK} · \\vec{AB} = 16α + 12β，\\vec{AK} · \\vec{AC} = 12α + 36β。", T_CTR),
			_f("D", "D 在 BC 上：係數和 = 1", "\\vec{AD} = [0]\\vec{AB} + [1]\\vec{AC}", ["3/11", "8/11"],
				"\\vec{AD} = \\frac{18}{11}\\vec{AK} = \\frac{3}{11}\\vec{AB} + \\frac{8}{11}\\vec{AC}", "α : β 不變，加起來變成 1。", T_CTR),
			_f("垂心", "\\vec{AH} = \\vec{AB} + \\vec{AC} − 2\\vec{AK}", "(u, v) = ([0], [1])", ["2/3", "1/9"],
				"\\vec{OH} = \\vec{OA} + \\vec{OB} + \\vec{OC} ⇒ \\vec{AH} = \\vec{AB} + \\vec{AC} − 2\\vec{AK} = \\frac{2}{3}\\vec{AB} + \\frac{1}{9}\\vec{AC}", "1 − 2 × \\frac{1}{6}、1 − 2 × \\frac{4}{9}。", T_CTR),
		]})
	# 變化 B：AB = 6、AC = 4、BC = 5，角平分線和中垂線
	var Ab := Vector2.ZERO
	var Bb := Vector2(6, 0)
	var Cb := Vector2(2.25, 4.0 * sqrt(1.0 - 81.0 / 256.0))
	var Db := Bb * 0.4 + Cb * 0.6
	var Pb := Db * 0.8
	var Eb := Cb * (12.0 / 17.0)
	var sb := [_poly([Ab, Bb, Cb], "dim")]
	sb += _dots({"A": Ab, "B": Bb, "C": Cb}, "text", {"A": [-14, 14], "B": [6, 14], "C": [-4, -12]})
	sb += [_seg(Vector2(3, -0.6), Vector2(3, 4.2), "faint", {"dash": true}), _dot(Db, "D", "dim", {"off": [8, -2]}), _seg(Ab, Db, "cyan"),
		_dot(Pb, "P", "gold", {"at": 2, "off": [8, 4]}), _seg(Bb, Eb, "gold", {"at": 3}), _dot(Eb, "E", "gold", {"at": 3, "off": [-16, -4]}),
		_ruler(Ab, Cb, 17, 12, 3, {"c": "gold"})]
	vars.append({"eq": "△ABC 中，\\ol{AB} = 6，\\ol{AC} = 4，\\ol{BC} = 5，∠A 的平分線交 \\ol{BC} 於 D\n\\ol{AB} 的中垂線交 \\ol{AD} 於 P，\\ol{BP} 延長交 \\ol{AC} 於 E",
		"plane": _plane([-1.4, 7.4], [-0.9, 4.4], sb),
		"steps": [
			_f("角平分線", "\\ol{BD} : \\ol{DC} = \\ol{AB} : \\ol{AC}", "\\vec{AD} = [0]\\vec{AB} + [1]\\vec{AC}", ["2/5", "3/5"], "\\ol{BD} : \\ol{DC} = 3 : 2 ⇒ \\vec{AD} = \\frac{2}{5}\\vec{AB} + \\frac{3}{5}\\vec{AC}", "係數交叉。", T_CTR),
			_f("中垂線", "\\vec{AP} = k\\vec{AD}，\\vec{AP} · \\vec{AB} = 18", "\\vec{AP} = [0]\\vec{AB} + [1]\\vec{AC}", ["8/25", "12/25"],
				"\\vec{AD} · \\vec{AB} = \\frac{45}{2} ⇒ k = \\frac{4}{5}，\\vec{AP} = \\frac{8}{25}\\vec{AB} + \\frac{12}{25}\\vec{AC}",
				"\\vec{AB} · \\vec{AC} = \\frac{27}{2}。P 在中垂線上：影子落在 \\ol{AB} 中點，\\vec{AP} · \\vec{AB} = \\frac{1}{2} × 36。", T_CTR),
			_f("比", "B、P、E 共線", "\\ol{AE} : \\ol{EC} = [0] : [1]", ["12", "5"], "\\vec{AP} = \\frac{8}{25}\\vec{AB} + \\frac{12}{25}\\vec{AC}，E 在 AC 上：\\vec{AE} = \\frac{12}{17}\\vec{AC}，12 : 5",
				"\\vec{AC} 換成 \\vec{AE}：係數和 = 1。", T_CTR, "prop"),
		]})
	# 變化 C：A(1, 1)、B(1, 7)、C(9, 1)
	var Ac := Vector2(1, 1)
	var Bc := Vector2(1, 7)
	var Cc := Vector2(9, 1)
	var sc := [_poly([Ac, Bc, Cc], "dim")]
	sc += _dots({"A": Ac, "B": Bc, "C": Cc}, "text", {"A": [-14, 14], "B": [-14, -4], "C": [6, 14]})
	sc += [_fire(Vector2(11.0 / 3.0, 3), "gold", 1, {"s": "G", "off": [12, 6]}), _fire(Vector2(3, 3), "cyan", 2, {"s": "I", "off": [-20, -4]}), {"k": "circle", "o": [3, 3], "r": 2, "c": "cyan", "at": 2},
		_fire(Ac, "lime", 3, {"s": "H", "off": [14, -12]}), _fire(Vector2(5, 4), "pink", 4, {"s": "O", "off": [12, -2]})]
	var stc := [
		_j("審判一", "重心是 (\\frac{11}{3}, 3)", true, "三個頂點的平均：(\\frac{1 + 1 + 9}{3}, \\frac{1 + 7 + 1}{3})。", "重心 (\\frac{11}{3}, 3)", T_GC),
		_j("審判二", "內心是 (3, 3)", true, "直角三角形：內切圓半徑 = \\frac{6 + 8 − 10}{2} = 2，從 A 往兩股各走 2。", "內心 (3, 3)", T_CTR),
		_j("審判三", "垂心是 (5, 4)", false, "直角三角形的垂心是直角頂點 A(1, 1)。(5, 4) 是外心。", "垂心是 A(1, 1)", T_CTR),
		_j("審判四", "外心是 (5, 4)", true, "直角三角形的外心是斜邊 \\ol{BC} 的中點。", "外心 (5, 4)", T_CTR)]
	vars.append({"eq": "△ABC 的三個頂點是 A(1, 1)、B(1, 7)、C(9, 1)\n下面哪些正確？", "plane": _axes([-1.5, 11.5], [-0.8, 8.2], sc), "steps": stc})
	return {"id": "calc", "chapter": 1, "type": "forge", "title": "外心和垂心的計算",
		"story": "外心的影子落在中點，垂心用歐拉的關係求。",
		"insight": "外心：\\vec{AK} · \\vec{AB} = \\frac{1}{2}|\\vec{AB}|^{2}、\\vec{AK} · \\vec{AC} = \\frac{1}{2}|\\vec{AC}|^{2}，聯立\n垂心：\\vec{AH} = \\vec{AB} + \\vec{AC} − 2\\vec{AK}（\\vec{OH} = \\vec{OA} + \\vec{OB} + \\vec{OC}）。",
		"variants": vars}


# ======================= 第二章．面積比 =======================

## 11 三分花圃（新）
static func _split_garden() -> Dictionary:
	var vars := []
	for cfg in [{"B": Vector2(6, 0), "C": Vector2(0, 6), "eq": Vector2(2, 2), "P": Vector2(2, 3), "r": "1 : 2 : 3", "w": ["1", "2", "3", "6"], "x": [-2.0, 9.5], "y": [-1.0, 7.0]},
			{"B": Vector2(6, 0), "C": Vector2(0, 9), "eq": Vector2(2, 3), "P": Vector2(2, 4), "r": "2 : 3 : 4", "w": ["2", "3", "4", "9"], "x": [-2.5, 11.5], "y": [-1.0, 10.0]}]:
		var A := Vector2.ZERO
		var B: Vector2 = cfg.B
		var C: Vector2 = cfg.C
		var shapes := [_poly([A, B, C], "text")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [8, -4]})
		shapes += [_fire(cfg.eq, "gold", 1, {"until": 2, "s": "G", "off": [12, -2]}), _split(cfg.P, A, B, C, 2), _dot(cfg.P, "P", "gold", {"at": 2, "off": [8, -6]})]
		var sbx := func(lit: Vector2) -> Dictionary:
			return {"label": "P", "split": [_p(A), _p(B), _p(C)], "lit": [_p(lit)], "start": [1, 1], "read": _split_read(A, B, C), "read_at": "br"}
		var w: Array = cfg.w
		vars.append({"eq": "花圃 A(0, 0)、B%s、C%s，從 P 拉線到三個頂點\n分成 △PBC、△PCA、△PAB 三塊" % [_pt(B), _pt(C)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "一樣大", "q": "拖 P，讓三塊一樣大", "sandbox": sbx.call(cfg.eq), "goal": "lit", "ans": _p(cfg.eq), "tag": T_AREA, "big": true,
				 "nudge": "看左上角三塊的面積。", "line": "三塊一樣大：P%s 是重心" % _pt(cfg.eq)},
				{"kind": "vplace", "name": cfg.r, "q": "拖 P，讓三塊是 %s" % cfg.r, "sandbox": sbx.call(cfg.P), "goal": "lit", "ans": _p(cfg.P), "tag": T_AREA, "big": true,
				 "nudge": "△PAB 的高是 P 的 y 坐標，△PCA 的高是 P 的 x 坐標。", "line": "△PBC : △PCA : △PAB = %s：P%s" % [cfg.r, _pt(cfg.P)]},
				_f("權重", "P 是三個頂點的加權平均", "[3]P = [0]A + [1]B + [2]C", w,
					"%sP = %s：權重就是對面那一塊的面積" % [w[3], _wsum(w)], "A 的權重 = A 對面那一塊（△PBC）。", T_AREA, "prop"),
			]})
	return {"id": "garden", "chapter": 2, "type": "forge", "title": "三分花圃",
		"story": "從 P 拉三條線，把花圃分成三塊。",
		"insight": "△PBC : △PCA : △PAB = w_{A} : w_{B} : w_{C} ⇔ P = \\frac{w_{A}A + w_{B}B + w_{C}C}{w_{A} + w_{B} + w_{C}}\n頂點的權重 = 對面那一塊的面積。",
		"variants": vars}


## 12 一樣高的花圃（新）
static func _same_height() -> Dictionary:
	var A := Vector2(0, 5)
	var B := Vector2(-5, 0)
	var C := Vector2(5, 0)
	var vars := []
	for cfg in [{"s": 0.4, "step": 0.1, "ratio": "2 : 3", "ad": ["3/5", "2/5"], "r": ["2", "5"]},
			{"s": 0.75, "step": 0.25, "ratio": "3 : 1", "ad": ["1/4", "3/4"], "r": ["3", "4"]}]:
		var s: float = cfg.s
		var D := B.lerp(C, s)
		var dx := "-5 + 10 * s"
		var lines := [{"k": "dot", "p": [dx, "0"], "c": "gold", "s": "D"}, {"k": "seg", "a": [0, 5], "b": [dx, "0"], "c": "gold"},
			{"k": "poly", "pts": [[0, 5], [-5, 0], [dx, "0"]], "c": "cyan", "fill": "cyan", "alpha": 0.18}]
		var shapes := [_poly([A, B, C], "text"), _seg(A, Vector2(0, 0), "faint", {"dash": true})]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-4, -12], "B": [-16, 4], "C": [8, 4]})
		shapes += [_seg(A, D, "gold", {"at": 1}), _dot(D, "D", "gold", {"at": 1, "off": [-4, 18]}), _poly([A, B, D], "cyan", {"at": 1, "fill": "cyan", "alpha": 0.18}),
			_ar(A, B, "cyan", "", {"at": 2, "w": 2.0}), _ar(A, C, "pink", "", {"at": 2, "w": 2.0})]
		var ad: Array = cfg.ad
		var r: Array = cfg.r
		vars.append({"eq": "D 在 \\ol{BC} 上，△ABD 和 △ADC 一樣高\n△ABD : △ADC = %s，\\vec{AD} 和面積有什麼關係？" % cfg.ratio,
			"plane": _plane([-7.0, 7.0], [-1.0, 6.0], shapes),
			"steps": [
				{"kind": "slide", "name": "拖 D", "q": "拖 D，讓 △ABD : △ADC = %s" % cfg.ratio, "tag": T_AREA, "big": true,
				 "params": [{"n": "s", "min": 0, "max": 1, "step": cfg.step, "v": 0.5}], "lines": lines, "goal": {"s": s},
				 "eq": "△ABD : △ADC = {25 * s} : {25 - 25 * s}", "line": "△ABD : △ADC = \\ol{BD} : \\ol{DC} = %s（高一樣）" % cfg.ratio, "nudge": "高一樣：面積比就是底的比。"},
				_f("分點", "\\vec{AD} 換成基底", "\\vec{AD} = [0]\\vec{AB} + [1]\\vec{AC}", ad, "\\vec{AD} = %s" % B1._lin(ad[0], "AB", ad[1], "AC"), "係數交叉。", T_AREA),
				_f("佔全部", "△ABD : △ABC", "△ABD : △ABC = [0] : [1]", r, "△ABD : △ABC = %s : %s（就是 \\vec{AC} 的係數 %s）" % [r[0], r[1], B1._frs(ad[1])], "底 \\ol{BD} 佔 \\ol{BC} 的多少？", T_AREA, "prop"),
			]})
	return {"id": "height", "chapter": 2, "type": "forge", "title": "一樣高的花圃",
		"story": "一樣高的兩塊花圃，面積比就是底的比。",
		"insight": "同高的三角形：面積比 = 底的比\n\\vec{AD} = x\\vec{AB} + y\\vec{AC}（D 在 BC 上）：△ABD 佔 △ABC 的 y。",
		"variants": vars}


## 13 係數就是高（A75）
static func _coef_height() -> Dictionary:
	var A := Vector2.ZERO
	var B := Vector2(6, 0)
	var C := Vector2(2, 5)
	var vars := []
	for cfg in [{"x": "1/5", "y": "2/5", "z": "2/5"}, {"x": "1/2", "y": "1/6", "z": "1/3"}]:
		var x := B1._frv(cfg.x)
		var y := B1._frv(cfg.y)
		var P := B * x + C * y
		var shapes := [_poly([A, B, C], "text")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [-4, -12]})
		shapes += [_dot(P, "P", "gold", {"off": [8, -6]}), _seg(A, P, "faint"), _seg(B, P, "faint"), _seg(C, P, "faint"),
			_poly([A, B, P], "lime", {"at": 1, "fill": "lime", "alpha": 0.22}), _seg(P, Vector2(P.x, 0), "lime", {"at": 1, "dash": true}), _seg(C, Vector2(C.x, 0), "faint", {"at": 1, "dash": true}),
			_poly([A, C, P], "pink", {"at": 2, "fill": "pink", "alpha": 0.22}), _poly([B, C, P], "cyan", {"at": 3, "fill": "cyan", "alpha": 0.22})]
		vars.append({"eq": "P 在 △ABC 內，\\vec{AP} = %s\\vec{AB} + %s\\vec{AC}\n求 △ABP、△ACP、△BCP 各佔 △ABC 的多少" % [B1._frs(cfg.x), B1._frs(cfg.y)],
			"plane": _plane([-1.2, 9.0], [-0.8, 5.8], shapes),
			"steps": [
				_f("△ABP", "P 到 AB 的高是 C 的幾倍", "\\frac{△ABP}{△ABC} = [0]", [cfg.y], "△ABP 佔 %s（\\vec{AC} 的係數）" % B1._frs(cfg.y), "沿 \\vec{AB} 走不會變高，只有 \\vec{AC} 那一段讓 P 升高。", T_AREA),
				_f("△ACP", "P 到 AC 的距離", "\\frac{△ACP}{△ABC} = [0]", [cfg.x], "△ACP 佔 %s（\\vec{AB} 的係數）" % B1._frs(cfg.x), "換成 AC 當底：看 \\vec{AB} 的係數。", T_AREA),
				_f("△BCP", "剩下的", "\\frac{△BCP}{△ABC} = [0]", [cfg.z], "△BCP 佔 1 − %s − %s = %s" % [B1._frs(cfg.x), B1._frs(cfg.y), B1._frs(cfg.z)], "三塊加起來是整個。", T_AREA),
			]})
	return {"id": "coefh", "chapter": 2, "type": "forge", "title": "係數就是高",
		"story": "係數告訴你 P 離每一條邊有多高。",
		"insight": "\\vec{AP} = x\\vec{AB} + y\\vec{AC}：△ABP = y△ABC、△ACP = x△ABC\n△BCP = (1 − x − y)△ABC。",
		"variants": vars}


## 14 三條繩子拉花圃（新）
static func _pull_split() -> Dictionary:
	var vars := []
	for cfg in [{"w": [1, 2, 3], "A": Vector2(6, 0), "B": Vector2(0, 6), "P": Vector2(1, 2), "eq": "\\vec{PA} + 2\\vec{PB} + 3\\vec{PC} = \\vec{0}", "x": [-2.5, 9.5], "y": [-1.0, 7.0]},
			{"w": [2, 3, 4], "A": Vector2(9, 0), "B": Vector2(0, 9), "P": Vector2(2, 3), "eq": "2\\vec{PA} + 3\\vec{PB} + 4\\vec{PC} = \\vec{0}", "x": [-3.0, 13.0], "y": [-1.0, 10.0]}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var C := Vector2.ZERO
		var P: Vector2 = cfg.P
		var w: Array = cfg.w
		var shapes := [_poly([A, B, C], "text")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [6, 14], "B": [8, -4], "C": [-14, 14]})
		shapes += [_split(P, A, B, C, 1), _dot(P, "P", "gold", {"at": 1, "off": [8, -6]})]
		vars.append({"eq": "A%s、B%s、C(0, 0)，%s\n求 △PBC : △PCA : △PAB" % [_pt(A), _pt(B), cfg.eq],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "拉平衡", "q": "拖 P，讓三條繩子拉平衡", "tag": T_AREA, "goal": "lit", "ans": _p(P), "big": true,
				 "sandbox": {"label": "P", "lit": [_p(P)], "pull": _pull([A, B, C], w), "split": [_p(A), _p(B), _p(C)], "start": [3, 1], "read": _split_read(A, B, C), "read_at": "br"},
				 "nudge": "金色的合力指向該去的地方。", "line": "P%s：三條繩子拉平衡" % _pt(P)},
				_f("面積比", "看三塊花圃", "△PBC : △PCA : △PAB = [0] : [1] : [2]", [str(w[0]), str(w[1]), str(w[2])],
					"△PBC : △PCA : △PAB = %d : %d : %d：就是權重" % w, "左上角的讀數約分。", T_AREA, "prop"),
			]})
	return {"id": "pullsplit", "chapter": 2, "type": "forge", "title": "三條繩子拉花圃",
		"story": "繩子拉得越用力，對面那一塊花圃越大。",
		"insight": "w_{A}\\vec{PA} + w_{B}\\vec{PB} + w_{C}\\vec{PC} = \\vec{0} ⇒ △PBC : △PCA : △PAB = w_{A} : w_{B} : w_{C}\n權重大的頂點，P 離它比較近，對面那一塊比較大。",
		"variants": vars}


## 15 照面積放營火（A76）
static func _place_by_area() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(0, 4), "B": Vector2(-3, -2), "C": Vector2(6, 1), "r": "1 : 2 : 3", "w": ["2", "3", "1", "6"], "P": ["-1/2", "1/2"], "x": [-5.5, 8.5], "y": [-3.0, 5.0]},
			{"A": Vector2(2, 5), "B": Vector2(-2, -1), "C": Vector2(6, -3), "r": "2 : 1 : 1", "w": ["1", "1", "2", "4"], "P": ["3", "-1/2"], "x": [-4.5, 9.5], "y": [-4.0, 6.0]}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var C: Vector2 = cfg.C
		var w: Array = cfg.w
		var P := _wavg([float(w[0]), float(w[1]), float(w[2])], [A, B, C])
		var shapes := [_poly([A, B, C], "text")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-4, -12], "B": [-16, 4], "C": [8, 4]})
		shapes += [_split(P, A, B, C, 2), _dot(P, "P", "gold", {"at": 2, "off": [8, -6]})]
		vars.append({"eq": "A%s、B%s、C%s，P 在 △ABC 內\n△PAB : △PBC : △PCA = %s，求 P" % [_pt(A), _pt(B), _pt(C), cfg.r],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("權重", "A 的權重是對面 △PBC", "[3]P = [0]A + [1]B + [2]C", w,
					"%sP = %s（A ↔ △PBC、B ↔ △PCA、C ↔ △PAB）" % [w[3], _wsum(w)],
					"題目的順序是 △PAB、△PBC、△PCA，要對到對面的頂點：△PAB 對 C。", T_AREA, "prop"),
				_f("P", "加權平均", "P = ([0], [1])", cfg.P, "P = %s" % _pt(P), "x 坐標、y 坐標各自加權平均。", T_AREA),
			]})
	return {"id": "byarea", "chapter": 2, "type": "forge", "title": "照面積放營火",
		"story": "三塊花圃的比知道了，營火放在哪裡？",
		"insight": "△PBC : △PCA : △PAB = w_{A} : w_{B} : w_{C} ⇒ P = \\frac{w_{A}A + w_{B}B + w_{C}C}{w_{A} + w_{B} + w_{C}}\n小心題目的順序：每一塊對到它對面的頂點。",
		"variants": vars}


## 16 面積比反推係數（新）
static func _reverse() -> Dictionary:
	var A := Vector2.ZERO
	var B := Vector2(6, 0)
	var C := Vector2(2, 5)
	var vars := []
	for cfg in [{"r": [1, 2, 3], "xy": ["1/3", "1/2"]}, {"r": [3, 4, 5], "xy": ["1/3", "5/12"]}]:
		var r: Array = cfg.r
		var s: int = r[0] + r[1] + r[2]
		var P := _wavg([float(r[0]), float(r[1]), float(r[2])], [A, B, C])
		var shapes := [{"k": "skew", "o": [0, 0], "a": _p(B), "b": _p(C), "i": [0, 1], "j": [0, 1], "div": 12, "c": "cyan", "at": 2}, _poly([A, B, C], "text")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [-4, -12]})
		shapes += [_split(P, A, B, C, 2), _dot(P, "P", "gold", {"at": 2, "off": [8, -6]})]
		vars.append({"eq": "P 在 △ABC 內，△PBC : △PCA : △PAB = %d : %d : %d\n\\vec{AP} = x\\vec{AB} + y\\vec{AC}，求 (x, y)" % r,
			"plane": _plane([-1.2, 9.0], [-0.8, 5.8], shapes),
			"steps": [
				_f("權重", "對面的那一塊", "[3]P = [0]A + [1]B + [2]C", [str(r[0]), str(r[1]), str(r[2]), str(s)],
					"%dP = %s" % [s, _wsum([str(r[0]), str(r[1]), str(r[2])])], "A 的權重是 △PBC。", T_AREA, "prop"),
				_f("係數", "以 A 為起點", "\\vec{AP} = [0]\\vec{AB} + [1]\\vec{AC}", cfg.xy,
					"\\vec{AP} = \\frac{%d}{%d}\\vec{AB} + \\frac{%d}{%d}\\vec{AC} = %s" % [r[1], s, r[2], s, B1._lin(cfg.xy[0], "AB", cfg.xy[1], "AC")],
					"P − A = \\frac{%d(B − A) + %d(C − A)}{%d}。" % [r[1], r[2], s], T_AREA),
			]})
	return {"id": "reverse", "chapter": 2, "type": "forge", "title": "面積比反推係數",
		"story": "知道三塊花圃的比，反推 P 的斜地址。",
		"insight": "△PBC : △PCA : △PAB = a : b : c ⇒ \\vec{AP} = \\frac{b}{a + b + c}\\vec{AB} + \\frac{c}{a + b + c}\\vec{AC}\n和第 13 題反過來：係數就是對面那兩塊佔全部的比。",
		"variants": vars}


## 17 四心的花圃（新）
static func _center_areas() -> Dictionary:
	var A := Vector2.ZERO
	var B := Vector2(6, 0)
	var C := Vector2(0, 8)
	var G := (A + B + C) / 3.0
	var I := Vector2(2, 2)
	var O := Vector2(3, 4)
	var base := [_poly([A, B, C], "text")]
	base += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-14, 14], "B": [6, 14], "C": [8, -4]})
	var vars := []
	var s1 := base.duplicate()
	s1 += [_split(G, A, B, C, 1, {"until": 2}), _fire(G, "gold", 1, {"s": "G", "off": [12, -4]}), _split(I, A, B, C, 2, {"until": 4}), _fire(I, "cyan", 2, {"s": "I", "off": [12, 8]}),
		_split(O, A, B, C, 4), _fire(O, "pink", 4, {"s": "O", "off": [12, -2]})]
	var st1 := [
		_j("審判一", "G 是重心 ⇒ △GBC : △GCA : △GAB = 1 : 1 : 1", true, "\\vec{GA} + \\vec{GB} + \\vec{GC} = \\vec{0}：權重都是 1。", "重心：三塊一樣大", T_AREA),
		_j("審判二", "I 是內心 ⇒ △IBC : △ICA : △IAB = \\ol{BC} : \\ol{CA} : \\ol{AB}", true, "三塊的高都是內切圓半徑，面積比 = 底的比。", "內心：面積比 = 三邊的比", T_AREA),
		_j("審判三", "I 是內心 ⇒ △IBC : △ICA : △IAB = \\ol{AB} : \\ol{BC} : \\ol{CA}", false, "△IBC 的底是 \\ol{BC}，不是 \\ol{AB}：每一塊對自己的底。", "順序要對：△IBC 對 \\ol{BC}", T_AREA),
		_j("審判四", "直角三角形的外心 O ⇒ △OAB = △OAC", true, "O 是斜邊 \\ol{BC} 的中點：\\ol{AO} 是中線，平分面積。", "外心在斜邊中點：△OAB = △OAC", T_AREA)]
	vars.append({"eq": "△ABC 中，A(0, 0)、B(6, 0)、C(0, 8)，四心把它分成三塊\n下面哪些正確？", "plane": _plane([-1.5, 9.5], [-0.8, 8.6], s1), "steps": st1})
	var s2 := base.duplicate()
	s2 += [_split(G, A, B, C, 1, {"until": 2}), _fire(G, "gold", 1, {"s": "G", "off": [12, -4]}), _split(I, A, B, C, 2, {"until": 3}), _fire(I, "cyan", 2, {"s": "I", "off": [12, 8]}),
		_split(O, A, B, C, 3, {"until": 4}), _fire(O, "pink", 3, {"s": "O", "off": [12, -2]})]
	var st2 := [
		_j("審判一", "G 是重心 ⇒ △GAB = \\frac{1}{3}△ABC", true, "重心的三塊一樣大。", "△GAB = \\frac{1}{3}△ABC", T_AREA),
		_j("審判二", "I 是內心 ⇒ \\ol{BC}\\vec{IA} + \\ol{CA}\\vec{IB} + \\ol{AB}\\vec{IC} = \\vec{0}", true, "權重 = 對面那一塊 = 對邊長。", "內心的權重是對邊長", T_CTR),
		_j("審判三", "O 是外心 ⇒ △OBC : △OCA : △OAB = \\ol{BC} : \\ol{CA} : \\ol{AB}", false, "那是內心。外心的三塊不一定是三邊的比（畫面上就不是）。", "外心的面積比不是三邊的比", T_AREA),
		_j("審判四", "正三角形的四心是同一點", true, "正三角形每一條中線也是角平分線、中垂線、高。", "正三角形四心合一", T_CTR)]
	vars.append({"eq": "△ABC 中，A(0, 0)、B(6, 0)、C(0, 8)\n下面哪些正確？", "plane": _plane([-1.5, 9.5], [-0.8, 8.6], s2), "steps": st2})
	return {"id": "careas", "chapter": 2, "type": "forge", "title": "四心的花圃",
		"story": "四座營火把花圃分成三塊，各是多少？",
		"insight": "重心：1 : 1 : 1。內心：三邊的比（每一塊對自己的底）\n權重 = 對面那一塊的面積。",
		"variants": vars}
