extends RefCounted
## 高一「指數與常用對數」第二大關「十倍石階」題庫（對應講義重點二：常用對數，另收重點三的 1 題）
## 設計稿：docs/exp_e2_design.md。題目的數字都用程式驗算過（tools/exp/verify_e2.py）。
## 同題型的講義題合成一題（每一題的 variants 是不同的講義題，每次隨機抽一種）。
##
## 旅程（引擎見 data/levels/num/num_level.gd）：
##   forge  一步一步推導：ltap（點十倍石階：數線加 "stair": true）、lsort（是不是實數）、
##          slide（計算尺 rule、分貝計 meter）、choice、fill（"dot" 小數鍵盤、"approx" 近似值）
##   speed  速算：gen = "logs"（log 的值與運算，按鈕）、"char"（log 的整數部分，按鈕）
## 使用者 2026/11/17：計算尺、數量級階梯的例子、log 3 的近似值、分貝計都可以。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/num/num1_bank.gd")

const T_DEF := "elog_def"        # 對數的意義、10^{log a} = a
const T_RULE := "elog_rule"      # 對數律、計算尺
const T_SHIFT := "elog_shift"    # 首數平移、用 log 比倍數
const T_RANGE := "elog_range"    # 對數的範圍、整數部分
const T_APP := "elog_app"        # 分貝、地震、公式的應用


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return SB.fill(name, q, template, answers, line, nudge, tag, mode)


static func _j(name: String, statement: String, ok: bool, why: String, line: String, tag: String) -> Dictionary:
	return B1._j(name, statement, ok, why, line, tag)


## 填空可以打小數（鍵盤多一個「.」）；tol > 0 是近似值
static func _dot(st: Dictionary, tol := 0.0) -> Dictionary:
	st["dot"] = true
	if tol > 0.0:
		st["mode"] = "approx"
		st["tol"] = tol
	return st


## 點石階：在 a、b 兩階之間
static func _tap(name: String, q: String, a: float, b: float, miss: float, wrongs: Array, nudge: String, line: String,
		tag: String, item := 0) -> Dictionary:
	return {"kind": "ltap", "name": name, "tag": tag, "q": q, "item": item, "snap": 0.1, "a": 0, "b": 0,
		"regions": [[a, b]], "wrongs": wrongs, "wrong": "", "hits": [(a + b) / 2.0], "miss": miss, "nudge": nudge, "line": line}


## 滑桿（計算尺、分貝計跟著它動）
static func _slide(name: String, q: String, n: String, lo: float, hi: float, stp: float, start: float, goal: float,
		eq: String, line: String, nudge: String, tag: String, traps := []) -> Dictionary:
	return {"kind": "slide", "name": name, "q": q, "params": [{"n": n, "min": lo, "max": hi, "step": stp, "v": start}],
		"lines": [], "eq": eq, "goal": {n: goal}, "traps": traps, "line": line, "nudge": nudge, "tag": tag}


## 石階上的一個點（v 是 log 的值）
static func _pt(v: float, s: String, at := 0, c := "gold") -> Dictionary:
	return {"v": v, "s": s, "at": at, "lit": at, "c": c}


static func _lg(x: float) -> float:
	return log(x) / log(10.0)


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
		# ======================= 第一章．對數的意義與運算 =======================
		{"id": "stair", "chapter": 1, "type": "forge", "title": "數量級階梯",
		 "story": "每往上一階，高度乘 10。",
		 "insight": "log x 就是 x 站在第幾階：1 在第 0 階、10 在第 1 階、100 在第 2 階\n100 < 508 < 1000 ⇒ 2 < log 508 < 3，整數部分是 2。",
		 "variants": [
			{"eq": "台北 101 高 508 公尺、螞蟻長 0.005 公尺\n各站在第幾階？",
			 "field": [{"k": "nline", "x": [-4, 4], "stair": true, "pts": [_pt(_lg(508.0), "508", 1), _pt(_lg(0.005), "0.005", 2, "cyan")]}],
			 "steps": [
				_tap("101 大樓", "508 站在哪裡？", 2.0, 3.0, 3.5,
					[[1.0, 2.0, "508 比 100 大，再往上。"], [3.0, 4.0, "508 比 1000 小，往下一點。"]],
					"100 和 1000 之間。", "100 < 508 < 1000：第 2、3 階之間", T_DEF),
				_tap("螞蟻", "0.005 站在哪裡？", -3.0, -2.0, -1.5,
					[[-2.0, -1.0, "0.005 比 0.01 小，往下。"], [-4.0, -3.0, "0.005 比 0.001 大，往上。"]],
					"0.001 和 0.01 之間。", "0.001 < 0.005 < 0.01：第 −3、−2 階之間", T_DEF),
				_f("整數部分", "log 的整數部分", "log 508 → [0]、log 0.005 → [1]", ["2", "-3"],
					"log 508 = 2.…、log 0.005 = −3 + 0.…", "站在哪兩階之間，取下面那一階。", T_RANGE),
			 ]},
			{"eq": "玉山高 3952 公尺、細菌長 0.000002 公尺\n各站在第幾階？",
			 "field": [{"k": "nline", "x": [-7, 5], "stair": true, "pts": [_pt(_lg(3952.0), "3952", 1), _pt(_lg(0.000002), "2 × 10^{−6}", 2, "cyan")]}],
			 "steps": [
				_tap("玉山", "3952 站在哪裡？", 3.0, 4.0, 2.5,
					[[2.0, 3.0, "3952 比 1000 大，再往上。"], [4.0, 5.0, "3952 比 10000 小，往下一點。"]],
					"1000 和 10000 之間。", "1000 < 3952 < 10000：第 3、4 階之間", T_DEF),
				_tap("細菌", "0.000002 站在哪裡？", -6.0, -5.0, -4.5,
					[[-5.0, -4.0, "0.000002 比 10^{−5} 小，往下。"], [-7.0, -6.0, "0.000002 比 10^{−6} 大，往上。"]],
					"0.000002 = 2 × 10^{−6}。", "10^{−6} < 0.000002 < 10^{−5}：第 −6、−5 階之間", T_DEF),
				_f("整數部分", "log 的整數部分", "log 3952 → [0]、log 0.000002 → [1]", ["3", "-6"],
					"log 3952 = 3.…、log 0.000002 = −6 + 0.…", "站在哪兩階之間，取下面那一階。", T_RANGE),
			 ]},
		 ]},

		{"id": "judge", "chapter": 1, "type": "forge", "title": "觀念審判",
		 "story": "石階上的刻字，有真有假。",
		 "insight": "負數的無理數次方沒有意義\n10^{n log 2} = (10^{log 2})^{n} = 2^{n}，不是 2n。",
		 "variants": [
			{"eq": "a、n 是實數，下面哪些對？",
			 "steps": [
				_j("負數的次方", "(−2)^{−√3} = \\frac{1}{(−2)^{√3}}", false, "負數的無理數次方沒有意義，兩邊都不存在。", "(−2)^{−√3} 沒有意義", T_DEF),
				_j("和是 2", "a^{\\frac{1}{2}} + a^{−\\frac{1}{2}} = 2 ⇒ a^{2025} + a^{−2025} = 2", true, "t + \\frac{1}{t} = 2 只有 t = 1，所以 a = 1。", "a = 1，a^{2025} + a^{−2025} = 2", T_DEF),
				_j("10 的 log 次方", "對所有 n：10^{n log 2} = 2n", false, "10^{n log 2} = 2^{n}，n = 3 時 8 ≠ 6。", "10^{n log 2} = 2^{n}", T_DEF),
				_j("對數相加", "log(−2)^{2} + log 3^{2} = log(−2 × 3)^{2}", true, "log 4 + log 9 = log 36 = log(−6)^{2}。", "log 4 + log 9 = log 36", T_RULE),
			 ]},
			{"eq": "a、n 是實數，下面哪些對？",
			 "steps": [
				_j("負數的次方", "(−3)^{−√2} = \\frac{1}{(−3)^{√2}}", false, "負數的無理數次方沒有意義，兩邊都不存在。", "(−3)^{−√2} 沒有意義", T_DEF),
				_j("和是 2", "a^{\\frac{1}{2}} + a^{−\\frac{1}{2}} = 2 ⇒ a^{100} + a^{−100} = 2", true, "t + \\frac{1}{t} = 2 只有 t = 1，所以 a = 1。", "a = 1，a^{100} + a^{−100} = 2", T_DEF),
				_j("10 的 log 次方", "對所有 n：10^{n log 3} = 3n", false, "10^{n log 3} = 3^{n}，n = 2 時 9 ≠ 6。", "10^{n log 3} = 3^{n}", T_DEF),
				_j("對數相加", "log(−5)^{2} + log 2^{2} = log(−5 × 2)^{2}", true, "log 25 + log 4 = log 100 = log(−10)^{2}。", "log 25 + log 4 = log 100", T_RULE),
			 ]},
		 ]},

		{"id": "points", "chapter": 1, "type": "forge", "title": "數線上的點",
		 "story": "不是實數的，放不上石階。",
		 "insight": "負數不能開平方：(−10)^{\\frac{1}{2}}、√{3 − 2√10} 都不是實數\n\\frac{1}{√10} = 10^{−\\frac{1}{2}}，是同一個點。",
		 "variants": [
			{"eq": "這 5 個數，數線上有幾個不同的點？",
			 "field": [
				{"k": "seeds", "bins": ["x ∈ ℝ", "x ∉ ℝ"], "at": 0, "hl": [],
				 "seeds": [["√{3 − 2√10}", 1], ["\\frac{1}{√10}", 0], ["(−10)^{\\frac{1}{2}}", 1], ["log √10", 0], ["10^{−\\frac{1}{2}}", 0]]},
				{"k": "nline", "x": [0, 1], "tick": 0.5, "pts": [_pt(pow(10.0, -0.5), "10^{−\\frac{1}{2}}", 2), _pt(0.5, "\\frac{1}{2}", 2, "cyan")]}],
			 "steps": [
				{"kind": "lsort", "name": "是實數嗎", "q": "放進籃子", "item": 0, "tag": T_DEF,
				 "why": {"√{3 − 2√10}": "3 − 2√10 < 0，開不了平方。", "(−10)^{\\frac{1}{2}}": "負數不能開平方。",
					"\\frac{1}{√10}": "是正的實數。", "log √10": "是實數。", "10^{−\\frac{1}{2}}": "是正的實數。"},
				 "nudge": "根號裡面是負的就不是實數。", "line": "√{3 − 2√10}、(−10)^{\\frac{1}{2}} 不是實數"},
				_f("算出來", "化成 10 的次方", "\\frac{1}{√10} = 10^{[0]}、log √10 = [1]", ["-1/2", "1/2"],
					"\\frac{1}{√10} = 10^{−\\frac{1}{2}}（和最後一個一樣）、log √10 = \\frac{1}{2}", "√10 = 10^{\\frac{1}{2}}。", T_DEF),
				_f("數一數", "幾個不同的點", "相異點 [0] 個", ["2"], "數線上有 2 個不同的點", "10^{−\\frac{1}{2}} 和 \\frac{1}{2}。", T_DEF),
			 ]},
			{"eq": "這 6 個數，數線上有幾個不同的點？",
			 "field": [
				{"k": "seeds", "bins": ["x ∈ ℝ", "x ∉ ℝ"], "at": 0, "hl": [],
				 "seeds": [["√{5 − 2√7}", 1], ["\\frac{1}{∛10}", 0], ["(−4)^{\\frac{1}{2}}", 1], ["log ∛10", 0], ["10^{−\\frac{1}{3}}", 0], ["log 1", 0]]},
				{"k": "nline", "x": [-0.5, 1], "tick": 0.5, "pts": [_pt(pow(10.0, -1.0 / 3.0), "10^{−\\frac{1}{3}}", 2), _pt(1.0 / 3.0, "\\frac{1}{3}", 2, "cyan").merged({"below": true}), _pt(0.0, "0", 2, "lime")]}],
			 "steps": [
				{"kind": "lsort", "name": "是實數嗎", "q": "放進籃子", "item": 0, "tag": T_DEF,
				 "why": {"√{5 − 2√7}": "5 − 2√7 < 0，開不了平方。", "(−4)^{\\frac{1}{2}}": "負數不能開平方。",
					"\\frac{1}{∛10}": "是正的實數。", "log ∛10": "是實數。", "10^{−\\frac{1}{3}}": "是正的實數。", "log 1": "log 1 = 0，是實數。"},
				 "nudge": "根號裡面是負的就不是實數。", "line": "√{5 − 2√7}、(−4)^{\\frac{1}{2}} 不是實數"},
				_f("算出來", "化成 10 的次方", "\\frac{1}{∛10} = 10^{[0]}、log ∛10 = [1]、log 1 = [2]", ["-1/3", "1/3", "0"],
					"\\frac{1}{∛10} = 10^{−\\frac{1}{3}}（和第五個一樣）、log ∛10 = \\frac{1}{3}、log 1 = 0", "∛10 = 10^{\\frac{1}{3}}。", T_DEF),
				_f("數一數", "幾個不同的點", "相異點 [0] 個", ["3"], "數線上有 3 個不同的點", "10^{−\\frac{1}{3}}、\\frac{1}{3}、0。", T_DEF),
			 ]},
		 ]},

		{"id": "guess2", "chapter": 1, "type": "forge", "title": "自己發現 log 2",
		 "story": "不查表，也估得出 log 2。",
		 "insight": "找一個差不多是 10 的次方的數：2^{10} = 1024 ≈ 10^{3}\n兩邊取 log：10log 2 ≈ 3 ⇒ log 2 ≈ 0.3。",
		 "variants": [
			{"eq": "不查表，估出 log 2 和 log 3",
			 "field": [{"k": "nline", "x": [0, 1], "logticks": true, "pts": [_pt(_lg(2.0), "0.301", 2), _pt(_lg(3.0), "0.477", 4, "cyan")]}],
			 "steps": [
				_f("2 的 10 次方", "2^{10} 是多少", "2^{10} = [0] ≈ 10^{[1]}", ["1024", "3"], "2^{10} = 1024 ≈ 10^{3}", "2^{10} = 1024，差不多是 1000。", T_DEF),
				_dot(_f("log 2", "10log 2 ≈ 3", "log 2 ≈ [0]", ["0.3"], "log 2 ≈ 0.3（真正的值 0.3010）", "兩邊除以 10。", T_DEF), 0.002),
				_f("3 的 4 次方", "3^{4} 是多少", "3^{4} = [0] ≈ 80 = 2^{3} × 10", ["81"], "3^{4} = 81 ≈ 2^{3} × 10", "3 × 3 × 3 × 3。", T_DEF),
				_dot(_f("log 3", "4log 3 ≈ 3log 2 + 1", "log 3 ≈ [0]", ["0.475"], "log 3 ≈ \\frac{0.9 + 1}{4} = 0.475（真正的值 0.4771）",
					"3 × 0.3 + 1 = 1.9，再除以 4。", T_RULE), 0.006),
			 ]},
			{"eq": "不查表，估出 log 2 和 log 7",
			 "field": [{"k": "nline", "x": [0, 1], "logticks": true, "pts": [_pt(_lg(2.0), "0.301", 2), _pt(_lg(7.0), "0.845", 4, "cyan")]}],
			 "steps": [
				_f("2 的 10 次方", "2^{10} 是多少", "2^{10} = [0] ≈ 10^{[1]}", ["1024", "3"], "2^{10} = 1024 ≈ 10^{3}", "2^{10} = 1024，差不多是 1000。", T_DEF),
				_dot(_f("log 2", "10log 2 ≈ 3", "log 2 ≈ [0]", ["0.3"], "log 2 ≈ 0.3（真正的值 0.3010）", "兩邊除以 10。", T_DEF), 0.002),
				_f("7 的平方", "7^{2} 是多少", "7^{2} = [0] ≈ 50 = \\frac{100}{2}", ["49"], "7^{2} = 49 ≈ \\frac{100}{2}", "7 × 7。", T_DEF),
				_dot(_f("log 7", "2log 7 ≈ 2 − log 2", "log 7 ≈ [0]", ["0.85"], "log 7 ≈ \\frac{2 − 0.3}{2} = 0.85（真正的值 0.8451）",
					"2 − 0.3 = 1.7，再除以 2。", T_RULE), 0.006),
			 ]},
		 ]},

		{"id": "pow", "chapter": 1, "type": "forge", "title": "10 的 log 次方",
		 "story": "10 的 log a 次方，就回到 a。",
		 "insight": "10^{log a} = a\n100^{log 3} = (10^{log 3})^{2} = 3^{2}、(√10)^{log 16} = 16^{\\frac{1}{2}}。",
		 "variants": [
			{"eq": "化簡：100^{log 3}、(√10)^{log 16}、(∛100)^{log \\frac{27}{8}}",
			 "steps": [
				_f("關鍵", "10^{log 3}", "10^{log 3} = [0]", ["3"], "10^{log a} = a", "log 3 就是 10 的幾次方等於 3。", T_DEF),
				_f("100", "100 = 10^{2}", "100^{log 3} = (10^{log 3})^{[0]} = [1]", ["2", "9"], "100^{log 3} = 3^{2} = 9", "100 = 10^{2}。", T_DEF),
				_f("√10", "√10 = 10^{\\frac{1}{2}}", "(√10)^{log 16} = 16^{[0]} = [1]", ["1/2", "4"], "(√10)^{log 16} = 16^{\\frac{1}{2}} = 4", "√10 = 10^{\\frac{1}{2}}。", T_DEF),
				_f("∛100", "∛100 = 10^{\\frac{2}{3}}", "(∛100)^{log \\frac{27}{8}} = (\\frac{27}{8})^{[0]} = [1]", ["2/3", "9/4"],
					"(∛100)^{log \\frac{27}{8}} = (\\frac{27}{8})^{\\frac{2}{3}} = \\frac{9}{4}", "∛100 = 10^{\\frac{2}{3}}，(\\frac{27}{8})^{\\frac{1}{3}} = \\frac{3}{2}。", T_DEF),
			 ]},
			{"eq": "a = log \\frac{√10}{1000}、b = (\\frac{1}{10})^{log 3}、c = 100^{log 2}\n√{a^{2} + b^{2} + c^{2} + 2ab − 2bc − 2ca} = ？",
			 "steps": [
				_f("a", "化成 10 的次方", "a = [0]", ["-5/2"], "a = log 10^{\\frac{1}{2} − 3} = −\\frac{5}{2}", "√10 = 10^{\\frac{1}{2}}，1000 = 10^{3}。", T_DEF),
				_f("b、c", "10 的 log 次方", "b = [0]、c = [1]", ["1/3", "4"], "b = 10^{−log 3} = \\frac{1}{3}、c = 10^{2log 2} = 4", "\\frac{1}{10} = 10^{−1}、100 = 10^{2}。", T_DEF),
				_c("完全平方", "根號裡面是", ["(a + b − c)^{2}", "(a − b + c)^{2}", "(a + b + c)^{2}"], 0,
					"2ab 是正的，−2bc、−2ca 是負的：c 帶負號。", "看交叉項的正負。", "根號裡面是 (a + b − c)^{2}", T_DEF),
				_f("答案", "開根號", "= |a + b − c| = [0]", ["37/6"], "= |−\\frac{5}{2} + \\frac{1}{3} − 4| = \\frac{37}{6}", "開根號要加絕對值。", T_DEF),
			 ]},
		 ]},

		{"id": "rule", "chapter": 1, "type": "forge", "title": "計算尺",
		 "story": "兩把對數尺，長度相加就是相乘。",
		 "insight": "log ab = log a + log b：計算尺上長度相加就是相乘\nlog \\frac{a}{b} = log a − log b、log a^{r} = r log a。",
		 "variants": [
			{"eq": "2log 3 + 3log 2 − \\frac{1}{2}log 36 = log k\nk = ？",
			 "field": [{"k": "rule", "m": "m", "read": 3, "at": 1}],
			 "steps": [
				_slide("計算尺", "上尺的 1 對到下尺的 2", "m", 1, 9, 1, 1, 2, "上尺的 1 對齊 {m}", "上尺的 1 對齊下尺的 2",
					"拖滑桿，讓上尺的 1 停在下尺的 2。", T_RULE),
				_f("讀尺", "上尺的 3 底下是幾", "2 × 3 = [0]", ["6"], "log 2 + log 3 = log 6：長度相加就是相乘", "看上尺 3 的正下方。", T_RULE),
				_f("合併", "對數律", "2log 3 + 3log 2 − \\frac{1}{2}log 36 = log \\frac{[0] × [1]}{[2]}", ["9", "8", "6"],
					"= log \\frac{3^{2} × 2^{3}}{36^{\\frac{1}{2}}} = log \\frac{9 × 8}{6}", "r log a = log a^{r}，加是乘、減是除。", T_RULE, "perm"),
				_f("答案", "k 是多少", "k = [0]", ["12"], "k = 12", "\\frac{72}{6}。", T_RULE),
			 ]},
			{"eq": "log(√13 + √3) + log(√13 − √3) = ？",
			 "field": [{"k": "rule", "m": "m", "read": 5, "at": 1}],
			 "steps": [
				_slide("計算尺", "上尺的 1 對到下尺的 2", "m", 1, 9, 1, 1, 2, "上尺的 1 對齊 {m}", "上尺的 1 對齊下尺的 2",
					"拖滑桿，讓上尺的 1 停在下尺的 2。", T_RULE),
				_f("讀尺", "上尺的 5 底下是幾", "2 × 5 = [0]", ["10"], "log 2 + log 5 = log 10 = 1", "看上尺 5 的正下方。", T_RULE),
				_f("相乘", "平方差", "(√13 + √3)(√13 − √3) = [0]", ["10"], "log(√13 + √3) + log(√13 − √3) = log 10", "13 − 3。", T_RULE),
				_f("答案", "log 10", "= [0]", ["1"], "= log 10 = 1", "10 = 10^{1}。", T_RULE),
			 ]},
			{"eq": "log p = 1.2、log q = 2.5、log r = 3.1\n\\frac{p^{3}q}{r} = ？",
			 "field": [{"k": "rule", "m": "m", "read": 3, "at": 1}],
			 "steps": [
				_slide("計算尺", "上尺的 3 對到下尺的 6", "m", 1, 9, 1, 1, 2, "上尺的 1 對齊 {m}", "上尺的 3 對齊下尺的 6",
					"上尺的 3 要停在下尺的 6 上面。", T_RULE),
				_f("讀尺", "上尺的 1 對著幾", "\\frac{6}{3} = [0]", ["2"], "log 6 − log 3 = log 2：長度相減就是相除", "看上尺 1 的正下方。", T_RULE),
				_dot(_f("合併", "對數律", "log \\frac{p^{3}q}{r} = 3log p + log q − log r = [0]", ["3"], "log \\frac{p^{3}q}{r} = 3.6 + 2.5 − 3.1 = 3",
					"3 × 1.2 + 2.5 − 3.1。", T_RULE)),
				_f("答案", "真數", "\\frac{p^{3}q}{r} = [0]", ["1000"], "\\frac{p^{3}q}{r} = 10^{3} = 1000", "log x = 3 ⇒ x = 10^{3}。", T_RULE),
			 ]},
		 ]},

		{"id": "shift", "chapter": 1, "type": "forge", "title": "首數平移",
		 "story": "乘 1000，就往上爬 3 階。",
		 "insight": "x 乘 10^{n}，log x 就加 n：log 1000x = log x + 3\n數字一樣、小數點不一樣，log 只差整數。",
		 "variants": [
			{"eq": "log x = 2.71\nlog 1000x、log \\frac{x}{10} 是多少？",
			 "field": [{"k": "nline", "x": [0, 6], "stair": true, "pts": [_pt(2.71, "x"), _pt(5.71, "1000x", 1, "cyan"), _pt(1.71, "\\frac{x}{10}", 2, "lime")]}],
			 "steps": [
				_dot(_f("乘 1000", "log 1000 = 3", "log 1000x = 2.71 + [0] = [1]", ["3", "5.71"], "log 1000x = log 1000 + log x = 5.71", "log 1000 = 3。", T_SHIFT)),
				_dot(_f("除以 10", "log 10 = 1", "log \\frac{x}{10} = [0]", ["1.71"], "log \\frac{x}{10} = 2.71 − 1 = 1.71", "log \\frac{x}{10} = log x − log 10。", T_SHIFT)),
			 ]},
			{"eq": "log 169 = k\nlog 0.0169 用 k 怎麼寫？",
			 "field": [{"k": "nline", "x": [-3, 3], "stair": true, "pts": [_pt(_lg(169.0), "169"), _pt(_lg(0.0169), "0.0169", 1, "cyan")]}],
			 "steps": [
				_f("搬小數點", "0.0169 和 169", "0.0169 = 169 × 10^{[0]}", ["-4"], "0.0169 = 169 × 10^{−4}", "小數點往左搬 4 位。", T_SHIFT),
				_f("寫成 k", "log 加減", "log 0.0169 = k − [0]", ["4"], "log 0.0169 = k − 4", "log 10^{−4} = −4。", T_SHIFT),
			 ]},
		 ]},

		{"id": "ratio", "chapter": 1, "type": "forge", "title": "用 log 比倍數",
		 "story": "差幾階，就差 10 的幾次方倍。",
		 "insight": "log a − log b = log \\frac{a}{b}\nlog 差 −3 ⇒ a 是 b 的 10^{−3} = \\frac{1}{1000} 倍。",
		 "variants": [
			{"eq": "log a = −1.8、log b = 1.2\na 是 b 的幾倍？",
			 "field": [{"k": "nline", "x": [-3, 3], "stair": true, "pts": [_pt(-1.8, "a"), _pt(1.2, "b", 0, "cyan")]}],
			 "steps": [
				_f("相減", "差幾階", "log a − log b = [0]", ["-3"], "log \\frac{a}{b} = −1.8 − 1.2 = −3", "−1.8 − 1.2。", T_SHIFT),
				_f("倍數", "10 的 −3 次方", "a 是 b 的 [0] 倍", ["1/1000"], "\\frac{a}{b} = 10^{−3}：a 是 b 的 \\frac{1}{1000} 倍", "10^{−3} = \\frac{1}{1000}。", T_SHIFT),
			 ]},
			{"eq": "log a = 2.03\n0.001^{0.01} 用 a 怎麼寫？",
			 "steps": [
				_dot(_f("10 的次方", "0.001 = 10^{−3}", "0.001^{0.01} = 10^{[0]}", ["-0.03"], "0.001^{0.01} = 10^{−3 × 0.01} = 10^{−0.03}", "−3 × 0.01。", T_SHIFT)),
				_c("用 a 寫", "10^{−0.03} = ？", ["\\frac{100}{a}", "\\frac{a}{100}", "100a", "a − 2"], 0,
					"10^{−0.03} = 10^{2 − 2.03} = \\frac{10^{2}}{10^{2.03}} = \\frac{100}{a}。", "−0.03 = 2 − 2.03。", "0.001^{0.01} = \\frac{100}{a}", T_SHIFT),
			 ]},
		 ]},

		{"id": "speed1", "chapter": 1, "type": "speed", "title": "石階速算", "time": 120.0,
		 "story": "一階一階，越爬越快！",
		 "insight": "log 10^{n} = n、10^{log a} = a\nlog a + log b = log ab。",
		 "variants": [{"gen": "logs", "count": 8}]},

		# ======================= 第二章．對數的範圍與應用 =======================
		{"id": "abc", "chapter": 2, "type": "forge", "title": "log 2、3、7",
		 "story": "用 log 2、log 3、log 7 拼出別的 log。",
		 "insight": "log 20 = log 2 + log 10 = 1 + log 2\n1000^{c} = 10^{3c} = (10^{c})^{3}。",
		 "variants": [
			{"eq": "a = log 2、b = log 3、c = log 7\n哪些對？",
			 "steps": [
				_j("a + b", "a + b = log 6", true, "log 2 + log 3 = log 6。", "a + b = log 6", T_RULE),
				_j("log 20", "log 20 = 10a", false, "log 20 = log 2 + log 10 = 1 + a。", "log 20 = 1 + a", T_RULE),
				_j("1000 的 c 次方", "1000^{c} = 343", true, "1000^{c} = 10^{3c} = 7^{3} = 343。", "1000^{c} = 343", T_DEF),
				_j("log 14", "log 14 = 2c", false, "log 14 = log 2 + log 7 = a + c。", "log 14 = a + c", T_RULE),
			 ]},
			{"eq": "a = log 2、b = log 3、c = log 7\n哪些對？",
			 "steps": [
				_j("a + c", "a + c = log 14", true, "log 2 + log 7 = log 14。", "a + c = log 14", T_RULE),
				_j("log 30", "log 30 = 3b", false, "log 30 = log 3 + log 10 = 1 + b。", "log 30 = 1 + b", T_RULE),
				_j("100 的 b 次方", "100^{b} = 9", true, "100^{b} = 10^{2b} = 3^{2} = 9。", "100^{b} = 9", T_DEF),
				_j("log 3.5", "log \\frac{7}{2} = \\frac{c}{a}", false, "log \\frac{7}{2} = log 7 − log 2 = c − a。", "log \\frac{7}{2} = c − a", T_RULE),
			 ]},
		 ]},

		{"id": "between", "chapter": 2, "type": "forge", "title": "夾在哪兩階",
		 "story": "站在兩階之間，整數部分就是下面那一階。",
		 "insight": "10^{n} ≤ x < 10^{n + 1} ⇔ n ≤ log x < n + 1\nlog a = 2.6 ⇒ a = 10^{2} × 10^{0.6}，10^{0.6} ≈ 4。",
		 "variants": [
			{"eq": "log 3870 在哪兩個整數之間？",
			 "field": [{"k": "nline", "x": [-3, 5], "stair": true, "pts": [_pt(_lg(3870.0), "3870", 1), _pt(_lg(0.0387), "0.0387", 2, "cyan")]}],
			 "steps": [
				_tap("3870", "3870 站在哪裡？", 3.0, 4.0, 2.5,
					[[2.0, 3.0, "3870 比 1000 大。"], [4.0, 5.0, "3870 比 10000 小。"]],
					"1000 和 10000 之間。", "1000 < 3870 < 10000 ⇒ 3 < log 3870 < 4", T_RANGE),
				_f("很小的數", "0.0387 呢", "log 0.0387 在 [0] 和 [1] 之間", ["-2", "-1"], "0.01 < 0.0387 < 0.1 ⇒ −2 < log 0.0387 < −1",
					"0.0387 = 3870 × 10^{−5}。", T_RANGE),
			 ]},
			{"eq": "log a = 2.6，a 最接近哪一個？\nlog 2 ≈ 0.3010",
			 "field": [{"k": "nline", "x": [0, 4], "stair": true, "pts": [_pt(2.6, "a")]}],
			 "steps": [
				_f("0.6 是誰的 log", "0.6 ≈ 2 × 0.3010", "0.6 ≈ 2 × 0.3010 = log [0]", ["4"], "0.6 ≈ log 4 ⇒ 10^{0.6} ≈ 4", "2log 2 = log 2^{2}。", T_RANGE),
				_c("最接近", "a 最接近", ["400", "40", "600", "4000"], 0, "a = 10^{2} × 10^{0.6} ≈ 100 × 4 = 400。", "a = 10^{2.6} = 10^{2} × 10^{0.6}。",
					"a ≈ 400", T_RANGE),
			 ]},
		 ]},

		{"id": "range", "chapter": 2, "type": "forge", "title": "範圍審判",
		 "story": "這些值，落在哪裡？",
		 "insight": "log √{√{√10}} = \\frac{1}{8}：開三次平方根\n0.001 < 0.0035 < 0.01 ⇒ −3 < log 0.0035 < −2。",
		 "variants": [
			{"eq": "下面哪些對？",
			 "steps": [
				_j("互為反運算", "對所有正數 a：10^{log a} = log 10^{a}", true, "兩邊都是 a。", "10^{log a} = a = log 10^{a}", T_DEF),
				_j("比大小", "10^{5log 3} > 10^{3log 5}", true, "10^{5log 3} = 3^{5} = 243、10^{3log 5} = 5^{3} = 125。", "243 > 125", T_RANGE),
				_j("三層根號", "log √{√{√10}} = \\frac{1}{6}", false, "√{√{√10}} = 10^{\\frac{1}{8}}，log 是 \\frac{1}{8}。", "log √{√{√10}} = \\frac{1}{8}", T_DEF),
				_j("很小的數", "log 0.0035 在 −4 和 −3 之間", false, "0.001 < 0.0035 < 0.01，在 −3 和 −2 之間。", "−3 < log 0.0035 < −2", T_RANGE),
			 ]},
			{"eq": "下面哪些對？",
			 "steps": [
				_j("根號", "log ∜{10^{0.6}} = 0.15", true, "∜{10^{0.6}} = 10^{0.15}。", "log ∜{10^{0.6}} = 0.15", T_DEF),
				_j("比大小", "10^{2log 5} < 10^{3log 2}", false, "10^{2log 5} = 25、10^{3log 2} = 8，25 比較大。", "25 > 8", T_RANGE),
				_j("兩層根號", "log √{√10} = \\frac{1}{4}", true, "√{√10} = 10^{\\frac{1}{4}}。", "log √{√10} = \\frac{1}{4}", T_DEF),
				_j("很小的數", "log 0.042 在 −2 和 −1 之間", true, "0.01 < 0.042 < 0.1。", "−2 < log 0.042 < −1", T_RANGE),
			 ]},
		 ]},

		{"id": "db", "chapter": 2, "type": "forge", "title": "分貝計",
		 "story": "分貝加 10，聲音的強度乘 10。",
		 "insight": "d = 10log \\frac{I}{I_{0}}：分貝差 10，強度差 10 倍\n差 50 分貝 ⇒ 強度差 10^{5} 倍。",
		 "variants": [
			{"eq": "d = 10log \\frac{I}{I_{0}}，I_{0} = 10^{−12}\n圖書館 30 分貝、吹風機 80 分貝",
			 "field": [{"k": "meter", "v": "d", "ref": 30.0, "coef": 0.1, "unit": "dB", "max": 120.0, "icons": ["book", "dryer"]}],
			 "steps": [
				_slide("分貝計", "拖到吹風機", "d", 0, 120, 10, 30, 80, "d = {d} 分貝", "吹風機 80 分貝", "吹風機是 80 分貝。", T_APP),
				_f("倍數", "強度差幾倍", "強度是 10^{[0]} 倍", ["5"], "差 50 分貝：強度是 10^{5} 倍", "每 10 分貝乘 10。", T_APP),
				_j("20 和 10", "20 分貝是 10 分貝的 2 倍", false, "差 10 分貝，強度差 10 倍。", "20 分貝是 10 分貝的 10 倍", T_APP),
				_j("飛機", "強度 10^{−1}，是 110 分貝", true, "10log \\frac{10^{−1}}{10^{−12}} = 10 × 11 = 110。", "強度 10^{−1} 是 110 分貝", T_APP),
			 ]},
			{"eq": "d = 10log \\frac{I}{I_{0}}，I_{0} = 10^{−12}\n冷氣 40 分貝、吸塵器 70 分貝",
			 "field": [{"k": "meter", "v": "d", "ref": 40.0, "coef": 0.1, "unit": "dB", "max": 120.0, "icons": ["ac", "vacuum"]}],
			 "steps": [
				_slide("分貝計", "拖到吸塵器", "d", 0, 120, 10, 40, 70, "d = {d} 分貝", "吸塵器 70 分貝", "吸塵器是 70 分貝。", T_APP),
				_f("倍數", "強度差幾倍", "強度是 10^{[0]} 倍", ["3"], "差 30 分貝：強度是 10^{3} 倍", "每 10 分貝乘 10。", T_APP),
				_j("58 和 43", "58 分貝是 43 分貝的 15 倍", false, "差 15 分貝：10^{1.5} ≈ 31.6 倍。", "差 15 分貝是 10^{1.5} 倍", T_APP),
				_j("睡覺", "強度 10^{−9}，是 30 分貝", true, "10log \\frac{10^{−9}}{10^{−12}} = 10 × 3 = 30。", "強度 10^{−9} 是 30 分貝", T_APP),
			 ]},
		 ]},

		{"id": "formula", "chapter": 2, "type": "forge", "title": "對數公式",
		 "story": "log 加多少，真數就乘 10 的多少次方。",
		 "insight": "log E 加 k ⇒ E 乘 10^{k}\n地震：規模差 1，log E 差 1.5，能量差 10^{1.5} ≈ 32 倍。",
		 "variants": [
			{"eq": "T = 2 + 4log E\nT 增加 2，E 變成幾倍？",
			 "steps": [
				_f("log E", "4log E 增加 2", "log E 增加 [0]", ["1/2"], "4log E 增加 2 ⇒ log E 增加 \\frac{1}{2}", "\\frac{2}{4} = \\frac{1}{2}。", T_APP),
				_c("倍數", "E 變成幾倍？", ["√10 倍", "2 倍", "5 倍", "10 倍"], 0, "log E 加 \\frac{1}{2}，E 乘 10^{\\frac{1}{2}} = √10。",
					"10^{\\frac{1}{2}} 是多少？", "E 變成 √10 倍", T_APP),
			 ]},
			{"eq": "log E = 1.5r + 11.8，規模 6.1 和 7.2\n能量差幾倍？10^{0.65} ≈ 4.467",
			 "field": [{"k": "meter", "v": "r", "ref": 6.1, "coef": 1.5, "unit": "", "max": 9.0, "base": 4.0}],
			 "steps": [
				_slide("地震", "拖到規模 7.2", "r", 5, 9, 0.1, 6.1, 7.2, "r = {r}", "規模 6.1 → 7.2", "拖到 7.2。", T_APP),
				_dot(_f("log 差", "1.5 × 1.1", "log E 差 [0]", ["1.65"], "log E 差 1.5 × (7.2 − 6.1) = 1.65", "1.5 × 1.1。", T_APP)),
				_dot(_f("倍數", "10^{1.65}", "10^{1.65} = 10 × 10^{0.65} ≈ [0]", ["45"], "10^{1.65} ≈ 10 × 4.467 ≈ 45 倍", "10 × 4.467。", T_APP), 1.0),
			 ]},
		 ]},

		{"id": "speed2", "chapter": 2, "type": "speed", "title": "十倍速算", "time": 120.0,
		 "story": "石階一階一階亮起來！",
		 "insight": "10^{n} ≤ x < 10^{n + 1} ⇔ n ≤ log x < n + 1。",
		 "variants": [{"gen": "char", "count": 8}]},
	]
