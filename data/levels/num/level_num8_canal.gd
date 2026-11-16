extends "res://data/levels/num/num_level.gd"
## 數與式 第八大關「谷底水渠」（對應講義重點八：數線上的幾何）。設計稿：docs/num_r8_design.md
## 底層是 num_level.gd（原野、按鈕速算、背景），題庫在 num8_bank.gd。
##   ・第一章：柵欄的範圍、相同的解、絕對值的絕對值、標準值上下 10％、反寫成絕對值、反寫 ≥、兩段柵欄的交集、
##            整數解的個數、反寫雙不等式、兩邊平方、速算
##   ・第二章：分段討論、兩個絕對值、交通費、相異的四點、分段解不等式、中位數、有係數的中位數、水渠的底（滑桿數交點）、
##            分段畫圖、三角不等式、整數的絕對值、速算
## 速算：fence（絕對值和範圍互換，按鈕）、canal（距離和的最小值，按鈕）

const BankR8 := preload("res://data/levels/num/num8_bank.gd")

const CHAPTERS_R8 := [
	{"ch": 1, "name": "第一章．柵欄", "topic": "絕對值就是距離", "color": UITheme.CYAN},
	{"ch": 2, "name": "第二章．水渠", "topic": "分段討論與三角不等式", "color": UITheme.MINT},
]


func level_id() -> String:
	return "R8"

func level_title() -> String:
	return "谷底水渠"

func level_subtitle() -> String:
	return "數線上的幾何"

func level_chapters() -> Array:
	return CHAPTERS_R8

func bank_slots() -> Array:
	return BankR8.slots()

func step_color() -> Color:
	return UITheme.CYAN

func chapter_card() -> Dictionary:
	return {"title": "第二章．水渠", "button": "出發  ▶",
		"text": "柵欄都量好了，接下來順著水渠走：\n\n" \
			+ "・轉折點把數線切成幾段，一段一段解\n" \
			+ "・算出來的解要在那一段裡才算\n" \
			+ "・距離加起來，站在中間那根柱子最少\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankR8.T_DIST if String(r.get("gen", "")) == "fence" else BankR8.T_MED


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


static func _sg(v: int) -> String:
	return ("−%d" % -v) if v < 0 else str(v)


## |x − a| 寫成「|x − 3|」「|x + 2|」「|x|」
static func _ab(a: int) -> String:
	if a == 0:
		return "|x|"
	return "|x − %d|" % a if a > 0 else "|x + %d|" % -a


static func _shuffle3(ans: String, w1: String, w2: String) -> Dictionary:
	var opts := [ans, w1, w2]
	var order := [0, 1, 2]
	order.shuffle()
	var choices := []
	for i in order:
		choices.append(opts[i])
	return {"choices": choices, "correct": order.find(0)}


## 速算題：
##   fence  |x − a| ≤ b 的範圍（按鈕：a − b ≤ x ≤ a + b、−b ≤ x ≤ b 平移錯、b − a ≤ x ≤ a + b），
##          或 m ≤ x ≤ n 寫成絕對值（按鈕：|x − 中點| ≤ 半長、|x − 中點| ≤ 全長、|x + 中點| ≤ 半長）
##   canal  |x − a| + |x − b| 的最小值（按鈕：|a − b|、|a + b|、0），三根柱子的最小值（按鈕：最右 − 最左、兩倍、中間那根）
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
		if kind == "fence":
			if randf() < 0.5:
				var a := randi_range(-5, 5)
				var b := randi_range(1, 6)
				if a == 0:
					continue
				pb = {"eq": "%s ≤ %d 的範圍？" % [_ab(a), b], "nudge": "中心 %s，往兩邊各走 %d。" % [_sg(a), b]}
				ans = "%s ≤ x ≤ %s" % [_sg(a - b), _sg(a + b)]
				w1 = "%s ≤ x ≤ %s" % [_sg(-a - b), _sg(-a + b)]
				w2 = "%s ≤ x ≤ %s" % [_sg(-b), _sg(b)]
			else:
				var m := randi_range(-6, 4)
				var len2 := randi_range(1, 4) * 2
				var c := m + len2 / 2
				if c == 0:
					continue
				pb = {"eq": "%s ≤ x ≤ %s 寫成絕對值？" % [_sg(m), _sg(m + len2)], "nudge": "中點 %s、半長 %d。" % [_sg(c), len2 / 2]}
				ans = "%s ≤ %d" % [_ab(c), len2 / 2]
				w1 = "%s ≤ %d" % [_ab(c), len2]
				w2 = "%s ≤ %d" % [_ab(-c), len2 / 2]
			pb["tag"] = BankR8.T_DIST
		else:
			if randf() < 0.5:
				var a := randi_range(-6, 6)
				var b := randi_range(-6, 6)
				if a == b or a + b == 0 or absi(a - b) == absi(a + b):
					continue
				pb = {"eq": "%s + %s 的最小值？" % [_ab(a), _ab(b)], "nudge": "x 在 %s 和 %s 之間：%d。" % [_sg(mini(a, b)), _sg(maxi(a, b)), absi(a - b)]}
				ans = str(absi(a - b))
				w1 = str(absi(a + b))
				w2 = "0"
			else:
				var p := randi_range(-5, 2)
				var q := p + randi_range(1, 4)
				var r := q + randi_range(1, 4)
				pb = {"eq": "%s + %s + %s 的最小值？" % [_ab(p), _ab(q), _ab(r)], "nudge": "站在中間那根 %s：%d。" % [_sg(q), r - p]}
				ans = str(r - p)
				w1 = str(2 * (r - p))
				w2 = str(absi(q))
			pb["tag"] = BankR8.T_MED
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
