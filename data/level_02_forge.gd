extends "step_level.gd"
## 第二大關「換元鍛造所」（對應講義 重點二：指數方程式）
## 用法：主選單會自動開啟它。引擎在 step_level.gd（所有單元共用的步驟推導），題庫在 level02_bank.gd。
##
## 三種旅程（題庫說明見 level02_bank.gd）：
##   forge  一步一步鍛造：選擇換元 → 用數字鍵盤填係數、解 t → 篩掉不合的 t → 換回 x。
##          每一步答對就寫進左邊的「鍛造紀錄」，最後是一份完整的計算過程。
##   speed  速算爐：限時連續解化同底的方程式，題目每次重新產生。
##   tune   參數調頻：拖動參數，看 t 的拋物線和「合格區」(t > 0 或 t > 1) 的關係，再回答範圍題。
## 也可以用實體鍵盤輸入：數字、−、/、Backspace、Enter（送出）、Tab（下一格）。

const Bank2 := preload("level02_bank.gd")
const CHAPTERS2 := [
	{"ch": 1, "name": "第一章．同底熔爐", "topic": "化同底、換元與 t > 0", "color": Color("ffb454")},
	{"ch": 2, "name": "第二章．大師工坊", "topic": "成立條件、分解、聯立與參數", "color": Color("ff7e6b")},
]

func level_id() -> String:
	return "L2"

func level_title() -> String:
	return "換元鍛造所"

func level_subtitle() -> String:
	return "指數方程式：化同底與變數變換"

func level_chapters() -> Array:
	return CHAPTERS2

func bank_slots() -> Array:
	return Bank2.slots()

func stage_style() -> Dictionary:
	return {"sky_top": Color("24121f"), "sky_bot": Color("3a1b10"), "scenery": "none"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．大師工坊", "button": "進入大師工坊  ▶",
		"text": "大師的四種絕招：\n\n" \
			+ "・a^{x} + a^{−x} 整塊換元，記得 t ≥ 2\n" \
			+ "・四項的方程式：兩兩分組提公因式\n" \
			+ "・互為倒數的底數：(2 − √3)^{x} = 1/t\n" \
			+ "・兩根之和：a^{α+β} = t₁t₂\n\n" \
			+ "還有會轉動的參數旋鈕……"}


## 速算爐：化同底的方程式
func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


func _speed_tag() -> String:
	return "exp_eq_base"


## 產生 n 道不重複的化同底題目：{eq, ans, nudge, check}
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 5000:
		guard += 1
		var pb := _gen_pow1() if kind == "pow1" else _gen_pow2()
		if pb.is_empty() or seen.has(pb.eq):
			continue
		seen[pb.eq] = true
		out.append(pb)
	return out


static func _lin(p: int, q: int) -> String:
	var s := "x" if p == 1 else ("−x" if p == -1 else ("%dx" % p if p > 0 else "−%dx" % -p))
	if q > 0:
		s += " + %d" % q
	elif q < 0:
		s += " − %d" % -q
	return s


static func _qtext(num: int, den: int) -> String:
	if den < 0:
		num = -num
		den = -den
	var g := _gcd(absi(num), den)
	num /= g
	den /= g
	var t := str(absi(num)) if den == 1 else "%d/%d" % [absi(num), den]
	return ("−" if num < 0 else "") + t


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return maxi(a, 1)


## b^{px + q} = N
static func _gen_pow1() -> Dictionary:
	var b: int = [2, 2, 3, 3, 5].pick_random()
	var lim := {2: [-5, 7], 3: [-4, 5], 5: [-3, 4]}[b] as Array
	var p: int = [1, 1, 2, 3, -1].pick_random()
	var k := randi_range(lim[0], lim[1])
	var q := randi_range(-3, 3)
	var num := k - q
	var den := p
	if den < 0:
		num = -num
		den = -den
	if num % den != 0 and den != 2:
		return {}
	var rhs := str(int(pow(b, k))) if k >= 0 else "1/%d" % int(pow(b, -k))
	var eq := "%d^{%s} = %s" % [b, _lin(p, q), rhs]
	var x0 := float(num) / den
	return {"eq": eq, "ans": _qtext(num, den),
		"nudge": "把 %s 寫成 %d 的次方：%s = %d^{%s}，再讓指數相等。" % [rhs, b, rhs, b, str(k).replace("-", "−")],
		"check": pow(float(b), p * x0 + q) - pow(float(b), k)}


static func _base_text(b: int, m: int) -> String:
	return str(int(pow(b, m))) if m > 0 else "(1/%d)" % int(pow(b, -m))


## (b^m)^{px + q} = (b^n)^{rx + s}
static func _gen_pow2() -> Dictionary:
	var b: int = [2, 2, 3].pick_random()
	var ms := [-2, -1, 1, 2, 3]
	var m: int = ms.pick_random()
	var n: int = ms.pick_random()
	if m == n or (m == 1 and n == 1):
		return {}
	var p: int = [1, 1, 2].pick_random()
	var rr: int = [1, 1, 2].pick_random()
	var q := randi_range(-3, 3)
	var x0 := randi_range(-3, 3)
	if m * p == n * rr:
		return {}
	var s_num := m * (p * x0 + q) - n * rr * x0
	if s_num % n != 0:
		return {}
	var s := s_num / n
	if absi(s) > 4:
		return {}
	var eq := "%s^{%s} = %s^{%s}" % [_base_text(b, m), _lin(p, q), _base_text(b, n), _lin(rr, s)]
	var bm := pow(float(b), m)
	var bn := pow(float(b), n)
	return {"eq": eq, "ans": _qtext(x0, 1),
		"nudge": "兩邊都化成 %d 的次方：%s = %d^{%s}、%s = %d^{%s}，指數要乘開。" % [b, _base_text(b, m), b,
			str(m).replace("-", "−"), _base_text(b, n), b, str(n).replace("-", "−")],
		"check": pow(bm, p * x0 + q) - pow(bn, rr * x0 + s)}
