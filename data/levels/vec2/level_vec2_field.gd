extends "res://data/levels/vec2/vec_level.gd"
## 平面向量 第二大關「斜紋麥田」（上冊 3-1 重點三、四：共線、係數的範圍、坐標表示法）。設計稿：docs/vec2_v2_design.md
## 底層是 vec_level.gd（箭頭畫布、在圖上作答），題庫在 vec2_bank.gd。
##   ・第一章：共線判斷、x + y、兩道光束（交點）、分線段的比、孟氏、三角形內部、菱形播種、七塊田、面積、速算
##   ・第二章：斜地址、拼箭頭、梯形第四點、橡皮筋（加權平均）、塌掉的斜格子、中點、合力最小值、單位向量、角平分向量、坐標分點、速算
## 速算：side（按鈕：在直線 BC 上、和 A 同側、另一側）、coord（m\vec{a} + n\vec{b} 的坐標，填兩格）

const BankV2 := preload("res://data/levels/vec2/vec2_bank.gd")

const CHAPTERS_V2 := [
	{"ch": 1, "name": "第一章．斜紋麥田", "topic": "三點共線、兩線交點、斜坐標的區域與面積", "color": UITheme.LIME},
	{"ch": 2, "name": "第二章．烽台的坐標", "topic": "坐標表示、加權平均、單位向量、角平分向量", "color": UITheme.GOLD},
]


func level_id() -> String:
	return "V2"

func level_title() -> String:
	return "斜紋麥田"

func level_subtitle() -> String:
	return "共線與坐標表示"

func level_chapters() -> Array:
	return CHAPTERS_V2

func bank_slots() -> Array:
	return BankV2.slots()

func step_color() -> Color:
	return UITheme.LIME

func chapter_card() -> Dictionary:
	return {"title": "第二章．烽台的坐標", "button": "點亮烽台  ▶",
		"text": "麥田裡的稻子都種好了！田埂上的烽台排成直角坐標的方格：\n\n" \
			+ "・向量寫成坐標，分量各自算\n" \
			+ "・橡皮筋拉平衡的點、合力指向的點\n" \
			+ "・單位向量、角平分向量、坐標的分點\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankV2.T_COL if String(r.get("gen", "")) == "side" else BankV2.T_CRD


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


static func _coef(v: int, name: String, first: bool) -> String:
	if v == 0:
		return ""
	var body := name if absi(v) == 1 else "%d%s" % [absi(v), name]
	if first:
		return ("−" if v < 0 else "") + body
	return (" − " if v < 0 else " + ") + body


static func _sn(v: int) -> String:
	return str(v).replace("-", "−")


## 速算題：side（x + y 和 1 比：按鈕）、coord（m\vec{a} + n\vec{b} 的坐標）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	var dens := [1, 2, 3, 4, 5]
	while out.size() < n and guard < 4000:
		guard += 1
		var pb := {}
		if kind == "side":
			var d: int = dens[randi() % dens.size()]
			var xn := randi_range(-4, 6)
			var yn := randi_range(-4, 6)
			if xn == 0 or yn == 0:
				continue
			var want := out.size() % 3          # 0 在線上、1 同側、2 另一側（輪流）
			var sm := xn + yn
			var got := 0 if sm == d else (1 if sm < d else 2)
			if got != want:
				continue
			var xs := _frac_s(xn, d)
			var ys := _frac_s(yn, d)
			var expr := xs + "\\vec{AB}" + (" − " if yn < 0 else " + ") + _frac_s(absi(yn), d) + "\\vec{AC}"
			pb = {"eq": "\\vec{AP} = %s\nP 在哪裡？" % expr, "q": "x + y 和 1 比",
				"choices": ["直線 BC 上", "和 A 同一側", "BC 的另一側"], "correct": got, "tag": BankV2.T_COL,
				"nudge": "x + y = 1 在直線 BC 上，< 1 和 A 同側，> 1 在另一側。"}
		else:
			var a := Vector2i(randi_range(-4, 4), randi_range(-4, 4))
			var b := Vector2i(randi_range(-4, 4), randi_range(-4, 4))
			if a == Vector2i.ZERO or b == Vector2i.ZERO or a == b:
				continue
			var m := randi_range(-3, 3)
			var k := randi_range(-3, 3)
			if m == 0 or k == 0:
				continue
			var r := a * m + b * k
			pb = {"eq": "\\vec{a} = (%s, %s)、\\vec{b} = (%s, %s)\n%s%s = ？" % [_sn(a.x), _sn(a.y), _sn(b.x), _sn(b.y),
					_coef(m, "\\vec{a}", true), _coef(k, "\\vec{b}", false)],
				"q": "分量各自算", "template": "([0], [1])", "answers": [str(r.x), str(r.y)], "tag": BankV2.T_CRD,
				"nudge": "x 分量：%d × %s + %d × %s。" % [m, _sn(a.x), k, _sn(b.x)]}
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out


static func _frac_s(n: int, d: int) -> String:
	if d == 1:
		return _sn(n) if absi(n) != 1 else ("−" if n < 0 else "")
	var g := _gcd(absi(n), d)
	var nn := n / g
	var dd := d / g
	if dd == 1:
		return _sn(nn) if absi(nn) != 1 else ("−" if nn < 0 else "")
	return ("−" if nn < 0 else "") + "\\frac{%d}{%d}" % [absi(nn), dd]
