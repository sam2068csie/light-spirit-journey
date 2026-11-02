extends Control
## 單元地圖的共用底層（指數與對數 exp_map.gd、三角函數 trig_map.gd 都繼承它）
##   共用：資訊卡、點選聖地、點亮進度、光靈、霧、名牌、旅程路線、終焉之塔、劇情播放與回顧
##   子類別只要寫「地形長怎樣」：
##     ・在 _init() 設好 m_sites、m_story、m_titles、m_prefix、m_unit、m_tower
##     ・_site_p(i)、_label_p(i)、_hover_p(i)、_region(p)、_rand_point(i)、_route(i)、_isle_target(k)
##     ・_draw_land(layer)（不會動的陸地）、_draw_region_ring(i)、_draw_landmark(i)、_draw_names(font)、_make_details()
##     ・需要的話：_fx_under()（點亮邊框之前畫）、_fx_mid()（旅程路線之後畫）

const UITheme := preload("game_theme.gd")
const SL := preload("spirit_look.gd")
const Game := preload("game.gd")
const Center := preload("review_center.gd")
const Units := preload("units.gd")
const StoryPlayer := preload("story_player.gd")
const MapLayer := preload("map_layer.gd")

const W := 1152.0
const H := 648.0
const SCREEN_C := Vector2(W / 2.0, H / 2.0)

signal enter_level(file: String)
signal story_changed(on: bool)
signal open_tower

## ---- 子類別在 _init() 設定 ----
var m_sites: Array = []           # 聖地：[{id, …}]
var m_story: Dictionary = {}      # 劇情：key → [{text, who, cam, site, zoom, light, spirit}]
var m_titles: Dictionary = {}     # 劇情標題
var m_prefix := ""                # 劇情 key 的前綴（存檔裡用；三角函數是 "trig/"）
var m_unit := ""                  # 單元 id（找終焉之塔用）
var m_tower := Vector2.ZERO       # 終焉之塔的位置

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

var _land: MapLayer
var _fx: MapLayer
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


# ================= 子類別要提供的 =================

func _site_p(_i: int) -> Vector2:
	return Vector2.ZERO

func _label_p(i: int) -> Vector2:
	return _site_p(i)

func _hover_p(i: int) -> Vector2:
	return _label_p(i) + Vector2(0, -36)

func _region(_p: Vector2) -> int:
	return -1

func _rand_point(i: int) -> Vector2:
	return _site_p(i)

func _route(_i: int) -> PackedVector2Array:
	return PackedVector2Array()

func _isle_target(_k: int) -> Vector2:
	return SCREEN_C

func _make_details() -> Array:
	return []

func _draw_land(_layer: CanvasItem) -> void:
	pass

func _draw_region_ring(_i: int) -> void:
	pass

func _draw_landmark(_i: int) -> void:
	pass

func _draw_names(_font: Font) -> void:
	pass

func _fx_under() -> void:
	pass

func _fx_mid() -> void:
	pass


# ================= 共用 =================

func _ready() -> void:
	_tgt = self
	_land = MapLayer.new()
	_land.painter = _draw_land
	add_child(_land)
	_fx = MapLayer.new()
	_fx.painter = _draw_fx
	add_child(_fx)
	position = Vector2.ZERO
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 150:
		sky_stars.append({"p": Vector2(rng.randf() * W, rng.randf() * H), "s": rng.randf_range(0.5, 1.6), "ph": rng.randf() * TAU})
	for i in m_sites.size():
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


func refresh() -> void:
	var g = Game.of(self)
	for i in m_sites.size():
		progress[i] = Center.level_progress(g, m_sites[i].id)
		done[i] = progress[i] >= 0.999
		glow[i] = _rest_glow(i)
	_update_story_btn()


func _rest_glow(i: int) -> float:
	var g = Game.of(self)
	if done[i] and g.story_seen.has(m_prefix + m_sites[i].id):
		return 1.0
	return 0.32 * progress[i]


func on_shown() -> void:
	refresh()
	var first := 0
	for i in m_sites.size():
		if not done[i]:
			first = i
			break
		first = i
	var g = Game.of(self)
	var ms: int = g.map_sel
	select(ms if ms >= 0 and ms < m_sites.size() else first, false)
	spirit = spirit_target
	cam = SCREEN_C
	zoom = 1.0
	call_deferred("_play_pending")


func _pending_stories() -> Array:
	var g = Game.of(self)
	var out := []
	if not g.story_seen.has(m_prefix + "prologue"):
		out.append("prologue")
	for i in m_sites.size():
		if done[i] and not g.story_seen.has(m_prefix + m_sites[i].id):
			out.append(m_sites[i].id)
	if not done.has(false) and not g.story_seen.has(m_prefix + "epilogue"):
		out.append("epilogue")
	return out


func _play_pending() -> void:
	if playing or not is_visible_in_tree():
		return
	var queue := _pending_stories()
	if queue.is_empty():
		return
	play_story(queue[0], true)


func _to_world(p: Vector2) -> Vector2:
	return (p - SCREEN_C) / zoom + cam


func _site_at(screen_p: Vector2) -> int:
	var wp := _to_world(screen_p)
	if wp.distance_to(m_tower + Vector2(0, -32)) < 38.0:
		return 99
	for i in m_sites.size():
		if wp.distance_to(_site_p(i) + Vector2(0, -24)) < 40.0:
			return i
	for i in m_sites.size():
		if wp.distance_to(_label_p(i) + Vector2(0, -6)) < 34.0:
			return i
	return _region(wp)


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
	if String(Units.unit(m_unit).get("tower", "")) == "":
		_notice("終焉之塔", "塔裡的題目還在準備中，\n等%d 座聖地蓋好之後就會開放！" % m_sites.size())
		return
	g.sfx("open")
	open_tower.emit()


func select(i: int, sound := true) -> void:
	sel = i
	Game.of(self).map_sel = i
	spirit_target = _hover_p(i)
	if sound:
		Game.of(self).play("blip", 1.0 + 0.06 * i, -10.0)
	_update_card()


func _enter(i: int) -> void:
	var info: Dictionary = Center.level_info(m_sites[i].id)
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
	var info: Dictionary = Center.level_info(m_sites[sel].id)
	var c: Color = info.color
	var g = Game.of(self)
	_card_bar.color = c
	_card_name.text = "%d．%s" % [sel + 1, info.name]
	_card_name.add_theme_color_override("font_color", c.lightened(0.15))
	var st := int(g.stars.get(m_sites[sel].id, 0))
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


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	var k := 1.0 - exp(-4.0 * delta)
	spirit = spirit.lerp(spirit_target + Vector2(0, 5.0 * sin(t * 2.4)), k)
	trail.push_front(spirit)
	if trail.size() > 16:
		trail.pop_back()
	for i in m_sites.size():
		if glow[i] > 0.5 and randf() < 0.12 * glow[i]:
			var info: Dictionary = Center.level_info(m_sites[i].id)
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


func _draw_details(L: CanvasItem) -> void:
	var mounts := PackedVector2Array()
	var mcols := PackedColorArray()
	for d in _details:
		var p: Vector2 = d.p
		var si: int = d.si
		var g: float = glow[si]
		var c: Color = Center.level_info(m_sites[si].id).color
		if int(d.k) % 3 == 0:
			var col := Color(0.42, 0.46, 0.7, 0.55).lerp(c.lightened(0.2), g * 0.8)
			mounts.append_array([p + Vector2(-8, 4), p + Vector2(0, -7), p + Vector2(0, -7), p + Vector2(8, 4)])
			mcols.append_array([col, col])
		else:
			UITheme.dot(L, p, 3.4, Color(0.16, 0.2, 0.4).lerp(c.darkened(0.25), g * 0.85))
			UITheme.dot(L, p + Vector2(-1, -1), 1.3, Color(1, 1, 1, 0.06 + 0.2 * g))
	if not mounts.is_empty():
		L.draw_multiline_colors(mounts, mcols, 2.0, true)


## 每幀都在動的東西（畫在 _fx）
func _draw_fx(layer: CanvasItem) -> void:
	_tgt = layer
	var font := get_theme_default_font()
	layer.draw_set_transform(SCREEN_C - cam * zoom, 0.0, Vector2(zoom, zoom))
	_fx_under()
	for i in m_sites.size():
		_draw_region_ring(i)
	_draw_path()
	_fx_mid()
	_draw_tower(font)
	for i in m_sites.size():
		_draw_landmark(i)
	_draw_fog()
	for p in particles:
		UITheme.dot(layer, p.p, p.r, Color(p.c.r, p.c.g, p.c.b, p.life * 0.8))
	for i in m_sites.size():
		_draw_label(font, i)
	if spirit_on:
		_draw_spirit()
	_draw_names(font)
	layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not playing:
		var lit := done.count(true)
		UITheme.text_ol(layer, font, Vector2(0, 46), "光靈的旅程", HORIZONTAL_ALIGNMENT_CENTER, W, UITheme.fs(30), UITheme.ACCENT, 6)
		UITheme.text_ol(layer, font, Vector2(0, 74), "世界之光  %d ／ %d" % [lit, m_sites.size()], HORIZONTAL_ALIGNMENT_CENTER, W, UITheme.fs(15), UITheme.TEXT_DIM)
	_tgt = self


func _draw_path() -> void:
	for i in m_sites.size() - 1:
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
	var p := m_tower
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


func _draw_fog() -> void:
	var tex: Texture2D = _fog_tex()
	for f in fog:
		var i: int = f.site
		var dim: float = 1.0 - glow[i]
		if dim <= 0.02:
			continue
		var c: Vector2 = _site_p(i) + f.o + Vector2(8.0 * sin(t * 0.4 + f.ph), 3.0 * sin(t * 0.7 + f.ph))
		var r: float = f.r
		_tgt.draw_texture_rect(tex, Rect2(c.x - r, c.y - r, 2.0 * r, 2.0 * r), false,
			Color(0.5, 0.55, 0.8, 1.0 - pow(1.0 - 0.025 * dim, 4.0)))


func _draw_label(font: Font, i: int) -> void:
	var info: Dictionary = Center.level_info(m_sites[i].id)
	var c: Color = info.color
	var gl: float = glow[i]
	var p := _label_p(i)
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


func _update_story_btn() -> void:
	if _story_btn:
		var any := false
		for s in Game.of(self).story_seen:
			var ss := String(s)
			if ss.begins_with(m_prefix) and m_story.has(ss.substr(m_prefix.length())):
				any = true
		_story_btn.visible = any


func play_story(key: String, auto := false) -> void:
	if not m_story.has(key) or playing:
		return
	playing = true
	story_changed.emit(true)
	_card.visible = false
	_story_btn.visible = false
	var g = Game.of(self)
	var steps: Array = m_story[key]
	for st in steps:
		if st.has("light"):
			glow[st.light] = 0.32 * progress[st.light]
	if key == "prologue":
		spirit_on = false
	var player = StoryPlayer.new()
	player.title = m_titles.get(key, "")
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
		spirit_target = _hover_p(sel)
	spirit_on = true
	g.mark_story(m_prefix + key)
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
			target = _site_p(int(st.site)) + Vector2(0, -40)
		"isle0":
			target = _isle_target(0)
		"isle1":
			target = _isle_target(1)
		_:
			z = 1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "cam", target, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "zoom", z, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if st.has("spirit"):
		spirit_target = _hover_p(int(st.spirit))
		if st.get("appear", false):
			spirit = spirit_target
			spirit_on = true
			trail.clear()
			_burst(spirit, Color(1, 0.95, 0.7), 40)
			Game.of(self).sfx("open")
	if st.has("light"):
		var i: int = st.light
		tw.tween_method(func(v: float): glow[i] = v, glow[i], 1.0, 1.6).set_delay(0.5)
		var info: Dictionary = Center.level_info(m_sites[i].id)
		get_tree().create_timer(0.6).timeout.connect(func():
			_burst(_site_p(i) + Vector2(0, -30), info.color, 50)
			Game.of(self).sfx("fanfare"))
	if st.get("all", false):
		for i in m_sites.size():
			var info2: Dictionary = Center.level_info(m_sites[i].id)
			get_tree().create_timer(0.15 * i).timeout.connect(func(): _burst(_site_p(i) + Vector2(0, -30), info2.color, 24))
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
	for st in m_sites:
		keys.append(st.id)
	keys.append("epilogue")
	for k in keys:
		var seen: bool = g.story_seen.has(m_prefix + k)
		var b := Button.new()
		b.text = m_titles[k] if seen else "？？？（點亮聖地後解鎖）"
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


static var _fog_texture: Texture2D

## 霧的貼圖（柔邊圓形，所有霧共用一張）
static func _fog_tex() -> Texture2D:
	if _fog_texture:
		return _fog_texture
	var n := 128
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	var half := n / 2.0
	var full := 1.0 - pow(1.0 - 0.025, 4.0)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - half, y + 0.5 - half).length()
			var keep := 1.0
			for k in 4:
				var cover := clampf(half * (1.0 - 0.2 * k) - d + 0.5, 0.0, 1.0)
				keep *= 1.0 - 0.025 * cover
			img.set_pixel(x, y, Color(1, 1, 1, (1.0 - keep) / full))
	_fog_texture = ImageTexture.create_from_image(img)
	return _fog_texture
