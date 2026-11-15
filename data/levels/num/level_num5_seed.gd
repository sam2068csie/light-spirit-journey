extends "res://data/levels/num/num_level.gd"
## 數與式 第五大關「篩種倉庫」（對應講義重點五：有理數與無理數）。設計稿：docs/num_r5_design.md
## 底層是 num_level.gd（原野、按鈕速算、背景），題庫在 num5_bank.gd。
##   ・第一章：篩種子、算一算再篩、審判台（三種題型）、一定是有理數嗎、半圓裡的線段、速算
##   ・第二章：兩個秤盤、秤盤的條件、反證法、分母有理化、三項的分母、速算
##   ・種子拖進兩個籃子（num_field.gd 的 seeds、lsort）
## 速算：rat（有理數還是無理數，按鈕位置固定）、ratz（分母有理化，按鈕）

const BankR5 := preload("res://data/levels/num/num5_bank.gd")

const CHAPTERS_R5 := [
	{"ch": 1, "name": "第一章．兩個籃子", "topic": "分辨有理數、無理數，封閉性", "color": UITheme.GOOD},
	{"ch": 2, "name": "第二章．秤盤與反證", "topic": "比較係數、反證法、分母有理化", "color": UITheme.CYAN},
]


func level_id() -> String:
	return "R5"

func level_title() -> String:
	return "篩種倉庫"

func level_subtitle() -> String:
	return "有理數與無理數"

func level_chapters() -> Array:
	return CHAPTERS_R5

func bank_slots() -> Array:
	return BankR5.slots()

func step_color() -> Color:
	return UITheme.GOOD

func chapter_card() -> Dictionary:
	return {"title": "第二章．秤盤與反證", "button": "上秤  ▶",
		"text": "種子都篩好了，接下來用有理數、無理數的性質解題：\n\n" \
			+ "・有理數放一盤、根號放一盤，比較係數\n" \
			+ "・反證法：假設它是有理數，推到矛盾\n" \
			+ "・分母有理化，三項的分兩次做\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankR5.T_RAT if String(r.get("gen", "")) == "rat" else BankR5.T_RATZ


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


const NON_SQ := [2, 3, 5, 6, 7, 8, 10, 11, 12, 13, 15, 18, 20]
const SQ_FREE := [2, 3, 5, 6, 7, 10, 11, 13, 14, 15, 17, 19]     # 有理化的題目：根號已經是最簡


## 速算題：
##   rat   一顆種子，按鈕「有理數」「無理數」（位置固定）
##   ratz  \frac{k}{√a ∓ b}（k = a − b^{2}），按鈕三個：答案、符號沒變、分母沒約掉
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		var pb := {}
		if kind == "rat":
			var s := ""
			var ok := true
			var why := ""
			match randi() % 7:
				0:
					var m := randi_range(2, 9)
					if randf() < 0.5:
						s = "√%d" % (m * m)
						why = "√%d = %d。" % [m * m, m]
					else:
						var a: int = NON_SQ[randi() % NON_SQ.size()]
						s = "√%d" % a
						ok = false
						why = "%d 不是完全平方數。" % a
				1:
					var q := randi_range(3, 13)
					var p := randi_range(1, 30)
					if _gcd(p, q) != 1:
						continue
					s = "\\frac{%d}{%d}" % [p, q]
					why = "分數是有理數。"
				2:
					s = "%d.\\ol{%d}" % [randi_range(0, 3), randi_range(1, 98)]
					why = "循環小數是有理數。"
				3:
					var a: int = NON_SQ[randi() % NON_SQ.size()]
					var b: int = NON_SQ[randi() % NON_SQ.size()]
					var root := int(roundf(sqrt(float(a * b))))
					ok = root * root == a * b
					s = "√%d × √%d" % [a, b]
					why = "√%d × √%d = √%d%s。" % [a, b, a * b, (" = %d" % root) if ok else ""]
				4:
					var k := randi_range(1, 5)
					s = "π + %d" % k if randf() < 0.5 else "%dπ" % (k + 1)
					ok = false
					why = "π 是無理數。"
				5:
					var a: int = NON_SQ[randi() % NON_SQ.size()]
					s = "√%d + √%d" % [a, a] if randf() < 0.5 else "√%d − √%d" % [a, a]
					ok = s.contains("−")
					why = "√%d − √%d = 0。" % [a, a] if ok else "√%d + √%d = 2√%d。" % [a, a, a]
				6:
					var a: int = NON_SQ[randi() % NON_SQ.size()]
					var m := randi_range(2, 4)
					s = "\\frac{√%d}{√%d}" % [a * m * m, a]
					why = "\\frac{√%d}{√%d} = √%d = %d。" % [a * m * m, a, m * m, m]
			pb = {"eq": "%s\n是有理數還是無理數？" % s, "q": "點一個", "choices": ["有理數", "無理數"],
				"correct": 0 if ok else 1, "tag": BankR5.T_RAT, "nudge": why}
		else:
			var a: int = SQ_FREE[randi() % SQ_FREE.size()]
			var b := randi_range(1, 3)
			var k := a - b * b
			if k < 2:
				continue
			var minus := randf() < 0.5
			var den := "√%d %s %d" % [a, "−" if minus else "+", b]
			var right := "√%d %s %d" % [a, "+" if minus else "−", b]
			var opts := [right, den, "%d(%s)" % [k, right]]
			var order := [0, 1, 2]
			order.shuffle()
			var choices := []
			for i in order:
				choices.append(opts[i])
			pb = {"eq": "\\frac{%d}{%s} = ？" % [k, den], "q": "分母有理化", "choices": choices, "correct": order.find(0),
				"tag": BankR5.T_RATZ, "nudge": "上下同乘 %s，分母是 %d − %d = %d。" % [right, a, b * b, k]}
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out
