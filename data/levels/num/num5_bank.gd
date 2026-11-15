extends RefCounted
## 數與式 第五大關「篩種倉庫」題庫（對應講義重點五：有理數與無理數）
## 設計稿：docs/num_r5_design.md。題目的數字都用程式驗算過（tools/num/verify_r5.py）。
##
## 旅程（引擎見 num_level.gd）：
##   forge  一步一步推導：lsort（把種子拖進兩個籃子）、choice（審判卡）、order（證明排順序）、filter、fill
##   speed  速算：gen = "rat"（有理數還是無理數，按鈕）、"ratz"（分母有理化，按鈕）
## 題目的 "field" 是穀倉的種子和兩個籃子（seeds，寫法見 num_field.gd 開頭）。
## 看圖作答、少讀字（design_rules 1.8）：分類都用拖的。

const SB := preload("res://data/levels/engine/step_bank.gd")
const B1 := preload("res://data/levels/num/num1_bank.gd")

const T_RAT := "num_rat"           # 分辨有理數、無理數
const T_CLO := "num_closure"       # 封閉性、一定是有理數嗎
const T_COEF := "num_coef"         # 比較係數
const T_CONTRA := "num_contra"     # 反證法
const T_RATZ := "num_ratz"         # 分母有理化

const RAT := "有理數"
const IRR := "無理數"


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return SB.fill(name, q, template, answers, line, nudge, tag, mode)


static func _j(name: String, statement: String, ok: bool, why: String, line: String, tag: String) -> Dictionary:
	return B1._j(name, statement, ok, why, line, tag)


## 種子和兩個籃子：seeds = [["算式", 0 或 1], …]，at 是篩種子那一步，hl = [[第幾步起, "算式"], …]
static func _seeds(bins: Array, seeds: Array, at := 0, hl := []) -> Dictionary:
	return {"k": "seeds", "bins": bins, "seeds": seeds, "at": at, "hl": hl}


static func _sort(name: String, q: String, why: Dictionary, nudge: String, line: String, tag: String) -> Dictionary:
	return {"kind": "lsort", "name": name, "q": q, "item": 0, "why": why, "nudge": nudge, "line": line, "tag": tag}


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
				if String(st.get("kind", "")) == "lsort":
					# 種子的名字經過 fix_roots 會變成 √{25}，提示的 key 也要一起換
					var why := {}
					for k in st.get("why", {}):
						why[SB.root_markup(String(k))] = SB.root_markup(String(st.why[k]))
					st["why"] = why
				if String(st.get("kind", "")) == "filter":
					st["bare"] = true          # 候選是線段，不寫「t = 」
				if String(st.get("kind", "")) == "order":
					st["sep"] = "→"            # 證明的句子是順序，不是大小
	return out


static func _slots() -> Array:
	return [
		# ======================= 第一章．分辨與封閉性 =======================
		{"id": "seed", "chapter": 1, "type": "forge", "title": "篩種子",
		 "story": "穀倉裡的種子混在一起，分成兩堆。",
		 "insight": "有理數：可以寫成 \\frac{p}{q}，包括整數、有限小數、循環小數\n無理數：不循環的無限小數，例如 √2、π。√ 先化簡再判斷。",
		 "variants": [
			{"eq": "把種子分成有理數、無理數",
			 "field": [_seeds([RAT, IRR], [["√16", 0], ["π", 1], ["\\frac{22}{7}", 0], ["√8", 1], ["0.\\ol{3}", 0],
				["√2 + 1", 1], ["√2 × √8", 0], ["0.1010010001…", 1]])],
			 "steps": [
				_sort("篩", "把種子拖進籃子",
					{"√16": "√16 = 4。", "√8": "√8 = 2√2。", "√2 × √8": "√2 × √8 = √16 = 4。", "0.\\ol{3}": "循環小數 = \\frac{1}{3}。",
					 "0.1010010001…": "1 和 0 越隔越遠，不會循環。", "\\frac{22}{7}": "分數都是有理數（不是 π）。", "π": "π 不循環。",
					 "√2 + 1": "有理數 + 無理數 = 無理數。"},
					"√ 先化簡，循環小數是有理數。", "有理數：√16、\\frac{22}{7}、0.\\ol{3}、√2 × √8。無理數：π、√8、√2 + 1、0.1010010001…", T_RAT),
			 ]},
			{"eq": "把種子分成有理數、無理數",
			 "field": [_seeds([RAT, IRR], [["√25", 0], ["√12", 1], ["1.\\ol{27}", 0], ["π − 3", 1], ["−√9", 0],
				["\\frac{√2}{2}", 1], ["\\frac{√12}{√3}", 0], ["2.1211211121…", 1]])],
			 "steps": [
				_sort("篩", "把種子拖進籃子",
					{"√25": "√25 = 5。", "√12": "√12 = 2√3。", "\\frac{√12}{√3}": "\\frac{√12}{√3} = √4 = 2。", "1.\\ol{27}": "循環小數 = \\frac{14}{11}。",
					 "2.1211211121…": "1 越來越多，不會循環。", "−√9": "−√9 = −3。", "π − 3": "π 減掉整數還是無理數。",
					 "\\frac{√2}{2}": "無理數除以 2 還是無理數。"},
					"√ 先化簡，循環小數是有理數。", "有理數：√25、1.\\ol{27}、−√9、\\frac{√12}{√3}。無理數：√12、π − 3、\\frac{√2}{2}、2.1211211121…", T_RAT),
			 ]},
		 ]},

		{"id": "calc", "chapter": 1, "type": "forge", "title": "算一算再篩",
		 "story": "先算出結果，再決定放哪個籃子。",
		 "insight": "有理數 + 無理數 = 無理數\n無理數 + 無理數、無理數 × 無理數不一定：√2 + (−√2) = 0、√3 × √12 = 6。",
		 "variants": [
			{"eq": "算一算再分類\n哪些一定成立？",
			 "field": [_seeds([RAT, IRR], [["√2 + (−√2)", 0], ["√3 + √3", 1], ["0 × √5", 0], ["3 + √2", 1],
				["√3 × √12", 0], ["√2 × √3", 1], ["\\frac{√18}{√2}", 0]], 0, [[2, "√2 + (−√2)"], [4, "√3 × √12"]])],
			 "steps": [
				_sort("篩", "算一算再拖進籃子",
					{"√2 + (−√2)": "√2 + (−√2) = 0。", "√3 + √3": "√3 + √3 = 2√3。", "0 × √5": "0 乘任何數都是 0。",
					 "3 + √2": "有理數 + 無理數。", "√3 × √12": "√3 × √12 = √36 = 6。", "√2 × √3": "√2 × √3 = √6。",
					 "\\frac{√18}{√2}": "\\frac{√18}{√2} = √9 = 3。"},
					"先算出來再分。", "有理數：0、0、6、3。無理數：2√3、3 + √2、√6", T_CLO),
				_j("審判一", "無理數 + 無理數一定是無理數", false, "√2 + (−√2) = 0 是有理數。", "無理數 + 無理數不一定是無理數", T_CLO),
				_j("審判二", "有理數 + 無理數一定是無理數", true,
					"如果 r + x = q 是有理數，x = q − r 也會是有理數，矛盾。", "有理數 + 無理數一定是無理數", T_CLO),
				_j("審判三", "無理數 × 無理數一定是無理數", false, "√3 × √12 = 6 是有理數。", "無理數 × 無理數不一定是無理數", T_CLO),
			 ]},
			{"eq": "算一算再分類\n哪些一定成立？",
			 "field": [_seeds([RAT, IRR], [["(1 + √3) + (2 − √3)", 0], ["√5 + 2√5", 1], ["√6 × √6", 0], ["4 − √3", 1],
				["0 × π", 0], ["√2 × √5", 1], ["\\frac{√20}{√5}", 0]], 0, [[2, "(1 + √3) + (2 − √3)"], [3, "0 × π"]])],
			 "steps": [
				_sort("篩", "算一算再拖進籃子",
					{"(1 + √3) + (2 − √3)": "√3 消掉，剩下 3。", "√5 + 2√5": "√5 + 2√5 = 3√5。", "√6 × √6": "√6 × √6 = 6。",
					 "4 − √3": "有理數 − 無理數。", "0 × π": "0 乘任何數都是 0。", "√2 × √5": "√2 × √5 = √10。",
					 "\\frac{√20}{√5}": "\\frac{√20}{√5} = √4 = 2。"},
					"先算出來再分。", "有理數：3、6、0、2。無理數：3√5、4 − √3、√10", T_CLO),
				_j("審判一", "無理數 + 無理數一定是無理數", false, "(1 + √3) + (2 − √3) = 3 是有理數。", "無理數 + 無理數不一定是無理數", T_CLO),
				_j("審判二", "有理數 × 無理數一定是無理數", false, "0 × π = 0 是有理數（有理數是 0 的時候）。", "有理數 × 無理數不一定是無理數", T_CLO),
				_j("審判三", "有理數 + 無理數一定是無理數", true,
					"如果 r + x = q 是有理數，x = q − r 也會是有理數，矛盾。", "有理數 + 無理數一定是無理數", T_CLO),
			 ]},
		 ]},

		# 三種題型（使用者 2026/11/15）：講義第 18、19、20 頁的五選題
		{"id": "judge", "chapter": 1, "type": "forge", "title": "審判台",
		 "story": "一張一張判，舉一個反例就能推翻。",
		 "insight": "推翻一句話，找一個反例就夠了：a = 0、√2 + (−√2)、2 + √3 和 2 − √3\n有理數的加減乘除還是有理數（除數不是 0）。",
		 "variants": [
			{"eq": "a、b 是實數\n下面哪些一定成立？",
			 "steps": [
				_j("審判一", "a、b 有理 ⇒ a + b 有理", true, "有理數相加還是有理數。", "a + b 有理", T_CLO),
				_j("審判二", "2a + 3b、3a − 2b 有理 ⇒ a、b 有理", true,
					"a = \\frac{2(2a + 3b) + 3(3a − 2b)}{13}，b 也一樣解得出來，都是有理數算出來的。", "a、b 都是有理數", T_CLO),
				_j("審判三", "a、b 有理 ⇒ \\frac{a√12 + b}{√3 + 1} 無理", false,
					"a = 1、b = 2：\\frac{2√3 + 2}{√3 + 1} = 2 是有理數（a = b = 0 也是）。", "不一定是無理數", T_CLO),
				_j("審判四", "a 無理 ⇒ a + \\frac{1}{a} 無理", false, "有反例，下一步找找看。", "a + \\frac{1}{a} 不一定無理", T_CLO),
				_c("反例", "哪一個 a 是反例？", ["2 + √3", "√2", "1 + √2"], 0,
					"\\frac{1}{2 + √3} = 2 − √3，a + \\frac{1}{a} = 4 是有理數。√2 是 \\frac{3√2}{2}，1 + √2 是 2√2。",
					"\\frac{1}{a} 有理化看看。", "a = 2 + √3：a + \\frac{1}{a} = 4", T_CLO),
			 ]},
			{"eq": "a、b 是有理數，c、d 是無理數\n下面哪些一定成立？",
			 "steps": [
				_j("審判一", "ac 是無理數", false, "a = 0 時 ac = 0。", "ac 不一定是無理數（a = 0）", T_CLO),
				_j("審判二", "c + d 是無理數", false, "c = √2、d = −√2：c + d = 0。", "c + d 不一定是無理數", T_CLO),
				_j("審判三", "bc 有理 ⇒ b = 0", true, "b ≠ 0 的話，c = \\frac{bc}{b} 是有理數，矛盾。", "bc 有理 ⇒ b = 0", T_CLO),
				_j("審判四", "a + c = 2 + √3 ⇒ a = 2", false, "a = 1、c = 1 + √3 也可以。", "a 不一定是 2", T_COEF),
			 ]},
			{"eq": "a、b、c、d 是實數\n下面哪些一定成立？",
			 "steps": [
				_j("審判一", "a 有理、b 無理 ⇒ a − b 無理", true, "a − b = q 有理的話，b = a − q 也有理，矛盾。", "a − b 無理", T_CLO),
				_j("審判二", "a^{3}、a^{8} 有理 ⇒ a 有理", true,
					"a^{9} = (a^{3})^{3} 是有理數，a ≠ 0 時 a = \\frac{a^{9}}{a^{8}}（a = 0 也是有理數）。", "a 有理", T_CLO),
				_j("審判三", "a + b、b + c、c + a 有理 ⇒ a、b、c 有理", true,
					"a = \\frac{(a + b) + (c + a) − (b + c)}{2}，b、c 也一樣。", "a、b、c 都有理", T_CLO),
				_j("審判四", "a、b 有理，c、d 無理，a + c = b + d ⇒ a = b", false,
					"a = 0、b = 1、c = 1 + √2、d = √2：兩邊都是 1 + √2。", "a 不一定等於 b", T_COEF),
			 ]},
		 ]},

		{"id": "must", "chapter": 1, "type": "forge", "title": "一定是有理數嗎",
		 "story": "a、b 都是無理數，卻加起來、乘起來都是有理數。",
		 "insight": "a + b、ab 有理：a^{2} + b^{2} = (a + b)^{2} − 2ab、(a − 1)(b − 1) = ab − (a + b) + 1 一定有理\na = 1 + √2、b = 1 − √2：a − b = 2√2 是無理數。",
		 "variants": [
			{"eq": "a、b 是無理數，a + b、ab 是有理數\n哪些一定是有理數？",
			 "field": [_seeds(["一定有理", "不一定"], [["a^{2} + b^{2}", 0], ["a − b", 1], ["(a − 1)(b − 1)", 0], ["\\frac{a}{b}", 1]])],
			 "steps": [
				_sort("篩", "拖進兩個籃子",
					{"a^{2} + b^{2}": "a^{2} + b^{2} = (a + b)^{2} − 2ab。", "(a − 1)(b − 1)": "(a − 1)(b − 1) = ab − (a + b) + 1。",
					 "a − b": "a = 1 + √2、b = 1 − √2：a − b = 2√2。", "\\frac{a}{b}": "a = 1 + √2、b = 1 − √2：\\frac{a}{b} = −3 − 2√2。"},
					"用 a + b、ab 寫得出來的就一定有理。", "一定：a^{2} + b^{2}、(a − 1)(b − 1)。不一定：a − b、\\frac{a}{b}", T_CLO),
			 ]},
			{"eq": "a、b 是無理數，a + b、ab 是有理數\n哪些一定是有理數？",
			 "field": [_seeds(["一定有理", "不一定"], [["a^{2}b + ab^{2}", 0], ["a^{2} − b^{2}", 1], ["\\frac{1}{a} + \\frac{1}{b}", 0], ["\\frac{a}{b}", 1]])],
			 "steps": [
				_sort("篩", "拖進兩個籃子",
					{"a^{2}b + ab^{2}": "a^{2}b + ab^{2} = ab(a + b)。", "\\frac{1}{a} + \\frac{1}{b}": "\\frac{1}{a} + \\frac{1}{b} = \\frac{a + b}{ab}。",
					 "a^{2} − b^{2}": "a^{2} − b^{2} = (a + b)(a − b)：a = 1 + √2、b = 1 − √2 時是 4√2。",
					 "\\frac{a}{b}": "a = 1 + √2、b = 1 − √2：\\frac{a}{b} = −3 − 2√2。"},
					"用 a + b、ab 寫得出來的就一定有理。", "一定：a^{2}b + ab^{2}、\\frac{1}{a} + \\frac{1}{b}。不一定：a^{2} − b^{2}、\\frac{a}{b}", T_CLO),
			 ]},
		 ]},

		{"id": "semi", "chapter": 1, "type": "forge", "title": "半圓裡的線段",
		 "story": "半圓裡的線段，有的長度是有理數。",
		 "insight": "直角三角形斜邊上的高：\\ol{PB}^{2} = \\ol{OP} × \\ol{PA}\n\\ol{BD} = \\frac{\\ol{PB}^{2}}{\\ol{BC}}、\\ol{CD} = \\frac{\\ol{PC}^{2}}{\\ol{BC}}（相似三角形）。",
		 "variants": [_semi_variant(2, 8), _semi_variant(1, 6)]},

		{"id": "speed1", "chapter": 1, "type": "speed", "title": "篩種速算", "time": 120.0,
		 "story": "種子一顆一顆掉下來，快速分類！",
		 "insight": "√ 先化簡：√16 = 4、√2 × √8 = 4\n循環小數是有理數，π 是無理數。",
		 "variants": [{"gen": "rat", "count": 10}]},

		# ======================= 第二章．比較係數、反證法與有理化 =======================
		{"id": "pans", "chapter": 2, "type": "forge", "title": "兩個秤盤",
		 "story": "有理數放一盤，根號放一盤，兩盤各自平衡。",
		 "insight": "a、b、c、d 有理：a + c√3 = b + d√3 ⇒ a = b 且 c = d\n先把左邊展開，有理數部分、√3 部分各自相等。",
		 "variants": [
			{"eq": "a、b 是有理數\n(2 + √3)a + (1 − √3)b = 7 − √3，求 (a, b)",
			 "field": [_seeds(["有理數盤", "√3 盤"], [["2a", 0], ["√3a", 1], ["b", 0], ["−√3b", 1]])],
			 "steps": [
				_sort("分盤", "左邊的四項放上秤盤", {"√3a": "√3a 有 √3。", "−√3b": "−√3b 有 √3。", "2a": "2a 沒有 √3。", "b": "b 沒有 √3。"},
					"有 √3 的放 √3 盤。", "(2a + b) + (a − b)√3 = 7 − √3", T_COEF),
				_f("兩條式子", "兩盤各自相等", "2a + b = [0]、a − b = [1]", ["7", "-1"], "2a + b = 7、a − b = −1",
					"√3 盤：a − b 要等於 −1。", T_COEF),
				_f("(a, b)", "解聯立", "(a, b) = ([0], [1])", ["2", "3"], "(a, b) = (2, 3)", "兩式相加：3a = 6。", T_COEF),
			 ]},
			{"eq": "a、b 是有理數\n(1 + 2√2)a + (3 − √2)b = 7 + 7√2，求 (a, b)",
			 "field": [_seeds(["有理數盤", "√2 盤"], [["a", 0], ["2√2a", 1], ["3b", 0], ["−√2b", 1]])],
			 "steps": [
				_sort("分盤", "左邊的四項放上秤盤", {"2√2a": "2√2a 有 √2。", "−√2b": "−√2b 有 √2。", "a": "a 沒有 √2。", "3b": "3b 沒有 √2。"},
					"有 √2 的放 √2 盤。", "(a + 3b) + (2a − b)√2 = 7 + 7√2", T_COEF),
				_f("兩條式子", "兩盤各自相等", "a + 3b = [0]、2a − b = [1]", ["7", "7"], "a + 3b = 7、2a − b = 7",
					"√2 盤：2a − b 要等於 7。", T_COEF),
				_f("(a, b)", "解聯立", "(a, b) = ([0], [1])", ["4", "1"], "(a, b) = (4, 1)", "第二式乘 3 再相加：7a = 28。", T_COEF),
			 ]},
		 ]},

		{"id": "cond", "chapter": 2, "type": "forge", "title": "秤盤的條件",
		 "story": "兩個秤盤要分得開，裡面的東西得是有理數。",
		 "insight": "a + c√2 = b + d√2 ⇒ a = b 且 c = d，要 a、b、c、d 都是有理數\n反例：√2 + 0 × √2 = 0 + 1 × √2。",
		 "variants": [
			{"eq": "a + c√2 = b + d√2\n一定 a = b 且 c = d 嗎？",
			 "steps": [
				_j("審判一", "一定 a = b 且 c = d", false, "有反例，下一步找找看。", "不一定", T_COEF),
				_c("反例", "哪一組 (a, b, c, d) 是反例？", ["(√2, 0, 0, 1)", "(1, 1, 2, 2)", "(0, 0, 1, 1)"], 0,
					"√2 + 0 = 0 + √2，可是 a ≠ b。另外兩組 a = b、c = d，不是反例。", "要兩邊相等，可是 a ≠ b。",
					"(√2, 0, 0, 1)：√2 + 0 = 0 + √2", T_COEF),
				_j("審判二", "a、b、c、d 都有理時就成立", true,
					"c ≠ d 的話，√2 = \\frac{a − b}{d − c} 是有理數，矛盾。所以 c = d，再得到 a = b。", "a、b、c、d 有理 ⇒ a = b 且 c = d", T_COEF),
			 ]},
			{"eq": "a + c√3 = b + d√3\n一定 a = b 且 c = d 嗎？",
			 "steps": [
				_j("審判一", "一定 a = b 且 c = d", false, "有反例，下一步找找看。", "不一定", T_COEF),
				_c("反例", "哪一組 (a, b, c, d) 是反例？", ["(√3, 0, 0, 1)", "(2, 2, 1, 1)", "(0, 0, 3, 3)"], 0,
					"√3 + 0 = 0 + √3，可是 a ≠ b。另外兩組 a = b、c = d，不是反例。", "要兩邊相等，可是 a ≠ b。",
					"(√3, 0, 0, 1)：√3 + 0 = 0 + √3", T_COEF),
				_j("審判二", "a、b、c、d 都有理時就成立", true,
					"c ≠ d 的話，√3 = \\frac{a − b}{d − c} 是有理數，矛盾。所以 c = d，再得到 a = b。", "a、b、c、d 有理 ⇒ a = b 且 c = d", T_COEF),
			 ]},
		 ]},

		{"id": "contra", "chapter": 2, "type": "forge", "title": "反證法",
		 "story": "先假設它是有理數，推到不可能。",
		 "insight": "反證法：假設結論不對 → 推下去 → 得到不可能的事（矛盾）→ 所以結論對\n√5 − √2 = r 有理 ⇒ √2 = \\frac{3 − r^{2}}{2r} 有理，矛盾。",
		 "variants": [_contra_variant(5, 2), _contra_variant(7, 3)]},

		{"id": "ratz", "chapter": 2, "type": "forge", "title": "分母有理化",
		 "story": "分母的根號，上下同乘就消掉。",
		 "insight": "\\frac{k}{√a}：上下同乘 √a\n\\frac{k}{√a − b}：上下同乘 √a + b，分母變成 a − b^{2}。",
		 "variants": [
			{"eq": "把分母有理化\n\\frac{6}{√3}、\\frac{4}{√5 − 1}",
			 "steps": [
				_f("一項", "上下同乘 √3", "\\frac{6}{√3} = [0]√3", ["2"], "\\frac{6}{√3} = \\frac{6√3}{3} = 2√3", "分母變成 3。", T_RATZ),
				_f("兩項", "上下同乘 √5 + 1", "\\frac{4}{√5 − 1} = √5 + [0]", ["1"], "\\frac{4(√5 + 1)}{5 − 1} = √5 + 1",
					"分母 (√5 − 1)(√5 + 1) = 4。", T_RATZ),
			 ]},
			{"eq": "把分母有理化\n\\frac{10}{√5}、\\frac{6}{√7 + 1}",
			 "steps": [
				_f("一項", "上下同乘 √5", "\\frac{10}{√5} = [0]√5", ["2"], "\\frac{10}{√5} = \\frac{10√5}{5} = 2√5", "分母變成 5。", T_RATZ),
				_f("兩項", "上下同乘 √7 − 1", "\\frac{6}{√7 + 1} = √7 − [0]", ["1"], "\\frac{6(√7 − 1)}{7 − 1} = √7 − 1",
					"分母 (√7 + 1)(√7 − 1) = 6。", T_RATZ),
			 ]},
		 ]},

		{"id": "three", "chapter": 2, "type": "forge", "title": "三項的分母",
		 "story": "三項的分母，分兩次有理化。",
		 "insight": "1 + √2 + √3：先把 1 + √2 看成一組，乘 (1 + √2) − √3\n分母變成 (1 + √2)^{2} − 3 = 2√2，再有理化一次。",
		 "variants": [
			{"eq": "把 \\frac{8}{1 + √2 + √3} 的分母有理化",
			 "steps": [
				_f("第一次", "1 + √2 看成一組", "(1 + √2 + √3)(1 + √2 − √3) = [0]√2", ["2"], "(1 + √2)^{2} − 3 = 2√2",
					"(1 + √2)^{2} = 3 + 2√2。", T_RATZ),
				_f("第二次", "再乘 √2", "\\frac{8(1 + √2 − √3)}{2√2} = [0] + [1]√2 − [2]√6", ["4", "2", "2"],
					"\\frac{4(1 + √2 − √3)}{√2} = 2√2(1 + √2 − √3) = 4 + 2√2 − 2√6", "\\frac{4}{√2} = 2√2。", T_RATZ),
			 ]},
			{"eq": "把 \\frac{12}{√2 + √3 + √5} 的分母有理化",
			 "steps": [
				_f("第一次", "√2 + √3 看成一組", "(√2 + √3 + √5)(√2 + √3 − √5) = [0]√6", ["2"], "(√2 + √3)^{2} − 5 = 2√6",
					"(√2 + √3)^{2} = 5 + 2√6。", T_RATZ),
				_f("第二次", "再乘 √6", "\\frac{12(√2 + √3 − √5)}{2√6} = [0]√3 + [1]√2 − √30", ["2", "3"],
					"\\frac{6(√2 + √3 − √5)}{√6} = √6(√2 + √3 − √5) = 2√3 + 3√2 − √30", "\\frac{6}{√6} = √6。", T_RATZ),
			 ]},
		 ]},

		{"id": "speed2", "chapter": 2, "type": "speed", "title": "有理化速算", "time": 120.0,
		 "story": "分母的根號一個一個消掉！",
		 "insight": "\\frac{k}{√a − b}：上下同乘 √a + b\n分母 a − b^{2}，分子要一起乘。",
		 "variants": [{"gen": "ratz", "count": 8}]},
	]


## 半圓裡的線段：O(0, 0)、P(p, 0)、A(L, 0)，以 \ol{OA} 為直徑的半圓，B 在 P 的正上方，C 是圓心，D 是 P 到 \ol{BC} 的垂足
static func _semi_variant(p: int, L: int) -> Dictionary:
	var c := L / 2.0
	var pb2 := p * (L - p)
	var pb := sqrt(float(pb2))
	var bc := c
	var pc := c - p
	var bd := pb2 / bc
	var cd := pc * pc / bc
	var dx := p + (c - p) * bd / bc
	var dy := pb * (1.0 - bd / bc)
	return {"eq": "O(0, 0)、P(%d, 0)、A(%d, 0)，以 \\ol{OA} 為直徑畫半圓\n哪些長度是有理數？" % [p, L],
		"plane": B1._plane([-1, L + 1], [-0.6, c + 0.8], [
			{"k": "arc", "o": [c, 0], "r": c, "a0": 0, "a1": 180, "c": "dim"},
			{"k": "seg", "a": [0, 0], "b": [L, 0], "c": "dim"},
			{"k": "seg", "a": [p, 0], "b": [p, pb], "c": "gold"}, {"k": "seg", "a": [p, pb], "b": [c, 0], "c": "cyan"},
			{"k": "seg", "a": [p, 0], "b": [dx, dy], "c": "lime"},
			{"k": "dot", "p": [0, 0], "s": "O", "off": [-14, 16]}, {"k": "dot", "p": [p, 0], "s": "P", "off": [-4, 18]},
			{"k": "dot", "p": [c, 0], "s": "C", "off": [-4, 18]}, {"k": "dot", "p": [L, 0], "s": "A", "off": [4, 18]},
			{"k": "dot", "p": [p, pb], "s": "B", "off": [-16, -6]}, {"k": "dot", "p": [dx, dy], "s": "D", "off": [6, -6]}]),
		"steps": [
			_f("PB", "\\ol{OP} × \\ol{PA}", "\\ol{PB}^{2} = [0]", [str(pb2)],
				"\\ol{PB}^{2} = \\ol{OP} × \\ol{PA} = %d × %d = %d ⇒ \\ol{PB} = √%d" % [p, L - p, pb2, pb2], "直角三角形 OBA 斜邊上的高。", T_CLO),
			_f("BD、CD", "\\ol{BC} 是半徑 %s" % _n(bc), "\\ol{BD} = [0]、\\ol{CD} = [1]", [_frac(pb2, bc), _frac(pc * pc, bc)],
				"\\ol{BD} = \\frac{\\ol{PB}^{2}}{\\ol{BC}} = %s、\\ol{CD} = \\frac{\\ol{PC}^{2}}{\\ol{BC}} = %s" % [_frac_tex(pb2, bc), _frac_tex(pc * pc, bc)],
				"\\ol{BD} = \\frac{\\ol{PB}^{2}}{\\ol{BC}}、\\ol{CD} = \\frac{\\ol{PC}^{2}}{\\ol{BC}}。", T_CLO),
			B1._flt("哪些有理", "點出有理數長度", ["\\arc{OBA}", "\\ol{PB}", "\\ol{BD}", "\\ol{CD}", "\\ol{PD}"], [false, false, true, true, false],
				"有理數", "無理數", "弧長有 π，\\ol{PB} = √%d，\\ol{PD} = \\frac{\\ol{PB} × \\ol{PC}}{\\ol{BC}} 也有 √%d" % [pb2, pb2],
				"弧長 = π × 半徑。\\ol{PD} = \\frac{\\ol{PB} × \\ol{PC}}{\\ol{BC}}。", T_CLO),
		]}


static func _n(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else str(v)


## v / d 寫成答案（整數或 a/b）
static func _frac(v: float, d: float) -> String:
	var num := int(roundf(v * 2.0))
	var den := int(roundf(d * 2.0))
	var g := _gcd(num, den)
	num /= g
	den /= g
	return str(num) if den == 1 else "%d/%d" % [num, den]


static func _frac_tex(v: float, d: float) -> String:
	var s := _frac(v, d)
	if not s.contains("/"):
		return s
	var parts := s.split("/")
	return "\\frac{%s}{%s}" % [parts[0], parts[1]]


static func _gcd(a: int, b: int) -> int:
	a = absi(a)
	b = absi(b)
	while b != 0:
		var t := a % b
		a = b
		b = t
	return maxi(a, 1)


## 反證法：證明 √p − √q 是無理數（已知 √q 是無理數）
static func _contra_variant(p: int, q: int) -> Dictionary:
	var top := p - q
	var last := "√%d = \\frac{%d − r^{2}}{2r}" % [q, top]
	return {"eq": "已知 √%d 是無理數\n證明 √%d − √%d 是無理數" % [q, p, q],
		"steps": [
			B1._o("把證明排好", [["①", "假設 √%d − √%d = r 是有理數" % [p, q], 1], ["②", "√%d = r + √%d，兩邊平方" % [p, q], 2],
				["③", "%d = r^{2} + 2√%dr + %d" % [p, q, q], 3], ["④", last, 4]],
				"假設 √%d − √%d = r 有理 ⇒ … ⇒ %s" % [p, q, last], "先假設，再移項、平方。", T_CONTRA),
			_c("矛盾", "哪一句是矛盾？", [last, "%d = r^{2} + 2√%dr + %d" % [p, q, q], "√%d = r + √%d" % [p, q]], 0,
				"左邊 √%d 是無理數，右邊是有理數算出來的（r ≠ 0，因為 √%d ≠ √%d）：不可能相等。前兩句都是正確的推導。" % [q, p, q],
				"哪一句左右兩邊一個有理、一個無理？", "%s：左邊無理、右邊有理，矛盾 ⇒ √%d − √%d 是無理數" % [last, p, q], T_CONTRA),
		]}
