extends "res://data/levels/num/num_level.gd"
## 數與式 第二大關「繩上珠子」（對應講義重點二：分點公式）。設計稿：docs/num_r2_design.md
## 底層是 num_level.gd（原野、按鈕速算、背景），題庫在 num2_bank.gd。
##   ・第一章：內分點公式（拖珠子）、兩個位置（內分、外分）、縮小畫在數線上、追趕、速算
##   ・第二章：p|x − a| = q|x − b| 的判斷、加權平均的位置、根號的分點、速算
##   ・數線柵欄上的繩子和珠子、砝碼、跑者、縮小地圖都在 num_field.gd
## 速算：bead（內分點、外分點的坐標，填數字）、where（分點靠近 a、靠近 b、在外面，按鈕）

const BankR2 := preload("res://data/levels/num/num2_bank.gd")

const CHAPTERS_R2 := [
	{"ch": 1, "name": "第一章．穿上繩子的珠子", "topic": "內分點、外分點、縮小比例、追趕", "color": UITheme.CYAN},
	{"ch": 2, "name": "第二章．珠子的排隊", "topic": "分點的判斷、加權平均和根號的分點比大小", "color": UITheme.GOLD},
]


func level_id() -> String:
	return "R2"

func level_title() -> String:
	return "繩上珠子"

func level_subtitle() -> String:
	return "分點公式"

func level_chapters() -> Array:
	return CHAPTERS_R2

func bank_slots() -> Array:
	return BankR2.slots()

func step_color() -> Color:
	return UITheme.CYAN

func chapter_card() -> Dictionary:
	return {"title": "第二章．珠子的排隊", "button": "排排看  ▶",
		"text": "珠子都串上繩子了，接下來比比看誰在前面：\n\n" \
			+ "・滿足條件的珠子有幾顆、在哪裡\n" \
			+ "・加權平均靠近哪一端\n" \
			+ "・根號的分點，不用算小數也能排\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankR2.T_DIV if String(r.get("gen", "")) == "bead" else BankR2.T_DCMP


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


static func _num(v: int) -> String:
	return str(v).replace("-", "−")


## 「3a + 2b」：係數 1 不寫
static func _term(k: int, v: String) -> String:
	return v if k == 1 else "%d%s" % [k, v]


## 速算題：bead（填分點的坐標）、where（按鈕：靠近 a、靠近 b、在外面）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		var pb := {}
		var m := randi_range(1, 4)
		var k := randi_range(1, 4)
		if m == k or _gcd(m, k) != 1:
			continue
		if kind == "bead":
			var a := randi_range(-10, 6)
			var b := a + randi_range(3, 14)
			var ext := out.size() % 3 == 2      # 三題裡有一題是外分點
			var num := (m * b - k * a) if ext else (k * a + m * b)
			var den := (m - k) if ext else (m + k)
			if num % den != 0:
				continue
			var p := num / den
			if absi(p) > 40:
				continue
			pb = {"eq": "A(%s)、B(%s)，P 在 \\ol{AB} %s，\\ol{AP} : \\ol{PB} = %d : %d\nP = ？" % [_num(a), _num(b), "外面" if ext else "上", m, k],
				"q": "外分點 \\frac{mb − na}{m − n}。" if ext else "內分點 \\frac{na + mb}{m + n}。", "template": "P = [0]",
				"answers": [str(p)], "tag": BankR2.T_EXT if ext else BankR2.T_DIV,
				"nudge": ("P = \\frac{%d × %s − %d × %s}{%d − %d}。" % [m, _paren(b), k, _paren(a), m, k]) if ext \
					else ("P = \\frac{%d × %s + %d × %s}{%d}。" % [k, _paren(a), m, _paren(b), m + k])}
		else:
			# a < b。內分點 \frac{ma + kb}{m + k}：m > k 靠近 a、m < k 靠近 b。外分點 \frac{mb − ka}{m − k}（m > k）在外面
			var outside := randf() < 0.3
			var expr := ""
			var ans := 0
			if outside:
				var big := maxi(m, k)
				var small := mini(m, k)
				var top := ("%s − %s" % [_term(big, "b"), _term(small, "a"))) if randf() < 0.5 else ("%s − %s" % [_term(big, "a"), _term(small, "b")])
				expr = top if big - small == 1 else "\\frac{%s}{%d}" % [top, big - small]
				ans = 2
			else:
				expr = "\\frac{%s + %s}{%d}" % [_term(m, "a"), _term(k, "b"), m + k]
				ans = 0 if m > k else 1
			pb = {"eq": "a < b\n%s 在哪裡？" % expr, "q": "看權重：係數大的那一端比較近，有負的就在外面。",
				"choices": ["靠近 a", "靠近 b", "在外面"], "correct": ans, "tag": BankR2.T_DCMP,
				"nudge": "\\frac{ma + nb}{m + n}：m > n 靠近 a、m < n 靠近 b。係數有負的，就在 a、b 外面。"}
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out


static func _paren(v: int) -> String:
	return "(%s)" % _num(v) if v < 0 else str(v)
