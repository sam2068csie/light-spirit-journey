extends RefCounted
## 終焉之塔的段考風格題庫（參考各校 114 學年度高二上第二次段考的考法改編，數字與情境都換過）
##
## 每一題：
##   id      唯一代號
##   kind    judge 真假審判／roots 驗根之刃／line 數線封印／extreme 極值換元／quest 現實委託／boss 試煉大題
##   tier    難度 1～3（越高的樓層越會出到難的）
##   title   題目名稱（結算畫面會顯示）
##   stem    題目敘述（MathLabel 標記，\n 換行）
##   tmul    限時倍數（大題比較長，時間多給一點）
##   plot    （可省略）左邊的小座標圖，見 boss_tower.gd 的 Plot
##   steps   一步一步作答：
##     {t: "choice", q, opts: [正確, 錯誤…], hint, write, part}
##         選擇題。opts[0] 是正確答案（畫面上會打亂）。答錯扣一顆心、顯示 hint，可以再選。
##         write：答對後寫在左邊推導板上的一行。part：大題的小題編號，例如 "(1)"。
##     {t: "judge", q, cards: [{s: 敘述, ok: 真/假, why: 理由}]}
##         一次判斷所有敘述，整題判錯兩張以上才扣一顆心。
##     {t: "roots", q, cands: [{v: 候選根, ok: 要不要留下, why}], write}
##         把不合的根劃掉（點一下劃掉，再點一下復原），按「確認」。
##     {t: "line", q, row: 這一列的名稱, marks: [數線上的關鍵點…], seg: [每一段選不選], pt: [每個點包不包含], write}
##         數線封印：點選數線上的區段和端點。同一題連續的 line 步驟共用同一條數線，前面完成的列會留著當參考。
##         seg 有 marks.size()+1 段（由左到右），pt 有 marks.size() 個；1 = 選、0 = 不選。
const UITheme := preload("game_theme.gd")

const KIND_NAME := {"judge": "真假審判", "roots": "驗根之刃", "line": "數線封印", "extreme": "極值換元",
	"quest": "現實委託", "boss": "試煉大題"}
const KIND_COLOR := {"judge": UITheme.CYAN, "roots": UITheme.PINK, "line": UITheme.LIME,
	"extreme": UITheme.ORANGE, "quest": UITheme.VIOLET, "boss": UITheme.ROSE}


static var _items: Array = []


static func items() -> Array:
	if _items.is_empty():
		_items = (JUDGE + ROOTS + LINES + EXTREME + QUEST + BOSS).duplicate(true)
		for it in _items:
			_add_factor_steps(it)
	return _items


# ================= 自動補上「因式分解」 =================
## 推導板上寫「x^{2} − 5x + 4 ≤ 0　→　…」的那一步之後，補一題讓學生自己因式分解：
## 原本那一步只寫二次式，新的一步寫因式分解的結果（後面原本寫的範圍或解也接在後面）。
## 因式分解的選項（正解＋正負號、常數放錯的錯誤選項）沿用換元鍛造所的產生方式。

const B2 := preload("level02_bank.gd")


static func _add_factor_steps(it: Dictionary) -> void:
	var re := RegEx.new()
	re.compile("^((?:\\(\\d\\)　)?)([^=≤≥<>]*?([a-z])\\^\\{2\\}[^=≤≥<>]*?)\\s*(=|≤|≥|<|>)\\s*0(?:　→　(.*))?$")
	var steps: Array = it.steps
	var i := 0
	while i < steps.size():
		var st: Dictionary = steps[i]
		var m := re.search(String(st.get("write", "")))
		if m == null:
			i += 1
			continue
		var pre := m.get_string(1)
		var poly := m.get_string(2).strip_edges()
		var v := m.get_string(3)
		var rel := m.get_string(4)
		var rest := m.get_string(5)
		var abc := _parse_poly(poly, v)
		var fac := B2._parse_factors(rest + " = 0", v) if rest.contains(")(") else []
		if fac.size() != 2 and not abc.is_empty():
			fac = _factor_int(abc)
		if fac.size() != 2 or abc.is_empty() or B2._expand(fac) != abc:
			i += 1
			continue
		var fs := B2._factor_step({"fac_line": B2._pair_text(fac, v) + " = 0"}, v)
		var fwrite := pre.replace("(1)", "　 ").replace("(2)", "　 ").replace("(3)", "　 ") + B2._pair_text(fac, v) + " " + rel + " 0"
		if rest != "" and not rest.contains(")("):
			fwrite += "　→　" + rest
		var step := {"t": "choice", "q": "先因式分解：%s = ？" % poly, "opts": fs.options, "hint": fs.nudge, "write": fwrite}
		if st.has("part"):
			step["part"] = st.part
		st["write"] = pre + poly + " " + rel + " 0"
		steps.insert(i + 1, step)
		it["tmul"] = float(it.get("tmul", 1.0)) + 0.1
		# 圖上「完成第幾步才出現」的圖層，排在新步驟後面的要往後挪一格
		if it.has("plot"):
			for key in ["curves", "pts", "vlines"]:
				for layer in it.plot.get(key, []):
					if int(layer.get("at", 0)) > i:
						layer["at"] = int(layer.at) + 1
			if it.plot.has("band") and int(it.plot.band.get("at", 0)) > i:
				it.plot.band["at"] = int(it.plot.band.at) + 1
		i += 2


## 「2t^{2} − 9t + 4」→ [2, −9, 4]（看不懂就回傳 []）
static func _parse_poly(poly: String, v: String) -> Array:
	var re := RegEx.new()
	re.compile("^(\\d*)" + v + "\\^\\{2\\}\\s*([+−-])\\s*(\\d*)" + v + "\\s*([+−-])\\s*(\\d+)$")
	var m := re.search(poly)
	if m == null:
		return []
	var a := 1 if m.get_string(1) == "" else int(m.get_string(1))
	var b := (1 if m.get_string(3) == "" else int(m.get_string(3))) * (1 if m.get_string(2) == "+" else -1)
	var c := int(m.get_string(5)) * (1 if m.get_string(4) == "+" else -1)
	return [a, b, c]


## 整數係數的十字交乘：找 (k1·v + c1)(k2·v + c2)
static func _factor_int(abc: Array) -> Array:
	var a: int = abc[0]
	var c: int = abc[2]
	for k1 in range(1, a + 1):
		if a % k1 != 0:
			continue
		var k2 := a / k1
		for d in range(1, absi(c) + 1):
			if c % d != 0:
				continue
			for c1 in [d, -d]:
				var c2: int = c / int(c1)
				if k1 * c2 + k2 * c1 == abc[1]:
					return [[k1, c1], [k2, c2]]
	return []


static func by_id(id: String) -> Dictionary:
	for it in items():
		if it.id == id:
			return it
	return {}


# ================= 真假審判 =================

const JUDGE := [
	{"id": "j_rules", "kind": "judge", "tier": 1, "title": "對數性質", "tmul": 1.0,
		"stem": "下列關於對數的運算，哪些正確？",
		"steps": [{"t": "judge", "q": "逐一判斷每張卡片的真假。", "cards": [
			{"s": "log (2 + 3) = log 2 + log 3", "ok": false, "why": "log 2 + log 3 = log 6，不是 log 5"},
			{"s": "log_{2} 3 · log_{3} 2 = 1", "ok": true, "why": "兩個互為倒數，相乘是 1"},
			{"s": "對所有 x ≠ 0，log x^{2} = 2 log x", "ok": false, "why": "x < 0 時右邊沒有意義，應該是 2 log |x|"},
			{"s": "2^{−log_{2} 3} = −3", "ok": false, "why": "2^{−log_{2} 3} = 3^{−1} = 1/3，指數的值不會是負的"},
			{"s": "log_{√{2}} √{3} = log_{2} 3", "ok": true, "why": "底數和真數同時開平方，值不變"}]}]},

	{"id": "j_value", "kind": "judge", "tier": 1, "title": "對數求值", "tmul": 1.0,
		"stem": "下列各式的值，哪些正確？",
		"steps": [{"t": "judge", "q": "逐一判斷每張卡片的真假。", "cards": [
			{"s": "log_{2} 24 − log_{2} 3 = 3", "ok": true, "why": "log_{2} (24/3) = log_{2} 8 = 3"},
			{"s": "log_{3} 5 · log_{5} 9 = 2", "ok": true, "why": "連鎖：log_{3} 9 = 2"},
			{"s": "log_{4} 8 = 3/2", "ok": true, "why": "log_{2^{2}} 2^{3} = 3/2"},
			{"s": "5^{log_{25} 9} = 9", "ok": false, "why": "log_{25} 9 = log_{5} 3，所以 5^{log_{5} 3} = 3"},
			{"s": "log_{9} 27 = 2/3", "ok": false, "why": "log_{3^{2}} 3^{3} = 3/2，分子分母放反了"}]}]},

	{"id": "j_expcmp", "kind": "judge", "tier": 1, "title": "指數大小", "tmul": 1.0,
		"stem": "下列大小關係，哪些正確？",
		"steps": [{"t": "judge", "q": "先看底數大於 1 還是小於 1。", "cards": [
			{"s": "2^{0.3} < 2^{0.4}", "ok": true, "why": "底數 2 > 1，指數大的比較大"},
			{"s": "0.5^{0.3} < 0.5^{0.4}", "ok": false, "why": "底數 0.5 < 1 是遞減，指數大的反而小"},
			{"s": "0.3^{√{2}} < 0.6^{√{2}}", "ok": true, "why": "指數都是 √{2} > 0，底數大的比較大"},
			{"s": "3^{0.2} > 1", "ok": true, "why": "底數 > 1、指數 > 0，結果 > 1"},
			{"s": "(1/2)^{−2} < 1", "ok": false, "why": "(1/2)^{−2} = 2^{2} = 4"}]}]},

	{"id": "j_curve", "kind": "judge", "tier": 1, "title": "指數曲線上的點", "tmul": 1.0,
		"stem": "在 y = 2^{x} 的圖形上取 A、B、C、D 四點，x 坐標分別是 −1、0、1、2。",
		"plot": {"x": [-2.5, 3.0], "y": [-0.8, 5.0], "curves": [{"f": "pow(2,x)", "c": "cyan"}],
			"pts": [{"x": -1, "y": 0.5, "label": "A"}, {"x": 0, "y": 1, "label": "B"}, {"x": 1, "y": 2, "label": "C"}, {"x": 2, "y": 4, "label": "D"}]},
		"steps": [{"t": "judge", "q": "看著下面的圖判斷。", "cards": [
			{"s": "y = 2^{x} 的圖形凹口向上", "ok": true, "why": "指數函數的圖形都是凹口向上"},
			{"s": "AB、BC、CD 之中，CD 的斜率最大", "ok": true, "why": "斜率依序是 1/2、1、2，越往右越陡"},
			{"s": "直線 y = 2x 和 y = 2^{x} 恰有兩個交點", "ok": true, "why": "交在 x = 1 和 x = 2"},
			{"s": "A 和 C 對稱於 y 軸", "ok": false, "why": "A(−1, 1/2)、C(1, 2)，y 坐標不同"},
			{"s": "B 在直線 AC 的下方", "ok": true, "why": "凹口向上，弦在曲線上方，所以 B 在 AC 下方"}]}]},

	{"id": "j_logcmp", "kind": "judge", "tier": 2, "title": "對數大小", "tmul": 1.1,
		"stem": "下列大小關係，哪些正確？",
		"steps": [{"t": "judge", "q": "換成同底數，或拿 0、1 當中間值。", "cards": [
			{"s": "log_{0.5} 3 < log_{0.5} 2", "ok": true, "why": "底數 0.5 < 1 是遞減，真數大的反而小"},
			{"s": "log_{2} 5 > log_{3} 5", "ok": true, "why": "log 5 / log 2 > log 5 / log 3，分母越小越大"},
			{"s": "log_{1/2} 3 < log_{1/3} 2", "ok": true, "why": "左邊 = −log_{2} 3 < −1，右邊 = −log_{3} 2 > −1"},
			{"s": "log_{4} 5 < log_{16} 24", "ok": false, "why": "log_{16} 24 = log_{4} √{24}，而 √{24} < 5"},
			{"s": "(log_{2} 3 + log_{2} 12) / 2 < log_{2} 6", "ok": false, "why": "左邊 = (1/2)log_{2} 36 = log_{2} 6，兩邊相等"}]}]},

	{"id": "j_graph", "kind": "judge", "tier": 2, "title": "圖形的對稱與平移", "tmul": 1.1,
		"stem": "下列關於圖形的敘述，哪些正確？",
		"steps": [{"t": "judge", "q": "想一想每個圖形怎麼變過來的。", "cards": [
			{"s": "y = 0.5^{x} 與 y = 2^{x} 的圖形對稱於 y 軸", "ok": true, "why": "0.5^{x} = 2^{−x}，x 換成 −x"},
			{"s": "y = 2^{x} 與 y = log_{2} x 的圖形對稱於直線 y = x", "ok": true, "why": "兩者互為反函數"},
			{"s": "若 a > 1，y = a^{x} 與 y = log_{a} x 的圖形一定沒有交點", "ok": false, "why": "例如 a = √{2}，兩圖形交於 (2, 2) 和 (4, 4)"},
			{"s": "y = log_{2} (2x) 是 y = log_{2} x 向上平移 1 單位", "ok": true, "why": "log_{2} (2x) = 1 + log_{2} x"},
			{"s": "y = 2 log_{2} x 可由 y = log_{2} x 平移得到", "ok": false, "why": "乘 2 是鉛直伸縮，平移做不到"}]}]},

	{"id": "j_fg", "kind": "judge", "tier": 2, "title": "指對互換", "tmul": 1.1,
		"stem": "設 a > 0 且 a ≠ 1，f(x) = a^{x}，g(x) = log_{a} x。下列敘述哪些正確？",
		"steps": [{"t": "judge", "q": "可以代一個 a 試試看。", "cards": [
			{"s": "若 f(2) = 9，則 g(27) = 3", "ok": true, "why": "a^{2} = 9，a = 3，log_{3} 27 = 3"},
			{"s": "g(40) − g(5) = g(16) − g(2)", "ok": true, "why": "兩邊都是 log_{a} 8"},
			{"s": "f(5) − f(3) = f(4) − f(2)", "ok": false, "why": "左邊 = a^{3}(a^{2} − 1)，右邊 = a^{2}(a^{2} − 1)，a ≠ 1 時不相等"},
			{"s": "y = g(x) 圖形上任兩點連線的斜率必為正", "ok": false, "why": "0 < a < 1 時 g 是遞減，斜率是負的"},
			{"s": "對所有 x > 0，f(g(x)) = x", "ok": true, "why": "a^{log_{a} x} = x"}]}]},

	{"id": "j_digits", "kind": "judge", "tier": 2, "title": "位數與首位", "tmul": 1.25,
		"stem": "已知 log 2 ≈ 0.3010，log 3 ≈ 0.4771。設 a = 2^{40}，b = 3^{20}。",
		"steps": [{"t": "judge", "q": "先算 log a、log b，再判斷。", "cards": [
			{"s": "a 是 13 位數", "ok": true, "why": "log a = 40 × 0.3010 = 12.04，首數 12，所以是 13 位數"},
			{"s": "b 的最高位數字是 3", "ok": true, "why": "log b = 9.542，0.477 < 0.542 < 0.602，介於 log 3 和 log 4 之間"},
			{"s": "a + b 是 14 位數", "ok": false, "why": "a ≈ 1.1 × 10^{12}，b 只有 10 位數，加起來還是 13 位數"},
			{"s": "1/a 寫成小數，從小數點後第 12 位開始不為 0", "ok": false, "why": "log (1/a) = −12.04 = −13 + 0.96，從第 13 位開始"},
			{"s": "ab 是 22 位數", "ok": true, "why": "log ab = 12.04 + 9.542 = 21.582，首數 21"}]}]},

	{"id": "j_roots", "kind": "judge", "tier": 3, "title": "交點的個數", "tmul": 1.25,
		"stem": "下列各方程式，哪些恰有兩個相異實根？",
		"steps": [{"t": "judge", "q": "在腦中畫出兩邊的圖形，數交點。", "cards": [
			{"s": "x^{2} = 2^{x}", "ok": false, "why": "x = 2、x = 4，再加上負數那邊還有一個，共 3 個"},
			{"s": "2^{x} = x + 1", "ok": true, "why": "x = 0 和 x = 1；凹口向上的曲線和直線最多交兩點"},
			{"s": "log_{2} x = x − 1", "ok": true, "why": "x = 1 和 x = 2，是上一題對 y = x 鏡射的結果"},
			{"s": "(1/2)^{x} = x", "ok": false, "why": "左邊遞減、右邊遞增，只交一點"},
			{"s": "2^{|x|} = 3", "ok": true, "why": "x = ±log_{2} 3"}]}]},

	{"id": "j_shift", "kind": "judge", "tier": 3, "title": "平移與鏡射", "tmul": 1.25,
		"stem": "f(x) = log_{2} x，g(x) = log_{2} (x + 2)，h(x) = log_{2} 4x，p(x) = 2 log_{2} x，q(x) = 2^{x + 2}。",
		"steps": [{"t": "judge", "q": "把每個函數都化成 f(x) 的變形。", "cards": [
			{"s": "y = g(x) 的圖形可由 y = f(x) 平移得到", "ok": true, "why": "向左平移 2 單位"},
			{"s": "y = h(x) 的圖形可由 y = f(x) 平移得到", "ok": true, "why": "h(x) = 2 + log_{2} x，向上平移 2 單位"},
			{"s": "y = p(x) 的圖形可由 y = f(x) 平移得到", "ok": false, "why": "p 是 f 的鉛直伸縮 2 倍"},
			{"s": "y = q(x) 對直線 y = x 鏡射後是 y = log_{2} x − 2", "ok": true, "why": "x = 2^{y + 2}，所以 y = log_{2} x − 2"},
			{"s": "y = f(x)、y = h(x)、y = p(x) 的漸近線都相同", "ok": true, "why": "漸近線都是 y 軸（x = 0）"}]}]},

	{"id": "j_ab", "kind": "judge", "tier": 3, "title": "指數條件", "tmul": 1.25,
		"stem": "設 2^{a} = 3，3^{b} = 4。下列敘述哪些正確？",
		"steps": [{"t": "judge", "q": "先把 a、b 寫成對數。", "cards": [
			{"s": "ab = 2", "ok": true, "why": "a = log_{2} 3，b = log_{3} 4，連鎖得 log_{2} 4 = 2"},
			{"s": "a > 3/2", "ok": true, "why": "2^{3/2} = 2√{2} ≈ 2.83 < 3"},
			{"s": "b > a", "ok": false, "why": "b = log_{3} 4 < 3/2 < a（因為 3^{3/2} ≈ 5.2 > 4）"},
			{"s": "4^{a} = 9", "ok": true, "why": "4^{a} = (2^{a})^{2} = 9"},
			{"s": "8^{a} < 9^{b}", "ok": false, "why": "8^{a} = 3^{3} = 27，9^{b} = 4^{2} = 16"}]}]},

	{"id": "j_big", "kind": "judge", "tier": 3, "title": "大數的首尾", "tmul": 1.25,
		"stem": "已知 log 2 ≈ 0.3010，log 3 ≈ 0.4771。設 x = 6^{20}。",
		"steps": [{"t": "judge", "q": "log 6 = log 2 + log 3 ≈ 0.7781。", "cards": [
			{"s": "x 是 16 位數", "ok": true, "why": "log x = 20 × 0.7781 = 15.562，首數 15"},
			{"s": "x 的最高位數字是 4", "ok": false, "why": "0.477 < 0.562 < 0.602，最高位數字是 3"},
			{"s": "x = 10^{20 log 6}", "ok": true, "why": "10^{log x} = x，而 log x = 20 log 6"},
			{"s": "1/x 寫成小數，從小數點後第 15 位開始不為 0", "ok": false, "why": "log (1/x) = −16 + 0.438，從第 16 位開始"},
			{"s": "1/x 小數點後第一個不為 0 的數字是 2", "ok": true, "why": "0.301 < 0.438 < 0.477，介於 log 2 和 log 3 之間"}]}]},
]


# ================= 驗根之刃 =================

const ROOTS := [
	{"id": "r_logsum", "kind": "roots", "tier": 1, "title": "對數方程式", "tmul": 1.0,
		"stem": "解方程式 log (x − 9) + log x = 1。",
		"steps": [
			{"t": "choice", "q": "先找出定義域（真數 > 0；底數 > 0 且 ≠ 1）：", "opts": ["x > 9", "x > 0", "0 < x < 9", "x > −9"],
				"hint": "x − 9 > 0 且 x > 0，兩個都要成立", "write": "定義域：x > 9"},
			{"t": "choice", "q": "兩個 log 相加，先合併成？",
				"opts": ["log [x(x − 9)] = 1", "log (2x − 9) = 1", "log x · log (x − 9) = 1", "log [(x − 9)/x] = 1"],
				"hint": "log M + log N = log MN", "write": "log [x(x − 9)] = 1"},
			{"t": "choice", "q": "所以 x(x − 9) 等於多少？",
				"opts": ["10", "1", "0", "9"], "hint": "log N = 1 代表 N = 10^{1}",
				"write": "x(x − 9) = 10"},
			{"t": "choice", "q": "展開、移項：", "opts": ["x^{2} − 9x − 10 = 0", "x^{2} − 9x + 10 = 0", "x^{2} + 9x − 10 = 0", "x^{2} − 10x − 9 = 0"],
				"hint": "x(x − 9) = x^{2} − 9x，再把 10 移到左邊", "write": "x^{2} − 9x − 10 = 0　→　(x − 10)(x + 1) = 0"},
			{"t": "roots", "q": "和定義域 x > 9 比對，把不合的根劃掉。", "cands": [
				{"v": "x = 10", "ok": true, "why": "log 1 + log 10 = 1 ✓"},
				{"v": "x = −1", "ok": false, "why": "log (−10) 真數是負的，沒有意義"}],
				"write": "答：x = 10"}]},

	{"id": "r_sub2", "kind": "roots", "tier": 1, "title": "指數換元", "tmul": 1.0,
		"stem": "解方程式 4^{x} + 2^{x + 1} − 24 = 0。",
		"steps": [
			{"t": "choice", "q": "令 t = 2^{x}，方程式變成？", "pre": "令 t = 2^{x}（t > 0）",
				"opts": ["t^{2} + 2t − 24 = 0", "t^{2} + t − 24 = 0", "2t + 2t − 24 = 0", "t^{2} + 2^{t} − 24 = 0"],
				"hint": "4^{x} = (2^{x})^{2} = t^{2}，2^{x + 1} = 2 · 2^{x} = 2t",
				"write": "t^{2} + 2t − 24 = 0　→　(t + 6)(t − 4) = 0"},
			{"t": "roots", "q": "t 的兩個解，哪個不合？劃掉它。", "cands": [
				{"v": "t = 4", "ok": true, "why": "2^{x} = 4 可以做到"},
				{"v": "t = −6", "ok": false, "why": "t = 2^{x} 一定大於 0"}],
				"write": "t = −6 不合（t > 0）　→　2^{x} = 4"},
			{"t": "choice", "q": "所以 x = ？", "opts": ["2", "4", "log_{2} 6", "−6"],
				"hint": "2^{x} = 4 = 2^{2}", "write": "答：x = 2"}]},

	{"id": "r_logsq", "kind": "roots", "tier": 2, "title": "對數換元", "tmul": 1.0,
		"stem": "解方程式 (log_{2} x)^{2} − log_{2} x^{3} + 2 = 0。",
		"steps": [
			{"t": "choice", "q": "先找出定義域（真數 > 0；底數 > 0 且 ≠ 1）：", "opts": ["x > 0", "x ≠ 0", "x > 1", "全體實數"],
				"hint": "log_{2} x 的真數 x > 0", "write": "定義域：x > 0"},
			{"t": "choice", "q": "令 u = log_{2} x，方程式變成？", "pre": "log_{2} x^{3} = 3 log_{2} x；令 u = log_{2} x",
				"opts": ["u^{2} − 3u + 2 = 0", "u^{2} − u^{3} + 2 = 0", "u^{2} − 3 + 2 = 0", "2u − 3u + 2 = 0"],
				"hint": "log_{2} x^{3} = 3 log_{2} x = 3u",
				"write": "u^{2} − 3u + 2 = 0　→　u = 1 或 u = 2"},
			{"t": "roots", "q": "換回 x（x = 2^{u}），和定義域 x > 0 比對：有沒有不合的根？（沒有就直接確認）", "cands": [
				{"v": "x = 2", "ok": true, "why": "x > 0，代回成立"},
				{"v": "x = 4", "ok": true, "why": "x > 0，代回成立"}],
				"write": "x = 2^{1} = 2、x = 2^{2} = 4，都 > 0　→　答：x = 2 或 x = 4"}]},

	{"id": "r_base", "kind": "roots", "tier": 2, "title": "底數陷阱", "tmul": 1.0,
		"stem": "解方程式 log_{x} (2x + 3) = 2。",
		"steps": [
			{"t": "choice", "q": "先找出定義域（真數 > 0；底數 > 0 且 ≠ 1）：", "opts": ["x > 0 且 x ≠ 1", "x > −3/2", "x > 0", "x ≠ 1"],
				"hint": "底數 x > 0 且 x ≠ 1；這時 2x + 3 > 0 自動成立", "write": "定義域：x > 0 且 x ≠ 1"},
			{"t": "choice", "q": "依照對數的定義，改寫成？",
				"opts": ["x^{2} = 2x + 3", "2^{x} = 2x + 3", "2x + 3 = 2x", "x = (2x + 3)^{2}"],
				"hint": "log_{a} N = k 代表 a^{k} = N", "write": "x^{2} = 2x + 3"},
			{"t": "choice", "q": "移項：", "opts": ["x^{2} − 2x − 3 = 0", "x^{2} + 2x − 3 = 0", "x^{2} − 2x + 3 = 0", "x^{2} + 2x + 3 = 0"],
				"hint": "2x + 3 整個移到左邊要變號", "write": "x^{2} − 2x − 3 = 0　→　(x − 3)(x + 1) = 0"},
			{"t": "roots", "q": "和定義域比對（底數也有條件！），把不合的根劃掉。", "cands": [
				{"v": "x = 3", "ok": true, "why": "log_{3} 9 = 2 ✓"},
				{"v": "x = −1", "ok": false, "why": "底數必須大於 0 且不等於 1"}],
				"write": "答：x = 3"}]},

	{"id": "r_diff", "kind": "roots", "tier": 2, "title": "真數檢查", "tmul": 1.0,
		"stem": "解方程式 log_{2} (x + 1) + log_{2} (x − 1) = 3。",
		"steps": [
			{"t": "choice", "q": "先找出定義域（真數 > 0；底數 > 0 且 ≠ 1）：", "opts": ["x > 1", "x > −1", "−1 < x < 1", "x > 0"],
				"hint": "x + 1 > 0 且 x − 1 > 0，取比較嚴格的", "write": "定義域：x > 1"},
			{"t": "choice", "q": "合併之後得到？", "opts": ["x^{2} − 1 = 8", "x^{2} − 1 = 3", "2x = 8", "x^{2} − 1 = 6"],
				"hint": "(x + 1)(x − 1) = 2^{3}", "write": "log_{2} (x + 1)(x − 1) = 3　→　x^{2} − 1 = 8　→　x^{2} = 9　→　x = ±3"},
			{"t": "roots", "q": "和定義域 x > 1 比對，把不合的根劃掉。", "cands": [
				{"v": "x = 3", "ok": true, "why": "log_{2} 4 + log_{2} 2 = 3 ✓"},
				{"v": "x = −3", "ok": false, "why": "x − 1 = −4，真數是負的"}],
				"write": "答：x = 3"}]},

	{"id": "r_pq", "kind": "roots", "tier": 3, "title": "兩根的和", "tmul": 1.15,
		"stem": "方程式 2 · 9^{x} − 3^{x + 2} + 4 = 0 的兩根為 p、q，求 27^{p + q}。",
		"steps": [
			{"t": "choice", "q": "令 t = 3^{x}，方程式變成？", "pre": "令 t = 3^{x}（t > 0）",
				"opts": ["2t^{2} − 9t + 4 = 0", "2t^{2} − 3t + 4 = 0", "2t − 9t + 4 = 0", "18t^{2} − 9t + 4 = 0"],
				"hint": "3^{x + 2} = 9 · 3^{x} = 9t", "write": "2t^{2} − 9t + 4 = 0　→　(2t − 1)(t − 4) = 0"},
			{"t": "roots", "q": "兩個 t 都要檢查：哪個不合？（都合就直接確認）", "cands": [
				{"v": "t = 4", "ok": true, "why": "t > 0 就可以"},
				{"v": "t = 1/2", "ok": true, "why": "分數也大於 0，可以"}],
				"write": "兩個 t 就是 3^{p}、3^{q}：3^{p} · 3^{q} = 4 × (1/2) = 2　→　3^{p + q} = 2"},
			{"t": "choice", "q": "27^{p + q} = ？", "opts": ["8", "2", "6", "54"],
				"hint": "27^{p + q} = (3^{p + q})^{3}", "write": "答：27^{p + q} = (3^{p + q})^{3} = 2^{3} = 8"}]},

	{"id": "r_xlog", "kind": "roots", "tier": 3, "title": "取對數", "tmul": 1.15,
		"stem": "解方程式 x^{log x} = 100x。",
		"steps": [
			{"t": "choice", "q": "先找出定義域（真數 > 0；底數 > 0 且 ≠ 1）：", "opts": ["x > 0", "x ≠ 0", "x > 1", "全體實數"],
				"hint": "次方裡有 log x，x 要 > 0", "write": "定義域：x > 0"},
			{"t": "choice", "q": "兩邊取 log，令 u = log x，得到？", "pre": "兩邊取 log：log x^{log x} = log (100x)",
				"opts": ["u^{2} = 2 + u", "u^{2} = 100u", "2u = 2 + u", "u = 2u"],
				"hint": "log x^{log x} = (log x)(log x)，log 100x = 2 + log x",
				"write": "u^{2} − u − 2 = 0　→　u = 2 或 u = −1"},
			{"t": "roots", "q": "換回 x（x = 10^{u}），和定義域 x > 0 比對：有沒有不合的根？", "cands": [
				{"v": "x = 100", "ok": true, "why": "100^{2} = 10000 = 100 × 100 ✓"},
				{"v": "x = 1/10", "ok": true, "why": "u = −1 是 log 的值，x = 10^{−1} > 0，可以"}],
				"write": "x = 10^{2} = 100、x = 10^{−1} = 1/10，都 > 0　→　答：x = 100 或 x = 1/10"}]},
]


# ================= 數線封印 =================

const LINES := [
	{"id": "l_flip", "kind": "line", "tier": 1, "title": "底數小於 1", "tmul": 1.0,
		"stem": "解不等式 log_{0.5} (x − 1) > log_{0.5} (5 − x)。",
		"steps": [
			{"t": "line", "q": "先封印定義域：兩個真數都要大於 0。", "row": "定義域",
				"marks": ["1", "3", "5"], "seg": [0, 1, 1, 0], "pt": [0, 1, 0], "write": "定義域：1 < x < 5"},
			{"t": "choice", "q": "底數 0.5 < 1，拿掉 log 後不等號？",
				"opts": ["反向：x − 1 < 5 − x", "不變：x − 1 > 5 − x"],
				"hint": "底數小於 1 的對數是遞減函數", "write": "x − 1 < 5 − x　→　x < 3"},
			{"t": "line", "q": "和定義域取交集，封印最後的解。", "row": "解",
				"marks": ["1", "3", "5"], "seg": [0, 1, 0, 0], "pt": [0, 0, 0], "write": "答：1 < x < 3"}]},

	{"id": "l_expineq", "kind": "line", "tier": 1, "title": "指數不等式", "tmul": 1.0,
		"stem": "解不等式 (1/2)^{x^{2} − 3x} ≥ (1/4)^{x − 2}。",
		"steps": [
			{"t": "choice", "q": "右邊化成底數 1/2：", "opts": ["(1/2)^{2x − 4}", "(1/2)^{x − 4}", "(1/2)^{2x − 2}", "(1/2)^{x^{2} − 4}"],
				"hint": "1/4 = (1/2)^{2}", "write": "(1/2)^{x^{2} − 3x} ≥ (1/2)^{2x − 4}"},
			{"t": "choice", "q": "比較指數，得到？", "opts": ["x^{2} − 3x ≤ 2x − 4", "x^{2} − 3x ≥ 2x − 4"],
				"hint": "底數 1/2 < 1，不等號要反向", "write": "x^{2} − 3x ≤ 2x − 4（底數 < 1，反向）"},
			{"t": "choice", "q": "移項整理：", "opts": ["x^{2} − 5x + 4 ≤ 0", "x^{2} − x − 4 ≤ 0", "x^{2} − 5x − 4 ≤ 0", "x^{2} + 5x + 4 ≤ 0"],
				"hint": "2x − 4 整個移到左邊要變號", "write": "x^{2} − 5x + 4 ≤ 0　→　1 ≤ x ≤ 4"},
			{"t": "line", "q": "封印解的範圍（注意等號）。", "row": "解",
				"marks": ["1", "4"], "seg": [0, 1, 0], "pt": [1, 1], "write": "答：1 ≤ x ≤ 4"}]},

	{"id": "l_twolog", "kind": "line", "tier": 2, "title": "合併再比較", "tmul": 1.15,
		"stem": "解不等式 log_{0.5} (x − 1) + log_{0.5} (x − 2) ≥ log_{0.5} 6。",
		"steps": [
			{"t": "line", "q": "先封印定義域。", "row": "定義域",
				"marks": ["−1", "2", "4"], "seg": [0, 0, 1, 1], "pt": [0, 0, 1], "write": "定義域：x > 2"},
			{"t": "choice", "q": "合併並拿掉 log 之後？",
				"opts": ["(x − 1)(x − 2) ≤ 6", "(x − 1)(x − 2) ≥ 6", "(x − 1) + (x − 2) ≤ 6", "(x − 1)(x − 2) ≤ log 6"],
				"hint": "相加變相乘，底數 0.5 < 1 要變號",
				"write": "log_{0.5} (x − 1)(x − 2) ≥ log_{0.5} 6　→　(x − 1)(x − 2) ≤ 6（底數 < 1，反向）"},
			{"t": "choice", "q": "展開、移項：", "opts": ["x^{2} − 3x − 4 ≤ 0", "x^{2} − 3x + 2 ≤ 0", "x^{2} − 3x − 8 ≤ 0", "x^{2} + 3x − 4 ≤ 0"],
				"hint": "(x − 1)(x − 2) = x^{2} − 3x + 2，再減 6", "write": "x^{2} − 3x − 4 ≤ 0　→　−1 ≤ x ≤ 4"},
			{"t": "line", "q": "封印不等式的解。", "row": "不等式",
				"marks": ["−1", "2", "4"], "seg": [0, 1, 1, 0], "pt": [1, 1, 1]},
			{"t": "line", "q": "兩列取交集。", "row": "交集",
				"marks": ["−1", "2", "4"], "seg": [0, 0, 1, 0], "pt": [0, 0, 1], "write": "答：2 < x ≤ 4"}]},

	{"id": "l_meaning", "kind": "line", "tier": 2, "title": "有意義的範圍", "tmul": 1.0,
		"stem": "若 log_{2} [log_{1/2} (x + 1)] 有意義，求 x 的範圍。",
		"steps": [
			{"t": "choice", "q": "外層的 log_{2} 要有意義，需要？",
				"opts": ["log_{1/2} (x + 1) > 0", "log_{1/2} (x + 1) > 1", "x + 1 > 0", "log_{1/2} (x + 1) ≥ 0"],
				"hint": "外層的真數必須大於 0", "write": "log_{1/2} (x + 1) > 0"},
			{"t": "choice", "q": "log_{1/2} (x + 1) > 0 代表？",
				"opts": ["0 < x + 1 < 1", "x + 1 > 1", "x + 1 > 0", "x + 1 < 0"],
				"hint": "底數 1/2 < 1：真數在 0 和 1 之間，值才是正的", "write": "0 < x + 1 < 1"},
			{"t": "line", "q": "封印 x 的範圍。", "row": "解",
				"marks": ["−1", "0"], "seg": [0, 1, 0], "pt": [0, 0], "write": "答：−1 < x < 0"}]},

	{"id": "l_quad3", "kind": "line", "tier": 3, "title": "換元不等式", "tmul": 1.15,
		"stem": "解不等式 9^{x} − 10 · 3^{x} + 9 < 0。",
		"steps": [
			{"t": "choice", "q": "令 t = 3^{x}，不等式變成？", "pre": "令 t = 3^{x}（t > 0）",
				"opts": ["t^{2} − 10t + 9 < 0", "t^{2} − 10t − 9 < 0", "t^{2} + 10t + 9 < 0", "t − 10t + 9 < 0"],
				"hint": "9^{x} = (3^{x})^{2} = t^{2}", "write": "t^{2} − 10t + 9 < 0　→　1 < t < 9"},
			{"t": "choice", "q": "1 < 3^{x} < 9，所以？", "opts": ["0 < x < 2", "1 < x < 9", "0 < x < 3", "1 < x < 2"],
				"hint": "1 = 3^{0}，9 = 3^{2}", "write": "3^{0} < 3^{x} < 3^{2}"},
			{"t": "line", "q": "封印 x 的範圍。", "row": "解", "marks": ["0", "2"], "seg": [0, 1, 0], "pt": [0, 0],
				"write": "答：0 < x < 2"}]},

	{"id": "l_basecond", "kind": "line", "tier": 3, "title": "底數與真數", "tmul": 1.25,
		"stem": "若 log_{x} (−x^{2} + 5x + 6) 有意義，x 可以是哪些整數？",
		"steps": [
			{"t": "line", "q": "底數條件：x > 0 且 x ≠ 1。", "row": "底數",
				"marks": ["−1", "0", "1", "6"], "seg": [0, 0, 1, 1, 1], "pt": [0, 0, 0, 1]},
			{"t": "choice", "q": "真數條件：−x^{2} + 5x + 6 > 0，兩邊乘 −1：",
				"opts": ["x^{2} − 5x − 6 < 0", "x^{2} − 5x − 6 > 0", "x^{2} + 5x + 6 < 0", "x^{2} − 5x + 6 < 0"],
				"hint": "乘上負數，不等號要反向", "write": "x^{2} − 5x − 6 < 0　→　−1 < x < 6"},
			{"t": "line", "q": "封印真數條件 −1 < x < 6。", "row": "真數",
				"marks": ["−1", "0", "1", "6"], "seg": [0, 1, 1, 1, 0], "pt": [0, 1, 1, 0]},
			{"t": "line", "q": "兩個條件同時成立。", "row": "同時",
				"marks": ["−1", "0", "1", "6"], "seg": [0, 0, 1, 1, 0], "pt": [0, 0, 0, 0], "write": "0 < x < 6 且 x ≠ 1"},
			{"t": "choice", "q": "範圍內有幾個整數？", "opts": ["4 個", "5 個", "6 個", "3 個"],
				"hint": "整數 1 不行（底數不能是 1）", "write": "答：x = 2、3、4、5，共 4 個"}]},
]


# ================= 極值換元 =================

const EXTREME := [
	{"id": "e_basic", "kind": "extreme", "tier": 1, "title": "指數二次式", "tmul": 1.0,
		"stem": "求 f(x) = 4^{x} − 2^{x + 2} + 7 的最小值。",
		"plot": {"x": [-1.0, 5.0], "y": [-1.0, 9.0], "var": "t",
			"curves": [{"f": "x*x-4*x+7", "c": "orange", "dom": [0.0, 99.0], "at": 3}],
			"pts": [{"x": 2, "y": 3, "label": "(2, 3)", "at": 5}], "band": {"lo": 0.0, "at": 2}},
		"steps": [
			{"t": "choice", "q": "令 t 等於什麼最好算？", "opts": ["t = 2^{x}", "t = 4^{x}", "t = x^{2}", "t = 2x"],
				"hint": "4^{x} 和 2^{x + 2} 都能用 2^{x} 表示", "write": "令 t = 2^{x}"},
			{"t": "choice", "q": "t 的範圍是？", "opts": ["t > 0", "t ≥ 1", "t ≥ 2", "全體實數"],
				"hint": "2^{x} 可以是任何正數", "write": "t > 0"},
			{"t": "choice", "q": "f 用 t 表示：", "opts": ["t^{2} − 4t + 7", "t^{2} − 2t + 7", "t^{2} − t^{2} + 7", "2t − 4t + 7"],
				"hint": "2^{x + 2} = 4 · 2^{x} = 4t", "write": "f(x) = t^{2} − 4t + 7"},
			{"t": "choice", "q": "配方：f(x) = ？", "opts": ["(t − 2)^{2} + 3", "(t − 2)^{2} + 7", "(t − 4)^{2} + 7", "(t + 2)^{2} + 3"],
				"hint": "t^{2} − 4t = (t − 2)^{2} − 4", "write": "f(x) = (t − 2)^{2} + 3，頂點 t = 2"},
			{"t": "choice", "q": "頂點 t = 2 在 t > 0 裡面。最小值是？", "opts": ["3", "7", "2", "−4"],
				"hint": "頂點的值就是配方後的常數項", "write": "t = 2 時，最小值 3"},
			{"t": "choice", "q": "此時 x = ？", "opts": ["1", "2", "4", "0"],
				"hint": "t = 2^{x} = 2", "write": "答：2^{x} = 2 ⇒ x = 1 時，最小值 3"}]},

	{"id": "e_inside", "kind": "extreme", "tier": 2, "title": "頂點在範圍內", "tmul": 1.1,
		"stem": "求 f(x) = (4^{x} + 4^{−x}) − 6(2^{x} + 2^{−x}) + 12 的最小值。",
		"plot": {"x": [-1.0, 6.0], "y": [-1.0, 8.0], "var": "t",
			"curves": [{"f": "x*x-6*x+10", "c": "orange", "dom": [2.0, 99.0], "at": 4}],
			"pts": [{"x": 3, "y": 1, "label": "(3, 1)", "at": 5}], "band": {"lo": 2.0, "at": 2}},
		"steps": [
			{"t": "choice", "q": "令 t 等於什麼？", "opts": ["t = 2^{x} + 2^{−x}", "t = 2^{x}", "t = 4^{x}", "t = 2^{x} − 2^{−x}"],
				"hint": "式子裡一整組 2^{x} + 2^{−x} 一起出現", "write": "令 t = 2^{x} + 2^{−x}"},
			{"t": "choice", "q": "t 的範圍是？（關鍵！）", "opts": ["t ≥ 2", "t > 0", "t ≥ 0", "全體實數"],
				"hint": "算幾不等式：2^{x} + 2^{−x} ≥ 2√{2^{x} · 2^{−x}} = 2", "write": "t ≥ 2"},
			{"t": "choice", "q": "4^{x} + 4^{−x} 用 t 表示：", "opts": ["t^{2} − 2", "t^{2}", "t^{2} + 2", "2t"],
				"hint": "t^{2} = 4^{x} + 2 + 4^{−x}", "write": "4^{x} + 4^{−x} = t^{2} − 2"},
			{"t": "choice", "q": "代入並配方：f(x) = ？", "opts": ["(t − 3)^{2} + 1", "(t − 3)^{2} + 3", "(t − 6)^{2} − 24", "(t + 3)^{2} + 1"],
				"hint": "(t^{2} − 2) − 6t + 12 = t^{2} − 6t + 10", "write": "f(x) = (t^{2} − 2) − 6t + 12 = t^{2} − 6t + 10 = (t − 3)^{2} + 1"},
			{"t": "choice", "q": "頂點 t = 3 在 t ≥ 2 裡面嗎？最小值是？", "opts": ["1", "2", "10", "−8"],
				"hint": "3 ≥ 2，頂點在範圍內", "write": "答：頂點 t = 3 在範圍內 ⇒ 最小值 1"}]},

	{"id": "e_edge", "kind": "extreme", "tier": 2, "title": "頂點不在範圍內", "tmul": 1.1,
		"stem": "求 f(x) = (4^{x} + 4^{−x}) + 4(2^{x} + 2^{−x}) + 3 的最小值。",
		"plot": {"x": [-4.5, 4.0], "y": [-4.0, 16.0], "var": "t",
			"curves": [{"f": "x*x+4*x+1", "c": "orange", "at": 3}],
			"pts": [{"x": -2, "y": -3, "label": "頂點", "at": 3}, {"x": 2, "y": 13, "label": "(2, 13)", "at": 4}],
			"band": {"lo": 2.0, "at": 1}},
		"steps": [
			{"t": "choice", "q": "令 t = 2^{x} + 2^{−x}，t 的範圍是？", "opts": ["t ≥ 2", "t > 0", "t ≥ −2", "全體實數"],
				"hint": "算幾不等式", "write": "t = 2^{x} + 2^{−x} ≥ 2"},
			{"t": "choice", "q": "f 用 t 表示：", "opts": ["t^{2} + 4t + 1", "t^{2} + 4t + 3", "t^{2} + 4t + 5", "t^{2} + 4t − 1"],
				"hint": "4^{x} + 4^{−x} = t^{2} − 2", "write": "f(x) = (t^{2} − 2) + 4t + 3 = t^{2} + 4t + 1"},
			{"t": "choice", "q": "配方：f(x) = ？", "opts": ["(t + 2)^{2} − 3", "(t + 2)^{2} + 1", "(t − 2)^{2} − 3", "(t + 4)^{2} − 15"],
				"hint": "t^{2} + 4t = (t + 2)^{2} − 4", "write": "f(x) = (t + 2)^{2} − 3，頂點 t = −2"},
			{"t": "choice", "q": "頂點 t = −2 在 t ≥ 2 裡面嗎？最小值是？", "opts": ["13", "−3", "1", "9"],
				"hint": "頂點不在範圍內：t ≥ 2 時遞增，最小值在 t = 2",
				"write": "頂點不在 t ≥ 2 裡 ⇒ 最小值在 t = 2：4 + 8 + 1 = 13"},
			{"t": "choice", "q": "t = 2^{x} + 2^{−x} = 2 時，x = ？", "opts": ["0", "1", "2", "−1"],
				"hint": "算幾的等號成立：2^{x} = 2^{−x}", "write": "答：x = 0 時，最小值 13"}]},

	{"id": "e_closed", "kind": "extreme", "tier": 3, "title": "閉區間的最值", "tmul": 1.2,
		"stem": "當 −2 ≤ x ≤ 1 時，f(x) = (1/4)^{x} − 4 · (1/2)^{x} + 5 的最大值 M、最小值 m，求 (M, m)。",
		"plot": {"x": [-0.5, 5.0], "y": [-0.8, 7.0], "var": "t",
			"curves": [{"f": "x*x-4*x+5", "c": "orange", "dom": [0.5, 4.0], "at": 3}],
			"pts": [{"x": 2, "y": 1, "label": "m", "at": 4}, {"x": 4, "y": 5, "label": "M", "at": 6}, {"x": 0.5, "y": 3.25, "label": "", "at": 6}],
			"band": {"lo": 0.5, "hi": 4.0, "at": 1}},
		"steps": [
			{"t": "choice", "q": "令 t = (1/2)^{x}，t 的範圍是？",
				"opts": ["1/2 ≤ t ≤ 4", "−2 ≤ t ≤ 1", "1/4 ≤ t ≤ 2", "t > 0"],
				"hint": "(1/2)^{x} 是遞減：x = −2 時 t = 4，x = 1 時 t = 1/2", "write": "t = (1/2)^{x}，1/2 ≤ t ≤ 4"},
			{"t": "choice", "q": "f 用 t 表示：", "opts": ["t^{2} − 4t + 5", "t^{2} − 2t + 5", "2t − 4t + 5", "t^{4} − 4t + 5"],
				"hint": "(1/4)^{x} = [(1/2)^{x}]^{2}", "write": "f(x) = t^{2} − 4t + 5"},
			{"t": "choice", "q": "配方：f(x) = ？", "opts": ["(t − 2)^{2} + 1", "(t − 2)^{2} + 5", "(t − 4)^{2} + 5", "(t + 2)^{2} + 1"],
				"hint": "t^{2} − 4t = (t − 2)^{2} − 4", "write": "f(x) = (t − 2)^{2} + 1，頂點 t = 2"},
			{"t": "choice", "q": "頂點 t = 2 在 1/2 ≤ t ≤ 4 裡面。最小值 m = ？", "opts": ["1", "13/4", "5", "0"],
				"hint": "頂點在範圍內，最小值就是配方後的常數項", "write": "頂點 t = 2 在範圍內 ⇒ 最小值 m = 1"},
			{"t": "choice", "q": "最小值發生時，t 與 x 各是多少？", "opts": ["t = 2，x = −1", "t = 2，x = 1", "t = 1，x = 0", "t = 4，x = −2"],
				"hint": "(1/2)^{x} = 2 = (1/2)^{−1}", "write": "t = 2 ⇒ (1/2)^{x} = 2 ⇒ x = −1"},
			{"t": "choice", "q": "最大值 M = ？", "opts": ["5", "13/4", "1", "7"],
				"hint": "最大值在離頂點 t = 2 較遠的端點：|4 − 2| > |1/2 − 2|",
				"write": "端點 t = 4 離頂點較遠 ⇒ M = (4 − 2)^{2} + 1 = 5"},
			{"t": "choice", "q": "最大值發生時，t 與 x 各是多少？", "opts": ["t = 4，x = −2", "t = 4，x = 2", "t = 1/2，x = 1", "t = 1/2，x = −1"],
				"hint": "(1/2)^{x} = 4 = (1/2)^{−2}", "write": "答：x = −2 時 M = 5，x = −1 時 m = 1"}]},

	{"id": "e_xpow", "kind": "extreme", "tier": 3, "title": "取對數找最值", "tmul": 1.2,
		"stem": "當 1/4 ≤ x ≤ 4 時，f(x) = x^{2 + log_{2} x} 的最大值 M、最小值 m，求 (M, m)。",
		"plot": {"x": [-3.0, 3.0], "y": [-2.0, 9.0], "var": "u",
			"curves": [{"f": "x*x+2*x", "c": "orange", "dom": [-2.0, 2.0], "at": 3}],
			"pts": [{"x": -1, "y": -1, "label": "−1", "at": 4}, {"x": 2, "y": 8, "label": "8", "at": 6}],
			"band": {"lo": -2.0, "hi": 2.0, "at": 2}},
		"steps": [
			{"t": "choice", "q": "兩邊取 log_{2}，令 u = log_{2} x：log_{2} f = ？",
				"opts": ["u^{2} + 2u", "2 + u^{2}", "2u", "(2 + u)^{2}"],
				"hint": "log_{2} x^{k} = k · log_{2} x，這裡 k = 2 + u", "write": "令 u = log_{2} x，兩邊取 log_{2}：log_{2} f = (2 + u) log_{2} x = (2 + u)u = u^{2} + 2u"},
			{"t": "choice", "q": "u 的範圍？", "opts": ["−2 ≤ u ≤ 2", "1/4 ≤ u ≤ 4", "0 ≤ u ≤ 2", "−4 ≤ u ≤ 4"],
				"hint": "log_{2} (1/4) = −2，log_{2} 4 = 2", "write": "1/4 ≤ x ≤ 4 ⇒ −2 ≤ u = log_{2} x ≤ 2"},
			{"t": "choice", "q": "配方：log_{2} f = u^{2} + 2u = ？", "opts": ["(u + 1)^{2} − 1", "(u + 1)^{2} + 1", "(u − 1)^{2} − 1", "(u + 2)^{2} − 4"],
				"hint": "u^{2} + 2u = (u + 1)^{2} − 1", "write": "log_{2} f = (u + 1)^{2} − 1，頂點 u = −1"},
			{"t": "choice", "q": "頂點 u = −1 在 −2 ≤ u ≤ 2 裡面。f 的最小值 m = ？", "opts": ["1/2", "−1", "1", "1/4"],
				"hint": "頂點時 log_{2} f = −1，還要換回 f：f = 2^{log_{2} f}",
				"write": "u = −1 時 log_{2} f 最小 = −1 ⇒ m = 2^{−1} = 1/2"},
			{"t": "choice", "q": "最小值發生時，u 與 x 各是多少？", "opts": ["u = −1，x = 1/2", "u = −1，x = −1/2", "u = 1，x = 2", "u = −2，x = 1/4"],
				"hint": "u = log_{2} x = −1 ⇒ x = 2^{−1}", "write": "u = −1 ⇒ x = 2^{−1} = 1/2"},
			{"t": "choice", "q": "f 的最大值 M = ？", "opts": ["256", "8", "16", "4"],
				"hint": "最大在離頂點 u = −1 最遠的端點 u = 2：log_{2} f = 8，再換回 f",
				"write": "端點 u = 2 離頂點較遠 ⇒ log_{2} f = 8 ⇒ M = 2^{8} = 256"},
			{"t": "choice", "q": "最大值發生時，u 與 x 各是多少？", "opts": ["u = 2，x = 4", "u = 2，x = 1/4", "u = −2，x = 1/4", "u = 8，x = 256"],
				"hint": "u = log_{2} x = 2 ⇒ x = 2^{2}", "write": "答：x = 4 時 M = 256，x = 1/2 時 m = 1/2"}]},
]


# ================= 現實委託 =================

const QUEST := [
	{"id": "q_bact", "kind": "quest", "tier": 1, "title": "細菌繁殖", "tmul": 1.0,
		"stem": "實驗室的細菌每小時數量變成 2 倍。至少要經過幾小時，細菌數會超過原來的 1000 倍？\n（log 2 ≈ 0.3010）",
		"steps": [
			{"t": "choice", "q": "經過 n 小時後，要滿足？", "opts": ["2^{n} > 1000", "2n > 1000", "n^{2} > 1000", "1000^{n} > 2"],
				"hint": "每小時乘 2，n 小時乘了 n 次", "write": "2^{n} > 1000"},
			{"t": "choice", "q": "兩邊取 log：", "opts": ["n > 3 / 0.3010", "n > 3 × 0.3010", "n > 0.3010 / 3", "n > 1000 / 0.3010"],
				"hint": "n log 2 > log 1000 = 3", "write": "n log 2 > log 1000 = 3　→　n > 3 / 0.3010 ≈ 9.97"},
			{"t": "choice", "q": "至少幾小時？", "opts": ["10", "9", "11", "30"],
				"hint": "n 要超過 9.97 的整數", "write": "答：10 小時"}]},

	{"id": "q_interest", "kind": "quest", "tier": 2, "title": "複利翻倍", "tmul": 1.1,
		"stem": "一筆存款年利率 5%，每年複利一次。至少要存幾年，本利和才會超過本金的 2 倍？\n（log 2 ≈ 0.3010，log 1.05 ≈ 0.0212）",
		"steps": [
			{"t": "choice", "q": "存 n 年後，要滿足？", "opts": ["1.05^{n} > 2", "1 + 0.05n > 2", "1.05n > 2", "2^{n} > 1.05"],
				"hint": "複利：每年乘 1.05", "write": "1.05^{n} > 2"},
			{"t": "choice", "q": "取 log 之後：", "opts": ["n · log 1.05 > log 2", "log n · 1.05 > log 2", "n + log 1.05 > log 2", "n > log 2 · log 1.05"],
				"hint": "log a^{n} = n log a", "write": "n log 1.05 > log 2　→　0.0212n > 0.3010"},
			{"t": "choice", "q": "至少幾年？（0.0212 × 14 ≈ 0.297）", "opts": ["15", "14", "16", "20"],
				"hint": "14 年還不夠 0.3010，要再多一年", "write": "0.0212 × 14 ≈ 0.297 < 0.3010，0.0212 × 15 ≈ 0.318 > 0.3010　→　答：15 年"}]},

	{"id": "q_ph", "kind": "quest", "tier": 2, "title": "酸鹼度", "tmul": 1.0,
		"stem": "pH = −log [H^{+}]。洗面乳 A 的 pH 是 5.3，洗面乳 B 的 pH 是 6.2。A 的氫離子濃度大約是 B 的幾倍？\n（log 2 ≈ 0.3010）",
		"steps": [
			{"t": "choice", "q": "氫離子濃度用 pH 表示：", "opts": ["[H^{+}] = 10^{−pH}", "[H^{+}] = −10^{pH}", "[H^{+}] = 10^{pH}", "[H^{+}] = log pH"],
				"hint": "−log [H^{+}] = pH，所以 log [H^{+}] = −pH", "write": "[H^{+}] = 10^{−pH}"},
			{"t": "choice", "q": "A ÷ B = ？", "opts": ["10^{0.9}", "10^{−0.9}", "5.3/6.2", "10^{11.5}"],
				"hint": "10^{−5.3} ÷ 10^{−6.2} = 10^{−5.3 + 6.2}", "write": "10^{−5.3} ÷ 10^{−6.2} = 10^{0.9}"},
			{"t": "choice", "q": "10^{0.9} 大約是？", "opts": ["8 倍", "9 倍", "2 倍", "0.9 倍"],
				"hint": "log 8 = 3 log 2 ≈ 0.903", "write": "答：約 8 倍"}]},

	{"id": "q_db", "kind": "quest", "tier": 2, "title": "噪音管制", "tmul": 1.0,
		"stem": "分貝 dB = 120 + 10 log ω（ω 是聲音能量）。一支哨子會發出 50 分貝，場內規定不能超過 70 分貝。最多能同時吹幾支？",
		"steps": [
			{"t": "choice", "q": "n 支哨子同時吹，能量變成 nω，分貝變成？",
				"opts": ["50 + 10 log n", "50n", "50 + log n", "500 log n"],
				"hint": "120 + 10 log (nω) = (120 + 10 log ω) + 10 log n", "write": "120 + 10 log (nω) = 50 + 10 log n ≤ 70"},
			{"t": "choice", "q": "最多幾支？", "opts": ["100", "20", "10", "1000"],
				"hint": "log n ≤ 2", "write": "10 log n ≤ 20　→　log n ≤ 2　→　n ≤ 100　→　答：最多 100 支"}]},

	{"id": "q_quake", "kind": "quest", "tier": 3, "title": "地震能量", "tmul": 1.0,
		"stem": "芮氏規模 r 的地震釋放能量 E 滿足 log E = 11.8 + 1.5r。規模 7.2 的地震，能量大約是規模 6.2 的幾倍？\n（√{10} ≈ 3.16）",
		"steps": [
			{"t": "choice", "q": "規模差 1，log E 差多少？", "opts": ["1.5", "1", "11.8", "15"],
				"hint": "1.5 × 7.2 − 1.5 × 6.2", "write": "log E_{1} − log E_{2} = 1.5 × (7.2 − 6.2) = 1.5　→　E_{1}/E_{2} = 10^{1.5}"},
			{"t": "choice", "q": "大約是幾倍？", "opts": ["約 32 倍", "約 15 倍", "約 1.5 倍", "約 100 倍"],
				"hint": "10^{1.5} = 10√{10}", "write": "答：10^{1.5} = 10√{10} ≈ 31.6，約 32 倍"}]},
]


# ================= 試煉大題（每 5 層） =================

const BOSS := [
	{"id": "b_drug", "kind": "boss", "tier": 2, "title": "藥物代謝", "tmul": 1.6,
		"stem": "某藥物在血液中的濃度每 6 小時減半：服藥 t 小時後，濃度是 C(t) = C_{0} · (1/2)^{t/6}。\n(1) 12 小時後剩原本的幾分之幾？\n(2) 降到原本的 1/10，約需幾小時？\n(3) 降到原本的 1/1000，約需幾小時？（log 2 ≈ 0.3010）",
		"steps": [
			{"t": "choice", "part": "(1)", "q": "t = 12 代入：(1/2)^{12/6} = ？", "opts": ["1/4", "1/2", "1/8", "1/12"],
				"hint": "12 ÷ 6 = 2，(1/2)^{2} = 1/4", "write": "(1)　C(12) = C_{0} · (1/2)^{2} = C_{0}/4，剩 1/4"},
			{"t": "choice", "part": "(2)", "q": "(1/2)^{t/6} = 1/10。兩邊取 log，得到？",
				"opts": ["t/6 · log 2 = 1", "t/6 · log 2 = 10", "t/6 = log 2", "t/6 · log 2 = −1"],
				"hint": "log (1/2) = −log 2、log (1/10) = −1，兩邊的負號可以消掉",
				"write": "(2)　t/6 · log (1/2) = log (1/10)　⇒　t/6 · log 2 = 1"},
			{"t": "choice", "part": "(2)", "q": "t = 6 ÷ log 2 ≈ 6 ÷ 0.3010 ≈ ？",
				"opts": ["約 19.9 小時", "約 1.8 小時", "約 18 小時", "約 60 小時"],
				"hint": "1 ÷ 0.3010 ≈ 3.32，再乘 6",
				"write": "　 　t = 6 ÷ log 2 ≈ 19.9（小時）"},
			{"t": "choice", "part": "(3)", "q": "1/1000 = (1/10)^{3}。每降到 1/10 都要花一樣久，所以需要？",
				"opts": ["約 60 小時", "約 20 小時", "約 30 小時", "約 1000 小時"],
				"hint": "降到 1/10 要 19.9 小時，連續降 3 次",
				"write": "(3)　(1/10)^{3}：時間是 3 倍，3 × 19.9 ≈ 60（小時）"}]},

	{"id": "b_slope", "kind": "boss", "tier": 2, "title": "曲線上的兩點", "tmul": 1.6,
		"stem": "A(a, r)、B(b, s) 是 y = log_{2} x 圖形上的兩點，a < b。AB 的斜率是 2，AB 長 √{5}。求 2a + b。",
		"plot": {"x": [-0.4, 3.0], "y": [-2.5, 2.0], "curves": [{"f": "log(x)/log(2)", "c": "cyan", "dom": [0.02, 99.0]}],
			"pts": [{"x": 0.3333, "y": -1.585, "label": "A", "at": 3}, {"x": 1.3333, "y": 0.415, "label": "B", "at": 3}]},
		"steps": [
			{"t": "choice", "part": "(1)", "q": "斜率 2、長度 √{5}，所以 (b − a, s − r) = ？",
				"opts": ["(1, 2)", "(2, 1)", "(√{5}, 2√{5})", "(1, √{5})"],
				"hint": "s − r = 2(b − a)，畢氏定理：(b − a)^{2} + 4(b − a)^{2} = 5",
				"write": "(1)　s − r = 2(b − a)，(b − a)^{2} + (s − r)^{2} = 5　→　5(b − a)^{2} = 5　→　b − a = 1，s − r = 2"},
			{"t": "choice", "part": "(2)", "q": "s − r = log_{2} b − log_{2} a = 2，代表？",
				"opts": ["b = 4a", "b = a + 4", "b = 2a", "b = a^{2}"],
				"hint": "log_{2} (b/a) = 2", "write": "(2)　log_{2} (b/a) = 2　→　b/a = 4　→　b = 4a"},
			{"t": "choice", "part": "(3)", "q": "2a + b = ？", "opts": ["2", "5/3", "3", "4/3"],
				"hint": "b − a = 3a = 1", "write": "(3)　4a − a = 1　→　a = 1/3，b = 4/3　→　2a + b = 2"}]},

	{"id": "b_mirror", "kind": "boss", "tier": 3, "title": "鏡像雙根", "tmul": 1.6,
		"stem": "α 是 2^{x} = 6 − x 的實根，β 是 log_{2} x = 6 − x 的實根。求 α + β 和 2^{α} + log_{2} β。",
		"plot": {"x": [-0.5, 6.5], "y": [-0.5, 6.5],
			"curves": [{"f": "pow(2,x)", "c": "cyan"}, {"f": "log(x)/log(2)", "c": "pink", "dom": [0.02, 99.0]}, {"f": "6-x", "c": "dim", "at": 1}, {"f": "x", "c": "faint"}],
			"pts": [{"x": 2.0, "y": 4.0, "label": "", "at": 2}, {"x": 4.0, "y": 2.0, "label": "", "at": 2}, {"x": 3, "y": 3, "label": "(3, 3)", "at": 2}]},
		"steps": [
			{"t": "choice", "part": "(1)", "q": "y = 2^{x} 與 y = log_{2} x 的圖形對稱於？", "opts": ["直線 y = x", "y 軸", "x 軸", "原點"],
				"hint": "互為反函數", "write": "(1)　兩曲線對稱於 y = x"},
			{"t": "choice", "part": "(2)", "q": "直線 y = 6 − x 也對稱於 y = x，兩個交點互相鏡射。α + β = ？",
				"opts": ["6", "3", "12", "無法確定"],
				"hint": "兩交點的中點在 y = x 和 y = 6 − x 的交點 (3, 3)", "write": "(2)　兩交點的中點是 y = x 與 y = 6 − x 的交點 (3, 3)　→　α + β = 2 × 3 = 6"},
			{"t": "choice", "part": "(3)", "q": "2^{α} + log_{2} β = ？", "opts": ["6", "12", "3", "8"],
				"hint": "2^{α} = 6 − α，log_{2} β = 6 − β", "write": "(3)　2^{α} = 6 − α，log_{2} β = 6 − β　→　和 = 12 − (α + β) = 6"}]},

	{"id": "b_read", "kind": "boss", "tier": 2, "title": "讀圖解謎", "tmul": 1.6,
		"stem": "f(x) = log (ax + b) 的圖形往左越來越靠近 y 軸；g(x) = log (cx + d) 的圖形往左越來越靠近直線 x = 1。兩個圖形都通過 (2, 0)。",
		"plot": {"x": [-0.5, 5.0], "y": [-2.0, 1.2],
			"curves": [{"f": "log(0.5*x)/log(10)", "c": "cyan", "dom": [0.02, 99.0]}, {"f": "log(x-1)/log(10)", "c": "pink", "dom": [1.005, 99.0]}],
			"vlines": [{"x": 1.0}], "pts": [{"x": 2, "y": 0, "label": "(2, 0)", "off": [6, 20]}]},
		"steps": [
			{"t": "choice", "part": "(1)", "q": "f 的漸近線是 y 軸（x = 0），所以 b = ？", "opts": ["0", "1", "−1", "2"],
				"hint": "漸近線在真數 ax + b = 0 的地方，x = 0 代入得 b = 0", "write": "(1)　漸近線在真數 ax + b = 0 的地方：x = 0 代入 ⇒ b = 0"},
			{"t": "choice", "part": "(2)", "q": "f 通過 (2, 0)，所以 a = ？", "opts": ["1/2", "2", "1", "−1/2"],
				"hint": "log (2a) = 0，2a = 1", "write": "(2)　log (2a) = 0　→　2a = 1　→　a = 1/2"},
			{"t": "choice", "part": "(3)", "q": "g 的漸近線 x = 1、又通過 (2, 0)，(c, d) = ？",
				"opts": ["(1, −1)", "(−1, 1)", "(1/2, −1/2)", "(2, −2)"],
				"hint": "c + d = 0，且 log (2c + d) = 0 → 2c + d = 1", "write": "(3)　漸近線 x = 1：c + d = 0；過 (2, 0)：2c + d = 1　→　(c, d) = (1, −1)"}]},

	{"id": "b_digits", "kind": "boss", "tier": 3, "title": "等比數列的位數", "tmul": 1.6,
		"stem": "a = 1 + 2 + 2^{2} + … + 2^{39}（共 40 項）。已知 log 2 ≈ 0.3010。",
		"steps": [
			{"t": "choice", "part": "(1)", "q": "a 化簡成？", "opts": ["2^{40} − 1", "2^{40}", "2^{39} − 1", "2^{41} − 1"],
				"hint": "等比級數：1 × (2^{40} − 1)/(2 − 1)", "write": "(1)　等比級數：a = (2^{40} − 1)/(2 − 1) = 2^{40} − 1"},
			{"t": "choice", "part": "(2)", "q": "a 是幾位數？", "opts": ["13 位數", "12 位數", "40 位數", "14 位數"],
				"hint": "log 2^{40} = 12.04；2^{40} 不是 10 的次方，減 1 不會少一位", "write": "(2)　log 2^{40} = 40 × 0.3010 = 12.04　→　2^{40} 是 13 位數，減 1 不變　→　13 位數"},
			{"t": "choice", "part": "(3)", "q": "a 的個位數字？", "opts": ["5", "6", "1", "7"],
				"hint": "2 的次方個位數：2、4、8、6 循環，2^{40} 的個位是 6", "write": "(3)　2 的次方個位：2、4、8、6 循環，2^{40} 個位 6　→　a 個位 6 − 1 = 5"},
			{"t": "choice", "part": "(4)", "q": "a 的最高位數字？", "opts": ["1", "2", "4", "9"],
				"hint": "0.04 < log 2，所以 10^{0.04} 介於 1 和 2 之間", "write": "(4)　2^{40} = 10^{12.04}，10^{0.04} 在 1 和 2 之間　→　最高位數字 1"}]},

	{"id": "b_ineq", "kind": "boss", "tier": 3, "title": "換元不等式", "tmul": 1.7,
		"stem": "解不等式 3^{−x + 3} − 244 · 3^{−x/2} + 9 < 0。",
		"steps": [
			{"t": "choice", "part": "(1)", "q": "令 t = 3^{−x/2}，t 的範圍是？", "opts": ["t > 0", "t ≥ 1", "t ≥ 0", "全體實數"],
				"hint": "3 的任何次方都是正數", "write": "(1)　令 t = 3^{−x/2}，t > 0"},
			{"t": "choice", "part": "(1)", "q": "3^{−x + 3} 用 t 表示：", "opts": ["27t^{2}", "27t", "3t^{2}", "t^{2} + 27"],
				"hint": "3^{−x + 3} = 3^{3} · 3^{−x} = 27 · (3^{−x/2})^{2}", "write": "3^{−x + 3} = 3^{3} · (3^{−x/2})^{2} = 27t^{2}"},
			{"t": "choice", "part": "(1)", "q": "原不等式改寫成 t 的式子：", "opts": ["27t^{2} − 244t + 9 < 0", "27t − 244t + 9 < 0", "27t^{2} − 244t^{2} + 9 < 0", "t^{2} − 244t + 243 < 0"],
				"hint": "3^{−x/2} 直接換成 t", "write": "原式 ⇒ 27t^{2} − 244t + 9 < 0"},
			{"t": "choice", "part": "(2)", "q": "27t^{2} − 244t + 9 因式分解：", "opts": ["(27t − 1)(t − 9)", "(27t − 9)(t − 1)", "(9t − 1)(3t − 9)", "(27t + 1)(t + 9)"],
				"hint": "27 × 9 = 243，243 + 1 = 244：交叉相乘湊 −244t", "write": "(2)　(27t − 1)(t − 9) < 0"},
			{"t": "choice", "part": "(2)", "q": "t 的範圍？", "opts": ["1/27 < t < 9", "t < 1/27 或 t > 9", "1/9 < t < 27", "0 < t < 9"],
				"hint": "兩根 1/27、9；開口向上，小於 0 在兩根之間", "write": "1/27 < t < 9（也滿足 t > 0）"},
			{"t": "choice", "part": "(2)", "q": "換回 3^{−x/2}，兩端寫成 3 的次方：", "opts": ["3^{−3} < 3^{−x/2} < 3^{2}", "3^{3} < 3^{−x/2} < 3^{2}", "3^{−3} < 3^{−x/2} < 3^{−2}", "3^{−1/3} < 3^{−x/2} < 3^{2}"],
				"hint": "1/27 = 3^{−3}，9 = 3^{2}", "write": "3^{−3} < 3^{−x/2} < 3^{2}"},
			{"t": "choice", "part": "(2)", "q": "底數 3 > 1，比較指數：", "opts": ["−3 < −x/2 < 2", "−3 > −x/2 > 2", "3 < −x/2 < 2", "−3 < x/2 < 2"],
				"hint": "底數大於 1 是遞增，指數的大小順序和原本一樣", "write": "底數 3 > 1 ⇒ −3 < −x/2 < 2"},
			{"t": "choice", "part": "(3)", "q": "−3 < −x/2 < 2 化成 x 的範圍時，不等號？",
				"opts": ["兩邊都反向", "都不變", "只有左邊反向"], "hint": "乘上 −2 要變號", "write": "(3)　兩邊乘 −2（不等號反向）：6 > x > −4"},
			{"t": "line", "part": "(3)", "q": "封印 x 的範圍。", "row": "解", "marks": ["−4", "6"], "seg": [0, 1, 0], "pt": [0, 0],
				"write": "答：−4 < x < 6"}]},
]
