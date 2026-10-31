extends RefCounted
## 三角函數 第七大關「疊合燈塔」題庫（對應講義 1-2 重點三：正餘弦函數的疊合）
## 題目的數字都是自己設計的（和講義、學校的題目不一樣）。
##
## 引擎：level_trig7_lighthouse.gd（繼承第六關）。步驟除了 choice、fill、filter、order，多三種動手的：
##   phasor 相位指針：a、b（目標點 (a, b)）、a_txt／b_txt（畫面上寫的樣子）、ftxt（目標的式子）、
##          rmax（座標範圍，r 滑桿只會出現 ≤ rmax 的選項）、form "sin"（r sin(x + φ)）或 "cos"（r cos(x − θ)）
##   peak   找亮點：a、b、goal（"max"、"min"、"zero"）、xs（正確的 x，單位度，可以不只一個）、
##          dom（x 的範圍，預設 0～360，每格 15°）、word（答錯時說「最亮」「最暗」「熄滅」）
##   wave   拼光束：expr（左邊顯示的式子）、a、b（目標是 a sin x + b cos x）、tokens（積木）、cols（一排幾個）
##          積木可以是 "sin x"、"cos x"、"sin(x+30°)"、"cos(x−45°)"、數字（"2"、"√3"、"√3/2"、"1/2"）和 + − × ÷ ( )
const UITheme := preload("game_theme.gd")

const SB := preload("step_bank.gd")

const T_LIGHT := "trig_lightmax"
const T_FORM := "trig_mergeform"
const T_EXPAND := "trig_expandform"
const T_PHASE := "trig_phase"
const T_PEAK := "trig_peak"
const T_BRIGHT := "trig_brightcmp"
const T_RANGE := "trig_peakrange"
const T_NONSP := "trig_nonspecial"
const T_HOMOG := "trig_homog"
const T_PARAM := "trig_param"
const T_COMBO := "trig_combo"
const T_APPLY := "trig_lightapply"
const T_JUDGE7 := "trig_lightjudge"

const S2 := 1.4142135623730951
const S3 := 1.7320508075688772

const TK_EXP1 := ["2", "4", "√3", "sin x", "cos x", "+", "×"]
const TK_EXP2 := ["2", "√2", "sin x", "cos x", "+", "−", "×"]
const TK_EXP3 := ["3", "√3", "sin x", "cos x", "+", "×"]


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return SB.fill(name, q, template, answers, line, nudge, tag, mode)


static func _tf(name: String, stmt: String, truth: bool, why: String, line: String) -> Dictionary:
	return _c(name, stmt, ["對", "錯"] if truth else ["錯", "對"], 0, why, why, line, T_JUDGE7)


## 相位指針
static func _phasor(name: String, q: String, a: float, b: float, a_txt: String, b_txt: String, ftxt: String,
		rmax: float, line: String, nudge: String, tag: String, form := "sin") -> Dictionary:
	return {"kind": "phasor", "name": name, "q": q, "a": a, "b": b, "a_txt": a_txt, "b_txt": b_txt, "ftxt": ftxt,
		"rmax": rmax, "form": form, "line": line, "nudge": nudge, "tag": tag}


## 找亮點
static func _peak(name: String, q: String, a: float, b: float, goal: String, xs: Array, line: String, nudge: String,
		tag: String, dom := [0.0, 360.0]) -> Dictionary:
	return {"kind": "peak", "name": name, "q": q, "a": a, "b": b, "goal": goal, "xs": xs.duplicate(),
		"dom": dom.duplicate(), "word": {"max": "最亮", "min": "最暗", "zero": "熄滅"}[goal],
		"line": line, "nudge": nudge, "tag": tag}


## 拼光束
static func _wave(name: String, q: String, expr: String, a: float, b: float, tokens: Array, line: String, nudge: String,
		tag: String, cols := 3) -> Dictionary:
	return {"kind": "wave", "name": name, "q": q, "expr": expr, "a": a, "b": b, "tokens": tokens.duplicate(),
		"cols": cols, "line": line, "nudge": nudge, "tag": tag}


static func slots() -> Array:
	var out := _slots()
	for slot in out:
		slot["plain"] = true
		slot["params"] = slot.get("params", [])
		SB.fix_roots(slot)
	return out


static func _slots() -> Array:
	return [
		# ======================= 第一章．合成一道光 =======================
		{"id": "form", "chapter": 1, "type": "forge", "title": "兩道光合成一道",
		 "story": "燈塔有兩盞燈：一盞隨 sin x 閃，一盞隨 cos x 閃。把它們疊起來，其實只是一道比較強、位置偏了一點的光。",
		 "insight": "a sin x + b cos x = r sin(x + φ)，其中 r = √(a² + b²)，cos φ = \\frac{a}{r}，sin φ = \\frac{b}{r}。點 (a, b) 到原點的距離是 r，它的方向角就是 φ。",
		 "variants": [
			{"eq": "把 sin x + √3 cos x\n化成 r sin(x + φ)",
			 "steps": [
				_f("判斷 r", "r = √(a² + b²)：a 是 sin x 的係數 1，b 是 cos x 的係數 √3。", "r = √(1² + (√3)²) = [0]", ["2"],
					"r = √(1² + (√3)²) = 2", "1 + 3 = 4。", T_FORM),
				_c("哪個和角公式", "把 r = 2 提出來：sin x + √3 cos x = 2[(1/2) sin x + (√3/2) cos x]。要湊成 sin(x + φ)，括號裡對應哪一個和角公式？", ["sin(x + φ) = sin x cos φ + cos x sin φ", "sin(x + φ) = sin x sin φ + cos x cos φ", "sin(x − φ) = sin x cos φ − cos x sin φ", "cos(x + φ) = cos x cos φ − sin x sin φ"], 0,
					"sin(x + φ) = sin x cos φ + cos x sin φ：sin x 配 cos φ、cos x 配 sin φ。", "sin x 後面接的是 cos φ。", "sin x + √3 cos x = 2[(1/2) sin x + (√3/2) cos x]\n對照 sin(x + φ) = sin x cos φ + cos x sin φ", T_FORM),
				_c("cos φ、sin φ", "對照 sin x cos φ + cos x sin φ，cos φ 和 sin φ 各是多少？", ["cos φ = 1/2、sin φ = √3/2", "cos φ = √3/2、sin φ = 1/2", "cos φ = 1、sin φ = √3"], 0,
					"sin x 的係數是 cos φ，cos x 的係數是 sin φ。", "cos φ = a ÷ r，sin φ = b ÷ r。", "cos φ = 1/2、sin φ = √3/2", T_FORM),
				_f("合成", "找出 φ，代回 r sin(x + φ)。", "sin x + √3 cos x = [0] sin(x + [1]°)", ["2", "60"],
					"sin x + √3 cos x = 2 sin(x + 60°)", "cos φ = 1/2、sin φ = √3/2 的角。", T_FORM),
				_phasor("相位指針", "最後用燈塔驗證：拖動 r 與 φ，讓箭頭壓在金色的目標點 (1, √3) 上。", 1.0, S3, "1", "√3", "sin x + √3 cos x", 3.5,
					"箭頭長 r = 2、角度 φ = 60°", "r = 2，cos φ = 1/2、sin φ = √3/2 的角是 60°。", T_FORM),
			 ]},
			{"eq": "把 √3 sin x − cos x\n化成 r sin(x + φ)",
			 "steps": [
				_f("判斷 r", "r = √(a² + b²)：a 是 sin x 的係數 √3，b 是 cos x 的係數 −1。", "r = √((√3)² + (−1)²) = [0]", ["2"],
					"r = √((√3)² + (−1)²) = 2", "3 + 1 = 4。", T_FORM),
				_c("哪個和角公式", "把 r = 2 提出來：√3 sin x − cos x = 2[(√3/2) sin x − (1/2) cos x]。要湊成 sin(x + φ)，括號裡對應哪一個和角公式？（−(1/2) cos x 看成 + (−1/2) cos x）", ["sin(x + φ) = sin x cos φ + cos x sin φ", "sin(x + φ) = sin x sin φ + cos x cos φ", "sin(x − φ) = sin x cos φ − cos x sin φ", "cos(x + φ) = cos x cos φ − sin x sin φ"], 0,
					"sin(x + φ) = sin x cos φ + cos x sin φ：sin x 配 cos φ、cos x 配 sin φ。", "sin x 後面接的是 cos φ。", "√3 sin x − cos x = 2[(√3/2) sin x − (1/2) cos x]\n對照 sin(x + φ) = sin x cos φ + cos x sin φ", T_FORM),
				_c("cos φ、sin φ", "對照 sin x cos φ + cos x sin φ，cos φ 和 sin φ 各是多少？", ["cos φ = √3/2、sin φ = −1/2", "cos φ = −1/2、sin φ = √3/2", "cos φ = √3/2、sin φ = 1/2"], 0,
					"sin x 的係數是 cos φ，cos x 的係數是 sin φ。", "cos φ = a ÷ r，sin φ = b ÷ r。", "cos φ = √3/2、sin φ = −1/2", T_FORM),
				_f("合成", "找出 φ，代回 r sin(x + φ)。", "√3 sin x − cos x = [0] sin(x − [1]°)", ["2", "30"],
					"√3 sin x − cos x = 2 sin(x − 30°)", "cos φ = √3/2、sin φ = −1/2 的角。", T_FORM),
				_phasor("相位指針", "最後用燈塔驗證：拖動 r 與 φ，讓箭頭壓在金色的目標點 (√3, −1) 上。", S3, -1.0, "√3", "−1", "√3 sin x − cos x", 3.5,
					"箭頭長 r = 2、角度 φ = −30°", "目標點在右下方，所以角度是負的。", T_FORM),
			 ]},
			{"eq": "把 2 sin x + 2 cos x\n化成 r sin(x + φ)",
			 "steps": [
				_f("判斷 r", "r = √(a² + b²)：a 是 sin x 的係數 2，b 是 cos x 的係數 2。", "r = √(2² + 2²) = [0]", ["2√2"],
					"r = √(2² + 2²) = 2√2", "4 + 4 = 8，√8 = 2√2。", T_FORM),
				_c("哪個和角公式", "把 r = 2√2 提出來：2 sin x + 2 cos x = 2√2[(√2/2) sin x + (√2/2) cos x]。要湊成 sin(x + φ)，括號裡對應哪一個和角公式？", ["sin(x + φ) = sin x cos φ + cos x sin φ", "sin(x + φ) = sin x sin φ + cos x cos φ", "sin(x − φ) = sin x cos φ − cos x sin φ", "cos(x + φ) = cos x cos φ − sin x sin φ"], 0,
					"sin(x + φ) = sin x cos φ + cos x sin φ：sin x 配 cos φ、cos x 配 sin φ。", "sin x 後面接的是 cos φ。", "2 sin x + 2 cos x = 2√2[(√2/2) sin x + (√2/2) cos x]\n對照 sin(x + φ) = sin x cos φ + cos x sin φ", T_FORM),
				_c("cos φ、sin φ", "對照 sin x cos φ + cos x sin φ，cos φ 和 sin φ 各是多少？", ["cos φ = √2/2、sin φ = √2/2", "cos φ = 1/2、sin φ = 1/2", "cos φ = 2、sin φ = 2"], 0,
					"sin x 的係數是 cos φ，cos x 的係數是 sin φ。", "cos φ = a ÷ r，sin φ = b ÷ r。", "cos φ = √2/2、sin φ = √2/2", T_FORM),
				_f("合成", "找出 φ，代回 r sin(x + φ)。", "2 sin x + 2 cos x = [0] sin(x + [1]°)", ["2√2", "45"],
					"2 sin x + 2 cos x = 2√2 sin(x + 45°)", "cos φ = √2/2、sin φ = √2/2 的角。", T_FORM),
				_phasor("相位指針", "最後用燈塔驗證：拖動 r 與 φ，讓箭頭壓在金色的目標點 (2, 2) 上。", 2.0, 2.0, "2", "2", "2 sin x + 2 cos x", 3.5,
					"箭頭長 r = 2√2、角度 φ = 45°", "a = b：目標點正好在對角線上。", T_FORM),
			 ]},
		 ]},

		{"id": "expand", "chapter": 1, "type": "forge", "title": "拆開與合起來",
		 "story": "合成的反方向是展開：r sin(x + φ) 用和角公式拆成 sin x 和 cos x。拆得開，才合得回去。",
		 "insight": "r sin(x + φ) = r cos φ · sin x + r sin φ · cos x。反過來，a sin x + b cos x 要找 r 和 φ，使 r cos φ = a、r sin φ = b。拆開和合起來是同一條公式。",
		 "variants": [
			{"eq": "4 sin(x + 30°) 展開，\n再把 sin x + cos x 合成",
			 "steps": [
				_f("展開", "先用和角公式展開，再算出係數：4 sin(x + 30°) = 4 sin x cos 30° + 4 cos x sin 30°。", "= [0] sin x + [1] cos x", ["2√3", "2"],
					"4 × √3/2 = 2√3；4 × 1/2 = 2", "cos 30° = √3/2，sin 30° = 1/2。", T_EXPAND),
				_wave("拼展開", "照推導紀錄算好的係數，用積木拼出展開式，看兩條光線有沒有重合。", "4 sin(x + 30°)", 2.0 * S3, 2.0, TK_EXP1,
					"4 sin(x + 30°) = 2√3 sin x + 2 cos x", "4 乘 cos 30° 是 2√3，4 乘 sin 30° 是 2。", T_EXPAND),
				_f("求 r", "反過來合成 sin x + cos x：r = √(a² + b²)。", "r = √(1² + 1²) = [0]", ["√2"],
					"sin x + cos x：r = √2", "a² + b² 再開根號。", T_EXPAND),
				_f("求 φ", "cos φ = a ÷ r = √2/2，sin φ = b ÷ r = √2/2。", "φ = [0]°", ["45"],
					"cos φ = √2/2、sin φ = √2/2，φ = 45°", "哪個角的 cos 是 √2/2、sin 是 √2/2？", T_EXPAND),
				_wave("拼合成", "用剛剛算好的 r 和 φ，把它拼成一個 sin，看兩條光線有沒有重合。", "sin x + cos x", 1.0, 1.0,
					["√2", "2", "sin(x+45°)", "sin(x−45°)", "cos(x+45°)", "×", "+"],
					"sin x + cos x = √2 sin(x + 45°)", "r = √2；角度是 45° 還是 −45°？看畫面哪一條藍線重合。", T_EXPAND),
			 ]},
			{"eq": "2 sin(x − 45°) 展開，\n再把 √3 sin x + cos x 合成",
			 "steps": [
				_f("展開", "先用和角公式展開，再算出係數：2 sin(x − 45°) = 2 sin x cos 45° − 2 cos x sin 45°。", "= [0] sin x − [1] cos x", ["√2", "√2"],
					"2 × √2/2 = √2", "2 × √2/2。", T_EXPAND),
				_wave("拼展開", "照推導紀錄算好的係數，用積木拼出展開式，看兩條光線有沒有重合。", "2 sin(x − 45°)", S2, -S2, TK_EXP2,
					"2 sin(x − 45°) = √2 sin x − √2 cos x", "cos 45° = sin 45° = √2/2，乘 2 是 √2；cos 項的符號是負的。", T_EXPAND),
				_f("求 r", "反過來合成 √3 sin x + cos x：r = √(a² + b²)。", "r = √((√3)² + 1²) = [0]", ["2"],
					"√3 sin x + cos x：r = 2", "a² + b² 再開根號。", T_EXPAND),
				_f("求 φ", "cos φ = a ÷ r = √3/2，sin φ = b ÷ r = 1/2。", "φ = [0]°", ["30"],
					"cos φ = √3/2、sin φ = 1/2，φ = 30°", "哪個角的 cos 是 √3/2、sin 是 1/2？", T_EXPAND),
				_wave("拼合成", "用剛剛算好的 r 和 φ，把它拼成一個 sin，看兩條光線有沒有重合。", "√3 sin x + cos x", S3, 1.0,
					["2", "sin(x+30°)", "sin(x+60°)", "sin(x−30°)", "cos(x−30°)", "×", "+"],
					"√3 sin x + cos x = 2 sin(x + 30°)", "r = 2；cos φ = √3/2。", T_EXPAND),
			 ]},
			{"eq": "6 sin(x + 60°) 展開，\n再把 3 sin x − 3 cos x 合成",
			 "steps": [
				_f("展開", "先用和角公式展開，再算出係數：6 sin(x + 60°) = 6 sin x cos 60° + 6 cos x sin 60°。", "= [0] sin x + [1] cos x", ["3", "3√3"],
					"6 × 1/2 = 3；6 × √3/2 = 3√3", "cos 60° = 1/2，sin 60° = √3/2。", T_EXPAND),
				_wave("拼展開", "照推導紀錄算好的係數，用積木拼出展開式，看兩條光線有沒有重合。", "6 sin(x + 60°)", 3.0, 3.0 * S3, TK_EXP3,
					"6 sin(x + 60°) = 3 sin x + 3√3 cos x", "6 乘 cos 60° = 3；6 乘 sin 60° = 3√3。", T_EXPAND),
				_f("求 r", "反過來合成 3 sin x − 3 cos x：r = √(a² + b²)。", "r = √(3² + (−3)²) = [0]", ["3√2"],
					"3 sin x − 3 cos x：r = 3√2", "a² + b² 再開根號。", T_EXPAND),
				_f("求 φ", "cos φ = a ÷ r = √2/2，sin φ = b ÷ r = −√2/2。", "φ = [0]°", ["-45"],
					"cos φ = √2/2、sin φ = −√2/2，φ = −45°", "哪個角的 cos 是 √2/2、sin 是 −√2/2？", T_EXPAND),
				_wave("拼合成", "用剛剛算好的 r 和 φ，把它拼成一個 sin，看兩條光線有沒有重合。", "3 sin x − 3 cos x", 3.0, -3.0,
					["3", "√2", "sin(x−45°)", "sin(x+45°)", "cos(x−45°)", "×", "+"],
					"3 sin x − 3 cos x = 3√2 sin(x − 45°)", "r = 3√2；點 (3, −3) 在右下方。", T_EXPAND),
			 ]},
		 ]},

		{"id": "quad", "chapter": 1, "type": "forge", "title": "φ 在哪個象限",
		 "story": "a 或 b 是負的時候，目標點跑到別的象限。這時候只用 tan φ = b ÷ a 找角度很容易差 180°——要看點在哪裡。",
		 "insight": "φ 的方向就是點 (a, b) 的方向：由 (a, b) 的象限決定。cos φ = a/r 的正負看 a，sin φ = b/r 的正負看 b。只算 tan φ 會漏掉象限，所以一定要看 cos φ 和 sin φ 兩個。",
		 "variants": [
			{"eq": "把 −sin x + √3 cos x\n化成 r sin(x + φ)",
			 "steps": [
				_c("點在哪裡", "目標點 (a, b) = (−1, √3)，在第幾象限？", ["第二象限", "第一象限", "第三象限", "第四象限"], 0,
					"a 為負、b 為正：左上方，第二象限。", "x 坐標負、y 坐標正。", "(−1, √3) 在第二象限", T_PHASE),
				_phasor("相位指針", "拖動 r 與 φ，讓箭頭壓在目標點上。", -1.0, S3, "−1", "√3", "−sin x + √3 cos x", 3.5,
					"r = 2、φ = 120°", "點在左上方：角度比 90° 大。", T_PHASE),
				_f("合成", "cos φ = −1/2，sin φ = √3/2。", "−sin x + √3 cos x = [0] sin(x + [1]°)", ["2", "120"],
					"= 2 sin(x + 120°)", "第二象限的角：120°。", T_PHASE),
			 ]},
			{"eq": "把 −√3 sin x − cos x\n化成 r sin(x + φ)",
			 "steps": [
				_c("點在哪裡", "目標點 (a, b) = (−√3, −1)，在第幾象限？", ["第三象限", "第一象限", "第二象限", "第四象限"], 0,
					"a、b 都是負的：左下方，第三象限。", "兩個坐標都是負的。", "(−√3, −1) 在第三象限", T_PHASE),
				_phasor("相位指針", "拖動 r 與 φ，讓箭頭壓在目標點上。（角度可以取負的）", -S3, -1.0, "−√3", "−1", "−√3 sin x − cos x", 3.5,
					"r = 2、φ = −150°（也就是 210°）", "只算 tan φ = 1/√3 會得到 30°，但點在左下方。", T_PHASE),
				_f("合成", "cos φ = −√3/2，sin φ = −1/2，φ = −150°。", "−√3 sin x − cos x = [0] sin(x − [1]°)", ["2", "150"],
					"= 2 sin(x − 150°)", "−150° 寫成 x − 150°。", T_PHASE),
			 ]},
			{"eq": "把 2 sin x − 2√3 cos x\n化成 r sin(x + φ)",
			 "steps": [
				_c("點在哪裡", "目標點 (a, b) = (2, −2√3)，在第幾象限？", ["第四象限", "第一象限", "第二象限", "第三象限"], 0,
					"a 為正、b 為負：右下方，第四象限。", "x 坐標正、y 坐標負。", "(2, −2√3) 在第四象限", T_PHASE),
				_phasor("相位指針", "拖動 r 與 φ，讓箭頭壓在目標點上。", 2.0, -2.0 * S3, "2", "−2√3", "2 sin x − 2√3 cos x", 4.5,
					"r = 4、φ = −60°", "r = √(4 + 12)。", T_PHASE),
				_f("合成", "cos φ = 1/2，sin φ = −√3/2，φ = −60°。", "2 sin x − 2√3 cos x = [0] sin(x − [1]°)", ["4", "60"],
					"= 4 sin(x − 60°)", "r = 4。", T_PHASE),
			 ]},
		 ]},

		{"id": "peak", "chapter": 1, "type": "forge", "title": "燈塔的亮點",
		 "story": "合成之後，燈塔的光只有一個亮點，也只有一個最暗的地方。拖動 x，看看光束什麼時候最亮。",
		 "insight": "r sin(x + φ) 的最大值是 r，發生在 x + φ = 90° + 360°k；最小值是 −r，發生在 x + φ = 270° + 360°k；等於 0 在 x + φ = 180°k。週期是 2π。",
		 "variants": [
			{"eq": "f(x) = sin x + √3 cos x\n求最大值、最小值",
			 "steps": [
				_peak("找最亮", "拖動 x，讓光束最亮。（f(x) 最大）", 1.0, S3, "max", [30.0],
					"x = 30° 時最亮", "最亮時 x + 60° = 90°。", T_PEAK),
				_f("最大值", "f(x) = 2 sin(x + 60°)，最亮的時候 x + 60° = 90°。", "最大值 = [0]，x = [1]°", ["2", "30"],
					"最大值 2，在 x = 30°", "x = 90° − 60°。", T_PEAK),
				_peak("找最暗", "再拖動 x，讓光束最暗。（f(x) 最小）", 1.0, S3, "min", [210.0],
					"x = 210° 時最暗", "最暗時 x + 60° = 270°。", T_PEAK),
				_f("最小值", "最暗的時候 x + 60° = 270°。", "最小值 = [0]，x = [1]°", ["-2", "210"],
					"最小值 −2，在 x = 210°", "x = 270° − 60°。", T_PEAK),
			 ]},
			{"eq": "f(x) = √3 sin x − cos x\n求零點與最大值",
			 "steps": [
				_peak("找熄滅", "拖動 x，讓光束熄滅。（f(x) = 0，有兩個位置，找到一個就好）", S3, -1.0, "zero", [30.0, 210.0],
					"x = 30° 或 210° 時 f = 0", "f(x) = 2 sin(x − 30°)，x − 30° = 0 或 180°。", T_PEAK),
				_f("零點", "f(x) = 2 sin(x − 30°) = 0，x − 30° = 0° 或 180°（0° ≤ x < 360°）。", "x = [0]° 或 [1]°", ["30", "210"],
					"x = 30° 或 210°", "x − 30° = 0 或 180。", T_PEAK, "set"),
				_peak("找最亮", "再拖動 x，讓光束最亮。", S3, -1.0, "max", [120.0],
					"x = 120° 時最亮", "最亮時 x − 30° = 90°。", T_PEAK),
				_f("最大值", "x − 30° = 90°。", "最大值 = [0]，x = [1]°", ["2", "120"],
					"最大值 2，在 x = 120°", "x = 90° + 30°。", T_PEAK),
			 ]},
			{"eq": "f(x) = sin x − cos x\n求最大值與週期",
			 "steps": [
				_peak("找最亮", "拖動 x，讓光束最亮。", 1.0, -1.0, "max", [135.0],
					"x = 135° 時最亮", "f(x) = √2 sin(x − 45°)，x − 45° = 90°。", T_PEAK),
				_f("最大值", "f(x) = √2 sin(x − 45°)。", "最大值 = [0]，x = [1]°", ["√2", "135"],
					"最大值 √2，在 x = 135°", "x = 90° + 45°。", T_PEAK),
				_f("週期", "r sin(x + φ) 的週期和 sin x 一樣。", "週期 = [0]π", ["2"],
					"週期 2π", "x 的係數是 1：2π ÷ 1。", T_PEAK),
			 ]},
		 ]},

		{"id": "bright", "chapter": 1, "type": "forge", "title": "比比誰最亮",
		 "story": "不用合成出角度，也能比較誰的光最強：只要算每一道光的 r。",
		 "insight": "a sin x + b cos x 的最大值是 √(a² + b²)，最小值是 −√(a² + b²)。比較大小只要比 a² + b²，不用開根號。",
		 "variants": [
			{"eq": "四道光，比較最大亮度",
			 "steps": [
				SB.order("把四道光的最大亮度，由小到大排好。（點按鈕，依序放進去）", [
					SB.item("A", "sin x + cos x", S2),
					SB.item("B", "√3 sin x + cos x", 2.0),
					SB.item("C", "2 sin x + 2 cos x", 2.0 * S2),
					SB.item("D", "3 sin x − 4 cos x", 5.0)],
					"最大值：A = √2、B = 2、C = 2√2、D = 5", "各自算 √(a² + b²)：2、4、8、25 的平方根。", T_BRIGHT, "比亮度"),
				_f("最亮的", "最亮的是 D：3 sin x − 4 cos x。", "最大值 = [0]", ["5"],
					"√(9 + 16) = 5", "3² + 4² = 25。", T_BRIGHT),
			 ]},
			{"eq": "哪些光的最大值是整數？",
			 "steps": [
				SB.with_pre(_filter("篩選", "最大值是整數的才留下。", ["sin x + cos x", "3 sin x + 4 cos x", "√3 sin x + cos x",
					"5 sin x − 12 cos x", "2 sin x + cos x"], [false, true, true, true, false],
					"留下 3 sin x + 4 cos x（5）、√3 sin x + cos x（2）、5 sin x − 12 cos x（13）；丟掉 √2 與 √5",
					"算 a² + b²：2、25、4、169、5；是完全平方數的才留下。"), "f 的最大值是 √(a² + b²)。"),
				_f("最大的", "留下的三道光，最亮的是 5 sin x − 12 cos x。", "最大值 = [0]", ["13"],
					"√(25 + 144) = 13", "5² + 12² = 169。", T_BRIGHT),
			 ]},
		 ]},

		{"id": "speed", "chapter": 1, "type": "speed", "title": "速算光束", "time": 160.0,
		 "story": "看到 a sin x ± b cos x，立刻說出最大值或最小值！",
		 "insight": "最大值 √(a² + b²)，最小值 −√(a² + b²)。常見的：3、4、5；5、12、13；8、15、17；1、√3、2；1、1、√2。",
		 "variants": [{"gen": "light", "count": 8}]},

		{"id": "boss1", "chapter": 1, "type": "forge", "title": "第一章試煉", "time": 300.0,
		 "story": "限時 300 秒！轉指針、拼光束、找亮點，把合成一道光的本事全部用上。",
		 "insight": "a sin x + b cos x = r sin(x + φ)：r = √(a² + b²)，cos φ = a/r，sin φ = b/r；最大值 r，最小值 −r。",
		 "variants": [
			{"eq": "f(x) = √3 sin x + 3 cos x\n合成並求最大值",
			 "steps": [
				_phasor("相位指針", "拖動 r 與 φ，讓箭頭壓在目標點 (√3, 3) 上。", S3, 3.0, "√3", "3", "√3 sin x + 3 cos x", 4.5,
					"r = 2√3、φ = 60°", "r = √(3 + 9) = √12。", T_FORM),
				_f("合成", "cos φ = 1/2，sin φ = √3/2。", "f(x) = [0] sin(x + [1]°)", ["2√3", "60"],
					"f(x) = 2√3 sin(x + 60°)", "r = 2√3。", T_FORM),
				_peak("找最亮", "拖動 x，讓光束最亮。", S3, 3.0, "max", [30.0],
					"x = 30° 時最亮", "x + 60° = 90°。", T_PEAK),
				_f("最大值", "最亮的時候 x = 30°。", "最大值 = [0]", ["2√3"],
					"最大值 = 2√3", "最大值就是 r。", T_LIGHT),
			 ]},
			{"eq": "f(x) = 3 sin x − 3 cos x\n合成並求最小值",
			 "steps": [
				_wave("拼合成", "用積木把 3 sin x − 3 cos x 合成一個 sin。", "3 sin x − 3 cos x", 3.0, -3.0,
					["3", "√2", "sin(x−45°)", "sin(x+45°)", "cos(x−45°)", "×", "+"],
					"f(x) = 3√2 sin(x − 45°)", "r = 3√2，點 (3, −3) 在第四象限。", T_FORM),
				_f("最大最小", "r = 3√2。", "最大值 = [0]，最小值 = [1]", ["3√2", "-3√2"],
					"M = 3√2，m = −3√2", "最小值是 −r。", T_LIGHT),
				_peak("找最暗", "拖動 x，讓光束最暗。", 3.0, -3.0, "min", [315.0],
					"x = 315° 時最暗", "x − 45° = 270°。", T_PEAK),
			 ]},
		 ]},

		# ======================= 第二章．疊合的變身 =======================
		{"id": "nonsp", "chapter": 2, "type": "forge", "title": "非特殊角",
		 "story": "7、24、25 這種三邊的光，φ 不是特殊角——但沒關係，只要記得 cos φ、sin φ 的分數，最亮的時候 sin x 和 cos x 也就知道了。",
		 "insight": "φ 不是特殊角時，不用算出角度：r = √(a² + b²)，cos φ = a/r，sin φ = b/r。最大值發生在 x + φ = 90°，所以 sin x = cos φ = a/r，cos x = sin φ = b/r。最小值發生時，sin x = −a/r，cos x = −b/r。",
		 "variants": [
			{"eq": "f(x) = 7 sin x + 24 cos x\n求最大值，並求最大時的 sin x、cos x",
			 "steps": [
				_f("求 r", "r = √(a² + b²)。", "r = [0]", ["25"],
					"r = √(49 + 576) = 25", "7² + 24² = 625。", T_NONSP),
				_f("cos φ、sin φ", "疊合成 f(x) = 25 sin(x + φ)，其中 cos φ = a ÷ r、sin φ = b ÷ r。", "cos φ = [0]，sin φ = [1]", ["7/25", "24/25"],
					"cos φ = 7/25、sin φ = 24/25（φ 在第一象限）", "7 ÷ 25、24 ÷ 25。", T_NONSP),
				_f("最亮的時候", "sin(x + φ) = 1 時最大：取 x + φ = 90°，x = 90° − φ，所以 sin x = cos φ，cos x = sin φ。", "最大值 = [0]，sin x = [1]，cos x = [2]",
					["25", "7/25", "24/25"], "最大值 25；sin x = 7/25、cos x = 24/25", "sin(90° − φ) = cos φ。", T_NONSP),
			 ]},
			{"eq": "f(x) = 8 cos x − 15 sin x\n求最大值，並求最大時的 sin x、cos x",
			 "steps": [
				_f("整理", "排成 a sin x + b cos x 的樣子。", "f(x) = [0] sin x + [1] cos x", ["-15", "8"],
					"a = −15、b = 8", "sin x 的係數在前面。", T_NONSP),
				_f("求 r、cos φ、sin φ", "r = √(a² + b²)。", "r = [0]，cos φ = [1]，sin φ = [2]", ["17", "-15/17", "8/17"],
					"r = 17，cos φ = −15/17，sin φ = 8/17", "15² + 8² = 289。", T_NONSP),
				_c("φ 的象限", "cos φ < 0、sin φ > 0，φ 在第幾象限？", ["第二象限", "第一象限", "第三象限", "第四象限"], 0,
					"cos 負、sin 正：第二象限。", "cos 管左右，sin 管上下。", "φ 在第二象限", T_NONSP),
				_f("最亮的時候", "sin x = cos φ，cos x = sin φ。", "最大值 = [0]，sin x = [1]，cos x = [2]",
					["17", "-15/17", "8/17"], "最大值 17；sin x = −15/17、cos x = 8/17（x 在第四象限）", "代入 cos φ、sin φ 的值。", T_NONSP),
			 ]},
			{"eq": "f(x) = 5 sin x − 12 cos x\n求最大值、最小值，並求最小時的 sin x、cos x",
			 "steps": [
				_f("求 r", "a = 5、b = −12。", "r = [0]", ["13"],
					"r = √(25 + 144) = 13", "5² + 12² = 169。", T_NONSP),
				_f("cos φ、sin φ", "cos φ = a ÷ r，sin φ = b ÷ r。", "cos φ = [0]，sin φ = [1]", ["5/13", "-12/13"],
					"cos φ = 5/13、sin φ = −12/13（φ 在第四象限）", "b 是負的。", T_NONSP),
				_f("最大最小", "最大值 r，最小值 −r。", "最大值 = [0]，最小值 = [1]", ["13", "-13"],
					"M = 13，m = −13", "−r。", T_NONSP),
				_f("最暗的時候", "x + φ = 270°，所以 sin x = −cos φ，cos x = −sin φ。", "sin x = [0]，cos x = [1]",
					["-5/13", "12/13"], "sin x = −5/13、cos x = 12/13", "sin x = −5/13；cos x = −(−12/13)。", T_NONSP),
			 ]},
		 ]},

		{"id": "range", "chapter": 2, "type": "forge", "title": "限制範圍",
		 "story": "x 只能走一小段的時候，光束可能沒機會到頂：最大最小值不一定在最亮最暗的地方，也可能卡在端點。",
		 "insight": "先求 x + φ 的範圍，再看 sin 在這個範圍的圖形：範圍內包含 90° 才有最大值 r，包含 270° 才有最小值 −r，不然就在端點。",
		 "variants": [
			{"eq": "f(x) = √3 sin x + cos x，\n0° ≤ x ≤ 180°，求最大最小值",
			 "steps": [
				_f("先合成", "f(x) = 2 sin(x + 30°)。x 在 0° ～ 180°。", "[0]° ≤ x + 30° ≤ [1]°", ["30", "210"],
					"30° ≤ x + 30° ≤ 210°", "0 + 30、180 + 30。", T_RANGE),
				_peak("找最亮", "拖動 x（只能在 0° ～ 180°），讓光束最亮。", S3, 1.0, "max", [60.0],
					"x = 60° 時最亮", "x + 30° = 90° 在範圍內。", T_RANGE, [0.0, 180.0]),
				_peak("找最暗", "再拖動 x，讓光束最暗。（270° 不在範圍內，最暗卡在端點）", S3, 1.0, "min", [180.0],
					"x = 180° 時最暗", "範圍裡 sin 最小的地方是 210°，也就是 x = 180°。", T_RANGE, [0.0, 180.0]),
				_f("最大最小", "x = 60° 時 2 sin 90°；x = 180° 時 2 sin 210°。", "M = [0]，m = [1]", ["2", "-1"],
					"M = 2，m = 2 × (−1/2) = −1", "sin 210° = −1/2。", T_RANGE),
			 ]},
			{"eq": "f(x) = sin x − √3 cos x，\n0° ≤ x ≤ 90°，求最大最小值",
			 "steps": [
				_f("先合成", "f(x) = 2 sin(x − 60°)。x 在 0° ～ 90°。", "[0]° ≤ x − 60° ≤ [1]°", ["-60", "30"],
					"−60° ≤ x − 60° ≤ 30°", "0 − 60、90 − 60。", T_RANGE),
				_peak("找最亮", "拖動 x（只能在 0° ～ 90°），讓光束最亮。", 1.0, -S3, "max", [90.0],
					"x = 90° 時最亮", "範圍裡 sin 一路往上升，最大在右端點。", T_RANGE, [0.0, 90.0]),
				_peak("找最暗", "再拖動 x，讓光束最暗。", 1.0, -S3, "min", [0.0],
					"x = 0° 時最暗", "最小在左端點。", T_RANGE, [0.0, 90.0]),
				_f("最大最小", "x = 90° 時 2 sin 30°；x = 0° 時 2 sin(−60°)。", "M = [0]，m = [1]", ["1", "-√3"],
					"M = 1，m = −√3", "sin(−60°) = −√3/2。", T_RANGE),
			 ]},
			{"eq": "f(x) = 2 sin x + 2 cos x，\n90° ≤ x ≤ 180°，求最大最小值",
			 "steps": [
				_f("先合成", "f(x) = 2√2 sin(x + 45°)。x 在 90° ～ 180°。", "[0]° ≤ x + 45° ≤ [1]°", ["135", "225"],
					"135° ≤ x + 45° ≤ 225°", "90 + 45、180 + 45。", T_RANGE),
				_peak("找最亮", "拖動 x（只能在 90° ～ 180°），讓光束最亮。", 2.0, 2.0, "max", [90.0],
					"x = 90° 時最亮", "135° ～ 225° 之間 sin 一路往下降，最大在左端點。", T_RANGE, [90.0, 180.0]),
				_peak("找最暗", "再拖動 x，讓光束最暗。", 2.0, 2.0, "min", [180.0],
					"x = 180° 時最暗", "最小在右端點。", T_RANGE, [90.0, 180.0]),
				_f("最大最小", "x = 90°：2√2 sin 135°；x = 180°：2√2 sin 225°。", "M = [0]，m = [1]", ["2", "-2"],
					"M = 2，m = −2", "sin 135° = √2/2，sin 225° = −√2/2。", T_RANGE),
			 ]},
		 ]},

		{"id": "homog", "chapter": 2, "type": "forge", "title": "齊次型",
		 "story": "sin x cos x、cos²x 這些「二次」的式子，用倍角和降冪公式一換，就變成 sin 2x、cos 2x 的疊合。",
		 "insight": "2 sin x cos x = sin 2x；cos²x = \\frac{1 + cos 2x}{2}；sin²x = \\frac{1 − cos 2x}{2}；cos²x − sin²x = cos 2x。換完之後 a sin 2x + b cos 2x 照樣疊合，只是角度是 2x，週期變成 π。",
		 "variants": [
			{"eq": "f(x) = 2√3 sin x cos x + 2cos²x − 1\n化成 r sin(2x + φ)",
			 "steps": [
				_f("倍角", "2 sin x cos x 和 2cos²x − 1 各是誰的倍角？", "2 sin x cos x = sin [0]x，2cos²x − 1 = cos [1]x", ["2", "2"],
					"2 sin x cos x = sin 2x；2cos²x − 1 = cos 2x", "兩個都是 2x。", T_HOMOG),
				_f("改寫", "f(x) = √3 × (2 sin x cos x) + (2cos²x − 1)。", "f(x) = [0] sin 2x + [1] cos 2x", ["√3", "1"],
					"f(x) = √3 sin 2x + cos 2x", "√3 乘 sin 2x，加 cos 2x。", T_HOMOG),
				_f("疊合", "r = √(3 + 1) = 2，cos φ = √3/2，sin φ = 1/2。", "f(x) = [0] sin(2x + [1]°)", ["2", "30"],
					"f(x) = 2 sin(2x + 30°)", "φ = 30°。", T_HOMOG),
				_f("最大最小與週期", "sin 的係數是 2。", "M = [0]，m = [1]，週期 = [2]π", ["2", "-2", "1"],
					"M = 2，m = −2，週期 2π ÷ 2 = π", "週期 2π ÷ 2。", T_HOMOG),
			 ]},
			{"eq": "f(x) = sin²x + √3 sin x cos x\n求最大值與最小值",
			 "steps": [
				_f("降冪、倍角", "sin²x = (1 − cos 2x) ÷ 2；sin x cos x = (sin 2x) ÷ 2。", "sin²x = (1 − cos [0]x) ÷ 2，sin x cos x = (sin [1]x) ÷ 2", ["2", "2"],
					"角度都是 2x", "降冪和倍角都是 2x。", T_HOMOG),
				_f("改寫", "f(x) = (1 − cos 2x) ÷ 2 + (√3 sin 2x) ÷ 2。", "f(x) = 1/2 + [0] sin 2x − [1] cos 2x", ["√3/2", "1/2"],
					"f(x) = 1/2 + (√3/2) sin 2x − (1/2) cos 2x", "各項除以 2。", T_HOMOG),
				_f("疊合", "(√3/2) sin 2x − (1/2) cos 2x 的 r = 1，cos φ = √3/2，sin φ = −1/2。", "f(x) = 1/2 + [0] sin(2x − [1]°)", ["1", "30"],
					"f(x) = 1/2 + sin(2x − 30°)", "φ = −30°。", T_HOMOG),
				_f("最大最小", "sin 的範圍是 −1 ～ 1。", "M = [0]，m = [1]", ["3/2", "-1/2"],
					"M = 1/2 + 1 = 3/2，m = 1/2 − 1 = −1/2", "1/2 ± 1。", T_HOMOG),
			 ]},
			{"eq": "f(x) = cos²x − √3 sin x cos x\n求最大值與最小值",
			 "steps": [
				_f("降冪、倍角", "cos²x = (1 + cos 2x) ÷ 2；sin x cos x = (sin 2x) ÷ 2。", "cos²x = (1 + cos [0]x) ÷ 2，sin x cos x = (sin [1]x) ÷ 2", ["2", "2"],
					"角度都是 2x", "降冪和倍角都是 2x。", T_HOMOG),
				_f("改寫", "f(x) = (1 + cos 2x) ÷ 2 − (√3 sin 2x) ÷ 2。", "f(x) = 1/2 + (1/2) cos 2x − [0] sin 2x", ["√3/2"],
					"f(x) = 1/2 + (1/2) cos 2x − (√3/2) sin 2x", "√3 ÷ 2。", T_HOMOG),
				_f("疊合", "(1/2) cos 2x − (√3/2) sin 2x = cos(2x + 60°)。", "f(x) = 1/2 + [0] cos(2x + [1]°)", ["1", "60"],
					"f(x) = 1/2 + cos(2x + 60°)", "cos 60° = 1/2，sin 60° = √3/2。", T_HOMOG),
				_f("最大最小", "cos 的範圍是 −1 ～ 1。", "M = [0]，m = [1]", ["3/2", "-1/2"],
					"M = 3/2，m = −1/2", "1/2 ± 1。", T_HOMOG),
			 ]},
		 ]},

		{"id": "param", "chapter": 2, "type": "forge", "title": "參數型",
		 "story": "sin x + cos x 和 sin x cos x 常常一起出現。令 k = sin x + cos x，平方一下，另一個就變成 k 的式子——三角函數搖身一變，變成二次函數。",
		 "insight": "令 k = sin x ± cos x，則 −√2 ≤ k ≤ √2（疊合的範圍）。k² = 1 ± 2 sin x cos x = 1 ± sin 2x，所以 sin x cos x 可以用 k 表示。原式變成 k 的二次函數，配方後在 −√2 ≤ k ≤ √2 找最大最小：頂點在範圍內看頂點，不在範圍內看端點。",
		 "variants": [
			{"eq": "f(x) = sin x − cos x + sin 2x\n令 k = sin x − cos x，求最大最小值",
			 "steps": [
				_f("k 的範圍", "k = sin x − cos x = √2 sin(x − 45°)。", "−[0] ≤ k ≤ [1]", ["√2", "√2"],
					"−√2 ≤ k ≤ √2", "疊合的 r = √2。", T_PARAM),
				_f("平方", "k² = sin²x − 2 sin x cos x + cos²x = 1 − sin 2x。", "sin 2x = [0] − k²", ["1"],
					"sin 2x = 1 − k²", "1 − sin 2x = k²。", T_PARAM),
				_f("改寫", "f = k + sin 2x = k + 1 − k²。", "f = −k² + [0]k + [1]", ["1", "1"],
					"f = −k² + k + 1", "k + (1 − k²)。", T_PARAM),
				_f("頂點", "開口向下，頂點 k = −b ÷ 2a 在範圍內嗎？（√2 ≈ 1.41）", "頂點 k = [0]，最大值 M = [1]", ["1/2", "5/4"],
					"頂點 k = 1/2（在範圍內），M = −1/4 + 1/2 + 1 = 5/4", "−1 ÷ (2 × (−1)) = 1/2。", T_PARAM),
				_f("最小值", "最小值在離頂點最遠的端點 k = −√2：f = −2 − √2 + 1。", "m = −[0] − [1]", ["1", "√2"],
					"m = −1 − √2", "−(√2)² = −2。", T_PARAM),
			 ]},
			{"eq": "f(x) = 2 sin x cos x − 3(sin x + cos x)\n令 k = sin x + cos x，求最大最小值",
			 "steps": [
				_f("k 的範圍", "k = sin x + cos x = √2 sin(x + 45°)。", "−[0] ≤ k ≤ [1]", ["√2", "√2"],
					"−√2 ≤ k ≤ √2", "疊合的 r = √2。", T_PARAM),
				_f("平方", "k² = 1 + 2 sin x cos x。", "2 sin x cos x = k² − [0]", ["1"],
					"2 sin x cos x = k² − 1", "k² = 1 + 2 sin x cos x。", T_PARAM),
				_f("改寫", "f = (k² − 1) − 3k。", "f = k² − [0]k − [1]", ["3", "1"],
					"f = k² − 3k − 1", "−3k 的係數是 −3。", T_PARAM),
				_c("頂點的位置", "開口向上，頂點 k = 3/2 ≈ 1.5，範圍 −1.41 ≤ k ≤ 1.41。頂點在哪裡？",
					["在範圍右邊（範圍外）", "在範圍裡面", "在範圍左邊（範圍外）"], 0,
					"3/2 比 √2 大：頂點在範圍右邊，範圍內函數一路往下降。", "比較 1.5 和 1.41。", "頂點在範圍外：最大最小在端點", T_PARAM),
				_f("最大最小", "範圍內函數遞減：最大在 k = −√2，最小在 k = √2。", "M = [0] + [1]√2，m = [2] − [3]√2", ["1", "3", "1", "3"],
					"M = 2 + 3√2 − 1 = 1 + 3√2；m = 2 − 3√2 − 1 = 1 − 3√2", "k = −√2：k² = 2，−3k = 3√2。", T_PARAM),
			 ]},
		 ]},

		{"id": "combo", "chapter": 2, "type": "forge", "title": "兩道光再疊",
		 "story": "sin x 加上一道已經平移過的光，例如 cos(x + 60°)：先把平移過的那道展開，再整個疊合。",
		 "insight": "遇到 sin(x + α) 或 cos(x + α) 的和：先用和角公式展開成 sin x、cos x，合併同類項，再 a sin x + b cos x = r sin(x + φ)。",
		 "variants": [
			{"eq": "f(x) = √3 sin x + cos(x + 60°)\n求最大值、最小值",
			 "steps": [
				_f("展開", "cos(x + 60°) = cos x cos 60° − sin x sin 60°。", "cos(x + 60°) = [0] cos x − [1] sin x", ["1/2", "√3/2"],
					"cos(x + 60°) = (1/2) cos x − (√3/2) sin x", "cos 60° = 1/2，sin 60° = √3/2。", T_COMBO),
				_f("合併", "f = √3 sin x + (1/2) cos x − (√3/2) sin x。", "f(x) = [0] sin x + [1] cos x", ["√3/2", "1/2"],
					"f(x) = (√3/2) sin x + (1/2) cos x", "√3 − √3/2 = √3/2。", T_COMBO),
				_f("疊合", "r = √(3/4 + 1/4) = 1，cos φ = √3/2，sin φ = 1/2。", "f(x) = [0] sin(x + [1]°)", ["1", "30"],
					"f(x) = sin(x + 30°)", "r = 1，φ = 30°。", T_COMBO),
				_peak("找最亮", "拖動 x，讓光束最亮。", S3 / 2.0, 0.5, "max", [60.0],
					"x = 60° 時最亮，M = 1", "x + 30° = 90°。", T_COMBO),
			 ]},
			{"eq": "f(x) = 2 sin x + 2 sin(x − 60°)\n求最大值、最小值",
			 "steps": [
				_f("展開", "2 sin(x − 60°) = 2 sin x cos 60° − 2 cos x sin 60°。", "2 sin(x − 60°) = [0] sin x − [1] cos x", ["1", "√3"],
					"2 sin(x − 60°) = sin x − √3 cos x", "2 × 1/2 = 1；2 × √3/2 = √3。", T_COMBO),
				_f("合併", "f = 2 sin x + sin x − √3 cos x。", "f(x) = [0] sin x − [1] cos x", ["3", "√3"],
					"f(x) = 3 sin x − √3 cos x", "2 + 1 = 3。", T_COMBO),
				_phasor("相位指針", "拖動 r 與 φ，讓箭頭壓在目標點 (3, −√3) 上。", 3.0, -S3, "3", "−√3", "3 sin x − √3 cos x", 4.5,
					"r = 2√3、φ = −30°", "r = √(9 + 3) = √12。", T_COMBO),
				_f("最大最小", "f(x) = 2√3 sin(x − 30°)。", "M = [0]，m = [1]", ["2√3", "-2√3"],
					"M = 2√3，m = −2√3", "最大值 r，最小值 −r。", T_COMBO),
			 ]},
			{"eq": "f(x) = 2 sin x + 2 cos(x − 30°)\n求最大值",
			 "steps": [
				_f("展開", "2 cos(x − 30°) = 2 cos x cos 30° + 2 sin x sin 30°。", "2 cos(x − 30°) = [0] cos x + [1] sin x", ["√3", "1"],
					"2 cos(x − 30°) = √3 cos x + sin x", "2 × √3/2 = √3；2 × 1/2 = 1。", T_COMBO),
				_f("合併", "f = 2 sin x + √3 cos x + sin x。", "f(x) = [0] sin x + [1] cos x", ["3", "√3"],
					"f(x) = 3 sin x + √3 cos x", "2 + 1 = 3。", T_COMBO),
				_phasor("相位指針", "拖動 r 與 φ，讓箭頭壓在目標點 (3, √3) 上。", 3.0, S3, "3", "√3", "3 sin x + √3 cos x", 4.5,
					"r = 2√3、φ = 30°", "r = √(9 + 3) = √12。", T_COMBO),
				_f("最大值", "f(x) = 2√3 sin(x + 30°)。", "M = [0]", ["2√3"],
					"M = 2√3", "最大值就是 r。", T_COMBO),
			 ]},
		 ]},

		{"id": "apply", "chapter": 2, "type": "forge", "title": "燈塔的應用",
		 "story": "周長、長度的最大值：先用角度把長和寬寫出來，再合成一道光。",
		 "insight": "應用題的做法：① 設一個角 θ，用 sin θ、cos θ 表示長度 ② 得到 a sin θ + b cos θ ③ 疊合 r sin(θ + φ)，最大值 r（記得檢查 θ 的範圍能不能取到）。",
		 "variants": [
			{"eq": "半徑 30 公尺的圓形池塘，\n內接一個長方形的木框，求周長最大值",
			 "steps": [
				_f("長與寬", "對角線是直徑 60，與長邊夾角 θ（0° < θ < 90°）。", "長 = [0] cos θ，寬 = [1] sin θ", ["60", "60"],
					"長 = 60 cos θ，寬 = 60 sin θ", "直角三角形：斜邊 60。", T_APPLY),
				_f("周長", "周長 L = 2 × (長 + 寬)。", "L = [0] sin θ + [1] cos θ", ["120", "120"],
					"L = 120 sin θ + 120 cos θ", "2 × 60 = 120。", T_APPLY),
				_f("疊合", "r = √(120² + 120²) = 120√2，φ = 45°。", "L = [0]√2 sin(θ + [1]°)", ["120", "45"],
					"L = 120√2 sin(θ + 45°)", "a = b：φ = 45°。", T_APPLY),
				_c("取得到嗎", "最大值發生在 θ + 45° = 90°，也就是 θ = 45°。0° < θ < 90°，取得到嗎？",
					["取得到，θ = 45°（正方形）", "取不到", "只能取端點"], 0,
					"45° 在範圍內：最大周長 120√2，此時長方形是正方形。", "45° 在 0° 和 90° 中間。", "θ = 45° 在範圍內", T_APPLY),
				_f("答案", "最大值就是 r。", "最大周長 = [0]√2 公尺", ["120"],
					"最大周長 120√2 公尺", "r = 120√2。", T_APPLY),
			 ]},
			{"eq": "半徑 25 公尺的半圓形花圃，\n內接長方形（一邊在直徑上），求周長最大值",
			 "steps": [
				_f("長與寬", "圓心到頂點的線與直徑夾角 θ：底的一半 25 cos θ，高 25 sin θ。", "底 = [0] cos θ，高 = [1] sin θ", ["50", "25"],
					"底 = 50 cos θ，高 = 25 sin θ", "底是一半的兩倍。", T_APPLY),
				_f("周長", "周長 P = 2 × (底 + 高)。", "P = [0] cos θ + [1] sin θ", ["100", "50"],
					"P = 100 cos θ + 50 sin θ", "2 × 50、2 × 25。", T_APPLY),
				_f("最大周長", "P = 50 × (2 cos θ + sin θ)，r = √(2² + 1²)。", "最大周長 = [0]√5", ["50"],
					"最大周長 = 50√5 公尺", "a² + b² = 100² + 50² = 12500 = 2500 × 5。", T_APPLY),
				_f("取最大時", "最大時 (cos θ, sin θ) 和 (2, 1) 同方向，除以 √5。", "cos θ = [0]", ["2√5/5"],
					"cos θ = 2/√5 = 2√5/5", "2 ÷ √5。", T_APPLY),
			 ]},
		 ]},

		{"id": "judge", "chapter": 2, "type": "forge", "title": "真假判斷",
		 "story": "段考最愛的「下列何者為真」：疊合的選項，一個一個合成、代入檢查。",
		 "insight": "r = √(a² + b²) 不是 a + b。sin 和 cos 的位置別弄反：cos φ = a/r，sin φ = b/r。最大值和最大值發生的位置是兩件事。",
		 "variants": [
			{"eq": "f(x) = √3 sin x − cos x，\n下列的敘述對還是錯？",
			 "steps": [
				_tf("(A) 合成", "(A) f(x) = 2 sin(x − 30°)", true, "r = 2，cos φ = √3/2，sin φ = −1/2，φ = −30°。", "(A) 對：f(x) = 2 sin(x − 30°)"),
				_tf("(B) 餘弦", "(B) f(x) = 2 cos(x − 120°)", true, "2 sin(x − 30°) = 2 cos(x − 30° − 90°) = 2 cos(x − 120°)。", "(B) 對：sin 比 cos 慢 90°"),
				_tf("(C) 最大值", "(C) f(x) 的最大值是 √3 + 1", false, "最大值是 r = 2，不是 a + b。", "(C) 錯：最大值 2"),
				_tf("(D) 週期", "(D) f(x) 的週期是 2π", true, "x 的係數是 1。", "(D) 對：週期 2π"),
				_tf("(E) 位置", "(E) 當 x = 30° 時，f(x) 有最大值", false, "f(30°) = 2 sin 0° = 0；最大值在 x = 120°。", "(E) 錯：最大值在 x = 120°"),
			 ]},
			{"eq": "關於 a sin x + b cos x，\n下列的敘述對還是錯？",
			 "steps": [
				_tf("(A) 最大值", "(A) a sin x + b cos x 的最大值是 a + b", false, "最大值是 √(a² + b²)。例如 sin x + cos x 最大是 √2，不是 2。", "(A) 錯：最大值 √(a² + b²)"),
				_tf("(B) 最大值", "(B) a sin x + b cos x 的最大值是 √(a² + b²)", true, "疊合成 r sin(x + φ)，最大值 r。", "(B) 對：最大值 r"),
				_tf("(C) cos φ", "(C) 3 sin x + 4 cos x = 5 sin(x + φ)，其中 cos φ = 3/5", true, "cos φ = a/r = 3/5，sin φ = 4/5。", "(C) 對：cos φ = a/r"),
				_tf("(D) 大小", "(D) sin x + cos x 的最大值是 2", false, "= √2 sin(x + 45°)，最大值 √2。", "(D) 錯：最大值 √2"),
				_tf("(E) 餘弦型", "(E) a sin x + b cos x 也可以寫成 r cos(x − θ)，r = √(a² + b²)", true, "例如 sin x = cos(x − 90°)，r 不變、角度不一樣。", "(E) 對：sin 與 cos 差 90°"),
			 ]},
		 ]},

		{"id": "boss2", "chapter": 2, "type": "forge", "title": "大師試煉", "time": 300.0,
		 "story": "限時 300 秒！限制範圍、倍角齊次、疊合……燈塔最後的光，交給你了。",
		 "insight": "疊合的流程：整理成 a sin x + b cos x（齊次型先用倍角降冪）→ r = √(a² + b²)、找 φ → r sin(x + φ) → 看 x + φ 的範圍，決定最大最小值。",
		 "variants": [
			{"eq": "f(x) = 3√3 sin x − 3 cos x，\n0° ≤ x ≤ 180°，求最大最小值",
			 "steps": [
				_phasor("相位指針", "拖動 r 與 φ，讓箭頭壓在目標點 (3√3, −3) 上。", 3.0 * S3, -3.0, "3√3", "−3", "3√3 sin x − 3 cos x", 6.5,
					"r = 6、φ = −30°", "r = √(27 + 9) = 6。", T_FORM),
				_f("合成", "cos φ = √3/2，sin φ = −1/2。", "f(x) = [0] sin(x − [1]°)", ["6", "30"],
					"f(x) = 6 sin(x − 30°)", "φ = −30°。", T_FORM),
				_peak("找最亮", "拖動 x（0° ～ 180°），讓光束最亮。", 3.0 * S3, -3.0, "max", [120.0],
					"x = 120° 時最亮", "x − 30° = 90°。", T_RANGE, [0.0, 180.0]),
				_peak("找最暗", "再拖動 x，讓光束最暗。（最暗卡在端點）", 3.0 * S3, -3.0, "min", [0.0],
					"x = 0° 時最暗", "x − 30° 的範圍是 −30° ～ 150°，最小在 −30°。", T_RANGE, [0.0, 180.0]),
				_f("最大最小", "x = 120°：6 sin 90°；x = 0°：6 sin(−30°)。", "M = [0]，m = [1]", ["6", "-3"],
					"M = 6，m = −3", "sin(−30°) = −1/2。", T_RANGE),
			 ]},
			{"eq": "f(x) = cos²x + √3 sin x cos x\n求最大值，以及最大值發生的 x",
			 "steps": [
				_f("降冪、倍角", "cos²x = (1 + cos 2x) ÷ 2；sin x cos x = (sin 2x) ÷ 2。", "f(x) = 1/2 + [0] cos 2x + [1] sin 2x", ["1/2", "√3/2"],
					"f(x) = 1/2 + (1/2) cos 2x + (√3/2) sin 2x", "√3 × (1/2) = √3/2。", T_HOMOG),
				_f("疊合", "(√3/2) sin 2x + (1/2) cos 2x 的 r = 1，φ = 30°。", "f(x) = 1/2 + [0] sin(2x + [1]°)", ["1", "30"],
					"f(x) = 1/2 + sin(2x + 30°)", "cos φ = √3/2，sin φ = 1/2。", T_HOMOG),
				_f("最大最小", "sin 的範圍是 −1 ～ 1。", "M = [0]，m = [1]", ["3/2", "-1/2"],
					"M = 3/2，m = −1/2", "1/2 ± 1。", T_HOMOG),
				_f("發生的位置", "最大時 2x + 30° = 90°（0° ≤ x < 180° 的第一個）。", "x = [0]°", ["30"],
					"2x + 30° = 90°，x = 30°", "2x = 60°。", T_HOMOG),
			 ]},
		 ]},
	]


## SB.filter 加上 "var"：按鈕上寫「f = …」
static func _filter(name: String, q: String, cands: Array, keep: Array, line: String, nudge: String) -> Dictionary:
	var st := SB.filter(name, q, cands, keep, line, nudge, T_BRIGHT)
	st["var"] = "f"
	return st
