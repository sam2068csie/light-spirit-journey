extends RefCounted
## 直線與圓 第四大關「分光稻田」題庫（對應講義 3-2 重點三：二元一次不等式）
##
## 旅程（引擎見 line_level.gd）：
##   forge  一步一步推導：choice、fill、grid（點選格子點）、slide（滑桿）、region（點選區域：點要塗色的那幾塊）
##   speed  速算：gen = "side"（代入 ax + by + c 的值）、"row"（數一列的格子點）
##
## 觀念標籤都用 line_ 開頭（名稱寫在 quiz_manager.gd 的 MISTAKE_INFO）。
## 題目的數字都用程式驗算過（scratchpad/c4/verify_c4.py）。
## 線性規劃不收錄（使用者 2026/11/06 決定）。延後到終焉之塔的題型記在 docs/line_tower_backlog.md。

const SB := preload("res://data/levels/engine/step_bank.gd")
const RADICALS := true

const T_SIDE := "line_side"        # 代入看正負：同側、異側
const T_REG := "line_region"       # 不等式（組）的圖形
const T_APP := "line_ineqapp"      # 反求係數、面積、斜率範圍、格子點
const T_EQ := "line_eq"            # 直線方程式（第二關也有）
const T_BIS := "line_bisect"       # 內心（第三關也有）


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return SB.fill(name, q, template, answers, line, nudge, tag, mode)


## 列式的填空：groups 裡的格子可以互換，alts 是其他也算對的整組答案
static func _fx(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, groups := [], alts := []) -> Dictionary:
	var st := SB.fill(name, q, template, answers, line, nudge, tag)
	if not groups.is_empty():
		st["groups"] = groups
	if not alts.is_empty():
		st["alts"] = alts
	return st


## 點選格子點
static func _g(name: String, q: String, label: String, target: Array, line: String, nudge: String, tag: String,
		traps := [], snap := 1.0) -> Dictionary:
	return {"kind": "grid", "name": name, "q": q, "label": label, "target": target, "line": line, "nudge": nudge,
		"tag": tag, "traps": traps, "snap": snap}


## 滑桿：params = [[名稱, 最小, 最大, 間隔, 一開始], …]
##   lines：[a, b, c 的算式, 顏色, 名字]（會動的直線），或直接寫字典（會動的點、線段，見 line_level.gd）
static func _s(name: String, q: String, params: Array, lines: Array, line: String, nudge: String, tag: String,
		extra := {}) -> Dictionary:
	var ps := []
	for p in params:
		ps.append({"n": p[0], "min": p[1], "max": p[2], "step": p[3], "v": p[4]})
	var ls := []
	for l in lines:
		if l is Dictionary:
			ls.append(l)
		else:
			ls.append({"abc": [l[0], l[1], l[2]], "c": l[3] if l.size() > 3 else "cyan", "s": l[4] if l.size() > 4 else ""})
	var st := {"kind": "slide", "name": name, "q": q, "params": ps, "lines": ls, "line": line, "nudge": nudge, "tag": tag}
	st.merge(extra, true)
	return st


# ---------- 坐標方格的圖層 ----------

static func _p(s: String, x: float, y: float, at := 0, off := [8, -8], c := "text") -> Dictionary:
	return {"k": "dot", "p": [x, y], "s": s, "at": at, "off": off, "c": c}


static func _seg(a: Array, b: Array, at := 0, c := "dim", dash := false) -> Dictionary:
	return {"k": "seg", "a": a, "b": b, "at": at, "c": c, "dash": dash}


static func _ln(p: Array, q: Array, s := "", at := 0, c := "cyan", dash := false) -> Dictionary:
	return {"k": "line", "p": p, "q": q, "s": s, "at": at, "c": c, "dash": dash}


static func _lg(a: float, b: float, c: float, s := "", at := 0, col := "cyan", dash := false) -> Dictionary:
	return {"k": "line", "abc": [a, b, c], "s": s, "at": at, "c": col, "dash": dash}


## 點選區域：ineq = [[a, b, c, "<="], …]，names = 每一條的寫法（答錯時提示用）
static func _r(name: String, q: String, ineq: Array, names: Array, line: String, nudge: String, tag: String, lines := []) -> Dictionary:
	var st := {"kind": "region", "name": name, "q": q, "ineq": ineq, "names": names, "line": line, "nudge": nudge, "tag": tag}
	if not lines.is_empty():
		st["lines"] = lines
	return st


static func _reg(ineq: Array, at := 0, c := "lime", alpha := 0.2) -> Dictionary:
	return {"k": "region", "ineq": ineq, "at": at, "c": c, "alpha": alpha}


## 第 y = r 列的格子點（ineq 再加上 y = r）
static func _row(base: Array, r: int, at: int) -> Dictionary:
	var iq := base.duplicate()
	iq.append([0, 1, -r, ">="])
	iq.append([0, 1, -r, "<="])
	return {"k": "lattice", "ineq": iq, "at": at, "c": "gold"}


static func _plane(x: Array, y: Array, shapes: Array) -> Dictionary:
	return {"x": x, "y": y, "shapes": shapes}


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
				elif String(st.get("kind", "")) == "filter":
					st["bare"] = true
	return out


static func _slots() -> Array:
	var tri := [[1, -2, -1, "<="], [1, 2, -9, "<="], [1, 0, -1, ">="]]          # △ABC：A(1, 0)、B(5, 2)、C(1, 4)
	var quad := [[1, 0, 0, ">="], [0, 1, 0, ">="], [1, 2, -8, "<="], [3, 1, -9, "<="]]   # 四邊形 (0, 0)、(3, 0)、(2, 3)、(0, 4)
	var buy := [[3, 5, -30, "<="], [1, 0, -1, ">="], [0, 1, -1, ">="]]          # 3x + 5y ≤ 30、x ≥ 1、y ≥ 1
	return [
		# ======================= 第一章．田埂的兩邊 =======================
		{"id": "side", "chapter": 1, "type": "forge", "title": "田埂的兩邊",
		 "story": "一條田埂（直線 L）把稻田分成兩半。把點的坐標代進 L 的式子，一邊算出來都是正的，另一邊都是負的。",
		 "insight": "直線 L：ax + by + c = 0 把平面分成兩半：一邊 ax + by + c > 0，另一邊 ax + by + c < 0\n兩點代入同號 ⇔ 同側，異號 ⇔ 兩側（在 L 上的點代入是 0）。",
		 "variants": [
			{"eq": "直線 L：2x − y − 2 = 0\n點 O(0, 0)、B(3, 1)、C(1, 3) 在 L 的哪一側？",
			 "plane": _plane([-2, 5], [-3, 4], [_lg(2, -1, -2, "L"), _p("O", 0, 0, 0, [-16, -6]), _p("B", 3, 1), _p("C", 1, 3)]),
			 "steps": [
				_s("走過田埂", "拉動滑桿讓 P 左右移動，看看穿過 L 的時候，2x − y − 2 的值怎麼變。", [["x", -2, 5, 0.5, -1]],
					[{"k": "dot", "p": ["x", "1"], "s": "P", "c": "gold"}],
					"P 穿過 L 時，2x − y − 2 的值由負變正", "", T_SIDE, {"eq": "P({x}, 1)\n2x − y − 2 = {2*x - 3}", "free": true}),
				_c("變號", "P 穿過 L 的時候，2x − y − 2 的值？", ["由負變正（正負號改變）", "一直是正的", "一直是負的", "一直是 0"], 0,
					"在 L 上剛好是 0，越過去就換號。", "看看 P 在 L 左邊、右邊時的數字。", "L 的兩側：2x − y − 2 一邊正、一邊負", T_SIDE),
				_f("代入", "把 O、B、C 代進 2x − y − 2。", "O：[0]，B：[1]，C：[2]", ["-2", "3", "-3"],
					"O：−2，B：6 − 1 − 2 = 3，C：2 − 3 − 2 = −3", "B：2 × 3 − 1 − 2。", T_SIDE),
				_c("同側", "哪兩點在 L 的同一側？", ["O 和 C", "O 和 B", "B 和 C", "三點都在同一側"], 0,
					"O、C 代入都是負的（同號），B 是正的。", "看正負號，同號就同側。", "O、C 同側（負），B 在另一側（正）", T_SIDE),
				_c("回顧", "第三關的渡橋：A(−1, 1)、B(5, 1) 代入 x + y − 4 得 −4、2。A、B 在？", ["L 的兩側（異號）", "L 的同側", "A 在 L 上", "看不出來"], 0,
					"−4 和 2 異號，所以在兩側——和當時看圖的結論一樣。", "−4 和 2 是同號還是異號？", "−4、2 異號 ⇒ A、B 在兩側（和第三關看圖一樣）", T_SIDE),
			 ]},
		 ]},

		{"id": "sidek", "chapter": 1, "type": "forge", "title": "稻草人站哪邊",
		 "story": "稻草人 A 站在田埂的一邊，稻草人 B 的位置還沒決定。要讓 B 站在另一邊，B 要放在哪裡？",
		 "insight": "A、B 在 L 的兩側 ⇔ 代入的值相乘 < 0，同側 ⇔ 相乘 > 0\nL 和 \\ol{AB} 相交（含端點）⇔ 相乘 ≤ 0。",
		 "variants": [
			{"eq": "A(1, 2)、B(3, k)，直線 L：x + y − 4 = 0\nA、B 在 L 的兩側，求 k 的範圍",
			 "plane": _plane([-1, 6], [-4, 6], [_lg(1, 1, -4, "L"), _p("A", 1, 2, 0, [-18, -6]), {"k": "seg", "a": [3, -4], "b": [3, 6], "c": "faint", "dash": true}]),
			 "steps": [
				_f("代入 A", "把 A 代進 x + y − 4。", "1 + 2 − 4 = [0]", ["-1"], "A：1 + 2 − 4 = −1（負的那一側）", "1 + 2 − 4。", T_SIDE),
				_f("代入 B", "把 B 代進 x + y − 4。", "3 + k − 4 = k − [0]", ["1"], "B：k − 1", "3 − 4 = −1。", T_SIDE),
				_c("兩側", "A、B 在兩側，代表兩個值？", ["異號（相乘 < 0）", "同號（相乘 > 0）", "相等", "都是 0"], 0,
					"在兩側：一個正、一個負。", "上一題的結論。", "兩側：(−1)(k − 1) < 0", T_SIDE),
				_f("解", "(−1)(k − 1) < 0，兩邊除以 −1 要變號。", "k − 1 > 0 ⇒ k > [0]", ["1"], "k > 1", "k − 1 > 0。", T_SIDE),
				_c("其他情形", "如果改成「L 和 \\ol{AB} 相交（含端點）」，k 的範圍是？", ["k ≥ 1", "k > 1", "k ≤ 1", "k < 1"], 0,
					"B 在 L 上（k = 1）時也算相交：相乘 ≤ 0。", "端點落在 L 上算不算相交？", "相交（含端點）：(−1)(k − 1) ≤ 0 ⇒ k ≥ 1", T_SIDE),
				_s("驗證", "拉動 k 移動 B，看看 \\ol{AB} 什麼時候會穿過 L。", [["k", -3, 6, 1, -2]],
					[{"k": "seg", "a": ["1", "2"], "b": ["3", "k"], "c": "gold", "dash": true}, {"k": "dot", "p": ["3", "k"], "s": "B", "c": "gold"}],
					"k > 1 時 B 跑到 L 的另一側", "", T_SIDE, {"eq": "B(3, {k})\nk − 1 = {k - 1}", "free": true}),
			 ]},
		 ]},

		{"id": "draw", "chapter": 1, "type": "forge", "title": "點亮半片稻田",
		 "story": "不等式 2x + y ≤ 4 的圖形是田埂一邊的整片稻田。代一個點進去試試，就知道要塗哪一邊。",
		 "insight": "畫 ax + by + c ≤ 0（或 < 0）：先畫邊界（有等號畫實線、沒有等號畫虛線），再代一個不在線上的點（常用原點）決定塗哪一側\ny > mx + k 是直線的上方，y < mx + k 是下方。",
		 "variants": [
			{"eq": "畫出 2x + y ≤ 4 的圖形",
			 "plane": _plane([-3, 5], [-3, 6], [_lg(2, 1, -4, "", 0, "cyan")]),
			 "steps": [
				_c("邊界", "邊界 2x + y = 4 要畫成？", ["實線（有等號，線上的點也算）", "虛線（沒有等號）"], 0,
					"≤ 有等號：線上的點也滿足，畫實線。", "≤ 包不包含等於？", "≤ 有等號：邊界畫實線", T_REG),
				_c("代原點", "原點代入：2 × 0 + 0 ≤ 4 成立嗎？", ["成立，塗原點那一側", "不成立，塗另一側"], 0,
					"0 ≤ 4 成立，原點那一側都滿足。", "0 和 4 比。", "原點：0 ≤ 4 成立 ⇒ 塗原點那一側", T_SIDE),
				_r("塗色", "點一下要塗色的那一側。", [[2, 1, -4, "<="]], ["2x + y ≤ 4"], "2x + y ≤ 4：直線的左下方（含邊界）", "原點那一側。", T_REG),
			 ]},
			{"eq": "畫出 y > 2x − 1 的圖形",
			 "plane": _plane([-3, 4], [-3, 5], [_lg(2, -1, -1, "", 0, "cyan", true)]),
			 "steps": [
				_c("邊界", "邊界 y = 2x − 1 要畫成？", ["虛線（沒有等號）", "實線（有等號）"], 0,
					"> 沒有等號：線上的點不算，畫虛線。", "> 包不包含等於？", "> 沒有等號：邊界畫虛線", T_REG),
				_c("代原點", "原點代入：0 > 2 × 0 − 1 成立嗎？", ["成立（0 > −1）", "不成立"], 0,
					"0 > −1 成立。", "2 × 0 − 1 = −1。", "原點：0 > −1 成立 ⇒ 塗原點那一側", T_SIDE),
				_r("塗色", "點一下要塗色的那一側。", [[2, -1, -1, "<"]], ["y > 2x − 1"], "y > 2x − 1：直線的上方（不含邊界）", "原點那一側。", T_REG),
				_c("上方", "y > 2x − 1 塗的是直線的？", ["上方", "下方", "左方", "右方"], 0,
					"同一個 x，y 比直線上的點大：在直線的上方。", "y 比較大是往上還是往下？", "y > mx + k：直線的上方", T_REG),
			 ]},
		 ]},

		{"id": "system", "chapter": 1, "type": "forge", "title": "四條田埂圍出的田",
		 "story": "四條田埂圍出一塊田。同時滿足四個不等式的地方，就是這塊田。",
		 "insight": "聯立不等式的圖形 = 每一個不等式圖形的共同部分\n頂點是兩條邊界的交點，面積可以切成三角形來算。",
		 "variants": [
			{"eq": "x ≥ 0、y ≥ 0、x + 2y ≤ 8、3x + y ≤ 9\n畫出圖形並求面積",
			 "plane": _plane([-2, 9], [-2, 6], [_lg(1, 2, -8, "L₁", 0, "cyan"), _lg(3, 1, -9, "L₂", 0, "lime")]),
			 "steps": [
				_r("塗色", "四條線把方格切成好幾塊。點出同時滿足四個不等式的那一塊。", quad,
					["x ≥ 0", "y ≥ 0", "x + 2y ≤ 8", "3x + y ≤ 9"], "四個不等式的共同部分：一個四邊形", "原點代進每一個不等式都成立。", T_REG),
				_g("頂點", "L₁ 和 L₂ 交在哪裡？放下這個頂點。", "P", [2, 3], "x + 2y = 8、3x + y = 9 ⇒ P(2, 3)", "第二式乘 2 減第一式：5x = 10。", T_REG),
				_f("面積", "四個頂點 (0, 0)、(3, 0)、(2, 3)、(0, 4)。沿著原點和 P 切成兩個三角形。", "面積 = \\frac{9}{2} + [0] = [1]", ["4", "17/2"],
					"\\frac{1}{2} × 3 × 3 + \\frac{1}{2} × 4 × 2 = \\frac{17}{2}", "兩個三角形的底各是 3 和 4，高各是 3 和 2。", T_APP),
			 ]},
		 ]},

		{"id": "fromgraph", "chapter": 1, "type": "forge", "title": "看圖寫出田界",
		 "story": "三角形的稻田已經畫好了。要寫出它的不等式：先寫三條邊，再拿田裡的一個點決定不等號的方向。",
		 "insight": "由圖寫不等式組：先寫每一條邊的方程式，再代一個區域裡面的點，看是正還是負\n包含邊界用 ≤、≥，不含邊界用 <、>。",
		 "variants": [
			{"eq": "△ABC：A(1, 0)、B(5, 2)、C(1, 4)（包含邊界）\n用聯立不等式表示",
			 "plane": _plane([-1, 7], [-1, 5], [_reg(tri), {"k": "poly", "pts": [[1, 0], [5, 2], [1, 4]], "c": "lime"},
				_p("A", 1, 0, 0, [8, 14]), _p("B", 5, 2), _p("C", 1, 4), _p("", 2, 2, 3, [0, 0], "gold")]),
			 "steps": [
				_f("\\ol{AB}", "寫出直線 AB（過 (1, 0)、(5, 2)）。", "x − [0]y − [1] = 0", ["2", "1"],
					"AB：x − 2y − 1 = 0", "斜率 \\frac{1}{2}：y = \\frac{1}{2}(x − 1)。", T_EQ),
				_f("\\ol{BC}", "寫出直線 BC（過 (5, 2)、(1, 4)）。", "x + [0]y − [1] = 0", ["2", "9"],
					"BC：x + 2y − 9 = 0", "斜率 −\\frac{1}{2}：y − 4 = −\\frac{1}{2}(x − 1)。", T_EQ),
				_f("\\ol{CA}", "寫出直線 CA。", "x = [0]", ["1"], "CA：x = 1", "A、C 的 x 坐標都是 1。", T_EQ),
				_f("代入", "(2, 2) 在三角形裡面，代進前兩條。", "x − 2y − 1 = [0]，x + 2y − 9 = [1]", ["-3", "-3"],
					"(2, 2)：x − 2y − 1 = −3 < 0，x + 2y − 9 = −3 < 0，x = 2 > 1", "2 − 4 − 1、2 + 4 − 9。", T_SIDE),
				_c("不等式組", "△ABC（含邊界）是？", ["x − 2y − 1 ≤ 0、x + 2y − 9 ≤ 0、x ≥ 1", "x − 2y − 1 ≥ 0、x + 2y − 9 ≤ 0、x ≥ 1",
					"x − 2y − 1 ≤ 0、x + 2y − 9 ≥ 0、x ≥ 1", "x − 2y − 1 ≤ 0、x + 2y − 9 ≤ 0、x ≤ 1"], 0,
					"裡面的點代入都是負的，所以都是 ≤ 0，而且 x ≥ 1。", "上一步算出來的正負。", "△ABC：x − 2y − 1 ≤ 0、x + 2y − 9 ≤ 0、x ≥ 1", T_REG),
			 ]},
		 ]},

		{"id": "inside", "chapter": 1, "type": "forge", "title": "走進三角田",
		 "story": "光靈沿著 y = x 的小路走，什麼時候會走進三角形的稻田裡（不碰到田埂）？",
		 "insight": "點在三角形內部（不含邊界）：代入每一條邊，都要和內部的點同號，而且不能是 0\n把點的坐標代進不等式組，解出參數的範圍。",
		 "variants": [
			{"eq": "△ABC：A(1, 0)、B(5, 2)、C(1, 4)\nP(a, a) 在 △ABC 的內部（不含邊界），求 a 的範圍",
			 "plane": _plane([-2, 7], [-2, 5], [_reg(tri), {"k": "poly", "pts": [[1, 0], [5, 2], [1, 4]], "c": "lime"},
				_p("A", 1, 0, 0, [8, 14]), _p("B", 5, 2), _p("C", 1, 4), _ln([0, 0], [1, 1], "", 0, "dim", true)]),
			 "steps": [
				_s("走走看", "拉動 a，讓 P 沿著 y = x 走，看看三個值什麼時候符合三角形的條件。", [["a", -1, 5, 0.5, 4]],
					[{"k": "dot", "p": ["a", "a"], "s": "P", "c": "gold"}], "P 在 1 < a < 3 之間走在田裡", "", T_REG,
					{"eq": "x − 2y − 1 = {-a - 1}\nx + 2y − 9 = {3*a - 9}\nx − 1 = {a - 1}", "free": true}),
				_f("代入", "內部：x − 2y − 1 < 0、x + 2y − 9 < 0、x − 1 > 0。把 P(a, a) 代進去。", "a > [0]，a < [1]，a > [2]", ["-1", "3", "1"],
					"−a − 1 < 0 ⇒ a > −1，3a − 9 < 0 ⇒ a < 3，a − 1 > 0 ⇒ a > 1", "x、y 都換成 a：a − 2a − 1 = −a − 1。", T_REG),
				_f("範圍", "三個條件同時成立。", "[0] < a < [1]", ["1", "3"], "1 < a < 3", "a > −1 和 a > 1 取比較嚴的。", T_REG),
			 ]},
		 ]},

		{"id": "speed1", "chapter": 1, "type": "speed", "title": "正負速算", "time": 120.0,
		 "story": "田裡的螢火蟲一隻一隻飛起來！快速算出代入的值，看牠在田埂的哪一邊。",
		 "insight": "把點代進 ax + by + c：正的在一側、負的在另一側、0 在線上。",
		 "variants": [{"gen": "side", "count": 8}]},

		# ======================= 第二章．稻田的規劃 =======================
		{"id": "coef", "chapter": 2, "type": "forge", "title": "讀出田界的係數",
		 "story": "地圖上已經塗好了 ax + by + 6 ≥ 0 的稻田，可是係數被雨水沖掉了。從圖把 a、b 找回來。",
		 "insight": "由圖反求係數：先由邊界寫出直線（截距式最快），再調成題目要的樣子（例如常數項是 +6）\n最後代一個塗色區域的點，檢查不等號的方向。",
		 "variants": [
			{"eq": "不等式 ax + by + 6 ≥ 0 的圖形如下\n（邊界過 (3, 0)、(0, −2)，塗色的一側包含原點）求 a、b",
			 "plane": _plane([-3, 6], [-4, 4], [_reg([[-2, 3, 6, ">="]]), _ln([3, 0], [0, -2], "", 0, "cyan"),
				_p("(3, 0)", 3, 0, 0, [8, -8], "gold"), _p("(0, −2)", 0, -2, 0, [8, 14], "gold")]),
			 "steps": [
				_f("邊界", "用截距式寫出邊界，再去分母。", "\\frac{x}{3} + \\frac{y}{−2} = 1 ⇒ [0]x − [1]y − 6 = 0", ["2", "3"],
					"邊界：2x − 3y − 6 = 0", "兩邊乘 6：2x − 3y = 6。", T_EQ),
				_f("調常數", "題目是 ax + by + 6，常數項要是 +6：兩邊乘 −1。", "[0]x + [1]y + 6 = 0", ["-2", "3"],
					"−2x + 3y + 6 = 0 ⇒ a = −2、b = 3", "2x − 3y − 6 = 0 每一項都變號。", T_EQ),
				_c("檢查", "原點在塗色的一側。代入 −2x + 3y + 6 得 6，符合 ≥ 0 嗎？", ["符合，a = −2、b = 3", "不符合，要改成 a = 2、b = −3"], 0,
					"6 ≥ 0 成立，方向沒錯。", "6 和 0 比。", "原點：6 ≥ 0 ✓ ⇒ a = −2、b = 3", T_SIDE),
			 ]},
		 ]},

		{"id": "area", "chapter": 2, "type": "forge", "title": "要多大的田",
		 "story": "y ≥ 0、y ≤ x、x + 2y ≤ a 圍出一塊三角形的田。a 越大，田越大。田要剛好 6 平方單位，a 是多少？",
		 "insight": "已知面積反求參數：先用參數表示頂點，再寫出面積的式子\n可以先拉滑桿感覺一下面積怎麼隨著參數變。",
		 "variants": [
			{"eq": "y ≥ 0、y ≤ x、x + 2y ≤ a（a > 0）圍出的面積是 6\n求 a",
			 "plane": _plane([-1, 9], [-1, 5], [_ln([0, 0], [1, 1], "y = x", 0, "dim"), _reg([[0, 1, 0, ">="], [1, -1, 0, ">="], [1, 2, -6, "<="]], 4)]),
			 "steps": [
				_s("拉大拉小", "拉動 a，看看田的面積怎麼變。", [["a", 1, 9, 1, 3]],
					[{"k": "region", "ineq": [["0", "1", "0", ">="], ["1", "-1", "0", ">="], ["1", "2", "-a", "<="]], "c": "lime"}, ["1", "2", "-a", "cyan", ""]],
					"a 越大，田越大（面積和 a^{2} 成正比）", "", T_APP, {"eq": "x + 2y ≤ {a}\n面積 = {a*a/6}", "free": true}),
				_f("頂點", "x + 2y = a 和 y = x 的交點。", "3x = a ⇒ 頂點 (\\frac{a}{[0]}, \\frac{a}{3})", ["3"],
					"另外兩個頂點 (0, 0)、(a, 0)，第三個頂點 (\\frac{a}{3}, \\frac{a}{3})", "y = x 代進 x + 2y = a。", T_APP),
				_f("面積", "底 a、高 \\frac{a}{3}，寫出面積。", "面積 = \\frac{a^{2}}{[0]}", ["6"],
					"面積 = \\frac{1}{2} × a × \\frac{a}{3} = \\frac{a^{2}}{6}", "\\frac{1}{2} × \\frac{1}{3}。", T_APP),
				_f("求 a", "面積是 6。", "a^{2} = [0] ⇒ a = [1]", ["36", "6"],
					"\\frac{a^{2}}{6} = 6 ⇒ a^{2} = 36 ⇒ a = 6（a > 0）", "6 × 6 = 36。", T_APP),
			 ]},
		 ]},

		{"id": "slopereg", "chapter": 2, "type": "forge", "title": "照進田裡的光",
		 "story": "燈柱 P(−1, −2) 射出一道光（直線），要照到四邊形的稻田。光的斜率可以在什麼範圍？",
		 "insight": "過定點 P 的直線和凸多邊形區域有交點：斜率的極端情形發生在區域的頂點\n算出 P 到每個頂點的斜率，取最小到最大（轉動的過程沒有經過鉛直線時）。",
		 "variants": [
			{"eq": "區域 x ≥ 0、y ≥ 0、x + 2y ≤ 8、3x + y ≤ 9（第一章的四邊形）\n過 P(−1, −2)、斜率 m 的直線和區域有交點，求 m 的範圍",
			 "plane": _plane([-2, 8], [-3, 6], [_reg(quad), {"k": "poly", "pts": [[0, 0], [3, 0], [2, 3], [0, 4]], "c": "lime"},
				_p("P", -1, -2, 0, [-16, -6], "gold"), _p("", 3, 0, 0, [0, 0]), _p("", 2, 3, 0, [0, 0]), _p("", 0, 4, 0, [0, 0])]),
			 "steps": [
				_c("極端", "光繞著 P 轉，剛好碰到區域的時候，會碰到區域的？", ["頂點", "某一條邊的中點", "區域的中心", "原點"], 0,
					"區域是凸多邊形，光剛要離開它時，一定擦過一個頂點。", "想像光慢慢轉，最後一刻碰到哪裡？", "極端情形：光經過區域的頂點", T_APP),
				_s("最平", "拉動 m，讓光轉到最平、剛好碰到區域。", [["m", 0, 7, 0.5, 3]], [["m", "-1", "m - 2", "cyan", "L"]],
					"最平：經過 (3, 0)，m = \\frac{0 + 2}{3 + 1} = \\frac{1}{2}", "最平的時候碰到哪一個頂點？", T_APP,
					{"eq": "L：y + 2 = {m}(x + 1)", "goal": {"m": 0.5}, "keep": true}),
				_s("最陡", "再轉到最陡、剛好碰到區域。", [["m", 0, 7, 0.5, 3]], [["m", "-1", "m - 2", "lime", "L"]],
					"最陡：經過 (0, 4)，m = \\frac{4 + 2}{0 + 1} = 6", "最陡的時候碰到哪一個頂點？", T_APP,
					{"eq": "L：y + 2 = {m}(x + 1)", "goal": {"m": 6}, "keep": true}),
				_c("範圍", "m 的範圍是？", ["\\frac{1}{2} ≤ m ≤ 6", "m ≤ \\frac{1}{2} 或 m ≥ 6", "\\frac{1}{2} < m < 6", "\\frac{2}{5} ≤ m ≤ 6"], 0,
					"從最平轉到最陡都碰得到，端點（擦過頂點）也算。", "端點碰到頂點，算不算有交點？", "\\frac{1}{2} ≤ m ≤ 6", T_APP),
			 ]},
		 ]},

		{"id": "pool", "chapter": 2, "type": "forge", "title": "最大的圓形水池",
		 "story": "三角形的稻田 x ≥ 0、y ≥ 0、3x + 4y ≤ 12 裡要挖一個圓形的水池，水池要在田裡，越大越好。",
		 "insight": "三角形區域裡最大的圓 = 內切圓（第三關的內心）\n設圓心 (r, r)，到斜邊的距離也是 r。",
		 "variants": [
			{"eq": "區域 x ≥ 0、y ≥ 0、3x + 4y ≤ 12 裡最大的圓\n求圓心和半徑",
			 "plane": _plane([-1, 6], [-1, 4], [_reg([[1, 0, 0, ">="], [0, 1, 0, ">="], [3, 4, -12, "<="]]), _lg(3, 4, -12, "", 0, "cyan"),
				{"k": "circle", "o": [1, 1], "r": 1.0, "c": "gold", "at": 6}]),
			 "steps": [
				_c("最大的圓", "三角形裡最大的圓是？", ["內切圓（和三邊都相切）", "外接圓", "以原點為圓心的圓", "和斜邊相切、圓心在原點的圓"], 0,
					"圓要整個在三角形裡，越大越好，最後會碰到三條邊：內切圓。", "外接圓會跑出三角形嗎？", "最大的圓 = 內切圓", T_BIS),
				_c("圓心", "內切圓碰到 x 軸、y 軸，圓心可以設成？", ["(r, r)", "(r, 0)", "(0, r)", "(−r, r)"], 0,
					"到兩軸的距離都是 r，而且在第一象限。", "圓心到 x 軸、y 軸多遠？", "設圓心 (r, r)", T_BIS),
				_f("斜邊", "圓心到 3x + 4y − 12 = 0 的距離也是 r。", "\\frac{|7r − 12|}{[0]} = r", ["5"],
					"\\frac{|3r + 4r − 12|}{5} = r", "√(3^{2} + 4^{2})。", T_BIS),
				_fx("解 r", "拿掉絕對值。", "7r − 12 = ±5r ⇒ r = [0] 或 [1]", ["6", "1"], "r = 6 或 1", "2r = 12 或 12r = 12。", T_BIS, [[0, 1]]),
				_c("檢查", "r = 6 時圓心 (6, 6)，在稻田裡嗎？", ["不在，所以 r = 1", "在，所以 r = 6"], 0,
					"3 × 6 + 4 × 6 = 42 > 12，不在區域裡。", "(6, 6) 代進 3x + 4y ≤ 12。", "(6, 6) 不在區域裡 ⇒ r = 1", T_SIDE),
				_g("圓心", "放下水池的圓心。", "O′", [1, 1], "圓心 (1, 1)、半徑 1", "r = 1。", T_BIS),
			 ]},
		 ]},

		{"id": "buy", "chapter": 2, "type": "forge", "title": "市集的買法",
		 "story": "收成之後去市集：橘子每斤 30 元、香瓜每顆 50 元，帶了 300 元，兩種都要買。有幾種買法？",
		 "insight": "格子點應用題：設變數、列不等式組，答案是區域裡的格子點\n一列一列數（固定 y，看 x 可以是幾到幾），最後加起來。",
		 "variants": [
			{"eq": "橘子每斤 30 元、香瓜每顆 50 元，預算 300 元\n兩種都至少買 1（橘子整斤買），有幾種買法？",
			 "plane": _plane([-1, 11], [-1, 7], [_reg(buy), _lg(3, 5, -30, "", 0, "cyan"),
				_row(buy, 1, 2), _row(buy, 2, 3), _row(buy, 3, 4), _row(buy, 4, 4), _row(buy, 5, 4)]),
			 "steps": [
				_c("列式", "買 x 斤橘子、y 顆香瓜，條件是？", ["30x + 50y ≤ 300、x ≥ 1、y ≥ 1", "30x + 50y ≥ 300、x ≥ 1、y ≥ 1",
					"30x + 50y ≤ 300、x ≥ 0、y ≥ 0", "x + y ≤ 300、x ≥ 1、y ≥ 1"], 0,
					"總價不超過 300，兩種都至少 1。", "錢夠不夠：總價和 300 比。都至少買 1。", "30x + 50y ≤ 300 ⇒ 3x + 5y ≤ 30，x ≥ 1，y ≥ 1（整數）", T_APP),
				_f("y = 1", "先看 y = 1：3x + 5 ≤ 30。", "3x ≤ 25 ⇒ x = 1～[0]，共 [1] 種", ["8", "8"], "y = 1：x = 1～8，8 種", "\\frac{25}{3} ≈ 8.3。", T_APP),
				_f("y = 2", "y = 2：3x + 10 ≤ 30。", "3x ≤ [0] ⇒ x 有 [1] 種", ["20", "6"], "y = 2：3x ≤ 20 ⇒ x = 1～6，6 種", "\\frac{20}{3} ≈ 6.7。", T_APP),
				_f("y = 3～5", "y = 3、4、5 也一樣數。", "y = 3：[0] 種，y = 4：[1] 種，y = 5：[2] 種", ["5", "3", "1"],
					"y = 3：3x ≤ 15 ⇒ 5 種，y = 4：3x ≤ 10 ⇒ 3 種，y = 5：3x ≤ 5 ⇒ 1 種", "3x ≤ 15、3x ≤ 10、3x ≤ 5。", T_APP),
				_c("y = 6", "y = 6 呢？", ["0 種", "1 種", "2 種"], 0,
					"5 × 6 = 30，x 至少 1 就超過了。", "3x + 30 ≤ 30，x 最小是 1。", "y = 6：3x ≤ 0，沒有 x ≥ 1 的解", T_APP),
				_f("總共", "把每一列加起來。", "8 + 6 + 5 + 3 + 1 = [0]", ["23"], "共 23 種買法", "每一列的格子點加起來。", T_APP),
			 ]},
		 ]},

		{"id": "speed2", "chapter": 2, "type": "speed", "title": "格子點速算", "time": 150.0,
		 "story": "市集一攤接一攤！快速數出一列有幾個格子點。",
		 "insight": "固定 y，把不等式化成 x ≤ 某個數，x 從 1 數到那個數的整數部分。",
		 "variants": [{"gen": "row", "count": 8}]},
	]
