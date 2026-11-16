extends "res://data/levels/num/num_level.gd"
## 數與式 第七大關「方田拼圖」（對應講義重點七：乘法公式）。設計稿：docs/num_r7_design.md
## 底層是 num_level.gd（原野、按鈕速算、背景），題庫在 num7_bank.gd。
##   ・第一章：等式審判（天秤）、看成一整塊、湊成平方差、兩兩配對、四次方的平方差、立方根的有理化、三個殼一起剝、
##            加起來是 0 的立方和、速算
##   ・第二章：先分解再代、倒數的梯子、梯子、雙重根號相加再代、對稱式互求、根號裡的絕對值、平方和 ≤ 0（水槽）、三個平方、速算
##   ・新的圖上元件（num_field.gd）：scale 天秤、chips 項的卡片、sqs 兩塊麥田、ladder 梯子
## 速算：formula（公式的係數，按鈕）、sym（倒數、對稱式，按鈕）

const BankR7 := preload("res://data/levels/num/num7_bank.gd")

const CHAPTERS_R7 := [
	{"ch": 1, "name": "第一章．拼麥田", "topic": "展開與因式分解", "color": UITheme.LIME},
	{"ch": 2, "name": "第二章．爬梯子", "topic": "代入與對稱式互求", "color": UITheme.GOLD},
]


func level_id() -> String:
	return "R7"

func level_title() -> String:
	return "方田拼圖"

func level_subtitle() -> String:
	return "乘法公式"

func level_chapters() -> Array:
	return CHAPTERS_R7

func bank_slots() -> Array:
	return BankR7.slots()

func step_color() -> Color:
	return UITheme.LIME

func chapter_card() -> Dictionary:
	return {"title": "第二章．爬梯子", "button": "出發  ▶",
		"text": "公式都拼好了，接下來代數字進去：\n\n" \
			+ "・先分解，再代進去\n" \
			+ "・知道 a + b、ab，一階一階往上爬\n" \
			+ "・平方加起來 ≤ 0，每一個都是 0\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankR7.T_CUBE if String(r.get("gen", "")) == "formula" else BankR7.T_RECIP


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


static func _sg(v: int) -> String:
	return ("−%d" % -v) if v < 0 else str(v)


static func _shuffle3(ans: String, w1: String, w2: String) -> Dictionary:
	var opts := [ans, w1, w2]
	var order := [0, 1, 2]
	order.shuffle()
	var choices := []
	for i in order:
		choices.append(opts[i])
	return {"choices": choices, "correct": order.find(0)}


## 速算題：
##   formula  (px ± q)^{2} 的 x 項、(x ± q)^{3} 的 x 項、x^{3} ± q^{3} 分解的中間項；按鈕：答案、正負號相反、忘了乘 2（或 3）
##   sym      x + \frac{1}{x} = k 求 x^{2} + \frac{1}{x^{2}}、a + b 和 ab 求 a^{2} + b^{2}
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		var pb := {}
		var ans := ""
		var w1 := ""
		var w2 := ""
		if kind == "formula":
			var q := randi_range(1, 5)
			var minus := randf() < 0.5
			var sg := -1 if minus else 1
			var typ := randi() % 3
			if typ == 0:
				var p := randi_range(2, 4)
				pb = {"eq": "(%dx %s %d)^{2} 的 x 項係數？" % [p, "−" if minus else "+", q],
					"nudge": "2 × %dx × %d。" % [p, q]}
				ans = _sg(2 * p * q * sg)
				w1 = _sg(-2 * p * q * sg)
				w2 = _sg(p * q * sg)
			elif typ == 1:
				q = randi_range(2, 4)
				pb = {"eq": "(x %s %d)^{3} 的 x 項係數？" % ["−" if minus else "+", q],
					"nudge": "3 × x × %d^{2}。" % q}
				ans = str(3 * q * q)
				w1 = str(q * q)
				w2 = _sg(-3 * q * q) if not minus else str(3 * q)
			else:
				q = randi_range(2, 5)
				pb = {"eq": "x^{3} %s %d = (x %s %d)(x^{2} + kx + %d)，k = ？" % ["−" if minus else "+", q * q * q, "−" if minus else "+", q, q * q],
					"nudge": "立方%s：中間那一項是%s號。" % ["差" if minus else "和", "加" if minus else "減"]}
				ans = _sg(q if minus else -q)
				w1 = _sg(-q if minus else q)
				w2 = _sg(2 * q if minus else -2 * q)
			pb["tag"] = BankR7.T_CUBE
		else:
			if randf() < 0.5:
				var k := randi_range(2, 6)
				var root := randf() < 0.4
				var ks := str(k)
				var k2 := k * k
				if root:
					# x + \frac{1}{x} 是實數時至少是 2：√k ≥ 2，k ≥ 4（4、9 開得出來，不用根號）
					k = randi_range(5, 11)
					if k == 9:
						continue
					ks = "√%d" % k
					k2 = k
				pb = {"eq": "x + \\frac{1}{x} = %s，x^{2} + \\frac{1}{x^{2}} = ？" % ks, "nudge": "(%s)^{2} − 2。" % ks}
				ans = str(k2 - 2)
				w1 = str(k2 + 2)
				w2 = str(k2)
			else:
				var s := randi_range(2, 7)
				var p := randi_range(-3, 6)
				# a、b 要是實數：判別式 s^{2} − 4p ≥ 0
				if p == 0 or s * s < 4 * p:
					continue
				var ps := ("(%s)" % _sg(p)) if p < 0 else str(p)
				pb = {"eq": "a + b = %d、ab = %s，a^{2} + b^{2} = ？" % [s, _sg(p)], "nudge": "%d^{2} − 2 × %s。" % [s, ps]}
				ans = _sg(s * s - 2 * p)
				w1 = _sg(s * s + 2 * p)
				w2 = _sg(s * s - p)
			pb["tag"] = BankR7.T_RECIP
		if ans == w1 or ans == w2 or w1 == w2:
			continue
		pb.merge(_shuffle3(ans, w1, w2))
		pb["q"] = "點一個"
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out
