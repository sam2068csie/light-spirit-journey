extends "res://data/levels/line/line_level.gd"
## 直線與圓 第四大關「分光稻田」（對應講義 3-2 重點三：二元一次不等式）
## 引擎是 line_level.gd（推導＋下方的坐標方格、點選格子點、滑桿、點選區域），題庫在 line4_bank.gd。
##   ・第一章：直線的兩側（代入看正負，回顧第三關）、同側異側求範圍、畫不等式、聯立不等式、由圖寫不等式、點在三角形內部、正負速算
##   ・第二章：由圖反求係數、由面積反求參數、過定點的直線照進區域、最大的圓形水池、格子點應用題、格子點速算
##   ・背景：夜裡發光的稻田，田埂把稻田切成一塊一塊（data/ui/scenery.gd 的 "paddy"）

const BankC4 := preload("res://data/levels/line/line4_bank.gd")
const RICE := UITheme.ORANGE

const CHAPTERS_C4 := [
	{"ch": 1, "name": "第一章．田埂的兩邊", "topic": "代入看正負、畫不等式、聯立不等式、由圖寫不等式", "color": UITheme.ORANGE},
	{"ch": 2, "name": "第二章．稻田的規劃", "topic": "反求係數、面積、斜率範圍、最大的圓、格子點", "color": UITheme.LIME},
]


func level_id() -> String:
	return "C4"

func level_title() -> String:
	return "分光稻田"

func level_subtitle() -> String:
	return "二元一次不等式"

func level_chapters() -> Array:
	return CHAPTERS_C4

func bank_slots() -> Array:
	return BankC4.slots()

func step_color() -> Color:
	return RICE

func scene_theme() -> String:
	return "paddy"

func stage_style() -> Dictionary:
	return {"sky_top": Color("16213a"), "sky_bot": Color("0a1020"), "scenery": "none", "ambient": ""}

func chapter_card() -> Dictionary:
	return {"title": "第二章．稻田的規劃", "button": "規劃稻田  ▶",
		"text": "田埂的兩邊分清楚了，接下來規劃稻田：\n\n" \
			+ "・從圖讀出不等式的係數\n" \
			+ "・田要多大（由面積反求）\n" \
			+ "・燈光照得到田的範圍\n" \
			+ "・最大的圓形水池、市集的買法\n\n" \
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
	return BankC4.T_APP if String(r.get("gen", "")) == "row" else BankC4.T_SIDE


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算題：side（代入 ax + by + c 的值）、row（ax + by ≤ c、x ≥ 1、y 固定：x 有幾個）。{eq, q, template, answers, nudge, tag}
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var pb := {}
		if kind == "row":
			var a := randi_range(2, 6)
			var b := randi_range(2, 7)
			var c := randi_range(4, 9) * a + randi_range(0, a - 1) + b
			var y := randi_range(1, 3)
			var room := c - b * y
			if room < a:
				continue
			var cnt := room / a
			pb = {"eq": "%dx + %dy ≤ %d\nx ≥ 1，y = %d" % [a, b, c, y], "q": "x 可以是幾個正整數？", "template": "共 [0] 個",
				"answers": [str(cnt)], "tag": BankC4.T_APP, "nudge": "y = %d：%dx ≤ %d，x ≤ \\frac{%d}{%d}，取整數部分。" % [y, a, room, room, a]}
		else:
			var a := randi_range(-5, 5)
			var b := randi_range(-5, 5)
			var c := randi_range(-9, 9)
			var x0 := randi_range(-4, 4)
			var y0 := randi_range(-4, 4)
			if a == 0 or b == 0:
				continue
			if a < 0:
				a = -a
				b = -b
				c = -c
			var v := a * x0 + b * y0 + c
			if v == 0:
				continue
			pb = {"eq": "P%s 代入\n%s" % [_pt(x0, y0), lin(a, b, c).replace(" = 0", "")], "q": "算出代入的值。", "template": "[0]",
				"answers": [str(v)], "tag": BankC4.T_SIDE, "nudge": "%d × %s + %s × %s %s。" % [a, _wrap(x0), _wrap(b), _wrap(y0),
					("+ %d" % c) if c > 0 else (("− %d" % -c) if c < 0 else "")]}
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out


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
