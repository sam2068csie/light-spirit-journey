extends "res://data/maps/unit_map_base.gd"
## 高一「指數與常用對數」的世界地圖：倍增峽谷
##   ・峽谷的岩壁一層一層往下，每往下一層，那一層岩石的厚度就加倍（指數）
##   ・一條小路從左上的崖頂繞下谷底，三座聖地由上往下：E1 倍增岩壁 → E2 十倍石階 → E3 深谷測繩
##   ・右上的平台上立著終焉之塔（三座聖地蓋好後開放）
##   ・操作、點亮、劇情都在共用底層 unit_map_base.gd；劇情的 key 都加上 "h1exp/"
## 劇情文字寫在下面的 STORY，可以直接修改。

const UNIT := "h1exp"
const PREFIX := "h1exp/"

# ---------------- 地形 ----------------
## 峽谷的輪廓（外圍的高原）
const RIM := [Vector2(30, 120), Vector2(240, 70), Vector2(560, 60), Vector2(860, 80), Vector2(1120, 110),
	Vector2(1130, 600), Vector2(820, 630), Vector2(420, 625), Vector2(60, 600)]
## 谷底（深的那一塊）：左上窄、右下寬
const FLOOR := [Vector2(150, 190), Vector2(420, 230), Vector2(700, 330), Vector2(1000, 440), Vector2(1060, 560),
	Vector2(760, 590), Vector2(430, 520), Vector2(180, 330)]
## 每往下一層，岩層的厚度加倍
const STRATA := [10.0, 20.0, 40.0, 80.0, 160.0, 320.0]
const STRATA_Y0 := 120.0

## 三座聖地：p 是位置，lab 是名牌的位置（相對聖地）
const SITES := [
	{"id": "E1", "p": Vector2(270, 250), "lab": Vector2(0, -92)},
	{"id": "E2", "p": Vector2(580, 380), "lab": Vector2(0, 84)},
	{"id": "E3", "p": Vector2(880, 500), "lab": Vector2(0, -92)},
]
const R := 62.0                   # 每座聖地的範圍

## 終焉之塔：右上的平台
const TOWER_P := Vector2(1010, 210)
const MESA_R := 60.0

## 劇情：每一句 {text, who, cam（"wide"、"site"、"isle0" 左半邊、"isle1" 右半邊）, site, zoom, light, spirit}
const STORY := {
	"prologue": [
		{"text": "曦光大陸的北邊，大地裂開一道深深的峽谷——「倍增峽谷」。", "cam": "wide"},
		{"text": "峽谷的岩壁一層一層，越往下，每一層岩石就越厚，厚度一層一層加倍。", "cam": "isle0", "zoom": 1.3},
		{"text": "可是岩壁上的光柱都熄了，谷底黑漆漆的……", "cam": "wide"},
		{"text": "岩壁上刻著好多次方耶！2 的 3 次方、9 的負二分之三次方……把它們拼起來，光柱就會亮吧？", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.7, "spirit": 0, "appear": true},
		{"text": "先從崖頂的岩壁開始吧～", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.5},
	],
	"E1": [
		{"text": "倍增岩壁的光柱亮起來了。每個數都拆成質數的次方，指數一加，光柱就長到那一層。", "cam": "site", "site": 0, "zoom": 1.8, "light": 0},
		{"text": "一張紙對折 42 次就到月球——倍增好可怕！下面的石階，好像每一階都是 10 倍～", "who": "光靈", "cam": "site", "site": 1, "zoom": 1.4, "spirit": 1},
	],
	"E2": [
		{"text": "十倍石階亮了。log x 就是 x 站在第幾階。", "cam": "site", "site": 1, "zoom": 1.8, "light": 1},
		{"text": "乘法變成往上走、除法變成往下走——最後一站在谷底！", "who": "光靈", "cam": "site", "site": 2, "zoom": 1.4, "spirit": 2},
	],
	"E3": [
		{"text": "深谷的測繩放到底了。log 的整數部分告訴我們有幾位數。", "cam": "site", "site": 2, "zoom": 1.7, "light": 2},
		{"text": "尾數落在 log 2 和 log 3 之間，最高位就是 2！", "who": "光靈", "cam": "site", "site": 2, "zoom": 1.5},
	],
}

const STORY_TITLES := {"prologue": "序章．加倍的岩層", "E1": "第一幕．倍增岩壁", "E2": "第二幕．十倍石階",
	"E3": "第三幕．深谷測繩", "epilogue": "終章．指數與常用對數"}


func _init() -> void:
	m_sites = SITES
	m_story = STORY
	m_titles = STORY_TITLES
	m_prefix = PREFIX
	m_unit = UNIT
	m_tower = TOWER_P


func _site_p(i: int) -> Vector2:
	return site_point(i)

func _label_p(i: int) -> Vector2:
	return site_point(i) + Vector2(SITES[i].lab)

func _hover_p(i: int) -> Vector2:
	return site_point(i) + Vector2(0, -60)

func _region(p: Vector2) -> int:
	return region_at(p)

func _isle_target(k: int) -> Vector2:
	return Vector2(360, 300) if k == 0 else Vector2(800, 420)


static func site_point(i: int) -> Vector2:
	return Vector2(SITES[i].p)


## 這一點在哪一座聖地（−1：其他地方）
static func region_at(p: Vector2) -> int:
	for i in SITES.size():
		if p.distance_to(site_point(i)) < R:
			return i
	return -1


static func near_site(p: Vector2) -> int:
	var best := 0
	for i in SITES.size():
		if p.distance_to(site_point(i)) < p.distance_to(site_point(best)):
			best = i
	return best


func _rand_point(i: int) -> Vector2:
	var a := randf() * TAU
	return site_point(i) + Vector2(cos(a), sin(a) * 0.5) * randf_range(4.0, R - 12.0)


# ================= 繪圖 =================

const LAND := Color("2c2636")
const HIGH := Color("372f44")
const ROCK := Color("4a3a3a")
const TRAIL := Color(0.95, 0.75, 0.5, 0.35)


func _draw_land(layer: CanvasItem) -> void:
	_tgt = layer
	var L := layer
	var rim := PackedVector2Array(RIM)
	var c0 := Vector2(580, 360)
	var big := PackedVector2Array()
	for p in rim:
		big.append(p + (p - c0).normalized() * 16.0)
	L.draw_colored_polygon(big, Color(1.0, 0.65, 0.4, 0.05))
	L.draw_colored_polygon(rim, LAND)
	var inner := PackedVector2Array()
	for p in rim:
		inner.append(c0 + (p - c0) * 0.94)
	L.draw_colored_polygon(inner, HIGH)
	# 岩層：每往下一層，厚度加倍（顏色一深一淺交替）
	var y := STRATA_Y0
	for k in STRATA.size():
		var h: float = STRATA[k]
		var band := PackedVector2Array([Vector2(40, y), Vector2(1120, y), Vector2(1120, y + h), Vector2(40, y + h)])
		var clip := Geometry2D.intersect_polygons(band, inner)
		var col := ROCK.lightened(0.06 * float(k % 2)).darkened(0.05 * k)
		for poly in clip:
			L.draw_colored_polygon(poly, Color(col.r, col.g, col.b, 0.55))
		L.draw_line(Vector2(60, y), Vector2(1110, y), Color(1, 0.8, 0.6, 0.08), 1.0)
		y += h
	# 谷底：更深的一塊
	L.draw_colored_polygon(PackedVector2Array(FLOOR), Color(0.08, 0.06, 0.12, 0.55))
	var fl := PackedVector2Array(FLOOR)
	fl.append(FLOOR[0])
	L.draw_polyline(fl, Color(1, 0.75, 0.5, 0.18), 2.0, true)
	var closed := rim.duplicate()
	closed.append(rim[0])
	L.draw_polyline(closed, Color(1, 0.75, 0.5, 0.3), 3.0, true)
	# 平台（終焉之塔）
	UITheme.dot(L, TOWER_P + Vector2(0, 10), MESA_R + 12.0, Color(1, 0.7, 0.45, 0.06))
	UITheme.dot(L, TOWER_P + Vector2(0, 10), MESA_R, Color("3a3046"))
	UITheme.dot(L, TOWER_P + Vector2(0, 6), MESA_R - 14.0, Color("463a54"))
	# 小路：從崖頂繞下谷底
	for i in SITES.size() - 1:
		var pts := _route(i)
		L.draw_polyline(pts, Color(0, 0, 0, 0.25), 12.0, true)
		L.draw_polyline(pts, TRAIL, 6.0, true)
	for i in SITES.size():
		_draw_region_fill(L, i)
	_draw_details(L)
	_tgt = self


func _draw_region_fill(L: CanvasItem, i: int) -> void:
	var gl: float = glow[i]
	var c: Color = Center.level_info(SITES[i].id).color
	var p := site_point(i)
	var pts := PackedVector2Array()
	for k in 33:
		var a := TAU * k / 32.0
		pts.append(p + Vector2(cos(a) * R, sin(a) * R * 0.5))
	L.draw_colored_polygon(pts, Color(0.2, 0.17, 0.25, 0.6).lerp(Color(c.r, c.g, c.b, 0.3), gl))


func _draw_region_ring(i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var c: Color = Center.level_info(SITES[i].id).color
	var pulse := 0.85 + 0.15 * sin(t * 2.0 + i)
	var p := site_point(i)
	var pts := PackedVector2Array()
	for k in 49:
		var a := TAU * k / 48.0
		pts.append(p + Vector2(cos(a) * R, sin(a) * R * 0.5))
	_tgt.draw_polyline(pts, Color(c.r, c.g, c.b, 0.25 * gl * pulse), 7.0)
	_tgt.draw_polyline(pts, Color(c.r, c.g, c.b, 0.9 * gl).lightened(0.3), 2.0, true)


func _make_details() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	var rim := PackedVector2Array(RIM)
	for k in 90:
		var p := Vector2(rng.randf_range(50, 1110), rng.randf_range(90, 610))
		if not Geometry2D.is_point_in_polygon(p, rim) or p.distance_to(TOWER_P) < MESA_R + 10.0:
			continue
		var near := false
		for j in SITES.size():
			if p.distance_to(site_point(j)) < R + 24.0 or p.distance_to(_label_p(j)) < 50.0:
				near = true
		if not near:
			out.append({"p": p, "si": near_site(p), "k": k})
	return out


## 旅程路線：之字形往下
func _route(i: int) -> PackedVector2Array:
	var a := site_point(i)
	var b := site_point(i + 1)
	var m := a.lerp(b, 0.5) + Vector2(-40, 30) if i == 0 else a.lerp(b, 0.5) + Vector2(40, -20)
	return PackedVector2Array([a, m, b])


## 小石子從岩壁上滾下來
func _fx_under() -> void:
	for k in 4:
		var ph := fposmod(t * 0.25 + k * 0.25, 1.0)
		var x := 150.0 + k * 250.0
		var y := lerpf(130.0, 420.0, ph * ph)
		UITheme.dot(_tgt, Vector2(x + 10.0 * sin(t + k), y), 1.8, Color(1, 0.8, 0.6, 0.25 * (1.0 - ph)))


## 三座聖地的地標
func _draw_landmark(i: int) -> void:
	var col: Color = Center.level_info(SITES[i].id).color
	var gl: float = glow[i]
	var p := site_point(i) + Vector2(0, -4)
	var Tg := _tgt
	var base := Color("4a4466").lerp(col.darkened(0.15), clampf(0.15 + 0.75 * gl, 0.0, 1.0))
	var lit_c := Color(col.r, col.g, col.b, 0.25 + 0.75 * gl) if gl > 0.05 else base.lightened(0.25)
	var sh := PackedVector2Array()
	for k in 25:
		var ang := TAU * k / 24.0
		sh.append(p + Vector2(cos(ang) * 24.0, sin(ang) * 5.0 + 2.0))
	Tg.draw_colored_polygon(sh, Color(0, 0, 0, 0.25))
	if i == sel and not playing:
		var pts := PackedVector2Array()
		for k in 33:
			var ang := TAU * k / 32.0
			pts.append(site_point(i) + Vector2(cos(ang) * 44.0, sin(ang) * 14.0))
		Tg.draw_polyline(pts, Color(1, 0.85, 0.45, 0.5 + 0.3 * sin(t * 4.0)), 2.0, true)
	if gl > 0.05:
		UITheme.dot(Tg, p + Vector2(0, -24), 40.0, Color(col.r, col.g, col.b, 0.07 * gl))
	match i:
		0:   # 倍增岩壁：三根光柱，高度 1、2、4
			for k in 3:
				var h := 8.0 * pow(2.0, k)
				var x := p.x - 16.0 + k * 14.0
				Tg.draw_rect(Rect2(x, p.y - h, 9.0, h), base.lightened(0.15))
				var lh := h * (0.6 + 0.4 * sin(t * 2.0 + k)) if gl > 0.5 else h * 0.3
				Tg.draw_rect(Rect2(x + 2.0, p.y - lh, 5.0, lh), lit_c)
		1:   # 十倍石階：三階石階
			for k in 3:
				Tg.draw_rect(Rect2(p.x - 20.0 + k * 13.0, p.y - 10.0 - k * 11.0, 14.0, 10.0 + k * 11.0), base.lightened(0.1 + 0.05 * k))
			UITheme.dot(Tg, p + Vector2(18, -38), 3.5 + (1.5 * sin(t * 3.0) if gl > 0.5 else 0.0), lit_c)
		2:   # 深谷測繩：一根柱子垂下一條打結的繩子
			Tg.draw_line(p + Vector2(-14, 0), p + Vector2(-14, -40), base.lightened(0.25), 3.0)
			Tg.draw_line(p + Vector2(-14, -40), p + Vector2(10, -40), base.lightened(0.25), 3.0)
			var len := 34.0 if gl > 0.5 else 14.0
			Tg.draw_line(p + Vector2(10, -40), p + Vector2(10, -40 + len), lit_c, 1.5)
			var k := 0.0
			while k < len:
				UITheme.dot(Tg, p + Vector2(10, -40 + k), 2.0, lit_c)
				k += 7.0


func _draw_names(font: Font) -> void:
	UITheme.text_ol(_tgt, font, Vector2(52, 112), "倍增峽谷", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(30), Color(1.0, 0.72, 0.48, 0.88), 6)
