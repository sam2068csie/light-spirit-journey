extends "res://data/maps/unit_map_base.gd"
## 數與式的世界地圖：數之原野
##   ・一條筆直的數線柵欄橫過整片原野（往右的箭頭），八座聖地剛好站在數線的整數刻度上，由左往右 R1 → R8
##   ・柵欄上方、下方是一塊一塊的方格麥田，風吹過時麥浪一波一波
##   ・右上方的小丘上立著終焉之塔（八座聖地蓋好後開放）
##   ・操作、點亮、劇情都在共用底層 unit_map_base.gd；劇情的 key 都加上 "num/"
## 劇情文字寫在下面的 STORY，可以直接修改。

const UNIT := "h1num"
const PREFIX := "num/"

# ---------------- 地形 ----------------
const ROAD_Y := 372.0             # 數線柵欄的高度
const ROAD_X0 := 50.0
const ROAD_X1 := 1100.0
const CW := 34.0                  # 柵欄路的寬度
const TICK := 60.0                # 刻度間隔（聖地站在每隔一格的整數上）
const ZERO_X := 60.0              # 原點的位置（聖地站在 1、3、5…15）
## 原野的輪廓
const FIELD := [Vector2(20, 150), Vector2(90, 90), Vector2(330, 70), Vector2(620, 92), Vector2(860, 60), Vector2(1100, 100),
	Vector2(1138, 220), Vector2(1130, 470), Vector2(1080, 600), Vector2(760, 630), Vector2(420, 618), Vector2(140, 610), Vector2(24, 520)]

## 八座聖地：x 是數線上的位置，lab 是名牌的位置（相對聖地）
const SITES := [
	{"id": "R1", "x": 120.0, "lab": Vector2(0, -100)},
	{"id": "R2", "x": 240.0, "lab": Vector2(0, 86)},
	{"id": "R3", "x": 360.0, "lab": Vector2(0, -100)},
	{"id": "R4", "x": 480.0, "lab": Vector2(0, 86)},
	{"id": "R5", "x": 600.0, "lab": Vector2(0, -100)},
	{"id": "R6", "x": 720.0, "lab": Vector2(0, 86)},
	{"id": "R7", "x": 840.0, "lab": Vector2(0, -100)},
	{"id": "R8", "x": 960.0, "lab": Vector2(0, 86)},
]
const HALF := 60.0                # 每座聖地占的數線長度的一半

## 終焉之塔：右上方的小丘
const TOWER_P := Vector2(1000, 210)
const HILL_R := 62.0

## 劇情：每一句 {text, who, cam（"wide"、"site"、"isle0" 左半邊、"isle1" 右半邊）, site, zoom, light, spirit}
const STORY := {
	"prologue": [
		{"text": "曦光大陸的西南邊，是一片金黃色的原野。一條筆直的柵欄橫過原野，上面刻滿了刻度——「數之原野」。", "cam": "wide"},
		{"text": "每一根柵欄柱都標著一個數。從左到右，數越來越大，一直延伸到看不見的地方。", "cam": "isle0", "zoom": 1.3},
		{"text": "可是原野上的風車停了，柵欄的刻度也模糊了……", "cam": "wide"},
		{"text": "哇，風車的扇葉上寫著數字耶！2、7、2、7……轉起來會不會變成一個小數？", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.7, "spirit": 0, "appear": true},
		{"text": "先讓入口的風車轉起來吧～", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.5},
	],
	"R1": [
		{"text": "風車小數轉起來了。扇葉上的數字一圈一圈接下去，就是循環小數。", "cam": "site", "site": 0, "zoom": 1.8, "light": 0},
		{"text": "循環小數都能寫成分數，分數也都能寫成有限或循環小數——它們都是有理數！下一站有一條繩子～", "who": "光靈", "cam": "site", "site": 1, "zoom": 1.4, "spirit": 1},
	],
	"R2": [
		{"text": "繩上的珠子定住了。兩根柱子之間的每一點，都把繩子分成固定的比。", "cam": "site", "site": 1, "zoom": 1.8, "light": 1},
		{"text": "內分點在中間，外分點跑到外面去——分點公式就是加權平均！", "who": "光靈", "cam": "site", "site": 2, "zoom": 1.4, "spirit": 2},
	],
	"R3": [
		{"text": "天秤市集熱鬧起來了。x、y 的範圍一合起來，就知道 x + y、xy 會落在哪裡。", "cam": "site", "site": 2, "zoom": 1.8, "light": 2},
		{"text": "減一個數，等於加上它的相反數。乘負數的時候，不等號要轉向！", "who": "光靈", "cam": "site", "site": 3, "zoom": 1.4, "spirit": 3},
	],
	"R4": [
		{"text": "圍籬牧場的草長滿了。周長一樣的時候，圍成正方形的面積最大。", "cam": "site", "site": 3, "zoom": 1.8, "light": 3},
		{"text": "算術平均數不會比幾何平均數小，兩個數一樣大時剛好相等！", "who": "光靈", "cam": "site", "site": 4, "zoom": 1.4, "spirit": 4},
	],
	"R5": [
		{"text": "篩種倉庫的種子分好了：有理數一籃、無理數一籃。", "cam": "site", "site": 4, "zoom": 1.8, "light": 4},
		{"text": "有理數加有理數還是有理數，可是無理數加無理數就不一定了喔～", "who": "光靈", "cam": "site", "site": 5, "zoom": 1.4, "spirit": 5},
	],
	"R6": [
		{"text": "剝殼磨坊的石磨轉起來了。雙重根號一層一層剝開，露出裡面簡單的根號。", "cam": "site", "site": 5, "zoom": 1.8, "light": 5},
		{"text": "剝雙重根號的祕訣：找兩個數，加起來是外面那個數、乘起來是裡面那個數！", "who": "光靈", "cam": "site", "site": 6, "zoom": 1.4, "spirit": 6},
	],
	"R7": [
		{"text": "方田拼圖拼好了。大正方形切成小塊，就是乘法公式。", "cam": "site", "site": 6, "zoom": 1.8, "light": 6},
		{"text": "最後一站在山谷裡，那裡的水渠有一個平平的谷底！", "who": "光靈", "cam": "site", "site": 7, "zoom": 1.4, "spirit": 7},
	],
	"R8": [
		{"text": "谷底水渠的水流起來了。|x − a| 就是 x 到 a 的距離。", "cam": "site", "site": 7, "zoom": 1.7, "light": 7},
		{"text": "到好幾根柱子的距離加起來，站在中間那一根最近——中位數！", "who": "光靈", "cam": "site", "site": 7, "zoom": 1.5},
	],
	"epilogue": [
		{"text": "八座聖地全部點亮，數線柵欄從左到右閃閃發光，麥田一片金黃。", "cam": "wide", "all": true},
		{"text": "有理數、無理數、根號、絕對值……每一個數，在數線上都有自己的位置。", "cam": "wide"},
		{"text": "數之原野的紀念品也送到小屋囉！小丘上的終焉之塔，有空也要來挑戰喔～", "who": "光靈", "cam": "wide"},
	],
}

const STORY_TITLES := {"prologue": "序章．刻滿數字的柵欄", "R1": "第一幕．風車小數", "R2": "第二幕．繩上珠子",
	"R3": "第三幕．天秤市集", "R4": "第四幕．圍籬牧場", "R5": "第五幕．篩種倉庫", "R6": "第六幕．剝殼磨坊",
	"R7": "第七幕．方田拼圖", "R8": "第八幕．谷底水渠", "epilogue": "終章．數與式"}


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
	return site_point(i) + Vector2(0, -60)

func _region(p: Vector2) -> int:
	return region_at(p)

func _isle_target(k: int) -> Vector2:
	return Vector2(330, 360) if k == 0 else Vector2(820, 360)


# ================= 幾何 =================

static func site_point(i: int) -> Vector2:
	return Vector2(float(SITES[i].x), ROAD_Y)


static func label_point(i: int) -> Vector2:
	return site_point(i) + Vector2(SITES[i].lab)


## 這一點在哪一座聖地（−1：麥田或其他地方）
static func region_at(p: Vector2) -> int:
	if absf(p.y - ROAD_Y) > CW / 2.0 + 6.0:
		return -1
	for i in SITES.size():
		if absf(p.x - float(SITES[i].x)) < HALF:
			return i
	return -1


## 麥田裡的點靠近哪一座聖地（給麥穗染色）
static func near_site(p: Vector2) -> int:
	var best := 0
	for i in SITES.size():
		if absf(p.x - float(SITES[i].x)) < absf(p.x - float(SITES[best].x)):
			best = i
	return best


func _rand_point(i: int) -> Vector2:
	return Vector2(float(SITES[i].x) + randf_range(-HALF + 6.0, HALF - 6.0), ROAD_Y + randf_range(-0.35, 0.35) * CW)


static func band(x0: float, x1: float, half: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, ROAD_Y - half), Vector2(x1, ROAD_Y - half), Vector2(x1, ROAD_Y + half), Vector2(x0, ROAD_Y + half)])


# ================= 繪圖 =================

const LAND := Color("2a2a3e")
const HIGH := Color("33334c")
const WHEAT := Color("8a7440")
const SAND := Color(0.95, 0.82, 0.5, 0.30)
const ROAD := Color("4a4258")
const POST := Color("6a5a48")


func _draw_land(layer: CanvasItem) -> void:
	_tgt = layer
	var L := layer
	var field := PackedVector2Array(FIELD)
	var c0 := Vector2(580, 360)
	var big := PackedVector2Array()
	for p in field:
		big.append(p + (p - c0).normalized() * 16.0)
	L.draw_colored_polygon(big, Color(0.95, 0.8, 0.45, 0.05))
	L.draw_colored_polygon(field, LAND)
	var inner := PackedVector2Array()
	for p in field:
		inner.append(c0 + (p - c0) * 0.92)
	L.draw_colored_polygon(inner, HIGH)
	# 方格麥田：柵欄上下各一排田
	_draw_wheat_plots(L)
	var closed := field.duplicate()
	closed.append(field[0])
	L.draw_polyline(closed, SAND, 3.0, true)
	# 小丘（終焉之塔）
	UITheme.dot(L, TOWER_P + Vector2(0, 10), HILL_R + 12.0, Color(0.95, 0.8, 0.45, 0.06))
	UITheme.dot(L, TOWER_P + Vector2(0, 10), HILL_R, Color("3a3a56"))
	UITheme.dot(L, TOWER_P + Vector2(0, 6), HILL_R - 14.0, Color("434363"))
	# 柵欄路
	L.draw_colored_polygon(band(ROAD_X0, ROAD_X1, CW / 2.0 + 3.0), Color(0, 0, 0, 0.2))
	L.draw_colored_polygon(band(ROAD_X0, ROAD_X1, CW / 2.0), ROAD)
	for i in SITES.size():
		_draw_region_fill(L, i)
	# 數線：中間一條線、往右的箭頭、刻度
	L.draw_line(Vector2(ROAD_X0 + 6, ROAD_Y), Vector2(ROAD_X1 - 4, ROAD_Y), Color(1, 0.95, 0.85, 0.5), 2.0, true)
	L.draw_colored_polygon(PackedVector2Array([Vector2(ROAD_X1 + 10, ROAD_Y), Vector2(ROAD_X1 - 6, ROAD_Y - 8), Vector2(ROAD_X1 - 6, ROAD_Y + 8)]),
		Color(1, 0.95, 0.85, 0.6))
	var font := ThemeDB.fallback_font
	var x := ZERO_X
	var n := 0
	while x < ROAD_X1 - 10.0:
		var big_t := _site_on(x)
		var hl := 9.0 if big_t else 5.0
		L.draw_line(Vector2(x, ROAD_Y - hl), Vector2(x, ROAD_Y + hl), Color(1, 0.95, 0.85, 0.55 if big_t else 0.3), 2.0)
		if not big_t:
			var s := str(n).replace("-", "−")
			var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			L.draw_string(font, Vector2(x - w / 2.0, ROAD_Y + CW / 2.0 + 14.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.95, 0.85, 0.35))
		x += TICK
		n += 1
	# 柵欄：上下兩排小柱子
	var px := ROAD_X0 + 14.0
	while px < ROAD_X1 - 10.0:
		for side in [-1.0, 1.0]:
			var y0: float = ROAD_Y + side * (CW / 2.0 + 2.0)
			L.draw_line(Vector2(px, y0), Vector2(px, y0 - 9.0), POST, 3.0)
		px += 30.0
	L.draw_line(Vector2(ROAD_X0 + 10, ROAD_Y - CW / 2.0 - 7.0), Vector2(ROAD_X1 - 10, ROAD_Y - CW / 2.0 - 7.0), POST.darkened(0.15), 2.0)
	L.draw_line(Vector2(ROAD_X0 + 10, ROAD_Y + CW / 2.0 - 4.0), Vector2(ROAD_X1 - 10, ROAD_Y + CW / 2.0 - 4.0), POST.darkened(0.15), 2.0)
	_draw_details(L)
	_draw_borders(L)
	_tgt = self


func _site_on(x: float) -> bool:
	for st in SITES:
		if absf(float(st.x) - x) < 1.0:
			return true
	return false


## 柵欄上下的方格麥田（一塊一塊，靠近的聖地點亮時染上它的顏色）
func _draw_wheat_plots(L: CanvasItem) -> void:
	for row in [[150.0, 300.0], [445.0, 590.0]]:
		var x := 70.0
		var k := 0
		while x < 1060.0:
			var w := 96.0 + 14.0 * float((k * 7) % 3)
			var rc := Rect2(x, row[0] + 6.0 * float(k % 2), w - 10.0, row[1] - row[0] - 6.0 * float(k % 2))
			if rc.end.x > 1080.0:
				break
			var c0 := rc.get_center()
			if not Geometry2D.is_point_in_polygon(c0, PackedVector2Array(FIELD)) or c0.distance_to(TOWER_P) < HILL_R + 60.0:
				x += w
				k += 1
				continue
			var si := near_site(c0)
			var g: float = glow[si]
			var c: Color = Center.level_info(SITES[si].id).color
			var base := WHEAT.darkened(0.45).lerp(Color(c.r, c.g, c.b).darkened(0.35), 0.15 + 0.6 * g)
			L.draw_rect(rc, Color(base.r, base.g, base.b, 0.55))
			# 田裡的格線（方格麥田）
			var gx := rc.position.x + 16.0
			while gx < rc.end.x - 4.0:
				L.draw_line(Vector2(gx, rc.position.y + 3), Vector2(gx, rc.end.y - 3), Color(1, 0.9, 0.6, 0.06 + 0.08 * g), 1.0)
				gx += 16.0
			L.draw_rect(rc, Color(1, 0.9, 0.6, 0.12 + 0.2 * g), false, 1.0)
			x += w
			k += 1


func _draw_region_fill(L: CanvasItem, i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var st: Dictionary = SITES[i]
	var c: Color = Center.level_info(st.id).color
	var x := float(st.x)
	L.draw_colored_polygon(band(x - HALF, x + HALF, CW / 2.0), Color(c.r, c.g, c.b, 0.30 * gl).darkened(0.1))
	L.draw_colored_polygon(band(x - HALF, x + HALF, CW / 2.0 - 8.0), Color(c.r, c.g, c.b, 0.22 * gl))


func _draw_region_ring(i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var st: Dictionary = SITES[i]
	var c: Color = Center.level_info(st.id).color
	var pulse := 0.85 + 0.15 * sin(t * 2.0 + i)
	var x := float(st.x)
	for y in [ROAD_Y - CW / 2.0, ROAD_Y + CW / 2.0]:
		var ln := PackedVector2Array([Vector2(x - HALF, y), Vector2(x + HALF, y)])
		_tgt.draw_polyline(ln, Color(c.r, c.g, c.b, 0.25 * gl * pulse), 7.0)
		_tgt.draw_polyline(ln, Color(c.r, c.g, c.b, 0.9 * gl).lightened(0.3), 2.0, true)


## 區域之間的虛線邊界（兩邊都點亮時變成金色）
func _draw_borders(L: CanvasItem) -> void:
	for i in SITES.size() - 1:
		var x := float(SITES[i].x) + HALF
		var both: bool = glow[i] > 0.6 and glow[i + 1] > 0.6
		L.draw_dashed_line(Vector2(x, ROAD_Y - CW / 2.0), Vector2(x, ROAD_Y + CW / 2.0),
			Color(1, 0.88, 0.55, 0.65) if both else Color(1, 1, 1, 0.28), 2.0, 7.0)


func _make_details() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 47
	var field := PackedVector2Array(FIELD)
	for k in 110:
		var p := Vector2(rng.randf_range(40, 1110), rng.randf_range(110, 610))
		if not Geometry2D.is_point_in_polygon(p, field):
			continue
		if absf(p.y - ROAD_Y) < CW / 2.0 + 22.0 or p.distance_to(TOWER_P) < HILL_R + 10.0:
			continue
		var near := false
		for j in SITES.size():
			if p.distance_to(site_point(j) + Vector2(0, -24)) < 48.0 or p.distance_to(label_point(j)) < 46.0:
				near = true
		if not near:
			out.append({"p": p, "si": near_site(p), "k": k})
	return out


## 旅程路線：沿著數線柵欄往右走
func _route(i: int) -> PackedVector2Array:
	return PackedVector2Array([site_point(i), site_point(i + 1)])


## 麥浪：風吹過麥田，一道一道淡淡的亮光往右移動
func _fx_under() -> void:
	for k in 3:
		var x := fposmod(t * 70.0 + k * 400.0, 1250.0) - 80.0
		for row in [[150.0, 300.0], [445.0, 590.0]]:
			var pts := PackedVector2Array()
			for j in 9:
				var y := lerpf(row[0], row[1], j / 8.0)
				pts.append(Vector2(x + 18.0 * sin(y * 0.03 + t), y))
			_tgt.draw_polyline(pts, Color(1, 0.92, 0.6, 0.05), 14.0, true)


## 八座聖地的地標（畫在柵欄上方）
func _draw_landmark(i: int) -> void:
	var col: Color = Center.level_info(SITES[i].id).color
	var gl: float = glow[i]
	var p := site_point(i) + Vector2(0, -CW / 2.0 - 4.0)
	var Tg := _tgt
	var base := Color("4a4466").lerp(col.darkened(0.15), clampf(0.15 + 0.75 * gl, 0.0, 1.0))
	var dark := Color("262340").lerp(col.darkened(0.55), gl)
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
		0:   # 風車小數：風車，扇葉轉動（點亮後轉得快）
			var hub := p + Vector2(0, -40)
			Tg.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, 0), p + Vector2(9, 0), hub + Vector2(4, 0), hub + Vector2(-4, 0)]), dark.lightened(0.15))
			var ang := t * (2.4 if gl > 0.5 else 0.5)
			for k in 4:
				var a := ang + k * PI / 2.0
				var d := Vector2(cos(a), sin(a))
				var nrm := Vector2(-d.y, d.x)
				Tg.draw_colored_polygon(PackedVector2Array([hub + nrm * 2.0, hub + d * 24.0 + nrm * 6.0, hub + d * 24.0 - nrm * 1.0, hub - nrm * 2.0]), lit_c)
			UITheme.dot(Tg, hub, 3.5, base.lightened(0.4))
		1:   # 繩上珠子：兩根柱子之間一條繩，一顆珠子
			var a := p + Vector2(-20, -10)
			var b := p + Vector2(20, -10)
			Tg.draw_line(p + Vector2(-20, 0), a + Vector2(0, -16), base.lightened(0.2), 3.0)
			Tg.draw_line(p + Vector2(20, 0), b + Vector2(0, -16), base.lightened(0.2), 3.0)
			Tg.draw_line(a + Vector2(0, -12), b + Vector2(0, -12), base.lightened(0.35), 1.5)
			var u := 0.6 + (0.15 * sin(t * 1.5) if gl > 0.5 else 0.0)
			UITheme.dot(Tg, a.lerp(b, u) + Vector2(0, -12), 4.5, lit_c)
		2:   # 天秤市集：一把天秤
			var top := p + Vector2(0, -38)
			var tilt := 0.18 * sin(t * 1.2) if gl > 0.5 else 0.12
			var dl := Vector2(cos(tilt), sin(tilt)) * 20.0
			Tg.draw_line(p, top, base.lightened(0.2), 3.0)
			Tg.draw_line(top - dl, top + dl, base.lightened(0.3), 2.5)
			for e in [top - dl, top + dl]:
				Tg.draw_line(e, e + Vector2(0, 10), base.lightened(0.3), 1.0)
				Tg.draw_line(e + Vector2(-7, 10), e + Vector2(7, 10), lit_c, 3.0)
		3:   # 圍籬牧場：正方形的圍籬，裡面的草
			var rc := Rect2(p + Vector2(-18, -36), Vector2(36, 32))
			Tg.draw_rect(rc, dark.lightened(0.05))
			Tg.draw_rect(rc.grow(-4), Color(col.r, col.g, col.b, 0.15 + 0.45 * gl))
			Tg.draw_rect(rc, lit_c, false, 2.0)
		4:   # 篩種倉庫：一個篩子，兩個籃子
			Tg.draw_line(p + Vector2(-20, -30), p + Vector2(20, -30), base.lightened(0.3), 3.0)
			for k in 5:
				UITheme.dot(Tg, p + Vector2(-14 + k * 7, -26 + fposmod(t * 20.0 + k * 5, 16.0) * (1.0 if gl > 0.5 else 0.2)), 1.8, lit_c)
			for e in [-12.0, 12.0]:
				Tg.draw_colored_polygon(PackedVector2Array([p + Vector2(e - 9, -10), p + Vector2(e + 9, -10), p + Vector2(e + 6, 0), p + Vector2(e - 6, 0)]), base.lightened(0.1))
		5:   # 剝殼磨坊：石磨（一大一小兩個圓），殼一片片掉下來
			UITheme.dot(Tg, p + Vector2(0, -18), 16.0, dark.lightened(0.15))
			Tg.draw_arc(p + Vector2(0, -18), 16.0, 0, TAU, 32, base.lightened(0.3), 2.0, true)
			var ang := t * (1.6 if gl > 0.5 else 0.3)
			Tg.draw_line(p + Vector2(0, -18), p + Vector2(0, -18) + Vector2(cos(ang), sin(ang)) * 13.0, lit_c, 3.0)
			UITheme.dot(Tg, p + Vector2(0, -18), 4.0, lit_c)
		6:   # 方田拼圖：田字形（大正方形切成四塊）
			var rc := Rect2(p + Vector2(-18, -38), Vector2(36, 36))
			Tg.draw_rect(Rect2(rc.position, Vector2(22, 22)), Color(col.r, col.g, col.b, 0.2 + 0.5 * gl))
			Tg.draw_rect(Rect2(rc.position + Vector2(22, 22), Vector2(14, 14)), Color(col.r, col.g, col.b, 0.12 + 0.35 * gl))
			Tg.draw_rect(rc, base.lightened(0.25), false, 1.5)
			Tg.draw_line(rc.position + Vector2(22, 0), rc.position + Vector2(22, 36), lit_c, 1.5)
			Tg.draw_line(rc.position + Vector2(0, 22), rc.position + Vector2(36, 22), lit_c, 1.5)
		7:   # 谷底水渠：有平底的 V 形水渠，水在谷底流
			var pts := PackedVector2Array([p + Vector2(-22, -36), p + Vector2(-8, -8), p + Vector2(8, -8), p + Vector2(22, -36)])
			Tg.draw_polyline(pts, base.lightened(0.3), 3.0, true)
			Tg.draw_line(p + Vector2(-7, -10), p + Vector2(7, -10), lit_c, 3.0)
			if gl > 0.05:
				UITheme.dot(Tg, p + Vector2(-6 + fposmod(t * 8.0, 12.0), -11), 2.0, Color(1, 1, 1, 0.7 * gl))


func _draw_names(font: Font) -> void:
	UITheme.text_ol(_tgt, font, Vector2(52, 132), "數之原野", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(30), Color(1.0, 0.86, 0.5, 0.88), 6)
