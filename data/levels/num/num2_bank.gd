extends RefCounted
## 數與式 第二大關「繩上珠子」題庫（對應講義重點二：分點公式）
## 設計稿：docs/num_r2_design.md。題目的數字都用程式驗算過（tools/num/verify_r2.py）。
##
## 旅程（引擎見 num_level.gd）：
##   forge  一步一步推導：choice、fill、order、slide（拖珠子）
##   speed  速算：gen = "bead"（內分點、外分點的坐標）、"where"（分點靠近 a、靠近 b、在外面）
## 題目的 "field" 是數線柵欄：繩子 rope、珠子 bead、砝碼 weights、跑者 run、縮小地圖 road（寫法見 num_field.gd 開頭）。
## 要學生找的點，答對之後才出現在數線上（design_rules 1.5）。每一步都是回答題目必要的（1.7）。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/num/num1_bank.gd")

const T_DIV := "num_divide"        # 內分點公式
const T_EXT := "num_external"      # 外分點（所有可能的位置）
const T_APP := "num_divapp"        # 分點的應用：縮小比例、追趕
const T_DCMP := "num_divcmp"       # 分點比大小（權重、位置）


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return SB.fill(name, q, template, answers, line, nudge, tag, mode)


static func _j(name: String, statement: String, ok: bool, why: String, line: String, tag: String) -> Dictionary:
	return B1._j(name, statement, ok, why, line, tag)


static func _o(q: String, items: Array, line: String, nudge: String, tag: String) -> Dictionary:
	return B1._o(q, items, line, nudge, tag)


static func _pt(v: float, s: String, at := 0, lit := -1, extra := {}) -> Dictionary:
	return B1._pt(v, s, at, lit, extra)


## 穿在繩上的珠子
static func _bead(v: float, s: String, at: int, lit: int, extra := {}) -> Dictionary:
	var d := {"bead": true}
	d.merge(extra, true)
	return B1._pt(v, s, at, lit, d)


static func _nl(x: Array, pts: Array, extra := {}) -> Dictionary:
	return B1._nl(x, pts, extra)


static func _rope(a: float, b: float, ext := [], s := ["A", "B"]) -> Dictionary:
	return {"a": a, "b": b, "ext": ext, "s": s}


static func slots() -> Array:
	var out := _slots()
	for slot in out:
		slot["plain"] = true
		if String(slot.type) == "forge":
			slot["type_name"] = "逐步推導"
		SB.fix_roots(slot)
		slot["params"] = slot.get("params", [])
		for v in slot.get("variants", []):
			for st in v.get("steps", []):
				if String(st.get("kind", "")) == "fill":
					st["paren"] = true
	return out


## 拖珠子：滑桿 t 是珠子的位置，讀數顯示 \ol{AP}、\ol{PB}
static func _drag(a: int, b: int, m: int, n: int, p: int, start: float) -> Dictionary:
	return {"kind": "slide", "name": "拖拖看", "tag": T_DIV,
		"q": "拖珠子：\\ol{AP} : \\ol{PB} = %d : %d" % [m, n],
		"params": [{"n": "t", "min": a, "max": b, "step": 0.5, "v": start}], "lines": [],
		"eq": "P = {t}\n\\ol{AP} = {t - (%d)}，\\ol{PB} = {%d - t}" % [a, b], "goal": {"t": p},
		"line": "P = %s 時 \\ol{AP} = %d、\\ol{PB} = %d，%d : %d = %d : %d" % [_n(p), p - a, b - p, p - a, b - p, m, n],
		"nudge": "\\ol{AP} 要是 \\ol{PB} 的 \\frac{%d}{%d} 倍。" % [m, n]}


## 在數線上點出 C 可能在的兩個地方（\ol{AC} : \ol{BC} = m : n，m > n：C 離 B 比較近）
static func _tap_c(a: int, b: int, m: int, n: int, hits: Array) -> Dictionary:
	var mid := (a + b) / 2.0
	return {"kind": "ltap", "name": "在哪裡", "tag": T_EXT, "q": "點出 C 可能在的地方（兩個）",
		"item": 0, "snap": 0.5, "a": a, "b": b, "regions": [[mid, b], [b, 1e9]], "wrong": "\\ol{AC} {rel} \\ol{BC}",
		"hits": hits, "miss": a - 1,
		"nudge": "\\ol{AC} : \\ol{BC} = %d : %d，C 離 B 比較近。" % [m, n],
		"line": "C 在 \\ol{AB} 上（內分點）或 B 的右邊（外分點）"}


## 追趕：點出追上的地方（B 的右邊）
static func _tap_meet(a: int, b: int, hit: int) -> Dictionary:
	return {"kind": "ltap", "name": "在哪裡", "tag": T_APP, "q": "點出追上的地方", "item": 0, "snap": 0.5, "a": a, "b": b,
		"regions": [[b, 1e9]], "wrongs": [[-1e9, a, "往左了"], [a, b, "還沒追到 B"]], "wrong": "", "hits": [hit], "miss": (a + b) / 2.0,
		"nudge": "B 也在往右走。", "line": "P 在 B 的右邊：外分點"}


## 把 p、q、r 拖到繩上：吸附在「a 往 b 走 t」，t 是這些分數
const ROOT_SNAPS := [[-1.0 / 3.0, "−\\frac{1}{3}"], [-0.25, "−\\frac{1}{4}"], [0.25, "\\frac{1}{4}"], [1.0 / 3.0, "\\frac{1}{3}"],
	[0.5, "\\frac{1}{2}"], [2.0 / 3.0, "\\frac{2}{3}"], [0.75, "\\frac{3}{4}"], [1.25, "\\frac{5}{4}"], [4.0 / 3.0, "\\frac{4}{3}"]]


static func _drag_roots(a: float, b: float, goal: Dictionary, why: Dictionary, line: String) -> Dictionary:
	return {"kind": "ldrag", "name": "放珠子", "tag": T_DCMP, "q": "把 p、q、r 拖到繩上",
		"item": 0, "a": a, "b": b, "beads": [["p", "p"], ["q", "q"], ["r", "r"]], "goal": goal, "snaps": ROOT_SNAPS.duplicate(true),
		"why": why, "nudge": "權重大的那一端比較近，係數有負的就在外面。", "line": line}


## 加權平均：把 p、q、r 拖到數線上（a 在 0、c 在 1，吸附在 snaps 的比例）
static func _drag_ac(goal: Dictionary, snaps: Array, why: Dictionary, line: String) -> Dictionary:
	return {"kind": "ldrag", "name": "放珠子", "tag": T_DCMP, "q": "把 p、q、r 拖到數線上",
		"item": 0, "a": 0.0, "b": 1.0, "beads": [["p", "p"], ["q", "q"], ["r", "r"]], "goal": goal, "snaps": snaps,
		"why": why, "nudge": "c 的權重越大，越靠近 c。", "line": line}


static func _n(v: int) -> String:
	return str(v).replace("-", "−")


static func _slots() -> Array:
	return [
		# ======================= 第一章．內分與外分 =======================
		{"id": "bead", "chapter": 1, "type": "forge", "title": "繩上的珠子",
		 "story": "珠子停在哪裡，繩子就被分成什麼比？",
		 "insight": "內分點：\\ol{AP} : \\ol{PB} = m : n ⇒ P = \\frac{na + mb}{m + n}\n交叉乘：A 乘 n、B 乘 m。靠近誰，誰的權重大。",
		 "variants": [
			{"eq": "A(−3)、B(9)，P 在 \\ol{AB} 上，\\ol{AP} : \\ol{PB} = m : n\n內分點 P 的公式是哪一個？",
			 "field": [_nl([-5, 11], [_bead(1, "P", 0, 1, {"slide": "t", "wrong": [1, 5]})],
				{"rope": _rope(-3, 9), "weights": {"at": 2, "a": [-3, 2], "b": [9, 1]}})],
			 "steps": [
				_drag(-3, 9, 1, 2, 1, 5.0),
				_c("公式", "m = 1、n = 2，哪一個算出 1？",
					["\\frac{na + mb}{m + n}", "\\frac{ma + nb}{m + n}", "\\frac{a + b}{2}", "\\frac{mb − na}{m − n}"], 0,
					"\\frac{2 × (−3) + 1 × 9}{3} = 1。交叉乘：A 乘 n、B 乘 m，靠近 A，A 的權重就大。",
					"珠子靠近 A，A 的權重應該比較大。每個公式代代看。", "P = \\frac{na + mb}{m + n}：靠近誰，誰的權重大", T_DIV),
			 ]},
			{"eq": "A(−4)、B(11)，P 在 \\ol{AB} 上，\\ol{AP} : \\ol{PB} = m : n\n內分點 P 的公式是哪一個？",
			 "field": [_nl([-6, 13], [_bead(2, "P", 0, 1, {"slide": "t", "wrong": [1, 5]})],
				{"rope": _rope(-4, 11), "weights": {"at": 2, "a": [-4, 3], "b": [11, 2]}})],
			 "steps": [
				_drag(-4, 11, 2, 3, 2, 8.0),
				_c("公式", "m = 2、n = 3，哪一個算出 2？",
					["\\frac{na + mb}{m + n}", "\\frac{ma + nb}{m + n}", "\\frac{a + b}{2}", "\\frac{mb − na}{m − n}"], 0,
					"\\frac{3 × (−4) + 2 × 11}{5} = 2。交叉乘：A 乘 n、B 乘 m，靠近 A，A 的權重就大。",
					"珠子靠近 A，A 的權重應該比較大。每個公式代代看。", "P = \\frac{na + mb}{m + n}：靠近誰，誰的權重大", T_DIV),
			 ]},
		 ]},

		{"id": "two", "chapter": 1, "type": "forge", "title": "兩個位置",
		 "story": "只知道比，不知道珠子在繩上還是繩子外面。",
		 "insight": "\\ol{AC} : \\ol{BC} = m : n（m ≠ n）的 C 有兩個：\n內分點 \\frac{na + mb}{m + n}，外分點 \\frac{mb − na}{m − n}（在比較短的那一端外面）。",
		 "variants": [
			{"eq": "A(−2)、B(8)、\\ol{AC} : \\ol{BC} = 3 : 2\n求 C（所有可能）",
			 "field": [_nl([-4, 30], [_bead(4, "C_{1}", 2, 2), _bead(28, "C_{2}", 3, 3)], {"rope": _rope(-2, 8, [[28, 3]])})],
			 "steps": [
				_tap_c(-2, 8, 3, 2, [5, 20]),
				_f("內分點", "內分點：交叉乘", "C = \\frac{[0] × (−2) + [1] × 8}{5} = [2]", ["2", "3", "4"],
					"內分點 C = \\frac{2 × (−2) + 3 × 8}{5} = 4", "A 乘 B 那邊的比 2，B 乘 A 那邊的比 3。", T_DIV),
				_f("外分點", "外分點", "C = \\frac{[0] × 8 − [1] × (−2)}{3 − 2} = [2]", ["3", "2", "28"],
					"外分點 C = \\frac{3 × 8 − 2 × (−2)}{1} = 28", "m = 3、n = 2。", T_EXT),
			 ]},
			{"eq": "A(−5)、B(9)、3\\ol{AC} = 4\\ol{BC}\n求 C（所有可能）",
			 "field": [_nl([-7, 54], [_bead(3, "C_{1}", 3, 3), _bead(51, "C_{2}", 4, 4)], {"rope": _rope(-5, 9, [[51, 4]])})],
			 "steps": [
				_f("比", "寫成比", "\\ol{AC} : \\ol{BC} = [0] : [1]", ["4", "3"],
					"3\\ol{AC} = 4\\ol{BC} ⇒ \\ol{AC} : \\ol{BC} = 4 : 3", "比要反過來寫：3\\ol{AC} = 4\\ol{BC}，\\ol{AC} 比較長。", T_EXT, "prop"),
				_tap_c(-5, 9, 4, 3, [6, 30]),
				_f("內分點", "內分點：交叉乘", "C = \\frac{[0] × (−5) + [1] × 9}{7} = [2]", ["3", "4", "3"],
					"內分點 C = \\frac{3 × (−5) + 4 × 9}{7} = 3", "A 乘 B 那邊的比 3，B 乘 A 那邊的比 4。", T_DIV),
				_f("外分點", "外分點", "C = \\frac{[0] × 9 − [1] × (−5)}{4 − 3} = [2]", ["4", "3", "51"],
					"外分點 C = \\frac{4 × 9 − 3 × (−5)}{1} = 51", "m = 4、n = 3。", T_EXT),
			 ]},
		 ]},

		{"id": "map", "chapter": 1, "type": "forge", "title": "縮小畫在數線上",
		 "story": "三座風車在一直線上，縮小畫到數線上。",
		 "insight": "只知道兩段距離，三個點可能有不同的排法\n每一種排法都是一個分點：先決定誰在中間，再用分點公式。",
		 "variants": [
			{"eq": "直路上 \\ol{AB} = 6、\\ol{BC} = 2（公里）\n縮小畫到數線 A = 1、C = 5，求 B（所有可能）",
			 "field": [_nl([0, 8], [_pt(1, "A"), _pt(5, "C"), _pt(4, "B", 2, 2), _pt(7, "B", 3, 3)],
				{"road": {"pin": {"A": 1, "C": 5}, "cases": [{"at": 2, "km": {"A": 0, "B": 6, "C": 8}}, {"at": 3, "km": {"A": 0, "C": 4, "B": 6}}]}})],
			 "steps": [
				_c("誰在中間", "誰可能在中間？", ["B 或 C", "只有 B", "只有 C", "A、B、C 都可能"], 0,
					"B 在中間：\\ol{AC} = 6 + 2 = 8。C 在中間：\\ol{AC} = 6 − 2 = 4。A 在中間的話 \\ol{BC} = \\ol{BA} + \\ol{AC} 會比 6 長，不可能。",
					"A 在中間的話，\\ol{BC} 至少多長？", "B 在中間（\\ol{AC} = 8 公里）或 C 在中間（\\ol{AC} = 4 公里）", T_APP),
				_f("B 在中間", "B 把 \\ol{AC} 分成 6 : 2 = 3 : 1。", "B = \\frac{[0] × 1 + [1] × 5}{4} = [2]", ["1", "3", "4"],
					"B 在中間：B = \\frac{1 × 1 + 3 × 5}{4} = 4", "交叉乘：A 乘 1、C 乘 3。", T_APP),
				_f("C 在中間", "C 把 \\ol{AB} 分成 4 : 2 = 2 : 1，A 在 1。", "5 = \\frac{1 + [0] × B}{3}，B = [1]", ["2", "7"],
					"C 在中間：5 = \\frac{1 + 2B}{3} ⇒ B = 7", "交叉乘：A 乘 1、B 乘 2。", T_APP),
			 ]},
			{"eq": "直路上 \\ol{AB} = 4、\\ol{BC} = 1（公里）\n縮小畫到數線 A = 2、C = 7，求 B（所有可能）",
			 "field": [_nl([1, 10], [_pt(2, "A"), _pt(7, "C"), _pt(6, "B", 2, 2), _pt(26.0 / 3.0, "B", 3, 3)],
				{"road": {"pin": {"A": 2, "C": 7}, "cases": [{"at": 2, "km": {"A": 0, "B": 4, "C": 5}}, {"at": 3, "km": {"A": 0, "C": 3, "B": 4}}]}})],
			 "steps": [
				_c("誰在中間", "誰可能在中間？", ["B 或 C", "只有 B", "只有 C", "A、B、C 都可能"], 0,
					"B 在中間：\\ol{AC} = 4 + 1 = 5。C 在中間：\\ol{AC} = 4 − 1 = 3。A 在中間的話 \\ol{BC} 會比 4 長，不可能。",
					"A 在中間的話，\\ol{BC} 至少多長？", "B 在中間（\\ol{AC} = 5 公里）或 C 在中間（\\ol{AC} = 3 公里）", T_APP),
				_f("B 在中間", "B 把 \\ol{AC} 分成 4 : 1。", "B = \\frac{[0] × 2 + [1] × 7}{5} = [2]", ["1", "4", "6"],
					"B 在中間：B = \\frac{1 × 2 + 4 × 7}{5} = 6", "交叉乘：A 乘 1、C 乘 4。", T_APP),
				_f("C 在中間", "C 把 \\ol{AB} 分成 3 : 1，A 在 2。", "7 = \\frac{2 + [0] × B}{4}，B = [1]", ["3", "26/3"],
					"C 在中間：7 = \\frac{2 + 3B}{4} ⇒ B = \\frac{26}{3}", "交叉乘：A 乘 1、B 乘 3。", T_APP),
			 ]},
		 ]},

		{"id": "chase", "chapter": 1, "type": "forge", "title": "追趕的光點",
		 "story": "快的光點在哪裡追上慢的？",
		 "insight": "同時出發、同時到達：走的距離比 = 速度比\n追上的地方在兩個起點的外面，是外分點。",
		 "variants": [
			{"eq": "A(−3)、B(9) 同時往右走，A 的速度是 B 的 4 倍\nA 在哪裡追上 B？",
			 "field": [_nl([-5, 15], [_pt(13, "P", 3, 3)], {"run": {"a": -3, "b": 9, "meet": 13, "at": 3}, "segs": [[9, 15, 1, "gold"]]})],
			 "steps": [
				_tap_meet(-3, 9, 12),
				_f("距離比", "距離比 = 速度比", "\\ol{PA} : \\ol{PB} = [0] : [1]", ["4", "1"],
					"\\ol{PA} : \\ol{PB} = 4 : 1", "A 走的距離是 B 的幾倍？", T_APP, "prop"),
				_f("求 P", "外分點", "P = \\frac{[0] × 9 − [1] × (−3)}{4 − 1} = [2]", ["4", "1", "13"],
					"P = \\frac{4 × 9 − 1 × (−3)}{3} = 13", "m = 4、n = 1。", T_EXT),
			 ]},
			{"eq": "A(−4)、B(6) 同時往右走，A 的速度是 B 的 3 倍\nA 在哪裡追上 B？",
			 "field": [_nl([-6, 13], [_pt(11, "P", 3, 3)], {"run": {"a": -4, "b": 6, "meet": 11, "at": 3}, "segs": [[6, 13, 1, "gold"]]})],
			 "steps": [
				_tap_meet(-4, 6, 9),
				_f("距離比", "距離比 = 速度比", "\\ol{PA} : \\ol{PB} = [0] : [1]", ["3", "1"],
					"\\ol{PA} : \\ol{PB} = 3 : 1", "A 走的距離是 B 的幾倍？", T_APP, "prop"),
				_f("求 P", "外分點", "P = \\frac{[0] × 6 − [1] × (−4)}{3 − 1} = [2]", ["3", "1", "11"],
					"P = \\frac{3 × 6 − 1 × (−4)}{2} = 11", "m = 3、n = 1。", T_EXT),
			 ]},
		 ]},

		{"id": "speed1", "chapter": 1, "type": "speed", "title": "珠子速算", "time": 120.0,
		 "story": "一顆一顆珠子串上繩子！快速算出分點的位置。",
		 "insight": "內分點 \\frac{na + mb}{m + n}，外分點 \\frac{mb − na}{m − n}\n交叉乘：A 乘 n、B 乘 m。",
		 "variants": [{"gen": "bead", "count": 8}]},

		# ======================= 第二章．分點比大小 =======================
		{"id": "judge", "chapter": 2, "type": "forge", "title": "繩上有幾顆珠子",
		 "story": "滿足條件的珠子，可能不只一顆。",
		 "insight": "p|x − a| = q|x − b| ⇒ \\ol{PA} : \\ol{PB} = q : p（比要反過來）\nP 有兩個：內分點和外分點，都靠近比較短的那一端。",
		 "variants": [
			{"eq": "A(a)、B(b)、P(x)，a < b\n2|x − a| = 3|x − b|\nP 在哪裡？哪些一定成立？",
			 "field": [_nl([-2, 17], [_bead(3, "P", 2, 2), _bead(15, "P", 2, 2)], {"rope": _rope(0, 5, [[15, 2]]), "noticks": true})],
			 "steps": [
				_j("審判一", "\\ol{PA} : \\ol{PB} = 3 : 2", true, "2\\ol{PA} = 3\\ol{PB} ⇒ \\ol{PA} : \\ol{PB} = 3 : 2（比要反過來寫）。",
					"\\ol{PA} : \\ol{PB} = 3 : 2", T_DCMP),
				{"kind": "ltap", "name": "在哪裡", "tag": T_EXT, "q": "點出 P 可能在的地方", "item": 0, "snap": 0.5, "a": 0, "b": 5,
				 "regions": [[2.5, 5], [5, 1e9]], "wrong": "\\ol{PA} {rel} \\ol{PB}", "hits": [4, 11], "miss": -1,
				 "nudge": "\\ol{PA} : \\ol{PB} = 3 : 2，P 離 B 比較近。", "line": "P 在 \\ol{AB} 上靠近 B，或在 B 的右邊（不一定在 \\ol{AB} 上）"},
				_j("審判二", "5|x − a| = 3|a − b|", false, "只有內分點才對：\\ol{PA} = \\frac{3}{5}\\ol{AB}。外分點的 \\ol{PA} = 3\\ol{AB}。",
					"5|x − a| = 3|a − b| 只有內分點成立", T_DCMP),
			 ]},
			{"eq": "A(a)、B(b)、P(x)，a < b\n3|x − a| = |x − b|\nP 在哪裡？哪些一定成立？",
			 "insight": "p|x − a| = q|x − b| ⇒ \\ol{PA} : \\ol{PB} = q : p（比要反過來）\n3|x − a| = |x − b| ⇒ \\ol{PA} : \\ol{PB} = 1 : 3：兩個 P 都靠近 A。",
			 "field": [_nl([-6, 10], [_bead(2, "P", 2, 2), _bead(-4, "P", 2, 2)], {"rope": _rope(0, 8, [[-4, 2]]), "noticks": true})],
			 "steps": [
				_j("審判一", "\\ol{PA} : \\ol{PB} = 1 : 3", true, "3\\ol{PA} = \\ol{PB} ⇒ \\ol{PA} : \\ol{PB} = 1 : 3（比要反過來寫）。",
					"\\ol{PA} : \\ol{PB} = 1 : 3", T_DCMP),
				{"kind": "ltap", "name": "在哪裡", "tag": T_EXT, "q": "點出 P 可能在的地方", "item": 0, "snap": 0.5, "a": 0, "b": 8,
				 "regions": [[-1e9, 0], [0, 4]], "wrong": "\\ol{PA} {rel} \\ol{PB}", "hits": [-3, 2], "miss": 6,
				 "nudge": "\\ol{PA} : \\ol{PB} = 1 : 3，P 離 A 比較近。", "line": "P 在 \\ol{AB} 上靠近 A，或在 A 的左邊（不一定在 \\ol{AB} 上）"},
				_j("審判二", "4|x − a| = |a − b|", false, "只有內分點才對：\\ol{PA} = \\frac{1}{4}\\ol{AB}。外分點的 \\ol{PA} = \\frac{1}{2}\\ol{AB}。",
					"4|x − a| = |a − b| 只有內分點成立", T_DCMP),
			 ]},
		 ]},

		{"id": "weight", "chapter": 2, "type": "forge", "title": "加權平均的位置",
		 "story": "權重決定珠子在 a、c 之間的位置。",
		 "insight": "\\frac{ma + nc}{m + n} 在 a 往 c 走 \\frac{n}{m + n} 的地方\nc 的權重越大，越靠近 c。先把每個數都寫成 a、c 的分點再比。",
		 "variants": [
			{"eq": "a < b < c，|c − a| = 4|b − a|，由小到大排\np = \\frac{3a + 5c}{8}、q = \\frac{a + c}{2}、r = \\frac{a + 3b}{4}",
			 "field": [_nl([-0.1, 1.1], [_pt(0, "a"), _pt(1, "c"), _pt(0.25, "b", 1, 1),
				_pt(0.625, "p", 3, 3), _pt(0.5, "q", 3, 3), _pt(0.1875, "r", 3, 3)], {"noticks": true})],
			 "steps": [
				_f("b", "b 寫成 a、c 的分點", "b = \\frac{[0]a + c}{[1]}", ["3", "4"],
					"b − a = \\frac{c − a}{4} ⇒ b = \\frac{3a + c}{4}", "b = a + \\frac{1}{4}(c − a)。", T_DCMP),
				_f("r", "b 代進 r", "r = \\frac{a + 3b}{4} = \\frac{[0]a + [1]c}{16}", ["13", "3"],
					"3b = \\frac{9a + 3c}{4} ⇒ r = \\frac{a + 3b}{4} = \\frac{13a + 3c}{16}", "3b = \\frac{9a + 3c}{4}，a = \\frac{4a}{4}。", T_DCMP),
				_drag_ac({"p": 0.625, "q": 0.5, "r": 0.1875},
					[[0.1875, "\\frac{3}{16}"], [0.375, "\\frac{3}{8}"], [0.5, "\\frac{1}{2}"], [0.625, "\\frac{5}{8}"], [0.8125, "\\frac{13}{16}"]],
					{"p": "p = \\frac{3a + 5c}{8}：c 的權重占幾分之幾？", "q": "q 是中點。", "r": "r = \\frac{13a + 3c}{16}：c 的權重占幾分之幾？"},
					"c 的權重：r 是 \\frac{3}{16}、q 是 \\frac{1}{2}、p 是 \\frac{5}{8} ⇒ r < q < p"),
			 ]},
			{"eq": "a < b < c，|c − b| = 2|b − a|，由小到大排\np = \\frac{2a + 3c}{5}、q = \\frac{a + 2b}{3}、r = \\frac{b + c}{2}",
			 "field": [_nl([-0.1, 1.1], [_pt(0, "a"), _pt(1, "c"), _pt(1.0 / 3.0, "b", 1, 1),
				_pt(0.6, "p", 4, 4), _pt(2.0 / 9.0, "q", 4, 4), _pt(2.0 / 3.0, "r", 4, 4)], {"noticks": true})],
			 "steps": [
				_f("b", "b 寫成 a、c 的分點", "b = \\frac{[0]a + c}{[1]}", ["2", "3"],
					"b − a = \\frac{c − a}{3} ⇒ b = \\frac{2a + c}{3}", "b = a + \\frac{1}{3}(c − a)。", T_DCMP),
				_f("q", "b 代進 q", "q = \\frac{a + 2b}{3} = \\frac{[0]a + [1]c}{9}", ["7", "2"],
					"2b = \\frac{4a + 2c}{3} ⇒ q = \\frac{a + 2b}{3} = \\frac{7a + 2c}{9}", "2b = \\frac{4a + 2c}{3}，a = \\frac{3a}{3}。", T_DCMP),
				_f("r", "b 代進 r", "r = \\frac{b + c}{2} = \\frac{a + [0]c}{3}", ["2"],
					"b + c = \\frac{2a + 4c}{3} ⇒ r = \\frac{b + c}{2} = \\frac{a + 2c}{3}", "c = \\frac{3c}{3}。", T_DCMP),
				_drag_ac({"p": 0.6, "q": 2.0 / 9.0, "r": 2.0 / 3.0},
					[[2.0 / 9.0, "\\frac{2}{9}"], [0.4, "\\frac{2}{5}"], [0.6, "\\frac{3}{5}"], [2.0 / 3.0, "\\frac{2}{3}"], [7.0 / 9.0, "\\frac{7}{9}"]],
					{"p": "p = \\frac{2a + 3c}{5}：c 的權重占幾分之幾？", "q": "q = \\frac{7a + 2c}{9}：c 的權重占幾分之幾？", "r": "r = \\frac{a + 2c}{3}：c 的權重占幾分之幾？"},
					"c 的權重：q 是 \\frac{2}{9}、p 是 \\frac{3}{5}、r 是 \\frac{2}{3} ⇒ q < p < r"),
			 ]},
		 ]},

		{"id": "roots", "chapter": 2, "type": "forge", "title": "根號的分點",
		 "story": "兩根柱子是 √ 的數，不用算小數，看權重就知道珠子在哪裡。",
		 "insight": "把 √ 看成 a、b：\\frac{2a + b}{3} 是靠近 a 的三等分點\n係數有負的（\\frac{5b − a}{4}）就在外面：比 b 再往外走。",
		 "variants": [
			{"eq": "a = √3、b = √6\np = \\frac{2√3 + √6}{3}　q = \\frac{√3 + 3√6}{4}　r = \\frac{5√6 − √3}{4}\na、b、p、q、r 由小到大排",
			 "field": [_nl([1.4, 2.8], [_bead(1.9714, "p", 1, 1), _bead(2.2701, "q", 1, 1), _bead(2.6286, "r", 1, 1)],
				{"rope": _rope(1.7321, 2.4495, [[2.6286, 1]], ["a", "b"]), "noticks": true})],
			 "steps": [
				_drag_roots(1.7321, 2.4495, {"p": 1.0 / 3.0, "q": 0.75, "r": 1.25},
					{"p": "p = \\frac{2a + b}{3}：a 的權重比較大。", "q": "q = \\frac{a + 3b}{4}：b 的權重占幾分之幾？", "r": "r = \\frac{5b − a}{4}：把 r 寫成 b + 什麼。"},
					"p、q、r 在 a 往 b 走 \\frac{1}{3}、\\frac{3}{4}、\\frac{5}{4} 的地方 ⇒ a < p < q < b < r"),
			 ]},
			{"eq": "a = √2、b = √5\np = \\frac{3√2 + √5}{4}　q = \\frac{√2 + 2√5}{3}　r = \\frac{4√2 − √5}{3}\na、b、p、q、r 由小到大排",
			 "insight": "把 √ 看成 a、b：\\frac{3a + b}{4} 在 a 往 b 走 \\frac{1}{4} 的地方\n係數有負的（\\frac{4a − b}{3}）就在外面：比 a 再往外走。",
			 "field": [_nl([1.0, 2.65], [_bead(1.6197, "p", 1, 1), _bead(1.9621, "q", 1, 1), _bead(1.1402, "r", 1, 1)],
				{"rope": _rope(1.4142, 2.2361, [[1.1402, 1]], ["a", "b"]), "noticks": true})],
			 "steps": [
				_drag_roots(1.4142, 2.2361, {"p": 0.25, "q": 2.0 / 3.0, "r": -1.0 / 3.0},
					{"p": "p = \\frac{3a + b}{4}：b 的權重占幾分之幾？", "q": "q = \\frac{a + 2b}{3}：b 的權重比較大。", "r": "r = \\frac{4a − b}{3}：把 r 寫成 a − 什麼。"},
					"p、q、r 在 a 往 b 走 \\frac{1}{4}、\\frac{2}{3}、−\\frac{1}{3} 的地方 ⇒ r < a < p < q < b"),
			 ]},
		 ]},

		{"id": "speed2", "chapter": 2, "type": "speed", "title": "分點速算", "time": 120.0,
		 "story": "珠子落在哪裡？看權重就知道！",
		 "insight": "a < b：b 的權重比較大就靠近 b\n係數有負的就在外面。",
		 "variants": [{"gen": "where", "count": 8}]},
	]
