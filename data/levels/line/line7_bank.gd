extends RefCounted
## 直線與圓 第七大關「切線燈環」題庫（對應講義 3-3 重點五：切線問題）
##
## 旅程（引擎見 line_level.gd）：
##   forge  一步一步推導：choice、fill、grid、grids、slide（直線繞著定點轉，剛好相切時切點亮起一盞燈）
##          坐標方格都有交點漣漪＋切點燈（plane 的 "lamps"），滑桿讀數可以顯示交點個數 {#hits}
##   speed  速算：gen = "tan"（圓上一點的切線，替換公式）、"len"（切線段長，畢氏定理）
##
## 使用者 2026/11/07 的決定：先用「切線 ⊥ 半徑」推，第二題再給替換公式當捷徑。
##   不收圓冪（課綱刪掉了）：不做「最近 × 最遠 = 切線段長²」、不做割線，切線段長只用畢氏定理。
## 觀念標籤都用 line_ 開頭（名稱寫在 quiz_manager.gd 的 MISTAKE_INFO）。
## 題目的數字都用程式驗算過（scratchpad/c7/verify_c7.py）。延後到終焉之塔的題型記在 docs/line_tower_backlog.md。

const SB := preload("res://data/levels/engine/step_bank.gd")
const RADICALS := true

const T_PT := "line_tan_pt"         # 圓上一點的切線（⊥ 半徑、替換公式）
const T_EXT := "line_tan_ext"       # 圓外一點的切線（別漏鉛直線）、切線段長
const T_APP := "line_tan_app"       # 反射、影長、圓內反射、兩條切線的交點、從切線反求圓
const T_DIST := "line_dist"         # 點到直線距離（第三關也有）
const T_FIND := "line_circle_find"  # 求圓（第五關也有）



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
		# ======================= 第一章．點亮切點 =======================
		{"id": "tanpt", "chapter": 1, "type": "forge", "title": "點亮湖岸的燈",
		 "story": "湖岸（圓）上的一盞燈要打出一道光，光只能碰到湖岸這一點（切線）。光要往哪個方向打？",
		 "insight": "切線 ⊥ 半徑：先算半徑的斜率，切線斜率是它的負倒數，再用點斜式\n半徑是水平的時候，切線是鉛直線（沒有斜率）。",
		 "variants": [
			{"eq": "圓 (x − 1)^{2} + (y + 2)^{2} = 25 上一點 P(4, 2)\n求過 P 的切線",
			 "plane": _plane([-5, 8], [-8, 4], [_cir([1, -2], 5.0, 0, "cyan"), _p("K", 1, -2, 0, [-16, 16]), _p("P", 4, 2, 0, [8, -6], "gold"),
				_seg([1, -2], [4, 2], 0, "dim", true), {"k": "right", "p": [4, 2], "u": [-3, -4], "v": [4, -3], "at": 1},
				_lg(3, 4, -20, "L", 3, "gold")]),
			 "steps": [
				_c("切線和半徑", "過 P 的切線和半徑 \\ol{KP} 是什麼關係？", ["垂直", "平行", "夾 45°", "重合"], 0,
					"切線只碰到圓一點。圓心到切線最近的點就是切點，所以 \\ol{KP} ⊥ 切線。", "圓心到切線的距離 = r，最近的點在哪裡？", "切線 ⊥ 半徑 \\ol{KP}", T_PT),
				_f("斜率", "先算 m_{KP}，再寫出切線的斜率。", "m_{KP} = [0]，切線斜率 = [1]", ["4/3", "-3/4"], "m_{KP} = \\frac{4}{3} ⇒ 切線斜率 −\\frac{3}{4}", "垂直：斜率相乘 −1。", T_PT),
				_f("切線", "過 P(4, 2)、斜率 −\\frac{3}{4}：y − 2 = −\\frac{3}{4}(x − 4)，整理。", "3x + 4y = [0]", ["20"], "切線 L：3x + 4y = 20（切點的燈亮了）", "兩邊乘 4：4y − 8 = −3x + 12。", T_PT),
				_f("驗證", "圓心 K(1, −2) 到 L 的距離是不是 r？", "d(K, L) = \\frac{|3 − 8 − 20|}{5} = [0]", ["5"], "d(K, L) = 5 = r ✓", "|−25| = 25。", T_DIST),
			 ]},
			{"eq": "圓 (x − 2)^{2} + (y + 1)^{2} = 9 上一點 P(5, −1)\n求過 P 的切線",
			 "plane": _plane([-3, 7], [-5, 3], [_cir([2, -1], 3.0, 0, "cyan"), _p("K", 2, -1, 0, [-16, -6]), _p("P", 5, -1, 0, [8, -8], "gold"),
				_seg([2, -1], [5, -1], 0, "dim", true), {"k": "right", "p": [5, -1], "u": [-1, 0], "v": [0, 1], "at": 1},
				{"k": "line", "p": [5, 0], "q": [5, 1], "s": "L", "at": 2, "c": "gold"}]),
			 "steps": [
				_c("半徑", "半徑 \\ol{KP} 是什麼方向？", ["水平（m_{KP} = 0）", "鉛直", "斜率 1", "斜率 −1"], 0,
					"K(2, −1)、P(5, −1) 的 y 坐標一樣。", "比一比 K、P 的 y 坐標。", "\\ol{KP} 是水平的", T_PT),
				_c("切線", "切線 ⊥ 水平的半徑，切線是？", ["鉛直線 x = 5", "水平線 y = −1", "斜率 1 的直線", "沒有切線"], 0,
					"垂直於水平線的是鉛直線，而且要過 P(5, −1)。鉛直線沒有斜率，不能用「斜率相乘 −1」。", "水平線的垂直線是什麼？", "切線 L：x = 5（鉛直線，沒有斜率）", T_PT),
				_f("驗證", "圓心 K(2, −1) 到 L 的距離是不是 r？", "d(K, L) = [0]", ["3"], "d(K, L) = 3 = r ✓", "5 − 2。", T_DIST),
			 ]},
		 ]},

		{"id": "formula", "chapter": 1, "type": "forge", "title": "切線的捷徑",
		 "story": "每次都先算半徑的斜率有點慢。圓上一點的切線有一個好用的公式：把 x^{2} 換成 x₀x、y^{2} 換成 y₀y。",
		 "insight": "x^{2} + y^{2} = r^{2} 上一點 (x₀, y₀) 的切線：x₀x + y₀y = r^{2}\n一般式：x₀x + y₀y + \\frac{D}{2}(x + x₀) + \\frac{E}{2}(y + y₀) + F = 0",
		 "variants": [
			{"eq": "圓 x^{2} + y^{2} = 25 上一點 P(−4, 3)\n用公式求過 P 的切線",
			 "plane": _plane([-7, 7], [-6, 6], [_cir([0, 0], 5.0, 0, "cyan"), _p("O", 0, 0, 0, [-16, 16]), _p("P", -4, 3, 0, [-18, -8], "gold"),
				_seg([0, 0], [-4, 3], 1, "dim", true), _lg(-4, 3, -25, "L", 1, "gold")]),
			 "steps": [
				_f("代公式", "x₀ = −4、y₀ = 3 代進 x₀x + y₀y = r^{2}。", "[0]x + [1]y = 25", ["-4", "3"], "切線 L：−4x + 3y = 25（燈亮了）", "x 的係數是 x₀，y 的係數是 y₀。", T_PT),
				_f("對照", "用斜率對照看看：L 的斜率和 m_{OP}。", "L 的斜率 = [0]，m_{OP} = [1]", ["4/3", "-3/4"], "\\frac{4}{3} × (−\\frac{3}{4}) = −1：L ⊥ \\ol{OP} ✓", "−4x + 3y = 25 ⇒ y = \\frac{4}{3}x + \\frac{25}{3}。", T_PT),
			 ]},
			{"eq": "圓 x^{2} + y^{2} − 2x + 4y − 20 = 0 上一點 P(4, 2)\n用公式求過 P 的切線",
			 "plane": _plane([-5, 8], [-8, 4], [_cir([1, -2], 5.0, 0, "cyan"), _p("K", 1, -2, 0, [-16, 16]), _p("P", 4, 2, 0, [8, -6], "gold"),
				_lg(3, 4, -20, "L", 2, "gold")]),
			 "steps": [
				_f("代公式", "D = −2、E = 4、F = −20，P(4, 2) 代進公式。", "4x + 2y − (x + [0]) + 2(y + [1]) − 20 = 0", ["4", "2"],
					"4x + 2y − (x + 4) + 2(y + 2) − 20 = 0", "\\frac{D}{2}(x + x₀) = −(x + 4)。", T_PT),
				_f("整理", "把式子整理好。", "3x + 4y = [0]", ["20"], "切線 L：3x + 4y = 20（燈亮了）", "4x − x = 3x，2y + 2y = 4y，−4 + 4 − 20 = −20。", T_PT),
				_f("驗證", "圓心 K(1, −2)，看看 d(K, L) 是不是 r。", "d(K, L) = \\frac{|3 − 8 − 20|}{5} = [0]", ["5"], "d(K, L) = 5 = r ✓", "|−25| = 25。", T_DIST),
			 ]},
		 ]},

		{"id": "ext", "chapter": 1, "type": "forge", "title": "繞著燈塔轉的光",
		 "story": "燈塔 P 在湖外，光繞著燈塔轉。哪幾個方向的光，剛好擦過湖岸？",
		 "insight": "圓外一點的切線有兩條：設 y − y₀ = m(x − x₀)，用 d(K, L) = r 解 m\n只解出一個 m 的時候，另一條是鉛直線（沒有斜率，設斜率會漏掉）。",
		 "variants": [
			{"eq": "圓 x^{2} + y^{2} = 25、圓外一點 P(7, 1)\n求過 P 的切線",
			 "plane": _plane([-6, 9], [-6, 6], [_cir([0, 0], 5.0, 0, "cyan"), _p("O", 0, 0, 0, [-16, 16]), _p("P", 7, 1, 0, [8, -6], "gold"),
				_lg(4, -3, -25, "", 4, "gold"), _lg(3, 4, -25, "", 4, "gold")]),
			 "steps": [
				_s("轉轉看", "拉動 m 讓光繞著 P 轉，找到兩個只碰到湖岸一點的位置。", [["m", -3, 3, 1.0 / 12.0, 0]],
					[["m", "-1", "1 - 7*m", "gold", ""]],
					"m = \\frac{4}{3}、−\\frac{3}{4} 時只有 1 個交點（燈亮了）", "", T_EXT,
					{"eq": "y − 1 = m(x − 7)，m = {m}\n交點 {#hits} 個", "free": true}),
				_f("列式", "設 L：y − 1 = m(x − 7)，也就是 mx − y + 1 − 7m = 0。相切：d(O, L) = r。",
					"\\frac{|1 − 7m|}{√(m^{2} + 1)} = [0]", ["5"], "\\frac{|1 − 7m|}{√(m^{2} + 1)} = 5", "r = 5。", T_EXT),
				_fx("解 m", "兩邊平方：(1 − 7m)^{2} = 25(m^{2} + 1)，整理成 12m^{2} − 7m − 12 = 0。", "m = [0] 或 [1]", ["4/3", "-3/4"],
					"(3m − 4)(4m + 3) = 0 ⇒ m = \\frac{4}{3} 或 −\\frac{3}{4}", "十字交乘：(3m − 4)(4m + 3)。", T_EXT, [[0, 1]]),
				_f("兩條切線", "代回 y − 1 = m(x − 7)，整理。", "4x − 3y = [0]、3x + 4y = [1]", ["25", "25"],
					"切線：4x − 3y = 25、3x + 4y = 25（兩盞燈都亮了）", "m = \\frac{4}{3}：3y − 3 = 4x − 28。", T_EXT),
				_c("夾角", "這兩條切線是什麼關係？", ["互相垂直", "互相平行", "夾 60°", "重合"], 0,
					"\\frac{4}{3} × (−\\frac{3}{4}) = −1。", "斜率相乘。", "兩條切線互相垂直", T_EXT),
			 ]},
			{"eq": "圓 (x − 1)^{2} + (y − 1)^{2} = 4、圓外一點 P(3, 5)\n求過 P 的切線",
			 "plane": _plane([-3, 7], [-2, 7], [_cir([1, 1], 2.0, 0, "cyan"), _p("K", 1, 1, 0, [-16, 16]), _p("P", 3, 5, 0, [8, -6], "gold"),
				_lg(3, -4, 11, "", 4, "gold"), {"k": "line", "p": [3, 0], "q": [3, 1], "at": 4, "c": "lime"}]),
			 "steps": [
				_s("轉轉看", "拉動 m 讓光繞著 P 轉，找出只碰到湖岸一點的位置。", [["m", -3, 3, 0.25, 0]],
					[["m", "-1", "5 - 3*m", "gold", ""]],
					"滑桿只找得到一條：m = \\frac{3}{4}", "", T_EXT,
					{"eq": "y − 5 = m(x − 3)，m = {m}\n交點 {#hits} 個", "free": true}),
				_f("解 m", "d(K, L) = r：\\frac{|m − 1 + 5 − 3m|}{√(m^{2} + 1)} = 2，兩邊平方解 m。", "\\frac{|4 − 2m|}{√(m^{2} + 1)} = 2 ⇒ m = [0]", ["3/4"],
					"16 − 16m + 4m^{2} = 4m^{2} + 4 ⇒ m = \\frac{3}{4}", "m^{2} 兩邊消掉：16 − 16m = 4。", T_EXT),
				_c("另一條", "圓外一點應該有兩條切線，卻只解出一個 m。另一條是？", ["鉛直線 x = 3（沒有斜率）", "水平線 y = 5", "沒有另一條", "斜率 −\\frac{3}{4} 的直線"], 0,
					"設斜率會漏掉鉛直線。x = 3 到 K(1, 1) 的距離剛好是 2 = r。", "什麼直線沒有斜率？", "另一條是鉛直線 x = 3（d(K, L) = 2 = r）", T_EXT),
				_f("兩條切線", "m = \\frac{3}{4} 代回 y − 5 = m(x − 3)，整理。", "3x − 4y + [0] = 0、x = [1]", ["11", "3"],
					"切線：3x − 4y + 11 = 0、x = 3（兩盞燈都亮了）", "兩邊乘 4：4y − 20 = 3x − 9。", T_EXT),
			 ]},
		 ]},

		{"id": "len", "chapter": 1, "type": "forge", "title": "切線段有多長",
		 "story": "從燈塔 P 到切點的那一段光叫做切線段。它有多長？",
		 "insight": "切點 T、圓心 K、圓外一點 P：∠KTP = 90°\n切線段長 \\ol{PT} = √(\\ol{PK}^{2} − r^{2})，兩條切線段一樣長。",
		 "variants": [
			{"eq": "圓 x^{2} + y^{2} − 4x + 2y − 4 = 0、圓外一點 P(6, 2)\n求切線段長",
			 "plane": _plane([-3, 8], [-5, 4], [_cir([2, -1], 3.0, 0, "cyan"), _p("P", 6, 2, 0, [8, -6], "gold"), _p("K", 2, -1, 1, [-16, -6]),
				{"k": "line", "p": [2, 2], "q": [6, 2], "at": 2, "c": "gold"}, _seg([2, -1], [2, 2], 2, "dim", true), _seg([2, -1], [6, 2], 2, "dim", true),
				{"k": "right", "p": [2, 2], "u": [0, -1], "v": [1, 0], "at": 2}, _p("T", 2, 2, 2, [-18, -8], "gold"),
				_lg(24, -7, -130, "", 5, "gold")]),
			 "steps": [
				_f("圓心半徑", "先配方，找出圓心 K 和半徑。", "K([0], [1])，r = [2]", ["2", "-1", "3"],
					"(x − 2)^{2} + (y + 1)^{2} = 9：K(2, −1)，r = 3", "(x − 2)^{2} + (y + 1)^{2} = 4 + 1 + 4。", T_FIND),
				_c("直角", "P、切點 T、圓心 K 圍成什麼三角形？", ["直角三角形，直角在 T", "直角三角形，直角在 K", "直角三角形，直角在 P", "正三角形"], 0,
					"切線 ⊥ 半徑：\\ol{KT} ⊥ \\ol{PT}。", "切線和半徑的關係。", "△PTK：直角在 T", T_EXT),
				_f("斜邊", "先算斜邊 \\ol{PK}。", "\\ol{PK} = [0]", ["5"], "\\ol{PK} = √(16 + 9) = 5", "橫向 4、縱向 3。", T_EXT),
				_f("切線段", "用畢氏定理。", "\\ol{PT} = √(\\ol{PK}^{2} − r^{2}) = √(25 − 9) = [0]", ["4"], "切線段長 \\ol{PT} = 4（3、4、5 的直角三角形）", "√16。", T_EXT),
				_c("另一條", "從 P 到另一個切點的切線段多長？", ["也是 4", "比 4 長", "比 4 短", "不一定"], 0,
					"兩個直角三角形的斜邊都是 \\ol{PK}、一股都是 r，另一股就一樣長。", "兩個直角三角形的邊有什麼一樣？", "兩條切線段一樣長", T_EXT),
			 ]},
		 ]},

		{"id": "speed1", "chapter": 1, "type": "speed", "title": "切線速算", "time": 150.0,
		 "story": "湖岸上的燈一盞接一盞亮起來！用公式快速寫出切線。",
		 "insight": "x^{2} + y^{2} = r^{2} 上一點 (x₀, y₀) 的切線：x₀x + y₀y = r^{2}\n(x − h)^{2} + (y − k)^{2} = r^{2} 上一點：(x₀ − h)(x − h) + (y₀ − k)(y − k) = r^{2}",
		 "variants": [{"gen": "tan", "count": 6}]},

		# ======================= 第二章．切線的應用 =======================
		{"id": "reflect", "chapter": 2, "type": "forge", "title": "湖面反射的光",
		 "story": "燈 A 照向湖面（x 軸），反射後的光剛好擦過岸邊的燈環。光打在湖面的哪裡？",
		 "insight": "反射後的光在 T 擦過圓，它就是過 T 的切線\n入射光、反射光對鏡面對稱：A 的對稱點 A' 也在反射光上（第三關）。",
		 "variants": [
			{"eq": "A(−4, 2) 的光經湖面 y = 0 反射後，和圓 (x − 3)^{2} + (y − 4)^{2} = 5 切於 T(4, 2)\n求入射光和反射光",
			 "plane": _plane([-6, 7], [-3, 7], [{"k": "region", "ineq": [[0, 1, 0, "<="]], "c": "cyan", "alpha": 0.08},
				_cir([3, 4], sqrt(5.0), 0, "cyan"), _p("A", -4, 2, 0, [-8, -10], "gold"), _p("K", 3, 4, 0, [8, -6]), _p("T", 4, 2, 0, [8, 12], "gold"),
				_seg([3, 4], [4, 2], 1, "dim", true), {"k": "right", "p": [4, 2], "u": [-1, 2], "v": [2, 1], "at": 1},
				_lg(1, -2, 0, "", 3, "gold"), _p("R", 0, 0, 4, [8, 16], "gold"),
				_p("A'", -4, -2, 5, [-22, 8], "dim"), _seg([-4, -2], [0, 0], 5, "dim", true),
				{"k": "path", "pts": [[-4, 2], [0, 0], [4, 2], [7, 3.5]], "c": "gold", "at": 5, "dur": 1.6}]),
			 "steps": [
				_c("反射光", "反射後的光在 T 擦過圓，它是哪一條線？", ["過 T 的切線", "過 T 和圓心 K 的直線", "過 T 的水平線", "過 T 的鉛直線"], 0,
					"只碰到圓一點的直線就是切線。", "擦過＝只碰到一點。", "反射光是過 T 的切線", T_APP),
				_f("切線斜率", "先算 m_{KT}，再寫出切線的斜率。", "m_{KT} = [0]，切線斜率 = [1]", ["-2", "1/2"], "m_{KT} = −2 ⇒ 切線斜率 \\frac{1}{2}", "垂直：斜率相乘 −1。", T_PT),
				_f("反射光", "過 T(4, 2)、斜率 \\frac{1}{2}：y − 2 = \\frac{1}{2}(x − 4)，整理。", "x − [0]y = 0", ["2"], "反射光：x − 2y = 0", "兩邊乘 2：2y − 4 = x − 4。", T_APP),
				_f("反射點", "反射光和湖面 y = 0 的交點 R。", "R([0], 0)", ["0"], "R(0, 0)：光打在原點", "y = 0 代進 x − 2y = 0。", T_APP),
				_f("入射光", "入射光是直線 AR：A(−4, 2)、R(0, 0)。", "x + [0]y = 0", ["2"],
					"入射光：x + 2y = 0（A 的對稱點 A'(−4, −2) 也在反射光上 ✓）", "斜率 −\\frac{1}{2}，過原點。", T_APP),
			 ]},
		 ]},

		{"id": "shadow", "chapter": 2, "type": "forge", "title": "燈環在牆上的影子",
		 "story": "燈 A 照向湖中的圓形小島，小島在後面的牆上留下影子。影子有多長？",
		 "insight": "點光源照圓：影子的兩端是兩條切線碰到牆的地方\n先用 d(K, L) = r 求兩條切線，再求它們和牆的交點。",
		 "variants": [
			{"eq": "燈 A(−6, 0)，小島 (x + 1)^{2} + y^{2} = 5，牆 x = 2\n求小島在牆上的影長",
			 "plane": _plane([-7, 3], [-5, 5], [_cir([-1, 0], sqrt(5.0), 0, "cyan"), _p("A", -6, 0, 0, [-8, -10], "gold"), _p("K", -1, 0, 0, [6, 14]),
				{"k": "line", "p": [2, 0], "q": [2, 1], "c": "violet", "w": 4.0, "nohit": true},
				{"k": "poly", "pts": [[-2, 2], [2, 4], [2, -4], [-2, -2]], "c": "faint", "fill": "violet", "alpha": 0.25, "at": 4},
				_lg(1, -2, 6, "", 2, "gold"), _lg(1, 2, 6, "", 2, "gold"),
				_p("", 2, 4, 3, [0, 0], "gold"), _p("", 2, -4, 3, [0, 0], "gold"),
				{"k": "seg", "a": [2, -4], "b": [2, 4], "c": "orange", "w": 6.0, "at": 4}]),
			 "steps": [
				_f("列式", "設過 A 的光 L：y = m(x + 6)，也就是 mx − y + 6m = 0。K(−1, 0) 代進 d(K, L) = r，分子合併。",
					"\\frac{|[0]m|}{√(m^{2} + 1)} = √5", ["5"], "\\frac{|5m|}{√(m^{2} + 1)} = √5", "−m + 6m。", T_EXT),
				_fx("解 m", "兩邊平方：25m^{2} = 5(m^{2} + 1)。", "m = [0] 或 [1]", ["1/2", "-1/2"],
					"20m^{2} = 5 ⇒ m = ±\\frac{1}{2}（兩條切線，燈亮了）", "m^{2} = \\frac{1}{4}。", T_EXT, [[0, 1]]),
				_fx("碰到牆", "兩條切線 y = ±\\frac{1}{2}(x + 6) 和牆 x = 2 的交點。", "(2, [0])、(2, [1])", ["4", "-4"],
					"影子的兩端：(2, 4)、(2, −4)", "x = 2 代進去：\\frac{1}{2} × 8。", T_APP, [[0, 1]]),
				_f("影長", "牆上的影子有多長？", "影長 = [0]", ["8"], "影長 = 4 − (−4) = 8", "兩端的 y 坐標相減。", T_APP),
			 ]},
		 ]},

		{"id": "rainbow", "chapter": 2, "type": "forge", "title": "水滴裡的彩虹",
		 "story": "彩虹是陽光在小水滴裡反射造成的。光在圓形的水滴裡打到邊上，會往哪裡反射？",
		 "insight": "光打到圓上的 R：法線是半徑 \\ol{OR}，入射光、反射光對法線對稱\n把 A 對 \\ol{OR} 所在的直線對稱，連 R 和對稱點，就是反射光。",
		 "variants": [
			{"eq": "水滴 x^{2} + y^{2} = 25，光從 A(1, 2) 射向 R(5, 0)，反射後打到圓上的 B\n求 B",
			 "plane": _plane([-7, 7], [-6, 6], [_cir([0, 0], 5.0, 0, "cyan"), _p("O", 0, 0, 0, [-16, 16]), _p("A", 1, 2, 0, [-8, -8], "gold"),
				_p("R", 5, 0, 0, [8, -8], "gold"), {"k": "path", "pts": [[1, 2], [5, 0]], "c": "gold", "dur": 0.8},
				{"k": "seg", "a": [-5, 0], "b": [5, 0], "c": "lime", "dash": true, "at": 1},
				_p("A'", 1, -2, 2, [8, 12], "dim"), _seg([1, 2], [1, -2], 2, "dim", true),
				{"k": "path", "pts": [[1, 2], [5, 0], [-3, -4]], "c": "gold", "at": 4, "dur": 1.6}]),
			 "steps": [
				_c("法線", "光在 R 反射時，「法線」（和圓周垂直的那條線）是哪一條？", ["半徑 \\ol{OR} 所在的直線（x 軸）", "圓在 R 的切線", "直線 AR", "y 軸"], 0,
					"圓上每一點的法線都是那一點的半徑（半徑 ⊥ 切線）。", "和切線垂直的是誰？", "法線：\\ol{OR} 所在的直線（x 軸）", T_APP),
				_f("對稱點", "入射光、反射光對法線對稱。A(1, 2) 對 x 軸的對稱點？", "A'([0], [1])", ["1", "-2"], "A'(1, −2)", "對 x 軸對稱：y 變號。", T_APP),
				_f("反射光", "反射光是直線 RA'：R(5, 0)、A'(1, −2)。", "x − [0]y = 5", ["2"], "反射光：x − 2y = 5", "斜率 \\frac{−2 − 0}{1 − 5} = \\frac{1}{2}。", T_APP),
				_g("B", "x = 5 + 2y 代進 x^{2} + y^{2} = 25，放下 B。", "B", [-3, -4], "(5 + 2y)^{2} + y^{2} = 25 ⇒ y = 0 或 −4 ⇒ B(−3, −4)",
					"5y^{2} + 20y = 0。", T_APP, [[5, 0, "這是 R，光是從這裡反射出去的。"]]),
			 ]},
		 ]},

		{"id": "polar", "chapter": 2, "type": "forge", "title": "兩盞燈的交會",
		 "story": "湖岸上 A、B 兩盞燈各打出一道切線光，兩道光在湖外交會於 P。P 在哪裡？",
		 "insight": "已知切點：用公式寫出兩條切線，聯立就是 P\n\\ol{AB} ⊥ \\ol{OP}，而且把 P 代進 x₀x + y₀y = r^{2}，得到的就是 \\ol{AB} 所在的直線。",
		 "variants": [
			{"eq": "圓 x^{2} + y^{2} = 10 上兩點 A(1, 3)、B(3, −1)\n過 A、B 的切線交於 P，求 P",
			 "plane": _plane([-5, 6], [-4, 5], [_cir([0, 0], sqrt(10.0), 0, "cyan"), _p("O", 0, 0, 0, [-16, 16]), _p("A", 1, 3, 0, [-14, -8], "gold"),
				_p("B", 3, -1, 0, [8, 14], "gold"), _lg(1, 3, -10, "", 1, "gold"), _lg(3, -1, -10, "", 2, "gold"),
				_seg([0, 0], [4, 2], 3, "dim", true), _seg([1, 3], [3, -1], 3, "lime")]),
			 "steps": [
				_f("A 的切線", "用公式 x₀x + y₀y = r^{2}。", "x + [0]y = 10", ["3"], "過 A 的切線：x + 3y = 10", "(x₀, y₀) = (1, 3)。", T_PT),
				_f("B 的切線", "同樣的公式。", "[0]x − y = 10", ["3"], "過 B 的切線：3x − y = 10", "(x₀, y₀) = (3, −1)。", T_PT),
				_g("P", "兩條切線聯立，放下交點 P。", "P", [4, 2], "y = 3x − 10 代進 x + 3y = 10 ⇒ P(4, 2)", "x + 9x − 30 = 10。", T_APP),
				_c("垂直", "\\ol{AB} 和 \\ol{OP} 是什麼關係？", ["垂直", "平行", "重合", "夾 45°"], 0,
					"m_{AB} = −2、m_{OP} = \\frac{1}{2}，相乘 −1。整個圖對 \\ol{OP} 對稱。", "算兩條的斜率。", "\\ol{AB} ⊥ \\ol{OP}", T_APP),
				_f("AB", "寫出 \\ol{AB} 所在的直線。", "2x + y = [0]", ["5"],
					"\\ol{AB}：2x + y = 5（把 P(4, 2) 代進 x₀x + y₀y = 10 也是 4x + 2y = 10）", "斜率 −2，過 A(1, 3)。", T_APP),
			 ]},
		 ]},

		{"id": "fromtan", "chapter": 2, "type": "forge", "title": "照訂單做燈環",
		 "story": "訂單：燈環要在原點剛好碰到直線 L（和 L 切於原點），而且要經過 A(1, 3)。圓心要放在哪裡？",
		 "insight": "和 L 切於 T：圓心在過 T、垂直 L 的直線上\n又過 A：圓心也在 \\ol{TA} 的中垂線上，兩條線的交點就是圓心。",
		 "variants": [
			{"eq": "圓和直線 L：2x + y = 0 切於原點 O，而且通過 A(1, 3)\n求這個圓",
			 "plane": _plane([-3, 5], [-2, 5], [_lg(2, 1, 0, "L", 0, "dim"), _p("O", 0, 0, 0, [-16, 16]), _p("A", 1, 3, 0, [8, -6], "gold"),
				{"k": "line", "abc": [1, -2, 0], "at": 2, "c": "lime", "dash": true, "nohit": true},
				{"k": "line", "abc": [1, 3, -5], "at": 3, "c": "violet", "dash": true, "nohit": true},
				_cir([2, 1], sqrt(5.0), 5, "cyan")]),
			 "steps": [
				_c("圓心", "圓和 L 切於 O，圓心在哪一條線上？", ["過 O、垂直 L 的直線", "L 上", "過 A、垂直 L 的直線", "x 軸"], 0,
					"切線 ⊥ 半徑：半徑 \\ol{KO} ⊥ L。", "切點和圓心的連線。", "圓心在過 O、垂直 L 的直線上", T_APP),
				_f("垂直線", "L 的斜率是 −2，垂直線過 O。", "x − [0]y = 0", ["2"], "垂直線：x − 2y = 0", "斜率 \\frac{1}{2}。", T_APP),
				_f("中垂線", "圓心到 O、A 一樣遠，在 \\ol{OA} 的中垂線上。中點 (\\frac{1}{2}, \\frac{3}{2})、m_{OA} = 3。", "x + [0]y = 5", ["3"],
					"\\ol{OA} 的中垂線：x + 3y = 5", "斜率 −\\frac{1}{3}，過中點。", T_APP),
				_g("圓心 K", "兩條線的交點就是圓心。放下 K。", "K", [2, 1], "x = 2y 代進 x + 3y = 5 ⇒ K(2, 1)", "5y = 5。", T_APP),
				_f("半徑", "r = \\ol{KO}。", "r = [0]", ["√5"], "圓：(x − 2)^{2} + (y − 1)^{2} = 5（在 O 碰到 L，燈亮了）", "√(4 + 1)。", T_FIND),
			 ]},
		 ]},

		{"id": "speed2", "chapter": 2, "type": "speed", "title": "切線段速算", "time": 150.0,
		 "story": "燈塔一座接一座！快速算出切線段長。",
		 "insight": "切線段長 = √(\\ol{PK}^{2} − r^{2})：先算 \\ol{PK}^{2}，減掉 r^{2} 再開根號。",
		 "variants": [{"gen": "len", "count": 6}]},
	]
