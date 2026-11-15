extends RefCounted
## 數與式 第三大關「天秤市集」題庫（對應講義重點三：次序不等式）
## 設計稿：docs/num_r3_design.md。題目的數字都用程式驗算過（tools/num/verify_r3.py）。
##
## 旅程（引擎見 num_level.gd）：
##   forge  一步一步推導：lrange（拉範圍）、grid（在方框上點角落、點最近最遠的點）、fill、choice（審判卡）
##   speed  速算：gen = "rng"（x − y、xy 的範圍，按鈕）、"sq"（x^{2} 的範圍，按鈕）
## 題目的 "field" 是數線柵欄上的燈條 bars（寫法見 num_field.gd 開頭），"plane" 是坐標方格上的方框。
## 看圖作答、少讀字（design_rules 1.8）：範圍都用拉的，相乘、相除、距離都在方框上點。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/num/num1_bank.gd")

const T_ABS := "num_absr"          # 絕對值寫成範圍
const T_ADD := "num_rangeop"       # 範圍的加減（−y 左右對調）
const T_MUL := "num_corner"        # 範圍的乘除（看四個角）
const T_SQ := "num_rsq"            # 平方的範圍（跨過 0）
const T_COMP := "num_rcomp"        # 複合的式子（配方看距離、拆括號）


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return SB.fill(name, q, template, answers, line, nudge, tag, mode)


static func _j(name: String, statement: String, ok: bool, why: String, line: String, tag: String) -> Dictionary:
	return B1._j(name, statement, ok, why, line, tag)


## 燈條：row 是第幾排（0 = 最靠近數線），at 是第幾步出現
static func _bar(lo: float, hi: float, s: String, row: int, at := 0, c := "cyan", extra := {}) -> Dictionary:
	var d := {"lo": lo, "hi": hi, "s": s, "row": row, "at": at, "c": c}
	d.merge(extra, true)
	return d


static func _line(x: Array, bars: Array, pts := []) -> Dictionary:
	return {"k": "nline", "x": x, "pts": pts, "bars": bars}


## 拉範圍
static func _rng(name: String, s: String, row: int, ans: Array, start: Array, q: String, nudge: String, line: String,
		tag: String, wrongs := [], snap := 1.0, demo := false) -> Dictionary:
	return {"kind": "lrange", "name": name, "tag": tag, "q": q, "item": 0, "row": row, "s": s, "ans": ans,
		"start": start, "snap": snap, "demo": demo, "wrongs": wrongs, "nudge": nudge, "line": line}


## 在方框上點一個點（grid）。traps：點到別的點時的提示
static func _pick(name: String, q: String, target: Array, traps: Array, nudge: String, line: String, tag: String) -> Dictionary:
	return {"kind": "grid", "name": name, "tag": tag, "q": q, "target": target, "label": "", "traps": traps,
		"nudge": nudge, "line": line}


## 方框：x 從 x0 到 x1、y 從 y0 到 y1，四個角是格子點
static func _box(x0: float, x1: float, y0: float, y1: float) -> Array:
	return [{"k": "poly", "pts": [[x0, y0], [x1, y0], [x1, y1], [x0, y1]], "c": "lime", "fill": "lime", "alpha": 0.14},
		{"k": "dot", "p": [x0, y0], "c": "dim"}, {"k": "dot", "p": [x1, y0], "c": "dim"},
		{"k": "dot", "p": [x0, y1], "c": "dim"}, {"k": "dot", "p": [x1, y1], "c": "dim"}]


static func _lab(p: Array, s: String, at: int, off := [10, -10]) -> Dictionary:
	return {"k": "label", "p": p, "s": s, "at": at, "off": off, "c": "gold"}


## 配方看距離：方框裡每一個格子點（除了答案）點到時，告訴學生它到 C 的距離平方
static func _dist_traps(x0: int, x1: int, y0: int, y1: int, cx: int, cy: int, target: Array) -> Array:
	var out := []
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			if x == int(target[0]) and y == int(target[1]):
				continue
			out.append([x, y, "這一點到 C 的距離平方是 %d。" % [(x - cx) * (x - cx) + (y - cy) * (y - cy)]])
	return out


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


static func _slots() -> Array:
	return [
		# ======================= 第一章．範圍的加減乘除 =======================
		{"id": "dist", "chapter": 1, "type": "forge", "title": "距離寫成範圍",
		 "story": "|x − a| ≤ b：x 離 a 不超過 b。",
		 "insight": "|x − a| ≤ b ⇔ a − b ≤ x ≤ a + b：中心 a，往兩邊各走 b\n|2y − 3| ≤ 5 要先除以 2，才看得出中心和距離。",
		 "variants": [
			{"eq": "|x − 1| ≤ 3、|2y − 3| ≤ 5\n求 x、y 的範圍",
			 "field": [_line([-4, 6], [_bar(-2, 4, "x", 0, 1), _bar(-1, 4, "y", 1, 3, "gold")],
				[{"v": 1, "s": "", "c": "cyan"}, {"v": 1.5, "s": "", "c": "gold", "at": 2}])],
			 "steps": [
				_rng("x", "x", 0, [-2, 4], [0, 2], "拉出 x 的範圍", "從中心 1 往左、往右各走 3。",
					"|x − 1| ≤ 3 ⇔ −2 ≤ x ≤ 4", T_ABS, [[-3, 3, "中心是 1，不是 0。"]], 1.0, true),
				_f("除以 2", "兩邊除以 2", "|2y − 3| ≤ 5 ⇒ |y − [0]| ≤ [1]", ["3/2", "5/2"],
					"|y − \\frac{3}{2}| ≤ \\frac{5}{2}", "|2y − 3| = 2|y − \\frac{3}{2}|。", T_ABS),
				_rng("y", "y", 1, [-1, 4], [1, 2], "拉出 y 的範圍", "從中心 \\frac{3}{2} 往兩邊各走 \\frac{5}{2}。",
					"−1 ≤ y ≤ 4", T_ABS, [], 0.5),
			 ]},
			{"eq": "|x + 2| ≤ 2、|2y + 1| ≤ 3\n求 x、y 的範圍",
			 "field": [_line([-6, 5], [_bar(-4, 0, "x", 0, 1), _bar(-2, 1, "y", 1, 3, "gold")],
				[{"v": -2, "s": "", "c": "cyan"}, {"v": -0.5, "s": "", "c": "gold", "at": 2}])],
			 "steps": [
				_rng("x", "x", 0, [-4, 0], [-3, -1], "拉出 x 的範圍", "|x + 2| = |x − (−2)|：中心是 −2。",
					"|x + 2| ≤ 2 ⇔ −4 ≤ x ≤ 0", T_ABS, [[0, 4, "x + 2 = x − (−2)：中心是 −2。"]], 1.0, true),
				_f("除以 2", "兩邊除以 2", "|2y + 1| ≤ 3 ⇒ |y + [0]| ≤ [1]", ["1/2", "3/2"],
					"|y + \\frac{1}{2}| ≤ \\frac{3}{2}", "|2y + 1| = 2|y + \\frac{1}{2}|。", T_ABS),
				_rng("y", "y", 1, [-2, 1], [-1, 0], "拉出 y 的範圍", "從中心 −\\frac{1}{2} 往兩邊各走 \\frac{3}{2}。",
					"−2 ≤ y ≤ 1", T_ABS, [], 0.5),
			 ]},
		 ]},

		{"id": "addsub", "chapter": 1, "type": "forge", "title": "加和減",
		 "story": "兩段燈條合起來，看新的燈條有多長。",
		 "insight": "x + y：最小加最小、最大加最大\nx − y = x + (−y)：−y 的範圍要左右對調，不能直接拿端點相減。",
		 "variants": [
			{"eq": "−1 ≤ x ≤ 3、2 ≤ y ≤ 4\n求 x + y、x − y 的範圍",
			 "field": [_line([-6, 8], [_bar(-1, 3, "x", 0), _bar(2, 4, "y", 1, 0, "gold"),
				_bar(1, 7, "x + y", 2, 1, "lime", {"src": [[0, -1, 0], [1, 2, 0], [0, 3, 1], [1, 4, 1]]}),
				_bar(-4, -2, "−y", 3, 2, "gold", {"from": [4, 2, 1]}),
				_bar(-5, 1, "x − y", 4, 3, "lime", {"src": [[0, -1, 0], [3, -4, 0], [0, 3, 1], [3, -2, 1]]})])],
			 "steps": [
				_rng("x + y", "x + y", 2, [1, 7], [-1, 1], "拉出 x + y", "最小加最小、最大加最大。", "1 ≤ x + y ≤ 7", T_ADD),
				_rng("−y", "−y", 3, [-4, -2], [2, 4], "拉出 −y", "y 越大，−y 越小：−y 在 0 的另一邊。", "−4 ≤ −y ≤ −2", T_ADD),
				_rng("x − y", "x − y", 4, [-5, 1], [-1, 1], "拉出 x − y", "x − y = x + (−y)：用 −y 的燈條。",
					"x − y = x + (−y) ⇒ −5 ≤ x − y ≤ 1", T_ADD, [[-3, -1, "端點直接相減不對：x − y = x + (−y)。"]]),
			 ]},
			{"eq": "−2 ≤ x ≤ 5、1 ≤ y ≤ 3\n求 x + y、x − y 的範圍",
			 "field": [_line([-6, 9], [_bar(-2, 5, "x", 0), _bar(1, 3, "y", 1, 0, "gold"),
				_bar(-1, 8, "x + y", 2, 1, "lime", {"src": [[0, -2, 0], [1, 1, 0], [0, 5, 1], [1, 3, 1]]}),
				_bar(-3, -1, "−y", 3, 2, "gold", {"from": [3, 1, 1]}),
				_bar(-5, 4, "x − y", 4, 3, "lime", {"src": [[0, -2, 0], [3, -3, 0], [0, 5, 1], [3, -1, 1]]})])],
			 "steps": [
				_rng("x + y", "x + y", 2, [-1, 8], [1, 3], "拉出 x + y", "最小加最小、最大加最大。", "−1 ≤ x + y ≤ 8", T_ADD),
				_rng("−y", "−y", 3, [-3, -1], [1, 3], "拉出 −y", "y 越大，−y 越小：−y 在 0 的另一邊。", "−3 ≤ −y ≤ −1", T_ADD),
				_rng("x − y", "x − y", 4, [-5, 4], [0, 2], "拉出 x − y", "x − y = x + (−y)：用 −y 的燈條。",
					"x − y = x + (−y) ⇒ −5 ≤ x − y ≤ 4", T_ADD, [[-3, 2, "端點直接相減不對：x − y = x + (−y)。"]]),
			 ]},
		 ]},

		{"id": "corner", "chapter": 1, "type": "forge", "title": "四個角",
		 "story": "x、y 圍出一個方框，答案藏在角落。",
		 "insight": "x、y 的範圍圍出一個方框\nxy、\\frac{x}{y}（y > 0）的最大、最小一定在四個角：四個角都算一算。",
		 "variants": [
			{"eq": "−2 ≤ x ≤ 4、2 ≤ y ≤ 4\n求 xy、\\frac{x}{y} 的範圍",
			 "plane": B1._plane([-3, 5], [-0.6, 5], _box(-2, 4, 2, 4) + [
				_lab([4, 4], "16", 1, [-30, 24]), _lab([-2, 4], "−8", 2, [10, 24]), _lab([4, 2], "2", 3, [-24, -10]), _lab([-2, 2], "−1", 4, [10, -10])]),
			 "steps": [
				_pick("xy 最大", "點 xy 最大的角", [4, 4], [[-2, 2, "這個角 xy = −4。"], [-2, 4, "這個角 xy = −8。"], [4, 2, "這個角 xy = 8。"]],
					"xy 的最大、最小在四個角：每個角算 x × y。", "xy 最大：(4, 4)，4 × 4 = 16", T_MUL),
				_pick("xy 最小", "點 xy 最小的角", [-2, 4], [[-2, 2, "這個角 xy = −4。"], [4, 2, "這個角 xy = 8。"], [4, 4, "這個角 xy = 16。"]],
					"負的乘大的，會更小。", "xy 最小：(−2, 4)，−8 ⇒ −8 ≤ xy ≤ 16", T_MUL),
				_pick("x/y 最大", "點 \\frac{x}{y} 最大的角", [4, 2], [[4, 4, "這個角 \\frac{x}{y} = 1。"], [-2, 2, "這個角 \\frac{x}{y} = −1。"], [-2, 4, "這個角 \\frac{x}{y} = −\\frac{1}{2}。"]],
					"每個角算 \\frac{x}{y}。", "\\frac{x}{y} 最大：(4, 2)，\\frac{4}{2} = 2", T_MUL),
				_pick("x/y 最小", "點 \\frac{x}{y} 最小的角", [-2, 2], [[4, 4, "這個角 \\frac{x}{y} = 1。"], [4, 2, "這個角 \\frac{x}{y} = 2。"], [-2, 4, "這個角 \\frac{x}{y} = −\\frac{1}{2}。"]],
					"負的除以小的，會更小。", "\\frac{x}{y} 最小：(−2, 2)，−1 ⇒ −1 ≤ \\frac{x}{y} ≤ 2", T_MUL),
			 ]},
			{"eq": "−3 ≤ x ≤ 1、1 ≤ y ≤ 3\n求 xy、\\frac{x}{y} 的範圍",
			 "plane": B1._plane([-4, 3], [-0.6, 4], _box(-3, 1, 1, 3) + [
				_lab([1, 3], "3", 1, [-24, 24]), _lab([-3, 3], "−9", 2, [10, 24]), _lab([1, 1], "1", 3, [-24, -10]), _lab([-3, 1], "−3", 4, [10, -10])]),
			 "steps": [
				_pick("xy 最大", "點 xy 最大的角", [1, 3], [[-3, 1, "這個角 xy = −3。"], [-3, 3, "這個角 xy = −9。"], [1, 1, "這個角 xy = 1。"]],
					"xy 的最大、最小在四個角：每個角算 x × y。", "xy 最大：(1, 3)，1 × 3 = 3", T_MUL),
				_pick("xy 最小", "點 xy 最小的角", [-3, 3], [[-3, 1, "這個角 xy = −3。"], [1, 1, "這個角 xy = 1。"], [1, 3, "這個角 xy = 3。"]],
					"負的乘大的，會更小。", "xy 最小：(−3, 3)，−9 ⇒ −9 ≤ xy ≤ 3", T_MUL),
				_pick("x/y 最大", "點 \\frac{x}{y} 最大的角", [1, 1], [[1, 3, "這個角 \\frac{x}{y} = \\frac{1}{3}。"], [-3, 1, "這個角 \\frac{x}{y} = −3。"], [-3, 3, "這個角 \\frac{x}{y} = −1。"]],
					"每個角算 \\frac{x}{y}。", "\\frac{x}{y} 最大：(1, 1)，\\frac{1}{1} = 1", T_MUL),
				_pick("x/y 最小", "點 \\frac{x}{y} 最小的角", [-3, 1], [[1, 3, "這個角 \\frac{x}{y} = \\frac{1}{3}。"], [1, 1, "這個角 \\frac{x}{y} = 1。"], [-3, 3, "這個角 \\frac{x}{y} = −1。"]],
					"負的除以小的，會更小。", "\\frac{x}{y} 最小：(−3, 1)，−3 ⇒ −3 ≤ \\frac{x}{y} ≤ 1", T_MUL),
			 ]},
		 ]},

		{"id": "square", "chapter": 1, "type": "forge", "title": "跨過 0 的平方",
		 "story": "燈條跨過 0 時，平方的燈條會對摺。",
		 "insight": "x 的範圍跨過 0：x^{2} 最小是 0（x = 0），最大看離 0 最遠的端點\n不能直接把兩個端點平方。",
		 "variants": [
			{"eq": "−3 ≤ x ≤ 2、1 ≤ y ≤ 2\n求 x^{2}、x^{2} + y^{2} 的範圍",
			 "field": [_line([-4, 14], [_bar(-3, 2, "x", 0), _bar(1, 2, "y", 1, 0, "gold"),
				_bar(0, 9, "x^{2}", 2, 1, "lime", {"from": [0, 3, 0]}),
				_bar(1, 13, "x^{2} + y^{2}", 3, 2, "lime", {"src": [[2, 0, 0], [2, 9, 1]]})])],
			 "steps": [
				_rng("x²", "x^{2}", 2, [0, 9], [1, 3], "拉出 x^{2}", "x 跨過 0：x^{2} 最小是多少？", "x 跨過 0 ⇒ 0 ≤ x^{2} ≤ 9", T_SQ,
					[[4, 9, "x = 0 也在範圍裡：x^{2} 最小是 0。"]]),
				_rng("x² + y²", "x^{2} + y^{2}", 3, [1, 13], [3, 5], "拉出 x^{2} + y^{2}", "y^{2} 在 1 到 4 之間。",
					"1 ≤ y^{2} ≤ 4 ⇒ 1 ≤ x^{2} + y^{2} ≤ 13", T_SQ),
			 ]},
			{"eq": "−1 ≤ x ≤ 4、−2 ≤ y ≤ −1\n求 x^{2}、x^{2} + y^{2} 的範圍",
			 "field": [_line([-3, 21], [_bar(-1, 4, "x", 0), _bar(-2, -1, "y", 1, 0, "gold"),
				_bar(0, 16, "x^{2}", 2, 1, "lime", {"from": [0, 4, 0]}),
				_bar(1, 20, "x^{2} + y^{2}", 3, 2, "lime", {"src": [[2, 0, 0], [2, 16, 1]]})])],
			 "steps": [
				_rng("x²", "x^{2}", 2, [0, 16], [2, 5], "拉出 x^{2}", "x 跨過 0：x^{2} 最小是多少？", "x 跨過 0 ⇒ 0 ≤ x^{2} ≤ 16", T_SQ,
					[[1, 16, "x = 0 也在範圍裡：x^{2} 最小是 0。"]]),
				_rng("x² + y²", "x^{2} + y^{2}", 3, [1, 20], [4, 7], "拉出 x^{2} + y^{2}", "y 是負的：y^{2} 在 1 到 4 之間。",
					"1 ≤ y^{2} ≤ 4 ⇒ 1 ≤ x^{2} + y^{2} ≤ 20", T_SQ),
			 ]},
		 ]},

		{"id": "which", "chapter": 1, "type": "forge", "title": "哪些一定成立",
		 "story": "把學過的範圍，一張一張審判。",
		 "insight": "先把絕對值寫成範圍，畫出方框\n加減看端點、乘除看四個角、平方看有沒有跨過 0。推翻一句話，找一個反例就夠了。",
		 "variants": [
			{"eq": "|x + 1| ≤ 2、|y − 3| ≤ 1\n下面哪些一定成立？",
			 "plane": B1._plane([-4, 2], [-0.6, 5], _box(-3, 1, 2, 4) + [_lab([0, 2], "4", 5, [-6, -14])]),
			 "steps": [
				_j("審判一", "−7 ≤ x − y ≤ −1", true, "x：−3 到 1，−y：−4 到 −2，相加是 −7 到 −1。", "−7 ≤ x − y ≤ −1", T_ADD),
				_j("審判二", "−12 ≤ xy ≤ 4", true, "四個角：(−3, 2) = −6、(−3, 4) = −12、(1, 2) = 2、(1, 4) = 4。", "−12 ≤ xy ≤ 4", T_MUL),
				_j("審判三", "−\\frac{3}{2} ≤ \\frac{x}{y} ≤ \\frac{1}{2}", true,
					"四個角：(−3, 2) = −\\frac{3}{2}、(−3, 4) = −\\frac{3}{4}、(1, 2) = \\frac{1}{2}、(1, 4) = \\frac{1}{4}。",
					"−\\frac{3}{2} ≤ \\frac{x}{y} ≤ \\frac{1}{2}", T_MUL),
				_j("審判四", "5 ≤ x^{2} + y^{2} ≤ 25", false, "x 跨過 0：x^{2} 最小是 0，x^{2} + y^{2} 最小是 0 + 4 = 4。",
					"x^{2} + y^{2} 可以比 5 小", T_SQ),
				_pick("反例", "點一個 x^{2} + y^{2} < 5 的點", [0, 2], [[-1, 2, "這一點 x^{2} + y^{2} = 5，沒有比 5 小。"], [1, 2, "這一點 x^{2} + y^{2} = 5，沒有比 5 小。"]],
					"x^{2} 最小在 x = 0，y^{2} 最小在 y = 2。", "(0, 2)：0 + 4 = 4 < 5 ⇒ 審判四不成立", T_SQ),
			 ]},
			{"eq": "|x| ≤ 1、|y + 3| ≤ 1\n下面哪些一定成立？",
			 "plane": B1._plane([-3, 3], [-5, 0.6], _box(-1, 1, -4, -2) + [_lab([0, -2], "4", 5, [-6, 26])]),
			 "steps": [
				_j("審判一", "1 ≤ x − y ≤ 5", true, "x：−1 到 1，−y：2 到 4，相加是 1 到 5。", "1 ≤ x − y ≤ 5", T_ADD),
				_j("審判二", "−4 ≤ xy ≤ 4", true, "四個角：(−1, −4) = 4、(−1, −2) = 2、(1, −4) = −4、(1, −2) = −2。", "−4 ≤ xy ≤ 4", T_MUL),
				_j("審判三", "−\\frac{1}{2} ≤ \\frac{x}{y} ≤ \\frac{1}{2}", true,
					"四個角：(−1, −4) = \\frac{1}{4}、(−1, −2) = \\frac{1}{2}、(1, −4) = −\\frac{1}{4}、(1, −2) = −\\frac{1}{2}。",
					"−\\frac{1}{2} ≤ \\frac{x}{y} ≤ \\frac{1}{2}", T_MUL),
				_j("審判四", "5 ≤ x^{2} + y^{2} ≤ 17", false, "x 跨過 0：x^{2} 最小是 0，x^{2} + y^{2} 最小是 0 + 4 = 4。",
					"x^{2} + y^{2} 可以比 5 小", T_SQ),
				_pick("反例", "點一個 x^{2} + y^{2} < 5 的點", [0, -2], [[-1, -2, "這一點 x^{2} + y^{2} = 5，沒有比 5 小。"], [1, -2, "這一點 x^{2} + y^{2} = 5，沒有比 5 小。"]],
					"x^{2} 最小在 x = 0，y^{2} 最小在 y = −2。", "(0, −2)：0 + 4 = 4 < 5 ⇒ 審判四不成立", T_SQ),
			 ]},
		 ]},

		{"id": "speed1", "chapter": 1, "type": "speed", "title": "範圍速算", "time": 120.0,
		 "story": "攤位一個一個亮起來！快速點出範圍。",
		 "insight": "x − y = x + (−y)：最小 − 最大、最大 − 最小\nxy 看四個角。",
		 "variants": [{"gen": "rng", "count": 8}]},

		# ======================= 第二章．複合的式子 =======================
		{"id": "sqsub", "chapter": 2, "type": "forge", "title": "平方相減",
		 "story": "先看兩個平方，再相減。",
		 "insight": "x^{2} − y^{2} = x^{2} + (−y^{2})：最小是 x^{2} 最小 − y^{2} 最大\ny 跨過 0 時，y^{2} 最小是 0。負的範圍平方，左右要對調。",
		 "variants": [
			{"eq": "2 ≤ x ≤ 4、−2 ≤ y ≤ 4\n求 x^{2} − y^{2} 的範圍",
			 "field": [_line([-14, 18], [_bar(2, 4, "x", 0), _bar(-2, 4, "y", 1, 0, "gold"),
				_bar(4, 16, "x^{2}", 2, 1, "cyan", {"from": [2, 4, 0]}),
				_bar(0, 16, "y^{2}", 3, 2, "gold", {"from": [0, 4, 1]}),
				_bar(-12, 16, "x^{2} − y^{2}", 4, 3, "lime", {"src": [[2, 4, 0], [3, 16, 0], [2, 16, 1], [3, 0, 1]]})])],
			 "steps": [
				_rng("x²", "x^{2}", 2, [4, 16], [0, 2], "拉出 x^{2}", "x 都是正的：端點平方。", "4 ≤ x^{2} ≤ 16", T_SQ),
				_rng("y²", "y^{2}", 3, [0, 16], [6, 8], "拉出 y^{2}", "y 跨過 0。", "y 跨過 0 ⇒ 0 ≤ y^{2} ≤ 16", T_SQ,
					[[4, 16, "y 跨過 0：y^{2} 最小是 0。"]]),
				_rng("x² − y²", "x^{2} − y^{2}", 4, [-12, 16], [-2, 2], "拉出 x^{2} − y^{2}", "最小：x^{2} 最小減 y^{2} 最大。",
					"x^{2} − y^{2}：4 − 16 = −12 到 16 − 0 = 16", T_COMP, [[-12, 12, "y^{2} 最小是 0：最大是 16 − 0。"]]),
			 ]},
			{"eq": "−3 ≤ x ≤ −1、−1 ≤ y ≤ 3\n求 x^{2} − y^{2} 的範圍",
			 "field": [_line([-10, 11], [_bar(-3, -1, "x", 0), _bar(-1, 3, "y", 1, 0, "gold"),
				_bar(1, 9, "x^{2}", 2, 1, "cyan", {"from": [-1, -3, 0]}),
				_bar(0, 9, "y^{2}", 3, 2, "gold", {"from": [0, 3, 1]}),
				_bar(-8, 9, "x^{2} − y^{2}", 4, 3, "lime", {"src": [[2, 1, 0], [3, 9, 0], [2, 9, 1], [3, 0, 1]]})])],
			 "steps": [
				_rng("x²", "x^{2}", 2, [1, 9], [3, 5], "拉出 x^{2}", "x 都是負的：離 0 越遠，平方越大。", "1 ≤ x^{2} ≤ 9", T_SQ),
				_rng("y²", "y^{2}", 3, [0, 9], [4, 6], "拉出 y^{2}", "y 跨過 0。", "y 跨過 0 ⇒ 0 ≤ y^{2} ≤ 9", T_SQ,
					[[1, 9, "y 跨過 0：y^{2} 最小是 0。"]]),
				_rng("x² − y²", "x^{2} − y^{2}", 4, [-8, 9], [-2, 2], "拉出 x^{2} − y^{2}", "最小：x^{2} 最小減 y^{2} 最大。",
					"x^{2} − y^{2}：1 − 9 = −8 到 9 − 0 = 9", T_COMP, [[-8, 8, "y^{2} 最小是 0：最大是 9 − 0。"]]),
			 ]},
		 ]},

		{"id": "dist2", "chapter": 2, "type": "forge", "title": "配方看距離",
		 "story": "配方之後，式子變成到一個點的距離平方。",
		 "insight": "(x − h)^{2} + (y − k)^{2} 是 (x, y) 到 C(h, k) 的距離平方\n方框裡離 C 最近的點是最小值，最遠的點是最大值。",
		 "variants": [
			{"eq": "−2 ≤ x ≤ 3、−4 ≤ y ≤ 1\nx^{2} + y^{2} − 2x + 4y + 3 的最大值 M、最小值 m",
			 "plane": B1._plane([-3, 4], [-5, 2], _box(-2, 3, -4, 1) + [
				{"k": "dot", "p": [1, -2], "s": "C", "c": "cyan", "at": 1, "off": [8, 16]},
				{"k": "seg", "a": [1, -2], "b": [-2, 1], "c": "gold", "dash": true, "at": 3},
				{"k": "circle", "o": [1, -2], "r": sqrt(18.0), "c": "gold", "at": 3}]),
			 "steps": [
				_f("配方", "配方", "(x − [0])^{2} + (y + [1])^{2} − [2]", ["1", "2", "2"],
					"(x − 1)^{2} + (y + 2)^{2} − 2：到 C(1, −2) 的距離平方 − 2", "x^{2} − 2x = (x − 1)^{2} − 1。", T_COMP),
				_pick("最近", "點離 C 最近的點", [1, -2], _dist_traps(-2, 3, -4, 1, 1, -2, [1, -2]),
					"C 在方框裡面。", "最近的就是 C：距離平方 0", T_COMP),
				_pick("最遠", "點離 C 最遠的點", [-2, 1], _dist_traps(-2, 3, -4, 1, 1, -2, [-2, 1]),
					"最遠的點在角落。", "最遠：(−2, 1)，距離平方 9 + 9 = 18", T_COMP),
				_f("m、M", "最小值、最大值", "m = [0]、M = [1]", ["-2", "16"],
					"m = 0 − 2 = −2、M = 18 − 2 = 16", "距離平方再減 2。", T_COMP),
			 ]},
			{"eq": "−1 ≤ x ≤ 3、1 ≤ y ≤ 4\nx^{2} + y^{2} + 4x − 2y + 1 的最大值 M、最小值 m",
			 "plane": B1._plane([-3.5, 4], [-0.6, 5], _box(-1, 3, 1, 4) + [
				{"k": "dot", "p": [-2, 1], "s": "C", "c": "cyan", "at": 1, "off": [-18, 16]},
				{"k": "seg", "a": [-2, 1], "b": [-1, 1], "c": "gold", "dash": true, "at": 2},
				{"k": "circle", "o": [-2, 1], "r": 1.0, "c": "cyan", "at": 2},
				{"k": "seg", "a": [-2, 1], "b": [3, 4], "c": "gold", "dash": true, "at": 3},
				{"k": "circle", "o": [-2, 1], "r": sqrt(34.0), "c": "gold", "at": 3}]),
			 "steps": [
				_f("配方", "配方", "(x + [0])^{2} + (y − [1])^{2} − [2]", ["2", "1", "4"],
					"(x + 2)^{2} + (y − 1)^{2} − 4：到 C(−2, 1) 的距離平方 − 4", "x^{2} + 4x = (x + 2)^{2} − 4。", T_COMP),
				_pick("最近", "點離 C 最近的點", [-1, 1], _dist_traps(-1, 3, 1, 4, -2, 1, [-1, 1]),
					"C 在方框外面：找方框邊上最靠近 C 的點。", "最近：(−1, 1)，距離平方 1", T_COMP),
				_pick("最遠", "點離 C 最遠的點", [3, 4], _dist_traps(-1, 3, 1, 4, -2, 1, [3, 4]),
					"最遠的點在角落。", "最遠：(3, 4)，距離平方 25 + 9 = 34", T_COMP),
				_f("m、M", "最小值、最大值", "m = [0]、M = [1]", ["-3", "30"],
					"m = 1 − 4 = −3、M = 34 − 4 = 30", "距離平方再減 4。", T_COMP),
			 ]},
		 ]},

		{"id": "factor", "chapter": 2, "type": "forge", "title": "拆成兩個括號",
		 "story": "拆成兩個括號，就是兩段燈條相乘。",
		 "insight": "xy − 2x − 3y + 1 = (x − 3)(y − 2) − 5\n拆成兩個括號，各自的範圍相乘（看四種組合），最後再加回常數。",
		 "variants": [
			{"eq": "−1 ≤ x ≤ 2、1 ≤ y ≤ 4\n求 xy − 2x − 3y + 1 的範圍",
			 "field": [_line([-14, 5], [_bar(-1, 2, "x", 0), _bar(1, 4, "y", 1, 0, "gold"),
				_bar(-4, -1, "x − 3", 2, 1, "cyan", {"from": [-1, 2, 0]}),
				_bar(-1, 2, "y − 2", 3, 1, "gold", {"from": [1, 4, 1]}),
				_bar(-8, 4, "(x − 3)(y − 2)", 4, 2, "lime"),
				_bar(-13, -1, "xy − 2x − 3y + 1", 5, 3, "lime", {"from": [-8, 4, 4]})])],
			 "steps": [
				_f("拆", "拆成兩個括號", "xy − 2x − 3y + 1 = (x − [0])(y − [1]) − [2]", ["3", "2", "5"],
					"xy − 2x − 3y + 1 = (x − 3)(y − 2) − 5", "(x − 3)(y − 2) 展開是 xy − 2x − 3y + 6。", T_COMP),
				_rng("相乘", "(x − 3)(y − 2)", 4, [-8, 4], [-1, 1], "拉出兩個括號的乘積", "看四種組合：(−4)(−1)、(−4)(2)、(−1)(−1)、(−1)(2)。",
					"(x − 3)(y − 2)：−8 到 4", T_COMP, [[-2, 4, "不能只看兩端：(−4) × 2 = −8 更小。"]]),
				_rng("答案", "xy − 2x − 3y + 1", 5, [-13, -1], [-4, -2], "再減 5", "整條燈條往左移 5。",
					"−13 ≤ xy − 2x − 3y + 1 ≤ −1", T_COMP),
			 ]},
			{"eq": "0 ≤ x ≤ 4、−2 ≤ y ≤ 1\n求 xy + x − 2y + 1 的範圍",
			 "field": [_line([-6, 9], [_bar(0, 4, "x", 0), _bar(-2, 1, "y", 1, 0, "gold"),
				_bar(-2, 2, "x − 2", 2, 1, "cyan", {"from": [0, 4, 0]}),
				_bar(-1, 2, "y + 1", 3, 1, "gold", {"from": [-2, 1, 1]}),
				_bar(-4, 4, "(x − 2)(y + 1)", 4, 2, "lime"),
				_bar(-1, 7, "xy + x − 2y + 1", 5, 3, "lime", {"from": [-4, 4, 4]})])],
			 "steps": [
				_f("拆", "拆成兩個括號", "xy + x − 2y + 1 = (x − [0])(y + [1]) + [2]", ["2", "1", "3"],
					"xy + x − 2y + 1 = (x − 2)(y + 1) + 3", "(x − 2)(y + 1) 展開是 xy + x − 2y − 2。", T_COMP),
				_rng("相乘", "(x − 2)(y + 1)", 4, [-4, 4], [0, 1], "拉出兩個括號的乘積", "看四種組合：(−2)(−1)、(−2)(2)、(2)(−1)、(2)(2)。",
					"(x − 2)(y + 1)：−4 到 4", T_COMP, [[2, 4, "不能只看兩端：(−2) × 2 = −4 更小。"]]),
				_rng("答案", "xy + x − 2y + 1", 5, [-1, 7], [1, 3], "再加 3", "整條燈條往右移 3。",
					"−1 ≤ xy + x − 2y + 1 ≤ 7", T_COMP),
			 ]},
		 ]},

		{"id": "speed2", "chapter": 2, "type": "speed", "title": "平方速算", "time": 120.0,
		 "story": "燈條跨過 0 了沒？快速點出平方的範圍。",
		 "insight": "跨過 0：x^{2} 最小是 0\n都是負的：平方之後左右對調。",
		 "variants": [{"gen": "sq", "count": 8}]},
	]
