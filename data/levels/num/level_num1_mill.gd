extends "res://data/levels/line/line_level.gd"
## 數與式 第一大關「風車小數」（對應講義重點一：數線）。設計稿：docs/num_r1_design.md
## 引擎是 line_level.gd（推導＋坐標方格、滑桿），題庫在 num1_bank.gd。
##   ・第一章：稠密性、循環小數化分數（純循環、混循環、0.\ol{9}）、夾範圍、分數化循環小數、有限小數、第 n 位、相加、速算
##   ・第二章：尺規作圖（比例、√ab）、分數比大小、加權平均、根號比大小、四捨五入、不等式的性質、正負號、速算
##   ・推導紀錄下方的「原野」（num_field.gd）：風車、數線柵欄、質因數積木。尺規作圖用坐標方格。
##   ・背景：黎明的麥田（data/ui/scenery.gd 的 "meadow"）
## 速算：mill（循環小數化分數、有限或循環）、cmp（兩個數點大的那一個）

const BankR1 := preload("res://data/levels/num/num1_bank.gd")
const NumField := preload("res://data/levels/num/num_field.gd")
const MILL := UITheme.GOLD

const CHAPTERS_R1 := [
	{"ch": 1, "name": "第一章．轉動的風車", "topic": "循環小數和分數互換、有限小數、第 n 位", "color": UITheme.GOLD},
	{"ch": 2, "name": "第二章．柵欄上的天秤", "topic": "尺規作圖、分數和根號比大小、不等式的性質", "color": UITheme.CYAN},
]


func level_id() -> String:
	return "R1"

func level_title() -> String:
	return "風車小數"

func level_subtitle() -> String:
	return "數線、循環小數與比大小"

func level_chapters() -> Array:
	return CHAPTERS_R1

func bank_slots() -> Array:
	return BankR1.slots()

func step_color() -> Color:
	return MILL

func scene_theme() -> String:
	return "meadow"

func stage_style() -> Dictionary:
	return {"sky_top": Color("1d1a33"), "sky_bot": Color("0c0b18"), "scenery": "none", "ambient": ""}

## 這一關的填空用不到根號鍵（√6 那一題的根號已經寫在式子裡）
func radicals_ok() -> bool:
	return false

func chapter_card() -> Dictionary:
	return {"title": "第二章．柵欄上的天秤", "button": "比比看  ▶",
		"text": "風車都轉起來了，接下來到數線柵欄上比大小：\n\n" \
			+ "・用平行線和半圓，在數線上畫出點和 √ab\n" \
			+ "・分數、根號誰比較大\n" \
			+ "・四捨五入之前是多少\n" \
			+ "・不等式能怎麼加、怎麼乘\n\n" \
			+ "出發吧！"}


func _ensure_fview() -> void:
	if fview == null:
		var v := NumView.new()
		v.theme_name = scene_theme()
		fview = v
		stage.add_child(fview)
		fview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fview.clip_contents = true
		fview.log_title = "推導紀錄"
		fview.work_word = "推導"
		fview.speed_title = "速算"


# ================= 速算 =================

func _speed_tag() -> String:
	return BankR1.T_REP if String(r.get("gen", "")) == "mill" else BankR1.T_CMP


func _speed_gen(kind: String, n: int) -> Array:
	return gen_problems(kind, n)


## 有 choices 的題目用大按鈕（數學排版），其他用數字鍵盤
func _speed_show() -> void:
	var pb: Dictionary = problems[sp_i]
	fview.speed_title = String(r.get("title", "速算"))
	fview.show_speed(pb.eq, sp_i, problems.size(), streak)
	step_label.text = UITheme.step_bar(_steps(), 0)
	if sp_i > 0:
		story_label.visible = false
	if not pb.has("choices"):
		_build_fill({"name": "速算", "q": pb.q, "template": pb.template, "answers": pb.answers, "mode": "ordered",
			"nudge": pb.nudge, "tag": pb.tag, "line": "", "paren": true})
		return
	keypad_on = false
	rank_box.visible = true
	_clear(rank_box)
	task_label.visible = true
	task_label.text = pb.q
	var row := GridContainer.new()
	row.columns = 2
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 10)
	rank_box.add_child(row)
	for i in pb.choices.size():
		var b := MathLabel.make_button(String(pb.choices[i]), 22, Vector2(0, 72))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		var idx: int = i
		b.pressed.connect(func(): _speed_pick(idx))
		row.add_child(b)


func _speed_pick(i: int) -> void:
	if busy or r.get("type", "") != "speed" or sp_i >= problems.size():
		return
	var pb: Dictionary = problems[sp_i]
	if i == int(pb.correct):
		Game.of(self).sfx("correct")
		_speed_correct()
		return
	Game.of(self).sfx("wrong")
	_record(String(pb.get("tag", _speed_tag())))
	streak = 0
	sp_wrong += 1
	time_left = maxf(1.0, time_left - 5.0)
	fview.miss()
	_hint("不對喔，再想一次！（−5 秒）\n" + String(pb.nudge), "bad")
	_update_hud()


## 分母只有 2、5（約分後）的分數 → 有限小數；其他 → 循環小數
const FIN_DEN := [4, 8, 16, 20, 25, 40, 50, 80, 125]
const LOOP_DEN := [3, 6, 7, 9, 11, 12, 15, 18, 21, 22, 30, 33]


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return absi(a)


static func _finite(num: int, den: int) -> bool:
	var d := den / _gcd(num, den)
	for p in [2, 5]:
		while d % p == 0:
			d /= p
	return d == 1


static func _square(n: int) -> bool:
	var r := int(round(sqrt(float(n))))
	return r * r == n


static func _fr(n: int, d: int) -> String:
	return "\\frac{%d}{%d}" % [n, d]


## 速算題：mill（循環小數化分數、有限或循環）、cmp（比大小，兩顆按鈕）
##   填空：{eq, q, template, answers, nudge, tag}　按鈕：{eq, q, choices, correct, nudge, tag}
static func gen_problems(kind: String, n: int) -> Array:
	var out := []
	var seen := {}
	var guard := 0
	while out.size() < n and guard < 4000:
		guard += 1
		var pb := {}
		if kind == "mill":
			if out.size() % 2 == 0:
				# 純循環小數 → 分數（一位或兩位的循環節）
				var two := randf() < 0.6
				var dg := randi_range(10, 98) if two else randi_range(1, 8)
				if two and (dg % 11 == 0):
					continue      # 0.\ol{33} 這種其實是一位的循環節
				var den := 99 if two else 9
				var g := _gcd(dg, den)
				var s := ("%02d" % dg) if two else str(dg)
				pb = {"eq": "0.\\ol{%s} = ？" % s, "q": "寫成分數（不用約分也可以）。", "template": "0.\\ol{%s} = [0]" % s,
					"answers": ["%d/%d" % [dg / g, den / g]], "tag": BankR1.T_REP,
					"nudge": "循環節 %d 位：0.\\ol{%s} = \\frac{%d}{%d}。" % [s.length(), s, dg, den]}
				if s.begins_with("0"):
					continue
			else:
				var fin := randf() < 0.5
				var den: int = FIN_DEN[randi() % FIN_DEN.size()] if fin else LOOP_DEN[randi() % LOOP_DEN.size()]
				var k := randi_range(1, 3)
				var num := randi_range(1, den - 1)
				if _gcd(num, den) == 1 and k > 1:
					# 偶爾放一個沒約分的（例如 \frac{21}{56}），要先約分才看得出來
					num *= k
					den *= k
				if num >= den:
					continue
				var ok := _finite(num, den)
				pb = {"eq": "%s\n化成小數是？" % _fr(num, den), "q": "先約分，再看分母的質因數。", "choices": ["有限小數", "循環小數"],
					"correct": 0 if ok else 1, "tag": BankR1.T_FIN,
					"nudge": "約分後的分母只有 2、5 ⇒ 有限小數，有別的質因數 ⇒ 循環小數。"}
		else:
			var kind2 := randi() % 3
			var a := 0.0
			var b := 0.0
			var sa := ""
			var sb := ""
			var why := ""
			match kind2:
				0:   # 分子分母很接近的分數
					var d1 := randi_range(7, 30)
					var d2 := d1 + randi_range(3, 20)
					var gap := randi_range(1, 4)
					a = float(d1 - gap) / d1
					b = float(d2 - gap) / d2
					sa = _fr(d1 - gap, d1)
					sb = _fr(d2 - gap, d2)
					why = "比離 1 差多少：\\frac{%d}{%d} 和 \\frac{%d}{%d}，分子一樣，分母大的差比較少。" % [gap, d1, gap, d2]
				1:   # 根號相加，裡面的和一樣
					var tot := randi_range(10, 20)
					var p := randi_range(2, tot / 2 - 1)
					var q := randi_range(2, tot / 2 - 1)
					if p == q or _square(p) or _square(q) or _square(tot - p) or _square(tot - q):
						continue      # 不要 √1、√9 這種其實是整數的
					a = sqrt(float(p)) + sqrt(float(tot - p))
					b = sqrt(float(q)) + sqrt(float(tot - q))
					sa = "√%d + √%d" % [tot - p, p]
					sb = "√%d + √%d" % [tot - q, q]
					why = "平方：%d + 2√%d 和 %d + 2√%d，比 √ 裡面就好。" % [tot, p * (tot - p), tot, q * (tot - q)]
				2:   # 根號相減，差一樣
					var dd := randi_range(1, 3)
					var p2 := randi_range(2, 12)
					var q2 := randi_range(2, 12)
					if p2 == q2 or _square(p2) or _square(q2) or _square(p2 + dd) or _square(q2 + dd):
						continue
					a = sqrt(float(p2 + dd)) - sqrt(float(p2))
					b = sqrt(float(q2 + dd)) - sqrt(float(q2))
					sa = "√%d − √%d" % [p2 + dd, p2]
					sb = "√%d − √%d" % [q2 + dd, q2]
					why = "有理化：分子都是 %d，分母（兩個根號相加）大的反而小。" % dd
			if absf(a - b) < 1e-6:
				continue
			if randf() < 0.5:
				var tmp := a
				a = b
				b = tmp
				var ts := sa
				sa = sb
				sb = ts
			pb = {"eq": "%s　和　%s\n哪一個比較大？" % [sa, sb], "q": "點比較大的那一個。", "choices": [sa, sb],
				"correct": 0 if a > b else 1, "tag": BankR1.T_CMP, "nudge": why}
		var key := String(pb.eq)
		if seen.has(key):
			continue
		seen[key] = true
		out.append(pb)
	return out


# ================= 推導台：坐標方格＋原野 =================

class NumView extends PlaneView:
	var field: Control

	func setup(round: Dictionary) -> void:
		super(round)
		var fd: Array = round.get("field", [])
		if field == null:
			field = NumField.new()
			add_child(field)
		field.reset(fd, self)
		field.visible = not fd.is_empty() and kind == "forge"
		_place_plane()

	func _field_on() -> bool:
		return field != null and field.visible

	func _place_plane() -> void:
		super()
		if field != null:
			var rc := _plane_rect()
			field.position = rc.position
			field.size = rc.size

	func _plane_on() -> bool:
		return super() or _field_on()

	func _process(delta: float) -> void:
		super(delta)
		if _field_on() and (field.size != _plane_rect().size or field.position != _plane_rect().position):
			_place_plane()
