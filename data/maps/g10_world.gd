extends "res://data/maps/world_base.gd"
## 高一世界地圖「曦光大陸」：可以自由走動的 2D 地圖（比螢幕大，鏡頭跟著光靈）。
##   ・方向鍵／WASD 移動；手機或滑鼠：在畫面左半邊按住，出現虛擬搖桿
##   ・走到地區入口（拱門）會跳出卡片，Enter／點按鈕進入
##   ・不想跑圖：左上「單元列表」直接選單元進入
##   ・地圖裡藏了小解謎（彩蛋），獎勵星塵
## 左岸「秋晨之地」是高一上四區，晨昏之橋過去是右岸「星夜之地」高一下五區。地區的題目之後再放（現在進去會顯示「準備中」）。
## 存檔放在 Game.world10：{stones: [], visited: [], eggs: [], pos: [x, y]}


const WORLD := Vector2(3600, 2200)
const SPEED := 330.0
const R_PLAYER := 16.0

## 左岸（秋晨之地・高一上）的海岸線
const LEFT := [Vector2(140, 2040), Vector2(80, 1640), Vector2(150, 1150), Vector2(110, 720), Vector2(240, 320),
	Vector2(560, 150), Vector2(1080, 110), Vector2(1500, 170), Vector2(1760, 380), Vector2(1820, 820),
	Vector2(1760, 1220), Vector2(1800, 1620), Vector2(1720, 1980), Vector2(1300, 2110), Vector2(700, 2140)]
## 右岸（星夜之地・高一下）
const RIGHT := [Vector2(2020, 300), Vector2(2320, 150), Vector2(2900, 120), Vector2(3400, 300), Vector2(3520, 900),
	Vector2(3450, 1500), Vector2(3500, 2000), Vector2(3000, 2120), Vector2(2300, 2100), Vector2(2040, 1800),
	Vector2(2010, 1200), Vector2(2060, 700)]
const RIVER := [Vector2(1910, -60), Vector2(1880, 400), Vector2(1950, 900), Vector2(1890, 1400), Vector2(1930, 1900), Vector2(1900, 2300)]
const BRIDGE := Rect2(1740, 1490, 350, 76)
const RIGHT_SPAWN := Vector2(2200, 1530)   # 從「星夜之地」進來時站在橋的東岸

const SPAWN := Vector2(470, 1960)
const HOUSE := Vector2(360, 1930)

## 四個地區：center 地區中心、gate 入口（站在這裡進入）
const ZONES := [
	{"id": "num", "unit": "h1num", "name": "數之原野", "chapter": "數與式", "center": Vector2(540, 1470), "gate": Vector2(760, 1660),
	 "stone": Vector2(860, 1660), "color": Color("f5c84c")},
	{"id": "exp", "unit": "h1exp", "name": "倍增峽谷", "chapter": "指數與常用對數", "center": Vector2(560, 620), "gate": Vector2(600, 930),
	 "stone": Vector2(700, 930), "color": Color("ff9a5a")},
	{"id": "line", "unit": "h1line", "name": "圓規湖", "chapter": "直線與圓", "center": Vector2(1250, 470), "gate": Vector2(1250, 800),
	 "stone": Vector2(1350, 800), "color": Color("5fd4ff")},
	{"id": "poly", "unit": "h1poly", "name": "根之洞窟", "chapter": "多項式", "center": Vector2(1380, 1300), "gate": Vector2(1380, 1520),
	 "stone": Vector2(1480, 1520), "color": Color("c59bff")},
	# ---- 星夜之地（高一下）----
	{"id": "seq", "unit": "h1seq", "name": "階梯瀑布", "chapter": "數列與級數", "center": Vector2(2330, 1800), "gate": Vector2(2580, 1730),
	 "stone": Vector2(2680, 1730), "color": Color("6ee7c0")},
	{"id": "data", "unit": "h1data", "name": "星點觀測台", "chapter": "數據分析", "center": Vector2(2450, 960), "gate": Vector2(2450, 1190),
	 "stone": Vector2(2550, 1190), "color": Color("9fd8ff")},
	{"id": "comb", "unit": "h1comb", "name": "排列花園", "chapter": "排列組合", "center": Vector2(2560, 420), "gate": Vector2(2780, 640),
	 "stone": Vector2(2880, 640), "color": Color("ff9ad5")},
	{"id": "prob", "unit": "h1prob", "name": "骰子市集", "chapter": "機率", "center": Vector2(3150, 760), "gate": Vector2(3150, 1010),
	 "stone": Vector2(3250, 1010), "color": Color("ffb35a")},
	{"id": "trig", "unit": "h1trig", "name": "三角燈塔", "chapter": "三角比", "center": Vector2(3230, 1620), "gate": Vector2(3040, 1780),
	 "stone": Vector2(2940, 1780), "color": Color("f5e27a")},
]
const LEFT_ZONES := 4                 # ZONES 前 4 個在左岸
## 右岸的障礙物
const DOME_C := Vector2(2450, 950)    # 觀測台
const DOME_R := 105.0
const TOWER_C := Vector2(3290, 1600)  # 燈塔
const TOWER_R := 52.0
const STALLS := [Vector2(3020, 690), Vector2(3160, 640), Vector2(3300, 700)]   # 市集攤位
const HEDGES := [Rect2(2400, 300, 120, 34), Rect2(2580, 300, 120, 34), Rect2(2400, 420, 120, 34),
	Rect2(2580, 420, 120, 34), Rect2(2400, 540, 120, 34), Rect2(2580, 540, 120, 34)]   # 花園的樹籬
## 彩蛋三：骰子市集的攤販
const DICE_NPC := Vector2(3420, 860)
const EXIT_SIGN := Vector2(3400, 1960)
const LAKE_C := Vector2(1250, 470)
const LAKE_R := 230.0
const MOUND_C := Vector2(1380, 1290)
const MOUND_R := 165.0

## 彩蛋一：數之原野的數字石，由小到大踩過去
const EGG_STONES := [
	{"t": "π", "v": 3.14159, "p": Vector2(380, 1360)},
	{"t": "√{2}", "v": 1.41421, "p": Vector2(600, 1310)},
	{"t": "√{10}", "v": 3.16228, "p": Vector2(720, 1440)},
	{"t": "3/2", "v": 1.5, "p": Vector2(430, 1570)},
]
const CHEST := Vector2(560, 1450)
## 彩蛋二：西北角的石碑（費氏數列）
const STELE := Vector2(330, 420)

var _fade: ColorRect
var face := Vector2(1, 0)
var walking := false
var _face_left := false
var _trees: Array = []
var _rocks: Array = []
var _grass: Array = []
var _sparks: Array = []
var _trail: Array = []
var _egg_seq: Array = []          # 這一輪已經踩對的數字石（編號）
var _egg_cool := 0.0
var _egg_bad_t := -10.0           # 踩錯順序的時間（數字石閃紅色再重置）
const MathLabel := preload("res://data/ui/math_text.gd")
var _card: PanelContainer
var _card_title: Label
var _card_sub: Label
var _card_btn: Button
var _tp_btn: Button
var _save_t := 0.0
var _mini: Array = []      # 小地圖上縮小的兩塊陸地（算一次）
var _left_poly := PackedVector2Array()
var _right_poly := PackedVector2Array()


func _init() -> void:
	pos = SPAWN


func _world_key() -> String:
	return "g10"


func _grade_name() -> String:
	return "高一"


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_left_poly = _smooth(LEFT)
	_right_poly = _smooth(RIGHT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1010
	# 樹（擋路）：散在左岸，避開地區、入口和小路
	var tries := 0
	while _trees.size() < 130 and tries < 8000:
		tries += 1
		var p := Vector2(rng.randf_range(150, 3480), rng.randf_range(160, 2080))
		var east := p.x > 1960.0
		if not Geometry2D.is_point_in_polygon(p, _right_poly if east else _left_poly) or _near_feature(p, 150.0):
			continue
		_trees.append({"p": p, "r": rng.randf_range(20, 32), "k": rng.randf(), "east": east})
	for i in 280:
		var p := Vector2(rng.randf_range(100, 3500), rng.randf_range(150, 2100))
		if Geometry2D.is_point_in_polygon(p, _left_poly) or Geometry2D.is_point_in_polygon(p, _right_poly):
			_grass.append({"p": p, "s": rng.randf_range(0.7, 1.3)})
	for i in 40:
		_sparks.append({"p": Vector2(rng.randf() * W, rng.randf() * H), "ph": rng.randf() * TAU, "s": rng.randf_range(0.6, 1.4)})
	_build_ui()
	var g = Game.of(self)
	var sp = _state().get("pos", [])
	if sp is Array and sp.size() == 2:
		var p0 := Vector2(float(sp[0]), float(sp[1]))
		if _free(p0):
			pos = p0
	# 從單元地圖回來：站在那個地區的入口，播離開動畫（畫面由暗轉亮、鏡頭拉遠）
	var ret := String(_state().get("ret", ""))
	if ret != "":
		_state()["ret"] = ""
		for z in ZONES:
			if z.unit == ret:
				pos = z.gate + Vector2(0, 40)
		zoom = 1.7
		_fade.color.a = 1.0
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "zoom", 1.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_fade, "color:a", 0.0, 0.6)
	cam = _cam_target()
	_refresh_goal()
	_story_check.call_deferred()


## 這一點附近有沒有地區、入口、小屋、彩蛋（種樹時避開）
func _near_feature(p: Vector2, d: float) -> bool:
	for z in ZONES:
		if p.distance_to(z.gate) < d + 40.0 or p.distance_to(z.center) < 260.0 or p.distance_to(z.stone) < d:
			return true
	for e in EGG_STONES:
		if p.distance_to(e.p) < d:
			return true
	if p.distance_to(HOUSE) < 220.0 or p.distance_to(SPAWN) < 200.0 or p.distance_to(STELE) < 160.0:
		return true
	if p.distance_to(RIGHT_SPAWN) < 200.0 or p.distance_to(DICE_NPC) < 160.0 or p.distance_to(EXIT_SIGN) < 160.0:
		return true
	if p.distance_to(DOME_C) < 260.0 or p.distance_to(TOWER_C) < 260.0 or Rect2(2340, 240, 420, 380).has_point(p):
		return true
	for st in STALLS:
		if p.distance_to(st) < 140.0:
			return true
	if BRIDGE.grow(120.0).has_point(p):
		return true
	# 小路附近不種
	var path := _path_points()
	for i in path.size() - 1:
		if Geometry2D.get_closest_point_to_segment(p, path[i], path[i + 1]).distance_to(p) < 70.0:
			return true
	return false


## 小路：小屋 → 高一上四區 → 橋 → 高一下五區（只是引導，不擋路）
func _path_points() -> Array:
	return [SPAWN, ZONES[0].gate, Vector2(480, 1200), ZONES[1].gate, Vector2(900, 860), ZONES[2].gate,
		Vector2(1300, 1000), ZONES[3].gate, Vector2(1640, 1530), RIGHT_SPAWN, ZONES[4].gate, Vector2(2700, 1400),
		ZONES[5].gate, Vector2(2300, 760), ZONES[6].gate, ZONES[7].gate, Vector2(3150, 1300), ZONES[8].gate]


static func _smooth(pts: Array) -> PackedVector2Array:
	# Catmull-Rom：海岸線圓滑一點
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var p0: Vector2 = pts[(i - 1 + n) % n]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n]
		for k in 8:
			var s := k / 8.0
			var s2 := s * s
			var s3 := s2 * s
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * s + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * s2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * s3))
	return out


# ================= 存檔 =================

func _state() -> Dictionary:
	var g = Game.of(self)
	for k in ["stones", "visited", "eggs"]:
		if not g.world10.has(k):
			g.world10[k] = []
	return g.world10








# ================= 主選單會呼叫的 =================



func on_shown() -> void:
	cam = _cam_target()
	queue_redraw()




func _exit_tree() -> void:
	if is_inside_tree():
		_save()


# ================= 介面 =================

func _build_ui() -> void:
	# 傳送鍵（左上，主選單的按鈕下面）
	_tp_btn = Button.new()
	_tp_btn.text = UITheme.kb("☰ 單元列表（M）", "☰ 單元列表")
	_tp_btn.focus_mode = Control.FOCUS_NONE
	_tp_btn.custom_minimum_size = Vector2(140, 44)
	_tp_btn.position = Vector2(16, 70)
	UITheme.button_3d(_tp_btn, Color("1f4a6e"), Color("12304a"), Color("c8f0ff"), 16, 4, 14, 4)
	_tp_btn.pressed.connect(_open_teleport)
	add_child(_tp_btn)
	# 進入卡片（畫面下方中間）
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UITheme.box(Color(0.06, 0.08, 0.18, 0.94), 16, UITheme.ACCENT, 2, 14))
	_card.custom_minimum_size = Vector2(360, 0)
	_card.visible = false
	add_child(_card)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	_card.add_child(hb)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 2)
	hb.add_child(vb)
	_card_title = Label.new()
	_card_title.add_theme_font_override("font", UITheme.bold_font())
	_card_title.add_theme_font_size_override("font_size", UITheme.fs(22))
	_card_title.add_theme_color_override("font_color", Color("ffe7a3"))
	vb.add_child(_card_title)
	_card_sub = Label.new()
	_card_sub.add_theme_font_size_override("font_size", UITheme.fs(14))
	_card_sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	vb.add_child(_card_sub)
	_card_btn = Button.new()
	_card_btn.focus_mode = Control.FOCUS_NONE
	_card_btn.custom_minimum_size = Vector2(120, 48)
	UITheme.accent_button(_card_btn, 17)
	_card_btn.pressed.connect(_interact)
	hb.add_child(_card_btn)
	# 提示文字（畫面左下）
	var tip := Label.new()
	tip.text = UITheme.kb("方向鍵／WASD 移動，或按住左半邊用搖桿　·　Enter 進入　·　M 單元列表", "按住畫面左半邊，用搖桿移動")
	tip.position = Vector2(18, H - 34)
	tip.add_theme_font_size_override("font_size", UITheme.fs(13))
	tip.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tip)
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(0, 120)
	_toast.size = Vector2(W, 40)
	_toast.add_theme_font_override("font", UITheme.bold_font())
	_toast.add_theme_font_size_override("font_size", UITheme.fs(20))
	_toast.add_theme_color_override("font_color", Color("ffe7a3"))
	_toast.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.12))
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	add_child(_toast)
	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.04, 0.1, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)




func _update_card() -> void:
	var k := String(_near.get("kind", ""))
	_card.visible = k != "" and not is_instance_valid(_overlay) and not _busy and not playing
	if not _card.visible:
		return
	match k:
		"house":
			_card_title.text = "光靈的小屋"
			_card_sub.text = "回家休息、擺家具、看紀念品"
			_card_btn.text = "進屋 ▶"
		"ferry":
			_card_title.text = "渡口"
			_card_sub.text = "搭船到高二的光潮群島"
			_card_btn.text = "搭船 ▶"
		"zone":
			var z: Dictionary = ZONES[int(_near.i)]
			_card_title.text = z.name
			_card_sub.text = "%s　·　題目準備中" % z.chapter
			_card_btn.text = "進入 ▶"
		"stele":
			_card_title.text = "古老的石碑"
			_card_sub.text = "上面刻著一串數字……" if not _has("eggs", "fib") else "石碑已經發出微光（解開了）"
			_card_btn.text = "調查"
		"dice":
			_card_title.text = "擲骰子的攤販"
			_card_sub.text = "「猜對機率就送你獎品！」" if not _has("eggs", "dice") else "「你已經是機率高手啦！」"
			_card_btn.text = "聊聊"
		"chest":
			_card_title.text = "數字石的寶箱"
			_card_sub.text = "四顆石頭都亮了，寶箱打開了！"
			_card_btn.text = "打開"
	_card.reset_size()
	_card.position = Vector2((W - _card.size.x) / 2.0, H - _card.size.y - 48.0)


func _interact() -> void:
	var k := String(_near.get("kind", ""))
	if k == "" or is_instance_valid(_overlay) or _busy:
		return
	Game.of(self).sfx("click")
	match k:
		"house":
			var g = Game.of(self)
			g.set_meta("house_from", "units")
			g.goto("house.gd")
		"ferry":
			var mm := get_parent()
			while mm != null and not mm.has_method("_set_grade"):
				mm = mm.get_parent()
			if mm != null:
				mm._set_grade("高二")
		"zone":
			_open_zone(int(_near.i))
		"stele":
			_open_stele()
		"chest":
			_open_chest()
		"dice":
			_open_dice()


## 進入地區：單元開放了 → 鏡頭推進、畫面變暗，進入那個單元的地圖；還沒開放 → 告訴玩家準備中
func _open_zone(i: int) -> void:
	var z: Dictionary = ZONES[i]
	var u: Dictionary = Units.unit(z.unit)
	if u.id == z.unit and Units.is_open(u):
		_busy = true
		Game.of(self).sfx("success")
		_state()["ret"] = z.unit
		_save()
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "zoom", 1.8, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(_fade, "color:a", 1.0, 0.5).set_delay(0.08)
		await tw.finished
		pick_unit.emit(z.unit)
		return
	var o := UITheme.modal(self, z.color, 460)
	_overlay = o[0]
	var col: VBoxContainer = o[1]
	col.add_child(UITheme.title_label(z.name, 28, z.color))
	var l := Label.new()
	l.text = "「%s」的關卡正在準備中。\n題目放好之後，從這裡就能進入旅程！" % z.chapter
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", UITheme.fs(16))
	l.add_theme_color_override("font_color", UITheme.TEXT)
	col.add_child(l)
	col.add_child(_close_button("知道了"))


func _close_button(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 48)
	UITheme.accent_button(b, 17)
	b.pressed.connect(func(): close_overlay())
	return b


## 單元列表：不想跑圖，直接選一個單元進去（左欄高一上、右欄高一下）
func _open_teleport() -> void:
	if is_instance_valid(_overlay) or _busy:
		return
	Game.of(self).sfx("click")
	var o := UITheme.modal(self, UITheme.ACCENT, 860)
	_overlay = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(UITheme.title_label("☰ 單元列表", 26, UITheme.ACCENT))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	col.add_child(cols)
	var sides := [["秋晨之地 · 高一上", Color("d9b8ff"), range(0, LEFT_ZONES)], ["星夜之地 · 高一下", Color("9fd8ff"), range(LEFT_ZONES, ZONES.size())]]
	for sd in sides:
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_theme_constant_override("separation", 8)
		cols.add_child(vb)
		var hd := Label.new()
		hd.text = sd[0]
		hd.add_theme_font_override("font", UITheme.bold_font())
		hd.add_theme_font_size_override("font_size", UITheme.fs(16))
		hd.add_theme_color_override("font_color", sd[1])
		vb.add_child(hd)
		for zi in sd[2]:
			vb.add_child(_tp_row(zi))
	col.add_child(_close_button("關閉"))


## 單元列表的一列：地區名＋章節、進入
func _tp_row(zi: int) -> Control:
	var z: Dictionary = ZONES[zi]
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var nv := VBoxContainer.new()
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.add_theme_constant_override("separation", 0)
	hb.add_child(nv)
	var nm := Label.new()
	nm.text = z.chapter
	nm.add_theme_font_override("font", UITheme.bold_font())
	nm.add_theme_font_size_override("font_size", UITheme.fs(16))
	nm.add_theme_color_override("font_color", (z.color as Color).lightened(0.3))
	nv.add_child(nm)
	var ch := Label.new()
	ch.text = z.name
	ch.add_theme_font_size_override("font_size", UITheme.fs(12))
	ch.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	nv.add_child(ch)
	var go := Button.new()
	go.focus_mode = Control.FOCUS_NONE
	go.custom_minimum_size = Vector2(100, 40)
	var u: Dictionary = Units.unit(z.unit)
	var ok: bool = u.id == z.unit and Units.is_open(u)
	go.text = "進入 ▶" if ok else "準備中"
	UITheme.button_3d(go, Color("2a6f9e") if ok else Color("3a3360"), Color("17405e") if ok else Color("231e40"), Color("e6f7ff"), 14, 4, 12, 3)
	go.pressed.connect(func():
		close_overlay()
		pos = z.gate + Vector2(0, 40)
		cam = _cam_target()
		_open_zone(zi))
	hb.add_child(go)
	return hb


func _teleport(dest: Vector2) -> void:
	close_overlay()
	Game.of(self).sfx("success")
	pos = dest
	cam = _cam_target()
	for i in 24:
		var a := randf() * TAU
		_trail.append({"p": pos + Vector2(cos(a), sin(a)) * randf_range(4, 30), "v": Vector2(cos(a), sin(a)) * randf_range(40, 140), "life": 0.0})
	_save()


## 彩蛋二：石碑上的費氏數列
func _open_stele() -> void:
	var o := UITheme.modal(self, Color("ff9ad5"), 480)
	_overlay = o[0]
	var col: VBoxContainer = o[1]
	col.add_child(UITheme.title_label("古老的石碑", 26, Color("ff9ad5")))
	var l := Label.new()
	l.text = "1，1，2，3，5，8，13，？"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UITheme.bold_font())
	l.add_theme_font_size_override("font_size", UITheme.fs(26))
	l.add_theme_color_override("font_color", UITheme.TEXT)
	col.add_child(l)
	if _has("eggs", "fib"):
		var d := Label.new()
		d.text = "答案是 21：每一項是前兩項的和（費氏數列）。\n石碑已經被你解開了！"
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.add_theme_font_size_override("font_size", UITheme.fs(15))
		d.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		col.add_child(d)
		col.add_child(_close_button("關閉"))
		return
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	col.add_child(grid)
	var msg := Label.new()
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", UITheme.fs(15))
	msg.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	for v in ["18", "20", "21", "26"]:
		var b := Button.new()
		b.text = v
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(96, 48)
		UITheme.button_3d(b, Color("3a3360"), Color("231e40"), UITheme.TEXT, 18, 4, 12, 3)
		var vv: String = v
		b.pressed.connect(func():
			if vv == "21":
				_add("eggs", "fib")
				Game.of(self).inv["dust"] = int(Game.of(self).inv.get("dust", 0)) + 30
				Game.of(self).sfx("success")
				close_overlay()
				_show_toast("石碑亮了！獲得 星塵 ×30")
			else:
				Game.of(self).sfx("wrong")
				msg.text = "石碑沒有反應……看看相鄰的數字有什麼關係？")
		grid.add_child(b)
	col.add_child(msg)
	col.add_child(_close_button("離開"))


## 彩蛋三：骰子攤販
func _open_dice() -> void:
	var o := UITheme.modal(self, Color("ffb35a"), 500)
	_overlay = o[0]
	var col: VBoxContainer = o[1]
	col.add_child(UITheme.title_label("擲骰子的攤販", 26, Color("ffb35a")))
	var l := Label.new()
	l.text = "「同時擲兩顆公正的骰子，\n點數和是 7 的機率是多少？」"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", UITheme.fs(18))
	l.add_theme_color_override("font_color", UITheme.TEXT)
	col.add_child(l)
	if _has("eggs", "dice"):
		var d := Label.new()
		d.text = "答案是 1/6：36 種結果裡，和是 7 的有 6 種。"
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.add_theme_font_size_override("font_size", UITheme.fs(15))
		d.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		col.add_child(d)
		col.add_child(_close_button("關閉"))
		return
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	col.add_child(grid)
	var msg := Label.new()
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", UITheme.fs(15))
	msg.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	for v in ["7/36", "1/6", "1/12", "1/2"]:
		var b := Button.new()
		b.text = v
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(100, 48)
		UITheme.button_3d(b, Color("3a3360"), Color("231e40"), UITheme.TEXT, 18, 4, 12, 3)
		var vv: String = v
		b.pressed.connect(func():
			if vv == "1/6":
				_add("eggs", "dice")
				Game.of(self).inv["dust"] = int(Game.of(self).inv.get("dust", 0)) + 40
				Game.of(self).sfx("success")
				close_overlay()
				_show_toast("攤販：「答對了！」獲得 星塵 ×40")
			else:
				Game.of(self).sfx("wrong")
				msg.text = "「再想想～把 36 種結果裡和是 7 的數一數？」")
		grid.add_child(b)
	col.add_child(msg)
	col.add_child(_close_button("離開"))


## 彩蛋一的寶箱
func _open_chest() -> void:
	if _has("eggs", "stones"):
		return
	_add("eggs", "stones")
	Game.of(self).inv["dust"] = int(Game.of(self).inv.get("dust", 0)) + 50
	Game.of(self).sfx("success")
	_show_toast("由小到大：√2 < 3/2 < π < √10　獲得 星塵 ×50")
	_save()


# ================= 輸入 =================



func _unhandled_input(e: InputEvent) -> void:
	if playing:
		return
	if not is_visible_in_tree() or is_instance_valid(_overlay):
		return
	if e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_interact()
				get_viewport().set_input_as_handled()
			KEY_M, KEY_TAB:
				_open_teleport()
				get_viewport().set_input_as_handled()




# ================= 移動與碰撞 =================

## 這一點在陸地或橋上嗎
func _ground(q: Vector2) -> bool:
	return BRIDGE.has_point(q) or Geometry2D.is_point_in_polygon(q, _left_poly) or Geometry2D.is_point_in_polygon(q, _right_poly)


## 這個位置能不能站：在陸地或橋上，而且沒有撞到湖、土丘、樹、建築
func _free(p: Vector2) -> bool:
	if not _ground(p):
		return false
	# 離海岸太近也不行（光靈有身體）
	for dv in [Vector2(R_PLAYER, 0), Vector2(-R_PLAYER, 0), Vector2(0, R_PLAYER), Vector2(0, -R_PLAYER)]:
		if not _ground(p + dv):
			return false
	if p.distance_to(DOME_C) < DOME_R + R_PLAYER or p.distance_to(TOWER_C) < TOWER_R + R_PLAYER:
		return false
	for st in STALLS:
		if p.distance_to(st) < 46.0 + R_PLAYER:
			return false
	for hg in HEDGES:
		if (hg as Rect2).grow(R_PLAYER).has_point(p):
			return false
	if p.distance_to(LAKE_C) < LAKE_R + R_PLAYER:
		return false
	if p.distance_to(MOUND_C) < MOUND_R + R_PLAYER:
		return false
	for tr in _trees:
		if p.distance_to(tr.p) < float(tr.r) * 0.7 + R_PLAYER:
			return false
	if p.distance_to(HOUSE) < 70.0:
		return false
	return true


func _cam_target() -> Vector2:
	var c := (story_focus if story_focus.x >= 0.0 else pos) - Vector2(W, H) / 2.0
	return Vector2(clampf(c.x, 0.0, WORLD.x - W), clampf(c.y, 0.0, WORLD.y - H))


func _process(delta: float) -> void:
	t += delta
	var active := is_visible_in_tree() and not is_instance_valid(_overlay) and not _busy and not playing
	_goal_t -= delta
	if _goal_t <= 0.0:
		_goal_t = 1.0
		_refresh_goal()
	var dir := _key_dir() if active else Vector2.ZERO
	if dir == Vector2.ZERO and _hold and active:
		var jv := (_hold_pt - _joy_base) / JOY_R
		if jv.length() > 0.18:
			dir = jv.normalized() * clampf((jv.length() - 0.18) / 0.62, 0.35, 1.0)
	walking = dir != Vector2.ZERO
	if walking:
		face = dir
		var step := dir * SPEED * delta
		var np := pos + step
		if _free(np):
			pos = np
		elif _free(pos + Vector2(step.x, 0)):
			pos += Vector2(step.x, 0)
		elif _free(pos + Vector2(0, step.y)):
			pos += Vector2(0, step.y)
		if randf() < 0.5:
			_trail.append({"p": pos + Vector2(randf_range(-6, 6), randf_range(4, 12)), "v": Vector2(randf_range(-10, 10), randf_range(-30, -10)), "life": 0.0})
		_save_t += delta
		if _save_t > 4.0:
			_save_t = 0.0
			_state()["pos"] = [roundi(pos.x), roundi(pos.y)]
	for p in _trail:
		p.life += delta
		p.p += p.v * delta
	_trail = _trail.filter(func(p): return p.life < 0.8)
	cam = cam.lerp(_cam_target(), 1.0 - exp(-8.0 * delta))
	_check_world(delta)
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)
	_update_card()
	queue_redraw()


## 走到哪裡：去過的地區、傳送石、彩蛋、入口
func _check_world(delta: float) -> void:
	for z in ZONES:
		if pos.distance_to(z.center) < 380.0 and not _has("visited", z.id):
			_add("visited", z.id)
			_show_toast("發現新地區：%s" % z.name)

	# 彩蛋一：數字石
	_egg_cool = maxf(0.0, _egg_cool - delta)
	if not _has("eggs", "stones") and _egg_cool <= 0.0:
		for i in EGG_STONES.size():
			if pos.distance_to(EGG_STONES[i].p) < 34.0 and not _egg_seq.has(i):
				var want := _next_egg()
				if i == want:
					_egg_seq.append(i)
					Game.of(self).sfx("click")
					if _egg_seq.size() == EGG_STONES.size():
						_show_toast("四顆數字石都亮了！原野中間出現了寶箱")
				else:
					_egg_seq = []
					_egg_cool = 1.2
					_egg_bad_t = t
					Game.of(self).play("bonk", 1.0, -6.0)      # 只有聲音，不要整個畫面閃紅（不是扣血）
					_show_toast("石頭暗下去了……要照什麼順序踩呢？")
				break
	# 靠近什麼
	_near = {}
	for i in ZONES.size():
		if pos.distance_to(ZONES[i].gate) < 70.0:
			_near = {"kind": "zone", "i": i}
	if pos.distance_to(STELE) < 90.0:
		_near = {"kind": "stele"}
	if pos.distance_to(DICE_NPC) < 90.0:
		_near = {"kind": "dice"}
	if pos.distance_to(EXIT_SIGN) < 110.0:
		_near = {"kind": "ferry"}
	if pos.distance_to(HOUSE) < 130.0:
		_near = {"kind": "house"}
	if _egg_seq.size() == EGG_STONES.size() and not _has("eggs", "stones") and pos.distance_to(CHEST) < 70.0:
		_near = {"kind": "chest"}


## 數字石：還沒踩的裡面最小的那一顆
func _next_egg() -> int:
	var best := -1
	for i in EGG_STONES.size():
		if _egg_seq.has(i):
			continue
		if best < 0 or float(EGG_STONES[i].v) < float(EGG_STONES[best].v):
			best = i
	return best


# ================= 畫圖 =================

func _draw() -> void:
	var font := UITheme.bold_font()
	# 海
	draw_rect(Rect2(Vector2.ZERO, size), Color("0c1430"))
	var C := Vector2(W, H) / 2.0
	draw_set_transform(C - (cam + C) * zoom, 0.0, Vector2(zoom, zoom))
	var view := Rect2(cam - Vector2(80, 80), Vector2(W, H) + Vector2(160, 160))
	_draw_waves(view)
	# 右岸（星夜之地）
	_fill("right", _right_poly, Color("1c3352"))
	_outline(_right_poly, Color("4f86b0"), 4.0)
	# 河
	var rv := PackedVector2Array(RIVER)
	draw_polyline(rv, Color("1f5a8e"), 150.0, true)
	draw_polyline(rv, Color("2e6fa8"), 110.0, true)
	for i in 10:
		var yy := fmod(t * 40.0 + i * 230.0, 2300.0) - 60.0
		draw_line(Vector2(1890, yy), Vector2(1906, yy + 30), Color(0.7, 0.88, 1.0, 0.35), 3.0, true)
	# 左岸
	_fill("left", _left_poly, Color("2c2646"))
	_outline(_left_poly, Color("6b5a8e"), 4.0)
	_draw_path()
	var grass := PackedVector2Array()      # 草：全部收集起來一次畫完
	for gr in _grass:
		if view.has_point(gr.p):
			var gp: Vector2 = gr.p
			var s: float = gr.s
			grass.append_array([gp, gp + Vector2(-4, -10) * s, gp + Vector2(4, 0), gp + Vector2(6, -12) * s + Vector2(4, 0)])
	if not grass.is_empty():
		draw_multiline(grass, Color("4f6a5c"), 2.0, true)
	_draw_zone_grounds(font)
	_draw_east_grounds(font)
	# 橋
	draw_rect(BRIDGE, Color("8a6a3e"))
	draw_rect(BRIDGE, Color("d6a660"), false, 3.0)
	var bx := BRIDGE.position.x + 10.0
	while bx < BRIDGE.end.x:
		draw_line(Vector2(bx, BRIDGE.position.y), Vector2(bx, BRIDGE.end.y), Color("d6a660"), 2.0)
		bx += 26.0
	draw_string(font, Vector2(BRIDGE.position.x + 70, BRIDGE.position.y - 16), "晨昏之橋", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("f0d29a"))
	# 往高二的渡口告示牌
	var sg := EXIT_SIGN
	draw_rect(Rect2(sg + Vector2(-4, 10), Vector2(8, 60)), Color("6b4f2e"))
	draw_rect(Rect2(sg + Vector2(-90, -24), Vector2(180, 40)), Color("9fd8ff"))
	draw_string(font, sg + Vector2(-80, 4), "渡口 → 高二", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("10223a"))
	# 小屋
	_draw_house(font)
	# 彩蛋二：石碑
	draw_rect(Rect2(STELE + Vector2(-26, -70), Vector2(52, 80)), Color("4a4366"))
	draw_rect(Rect2(STELE + Vector2(-26, -70), Vector2(52, 80)), Color("8d7fb8"), false, 2.0)
	if _has("eggs", "fib"):
		UITheme.dot(self, STELE + Vector2(0, -30), 50.0, Color(1.0, 0.6, 0.85, 0.15 + 0.08 * sin(t * 2.0)))
	draw_string(font, STELE + Vector2(-18, -30), "1 1 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("c4b8ea"))
	draw_string(font, STELE + Vector2(-18, -12), "3 5 ?", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("c4b8ea"))
	# 樹（依 y 排序：上面的先畫）
	var vis := []
	for tr in _trees:
		if view.grow(40.0).has_point(tr.p):
			vis.append(tr)
	_draw_trees(vis)
	# 霧：還沒去過的地區
	for z in ZONES:
		if not _has("visited", z.id):
			for k in 6:
				var o := Vector2(cos(k * 1.05 + t * 0.2), sin(k * 1.05 + t * 0.15)) * 120.0
				UITheme.dot_n(self, z.center + o, 170.0, Color(0.8, 0.82, 0.95, 0.07), 256)
	# 入口、傳送石、名字
	for z in ZONES:
		_draw_gate(font, z)
	# 光靈
	for p in _trail:
		UITheme.dot_n(self, p.p, 3.0 * (1.0 - p.life / 0.8), Color(1.0, 0.92, 0.6, 0.7 * (1.0 - p.life / 0.8)), 32)
	_draw_spirit()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 螢幕上：小光點、小地圖、地區名
	for s in _sparks:
		var a := 0.15 + 0.15 * sin(t * s.s + s.ph)
		UITheme.dot_n(self, s.p, 1.6, Color(1, 0.95, 0.8, a), 16)
	_draw_minimap(font)
	_draw_goal()
	_draw_joystick()
	if pos.x < 1900.0:
		draw_string(font, Vector2(20, 142), "曦光大陸 · 秋晨之地（高一上）", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d9b8ff"))
	else:
		draw_string(font, Vector2(20, 142), "曦光大陸 · 星夜之地（高一下）", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("9fd8ff"))


func _outline(poly: PackedVector2Array, c: Color, w: float) -> void:
	var p2 := poly.duplicate()
	p2.append(poly[0])
	draw_polyline(p2, c, w, true)


func _draw_waves(view: Rect2) -> void:
	var wv := PackedVector2Array()      # 海浪：全部收集起來一次畫完
	var y0 := floorf(view.position.y / 90.0) * 90.0
	var y := y0
	while y < view.end.y:
		var x := floorf(view.position.x / 160.0) * 160.0 + fmod(y, 320.0) * 0.5
		while x < view.end.x:
			var off := sin(t * 1.2 + x * 0.01 + y * 0.02) * 6.0
			var c := Vector2(x + off, y)
			for k in 4:
				wv.append(c + Vector2.from_angle(PI * (1.1 + 0.2 * k)) * 18.0)
				wv.append(c + Vector2.from_angle(PI * (1.1 + 0.2 * (k + 1))) * 18.0)
			x += 160.0
		y += 90.0
	if not wv.is_empty():
		draw_multiline(wv, Color(0.4, 0.55, 0.9, 0.18), 2.0, true)


func _draw_path() -> void:
	var pts := _path_points()
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var n := int(a.distance_to(b) / 26.0)
		for k in n:
			UITheme.dot_n(self, a.lerp(b, (k + 0.5) / maxf(1.0, n)), 5.0, Color(0.95, 0.85, 0.65, 0.28), 32)


func _draw_house(font: Font) -> void:
	var h := HOUSE
	draw_rect(Rect2(h + Vector2(-60, -40), Vector2(120, 80)), Color("6b4f7e"))
	draw_colored_polygon(PackedVector2Array([h + Vector2(-76, -40), h + Vector2(0, -100), h + Vector2(76, -40)]), Color("c97b5a"))
	draw_rect(Rect2(h + Vector2(-16, 0), Vector2(32, 40)), Color("3a2a4a"))
	UITheme.dot(self, h + Vector2(36, -12), 10.0, Color(1.0, 0.85, 0.45, 0.6 + 0.2 * sin(t * 2.0)))
	draw_string(font, h + Vector2(-56, 70), "光靈的小屋", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f0d29a"))


## 樹：同一種東西一起畫（影子 → 樹幹 → 樹冠 → 亮面），每一種只要一次繪圖
func _draw_trees(list: Array) -> void:
	for tr in list:
		UITheme.dot_n(self, tr.p + Vector2(0, tr.r * 0.7), tr.r * 0.8, Color(0, 0, 0, 0.18), 128)
	for tr in list:
		draw_rect(Rect2(tr.p + Vector2(-4, 0), Vector2(8, tr.r * 0.7)), Color("5a3f2e"))
	for tr in list:
		UITheme.dot_n(self, tr.p + Vector2(0, -tr.r * 0.3), tr.r, _tree_col(tr), 128)
	for tr in list:
		UITheme.dot_n(self, tr.p + Vector2(-tr.r * 0.3, -tr.r * 0.6), tr.r * 0.45, _tree_col(tr).lightened(0.15), 128)


func _tree_col(tr: Dictionary) -> Color:
	var k: float = tr.k
	if bool(tr.get("east", false)):
		return Color("2f5f72") if k < 0.5 else (Color("3d6e8a") if k < 0.8 else Color("5a5a9a"))
	return Color("3f6b52") if k < 0.5 else (Color("4d7a4a") if k < 0.8 else Color("8a5a6e"))


## 各地區的地面景物
func _draw_zone_grounds(font: Font) -> void:
	# 數之原野：草地 + 數字石
	var z0: Dictionary = ZONES[0]
	UITheme.dot(self, z0.center, 300.0, Color(0.36, 0.42, 0.34, 0.35))
	for i in EGG_STONES.size():
		var e: Dictionary = EGG_STONES[i]
		var lit := _has("eggs", "stones") or _egg_seq.has(i)
		# 踩錯順序：四顆石頭一起閃紅色三下，然後暗下去重來
		var bad := t - _egg_bad_t < 0.9
		var red := bad and fmod(t - _egg_bad_t, 0.3) < 0.18
		var fill := Color("e0505e") if red else (Color("f5c84c") if lit else Color("4a4366"))
		var rim := Color("ffb0b8") if red else (Color("ffe7a3") if lit else Color("8d7fb8"))
		UITheme.dot(self, e.p + Vector2(0, 8), 30.0, Color(0, 0, 0, 0.2))
		if red:
			UITheme.dot(self, e.p, 40.0, Color(1, 0.3, 0.35, 0.25))
		UITheme.dot(self, e.p, 30.0, fill)
		draw_arc(e.p, 30.0, 0, TAU, 32, rim, 3.0, true)
		# 用數學排版畫，根號上面才有橫線
		MathLabel.draw_on(self, font, e.p.x, e.p.y + 8.0, e.t, 22, Color("2a2440") if (lit or red) else Color("e4d8ff"))
	if _egg_seq.size() == EGG_STONES.size() or _has("eggs", "stones"):
		var opened := _has("eggs", "stones")
		UITheme.dot(self, CHEST, 46.0, Color(1.0, 0.85, 0.4, 0.15 + 0.1 * sin(t * 3.0)))
		draw_rect(Rect2(CHEST + Vector2(-26, -14), Vector2(52, 32)), Color("9a6a32"))
		draw_rect(Rect2(CHEST + Vector2(-26, -14 - (14 if opened else 0)), Vector2(52, 12)), Color("c98a3e"))
		draw_rect(Rect2(CHEST + Vector2(-26, -14), Vector2(52, 32)), Color("f5c84c"), false, 2.0)
	# 倍增峽谷：一層一層往下的峽谷（每層 ×10）
	var z1: Dictionary = ZONES[1]
	for k in 5:
		var rr := 260.0 - k * 46.0
		_fill("canyon%d" % k, _ellipse(z1.center, rr * 1.25, rr * 0.75), Color(0.45 - k * 0.07, 0.28 - k * 0.04, 0.3 - k * 0.03))
		if k < 4:
			draw_string(font, z1.center + Vector2(rr * 1.05, -rr * 0.2), "×10", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.75, 0.55, 0.7))
	# 圓規湖：正圓的湖 + 兩條筆直的路切過湖邊
	var z2: Dictionary = ZONES[2]
	draw_line(z2.center + Vector2(-420, 260), z2.center + Vector2(420, -40), Color(0.95, 0.85, 0.65, 0.18), 18.0, true)
	UITheme.dot(self, LAKE_C, LAKE_R + 14.0, Color("8a7a5a"))
	UITheme.dot(self, LAKE_C, LAKE_R, Color("2e6fa8"))
	for k in 3:
		var rr2 := fmod(t * 30.0 + k * 70.0, LAKE_R - 20.0)
		draw_arc(LAKE_C, rr2, 0, TAU, 48, Color(0.75, 0.9, 1.0, 0.25 * (1.0 - rr2 / LAKE_R)), 2.0, true)
	draw_line(LAKE_C, LAKE_C + Vector2(LAKE_R, 0), Color(1, 1, 1, 0.3), 2.0, true)
	draw_string(font, LAKE_C + Vector2(LAKE_R * 0.35, -8), "r", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.5))
	# 根之洞窟：岩石土丘 + 洞口
	_fill("mound0", _ellipse(MOUND_C, MOUND_R + 20.0, MOUND_R), Color("4a3f5e"))
	_fill("mound1", _ellipse(MOUND_C + Vector2(0, -30), MOUND_R * 0.75, MOUND_R * 0.6), Color("5b4f72"))
	_fill("mound2", _ellipse(MOUND_C + Vector2(0, MOUND_R - 40.0), 60.0, 46.0), Color("140f22"))
	draw_string(font, MOUND_C + Vector2(-40, -40), "x² − 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.85, 0.75, 1.0, 0.6))


## 星夜之地五區的地面景物
func _draw_east_grounds(font: Font) -> void:
	# 階梯瀑布：一階一階往下的瀑布（a₁、a₂、a₃…）
	var sc: Vector2 = ZONES[4].center
	for k in 5:
		var r := Rect2(sc + Vector2(-200 + k * 70, -170 + k * 60), Vector2(150, 70))
		draw_rect(r, Color(0.3 - k * 0.03, 0.42 - k * 0.04, 0.55 - k * 0.04))
		draw_rect(Rect2(r.position + Vector2(20, 0), Vector2(60, 70)), Color(0.45, 0.75, 1.0, 0.75))
		for q in 3:
			var yy := fmod(t * 60.0 + q * 23.0, 70.0)
			draw_line(r.position + Vector2(28 + q * 18, yy), r.position + Vector2(28 + q * 18, minf(70.0, yy + 14.0)), Color(0.9, 0.97, 1.0, 0.7), 2.0)
		draw_string(font, r.position + Vector2(92, 44), "a%s" % ["₁", "₂", "₃", "₄", "₅"][k], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.8, 1.0, 0.92, 0.85))
	# 星點觀測台：圓頂＋散布圖的星星＋迴歸線
	var dc: Vector2 = DOME_C
	var pts := [Vector2(-240, 150), Vector2(-190, 110), Vector2(-150, 120), Vector2(-100, 70), Vector2(-60, 80), Vector2(130, -60), Vector2(170, -40), Vector2(210, -110), Vector2(250, -90)]
	draw_line(dc + Vector2(-270, 170), dc + Vector2(280, -130), Color(0.62, 0.85, 1.0, 0.35), 3.0, true)
	for q in pts:
		UITheme.dot(self, dc + q, 6.0 + sin(t * 2.0 + q.x) * 1.5, Color(0.8, 0.92, 1.0, 0.85))
	UITheme.dot(self, dc + Vector2(0, 12), DOME_R + 8.0, Color(0, 0, 0, 0.2))
	UITheme.dot(self, dc, DOME_R, Color("3a5878"))
	draw_arc(dc, DOME_R, PI, TAU, 32, Color("9fd8ff"), 4.0, true)
	draw_line(dc + Vector2(-20, -DOME_R + 8), dc + Vector2(60, -DOME_R - 40), Color("c8e6ff"), 10.0, true)
	# 排列花園：樹籬＋三色花（3! = 6 種排法）
	for hg in HEDGES:
		draw_rect(hg, Color("2f6a52"))
		draw_rect(hg, Color("4f9a7a"), false, 2.0)
	var fl := [Color("ff9ad5"), Color("ffd36e"), Color("8fd0ff")]
	for row in 3:
		for k in 3:
			UITheme.dot(self, Vector2(2420 + k * 34, 380 + row * 120), 9.0, fl[(k + row) % 3])
			UITheme.dot(self, Vector2(2600 + k * 34, 380 + row * 120), 9.0, fl[(2 * k + row) % 3])
	draw_string(font, ZONES[6].center + Vector2(-40, -150), "3! = 6", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.75, 0.9, 0.8))
	# 骰子市集：攤位（遮雨棚）＋骰子
	for k in STALLS.size():
		var st: Vector2 = STALLS[k]
		draw_rect(Rect2(st + Vector2(-46, -10), Vector2(92, 46)), Color("6b4f2e"))
		var aw := Color("ffb35a") if k % 2 == 0 else Color("ff7a7a")
		for q in 4:
			draw_rect(Rect2(st + Vector2(-50 + q * 25, -40), Vector2(25, 30)), aw if q % 2 == 0 else Color("fff0d8"))
		_draw_die(st + Vector2(-14, 6), (k * 2 + int(t * 0.7)) % 6 + 1)
		_draw_die(st + Vector2(16, 6), (k * 3 + 2 + int(t * 0.9)) % 6 + 1)
	# 彩蛋三：攤販（一個小攤＋兩顆大骰子）
	UITheme.dot(self, DICE_NPC + Vector2(0, -30), 18.0, Color("e8c8a0"))
	draw_rect(Rect2(DICE_NPC + Vector2(-40, -10), Vector2(80, 40)), Color("8a5a3a"))
	_draw_die(DICE_NPC + Vector2(-14, 4), 3)
	_draw_die(DICE_NPC + Vector2(16, 4), 4)
	if not _has("eggs", "dice"):
		draw_string(font, DICE_NPC + Vector2(-8, -60), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ffb35a"))
	# 三角燈塔：塔身＋旋轉的光束＋地上的直角三角形（tan θ = 高 ÷ 影長）
	var tc: Vector2 = TOWER_C
	var beam := t * 0.8
	var tip := tc + Vector2(0, -150)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(cos(beam - 0.12), sin(beam - 0.12)) * 520.0,
		tip + Vector2(cos(beam + 0.12), sin(beam + 0.12)) * 520.0]), Color(1.0, 0.95, 0.6, 0.12))
	var base := tc + Vector2(0, 40)
	draw_line(base, base + Vector2(-260, 0), Color(1, 1, 1, 0.35), 2.0, true)
	draw_line(base + Vector2(-260, 0), tip, Color(1.0, 0.9, 0.5, 0.5), 2.0, true)
	draw_string(font, base + Vector2(-150, 30), "影長", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.5))
	draw_string(font, base + Vector2(-238, -8), "θ", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.9, 0.5, 0.8))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-34, 0), base + Vector2(34, 0), tip + Vector2(16, 20), tip + Vector2(-16, 20)]), Color("e8e0f0"))
	for q in 3:
		draw_rect(Rect2(base + Vector2(-30 + q * 3, -40 - q * 50), Vector2(60 - q * 6, 16)), Color("ff7a7a"))
	UITheme.dot(self, tip, 22.0, Color(1.0, 0.95, 0.6, 0.6 + 0.3 * sin(t * 4.0)))


func _draw_die(c: Vector2, n: int) -> void:
	draw_rect(Rect2(c - Vector2(12, 12), Vector2(24, 24)), Color("fffaf0"))
	draw_rect(Rect2(c - Vector2(12, 12), Vector2(24, 24)), Color("8a6a4a"), false, 1.5)
	var pip := {1: [Vector2.ZERO], 2: [Vector2(-6, -6), Vector2(6, 6)], 3: [Vector2(-6, -6), Vector2.ZERO, Vector2(6, 6)],
		4: [Vector2(-6, -6), Vector2(6, -6), Vector2(-6, 6), Vector2(6, 6)],
		5: [Vector2(-6, -6), Vector2(6, -6), Vector2.ZERO, Vector2(-6, 6), Vector2(6, 6)],
		6: [Vector2(-6, -7), Vector2(6, -7), Vector2(-6, 0), Vector2(6, 0), Vector2(-6, 7), Vector2(6, 7)]}
	for q in pip[n]:
		UITheme.dot(self, c + q, 2.3, Color("2a2440"))


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in 40:
		var a := TAU * k / 40.0
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out


func _draw_gate(font: Font, z: Dictionary) -> void:
	var g: Vector2 = z.gate
	var col: Color = z.color
	var near: bool = String(_near.get("kind", "")) == "zone" and ZONES[int(_near.i)].id == z.id
	UITheme.dot(self, g + Vector2(0, 14), 46.0, Color(col.r, col.g, col.b, 0.18 + (0.15 * sin(t * 3.0) + 0.15 if near else 0.0)))
	# 拱門
	var a := PackedVector2Array()
	for k in 17:
		var ang := PI + PI * k / 16.0
		a.append(g + Vector2(cos(ang) * 40.0, -40.0 + sin(ang) * 40.0))
	a.insert(0, g + Vector2(-40, 10))
	a.append(g + Vector2(40, 10))
	draw_polyline(a, col, 9.0, true)
	# 名字牌
	var nm: String = z.name
	var tw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_rect(Rect2(g + Vector2(-tw / 2.0 - 12, -118), Vector2(tw + 24, 34)), Color(col.r, col.g, col.b, 0.92))
	draw_string(font, g + Vector2(-tw / 2.0, -93), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("1a1530"))


func _draw_spirit() -> void:
	var bob := sin(t * (9.0 if walking else 3.0)) * (3.0 if walking else 2.0)
	var p := pos + Vector2(0, bob - 6.0)
	UITheme.dot(self, pos + Vector2(0, 14), 14.0, Color(0, 0, 0, 0.25))
	if absf(face.x) > 0.2:
		_face_left = face.x < 0.0
	_draw_dressed(p, 20.0, _face_left)




func _draw_minimap(font: Font) -> void:
	var mw := 200.0
	var k := mw / WORLD.x
	var mh := WORLD.y * k
	var o := Vector2(W - 18 - mw, 70)
	draw_rect(Rect2(o - Vector2(4, 4), Vector2(mw + 8, mh + 8)), Color(0.04, 0.05, 0.12, 0.85))
	draw_rect(Rect2(o - Vector2(4, 4), Vector2(mw + 8, mh + 8)), Color(1, 1, 1, 0.2), false, 1.0)
	if not _tri.has("mini_left"):
		var lp := PackedVector2Array()
		for q in _left_poly:
			lp.append(o + q * k)
		var rp := PackedVector2Array()
		for q in _right_poly:
			rp.append(o + q * k)
		_mini = [lp, rp]
	_fill("mini_left", _mini[0], Color("4a3f6e"))
	_fill("mini_right", _mini[1], Color("223a58"))
	for z in ZONES:
		UITheme.dot(self, o + z.center * k, 4.0, z.color if _has("visited", z.id) else Color(0.6, 0.62, 0.75))
	# 鏡頭框
	draw_rect(Rect2(o + cam * k, Vector2(W, H) * k), Color(1, 1, 1, 0.5), false, 1.0)
	UITheme.dot(self, o + pos * k, 3.5 + sin(t * 4.0), Color("fff3c4"))


# ================= 主線故事、教學引導 =================












func focus_point(name: String, uid: String) -> Vector2:
	match name:
		"wide":
			return Vector2(1800, 1100)
		"house":
			return HOUSE
		"zones":
			return Vector2(1150, 1050)
		"ferry":
			return EXIT_SIGN
		"goal":
			return _goal_pt if _goal_pt.x >= 0.0 else pos
		"unit":
			for z in ZONES:
				if z.unit == uid:
					return z.center
	return Vector2(-1, -1)


func _goal_world(gl: Dictionary) -> Vector2:
	if gl.is_empty():
		return Vector2(-1, -1)
	if gl.grade != "高一":
		return EXIT_SIGN
	for z in ZONES:
		if z.unit == gl.uid:
			return z.gate
	return Vector2(-1, -1)


func _tut_steps() -> Array:
	return [
		{"rect": func(): return _scr(pos, Vector2(44, 52)),
		 "text": UITheme.kb("這是我！用方向鍵或 WASD 走路；用滑鼠的話，在畫面左半邊按住，就會出現搖桿，往哪裡拖我就往哪裡走。", "這是我！在畫面左半邊按住，就會出現搖桿，往哪裡拖我就往哪裡走。")},
		{"rect": func(): return _goal_rect(),
		 "text": "上面的金色橫幅是「主線目標」，告訴你下一步要做什麼；金色箭頭會指出要往哪裡走。"},
		{"rect": func(): return _scr(ZONES[0].gate, Vector2(70, 60)),
		 "text": UITheme.kb("這是地區的拱門。走到拱門前會跳出卡片，按 Enter 或「進入」就能進去。", "這是地區的拱門。走到拱門前會跳出卡片，按「進入」就能進去。")},
		{"rect": func(): return _tp_btn.get_global_rect(),
		 "text": UITheme.kb("不想走路的話，按「單元列表」（M），直接選要去的單元。", "不想走路的話，按「單元列表」，直接選要去的單元。")},
		{"rect": func(): return _scr(HOUSE, Vector2(80, 70)),
		 "text": "這是我們的小屋！走過去就能進屋：擺家具、看紀念品、接每日任務。"},
		{"rect": func(): return Rect2(W - 18 - 200, 14, 200, 44),
		 "text": "右上角可以切換高一、高二的地圖。好啦，出發吧！"},
	]


