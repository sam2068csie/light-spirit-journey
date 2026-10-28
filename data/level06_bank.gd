extends RefCounted
## 第六大關「真數守門員」題庫（對應講義 重點三：對數方程式）
##
## 旅程都是 forge（一步一步解），沿用前面的 choice／fill／filter／rule，再加上：
##   gate   真數守門員：把解出來的每個 x 代回原式，真數 > 0、底數 > 0 且 ≠ 1 才「放行」，
##          不合的「擋下」。cands 是候選解，keep 是該放行的，conds 是要檢查的條件，checks 是代進去的結果。
## 另外有一個 speed 旅程（守門速算），題目由 gen_problems 產生。
##
## verify：測試用。f(x) 在每個 roots 上要等於 0；ok(x) 是「x 代回原式有沒有意義」，要和 gate 的 keep 一致。

const B4 := preload("level04_bank.gd")
const T_POS := "t = %s 一定大於 0。哪些 t 可以留下？"


static func lb(b: float, x: float) -> float:
	return log(x) / log(b)


static func lg(x: float) -> float:
	return log(x) / log(10.0)


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag := "logeq_same") -> Dictionary:
	return B4._c(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag := "logeq_calc", mode := "ordered") -> Dictionary:
	return B4._f(name, q, template, answers, line, nudge, tag, mode)


static func _r(q: String, correct: String, others: Array, line: String, why: String, nudge: String,
		tag := "logeq_same") -> Dictionary:
	return B4._r(q, correct, others, line, why, nudge, tag)


## 解 t 的兩個根（順序不限）
static func _roots(v: String, answers: Array, line: String, nudge: String) -> Dictionary:
	var st := _f("解 " + v, "解出 %s（順序不限）。" % v, "%s = [0] 或 %s = [1]" % [v, v], answers, line, nudge, "logeq_calc", "set")
	if v.length() == 1 and line.contains(")("):
		st["fac_line"] = line      # slots() 最後會在它前面自動補上「因式分解」這一步
		st["fac_var"] = v
	elif v.length() == 1 and line.begins_with(v + "("):
		st["fac_line"] = line
		st["fac_var"] = v
	return st


## 真數守門員
static func _gate(cands: Array, keep: Array, conds: String, checks: Array, line: String, nudge: String) -> Dictionary:
	return {"kind": "gate", "name": "守門", "q": "把每個解代回原式檢查。合格的「放行」，不合的「擋下」。",
		"cands": cands, "keep": keep, "var": "x", "conds": conds, "checks": checks,
		"keep_word": "✓ 放行", "drop_word": "✗ 擋下", "tip": "點一下可以切換「放行」或「擋下」。",
		"line": line, "nudge": nudge, "tag": "logeq_check"}


## t 的篩選（t = a^{x} > 0）
static func _tpos(tdef: String, cands: Array, keep: Array, line: String) -> Dictionary:
	return {"kind": "filter", "name": "檢查 t", "q": T_POS % tdef, "cands": cands, "keep": keep, "line": line,
		"nudge": tdef + " 永遠大於 0：負的 t 要丟掉。", "tag": "logeq_check"}


const DOMS := {
	"same#0": ["x > 1/2", ["x > −3", "−3 < x < 1/2", "x > 0"], "x + 3 > 0 ⇒ x > −3；2x − 1 > 0 ⇒ x > 1/2。兩個都要成立 ⇒ x > 1/2。"],
	"same#1": ["x > 1", ["x > −1", "−1 < x < 1", "x > 0"], "x − 1 > 0 ⇒ x > 1；x + 1 > 0 ⇒ x > −1。兩個都要成立 ⇒ x > 1。"],
	"same#2": ["x > 0", ["x > −3", "−3 < x < 0", "全體實數"], "x + 3 > 0 ⇒ x > −3；x > 0。兩個都要成立 ⇒ x > 0。"],
	"same#3": ["−5 < x < 0 或 x > 3", ["x > 3", "x > −5", "0 < x < 3"], "x^{2} − 3x = x(x − 3) > 0 ⇒ x < 0 或 x > 3；x + 5 > 0 ⇒ x > −5。取交集 ⇒ −5 < x < 0 或 x > 3。"],
	"base#0": ["x > 0", ["x > 1", "x ≠ 0", "全體實數"], "兩個真數都是 x ⇒ x > 0。"],
	"base#1": ["x > 1", ["x > −5", "−5 < x < 1", "x > 0"], "x − 1 > 0 ⇒ x > 1；x + 5 > 0 ⇒ x > −5。取交集 ⇒ x > 1。"],
	"base#2": ["x > 2", ["x > −2", "−2 < x < 2", "x > 0"], "2x + 4 > 0 ⇒ x > −2；x − 2 > 0 ⇒ x > 2。取交集 ⇒ x > 2。"],
	"sub#0": ["x > 0", ["x ≠ 0", "x > 1", "全體實數"], "log_{2} x 的真數 x > 0（x^{3} > 0 也一樣是 x > 0）。"],
	"recip#0": ["x > 0 且 x ≠ 1", ["x > 0", "x ≠ 1", "x > 1"], "log_{3} x 要 x > 0；log_{x} 3 的底數是 x，還要 x ≠ 1。"],
	"recip#1": ["x > 0 且 x ≠ 1", ["x > 0", "x ≠ 1", "x > 1"], "log_{2} x 要 x > 0；log_{x} 2 的底數是 x，還要 x ≠ 1。"],
	"recip#2": ["x > 0 且 x ≠ 1", ["x > 0", "x ≠ 1", "x > 1"], "log_{3} x 要 x > 0；log_{x} 9 的底數是 x，還要 x ≠ 1。"],
	"boss1#0": ["x > 0", ["x > −6", "−6 < x < 0", "全體實數"], "log_{3} x 要 x > 0；x + 6 > 0 ⇒ x > −6。取交集 ⇒ x > 0。"],
	"boss1#1": ["x > 0", ["x > 1", "x > −1", "全體實數"], "真數 2^{x} − 1 > 0 ⇒ 2^{x} > 1 = 2^{0} ⇒ x > 0。"],
	"boss1#2": ["x > 0", ["x ≠ 0", "x > 1", "全體實數"], "log x 要 x > 0（log x^{2} 只要 x ≠ 0，但 log x 更嚴格）。"],
	"power#0": ["x > 0", ["x > 0 且 x ≠ 1", "x ≠ 0", "全體實數"], "次方裡有 log_{2} x ⇒ x > 0。"],
	"power#1": ["x > 0", ["x > 0 且 x ≠ 1", "x ≠ 0", "全體實數"], "次方裡有 log x ⇒ x > 0。"],
	"power#2": ["x > 0", ["x > 0 且 x ≠ 1", "x ≠ 0", "全體實數"], "次方裡有 log_{3} x ⇒ x > 0。"],
	"swap#0": ["x > 0", ["x > 1", "x ≠ 0", "全體實數"], "次方裡有 log_{2} x ⇒ x > 0。"],
	"swap#1": ["x > 0", ["x > 1", "x ≠ 0", "全體實數"], "x^{log_{2} 9}：底數 x 要 > 0 才有意義。"],
	"swap#2": ["x > 0", ["x > 1", "x ≠ 0", "全體實數"], "2^{log x} 裡有 log x ⇒ x > 0。"],
	"boss2#0": ["x > 2", ["x > −2", "−2 < x < 2", "x > 0"], "x + 2 > 0 ⇒ x > −2；x − 2 > 0 ⇒ x > 2。取交集 ⇒ x > 2。"],
	"boss2#2": ["x > 0 且 x ≠ 1", ["x > 0", "x ≠ 1", "x > 1"], "log_{2} x 要 x > 0；log_{x} 4 的底數是 x，還要 x ≠ 1。"],
}


## 每一題的第一步：先找出讓式子有意義的 x 範圍，最後守門就拿這個範圍來比對
static func _add_domain_steps(out: Array) -> void:
	for slot in out:
		var vs: Array = slot.get("variants", [])
		for vi in vs.size():
			var key := "%s#%d" % [slot.id, vi]
			if not DOMS.has(key):
				continue
			var d: Array = DOMS[key]
			var steps: Array = vs[vi].steps
			steps.insert(0, _c("有意義", "先找出讓每個 log 都有意義的 x 範圍（真數 > 0；底數 > 0 且 ≠ 1）：",
				[d[0]] + d[1], 0, d[2], "每個真數都要 > 0；log 的底數有 x 的話，還要 x > 0、x ≠ 1。最後取交集。",
				"有意義：" + d[0], "logeq_check"))
			for st in steps:
				if st.get("kind", "") == "gate":
					st["conds"] = d[0]
					st["q"] = "第一步算出 x 的範圍是 %s。把每個解和它比對：在範圍裡的「放行」，不在的「擋下」。" % d[0]


const PRE := {
	"base#0/合併": "log_{2} x + (1/2)log_{2} x = 3",
	"base#1/施放法則": "兩邊乘 2：2log_{3} (x − 1) = log_{3} (x + 5)",
	"base#1/整理": "(x − 1)^{2} = x + 5",
	"base#2/整理": "兩邊乘 2：log_{2} (2x + 4) = 2log_{2} (x − 2) ⇒ 2x + 4 = (x − 2)^{2}",
	"sub#2/換元": "令 t = 3^{x}：t^{2} − 2 = t",
	"recip#0/列式": "令 t = log_{3} x：t + 2/t = 3",
	"recip#1/列式": "令 t = log_{2} x：t − 3/t = 2",
	"recip#2/列式": "令 t = log_{3} x：2/t − t = 1",
	"boss2#2/列式": "令 t = log_{2} x：2/t + t = 3",
	"boss1#0/整理": "x^{2} = x + 6",
	"boss1#2/換元": "(log x)^{2} − 2log x − 3 = 0",
	"power#1/換元": "令 t = log x：t^{2} = 2 + t",
	"power#2/換元": "令 t = log_{3} x：t^{2} = 2 + t",
	"swap#2/合併": "2^{log x} + 2^{log x} = 16",
	"swap#1/換回 x": "3^{log_{2} x} = 1 或 3",
	"vieta#1/根與係數": "令 t = log_{2} x：t^{2} − 3t − 3 = 0",
}


static func slots() -> Array:
	var out := [
		# ======================= 第一章．守門基本功 =======================
		{"id": "same", "chapter": 1, "type": "forge", "title": "同底對決", "type_name": "同底比較",
		 "story": "log_{a} M = log_{a} N ⇒ M = N。解出的 x 都要檢查真數 > 0！",
		 "insight": "① 化成 log_{a} M = log_{a} N ② 解 x ③ 代回檢查真數、底數。",
		 "variants": [
			{"eq": "log_{2} (x + 3) = log_{2} (2x − 1)",
			 "steps": [
				_c("去掉 log", "兩邊都是 log_{2}，可以得到？", ["x + 3 = 2x − 1", "x + 3 = 2(2x − 1)", "(x + 3)^{2} = 2x − 1", "x + 3 = log_{2} (2x − 1)"], 0,
					"y = log_{2} x 一對一：log_{2} M = log_{2} N ⇒ M = N。", "同一個底的 log 相等，真數就相等。", "x + 3 = 2x − 1"),
				_f("解 x", "解出 x。", "x = [0]", ["4"], "x = 4", "移項：3 + 1 = 2x − x。"),
				_gate(["4"], [true], "x + 3 > 0、2x − 1 > 0", ["x + 3 = 7、2x − 1 = 7，都 > 0 ✓"], "x = 4 合格",
					"把 x = 4 代回兩個真數，看看是不是都大於 0。"),
			 ],
			 "verify": {"f": func(x): return lb(2, x + 3) - lb(2, 2 * x - 1), "ok": func(x): return x + 3 > 0 and 2 * x - 1 > 0,
				"roots": [4.0]}},
			{"eq": "log_{3} (x − 1) + log_{3} (x + 1) = 1",
			 "steps": [
				_r("兩個 log 相加，先施放哪條法則？", "add", ["sub", "pow", "base"], "log_{3} (x − 1)(x + 1) = 1",
					"同底相加 ⇒ 真數相乘。", "兩項是「相加」。"),
				_f("定義", "log_{3} N = 1 改寫成指數式。", "(x − 1)(x + 1) = [0]", ["3"], "x^{2} − 1 = 3", "N = 3^{1}。", "logeq_same"),
				_roots("x", ["2", "-2"], "x^{2} = 4 ⇒ x = ±2", "x^{2} = 4。"),
				_gate(["2", "-2"], [true, false], "x − 1 > 0、x + 1 > 0", ["x − 1 = 1、x + 1 = 3 ✓", "x − 1 = −3 < 0 ✗"],
					"x = −2 不合（真數 x − 1 < 0），所以 x = 2", "x = −2 代進 x − 1 是多少？"),
			 ],
			 "verify": {"f": func(x): return lb(3, x - 1) + lb(3, x + 1) - 1, "ok": func(x): return x - 1 > 0 and x + 1 > 0,
				"roots": [2.0]}},
			{"eq": "log (x + 3) + log x = 1",
			 "steps": [
				_r("兩個 log 相加，先施放哪條法則？", "add", ["sub", "pow", "recip"], "log x(x + 3) = 1",
					"同底相加 ⇒ 真數相乘。", "兩項是「相加」。"),
				_f("定義", "log N = 1 改寫成指數式。", "x(x + 3) = [0]", ["10"], "x^{2} + 3x − 10 = 0", "log 的底數是 10。", "logeq_same"),
				_roots("x", ["2", "-5"], "(x − 2)(x + 5) = 0", "兩數相乘 −10、相加 3。"),
				_gate(["2", "-5"], [true, false], "x + 3 > 0、x > 0", ["x + 3 = 5、x = 2 ✓", "x = −5 < 0 ✗"],
					"x = −5 不合，所以 x = 2", "x = −5 時，log x 有意義嗎？"),
			 ],
			 "verify": {"f": func(x): return lg(x + 3) + lg(x) - 1, "ok": func(x): return x + 3 > 0 and x > 0, "roots": [2.0]}},
			{"eq": "log_{2} (x^{2} − 3x) = log_{2} (x + 5)",
			 "steps": [
				_c("去掉 log", "兩邊都是 log_{2}，可以得到？", ["x^{2} − 3x = x + 5", "x^{2} − 3x = 2(x + 5)", "x − 3 = x + 5", "2x − 3 = 1"], 0,
					"同一個底的 log 相等，真數就相等。", "log_{2} M = log_{2} N ⇒ M = N。", "x^{2} − 3x = x + 5"),
				_f("整理", "移項整理。", "x^{2} − [0]x − [1] = 0", ["4", "5"], "x^{2} − 4x − 5 = 0", "−3x − x = −4x。"),
				_roots("x", ["5", "-1"], "(x − 5)(x + 1) = 0", "兩數相乘 −5、相加 −4。"),
				_gate(["5", "-1"], [true, true], "x^{2} − 3x > 0、x + 5 > 0",
					["x^{2} − 3x = 10、x + 5 = 10 ✓", "x^{2} − 3x = 4、x + 5 = 4 ✓"],
					"兩個都合格：x = 5 或 x = −1", "x 是負的沒關係，要看的是「真數」是不是正的！"),
			 ],
			 "verify": {"f": func(x): return lb(2, x * x - 3 * x) - lb(2, x + 5), "ok": func(x): return x * x - 3 * x > 0 and x + 5 > 0,
				"roots": [5.0, -1.0]}},
		 ]},

		{"id": "base", "chapter": 1, "type": "forge", "title": "換底守門", "type_name": "化同底",
		 "story": "底數不同：先用次方處理化成同底。",
		 "insight": "log_{a^{2}} M = (1/2)log_{a} M。平方會多出假解，要代回檢查。",
		 "variants": [
			{"eq": "log_{2} x + log_{4} x = 3",
			 "steps": [
				_f("次方", "log_{4} x = log_{2^{2}} x。", "log_{4} x = [0]log_{2} x", ["1/2"], "log_{4} x = (1/2)log_{2} x",
					"底數的次方 2 除下來。", "logeq_base"),
				_f("合併", "log_{2} x + (1/2)log_{2} x = 3。", "log_{2} x = [0]", ["2"], "(3/2)log_{2} x = 3 ⇒ log_{2} x = 2", "3 ÷ 3/2。",
					"logeq_base"),
				_f("定義", "改寫成指數式。", "x = [0]", ["4"], "x = 2^{2} = 4", "x = 2^{2}。", "logeq_same"),
				_gate(["4"], [true], "x > 0", ["x = 4 > 0 ✓"], "x = 4", "4 > 0。"),
			 ],
			 "verify": {"f": func(x): return lb(2, x) + lb(4, x) - 3, "ok": func(x): return x > 0, "roots": [4.0]}},
			{"eq": "log_{3} (x − 1) = log_{9} (x + 5)",
			 "steps": [
				_c("化同底", "log_{9} (x + 5) 化成以 3 為底：", ["(1/2)log_{3} (x + 5)", "2log_{3} (x + 5)", "log_{3} (x + 5)", "log_{3} (x + 5)^{2}"], 0,
					"log_{3^{2}} M = (1/2)log_{3} M。", "9 = 3^{2}，底數的次方要除下來。", "log_{3} (x − 1) = (1/2)log_{3} (x + 5)", "logeq_base"),
				_r("兩邊乘 2：2log_{3} (x − 1) = log_{3} (x + 5)。係數 2 怎麼處理？", "pow", ["add", "sub", "recip"],
					"log_{3} (x − 1)^{2} = log_{3} (x + 5)", "係數變成真數的次方。", "前面有係數 2。", "logeq_base"),
				_f("整理", "(x − 1)^{2} = x + 5，展開移項。", "x^{2} − [0]x − [1] = 0", ["3", "4"], "x^{2} − 3x − 4 = 0",
					"x^{2} − 2x + 1 = x + 5。"),
				_roots("x", ["4", "-1"], "(x − 4)(x + 1) = 0", "兩數相乘 −4、相加 −3。"),
				_gate(["4", "-1"], [true, false], "x − 1 > 0、x + 5 > 0", ["x − 1 = 3、x + 5 = 9 ✓", "x − 1 = −2 < 0 ✗"],
					"x = −1 不合，所以 x = 4", "原式的真數是 x − 1，不是 (x − 1)^{2}！"),
			 ],
			 "verify": {"f": func(x): return lb(3, x - 1) - lb(9, x + 5), "ok": func(x): return x - 1 > 0 and x + 5 > 0, "roots": [4.0]}},
			{"eq": "log_{4} (2x + 4) = log_{2} (x − 2)",
			 "steps": [
				_c("化同底", "log_{4} (2x + 4) 化成以 2 為底：", ["(1/2)log_{2} (2x + 4)", "2log_{2} (2x + 4)", "log_{2} (x + 2)", "log_{2} (2x + 4)^{2}"], 0,
					"log_{2^{2}} M = (1/2)log_{2} M。", "4 = 2^{2}。", "(1/2)log_{2} (2x + 4) = log_{2} (x − 2)", "logeq_base"),
				_f("整理", "兩邊乘 2：2x + 4 = (x − 2)^{2}，展開移項。", "x^{2} − [0]x = 0", ["6"], "x^{2} − 6x = 0", "x^{2} − 4x + 4 = 2x + 4。"),
				_roots("x", ["0", "6"], "x(x − 6) = 0", "提出 x。"),
				_gate(["0", "6"], [false, true], "2x + 4 > 0、x − 2 > 0", ["x − 2 = −2 < 0 ✗", "2x + 4 = 16、x − 2 = 4 ✓"],
					"x = 0 不合，所以 x = 6", "x = 0 代進 x − 2 是多少？"),
			 ],
			 "verify": {"f": func(x): return lb(4, 2 * x + 4) - lb(2, x - 2), "ok": func(x): return 2 * x + 4 > 0 and x - 2 > 0, "roots": [6.0]}},
		 ]},

		{"id": "sub", "chapter": 1, "type": "forge", "title": "換元守門", "type_name": "換元",
		 "story": "同一個 log 出現多次：令 t = log_{a} x，變成二次方程式。",
		 "insight": "t = log_{a} x 可為任何實數，解完換回 x = a^{t}。",
		 "variants": [
			{"eq": "(log_{2} x)^{2} − log_{2} x^{3} + 2 = 0",
			 "steps": [
				_r("log_{2} x^{3} 先怎麼處理？", "pow", ["add", "sub", "base"], "log_{2} x^{3} = 3log_{2} x", "真數的次方拿到前面。", "x 有 3 次方。",
					"logeq_sub"),
				_c("換元", "令 t 等於什麼，可以變成二次方程式？", ["t = log_{2} x", "t = x^{2}", "t = 2^{x}", "t = log_{x} 2"], 0,
					"(log_{2} x)^{2} = t^{2}、3log_{2} x = 3t。", "同一個 log 出現了兩次。", "令 t = log_{2} x：t^{2} − 3t + 2 = 0", "logeq_sub"),
				_roots("t", ["1", "2"], "(t − 1)(t − 2) = 0", "兩數相乘 2、相加 −3。"),
				_f("換回 x", "x = 2^{t}（順序不限）。", "x = [0] 或 x = [1]", ["2", "4"], "x = 2^{1} = 2 或 x = 2^{2} = 4", "2^{1}、2^{2}。",
					"logeq_sub", "set"),
				_gate(["2", "4"], [true, true], "x > 0", ["2 > 0 ✓", "4 > 0 ✓"], "x = 2 或 x = 4", "x = 2^{t} 一定大於 0。"),
			 ],
			 "verify": {"f": func(x): return pow(lb(2, x), 2) - 3 * lb(2, x) + 2, "ok": func(x): return x > 0, "roots": [2.0, 4.0]}},
			{"eq": "log_{2} (4^{x} + 3) = x + 2",
			 "steps": [
				_c("定義", "改寫成指數式：", ["4^{x} + 3 = 2^{x + 2}", "4^{x} + 3 = (x + 2)^{2}", "4^{x} + 3 = 2(x + 2)", "4^{x} + 3 = x + 4"], 0,
					"log_{2} N = k ⇔ N = 2^{k}。", "底數 2 當底，x + 2 是次方。", "4^{x} + 3 = 2^{x + 2} = 4·2^{x}", "logeq_sub"),
				_c("換元", "令 t = 2^{x}，方程式變成？", ["t^{2} − 4t + 3 = 0", "t^{2} + 3 = t + 2", "t^{2} − 4t − 3 = 0", "t^{2} + 4t + 3 = 0"], 0,
					"4^{x} = t^{2}、2^{x + 2} = 4t。", "4^{x} = (2^{x})^{2}。", "令 t = 2^{x}：t^{2} − 4t + 3 = 0", "logeq_sub"),
				_roots("t", ["1", "3"], "(t − 1)(t − 3) = 0", "兩數相乘 3、相加 −4。"),
				_tpos("2^{x}", ["1", "3"], [true, true], "兩個 t 都大於 0，都留下"),
				_c("換回 x", "2^{x} = 1 或 2^{x} = 3 ⇒ x = ？", ["0 或 log_{2} 3", "1 或 3", "0 或 3/2", "0 或 log_{3} 2"], 0,
					"2^{x} = 3 ⇔ x = log_{2} 3。", "2^{0} = 1。", "x = 0 或 x = log_{2} 3", "logeq_sub"),
			 ],
			 "verify": {"f": func(x): return lb(2, pow(4.0, x) + 3) - x - 2, "ok": func(x): return true, "roots": [0.0, lb(2, 3)]}},
			{"eq": "log_{3} (9^{x} − 2) = x",
			 "steps": [
				_c("定義", "改寫成指數式：", ["9^{x} − 2 = 3^{x}", "9^{x} − 2 = x^{3}", "9^{x} − 2 = 3x", "9^{x} = 3^{x}"], 0,
					"log_{3} N = x ⇔ N = 3^{x}。", "底數 3 當底，x 是次方。", "9^{x} − 2 = 3^{x}", "logeq_sub"),
				_f("換元", "令 t = 3^{x}，9^{x} = t^{2}。", "t^{2} − t − [0] = 0", ["2"], "令 t = 3^{x}：t^{2} − t − 2 = 0", "把 3^{x} 移到左邊。", "logeq_sub"),
				_roots("t", ["2", "-1"], "(t − 2)(t + 1) = 0", "兩數相乘 −2、相加 −1。"),
				_tpos("3^{x}", ["2", "-1"], [true, false], "t = −1 不合（3^{x} > 0），t = 2"),
				_c("換回 x", "3^{x} = 2 ⇒ x = ？", ["log_{3} 2", "2/3", "log_{2} 3", "3/2"], 0, "3^{x} = 2 ⇔ x = log_{3} 2。",
					"a^{x} = N ⇔ x = log_{a} N。", "x = log_{3} 2", "logeq_sub"),
			 ],
			 "verify": {"f": func(x): return lb(3, pow(9.0, x) - 2) - x, "ok": func(x): return pow(9.0, x) - 2 > 0, "roots": [lb(3, 2)]}},
		 ]},

		{"id": "recip", "chapter": 1, "type": "forge", "title": "倒數守門", "type_name": "倒數換元",
		 "story": "log_{x} 2 = 1/log_{2} x：令 t = log_{2} x。",
		 "insight": "令 t = log_{a} x（t ≠ 0），乘 t 變二次方程式。x 當底數時 x > 0、≠ 1。",
		 "variants": [
			{"eq": "log_{3} x + 2log_{x} 3 = 3",
			 "steps": [
				_r("log_{x} 3 和 log_{3} x 有什麼關係？用哪條法則？", "recip", ["add", "sub", "swap"], "log_{x} 3 = 1/log_{3} x",
					"底數和真數對調，互為倒數。", "3 和 x 的位置剛好對調。", "logeq_recip"),
				_f("列式", "令 t = log_{3} x：t + 2/t = 3，兩邊乘 t。", "t^{2} − [0]t + [1] = 0", ["3", "2"], "令 t = log_{3} x：t^{2} − 3t + 2 = 0",
					"t^{2} + 2 = 3t。", "logeq_recip"),
				_roots("t", ["1", "2"], "(t − 1)(t − 2) = 0", "兩數相乘 2、相加 −3。"),
				_f("換回 x", "x = 3^{t}（順序不限）。", "x = [0] 或 x = [1]", ["3", "9"], "x = 3 或 x = 9", "3^{1}、3^{2}。", "logeq_recip", "set"),
				_gate(["3", "9"], [true, true], "底數 x > 0 且 x ≠ 1", ["3 > 0、≠ 1 ✓", "9 > 0、≠ 1 ✓"], "x = 3 或 x = 9",
					"兩個都是正數，也都不是 1。"),
			 ],
			 "verify": {"f": func(x): return lb(3, x) + 2 * lb(x, 3) - 3, "ok": func(x): return x > 0 and absf(x - 1) > 1e-9,
				"roots": [3.0, 9.0]}},
			{"eq": "log_{2} x − 3log_{x} 2 = 2",
			 "steps": [
				_r("log_{x} 2 和 log_{2} x 有什麼關係？用哪條法則？", "recip", ["add", "sub", "swap"], "log_{x} 2 = 1/log_{2} x",
					"底數和真數對調，互為倒數。", "2 和 x 的位置剛好對調。", "logeq_recip"),
				_f("列式", "令 t = log_{2} x：t − 3/t = 2，兩邊乘 t。", "t^{2} − [0]t − [1] = 0", ["2", "3"], "令 t = log_{2} x：t^{2} − 2t − 3 = 0",
					"t^{2} − 3 = 2t。", "logeq_recip"),
				_roots("t", ["3", "-1"], "(t − 3)(t + 1) = 0", "兩數相乘 −3、相加 −2。"),
				_f("換回 x", "x = 2^{t}（順序不限）。", "x = [0] 或 x = [1]", ["8", "1/2"], "x = 2^{3} = 8 或 x = 2^{−1} = 1/2",
					"2^{−1} = 1/2。", "logeq_recip", "set"),
				_gate(["8", "1/2"], [true, true], "底數 x > 0 且 x ≠ 1", ["8 > 0、≠ 1 ✓", "1/2 > 0、≠ 1 ✓"], "x = 8 或 x = 1/2",
					"1/2 雖然小於 1，但它是正數，也不等於 1。"),
			 ],
			 "verify": {"f": func(x): return lb(2, x) - 3 * lb(x, 2) - 2, "ok": func(x): return x > 0 and absf(x - 1) > 1e-9,
				"roots": [8.0, 0.5]}},
			{"eq": "log_{x} 9 − log_{3} x = 1",
			 "steps": [
				_f("次方", "9 = 3^{2}。", "log_{x} 9 = [0]log_{x} 3", ["2"], "log_{x} 9 = 2log_{x} 3", "真數的次方拿到前面。", "logeq_recip"),
				_r("log_{x} 3 換成 log_{3} x 的樣子，用哪條法則？", "recip", ["add", "chain", "swap"], "log_{x} 9 = 2/log_{3} x",
					"log_{x} 3 = 1/log_{3} x。", "底數和真數對調。", "logeq_recip"),
				_f("列式", "令 t = log_{3} x：2/t − t = 1，兩邊乘 t。", "t^{2} + t − [0] = 0", ["2"], "令 t = log_{3} x：t^{2} + t − 2 = 0", "2 − t^{2} = t。",
					"logeq_recip"),
				_roots("t", ["1", "-2"], "(t − 1)(t + 2) = 0", "兩數相乘 −2、相加 1。"),
				_f("換回 x", "x = 3^{t}（順序不限）。", "x = [0] 或 x = [1]", ["3", "1/9"], "x = 3 或 x = 3^{−2} = 1/9", "3^{−2} = 1/9。",
					"logeq_recip", "set"),
				_gate(["3", "1/9"], [true, true], "底數 x > 0 且 x ≠ 1", ["3 > 0、≠ 1 ✓", "1/9 > 0、≠ 1 ✓"], "x = 3 或 x = 1/9",
					"兩個都是正數，也都不是 1。"),
			 ],
			 "verify": {"f": func(x): return lb(x, 9) - lb(3, x) - 1, "ok": func(x): return x > 0 and absf(x - 1) > 1e-9,
				"roots": [3.0, 1.0 / 9.0]}},
		 ]},

		{"id": "speed", "chapter": 1, "type": "speed", "title": "守門速算", "time": 210.0, "type_name": "快速解方程式",
		 "story": "改寫成指數式解 x；負的解要擋下來。",
		 "insight": "log_{a} M = k ⇔ M = a^{k}；兩 log 相加時記得 x > 0。",
		 "variants": [{"gen": "logeq", "count": 8}]},

		{"id": "boss1", "chapter": 1, "type": "forge", "title": "守門試煉", "type_name": "綜合", "time": 350.0,
		 "story": "限時 350 秒！化同底、換元、守門檢查，全部用上。",
		 "insight": "最後一步永遠是守門：真數 > 0、底數 > 0 且 ≠ 1。",
		 "variants": [
			{"eq": "2log_{3} x = log_{3} (x + 6)",
			 "steps": [
				_r("左邊的係數 2 怎麼處理？", "pow", ["add", "sub", "recip"], "log_{3} x^{2} = log_{3} (x + 6)", "係數變成真數的次方。", "前面有係數 2。",
					"logeq_base"),
				_f("整理", "x^{2} = x + 6，移項。", "x^{2} − x − [0] = 0", ["6"], "x^{2} − x − 6 = 0", "把 x + 6 移到左邊。"),
				_roots("x", ["3", "-2"], "(x − 3)(x + 2) = 0", "兩數相乘 −6、相加 −1。"),
				_gate(["3", "-2"], [true, false], "x > 0、x + 6 > 0", ["x = 3、x + 6 = 9 ✓", "x = −2 < 0 ✗"], "x = −2 不合，所以 x = 3",
					"原式的真數是 x，不是 x^{2}。"),
			 ],
			 "verify": {"f": func(x): return 2 * lb(3, x) - lb(3, x + 6), "ok": func(x): return x > 0 and x + 6 > 0, "roots": [3.0]}},
			{"eq": "log_{2} (2^{x} − 1) + x = 1",
			 "steps": [
				_c("定義", "log_{2} (2^{x} − 1) = 1 − x，改寫成指數式：", ["2^{x} − 1 = 2^{1 − x}", "2^{x} − 1 = 1 − x", "2^{x} − 1 = 2(1 − x)", "2^{x} = 2^{1 − x}"], 0,
					"log_{2} N = k ⇔ N = 2^{k}。", "移項之後再改寫。", "2^{x} − 1 = 2/2^{x}", "logeq_sub"),
				_c("換元", "令 t = 2^{x}，方程式變成？", ["t^{2} − t − 2 = 0", "t^{2} − t + 2 = 0", "t − 1 = 2t", "t^{2} − 2 = 0"], 0,
					"t − 1 = 2/t，兩邊乘 t。", "2^{1 − x} = 2/2^{x} = 2/t。", "令 t = 2^{x}：t^{2} − t − 2 = 0", "logeq_sub"),
				_roots("t", ["2", "-1"], "(t − 2)(t + 1) = 0", "兩數相乘 −2、相加 −1。"),
				_tpos("2^{x}", ["2", "-1"], [true, false], "t = −1 不合，t = 2"),
				_f("換回 x", "2^{x} = 2。", "x = [0]", ["1"], "x = 1", "2^{1} = 2。", "logeq_sub"),
				_gate(["1"], [true], "2^{x} − 1 > 0", ["2^{1} − 1 = 1 > 0 ✓"], "x = 1", "代進真數 2^{x} − 1。"),
			 ],
			 "verify": {"f": func(x): return lb(2, pow(2.0, x) - 1) + x - 1, "ok": func(x): return pow(2.0, x) - 1 > 0, "roots": [1.0]}},
			{"eq": "(log x)^{2} − log x^{2} − 3 = 0",
			 "steps": [
				_r("log x^{2} 先怎麼處理？", "pow", ["add", "sub", "base"], "log x^{2} = 2log x", "真數的次方拿到前面。", "x 有 2 次方。", "logeq_sub"),
				_f("換元", "令 t = log x。", "t^{2} − [0]t − [1] = 0", ["2", "3"], "令 t = log x：t^{2} − 2t − 3 = 0", "(log x)^{2} = t^{2}。", "logeq_sub"),
				_roots("t", ["3", "-1"], "(t − 3)(t + 1) = 0", "兩數相乘 −3、相加 −2。"),
				_f("換回 x", "x = 10^{t}（順序不限）。", "x = [0] 或 x = [1]", ["1000", "1/10"], "x = 1000 或 x = 1/10", "10^{3}、10^{−1}。",
					"logeq_sub", "set"),
				_gate(["1000", "1/10"], [true, true], "x > 0、x^{2} > 0", ["1000 > 0 ✓", "1/10 > 0 ✓"], "x = 1000 或 x = 1/10",
					"10^{t} 一定大於 0。"),
			 ],
			 "verify": {"f": func(x): return pow(lg(x), 2) - lg(x * x) - 3, "ok": func(x): return x > 0, "roots": [1000.0, 0.1]}},
		 ]},

		# ======================= 第二章．大師的球門 =======================
		{"id": "power", "chapter": 2, "type": "forge", "title": "高高在上", "type_name": "取對數",
		 "story": "次方上有 log：兩邊取 log，把次方拿下來。",
		 "insight": "取 log_{a}：log_{a} (x^{log_{a} x}) = (log_{a} x)^{2}，再令 t。",
		 "variants": [
			{"eq": "x^{log_{2} x} = 16",
			 "steps": [
				_c("取 log", "兩邊取 log_{2}，左邊變成？", ["(log_{2} x)^{2}", "log_{2} x", "2log_{2} x", "log_{2} (log_{2} x)"], 0,
					"log_{2} M^{r} = r·log_{2} M，這裡 r = log_{2} x。", "次方 log_{2} x 拿到前面當係數。", "(log_{2} x)^{2} = log_{2} 16 = 4",
					"logeq_power"),
				_roots("log_{2} x", ["2", "-2"], "log_{2} x = ±2", "平方等於 4。"),
				_f("換回 x", "x = 2^{t}（順序不限）。", "x = [0] 或 x = [1]", ["4", "1/4"], "x = 4 或 x = 1/4", "2^{2}、2^{−2}。", "logeq_power", "set"),
				_gate(["4", "1/4"], [true, true], "x > 0", ["4 > 0 ✓", "1/4 > 0 ✓"], "x = 4 或 x = 1/4", "x = 2^{t} 一定大於 0。"),
			 ],
			 "verify": {"f": func(x): return pow(x, lb(2, x)) - 16, "ok": func(x): return x > 0, "roots": [4.0, 0.25]}},
			{"eq": "x^{log x} = 100x",
			 "steps": [
				_c("取 log", "兩邊取 log：", ["(log x)^{2} = 2 + log x", "log x = 100 + log x", "(log x)^{2} = 100log x", "(log x)^{2} = 2log x"], 0,
					"左邊：log x · log x；右邊：log 100 + log x = 2 + log x。", "右邊是相乘，取 log 變相加。", "(log x)^{2} = 2 + log x",
					"logeq_power"),
				_f("換元", "令 t = log x，移項。", "t^{2} − t − [0] = 0", ["2"], "令 t = log x：t^{2} − t − 2 = 0", "把 2 + t 移到左邊。", "logeq_power"),
				_roots("t", ["2", "-1"], "(t − 2)(t + 1) = 0", "兩數相乘 −2、相加 −1。"),
				_f("換回 x", "x = 10^{t}（順序不限）。", "x = [0] 或 x = [1]", ["100", "1/10"], "x = 100 或 x = 1/10", "10^{2}、10^{−1}。",
					"logeq_power", "set"),
				_gate(["100", "1/10"], [true, true], "x > 0", ["100 > 0 ✓", "1/10 > 0 ✓"], "x = 100 或 x = 1/10", "10^{t} 一定大於 0。"),
			 ],
			 "verify": {"f": func(x): return lg(pow(x, lg(x))) - lg(100 * x), "ok": func(x): return x > 0, "roots": [100.0, 0.1]}},
			{"eq": "x^{log_{3} x} = 9x",
			 "steps": [
				_c("取 log", "兩邊取 log_{3}：", ["(log_{3} x)^{2} = 2 + log_{3} x", "(log_{3} x)^{2} = 9 + log_{3} x", "log_{3} x = 2 + log_{3} x",
					"(log_{3} x)^{2} = 2log_{3} x"], 0,
					"右邊 log_{3} 9 + log_{3} x = 2 + log_{3} x。", "右邊是相乘，取 log 變相加。", "(log_{3} x)^{2} = 2 + log_{3} x", "logeq_power"),
				_f("換元", "令 t = log_{3} x，移項。", "t^{2} − t − [0] = 0", ["2"], "令 t = log_{3} x：t^{2} − t − 2 = 0", "把 2 + t 移到左邊。", "logeq_power"),
				_roots("t", ["2", "-1"], "(t − 2)(t + 1) = 0", "兩數相乘 −2、相加 −1。"),
				_f("換回 x", "x = 3^{t}（順序不限）。", "x = [0] 或 x = [1]", ["9", "1/3"], "x = 9 或 x = 1/3", "3^{2}、3^{−1}。", "logeq_power", "set"),
				_gate(["9", "1/3"], [true, true], "x > 0", ["9 > 0 ✓", "1/3 > 0 ✓"], "x = 9 或 x = 1/3", "3^{t} 一定大於 0。"),
			 ],
			 "verify": {"f": func(x): return lb(3, x) * lb(3, x) - lb(3, 9 * x), "ok": func(x): return x > 0, "roots": [9.0, 1.0 / 3.0]}},
		 ]},

		{"id": "vieta", "chapter": 2, "type": "forge", "title": "兩根之積", "type_name": "根與係數",
		 "story": "不必解根：兩根之和 = −b/a，再合併 log。",
		 "insight": "log_{a} α + log_{a} β = log_{a} αβ = 兩根之和 ⇒ αβ = a^{兩根和}。",
		 "variants": [
			{"eq": "(log x)^{2} − 3log x + 1 = 0 的兩根為 α、β\n[color=#ffcf5a]求 αβ[/color]",
			 "steps": [
				_c("換元", "令 t = log x，這個二次方程式的兩根 t₁、t₂ 是？", ["log α、log β", "α、β", "10^{α}、10^{β}", "log αβ"], 0,
					"x = α 時 t = log α，x = β 時 t = log β。", "t 是 log x。", "令 t = log x：t^{2} − 3t + 1 = 0 的兩根是 log α、log β", "logeq_vieta"),
				_f("根與係數", "t₁ + t₂ = −b/a。", "log α + log β = [0]", ["3"], "log α + log β = 3", "−(−3)/1。", "logeq_vieta"),
				_r("log α + log β 合併：", "add", ["sub", "pow", "recip"], "log αβ = 3", "相加 ⇒ 真數相乘。", "兩項是「相加」。", "logeq_vieta"),
				_f("答案", "改寫成指數式。", "αβ = [0]", ["1000"], "αβ = 10^{3} = 1000", "10^{3}。", "logeq_vieta"),
			 ],
			 "check": [pow(10.0, (3 + sqrt(5.0)) / 2) * pow(10.0, (3 - sqrt(5.0)) / 2), 1000.0, 1e-6]},
			{"eq": "x^{log_{2} x} = 8x^{3} 的兩根為 α、β\n[color=#ffcf5a]求 αβ[/color]",
			 "steps": [
				_c("取 log", "兩邊取 log_{2}：", ["(log_{2} x)^{2} = 3 + 3log_{2} x", "(log_{2} x)^{2} = 8 + 3log_{2} x", "log_{2} x = 3 + 3log_{2} x",
					"(log_{2} x)^{2} = 24log_{2} x"], 0,
					"右邊：log_{2} 8 + log_{2} x^{3} = 3 + 3log_{2} x。", "右邊是相乘，取 log 變相加。", "(log_{2} x)^{2} − 3log_{2} x − 3 = 0",
					"logeq_power"),
				_f("根與係數", "t^{2} − 3t − 3 = 0 不好因式分解，不用解！兩根是 log_{2} α、log_{2} β。", "log_{2} α + log_{2} β = [0]", ["3"], "log_{2} α + log_{2} β = 3",
					"t^{2} − 3t − 3 = 0，兩根之和 = 3。", "logeq_vieta"),
				_r("log_{2} α + log_{2} β 合併：", "add", ["sub", "pow", "chain"], "log_{2} αβ = 3", "相加 ⇒ 真數相乘。", "兩項是「相加」。", "logeq_vieta"),
				_f("答案", "改寫成指數式。", "αβ = [0]", ["8"], "αβ = 2^{3} = 8", "2^{3}。", "logeq_vieta"),
			 ],
			 "check": [pow(2.0, (3.0 + sqrt(21.0)) / 2) * pow(2.0, (3.0 - sqrt(21.0)) / 2), 8.0, 1e-6]},
			{"eq": "α、β 是 x^{2} − (log 30)x + log 2 · log 15 = 0 的兩根\n[color=#ffcf5a]求 10^{α} × 10^{β}[/color]",
			 "steps": [
				_f("根與係數", "兩根之和 = −b/a。", "α + β = log [0]", ["30"], "α + β = log 30", "−(−log 30)/1。", "logeq_vieta"),
				_c("指數律", "10^{α} × 10^{β} = ？", ["10^{α + β}", "10^{αβ}", "100^{α + β}", "10^{α} + 10^{β}"], 0, "同底相乘，指數相加。",
					"a^{m}·a^{n} = a^{m + n}。", "10^{α} × 10^{β} = 10^{α + β} = 10^{log 30}", "logeq_vieta"),
				_f("答案", "a^{log_{a} N} = N。", "10^{log 30} = [0]", ["30"], "10^{α} × 10^{β} = 30", "定義。", "logeq_vieta"),
			 ],
			 "check": [pow(10.0, lg(30)), 30.0, 1e-6]},
		 ]},

		{"id": "swap", "chapter": 2, "type": "forge", "title": "次方上的真數", "type_name": "互換＋換元",
		 "story": "x^{log_{2} 3} = 3^{log_{2} x}：互換後再換元。",
		 "insight": "互換後令 t = 3^{log_{2} x}（t > 0）。",
		 "variants": [
			{"eq": "9^{log_{2} x} − 4·3^{log_{2} x} + 3 = 0",
			 "steps": [
				_c("換元", "令 t = 3^{log_{2} x}，9^{log_{2} x} = ？", ["t^{2}", "2t", "3t", "t^{3}"], 0,
					"9^{log_{2} x} = (3^{2})^{log_{2} x} = (3^{log_{2} x})^{2}。", "9 = 3^{2}。", "令 t = 3^{log_{2} x}：t^{2} − 4t + 3 = 0", "logeq_sub"),
				_roots("t", ["1", "3"], "(t − 1)(t − 3) = 0", "兩數相乘 3、相加 −4。"),
				_f("換回", "3^{log_{2} x} = 1 或 3（順序不限）。", "log_{2} x = [0] 或 [1]", ["0", "1"], "log_{2} x = 0 或 1", "3^{0} = 1。",
					"logeq_sub", "set"),
				_f("換回 x", "x = 2^{…}（順序不限）。", "x = [0] 或 x = [1]", ["1", "2"], "x = 1 或 x = 2", "2^{0} = 1。", "logeq_sub", "set"),
				_gate(["1", "2"], [true, true], "x > 0（log_{2} x 的真數）", ["1 > 0 ✓", "2 > 0 ✓"], "x = 1 或 x = 2",
					"這裡 x 是真數，不是底數，x = 1 沒問題！"),
			 ],
			 "verify": {"f": func(x): return pow(9.0, lb(2, x)) - 4 * pow(3.0, lb(2, x)) + 3, "ok": func(x): return x > 0, "roots": [1.0, 2.0]}},
			{"eq": "x^{log_{2} 9} − 4x^{log_{2} 3} + 3 = 0",
			 "steps": [
				_r("x^{log_{2} 3} 的 x 和 3 互換，用哪條法則？", "swap", ["recip", "chain", "base"],
					"x^{log_{2} 3} = 3^{log_{2} x}，x^{log_{2} 9} = 9^{log_{2} x}", "a^{log_{c} b} = b^{log_{c} a}。", "x 和 3 交換位置。", "logeq_power"),
				_c("換元", "令 t = 3^{log_{2} x}，方程式變成？", ["t^{2} − 4t + 3 = 0", "t^{2} + 4t + 3 = 0", "t^{3} − 4t + 3 = 0", "t − 4t + 3 = 0"], 0,
					"9^{log_{2} x} = t^{2}。", "9 = 3^{2}。", "令 t = 3^{log_{2} x}：t^{2} − 4t + 3 = 0", "logeq_sub"),
				_roots("t", ["1", "3"], "(t − 1)(t − 3) = 0", "兩數相乘 3、相加 −4。"),
				_f("換回 x", "3^{log_{2} x} = 1 或 3 ⇒ log_{2} x = 0 或 1。", "x = [0] 或 x = [1]", ["1", "2"], "x = 1 或 x = 2", "2^{0}、2^{1}。",
					"logeq_sub", "set"),
				_gate(["1", "2"], [true, true], "x > 0", ["1 > 0 ✓", "2 > 0 ✓"], "x = 1 或 x = 2", "兩個都是正數。"),
			 ],
			 "verify": {"f": func(x): return pow(x, lb(2, 9)) - 4 * pow(x, lb(2, 3)) + 3, "ok": func(x): return x > 0, "roots": [1.0, 2.0]}},
			{"eq": "x^{log 2} + 2^{log x} = 16",
			 "steps": [
				_r("x^{log 2} 的 x 和 2 互換，用哪條法則？", "swap", ["recip", "chain", "pow"], "x^{log 2} = 2^{log x}", "a^{log b} = b^{log a}。",
					"x 和 2 交換位置。", "logeq_power"),
				_f("合併", "兩項一樣！", "[0]·2^{log x} = 16", ["2"], "2·2^{log x} = 16 ⇒ 2^{log x} = 8", "2^{log x} + 2^{log x}。", "logeq_power"),
				_f("指數", "2^{log x} = 8 = 2^{3}。", "log x = [0]", ["3"], "log x = 3", "指數相等。", "logeq_power"),
				_f("答案", "改寫成指數式。", "x = [0]", ["1000"], "x = 10^{3} = 1000", "log x = 3 ⇔ x = 10^{3}。", "logeq_power"),
				_gate(["1000"], [true], "x > 0", ["1000 > 0 ✓"], "x = 1000", "1000 > 0。"),
			 ],
			 "verify": {"f": func(x): return pow(x, lg(2)) + pow(2.0, lg(x)) - 16, "ok": func(x): return x > 0, "roots": [1000.0]}},
		 ]},

		{"id": "boss2", "chapter": 2, "type": "forge", "title": "大師球門", "type_name": "綜合", "time": 350.0,
		 "story": "限時 350 秒！取對數、根與係數、倒數換元，最後要守門。",
		 "insight": "次方有 log 就取 log；log_{x} a 用倒數；只問積用根與係數。最後守門！",
		 "variants": [
			{"eq": "log_{2} (x + 2) + log_{2} (x − 2) = 5",
			 "steps": [
				_r("兩個 log 相加：", "add", ["sub", "pow", "recip"], "log_{2} (x + 2)(x − 2) = 5", "相加 ⇒ 真數相乘。", "兩項是「相加」。"),
				_f("定義", "改寫成指數式。", "x^{2} − 4 = [0]", ["32"], "x^{2} − 4 = 2^{5} = 32", "2^{5} = 32。", "logeq_same"),
				_roots("x", ["6", "-6"], "x^{2} = 36 ⇒ x = ±6", "x^{2} = 36。"),
				_gate(["6", "-6"], [true, false], "x + 2 > 0、x − 2 > 0", ["x + 2 = 8、x − 2 = 4 ✓", "x + 2 = −4 < 0 ✗"], "x = −6 不合，所以 x = 6",
					"x = −6 代進 x + 2。"),
			 ],
			 "verify": {"f": func(x): return lb(2, x + 2) + lb(2, x - 2) - 5, "ok": func(x): return x + 2 > 0 and x - 2 > 0, "roots": [6.0]}},
			{"eq": "x^{2 + log_{3} x} = 27x^{2} 的兩根為 α、β\n[color=#ffcf5a]求 αβ[/color]",
			 "steps": [
				_c("取 log", "兩邊取 log_{3}（令 t = log_{3} x）：", ["(2 + t)t = 3 + 2t", "2 + t = 27 + 2t", "(2 + t)t = 27t^{2}", "2t + t = 3 + 2t"], 0,
					"左邊：(2 + log_{3} x)·log_{3} x；右邊：log_{3} 27 + log_{3} x^{2} = 3 + 2t。", "次方拿到前面；右邊相乘變相加。",
					"t^{2} + 2t = 3 + 2t", "logeq_power"),
				_f("整理", "2t 消掉了！", "t^{2} = [0]", ["3"], "t^{2} = 3 ⇒ t = ±√{3}", "移項。", "logeq_power"),
				_f("根與係數", "兩根是 log_{3} α、log_{3} β。", "log_{3} α + log_{3} β = [0]", ["0"], "log_{3} αβ = √{3} + (−√{3}) = 0", "√{3} − √{3}。",
					"logeq_vieta"),
				_f("答案", "log_{3} αβ = 0。", "αβ = [0]", ["1"], "αβ = 3^{0} = 1", "3^{0} = 1。", "logeq_vieta"),
			 ],
			 "check": [pow(3.0, sqrt(3.0)) * pow(3.0, -sqrt(3.0)), 1.0]},
			{"eq": "log_{x} 4 + log_{2} x = 3",
			 "steps": [
				_f("次方", "4 = 2^{2}。", "log_{x} 4 = [0]log_{x} 2", ["2"], "log_{x} 4 = 2log_{x} 2", "真數的次方拿到前面。", "logeq_recip"),
				_r("log_{x} 2 換成 log_{2} x 的樣子，用哪條法則？", "recip", ["add", "chain", "swap"], "log_{x} 4 = 2/log_{2} x",
					"log_{x} 2 = 1/log_{2} x。", "底數和真數對調。", "logeq_recip"),
				_f("列式", "令 t = log_{2} x：2/t + t = 3，兩邊乘 t。", "t^{2} − [0]t + [1] = 0", ["3", "2"], "令 t = log_{2} x：t^{2} − 3t + 2 = 0", "t^{2} + 2 = 3t。",
					"logeq_recip"),
				_roots("t", ["1", "2"], "(t − 1)(t − 2) = 0", "兩數相乘 2、相加 −3。"),
				_f("換回 x", "x = 2^{t}（順序不限）。", "x = [0] 或 x = [1]", ["2", "4"], "x = 2 或 x = 4", "2^{1}、2^{2}。", "logeq_recip", "set"),
				_gate(["2", "4"], [true, true], "底數 x > 0 且 x ≠ 1", ["2 > 0、≠ 1 ✓", "4 > 0、≠ 1 ✓"], "x = 2 或 x = 4", "兩個都可以當底數。"),
			 ],
			 "verify": {"f": func(x): return lb(x, 4) + lb(2, x) - 3, "ok": func(x): return x > 0 and absf(x - 1) > 1e-9, "roots": [2.0, 4.0]}},
		 ]},
	]
	B4.B2._add_factor_steps(out, "logeq_calc")
	_add_domain_steps(out)
	B4.B2.apply_pre(out, PRE)
	for slot in out:
		slot["plain"] = true
		slot["params"] = slot.get("params", [])
	return out


# ================= 守門速算的題目 =================

## x(x + d) = b^{k} 的組合：[b, d, x]（正根 x，另一個根是負的）
const PAIRS := [[2, 1, 1], [2, 3, 1], [2, 2, 2], [2, 6, 2], [2, 4, 4], [3, 2, 1], [3, 8, 1], [3, 6, 3],
	[5, 4, 1], [6, 1, 2], [10, 3, 2], [10, 15, 5], [6, 9, 3], [2, 7, 1], [2, 14, 2]]


static func _btext(b: int) -> String:
	return "log " if b == 10 else "log_{%d} " % b


static func _lin(p: int, q: int) -> String:
	var s := "x" if p == 1 else "%dx" % p
	if q > 0:
		s += " + %d" % q
	elif q < 0:
		s += " − %d" % -q
	return s


## log_{b} (px + q) = k
static func _gen_lin() -> Dictionary:
	var b: int = [2, 2, 3, 3, 5, 10].pick_random()
	var k := randi_range(0, 3 if b <= 3 else 2)
	var p: int = [1, 1, 2, 3].pick_random()
	var x0 := randi_range(-3, 6)
	var bk := int(pow(b, k))
	var q := bk - p * x0
	if absi(q) > 15 or q == 0:
		return {}
	var eq := "%s(%s) = %d" % [_btext(b), _lin(p, q), k]
	return {"eq": eq, "ans": str(x0).replace("-", "−"), "value": float(x0),
		"resid": lb(b, p * x0 + q) - k,
		"nudge": "改寫成指數式：%s = %d^{%d} = %d。" % [_lin(p, q), b, k, bk], "kind": "lin"}


## log_{b} x + log_{b} (x + d) = k
static func _gen_pair() -> Dictionary:
	var pr: Array = PAIRS.pick_random()
	var b: int = pr[0]
	var d: int = pr[1]
	var x0: int = pr[2]
	var prod := x0 * (x0 + d)
	var k := int(round(log(prod) / log(b)))
	if int(pow(b, k)) != prod:
		return {}
	var eq := "%sx + %s(x + %d) = %d" % [_btext(b), _btext(b), d, k]
	return {"eq": eq, "ans": str(x0), "value": float(x0), "resid": lb(b, x0) + lb(b, x0 + d) - k,
		"nudge": "x(x + %d) = %d，負的根要擋下來（真數 x > 0）。" % [d, prod], "kind": "pair"}


static func gen_problems(_kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	var n_lin := int(ceil(n * 0.6))
	while out.size() < n and guard < 5000:
		guard += 1
		var pb := _gen_lin() if out.size() < n_lin else _gen_pair()
		if pb.is_empty() or seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		pb["q"] = "解出 x（可以填負數）。"
		pb["template"] = "x = [0]"
		pb["tag"] = "logeq_same" if pb.kind == "lin" else "logeq_check"
		out.append(pb)
	return out
