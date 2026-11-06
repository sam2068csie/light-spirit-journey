extends "res://data/levels/line/line_level.gd"
## 直線與圓 第六大關「割弦漣漪」（對應講義 3-3 重點四：圓與直線的相交情況，加上半圓問題）
## 引擎是 line_level.gd（推導＋下方的坐標方格、點選格子點、點出所有格子點、滑桿），題庫在 line6_bank.gd。
## 這一關的坐標方格都有交點漣漪：直線碰到圓的地方濺起水花，滑桿的讀數會顯示交點個數。
##   ・第一章：d 和 r 比（相割、相切、相離）、相離求範圍、到直線等距的點、弦長和弦的中點、交點速算
##   ・第二章：已知弦長求直線、已知弦的中點、過圓內一點的最長最短弦、最近最遠和面積、半圓與直線、弦長速算
##   ・背景：夜裡的圓形湖，一道光掃過水面濺起漣漪（data/ui/scenery.gd 的 "ripple"）
## 不用判別式（使用者 2026/11/07 決定），一律用 d 和 r 比。

const BankC6 := preload("res://data/levels/line/line6_bank.gd")
const WATER := UITheme.BLUE

const CHAPTERS_C6 := [
	{"ch": 1, "name": "第一章．直線和圓的三種關係", "topic": "相割、相切、相離、等距的點、弦長、弦的中點", "color": UITheme.BLUE},
	{"ch": 2, "name": "第二章．弦與距離的應用", "topic": "已知弦長、已知中點、最長最短的弦、最近最遠、半圓", "color": UITheme.CYAN},
]


func level_id() -> String:
	return "C6"

func level_title() -> String:
	return "割弦漣漪"

func level_subtitle() -> String:
	return "圓與直線"

func level_chapters() -> Array:
	return CHAPTERS_C6

func bank_slots() -> Array:
	return BankC6.slots()

func step_color() -> Color:
	return WATER

func scene_theme() -> String:
	return "ripple"

func stage_style() -> Dictionary:
	return {"sky_top": Color("0f1a33"), "sky_bot": Color("070c1a"), "scenery": "none", "ambient": ""}

func chapter_card() -> Dictionary:
	return {"title": "第二章．弦與距離的應用", "button": "出發  ▶",
		"text": "光線和湖面的三種關係都會判斷了，接下來用弦和距離解問題：\n\n" \
			+ "・要割出多長的弦\n" \
			+ "・只知道弦的正中間\n" \
			+ "・繞著燈柱轉的光：最長、最短\n" \
			+ "・離岸最遠的燈、半圓形的拱橋\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_show() -> void:
	var pb: Dictionary = problems[sp_i]
	fview.show_speed(pb.eq, sp_i, problems.size(), streak)
	step_label.text = UITheme.step_bar(_steps(), 0)
	if sp_i > 0:
		story_label.visible = false
	_build_fill({"name": "速算", "q": pb.q, "template": pb.template, "answers": pb.answers, "mode": "ordered",
		"nudge": pb.nudge, "tag": pb.tag, "line": "", "paren": true})


func _speed_tag() -> String:
	return BankC6.T_REL


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 法向量（長度是整數）：[a, b, √(a² + b²)]
const NORMALS := [[3, 4, 5], [4, 3, 5], [1, 0, 1], [0, 1, 1]]
## 弦長是整數的 (r, d)
const CHORDS := [[5, 3], [5, 4], [10, 6], [10, 8], [13, 5], [13, 12]]


## 速算題：count（交點個數）、chord（弦長）。{eq, q, template, answers, nudge, tag}
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	var want := 0          # count：0、1、2 個輪流出現
	while out.size() < n and guard < 3000:
		guard += 1
		var h := randi_range(-3, 3)
		var k := randi_range(-3, 3)
		var nv: Array = NORMALS[randi() % NORMALS.size()]
		var a := int(nv[0]) * (1 if randf() < 0.5 else -1)
		var b := int(nv[1]) * (1 if randf() < 0.5 else -1)
		var nl := int(nv[2])
		var side := 1 if randf() < 0.5 else -1
		var pb := {}
		if kind == "chord":
			var rd: Array = CHORDS[randi() % CHORDS.size()]
			var r := int(rd[0])
			var d := int(rd[1])
			var c := side * d * nl - a * h - b * k
			pb = {"eq": "%s 和 %s" % [_circle(h, k, r), lin(a, b, c)], "q": "算出弦心距 d(K, L) 和弦長。",
				"template": "d(K, L) = [0]，弦長 = [1]", "answers": [str(d), str(2 * int(round(sqrt(r * r - d * d))))],
				"tag": BankC6.T_CHORD, "nudge": "弦長 = 2√(r^{2} − d(K, L)^{2})。"}
		else:
			var r := randi_range(2, 5)
			var d := r
			# want = 0：d > r（相離）、want = 1：d = r（相切）、want = 2：d < r（相割）
			if want == 0:
				d = r + randi_range(1, 2)
			elif want == 2:
				d = r - randi_range(1, mini(2, r))
			var c := side * d * nl - a * h - b * k
			pb = {"eq": "%s 和 %s" % [_circle(h, k, r), lin(a, b, c)], "q": "d(K, L) 和半徑 r 比，有幾個交點？",
				"template": "d(K, L) = [0]，交點 [1] 個", "answers": [str(d), str(want)], "tag": BankC6.T_REL,
				"nudge": "d(K, L) 小於 r 兩個、等於 r 一個、大於 r 零個。"}
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
		want = (want + 1) % 3
	if kind == "count":
		out.shuffle()
	return out


## (x − h)^{2} + (y − k)^{2} = r^{2}（圓心是 0 的寫成 x^{2}）
static func _circle(h: int, k: int, r: int) -> String:
	return "%s + %s = %d" % [_sq("x", h), _sq("y", k), r * r]


static func _sq(x: String, h: int) -> String:
	if h == 0:
		return x + "^{2}"
	return "(%s %s %d)^{2}" % [x, "−" if h > 0 else "+", absi(h)]


## ax + by + c = 0（第一個係數寫成正的）
static func lin(a: int, b: int, c: int) -> String:
	if a < 0 or (a == 0 and b < 0):
		a = -a
		b = -b
		c = -c
	var s := _term(a, "x", true) + _term(b, "y", a == 0)
	if c != 0:
		s += (" + " if c > 0 else " − ") + str(absi(c))
	return s + " = 0"


static func _term(v: int, x: String, first: bool) -> String:
	if v == 0:
		return ""
	var mag := "" if absi(v) == 1 else str(absi(v))
	if first:
		return ("−" if v < 0 else "") + mag + x
	return (" + " if v > 0 else " − ") + mag + x


static func _n(v: int) -> String:
	return ("−" if v < 0 else "") + str(absi(v))


static func _pt(x: int, y: int) -> String:
	return "(%s, %s)" % [_n(x), _n(y)]
