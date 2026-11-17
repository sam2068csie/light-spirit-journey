extends "res://data/levels/num/num_level.gd"
## 高一「指數與常用對數」第二大關「十倍石階」（對應講義重點二：常用對數）。設計稿：docs/exp_e2_design.md
## 底層是數與式的 num_level.gd（原野、按鈕速算），題庫在 exp2_bank.gd。
##   ・第一章：數量級階梯、觀念審判、數線上的點、自己發現 log 2、10 的 log 次方、計算尺、首數平移、用 log 比倍數、速算
##   ・第二章：log 2、3、7、夾在哪兩階、範圍審判、分貝計、對數公式、速算
##   ・新的圖上元件（num_field.gd）：nline 加 "stair"（十倍石階）、"logticks"（對數尺）、rule 計算尺、meter 分貝計
## 速算：logs（log 的值與運算，按鈕）、char（log x 夾在哪兩個整數之間，按鈕）

const BankE2 := preload("res://data/levels/h1exp/exp2_bank.gd")

const CHAPTERS_E2 := [
	{"ch": 1, "name": "第一章．十倍石階", "topic": "對數的意義與運算", "color": UITheme.GOLD},
	{"ch": 2, "name": "第二章．分貝與地震", "topic": "對數的範圍與應用", "color": UITheme.ORANGE},
]


func level_id() -> String:
	return "E2"

func level_title() -> String:
	return "十倍石階"

func level_subtitle() -> String:
	return "常用對數"

func level_chapters() -> Array:
	return CHAPTERS_E2

func bank_slots() -> Array:
	return BankE2.slots()

func step_color() -> Color:
	return UITheme.GOLD

func scene_theme() -> String:
	return "steps"

func chapter_card() -> Dictionary:
	return {"title": "第二章．分貝與地震", "button": "出發  ▶",
		"text": "石階都爬過一遍了，接著用石階量世界：\n\n" \
			+ "・log x 夾在哪兩個整數之間\n" \
			+ "・分貝加 10，聲音強度乘 10\n" \
			+ "・地震規模差 1，能量差 10^{1.5} 倍\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankE2.T_DEF if String(r.get("gen", "")) == "logs" else BankE2.T_RANGE


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


static func _shuffle3(ans: String, w1: String, w2: String) -> Dictionary:
	var opts := [ans, w1, w2]
	var order := [0, 1, 2]
	order.shuffle()
	var choices := []
	for i in order:
		choices.append(opts[i])
	return {"choices": choices, "correct": order.find(0)}


static func _m(n: int) -> String:
	return str(n).replace("-", "−")


## 10^{n} 寫成小數或整數（n 從 −4 到 5）
static func _dec(n: int) -> String:
	if n >= 0:
		return "1" + "0".repeat(n)
	return "0." + "0".repeat(-n - 1) + "1"


## 速算題：
##   logs  log 10^{n}（n、n + 1、n − 1）、log 0.0…1（−n、n、−n − 1）、
##         log a + log b，ab = 10^{k}（k、log(a + b)、ab）、10^{log a}（a、log a、10^{a}）、log 10^{a} − log 10^{b}
##   char  log x 在哪兩個整數之間（x 是 3～4 位有效數字的整數，或很小的小數）
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
		if kind == "logs":
			var typ := randi() % 4
			if typ == 0:
				var k := randi_range(2, 5)
				pb = {"eq": "log %s = ？" % _dec(k), "nudge": "%s = 10^{%d}。" % [_dec(k), k]}
				ans = str(k)
				w1 = str(k + 1)
				w2 = str(k - 1)
			elif typ == 1:
				var k := randi_range(1, 4)
				pb = {"eq": "log %s = ？" % _dec(-k), "nudge": "%s = 10^{−%d}。" % [_dec(-k), k]}
				ans = _m(-k)
				w1 = str(k)
				w2 = _m(-k - 1)
			elif typ == 2:
				var pairs := [[2, 5, 1], [4, 25, 2], [20, 5, 2], [8, 125, 3], [50, 2, 2], [25, 40, 3], [4, 250, 3]]
				var p: Array = pairs[randi() % pairs.size()]
				pb = {"eq": "log %d + log %d = ？" % [p[0], p[1]], "nudge": "log %d × %d。" % [p[0], p[1]]}
				ans = str(p[2])
				w1 = "log %d" % (p[0] + p[1])
				w2 = str(p[0] * p[1])
			else:
				var a := randi_range(2, 9)
				pb = {"eq": "10^{log %d} = ？" % a, "nudge": "10^{log a} = a。"}
				ans = str(a)
				w1 = "log %d" % a
				w2 = "10^{%d}" % a
			pb["tag"] = BankE2.T_DEF
		else:
			var k := randi_range(-4, 4)
			var lead := randi_range(1, 9)
			var dig := randi_range(1, 99)
			# x = lead.dig × 10^{k}，寫成一般的數
			var mant := "%d%02d" % [lead, dig]
			var s := ""
			if k >= 2:
				s = mant + "0".repeat(k - 2)
			elif k == 1:
				s = mant.substr(0, 2) + "." + mant.substr(2)
			elif k == 0:
				s = mant.substr(0, 1) + "." + mant.substr(1)
			else:
				s = "0." + "0".repeat(-k - 1) + mant
			s = s.rstrip("0").trim_suffix(".") if s.contains(".") else s
			if s.ends_with(".") or s == "":
				continue
			pb = {"eq": "log %s 在哪兩個整數之間？" % s, "nudge": "%s 在 %s 和 %s 之間。" % [s, _dec(k), _dec(k + 1)]}
			ans = "%s 和 %s" % [_m(k), _m(k + 1)]
			w1 = "%s 和 %s" % [_m(k + 1), _m(k + 2)]
			w2 = "%s 和 %s" % [_m(k - 1), _m(k)]
			pb["tag"] = BankE2.T_RANGE
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
