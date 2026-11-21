extends "res://data/levels/vec2/vec_level.gd"
## 平面向量 第五大關「四心營火」（上冊 3-2 重點四、五：三角形的四心、面積比）。設計稿：docs/vec2_v5_design.md
## 底層是 vec_level.gd（箭頭畫布、在圖上作答），題庫在 vec5_bank.gd。
##   ・第一章：重心審判（拖 G）、重心的內積、首尾相接的三支箭、小營地的重心、過重心的蹺蹺板、內心審判、點起四座營火、四心審判、外心和垂心的計算、速算
##   ・第二章：三分花圃、一樣高的花圃、係數就是高、三條繩子拉花圃、照面積放營火、面積比反推係數、四心的花圃、速算
## 速算：center（看關係式按四心）、area（權重 ⇒ 某一塊佔全部的比，填分數）

const BankV5 := preload("res://data/levels/vec2/vec5_bank.gd")

const CHAPTERS_V5 := [
	{"ch": 1, "name": "第一章．四心營火", "topic": "重心、內心、外心、垂心的向量性質與計算", "color": UITheme.GOLD},
	{"ch": 2, "name": "第二章．三分花圃", "topic": "係數、權重與面積比", "color": UITheme.LIME},
]


func level_id() -> String:
	return "V5"

func level_title() -> String:
	return "四心營火"

func level_subtitle() -> String:
	return "三角形的四心與面積比"

func level_chapters() -> Array:
	return CHAPTERS_V5

func bank_slots() -> Array:
	return BankV5.slots()

func step_color() -> Color:
	return UITheme.GOLD

func radicals_ok() -> bool:
	return true

func chapter_card() -> Dictionary:
	return {"title": "第二章．三分花圃", "button": "走進花圃  ▶",
		"text": "四座營火都點起來了！營地旁邊有一片三角形的花圃：\n\n" \
			+ "・從 P 拉三條線，把花圃分成三塊\n" \
			+ "・係數、權重、面積比，其實是同一件事\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankV5.T_CTR if String(r.get("gen", "")) == "center" else BankV5.T_AREA


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


const CENTER_FORMS := [
	["\\vec{PA} + \\vec{PB} + \\vec{PC} = \\vec{0}", 0],
	["\\vec{AP} = \\frac{1}{3}(\\vec{AB} + \\vec{AC})", 0],
	["|\\vec{PA}| = |\\vec{PB}| = |\\vec{PC}|", 1],
	["\\vec{AP} · \\vec{AB} = \\frac{1}{2}|\\vec{AB}|^{2}，\\vec{AP} · \\vec{AC} = \\frac{1}{2}|\\vec{AC}|^{2}", 1],
	["\\ol{BC}\\vec{PA} + \\ol{CA}\\vec{PB} + \\ol{AB}\\vec{PC} = \\vec{0}", 2],
	["△PBC : △PCA : △PAB = \\ol{BC} : \\ol{CA} : \\ol{AB}", 2],
	["\\vec{PA} · \\vec{PB} = \\vec{PB} · \\vec{PC} = \\vec{PC} · \\vec{PA}", 3],
	["\\vec{AP} · \\vec{BC} = \\vec{BP} · \\vec{CA} = 0", 3],
]


## 速算題：center（關係式 ⇒ 哪一心）、area（w_{A}\vec{PA} + w_{B}\vec{PB} + w_{C}\vec{PC} = \vec{0} ⇒ 某一塊佔全部）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	if kind == "center":
		var order := range(CENTER_FORMS.size())
		order.shuffle()
		var letters := ["P", "Q", "X"]
		for i in mini(n, order.size()):
			var f: Array = CENTER_FORMS[order[i]]
			var L: String = letters[randi() % letters.size()]
			out.append({"eq": String(f[0]).replace("P", L), "q": "是哪一心", "choices": ["重心", "外心", "內心", "垂心"], "correct": int(f[1]),
				"tag": BankV5.T_GC if int(f[1]) == 0 else BankV5.T_CTR,
				"nudge": "重心：合力是 \\vec{0}。外心：一樣遠。內心：權重是對邊長。垂心：和對邊垂直。"})
		return out
	var seen := {}
	var guard := 0
	var names := ["△PBC", "△PCA", "△PAB"]
	while out.size() < n and guard < 3000:
		guard += 1
		var w := [randi_range(1, 5), randi_range(1, 5), randi_range(1, 5)]
		var k := randi() % 3
		var key := str(w) + str(k)
		if seen.has(key) or (w[0] == w[1] and w[1] == w[2]):
			continue
		seen[key] = true
		var s: int = w[0] + w[1] + w[2]
		var g := _gcd(int(w[k]), s)
		var ans := "%d/%d" % [int(w[k]) / g, s / g] if s / g != 1 else str(int(w[k]) / g)
		var terms := ""
		for i in 3:
			var c := "" if int(w[i]) == 1 else str(w[i])
			terms += ("" if i == 0 else " + ") + c + "\\vec{P%s}" % ["A", "B", "C"][i]
		out.append({"eq": "%s = \\vec{0}" % terms, "q": "佔全部的比", "template": "\\frac{%s}{△ABC} = [0]" % names[k],
			"answers": [ans], "tag": BankV5.T_AREA, "nudge": "%s 對面的頂點，它的權重除以權重和。" % names[k]})
	return out
