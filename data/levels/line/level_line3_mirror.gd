extends "res://data/levels/line/line_level.gd"
## 直線與圓 第三大關「鏡面渡口」（對應講義 3-1 對稱、反射、極值，3-2 距離、角平分線）
## 引擎是 line_level.gd（推導＋下方的坐標方格、點選格子點、滑桿：直線或點跟著動），題庫在 line3_bank.gd。
##   ・第一章：中垂線、對稱點與投影點、摺紙、光的反射（含撞球兩次反射）、最短路徑、差的最大值、對稱點速算
##   ・第二章：點到直線距離、最近的點、過定點且距離固定的直線、平行線距離、距離比 = 分割比、角平分線、內心、距離速算
##   ・背景：月夜的鏡湖，月亮和燈塔倒映在水裡（data/ui/scenery.gd 的 "moonlake"）

const BankC3 := preload("res://data/levels/line/line3_bank.gd")
const MOON := UITheme.LIME

const CHAPTERS_C3 := [
	{"ch": 1, "name": "第一章．鏡子裡的點", "topic": "中垂線、對稱點、摺紙、反射、最短路徑", "color": UITheme.LIME},
	{"ch": 2, "name": "第二章．渡口的距離", "topic": "點到直線、平行線距離、距離比、角平分線、內心", "color": UITheme.CYAN},
]


func level_id() -> String:
	return "C3"

func level_title() -> String:
	return "鏡面渡口"

func level_subtitle() -> String:
	return "對稱與距離"

func level_chapters() -> Array:
	return CHAPTERS_C3

func bank_slots() -> Array:
	return BankC3.slots()

func step_color() -> Color:
	return MOON

func scene_theme() -> String:
	return "moonlake"

func stage_style() -> Dictionary:
	return {"sky_top": Color("101a33"), "sky_bot": Color("070b18"), "scenery": "none", "ambient": ""}

func chapter_card() -> Dictionary:
	return {"title": "第二章．渡口的距離", "button": "量量看  ▶",
		"text": "鏡子裡的點都找到了，接下來量距離：\n\n" \
			+ "・燈塔到航道的距離\n" \
			+ "・航道上離渡口最近的點\n" \
			+ "・兩條平行航道有多寬\n" \
			+ "・航道把渡橋切成幾比幾\n" \
			+ "・角平分線和三角島的內心\n\n" \
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
	return BankC3.T_REFL if String(r.get("gen", "")) == "mirror" else BankC3.T_DIST


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


const NORMS := [[3, 4, 5], [4, 3, 5], [5, 12, 13], [12, 5, 13], [8, 15, 17], [15, 8, 17]]
const AXES := [["x 軸", 1, 0], ["y 軸", 2, 0], ["原點", 3, 0], ["直線 y = x", 4, 0], ["直線 y = −x", 5, 0]]


## 速算題：mirror（對稱點，ans 兩格）、pdist（點到直線距離，ans 一格）。{eq, q, template, answers: [...], nudge, tag}
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var pb := {}
		if kind == "mirror":
			var a := randi_range(-6, 6)
			var b := randi_range(-6, 6)
			if a == 0 or b == 0 or a == b or a == -b:
				continue
			var ax: Array = AXES[randi() % AXES.size()]
			var r := [a, -b]
			var why := "對 x 軸：y 變號。"
			match int(ax[1]):
				2:
					r = [-a, b]
					why = "對 y 軸：x 變號。"
				3:
					r = [-a, -b]
					why = "對原點：兩個都變號。"
				4:
					r = [b, a]
					why = "對 y = x：x、y 交換。"
				5:
					r = [-b, -a]
					why = "對 y = −x：交換再變號。"
			pb = {"eq": "P%s\n對%s的對稱點" % [_pt(a, b), ax[0]], "q": "寫出對稱點 P′。", "template": "P′([0], [1])",
				"answers": [str(r[0]), str(r[1])], "tag": BankC3.T_REFL, "nudge": why}
		else:
			var nm: Array = NORMS[randi() % NORMS.size()]
			var sb := 1 if randf() < 0.5 else -1
			var a := int(nm[0])
			var b := sb * int(nm[1])
			var x0 := randi_range(-4, 4)
			var y0 := randi_range(-4, 4)
			var d := randi_range(1, 4)
			var sgn := 1 if randf() < 0.5 else -1
			var c := sgn * d * int(nm[2]) - (a * x0 + b * y0)
			if absi(c) > 60 or c == 0:
				continue
			pb = {"eq": "P%s 到\n%s" % [_pt(x0, y0), lin(a, b, c)], "q": "算出距離。", "template": "d = [0]", "answers": [str(d)],
				"tag": BankC3.T_DIST, "nudge": "\\frac{|%d × %s + %s × %s %s|}{√(%d^{2} + %d^{2})}，分母是 %d。" % [a, _wrap(x0), _wrap(b), _wrap(y0),
					("+ %d" % c) if c > 0 else ("− %d" % -c), a, absi(b), nm[2]]}
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
