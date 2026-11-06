extends "res://data/levels/line/line_level.gd"
## 直線與圓 第七大關「切線燈環」（對應講義 3-3 重點五：切線問題）
## 引擎是 line_level.gd（推導＋下方的坐標方格、點選格子點、滑桿），題庫在 line7_bank.gd。
## 這一關的坐標方格都有切點燈：直線剛好和圓相切時，切點亮起一盞燈（plane 的 "lamps"）。
##   ・第一章：圓上一點的切線（⊥ 半徑、鉛直切線）、替換公式、圓外一點的兩條切線（別漏鉛直線）、切線段長、切線速算
##   ・第二章：湖面反射、影長、水滴裡的反射、兩條切線的交點、從切線反求圓、切線段速算
##   ・背景：夜裡的湖岸一圈燈，燈塔的光擦過湖岸，切點亮起來（data/ui/scenery.gd 的 "lampring"）
## 不收圓冪（使用者 2026/11/07：課綱刪掉了），切線段長只用畢氏定理。

const BankC7 := preload("res://data/levels/line/line7_bank.gd")
const LAMP := UITheme.PINK

const CHAPTERS_C7 := [
	{"ch": 1, "name": "第一章．點亮切點", "topic": "圓上一點的切線、替換公式、圓外一點的切線、切線段長", "color": UITheme.PINK},
	{"ch": 2, "name": "第二章．切線的應用", "topic": "反射、影長、水滴裡的反射、兩條切線的交點、從切線反求圓", "color": UITheme.GOLD},
]


func level_id() -> String:
	return "C7"

func level_title() -> String:
	return "切線燈環"

func level_subtitle() -> String:
	return "切線"

func level_chapters() -> Array:
	return CHAPTERS_C7

func bank_slots() -> Array:
	return BankC7.slots()

func step_color() -> Color:
	return LAMP

func scene_theme() -> String:
	return "lampring"

func stage_style() -> Dictionary:
	return {"sky_top": Color("1a1430"), "sky_bot": Color("0a0814"), "scenery": "none", "ambient": ""}

func chapter_card() -> Dictionary:
	return {"title": "第二章．切線的應用", "button": "出發  ▶",
		"text": "切線都會求了，接下來讓光去做事：\n\n" \
			+ "・湖面反射後擦過燈環的光\n" \
			+ "・小島在牆上的影子\n" \
			+ "・水滴裡反射的光\n" \
			+ "・兩道切線光的交會、照訂單做燈環\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_show() -> void:
	var pb: Dictionary = problems[sp_i]
	fview.show_speed(pb.eq, sp_i, problems.size(), streak)
	step_label.text = UITheme.step_bar(_steps(), 0)
	if sp_i > 0:
		story_label.visible = false
	_build_fill({"name": "速算", "q": pb.q, "template": pb.template, "answers": pb.answers, "alts": pb.get("alts", []),
		"mode": "ordered", "nudge": pb.nudge, "tag": pb.tag, "line": "", "paren": true})


func _speed_tag() -> String:
	return BankC7.T_PT


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 圓上一點：圓心到切點的向量（都是最簡的整數比，切線的係數就不用約分）
const VECS := [[3, 4], [4, 3], [1, 2], [2, 1], [1, 3], [3, 1], [1, 1]]
## 切線段長：[r, 切線段長, 圓心到 P 的向量…]
const LENS := [[1, 2, [[1, 2], [2, 1]]], [2, 1, [[1, 2], [2, 1]]], [1, 3, [[1, 3], [3, 1]]], [3, 1, [[1, 3], [3, 1]]],
	[3, 4, [[3, 4], [4, 3], [5, 0], [0, 5]]], [4, 3, [[3, 4], [4, 3], [5, 0], [0, 5]]], [2, 4, [[2, 4], [4, 2]]], [4, 2, [[2, 4], [4, 2]]]]


## 速算題：tan（圓上一點的切線）、len（切線段長）。{eq, q, template, answers, alts, nudge, tag}
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 3000:
		guard += 1
		var h := 0
		var k := 0
		if randf() < 0.6:
			h = randi_range(-3, 3)
			k = randi_range(-3, 3)
		var sx := 1 if randf() < 0.5 else -1
		var sy := 1 if randf() < 0.5 else -1
		var pb := {}
		if kind == "len":
			var e: Array = LENS[randi() % LENS.size()]
			var r := int(e[0])
			var vs: Array = e[2]
			var v: Array = vs[randi() % vs.size()]
			var a := int(v[0]) * sx
			var b := int(v[1]) * sy
			pb = {"eq": "%s、圓外一點 P%s" % [_circle(h, k, r * r), _pt(h + a, k + b)], "q": "算出 \\ol{PK}^{2} 和切線段長 \\ol{PT}（T 是切點）。",
				"template": "\\ol{PK}^{2} = [0]，\\ol{PT} = [1]", "answers": [str(a * a + b * b), str(int(e[1]))],
				"tag": BankC7.T_EXT, "nudge": "切線段長 = √(\\ol{PK}^{2} − r^{2})。"}
		else:
			var v: Array = VECS[randi() % VECS.size()]
			if randf() < 0.5:
				v = [v[1], v[0]]
			var u := int(v[0]) * sx
			var w := int(v[1]) * sy
			var r2 := u * u + w * w
			var c := r2 + u * h + w * k
			pb = {"eq": "%s 上一點 P%s" % [_circle(h, k, r2), _pt(h + u, k + w)], "q": "用公式寫出過 P 的切線。",
				"template": "[0]x + [1]y = [2]", "answers": [str(u), str(w), str(c)], "alts": [[str(-u), str(-w), str(-c)]],
				"tag": BankC7.T_PT,
				"nudge": "x₀x + y₀y = r^{2}。" if h == 0 and k == 0 else "(x₀ − h)(x − h) + (y₀ − k)(y − k) = r^{2}，再展開。"}
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out


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
