extends RefCounted
## 第五大關「鏡像之塔」題庫（對應講義 重點二：對數函數之圖形與性質）
##
## 結構與第一大關相同（見 level01_bank.gd 的說明），另外多了這些欄位：
##   form       log           y = log_{a}(x − h) + k
##              log_abs_in    y = log_{a}|x − h| + k
##              log_abs_out   y = |log_{a}(x − h) + k|
##              log_abs_both  y = |log_{a}|x − h| + k|
##   mirror     true：畫出鏡子 y = x
##   square     true：x、y 同比例（鏡子才會是 45°），view.x 只取中心
##   ghost      true／"inverse"：同時畫出目前曲線對 y = x 的鏡像（反函數）；
##              "x_axis"：畫出對 x 軸的倒影（對數時就是 log_{1/a} x）。都會跟著滑桿一起動
##   source     鏡像配對：原曲線 {form, a, h, k}；寶石是它對 y = x 的鏡像
##   rank_form  "log"：底數辨識改看對數曲線，參考線是 y = 1
##   exp / quad 交點題的兩邊：字典 {form, a, h, k} 是一條曲線、陣列 [p, q, r] 是 px² + qx + r
##   draw       徒手作圖（見 level01_bank.gd）：keys 是一定要經過的點
##   domain     交點題的掃描範圍（預設 −6 ～ 6）；need：沒有交點時要掃過的範圍
##
## 新增題目：在對應 slot 的 variants 裡加一筆即可；fit 題請用 test_bank 檢查答案唯一。

const TAG_CROSS := "log_exp_cross"

## 對數的底數滑桿只在這些「好算」的值之間跳（底數差一點點時，對數曲線幾乎看不出差別）
const BASES := {"a": [0.2, 0.25, 1.0 / 3.0, 0.5, 1.5, 2.0, 3.0, 4.0, 5.0]}

const DIR_UP := {"q": "寶石從左下排到右上。y = log_{a} x 的底數應該？",
	"options": ["a > 1", "0 < a < 1"], "correct": 0, "keep_order": true,
	"why": "往右上升 → 遞增 → a > 1。",
	"nudge": "往右走，寶石越來越高還是越來越低？", "tag": "log_monotonic"}

const DIR_DOWN := {"q": "寶石從左上排到右下。y = log_{a} x 的底數應該？",
	"options": ["a > 1", "0 < a < 1"], "correct": 1, "keep_order": true,
	"why": "往右下降 → 遞減 → 0 < a < 1。",
	"nudge": "往右走，寶石越來越高還是越來越低？", "tag": "log_monotonic"}

const Q_FIXED := {"q": "不論 a 是多少，y = log_{a} x 一定通過哪一點？",
	"options": ["(1, 0)", "(0, 1)", "(a, 0)", "(0, a)"], "correct": 0,
	"why": "log_{a} 1 = 0，一定過 (1, 0)：(0, 1) 對 y = x 的倒影。",
	"nudge": "a 的幾次方會等於 1？", "tag": "log_fixed_point"}

const Q_INVERSE_PT := {"q": "兩圖形對稱於 y = x。若點 (p, q) 在原曲線上，哪一點一定在它的鏡像上？",
	"options": ["(q, p)", "(−p, q)", "(p, −q)", "(−q, −p)"], "correct": 0,
	"why": "對 y = x 翻轉 = 坐標交換：(p, q) → (q, p)。",
	"nudge": "鏡子是 y = x：點 (0, 1) 翻過去會到哪裡？", "tag": "inverse_symmetry"}


## 凹口比大小：先判斷凹口方向（up = true 表示凹口向上）
static func conc_q(eq: String, up: bool, why: String) -> Dictionary:
	return {"q": eq + " 的圖形，凹口朝哪個方向？", "options": ["凹口向上（像碗）", "凹口向下（像蓋子）"],
		"correct": 0 if up else 1, "keep_order": true, "why": why,
		"nudge": "往右走越陡還是越平？曲線往上彎還是往下彎？", "tag": "concavity"}


## 凹口比大小：最後比較「函數值的平均」和「中點代入的函數值」；ans 是 "＞"、"＜" 或 "＝"
static func conc_final(q: String, ans: String, why: String, cond := "") -> Dictionary:
	return {"q": "比比看，[color=#ff7eb6]？[/color] 要填哪個符號？\n" + (cond + "\n" if cond != "" else "") + q, "options": ["＞", "＜", "＝"], "correct": ["＞", "＜", "＝"].find(ans), "keep_order": true, "cols": 4,
		"why": why, "nudge": "M 是函數值的平均、N 是中點的函數值。誰比較高？", "tag": "concavity"}


const B1 := preload("level01_bank.gd")


## 用這一題的寶石反推對數的底數
static func _logbase_pred(x: float, a_txt: String, opts: Array, why: String) -> Dictionary:
	return {"q": "寶石 (%s, −1) 在 y = log_{a} x 上：log_{a} %s = −1，所以 a = ？" % [B1._sn(x), B1._sn(x)],
		"options": [a_txt] + opts, "correct": 0, "why": why,
		"nudge": "改寫成指數式：a^{−1} = %s。" % B1._sn(x), "tag": "log_def"}


static func _tag(q: Dictionary) -> Dictionary:
	q["tag"] = "log_abs"
	return q


static func slots() -> Array:
	return [
		# ======================= 第一章．鏡中之光 =======================
		{"id": "gate", "choices": BASES, "chapter": 1, "type": "fit", "title": "鏡像之門", "form": "log",
		 "params": ["a"], "live": true, "mirror": true, "ghost": true, "square": true,
		 "view": {"x": Vector2(-3, 6), "y": Vector2(-2.5, 4.5)},
		 "story": "調整 a，讓對數光橋穿過寶石；看鏡中的指數分身怎麼動。",
		 "predicts": [Q_FIXED,
			{"q": "y = log_{a} x 的定義域是？",
			 "options": ["x > 0", "x ≥ 0", "全體實數", "x > 1"], "correct": 0,
			 "why": "真數 > 0：圖形在 y 軸右邊，y 軸是漸近線。",
			 "nudge": "log 裡面的數（真數）可以是 0 或負數嗎？", "tag": "log_domain"}],
		 "insight": "log_{a} x 與 a^{x} 對稱於 y = x：(1, a) ↔ (a, 1)，所以 y = 1 時 x = a。",
		 "variants": [
			{"answer": {"a": 2.0}, "xs": [0.5, 1, 2, 4]},
			{"answer": {"a": 3.0}, "xs": [1.0 / 3.0, 1, 3]},
			{"answer": {"a": 4.0}, "xs": [0.25, 1, 4]},
		 ]},

		{"id": "fall", "choices": BASES, "chapter": 1, "type": "fit", "title": "倒影迴廊", "form": "log",
		 "params": ["a"], "live": true, "ghost": "x_axis",
		 "view": {"x": Vector2(-1, 6), "y": Vector2(-3.0, 3.0)},
		 "story": "寶石從左上到右下，鏡子是 x 軸。底數比 1 大還是小？",
		 "predicts": [DIR_DOWN],
		 "insight": "log_{1/a} x = −log_{a} x：兩者對稱於 x 軸。",
		 "variants": [
			{"answer": {"a": 0.5}, "xs": [0.5, 1, 2, 4], "predicts": [DIR_DOWN, _logbase_pred(2, "1/2", ["2", "−2", "−1/2"],
				"log_{a} 2 = −1 ⇔ a^{−1} = 2 ⇔ 1/a = 2 ⇒ a = 1/2。")]},
			{"answer": {"a": 0.25}, "xs": [0.25, 1, 4], "predicts": [DIR_DOWN, _logbase_pred(4, "1/4", ["4", "−4", "1/2"],
				"log_{a} 4 = −1 ⇔ a^{−1} = 4 ⇒ a = 1/4。")]},
			{"answer": {"a": 0.2}, "xs": [0.2, 1, 5], "predicts": [DIR_DOWN, _logbase_pred(5, "1/5", ["5", "−5", "1/25"],
				"log_{a} 5 = −1 ⇔ a^{−1} = 5 ⇒ a = 1/5。")]},
		 ]},

		{"id": "rank", "chapter": 1, "type": "rank", "title": "底數辨識", "rank_form": "log",
		 "params": [], "live": true, "view": {"x": Vector2(-0.6, 6.4), "y": Vector2(-3.0, 3.0)},
		 "story": "用 y = 1 這條線，幫每條曲線找回底數。",
		 "rank_fail": "看 y = 1：曲線交在 x = a，越右邊底數越大。",
		 "predicts": [
			{"q": "在直線 y = 1 上，y = log_{a} x 通過哪一點？",
			 "options": ["(a, 1)", "(1, a)", "(1, 0)", "(0, 1)"], "correct": 0,
			 "why": "log_{a} a = 1：交 y = 1 於 x = a，越右邊底數越大。",
			 "nudge": "log_{a} 多少會等於 1？", "tag": "log_base_compare"},
			{"q": "x > 1 時，y = log_{2} x 和 y = log_{3} x 誰比較高？",
			 "options": ["log_{2} x", "log_{3} x", "一樣高", "不一定"], "correct": 0,
			 "why": "a > 1 時底數越大越平：x > 1 時 log_{2} x 較高。",
			 "nudge": "代 x = 9 試試：log_{3} 9 = 2，log_{2} 9 呢？", "tag": "log_base_compare"},
			{"q": "y = log_{6} x 是把 y = log_{4} x 鉛直伸縮幾倍？",
			 "options": ["log 4 ÷ log 6 ≈ 0.77", "6 ÷ 4 = 1.5", "log 6 ÷ log 4 ≈ 1.29", "4 ÷ 6 ≈ 0.67"], "correct": 0,
			 "why": "換底：log_{6} x ≈ 0.77·log_{4} x，曲線被壓扁。",
			 "nudge": "用換底公式把兩個都寫成 log x ÷ log(底數)。", "tag": "log_base_compare"}],
		 "insight": "看 y = 1 交在 x = a；a > 1 底數越大越平，a < 1 在 x > 1 時為負。",
		 "variants": [
			{"bases": [2.0, 3.0, 0.5]},
			{"bases": [1.5, 2.0, 4.0]},
			{"bases": [2.0, 3.0, 5.0, 0.5]},
			{"bases": [1.5, 3.0, 0.25]},
		 ]},

		{"id": "shift", "chapter": 1, "type": "fit", "title": "平移之階", "form": "log",
		 "params": ["h", "k"], "live": false, "fixed": {"a": 2.0},
		 "view": {"x": Vector2(-3.0, 7.0), "y": Vector2(-3.0, 4.5)},
		 "story": "霧中模式：對數的雷射牆（漸近線）是鉛直線。",
		 "predicts": [
			{"q": "y = log_{2}(x − h) + k 的漸近線是？",
			 "options": ["x = h", "y = k", "x = k", "y = h"], "correct": 0,
			 "why": "真數 x − h > 0：圖形貼著 x = h。",
			 "nudge": "log 裡面的 x − h 什麼時候會變成 0？", "tag": "log_asymptote"},
			{"q": "y = log_{2}(x − h) + k 一定通過哪一點？",
			 "options": ["(1 + h, k)", "(h, 1 + k)", "(1, 0)", "(h, k)"], "correct": 0,
			 "why": "x − h = 1 時 log 為 0：過 (1 + h, k)。",
			 "nudge": "x − h 等於多少時，log_{2}(x − h) = 0？", "tag": "log_fixed_point"}],
		 "insight": "log_{a}(x − h) + k：漸近線 x = h，過 (1 + h, k)。",
		 "variants": [
			{"answer": {"h": 1.0, "k": 1.0}, "xs": [1.5, 2, 3, 5]},
			{"answer": {"h": -1.0, "k": 0.0}, "xs": [-0.5, 0, 1, 3]},
			{"answer": {"h": 2.0, "k": -1.0}, "xs": [2.5, 3, 4, 6]},
			{"answer": {"h": -2.0, "k": 1.0}, "xs": [-1.5, -1, 0, 2]},
		 ]},

		{"id": "sketch", "chapter": 1, "type": "draw", "title": "徒手作圖", "form": "log",
		 "params": [], "tag": "draw_graph", "view": {"x": Vector2(-2.0, 7.0), "y": Vector2(-3.0, 3.5)},
		 "story": "沒有滑桿！直接把圖形畫出來（可以分好幾筆）。",
		 "insight": "畫法：漸近線 x = h → 點 (1 + h, k)、(a + h, 1 + k) → 一邊貼漸近線、一邊變平。",
		 "variants": [
			{"answer": {"a": 2.0, "h": 0.0, "k": 0.0}, "keys": [Vector2(0.5, -1), Vector2(1, 0), Vector2(2, 1), Vector2(4, 2)]},
			{"answer": {"a": 2.0, "h": 1.0, "k": 0.0}, "keys": [Vector2(2, 0), Vector2(3, 1), Vector2(5, 2)]},
			{"answer": {"a": 0.5, "h": 0.0, "k": 1.0}, "keys": [Vector2(0.5, 2), Vector2(1, 1), Vector2(2, 0), Vector2(4, -1)]},
			{"answer": {"a": 3.0, "h": -1.0, "k": 0.0}, "keys": [Vector2(0, 0), Vector2(2, 1)]},
		 ]},

		{"id": "absorb", "chapter": 1, "type": "fit", "title": "真數拆解", "form": "log",
		 "params": ["h", "k"], "live": false,
		 "diagnose": {"tag": "log_shift_coef",
			"text": "提出係數再拆：log_{2}(4x − 12) = log_{2}(x − 3) + 2。"},
		 "insight": "真數乘 c = 上下平移 log_{a} c：log_{2}(4x) = log_{2} x + 2。",
		 "variants": [
			{"answer": {"a": 2.0, "h": 3.0, "k": 2.0}, "xs": [3.5, 4, 5, 7],
			 "view": {"x": Vector2(-1.0, 8.0), "y": Vector2(-2.0, 5.5)},
			 "story": "寶石在 y = log_{2}(4x − 12) 上，只用 h、k 調出來。",
			 "predicts": [{"q": "log_{2}(4x − 12) 可以改寫成？",
				"options": ["log_{2}(x − 3) + 2", "log_{2}(x − 12) + 4", "4·log_{2}(x − 3)", "log_{2}(x − 3) + 4"], "correct": 0,
				"why": "log_{2} 4(x − 3) = log_{2}(x − 3) + 2：右移 3、上移 2。",
				"nudge": "4x − 12 = 4(x − ?)，再用 log(MN) = log M + log N。", "tag": "log_shift_coef"}]},
			{"answer": {"a": 2.0, "h": -1.0, "k": 1.0}, "xs": [-0.5, 0, 1, 3],
			 "view": {"x": Vector2(-3.0, 6.0), "y": Vector2(-2.0, 4.5)},
			 "story": "寶石在 y = log_{2}(2x + 2) 上，只用 h、k 調出來。",
			 "predicts": [{"q": "log_{2}(2x + 2) 可以改寫成？",
				"options": ["log_{2}(x + 1) + 1", "log_{2}(x + 2) + 1", "2·log_{2}(x + 1)", "log_{2}(x + 1) + 2"], "correct": 0,
				"why": "log_{2} 2(x + 1) = 1 + log_{2}(x + 1)：左移 1、上移 1。",
				"nudge": "先把 2 提出來：2x + 2 = 2(x + ?)。log_{2} 2 = ?", "tag": "log_shift_coef"}]},
			{"answer": {"a": 2.0, "h": 2.0, "k": -2.0}, "xs": [2.5, 3, 4, 6],
			 "view": {"x": Vector2(-1.0, 8.0), "y": Vector2(-4.0, 2.5)},
			 "story": "寶石在 y = log_{2}((x − 2)/4) 上，只用 h、k 調出來。",
			 "predicts": [{"q": "log_{2}((x − 2)/4) 可以改寫成？",
				"options": ["log_{2}(x − 2) − 2", "log_{2}(x − 2) + 2", "log_{2}(x − 2) − 4", "(1/4)·log_{2}(x − 2)"], "correct": 0,
				"why": "= log_{2}(x − 2) − 2：右移 2、下移 2。",
				"nudge": "除法變減法：log(M/N) = log M − log N。log_{2} 4 = ?", "tag": "log_shift_coef"}]},
		 ]},

		{"id": "inverse", "chapter": 1, "type": "fit", "title": "鏡像配對",
		 "params": ["h", "k"], "live": false, "mirror": true, "square": true, "holes": [],
		 "predicts": [Q_INVERSE_PT,
			{"q": "y = a^{x} + k 對 y = x 的鏡像（反函數）是？",
			 "options": ["y = log_{a}(x − k)", "y = log_{a} x − k", "y = log_{a}(x + k)", "y = −log_{a} x + k"], "correct": 0,
			 "why": "x、y 交換：x = a^{y} + k ⇒ y = log_{a}(x − k)。",
			 "nudge": "反函數：先把 x 和 y 交換，再解出 y。", "tag": "inverse_symmetry"}],
		 "diagnose": {"tag": "inverse_symmetry",
			"text": "原曲線的點 (p, q) 換成 (q, p) 就是寶石；y = k 翻成 x = k。"},
		 "insight": "a^{x − h} + k 的鏡像是 log_{a}(x − k) + h。",
		 "variants": [
			{"form": "log", "answer": {"a": 2.0, "h": -2.0, "k": 0.0}, "xs": [-1, 0, 2],
			 "source": {"form": "exp", "a": 2.0, "h": 0.0, "k": -2.0},
			 "view": {"x": Vector2(0.5, 0.5), "y": Vector2(-3.0, 4.0)},
			 "story": "調 h、k，讓 log_{2}(x − h) + k 成為 y = 2^{x} − 2 的鏡像。"},
			{"form": "log", "answer": {"a": 2.0, "h": 1.0, "k": 1.0}, "xs": [1.5, 2, 3],
			 "source": {"form": "exp", "a": 2.0, "h": 1.0, "k": 1.0},
			 "view": {"x": Vector2(1.5, 1.5), "y": Vector2(-2.0, 5.0)},
			 "story": "調 h、k，讓 log_{2}(x − h) + k 成為 y = 2^{x − 1} + 1 的鏡像。"},
			{"form": "exp", "answer": {"a": 2.0, "h": 2.0, "k": 3.0}, "xs": [0, 1, 2, 3],
			 "source": {"form": "log", "a": 2.0, "h": 3.0, "k": 2.0},
			 "view": {"x": Vector2(3.0, 3.0), "y": Vector2(-1.5, 6.5)},
			 "story": "原曲線 y = log_{2}(x − 3) + 2，調出它的鏡像 y = 2^{x − h} + k。"},
		 ]},

		{"id": "concave", "chapter": 1, "type": "chord", "title": "凹口天秤", "form": "log", "params": [], "tag": "concavity",
		 "story": "把 P、Q 連成弦：弦的中點和曲線，誰比較高？",
		 "insight": "a > 1 時[color=#ffcf5a]凹口向下[/color]：平均 ＜ 中點代入；0 < a < 1 相反。",
		 "variants": [
			{"answer": {"a": 2.0}, "eq": "y = log_{2} x", "chord": {"x1": 1.0, "x2": 4.0},
			 "view": {"x": Vector2(-0.8, 5.5), "y": Vector2(-2.6, 3.2)},
			 "predicts": [conc_q("y = log_{2} x", false, "往右越來越平，曲線往下彎 ⇒ 凹口向下。（它是凹口向上的 y = 2^{x} 對 y = x 的鏡像）")],
			 "final": conc_final("(log_{2} 1 + log_{2} 4) / 2 [color=#ff7eb6]？[/color] log_{2} 2.5", "＜",
				"左邊 = (0 + 2)/2 = 1 = log_{2} 2，而 2.5 > 2，所以右邊比較大。凹口向下 ⇒ 弦在曲線下方。")},
			{"answer": {"a": 0.5}, "eq": "y = log_{1/2} x", "chord": {"x1": 1.0, "x2": 4.0},
			 "view": {"x": Vector2(-0.8, 5.5), "y": Vector2(-3.2, 2.6)},
			 "predicts": [conc_q("y = log_{1/2} x", true, "它是 y = log_{2} x 對 x 軸翻過來，凹口也跟著翻成向上。")],
			 "final": conc_final("[log_{1/2} 1 + log_{1/2} 4] / 2 [color=#ff7eb6]？[/color] log_{1/2} 2.5", "＞",
				"左邊 = (0 − 2)/2 = −1 = log_{1/2} 2；log_{1/2} 是遞減，2.5 > 2，所以右邊更小。凹口向上 ⇒ 弦在曲線上方。")},
			{"answer": {"a": 3.0}, "eq": "y = log_{3} x", "chord": {"x1": 1.0, "x2": 9.0},
			 "view": {"x": Vector2(-1.0, 10.5), "y": Vector2(-2.2, 3.0)},
			 "predicts": [conc_q("y = log_{3} x", false, "底數大於 1 的對數，往右越來越平 ⇒ 凹口向下。")],
			 "final": conc_final("(log_{3} 1 + log_{3} 9) / 2 [color=#ff7eb6]？[/color] log_{3} 5", "＜",
				"左邊 = (0 + 2)/2 = 1 = log_{3} 3，而 5 > 3，所以右邊比較大。")},
			{"answer": {"a": 10.0}, "eq": "y = log x", "chord": {"x1": 1.0, "x2": 9.0},
			 "view": {"x": Vector2(-0.8, 10.5), "y": Vector2(-0.9, 1.35)},
			 "predicts": [conc_q("y = log x", false, "常用對數的底數是 10 > 1 ⇒ 凹口向下。")],
			 "final": conc_final("(log x_{1} + log x_{2}) / 2 [color=#ff7eb6]？[/color] log [(x_{1} + x_{2})/2]", "＜",
				"左邊 = log √{x_{1}x_{2}}；算幾不等式 √{x_{1}x_{2}} < (x_{1} + x_{2})/2，log 又是遞增，所以左邊比較小。", "設 0 < x_{1} < x_{2}：")},
		 ]},

		{"id": "cross1", "chapter": 1, "type": "cross", "title": "鏡面交點", "tag": TAG_CROSS,
		 "params": ["s"], "mirror": true,
		 "story": "徒手畫出兩條鏡像曲線，再數交點。",
		 "variants": [
			{"lhs": "2^{x}", "rhs": "log_{2} x", "exp": {"form": "exp", "a": 2.0}, "quad": {"form": "log", "a": 2.0}, "n": 0,
			 "domain": Vector2(-1.0, 7.0), "need": Vector2(0.0, 5.0), "start": {"s": 1.0}, "ranges": {"s": [-1.0, 7.0, 0.05]},
			 "view": {"y": Vector2(-2.5, 6.0)},
			 "nudge": "a > 1 時只在 y = x 上相交。2^{x} 碰得到 y = x 嗎？",
			 "why": "2^{x} 在 y = x 上方、log_{2} x 在下方：沒有交點。",
			 "insight": "a > 1：交點都在 y = x 上；a > 約 1.44 就沒有交點。"},
			{"weight": 2, "lhs": "(√{2})^{x}", "rhs": "log_{√{2}} x", "exp": {"form": "exp", "a": 1.4142135623731}, "quad": {"form": "log", "a": 1.4142135623731}, "n": 2,
			 "domain": Vector2(-1.0, 7.0), "start": {"s": 1.0}, "ranges": {"s": [-1.0, 7.0, 0.05]},
			 "view": {"y": Vector2(-1.5, 6.0)},
			 "nudge": "交點在 y = x 上。(√{2})^{x} = x：x = 2、4 成立嗎？",
			 "why": "交於 (2, 2)、(4, 4)，共 2 個。",
			 "insight": "1 < a < 約 1.44：a^{x} 穿過 y = x 兩次，共 2 個交點。"},
			{"lhs": "(4/3)^{x}", "rhs": "log_{4/3} x", "exp": {"form": "exp", "a": 1.3333333333333}, "quad": {"form": "log", "a": 1.3333333333333}, "n": 2,
			 "domain": Vector2(-1.0, 8.0), "start": {"s": 1.0}, "ranges": {"s": [-1.0, 8.0, 0.05]},
			 "view": {"y": Vector2(-1.5, 8.5)},
			 # 沒有兩個以上的整數點可以標：畫之前先給三個會通過的點（第二條是鏡像，x、y 對調）
			 "guides": {1: [[0.0, 1.0, "(0, 1)"], [2.0, 16.0 / 9.0, "(2, 16/9)"], [4.0, 256.0 / 81.0, "(4, 256/81)"]],
				2: [[1.0, 0.0, "(1, 0)"], [16.0 / 9.0, 2.0, "(16/9, 2)"], [256.0 / 81.0, 4.0, "(256/81, 4)"]]},
			 "nudge": "比較 (4/3)^{x} 和 x：x = 1、3、7 時誰大？",
			 "why": "x = 1、3、7 時大小換了兩次：2 個交點，都在 y = x 上。",
			 "insight": "(4/3)^{x} 與 log_{4/3} x 的兩交點都在 y = x 上。"},
			{"lhs": "(1/2)^{x}", "rhs": "log_{1/2} x", "exp": {"form": "exp", "a": 0.5}, "quad": {"form": "log", "a": 0.5}, "n": 1,
			 "domain": Vector2(-2.5, 6.0), "start": {"s": 0.5}, "ranges": {"s": [-2.5, 6.0, 0.05]},
			 "view": {"x": Vector2(-2.5, 6.0), "y": Vector2(-2.5, 5.0)},     # 往左多看一點：(1/2)^{x} 才有 (−2, 4)、(−1, 2) 可以標
			 "nudge": "遞減曲線一定穿過 y = x 一次，鏡像也交在同一點。",
			 "why": "(1/2)^{x} 遞減，和 y = x 交一次（x ≈ 0.64），共 1 個。",
			 "insight": "0 < a < 1 時交點不一定在 y = x 上，例如 a = 1/16 有 3 個。"},
		 ]},

		{"id": "boss1", "choices": BASES, "chapter": 1, "type": "fit", "title": "第一章試煉", "form": "log",
		 "params": ["a", "h", "k"], "live": false, "time": 130.0,
		 "view": {"x": Vector2(-2.0, 7.0), "y": Vector2(-3.0, 3.5)},
		 "story": "限時 130 秒！先找鉛直雷射牆和恆過點，再往上 1 格找底數。",
		 "predicts": [
			{"q": "y = log_{a}(x − h) + k 一定通過哪一點？",
			 "options": ["(1 + h, k)", "(h, k)", "(1, 0)", "(h, 1 + k)"], "correct": 0,
			 "why": "x − h = 1 時 log 為 0，y = k。",
			 "nudge": "log_{a}(x − h) = 0 時，x − h = ？", "tag": "log_fixed_point"},
			{"q": "在 y = log_{a}(x − h) + k 上，y = k + 1 的點 x 坐標是？",
			 "options": ["a + h", "a", "1 + a", "h + 1/a"], "correct": 0,
			 "why": "log = 1 ⇒ x = a + h：比恆過點高 1 的寶石讀出 a。",
			 "nudge": "log_{a}(x − h) = 1 時，x − h = ?", "tag": "log_base_compare"}],
		 "insight": "漸近線給 h，(1 + h, k) 給 k，(a + h, k + 1) 給 a。",
		 "variants": [
			{"answer": {"a": 2.0, "h": 1.0, "k": -1.0}, "xs": [1.5, 2, 3, 5]},
			{"answer": {"a": 0.5, "h": -1.0, "k": 1.0}, "xs": [-0.5, 0, 1, 3]},
			{"answer": {"a": 3.0, "h": 0.0, "k": -1.0}, "xs": [1.0 / 3.0, 1, 3]},
			{"answer": {"a": 0.5, "h": 2.0, "k": 0.0}, "xs": [2.5, 3, 4, 6]},
		 ]},

		# ======================= 第二章．交點之鏡 =======================
		{"id": "twin", "choices": BASES, "chapter": 2, "type": "fit", "title": "雙生對數", "form": "log_abs_in",
		 "params": ["a"], "live": true, "view": {"x": Vector2(-5.0, 5.0), "y": Vector2(-3.0, 3.0)},
		 "story": "圖形被 y 軸切開、左右對稱。調整 a 點亮兩邊寶石。",
		 "predicts": [
			{"q": "這座光橋是 y = log_{a}|x|。它的圖形對稱於？",
			 "options": ["y 軸", "x 軸", "原點", "直線 y = x"], "correct": 0,
			 "why": "|−x| = |x|：對 y 軸對稱。",
			 "nudge": "x = 2 和 x = −2 代進去，y 一樣嗎？", "tag": "log_abs"},
			{"q": "這座光橋 y = log_{a}|x| 的定義域是？",
			 "options": ["x ≠ 0", "x > 0", "全體實數", "x ≥ 0"], "correct": 0,
			 "why": "|x| > 0 ⇔ x ≠ 0：左右兩支，被 y 軸隔開。",
			 "nudge": "|x| 什麼時候會等於 0？", "tag": "log_domain"}],
		 "insight": "log_{a}|x|：右半是 log_{a} x，左半是鏡像。",
		 "variants": [
			{"answer": {"a": 2.0}, "xs": [-4, -1, 1, 4]},
			{"answer": {"a": 3.0}, "xs": [-3, -1, 1, 3]},
			{"answer": {"a": 0.5}, "xs": [-2, -1, 1, 2]},
		 ]},

		{"id": "twin_shift", "chapter": 2, "type": "fit", "title": "移動的鏡子", "form": "log_abs_in",
		 "params": ["h", "k"], "live": false, "fixed": {"a": 2.0},
		 "view": {"x": Vector2(-5.0, 5.0), "y": Vector2(-3.0, 3.5)},
		 "story": "找出兩顆等高的寶石，鏡子就在它們正中間。",
		 "predicts": [],
		 "insight": "對稱軸（也是漸近線）x = h；|x − h| = 1 時 y = k。兩根和 = 2h。",
		 "variants": [
			{"answer": {"h": 1.0, "k": 0.0}, "xs": [-1, 0, 2, 3],
			 "predicts": [_tag(B1._axis_pred("y = log_{2}|x − h| + k", -1, 3, 1, 1))], "chain": [_tag(B1._sum_pred("y = log_{2}|x − h| + k", 1))]},
			{"answer": {"h": -1.0, "k": 1.0}, "xs": [-3, -2, 0, 1],
			 "predicts": [_tag(B1._axis_pred("y = log_{2}|x − h| + k", -3, 1, 2, -1))], "chain": [_tag(B1._sum_pred("y = log_{2}|x − h| + k", -1))]},
			{"answer": {"h": 2.0, "k": -1.0}, "xs": [0, 1, 3, 4],
			 "predicts": [_tag(B1._axis_pred("y = log_{2}|x − h| + k", 0, 4, 0, 2))], "chain": [_tag(B1._sum_pred("y = log_{2}|x − h| + k", 2))]},
		 ]},

		{"id": "fold", "chapter": 2, "type": "fit", "title": "反彈之光", "form": "log_abs_out",
		 "params": ["h", "k"], "live": false, "fixed": {"a": 2.0},
		 "view": {"x": Vector2(-2.0, 6.0), "y": Vector2(-1.0, 3.5)},
		 "story": "x 軸下方會翻上來。先找出碰到 x 軸的位置。",
		 "predicts": [
			{"q": "這座光橋 y = |log_{2}(x − h) + k| 是怎麼來的？",
			 "options": ["把 x 軸下方的部分翻到上方", "左右翻折", "對 y = x 翻折", "把 y 軸左邊翻到右邊"], "correct": 0,
			 "why": "0 < x < 1 時 log_{2} x < 0，取絕對值翻上來。",
			 "nudge": "|負數| 會變成什麼？", "tag": "log_abs"},
			{"q": "這座光橋 y = |log_{2}(x − h) + k| 碰到 x 軸的地方，滿足？",
			 "options": ["log_{2}(x − h) + k = 0", "log_{2}(x − h) = k", "x = h", "x = 0"], "correct": 0,
			 "why": "絕對值等於 0 ⇔ 裡面等於 0。反彈就從這一點開始。",
			 "nudge": "絕對值什麼時候等於 0？", "tag": "log_abs"}],
		 "insight": "|f(x)|：x 軸下方翻上來。|log_{2} x| = c（c > 0）兩根乘積 = 1。",
		 "variants": [
			{"answer": {"h": 0.0, "k": -1.0}, "xs": [0.5, 1, 2, 4], "predicts": [_tag(B1._fold_pred("y = |log_{2}(x − h) + k|", 1, 1))]},
			{"answer": {"h": 1.0, "k": 0.0}, "xs": [1.25, 1.5, 2, 3], "predicts": [_tag(B1._fold_pred("y = |log_{2}(x − h) + k|", 1.5, 1))]},
			{"answer": {"h": -1.0, "k": -1.0}, "xs": [-0.5, 0, 1, 3], "predicts": [_tag(B1._fold_pred("y = |log_{2}(x − h) + k|", 0, 1))]},
		 ]},

		{"id": "sketch2", "chapter": 2, "type": "draw", "title": "徒手翻折", "form": "log_abs_out",
		 "params": [], "tag": "draw_graph", "view": {"x": Vector2(-2.0, 7.0), "y": Vector2(-1.0, 3.5)},
		 "story": "沒有滑桿！先想對數圖形，再把 x 軸下方翻上來。",
		 "insight": "先畫對數圖形，x 軸下方翻上來，碰到 x 軸處是尖點。",
		 "variants": [
			{"answer": {"a": 2.0, "h": 0.0, "k": 0.0}, "keys": [Vector2(0.5, 1), Vector2(1, 0), Vector2(2, 1), Vector2(4, 2)]},
			{"answer": {"a": 2.0, "h": 0.0, "k": -1.0}, "keys": [Vector2(1, 1), Vector2(2, 0), Vector2(4, 1)]},
			{"answer": {"a": 2.0, "h": -1.0, "k": 0.0}, "keys": [Vector2(-0.5, 1), Vector2(0, 0), Vector2(1, 1), Vector2(3, 2)]},
		 ]},

		{"id": "count", "chapter": 2, "type": "count", "title": "交點調頻",
		 "params": ["c"], "goals": [2, 1, 0], "ranges": {"c": [-1.0, 2.5, 0.25]},
		 "story": "方程式的解 = 圖形交點。移動水平線 y = c 完成任務。",
		 "insight": "f(x) = c 的解數 = 交點數；碰到最低點時會跳動。",
		 "variants": [
			{"form": "log_abs_out", "fixed": {"a": 2.0}, "view": {"x": Vector2(-0.8, 6.5), "y": Vector2(-1.0, 3.5)},
			 "final": {"q": "方程式 |log_{2} x| = c 恰有兩個實數解時，c 的範圍是？",
				"options": ["c > 0", "c ≥ 0", "0 < c < 1", "c > 1"], "correct": 0,
				"why": "最低點 (1, 0)：c > 0 兩解、c = 0 一解、c < 0 無解。",
				"nudge": "最低點在哪？水平線比它高、一樣高、比它低時各有幾個交點？", "tag": "solution_count"}},
			{"form": "log_abs_both", "fixed": {"a": 2.0}, "goals": [4, 2, 0],
			 "view": {"x": Vector2(-6.5, 6.5), "y": Vector2(-1.0, 3.5)},
			 "final": {"q": "方程式 |log_{2}|x|| = c 恰有 4 個實數解時，c 的範圍是？",
				"options": ["c > 0", "c ≥ 0", "c > 1", "0 < c < 1"], "correct": 0,
				"why": "x > 0 一半有 2 解，左右對稱共 4 個；c = 0 時 x = ±1。",
				"nudge": "左右對稱：x > 0 的交點數乘 2。", "tag": "solution_count"}},
		 ]},

		{"id": "cross2", "chapter": 2, "type": "cross", "title": "交點獵人", "tag": TAG_CROSS,
		 "params": ["s"],
		 "story": "先徒手畫出兩個圖形，再數交點。",
		 "variants": [
			{"lhs": "log_{1/2} x", "rhs": "2 − x", "exp": {"form": "log", "a": 0.5}, "quad": [0.0, -1.0, 2.0], "n": 2,
			 "domain": Vector2(-1.0, 7.0), "start": {"s": 0.5}, "ranges": {"s": [-1.0, 7.0, 0.05]},
			 "view": {"y": Vector2(-3.0, 4.0)},
			 "nudge": "兩條都遞減，要列表：x = 1/4、1、4 時誰大？",
			 "why": "1/4 到 1 之間變號一個，加上 x = 4，共 2 個。",
			 "insight": "兩條都遞減時，要列表比大小才知道交幾次。"},
			{"lhs": "|log_{2} x|", "rhs": "x − 1", "exp": {"form": "log_abs_out", "a": 2.0}, "quad": [0.0, 1.0, -1.0], "n": 2,
			 "domain": Vector2(-1.0, 7.0), "start": {"s": 0.5}, "ranges": {"s": [-1.0, 7.0, 0.05]},
			 "view": {"y": Vector2(-2.0, 5.0)},
			 "nudge": "0 < x < 1 時一正一負；x ≥ 1 時就是 log_{2} x = x − 1。",
			 "why": "x < 1 碰不到；x ≥ 1 時解是 1 和 2，共 2 個。",
			 "insight": "先用正負號排除一段，再處理剩下的部分。"},
			{"lhs": "log_{2}|x|", "rhs": "x^{2}", "exp": {"form": "log_abs_in", "a": 2.0}, "quad": [1.0, 0.0, 0.0], "n": 0,
			 "view": {"y": Vector2(-3.0, 6.0)},
			 "nudge": "左右對稱，先看 x > 0：log_{2} x 和 x^{2} 誰大？",
			 "why": "x > 0 時 log_{2} x 永遠小於 x^{2}：0 個。",
			 "insight": "對數長得慢、二次長得快：log_{2}|x| = x^{2} 無解。"},
			{"lhs": "log_{2}|x|", "rhs": "(x + 1)/2", "exp": {"form": "log_abs_in", "a": 2.0}, "quad": [0.0, 0.5, 0.5], "n": 1,
			 "view": {"y": Vector2(-3.0, 4.0)},
			 "nudge": "直線是 y = (x + 1)/2。x > 0、x < 0 分開看。",
			 "why": "x > 0 不交；x < 0 時在 x = −1 交一次，共 1 個。",
			 "insight": "恰有一個交點 (−1, 0)。"},
			{"lhs": "log_{1/2} x", "rhs": "(x + 1)/2", "exp": {"form": "log", "a": 0.5}, "quad": [0.0, 0.5, 0.5], "n": 1,
			 "domain": Vector2(-1.0, 7.0), "start": {"s": 0.5}, "ranges": {"s": [-1.0, 7.0, 0.05]},
			 "view": {"y": Vector2(-3.0, 4.0)},
			 "nudge": "log_{1/2} x 遞減、直線遞增。",
			 "why": "一減一增，恰交一次。",
			 "insight": "一增一減最多一個交點；再確認兩端的高低順序相反，就恰有一個。"},
		 ]},

		{"id": "boss2", "choices": BASES, "chapter": 2, "type": "fit", "title": "鏡之試煉", "form": "log_abs_in",
		 "params": ["a", "h", "k"], "live": false, "time": 130.0,
		 "view": {"x": Vector2(-5.0, 5.0), "y": Vector2(-3.0, 3.0)},
		 "story": "限時 130 秒！先用等高的寶石找出對稱軸。",
		 "predicts": [
			{"q": "y = log_{a}|x − h| + k 的圖形以哪條直線為對稱軸？",
			 "options": ["x = h", "x = −h", "y = k", "y = x"], "correct": 0,
			 "why": "等高兩寶石的中點就是對稱軸 x = h。",
			 "nudge": "log_{a}|x| 對稱於 x = 0，右移 h 之後呢？", "tag": "log_abs"},
			{"q": "方程式 log_{a}|x − h| + k = c 有兩個解時，兩根之和是？",
			 "options": ["2h", "h", "0", "2c"], "correct": 0,
			 "why": "兩根對稱於 x = h：和為 2h。",
			 "nudge": "兩個根對稱於哪條直線？", "tag": "log_abs"}],
		 "insight": "對稱軸給 h；|x − h| = 1 給 k；|x − h| = a 時 y = k + 1 給 a。",
		 "variants": [
			{"answer": {"a": 2.0, "h": 1.0, "k": -1.0}, "xs": [-1, 0, 2, 3]},
			{"answer": {"a": 0.5, "h": -1.0, "k": 1.0}, "xs": [-3, -2, 0, 1]},
			{"answer": {"a": 3.0, "h": 0.0, "k": 0.0}, "xs": [-3, -1, 1, 3]},
		 ]},
	]
