extends RefCounted
## 多項式 第四大關「根之鑄模」（求多項式）題庫：草稿
## 這一關還沒做（units.gd 的 P4 還沒有 file、bank）。先放第三關搬過來的「牛頓階梯假設法」（求多項式），做 P4 時再補其他題型。

const SB := preload("res://data/levels/engine/step_bank.gd")
const P3 := preload("res://data/levels/poly/poly3_bank.gd")
const T_NEWT := P3.T_NEWT


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return SB.fill(name, q, template, answers, line, nudge, tag, mode)


static func _echo(st: Dictionary, x: String, val: String) -> Dictionary:
	return P3._echo(st, x, val)


static func slots() -> Array:
	var out := _slots()
	for slot in out:
		slot["plain"] = true
		SB.fix_roots(slot)
		slot["params"] = slot.get("params", [])
	return out


static func _slots() -> Array:
	return [
		{"id": "newton", "chapter": 1, "type": "forge", "title": "牛頓階梯",
		 "story": "石廊裡有一座階梯：每喊一個數，就往上走一階、解出一個係數——這是牛頓階梯假設法，不用解聯立。",
		 "insight": "牛頓階梯假設法：知道 f(a)、f(b)、f(c) 的二次式，設 f(x) = P(x − a)(x − b) + Q(x − a) + R，依序代 a、b、c，一次求出一個係數。",
		 "variants": [
			{"eq": "f(x) 是二次多項式，f(121) = 1，f(122) = 4，f(123) = 11\n求 f(125)",
			 "steps": [
				_c("怎麼假設", "用牛頓階梯假設法，f(x) 要設成？", ["P(x − 121)(x − 122) + Q(x − 121) + R", "ax^{2} + bx + c",
					"P(x − 121)(x − 122)(x − 123)", "P(x − 122) + Q(x − 123) + R"], 0,
					"代 121 時前兩項都是 0，代 122 時第一項是 0：一階一階往上解。", "每一項多乘一個 (x − 下一個數)。",
					"設 f(x) = P(x − 121)(x − 122) + Q(x − 121) + R", T_NEWT),
				_echo(_f("第一階：代 121", "x = 121：前兩項都是 0。", "R = [0]", ["1"], "代 121：R = f(121) = 1", "只剩 R = f(121)。", T_NEWT), "121", "1"),
				_echo(_f("第二階：代 122", "x = 122：第一項是 0，剩 Q(122 − 121) + 1 = 4。", "Q = [0]", ["3"], "代 122：Q + 1 = 4 ⇒ Q = 3",
					"Q × 1 + 1 = 4。", T_NEWT), "122", "4"),
				_echo(_f("第三階：代 123", "x = 123：P × 2 × 1 + 3 × 2 + 1 = 11。", "2P + [0] = 11", ["7"], "代 123：2P + 7 = 11",
					"3 × 2 + 1。", T_NEWT), "123", "11"),
				_f("求 P", "2P + 7 = 11。", "P = [0]", ["2"], "P = 2 ⇒ f(x) = 2(x − 121)(x − 122) + 3(x − 121) + 1", "2P = 4。", T_NEWT),
				_f("代 125", "先算括號：125 − 121、125 − 122。", "125 − 121 = [0]，125 − 122 = [1]", ["4", "3"], "125 − 121 = 4，125 − 122 = 3",
					"直接相減。", T_NEWT),
				_f("求 f(125)", "f(125) = 2 × 4 × 3 + 3 × 4 + 1。", "f(125) = [0]", ["37"], "f(125) = 24 + 12 + 1 = 37", "24 + 12 + 1。", T_NEWT),
			 ]},
			{"eq": "f(x) 是二次多項式，f(0) = 3，f(1) = 4，f(3) = 18\n求 f(x)",
			 "steps": [
				_c("怎麼假設", "用牛頓階梯假設法，f(x) 要設成？", ["Px(x − 1) + Qx + R", "P(x − 1)(x − 3) + Q(x − 3) + R",
					"Px(x − 1)(x − 3)", "Px^{2} + Q"], 0,
					"依序代 0、1、3：x − 0 寫成 x。", "第一階是 (x − 0)、第二階多乘 (x − 1)。", "設 f(x) = Px(x − 1) + Qx + R", T_NEWT),
				_echo(_f("第一階：代 0", "x = 0：前兩項都是 0。", "R = [0]", ["3"], "代 0：R = 3", "R = f(0)。", T_NEWT), "0", "3"),
				_echo(_f("第二階：代 1", "x = 1：Q × 1 + 3 = 4。", "Q = [0]", ["1"], "代 1：Q + 3 = 4 ⇒ Q = 1", "Q + 3 = 4。", T_NEWT), "1", "4"),
				_echo(_f("第三階：代 3", "x = 3：P × 3 × 2 + 1 × 3 + 3 = 18。", "6P + [0] = 18", ["6"], "代 3：6P + 6 = 18", "3 + 3。", T_NEWT), "3", "18"),
				_f("求 P", "6P + 6 = 18。", "P = [0]", ["2"], "P = 2 ⇒ f(x) = 2x(x − 1) + x + 3", "6P = 12。", T_NEWT),
				_f("展開", "2x(x − 1) + x + 3 = 2x^{2} − 2x + x + 3。", "f(x) = [0]x^{2} + ([1])x + [2]", ["2", "-1", "3"], "f(x) = 2x^{2} − x + 3",
					"−2x + x = −x。", T_NEWT),
			 ]},
		 ]},
	]
