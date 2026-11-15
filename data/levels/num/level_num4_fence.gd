extends "res://data/levels/num/num_level.gd"
## 數與式 第四大關「圍籬牧場」（對應講義重點四：算幾不等式）。設計稿：docs/num_r4_design.md
## 底層是 num_level.gd（原野、按鈕速算、背景），題庫在 num4_bank.gd。
##   ・第一章：半圓裡的兩個平均、周長固定的圍籬、面積固定的圍籬、平方和固定、先湊出定值、步道最省、
##             三角形裡的最大面積（兩種題型）、速算。拖圍籬、拖半圓上的點都是坐標方格上的滑桿（slide）
##   ・第二章：倒數型、分式型、根號型、正數才能用、兩個等號一起成立、速算（只用填空，使用者 2026/11/15）
## 速算：fix（給和求積、給積求和，按鈕）、recip（ax + \frac{b}{x} 的最小值，按鈕）

const BankR4 := preload("res://data/levels/num/num4_bank.gd")

const CHAPTERS_R4 := [
	{"ch": 1, "name": "第一章．長滿草的牧場", "topic": "算幾不等式、給和求積、給積求和、應用", "color": UITheme.GOOD},
	{"ch": 2, "name": "第二章．湊出定值", "topic": "倒數型、分式型、根號型、正數才能用", "color": UITheme.GOLD},
]


func level_id() -> String:
	return "R4"

func level_title() -> String:
	return "圍籬牧場"

func level_subtitle() -> String:
	return "算幾不等式"

func level_chapters() -> Array:
	return CHAPTERS_R4

func bank_slots() -> Array:
	return BankR4.slots()

func step_color() -> Color:
	return UITheme.GOOD

func chapter_card() -> Dictionary:
	return {"title": "第二章．湊出定值", "button": "湊湊看  ▶",
		"text": "牧場的草都長滿了，接下來是不容易直接用的式子：\n\n" \
			+ "・x + \\frac{9}{x}：乘起來是定值\n" \
			+ "・分式、根號：先拆成 t + \\frac{k}{t}\n" \
			+ "・負數不能直接用，要先提出負號\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankR4.T_FIX if String(r.get("gen", "")) == "fix" else BankR4.T_FORM


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


static func _term(k: int, v: String) -> String:
	return v if k == 1 else "%d%s" % [k, v]


## 速算題（按鈕三個，答案的位置隨機）：
##   fix    給和求積：pa + qb = S，ab 最大 =（\frac{S}{2}）^{2} ÷ pq。錯的按鈕：乘以 2（忘了除 4 的一半）、和本身
##          給積求和：xy = P，px + qy 最小 = 2√(pqP)。錯的按鈕：√(pqP)（忘了乘 2）、積本身
##   recip  x > 0，ax + \frac{b}{x} 最小 = 2√(ab)。錯的按鈕：√(ab)、a + b
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		var eq := ""
		var right := 0
		var wrongs := []
		var nudge := ""
		var tag := BankR4.T_FIX
		if kind == "fix":
			var p := randi_range(1, 3)
			var q := randi_range(1, 3)
			if out.size() % 2 == 0:
				var s := 2 * randi_range(3, 12)
				var half := int(s / 2.0)
				var top := half * half
				if top % (p * q) != 0:
					continue
				right = int(top / float(p * q))
				wrongs = [right * 2, s]
				eq = "a、b > 0，%s + %s = %d\nab 最大是？" % [_term(p, "a"), _term(q, "b"), s]
				nudge = "%s × %s ≤ (\\frac{%d}{2})^{2} = %d，再除以 %d。" % [_term(p, "a"), _term(q, "b"), s, top, p * q]
			else:
				var pr := randi_range(2, 36)
				var inside := p * q * pr
				var k := int(roundf(sqrt(float(inside))))
				if k * k != inside:
					continue
				right = 2 * k
				wrongs = [k, pr]
				eq = "x、y > 0，xy = %d\n%s + %s 最小是？" % [pr, _term(p, "x"), _term(q, "y")]
				nudge = "%s × %s = %d：最小是 2√%d。" % [_term(p, "x"), _term(q, "y"), inside, inside]
		else:
			tag = BankR4.T_FORM
			var a := randi_range(1, 9)
			var b := randi_range(1, 36)
			var k := int(roundf(sqrt(float(a * b))))
			if k * k != a * b:
				continue
			right = 2 * k
			wrongs = [k, a + b]
			eq = "x > 0\n%s + \\frac{%d}{x} 最小是？" % [_term(a, "x"), b]
			nudge = "%s × \\frac{%d}{x} = %d：最小是 2√%d = %d。" % [_term(a, "x"), b, a * b, a * b, right]
		var opts := [right] + wrongs
		if opts[1] == right or opts[2] == right or opts[1] == opts[2]:
			continue
		var order := [0, 1, 2]
		order.shuffle()
		var choices := []
		for i in order:
			choices.append(str(opts[i]))
		var pb := {"eq": eq, "q": "點最大或最小值", "choices": choices, "correct": order.find(0), "tag": tag, "nudge": nudge}
		if seen.has(eq):
			continue
		seen[eq] = true
		out.append(pb)
	return out
