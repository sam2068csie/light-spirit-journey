extends "res://data/levels/line/line_level.gd"
## 直線與圓 第八大關「軌跡星環」（對應講義 3-3 重點二：圓系、重點三：軌跡，加上公切線）
## 引擎是 line_level.gd（推導＋下方的坐標方格、點選格子點、滑桿），題庫在 line8_bank.gd。
## 這一關的滑桿會留下足跡：動點走過的地方留下一串光點，連起來就是軌跡。
##   ・第一章：過圓與直線交點的圓（C + kL = 0）、兩圓的公共弦（k = −1）、外公切線、公共弦速算
##   ・第二章：中點、重心（拿掉共線的點）、切線夾 60°、弦中點、阿波羅尼斯圓、軌跡判斷、中點軌跡速算
##   ・背景：長時間曝光的星軌，一顆星星沿著圓走留下足跡（data/ui/scenery.gd 的 "startrail"）
## 使用者 2026/11/07：公切線、圓系放 C8，不收圓冪。

const BankC8 := preload("res://data/levels/line/line8_bank.gd")
const STAR := UITheme.GOOD

const CHAPTERS_C8 := [
	{"ch": 1, "name": "第一章．圓系與兩個圓", "topic": "過交點的圓、公共弦、外公切線", "color": UITheme.GOOD},
	{"ch": 2, "name": "第二章．留下足跡的星", "topic": "中點、重心、夾角、弦中點、兩倍遠、軌跡判斷", "color": UITheme.VIOLET},
]


func level_id() -> String:
	return "C8"

func level_title() -> String:
	return "軌跡星環"

func level_subtitle() -> String:
	return "圓系與軌跡"

func level_chapters() -> Array:
	return CHAPTERS_C8

func bank_slots() -> Array:
	return BankC8.slots()

func step_color() -> Color:
	return STAR

func scene_theme() -> String:
	return "startrail"

func stage_style() -> Dictionary:
	return {"sky_top": Color("0c1530"), "sky_bot": Color("060a18"), "scenery": "none", "ambient": ""}

func chapter_card() -> Dictionary:
	return {"title": "第二章．留下足跡的星", "button": "出發  ▶",
		"text": "兩個圓的關係都看懂了，接下來讓星星動起來：\n\n" \
			+ "・中點、重心走出來的足跡\n" \
			+ "・看星環剛好 60° 的地方\n" \
			+ "・弦中點的足跡、兩倍遠的燈\n" \
			+ "・哪些足跡是完整的圓\n\n" \
			+ "設動點、代進去、整理，最後記得檢查有沒有要拿掉的點！"}


# ================= 速算 =================

func _speed_show() -> void:
	var pb: Dictionary = problems[sp_i]
	fview.show_speed(pb.eq, sp_i, problems.size(), streak)
	step_label.text = UITheme.step_bar(_steps(), 0)
	if sp_i > 0:
		story_label.visible = false
	_build_fill({"name": "速算", "q": pb.q, "template": pb.template, "answers": pb.answers, "alts": pb.get("alts", []),
		"mode": pb.get("mode", "ordered"), "nudge": pb.nudge, "tag": pb.tag, "line": "", "paren": true})


func _speed_tag() -> String:
	return BankC8.T_FAM


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算題：chord（兩圓的公共弦）、mid（中點的軌跡）。{eq, q, template, answers, alts, nudge, tag}
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 5000:
		guard += 1
		var pb := {}
		if kind == "mid":
			var h := randi_range(-3, 3)
			var k := randi_range(-3, 3)
			var a := randi_range(-4, 4)
			var b := randi_range(-4, 4)
			if (h + a) % 2 != 0 or (k + b) % 2 != 0:
				continue
			var r := 2 * randi_range(1, 3)
			if (a - h) * (a - h) + (b - k) * (b - k) <= r * r:
				continue      # A 在圓外，圖比較好想
			pb = {"eq": "A%s，P 在 %s 上走" % [_pt(a, b), _circle(h, k, r * r)], "q": "\\ol{AP} 的中點，軌跡的圓心和半徑？",
				"template": "圓心 ([0], [1])，半徑 [2]", "answers": [str((h + a) / 2), str((k + b) / 2), str(r / 2)],
				"tag": BankC8.T_LOC, "nudge": "圓心是 A 和圓心的中點，半徑是 \\frac{r}{2}。"}
		else:
			var h1 := randi_range(-3, 3)
			var k1 := randi_range(-3, 3)
			var h2 := randi_range(-3, 3)
			var k2 := randi_range(-3, 3)
			if h1 == h2 and k1 == k2:
				continue
			var q1 := randi_range(2, 25)
			var q2 := randi_range(2, 25)
			var d2 := (h1 - h2) * (h1 - h2) + (k1 - k2) * (k1 - k2)
			var r1 := sqrt(float(q1))
			var r2 := sqrt(float(q2))
			if not (float(d2) < pow(r1 + r2, 2) - 0.5 and float(d2) > pow(r1 - r2, 2) + 0.5):
				continue      # 兩圓要交於兩點
			var a := 2 * (h2 - h1)
			var b := 2 * (k2 - k1)
			var c := (h1 * h1 + k1 * k1 - q1) - (h2 * h2 + k2 * k2 - q2)
			var g := _gcd(_gcd(absi(a), absi(b)), absi(c))
			a /= g
			b /= g
			c /= g
			if a < 0 or (a == 0 and b < 0):
				a = -a
				b = -b
				c = -c
			if a == 0 or b == 0 or absi(a) > 6 or absi(b) > 6 or absi(c) > 20:
				continue
			pb = {"eq": "%s\n%s" % [_general(h1, k1, q1), _general(h2, k2, q2)], "q": "兩式相減，寫出公共弦所在的直線。",
				"template": "[0]x + [1]y = [2]", "answers": [str(a), str(b), str(-c)], "mode": "prop",
				"tag": BankC8.T_FAM, "nudge": "上式減下式，x^{2}、y^{2} 消掉，再約分。"}
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return maxi(a, 1)


## 一般式 x^{2} + y^{2} + Dx + Ey + F = 0
static func _general(h: int, k: int, q: int) -> String:
	var s := "x^{2} + y^{2}"
	s += _tm(-2 * h, "x") + _tm(-2 * k, "y") + _tm(h * h + k * k - q, "")
	return s + " = 0"


static func _tm(v: int, x: String) -> String:
	if v == 0:
		return ""
	var mag := str(absi(v)) if absi(v) != 1 or x == "" else ""
	return (" + " if v > 0 else " − ") + mag + x


## (x − h)^{2} + (y − k)^{2} = r²（圓心是 0 的寫成 x^{2}）
static func _circle(h: int, k: int, r2: int) -> String:
	return "%s + %s = %d" % [_sq("x", h), _sq("y", k), r2]


static func _sq(x: String, h: int) -> String:
	if h == 0:
		return x + "^{2}"
	return "(%s %s %d)^{2}" % [x, "−" if h > 0 else "+", absi(h)]


static func _n(v: int) -> String:
	return ("−" if v < 0 else "") + str(absi(v))


static func _pt(x: int, y: int) -> String:
	return "(%s, %s)" % [_n(x), _n(y)]
