extends "test_base.gd"
## 排版檢查：所有會畫在畫面上的數學文字，根號、分數、上標有沒有寫對
##   掃描範圍：每個單元每一關的題庫（含速算產生器產生的題目）、觀念卡、章節卡、各張地圖的劇情、
##            還有所有腳本裡的字串常數（只檢查看起來有數學排版的字串）
##   每段文字交給 MathLabel.lint() 檢查（規則寫在 math_text.gd）：
##     大括號成對、\frac{分子}{分母}、^ 後面接 {…}、根號自動補完後都有 {…}（才畫得出橫線）、沒有多跳脫的 \\
##   另外：篩選按鈕的候選值（cands）是一般文字，不能有 {、\、^ 這些排版符號
##   標點：玩家看得到的文字不能有「；」和 ÷（也掃舊的 JSON 題庫）
## 新增題目或卡片之後跑這個測試：GODOT=… tests/run_tests.sh markup

const Units := preload("res://data/core/units.gd")
const Paths := preload("res://data/core/paths.gd")
const MathLabel := preload("res://data/ui/math_text.gd")
const Cards := preload("res://data/ui/concept_cards.gd")

const SKIP_KEYS := ["id", "tag", "type", "gen", "file", "bank", "answers", "keep", "ans", "map", "tower", "concepts", "glyph"]
var problems := 0
var seen := {}


func _initialize() -> void:
	await setup()
	for u in Units.UNITS:
		for l in u.levels:
			var lid := String(l.id)
			_scan(l, "%s 關卡資訊" % lid)
			if String(l.get("bank", "")) != "":
				var bank = load(Paths.of(String(l.bank)))
				var slots: Array = bank.slots()
				for slot in slots:
					var where := "%s/%s" % [lid, slot.id]
					_scan(slot, where)
					if slot.type == "speed":
						_scan_speed(l, bank, slot, where)
			_scan(Cards.cards(lid), "%s 觀念卡" % lid)
			if String(l.get("file", "")) != "":
				var scr: Script = load(Paths.of(String(l.file)))
				var lv = scr.new()
				_scan(lv.chapter_card(), "%s 章節卡" % lid)
				_scan(lv.level_chapters(), "%s 章節" % lid)
				lv.free()
	# 所有腳本的字串常數（劇情、地圖名稱、提示…）
	for f in Paths.MAP:
		var scr2 = load(Paths.MAP[f])
		if scr2 is Script:
			var cm: Dictionary = scr2.get_script_constant_map()
			for k in cm:
				if cm[k] is Dictionary or cm[k] is Array or cm[k] is String:
					_scan(cm[k], "%s 的 %s" % [f, k])
	# 舊的選擇題題庫（JSON）：只檢查標點
	var jf := FileAccess.open("res://data/questions_exp_log.json", FileAccess.READ)
	if jf != null:
		_punct_all(JSON.parse_string(jf.get_as_text()), "questions_exp_log.json")
	ok(problems == 0, "排版有 %d 個問題（見上面的 MARKUP 行）" % problems)
	_check_overline()
	finish("MARKUP")


## 循環小數、線段的上橫線（\ol{…}）不能在前面多佔位置：1.2\ol{36} 要和 1.236 一樣寬
## （以前 \ol 被當成三次方根，左邊多留了根指數的空隙，畫出來變成「1.2 ‾36」）
func _check_overline() -> void:
	var f := ThemeDB.fallback_font
	for pair in [["1.2\\ol{36}", "1.236"], ["0.\\ol{142857}", "0.142857"], ["\\ol{AB}", "AB"]]:
		var w1 := MathLabel.text_width(f, pair[0], 20)
		var w2 := MathLabel.text_width(f, pair[1], 20)
		ok(absf(w1 - w2) < 0.5, "上橫線前面多了空隙：%s 寬 %.1f，%s 寬 %.1f" % [pair[0], w1, pair[1], w2])


## 速算：題目是程式產生的，多產生幾批來檢查
func _scan_speed(l: Dictionary, bank, slot: Dictionary, where: String) -> void:
	var gen := String(slot.variants[0].get("gen", ""))
	var srcs := [bank]
	if String(l.get("file", "")) != "":
		srcs.append(load(Paths.of(String(l.file))))
	for src in srcs:
		var names: Array = (src as Script).get_script_method_list().map(func(m): return m.name)
		if names.has("gen_problems"):
			for rep in 4:
				_scan(src.gen_problems(gen, 10), where + " 速算")
			return


func _scan(v, where: String, key := "") -> void:
	if v is Dictionary:
		for k in v:
			if str(k) in SKIP_KEYS:
				continue
			_scan(v[k], where, str(k))
	elif v is Array:
		for e in v:
			_scan(e, where, key)
	elif v is String:
		var s: String = v
		_punct(s, where)
		if not (s.contains("√") or s.contains("\\frac") or s.contains("^") or s.contains("{") or s.contains("∛")):
			return
		if s.begins_with("res://") or s.contains("%s") or s.contains("%d"):
			return       # 檔案路徑、格式字串（之後才填數字）不檢查
		for p in MathLabel.lint(s):
			_report(where, s, p)


## 玩家看得到的文字不用「；」、不用 ÷（docs/design_rules.md 第 3 節）
##   例外：math_text.gd 的斷行標點表、拼公式的 ÷ 積木（會自動變成分數模式，畫面上看不到）
func _punct(s: String, where: String) -> void:
	if where.begins_with("math_text.gd") or s == "÷" or s == "；":
		return
	if s.contains("；"):
		_report(where, s, "玩家看得到的文字不用「；」（改成逗號、句號或拆成兩句）")
	if s.contains("÷"):
		_report(where, s, "不用 ÷（寫成分數）")
	# 直線與圓（C1～C8）：距離寫 d(P, L)、d(L₁, L₂)，不單獨寫 d
	if where.begins_with("C") and _bare_d().search(s) != null:
		_report(where, s, "距離要寫成 d(P, L)、d(L₁, L₂) 或「弦心距」，不單獨寫 d")


var _bare_d_re: RegEx

func _bare_d() -> RegEx:
	if _bare_d_re == null:
		_bare_d_re = RegEx.new()
		_bare_d_re.compile("(?<![A-Za-z0-9\\\\_{%])d(?![A-Za-z(_])")
	return _bare_d_re


func _punct_all(v, where: String) -> void:
	if v is Dictionary:
		for k in v:
			_punct_all(v[k], where)
	elif v is Array:
		for e in v:
			_punct_all(e, where)
	elif v is String:
		_punct(v, where)


func _report(where: String, s: String, p: String) -> void:
	var key := s + p
	if seen.has(key):
		return
	seen[key] = true
	problems += 1
	print("MARKUP %s：%s ⇐ 「%s」" % [where, p, s.left(90)])
