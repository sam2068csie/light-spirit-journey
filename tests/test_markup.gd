extends "test_base.gd"
## 排版檢查：所有會畫在畫面上的數學文字，根號、分數、上標有沒有寫對
##   掃描範圍：每個單元每一關的題庫（含速算產生器產生的題目）、觀念卡、章節卡、各張地圖的劇情、
##            還有所有腳本裡的字串常數（只檢查看起來有數學排版的字串）
##   每段文字交給 MathLabel.lint() 檢查（規則寫在 math_text.gd）：
##     大括號成對、\frac{分子}{分母}、^ 後面接 {…}、根號自動補完後都有 {…}（才畫得出橫線）、沒有多跳脫的 \\
##   另外：篩選按鈕的候選值（cands）是一般文字，不能有 {、\、^ 這些排版符號
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
	ok(problems == 0, "排版有 %d 個問題（見上面的 MARKUP 行）" % problems)
	finish("MARKUP")


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
		if not (s.contains("√") or s.contains("\\frac") or s.contains("^") or s.contains("{") or s.contains("∛")):
			return
		if s.begins_with("res://") or s.contains("%s") or s.contains("%d"):
			return       # 檔案路徑、格式字串（之後才填數字）不檢查
		for p in MathLabel.lint(s):
			_report(where, s, p)


func _report(where: String, s: String, p: String) -> void:
	var key := s + p
	if seen.has(key):
		return
	seen[key] = true
	problems += 1
	print("MARKUP %s：%s ⇐ 「%s」" % [where, p, s.left(90)])
