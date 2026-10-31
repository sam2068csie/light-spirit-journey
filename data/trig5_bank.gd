extends RefCounted
## 三角函數 第五大關「和角羅盤」題庫（對應講義 1-2 重點一：和角公式）
## 題目的數字都是自己設計的（和講義、學校的題目不一樣），觀念對應：
##   差角公式的推導（單位圓兩點、餘弦定理）、sin／cos／tan 的和差角公式、特殊角（15°、75°、105°）的值、公式的合併、
##   象限與正負號、由 tan 求角的和差、三角形內角和、tan 的根與係數、兩直線的夾角、圖形上的和角應用
##
## 引擎：level_trig5_compass.gd（繼承第四關）。步驟除了 choice、fill、filter，多三種動手的：
##   rot    雙層轉盤：mode "sum"（α + β）或 "diff"（α − β）、fn（右邊顯示的公式："sin"／"cos"／"tan"）、
##          target（目標角，度）、alphas／betas（α、β 只能用這些角，空的就不限）、arange／brange（滑桿的範圍）、start
##   tiles  拼公式：expr（顯示用的左邊，例如 "sin(α + β)"）、target（"sin_sum"、"sin_diff"、"cos_sum"、"cos_diff"、"tan_sum"、"tan_diff"）、
##          tokens（可以用的積木）。引擎用幾組角度代進去算，和正確的式子一樣就過關（所以乘法的順序隨意）
##   lines  兩直線夾角：p 是兩條直線共同經過的點、m1 是 L₁ 的斜率、tan 是目標的 tan θ、slopes 是 L₂ 可以選的斜率、targets 是答案的斜率
const UITheme := preload("game_theme.gd")

const SB := preload("step_bank.gd")

const T_COSD := "trig_cosdiff"
const T_SUMF := "trig_sumf"
const T_TANSUM := "trig_tansum"
const T_MERGE := "trig_merge"
const T_QUAD := "trig_quadsign"
const T_ANGLE := "trig_findangle"
const T_TRI := "trig_tri"
const T_LINE := "trig_lineangle"
const T_GEO := "trig_geoapp"
const T_JUDGE := "trig_sumjudge"

const TK_SC := ["sin α", "cos α", "sin β", "cos β", "+", "−", "×"]
const TK_TAN := ["tan α", "tan β", "1", "+", "−", "×", "÷", "(", ")"]
const VERT := 1.0e6           # 斜率不存在（鉛直線）
const SLOPES := [-7.0, -3.0, -2.0, -1.0, -0.5, -1.0 / 3.0, 0.0, 1.0 / 3.0, 0.5, 1.0, 2.0, 3.0, 7.0, VERT]


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return SB.fill(name, q, template, answers, line, nudge, tag, mode)


static func _tf(name: String, stmt: String, truth: bool, why: String, line: String) -> Dictionary:
	return _c(name, stmt, ["對", "錯"] if truth else ["錯", "對"], 0, why, why, line, T_JUDGE)


## 雙層轉盤
static func _rot(name: String, q: String, mode: String, fn: String, target: float, line: String, nudge: String,
		tag: String, extra := {}) -> Dictionary:
	var d := {"kind": "rot", "name": name, "q": q, "mode": mode, "fn": fn, "target": target, "alphas": [], "betas": [],
		"line": line, "nudge": nudge, "tag": tag}
	d.merge(extra, true)
	return d


## 拼公式
static func _tiles(name: String, q: String, expr: String, target: String, tokens: Array, line: String, nudge: String,
		tag: String) -> Dictionary:
	return {"kind": "tiles", "name": name, "q": q, "expr": expr, "target": target, "tokens": tokens.duplicate(),
		"line": line, "nudge": nudge, "tag": tag}


## 兩直線夾角
static func _lines(name: String, q: String, p: Array, m1: float, tan_t: float, targets: Array, line: String,
		nudge: String, extra_slopes := []) -> Dictionary:
	var sl := SLOPES.duplicate()
	for e in extra_slopes:
		if not sl.has(e):
			sl.append(e)
	sl.sort()
	return {"kind": "lines", "name": name, "q": q, "p": p, "m1": m1, "tan": tan_t, "slopes": sl, "targets": targets,
		"line": line, "nudge": nudge, "tag": T_LINE}


static func slots() -> Array:
	var out := _slots()
	for slot in out:
		slot["plain"] = true
		slot["params"] = slot.get("params", [])
		SB.fix_roots(slot)
		# tan 的和差角：積木改成「分數」模式（分子、分母各一格，不用括號）
		for v in slot.variants:
			for st in v.get("steps", []):
				if st.kind == "tiles" and String(st.target).begins_with("tan"):
					st["frac"] = true
					st["nudge"] = String(st.nudge).replace("別忘了括號：", "").replace("(分子) ÷ (分母)，", "").replace("(分子) ÷ (1 − 乘積)。", "分母是 1 − 乘積。")
	return out


static func _slots() -> Array:
	return [
		# ======================= 第一章．雙層轉盤 =======================
		{"id": "sumf", "chapter": 1, "type": "forge", "title": "和角公式",
		 "story": "羅盤的兩層轉盤可以把兩個角「加起來」。先學 sin、cos 的和角公式，再把羅盤轉到 75°、15°、105° 這些新的特殊角。",
		 "insight": "cos(α + β) = cos α cos β − sin α sin β；sin(α + β) = sin α cos β + cos α sin β；sin(α − β) = sin α cos β − cos α sin β。把 75° = 45° + 30°、15° = 45° − 30°、105° = 60° + 45° 拆成特殊角，就能求值。",
		 "variants": [
			{"eq": "認識和角公式，\n再求 sin 75°、cos 75°",
			 "steps": [
				_tiles("cos 和角", "cos 的和角公式：同名相乘（cos 配 cos、sin 配 sin），中間是「−」。拼出 cos(α + β)。", "cos(α + β)", "cos_sum", TK_SC,
					"cos(α + β) = cos α cos β − sin α sin β", "cos α cos β 減掉 sin α sin β。", T_SUMF),
				_tiles("sin 和角", "拼出 sin(α + β)。（sin 配 cos、cos 配 sin）", "sin(α + β)", "sin_sum", TK_SC,
					"sin(α + β) = sin α cos β + cos α sin β", "sin 的和角公式，中間是「＋」，每一項 sin 配 cos。", T_SUMF),
				_rot("轉羅盤", "把羅盤轉到 α + β = 75°，而且 α、β 都要是特殊角（30°、45°）。", "sum", "sin", 75.0,
					"75° = 45° + 30°", "45° + 30° = 75°。", T_SUMF,
					{"alphas": [30.0, 45.0], "betas": [30.0, 45.0], "arange": [0.0, 90.0], "brange": [0.0, 90.0]}),
				_f("sin 75°", "sin 75° = sin 45° cos 30° + cos 45° sin 30°。", "sin 75° = (√6 + √2) ÷ [0]", ["4"],
					"sin 75° = (√6 + √2)/4", "(√2/2)(√3/2) + (√2/2)(1/2) = √6/4 + √2/4。", T_SUMF),
				_f("cos 75°", "cos 75° = cos 45° cos 30° − sin 45° sin 30°。", "cos 75° = (√6 − √2) ÷ [0]", ["4"],
					"cos 75° = (√6 − √2)/4", "√6/4 − √2/4。", T_SUMF),
			 ]},
			{"eq": "求 sin 15°、cos 15°",
			 "steps": [
				_tiles("sin 差角", "拼出 sin(α − β)。", "sin(α − β)", "sin_diff", TK_SC,
					"sin(α − β) = sin α cos β − cos α sin β", "和角公式的「＋」變成「−」。", T_SUMF),
				_rot("轉羅盤", "把羅盤轉到 α − β = 15°，而且 α、β 都要是特殊角（30°、45°、60°）。", "diff", "sin", 15.0,
					"15° = 45° − 30°（或 60° − 45°）", "45° − 30° = 15°。", T_SUMF,
					{"alphas": [45.0, 60.0], "betas": [30.0, 45.0], "arange": [0.0, 90.0], "brange": [0.0, 90.0]}),
				_f("sin 15°", "sin 15° = sin 45° cos 30° − cos 45° sin 30°。", "sin 15° = (√6 − √2) ÷ [0]", ["4"],
					"sin 15° = (√6 − √2)/4", "√6/4 − √2/4。", T_SUMF),
				_f("cos 15°", "cos 15° = cos 45° cos 30° + sin 45° sin 30°。", "cos 15° = (√6 + √2) ÷ [0]", ["4"],
					"cos 15° = (√6 + √2)/4", "√6/4 + √2/4。", T_SUMF),
			 ]},
			{"eq": "求 sin 105°、cos 105°",
			 "steps": [
				_tiles("cos 和角", "拼出 cos(α + β)。", "cos(α + β)", "cos_sum", TK_SC,
					"cos(α + β) = cos α cos β − sin α sin β", "cos 的和角公式中間是「−」。", T_SUMF),
				_rot("轉羅盤", "把羅盤轉到 α + β = 105°，α、β 都要是特殊角（45°、60°）。", "sum", "cos", 105.0,
					"105° = 60° + 45°", "60° + 45° = 105°。", T_SUMF,
					{"alphas": [45.0, 60.0], "betas": [45.0, 60.0], "arange": [0.0, 90.0], "brange": [0.0, 90.0]}),
				_f("sin 105°", "sin 105° = sin 60° cos 45° + cos 60° sin 45°。", "sin 105° = (√6 + √2) ÷ [0]", ["4"],
					"sin 105° = (√6 + √2)/4", "√6/4 + √2/4。", T_SUMF),
				_f("cos 105°", "cos 105° = cos 60° cos 45° − sin 60° sin 45°。", "cos 105° = (√2 − √6) ÷ [0]", ["4"],
					"cos 105° = (√2 − √6)/4（負的：105° 在第二象限）", "√2/4 − √6/4。", T_SUMF),
			 ]},
		 ]},

		{"id": "cosd", "chapter": 1, "type": "forge", "title": "差角公式",
		 "story": "學會和角之後，換成兩個角「相減」。羅盤上有兩根指針 A、B，長度都是 1，它們之間的距離藏著 cos(α − β) 的祕密。",
		 "insight": "差角公式也可以把和角公式的 β 換成 −β 得到（cos(−β) = cos β、sin(−β) = −sin β）。另一種證法：A(cos α, sin α)、B(cos β, sin β)：\\ol{AB}² = (cos α − cos β)² + (sin α − sin β)² = 2 − 2(cos α cos β + sin α sin β)。餘弦定理又說 \\ol{AB}² = 2 − 2 cos(α − β)。所以 cos(α − β) = cos α cos β + sin α sin β。",
		 "variants": [
			{"eq": "單位圓上 A(cos α, sin α)、B(cos β, sin β)，\n∠AOB = 60°，求 \\ol{AB} 與 cos 15°",
			 "steps": [
				_rot("轉指針", "轉動外盤 α 和內盤 β，讓 ∠AOB 等於 60°（α − β = 60° 或 −60° 都可以）。", "diff", "cos", 60.0,
					"∠AOB = 60°（|α − β| = 60°）", "α 比 β 大 60°：例如 α = 75°、β = 15°。", T_COSD, {"abs": true}),
				_f("弦長", "\\ol{AB}² 用座標算是 2 − 2(cos α cos β + sin α sin β)，用餘弦定理算是 2 − 2 cos(α − β)。", "\\ol{AB}² = 2 − 2 cos 60° = [0]，\\ol{AB} = [1]", ["1", "1"],
					"\\ol{AB}² = 2 − 2 × 1/2 = 1，\\ol{AB} = 1", "cos 60° = 1/2。", T_COSD),
				_tiles("拼差角公式", "兩種算法的 \\ol{AB}² 相等，拼出 cos(α − β)。", "cos(α − β)", "cos_diff", TK_SC,
					"cos(α − β) = cos α cos β + sin α sin β", "cos α cos β 和 sin α sin β 相加，符號是「＋」。", T_COSD),
				_f("cos 15°", "15° = 60° − 45°，代進差角公式：cos 15° = cos 60° cos 45° + sin 60° sin 45°。", "cos 15° = (√2 + √6) ÷ [0]", ["4"],
					"cos 15° = (√2 + √6)/4", "(1/2)(√2/2) + (√3/2)(√2/2) = √2/4 + √6/4。", T_COSD),
			 ]},
			{"eq": "單位圓上 A(cos α, sin α)、B(cos β, sin β)，\n∠AOB = 90°，求 \\ol{AB}，再用差角公式驗算 cos 90°",
			 "steps": [
				_rot("轉指針", "轉動 α、β，讓 ∠AOB 等於 90°（α − β = 90° 或 −90° 都可以）。", "diff", "cos", 90.0,
					"∠AOB = 90°（|α − β| = 90°）", "α 比 β 大 90°：例如 α = 120°、β = 30°。", T_COSD, {"abs": true}),
				_f("弦長", "∠AOB = 90°，△AOB 是等腰直角三角形。", "\\ol{AB}² = 2 − 2 cos 90° = [0]，\\ol{AB} = [1]", ["2", "√2"],
					"\\ol{AB}² = 2 − 0 = 2，\\ol{AB} = √2", "cos 90° = 0。", T_COSD),
				_tiles("拼差角公式", "拼出 cos(α − β)。", "cos(α − β)", "cos_diff", TK_SC,
					"cos(α − β) = cos α cos β + sin α sin β", "同名相乘（cos 配 cos、sin 配 sin），中間是「＋」。", T_COSD),
				_f("代入", "取 α = 120°、β = 30°，代入差角公式：cos(120° − 30°) = cos 120° cos 30° + sin 120° sin 30°。", "cos 90° = [0]", ["0"],
					"(−1/2)(√3/2) + (√3/2)(1/2) = 0，剛好是 cos 90°", "(−√3/4) + (√3/4)。", T_COSD),
			 ]},
			{"eq": "單位圓上 A(cos α, sin α)、B(cos β, sin β)，\n∠AOB = 120°，求 \\ol{AB}，再用差角公式驗算 cos 120°",
			 "steps": [
				_rot("轉指針", "轉動 α、β，讓 ∠AOB 等於 120°（α − β = 120° 或 −120° 都可以）。", "diff", "cos", 120.0,
					"∠AOB = 120°（|α − β| = 120°）", "α 比 β 大 120°：例如 α = 150°、β = 30°。", T_COSD, {"abs": true}),
				_f("弦長", "∠AOB = 120°。", "\\ol{AB}² = 2 − 2 cos 120° = [0]，\\ol{AB} = [1]", ["3", "√3"],
					"\\ol{AB}² = 2 − 2 × (−1/2) = 3，\\ol{AB} = √3", "cos 120° = −1/2。", T_COSD),
				_tiles("拼差角公式", "拼出 cos(α − β)。", "cos(α − β)", "cos_diff", TK_SC,
					"cos(α − β) = cos α cos β + sin α sin β", "cos α cos β 加上 sin α sin β。", T_COSD),
				_f("代入", "取 α = 150°、β = 30°，代入差角公式：cos(150° − 30°) = cos 150° cos 30° + sin 150° sin 30°。", "cos 120° = [0]", ["-1/2"],
					"(−√3/2)(√3/2) + (1/2)(1/2) = −3/4 + 1/4 = −1/2", "(−3/4) + (1/4)。", T_COSD),
			 ]},
		 ]},

		{"id": "tanf", "chapter": 1, "type": "forge", "title": "tan 的和角",
		 "story": "sin 除以 cos 就是 tan：把和角公式上下同除以 cos α cos β，就得到 tan 的和角公式。",
		 "insight": "tan(α + β) = \\frac{tan α + tan β}{1 − tan α tan β}；tan(α − β) = \\frac{tan α − tan β}{1 + tan α tan β}。分母是「1 ∓ tan α tan β」，符號和分子的相反。tan α 或 tan β 不存在（90°）時不能用。",
		 "variants": [
			{"eq": "求 tan 75°、tan 15°",
			 "steps": [
				_tiles("tan 和角", "拼出 tan(α + β)：分子 tan α + tan β，分母 1 − tan α tan β。", "tan(α + β)", "tan_sum", TK_TAN,
					"tan(α + β) = (tan α + tan β) ÷ (1 − tan α tan β)", "別忘了括號：(分子) ÷ (分母)。", T_TANSUM),
				_f("tan 75°", "tan 75° = tan(45° + 30°)，tan 45° = 1、tan 30° = √3/3。", "tan 75° = (1 + √3/3) ÷ (1 − √3/3) = [0] + √3", ["2"],
					"tan 75° = 2 + √3", "上下同乘 3：(3 + √3)/(3 − √3)，再有理化。", T_TANSUM),
				_tiles("tan 差角", "拼出 tan(α − β)。", "tan(α − β)", "tan_diff", TK_TAN,
					"tan(α − β) = (tan α − tan β) ÷ (1 + tan α tan β)", "分子是「−」，分母是「1 + …」。", T_TANSUM),
				_f("tan 15°", "tan 15° = tan(45° − 30°)，tan 45° = 1、tan 30° = √3/3。", "tan 15° = (1 − √3/3) ÷ (1 + √3/3) = [0] − √3", ["2"],
					"tan 15° = 2 − √3", "(1 − √3/3) ÷ (1 + √3/3)，有理化後是 2 − √3。", T_TANSUM),
			 ]},
			{"eq": "tan α = 2、tan β = 3，求 tan(α + β)",
			 "steps": [
				_tiles("tan 和角", "拼出 tan(α + β)。", "tan(α + β)", "tan_sum", TK_TAN,
					"tan(α + β) = (tan α + tan β) ÷ (1 − tan α tan β)", "(分子) ÷ (1 − 乘積)。", T_TANSUM),
				_f("分子分母", "代入 tan α = 2、tan β = 3。", "分子 = [0]，分母 = [1]", ["5", "-5"],
					"分子 2 + 3 = 5，分母 1 − 2 × 3 = −5", "1 − 6。", T_TANSUM),
				_f("tan(α + β)", "分子 ÷ 分母：", "tan(α + β) = [0]", ["-1"],
					"tan(α + β) = 5 ÷ (−5) = −1", "5 ÷ (−5)。", T_TANSUM),
				_c("鈍角", "α、β 都是銳角（tan 是正的）。tan(α + β) = −1 < 0，所以 α + β 是？", ["鈍角", "銳角", "直角"], 0,
					"0° < α + β < 180°，而 tan < 0：α + β 是鈍角（135°）。", "tan 是負的在第二象限。", "α + β 是鈍角", T_TANSUM),
			 ]},
			{"eq": "tan α = 1/2、tan β = 1/3，求 tan(α − β)",
			 "steps": [
				_tiles("tan 差角", "拼出 tan(α − β)。", "tan(α − β)", "tan_diff", TK_TAN,
					"tan(α − β) = (tan α − tan β) ÷ (1 + tan α tan β)", "分子 −、分母 +。", T_TANSUM),
				_f("分子分母", "代入 tan α = 1/2、tan β = 1/3。", "分子 = [0]，分母 = [1]", ["1/6", "7/6"],
					"分子 1/2 − 1/3 = 1/6，分母 1 + 1/6 = 7/6", "1 + (1/2)(1/3) = 1 + 1/6。", T_TANSUM),
				_f("tan(α − β)", "分子 ÷ 分母：", "tan(α − β) = [0]", ["1/7"],
					"tan(α − β) = (1/6) ÷ (7/6) = 1/7", "(1/6) × (6/7)。", T_TANSUM),
			 ]},
		 ]},

		{"id": "eval", "chapter": 1, "type": "forge", "title": "公式合併",
		 "story": "公式也可以倒著用：看到 sin A cos B + cos A sin B，就把它合併成 sin(A + B)。",
		 "insight": "合併的四個樣子：sin A cos B + cos A sin B = sin(A + B)；sin A cos B − cos A sin B = sin(A − B)；cos A cos B − sin A sin B = cos(A + B)；cos A cos B + sin A sin B = cos(A − B)。先看是 sin 還是 cos，再看符號，最後看角的順序。",
		 "variants": [
			{"eq": "合併、求值：\nsin 20° cos 25° + cos 20° sin 25° 等",
			 "steps": [
				_c("看樣子", "sin 20° cos 25° + cos 20° sin 25° 可以合併成？", ["sin 45°", "sin(−5°)", "cos 45°", "sin 5°"], 0,
					"sin A cos B + cos A sin B = sin(A + B) = sin(20° + 25°)。", "sin 配 cos 再加 cos 配 sin：和角。", "合併成 sin 45°", T_MERGE),
				_f("值", "sin 45° 是多少？", "sin 20° cos 25° + cos 20° sin 25° = [0]", ["√2/2"], "= sin 45° = √2/2", "sin 45° = √2/2。", T_MERGE),
				_f("cos 的合併", "cos 75° cos 15° − sin 75° sin 15° = cos(75° + 15°)。", "cos 75° cos 15° − sin 75° sin 15° = [0]", ["0"],
					"= cos 90° = 0", "cos 90° = 0。", T_MERGE),
				_f("sin 的差", "sin 50° cos 20° − cos 50° sin 20° = sin(50° − 20°)。", "sin 50° cos 20° − cos 50° sin 20° = [0]", ["1/2"],
					"= sin 30° = 1/2", "sin 30° = 1/2。", T_MERGE),
			 ]},
			{"eq": "合併、求值：\nsin 80° cos 35° − cos 80° sin 35° 等",
			 "steps": [
				_f("sin 的差", "sin A cos B − cos A sin B = sin(A − B)。", "sin 80° cos 35° − cos 80° sin 35° = [0]", ["√2/2"],
					"= sin 45° = √2/2", "80° − 35° = 45°。", T_MERGE),
				_f("cos 的和", "cos A cos B − sin A sin B = cos(A + B)。", "cos 10° cos 20° − sin 10° sin 20° = [0]", ["√3/2"],
					"= cos 30° = √3/2", "10° + 20° = 30°。", T_MERGE),
				_f("順序不同", "這一題 cos 在前面：sin 20° cos 40° + sin 40° cos 20°。每一項都是 sin 配 cos。", "sin 20° cos 40° + sin 40° cos 20° = [0]", ["√3/2"],
					"= sin(20° + 40°) = sin 60° = √3/2", "sin 40° cos 20° 就是 cos 20° sin 40°。", T_MERGE),
			 ]},
			{"eq": "合併、求值：\ncos 65° cos 5° + sin 65° sin 5° 等",
			 "steps": [
				_f("cos 的差", "cos A cos B + sin A sin B = cos(A − B)。", "cos 65° cos 5° + sin 65° sin 5° = [0]", ["1/2"],
					"= cos 60° = 1/2", "65° − 5° = 60°。", T_MERGE),
				_f("sin 的差", "sin 110° cos 20° − cos 110° sin 20° = sin(110° − 20°)。", "sin 110° cos 20° − cos 110° sin 20° = [0]", ["1"],
					"= sin 90° = 1", "sin 90° = 1。", T_MERGE),
				_f("cos 的和", "cos 100° cos 20° − sin 100° sin 20° = cos(100° + 20°)。", "cos 100° cos 20° − sin 100° sin 20° = [0]", ["-1/2"],
					"= cos 120° = −1/2", "cos 120° = −1/2。", T_MERGE),
			 ]},
		 ]},

		{"id": "speed", "chapter": 1, "type": "speed", "title": "速算羅盤", "time": 160.0,
		 "story": "看到公式的樣子，立刻合併成一個角，說出值！",
		 "insight": "sin A cos B ± cos A sin B = sin(A ± B)；cos A cos B ∓ sin A sin B = cos(A ± B)（cos 的符號和中間的相反）。",
		 "variants": [{"gen": "compass", "count": 8}]},

		{"id": "boss1", "chapter": 1, "type": "forge", "title": "第一章試煉", "time": 300.0,
		 "story": "限時 300 秒！拼公式、拆角、合併，一口氣算完。",
		 "insight": "和差角公式正著用（拆成特殊角）、倒著用（合併成一個角）。tan(α ± β) = \\frac{tan α ± tan β}{1 ∓ tan α tan β}。",
		 "variants": [
			{"eq": "拼 cos 的和角公式，\n再求 cos 75°",
			 "steps": [
				_tiles("cos 和角", "拼出 cos(α + β)。", "cos(α + β)", "cos_sum", TK_SC,
					"cos(α + β) = cos α cos β − sin α sin β", "cos 和角：中間是「−」。", T_SUMF),
				_f("cos 75°", "cos 75° = cos(45° + 30°)。", "cos 75° = (√6 − √2) ÷ [0]", ["4"],
					"cos 75° = (√6 − √2)/4", "√6/4 − √2/4。", T_SUMF),
			 ]},
			{"eq": "拼 tan 的和角公式，\n再求 tan 105°，最後倒過來合併",
			 "steps": [
				_tiles("tan 和角", "拼出 tan(α + β)。", "tan(α + β)", "tan_sum", TK_TAN,
					"tan(α + β) = (tan α + tan β) ÷ (1 − tan α tan β)", "(分子) ÷ (分母)，分母是 1 −。", T_TANSUM),
				_f("tan 105°", "tan 105° = tan(60° + 45°) = (√3 + 1) ÷ (1 − √3)，有理化。", "tan 105° = −[0] − √3", ["2"],
					"tan 105° = −2 − √3", "(√3 + 1)² ÷ (1 − 3) = (4 + 2√3) ÷ (−2)。", T_TANSUM),
				_f("倒過來合併", "把公式倒過來用：分子 tan 75° + tan 30°、分母 1 − tan 75° tan 30°，是 tan 的和角公式。合併成一個角。", "\\frac{tan 75° + tan 30°}{1 − tan 75° tan 30°} = tan [0]°", ["105"],
					"= tan(75° + 30°) = tan 105° = −2 − √3（就是上一步算出來的值）", "分子「+」、分母「1 −」：和角，75° + 30°。", T_MERGE),
			 ]},
		 ]},

		# ======================= 第二章．羅盤的應用 =======================
		{"id": "quad", "chapter": 2, "type": "forge", "title": "象限與正負號",
		 "story": "只知道 sin α，cos α 是正是負？先看角在哪個象限，再用 sin²α + cos²α = 1 找出另一個值。",
		 "insight": "步驟：① 象限定正負 ② 畫直角三角形（或用 sin² + cos² = 1）求另一個值 ③ 代進和差角公式。sin 在第一、二象限為正；cos 在第一、四象限為正；tan 在第一、三象限為正。",
		 "variants": [
			{"eq": "sin α = 5/13（α 在第二象限）、\ntan β = 3/4（β 在第三象限），求 cos(α − β)",
			 "steps": [
				_c("α 的正負", "α 在第二象限，cos α 的正負？", ["負", "正", "0"], 0,
					"第二象限的點，橫坐標是負的。", "第二象限在 y 軸的左邊。", "α 在第二象限：cos α < 0", T_QUAD),
				_f("cos α", "sin α = 5/13，直角三角形的邊是 5、12、13。", "cos α = [0]", ["-12/13"],
					"cos α = −12/13", "邊長 12，要帶負號。", T_QUAD),
				_c("β 的正負", "β 在第三象限，sin β、cos β 的正負？", ["都是負", "sin 負、cos 正", "都是正", "sin 正、cos 負"], 0,
					"第三象限：橫、縱坐標都是負。", "第三象限在左下方。", "β 在第三象限：sin β < 0、cos β < 0", T_QUAD),
				_f("sin β、cos β", "tan β = 3/4，直角三角形的邊是 3、4、5。", "sin β = [0]，cos β = [1]", ["-3/5", "-4/5"],
					"sin β = −3/5、cos β = −4/5", "邊長 3、4、5，都要帶負號。", T_QUAD),
				_f("兩個乘積", "cos(α − β) = cos α cos β + sin α sin β。先算兩個乘積。", "cos α cos β = [0]，sin α sin β = [1]", ["48/65", "-15/65"],
					"cos α cos β = (−12/13)(−4/5) = 48/65，sin α sin β = (5/13)(−3/5) = −15/65", "分子乘分子、分母乘分母，注意正負號。", T_QUAD),
				_f("相加", "把兩個乘積加起來。", "cos(α − β) = [0]", ["33/65"],
					"cos(α − β) = 48/65 − 15/65 = 33/65", "48 − 15 = 33。", T_QUAD),
			 ]},
			{"eq": "cos α = −4/5（α 在第三象限）、\nsin β = 12/13（β 在第二象限），求 sin(α + β)",
			 "steps": [
				_f("sin α", "α 在第三象限，sin α 是負的；邊長 3、4、5。", "sin α = [0]", ["-3/5"],
					"sin α = −3/5", "第三象限 sin < 0。", T_QUAD),
				_f("cos β", "β 在第二象限，cos β 是負的；邊長 5、12、13。", "cos β = [0]", ["-5/13"],
					"cos β = −5/13", "第二象限 cos < 0。", T_QUAD),
				_f("兩個乘積", "sin(α + β) = sin α cos β + cos α sin β。先算兩個乘積。", "sin α cos β = [0]，cos α sin β = [1]", ["15/65", "-48/65"],
					"sin α cos β = (−3/5)(−5/13) = 15/65，cos α sin β = (−4/5)(12/13) = −48/65", "注意正負號。", T_QUAD),
				_f("相加", "把兩個乘積加起來。", "sin(α + β) = [0]", ["-33/65"],
					"sin(α + β) = 15/65 − 48/65 = −33/65", "15 − 48 = −33。", T_QUAD),
			 ]},
			{"eq": "sin α = 3/5（α 在第二象限）、\ncos β = 5/13（β 在第四象限），求 cos(α + β)",
			 "steps": [
				_f("cos α", "α 在第二象限，cos α 是負的；邊長 3、4、5。", "cos α = [0]", ["-4/5"],
					"cos α = −4/5", "第二象限 cos < 0。", T_QUAD),
				_f("sin β", "β 在第四象限，sin β 是負的；邊長 5、12、13。", "sin β = [0]", ["-12/13"],
					"sin β = −12/13", "第四象限 sin < 0。", T_QUAD),
				_f("兩個乘積", "cos(α + β) = cos α cos β − sin α sin β。先算兩個乘積。", "cos α cos β = [0]，sin α sin β = [1]", ["-20/65", "-36/65"],
					"cos α cos β = (−4/5)(5/13) = −20/65，sin α sin β = (3/5)(−12/13) = −36/65", "注意正負號。", T_QUAD),
				_f("相減", "cos α cos β 減掉 sin α sin β。", "cos(α + β) = [0]", ["16/65"],
					"cos(α + β) = −20/65 − (−36/65) = 16/65", "−20 + 36 = 16。", T_QUAD),
			 ]},
		 ]},

		{"id": "angle", "chapter": 2, "type": "forge", "title": "由 tan 求角",
		 "story": "知道兩個角的 tan，這兩個角加起來（或相減）是幾度？",
		 "insight": "先用 tan 的和差角公式算出 tan(α ± β)，再根據角的範圍決定是哪個角：兩個銳角相加在 0° ～ 180°，tan > 0 是銳角、tan < 0 是鈍角；兩個銳角相減在 −90° ～ 90°。",
		 "variants": [
			{"eq": "α、β 都是銳角，tan α = 1/2、tan β = 1/3，求 α + β",
			 "steps": [
				_f("分子分母", "tan(α + β) = (tan α + tan β) ÷ (1 − tan α tan β)。先算分子、分母。", "分子 = [0]，分母 = [1]", ["5/6", "5/6"],
					"分子 1/2 + 1/3 = 5/6，分母 1 − 1/6 = 5/6", "1/2 + 1/3 = 3/6 + 2/6。", T_ANGLE),
				_f("tan(α + β)", "分子 ÷ 分母：", "tan(α + β) = [0]", ["1"], "tan(α + β) = 1", "5/6 ÷ 5/6。", T_ANGLE),
				_f("角度", "0° < α + β < 180°，tan(α + β) = 1。", "α + β = [0]°", ["45"],
					"α + β = 45°", "tan 45° = 1。", T_ANGLE),
			 ]},
			{"eq": "α、β 都是銳角，tan α = 2、tan β = 3，求 α + β",
			 "steps": [
				_f("分子分母", "tan(α + β) = (tan α + tan β) ÷ (1 − tan α tan β)。先算分子、分母。", "分子 = [0]，分母 = [1]", ["5", "-5"],
					"分子 2 + 3 = 5，分母 1 − 6 = −5", "1 − 2 × 3。", T_ANGLE),
				_f("tan(α + β)", "分子 ÷ 分母：", "tan(α + β) = [0]", ["-1"], "tan(α + β) = −1", "5 ÷ (−5)。", T_ANGLE),
				_c("哪個象限", "0° < α + β < 180°，tan(α + β) = −1 < 0，α + β 在？", ["第二象限（鈍角）", "第一象限", "第四象限"], 0,
					"0° ～ 180° 之間 tan 為負，只有第二象限。", "tan 在第一、三象限為正，第二、四象限為負。", "α + β 在第二象限", T_ANGLE),
				_f("角度", "第二象限、tan = −1 的角：", "α + β = [0]°", ["135"],
					"α + β = 135°", "180° − 45°。", T_ANGLE),
			 ]},
			{"eq": "α、β 都是銳角，tan α = 3、tan β = 1/2，求 α − β",
			 "steps": [
				_f("分子分母", "tan(α − β) = (tan α − tan β) ÷ (1 + tan α tan β)。", "分子 = [0]，分母 = [1]", ["5/2", "5/2"],
					"分子 3 − 1/2 = 5/2，分母 1 + 3/2 = 5/2", "1 + 3 × (1/2) = 5/2。", T_ANGLE),
				_f("tan(α − β)", "分子 ÷ 分母：", "tan(α − β) = [0]", ["1"], "tan(α − β) = 1", "5/2 ÷ 5/2。", T_ANGLE),
				_f("角度", "tan α > tan β，所以 α > β，α − β 在 0° ～ 90°。", "α − β = [0]°", ["45"],
					"α − β = 45°", "tan 45° = 1。", T_ANGLE),
			 ]},
		 ]},

		{"id": "tri", "chapter": 2, "type": "forge", "title": "三角形與根與係數",
		 "story": "三角形的內角和是 180°，所以 C = 180° − (A + B)。tan 的兩個值如果是方程式的根，用根與係數就不用解出來。",
		 "insight": "△ABC：tan C = −tan(A + B)（sin C = sin(A + B)、cos C = −cos(A + B)）。若 tan α、tan β 是 x² + px + q = 0 的兩根：tan α + tan β = −p、tan α tan β = q，再代入 tan(α + β)。",
		 "variants": [
			{"eq": "△ABC 中，tan A = 3/4、tan B = 2，求 tan C",
			 "steps": [
				_c("內角和", "A + B + C = 180°，tan C 等於？", ["−tan(A + B)", "tan(A + B)", "1 ÷ tan(A + B)", "−1 ÷ tan(A + B)"], 0,
					"C = 180° − (A + B)，tan(180° − θ) = −tan θ。", "tan(180° − θ) = ?", "tan C = −tan(A + B)", T_TRI),
				_f("分子分母", "tan(A + B) = (tan A + tan B) ÷ (1 − tan A tan B)。先算分子、分母。", "分子 = [0]，分母 = [1]", ["11/4", "-1/2"],
					"分子 3/4 + 2 = 11/4，分母 1 − 3/2 = −1/2", "tan A tan B = 3/4 × 2 = 3/2。", T_TRI),
				_f("tan(A + B)", "分子 ÷ 分母：", "tan(A + B) = [0]", ["-11/2"], "tan(A + B) = (11/4) ÷ (−1/2) = −11/2", "11/4 × (−2)。", T_TRI),
				_f("tan C", "tan C = −tan(A + B)。", "tan C = [0]", ["11/2"],
					"tan C = 11/2", "−(−11/2)。", T_TRI),
			 ]},
			{"eq": "tan α、tan β 是 x² − 6x + 3 = 0 的兩根，\n求 tan(α + β)",
			 "steps": [
				_f("根與係數", "x² − 6x + 3 = 0 不好因式分解，用根與係數：兩根的和是 −(−6)，積是 3。", "tan α + tan β = [0]，tan α tan β = [1]", ["6", "3"],
					"兩根的和 6、積 3", "和 = −b/a、積 = c/a。", T_TRI),
				_f("代入", "tan(α + β) = (tan α + tan β) ÷ (1 − tan α tan β)。", "tan(α + β) = [0]", ["-3"],
					"tan(α + β) = 6 ÷ (1 − 3) = −3", "6 ÷ (−2)。", T_TRI),
			 ]},
			{"eq": "tan α、tan β 是 x² + 6x + 2 = 0 的兩根，\n求 tan(α + β) 與 sin(α + β) ÷ cos(α − β)",
			 "steps": [
				_f("根與係數", "x² + 6x + 2 = 0：兩根的和是 −6，積是 2。", "tan α + tan β = [0]，tan α tan β = [1]", ["-6", "2"],
					"兩根的和 −6、積 2", "和 = −b/a、積 = c/a。", T_TRI),
				_f("tan(α + β)", "代入 tan 的和角公式。", "tan(α + β) = [0]", ["6"],
					"tan(α + β) = −6 ÷ (1 − 2) = 6", "−6 ÷ (−1)。", T_TRI),
				_c("化成 tan", "sin(α + β) ÷ cos(α − β)，上下同除以 cos α cos β 得到？",
					["(tan α + tan β) ÷ (1 + tan α tan β)", "(tan α + tan β) ÷ (1 − tan α tan β)", "tan α − tan β", "tan α tan β"], 0,
					"分子 sin α cos β + cos α sin β 同除以 cos α cos β：tan α + tan β；分母 cos α cos β + sin α sin β：1 + tan α tan β。", "分母是 cos(α − β) 展開，中間是「＋」。",
					"sin(α + β) ÷ cos(α − β) = (tan α + tan β) ÷ (1 + tan α tan β)", T_TRI),
				_f("值", "代入 tan α + tan β = −6、tan α tan β = 2。", "sin(α + β) ÷ cos(α − β) = [0]", ["-2"],
					"−6 ÷ (1 + 2) = −2", "−6 ÷ 3。", T_TRI),
			 ]},
		 ]},

		{"id": "lines", "chapter": 2, "type": "forge", "title": "兩直線的夾角",
		 "story": "兩條直線的夾角，其實就是 tan 的差角公式：直線的斜率 = tan（傾斜角）。",
		 "insight": "斜率 m₁、m₂ 的兩直線，夾角 θ（0° < θ ≤ 90°）：tan θ = \\frac{|m₂ − m₁|}{|1 + m₁m₂|}。已知夾角求直線：把 \\frac{|m − m₁|}{|1 + m₁m|} = tan θ 兩邊平方去掉絕對值，整理成 m 的二次方程式再因式分解，通常有兩條。如果平方後 m² 被消去、只剩一次方程式，少掉的那一條就是斜率不存在的鉛直線。",
		 "variants": [
			{"eq": "過 P(2, 1) 作直線 L₂，和斜率 2 的直線 L₁\n夾角 θ 滿足 tan θ = 1/3，求 L₂",
			 "steps": [
				_lines("找直線", "拖動 L₂ 的斜率，找出夾角 tan θ = 1/3 的直線（有兩條）。", [2.0, 1.0], 2.0, 1.0 / 3.0, [7.0, 1.0],
					"夾角 tan θ = 1/3 的直線，斜率是 1 或 7", "斜率比 2 大一點的一條、比 2 小一點的一條。"),
				_f("平方整理", "\\frac{|m − 2|}{|1 + 2m|} = 1/3，兩邊平方去掉絕對值：9(m − 2)² = (1 + 2m)²。展開、移項、同除以 5：", "m² − [0]m + [1] = 0", ["8", "7"],
					"9m² − 36m + 36 = 4m² + 4m + 1 ⇒ 5m² − 40m + 35 = 0 ⇒ m² − 8m + 7 = 0", "左邊 9m² − 36m + 36，右邊 4m² + 4m + 1。", T_LINE),
				_f("因式分解", "m² − 8m + 7 = (m − 1)(m − 7) = 0。", "m = [0] 或 [1]", ["1", "7"],
					"(m − 1)(m − 7) = 0 ⇒ m = 1 或 7", "兩數相乘 7、相加 8。", T_LINE, "set"),
				_f("直線方程式", "斜率 7、過 (2, 1)：y − 1 = 7(x − 2)。", "y = [0]x + [1]", ["7", "-13"],
					"y = 7x − 13", "y = 7x − 14 + 1。", T_LINE),
				_f("另一條", "斜率 1、過 (2, 1)：y − 1 = x − 2。", "y = [0]x + [1]", ["1", "-1"],
					"L₂：y = 7x − 13 或 y = x − 1", "y = x − 2 + 1。", T_LINE),
			 ]},
			{"eq": "過 P(1, 2) 作直線 L₂，和斜率 1 的直線 L₁\n夾角 45°，求 L₂",
			 "steps": [
				_lines("找直線", "拖動 L₂ 的斜率，找出和 L₁ 夾 45°（tan θ = 1）的直線（有兩條，拉到最右邊是斜率不存在的鉛直線）。", [1.0, 2.0], 1.0, 1.0, [0.0, VERT],
					"水平線（斜率 0）和鉛直線（斜率不存在）都和 L₁ 夾 45°", "L₁ 的傾斜角是 45°，再轉 45° 會變成水平或鉛直。"),
				_f("平方整理", "\\frac{|m − 1|}{|1 + m|} = 1，兩邊平方：(m − 1)² = (1 + m)²。展開之後 m² 被消掉了！", "m² − 2m + 1 = m² + 2m + 1 ⇒ −4m = 0 ⇒ m = [0]", ["0"],
					"(m − 1)² = (1 + m)² ⇒ −4m = 0 ⇒ m = 0（二次項被消去，只有一個解）", "左右的 m² 和 1 都消掉，剩 −2m = 2m。", T_LINE),
				_c("少掉的那一條", "平方後 m² 被消去，只解出 m = 0 一個斜率。可是剛剛拖出了兩條，另一條是？",
					["鉛直線（斜率不存在）", "沒有另一條", "斜率是 −1 的直線", "斜率是 1 的直線"], 0,
					"二次項被消去時，少掉的那一個解是「斜率不存在」：鉛直線。斜率 1 的直線傾斜 45°，和鉛直線也夾 45°。", "設斜率 m 的時候，已經把鉛直線排除了。",
					"m² 被消去 ⇒ 另一條是鉛直線（斜率不存在）", T_LINE),
				_f("兩條直線", "斜率 0、過 (1, 2) 的水平線；過 (1, 2) 的鉛直線。", "y = [0]　或　x = [1]", ["2", "1"],
					"L₂：y = 2 或 x = 1", "水平線 y = 點的 y 坐標；鉛直線 x = 點的 x 坐標。", T_LINE),
			 ]},
			{"eq": "過 P(1, −2) 作直線 L₂，和斜率 3 的直線 L₁\n夾角 θ 滿足 tan θ = 1/3，求 L₂",
			 "steps": [
				_lines("找直線", "拖動 L₂ 的斜率，找出夾角 tan θ = 1/3 的直線（有兩條，拉到最右邊是斜率不存在的鉛直線）。", [1.0, -2.0], 3.0, 1.0 / 3.0, [4.0 / 3.0, VERT],
					"斜率 4/3 的直線和鉛直線，和 L₁ 的夾角都是 tan θ = 1/3", "一條比 L₁ 平緩一點；另一條比 L₁ 更陡，陡到變成鉛直。", [4.0 / 3.0]),
				_f("平方整理", "\\frac{|m − 3|}{|1 + 3m|} = 1/3，兩邊平方：9(m − 3)² = (1 + 3m)²。展開之後 m² 被消掉了！", "9m² − 54m + 81 = 9m² + 6m + 1 ⇒ [0]m + 80 = 0", ["-60"],
					"9(m − 3)² = (1 + 3m)² ⇒ −60m + 80 = 0（二次項被消去）", "兩邊的 9m² 消掉，−54m − 6m = −60m。", T_LINE),
				_f("解斜率", "−60m + 80 = 0。", "m = [0]", ["4/3"], "m = 4/3", "80 ÷ 60。", T_LINE),
				_c("少掉的那一條", "二次項被消去，只解出一個斜率。剛剛拖出的另一條是？",
					["鉛直線（斜率不存在）", "沒有另一條", "斜率是 −4/3 的直線", "水平線"], 0,
					"m² 被消去時，另一個解是斜率不存在的鉛直線。檢查：L₁ 和鉛直線的夾角，tan 值是 1/3（鉛直線的傾斜角 90°）。", "設斜率 m 的時候，已經把鉛直線排除了。",
					"m² 被消去 ⇒ 另一條是鉛直線", T_LINE),
				_f("直線方程式", "斜率 4/3、過 (1, −2)：y + 2 = \\frac{4}{3}(x − 1)。", "y = [0]x + [1]", ["4/3", "-10/3"],
					"y = \\frac{4}{3}x − \\frac{10}{3}", "y = \\frac{4}{3}x − \\frac{4}{3} − 2。", T_LINE),
				_f("鉛直線", "過 (1, −2) 的鉛直線。", "x = [0]", ["1"],
					"L₂：y = \\frac{4}{3}x − \\frac{10}{3} 或 x = 1", "鉛直線 x = 點的 x 坐標。", T_LINE),
			 ]},
		 ]},

		{"id": "geo", "chapter": 2, "type": "forge", "title": "圖形上的和角",
		 "story": "把圖形裡的大角拆成兩個直角三角形的角，每個小角的 sin、cos 都能直接讀出來，再用和角公式合起來。",
		 "insight": "解題的樣子：① 把要求的角拆成兩個角（α + β）② 在直角三角形裡讀出 sin α、cos α、sin β、cos β ③ 代入和角公式。座標平面上，用斜率 = tan（傾斜角），再用 tan 的差角公式。",
		 "variants": [
			{"eq": "扇形 AOB 的半徑為 25，P 在弧 AB 上，\nP 到 OA、OB 的距離分別是 7、15，求 sin∠AOB",
			 "steps": [
				_f("兩個小角", "P 到 OA 的距離 = 25 sin∠AOP = 7；P 到 OB 的距離 = 25 sin∠POB = 15。", "cos∠AOP = [0]，cos∠POB = [1]", ["24/25", "4/5"],
					"sin∠AOP = 7/25 → cos = 24/25；sin∠POB = 3/5 → cos = 4/5（都是銳角）", "7-24-25、3-4-5 直角三角形。", T_GEO),
				_f("兩個乘積", "∠AOB = ∠AOP + ∠POB，sin(α + β) = sin α cos β + cos α sin β。先算兩個乘積。", "sin α cos β = [0]，cos α sin β = [1]", ["28/125", "72/125"],
					"(7/25)(4/5) = 28/125，(24/25)(3/5) = 72/125", "分子乘分子、分母乘分母。", T_GEO),
				_f("相加", "兩個乘積相加，再約分。", "sin∠AOB = [0]", ["4/5"],
					"sin∠AOB = 100/125 = 4/5", "28 + 72 = 100。", T_GEO),
			 ],
				 "circles": [{"kind": "fig", "after": -1,
					"pts": {"O": [0, 0], "A": [25, 0], "B": [15, 20], "P": [24, 7], "E": [24, 0], "F": [12, 16]},
					"carcs": [["O", "A", "B"]], "segs": [["O", "A", ""], ["O", "B", ""], ["O", "P", "25"], ["P", "E", "7"], ["P", "F", "15"]],
					"right": [["E", "O", "P"], ["F", "O", "P"]], "angles": [], "hide": ["E", "F"]}],
			},
			{"eq": "O 為原點，A(3, 1)、B(−1, 2)，\n∠AOB = θ，求 tan θ",
			 "steps": [
				_f("斜率", "OA 的斜率 = 1/3。OB 的斜率是 y ÷ x：", "OB 的斜率 = [0]", ["-2"],
					"OB 的斜率 = 2 ÷ (−1) = −2", "2 ÷ (−1)。", T_GEO),
				_f("分子分母", "tan θ = (m₂ − m₁) ÷ (1 + m₁m₂)，m₁ = 1/3、m₂ = −2。先算分子、分母。", "分子 = [0]，分母 = [1]", ["-7/3", "1/3"],
					"分子 −2 − 1/3 = −7/3，分母 1 + (−2)(1/3) = 1/3", "−2 = −6/3。", T_GEO),
				_f("tan θ", "分子 ÷ 分母：", "tan θ = [0]", ["-7"], "tan θ = (−7/3) ÷ (1/3) = −7", "−7/3 × 3。", T_GEO),
				_c("鈍角還是銳角", "tan θ = −7 < 0，θ 是？", ["鈍角", "銳角"], 0,
					"tan 是負的：θ 在第二象限，是鈍角。", "OB 在第二象限、OA 在第一象限。", "θ 是鈍角", T_GEO),
			 ],
				 "circles": [{"kind": "fig", "after": -1, "axes": true,
					"pts": {"O": [0, 0], "A(3, 1)": [3, 1], "B(−1, 2)": [-1, 2]},
					"segs": [["O", "A(3, 1)", ""], ["O", "B(−1, 2)", ""]], "angles": [["O", "A(3, 1)", "B(−1, 2)", "θ"]]}],
			},
			{"eq": "四邊形 ABCD 中，∠ABD = ∠BCD = 90°，\\ol{AB} = 12、\n\\ol{BD} = 5、\\ol{BC} = 3、\\ol{CD} = 4（A、C 在 \\ol{BD} 的兩側），求 cos∠ADC",
			 "steps": [
				_f("△ABD", "△ABD 中 ∠ABD = 90°，\\ol{AB} = 12、\\ol{BD} = 5。", "\\ol{AD} = [0]，cos∠ADB = [1]，sin∠ADB = [2]", ["13", "5/13", "12/13"],
					"\\ol{AD} = 13，cos∠ADB = 5/13，sin∠ADB = 12/13", "5-12-13。", T_GEO),
				_f("△BCD", "△BCD 中 ∠BCD = 90°，\\ol{BC} = 3、\\ol{CD} = 4、\\ol{BD} = 5。", "cos∠BDC = [0]，sin∠BDC = [1]", ["4/5", "3/5"],
					"cos∠BDC = 4/5，sin∠BDC = 3/5", "鄰邊 \\ol{CD} 除以斜邊 \\ol{BD}。", T_GEO),
				_f("兩個乘積", "∠ADC = ∠ADB + ∠BDC，cos(α + β) = cos α cos β − sin α sin β。先算兩個乘積。", "cos α cos β = [0]，sin α sin β = [1]", ["20/65", "36/65"],
					"(5/13)(4/5) = 20/65，(12/13)(3/5) = 36/65", "分子乘分子、分母乘分母。", T_GEO),
				_f("相減", "cos α cos β 減掉 sin α sin β。", "cos∠ADC = [0]", ["-16/65"],
					"cos∠ADC = 20/65 − 36/65 = −16/65", "20 − 36 = −16。", T_GEO),
			 ],
				 "circles": [{"kind": "fig", "after": -1,
					"pts": {"A": [-12, 0], "B": [0, 0], "D": [0, 5], "C": [2.4, 1.8]},
					"segs": [["A", "B", "12"], ["B", "D", "5"], ["A", "D", ""], ["B", "C", "3"], ["C", "D", "4"]],
					"right": [["B", "A", "D"], ["C", "B", "D"]], "angles": [["D", "A", "C", ""]]}],
			},
		 ]},

		{"id": "judge", "chapter": 2, "type": "forge", "title": "真假判斷",
		 "story": "段考最愛的「下列何者為真」：和角公式、三角形的內角和，一個一個選項檢查。",
		 "insight": "和差角公式不是「分配律」：sin(α + β) ≠ sin α + sin β。△ABC 中：sin(A + B) = sin C、cos(A + B) = −cos C、tan(A + B) = −tan C。cos A cos B − sin A sin B = cos(A + B)，若 > 0 則 A + B < 90°，C 是鈍角。",
		 "variants": [
			{"eq": "△ABC 中，下列敘述對還是錯？",
			 "steps": [
				_tf("(A) sin", "(A) sin(A + B) = sin C", true, "A + B = 180° − C，sin(180° − C) = sin C。", "(A) 對：sin(A + B) = sin C"),
				_tf("(B) cos", "(B) cos(A + B) = cos C", false, "cos(180° − C) = −cos C。", "(B) 錯：cos(A + B) = −cos C"),
				_tf("(C) tan", "(C) tan(A + B) = −tan C（C ≠ 90°）", true, "tan(180° − C) = −tan C。", "(C) 對：tan(A + B) = −tan C"),
				_tf("(D) 合併", "(D) sin A cos B + cos A sin B = sin C", true, "合併成 sin(A + B) = sin C。", "(D) 對：左邊 = sin(A + B) = sin C"),
				_tf("(E) 銳角", "(E) 若 cos A cos B > sin A sin B，則 △ABC 必為銳角三角形", false,
					"cos A cos B − sin A sin B = cos(A + B) > 0 ⇒ A + B < 90° ⇒ C > 90°，是鈍角三角形。", "(E) 錯：cos(A + B) > 0 ⇒ C 是鈍角"),
			 ]},
			{"eq": "α = 60°、β = 30°，下列敘述對還是錯？",
			 "steps": [
				_tf("(A) 分配", "(A) sin(α + β) = sin α + sin β", false, "sin 90° = 1，sin 60° + sin 30° = (√3 + 1)/2 ≠ 1。", "(A) 錯：公式不是分配律"),
				_tf("(B) 差角", "(B) cos(α − β) = cos α cos β + sin α sin β", true, "這就是差角公式。", "(B) 對：差角公式"),
				_tf("(C) tan", "(C) tan(α + β) = tan α + tan β", false, "tan 90° 不存在，而且公式有分母 1 − tan α tan β。", "(C) 錯：tan 和角有分母"),
				_tf("(D) sin", "(D) sin(α − β) = 1/2", true, "sin(60° − 30°) = sin 30° = 1/2。", "(D) 對：sin 30° = 1/2"),
				_tf("(E) cos", "(E) cos(α + β) = 0", true, "cos(60° + 30°) = cos 90° = 0。", "(E) 對：cos 90° = 0"),
			 ]},
		 ]},

		{"id": "boss2", "chapter": 2, "type": "forge", "title": "大師試煉", "time": 300.0,
		 "story": "限時 300 秒！象限、公式、直線的夾角，全部派上用場。",
		 "insight": "象限定正負 → 直角三角形求另一個值 → 代進和差角公式；兩直線的夾角用 tan θ = \\frac{|m₂ − m₁|}{|1 + m₁m₂|}。",
		 "variants": [
			{"eq": "sin α = 3/5（α 在第二象限）、\ncos β = −12/13（β 在第三象限），求 sin(α + β)",
			 "steps": [
				_f("cos α", "α 在第二象限，cos α < 0。", "cos α = [0]", ["-4/5"], "cos α = −4/5", "邊長 3、4、5。", T_QUAD),
				_f("sin β", "β 在第三象限，sin β < 0；邊長 5、12、13。", "sin β = [0]", ["-5/13"], "sin β = −5/13", "第三象限 sin < 0。", T_QUAD),
				_f("兩個乘積", "sin(α + β) = sin α cos β + cos α sin β。先算兩個乘積。", "sin α cos β = [0]，cos α sin β = [1]", ["-36/65", "20/65"],
					"sin α cos β = (3/5)(−12/13) = −36/65，cos α sin β = (−4/5)(−5/13) = 20/65", "注意正負號。", T_QUAD),
				_f("相加", "把兩個乘積加起來。", "sin(α + β) = [0]", ["-16/65"],
					"sin(α + β) = −36/65 + 20/65 = −16/65", "−36 + 20 = −16。", T_QUAD),
			 ]},
			{"eq": "過 P(0, 2) 作直線 L₂，和 L₁：y = 3x − 5\n夾角 θ 滿足 tan θ = 1/2，求 L₂",
			 "steps": [
				_lines("找直線", "拖動 L₂ 的斜率，找出夾角 tan θ = 1/2 的直線（L₁ 的斜率是 3）。", [0.0, 2.0], 3.0, 0.5, [1.0, -7.0],
					"夾角 tan θ = 1/2 的直線，斜率是 1 或 −7", "斜率 3 的直線旁邊，一條平緩一點、一條往反方向。"),
				_f("平方整理", "\\frac{|m − 3|}{|1 + 3m|} = 1/2，兩邊平方：4(m − 3)² = (1 + 3m)²。展開、移項、同除以 −5：", "m² + [0]m − [1] = 0", ["6", "7"],
					"4m² − 24m + 36 = 9m² + 6m + 1 ⇒ 5m² + 30m − 35 = 0 ⇒ m² + 6m − 7 = 0", "左邊 4m² − 24m + 36，右邊 9m² + 6m + 1。", T_LINE),
				_f("因式分解", "m² + 6m − 7 = (m + 7)(m − 1) = 0。", "m = [0] 或 [1]", ["1", "-7"],
					"(m + 7)(m − 1) = 0 ⇒ m = 1 或 −7", "兩數相乘 −7、相加 6。", T_LINE, "set"),
				_f("直線方程式", "斜率 −7、過 (0, 2)：", "y = [0]x + [1]", ["-7", "2"],
					"y = −7x + 2", "過 y 軸上的 (0, 2)，截距就是 2。", T_LINE),
				_f("另一條", "斜率 1、過 (0, 2)：", "y = [0]x + [1]", ["1", "2"],
					"L₂：y = −7x + 2 或 y = x + 2", "截距還是 2。", T_LINE),
			 ]},
		 ]},
	]
