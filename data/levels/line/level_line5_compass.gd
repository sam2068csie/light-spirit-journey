extends "res://data/levels/line/line_level.gd"
## 直線與圓 第五大關「圓規工坊」（對應講義 3-3 重點一：圓方程式）
## 引擎是 line_level.gd（推導＋下方的坐標方格、點選格子點、點出所有格子點、滑桿——這一關多了圓規），題庫在 line5_bank.gd。
##   ・第一章：標準式、一般式配方、圓的條件（圓會縮成一點、消失）、直徑式、點與圓、圓上的格子點、配方速算
##   ・第二章：三點求圓、圓心在直線上、和直線相切、和兩軸相切（兩個圓）、拱門、恰可決定一圓、直徑速算
##   ・背景：月光下的圓規工坊，大圓規在地上畫出發光的圓（data/ui/scenery.gd 的 "workshop"）

const BankC5 := preload("res://data/levels/line/line5_bank.gd")
const BRASS := UITheme.VIOLET

const CHAPTERS_C5 := [
	{"ch": 1, "name": "第一章．讀懂圓的方程式", "topic": "標準式、一般式、圓的條件、直徑式、點與圓", "color": UITheme.VIOLET},
	{"ch": 2, "name": "第二章．打造指定的圓", "topic": "三點求圓、圓心在直線上、相切、兩軸相切、拱門", "color": UITheme.PINK},
]


func level_id() -> String:
	return "C5"

func level_title() -> String:
	return "圓規工坊"

func level_subtitle() -> String:
	return "圓方程式與求圓"

func level_chapters() -> Array:
	return CHAPTERS_C5

func bank_slots() -> Array:
	return BankC5.slots()

func step_color() -> Color:
	return BRASS

func scene_theme() -> String:
	return "workshop"

func stage_style() -> Dictionary:
	return {"sky_top": Color("1d1830"), "sky_bot": Color("0d0b18"), "scenery": "none", "ambient": ""}

func chapter_card() -> Dictionary:
	return {"title": "第二章．打造指定的圓", "button": "開工  ▶",
		"text": "圓的方程式都讀得懂了，接下來照訂單打造圓：\n\n" \
			+ "・穿過三根釘子的圓\n" \
			+ "・圓心在軌道上、剛好碰到牆的圓\n" \
			+ "・卡在牆角的圓（有兩個！）\n" \
			+ "・圓弧拱門、訂單夠不夠清楚\n\n" \
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
	return BankC5.T_STD


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


const VECS := [[3, 4], [4, 3], [0, 5], [5, 0], [0, 3], [3, 0], [0, 2], [2, 0], [4, 0], [0, 4], [1, 0], [0, 1]]


## 速算題：complete（一般式 → 圓心、半徑）、diam（直徑兩端 → 圓心、半徑）。{eq, q, template, answers, nudge, tag}
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var h := randi_range(-5, 5)
		var k := randi_range(-5, 5)
		var pb := {}
		if kind == "diam":
			var v: Array = VECS[randi() % VECS.size()]
			var sx := 1 if randf() < 0.5 else -1
			var sy := 1 if randf() < 0.5 else -1
			var vx := int(v[0]) * sx
			var vy := int(v[1]) * sy
			var r := int(round(sqrt(vx * vx + vy * vy)))
			pb = {"eq": "直徑兩端 A%s、B%s" % [_pt(h - vx, k - vy), _pt(h + vx, k + vy)], "q": "寫出圓心和半徑。",
				"template": "圓心 ([0], [1])，r = [2]", "answers": [str(h), str(k), str(r)], "tag": BankC5.T_STD,
				"nudge": "圓心是中點，r 是 \\ol{AB} 的一半。"}
		else:
			var r := randi_range(1, 6)
			var D := -2 * h
			var E := -2 * k
			var F := h * h + k * k - r * r
			pb = {"eq": "x^{2} + y^{2}%s%s%s = 0" % [_tm(D, "x"), _tm(E, "y"), _tm(F, "")], "q": "配方，寫出圓心和半徑。",
				"template": "圓心 ([0], [1])，r = [2]", "answers": [str(h), str(k), str(r)], "tag": BankC5.T_STD,
				"nudge": "圓心 (−\\frac{D}{2}, −\\frac{E}{2})，r^{2} = (\\frac{D}{2})^{2} + (\\frac{E}{2})^{2} − F。"}
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out


## 「 + 3x」「 − y」這種項（係數 0 不寫）
static func _tm(v: int, x: String) -> String:
	if v == 0:
		return ""
	var mag := str(absi(v)) if absi(v) != 1 or x == "" else ""
	return (" + " if v > 0 else " − ") + mag + x


static func lin(a: int, b: int, c: int) -> String:
	var s := _term(a, "x", true) + _term(b, "y", false)
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


static func _wrap(v: int) -> String:
	return "(−%d)" % absi(v) if v < 0 else str(v)


static func _pt(x: int, y: int) -> String:
	return "(%s, %s)" % [_n(x), _n(y)]
