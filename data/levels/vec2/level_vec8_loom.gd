extends "res://data/levels/vec2/vec_level.gd"
## 平面向量 第八大關「雙線織坊」（下冊 3-3 重點四：二階行列式與克拉瑪法則）。設計稿：docs/vec2_v8_design.md
## 底層是 vec_level.gd（箭頭畫布、在圖上作答），題庫在 vec8_bank.gd。
##   ・第一章：張開的布、大數字的布、整數的織法、拉長推斜的布、疊起來的布、第三根釘子、織布機的審判、速算
##   ・第二章：交叉的線、只知道三塊布、用布量係數、換一組線、交線的審判、有幾組解、轉動的線、永遠碰不到、疊在一起、速算
## 速算：det（二階行列式的值）、sol（兩條直線：恰一組解／無解／無限多組解）

const BankV8 := preload("res://data/levels/vec2/vec8_bank.gd")

const CHAPTERS_V8 := [
	{"ch": 1, "name": "第一章．織布機", "topic": "二階行列式", "color": UITheme.VIOLET},
	{"ch": 2, "name": "第二章．交叉的線", "topic": "克拉瑪法則", "color": UITheme.CYAN},
]


func level_id() -> String:
	return "V8"

func level_title() -> String:
	return "雙線織坊"

func level_subtitle() -> String:
	return "二階行列式與克拉瑪法則"

func level_chapters() -> Array:
	return CHAPTERS_V8

func bank_slots() -> Array:
	return BankV8.slots()

func step_color() -> Color:
	return UITheme.VIOLET

func radicals_ok() -> bool:
	return true

func chapter_card() -> Dictionary:
	return {"title": "第二章．交叉的線", "button": "走向掛線架  ▶",
		"text": "布都織好了！架子上的線交叉在一起：\n\n" \
			+ "・兩條線交叉的地方，就是聯立方程式的解\n" \
			+ "・Δ ≠ 0 交在一點，Δ = 0 平行或疊在一起\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankV8.T_DET if String(r.get("gen", "")) == "det" else BankV8.T_SOL


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 速算題：det（二階行列式的值）、sol（兩條直線 ⇒ 恰一組解／無解／無限多組解）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		if kind == "det":
			var m := [randi_range(-6, 9), randi_range(-6, 9), randi_range(-6, 9), randi_range(-6, 9)]
			if m.has(0):
				continue
			var key := str(m)
			if seen.has(key):
				continue
			seen[key] = true
			out.append({"eq": BankV8._D(m[0], m[1], m[2], m[3]), "q": "行列式的值", "template": "值 = [0]",
				"answers": [str(m[0] * m[3] - m[1] * m[2])], "tag": BankV8.T_DET, "nudge": "左上 × 右下 − 右上 × 左下。"})
			continue
		var want := out.size() % 3
		var a1 := randi_range(-4, 4)
		var b1 := randi_range(-4, 4)
		var c1 := randi_range(-6, 6)
		if a1 == 0 or b1 == 0:
			continue
		var a2: int
		var b2: int
		var c2: int
		if want == 0:
			a2 = randi_range(-4, 4)
			b2 = randi_range(-4, 4)
			c2 = randi_range(-6, 6)
			if a2 == 0 and b2 == 0 or a1 * b2 - a2 * b1 == 0:
				continue
		else:
			var k: int = [2, -1, -2, 3][randi() % 4]
			a2 = a1 * k
			b2 = b1 * k
			c2 = c1 * k if want == 2 else c1 * k + [1, -1, 2, 3][randi() % 4]
		var key2 := "%d,%d,%d,%d,%d,%d" % [a1, b1, c1, a2, b2, c2]
		if seen.has(key2):
			continue
		seen[key2] = true
		out.append({"eq": "%s、%s" % [BankV8.B6._lk(a1, b1, c1), BankV8.B6._lk(a2, b2, c2)], "q": "解的個數",
			"choices": ["恰一組解", "無解", "無限多組解"], "correct": want, "tag": BankV8.T_SOL,
			"nudge": "Δ ≠ 0 恰一組，Δ = 0 時看常數是不是也成比例。"})
	return out
