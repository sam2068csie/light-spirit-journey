extends "res://data/maps/unit_map_base.gd"
## 高二「平面向量」的世界地圖：箭羽高原（光潮群島的 3 號島，g11_sea.gd）
##   ・圓圓的台地，上面的田沿著兩個方向排成平行四邊形（斜方格）
##   ・主路是 8 支「首尾相接」的箭頭：每座聖地是一支箭頭的起點，下一座聖地在它的箭頭尖端（2026/11/21 使用者選的 A 案）
##     V1 風向台 → … → V8（ALL_SITES），最後一支箭頭指到終焉之塔。只顯示 units.gd 裡已經有的關卡，還沒蓋好的路淡淡的
##   ・一支金色的虛線箭頭從起點直接指到塔：全部箭頭加起來的「合向量」（八座聖地都點亮才亮起來）
##   ・操作、點亮、劇情都在共用底層 unit_map_base.gd；劇情的 key 都加上 "vec2/"
## 劇情文字寫在下面的 STORY，可以直接修改。

const UNIT := "vec2"
const PREFIX := "vec2/"

## 高原的輪廓：圓圓的台地（和光潮群島海圖上的 3 號島一樣），用 island_poly() 產生
const ISLE_C := Vector2(590, 372)
const ISLE_R := Vector2(540, 272)
## 斜方格田的兩個方向
const DIR_A := Vector2(70, -22)
const DIR_B := Vector2(26, 58)

## 八座聖地：每一座是一支箭頭的起點，箭頭一支接一支（首尾相接），最後一支的箭頭尖端是終焉之塔
## （p 是位置，lab 是名牌的位置）
const ALL_SITES := [
	{"id": "V1", "p": Vector2(150, 500), "lab": Vector2(0, 64)},
	{"id": "V2", "p": Vector2(290, 440), "lab": Vector2(0, 64)},
	{"id": "V3", "p": Vector2(320, 320), "lab": Vector2(0, -88)},
	{"id": "V4", "p": Vector2(450, 352), "lab": Vector2(0, 64)},
	{"id": "V5", "p": Vector2(540, 240), "lab": Vector2(0, -88)},
	{"id": "V6", "p": Vector2(670, 312), "lab": Vector2(0, 64)},
	{"id": "V7", "p": Vector2(760, 214), "lab": Vector2(0, -88)},
	{"id": "V8", "p": Vector2(880, 266), "lab": Vector2(0, 64)},
]
const R := 44.0

## 終焉之塔：最後一支箭頭的尖端
const TOWER_P := Vector2(965, 205)

const STORY := {
	"prologue": [
		{"text": "光潮群島的東北邊，有一座像箭一樣的高原——「箭羽高原」。", "cam": "wide"},
		{"text": "高原上的田沿著兩個方向排成斜斜的格子，風一吹，芒草像箭羽一樣倒向同一邊。", "cam": "isle0", "zoom": 1.3},
		{"text": "可是風向台的旗子都垂下來了，沒有風，風箏飛不起來……", "cam": "wide"},
		{"text": "一支箭頭就是一陣風耶！往哪吹、吹多大，都畫在箭頭上。我們把風找回來吧！", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.7, "spirit": 0, "appear": true},
	],
	"V1": [
		{"text": "風向台的旗子揚起來了。一樣的風，不管從哪裡吹起都一樣。兩陣風首尾接起來，就是合起來的風。", "cam": "site", "site": 0, "zoom": 1.8, "light": 0},
		{"text": "繩橋上的珠子也穿好了——靠近誰，誰的係數就大！沿著箭頭往前走吧～", "who": "光靈", "cam": "site", "site": 1, "zoom": 1.4, "spirit": 1},
	],
	"V2": [
		{"text": "斜紋麥田的稻子長出來了。每一塊田都有斜斜的地址：沿 AB 方向走 x 格、沿 AC 方向走 y 格。", "cam": "site", "site": 1, "zoom": 1.8, "light": 1},
		{"text": "x + y = 1 就在直線 BC 上！田埂上的烽台也亮了，坐標一個一個寫好囉～", "who": "光靈", "cam": "site", "site": 1, "zoom": 1.4, "spirit": 1},
	],
	"V3": [
		{"text": "日晷的指針投下影子了。太陽從正上方照下來，箭頭落在地上的影子，量的是它朝那個方向走了多遠。", "cam": "site", "site": 2, "zoom": 1.8, "light": 2},
		{"text": "影子乘上地面那支箭頭的長，就是內積！竿子站直的時候內積是 0～", "who": "光靈", "cam": "site", "site": 2, "zoom": 1.4, "spirit": 2},
	],
}

const STORY_TITLES := {"prologue": "序章．沒有風的高原", "V1": "第一幕．風向台", "V2": "第二幕．斜紋麥田", "V3": "第三幕．日晷影場", "epilogue": "終章．平面向量"}


static func sites() -> Array:
	var ids := Units.level_ids(UNIT)
	return ALL_SITES.filter(func(s): return ids.has(String(s.id)))


func _init() -> void:
	m_sites = sites()
	m_story = STORY
	m_titles = STORY_TITLES
	m_prefix = PREFIX
	m_unit = UNIT
	m_tower = TOWER_P


static func site_point(i: int) -> Vector2:
	return Vector2(sites()[i].p)


func _site_p(i: int) -> Vector2:
	return site_point(i)

func _label_p(i: int) -> Vector2:
	return site_point(i) + Vector2(m_sites[i].lab)

func _hover_p(i: int) -> Vector2:
	return site_point(i) + Vector2(0, -56)

func _region(p: Vector2) -> int:
	for i in m_sites.size():
		if p.distance_to(site_point(i)) < R:
			return i
	return -1

func _isle_target(k: int) -> Vector2:
	return Vector2(300, 470) if k == 0 else Vector2(820, 240)


func _rand_point(i: int) -> Vector2:
	var a := randf() * TAU
	return site_point(i) + Vector2(cos(a), sin(a) * 0.5) * randf_range(4.0, R - 12.0)


## 旅程路線：沿著那一支箭頭走
func _route(i: int) -> PackedVector2Array:
	return PackedVector2Array([site_point(i), site_point(i + 1)])


## 第 k 支箭頭的起點、終點（k = 0～7；最後一支指到塔）
static func arrow_ends(k: int) -> Array:
	var a: Vector2 = ALL_SITES[k].p
	var b: Vector2 = ALL_SITES[k + 1].p if k + 1 < ALL_SITES.size() else TOWER_P
	return [a, b]


## 台地的輪廓（固定的亂數，每次都一樣）
static func island_poly() -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := 64
	for i in n:
		var a := TAU * i / n
		var r := 1.0 + 0.05 * sin(3.0 * a + 5.0) + 0.03 * sin(7.0 * a + 10.0) + 0.015 * sin(13.0 * a + 2.0)
		out.append(ISLE_C + Vector2(cos(a) * ISLE_R.x, sin(a) * ISLE_R.y) * r)
	return out


# ================= 繪圖 =================

const LAND := Color("26584f")
const CLIFF := Color("1a3a3c")
const CLIFF2 := Color("1f4a48")
const CROPS := [Color("d8b45a"), Color("8fa24e"), Color("a990c8"), Color("c48a4a"), Color("6aa0b0")]
const ROAD_A := Color("78d7ff")
const ROAD_B := Color("ff96c8")
const GOLD := Color("ffdc8c")


func _draw_land(layer: CanvasItem) -> void:
	_tgt = layer
	var L := layer
	var isle := island_poly()
	# 崖壁：往下錯開兩層，比較暗
	L.draw_colored_polygon(_shift(isle, Vector2(0, 16)), CLIFF)
	L.draw_colored_polygon(_shift(isle, Vector2(0, 8)), CLIFF2)
	L.draw_colored_polygon(isle, LAND)
	# 斜方格的田：沿著 DIR_A、DIR_B 排成平行四邊形，切在台地裡面
	var inner := PackedVector2Array()
	for p in isle:
		inner.append(ISLE_C + (p - ISLE_C) * 0.95)
	for i in range(-10, 11):
		for j in range(-6, 7):
			if posmod(i * 7 + j * 3, 5) == 0:
				continue
			var o := ISLE_C + DIR_A * i + DIR_B * j
			var cell := PackedVector2Array([o, o + DIR_A, o + DIR_A + DIR_B, o + DIR_B])
			var ctr := o + (DIR_A + DIR_B) / 2.0
			var sh := PackedVector2Array()
			for q in cell:
				sh.append(ctr + (q - ctr) * 0.86)
			for pc in Geometry2D.intersect_polygons(sh, inner):
				var c: Color = CROPS[posmod(i * 2 + j * 3, CROPS.size())]
				L.draw_colored_polygon(pc, Color(c.r, c.g, c.b, 0.13))
	var closed := isle.duplicate()
	closed.append(isle[0])
	L.draw_polyline(closed, Color(0.45, 0.85, 0.85, 0.75), 2.5, true)
	# 塔的平台
	UITheme.dot(L, TOWER_P + Vector2(0, 6), 40.0, Color(0.5, 0.9, 1.0, 0.07))
	UITheme.dot(L, TOWER_P + Vector2(0, 4), 28.0, Color("2f6a63"))
	for i in m_sites.size():
		_draw_region_fill(L, i)
	_draw_details(L)
	_tgt = self


static func _shift(poly: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(p + d)
	return out


## 一支箭頭（寬的發光路面＋三角形的頭）。lit：0～1 亮的程度
func _road_arrow(a: Vector2, b: Vector2, col: Color, lit: float) -> void:
	var d := b - a
	var L := d.length()
	if L < 1.0:
		return
	var u := d / L
	var n := Vector2(-u.y, u.x)
	var hl := 24.0
	var base := b - u * hl
	var a0 := a + u * 10.0
	var c := Color(col.r, col.g, col.b, 0.25 + 0.75 * lit)
	if lit > 0.05:
		_tgt.draw_line(a0, base, Color(col.r, col.g, col.b, 0.18 * lit), 22.0, true)
	_tgt.draw_line(a0, base + u * 2.0, Color(0, 0, 0, 0.25), 11.0, true)
	_tgt.draw_line(a0, base + u * 2.0, c, 8.0, true)
	_tgt.draw_colored_polygon(PackedVector2Array([b, base + n * 13.0, base - n * 13.0]), c)
	# 路面上一顆一顆往前流的光點
	if lit > 0.5:
		for k in 3:
			var ph := fposmod(t * 0.35 + k / 3.0, 1.0)
			UITheme.dot(_tgt, a0.lerp(base, ph), 2.6, Color(1, 1, 1, 0.7 * sin(ph * PI)))


## 合向量：起點到塔的金色虛線箭頭
func _resultant(lit: float) -> void:
	var a: Vector2 = ALL_SITES[0].p
	var b := TOWER_P
	var d := b - a
	var L := d.length()
	var u := d / L
	var n := Vector2(-u.y, u.x)
	var hl := 26.0
	var col := Color(GOLD.r, GOLD.g, GOLD.b, 0.22 + 0.6 * lit)
	var s := 12.0
	while s < L - hl:
		var e := minf(s + 14.0, L - hl)
		_tgt.draw_line(a + u * s, a + u * e, col, 3.5, true)
		s += 28.0
	var base := b - u * hl
	_tgt.draw_colored_polygon(PackedVector2Array([b - u * 6.0, base + n * 11.0, base - n * 11.0]), col)


func _draw_region_fill(L: CanvasItem, i: int) -> void:
	var gl: float = glow[i]
	var c: Color = Center.level_info(m_sites[i].id).color
	var p := site_point(i)
	var pts := PackedVector2Array()
	for k in 33:
		var a := TAU * k / 32.0
		pts.append(p + Vector2(cos(a) * R, sin(a) * R * 0.5))
	L.draw_colored_polygon(pts, Color(0.15, 0.25, 0.28, 0.6).lerp(Color(c.r, c.g, c.b, 0.3), gl))


func _draw_region_ring(i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var c: Color = Center.level_info(m_sites[i].id).color
	var pulse := 0.85 + 0.15 * sin(t * 2.0 + i)
	var p := site_point(i)
	var pts := PackedVector2Array()
	for k in 49:
		var a := TAU * k / 48.0
		pts.append(p + Vector2(cos(a) * R, sin(a) * R * 0.5))
	_tgt.draw_polyline(pts, Color(c.r, c.g, c.b, 0.25 * gl * pulse), 7.0)
	_tgt.draw_polyline(pts, Color(c.r, c.g, c.b, 0.9 * gl).lightened(0.3), 2.0, true)


## 高原上的芒草（像箭羽）
func _make_details() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 73
	var mesa := island_poly()
	for k in 36:
		var p := Vector2(rng.randf_range(80, 1090), rng.randf_range(80, 600))
		if not Geometry2D.is_point_in_polygon(p, mesa) or p.distance_to(TOWER_P) < 50.0:
			continue
		var near := false
		for j in m_sites.size():
			if p.distance_to(site_point(j)) < R + 20.0 or p.distance_to(_label_p(j)) < 46.0:
				near = true
		if not near:
			out.append({"p": p, "si": 0, "k": k})
	return out


## 首尾相接的箭頭路、合向量（畫在聖地的地標底下）
func _fx_under() -> void:
	var all_done := m_sites.size() == ALL_SITES.size() and not done.has(false)
	_resultant(1.0 if all_done else 0.0)
	for k in ALL_SITES.size():
		var e := arrow_ends(k)
		var lit := 0.0
		if k < m_sites.size():
			lit = clampf(0.7 + 0.3 * glow[k], 0.0, 1.0)
		_road_arrow(e[0], e[1], ROAD_A if k % 2 == 0 else ROAD_B, lit)
	# 還沒蓋好的聖地：箭頭接點上一個淡淡的圈
	for k in range(m_sites.size(), ALL_SITES.size()):
		var p: Vector2 = ALL_SITES[k].p
		var pts := PackedVector2Array()
		for q in 25:
			var ang := TAU * q / 24.0
			pts.append(p + Vector2(cos(ang) * 22.0, sin(ang) * 8.0))
		_tgt.draw_polyline(pts, Color(1, 1, 1, 0.18), 1.5, true)


## 聖地的地標：V1 是插著風向旗的石台，旗子點亮後會飄起來
func _draw_landmark(i: int) -> void:
	var col: Color = Center.level_info(m_sites[i].id).color
	var gl: float = glow[i]
	var p := site_point(i) + Vector2(0, -4)
	var Tg := _tgt
	var base := Color("3e5a66").lerp(col.darkened(0.15), clampf(0.15 + 0.75 * gl, 0.0, 1.0))
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
		Tg.draw_polyline(pts, Color(0.6, 0.95, 1.0, 0.5 + 0.3 * sin(t * 4.0)), 2.0, true)
	if gl > 0.05:
		UITheme.dot(Tg, p + Vector2(0, -24), 40.0, Color(col.r, col.g, col.b, 0.07 * gl))
	# 石台
	Tg.draw_rect(Rect2(p + Vector2(-18, -10), Vector2(36, 10)), base.lightened(0.1))
	if String(m_sites[i].id) == "V3":
		# 日晷：斜斜的指針，亮了之後地上有一道影子
		var dial := PackedVector2Array()
		for k in 25:
			var ang := TAU * k / 24.0
			dial.append(p + Vector2(cos(ang) * 20.0, sin(ang) * 6.0 - 12.0))
		Tg.draw_colored_polygon(dial, base.lightened(0.2))
		if gl > 0.5:
			Tg.draw_line(p + Vector2(0, -12), p + Vector2(18, -9), Color(0.1, 0.1, 0.15, 0.55), 3.0)
		Tg.draw_colored_polygon(PackedVector2Array([p + Vector2(-2, -12), p + Vector2(-2, -40), p + Vector2(12, -12)]), lit_c)
		return
	# 旗桿和旗子：亮了就迎風飄
	Tg.draw_line(p + Vector2(0, -10), p + Vector2(0, -50), base.lightened(0.3), 2.5)
	var flap := (6.0 * sin(t * 5.0)) if gl > 0.5 else 0.0
	var fl := PackedVector2Array([p + Vector2(0, -50), p + Vector2(26, -44 + flap * 0.3), p + Vector2(0, -36)]) if gl > 0.5 \
		else PackedVector2Array([p + Vector2(0, -50), p + Vector2(6, -32), p + Vector2(0, -34)])
	Tg.draw_colored_polygon(fl, lit_c)


func _draw_names(font: Font) -> void:
	UITheme.text_ol(_tgt, font, Vector2(60, 96), "箭羽高原", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(30), Color(0.6, 0.92, 1.0, 0.88), 6)


## 旅程路線就是首尾相接的箭頭（_fx_under 畫了），不用再畫一條虛線
func _draw_path() -> void:
	pass
