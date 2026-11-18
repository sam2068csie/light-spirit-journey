extends RefCounted
## 數與式 第四大關「圍籬牧場」題庫（對應講義重點四：算幾不等式）
## 設計稿：docs/num_r4_design.md。題目的數字都用程式驗算過（tools/num/verify_r4.py）。
##
## 旅程（引擎見 num_level.gd、line_level.gd）：
##   forge  一步一步推導：slide（拖圍籬的角、拖半圓上的點）、fill、choice
##   speed  速算：gen = "fix"（給和求積、給積求和，按鈕）、"recip"（ax + \frac{b}{x} 的最小值，按鈕）
## 第一章先動手：拖到正方形（等腰）時面積最大、草長滿，再寫出不等式。第二章只用填空（使用者 2026/11/15：不畫曲線）。
## 拖圍籬時讀數只顯示乘積或和，不顯示 a、b（使用者 2026/11/15），最後一步自己從正方形推回 a、b。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/num/num1_bank.gd")

const T_AM := "num_amgm"           # 算幾不等式與等號
const T_FIX := "num_amgmfix"       # 給和求積、給積求和
const T_FORM := "num_amgmform"     # 湊出定值（乘開、拆項）
const T_SIGN := "num_amgmsign"     # 正數才能用


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return SB.fill(name, q, template, answers, line, nudge, tag, mode)


static func _j(name: String, statement: String, ok: bool, why: String, line: String, tag: String) -> Dictionary:
	return B1._j(name, statement, ok, why, line, tag)


## 拖滑桿：t 從 lo 到 hi，拖到 goal 才算對。readout 是右邊的讀數（{…} 裡是算式）
static func _drag(name: String, q: String, lo: float, hi: float, stp: float, start: float, goal: float, lines: Array,
		readout: String, line: String, nudge: String, tag: String) -> Dictionary:
	return {"kind": "slide", "name": name, "q": q, "params": [{"n": "t", "min": lo, "max": hi, "step": stp, "v": start}],
		"lines": lines, "eq": readout, "goal": {"t": goal}, "keep": true, "line": line, "nudge": nudge, "tag": tag}


## 長方形圍籬：左下角在 (x0, y0)，寬、高是算式（含 t）
static func _rect(w: String, h: String, c := "gold", x0 := "0", y0 := "0") -> Array:
	var x1 := "%s + %s" % [x0, w]
	var y1 := "%s + %s" % [y0, h]
	return [{"k": "seg", "a": [x0, y0], "b": [x1, y0], "c": c}, {"k": "seg", "a": [x1, y0], "b": [x1, y1], "c": c},
		{"k": "seg", "a": [x1, y1], "b": [x0, y1], "c": c}, {"k": "seg", "a": [x0, y1], "b": [x0, y0], "c": c},
		{"k": "dot", "p": [x1, y1], "c": c}]


## 拖完之後長出來的草（正方形）
static func _grass(x0: float, y0: float, x1: float, y1: float, at: int) -> Dictionary:
	return {"k": "poly", "pts": [[x0, y0], [x1, y0], [x1, y1], [x0, y1]], "c": "lime", "fill": "lime", "alpha": 0.3, "at": at}


static func _arc(o: Array, r: float, a0: float, a1: float, c := "dim") -> Dictionary:
	return {"k": "arc", "o": o, "r": r, "a0": a0, "a1": a1, "c": c}


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


## 半圓：直徑 s，拖分點 P，半弦 √ab
static func _semi_variant(s: int) -> Dictionary:
	var r := s / 2.0
	var expr := "sqrt(t * (%d - t))" % s
	return {"eq": "a、b > 0，a + b = %d\n\\frac{a + b}{2} 和 √ab 哪一個大？" % s,
		"plane": B1._plane([-1, s + 1], [-1, r + 1.2], [_arc([r, 0], r, 0, 180), {"k": "seg", "a": [0, 0], "b": [s, 0], "c": "dim"},
			{"k": "dot", "p": [0, 0], "s": "A", "off": [-14, 16]}, {"k": "dot", "p": [s, 0], "s": "B", "off": [6, 16]},
			{"k": "seg", "a": [r, 0], "b": [r, r], "c": "cyan", "dash": true}]),
		"steps": [
			_drag("拖拖看", "拖 P，讓 √ab 最長", 0.5, s - 0.5, 0.5, 1.5, r,
				[{"k": "dot", "p": ["t", "0"], "s": "P", "c": "gold"}, {"k": "seg", "a": ["t", "0"], "b": ["t", expr], "c": "gold"},
				 {"k": "dot", "p": ["t", expr], "c": "gold"}],
				"a = {t}、b = {%d - t}\n√ab ≈ {%s}" % [s, expr], "P 在圓心時 a = b = %s，√ab = %s = 半徑" % [_num(r), _num(r)],
				"半弦什麼時候碰到半徑？", T_AM),
			_c("比大小", "\\frac{a + b}{2} 和 √ab", ["\\frac{a + b}{2} ≥ √ab", "\\frac{a + b}{2} ≤ √ab", "要看 a、b"], 0,
				"√ab 是半弦，\\frac{a + b}{2} 是半徑，半弦不會比半徑長。a = b 時一樣長。", "半弦和半徑，哪一個比較長？",
				"\\frac{a + b}{2} ≥ √ab，等號在 a = b", T_AM),
		]}


static func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else str(v)


static func _slots() -> Array:
	return [
		# ======================= 第一章．算幾不等式與等號 =======================
		{"id": "semi", "chapter": 1, "type": "forge", "title": "半圓裡的兩個平均",
		 "story": "直徑分成 a、b，半弦是 √ab。",
		 "insight": "a、b > 0：\\frac{a + b}{2} ≥ √ab（算幾不等式）\n半弦不會比半徑長，a = b 時一樣長：等號在 a = b。",
		 "variants": [_semi_variant(8), _semi_variant(10)]},

		{"id": "perim", "chapter": 1, "type": "forge", "title": "周長固定的圍籬",
		 "story": "圍籬的長、寬加起來固定，怎麼圍面積最大？",
		 "insight": "和固定：兩個數相等時，乘積最大\n3a × 4b ≤ (\\frac{3a + 4b}{2})^{2}，等號在 3a = 4b。",
		 "variants": [
			{"eq": "a、b > 0，3a + 4b = 24\n求 ab 的最大值和這時的 (a, b)",
			 "plane": B1._plane([-1, 25], [-1, 25], [_grass(0, 0, 12, 12, 1)]),
			 "steps": [
				_drag("拖圍籬", "拖圍籬的角，讓面積最大", 2, 22, 1, 6, 12, _rect("t", "24 - t"),
					"3a × 4b = {t * (24 - t)}", "正方形：3a = 4b = 12", "長方形什麼時候面積最大？", T_FIX),
				_f("最大值", "3a = 4b 時最大", "3a × 4b ≤ [0]^{2} ⇒ ab ≤ [1]", ["12", "12"],
					"3a × 4b ≤ 12^{2} = 144 ⇒ ab ≤ 12", "3a × 4b = 12ab。", T_FIX),
				_f("(a, b)", "這時的 (a, b)", "(a, b) = ([0], [1])", ["4", "3"], "3a = 4b = 12 ⇒ (a, b) = (4, 3)",
					"3a = 12、4b = 12。", T_FIX),
			 ]},
			{"eq": "a、b > 0，a + 4b = 8\n求 ab 的最大值和這時的 (a, b)",
			 "insight": "和固定：兩個數相等時，乘積最大\na × 4b ≤ (\\frac{a + 4b}{2})^{2} = 16，等號在 a = 4b。",
			 "plane": B1._plane([-0.5, 8.5], [-0.5, 8.5], [_grass(0, 0, 4, 4, 1)]),
			 "steps": [
				_drag("拖圍籬", "拖圍籬的角，讓面積最大", 0.5, 7.5, 0.5, 1.5, 4, _rect("t", "8 - t"),
					"a × 4b = {t * (8 - t)}", "正方形：a = 4b = 4", "長方形什麼時候面積最大？", T_FIX),
				_f("最大值", "a = 4b 時最大", "a × 4b ≤ [0]^{2} ⇒ ab ≤ [1]", ["4", "4"],
					"a × 4b ≤ 4^{2} = 16 ⇒ ab ≤ 4", "a × 4b = 4ab。", T_FIX),
				_f("(a, b)", "這時的 (a, b)", "(a, b) = ([0], [1])", ["4", "1"], "a = 4b = 4 ⇒ (a, b) = (4, 1)",
					"a = 4、4b = 4。", T_FIX),
			 ]},
		 ]},

		{"id": "area", "chapter": 1, "type": "forge", "title": "面積固定的圍籬",
		 "story": "面積固定，怎麼圍用的木條最少？",
		 "insight": "積固定：兩個數相等時，和最小\nx + 2y ≥ 2√(x · 2y)，等號在 x = 2y。",
		 "variants": [
			{"eq": "x、y > 0，xy = 8\n求 x + 2y 的最小值",
			 "plane": B1._plane([-0.5, 17], [-0.5, 17], [_grass(0, 0, 4, 4, 1)]),
			 "steps": [
				_drag("拖圍籬", "拖圍籬的角，讓 x + 2y 最小", 1, 16, 1, 8, 4, _rect("t", "16 / t"),
					"x × 2y = 16\nx + 2y = {t + 16 / t}", "正方形：x = 2y = 4", "長方形什麼時候最省木條？", T_FIX),
				_f("最小值", "x = 2y 時最小", "x + 2y ≥ 2√([0]) = [1]", ["16", "8"],
					"x + 2y ≥ 2√(x · 2y) = 2√16 = 8（x = 4、y = 2）", "x · 2y = 2xy = 16。", T_FIX),
			 ]},
			{"eq": "x、y > 0，xy = 6\n求 2x + 3y 的最小值",
			 "insight": "積固定：兩個數相等時，和最小\n2x + 3y ≥ 2√(2x · 3y) = 12，等號在 2x = 3y。",
			 "plane": B1._plane([-1, 19], [-1, 19], [_grass(0, 0, 6, 6, 1)]),
			 "steps": [
				_drag("拖圍籬", "拖圍籬的角，讓 2x + 3y 最小", 2, 18, 1, 12, 6, _rect("t", "36 / t"),
					"2x × 3y = 36\n2x + 3y = {t + 36 / t}", "正方形：2x = 3y = 6", "長方形什麼時候最省木條？", T_FIX),
				_f("最小值", "2x = 3y 時最小", "2x + 3y ≥ 2√([0]) = [1]", ["36", "12"],
					"2x + 3y ≥ 2√(2x · 3y) = 2√36 = 12（x = 3、y = 2）", "2x · 3y = 6xy = 36。", T_FIX),
			 ]},
		 ]},

		{"id": "sqsum", "chapter": 1, "type": "forge", "title": "平方和固定",
		 "story": "P 在圓弧上走，長方形什麼時候最大？",
		 "insight": "u^{2} + v^{2} ≥ 2uv：平方和固定，乘積在 u = v 時最大\n9a^{2} + b^{2} = (3a)^{2} + b^{2} ≥ 2 · 3a · b。",
		 "variants": [
			{"eq": "a、b > 0，9a^{2} + b^{2} = 18\n求 ab 的最大值和這時的 (a, b)",
			 "plane": B1._plane([-0.5, 5], [-0.5, 5], [_arc([0, 0], sqrt(18.0), 0, 90), _grass(0, 0, 3, 3, 1)]),
			 "steps": [
				_drag("拖拖看", "拖 P，讓長方形最大", 0.5, 4, 0.5, 1, 3, _rect("t", "sqrt(18 - t * t)"),
					"P(3a, b)\n3a × b ≈ {t * sqrt(18 - t * t)}", "正方形：3a = b = 3", "P 在圓弧的哪裡，長方形最大？", T_FIX),
				_f("最大值", "18 = (3a)^{2} + b^{2} ≥ 2 · 3a · b", "6ab ≤ 18 ⇒ ab ≤ [0]", ["3"],
					"18 ≥ 6ab ⇒ ab ≤ 3", "2 · 3a · b = 6ab。", T_FIX),
				_f("(a, b)", "這時的 (a, b)", "(a, b) = ([0], [1])", ["1", "3"], "3a = b = 3 ⇒ (a, b) = (1, 3)",
					"3a = 3、b = 3。", T_FIX),
			 ]},
			{"eq": "a、b > 0，a^{2} + 4b^{2} = 8\n求 ab 的最大值和這時的 (a, b)",
			 "insight": "u^{2} + v^{2} ≥ 2uv：平方和固定，乘積在 u = v 時最大\na^{2} + 4b^{2} = a^{2} + (2b)^{2} ≥ 2 · a · 2b。",
			 "plane": B1._plane([-0.5, 3.5], [-0.5, 3.5], [_arc([0, 0], sqrt(8.0), 0, 90), _grass(0, 0, 2, 2, 1)]),
			 "steps": [
				_drag("拖拖看", "拖 P，讓長方形最大", 0.5, 2.5, 0.5, 1, 2, _rect("t", "sqrt(8 - t * t)"),
					"P(a, 2b)\na × 2b ≈ {t * sqrt(8 - t * t)}", "正方形：a = 2b = 2", "P 在圓弧的哪裡，長方形最大？", T_FIX),
				_f("最大值", "8 = a^{2} + (2b)^{2} ≥ 2 · a · 2b", "4ab ≤ 8 ⇒ ab ≤ [0]", ["2"],
					"8 ≥ 4ab ⇒ ab ≤ 2", "2 · a · 2b = 4ab。", T_FIX),
				_f("(a, b)", "這時的 (a, b)", "(a, b) = ([0], [1])", ["2", "1"], "a = 2b = 2 ⇒ (a, b) = (2, 1)",
					"a = 2、2b = 2。", T_FIX),
			 ]},
		 ]},

		{"id": "expand", "chapter": 1, "type": "forge", "title": "先湊出定值",
		 "story": "兩個括號的和不是定值，先湊一湊。",
		 "insight": "(a + 2)(b + 1) 的和不是定值：湊成 (a + 2) + 2(b + 1) = a + 2b + 4 = 10\n再用 (a + 2) · 2(b + 1) ≤ (\\frac{10}{2})^{2}。",
		 "variants": [
			{"eq": "a、b > 0，a + 2b = 6\n求 (a + 2)(b + 1) 的最大值",
			 "steps": [
				_f("湊定值", "湊出定值", "(a + 2) + 2(b + 1) = [0]", ["10"], "(a + 2) + 2(b + 1) = a + 2b + 4 = 10",
					"a + 2b = 6，再加 4。", T_FORM),
				_f("乘積", "和是 10，乘積最大？", "(a + 2) · 2(b + 1) ≤ [0]", ["25"], "(a + 2) · 2(b + 1) ≤ 5^{2} = 25",
					"(\\frac{10}{2})^{2}。", T_FORM),
				_f("最大值", "除以 2", "(a + 2)(b + 1) ≤ [0]", ["25/2"], "(a + 2)(b + 1) ≤ \\frac{25}{2}（a = 3、b = \\frac{3}{2}）",
					"25 除以 2，寫成分數。", T_FORM),
			 ]},
			{"eq": "a、b > 0，2a + b = 8\n求 (a + 1)(b + 2) 的最大值",
			 "insight": "(a + 1)(b + 2) 的和不是定值：湊成 2(a + 1) + (b + 2) = 2a + b + 4 = 12\n再用 2(a + 1) · (b + 2) ≤ (\\frac{12}{2})^{2}。",
			 "steps": [
				_f("湊定值", "湊出定值", "2(a + 1) + (b + 2) = [0]", ["12"], "2(a + 1) + (b + 2) = 2a + b + 4 = 12",
					"2a + b = 8，再加 4。", T_FORM),
				_f("乘積", "和是 12，乘積最大？", "2(a + 1) · (b + 2) ≤ [0]", ["36"], "2(a + 1) · (b + 2) ≤ 6^{2} = 36",
					"(\\frac{12}{2})^{2}。", T_FORM),
				_f("最大值", "除以 2", "(a + 1)(b + 2) ≤ [0]", ["18"], "(a + 1)(b + 2) ≤ 18（a = 2、b = 4）",
					"36 除以 2。", T_FORM),
			 ]},
		 ]},

		{"id": "path", "chapter": 1, "type": "forge", "title": "步道最省",
		 "story": "草地面積固定，四周鋪步道。",
		 "insight": "步道面積 = (x + 6)(y + 4) − xy = 4x + 6y + 24\n4x · 6y = 24xy 是定值：4x = 6y 時步道最小。",
		 "variants": [
			{"eq": "草地 x × y = 150，步道上下寬 2、左右寬 3\nx、y 多少時步道最小？",
			 "plane": B1._plane([-1, 37], [-1, 35], [
				{"k": "poly", "pts": [[0, 0], [16, 0], [16, 19], [0, 19]], "c": "dim", "fill": "dim", "alpha": 0.15, "until": 2},
				{"k": "poly", "pts": [[3, 2], [13, 2], [13, 17], [3, 17]], "c": "lime", "fill": "lime", "alpha": 0.25, "until": 2},
				# 拖完：步道（外框）和草地 15 × 10 留在圖上
				{"k": "poly", "pts": [[0, 0], [21, 0], [21, 14], [0, 14]], "c": "dim", "fill": "dim", "alpha": 0.15, "at": 3},
				_grass(3, 2, 18, 12, 3)]),
			 "steps": [
				_f("步道", "步道面積", "(x + 6)(y + 4) − xy = [0]x + [1]y + [2]", ["4", "6", "24"],
					"步道面積 = 4x + 6y + 24", "展開 (x + 6)(y + 4)，xy 消掉。", T_FIX),
				_f("算幾", "4x · 6y = 3600", "4x + 6y ≥ 2√([0]) = [1]", ["3600", "120"],
					"4x + 6y ≥ 2√3600 = 120 ⇒ 步道 ≥ 144", "4x · 6y = 24 × 150。", T_FIX),
				_drag("拖草地", "拖草地的角，讓步道最小", 5, 30, 1, 25, 15,
					_rect("t + 6", "150 / t + 4", "dim") + _rect("t", "150 / t", "lime", "3", "2"),
					"4x = {4 * t}、6y = {900 / t}\n步道 = {4 * t + 900 / t + 24}", "4x = 6y = 60 ⇒ 草地 15 × 10，步道 144",
					"4x 和 6y 什麼時候一樣？", T_FIX),
			 ]},
			{"eq": "草地 x × y = 96，步道上下寬 3、左右寬 2\nx、y 多少時步道最小？",
			 "insight": "步道面積 = (x + 4)(y + 6) − xy = 6x + 4y + 24\n6x · 4y = 24xy 是定值：6x = 4y 時步道最小。",
			 "plane": B1._plane([-1, 29], [-1, 31], [
				{"k": "poly", "pts": [[0, 0], [16, 0], [16, 14], [0, 14]], "c": "dim", "fill": "dim", "alpha": 0.15, "until": 2},
				{"k": "poly", "pts": [[2, 3], [14, 3], [14, 11], [2, 11]], "c": "lime", "fill": "lime", "alpha": 0.25, "until": 2},
				{"k": "poly", "pts": [[0, 0], [12, 0], [12, 18], [0, 18]], "c": "dim", "fill": "dim", "alpha": 0.15, "at": 3},
				_grass(2, 3, 10, 15, 3)]),
			 "steps": [
				_f("步道", "步道面積", "(x + 4)(y + 6) − xy = [0]x + [1]y + [2]", ["6", "4", "24"],
					"步道面積 = 6x + 4y + 24", "展開 (x + 4)(y + 6)，xy 消掉。", T_FIX),
				_f("算幾", "6x · 4y = 2304", "6x + 4y ≥ 2√([0]) = [1]", ["2304", "96"],
					"6x + 4y ≥ 2√2304 = 96 ⇒ 步道 ≥ 120", "6x · 4y = 24 × 96，2304 = 48^{2}。", T_FIX),
				_drag("拖草地", "拖草地的角，讓步道最小", 4, 24, 1, 16, 8,
					_rect("t + 4", "96 / t + 6", "dim") + _rect("t", "96 / t", "lime", "2", "3"),
					"6x = {6 * t}、4y = {384 / t}\n步道 = {6 * t + 384 / t + 24}", "6x = 4y = 48 ⇒ 草地 8 × 12，步道 120",
					"6x 和 4y 什麼時候一樣？", T_FIX),
			 ]},
		 ]},

		# 兩種題型（使用者 2026/11/15）：斜邊固定的直角三角形、等腰直角三角形裡的水池
		{"id": "tri", "chapter": 1, "type": "forge", "title": "三角形裡的最大面積",
		 "story": "三角形裡，什麼時候面積最大？",
		 "insight": "直角三角形：a^{2} + b^{2} = 斜邊^{2} ≥ 2ab，等腰時面積最大\n水池：w + 2h 是定值（兩邊的小三角形也是等腰直角），w = 2h 時最大。",
		 "variants": [
			_right_tri(6), _right_tri(10), _pool(16), _pool(12),
		 ]},

		{"id": "speed1", "chapter": 1, "type": "speed", "title": "圍籬速算", "time": 120.0,
		 "story": "一格一格的牧場長滿草！",
		 "insight": "和固定：乘積最大是 (\\frac{和}{2})^{2}\n積固定：和最小是 2√積。",
		 "variants": [{"gen": "fix", "count": 8}]},

		# ======================= 第二章．湊出能用的形式（只用填空） =======================
		{"id": "recip", "chapter": 2, "type": "forge", "title": "倒數型",
		 "story": "x 和 \\frac{9}{x} 乘起來是定值。",
		 "insight": "x > 0：x + \\frac{k}{x} ≥ 2√k，等號在 x = \\frac{k}{x}（x = √k）。",
		 "variants": [
			{"eq": "x > 0，求 x + \\frac{9}{x} + 2 的最小值",
			 "steps": [
				_f("算幾", "x · \\frac{9}{x} = 9", "x + \\frac{9}{x} ≥ 2√([0]) = [1]", ["9", "6"], "x + \\frac{9}{x} ≥ 2√9 = 6",
					"x 和 \\frac{9}{x} 乘起來是 9。", T_FORM),
				_f("最小值", "再加 2", "最小值 [0]，x = [1]", ["8", "3"], "最小值 6 + 2 = 8，x = \\frac{9}{x} ⇒ x = 3",
					"等號在 x = \\frac{9}{x}。", T_FORM),
			 ]},
			{"eq": "x > 0，求 4x + \\frac{1}{x} − 1 的最小值",
			 "steps": [
				_f("算幾", "4x · \\frac{1}{x} = 4", "4x + \\frac{1}{x} ≥ 2√([0]) = [1]", ["4", "4"], "4x + \\frac{1}{x} ≥ 2√4 = 4",
					"4x 和 \\frac{1}{x} 乘起來是 4。", T_FORM),
				_f("最小值", "再減 1", "最小值 [0]，x = [1]", ["3", "1/2"], "最小值 4 − 1 = 3，4x = \\frac{1}{x} ⇒ x = \\frac{1}{2}",
					"等號在 4x = \\frac{1}{x}：x^{2} = \\frac{1}{4}。", T_FORM),
			 ]},
		 ]},

		{"id": "frac", "chapter": 2, "type": "forge", "title": "分式型",
		 "story": "分子配方，拆成 t + \\frac{k}{t}。",
		 "insight": "\\frac{x^{2} + 2x + 5}{x + 1} = \\frac{(x + 1)^{2} + 4}{x + 1} = (x + 1) + \\frac{4}{x + 1}\n令 t = x + 1 > 0，再用算幾。",
		 "variants": [
			{"eq": "x > −1，求 \\frac{x^{2} + 2x + 5}{x + 1} 的最小值",
			 "steps": [
				_f("拆", "分子配方再拆開", "(x + 1) + \\frac{[0]}{x + 1}", ["4"], "\\frac{x^{2} + 2x + 5}{x + 1} = (x + 1) + \\frac{4}{x + 1}",
					"x^{2} + 2x + 5 = (x + 1)^{2} + 4。", T_FORM),
				_f("算幾", "x + 1 > 0", "(x + 1) + \\frac{4}{x + 1} ≥ 2√([0]) = [1]", ["4", "4"], "≥ 2√4 = 4",
					"兩項乘起來是 4。", T_FORM),
				_f("x", "等號成立時", "x = [0]", ["1"], "x + 1 = \\frac{4}{x + 1} ⇒ x + 1 = 2 ⇒ x = 1",
					"(x + 1)^{2} = 4。", T_FORM),
			 ]},
			{"eq": "x > 1，求 \\frac{x^{2} − 2x + 10}{x − 1} 的最小值",
			 "insight": "\\frac{x^{2} − 2x + 10}{x − 1} = \\frac{(x − 1)^{2} + 9}{x − 1} = (x − 1) + \\frac{9}{x − 1}\n令 t = x − 1 > 0，再用算幾。",
			 "steps": [
				_f("拆", "分子配方再拆開", "(x − 1) + \\frac{[0]}{x − 1}", ["9"], "\\frac{x^{2} − 2x + 10}{x − 1} = (x − 1) + \\frac{9}{x − 1}",
					"x^{2} − 2x + 10 = (x − 1)^{2} + 9。", T_FORM),
				_f("算幾", "x − 1 > 0", "(x − 1) + \\frac{9}{x − 1} ≥ 2√([0]) = [1]", ["9", "6"], "≥ 2√9 = 6",
					"兩項乘起來是 9。", T_FORM),
				_f("x", "等號成立時", "x = [0]", ["4"], "x − 1 = \\frac{9}{x − 1} ⇒ x − 1 = 3 ⇒ x = 4",
					"(x − 1)^{2} = 9。", T_FORM),
			 ]},
		 ]},

		{"id": "root", "chapter": 2, "type": "forge", "title": "根號型",
		 "story": "分母是根號，分子也拆成根號的平方。",
		 "insight": "\\frac{x + 5}{√(x − 4)} = \\frac{(x − 4) + 9}{√(x − 4)} = √(x − 4) + \\frac{9}{√(x − 4)}\n令 t = √(x − 4) > 0：t + \\frac{9}{t} ≥ 6。",
		 "variants": [
			{"eq": "x > 4，求 \\frac{x + 5}{√(x − 4)} 的最小值和這時的 x",
			 "steps": [
				_f("拆", "x + 5 = (x − 4) + 9", "√(x − 4) + \\frac{[0]}{√(x − 4)}", ["9"], "\\frac{x + 5}{√(x − 4)} = √(x − 4) + \\frac{9}{√(x − 4)}",
					"\\frac{x − 4}{√(x − 4)} = √(x − 4)。", T_FORM),
				_f("算幾", "兩項乘起來是定值", "≥ 2√([0]) = [1]", ["9", "6"], "≥ 2√9 = 6", "√(x − 4) × \\frac{9}{√(x − 4)} = 9。", T_FORM),
				_f("x", "等號成立時", "x − 4 = [0]，x = [1]", ["9", "13"], "√(x − 4) = 3 ⇒ x − 4 = 9 ⇒ x = 13",
					"√(x − 4) = \\frac{9}{√(x − 4)}。", T_FORM),
			 ]},
			{"eq": "x > −5，求 \\frac{x + 21}{√(x + 5)} 的最小值和這時的 x",
			 "insight": "\\frac{x + 21}{√(x + 5)} = \\frac{(x + 5) + 16}{√(x + 5)} = √(x + 5) + \\frac{16}{√(x + 5)}\n令 t = √(x + 5) > 0：t + \\frac{16}{t} ≥ 8。",
			 "steps": [
				_f("拆", "x + 21 = (x + 5) + 16", "√(x + 5) + \\frac{[0]}{√(x + 5)}", ["16"], "\\frac{x + 21}{√(x + 5)} = √(x + 5) + \\frac{16}{√(x + 5)}",
					"\\frac{x + 5}{√(x + 5)} = √(x + 5)。", T_FORM),
				_f("算幾", "兩項乘起來是定值", "≥ 2√([0]) = [1]", ["16", "8"], "≥ 2√16 = 8", "√(x + 5) × \\frac{16}{√(x + 5)} = 16。", T_FORM),
				_f("x", "等號成立時", "x + 5 = [0]，x = [1]", ["16", "11"], "√(x + 5) = 4 ⇒ x + 5 = 16 ⇒ x = 11",
					"√(x + 5) = \\frac{16}{√(x + 5)}。", T_FORM),
			 ]},
		 ]},

		{"id": "sign", "chapter": 2, "type": "forge", "title": "正數才能用",
		 "story": "算幾不等式只能用在正數。",
		 "insight": "t < 0 時不能直接用 t + \\frac{k}{t} ≥ 2√k\n先提出負號：t + \\frac{k}{t} = −[(−t) + \\frac{k}{−t}] ≤ −2√k。",
		 "variants": [
			{"eq": "y = x + \\frac{4}{x − 1}\nx > 1 時的最小值、x < 1 時的最大值",
			 "steps": [
				_f("拆", "湊出 x − 1", "y = (x − 1) + \\frac{4}{x − 1} + [0]", ["1"], "y = (x − 1) + \\frac{4}{x − 1} + 1",
					"x = (x − 1) + 1。", T_FORM),
				_f("x > 1", "x − 1 > 0", "最小值 [0]，x = [1]", ["5", "3"], "x > 1：y ≥ 4 + 1 = 5，x − 1 = 2 ⇒ x = 3",
					"(x − 1) + \\frac{4}{x − 1} ≥ 2√4。", T_SIGN),
				_j("審判", "x < 1 時 (x − 1) + \\frac{4}{x − 1} ≥ 4", false,
					"x < 1 時 x − 1 是負的，兩項都是負的，加起來不會 ≥ 4。例如 x = 0：−1 − 4 = −5。",
					"x < 1 時不能直接用算幾", T_SIGN),
				_f("提負號", "x − 1 < 0：提出負號", "(x − 1) + \\frac{4}{x − 1} ≤ [0]", ["-4"],
					"(x − 1) + \\frac{4}{x − 1} = −[(1 − x) + \\frac{4}{1 − x}] ≤ −4",
					"(1 − x) + \\frac{4}{1 − x} ≥ 4，前面再加負號。", T_SIGN),
				_f("x < 1", "再加 1", "最大值 [0]，x = [1]", ["-3", "-1"], "x < 1：y ≤ −4 + 1 = −3，1 − x = 2 ⇒ x = −1",
					"等號在 1 − x = \\frac{4}{1 − x}。", T_SIGN),
			 ]},
			{"eq": "y = x + \\frac{9}{x + 2}\nx > −2 時的最小值、x < −2 時的最大值",
			 "steps": [
				_f("拆", "湊出 x + 2", "y = (x + 2) + \\frac{9}{x + 2} − [0]", ["2"], "y = (x + 2) + \\frac{9}{x + 2} − 2",
					"x = (x + 2) − 2。", T_FORM),
				_f("x > −2", "x + 2 > 0", "最小值 [0]，x = [1]", ["4", "1"], "x > −2：y ≥ 6 − 2 = 4，x + 2 = 3 ⇒ x = 1",
					"(x + 2) + \\frac{9}{x + 2} ≥ 2√9。", T_SIGN),
				_j("審判", "x < −2 時 (x + 2) + \\frac{9}{x + 2} ≥ 6", false,
					"x < −2 時 x + 2 是負的，兩項都是負的，加起來不會 ≥ 6。例如 x = −3：−1 − 9 = −10。",
					"x < −2 時不能直接用算幾", T_SIGN),
				_f("提負號", "x + 2 < 0：提出負號", "(x + 2) + \\frac{9}{x + 2} ≤ [0]", ["-6"],
					"(x + 2) + \\frac{9}{x + 2} = −[−(x + 2) + \\frac{9}{−(x + 2)}] ≤ −6",
					"−(x + 2) + \\frac{9}{−(x + 2)} ≥ 6，前面再加負號。", T_SIGN),
				_f("x < −2", "再減 2", "最大值 [0]，x = [1]", ["-8", "-5"], "x < −2：y ≤ −6 − 2 = −8，x + 2 = −3 ⇒ x = −5",
					"等號在 −(x + 2) = 3。", T_SIGN),
			 ]},
		 ]},

		{"id": "both", "chapter": 2, "type": "forge", "title": "兩個等號一起成立",
		 "story": "兩組加起來剛好等於右邊。",
		 "insight": "x + \\frac{4}{x} ≥ 4、4y + \\frac{1}{y} ≥ 4，加起來 ≥ 8\n題目說剛好等於 8：兩個等號都要成立。",
		 "variants": [
			{"eq": "x、y > 0，x + 4y + \\frac{4}{x} + \\frac{1}{y} = 8\n求 (x, y)",
			 "steps": [
				_f("x 那組", "x · \\frac{4}{x} = 4", "x + \\frac{4}{x} ≥ [0]", ["4"], "x + \\frac{4}{x} ≥ 2√4 = 4", "2√4。", T_AM),
				_f("y 那組", "4y · \\frac{1}{y} = 4", "4y + \\frac{1}{y} ≥ [0]", ["4"], "4y + \\frac{1}{y} ≥ 2√4 = 4", "2√4。", T_AM),
				_f("(x, y)", "兩個等號都成立", "(x, y) = ([0], [1])", ["2", "1/2"],
					"4 + 4 = 8：x = \\frac{4}{x}、4y = \\frac{1}{y} ⇒ (x, y) = (2, \\frac{1}{2})", "x^{2} = 4、4y^{2} = 1。", T_AM),
			 ]},
			{"eq": "x、y > 0，9x + y + \\frac{1}{x} + \\frac{9}{y} = 12\n求 (x, y)",
			 "insight": "9x + \\frac{1}{x} ≥ 6、y + \\frac{9}{y} ≥ 6，加起來 ≥ 12\n題目說剛好等於 12：兩個等號都要成立。",
			 "steps": [
				_f("x 那組", "9x · \\frac{1}{x} = 9", "9x + \\frac{1}{x} ≥ [0]", ["6"], "9x + \\frac{1}{x} ≥ 2√9 = 6", "2√9。", T_AM),
				_f("y 那組", "y · \\frac{9}{y} = 9", "y + \\frac{9}{y} ≥ [0]", ["6"], "y + \\frac{9}{y} ≥ 2√9 = 6", "2√9。", T_AM),
				_f("(x, y)", "兩個等號都成立", "(x, y) = ([0], [1])", ["1/3", "3"],
					"6 + 6 = 12：9x = \\frac{1}{x}、y = \\frac{9}{y} ⇒ (x, y) = (\\frac{1}{3}, 3)", "9x^{2} = 1、y^{2} = 9。", T_AM),
			 ]},
		 ]},

		{"id": "speed2", "chapter": 2, "type": "speed", "title": "最小值速算", "time": 120.0,
		 "story": "x 和 \\frac{k}{x} 一起出現，最小值是多少？",
		 "insight": "x > 0：ax + \\frac{b}{x} ≥ 2√(ab)。",
		 "variants": [{"gen": "recip", "count": 8}]},
	]


## 題型一：斜邊 c 的直角三角形，直角的頂點在半圓上
static func _right_tri(c: int) -> Dictionary:
	var r := c / 2.0
	var hexpr := "sqrt(%s - t * t)" % _num(r * r)
	return {"eq": "直角三角形的斜邊是 %d\n面積最大是多少？" % c,
		"insight": "直角三角形：a^{2} + b^{2} = %d^{2} ≥ 2ab\n等腰（a = b）時面積最大：\\frac{%d}{4} = %d。" % [c, c * c, int(c * c / 4.0)],
		"plane": B1._plane([-r - 1, r + 1], [-1, r + 1], [_arc([0, 0], r, 0, 180), {"k": "seg", "a": [-r, 0], "b": [r, 0], "c": "dim"},
			{"k": "poly", "pts": [[-r, 0], [r, 0], [0, r]], "c": "lime", "fill": "lime", "alpha": 0.3, "at": 1}]),
		"steps": [
			_drag("拖頂點", "拖頂點，讓面積最大", -r + 1, r - 1, 1 if c > 6 else 0.5, -r + 1, 0,
				[{"k": "seg", "a": [str(-r), "0"], "b": ["t", hexpr], "c": "gold"}, {"k": "seg", "a": ["t", hexpr], "b": [str(r), "0"], "c": "gold"},
				 {"k": "seg", "a": ["t", hexpr], "b": ["t", "0"], "c": "gold", "dash": true}, {"k": "dot", "p": ["t", hexpr], "c": "gold"}],
				"面積 ≈ {%s * %s}" % [_num(r), hexpr], "頂點在最上面：等腰直角三角形", "高什麼時候最高？", T_FIX),
			_f("最大值", "兩股 a、b", "a^{2} + b^{2} = [0] ≥ 2ab ⇒ \\frac{ab}{2} ≤ [1]", [str(c * c), str(int(c * c / 4.0))],
				"a^{2} + b^{2} = %d ≥ 2ab ⇒ 面積 \\frac{ab}{2} ≤ %d" % [c * c, int(c * c / 4.0)], "畢氏定理：a^{2} + b^{2} = 斜邊^{2}。", T_FIX),
		]}


## 題型二：等腰直角三角形（斜邊 c）裡的長方形水池，一邊在斜邊上
static func _pool(c: int) -> Dictionary:
	var hh := c / 2.0
	var w := c / 2.0
	var h := c / 4.0
	return {"eq": "等腰直角三角形，斜邊 %d\n裡面的長方形最大多少？" % c,
		"insight": "兩邊的小三角形也是等腰直角：w + 2h = %d 是定值\nw · 2h ≤ (\\frac{%d}{2})^{2}，w = 2h 時長方形最大。" % [c, c],
		"plane": B1._plane([-hh - 1, hh + 1], [-1, hh + 1], [
			{"k": "poly", "pts": [[-hh, 0], [hh, 0], [0, hh]], "c": "lime", "fill": "lime", "alpha": 0.12},
			{"k": "poly", "pts": [[-hh / 2.0 - 1, 0], [hh / 2.0 + 1, 0], [hh / 2.0 + 1, hh / 2.0 - 1], [-hh / 2.0 - 1, hh / 2.0 - 1]],
			 "c": "cyan", "fill": "cyan", "alpha": 0.2, "until": 2},
			{"k": "label", "p": [0, 0], "s": "w", "off": [-4, 18]}, {"k": "label", "p": [hh / 2.0 + 1, (hh / 2.0 - 1) / 2.0], "s": "h", "off": [8, 4], "until": 2},
			{"k": "poly", "pts": [[-w / 2.0, 0], [w / 2.0, 0], [w / 2.0, h], [-w / 2.0, h]], "c": "cyan", "fill": "cyan", "alpha": 0.35, "at": 2}]),
		"steps": [
			_f("關係", "小三角形是等腰直角", "w + [0]h = %d" % c, ["2"], "兩邊各少 h：w + 2h = %d" % c,
				"小三角形的兩股一樣長，都是 h。", T_FIX),
			_f("最大值", "w + 2h 是定值", "w · 2h ≤ [0] ⇒ wh ≤ [1]", [str(int(c * c / 4.0)), str(int(c * c / 8.0))],
				"w · 2h ≤ (\\frac{%d}{2})^{2} = %d ⇒ wh ≤ %d（w = %d、h = %d）" % [c, int(c * c / 4.0), int(c * c / 8.0), int(w), int(h)],
				"(\\frac{%d}{2})^{2}。" % c, T_FIX),
		]}
