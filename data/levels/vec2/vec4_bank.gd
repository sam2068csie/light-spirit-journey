extends RefCounted
## 平面向量 第四大關「長弓靶場」題庫（上冊 3-2 重點二、三：求長度、求夾角）
## 設計稿：docs/vec2_v4_design.md。數字都用程式驗算過（tools/vec2/verify_v4.py）。
##
## 引擎見 vec_level.gd（箭頭畫布、在圖上作答），圖層見 vec_board.gd。這一關多用了：
##   vplace 沙盒的 protractor（量角器）＋ goal "guess"（先猜）、sum（合起來的箭）、
##   圖層 protractor（量角器的指針，答對後從猜的角度轉到正確的角度）、3 × 3 的 expand（展開田）、
##   滑桿裡的弓弦（\vec{a} + t\vec{b} 的尖端）和角落的拋物線。填空有「√」鍵（關卡的 radicals_ok）。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/vec2/vec1_bank.gd")
const B2 := preload("res://data/levels/vec2/vec2_bank.gd")
const B3 := preload("res://data/levels/vec2/vec3_bank.gd")

const T_LEN := "vec_len"          # 長度平方 = 內積展開
const T_MIN := "vec_lenmin"       # 長度的範圍、最小值
const T_ANG := "vec_angle"        # 求夾角、夾角的條件


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


static func _line(p: Vector2, q: Vector2, c := "faint", extra := {}) -> Dictionary:
	return B3._line(p, q, c, extra)


static func _right(p: Vector2, u: Vector2, v: Vector2, extra := {}) -> Dictionary:
	return B3._right(p, u, v, extra)


static func _expand(p: Vector2, rows: Array, cols: Array, cells: Array, sg: Array, at: int, extra := {}) -> Dictionary:
	return B3._expand(p, rows, cols, cells, sg, at, extra)


static func _pt(v: Vector2) -> String:
	return B2._pt(v)


static func _e(v: float) -> String:
	return B3._e(v)


## 角的小弧（從 d0 轉到 d1，度）
static func _arc(o: Vector2, d0: float, d1: float, s := "", extra := {}) -> Dictionary:
	var d := {"k": "angle", "o": _p(o), "a0": minf(d0, d1), "a1": maxf(d0, d1), "r": 24, "c": "gold", "s": s}
	d.merge(extra, true)
	return d


static func _deg(v: Vector2) -> float:
	return rad_to_deg(v.angle())


## 量角器先猜：拖指針（轉箭頭，每 5°），放哪裡都算
static func _guess(o: Vector2, r: float, base: Vector2, side: float, name: String, extra := {}) -> Dictionary:
	var a0 := _deg(base)
	var c := cos(deg_to_rad(a0))
	var s := sin(deg_to_rad(a0))
	var ex := "acos(((x - (%s)) * %s + (y - (%s)) * %s) / %s) * 57.2957795" % [_e(o.x), str(c), _e(o.y), str(s), str(r)]
	var st := {"kind": "vplace", "name": "先猜", "q": "拖指針，猜 %s 是幾度" % name, "goal": "guess", "tag": T_ANG, "big": true,
		"sandbox": {"label": "", "ring": {"o": _p(o), "r": r, "step": 5, "a0": a0}, "arrow": {"o": _p(o), "c": "gold"},
			"protractor": {"o": _p(o), "r": r, "a0": a0, "side": side}, "lit": [],
			"read": "%s ≈ {%s}°" % [name, ex], "start": _p(o + base.normalized() * r)},
		"ans": _p(o + base.normalized().rotated(deg_to_rad(side * 90.0)) * r),
		"nudge": "放哪裡都可以，先猜猜看。", "line": "先猜：%s ≈ {guess}°" % name}
	st.merge(extra, true)
	return st


## 量角器的指針：答對後從猜的角度轉到正確的角度
static func _hand(o: Vector2, r: float, base: Vector2, side: float, deg: float, at: int) -> Dictionary:
	return {"k": "protractor", "o": _p(o), "p": _p(o + base), "r": r, "a0": _deg(base), "side": side, "deg": deg, "guess": true, "at": at, "dur": 1.2}


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
		_diag(), _two_targets(), _bend(), _range(), _rail(), _center(),
		{"id": "speed1", "chapter": 1, "type": "speed", "title": "長度速算", "time": 120.0,
		 "story": "兩支箭合起來飛多遠？展開就知道！",
		 "insight": "|\\vec{a} + \\vec{b}|^{2} = |\\vec{a}|^{2} + 2|\\vec{a}||\\vec{b}|cos θ + |\\vec{b}|^{2}\ncos 60° = \\frac{1}{2}、cos 90° = 0、cos 120° = −\\frac{1}{2}。",
		 "variants": [{"gen": "len", "count": 8}]},
		_sign_cards(), _coord_angle(), _fake(), _flags(), _len_angle(), _right_axes(),
		{"id": "speed2", "chapter": 2, "type": "speed", "title": "角度速算", "time": 120.0,
		 "story": "量角器一格一格亮起來，看坐標說角度！",
		 "insight": "cos θ = \\frac{\\vec{a} · \\vec{b}}{|\\vec{a}||\\vec{b}|}\n內積是 0：90°。cos θ = ±\\frac{√2}{2}：45° 或 135°。",
		 "variants": [{"gen": "ang", "count": 8}]},
	]


# ======================= 第一章．求長度 =======================

## 1 兩條對角線（新）
static func _diag() -> Dictionary:
	var vars := []
	for cfg in [{"la": 3.0, "lb": 4.0, "th": 60.0, "ab": "6", "p": ["37", "√37"], "m": ["13", "√13"], "x": [-0.8, 12.0], "y": [-0.8, 4.4], "ep": Vector2(6.8, 4.2)},
			{"la": 4.0, "lb": 2.0, "th": 120.0, "ab": "−4", "p": ["12", "2√3"], "m": ["28", "2√7"], "x": [-2.0, 11.0], "y": [-0.9, 3.2], "ep": Vector2(5.4, 3.1)}]:
		var a := Vector2(cfg.la, 0)
		var b := Vector2.from_angle(deg_to_rad(cfg.th)) * float(cfg.lb)
		var O := Vector2.ZERO
		var shapes := [_poly([O, a, a + b, b], "faint"), _ar(O, a, "cyan", "\\vec{a}", {"ls": -1}), _ar(O, b, "pink", "\\vec{b}"),
			_arc(O, 0, cfg.th, "%d°" % int(cfg.th)),
			_expand(cfg.ep, ["\\vec{a}", "\\vec{b}"], ["\\vec{a}", "\\vec{b}"], [["|\\vec{a}|^{2}", "\\vec{a} · \\vec{b}"], ["\\vec{a} · \\vec{b}", "|\\vec{b}|^{2}"]],
				[[1, 1 if cfg.th < 90.0 else -1], [1 if cfg.th < 90.0 else -1, 1]], 0),
			_ar(O, a + b, "gold", cfg.p[1], {"at": 2, "lt": 0.6}), _seg(b, a, "lime", {"at": 3, "w": 3.0}),
			{"k": "label", "p": _p((a + b) / 2.0 + Vector2(0.5, -0.35)), "s": cfg.m[1], "c": "lime", "at": 3}]
		vars.append({"eq": "|\\vec{a}| = %s，|\\vec{b}| = %s，夾角 %d°\n以 \\vec{a}、\\vec{b} 為兩邊的平行四邊形，兩條對角線各多長？" % [B1._n(cfg.la), B1._n(cfg.lb), int(cfg.th)],
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				_f("展開田", "|\\vec{a} + \\vec{b}|^{2}", "|\\vec{a} + \\vec{b}|^{2} = [0]", [cfg.p[0]],
					"|\\vec{a} + \\vec{b}|^{2} = %s + 2(%s) + %s = %s" % [B1._n(cfg.la * cfg.la), cfg.ab, B1._n(cfg.lb * cfg.lb), cfg.p[0]],
					"\\vec{a} · \\vec{b} = %s × %s × cos %d° = %s。四格加起來。" % [B1._n(cfg.la), B1._n(cfg.lb), int(cfg.th), cfg.ab], T_LEN),
				_f("對角線", "開根號", "|\\vec{a} + \\vec{b}| = [0]", [cfg.p[1]], "\\vec{a} + \\vec{b} 那一條對角線 = %s" % cfg.p[1], "√%s 化簡。" % cfg.p[0], T_LEN),
				_f("另一條", "|\\vec{a} − \\vec{b}|", "|\\vec{a} − \\vec{b}|^{2} = [0]，|\\vec{a} − \\vec{b}| = [1]", cfg.m,
					"|\\vec{a} − \\vec{b}|^{2} = %s − 2(%s) + %s = %s，另一條 = %s" % [B1._n(cfg.la * cfg.la), cfg.ab, B1._n(cfg.lb * cfg.lb), cfg.m[0], cfg.m[1]],
					"中間兩格變成 −\\vec{a} · \\vec{b}。", T_LEN),
			]})
	return {"id": "diag", "chapter": 1, "type": "forge", "title": "兩條對角線",
		"story": "兩支箭夾一個角，對角線就是合起來的箭。",
		"insight": "|\\vec{a} ± \\vec{b}|^{2} = |\\vec{a}|^{2} ± 2\\vec{a} · \\vec{b} + |\\vec{b}|^{2}\n長度的平方 = 自己和自己的內積，展開就好。",
		"variants": vars}


## 2 兩個靶之間（A51）
static func _two_targets() -> Dictionary:
	var vars := []
	for cfg in [{"la": 3.0, "lb": 1.0, "th": 60.0, "P": [1, 2], "Q": [2, 3], "sol": [[0, 1], [1, 1]], "d": "\\vec{a} + \\vec{b}", "L": ["13", "√13"],
				"ex": "9 + 2 × \\frac{3}{2} + 1 = 13", "x": [-1.0, 9.0], "y": [-0.8, 3.4]},
			{"la": 2.0, "lb": 2.0, "th": 120.0, "P": [3, -1], "Q": [4, 1], "sol": [[0, 1], [1, 1], [1, 1]], "d": "\\vec{a} + 2\\vec{b}", "L": ["12", "2√3"],
				"ex": "4 + 4(−2) + 4 × 4 = 12", "x": [-2.5, 9.5], "y": [-2.6, 2.6]}]:
		var a := Vector2(cfg.la, 0)
		var b := Vector2.from_angle(deg_to_rad(cfg.th)) * float(cfg.lb)
		var P: Vector2 = a * float(cfg.P[0]) + b * float(cfg.P[1])
		var Q: Vector2 = a * float(cfg.Q[0]) + b * float(cfg.Q[1])
		var O := Vector2.ZERO
		var shapes := [{"k": "skew", "o": [0, 0], "a": _p(a), "b": _p(b), "i": [-1, 5], "j": [-3, 4], "c": "cyan"},
			_ar(O, a, "cyan", "\\vec{a}", {"ls": -1, "w": 2.5}), _ar(O, b, "pink", "\\vec{b}", {"w": 2.5}),
			_dot(O, "O", "dim", {"off": [-14, 14]}), _dot(P, "P", "gold", {"off": [8, 14]}), _dot(Q, "Q", "gold", {"off": [8, -6]}),
			_ar(P, Q, "gold", "", {"at": 1, "w": 3.5})]
		var lin := func(c: Array) -> String:
			return B1._lin(str(c[0]), "a", str(c[1]), "b")
		vars.append({"eq": "|\\vec{a}| = %s，|\\vec{b}| = %s，夾角 %d°\n\\vec{OP} = %s，\\vec{OQ} = %s，求 |\\vec{PQ}|" % [B1._n(cfg.la), B1._n(cfg.lb), int(cfg.th), lin.call(cfg.P), lin.call(cfg.Q)],
			"plane": _plane(cfg.x, cfg.y, shapes, {}, {"grid": "none"}),
			"steps": [
				{"kind": "vpath", "name": "鋪路", "q": "從 P 鋪到 Q", "from": _p(P), "to": _p(Q), "tag": T_LEN,
				 "tiles": [{"s": "\\vec{a}", "v": _p(a)}, {"s": "\\vec{b}", "v": _p(b)}], "sol": cfg.sol,
				 "nudge": "\\vec{PQ} = \\vec{OQ} − \\vec{OP}：\\vec{a}、\\vec{b} 各差幾支？", "line": "\\vec{PQ} = \\vec{OQ} − \\vec{OP} = %s" % cfg.d},
				_f("平方", "|\\vec{PQ}|^{2} 展開", "|\\vec{PQ}|^{2} = [0]", [cfg.L[0]], "|\\vec{PQ}|^{2} = %s" % cfg.ex,
					"\\vec{a} · \\vec{b} = %s × %s × cos %d°。" % [B1._n(cfg.la), B1._n(cfg.lb), int(cfg.th)], T_LEN),
				_f("長度", "開根號", "|\\vec{PQ}| = [0]", [cfg.L[1]], "|\\vec{PQ}| = %s" % cfg.L[1], "√%s 化簡。" % cfg.L[0], T_LEN),
			]})
	return {"id": "targets", "chapter": 1, "type": "forge", "title": "兩個靶之間",
		"story": "兩個靶之間差了哪幾支箭？",
		"insight": "\\vec{PQ} = \\vec{OQ} − \\vec{OP}：先化成 \\vec{a}、\\vec{b} 的組合\n再把長度平方展開：|x\\vec{a} + y\\vec{b}|^{2} = x^{2}|\\vec{a}|^{2} + 2xy\\vec{a} · \\vec{b} + y^{2}|\\vec{b}|^{2}。",
		"variants": vars}


## 3 拉弓的角度（A52）
static func _bend() -> Dictionary:
	var vars := []
	for cfg in [{"la": 2.0, "lb": 1.0, "th": 60.0, "eq": "|\\vec{a}| = 2，|\\vec{b}| = 1，|\\vec{a} + 3\\vec{b}| = √19\n求 \\vec{a} · \\vec{b} 和 |2\\vec{a} − \\vec{b}|",
				"f1": ["19", "4", "6", "9"], "ab": "1", "q2": "|2\\vec{a} − \\vec{b}|", "L": ["13", "√13"], "ex": "16 − 4 + 1", "x": [-1.8, 3.6], "y": [-1.2, 1.4]},
			{"la": 3.0, "lb": 2.0, "th": 120.0, "eq": "|\\vec{a}| = 3，|\\vec{b}| = 2，|2\\vec{a} + \\vec{b}| = 2√7\n求 \\vec{a} · \\vec{b} 和 |\\vec{a} − \\vec{b}|",
				"f1": ["28", "36", "4", "4"], "ab": "-3", "q2": "|\\vec{a} − \\vec{b}|", "L": ["19", "√19"], "ex": "9 + 6 + 4", "x": [-3.4, 4.4], "y": [-2.4, 2.6]}]:
		var a := Vector2(cfg.la, 0)
		var b := Vector2.from_angle(deg_to_rad(cfg.th)) * float(cfg.lb)
		var O := Vector2.ZERO
		var f1: Array = cfg.f1
		var shapes := [_ar(O, a, "cyan", "\\vec{a}", {"ls": -1}), {"k": "circle", "o": [0, 0], "r": cfg.lb, "c": "faint", "dash": true, "until": 2},
			_ar(O, b, "pink", "\\vec{b}", {"at": 2}), _arc(O, 0, cfg.th, "%d°" % int(cfg.th), {"at": 2})]
		var tpl := "[0] = [1] + [2]\\vec{a} · \\vec{b} + [3]"
		vars.append({"eq": cfg.eq, "plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				_f("展開田", "長度平方展開", tpl, f1, "%s = %s + %s\\vec{a} · \\vec{b} + %s" % f1, "已知的長度平方，展開成三項。", T_LEN),
				_f("內積", "解出 \\vec{a} · \\vec{b}", "\\vec{a} · \\vec{b} = [0]", [cfg.ab],
					"\\vec{a} · \\vec{b} = %s（夾角 %d°）" % [B2._fv(float(cfg.ab)), int(cfg.th)], "移項：%s − %s − %s，再除以 %s。" % [f1[0], f1[1], f1[3], f1[2]], T_LEN),
				_f("另一支", cfg.q2, cfg.q2 + "^{2} = [0]，" + cfg.q2 + " = [1]", cfg.L, "%s^{2} = %s = %s，%s = %s" % [cfg.q2, cfg.ex, cfg.L[0], cfg.q2, cfg.L[1]],
					"再展開一次，\\vec{a} · \\vec{b} 用剛才算的。", T_LEN),
			]})
	return {"id": "bend", "chapter": 1, "type": "forge", "title": "拉弓的角度",
		"story": "知道合起來多長，就知道弓拉開多大。",
		"insight": "已知長度求內積：把已知的長度平方展開，\\vec{a} · \\vec{b} 是唯一的未知數\n求出內積之後，其他組合的長度都能算。",
		"variants": vars}


## 4 最遠和最近的靶（A53）
static func _range() -> Dictionary:
	var vars := []
	for cfg in [{"la": 3.0, "lb": 2.0, "k": 2, "th": 120.0, "lo": "1", "hi": 7.0, "L": ["13", "√13"], "x": [-6.0, 12.0], "y": [-4.6, 4.6]},
			{"la": 5.0, "lb": 1.0, "k": 3, "th": 60.0, "lo": "2", "hi": 8.0, "L": ["49", "7"], "x": [-3.5, 12.5], "y": [-3.8, 3.8]}]:
		var la: float = cfg.la
		var r := float(cfg.k) * float(cfg.lb)
		var a := Vector2(la, 0)
		var O := Vector2.ZERO
		var kb := "%d\\vec{b}" % cfg.k
		var lo := Vector2(la - r, 0)
		var hi := Vector2(la + r, 0)
		var at := a + Vector2.from_angle(deg_to_rad(cfg.th)) * r
		var shapes := [_ar(O, a, "cyan", "\\vec{a}", {"ls": -1}), _dot(O, "O", "dim", {"off": [-14, 14]}),
			{"k": "circle", "o": _p(a), "r": r, "c": "faint", "dash": true, "at": 1},
			_dot(lo, "", "lime", {"at": 1}), _dot(hi, "", "lime", {"at": 1}),
			_ar(a, at, "pink", kb, {"at": 3}), _ar(O, at, "gold", cfg.L[1], {"at": 3, "w": 3.5})]
		var sbx := {"label": "", "ring": {"o": _p(a), "r": r, "step": 15}, "arrow": {"o": _p(a), "c": "pink", "s": kb}, "sum": {"o": [0, 0]},
			"lit": "abs(sqrt(x * x + y * y) - %s) < 0.01" % cfg.lo, "read": "|\\vec{a} + %s| ≈ {sqrt(x * x + y * y)}" % kb,
			"start": _p(a + Vector2.from_angle(deg_to_rad(60.0)) * r)}
		vars.append({"eq": "|\\vec{a}| = %s，|\\vec{b}| = %s，夾角不知道\n|\\vec{a} + %s| 最小是多少？夾角 %d° 時是多少？" % [B1._n(la), B1._n(cfg.lb), kb, int(cfg.th)],
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "最近", "q": "轉 %s，讓金色的箭最短" % kb, "sandbox": sbx, "goal": "lit", "ans": _p(lo), "tag": T_MIN, "big": true,
				 "nudge": "%s 的尖端在一個圓上：圓上哪一點離 O 最近？" % kb, "line": "%s 和 \\vec{a} 反方向時最短（同方向時最長，|\\vec{a} + %s| 介於 %s 和 %s 之間）" % [kb, kb, cfg.lo, B1._n(cfg.hi)]},
				_f("最小值", "反方向：長度相減", "最小值 = [0]", [cfg.lo], "最小值 = |%s − %s| = %s" % [B1._n(r), B1._n(la), cfg.lo], "%s 的長度是 %s，\\vec{a} 是 %s。" % [kb, B1._n(r), B1._n(la)], T_MIN),
				_f("%d°" % int(cfg.th), "夾角 %d° 時" % int(cfg.th), "|\\vec{a} + %s|^{2} = [0]，長度 = [1]" % kb, cfg.L,
					"|\\vec{a} + %s|^{2} = %s %s %s + %s = %s，長度 = %s" % [kb, B1._n(la * la), "+" if cfg.th < 90.0 else "−", B1._n(absf(roundf(2.0 * la * r * cos(deg_to_rad(cfg.th))))), B1._n(r * r), cfg.L[0], cfg.L[1]],
					"2 × \\vec{a} · %s = 2 × %s × %s × cos %d°。" % [kb, B1._n(la), B1._n(r), int(cfg.th)], T_LEN),
			]})
	return {"id": "range", "chapter": 1, "type": "forge", "title": "最遠和最近的靶",
		"story": "第二支箭接在第一支的頭上轉一圈，哪裡最近？",
		"insight": "||\\vec{a}| − |\\vec{b}|| ≤ |\\vec{a} + \\vec{b}| ≤ |\\vec{a}| + |\\vec{b}|\n反方向最短、同方向最長。",
		"variants": vars}


## 5 弓弦上最近的點（A55）
static func _rail() -> Dictionary:
	var vars := []
	for cfg in [{"la": 2.0, "lb": 1.0, "th": 120.0, "t": 1.0, "rng": [-2.0, 3.0], "f3": ["-1", "1"], "m": "√3", "m2": "3",
				"x": [-1.5, 9.0], "y": [-2.2, 3.0], "in": [4.6, -1.8, 0.8, 0.3]},
			{"la": 4.0, "lb": 2.0, "th": 60.0, "t": -1.0, "rng": [-3.0, 1.0], "f3": ["4", "4"], "m": "2√3", "m2": "12",
				"x": [-2.0, 13.0], "y": [-5.6, 2.4], "in": [7.0, -5.2, 1.1, 0.2]}]:
		var la: float = cfg.la
		var lb: float = cfg.lb
		var a := Vector2(la, 0)
		var b := Vector2.from_angle(deg_to_rad(cfg.th)) * lb
		var ab := la * lb * cos(deg_to_rad(cfg.th))
		var tt: float = cfg.t
		var tip := a + b * tt
		var O := Vector2.ZERO
		var rng: Array = cfg.rng
		var ins: Array = cfg["in"]
		# 角落的拋物線：X = x0 + (t − t0)·sx、Y = y0 + f(t)·sy
		var fx := "(%s) + (%s) * t + (%s) * t * t" % [str(la * la), str(2.0 * ab), str(lb * lb)]
		var para := []
		for k in 41:
			var t := lerpf(float(rng[0]), float(rng[1]), k / 40.0)
			var fv := la * la + 2.0 * ab * t + lb * lb * t * t
			para.append(Vector2(float(ins[0]) + (t - float(rng[0])) * float(ins[2]), float(ins[1]) + fv * float(ins[3])))
		var shapes := [_ar(O, a, "dim", "\\vec{a}", {"ls": -1, "w": 2.0}), _ar(O, b, "pink", "\\vec{b}", {"w": 2.5}),
			_line(a, a + b, "gold", {"dash": true}), _dot(O, "O", "dim", {"off": [-14, 14]}),
			_poly(para, "gold", {"open": true, "w": 1.6}),
			_seg(Vector2(float(ins[0]), float(ins[1])), Vector2(float(ins[0]) + (float(rng[1]) - float(rng[0])) * float(ins[2]), float(ins[1])), "faint"),
			_ar(O, tip, "cyan", cfg.m, {"at": 1, "w": 3.5}), _right(tip, b, -tip, {"at": 2})]
		var lines := [{"k": "arrow", "a": [0, 0], "b": ["%s + t * %s" % [_e(a.x), str(b.x)], "t * %s" % str(b.y)], "c": "cyan", "w": 3.0},
			{"k": "dot", "p": ["%s + (t - (%s)) * %s" % [str(ins[0]), str(rng[0]), str(ins[2])], "%s + (%s) * %s" % [str(ins[1]), fx, str(ins[3])]], "c": "gold"},
			{"k": "right", "p": ["%s + t * %s" % [_e(a.x), str(b.x)], "t * %s" % str(b.y)], "u": [b.x, b.y], "v": ["-(%s + t * %s)" % [_e(a.x), str(b.x)], "-(t * %s)" % str(b.y)],
				"c": "gold", "when": "abs(t - (%s)) < 0.01" % _e(tt)}]
		var f3: Array = cfg.f3
		vars.append({"eq": "|\\vec{a}| = %s，|\\vec{b}| = %s，夾角 %d°\n求 |\\vec{a} + t\\vec{b}| 的最小值和那時的 t" % [B1._n(la), B1._n(lb), int(cfg.th)],
			"plane": _plane(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "slide", "name": "拉弓弦", "q": "拖 t，找最短的那一支", "tag": T_MIN, "big": true,
				 "params": [{"n": "t", "min": rng[0], "max": rng[1], "step": 0.25, "v": rng[1]}], "lines": lines,
				 "eq": "t = {t}，|\\vec{a} + t\\vec{b}| ≈ {sqrt(%s)}" % fx, "goal": {"t": tt},
				 "line": "t = %s 時最短：拋物線的最低點" % B2._fv(tt), "nudge": "看角落的拋物線：最低點在哪裡？"},
				_c("為什麼", "最短的時候？", ["\\vec{a} + t\\vec{b} ⊥ \\vec{b}", "\\vec{a} + t\\vec{b} ∥ \\vec{a}", "t = 0"], 0,
					"箭的尖端在弓弦（\\vec{b} 的方向）上滑，離 O 最近的點是垂足：最短的箭和弓弦垂直。",
					"點到直線的最短距離是哪一條？", "最短時 (\\vec{a} + t\\vec{b}) ⊥ \\vec{b}", T_MIN),
				_f("t", "內積 = 0", "(\\vec{a} + t\\vec{b}) · \\vec{b} = [0] + [1]t = 0", f3,
					"\\vec{a} · \\vec{b} + t|\\vec{b}|^{2} = 0 ⇒ t = %s" % B2._fv(tt), "\\vec{a} · \\vec{b} = %s、|\\vec{b}|^{2} = %s。" % [B2._fv(ab), B1._n(lb * lb)], T_MIN, "prop"),
				_f("最小值", "t 代回去", "最小值 = [0]", [cfg.m], "|\\vec{a} + t\\vec{b}|^{2} = %s，最小值 = %s" % [cfg.m2, cfg.m], "把 t = %s 代進長度平方。" % B2._fv(tt), T_MIN),
			]})
	return {"id": "rail", "chapter": 1, "type": "forge", "title": "弓弦上最近的點",
		"story": "箭的尖端沿著弓弦滑，哪一支最短？",
		"insight": "|\\vec{a} + t\\vec{b}|^{2} 是 t 的二次函數（拋物線）\n最短時 (\\vec{a} + t\\vec{b}) ⊥ \\vec{b}：t = −\\frac{\\vec{a} · \\vec{b}}{|\\vec{b}|^{2}}。",
		"variants": vars}


## 6 靶心的箭（A54、A56）
static func _center() -> Dictionary:
	var vars := []
	# 變化 A：外心，R = 4
	var R := 4.0
	var O := Vector2.ZERO
	var A := Vector2.from_angle(deg_to_rad(90.0)) * R
	var B := Vector2.from_angle(deg_to_rad(210.0)) * R
	var C := Vector2.from_angle(deg_to_rad(0.0)) * R
	var sa := [{"k": "circle", "o": [0, 0], "r": R, "c": "faint"}, _poly([A, B, C], "dim")]
	sa += _dots({"A": A, "B": B, "C": C}, "text", {"A": [-4, -12], "B": [-16, 14], "C": [8, 4]})
	sa += [_dot(O, "O", "dim", {"off": [-16, 12]}), _ar(O, A, "cyan", "", {"w": 2.0}), _ar(O, B, "pink", "", {"w": 2.0}), _ar(O, C, "lime", "", {"w": 2.0}),
		_arc(O, 90, 210, "120°", {"at": 1}), _arc(O, 0, 90, "90°", {"at": 1, "r": 34}), _arc(O, 210, 360, "150°", {"at": 1, "r": 18}),
		_expand(Vector2(-15.6, 4.4), ["\\vec{OA}", "\\vec{OB}", "\\vec{OC}"], ["\\vec{OA}", "\\vec{OB}", "\\vec{OC}"],
			[["16", "−8", "0"], ["−8", "16", "−8√3"], ["0", "−8√3", "16"]], [[1, -1, 0], [-1, 1, -1], [0, -1, 1]], 1, {"cw": 74, "ch": 38}),
		B1._walk([O, A, A + B, A + B + C], 3, "gold", true),
		_ar(O, A + B + C, "gold", "", {"at": 3, "w": 4.0})]
	vars.append({"eq": "△ABC 中，∠A = 75°，∠B = 45°，O 是外心\n外接圓半徑 4，求 |\\vec{OA} + \\vec{OB} + \\vec{OC}|",
		"plane": _plane([-16.0, 5.2], [-4.8, 4.8], sa),
		"steps": [
			_f("圓心角", "圓心角 = 2 × 圓周角", "∠BOC = [0]°，∠COA = [1]°，∠AOB = [2]°", ["150", "90", "120"],
				"∠BOC = 2∠A = 150°、∠COA = 2∠B = 90°、∠AOB = 2∠C = 120°", "∠C = 180° − 75° − 45° = 60°。", T_LEN),
			_f("展開田", "九格加起來", "|\\vec{OA} + \\vec{OB} + \\vec{OC}|^{2} = [0] − [1]√3", ["32", "16"],
				"|\\vec{OA} + \\vec{OB} + \\vec{OC}|^{2} = 3 × 16 + 2(−8 + 0 − 8√3) = 32 − 16√3", "對角線三格 16，其他六格兩兩一樣：16cos 120°、16cos 90°、16cos 150°。", T_LEN),
			_c("開根號", "32 − 16√3 是誰的平方？", ["2√6 − 2√2", "2√6 + 2√2", "4√2"], 0,
				"(2√6 − 2√2)^{2} = 24 − 8√12 + 8 = 32 − 16√3。", "(√x − √y)^{2} = x + y − 2√(xy)。", "|\\vec{OA} + \\vec{OB} + \\vec{OC}| = 2√6 − 2√2", T_LEN),
		]})
	# 變化 B：角平分線，AB = 3、AC = 6、BC = 7
	var Ab := Vector2.ZERO
	var Bb := Vector2(3, 0)
	var cs := -1.0 / 9.0
	var Cb := Vector2(cs, sqrt(1.0 - cs * cs)) * 6.0
	var Db := Bb * (2.0 / 3.0) + Cb / 3.0
	var sb := [_poly([Ab, Bb, Cb], "dim")]
	sb += _dots({"A": Ab, "B": Bb, "C": Cb}, "text", {"A": [-14, 14], "B": [6, 14], "C": [-16, -4]})
	sb += [{"k": "ruler", "a": _p(Bb), "b": _p(Cb), "n": 3, "m": 1, "at": 1, "c": "gold"}, _dot(Db, "D", "gold", {"at": 1, "off": [8, 4]}),
		_seg(Ab, Db, "faint", {"dash": true, "until": 3}), _seg(Ab, Db, "gold", {"at": 3, "w": 3.5}),
		_expand(Vector2(4.2, 6.4), ["\\frac{2}{3}\\vec{AB}", "\\frac{1}{3}\\vec{AC}"], ["\\frac{2}{3}\\vec{AB}", "\\frac{1}{3}\\vec{AC}"],
			[["4", "−\\frac{4}{9}"], ["−\\frac{4}{9}", "4"]], [[1, -1], [-1, 1]], 2, {"hw": 72})]
	vars.append({"eq": "△ABC 中，\\ol{AB} = 3，\\ol{AC} = 6，\\ol{BC} = 7\n\\ol{AD} 是 ∠A 的平分線，交 \\ol{BC} 於 D，求 \\ol{AD}",
		"plane": _plane([-1.6, 10.6], [-0.8, 6.6], sb),
		"steps": [
			_f("分點", "\\ol{BD} : \\ol{DC} = \\ol{AB} : \\ol{AC}", "\\vec{AD} = [0]\\vec{AB} + [1]\\vec{AC}", ["2/3", "1/3"],
				"\\ol{BD} : \\ol{DC} = 3 : 6 = 1 : 2 ⇒ \\vec{AD} = \\frac{2}{3}\\vec{AB} + \\frac{1}{3}\\vec{AC}", "係數交叉：靠近 B，\\vec{AB} 的係數大。", T_LEN),
			_f("基底的內積", "三邊求 \\vec{AB} · \\vec{AC}", "\\vec{AB} · \\vec{AC} = [0]", ["-2"],
				"|\\vec{BC}|^{2} = |\\vec{AC} − \\vec{AB}|^{2}：49 = 36 − 2\\vec{AB} · \\vec{AC} + 9，\\vec{AB} · \\vec{AC} = −2", "\\vec{BC} = \\vec{AC} − \\vec{AB}，兩邊平方。", T_LEN),
			_f("展開田", "|\\vec{AD}|^{2}", "|\\vec{AD}|^{2} = [0]，\\ol{AD} = [1]", ["64/9", "8/3"],
				"|\\vec{AD}|^{2} = 4 − \\frac{8}{9} + 4 = \\frac{64}{9}，\\ol{AD} = \\frac{8}{3}", "四格：\\frac{4}{9} × 9、\\frac{2}{9} × (−2) 兩格、\\frac{1}{9} × 36。", T_LEN),
		]})
	return {"id": "center", "chapter": 1, "type": "forge", "title": "靶心的箭",
		"story": "三支箭從靶心射向圓上，合起來多長？",
		"insight": "幾支向量的和：長度平方展開成九格（或四格），對角線是長度平方\n外心：|\\vec{OA}| = |\\vec{OB}| = |\\vec{OC}| = R，圓心角是圓周角的 2 倍。",
		"variants": vars}


# ======================= 第二章．求夾角 =======================

## 8 正負和角度（新）
static func _sign_cards() -> Dictionary:
	var a := Vector2(3, 0)
	var O := Vector2.ZERO
	var vars := []
	for cards in [
			[["\\vec{a} · \\vec{b} > 0 ⇒ 夾角是銳角", false, "x > 1.99", [2, 0], "夾角 0°（同方向）時內積也是正的，可是 0° 不是銳角。", "反例：同方向"],
			 ["夾角是銳角 ⇒ \\vec{a} · \\vec{b} > 0", true, "", [], "0° < θ < 90° 時 cos θ > 0。", ""],
			 ["\\vec{a} · \\vec{b} < 0 ⇒ 夾角是鈍角", false, "x < -1.99", [-2, 0], "夾角 180°（反方向）時內積也是負的，可是 180° 不是鈍角。", "反例：反方向"],
			 ["\\vec{a} · \\vec{b} = 0 ⇔ \\vec{a} ⊥ \\vec{b}", true, "", [], "非零向量：cos θ = 0 ⇔ θ = 90°。", ""]],
			[["\\vec{a} · \\vec{b} = |\\vec{a}||\\vec{b}| ⇒ 夾角 0°", true, "", [], "cos θ = 1 ⇒ θ = 0°。", ""],
			 ["\\vec{a} · \\vec{b} = −|\\vec{a}||\\vec{b}| ⇒ 夾角 180°", true, "", [], "cos θ = −1 ⇒ θ = 180°。", ""],
			 ["\\vec{a} · \\vec{b} = 0 ⇒ \\vec{a} = \\vec{0} 或 \\vec{b} = \\vec{0}", false, "abs(x) < 0.01", [0, 2], "兩支都不是零向量也可以：垂直的時候內積就是 0。", "反例：垂直"],
			 ["夾角是鈍角 ⇒ \\vec{a} · \\vec{b} < 0", true, "", [], "90° < θ < 180° 時 cos θ < 0。", ""]]]:
		var shapes := [_line(O, a, "faint"), _ar(O, a, "cyan", "\\vec{a}", {"ls": -1, "w": 3.0}), {"k": "circle", "o": [0, 0], "r": 2, "c": "faint", "dash": true}]
		var steps := []
		var k := 0
		for cd in cards:
			k += 1
			var ok: bool = cd[1]
			var st := _j(["審判一", "審判二", "審判三", "審判四"][k - 1], String(cd[0]), ok, String(cd[4]),
				String(cd[0]) + ("" if ok else " ✕"), T_ANG)
			st["big"] = true
			steps.append(st)
			if not ok:
				steps.append({"kind": "vplace", "name": "反例", "q": "轉 \\vec{b}，找一個反例", "tag": T_ANG, "goal": "lit", "ans": cd[3], "big": true,
					"sandbox": {"label": "", "ring": {"o": [0, 0], "r": 2, "step": 15}, "arrow": {"o": [0, 0], "c": "pink", "s": "\\vec{b}"},
						"lit": String(cd[2]), "start": [1.0, 1.7320508],
						"read": "θ = {acos(x / 2) * 57.2957795}°，\\vec{a} · \\vec{b} = {3 * x}"},
					"nudge": "轉到內積 %s 但角度不是那一種的地方。" % ("是正的" if k == 1 else ("是負的" if k == 3 else "是 0")),
					"line": String(cd[5])})
		vars.append({"eq": "\\vec{a}、\\vec{b} 是非零向量\n下面哪些一定成立？", "plane": _plane([-5.5, 5.5], [-2.6, 2.6], shapes), "steps": steps})
	return {"id": "signs", "chapter": 2, "type": "forge", "title": "正負和角度",
		"story": "內積是正的，夾角就一定是銳角嗎？",
		"insight": "\\vec{a} · \\vec{b} > 0 ⇔ 0° ≤ θ < 90°（0° 也算），< 0 ⇔ 90° < θ ≤ 180°\n= 0 ⇔ 垂直（非零向量）。",
		"variants": vars}


## 9 坐標量角度（A57）
static func _coord_angle() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(4, 5), "B": Vector2(1, 1), "C": Vector2(8, 2), "d": "25", "L": ["5", "5√2"], "c": "√2/2", "deg": 45, "r": 2.4, "x": [-1.5, 9.5], "y": [-1.2, 6.2]},
			{"A": Vector2(4, 0), "B": Vector2(2, -1), "C": Vector2(-1, 0), "d": "-5", "L": ["√5", "√10"], "c": "-√2/2", "deg": 135, "r": 1.6, "x": [-2.5, 5.5], "y": [-2.4, 1.4]}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var C: Vector2 = cfg.C
		var BA := A - B
		var BC := C - B
		var side := signf(BA.cross(BC))
		var r: float = cfg.r
		var shapes := [_poly([A, B, C], "dim"), _ar(B, A, "cyan", "", {"w": 2.5}), _ar(B, C, "pink", "", {"w": 2.5})]
		shapes += _dots({"A": A, "B": B, "C": C}, "text", {"A": [8, -6], "B": [-14, 14], "C": [8, 4]})
		shapes.append(_hand(B, r, BA, side, float(cfg.deg), 4))
		var L: Array = cfg.L
		vars.append({"eq": "A%s、B%s、C%s\n求 \\vec{BA} · \\vec{BC} 和 ∠B" % [_pt(A), _pt(B), _pt(C)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_guess(B, r, BA, side, "∠B"),
				_f("內積", "\\vec{BA} · \\vec{BC}", "\\vec{BA} · \\vec{BC} = [0]", [cfg.d],
					"\\vec{BA} = %s、\\vec{BC} = %s，\\vec{BA} · \\vec{BC} = %s" % [_pt(BA), _pt(BC), B2._fv(float(cfg.d))], "先算 \\vec{BA}、\\vec{BC}（終點減起點）。", T_ANG),
				_f("長度", "兩支的長度", "|\\vec{BA}| = [0]，|\\vec{BC}| = [1]", L, "|\\vec{BA}| = %s、|\\vec{BC}| = %s" % L, "√(x^{2} + y^{2})。", T_LEN),
				_f("角度", "cos B", "cos B = [0]，∠B = [1]°", [cfg.c, str(cfg.deg)],
					"cos B = \\frac{%s}{%s × %s} = %s，∠B = %d°" % [B2._fv(float(cfg.d)), L[0], L[1], String(cfg.c).replace("-", "−").replace("√2/2", "\\frac{√2}{2}"), cfg.deg],
					"內積除以兩個長度。", T_ANG),
			]})
	return {"id": "cangle", "chapter": 2, "type": "forge", "title": "坐標量角度",
		"story": "先用量角器猜，再用內積算。",
		"insight": "cos θ = \\frac{\\vec{a} · \\vec{b}}{|\\vec{a}||\\vec{b}|} = \\frac{a_{1}b_{1} + a_{2}b_{2}}{√(a_{1}^{2} + a_{2}^{2}) √(b_{1}^{2} + b_{2}^{2})}\n角的頂點是兩支向量共同的起點。",
		"variants": vars}


## 10 假的那一支箭（A58）
static func _fake() -> Dictionary:
	var vars := []
	for cfg in [{"a": Vector2(3, 1), "b2": 2.0, "deg": 135, "q": ["3", "4"], "r": ["1", "-4"], "keep": 1, "x": [-5.5, 4.5], "y": [-0.8, 3.0]},
			{"a": Vector2(2, 1), "b2": 3.0, "deg": 45, "q": ["8", "9"], "r": ["1", "-9"], "keep": 0, "x": [-10.5, 3.5], "y": [-0.8, 3.8]}]:
		var a: Vector2 = cfg.a
		var r: Array = cfg.r
		var O := Vector2.ZERO
		var shapes := [_ar(O, a, "cyan", "\\vec{a}", {"ls": -1, "w": 3.0})]
		var cands := []
		var keep := []
		for i in 2:
			var bb := Vector2(float(r[i]), float(cfg.b2))
			var dg := rad_to_deg(absf(a.angle_to(bb)))
			var good := i == int(cfg.keep)
			shapes += [_ar(O, bb, "lime" if good else "pink", "", {"at": 2, "w": 2.5}),
				_arc(O, _deg(a), _deg(bb), "%d°" % int(roundf(dg)), {"at": 2, "r": 30 + 16 * i, "c": "lime" if good else "pink"}),
				_dot(bb, "x = %s" % B2._fv(float(r[i])), "lime" if good else "pink", {"at": 2, "off": [6, -8]})]
			cands.append("x = %s" % B2._fv(float(r[i])))
			keep.append(good)
		var q: Array = cfg.q
		var flt := SB.filter("篩選", "哪一個是真的？丟掉假的", cands, keep,
			"x = %s（另一個根的夾角是 %d°，平方時把正負弄丟了）" % [B2._fv(float(r[cfg.keep])), 180 - int(cfg.deg)],
			"量量看兩支箭的角度，哪一支是 %d°？" % cfg.deg, T_ANG)
		vars.append({"eq": "\\vec{a} = %s，\\vec{b} = (x, %s)\n\\vec{a}、\\vec{b} 的夾角是 %d°，求 x" % [_pt(a), B1._n(cfg.b2), cfg.deg],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("平方", "cos θ 的式子兩邊平方", "x^{2} + [0]x − [1] = 0", q,
					"cos %d° = \\frac{\\vec{a} · \\vec{b}}{|\\vec{a}||\\vec{b}|}，平方化簡：x^{2} + %sx − %s = 0" % [cfg.deg, q[0], q[1]],
					"(\\vec{a} · \\vec{b})^{2} = \\frac{1}{2}|\\vec{a}|^{2}|\\vec{b}|^{2}，展開再整理。", T_ANG),
				_f("兩個根", "解方程式", "x = [0] 或 x = [1]", r, "x = %s 或 %s" % [B2._fv(float(r[0])), B2._fv(float(r[1]))], "因式分解。", T_ANG),
				flt,
			]})
		vars[-1].steps[1]["groups"] = [[0, 1]]
	return {"id": "fake", "chapter": 2, "type": "forge", "title": "假的那一支箭",
		"story": "兩支候選的箭，只有一支的角度是對的。",
		"insight": "cos θ 的式子平方之後，cos θ 的正負會弄丟\n解出來的根要代回去：內積的正負要和 cos θ 一樣。",
		"variants": vars}


## 11 三面旗子（A59）
static func _flags() -> Dictionary:
	var vars := []
	for cfg in [{"ab": 4.0, "bc": 2.0, "d1": "16", "c": "√26/26", "x": [-3.5, 8.0], "y": [-4.8, 7.0]},
			{"ab": 3.0, "bc": 3.0, "d1": "9", "c": "√10/10", "x": [-4.0, 7.5], "y": [-3.8, 6.8]}]:
		var ab: float = cfg.ab
		var bc: float = cfg.bc
		var B := Vector2.ZERO
		var A := Vector2(ab, 0)
		var C := Vector2(0, bc)
		var D := Vector2(0, -ab)
		var E := Vector2(ab, -ab)
		var H := Vector2(-bc, bc)
		var I := Vector2(-bc, 0)
		var nrm := Vector2(bc, ab)
		var Fp := C + nrm
		var G := A + nrm
		var deg := rad_to_deg(absf(G.angle_to(E)))
		var shapes := [_poly([A, B, C], "text"), _poly([A, B, D, E], "cyan", {"fill": "cyan", "alpha": 0.1}), _poly([B, C, H, I], "pink", {"fill": "pink", "alpha": 0.1}),
			_poly([A, C, Fp, G], "gold", {"fill": "gold", "alpha": 0.12, "at": 1})]
		shapes += _dots({"A": A, "B": B, "C": C, "D": D, "E": E, "H": H, "I": I}, "text",
			{"A": [6, 14], "B": [-14, 14], "C": [-14, -6], "D": [-14, 4], "E": [8, 4], "H": [-14, -6], "I": [-14, 14]})
		shapes += [_dot(Fp, "F", "gold", {"at": 1, "off": [-4, -12]}), _dot(G, "G", "gold", {"at": 1, "off": [8, -4]}),
			_ar(A, D, "cyan", "", {"at": 2, "w": 2.5}), _ar(A, H, "pink", "", {"at": 2, "w": 2.5}),
			_seg(B, G, "gold", {"at": 3}), _seg(B, E, "gold", {"at": 3}), _hand(B, 2.0, G, -1.0, deg, 4)]
		var st_g := _guess(B, 2.0, G, -1.0, "∠GBE")
		vars.append({"eq": "△ABC 中 ∠B = 90°，\\ol{AB} = %s，\\ol{BC} = %s，向外作正方形\nACFG、ABDE、BCHI，求 \\vec{AD} · \\vec{AH} 和 cos∠GBE" % [B1._n(ab), B1._n(bc)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vpick", "name": "G", "q": "點出正方形 ACFG 的頂點 G", "target": _p(G), "snap": 1, "tag": T_ANG,
				 "traps": [[A.x - nrm.x, A.y - nrm.y, "這是往內作的：正方形蓋住 B 了，要往外。"]],
				 "nudge": "\\vec{AC} = %s 轉 90°，往離開 B 的那一邊。" % _pt(C - A), "line": "G%s、F%s" % [_pt(G), _pt(Fp)]},
				_f("內積", "\\vec{AD} · \\vec{AH}", "\\vec{AD} · \\vec{AH} = [0]", [cfg.d1],
					"\\vec{AD} = %s、\\vec{AH} = %s，內積 = %s" % [_pt(D - A), _pt(H - A), cfg.d1], "D%s、H%s。" % [_pt(D), _pt(H)], T_ANG),
				st_g,
				_f("cos", "cos∠GBE", "cos∠GBE = [0]", [cfg.c],
					"\\vec{BG} = %s、\\vec{BE} = %s：cos∠GBE = %s" % [_pt(G), _pt(E), "\\frac{" + String(cfg.c).split("/")[0] + "}{" + String(cfg.c).split("/")[1] + "}"],
					"內積除以兩個長度，再有理化。", T_ANG),
			]})
	return {"id": "flags", "chapter": 2, "type": "forge", "title": "三面旗子",
		"story": "三邊各插一面正方形的旗子，放上坐標就好算。",
		"insight": "圖形題放上坐標：直角的頂點放原點，兩股放在坐標軸上\n正方形往外作：邊轉 90°，看清楚是哪一邊。",
		"variants": vars}


## 12 只知道長度的夾角（A60、A62、A63）
static func _len_angle() -> Dictionary:
	var vars := []
	var O := Vector2.ZERO
	# 變化 A：|a| = 2、|b| = 1、|a − 2b| = 2√3
	var aA := Vector2(2, 0)
	var bA := Vector2.from_angle(deg_to_rad(120.0))
	var sA := [_line(O, aA, "faint"), _ar(O, aA, "cyan", "\\vec{a}", {"ls": -1}), _ar(O, bA, "pink", "\\vec{b}", {"at": 3}), _hand(O, 1.4, aA, 1.0, 120.0, 3)]
	vars.append({"eq": "|\\vec{a}| = 2，|\\vec{b}| = 1，|\\vec{a} − 2\\vec{b}| = 2√3\n求 \\vec{a}、\\vec{b} 的夾角",
		"plane": _plane([-3.2, 3.6], [-0.8, 2.2], sA),
		"steps": [
			_guess(O, 1.4, aA, 1.0, "θ"),
			_f("內積", "|\\vec{a} − 2\\vec{b}|^{2} 展開", "\\vec{a} · \\vec{b} = [0]", ["-1"], "12 = 4 − 4\\vec{a} · \\vec{b} + 4 ⇒ \\vec{a} · \\vec{b} = −1",
				"|\\vec{a} − 2\\vec{b}|^{2} = |\\vec{a}|^{2} − 4\\vec{a} · \\vec{b} + 4|\\vec{b}|^{2}。", T_LEN),
			_f("夾角", "cos θ", "cos θ = [0]，θ = [1]°", ["-1/2", "120"], "cos θ = \\frac{−1}{2 × 1} = −\\frac{1}{2}，θ = 120°", "內積除以 |\\vec{a}||\\vec{b}|。", T_ANG),
		]})
	# 變化 B：|a| = |b| = |a + b|
	var aB := Vector2(2, 0)
	var bB := Vector2.from_angle(deg_to_rad(120.0)) * 2.0
	var sB := [_line(O, aB, "faint"), _ar(O, aB, "cyan", "\\vec{a}", {"ls": -1}), _ar(O, bB, "pink", "\\vec{b}", {"at": 2}),
		_ar(O, aB + bB, "gold", "\\vec{a} + \\vec{b}", {"at": 2, "lt": 0.7}), _poly([O, aB, aB + bB], "gold", {"fill": "gold", "alpha": 0.12, "at": 2}),
		_hand(O, 1.4, aB, 1.0, 120.0, 3)]
	vars.append({"eq": "\\vec{a}、\\vec{b} 是非零向量，|\\vec{a}| = |\\vec{b}| = |\\vec{a} + \\vec{b}|\n求 \\vec{a}、\\vec{b} 的夾角",
		"plane": _plane([-3.0, 3.4], [-0.6, 2.4], sB),
		"steps": [
			_guess(O, 1.4, aB, 1.0, "θ"),
			_f("內積", "設長度都是 1", "\\vec{a} · \\vec{b} = [0]", ["-1/2"], "|\\vec{a} + \\vec{b}|^{2} = 1 + 2\\vec{a} · \\vec{b} + 1 = 1 ⇒ \\vec{a} · \\vec{b} = −\\frac{1}{2}（三支等長的箭圍成正三角形）",
				"長度設多少都可以，角度不會變。展開 |\\vec{a} + \\vec{b}|^{2}。", T_LEN),
			_f("夾角", "cos θ", "cos θ = [0]，θ = [1]°", ["-1/2", "120"], "cos θ = −\\frac{1}{2}，θ = 120°", "內積除以 |\\vec{a}||\\vec{b}| = 1。", T_ANG),
		]})
	# 變化 C：|u| = 3|v| = |u + 2v|
	var uC := Vector2(3, 0)
	var cth := rad_to_deg(acos(-1.0 / 3.0))
	var vC := Vector2.from_angle(deg_to_rad(cth))
	var sC := [_line(O, uC, "faint"), _ar(O, uC, "cyan", "\\vec{u}", {"ls": -1}), _ar(O, vC, "pink", "\\vec{v}", {"at": 3}), _hand(O, 1.4, uC, 1.0, cth, 3)]
	vars.append({"eq": "|\\vec{u}| = 3|\\vec{v}| = |\\vec{u} + 2\\vec{v}|\n求 \\vec{u}、\\vec{v} 夾角的 cos θ",
		"plane": _plane([-3.2, 4.4], [-0.8, 2.2], sC),
		"steps": [
			_guess(O, 1.4, uC, 1.0, "θ"),
			_f("內積", "設 |\\vec{v}| = 1", "\\vec{u} · \\vec{v} = [0]", ["-1"], "|\\vec{u}| = 3：9 = 9 + 4\\vec{u} · \\vec{v} + 4 ⇒ \\vec{u} · \\vec{v} = −1",
				"|\\vec{u} + 2\\vec{v}|^{2} = |\\vec{u}|^{2} + 4\\vec{u} · \\vec{v} + 4|\\vec{v}|^{2}。", T_LEN),
			_f("夾角", "cos θ", "cos θ = [0]", ["-1/3"], "cos θ = \\frac{−1}{3 × 1} = −\\frac{1}{3}（大約 109°）", "內積除以 |\\vec{u}||\\vec{v}|。", T_ANG),
		]})
	return {"id": "lenang", "chapter": 2, "type": "forge", "title": "只知道長度的夾角",
		"story": "沒有坐標、只知道長度，也能量出角度。",
		"insight": "只知道長度：把已知的長度平方展開，先求內積\n再用 cos θ = \\frac{\\vec{a} · \\vec{b}}{|\\vec{a}||\\vec{b}|}。長度只給比例時，設一個方便的數。",
		"variants": vars}


## 13 直角的兩支箭（A61）
static func _right_axes() -> Dictionary:
	var vars := []
	for cfg in [{"la": 3.0, "lb": 1.0, "p": [1, 3], "q": [2, -3], "pq": ["3", "3", "6", "-3"], "c": "√10/10", "x": [-1.5, 7.5], "y": [-3.6, 3.6],
				"opts": ["\\vec{a} = (3, 0)，\\vec{b} = (0, 1)", "\\vec{a} = (3, 0)，\\vec{b} = (1, 0)", "\\vec{a} = (3, 1)，\\vec{b} = (0, 1)"]},
			{"la": 2.0, "lb": 2.0, "p": [1, 1], "q": [1, -3], "pq": ["2", "2", "2", "-6"], "c": "-√5/5", "x": [-2.5, 6.5], "y": [-6.6, 2.8],
				"opts": ["\\vec{a} = (2, 0)，\\vec{b} = (0, 2)", "\\vec{a} = (2, 0)，\\vec{b} = (2, 0)", "\\vec{a} = (2, 2)，\\vec{b} = (0, 2)"]}]:
		var a := Vector2(cfg.la, 0)
		var b := Vector2(0, cfg.lb)
		var pv: Vector2 = a * float(cfg.p[0]) + b * float(cfg.p[1])
		var qv: Vector2 = a * float(cfg.q[0]) + b * float(cfg.q[1])
		var O := Vector2.ZERO
		var pn := B1._lin(str(cfg.p[0]), "a", str(cfg.p[1]), "b")
		var qn := B1._lin(str(cfg.q[0]), "a", str(cfg.q[1]), "b")
		var shapes := [_ar(O, a, "cyan", "\\vec{a}", {"ls": -1, "at": 1}), _ar(O, b, "pink", "\\vec{b}", {"at": 1}), _right(O, a, b, {"at": 1}),
			_ar(O, pv, "lime", pn, {"at": 2, "lt": 0.75}), _ar(O, qv, "gold", qn, {"at": 2, "lt": 0.75}), _arc(O, _deg(qv), _deg(pv), "θ", {"at": 3})]
		var pq: Array = cfg.pq
		vars.append({"eq": "|\\vec{a}| = %s，|\\vec{b}| = %s，\\vec{a} ⊥ \\vec{b}\n%s 和 %s 的夾角是 θ，求 cos θ" % [B1._n(cfg.la), B1._n(cfg.lb), pn, qn],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_c("放上坐標", "\\vec{a} ⊥ \\vec{b}，可以放成？", cfg.opts, 0,
					"兩支互相垂直：一支放在 x 軸、一支放在 y 軸，長度照題目。", "要垂直，長度也要對。", "放上坐標：%s" % cfg.opts[0], T_ANG),
				_f("坐標", "兩個組合的坐標", "%s = ([0], [1])，%s = ([2], [3])" % [pn, qn], pq,
					"%s = %s，%s = %s" % [pn, _pt(pv), qn, _pt(qv)], "分量各自算。", T_ANG),
				_f("cos θ", "內積除以長度", "cos θ = [0]", [cfg.c], "cos θ = \\frac{%s}{%s} = %s" % [B2._fv(pv.dot(qv)), "√%d × √%d" % [int(pv.length_squared()), int(qv.length_squared())],
					("−" if String(cfg.c).begins_with("-") else "") + "\\frac{" + String(cfg.c).trim_prefix("-").split("/")[0] + "}{" + String(cfg.c).split("/")[1] + "}"],
					"內積 = %s，長度各是 √%d、√%d，記得有理化。" % [B2._fv(pv.dot(qv)), int(pv.length_squared()), int(qv.length_squared())], T_ANG),
			]})
	return {"id": "raxes", "chapter": 2, "type": "forge", "title": "直角的兩支箭",
		"story": "兩支箭互相垂直？那就放在坐標軸上！",
		"insight": "\\vec{a} ⊥ \\vec{b}：可以放成 \\vec{a} = (|\\vec{a}|, 0)、\\vec{b} = (0, |\\vec{b}|)\n組合的坐標直接算，內積、長度都變簡單。",
		"variants": vars}
