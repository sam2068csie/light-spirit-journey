extends "res://data/levels/vec2/vec_level.gd"
## 平面向量 第六大關「風箏航道」（下冊 3-3 重點一：直線的參數式、法向量、距離、極值、投影、反射、夾角）。設計稿：docs/vec2_v6_design.md
## 底層是 vec_level.gd（箭頭畫布、在圖上作答），題庫在 vec6_bank.gd。
##   ・第一章：風箏起飛、哪一條是 AB 航道、線段航道的審判、航道上的珠子、插旗的航道、方向向量和法向量、兩條航道交會、
##             燈塔到航道的距離、沿航道走固定距離、轉 90° 的頂點、速算
##   ・第二章：航道上的極值、最短的繩子、鏡岩、航道上的影子、影子的另一頭、交叉的航道、參數式的交點和夾角、已知斜率的交角、轉動的航道、速算
## 速算：para（直線和箭頭：平行、垂直、都不是）、angle（兩條直線：平行、垂直、夾 45°、都不是）

const BankV6 := preload("res://data/levels/vec2/vec6_bank.gd")

const CHAPTERS_V6 := [
	{"ch": 1, "name": "第一章．風箏航道", "topic": "參數式、方向向量與法向量", "color": UITheme.LIME},
	{"ch": 2, "name": "第二章．鏡岩", "topic": "極值、投影、反射與夾角", "color": UITheme.CYAN},
]


func level_id() -> String:
	return "V6"

func level_title() -> String:
	return "風箏航道"

func level_subtitle() -> String:
	return "直線的參數式與法向量"

func level_chapters() -> Array:
	return CHAPTERS_V6

func bank_slots() -> Array:
	return BankV6.slots()

func step_color() -> Color:
	return UITheme.LIME

func radicals_ok() -> bool:
	return true

func chapter_card() -> Dictionary:
	return {"title": "第二章．鏡岩", "button": "走向鏡岩  ▶",
		"text": "風箏都飛起來了！航道的盡頭有一面像鏡子的岩壁：\n\n" \
			+ "・光打到鏡岩會反射，入射角 = 反射角\n" \
			+ "・兩條航道交叉，看法向量就知道夾多大\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankV6.T_NRM if String(r.get("gen", "")) == "para" else BankV6.T_ANG


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


static func _gcd(a: int, b: int) -> int:
	a = absi(a)
	b = absi(b)
	while b != 0:
		var t := a % b
		a = b
		b = t
	return a


static func _vs(v: Vector2i) -> String:
	return "(%s, %s)" % [str(v.x).replace("-", "−"), str(v.y).replace("-", "−")]


## 速算題：para（直線 ax + by + c = 0 和箭頭 ⇒ 平行／垂直／都不是）、angle（兩條直線 ⇒ 平行／垂直／夾 45°／都不是）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		var want := out.size() % (3 if kind == "para" else 4)
		var a := randi_range(-6, 6)
		var b := randi_range(-6, 6)
		if a == 0 or b == 0 or _gcd(a, b) != 1 and randf() < 0.5:
			continue
		var g := _gcd(a, b)
		var nv := Vector2i(a / g, b / g)
		var c := randi_range(-9, 9)
		if kind == "para":
			var k: int = [1, -1, 2, -2, 3][randi() % 5]
			var v: Vector2i
			match want:
				0:
					v = Vector2i(nv.y, -nv.x) * k
				1:
					v = nv * k
				_:
					v = Vector2i(randi_range(-5, 5), randi_range(-5, 5))
					if v == Vector2i.ZERO or v.x * nv.y - v.y * nv.x == 0 or v.x * nv.x + v.y * nv.y == 0:
						continue
			var key := "%d,%d,%d,%s" % [a, b, c, str(v)]
			if seen.has(key):
				continue
			seen[key] = true
			out.append({"eq": "%s，%s" % [BankV6._lstr(a, b, c), _vs(v)], "q": "箭頭和直線", "choices": ["平行", "垂直", "都不是"], "correct": want,
				"tag": BankV6.T_NRM, "nudge": "法向量是 (a, b)：箭頭和法向量垂直 ⇒ 和直線平行，和法向量平行 ⇒ 和直線垂直。"})
			continue
		# angle：第二條直線的法向量
		var m: Vector2i
		match want:
			0:
				m = nv * [1, -1, 2, 3][randi() % 4]
			1:
				m = Vector2i(-nv.y, nv.x) * [1, -1, 2][randi() % 3]
			2:
				# 轉 45° 再乘 √2：(a − b, a + b) 或 (a + b, b − a)，約分
				var r := Vector2i(nv.x - nv.y, nv.x + nv.y) if randf() < 0.5 else Vector2i(nv.x + nv.y, nv.y - nv.x)
				var gg := _gcd(r.x, r.y)
				if gg == 0:
					continue
				m = r / gg
			_:
				m = Vector2i(randi_range(-5, 5), randi_range(-5, 5))
				var dt := m.x * nv.x + m.y * nv.y
				var cr := m.x * nv.y - m.y * nv.x
				var nn := (m.x * m.x + m.y * m.y) * (nv.x * nv.x + nv.y * nv.y)
				if m == Vector2i.ZERO or cr == 0 or dt == 0 or 2 * dt * dt == nn:
					continue
		if absi(m.x) > 9 or absi(m.y) > 9 or m == Vector2i.ZERO:
			continue
		var c2 := randi_range(-9, 9)
		if want == 0 and c2 * g == c * (m.x / nv.x if nv.x != 0 else m.y / nv.y):
			c2 += 1
		var key2 := "%d,%d,%s" % [a, b, str(m)]
		if seen.has(key2):
			continue
		seen[key2] = true
		out.append({"eq": "%s，%s" % [BankV6._lk(a, b, c), BankV6._lk(m.x, m.y, c2)], "q": "兩直線的夾角", "choices": ["平行", "垂直", "夾 45°", "都不是"], "correct": want,
			"tag": BankV6.T_ANG, "nudge": "看兩支法向量：倍數 ⇒ 平行，內積 0 ⇒ 垂直，cos^{2} θ = \\frac{1}{2} ⇒ 45°。"})
	return out
