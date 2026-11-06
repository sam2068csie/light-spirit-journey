extends RefCounted
## 直線與圓 第六大關「割弦漣漪」題庫（對應講義 3-3 重點四：圓與直線的相交情況，加上半圓問題）
##
## 旅程（引擎見 line_level.gd）：
##   forge  一步一步推導：choice、fill、grid、grids（點出幾個點）、slide（滑桿：直線平移、繞著定點轉、點繞著圓走）
##          坐標方格都有交點漣漪（直線碰到圓的地方濺起水花），滑桿的讀數可以顯示交點個數 {#hits}
##   speed  速算：gen = "count"（交點個數）、"chord"（弦長）
##
## 觀念標籤都用 line_ 開頭（名稱寫在 quiz_manager.gd 的 MISTAKE_INFO）。
## 題目的數字都用程式驗算過（scratchpad/c6/verify_c6.py）。不用判別式（使用者 2026/11/07 決定），一律用 d 和 r 比。
## 延後到終焉之塔的題型記在 docs/line_tower_backlog.md。

const SB := preload("res://data/levels/engine/step_bank.gd")
const RADICALS := true

const T_REL := "line_cl_rel"        # 相交情況（d 和 r 比）
const T_CHORD := "line_chord"       # 弦長、弦心距、弦的中點
const T_APP := "line_cl_app"        # 最長最短的弦、最近最遠、面積、半圓
const T_DIST := "line_dist"         # 點到直線距離（第三關也有）


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


## 圓規：三條滑桿調圓心 (h, k) 和半徑 r，也可以在方格上點、拖動圓心。goal = [h, k, r]
##   rg = [[h 最小, h 最大], [k 最小, k 最大], [r 最小, r 最大]]，start = [h, k, r]
static func _compass(name: String, q: String, goal: Array, rg: Array, start: Array, line: String, nudge: String, tag: String,
		traps := [], keep := true, rstep := 1.0) -> Dictionary:
	return _s(name, q, [["h", rg[0][0], rg[0][1], 1, start[0]], ["k", rg[1][0], rg[1][1], 1, start[1]], ["r", rg[2][0], rg[2][1], rstep, start[2]]],
		[{"k": "circle", "o": ["h", "k"], "r": "r", "c": "cyan"}, {"k": "dot", "p": ["h", "k"], "s": "", "c": "cyan"}],
		line, nudge, tag, {"eq": "(x − {h})^{2} + (y − {k})^{2} = {r*r}", "goal": {"h": goal[0], "k": goal[1], "r": goal[2]},
			"drag": ["h", "k"], "keep": keep, "traps": traps})


static func _cir(o: Array, r: float, at := 0, c := "cyan", dash := false) -> Dictionary:
	return {"k": "circle", "o": o, "r": r, "at": at, "c": c, "dash": dash}


## 這一關的坐標方格都會畫交點漣漪
static func _plane(x: Array, y: Array, shapes: Array) -> Dictionary:
	return {"x": x, "y": y, "shapes": shapes, "hits": true}


static func _arc(o: Array, r: float, a0: float, a1: float, at := 0, c := "cyan") -> Dictionary:
	return {"k": "arc", "o": o, "r": r, "a0": a0, "a1": a1, "at": at, "c": c}


## 點出幾個點（交點、端點）
static func _gs(name: String, q: String, targets: Array, line: String, nudge: String, tag: String) -> Dictionary:
	return {"kind": "grids", "name": name, "q": q, "targets": targets, "line": line, "nudge": nudge, "tag": tag}


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
	return [
		# ======================= 第一章．直線和圓的三種關係 =======================
		{"id": "rel", "chapter": 1, "type": "forge", "title": "掃過湖面的光",
		 "story": "一道光（直線）掃過圓形的湖面。碰到湖面兩次、剛好擦過、還是完全碰不到？比一比圓心到直線的距離 d 和半徑 r 就知道。",
		 "insight": "圓心到直線的距離 d、半徑 r：d < r 相割（2 個交點）、d = r 相切（1 個）、d > r 相離（0 個）",
		 "variants": [
			{"eq": "圓 x^{2} + y^{2} = 25、直線 L：3x + 4y = k\nk 是多少時相割、相切、相離？",
			 "plane": _plane([-8, 8], [-7, 7], [_cir([0, 0], 5.0, 0, "cyan"), _p("O", 0, 0, 0, [-16, 16])]),
			 "steps": [
				_s("掃過湖面", "拉動 k 讓光平移。調到右上方、剛好擦過湖面的位置。", [["k", -35, 35, 5, -35]], [["3", "4", "-k", "gold", "L"]],
					"k = 25：剛好相切（只有 1 個交點）", "看右邊的交點個數，什麼時候剛好 1 個？", T_REL,
					{"eq": "3x + 4y = {k}\n交點 {#hits} 個", "goal": {"k": 25}, "keep": true,
					 "traps": [[{"k": -25}, "這也是相切，不過是左下方那一條。調到右上方。"], [{"k": 20}, "還有 2 個交點，再往外推一點。"]]}),
				_f("距離", "圓心 O 到 L 的距離。", "d(O, L) = \\frac{|k|}{[0]}", ["5"], "d(O, L) = \\frac{|k|}{5}", "√(3^{2} + 4^{2})。", T_DIST),
				_f("相切", "相切：d = r。", "\\frac{|k|}{5} = 5 ⇒ k = ±[0]", ["25"], "相切：d = r ⇒ k = ±25", "|k| = 25。", T_REL),
				_c("相割", "相割（2 個交點）時，k 的範圍？", ["|k| < 25", "|k| > 25", "|k| = 25", "k < 25"], 0,
					"d < r：\\frac{|k|}{5} < 5。k < 25 包含 k = −30，那時候是相離。", "d 比 r 小。", "相割：d < r ⇒ |k| < 25", T_REL),
				_c("相離", "相離（沒有交點）時？", ["|k| > 25", "|k| < 25", "|k| = 25", "k > 25"], 0,
					"d > r：\\frac{|k|}{5} > 5。k = −30 也相離，k > 25 漏掉了。", "d 比 r 大，而且 k 可以是負的。", "相離：d > r ⇒ |k| > 25", T_REL),
			 ]},
		 ]},

		{"id": "sep", "chapter": 1, "type": "forge", "title": "碰不到湖的棧道",
		 "story": "新的棧道 3x − 4y + k = 0 不能碰到圓形的湖 (x − 1)^{2} + (y − 2)^{2} = 4。k 要在什麼範圍？",
		 "insight": "相離 ⇔ d(K, L) > r：列出絕對值不等式，拿掉絕對值有兩邊\n端點（d = r）是相切，不算相離。",
		 "variants": [
			{"eq": "圓 (x − 1)^{2} + (y − 2)^{2} = 4 和直線 3x − 4y + k = 0 相離\n求 k 的範圍",
			 "plane": _plane([-4, 7], [-2, 7], [_cir([1, 2], 2.0, 0, "cyan"), _p("K", 1, 2, 0, [-16, -6])]),
			 "steps": [
				_f("距離", "圓心 K(1, 2) 到直線的距離。", "d(K, L) = \\frac{|3 − [0] + k|}{5}", ["8"], "d(K, L) = \\frac{|k − 5|}{5}", "−4 × 2 = −8。", T_DIST),
				_c("相離", "相離的條件是？", ["\\frac{|k − 5|}{5} > 2", "\\frac{|k − 5|}{5} < 2", "\\frac{|k − 5|}{5} = 2", "\\frac{|k − 5|}{5} > 4"], 0,
					"相離：d > r，r = 2。", "d 和 r 比，r 是多少？", "相離：\\frac{|k − 5|}{5} > 2", T_REL),
				_f("解", "|k − 5| > 10，拿掉絕對值。", "k > [0] 或 k < [1]", ["15", "-5"], "k − 5 > 10 或 k − 5 < −10 ⇒ k > 15 或 k < −5", "k − 5 > 10 或 k − 5 < −10。", T_REL),
				_s("驗證", "拉到 k = 15，看看是不是剛好相切（端點）。", [["k", -10, 20, 5, 5]], [["3", "-4", "k", "gold", "L"]],
					"k = 15：剛好相切，所以相離是 k > 15（不含等號）", "k = 15。", T_REL,
					{"eq": "3x − 4y + {k} = 0\n交點 {#hits} 個", "goal": {"k": 15}, "keep": true}),
			 ]},
		 ]},

		{"id": "dist2", "chapter": 1, "type": "forge", "title": "離光線兩步遠的燈",
		 "story": "湖岸（圓）上要放幾盞燈，每一盞都要離光線 L 剛好 2 步遠。可以放幾盞？",
		 "insight": "圓上到 L 距離為 k 的點：在和 L 平行、距離 k 的兩條直線上\n看這兩條線各和圓交幾點（比它們到圓心的距離和 r），加起來。",
		 "variants": [
			{"eq": "圓 x^{2} + y^{2} = 25、直線 L：3x + 4y = 15\n圓上到 L 距離為 2 的點有幾個？",
			 "plane": _plane([-7, 9], [-7, 7], [_cir([0, 0], 5.0, 0, "cyan"), {"k": "line", "abc": [3, 4, -15], "s": "L", "c": "dim", "nohit": true},
				_lg(3, 4, -5, "", 3, "gold", true), _lg(3, 4, -25, "", 3, "gold", true)]),
			 "steps": [
				_f("距離", "先算圓心到 L 的距離。", "d(O, L) = \\frac{15}{5} = [0]", ["3"], "d(O, L) = 3", "√(3^{2} + 4^{2}) = 5。", T_DIST),
				_c("在哪裡", "到 L 距離為 2 的點在哪裡？", ["和 L 平行、距離 2 的兩條直線上", "以 O 為圓心、半徑 2 的圓上", "L 上", "過 O 垂直 L 的直線上"], 0,
					"到一條直線等距的點，排成兩條平行線（兩邊各一條）。", "L 的兩邊各有一條。", "距離 2 的點在 L 兩側的兩條平行線上", T_REL),
				_fx("兩條線", "平行線距離 2：\\frac{|c − 15|}{5} = 2。", "3x + 4y = [0] 或 3x + 4y = [1]", ["5", "25"],
					"3x + 4y = 5、3x + 4y = 25", "c = 15 ± 10。", T_DIST, [[0, 1]]),
				_fx("到圓心", "這兩條線到圓心 O 的距離各是多少？", "[0] 和 [1]", ["1", "5"], "到 O 的距離：1 和 5", "\\frac{5}{5}、\\frac{25}{5}。", T_REL, [[0, 1]]),
				_f("幾個", "距離 1 < 5 相割、距離 5 = 5 相切。一共幾個點？", "共 [0] 個", ["3"], "2 + 1 = 3 個（漣漪就是那 3 盞燈）", "相割 2 個、相切 1 個。", T_REL),
			 ]},
			{"eq": "圓 x^{2} + y^{2} = 25、直線 L：3x + 4y = 15\n圓上到 L 距離為 k 的點恰有 3 個，求 k",
			 "plane": _plane([-7, 9], [-7, 7], [_cir([0, 0], 5.0, 0, "cyan"), {"k": "line", "abc": [3, 4, -15], "s": "L", "c": "dim", "nohit": true},
				{"k": "line", "abc": [3, 4, -25], "at": 3, "until": 4, "c": "gold", "dash": true}, {"k": "line", "abc": [3, 4, -5], "at": 3, "until": 4, "c": "gold", "dash": true},
				{"k": "line", "abc": [3, 4, -55], "at": 4, "c": "gold", "dash": true}, {"k": "line", "abc": [3, 4, 25], "at": 4, "c": "gold", "dash": true}]),
			 "steps": [
				_s("移動", "拉動 k，兩條平行線跟著離 L 越來越遠。看看點數怎麼變。", [["k", 1, 9, 1, 1]],
					[["3", "4", "-(15 + 5*k)", "gold", ""], ["3", "4", "-(15 - 5*k)", "gold", ""]],
					"k 越大，點數 4 → 3 → 2 → 1 → 0", "", T_REL, {"eq": "距離 k = {k}\n圓上有 {#hits} 個點", "free": true}),
				_c("3 個", "恰有 3 個時，是哪一條平行線和圓相切？", ["離圓心比較遠的那一條（3 + k = 5）", "離圓心比較近的那一條（|3 − k| = 5）", "L 本身"], 0,
					"遠的那條相切（1 點）、近的那條相割（2 點）才會是 3 個。近的那條相切時，遠的那條已經碰不到了。", "k = 8 時遠的那條離圓心 11。", "3 個：遠的那條相切（1 點）＋近的那條相割（2 點）", T_REL),
				_f("求 k", "遠的那條到圓心的距離 3 + k = 5。", "k = [0]", ["2"], "3 + k = 5 ⇒ k = 2", "3 + k = 5。", T_REL),
				_c("k = 8", "k = 8 時有幾個點？", ["1 個", "3 個", "2 個", "0 個"], 0,
					"兩條線到圓心的距離是 11 和 |3 − 8| = 5：一條碰不到、一條相切。", "算兩條線到圓心的距離。", "k = 8：距離 11（0 點）、5（相切 1 點），共 1 個", T_REL),
			 ]},
		 ]},

		{"id": "chord", "chapter": 1, "type": "forge", "title": "割出來的弦",
		 "story": "光線割過湖面，在湖上留下一段弦。弦有多長？弦的正中間在哪裡？",
		 "insight": "弦心距 d、半徑 r：(\\frac{弦長}{2})^{2} + d^{2} = r^{2}，弦長 = 2√(r^{2} − d^{2})\n弦的中點 = 圓心在弦上的垂足（圓心和弦中點的連線垂直弦）。",
		 "variants": [
			{"eq": "圓 (x − 1)^{2} + (y + 2)^{2} = 25 被直線 3x + 4y + 20 = 0 截出的弦\n求弦長",
			 "plane": _plane([-7, 8], [-9, 4], [_cir([1, -2], 5.0, 0, "cyan"), _p("K", 1, -2, 0, [8, -6]), _lg(3, 4, 20, "L", 0, "gold"),
				_seg([1, -2], [-0.8, -4.4], 2, "gold", true), {"k": "right", "p": [-0.8, -4.4], "u": [1.8, 2.4], "v": [4, -3], "at": 2}]),
			 "steps": [
				_c("三者的關係", "弦心距 d、半徑 r、半弦長，有什麼關係？", ["(半弦)^{2} + d^{2} = r^{2}", "半弦 + d = r", "(半弦)^{2} = d^{2} + r^{2}", "半弦 = r − d"], 0,
					"圓心、弦的中點、弦的端點圍成直角三角形，斜邊是 r。", "畫出圓心到弦的垂線看看。", "(半弦)^{2} + d^{2} = r^{2}", T_CHORD),
				_f("弦心距", "圓心 K(1, −2) 到弦的距離。", "d(K, L) = \\frac{|3 − [0] + 20|}{5} = [1]", ["8", "3"], "d(K, L) = \\frac{15}{5} = 3", "4 × (−2) = −8。", T_DIST),
				_f("弦長", "用畢氏定理。", "半弦 = √(25 − 9) = [0]，弦長 = [1]", ["4", "8"], "半弦 = 4，弦長 = 8", "√16 = 4。", T_CHORD),
			 ]},
			{"eq": "圓 x^{2} + y^{2} = 25 被直線 x + 2y = 5 截出弦 \\ol{AB}\n求 \\ol{AB} 的中點 M 和弦長",
			 "plane": _plane([-7, 7], [-6, 6], [_cir([0, 0], 5.0, 0, "cyan"), _p("O", 0, 0, 0, [-16, 16]), _lg(1, 2, -5, "", 0, "gold"),
				{"k": "line", "p": [0, 0], "q": [1, 2], "at": 2, "c": "dim", "dash": true, "nohit": true}, _seg([5, 0], [-3, 4], 5, "gold")]),
			 "steps": [
				_c("中點", "弦 \\ol{AB} 的中點 M 和圓心 O 的連線，和弦是什麼關係？", ["\\ol{OM} ⊥ 弦", "\\ol{OM} ∥ 弦", "\\ol{OM} = 弦長", "M 就是 O"], 0,
					"△OAB 是等腰三角形（\\ol{OA} = \\ol{OB}），頂點到底邊中點的線垂直底邊。", "\\ol{OA}、\\ol{OB} 都是半徑。", "\\ol{OM} ⊥ 弦：M 是 O 在弦上的垂足", T_CHORD),
				_f("垂直線", "過 O、垂直 x + 2y = 5 的直線。", "y = [0]x", ["2"], "弦的斜率 −\\frac{1}{2}，垂直線斜率 2：y = 2x", "斜率相乘 −1。", T_CHORD),
				_g("中點 M", "y = 2x 和 x + 2y = 5 的交點就是 M。放下 M。", "M", [1, 2], "x + 4x = 5 ⇒ M(1, 2)", "y = 2x 代進 x + 2y = 5。", T_CHORD),
				_gs("交點", "看漣漪的位置，點出 A、B 兩個交點。", [[5, 0], [-3, 4]], "A(5, 0)、B(−3, 4)，中點 (1, 2) ✓",
					"x = 5 − 2y 代進 x^{2} + y^{2} = 25：y = 0 或 4。", T_CHORD),
				_f("弦長", "算出 \\ol{AB}。", "\\ol{AB} = [0]", ["4√5"], "\\ol{AB} = √(64 + 16) = 4√5（也等於 2√(25 − \\ol{OM}^{2}) = 2√20）",
					"A → B：橫向 8、縱向 4。", T_CHORD),
			 ]},
		 ]},

		{"id": "speed1", "chapter": 1, "type": "speed", "title": "交點速算", "time": 150.0,
		 "story": "一道接一道的光掃過湖面！快速判斷有幾個交點。",
		 "insight": "算 d（圓心到直線的距離）和 r 比：d < r 兩個、d = r 一個、d > r 零個。",
		 "variants": [{"gen": "count", "count": 8}]},

		# ======================= 第二章．弦與距離的應用 =======================
		{"id": "chordk", "chapter": 2, "type": "forge", "title": "要割出多長的弦",
		 "story": "光線要在湖面上割出指定長度的弦。弦長固定，弦心距就固定，再反推直線。",
		 "insight": "已知弦長：半弦^{2} + d^{2} = r^{2} 先求 d，再用點到直線距離公式反求直線\n設斜率時別忘了鉛直線（沒有斜率）。",
		 "variants": [
			{"eq": "直線 3x + 4y + k = 0 被圓 x^{2} + y^{2} = 25 截出的弦長是 8\n求 k",
			 "plane": _plane([-8, 8], [-7, 7], [_cir([0, 0], 5.0, 0, "cyan")]),
			 "steps": [
				_f("弦心距", "半弦是 4。", "d = √(25 − [0]) = [1]", ["16", "3"], "d = √(25 − 16) = 3", "半弦^{2} = 16。", T_CHORD),
				_fx("求 k", "圓心到直線的距離 = 3。", "\\frac{|k|}{5} = 3 ⇒ k = [0] 或 [1]", ["15", "-15"], "|k| = 15 ⇒ k = ±15", "|k| = 15。", T_CHORD, [[0, 1]]),
				_s("第一條", "拉動 k，找出 k 是正的那一條。", [["k", -25, 25, 5, 0]], [["3", "4", "k", "gold", ""]],
					"k = 15：3x + 4y + 15 = 0，弦長 8", "看右邊的弦長。", T_CHORD,
					{"eq": "3x + 4y + {k} = 0\n弦長 ≈ {2*sqrt(25 - pow(k/5, 2))}", "goal": {"k": 15}, "keep": true}),
				_s("第二條", "再找另一條。", [["k", -25, 25, 5, 0]], [["3", "4", "k", "gold", ""]],
					"k = −15：3x + 4y − 15 = 0，弦長也是 8", "另一邊。", T_CHORD,
					{"eq": "3x + 4y + {k} = 0\n弦長 ≈ {2*sqrt(25 - pow(k/5, 2))}", "goal": {"k": -15}, "keep": true}),
			 ]},
			{"eq": "過圓 x^{2} + y^{2} = 25 上一點 P(4, 3)、弦長是 6 的直線\n求這樣的直線",
			 "plane": _plane([-7, 8], [-6, 6], [_cir([0, 0], 5.0, 0, "cyan"), _p("P", 4, 3, 0, [8, -6], "gold"),
				_lg(7, 24, -100, "", 4, "gold"), {"k": "line", "p": [4, 0], "q": [4, 1], "at": 4, "c": "lime"}]),
			 "steps": [
				_f("弦心距", "半弦是 3。", "d = √(25 − 9) = [0]", ["4"], "弦心距 d = 4", "√16。", T_CHORD),
				_c("設直線", "設過 P 的直線 y − 3 = m(x − 4)。這樣設會漏掉哪一條？", ["鉛直線 x = 4", "水平線 y = 3", "過原點的直線", "不會漏掉"], 0,
					"鉛直線沒有斜率，用 m 表示不出來（第三關也遇過）。", "什麼直線沒有斜率？", "設斜率會漏掉鉛直線，最後要另外檢查", T_CHORD),
				_f("解 m", "原點到 mx − y + 3 − 4m = 0 的距離是 4，兩邊平方解 m。", "\\frac{|3 − 4m|}{√(m^{2} + 1)} = 4 ⇒ m = [0]", ["-7/24"],
					"9 − 24m + 16m^{2} = 16m^{2} + 16 ⇒ m = −\\frac{7}{24}：7x + 24y = 100", "m^{2} 兩邊消掉：−24m = 7。", T_CHORD),
				_f("鉛直線", "檢查 x = 4。", "x = 4 到原點的距離 = [0]", ["4"], "x = 4 的距離也是 4：也是答案（弦是 (4, ±3)）", "原點到 x = 4。", T_CHORD),
				_c("幾條", "這樣的直線一共幾條？", ["2 條", "1 條", "3 條", "4 條"], 0,
					"7x + 24y = 100 和 x = 4。", "別漏了鉛直線。", "共 2 條：7x + 24y = 100、x = 4", T_CHORD),
			 ]},
		 ]},

		{"id": "midchord", "chapter": 2, "type": "forge", "title": "知道弦的中點",
		 "story": "湖面上有一段弦，只知道它的正中間是 M(3, 2)。這段弦在哪一條直線上？",
		 "insight": "已知弦的中點 M：圓心 K 和 M 的連線垂直弦\n弦的斜率 = −\\frac{1}{m_{KM}}，再用點斜式過 M。",
		 "variants": [
			{"eq": "圓 (x − 1)^{2} + (y − 1)^{2} = 25 的一條弦，中點是 M(3, 2)\n求這條弦所在的直線",
			 "plane": _plane([-5, 7], [-5, 7], [_cir([1, 1], 5.0, 0, "cyan"), _p("K", 1, 1, 0, [-18, -6]), _p("M", 3, 2, 0, [8, -6], "gold"),
				_seg([1, 1], [3, 2], 0, "dim", true), _lg(2, 1, -8, "", 3, "gold")]),
			 "steps": [
				_c("垂直", "\\ol{KM} 和弦是什麼關係？", ["垂直", "平行", "重合", "夾 45°"], 0,
					"圓心到弦中點的連線垂直弦。", "上一章「割出來的弦」。", "\\ol{KM} ⊥ 弦", T_CHORD),
				_f("斜率", "先算 m_{KM}，再寫出弦的斜率。", "m_{KM} = [0]，弦的斜率 = [1]", ["1/2", "-2"], "m_{KM} = \\frac{1}{2} ⇒ 弦的斜率 −2", "垂直：倒數再變號。", T_CHORD),
				_f("弦", "過 M(3, 2)、斜率 −2。", "y − 2 = −2(x − 3) ⇒ 2x + y = [0]", ["8"], "弦：2x + y = 8", "y = −2x + 8。", T_CHORD),
				_gs("驗證", "點出弦的兩個端點（漣漪的位置），看看 M 是不是中點。", [[1, 6], [5, -2]], "端點 (1, 6)、(5, −2)，中點 (3, 2) ✓",
					"y = 8 − 2x 代進圓：x = 1 或 5。", T_CHORD),
			 ]},
		 ]},

		{"id": "longest", "chapter": 2, "type": "forge", "title": "繞著燈柱轉的光",
		 "story": "湖裡有一根燈柱 P(2, 1)，光線繞著它轉，在湖面上割出長長短短的弦。最長、最短各是多少？",
		 "insight": "過圓內一點 P 的弦：最長的是直徑（過圓心）、最短的是垂直 \\ol{OP} 的弦\n最短的弦：弦心距 = \\ol{OP}，長 2√(r^{2} − \\ol{OP}^{2})。",
		 "variants": [
			{"eq": "圓 x^{2} + y^{2} = 25 內一點 P(2, 1)\n過 P 的弦，最長、最短各是多少？",
			 "plane": _plane([-7, 7], [-6, 6], [_cir([0, 0], 5.0, 0, "cyan"), _p("O", 0, 0, 0, [-16, 16]), _p("P", 2, 1, 0, [8, -6], "gold"),
				_seg([0, 0], [2, 1], 0, "dim", true), _lg(2, 1, -5, "", 3, "gold")]),
			 "steps": [
				_s("轉轉看", "拉動滑桿讓光繞著 P 轉（t 是光和 \\ol{OP} 的夾角），看看弦長怎麼變。", [["t", 0, 180, 15, 30]],
					[["sin(t*PI/180 + atan(0.5))", "-cos(t*PI/180 + atan(0.5))", "cos(t*PI/180 + atan(0.5)) - 2*sin(t*PI/180 + atan(0.5))", "gold", ""]],
					"弦長在 4√5 ≈ 8.94 到 10 之間變化", "", T_APP,
					{"eq": "和 \\ol{OP} 夾 {t}°\n弦長 ≈ {2*sqrt(25 - pow(cos(t*PI/180 + atan(0.5)) - 2*sin(t*PI/180 + atan(0.5)), 2))}", "free": true}),
				_c("最長", "最長的弦是？", ["過圓心的直徑，長 10", "垂直 \\ol{OP} 的弦，長 10", "水平的弦，長 10", "鉛直的弦，長 10"], 0,
					"直徑是圓裡最長的弦，過 P 也過 O 的那一條就是。", "圓裡最長的弦是什麼？", "最長：過 O 的直徑，長 10", T_APP),
				_c("最短", "最短的弦和 \\ol{OP} 是什麼關係？", ["垂直", "平行", "重合", "夾 45°"], 0,
					"弦心距越大弦越短。過 P 的弦，弦心距最大就是 \\ol{OP}，這時弦垂直 \\ol{OP}。", "弦心距最大是多少？", "最短：垂直 \\ol{OP} 的弦（弦心距 = \\ol{OP}）", T_APP),
				_f("最短的弦", "垂直 \\ol{OP}（斜率 \\frac{1}{2}）、過 P。", "2x + y = [0]", ["5"], "最短的弦：2x + y = 5", "斜率 −2，過 (2, 1)。", T_APP),
				_gs("端點", "點出最短的弦的兩個端點。", [[0, 5], [4, -3]], "端點 (0, 5)、(4, −3)", "y = 5 − 2x 代進圓：x = 0 或 4。", T_APP),
				_f("最短", "算出最短的弦長。", "最短 = [0]", ["4√5"], "\\ol{OP} = √5：2√(25 − 5) = 4√5", "2√(r^{2} − \\ol{OP}^{2})。", T_APP),
			 ]},
		 ]},

		{"id": "far", "chapter": 2, "type": "forge", "title": "離岸最遠的燈",
		 "story": "湖岸（圓）上的燈要照到遠方的棧道（直線）。哪一盞離棧道最近？哪一盞最遠？",
		 "insight": "圓和直線相離：圓上的點到直線，最近 d − r、最遠 d + r\n最近、最遠的點都在過圓心垂直直線的那條線上。",
		 "variants": [
			{"eq": "圓 x^{2} + y^{2} = 25、直線 L：3x + 4y = 35\n圓上的點到 L 最近、最遠多遠？是哪兩點？",
			 "plane": _plane([-7, 10], [-6, 9], [_cir([0, 0], 5.0, 0, "cyan"), _p("O", 0, 0, 0, [-16, 16]), _lg(3, 4, -35, "L", 0, "gold"),
				{"k": "line", "p": [0, 0], "q": [3, 4], "at": 2, "c": "dim", "dash": true, "nohit": true}]),
			 "steps": [
				_s("繞一圈", "拉動滑桿讓燈 Q 繞著湖岸走，看看 Q 到 L 的距離怎麼變。", [["t", 0, 360, 15, 180]],
					[{"k": "dot", "p": ["5*cos(t*PI/180)", "5*sin(t*PI/180)"], "s": "Q", "c": "gold"}],
					"Q 在 O 和 L 之間的那條垂線上時最近、最遠", "", T_APP,
					{"eq": "d(Q, L) ≈ {abs(15*cos(t*PI/180) + 20*sin(t*PI/180) - 35) / 5}", "free": true}),
				_f("距離", "圓心到 L 的距離。", "d(O, L) = [0]", ["7"], "d(O, L) = \\frac{35}{5} = 7 > 5：相離", "\\frac{35}{5}。", T_DIST),
				_f("最近最遠", "最近、最遠各是多少？", "最近 = [0]，最遠 = [1]", ["2", "12"], "最近 7 − 5 = 2、最遠 7 + 5 = 12", "d − r、d + r。", T_APP),
				_g("最近的點", "最近的點在 O 往 L 垂直走 5 的地方。放下這一點。", "Q₁", [3, 4], "最近：Q₁(3, 4)", "方向 (3, 4)，長度剛好 5。", T_APP,
					[[-3, -4, "這是最遠的那一點。"]]),
				_g("最遠的點", "最遠的點在反方向。放下這一點。", "Q₂", [-3, -4], "最遠：Q₂(−3, −4)", "(3, 4) 的對面。", T_APP),
			 ]},
			{"eq": "直線 3x + 4y = 12 和兩軸交於 A、B，P 在圓 x^{2} + (y + 2)^{2} = 4 上\n求 △PAB 面積的最大值",
			 "plane": _plane([-4, 6], [-5, 4], [_cir([0, -2], 2.0, 0, "cyan"), _p("K", 0, -2, 0, [8, 4]), _lg(3, 4, -12, "", 0, "gold"),
				_p("A", 4, 0, 0, [6, 16]), _p("B", 0, 3, 0, [8, -4]),
				{"k": "poly", "pts": [[4, 0], [0, 3], [-1.2, -3.6]], "c": "gold", "fill": "orange", "alpha": 0.18, "at": 3},
				_p("P", -1.2, -3.6, 3, [-16, 12], "gold")]),
			 "steps": [
				_f("底", "\\ol{AB} 是固定的底。", "\\ol{AB} = [0]", ["5"], "A(4, 0)、B(0, 3)：\\ol{AB} = 5", "3、4、5。", T_APP),
				_f("圓心", "圓心 K(0, −2) 到直線的距離。", "d(K, L) = \\frac{|0 − 8 − 12|}{5} = [0]", ["4"], "d(K, L) = 4 > 2：相離", "|−20| = 20。", T_DIST),
				_c("最高", "P 在圓上，P 到直線的距離最大是？", ["d(K, L) + r = 6", "d(K, L) − r = 2", "d(K, L) = 4", "r = 2"], 0,
					"P 在圓上離直線最遠的地方：d + r。", "上一題的最遠。", "高最大 = 4 + 2 = 6", T_APP),
				_f("面積", "面積最大是？", "\\frac{1}{2} × 5 × [0] = [1]", ["6", "15"], "△PAB 面積最大 = \\frac{1}{2} × 5 × 6 = 15", "\\frac{1}{2} × 底 × 高。", T_APP),
			 ]},
		 ]},

		{"id": "semi", "chapter": 2, "type": "forge", "title": "半圓形的拱橋",
		 "story": "湖邊有一座半圓形的拱橋，一道光從 (0, 4) 斜斜照下來。光要碰到拱橋兩次，斜率 m 要在什麼範圍？",
		 "insight": "√(x(4 − x)) = mx + 4 的實根 = 上半圓和直線的交點\n找臨界情形：相切（d = r）、經過半圓的端點，再看端點有沒有等號。",
		 "variants": [
			{"eq": "√(x(4 − x)) = mx + 4 有兩個相異實根\n求 m 的範圍",
			 "plane": _plane([-1, 6], [-1, 5], [_arc([2, 0], 2.0, 0, 180, 0, "cyan"), {"k": "seg", "a": [0, 0], "b": [4, 0], "c": "faint", "dash": true, "nohit": true},
				_p("", 0, 4, 0, [8, -6], "gold"), _p("", 0, 0, 0, [0, 0]), _p("", 4, 0, 0, [0, 0]),
				_lg(-0.75, -1, 4, "", 4, "gold", true), _lg(-1, -1, 4, "", 5, "gold")]),
			 "steps": [
				_c("左邊", "y = √(x(4 − x)) 的圖形是？", ["上半圓 (x − 2)^{2} + y^{2} = 4（y ≥ 0）", "整個圓 (x − 2)^{2} + y^{2} = 4", "下半圓", "拋物線"], 0,
					"兩邊平方：y^{2} = 4x − x^{2} ⇒ (x − 2)^{2} + y^{2} = 4，而且根號一定 ≥ 0。", "平方前 y 會是負的嗎？", "y = √(x(4 − x))：上半圓 (x − 2)^{2} + y^{2} = 4（y ≥ 0）", T_APP),
				_c("右邊", "y = mx + 4 的圖形是？", ["過 (0, 4) 的直線", "過原點的直線", "斜率 4 的直線", "水平線"], 0,
					"x = 0 時 y = 4，m 改變時繞著 (0, 4) 轉。", "x = 0 代進去。", "y = mx + 4：繞著 (0, 4) 轉的直線", T_APP),
				_s("轉轉看", "拉動 m，看看光和半圓有幾個交點。", [["m", -2, 0, 0.125, -0.25]], [["m", "-1", "4", "gold", ""]],
					"m 從 0 往下：0 個 → 相切 1 個 → 2 個 → 過端點 (4, 0) 之後 1 個", "", T_APP, {"eq": "y = {m}x + 4\n交點 {#hits} 個", "free": true}),
				_f("相切", "圓心 (2, 0) 到直線 mx − y + 4 = 0 的距離 = 2。", "\\frac{|2m + 4|}{√(m^{2} + 1)} = 2 ⇒ m = [0]", ["-3/4"],
					"(2m + 4)^{2} = 4(m^{2} + 1) ⇒ 16m = −12 ⇒ m = −\\frac{3}{4}", "m^{2} 兩邊消掉：16m + 16 = 4。", T_APP),
				_f("端點", "經過半圓的右端點 (4, 0) 時。", "m = [0]", ["-1"], "過 (4, 0)：0 = 4m + 4 ⇒ m = −1（還經過 (2, 2)，兩個交點）", "0 = 4m + 4。", T_APP),
				_c("範圍", "兩個相異實根時，m 的範圍？", ["−1 ≤ m < −\\frac{3}{4}", "−1 < m < −\\frac{3}{4}", "−1 < m ≤ −\\frac{3}{4}", "m < −\\frac{3}{4}"], 0,
					"m = −1 時交於 (4, 0)、(2, 2)，兩個根都算，要包含。m = −\\frac{3}{4} 相切只有一個根，不包含。", "兩個端點各有幾個交點？", "−1 ≤ m < −\\frac{3}{4}", T_APP),
			 ]},
		 ]},

		{"id": "speed2", "chapter": 2, "type": "speed", "title": "弦長速算", "time": 150.0,
		 "story": "光線一道接一道割過湖面！快速算出弦長。",
		 "insight": "弦長 = 2√(r^{2} − d^{2})。常見的組合：r = 5 時 d = 3、4，r = 13 時 d = 5、12。",
		 "variants": [{"gen": "chord", "count": 6}]},
	]
