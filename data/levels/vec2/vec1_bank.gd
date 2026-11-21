extends RefCounted
## 平面向量 第一大關「風向台」題庫（上冊 3-1 重點一、二：向量的意義、線性組合、分點公式）
## 設計稿：docs/vec2_v1_design.md。數字都用程式驗算過（tools/vec2/verify_v1.py）。
##
## 引擎見 vec_level.gd（在箭頭畫布上作答：vtap、vpick、vdrag、vpath、vplace、vweigh，加上滑桿、填空、選擇）。
## 每一題的 "plane" 是箭頭畫布（寫法見 vec_board.gd）。要學生找的點、鋪的路，答對之後才出現（design_rules 1.5）。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/num/num1_bank.gd")

const T_EQ := "vec_equal"         # 相等向量（長度、方向）
const T_ADD := "vec_add"          # 加法、減法（首尾相接、終點減起點）
const T_LIN := "vec_lincomb"      # 用兩個向量表示（線性組合）
const T_PARA := "vec_parallel"    # 係數積與平行、平行四邊形的判定
const T_IND := "vec_indep"        # 不共線時係數唯一
const T_DIV := "vec_divide"       # 分點公式
const T_DAPP := "vec_divapp"      # 分點的應用（角平分線、內切圓、垂足、面積比）


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	var st := SB.fill(name, q, template, answers, line, nudge, tag, mode)
	st["paren"] = true
	return st


static func _j(name: String, statement: String, ok: bool, why: String, line: String, tag: String) -> Dictionary:
	return B1._j(name, statement, ok, why, line, tag)


# ---------------- 圖層 ----------------

static func _p(v: Vector2) -> Array:
	return [v.x, v.y]


static func _ar(a: Vector2, b: Vector2, c := "cyan", s := "", extra := {}) -> Dictionary:
	var d := {"k": "arrow", "a": _p(a), "b": _p(b), "c": c}
	if s != "":
		d["s"] = s
	d.merge(extra, true)
	return d


static func _dot(p: Vector2, s: String, c := "gold", extra := {}) -> Dictionary:
	var d := {"k": "dot", "p": _p(p), "s": s, "c": c}
	d.merge(extra, true)
	return d


static func _tag(p: Vector2, s: String, c := "text", extra := {}) -> Dictionary:
	var d := {"k": "tag", "p": _p(p), "s": s, "c": c}
	d.merge(extra, true)
	return d


static func _seg(a: Vector2, b: Vector2, c := "dim", extra := {}) -> Dictionary:
	var d := {"k": "seg", "a": _p(a), "b": _p(b), "c": c}
	d.merge(extra, true)
	return d


static func _poly(pts: Array, c := "dim", extra := {}) -> Dictionary:
	var d := {"k": "poly", "pts": pts.map(func(q): return _p(q)), "c": c}
	d.merge(extra, true)
	return d


static func _walk(pts: Array, at: int, c := "gold", arrows := true, extra := {}) -> Dictionary:
	var d := {"k": "walk", "pts": pts.map(func(q): return _p(q)), "c": c, "arrows": arrows, "at": at}
	d.merge(extra, true)
	return d


static func _plane(x: Array, y: Array, shapes: Array, named := {}, extra := {}) -> Dictionary:
	var nm := {}
	for k in named.keys():
		nm[k] = _p(named[k])
	var d := {"x": x, "y": y, "grid": "plain", "shapes": shapes, "named": nm}
	d.merge(extra, true)
	return d


## 三角形、多邊形的頂點：每一個點都畫成有名字的點
static func _dots(pts: Dictionary, c := "text", offs := {}) -> Array:
	var out := []
	for k in pts.keys():
		out.append(_dot(pts[k], k, c, {"off": offs.get(k, [8, -8])}))
	return out


static func _fr(n: int, d: int) -> String:
	return str(n) if d == 1 else "%s\\frac{%d}{%d}" % ["−" if n < 0 else "", absi(n), d]


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
		_same(), _dex(), _detour(), _hexa(), _flag(), _bow(), _skew(), _locks(),
		{"id": "speed1", "chapter": 1, "type": "speed", "title": "風向速算", "time": 120.0,
		 "story": "斜格子上的風，看一眼就讀出係數！",
		 "insight": "\\vec{OP} = x\\vec{a} + y\\vec{b}：沿 \\vec{a} 走 x 格、沿 \\vec{b} 走 y 格\n往反方向走，係數就是負的。",
		 "variants": [{"gen": "skew", "count": 8}]},
		_bead(), _two_kites(), _trapezoid(), _fold(), _incircle(), _plumb(), _zoom(),
		{"id": "speed2", "chapter": 2, "type": "speed", "title": "珠子速算", "time": 120.0,
		 "story": "珠子落在繩橋上，係數交叉一下就好！",
		 "insight": "\\ol{BP} : \\ol{PC} = m : n ⇒ \\vec{AP} = \\frac{n}{m + n}\\vec{AB} + \\frac{m}{m + n}\\vec{AC}\n靠近 B，\\vec{AB} 的係數就大。",
		 "variants": [{"gen": "bead", "count": 8}]},
	]


# ======================= 第一章．風向台 =======================

## 1 同一陣風：點出相等的箭頭，再從 P 畫出 \vec{a}
static func _same() -> Dictionary:
	var vars := []
	for cfg in [
			{"a": Vector2(3, 1), "ref": [Vector2(-7, 1), Vector2(-4, 2)],
			 "arr": {"p": [Vector2(-3, -1), Vector2(0, 0)], "q": [Vector2(7, 3), Vector2(4, 2)], "r": [Vector2(-8, -3), Vector2(-2, -1)],
				"s": [Vector2(5, -3), Vector2(6, 0)], "t": [Vector2(1, -3), Vector2(4, -2)]},
			 "same": ["p", "t"], "bad": {"q": "rev", "r": "dbl", "s": "rot"}, "P": Vector2(-2, 2)},
			{"a": Vector2(-2, 3), "ref": [Vector2(-6, -3), Vector2(-8, 0)],
			 "arr": {"p": [Vector2(1, -2), Vector2(-1, 1)], "q": [Vector2(5, 0), Vector2(7, -3)], "r": [Vector2(8, -1), Vector2(6, 2)],
				"s": [Vector2(1, 1), Vector2(4, 3)], "t": [Vector2(-2, -3), Vector2(-6, 3)]},
			 "same": ["p", "r"], "bad": {"q": "rev", "t": "dbl", "s": "rot"}, "P": Vector2(3, -3)}]:
		var a: Vector2 = cfg.a
		var P: Vector2 = cfg.P
		var shapes := [_ar(cfg.ref[0], cfg.ref[1], "gold", "\\vec{a}", {"id": "a", "w": 3.5})]
		for id in cfg.arr.keys():
			shapes.append(_ar(cfg.arr[id][0], cfg.arr[id][1], "cyan", "", {"id": id}))
		shapes.append(_dot(P, "P", "pink"))
		shapes.append(_ar(P, P + a, "gold", "\\vec{a}", {"at": 2}))
		shapes.append(_walk([P, P + a], 2, "gold", false))
		var why_bad := {}
		for id in cfg.bad.keys():
			why_bad[id] = {"rev": "方向相反：頭尾反過來了。", "dbl": "方向一樣，可是長了一倍。",
				"rot": "一樣長，可是方向不一樣。"}[cfg.bad[id]]
		vars.append({"eq": "哪些箭頭和 \\vec{a} 是同一個向量？\n從 P 出發的 \\vec{a} 指到哪裡？",
			"plane": _plane([-9, 9], [-4, 4], shapes),
			"steps": [
				{"kind": "vtap", "name": "一樣的風", "q": "點出和 \\vec{a} 一樣的箭頭", "ref": "a", "targets": cfg.same,
				 "why_bad": why_bad, "tag": T_EQ, "nudge": "長度和方向都要一樣。",
				 "why": "兩支都和 \\vec{a} 完全疊合：長度、方向都一樣。",
				 "line": "相等向量：長度、方向都一樣，起點在哪裡都可以"},
				{"kind": "vpick", "name": "從 P 出發", "q": "從 P 畫出 \\vec{a}：點終點", "target": _p(P + a), "snap": 1,
				 "traps": [[P.x - a.x, P.y - a.y, "這是反方向：−\\vec{a}。"]], "tag": T_EQ,
				 "nudge": "數一數 \\vec{a} 橫的走幾格、直的走幾格。",
				 "line": "從 P 出發也是 \\vec{a}：向量可以平移"},
			]})
	return {"id": "same", "chapter": 1, "type": "forge", "title": "同一陣風",
		"story": "一支箭頭就是一陣風：往哪吹、吹多大。",
		"insight": "相等向量：長度一樣、方向一樣\n位置不重要：同一個向量可以從任何地方出發。",
		"variants": vars}


static func _n(v: float) -> String:
	var s := str(int(v)) if is_equal_approx(v, roundf(v)) else str(v)
	return s.replace("-", "−")


## 2 風羽圖鑑：數有幾個不同的向量（A1）
static func _dex() -> Dictionary:
	var A := Vector2(0, 0)
	var B := Vector2(4, 0)
	var C := Vector2(5, 3)
	var D := Vector2(1, 3)
	var O := Vector2(2.5, 1.5)
	var vars := []
	for with_o in [false, true]:
		var pts := {"A": A, "B": B, "C": C, "D": D}
		var offs := {"A": [-14, 14], "B": [6, 14], "C": [6, -6], "D": [-14, -6]}
		if with_o:
			pts["O"] = O
			offs["O"] = [8, 16]
		var shapes := [_poly([A, B, C, D], "faint")]
		if with_o:
			shapes.append(_seg(A, C, "faint", {"dash": true}))
			shapes.append(_seg(B, D, "faint", {"dash": true}))
		shapes.append_array(_dots(pts, "gold", offs))
		var pairs := [["AB", "DC"], ["BA", "CD"], ["AD", "BC"], ["DA", "CB"]]
		if with_o:
			pairs.append_array([["AO", "OC"], ["OA", "CO"], ["BO", "OD"], ["OB", "DO"]])
		var n := pts.size()
		var total := n * (n - 1)
		vars.append({"eq": ("平行四邊形 ABCD 和中心 O\n" if with_o else "平行四邊形 ABCD 的頂點\n") + "當起點、終點，有幾種向量？",
			"plane": _plane([-3, 8], [-0.9, 4.2], shapes, pts),
			"steps": [
				{"kind": "vdrag", "name": "疊疊看", "q": "拖 \\vec{AB}，找一樣的", "fixed": ["A", "B"], "need": 1,
				 "pairs": [["AB", "DC"]], "tag": T_EQ, "nudge": "整支平移，不能轉。",
				 "why": "\\vec{AB} 平移到 D 出發，剛好指到 C：\\vec{AB} = \\vec{DC}。",
				 "line": "\\vec{AB} = \\vec{DC}：平移之後完全疊合"},
				_f("幾支", "起點、終點各有幾種選法？", "[0] × [1] = [2]", [str(n), str(n - 1), str(total)],
					"起點 %d 種、終點 %d 種：%d × %d = %d 支箭頭" % [n, n - 1, n, n - 1, total],
					"起點 %d 個點選一個，終點不能和起點一樣。" % n, T_EQ),
				{"kind": "vdrag", "name": "找一樣的", "q": "點兩點畫箭頭，再拖去找", "need": pairs.size(), "pairs": pairs,
				 "seed": [["AB", "DC"]], "done_btn": true, "tag": T_EQ,
				 "nudge": "反方向的箭頭也找找看。" + ("中心 O 也可以當起點。" if with_o else ""),
				 "line": ("一樣的有 8 對，像 \\vec{AB} = \\vec{DC}、\\vec{AO} = \\vec{OC}" if with_o else
					"一樣的有 4 對：\\vec{AB} = \\vec{DC}、\\vec{AD} = \\vec{BC} 和反方向")},
				_f("幾種", "不同的向量有幾個？", "[0] − [1] = [2]", [str(total), str(pairs.size()), str(total - pairs.size())],
					"%d − %d = %d 個不同的向量" % [total, pairs.size(), total - pairs.size()],
					"每一對一樣的只能算一次。", T_EQ),
			]})
	vars[0]["steps"][1]["groups"] = [[0, 1]]
	vars[1]["steps"][1]["groups"] = [[0, 1]]
	return {"id": "dex", "chapter": 1, "type": "forge", "title": "風羽圖鑑",
		"story": "收集所有不一樣的風，一樣的只收一次。",
		"insight": "n 個點任取起點、終點：n(n − 1) 支箭頭\n平行四邊形裡 \\vec{AB} = \\vec{DC} 這種一樣的，只算一次。",
		"variants": vars}


## 3 逆風繞路：減法 \vec{CB} = \vec{AB} − \vec{AC}
static func _detour() -> Dictionary:
	var A := Vector2(-4, -2)
	var B := Vector2(3, -3)
	var C := Vector2(0, 3)
	var pts := {"A": A, "B": B, "C": C}
	var offs := {"A": [-16, 4], "B": [8, 12], "C": [8, -8]}
	var S := A + (B - A) + (C - A)
	var react := [_seg(B, S, "faint", {"dash": true, "at": 2}), _seg(C, S, "faint", {"dash": true, "at": 2}),
		_ar(A, S, "lime", "\\vec{AB} + \\vec{AC}", {"at": 2, "w": 2.5, "lt": 0.78})]
	var v1 := _plane([-8, 8], [-4, 4],
		[_ar(A, B, "cyan", "\\vec{AB}", {"ls": -1}), _ar(A, C, "pink", "\\vec{AC}")] + _dots(pts, "gold", offs) + react
			+ [_ar(C, B, "gold", "\\vec{AB} − \\vec{AC}", {"at": 2, "w": 2.5, "ls": -1, "lt": 0.25})], pts)
	var v2 := _plane([-8, 8], [-4, 4],
		[_ar(A, C, "pink", "\\vec{AC}"), _ar(B, C, "cyan", "\\vec{BC}", {"ls": -1})] + _dots(pts, "gold", offs)
			+ [_ar(A, B, "gold", "\\vec{AC} − \\vec{BC}", {"at": 2, "w": 2.5, "ls": -1})], pts)
	return {"id": "detour", "chapter": 1, "type": "forge", "title": "逆風繞路",
		"story": "只有兩種風，要飛回去就讓風掉頭。",
		"insight": "減法：\\vec{AB} − \\vec{AC} = \\vec{CB}（終點減起點，從減數的終點指到被減數的終點）\n加法：首尾相接，或以兩支為邊的平行四邊形對角線。",
		"variants": [
			{"eq": "只用 \\vec{AB}、\\vec{AC} 兩種風\n風箏怎麼從 C 飛到 B？", "plane": v1,
			 "steps": [
				{"kind": "vpath", "name": "鋪路", "q": "從 C 鋪到 B", "from": _p(C), "to": _p(B),
				 "tiles": [{"s": "\\vec{AB}", "v": _p(B - A)}, {"s": "\\vec{AC}", "v": _p(C - A)}], "sol": [[1, -1], [0, 1]],
				 "tag": T_ADD, "nudge": "先從 C 回到 A，再從 A 到 B。",
				 "line": "從 C 回到 A（−\\vec{AC}），再到 B（\\vec{AB}）"},
				_f("式子", "寫成式子", "\\vec{CB} = [0]\\vec{AC} + [1]\\vec{AB}", ["-1", "1"],
					"\\vec{CB} = \\vec{AB} − \\vec{AC}：終點減起點", "\\vec{AC} 掉頭是 −1 倍。", T_ADD),
			 ]},
			{"eq": "只用 \\vec{AC}、\\vec{BC} 兩種風\n風箏怎麼從 A 飛到 B？", "plane": v2,
			 "steps": [
				{"kind": "vpath", "name": "鋪路", "q": "從 A 鋪到 B", "from": _p(A), "to": _p(B),
				 "tiles": [{"s": "\\vec{AC}", "v": _p(C - A)}, {"s": "\\vec{BC}", "v": _p(C - B)}], "sol": [[0, 1], [1, -1]],
				 "tag": T_ADD, "nudge": "先從 A 到 C，再從 C 回到 B。",
				 "line": "從 A 到 C（\\vec{AC}），再回到 B（−\\vec{BC}）"},
				_f("式子", "寫成式子", "\\vec{AB} = [0]\\vec{AC} + [1]\\vec{BC}", ["1", "-1"],
					"\\vec{AB} = \\vec{AC} − \\vec{BC} = \\vec{AC} + \\vec{CB}", "\\vec{BC} 掉頭是 −1 倍。", T_ADD),
			 ]},
		]}


## 4 六角風場：正六邊形的審判卡，判完照式子走一遍（A3、A4）
static func _hexa() -> Dictionary:
	var H := {}
	var names := "ABCDEF"
	for i in 6:
		var ang := deg_to_rad(240.0 + 60.0 * i)
		H[names[i]] = Vector2(2.8 * cos(ang), 2.8 * sin(ang))
	H["O"] = Vector2.ZERO
	var offs := {"A": [-14, 14], "B": [6, 14], "C": [8, 4], "D": [6, -6], "E": [-14, -6], "F": [-18, 4]}
	var hex := [H.A, H.B, H.C, H.D, H.E, H.F]
	var base := [_poly(hex, "faint")]
	var vdots := _dots({"A": H.A, "B": H.B, "C": H.C, "D": H.D, "E": H.E, "F": H.F}, "gold", offs)
	var named := {"A": H.A, "B": H.B, "C": H.C, "D": H.D, "E": H.E, "F": H.F, "O": H.O}
	# ---- 變化 A：\vec{a} = \vec{AB}、\vec{b} = \vec{AF} ----
	var a: Vector2 = H.B - H.A
	var b: Vector2 = H.F - H.A
	var wa := func(st: Vector2, terms: Array) -> Array:      # 照式子走：[[係數, 向量], …] 一格一格走
		var out := [st]
		var p := st
		for tm in terms:
			var n := int(absf(float(tm[0])))
			var stp: Vector2 = tm[1] * signf(float(tm[0]))
			for k in n:
				p += stp
				out.append(p)
		return out
	var sa := base + [_tag(H.O, "O", "dim", {"off": [6, 14]}), _ar(H.A, H.B, "cyan", "\\vec{a}", {"ls": -1}),
		_ar(H.A, H.F, "pink", "\\vec{b}")] + vdots + [
		_walk(wa.call(H.A, [[2, a], [2, b]]), 1, "gold", true, {"until": 2}),
		_walk(wa.call(H.A, [[1, a], [2, b]]), 2, "gold", true, {"bad": true, "target": _p(H.C), "until": 3}),
		_walk(wa.call(H.C, [[1, b], [-1, a]]), 4, "gold", true, {"until": 5}),
		_walk(wa.call(H.B, [[-2, a]]), 5, "gold", true, {"bad": true, "target": _p(H.E), "until": 6})]
	var tiles_ab := [{"s": "\\vec{a}", "v": _p(a)}, {"s": "\\vec{b}", "v": _p(b)}]
	var va := {"eq": "正六邊形 ABCDEF，\\vec{a} = \\vec{AB}、\\vec{b} = \\vec{AF}\n下面哪些正確？",
		"plane": _plane([-7, 7], [-3.4, 3.4], sa, named),
		"steps": [
			_j("審判一", "\\vec{AD} = 2\\vec{a} + 2\\vec{b}", true,
				"\\vec{AO} = \\vec{a} + \\vec{b}，\\vec{AD} = 2\\vec{AO}。", "\\vec{AD} = 2\\vec{a} + 2\\vec{b}", T_LIN),
			_j("審判二", "\\vec{AC} = \\vec{a} + 2\\vec{b}", false,
				"照式子走會停在 E：\\vec{a} + 2\\vec{b} = \\vec{AE}。", "\\vec{AC} ≠ \\vec{a} + 2\\vec{b}（那是 \\vec{AE}）", T_LIN),
			{"kind": "vpath", "name": "鋪到 C", "q": "從 A 鋪到 C", "from": _p(H.A), "to": _p(H.C), "tiles": tiles_ab,
			 "sol": [[0, 1], [0, 1], [1, 1]], "tag": T_LIN, "nudge": "\\vec{BC} 和 \\vec{AO} 平行、一樣長。",
			 "line": "\\vec{AC} = 2\\vec{a} + \\vec{b}"},
			_j("審判三", "\\vec{CE} = \\vec{b} − \\vec{a}", true,
				"從 C 走 \\vec{b} 再退 \\vec{a}，剛好到 E。", "\\vec{CE} = \\vec{b} − \\vec{a}", T_LIN),
			_j("審判四", "\\vec{BE} = −2\\vec{a}", false,
				"\\vec{BE} 和 \\vec{AF} 平行：\\vec{BE} = 2\\vec{b}。", "\\vec{BE} ≠ −2\\vec{a}", T_LIN),
			{"kind": "vpath", "name": "鋪到 E", "q": "從 B 鋪到 E", "from": _p(H.B), "to": _p(H.E), "tiles": tiles_ab,
			 "sol": [[1, 1], [1, 1]], "tag": T_LIN, "nudge": "\\vec{BE} 和哪一支平行？",
			 "line": "\\vec{BE} = 2\\vec{b}"},
		]}
	# ---- 變化 B：\vec{u} = \vec{AC}、\vec{v} = \vec{AE}（斜格子三等分）----
	var u: Vector2 = H.C - H.A
	var v: Vector2 = H.E - H.A
	var wl := func(st: Vector2, cu: float, cv: float) -> Array:
		return [st, st + u * cu, st + u * cu + v * cv]
	var sb := base + [{"k": "skew", "o": _p(H.A), "a": _p(u), "b": _p(v), "i": [-1, 2], "j": [-1, 2], "div": 3, "c": "cyan"},
		_tag(H.O, "O", "dim", {"off": [6, 14]}), _ar(H.A, H.C, "cyan", "\\vec{u}", {"ls": -1}), _ar(H.A, H.E, "pink", "\\vec{v}")] + vdots + [
		_walk(wl.call(H.A, 2.0 / 3.0, 2.0 / 3.0), 1, "gold", true, {"until": 2}),
		_walk([H.B, H.B + u], 2, "gold", true, {"bad": true, "target": _p(H.D), "until": 3}),
		_walk(wl.call(H.F, 4.0 / 3.0, -2.0 / 3.0), 4, "gold", true, {"until": 5}),
		_walk(wl.call(H.A, 2.0 / 3.0, 1.0 / 3.0), 5, "gold", true, {"bad": true, "target": _p(H.B), "until": 6})]
	var vb := {"eq": "正六邊形 ABCDEF，\\vec{u} = \\vec{AC}、\\vec{v} = \\vec{AE}\n下面哪些正確？",
		"plane": _plane([-7, 7], [-3.4, 3.4], sb, named),
		"steps": [
			_j("審判一", "\\vec{AD} = \\frac{2}{3}\\vec{u} + \\frac{2}{3}\\vec{v}", true,
				"\\vec{AO} = \\frac{1}{3}(\\vec{u} + \\vec{v})，\\vec{AD} = 2\\vec{AO}。", "\\vec{AD} = \\frac{2}{3}\\vec{u} + \\frac{2}{3}\\vec{v}", T_LIN),
			_j("審判二", "\\vec{BD} = \\vec{u}", false,
				"照式子走會跑到六邊形外面：\\vec{BD} 和 \\vec{AE} 平行。", "\\vec{BD} ≠ \\vec{u}", T_LIN),
			_f("讀斜格子", "照斜格子讀", "\\vec{BD} = [0]\\vec{u} + [1]\\vec{v}", ["0", "1"],
				"\\vec{BD} = \\vec{v}（和 \\vec{AE} 平行、一樣長）", "\\vec{BD} 和哪一支平行？", T_LIN),
			_j("審判三", "\\vec{FC} = \\frac{4}{3}\\vec{u} − \\frac{2}{3}\\vec{v}", true,
				"從 F 沿 \\vec{u} 走 \\frac{4}{3}、再退 \\frac{2}{3} 個 \\vec{v}，剛好到 C。", "\\vec{FC} = \\frac{4}{3}\\vec{u} − \\frac{2}{3}\\vec{v}", T_LIN),
			_j("審判四", "\\vec{AB} = \\frac{2}{3}\\vec{u} + \\frac{1}{3}\\vec{v}", false,
				"照式子走停在六邊形裡面：\\vec{v} 的係數應該是負的。", "\\vec{AB} ≠ \\frac{2}{3}\\vec{u} + \\frac{1}{3}\\vec{v}", T_LIN),
			_f("讀斜格子", "照斜格子讀", "\\vec{AB} = [0]\\vec{u} + [1]\\vec{v}", ["2/3", "-1/3"],
				"\\vec{AB} = \\frac{2}{3}\\vec{u} − \\frac{1}{3}\\vec{v}", "B 在 \\vec{v} 的反方向那一邊。", T_LIN),
		]}
	for vv in [va, vb]:
		for st in vv.steps:
			if String(st.kind) != "fill":      # 填空要留位置給作答框
				st["big"] = true
	return {"id": "hexa", "chapter": 1, "type": "forge", "title": "六角風場",
		"story": "照卡片上的式子走一遍，看風箏停在哪裡。",
		"insight": "正六邊形：\\vec{AO} = \\vec{AB} + \\vec{AF}，對邊平行、一樣長\n用兩支箭頭表示一支：沿著六邊形的邊首尾接起來。",
		"variants": [va, vb]}


## 5 第四根旗桿：哪些條件保證 ABCD 是平行四邊形（A7）
static func _flag() -> Dictionary:
	var vars := []
	for cfg in [
			{"A": Vector2(-5, -2), "B": Vector2(0, -2), "C": Vector2(2, 2), "E": Vector2(5, -3), "start": Vector2(-6, 3),
			 "cards": [["\\vec{AB} = \\vec{CD}", "bow", "\\vec{CD} = \\vec{AB} 的 D 只有一個，可是連起來是交叉的：ABDC 才是平行四邊形。"],
				["\\vec{AC} = \\vec{AB} + \\vec{AD}", "o", "平行四邊形法：\\vec{AB}、\\vec{AD} 為兩邊，對角線就是 \\vec{AC}。"],
				["\\vec{EA} + \\vec{EC} = \\vec{EB} + \\vec{ED}", "o", "兩條對角線的中點重合（E 放哪裡都一樣）。"],
				["\\vec{AB} + \\vec{BC} + \\vec{CD} = \\vec{AD}", "all", "首尾相接，任何四邊形都成立。"]],
			 "ans_all": Vector2(4, 0)},
			{"A": Vector2(-3, 0), "B": Vector2(1, -2), "C": Vector2(3, 0), "E": Vector2(-6, -3), "start": Vector2(5, 3),
			 "cards": [["\\vec{AD} = \\vec{BC}", "o", "一組對邊平行而且一樣長。"],
				["\\vec{EA} + \\vec{EB} = \\vec{EC} + \\vec{ED}", "bow2", "\\ol{AB}、\\ol{CD} 的中點重合：ACBD 才是平行四邊形。"],
				["\\vec{BD} = \\vec{BA} + \\vec{BC}", "o", "平行四邊形法：\\vec{BA}、\\vec{BC} 為兩邊，對角線是 \\vec{BD}。"],
				["\\vec{AB} − \\vec{AD} = \\vec{DB}", "all", "終點減起點，任何四個點都成立。"]],
			 "ans_all": Vector2(4, 2)}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var C: Vector2 = cfg.C
		var E: Vector2 = cfg.E
		var para := A + C - B
		var pts := {"A": A, "B": B, "C": C}
		var shapes := [_seg(A, B, "faint"), _seg(B, C, "faint")] + _dots(pts, "gold", {"A": [-16, 4], "B": [6, 14], "C": [8, -4]})
		shapes.append(_tag(E, "E", "dim"))
		var steps := []
		var k := 0
		for cd in cfg.cards:
			k += 1
			var kind := String(cd[1])
			var lit = [_p(para)]
			var bow := Vector2.INF
			if kind == "bow":
				bow = C + B - A
				lit = [_p(bow)]
			elif kind == "bow2":
				bow = A + B - C
				lit = [_p(bow)]
			elif kind == "all":
				lit = "all"
			var sbx := {"label": "D", "poly": ["A", "B", "C", "D"], "lit": lit, "start": _p(cfg.start)}
			var ok := kind == "o"
			var st := _j(["審判一", "審判二", "審判三", "審判四"][k - 1], String(cd[0]), ok, String(cd[2]),
				("%s ⇒ 平行四邊形" if ok else "%s 不能保證") % cd[0], T_PARA)
			st["sandbox"] = sbx
			if ok:
				st["ribbon"] = [_p(A), _p(B), _p(C), _p(para)]
			steps.append(st)
			if not ok:
				var pl := {"kind": "vplace", "name": "反例", "sandbox": sbx, "para": _p(para), "tag": T_PARA}
				if kind == "all":
					pl.merge({"q": "燈亮，但不是平行四邊形", "goal": "lit_not_para", "ans": _p(cfg.ans_all),
						"nudge": "這個條件哪裡都成立，隨便放一個不是平行四邊形的地方。",
						"line": "反例：D 在別的地方燈也亮，ABCD 不是平行四邊形"})
				else:
					pl.merge({"q": "把 D 拖到燈亮的地方", "goal": "lit", "ans": _p(bow),
						"nudge": "燈只在一個地方亮，慢慢拖找找看。",
						"line": "燈只在 D(%s, %s) 亮：ABCD 交叉成蝴蝶結" % [_n(bow.x), _n(bow.y)]})
				steps.append(pl)
		vars.append({"eq": "A、B、C 已經立好，哪些條件保證\nABCD 是平行四邊形？",
			"plane": _plane([-8, 8], [-4, 4], shapes, {"A": A, "B": B, "C": C, "E": E}), "steps": steps})
	return {"id": "flag", "chapter": 1, "type": "forge", "title": "第四根旗桿",
		"story": "拖第四根旗桿 D，條件成立時燈會亮。",
		"insight": "保證平行四邊形 ABCD：\\vec{AB} = \\vec{DC}、\\vec{AD} = \\vec{BC}、\\vec{AC} = \\vec{AB} + \\vec{AD}、對角線中點重合\n\\vec{AB} = \\vec{CD} 是交叉的（ABDC 才是），首尾相接的式子永遠成立。",
		"variants": vars}


## 6 伸縮弓：k\vec{a} 射得到哪些氣球（係數積與平行）
static func _bow() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(2, 1), "P": Vector2(4, 2), "kp": 2.0, "Q": Vector2(-3, -1.5), "kq": -1.5, "R": Vector2(2, 3)},
			{"a": Vector2(2, -1), "P": Vector2(-4, 2), "kp": -2.0, "Q": Vector2(3, -1.5), "kq": 1.5, "R": Vector2(-2, 3)}]:
		var a: Vector2 = cfg.a
		var O := Vector2.ZERO
		var shapes := [_tag(O, "O", "text", {"off": [-14, 16]}), _ar(O, a, "gold", "\\vec{a}", {"w": 2.0}),
			{"k": "balloon", "p": _p(cfg.P), "c": "pink", "pop": 1, "s": "P"},
			{"k": "balloon", "p": _p(cfg.Q), "c": "lime", "pop": 2, "s": "Q"},
			{"k": "balloon", "p": _p(cfg.R), "c": "violet", "s": "R"},
			_seg(a * -4.4, a * 4.4, "gold", {"dash": true, "at": 3, "w": 1.5})]
		var arrow := {"k": "arrow", "a": [0, 0], "b": ["%s * k" % a.x, "%s * k" % a.y], "c": "cyan", "w": 3.0}
		var slide := func(name: String, q: String, goal: float, line: String, nudge: String) -> Dictionary:
			return {"kind": "slide", "name": name, "q": q, "tag": T_PARA,
				"params": [{"n": "k", "min": -4, "max": 4, "step": 0.5, "v": 1}], "lines": [arrow],
				"eq": "\\vec{OX} = {k}\\vec{a}", "goal": {"k": goal}, "line": line, "nudge": nudge}
		var sP: String = _fr(int(cfg.kp * 2), 2) if not is_equal_approx(cfg.kp, roundf(cfg.kp)) else _n(cfg.kp)
		var sQ: String = ("−" if cfg.kq < 0 else "") + ("\\frac{3}{2}" if absf(cfg.kq) == 1.5 else _n(absf(cfg.kq)))
		vars.append({"eq": "箭只能沿 \\vec{a} 的方向飛，飛 k\\vec{a}\n哪些氣球射得中？",
			"plane": _plane([-9, 9], [-4.2, 4.2], shapes),
			"steps": [
				slide.call("射 P", "拖 k 射中 P", cfg.kp, "k = %s：\\vec{OP} = %s\\vec{a}" % [sP, sP],
					"P 是 \\vec{a} 的幾倍遠？" + ("P 在 \\vec{a} 的反方向。" if cfg.kp < 0 else "")),
				slide.call("射 Q", "拖 k 射中 Q", cfg.kq, "k = %s：\\vec{OQ} = %s\\vec{a}" % [sQ, sQ],
					"Q 在 \\vec{a} 的%s方向。" % ("反" if cfg.kq < 0 else "同")),
				_c("射 R", "R 射得中嗎？", ["射不中", "k = \\frac{3}{2}", "k = 2"], 0,
					"R 不在 \\vec{a} 的直線上：(%s, %s) 不是 (%s, %s) 的倍數。" % [_n(cfg.R.x), _n(cfg.R.y), _n(a.x), _n(a.y)],
					"k 不管多少，箭都在同一條直線上。", "R 不在這條線上：沒有 k 使 k\\vec{a} = \\vec{OR}", T_PARA),
			]})
	return {"id": "bow", "chapter": 1, "type": "forge", "title": "伸縮弓",
		"story": "弓只能往一個方向拉，k 是負的就往後射。",
		"insight": "k\\vec{a}：k > 0 同方向、k < 0 反方向，長度是 |k| 倍\n\\vec{b} ∥ \\vec{a} ⇔ \\vec{b} = k\\vec{a}（\\vec{a} ≠ \\vec{0}）。",
		"variants": vars}


## 7 斜紋田埂：\vec{EF} = x\vec{AB} + y\vec{AD}（A2）
static func _skew() -> Dictionary:
	var A := Vector2(0, 0)
	var B := Vector2(6, 0)
	var D := Vector2(2, 4)
	var C := B + D
	var vars := []
	for cfg in [
			{"E": [3, 4], "Fon": "BC", "F": [2, 3], "AE": ["3/4", "3/4"], "AF": ["1", "2/3"], "EF": ["1/4", "-1/12"], "g": 1,
			 "eq": "平行四邊形 ABCD，\\ol{AE} = 3\\ol{EC}，\\ol{BF} = 2\\ol{FC}\n\\vec{EF} = x\\vec{AB} + y\\vec{AD}，求 (x, y)",
			 "nf": "先走到 B，再沿 \\vec{BC}（= \\vec{AD}）走 \\frac{2}{3}。", "ne": "x：1 − \\frac{3}{4}，y：\\frac{2}{3} − \\frac{3}{4}。"},
			{"E": [1, 2], "Fon": "DC", "F": [2, 3], "AE": ["1/2", "1/2"], "AF": ["2/3", "1"], "EF": ["1/6", "1/2"], "g": 0,
			 "eq": "平行四邊形 ABCD，\\ol{AE} = \\ol{EC}，\\ol{DF} = 2\\ol{FC}\n\\vec{EF} = x\\vec{AB} + y\\vec{AD}，求 (x, y)",
			 "nf": "先走到 D，再沿 \\vec{DC}（= \\vec{AB}）走 \\frac{2}{3}。", "ne": "x：\\frac{2}{3} − \\frac{1}{2}，y：1 − \\frac{1}{2}。"}]:
		var E: Vector2 = A.lerp(C, float(cfg.E[0]) / float(cfg.E[1]))
		var Fp: Vector2 = (B if cfg.Fon == "BC" else D).lerp(C, float(cfg.F[0]) / float(cfg.F[1]))
		var ae := [_frv(cfg.AE[0]), _frv(cfg.AE[1])]
		var af := [_frv(cfg.AF[0]), _frv(cfg.AF[1])]
		var ef := [_frv(cfg.EF[0]), _frv(cfg.EF[1])]
		var shapes := [{"k": "skew", "o": [0, 0], "a": _p(B), "b": _p(D), "i": [0, 1], "j": [0, 1], "div": 12, "c": "cyan"},
			_poly([A, B, C, D], "dim"), _seg(A, C, "faint", {"dash": true}),
			_ar(A, B, "cyan", "\\vec{AB}", {"ls": -1, "w": 2.5}), _ar(A, D, "pink", "\\vec{AD}", {"w": 2.5})]
		shapes += _dots({"A": A, "B": B, "C": C, "D": D}, "dim", {"A": [-14, 14], "B": [6, 14], "C": [6, -6], "D": [-14, -6]})
		shapes += [_dot(E, "E", "gold", {"off": [-16, -6]}), _dot(Fp, "F", "lime", {"off": [8, 4]}),
			_walk([A, B * ae[0], E], 2, "cyan", false), _walk([A, B * af[0], Fp], 3, "lime", false),
			_walk([E, E + B * ef[0], Fp], 4, "gold", true)]
		var tpl := func(nm: String) -> String:
			return "\\vec{%s} = [0]\\vec{AB} + [1]\\vec{AD}" % nm
		var opts := ["x > 0，y > 0", "x > 0，y < 0", "x < 0，y > 0", "x < 0，y < 0"]
		var guess := _c("先猜", "先猜 x、y 的正負", opts, int(cfg.g), "", "", "先猜：{guess}", T_LIN)
		guess["guess"] = true
		vars.append({"eq": cfg.eq, "plane": _plane([-1, 9.6], [-0.9, 4.6], shapes),
			"steps": [
				guess,
				_f("E", "E 的斜坐標", tpl.call("AE"), cfg.AE, "\\vec{AE} = " + _lin(cfg.AE[0], "AB", cfg.AE[1], "AD"),
					"E 在 \\vec{AC} 上，\\vec{AC} = \\vec{AB} + \\vec{AD}。", T_LIN),
				_f("F", "F 的斜坐標", tpl.call("AF"), cfg.AF, "\\vec{AF} = " + _lin(cfg.AF[0], "AB", cfg.AF[1], "AD"),
					cfg.nf, T_LIN),
				_f("EF", "終點減起點", tpl.call("EF"), cfg.EF,
					"\\vec{EF} = \\vec{AF} − \\vec{AE} ⇒ (x, y) = (%s, %s)" % [_frs(cfg.EF[0]), _frs(cfg.EF[1])], cfg.ne, T_LIN),
			]})
	return {"id": "skew", "chapter": 1, "type": "forge", "title": "斜紋田埂",
		"story": "田埂沿著兩個方向排，每塊田都有斜坐標。",
		"insight": "\\vec{EF} = \\vec{AF} − \\vec{AE}：兩個終點都用 \\vec{AB}、\\vec{AD} 表示，再相減\n斜坐標就是沿 \\vec{AB} 走幾格、沿 \\vec{AD} 走幾格。",
		"variants": vars}


static func _frv(s: String) -> float:
	if s.contains("/"):
		var p := s.split("/")
		return float(p[0]) / float(p[1])
	return float(s)


## 係數的寫法：1 不寫、−1 只寫負號（\vec{AF} = \vec{AB} + \frac{2}{3}\vec{AD}）
static func _lin(a: String, va: String, b: String, vb: String) -> String:
	var out := ""
	for pr in [[a, va], [b, vb]]:
		var c := String(pr[0])
		if c == "0":
			continue
		var neg := c.begins_with("-")
		var body := _cs(c.trim_prefix("-")) + "\\vec{%s}" % pr[1]
		if out == "":
			out = ("−" if neg else "") + body
		else:
			out += (" − " if neg else " + ") + body
	return out if out != "" else "\\vec{0}"


static func _cs(s: String) -> String:
	if s == "1":
		return ""
	if s == "-1":
		return "−"
	return _frs(s)


static func _frs(s: String) -> String:
	if s.contains("/"):
		var p := s.split("/")
		var n := int(p[0])
		return ("−" if n < 0 else "") + "\\frac{%d}{%s}" % [absi(n), p[1]]
	return s.replace("-", "−")


## 8 兩把風鎖：不共線時係數都是 0（A5、A6）
static func _locks() -> Dictionary:
	var A := Vector2(0, 0)
	var B := Vector2(4, 1)
	var C := Vector2(1, 3)
	var Cp := Vector2(2, 0.5)
	var shapes := [_ar(A, B, "cyan", "\\vec{AB}", {"ls": -1, "w": 2.0}), _ar(A, C, "pink", "\\vec{AC}", {"w": 2.0})]
	shapes += _dots({"A": A, "B": B, "C": C}, "dim", {"A": [-16, 14], "B": [8, 4], "C": [8, -6]})
	shapes += [_seg(B * -0.8, B * 1.5, "faint", {"dash": true, "at": 1, "until": 2}),
		_tag(Cp, "C'", "lime", {"at": 1, "until": 2, "off": [4, 22]}),
		_ar(B, A, "lime", "", {"at": 1, "until": 2, "dash": true})]
	var slide := {"kind": "slide", "name": "回家", "q": "讓光點回到 A", "tag": T_IND,
		"params": [{"n": "s", "min": -0.5, "max": 1, "step": 0.5, "v": 1}, {"n": "t", "min": -0.5, "max": 1, "step": 0.5, "v": 1}],
		"lines": [{"k": "arrow", "a": [0, 0], "b": ["4 * s", "s"], "c": "cyan", "w": 3.0},
			{"k": "arrow", "a": ["4 * s", "s"], "b": ["4 * s + t", "s + 3 * t"], "c": "pink", "w": 3.0},
			{"k": "dot", "p": ["4 * s + t", "s + 3 * t"], "c": "gold", "s": ""}],
		"eq": "s\\vec{AB} + t\\vec{AC}，s = {s}，t = {t}", "goal": {"s": 0, "t": 0},
		"line": "A、B、C 不共線：s\\vec{AB} + t\\vec{AC} = \\vec{0} 只有 s = t = 0",
		"nudge": "\\vec{AB}、\\vec{AC} 方向不同，互相抵消不了。",
		"why": "只有 s = t = 0 回得來。如果 C 在直線 AB 上（C'），就有別的走法。"}
	var zero := _c("係數", "兩個係數要是多少？", ["都是 0", "都是 1", "加起來是 1"], 0,
		"不共線，所以兩個係數都要是 0。", "回想剛才光點什麼時候回到 A。", "兩個係數都是 0", T_IND)
	zero["big"] = true
	return {"id": "locks", "chapter": 1, "type": "forge", "title": "兩把風鎖",
		"story": "兩把鎖都要轉到 0，門才會開。",
		"insight": "A、B、C 不共線：x\\vec{AB} + y\\vec{AC} = \\vec{0} ⇒ x = y = 0\n有別的向量（像 \\vec{CB}）先拆成 \\vec{AB}、\\vec{AC}，再比係數。",
		"variants": [
			{"eq": "A、B、C 不共線\n(x − 2y + 1)\\vec{AB} + (x + y − 5)\\vec{AC} = \\vec{0}，求 (x, y)",
			 "plane": _plane([-4.4, 7.2], [-2.5, 4.4], shapes),
			 "steps": [slide, zero,
				SB.with_pre(_f("解", "解聯立", "(x, y) = ([0], [1])", ["3", "2"],
					"(x, y) = (3, 2)", "兩式相減消掉 x。", T_IND), "x − 2y + 1 = 0、x + y − 5 = 0")]},
			{"eq": "A、B、C 不共線\nx\\vec{AB} + (y − 1)\\vec{CB} + (x + 4)\\vec{AC} = \\vec{0}，求 (x, y)",
			 "plane": _plane([-4.4, 7.2], [-2.5, 4.4], shapes),
			 "steps": [slide,
				_c("拆開", "\\vec{CB} = \\vec{AB} − \\vec{AC}，整理", ["(x + y − 1)\\vec{AB} + (x − y + 5)\\vec{AC}",
					"(x − y + 1)\\vec{AB} + (x + y + 3)\\vec{AC}", "(x + y − 1)\\vec{AB} + (x + y + 3)\\vec{AC}"], 0,
					"(y − 1)\\vec{CB} = (y − 1)\\vec{AB} − (y − 1)\\vec{AC}，再和同一支的合起來。",
					"\\vec{AC} 的係數：(x + 4) − (y − 1)。", "(x + y − 1)\\vec{AB} + (x − y + 5)\\vec{AC} = \\vec{0}", T_IND),
				SB.with_pre(_f("解", "兩個係數都是 0", "(x, y) = ([0], [1])", ["-2", "3"],
					"(x, y) = (−2, 3)", "兩式相加消掉 y。", T_IND), "x + y − 1 = 0、x − y + 5 = 0")]},
		]}


# ======================= 第二章．繩橋 =======================

## 10 繩橋上的珠子：拖珠子、掛砝碼，係數交叉
static func _bead() -> Dictionary:
	var A := Vector2(0, 5)
	var B := Vector2(-4, 0)
	var C := Vector2(5, 0)
	var vars := []
	for cfg in [[1, 3], [3, 2]]:
		var m: int = cfg[0]
		var n: int = cfg[1]
		var den := m + n
		var P := B.lerp(C, float(m) / den)
		var shapes := [_seg(A, B, "dim"), _seg(A, C, "dim"), _seg(B, C, "gold", {"w": 3.0})]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [8, -4], "B": [-16, 4], "C": [8, 4]})
		shapes += [_dot(P, "P", "gold", {"at": 1, "off": [-4, -12]}), _ar(A, P, "gold", "\\vec{AP}", {"at": 3}), _walk([A, P], 3, "gold", false)]
		vars.append({"eq": "P 在 \\ol{BC} 上，\\ol{BP} : \\ol{PC} = %d : %d\n\\vec{AP} = x\\vec{AB} + y\\vec{AC}，求 (x, y)" % [m, n],
			"plane": _plane([-7.5, 8.5], [-4.6, 5.8], shapes),
			"steps": [
				{"kind": "slide", "name": "拖珠子", "q": "拖珠子到 %d : %d" % [m, n], "tag": T_DIV,
				 "params": [{"n": "n", "min": 0, "max": den, "step": 1, "v": 2 if m != 2 else 3}],
				 "lines": [{"k": "dot", "p": ["%s + %s * n / %d" % [B.x, C.x - B.x, den], "0"], "c": "gold", "s": "P"}],
				 "eq": "\\ol{BP} : \\ol{PC} = {n} : {%d - n}" % den, "goal": {"n": m},
				 "line": "P 把 \\ol{BC} 分成 %d : %d" % [m, n], "nudge": "\\ol{BC} 分成 %d 等分。" % den},
				{"kind": "vweigh", "name": "掛砝碼", "q": "掛砝碼，讓秤桿在 P 平衡", "b": _p(B), "c": _p(C), "p": _p(P),
				 "ans": [n, m], "tag": T_DIV, "nudge": "離支點近的那一邊要重一點。",
				 "why": "B 掛 %d、C 掛 %d：%d × %d = %d × %d。" % [n, m, n, m, m, n],
				 "line": "B 掛 %d、C 掛 %d 才平衡：靠近 B，B 的權重大" % [n, m]},
				_f("係數", "權重就是係數", "\\vec{AP} = [0]\\vec{AB} + [1]\\vec{AC}", ["%d/%d" % [n, den], "%d/%d" % [m, den]],
					"\\vec{AP} = %s\\vec{AB} + %s\\vec{AC}：係數交叉，加起來是 1" % [_fr(n, den), _fr(m, den)],
					"砝碼 %d 和 %d，各占幾分之幾？" % [n, m], T_DIV),
			]})
	return {"id": "bead", "chapter": 2, "type": "forge", "title": "繩橋上的珠子",
		"story": "兩座崖之間的繩橋，珠子停在哪裡？",
		"insight": "\\ol{BP} : \\ol{PC} = m : n ⇒ \\vec{AP} = \\frac{n}{m + n}\\vec{AB} + \\frac{m}{m + n}\\vec{AC}\n係數交叉（靠近誰，誰的係數大），加起來是 1。",
		"variants": vars}


## 11 兩隻風箏之間：\vec{PQ} = \vec{AQ} − \vec{AP}（A12）
static func _two_kites() -> Dictionary:
	var A := Vector2(0, 5)
	var B := Vector2(-5, -1)
	var C := Vector2(4, -1)
	var vars := []
	for cfg in [
			{"P": B.lerp(C, 2.0 / 3.0), "Q": A.lerp(C, 0.75),
			 "eq": "\\ol{BP} : \\ol{PC} = 2 : 1，\\ol{AQ} : \\ol{QC} = 3 : 1\n\\vec{PQ} = x\\vec{AB} + y\\vec{AC}，求 (x, y)",
			 "AP": ["1/3", "2/3"], "AQ": ["0", "3/4"], "PQ": ["-1/3", "1/12"],
			 "np": "\\ol{BP} : \\ol{PC} = 2 : 1，係數交叉。", "nq": "Q 在 \\ol{AC} 上，用不到 \\vec{AB}。",
			 "nd": "\\vec{AB}：0 − \\frac{1}{3}，\\vec{AC}：\\frac{3}{4} − \\frac{2}{3}。"},
			{"P": A.lerp(B, 2.0 / 3.0), "Q": B.lerp(C, 0.5),
			 "eq": "\\ol{AP} : \\ol{PB} = 2 : 1，Q 是 \\ol{BC} 的中點\n\\vec{PQ} = x\\vec{AB} + y\\vec{AC}，求 (x, y)",
			 "AP": ["2/3", "0"], "AQ": ["1/2", "1/2"], "PQ": ["-1/6", "1/2"],
			 "np": "P 在 \\ol{AB} 上，用不到 \\vec{AC}。", "nq": "中點：兩個係數一樣。",
			 "nd": "\\vec{AB}：\\frac{1}{2} − \\frac{2}{3}，\\vec{AC}：\\frac{1}{2} − 0。"}]:
		var P: Vector2 = cfg.P
		var Q: Vector2 = cfg.Q
		var shapes := [_poly([A, B, C], "dim")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [8, -4], "B": [-16, 4], "C": [8, 4]})
		shapes += [_dot(P, "P", "cyan", {"off": [-6, 18]}), _dot(Q, "Q", "pink", {"off": [8, -4]}),
			_ar(A, P, "cyan", "", {"at": 2, "w": 2.5}), _ar(A, Q, "pink", "", {"at": 3, "w": 2.5}),
			_ar(P, Q, "gold", "\\vec{PQ}", {"at": 4}), _walk([P, Q], 4, "gold", false)]
		var tpl := func(nm: String) -> String:
			return "\\vec{%s} = [0]\\vec{AB} + [1]\\vec{AC}" % nm
		vars.append({"eq": cfg.eq, "plane": _plane([-7.5, 7], [-2.2, 6], shapes),
			"steps": [
				_c("相減", "\\vec{PQ} = ？", ["\\vec{AQ} − \\vec{AP}", "\\vec{AP} − \\vec{AQ}", "\\vec{AP} + \\vec{AQ}"], 0,
					"從 P 先回到 A（−\\vec{AP}），再從 A 到 Q（\\vec{AQ}）。",
					"從 P 到 Q：先從 P 回到 A，再到 Q。", "\\vec{PQ} = \\vec{AQ} − \\vec{AP}（終點減起點）", T_ADD),
				_f("P", "P 的分點", tpl.call("AP"), cfg.AP, "\\vec{AP} = " + _lin(cfg.AP[0], "AB", cfg.AP[1], "AC"), cfg.np, T_DIV),
				_f("Q", "Q 的分點", tpl.call("AQ"), cfg.AQ, "\\vec{AQ} = " + _lin(cfg.AQ[0], "AB", cfg.AQ[1], "AC"), cfg.nq, T_DIV),
				_f("PQ", "相減", tpl.call("PQ"), cfg.PQ, "\\vec{PQ} = \\vec{AQ} − \\vec{AP} ⇒ (x, y) = (%s, %s)" % [_frs(cfg.PQ[0]), _frs(cfg.PQ[1])], cfg.nd, T_DIV),
			]})
	return {"id": "kites", "chapter": 2, "type": "forge", "title": "兩隻風箏之間",
		"story": "兩隻風箏都從 A 放出去，牠們之間差多少？",
		"insight": "\\vec{PQ} = \\vec{AQ} − \\vec{AP}（終點減起點）\n兩個點都先用分點公式寫成 \\vec{AB}、\\vec{AC}，再相減。",
		"variants": vars}


## 12 梯形看台：先鋪 \vec{AC}，再用分點（A11）
static func _trapezoid() -> Dictionary:
	var vars := []
	for cfg in [{"k": 3, "B": Vector2(9, 0), "C": Vector2(4, 3), "m": 1, "n": 2, "AM": ["2/3", "1/3"], "xy": ["7/9", "1/3"], "sol": [[0, 1], [1, 1]],
				"eq": "梯形 ABCD，\\ol{AB} = 3\\ol{DC}，\\ol{BM} : \\ol{MC} = 1 : 2\n\\vec{AM} = x\\vec{AB} + y\\vec{AD}，求 (x, y)",
				"n2": "\\frac{2}{3}\\vec{AB} + \\frac{1}{3}(\\vec{AD} + \\frac{1}{3}\\vec{AB})。"},
			{"k": 2, "B": Vector2(8, 0), "C": Vector2(5, 3), "m": 1, "n": 1, "AM": ["1/2", "1/2"], "xy": ["3/4", "1/2"], "sol": [[0, 1], [2, 1]],
				"eq": "梯形 ABCD，\\ol{AB} = 2\\ol{DC}，M 是 \\ol{BC} 的中點\n\\vec{AM} = x\\vec{AB} + y\\vec{AD}，求 (x, y)",
				"n2": "\\frac{1}{2}\\vec{AB} + \\frac{1}{2}(\\vec{AD} + \\frac{1}{2}\\vec{AB})。"}]:
		var A := Vector2(0, 0)
		var D := Vector2(1, 3)
		var B: Vector2 = cfg.B
		var C: Vector2 = cfg.C
		var M := B.lerp(C, float(cfg.m) / float(cfg.m + cfg.n))
		var shapes := [_poly([A, B, C, D], "dim"), _ar(A, B, "cyan", "\\vec{AB}", {"ls": -1, "w": 2.5}), _ar(A, D, "pink", "\\vec{AD}", {"w": 2.5})]
		shapes += _dots({"A": A, "B": B, "C": C, "D": D}, "text", {"A": [-14, 14], "B": [6, 14], "C": [6, -6], "D": [-14, -6]})
		shapes += [_dot(M, "M", "gold", {"off": [8, 4]}), _ar(A, M, "gold", "\\vec{AM}", {"at": 3}), _walk([A, M], 3, "gold", false)]
		var ab := B - A
		var tiles := [{"s": "\\vec{AD}", "v": _p(D - A)}, {"s": "\\frac{1}{3}\\vec{AB}", "v": _p(ab / 3.0)},
			{"s": "\\frac{1}{2}\\vec{AB}", "v": _p(ab / 2.0)}, {"s": "\\vec{AB}", "v": _p(ab)}]
		var kk: int = cfg.k
		vars.append({"eq": cfg.eq, "plane": _plane([-1, 10], [-0.9, 4.1], shapes),
			"steps": [
				{"kind": "vpath", "name": "鋪到 C", "q": "從 A 鋪到 C", "from": [0, 0], "to": _p(C), "tiles": tiles, "flip": false,
				 "sol": cfg.sol, "tag": T_LIN, "nudge": "\\ol{DC} 是 \\ol{AB} 的幾分之幾？",
				 "line": "\\vec{AC} = \\vec{AD} + \\frac{1}{%d}\\vec{AB}（\\vec{DC} = \\frac{1}{%d}\\vec{AB}）" % [kk, kk]},
				_f("分點", "M 的分點", "\\vec{AM} = [0]\\vec{AB} + [1]\\vec{AC}", cfg.AM,
					"\\vec{AM} = " + _lin(cfg.AM[0], "AB", cfg.AM[1], "AC"),
					"\\ol{BM} : \\ol{MC} = %d : %d，係數交叉。" % [cfg.m, cfg.n], T_DIV),
				_f("代進去", "把 \\vec{AC} 代進去", "\\vec{AM} = [0]\\vec{AB} + [1]\\vec{AD}", cfg.xy,
					"\\vec{AM} = " + _lin(cfg.xy[0], "AB", cfg.xy[1], "AD"), cfg.n2, T_LIN),
			]})
	return {"id": "trap", "chapter": 2, "type": "forge", "title": "梯形看台",
		"story": "看台是梯形，上底比下底短。",
		"insight": "梯形：\\vec{DC} = \\frac{\\ol{DC}}{\\ol{AB}}\\vec{AB}（平行而且同方向）\n先用分點寫成 \\vec{AB}、\\vec{AC}，再把 \\vec{AC} = \\vec{AD} + \\vec{DC} 代進去。",
		"variants": vars}


## 三角形：B(0, 0)、C(a, 0)，\ol{AB} = c、\ol{AC} = b
static func _tri(c: float, b: float, a: float) -> Vector2:
	var x := (c * c - b * b + a * a) / (2.0 * a)
	return Vector2(x, sqrt(c * c - x * x))


static func _ang_expr(A: Vector2, P: Vector2, other: String) -> String:
	# ∠PAD（D = (t, 0)）的度數，四捨五入到整數
	var ux := P.x - A.x
	var uy := P.y - A.y
	return "round(acos((%f * (t - %f) + %f * (%f)) / (%f * sqrt(pow(t - %f, 2) + %f))) * 57.2957795)" % [
		ux, A.x, uy, -A.y, Vector2(ux, uy).length(), A.x, A.y * A.y]


## 13 對折的角：角平分線分對邊（新）
static func _fold() -> Dictionary:
	var vars := []
	for cfg in [{"c": 4.0, "b": 6.0, "a": 5.0, "bd": 2.0, "r": [2, 3], "xy": ["3/5", "2/5"]},
			{"c": 6.0, "b": 3.0, "a": 6.0, "bd": 4.0, "r": [2, 1], "xy": ["1/3", "2/3"]}]:
		var A := _tri(cfg.c, cfg.b, cfg.a)
		var B := Vector2.ZERO
		var C := Vector2(cfg.a, 0)
		var D := Vector2(cfg.bd, 0)
		var Bp := A + (C - A).normalized() * float(cfg.c)
		var shapes := [_poly([A, B, C], "dim")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [8, -6], "B": [-16, 6], "C": [8, 6]})
		shapes += [_dot(D, "D", "gold", {"at": 1, "off": [-4, 20]}), _seg(A, D, "gold", {"at": 1, "w": 2.0}),
			{"k": "fold", "pts": [_p(A), _p(B), _p(D)], "to": [_p(A), _p(Bp), _p(D)], "dur": 1.4, "c": "cyan", "at": 1},
			_ar(A, D, "gold", "\\vec{AD}", {"at": 3}), _walk([A, D], 3, "gold", false)]
		var m: int = cfg.r[0]
		var n: int = cfg.r[1]
		var e1 := _ang_expr(A, B, "")
		var e2 := _ang_expr(A, C, "")
		vars.append({"eq": "\\ol{AB} = %d、\\ol{AC} = %d、\\ol{BC} = %d，AD 平分 ∠A\n\\vec{AD} = x\\vec{AB} + y\\vec{AC}，求 (x, y)" % [cfg.c, cfg.b, cfg.a],
			"plane": _plane([-1.2, maxf(cfg.a, Bp.x) + 1.2], [minf(-0.9, Bp.y - 0.6), A.y + 0.7], shapes),
			"steps": [
				{"kind": "slide", "name": "對折", "q": "拖 D，讓兩個角一樣大", "tag": T_DAPP,
				 "params": [{"n": "t", "min": 0, "max": cfg.a, "step": 0.5, "v": cfg.a - 1.0}],
				 "lines": [{"k": "seg", "a": _p(A), "b": ["t", "0"], "c": "gold", "w": 2.0}, {"k": "dot", "p": ["t", "0"], "c": "gold", "s": "D"}],
				 "eq": "∠BAD ≈ {%s}°\n∠DAC ≈ {%s}°" % [e1, e2], "goal": {"t": cfg.bd},
				 "line": "\\ol{BD} = %d 時兩個角一樣大：AD 是角平分線" % int(cfg.bd), "nudge": "∠BAD 比較大，就往 B 拖。",
				 "why": "沿 AD 對折，B 剛好落在 \\ol{AC} 上。"},
				_c("比", "\\ol{BD} : \\ol{DC} = ？", ["\\ol{AB} : \\ol{AC}", "\\ol{AC} : \\ol{AB}", "1 : 1"], 0,
					"\\ol{BD} : \\ol{DC} = %d : %d = %d : %d。" % [int(cfg.bd), int(cfg.a - cfg.bd), int(cfg.c), int(cfg.b)],
					"看讀數：\\ol{BD} = %d、\\ol{DC} = %d。" % [int(cfg.bd), int(cfg.a - cfg.bd)],
					"角平分線：\\ol{BD} : \\ol{DC} = \\ol{AB} : \\ol{AC} = %d : %d" % [m, n], T_DAPP),
				_f("係數", "係數交叉", "\\vec{AD} = [0]\\vec{AB} + [1]\\vec{AC}", cfg.xy,
					"\\vec{AD} = " + _lin(cfg.xy[0], "AB", cfg.xy[1], "AC"),
					"\\ol{BD} : \\ol{DC} = %d : %d，係數交叉。" % [m, n], T_DIV),
			]})
	return {"id": "fold", "chapter": 2, "type": "forge", "title": "對折的角",
		"story": "把三角形沿著角平分線對折，兩邊會疊在一起。",
		"insight": "角平分線分對邊：\\ol{BD} : \\ol{DC} = \\ol{AB} : \\ol{AC}\n再用分點公式：\\vec{AD} = \\frac{\\ol{AC}}{\\ol{AB} + \\ol{AC}}\\vec{AB} + \\frac{\\ol{AB}}{\\ol{AB} + \\ol{AC}}\\vec{AC}。",
		"variants": vars}


## 14 吹大的圓：內切圓的切點（A8）
static func _incircle() -> Dictionary:
	var vars := []
	for cfg in [{"c": 6.0, "a": 7.0, "b": 5.0}, {"c": 7.0, "a": 8.0, "b": 5.0}]:
		var a: float = cfg.a
		var b: float = cfg.b
		var c: float = cfg.c
		var A := _tri(c, b, a)
		var B := Vector2.ZERO
		var C := Vector2(a, 0)
		var s := (a + b + c) / 2.0
		var I := (A * a + B * b + C * c) / (a + b + c)
		var r := I.y
		var pp := s - a
		var qq := s - b
		var rr := s - c
		var D := Vector2(qq, 0)
		var Fp := A + (B - A).normalized() * pp
		var E := A + (C - A).normalized() * pp
		var shapes := [_poly([A, B, C], "dim")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [8, -6], "B": [-16, 6], "C": [8, 6]})
		shapes += [{"k": "circle", "o": _p(I), "r": r, "c": "cyan", "at": 1},
			_dot(D, "D", "gold", {"at": 1, "off": [-4, 20]}), _tag(E, "", "gold", {"at": 1}), _tag(Fp, "", "gold", {"at": 1}),
			_tag(A.lerp(Fp, 0.5), "p", "pink", {"at": 2, "off": [-16, 0]}), _tag(B.lerp(D, 0.5), "q", "lime", {"at": 2, "off": [-4, 18]}),
			_tag(C.lerp(D, 0.5), "r", "violet", {"at": 2, "off": [-4, 18]}),
			_ar(A, D, "gold", "\\vec{AD}", {"at": 4}), _walk([A, D], 4, "gold", false)]
		var traps := []
		for big in [110, 120, 130, 140]:
			traps.append([{"p": big}, "吹太大了，圓被邊戳破。"])
		vars.append({"eq": "\\ol{AB} = %d、\\ol{BC} = %d、\\ol{CA} = %d，內切圓切 \\ol{BC} 於 D\n\\vec{AD} = x\\vec{AB} + y\\vec{AC}，求 (x, y)" % [c, a, b],
			"plane": _plane([-1.2, a + 1.2], [-0.9, A.y + 0.6], shapes),
			"steps": [
				{"kind": "slide", "name": "吹圓", "q": "把圓吹大，碰到三條邊", "tag": T_DAPP,
				 "params": [{"n": "p", "min": 20, "max": 140, "step": 10, "v": 40}],
				 "lines": [{"k": "circle", "o": _p(I), "r": "%f * p / 100" % r, "c": "cyan"}],
				 "eq": "大小 {p}%，碰到 {3 * int(p == 100)} 條邊", "goal": {"p": 100}, "traps": traps,
				 "line": "內切圓碰到三邊：三個切點把三邊分成六段", "nudge": "還沒碰到邊，再吹大一點。"},
				_f("切線長", "同一頂點的切線一樣長", "p + q = [0]，q + r = [1]，p + r = [2]", [str(int(c)), str(int(a)), str(int(b))],
					"p + q = %d、q + r = %d、p + r = %d" % [c, a, b], "p、q 合起來是 \\ol{AB}。", T_DAPP),
				_f("解", "解出 q、r", "\\ol{BD} = q = [0]，\\ol{DC} = r = [1]", [str(int(qq)), str(int(rr))],
					"p + q + r = %d ⇒ \\ol{BD} = q = %d、\\ol{DC} = r = %d" % [s, qq, rr], "三式相加：p + q + r = %d。" % int(s), T_DAPP),
				_f("係數", "係數交叉", "\\vec{AD} = [0]\\vec{AB} + [1]\\vec{AC}", ["%d/%d" % [rr, a], "%d/%d" % [qq, a]],
					"\\vec{AD} = %s\\vec{AB} + %s\\vec{AC}" % [_fr(int(rr), int(a)), _fr(int(qq), int(a))],
					"\\ol{BD} : \\ol{DC} = %d : %d，係數交叉。" % [qq, rr], T_DIV),
			]})
	return {"id": "circle", "chapter": 2, "type": "forge", "title": "吹大的圓",
		"story": "在三角形裡吹氣球，吹到碰到三條邊。",
		"insight": "從同一個頂點出發的兩段切線一樣長\n\\ol{BD} = s − \\ol{CA}（s 是半周長），再用分點公式。",
		"variants": vars}


## 15 鉛錘：高的垂足（A9）
static func _plumb() -> Dictionary:
	var vars := []
	for cfg in [{"c": 13, "a": 14, "b": 15, "bd": 5, "h": 12}, {"c": 10, "a": 21, "b": 17, "bd": 6, "h": 8}]:
		var a: int = cfg.a
		var bd: int = cfg.bd
		var A := Vector2(bd, cfg.h)
		var B := Vector2.ZERO
		var C := Vector2(a, 0)
		var D := Vector2(bd, 0)
		var shapes := [_poly([A, B, C], "dim")]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [8, -6], "B": [-16, 6], "C": [8, 6]})
		shapes += [_seg(A, A + Vector2(0, -cfg.h * 0.32), "faint", {"dash": true, "until": 1}),
			_tag(A + Vector2(0, -cfg.h * 0.32), "", "dim", {"until": 1}),
			_seg(A, D, "gold", {"at": 1, "w": 2.0}), _dot(D, "D", "gold", {"at": 1, "off": [-4, 20]}),
			{"k": "right", "p": _p(D), "u": [1, 0], "v": [0, 1], "at": 1},
			_ar(A, D, "gold", "\\vec{AD}", {"at": 4}), _walk([A, D], 4, "gold", false)]
		var c: int = cfg.c
		var b: int = cfg.b
		vars.append({"eq": "\\ol{AB} = %d、\\ol{BC} = %d、\\ol{CA} = %d，AD 是 \\ol{BC} 上的高\n\\vec{AD} = x\\vec{AB} + y\\vec{AC}，求 (x, y)" % [c, a, b],
			"plane": _plane([-1.5, a + 1.5], [-1.0, cfg.h + 1.0], shapes),
			"steps": [
				{"kind": "slide", "name": "鉛錘", "q": "拖 D，讓 \\ol{AD} ⊥ \\ol{BC}", "tag": T_DAPP,
				 "params": [{"n": "t", "min": 0, "max": a, "step": 1, "v": a - 3}],
				 "lines": [{"k": "seg", "a": _p(A), "b": ["t", "0"], "c": "gold", "w": 2.0}, {"k": "dot", "p": ["t", "0"], "c": "gold", "s": "D"}],
				 "eq": "∠ADB ≈ {round(atan2(%d, t - %d) * 57.2957795)}°" % [cfg.h, bd], "goal": {"t": bd},
				 "line": "∠ADB = 90°：D 是垂足", "nudge": "∠ADB 小於 90°，就往 B 拖。"},
				_f("列式", "兩邊都算 \\ol{AD}^{2}", "[0]^{2} − t^{2} = [1]^{2} − ([2] − t)^{2}", [str(c), str(b), str(a)],
					"\\ol{BD} = t：\\ol{AD}^{2} = %d^{2} − t^{2} = %d^{2} − (%d − t)^{2}" % [c, b, a], "左邊用 △ABD，右邊用 △ADC。", T_DAPP),
				_f("解", "解 t", "t = [0]", [str(bd)], "t = %d：\\ol{BD} = %d、\\ol{DC} = %d" % [bd, bd, a - bd],
					"%d − t^{2} = %d − %d + %dt − t^{2}。" % [c * c, b * b, a * a, 2 * a], T_DAPP),
				_f("係數", "係數交叉", "\\vec{AD} = [0]\\vec{AB} + [1]\\vec{AC}", ["%d/%d" % [a - bd, a], "%d/%d" % [bd, a]],
					"\\vec{AD} = %s\\vec{AB} + %s\\vec{AC}" % [_fr((a - bd) / _gcd(a - bd, a), a / _gcd(a - bd, a)), _fr(bd / _gcd(bd, a), a / _gcd(bd, a))],
					"\\ol{BD} : \\ol{DC} = %d : %d，係數交叉。" % [bd, a - bd], T_DIV),
			]})
	return {"id": "plumb", "chapter": 2, "type": "forge", "title": "鉛錘",
		"story": "從 A 垂下鉛錘，碰到 \\ol{BC} 的地方就是垂足。",
		"insight": "高的垂足：兩個直角三角形都用畢氏定理算高，列出 \\ol{BD}\n再用分點公式寫出 \\vec{AD}。",
		"variants": vars}


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return absi(a)


## 16 縮放鏡：面積比 → 邊長比 → 分點（A10）
static func _zoom() -> Dictionary:
	var A := Vector2(0, 0)
	var B := Vector2(6, 0)
	var D := Vector2(2, 4)
	var C := B + D
	var vars := []
	for cfg in [{"af": [1, 1], "k": [2, 3], "n": 4, "xy": ["4/5", "3/5"]}, {"af": [1, 2], "k": [1, 2], "n": 3, "xy": ["7/9", "2/3"]}]:
		var Fp := A.lerp(B, float(cfg.af[0]) / float(cfg.af[0] + cfg.af[1]))
		var kv := float(cfg.k[0]) / float(cfg.k[1])
		var E := C - (B - Fp) * kv
		var P := Fp.lerp(C, 1.0 / (1.0 + kv))
		var shapes := [_poly([A, B, C, D], "dim"), _seg(B, E, "dim"), _seg(C, Fp, "dim"),
			_poly([P, E, C], "pink", {"fill": "pink", "alpha": 0.18}), _poly([P, Fp, B], "cyan", {"fill": "cyan", "alpha": 0.18})]
		shapes += _dots({"A": A, "B": B, "C": C, "D": D}, "text", {"A": [-14, 14], "B": [6, 14], "C": [6, -6], "D": [-14, -6]})
		shapes += [_dot(E, "E", "pink", {"off": [-6, -10]}), _dot(Fp, "F", "cyan", {"off": [-6, 18]}), _dot(P, "P", "gold", {"off": [10, 4]}),
			_ar(A, P, "gold", "\\vec{AP}", {"at": 4}), _walk([A, P], 4, "gold", false)]
		var px := "%f - (n / 6.0) * (%f - %f)"
		var tri := {"k": "poly", "pts": [[str(P.x), str(P.y)],
			[px % [P.x, Fp.x, P.x], px % [P.y, Fp.y, P.y]], [px % [P.x, B.x, P.x], px % [P.y, B.y, P.y]]],
			"c": "lime", "fill": "lime", "alpha": 0.25}
		var ra := "%d : %d" % [cfg.k[0] * cfg.k[0], cfg.k[1] * cfg.k[1]]
		var afs := "\\ol{AF} = \\ol{FB}" if cfg.af[0] == cfg.af[1] else "\\ol{AF} : \\ol{FB} = %d : %d" % cfg.af
		vars.append({"eq": "平行四邊形 ABCD，%s，面積 △PEC : △PFB = %s\n\\vec{AP} = x\\vec{AB} + y\\vec{AD}，求 (x, y)" % [afs, ra],
			"plane": _plane([-1, 9.4], [-0.9, 4.6], shapes),
			"steps": [
				{"kind": "slide", "name": "縮放", "q": "把 △PFB 轉過去疊到 △PEC 上", "tag": T_DAPP,
				 "params": [{"n": "n", "min": 1, "max": 9, "step": 1, "v": 6}], "lines": [tri],
				 "eq": "放大 k = {n / 6.0} 倍，面積 × {pow(n / 6.0, 2)}", "goal": {"n": cfg.n},
				 "line": "k = %s 時剛好疊合：面積比 = k^{2} = %s" % [_fr(cfg.k[0], cfg.k[1]), _fr(cfg.k[0] * cfg.k[0], cfg.k[1] * cfg.k[1])],
				 "nudge": "面積比是 k^{2}。"},
				_f("邊長比", "面積比開根號", "\\ol{EC} : \\ol{FB} = [0] : [1]", [str(cfg.k[0]), str(cfg.k[1])],
					"面積比 %s ⇒ \\ol{EC} : \\ol{FB} = %d : %d" % [ra, cfg.k[0], cfg.k[1]], "面積比是邊長比的平方。", T_DAPP, "prop"),
				_f("分線段", "對應邊的比", "\\ol{FP} : \\ol{PC} = [0] : [1]", [str(cfg.k[1]), str(cfg.k[0])],
					"\\ol{FP} : \\ol{PC} = \\ol{FB} : \\ol{EC} = %d : %d" % [cfg.k[1], cfg.k[0]],
					"△PFB 和 △PCE 相似：\\ol{FP} 對應 \\ol{CP}。", T_DAPP, "prop"),
				_f("係數", "分點再換基底", "\\vec{AP} = [0]\\vec{AB} + [1]\\vec{AD}", cfg.xy,
					"\\vec{AP} = " + _lin(cfg.xy[0], "AB", cfg.xy[1], "AD"),
					"\\vec{AP} 用 \\vec{AF}、\\vec{AC} 的分點寫，再代 \\vec{AC} = \\vec{AB} + \\vec{AD}。", T_DIV),
			]})
	return {"id": "zoom", "chapter": 2, "type": "forge", "title": "縮放鏡",
		"story": "用縮放鏡把小三角形放大，疊到大三角形上。",
		"insight": "相似三角形：面積比 = 邊長比的平方\n邊長比找出 \\ol{FP} : \\ol{PC}，再用分點公式、換成 \\vec{AB}、\\vec{AD}。",
		"variants": vars}
