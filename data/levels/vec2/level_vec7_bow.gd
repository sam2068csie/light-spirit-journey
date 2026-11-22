extends "res://data/levels/vec2/vec_level.gd"
## 平面向量 第七大關「弓帆工坊」（下冊 3-3 重點二、三：柯西不等式、三角不等式、面積公式）。設計稿：docs/vec2_v7_design.md
## 底層是 vec_level.gd（箭頭畫布、在圖上作答），題庫在 vec7_bank.gd。
##   ・第一章：弓弦、拉最緊的弓、先整理弓弦、圓上的弓、直角的兩根竿子、倒過來的弓、不等式的審判、三角形裡的距離、半圓湖、速算
##   ・第二章：張開的帆、只知道長度的帆、坐標的帆、帆布的審判、兩面方帆、斜格子上的帆布、帆張多開、速算
## 速算：cauchy（ax + by = k，x² + y² 的最小值）、area（兩支向量張成的三角形面積）

const BankV7 := preload("res://data/levels/vec2/vec7_bank.gd")

const CHAPTERS_V7 := [
	{"ch": 1, "name": "第一章．弓架", "topic": "柯西不等式與三角不等式", "color": UITheme.GOLD},
	{"ch": 2, "name": "第二章．帆布場", "topic": "面積公式", "color": UITheme.CYAN},
]


func level_id() -> String:
	return "V7"

func level_title() -> String:
	return "弓帆工坊"

func level_subtitle() -> String:
	return "柯西不等式與面積公式"

func level_chapters() -> Array:
	return CHAPTERS_V7

func bank_slots() -> Array:
	return BankV7.slots()

func step_color() -> Color:
	return UITheme.GOLD

func radicals_ok() -> bool:
	return true

func chapter_card() -> Dictionary:
	return {"title": "第二章．帆布場", "button": "走向帆布場  ▶",
		"text": "弓都拉滿了！碼頭邊的帆還收著：\n\n" \
			+ "・兩支箭頭張開，張成一面三角形的帆\n" \
			+ "・帆的面積 = \\frac{1}{2}|a_{1}b_{2} − a_{2}b_{1}|\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankV7.T_CAU if String(r.get("gen", "")) == "cauchy" else BankV7.T_AREA


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


static func _frac(n: int, d: int) -> String:
	var g := _gcd(n, d)
	n /= g
	d /= g
	if d < 0:
		n = -n
		d = -d
	return str(n) if d == 1 else "%d/%d" % [n, d]


## 速算題：cauchy（ax + by = k ⇒ x² + y² 的最小值 \frac{k²}{a² + b²}）、area（\vec{a}、\vec{b} 張成的三角形面積）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		if kind == "cauchy":
			var a := randi_range(-4, 4)
			var b := randi_range(-4, 4)
			var k := randi_range(1, 12)
			if a == 0 or b == 0:
				continue
			var key := "%d,%d,%d" % [a, b, k]
			if seen.has(key):
				continue
			seen[key] = true
			out.append({"eq": "%s = %d" % [BankV7.B6._lin2(a, b, 0.0), k], "q": "x² + y² 的最小值", "template": "最小值 [0]",
				"answers": [_frac(k * k, a * a + b * b)], "tag": BankV7.T_CAU,
				"nudge": "(x^{2} + y^{2})(a^{2} + b^{2}) ≥ (ax + by)^{2}：最小值 \\frac{k^{2}}{a^{2} + b^{2}}。"})
			continue
		var p := Vector2i(randi_range(-5, 5), randi_range(-5, 5))
		var q := Vector2i(randi_range(-5, 5), randi_range(-5, 5))
		var det := p.x * q.y - p.y * q.x
		if det == 0:
			continue
		var key2 := str(p) + str(q)
		if seen.has(key2):
			continue
		seen[key2] = true
		out.append({"eq": "\\vec{a} = %s、\\vec{b} = %s" % [BankV7._pt(Vector2(p)), BankV7._pt(Vector2(q))], "q": "三角形面積", "template": "△ = [0]",
			"answers": [_frac(absi(det), 2)], "tag": BankV7.T_AREA, "nudge": "\\frac{1}{2}|a_{1}b_{2} − a_{2}b_{1}|：交叉相乘、相減、取絕對值。"})
	return out
