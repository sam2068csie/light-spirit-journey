extends "res://data/levels/num/num_level.gd"
## 數與式 第六大關「剝殼磨坊」（對應講義重點六：雙根號問題）。設計稿：docs/num_r6_design.md
## 底層是 num_level.gd（原野、按鈕速算、背景），題庫在 num6_bank.gd。
##   ・第一章：找兩個數、減號的那一個、先湊出 2√b、兩層的、化簡後比較係數、速算
##   ・第二章：由內往外夾、先化簡再夾、代入求值、反過來求、速算
##   ・找兩個數用點長方形（num_field.gd 的 rects、rtap），整數部分在數線上點（ltap）
## 速算：husk（雙重根號化簡，按鈕）、int（整數部分，按鈕由小到大）

const BankR6 := preload("res://data/levels/num/num6_bank.gd")

const CHAPTERS_R6 := [
	{"ch": 1, "name": "第一章．剝殼", "topic": "雙重根號化簡", "color": UITheme.VIOLET},
	{"ch": 2, "name": "第二章．夾在中間", "topic": "整數部分、小數部分", "color": UITheme.CYAN},
]


func level_id() -> String:
	return "R6"

func level_title() -> String:
	return "剝殼磨坊"

func level_subtitle() -> String:
	return "雙重根號"

func level_chapters() -> Array:
	return CHAPTERS_R6

func bank_slots() -> Array:
	return BankR6.slots()

func step_color() -> Color:
	return UITheme.VIOLET

func chapter_card() -> Dictionary:
	return {"title": "第二章．夾在中間", "button": "出發  ▶",
		"text": "麥殼都剝好了，接下來估一估它有多大：\n\n" \
			+ "・由內往外，一層一層夾在兩個整數之間\n" \
			+ "・先化簡，再找整數部分和小數部分\n" \
			+ "・小數部分 = 原來的數 − 整數部分\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankR6.T_HUSK if String(r.get("gen", "")) == "husk" else BankR6.T_INT


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


static func _is_sq(k: int) -> bool:
	var s := int(roundf(sqrt(float(k))))
	return s * s == k


## √k 化成最簡：8 → 2√2、9 → 3、3 → √3
static func rad(k: int) -> String:
	var c := 1
	var r := k
	var f := 2
	while f * f <= r:
		if r % (f * f) == 0:
			c *= f
			r /= f * f
		else:
			f += 1
	if r == 1:
		return str(c)
	return ("√%d" % r) if c == 1 else ("%d√%d" % [c, r])


## √m ± √n，整數放後面：√5 + 2 寫成 2 + √5 的話不好比，統一寫成「根號在前」
static func _pair_s(m: int, n: int, minus: bool) -> String:
	var a := rad(m)
	var b := rad(n)
	if not minus and _is_sq(m) and not _is_sq(n):
		var tmp := a
		a = b
		b = tmp
	return "%s %s %s" % [a, "−" if minus else "+", b]


## 速算題：
##   husk  √(a ± 2√b)，按鈕三個：答案、面積一樣但長 + 寬不對的另一組、加號題寫成減號／減號題大小顛倒
##   int   √n + k 或 k − √n 的整數部分，按鈕是三個連續整數（由小到大）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		var pb := {}
		if kind == "husk":
			var m := randi_range(2, 12)
			var k := randi_range(1, m - 1)
			var b := m * k
			if _is_sq(b) or (_is_sq(m) and _is_sq(k)):
				continue
			var others := []
			for w in range(1, int(sqrt(float(b))) + 1):
				if b % w == 0 and b / w != m:
					others.append([b / w, w])
			if others.is_empty():
				continue
			var o: Array = others[randi() % others.size()]
			var minus := randf() < 0.5
			var ans := _pair_s(m, k, minus)
			var wrong1 := _pair_s(int(o[0]), int(o[1]), minus)
			var wrong2 := ("%s − %s" % [rad(k), rad(m)]) if minus else _pair_s(m, k, true)
			var opts := [ans, wrong1, wrong2]
			if opts[0] == opts[1] or opts[0] == opts[2] or opts[1] == opts[2]:
				continue
			var order := [0, 1, 2]
			order.shuffle()
			var choices := []
			for i in order:
				choices.append(opts[i])
			pb = {"eq": "√{%d %s 2√%d} = ？" % [m + k, "−" if minus else "+", b], "q": "剝開它", "choices": choices,
				"correct": order.find(0), "tag": BankR6.T_HUSK,
				"nudge": "%d + %d = %d、%d × %d = %d%s。" % [m, k, m + k, m, k, b, "，大的在前" if minus else ""]}
		else:
			var r := randi_range(2, 80)
			if _is_sq(r):
				continue
			var lo := int(floorf(sqrt(float(r))))
			var s := ""
			var ans := 0
			var why := "%d^{2} = %d < %d < %d = %d^{2}" % [lo, lo * lo, r, (lo + 1) * (lo + 1), lo + 1]
			if randf() < 0.5:
				var k := randi_range(1, 6)
				s = "√%d + %d" % [r, k]
				ans = lo + k
				why += "，%d < √%d + %d < %d。" % [lo + k, r, k, lo + k + 1]
			else:
				var k := randi_range(lo + 1, lo + 5)
				s = "%d − √%d" % [k, r]
				ans = k - lo - 1
				why += "，%d < %d − √%d < %d。" % [ans, k, r, ans + 1]
			var start := maxi(0, ans - randi() % 3)
			var choices := []
			for i in 3:
				choices.append(str(start + i))
			pb = {"eq": "%s 的整數部分？" % s, "q": "點一個", "choices": choices, "correct": ans - start,
				"tag": BankR6.T_INT, "nudge": why}
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out
