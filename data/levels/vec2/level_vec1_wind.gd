extends "res://data/levels/vec2/vec_level.gd"
## 平面向量 第一大關「風向台」（上冊 3-1 重點一、二：向量的意義、線性組合、分點公式）。設計稿：docs/vec2_v1_design.md
## 底層是 vec_level.gd（箭頭畫布、在圖上作答），題庫在 vec1_bank.gd。
##   ・第一章：相等向量、圖鑑（數有幾個向量）、減法鋪路、正六邊形審判、平行四邊形的判定（拖旗桿）、伸縮弓、斜方格、不共線、速算
##   ・第二章：繩橋珠子＋秤桿、兩隻風箏（終點減起點）、梯形、角平分線（對折）、內切圓（吹圓）、垂足（鉛錘）、面積比（縮放鏡）、速算
## 速算：skew（斜格子上讀係數，每一題一張圖）、bead（分點的係數，填分數）

const BankV1 := preload("res://data/levels/vec2/vec1_bank.gd")

const CHAPTERS_V1 := [
	{"ch": 1, "name": "第一章．風向台", "topic": "相等向量、加減法、用兩支箭頭表示、平行、不共線", "color": UITheme.CYAN},
	{"ch": 2, "name": "第二章．繩橋", "topic": "分點公式、角平分線、內切圓、垂足、面積比", "color": UITheme.GOLD},
]


func level_id() -> String:
	return "V1"

func level_title() -> String:
	return "風向台"

func level_subtitle() -> String:
	return "向量的意義與分點公式"

func level_chapters() -> Array:
	return CHAPTERS_V1

func bank_slots() -> Array:
	return BankV1.slots()

func step_color() -> Color:
	return UITheme.CYAN

func chapter_card() -> Dictionary:
	return {"title": "第二章．繩橋", "button": "過橋  ▶",
		"text": "風箏都放上天了！崖邊有一條繩橋，繩上穿著珠子：\n\n" \
			+ "・珠子把繩子分成幾比幾，係數就交叉\n" \
			+ "・對折、吹氣球、垂鉛錘、縮放鏡，找出分點\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankV1.T_LIN if String(r.get("gen", "")) == "skew" else BankV1.T_DIV


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


const BASES := [[Vector2(2, 0), Vector2(1, 1.5)], [Vector2(2, 0.6), Vector2(-0.6, 1.6)], [Vector2(1.6, -0.8), Vector2(0.8, 1.4)],
	[Vector2(2, 0.5), Vector2(0.5, 1.5)]]


static func _cf(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return "%d/2" % int(roundf(v * 2.0))


## 速算題：skew（斜格子上 \vec{OP} = x\vec{a} + y\vec{b}）、bead（\ol{BP} : \ol{PC} = m : n，\vec{AP} 的係數）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		var pb := {}
		if kind == "skew":
			var bs: Array = BASES[randi() % BASES.size()]
			var a: Vector2 = bs[0]
			var b: Vector2 = bs[1]
			var half := out.size() % 3 == 2           # 三題裡有一題是半格
			var x := float(randi_range(-2, 3))
			var y := float(randi_range(-2, 2))
			if half:
				if randf() < 0.5:
					x += 0.5
				else:
					y += 0.5
			if absf(x) < 1e-6 and absf(y) < 1e-6:
				continue
			var P := a * x + b * y
			if absf(P.x) > 6.2 or absf(P.y) > 3.0:
				continue
			var plane := {"x": [-7, 7], "y": [-3.5, 3.5], "grid": "none", "named": {},
				"shapes": [{"k": "skew", "o": [0, 0], "a": [a.x, a.y], "b": [b.x, b.y], "i": [-5, 5], "j": [-4, 4], "div": 2 if half else 1, "c": "cyan"},
					{"k": "arrow", "a": [0, 0], "b": [a.x, a.y], "c": "cyan", "s": "\\vec{a}", "w": 2.5, "ls": -1},
					{"k": "arrow", "a": [0, 0], "b": [b.x, b.y], "c": "pink", "s": "\\vec{b}", "w": 2.5},
					{"k": "arrow", "a": [0, 0], "b": [P.x, P.y], "c": "gold", "w": 3.5},
					{"k": "tag", "p": [0, 0], "s": "O", "c": "text", "off": [-14, 14]},
					{"k": "tag", "p": [P.x, P.y], "s": "P", "c": "gold"}]}
			pb = {"eq": "\\vec{OP} = x\\vec{a} + y\\vec{b}", "q": "數斜格子", "template": "\\vec{OP} = [0]\\vec{a} + [1]\\vec{b}",
				"answers": [_cf(x), _cf(y)], "tag": BankV1.T_LIN, "plane": plane,
				"nudge": "沿 \\vec{a} 走幾格、再沿 \\vec{b} 走幾格？反方向是負的。"}
		else:
			var m := randi_range(1, 5)
			var k := randi_range(1, 5)
			if m == k or _gcd(m, k) != 1:
				continue
			var A := Vector2(0, 4)
			var B := Vector2(-5, -1)
			var C := Vector2(5, -1)
			var P := B.lerp(C, float(m) / float(m + k))
			var plane := {"x": [-9, 9], "y": [-2.6, 5.4], "grid": "none", "named": {},
				"shapes": [{"k": "poly", "pts": [[A.x, A.y], [B.x, B.y], [C.x, C.y]], "c": "dim"},
					{"k": "seg", "a": [B.x, B.y], "b": [C.x, C.y], "c": "gold", "w": 3.0},
					{"k": "dot", "p": [A.x, A.y], "s": "A", "c": "text", "off": [8, -4]},
					{"k": "dot", "p": [B.x, B.y], "s": "B", "c": "text", "off": [-16, 4]},
					{"k": "dot", "p": [C.x, C.y], "s": "C", "c": "text", "off": [8, 4]},
					{"k": "dot", "p": [P.x, P.y], "s": "P", "c": "gold", "off": [-4, 20]}]}
			pb = {"eq": "\\ol{BP} : \\ol{PC} = %d : %d，\\vec{AP} = ？" % [m, k], "q": "係數交叉",
				"template": "\\vec{AP} = [0]\\vec{AB} + [1]\\vec{AC}", "answers": ["%d/%d" % [k, m + k], "%d/%d" % [m, m + k]],
				"tag": BankV1.T_DIV, "plane": plane,
				"nudge": "靠近 B，\\vec{AB} 的係數就大：\\frac{n}{m + n}\\vec{AB} + \\frac{m}{m + n}\\vec{AC}。"}
		var key := String(pb.eq) + str(pb.answers)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out
