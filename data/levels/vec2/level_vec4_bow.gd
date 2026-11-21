extends "res://data/levels/vec2/vec_level.gd"
## 平面向量 第四大關「長弓靶場」（上冊 3-2 重點二、三：求長度、求夾角）。設計稿：docs/vec2_v4_design.md
## 底層是 vec_level.gd（箭頭畫布、在圖上作答），題庫在 vec4_bank.gd。
##   ・第一章：兩條對角線、兩個靶之間（鋪路）、拉弓的角度、最遠和最近（合起來的箭）、弓弦和拋物線、外心與角平分線（展開田）、速算
##   ・第二章：正負和角度（轉反例）、坐標量角度（量角器先猜）、假根、三面旗子、只知道長度的夾角、直角的兩支箭、速算
## 速算：len（|\vec{a} + \vec{b}|^{2}，填數字）、ang（坐標看角度，按鈕 45°、90°、135°）
## 這一關的答案常有根號：填空有「√」鍵。

const BankV4 := preload("res://data/levels/vec2/vec4_bank.gd")

const CHAPTERS_V4 := [
	{"ch": 1, "name": "第一章．長弓靶場", "topic": "長度平方展開、長度的範圍、最小值、外心與角平分線", "color": UITheme.PINK},
	{"ch": 2, "name": "第二章．量角器", "topic": "內積的正負、坐標求角、假根、已知長度求夾角", "color": UITheme.GOLD},
]


func level_id() -> String:
	return "V4"

func level_title() -> String:
	return "長弓靶場"

func level_subtitle() -> String:
	return "求長度與夾角"

func level_chapters() -> Array:
	return CHAPTERS_V4

func bank_slots() -> Array:
	return BankV4.slots()

func step_color() -> Color:
	return UITheme.PINK

## 長度、cos 常常有根號
func radicals_ok() -> bool:
	return true

func chapter_card() -> Dictionary:
	return {"title": "第二章．量角器", "button": "拿起量角器  ▶",
		"text": "箭都射進靶裡了！崖邊的大量角器亮起來：\n\n" \
			+ "・先用量角器猜，再用內積算夾角\n" \
			+ "・平方會弄丟正負，根要代回去\n" \
			+ "・只知道長度，也能求夾角\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankV4.T_LEN if String(r.get("gen", "")) == "len" else BankV4.T_ANG


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


static func _sn(v: int) -> String:
	return str(v).replace("-", "−")


## 速算題：len（|\vec{a}|、|\vec{b}|、夾角 ⇒ |\vec{a} + \vec{b}|^{2}）、ang（坐標 ⇒ 45°、90°、135°）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 6000:
		guard += 1
		var pb := {}
		var key := ""
		if kind == "len":
			var la := randi_range(1, 5)
			var lb := randi_range(1, 5)
			var th: int = [0, 60, 90, 120, 180][out.size() % 5]
			var c2: int = {0: 2, 60: 1, 90: 0, 120: -1, 180: -2}[th]     # 2cos θ
			var v := la * la + lb * lb + c2 * la * lb
			pb = {"eq": "|\\vec{a}| = %d，|\\vec{b}| = %d，夾角 %d°" % [la, lb, th], "q": "長度平方展開",
				"template": "|\\vec{a} + \\vec{b}|^{2} = [0]", "answers": [str(v)], "tag": BankV4.T_LEN,
				"nudge": "|\\vec{a}|^{2} + 2|\\vec{a}||\\vec{b}|cos θ + |\\vec{b}|^{2}。"}
			key = "%d,%d,%d" % [la, lb, th]
		else:
			var a := Vector2i(randi_range(-3, 3), randi_range(-3, 3))
			if a == Vector2i.ZERO:
				continue
			var want := out.size() % 3
			var b: Vector2i
			match want:
				0:
					b = Vector2i(a.x - a.y, a.x + a.y)
				1:
					b = Vector2i(-a.y, a.x) * [1, 2][randi() % 2]
				_:
					b = Vector2i(-a.x - a.y, a.x - a.y)
			if randi() % 2 == 0:
				var tmp := a
				a = b
				b = tmp
			pb = {"eq": "\\vec{a} = (%s, %s)，\\vec{b} = (%s, %s)" % [_sn(a.x), _sn(a.y), _sn(b.x), _sn(b.y)], "q": "夾角是幾度",
				"choices": ["45°", "90°", "135°"], "correct": want, "tag": BankV4.T_ANG,
				"nudge": "cos θ = \\frac{\\vec{a} · \\vec{b}}{|\\vec{a}||\\vec{b}|}：內積是 0 就是 90°，正的 45°、負的 135°。"}
			key = str(a) + str(b)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out
