extends Node
## QuizManager（請在 專案設定 → Autoload 加入，名稱 QuizManager）
## 負責：讀題庫、批改、依「錯誤類型」記錄錯題本、推薦回練關卡、存檔。

const QUESTION_FILE := "res://data/questions_exp_log.json"
const SAVE_FILE := "user://progress.json"

## 錯誤類型 → 說明與回練關卡
const MISTAKE_INFO := {
	"exp_monotonic":   {"name": "底數與遞增遞減判斷", "level": 1},
	"exp_fixed_point": {"name": "恆過點（0,1）/（1,0）", "level": 1},
	"symmetry":        {"name": "對稱關係（y 軸 / x 軸 / y = x）", "level": 2},
	"concavity":       {"name": "凹口方向比大小", "level": 2},
	"asymptote_shift": {"name": "平移後的漸近線", "level": 3},
	"domain_log":      {"name": "對數定義域", "level": 3},
	"compare_split":   {"name": "比大小：0 與 1 分界", "level": 4},
	"compare_base":    {"name": "比大小：換底 / 化同底", "level": 4},
	"intersect_miss":  {"name": "交點個數漏算", "level": 5},
	"ineq_flip":       {"name": "底數小於 1 不等號未變號", "level": 1},
	"abs_symmetry":    {"name": "指數絕對值圖形的對稱軸", "level": 1},
	"abs_reflect":     {"name": "|f(x)| 的翻折與漸近線", "level": 1},
	"abs_relation":    {"name": "|y| = f(x) 的圖形（不是函數）", "level": 1},
	"exp_base_compare": {"name": "由圖形判斷底數大小", "level": 1},
	"quadrant":        {"name": "指數圖形通過的象限", "level": 1},
	"exp_shift_coef":  {"name": "係數化為平移（如 4·2^x = 2^(x+2)）", "level": 1},
	"exp_ratio":       {"name": "比值與倍率（同樣間隔乘同一個數）", "level": 1},
	"solution_count":  {"name": "解的個數（圖形交點）", "level": 1},
	"exp_quad_cross":  {"name": "指數與二次函數的交點個數", "level": 1},
	"log_fixed_point": {"name": "對數的恆過點 (1, 0) 與平移後的 (1 + h, k)", "level": 5},
	"log_domain":      {"name": "對數的定義域（真數 > 0）", "level": 5},
	"log_monotonic":   {"name": "對數底數與遞增遞減", "level": 5},
	"log_symmetry":    {"name": "log_a x 與 log_(1/a) x 對稱於 x 軸", "level": 5},
	"log_base_compare": {"name": "由圖形判斷對數底數大小", "level": 5},
	"log_asymptote":   {"name": "對數的鉛直漸近線 x = h", "level": 5},
	"log_shift_coef":  {"name": "真數係數化為平移（log(4x) = log x + 2）", "level": 5},
	"inverse_symmetry": {"name": "對 y = x 對稱（反函數、坐標交換）", "level": 5},
	"log_abs":         {"name": "log|x| 與 |log x| 的對稱與翻折", "level": 5},
	"log_exp_cross":   {"name": "指數、對數與其他圖形的交點個數", "level": 5},
	"draw_graph":      {"name": "徒手畫出函數圖形", "level": 1},
	"exp_compare":     {"name": "指數比大小（化同底、同次方）", "level": 3},
	"exp_ineq":        {"name": "指數不等式（化同底）", "level": 3},
	"exp_ineq_flip":   {"name": "底數小於 1 時不等號變向", "level": 3},
	"exp_ineq_calc":   {"name": "指數不等式的計算", "level": 3},
	"exp_ineq_line":   {"name": "不等式的解畫在數線上（端點包含與否）", "level": 3},
	"exp_ineq_sign":   {"name": "乘積不等式的符號判斷", "level": 3},
	"exp_ineq_base":   {"name": "底數含未知數時分情況討論", "level": 3},
	"exp_extreme":     {"name": "換元求極值（t 的範圍、頂點與端點）", "level": 3},
	"exp_amgm":        {"name": "算幾不等式求最小值", "level": 3},
	"loglaw_def":      {"name": "對數的定義（a^x = N ⇔ x = log_a N）", "level": 4},
	"loglaw_valid":    {"name": "對數有意義的條件（底數 > 0、≠ 1，真數 > 0）", "level": 4},
	"loglaw_law":      {"name": "對數律：相加相乘、相減相除、係數變次方", "level": 4},
	"loglaw_power":    {"name": "次方處理 log_(a^m) b^n = (n/m) log_a b", "level": 4},
	"loglaw_base":     {"name": "換底公式", "level": 4},
	"loglaw_recip":    {"name": "倒數公式 log_a b · log_b a = 1", "level": 4},
	"loglaw_chain":    {"name": "連鎖公式 log_a b · log_b c = log_a c", "level": 4},
	"loglaw_swap":     {"name": "底數與真數互換 a^(log b) = b^(log a)", "level": 4},
	"loglaw_sub":      {"name": "代換問題（以代號表示對數）", "level": 4},
	"loglaw_convert":  {"name": "指數式與對數式互換", "level": 4},
	"loglaw_root":     {"name": "根式求值（雙重根號、√(k²) = |k|）", "level": 4},
	"loglaw_apply":    {"name": "對數的應用（地震、分貝、酸鹼值）", "level": 4},
	"logeq_same":      {"name": "對數方程式：同底比較、改寫成指數式", "level": 6},
	"logeq_base":      {"name": "對數方程式：化同底（log_(a²) M = ½ log_a M）", "level": 6},
	"logeq_calc":      {"name": "對數方程式的計算（整理、解根）", "level": 6},
	"logeq_check":     {"name": "代回檢查：真數 > 0、底數 > 0 且 ≠ 1", "level": 6},
	"logeq_sub":       {"name": "對數方程式的換元（t = log x、t = a^x）", "level": 6},
	"logeq_recip":     {"name": "倒數換元（log_x a = 1/log_a x）", "level": 6},
	"logeq_power":     {"name": "次方上有 log：取對數、互換", "level": 6},
	"logeq_vieta":     {"name": "對數方程式的根與係數", "level": 6},
	"logineq_sign":    {"name": "log_a b 的正負判斷", "level": 7},
	"logineq_compare": {"name": "對數比大小（和 0、1 比，同底、同真數）", "level": 7},
	"logineq_flip":    {"name": "底數 < 1 時不等號變向", "level": 7},
	"logineq_domain":  {"name": "對數不等式的真數條件", "level": 7},
	"logineq_calc":    {"name": "對數不等式的計算", "level": 7},
	"logineq_line":    {"name": "對數不等式的解畫在數線上", "level": 7},
	"logineq_sub":     {"name": "對數不等式的換元與符號表", "level": 7},
	"logineq_extreme": {"name": "對數函數的極值（t 的範圍、配方、取對數）", "level": 7},
	"logineq_amgm":    {"name": "算幾不等式與 log 的極值", "level": 7},
	"digits_char":     {"name": "首數：科學記號、位數、小數點後第幾位", "level": 8},
	"digits_mant":     {"name": "尾數：決定最高位（第一個不為 0）的數字", "level": 8},
	"digits_calc":     {"name": "首數尾數的計算（查表、取 log）", "level": 8},
	"digits_compare":  {"name": "取 log 比大小", "level": 8},
	"digits_apply":    {"name": "指數成長與衰退的應用（倍增、半衰期、複利、星等）", "level": 8},
	"exp_eq_base":     {"name": "化同底（把數字寫成底數的次方）", "level": 2},
	"exp_eq_sub":      {"name": "指數方程式的換元", "level": 2},
	"exp_eq_calc":     {"name": "換元後的計算（列式、解 t、換回 x）", "level": 2},
	"exp_eq_positive": {"name": "t = a^x > 0 的檢查", "level": 2},
	"exp_eq_condition": {"name": "成立條件（a^x + a^(−x) ≥ 2）", "level": 2},
	"exp_eq_factor":   {"name": "分組分解", "level": 2},
	"exp_eq_param":    {"name": "含參數的指數方程式（根的範圍）", "level": 2},
	# ---- 三角函數 ----
	"trig_rad_conv":   {"name": "度與弧度的換算（π = 180°）", "level": 1},
	"trig_angle_draw": {"name": "有向角：逆時針為正、順時針為負、超過一圈", "level": 1},
	"trig_coterminal": {"name": "同界角（最小正、最大負）", "level": 1},
	"trig_quadrant":   {"name": "終邊在哪個象限（弧度扣掉整圈再比）", "level": 1},
	"trig_special":    {"name": "特殊角的三角函數值（參考角）", "level": 1},
	"trig_sign":       {"name": "三角函數在各象限的正負", "level": 1},
	"trig_reduce":     {"name": "奇變偶不變（誘導公式化簡）", "level": 1},
	"trig_compare":    {"name": "三角函數值比大小", "level": 1},
	"trig_sector_formula":   {"name": "扇形的弧長與面積（l = rθ、A = ½r²θ）", "level": 1},
	"trig_sector_perimeter": {"name": "已知扇形周長與面積求半徑、圓心角（θ ≤ 2π）", "level": 1},
	"trig_sector_max":       {"name": "周長固定時扇形的最大面積", "level": 1},
	"trig_sector_clock":     {"name": "時鐘問題（指針的轉速與夾角）", "level": 1},
	"trig_sector_roll":      {"name": "滾動與捆繩（弧長 = 滾過的距離）", "level": 1},
	"trig_sector_segment":   {"name": "弓形面積（扇形 − 三角形）", "level": 1},
	"trig_sector_cone":      {"name": "扇形與圓錐（弧長 = 底圓周長、最短路徑）", "level": 1},
	"trig_graph_shape":      {"name": "sin、cos、tan 的圖形（值域、零點、漸近線）", "level": 1},
	"trig_period":           {"name": "三角函數的週期（2π/|b|、π/|b|）", "level": 1},
	"trig_period_combo":     {"name": "週期組合（絕對值、平方、相加取最小公倍數）", "level": 1},
	"trig_graph_prop":       {"name": "圖形性質（最大最小、對稱軸、遞增遞減）", "level": 1},
	"trig_graph_judge":      {"name": "圖形的真假判斷", "level": 1},
	"trig_amp":              {"name": "振幅與上下平移（|a|、d、最大最小值）", "level": 1},
	"trig_freq":             {"name": "水平伸縮與週期（b、2π/|b|）", "level": 1},
	"trig_shift":            {"name": "左右平移量（−c/b：先提出 x 的係數）", "level": 1},
	"trig_order":            {"name": "先伸縮再平移（y = a sin(bx + c) + d 的做法）", "level": 1},
	"trig_read":             {"name": "看圖求 a、b、c、d", "level": 1},
	"trig_apply":            {"name": "潮汐與摩天輪的應用題", "level": 1},
	"trig_solve":            {"name": "作圖求解（解的個數與範圍）", "level": 1},
	"trig_cosdiff":          {"name": "差角公式的推導（單位圓兩點、餘弦定理）", "level": 1},
	"trig_sumf":             {"name": "sin、cos 的和差角公式（特殊角 15°、75°、105°）", "level": 1},
	"trig_tansum":           {"name": "tan 的和差角公式（分母 1 ∓ tan α tan β）", "level": 1},
	"trig_merge":            {"name": "公式合併（倒著用和差角公式求值）", "level": 1},
	"trig_quadsign":         {"name": "象限判斷正負後求值（再代入和差角公式）", "level": 1},
	"trig_findangle":        {"name": "由 tan 求角的和差（再看角的範圍）", "level": 1},
	"trig_tri":              {"name": "三角形內角和與 tan 的根與係數", "level": 1},
	"trig_lineangle":        {"name": "兩直線的夾角（tan θ = |(m₂ − m₁) ÷ (1 + m₁m₂)|）", "level": 1},
	"trig_geoapp":           {"name": "圖形與座標上的和角應用", "level": 1},
	"trig_sumjudge":         {"name": "和角公式的真假判斷", "level": 1},
	"trig_double":           {"name": "二倍角公式（sin 2θ、cos 2θ、tan 2θ 與鏡面反射）", "level": 1},
	"trig_cos2form":         {"name": "cos 2θ 的三種寫法（只知道 cos 或只知道 sin）", "level": 1},
	"trig_dblvalue":         {"name": "由象限與一個函數值求二倍角的值", "level": 1},
	"trig_dblmerge":         {"name": "二倍角公式合併（2 sin cos、cos² − sin²、降冪）", "level": 1},
	"trig_half":             {"name": "半角公式（sin²、cos²、tan 的 θ/2）", "level": 1},
	"trig_halfquad":         {"name": "半角的象限與正負號（θ/2 的範圍）", "level": 1},
	"trig_sqrtsimp":         {"name": "根號化簡（1 ± sin 2θ 是完全平方、去絕對值）", "level": 1},
	"trig_tanrep":           {"name": "以切表弦（t = tan θ 求 sin 2θ、cos 2θ）", "level": 1},
	"trig_product":          {"name": "連乘積（乘 sin 後反覆二倍角）", "level": 1},
	"trig_dblextreme":       {"name": "含 cos 2θ 的最大最小值（換成二次函數）", "level": 1},
	"trig_dbljudge":         {"name": "倍角與半角公式的真假判斷", "level": 1},
	"trig_lightmax":         {"name": "a sin x + b cos x 的最大值與最小值（±√(a² + b²)）", "level": 1},
	"trig_mergeform":        {"name": "疊合公式（r = √(a² + b²)、cos φ = a/r、sin φ = b/r）", "level": 1},
	"trig_expandform":       {"name": "r sin(x + φ) 的展開與合成（和角公式的來回）", "level": 1},
	"trig_phase":            {"name": "疊合角 φ 的象限（由 (a, b) 的位置決定）", "level": 1},
	"trig_peak":             {"name": "疊合後的最大最小值、零點與週期", "level": 1},
	"trig_brightcmp":        {"name": "比較疊合後的振幅（比 a² + b²）", "level": 1},
	"trig_peakrange":        {"name": "限制範圍下的最大最小值（x + φ 的範圍、端點）", "level": 1},
	"trig_nonspecial":       {"name": "非特殊角的疊合（用 cos φ、sin φ 的分數表示）", "level": 1},
	"trig_homog":            {"name": "齊次型的疊合（倍角、降冪後疊合）", "level": 1},
	"trig_param":            {"name": "參數型（k = sin x ± cos x，換成二次函數）", "level": 1},
	"trig_combo":            {"name": "兩個平移過的正餘弦相加（先展開再疊合）", "level": 1},
	"trig_lightapply":       {"name": "疊合的應用題（周長、長度的最大值）", "level": 1},
	"trig_lightjudge":       {"name": "疊合公式的真假判斷", "level": 1},
}

var questions: Array = []
var mistake_book := {}   # tag -> 次數
var wrong_ids := {}      # 題目 id -> true（錯題本清單）


func _ready() -> void:
	_load_questions()
	_load_progress()


func _load_questions() -> void:
	var file := FileAccess.open(QUESTION_FILE, FileAccess.READ)
	if file == null:
		push_warning("找不到題庫：%s" % QUESTION_FILE)
		return
	var data = JSON.parse_string(file.get_as_text())
	if data is Array:
		questions = data


func get_questions_for_level(level: int, layer: String = "") -> Array:
	return questions.filter(func(q): return q.level == level and (layer == "" or q.layer == layer))


## 批改。chosen = 學生選的選項索引陣列（單選也用陣列）
## 回傳 { correct: bool, tags: Array[String], explain: String }
func grade(q: Dictionary, chosen_raw: Array) -> Dictionary:
	# JSON 讀進來的數字是 float，統一轉成 int 再比較
	var answer: Array = q.answer.map(func(v): return int(v))
	var chosen: Array = chosen_raw.map(func(v): return int(v))
	var correct := chosen.size() == answer.size()
	if correct:
		for c in chosen:
			if not answer.has(c):
				correct = false
				break

	var tags: Array[String] = []
	if not correct:
		# 選了錯誤選項 → 對應的迷思
		for c in chosen:
			var t = q.get("distractor_tags", {}).get(str(c))
			if t and not tags.has(t):
				tags.append(t)
		# 漏選正確選項 → 對應的迷思（多選題）
		for c in answer:
			if not chosen.has(c):
				var t = q.get("miss_tags", {}).get(str(c))
				if t and not tags.has(t):
					tags.append(t)
		for t in tags:
			record_mistake(t)
		wrong_ids[q.id] = true
	else:
		wrong_ids.erase(q.id)  # 錯題重做答對，從錯題本移除
	_save_progress()
	return {"correct": correct, "tags": tags, "explain": q.get("explain", "")}


func record_mistake(tag: String) -> void:
	mistake_book[tag] = mistake_book.get(tag, 0) + 1
	_save_progress()


## 回傳最弱的 n 個錯誤類型，用於「段考前弱點回練」
func weakest(n: int = 3) -> Array:
	var keys := mistake_book.keys()
	keys.sort_custom(func(a, b): return mistake_book[a] > mistake_book[b])
	var out := []
	for k in keys.slice(0, n):
		var info: Dictionary = MISTAKE_INFO.get(k, {"name": k, "level": 1})
		out.append({"tag": k, "name": info.name, "level": info.level, "count": mistake_book[k]})
	return out


func _save_progress() -> void:
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"mistake_book": mistake_book, "wrong_ids": wrong_ids.keys()}))


func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	var data = JSON.parse_string(FileAccess.open(SAVE_FILE, FileAccess.READ).get_as_text())
	if data is Dictionary:
		mistake_book = data.get("mistake_book", {})
		for id in data.get("wrong_ids", []):
			wrong_ids[id] = true
