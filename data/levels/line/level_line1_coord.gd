extends "res://data/levels/line/line_level.gd"
## 直線與圓 第一大關「坐標燈標」（對應講義 3-1 重點一：平面坐標系的概念）
## 引擎是 line_level.gd（推導＋下方的坐標方格、點選格子點），題庫在 line1_bank.gd。
##   ・第一章：中點與距離、分點、平行四邊形的第四頂點、重心、燈距速算
##   ・第二章：斜率、共線、垂直、比斜率大小、角平分線分點、外心、垂心
##   ・背景：清晨的圓規湖岸邊，一排燈標（data/ui/scenery.gd 的 "lakeside"）

const BankC1 := preload("res://data/levels/line/line1_bank.gd")
const LAMP := UITheme.CYAN

const CHAPTERS_C1 := [
	{"ch": 1, "name": "第一章．坐標的基本功", "topic": "中點、距離、分點、平行四邊形、重心", "color": UITheme.CYAN},
	{"ch": 2, "name": "第二章．斜率與三心", "topic": "斜率、共線、垂直、角平分線、外心、垂心", "color": UITheme.GOLD},
]


func level_id() -> String:
	return "C1"

func level_title() -> String:
	return "坐標燈標"

func level_subtitle() -> String:
	return "坐標與斜率"

func level_chapters() -> Array:
	return CHAPTERS_C1

func bank_slots() -> Array:
	return BankC1.slots()

func step_color() -> Color:
	return LAMP

func scene_theme() -> String:
	return "lakeside"

func stage_style() -> Dictionary:
	return {"sky_top": Color("1b2c4a"), "sky_bot": Color("0c1628"), "scenery": "none", "ambient": ""}     # 粒子畫在 Scenery 背景裡

func chapter_card() -> Dictionary:
	return {"title": "第二章．斜率與三心", "button": "走上棧橋  ▶",
		"text": "燈標都點亮了，接下來走上棧橋：\n\n" \
			+ "・斜率：往右走 1 格，往上走幾格\n" \
			+ "・三點共線：斜率一樣，垂直：斜率相乘是 −1\n" \
			+ "・不用算，看圖比斜率的大小\n" \
			+ "・角平分線分點、外心、垂心\n\n" \
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
	return BankC1.T_SLOPE if String(r.get("gen", "")) == "slope" else BankC1.T_MID


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


const TRIPLES := [[3, 4, 5], [6, 8, 10], [5, 12, 13], [8, 15, 17], [9, 12, 15], [12, 5, 13], [4, 3, 5], [8, 6, 10], [12, 9, 15], [15, 8, 17]]


## 速算題：dist（兩點距離，畢氏數）、slope（兩點斜率）。{eq, q, template, ans, nudge, tag}
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 2000:
		guard += 1
		var x1 := randi_range(-6, 6)
		var y1 := randi_range(-6, 6)
		var pb := {}
		if kind == "slope":
			var dx := randi_range(-6, 6)
			var dy := randi_range(-6, 6)
			if dx == 0 or dy == 0:
				continue
			var x2 := x1 + dx
			var y2 := y1 + dy
			var gg := _gcd(absi(dx), absi(dy))
			var nu := dy / gg
			var de := dx / gg
			if de < 0:
				nu = -nu
				de = -de
			var ans := str(nu) if de == 1 else "%d/%d" % [nu, de]
			pb = {"eq": "A%s、B%s\n斜率 m_{AB} = ？" % [_pt(x1, y1), _pt(x2, y2)], "ans": ans, "tag": BankC1.T_SLOPE,
				"q": "算出 A、B 的斜率（可以寫分數）。", "template": "m_{AB} = [0]",
				"nudge": "\\frac{%s − %s}{%s − %s}，記得約分。" % [_n(y2), _wrap(y1), _n(x2), _wrap(x1)]}
		else:
			var tr: Array = TRIPLES[randi() % TRIPLES.size()]
			var sx := 1 if randf() < 0.5 else -1
			var sy := 1 if randf() < 0.5 else -1
			var x2 := x1 + sx * int(tr[0])
			var y2 := y1 + sy * int(tr[1])
			if absi(x2) > 12 or absi(y2) > 12:
				continue
			pb = {"eq": "A%s、B%s\n距離 \\ol{AB} = ？" % [_pt(x1, y1), _pt(x2, y2)], "ans": str(tr[2]), "tag": BankC1.T_MID,
				"q": "算出 \\ol{AB}。", "template": "\\ol{AB} = [0]",
				"nudge": "橫向 %d 格、縱向 %d 格：√(%d^{2} + %d^{2})。" % [tr[0], tr[1], tr[0], tr[1]]}
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out


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
