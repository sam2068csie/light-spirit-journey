extends Control
## 高二的「選擇單元」世界地圖：光潮群島。划光舟在海上自由航行，一個單元一座島。
##   ・七座島沿著順時針航道排列，浮標編號就是課本的章節順序（單元之間不上鎖）
##   ・靠近碼頭跳出靠岸卡片，「上岸」進入原本的單元地圖（聖地照順序解鎖、劇情照舊）
##   ・從單元地圖按返回，回到這裡，光舟停在那座島的碼頭旁
##   ・海上藏了彩蛋（沉船、漩渦）
## 存檔：Game.world11 {pos: [x, y], visited: [], eggs: [], ret: 上岸時記下的單元（回來時播離島動畫）}
const UITheme := preload("game_theme.gd")
const Game := preload("game.gd")
const Units := preload("units.gd")
const Center := preload("review_center.gd")
const SL := preload("spirit_look.gd")
const TM := preload("trig_map.gd")     # 月輪島：照單元地圖的形狀縮小畫（圓環＋正弦海岸＋羅盤礁）
const WM := preload("world_map.gd")
const EM := preload("exp_map.gd")     # 指數島、對數島（幾何版）    # 指數島、對數島：照單元地圖的海岸線縮小畫

signal pick_unit(uid: String)

const W := 1152.0
const H := 648.0
const WORLD := Vector2(3600, 2200)
const SEA_C := Vector2(1850, 1120)
const SPEED := 360.0
const R_BOAT := 26.0

## 七座島（章節順序）：unit 對應 units.gd 的單元 id
const ISLANDS := [
	{"n": 1, "unit": "trig", "name": "月輪島", "c": Vector2(760, 450), "r": Vector2(500, 270), "col": Color("ff9ad5"), "land": Color("2c3f6e")},
	{"n": 2, "unit": "exp", "name": "指數對數雙島", "c": Vector2(1930, 380), "r": Vector2(420, 230), "col": Color("f5c84c"), "land": Color("3e3466")},
	{"n": 3, "unit": "vec2", "name": "箭羽高原", "c": Vector2(3040, 430), "r": Vector2(400, 230), "col": Color("5fd4ff"), "land": Color("24456a")},
	{"n": 4, "unit": "vec3", "name": "立方浮島", "c": Vector2(3130, 1130), "r": Vector2(340, 200), "col": Color("c59bff"), "land": Color("34306a")},
	{"n": 5, "unit": "plane", "name": "平面峽灣", "c": Vector2(2980, 1830), "r": Vector2(420, 220), "col": Color("6ee7a0"), "land": Color("1f4a48")},
	{"n": 6, "unit": "prob", "name": "機率樹海", "c": Vector2(1930, 1860), "r": Vector2(420, 210), "col": Color("ffb35a"), "land": Color("3a3a2a")},
	{"n": 7, "unit": "matrix", "name": "矩陣城", "c": Vector2(720, 1770), "r": Vector2(370, 220), "col": Color("8fb4ff"), "land": Color("2a3460")},
]
const HARBOR := Vector2(150, 1100)       # 晨曦港（左邊的小岬角）
const SPAWN := Vector2(380, 1100)
const WRECK := Vector2(1150, 1250)       # 彩蛋：沉船
const WHIRL := Vector2(2600, 1250)       # 彩蛋：漩渦

var pos := SPAWN
var vel := Vector2.ZERO
var heading := 0.0
var cam := Vector2.ZERO
var zoom := 1.0
var t := 0.0
var playing := false
var _hold := false
var _hold_pt := Vector2.ZERO
var _polys: Array = []
var _shape: Array = []        # 有單元地圖的島：縮小後的真實形狀 {kind, k, off, …}
var _docks: Array = []
var _wake: Array = []
var _sparks: Array = []
var _near := {}
var _overlay: Control
var _card: PanelContainer
var _card_no: Label
var _card_title: Label
var _card_sub: Label
var _card_bar: ProgressBar
var _card_btn: Button
var _toast: Label
var _toast_t := 0.0
var _fade: ColorRect
var _busy := false
var _tp: Button
var _zoom_hold := 0.0     # 離島動畫（zoom 1.7 → 1）播放中，先不要自動縮放
var _whirl_spin := 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 1111
	for isl in ISLANDS:
		var poly := PackedVector2Array()
		for k in 48:
			var a := TAU * k / 48.0
			var wob := 1.0 + 0.07 * sin(a * 3.0 + isl.n) + 0.04 * sin(a * 7.0 + isl.n * 2.0)
			poly.append(isl.c + Vector2(cos(a) * isl.r.x, sin(a) * isl.r.y) * wob)
		_polys.append(poly)
		_shape.append(_make_shape(isl))
	# 碼頭：從島中心往海中央走，第一個船能停的地方再往外一點
	for i in ISLANDS.size():
		var isl: Dictionary = ISLANDS[i]
		var dir: Vector2 = (SEA_C - isl.c).normalized()
		var q: Vector2 = isl.c
		var hit := false      # 先碰到陸地（月輪島中間是潟湖），再找到外面的海
		for k in 500:
			q += dir * 8.0
			var fr := _free_island(q, i, 30.0)
			if not fr:
				hit = true
			elif hit:
				break
		_docks.append(q + dir * 30.0)
	for i in 40:
		_sparks.append({"p": Vector2(rng.randf() * W, rng.randf() * H), "ph": rng.randf() * TAU, "s": rng.randf_range(0.6, 1.4)})
	_build_ui()
	var st := _state()
	var sp = st.get("pos", [])
	if sp is Array and sp.size() == 2:
		var p0 := Vector2(float(sp[0]), float(sp[1]))
		if _free(p0):
			pos = p0
	# 從單元地圖回來：光舟停在那座島的碼頭旁，播離島動畫
	var ret := String(st.get("ret", ""))
	if ret != "":
		for i in ISLANDS.size():
			if ISLANDS[i].unit == ret:
				pos = _docks[i]
				heading = (_docks[i] - ISLANDS[i].c).angle()
		st["ret"] = ""
		cam = _cam_target()
		zoom = 1.7
		_fade.color.a = 1.0
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "zoom", 1.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_fade, "color:a", 0.0, 0.6)
		_zoom_hold = 0.8
		vel = Vector2.from_angle(heading) * 160.0
	cam = _cam_target()
	_refresh_goal()
	_story_check.call_deferred()


func _state() -> Dictionary:
	var g = Game.of(self)
	for k in ["visited", "eggs"]:
		if not g.world11.has(k):
			g.world11[k] = []
	return g.world11


func _has(key: String, id: String) -> bool:
	return (_state()[key] as Array).has(id)


func _add(key: String, id: String) -> void:
	if not _has(key, id):
		(_state()[key] as Array).append(id)
		_save()


func _save() -> void:
	_state()["pos"] = [roundi(pos.x), roundi(pos.y)]
	Game.of(self).save_review()


func refresh() -> void:
	queue_redraw()


func on_shown() -> void:
	queue_redraw()


func close_overlay() -> bool:
	if is_instance_valid(_overlay) and not _overlay.is_queued_for_deletion():
		_overlay.queue_free()
		_overlay = null
		return true
	return false


func _exit_tree() -> void:
	_save()


# ================= 介面 =================

func _build_ui() -> void:
	var tp := Button.new()
	_tp = tp
	tp.text = "☰ 單元列表（M）"
	tp.focus_mode = Control.FOCUS_NONE
	tp.custom_minimum_size = Vector2(160, 44)
	tp.position = Vector2(16, 70)
	UITheme.button_3d(tp, Color("1f4a6e"), Color("12304a"), Color("c8f0ff"), 16, 4, 14, 4)
	tp.pressed.connect(_open_sail_menu)
	add_child(tp)
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(560, 0)
	_card.visible = false
	add_child(_card)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	_card.add_child(hb)
	_card_no = Label.new()
	_card_no.custom_minimum_size = Vector2(48, 48)
	_card_no.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_no.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card_no.add_theme_font_override("font", UITheme.bold_font())
	_card_no.add_theme_font_size_override("font_size", UITheme.fs(22))
	_card_no.add_theme_color_override("font_color", Color("2a2440"))
	_card_no.add_theme_stylebox_override("normal", UITheme.box(UITheme.ACCENT, 24, Color(0, 0, 0, 0), 0, 0))
	hb.add_child(_card_no)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 3)
	hb.add_child(vb)
	_card_title = Label.new()
	_card_title.add_theme_font_override("font", UITheme.bold_font())
	_card_title.add_theme_font_size_override("font_size", UITheme.fs(22))
	vb.add_child(_card_title)
	_card_sub = Label.new()
	_card_sub.add_theme_font_size_override("font_size", UITheme.fs(14))
	_card_sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	vb.add_child(_card_sub)
	_card_bar = ProgressBar.new()
	_card_bar.show_percentage = false
	_card_bar.max_value = 100
	_card_bar.custom_minimum_size = Vector2(0, 7)
	_card_bar.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.1), 4, Color(0, 0, 0, 0), 0, 0))
	vb.add_child(_card_bar)
	_card_btn = Button.new()
	_card_btn.focus_mode = Control.FOCUS_NONE
	_card_btn.custom_minimum_size = Vector2(120, 50)
	UITheme.accent_button(_card_btn, 17)
	_card_btn.pressed.connect(_interact)
	hb.add_child(_card_btn)
	var tip := Label.new()
	tip.text = "方向鍵／WASD 划船，或按住畫面往那裡划　·　Enter 上岸　·　M 單元列表"
	tip.position = Vector2(18, H - 34)
	tip.add_theme_font_size_override("font_size", UITheme.fs(13))
	tip.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tip)
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(0, 124)
	_toast.size = Vector2(W, 40)
	_toast.add_theme_font_override("font", UITheme.bold_font())
	_toast.add_theme_font_size_override("font_size", UITheme.fs(20))
	_toast.add_theme_color_override("font_color", Color("ffe7a3"))
	_toast.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.12))
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	add_child(_toast)
	# 上岸／離島的轉場：黑幕
	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.04, 0.1, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _show_toast(s: String) -> void:
	_toast.text = s
	_toast_t = 2.6


func _progress(uid: String) -> Dictionary:
	var u: Dictionary = Units.unit(uid)
	var lit := 0
	var prog := 0.0
	var nxt := ""
	var g = Game.of(self)
	for l in u.levels:
		var pr: float = Center.level_progress(g, l.id)
		prog += pr
		if pr >= 0.999:
			lit += 1
		elif nxt == "":
			nxt = l.name
	return {"lit": lit, "n": u.levels.size(), "p": prog / maxf(1.0, u.levels.size()), "next": nxt}


func _open(i: int) -> bool:
	var u: Dictionary = Units.unit(ISLANDS[i].unit)
	return u.id == ISLANDS[i].unit and Units.is_open(u)


func _update_card() -> void:
	var k := String(_near.get("kind", ""))
	_card.visible = k != "" and not is_instance_valid(_overlay) and not _busy and not playing
	if not _card.visible:
		return
	match k:
		"dock":
			var i: int = _near.i
			var isl: Dictionary = ISLANDS[i]
			var u: Dictionary = Units.unit(isl.unit)
			var col: Color = isl.col
			_card.add_theme_stylebox_override("panel", UITheme.box(Color(0.06, 0.08, 0.18, 0.95), 16, col, 2, 14))
			_card_no.text = str(isl.n)
			_card_no.visible = true
			_card_title.text = "%s　%s" % [isl.name, u.title if u.id == isl.unit else ""]
			_card_title.add_theme_color_override("font_color", col.lightened(0.35))
			if _open(i):
				var pr := _progress(isl.unit)
				_card_sub.text = "世界之光 %d／%d%s" % [pr.lit, pr.n, ("　·　下一站：" + pr.next) if pr.next != "" else "　·　全部點亮！"]
				_card_bar.visible = true
				_card_bar.value = pr.p * 100.0
				_card_bar.add_theme_stylebox_override("fill", UITheme.box(col, 4, Color(0, 0, 0, 0), 0, 0))
				_card_btn.text = "上岸 ▶"
				_card_btn.disabled = false
			else:
				_card_sub.text = "島上還籠罩在霧裡（建造中）"
				_card_bar.visible = false
				_card_btn.text = "還不能上岸"
				_card_btn.disabled = true
		"wreck", "whirl":
			_card.add_theme_stylebox_override("panel", UITheme.box(Color(0.06, 0.08, 0.18, 0.95), 16, Color("ff9ad5"), 2, 14))
			_card_no.visible = false
			_card_title.text = "沉船殘骸" if k == "wreck" else "海上的漩渦"
			_card_title.add_theme_color_override("font_color", Color("ffd6ec"))
			var done := _has("eggs", k)
			_card_sub.text = ("船艙裡有一本泡水的航海日誌……" if k == "wreck" else "光舟被捲著轉了一圈……") if not done else "已經解開了"
			_card_bar.visible = false
			_card_btn.text = "調查"
			_card_btn.disabled = false
		"harbor":
			_card.add_theme_stylebox_override("panel", UITheme.box(Color(0.06, 0.08, 0.18, 0.95), 16, UITheme.ACCENT, 2, 14))
			_card_no.visible = false
			_card_title.text = "晨曦港"
			_card_title.add_theme_color_override("font_color", Color("ffe7a3"))
			_card_sub.text = "從這裡搭船回高一的曦光大陸"
			_card_bar.visible = false
			_card_btn.text = "回高一"
			_card_btn.disabled = false
	_card.reset_size()
	_card.position = Vector2((W - _card.size.x) / 2.0, H - _card.size.y - 48.0)


func _interact() -> void:
	var k := String(_near.get("kind", ""))
	if k == "" or is_instance_valid(_overlay) or _busy:
		return
	match k:
		"dock":
			if _open(int(_near.i)):
				_land(int(_near.i))
		"wreck":
			_open_egg("wreck")
		"whirl":
			_open_egg("whirl")
		"harbor":
			var mm := get_parent()
			while mm != null and not mm.has_method("_set_grade"):
				mm = mm.get_parent()
			if mm != null:
				mm._set_grade("高一")


## 上岸：鏡頭往碼頭推進、畫面變暗，然後進入單元地圖
func _land(i: int) -> void:
	_busy = true
	Game.of(self).sfx("success")
	var uid: String = ISLANDS[i].unit
	_state()["ret"] = uid
	_save()
	var target: Vector2 = ISLANDS[i].c
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "zoom", 1.8, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "pos", pos.lerp(target, 0.25), 0.55)
	tw.tween_property(_fade, "color:a", 1.0, 0.5).set_delay(0.08)
	await tw.finished
	pick_unit.emit(uid)


## 單元列表：不想划船，直接選一座島上岸
func _open_sail_menu() -> void:
	if is_instance_valid(_overlay) or _busy:
		return
	Game.of(self).sfx("click")
	var o := UITheme.modal(self, UITheme.ACCENT, 560)
	_overlay = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 8)
	col.add_child(UITheme.title_label("☰ 單元列表", 26, UITheme.ACCENT))
	for i in ISLANDS.size():
		var isl: Dictionary = ISLANDS[i]
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		col.add_child(hb)
		var nm := Label.new()
		nm.text = "%d　%s" % [isl.n, Units.unit(isl.unit).title]
		nm.custom_minimum_size = Vector2(250, 0)
		nm.add_theme_font_override("font", UITheme.bold_font())
		nm.add_theme_font_size_override("font_size", UITheme.fs(16))
		var ok := _open(i)
		nm.add_theme_color_override("font_color", (isl.col as Color).lightened(0.3) if ok else UITheme.TEXT_DIM)
		hb.add_child(nm)
		var sb := Label.new()
		sb.text = isl.name
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.add_theme_font_size_override("font_size", UITheme.fs(14))
		sb.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		hb.add_child(sb)
		var go := Button.new()
		go.focus_mode = Control.FOCUS_NONE
		go.custom_minimum_size = Vector2(110, 38)
		go.text = "上岸 ▶" if ok else "建造中"
		go.disabled = not ok
		UITheme.button_3d(go, Color("2a6f9e"), Color("17405e"), Color("e6f7ff"), 14, 4, 12, 3)
		var ii: int = i
		go.pressed.connect(func():
			close_overlay()
			pos = _docks[ii]
			vel = Vector2.ZERO
			cam = _cam_target()
			_land(ii))
		hb.add_child(go)
	var cb := Button.new()
	cb.text = "關閉"
	cb.focus_mode = Control.FOCUS_NONE
	cb.custom_minimum_size = Vector2(0, 46)
	UITheme.accent_button(cb, 17)
	cb.pressed.connect(func(): close_overlay())
	col.add_child(cb)


## 海上的彩蛋：沉船（對數）與漩渦（弧度）
func _open_egg(id: String) -> void:
	var title := "沉船殘骸" if id == "wreck" else "海上的漩渦"
	var q := "航海日誌最後一頁寫著：\nlog₂ 8 + log₂ 4 = ？" if id == "wreck" else "光舟被漩渦捲著轉了整整一圈。\n轉了幾弧度？"
	var opts := ["5", "6", "12", "32"] if id == "wreck" else ["π", "2π", "360", "π/2"]
	var ans := "5" if id == "wreck" else "2π"
	var why := "log₂ 8 = 3、log₂ 4 = 2，合起來是 5。" if id == "wreck" else "一整圈是 360°，也就是 2π 弧度。"
	var gain := 30 if id == "wreck" else 20
	var o := UITheme.modal(self, Color("ff9ad5"), 480)
	_overlay = o[0]
	var col: VBoxContainer = o[1]
	col.add_child(UITheme.title_label(title, 26, Color("ff9ad5")))
	var l := Label.new()
	l.text = q
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", UITheme.fs(18))
	l.add_theme_color_override("font_color", UITheme.TEXT)
	col.add_child(l)
	var msg := Label.new()
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", UITheme.fs(15))
	msg.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	if _has("eggs", id):
		msg.text = "答案是 %s：%s" % [ans, why]
	else:
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 10)
		col.add_child(grid)
		for v in opts:
			var b := Button.new()
			b.text = v
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(96, 48)
			UITheme.button_3d(b, Color("3a3360"), Color("231e40"), UITheme.TEXT, 18, 4, 12, 3)
			var vv: String = v
			b.pressed.connect(func():
				if vv == ans:
					_add("eggs", id)
					Game.of(self).inv["dust"] = int(Game.of(self).inv.get("dust", 0)) + gain
					Game.of(self).sfx("success")
					close_overlay()
					_show_toast("答對了！獲得 星塵 ×%d" % gain)
				else:
					Game.of(self).sfx("wrong")
					msg.text = "好像不對……再想想？")
			grid.add_child(b)
	col.add_child(msg)
	var cb := Button.new()
	cb.text = "離開"
	cb.focus_mode = Control.FOCUS_NONE
	cb.custom_minimum_size = Vector2(0, 46)
	UITheme.accent_button(cb, 17)
	cb.pressed.connect(func(): close_overlay())
	col.add_child(cb)


# ================= 輸入、移動 =================

func _gui_input(e: InputEvent) -> void:
	if playing:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_hold = e.pressed
		_hold_pt = e.position
	elif e is InputEventMouseMotion and _hold:
		_hold_pt = e.position


func _unhandled_input(e: InputEvent) -> void:
	if playing:
		return
	if not is_visible_in_tree() or is_instance_valid(_overlay) or _busy:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_interact()
				get_viewport().set_input_as_handled()
			KEY_M, KEY_TAB:
				_open_sail_menu()
				get_viewport().set_input_as_handled()


func _key_dir() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		d.x -= 1
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		d.x += 1
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
		d.y -= 1
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
		d.y += 1
	return d.normalized()


## 船能不能在這裡：在海上（不在任何島或港口上），也不能出地圖
func _free(p: Vector2) -> bool:
	if p.x < 60.0 or p.y < 60.0 or p.x > WORLD.x - 60.0 or p.y > WORLD.y - 60.0:
		return false
	if p.distance_to(HARBOR) < 150.0 + R_BOAT:
		return false
	for i in _polys.size():
		if not _free_island(p, i, R_BOAT):
			return false
	return true


## 這一點離第 i 座島夠不夠遠（m：船身的寬度）
func _free_island(p: Vector2, i: int, m: float) -> bool:
	var isl: Dictionary = ISLANDS[i]
	var sh: Dictionary = _shape[i]
	match String(sh.get("kind", "")):
		"trig":
			if absf(p.distance_to(sh.o) - sh.r) < sh.rw / 2.0 + m:
				return false
			if p.distance_to(sh.cp) < sh.dr + m:
				return false
			var wv: PackedVector2Array = sh.wave
			for k in range(0, wv.size() - 1, 2):
				if Geometry2D.get_closest_point_to_segment(p, wv[k], wv[mini(k + 2, wv.size() - 1)]).distance_to(p) < sh.cw / 2.0 + m:
					return false
			return true
		"exp":
			for poly in sh.polys:
				if Geometry2D.is_point_in_polygon(p, poly):
					return false
				var pp: PackedVector2Array = poly
				for k in range(0, pp.size(), 3):
					if pp[k].distance_to(p) < m + 6.0:
						return false
			return true
	var d: Vector2 = (p - isl.c)
	var e := Vector2(d.x / (isl.r.x * 1.1 + m), d.y / (isl.r.y * 1.1 + m))
	return e.length() >= 1.0


## 有單元地圖的島：把單元地圖（1152×648 的座標）縮放、搬到這座島的位置
func _make_shape(isl: Dictionary) -> Dictionary:
	match String(isl.unit):
		"trig":
			var lo := Vector2(TM.O.x - TM.R - TM.RW, TM.WY - TM.R - TM.RW)
			var hi := Vector2(TM.X_END, TM.WY + TM.R + TM.RW)
			var k: float = minf(2.0 * isl.r.x / (hi.x - lo.x), 2.0 * isl.r.y / (hi.y - lo.y)) * 1.15
			var mid := (lo + hi) / 2.0
			var tf := func(q: Vector2) -> Vector2: return isl.c + (q - mid) * k
			var wave := PackedVector2Array()
			for q in TM.wave_pts(TM.WX0, TM.X_END, 10.0):
				wave.append(tf.call(q))
			var sites := []
			for j in TM.SITES.size():
				sites.append(tf.call(TM.site_point(j)))
			return {"kind": "trig", "k": k, "o": tf.call(TM.O), "r": TM.R * k, "rw": TM.RW * k, "wave": wave,
				"cw": TM.CW * k, "cp": tf.call(TM.CP), "dr": TM.DR * k, "sites": sites}
		"exp":
			var obs := PackedVector2Array()      # 天文台小島（位數望遠鏡）
			for j in 24:
				obs.append(EM.OBS_C + Vector2.from_angle(TAU * j / 24.0) * EM.OBS_R)
			var polys := [EM.island_poly(0), EM.island_poly(1), obs]
			var lo := Vector2(INF, INF)
			var hi := Vector2(-INF, -INF)
			for poly in polys:
				for q in poly:
					lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
					hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
			var k: float = minf(2.0 * isl.r.x / (hi.x - lo.x), 2.0 * isl.r.y / (hi.y - lo.y)) * 1.2
			var mid := (lo + hi) / 2.0
			var out := []
			for poly in polys:
				var pp := PackedVector2Array()
				for q in poly:
					pp.append(isl.c + (q - mid) * k)
				out.append(pp)
			var sites := []
			for j in 8:
				sites.append(isl.c + (EM.site_point(j) - mid) * k)
			return {"kind": "exp", "k": k, "polys": out, "sites": sites}
	return {}


## 一座島真正的範圍（月輪島、雙島照實際形狀算），外面多留一點海
func _island_box(i: int) -> Rect2:
	var isl: Dictionary = ISLANDS[i]
	var sh: Dictionary = _shape[i]
	var box := Rect2(isl.c - isl.r, isl.r * 2.0)
	match String(sh.get("kind", "")):
		"trig":
			var rr: float = sh.r + sh.rw
			box = Rect2(sh.o - Vector2(rr, rr), Vector2(rr, rr) * 2.0)
			for q in sh.wave:
				box = box.expand(q)
			box = box.merge(Rect2(sh.cp - Vector2(sh.dr, sh.dr), Vector2(sh.dr, sh.dr) * 2.0))
		"exp":
			box = Rect2(sh.polys[0][0], Vector2.ZERO)
			for poly in sh.polys:
				for q in poly:
					box = box.expand(q)
	return box.grow(50.0)


## 靠近碼頭（跳出卡片）時：整座島和光舟都要入鏡 → 回傳 [中心, 縮放]；沒有就回傳 []
func _dock_view() -> Array:
	if String(_near.get("kind", "")) != "dock" or story_focus.x >= 0.0:
		return []
	var box := _island_box(int(_near.i)).expand(pos + Vector2(60, 60)).expand(pos - Vector2(60, 60))
	# 上面留給橫幅、按鈕，下面留給卡片
	var z := minf((W - 80.0) / box.size.x, (H - 260.0) / box.size.y)
	return [box.get_center() + Vector2(0, 30.0 / z), clampf(z, 0.35, 1.0)]


func _cam_target() -> Vector2:
	var dv := _dock_view()
	if not dv.is_empty():
		return dv[0] - Vector2(W, H) / 2.0
	var c := (story_focus if story_focus.x >= 0.0 else pos) - Vector2(W, H) / 2.0
	return Vector2(clampf(c.x, 0.0, WORLD.x - W), clampf(c.y, 0.0, WORLD.y - H))


func _process(delta: float) -> void:
	t += delta
	_zoom_hold -= delta
	var active := is_visible_in_tree() and not is_instance_valid(_overlay) and not _busy and not playing
	_goal_t -= delta
	if _goal_t <= 0.0:
		_goal_t = 1.0
		_refresh_goal()
	var dir := _key_dir() if active else Vector2.ZERO
	if dir == Vector2.ZERO and _hold and active:
		var to := (_hold_pt - Vector2(W, H) / 2.0) / zoom + Vector2(W, H) / 2.0 + cam - pos
		if to.length() > 14.0:
			dir = to.normalized()
	# 有一點慣性的划船
	vel = vel.lerp(dir * SPEED, 1.0 - exp(-(3.0 if dir != Vector2.ZERO else 1.6) * delta))
	if _whirl_spin > 0.0:
		_whirl_spin -= delta
		vel = vel.rotated(delta * 5.0)
	if vel.length() > 8.0 and not _busy:
		heading = lerp_angle(heading, vel.angle(), 1.0 - exp(-6.0 * delta))
		var step := vel * delta
		if _free(pos + step):
			pos += step
		elif _free(pos + Vector2(step.x, 0)):
			pos += Vector2(step.x, 0)
			vel.y = 0.0
		elif _free(pos + Vector2(0, step.y)):
			pos += Vector2(0, step.y)
			vel.x = 0.0
		else:
			vel *= 0.3
		if randf() < vel.length() / SPEED:
			var back := Vector2.from_angle(heading + PI)
			_wake.append({"p": pos + back * 24.0 + Vector2(randf_range(-6, 6), randf_range(-6, 6)), "life": 0.0})
	for w in _wake:
		w.life += delta
	_wake = _wake.filter(func(w): return w.life < 1.4)
	if not _busy:
		cam = cam.lerp(_cam_target(), 1.0 - exp(-6.0 * delta))
		# 鏡頭縮放：靠近碼頭時拉遠到看得到整座島，離開就慢慢回到 1
		if not _busy and _zoom_hold <= 0.0:
			var dv := _dock_view()
			var zt: float = dv[1] if not dv.is_empty() else 1.0
			zoom = lerpf(zoom, zt, 1.0 - exp(-4.0 * delta))
	_check_world()
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)
	_update_card()
	queue_redraw()


func _check_world() -> void:
	_near = {}
	for i in ISLANDS.size():
		var isl: Dictionary = ISLANDS[i]
		if pos.distance_to(_docks[i]) < 110.0:
			_near = {"kind": "dock", "i": i}
			if not _has("visited", isl.unit):
				_add("visited", isl.unit)
				_show_toast("發現 %d 號島：%s" % [isl.n, isl.name])
	if pos.distance_to(WRECK) < 130.0:
		_near = {"kind": "wreck"}
	if pos.distance_to(WHIRL) < 120.0:
		_near = {"kind": "whirl"}
		if _whirl_spin <= 0.0 and not _has("eggs", "whirl") and vel.length() > 60.0:
			_whirl_spin = 1.2
	if pos.distance_to(HARBOR) < 300.0:
		_near = {"kind": "harbor"}


# ================= 畫圖 =================

func _to_screen_xf() -> void:
	var C := Vector2(W, H) / 2.0
	draw_set_transform(C - (cam + C) * zoom, 0.0, Vector2(zoom, zoom))


func _draw() -> void:
	var font := UITheme.bold_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b2050"))
	_to_screen_xf()
	var view := Rect2(cam - Vector2(200, 200), Vector2(W, H) / zoom + Vector2(400, 400))
	# 海浪紋
	var y := floorf(view.position.y / 110.0) * 110.0
	while y < view.end.y:
		var x := floorf(view.position.x / 180.0) * 180.0 + fmod(y, 360.0) * 0.5
		while x < view.end.x:
			var off := sin(t * 1.1 + x * 0.01 + y * 0.02) * 8.0
			draw_arc(Vector2(x + off, y), 20.0, PI * 1.1, PI * 1.9, 8, Color(0.45, 0.62, 0.95, 0.22), 2.0, true)
			x += 180.0
		y += 110.0
	# 航道：碼頭依章節順序連起來，浮標寫編號
	var route := [SPAWN]
	for d in _docks:
		route.append(d)
	for i in route.size() - 1:
		var a: Vector2 = route[i]
		var b: Vector2 = route[i + 1]
		var n := int(a.distance_to(b) / 48.0)
		for k in n:
			UITheme.dot(self, a.lerp(b, (k + 0.5) / maxf(1.0, n)), 5.0, Color(0.96, 0.78, 0.3, 0.35))
	# 晨曦港
	UITheme.dot(self, HARBOR, 150.0, Color("2c2646"))
	draw_arc(HARBOR, 150.0, 0, TAU, 48, Color("6b5a8e"), 4.0, true)
	draw_rect(Rect2(HARBOR + Vector2(110, -14), Vector2(110, 28)), Color("8a6a3e"))
	draw_string(font, HARBOR + Vector2(-70, -20), "晨曦港", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("ffe7a3"))
	draw_string(font, HARBOR + Vector2(-64, 24), "← 高一 · 曦光大陸", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("c9d1f0"))
	# 島
	for i in ISLANDS.size():
		_draw_island(font, i)
	# 彩蛋
	var wr := WRECK
	draw_colored_polygon(PackedVector2Array([wr + Vector2(-60, 0), wr + Vector2(60, 0), wr + Vector2(40, 26), wr + Vector2(-40, 26)]), Color("5a4030"))
	draw_line(wr + Vector2(-6, 0), wr + Vector2(-26, -70), Color("6b4f2e"), 6.0, true)
	draw_colored_polygon(PackedVector2Array([wr + Vector2(-24, -66), wr + Vector2(14, -40), wr + Vector2(-18, -30)]), Color(0.85, 0.82, 0.75, 0.7))
	for k in 4:
		var rr := 30.0 + k * 22.0
		draw_arc(WHIRL, rr, t * (2.0 - k * 0.3), t * (2.0 - k * 0.3) + 4.4, 24, Color(0.75, 0.88, 1.0, 0.35 - k * 0.06), 3.0, true)
	# 船跡
	for w in _wake:
		var a: float = 1.0 - w.life / 1.4
		draw_arc(w.p, 6.0 + 18.0 * (1.0 - a), 0, TAU, 16, Color(0.85, 0.95, 1.0, 0.35 * a), 2.0, true)
	_draw_boat()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for s in _sparks:
		UITheme.dot(self, s.p, 1.6, Color(1, 0.95, 0.8, 0.12 + 0.12 * sin(t * s.s + s.ph)))
	_draw_minimap()
	_draw_goal()
	draw_string(font, Vector2(20, 142), "光潮群島 · 高二", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("9fd8ff"))


func _draw_island(font: Font, i: int) -> void:
	var isl: Dictionary = ISLANDS[i]
	var open := _open(i)
	var poly: PackedVector2Array = _polys[i]
	var col: Color = isl.col
	var land: Color = isl.land if open else Color("1c2a52")
	var c: Vector2 = isl.c
	var sh: Dictionary = _shape[i]
	if not sh.is_empty():
		_draw_real(i, sh, open)
	else:
		# 淺灘
		var shoal := PackedVector2Array()
		for p in poly:
			shoal.append(isl.c + (p - isl.c) * 1.08)
		draw_colored_polygon(shoal, Color(0.3, 0.5, 0.8, 0.25))
		draw_colored_polygon(poly, land)
		var outl := poly.duplicate()
		outl.append(poly[0])
		draw_polyline(outl, col if open else Color("3a4f86"), 5.0, true)
	if open and sh.is_empty():
		_draw_landmark(i, c, col)
	elif not open:
		for k in 5:
			var o := Vector2(cos(k * 1.3 + t * 0.2), sin(k * 1.3 + t * 0.17)) * Vector2(isl.r.x, isl.r.y) * 0.45
			UITheme.dot(self, c + o, 150.0, Color(0.8, 0.84, 0.98, 0.10))
	# 名字
	var nm: String = isl.name
	var fs := 40
	var tw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string_outline(font, c + Vector2(-tw / 2.0, -10), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Color(0.03, 0.06, 0.15, 0.85))
	draw_string(font, c + Vector2(-tw / 2.0, -10), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("fff3d6") if open else Color(0.78, 0.8, 0.9, 0.7))
	var u: Dictionary = Units.unit(isl.unit)
	var sub := String(u.title) if u.id == isl.unit else ""
	if not open:
		sub += "（建造中）"
	var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string_outline(font, c + Vector2(-sw / 2.0, 26), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 8, Color(0.03, 0.06, 0.15, 0.85))
	draw_string(font, c + Vector2(-sw / 2.0, 26), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.85, 0.88, 1.0, 0.85 if open else 0.5))
	if open:
		var pr := _progress(isl.unit)
		var ps := "世界之光 %d／%d" % [pr.lit, pr.n]
		var pw := font.get_string_size(ps, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string_outline(font, c + Vector2(-pw / 2.0, 58), ps, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 8, Color(0.03, 0.06, 0.15, 0.85))
		draw_string(font, c + Vector2(-pw / 2.0, 58), ps, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f5c84c"))
	# 碼頭＋浮標
	var d: Vector2 = _docks[i]
	var inward: Vector2 = (c - d).normalized()
	draw_line(d - inward * 10.0, d + inward * 90.0, Color("8a6a3e"), 26.0)
	draw_line(d - inward * 10.0, d + inward * 90.0, Color("d6a660"), 2.0)
	var bp := d + inward.orthogonal() * 70.0
	var glow := 0.5 + 0.3 * sin(t * 3.0 + i)
	UITheme.dot(self, bp, 30.0, Color(0.96, 0.78, 0.3, 0.25 * glow))
	UITheme.dot(self, bp, 20.0, UITheme.ACCENT)
	draw_arc(bp, 20.0, 0, TAU, 24, Color("fff3c4"), 3.0, true)
	var ns := str(isl.n)
	var nw := font.get_string_size(ns, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_string(font, bp + Vector2(-nw / 2.0, 9), ns, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("2a2440"))


## 有單元地圖的島：照單元地圖的形狀畫（淺灘、陸地、內陸、聖地的點）
## 正弦海岸最右端收成往外凸的半圓
func _wave_cap(wave: PackedVector2Array, c: Color, r: float) -> void:
	var n := wave.size()
	var e := wave[n - 1]
	var d := (e - wave[n - 2]).normalized()
	var o := d.orthogonal()
	var poly := PackedVector2Array()
	for k in 17:
		var a := PI * k / 16.0
		poly.append(e + (o * cos(a) + d * sin(a)) * r)
	draw_colored_polygon(poly, c)


func _draw_real(i: int, sh: Dictionary, open: bool) -> void:
	var isl: Dictionary = ISLANDS[i]
	var col: Color = isl.col
	var land := Color("2f5a4a") if open else Color("24304f")
	var high := Color("3f7458") if open else Color("2c3a5c")
	var sand := Color("d8c08a") if open else Color("5a6488")
	var shallow := Color(0.35, 0.7, 0.95, 0.12)
	match String(sh.kind):
		"trig":
			draw_arc(sh.o, sh.r, 0, TAU, 96, shallow, sh.rw + 50.0, true)
			draw_polyline(sh.wave, shallow, sh.cw + 50.0, true)
			_wave_cap(sh.wave, shallow, (sh.cw + 50.0) / 2.0)
			UITheme.dot(self, sh.cp, sh.dr + 25.0, shallow)
			UITheme.dot(self, sh.o, sh.r - sh.rw / 2.0, Color("12355e"))      # 潟湖
			for pass_ in [[sand, 0.0], [land, 8.0], [high, 26.0]]:
				var cc: Color = pass_[0]
				var sh_in: float = pass_[1]
				draw_arc(sh.o, sh.r, 0, TAU, 128, cc, sh.rw - sh_in, true)
				draw_polyline(sh.wave, cc, sh.cw - sh_in, true)
				_wave_cap(sh.wave, cc, (sh.cw - sh_in) / 2.0)
				UITheme.dot(self, sh.cp, sh.dr - sh_in / 2.0, cc)
			# 羅盤礁的刻紋、圓環刻度
			draw_arc(sh.cp, sh.dr * 0.7, 0, TAU, 48, Color(1, 0.85, 0.45, 0.4), 3.0, true)
			for k in 4:
				var a := k * PI / 2.0
				draw_line(sh.o + Vector2(cos(a), -sin(a)) * (sh.r - 16.0), sh.o + Vector2(cos(a), -sin(a)) * (sh.r + 16.0), Color(1, 1, 1, 0.35), 3.0)
			# 終焉之塔在潟湖中間
			draw_rect(Rect2(sh.o + Vector2(-9, -44), Vector2(18, 44)), Color("c4b0ff"))
		"exp":
			for poly in sh.polys:
				var pp: PackedVector2Array = poly
				var sp := Geometry2D.offset_polygon(pp, 26.0, Geometry2D.JOIN_ROUND)
				for q in sp:
					draw_colored_polygon(q, shallow)
				draw_colored_polygon(pp, sand)
				for q in Geometry2D.offset_polygon(pp, -8.0, Geometry2D.JOIN_ROUND):
					draw_colored_polygon(q, land)
				for q in Geometry2D.offset_polygon(pp, -24.0, Geometry2D.JOIN_ROUND):
					draw_colored_polygon(q, high)
	# 聖地：小小的點，點亮的發光
	var u: Dictionary = Units.unit(isl.unit)
	var g = Game.of(self)
	var sites: Array = sh.sites
	for j in sites.size():
		var lit := false
		if j < u.levels.size():
			lit = Center.level_progress(g, u.levels[j].id) >= 0.999
		var sp2: Vector2 = sites[j]
		var lc: Color = u.levels[j].color if j < u.levels.size() else col
		if lit:
			UITheme.dot(self, sp2, 26.0, Color(lc.r, lc.g, lc.b, 0.3 + 0.1 * sin(t * 2.0 + j)))
		UITheme.dot(self, sp2, 11.0, lc if (lit and open) else Color(0.6, 0.64, 0.8, 0.8))
		draw_arc(sp2, 11.0, 0, TAU, 20, Color(1, 1, 1, 0.7), 2.0, true)


## 開放的島：簡單的地標
func _draw_landmark(i: int, c: Vector2, col: Color) -> void:
	match ISLANDS[i].unit:
		"trig":
			# 月亮＋正弦波海岸
			UITheme.dot(self, c + Vector2(260, -150), 50.0, Color("fff3d6"))
			UITheme.dot(self, c + Vector2(282, -160), 44.0, ISLANDS[i].land)
			var w := PackedVector2Array()
			for k in 41:
				var x := -320.0 + 640.0 * k / 40.0
				w.append(c + Vector2(x, 140 + sin(x / 60.0 + t) * 22.0))
			draw_polyline(w, Color(col.r, col.g, col.b, 0.7), 4.0, true)
		"exp":
			# 指數曲線和對數曲線
			var a := PackedVector2Array()
			var b := PackedVector2Array()
			for k in 31:
				var x := -2.0 + 3.6 * k / 30.0
				var y := pow(2.0, x) - 1.5
				a.append(c + Vector2(x * 70.0 - 120.0, -y * 60.0 + 40.0))
				b.append(c + Vector2(y * 60.0 + 140.0, -x * 70.0 + 40.0))
			draw_polyline(a, Color(col.r, col.g, col.b, 0.75), 4.0, true)
			draw_polyline(b, Color(col.r, col.g, col.b, 0.5), 4.0, true)


func _draw_boat() -> void:
	var bob := sin(t * 2.4) * 3.0
	var f := Vector2.from_angle(heading)
	var s := f.orthogonal()
	var p := pos + Vector2(0, bob)
	UITheme.dot(self, pos + Vector2(0, 14), 30.0, Color(0, 0, 0, 0.18))
	var hull := PackedVector2Array([p + f * 40.0, p + f * 10.0 + s * 18.0, p - f * 32.0 + s * 14.0, p - f * 32.0 - s * 14.0, p + f * 10.0 - s * 18.0])
	draw_colored_polygon(hull, Color("f0d29a"))
	var hl := hull.duplicate()
	hl.append(hull[0])
	draw_polyline(hl, Color("c98a3e"), 3.0, true)
	# 光靈坐在船上
	_draw_dressed(p + Vector2(0, -18), 17.0, f.x < -0.1)


## 畫穿著裝扮的光靈（和主畫面、衣櫃同一隻）；往左走就左右翻轉
func _draw_dressed(p: Vector2, r: float, left: bool) -> void:
	var C := Vector2(W, H) / 2.0
	var o := C - (cam + C) * zoom
	draw_set_transform(o + p * zoom, 0.0, Vector2(-zoom if left else zoom, zoom))
	SL.draw_all(self, Vector2.ZERO, r, Game.of(self).equipped, t)
	draw_set_transform(o, 0.0, Vector2(zoom, zoom))


func _draw_minimap() -> void:
	var mw := 200.0
	var k := mw / WORLD.x
	var mh := WORLD.y * k
	var o := Vector2(W - 18 - mw, 70)
	draw_rect(Rect2(o - Vector2(4, 4), Vector2(mw + 8, mh + 8)), Color(0.04, 0.06, 0.16, 0.88))
	draw_rect(Rect2(o - Vector2(4, 4), Vector2(mw + 8, mh + 8)), Color(1, 1, 1, 0.2), false, 1.0)
	UITheme.dot(self, o + HARBOR * k, 150.0 * k, Color("4a3f6e"))
	for i in ISLANDS.size():
		var mc: Color = (ISLANDS[i].col as Color).darkened(0.35) if _open(i) else Color("2a3a66")
		var sh: Dictionary = _shape[i]
		match String(sh.get("kind", "")):
			"trig":
				draw_arc(o + sh.o * k, sh.r * k, 0, TAU, 32, mc, maxf(1.5, sh.rw * k), true)
				var wv := PackedVector2Array()
				for q in sh.wave:
					wv.append(o + q * k)
				draw_polyline(wv, mc, maxf(1.5, sh.cw * k), true)
				UITheme.dot(self, o + sh.cp * k, sh.dr * k, mc)
			"exp":
				for poly in sh.polys:
					var pq := PackedVector2Array()
					for q in poly:
						pq.append(o + q * k)
					draw_colored_polygon(pq, mc)
			_:
				var pp := PackedVector2Array()
				for q in _polys[i]:
					pp.append(o + q * k)
				draw_colored_polygon(pp, mc)
	draw_rect(Rect2(o + cam * k, Vector2(W, H) * k / zoom), Color(1, 1, 1, 0.5), false, 1.0)
	UITheme.dot(self, o + pos * k, 3.5 + sin(t * 4.0), Color("fff3c4"))


# ================= 主線故事、教學引導 =================
const KEY := "g11"
const GRADE := "高二"
const WS := preload("world_story.gd")
const Tut := preload("tutorial.gd")
var story_focus := Vector2(-1, -1)     # 劇情播放時鏡頭看的地方；(-1, -1) = 跟著玩家
var _goal_text := ""
var _goal_pt := Vector2(-1, -1)        # 主線目標在地圖上的位置
var _goal_t := 0.0


func _story_check() -> void:
	await get_tree().create_timer(0.7).timeout
	while is_inside_tree() and not is_visible_in_tree():
		await get_tree().create_timer(0.3).timeout
	if not is_inside_tree() or playing:
		return
	var g = Game.of(self)
	if not WS.seen(g, KEY):
		await WS.play(self, KEY, WS.STORY[KEY], WS.TITLES[KEY])
		if is_inside_tree():
			_refresh_goal()
			await get_tree().create_timer(0.3).timeout
			Tut.run(self, _tut_steps())
		return
	var su := WS.pending_souvenir(g, GRADE)
	if su != "":
		await WS.play(self, "sv_" + su, WS.souvenir_lines(su), "點亮！" + String(WS.Units.unit(su).title), su)


## 螢幕上的一塊（地圖座標 → 螢幕）；整塊不在畫面上就回傳空的（教學會跳過那一句）
func _scr(p: Vector2, half: Vector2) -> Rect2:
	var C := Vector2(W, H) / 2.0
	var sp := C - (cam + C) * zoom + p * zoom
	var r := Rect2(sp - half, half * 2.0)
	return r if Rect2(0, 0, W, H).encloses(r) else Rect2()


func _goal_rect() -> Rect2:
	var font := UITheme.bold_font()
	var tw := font.get_string_size(_goal_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	return Rect2(Vector2((W - tw) / 2.0 - 16, 72), Vector2(tw + 32, 32))


func _refresh_goal() -> void:
	var g = Game.of(self)
	_goal_text = WS.goal_text(g, GRADE)
	_goal_pt = _goal_world(WS.next_goal(g))


func _draw_goal() -> void:
	if playing or _goal_text == "":
		return
	var tp := Vector2(-1, -1)
	if _goal_pt.x >= 0.0:
		var C := Vector2(W, H) / 2.0
		tp = C - (cam + C) * zoom + _goal_pt * zoom
	WS.draw_goal(self, _goal_text, tp, t)


func focus_point(name: String, uid: String) -> Vector2:
	match name:
		"wide":
			return Vector2(1350, 520)      # 月輪島和雙島之間：一次看到兩座島
		"harbor":
			return HARBOR + Vector2(300, 0)
		"goal":
			return _goal_pt if _goal_pt.x >= 0.0 else pos
		"unit":
			for i in ISLANDS.size():
				if ISLANDS[i].unit == uid:
					return ISLANDS[i].c
	return Vector2(-1, -1)


func _goal_world(gl: Dictionary) -> Vector2:
	if gl.is_empty():
		return Vector2(-1, -1)
	if gl.grade != "高二":
		return HARBOR
	for i in ISLANDS.size():
		if ISLANDS[i].unit == gl.uid:
			return _docks[i]
	return Vector2(-1, -1)


func _tut_steps() -> Array:
	return [
		{"rect": func(): return _scr(pos, Vector2(50, 50)),
		 "text": "這是我們的光舟！用方向鍵或 WASD 划船；也可以按住畫面，船會往那個方向開。"},
		{"rect": func(): return _goal_rect(),
		 "text": "上面的金色橫幅是「主線目標」；畫面邊緣的金色箭頭指著要去的島。"},
		{"rect": func(): return _scr(_goal_pt, Vector2(60, 60)) if _goal_pt.x >= 0.0 else Rect2(),
		 "text": "這是島的碼頭。船開到碼頭旁邊會跳出卡片，按 Enter 或「上岸」就能登島。"},
		{"rect": func(): return _tp.get_global_rect(),
		 "text": "想直接過去的話，按「單元列表」（M），選好島就會開船過去。"},
		{"rect": func(): return Rect2(W - 18 - 200, 14, 200, 44),
		 "text": "右上角可以切回高一的曦光大陸。出航吧！"},
	]
