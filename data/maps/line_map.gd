extends "res://data/maps/unit_map_base.gd"
## 直線與圓的世界地圖：圓規湖
##   ・左邊是坐標平原：地上刻著淡淡的方格，一條筆直的棧道斜斜地穿過平原（直線的四關，由左下往右上 1 → 4）
##   ・棧道走出平原後變成木橋，剛好「切」到圓規湖的湖岸：棧道就是湖的切線
##   ・圓規湖是一個正圓：湖岸一圈是圓的四關，從切點開始順著湖岸繞一圈 5 → 8
##   ・湖中央的小島就是圓心，立著終焉之塔；一把巨大的圓規一腳插在圓心、一腳畫著湖岸
##   ・操作、點亮、劇情都在共用底層 unit_map_base.gd；劇情的 key 都加上 "line/"
## 劇情文字寫在下面的 STORY，可以直接修改。

const UNIT := "h1line"
const PREFIX := "line/"

# ---------------- 地形 ----------------
## 圓規湖（圓）
const O := Vector2(800, 300)      # 圓心＝終焉之塔（右下角留給資訊卡）
const R := 170.0                  # 湖岸中線的半徑
const RW := 40.0                  # 湖岸陸地的寬度
## 棧道：從 E 出發的直線，剛好切圓於 T（切點）
const E := Vector2(60, 560)
const T := Vector2(710.22, 155.64)
const CW := 34.0                  # 棧道的寬度
const LAND_END := 556.0           # 平原到這裡結束，之後是木橋
## 坐標平原的輪廓
const PLAIN := [Vector2(16, 160), Vector2(60, 100), Vector2(250, 84), Vector2(450, 104), Vector2(540, 170), Vector2(574, 252),
	Vector2(560, 360), Vector2(530, 470), Vector2(450, 592), Vector2(250, 618), Vector2(60, 604), Vector2(16, 530)]

## 八座聖地。kind：road（棧道上，x 範圍 x、站在 at）、ring（湖岸上，角度範圍 a（度，畫面座標）、站在 at）
const SITES := [
	{"id": "C1", "kind": "road", "x": Vector2(40.0, 185.0), "at": 128.0, "lab": Vector2(0, -78)},
	{"id": "C2", "kind": "road", "x": Vector2(185.0, 300.0), "at": 245.0, "lab": Vector2(0, -78)},
	{"id": "C3", "kind": "road", "x": Vector2(300.0, 415.0), "at": 360.0, "lab": Vector2(0, -78)},
	{"id": "C4", "kind": "road", "x": Vector2(415.0, LAND_END), "at": 474.0, "lab": Vector2(0, -78)},
	{"id": "C5", "kind": "ring", "a": Vector2(238.0, 328.0), "at": 276.0, "lab": Vector2(-36, -70)},
	{"id": "C6", "kind": "ring", "a": Vector2(328.0, 418.0), "at": 14.0, "lab": Vector2(66, -42)},
	{"id": "C7", "kind": "ring", "a": Vector2(418.0, 508.0), "at": 98.0, "lab": Vector2(0, -78)},
	{"id": "C8", "kind": "ring", "a": Vector2(508.0, 598.0), "at": 196.0, "lab": Vector2(-28, 66)},
]

## 終焉之塔：湖中央的小島（圓心）
const TOWER_P := O + Vector2(0, 8)
const ISLE_R := 40.0

## 劇情：每一句 {text, who, cam（"wide"、"site"、"isle0" 坐標平原、"isle1" 圓規湖）, site, zoom, light, spirit}
const STORY := {
	"prologue": [
		{"text": "曦光大陸的東北邊，有一座圓得不可思議的湖。傳說是一把巨大的圓規，一腳插在湖心，一腳畫出了湖岸——人們叫它「圓規湖」。", "cam": "wide"},
		{"text": "湖的西邊是坐標平原，地上刻滿了整整齊齊的方格。一條筆直的棧道穿過平原，剛好碰到湖岸的一點。", "cam": "isle0", "zoom": 1.3},
		{"text": "可是燈標一盞一盞熄滅了。方格看不清楚，棧道歪了，連湖岸都變得模模糊糊……", "cam": "wide"},
		{"text": "哇，地上都是格子！每一個交叉點都有自己的名字，像 (2, 4)、(−1, 3)……這就是坐標吧？", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.7, "spirit": 0, "appear": true},
		{"text": "先把入口的燈標點亮！聽說要找到「正中間」和「照比例」的位置，燈才會亮起來～", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.5},
	],
	"C1": [
		{"text": "坐標燈標亮了。中點、分點、重心……每一盞燈都落在剛剛好的格子點上。", "cam": "site", "site": 0, "zoom": 1.8, "light": 0},
		{"text": "往右走 1 格、往上走幾格，就是斜率！棧道就在前面，我們沿著它走吧～", "who": "光靈", "cam": "site", "site": 1, "zoom": 1.4, "spirit": 1},
	],
	"C2": [
		{"text": "直線棧橋重新接直了。一個點加一個斜率，就決定了一整條直線。", "cam": "site", "site": 1, "zoom": 1.8, "light": 1},
		{"text": "點斜式、斜截式、截距式……原來同一條直線有好多種寫法！", "who": "光靈", "cam": "site", "site": 2, "zoom": 1.4, "spirit": 2},
	],
	"C3": [
		{"text": "鏡面渡口的水面平靜下來。對稱點、反射的光，都照著直線乖乖排好。", "cam": "site", "site": 2, "zoom": 1.8, "light": 2},
		{"text": "點到直線的距離，就是走最短的那一條垂直的路！", "who": "光靈", "cam": "site", "site": 3, "zoom": 1.4, "spirit": 3},
	],
	"C4": [
		{"text": "棧道把平原分成兩半：一邊的稻田 ax + by + c > 0，另一邊 < 0。", "cam": "site", "site": 3, "zoom": 1.8, "light": 3},
		{"text": "棧道的盡頭是一座木橋，剛好碰到湖岸的一點——這條棧道是圓的切線耶！", "who": "光靈", "cam": "site", "site": 4, "zoom": 1.4, "spirit": 4},
	],
	"C5": [
		{"text": "圓規工坊的大圓規轉了起來：圓心和半徑一確定，圓就畫出來了。", "cam": "site", "site": 4, "zoom": 1.8, "light": 4},
		{"text": "(x − h)² + (y − k)² = r²，圓心 (h, k)、半徑 r！三個點也能決定一個圓喔～", "who": "光靈", "cam": "site", "site": 5, "zoom": 1.4, "spirit": 5},
	],
	"C6": [
		{"text": "湖面的漣漪碰到直線：圓心到直線的距離 d 比半徑小，就割出一條弦。", "cam": "site", "site": 5, "zoom": 1.8, "light": 5},
		{"text": "d < r 相割、d = r 相切、d > r 相離！比一比就知道了～", "who": "光靈", "cam": "site", "site": 6, "zoom": 1.4, "spirit": 6},
	],
	"C7": [
		{"text": "切線燈環亮了。從湖外的一點望向湖岸，兩條切線一樣長。", "cam": "site", "site": 6, "zoom": 1.8, "light": 6},
		{"text": "切線段長的平方，就是代進圓方程式的值！最後一站，星星在轉圈圈！", "who": "光靈", "cam": "site", "site": 7, "zoom": 1.4, "spirit": 7},
	],
	"C8": [
		{"text": "軌跡星環亮了！動點一邊走、一邊留下光的足跡，連起來又是一個圓。", "cam": "site", "site": 7, "zoom": 1.7, "light": 7},
		{"text": "距離比固定的點會排成圓，過兩圓交點的圓有一整族……圓真的到處都是！", "who": "光靈", "cam": "site", "site": 7, "zoom": 1.5},
	],
	"epilogue": [
		{"text": "八座聖地全部點亮，坐標平原的方格和圓規湖的湖岸一起閃閃發光。", "cam": "wide", "all": true},
		{"text": "筆直的棧道輕輕碰著圓圓的湖岸——直線和圓，原來一直在一起。", "cam": "wide"},
		{"text": "圓規湖的紀念品也送到小屋囉！湖中央的終焉之塔，有空也要來挑戰喔～", "who": "光靈", "cam": "wide"},
	],
}

const STORY_TITLES := {"prologue": "序章．圓規畫的湖", "C1": "第一幕．坐標燈標", "C2": "第二幕．直線棧橋",
	"C3": "第三幕．鏡面渡口", "C4": "第四幕．分光稻田", "C5": "第五幕．圓規工坊", "C6": "第六幕．割弦漣漪",
	"C7": "第七幕．切線燈環", "C8": "第八幕．軌跡星環", "epilogue": "終章．直線與圓"}


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
	return label_point(i)

func _hover_p(i: int) -> Vector2:
	return label_point(i) + Vector2(0, -36)

func _region(p: Vector2) -> int:
	return region_at(p)

func _isle_target(k: int) -> Vector2:
	return Vector2(300, 360) if k == 0 else O


# ================= 幾何 =================

## 棧道上 x 處的點
static func road_p(x: float) -> Vector2:
	return E + (T - E) * ((x - E.x) / (T.x - E.x))


## 棧道的方向、法向量（往上那一側）
static func road_d() -> Vector2:
	return (T - E).normalized()


static func road_n() -> Vector2:
	var d := road_d()
	return Vector2(d.y, -d.x)


## 湖岸上角度 a（度，畫面座標：0° 朝右、90° 朝下）的點
static func ring_p(a_deg: float, r: float = R) -> Vector2:
	var a := deg_to_rad(a_deg)
	return O + Vector2(cos(a), sin(a)) * r


static func arc_pts(a0: float, a1: float, r: float, n: int = 0) -> PackedVector2Array:
	if n <= 0:
		n = maxi(6, int(absf(deg_to_rad(a1 - a0)) * r / 6.0))
	var pts := PackedVector2Array()
	for k in n + 1:
		pts.append(ring_p(lerpf(a0, a1, float(k) / n), r))
	return pts


static func site_point(i: int) -> Vector2:
	var st: Dictionary = SITES[i]
	if String(st.kind) == "road":
		return road_p(float(st.at))
	return ring_p(float(st.at))


static func label_point(i: int) -> Vector2:
	return site_point(i) + Vector2(SITES[i].lab)


## 棧道一段的色塊（x 從 a 到 b，半寬 half）
static func road_band(a: float, b: float, half: float) -> PackedVector2Array:
	var n := road_n()
	var p0 := road_p(a)
	var p1 := road_p(b)
	return PackedVector2Array([p0 + n * half, p1 + n * half, p1 - n * half, p0 - n * half])


## 角度換到 [238, 598)（從切點開始繞一圈）
static func _ang(p: Vector2) -> float:
	var a := rad_to_deg(atan2(p.y - O.y, p.x - O.x))
	return fposmod(a - 238.0, 360.0) + 238.0


## 這一點在哪一座聖地（−1：水上或平原的其他地方）
static func region_at(p: Vector2) -> int:
	var d := p.distance_to(O)
	if absf(d - R) <= RW / 2.0 + 2.0:
		var a := _ang(p)
		for i in range(4, SITES.size()):
			var ar: Vector2 = SITES[i].a
			if a >= ar.x and a < ar.y:
				return i
	# 棧道上
	var dd := road_d()
	var rel := p - E
	var along := rel.dot(dd)
	var off := absf(rel.dot(road_n()))
	if off <= CW / 2.0 + 4.0 and along >= 0.0:
		var x := (E + dd * along).x
		for i in 4:
			var xr: Vector2 = SITES[i].x
			if x >= xr.x and x < xr.y:
				return i
	return -1


## 平原上的點靠近哪一座直線的聖地（給樹和石頭染色）
static func plain_site(p: Vector2) -> int:
	for i in 4:
		var xr: Vector2 = SITES[i].x
		if p.x < xr.y:
			return i
	return 3


func _rand_point(i: int) -> Vector2:
	var st: Dictionary = SITES[i]
	if String(st.kind) == "road":
		var x := randf_range(st.x.x + 6.0, st.x.y - 6.0)
		return road_p(x) + road_n() * randf_range(-0.35, 0.35) * CW
	var a := randf_range(st.a.x, st.a.y)
	return ring_p(a, R + randf_range(-0.35, 0.35) * RW)


# ================= 繪圖 =================

const LAND := Color("1f2b47")
const HIGH := Color("27375a")
const SAND := Color(0.85, 0.8, 0.62, 0.30)
const ROAD := Color("3a4466")
const WOOD := Color("5a4a3a")


func _draw_land(layer: CanvasItem) -> void:
	_tgt = layer
	var L := layer
	var plain := PackedVector2Array(PLAIN)
	# ---- 圓規湖：淺灘、湖面（湖比外面的水亮一點） ----
	L.draw_arc(O, R, 0, TAU, 128, Color(0.35, 0.7, 0.95, 0.05), RW + 44.0, true)
	L.draw_arc(O, R, 0, TAU, 128, Color(0.4, 0.75, 1.0, 0.08), RW + 22.0, true)
	UITheme.dot(L, O, R - RW / 2.0, Color("0f2f55"))
	UITheme.dot(L, O, R - RW / 2.0 - 12.0, Color("12385f"))
	# ---- 坐標平原 ----
	var big := PackedVector2Array()
	for k in plain.size():
		var c := plain[k]
		big.append(c + (c - Vector2(310, 360)).normalized() * 16.0)
	L.draw_colored_polygon(big, Color(0.35, 0.7, 0.95, 0.06))
	L.draw_colored_polygon(plain, LAND)
	var inner := PackedVector2Array()
	for c in plain:
		inner.append(Vector2(310, 360) + (c - Vector2(310, 360)) * 0.9)
	L.draw_colored_polygon(inner, HIGH)
	# 地上的方格（只畫在平原裡）
	_draw_plain_grid(L, plain)
	var closed := plain.duplicate()
	closed.append(plain[0])
	L.draw_polyline(closed, SAND, 3.0, true)
	# ---- 湖岸 ----
	L.draw_arc(O, R, 0, TAU, 128, LAND, RW, true)
	L.draw_arc(O, R, 0, TAU, 128, HIGH, RW - 18.0, true)
	L.draw_arc(O, R + RW / 2.0, 0, TAU, 128, SAND, 3.0, true)
	L.draw_arc(O, R - RW / 2.0, 0, TAU, 128, SAND, 2.0, true)
	# ---- 湖中央的小島（圓心） ----
	UITheme.dot(L, O, ISLE_R + 10.0, Color(0.4, 0.75, 1.0, 0.08))
	UITheme.dot(L, O, ISLE_R, LAND)
	UITheme.dot(L, O, ISLE_R - 9.0, HIGH)
	L.draw_arc(O, ISLE_R, 0, TAU, 48, SAND, 2.0, true)
	# ---- 棧道（平原上）＋木橋（水上，一直到切點） ----
	var n := road_n()
	var p_end := road_p(LAND_END)
	L.draw_colored_polygon(road_band(E.x - 30.0, LAND_END, CW / 2.0 + 3.0), Color(0, 0, 0, 0.18))
	L.draw_colored_polygon(road_band(E.x - 30.0, LAND_END, CW / 2.0), ROAD)
	# 木橋：兩根欄杆＋一片一片的木板
	var bt := T + (T - O).normalized() * (RW / 2.0 - 4.0) * 0.0
	var dd := road_d()
	var len := p_end.distance_to(bt)
	for k in int(len / 9.0):
		var c := p_end + dd * (k * 9.0 + 4.0)
		L.draw_line(c + n * (CW / 2.0 - 6.0), c - n * (CW / 2.0 - 6.0), WOOD.lightened(0.08 * (k % 2)), 6.0)
	L.draw_line(p_end + n * (CW / 2.0 - 5.0), bt + n * (CW / 2.0 - 5.0), WOOD.darkened(0.3), 2.0, true)
	L.draw_line(p_end - n * (CW / 2.0 - 5.0), bt - n * (CW / 2.0 - 5.0), WOOD.darkened(0.3), 2.0, true)
	# 點亮的區域
	for i in SITES.size():
		_draw_region_fill(L, i)
	# 棧道中間的虛線（直線）
	var d0 := road_p(E.x - 20.0)
	L.draw_dashed_line(d0, p_end, Color(1, 1, 1, 0.22), 2.0, 10.0)
	# 切點：棧道剛好碰到湖岸的地方，一個小小的直角記號（半徑 ⊥ 切線）
	var tin := O + (T - O).normalized() * (R - RW / 2.0 - 2.0)
	L.draw_dashed_line(O + (T - O).normalized() * ISLE_R, tin, Color(1, 0.9, 0.6, 0.18), 1.5, 8.0)
	# 湖岸的刻度（每 30° 一條）
	for k in 12:
		var a := k * 30.0
		var hl := 12.0 if k % 3 == 0 else 6.0
		L.draw_line(ring_p(a, R - hl), ring_p(a, R + hl), Color(1, 1, 1, 0.22 if k % 3 == 0 else 0.12), 2.0 if k % 3 == 0 else 1.5)
	# 圓規：一腳在圓心（塔旁邊）、一腳在湖岸（畫筆），鉸鏈在上方
	var g5: float = glow[4]
	var hinge := O + Vector2(56, -104)
	var pen := ring_p(318.0, R - 6.0)
	var leg_c := Color(0.75, 0.78, 0.9, 0.22 + 0.4 * g5)
	L.draw_line(hinge, O + Vector2(6, -4), leg_c, 5.0, true)
	L.draw_line(hinge, pen, leg_c, 5.0, true)
	UITheme.dot(L, hinge, 7.0, Color(0.85, 0.86, 0.95, 0.35 + 0.4 * g5))
	UITheme.dot(L, pen, 4.0, Color(1, 0.85, 0.45, 0.4 + 0.5 * g5))
	_draw_details(L)
	_draw_borders(L)
	_tgt = self


## 平原上的方格：每 40 像素一條，切成小段，只留在平原裡的
func _draw_plain_grid(L: CanvasItem, plain: PackedVector2Array) -> void:
	if not _cache.has("grid"):
		var segs := PackedVector2Array()
		var axes := PackedVector2Array()
		var step := 40.0
		var x := 40.0
		while x <= 600.0:
			var y := 80.0
			while y < 620.0:
				var a := Vector2(x, y)
				var b := Vector2(x, y + step)
				if Geometry2D.is_point_in_polygon((a + b) / 2.0, plain):
					(axes if is_equal_approx(x, 120.0) else segs).append_array([a, b])
				y += step
			x += step
		var yy := 80.0
		while yy <= 620.0:
			var xx := 0.0
			while xx < 600.0:
				var a := Vector2(xx, yy)
				var b := Vector2(xx + step, yy)
				if Geometry2D.is_point_in_polygon((a + b) / 2.0, plain):
					(axes if is_equal_approx(yy, 520.0) else segs).append_array([a, b])
				xx += step
			yy += step
		_cache["grid"] = segs
		_cache["axes"] = axes
	L.draw_multiline(_cache.grid, Color(0.7, 0.85, 1.0, 0.07), 1.0)
	L.draw_multiline(_cache.axes, Color(0.75, 0.9, 1.0, 0.18), 2.0)


func _draw_region_fill(L: CanvasItem, i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var st: Dictionary = SITES[i]
	var c: Color = Center.level_info(st.id).color
	var c1 := Color(c.r, c.g, c.b, 0.30 * gl).darkened(0.1)
	var c2 := Color(c.r, c.g, c.b, 0.22 * gl)
	if String(st.kind) == "road":
		L.draw_colored_polygon(road_band(st.x.x, st.x.y, CW / 2.0), c1)
		L.draw_colored_polygon(road_band(st.x.x, st.x.y, CW / 2.0 - 8.0), c2)
	else:
		L.draw_arc(O, R, deg_to_rad(st.a.x), deg_to_rad(st.a.y), 48, c1, RW, true)
		L.draw_arc(O, R, deg_to_rad(st.a.x), deg_to_rad(st.a.y), 48, c2, RW - 18.0, true)


func _draw_region_ring(i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var st: Dictionary = SITES[i]
	var c: Color = Center.level_info(st.id).color
	var pulse := 0.85 + 0.15 * sin(t * 2.0 + i)
	var lines := []
	if String(st.kind) == "road":
		var n := road_n()
		lines.append(PackedVector2Array([road_p(st.x.x) + n * CW / 2.0, road_p(st.x.y) + n * CW / 2.0]))
		lines.append(PackedVector2Array([road_p(st.x.x) - n * CW / 2.0, road_p(st.x.y) - n * CW / 2.0]))
	else:
		lines.append(arc_pts(st.a.x, st.a.y, R + RW / 2.0))
		lines.append(arc_pts(st.a.x, st.a.y, R - RW / 2.0))
	for ln in lines:
		_tgt.draw_polyline(ln, Color(c.r, c.g, c.b, 0.25 * gl * pulse), 7.0)
		_tgt.draw_polyline(ln, Color(c.r, c.g, c.b, 0.9 * gl).lightened(0.3), 2.0, true)


func _make_details() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var plain := PackedVector2Array(PLAIN)
	for k in 90:
		var p: Vector2
		var si := -1
		if k < 30:
			var a := rng.randf_range(238.0, 598.0)
			p = ring_p(a, R + rng.randf_range(-0.3, 0.3) * RW)
			si = region_at(p)
		else:
			p = Vector2(rng.randf_range(40, 590), rng.randf_range(110, 600))
			if not Geometry2D.is_point_in_polygon(p, plain):
				continue
			var off := absf((p - E).dot(road_n()))
			if off < CW / 2.0 + 10.0:
				continue
			si = plain_site(p)
		if si < 0:
			continue
		var near := false
		for j in SITES.size():
			if p.distance_to(site_point(j) + Vector2(0, -16)) < 42.0:
				near = true
		if not near:
			out.append({"p": p, "si": si, "k": k})
	return out


## 區域之間的虛線邊界（兩邊都點亮時變成金色）
func _draw_borders(L: CanvasItem) -> void:
	var cuts := []
	var n := road_n()
	for i in 3:
		var x: float = SITES[i].x.y
		cuts.append([i, i + 1, road_p(x) + n * CW / 2.0, road_p(x) - n * CW / 2.0])
	for i in range(4, 7):
		var a: float = SITES[i].a.y
		cuts.append([i, i + 1, ring_p(a, R - RW / 2.0), ring_p(a, R + RW / 2.0)])
	cuts.append([7, 4, ring_p(238.0, R - RW / 2.0), ring_p(238.0, R + RW / 2.0)])
	for ct in cuts:
		var both: bool = glow[ct[0]] > 0.6 and glow[ct[1]] > 0.6
		L.draw_dashed_line(ct[2], ct[3], Color(1, 0.88, 0.55, 0.65) if both else Color(1, 1, 1, 0.28), 2.0, 7.0)


## 旅程路線：沿著棧道走到切點，再順著湖岸繞一圈
func _route(i: int) -> PackedVector2Array:
	var key := "route%d" % i
	if _cache.has(key):
		return _cache[key]
	var pts := PackedVector2Array()
	if i < 3:
		pts = PackedVector2Array([site_point(i), site_point(i + 1)])
	elif i == 3:
		pts = PackedVector2Array([site_point(3), T])
		pts.append_array(arc_pts(238.0, float(SITES[4].at), R))
	else:
		pts = arc_pts(float(SITES[i].at), float(SITES[i + 1].at) + (360.0 if float(SITES[i + 1].at) < float(SITES[i].at) else 0.0), R)
	_cache[key] = pts
	return pts


## 八座聖地的地標
func _draw_landmark(i: int) -> void:
	var col: Color = Center.level_info(SITES[i].id).color
	var gl: float = glow[i]
	var p := site_point(i)
	var Tg := _tgt
	var base := Color("3a4170").lerp(col.darkened(0.15), clampf(0.15 + 0.75 * gl, 0.0, 1.0))
	var dark := Color("1c2142").lerp(col.darkened(0.55), gl)
	var light := Color(col.r, col.g, col.b, 0.25 + 0.75 * gl)
	var sh := PackedVector2Array()
	for k in 25:
		var ang := TAU * k / 24.0
		sh.append(p + Vector2(cos(ang) * 26.0, sin(ang) * 6.0 + 2.0))
	Tg.draw_colored_polygon(sh, Color(0, 0, 0, 0.25))
	if i == sel and not playing:
		var pts := PackedVector2Array()
		for k in 33:
			var ang := TAU * k / 32.0
			pts.append(p + Vector2(cos(ang) * 40.0, sin(ang) * 10.0 + 2.0))
		Tg.draw_polyline(pts, Color(1, 0.85, 0.45, 0.5 + 0.3 * sin(t * 4.0)), 2.0, true)
	if gl > 0.05:
		UITheme.dot(Tg, p + Vector2(0, -28), 42.0, Color(col.r, col.g, col.b, 0.07 * gl))
	var lit_c := light if gl > 0.05 else base.lightened(0.25)
	match i:
		0:   # 坐標燈標：一個小小的坐標軸（x、y 箭頭），原點上掛一盞燈
			var o := p + Vector2(-12, -8)
			Tg.draw_line(o, o + Vector2(32, 0), base.lightened(0.2), 2.5)
			Tg.draw_line(o, o + Vector2(0, -34), base.lightened(0.2), 2.5)
			Tg.draw_colored_polygon(PackedVector2Array([o + Vector2(36, 0), o + Vector2(29, -4), o + Vector2(29, 4)]), base.lightened(0.2))
			Tg.draw_colored_polygon(PackedVector2Array([o + Vector2(0, -38), o + Vector2(-4, -31), o + Vector2(4, -31)]), base.lightened(0.2))
			var lp := o + Vector2(16, -18)
			UITheme.dot(Tg, lp, 4.5, lit_c)
			Tg.draw_dashed_line(lp, Vector2(lp.x, o.y), Color(1, 1, 1, 0.3), 1.0, 3.0)
			Tg.draw_dashed_line(lp, Vector2(o.x, lp.y), Color(1, 1, 1, 0.3), 1.0, 3.0)
			if gl > 0.05:
				UITheme.dot(Tg, lp, 12.0, Color(col.r, col.g, col.b, 0.2 * gl))
		1:   # 直線棧橋：一座斜坡（直角三角形），斜邊是一條直線，標出往右、往上
			var a := p + Vector2(-24, -4)
			var b := p + Vector2(24, -4)
			var c := p + Vector2(24, -36)
			Tg.draw_colored_polygon(PackedVector2Array([a, b, c]), dark.lightened(0.1))
			Tg.draw_line(a, c, lit_c, 3.0, true)
			Tg.draw_line(a, b, base.lightened(0.25), 2.0)
			Tg.draw_line(b, c, base.lightened(0.25), 2.0)
			if gl > 0.05:
				var u := fposmod(t * 0.4, 1.0)
				UITheme.dot(Tg, a.lerp(c, u), 3.5, Color(1, 1, 0.85, gl))
		2:   # 鏡面渡口：一條虛線（鏡子），兩邊各一盞對稱的燈
			var m0 := p + Vector2(-20, 0)
			var m1 := p + Vector2(20, -40)
			Tg.draw_dashed_line(m0, m1, base.lightened(0.35), 2.0, 5.0)
			var l1 := p + Vector2(-16, -30)
			var l2 := p + Vector2(16, -6)
			for lp in [l1, l2]:
				Tg.draw_line(lp, lp + Vector2(0, 10), base, 2.0)
				UITheme.dot(Tg, lp, 4.0, lit_c)
			if gl > 0.05:
				Tg.draw_line(l1, l2, Color(col.r, col.g, col.b, 0.4 * gl), 1.5, true)
		3:   # 分光稻田：一塊方田，被一條斜線分成兩半，一半有稻子
			var rc := Rect2(p + Vector2(-24, -36), Vector2(48, 32))
			Tg.draw_rect(rc, dark.lightened(0.08))
			var half := PackedVector2Array([rc.position, rc.position + Vector2(rc.size.x, 0), rc.position + Vector2(0, rc.size.y)])
			Tg.draw_colored_polygon(half, Color(col.r, col.g, col.b, 0.2 + 0.5 * gl))
			for k in 4:
				var q := rc.position + Vector2(5 + k * 7, 5)
				Tg.draw_line(q, q + Vector2(0, 14 - k * 3.0), base.lightened(0.4), 1.5)
			Tg.draw_line(rc.position + Vector2(rc.size.x, 0), rc.position + Vector2(0, rc.size.y), lit_c, 2.5, true)
			Tg.draw_rect(rc, base.lightened(0.2), false, 1.5)
		4:   # 圓規工坊：一把小圓規在畫圓
			var hc := p + Vector2(0, -40)
			var ang := t * (1.2 if gl > 0.5 else 0.4)
			var foot := p + Vector2(-2, -4)
			var penp := foot + Vector2(cos(ang), sin(ang) * 0.35) * 20.0
			Tg.draw_arc(foot, 20.0, 0, TAU, 32, Color(col.r, col.g, col.b, 0.2 + 0.5 * gl), 1.5, true)
			Tg.draw_line(hc, foot, base.lightened(0.3), 2.5)
			Tg.draw_line(hc, penp, base.lightened(0.3), 2.5)
			UITheme.dot(Tg, hc, 3.5, base.lightened(0.4))
			UITheme.dot(Tg, penp, 3.0, lit_c)
		5:   # 割弦漣漪：一個圓被一條直線割出一條弦
			var cc := p + Vector2(0, -22)
			Tg.draw_arc(cc, 18.0, 0, TAU, 32, base.lightened(0.25), 2.0, true)
			var y := 8.0
			var hw := sqrt(18.0 * 18.0 - y * y)
			Tg.draw_line(cc + Vector2(-30, y), cc + Vector2(30, y), base.lightened(0.2), 1.5)
			Tg.draw_line(cc + Vector2(-hw, y), cc + Vector2(hw, y), lit_c, 3.0)
			UITheme.dot(Tg, cc + Vector2(-hw, y), 3.0, lit_c)
			UITheme.dot(Tg, cc + Vector2(hw, y), 3.0, lit_c)
		6:   # 切線燈環：一個圓、一條切線，切點上一盞燈
			var cc := p + Vector2(0, -20)
			Tg.draw_arc(cc, 16.0, 0, TAU, 32, base.lightened(0.25), 2.0, true)
			Tg.draw_line(cc + Vector2(-28, -16), cc + Vector2(28, -16), lit_c, 2.0)
			Tg.draw_line(cc, cc + Vector2(0, -16), Color(1, 1, 1, 0.3), 1.0)
			UITheme.dot(Tg, cc + Vector2(0, -16), 4.0, lit_c)
			if gl > 0.05:
				UITheme.dot(Tg, cc + Vector2(0, -16), 11.0, Color(col.r, col.g, col.b, 0.25 * gl))
		7:   # 軌跡星環：兩個相交的圓，一顆星星沿著圓走
			var c1 := p + Vector2(-8, -22)
			var c2 := p + Vector2(8, -22)
			Tg.draw_arc(c1, 14.0, 0, TAU, 28, base.lightened(0.25), 1.8, true)
			Tg.draw_arc(c2, 14.0, 0, TAU, 28, base.lightened(0.25), 1.8, true)
			var u := t * (1.4 if gl > 0.5 else 0.5)
			var sp := c1 + Vector2(cos(u), sin(u)) * 14.0
			UITheme.dot(Tg, sp, 3.5, lit_c)
			if gl > 0.05:
				for k in 6:
					var uu := u - k * 0.25
					UITheme.dot(Tg, c1 + Vector2(cos(uu), sin(uu)) * 14.0, 2.0, Color(col.r, col.g, col.b, 0.5 * gl * (1.0 - k / 6.0)))


func _draw_names(font: Font) -> void:
	UITheme.text_ol(_tgt, font, Vector2(48, 138), "坐標平原", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(28), Color(0.6, 0.85, 1.0, 0.85), 6)
	UITheme.text_ol(_tgt, font, O + Vector2(R + 10.0, -R + 6.0), "圓規湖", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(30), Color(1.0, 0.86, 0.5, 0.85), 6)
