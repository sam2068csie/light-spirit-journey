extends "res://data/levels/num/num_level.gd"
## 高一「指數與常用對數」第一大關「倍增岩壁」（對應講義重點一：指數律）。設計稿：docs/exp_e1_design.md
## 底層是數與式的 num_level.gd（原野、按鈕速算），題庫在 exp1_bank.gd。
##   ・第一章：有意義嗎、裂開的寶石、共軛相乘、光柱積木、解方程、提公因式、代換、找關係式、速算
##   ・第二章：已知 a^{2x}、回音往上爬、往下開根號、開立方、折紙到月球、兩筆資料反求、發光礦石、選模型、代公式、賽跑、速算
##   ・新的圖上元件（num_field.gd）：pillar 光柱積木（pdrag、stack）、gems 等號寶石（etap）、fold 折紙、glow 發光礦石、race 賽跑
## 速算：law（指數律，按鈕）、grow（倍增與減半、a + a^{−1}，按鈕）

const BankE1 := preload("res://data/levels/h1exp/exp1_bank.gd")

const CHAPTERS_E1 := [
	{"ch": 1, "name": "第一章．光柱積木", "topic": "指數律", "color": UITheme.ORANGE},
	{"ch": 2, "name": "第二章．回音與倍增", "topic": "乘法公式與指數的應用", "color": UITheme.GOLD},
]


func level_id() -> String:
	return "E1"

func level_title() -> String:
	return "倍增岩壁"

func level_subtitle() -> String:
	return "指數律"

func level_chapters() -> Array:
	return CHAPTERS_E1

func bank_slots() -> Array:
	return BankE1.slots()

func step_color() -> Color:
	return UITheme.ORANGE

func scene_theme() -> String:
	return "echo"

func chapter_card() -> Dictionary:
	return {"title": "第二章．回音與倍增", "button": "出發  ▶",
		"text": "岩壁上的光柱都亮了，往下走進回音岩洞：\n\n" \
			+ "・知道 a + a^{−1}，一階一階往上爬\n" \
			+ "・每天變幾倍、每幾年減半\n" \
			+ "・先猜，再算\n\n" \
			+ "出發吧！"}


# ================= 速算 =================

func _speed_tag() -> String:
	return BankE1.T_LAW if String(r.get("gen", "")) == "law" else BankE1.T_GROW


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


static func _shuffle3(ans: String, w1: String, w2: String) -> Dictionary:
	var opts := [ans, w1, w2]
	var order := [0, 1, 2]
	order.shuffle()
	var choices := []
	for i in order:
		choices.append(opts[i])
	return {"choices": choices, "correct": order.find(0)}


static func _q(p: int, q: int) -> String:
	var g := _gcd(p, q)
	p /= g
	q /= g
	if q < 0:
		p = -p
		q = -q
	if q == 1:
		return str(p).replace("-", "−")
	return ("−" if p < 0 else "") + "\\frac{%d}{%d}" % [absi(p), q]


## 速算題：
##   law   a^{\frac{1}{p}} × a^{\frac{1}{q}}（按鈕：相加、相乘、相減）、∛{x^{m}} = x^{?}（\frac{m}{n}、\frac{n}{m}、m − n）、
##         4^{x} = c ⇒ 8^{x}（c√c、\frac{3c}{2}、c^{3}）
##   grow  每 n 天變 k 倍，t 天後（k^{t/n}、\frac{kt}{n}、k^{t/n − 1}）、a + a^{−1} = m ⇒ a^{2} + a^{−2}（m^{2} − 2、m^{2} + 2、m^{2}）、
##         半衰期 T，t = jT 年後剩（\frac{1}{2^{j}}、\frac{1}{2j}、\frac{1}{j + 1}）
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		var pb := {}
		var ans := ""
		var w1 := ""
		var w2 := ""
		var typ := randi() % 3
		if kind == "law":
			if typ == 0:
				var b: int = [2, 3, 5][randi() % 3]
				var p := randi_range(2, 6)
				var q := randi_range(2, 6)
				if p == q:
					continue
				pb = {"eq": "%d^{\\frac{1}{%d}} × %d^{\\frac{1}{%d}} = ？" % [b, p, b, q], "nudge": "同底數相乘，指數相加。"}
				ans = "%d^{%s}" % [b, _q(p + q, p * q)]
				w1 = "%d^{%s}" % [b, _q(1, p * q)]
				w2 = "%d^{%s}" % [b, _q(q - p, p * q)]
			elif typ == 1:
				var m := randi_range(2, 7)
				var r := randi_range(3, 4)
				if m == r or _gcd(m, r) != 1:
					continue
				var rs: String = "∛" if r == 3 else "∜"
				pb = {"eq": "%s{x^{%d}} = x^{?}（x > 0）" % [rs, m], "nudge": "開 n 次方根就是 \\frac{1}{n} 次方。"}
				ans = "x^{%s}" % _q(m, r)
				w1 = "x^{%s}" % _q(r, m)
				w2 = "x^{%d}" % (m - r)
			else:
				var c := randi_range(2, 7)
				if _square(c):
					continue
				pb = {"eq": "4^{x} = %d，8^{x} = ？" % c, "nudge": "2^{x} = √%d，8^{x} = (2^{x})^{3}。" % c}
				ans = "%d√%d" % [c, c]
				w1 = _q(3 * c, 2)
				w2 = str(c * c * c)
			pb["tag"] = BankE1.T_LAW
		else:
			if typ == 0:
				var k := randi_range(2, 3)
				var nd := randi_range(2, 5)
				var j := randi_range(2, 4)
				var t := nd * j
				pb = {"eq": "每 %d 天變 %d 倍，%d 天後變幾倍？" % [nd, k, t], "nudge": "%d 天裡結算 %d 次。" % [t, j]}
				ans = str(int(pow(k, j)))
				w1 = str(k * j)
				w2 = str(int(pow(k, j - 1)))
			elif typ == 1:
				var m := randi_range(3, 9)
				pb = {"eq": "a + a^{−1} = %d，a^{2} + a^{−2} = ？" % m, "nudge": "(%d)^{2} − 2。" % m}
				ans = str(m * m - 2)
				w1 = str(m * m + 2)
				w2 = str(m * m)
			else:
				var tt := randi_range(2, 8)
				var j := randi_range(2, 4)
				pb = {"eq": "半衰期 %d 年，%d 年後剩幾分之幾？" % [tt, tt * j], "nudge": "減半 %d 次。" % j}
				ans = _q(1, int(pow(2, j)))
				w1 = _q(1, 2 * j)
				w2 = _q(1, j + 1)
			pb["tag"] = BankE1.T_GROW
		if ans == w1 or ans == w2 or w1 == w2:
			continue
		pb.merge(_shuffle3(ans, w1, w2))
		pb["q"] = "點一個"
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out
