extends "res://data/levels/line/line_level.gd"
## 數與式 R1～R8 共用的關卡底層。引擎是 line_level.gd（推導＋坐標方格、滑桿），這裡再加：
##   ・推導紀錄下方的「原野」（num_field.gd）：題目有 "field" 就畫風車、數線柵欄（繩子、珠子、跑者、地圖）、質因數積木
##   ・速算可以混用填空和按鈕：題目有 choices 就是大按鈕（數學排版），沒有就用數字鍵盤
##   ・背景：黎明的麥田（data/ui/scenery.gd 的 "meadow"）
## 每一關只要寫 level_id、標題、章節、題庫、速算的題目產生器。

const NumField := preload("res://data/levels/num/num_field.gd")


func scene_theme() -> String:
	return "meadow"

func stage_style() -> Dictionary:
	return {"sky_top": Color("1d1a33"), "sky_bot": Color("0c0b18"), "scenery": "none", "ambient": ""}

## 數與式的填空大多用不到根號鍵（要根號的格子，根號會寫在式子裡）
func radicals_ok() -> bool:
	return false


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



# ================= 速算：填空或按鈕 =================

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



static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return absi(a)


static func _square(n: int) -> bool:
	var r := int(round(sqrt(float(n))))
	return r * r == n


static func _fr(n: int, d: int) -> String:
	return "\\frac{%d}{%d}" % [n, d]


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

