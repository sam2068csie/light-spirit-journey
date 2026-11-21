extends RefCounted
## 平面向量 第六大關「風箏航道」題庫（下冊 3-3 重點一：直線的參數式、法向量、距離、極值、投影、反射、夾角）
## 設計稿：docs/vec2_v6_design.md。數字都用程式驗算過（tools/vec2/verify_v6.py）。B18 移到終焉之塔（docs/vec2_tower_backlog.md）。
##
## 引擎見 vec_level.gd（箭頭畫布、在圖上作答），圖層見 vec_board.gd。這一關多用了：
##   圖層 kite（風箏，跟著滑桿的 t 飛）、sweep（航跡：照參數式的 t 範圍飛，走錯的那一段變紅）、beads（格子點的珠子）、
##   vplace 沙盒的 mirror（鏡岩）、滑桿的 goals（多個答案）、直線與圓的 trail（光點）。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/vec2/vec1_bank.gd")
const B2 := preload("res://data/levels/vec2/vec2_bank.gd")
const B3 := preload("res://data/levels/vec2/vec3_bank.gd")

const T_PAR := "vec_param"        # 直線的參數式
const T_NRM := "vec_normal"       # 法向量、方向向量
const T_DST := "vec_ldist"        # 點到直線的距離、沿直線走
const T_LPJ := "vec_lproj"        # 向量在直線上的正射影、投影點
const T_ANG := "vec_langle"       # 兩直線的夾角
const T_RFL := "vec_reflect"      # 對稱點、反射
const T_TRN := "vec_turn"         # 轉 90° 的頂點


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


static func _tag(p: Vector2, s: String, c := "text", extra := {}) -> Dictionary:
	return B1._tag(p, s, c, extra)


static func _seg(a: Vector2, b: Vector2, c := "dim", extra := {}) -> Dictionary:
	return B1._seg(a, b, c, extra)


static func _poly(pts: Array, c := "dim", extra := {}) -> Dictionary:
	return B1._poly(pts, c, extra)


static func _plane(x: Array, y: Array, shapes: Array, named := {}, extra := {}) -> Dictionary:
	return B1._plane(x, y, shapes, named, extra)


static func _axes(x: Array, y: Array, shapes: Array, named := {}) -> Dictionary:
	return _plane(x, y, shapes, named, {"grid": "axes"})


static func _right(p: Vector2, u: Vector2, v: Vector2, extra := {}) -> Dictionary:
	return B3._right(p, u, v, extra)


static func _e(v: float) -> String:
	return B3._e(v)


static func _fv(v: float) -> String:
	return B2._fv(v)


static func _pt(v: Vector2) -> String:
	return B2._pt(v)


static func _ans(v: float) -> String:
	return B2._ans(v)


## 直線 ax + by + c = 0 的圖層
static func _L(a: float, b: float, c: float, col := "cyan", s := "", extra := {}) -> Dictionary:
	var d := {"k": "line", "abc": [a, b, c], "c": col}
	if s != "":
		d["s"] = s
	d.merge(extra, true)
	return d


## 過 p、方向 d 的直線
static func _Lpd(p: Vector2, d: Vector2, col := "cyan", s := "", extra := {}) -> Dictionary:
	return _L(d.y, -d.x, d.x * p.y - d.y * p.x, col, s, extra)


## 角的小弧（從 d0 轉到 d1，度）
static func _arc(o: Vector2, d0: float, d1: float, s := "", extra := {}) -> Dictionary:
	var d := {"k": "angle", "o": _p(o), "a0": minf(d0, d1), "a1": maxf(d0, d1), "r": 24, "c": "gold", "s": s}
	d.merge(extra, true)
	return d


static func _deg(v: Vector2) -> float:
	return rad_to_deg(v.angle())


static func _walk(pts: Array, at: int, extra := {}) -> Dictionary:
	var arr := []
	for q in pts:
		arr.append(_p(q))
	var d := {"k": "walk", "pts": arr, "c": "gold", "arrows": true, "at": at}
	d.merge(extra, true)
	return d


## 從 p 沿 d 走 n 步的折線
static func _steps(p: Vector2, d: Vector2, n: int) -> Array:
	var out := []
	for i in absi(n) + 1:
		out.append(p + d * float(i) * signf(n))
	return out


static func _sweep(p0: Vector2, d: Vector2, t0, t1, at: int, extra := {}) -> Dictionary:
	var dd := {"k": "sweep", "p0": _p(p0), "d": _p(d), "t0": t0, "t1": t1, "at": at, "dur": 1.6}
	dd.merge(extra, true)
	return dd


static func _foot(a: float, b: float, c: float, p: Vector2) -> Vector2:
	var n := Vector2(a, b)
	return p - n * ((n.dot(p) + c) / n.length_squared())


# ---------------- 式子的寫法 ----------------

static func _num(v: float) -> String:
	return _fv(v)


## 一項：c·v，first 是第一項（不寫 +）；係數 1 不寫
static func _term(c: float, v: String, first: bool) -> String:
	if is_zero_approx(c):
		return ""
	var a := absf(c)
	var cs := "" if (is_equal_approx(a, 1.0) and v != "") else _num(a)
	if first:
		return ("−" if c < 0 else "") + cs + v
	return (" − " if c < 0 else " + ") + cs + v


static func _lin2(a: float, b: float, c: float) -> String:
	var out := ""
	for pr in [[a, "x"], [b, "y"], [c, ""]]:
		if is_zero_approx(float(pr[0])):
			continue
		out += _term(float(pr[0]), String(pr[1]), out == "")
	return out


## ax + by + c = 0
static func _lstr(a: float, b: float, c: float) -> String:
	return _lin2(a, b, c) + " = 0"


## ax + by = k
static func _lk(a: float, b: float, k: float) -> String:
	return _lin2(a, b, 0.0) + " = " + _num(k)


static func _pc(p0: float, d: float, v: String) -> String:
	if is_zero_approx(p0):
		return _term(d, v, true) if not is_zero_approx(d) else "0"
	return _num(p0) + _term(d, v, false)


## x = 2 + 4t，y = −1 + 3t
static func _par(P: Vector2, d: Vector2, v := "t") -> String:
	return "x = %s，y = %s" % [_pc(P.x, d.x, v), _pc(P.y, d.y, v)]


## (2 + 4t, −1 + 3t)
static func _parp(P: Vector2, d: Vector2, v := "t") -> String:
	return "(%s, %s)" % [_pc(P.x, d.x, v), _pc(P.y, d.y, v)]


## 滑桿的算式：p + v·d（Expression 用的 ASCII）
static func _ex(p: float, d: float, v := "t") -> String:
	return "%s + %s * %s" % [_e(p), _e(d), v]


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
		_fly(), _seg_cards(), _seg_judge(), _beads(), _flag(), _dirnorm(), _meet(), _dist(), _walk_k(), _turn(),
		{"id": "speed1", "chapter": 1, "type": "speed", "title": "航道速算", "time": 120.0,
		 "story": "看直線和箭頭：平行、垂直，還是都不是？",
		 "insight": "ax + by + c = 0：法向量 (a, b)、方向向量 (b, −a)\n箭頭和 (a, b) 平行 ⇒ 垂直直線；和 (a, b) 垂直 ⇒ 平行直線。",
		 "variants": [{"gen": "para", "count": 8}]},
		_extreme(), _rope(), _mirror(), _lproj(), _lfoot(), _cross(), _pcross(), _slope(), _rotate(),
		{"id": "speed2", "chapter": 2, "type": "speed", "title": "交角速算", "time": 120.0,
		 "story": "兩條航道交叉，看法向量就知道夾多大！",
		 "insight": "兩直線的夾角看法向量：平行 ⇒ 平行，內積 0 ⇒ 垂直\ncos^{2} θ = \\frac{1}{2} ⇒ 夾 45°（另一個夾角 135°）。",
		 "variants": [{"gen": "angle", "count": 8}]},
	]


# ======================= 第一章．參數式與法向量 =======================

## 1 風箏起飛（新）
static func _fly() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(-3, 1), "v": Vector2(2, 1), "ax": 0, "goal": 5, "x": [-5.0, 8.0], "y": [-1.0, 6.0]},
			{"A": Vector2(4, -2), "v": Vector2(-3, 2), "ax": 1, "goal": 6, "x": [-10.0, 6.5], "y": [-3.0, 7.0]}]:
		var A: Vector2 = cfg.A
		var v: Vector2 = cfg.v
		var P2 := A + v * 2.0
		var tg := 4.0
		var Pg := A + v * tg
		var shapes := [_dot(A, "A", "text", {"off": [-14, 16]}), _ar(A, A + v, "cyan", "\\vec{v}", {"ls": -1})]
		shapes += [_walk([A, A + v, P2], 1), _dot(Pg, "", "gold", {"at": 3}), _tag(Pg, "t = 4", "gold", {"at": 3, "off": [10, -8]})]
		var axn := "x" if int(cfg.ax) == 0 else "y"
		var lines := [{"k": "dot", "p": [_ex(A.x, v.x), _ex(A.y, v.y)], "c": "gold", "s": "", "trail": true},
			{"k": "kite", "p": [_ex(A.x, v.x), _ex(A.y, v.y)], "c": "gold"}]
		vars.append({"eq": "風箏從 A%s 出發，每秒照 \\vec{v} = %s 飛一段\nt 秒時在哪裡？" % [_pt(A), _pt(v)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vpick", "name": "t = 2", "q": "點出 t = 2 的位置", "target": _p(P2), "snap": 1, "tag": T_PAR,
				 "traps": [[A.x + v.x, A.y + v.y, "這是 t = 1：只飛了一段。"], [v.x * 2.0, v.y * 2.0, "要從 A 出發，不是從原點。"]],
				 "nudge": "從 A 出發，照 \\vec{v} 飛兩段。", "line": "t = 2：從 A 飛兩段 2\\vec{v}，到 %s" % _pt(P2)},
				_f("參數式", "t 秒時的位置", "P = (%s + [0]t, %s + [1]t)" % [_num(A.x), _num(A.y)], [_ans(v.x), _ans(v.y)],
					"P = A + t\\vec{v} = %s" % _parp(A, v), "每秒走一次 \\vec{v}：x 多 %s、y 多 %s。" % [_num(v.x), _num(v.y)], T_PAR),
				_f("反推 t", "什麼時候 %s = %d" % [axn, int(cfg.goal)], "t = [0]", ["4"],
					"%s = %d ⇒ t = 4，風箏在 %s" % [_pc(A[int(cfg.ax)], v[int(cfg.ax)], "t"), int(cfg.goal), _pt(Pg)],
					"%s 坐標 %s = %d。" % [axn, _pc(A[int(cfg.ax)], v[int(cfg.ax)], "t"), int(cfg.goal)], T_PAR),
				{"kind": "slide", "name": "拖 t", "q": "拖 t，看風箏飛", "tag": T_PAR, "free": true,
				 "params": [{"n": "t", "min": -1, "max": 5, "step": 0.5, "v": 0}], "lines": lines,
				 "eq": "t = {t}：P = ({%s}, {%s})" % [_ex(A.x, v.x), _ex(A.y, v.y)],
				 "line": "風箏飛過的地方排成一條直線：過 A、方向 \\vec{v}", "nudge": "拉動滑桿，看風箏飛。"},
			]})
	return {"id": "kfly", "chapter": 1, "type": "forge", "title": "風箏起飛",
		"story": "t 是時間：風箏每秒照 \\vec{v} 飛一段。",
		"insight": "過 A、方向 \\vec{v} 的直線：P = A + t\\vec{v}\nt 是時間，(x, y) = (x_{A} + tv_{1}, y_{A} + tv_{2})。",
		"variants": vars}


## 2 哪一條是 AB 航道（B1、B2）
static func _seg_cards() -> Dictionary:
	var vars := []
	# 第 1 組：線段 AB
	var A := Vector2(5, 1)
	var B := Vector2(1, 3)
	var s1 := [_seg(A, B, "faint", {"w": 6.0})]
	s1 += B1._dots({"A": A, "B": B}, "text", {"A": [8, 14], "B": [-14, -8]})
	var cards := [[A, Vector2(-4, 2), 0, 1, true, "x = 5 − 4t，y = 1 + 2t，0 ≤ t ≤ 1", "t = 0 在 A，t = 1 在 B。"],
		[A, Vector2(4, -2), -1, 0, true, "x = 5 + 4t，y = 1 − 2t，−1 ≤ t ≤ 0", "t = −1 在 B，t = 0 在 A。"],
		[B, Vector2(-2, 1), -1, 0, false, "x = 1 − 2t，y = 3 + t，−1 ≤ t ≤ 0", "t = −1 在 (3, 2)：只走到中點。"],
		[B, Vector2(6, -2), 0, 2.0 / 3.0, false, "x = 1 + 6t，y = 3 − 2t，0 ≤ t ≤ \\frac{2}{3}", "t = \\frac{2}{3} 在 (5, \\frac{5}{3})，不是 A：方向就錯了。"]]
	var st1 := []
	for k in cards.size():
		var cd: Array = cards[k]
		s1.append(_sweep(cd[0], cd[1], cd[2], cd[3], k + 1, {"until": k + 2, "ref": [_p(A), _p(B)]}))
		st1.append(_j("審判%s" % ["一", "二", "三", "四"][k], cd[5], cd[4], cd[6], "%s：%s" % [cd[5], "○" if cd[4] else "✕"], T_PAR))
	s1.append(_seg(A, B, "gold", {"at": 5, "w": 3.0}))
	vars.append({"eq": "A(5, 1)、B(1, 3)\n哪些參數式是線段 AB？", "plane": _axes([-2.0, 8.0], [-1.0, 4.2], s1), "steps": st1})
	# 第 2 組：射線
	var S := Vector2(1, -1)
	var dv := Vector2(-2, 1)
	var s2 := [{"k": "beam", "a": _p(S), "b": _p(S + dv), "c": "cyan", "len": 1.0}, _dot(S, "", "text")]
	var cards2 := [[S, dv, 0, null, true, "x = 1 − 2s，y = −1 + s，s ≥ 0", "s = 0 在 (1, −1)，往 (−2, 1) 走。"],
		[S, Vector2(4, -2), null, 0, true, "x = 1 + 4s，y = −1 − 2s，s ≤ 0", "s 往負的走：(−4, 2) 的方向，就是 (−2, 1)。"],
		[Vector2(-3, 1), Vector2(2, -1), 2, null, false, "x = −3 + 2s，y = 1 − s，s ≥ 2", "s = 2 在 (1, −1)，可是往 (2, −1) 走：方向反了。"],
		[Vector2(5, -3), dv, 2, null, true, "x = 5 − 2s，y = −3 + s，s ≥ 2", "s = 2 在 (1, −1)，往 (−2, 1) 走。"]]
	var st2 := []
	for k in cards2.size():
		var cd: Array = cards2[k]
		s2.append(_sweep(cd[0], cd[1], cd[2], cd[3], k + 1, {"until": k + 2, "ray": [_p(S), _p(dv)]}))
		st2.append(_j("審判%s" % ["一", "二", "三", "四"][k], cd[5], cd[4], cd[6], "%s：%s" % [cd[5], "○" if cd[4] else "✕"], T_PAR))
	vars.append({"eq": "射線 x = 3 − 2s，y = −2 + s，s ≥ 1\n哪些和它是同一個圖形？", "plane": _axes([-8.0, 5.0], [-3.2, 3.4], s2), "steps": st2})
	return {"id": "kseg", "chapter": 1, "type": "forge", "title": "哪一條是 AB 航道",
		"story": "t 的範圍決定航道是線段、射線還是直線。",
		"insight": "P = A + t\\vec{AB}：0 ≤ t ≤ 1 是線段 AB，t ≥ 0 是射線\n同一條航道可以有很多種寫法：起點、方向、範圍要一起看。",
		"variants": vars}


## 3 線段航道的審判（B7）
static func _seg_judge() -> Dictionary:
	var vars := []
	# 第 1 組：x = 2 + 4t，y = −1 + 3t，−1 ≤ t ≤ 1
	var P0 := Vector2(2, -1)
	var d := Vector2(4, 3)
	var A := P0 - d
	var B := P0 + d
	var X := P0 - d * 2.0
	var s1 := [_seg(A, B, "cyan", {"w": 3.0})]
	s1 += B1._dots({"A": A, "B": B}, "text", {"A": [8, 14], "B": [8, -6]})
	s1 += [_seg(A, A + Vector2(4, 0), "gold", {"at": 1, "until": 2, "dash": true}), _seg(A + Vector2(4, 0), A + d, "gold", {"at": 1, "until": 2, "dash": true}),
		_tag(A + Vector2(2, 0), "4", "gold", {"at": 1, "until": 2, "off": [-4, 16]}), _tag(A + Vector2(4, 1.5), "3", "gold", {"at": 1, "until": 2, "off": [8, 4]}),
		_ar(P0, P0 + d, "cyan", "(4, 3)", {"at": 2, "until": 3, "w": 3.5}), _ar(P0, P0 + Vector2(3, -4), "pink", "(3, −4)", {"at": 2, "until": 3, "ls": -1}),
		_right(P0, d, Vector2(3, -4), {"at": 2, "until": 3}),
		_sweep(P0, d, -1, -2, 3, {"until": 4, "ref": [_p(A), _p(B)]}), _dot(X, "", "pink", {"at": 3, "until": 4}), _tag(X, "t = −2", "pink", {"at": 3, "until": 4, "off": [10, 4]}),
		_walk([A, P0, B], 4)]
	var st1 := [
		_j("審判一", "直線 AB 的斜率是 \\frac{3}{4}", true, "方向向量 (4, 3)：往右 4、往上 3。", "方向向量 (4, 3) ⇒ 斜率 \\frac{3}{4} ○", T_PAR),
		_j("審判二", "(4, 3) 是直線 AB 的法向量", false, "(4, 3) 是方向向量。法向量要和它垂直，例如 (3, −4)。", "(4, 3) 是方向向量，不是法向量 ✕", T_NRM),
		_j("審判三", "(−6, −7) 在線段 AB 上", false, "t = −2 才到 (−6, −7)，不在 −1 ≤ t ≤ 1 裡：在直線上、不在線段上。", "(−6, −7) 是 t = −2：不在線段上 ✕", T_PAR),
		_j("審判四", "\\ol{AB} = 10", true, "t 從 −1 走到 1，走了 2 段 (4, 3)：2 × 5 = 10。", "\\ol{AB} = 2 × |(4, 3)| = 10 ○", T_PAR)]
	vars.append({"eq": "線段 AB：%s，−1 ≤ t ≤ 1\n下面哪些正確？" % _par(P0, d), "plane": _axes([-10.0, 9.0], [-8.2, 3.2], s1), "steps": st1})
	# 第 2 組：x = 1 − 3t，y = −2 + 4t，0 ≤ t ≤ 1
	var Q0 := Vector2(1, -2)
	var e := Vector2(-3, 4)
	var A2 := Q0
	var B2 := Q0 + e
	var X2 := Q0 - e
	var M2 := Q0 + e * 0.5
	var s2 := [_seg(A2, B2, "cyan", {"w": 3.0})]
	s2 += B1._dots({"A": A2, "B": B2}, "text", {"A": [8, 14], "B": [-14, -8]})
	s2 += [_seg(A2, A2 + Vector2(-3, 0), "gold", {"at": 1, "until": 2, "dash": true}), _seg(A2 + Vector2(-3, 0), B2, "gold", {"at": 1, "until": 2, "dash": true}),
		_ar(A2, B2, "cyan", "(−3, 4)", {"at": 2, "until": 3, "w": 3.5, "ls": -1}), _ar(A2, A2 + Vector2(4, 3), "pink", "(4, 3)", {"at": 2, "until": 3}),
		_right(A2, e, Vector2(4, 3), {"at": 2, "until": 3}),
		_sweep(Q0, e, 0, -1, 3, {"until": 4, "ref": [_p(A2), _p(B2)]}), _dot(X2, "", "pink", {"at": 3, "until": 4}), _tag(X2, "t = −1", "pink", {"at": 3, "until": 4, "off": [10, 4]}),
		_walk([A2, M2], 4), _dot(M2, "", "gold", {"at": 4}), _tag(M2, "t = \\frac{1}{2}", "gold", {"at": 4, "off": [-40, -6]})]
	var st2 := [
		_j("審判一", "直線 AB 的斜率是 −\\frac{4}{3}", true, "方向向量 (−3, 4)：往左 3、往上 4。", "斜率 −\\frac{4}{3} ○", T_PAR),
		_j("審判二", "(4, 3) 是直線 AB 的法向量", true, "(4, 3) · (−3, 4) = 0：和方向向量垂直。", "(4, 3) ⊥ (−3, 4)：法向量 ○", T_NRM),
		_j("審判三", "(4, −6) 在線段 AB 上", false, "t = −1 才到 (4, −6)，不在 0 ≤ t ≤ 1 裡。", "(4, −6) 是 t = −1：不在線段上 ✕", T_PAR),
		_j("審判四", "t = \\frac{1}{2} 的點是 \\ol{AB} 的中點", true, "t 從 0 走到 1，走一半就是中點 (−\\frac{1}{2}, 0)。", "t = \\frac{1}{2}：中點 ○", T_PAR)]
	vars.append({"eq": "線段 AB：%s，0 ≤ t ≤ 1\n下面哪些正確？" % _par(Q0, e), "plane": _axes([-8.0, 9.0], [-7.0, 3.0], s2), "steps": st2})
	return {"id": "kjudge", "chapter": 1, "type": "forge", "title": "線段航道的審判",
		"story": "看參數式，就知道航道的斜率、長度和範圍。",
		"insight": "x = x_{0} + at，y = y_{0} + bt：方向向量 (a, b)、斜率 \\frac{b}{a}\nt 走了多少，長度就是 t 的差 × |(a, b)|。",
		"variants": vars}


## 4 航道上的珠子（B3）
static func _beads() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(2, -30), "B": Vector2(47, 30), "g": 15, "x": [-30.0, 80.0], "y": [-34.0, 34.0]},
			{"A": Vector2(-20, 7), "B": Vector2(36, -35), "g": 14, "x": [-60.0, 76.0], "y": [-39.0, 11.0]}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var v := B - A
		var g := int(cfg.g)
		var st := v / float(g)
		var shapes := [_seg(A, B, "cyan", {"w": 2.5}), _dot(A, "A" + _pt(A), "text", {"off": [10, 4]}), _dot(B, "B" + _pt(B), "text", {"off": [10, 4]}),
			_walk(_steps(A, st, 3), 2), {"k": "beads", "a": _p(A), "b": _p(B), "n": g + 1, "at": 3}]
		vars.append({"eq": "A%s、B%s\n線段 AB 上有幾個格子點（含兩端）？" % [_pt(A), _pt(B)],
			"plane": _plane(cfg.x, cfg.y, shapes, {}, {"grid": "none"}),
			"steps": [
				_f("\\vec{AB}", "終點減起點", "\\vec{AB} = ([0], [1])", [_ans(v.x), _ans(v.y)], "\\vec{AB} = %s" % _pt(v), "B − A。", T_PAR),
				_f("最小的一步", "除以最大公因數", "每一步 ([0], [1])", [_ans(st.x), _ans(st.y)],
					"%s 和 %s 的最大公因數是 %d：每一小步 %s" % [_num(absf(v.x)), _num(absf(v.y)), g, _pt(st)], "%s 和 %s 的最大公因數是 %d。" % [_num(absf(v.x)), _num(absf(v.y)), g], T_PAR),
				_f("數珠子", "含兩端", "格子點 [0] 個", [str(g + 1)], "%d 小步，加上起點：%d 個格子點" % [g, g + 1], "%d 小步，兩端都要算：%d + 1。" % [g, g], T_PAR),
			]})
	return {"id": "kbeads", "chapter": 1, "type": "forge", "title": "航道上的珠子",
		"story": "航道上每隔一小步，就有一顆格子點的珠子。",
		"insight": "\\vec{AB} 除以 x、y 的最大公因數 g，就是最小的一步\n線段上的格子點有 g + 1 個（含兩端）。",
		"variants": vars}


## 5 插旗的航道（B4）
static func _flag() -> Dictionary:
	var vars := []
	for cfg in [{"P": Vector2(2, 1), "n": Vector2(3, -4), "trace": [Vector2(6, 4), Vector2(-2, -2), Vector2(-6, -5)], "start": Vector2(5, -2), "x": [-9.0, 11.0], "y": [-6.0, 5.5]},
			{"P": Vector2(-1, 3), "n": Vector2(2, 5), "trace": [Vector2(4, 1), Vector2(-6, 5), Vector2(9, -1)], "start": Vector2(2, -2), "x": [-9.0, 11.0], "y": [-3.0, 7.0]}]:
		var P: Vector2 = cfg.P
		var n: Vector2 = cfg.n
		var k := n.dot(P)
		var dx := "%s * (x - %s) + %s * (y - %s)" % [_e(n.x), _e(P.x), _e(n.y), _e(P.y)]
		var tr := []
		for q in cfg.trace:
			tr.append(_p(q))
		var dirv := Vector2(-n.y, n.x)
		var shapes := [_dot(P, "P", "text", {"off": [-16, -6]}), _ar(P, P + n, "pink", "\\vec{n}", {"ls": -1}),
			_L(n.x, n.y, -k, "faint", "", {"at": 1, "until": 2, "dash": true}), _right(P, n, dirv, {"at": 1}),
			_L(n.x, n.y, -k, "cyan", _lk(n.x, n.y, k), {"at": 2})]
		vars.append({"eq": "過 P%s、和 \\vec{n} = %s 垂直的直線\n方程式是什麼？" % [_pt(P), _pt(n)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				{"kind": "vplace", "name": "插旗", "q": "拖 Q，找 3 個燈亮的點", "tag": T_NRM, "goal": "trace", "need": 3,
				 "sandbox": {"label": "Q", "arrow": {"o": _p(P), "c": "lime", "s": "\\vec{PQ}"}, "trace": true, "start": _p(cfg.start),
					"lit": "abs(%s) < 0.01 and (abs(x - %s) + abs(y - %s)) > 0.01" % [dx, _e(P.x), _e(P.y)],
					"read": "\\vec{PQ} · \\vec{n} = {%s}" % dx},
				 "ans": tr[0], "trace_ans": tr, "nudge": "\\vec{PQ} 要和 \\vec{n} 垂直：內積是 0。",
				 "line": "燈亮的 Q 排成一條直線：過 P、和 \\vec{n} 垂直", "big": true},
				_f("方程式", "代 P 進去", "%s = [0]" % _lin2(n.x, n.y, 0.0), [_ans(k)],
					"%s(x %s) %s %s(y %s) = 0 ⇒ %s" % [_num(n.x), _term(-P.x, "", false), "+" if n.y > 0 else "−", _num(absf(n.y)), _term(-P.y, "", false), _lk(n.x, n.y, k)],
					"(x − x_{P}, y − y_{P}) · \\vec{n} = 0，展開。", T_NRM),
			]})
	return {"id": "kflag", "chapter": 1, "type": "forge", "title": "插旗的航道",
		"story": "航道上插一面旗子，旗子和航道垂直。",
		"insight": "和 \\vec{n} = (a, b) 垂直的直線：ax + by = c\n(a, b) 是法向量；c 用直線上的一點代進去。",
		"variants": vars}


## 6 方向向量和法向量（B5、B6、B8）
static func _dirnorm() -> Dictionary:
	var vars := []
	# 變化 A（B5）
	var Q := Vector2(1, 2)
	var sa := [_L(3, 2, -7, "cyan", "L"), _dot(Q, "", "text"),
		_ar(Q, Q + Vector2(3, 2), "pink", "(3, 2)", {"at": 1}), _ar(Q, Q + Vector2(4, -6), "lime", "(4, −6)", {"at": 1, "ls": -1}),
		_right(Q, Vector2(3, 2), Vector2(4, -6), {"at": 1}), _dot(Vector2(-1, 5), "P", "gold", {"at": 2, "off": [10, -6]})]
	vars.append({"eq": "(4, b) 是 L：3x + 2y − 7 = 0 的方向向量\nP(t, 4 − t) 在 L 上，求 b、t",
		"plane": _axes([-8.0, 12.0], [-5.0, 6.5], sa),
		"steps": [
			_f("b", "方向向量 ⊥ 法向量", "b = [0]", ["-6"], "(4, b) · (3, 2) = 12 + 2b = 0 ⇒ b = −6", "L 的法向量是 (3, 2)，內積是 0。", T_NRM),
			_f("t", "P 代進 L", "t = [0]", ["-1"], "3t + 2(4 − t) = 7 ⇒ t = −1，P(−1, 5)", "x = t、y = 4 − t 代進 3x + 2y = 7。", T_NRM),
		]})
	# 變化 B（B6）
	var R := Vector2(0.8, 0.8)
	var sb := [_L(10, -15, 4, "cyan", "L")]
	var vecs := [[Vector2(3, 2), true, "\\vec{a} = (3, 2)"], [Vector2(-6, -4), true, "\\vec{b} = (−6, −4)"],
		[Vector2(2, -3), false, "\\vec{c} = (2, −3)"], [Vector2(-3, 2), false, "\\vec{d} = (−3, 2)"]]
	var stb := [_f("法向量", "最簡的法向量", "\\vec{n} = ([0], [1])", ["2", "-3"], "法向量 (10, −15) = 5(2, −3)", "ax + by + c = 0 的法向量是 (a, b)，再約掉公因數。", T_NRM, "prop")]
	for k in vecs.size():
		var vv: Array = vecs[k]
		var ok: bool = vv[1]
		sb.append(_ar(R, R + Vector2(vv[0]), "lime" if ok else "pink", String(vv[2]).split(" = ")[0], {"at": k + 2, "w": 3.0}))
		stb.append(_j("審判%s" % ["一", "二", "三", "四"][k], "%s 和 L 平行" % vv[2], ok,
			("和 (2, −3) 的內積是 0：和法向量垂直，所以和 L 平行。" if ok else ("這就是法向量：和 L 垂直。" if k == 2 else "和 (2, −3) 的內積不是 0，也不是倍數：斜斜的。")),
			"%s：%s" % [vv[2], "和 L 平行 ○" if ok else "不平行 ✕"], T_NRM))
	vars.append({"eq": "L：10x − 15y + 4 = 0\n哪些向量和 L 平行？", "plane": _axes([-8.0, 10.0], [-4.6, 4.6], sb), "steps": stb})
	# 變化 C（B8）
	var S := Vector2(2, 1)
	var sc := [_L(2, 5, -9, "cyan", "L"), _dot(S, "", "gold", {"at": 2}), _tag(S, "t = 0", "gold", {"at": 2, "off": [-30, -10]}),
		_walk([S, S + Vector2(5, -2)], 2), _ar(Vector2(-2, 2.6), Vector2(0, 7.6), "pink", "(2, 5)", {"at": 1}), _right(Vector2(-2, 2.6), Vector2(2, 5), Vector2(5, -2), {"at": 1})]
	vars.append({"eq": "L：2x + 5y − 9 = 0 的參數式\n寫成 x = 2 + at，y = b − 2t，求 a、b",
		"plane": _axes([-5.0, 10.0], [-2.0, 4.0], sc),
		"steps": [
			_f("a", "方向向量 ⊥ 法向量", "a = [0]", ["5"], "(a, −2) · (2, 5) = 2a − 10 = 0 ⇒ a = 5", "方向向量 (a, −2) 和法向量 (2, 5) 垂直。", T_NRM),
			_f("b", "t = 0 的點在 L 上", "b = [0]", ["1"], "t = 0：(2, b) 代進 L：4 + 5b = 9 ⇒ b = 1", "t = 0 時 x = 2、y = b。", T_PAR),
		]})
	return {"id": "kdir", "chapter": 1, "type": "forge", "title": "方向向量和法向量",
		"story": "一條航道有兩支箭頭：一支往前走，一支插旗。",
		"insight": "ax + by + c = 0：法向量 (a, b)、方向向量 (b, −a)\n參數式：方向向量 ⊥ 法向量，t = 0 的點在直線上。",
		"variants": vars}


## 7 兩條航道交會（B9、B10）
static func _meet() -> Dictionary:
	var vars := []
	# 變化 A（B9）
	var S := Vector2(-1, 1)
	var d := Vector2(2, -1)
	var X := S + d * 2.0
	var sa := [_L(2, -1, -7, "cyan", "L₁"), _Lpd(S, d, "pink", "L₂"), _dot(S, "", "pink"), _tag(S, "t = 0", "pink", {"off": [-20, -12]}),
		_walk(_steps(S, d, 2), 1), _dot(X, "P", "gold", {"at": 2, "off": [10, 14]})]
	vars.append({"eq": "L₁：2x − y − 7 = 0\nL₂：%s，求交點" % _par(S, d),
		"plane": _axes([-6.0, 9.0], [-3.6, 3.6], sa),
		"steps": [
			_f("t", "代進 L₁", "t = [0]", ["2"], "2(−1 + 2t) − (1 − t) − 7 = 5t − 10 = 0 ⇒ t = 2", "L₂ 的 x、y 代進 L₁ 的式子。", T_PAR),
			_f("交點", "t 代回 L₂", "P = ([0], [1])", ["3", "-1"], "t = 2：(−1 + 4, 1 − 2) = (3, −1)", "t = 2 代回 x = −1 + 2t、y = 1 − t。", T_PAR),
		]})
	# 變化 B（B10）
	var S2 := Vector2(-4, 5)
	var v := Vector2(3, -1)
	var P := S2 + v * 3.0
	var sb := [_L(1, -2, -1, "cyan", "x − 2y = 1"), _dot(S2, "", "text"), _ar(S2, S2 + v, "gold", "\\vec{v}", {"ls": -1}),
		_walk(_steps(S2, v, 3), 1), _dot(P, "P", "gold", {"at": 2, "off": [10, -6]})]
	vars.append({"eq": "從 (−4, 5) 沿 \\vec{v} = (3, −1) 一直前進\n碰到 x − 2y = 1 的點 P",
		"plane": _axes([-7.0, 9.0], [-1.5, 6.5], sb),
		"steps": [
			_f("t", "代進直線", "t = [0]", ["3"], "(−4 + 3t) − 2(5 − t) = 5t − 14 = 1 ⇒ t = 3", "P = (−4 + 3t, 5 − t) 代進 x − 2y = 1。", T_PAR),
			_f("P", "t 代回去", "P = ([0], [1])", ["5", "2"], "t = 3：P = (5, 2)", "t = 3 代回 (−4 + 3t, 5 − t)。", T_PAR),
		]})
	return {"id": "kmeet", "chapter": 1, "type": "forge", "title": "兩條航道交會",
		"story": "風箏沿著一條航道飛，什麼時候碰到另一條？",
		"insight": "參數式代進另一條直線的方程式，解出 t\nt 代回參數式就是交點。",
		"variants": vars}


## 8 燈塔到航道的距離（B11）
static func _dist() -> Dictionary:
	var vars := []
	for cfg in [{"P": Vector2(2, -1), "Q": Vector2(1, 4), "d": Vector2(3, -4), "n": Vector2(4, 3), "x": [-4.0, 12.0], "y": [-2.5, 5.5]},
			{"P": Vector2(0, 2), "Q": Vector2(3, -1), "d": Vector2(4, 3), "n": Vector2(3, -4), "x": [-5.0, 11.0], "y": [-3.2, 4.2]}]:
		var P: Vector2 = cfg.P
		var Q: Vector2 = cfg.Q
		var d: Vector2 = cfg.d
		var n: Vector2 = cfg.n
		var k := n.dot(Q)
		var num := absf(n.dot(P) - k)
		var Fo := _foot(n.x, n.y, -k, P)
		var shapes := [_Lpd(Q, d, "cyan", "L"), _dot(P, "P", "gold", {"off": [-16, -6]}), _dot(Q, "", "text"),
			_ar(Q, Q + d * 0.5, "cyan", "", {"w": 2.0}), _ar(Q, Q + n * 0.5, "pink", "", {"at": 1}), _right(Q, d, n, {"at": 1}),
			_seg(P, Fo, "gold", {"at": 3, "w": 3.0}), _right(Fo, -d, P - Fo, {"at": 3}),
			{"k": "label", "p": _p((P + Fo) / 2.0), "s": "\\frac{%d}{5}" % int(num), "c": "gold", "math": true, "off": [16, 0], "at": 3}]
		vars.append({"eq": "P%s 到 L：%s 的距離" % [_pt(P), _par(Q, d)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("法向量", "和方向向量垂直", "\\vec{n} = ([0], [1])", [_ans(n.x), _ans(n.y)], "方向向量 %s，法向量 %s" % [_pt(d), _pt(n)], "(a, b) 和 %s 垂直：交換、變一個號。" % _pt(d), T_NRM, "prop"),
				_f("一般式", "代 t = 0 的點", "%s = [0]" % _lin2(n.x, n.y, 0.0), [_ans(k)], "代 %s：%s" % [_pt(Q), _lk(n.x, n.y, k)], "L 過 %s。" % _pt(Q), T_NRM),
				_f("距離", "點到直線的距離", "距離 = [0]", ["%d/5" % int(num)],
					"\\frac{|%s|}{\\sqrt{%s^{2} + %s^{2}}} = \\frac{%d}{5}" % [_lin2(n.x, n.y, -k).replace("x", "(%s)" % _num(P.x)).replace("y", "(%s)" % _num(P.y)), _num(absf(n.x)), _num(absf(n.y)), int(num)],
					"\\frac{|ax_{0} + by_{0} − c|}{\\sqrt{a^{2} + b^{2}}}：分子加絕對值，分母是法向量的長。", T_DST),
			]})
	return {"id": "kdist", "chapter": 1, "type": "forge", "title": "燈塔到航道的距離",
		"story": "燈塔 P 拉一條最短的繩子到航道。",
		"insight": "參數式先換成 ax + by = c（法向量 ⊥ 方向向量）\nP 到直線的距離 = \\frac{|ax_{0} + by_{0} − c|}{\\sqrt{a^{2} + b^{2}}}。",
		"variants": vars}


## 9 沿航道走固定距離（B15）
static func _walk_k() -> Dictionary:
	var vars := []
	for cfg in [{"L": [1, 2, -5], "A": Vector2(1, 2), "d": Vector2(2, -1), "len": "√5", "k": 3, "dist": "3√5", "x": [-8.0, 10.0], "y": [-2.4, 6.4]},
			{"L": [4, 3, 5], "A": Vector2(-2, 1), "d": Vector2(3, -4), "len": "5", "k": 1, "dist": "5", "x": [-9.0, 6.0], "y": [-4.2, 6.2]}]:
		var L: Array = cfg.L
		var A: Vector2 = cfg.A
		var d: Vector2 = cfg.d
		var k := int(cfg.k)
		var P1 := A + d * k
		var P2 := A - d * k
		var shapes := [_L(L[0], L[1], L[2], "cyan", "L"), _dot(A, "A", "text", {"off": [-16, -8]}),
			_ar(A, A + d, "lime", "\\vec{d}", {"at": 1, "ls": -1}),
			_walk(_steps(A, d, k), 3), _walk(_steps(A, -d, k), 3), _dot(P1, "", "gold", {"at": 3}), _dot(P2, "", "gold", {"at": 3})]
		var lstr := _lstr(L[0], L[1], L[2]) if int(L[2]) > 0 else _lk(L[0], L[1], -L[2])
		vars.append({"eq": "A%s 在 L：%s 上\nL 上和 A 距離 %s 的點？" % [_pt(A), lstr, cfg.dist],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("方向", "L 的方向向量", "\\vec{d} = ([0], [1])", [_ans(d.x), _ans(d.y)], "法向量 (%d, %d)，方向向量 %s" % [L[0], L[1], _pt(d)], "方向向量 (b, −a)。", T_NRM, "prop"),
				_f("一步多長", "方向向量的長", "|\\vec{d}| = [0]", [cfg.len], "|\\vec{d}| = %s" % cfg.len, "\\sqrt{%s^{2} + %s^{2}}。" % [_num(absf(d.x)), _num(absf(d.y))], T_DST),
				{"kind": "fill", "name": "兩個點", "q": "往兩邊各走 %d 步" % k, "template": "([0], [1])、([2], [3])",
				 "answers": [_ans(P1.x), _ans(P1.y), _ans(P2.x), _ans(P2.y)], "alts": [[_ans(P2.x), _ans(P2.y), _ans(P1.x), _ans(P1.y)]],
				 "line": "A ± %s\\vec{d}：%s、%s" % ["" if k == 1 else str(k), _pt(P1), _pt(P2)], "nudge": "%s = %d|\\vec{d}|：另一個方向也可以。" % [cfg.dist, k],
				 "tag": T_DST, "paren": true},
			]})
	return {"id": "kstep", "chapter": 1, "type": "forge", "title": "沿航道走固定距離",
		"story": "從 A 沿著航道往前、往後各走一樣遠。",
		"insight": "距離 k|\\vec{d}| 的點：A ± k\\vec{d}（\\vec{d} 是方向向量）\n兩個方向都要算。",
		"variants": vars}


## 10 轉 90° 的頂點（B16、B17）
static func _turn() -> Dictionary:
	var vars := []
	# 變化 A（B16）：菱形
	var A := Vector2(1, 1)
	var C := Vector2(5, 3)
	var M := (A + C) / 2.0
	var D := Vector2(1, 6)
	var Bv := Vector2(5, -2)
	var sa := [_seg(A, C, "cyan", {"w": 2.5})]
	sa += B1._dots({"A": A, "C": C}, "text", {"A": [-14, 14], "C": [10, 4]})
	sa += [_dot(M, "M", "dim", {"at": 1, "off": [10, 14]}), _ar(M, D, "gold", "", {"at": 3}), _ar(M, Bv, "dim", "", {"at": 3, "dash": true}),
		_dot(D, "D", "gold", {"at": 3, "off": [10, -6]}), _dot(Bv, "", "dim", {"at": 3}), _right(M, C - M, D - M, {"at": 3}),
		_poly([A, Bv, C, D], "lime", {"at": 4, "fill": "lime", "alpha": 0.18}), _tag(Bv, "B", "text", {"at": 4, "off": [10, 4]})]
	vars.append({"eq": "菱形 ABCD，A(1, 1)、C(5, 3)，面積 20\nD 在第一象限，求 D",
		"plane": _axes([-6.0, 12.0], [-3.5, 7.5], sa),
		"steps": [
			_f("中點", "對角線互相平分", "M = ([0], [1])", ["3", "2"], "M = \\frac{A + C}{2} = (3, 2)", "A、C 的平均。", T_TRN),
			_f("\\ol{BD}", "菱形面積", "\\ol{BD} = [0]", ["4√5"], "\\ol{AC} = 2√5，\\frac{1}{2} × 2√5 × \\ol{BD} = 20 ⇒ \\ol{BD} = 4√5", "面積 = \\frac{1}{2} × \\ol{AC} × \\ol{BD}，\\ol{AC} = 2√5。", T_TRN),
			_f("\\vec{MD}", "\\vec{MD} ⊥ \\vec{AC}", "\\vec{MD} = ±[0](−1, 2)", ["2"], "\\vec{AC} = (4, 2) 轉 90°：(−1, 2)，|\\vec{MD}| = 2√5 ⇒ \\vec{MD} = ±2(−1, 2)",
				"|(−1, 2)| = √5，\\vec{MD} 的長是 \\ol{BD} 的一半。", T_TRN),
			_f("D", "D 在第一象限", "D = ([0], [1])", ["1", "6"], "M ± 2(−1, 2)：(1, 6) 或 (5, −2)，第一象限的是 D(1, 6)", "(3, 2) ± (−2, 4)。", T_TRN),
		]})
	# 變化 B（B17）：正方形
	var A2 := Vector2(1, -2)
	var B2 := Vector2(-1, 2)
	var sq1 := [A2, B2, Vector2(3, 4), Vector2(5, 0)]
	var sq2 := [A2, B2, Vector2(-5, 0), Vector2(-3, -4)]
	var sb := [_seg(A2, B2, "cyan", {"w": 3.0})]
	sb += B1._dots({"A": A2, "B": B2}, "text", {"A": [8, 14], "B": [-16, -6]})
	sb += [_ar(A2, A2 + Vector2(4, 2), "gold", "", {"at": 2}), _ar(A2, A2 - Vector2(4, 2), "gold", "", {"at": 2}),
		_poly(sq1, "faint", {"at": 2, "dash": true}), _poly(sq2, "faint", {"at": 2, "dash": true})]
	var cands := [[Vector2(5, 0), true, "D 可以是 (5, 0)：A + (4, 2)。"], [Vector2(-5, 0), true, "C 可以是 (−5, 0)：B − (4, 2)。"],
		[Vector2(5, 4), false, "C 是 (3, 4) 或 (−5, 0)，D 是 (5, 0) 或 (−3, −4)：沒有 (5, 4)。"],
		[Vector2(-3, 4), false, "(−3, 4) 不是正方形的頂點：\\vec{B}(−3, 4) 和 \\vec{AB} 不垂直。"]]
	var stb := [
		_f("\\vec{AB}", "終點減起點", "\\vec{AB} = ([0], [1])", ["-2", "4"], "\\vec{AB} = (−2, 4)", "B − A。", T_TRN),
		{"kind": "fill", "name": "轉 90°", "q": "\\vec{AB} 轉 90°", "template": "\\vec{AD} = ([0], [1])", "answers": ["4", "2"], "alts": [["-4", "-2"]],
		 "line": "(−2, 4) 轉 90°：(4, 2) 或 (−4, −2)：兩個正方形", "nudge": "(a, b) 轉 90° 是 (b, −a) 或 (−b, a)。", "tag": T_TRN, "paren": true}]
	for k in cands.size():
		var cd: Array = cands[k]
		sb.append(_dot(cd[0], "", "lime" if cd[1] else "pink", {"at": k + 3}))
		stb.append(_j("審判%s" % ["一", "二", "三", "四"][k], "C 或 D 可以是 %s" % _pt(cd[0]), cd[1], cd[2], "%s：%s" % [_pt(cd[0]), "○" if cd[1] else "✕"], T_TRN))
	stb[5]["why"] = "(−3, 4) − (−1, 2) = (−2, 2)，和 \\vec{AB} 不垂直：不是頂點。"
	vars.append({"eq": "正方形 ABCD，A(1, −2)、B(−1, 2)\nC、D 可以是哪些點？", "plane": _axes([-9.0, 9.0], [-4.8, 5.2], sb), "steps": stb})
	return {"id": "kturn", "chapter": 1, "type": "forge", "title": "轉 90° 的頂點",
		"story": "箭頭轉 90°，就找到正方形和菱形的頂點。",
		"insight": "(a, b) 轉 90°：(−b, a) 或 (b, −a)，長度不變\n菱形的對角線互相垂直平分，面積 = 對角線相乘的一半。",
		"variants": vars}


# ======================= 第二章．極值、投影、反射與夾角 =======================

## 12 航道上的極值（B12、B13、B14）
static func _extreme() -> Dictionary:
	var vars := []
	# 變化 A（B12）：線段上一次式的最大值
	var A := Vector2(-3, 2)
	var B := Vector2(2, -1)
	var px := _ex(A.x, B.x - A.x)
	var py := _ex(A.y, B.y - A.y)
	var sa := [_seg(A, B, "cyan", {"w": 2.5})]
	sa += B1._dots({"A": A, "B": B}, "text", {"A": [-14, -8], "B": [8, 14]})
	var la := [{"k": "dot", "p": [px, py], "c": "gold", "s": "", "trail": true}, {"k": "kite", "p": [px, py], "c": "gold"}]
	vars.append({"eq": "A(−3, 2)、B(2, −1)，P(x, y) 在線段 AB 上\n求 2x − 3y + 4 的最大值",
		"plane": _axes([-5.5, 4.5], [-2.5, 3.5], sa),
		"steps": [
			_f("寫成 t", "P = (−3 + 5t, 2 − 3t)", "2x − 3y + 4 = [0]t − [1]", ["19", "8"], "2(−3 + 5t) − 3(2 − 3t) + 4 = 19t − 8，0 ≤ t ≤ 1", "x = −3 + 5t、y = 2 − 3t 代進去。", T_PAR),
			{"kind": "slide", "name": "最大", "q": "拖 t，找最大值", "tag": T_PAR,
			 "params": [{"n": "t", "min": 0, "max": 1, "step": 0.125, "v": 0.5}], "lines": la, "goal": {"t": 1},
			 "eq": "t = {t}：2x − 3y + 4 = {19 * t - 8}", "traps": [[{"t": 0}, "這是最小值 −8，題目問最大。"]],
			 "line": "一次函數：t = 1（B）最大，最大值 11", "nudge": "19t − 8 越大越好：t 要多大？"},
		]})
	# 變化 B（B13）：平方和的最小值
	var A2 := Vector2(3, 1)
	var B2 := Vector2(-1, 3)
	var lb := [{"k": "dot", "p": ["t", "1 - t"], "c": "gold", "s": "P", "trail": true},
		{"k": "seg", "a": ["t", "1 - t"], "b": [3, 1], "c": "pink"}, {"k": "seg", "a": ["t", "1 - t"], "b": [-1, 3], "c": "pink"}]
	var sb := [_L(1, 1, -1, "cyan", "x + y = 1")]
	sb += B1._dots({"A": A2, "B": B2}, "text", {"A": [8, -6], "B": [-14, -8]})
	vars.append({"eq": "A(3, 1)、B(−1, 3)，P 在 x + y − 1 = 0 上\n\\ol{AP}^{2} + \\ol{BP}^{2} 最小時 P 在哪裡？",
		"plane": _axes([-4.5, 6.0], [-2.2, 4.2], sb),
		"steps": [
			_f("寫成 t", "P = (t, 1 − t)", "\\ol{AP}^{2} + \\ol{BP}^{2} = [0]t^{2} + [1]", ["4", "14"],
				"(t − 3)^{2} + t^{2} + (t + 1)^{2} + (t + 2)^{2} = 4t^{2} + 14", "\\ol{AP}^{2} = (t − 3)^{2} + (1 − t − 1)^{2}。", T_PAR),
			{"kind": "slide", "name": "最小", "q": "拖 t，找最小的地方", "tag": T_PAR,
			 "params": [{"n": "t", "min": -2, "max": 2, "step": 0.5, "v": 1.5}], "lines": lb, "goal": {"t": 0},
			 "eq": "t = {t}：\\ol{AP}^{2} + \\ol{BP}^{2} = {4 * t * t + 14}",
			 "line": "t = 0 最小：P(0, 1)，最小值 14", "nudge": "4t^{2} + 14：t = 0 最小。"},
		]})
	# 變化 C（B14）：內積的最小值
	var A3 := Vector2(3, 0)
	var B3v := Vector2(0, 3)
	var C3 := Vector2(-1, 0)
	var lc := [{"k": "dot", "p": ["3 - 3 * t", "3 * t"], "c": "gold", "s": "P", "trail": true},
		{"k": "arrow", "a": ["3 - 3 * t", "3 * t"], "b": [3, 0], "c": "cyan", "w": 2.0}, {"k": "arrow", "a": ["3 - 3 * t", "3 * t"], "b": [-1, 0], "c": "pink", "w": 2.0}]
	var sc := [_L(1, 1, -3, "faint")]
	sc += B1._dots({"A": A3, "B": B3v, "C": C3}, "text", {"A": [8, 14], "B": [-14, -6], "C": [-14, 14]})
	vars.append({"eq": "A(3, 0)、B(0, 3)、C(−1, 0)，P 在直線 AB 上\n求 \\vec{PA} · \\vec{PC} 的最小值",
		"plane": _axes([-3.5, 5.5], [-1.4, 4.4], sc),
		"steps": [
			_f("寫成 t", "P = (3 − 3t, 3t)", "\\vec{PA} · \\vec{PC} = [0]t^{2} − [1]t", ["18", "12"],
				"\\vec{PA} = (3t, −3t)、\\vec{PC} = (−4 + 3t, −3t)：內積 18t^{2} − 12t", "\\vec{PA} = A − P、\\vec{PC} = C − P。", T_PAR),
			{"kind": "slide", "name": "最小", "q": "拖 t，找最小的地方", "tag": T_PAR,
			 "params": [{"n": "t", "min": -0.5, "max": 1, "step": 1.0 / 12.0, "v": 0.75}], "lines": lc, "goal": {"t": 1.0 / 3.0},
			 "eq": "t = {t}：\\vec{PA} · \\vec{PC} = {18 * t * t - 12 * t}",
			 "line": "t = \\frac{1}{3} 最小：最小值 −2，P(2, 1)", "nudge": "18t^{2} − 12t 的頂點：t = \\frac{12}{36}。"},
		]})
	return {"id": "kext", "chapter": 2, "type": "forge", "title": "航道上的極值",
		"story": "風箏沿航道飛，什麼時候讀數最大、最小？",
		"insight": "P 在直線上：寫成 P = A + t\\vec{v}，式子變成 t 的函數\n一次式看端點，二次式看頂點。",
		"variants": vars}


## 13 最短的繩子（B19）
static func _rope() -> Dictionary:
	var vars := []
	for cfg in [{"L": [4, 3, -5], "A": Vector2(-2, -4), "B": Vector2(1, -3), "min": "5√2", "x": [-6.0, 11.0], "y": [-5.4, 3.0]},
			{"L": [1, -2, 3], "A": Vector2(-4, 2), "B": Vector2(1, 4), "min": "3√5", "x": [-9.0, 7.0], "y": [-3.0, 5.2]}]:
		var L: Array = cfg.L
		var n := Vector2(L[0], L[1])
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var Fo := _foot(L[0], L[1], L[2], A)
		var kk := (Fo - A).x / n.x
		var Ap := A + (Fo - A) * 2.0
		var dd := B - Ap
		var tt := -(n.dot(Ap) + float(L[2])) / n.dot(dd)
		var P := Ap + dd * tt
		var shapes := [_L(L[0], L[1], L[2], "cyan", "L")]
		shapes += B1._dots({"A": A, "B": B}, "text", {"A": [-16, 4], "B": [10, 4]})
		shapes += [_seg(A, Fo, "gold", {"at": 1, "dash": true}), _right(Fo, Vector2(-n.y, n.x), A - Fo, {"at": 1}), _dot(Fo, "", "gold", {"at": 1}),
			_seg(Fo, Ap, "gold", {"at": 2, "dash": true}), _dot(Ap, "A'", "violet", {"at": 2, "off": [10, -6]}),
			_seg(Ap, P, "violet", {"at": 3, "dash": true}), {"k": "path", "pts": [_p(A), _p(P), _p(B)], "c": "gold", "dur": 1.4, "at": 3}, _dot(P, "P", "gold", {"at": 3, "off": [10, 14]})]
		vars.append({"eq": "A%s、B%s，P 在 L：%s 上\n求垂足和 \\ol{PA} + \\ol{PB} 的最小值" % [_pt(A), _pt(B), _lstr(L[0], L[1], L[2])],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("垂足", "A + k\\vec{n} 代進 L", "k = [0]，垂足 ([1], [2])", [_ans(kk), _ans(Fo.x), _ans(Fo.y)],
					"A + k%s 代進 L：k = %s，垂足 %s" % [_pt(n), _num(kk), _pt(Fo)], "法向量 %s：從 A 沿著它走到 L 上。" % _pt(n), T_RFL),
				_f("對稱點", "穿過 L 再走一樣長", "A' = ([0], [1])", [_ans(Ap.x), _ans(Ap.y)], "A' = A + 2k\\vec{n} = %s" % _pt(Ap), "垂足是 \\ol{AA'} 的中點。", T_RFL),
				_f("最短", "\\ol{PA} + \\ol{PB} 最小", "最小值 = [0]", [cfg.min], "\\ol{PA} + \\ol{PB} = \\ol{PA'} + \\ol{PB} ≥ \\ol{A'B} = %s" % cfg.min,
					"A、B 在同一邊：換成 A'，A'、P、B 連成一直線最短。", T_RFL),
			]})
	return {"id": "krope", "chapter": 2, "type": "forge", "title": "最短的繩子",
		"story": "從 A 拉繩子碰一下航道，再拉到 B，最短多長？",
		"insight": "垂足：A + k\\vec{n} 代進直線；對稱點 A' = A + 2k\\vec{n}\nA、B 同一側：\\ol{PA} + \\ol{PB} 的最小值是 \\ol{A'B}。",
		"variants": vars}


## 14 鏡岩（B20）
static func _mirror() -> Dictionary:
	var vars := []
	for cfg in [{"u": Vector2(3, 4), "v": Vector2(5, 0), "m": Vector2(2, 1), "uh": Vector2(0.6, 0.8), "vh": Vector2(1, 0), "sum": ["8/5", "4/5"], "slope": "1/2",
				"sl": "(\\frac{3}{5}, \\frac{4}{5}) + (1, 0) = (\\frac{8}{5}, \\frac{4}{5}) ∥ (2, 1)"},
			{"u": Vector2(-6, 8), "v": Vector2(5, 0), "m": Vector2(1, 2), "uh": Vector2(-0.6, 0.8), "vh": Vector2(1, 0), "sum": ["2/5", "4/5"], "slope": "2",
				"sl": "(−\\frac{3}{5}, \\frac{4}{5}) + (1, 0) = (\\frac{2}{5}, \\frac{4}{5}) ∥ (1, 2)"}]:
		var u: Vector2 = cfg.u
		var v: Vector2 = cfg.v
		var m: Vector2 = cfg.m
		var O := Vector2.ZERO
		var lit := []
		for x in range(-6, 7):
			for y in range(-3, 4):
				if (x != 0 or y != 0) and absf(float(x) * m.y - float(y) * m.x) < 1e-9:
					lit.append([x, y])
		var uh: Vector2 = cfg.uh * 3.0
		var vh: Vector2 = cfg.vh * 3.0
		var shapes := [_ar(O, v.normalized() * 3.5, "lime", "\\vec{v}", {"dash": true, "w": 2.0, "ls": -1}), _dot(O, "O", "text", {"off": [-16, 14]}),
			_ar(O, uh, "pink", "", {"at": 2, "w": 2.5}), _ar(uh, uh + vh, "lime", "", {"at": 2, "w": 2.5}), _ar(O, uh + vh, "gold", "", {"at": 2, "w": 3.5}),
			_L(m.y, -m.x, 0, "faint", "", {"at": 1})]
		var good := "\\vec{u} + \\vec{v} = %s 不對：兩支長度不一樣，要先變成單位向量。" % _pt(u + v) if not is_equal_approx(u.length(), v.length()) else "單位向量：除以自己的長度。"
		vars.append({"eq": "光沿 \\vec{u} = %s 前進，碰到鏡子 L 反射後\n沿 \\vec{v} = %s 前進，求 L 的斜率" % [_pt(u), _pt(v)],
			"plane": _plane([-6.5, 6.5], [-3.4, 3.6], shapes),
			"steps": [
				{"kind": "vplace", "name": "拖鏡子", "q": "拖 T，讓反射光沿 \\vec{v}", "tag": T_RFL, "goal": "lit", "ans": _p(m), "big": true,
				 "sandbox": {"label": "T", "mirror": {"o": [0, 0], "u": _p(u), "len": 3.4}, "lit": lit, "start": [-2, 3] if m.x > m.y else [3, 1]},
				 "nudge": "入射角 = 反射角：鏡子要在兩道光的正中間。", "line": "鏡子 OT 的方向是 %s" % _pt(m)},
				_f("鏡子的方向", "單位向量相加", "\\frac{\\vec{u}}{|\\vec{u}|} + \\frac{\\vec{v}}{|\\vec{v}|} = ([0], [1])", cfg.sum, cfg.sl, good, T_RFL, "prop"),
				_f("斜率", "鏡子的斜率", "斜率 = [0]", [cfg.slope], "L 的方向 %s ⇒ 斜率 %s" % [_pt(m), _fv(m.y / m.x)], "方向向量 (a, b) 的斜率是 \\frac{b}{a}。", T_RFL),
			]})
	return {"id": "kmirror", "chapter": 2, "type": "forge", "title": "鏡岩",
		"story": "光打到鏡岩反射：鏡子要怎麼擺？",
		"insight": "入射角 = 反射角：鏡子平分兩道光的夾角\n鏡子 ∥ \\frac{\\vec{u}}{|\\vec{u}|} + \\frac{\\vec{v}}{|\\vec{v}|}（菱形的對角線）。",
		"variants": vars}


## 15 航道上的影子（B21）
static func _lproj() -> Dictionary:
	var vars := []
	for cfg in [{"A": Vector2(4, 1), "B": Vector2(-1, 6), "L": [1, -2, 1], "d": Vector2(2, 1), "x": [-5.0, 10.0], "y": [-1.2, 7.0]},
			{"A": Vector2(-2, -3), "B": Vector2(3, 2), "L": [3, 1, -4], "d": Vector2(1, -3), "x": [-6.0, 7.0], "y": [-4.0, 3.2]}]:
		var A: Vector2 = cfg.A
		var B: Vector2 = cfg.B
		var L: Array = cfg.L
		var d: Vector2 = cfg.d
		var ab := B - A
		var pr := d * (ab.dot(d) / d.length_squared())
		var Af := _foot(L[0], L[1], L[2], A)
		var Bf := _foot(L[0], L[1], L[2], B)
		var shapes := [_L(L[0], L[1], L[2], "cyan", "L"), _ar(A, B, "pink", "\\vec{AB}")]
		shapes += B1._dots({"A": A, "B": B}, "text", {"A": [10, 4], "B": [-16, -6]})
		shapes += [_ar(Af + (Bf - Af) * 0.0 + Vector2(-d.y, d.x).normalized() * 0.0, Af + d, "lime", "\\vec{d}", {"at": 1, "until": 2, "ls": -1}),
			_seg(A, Af, "gold", {"at": 2, "dash": true}), _seg(B, Bf, "gold", {"at": 2, "dash": true}),
			_ar(Af, Bf, "violet", "", {"at": 2, "w": 4.0}), _right(Af, d, A - Af, {"at": 2}), _right(Bf, d, B - Bf, {"at": 2})]
		vars.append({"eq": "A%s、B%s，求 \\vec{AB} 在\n直線 %s 上的正射影" % [_pt(A), _pt(B), _lstr(L[0], L[1], L[2]) if int(L[2]) > 0 else _lk(L[0], L[1], -L[2])],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("方向", "L 的方向向量", "\\vec{d} = ([0], [1])", [_ans(d.x), _ans(d.y)], "法向量 (%d, %d)，方向向量 \\vec{d} = %s" % [L[0], L[1], _pt(d)], "方向向量 (b, −a)。", T_LPJ, "prop"),
				_f("正射影", "\\vec{AB} 的影子", "正射影 = ([0], [1])", [_ans(pr.x), _ans(pr.y)],
					"\\frac{\\vec{AB} · \\vec{d}}{|\\vec{d}|^{2}}\\vec{d} = \\frac{%s}{%s}%s = %s" % [_num(ab.dot(d)), _num(d.length_squared()), _pt(d), _pt(pr)],
					"\\vec{AB} = %s，\\frac{\\vec{AB} · \\vec{d}}{|\\vec{d}|^{2}}\\vec{d}。" % _pt(ab), T_LPJ),
			]})
	return {"id": "kproj", "chapter": 2, "type": "forge", "title": "航道上的影子",
		"story": "陽光垂直照到航道，\\vec{AB} 的影子有多長？",
		"insight": "\\vec{AB} 在直線上的正射影 = \\frac{\\vec{AB} · \\vec{d}}{|\\vec{d}|^{2}}\\vec{d}\n\\vec{d} 是直線的方向向量（不是法向量）。",
		"variants": vars}


## 16 影子的另一頭（B22）
static func _lfoot() -> Dictionary:
	var vars := []
	for cfg in [{"L": [1, 2, -5], "A1": Vector2(1, 2), "AB": Vector2(6, 2), "d": Vector2(2, -1), "sg": 1.0, "x": [-4.0, 12.0], "y": [-1.4, 7.0]},
			{"L": [3, -1, -1], "A1": Vector2(1, 2), "AB": Vector2(-5, -5), "d": Vector2(1, 3), "sg": -1.0, "x": [-11.0, 7.0], "y": [-5.0, 4.2]}]:
		var L: Array = cfg.L
		var A1: Vector2 = cfg.A1
		var ab: Vector2 = cfg.AB
		var d: Vector2 = cfg.d
		var pr := d * (ab.dot(d) / d.length_squared())
		var B1p := A1 + pr
		var A := A1 + Vector2(L[0], L[1]) * float(cfg.sg)
		var B := A + ab
		var shapes := [_L(L[0], L[1], L[2], "cyan", "L"), _dot(A1, "A'", "text", {"off": [-20, 14]}),
			_dot(A, "A", "dim", {"off": [-14, -6]}), _dot(B, "B", "dim", {"off": [10, -6]}), _ar(A, B, "faint", "\\vec{AB}"),
			_seg(A, A1, "faint", {"dash": true}), _right(A1, d, A - A1),
			_ar(A1, B1p, "violet", "", {"at": 1, "w": 4.0}), _seg(B, B1p, "gold", {"at": 2, "dash": true}), _right(B1p, d, B - B1p, {"at": 2}),
			_dot(B1p, "B'", "gold", {"at": 2, "off": [10, 14]})]
		var lstr := _lk(L[0], L[1], -L[2])
		vars.append({"eq": "L：%s，A 的投影點 A'%s\n\\vec{AB} = %s，求 B 的投影點 B'" % [lstr, _pt(A1), _pt(ab)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("影子", "\\vec{AB} 在 L 上的正射影", "\\vec{A'B'} = ([0], [1])", [_ans(pr.x), _ans(pr.y)],
					"L 的方向 %s：\\frac{%s}{%s}%s = %s" % [_pt(d), _num(ab.dot(d)), _num(d.length_squared()), _pt(d), _pt(pr)], "\\vec{A'B'} 就是 \\vec{AB} 的影子。", T_LPJ),
				_f("B'", "A' 加上影子", "B' = ([0], [1])", [_ans(B1p.x), _ans(B1p.y)], "B' = A' + \\vec{A'B'} = %s" % _pt(B1p), "從 A' 沿著影子走。", T_LPJ),
			]})
	return {"id": "kfoot", "chapter": 2, "type": "forge", "title": "影子的另一頭",
		"story": "知道 A 的影子落在哪，B 的影子在哪？",
		"insight": "A、B 在 L 上的投影點 A'、B'：\\vec{A'B'} 是 \\vec{AB} 在 L 上的正射影\nB' = A' + 正射影。",
		"variants": vars}


## 17 交叉的航道（B23）
static func _cross() -> Dictionary:
	var vars := []
	for cfg in [{"L1": [1, 3, 1], "L2": [2, -1, 3], "cos": "√2/10", "x": [-3.5, 6.5], "y": [-2.6, 2.6]},
			{"L1": [1, 2, 3], "L2": [3, 1, 5], "cos": "√2/2", "x": [-2.5, 5.5], "y": [-1.4, 2.8]}]:
		var a: Array = cfg.L1
		var b: Array = cfg.L2
		var det := float(a[0] * b[1] - a[1] * b[0])
		var X := Vector2((a[2] * b[1] - a[1] * b[2]) / det, (a[0] * b[2] - a[2] * b[0]) / det)
		var m := Vector2(a[0], a[1])
		var n := Vector2(b[0], b[1])
		var d1 := Vector2(a[1], -a[0])
		var d2 := Vector2(b[1], -b[0])
		var g1 := _deg(d1)
		var g2 := _deg(d2)
		if absf(g2 - g1) > 90.0:
			g2 = _deg(-d2)
		var h1 := _deg(m)
		var h2 := _deg(n)
		if absf(h2 - h1) > 180.0:
			h2 += 360.0 * signf(h1 - h2)
		var shapes := [_L(a[0], a[1], -a[2], "cyan", "L₁"), _L(b[0], b[1], -b[2], "pink", "L₂"),
			_ar(X, X + m.normalized() * 1.6, "cyan", "\\vec{m}", {"at": 1, "w": 2.5}), _ar(X, X + n.normalized() * 1.6, "pink", "\\vec{n}", {"at": 1, "w": 2.5, "ls": -1}),
			_arc(X, g1, g2, "θ", {"at": 2})]
		vars.append({"eq": "L₁：%s，L₂：%s\n銳角交角 θ，求 cos θ" % [_lk(a[0], a[1], a[2]), _lk(b[0], b[1], b[2])],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("法向量", "兩條直線的法向量", "\\vec{m} = ([0], [1])，\\vec{n} = ([2], [3])", [_ans(m.x), _ans(m.y), _ans(n.x), _ans(n.y)],
					"\\vec{m} = %s、\\vec{n} = %s：兩直線的夾角和兩支法向量的夾角一樣（或互補）" % [_pt(m), _pt(n)], "ax + by = c 的法向量 (a, b)。", T_ANG),
				_f("cos θ", "銳角", "cos θ = [0]", [cfg.cos],
					"cos θ = \\frac{|\\vec{m} · \\vec{n}|}{|\\vec{m}||\\vec{n}|} = \\frac{%s}{\\sqrt{%s}\\sqrt{%s}} = %s" % [_num(absf(m.dot(n))), _num(m.length_squared()), _num(n.length_squared()), _rad_frac(String(cfg.cos))],
					"題目問銳角：分子取絕對值。", T_ANG),
			]})
	return {"id": "kangle", "chapter": 2, "type": "forge", "title": "交叉的航道",
		"story": "兩條航道交叉，看法向量就知道夾多大。",
		"insight": "兩直線的夾角 = 兩支法向量的夾角（或補角）\n銳角：cos θ = \\frac{|\\vec{m} · \\vec{n}|}{|\\vec{m}||\\vec{n}|}。",
		"variants": vars}


## 18 參數式的交點和夾角（B24）
static func _pcross() -> Dictionary:
	var vars := []
	for cfg in [{"P1": Vector2(-1, 1), "d1": Vector2(2, 1), "P2": Vector2(2, 0), "d2": Vector2(1, 3), "t": 2, "s": 1, "cos": "√2/2", "sin": "√2/2", "x": [-3.5, 7.5], "y": [-1.0, 4.6]},
			{"P1": Vector2(2, -1), "d1": Vector2(3, -1), "P2": Vector2(-2, 3), "d2": Vector2(1, -3), "t": -1, "s": 1, "cos": "3/5", "sin": "4/5", "x": [-5.5, 6.5], "y": [-2.4, 3.8]}]:
		var P1: Vector2 = cfg.P1
		var d1: Vector2 = cfg.d1
		var P2: Vector2 = cfg.P2
		var d2: Vector2 = cfg.d2
		var t := int(cfg.t)
		var s := int(cfg.s)
		var P := P1 + d1 * t
		var g1 := _deg(d1)
		var g2 := _deg(d2)
		if absf(g2 - g1) > 90.0:
			g2 = _deg(-d2)
		var shapes := [_Lpd(P1, d1, "cyan", "L₁"), _Lpd(P2, d2, "pink", "L₂"), _dot(P1, "", "cyan"), _dot(P2, "", "pink"),
			_tag(P1, "t = 0", "cyan", {"off": [-18, 18]}), _tag(P2, "s = 0", "pink", {"off": [10, 16]}),
			_walk(_steps(P1, d1, t), 1), _walk(_steps(P2, d2, s), 1, {"c": "lime"}), _dot(P, "P", "gold", {"at": 1, "off": [10, -8]}),
			_arc(P, g1, g2, "θ", {"at": 3})]
		vars.append({"eq": "L₁：%s，L₂：%s\n求交點 P 和夾角 θ 的 sin θ" % [_parp(P1, d1), _parp(P2, d2, "s")],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("交點", "解 L₁ = L₂", "t = [0]，P = ([1], [2])", [str(t), _ans(P.x), _ans(P.y)],
					"%s = %s、%s = %s ⇒ t = %d（s = %d），P%s" % [_pc(P1.x, d1.x, "t"), _pc(P2.x, d2.x, "s"), _pc(P1.y, d1.y, "t"), _pc(P2.y, d2.y, "s"), t, s, _pt(P)],
					"x、y 各列一條，解 t、s。", T_PAR),
				_f("cos θ", "方向向量的夾角", "cos θ = [0]", [cfg.cos],
					"cos θ = \\frac{|%s · %s|}{|%s||%s|} = %s" % [_pt(d1), _pt(d2), _pt(d1), _pt(d2), _rad_frac(String(cfg.cos))], "方向向量 %s、%s，取絕對值。" % [_pt(d1), _pt(d2)], T_ANG),
				_f("sin θ", "sin^{2} θ + cos^{2} θ = 1", "sin θ = [0]", [cfg.sin], "sin θ = \\sqrt{1 − cos^{2} θ} = %s" % _rad_frac(String(cfg.sin)), "sin^{2} θ = 1 − cos^{2} θ。", T_ANG),
			]})
	return {"id": "kpangle", "chapter": 2, "type": "forge", "title": "參數式的交點和夾角",
		"story": "兩隻風箏各飛各的航道，在哪裡相遇？",
		"insight": "兩條參數式：x、y 各列一條，解 t、s 就是交點\n夾角用方向向量：cos θ = \\frac{|\\vec{d_{1}} · \\vec{d_{2}}|}{|\\vec{d_{1}}||\\vec{d_{2}}|}。",
		"variants": vars}


## "√2/10" → "\\frac{√2}{10}"（推導句用）
static func _rad_frac(s: String) -> String:
	if not s.contains("/"):
		return s
	var pr := s.split("/")
	return "\\frac{%s}{%s}" % [pr[0], pr[1]]


## 19 已知斜率的交角（B25）
static func _slope() -> Dictionary:
	var vars := []
	for cfg in [{"P1": Vector2(1, -1), "d1": Vector2(2, 1), "m": -3, "cos": "√2/10", "sin": "7√2/10", "x": [-3.5, 6.0], "y": [-4.6, 2.6]},
			{"P1": Vector2(2, 0), "d1": Vector2(1, 3), "m": 2, "cos": "7√2/10", "sin": "√2/10", "x": [-2.0, 6.0], "y": [-1.4, 4.4]}]:
		var P1: Vector2 = cfg.P1
		var d1: Vector2 = cfg.d1
		var m := int(cfg.m)
		var d2 := Vector2(1, m)
		var g1 := _deg(d1)
		var g2 := _deg(d2)
		if absf(g2 - g1) > 90.0:
			g2 = _deg(-d2)
		var shapes := [_Lpd(P1, d1, "cyan", "L₁"), _dot(P1, "", "text"),
			_Lpd(P1, d2, "pink", "L₂", {"at": 1}), _seg(P1, P1 + Vector2(1, 0), "gold", {"at": 1, "dash": true}), _seg(P1 + Vector2(1, 0), P1 + d2, "gold", {"at": 1, "dash": true}),
			_tag(P1 + Vector2(0.5, 0), "1", "gold", {"at": 1, "off": [-4, 16 if m > 0 else -8]}), _tag(P1 + Vector2(1, m * 0.5), _num(m), "gold", {"at": 1, "off": [8, 4]}),
			_arc(P1, g1, g2, "θ", {"at": 3})]
		vars.append({"eq": "L₁：%s\nL₂ 的斜率是 %s，求交角 θ 的 sin θ" % [_par(P1, d1), _num(m)],
			"plane": _axes(cfg.x, cfg.y, shapes),
			"steps": [
				_f("L₂ 的方向", "斜率 m：(1, m)", "L₂ 的方向向量 (1, [0])", [str(m)], "斜率 %s：往右 1、往上 %s ⇒ (1, %s)" % [_num(m), _num(m), _num(m)], "斜率 = \\frac{往上}{往右}。", T_ANG),
				_f("cos θ", "方向向量的夾角", "|cos θ| = [0]", [cfg.cos],
					"|cos θ| = \\frac{|%s · %s|}{|%s||%s|} = %s" % [_pt(d1), _pt(d2), _pt(d1), _pt(d2), _rad_frac(String(cfg.cos))], "取絕對值。", T_ANG),
				_f("sin θ", "sin^{2} θ + cos^{2} θ = 1", "sin θ = [0]", [cfg.sin], "sin θ = \\sqrt{1 − cos^{2} θ} = %s" % _rad_frac(String(cfg.sin)),
					"不是 cos θ：sin^{2} θ = 1 − cos^{2} θ。", T_ANG),
			]})
	return {"id": "kslope", "chapter": 2, "type": "forge", "title": "已知斜率的交角",
		"story": "只知道另一條航道的斜率，也量得出夾角。",
		"insight": "斜率 m 的直線：方向向量 (1, m)\n交角的 sin：先算 cos，再用 sin^{2} θ + cos^{2} θ = 1。",
		"variants": vars}


## 20 轉動的航道（B26）
static func _rotate() -> Dictionary:
	var vars := []
	# 第 1 組：x − 3y + 5 = 0、ax + y − 4 = 0 夾 45°：a = 1/2 或 −2
	var c1 := "pow(a - 3, 2) - 5 * (a * a + 1)"
	var s1 := [_L(1, -3, 5, "cyan", "L₁"), _dot(Vector2(0, 4), "", "pink"),
		_L(0.5, 1, -4, "lime", "", {"at": 3, "dash": true}), _L(-2, 1, -4, "lime", "", {"at": 3, "dash": true})]
	var l1 := [{"abc": ["a", "1", "-4"], "c": "pink", "s": "L₂"},
		{"k": "label", "p": [1.2, 5.2], "s": "45°", "c": "gold", "when": "abs(%s) < 0.001" % c1}]
	vars.append({"eq": "L₁：x − 3y + 5 = 0，L₂：ax + y − 4 = 0\n夾角之一是 45°，求 a",
		"plane": _axes([-7.0, 6.0], [-1.6, 6.0], s1),
		"steps": [
			{"kind": "slide", "name": "轉 L₂", "q": "拖 a，讓夾角是 45°", "tag": T_ANG,
			 "params": [{"n": "a", "min": -3, "max": 2, "step": 0.5, "v": 1}], "lines": l1,
			 "goal": {"a": 0.5}, "goals": [{"a": 0.5}, {"a": -2}], "other_at": 2, "others": ["-2", "1/2"],
			 "other_lines": ["另一個 a = −2：(2a − 1)(a + 2) = 0", "另一個 a = \\frac{1}{2}：(2a − 1)(a + 2) = 0"],
			 "eq": "a = {a}：銳角交角 ≈ {round(acos(abs(a - 3) / sqrt(10 * (a * a + 1))) * 57.29578)}°",
			 "line": "L₂ 繞著 (0, 4) 轉，夾 45° 時 45° 亮起來", "nudge": "看讀數，讓它變成 45°。"},
			_f("列式", "cos^{2} 45° = \\frac{1}{2}", "2a^{2} + [0]a − [1] = 0", ["3", "2"],
				"\\frac{(a − 3)^{2}}{10(a^{2} + 1)} = \\frac{1}{2} ⇒ 2a^{2} + 3a − 2 = 0", "法向量 (1, −3)、(a, 1)：(a − 3)^{2} × 2 = 10(a^{2} + 1)。", T_ANG),
			_f("另一個 a", "解方程式", "另一個 a = [0]", ["-2"], "另一個 a = −2", "2a^{2} + 3a − 2 = (2a − 1)(a + 2)。", T_ANG),
		]})
	# 第 2 組：3x + y − 1 = 0、x + ay + 2 = 0 夾 135°：a = 2 或 −1/2
	var c2 := "pow(3 + a, 2) - 5 * (1 + a * a)"
	var s2 := [_L(3, 1, -1, "cyan", "L₁"), _dot(Vector2(-2, 0), "", "pink"),
		_L(1, 2, 2, "lime", "", {"at": 3, "dash": true}), _L(1, -0.5, 2, "lime", "", {"at": 3, "dash": true})]
	var l2 := [{"abc": ["1", "a", "2"], "c": "pink", "s": "L₂"},
		{"k": "label", "p": [2.6, 3.4], "s": "45°", "c": "gold", "when": "abs(%s) < 0.001" % c2}]
	vars.append({"eq": "L₁：3x + y − 1 = 0，L₂：x + ay + 2 = 0\n夾角之一是 135°，求 a",
		"plane": _axes([-6.0, 5.0], [-3.0, 4.2], s2),
		"steps": [
			{"kind": "slide", "name": "轉 L₂", "q": "拖 a，讓夾角是 45°", "tag": T_ANG,
			 "params": [{"n": "a", "min": -2, "max": 3, "step": 0.5, "v": 0}], "lines": l2,
			 "goal": {"a": 2}, "goals": [{"a": 2}, {"a": -0.5}], "other_at": 2, "others": ["-1/2", "2"],
			 "other_lines": ["另一個 a = −\\frac{1}{2}：(2a + 1)(a − 2) = 0", "另一個 a = 2：(2a + 1)(a − 2) = 0"],
			 "eq": "a = {a}：銳角交角 ≈ {round(acos(abs(3 + a) / sqrt(10 * (1 + a * a))) * 57.29578)}°",
			 "line": "135° 和 45° 是同一對直線的兩個夾角", "nudge": "135° 的另一個夾角是 45°：讓讀數變成 45°。"},
			_f("列式", "cos^{2} 135° = \\frac{1}{2}", "2a^{2} − [0]a − [1] = 0", ["3", "2"],
				"\\frac{(3 + a)^{2}}{10(1 + a^{2})} = \\frac{1}{2} ⇒ 2a^{2} − 3a − 2 = 0", "法向量 (3, 1)、(1, a)：(3 + a)^{2} × 2 = 10(1 + a^{2})。", T_ANG),
			_f("另一個 a", "解方程式", "另一個 a = [0]", ["-1/2"], "另一個 a = −\\frac{1}{2}", "2a^{2} − 3a − 2 = (2a + 1)(a − 2)。", T_ANG),
		]})
	return {"id": "krot", "chapter": 2, "type": "forge", "title": "轉動的航道",
		"story": "轉動一條航道，讓兩條航道夾 45°。",
		"insight": "夾角 45° 或 135°：cos^{2} θ = \\frac{1}{2}，平方之後兩個解都要\n135° 和 45° 是同一對直線的兩個夾角。",
		"variants": vars}
