extends RefCounted
## 三角函數（高二上）的終焉之塔題庫
##   考法參考各校 113、114 學年度高二第一次段考（建中、北一女、師大附中、成功、中山女中、松山、大同、板橋）；
##   數字、情境全部換過，答案都用程式驗算過。用到高一教過的正弦定理、餘弦定理、極坐標也照收。
##
## 題目的格式和 poly_tower_bank.gd 一樣（id、kind、tier、title、stem、tmul、plot、steps）。
##   座標圖的 "pi"：橫軸用 π 當刻度；"geo"：幾何圖（等比例、可以有 shapes、會動的 groups），見 boss_tower.gd 的 Plot。
##   曲線的式子可以寫 PI（items() 會換成數字）。
##   填空的鍵盤和三角函數八大關一樣有「√」鍵；π 寫在格子外面，格子只填係數（[0]π）。
const UITheme := preload("res://data/ui/game_theme.gd")

const RADICALS := true

const KIND_NAME := {"judge": "判讀羅盤", "graph": "波形辨識", "cross": "交點潮汐", "angle": "角的鍛造",
	"extreme": "疊合極值", "quest": "海岸委託", "boss": "試煉大題"}
const KIND_COLOR := {"judge": UITheme.CYAN, "graph": UITheme.VIOLET, "cross": UITheme.LIME, "angle": UITheme.PINK,
	"extreme": UITheme.ORANGE, "quest": UITheme.GOLD, "boss": UITheme.ROSE}


static var _items: Array = []


static func items() -> Array:
	if _items.is_empty():
		_items = (_judge() + _graph() + _cross() + _angle() + _extreme() + _quest() + _boss()).duplicate(true)
		for it in _items:
			_fix_pi(it)
	return _items


static func by_id(id: String) -> Dictionary:
	for it in items():
		if it.id == id:
			return it
	return {}


## 曲線式子裡的 PI 換成數字（Godot 的 Expression 不認得 PI）
static func _fix_pi(v) -> void:
	if v is Dictionary:
		for k in v.keys():
			if k == "f" and v[k] is String:
				v[k] = String(v[k]).replace("PI", "3.141592653589793")
			else:
				_fix_pi(v[k])
	elif v is Array:
		for e in v:
			_fix_pi(e)


## 選圖題的小圖：虛線（題目給的）＋實線（選項），橫軸用 π 當刻度
static func _g(solid: String, dashed := "", xr := [-0.6, 6.9], yr := [-3.0, 3.0]) -> Dictionary:
	var cs := []
	if dashed != "":
		cs.append({"f": dashed, "c": "dim", "dash": true})
	cs.append({"f": solid, "c": "cyan"})
	return {"x": xr, "y": yr, "pi": 2, "curves": cs}


# ================= 判讀羅盤（多選、是非） =================

static func _judge() -> Array:
	return [
	{"id": "tj_radian", "kind": "judge", "tier": 1, "title": "沒有度的角", "tmul": 1.0,
		"stem": "角度沒寫 ° 的都是弧度。不查表，判斷下列敘述。",
		"steps": [{"t": "judge", "q": "1 弧度 ≈ 57.3°，先把角換成大約的度數，看在第幾象限。", "cards": [
			{"s": "sin 2 > sin 1", "ok": true, "why": "sin 2 = sin(π − 2)，π − 2 ≈ 1.14 比 1 大，而且都在第一象限"},
			{"s": "cos 3 > 0", "ok": false, "why": "3 ≈ 172°，在第二象限，cos 3 < 0"},
			{"s": "tan 4 > 0", "ok": true, "why": "4 ≈ 229°，在第三象限，tan 是正的"},
			{"s": "sin 6 < 0", "ok": true, "why": "6 ≈ 344°，在第四象限"},
			{"s": "sin 1° > sin 1", "ok": false, "why": "1° 比 1 弧度（≈ 57.3°）小很多，sin 1° 比較小"}]}]},

	{"id": "tj_sign", "kind": "judge", "tier": 1, "title": "象限與正負", "tmul": 1.1,
		"stem": "tan θ = −8/15，且 3π/2 < θ < 2π。下列敘述哪些正確？",
		"steps": [{"t": "judge", "q": "第四象限：sin θ < 0、cos θ > 0。邊長 8、15、17。", "cards": [
			{"s": "sin θ = −8/17", "ok": true, "why": "第四象限 sin 是負的，sin θ = −8/17、cos θ = 15/17"},
			{"s": "cos 2θ = 161/289", "ok": true, "why": "cos^{2}θ − sin^{2}θ = (225 − 64)/289"},
			{"s": "sin 2θ > 0", "ok": false, "why": "2 sin θ cos θ = 2 · (−8/17) · (15/17) < 0"},
			{"s": "θ/2 在第二象限", "ok": true, "why": "3π/4 < θ/2 < π"},
			{"s": "tan(θ/2) = −4", "ok": false, "why": "tan(θ/2) = (1 − cos θ)/sin θ = (2/17)/(−8/17) = −1/4"}]}]},

	{"id": "tj_period", "kind": "judge", "tier": 1, "title": "週期是 π", "tmul": 1.0,
		"stem": "下列哪些函數的週期是 π？",
		"steps": [{"t": "judge", "q": "先化成 sin、cos 一次的樣子，或想想絕對值把圖形怎麼折。", "cards": [
			{"s": "y = |sin x|", "ok": true, "why": "負的那一半翻上來，每 π 重複一次"},
			{"s": "y = cos^{2} x", "ok": true, "why": "cos^{2} x = (1 + cos 2x)/2"},
			{"s": "y = tan(x/2)", "ok": false, "why": "週期是 π/(1/2) = 2π"},
			{"s": "y = sin 2x + cos x", "ok": false, "why": "兩個週期 π、2π 的最小公倍數是 2π"},
			{"s": "y = |sin x + cos x|", "ok": true, "why": "= |√{2} sin(x + π/4)|，週期 π"}]}]},

	{"id": "tj_shift", "kind": "judge", "tier": 2, "title": "伸縮平移的順序", "tmul": 1.15,
		"stem": "把 y = sin x 的圖形做下列變換，哪些敘述正確？（水平伸縮以 y 軸為基準）",
		"steps": [{"t": "judge", "q": "平移：x 換成 x ∓ h。伸縮：x 換成 x/k。照順序換。", "cards": [
			{"s": "右移 π/3：y = sin(x − π/3)", "ok": true, "why": "右移 h：x 換成 x − h"},
			{"s": "先水平縮成 1/2 倍、再左移 π/6：y = sin(2x + π/6)", "ok": false, "why": "先得 sin 2x，再左移：sin 2(x + π/6) = sin(2x + π/3)"},
			{"s": "先左移 π/6、再水平縮成 1/2 倍：y = sin(2x + π/6)", "ok": true, "why": "先得 sin(x + π/6)，再把 x 換成 2x"},
			{"s": "鉛直伸長 3 倍、再上移 1：y = 3 sin x + 1", "ok": true, "why": "先乘 3 再加 1"},
			{"s": "左移 π/2：y = −cos x", "ok": false, "why": "sin(x + π/2) = cos x"}]}]},

	{"id": "tj_sym", "kind": "judge", "tier": 2, "title": "對稱軸與對稱中心", "tmul": 1.15,
		"stem": "f(x) = 2 sin(2x − π/3) + 1。下列敘述哪些正確？",
		"steps": [{"t": "judge", "q": "令 u = 2x − π/3：u = π/2 + kπ 是對稱軸，u = kπ 是對稱中心。", "cards": [
			{"s": "直線 x = 5π/12 是圖形的對稱軸", "ok": true, "why": "2x − π/3 = π/2 ⇒ x = 5π/12（最高點）"},
			{"s": "點 (π/6, 1) 是圖形的對稱中心", "ok": true, "why": "2x − π/3 = 0 ⇒ x = π/6，此時 f = 1（在中線上）"},
			{"s": "f(x) 的最小值是 −1", "ok": true, "why": "−2 + 1 = −1"},
			{"s": "0 ≤ x ≤ π/2 時，f(x) 遞增", "ok": false, "why": "u 從 −π/3 到 2π/3，過了 π/2（x = 5π/12）就開始遞減"},
			{"s": "f(x) 的週期是 2π", "ok": false, "why": "週期 2π/2 = π"}]}]},

	{"id": "tj_fold", "kind": "judge", "tier": 2, "title": "疊合的性質", "tmul": 1.15,
		"stem": "f(x) = √{3} sin x − cos x。下列敘述哪些正確？",
		"steps": [{"t": "judge", "q": "先疊合：√{3} sin x − cos x = 2(sin x · √{3}/2 − cos x · 1/2)。", "cards": [
			{"s": "f(x) = 2 sin(x − π/6)", "ok": true, "why": "cos(π/6) = √{3}/2、sin(π/6) = 1/2"},
			{"s": "f(x) 的最大值是 √{3} + 1", "ok": false, "why": "最大值是 √{3 + 1} = 2"},
			{"s": "x = 2π/3 時 f(x) 有最大值", "ok": true, "why": "x − π/6 = π/2"},
			{"s": "0 ≤ x < 2π 時，f(x) = 1 恰有兩個解", "ok": true, "why": "sin(x − π/6) = 1/2 ⇒ x − π/6 = π/6、5π/6 ⇒ x = π/3、π"},
			{"s": "y = f(x) 的圖形對稱於原點", "ok": false, "why": "f(0) = −1 ≠ 0，圖形不過原點"}]}]},

	{"id": "tj_always", "kind": "judge", "tier": 1, "title": "恆成立嗎", "tmul": 1.0,
		"stem": "當 π/4 < x < π/2 時，下列哪些不等式恆成立？",
		"steps": [{"t": "judge", "q": "先寫出 2x、x + π/4 的範圍。", "cards": [
			{"s": "sin 2x > 0", "ok": true, "why": "π/2 < 2x < π，第二象限 sin > 0"},
			{"s": "cos 2x > 0", "ok": false, "why": "第二象限 cos < 0"},
			{"s": "sin x > cos x", "ok": true, "why": "x > π/4 以後 sin 比 cos 大"},
			{"s": "tan x > 1", "ok": true, "why": "tan(π/4) = 1，tan 在這裡遞增"},
			{"s": "sin x + cos x > √{2}", "ok": false, "why": "= √{2} sin(x + π/4)，最大才 √{2}，而且到不了"}]}]},

	{"id": "tj_case", "kind": "judge", "tier": 3, "title": "兩種可能", "tmul": 1.3,
		"stem": "sin α = 4/5，sin β = 5/13，且 cos α · cos β < 0。下列敘述哪些正確？",
		"steps": [{"t": "judge", "q": "cos α、cos β 一正一負：(3/5, −12/13) 或 (−3/5, 12/13)，兩種都要算。", "cards": [
			{"s": "cos(α − β) 只有一個可能的值", "ok": true, "why": "cos α cos β + sin α sin β = −36/65 + 20/65 = −16/65，兩種情形一樣"},
			{"s": "sin(α + β) 只有一個可能的值", "ok": false, "why": "第一種 −48/65 + 15/65 = −33/65，第二種 48/65 − 15/65 = 33/65"},
			{"s": "cos(α + β) = −56/65", "ok": true, "why": "cos α cos β − sin α sin β = −36/65 − 20/65"},
			{"s": "sin(α − β) 可能是 63/65", "ok": true, "why": "第二種：sin α cos β − cos α sin β = 48/65 + 15/65"},
			{"s": "tan α tan β > 0", "ok": false, "why": "sin α sin β > 0、cos α cos β < 0，所以 tan α tan β < 0"}]}]},

	{"id": "tj_compare", "kind": "judge", "tier": 3, "title": "三個數比大小", "tmul": 1.3,
		"stem": "0 < x < π/4，a = sin x、b = tan(x/2)、c = sin(x°)。下列哪些恆成立？",
		"steps": [{"t": "judge", "q": "以切表弦：tan(x/2) = sin x/(1 + cos x)。x° 是 x 的 π/180 倍。", "cards": [
			{"s": "a > b", "ok": true, "why": "b = sin x/(1 + cos x)，分母大於 1"},
			{"s": "b < c", "ok": false, "why": "b > x/2 > πx/180 > c：x° 小非常多"},
			{"s": "a > c", "ok": true, "why": "x° 比 x 弧度小，sin 在 0 到 π/2 遞增"},
			{"s": "a < √{2}/2", "ok": true, "why": "x < π/4 ⇒ sin x < sin(π/4)"},
			{"s": "2b < a", "ok": false, "why": "2b = 2 sin x/(1 + cos x)，分母小於 2，所以 2b > a"}]}]},

	{"id": "tj_truefalse", "kind": "judge", "tier": 2, "title": "觀念是非", "tmul": 1.15,
		"stem": "判斷下列敘述是否正確。",
		"steps": [{"t": "judge", "q": "說「一定」的，找一個反例就是假的。", "cards": [
			{"s": "有實數 x 使得 cos x = 3/√{7}", "ok": false, "why": "3/√{7} = √{9/7} > 1"},
			{"s": "若 sin 2x = sin 2y，且 0 < x、y < π/2，則 x = y", "ok": false, "why": "反例 x = π/6、y = π/3：sin(π/3) = sin(2π/3)"},
			{"s": "若 cos 2x = cos 2y，且 0 < x、y < π/2，則 x = y", "ok": true, "why": "0 < 2x、2y < π，cos 在這裡一對一"},
			{"s": "0 ≤ θ ≤ π/2 時，sin θ ≤ θ", "ok": true, "why": "單位圓上，弦（2 sin θ）比弧（2θ）短"},
			{"s": "tan 3 > 0", "ok": false, "why": "3 ≈ 172°，在第二象限"}]}]},

	{"id": "tj_root", "kind": "judge", "tier": 3, "title": "根號裡的倍角", "tmul": 1.3,
		"stem": "3π/4 < θ < π，A = √{1 + sin 2θ} + √{1 − sin 2θ}。下列哪些正確？",
		"steps": [{"t": "judge", "q": "1 ± sin 2θ = (sin θ ± cos θ)^{2}，開根號要加絕對值。", "cards": [
			{"s": "1 + sin 2θ = (sin θ + cos θ)^{2}", "ok": true, "why": "sin^{2}θ + cos^{2}θ + 2 sin θ cos θ"},
			{"s": "sin θ + cos θ > 0", "ok": false, "why": "θ 在 3π/4 和 π 之間，|cos θ| > sin θ，和是負的"},
			{"s": "A = −2 cos θ", "ok": true, "why": "A = −(sin θ + cos θ) + (sin θ − cos θ)"},
			{"s": "A = 2 sin θ", "ok": false, "why": "這是兩個都當成正的才會得到的"},
			{"s": "θ = 5π/6 時，A = √{3}", "ok": true, "why": "−2 cos(5π/6) = √{3}"}]}]},

	{"id": "tj_graph", "kind": "judge", "tier": 2, "title": "同一條波", "tmul": 1.2,
		"stem": "圖是一個正弦波的一部分，最高點 (π/12, 2)、和 x 軸交於 (−π/6, 0)。下列哪些函數的圖形就是它？",
		"plot": {"x": [-1.2, 3.6], "y": [-2.6, 2.6], "pi": 12, "pi_lab": 6,
			"curves": [{"f": "2*sin(2*x+PI/3)", "c": "cyan"}],
			"pts": [{"x": 0.2618, "y": 2, "label": "(π/12, 2)"}, {"x": -0.5236, "y": 0, "label": ""}]},
		"steps": [{"t": "judge", "q": "振幅 2、週期 π，最高點在 x = π/12：代進去看是不是最大值。", "cards": [
			{"s": "y = 2 sin(2x + π/3)", "ok": true, "why": "x = π/12：2x + π/3 = π/2"},
			{"s": "y = 2 cos(2x − π/6)", "ok": true, "why": "x = π/12：2x − π/6 = 0，cos 0 = 1"},
			{"s": "y = −2 sin(2x − 2π/3)", "ok": true, "why": "x = π/12：−2 sin(−π/2) = 2"},
			{"s": "y = 2 sin(2x + π/6)", "ok": false, "why": "x = π/12：2 sin(π/3) = √{3}，不是最大值"},
			{"s": "y = 2 sin 2(x + π/3)", "ok": false, "why": "= 2 sin(2x + 2π/3)，x = π/12 時是 2 sin(5π/6) = 1"}]}]},
	]


# ================= 波形辨識 =================

static func _graph() -> Array:
	return [
	{"id": "tg_read", "kind": "graph", "tier": 1, "title": "看圖寫式子", "tmul": 1.0,
		"stem": "圖是 y = a sin(bx + c) + d 的一段（a > 0、b > 0、0 ≤ c < 2π），最高點 (π/6, 5)，相鄰的最低點 (2π/3, −1)。求 a、b、c、d。",
		"plot": {"x": [-0.4, 3.4], "y": [-1.8, 5.8], "pi": 6, "pi_lab": 6,
			"curves": [{"f": "3*sin(2*x+PI/6)+2", "c": "cyan"}],
			"pts": [{"x": 0.5236, "y": 5, "label": "(π/6, 5)"}, {"x": 2.0944, "y": -1, "label": "(2π/3, −1)", "off": [-60, 20]}]},
		"steps": [
			{"t": "fill", "q": "振幅和中線：", "template": "a = (5 − (−1))/2 = [0]，d = (5 + (−1))/2 = [1]", "ans": ["3", "2"],
				"hint": "a 是最高和最低的差的一半，d 是平均"},
			{"t": "fill", "q": "最高到相鄰最低是半個週期：", "template": "T/2 = 2π/3 − π/6 ⇒ T = π ⇒ b = [0]", "ans": ["2"],
				"hint": "b = 2π/T"},
			{"t": "fill", "q": "最高點時 bx + c = π/2：", "template": "2 · π/6 + c = π/2 ⇒ c = [0]π", "ans": ["1/6"],
				"hint": "π/2 − π/3"}]},

	{"id": "tg_pick", "kind": "graph", "tier": 1, "title": "認出那條波", "tmul": 1.0,
		"stem": "(1) 哪一張的實線是 y = 2 sin(x − π/4)？（虛線是 y = 2 sin x）\n(2) 它和 y 軸交於 (0, k)，求 k",
		"steps": [
			{"t": "pick", "q": "哪一張的實線是 y = 2 sin(x − π/4)？",
				"graphs": [
					_g("2*sin(x-PI/4)", "2*sin(x)"),
					_g("2*sin(x+PI/4)", "2*sin(x)"),
					_g("2*sin(2*x-PI/4)", "2*sin(x)"),
					_g("-2*sin(x-PI/4)", "2*sin(x)"),
					_g("sin(x-PI/4)", "2*sin(x)")],
				"whys": ["", "這是往左移 π/4", "週期變成 π 了", "上下翻轉了", "振幅只有 1"],
				"hint": "x − π/4：整條波往右移 π/4，振幅還是 2",
				"write": "y = 2 sin(x − π/4)：往右移 π/4，振幅 2"},
			{"t": "fill", "q": "(2) x = 0 代入：", "template": "k = 2 sin(−π/4) = [0]", "ans": ["−√2"],
				"hint": "sin(−π/4) = −√{2}/2"}]},

	{"id": "tg_steps", "kind": "graph", "tier": 2, "title": "四個步驟", "tmul": 1.2,
		"stem": "y = sin x 依序 ① 鉛直伸縮 a 倍 ② 向左平移 b ③ 水平伸縮 c 倍 ④ 向上平移 d，得到 y = 3 sin(2x + π/2) − 1。\n(1) 求 a、b、c、d　(2) 若 ②、③ 對調，要向左平移多少？",
		"steps": [
			{"t": "fill", "part": "(1)", "q": "照順序把 x 換掉：sin(x + b) → sin(x/c + b) = sin(2x + π/2)。",
				"template": "a = [0]，b = [1]π，c = [2]，d = [3]", "ans": ["3", "1/2", "1/2", "−1"],
				"hint": "x/c = 2x ⇒ c = 1/2，b = π/2，向上平移 −1 就是往下 1"},
			{"t": "fill", "part": "(2)", "q": "先水平伸縮成 sin 2x，再左移 h：sin 2(x + h) = sin(2x + π/2)。",
				"template": "h = [0]π", "ans": ["1/4"], "hint": "2h = π/2"}]},

	{"id": "tg_cond", "kind": "graph", "tier": 2, "title": "從條件找波形", "tmul": 1.25,
		"stem": "f(x) = a sin(bx + c) + d（a > 0、b > 0、0 ≤ c < 2π），已知：\n① f(0) = f(4) = f(12) = 1　② 0 < x < 4 時 f(x) > 1\n③ 4 < x < 12 時 f(x) < 1　④ f 的最大值是 5。求 a、b、c、d。",
		"plot": {"x": [-1.0, 13.0], "y": [-12.0, 6.5],
			"curves": [{"f": "8*sin(PI/6*x+PI/6)-3", "c": "cyan", "at": 3}, {"f": "1", "c": "faint", "dash": true}],
			"pts": [{"x": 0, "y": 1, "label": ""}, {"x": 4, "y": 1, "label": ""}, {"x": 12, "y": 1, "label": ""},
				{"x": 2, "y": 5, "label": "(2, 5)", "at": 1}]},
		"steps": [
			{"t": "fill", "q": "從 0 開始，大於 1、小於 1，到 12 又回到 1：剛好一個週期。", "template": "T = [0]，b = 2π/T = [1]π", "ans": ["12", "1/6"],
				"hint": "0 到 12 走完「上去、下來」一整輪"},
			{"t": "fill", "q": "0 到 4 這一段在上面，最高點在中間。", "template": "最高點 x = [0]，最低點 x = [1]", "ans": ["2", "8"],
				"hint": "4 到 12 的中點是最低點"},
			{"t": "fill", "q": "最高點時 bx + c = π/2：", "template": "π/6 · 2 + c = π/2 ⇒ c = [0]π", "ans": ["1/6"], "hint": "π/2 − π/3"},
			{"t": "fill", "q": "用 f(0) = 1 和最大值 5：", "template": "a sin(π/6) + d = 1，a + d = 5 ⇒ a = [0]，d = [1]", "ans": ["8", "−3"],
				"hint": "a/2 + d = 1、a + d = 5，相減得 a/2 = 4"}]},

	{"id": "tg_tri", "kind": "graph", "tier": 3, "title": "波上的正三角形", "tmul": 1.3,
		"stem": "y = a sin(bx)（a > 0、b > 0）的圖形上，A(1, √{3}) 是一個最高點，A 和下一個最高點 B、以及它們之間的最低點 C 剛好是正三角形。\n求 a、b 與 C 的坐標。",
		"plot": {"x": [-0.6, 6.2], "y": [-2.4, 2.4],
			"curves": [{"f": "sqrt(3)*sin(PI/2*x)", "c": "cyan"}],
			"shapes": [{"k": "poly", "pts": [[1, 1.732], [5, 1.732], [3, -1.732]], "c": "gold", "fill": "gold", "alpha": 0.12, "at": 1}],
			"pts": [{"x": 1, "y": 1.732, "label": "A"}, {"x": 5, "y": 1.732, "label": "B", "at": 2}, {"x": 3, "y": -1.732, "label": "C", "at": 3}]},
		"steps": [
			{"t": "choice", "q": "設週期 T。△ABC 的邊長、高各是？", "opts": ["邊長 T，高 2a", "邊長 T/2，高 a", "邊長 T，高 a", "邊長 2T，高 2a"],
				"hint": "相鄰兩個最高點差一個週期，最高到最低的落差是 2a",
				"write": "\\ol{AB} = T，高 = 2a"},
			{"t": "fill", "q": "A 是最高點，再用正三角形的高 = (√{3}/2) × 邊長：", "template": "a = [0]，2a = (√{3}/2)T ⇒ T = [1]", "ans": ["√3", "4"],
				"hint": "最高點的 y 坐標就是 a"},
			{"t": "fill", "q": "週期 T = 4：", "template": "b = 2π/T = [0]π", "ans": ["1/2"], "hint": "2π/4"},
			{"t": "fill", "q": "C 在 A、B 的正中間，是最低點：", "template": "答：C([0], [1])", "ans": ["3", "−√3"],
				"hint": "B 的 x 坐標是 1 + T = 5"}]},

	{"id": "tg_squeeze", "kind": "graph", "tier": 2, "title": "壓縮後的波", "tmul": 1.1,
		"stem": "(1) 哪一張的實線是 y = sin(2x + π/3)？（虛線是 y = sin x）\n(2) x > 0 的第一個最高點，x 坐標是多少？",
		"steps": [
			{"t": "pick", "q": "哪一張的實線是 y = sin(2x + π/3)？",
				"graphs": [
					_g("sin(2*x+PI/3)", "sin(x)", [-0.6, 6.9], [-1.6, 1.6]),
					_g("sin(2*x+2*PI/3)", "sin(x)", [-0.6, 6.9], [-1.6, 1.6]),
					_g("sin(x/2+PI/3)", "sin(x)", [-0.6, 6.9], [-1.6, 1.6]),
					_g("sin(2*x-PI/3)", "sin(x)", [-0.6, 6.9], [-1.6, 1.6]),
					_g("sin(x+PI/3)", "sin(x)", [-0.6, 6.9], [-1.6, 1.6])],
				"whys": ["", "這是 sin 2(x + π/3)：左移太多了", "週期變成 4π 了", "這是往右移", "週期還是 2π"],
				"hint": "sin(2x + π/3) = sin 2(x + π/6)：週期 π，往左移 π/6",
				"write": "sin(2x + π/3) = sin 2(x + π/6)：週期 π，左移 π/6"},
			{"t": "fill", "q": "(2) 最高點時 2x + π/3 = π/2：", "template": "x = [0]π", "ans": ["1/12"], "hint": "2x = π/6"}]},

	{"id": "tg_center", "kind": "graph", "tier": 3, "title": "對稱中心定參數", "tmul": 1.3,
		"stem": "f(x) = 2 sin(ax − π/3) + b，a > 0，週期 T 滿足 2π/3 < T < π，且 y = f(x) 的圖形對稱於點 (π/2, −1)。求 a、b。",
		"steps": [
			{"t": "fill", "q": "對稱中心在中線上：", "template": "b = [0]", "ans": ["−1"], "hint": "中線是 y = b"},
			{"t": "fill", "q": "對稱中心的地方 sin 那一項是 0：a · π/2 − π/3 = kπ（k 是整數）。", "template": "a = 2k + [0]", "ans": ["2/3"],
				"hint": "a · π/2 = kπ + π/3，兩邊乘 2/π"},
			{"t": "fill", "q": "週期 T = 2π/a 在 2π/3 和 π 之間：", "template": "[0] < a < [1]", "ans": ["2", "3"], "hint": "T 越大 a 越小"},
			{"t": "fill", "q": "2k + 2/3 落在 2 和 3 之間：", "template": "答：a = [0]，b = −1", "ans": ["8/3"], "hint": "k = 1"}]},

	{"id": "tg_overlap", "kind": "graph", "tier": 2, "title": "移到重合", "tmul": 1.15,
		"stem": "y = sin(3x + π/4) 的圖形向右平移 h（h > 0）後，和 y = cos 3x 的圖形重合。求 h 的最小值。",
		"plot": {"x": [-0.3, 3.4], "y": [-1.5, 1.5], "pi": 12, "pi_lab": 4,
			"curves": [{"f": "cos(3*x)", "c": "dim", "dash": true}, {"f": "sin(3*x+PI/4)", "c": "cyan", "until": 2},
				{"f": "sin(3*(x-7*PI/12)+PI/4)", "c": "pink", "at": 2}]},
		"steps": [
			{"t": "choice", "q": "cos 3x 先寫成 sin：", "opts": ["sin(3x + π/2)", "sin(3x − π/2)", "sin(3x + π)", "−sin 3x"],
				"hint": "cos θ = sin(θ + π/2)", "write": "cos 3x = sin(3x + π/2)"},
			{"t": "fill", "pre": "右移 h：sin(3(x − h) + π/4) = sin(3x + π/2)", "q": "兩邊的角差 2π 的整數倍：", "template": "−3h + π/4 = π/2 + 2kπ ⇒ h = −π/12 − [0]kπ", "ans": ["2/3"],
				"hint": "兩邊同減 π/4，再除以 −3"},
			{"t": "fill", "q": "取 h > 0 的最小值：", "template": "答：h = [0]π", "ans": ["7/12"], "hint": "k = −1"}]},
	]


# ================= 交點潮汐 =================

static func _cross() -> Array:
	return [
	{"id": "tc_count", "kind": "cross", "tier": 1, "title": "直線穿過波", "tmul": 1.0,
		"stem": "方程式 sin(πx) = x/3 有幾個實根？",
		"plot": {"x": [-3.6, 3.6], "y": [-1.5, 1.5],
			"curves": [{"f": "sin(PI*x)", "c": "cyan", "at": 1}, {"f": "x/3", "c": "pink", "at": 1}]},
		"steps": [
			{"t": "choice", "q": "交點的 x 一定在哪個範圍？", "opts": ["−3 ≤ x ≤ 3", "−1 ≤ x ≤ 1", "0 ≤ x ≤ 3", "全體實數"],
				"hint": "|sin(πx)| ≤ 1，所以 |x/3| ≤ 1", "write": "|x/3| ≤ 1 ⇒ −3 ≤ x ≤ 3"},
			{"t": "fill", "q": "看圖：x > 0 的交點有幾個？", "template": "x > 0：[0] 個", "ans": ["3"],
				"hint": "0 到 1 一個，2 到 3 那個波峰被直線切過兩次"},
			{"t": "fill", "q": "兩邊都是奇函數，圖形對稱於原點：", "template": "答：共 [0] 個實根", "ans": ["7"], "hint": "左右各 3 個，再加原點"}]},

	{"id": "tc_sum", "kind": "cross", "tier": 1, "title": "解的總和", "tmul": 1.0,
		"stem": "求方程式 cos x = −1/5 在 −2π ≤ x ≤ 4π 的所有解的和。",
		"plot": {"x": [-6.6, 12.9], "y": [-1.4, 1.4], "pi": 1, "pi_up": true,
			"curves": [{"f": "cos(x)", "c": "cyan"}, {"f": "-0.2", "c": "pink", "dash": true}]},
		"steps": [
			{"t": "fill", "q": "先看 0 ≤ x ≤ 2π 這一段：", "template": "有 [0] 個解，對稱於 x = [1]π", "ans": ["2", "1"],
				"hint": "cos 的圖形在一個週期內對稱於最低點"},
			{"t": "fill", "q": "−2π 到 4π 有三個週期，每一段的兩個解都對稱於該段的中點：", "template": "答：和 = 2(−π) + 2π + 2(3π) = [0]π", "ans": ["6"],
				"hint": "三段的中點是 −π、π、3π"}]},

	{"id": "tc_center", "kind": "cross", "tier": 2, "title": "對稱中心配對", "tmul": 1.15,
		"stem": "方程式 sin 2x = (x − π)/2 的所有實數解的和是多少？",
		"plot": {"x": [0.6, 5.7], "y": [-1.4, 1.4], "pi": 4,
			"curves": [{"f": "sin(2*x)", "c": "cyan"}, {"f": "(x-PI)/2", "c": "pink"}],
			"pts": [{"x": 3.1416, "y": 0, "label": "(π, 0)", "off": [6, 20]}]},
		"steps": [
			{"t": "choice", "q": "令 u = x − π，方程式變成？", "opts": ["sin 2u = u/2", "−sin 2u = u/2", "sin 2u = (u − π)/2", "cos 2u = u/2"],
				"hint": "sin(2u + 2π) = sin 2u", "write": "u = x − π：sin 2u = u/2（兩邊都是 u 的奇函數）"},
			{"t": "fill", "q": "看圖數交點（u 的解正負成對，加上 u = 0）：", "template": "共 [0] 個解", "ans": ["3"],
				"hint": "|u/2| ≤ 1 ⇒ |u| ≤ 2，第二個波峰已經在 u = 2 外面"},
			{"t": "fill", "q": "u 的解加起來是 0，換回 x = u + π：", "template": "答：所有解的和 = [0]π", "ans": ["3"], "hint": "每個解都加 π"}]},

	{"id": "tc_tan", "kind": "cross", "tier": 2, "title": "tan 和直線", "tmul": 1.15,
		"stem": "方程式 tan x = 1 − x 在 −π < x < 2π 有幾個實根？",
		"plot": {"x": [-3.3, 6.45], "y": [-6.0, 6.0], "pi": 2,
			"curves": [{"f": "tan(x)", "c": "cyan"}, {"f": "1-x", "c": "pink"}],
			"vlines": [{"x": -1.5708}, {"x": 1.5708}, {"x": 4.7124}]},
		"steps": [
			{"t": "fill", "q": "漸近線 x = −π/2、π/2、3π/2 把 tan 的圖形切成幾段？", "template": "[0] 段", "ans": ["4"],
				"hint": "−π 到 2π 之間有三條漸近線"},
			{"t": "fill", "q": "每一段 tan 從 −∞ 到 ∞（或從 0 出發），直線只穿過一次：", "template": "答：共 [0] 個實根", "ans": ["4"],
				"hint": "最左、最右兩段只有半條，也要看端點的高低"}]},

	{"id": "tc_abs", "kind": "cross", "tier": 3, "title": "絕對值的波", "tmul": 1.3,
		"stem": "方程式 4π sin|x| + x = 0 有幾個實數解？",
		"plot": {"x": [-13.0, 13.0], "y": [-1.5, 1.5], "pi": 1,
			"curves": [{"f": "sin(abs(x))", "c": "cyan"}, {"f": "-x/(4*PI)", "c": "pink"}]},
		"steps": [
			{"t": "fill", "pre": "4π sin|x| + x = 0 ⇒ sin|x| = −x/(4π)", "q": "看圖：先數 x ≥ 0（右半邊，含原點）：", "template": "x ≥ 0：[0] 個", "ans": ["5"],
				"hint": "|x/(4π)| ≤ 1 ⇒ |x| ≤ 4π。右邊直線往下，和 π 到 2π、3π 到 4π 的波谷各交兩次"},
			{"t": "fill", "q": "x < 0（左半邊）：sin|x| 是左右對稱的，直線在這邊往上。", "template": "x < 0：[0] 個 ⇒ 共 [1] 個", "ans": ["3", "8"],
				"hint": "−π 到 0 的波峰一次，−3π 到 −2π 的波峰兩次"}]},

	{"id": "tc_double", "kind": "cross", "tier": 2, "title": "倍角方程式", "tmul": 1.15,
		"stem": "求方程式 sin 2x = √{2} sin x 在 0 ≤ x ≤ 2π 的所有解的和。",
		"steps": [
			{"t": "choice", "q": "sin 2x 展開，再提出公因式：", "opts": ["sin x(2 cos x − √{2}) = 0", "sin x(2 cos x + √{2}) = 0", "cos x(2 sin x − √{2}) = 0", "2 sin x(cos x − √{2}) = 0"],
				"hint": "sin 2x = 2 sin x cos x", "write": "2 sin x cos x − √{2} sin x = 0 ⇒ sin x(2 cos x − √{2}) = 0"},
			{"t": "fill", "pre": "sin x = 0 ⇒ x = 0、π、2π", "q": "cos x = √{2}/2 的兩個解（由小到大）：", "template": "cos x = √{2}/2 ⇒ x = [0]π、[1]π", "ans": ["1/4", "7/4"],
				"hint": "第一、第四象限"},
			{"t": "fill", "q": "五個解加起來：", "template": "答：和 = [0]π", "ans": ["5"], "hint": "0 + π + 2π + π/4 + 7π/4"}]},

	{"id": "tc_ineq", "kind": "cross", "tier": 1, "title": "疊合不等式", "tmul": 1.0,
		"stem": "在 0 ≤ x < 2π，解不等式 sin x − √{3} cos x ≥ 1。",
		"plot": {"x": [-0.3, 6.6], "y": [-2.5, 2.5], "pi": 6, "pi_lab": 2,
			"curves": [{"f": "sin(x)-sqrt(3)*cos(x)", "c": "cyan", "at": 1}, {"f": "1", "c": "pink", "dash": true, "at": 1}],
			"band": {"lo": 1.5708, "hi": 3.6652, "at": 2}},
		"steps": [
			{"t": "fill", "q": "先疊合：", "template": "sin x − √{3} cos x = [0] sin(x − [1]π)", "ans": ["2", "1/3"],
				"hint": "√{1 + 3} = 2，cos(π/3) = 1/2、sin(π/3) = √{3}/2"},
			{"t": "fill", "q": "sin(x − π/3) ≥ 1/2，而 x − π/3 在 −π/3 到 5π/3 之間：", "template": "[0]π ≤ x − π/3 ≤ [1]π", "ans": ["1/6", "5/6"],
				"hint": "sin u ≥ 1/2 在 π/6 ≤ u ≤ 5π/6"},
			{"t": "line", "q": "封印 x 的範圍（兩端都可以等於）。", "row": "解", "marks": ["π/2", "7π/6"], "seg": [0, 1, 0], "pt": [1, 1],
				"write": "答：π/2 ≤ x ≤ 7π/6"}]},

	{"id": "tc_half", "kind": "cross", "tier": 3, "title": "半角的不等式", "tmul": 1.3,
		"stem": "在 0 ≤ x < 2π，解不等式 cos x > cos(x/2)。",
		"steps": [
			{"t": "choice", "q": "令 c = cos(x/2)，cos x 用 c 表示：", "opts": ["2c^{2} − 1", "1 − 2c^{2}", "2c − 1", "c^{2} − 1"],
				"hint": "cos x = cos 2(x/2)", "write": "c = cos(x/2)：2c^{2} − 1 > c"},
			{"t": "fill", "q": "移項後因式分解：", "template": "(2c + 1)(c − 1) > 0 ⇒ c < [0] 或 c > 1", "ans": ["−1/2"],
				"hint": "兩根 −1/2、1，開口向上，大於 0 在兩根外面"},
			{"t": "roots", "q": "c = cos(x/2)：劃掉不可能的那一邊。", "cands": [
				{"v": "c < −1/2", "ok": true, "why": "0 ≤ x/2 < π，cos(x/2) 可以小於 −1/2"},
				{"v": "c > 1", "ok": false, "why": "cos 不會大於 1"}],
				"write": "只剩 cos(x/2) < −1/2"},
			{"t": "fill", "q": "0 ≤ x/2 < π 裡，cos(x/2) < −1/2：", "template": "[0]π < x/2 < π", "ans": ["2/3"], "hint": "cos(2π/3) = −1/2"},
			{"t": "line", "q": "封印 x 的範圍。", "row": "解", "marks": ["4π/3", "2π"], "seg": [0, 1, 0], "pt": [0, 0],
				"write": "答：4π/3 < x < 2π"}]},

	{"id": "tc_k", "kind": "cross", "tier": 3, "title": "兩個交點的 k", "tmul": 1.3,
		"stem": "方程式 sin x + √{3} cos x = k 在 0 ≤ x ≤ 2π/3 有兩個相異實根，求 k 的範圍（寫成 a ≤ k < b）。",
		"plot": {"x": [-0.3, 3.5], "y": [-0.6, 2.5], "pi": 6, "var": "u",
			"curves": [{"f": "2*sin(x)", "c": "cyan", "dom": [1.0472, 3.1416], "at": 2}, {"f": "sqrt(3)", "c": "pink", "dash": true, "at": 2}],
			"band": {"lo": 1.0472, "hi": 3.1416, "at": 2},
			"pts": [{"x": 1.0472, "y": 1.732, "label": "√3", "off": [-26, -6], "at": 2}, {"x": 1.5708, "y": 2, "label": "2", "at": 2}]},
		"steps": [
			{"t": "fill", "q": "先疊合：", "template": "sin x + √{3} cos x = [0] sin(x + [1]π)", "ans": ["2", "1/3"],
				"hint": "√{1 + 3} = 2，cos(π/3) = 1/2、sin(π/3) = √{3}/2"},
			{"t": "fill", "q": "令 u = x + π/3：", "template": "[0]π ≤ u ≤ [1]π", "ans": ["1/3", "1"], "hint": "0 + π/3 到 2π/3 + π/3"},
			{"t": "fill", "q": "看圖：水平線 y = k 和 y = 2 sin u 交兩點的時候：", "template": "答：[0] ≤ k < [1]", "ans": ["√3", "2"],
				"hint": "左端點高度 2 sin(π/3) = √{3}，最高點 2 只有一個交點"}]},
	]


# ================= 角的鍛造 =================

static func _angle() -> Array:
	return [
	{"id": "ta_tri", "kind": "angle", "tier": 1, "title": "三角形的第三個角", "tmul": 1.0,
		"stem": "△ABC 中，cos A = −3/5，sin B = 8/17。求 cos C。",
		"steps": [
			{"t": "choice", "q": "cos A < 0，A 是鈍角。那 B 呢？", "opts": ["B 一定是銳角", "B 一定是鈍角", "B 可能是鈍角", "B 一定是直角"],
				"hint": "三角形最多只有一個鈍角", "write": "A 是鈍角 ⇒ B 是銳角"},
			{"t": "fill", "q": "畫直角三角形：", "template": "sin A = [0]，cos B = [1]", "ans": ["4/5", "15/17"], "hint": "3、4、5 和 8、15、17"},
			{"t": "fill", "q": "C = π − (A + B)：", "template": "答：cos C = −cos(A + B) = [0]", "ans": ["77/85"],
				"hint": "−(cos A cos B − sin A sin B) = −(−45/85 − 32/85)"}]},

	{"id": "ta_sixth", "kind": "angle", "tier": 2, "title": "六次方的差", "tmul": 1.2,
		"stem": "cos 2θ = 1/3，求 27(cos^{6}θ − sin^{6}θ)。",
		"steps": [
			{"t": "fill", "pre": "a = cos^{2}θ、b = sin^{2}θ：a^{3} − b^{3} = (a − b)(a^{2} + ab + b^{2}) = (a − b)[(a + b)^{2} − ab]",
				"q": "a − b、a + b 各是多少？", "template": "a − b = [0]，a + b = [1]", "ans": ["1/3", "1"],
				"hint": "cos^{2}θ − sin^{2}θ = cos 2θ"},
			{"t": "fill", "q": "ab = sin^{2}θ cos^{2}θ = (sin 2θ)^{2}/4：", "template": "sin^{2} 2θ = 1 − cos^{2} 2θ = [0] ⇒ ab = [1]", "ans": ["8/9", "2/9"],
				"hint": "8/9 再除以 4"},
			{"t": "fill", "q": "全部代回：", "template": "答：27 · (1/3)(1 − 2/9) = [0]", "ans": ["7"], "hint": "9 × 7/9"}]},

	{"id": "ta_halftan", "kind": "angle", "tier": 2, "title": "第四象限的半角", "tmul": 1.2,
		"stem": "270° < θ < 360°，且 3 sin^{2}θ + 4 cos θ − 4 = 0。求 tan(θ/2)。",
		"steps": [
			{"t": "choice", "q": "令 c = cos θ，sin^{2}θ = 1 − c^{2} 代入：", "opts": ["3c^{2} − 4c + 1 = 0", "3c^{2} + 4c − 1 = 0", "3c^{2} − 4c − 1 = 0", "c^{2} − 4c + 1 = 0"],
				"hint": "3 − 3c^{2} + 4c − 4 = 0，整理後乘 −1", "write": "3c^{2} − 4c + 1 = 0 ⇒ (3c − 1)(c − 1) = 0"},
			{"t": "roots", "q": "劃掉不合的根。", "cands": [
				{"v": "cos θ = 1/3", "ok": true, "why": "第四象限 cos θ 在 0 和 1 之間"},
				{"v": "cos θ = 1", "ok": false, "why": "cos θ = 1 時 θ = 360°，不在 270° < θ < 360° 裡"}],
				"write": "cos θ = 1/3"},
			{"t": "fill", "q": "第四象限的 sin θ：", "template": "sin θ = [0]", "ans": ["−2√2/3"], "hint": "√{1 − 1/9} = 2√{2}/3，加負號"},
			{"t": "fill", "q": "以切表弦：", "template": "答：tan(θ/2) = (1 − cos θ)/sin θ = [0]", "ans": ["−√2/2"],
				"hint": "(2/3)/(−2√{2}/3) = −1/√{2}"}]},

	{"id": "ta_lines", "kind": "angle", "tier": 1, "title": "兩直線的夾角", "tmul": 1.0,
		"stem": "L_{1}：x − 3y + 2 = 0、L_{2}：2x + y − 5 = 0 的銳夾角為 θ。求 tan θ 與 cos θ。",
		"plot": {"x": [-2.5, 4.0], "y": [-1.5, 4.2], "geo": true, "axes": true,
			"shapes": [{"k": "seg", "a": [-2.5, -0.1667], "b": [4.0, 2.0], "c": "cyan"}, {"k": "seg", "a": [0.45, 4.1], "b": [3.2, -1.4], "c": "pink"},
				{"k": "angle", "o": [1.857, 1.286], "a0": -63.43, "a1": 18.43, "r": 18, "s": "θ"},
				{"k": "label", "p": [3.6, 2.2], "s": "L1", "c": "cyan"}, {"k": "label", "p": [3.4, -0.9], "s": "L2", "c": "pink"}]},
		"steps": [
			{"t": "fill", "q": "兩條直線的斜率：", "template": "m_{1} = [0]，m_{2} = [1]", "ans": ["1/3", "−2"], "hint": "ax + by + c = 0 的斜率是 −a/b"},
			{"t": "fill", "q": "差角公式（銳角取絕對值）：", "template": "tan θ = |(m_{1} − m_{2})/(1 + m_{1}m_{2})| = [0]", "ans": ["7"],
				"hint": "(1/3 + 2)/(1 − 2/3)"},
			{"t": "fill", "q": "tan θ = 7 的銳角：", "template": "答：cos θ = [0]", "ans": ["√2/10"], "hint": "斜邊 √{1 + 49} = 5√{2}"}]},

	{"id": "ta_roots", "kind": "angle", "tier": 2, "title": "根與係數", "tmul": 1.15,
		"stem": "√{5} − 2 是 x^{2} − (tan θ + 1/tan θ)x + 1 = 0 的一根。求 sin 2θ。",
		"steps": [
			{"t": "fill", "q": "兩根的積是 1，另一根是 1/(√{5} − 2)。兩根的和：", "template": "tan θ + 1/tan θ = [0]", "ans": ["2√5"],
				"hint": "1/(√{5} − 2) = √{5} + 2"},
			{"t": "choice", "q": "tan θ + 1/tan θ 化簡：", "opts": ["1/(sin θ cos θ)", "1/(sin θ + cos θ)", "sin θ cos θ", "2/cos 2θ"],
				"hint": "通分：(sin^{2}θ + cos^{2}θ)/(sin θ cos θ)", "write": "tan θ + 1/tan θ = 1/(sin θ cos θ) = 2/sin 2θ"},
			{"t": "fill", "q": "2/sin 2θ = 2√{5}：", "template": "答：sin 2θ = [0]", "ans": ["√5/5"], "hint": "1/√{5} 有理化"}]},

	{"id": "ta_tanpair", "kind": "angle", "tier": 2, "title": "兩根的 tan", "tmul": 1.15,
		"stem": "tan α、tan β 是 x^{2} + 5x − 3 = 0 的兩根。求 cos(α − β)/sin(α + β)。",
		"steps": [
			{"t": "fill", "q": "根與係數：", "template": "tan α + tan β = [0]，tan α tan β = [1]", "ans": ["−5", "−3"], "hint": "和 = −b/a、積 = c/a"},
			{"t": "choice", "q": "分子、分母同除以 cos α cos β：", "opts": ["(1 + tan α tan β)/(tan α + tan β)", "(1 − tan α tan β)/(tan α + tan β)", "(1 + tan α tan β)/(tan α − tan β)", "(tan α + tan β)/(1 + tan α tan β)"],
				"hint": "cos α cos β + sin α sin β 除以 cos α cos β 是 1 + tan α tan β",
				"write": "原式 = (1 + tan α tan β)/(tan α + tan β)"},
			{"t": "fill", "q": "代入：", "template": "答：原式 = [0]", "ans": ["2/5"], "hint": "(1 + (−3))/(−5)"}]},

	{"id": "ta_split", "kind": "angle", "tier": 3, "title": "拆角", "tmul": 1.3,
		"stem": "π/2 ≤ α ≤ π、0 ≤ β ≤ π/2，cos(α − β) = 5/13，sin(α + β) = −3/5。求 cos 2α。",
		"steps": [
			{"t": "fill", "q": "先寫出 α − β、α + β 的範圍：", "template": "[0] ≤ α − β ≤ π，π/2 ≤ α + β ≤ [1]π", "ans": ["0", "3/2"],
				"hint": "α − β：最小 π/2 − π/2，α + β：最大 π + π/2"},
			{"t": "fill", "q": "sin(α + β) < 0，所以 α + β 在 π 到 3π/2：", "template": "sin(α − β) = [0]，cos(α + β) = [1]", "ans": ["12/13", "−4/5"],
				"hint": "α − β 在 0 到 π，sin ≥ 0。α + β 在第三象限，cos < 0"},
			{"t": "fill", "q": "2α = (α + β) + (α − β)：", "template": "答：cos 2α = [0]", "ans": ["16/65"],
				"hint": "cos(α + β)cos(α − β) − sin(α + β)sin(α − β) = −20/65 + 36/65"}]},

	{"id": "ta_grid", "kind": "angle", "tier": 2, "title": "方格裡的角", "tmul": 1.15,
		"stem": "10 個邊長 1 的正方形排成 5 × 2 的長方形 ABCD，O 是兩條對角線的交點。求 tan∠AOB 與 cos∠AOB。",
		"plot": {"x": [-0.4, 5.4], "y": [-0.6, 2.6], "geo": true, "h": 150,
			"shapes": [
				{"k": "seg", "a": [1, 0], "b": [1, 2], "c": "faint"}, {"k": "seg", "a": [2, 0], "b": [2, 2], "c": "faint"},
				{"k": "seg", "a": [3, 0], "b": [3, 2], "c": "faint"}, {"k": "seg", "a": [4, 0], "b": [4, 2], "c": "faint"},
				{"k": "seg", "a": [0, 1], "b": [5, 1], "c": "faint"},
				{"k": "poly", "pts": [[0, 0], [5, 0], [5, 2], [0, 2]], "c": "dim"},
				{"k": "seg", "a": [0, 0], "b": [5, 2], "c": "cyan"}, {"k": "seg", "a": [5, 0], "b": [0, 2], "c": "cyan"},
				{"k": "seg", "a": [2.5, 1], "b": [2.5, 0], "c": "gold", "dash": true, "at": 1},
				{"k": "label", "p": [-0.25, -0.3], "s": "A"}, {"k": "label", "p": [5.25, -0.3], "s": "B"},
				{"k": "label", "p": [5.25, 2.3], "s": "C"}, {"k": "label", "p": [-0.25, 2.3], "s": "D"},
				{"k": "label", "p": [2.5, 1.35], "s": "O"}, {"k": "label", "p": [2.5, -0.35], "s": "M", "at": 1}]},
		"steps": [
			{"t": "fill", "q": "從 O 作 \\ol{AB} 的垂線，垂足 M：", "template": "tan∠AOM = \\ol{AM}/\\ol{OM} = [0]", "ans": ["5/2"],
				"hint": "\\ol{AM} = 5/2、\\ol{OM} = 1"},
			{"t": "fill", "q": "∠AOB = 2∠AOM：", "template": "tan∠AOB = [0]", "ans": ["−20/21"], "hint": "2t/(1 − t^{2})，t = 5/2"},
			{"t": "fill", "q": "cos 2∠AOM = (1 − t^{2})/(1 + t^{2})：", "template": "答：cos∠AOB = [0]", "ans": ["−21/29"],
				"hint": "(1 − 25/4)/(1 + 25/4)"}]},

	{"id": "ta_double", "kind": "angle", "tier": 3, "title": "兩倍的角", "tmul": 1.3,
		"stem": "△ABC 中，∠B = 2∠A，\\ol{AC} = 6，\\ol{BC} = 4。求 tan B。",
		"plot": {"x": [-0.6, 4.6], "y": [-0.7, 5.6], "geo": true,
			"shapes": [{"k": "poly", "pts": [[0, 0], [4, 0], [0.625, 4.961]], "c": "cyan"},
				{"k": "angle", "o": [0.625, 4.961], "a0": -97.18, "a1": -55.77, "r": 22, "s": "θ"},
				{"k": "angle", "o": [0, 0], "a0": 0, "a1": 82.82, "r": 18, "s": "2θ"},
				{"k": "label", "p": [0.62, 5.35], "s": "A"}, {"k": "label", "p": [-0.3, -0.3], "s": "B"}, {"k": "label", "p": [4.3, -0.3], "s": "C"},
				{"k": "label", "p": [2.55, 2.6], "s": "6"}, {"k": "label", "p": [2.0, -0.4], "s": "4"}]},
		"steps": [
			{"t": "fill", "q": "正弦定理：\\ol{AC} 對 B、\\ol{BC} 對 A。", "template": "sin B/sin A = \\ol{AC}/\\ol{BC} = [0]", "ans": ["3/2"], "hint": "6/4"},
			{"t": "fill", "q": "sin B = sin 2A = 2 sin A cos A：", "template": "2 cos A = 3/2 ⇒ cos A = [0]", "ans": ["3/4"], "hint": "sin 2A/sin A = 2 cos A"},
			{"t": "fill", "q": "二倍角：", "template": "cos B = cos 2A = [0]", "ans": ["1/8"], "hint": "2cos^{2}A − 1 = 2 · 9/16 − 1"},
			{"t": "fill", "q": "B 是銳角：", "template": "答：tan B = [0]", "ans": ["3√7"], "hint": "sin B = √{1 − 1/64} = 3√{7}/8"}]},

	{"id": "ta_shift", "kind": "angle", "tier": 1, "title": "通分再疊合", "tmul": 1.0,
		"stem": "求 √{3}/sin 20° − 1/cos 20° 的值。",
		"steps": [
			{"t": "fill", "q": "通分，分子疊合：√{3} cos 20° − sin 20° = 2(sin 60° cos 20° − cos 60° sin 20°)。", "template": "分子 = [0] sin 40°", "ans": ["2"],
				"hint": "sin(60° − 20°)"},
			{"t": "fill", "q": "分母用二倍角：", "template": "分母 = sin 20° cos 20° = [0] sin 40°", "ans": ["1/2"], "hint": "sin 40° = 2 sin 20° cos 20°"},
			{"t": "fill", "q": "相除：", "template": "答：原式 = [0]", "ans": ["4"], "hint": "2 除以 1/2"}]},
	]


# ================= 疊合極值 =================

static func _extreme() -> Array:
	return [
	{"id": "te_quad", "kind": "extreme", "tier": 1, "title": "換成 sin 的二次式", "tmul": 1.0,
		"stem": "π/6 ≤ x ≤ 7π/6 時，f(x) = cos^{2} x − 3 sin x + 2 的最大值 M、最小值 m，求 (M, m)。",
		"plot": {"x": [-3.2, 1.6], "y": [-2.0, 6.2], "var": "t",
			"curves": [{"f": "-x*x-3*x+3", "c": "orange", "at": 2}],
			"band": {"lo": -0.5, "hi": 1.0, "at": 1},
			"pts": [{"x": -1.5, "y": 5.25, "label": "", "at": 2}, {"x": -0.5, "y": 4.25, "label": "M", "at": 3}, {"x": 1, "y": -1, "label": "m", "at": 3}]},
		"steps": [
			{"t": "fill", "q": "令 t = sin x。x 從 π/6 走到 7π/6，t 的範圍：", "template": "[0] ≤ t ≤ [1]", "ans": ["−1/2", "1"],
				"hint": "會經過 x = π/2（t = 1），最右邊到 sin(7π/6)"},
			{"t": "choice", "q": "cos^{2} x = 1 − t^{2}，f 用 t 表示：", "opts": ["−t^{2} − 3t + 3", "−t^{2} − 3t + 1", "t^{2} − 3t + 3", "−t^{2} + 3t + 3"],
				"hint": "1 − t^{2} − 3t + 2", "write": "f = −t^{2} − 3t + 3 = −(t + 3/2)^{2} + 21/4"},
			{"t": "fill", "q": "頂點 t = −3/2 不在範圍內，f 在範圍內遞減：", "template": "答：M = [0]（t = −1/2），m = [1]（t = 1）", "ans": ["17/4", "−1"],
				"hint": "−1/4 + 3/2 + 3、−1 − 3 + 3"}]},

	{"id": "te_sum", "kind": "extreme", "tier": 2, "title": "t = sin x + cos x", "tmul": 1.2,
		"stem": "0 ≤ x ≤ π 時，f(x) = sin 2x + 2(sin x + cos x) − 1 的最大值 M、最小值 m，求 (M, m)。",
		"plot": {"x": [-2.6, 2.0], "y": [-3.6, 3.6], "var": "t",
			"curves": [{"f": "(x+1)*(x+1)-3", "c": "orange", "at": 2}],
			"band": {"lo": -1.0, "hi": 1.4142, "at": 1},
			"pts": [{"x": -1, "y": -3, "label": "m", "at": 3}, {"x": 1.4142, "y": 2.8284, "label": "M", "at": 3}]},
		"steps": [
			{"t": "fill", "pre": "令 t = sin x + cos x = √{2} sin(x + π/4)", "q": "x + π/4 從 π/4 到 5π/4，t 的範圍：", "template": "[0] ≤ t ≤ [1]", "ans": ["−1", "√2"],
				"hint": "sin 在 π/4 到 5π/4 的範圍：最小在 5π/4、最大在 π/2"},
			{"t": "fill", "q": "t^{2} = 1 + 2 sin x cos x：", "template": "sin 2x = t^{2} − [0] ⇒ f = (t + 1)^{2} − 3", "ans": ["1"],
				"hint": "f = t^{2} − 1 + 2t − 1"},
			{"t": "fill", "q": "頂點 t = −1 剛好是左端點：", "template": "答：M = [0]，m = [1]", "ans": ["2√2", "−3"],
				"hint": "t = √{2}：(√{2} + 1)^{2} − 3 = 2√{2}"}]},

	{"id": "te_box", "kind": "extreme", "tier": 1, "title": "疊合找最大", "tmul": 1.05,
		"stem": "0 ≤ x ≤ π 時，f(x) = 3 sin x − 4 cos x 的最大值 M、最小值 m，以及最大值發生時 sin x 的值。",
		"plot": {"x": [-0.3, 3.5], "y": [-5.6, 5.8], "pi": 4,
			"curves": [{"f": "3*sin(x)-4*cos(x)", "c": "cyan", "dom": [0.0, 3.1416], "at": 1}],
			"band": {"lo": 0.0, "hi": 3.1416, "at": 1},
			"pts": [{"x": 2.498, "y": 5, "label": "M", "at": 2}, {"x": 0, "y": -4, "label": "m", "off": [8, 4], "at": 3}]},
		"steps": [
			{"t": "fill", "q": "疊合成 r sin(x − φ)，φ 是銳角：", "template": "r = [0]，cos φ = [1]，sin φ = [2]", "ans": ["5", "3/5", "4/5"],
				"hint": "r = √{3^{2} + 4^{2}}，r cos φ = 3、r sin φ = 4"},
			{"t": "fill", "q": "x − φ 從 −φ 到 π − φ，裡面有 π/2：", "template": "M = [0]，此時 x = π/2 + φ，sin x = cos φ = [1]", "ans": ["5", "3/5"],
				"hint": "sin(π/2 + φ) = cos φ"},
			{"t": "fill", "q": "最小值在端點：比較 f(0)、f(π)。", "template": "答：m = [0]", "ans": ["−4"], "hint": "f(0) = −4、f(π) = 4"}]},

	{"id": "te_expand", "kind": "extreme", "tier": 2, "title": "先展開再疊合", "tmul": 1.15,
		"stem": "0 ≤ x ≤ π/2 時，f(x) = 2 sin(x + π/6) − 2 cos x 的最大值 M、最小值 m，求 (M, m)。",
		"plot": {"x": [-0.5, 2.3], "y": [-1.6, 2.4], "pi": 6, "pi_lab": 6,
			"curves": [{"f": "2*sin(x-PI/6)", "c": "cyan", "dom": [0.0, 1.5708], "at": 2}],
			"band": {"lo": 0.0, "hi": 1.5708, "at": 2}},
		"steps": [
			{"t": "fill", "q": "和角公式展開：", "template": "2 sin(x + π/6) = [0] sin x + [1] cos x", "ans": ["√3", "1"], "hint": "2(sin x cos(π/6) + cos x sin(π/6))"},
			{"t": "fill", "q": "f = √{3} sin x − cos x，疊合：", "template": "f = [0] sin(x − [1]π)", "ans": ["2", "1/6"], "hint": "cos(π/6) = √{3}/2"},
			{"t": "fill", "q": "x − π/6 從 −π/6 到 π/3：", "template": "答：M = [0]，m = [1]", "ans": ["√3", "−1"], "hint": "2 sin(π/3)、2 sin(−π/6)"}]},

	{"id": "te_reduce", "kind": "extreme", "tier": 2, "title": "降次再疊合", "tmul": 1.2,
		"stem": "0 ≤ x ≤ π/2 時，f(x) = 2 sin x(sin x + √{3} cos x) 的最大值 M、最小值 m，求 (M, m)。",
		"plot": {"x": [-0.4, 2.0], "y": [-0.6, 3.5], "pi": 12, "pi_lab": 4,
			"curves": [{"f": "2*sin(2*x-PI/6)+1", "c": "cyan", "dom": [0.0, 1.5708], "at": 2}],
			"band": {"lo": 0.0, "hi": 1.5708, "at": 2},
			"pts": [{"x": 1.0472, "y": 3, "label": "M", "at": 3}, {"x": 0, "y": 0, "label": "m", "off": [8, 4], "at": 3}]},
		"steps": [
			{"t": "fill", "q": "展開：2 sin^{2} x = 1 − cos 2x，2 sin x cos x = sin 2x。", "template": "f = 1 − cos 2x + [0] sin 2x", "ans": ["√3"], "hint": "2√{3} sin x cos x = √{3} sin 2x"},
			{"t": "fill", "q": "疊合 √{3} sin 2x − cos 2x：", "template": "f = 2 sin(2x − [0]π) + 1", "ans": ["1/6"], "hint": "和 √{3} sin x − cos x 一樣"},
			{"t": "fill", "q": "2x − π/6 的範圍：", "template": "−π/6 ≤ 2x − π/6 ≤ [0]π", "ans": ["5/6"], "hint": "x = π/2 代入"},
			{"t": "fill", "q": "sin 在 −π/6 到 5π/6 的範圍是 −1/2 到 1：", "template": "答：M = [0]，m = [1]", "ans": ["3", "0"], "hint": "2 · 1 + 1、2 · (−1/2) + 1"}]},

	{"id": "te_frac", "kind": "extreme", "tier": 3, "title": "分式的最值", "tmul": 1.3,
		"stem": "求 y = (1 − cos x)/(3 + sin x) 的最大值與最小值。",
		"plot": {"x": [-0.3, 6.6], "y": [-0.15, 0.95], "pi": 2,
			"curves": [{"f": "(1-cos(x))/(3+sin(x))", "c": "cyan", "at": 3}, {"f": "0.75", "c": "pink", "dash": true, "at": 3}]},
		"steps": [
			{"t": "fill", "q": "去分母，把 sin x、cos x 移到同一邊：", "template": "y sin x + cos x = 1 − [0]y", "ans": ["3"], "hint": "3y + y sin x = 1 − cos x"},
			{"t": "choice", "q": "左邊疊合後的範圍是 ±√{y^{2} + 1}，所以：", "opts": ["(1 − 3y)^{2} ≤ y^{2} + 1", "1 − 3y ≤ y + 1", "(1 − 3y)^{2} ≥ y^{2} + 1", "|1 − 3y| ≤ y^{2} + 1"],
				"hint": "a sin x + b cos x = k 有解 ⇔ k^{2} ≤ a^{2} + b^{2}", "write": "(1 − 3y)^{2} ≤ y^{2} + 1 ⇒ 8y^{2} − 6y ≤ 0"},
			{"t": "fill", "q": "解 2y(4y − 3) ≤ 0：", "template": "答：[0] ≤ y ≤ [1]", "ans": ["0", "3/4"], "hint": "兩根 0、3/4"}]},

	{"id": "te_solvable", "kind": "extreme", "tier": 2, "title": "有解的 k", "tmul": 1.15,
		"stem": "方程式 cos 2x + 4 sin x = k 有實數解，求 k 的範圍。",
		"plot": {"x": [-1.6, 2.0], "y": [-5.8, 3.8], "var": "t",
			"curves": [{"f": "-2*(x-1)*(x-1)+3", "c": "orange", "at": 1}],
			"band": {"lo": -1.0, "hi": 1.0, "at": 0},
			"pts": [{"x": 1, "y": 3, "label": "3", "at": 2}, {"x": -1, "y": -5, "label": "−5", "at": 2}]},
		"steps": [
			{"t": "fill", "q": "令 t = sin x（−1 ≤ t ≤ 1），cos 2x = 1 − 2t^{2}：", "template": "k = −2t^{2} + 4t + 1 = −2(t − 1)^{2} + [0]", "ans": ["3"],
				"hint": "−2(t^{2} − 2t + 1) + 2 + 1"},
			{"t": "fill", "q": "k 是 t 在 −1 到 1 之間時，這個二次函數取到的值：", "template": "答：[0] ≤ k ≤ [1]", "ans": ["−5", "3"], "hint": "t = 1 最大，t = −1 最小"}]},

	{"id": "te_halfmax", "kind": "extreme", "tier": 3, "title": "疊合的角再對半", "tmul": 1.3,
		"stem": "f(x) = 8 sin x + 15 cos x 寫成 r sin(x + θ)（r > 0、θ 是銳角）。\n(1) 求 cos^{2}(θ/2)　(2) 0 ≤ x ≤ π/2 時，f 在 x = α 有最大值 k，求 k 與 sin 2α。",
		"plot": {"x": [-0.3, 1.9], "y": [-1.0, 19.0], "pi": 4,
			"curves": [{"f": "8*sin(x)+15*cos(x)", "c": "cyan", "dom": [0.0, 1.5708], "at": 2}],
			"band": {"lo": 0.0, "hi": 1.5708, "at": 2}},
		"steps": [
			{"t": "fill", "part": "(1)", "q": "疊合：r cos θ = 8、r sin θ = 15。", "template": "r = [0]，cos θ = [1]", "ans": ["17", "8/17"], "hint": "8、15、17"},
			{"t": "fill", "part": "(1)", "q": "半角公式：", "template": "cos^{2}(θ/2) = (1 + cos θ)/2 = [0]", "ans": ["25/34"], "hint": "(1 + 8/17)/2"},
			{"t": "fill", "part": "(2)", "q": "x + θ 從 θ 到 π/2 + θ，會經過 π/2：", "template": "k = [0]，α = π/2 − θ", "ans": ["17"], "hint": "sin 取到 1"},
			{"t": "fill", "part": "(2)", "q": "2α = π − 2θ：", "template": "答：sin 2α = sin 2θ = [0]", "ans": ["240/289"], "hint": "2 · (15/17) · (8/17)"}]},

	{"id": "te_cosprod", "kind": "extreme", "tier": 2, "title": "乘開再疊合", "tmul": 1.2,
		"stem": "0 ≤ x ≤ π/2 時，f(x) = 2 cos x(3 sin x + 4 cos x) 的最大值 M、最小值 m，求 (M, m)。",
		"plot": {"x": [-0.3, 1.9], "y": [-0.8, 9.8], "pi": 4,
			"curves": [{"f": "2*cos(x)*(3*sin(x)+4*cos(x))", "c": "cyan", "dom": [0.0, 1.5708], "at": 2}],
			"band": {"lo": 0.0, "hi": 1.5708, "at": 2}},
		"steps": [
			{"t": "fill", "q": "乘開，用二倍角降次：", "template": "f = 3 sin 2x + 4 cos 2x + [0]", "ans": ["4"], "hint": "8 cos^{2} x = 4(1 + cos 2x)"},
			{"t": "fill", "q": "疊合（φ 是銳角，cos φ = 3/5、sin φ = 4/5）：", "template": "3 sin 2x + 4 cos 2x = [0] sin(2x + φ)", "ans": ["5"], "hint": "√{9 + 16}"},
			{"t": "fill", "q": "2x + φ 從 φ 到 π + φ：最大在 π/2，最小在 π + φ。", "template": "答：M = [0]，m = 5 · (−sin φ) + 4 = [1]", "ans": ["9", "0"],
				"hint": "sin(π + φ) = −sin φ = −4/5"}]},

	{"id": "te_cos2", "kind": "extreme", "tier": 1, "title": "二倍角的二次式", "tmul": 1.0,
		"stem": "求 f(x) = cos 2x − 2 sin x 的最大值 M、最小值 m。",
		"plot": {"x": [-1.7, 1.5], "y": [-3.6, 2.3], "var": "t",
			"curves": [{"f": "1-2*x*x-2*x", "c": "orange", "at": 1}],
			"band": {"lo": -1.0, "hi": 1.0, "at": 1},
			"pts": [{"x": -0.5, "y": 1.5, "label": "M", "at": 2}, {"x": 1, "y": -3, "label": "m", "at": 3}]},
		"steps": [
			{"t": "choice", "q": "令 t = sin x，cos 2x 用 t 表示：", "opts": ["1 − 2t^{2}", "2t^{2} − 1", "1 − t^{2}", "2t^{2} + 1"],
				"hint": "cos 2x = 1 − 2 sin^{2} x", "write": "f = 1 − 2t^{2} − 2t = −2(t + 1/2)^{2} + 3/2，−1 ≤ t ≤ 1"},
			{"t": "fill", "q": "頂點 t = −1/2 在範圍內：", "template": "M = [0]", "ans": ["3/2"], "hint": "開口向下，頂點最高"},
			{"t": "fill", "q": "離頂點最遠的端點：", "template": "答：m = [0]（t = 1）", "ans": ["−3"], "hint": "1 − 2 − 2"}]},
	]


# ================= 海岸委託 =================

static func _quest() -> Array:
	return [
	{"id": "tq_fan", "kind": "quest", "tier": 1, "title": "扇形花圃", "tmul": 1.0,
		"stem": "用 36 公尺長的籬笆圍一個扇形花圃（兩條半徑加一段弧）。半徑 r 是多少時面積最大？最大面積與圓心角各是多少？",
		"plot": {"x": [-9.8, 9.8], "y": [-1.2, 10.2], "geo": true, "h": 190,
			"shapes": [{"k": "sector", "o": [0, 0], "r": 9, "a0": 32.7, "a1": 147.3, "c": "lime", "fill": "lime", "alpha": 0.15},
				{"k": "angle", "o": [0, 0], "a0": 32.7, "a1": 147.3, "r": 16, "s": "θ"},
				{"k": "label", "p": [5.0, 2.0], "s": "r"}]},
		"steps": [
			{"t": "fill", "q": "弧長 = 36 − 2r，面積 = (1/2) · r · 弧長：", "template": "面積 = −r^{2} + [0]r", "ans": ["18"], "hint": "(1/2) r (36 − 2r)"},
			{"t": "fill", "q": "配方：−(r − 9)^{2} + 81。", "template": "r = [0] 時面積最大，最大面積 [1] 平方公尺", "ans": ["9", "81"], "hint": "頂點"},
			{"t": "fill", "q": "圓心角 = 弧長/半徑：", "template": "答：θ = (36 − 18)/9 = [0]（弧度）", "ans": ["2"], "hint": "18/9"}]},

	{"id": "tq_cone", "kind": "quest", "tier": 2, "title": "圓錐上的螞蟻", "tmul": 1.2,
		"stem": "圓錐的母線 \\ol{OA} = 12、底圓半徑 4，D 在母線 \\ol{OA} 上，\\ol{OD} = 6。螞蟻從 A 出發，沿側面繞一圈爬到 D，最短要爬多遠？",
		"plot": {"x": [-13.0, 13.0], "y": [-2.0, 13.0], "geo": true, "h": 200,
			"shapes": [
				{"k": "seg", "a": [-4, 0], "b": [0, 11.31], "c": "cyan", "until": 2}, {"k": "seg", "a": [4, 0], "b": [0, 11.31], "c": "cyan", "until": 2},
				{"k": "ellipse", "o": [0, 0], "rx": 4, "ry": 1.1, "c": "cyan", "until": 2},
				{"k": "dot", "p": [4, 0], "s": "A", "off": [6, 14], "until": 2}, {"k": "dot", "p": [2, 5.66], "s": "D", "until": 2},
				{"k": "label", "p": [0, 12.4], "s": "O", "until": 2},
				{"k": "sector", "o": [0, 0], "r": 12, "a0": 30, "a1": 150, "c": "cyan", "fill": "cyan", "alpha": 0.1, "at": 2},
				{"k": "angle", "o": [0, 0], "a0": 30, "a1": 150, "r": 16, "s": "", "at": 2},
				{"k": "dot", "p": [10.39, 6.0], "s": "A", "at": 2}, {"k": "dot", "p": [-5.196, 3.0], "s": "D", "off": [-8, -10], "at": 2},
				{"k": "label", "p": [-10.9, 7.6], "s": "A'", "at": 2}, {"k": "label", "p": [0, -1.0], "s": "O", "at": 2},
				{"k": "seg", "a": [10.39, 6.0], "b": [-5.196, 3.0], "c": "gold", "w": 2.6, "at": 3}]},
		"steps": [
			{"t": "fill", "q": "沿 \\ol{OA} 剪開攤平，是半徑 12 的扇形：", "template": "扇形的弧長 = 底圓周長 = [0]π", "ans": ["8"], "hint": "2π · 4"},
			{"t": "fill", "q": "圓心角 = 弧長/半徑：", "template": "∠AOA' = [0]π", "ans": ["2/3"], "hint": "8π/12"},
			{"t": "fill", "q": "攤平後最短路徑是線段 \\ol{AD}（D 在 \\ol{OA'} 上）。用餘弦定理：", "template": "答：\\ol{AD} = [0]", "ans": ["6√7"],
				"hint": "12^{2} + 6^{2} − 2 · 12 · 6 · cos(2π/3) = 252"}]},

	{"id": "tq_wheel", "kind": "quest", "tier": 2, "title": "滾動的輪子", "tmul": 1.15,
		"stem": "半徑 2 公尺的輪子沿地面向右滾動（不打滑）。輪上一點 P 一開始碰著地面。\n(1) 輪子滾了 4π/3 公尺時，P 離地多高？(2) 滾了 x 公尺時，P 離地 h(x) = ？",
		"plot": {"x": [-2.6, 7.0], "y": [-0.6, 4.6], "geo": true, "h": 150,
			"shapes": [{"k": "seg", "a": [-2.6, 0], "b": [7.0, 0], "c": "dim"}],
			"groups": [{"o": [0, 2], "anim": {"k": "roll", "r": 2, "dist": 4.18879, "dur": 3.0}, "trace": [0, -2],
				"shapes": [{"k": "circle", "o": [0, 0], "r": 2, "c": "cyan"}, {"k": "seg", "a": [0, 0], "b": [0, -2], "c": "faint"},
					{"k": "seg", "a": [0, 0], "b": [2, 0], "c": "faint"}, {"k": "seg", "a": [0, 0], "b": [-2, 0], "c": "faint"}, {"k": "seg", "a": [0, 0], "b": [0, 2], "c": "faint"},
					{"k": "dot", "p": [0, -2], "s": "P", "off": [6, 14]}]}]},
		"steps": [
			{"t": "fill", "part": "(1)", "q": "滾過的距離 = 轉過的弧長 = 半徑 × 轉過的弧度：", "template": "轉了 (4π/3)/2 = [0]π", "ans": ["2/3"], "hint": "弧長 = rθ"},
			{"t": "fill", "part": "(1)", "q": "P 從最低點繞圓心轉 2π/3，離圓心的高度差是 −2 cos(2π/3)。", "template": "P 離地 2 − 2 cos(2π/3) = [0]", "ans": ["3"], "hint": "cos(2π/3) = −1/2"},
			{"t": "fill", "part": "(2)", "q": "滾 x 公尺就轉 x/2：", "template": "答：h(x) = [0] − 2 cos(x/[1])", "ans": ["2", "2"], "hint": "圓心離地 2"}]},

	{"id": "tq_ferris", "kind": "quest", "tier": 2, "title": "摩天輪", "tmul": 1.2,
		"stem": "摩天輪直徑 60 公尺，最低點離地 10 公尺，逆時針等速轉動，12 分鐘一圈。小光從最低點上車，t 分鐘後離地 h(t) = a sin(bt + c) + d 公尺（a、b > 0，−π < c ≤ π）。\n(1) 求 a、b、c、d　(2) 一圈之中，有幾分鐘高於 55 公尺？",
		"plot": {"x": [-3.6, 3.6], "y": [-0.3, 7.4], "geo": true, "h": 180,
			"shapes": [{"k": "seg", "a": [-3.6, 0], "b": [3.6, 0], "c": "dim"}, {"k": "seg", "a": [0, 4], "b": [-1.6, 0], "c": "faint"},
				{"k": "seg", "a": [0, 4], "b": [1.6, 0], "c": "faint"},
				{"k": "seg", "a": [-3.6, 5.5], "b": [3.6, 5.5], "c": "pink", "dash": true, "at": 3}, {"k": "label", "p": [3.2, 5.9], "s": "55", "c": "pink", "at": 3}],
			"groups": [{"o": [0, 4], "anim": {"k": "spin", "period": 9.0, "dir": 1},
				"shapes": [{"k": "circle", "o": [0, 0], "r": 3, "c": "cyan"},
					{"k": "seg", "a": [0, -3], "b": [0, 3], "c": "faint"}, {"k": "seg", "a": [-2.598, -1.5], "b": [2.598, 1.5], "c": "faint"}, {"k": "seg", "a": [-2.598, 1.5], "b": [2.598, -1.5], "c": "faint"},
					{"k": "dot", "p": [0, 3], "c": "cyan"}, {"k": "dot", "p": [2.598, 1.5], "c": "cyan"}, {"k": "dot", "p": [2.598, -1.5], "c": "cyan"},
					{"k": "dot", "p": [-2.598, 1.5], "c": "cyan"}, {"k": "dot", "p": [-2.598, -1.5], "c": "cyan"}, {"k": "dot", "p": [0, -3], "c": "gold"}]}]},
		"steps": [
			{"t": "fill", "part": "(1)", "q": "振幅是半徑，中線是圓心的高度：", "template": "a = [0]，d = [1]", "ans": ["30", "40"], "hint": "圓心離地 10 + 30"},
			{"t": "fill", "part": "(1)", "q": "週期 12 分鐘：", "template": "b = 2π/12 = [0]π", "ans": ["1/6"], "hint": "化簡 2/12"},
			{"t": "fill", "part": "(1)", "q": "t = 0 在最低點：sin c = −1。", "template": "c = [0]π", "ans": ["−1/2"], "hint": "−π < c ≤ π"},
			{"t": "fill", "part": "(2)", "pre": "(2)　h(t) = 40 − 30 cos(πt/6) > 55 ⇒ cos(πt/6) < −1/2", "q": "一圈 0 ≤ t ≤ 12 裡，解出 t：", "template": "2π/3 < πt/6 < 4π/3 ⇒ [0] < t < [1]", "ans": ["4", "8"],
				"hint": "兩邊乘 6/π", "write": "答：每圈 4 分鐘高於 55 公尺"}]},

	{"id": "tq_tide", "kind": "quest", "tier": 2, "title": "進港的時段", "tmul": 1.2,
		"stem": "港口水深 y = a sin(bx + c) + d（公尺，x 是時刻，a、b > 0、0 ≤ c < 2π）。x = 0、3、6、9、12 時，y = 5、8、5、2、5。\n水深 ≥ 6.5 時大船才能進港。一天（0 ≤ x ≤ 24）哪些時段可以進港？",
		"plot": {"x": [-0.8, 24.8], "y": [0.0, 9.5],
			"curves": [{"f": "3*sin(PI/6*x)+5", "c": "cyan", "at": 2}, {"f": "6.5", "c": "pink", "dash": true, "at": 2}],
			"pts": [{"x": 0, "y": 5, "label": ""}, {"x": 3, "y": 8, "label": ""}, {"x": 6, "y": 5, "label": ""}, {"x": 9, "y": 2, "label": ""}, {"x": 12, "y": 5, "label": ""}]},
		"steps": [
			{"t": "fill", "q": "最高 8、最低 2，12 小時一個週期：", "template": "d = [0]，a = [1]，b = [2]π", "ans": ["5", "3", "1/6"], "hint": "b = 2π/12"},
			{"t": "fill", "q": "x = 0 時 y 在中線 5，接著往上升：", "template": "c = [0]", "ans": ["0"], "hint": "sin c = 0，而且要是上升的那一點"},
			{"t": "fill", "pre": "3 sin(πx/6) + 5 ≥ 6.5 ⇒ sin(πx/6) ≥ 1/2", "q": "sin u ≥ 1/2 在 π/6 ≤ u ≤ 5π/6（再加 2π 的倍數）：", "template": "π/6 ≤ πx/6 ≤ 5π/6 ⇒ [0] ≤ x ≤ [1]", "ans": ["1", "5"], "hint": "兩邊乘 6/π"},
			{"t": "line", "q": "加一個週期 12，封印一天之中可以進港的時段。", "row": "進港", "marks": ["1", "5", "13", "17"], "seg": [0, 1, 0, 1, 0], "pt": [1, 1, 1, 1],
				"write": "答：1 ≤ x ≤ 5 或 13 ≤ x ≤ 17"}]},

	{"id": "tq_light", "kind": "quest", "tier": 2, "title": "自動窗簾", "tmul": 1.15,
		"stem": "窗邊照度 I(t) = 500 + 300 sin(π/12 · (t − 8))，0 ≤ t < 24（時）。I(t) ≥ 650 時窗簾半閉。\n(1) 晴天從幾點半閉到幾點？(2) 陰天 I(t) = 500 + 150 sin(π/12 · (t − 8))，會怎樣？",
		"plot": {"x": [-0.5, 24.5], "y": [1.5, 8.8],
			"curves": [{"f": "5+3*sin(PI/12*(x-8))", "c": "cyan"}, {"f": "6.5", "c": "pink", "dash": true},
				{"f": "5+1.5*sin(PI/12*(x-8))", "c": "lime", "dash": true, "at": 2}],
			"pts": [{"x": 10, "y": 6.5, "label": "", "at": 1}, {"x": 18, "y": 6.5, "label": "", "at": 1}, {"x": 14, "y": 6.5, "label": "", "at": 2}]},
		"steps": [
			{"t": "fill", "part": "(1)", "q": "500 + 300 sin(…) ≥ 650：", "template": "sin(π/12 · (t − 8)) ≥ [0]", "ans": ["1/2"], "hint": "150/300"},
			{"t": "fill", "part": "(1)", "q": "π/6 ≤ π/12 · (t − 8) ≤ 5π/6：", "template": "[0] ≤ t ≤ [1]", "ans": ["10", "18"], "hint": "2 ≤ t − 8 ≤ 10"},
			{"t": "choice", "part": "(2)", "q": "陰天要 150 sin(…) ≥ 150，也就是 sin(…) ≥ 1：", "opts": ["只在 14 點那一瞬間半閉", "10 點到 18 點都半閉", "12 點到 16 點半閉", "整天都不會半閉"],
				"hint": "sin 等於 1 只有一個時刻：π/12 · (t − 8) = π/2", "write": "答：(1) 10 點到 18 點　(2) 只在 14 點那一瞬間"}]},

	{"id": "tq_slope", "kind": "quest", "tier": 1, "title": "溜滑梯的坡度", "tmul": 1.0,
		"stem": "舊溜滑梯的坡道和地面夾角 θ，坡度 tan θ = 3/4。新溜滑梯的夾角是 θ/2，坡道一樣長 10 公尺。\n(1) 新的坡度 tan(θ/2) 是多少？(2) 新坡道的頂端多高？",
		"plot": {"x": [-0.6, 4.6], "y": [-0.6, 3.4], "geo": true, "h": 170,
			"shapes": [{"k": "poly", "pts": [[0, 0], [4, 0], [4, 3]], "c": "cyan"}, {"k": "right", "p": [4, 0], "u": [-1, 0], "v": [0, 1]},
				{"k": "angle", "o": [0, 0], "a0": 0, "a1": 36.87, "r": 30, "s": "θ"},
				{"k": "seg", "a": [0, 0], "b": [4, 1.333], "c": "gold", "dash": true, "at": 1},
				{"k": "label", "p": [2.0, -0.35], "s": "4"}, {"k": "label", "p": [4.3, 1.5], "s": "3"}]},
		"steps": [
			{"t": "fill", "part": "(1)", "q": "直角三角形 3、4、5：", "template": "sin θ = [0]，cos θ = [1]", "ans": ["3/5", "4/5"], "hint": "斜邊 5"},
			{"t": "fill", "part": "(1)", "q": "以切表弦：", "template": "tan(θ/2) = (1 − cos θ)/sin θ = [0]", "ans": ["1/3"], "hint": "(1/5)/(3/5)"},
			{"t": "fill", "part": "(2)", "q": "半角公式 sin^{2}(θ/2) = (1 − cos θ)/2：", "template": "答：高 = 10 sin(θ/2) = [0]", "ans": ["√10"], "hint": "sin(θ/2) = √{1/10}"}]},

	{"id": "tq_mount", "kind": "quest", "tier": 3, "title": "測山高", "tmul": 1.3,
		"stem": "在 A 點測得山頂 D 的仰角是 θ。朝山腳 C 直走 100 公尺到 B，仰角變成 2θ；再走 40 公尺剛好到山腳 C（\\ol{DC} 垂直地面）。求山高 \\ol{CD} 與 cos 2θ。",
		"plot": {"x": [-0.8, 15.0], "y": [-1.0, 10.0], "geo": true, "h": 180,
			"shapes": [{"k": "seg", "a": [-0.6, 0], "b": [14.8, 0], "c": "dim"}, {"k": "seg", "a": [0, 0], "b": [14, 9.165], "c": "cyan"},
				{"k": "seg", "a": [10, 0], "b": [14, 9.165], "c": "cyan"}, {"k": "seg", "a": [14, 0], "b": [14, 9.165], "c": "cyan"},
				{"k": "right", "p": [14, 0], "u": [-1, 0], "v": [0, 1]},
				{"k": "angle", "o": [0, 0], "a0": 0, "a1": 33.21, "r": 30, "s": "θ"}, {"k": "angle", "o": [10, 0], "a0": 0, "a1": 66.42, "r": 16, "s": "2θ"},
				{"k": "label", "p": [0, -0.6], "s": "A"}, {"k": "label", "p": [10, -0.6], "s": "B"}, {"k": "label", "p": [14.4, -0.6], "s": "C"}, {"k": "label", "p": [14, 9.7], "s": "D"},
				{"k": "label", "p": [5, -0.6], "s": "100"}, {"k": "label", "p": [12, -0.6], "s": "40"}]},
		"steps": [
			{"t": "choice", "q": "△ABD 中，∠ADB 是多少？", "opts": ["θ", "2θ", "90° − θ", "180° − 3θ"],
				"hint": "外角 2θ = ∠DAB + ∠ADB", "write": "∠ADB = 2θ − θ = θ ⇒ △ABD 是等腰三角形"},
			{"t": "fill", "q": "等腰：∠DAB = ∠ADB。", "template": "\\ol{BD} = \\ol{AB} = [0]", "ans": ["100"], "hint": "等角對等邊"},
			{"t": "fill", "q": "直角 △BCD：", "template": "\\ol{CD} = √{100^{2} − 40^{2}} = [0]", "ans": ["20√21"], "hint": "√{8400}"},
			{"t": "fill", "q": "∠DBC = 2θ：", "template": "答：cos 2θ = \\ol{BC}/\\ol{BD} = [0]", "ans": ["2/5"], "hint": "40/100"}]},
	]


# ================= 試煉大題（每 5 層） =================

static func _boss() -> Array:
	return [
	{"id": "tb_gun", "kind": "boss", "tier": 2, "title": "兩座砲台", "tmul": 1.6,
		"stem": "砲台 A 在砲台 B 的正東方 14 公里。A 向西偏北 θ、B 向東偏北 θ 發射，同時命中離兩砲台都是 18 公里的目標 P。接著 A 改向西偏北 θ/2 發射，落在 12 公里外的 Q 點。\n(1) 求 cos θ　(2) 求 cos(θ/2)　(3) 求 \\ol{BQ}",
		"plot": {"x": [-1.5, 15.5], "y": [-1.6, 18.2], "geo": true, "h": 210,
			"shapes": [{"k": "seg", "a": [0, 0], "b": [14, 0], "c": "dim"}, {"k": "seg", "a": [0, 0], "b": [7, 16.58], "c": "cyan"},
				{"k": "seg", "a": [14, 0], "b": [7, 16.58], "c": "cyan"},
				{"k": "angle", "o": [14, 0], "a0": 112.89, "a1": 180, "r": 26, "s": "θ"}, {"k": "angle", "o": [0, 0], "a0": 0, "a1": 67.11, "r": 22, "s": "θ"},
				{"k": "seg", "a": [14, 0], "b": [4, 6.633], "c": "pink", "dash": true, "at": 1},
				{"k": "seg", "a": [0, 0], "b": [4, 6.633], "c": "gold", "w": 2.6, "at": 2},
				{"k": "label", "p": [-0.5, -1.0], "s": "B"}, {"k": "label", "p": [14.5, -1.0], "s": "A"}, {"k": "label", "p": [7, 17.6], "s": "P"},
				{"k": "dot", "p": [4, 6.633], "s": "Q", "off": [-18, -6], "at": 1}]},
		"steps": [
			{"t": "fill", "part": "(1)", "q": "\\ol{PA} = \\ol{PB}：從 P 往 \\ol{AB} 作垂線，垂足是 \\ol{AB} 的中點。", "template": "(1)　cos θ = [0]", "ans": ["7/18"],
				"hint": "鄰邊 7、斜邊 18"},
			{"t": "fill", "part": "(2)", "q": "θ 是銳角，半角公式：", "template": "(2)　cos(θ/2) = √{(1 + cos θ)/2} = [0]", "ans": ["5/6"], "hint": "(1 + 7/18)/2 = 25/36"},
			{"t": "fill", "part": "(3)", "q": "△ABQ 中 \\ol{AB} = 14、\\ol{AQ} = 12、∠BAQ = θ/2，餘弦定理：", "template": "(3)　\\ol{BQ}^{2} = [0]", "ans": ["60"],
				"hint": "196 + 144 − 2 · 14 · 12 · (5/6)"},
			{"t": "fill", "part": "(3)", "q": "開根號：", "template": "答：\\ol{BQ} = [0]", "ans": ["2√15"], "hint": "√{60} = √{4 · 15}"}]},

	{"id": "tb_path", "kind": "boss", "tier": 3, "title": "「工」字步道", "tmul": 1.65,
		"stem": "半徑 20 公尺的圓形池塘裡修「工」字步道：上下兩條等長且平行的弦 \\ol{AB}、\\ol{CD}，加上連接兩弦中點 M、N 的步道（經過圓心 O）。設 ∠AOM = θ（0 < θ < π/2）。\n(1) 把總長 L 用 θ 表示　(2) L 最長多少？(3) 此時 \\ol{MN} 多長？",
		"plot": {"x": [-21.5, 21.5], "y": [-21.5, 21.5], "geo": true, "h": 200,
			"shapes": [{"k": "circle", "o": [0, 0], "r": 20, "c": "dim"},
				{"k": "seg", "a": [-16.38, 11.47], "b": [16.38, 11.47], "c": "cyan", "w": 2.6}, {"k": "seg", "a": [-16.38, -11.47], "b": [16.38, -11.47], "c": "cyan", "w": 2.6},
				{"k": "seg", "a": [0, 11.47], "b": [0, -11.47], "c": "cyan", "w": 2.6},
				{"k": "seg", "a": [0, 0], "b": [-16.38, 11.47], "c": "faint", "dash": true},
				{"k": "angle", "o": [0, 0], "a0": 90, "a1": 145, "r": 18, "s": "θ"},
				{"k": "label", "p": [-17.8, 13.4], "s": "A"}, {"k": "label", "p": [17.8, 13.4], "s": "B"}, {"k": "label", "p": [-17.8, -13.6], "s": "C"},
				{"k": "label", "p": [17.8, -13.6], "s": "D"}, {"k": "label", "p": [2.6, 13.6], "s": "M"}, {"k": "label", "p": [2.6, -13.8], "s": "N"},
				{"k": "label", "p": [2.8, -1.6], "s": "O"}]},
		"steps": [
			{"t": "fill", "part": "(1)", "pre": "(1)　直角 △AOM：\\ol{AM} = 20 sin θ、\\ol{OM} = 20 cos θ", "q": "\\ol{AB} = 2\\ol{AM}，\\ol{MN} = 2\\ol{OM}：", "template": "L = 2\\ol{AB} + \\ol{MN} = [0] sin θ + [1] cos θ", "ans": ["80", "40"],
				"hint": "\\ol{AB} = 2\\ol{AM}，\\ol{MN} = 2\\ol{OM}"},
			{"t": "fill", "part": "(2)", "q": "提出 40 再疊合：", "template": "(2)　L = 40(2 sin θ + cos θ)，最長 [0] 公尺", "ans": ["40√5"], "hint": "40 √{2^{2} + 1^{2}}"},
			{"t": "fill", "part": "(3)", "q": "最長時 sin θ : cos θ = 2 : 1（和係數成比例）：", "template": "tan θ = [0]，cos θ = [1]", "ans": ["2", "√5/5"], "hint": "斜邊 √{5}"},
			{"t": "fill", "part": "(3)", "q": "\\ol{MN} = 40 cos θ：", "template": "答：\\ol{MN} = [0] 公尺", "ans": ["8√5"], "hint": "40 · √{5}/5"}]},

	{"id": "tb_coin", "kind": "boss", "tier": 2, "title": "滾動的圓盤", "tmul": 1.6,
		"stem": "半徑 6 的圓盤內接正方形 ABCD（A、B、C、D 依逆時針排列），一開始 A 碰著地面、B 在圓心正右方。圓盤沿地面向右滾動（不打滑），滾了 x 之後 B 離地 y = a sin(bx + c) + d（a、b > 0，0 ≤ c < 2π）。\n(1) 求 a、b、c、d　(2) 滾了 7π 時 B 離地多高？(3) 滾了多遠 B 第一次碰到地面？",
		"plot": {"x": [-7.0, 17.0], "y": [-1.2, 13.0], "geo": true, "h": 170,
			"shapes": [{"k": "seg", "a": [-7.0, 0], "b": [17.0, 0], "c": "dim"}],
			"groups": [{"o": [0, 6], "anim": {"k": "roll", "r": 6, "dist": 9.42478, "dur": 3.2}, "trace": [6, 0],
				"shapes": [{"k": "circle", "o": [0, 0], "r": 6, "c": "cyan"}, {"k": "poly", "pts": [[0, -6], [6, 0], [0, 6], [-6, 0]], "c": "faint"},
					{"k": "dot", "p": [0, -6], "s": "A", "c": "cyan", "off": [6, 14]}, {"k": "dot", "p": [6, 0], "s": "B", "off": [8, -6]},
					{"k": "dot", "p": [0, 6], "s": "C", "c": "cyan"}, {"k": "dot", "p": [-6, 0], "s": "D", "c": "cyan", "off": [-18, -6]}]}]},
		"steps": [
			{"t": "fill", "part": "(1)", "q": "B 繞著圓心轉，圓心離地 6：", "template": "(1)　a = [0]，d = [1]", "ans": ["6", "6"], "hint": "半徑、圓心高度"},
			{"t": "fill", "part": "(1)", "q": "滾 x 就順時針轉 x/6（弧長 = 半徑 × 弧度）：", "template": "b = [0]", "ans": ["1/6"], "hint": "轉過的角 = x/6"},
			{"t": "fill", "part": "(1)", "pre": "B 從中線往下：y = 6 − 6 sin(x/6)", "q": "把 −sin(x/6) 寫成 sin(x/6 + c)：", "template": "y = 6 sin(x/6 + c) + 6 ⇒ c = [0]π", "ans": ["1"],
				"hint": "sin(θ + π) = −sin θ"},
			{"t": "fill", "part": "(2)", "q": "x = 7π 代入：", "template": "(2)　y = 6 sin(7π/6 + π) + 6 = [0]", "ans": ["9"], "hint": "sin(13π/6) = 1/2"},
			{"t": "fill", "part": "(3)", "q": "y = 0 ⇒ sin(x/6 + π) = −1，取最小的 x > 0：", "template": "答：滾了 [0]π", "ans": ["3"], "hint": "x/6 + π = 3π/2"}]},

	{"id": "tb_wave", "kind": "boss", "tier": 2, "title": "讀圖找疊合", "tmul": 1.6,
		"stem": "圖是 y = a sin x + b cos x 的一段，最高點 (π/3, 4)。\n(1) 求 a、b　(2) −π/2 ≤ x ≤ π/2 時的最小值　(3) 0 ≤ x ≤ 2π 時，y = 2 的所有解的和",
		"plot": {"x": [-1.8, 6.6], "y": [-4.8, 4.8], "pi": 6, "pi_lab": 2,
			"curves": [{"f": "4*sin(x+PI/6)", "c": "cyan"}, {"f": "2", "c": "pink", "dash": true, "at": 4}],
			"band": {"lo": -1.5708, "hi": 1.5708, "at": 2},
			"pts": [{"x": 1.0472, "y": 4, "label": "(π/3, 4)"}, {"x": -1.0472, "y": -3.464, "label": "", "at": 3}]},
		"steps": [
			{"t": "fill", "part": "(1)", "pre": "(1)　最大值 4 ⇒ y = 4 sin(x + φ)", "q": "最高點時 x + φ = π/2：", "template": "π/3 + φ = π/2 ⇒ φ = [0]π", "ans": ["1/6"], "hint": "π/2 − π/3"},
			{"t": "fill", "part": "(1)", "q": "展開 4 sin(x + π/6)：", "template": "a = 4 cos(π/6) = [0]，b = 4 sin(π/6) = [1]", "ans": ["2√3", "2"], "hint": "4 · √{3}/2、4 · 1/2"},
			{"t": "fill", "part": "(2)", "q": "x + π/6 從 −π/3 到 2π/3：", "template": "(2)　最小值 4 sin(−π/3) = [0]", "ans": ["−2√3"], "hint": "sin(−π/3) = −√{3}/2"},
			{"t": "fill", "part": "(3)", "q": "sin(x + π/6) = 1/2，x + π/6 從 π/6 到 13π/6：", "template": "x = 0、[0]π、2π", "ans": ["2/3"], "hint": "x + π/6 = 5π/6"},
			{"t": "fill", "part": "(3)", "q": "三個解加起來：", "template": "答：和 = [0]π", "ans": ["8/3"], "hint": "0 + 2π/3 + 2π"}]},

	{"id": "tb_hex", "kind": "boss", "tier": 3, "title": "翻滾的六邊形", "tmul": 1.65,
		"stem": "邊長 2 的正六邊形放在直線上，頂點 P 碰著直線。六邊形沿直線向右翻滾（每次繞著右下角的頂點轉），直到 P 再次碰到直線。\n(1) 一共翻了幾次？每次轉多少？(2) P 走過的路徑長",
		"plot": {"x": [-1.6, 13.6], "y": [-0.6, 4.6], "geo": true, "h": 130,
			"shapes": [{"k": "seg", "a": [-1.6, 0], "b": [13.6, 0], "c": "dim"}],
			"groups": [{"o": [0, 0], "anim": {"k": "polyroll", "side": 2, "sides": 6, "n": 5, "dur": 0.9}, "trace": [0, 0],
				"shapes": [{"k": "poly", "pts": [[0, 0], [2, 0], [3, 1.732], [2, 3.464], [0, 3.464], [-1, 1.732]], "c": "cyan"},
					{"k": "dot", "p": [0, 0], "s": "P", "off": [-14, -6]}]}]},
		"steps": [
			{"t": "fill", "part": "(1)", "q": "每翻一次，下一個頂點落地；六個頂點輪一圈回到 P。", "template": "(1)　翻 [0] 次，每次轉 [1]π", "ans": ["5", "1/3"],
				"hint": "外角 = 2π/6；P 自己落地的那次不用再轉"},
			{"t": "fill", "part": "(2)", "q": "每次 P 繞轉動中心畫一段圓弧，半徑是 P 到那個頂點的距離。", "template": "(2)　半徑依序 2、2√3、[0]、2√3、2", "ans": ["4"],
				"hint": "P 和正對面的頂點距離是直徑：2 × 邊長"},
			{"t": "fill", "part": "(2)", "q": "弧長 = 半徑 × π/3，五段加起來：", "template": "答：路徑長 = ([0] + [1]√3)π/3", "ans": ["8", "4"],
				"hint": "2 + 2√{3} + 4 + 2√{3} + 2"}]},

	{"id": "tb_circum", "kind": "boss", "tier": 3, "title": "外心的圓心角", "tmul": 1.6,
		"stem": "O 是 △ABC 的外心，tan A = 4/3、tan B = 2，外接圓半徑 5。\n(1) 求 tan C　(2) 求 tan∠AOB　(3) 求 \\ol{AB} 與 △AOB 的面積",
		"plot": {"x": [-5.8, 5.8], "y": [-5.8, 5.8], "geo": true, "h": 200,
			"shapes": [{"k": "circle", "o": [0, 0], "r": 5, "c": "dim"},
				{"k": "poly", "pts": [[-4.472, -2.236], [4.472, -2.236], [0.894, 4.919]], "c": "cyan"},
				{"k": "seg", "a": [0, 0], "b": [-4.472, -2.236], "c": "pink", "at": 1}, {"k": "seg", "a": [0, 0], "b": [4.472, -2.236], "c": "pink", "at": 1},
				{"k": "angle", "o": [0, 0], "a0": 206.57, "a1": 333.43, "r": 14, "s": "", "at": 1},
				{"k": "label", "p": [-5.1, -2.8], "s": "A"}, {"k": "label", "p": [5.1, -2.8], "s": "B"}, {"k": "label", "p": [1.0, 5.4], "s": "C"},
				{"k": "dot", "p": [0, 0], "s": "O", "off": [6, -6]}]},
		"steps": [
			{"t": "fill", "part": "(1)", "q": "C = π − (A + B)：", "template": "(1)　tan C = −tan(A + B) = [0]", "ans": ["2"],
				"hint": "tan(A + B) = (4/3 + 2)/(1 − 8/3) = −2"},
			{"t": "choice", "part": "(2)", "q": "三個角都是銳角，O 在三角形裡面。∠AOB 和 C 的關係：", "opts": ["∠AOB = 2∠C", "∠AOB = ∠C", "∠AOB = 180° − ∠C", "∠AOB = 2∠A"],
				"hint": "同弧所對的圓心角是圓周角的兩倍", "write": "(2)　∠AOB = 2C"},
			{"t": "fill", "part": "(2)", "q": "二倍角：", "template": "tan∠AOB = tan 2C = [0]", "ans": ["−4/3"], "hint": "2 · 2/(1 − 4)"},
			{"t": "fill", "part": "(3)", "q": "正弦定理：\\ol{AB} = 2R sin C，sin C = 2/√{5}。", "template": "(3)　\\ol{AB} = [0]", "ans": ["4√5"], "hint": "10 · 2/√{5}"},
			{"t": "fill", "part": "(3)", "q": "△AOB 面積 = (1/2) · 5 · 5 · sin 2C，sin 2C = 4/5：", "template": "答：面積 = [0]", "ans": ["10"], "hint": "(25/2) · (4/5)"}]},
	]
