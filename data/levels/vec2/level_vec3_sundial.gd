extends "res://data/levels/vec2/vec_level.gd"
## 平面向量 第三大關「日晷影場」（上冊 3-2 重點一、六：內積、垂直與平行、正射影）。設計稿：docs/vec2_v3_design.md
## 底層是 vec_level.gd（箭頭畫布、在圖上作答），題庫在 vec3_bank.gd。
##   ・第一章：轉動的影子、觀念審判（拖反例）、共線、影子排隊、尾接尾的夾角、化成基底（展開田）、垂足、內積是定值的圓、速算
##   ・第二章：坐標的內積、垂直求 t、平行求 t、兩道條件的光、影子＋竿子、正射影公式、正射影的審判、同一道陽光、竿子垂直地面、速算
## 速算：sign（看圖判斷內積 > 0、= 0、< 0，每一題一張圖）、perp（坐標判斷垂直、平行、都不是）

const BankV3 := preload("res://data/levels/vec2/vec3_bank.gd")

const CHAPTERS_V3 := [
	{"ch": 1, "name": "第一章．日晷影場", "topic": "內積的意義、性質、化成基底展開、內積的圓", "color": UITheme.ORANGE},
	{"ch": 2, "name": "第二章．影子與竿子", "topic": "坐標的內積、垂直與平行、正射影", "color": UITheme.GOLD},
]


func level_id() -> String:
	return "V3"

func level_title() -> String:
	return "日晷影場"

func level_subtitle() -> String:
	return "內積與正射影"

func level_chapters() -> Array:
	return CHAPTERS_V3

func bank_slots() -> Array:
	return BankV3.slots()

func step_color() -> Color:
	return UITheme.ORANGE

func chapter_card() -> Dictionary:
	return {"title": "第二章．影子與竿子", "button": "刻上方格  ▶",
		"text": "日晷的影子都量好了！石台上刻上直角坐標的方格：\n\n" \
			+ "・內積用坐標直接算\n" \
			+ "・垂直、平行的條件\n" \
			+ "・一支箭頭 = 地上的影子 + 垂直的竿子（正射影）\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankV3.T_DOT if String(r.get("gen", "")) == "sign" else BankV3.T_PERP


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


static func _sn(v: int) -> String:
	return str(v).replace("-", "−")


## 速算題：sign（看圖：\vec{a} · \vec{b} 的正負，按鈕）、perp（坐標：垂直、平行、都不是，按鈕）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 6000:
		guard += 1
		var pb := {}
		var want := out.size() % 3
		if kind == "sign":
			var a := Vector2i(randi_range(-4, 4), randi_range(-3, 3))
			var b := Vector2i(randi_range(-4, 4), randi_range(-3, 3))
			if a == Vector2i.ZERO or b == Vector2i.ZERO or a.x * b.y - a.y * b.x == 0:
				continue
			# 太短或夾角太小，兩支箭頭會疊在一起看不清楚
			if a.length_squared() < 5 or b.length_squared() < 5:
				continue
			if absf(a.x * b.y - a.y * b.x) < 0.4 * Vector2(a).length() * Vector2(b).length():
				continue
			var d := a.x * b.x + a.y * b.y
			var got := 0 if d > 0 else (1 if d == 0 else 2)
			if got != want:
				continue
			var plane := {"x": [-5.5, 5.5], "y": [-3.6, 3.6], "grid": "plain", "named": {},
				"shapes": [{"k": "arrow", "a": [0, 0], "b": [a.x, a.y], "c": "cyan", "s": "\\vec{a}", "w": 3.0, "ls": -1},
					{"k": "arrow", "a": [0, 0], "b": [b.x, b.y], "c": "pink", "s": "\\vec{b}", "w": 3.0}]}
			pb = {"eq": "\\vec{a} · \\vec{b} 是？", "q": "看夾角", "choices": ["> 0", "= 0", "< 0"], "correct": got,
				"tag": BankV3.T_DOT, "plane": plane, "key": str(a) + str(b),
				"nudge": "銳角是正的、直角是 0、鈍角是負的（看方格算 a_{1}b_{1} + a_{2}b_{2} 也可以）。"}
		else:
			var a := Vector2i(randi_range(-6, 6), randi_range(-6, 6))
			if a == Vector2i.ZERO:
				continue
			var b: Vector2i
			if want == 0:
				var k: int = [1, -1, 2, -2][randi() % 4]
				b = Vector2i(-a.y, a.x) * k
			elif want == 1:
				var k: int = [2, -1, -2, 3][randi() % 4]
				b = a * k
				if absi(b.x) > 9 or absi(b.y) > 9:
					continue
			else:
				b = Vector2i(randi_range(-6, 6), randi_range(-6, 6))
			if b == Vector2i.ZERO:
				continue
			var d := a.x * b.x + a.y * b.y
			var cr := a.x * b.y - a.y * b.x
			var got := 0 if d == 0 else (1 if cr == 0 else 2)
			if got != want:
				continue
			pb = {"eq": "\\vec{a} = (%s, %s)，\\vec{b} = (%s, %s)" % [_sn(a.x), _sn(a.y), _sn(b.x), _sn(b.y)], "q": "垂直還是平行",
				"choices": ["垂直", "平行", "都不是"], "correct": got, "tag": BankV3.T_PERP, "key": str(a) + str(b),
				"nudge": "垂直：a_{1}b_{1} + a_{2}b_{2} = 0。平行：分量成比例。"}
		var key := String(pb.key)
		if seen.has(key):
			continue
		seen[key] = true
		pb.erase("key")
		out.append(pb)
	return out
