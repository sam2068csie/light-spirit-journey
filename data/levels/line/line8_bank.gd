extends RefCounted
## 直線與圓 第八大關「軌跡星環」題庫（對應講義 3-3 重點二：圓系、重點三：軌跡，加上公切線）
##
## 旅程（引擎見 line_level.gd）：
##   forge  一步一步推導：choice、fill、grid、grids、slide
##          滑桿：拉 k 看一整族圓（圓系）都繞著同兩個點轉、k = −1 時變成公共弦（"when" 圖層）
##                讓動點走一圈，留下光的足跡（"trail"），連起來是一個圓
##          坐標方格都有交點漣漪＋切點燈（公切線剛好碰到兩個圓時，兩盞燈一起亮）
##   speed  速算：gen = "chord"（兩圓的公共弦）、"mid"（中點的軌跡：圓心、半徑）
##
## 使用者 2026/11/07 的決定：公切線、圓系都放 C8。不收圓冪（課綱刪掉了）。
## 觀念標籤都用 line_ 開頭（名稱寫在 quiz_manager.gd 的 MISTAKE_INFO）。
## 題目的數字都用程式驗算過（scratchpad/c8/verify_c8.py）。延後到終焉之塔的題型記在 docs/line_tower_backlog.md。

const SB := preload("res://data/levels/engine/step_bank.gd")
const RADICALS := true

const T_FAM := "line_family"        # 圓系、公共弦、公切線
const T_LOC := "line_locus"         # 軌跡方程式
const T_FIND := "line_circle_find"  # 求圓（第五關也有）
const T_TAN := "line_tan_ext"       # 圓外一點的切線（第七關也有）



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
	return {"x": x, "y": y, "shapes": shapes, "hits": true, "lamps": true}


## 會動的點（trail：走過的地方留下足跡）
static func _dd(px: String, py: String, s := "", c := "gold", trail := false) -> Dictionary:
	return {"k": "dot", "p": [px, py], "s": s, "c": c, "trail": trail}


## 空心的點（軌跡要拿掉的點）
static func _hole(x: float, y: float, at := 0, c := "orange") -> Dictionary:
	return {"k": "dot", "p": [x, y], "s": "", "at": at, "c": c, "hole": true}


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
		# ======================= 第一章．圓系與兩個圓 =======================
		{"id": "family", "chapter": 1, "type": "forge", "title": "繞著兩點轉的圓",
		 "story": "直線 L 和圓 C 交於兩點。過這兩點的圓有一整族，怎麼一次寫出？",
		 "insight": "過圓 C = 0 和直線 L = 0 交點的圓：C + kL = 0（k 是常數）\n在交點上 C = 0、L = 0，所以 C + kL = 0 一定成立。再代一個點求 k。",
		 "variants": [
			{"eq": "過圓 C：x^{2} + y^{2} − 25 = 0 和直線 L：x − y + 1 = 0 的交點，而且過 Q(4, 1) 的圓\n求這個圓",
			 "plane": _plane([-8, 7], [-6, 7], [_cir([0, 0], 5.0, 0, "dim"), _lg(1, -1, 1, "L", 0, "dim"), _p("Q", 4, 1, 0, [8, -6], "gold"),
				_cir([-1, 1], 5.0, 4, "cyan")]),
			 "steps": [
				_s("拉拉看", "拉動 k，看看 C + kL = 0 的圓怎麼變。", [["k", -4, 4, 1, -3]],
					[{"k": "circle", "o": ["-k/2", "k/2"], "r": "sqrt(k*k/2 - k + 25)", "c": "violet"}],
					"k 改變，圓跟著變，但一直經過同兩個點", "", T_FAM, {"eq": "x^{2} + y^{2} − 25 + k(x − y + 1) = 0\nk = {k}", "free": true}),
				_c("為什麼", "為什麼每一個 C + kL = 0 的圓都經過 C 和 L 的交點？", ["交點上 C = 0、L = 0，代進去一定是 0", "因為 k 是整數", "因為圓心都在 L 上", "因為半徑都一樣"], 0,
					"交點同時在圓上（C = 0）和直線上（L = 0），所以 C + kL = 0 + k × 0 = 0。半徑會變，圓心也不在 L 上。", "交點代進 C、L 各是多少？", "交點上 C = 0、L = 0 ⇒ C + kL = 0", T_FAM),
				_f("求 k", "Q(4, 1) 代進 x^{2} + y^{2} − 25 + k(x − y + 1) = 0。", "16 + 1 − 25 + k(4 − 1 + 1) = 0 ⇒ k = [0]", ["2"],
					"−8 + 4k = 0 ⇒ k = 2", "−8 + 4k = 0。", T_FAM),
				_f("圓", "k = 2 代回去，展開整理。", "x^{2} + y^{2} + [0]x − [1]y − 23 = 0", ["2", "2"],
					"x^{2} + y^{2} + 2x − 2y − 23 = 0，也就是 (x + 1)^{2} + (y − 1)^{2} = 25", "x^{2} + y^{2} − 25 + 2x − 2y + 2 = 0。", T_FAM),
			 ]},
		 ]},

		{"id": "chord2", "chapter": 1, "type": "forge", "title": "兩個星環的交點",
		 "story": "兩個星環 C₁、C₂ 交於兩點。把兩個方程式相減會得到什麼？",
		 "insight": "過兩圓交點的圓：C₁ + kC₂ = 0\nk = −1（兩式相減）時 x^{2}、y^{2} 消掉，變成兩交點所在的直線，也就是公共弦。",
		 "variants": [
			{"eq": "C₁：x^{2} + y^{2} + 2x − 4y − 4 = 0、C₂：x^{2} + y^{2} − 2x − 4 = 0\n求公共弦，再求過兩交點、圓心在 y 軸上的圓",
			 "plane": _plane([-5, 5], [-4, 6], [_cir([-1, 2], 3.0, 0, "dim"), _cir([1, 0], sqrt(5.0), 0, "dim"),
				_lg(1, -1, 0, "", 3, "gold"), _cir([0, 1], sqrt(5.0), 6, "cyan")]),
			 "steps": [
				_s("拉拉看", "拉動 k，看看 C₁ + kC₂ = 0 怎麼變。拉到 k = −1 的時候呢？", [["k", -3, 3, 0.5, 0.5]],
					[{"k": "circle", "o": ["(k - 1)/(1 + k)", "2/(1 + k)"], "r": "sqrt(pow((k - 1)/(1 + k), 2) + pow(2/(1 + k), 2) + 4)", "c": "violet"},
					 {"abc": ["1", "-1", "0"], "c": "gold", "when": "abs(k + 1) < 0.001"}],
					"每一個圓都經過兩個交點，k = −1 時變成一條直線", "", T_FAM, {"eq": "C₁ + kC₂ = 0\nk = {k}", "free": true}),
				_c("k = −1", "k = −1（C₁ − C₂ = 0）時，圖形是什麼？", ["過兩個交點的直線（公共弦所在的直線）", "一個比較小的圓", "一個點", "沒有圖形"], 0,
					"x^{2}、y^{2} 的係數相減變成 0，剩下一次式，是直線。兩個交點代進去還是 0，所以直線過兩個交點。", "相減之後 x^{2} 還在嗎？", "C₁ − C₂ = 0：公共弦所在的直線", T_FAM),
				_f("公共弦", "C₁ − C₂，整理。", "公共弦：[0]x − [1]y = 0", ["4", "4"], "公共弦：4x − 4y = 0，也就是 x − y = 0", "2x − (−2x) = 4x，−4y − 0 = −4y。", T_FAM, "prop"),
				_gs("交點", "公共弦 y = x 代回 C₂，點出兩個交點。", [[2, 2], [-1, -1]], "交點 (2, 2)、(−1, −1)", "2x^{2} − 2x − 4 = 0 ⇒ x = 2 或 −1。", T_FAM),
				_f("求 k", "C₁ + kC₂ = 0 的圓心是 (\\frac{k − 1}{1 + k}, \\frac{2}{1 + k})。圓心在 y 軸上，k 是多少？", "\\frac{k − 1}{1 + k} = 0 ⇒ k = [0]", ["1"],
					"圓心的 x 坐標 = 0 ⇒ k = 1", "分子 = 0。", T_FAM),
				_f("圓", "k = 1：C₁ + C₂ = 0，除以 2 再配方。", "x^{2} + (y − [0])^{2} = [1]", ["1", "5"],
					"2x^{2} + 2y^{2} − 4y − 8 = 0 ⇒ x^{2} + (y − 1)^{2} = 5", "x^{2} + y^{2} − 2y − 4 = 0。", T_FIND),
			 ]},
		 ]},

		{"id": "cotan", "chapter": 1, "type": "forge", "title": "同時擦過兩個星環的光",
		 "story": "兩圓的兩條外公切線交於 P。P 在哪裡？切線是哪兩條？",
		 "insight": "外公切線的交點 P 在連心線上，而且 \\ol{PK₁} : \\ol{PK₂} = r₁ : r₂（兩個直角三角形相似）\n找到 P 之後，就是圓外一點的切線（第七關）。",
		 "variants": [
			{"eq": "C₁：(x + 1)^{2} + y^{2} = 1、C₂：(x − 3)^{2} + (y − 2)^{2} = 9\n求兩條外公切線的交點 P 和外公切線",
			 "plane": _plane([-5, 7], [-3, 6], [_cir([-1, 0], 1.0, 0, "cyan"), _cir([3, 2], 3.0, 0, "cyan"), _p("K₁", -1, 0, 0, [-8, -12]), _p("K₂", 3, 2, 0, [8, -6]),
				{"k": "line", "p": [-1, 0], "q": [3, 2], "at": 1, "c": "dim", "dash": true, "nohit": true},
				_lg(0, 1, 1, "", 6, "gold"), _lg(4, -3, 9, "", 6, "gold")]),
			 "steps": [
				_c("在哪條線上", "兩條外公切線的交點 P 在哪一條線上？", ["連心線 K₁K₂", "x 軸", "公共弦", "過 K₁ 的鉛直線"], 0,
					"整個圖對連心線對稱：兩條外公切線對稱，交點就在對稱軸（連心線）上。", "整個圖對哪一條線對稱？", "P 在連心線 K₁K₂ 上", T_FAM),
				_f("比例", "兩個直角三角形相似：\\ol{PK₁} : \\ol{PK₂} = r₁ : r₂ = 1 : 3，所以 \\ol{PK₂} = 3\\ol{PK₁}。",
					"\\ol{K₁K₂} = \\ol{PK₂} − \\ol{PK₁} = [0]\\ol{PK₁}", ["2"], "\\ol{K₁K₂} = 2\\ol{PK₁}：P 在 K₁ 外側，距離是 \\ol{K₁K₂} 的一半", "3 − 1 = 2。", T_FAM),
				_g("P", "K₁ → K₂ 是 (4, 2)。從 K₁ 往反方向走一半，放下 P。", "P", [-3, -1], "P = K₁ − (2, 1) = (−3, −1)", "(−1, 0) − (2, 1)。", T_FAM,
					[[1, 1, "這是 K₁、K₂ 的中點，P 要在兩個圓的外面。"]]).merged({"off": [-70, 14]}),
				_s("轉轉看", "拉動 m 讓光繞著 P 轉，找出同時擦過兩個星環的位置（兩盞燈一起亮）。", [["m", -1, 2, 1.0 / 3.0, 1.0 / 3.0]],
					[["m", "-1", "3*m - 1", "gold", ""]],
					"m = 0、\\frac{4}{3} 時兩盞燈一起亮", "", T_TAN, {"eq": "y + 1 = m(x + 3)，m = {m}\n交點 {#hits} 個", "free": true}),
				_fx("解 m", "L：mx − y + 3m − 1 = 0。用 d(K₁, L) = 1 列式，平方整理得 3m^{2} − 4m = 0。", "m = [0] 或 [1]", ["0", "4/3"],
					"m(3m − 4) = 0 ⇒ m = 0 或 \\frac{4}{3}", "提出 m。", T_TAN, [[0, 1]]),
				_f("公切線", "代回 y + 1 = m(x + 3)，整理。", "y = [0]、4x − 3y + [1] = 0", ["-1", "9"],
					"外公切線：y = −1、4x − 3y + 9 = 0（d(K₂, L) 也剛好是 3，四盞燈都亮了）", "m = \\frac{4}{3}：3y + 3 = 4x + 12。", T_FAM),
			 ]},
		 ]},

		{"id": "speed1", "chapter": 1, "type": "speed", "title": "公共弦速算", "time": 150.0,
		 "story": "星環一對接一對！快速寫出兩圓的公共弦。",
		 "insight": "兩個一般式相減（x^{2}、y^{2} 消掉），化成最簡就是公共弦所在的直線。",
		 "variants": [{"gen": "chord", "count": 6}]},

		# ======================= 第二章．留下足跡的星 =======================
		{"id": "mid", "chapter": 2, "type": "forge", "title": "中點的足跡",
		 "story": "P 在圓上走，A 固定。\\ol{AP} 的中點 M 的軌跡是什麼？",
		 "insight": "求軌跡：設動點 (x, y)，用 x、y 表示已知的動點 P，再代進 P 滿足的式子\n中點軌跡：P = (2x − a, 2y − b)。",
		 "variants": [
			{"eq": "A(6, 0)，P 在圓 x^{2} + y^{2} = 4 上走\n求 \\ol{AP} 的中點 M 的軌跡",
			 "plane": _plane([-3, 7], [-3, 3], [_cir([0, 0], 2.0, 0, "dim"), _p("A", 6, 0, 0, [8, -6], "gold"), _cir([3, 0], 1.0, 4, "cyan")]),
			 "steps": [
				_s("走一圈", "拉動滑桿讓 P 繞一圈，看看 M 留下的足跡。", [["t", 0, 360, 15, 90]],
					[{"k": "seg", "a": ["6", "0"], "b": ["2*cos(t*PI/180)", "2*sin(t*PI/180)"], "c": "dim"},
					 _dd("2*cos(t*PI/180)", "2*sin(t*PI/180)", "P", "text"), _dd("3 + cos(t*PI/180)", "sin(t*PI/180)", "M", "gold", true)],
					"M 的足跡圍成一個小圓", "", T_LOC, {"eq": "P 走了 {t}°", "free": true}),
				_f("設 M", "設 M(x, y)。M 是 \\ol{AP} 的中點，用 x、y 表示 P。", "P = ([0]x − [1], [2]y)", ["2", "6", "2"],
					"x = \\frac{6 + p}{2} ⇒ P = (2x − 6, 2y)", "中點公式反過來：P = 2M − A。", T_LOC),
				_f("代入", "P 在 x^{2} + y^{2} = 4 上：(2x − 6)^{2} + (2y)^{2} = 4，兩邊除以 4。", "(x − 3)^{2} + y^{2} = [0]", ["1"],
					"(x − 3)^{2} + y^{2} = 1", "4(x − 3)^{2} + 4y^{2} = 4。", T_LOC),
				_f("足跡", "M 的軌跡是什麼圓？", "圓心 ([0], 0)，半徑 [1]", ["3", "1"], "軌跡：圓心 (3, 0)、半徑 1 的圓（足跡連起來了）", "(x − 3)^{2} + y^{2} = 1^{2}。", T_LOC),
			 ]},
		 ]},

		{"id": "centroid", "chapter": 2, "type": "forge", "title": "重心的足跡",
		 "story": "A 是圓心，B 固定，P 在圓上走。△ABP 的重心 G 的軌跡？哪裡要小心？",
		 "insight": "重心軌跡：G = \\frac{A + B + P}{3} ⇒ P = 3G − A − B，再代進 P 的式子\nA、B、P 共線時不是三角形，那兩點要從軌跡拿掉。",
		 "variants": [
			{"eq": "圓 C：(x + 3)^{2} + (y − 1)^{2} = 9 的圓心是 A，B(3, 1)，P 在 C 上\n求 △ABP 的重心 G 的軌跡",
			 "plane": _plane([-7, 4], [-3, 5], [_cir([-3, 1], 3.0, 0, "dim"), _p("A", -3, 1, 0, [-8, 18]), _p("B", 3, 1, 0, [8, -6], "gold"),
				_seg([-3, 1], [3, 1], 0, "dim"), _cir([-1, 1], 1.0, 3, "cyan"), _hole(0, 1, 5), _hole(-2, 1, 5)]),
			 "steps": [
				_s("走一圈", "拉動滑桿讓 P 繞著星環走，看看重心 G 的足跡。", [["t", 0, 360, 15, 90]],
					[{"k": "seg", "a": ["-3", "1"], "b": ["-3 + 3*cos(t*PI/180)", "1 + 3*sin(t*PI/180)"], "c": "dim"},
					 {"k": "seg", "a": ["3", "1"], "b": ["-3 + 3*cos(t*PI/180)", "1 + 3*sin(t*PI/180)"], "c": "dim"},
					 _dd("-3 + 3*cos(t*PI/180)", "1 + 3*sin(t*PI/180)", "P", "text"), _dd("-1 + cos(t*PI/180)", "1 + sin(t*PI/180)", "G", "gold", true)],
					"G 的足跡也圍成一個小圓", "", T_LOC, {"eq": "P 走了 {t}°", "free": true}),
				_f("設 G", "設 G(x, y)。x = \\frac{−3 + 3 + p}{3}、y = \\frac{1 + 1 + q}{3}，用 x、y 表示 P(p, q)。", "P = ([0]x, [1]y − 2)", ["3", "3"],
					"P = (3x, 3y − 2)", "p = 3x，q = 3y − 2。", T_LOC),
				_f("代入", "代進 (p + 3)^{2} + (q − 1)^{2} = 9：(3x + 3)^{2} + (3y − 3)^{2} = 9，兩邊除以 9。", "(x + [0])^{2} + (y − [1])^{2} = [2]", ["1", "1", "1"],
					"(x + 1)^{2} + (y − 1)^{2} = 1", "9(x + 1)^{2} + 9(y − 1)^{2} = 9。", T_LOC),
				_c("小心", "這個圓上的每一點都是重心嗎？", ["不是，A、B、P 共線時不是三角形，要拿掉", "是，整個圓都是", "不是，圓心要拿掉", "不是，要拿掉 B"], 0,
					"P 走到直線 AB 上的時候，A、B、P 在一條線上，圍不成三角形，就沒有重心。", "三個點什麼時候圍不成三角形？", "A、B、P 共線時不是三角形，那兩點要拿掉", T_LOC),
				_gs("拿掉", "直線 AB 是 y = 1。P = (0, 1)、(−6, 1) 時共線，點出對應的兩個重心。", [[0, 1], [-2, 1]],
					"拿掉 (0, 1)、(−2, 1)：軌跡是 (x + 1)^{2} + (y − 1)^{2} = 1，去掉這兩點", "G = \\frac{A + B + P}{3}。", T_LOC),
			 ]},
		 ]},

		{"id": "angle60", "chapter": 2, "type": "forge", "title": "看星環的角度",
		 "story": "從 P 看圓，兩條切線夾 60°。P 的軌跡是什麼？",
		 "insight": "兩條切線夾 60° ⇒ ∠KPT = 30°，直角三角形 KTP 的斜邊 \\ol{PK} = 2r\n\\ol{PK} 是定值，P 的軌跡就是以 K 為圓心的圓。",
		 "variants": [
			{"eq": "圓 (x − 1)^{2} + y^{2} = 4 外一點 P，過 P 的兩條切線夾 60°\n求 P 的軌跡",
			 "plane": _plane([-5, 7], [-5, 5], [_cir([1, 0], 2.0, 0, "cyan"), _p("K", 1, 0, 0, [-16, 16]), _cir([1, 0], 4.0, 4, "violet", true)]),
			 "steps": [
				_s("走一圈", "拉動滑桿讓 P 走，兩條切線一直夾 60°。看看 P 的足跡。", [["t", 0, 360, 15, 30]],
					[["sin((t + 210)*PI/180)", "-cos((t + 210)*PI/180)", "-(sin((t + 210)*PI/180)*(1 + 4*cos(t*PI/180)) - cos((t + 210)*PI/180)*4*sin(t*PI/180))", "gold", ""],
					 ["sin((t + 150)*PI/180)", "-cos((t + 150)*PI/180)", "-(sin((t + 150)*PI/180)*(1 + 4*cos(t*PI/180)) - cos((t + 150)*PI/180)*4*sin(t*PI/180))", "gold", ""],
					 _dd("1 + 4*cos(t*PI/180)", "4*sin(t*PI/180)", "P", "gold", true)],
					"P 的足跡圍成一個大圓（和星環同一個圓心）", "", T_LOC, {"eq": "P 走了 {t}°", "free": true}),
				_c("半個角", "切點 T、圓心 K：∠KPT 是幾度？", ["30°（60° 的一半）", "60°", "90°", "45°"], 0,
					"\\ol{PK} 平分兩條切線的夾角（整個圖對 \\ol{PK} 對稱）。", "整個圖對哪一條線對稱？", "∠KPT = 30°，而且 ∠KTP = 90°", T_LOC),
				_f("斜邊", "30°、60°、90° 的直角三角形：斜邊是短股的 2 倍。短股 \\ol{KT} = r = 2。", "\\ol{PK} = [0]", ["4"], "\\ol{PK} = 2r = 4", "2 × 2。", T_LOC),
				_f("軌跡", "P 到 K(1, 0) 的距離一直是 4。", "(x − 1)^{2} + y^{2} = [0]", ["16"], "P 的軌跡：(x − 1)^{2} + y^{2} = 16", "4^{2}。", T_LOC),
			 ]},
		 ]},

		{"id": "chordmid", "chapter": 2, "type": "forge", "title": "弦中點的足跡",
		 "story": "過 A 的直線割圓成弦，弦的中點 M 的軌跡是什麼？",
		 "insight": "弦的中點 M：\\ol{OM} ⊥ 弦（第六關），所以 ∠OMA = 90°\nM 在以 \\ol{OA} 為直徑的圓上（直角對直徑，第五關）。",
		 "variants": [
			{"eq": "圓 x^{2} + y^{2} = 25 內一點 A(2, 4)，過 A 的弦的中點是 M\n求 M 的軌跡",
			 "plane": _plane([-6, 7], [-6, 6], [_cir([0, 0], 5.0, 0, "cyan"), _p("O", 0, 0, 0, [-16, 16]), _p("A", 2, 4, 0, [8, -6], "gold"),
				_seg([0, 0], [2, 4], 2, "dim", true), {"k": "circle", "o": [1, 2], "r": sqrt(5.0), "at": 4, "c": "violet", "nohit": true}]),
			 "steps": [
				_s("轉轉看", "拉動滑桿讓光繞著 A 轉，看看弦的中點 M 留下的足跡。", [["t", 0, 180, 10, 0]],
					[["sin(t*PI/180)", "-cos(t*PI/180)", "4*cos(t*PI/180) - 2*sin(t*PI/180)", "gold", ""],
					 _dd("2 - (2*cos(t*PI/180) + 4*sin(t*PI/180))*cos(t*PI/180)", "4 - (2*cos(t*PI/180) + 4*sin(t*PI/180))*sin(t*PI/180)", "M", "gold", true)],
					"M 的足跡圍成一個小圓，經過 O 和 A", "", T_LOC, {"eq": "光轉了 {t}°", "free": true}),
				_c("直角", "∠OMA 是幾度？", ["90°", "60°", "45°", "不一定"], 0,
					"圓心到弦中點的連線垂直弦（第六關「知道弦的中點」）。", "\\ol{OM} 和弦是什麼關係？", "∠OMA = 90°", T_LOC),
				_c("在哪裡", "∠OMA 一直是 90°，M 在哪裡？", ["以 \\ol{OA} 為直徑的圓上", "以 O 為圓心、半徑 \\ol{OA} 的圓上", "直線 OA 上", "\\ol{OA} 的中垂線上"], 0,
					"直徑所對的圓周角是 90°，反過來看直角的頂點在以斜邊為直徑的圓上（第五關）。", "第五關的直徑式。", "M 在以 \\ol{OA} 為直徑的圓上", T_LOC),
				_f("軌跡", "以 \\ol{OA} 為直徑：圓心是中點，半徑是 \\frac{\\ol{OA}}{2}。", "(x − [0])^{2} + (y − [1])^{2} = [2]", ["1", "2", "5"],
					"M 的軌跡：(x − 1)^{2} + (y − 2)^{2} = 5", "中點 (1, 2)，半徑^{2} = \\frac{20}{4}。", T_LOC),
			 ]},
		 ]},

		{"id": "apollo", "chapter": 2, "type": "forge", "title": "兩倍遠的燈",
		 "story": "P 到 A 的距離一直是到 B 的 2 倍。P 的軌跡是什麼？",
		 "insight": "\\ol{PA} = k\\ol{PB}（k ≠ 1）的點，軌跡是一個圓（阿波羅尼斯圓）\n列式：兩邊平方，\\ol{PA}^{2} = k^{2}\\ol{PB}^{2}，展開整理再配方。",
		 "variants": [
			{"eq": "A(6, 0)、B(3, 0)，動點 P 滿足 \\ol{PA} = 2\\ol{PB}\n求 P 的軌跡",
			 "plane": _plane([-3, 8], [-4, 6], [_p("A", 6, 0, 0, [8, -6], "gold"), _p("B", 3, 0, 0, [8, -6], "gold"), _cir([2, 0], 2.0, 3, "cyan"),
				_p("Q", 2, 5, 4, [8, -6]), _seg([2, 5], [2, -2], 5, "gold")]),
			 "steps": [
				_gs("先找找", "x 軸上有兩個點滿足 \\ol{PA} = 2\\ol{PB}，點出來。", [[4, 0], [0, 0]],
					"(4, 0)：\\ol{PA} = 2、\\ol{PB} = 1。(0, 0)：\\ol{PA} = 6、\\ol{PB} = 3", "|x − 6| = 2|x − 3|。", T_LOC),
				_f("列式", "設 P(x, y)，兩邊平方：(x − 6)^{2} + y^{2} = 4[(x − 3)^{2} + y^{2}]，展開整理。", "x^{2} + y^{2} − [0]x = 0", ["4"],
					"36 − 12x + x^{2} + y^{2} = 4x^{2} − 24x + 36 + 4y^{2} ⇒ x^{2} + y^{2} − 4x = 0", "移到同一邊，除以 3。", T_LOC),
				_f("配方", "P 的軌跡是什麼圓？", "圓心 ([0], 0)，半徑 [1]", ["2", "2"], "(x − 2)^{2} + y^{2} = 4：圓心 (2, 0)、半徑 2", "(x − 2)^{2} + y^{2} = 4。", T_LOC),
				_c("兩點", "一開始點的 (0, 0)、(4, 0)，是這個圓的什麼？", ["直徑的兩端", "圓心", "切點", "圓外的點"], 0,
					"它們在 x 軸（過圓心）上，距離 4 = 2r。", "兩點的距離和半徑比一比。", "(0, 0)、(4, 0) 是直徑的兩端", T_LOC),
				_f("最遠", "Q(2, 5)：圓上的點 P 到 Q 最遠多遠？（第五關的點與圓）", "\\ol{PQ} 最大 = [0]", ["7"], "Q 到圓心 5，最遠 5 + 2 = 7", "到圓心的距離 + r。", T_LOC),
			 ]},
		 ]},

		{"id": "judge", "chapter": 2, "type": "forge", "title": "哪些是星環",
		 "story": "四種動點，各走出一種足跡。哪些是完整的圓？",
		 "insight": "到定點等距 ⇒ 圓。∠APB = 90° ⇒ 以 \\ol{AB} 為直徑的圓，但要拿掉 A、B\n到兩定點等距 ⇒ 中垂線。\\ol{PA} = k\\ol{PB}（k ≠ 1）⇒ 圓。",
		 "variants": [
			{"eq": "A(−2, 0)、B(2, 0)，下面四種動點 P 的軌跡\n哪些是完整的圓？",
			 "plane": _plane([-6, 7], [-5, 5], [_p("A", -2, 0, 0, [-8, 18], "gold"), _p("B", 2, 0, 0, [6, 18], "gold"),
				_cir([-2, 0], 3.0, 1, "cyan"), {"k": "circle", "o": [0, 0], "r": 2.0, "at": 2, "c": "lime", "nohit": true}, _hole(-2, 0, 2, "lime"), _hole(2, 0, 2, "lime"),
				{"k": "line", "p": [0, 0], "q": [0, 1], "at": 3, "c": "orange", "nohit": true}, {"k": "circle", "o": [10.0 / 3.0, 0], "r": 8.0 / 3.0, "at": 4, "c": "violet", "nohit": true}]),
			 "steps": [
				_c("一", "\\ol{PA} = 3 的 P：", ["圓（圓心 A、半徑 3）", "直線", "去掉兩點的圓", "兩條直線"], 0,
					"到 A 的距離固定是 3，就是圓的定義。", "圓的定義。", "\\ol{PA} = 3：圓", T_LOC),
				_c("二", "∠APB = 90° 的 P：", ["以 \\ol{AB} 為直徑的圓，去掉 A、B", "完整的圓", "直線", "沒有這樣的點"], 0,
					"直角的頂點在以 \\ol{AB} 為直徑的圓上，可是 P 在 A 或 B 的時候沒有角，要拿掉。", "P 可以剛好在 A 嗎？", "∠APB = 90°：x^{2} + y^{2} = 4，去掉 A、B", T_LOC),
				_c("三", "\\ol{PA} = \\ol{PB} 的 P：", ["直線（\\ol{AB} 的中垂線 x = 0）", "圓", "去掉兩點的圓", "一個點"], 0,
					"到兩點等距的點在中垂線上（第一關）。", "第一關的等距點。", "\\ol{PA} = \\ol{PB}：中垂線 x = 0", T_LOC),
				_c("四", "\\ol{PA} = 2\\ol{PB} 的 P：", ["圓", "直線", "去掉兩點的圓", "兩條直線"], 0,
					"\\ol{PA} = k\\ol{PB}（k ≠ 1）的軌跡是圓（上一題）。這裡是 (x − \\frac{10}{3})^{2} + y^{2} = \\frac{64}{9}。", "上一題「兩倍遠的燈」。", "\\ol{PA} = 2\\ol{PB}：圓", T_LOC),
				_f("幾個", "四種裡面，完整的圓有幾種？", "[0] 種", ["2"], "完整的圓：\\ol{PA} = 3、\\ol{PA} = 2\\ol{PB}，共 2 種", "第二種少了兩個點，第三種是直線。", T_LOC),
			 ]},
		 ]},

		{"id": "speed2", "chapter": 2, "type": "speed", "title": "中點軌跡速算", "time": 150.0,
		 "story": "星星一顆接一顆在星環上走！快速寫出中點的軌跡。",
		 "insight": "P 在圓心 K、半徑 r 的圓上，\\ol{AP} 的中點：圓心是 \\ol{AK} 的中點、半徑 \\frac{r}{2}。",
		 "variants": [{"gen": "mid", "count": 6}]},
	]
