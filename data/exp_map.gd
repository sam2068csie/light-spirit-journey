extends Control
## 指數與對數的地圖：指數島與對數島（幾何版）
##   ・兩座島的形狀就是 y = 2ˣ 和 y = log₂ x，隔著一道「鏡面海峽」（y = x）互為鏡像
##   ・指數島左邊的尾巴碎成一串小島，一個比一個小一半，越來越靠近「雷射牆」（漸近線 y = 0）卻永遠碰不到；
##     對數島的下端也一樣，靠近另一道雷射牆（x = 0）
##   ・對數島在「海平面」（y = 0）以下是潮間帶的淺灘：log 是負的那一段；海平面以上才是乾的陸地
##   ・光之橋跨過海峽，連起互為鏡像的兩點
##   ・八座聖地都由左下往右上排：指數島 1→3，對數島 4→8
##   ・劇情文字在 world_map.gd 的 STORY（key 沒有前綴，和舊地圖共用，看過的紀錄不會不見）

const UITheme := preload("game_theme.gd")
const SL := preload("spirit_look.gd")
const Game := preload("game.gd")
const Center := preload("review_center.gd")
const Units := preload("units.gd")
const WM := preload("world_map.gd")

const W := 1152.0
const H := 648.0
const SCREEN_C := Vector2(W / 2.0, H / 2.0)
const UNIT := "exp"
const PREFIX := ""
const STORY := WM.STORY
const STORY_TITLES := WM.STORY_TITLES

signal enter_level(file: String)
signal story_changed(on: bool)
signal open_tower

# ---------------- 地形 ----------------
## 數學座標 → 畫面：原點 O，一單位 S 像素
const O := Vector2(500, 420)
const SC := Vector2(96, 74)     # 一單位：橫的拉寬一點，畫面比較不擠
const CW := 46.0                  # 島的陸地寬度
const EXP_U := Vector2(-1.3, 2.3)       # 指數島：x 的範圍
const LOG_V := Vector2(-1.75, 1.9)      # 對數島：y 的範圍（對數島上的點 = 指數島上的點對 y = x 翻過去）
const TAILS := [-1.85, -2.3, -2.75, -3.2, -3.65]      # 碎成小島的尾巴（參數），一個比一個小
const TAIL_R := [10.0, 7.0, 5.0, 3.5, 2.5]

## 八座聖地：isle 0 指數島（參數 u = x）、1 對數島（參數 u = y）；r 是這一區的參數範圍，at 是地標的位置，lab 是名牌
const SITES := [
	{"id": "L1", "isle": 0, "r": Vector2(-1.3, 0.3), "at": -0.4, "lab": Vector2(-84, -12)},
	{"id": "L2", "isle": 0, "r": Vector2(0.3, 1.45), "at": 0.95, "lab": Vector2(-92, 4)},
	{"id": "L3", "isle": 0, "r": Vector2(1.45, 2.3), "at": 1.95, "lab": Vector2(-90, 10)},
	{"id": "L4", "isle": 1, "r": Vector2(-1.75, -0.85), "at": -1.3, "lab": Vector2(-96, 18)},
	{"id": "L5", "isle": 1, "r": Vector2(-0.85, 0.0), "at": -0.42, "lab": Vector2(84, 26)},
	{"id": "L6", "isle": 1, "r": Vector2(0.0, 0.95), "at": 0.48, "lab": Vector2(88, 28)},
	{"id": "L7", "isle": 1, "r": Vector2(0.95, 1.9), "at": 1.42, "lab": Vector2(70, 34)},
	{"id": "L8", "isle": 2, "r": Vector2(0.0, 0.0), "at": 0.0, "lab": Vector2(0, 62)},
]

## 終焉之塔：鏡面海峽的上游（y = x 上）
const TOWER_P := Vector2(500 + 2.95 * 96.0, 420 - 2.95 * 74.0 + 6.0)
## 天文台小島（位數望遠鏡）：對數島的東北外海
const OBS_C := Vector2(1010, 196)
const OBS_R := 46.0

## 小離島（位置、大小）
const ISLETS := [[Vector2(1040, 120), 10.0], [Vector2(1090, 420), 13.0], [Vector2(170, 150), 9.0], [Vector2(300, 560), 11.0]]



var t := 0.0
var glow: Array = []
var progress: Array = []
var done: Array = []
var sel := 0
var spirit := Vector2(480, 330)
var spirit_target := Vector2(480, 330)
var spirit_on := true
var trail: Array = []
var cam := SCREEN_C
var zoom := 1.0
var particles: Array = []
var sky_stars: Array = []
var fog: Array = []
var playing := false
var _hover := -1

var _land: WM._Layer
var _fx: WM._Layer
var _tgt: CanvasItem
var _land_glow: Array = []
var _cache := {}
var _details: Array = []

var _card: PanelContainer
var _card_bar: ColorRect
var _card_name: Label
var _card_topic: Label
var _card_stars: Label
var _card_bar_fill: ProgressBar
var _card_go: Button
var _story_btn: Button
var _player: Control
var _overlay: Control


func _ready() -> void:
	_tgt = self
	_land = WM._Layer.new()
	_land.painter = _draw_land
	add_child(_land)
	_fx = WM._Layer.new()
	_fx.painter = _draw_fx
	add_child(_fx)
	position = Vector2.ZERO
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 150:
		sky_stars.append({"p": Vector2(rng.randf() * W, rng.randf() * H), "s": rng.randf_range(0.5, 1.6), "ph": rng.randf() * TAU})
	for i in SITES.size():
		for k in 7:
			fog.append({"site": i, "o": Vector2(rng.randf_range(-46, 46), rng.randf_range(-50, 26)),
				"r": rng.randf_range(18, 32), "ph": rng.randf() * TAU})
		glow.append(0.0)
		progress.append(0.0)
		done.append(false)
	_details = _make_details()
	_build_card()
	_story_btn = UITheme.ghost_button("劇情回顧", 17)
	_story_btn.custom_minimum_size = Vector2(120, 44)
	_story_btn.position = Vector2(W - 150 - 18 - 130, 14)
	_story_btn.pressed.connect(_show_story_list)
	add_child(_story_btn)
	refresh()


# ================= 資料 =================

func refresh() -> void:
	var g = Game.of(self)
	for i in SITES.size():
		progress[i] = Center.level_progress(g, SITES[i].id)
		done[i] = progress[i] >= 0.999
		glow[i] = _rest_glow(i)
	_update_story_btn()


func _rest_glow(i: int) -> float:
	var g = Game.of(self)
	if done[i] and g.story_seen.has(PREFIX + SITES[i].id):
		return 1.0
	return 0.32 * progress[i]


func on_shown() -> void:
	refresh()
	var first := 0
	for i in SITES.size():
		if not done[i]:
			first = i
			break
		first = i
	var g = Game.of(self)
	var ms: int = g.map_sel
	select(ms if ms >= 0 and ms < SITES.size() else first, false)
	spirit = spirit_target
	cam = SCREEN_C
	zoom = 1.0
	call_deferred("_play_pending")


func _pending_stories() -> Array:
	var g = Game.of(self)
	var out := []
	if not g.story_seen.has(PREFIX + "prologue"):
		out.append("prologue")
	for i in SITES.size():
		if done[i] and not g.story_seen.has(PREFIX + SITES[i].id):
			out.append(SITES[i].id)
	if not done.has(false) and not g.story_seen.has(PREFIX + "epilogue"):
		out.append("epilogue")
	return out


func _play_pending() -> void:
	if playing or not is_visible_in_tree():
		return
	var queue := _pending_stories()
	if queue.is_empty():
		return
	play_story(queue[0], true)



# ================= 幾何 =================

## 島上參數 u 的點（isle 0：(u, 2^u)；isle 1：(2^u, u)）
static func isle_p(isle: int, u: float) -> Vector2:
	var a := pow(2.0, u)
	if isle == 0:
		return O + Vector2(u, -a) * SC
	if isle == 2:
		return OBS_C
	return O + Vector2(a, -u) * SC


## 島上參數 u 的法向量（指數島：往左上那一側；對數島：往右下那一側）
static func isle_n(isle: int, u: float) -> Vector2:
	var d := isle_p(isle, u + 0.01) - isle_p(isle, u - 0.01)
	d = d.normalized()
	return Vector2(d.y, -d.x) if isle == 0 else Vector2(-d.y, d.x)


static func isle_range(isle: int) -> Vector2:
	return EXP_U if isle == 0 else LOG_V


## 島中線的取樣點（照弧長大約每 6 像素一點）
static func isle_pts(isle: int, a: float, b: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var u := a
	pts.append(isle_p(isle, a))
	while u < b:
		var p := isle_p(isle, u)
		var q := isle_p(isle, u + 0.01)
		var step := clampf(0.01 * 6.0 / maxf(0.1, p.distance_to(q)), 0.002, 0.08)
		u = minf(u + step, b)
		pts.append(isle_p(isle, u))
	return pts


## 島的一側邊緣
static func isle_edge(isle: int, a: float, b: float, side: float, pad: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var mid := isle_pts(isle, a, b)
	for k in mid.size():
		var u := _u_of(isle, mid[k])
		pts.append(mid[k] + isle_n(isle, u) * side * (CW / 2.0 + pad))
	return pts


static func _u_of(isle: int, p: Vector2) -> float:
	var v := (p - O) / SC
	return v.x if isle == 0 else -v.y


## 一段島的色塊（兩側邊緣圍起來）
static func isle_band(isle: int, a: float, b: float, half: float) -> PackedVector2Array:
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for p in isle_pts(isle, a, b):
		var n := isle_n(isle, _u_of(isle, p))
		top.append(p + n * half)
		bot.append(p - n * half)
	bot.reverse()
	top.append_array(bot)
	return top


## 整座島的外形（給高二大地圖畫縮圖用；兩端是半圓）
static func island_poly(isle: int) -> PackedVector2Array:
	var r := isle_range(isle)
	var mid := isle_pts(isle, r.x, r.y)
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for p in mid:
		var n := isle_n(isle, _u_of(isle, p))
		top.append(p + n * CW / 2.0)
		bot.append(p - n * CW / 2.0)
	var out := PackedVector2Array(top)
	var e := mid[mid.size() - 1]
	var ne := isle_n(isle, r.y)
	for k in range(1, 12):
		out.append(e + ne.rotated(-PI * k / 12.0 * (1.0 if isle == 0 else -1.0)) * CW / 2.0)
	bot.reverse()
	out.append_array(bot)
	var s0 := mid[0]
	var n0 := isle_n(isle, r.x)
	for k in range(1, 12):
		out.append(s0 - n0.rotated(-PI * k / 12.0 * (1.0 if isle == 0 else -1.0)) * CW / 2.0)
	return out


## 聖地的位置（地標站的地方）
static func site_point(i: int) -> Vector2:
	var st: Dictionary = SITES[i]
	return isle_p(int(st.isle), float(st.at))


static func label_point(i: int) -> Vector2:
	return site_point(i) + Vector2(SITES[i].lab)


## 光靈停在名牌上方
static func hover_point(i: int) -> Vector2:
	return label_point(i) + Vector2(0, -36)


## 這一點在陸地上的哪一座聖地（−1：海上）
static func region_at(p: Vector2) -> int:
	if p.distance_to(OBS_C) <= OBS_R:
		return 7
	var best := -1
	var bd := CW / 2.0 + 4.0
	for isle in 2:
		var r := isle_range(isle)
		var u := r.x
		while u <= r.y:
			var d := p.distance_to(isle_p(isle, u))
			if d < bd:
				bd = d
				best = _site_of(isle, u)
			u += 0.02
	return best


static func _site_of(isle: int, u: float) -> int:
	for i in SITES.size():
		var st: Dictionary = SITES[i]
		if int(st.isle) == isle and u >= st.r.x - 0.0001 and u <= st.r.y + 0.0001:
			return i
	return -1



# ================= 點選 =================

func _to_world(p: Vector2) -> Vector2:
	return (p - SCREEN_C) / zoom + cam


func _site_at(screen_p: Vector2) -> int:
	var wp := _to_world(screen_p)
	if wp.distance_to(TOWER_P + Vector2(0, -32)) < 38.0:
		return 99
	for i in SITES.size():
		if wp.distance_to(site_point(i) + Vector2(0, -24)) < 40.0:
			return i
	for i in SITES.size():
		if wp.distance_to(label_point(i) + Vector2(0, -6)) < 34.0:
			return i
	return region_at(wp)


func _gui_input(e: InputEvent) -> void:
	if playing:
		return
	if e is InputEventMouseMotion:
		var hv := _site_at(e.position)
		if hv != _hover:
			_hover = hv
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hv >= 0 else Control.CURSOR_ARROW
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var i := _site_at(e.position)
		if i == 99:
			_tower_pressed()
			accept_event()
			return
		if i < 0:
			return
		if i == sel:
			_enter(i)
		else:
			select(i)
		accept_event()


func _tower_pressed() -> void:
	var g = Game.of(self)
	if String(Units.unit(UNIT).get("tower", "")) == "":
		_notice("終焉之塔", "塔裡的題目還在準備中，\n等八座聖地蓋好之後就會開放！")
		return
	g.sfx("open")
	open_tower.emit()


func select(i: int, sound := true) -> void:
	sel = i
	Game.of(self).map_sel = i
	spirit_target = hover_point(i)
	if sound:
		Game.of(self).play("blip", 1.0 + 0.06 * i, -10.0)
	_update_card()


func _enter(i: int) -> void:
	var info: Dictionary = Center.level_info(SITES[i].id)
	if String(info.get("file", "")) == "":
		_notice(String(info.name), "這座聖地還在建造中，\n很快就能出發了！")
		return
	enter_level.emit(info.file)


## 簡單的提示視窗
func _notice(title: String, msg: String) -> void:
	var o := UITheme.modal(self, Color(1, 0.85, 0.45, 0.5), 400)
	var layer: Control = o[0]
	_overlay = layer
	var col: VBoxContainer = o[1]
	col.add_child(UITheme.title_label(title, 24, UITheme.ACCENT))
	var l := Label.new()
	l.text = msg
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", UITheme.fs(17))
	l.add_theme_color_override("font_color", UITheme.TEXT)
	col.add_child(l)
	var ok := UITheme.ghost_button("好", 17)
	ok.custom_minimum_size = Vector2(120, 46)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func(): layer.queue_free())
	col.add_child(ok)


# ================= 下方的資訊卡 =================

func _build_card() -> void:
	_card = PanelContainer.new()
	_card.position = Vector2(724, 526)
	_card.custom_minimum_size = Vector2(412, 100)
	_card.add_theme_stylebox_override("panel", UITheme.box(Color(0.07, 0.09, 0.2, 0.92), 18, Color(1, 1, 1, 0.12), 1, 14))
	add_child(_card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_card.add_child(row)
	_card_bar = ColorRect.new()
	_card_bar.custom_minimum_size = Vector2(6, 0)
	row.add_child(_card_bar)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	_card_name = Label.new()
	_card_name.add_theme_font_size_override("font_size", UITheme.fs(24))
	top.add_child(_card_name)
	_card_stars = Label.new()
	_card_stars.add_theme_font_size_override("font_size", UITheme.fs(17))
	_card_stars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_card_stars)
	_card_topic = Label.new()
	_card_topic.add_theme_font_size_override("font_size", UITheme.fs(15))
	_card_topic.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_card_topic.clip_text = true
	_card_topic.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_card_topic.custom_minimum_size = Vector2(300, 0)
	v.add_child(_card_topic)
	_card_bar_fill = ProgressBar.new()
	_card_bar_fill.show_percentage = false
	_card_bar_fill.max_value = 1.0
	_card_bar_fill.custom_minimum_size = Vector2(0, 6)
	v.add_child(_card_bar_fill)
	_card_go = Button.new()
	_card_go.text = "出發  ▶"
	_card_go.custom_minimum_size = Vector2(124, 54)
	_card_go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UITheme.accent_button(_card_go, 20)
	_card_go.pressed.connect(func(): _enter(sel))
	row.add_child(_card_go)


func _update_card() -> void:
	var info: Dictionary = Center.level_info(SITES[sel].id)
	var c: Color = info.color
	var g = Game.of(self)
	_card_bar.color = c
	_card_name.text = "%d．%s" % [sel + 1, info.name]
	_card_name.add_theme_color_override("font_color", c.lightened(0.15))
	var st := int(g.stars.get(SITES[sel].id, 0))
	_card_stars.text = "★".repeat(st) + "☆".repeat(3 - st)
	_card_stars.add_theme_color_override("font_color", UITheme.ACCENT if st > 0 else Color(1, 1, 1, 0.25))
	var p: float = progress[sel]
	var building := String(info.get("file", "")) == ""
	_card_topic.text = "%s　·　%s" % [info.topic, ("建造中" if building else ("已點亮 ✓" if done[sel] else "點亮進度 %d%%" % roundi(100.0 * p)))]
	_card_bar_fill.value = p
	_card_bar_fill.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.08), 3, Color(0, 0, 0, 0), 0, 0))
	_card_bar_fill.add_theme_stylebox_override("fill", UITheme.box(UITheme.ACCENT if done[sel] else c, 3, Color(0, 0, 0, 0), 0, 0))
	_card_go.text = "建造中" if building else ("再訪  ▶" if done[sel] else ("出發  ▶" if p == 0.0 else "繼續  ▶"))
	_card_go.modulate.a = 0.55 if building else 1.0
	_place_card.call_deferred()


func _place_card() -> void:
	if not is_instance_valid(_card):
		return
	_card.reset_size()
	_card.position = Vector2(W - 16.0 - _card.size.x, H - 16.0 - _card.size.y)


# ================= 更新 =================

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	var k := 1.0 - exp(-4.0 * delta)
	spirit = spirit.lerp(spirit_target + Vector2(0, 5.0 * sin(t * 2.4)), k)
	trail.push_front(spirit)
	if trail.size() > 16:
		trail.pop_back()
	for i in SITES.size():
		if glow[i] > 0.5 and randf() < 0.12 * glow[i]:
			var info: Dictionary = Center.level_info(SITES[i].id)
			particles.append({"p": _rand_point(i), "v": Vector2(randf_range(-6, 6), randf_range(-24, -10)),
				"life": 1.0, "c": info.color, "r": randf_range(1.2, 2.6)})
	for p in particles:
		p.p += p.v * delta
		p.life -= delta * 0.5
	particles = particles.filter(func(p): return p.life > 0.0)
	queue_redraw()
	_fx.queue_redraw()
	_land.position = SCREEN_C - cam * zoom
	_land.scale = Vector2(zoom, zoom)
	if glow != _land_glow:
		_land_glow = glow.duplicate()
		_land.queue_redraw()



## 這座聖地的陸地上隨機一點（冒光點用）
func _rand_point(i: int) -> Vector2:
	var st: Dictionary = SITES[i]
	var isle: int = st.isle
	if isle == 2:
		return OBS_C + Vector2.from_angle(randf() * TAU) * randf_range(4.0, OBS_R - 6.0)
	var u := randf_range(st.r.x, st.r.y)
	return isle_p(isle, u) + isle_n(isle, u) * randf_range(-0.4, 0.4) * CW


# ================= 繪圖 =================

func _draw() -> void:
	_tgt = self
	draw_set_transform(SCREEN_C - cam * zoom, 0.0, Vector2(zoom, zoom))
	_draw_sea()
	for st in sky_stars:
		var a: float = 0.12 + 0.14 * sin(t * 1.5 + st.ph)
		UITheme.dot(self, st.p, st.s, Color(0.85, 0.93, 1.0, a))


func _draw_sea() -> void:
	var r := Rect2(-W, -H, 3.0 * W, 3.0 * H)
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([Color("10264a"), Color("10264a"), Color("071526"), Color("071526")]))
	var segs := PackedVector2Array()
	var cols := PackedColorArray()
	for gy in 15:
		var dx := 10.0 * sin(t * 0.5 + gy)
		for gx in 20:
			var p := Vector2(gx * 62.0 + (31.0 if gy % 2 == 1 else 0.0) + dx, gy * 46.0 + 20.0)
			var a := 0.05 + 0.04 * sin(t * 1.3 + gx * 1.7 + gy)
			var c := Color(0.65, 0.85, 1.0, a)
			segs.append_array([p, p + Vector2(7, -3), p + Vector2(7, -3), p + Vector2(14, 0), p + Vector2(14, 0), p + Vector2(21, -3)])
			cols.append_array([c, c, c])
	draw_multiline_colors(segs, cols, 1.2, true)


const LAND := Color("1f2647")
const HIGH := Color("272f58")
const TIDE := Color("1d4152")       # 對數島海平面以下：潮間帶淺灘
const TIDE_HI := Color("245468")
const SAND := Color(0.85, 0.8, 0.62, 0.30)
const MIRROR_A := Vector2(500 - 1.4 * 96.0, 420 + 1.4 * 74.0)      # 鏡面海峽的兩端（y = x）
const MIRROR_B := Vector2(500 + 3.2 * 96.0, 420 - 3.2 * 74.0)


## 不會動的陸地（畫在 _land）
func _draw_land(layer: CanvasItem) -> void:
	_tgt = layer
	var L := layer
	# ---- 鏡面海峽：沿著 y = x 一道平靜、比較亮的海水 ----
	# 兩端淡出：一段一段畫，越靠近兩端越淡
	for k in 24:
		var a0 := MIRROR_A.lerp(MIRROR_B, k / 24.0)
		var a1 := MIRROR_A.lerp(MIRROR_B, (k + 1) / 24.0)
		var f := sin(PI * (k + 0.5) / 24.0)
		L.draw_line(a0, a1, Color(0.6, 0.78, 1.0, 0.06 * f), 40.0)
	# ---- 雷射牆的底座（光束每幀畫在 _fx）----
	# 小離島
	for it in ISLETS:
		_islet(L, it[0], it[1], false)
	# 尾巴碎成的小島：一個比一個小，越來越靠近雷射牆
	for k in TAILS.size():
		_islet(L, isle_p(0, TAILS[k]), TAIL_R[k], false)
		_islet(L, isle_p(1, TAILS[k] - 0.4), TAIL_R[k], true)
	# 塔下的小島
	_islet(L, TOWER_P + Vector2(0, -4), 26.0, false)
	# ---- 兩座島 ----
	var e := isle_pts(0, EXP_U.x, EXP_U.y)
	var lw := isle_pts(1, LOG_V.x, 0.0)
	var lu := isle_pts(1, 0.0, LOG_V.y)
	var ea := isle_pts(0, EXP_U.x, EXP_U.y)
	var la := isle_pts(1, LOG_V.x, LOG_V.y)
	for pts in [ea, la]:
		_round_line(L, pts, Color(0.35, 0.7, 0.95, 0.05), CW + 44.0)
		_round_line(L, pts, Color(0.4, 0.75, 1.0, 0.08), CW + 22.0)
	UITheme.dot(L, OBS_C, OBS_R + 22.0, Color(0.35, 0.7, 0.95, 0.05))
	UITheme.dot(L, OBS_C, OBS_R + 11.0, Color(0.4, 0.75, 1.0, 0.08))
	# 頭尾都收成圓的
	_round_line(L, e, LAND, CW)
	_round_line(L, lu, LAND, CW, false, true)
	_round_line(L, lw, TIDE, CW, true, false)
	_round_line(L, e, HIGH, CW - 18.0)
	_round_line(L, lu, HIGH, CW - 18.0, false, true)
	_round_line(L, lw, TIDE_HI, CW - 18.0, true, false)
	# 天文台小島
	UITheme.dot(L, OBS_C, OBS_R, LAND)
	UITheme.dot(L, OBS_C, OBS_R - 9.0, HIGH)
	L.draw_arc(OBS_C, OBS_R, 0, TAU, 48, SAND, 3.0, true)
	# 點亮的區域
	for i in SITES.size():
		_draw_region_fill(L, i)
	# 淺灘上的水紋
	var v := LOG_V.x + 0.1
	while v < -0.05:
		var p := isle_p(1, v)
		var n := isle_n(1, v)
		var tg := n.orthogonal()
		for s: float in [-0.25, 0.25]:
			var c := p + n * s * CW
			L.draw_polyline(PackedVector2Array([c - tg * 7.0, c - tg * 2.0 + n * 2.0, c + tg * 2.0, c + tg * 7.0 + n * 2.0]),
				Color(0.7, 0.95, 1.0, 0.22), 1.3, true)
		v += 0.17
	# 海平面：對數島從水裡冒出來的地方
	var w0 := isle_p(1, 0.0)
	var wn := isle_n(1, 0.0)
	L.draw_line(w0 - wn * (CW / 2.0 + 18.0), w0 + wn * (CW / 2.0 + 18.0), Color(0.75, 0.95, 1.0, 0.45), 2.0, true)
	# 沙灘
	_draw_sand(L)
	# 山和樹
	_draw_details(L)
	# 區域之間的虛線邊界
	_draw_borders(L)
	_tgt = self


## 粗線，兩端加半圓（島的頭尾收圓）
func _round_line(L: CanvasItem, pts: PackedVector2Array, c: Color, w: float, cap0 := true, cap1 := true) -> void:
	L.draw_polyline(pts, c, w, true)
	if cap0:
		_half_cap(L, pts[0], pts[0] - pts[1], c, w / 2.0)
	if cap1:
		_half_cap(L, pts[pts.size() - 1], pts[pts.size() - 1] - pts[pts.size() - 2], c, w / 2.0)


func _half_cap(L: CanvasItem, c: Vector2, dir: Vector2, col: Color, r: float) -> void:
	var d := dir.normalized()
	var n := d.orthogonal()
	var poly := PackedVector2Array()
	for k in 17:
		var a := PI * k / 16.0
		poly.append(c + n * cos(a) * r + d * sin(a) * r)
	L.draw_colored_polygon(poly, col)


func _islet(L: CanvasItem, c: Vector2, r: float, tide: bool) -> void:
	UITheme.dot(L, c, r + 9.0, Color(0.35, 0.7, 0.95, 0.06))
	UITheme.dot(L, c, r, TIDE if tide else LAND)
	UITheme.dot(L, c + Vector2(-1, -1), r * 0.55, TIDE_HI if tide else HIGH)
	L.draw_arc(c, r, 0, TAU, 24, SAND, 2.0, true)


func _draw_sand(L: CanvasItem) -> void:
	if not _cache.has("sand"):
		var lines := []
		for isle in 2:
			var r := isle_range(isle)
			for side in [1.0, -1.0]:
				lines.append(isle_edge(isle, r.x, r.y, side))
			var mid := isle_pts(isle, r.x, r.y)
			var m := mid.size()
			for end in [[mid[0], mid[0] - mid[1]], [mid[m - 1], mid[m - 1] - mid[m - 2]]]:
				var c: Vector2 = end[0]
				var d: Vector2 = (end[1] as Vector2).normalized()
				var n := d.orthogonal()
				var arc := PackedVector2Array()
				for k in 17:
					var a := PI * k / 16.0
					arc.append(c + (n * cos(a) + d * sin(a)) * CW / 2.0)
				lines.append(arc)
		_cache["sand"] = lines
	for ln in _cache.sand:
		L.draw_polyline(ln, SAND, 3.0, true)


## 點亮的區域：整片染上這一關的顏色
func _draw_region_fill(L: CanvasItem, i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var st: Dictionary = SITES[i]
	var c: Color = Center.level_info(st.id).color
	if int(st.isle) == 2:
		UITheme.dot(L, OBS_C, OBS_R, Color(c.r, c.g, c.b, 0.30 * gl).darkened(0.1))
		UITheme.dot(L, OBS_C, OBS_R - 9.0, Color(c.r, c.g, c.b, 0.22 * gl))
		return
	var isle: int = st.isle
	var rr := isle_range(isle)
	var pts := isle_pts(isle, st.r.x, st.r.y)
	var c0 := Color(c.r, c.g, c.b, 0.30 * gl).darkened(0.1)
	var c1 := Color(c.r, c.g, c.b, 0.22 * gl)
	var at0: bool = absf(st.r.x - rr.x) < 0.001
	var at1: bool = absf(st.r.y - rr.y) < 0.001
	L.draw_polyline(pts, c0, CW, false)
	L.draw_polyline(pts, c1, CW - 18.0, false)
	if at0 or at1:
		if at0:
			_half_cap(L, pts[0], pts[0] - pts[1], c0, CW / 2.0)
			_half_cap(L, pts[0], pts[0] - pts[1], c1, CW / 2.0 - 9.0)
		if at1:
			var n := pts.size()
			_half_cap(L, pts[n - 1], pts[n - 1] - pts[n - 2], c0, CW / 2.0)
			_half_cap(L, pts[n - 1], pts[n - 1] - pts[n - 2], c1, CW / 2.0 - 9.0)


## 點亮區域的發光邊（會脈動，所以每幀畫）
func _draw_region_ring(i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var st: Dictionary = SITES[i]
	var c: Color = Center.level_info(st.id).color
	var pulse := 0.85 + 0.15 * sin(t * 2.0 + i)
	var key := "ring%d" % i
	if not _cache.has(key):
		if int(st.isle) == 2:
			var circ := PackedVector2Array()
			for k in 49:
				circ.append(OBS_C + Vector2.from_angle(TAU * k / 48.0) * OBS_R)
			_cache[key] = [circ]
		else:
			_cache[key] = [isle_edge(int(st.isle), st.r.x, st.r.y, 1.0), isle_edge(int(st.isle), st.r.x, st.r.y, -1.0)]
	for ln in _cache[key]:
		_tgt.draw_polyline(ln, Color(c.r, c.g, c.b, 0.25 * gl * pulse), 7.0)
		_tgt.draw_polyline(ln, Color(c.r, c.g, c.b, 0.9 * gl).lightened(0.3), 2.0, true)


func _make_details() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 29
	for k in 80:
		var isle := 0 if k < 34 else 1
		var r := isle_range(isle)
		var u := rng.randf_range(r.x + 0.05, r.y - 0.05)
		var p := isle_p(isle, u) + isle_n(isle, u) * rng.randf_range(-0.3, 0.3) * CW
		var si := _site_of(isle, u)
		if si < 0:
			continue
		var near := false
		for j in SITES.size():
			if p.distance_to(site_point(j)) < 44.0:
				near = true
		if isle == 1 and u < 0.0:
			near = true          # 淺灘上不長樹
		if not near:
			out.append({"p": p, "si": si, "k": k})
	return out


func _draw_details(L: CanvasItem) -> void:
	var mounts := PackedVector2Array()
	var mcols := PackedColorArray()
	for d in _details:
		var p: Vector2 = d.p
		var si: int = d.si
		var g: float = glow[si]
		var c: Color = Center.level_info(SITES[si].id).color
		if int(d.k) % 3 == 0:
			var col := Color(0.42, 0.46, 0.7, 0.55).lerp(c.lightened(0.2), g * 0.8)
			mounts.append_array([p + Vector2(-8, 4), p + Vector2(0, -7), p + Vector2(0, -7), p + Vector2(8, 4)])
			mcols.append_array([col, col])
		else:
			UITheme.dot(L, p, 3.4, Color(0.16, 0.2, 0.4).lerp(c.darkened(0.25), g * 0.85))
			UITheme.dot(L, p + Vector2(-1, -1), 1.3, Color(1, 1, 1, 0.06 + 0.2 * g))
	if not mounts.is_empty():
		L.draw_multiline_colors(mounts, mcols, 2.0, true)


## 區域之間的虛線邊界（兩邊都點亮時變成金色）
func _draw_borders(L: CanvasItem) -> void:
	for i in SITES.size() - 1:
		if SITES[i].isle != SITES[i + 1].isle:
			continue
		var isle: int = SITES[i].isle
		var u: float = SITES[i].r.y
		var p := isle_p(isle, u)
		var n := isle_n(isle, u)
		var both: bool = glow[i] > 0.6 and glow[i + 1] > 0.6
		L.draw_dashed_line(p + n * CW / 2.0, p - n * CW / 2.0, Color(1, 0.88, 0.55, 0.65) if both else Color(1, 1, 1, 0.28), 2.0, 7.0)


## 每幀都在動的東西（畫在 _fx）
func _draw_fx(layer: CanvasItem) -> void:
	_tgt = layer
	var font := get_theme_default_font()
	layer.draw_set_transform(SCREEN_C - cam * zoom, 0.0, Vector2(zoom, zoom))
	_draw_mirror_shine()
	_draw_walls()
	_draw_bridge()
	for i in SITES.size():
		_draw_region_ring(i)
	_draw_path()
	_draw_tower(font)
	for i in SITES.size():
		_draw_landmark(i)
	_draw_fog()
	for p in particles:
		UITheme.dot(layer, p.p, p.r, Color(p.c.r, p.c.g, p.c.b, p.life * 0.8))
	for i in SITES.size():
		_draw_label(font, i)
	if spirit_on:
		_draw_spirit()
	_draw_names(font)
	layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not playing:
		var lit := done.count(true)
		UITheme.text_ol(layer, font, Vector2(0, 46), "光靈的旅程", HORIZONTAL_ALIGNMENT_CENTER, W, UITheme.fs(30), UITheme.ACCENT, 6)
		UITheme.text_ol(layer, font, Vector2(0, 74), "世界之光  %d ／ %d" % [lit, SITES.size()], HORIZONTAL_ALIGNMENT_CENTER, W, UITheme.fs(15), UITheme.TEXT_DIM)
	_tgt = self


## 鏡面海峽的水面反光：一道道斜斜的亮紋慢慢流動
func _draw_mirror_shine() -> void:
	var d := (MIRROR_B - MIRROR_A).normalized()
	var n := d.orthogonal()
	var mlen := MIRROR_A.distance_to(MIRROR_B)
	for k in 22:
		var s := fposmod(k * 37.0 + t * 14.0, mlen)
		var p := MIRROR_A + d * s + n * (sin(k * 2.3) * 14.0)
		var a := (0.12 + 0.1 * sin(t * 1.8 + k)) * sin(PI * s / mlen)
		_tgt.draw_line(p - d * 6.0, p + d * 6.0, Color(0.9, 0.95, 1.0, a), 1.5, true)


## 雷射牆：柱子之間的光束（會閃）
func _draw_walls() -> void:
	var a := 0.55 + 0.25 * sin(t * 6.0)
	var y0 := Vector2(-40.0, O.y)
	var y1 := O + Vector2(-1.55, 0.0) * SC
	var x0 := O + Vector2(0.0, 1.95) * SC
	var x1 := Vector2(O.x, H + 40.0)
	for seg in [[y0, y1], [x0, x1]]:
		_tgt.draw_line(seg[0], seg[1], Color(1, 0.42, 0.66, 0.16), 9.0)
		_tgt.draw_line(seg[0], seg[1], Color(1, 0.62, 0.8, a), 2.0)


## 光之橋：跨過鏡面海峽，連起光之橋（指數島）和鏡像之塔（對數島）這一對鏡像點
func _draw_bridge() -> void:
	var a := isle_p(0, -0.4) + isle_n(0, -0.4) * -14.0
	var b := isle_p(1, -0.45) + isle_n(1, -0.45) * -14.0
	var mid := (a + b) / 2.0 + Vector2(10, -10) * 2.0
	var pts := PackedVector2Array()
	for k in 21:
		var s := k / 20.0
		pts.append(a.lerp(mid, s).lerp(mid.lerp(b, s), s))
	var gl: float = maxf(glow[0], glow[4])
	_tgt.draw_polyline(pts, Color(0.37, 0.83, 1.0, 0.10 + 0.18 * gl), 12.0, true)
	_tgt.draw_polyline(pts, Color(0.75, 0.94, 1.0, 0.35 + 0.6 * gl), 3.0, true)
	if gl > 0.5:
		var u := fposmod(t * 0.4, 1.0)
		UITheme.dot(_tgt, pts[int(u * 20.0)], 3.5, Color(1, 1, 0.9, 0.9))


## 旅程路線：一串光點（走過的路段是金色）；第 3 → 4 座從指數島飛過海峽
func _route(i: int) -> PackedVector2Array:
	var key := "route%d" % i
	if _cache.has(key):
		return _cache[key]
	var pts := PackedVector2Array()
	var a: Dictionary = SITES[i]
	var b: Dictionary = SITES[i + 1]
	if a.isle == b.isle:
		pts = isle_pts(int(a.isle), a.at, b.at)
	else:
		var p0 := site_point(i)
		var p1 := site_point(i + 1)
		var ctl := O + Vector2(1.9, -1.9) * SC if i == 2 else (p0 + p1) / 2.0 + Vector2(0, -50)
		for k in 31:
			var s := k / 30.0
			pts.append(p0.lerp(ctl, s).lerp(ctl.lerp(p1, s), s))
	_cache[key] = pts
	return pts


func _draw_path() -> void:
	for i in SITES.size() - 1:
		var pts := _route(i)
		var lit: bool = done[i]
		var c := Color(1, 0.88, 0.5, 0.75) if lit else Color(1, 1, 1, 0.16)
		var acc := 0.0
		var nxt := 8.0
		for k in pts.size() - 1:
			var a: Vector2 = pts[k]
			var b: Vector2 = pts[k + 1]
			var L := a.distance_to(b)
			while nxt <= acc + L:
				UITheme.dot(_tgt, a.lerp(b, (nxt - acc) / L), 2.3, c)
				nxt += 14.0
			acc += L



## 終焉之塔
func _draw_tower(font: Font) -> void:
	var p := TOWER_P
	var hov := _hover == 99 and not playing
	var sh := PackedVector2Array()
	for k in 25:
		var ang := TAU * k / 24.0
		sh.append(p + Vector2(cos(ang) * 26.0, sin(ang) * 7.0 + 3.0))
	_tgt.draw_colored_polygon(sh, Color(0.35, 0.7, 0.95, 0.10))
	var body := Color("3a2f66").lightened(0.15 if hov else 0.0)
	_tgt.draw_colored_polygon(PackedVector2Array([p + Vector2(-13, 2), p + Vector2(13, 2), p + Vector2(7, -58), p + Vector2(-7, -58)]), body)
	for yy in [-14.0, -28.0, -42.0]:
		_tgt.draw_line(p + Vector2(-11 + absf(yy) * 0.08, yy), p + Vector2(11 - absf(yy) * 0.08, yy), Color(0, 0, 0, 0.3), 1.5)
		_tgt.draw_rect(Rect2(p + Vector2(-2, yy - 9), Vector2(4, 6)), Color(1, 0.5, 0.55, 0.7))
	_tgt.draw_colored_polygon(PackedVector2Array([p + Vector2(-10, -58), p + Vector2(10, -58), p + Vector2(0, -76)]), body.lightened(0.15))
	var pulse := 0.6 + 0.4 * sin(t * 2.5)
	UITheme.dot(_tgt, p + Vector2(0, -80), 14.0, Color(1, 0.35, 0.45, 0.12 * pulse))
	UITheme.dot(_tgt, p + Vector2(0, -80), 4.0, Color(1, 0.5, 0.55, 0.9))
	for k in 3:
		var a := t * 1.6 + k * TAU / 3.0
		UITheme.dot(_tgt, p + Vector2(cos(a) * 20.0, -34.0 + sin(a) * 6.0), 1.8, Color(1, 0.6, 0.65, 0.7))
	UITheme.text_ol(_tgt, font, p + Vector2(-60, 22), "終焉之塔", HORIZONTAL_ALIGNMENT_CENTER, 120, UITheme.fs(15),
		Color(1, 0.78, 0.8, 1.0 if hov else 0.92))
	var g = Game.of(self)
	if g.tower_best > 0:
		UITheme.text_ol(_tgt, font, p + Vector2(-60, 38), "最高 %d 層" % g.tower_best, HORIZONTAL_ALIGNMENT_CENTER, 120, UITheme.fs(12), Color(1, 0.85, 0.5, 0.92))



## 八座聖地的地標
func _draw_landmark(i: int) -> void:
	var col: Color = Center.level_info(SITES[i].id).color
	var gl: float = glow[i]
	var p := site_point(i)
	var T := _tgt
	var base := Color("3a4170").lerp(col.darkened(0.15), clampf(0.15 + 0.75 * gl, 0.0, 1.0))
	var dark := Color("1c2142").lerp(col.darkened(0.55), gl)
	var light := Color(col.r, col.g, col.b, 0.25 + 0.75 * gl)
	var sh := PackedVector2Array()
	for k in 25:
		var ang := TAU * k / 24.0
		sh.append(p + Vector2(cos(ang) * 26.0, sin(ang) * 6.0 + 2.0))
	T.draw_colored_polygon(sh, Color(0, 0, 0, 0.25))
	if i == sel and not playing:
		var pts := PackedVector2Array()
		for k in 33:
			var ang := TAU * k / 32.0
			pts.append(p + Vector2(cos(ang) * 40.0, sin(ang) * 10.0 + 2.0))
		T.draw_polyline(pts, Color(1, 0.85, 0.45, 0.5 + 0.3 * sin(t * 4.0)), 2.0, true)
	if gl > 0.05:
		UITheme.dot(T, p + Vector2(0, -28), 42.0, Color(col.r, col.g, col.b, 0.07 * gl))
	match i:
		0:   # 光之橋：橋頭的拱門和一盞燈（橋本身跨過海峽，畫在 _draw_bridge）
			var c0 := p + Vector2(0, -2)
			T.draw_line(c0 + Vector2(-16, 0), c0 + Vector2(-16, -30), base, 5.0)
			T.draw_line(c0 + Vector2(16, 0), c0 + Vector2(16, -30), base, 5.0)
			var arc := PackedVector2Array()
			for k in 13:
				var a := PI * k / 12.0
				arc.append(c0 + Vector2(cos(a) * 16.0, -30.0 - sin(a) * 12.0))
			T.draw_polyline(arc, base.lightened(0.15), 5.0, true)
			UITheme.dot(T, c0 + Vector2(0, -50), 5.0, light if gl > 0.05 else dark.lightened(0.2))
			if gl > 0.05:
				UITheme.dot(T, c0 + Vector2(0, -50), 13.0, Color(col.r, col.g, col.b, 0.22 * gl))
		1:   # 換元鍛造所：爐子＋煙囪，爐火上方一道拋物線的火花（換元之後變成二次式）
			T.draw_rect(Rect2(p + Vector2(-20, -26), Vector2(40, 26)), base)
			T.draw_rect(Rect2(p + Vector2(8, -42), Vector2(9, 16)), base.darkened(0.1))
			T.draw_rect(Rect2(p + Vector2(-10, -16), Vector2(16, 12)), dark)
			var fire := Color(1, 0.6, 0.25, 0.4 + 0.5 * (gl if gl > 0.05 else 0.3 + 0.2 * sin(t * 5.0)))
			UITheme.dot(T, p + Vector2(-2, -9), 5.0, fire)
			var para := PackedVector2Array()
			for k in 17:
				var x := -18.0 + 36.0 * k / 16.0
				para.append(p + Vector2(x - 2.0, -46.0 + x * x / 26.0))
			T.draw_polyline(para, Color(1, 0.75, 0.4, 0.25 + 0.7 * gl), 2.0, true)
			for k in 3:
				var sp := fposmod(t * 0.8 + k * 0.33, 1.0)
				UITheme.dot(T, p + Vector2(12.5, -46.0 - 24.0 * sp), 3.0 * (1.0 - sp), Color(0.8, 0.8, 0.9, 0.35 * (1.0 - sp)))
		2:   # 天秤神殿：柱子＋橫桿，兩邊的秤盤（亮了之後平衡）
			T.draw_rect(Rect2(p + Vector2(-18, -6), Vector2(36, 6)), base)
			T.draw_line(p + Vector2(0, -6), p + Vector2(0, -44), base.lightened(0.1), 4.0)
			var tilt := 0.0 if gl > 0.5 else 0.25 * sin(t * 1.4)
			var arm := Vector2(cos(tilt), sin(tilt)) * 24.0
			var top := p + Vector2(0, -44)
			T.draw_line(top - arm, top + arm, base.lightened(0.25), 3.0, true)
			for sg in [-1.0, 1.0]:
				var e: Vector2 = top + arm * sg
				T.draw_line(e, e + Vector2(0, 12), base.lightened(0.2), 1.5)
				T.draw_arc(e + Vector2(0, 12), 8.0, 0.0, PI, 10, light if gl > 0.05 else base.lightened(0.3), 2.5, true)
			UITheme.dot(T, top, 3.5, light if gl > 0.05 else base.lightened(0.35))
		3:   # 對數鍊金術：燒瓶，冒出一顆比一顆大的泡泡（相乘變相加）
			var fc := p + Vector2(0, -14)
			UITheme.dot(T, fc, 13.0, dark.lightened(0.12))
			T.draw_arc(fc, 13.0, 0, TAU, 28, base.lightened(0.3), 2.0, true)
			T.draw_rect(Rect2(fc + Vector2(-4, -26), Vector2(8, 16)), dark.lightened(0.12))
			T.draw_rect(Rect2(fc + Vector2(-4, -26), Vector2(8, 16)), base.lightened(0.3), false, 2.0)
			UITheme.dot(T, fc + Vector2(0, 3), 8.0, Color(col.r, col.g, col.b, 0.3 + 0.5 * gl))
			for k in 4:
				var u := fposmod(t * 0.35 + k * 0.25, 1.0)
				var r := 1.5 + 1.6 * k * (0.6 + 0.4 * u)
				var bp := fc + Vector2(4.0 * sin(t * 2.0 + k) + 2.0 * k, -30.0 - 40.0 * u)
				T.draw_arc(bp, r, 0, TAU, 16, Color(col.r, col.g, col.b, (0.3 + 0.6 * gl) * (1.0 - u)).lightened(0.3), 1.5, true)
		4:   # 鏡像之塔：淺灘上的塔，倒影映在水裡
			var body := PackedVector2Array([p + Vector2(-10, 0), p + Vector2(10, 0), p + Vector2(6, -46), p + Vector2(-6, -46)])
			var ref := PackedVector2Array([p + Vector2(-10, 0), p + Vector2(10, 0), p + Vector2(6, 30), p + Vector2(-6, 30)])
			T.draw_colored_polygon(ref, Color(col.r, col.g, col.b, 0.10 + 0.2 * gl) if gl > 0.05 else Color(0.5, 0.6, 0.9, 0.12))
			T.draw_colored_polygon(body, base)
			T.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -46), p + Vector2(9, -46), p + Vector2(0, -62)]), base.lightened(0.15))
			T.draw_rect(Rect2(p + Vector2(-4, -36), Vector2(8, 10)), light if gl > 0.05 else dark.lightened(0.3))
			for k in 3:
				var yy := 6.0 + k * 8.0 + 2.0 * sin(t * 2.0 + k)
				T.draw_line(p + Vector2(-12 + k * 2, yy), p + Vector2(12 - k * 2, yy), Color(0.8, 0.95, 1.0, 0.25), 1.2)
		5:   # 真數守門員：一道門，假的解進不來
			for sg in [-1.0, 1.0]:
				T.draw_rect(Rect2(p + Vector2(sg * 18.0 - 3.0, -40), Vector2(6, 40)), base.lightened(0.1))
			T.draw_line(p + Vector2(-18, -40), p + Vector2(18, -40), base.lightened(0.2), 4.0)
			var net := Color(1, 1, 1, 0.12 + 0.2 * gl)
			for k in 4:
				T.draw_line(p + Vector2(-15 + k * 10, -38), p + Vector2(-15 + k * 10, -2), net, 1.0)
			for k in 3:
				T.draw_line(p + Vector2(-15, -30 + k * 10), p + Vector2(15, -30 + k * 10), net, 1.0)
			var bx := 22.0 * sin(t * 1.3) if gl < 0.5 else 0.0
			UITheme.dot(T, p + Vector2(bx, -20), 6.0, light if gl > 0.05 else dark.lightened(0.35))
		6:   # 正負羅盤：圓盤上半寫 ＋、下半寫 －，指針擺動（亮了之後停在正確的一邊）
			var cc := p + Vector2(0, -28)
			T.draw_rect(Rect2(p + Vector2(-6, -12), Vector2(12, 12)), base)
			UITheme.dot(T, cc, 19.0, dark.lightened(0.1))
			T.draw_arc(cc, 19.0, 0, TAU, 32, base.lightened(0.3), 2.0, true)
			T.draw_line(cc + Vector2(-17, 0), cc + Vector2(17, 0), Color(1, 1, 1, 0.25), 1.0)
			T.draw_line(cc + Vector2(-4, -10), cc + Vector2(4, -10), light, 2.0)
			T.draw_line(cc + Vector2(0, -14), cc + Vector2(0, -6), light, 2.0)
			T.draw_line(cc + Vector2(-4, 10), cc + Vector2(4, 10), Color(0.6, 0.75, 1.0, 0.5 + 0.5 * gl), 2.0)
			var a := -PI / 2.0 + (0.5 * sin(t * 0.9) if gl > 0.5 else 1.4 * sin(t * 1.7))
			T.draw_line(cc, cc + Vector2(cos(a), sin(a)) * 15.0, Color(1, 0.85, 0.45, 0.6 + 0.4 * gl), 2.5, true)
			UITheme.dot(T, cc, 2.5, Color(1, 1, 1, 0.8))
		7:   # 位數望遠鏡：天文台小島上的圓頂，旁邊一架望遠鏡對著星星
			var dm := p + Vector2(-14, 0)
			T.draw_rect(Rect2(dm + Vector2(-16, -16), Vector2(32, 16)), base)
			var dome := PackedVector2Array()
			for k in 17:
				var a := PI * k / 16.0
				dome.append(dm + Vector2(cos(a) * 16.0, -16.0 - sin(a) * 16.0))
			T.draw_colored_polygon(dome, base.lightened(0.15))
			T.draw_line(dm + Vector2(-2, -31), dm + Vector2(4, -18), dark, 3.0)
			p = p + Vector2(20, 2)
			T.draw_line(p + Vector2(0, -16), p + Vector2(-12, 0), base, 2.5)
			T.draw_line(p + Vector2(0, -16), p + Vector2(12, 0), base, 2.5)
			T.draw_line(p + Vector2(0, -16), p + Vector2(0, 0), base, 2.5)
			var aim := Vector2(cos(-0.95), sin(-0.95))
			var c7 := p + Vector2(0, -20)
			T.draw_line(c7 - aim * 14.0, c7 + aim * 22.0, base.lightened(0.2), 8.0, true)
			UITheme.dot(T, c7 + aim * 23.0, 5.0, light if gl > 0.05 else dark.lightened(0.3))
			if gl > 0.05:
				var tip := c7 + aim * 24.0
				T.draw_colored_polygon(PackedVector2Array([tip, tip + aim.rotated(-0.12) * 140.0, tip + aim.rotated(0.12) * 140.0]),
					Color(col.r, col.g, col.b, 0.08 * gl))
				for k in 4:
					var sp := tip + aim.rotated(0.08 * (k - 1.5)) * (60.0 + 24.0 * k)
					UITheme.dot(T, sp, 2.0 + 0.8 * sin(t * 3.0 + k), Color(1, 0.97, 0.8, 0.8 * gl))


func _draw_names(font: Font) -> void:
	UITheme.text_ol(_tgt, font, Vector2(214, 300), "指數島", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(30), Color(1.0, 0.86, 0.5, 0.85), 6)
	UITheme.text_ol(_tgt, font, Vector2(760, 470), "對數島", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(30), Color(0.6, 0.85, 1.0, 0.85), 6)



func _draw_fog() -> void:
	var tex: Texture2D = WM._fog_tex()
	for f in fog:
		var i: int = f.site
		var dim: float = 1.0 - glow[i]
		if dim <= 0.02:
			continue
		var c: Vector2 = site_point(i) + f.o + Vector2(8.0 * sin(t * 0.4 + f.ph), 3.0 * sin(t * 0.7 + f.ph))
		var r: float = f.r
		_tgt.draw_texture_rect(tex, Rect2(c.x - r, c.y - r, 2.0 * r, 2.0 * r), false,
			Color(0.5, 0.55, 0.8, 1.0 - pow(1.0 - 0.025 * dim, 4.0)))


func _draw_label(font: Font, i: int) -> void:
	var info: Dictionary = Center.level_info(SITES[i].id)
	var c: Color = info.color
	var gl: float = glow[i]
	var p := label_point(i)
	var tc := Color(0.74, 0.78, 0.94, 0.9).lerp(c.lightened(0.2), clampf(gl * 1.2, 0.0, 1.0))
	if i == sel and not playing:
		tc = Color(1, 0.9, 0.6)
	var r := 11.0
	var cx := p + Vector2(-font.get_string_size(info.name, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15)).x / 2.0 - 16.0, -5.0)
	UITheme.dot(_tgt, cx, r, Color(c.r, c.g, c.b, 0.18 + 0.5 * gl))
	_tgt.draw_arc(cx, r, 0, TAU, 24, Color(c.r, c.g, c.b, 0.5 + 0.5 * gl), 1.5, true)
	UITheme.text_ol(_tgt, font, cx + Vector2(-10, 5), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 20, UITheme.fs(13), Color(1, 1, 1, 0.95), 3)
	UITheme.text_ol(_tgt, font, p + Vector2(-70, 0), info.name, HORIZONTAL_ALIGNMENT_CENTER, 140, UITheme.fs(15), tc)
	if done[i]:
		UITheme.text_ol(_tgt, font, p + Vector2(-70, 17), "✦ 已點亮", HORIZONTAL_ALIGNMENT_CENTER, 140, UITheme.fs(12), Color(1, 0.85, 0.45, 0.95))
	elif progress[i] > 0.0:
		_tgt.draw_rect(Rect2(p + Vector2(-22, 8), Vector2(44, 4)), Color(1, 1, 1, 0.12))
		_tgt.draw_rect(Rect2(p + Vector2(-22, 8), Vector2(44.0 * progress[i], 4)), c)


func _draw_spirit() -> void:
	var eq := SL.eq_of(self)
	SL.draw_path_trail(_tgt, trail, 6.5, eq, t)
	var r := 6.5 if eq.is_empty() else 8.0
	SL.draw_back(_tgt, spirit, r, eq, t, false)
	SL.draw_body(_tgt, spirit, r, eq, t)
	SL.draw_eyes(_tgt, spirit, r)
	SL.draw_front(_tgt, spirit, r, eq, t)
	if not eq.has("pet"):
		for k in 3:
			var a := t * 2.0 + k * TAU / 3.0
			UITheme.dot(_tgt, spirit + Vector2(cos(a), sin(a) * 0.5) * 16.0, 1.8, Color(1, 0.95, 0.7, 0.7))




# ================= 劇情 =================

func _update_story_btn() -> void:
	if _story_btn:
		var any := false
		for s in Game.of(self).story_seen:
			if STORY.has(String(s)):
				any = true
		_story_btn.visible = any


func play_story(key: String, auto := false) -> void:
	if not STORY.has(key) or playing:
		return
	playing = true
	story_changed.emit(true)
	_card.visible = false
	_story_btn.visible = false
	var g = Game.of(self)
	var steps: Array = STORY[key]
	for st in steps:
		if st.has("light"):
			glow[st.light] = 0.32 * progress[st.light]
	if key == "prologue":
		spirit_on = false
	var player = WM.StoryPlayer.new()
	player.title = STORY_TITLES.get(key, "")
	_player = player
	add_child(player)
	await player.intro()
	for st in steps:
		await _story_step(st)
		await player.say(st.get("text", ""), st.get("who", ""))
		if not is_instance_valid(player) or player.skipped:
			break
	var last_spirit := -1
	for st in steps:
		if st.has("light"):
			glow[st.light] = 1.0
		if st.has("spirit"):
			last_spirit = int(st.spirit)
	if last_spirit >= 0 and auto:
		select(last_spirit, false)
	else:
		spirit_target = hover_point(sel)
	spirit_on = true
	g.mark_story(PREFIX + key)
	if is_instance_valid(player):
		await player.outro()
		player.queue_free()
	_player = null
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "cam", SCREEN_C, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "zoom", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	playing = false
	story_changed.emit(false)
	_card.visible = true
	refresh()
	_update_card()
	if auto:
		call_deferred("_play_pending")


func _story_step(st: Dictionary) -> void:
	var target := SCREEN_C
	var z: float = st.get("zoom", 1.0)
	match st.get("cam", "wide"):
		"site":
			target = site_point(int(st.site)) + Vector2(0, -40)
		"isle0":
			target = isle_p(0, 0.8)
		"isle1":
			target = isle_p(1, 0.2)
		_:
			z = 1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "cam", target, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "zoom", z, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if st.has("spirit"):
		spirit_target = hover_point(int(st.spirit))
		if st.get("appear", false):
			spirit = spirit_target
			spirit_on = true
			trail.clear()
			_burst(spirit, Color(1, 0.95, 0.7), 40)
			Game.of(self).sfx("open")
	if st.has("light"):
		var i: int = st.light
		tw.tween_method(func(v: float): glow[i] = v, glow[i], 1.0, 1.6).set_delay(0.5)
		var info: Dictionary = Center.level_info(SITES[i].id)
		get_tree().create_timer(0.6).timeout.connect(func():
			_burst(site_point(i) + Vector2(0, -30), info.color, 50)
			Game.of(self).sfx("fanfare"))
	if st.get("all", false):
		for i in SITES.size():
			var info2: Dictionary = Center.level_info(SITES[i].id)
			get_tree().create_timer(0.15 * i).timeout.connect(func(): _burst(site_point(i) + Vector2(0, -30), info2.color, 24))
		Game.of(self).sfx("fanfare")
	await get_tree().create_timer(0.35).timeout


func _burst(at: Vector2, c: Color, n: int) -> void:
	for k in n:
		var ang := randf() * TAU
		var sp := randf_range(30, 120)
		particles.append({"p": at, "v": Vector2(cos(ang), sin(ang)) * sp, "life": 1.0, "c": c, "r": randf_range(1.5, 3.5)})


func _show_story_list() -> void:
	if playing:
		return
	var g = Game.of(self)
	var o := UITheme.modal(self, Color(1, 0.85, 0.45, 0.5), 420)
	var layer: Control = o[0]
	_overlay = layer
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(UITheme.title_label("劇情回顧", 26, UITheme.ACCENT))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, H - 2 * 40.0 - 2 * 24.0 - 140.0)
	col.add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", 14)
	scroll.add_child(pad)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	pad.add_child(list)
	var keys := ["prologue"]
	for st in SITES:
		keys.append(st.id)
	keys.append("epilogue")
	for k in keys:
		var seen: bool = g.story_seen.has(PREFIX + k)
		var b := Button.new()
		b.text = STORY_TITLES[k] if seen else "？？？（點亮聖地後解鎖）"
		b.custom_minimum_size = Vector2(0, 44)
		b.add_theme_font_size_override("font_size", UITheme.fs(15))
		b.disabled = not seen
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		if not seen:
			b.set_meta("silent", true)
		var key: String = k
		b.pressed.connect(func():
			layer.queue_free()
			play_story(key))
		list.add_child(b)
	var close := UITheme.ghost_button("關閉", 16)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): layer.queue_free())
	col.add_child(close)


func close_overlay() -> bool:
	if is_instance_valid(_overlay) and not _overlay.is_queued_for_deletion():
		_overlay.queue_free()
		_overlay = null
		return true
	return false
