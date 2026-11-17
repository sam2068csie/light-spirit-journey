extends "res://data/levels/num/num_level.gd"
## 高一「指數與常用對數」第三大關「深谷測繩」（對應講義重點三：科學記號與位數問題）。設計稿：docs/exp_e3_design.md
## 底層是數與式的 num_level.gd（原野、按鈕速算），題庫在 exp3_bank.gd。
##   ・第一章：拖小數點、科學記號審判、有效數字的運算、光走多久、先猜再算、位數審判、速算
##   ・第二章：已知位數反推、測繩比長短、反求 n、加起來有幾位數、位元與地震、速算
##   ・新的圖上元件（num_field.gd）：digits 數字條（拖小數點）、rope 測繩（先猜、跟著滑桿、比長短）
##     尾數尺用 E2 的對數尺（nline 加 "logticks"）＋ ltap
## 速算：digits（幾位數、小數點後第幾位，按鈕）、lead（最高位數字，按鈕）

const BankE3 := preload("res://data/levels/h1exp/exp3_bank.gd")

const CHAPTERS_E3 := [
	{"ch": 1, "name": "第一章．放下測繩", "topic": "科學記號與位數", "color": UITheme.CYAN},
	{"ch": 2, "name": "第二章．谷底的回聲", "topic": "位數的應用", "color": UITheme.ORANGE},
]

## 尾數尺的格線（題目給的近似值算出來的）：LOGD[d] = log d
const LOGD := [0.0, 0.0, 0.301, 0.477, 0.602, 0.699, 0.778, 0.845, 0.903, 0.954, 1.0]


func level_id() -> String:
	return "E3"

func level_title() -> String:
	return "深谷測繩"

func level_subtitle() -> String:
	return "科學記號與位數"

func level_chapters() -> Array:
	return CHAPTERS_E3

func bank_slots() -> Array:
	return BankE3.slots()

func step_color() -> Color:
	return UITheme.CYAN

func scene_theme() -> String:
	return "mine"

func chapter_card() -> Dictionary:
	return {"title": "第二章．谷底的回聲", "button": "出發  ▶",
		"text": "測繩放到谷底了，接著用它解題：\n\n" \
			+ "・知道有幾位數，反推 log\n" \
			+ "・兩條繩子比長短\n" \
			+ "・n 最大可以多大\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankE3.T_DIG if String(r.get("gen", "")) == "digits" else BankE3.T_LEAD


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


## 尾數（兩位小數）：離格線至少 0.02
static func _mant(d: int) -> float:
	var lo: float = LOGD[d] + 0.02
	var hi: float = LOGD[d + 1] - 0.02
	var m := snappedf(randf_range(lo, hi), 0.01)
	return clampf(m, snappedf(lo + 0.005, 0.01), snappedf(hi - 0.005, 0.01))


static func _ms(v: float) -> String:
	return ("%.2f" % v).replace("-", "−")


## 速算題：
##   digits  log x = n.ab ⇒ 幾位數（n + 1、n、n + 2）；log x = −n.ab ⇒ 小數點後第幾位開始不是 0（n + 1、n、n + 2）
##   lead    log x = n.ab ⇒ 最高位數字（d、d + 1、d − 1；d = 1 時 2、3）
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
		var ch := randi_range(2, 15)
		var m := snappedf(randf_range(0.05, 0.95), 0.01)
		if kind == "digits":
			if randi() % 2 == 0:
				var v := ch + m
				pb = {"eq": "log x = %s，x 有幾位數？" % _ms(v), "nudge": "整數部分是 %d：%d + 1 位數。" % [ch, ch]}
				ans = str(ch + 1)
				w1 = str(ch)
				w2 = str(ch + 2)
			else:
				var v := -(ch + m)
				pb = {"eq": "log x = %s，小數點後第幾位不是 0？" % _ms(v), "nudge": "%s = −%d + %s。" % [_ms(v), ch + 1, _ms(1.0 - m)]}
				ans = str(ch + 1)
				w1 = str(ch)
				w2 = str(ch + 2)
			pb["tag"] = BankE3.T_DIG
		else:
			var d := randi_range(1, 9)
			var mm := _mant(d)
			pb = {"eq": "log x = %s，最高位數字？" % _ms(ch + mm), "nudge": "尾數 %s 在 log %d 和 log %d 之間。" % [_ms(mm), d, d + 1]}
			ans = str(d)
			if d == 1:
				w1 = "2"
				w2 = "3"
			elif d == 9:
				w1 = "8"
				w2 = "7"
			else:
				w1 = str(d + 1)
				w2 = str(d - 1)
			pb["tag"] = BankE3.T_LEAD
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
