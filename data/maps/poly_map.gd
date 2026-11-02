extends "res://data/maps/unit_map_base.gd"
## 多項式的世界地圖：根之洞窟（剖面圖）
##   ・地表有一棵大樹，樹根往下伸進岩層——洞窟的名字「根」就是從這裡來的
##   ・上層礦脈（4-1 多項式的運算）：從左上的入口往右，1 → 4
##   ・右邊的豎井往下接到下層大洞窟（4-2、4-3 函數與不等式），路線由右往左回來，5 → 8
##   ・地下水面就是 x 軸，主岩脊的形狀是一條三次函數的曲線：
##       穿過水面的三個地方是發光的水晶泉（方程式的根）
##       水面上的岩脊是乾的（f(x) > 0），沉到水下的被淹沒（f(x) < 0）——第八關的不等式
##       岩脊最高點是第六關的燈芯（極值），對稱中心是第七關的大水晶
##   ・終焉之塔沉在最深的谷底
##   ・操作、點亮、劇情都在共用底層 unit_map_base.gd；劇情的 key 都加上 "poly/"
## 劇情文字寫在下面的 STORY，可以直接修改。

const UNIT := "h1poly"
const PREFIX := "poly/"

# ---------------- 地形 ----------------
const SURF_Y := 96.0              # 地表
const WY := 470.0                 # 地下水面（x 軸）
## 上層礦脈坑道的中線（入口 → 右邊的豎井）
const TUN := [Vector2(40, 90), Vector2(66, 136), Vector2(300, 158), Vector2(560, 180), Vector2(820, 200), Vector2(1080, 216)]
const TUN_W := 52.0
const SHAFT_X := 1080.0
const SHAFT_BOT := 452.0
## 下層大洞窟的範圍
const CAVE := Rect2(36, 290, 1088, 380)
## 三次曲線岩脊：X = CX + SX·u，Y = WY − SY·f(u)，f(u) = −u³/2 + 3.38u（三個根 u = 0、±2.6）
const CX := 576.0
const SX := 165.0
const SY := 44.0
const U0 := -2.85
const U1 := 3.2
const RIDGE_W := 26.0
const ROOT_U := 2.6

## 八座聖地。kind：tun（上層坑道上，x 範圍 xr）、lake（右邊的鏡湖）、ridge（岩脊上，u 範圍 ur，站在 at）、bridge（左邊的根和吊橋）
const SITES := [
	{"id": "P1", "kind": "tun", "at": 200.0, "xr": Vector2(40, 320)},
	{"id": "P2", "kind": "tun", "at": 440.0, "xr": Vector2(320, 565)},
	{"id": "P3", "kind": "tun", "at": 690.0, "xr": Vector2(565, 815)},
	{"id": "P4", "kind": "tun", "at": 940.0, "xr": Vector2(815, 1080)},
	{"id": "P5", "kind": "lake", "p": Vector2(1042, 468), "lab": Vector2(1042, 412)},
	{"id": "P6", "kind": "ridge", "at": 1.5, "ur": Vector2(0.75, 2.3), "lab": Vector2(0, 66)},
	{"id": "P7", "kind": "ridge", "at": 0.0, "ur": Vector2(-0.75, 0.75), "lab": Vector2(0, 74)},
	{"id": "P8", "kind": "bridge", "at": -ROOT_U, "ur": Vector2(U0, -2.0), "lab": Vector2(-8, -72)},
]

## 終焉之塔：沉在最深的谷底
const TOWER_P := Vector2(328, 612)
## 水面上的正負號浮標（第八關點亮後變亮）：u、符號
const BUOYS := [[-2.8, "+"], [-1.3, "−"], [1.3, "+"], [3.15, "−"]]

## 劇情：每一句 {text, who, cam（"wide"、"site"、"isle0" 上層礦脈、"isle1" 下層大洞窟）, site, zoom, light, spirit}
const STORY := {
	"prologue": [
		{"text": "曦光大陸的山丘底下，藏著一座很深很深的洞窟。大樹的根一路往下伸——人們叫它「根之洞窟」。", "cam": "wide"},
		{"text": "洞窟的上層是礦脈，每塊礦石都刻著多項式；下層有一條地下水脈，岩脊一高一低地穿過水面。", "cam": "isle1", "zoom": 1.3},
		{"text": "可是礦燈一盞一盞熄滅了，洞裡黑漆漆的，連水面在哪裡都看不清楚……", "cam": "wide"},
		{"text": "哇，好暗！地上的礦石寫著……3x² − 5x + 1？這是多項式耶！", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.7, "spirit": 0, "appear": true},
		{"text": "先把入口的礦燈點亮吧！聽說礦燈照在哪裡，x 就會變成多少～", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.5},
	],
	"P1": [
		{"text": "礦燈亮了！照在 x = 1，所有係數加在一起；照在 x = 0，只剩下常數項。", "cam": "site", "site": 0, "zoom": 1.8, "light": 0},
		{"text": "不用展開也能算係數和，好方便！前面有一座水車在轉耶～", "who": "光靈", "cam": "site", "site": 1, "zoom": 1.4, "spirit": 1},
	],
	"P2": [
		{"text": "水車轉起來了，數字一格一格往下流：乘上去、加下來，商式和餘式就出來了。", "cam": "site", "site": 1, "zoom": 1.8, "light": 1},
		{"text": "被除式 = 除式 × 商式 + 餘式！前面傳來好大的回音……", "who": "光靈", "cam": "site", "site": 2, "zoom": 1.4, "spirit": 2},
	],
	"P3": [
		{"text": "對著石廊喊出 x = a，傳回來的回音就是 f(a)——這就是餘式定理。", "cam": "site", "site": 2, "zoom": 1.8, "light": 2},
		{"text": "回音是 0 的話，x − a 就是因式！我們去鑄模工坊看看～", "who": "光靈", "cam": "site", "site": 3, "zoom": 1.4, "spirit": 3},
	],
	"P4": [
		{"text": "鑄模的火光亮起。知道了根、知道了餘式，就能把多項式一點一點鑄出來。", "cam": "site", "site": 3, "zoom": 1.8, "light": 3},
		{"text": "上層的礦脈都亮了！順著豎井爬下去，下面有水的聲音～", "who": "光靈", "cam": "site", "site": 4, "zoom": 1.4, "spirit": 4},
	],
	"P5": [
		{"text": "鏡湖的水面映出一道拋物線：開口方向、頂點、對稱軸，一看就知道。", "cam": "site", "site": 4, "zoom": 1.8, "light": 4},
		{"text": "a 決定開口，頂點是最高或最低的地方！岩脊上好像有一盞燈芯……", "who": "光靈", "cam": "site", "site": 5, "zoom": 1.4, "spirit": 5},
	],
	"P6": [
		{"text": "岩脊最高的地方，燈芯點起來了。只看一段範圍的時候，最大值不一定在頂點喔。", "cam": "site", "site": 5, "zoom": 1.8, "light": 5},
		{"text": "要先看範圍有沒有包含頂點！前面那顆大水晶在發光～", "who": "光靈", "cam": "site", "site": 6, "zoom": 1.4, "spirit": 6},
	],
	"P7": [
		{"text": "水晶轉了半圈，和自己完全重合。三次函數的圖形，對稱於它的對稱中心。", "cam": "site", "site": 6, "zoom": 1.8, "light": 6},
		{"text": "靠近中心像一條直線，離遠了就像 ax³！最後一站在吊橋的另一邊～", "who": "光靈", "cam": "site", "site": 7, "zoom": 1.4, "spirit": 7},
	],
	"P8": [
		{"text": "地下河亮了！岩脊在水面上的地方 f(x) > 0，沉到水下的地方 f(x) < 0。", "cam": "isle1", "zoom": 1.25, "light": 7},
		{"text": "原來解不等式，就是看圖形在水面上面還是下面！", "who": "光靈", "cam": "site", "site": 7, "zoom": 1.5},
	],
	"epilogue": [
		{"text": "八盞燈全部亮起，根之洞窟從礦脈到水脈都閃閃發光。", "cam": "wide", "all": true},
		{"text": "曲線穿過水面的地方，就是方程式的根——這座洞窟的名字，原來是這個意思。", "cam": "isle1", "zoom": 1.25},
		{"text": "根之果樹的紀念品送到小屋囉！谷底的終焉之塔，有空也要來挑戰喔～", "who": "光靈", "cam": "wide"},
	],
}

const STORY_TITLES := {"prologue": "序章．沉睡的洞窟", "P1": "第一幕．係數礦燈", "P2": "第二幕．綜合除法水車",
	"P3": "第三幕．回音石廊", "P4": "第四幕．根之鑄模", "P5": "第五幕．拋物鏡湖", "P6": "第六幕．極值燈芯",
	"P7": "第七幕．對稱水晶", "P8": "第八幕．符號地下河", "epilogue": "終章．根的意義"}


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

func _region(p: Vector2) -> int:
	return region_at(p)

func _isle_target(k: int) -> Vector2:
	return Vector2(560, 190) if k == 0 else Vector2(600, 470)


# ================= 幾何 =================

static func cubic_f(u: float) -> float:
	return -0.5 * u * u * u + 3.38 * u

static func ridge_p(u: float) -> Vector2:
	return Vector2(CX + SX * u, WY - SY * cubic_f(u))

## 岩脊中線的取樣點（u 從 a 到 b，可以倒著）
static func ridge_pts(a: float, b: float, step := 0.04) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := maxi(2, int(absf(b - a) / step))
	for k in n + 1:
		pts.append(ridge_p(lerpf(a, b, float(k) / n)))
	return pts

## 上層坑道在 x 處的高度
static func tun_y(x: float) -> float:
	for k in TUN.size() - 1:
		var a: Vector2 = TUN[k]
		var b: Vector2 = TUN[k + 1]
		if x <= b.x:
			return lerpf(a.y, b.y, clampf((x - a.x) / maxf(1.0, b.x - a.x), 0.0, 1.0))
	return TUN[TUN.size() - 1].y

static func tun_p(x: float) -> Vector2:
	return Vector2(x, tun_y(x))

## 坑道中線的取樣點（x 從 a 到 b）
static func tun_pts(a: float, b: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := maxi(2, int(absf(b - a) / 8.0))
	for k in n + 1:
		pts.append(tun_p(lerpf(a, b, float(k) / n)))
	return pts

## 吊橋：從對稱中心拱到左邊的根
static func bridge_pts() -> PackedVector2Array:
	var a := ridge_p(0.0) + Vector2(0, -18)
	var b := ridge_p(-ROOT_U) + Vector2(0, -18)
	var c := (a + b) / 2.0 + Vector2(0, -46)
	var pts := PackedVector2Array()
	for k in 33:
		var s := k / 32.0
		pts.append(a.lerp(c, s).lerp(c.lerp(b, s), s))
	return pts

## 往法線方向平移一條折線（畫邊緣用）
static func offset_line(pts: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in pts.size():
		var a: Vector2 = pts[maxi(0, k - 1)]
		var b: Vector2 = pts[mini(pts.size() - 1, k + 1)]
		var tan := (b - a).normalized()
		out.append(pts[k] + Vector2(tan.y, -tan.x) * d)
	return out

static func site_point(i: int) -> Vector2:
	var st: Dictionary = SITES[i]
	match String(st.kind):
		"tun":
			return tun_p(float(st.at)) + Vector2(0, 14)
		"lake":
			return st.p
		"bridge":
			return ridge_p(float(st.at))
	return ridge_p(float(st.at)) + Vector2(0, -10)

static func label_point(i: int) -> Vector2:
	var st: Dictionary = SITES[i]
	match String(st.kind):
		"tun":
			return tun_p(float(st.at)) + Vector2(0, 62)
		"lake":
			return st.lab
	return site_point(i) + Vector2(st.lab)

## 這一點在哪一座聖地的範圍（−1：都不是）
static func region_at(p: Vector2) -> int:
	for i in SITES.size():
		if p.distance_to(site_point(i)) < 64.0:
			return i
	for i in 4:
		var xr: Vector2 = SITES[i].xr
		if p.x >= xr.x and p.x <= xr.y and absf(p.y - tun_y(p.x)) <= TUN_W / 2.0:
			return i
	for i in [5, 6, 7]:
		var ur: Vector2 = SITES[i].ur
		var u := (p.x - CX) / SX
		if u >= ur.x and u <= ur.y and absf(p.y - ridge_p(u).y) <= RIDGE_W:
			return i
	return -1

func _rand_point(i: int) -> Vector2:
	var st: Dictionary = SITES[i]
	match String(st.kind):
		"tun":
			var x := randf_range(st.xr.x + 10.0, st.xr.y - 10.0)
			return tun_p(x) + Vector2(0, randf_range(-0.35, 0.35) * TUN_W)
		"lake":
			return Vector2(st.p) + Vector2(randf_range(-30, 30), randf_range(-24, 0))
	var u := randf_range(st.ur.x, st.ur.y)
	var q := ridge_p(u)
	if q.y > WY:
		q.y = WY - 4.0
	return q + Vector2(0, randf_range(-12, 0))


# ================= 繪圖 =================

const ROCK := Color("1a1230")
const ROCK2 := Color("231a3e")
const TUN_EDGE := Color("3a2d5e")
const TUN_IN := Color("4a3a74")
const CAVE_IN := Color("2a2148")
const RIDGE := Color("5b4f72")
const RIDGE_HI := Color("7a6a9e")


## 天空（每幀畫，只有上面一小條會閃星星）
func _draw() -> void:
	_tgt = self
	draw_set_transform(SCREEN_C - cam * zoom, 0.0, Vector2(zoom, zoom))
	var r := Rect2(-W, -H, 3.0 * W, H + SURF_Y)
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([Color("120f3a"), Color("120f3a"), Color("2c2a6a"), Color("2c2a6a")]))
	for st in sky_stars:
		if st.p.y < SURF_Y - 10.0:
			var a: float = 0.2 + 0.25 * sin(t * 1.5 + st.ph)
			UITheme.dot_n(self, st.p, st.s, Color(1, 1, 1, a), 16)


## 洞窟的輪廓（上緣微微起伏、兩邊圓角）
func _cave_poly() -> PackedVector2Array:
	if _cache.has("cave"):
		return _cache.cave
	var pts := PackedVector2Array()
	var x0 := CAVE.position.x
	var x1 := CAVE.end.x
	var y0 := CAVE.position.y
	var y1 := CAVE.end.y
	var rr := 60.0
	var x := x0 + rr
	while x <= x1 - rr:
		pts.append(Vector2(x, y0 + 8.0 * sin(x * 0.012) + 5.0 * sin(x * 0.031)))
		x += 16.0
	for k in 9:
		var a := -PI / 2.0 + PI / 2.0 * k / 8.0
		pts.append(Vector2(x1 - rr, y0 + rr) + Vector2(cos(a), sin(a)) * rr)
	pts.append(Vector2(x1, y1))
	pts.append(Vector2(x0, y1))
	for k in 9:
		var a := PI + PI / 2.0 * k / 8.0
		pts.append(Vector2(x0 + rr, y0 + rr) + Vector2(cos(a), sin(a)) * rr)
	_cache["cave"] = pts
	return pts


## 水（洞窟裡、水面以下的部分）
func _water_poly() -> PackedVector2Array:
	if _cache.has("water"):
		return _cache.water
	var below := PackedVector2Array([Vector2(0, WY), Vector2(W + 50, WY), Vector2(W + 50, H + 200), Vector2(0, H + 200)])
	var parts := Geometry2D.intersect_polygons(_cave_poly(), below)
	_cache["water"] = parts[0] if not parts.is_empty() else PackedVector2Array()
	return _cache.water


## 不會動的地形（畫在 _land）
func _draw_land(layer: CanvasItem) -> void:
	_tgt = layer
	var L := layer
	# 岩層
	L.draw_rect(Rect2(-W, SURF_Y, 3.0 * W, 2.0 * H), ROCK)
	for k in 8:
		var y := SURF_Y + 40.0 + k * 74.0
		var pts := PackedVector2Array()
		var x := -20.0
		while x <= W + 20.0:
			pts.append(Vector2(x, y + 9.0 * sin(x * 0.006 + k * 1.7)))
			x += 24.0
		L.draw_polyline(pts, ROCK2, 2.0, true)
	# 地表的草
	var grass := PackedVector2Array([Vector2(-W, SURF_Y - 4.0)])
	var gx := 0.0
	while gx <= W:
		grass.append(Vector2(gx, SURF_Y - 6.0 + 4.0 * sin(gx * 0.01)))
		gx += 32.0
	grass.append_array([Vector2(2.0 * W, SURF_Y - 4.0), Vector2(2.0 * W, SURF_Y + 10.0), Vector2(-W, SURF_Y + 10.0)])
	L.draw_colored_polygon(grass, Color("3f6b52"))
	L.draw_rect(Rect2(-W, SURF_Y + 6.0, 3.0 * W, 6.0), Color("2e4a3e"))
	# 大樹和往下伸的根
	_draw_tree(L)
	# 上層坑道
	var tun := PackedVector2Array(TUN)
	L.draw_polyline(tun, TUN_EDGE, TUN_W + 16.0, false)
	for k in range(1, tun.size()):
		L.draw_circle(tun[k], (TUN_W + 16.0) / 2.0, TUN_EDGE, true, -1.0, true)
	L.draw_polyline(tun, TUN_IN, TUN_W, false)
	for k in range(1, tun.size()):
		L.draw_circle(tun[k], TUN_W / 2.0, TUN_IN, true, -1.0, true)
	# 下層大洞窟
	var cave := _cave_poly()
	L.draw_colored_polygon(cave, CAVE_IN)
	var outl := cave.duplicate()
	outl.append(cave[0])
	L.draw_polyline(outl, TUN_EDGE, 8.0, true)
	# 豎井（接上下兩層）＋梯子
	L.draw_line(Vector2(SHAFT_X, tun_y(SHAFT_X)), Vector2(SHAFT_X, SHAFT_BOT), TUN_EDGE, 58.0)
	L.draw_line(Vector2(SHAFT_X, tun_y(SHAFT_X)), Vector2(SHAFT_X, SHAFT_BOT), TUN_IN, 42.0)
	L.draw_circle(Vector2(SHAFT_X, tun_y(SHAFT_X)), TUN_W / 2.0, TUN_IN, true, -1.0, true)
	L.draw_line(Vector2(SHAFT_X - 13, tun_y(SHAFT_X)), Vector2(SHAFT_X - 13, SHAFT_BOT), Color("8a6a4a"), 2.5)
	L.draw_line(Vector2(SHAFT_X + 13, tun_y(SHAFT_X)), Vector2(SHAFT_X + 13, SHAFT_BOT), Color("8a6a4a"), 2.5)
	var ry := tun_y(SHAFT_X) + 18.0
	var rungs := PackedVector2Array()
	while ry < SHAFT_BOT:
		rungs.append_array([Vector2(SHAFT_X - 13, ry), Vector2(SHAFT_X + 13, ry)])
		ry += 18.0
	L.draw_multiline(rungs, Color("a08060"), 2.5)
	# 點亮的區域（坑道、岩脊染上這一關的顏色）
	for i in SITES.size():
		_draw_region_fill(L, i)
	# 三次曲線岩脊（先畫，水蓋上去之後水下的部分就變暗）
	var rp := ridge_pts(U0, U1)
	L.draw_polyline(rp, RIDGE, RIDGE_W + 4.0, true)
	L.draw_polyline(rp, RIDGE_HI, 8.0, true)
	for i in [5, 6, 7]:
		_draw_ridge_fill(L, i)
	# 水
	var wp := _water_poly()
	if wp.size() >= 3:
		var cols := PackedColorArray()
		for q in wp:
			var k := clampf((q.y - WY) / 180.0, 0.0, 1.0)
			cols.append(Color(0.16, 0.36, 0.68, 0.78).lerp(Color(0.05, 0.11, 0.28, 0.94), k))
		L.draw_polygon(wp, cols)
	# 水下的岩脊（淡淡的藍）
	var under := PackedVector2Array()
	for q in rp:
		if q.y > WY + 2.0:
			under.append(q)
		elif under.size() > 1:
			L.draw_polyline(under, Color(0.55, 0.72, 0.95, 0.30), 8.0, true)
			under = PackedVector2Array()
		else:
			under = PackedVector2Array()
	if under.size() > 1:
		L.draw_polyline(under, Color(0.55, 0.72, 0.95, 0.30), 8.0, true)
	# 水面
	L.draw_line(Vector2(CAVE.position.x + 4.0, WY), Vector2(CAVE.end.x - 4.0, WY), Color(0.62, 0.82, 1.0, 0.75), 2.5, true)
	# 吊橋（對稱中心 → 左邊的根）
	var br := bridge_pts()
	var g8: float = glow[7]
	var rope := Color("c98a3e").lerp(Center.level_info("P8").color, g8 * 0.6)
	L.draw_polyline(br, rope, 3.0, true)
	var planks := PackedVector2Array()
	for k in range(2, br.size() - 1, 3):
		planks.append_array([br[k], br[k] + Vector2(0, 12)])
	L.draw_multiline(planks, rope, 2.5)
	# 正負號浮標
	var font := get_theme_default_font()
	for b in BUOYS:
		var bp := Vector2(CX + SX * float(b[0]), WY)
		var plus: bool = b[1] == "+"
		var bc := (UITheme.GOLD if plus else UITheme.CYAN).lerp(Color(0.6, 0.6, 0.75), 1.0 - g8)
		UITheme.dot(L, bp, 11.0, Color("1a1230"))
		L.draw_arc(bp, 11.0, 0, TAU, 24, Color(bc.r, bc.g, bc.b, 0.5 + 0.5 * g8), 2.5, true)
		UITheme.text_ol(L, font, bp + Vector2(-10, 6), b[1], HORIZONTAL_ALIGNMENT_CENTER, 20, UITheme.fs(16), bc, 3)
	# 小石頭、小水晶
	_draw_details(L)
	_tgt = self


func _draw_tree(L: CanvasItem) -> void:
	var b := Vector2(770, SURF_Y - 4.0)
	var roots := [[Vector2(-30, 30), Vector2(-70, 52)], [Vector2(14, 36), Vector2(40, 70)], [Vector2(-4, 40), Vector2(-14, 80)],
		[Vector2(30, 20), Vector2(96, 40)]]
	for rt in roots:
		var pts := PackedVector2Array()
		for k in 13:
			var s := k / 12.0
			var c1: Vector2 = b + rt[0]
			var c2: Vector2 = b + rt[1]
			pts.append(b.lerp(c1, s).lerp(c1.lerp(c2, s), s))
		L.draw_polyline(pts, Color(0.48, 0.36, 0.25, 0.6), 4.0, true)
	L.draw_rect(Rect2(b + Vector2(-7, -40), Vector2(14, 42)), Color("5a3f2e"))
	UITheme.dot(L, b + Vector2(0, -52), 28.0, Color("4d7a4a"))
	UITheme.dot(L, b + Vector2(-20, -40), 18.0, Color("3f6b52"))
	UITheme.dot(L, b + Vector2(20, -42), 18.0, Color("3f6b52"))
	for k in 5:
		var fp := b + Vector2(-18 + 9 * k, -48 + 8.0 * sin(k * 1.9))
		UITheme.dot(L, fp, 3.2, Color("c59bff"))


## 點亮的坑道區域
func _draw_region_fill(L: CanvasItem, i: int) -> void:
	var gl: float = glow[i]
	var st: Dictionary = SITES[i]
	if gl <= 0.01 or String(st.kind) != "tun":
		return
	var c: Color = Center.level_info(st.id).color
	var pts := tun_pts(st.xr.x, st.xr.y)
	L.draw_polyline(pts, Color(c.r, c.g, c.b, 0.22 * gl).darkened(0.1), TUN_W, false)
	L.draw_polyline(pts, Color(c.r, c.g, c.b, 0.16 * gl), TUN_W - 18.0, false)


## 點亮的岩脊、鏡湖
func _draw_ridge_fill(L: CanvasItem, i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var st: Dictionary = SITES[i]
	var c: Color = Center.level_info(st.id).color
	var pts := ridge_pts(st.ur.x, st.ur.y)
	L.draw_polyline(pts, Color(c.r, c.g, c.b, 0.45 * gl), RIDGE_W, true)
	L.draw_polyline(pts, Color(c.r, c.g, c.b, 0.6 * gl).lightened(0.2), 6.0, true)


## 區域的發光邊（會脈動，每幀畫）
func _draw_region_ring(i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var st: Dictionary = SITES[i]
	var c: Color = Center.level_info(st.id).color
	var pulse := 0.85 + 0.15 * sin(t * 2.0 + i)
	var lines := []
	match String(st.kind):
		"tun":
			var pts := tun_pts(st.xr.x + 6.0, st.xr.y - 6.0)
			lines = [offset_line(pts, TUN_W / 2.0), offset_line(pts, -TUN_W / 2.0)]
		"lake":
			var lk := PackedVector2Array()
			for k in 25:
				var a := PI * k / 24.0
				lk.append(Vector2(st.p) + Vector2(-cos(a) * 34.0, -sin(a) * 6.0 - 2.0))
			lines = [lk]
		_:
			var pts2 := ridge_pts(st.ur.x, st.ur.y)
			var keep := PackedVector2Array()
			for q in pts2:
				if q.y <= WY:
					keep.append(q)
			if keep.size() > 1:
				lines = [offset_line(keep, -RIDGE_W / 2.0 - 2.0)]
	for ln in lines:
		_tgt.draw_polyline(ln, Color(c.r, c.g, c.b, 0.25 * gl * pulse), 7.0)
		_tgt.draw_polyline(ln, Color(c.r, c.g, c.b, 0.9 * gl).lightened(0.3), 2.0, true)


func _make_details() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for k in 80:
		var p: Vector2
		if k < 40:
			var x := rng.randf_range(80.0, 1060.0)
			p = tun_p(x) + Vector2(0, rng.randf_range(0.15, 0.4) * TUN_W)
		else:
			var u := rng.randf_range(U0, U1)
			p = ridge_p(u) + Vector2(0, -RIDGE_W / 2.0 - 2.0)
			if p.y > WY - 4.0:
				continue
		var si := region_at(p)
		if si < 0:
			continue
		var near := false
		for j in SITES.size():
			if p.distance_to(site_point(j) + Vector2(0, -16)) < 44.0:
				near = true
		if not near:
			out.append({"p": p, "si": si, "k": k})
	return out


## 旅程路線
func _route(i: int) -> PackedVector2Array:
	var key := "route%d" % i
	if _cache.has(key):
		return _cache[key]
	var pts := PackedVector2Array()
	match i:
		0, 1, 2:
			pts = tun_pts(float(SITES[i].at), float(SITES[i + 1].at))
		3:
			pts = tun_pts(float(SITES[3].at), SHAFT_X)
			pts.append(Vector2(SHAFT_X, SHAFT_BOT))
			pts.append(site_point(4) + Vector2(0, -6))
		4:
			pts = PackedVector2Array([site_point(4) + Vector2(0, -6), ridge_p(ROOT_U) + Vector2(0, -16)])
			pts.append_array(offset_line(ridge_pts(ROOT_U, 1.5), RIDGE_W / 2.0 + 2.0))
		5:
			pts = offset_line(ridge_pts(1.5, 0.0), RIDGE_W / 2.0 + 2.0)
		6:
			pts = bridge_pts()
	_cache[key] = pts
	return pts


## 水面的波光、三個根的水晶泉（每幀畫，畫在點亮邊框之前）
func _fx_under() -> void:
	var T := _tgt
	var segs := PackedVector2Array()
	for k in 22:
		var x := 60.0 + k * 48.0 + 8.0 * sin(t * 0.6 + k)
		var y := WY + 22.0 + (k % 3) * 34.0
		segs.append_array([Vector2(x, y), Vector2(x + 9, y - 3), Vector2(x + 9, y - 3), Vector2(x + 18, y)])
	T.draw_multiline(segs, Color(0.7, 0.85, 1.0, 0.16 + 0.06 * sin(t * 1.2)), 1.5, true)
	for u in [-ROOT_U, 0.0, ROOT_U]:
		var p := ridge_p(u)
		var pulse := 0.6 + 0.4 * sin(t * 2.0 + u)
		UITheme.dot(T, p, 30.0, Color(0.8, 0.65, 1.0, 0.10 * pulse))
		if absf(u) > 0.1:
			T.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -16), p + Vector2(8, 0), p + Vector2(0, 9), p + Vector2(-8, 0)]),
				Color(0.88, 0.8, 1.0, 0.8))


## 八座聖地的地標
func _draw_landmark(i: int) -> void:
	var col: Color = Center.level_info(SITES[i].id).color
	var gl: float = glow[i]
	var p := site_point(i)
	var T := _tgt
	var base := Color("4a4170").lerp(col.darkened(0.15), clampf(0.15 + 0.75 * gl, 0.0, 1.0))
	var dark := Color("1c1832").lerp(col.darkened(0.55), gl)
	var light := Color(col.r, col.g, col.b, 0.3 + 0.7 * gl)
	if i == sel and not playing:
		var ring := PackedVector2Array()
		for k in 33:
			var ang := TAU * k / 32.0
			ring.append(p + Vector2(cos(ang) * 38.0, sin(ang) * 9.0 + 2.0))
		T.draw_polyline(ring, Color(1, 0.85, 0.45, 0.5 + 0.3 * sin(t * 4.0)), 2.0, true)
	if gl > 0.05:
		UITheme.dot(T, p + Vector2(0, -24), 40.0, Color(col.r, col.g, col.b, 0.08 * gl))
	match i:
		0:   # 係數礦燈：坑道頂垂下來的礦燈，地上一排小水晶
			var lp := p + Vector2(0, -30)
			T.draw_line(p + Vector2(0, -44), lp + Vector2(0, -6), Color(0.6, 0.5, 0.4, 0.8), 1.5)
			if gl > 0.05:
				UITheme.dot(T, lp, 18.0, Color(1, 0.85, 0.45, 0.25 * gl * (0.85 + 0.15 * sin(t * 5.0))))
			T.draw_rect(Rect2(lp + Vector2(-5, -6), Vector2(10, 12)), light if gl > 0.05 else dark.lightened(0.25))
			T.draw_rect(Rect2(lp + Vector2(-6, -8), Vector2(12, 3)), base)
			for k in 4:
				var cp := p + Vector2(-18 + 12 * k, 0)
				var cc: Color = (UITheme.GOLD if k % 2 == 0 else UITheme.CYAN) if gl > 0.05 else base
				T.draw_colored_polygon(PackedVector2Array([cp + Vector2(-4, 0), cp + Vector2(0, -11), cp + Vector2(4, 0)]),
					Color(cc.r, cc.g, cc.b, 0.5 + 0.5 * gl))
		1:   # 綜合除法水車：點亮之後會轉
			var wc := p + Vector2(0, -20)
			var rot := t * 1.2 if gl > 0.5 else 0.2 * sin(t)
			T.draw_arc(wc, 17.0, 0, TAU, 28, base.lightened(0.2), 3.0, true)
			var sp := PackedVector2Array()
			for k in 8:
				var a := rot + k * PI / 4.0
				sp.append_array([wc, wc + Vector2(cos(a), sin(a)) * 17.0])
			T.draw_multiline(sp, base.lightened(0.1), 2.0)
			UITheme.dot(T, wc, 3.0, light)
			var water := Color(0.4, 0.75, 1.0, 0.35 + 0.5 * gl)
			T.draw_line(wc + Vector2(-34, -20), wc + Vector2(-8, -18), water, 4.0, true)
			T.draw_line(wc + Vector2(14, 12), wc + Vector2(34, 16), water, 4.0, true)
		2:   # 回音石廊：一道深深的裂縫，點亮後傳出回音的波紋
			var cr := p + Vector2(0, -6)
			T.draw_colored_polygon(PackedVector2Array([cr + Vector2(-8, -24), cr + Vector2(4, -10), cr + Vector2(-4, 0),
				cr + Vector2(6, 14), cr + Vector2(16, 14), cr + Vector2(8, 0), cr + Vector2(15, -10), cr + Vector2(4, -24)]), Color("0d0918"))
			for k in 3:
				var ph := fposmod(t * 0.6 + k / 3.0, 1.0) if gl > 0.5 else 0.3 + 0.2 * k
				var rr := 12.0 + 26.0 * ph
				T.draw_arc(cr + Vector2(18, -4), rr, -0.9, 0.9, 12, Color(col.r, col.g, col.b, (0.2 + 0.6 * gl) * (1.0 - ph)), 2.0, true)
		3:   # 根之鑄模：鑄台＋上面的模子，點亮後流下金色的鑄液
			T.draw_colored_polygon(PackedVector2Array([p + Vector2(-20, 0), p + Vector2(20, 0), p + Vector2(14, -12), p + Vector2(-14, -12)]), base)
			T.draw_rect(Rect2(p + Vector2(-9, -26), Vector2(18, 14)), base.lightened(0.15))
			T.draw_rect(Rect2(p + Vector2(-9, -26), Vector2(18, 14)), light, false, 1.5)
			if gl > 0.05:
				var drip := fposmod(t * 0.8, 1.0)
				UITheme.dot(T, p + Vector2(0, -32 - 6.0 * (1.0 - drip)), 3.0, Color(1, 0.7, 0.3, gl))
				UITheme.dot(T, p + Vector2(0, -34), 12.0, Color(1, 0.6, 0.3, 0.15 * gl))
		4:   # 拋物鏡湖：水面上的拋物線，和水裡的倒影
			var lc := p + Vector2(0, -2)
			var up := PackedVector2Array()
			var dn := PackedVector2Array()
			for k in 21:
				var s := -1.0 + k / 10.0
				up.append(lc + Vector2(s * 26.0, -34.0 + 34.0 * (1.0 - s * s)) - Vector2(0, 0))
				dn.append(lc + Vector2(s * 26.0, 34.0 - 34.0 * (1.0 - s * s)))
			T.draw_polyline(up, light if gl > 0.05 else base.lightened(0.3), 3.0, true)
			for k in range(0, dn.size() - 1, 2):
				T.draw_line(dn[k], dn[k + 1], Color(col.r, col.g, col.b, 0.25 + 0.4 * gl), 2.0, true)
			UITheme.dot(T, lc, 3.5, Color(1, 0.95, 0.75, 0.5 + 0.5 * gl))
		5:   # 極值燈芯：岩脊最高點的蠟燭
			T.draw_rect(Rect2(p + Vector2(-5, -18), Vector2(10, 18)), Color(0.92, 0.88, 0.78, 0.5 + 0.5 * gl))
			var fl := 1.0 + 0.15 * sin(t * 9.0) if gl > 0.05 else 0.5
			var fc := Color(1, 0.7, 0.3, 0.35 + 0.65 * gl)
			T.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -34 * fl), p + Vector2(5, -24), p + Vector2(0, -19), p + Vector2(-5, -24)]), fc)
			if gl > 0.05:
				UITheme.dot(T, p + Vector2(0, -26), 20.0, Color(1, 0.75, 0.4, 0.18 * gl))
		6:   # 對稱水晶：水面上的大水晶，點亮後繞著中心轉半圈的箭頭
			var cc := ridge_p(0.0) + Vector2(0, -20)
			var shape := PackedVector2Array([cc + Vector2(0, -26), cc + Vector2(11, 0), cc + Vector2(0, 26), cc + Vector2(-11, 0)])
			T.draw_colored_polygon(shape, Color(col.r, col.g, col.b, 0.35 + 0.45 * gl).lerp(dark, 0.4 * (1.0 - gl)))
			shape.append(shape[0])
			T.draw_polyline(shape, Color(1, 1, 1, 0.4 + 0.5 * gl), 2.0, true)
			var rot := t * 0.8 if gl > 0.5 else 0.0
			for k in 2:
				var a0 := rot + PI * k + 0.3
				var arc := PackedVector2Array()
				for q in 9:
					var a := a0 + (PI - 0.6) * q / 8.0
					arc.append(cc + Vector2(cos(a) * 34.0, sin(a) * 34.0))
				T.draw_polyline(arc, Color(1, 1, 1, 0.15 + 0.5 * gl), 1.5, true)
		7:   # 符號地下河：根旁邊的告示牌
			var sp2 := p + Vector2(18, -6)
			T.draw_rect(Rect2(sp2 + Vector2(-2, -30), Vector2(4, 30)), Color("8a6a4a"))
			T.draw_rect(Rect2(sp2 + Vector2(-16, -42), Vector2(32, 16)), base.lightened(0.1))
			UITheme.text_ol(T, get_theme_default_font(), sp2 + Vector2(-16, -29), "＋ −", HORIZONTAL_ALIGNMENT_CENTER, 32,
				UITheme.fs(12), light.lightened(0.3), 2)


func _draw_names(font: Font) -> void:
	UITheme.text_ol(_tgt, font, Vector2(236, 274), "上層礦脈", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(26), Color(0.85, 0.75, 1.0, 0.8), 6)
	UITheme.text_ol(_tgt, font, Vector2(440, 640), "地下水脈", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(26), Color(0.6, 0.82, 1.0, 0.8), 6)
