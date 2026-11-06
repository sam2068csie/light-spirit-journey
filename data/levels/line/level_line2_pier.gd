extends "res://data/levels/line/line_level.gd"
## 直線與圓 第二大關「直線棧橋」（對應講義 3-1 重點二：直線方程式）
## 引擎是 line_level.gd（推導＋下方的坐標方格、點選格子點、滑桿調參數），題庫在 line2_bank.gd。
##   ・第一章：點斜式、兩點式、斜截式（滑桿）、一般式、截距式、斜率速算
##   ・第二章：平行與垂直、平移、解的個數（滑桿）、三線圍三角形、恆過定點與斜率範圍（滑桿）、不過第三象限、速算
##   ・背景：黃昏的湖面上，一座座木棧橋（data/ui/scenery.gd 的 "pier"）

const BankC2 := preload("res://data/levels/line/line2_bank.gd")
const PLANK := UITheme.GOLD

const CHAPTERS_C2 := [
	{"ch": 1, "name": "第一章．直線的五種寫法", "topic": "點斜式、兩點式、斜截式、一般式、截距式", "color": UITheme.GOLD},
	{"ch": 2, "name": "第二章．直線之間的關係", "topic": "平行、垂直、平移、解的個數、定點、象限", "color": UITheme.ORANGE},
]


func level_id() -> String:
	return "C2"

func level_title() -> String:
	return "直線棧橋"

func level_subtitle() -> String:
	return "直線方程式"

func level_chapters() -> Array:
	return CHAPTERS_C2

func bank_slots() -> Array:
	return BankC2.slots()

func step_color() -> Color:
	return PLANK

func scene_theme() -> String:
	return "pier"

func stage_style() -> Dictionary:
	return {"sky_top": Color("2a2240"), "sky_bot": Color("120f22"), "scenery": "none", "ambient": ""}

func chapter_card() -> Dictionary:
	return {"title": "第二章．直線之間的關係", "button": "走上棧橋  ▶",
		"text": "每一座棧橋都寫得出方程式了，接下來看橋和橋之間的關係：\n\n" \
			+ "・平行、垂直的棧橋怎麼寫\n" \
			+ "・整座棧橋搬家（平移）\n" \
			+ "・兩座棧橋會不會相遇（解的個數）\n" \
			+ "・三座棧橋圍不圍得出湖心島\n" \
			+ "・繞著燈柱轉、繞過沼澤的棧橋\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_show() -> void:
	var pb: Dictionary = problems[sp_i]
	fview.show_speed(pb.eq, sp_i, problems.size(), streak)
	step_label.text = UITheme.step_bar(_steps(), 0)
	if sp_i > 0:
		story_label.visible = false
	_build_fill({"name": "速算", "q": pb.q, "template": pb.template, "answers": [pb.ans], "mode": "ordered",
		"nudge": pb.nudge, "tag": pb.tag, "line": ""})


func _speed_tag() -> String:
	return BankC2.T_REL if String(r.get("gen", "")) == "parperp" else BankC2.T_SLOPE


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算題：gslope（一般式 → 斜率）、parperp（過 P 且和 L 平行／垂直：ax + by = k 的 k）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var a := randi_range(-6, 6)
		var b := randi_range(-6, 6)
		var c := randi_range(-9, 9)
		if a == 0 or b == 0:
			continue
		# x 的係數寫成正的（習慣的寫法）
		if a < 0:
			a = -a
			b = -b
			c = -c
		var g := _gcd(_gcd(absi(a), absi(b)), absi(c)) if c != 0 else _gcd(absi(a), absi(b))
		if g > 1:
			continue
		var pb := {}
		if kind == "parperp":
			var px := randi_range(-4, 4)
			var py := randi_range(-4, 4)
			var perp := randf() < 0.5
			# 平行：ax + by = k，垂直：bx − ay = k（x 的係數寫成正的）
			var gab := _gcd(absi(a), absi(b))
			var ca := a / gab
			var cb := b / gab
			if perp:
				ca = b / gab
				cb = -a / gab
				if ca < 0:
					ca = -ca
					cb = -cb
			var k := ca * px + cb * py
			pb = {"eq": "L：%s\nP%s" % [lin(a, b, c), _pt(px, py)],
				"q": "過 P 且和 L %s的直線。" % ("垂直" if perp else "平行"),
				"template": "%s = [0]" % lin(ca, cb, 0, false), "ans": str(k), "tag": BankC2.T_REL,
				"nudge": "%s：%s = k，代入 P%s。" % ["垂直：係數對調、其中一個變號" if perp else "平行：係數照抄", lin(ca, cb, 0, false), _pt(px, py)]}
		else:
			var nu := -a
			var de := b
			var gg := _gcd(absi(nu), absi(de))
			nu /= gg
			de /= gg
			if de < 0:
				nu = -nu
				de = -de
			var ans := str(nu) if de == 1 else "%d/%d" % [nu, de]
			pb = {"eq": "%s\n斜率 m = ？" % lin(a, b, c), "q": "算出斜率（可以寫分數）。", "template": "m = [0]", "ans": ans,
				"tag": BankC2.T_SLOPE, "nudge": "斜率 = −\\frac{a}{b} = −\\frac{%d}{%s}，記得約分。" % [a, _wrap(b)]}
		var key := String(pb.eq) + String(pb.get("q", ""))
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out


## ax + by + c = 0 的寫法（係數 1 不寫、負號用 −）；with_zero = false 時不寫「+ c = 0」
static func lin(a: int, b: int, c: int, with_zero := true) -> String:
	var s := _term(a, "x", true) + _term(b, "y", false)
	if with_zero:
		if c != 0:
			s += (" + " if c > 0 else " − ") + str(absi(c))
		s += " = 0"
	return s


static func _term(v: int, x: String, first: bool) -> String:
	if v == 0:
		return ""
	var mag := "" if absi(v) == 1 else str(absi(v))
	if first:
		return ("−" if v < 0 else "") + mag + x
	return (" + " if v > 0 else " − ") + mag + x


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t2 := a % b
		a = b
		b = t2
	return maxi(a, 1)


static func _n(v: int) -> String:
	return ("−" if v < 0 else "") + str(absi(v))


static func _wrap(v: int) -> String:
	return "(−%d)" % absi(v) if v < 0 else str(v)


static func _pt(x: int, y: int) -> String:
	return "(%s, %s)" % [_n(x), _n(y)]
