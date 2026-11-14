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
		"q": "拖動珠子 P，讓 \\ol{AP} : \\ol{PB} = %d : %d。" % [m, n],
		"params": [{"n": "t", "min": a, "max": b, "step": 0.5, "v": start}], "lines": [],
		"eq": "P = {t}\n\\ol{AP} = {t - (%d)}，\\ol{PB} = {%d - t}" % [a, b], "goal": {"t": p},
		"line": "P = %s 時 \\ol{AP} = %d、\\ol{PB} = %d，%d : %d = %d : %d" % [_n(p), p - a, b - p, p - a, b - p, m, n],
		"nudge": "\\ol{AP} 要是 \\ol{PB} 的 \\frac{%d}{%d} 倍。" % [m, n]}


static func _n(v: int) -> String:
	return str(v).replace("-", "−")


static func _slots() -> Array:
	return [
		# ======================= 第一章．內分與外分 =======================
		{"id": "bead", "chapter": 1, "type": "forge", "title": "繩上的珠子",
		 "story": "兩根柱子之間拉一條繩，珠子穿在上面。珠子停在哪裡，繩子就被分成什麼比？",
		 "insight": "內分點：\\ol{AP} : \\ol{PB} = m : n ⇒ P = \\frac{na + mb}{m + n}\n交叉乘：A 乘 n、B 乘 m。靠近誰，誰的權重大。",
		 "variants": [
			{"eq": "A(−3)、B(9)，P 在 \\ol{AB} 上，\\ol{AP} : \\ol{PB} = m : n\n內分點 P 的公式是哪一個？",
			 "field": [_nl([-5, 11], [_bead(1, "P", 0, 1, {"slide": "t", "wrong": [1, 5]})],
				{"rope": _rope(-3, 9), "weights": {"at": 2, "a": [-3, 2], "b": [9, 1]}})],
			 "steps": [
				_drag(-3, 9, 1, 2, 1, 5.0),
				_c("公式", "代 a = −3、b = 9、m = 1、n = 2，哪一個公式算出來剛好是珠子的位置 1？",
					["\\frac{na + mb}{m + n}", "\\frac{ma + nb}{m + n}", "\\frac{a + b}{2}", "\\frac{mb − na}{m − n}"], 0,
					"\\frac{2 × (−3) + 1 × 9}{3} = 1。交叉乘：A 乘 n、B 乘 m，靠近 A，A 的權重就大。",
					"珠子靠近 A，A 的權重應該比較大。每個公式代代看。", "P = \\frac{na + mb}{m + n}：靠近誰，誰的權重大", T_DIV),
			 ]},
			{"eq": "A(−4)、B(11)，P 在 \\ol{AB} 上，\\ol{AP} : \\ol{PB} = m : n\n內分點 P 的公式是哪一個？",
			 "field": [_nl([-6, 13], [_bead(2, "P", 0, 1, {"slide": "t", "wrong": [1, 5]})],
				{"rope": _rope(-4, 11), "weights": {"at": 2, "a": [-4, 3], "b": [11, 2]}})],
			 "steps": [
				_drag(-4, 11, 2, 3, 2, 8.0),
				_c("公式", "代 a = −4、b = 11、m = 2、n = 3，哪一個公式算出來剛好是珠子的位置 2？",
					["\\frac{na + mb}{m + n}", "\\frac{ma + nb}{m + n}", "\\frac{a + b}{2}", "\\frac{mb − na}{m − n}"], 0,
					"\\frac{3 × (−4) + 2 × 11}{5} = 2。交叉乘：A 乘 n、B 乘 m，靠近 A，A 的權重就大。",
					"珠子靠近 A，A 的權重應該比較大。每個公式代代看。", "P = \\frac{na + mb}{m + n}：靠近誰，誰的權重大", T_DIV),
			 ]},
		 ]},

		{"id": "two", "chapter": 1, "type": "forge", "title": "兩個位置",
		 "story": "只知道比，不知道珠子在繩上還是繩子外面。",
		 "insight": "\\ol{AC} : \\ol{BC} = m : n（m ≠ n）的 C 有兩個：\n內分點 \\frac{na + mb}{m + n}，外分點 \\frac{mb − na}{m − n}（在比較短的那一端外面）。",
		 "variants": [
			{"eq": "A(−2)、B(8)，C 在數線上，\\ol{AC} : \\ol{BC} = 3 : 2\n求 C（所有可能）",
			 "field": [_nl([-4, 30], [_bead(4, "C_{1}", 2, 2), _bead(28, "C_{2}", 3, 3)], {"rope": _rope(-2, 8, [[28, 3]])})],
			 "steps": [
				_c("在哪裡", "\\ol{AC} : \\ol{BC} = 3 : 2，C 可能在哪裡？",
					["\\ol{AB} 上一個、B 的右邊一個", "\\ol{AB} 上一個、A 的左邊一個", "只有 \\ol{AB} 上一個", "A 的左邊、B 的右邊各一個"], 0,
					"內分點在 \\ol{AB} 上。外分點在外面，而且靠近比較短的那一端：\\ol{BC} 比較短，所以在 B 的右邊。",
					"C 離 A 遠、離 B 近。在 A 的左邊的話，會離 A 比較近。", "C 在 \\ol{AB} 上（內分點）或 B 的右邊（外分點）", T_EXT),
				_f("內分點", "\\ol{AC} : \\ol{CB} = 3 : 2，交叉乘權重。", "C = \\frac{[0] × (−2) + [1] × 8}{5} = [2]", ["2", "3", "4"],
					"內分點 C = \\frac{2 × (−2) + 3 × 8}{5} = 4", "A 乘 B 那邊的比 2，B 乘 A 那邊的比 3。", T_DIV),
				_f("外分點", "C 在 B 的右邊：外分點公式 \\frac{mb − na}{m − n}。", "C = \\frac{[0] × 8 − [1] × (−2)}{3 − 2} = [2]", ["3", "2", "28"],
					"外分點 C = \\frac{3 × 8 − 2 × (−2)}{1} = 28", "m = 3、n = 2。", T_EXT),
			 ]},
			{"eq": "A(−5)、B(9)，C 在數線上，3\\ol{AC} = 4\\ol{BC}\n求 C（所有可能）",
			 "field": [_nl([-7, 54], [_bead(3, "C_{1}", 3, 3), _bead(51, "C_{2}", 4, 4)], {"rope": _rope(-5, 9, [[51, 4]])})],
			 "steps": [
				_f("比", "3\\ol{AC} = 4\\ol{BC}，寫成比。", "\\ol{AC} : \\ol{BC} = [0] : [1]", ["4", "3"],
					"3\\ol{AC} = 4\\ol{BC} ⇒ \\ol{AC} : \\ol{BC} = 4 : 3", "比要反過來寫：3\\ol{AC} = 4\\ol{BC}，\\ol{AC} 比較長。", T_EXT, "prop"),
				_c("在哪裡", "\\ol{AC} : \\ol{BC} = 4 : 3，C 可能在哪裡？",
					["\\ol{AB} 上一個、B 的右邊一個", "\\ol{AB} 上一個、A 的左邊一個", "只有 \\ol{AB} 上一個", "A 的左邊、B 的右邊各一個"], 0,
					"內分點在 \\ol{AB} 上。外分點在外面，而且靠近比較短的那一端：\\ol{BC} 比較短，所以在 B 的右邊。",
					"C 離 A 遠、離 B 近。在 A 的左邊的話，會離 A 比較近。", "C 在 \\ol{AB} 上（內分點）或 B 的右邊（外分點）", T_EXT),
				_f("內分點", "\\ol{AC} : \\ol{CB} = 4 : 3，交叉乘權重。", "C = \\frac{[0] × (−5) + [1] × 9}{7} = [2]", ["3", "4", "3"],
					"內分點 C = \\frac{3 × (−5) + 4 × 9}{7} = 3", "A 乘 B 那邊的比 3，B 乘 A 那邊的比 4。", T_DIV),
				_f("外分點", "C 在 B 的右邊：外分點公式 \\frac{mb − na}{m − n}。", "C = \\frac{[0] × 9 − [1] × (−5)}{4 − 3} = [2]", ["4", "3", "51"],
					"外分點 C = \\frac{4 × 9 − 3 × (−5)}{1} = 51", "m = 4、n = 3。", T_EXT),
			 ]},
		 ]},

		{"id": "map", "chapter": 1, "type": "forge", "title": "縮小畫在數線上",
		 "story": "三座風車在同一條直路上。把它們按比例縮小，畫到數線柵欄上。",
		 "insight": "只知道兩段距離，三個點可能有不同的排法\n每一種排法都是一個分點：先決定誰在中間，再用分點公式。",
		 "variants": [
			{"eq": "A、B、C 三座風車在同一條直路上，\\ol{AB} = 6 公里、\\ol{BC} = 2 公里\n按比例畫在數線上：A 在 1、C 在 5。B 在哪裡（所有可能）？",
			 "field": [_nl([0, 8], [_pt(1, "A"), _pt(5, "C"), _pt(4, "B", 2, 2), _pt(7, "B", 3, 3)],
				{"road": {"pin": {"A": 1, "C": 5}, "cases": [{"at": 2, "km": {"A": 0, "B": 6, "C": 8}}, {"at": 3, "km": {"A": 0, "C": 4, "B": 6}}]}})],
			 "steps": [
				_c("誰在中間", "\\ol{AB} = 6、\\ol{BC} = 2。三座風車排成一列，誰可能在中間？", ["B 或 C", "只有 B", "只有 C", "A、B、C 都可能"], 0,
					"B 在中間：\\ol{AC} = 6 + 2 = 8。C 在中間：\\ol{AC} = 6 − 2 = 4。A 在中間的話 \\ol{BC} = \\ol{BA} + \\ol{AC} 會比 6 長，不可能。",
					"A 在中間的話，\\ol{BC} 至少多長？", "B 在中間（\\ol{AC} = 8 公里）或 C 在中間（\\ol{AC} = 4 公里）", T_APP),
				_f("B 在中間", "B 把 \\ol{AC} 分成 6 : 2 = 3 : 1。", "B = \\frac{[0] × 1 + [1] × 5}{4} = [2]", ["1", "3", "4"],
					"B 在中間：B = \\frac{1 × 1 + 3 × 5}{4} = 4", "交叉乘：A 乘 1、C 乘 3。", T_APP),
				_f("C 在中間", "C 把 \\ol{AB} 分成 4 : 2 = 2 : 1，A 在 1。", "5 = \\frac{1 + [0] × B}{3}，B = [1]", ["2", "7"],
					"C 在中間：5 = \\frac{1 + 2B}{3} ⇒ B = 7", "交叉乘：A 乘 1、B 乘 2。", T_APP),
			 ]},
			{"eq": "A、B、C 三座風車在同一條直路上，\\ol{AB} = 4 公里、\\ol{BC} = 1 公里\n按比例畫在數線上：A 在 2、C 在 7。B 在哪裡（所有可能）？",
			 "field": [_nl([1, 10], [_pt(2, "A"), _pt(7, "C"), _pt(6, "B", 2, 2), _pt(26.0 / 3.0, "B", 3, 3)],
				{"road": {"pin": {"A": 2, "C": 7}, "cases": [{"at": 2, "km": {"A": 0, "B": 4, "C": 5}}, {"at": 3, "km": {"A": 0, "C": 3, "B": 4}}]}})],
			 "steps": [
				_c("誰在中間", "\\ol{AB} = 4、\\ol{BC} = 1。三座風車排成一列，誰可能在中間？", ["B 或 C", "只有 B", "只有 C", "A、B、C 都可能"], 0,
					"B 在中間：\\ol{AC} = 4 + 1 = 5。C 在中間：\\ol{AC} = 4 − 1 = 3。A 在中間的話 \\ol{BC} 會比 4 長，不可能。",
					"A 在中間的話，\\ol{BC} 至少多長？", "B 在中間（\\ol{AC} = 5 公里）或 C 在中間（\\ol{AC} = 3 公里）", T_APP),
				_f("B 在中間", "B 把 \\ol{AC} 分成 4 : 1。", "B = \\frac{[0] × 2 + [1] × 7}{5} = [2]", ["1", "4", "6"],
					"B 在中間：B = \\frac{1 × 2 + 4 × 7}{5} = 6", "交叉乘：A 乘 1、C 乘 4。", T_APP),
				_f("C 在中間", "C 把 \\ol{AB} 分成 3 : 1，A 在 2。", "7 = \\frac{2 + [0] × B}{4}，B = [1]", ["3", "26/3"],
					"C 在中間：7 = \\frac{2 + 3B}{4} ⇒ B = \\frac{26}{3}", "交叉乘：A 乘 1、B 乘 3。", T_APP),
			 ]},
		 ]},

		{"id": "chase", "chapter": 1, "type": "forge", "title": "追趕的光點",
		 "story": "兩個光點沿著數線柵欄往右跑，快的那一個在哪裡追上慢的？",
		 "insight": "同時出發、同時到達：走的距離比 = 速度比\n追上的地方在兩個起點的外面，是外分點。",
		 "variants": [
			{"eq": "A 在 −3、B 在 9，兩個光點同時往右走\nA 的速度是 B 的 4 倍，A 在哪裡追上 B？",
			 "field": [_nl([-5, 15], [_pt(13, "P", 3, 3)], {"run": {"a": -3, "b": 9, "meet": 13, "at": 3}, "segs": [[9, 15, 1, "gold"]]})],
			 "steps": [
				_c("在哪裡", "追上的地方 P 在哪裡？", ["B 的右邊", "A、B 之間", "A 的左邊"], 0,
					"兩個都往右走，A 要走過 B 原本的位置才追得上，所以 P 在 B 的右邊。", "B 也在往右走。", "P 在 B 的右邊：外分點", T_APP),
				_f("距離比", "同樣的時間，走的距離和速度成正比。", "\\ol{PA} : \\ol{PB} = [0] : [1]", ["4", "1"],
					"\\ol{PA} : \\ol{PB} = 4 : 1", "A 走的距離是 B 的幾倍？", T_APP, "prop"),
				_f("求 P", "P 是外分點，\\frac{mb − na}{m − n}。", "P = \\frac{[0] × 9 − [1] × (−3)}{4 − 1} = [2]", ["4", "1", "13"],
					"P = \\frac{4 × 9 − 1 × (−3)}{3} = 13", "m = 4、n = 1。", T_EXT),
			 ]},
			{"eq": "A 在 −4、B 在 6，兩個光點同時往右走\nA 的速度是 B 的 3 倍，A 在哪裡追上 B？",
			 "field": [_nl([-6, 13], [_pt(11, "P", 3, 3)], {"run": {"a": -4, "b": 6, "meet": 11, "at": 3}, "segs": [[6, 13, 1, "gold"]]})],
			 "steps": [
				_c("在哪裡", "追上的地方 P 在哪裡？", ["B 的右邊", "A、B 之間", "A 的左邊"], 0,
					"兩個都往右走，A 要走過 B 原本的位置才追得上，所以 P 在 B 的右邊。", "B 也在往右走。", "P 在 B 的右邊：外分點", T_APP),
				_f("距離比", "同樣的時間，走的距離和速度成正比。", "\\ol{PA} : \\ol{PB} = [0] : [1]", ["3", "1"],
					"\\ol{PA} : \\ol{PB} = 3 : 1", "A 走的距離是 B 的幾倍？", T_APP, "prop"),
				_f("求 P", "P 是外分點，\\frac{mb − na}{m − n}。", "P = \\frac{[0] × 6 − [1] × (−4)}{3 − 1} = [2]", ["3", "1", "11"],
					"P = \\frac{3 × 6 − 1 × (−4)}{2} = 11", "m = 3、n = 1。", T_EXT),
			 ]},
		 ]},

		{"id": "speed1", "chapter": 1, "type": "speed", "title": "珠子速算", "time": 120.0,
		 "story": "一顆一顆珠子串上繩子！快速算出分點的位置。",
		 "insight": "內分點 \\frac{na + mb}{m + n}，外分點 \\frac{mb − na}{m − n}\n交叉乘：A 乘 n、B 乘 m。",
		 "variants": [{"gen": "bead", "count": 8}]},

		# ======================= 第二章．分點比大小 =======================
		{"id": "judge", "chapter": 2, "type": "forge", "title": "繩上有幾顆珠子",
		 "story": "繩子上、繩子外，滿足條件的珠子可能不只一顆。",
		 "insight": "p|x − a| = q|x − b| ⇒ \\ol{PA} : \\ol{PB} = q : p（比要反過來）\nP 有兩個：內分點和外分點，都靠近比較短的那一端。",
		 "variants": [
			{"eq": "A(a)、B(b)、P(x)，a < b\n2|x − a| = 3|x − b|，下面哪些一定成立？",
			 "field": [_nl([-2, 17], [_bead(3, "P", 1, 1), _bead(15, "P", 3, 3)], {"rope": _rope(0, 5, [[15, 3]]), "noticks": true})],
			 "steps": [
				_j("審判一", "\\ol{PA} : \\ol{PB} = 3 : 2", true, "2\\ol{PA} = 3\\ol{PB} ⇒ \\ol{PA} : \\ol{PB} = 3 : 2（比要反過來寫）。",
					"\\ol{PA} : \\ol{PB} = 3 : 2", T_DCMP),
				_j("審判二", "P 在 \\ol{AB} 上", false, "還有外分點：P 也可以在 B 的右邊。", "P 不一定在 \\ol{AB} 上", T_EXT),
				_c("反例", "哪一組 (a, b, x) 的 P 在 \\ol{AB} 外面？", ["(0, 5, 15)", "(0, 5, 3)", "(0, 10, 6)", "(2, 7, 5)"], 0,
					"a = 0、b = 5、x = 15：2 × 15 = 3 × 10，成立，而且 15 在 \\ol{AB} 外面。其他三組的 x 都在 a、b 之間。",
					"先檢查每一組有沒有滿足 2|x − a| = 3|x − b|，再看 x 在不在 a、b 之間。", "(0, 5, 15)：P 在 B 的右邊", T_EXT),
				_j("審判三", "x > \\frac{a + b}{2}", true, "\\ol{PA} > \\ol{PB}，P 比較靠近 B，內分點、外分點都在中點的右邊。",
					"P 比較靠近 B ⇒ x > \\frac{a + b}{2}", T_DCMP),
				_j("審判四", "5|x − a| = 3|a − b|", false, "只有內分點才對：\\ol{PA} = \\frac{3}{5}\\ol{AB}。外分點的 \\ol{PA} = 3\\ol{AB}。",
					"5|x − a| = 3|a − b| 只有內分點成立", T_DCMP),
			 ]},
			{"eq": "A(a)、B(b)、P(x)，a < b\n3|x − a| = |x − b|，下面哪些一定成立？",
			 "field": [_nl([-6, 10], [_bead(2, "P", 1, 1), _bead(-4, "P", 3, 3)], {"rope": _rope(0, 8, [[-4, 3]]), "noticks": true})],
			 "steps": [
				_j("審判一", "\\ol{PA} : \\ol{PB} = 1 : 3", true, "3\\ol{PA} = \\ol{PB} ⇒ \\ol{PA} : \\ol{PB} = 1 : 3（比要反過來寫）。",
					"\\ol{PA} : \\ol{PB} = 1 : 3", T_DCMP),
				_j("審判二", "P 在 \\ol{AB} 上", false, "還有外分點：P 也可以在 A 的左邊。", "P 不一定在 \\ol{AB} 上", T_EXT),
				_c("反例", "哪一組 (a, b, x) 的 P 在 \\ol{AB} 外面？", ["(0, 8, −4)", "(0, 8, 2)", "(0, 4, 1)", "(4, 8, 5)"], 0,
					"a = 0、b = 8、x = −4：3 × 4 = 12、|−4 − 8| = 12，成立，而且 −4 在 \\ol{AB} 外面。其他三組的 x 都在 a、b 之間。",
					"先檢查每一組有沒有滿足 3|x − a| = |x − b|，再看 x 在不在 a、b 之間。", "(0, 8, −4)：P 在 A 的左邊", T_EXT),
				_j("審判三", "x < \\frac{a + b}{2}", true, "\\ol{PA} < \\ol{PB}，P 比較靠近 A，內分點、外分點都在中點的左邊。",
					"P 比較靠近 A ⇒ x < \\frac{a + b}{2}", T_DCMP),
				_j("審判四", "x > a", false, "外分點在 A 的左邊，x < a。例如 (0, 8, −4)。", "x > a 不一定", T_DCMP),
			 ]},
		 ]},

		{"id": "weight", "chapter": 2, "type": "forge", "title": "加權平均的位置",
		 "story": "a、c 兩根柱子之間有好幾顆珠子，權重決定它們的位置。",
		 "insight": "\\frac{ma + nc}{m + n} 在 a 往 c 走 \\frac{n}{m + n} 的地方\nc 的權重越大，越靠近 c。先把每個數都寫成 a、c 的分點再比。",
		 "variants": [
			{"eq": "a < b < c，|c − a| = 4|b − a|\np = \\frac{3a + 5c}{8}、q = \\frac{a + c}{2}、r = \\frac{a + 3b}{4}，由小到大排",
			 "field": [_nl([-0.1, 1.1], [_pt(0, "a"), _pt(1, "c"), _pt(0.25, "b", 1, 1),
				_pt(0.625, "p", 3, 3), _pt(0.5, "q", 3, 3), _pt(0.1875, "r", 3, 3)], {"noticks": true})],
			 "steps": [
				_f("b", "|c − a| = 4|b − a|：b 在 a 往 c 走 \\frac{1}{4} 的地方。寫成 a、c 的分點。", "b = \\frac{[0]a + c}{[1]}", ["3", "4"],
					"b − a = \\frac{c − a}{4} ⇒ b = \\frac{3a + c}{4}", "b = a + \\frac{1}{4}(c − a)。", T_DCMP),
				_f("r", "把 b 代進 r，也寫成 a、c 的分點。", "r = \\frac{a + 3b}{4} = \\frac{[0]a + [1]c}{16}", ["13", "3"],
					"3b = \\frac{9a + 3c}{4} ⇒ r = \\frac{a + 3b}{4} = \\frac{13a + 3c}{16}", "3b = \\frac{9a + 3c}{4}，a = \\frac{4a}{4}。", T_DCMP),
				_o("c 的權重越大，越靠近 c。p、q、r 由小到大排。",
					[["p", "\\frac{3a + 5c}{8}", 0.625], ["q", "\\frac{a + c}{2}", 0.5], ["r", "\\frac{13a + 3c}{16}", 0.1875]],
					"c 的權重：r 是 \\frac{3}{16}、q 是 \\frac{1}{2}、p 是 \\frac{5}{8} ⇒ r < q < p", "比 c 的係數占多少：\\frac{5}{8}、\\frac{1}{2}、\\frac{3}{16}。", T_DCMP),
			 ]},
			{"eq": "a < b < c，|c − b| = 2|b − a|\np = \\frac{2a + 3c}{5}、q = \\frac{a + 2b}{3}、r = \\frac{b + c}{2}，由小到大排",
			 "field": [_nl([-0.1, 1.1], [_pt(0, "a"), _pt(1, "c"), _pt(1.0 / 3.0, "b", 1, 1),
				_pt(0.6, "p", 4, 4), _pt(2.0 / 9.0, "q", 4, 4), _pt(2.0 / 3.0, "r", 4, 4)], {"noticks": true})],
			 "steps": [
				_f("b", "|c − b| = 2|b − a|：b 在 a 往 c 走 \\frac{1}{3} 的地方。寫成 a、c 的分點。", "b = \\frac{[0]a + c}{[1]}", ["2", "3"],
					"b − a = \\frac{c − a}{3} ⇒ b = \\frac{2a + c}{3}", "b = a + \\frac{1}{3}(c − a)。", T_DCMP),
				_f("q", "把 b 代進 q。", "q = \\frac{a + 2b}{3} = \\frac{[0]a + [1]c}{9}", ["7", "2"],
					"2b = \\frac{4a + 2c}{3} ⇒ q = \\frac{a + 2b}{3} = \\frac{7a + 2c}{9}", "2b = \\frac{4a + 2c}{3}，a = \\frac{3a}{3}。", T_DCMP),
				_f("r", "把 b 代進 r。", "r = \\frac{b + c}{2} = \\frac{a + [0]c}{3}", ["2"],
					"b + c = \\frac{2a + 4c}{3} ⇒ r = \\frac{b + c}{2} = \\frac{a + 2c}{3}", "c = \\frac{3c}{3}。", T_DCMP),
				_o("c 的權重越大，越靠近 c。p、q、r 由小到大排。",
					[["p", "\\frac{2a + 3c}{5}", 0.6], ["q", "\\frac{7a + 2c}{9}", 2.0 / 9.0], ["r", "\\frac{a + 2c}{3}", 2.0 / 3.0]],
					"c 的權重：q 是 \\frac{2}{9}、p 是 \\frac{3}{5}、r 是 \\frac{2}{3} ⇒ q < p < r", "比 c 的係數占多少：\\frac{3}{5}、\\frac{2}{9}、\\frac{2}{3}。", T_DCMP),
			 ]},
		 ]},

		{"id": "roots", "chapter": 2, "type": "forge", "title": "根號的分點",
		 "story": "兩根柱子是 √ 的數，不用算小數，看權重就知道珠子在哪裡。",
		 "insight": "把 √ 看成 a、b：\\frac{2a + b}{3} 是靠近 a 的三等分點\n係數有負的（\\frac{5b − a}{4}）就在外面：比 b 再往外走。",
		 "variants": [
			{"eq": "a = √3、b = √6\np = \\frac{2√3 + √6}{3}、q = \\frac{√3 + 3√6}{4}、r = \\frac{5√6 − √3}{4}，連同 a、b 由小到大排",
			 "field": [_nl([1.55, 2.75], [_bead(1.9714, "p", 1, 4), _bead(2.2701, "q", 2, 4), _bead(2.6286, "r", 3, 4)],
				{"rope": _rope(1.7321, 2.4495, [[2.6286, 3]], ["a", "b"]), "noticks": true})],
			 "steps": [
				_c("p", "p = \\frac{2a + b}{3}，在哪裡？", ["\\ol{ab} 上，靠近 a 的三等分點", "\\ol{ab} 上，靠近 b 的三等分點", "a、b 的中點", "b 的右邊"], 0,
					"a 的權重 2、b 的權重 1，靠近 a：從 a 往 b 走 \\frac{1}{3}。", "權重大的那一端比較近。", "p 在 a 往 b 走 \\frac{1}{3} 的地方", T_DCMP),
				_c("q", "q = \\frac{a + 3b}{4}，在哪裡？", ["\\ol{ab} 上，從 a 往 b 走 \\frac{3}{4}", "\\ol{ab} 上，從 a 往 b 走 \\frac{1}{4}", "a 的左邊", "b 的右邊"], 0,
					"b 的權重 3，占 \\frac{3}{4}：從 a 往 b 走 \\frac{3}{4}。", "b 的權重占全部的幾分之幾？", "q 在 a 往 b 走 \\frac{3}{4} 的地方", T_DCMP),
				_c("r", "r = \\frac{5b − a}{4}，a 的係數是負的，r 在哪裡？", ["b 的右邊", "a 的左邊", "\\ol{ab} 上"], 0,
					"r = b + \\frac{b − a}{4}：比 b 再往右走 \\frac{1}{4} 段。", "把 r 寫成 b + 什麼。", "r = b + \\frac{1}{4}(b − a)，在 b 的右邊", T_EXT),
				_o("a、b、p、q、r 由小到大排。",
					[["a", "√3", 1.7321], ["b", "√6", 2.4495], ["p", "\\frac{2√3 + √6}{3}", 1.9714], ["q", "\\frac{√3 + 3√6}{4}", 2.2701], ["r", "\\frac{5√6 − √3}{4}", 2.6286]],
					"a < p < q < b < r", "照剛剛找到的位置排。", T_DCMP),
			 ]},
			{"eq": "a = √2、b = √5\np = \\frac{3√2 + √5}{4}、q = \\frac{√2 + 2√5}{3}、r = \\frac{4√2 − √5}{3}，連同 a、b 由小到大排",
			 "field": [_nl([1.0, 2.35], [_bead(1.6197, "p", 1, 4), _bead(1.9621, "q", 2, 4), _bead(1.1402, "r", 3, 4)],
				{"rope": _rope(1.4142, 2.2361, [[1.1402, 3]], ["a", "b"]), "noticks": true})],
			 "steps": [
				_c("p", "p = \\frac{3a + b}{4}，在哪裡？", ["\\ol{ab} 上，從 a 往 b 走 \\frac{1}{4}", "\\ol{ab} 上，從 a 往 b 走 \\frac{3}{4}", "a、b 的中點", "a 的左邊"], 0,
					"b 的權重 1，占 \\frac{1}{4}：從 a 往 b 走 \\frac{1}{4}。", "b 的權重占全部的幾分之幾？", "p 在 a 往 b 走 \\frac{1}{4} 的地方", T_DCMP),
				_c("q", "q = \\frac{a + 2b}{3}，在哪裡？", ["\\ol{ab} 上，靠近 b 的三等分點", "\\ol{ab} 上，靠近 a 的三等分點", "a 的左邊", "b 的右邊"], 0,
					"b 的權重 2，靠近 b：從 a 往 b 走 \\frac{2}{3}。", "權重大的那一端比較近。", "q 在 a 往 b 走 \\frac{2}{3} 的地方", T_DCMP),
				_c("r", "r = \\frac{4a − b}{3}，b 的係數是負的，r 在哪裡？", ["a 的左邊", "b 的右邊", "\\ol{ab} 上"], 0,
					"r = a − \\frac{b − a}{3}：比 a 再往左走 \\frac{1}{3} 段。", "把 r 寫成 a − 什麼。", "r = a − \\frac{1}{3}(b − a)，在 a 的左邊", T_EXT),
				_o("a、b、p、q、r 由小到大排。",
					[["a", "√2", 1.4142], ["b", "√5", 2.2361], ["p", "\\frac{3√2 + √5}{4}", 1.6197], ["q", "\\frac{√2 + 2√5}{3}", 1.9621], ["r", "\\frac{4√2 − √5}{3}", 1.1402]],
					"r < a < p < q < b", "照剛剛找到的位置排。", T_DCMP),
			 ]},
		 ]},

		{"id": "speed2", "chapter": 2, "type": "speed", "title": "分點速算", "time": 120.0,
		 "story": "珠子落在哪裡？看權重就知道！",
		 "insight": "a < b：b 的權重比較大就靠近 b\n係數有負的就在外面。",
		 "variants": [{"gen": "where", "count": 8}]},
	]
