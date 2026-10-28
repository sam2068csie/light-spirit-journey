extends Control
## 終焉之塔：每過一層，播一段「往上爬一層樓」的小動畫，再進下一層（點一下可以跳過）
##   鏡頭沿著塔往上捲一層，光靈從這一層跳到上一層，新樓層的窗戶亮起來，樓層數字翻上去

const UITheme := preload("game_theme.gd")
const Game := preload("game.gd")
const Buddy := preload("buddy.gd")

const FLOOR_H := 92.0
const DURATION := 2.3

var from_floor := 1
var to_floor := 2
var stars := 3
var hearts := 3
var best := 0
var t := 0.0
var _left := false
var _sky: Array = []
var _sparks: Array = []
var _lit_burst := false
var face


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.shared()
	var a: Dictionary = Game.of(self).take_args()
	from_floor = int(a.get("from", 1))
	to_floor = int(a.get("to", from_floor + 1))
	stars = int(a.get("stars", 3))
	hearts = int(a.get("hearts", 3))
	best = int(a.get("best", 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 90:
		_sky.append({"p": Vector2(rng.randf() * 1152.0, rng.randf() * 648.0), "s": rng.randf_range(0.6, 1.8), "ph": rng.randf() * TAU})
	face = Buddy.Face.new()
	face.size = Vector2(70, 70)
	face.radius = 15.0
	face.mood = "happy" if stars > 0 else "normal"
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(face)
	Game.of(self).play("blip", 1.0, -10.0, 0.25)


func _process(delta: float) -> void:
	t += delta
	# 光靈落地：新樓層亮起來，噴一點光
	if not _lit_burst and t >= 1.15:
		_lit_burst = true
		Game.of(self).sfx("ping")
		var c := _floor_center(to_floor) + Vector2(0, 0)
		for i in 26:
			var ang := randf() * TAU
			_sparks.append({"p": c + Vector2(randf_range(-80, 80), randf_range(-20, 20)),
				"v": Vector2(cos(ang), sin(ang) - 0.6) * randf_range(60, 200), "life": 1.0})
		face.jump()
	for sp in _sparks:
		sp.p += sp.v * delta
		sp.v.y += 260.0 * delta
		sp.life -= delta * 1.3
	_sparks = _sparks.filter(func(sp): return sp.life > 0.0)
	var sp_pos := _spirit_pos()
	face.position = sp_pos - face.size / 2.0
	queue_redraw()
	if t >= DURATION:
		_go()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and t > 0.3:
		_go()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and t > 0.3:
		_go()


func _go() -> void:
	if _left:
		return
	_left = true
	Game.of(self).tower_continue()


# ---------- 位置 ----------

## 鏡頭：0 → 1 的時候從「from 那層」移到「to 那層」（先停一下、再滑上去、最後回彈一點點）
func _cam_k() -> float:
	var u := clampf((t - 0.35) / 0.85, 0.0, 1.0)
	return 1.0 - pow(1.0 - u, 3.0) * (1.0 + 1.6 * u)


func _cam_floor() -> float:
	return lerpf(float(from_floor), float(to_floor), clampf(_cam_k(), 0.0, 1.05))


## 某一層的中心（畫面座標）：鏡頭對準的樓層在畫面中間偏下
func _floor_center(f: int) -> Vector2:
	return Vector2(size.x * 0.5, size.y * 0.62 - (float(f) - _cam_floor()) * FLOOR_H)


func _spirit_pos() -> Vector2:
	# 從 from 那層的左邊跳到 to 那層：一段拋物線
	var u := clampf((t - 0.4) / 0.75, 0.0, 1.0)
	var a := _floor_center(from_floor) + Vector2(-150, 8)
	var b := _floor_center(to_floor) + Vector2(-150, 8)
	var p := a.lerp(b, u)
	p.y -= sin(u * PI) * 70.0
	p.y += sin(t * 3.0) * 3.0 if u >= 1.0 else 0.0
	return p


# ---------- 繪圖 ----------

func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([Color("120c2e"), Color("120c2e"), Color("2a1630"), Color("2a1630")]))
	# 星星跟著鏡頭慢慢往下飄（視差）
	var drift := (_cam_floor() - float(from_floor)) * 30.0
	for s in _sky:
		var y := fposmod(s.p.y + drift, h)
		UITheme.dot(self, Vector2(s.p.x, y), s.s, Color(1, 0.88, 0.95, 0.2 + 0.25 * sin(t * 1.5 + s.ph)))
	var font := get_theme_default_font()
	# 塔：畫目前畫面看得到的樓層
	var lo := int(floor(_cam_floor())) - 4
	var hi := int(ceil(_cam_floor())) + 5
	for f in range(maxi(1, lo), hi):
		_draw_floor(font, f)
	# 塔底（第 1 層以下是地面）
	var ground := _floor_center(1).y + FLOOR_H / 2.0
	if ground < h:
		draw_rect(Rect2(0, ground, w, h - ground), Color(0.06, 0.1, 0.2))
		draw_line(Vector2(0, ground), Vector2(w, ground), Color(0.6, 0.85, 1.0, 0.25), 2.0)
	for sp in _sparks:
		UITheme.dot(self, sp.p, 2.0 + 2.5 * sp.life, Color(1, 0.85, 0.45, sp.life))
	_draw_hud(font)


func _draw_floor(font: Font, f: int) -> void:
	var c := _floor_center(f)
	var half := 150.0 + (10.0 if f % 5 == 0 else 0.0)
	var y0 := c.y - FLOOR_H / 2.0
	var y1 := c.y + FLOOR_H / 2.0
	var lit := f < to_floor or (f == to_floor and t >= 1.15)
	var body := Color("2a2f5e") if not lit else Color("3b3270")
	if f % 5 == 0:
		body = body.lightened(0.08)
	draw_colored_polygon(PackedVector2Array([Vector2(c.x - half, y1), Vector2(c.x + half, y1),
		Vector2(c.x + half * 0.97, y0), Vector2(c.x - half * 0.97, y0)]), body)
	draw_line(Vector2(c.x - half, y1), Vector2(c.x + half, y1), Color(0, 0, 0, 0.4), 3.0)
	# 窗戶：新的那層亮起來時先閃一下
	var flash := 0.0
	if f == to_floor and t >= 1.15:
		flash = clampf(1.0 - (t - 1.15) / 0.5, 0.0, 1.0)
	for j in 4:
		var wx := c.x - half * 0.66 + j * half * 0.44
		var wr := Rect2(wx - 13, y0 + 22, 26, FLOOR_H - 40)
		if lit:
			draw_rect(wr.grow(10), Color(1, 0.85, 0.45, 0.08 + 0.3 * flash))
			draw_rect(wr, Color(1, 0.85 + 0.15 * flash, 0.45 + 0.5 * flash, 0.95))
		else:
			draw_rect(wr, Color(0.25, 0.28, 0.5, 0.7))
	# 樓層號碼
	var tc := Color(1, 0.88, 0.55) if lit else Color(0.7, 0.74, 0.9, 0.6)
	draw_string(font, Vector2(c.x + half + 16, c.y + 8), "%d F" % f, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(22), tc)
	var tag_y := c.y + 32.0
	if f % 5 == 0:
		draw_string(font, Vector2(c.x + half + 16, tag_y), "試煉層", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), Color(1, 0.55, 0.6, 0.9))
		tag_y += 20.0
	if f == best and best > 0 and f >= to_floor:
		draw_string(font, Vector2(c.x + half + 16, tag_y), "最高紀錄", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14), Color(1, 0.88, 0.55, 0.8))


func _draw_hud(font: Font) -> void:
	var w := size.x
	# 左邊空白處：大大的樓層數，到了之後翻成新的數字
	var col_w := size.x * 0.5 - 190.0
	var k := clampf((t - 1.1) / 0.25, 0.0, 1.0)
	var pop := 1.0 + 0.25 * sin(k * PI)
	var num := to_floor if t >= 1.1 else from_floor
	var cy := size.y * 0.42
	draw_string(font, Vector2(0, cy - 70), "終焉之塔", HORIZONTAL_ALIGNMENT_CENTER, col_w, UITheme.fs(18), Color("ff8fa0"))
	draw_string(font, Vector2(0, cy), "第 %d 層" % num, HORIZONTAL_ALIGNMENT_CENTER, col_w, int(52 * pop), UITheme.ACCENT)
	var sub := "往上爬！"
	var sub_c := Color(1, 1, 1, 0.8)
	if t >= 1.15:
		if to_floor % 5 == 0:
			sub = "這一層是試煉層，小心！"
			sub_c = Color("ff8fa0")
		elif to_floor > best and best > 0:
			sub = "新紀錄！"
			sub_c = UITheme.ACCENT
		else:
			sub = "繼續往上爬！"
	draw_string(font, Vector2(0, cy + 46), sub, HORIZONTAL_ALIGNMENT_CENTER, col_w, UITheme.fs(20), sub_c)
	# 剛剛那一層拿到的星星
	var st := ("★".repeat(stars) + "☆".repeat(3 - stars)) if stars > 0 else "示範通過"
	draw_string(font, Vector2(0, cy + 100), "第 %d 層　%s" % [from_floor, st], HORIZONTAL_ALIGNMENT_CENTER, col_w, UITheme.fs(18),
		Color(1, 0.88, 0.55, 0.85))
	# 右上：剩下的心
	var hs := "♥".repeat(clampi(hearts, 0, 3)) + "♡".repeat(clampi(3 - hearts, 0, 3))
	draw_string(font, Vector2(w - 160, 50), hs, HORIZONTAL_ALIGNMENT_RIGHT, 124, UITheme.fs(26), UITheme.PINK)
	if t > 0.8:
		draw_string(font, Vector2(0, size.y - 30), "點一下繼續", HORIZONTAL_ALIGNMENT_CENTER, col_w, UITheme.fs(15),
			Color(1, 1, 1, 0.35 + 0.15 * sin(t * 4.0)))
