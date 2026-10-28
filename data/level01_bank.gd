extends RefCounted
## 第一大關「光之橋」題庫（對應講義 2-1 重點一：指數函數之圖形與性質）
##
## 結構：
##   slots() 依難度排序，每個 slot 是一段旅程；每次遊玩從 variants 隨機抽一題，
##   預言題（predicts）也從題池隨機抽一題、選項順序隨機打亂。
##   variant 裡的欄位會覆蓋 slot 的同名欄位。
##
## 旅程類型 type：
##   fit       調參數讓光橋穿過寶石（寶石由 answer 與 xs 自動算出）
##   rank      底數辨識：替沒標名字的曲線配上底數（bases）
##   quadrant  象限燈塔：調 h、k 讓指定象限亮起（target）；impossible = 做不到
##   count     交點調頻：移動水平線 y = c 達成交點數目標（goals），再回答 final
##   table     列表作圖：不給圖形。逐一比較 xs 每個 x 的左右兩邊大小（點會畫上棋盤），
##             再點出「大小相反」的區間，最後判斷交點總數；答完才把曲線畫出來
##   cross     交點獵人：預言指數函數 exp 與二次函數 quad（[p, q, r] 表 px² + qx + r）
##             的交點數 n（學生先徒手畫出兩條圖形，畫對了再回答交點個數）
##   chord     凹口比大小：先判斷凹口方向，再在圖上點 P、Q 連出弦，最後比較
##             「函數值的平均」[f(x₁) + f(x₂)]/2 與「中點代入」f((x₁ + x₂)/2)（chord 給 x1、x2）
##   draw      徒手作圖：不給圖形也不給滑桿，玩家一筆畫出 answer 描述的函數；
##             keys 是一定要經過的點（答錯一次後才會顯示）。評分很嚴格：要畫滿畫面、
##             不能往回畫、不能越過漸近線、要經過所有 keys，平均偏差也要很小
## variant 可加 "weight"（預設 1）調整被抽中的機率；table 與 cross 同一輪不會抽到相同的方程式
##
## 函數型態 form：
##   exp      y = M·a^{x − h} + k
##   abs_in   y = M·a^{|x − h|} + k
##   abs_out  y = |M·a^{x − h} + k|
##   abs_y    |y| = M·a^{x − h} + k
##
## 新增題目：在對應 slot 的 variants 裡加一筆即可；fit 題請確認答案唯一
##（可執行 test_bank 測試場景檢查）。

const DIR_UP := {"q": "寶石在 (0, 1) 的右上方。曲線往右應該？",
	"options": ["往右上升 → a > 1", "往右下降 → 0 < a < 1"], "correct": 0, "keep_order": true,
	"why": "越往右越高 → 遞增，所以 a > 1。",
	"nudge": "比較寶石和 (0, 1)：往右走，曲線是變高還是變低？", "tag": "exp_monotonic"}

const DIR_DOWN := {"q": "寶石在 (0, 1) 的左上方。曲線往右應該？",
	"options": ["往右上升 → a > 1", "往右下降 → 0 < a < 1"], "correct": 1, "keep_order": true,
	"why": "左邊高、右邊低 → 往右下降，所以 0 < a < 1。",
	"nudge": "寶石在左邊而且比較高。那往右走，曲線會變高還是變低？", "tag": "exp_monotonic"}


## 凹口比大小：先判斷凹口方向（up = true 表示凹口向上）
static func conc_q(eq: String, up: bool, why: String) -> Dictionary:
	return {"q": eq + " 的圖形，凹口朝哪個方向？", "options": ["凹口向上（像碗）", "凹口向下（像蓋子）"],
		"correct": 0 if up else 1, "keep_order": true, "why": why,
		"nudge": "往右走越陡還是越平？曲線往上彎還是往下彎？", "tag": "concavity"}


## 凹口比大小：最後比較「函數值的平均」和「中點代入的函數值」；ans 是 "＞"、"＜" 或 "＝"
static func conc_final(q: String, ans: String, why: String, cond := "") -> Dictionary:
	return {"q": "比比看，[color=#ff7eb6]？[/color] 要填哪個符號？\n" + (cond + "\n" if cond != "" else "") + q, "options": ["＞", "＜", "＝"], "correct": ["＞", "＜", "＝"].find(ans), "keep_order": true, "cols": 4,
		"why": why, "nudge": "M 是函數值的平均、N 是中點的函數值。誰比較高？", "tag": "concavity"}


## 第一章試煉的三個小問題：先看差距比找 a，再找讓 y − k 成等比的 k，最後用 y − k = 1 的寶石找 h
static func _boss_a(ys: String, diffs: String, a: String, opts: Array) -> Dictionary:
	return {"q": "寶石由左到右的 y 是 %s，相鄰兩顆差 %s。每往右一格，差距乘上多少？（這就是底數 a）" % [ys, diffs],
		"options": opts, "correct": 0, "why": "差距的比值就是底數：a = %s。" % a,
		"nudge": "後一個差距 ÷ 前一個差距。", "tag": "exp_ratio"}


static func _boss_k(a: String, k: String, opts: Array, why: String) -> Dictionary:
	return {"q": "y − k 要每往右一格都乘 %s。哪一個 k（雷射牆）符合？" % a,
		"options": opts, "correct": 0, "why": why + "，雷射牆是 y = %s。" % k,
		"nudge": "代入選項：y − k 是否每格都乘 %s？" % a, "tag": "asymptote_shift"}


static func _boss_h(k: String, h: String, opts: Array, why: String) -> Dictionary:
	return {"q": "y − %s = a^{x − h}。哪一顆寶石的 y − %s 剛好等於 1？它的 x 就是 h。h = ？" % [k, k] if not k.begins_with("−") else
		"y + %s = a^{x − h}。哪一顆寶石的 y + %s 剛好等於 1？它的 x 就是 h。h = ？" % [k.trim_prefix("−"), k.trim_prefix("−")],
		"options": opts, "correct": 0, "why": why,
		"nudge": "a^{0} = 1：x − h = 0 時 y − k = 1。", "tag": "exp_fixed_point"}


const UITheme := preload("game_theme.gd")

## 數字的顯示（負號用 −）
static func _sn(v: float) -> String:
	return UITheme.num(v, 2).replace("-", "−")


## 「移動的鏡子」：用這一題自己的兩顆等高寶石問對稱軸，接著問同一座光橋的兩根之和
static func _axis_pred(fn: String, x1: float, x2: float, y: float, h: float) -> Dictionary:
	var opts := ["x = " + _sn(h), "x = 0", "x = " + _sn(-h if not is_zero_approx(h) else 1.0), "y = " + _sn(y)]
	return {"q": "寶石 (%s, %s) 和 (%s, %s) 一樣高。這座光橋 %s 的對稱軸是？" % [_sn(x1), _sn(y), _sn(x2), _sn(y), fn],
		"options": opts, "correct": 0,
		"why": "等高兩點的中點是對稱軸：x = (%s + %s) ÷ 2 = %s。" % [_sn(x1), _sn(x2), _sn(h)],
		"nudge": "對稱軸在兩顆一樣高的寶石正中間。", "tag": "abs_symmetry"}


static func _sum_pred(fn: String, h: float) -> Dictionary:
	return {"q": "同一座光橋 %s 被水平線 y = c 切在兩點。兩點的 x 坐標之和是？" % fn,
		"options": [_sn(2.0 * h), "0", _sn(h), _sn(4.0 * h)], "correct": 0,
		"why": "兩交點對稱於 x = %s：x₁ + x₂ = 2 × %s = %s。" % [_sn(h), _sn(h), _sn(2.0 * h)],
		"nudge": "兩個交點對稱於哪條直線？", "tag": "abs_symmetry"}


## 「反彈」：問某顆寶石在翻折之前（沒有絕對值時）的高度
static func _fold_pred(fn: String, x: float, y: float) -> Dictionary:
	return {"q": "寶石 (%s, %s) 在這座光橋 %s 上。翻折之前（拿掉絕對值時），它的 y 是？" % [_sn(x), _sn(y), fn],
		"options": [_sn(-y), _sn(y), "0", _sn(2.0 * y)], "correct": 0,
		"why": "原本在 x 軸下方（y = %s），取絕對值翻上來變 %s。" % [_sn(-y), _sn(y)],
		"nudge": "絕對值把負的翻成正的。這顆寶石是被翻上來的嗎？", "tag": "abs_reflect"}


## 「倒影」：用這一題的寶石反推底數
static func _base_pred(x: float, y: float, a_txt: String, opts: Array, why: String) -> Dictionary:
	return {"q": "寶石 (%s, %s) 在 y = a^{x} 上：a^{%s} = %s，所以 a = ？" % [_sn(x), _sn(y), _sn(x), _sn(y)],
		"options": [a_txt] + opts, "correct": 0, "why": why,
		"nudge": "負的次方是倒數：a^{−1} = 1/a。", "tag": "exp_value"}


static func slots() -> Array:
	return [
		# ======================= 第一章．指數之光 =======================
		{"id": "rise", "chapter": 1, "type": "fit", "title": "第一道光", "form": "exp",
		 "params": ["a"], "live": true,
		 "story": "光靈要跨過深谷。調整底數 a，讓光橋穿過所有寶石！",
		 "predicts": [DIR_UP,
			{"q": "不論 a 是多少，y = a^{x} 一定通過哪一點？",
			 "options": ["(0, 1)", "(1, 0)", "(1, a)", "(0, a)"], "correct": 0,
			 "why": "a^{0} = 1，一定通過 (0, 1)。",
			 "nudge": "把 x = 0 代進去，a^{0} 等於多少？", "tag": "exp_fixed_point"}],
		 "insight": "y = a^{x} 都過 (0, 1)；x = 1 的高度就是底數 a。",
		 "variants": [
			{"answer": {"a": 2.0}, "xs": [-1, 0, 2]},
			{"answer": {"a": 1.5}, "xs": [0, 2]},
			{"answer": {"a": 2.5}, "xs": [0, 2]},
			{"answer": {"a": 3.0}, "xs": [-1, 0, 2], "view": {"y": Vector2(-1.5, 10.5)}},
		 ]},

		{"id": "fall", "chapter": 1, "type": "fit", "title": "倒影之谷", "form": "exp",
		 "params": ["a"], "live": true,
		 "story": "這次寶石在左邊高處。想想曲線要往哪個方向走？",
		 "predicts": [DIR_DOWN],
		 "insight": "0 < a < 1 往右下降；a^{x} 與 (1/a)^{x} 對稱於 y 軸。",
		 "variants": [
			{"answer": {"a": 0.5}, "xs": [-2, 0, 1], "predicts": [DIR_DOWN, _base_pred(-2, 4, "1/2", ["2", "−2", "1/4"],
				"a^{−2} = 1/a^{2} = 4 ⇒ a^{2} = 1/4 ⇒ a = 1/2（a > 0）。")]},
			{"answer": {"a": 0.25}, "xs": [-1, 0], "predicts": [DIR_DOWN, _base_pred(-1, 4, "1/4", ["4", "−4", "1/2"],
				"a^{−1} = 1/a = 4 ⇒ a = 1/4。")]},
			{"answer": {"a": 0.2}, "xs": [-1, 0], "predicts": [DIR_DOWN, _base_pred(-1, 5, "1/5", ["5", "−5", "1/25"],
				"a^{−1} = 1/a = 5 ⇒ a = 1/5。")]},
			{"answer": {"a": 0.4}, "xs": [-2, 0]},
		 ]},

		{"id": "rank", "chapter": 1, "type": "rank", "title": "底數辨識",
		 "params": [], "live": true,
		 "story": "幾座光橋的名牌被風吹走了！幫每條曲線找回它的底數。",
		 "predicts": [
			{"q": "在直線 x = 1 上，y = a^{x} 的高度是多少？",
			 "options": ["1", "a", "0", "1/a"], "correct": 1,
			 "why": "x = 1 時 y = a：越高的曲線底數越大。",
			 "nudge": "把 x = 1 代進 y = a^{x}。", "tag": "exp_base_compare"},
			{"q": "在 x < 0 的那一側，底數越大的曲線會？",
			 "options": ["越高", "越低", "一樣高", "不一定"], "correct": 1,
			 "why": "x = −1 時 y = 1/a：底數越大反而越低。",
			 "nudge": "x = −1 時 y = 1/a。a 越大，1/a 會？", "tag": "exp_base_compare"}],
		 "insight": "比底數看 x = 1 的高度：越高底數越大；x < 0 時順序相反。",
		 "variants": [
			{"bases": [2.0, 3.0, 0.5, 1.0 / 3.0]},
			{"bases": [1.5, 2.0, 4.0]},
			{"bases": [0.5, 0.25, 2.0, 4.0]},
			{"bases": [1.2, 2.0, 5.0, 0.4]},
		 ]},

		{"id": "lift", "chapter": 1, "type": "fit", "title": "升空之泉", "form": "exp",
		 "params": ["a", "k"], "live": false,
		 "story": "霧中模式：寶石不先發光。小心黑洞和雷射牆（漸近線）。",
		 "predicts": [
			{"q": "y = a^{x} + k 的圖形一定通過哪一點？",
			 "options": ["(0, 1)", "(0, 1 + k)", "(0, k)", "(1, k)"], "correct": 1,
			 "why": "x = 0 時 y = 1 + k：看 x = 0 的寶石就知道 k。",
			 "nudge": "x = 0 代入：a^{0} 等於多少？", "tag": "exp_fixed_point"},
			{"q": "y = a^{x} + k 的漸近線是？",
			 "options": ["y = 0", "y = k", "y = 1", "y = 1 + k"], "correct": 1,
			 "why": "a^{x} > 0 且可無限接近 0，所以 y 無限接近 k。",
			 "nudge": "x 往某一邊走很遠時，a^{x} 會接近多少？", "tag": "asymptote_shift"}],
		 "insight": "加 k 就上移 k：過 (0, 1 + k)，漸近線 y = k。",
		 "variants": [
			{"answer": {"a": 2.0, "k": 2.0}, "xs": [0, 1, 2]},
			{"answer": {"a": 2.0, "k": -1.0}, "xs": [0, 1, 2]},
			{"answer": {"a": 0.5, "k": 1.0}, "xs": [-2, -1, 0]},
			{"answer": {"a": 2.0, "k": -2.0}, "xs": [0, 1, 2, 3]},
			{"answer": {"a": 3.0, "k": 1.0}, "xs": [0, 1, 2], "view": {"y": Vector2(-1.5, 10.5)}},
		 ]},

		{"id": "sketch", "chapter": 1, "type": "draw", "title": "徒手作圖", "form": "exp",
		 "params": [], "tag": "draw_graph",
		 "story": "沒有滑桿！直接把圖形畫出來（可以分好幾筆）。",
		 "insight": "畫法：漸近線 y = k → 點 (h, 1 + k)、(h + 1, a + k) → 一邊貼漸近線、一邊變陡。",
		 "variants": [
			{"answer": {"a": 2.0, "h": 0.0, "k": -1.0}, "keys": [Vector2(0, 0), Vector2(1, 1), Vector2(2, 3)]},
			{"answer": {"a": 0.5, "h": 0.0, "k": 1.0}, "keys": [Vector2(0, 2), Vector2(-1, 3), Vector2(-2, 5)]},
			{"answer": {"a": 2.0, "h": 1.0, "k": 0.0}, "keys": [Vector2(1, 1), Vector2(2, 2), Vector2(3, 4)]},
			{"answer": {"a": 2.0, "h": -1.0, "k": -2.0}, "keys": [Vector2(-1, -1), Vector2(0, 0), Vector2(1, 2)],
			 "view": {"y": Vector2(-3.0, 6.5)}},
		 ]},

		{"id": "quad", "chapter": 1, "type": "quadrant", "title": "象限燈塔", "form": "exp",
		 "params": ["h", "k"], "fixed": {"a": 2.0},
		 "story": "調整 h、k，讓光橋只經過指定的象限。",
		 "predicts": [
			{"q": "無論 h、k 為何，y = 2^{x − h} + k 一定通過第幾象限？",
			 "options": ["第一象限", "第二象限", "第三象限", "第四象限"], "correct": 0, "keep_order": true,
			 "why": "x 很大時 2^{x − h} 非常大，一定進入第一象限。",
			 "nudge": "x 往右走很遠，y 會變成怎樣？", "tag": "quadrant"},
			{"q": "y = 2^{x − h} + k 的圖形最多能通過幾個象限？",
			 "options": ["2 個", "3 個", "4 個"], "correct": 1, "keep_order": true,
			 "why": "遞增：左貼 y = k、右進第一象限，最多過 3 個象限。",
			 "nudge": "曲線一直往上走。左邊會停在哪條線附近？", "tag": "quadrant"}],
		 "insight": "必過 Ⅰ。b ≥ 0：Ⅰ、Ⅱ；b < 0：再過 Ⅲ，y 截距決定 Ⅱ 或 Ⅳ（過原點只過 Ⅰ、Ⅲ）。",
		 "variants": [
			{"target": [1, 2], "answer": {"h": 0.0, "k": 0.0}},
			{"target": [1, 2, 3], "answer": {"h": -2.0, "k": -1.0}},
			{"target": [1, 3, 4], "answer": {"h": 1.0, "k": -1.0}},
			{"target": [1, 3], "answer": {"h": 0.0, "k": -1.0}},
			{"target": [1, 2, 3, 4], "impossible": true, "answer": {"h": 0.0, "k": -1.0}},
		 ]},

		{"id": "absorb", "chapter": 1, "type": "fit", "title": "平移變身", "form": "exp",
		 "params": ["h", "k"], "live": false,
		 "insight": "係數可吸收進指數：c·a^{x} 改寫成 a 的次方，乘係數 = 左右平移。",
		 "variants": [
			{"answer": {"a": 2.0, "h": -2.0, "k": -1.0}, "xs": [-3, -2, -1],
			 "story": "寶石在 y = 4·2^{x} − 1 上，只用 h、k 調出來。",
			 "predicts": [{"q": "4·2^{x} 可以改寫成？",
				"options": ["2^{x+2}", "2^{x−2}", "8^{x}", "2^{4x}"], "correct": 0,
				"why": "4·2^{x} = 2^{x+2}：係數 4 = 向左平移 2。",
				"nudge": "4 是 2 的幾次方？2^{2}·2^{x} = 2^{?}", "tag": "exp_shift_coef"}]},
			{"answer": {"a": 3.0, "h": -2.0, "k": 1.0}, "xs": [-2, -1, 0], "view": {"y": Vector2(-1.5, 10.5)},
			 "story": "寶石在 y = 9·3^{x} + 1 上，只用 h、k 調出來。",
			 "predicts": [{"q": "9·3^{x} 可以改寫成？",
				"options": ["3^{x+2}", "3^{x−2}", "27^{x}", "3^{9x}"], "correct": 0,
				"why": "9·3^{x} = 3^{x+2}：係數 9 = 向左平移 2。",
				"nudge": "9 是 3 的幾次方？", "tag": "exp_shift_coef"}]},
			{"answer": {"a": 2.0, "h": 1.0, "k": 1.0}, "xs": [0, 1, 2, 3],
			 "story": "寶石在 y = (1/2)·2^{x} + 1 上，只用 h、k 調出來。",
			 "predicts": [{"q": "(1/2)·2^{x} 可以改寫成？",
				"options": ["2^{x−1}", "2^{x+1}", "2^{x/2}", "1^{x}"], "correct": 0,
				"why": "(1/2)·2^{x} = 2^{x−1}：向右平移 1。",
				"nudge": "1/2 是 2 的幾次方？", "tag": "exp_shift_coef"}]},
			{"answer": {"a": 0.5, "h": 3.0, "k": 0.0}, "xs": [1, 2, 3, 4],
			 "story": "寶石在 y = 8·(1/2)^{x} 上，只用 h、k 調出來。",
			 "predicts": [{"q": "8·(1/2)^{x} 可以改寫成？",
				"options": ["(1/2)^{x−3}", "(1/2)^{x+3}", "4^{x}", "(1/2)^{8x}"], "correct": 0,
				"why": "8·(1/2)^{x} = (1/2)^{x−3}：向右平移 3。",
				"nudge": "8 是 1/2 的幾次方？（提示：負的）", "tag": "exp_shift_coef"}]},
		 ]},

		{"id": "ratio", "chapter": 1, "type": "fit", "title": "衰減追蹤", "form": "exp",
		 "params": ["m", "a"], "live": false,
		 "ranges": {"a": [0.02, 4.0, 0.02]},
		 "insight": "間隔相同、倍率就相同：y₂ ÷ y₁ = a^{x₂ − x₁}。",
		 "variants": [
			{"answer": {"m": 1000.0, "a": 0.36}, "xs": [0, 0.5, 1, 1.5],
			 "view": {"x": Vector2(-0.5, 4), "y": Vector2(-120, 1150)}, "ranges": {"m": [100, 2000, 50]},
			 "story": "藥量 y = M·a^{x}（毫克，x 小時）。讓光橋接住每筆數據。",
			 "predicts": [{"q": "藥量 0.5 小時從 1000 降到 600。再過 0.5 小時會剩多少？",
				"options": ["200", "360", "400", "500"], "correct": 1,
				"why": "每 0.5 小時乘 0.6，每 1 小時乘 0.36：a = 0.36。",
				"nudge": "1000 → 600 乘了多少？每 0.5 小時都乘一樣的數。", "tag": "exp_ratio"}]},
			{"answer": {"m": 200.0, "a": 3.0}, "xs": [0, 1, 2],
			 "view": {"x": Vector2(-0.5, 2.6), "y": Vector2(-200, 2100)}, "ranges": {"m": [50, 1000, 50], "a": [0.5, 4.0, 0.5]},
			 "story": "細菌數 y = M·a^{x}（x 小時）。讓光橋接住每筆數據。",
			 "predicts": [{"q": "細菌每小時變成 3 倍。第 0 小時 200 隻，第 2 小時有幾隻？",
				"options": ["600", "800", "1200", "1800"], "correct": 3,
				"why": "200 × 3 × 3 = 1800：每小時乘 3。",
				"nudge": "過 1 小時乘 3，過 2 小時呢？", "tag": "exp_ratio"}]},
			{"answer": {"m": 800.0, "a": 0.5}, "xs": [0, 1, 2, 3],
			 "view": {"x": Vector2(-0.5, 4), "y": Vector2(-80, 920)}, "ranges": {"m": [100, 1500, 50]},
			 "story": "放射性物質 y = M·a^{x}（克，x 小時）。讓光橋接住每筆數據。",
			 "predicts": [{"q": "每 1 小時剩下一半。從 800 克變成 100 克要幾小時？",
				"options": ["3 小時", "4 小時", "6 小時", "8 小時"], "correct": 0,
				"why": "800 → 400 → 200 → 100：減半 3 次，3 小時。",
				"nudge": "800 減半幾次會變成 100？", "tag": "exp_ratio"}]},
		 ]},

		{"id": "convex", "chapter": 1, "type": "chord", "title": "凹口天秤", "form": "exp", "params": [], "tag": "concavity",
		 "story": "把 P、Q 連成弦：弦的中點和曲線，誰比較高？",
		 "insight": "指數函數[color=#ffcf5a]凹口向上[/color]：[f(x_{1}) + f(x_{2})]/2 ＞ f((x_{1} + x_{2})/2)，任何底數都成立。",
		 "variants": [
			{"answer": {"a": 2.0}, "eq": "y = 2^{x}", "chord": {"x1": 1.0, "x2": 3.0},
			 "view": {"x": Vector2(-2.5, 4.5), "y": Vector2(-1.2, 9.8)},
			 "predicts": [conc_q("y = 2^{x}", true, "往右越來越陡、往左越來越平，曲線往上彎 ⇒ 凹口向上。")],
			 "final": conc_final("(2^{1} + 2^{3}) / 2 [color=#ff7eb6]？[/color] 2^{2}", "＞", "左邊 = (2 + 8)/2 = 5，右邊 = 4。凹口向上 ⇒ 弦在曲線上方 ⇒ 左邊比較大。")},
			{"answer": {"a": 0.5}, "eq": "y = (1/2)^{x}", "chord": {"x1": -3.0, "x2": -1.0},
			 "view": {"x": Vector2(-4.5, 2.5), "y": Vector2(-1.2, 9.8)},
			 "predicts": [conc_q("y = (1/2)^{x}", true, "雖然是遞減，但往左越來越陡、往右越來越平，曲線一樣往上彎 ⇒ 凹口向上。")],
			 "final": conc_final("[(1/2)^{−3} + (1/2)^{−1}] / 2 [color=#ff7eb6]？[/color] (1/2)^{−2}", "＞", "左邊 = (8 + 2)/2 = 5，右邊 = 4。底數小於 1 也是凹口向上，弦在曲線上方。")},
			{"answer": {"a": 3.0}, "eq": "y = 3^{x}", "chord": {"x1": 0.0, "x2": 2.0},
			 "view": {"x": Vector2(-2.5, 3.5), "y": Vector2(-1.2, 10.5)},
			 "predicts": [conc_q("y = 3^{x}", true, "指數函數往一邊越來越陡、另一邊越來越平 ⇒ 凹口向上。")],
			 "final": conc_final("(3^{0} + 3^{2}) / 2 [color=#ff7eb6]？[/color] 3^{1}", "＞", "左邊 = (1 + 9)/2 = 5，右邊 = 3。凹口向上 ⇒ 弦在曲線上方。")},
			{"answer": {"a": 2.0}, "eq": "y = 2^{x}", "chord": {"x1": -1.0, "x2": 2.0},
			 "view": {"x": Vector2(-3.0, 3.5), "y": Vector2(-1.0, 5.5)},
			 "predicts": [conc_q("y = 2^{x}", true, "往右越來越陡、往左越來越平 ⇒ 凹口向上。")],
			 "final": conc_final("(2^{x_{1}} + 2^{x_{2}}) / 2 [color=#ff7eb6]？[/color] 2^{(x_{1} + x_{2})/2}", "＞",
				"凹口向上，任何一條弦都在曲線上方，所以永遠是左邊大。（這其實就是算幾不等式：(A + B)/2 ＞ √{AB}）", "對任意 x_{1} ≠ x_{2}：")},
		 ]},

		{"id": "cross1", "chapter": 1, "type": "cross", "title": "交點獵人",
		 "params": ["s"],
		 "story": "先徒手畫出兩個函數，再數交點個數。",
		 "variants": [
			{"lhs": "2^{x}", "rhs": "x^{2}", "exp": {"form": "exp", "a": 2.0}, "quad": [1.0, 0.0, 0.0], "n": 3,
			 "view": {"y": Vector2(-1.5, 17.5)},
			 "nudge": "列表：x = −1、0、2、3、4、5 時，2^{x} 和 x^{2} 誰大？",
			 "why": "x < 0 一個，x = 2、4 各一個，共 3 個。",
			 "insight": "兩曲線每交換一次上下位置，就多一個交點。"},
			{"lhs": "(1/2)^{x}", "rhs": "x^{2}", "exp": {"form": "exp", "a": 0.5}, "quad": [1.0, 0.0, 0.0], "n": 3,
			 "view": {"x": Vector2(-5.0, 4.0), "y": Vector2(-1.5, 17.5)},
			 "nudge": "(1/2)^{x} 是 2^{x} 的左右鏡像，x^{2} 也對稱。",
			 "why": "左右翻轉 2^{x} = x^{2}：x = −2、−4，加 x > 0 一個。",
			 "insight": "x 換成 −x：圖形左右翻轉，交點個數不變。"},
			{"lhs": "3^{x}", "rhs": "x^{2}", "exp": {"form": "exp", "a": 3.0}, "quad": [1.0, 0.0, 0.0], "n": 1,
			 "view": {"y": Vector2(-1.5, 12.0)},
			 "nudge": "x > 0 時 3^{x} 和 x^{2} 誰大？試 x = 1、2、3。",
			 "why": "x > 0 時 3^{x} 一直較大，只在 x < 0 交一次。",
			 "insight": "底數變大長得更快：2^{x} = x^{2} 有 3 解，3^{x} = x^{2} 只有 1 解。"},
			{"lhs": "2^{x}", "rhs": "4 − x^{2}", "exp": {"form": "exp", "a": 2.0}, "quad": [-1.0, 0.0, 4.0], "n": 2,
			 "view": {"y": Vector2(-5.0, 10.0)},
			 "nudge": "4 − x^{2} 開口向下，頂點 (0, 4)；2^{x} 永遠大於 0。",
			 "why": "拋物線只在 −2 < x < 2 為正，2^{x} 在這段交 2 次。",
			 "insight": "2^{x} > 0：交點只在拋物線高於 x 軸的那段。"},
		 ]},

		{"id": "boss1", "chapter": 1, "type": "fit", "title": "第一章試煉", "form": "exp",
		 "params": ["a", "h", "k"], "live": false, "time": 105.0,
		 "story": "限時 105 秒！依序求出 a、k、h，再調滑桿點亮光橋。",
		 "insight": "反推：y − k 每格乘 a；y − k = 1 的寶石，x 就是 h。",
		 "variants": [
			{"answer": {"a": 0.5, "h": -1.0, "k": 2.0}, "xs": [-3, -2, -1, 0],
			 "predicts": [_boss_a("6、4、3、2.5", "2、1、0.5", "1/2", ["1/2", "2", "−1/2", "1/4"])],
			 "chain": [_boss_k("1/2", "2", ["2", "0", "1", "2.5"], "y − 2 = 4、2、1、0.5，每格乘 1/2 ✓"),
				_boss_h("2", "−1", ["−1", "0", "1", "−3"], "(−1, 3)：3 − 2 = 1 = (1/2)^{0}，所以 x − h = 0，h = −1。")]},
			{"answer": {"a": 2.0, "h": 1.0, "k": 1.0}, "xs": [1, 2, 3],
			 "predicts": [_boss_a("2、3、5", "1、2", "2", ["2", "1/2", "1", "3"])],
			 "chain": [_boss_k("2", "1", ["1", "0", "2", "−1"], "y − 1 = 1、2、4，每格乘 2 ✓"),
				_boss_h("1", "1", ["1", "0", "2", "−1"], "(1, 2)：2 − 1 = 1 = 2^{0}，所以 x − h = 0，h = 1。")]},
			{"answer": {"a": 2.0, "h": -1.0, "k": -1.0}, "xs": [-1, 0, 1],
			 "predicts": [_boss_a("0、1、3", "1、2", "2", ["2", "1/2", "1", "3"])],
			 "chain": [_boss_k("2", "−1", ["−1", "0", "1", "−2"], "y − (−1) = y + 1 = 1、2、4，每格乘 2 ✓"),
				_boss_h("−1", "−1", ["−1", "0", "1", "−2"], "(−1, 0)：0 + 1 = 1 = 2^{0}，所以 x − h = 0，h = −1。")]},
			{"answer": {"a": 0.5, "h": 1.0, "k": -1.0}, "xs": [-1, 0, 1],
			 "predicts": [_boss_a("3、1、0", "2、1", "1/2", ["1/2", "2", "−1/2", "1/4"])],
			 "chain": [_boss_k("1/2", "−1", ["−1", "0", "1", "−2"], "y + 1 = 4、2、1，每格乘 1/2 ✓"),
				_boss_h("−1", "1", ["1", "0", "−1", "2"], "(1, 0)：0 + 1 = 1 = (1/2)^{0}，所以 x − h = 0，h = 1。")]},
		 ]},

		# ======================= 第二章．鏡之谷 =======================
		{"id": "mirror", "chapter": 2, "type": "fit", "title": "對稱之門", "form": "abs_in",
		 "params": ["a"], "live": true,
		 "story": "調整 a，讓光橋同時接住左右兩邊的寶石。",
		 "predicts": [
			{"q": "這座光橋是 y = a^{|x|}（a > 1）。它的圖形對稱於？",
			 "options": ["x 軸", "y 軸", "原點", "直線 y = x"], "correct": 1,
			 "why": "|−x| = |x|：偶函數，對稱於 y 軸。",
			 "nudge": "a^{|−x|} 和 a^{|x|} 一樣嗎？", "tag": "abs_symmetry"},
			{"q": "這座光橋 y = a^{|x|}（a > 1）的最小值是？",
			 "options": ["0", "1", "a", "沒有最小值"], "correct": 1,
			 "why": "|x| ≥ 0、a > 1：a^{|x|} ≥ 1，x = 0 時最小。",
			 "nudge": "|x| 最小是多少？", "tag": "abs_symmetry"}],
		 "insight": "a^{|x|}：右半是 a^{x}，左半是鏡像。a > 1 時最低點 (0, 1)。",
		 "variants": [
			{"answer": {"a": 2.0}, "xs": [-2, 0, 2]},
			{"answer": {"a": 1.5}, "xs": [-2, 0, 2]},
			{"answer": {"a": 3.0}, "xs": [-2, 0, 2], "view": {"y": Vector2(-1.5, 10.5)}},
		 ]},

		{"id": "peak", "chapter": 2, "type": "fit", "title": "倒立的山", "form": "abs_in",
		 "params": ["a"], "live": true, "view": {"x": Vector2(-4, 4), "y": Vector2(-0.5, 2.5)},
		 "story": "這座山越往兩邊越低，最高的寶石在正中間。",
		 "predicts": [
			{"q": "這座山是 y = a^{|x|}（0 < a < 1）。它的最大值是？",
			 "options": ["沒有最大值", "1", "a", "1/a"], "correct": 1,
			 "why": "|x| ≥ 0、a < 1：a^{|x|} ≤ 1，最高點 (0, 1)。",
			 "nudge": "|x| 最小是 0。底數小於 1，指數越小值越大還是越小？", "tag": "exp_monotonic"},
			{"q": "這座山 y = a^{|x|}（0 < a < 1）的值域是？",
			 "options": ["y > 0", "0 < y ≤ 1", "y ≥ 1", "0 ≤ y ≤ 1"], "correct": 1,
			 "why": "最大值 1（x = 0）；兩側趨近 0 但不等於 0。",
			 "nudge": "最高點在哪？兩邊會碰到 0 嗎？", "tag": "abs_symmetry"}],
		 "insight": "0 < a < 1：最高點 (0, 1)，值域 0 < y ≤ 1。",
		 "variants": [
			{"answer": {"a": 0.5}, "xs": [-2, 0, 1]},
			{"answer": {"a": 0.25}, "xs": [-1, 0, 1]},
			{"answer": {"a": 0.4}, "xs": [-1, 0, 2]},
		 ]},

		{"id": "shift_mirror", "chapter": 2, "type": "fit", "title": "移動的鏡子", "form": "abs_in",
		 "params": ["a", "h"], "live": false,
		 "story": "鏡子被移動了！找出兩顆一樣高的寶石，鏡子就在它們正中間。",
		 "predicts": [],
		 "insight": "a^{|x − h|} 對稱於 x = h：= c 的兩根之和是 2h。",
		 "variants": [
			{"answer": {"a": 2.0, "h": 1.0}, "xs": [-1, 0, 1, 3],
			 "predicts": [_axis_pred("y = a^{|x − h|}", -1, 3, 4, 1)], "chain": [_sum_pred("y = a^{|x − h|}", 1)]},
			{"answer": {"a": 2.0, "h": -1.0}, "xs": [-3, -1, 0, 1],
			 "predicts": [_axis_pred("y = a^{|x − h|}", -3, 1, 4, -1)], "chain": [_sum_pred("y = a^{|x − h|}", -1)]},
			{"answer": {"a": 3.0, "h": 1.0}, "xs": [-1, 0, 1, 2], "view": {"y": Vector2(-1.5, 10.5)},
			 "predicts": [_axis_pred("y = a^{|x − h|}", 0, 2, 3, 1)], "chain": [_sum_pred("y = a^{|x − h|}", 1)]},
		 ]},

		{"id": "twins", "chapter": 2, "type": "fit", "title": "雙生光橋", "form": "abs_y",
		 "params": ["a"], "live": false,
		 "story": "光靈分裂成兩個！上下兩座光橋要同時接住寶石。",
		 "predicts": [
			{"q": "這座光橋是 |y| = a^{x}。它的圖形是？",
			 "options": ["只有 y = a^{x}", "y = a^{x} 與 y = −a^{x}", "y = a^{|x|}", "y = |a^{x}|"], "correct": 1,
			 "why": "|y| = a^{x} ⇔ y = ±a^{x}，對稱於 x 軸。",
			 "nudge": "|y| = 2 時，y 可以是多少？", "tag": "abs_relation"},
			{"q": "這座光橋 |y| = a^{x} 是不是一個函數的圖形？",
			 "options": ["是，每個 x 只對到一個 y", "不是，每個 x 對到兩個 y", "只有 x > 0 時是"], "correct": 1,
			 "why": "x = 0 時 y = ±1：一個 x 對兩個 y，不是函數。",
			 "nudge": "x = 0 時，|y| = 1 的 y 有幾個？", "tag": "abs_relation"}],
		 "insight": "|y| = f(x)：留 f(x) ≥ 0 的部分再對 x 軸翻一份；不是函數。",
		 "variants": [
			{"answer": {"a": 2.0}, "xs": [0, 2], "view": {"x": Vector2(-4, 3.5), "y": Vector2(-5, 5)}},
			{"answer": {"a": 3.0}, "xs": [0, 2], "view": {"x": Vector2(-4, 3), "y": Vector2(-9.5, 9.5)}},
			{"answer": {"a": 0.5}, "xs": [-2, 0], "view": {"x": Vector2(-3.5, 4), "y": Vector2(-5, 5)}},
		 ]},

		{"id": "bounce", "chapter": 2, "type": "fit", "title": "反彈之谷", "form": "abs_out",
		 "params": ["a", "k"], "live": false, "ranges": {"k": [-4.0, 2.0, 0.5]},
		 "story": "這座光橋碰到地面就會反彈。先找出它碰到 x 軸的位置！",
		 "predicts": [
			{"q": "y = |a^{x} + k|（k < 0）往漸近線那一側走，會越來越接近哪條水平線？",
			 "options": ["y = 0", "y = k", "y = |k|", "沒有漸近線"], "correct": 2,
			 "why": "a^{x} → 0 時 |a^{x} + k| → |k|：漸近線翻成 y = |k|。",
			 "nudge": "a^{x} 接近 0 時，|a^{x} + k| 接近多少？", "tag": "abs_reflect"},
			{"q": "這座光橋 y = |a^{x} + k| 碰到 x 軸的地方，滿足？",
			 "options": ["a^{x} + k = 0", "a^{x} = k", "x = k", "x = 0"], "correct": 0,
			 "why": "|a^{x} + k| = 0 ⇔ a^{x} + k = 0：從這點開始翻折。",
			 "nudge": "絕對值什麼時候等於 0？", "tag": "abs_reflect"}],
		 "insight": "|f(x)|：x 軸下方翻上來。|2^{x} − 2| = c：0 < c < 2 兩解。",
		 "variants": [
			{"answer": {"a": 2.0, "k": -2.0}, "xs": [-2, 0, 1, 2], "predicts": [_fold_pred("y = |a^{x} + k|", 0, 1)]},
			{"answer": {"a": 2.0, "k": -4.0}, "xs": [0, 1, 2, 3], "predicts": [_fold_pred("y = |a^{x} + k|", 1, 2)]},
			{"answer": {"a": 3.0, "k": -3.0}, "xs": [0, 1, 2], "predicts": [_fold_pred("y = |a^{x} + k|", 0, 2)]},
			{"answer": {"a": 0.5, "k": -2.0}, "xs": [-2, -1, 0, 1], "predicts": [_fold_pred("y = |a^{x} + k|", 0, 1)]},
		 ]},

		{"id": "sketch2", "chapter": 2, "type": "draw", "title": "徒手照鏡", "params": [], "tag": "draw_graph",
		 "story": "沒有滑桿！先想沒有絕對值的圖，再翻折畫出來。",
		 "insight": "包住 x：對 y 軸翻；包住整個式子：x 軸下方翻上來。",
		 "variants": [
			{"form": "abs_in", "answer": {"a": 2.0, "h": 0.0, "k": 0.0},
			 "keys": [Vector2(0, 1), Vector2(1, 2), Vector2(-1, 2), Vector2(2, 4), Vector2(-2, 4)]},
			{"form": "abs_out", "answer": {"a": 2.0, "h": 0.0, "k": -2.0},
			 "keys": [Vector2(1, 0), Vector2(0, 1), Vector2(2, 2)]},
			{"form": "abs_in", "answer": {"m": 2.0, "a": 0.5, "h": 0.0, "k": 0.0},
			 "keys": [Vector2(0, 2), Vector2(1, 1), Vector2(-1, 1), Vector2(2, 0.5), Vector2(-2, 0.5)],
			 "view": {"x": Vector2(-4, 4), "y": Vector2(-0.6, 3.2)}},
		 ]},

		{"id": "count", "chapter": 2, "type": "count", "title": "交點調頻",
		 "params": ["c"], "goals": [2, 1, 0],
		 "story": "方程式的解 = 圖形交點。移動水平線 y = c 完成任務。",
		 "insight": "f(x) = c 的解數 = 交點數；c 碰到頂點或漸近線時會跳動。",
		 "variants": [
			{"form": "abs_in", "fixed": {"a": 2.0},
			 "final": {"q": "方程式 2^{|x|} = c 恰有兩個實數解時，c 的範圍是？",
				"options": ["c > 0", "c ≥ 1", "c > 1", "0 < c < 1"], "correct": 2,
				"why": "最低點 (0, 1)：c > 1 兩解、c = 1 一解、c < 1 無解。",
				"nudge": "最低點在哪？水平線比它高、一樣高、比它低時各有幾個交點？", "tag": "solution_count"}},
			{"form": "abs_out", "fixed": {"a": 2.0, "k": -2.0},
			 "final": {"q": "方程式 |2^{x} − 2| = c 恰有兩個實數解時，c 的範圍是？",
				"options": ["c > 0", "0 < c < 2", "c ≥ 2", "c > 2"], "correct": 1,
				"why": "0 < c < 2 左右各交一次；c ≥ 2 只剩右邊。",
				"nudge": "雷射牆在 y = 2。水平線在它上面時，左半段還碰得到嗎？", "tag": "solution_count"}},
			{"form": "abs_in", "fixed": {"a": 0.5}, "view": {"x": Vector2(-4, 4), "y": Vector2(-0.5, 2.5)},
			 "ranges": {"c": [-0.4, 2.0, 0.1]},
			 "final": {"q": "方程式 (1/2)^{|x|} = c 恰有兩個實數解時，c 的範圍是？",
				"options": ["0 < c < 1", "c > 1", "c ≥ 1", "0 < c ≤ 1"], "correct": 0,
				"why": "最高點 (0, 1)：0 < c < 1 兩解，c = 1 一解。",
				"nudge": "這座山的最高點和漸近線各在哪？", "tag": "solution_count"}},
			{"form": "abs_in", "fixed": {"a": 2.0, "h": 1.0},
			 "final": {"q": "方程式 2^{|x − 1|} = c 有兩個解時，兩根之和是？",
				"options": ["0", "1", "2", "2c"], "correct": 2,
				"why": "兩交點對稱於 x = 1：兩根之和 = 2。",
				"nudge": "兩個交點對稱於哪條直線？", "tag": "abs_symmetry"}},
		 ]},

		{"id": "cross2", "chapter": 2, "type": "cross", "title": "鏡中交點",
		 "params": ["s"],
		 "story": "畫出兩個圖形再數交點：數一半再乘 2。",
		 "variants": [
			{"lhs": "2^{|x|}", "rhs": "x^{2}", "exp": {"form": "abs_in", "a": 2.0}, "quad": [1.0, 0.0, 0.0], "n": 4,
			 "view": {"x": Vector2(-5.0, 5.0), "y": Vector2(-1.5, 17.5)},
			 "nudge": "兩者都對稱於 y 軸：先數 x > 0 的交點。",
			 "why": "x > 0：x = 2、4。左右對稱，共 4 個。",
			 "insight": "偶函數：x > 0 的交點 × 2（x = 0 另外檢查）。"},
			{"lhs": "(1/2)^{|x|}", "rhs": "x^{2} − 1", "exp": {"form": "abs_in", "a": 0.5}, "quad": [1.0, 0.0, -1.0], "n": 2,
			 "view": {"y": Vector2(-1.5, 7.0)},
			 "nudge": "(1/2)^{|x|} 往外變小，x^{2} − 1 往外變大。",
			 "why": "x > 0 只交一次，左右對稱共 2 個。",
			 "insight": "一條遞減、一條遞增，最多只交一次。這是判斷交點數最快的方法。"},
			{"lhs": "3^{|x|}", "rhs": "x^{2}", "exp": {"form": "abs_in", "a": 3.0}, "quad": [1.0, 0.0, 0.0], "n": 0,
			 "view": {"y": Vector2(-1.5, 12.0)},
			 "nudge": "3^{|x|} ≥ 1。|x| < 1 時 x^{2} < 1；|x| ≥ 1 呢？",
			 "why": "3^{|x|} 永遠在 x^{2} 上方，一個交點也沒有。",
			 "insight": "比較兩函數的最大、最小值，常能直接判斷。"},
			{"lhs": "2^{|x|}", "rhs": "5 − x^{2}", "exp": {"form": "abs_in", "a": 2.0}, "quad": [-1.0, 0.0, 5.0], "n": 2,
			 "view": {"y": Vector2(-5.0, 10.0)},
			 "nudge": "x > 0：一個遞增、一個遞減，交幾次？",
			 "why": "一增一減只交一次；左右對稱，共 2 個。",
			 "insight": "對稱 + 單調性：先算一半，再乘以 2。"},
		 ]},

		{"id": "boss2", "chapter": 2, "type": "fit", "title": "鏡之試煉", "form": "abs_in",
		 "params": ["a", "h", "k"], "live": false, "time": 130.0,
		 "story": "限時 130 秒！三個參數全開。先用一樣高的寶石找出對稱軸。",
		 "predicts": [
			{"q": "y = a^{|x − h|} + k 的圖形以哪條直線為對稱軸？",
			 "options": ["x = 0", "x = h", "y = k", "x = −h"], "correct": 1,
			 "why": "對稱軸是 x = h：一樣高的兩顆寶石，中點就在對稱軸上。",
			 "nudge": "a^{|x|} + k 對稱於 x = 0，右移 h 之後呢？", "tag": "abs_symmetry"},
			{"q": "y = a^{|x − h|} + k 在對稱軸上的點是？",
			 "options": ["(h, k)", "(h, 1 + k)", "(0, 1)", "(h, 1)"], "correct": 1,
			 "why": "x = h 時 y = 1 + k：最低點（a > 1）或最高點（a < 1）。",
			 "nudge": "x = h 時，a^{|x − h|} 等於多少？", "tag": "abs_symmetry"}],
		 "insight": "等高兩點的中點是對稱軸；(h, 1 + k) 是最高或最低點。",
		 "variants": [
			{"answer": {"a": 2.0, "h": -1.0, "k": -1.0}, "xs": [-3, -1, 0, 1]},
			{"answer": {"a": 3.0, "h": 0.0, "k": -2.0}, "xs": [-1, 0, 1, 2], "view": {"y": Vector2(-2.5, 8.5)}},
			{"answer": {"a": 2.0, "h": 1.0, "k": -2.0}, "xs": [-1, 0, 1, 2, 3]},
		 ]},
	]
