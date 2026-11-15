extends "res://data/levels/num/num_level.gd"
## 數與式 第三大關「天秤市集」（對應講義重點三：次序不等式）。設計稿：docs/num_r3_design.md
## 底層是 num_level.gd（原野、按鈕速算、背景），題庫在 num3_bank.gd。
##   ・第一章：距離寫成範圍、加和減、四個角（xy、x/y）、跨過 0 的平方、哪些一定成立、速算
##   ・第二章：平方相減、配方看距離、拆成兩個括號、速算
##   ・範圍是數線柵欄上的燈條（num_field.gd 的 bars），學生拖兩個把手拉出範圍（lrange）。相乘、距離在方框上點。
## 速算：rng（x − y、xy 的範圍，按鈕）、sq（x^{2} 的範圍，按鈕）

const BankR3 := preload("res://data/levels/num/num3_bank.gd")

const CHAPTERS_R3 := [
	{"ch": 1, "name": "第一章．亮起來的攤位", "topic": "絕對值寫成範圍、範圍的加減乘除、平方", "color": UITheme.LIME},
	{"ch": 2, "name": "第二章．市集的方框", "topic": "平方相減、配方看距離、拆成兩個括號", "color": UITheme.GOLD},
]


func level_id() -> String:
	return "R3"

func level_title() -> String:
	return "天秤市集"

func level_subtitle() -> String:
	return "次序不等式"

func level_chapters() -> Array:
	return CHAPTERS_R3

func bank_slots() -> Array:
	return BankR3.slots()

func step_color() -> Color:
	return UITheme.LIME

func chapter_card() -> Dictionary:
	return {"title": "第二章．市集的方框", "button": "走進方框  ▶",
		"text": "攤位的燈條都會拉了，接下來是複合的式子：\n\n" \
			+ "・x^{2} − y^{2}：先看兩個平方\n" \
			+ "・配方之後，看離中心最近、最遠的點\n" \
			+ "・拆成兩個括號，兩段燈條相乘\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankR3.T_ADD if String(r.get("gen", "")) == "rng" else BankR3.T_SQ


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


static func _num(v: int) -> String:
	return str(v).replace("-", "−")


static func _rg(lo: int, hi: int, mid: String) -> String:
	return "%s ≤ %s ≤ %s" % [_num(lo), mid, _num(hi)]


## 速算題（按鈕三個，答案的位置隨機）：
##   rng  給 x、y 的整數範圍，問 x − y 或 xy 的範圍。錯的按鈕：端點直接相減（或只看兩端相乘）、加成 x + y（或左右顛倒的組合）
##   sq   給 x 的整數範圍，問 x^{2} 的範圍。錯的按鈕：兩個端點平方、另一種常見錯誤
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		var right := []
		var wrongs := []
		var eq := ""
		var mid := ""
		var nudge := ""
		var tag := BankR3.T_ADD
		if kind == "rng":
			var a := randi_range(-5, 3)
			var b := a + randi_range(2, 5)
			var c := randi_range(-4, 4)
			var d := c + randi_range(1, 4)
			eq = "%s、%s" % [_rg(a, b, "x"), _rg(c, d, "y")]
			if out.size() % 2 == 0:
				mid = "x − y"
				right = [a - d, b - c]
				wrongs = [[mini(a - c, b - d), maxi(a - c, b - d)], [a + c, b + d]]
				nudge = "x − y = x + (−y)：最小 − 最大、最大 − 最小。"
			else:
				mid = "xy"
				tag = BankR3.T_MUL
				var cs := [a * c, a * d, b * c, b * d]
				right = [cs.min(), cs.max()]
				wrongs = [[mini(a * c, b * d), maxi(a * c, b * d)], [mini(a * d, b * c), maxi(a * d, b * c)]]
				nudge = "xy 看四個角：%s。" % "、".join(cs.map(func(v): return _num(v)))
		else:
			tag = BankR3.T_SQ
			var a := randi_range(-6, 3)
			var b := a + randi_range(2, 6)
			if b > 7:
				continue
			eq = _rg(a, b, "x")
			mid = "x^{2}"
			var hi := maxi(a * a, b * b)
			var lo := 0 if a < 0 and b > 0 else mini(a * a, b * b)
			right = [lo, hi]
			if a < 0 and b > 0:
				wrongs = [[mini(a * a, b * b), hi], [0, mini(a * a, b * b)]]
				nudge = "x 跨過 0：x^{2} 最小是 0。"
			else:
				wrongs = [[0, hi], [a, b]]
				nudge = "x 沒有跨過 0：兩個端點平方，小的在左邊。"
		var opts := [right] + wrongs
		var ok := true
		for k in range(1, opts.size()):
			if opts[k] == right or opts[k][0] > opts[k][1]:
				ok = false
			for j in range(1, k):
				if opts[k] == opts[j]:
					ok = false
		if not ok:
			continue
		var order := [0, 1, 2]
		order.shuffle()
		var choices := []
		for k in order:
			choices.append("%s ～ %s" % [_num(int(opts[k][0])), _num(int(opts[k][1]))])
		var pb := {"eq": "%s\n%s 的範圍？" % [eq, mid], "q": "從最小到最大", "choices": choices,
			"correct": order.find(0), "tag": tag, "nudge": nudge}
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out
