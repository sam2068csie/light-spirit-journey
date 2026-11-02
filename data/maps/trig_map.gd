extends "res://data/maps/unit_map_base.gd"
## 三角函數的世界地圖：月輪島與正弦海岸
##   ・月輪島：形狀就是一個單位圓（環礁），中間的潟湖立著終焉之塔
##   ・正弦海岸：從圓上「角度 0」的地方長出去，海岸線本身就是 y = sin x 的形狀
##     （圓上一點轉動時的高度，攤開來就是這條海岸）
##   ・七座聖地由左到右排好：圓環上緣 1→2，順著海岸 3→4，海岸上的羅盤礁 5→6，最右邊的燈塔 7
##   ・操作、點亮、劇情都在共用底層 unit_map_base.gd；劇情的 key 都加上 "trig/"
## 劇情文字寫在下面的 STORY，可以直接修改。


const UNIT := "trig"
const PREFIX := "trig/"

# ---------------- 地形 ----------------
## 月輪島（單位圓）
const O := Vector2(255, 340)      # 圓心＝終焉之塔
const R := 150.0                  # 圓環中線的半徑
const RW := 40.0                  # 圓環陸地的寬度
## 正弦海岸：y = WY − AMP·sin((x − WX0) / PER · 2π)，從圓上角度 0 的點出發
const WX0 := O.x + R
const WY := O.y
const AMP := 120.0
const PER := 470.0
const CW := 46.0                  # 海岸陸地的寬度
const X_END := 1210.0
## 羅盤礁：海岸往上爬的地方（一個週期的位置）鼓起來的圓形礁石，上面是兩層轉盤
const CP := Vector2(WX0 + PER, WY)
const DR := 70.0

## 七座聖地。kind：ring（圓環上，角度範圍 a）、coast（海岸上，x 範圍）、dial（羅盤礁的左半／右半＋那一段海岸）
const SITES := [
	{"id": "G1", "kind": "ring", "a": Vector2(PI / 2.0, 3.0 * PI / 2.0), "at": 2.6, "lab": Vector2(0, -86)},
	{"id": "G2", "kind": "ring", "a": Vector2(-PI / 2.0, PI / 2.0), "at": 0.85, "lab": Vector2(0, -86)},
	{"id": "G3", "kind": "coast", "x": Vector2(WX0, 640.0), "at": WX0 + PER * 0.25, "lab": Vector2(0, -86)},
	{"id": "G4", "kind": "coast", "x": Vector2(640.0, 845.0), "at": WX0 + PER * 0.75, "lab": Vector2(0, -86)},
	{"id": "G5", "kind": "dial", "side": -1.0, "x": Vector2(845.0, CP.x), "off": Vector2(-38, 22), "lab": Vector2(-10, -132)},
	{"id": "G6", "kind": "dial", "side": 1.0, "x": Vector2(CP.x, 905.0), "off": Vector2(38, -16), "lab": Vector2(104, 84)},
	{"id": "G7", "kind": "coast", "x": Vector2(905.0, X_END), "at": WX0 + PER * 1.25, "lab": Vector2(0, -112)},
]

## 終焉之塔：月輪島中間的潟湖
const TOWER_P := O + Vector2(0, 8)

## 小離島（位置、大小）
const ISLETS := [[Vector2(62, 560), 11.0], [Vector2(600, 584), 13.0], [Vector2(1104, 318), 8.0]]

## 劇情：每一句 {text, who, cam（"wide"、"site"、"isle0" 月輪島、"isle1" 正弦海岸）, site, zoom, light, spirit}
const STORY := {
	"prologue": [
		{"text": "夜空裡有一輪不會落下的月亮。它的倒影落進海裡，變成一座圓圓的島——月輪島。", "cam": "wide"},
		{"text": "月輪島的光從「角度 0」的地方流進海裡，一高一低地向東延伸，連成了正弦海岸。", "cam": "isle1", "zoom": 1.3},
		{"text": "可是有一天，月光漸漸黯淡。島上的刻度模糊了，海浪也亂了節拍……", "cam": "wide"},
		{"text": "上岸囉！咦？這裡的海浪……怎麼一高一低的那麼有規律？我們一起把月光找回來吧！", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.7, "spirit": 0, "appear": true},
		{"text": "先去弧之渡口看看！聽說那裡量角度不用「度」，是用「弧長」來量的耶～", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.5},
	],
	"G1": [
		{"text": "弧之渡口的燈亮了。沿著圓走一段和半徑一樣長的路，轉過的角就是 1 弧度。", "cam": "site", "site": 0, "zoom": 1.8, "light": 0},
		{"text": "所以繞一圈是 2π、半圈是 π！好像在圓上散步一樣～下一站，扇形潟湖！", "who": "光靈", "cam": "site", "site": 1, "zoom": 1.4, "spirit": 1},
	],
	"G2": [
		{"text": "潟湖邊的扇子一把一把展開：弧長 rθ、面積 ½r²θ，整整齊齊。", "cam": "site", "site": 1, "zoom": 1.8, "light": 1},
		{"text": "月輪島修好了！順著角度 0 的地方，我們走上海岸吧～", "who": "光靈", "cam": "site", "site": 2, "zoom": 1.4, "spirit": 2},
	],
	"G3": [
		{"text": "浪之階梯重新排好了。圓上一點轉動時的高度，攤開來就是 y = sin x。", "cam": "site", "site": 2, "zoom": 1.8, "light": 2},
		{"text": "每 2π 就重複一次，這就是週期！海浪一階一階的，好像在跳舞～", "who": "光靈", "cam": "site", "site": 3, "zoom": 1.4, "spirit": 3},
	],
	"G4": [
		{"text": "調音盤的旋鈕轉回原位：拉高、壓扁、左右平移，海浪又聽話了。", "cam": "site", "site": 3, "zoom": 1.8, "light": 3},
		{"text": "a 管高低、b 管快慢……先伸縮再平移，不要搞混！前面有個好大的羅盤耶！", "who": "光靈", "cam": "site", "site": 4, "zoom": 1.4, "spirit": 4},
	],
	"G5": [
		{"text": "羅盤的兩層轉盤一起轉動：先轉 α、再轉 β，指針剛好停在 α + β。", "cam": "site", "site": 4, "zoom": 1.8, "light": 4},
		{"text": "sin(α + β) = sin α cos β + cos α sin β！念一念就記住了～", "who": "光靈", "cam": "site", "site": 5, "zoom": 1.4, "spirit": 5},
	],
	"G6": [
		{"text": "鏡池的水面平靜下來，映出來的角，剛好是原來的兩倍。", "cam": "site", "site": 5, "zoom": 1.8, "light": 5},
		{"text": "同一個角轉兩次是二倍角，對折一半是半角！燈塔就在前面了！", "who": "光靈", "cam": "site", "site": 6, "zoom": 1.4, "spirit": 6},
	],
	"G7": [
		{"text": "燈塔亮了！sin 和 cos 兩道光合成一道，照亮了整片海面。", "cam": "site", "site": 6, "zoom": 1.7, "light": 6},
		{"text": "a sin x + b cos x = r sin(x + φ)，兩道光變一道，好帥！", "who": "光靈", "cam": "site", "site": 6, "zoom": 1.5},
	],
	"epilogue": [
		{"text": "七座聖地全部點亮，月輪島和正弦海岸在夜空下閃閃發光。", "cam": "wide", "all": true},
		{"text": "月亮轉一圈，海浪就起伏一次——角度和波浪，原來是同一件事。", "cam": "wide"},
		{"text": "月輪島的紀念品也送到小屋囉！月輪島中間的終焉之塔，有空也要來挑戰喔～", "who": "光靈", "cam": "wide"},
	],
}

const STORY_TITLES := {"prologue": "序章．月光下的島", "G1": "第一幕．弧之渡口", "G2": "第二幕．扇形潟湖",
	"G3": "第三幕．浪之階梯", "G4": "第四幕．潮汐調音盤", "G5": "第五幕．和角羅盤", "G6": "第六幕．倍角鏡池",
	"G7": "第七幕．疊合燈塔", "epilogue": "終章．月與浪"}


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
	return hover_point(i)

func _region(p: Vector2) -> int:
	return region_at(p)

func _isle_target(k: int) -> Vector2:
	return O if k == 0 else Vector2(760, 330)

func _fx_mid() -> void:
	_draw_dial_hands()





# ================= 資料 =================











# ================= 幾何 =================

static func wave_y(x: float) -> float:
	return WY - AMP * sin((x - WX0) / PER * TAU)


static func wave_p(x: float) -> Vector2:
	return Vector2(x, wave_y(x))


## 海岸中線在 x 處的法向量（往上那一側）
static func wave_n(x: float) -> Vector2:
	var d := Vector2(1.0, -AMP * TAU / PER * cos((x - WX0) / PER * TAU)).normalized()
	return Vector2(d.y, -d.x)


static func ring_p(a: float, r: float = R) -> Vector2:
	return O + Vector2(cos(a), -sin(a)) * r


## 聖地的位置（地標站的地方）
static func site_point(i: int) -> Vector2:
	var st: Dictionary = SITES[i]
	match String(st.kind):
		"ring":
			return ring_p(float(st.at))
		"coast":
			return wave_p(float(st.at))
	return CP + Vector2(st.off)


static func label_point(i: int) -> Vector2:
	return site_point(i) + Vector2(SITES[i].lab)


## 光靈停在名牌上方
static func hover_point(i: int) -> Vector2:
	return label_point(i) + Vector2(0, -36)


## 海岸中線的取樣點（x 從 a 到 b）
static func wave_pts(a: float, b: float, step: float = 6.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var x := a
	while x < b:
		pts.append(wave_p(x))
		x += step
	pts.append(wave_p(b))
	return pts


## 海岸的一側邊緣（side = 1 上緣、−1 下緣）
static func wave_edge(a: float, b: float, side: float, pad: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var x := a
	while x < b + 0.01:
		pts.append(wave_p(x) + wave_n(x) * side * (CW / 2.0 + pad))
		x += 5.0
	return pts


## 海岸一段的色塊（上下緣圍成的多邊形）；落在圓環裡的點推到圓環外緣上，接縫就會貼齊圓環
static func coast_band(a: float, b: float, half: float) -> PackedVector2Array:
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var x := a
	while x < b + 0.01:
		var c := wave_p(minf(x, b))
		var n := wave_n(minf(x, b))
		top.append(_outside_ring(c + n * half))
		bot.append(_outside_ring(c - n * half))
		x += 4.0
	bot.reverse()
	top.append_array(bot)
	return top


static func _outside_ring(p: Vector2) -> Vector2:
	var rr := R + RW / 2.0
	if p.distance_to(O) < rr:
		return O + (p - O).normalized() * rr
	return p


static func arc_pts(a0: float, a1: float, r: float, n: int = 0) -> PackedVector2Array:
	if n <= 0:
		n = maxi(6, int(absf(a1 - a0) * r / 6.0))
	var pts := PackedVector2Array()
	for k in n + 1:
		pts.append(ring_p(lerpf(a0, a1, float(k) / n), r))
	return pts


## 羅盤礁的左半／右半（以 x = CP.x 切開）
static func dial_half(side: float, r: float = DR) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 25:
		var a := -PI / 2.0 + PI * k / 24.0
		pts.append(CP + Vector2(cos(a) * side, sin(a)) * r)
	return pts


## 這一點在陸地上的哪一座聖地（−1：海上或沒有歸屬的陸地）
static func region_at(p: Vector2) -> int:
	var d := p.distance_to(O)
	if absf(d - R) <= RW / 2.0 + 2.0:
		var a := atan2(-(p.y - O.y), p.x - O.x)
		return 1 if absf(a) <= PI / 2.0 else 0
	if p.distance_to(CP) <= DR:
		return 4 if p.x < CP.x else 5
	if p.x >= WX0 and absf(p.y - wave_y(p.x)) <= CW / 2.0 + 4.0:
		for i in range(2, SITES.size()):
			var xr: Vector2 = SITES[i].x
			if p.x >= xr.x and p.x <= xr.y:
				return i
	return -1


# ================= 點選 =================















# ================= 下方的資訊卡 =================







# ================= 更新 =================



## 這座聖地的陸地上隨機一點（冒光點用）
func _rand_point(i: int) -> Vector2:
	var st: Dictionary = SITES[i]
	match String(st.kind):
		"ring":
			var a := randf_range(st.a.x, st.a.y)
			return ring_p(a, R + randf_range(-0.4, 0.4) * RW)
		"coast":
			var x := randf_range(st.x.x, minf(st.x.y, W))
			return wave_p(x) + wave_n(x) * randf_range(-0.4, 0.4) * CW
	var ang := randf_range(-PI / 2.0, PI / 2.0)
	return CP + Vector2(cos(ang) * float(st.side), sin(ang)) * randf_range(8.0, DR - 8.0)


# ================= 繪圖 =================





const LAND := Color("1f2647")
const HIGH := Color("272f58")
const SAND := Color(0.85, 0.8, 0.62, 0.30)


## 不會動的陸地（畫在 _land）
func _draw_land(layer: CanvasItem) -> void:
	_tgt = layer
	var L := layer
	# 小離島
	for it in ISLETS:
		var c: Vector2 = it[0]
		var r: float = it[1]
		UITheme.dot(L, c, r + 9.0, Color(0.35, 0.7, 0.95, 0.06))
		UITheme.dot(L, c, r, LAND)
		UITheme.dot(L, c + Vector2(-1, -1), r * 0.55, HIGH)
		L.draw_arc(c, r, 0, TAU, 24, SAND, 2.0, true)
	# ---- 月輪島：淺灘、陸地、潟湖 ----
	L.draw_arc(O, R, 0, TAU, 128, Color(0.35, 0.7, 0.95, 0.05), RW + 44.0, true)
	L.draw_arc(O, R, 0, TAU, 128, Color(0.4, 0.75, 1.0, 0.08), RW + 22.0, true)
	UITheme.dot(L, O, R - RW / 2.0, Color("0f2d52"))          # 潟湖（比外海淺）
	UITheme.dot(L, O, R - RW / 2.0 - 10.0, Color("12355e"))
	# ---- 正弦海岸 ----
	var mid := wave_pts(WX0, X_END)
	L.draw_polyline(mid, Color(0.35, 0.7, 0.95, 0.05), CW + 44.0, true)
	L.draw_polyline(mid, Color(0.4, 0.75, 1.0, 0.08), CW + 22.0, true)
	UITheme.dot(L, CP, DR + 22.0, Color(0.35, 0.7, 0.95, 0.05))
	UITheme.dot(L, CP, DR + 11.0, Color(0.4, 0.75, 1.0, 0.08))
	# 陸地
	L.draw_arc(O, R, 0, TAU, 128, LAND, RW, true)
	L.draw_polyline(mid, LAND, CW, true)
	UITheme.dot(L, CP, DR, LAND)
	# 內陸比較亮
	L.draw_arc(O, R, 0, TAU, 128, HIGH, RW - 18.0, true)
	L.draw_polyline(mid, HIGH, CW - 18.0, true)
	UITheme.dot(L, CP, DR - 9.0, HIGH)
	# 點亮的區域
	for i in SITES.size():
		if SITES[i].kind != "dial":
			_draw_region_fill(L, i)
	for i in [4, 5]:          # 羅盤礁最後畫，蓋住穿過它的海岸
		_draw_region_fill(L, i)
	# 沙灘海岸線（和別塊陸地相接的地方不畫）
	_draw_sand(L)
	# 羅盤礁上的兩層轉盤（地面的刻紋）
	var gd := maxf(glow[4], glow[5])
	L.draw_arc(CP, DR - 14.0, 0, TAU, 64, Color(1, 0.85, 0.45, 0.25 + 0.45 * gd), 2.0, true)
	L.draw_arc(CP, DR - 30.0, 0, TAU, 48, Color(0.8, 0.6, 1.0, 0.25 + 0.45 * gd), 2.0, true)
	for k in 12:
		var d := Vector2(cos(k * PI / 6.0), sin(k * PI / 6.0))
		L.draw_line(CP + d * (DR - 18.0), CP + d * (DR - 10.0), Color(1, 1, 1, 0.18 + 0.3 * gd), 1.5)
	# 圓環上的刻度：0、π/2、π、3π/2（每 π/6 一條小刻度）
	for k in 12:
		var a := k * PI / 6.0
		var big := k % 3 == 0
		var hl := 16.0 if big else 8.0
		L.draw_line(ring_p(a, R - hl), ring_p(a, R + hl), Color(1, 1, 1, 0.32 if big else 0.16), 2.0 if big else 1.5)
	# 第一關：「1 弧度」的弧（弧長＝半徑），第二關：潟湖裡的扇形
	var g1: float = glow[0]
	L.draw_polyline(arc_pts(2.1, 3.1, R), Color(1, 0.85, 0.4, 0.28 + 0.6 * g1), 5.0, true)
	L.draw_line(O, ring_p(2.1, R - RW / 2.0), Color(1, 0.85, 0.4, 0.12 + 0.35 * g1), 1.5, true)
	L.draw_line(O, ring_p(3.1, R - RW / 2.0), Color(1, 0.85, 0.4, 0.12 + 0.35 * g1), 1.5, true)
	var g2: float = glow[1]
	var sec := PackedVector2Array([O])
	sec.append_array(arc_pts(0.35, 1.25, R - RW / 2.0 - 4.0, 20))
	L.draw_colored_polygon(sec, Color(1, 0.7, 0.33, 0.07 + 0.16 * g2))
	L.draw_polyline(arc_pts(0.35, 1.25, R - RW / 2.0 - 4.0, 20), Color(1, 0.7, 0.33, 0.25 + 0.6 * g2), 3.0, true)
	# 山和樹
	_draw_details(L)
	# 區域之間的虛線邊界
	_draw_borders(L)
	_tgt = self


func _draw_sand(L: CanvasItem) -> void:
	if not _cache.has("sand"):
		var lines := []
		# 圓環外緣：海岸接上來的地方（角度 0 附近）不畫
		lines.append(arc_pts(0.32, TAU - 0.22, R + RW / 2.0, 120))
		lines.append(arc_pts(0, TAU, R - RW / 2.0, 120))
		# 海岸的上下緣：在圓環裡、羅盤礁裡的部分不畫
		for side in [1.0, -1.0]:
			var cur := PackedVector2Array()
			for p in wave_edge(WX0, X_END, side):
				var inside := p.distance_to(O) < R + RW / 2.0 or p.distance_to(CP) < DR - 1.0
				if inside:
					if cur.size() > 1:
						lines.append(cur)
					cur = PackedVector2Array()
				else:
					cur.append(p)
			if cur.size() > 1:
				lines.append(cur)
		# 羅盤礁的外緣：在海岸裡的部分不畫
		var cur2 := PackedVector2Array()
		for k in 97:
			var a := TAU * k / 96.0
			var p := CP + Vector2(cos(a), sin(a)) * DR
			if absf(p.y - wave_y(p.x)) < CW / 2.0 * absf(wave_n(p.x).y) + 0.5:
				if cur2.size() > 1:
					lines.append(cur2)
				cur2 = PackedVector2Array()
			else:
				cur2.append(p)
		if cur2.size() > 1:
			lines.append(cur2)
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
	var c1 := Color(c.r, c.g, c.b, 0.30 * gl).darkened(0.1)
	var c2 := Color(c.r, c.g, c.b, 0.22 * gl)
	match String(st.kind):
		"ring":
			L.draw_arc(O, R, -st.a.y, -st.a.x, 64, c1, RW, true)
			L.draw_arc(O, R, -st.a.y, -st.a.x, 64, c2, RW - 18.0, true)
		"coast":
			if float(st.x.x) <= WX0 + 1.0:
				# 從圓環接出來的那一段：沿著圓環外緣切齊，不留縫
				L.draw_colored_polygon(coast_band(WX0, minf(st.x.y, X_END), CW / 2.0), c1)
				L.draw_colored_polygon(coast_band(WX0, minf(st.x.y, X_END), CW / 2.0 - 9.0), c2)
			else:
				var pts := wave_pts(st.x.x, minf(st.x.y, X_END))
				L.draw_polyline(pts, c1, CW, false)
				L.draw_polyline(pts, c2, CW - 18.0, false)
		"dial":
			L.draw_colored_polygon(dial_half(st.side), c1)
			L.draw_colored_polygon(dial_half(st.side, DR - 9.0), c2)
			var pts2 := wave_pts(st.x.x, st.x.y)
			L.draw_polyline(pts2, c1, CW, false)


## 點亮區域的發光邊（會脈動，所以每幀畫）
func _draw_region_ring(i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var st: Dictionary = SITES[i]
	var c: Color = Center.level_info(st.id).color
	var pulse := 0.85 + 0.15 * sin(t * 2.0 + i)
	var lines := []
	match String(st.kind):
		"ring":
			lines.append(arc_pts(st.a.x, st.a.y, R + RW / 2.0))
			lines.append(arc_pts(st.a.x, st.a.y, R - RW / 2.0))
		"coast":
			var x0 := float(st.x.x)
			for side in [1.0, -1.0]:
				# 伸進羅盤礁、圓環的部分不畫
				var cur := PackedVector2Array()
				for q in wave_edge(x0, minf(st.x.y, X_END), side):
					if q.distance_to(CP) < DR or q.distance_to(O) < R + RW / 2.0:
						if cur.size() > 1:
							lines.append(cur)
						cur = PackedVector2Array()
					else:
						cur.append(q)
				if cur.size() > 1:
					lines.append(cur)
		"dial":
			lines.append(dial_half(st.side))
	for ln in lines:
		_tgt.draw_polyline(ln, Color(c.r, c.g, c.b, 0.25 * gl * pulse), 7.0)
		_tgt.draw_polyline(ln, Color(c.r, c.g, c.b, 0.9 * gl).lightened(0.3), 2.0, true)


func _make_details() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	for k in 70:
		var p: Vector2
		if k < 26:
			p = ring_p(rng.randf() * TAU, R + rng.randf_range(-0.32, 0.32) * RW)
		else:
			var x := rng.randf_range(WX0 + 30.0, W + 20.0)
			p = wave_p(x) + wave_n(x) * rng.randf_range(-0.32, 0.32) * CW
		var si := region_at(p)
		if si < 0:
			continue
		var near := false
		for j in SITES.size():
			if p.distance_to(site_point(j) + Vector2(0, -16)) < 40.0:
				near = true
		if p.distance_to(CP) < DR + 6.0:
			near = true          # 轉盤上不放東西
		if not near:
			out.append({"p": p, "si": si, "k": k})
	return out




## 區域之間的虛線邊界（兩邊都點亮時變成金色）
func _draw_borders(L: CanvasItem) -> void:
	var cuts := [
		[0, 1, ring_p(PI / 2.0, R - RW / 2.0), ring_p(PI / 2.0, R + RW / 2.0)],
		[0, 1, ring_p(3.0 * PI / 2.0, R - RW / 2.0), ring_p(3.0 * PI / 2.0, R + RW / 2.0)],
	]
	var x23: float = SITES[2].x.y
	cuts.append([2, 3, wave_p(x23) + wave_n(x23) * CW / 2.0, wave_p(x23) - wave_n(x23) * CW / 2.0])
	# 羅盤礁的左右兩半
	cuts.append([4, 5, CP + Vector2(0, -DR), CP + Vector2(0, DR)])
	for ct in cuts:
		var both: bool = glow[ct[0]] > 0.6 and glow[ct[1]] > 0.6
		L.draw_dashed_line(ct[2], ct[3], Color(1, 0.88, 0.55, 0.65) if both else Color(1, 1, 1, 0.28), 2.0, 7.0)




## 旅程路線：由左到右的一串光點（走過的路段是金色）
func _route(i: int) -> PackedVector2Array:
	var key := "route%d" % i
	if _cache.has(key):
		return _cache[key]
	var pts := PackedVector2Array()
	match i:
		0:
			pts = arc_pts(SITES[0].at, SITES[1].at, R)
		1:
			pts = arc_pts(SITES[1].at, 0.0, R)
			pts.append_array(wave_pts(WX0 + 4.0, SITES[2].at))
		2:
			pts = wave_pts(SITES[2].at, SITES[3].at)
		3:
			pts = wave_pts(SITES[3].at, CP.x - DR + 4.0)
			pts.append(site_point(4))
		4:
			pts = PackedVector2Array([site_point(4), CP, site_point(5)])
		5:
			pts = PackedVector2Array([site_point(5)])
			pts.append_array(wave_pts(CP.x + DR - 4.0, SITES[6].at))
	_cache[key] = pts
	return pts




## 羅盤礁的兩根指針：外圈 α（金色）、內圈再轉 β（紫色）→ 指到 α + β
func _draw_dial_hands() -> void:
	var g5: float = glow[4]
	var g6: float = glow[5]
	var al := 1.1 + (0.2 * sin(t * 0.6) if g5 > 0.5 else 0.0)
	var be := 0.8 + (0.15 * sin(t * 0.8 + 1.0) if g5 > 0.5 else 0.0)
	var ca := Color(1, 0.85, 0.45, 0.45 + 0.5 * g5)
	var cb := Color(0.82, 0.62, 1.0, 0.45 + 0.5 * g5)
	_tgt.draw_line(CP, CP + Vector2(cos(al), -sin(al)) * (DR - 14.0), ca, 3.0, true)
	_tgt.draw_line(CP, CP + Vector2(cos(al + be), -sin(al + be)) * (DR - 14.0), cb, 3.0, true)
	var arc := PackedVector2Array()
	for k in 13:
		var a := al + be * k / 12.0
		arc.append(CP + Vector2(cos(a), -sin(a)) * (DR - 40.0))
	_tgt.draw_polyline(arc, cb, 2.0, true)
	# 倍角：亮起來之後，鏡池那一側多一根「2α」的淡指針
	if g6 > 0.05:
		_tgt.draw_line(CP, CP + Vector2(cos(2.0 * al), -sin(2.0 * al)) * (DR - 22.0), Color(1, 0.85, 0.45, 0.35 * g6), 2.0, true)
	UITheme.dot(_tgt, CP, 4.0, Color(1, 1, 1, 0.8))




## 七座聖地的地標
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
		0:   # 弧之渡口：兩根柱子撐著一段圓弧（弧長＝半徑），掛著一盞燈
			var c0 := p + Vector2(0, -4)
			T.draw_line(c0 + Vector2(-20, 0), c0 + Vector2(-20, -30), base, 4.0)
			T.draw_line(c0 + Vector2(20, 0), c0 + Vector2(20, -30), base, 4.0)
			var arc := PackedVector2Array()
			for k in 17:
				var a := PI / 2.0 - 0.5 + 1.0 * k / 16.0
				arc.append(c0 + Vector2(0, -6) + Vector2(cos(a), -sin(a)) * 30.0)
			if gl > 0.05:
				T.draw_polyline(arc, Color(col.r, col.g, col.b, 0.3 * gl), 10.0, true)
			T.draw_polyline(arc, base.lightened(0.15), 4.0, true)
			T.draw_line(c0 + Vector2(0, -36), c0 + Vector2(0, -26), base, 1.5)
			UITheme.dot(T, c0 + Vector2(0, -22), 4.5, light if gl > 0.05 else dark.lightened(0.2))
			if gl > 0.05:
				UITheme.dot(T, c0 + Vector2(0, -22), 11.0, Color(col.r, col.g, col.b, 0.2 * gl))
		1:   # 扇形潟湖：一把打開的扇子
			var c1 := p + Vector2(0, -6)
			var open := 1.9 if gl > 0.5 else 1.5 + 0.08 * sin(t * 1.5)
			var fan := PackedVector2Array([c1])
			for k in 13:
				var a := PI / 2.0 - open / 2.0 + open * k / 12.0
				fan.append(c1 + Vector2(cos(a), -sin(a)) * 34.0)
			T.draw_colored_polygon(fan, dark.lightened(0.12))
			for k in 7:
				var a := PI / 2.0 - open / 2.0 + open * k / 6.0
				T.draw_line(c1, c1 + Vector2(cos(a), -sin(a)) * 34.0, base.lightened(0.2), 1.5)
			var rim := fan.slice(1)
			T.draw_polyline(rim, light if gl > 0.05 else base.lightened(0.2), 3.0, true)
			UITheme.dot(T, c1, 3.0, base.lightened(0.3))
		2:   # 浪之階梯：沿著正弦曲線排的台階
			for k in 5:
				var x := -24.0 + 12.0 * k
				var h := 14.0 + 16.0 * sin(PI * k / 4.0)
				T.draw_rect(Rect2(p + Vector2(x - 5, -h), Vector2(10, h)), base.lightened(0.04 * k))
				T.draw_rect(Rect2(p + Vector2(x - 5, -h), Vector2(10, 2.5)), light if gl > 0.05 else base.lightened(0.25))
			if gl > 0.05:
				var u := fposmod(t * 0.35, 1.0)
				UITheme.dot(T, p + Vector2(-24.0 + 48.0 * u, -20.0 - 16.0 * sin(PI * u)), 3.5, Color(1, 1, 0.85, gl))
		3:   # 潮汐調音盤：台座、上面的波形螢幕、兩個旋鈕
			T.draw_rect(Rect2(p + Vector2(-22, -14), Vector2(44, 14)), base)
			T.draw_rect(Rect2(p + Vector2(-26, -44), Vector2(52, 28)), dark.lightened(0.1))
			T.draw_rect(Rect2(p + Vector2(-26, -44), Vector2(52, 28)), base.lightened(0.2), false, 2.0)
			var wv := PackedVector2Array()
			var amp := 9.0 if gl > 0.5 else 4.0 + 5.0 * absf(sin(t * 1.2))
			for k in 21:
				var u := k / 20.0
				wv.append(p + Vector2(-22.0 + 44.0 * u, -30.0 - amp * sin(TAU * u + (t * 2.0 if gl > 0.5 else 0.0))))
			T.draw_polyline(wv, light if gl > 0.05 else base.lightened(0.3), 2.0, true)
			UITheme.dot(T, p + Vector2(-10, -7), 3.5, base.lightened(0.35))
			UITheme.dot(T, p + Vector2(10, -7), 3.5, base.lightened(0.35))
		4:   # 和角羅盤：台座上的小羅盤，兩根指針
			T.draw_rect(Rect2(p + Vector2(-8, -12), Vector2(16, 12)), base)
			var cc := p + Vector2(0, -30)
			UITheme.dot(T, cc, 17.0, dark.lightened(0.1))
			T.draw_arc(cc, 17.0, 0, TAU, 32, base.lightened(0.3), 2.0, true)
			var a1 := 0.5 + (0.3 * sin(t * 0.9) if gl > 0.5 else 0.6 * sin(t * 2.3))
			var a2 := a1 + 0.9
			T.draw_line(cc, cc + Vector2(cos(a1), -sin(a1)) * 14.0, Color(1, 0.85, 0.45, 0.6 + 0.4 * gl), 2.5)
			T.draw_line(cc, cc + Vector2(cos(a2), -sin(a2)) * 14.0, Color(0.85, 0.65, 1.0, 0.6 + 0.4 * gl), 2.5)
			UITheme.dot(T, cc, 2.5, Color(1, 1, 1, 0.8))
		5:   # 倍角鏡池：一池水，上面的角在水裡映成兩倍
			var pc := p + Vector2(0, -6)
			var pool := PackedVector2Array()
			for k in 25:
				var ang := TAU * k / 24.0
				pool.append(pc + Vector2(cos(ang) * 26.0, sin(ang) * 8.0))
			T.draw_colored_polygon(pool, Color(0.3, 0.55, 0.9, 0.35).lerp(Color(col.r, col.g, col.b, 0.5), gl))
			pool.append(pool[0])
			T.draw_polyline(pool, base.lightened(0.25), 2.0, true)
			var v := pc + Vector2(-14, -2)
			var al := 0.5
			T.draw_line(v, v + Vector2(30, 0), base.lightened(0.3), 2.0)
			T.draw_line(v, v + Vector2(cos(al), -sin(al)) * 30.0, base.lightened(0.3), 2.0)
			var sw := 0.35 + 0.65 * (gl if gl > 0.05 else 0.5 + 0.5 * sin(t * 1.6))
			T.draw_line(v, v + Vector2(cos(2.0 * al), -sin(2.0 * al)) * 30.0 * sw, light, 2.0)
			T.draw_arc(v, 10.0, -2.0 * al, 0, 12, light, 1.5, true)
		6:   # 疊合燈塔：塔身＋兩道光（亮起來時合成一道）
			T.draw_colored_polygon(PackedVector2Array([p + Vector2(-11, 0), p + Vector2(11, 0), p + Vector2(6, -54), p + Vector2(-6, -54)]), base)
			for yy in [-14.0, -30.0]:
				T.draw_rect(Rect2(p + Vector2(-9 + absf(yy) * 0.06, yy - 6), Vector2(18 - absf(yy) * 0.12, 5)), dark.lightened(0.25))
			T.draw_rect(Rect2(p + Vector2(-8, -66), Vector2(16, 12)), dark.lightened(0.15))
			T.draw_colored_polygon(PackedVector2Array([p + Vector2(-10, -66), p + Vector2(10, -66), p + Vector2(0, -76)]), base.lightened(0.15))
			UITheme.dot(T, p + Vector2(0, -60), 4.5, light if gl > 0.05 else dark.lightened(0.3))
			if gl > 0.05:
				var lp := p + Vector2(0, -60)
				var sw2 := 0.25 * sin(t * 0.7)
				var d1 := Vector2(cos(PI * 0.62 + sw2), -sin(PI * 0.62 + sw2))
				var d2 := Vector2(cos(PI * 0.38 + sw2), -sin(PI * 0.38 + sw2))
				var d3 := (d1 + d2).normalized()
				T.draw_colored_polygon(PackedVector2Array([lp, lp + d1 * 120.0 + d1.orthogonal() * 14.0, lp + d1 * 120.0 - d1.orthogonal() * 14.0]),
					Color(0.35, 0.85, 1.0, 0.10 * gl))
				T.draw_colored_polygon(PackedVector2Array([lp, lp + d2 * 120.0 + d2.orthogonal() * 14.0, lp + d2 * 120.0 - d2.orthogonal() * 14.0]),
					Color(1.0, 0.5, 0.72, 0.10 * gl))
				T.draw_colored_polygon(PackedVector2Array([lp, lp + d3 * 170.0 + d3.orthogonal() * 22.0, lp + d3 * 170.0 - d3.orthogonal() * 22.0]),
					Color(1, 0.92, 0.55, 0.14 * gl))
				UITheme.dot(T, lp, 14.0, Color(col.r, col.g, col.b, 0.25 * gl))








func _draw_names(font: Font) -> void:
	UITheme.text_ol(_tgt, font, Vector2(30, 600), "月輪島", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(30), Color(1.0, 0.86, 0.5, 0.85), 6)
	UITheme.text_ol(_tgt, font, Vector2(462, 486), "正弦海岸", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(30), Color(0.6, 0.85, 1.0, 0.85), 6)


# ================= 劇情 =================











