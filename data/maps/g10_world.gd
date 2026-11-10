extends "res://data/maps/world_base.gd"
## 高一世界地圖「曦光大陸」：可以自由走動的 2D 地圖（比螢幕大很多，鏡頭拉高、跟著光靈）。
##   ・方向鍵／WASD 移動；手機或滑鼠：在畫面左半邊按住，出現虛擬搖桿
##   ・走到地區入口（大門）會跳出卡片，Enter／點按鈕進入
##   ・不想跑圖：左上「單元列表」直接選單元進入
##   ・地圖裡藏了小解謎（彩蛋），獎勵星塵
## 左岸「秋晨之地」是高一上四區（晨光、楓紅、麥田），晨昏之橋過去是右岸「星夜之地」高一下五區（星空、螢火蟲、極光）。
## 每個地區的地形都藏著那個單元的數學（不寫算式）：
##   數之原野＝方格麥田與數線柵欄　倍增峽谷＝每往下一層、落差加倍的岩層　圓規湖＝正圓的湖、切線棧道、大圓規
##   根之洞窟＝大樹的根伸進山丘　階梯瀑布＝一階一階加寬的瀑布　星點觀測台＝散布的地燈和一條光帶
##   排列花園＝三色花的各種排法　骰子市集＝帳篷與巨大骰子　三角燈塔＝岬角上的燈塔和旋轉的光束
## 還沒開放的地區整片蓋在雲裡（走不進去）；開放之後雲散開。
## 開放的地區一開始是暗的、灰灰冷冷的（世界之光還沒點亮），聖地越點越亮；全部點亮才恢復原本的色彩和地區裡的動態。
## 畫法：不常變的東西（陸地、地形、樹、建築）分成一塊一塊的畫布，只畫一次，看不到的那塊直接隱藏；
##   會動的東西（浪花、水流、風車、光束、雲、螢火蟲、光靈）每幀畫在 _fx；小地圖、主線橫幅、搖桿畫在 _hud。
## 存檔放在 Game.world10：{stones: [], visited: [], eggs: [], pos: [x, y], v2: true}

const MapLayer := preload("res://data/maps/map_layer.gd")
const MathLabel := preload("res://data/ui/math_text.gd")
const Center := preload("res://data/core/review_center.gd")

const WORLD := Vector2(7200, 4400)
const BASE_ZOOM := 0.62           # 平常的鏡頭（拉高視角，一次看到比較大的範圍）
const WIDE_ZOOM := 0.16           # 劇情的全景
const SPEED := 560.0
const R_PLAYER := 24.0
const SPIRIT_R := 30.0
const MID_X := 3830.0             # 河的中線：西邊是秋晨、東邊是星夜

## 左岸（秋晨之地・高一上）的海岸線
const LEFT := [Vector2(280, 4080), Vector2(160, 3280), Vector2(300, 2300), Vector2(220, 1440), Vector2(480, 640),
	Vector2(1120, 300), Vector2(2160, 220), Vector2(3000, 340), Vector2(3520, 760), Vector2(3640, 1640),
	Vector2(3520, 2440), Vector2(3600, 3240), Vector2(3440, 3960), Vector2(2600, 4220), Vector2(1400, 4280)]
## 右岸（星夜之地・高一下）
const RIGHT := [Vector2(4040, 600), Vector2(4640, 300), Vector2(5800, 240), Vector2(6800, 600), Vector2(7040, 1800),
	Vector2(6900, 3000), Vector2(7000, 4000), Vector2(6000, 4240), Vector2(4600, 4200), Vector2(4080, 3600),
	Vector2(4020, 2400), Vector2(4120, 1400)]
const RIVER := [Vector2(3820, -160), Vector2(3760, 800), Vector2(3900, 1800), Vector2(3780, 2800), Vector2(3860, 3800), Vector2(3800, 4600)]
const BRIDGE := Rect2(3480, 2960, 760, 150)
const RIGHT_SPAWN := Vector2(4420, 3040)   # 從「星夜之地」進來時站在橋的東岸

const SPAWN := Vector2(1000, 3900)
const HOUSE := Vector2(720, 3780)

## 九個地區：center 地區中心（雲也蓋在這裡）、gate 入口（站在這裡進入）
const ZONES := [
	{"id": "num", "unit": "h1num", "name": "數之原野", "chapter": "數與式", "center": Vector2(1080, 2940), "gate": Vector2(1700, 3480),
	 "cloud": [Vector2(1080, 2700), 760.0, 520.0], "color": Color("f5c84c")},
	{"id": "exp", "unit": "h1exp", "name": "倍增峽谷", "chapter": "指數與常用對數", "center": Vector2(1120, 1240), "gate": Vector2(1200, 1990),
	 "cloud": [Vector2(1120, 1180), 760.0, 500.0], "color": Color("ff9a5a")},
	{"id": "line", "unit": "h1line", "name": "圓規湖", "chapter": "直線與圓", "center": Vector2(2500, 940), "gate": Vector2(2500, 1760),
	 "cloud": [Vector2(2650, 900), 760.0, 580.0], "color": Color("5fd4ff")},
	{"id": "poly", "unit": "h1poly", "name": "根之洞窟", "chapter": "多項式", "center": Vector2(2760, 2600), "gate": Vector2(2760, 3040),
	 "cloud": [Vector2(2760, 2300), 520.0, 500.0], "color": Color("c59bff")},
	# ---- 星夜之地（高一下）----
	{"id": "seq", "unit": "h1seq", "name": "階梯瀑布", "chapter": "數列與級數", "center": Vector2(4950, 3460), "gate": Vector2(5600, 3600),
	 "cloud": [Vector2(4950, 3460), 520.0, 620.0], "color": Color("6ee7c0")},
	{"id": "data", "unit": "h1data", "name": "星點觀測台", "chapter": "數據分析", "center": Vector2(4900, 1920), "gate": Vector2(4900, 2600),
	 "cloud": [Vector2(4950, 1880), 760.0, 420.0], "color": Color("9fd8ff")},
	{"id": "comb", "unit": "h1comb", "name": "排列花園", "chapter": "排列組合", "center": Vector2(5120, 840), "gate": Vector2(5900, 900),
	 "cloud": [Vector2(5120, 860), 640.0, 440.0], "color": Color("ff9ad5")},
	{"id": "prob", "unit": "h1prob", "name": "骰子市集", "chapter": "機率", "center": Vector2(6300, 1520), "gate": Vector2(6300, 2200),
	 "cloud": [Vector2(6300, 1450), 560.0, 460.0], "color": Color("ffb35a")},
	{"id": "trig", "unit": "h1trig", "name": "三角燈塔", "chapter": "三角比", "center": Vector2(6660, 3000), "gate": Vector2(6080, 3560),
	 "cloud": [Vector2(6660, 2980), 520.0, 680.0], "color": Color("f5e27a")},
]
const LEFT_ZONES := 4                 # ZONES 前 4 個在左岸

## 地標的位置（畫圖和碰撞共用）
const WINDMILL := Vector2(620, 2700)
const CANYON_C := Vector2(1120, 1220)
const LAKE_C := Vector2(2500, 940)
const LAKE_R := 400.0
const HILL_C := Vector2(2760, 2560)
const FALLS_X := 4950.0               # 階梯瀑布的中線
const FALL_T := [3000.0, 3300.0, 3480.0, 3640.0, 3790.0]     # 每一道水幕的頂端
const FALL_B := [3270.0, 3440.0, 3610.0, 3760.0, 3890.0]     # 每一道水幕的底端
const FALL_W := [80.0, 116.0, 152.0, 188.0, 224.0]           # 水幕越來越寬
const FALL_RW := [110.0, 160.0, 210.0, 255.0, 290.0]         # 岩壁的半寬
const FALL_POOL := Vector2(4950, 3960)
const DOME_C := Vector2(4900, 1880)
const GARDEN := Rect2(4660, 560, 920, 560)
const FOUNTAIN := Vector2(5120, 840)
const MARKET_C := Vector2(6300, 1500)
const TENTS := [Vector2(6020, 1330), Vector2(6300, 1230), Vector2(6590, 1340), Vector2(6080, 1690), Vector2(6540, 1700)]
const LIGHTHOUSE := Vector2(6660, 3150)
const EXIT_SIGN := Vector2(6760, 3900)
const PIER := Rect2(6820, 3960, 360, 70)

## 彩蛋一：小屋東邊草地上的數字石，由小到大踩過去
const EGG_STONES := [
	{"t": "π", "v": 3.14159, "p": Vector2(1980, 3700)},
	{"t": "√{2}", "v": 1.41421, "p": Vector2(2260, 3540)},
	{"t": "√{10}", "v": 3.16228, "p": Vector2(2540, 3700)},
	{"t": "3/2", "v": 1.5, "p": Vector2(2260, 3880)},
]
const CHEST := Vector2(2260, 3710)
## 彩蛋二：西北角的石碑（費氏數列），石碑前面鋪著黃金螺線的石板
const STELE := Vector2(1750, 560)
const STELE_U := 30.0                 # 石碑前黃金螺線石板的單位長
const STELE_O := Vector2(1300, 556)   # 1×1 石板的左上角
## 彩蛋三：橋東邊的骰子攤車
const DICE_NPC := Vector2(4560, 2860)

var _fade: ColorRect
var face := Vector2(1, 0)
var walking := false
var _face_left := false
var _trees: Array = []
var _deco: Array = []             # 石頭、草叢、花、南瓜……
var _trail: Array = []
var _leaves: Array = []           # 秋晨之地飄落的葉子（螢幕座標）
var _flies: Array = []            # 星夜之地的螢火蟲（地圖座標）
var _egg_seq: Array = []          # 這一輪已經踩對的數字石（編號）
var _egg_cool := 0.0
var _egg_bad_t := -10.0           # 踩錯順序的時間（數字石閃紅色再重置）
var _card: PanelContainer
var _card_title: Label
var _card_sub: Label
var _card_btn: Button
var _tp_btn: Button
var _save_t := 0.0
var _wall_t := -10.0              # 撞到雲牆的提示（不要一直跳）
var _left_poly := PackedVector2Array()
var _right_poly := PackedVector2Array()
var _left_in := PackedVector2Array()     # 草地（沙灘往內縮）
var _right_in := PackedVector2Array()
var _river := PackedVector2Array()
var _roads: Array = []          # 每一條小路（圓滑過的點）
var _coast_l: Array = []          # 浪花用：海岸線上的取樣點 [點, 往外的方向]
var _coast_r: Array = []
var _open := {}                   # 哪些地區開放了（雲散開）
var _blk_c: Array = []            # 圓形障礙 [中心, 半徑]
var _blk_e: Array = []            # 橢圓障礙 [中心, rx, ry]
var _blk_r: Array = []            # 方形障礙 Rect2
var _root: Node2D                 # 地圖座標的根（位置、縮放 = 鏡頭）
var _pieces: Array = []           # 一塊一塊的靜態畫布 {node, rect}
var _fx: MapLayer
var _hud: MapLayer
var _zoom_lock := false           # 進出地區的鏡頭動畫：不要被自動縮放蓋掉
var _seen_open := ""              # 上次畫的時候哪些地區開放（變了就重畫雲和大門）
var _gloom: MapLayer              # 還沒點亮的地區上面的暗影（點亮的做法在 world_base.gd）

static var _soft_tex: Texture2D


func _init() -> void:
	pos = SPAWN
	zoom = BASE_ZOOM


func _world_key() -> String:
	return "g10"


func _grade_name() -> String:
	return "高一"


# ================= 準備 =================

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_left_poly = _smooth(LEFT, 10)
	_right_poly = _smooth(RIGHT, 10)
	_left_in = _off(_left_poly, -44.0)
	_right_in = _off(_right_poly, -44.0)
	_river = _smooth_open(RIVER, 12)
	_roads = []
	for ln in _road_lines():
		_roads.append(_smooth_open(ln, 6))
	_coast_l = _coast_samples(_left_poly)
	_coast_r = _coast_samples(_right_poly)
	_refresh_open()
	_build_blockers()
	_scatter()
	for i in 34:
		_leaves.append({"p": Vector2(randf() * W, randf() * H), "v": Vector2(randf_range(-24, -8), randf_range(26, 48)),
			"r": randf() * TAU, "w": randf_range(1.5, 3.0), "c": [Color("e0763f"), Color("e3b23c"), Color("c8553d"), Color("f2a65a")][i % 4]})
	for i in 70:
		_flies.append({"base": Vector2(randf_range(4150, 7000), randf_range(400, 4150)), "ph": randf() * TAU, "s": randf_range(0.6, 1.4)})
	_build_layers()
	_build_ui()
	# 舊存檔（地圖放大之前）的位置換成新的座標
	var stt := _state()
	var sp = stt.get("pos", [])
	if sp is Array and sp.size() == 2:
		var p0 := Vector2(float(sp[0]), float(sp[1]))
		if not bool(stt.get("v2", false)):
			p0 *= 2.0
		if _free(p0):
			pos = p0
	stt["v2"] = true
	# 從單元地圖回來：站在那個地區的入口，播離開動畫（畫面由暗轉亮、鏡頭拉遠）
	var ret := String(stt.get("ret", ""))
	if ret != "":
		stt["ret"] = ""
		for z in ZONES:
			if z.unit == ret:
				pos = z.gate + Vector2(0, 90)
		zoom = BASE_ZOOM * 2.6
		_fade.color.a = 1.0
		_zoom_lock = true
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "zoom", BASE_ZOOM, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_fade, "color:a", 0.0, 0.6)
		tw.chain().tween_callback(func(): _zoom_lock = false)
	cam = _cam_target()
	_place_root()
	_refresh_goal()
	_story_check.call_deferred()


## 哪些地區開放了（單元正式開放或開發者預覽）
var debug_open := false           # 截圖用：雲全部散開

func _refresh_open() -> void:
	_open = {}
	for z in ZONES:
		if debug_open:
			_open[z.id] = true
			continue
		var u: Dictionary = Units.unit(z.unit)
		if u.id == z.unit and Units.is_open(u):
			_open[z.id] = true


## 雲蓋住的範圍（橢圓，入口和名牌留在雲的外面）：k = 1 是雲的邊
static func cloud_k(z: Dictionary, p: Vector2) -> float:
	var cl: Array = z.cloud
	var d: Vector2 = p - cl[0]
	return sqrt((d.x * d.x) / (cl[1] * cl[1]) + (d.y * d.y) / (cl[2] * cl[2]))


## 小路：小屋 → 高一上四區 → 橋 → 高一下五區 → 渡口（只是引導，不擋路；都繞過雲）
func _road_lines() -> Array:
	return [
		[SPAWN, ZONES[0].gate, Vector2(1900, 2860), Vector2(1700, 2150), ZONES[1].gate, Vector2(1800, 1820), ZONES[2].gate,
			Vector2(2300, 2200), Vector2(2300, 2900), ZONES[3].gate, Vector2(3300, 3040), Vector2(3470, 3035)],
		[Vector2(4250, 3035), RIGHT_SPAWN, Vector2(4800, 2760), ZONES[5].gate],
		[Vector2(4800, 2760), Vector2(5300, 2760), Vector2(5700, 3100), ZONES[4].gate, ZONES[8].gate, EXIT_SIGN],
		[ZONES[5].gate, Vector2(5500, 2300), ZONES[7].gate],
		[Vector2(5500, 2300), Vector2(5800, 1950), Vector2(5700, 1300), ZONES[6].gate],
	]


static func _smooth(pts: Array, seg: int) -> PackedVector2Array:
	# Catmull-Rom（封閉）：海岸線圓滑一點
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var p0: Vector2 = pts[(i - 1 + n) % n]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n]
		for k in seg:
			out.append(_cr(p0, p1, p2, p3, k / float(seg)))
	return out


static func _smooth_open(pts: Array, seg: int) -> PackedVector2Array:
	# Catmull-Rom（不封閉）：河、小路
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n - 1:
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, n - 1)]
		for k in seg:
			out.append(_cr(p0, p1, p2, p3, k / float(seg)))
	out.append(pts[n - 1])
	return out


static func _cr(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, s: float) -> Vector2:
	var s2 := s * s
	var s3 := s2 * s
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * s + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * s2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * s3)


## 多邊形往外（d > 0）或往內（d < 0）推；取最大的那一塊
static func _off(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var res := Geometry2D.offset_polygon(poly, d, Geometry2D.JOIN_ROUND)
	var best := PackedVector2Array()
	for p in res:
		if p.size() > best.size():
			best = p
	return best


## outer 減掉 inner 的那一圈（inner 在 outer 裡面）。直接相減會得到「有洞的多邊形」畫不出來，
## 所以先從中間切成左右兩半，各自相減就是兩個沒有洞的 C 字形
static func _ring(outer: PackedVector2Array, inner: PackedVector2Array) -> Array:
	var bb := Rect2(outer[0], Vector2.ZERO)
	for q in outer:
		bb = bb.expand(q)
	bb = bb.grow(10.0)
	var cx := bb.get_center().x
	var out := []
	for half in [Rect2(bb.position, Vector2(cx - bb.position.x, bb.size.y)), Rect2(Vector2(cx, bb.position.y), Vector2(bb.end.x - cx, bb.size.y))]:
		var hp := PackedVector2Array([half.position, Vector2(half.end.x, half.position.y), half.end, Vector2(half.position.x, half.end.y)])
		for piece in Geometry2D.intersect_polygons(outer, hp):
			for r in Geometry2D.clip_polygons(piece, inner):
				if Geometry2D.is_polygon_clockwise(r) != Geometry2D.is_polygon_clockwise(piece):
					return [outer]           # 萬一還是有洞：退回畫整塊（只是多畫一層）
				out.append(r)
	return out


static func _shift(poly: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in poly:
		out.append(q + d)
	return out


static func _ell(c: Vector2, rx: float, ry: float, n: int = 48, a0: float = 0.0, a1: float = TAU) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		var a := lerpf(a0, a1, k / float(n - 1 if a1 - a0 < TAU - 0.001 else n))
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out


static func _box(c: Vector2, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-w / 2, -h / 2), c + Vector2(w / 2, -h / 2), c + Vector2(w / 2, h / 2), c + Vector2(-w / 2, h / 2)])


## 海岸上每隔一段的點和往海那邊的方向（浪花用）
static func _coast_samples(poly: PackedVector2Array) -> Array:
	var out := []
	var acc := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		acc += a.distance_to(b)
		if acc < 46.0:
			continue
		acc = 0.0
		var d := (b - a).normalized()
		var n := Vector2(d.y, -d.x)
		# 往外：試一下哪一邊在陸地外面
		if Geometry2D.is_point_in_polygon(a + n * 20.0, poly):
			n = -n
		out.append([a, n])
	return out


## 柔和的圓形貼圖（雲、霧、光暈）：同一張貼圖的東西會合成一次繪圖
static func soft() -> Texture2D:
	if _soft_tex != null:
		return _soft_tex
	var n := 96
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - n / 2.0, y + 0.5 - n / 2.0).length() / (n / 2.0)
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a * (3.0 - 2.0 * a)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_soft_tex = ImageTexture.create_from_image(img)
	return _soft_tex


static func blob(ci, c: Vector2, r: Vector2, col: Color) -> void:
	if ci is CanvasItem:
		ci.draw_texture_rect(soft(), Rect2(c - r, r * 2.0), false, col)
	else:
		ci.soft(c, r, col)


## 有外框的字（UITheme.text_ol 的版本，但畫布可以是 CanvasBatch）
static func _text_ol(ci, font: Font, p: Vector2, text: String, align: int, w: float, size: int, col: Color, ow: int = 4) -> void:
	var oc := UITheme.OUTLINE_DARK
	ci.draw_string_outline(font, p, text, align, w, size, ow, Color(oc.r, oc.g, oc.b, oc.a * col.a))
	ci.draw_string(font, p, text, align, w, size, col)


## 圓點（UITheme.dot_n 的版本，但畫布可以是 CanvasBatch）
static func _dot(ci, c: Vector2, r: float, col: Color, n: int) -> void:
	if r <= 0.0 or col.a <= 0.0:
		return
	if ci is CanvasItem:
		ci.draw_texture_rect(UITheme._disc(n), Rect2(c.x - r, c.y - r, 2.0 * r, 2.0 * r), false, col)
	else:
		ci.disc(c, r, col, n)


# ================= 樹、小東西 =================

## 這一點附近有沒有地區、入口、小屋、彩蛋、地標（種樹時避開）
func _near_feature(p: Vector2, d: float) -> bool:
	for z in ZONES:
		if p.distance_to(z.gate) < d + 90.0 or cloud_k(z, p) < 1.08:
			return true
	for e in EGG_STONES:
		if p.distance_to(e.p) < d + 40.0:
			return true
	for q in [HOUSE, SPAWN, STELE, RIGHT_SPAWN, DICE_NPC, EXIT_SIGN, WINDMILL, LIGHTHOUSE]:
		if p.distance_to(q) < d + 220.0:
			return true
	if BRIDGE.grow(220.0).has_point(p) or p.distance_to(CHEST) < 300.0:
		return true
	if absf(p.x - MID_X) < 420.0:
		return true
	# 地標本身（山丘和大樹、瀑布山體、石板）上面不長樹
	if Rect2(STELE_O + Vector2(-3, -5) * STELE_U, Vector2(13, 8) * STELE_U).grow(60.0).has_point(p):
		return true
	if Rect2(HILL_C.x - 480, HILL_C.y - 720, 960, 1100).has_point(p) or Rect2(FALLS_X - 480, 2880, 960, 1220).has_point(p):
		return true
	return _road_dist(p) < 90.0 + d * 0.3


func _road_dist(p: Vector2) -> float:
	var best := INF
	for rd in _roads:
		var r: PackedVector2Array = rd
		for i in r.size() - 1:
			best = minf(best, Geometry2D.get_closest_point_to_segment(p, r[i], r[i + 1]).distance_to(p))
	return best


func _scatter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1010
	var tries := 0
	while _trees.size() < 460 and tries < 20000:
		tries += 1
		var p := Vector2(rng.randf_range(260, 6960), rng.randf_range(300, 4160))
		var east := p.x > MID_X
		if not Geometry2D.is_point_in_polygon(p, _right_in if east else _left_in):
			continue
		if _near_feature(p, 70.0):
			continue
		var bad := false
		for tr in _trees:
			if p.distance_to(tr.p) < 58.0:
				bad = true
				break
		if bad:
			continue
		var kind := ""
		var k := rng.randf()
		if east:
			kind = "nightpine" if k < 0.35 else ("glow" if k < 0.7 else "willow")
		else:
			kind = "maple" if k < 0.34 else ("ginkgo" if k < 0.55 else ("pine" if k < 0.8 else "oak"))
		_trees.append({"p": p, "r": rng.randf_range(34, 52), "k": kind, "v": rng.randf()})
	_trees.sort_custom(func(a, b): return a.p.y < b.p.y)
	# 小東西：石頭、草叢、花、南瓜、發光的花
	tries = 0
	while _deco.size() < 900 and tries < 20000:
		tries += 1
		var p := Vector2(rng.randf_range(260, 6960), rng.randf_range(300, 4160))
		var east := p.x > MID_X
		if not Geometry2D.is_point_in_polygon(p, _right_in if east else _left_in) or absf(p.x - MID_X) < 380.0:
			continue
		if _near_feature(p, 0.0) and rng.randf() < 0.85:
			continue
		var k := rng.randf()
		var kind := ""
		if east:
			kind = "rock" if k < 0.2 else ("bloom" if k < 0.62 else "tuft")
		else:
			kind = "rock" if k < 0.18 else ("flower" if k < 0.5 else ("tuft" if k < 0.9 else "pumpkin"))
		_deco.append({"p": p, "k": kind, "s": rng.randf_range(0.7, 1.35), "v": rng.randf(), "east": east})


# ================= 碰撞 =================

func _build_blockers() -> void:
	_blk_c = [[HOUSE, 110.0], [WINDMILL, 70.0], [STELE + Vector2(0, -6), 84.0], [DOME_C, 230.0], [FOUNTAIN, 90.0],
		[LIGHTHOUSE, 110.0], [LIGHTHOUSE + Vector2(-190, 110), 105.0], [DICE_NPC, 60.0], [LAKE_C, LAKE_R + 14.0],
		[MARKET_C, 70.0], [FALL_POOL, 270.0]]
	for tp in TENTS:
		_blk_c.append([tp, 86.0])
	_blk_e = [[CANYON_C, 560.0, 330.0], [HILL_C, 380.0, 290.0], [Vector2(FALLS_X, 3440), 430.0, 500.0], [Vector2(3080, 1045), 150.0, 50.0]]
	_blk_r = []
	# 排列花園的樹籬（中間留出走道）
	for hg in _hedges():
		_blk_r.append(hg)


## 排列花園的樹籬（外圈四邊留出入口，裡面四塊花圃）
func _hedges() -> Array:
	var g := GARDEN
	var t := 34.0
	var gap := 150.0
	var cx := g.position.x + g.size.x / 2.0
	var cy := g.position.y + g.size.y / 2.0
	return [
		Rect2(g.position.x, g.position.y, g.size.x / 2.0 - gap / 2.0, t), Rect2(cx + gap / 2.0, g.position.y, g.size.x / 2.0 - gap / 2.0, t),
		Rect2(g.position.x, g.end.y - t, g.size.x / 2.0 - gap / 2.0, t), Rect2(cx + gap / 2.0, g.end.y - t, g.size.x / 2.0 - gap / 2.0, t),
		Rect2(g.position.x, g.position.y, t, g.size.y / 2.0 - gap / 2.0), Rect2(g.position.x, cy + gap / 2.0, t, g.size.y / 2.0 - gap / 2.0),
		Rect2(g.end.x - t, g.position.y, t, g.size.y / 2.0 - gap / 2.0), Rect2(g.end.x - t, cy + gap / 2.0, t, g.size.y / 2.0 - gap / 2.0),
	]


## 這一點在陸地或橋上嗎
func _ground(q: Vector2) -> bool:
	return BRIDGE.has_point(q) or Geometry2D.is_point_in_polygon(q, _left_poly) or Geometry2D.is_point_in_polygon(q, _right_poly)


## 這個位置能不能站：在陸地或橋上，而且沒有撞到雲、湖、峽谷、建築、樹
func _free(p: Vector2) -> bool:
	if not _ground(p):
		return false
	for dv in [Vector2(R_PLAYER, 0), Vector2(-R_PLAYER, 0), Vector2(0, R_PLAYER), Vector2(0, -R_PLAYER)]:
		if not _ground(p + dv):
			return false
	if _in_cloud(p) >= 0:
		return false
	for b in _blk_c:
		if p.distance_to(b[0]) < float(b[1]) + R_PLAYER:
			return false
	for b in _blk_e:
		var d: Vector2 = p - b[0]
		var rx: float = float(b[1]) + R_PLAYER
		var ry: float = float(b[2]) + R_PLAYER
		if (d.x * d.x) / (rx * rx) + (d.y * d.y) / (ry * ry) < 1.0:
			return false
	for b in _blk_r:
		if (b as Rect2).grow(R_PLAYER).has_point(p):
			return false
	for tr in _trees:
		if absf(p.x - tr.p.x) < 60.0 and absf(p.y - tr.p.y) < 60.0 and p.distance_to(tr.p) < float(tr.r) * 0.45 + R_PLAYER:
			return false
	return true


## 在哪一個還沒開放地區的雲裡（−1：不在）
func _in_cloud(p: Vector2) -> int:
	for i in ZONES.size():
		var z: Dictionary = ZONES[i]
		if not _open.has(z.id) and cloud_k(z, p) < 0.96:
			return i
	return -1


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
	_apply_light()
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
	_card.visible = k != "" and not is_instance_valid(_overlay) and not _busy and not frozen()
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
			_card_sub.text = z.chapter if _open.has(z.id) else "%s　·　雲霧籠罩，準備中" % z.chapter
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
		_zoom_lock = true
		tw.tween_property(self, "zoom", BASE_ZOOM * 2.9, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(_fade, "color:a", 1.0, 0.5).set_delay(0.08)
		await tw.finished
		pick_unit.emit(z.unit)
		return
	var o := UITheme.modal(self, z.color, 460)
	_overlay = o[0]
	var col: VBoxContainer = o[1]
	col.add_child(UITheme.title_label(z.name, 28, z.color))
	var l := Label.new()
	l.text = "「%s」的題目還在準備中。" % z.chapter
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
		pos = z.gate + Vector2(0, 90)
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
	if frozen():
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


# ================= 鏡頭、移動 =================

## 畫面看到的地圖範圍
func _view() -> Rect2:
	var C := Vector2(W, H) / 2.0
	var half := C / zoom
	return Rect2(cam + C - half, half * 2.0)


func _cam_target() -> Vector2:
	var C := Vector2(W, H) / 2.0
	var focus := story_focus if story_focus.x >= 0.0 else pos
	var half := C / zoom
	var c := focus
	c.x = WORLD.x / 2.0 if half.x * 2.0 >= WORLD.x else clampf(c.x, half.x, WORLD.x - half.x)
	c.y = WORLD.y / 2.0 if half.y * 2.0 >= WORLD.y else clampf(c.y, half.y, WORLD.y - half.y)
	return c - C


## 把地圖座標的畫布放到鏡頭的位置，並隱藏看不到的那幾塊
func _place_root() -> void:
	var C := Vector2(W, H) / 2.0
	_root.position = C - (cam + C) * zoom
	_root.scale = Vector2(zoom, zoom)
	var v := _view().grow(60.0)
	for pc in _pieces:
		var z: String = pc.zone
		(pc.node as CanvasItem).visible = (pc.rect as Rect2).intersects(v) and (z == "" or _open.has(z))


func _process(delta: float) -> void:
	t += delta
	_fade.visible = _fade.color.a > 0.004          # 完全透明時不畫（全螢幕的一層）
	var active := is_visible_in_tree() and not is_instance_valid(_overlay) and not _busy and not frozen()
	_goal_t -= delta
	if _goal_t <= 0.0:
		_goal_t = 1.0
		_refresh_goal()
		_refresh_open()
		_apply_light()
		var key := ",".join(_open.keys())
		if key != _seen_open:
			_seen_open = key
			for pc in _pieces:
				if bool(pc.get("dyn", false)):
					pc.node.invalidate()
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
		elif _in_cloud(np) >= 0 and t - _wall_t > 2.5:
			_wall_t = t
			var z: Dictionary = ZONES[_in_cloud(np)]
			_show_toast("雲霧太濃了，「%s」還在準備中" % z.name)
		if randf() < 0.5:
			_trail.append({"p": pos + Vector2(randf_range(-8, 8), randf_range(6, 16)), "v": Vector2(randf_range(-14, 14), randf_range(-44, -16)), "life": 0.0})
		_save_t += delta
		if _save_t > 4.0:
			_save_t = 0.0
			_state()["pos"] = [roundi(pos.x), roundi(pos.y)]
	for p in _trail:
		p.life += delta
		p.p += p.v * delta
	_trail = _trail.filter(func(p): return p.life < 0.8)
	# 劇情的全景拉遠；平常回到一般的高度
	if not _zoom_lock:
		var want := WIDE_ZOOM if story_focus.x >= 0.0 and story_focus.distance_to(focus_point("wide", "")) < 1.0 else BASE_ZOOM
		zoom = lerpf(zoom, want, 1.0 - exp(-3.0 * delta))
	cam = cam.lerp(_cam_target(), 1.0 - exp(-8.0 * delta))
	_check_world(delta)
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)
	_update_card()
	# 葉子（螢幕座標，只在秋晨之地）
	for lf in _leaves:
		lf.p += lf.v * delta + Vector2(sin(t * lf.w + lf.r) * 18.0 * delta, 0)
		lf.r += delta * lf.w
		if lf.p.y > H + 20.0:
			lf.p = Vector2(randf_range(0, W + 200.0), -20.0)
		if lf.p.x < -20.0:
			lf.p.x = W + 20.0
	_place_root()
	_fx.queue_redraw()
	_light_tick(delta)
	_gloom.queue_redraw()
	for fl in _lit_fx.values():
		fl.queue_redraw()
	_hud.queue_redraw()
	queue_redraw()


## 走到哪裡：去過的地區、彩蛋、入口
func _check_world(delta: float) -> void:
	for z in ZONES:
		if not _has("visited", z.id) and (pos.distance_to(z.gate) < 320.0 or (_open.has(z.id) and pos.distance_to(z.center) < 700.0)):
			_add("visited", z.id)
			_show_toast("發現新地區：%s" % z.name)
	# 彩蛋一：數字石
	_egg_cool = maxf(0.0, _egg_cool - delta)
	if not _has("eggs", "stones") and _egg_cool <= 0.0:
		for i in EGG_STONES.size():
			if pos.distance_to(EGG_STONES[i].p) < 52.0 and not _egg_seq.has(i):
				var want := _next_egg()
				if i == want:
					_egg_seq.append(i)
					Game.of(self).sfx("click")
					if _egg_seq.size() == EGG_STONES.size():
						_show_toast("四顆數字石都亮了！草地中間出現了寶箱")
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
		if pos.distance_to(ZONES[i].gate) < 110.0:
			_near = {"kind": "zone", "i": i}
	if pos.distance_to(STELE) < 140.0:
		_near = {"kind": "stele"}
	if pos.distance_to(DICE_NPC) < 140.0:
		_near = {"kind": "dice"}
	if pos.distance_to(EXIT_SIGN) < 160.0:
		_near = {"kind": "ferry"}
	if pos.distance_to(HOUSE) < 190.0:
		_near = {"kind": "house"}
	if _egg_seq.size() == EGG_STONES.size() and not _has("eggs", "stones") and pos.distance_to(CHEST) < 100.0:
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


# ================= 畫布 =================

## 一塊靜態畫布：rect 是它的範圍（不在畫面裡就隱藏），dyn = 開放狀態改變時要重畫
## zone：這塊是哪個地區的地標 → 那個地區還沒開放時整塊在不透明的雲底下，乾脆不畫
func _piece(rect: Rect2, painter: Callable, dyn := false, zone := "") -> void:
	var n := MapLayer.new()
	n.painter = painter
	n.batched = true
	if zone != "":
		n.material = _zone_mat(zone)
	_root.add_child(n)
	_pieces.append({"node": n, "rect": rect, "dyn": dyn, "zone": zone})


func _zone_mat(id: String) -> ShaderMaterial:
	return _light_mat(id)


func _zone_of(id: String) -> Dictionary:
	for z in ZONES:
		if String(z.id) == id:
			return z
	return {}


# ---------- 點亮（共用的做法在 world_base.gd；這裡告訴它有哪些地區） ----------

func _light_keys() -> Array:
	var out := []
	for z in ZONES:
		out.append(String(z.id))
	return out


## 單元的完成度（0～1）
func _light_target(key: String) -> float:
	var z := _zone_of(key)
	var u: Dictionary = Units.unit(z.unit)
	if u.id != z.unit or u.levels.is_empty():
		return 0.0
	var g = Game.of(self)
	var p := 0.0
	for l in u.levels:
		p += float(Center.level_progress(g, l.id))
	return p / u.levels.size()


func _light_box(key: String) -> Rect2:
	var cl: Array = _zone_of(key).cloud
	var r := Vector2(cl[1], cl[2])
	return Rect2((cl[0] as Vector2) - r, r * 2.0)


func _light_name(key: String) -> String:
	return String(_zone_of(key).get("name", ""))


func _build_layers() -> void:
	_root = Node2D.new()
	add_child(_root)
	var base := MapLayer.new()
	base.painter = _p_base
	base.batched = true
	_root.add_child(base)
	_piece(Rect2(0, 0, WORLD.x, WORLD.y), _p_roads)
	# 地區的地標
	_piece(Rect2(160, 2280, 1720, 1080), _p_num, false, "num")
	_piece(Rect2(420, 700, 1400, 1280), _p_canyon, false, "exp")
	_piece(Rect2(1900, 380, 1300, 1320), _p_lake, false, "line")
	_piece(Rect2(2200, 1740, 1150, 1420), _p_hill, false, "poly")
	_piece(Rect2(320, 3400, 900, 700), _p_house)
	_piece(Rect2(900, 160, 1260, 700), _p_stele)
	_piece(Rect2(1800, 3380, 900, 700), _p_meadow)
	_piece(Rect2(3380, 2700, 960, 560), _p_bridge)
	_piece(Rect2(4180, 2770, 1540, 1430), _p_falls, false, "seq")
	_piece(Rect2(4300, 1360, 1200, 1120), _p_dome, false, "data")
	_piece(Rect2(4560, 420, 1120, 820), _p_garden, false, "comb")
	_piece(Rect2(5760, 980, 1160, 1060), _p_market, false, "prob")
	_piece(Rect2(6100, 2300, 1100, 1440), _p_lighthouse, false, "trig")
	_piece(Rect2(6380, 3640, 820, 560), _p_dock)
	_piece(Rect2(4320, 2640, 520, 420), _p_cart)
	# 樹和小東西：切成 900×900 的格子
	var cells := {}
	for tr in _trees:
		var key := Vector2i(int(tr.p.x / 900.0), int(tr.p.y / 900.0))
		if not cells.has(key):
			cells[key] = {"trees": [], "deco": []}
		cells[key].trees.append(tr)
	for d in _deco:
		var key := Vector2i(int(d.p.x / 900.0), int(d.p.y / 900.0))
		if not cells.has(key):
			cells[key] = {"trees": [], "deco": []}
		cells[key].deco.append(d)
	for key in cells:
		var cell: Dictionary = cells[key]
		var rect := Rect2(Vector2(key) * 900.0 - Vector2(120, 200), Vector2(1140, 1240))
		_piece(rect, func(L): _p_cell(L, cell))
	# 還沒點亮的地區：上面壓一層暗暗的影子（地面、樹也跟著暗；大門和名牌在上面，照樣看得清楚）
	var gloom := MapLayer.new()
	gloom.painter = _p_gloom
	_root.add_child(gloom)
	_gloom = gloom
	# 大門、名牌（開放狀態改變時重畫）
	_piece(Rect2(0, 0, WORLD.x, WORLD.y), _p_gates, true)
	# 每個地區自己的動態（風車、熱氣球、瀑布、光束……）：分開成一層一層，才能照點亮程度調淡
	for z in ZONES:
		var id: String = z.id
		var fl := MapLayer.new()
		fl.painter = func(L): _p_zone_fx(L, id, _view().grow(120.0))
		fl.material = _zone_mat(id)
		_root.add_child(fl)
		_lit_fx[id] = fl
	_apply_light()
	_fx = MapLayer.new()
	_fx.painter = _p_fx
	_root.add_child(_fx)
	_hud = MapLayer.new()
	_hud.painter = _p_hud
	add_child(_hud)
	_seen_open = ",".join(_open.keys())


# ================= 海（每幀畫，螢幕座標） =================

func _draw() -> void:
	# 海的顏色：西邊是晨光下的藍綠色，東邊是夜晚的深藍
	var v := _view()
	var xs := [0.0, W]
	var cols := []
	for sx in xs:
		var wx: float = v.position.x + sx / W * v.size.x
		cols.append(_sea_col(wx))
	var mid_sx := (MID_X - v.position.x) / v.size.x * W
	if mid_sx > 0.0 and mid_sx < W:
		var cm := _sea_col(MID_X)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(mid_sx, 0), Vector2(mid_sx, H), Vector2(0, H)]),
			PackedColorArray([cols[0], cm, cm.darkened(0.15), (cols[0] as Color).darkened(0.15)]))
		draw_polygon(PackedVector2Array([Vector2(mid_sx, 0), Vector2(W, 0), Vector2(W, H), Vector2(mid_sx, H)]),
			PackedColorArray([cm, cols[1], (cols[1] as Color).darkened(0.15), cm.darkened(0.15)]))
	else:
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]),
			PackedColorArray([cols[0], cols[1], (cols[1] as Color).darkened(0.15), (cols[0] as Color).darkened(0.15)]))


static func _sea_col(wx: float) -> Color:
	var k := clampf((wx - (MID_X - 1600.0)) / 3200.0, 0.0, 1.0)
	return Color("1d4466").lerp(Color("081430"), k)


# ================= 陸地（只畫一次） =================

const L_GRASS := Color("6f7d43")
const L_CLIFF := Color("5b3a31")
const L_SAND := Color("e2c08a")
const R_GRASS := Color("1d3a4e")
const R_CLIFF := Color("111e33")
const R_SAND := Color("8fa4bd")


func _p_base(L) -> void:
	for side in [0, 1]:
		var poly: PackedVector2Array = _left_poly if side == 0 else _right_poly
		var inner: PackedVector2Array = _left_in if side == 0 else _right_in
		var east: bool = side == 1
		# 淺灘：一圈一圈越往外越淡（只畫環，不疊整塊陸地；第 k 圈的顏色＝原本疊 5−k 層的效果）
		var sa := 0.035 if east else 0.05
		var sc := Color(0.55, 0.85, 1.0) if east else Color(0.6, 0.9, 0.95)
		for k in [4, 3, 2, 1]:
			var a := 1.0 - pow(1.0 - sa, 5 - k)
			for pc in _ring(_off(poly, 70.0 * k), poly if k == 1 else _off(poly, 70.0 * (k - 1))):
				L.draw_colored_polygon(pc, Color(sc.r, sc.g, sc.b, a))
		# 南邊的崖壁（陸地往下錯開，看起來像一塊浮起來的台地）：只畫露出來的那一條
		for pc in Geometry2D.clip_polygons(_shift(poly, Vector2(0, 64)), poly):
			L.draw_colored_polygon(pc, (R_CLIFF if east else L_CLIFF).darkened(0.25))
		for pc in Geometry2D.clip_polygons(_shift(poly, Vector2(0, 44)), poly):
			L.draw_colored_polygon(pc, R_CLIFF if east else L_CLIFF)
		var str1 := _shift(poly, Vector2(0, 26))
		str1.append(str1[0])
		L.draw_polyline(str1, (R_CLIFF if east else L_CLIFF).lightened(0.12), 5.0, true)
		# 沙灘（只畫草地外面那一圈）、草地
		var beach_hi := _off(poly, -14.0)
		for pc in _ring(poly, beach_hi):
			L.draw_colored_polygon(pc, R_SAND if east else L_SAND)
		for pc in _ring(beach_hi, inner):
			L.draw_colored_polygon(pc, (R_SAND if east else L_SAND).lightened(0.08))
		L.draw_colored_polygon(inner, R_GRASS if east else L_GRASS)
		var rim := inner.duplicate()
		rim.append(rim[0])
		L.draw_polyline(rim, (R_GRASS if east else L_GRASS).darkened(0.18), 6.0, true)
	# 草地的深淺（大片柔和的色塊）
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 340:
		var p := Vector2(rng.randf_range(200, 7000), rng.randf_range(260, 4200))
		var east := p.x > MID_X
		if not Geometry2D.is_point_in_polygon(p, _right_in if east else _left_in):
			continue
		var r := Vector2(rng.randf_range(160, 360), rng.randf_range(110, 240))
		var c: Color
		if east:
			c = [Color("26506a"), Color("1a3346"), Color("2b4f72"), Color("173044")][i % 4]
		else:
			c = [Color("8a8a48"), Color("5c7040"), Color("9a8346"), Color("7a8a4c"), Color("a2764a")][i % 5]
		blob(L, p, r, Color(c.r, c.g, c.b, 0.55))
	# 晨光：西北邊亮一點、暖一點；星夜：月光照亮的地方
	for q in [Vector2(900, 900), Vector2(1800, 1500), Vector2(700, 2600), Vector2(2400, 3300), Vector2(3100, 1200)]:
		blob(L, q, Vector2(900, 700), Color(1.0, 0.82, 0.5, 0.10))
	for q in [Vector2(5000, 1000), Vector2(6200, 2400), Vector2(5000, 3200)]:
		blob(L, q, Vector2(900, 700), Color(0.6, 0.75, 1.0, 0.07))
	# 河：河岸、水、亮一點的中間
	L.draw_polyline(_river, Color("6f5a46"), 340.0, true)
	L.draw_polyline(_river, Color("a7895e"), 300.0, true)
	L.draw_polyline(_river, Color("1d5a8a"), 240.0, true)
	L.draw_polyline(_river, Color("2a73a8"), 170.0, true)
	L.draw_polyline(_river, Color(0.55, 0.8, 1.0, 0.25), 60.0, true)
	# 河邊的石頭
	for i in 40:
		var k := rng.randf()
		var idx := int(k * (_river.size() - 2))
		var a := _river[idx]
		var b := _river[idx + 1]
		var n := (b - a).normalized().orthogonal()
		var p := a + n * (rng.randf_range(120, 150) * (1.0 if rng.randf() < 0.5 else -1.0))
		var rr := rng.randf_range(10, 22)
		L.draw_colored_polygon(_ell(p + Vector2(0, 4), rr, rr * 0.6, 12), Color(0, 0, 0, 0.2))
		L.draw_colored_polygon(_ell(p, rr, rr * 0.7, 12), Color("8a8478"))
		L.draw_colored_polygon(_ell(p + Vector2(-rr * 0.25, -rr * 0.2), rr * 0.5, rr * 0.35, 10), Color("aaa496"))


## 小路：西邊是泥土路、東邊是月光下的石板路
func _p_roads(L) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for rd in _roads:
		var ln: PackedVector2Array = rd
		var east := ln[0].x > MID_X
		var edge := Color("2c3a58") if east else Color("6e5235")
		var top := Color("50668c") if east else Color("bb9662")
		var mid := Color("5f77a0") if east else Color("c9a673")
		L.draw_polyline(_shift(ln, Vector2(0, 8)), Color(0, 0, 0, 0.18), 92.0, true)
		L.draw_polyline(ln, edge, 88.0, true)
		L.draw_polyline(ln, top, 72.0, true)
		L.draw_polyline(ln, mid, 34.0, true)
	# 路上的小石子、東邊的石板縫
	for rd in _roads:
		var ln: PackedVector2Array = rd
		var east := ln[0].x > MID_X
		var cracks := PackedVector2Array()
		for i in ln.size() - 1:
			var a := ln[i]
			var b := ln[i + 1]
			var dd := (b - a).normalized()
			var n := dd.orthogonal()
			for k in 3:
				var p := a.lerp(b, rng.randf()) + n * rng.randf_range(-28, 28)
				if east:
					cracks.append_array([p - n * 12.0, p + n * 12.0])
				else:
					L.draw_colored_polygon(_ell(p, 4.5, 3.0, 8), Color("8a6a46"))
		if not cracks.is_empty():
			L.draw_multiline(cracks, Color("3a4a6e"), 2.5)


static func _fillp(L, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() >= 3:
		L.draw_colored_polygon(pts, col)


## 一格的樹和小東西（同一種東西一起畫：影子 → 樹幹 → 樹冠 → 亮面）
func _p_cell(L, cell: Dictionary) -> void:
	var trees: Array = cell.trees
	var deco: Array = cell.deco
	# 小東西
	for d in deco:
		var p: Vector2 = d.p
		var s: float = d.s
		match String(d.k):
			"rock":
				blob(L, p + Vector2(0, 6 * s), Vector2(22, 9) * s, Color(0, 0, 0, 0.25))
				L.draw_colored_polygon(PackedVector2Array([p + Vector2(-20, 4) * s, p + Vector2(-12, -12) * s, p + Vector2(6, -16) * s,
					p + Vector2(20, -2) * s, p + Vector2(14, 6) * s]), Color("6c6a78") if d.east else Color("8a7d6a"))
				L.draw_colored_polygon(PackedVector2Array([p + Vector2(-12, -12) * s, p + Vector2(6, -16) * s, p + Vector2(2, -6) * s,
					p + Vector2(-10, -4) * s]), Color("8c8aa0") if d.east else Color("a8997e"))
			"pumpkin":
				blob(L, p + Vector2(0, 8 * s), Vector2(18, 7) * s, Color(0, 0, 0, 0.25))
				for k in 3:
					L.draw_colored_polygon(_ell(p + Vector2((k - 1) * 7.0 * s, 0), 9.0 * s, 10.0 * s, 14), Color("e07a2e").darkened(0.08 * absf(k - 1)))
				L.draw_rect(Rect2(p + Vector2(-2, -14) * s, Vector2(4, 6) * s), Color("5f6a2e"))
	var lines := PackedVector2Array()
	var lines_c := PackedVector2Array()
	for d in deco:
		var p: Vector2 = d.p
		var s: float = d.s
		if d.k == "tuft":
			for k in 3:
				var bx := (k - 1) * 6.0 * s
				lines.append_array([p + Vector2(bx, 0), p + Vector2(bx * 1.6 + (k - 1) * 3.0, -14.0 * s)])
	if not lines.is_empty():
		L.draw_multiline(lines, Color("9aa060") if (deco.size() > 0 and not deco[0].east) else Color("3f7088"), 2.5)
	for d in deco:
		var p: Vector2 = d.p
		var s: float = d.s
		if d.k == "flower":
			var fc: Color = [Color("ffd36e"), Color("ff9a7a"), Color("fff2c9"), Color("e9a0ff")][int(d.v * 4.0) % 4]
			for k in 5:
				_dot(L, p + Vector2.from_angle(TAU * k / 5.0) * 5.0 * s, 4.0 * s, fc, 32)
			_dot(L, p, 3.0 * s, Color("8a5a2e"), 32)
		elif d.k == "bloom":
			# 星夜的發光花
			var bc: Color = [Color("8ff0ff"), Color("c6a6ff"), Color("7affd2")][int(d.v * 3.0) % 3]
			blob(L, p, Vector2(26, 26) * s, Color(bc.r, bc.g, bc.b, 0.22))
			_dot(L, p, 4.0 * s, bc, 32)
	# 樹
	for tr in trees:
		var p: Vector2 = tr.p
		var r: float = tr.r
		blob(L, p + Vector2(r * 0.15, r * 0.2), Vector2(r * 1.05, r * 0.42), Color(0, 0, 0, 0.30))
	for tr in trees:
		var p: Vector2 = tr.p
		var r: float = tr.r
		if tr.k in ["pine", "nightpine"]:
			L.draw_rect(Rect2(p + Vector2(-5, -r * 0.2), Vector2(10, r * 0.4)), Color("4a3326"))
		else:
			L.draw_colored_polygon(PackedVector2Array([p + Vector2(-7, 0), p + Vector2(7, 0), p + Vector2(4, -r * 0.9), p + Vector2(-4, -r * 0.9)]),
				Color("5a3d2c") if tr.k != "willow" else Color("2c3046"))
	for tr in trees:
		var p: Vector2 = tr.p
		var r: float = tr.r
		var v: float = tr.v
		match String(tr.k):
			"pine", "nightpine":
				var dark := Color("2f5a45") if tr.k == "pine" else Color("173a4a")
				var lite := Color("4f8a5e") if tr.k == "pine" else Color("2a6478")
				for k in 3:
					var y0 := -r * 0.2 - k * r * 0.55
					var w := r * (1.0 - k * 0.22)
					L.draw_colored_polygon(PackedVector2Array([p + Vector2(-w, y0), p + Vector2(w, y0), p + Vector2(0, y0 - r * 1.0)]), dark)
					L.draw_colored_polygon(PackedVector2Array([p + Vector2(-w, y0), p + Vector2(-w * 0.05, y0), p + Vector2(0, y0 - r * 1.0)]), lite)
				if tr.k == "nightpine":
					_dot(L, p + Vector2(0, -r * 2.2), 3.0, Color("bff4ff"), 32)
			_:
				var cols := _canopy(String(tr.k), v)
				var c0: Vector2 = p + Vector2(0, -r * 1.1)
				_dot(L, c0 + Vector2(-r * 0.45, r * 0.15), r * 0.7, cols[0], 128)
				_dot(L, c0 + Vector2(r * 0.45, r * 0.18), r * 0.68, cols[0], 128)
				_dot(L, c0, r * 0.82, cols[1], 128)
				_dot(L, c0 + Vector2(-r * 0.25, -r * 0.3), r * 0.48, cols[2], 128)
				_dot(L, c0 + Vector2(-r * 0.32, -r * 0.42), r * 0.18, cols[3], 128)
	# 發光的樹：樹冠上的小光點
	for tr in trees:
		if tr.k == "glow":
			var p: Vector2 = tr.p + Vector2(0, -tr.r * 1.1)
			for k in 5:
				_dot(L, p + Vector2.from_angle(TAU * k / 5.0 + tr.v * 6.0) * tr.r * 0.55, 3.0, Color("c8fbff"), 32)


## 樹冠的顏色：[暗面, 主色, 亮面, 最亮的點]
static func _canopy(kind: String, v: float) -> Array:
	match kind:
		"maple":
			return [Color("9a3b2c"), Color("c8553d") if v < 0.5 else Color("d2643a"), Color("e8834a"), Color("f6b27a")]
		"ginkgo":
			return [Color("a6782a"), Color("dba83a"), Color("efc659"), Color("fde59a")]
		"oak":
			return [Color("4a5a30"), Color("6f7d3c"), Color("8f9a4c"), Color("c0c27a")]
		"glow":
			return [Color("1c3e55"), Color("24597a"), Color("3a7ea6"), Color("8fd8ff")]
		"willow":
			return [Color("2a2c5c"), Color("3b3f7a"), Color("5257a0"), Color("b8a6ff")]
	return [Color("444"), Color("666"), Color("888"), Color("aaa")]


# ================= 秋晨之地的地標 =================

## 數之原野：方格麥田、數線柵欄、大風車、稻草人
func _p_num(L) -> void:
	var o := Vector2(760, 2600)
	var pw := 176.0
	var ph := 120.0
	blob(L, Vector2(1220, 2900), Vector2(720, 420), Color(0.95, 0.8, 0.4, 0.16))
	for r in 4:
		for c in 5:
			var p := o + Vector2(c * (pw + 14.0), r * (ph + 14.0))
			var gold := Color("d9ae4a") if (r + c) % 2 == 0 else Color("c69a3e")
			if (r * 5 + c) % 7 == 3:
				gold = Color("a8a650")          # 一塊還沒熟的麥田
			L.draw_rect(Rect2(p + Vector2(0, 6), Vector2(pw, ph)), Color(0.35, 0.25, 0.12, 0.45))
			L.draw_rect(Rect2(p, Vector2(pw, ph)), gold)
			L.draw_rect(Rect2(p, Vector2(pw, 16)), gold.lightened(0.18))
	# 麥穗（一排一排的短線）
	var st := PackedVector2Array()
	for r in 4:
		for c in 5:
			var p := o + Vector2(c * (pw + 14.0), r * (ph + 14.0))
			for row in 5:
				for k in 9:
					var q := p + Vector2(10 + k * 19.0 + (row % 2) * 9.0, 22 + row * 21.0)
					st.append_array([q, q + Vector2(-2, -12)])
	L.draw_multiline(st, Color("f2d27a"), 2.0)
	# 數線柵欄：等距的木樁，每五根一根高的
	var fy := 3170.0
	L.draw_line(Vector2(730, fy - 26), Vector2(1730, fy - 26), Color("6e4a2c"), 6.0, true)
	L.draw_line(Vector2(730, fy - 8), Vector2(1730, fy - 8), Color("6e4a2c"), 6.0, true)
	for k in 21:
		var x := 740.0 + k * 49.0
		var tall := k % 5 == 0
		var hh := 64.0 if tall else 40.0
		L.draw_rect(Rect2(Vector2(x - 5, fy - hh), Vector2(10, hh)), Color("8a5f36"))
		L.draw_rect(Rect2(Vector2(x - 5, fy - hh), Vector2(4, hh)), Color("a8784a"))
		if tall:
			L.draw_colored_polygon(PackedVector2Array([Vector2(x - 8, fy - hh), Vector2(x + 8, fy - hh), Vector2(x, fy - hh - 12)]), Color("a8784a"))
	# 圓圓的乾草捆
	for q in [Vector2(820, 3260), Vector2(900, 3300), Vector2(1700, 2560), Vector2(1760, 2620)]:
		blob(L, q + Vector2(6, 22), Vector2(46, 14), Color(0, 0, 0, 0.3))
		L.draw_colored_polygon(_ell(q, 40, 30, 24), Color("c99a46"))
		L.draw_colored_polygon(_ell(q + Vector2(-8, -6), 26, 18, 20), Color("e0b45a"))
		L.draw_arc(q + Vector2(-8, -6), 14, 0, TAU, 20, Color("a87a36"), 2.0, true)
	# 稻草人
	var sc := Vector2(1250, 2830)
	L.draw_rect(Rect2(sc + Vector2(-4, -90), Vector2(8, 96)), Color("6e4a2c"))
	L.draw_rect(Rect2(sc + Vector2(-46, -70), Vector2(92, 8)), Color("6e4a2c"))
	L.draw_colored_polygon(PackedVector2Array([sc + Vector2(-30, -72), sc + Vector2(30, -72), sc + Vector2(24, -24), sc + Vector2(-24, -24)]), Color("b4503c"))
	L.draw_colored_polygon(_ell(sc + Vector2(0, -98), 18, 18, 18), Color("e8cf8a"))
	L.draw_colored_polygon(PackedVector2Array([sc + Vector2(-30, -108), sc + Vector2(30, -108), sc + Vector2(0, -140)]), Color("8a6a3a"))
	# 大風車（葉片在 _fx 轉）
	var w := WINDMILL
	blob(L, w + Vector2(40, 16), Vector2(150, 40), Color(0, 0, 0, 0.32))
	var body := PackedVector2Array([w + Vector2(-70, 0), w + Vector2(70, 0), w + Vector2(44, -300), w + Vector2(-44, -300)])
	L.draw_colored_polygon(body, Color("d8c8a8"))
	L.draw_colored_polygon(PackedVector2Array([w + Vector2(20, 0), w + Vector2(70, 0), w + Vector2(44, -300), w + Vector2(12, -300)]), Color("b8a888"))
	for k in 5:
		var yy := -40.0 - k * 56.0
		var hw := 70.0 - (70.0 - 44.0) * (-yy / 300.0)
		L.draw_line(w + Vector2(-hw, yy), w + Vector2(hw, yy), Color("a89878"), 2.0, true)
	L.draw_colored_polygon(_ell(w + Vector2(0, -24), 22, 30, 16, PI, TAU), Color("5a3d2c"))
	L.draw_rect(Rect2(w + Vector2(-22, -24), Vector2(44, 24)), Color("5a3d2c"))
	for q in [Vector2(0, -150), Vector2(0, -230)]:
		L.draw_rect(Rect2(w + q + Vector2(-12, -16), Vector2(24, 32)), Color("4a5a7a"))
		L.draw_rect(Rect2(w + q + Vector2(-12, -16), Vector2(24, 32)), Color("8a6a46"), false, 3.0)
	L.draw_colored_polygon(PackedVector2Array([w + Vector2(-58, -296), w + Vector2(58, -296), w + Vector2(0, -380)]), Color("a8503c"))
	L.draw_colored_polygon(PackedVector2Array([w + Vector2(0, -296), w + Vector2(58, -296), w + Vector2(0, -380)]), Color("8a3f30"))


## 倍增峽谷：一層一層往下的岩層，每往下一層的落差加倍；谷底一條映著晨光的河
func _p_canyon(L) -> void:
	var c := CANYON_C
	blob(L, c + Vector2(0, 40), Vector2(720, 450), Color(0.25, 0.12, 0.08, 0.35))
	var drops := [0.0, 14.0, 42.0, 98.0, 210.0]          # 每一層的落差：14、28、56、112（加倍）
	var tops := [Color("d39a62"), Color("c0804e"), Color("a8663f"), Color("8c5035"), Color("6e3c2e")]
	var walls := [Color("8a4a34"), Color("7a3e2e"), Color("6a3428"), Color("582a22"), Color("4a221c")]
	L.draw_colored_polygon(_ell(c, 600, 360, 64), Color("b58652"))      # 崖邊
	for k in 4:
		var rx := 560.0 - k * 92.0
		var ry := 330.0 - k * 58.0
		var rx2 := 560.0 - (k + 1) * 92.0
		var ry2 := 330.0 - (k + 1) * 58.0
		L.draw_colored_polygon(_ell(c + Vector2(0, drops[k]), rx, ry, 64), tops[k])
		# 往下一層的岩壁（北邊看得到）
		L.draw_colored_polygon(_ell(c + Vector2(0, drops[k]), rx2, ry2, 64), walls[k])
		# 岩壁上的紋路
		for s in 3:
			var f := (s + 1) / 4.0
			var off: float = lerpf(drops[k], drops[k + 1], f)
			L.draw_polyline(_ell(c + Vector2(0, off), rx2, ry2, 40, PI + 0.25, TAU - 0.25), walls[k].lightened(0.1), 2.0, true)
		L.draw_colored_polygon(_ell(c + Vector2(0, drops[k + 1]), rx2, ry2, 64), tops[k + 1])
	# 谷底的河
	var rv := PackedVector2Array()
	for k in 25:
		var x := lerpf(-170, 170, k / 24.0)
		rv.append(c + Vector2(x, drops[4] + sin(k * 0.6) * 22.0))
	L.draw_polyline(rv, Color("5a2f26"), 26.0, true)
	L.draw_polyline(rv, Color("f0a35a"), 16.0, true)
	L.draw_polyline(rv, Color("ffd79a"), 5.0, true)
	# 崖邊的石頭、吊橋
	for k in 14:
		var a := TAU * k / 14.0 + 0.2
		var p := c + Vector2(cos(a) * 590, sin(a) * 350)
		L.draw_colored_polygon(_ell(p, 26, 16, 10), Color("8a7058"))
		L.draw_colored_polygon(_ell(p + Vector2(-6, -5), 14, 8, 8), Color("b09070"))
	var b0 := c + Vector2(-600, -150)
	var b1 := c + Vector2(600, -150)
	var deck := PackedVector2Array()
	for k in 31:
		var s := k / 30.0
		deck.append(b0.lerp(b1, s) + Vector2(0, sin(s * PI) * 70.0))
	L.draw_polyline(_shift(deck, Vector2(0, 26)), Color(0, 0, 0, 0.25), 18.0, true)
	L.draw_polyline(deck, Color("8a6038"), 16.0, true)
	var planks := PackedVector2Array()
	for k in range(1, 30):
		planks.append_array([deck[k] + Vector2(0, -9), deck[k] + Vector2(0, 9)])
	L.draw_multiline(planks, Color("c08a50"), 4.0)
	L.draw_polyline(_shift(deck, Vector2(0, -26)), Color("d8b07a"), 3.0, true)
	for q in [b0, b1]:
		L.draw_rect(Rect2(q + Vector2(-8, -60), Vector2(16, 66)), Color("6e4a2c"))


## 圓規湖：正圓的湖、切線的棧道、湖邊的大圓規和它畫過的弧
func _p_lake(L) -> void:
	var c := LAKE_C
	var r := LAKE_R
	L.draw_colored_polygon(_ell(c + Vector2(0, 14), r + 56, r + 50, 96), Color(0.2, 0.25, 0.15, 0.4))
	L.draw_colored_polygon(_ell(c, r + 50, r + 50, 96), Color("cfb07a"))
	L.draw_colored_polygon(_ell(c, r + 30, r + 30, 96), Color("e2c690"))
	L.draw_colored_polygon(_ell(c, r, r, 96), Color("17507e"))
	L.draw_colored_polygon(_ell(c, r - 40, r - 40, 96), Color("1f6496"))
	L.draw_colored_polygon(_ell(c, r - 150, r - 150, 96), Color("2774aa"))
	blob(L, c + Vector2(-120, -140), Vector2(220, 130), Color(1.0, 0.85, 0.6, 0.22))      # 映著晨光
	# 睡蓮
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for k in 14:
		var a := rng.randf() * TAU
		var p := c + Vector2.from_angle(a) * rng.randf_range(r * 0.62, r * 0.9)
		var rr := rng.randf_range(16, 26)
		var pad := _ell(p, rr, rr * 0.7, 18, a + 0.5, a + TAU - 0.1)
		pad.append(p)
		L.draw_colored_polygon(pad, Color("4f8a4a"))
		if k % 3 == 0:
			_dot(L, p + Vector2(4, -4), 6.0, Color("ffb0c8"), 32)
	# 蘆葦
	var reeds := PackedVector2Array()
	for k in 60:
		var a := rng.randf() * TAU
		if a > 1.2 and a < 1.95:
			continue           # 南邊棧道那裡不長
		var p := c + Vector2.from_angle(a) * (r + rng.randf_range(4, 30))
		reeds.append_array([p, p + Vector2(rng.randf_range(-6, 6), -rng.randf_range(26, 44))])
	L.draw_multiline(reeds, Color("7a8a3e"), 3.0)
	# 切線棧道：剛好碰到湖的最南邊
	var ty := c.y + r + 8.0
	L.draw_rect(Rect2(Vector2(c.x - 460, ty + 8), Vector2(920, 54)), Color(0, 0, 0, 0.25))
	L.draw_rect(Rect2(Vector2(c.x - 460, ty - 6), Vector2(920, 54)), Color("9a6a3e"))
	var pl := PackedVector2Array()
	var x := c.x - 452.0
	while x < c.x + 460.0:
		pl.append_array([Vector2(x, ty - 6), Vector2(x, ty + 48)])
		x += 26.0
	L.draw_multiline(pl, Color("7a5030"), 3.0)
	L.draw_line(Vector2(c.x - 460, ty - 6), Vector2(c.x + 460, ty - 6), Color("c8955a"), 4.0, true)
	for k in 9:
		L.draw_rect(Rect2(Vector2(c.x - 450 + k * 112.0, ty + 40), Vector2(12, 22)), Color("5a3a22"))
	_dot(L, Vector2(c.x, ty - 4), 9.0, Color("ffe7a3"), 32)      # 切點
	# 大圓規：針腳插在湖東岸，筆腳畫出一段弧
	var pivot := Vector2(3060, 560)
	var needle := Vector2(2960, 1040)
	var pencil := Vector2(3200, 1040)
	var arc := PackedVector2Array()
	for k in 40:
		var a := lerpf(-0.95, 0.95, k / 39.0)
		arc.append(needle + Vector2(cos(a), sin(a) * 0.55) * 240.0)
	L.draw_polyline(arc, Color(1.0, 0.92, 0.7, 0.5), 10.0, true)
	L.draw_polyline(arc, Color("fff2c9"), 3.0, true)
	blob(L, Vector2(3080, 1060), Vector2(200, 50), Color(0, 0, 0, 0.3))
	L.draw_colored_polygon(_ell(Vector2(3080, 1050), 150, 40, 32), Color("8a8478"))
	L.draw_colored_polygon(_ell(Vector2(3080, 1040), 140, 34, 32), Color("b0a998"))
	for leg in [[needle, Color("9aa6b8"), Color("d8e2f0")], [pencil, Color("c89a4a"), Color("f2d08a")]]:
		var tip: Vector2 = leg[0]
		var d := (tip - pivot).normalized()
		var n := d.orthogonal()
		var mid := pivot.lerp(tip, 0.88)
		L.draw_colored_polygon(PackedVector2Array([pivot + n * 16.0, pivot - n * 16.0, mid - n * 10.0, mid + n * 10.0]), leg[1])
		L.draw_colored_polygon(PackedVector2Array([pivot + n * 5.0, pivot - n * 3.0, mid - n * 2.0, mid + n * 4.0]), leg[2])
		L.draw_colored_polygon(PackedVector2Array([mid + n * 10.0, mid - n * 10.0, tip]), Color("5a6070") if leg[0] == needle else Color("3a3a4a"))
	L.draw_colored_polygon(_ell(pivot, 34, 34, 24), Color("c8a64a"))
	L.draw_colored_polygon(_ell(pivot, 20, 20, 20), Color("f2d77a"))
	L.draw_rect(Rect2(pivot + Vector2(-9, -86), Vector2(18, 56)), Color("8a6a3a"))
	L.draw_colored_polygon(_ell(pivot + Vector2(0, -92), 16, 12, 16), Color("c8a64a"))


## 根之洞窟：大樹站在山丘上，樹根垂下來包住洞口；礦車軌道一路接到入口
func _p_hill(L) -> void:
	var c := HILL_C
	blob(L, c + Vector2(30, 190), Vector2(520, 160), Color(0, 0, 0, 0.35))
	# 山丘本體（下面一圈比較暗的岩壁）
	var hill := PackedVector2Array()
	for k in 64:
		var a := TAU * k / 64.0
		var wob := 1.0 + 0.06 * sin(a * 5.0) + 0.04 * sin(a * 9.0 + 1.0)
		hill.append(c + Vector2(cos(a) * 390.0 * wob, sin(a) * 300.0 * wob))
	L.draw_colored_polygon(_shift(hill, Vector2(0, 50)), Color("3e2e4e"))
	L.draw_colored_polygon(hill, Color("5e4a6e"))
	L.draw_colored_polygon(_shift(_off(hill, -60.0), Vector2(-20, -24)), Color("6e5a7e"))
	L.draw_colored_polygon(_shift(_off(hill, -150.0), Vector2(-40, -50)), Color("7e6a8a"))
	# 岩石的紋路、草
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for k in 26:
		var p := c + Vector2(rng.randf_range(-320, 320), rng.randf_range(-230, 220))
		if (p - c).length() > 300.0:
			continue
		L.draw_colored_polygon(_ell(p, rng.randf_range(18, 34), rng.randf_range(10, 18), 10), Color("4e3c5e"))
	# 洞口
	var mouth := c + Vector2(0, 240)
	L.draw_colored_polygon(_ell(mouth + Vector2(0, -4), 130, 150, 40, PI, TAU), Color("2a1e38"))
	L.draw_rect(Rect2(mouth + Vector2(-130, -4), Vector2(260, 40)), Color("2a1e38"))
	L.draw_colored_polygon(_ell(mouth, 104, 126, 40, PI, TAU), Color("140c22"))
	L.draw_rect(Rect2(mouth + Vector2(-104, -1), Vector2(208, 37)), Color("140c22"))
	# 洞口的紫水晶
	for q in [Vector2(-128, 20), Vector2(-112, -60), Vector2(120, 10), Vector2(132, -50), Vector2(-60, -126), Vector2(70, -118), Vector2(-150, 34), Vector2(150, 34)]:
		var p: Vector2 = mouth + q
		var hgt := rng.randf_range(34, 56)
		L.draw_colored_polygon(PackedVector2Array([p + Vector2(-12, 0), p + Vector2(0, -hgt), p + Vector2(12, 0), p + Vector2(0, 10)]), Color("a07ae6"))
		L.draw_colored_polygon(PackedVector2Array([p + Vector2(-12, 0), p + Vector2(0, -hgt), p + Vector2(0, 10)]), Color("d4bcff"))
	# 礦車軌道：洞口 → 入口
	var g: Vector2 = ZONES[3].gate
	var ties := PackedVector2Array()
	var y := mouth.y + 30.0
	while y < g.y - 30.0:
		ties.append_array([Vector2(c.x - 40, y), Vector2(c.x + 40, y)])
		y += 22.0
	L.draw_multiline(ties, Color("6e4a2c"), 8.0)
	L.draw_line(Vector2(c.x - 26, mouth.y + 20), Vector2(c.x - 26, g.y - 30), Color("9a9aa8"), 5.0, true)
	L.draw_line(Vector2(c.x + 26, mouth.y + 20), Vector2(c.x + 26, g.y - 30), Color("9a9aa8"), 5.0, true)
	# 礦車
	var cart := Vector2(c.x, mouth.y + 110)
	L.draw_colored_polygon(PackedVector2Array([cart + Vector2(-46, -36), cart + Vector2(46, -36), cart + Vector2(36, 0), cart + Vector2(-36, 0)]), Color("7a5a3a"))
	L.draw_rect(Rect2(cart + Vector2(-46, -40), Vector2(92, 8)), Color("a07a4e"))
	for q in [Vector2(-22, -44), Vector2(4, -50), Vector2(24, -42)]:
		L.draw_colored_polygon(PackedVector2Array([cart + q + Vector2(-9, 4), cart + q + Vector2(0, -12), cart + q + Vector2(9, 4)]), Color("c6a6ff"))
	for q in [Vector2(-24, 2), Vector2(24, 2)]:
		L.draw_colored_polygon(_ell(cart + q, 11, 11, 14), Color("3a3a46"))
	# 大樹：樹根 → 樹幹 → 很大的樹冠
	var top := c + Vector2(0, -150)
	# 樹根沿著山坡往兩側攀下去，在洞口上方分開，把洞口框起來
	var roots := [[Vector2(-36, 0), Vector2(-200, 40), Vector2(-340, 170), 26.0], [Vector2(-30, 6), Vector2(-150, 120), Vector2(-250, 300), 22.0],
		[Vector2(-14, 10), Vector2(-60, 120), Vector2(-150, 250), 16.0], [Vector2(36, 0), Vector2(210, 30), Vector2(350, 150), 26.0],
		[Vector2(30, 6), Vector2(150, 120), Vector2(260, 290), 22.0], [Vector2(14, 10), Vector2(64, 120), Vector2(152, 246), 16.0],
		[Vector2(-40, -4), Vector2(-230, -40), Vector2(-370, 20), 14.0], [Vector2(40, -4), Vector2(240, -30), Vector2(370, 30), 14.0]]
	for rt in roots:
		var pts := PackedVector2Array()
		var a0: Vector2 = top + rt[0]
		var b0: Vector2 = top + rt[1]
		var e0: Vector2 = top + rt[2]
		for k in 17:
			var s := k / 16.0
			pts.append(a0.lerp(b0, s).lerp(b0.lerp(e0, s), s))
		var wr: float = rt[3] * 1.35
		# 根越往外越細：分三段疊
		L.draw_polyline(_shift(pts, Vector2(5, 8)), Color(0, 0, 0, 0.28), wr * 0.7, true)
		L.draw_polyline(pts, Color("5e3e2a"), wr * 0.55, true)
		L.draw_polyline(pts.slice(0, 11), Color("5e3e2a"), wr * 0.85, true)
		L.draw_polyline(pts.slice(0, 6), Color("5e3e2a"), wr * 1.2, true)
		L.draw_polyline(_shift(pts.slice(0, 13), Vector2(-wr * 0.18, -wr * 0.15)), Color("8a6040"), maxf(3.0, wr * 0.2), true)
		# 細根鬚
		var tip := pts[16]
		var dd := (pts[16] - pts[13]).normalized()
		L.draw_line(tip, tip + dd.rotated(0.6) * 34.0, Color("5e3e2a"), 4.0, true)
		L.draw_line(tip, tip + dd.rotated(-0.5) * 28.0, Color("5e3e2a"), 3.0, true)
	L.draw_colored_polygon(PackedVector2Array([top + Vector2(-46, 10), top + Vector2(46, 10), top + Vector2(30, -230), top + Vector2(-30, -230)]), Color("6a4630"))
	L.draw_colored_polygon(PackedVector2Array([top + Vector2(-46, 10), top + Vector2(-14, 10), top + Vector2(-10, -230), top + Vector2(-30, -230)]), Color("8a6040"))
	for br in [[Vector2(-20, -200), Vector2(-150, -300)], [Vector2(20, -200), Vector2(160, -290)], [Vector2(0, -220), Vector2(20, -360)]]:
		L.draw_line(top + br[0], top + br[1], Color("6a4630"), 18.0, true)
	var cc := top + Vector2(0, -330)
	var leaf := [Color("5a3a8a"), Color("7a52b8"), Color("9a74d8"), Color("c6a6ff"), Color("d77a8a")]
	var puffs := [[Vector2(-210, 40), 120], [Vector2(200, 50), 120], [Vector2(-120, -60), 140], [Vector2(130, -50), 140],
		[Vector2(0, -130), 150], [Vector2(0, 30), 170], [Vector2(-260, -40), 90], [Vector2(270, -20), 90]]
	blob(L, cc + Vector2(0, 260), Vector2(380, 90), Color(0, 0, 0, 0.25))
	for pf in puffs:
		_dot(L, cc + pf[0] + Vector2(0, 16), float(pf[1]), leaf[0], 128)
	for pf in puffs:
		_dot(L, cc + pf[0], float(pf[1]) * 0.92, leaf[1], 128)
	for pf in puffs:
		_dot(L, cc + pf[0] + Vector2(-float(pf[1]) * 0.25, -float(pf[1]) * 0.3), float(pf[1]) * 0.55, leaf[2], 128)
	for k in 40:
		var p := cc + Vector2(rng.randf_range(-300, 300), rng.randf_range(-260, 160))
		_dot(L, p, rng.randf_range(6, 14), leaf[3] if k % 4 != 0 else leaf[4], 32)


## 光靈的小屋：石頭地基、木牆、斜屋頂、煙囪、亮著的窗、圍籬和南瓜田
func _p_house(L) -> void:
	var h := HOUSE
	blob(L, h + Vector2(40, 60), Vector2(260, 70), Color(0, 0, 0, 0.35))
	# 小院子
	L.draw_colored_polygon(_ell(h + Vector2(40, 70), 300, 120, 40), Color("8a9050"))
	# 圍籬
	var fence := PackedVector2Array()
	for k in 33:
		var a := PI * 0.1 + PI * 0.8 * k / 32.0
		fence.append(h + Vector2(40, 70) + Vector2(cos(a) * 300, sin(a) * 120))
	L.draw_polyline(fence, Color("e8d8b8"), 4.0, true)
	for k in range(0, 33, 2):
		if k > 13 and k < 19:
			continue
		var q := fence[k]
		L.draw_rect(Rect2(q + Vector2(-3, -26), Vector2(6, 28)), Color("f2e6cc"))
	# 地基、牆
	L.draw_rect(Rect2(h + Vector2(-130, 30), Vector2(260, 26)), Color("8a8478"))
	for k in 6:
		L.draw_rect(Rect2(h + Vector2(-126 + k * 43, 34), Vector2(38, 18)), Color("a8a296"))
	L.draw_rect(Rect2(h + Vector2(-120, -90), Vector2(240, 122)), Color("c08a58"))
	for k in 6:
		L.draw_line(h + Vector2(-120, -78 + k * 20), h + Vector2(120, -78 + k * 20), Color("a8744a"), 2.0)
	# 門、窗
	L.draw_rect(Rect2(h + Vector2(-26, -40), Vector2(52, 72)), Color("5a3a26"))
	L.draw_colored_polygon(_ell(h + Vector2(0, -40), 26, 18, 16, PI, TAU), Color("5a3a26"))
	_dot(L, h + Vector2(16, -4), 4.0, Color("f2c86a"), 32)
	for q in [Vector2(-80, -48), Vector2(80, -48)]:
		L.draw_rect(Rect2(h + q + Vector2(-26, -22), Vector2(52, 44)), Color("ffd98a"))
		L.draw_rect(Rect2(h + q + Vector2(-26, -22), Vector2(52, 44)), Color("6a4630"), false, 5.0)
		L.draw_line(h + q + Vector2(0, -22), h + q + Vector2(0, 22), Color("6a4630"), 4.0)
		L.draw_line(h + q + Vector2(-26, 0), h + q + Vector2(26, 0), Color("6a4630"), 4.0)
		L.draw_rect(Rect2(h + q + Vector2(-30, 24), Vector2(60, 12)), Color("8a5a3a"))
		for k in 4:
			_dot(L, h + q + Vector2(-20 + k * 13, 22), 6.0, [Color("ff8a6a"), Color("ffd36e")][k % 2], 32)
	# 屋頂（一排一排的瓦）＋煙囪
	var roof := PackedVector2Array([h + Vector2(-152, -84), h + Vector2(152, -84), h + Vector2(80, -210), h + Vector2(-80, -210)])
	L.draw_colored_polygon(roof, Color("b4503c"))
	for k in 5:
		var y := -100.0 - k * 24.0
		var hw := 152.0 - (152.0 - 80.0) * ((-y - 84.0) / 126.0)
		L.draw_line(h + Vector2(-hw, y), h + Vector2(hw, y), Color("8a3a2c"), 3.0, true)
	L.draw_line(h + Vector2(-80, -210), h + Vector2(80, -210), Color("d8704e"), 6.0, true)
	L.draw_rect(Rect2(h + Vector2(70, -250), Vector2(36, 80)), Color("8a7468"))
	L.draw_rect(Rect2(h + Vector2(64, -258), Vector2(48, 12)), Color("6a5a50"))
	# 郵筒、柴堆
	L.draw_rect(Rect2(h + Vector2(200, 30), Vector2(6, 46)), Color("6a4630"))
	L.draw_rect(Rect2(h + Vector2(186, 10), Vector2(34, 24)), Color("d04a3a"))
	for k in 3:
		for j in 3 - k:
			L.draw_colored_polygon(_ell(h + Vector2(-190 + j * 22 + k * 11, 40 - k * 18), 11, 9, 12), Color("8a6040"))


## 西北角的石碑：前面鋪著一塊一塊的正方形石板（邊長 1、1、2、3、5、8），連成黃金螺線
func _p_stele(L) -> void:
	var u := STELE_U
	var o := STELE_O
	# 石板：1、1 → 下 2 → 左 3 → 上 5 → 右 8，一圈一圈往外長
	var sq := [[Vector2(0, 0), 1], [Vector2(1, 0), 1], [Vector2(0, 1), 2], [Vector2(-3, 0), 3], [Vector2(-3, -5), 5], [Vector2(2, -5), 8]]
	blob(L, o + Vector2(3.5, -1) * u, Vector2(14, 9) * u, Color(0.9, 0.8, 0.6, 0.18))
	L.draw_rect(Rect2(o + Vector2(-3, -5) * u, Vector2(13, 8) * u).grow(10.0), Color("8a7e66"))
	for k in sq.size():
		var p: Vector2 = o + (sq[k][0] as Vector2) * u
		var w: float = float(sq[k][1]) * u
		var r := Rect2(p, Vector2(w, w)).grow(-3.0)
		L.draw_rect(Rect2(r.position + Vector2(0, 4), r.size), Color("6e6450"))
		L.draw_rect(r, Color("d2c6a8") if k % 2 == 0 else Color("bcb094"))
		L.draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), Color(1, 1, 1, 0.25))
	# 螺線：每塊石板裡一段四分之一圓，接成一條
	var arcs := [[Vector2(1, 1), 1, PI, 1.5 * PI], [Vector2(1, 1), 1, 1.5 * PI, TAU], [Vector2(0, 1), 2, 0.0, 0.5 * PI],
		[Vector2(0, 0), 3, 0.5 * PI, PI], [Vector2(2, 0), 5, PI, 1.5 * PI], [Vector2(2, 3), 8, 1.5 * PI, TAU]]
	for ar in arcs:
		L.draw_arc(o + (ar[0] as Vector2) * u, float(ar[1]) * u, ar[2], ar[3], 32, Color(0.95, 0.8, 0.4, 0.35), 10.0, true)
		L.draw_arc(o + (ar[0] as Vector2) * u, float(ar[1]) * u, ar[2], ar[3], 32, Color("f2d27a"), 4.0, true)
	# 石碑：兩層台座、方尖碑、頂上刻著螺旋
	var s0 := STELE
	blob(L, s0 + Vector2(16, 20), Vector2(120, 30), Color(0, 0, 0, 0.35))
	L.draw_rect(Rect2(s0 + Vector2(-90, -10), Vector2(180, 34)), Color("4a4460"))
	L.draw_rect(Rect2(s0 + Vector2(-90, -10), Vector2(180, 8)), Color("6e6688"))
	L.draw_rect(Rect2(s0 + Vector2(-66, -36), Vector2(132, 30)), Color("544c6c"))
	L.draw_rect(Rect2(s0 + Vector2(-66, -36), Vector2(132, 7)), Color("7a7296"))
	var ob := PackedVector2Array([s0 + Vector2(-46, -36), s0 + Vector2(46, -36), s0 + Vector2(34, -230), s0 + Vector2(0, -262), s0 + Vector2(-34, -230)])
	L.draw_colored_polygon(ob, Color("5e5678"))
	L.draw_colored_polygon(PackedVector2Array([s0 + Vector2(-46, -36), s0 + Vector2(-14, -36), s0 + Vector2(-10, -230), s0 + Vector2(0, -262), s0 + Vector2(-34, -230)]), Color("736b90"))
	L.draw_colored_polygon(PackedVector2Array([s0 + Vector2(24, -36), s0 + Vector2(46, -36), s0 + Vector2(34, -230), s0 + Vector2(20, -230)]), Color("4a4462"))
	var font := UITheme.bold_font()
	for k in 3:
		var tx: String = ["1 1", "2 3", "5 ?"][k]
		L.draw_string(font, s0 + Vector2(-36, -150 + k * 32), tx, HORIZONTAL_ALIGNMENT_CENTER, 72, 22, Color("dcd2f6"))
	var sp := PackedVector2Array()
	for k in 40:
		var a := k * 0.32
		sp.append(s0 + Vector2(0, -196) + Vector2.from_angle(a) * (2.0 + k * 0.42))
	L.draw_polyline(sp, Color("f2d27a"), 3.0, true)
	# 爬藤
	var ivy := PackedVector2Array([s0 + Vector2(-44, -40), s0 + Vector2(-38, -80), s0 + Vector2(-42, -120), s0 + Vector2(-34, -150)])
	L.draw_polyline(ivy, Color("4a7a3a"), 3.0, true)
	for q in ivy:
		L.draw_colored_polygon(_ell(q + Vector2(5, 0), 9, 6, 10), Color("6a9a4a"))
	for q in [Vector2(-80, -2), Vector2(70, 0), Vector2(-100, 18), Vector2(96, 20)]:
		L.draw_colored_polygon(_ell(s0 + q, 18, 9, 10), Color("6a8a4a"))


## 小屋東邊的草地：一圈小蘑菇圍著四顆數字石（數字石會亮，畫在 _fx）
func _p_meadow(L) -> void:
	blob(L, CHEST, Vector2(420, 260), Color(0.75, 0.85, 0.45, 0.22))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 30:
		var a := TAU * k / 30.0
		var p := CHEST + Vector2(cos(a) * 380, sin(a) * 240) + Vector2(rng.randf_range(-12, 12), rng.randf_range(-10, 10))
		L.draw_rect(Rect2(p + Vector2(-3, -10), Vector2(6, 12)), Color("efe2c8"))
		L.draw_colored_polygon(_ell(p + Vector2(0, -12), 11, 8, 12, PI, TAU), Color("d0503c") if k % 3 else Color("e8a43a"))


## 晨昏之橋：石拱橋，西半邊染著晨光、東半邊映著月光，橋中間有太陽和月亮的圖案
func _p_bridge(L) -> void:
	var b := BRIDGE
	blob(L, Vector2(b.get_center().x, b.end.y + 80), Vector2(460, 70), Color(0, 0, 0, 0.35))
	# 南面的拱和橋墩
	L.draw_rect(Rect2(Vector2(b.position.x + 60, b.end.y - 6), Vector2(b.size.x - 120, 76)), Color("6e6a74"))
	for k in 3:
		var cx := b.position.x + 200.0 + k * 180.0
		L.draw_colored_polygon(_ell(Vector2(cx, b.end.y + 70), 70, 62, 24, PI, TAU), Color("1a4c78"))
	L.draw_line(Vector2(b.position.x + 60, b.end.y + 66), Vector2(b.end.x - 60, b.end.y + 66), Color("4e4a56"), 4.0)
	# 橋面
	var deck := PackedVector2Array([b.position, Vector2(b.end.x, b.position.y), b.end, Vector2(b.position.x, b.end.y)])
	L.draw_polygon(deck, PackedColorArray([Color("d8b888"), Color("8a9ab8"), Color("6e7e9c"), Color("b8986e")]))
	var stones := PackedVector2Array()
	var x := b.position.x + 30.0
	while x < b.end.x:
		stones.append_array([Vector2(x, b.position.y + 18), Vector2(x, b.end.y - 18)])
		x += 46.0
	L.draw_multiline(stones, Color(0, 0, 0, 0.12), 2.0)
	# 欄杆
	for yy in [b.position.y + 6, b.end.y - 4]:
		L.draw_line(Vector2(b.position.x, yy - 26), Vector2(b.end.x, yy - 26), Color("e8dcc8"), 6.0, true)
		var px := b.position.x + 10.0
		while px < b.end.x:
			L.draw_rect(Rect2(Vector2(px - 5, yy - 30), Vector2(10, 32)), Color("f0e6d6"))
			px += 68.0
	# 太陽和月亮
	var mc := b.get_center()
	L.draw_colored_polygon(_ell(mc, 44, 34, 32), Color("3a3a5a"))
	L.draw_colored_polygon(_ell(mc, 40, 30, 32, PI * 0.5, PI * 1.5), Color("f5c84c"))
	L.draw_colored_polygon(_ell(mc, 40, 30, 32, -PI * 0.5, PI * 0.5), Color("c8d8ff"))
	var font := UITheme.bold_font()
	_text_ol(L, font, Vector2(b.position.x + 160, b.position.y - 60), "晨昏之橋", HORIZONTAL_ALIGNMENT_CENTER, 440, 44, Color("ffe7b8"), 8)


# ================= 星夜之地的地標 =================

## 階梯瀑布：高高的崖壁，水一階一階往下流，每往下一階瀑布就寬一點，最後落進月光下的水潭
func _p_falls(L) -> void:
	var x := FALLS_X
	blob(L, Vector2(x, 3480), Vector2(760, 700), Color(0.4, 0.7, 1.0, 0.08))
	blob(L, Vector2(x + 40, 3560), Vector2(560, 560), Color(0, 0, 0, 0.3))
	# 山體：兩座尖峰夾著一道缺口，水從缺口流出來
	var m := PackedVector2Array()
	for q in [[-300, 3900], [-390, 3790], [-440, 3620], [-430, 3440], [-390, 3260], [-330, 3110], [-270, 3000], [-205, 2925],
			[-160, 2955], [-110, 2975], [-60, 2992], [60, 2992], [110, 2972], [165, 2945], [220, 2932], [275, 2990],
			[335, 3110], [395, 3260], [435, 3440], [445, 3620], [395, 3790], [305, 3900]]:
		m.append(Vector2(x + q[0], q[1]))
	var cols := PackedColorArray()
	for q in m:
		cols.append(Color("22385a").lerp(Color("101a2e"), clampf((q.y - 2920.0) / 980.0, 0.0, 1.0)))
	L.draw_polygon(m, cols)
	# 月光照到的左側岩面
	var lit := PackedVector2Array([Vector2(x - 205, 2925), Vector2(x - 270, 3000), Vector2(x - 330, 3110), Vector2(x - 390, 3260), Vector2(x - 430, 3440),
		Vector2(x - 440, 3620), Vector2(x - 330, 3560), Vector2(x - 250, 3330), Vector2(x - 190, 3120), Vector2(x - 170, 2980)])
	L.draw_polygon(lit, PackedColorArray([Color("3a5880"), Color("344f76"), Color("2e486c"), Color("283f60"), Color("223656"), Color("1e304e"),
		Color("1e304e"), Color("26395a"), Color("2e486c"), Color("3a5880")]))
	L.draw_colored_polygon(PackedVector2Array([Vector2(x + 220, 2932), Vector2(x + 275, 2990), Vector2(x + 335, 3110), Vector2(x + 250, 3080), Vector2(x + 200, 2990)]), Color("2c4468"))
	# 稜線、岩層、裂縫
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	L.draw_polyline(PackedVector2Array([Vector2(x - 205, 2925), Vector2(x - 190, 3000), Vector2(x - 220, 3140), Vector2(x - 260, 3320), Vector2(x - 340, 3560)]), Color("4a6a94"), 4.0, true)
	L.draw_polyline(PackedVector2Array([Vector2(x + 220, 2932), Vector2(x + 210, 3020), Vector2(x + 250, 3160), Vector2(x + 300, 3360)]), Color("3a5478"), 3.0, true)
	var strata := PackedVector2Array()
	for k in 14:
		var y := 3040.0 + k * 58.0
		var hw := 380.0 - absf(y - 3460.0) * 0.22
		var xa := x - hw + rng.randf_range(0, 60)
		var xb := xa + rng.randf_range(80, 180)
		strata.append_array([Vector2(xa, y), Vector2(xb, y + rng.randf_range(-6, 6))])
		xa = x + hw - rng.randf_range(0, 60)
		xb = xa - rng.randf_range(80, 180)
		strata.append_array([Vector2(xa, y + 10), Vector2(xb, y + 10 + rng.randf_range(-6, 6))])
	L.draw_multiline(strata, Color("0c1424", 0.55), 3.0)
	# 缺口裡的泉水
	blob(L, Vector2(x, 2990), Vector2(150, 50), Color(0.55, 0.85, 1.0, 0.3))
	L.draw_colored_polygon(_ell(Vector2(x, 2990), 66, 16, 24), Color("2a6a9a"))
	L.draw_colored_polygon(_ell(Vector2(x, 2986), 50, 9, 24), Color("8fd4f5"))
	# 每一層：岩壁 → 水幕 → 下面的小水潭（水潭的前緣就是下一道水幕的起點）
	for k in 5:
		var rw: float = FALL_RW[k]
		var y0: float = FALL_T[k]
		var y1: float = FALL_B[k]
		# 岩壁（左右邊緣不規則）
		var face := PackedVector2Array()
		var fc := PackedColorArray()
		for j in 7:
			var s := j / 6.0
			face.append(Vector2(x - rw - 10.0 * s + (8.0 if j % 2 == 0 else -8.0), lerpf(y0 - 20.0, y1 + 30.0, s)))
		for j in 7:
			var s := 1.0 - j / 6.0
			face.append(Vector2(x + rw + 10.0 * s + (8.0 if j % 2 == 1 else -8.0), lerpf(y0 - 20.0, y1 + 30.0, s)))
		for q in face:
			fc.append(Color("2a4466").lerp(Color("142238"), clampf((q.y - y0) / (y1 - y0 + 30.0), 0.0, 1.0)))
		L.draw_polygon(face, fc)
		var cr := PackedVector2Array()
		for j in 6:
			var cx := x - rw + 30.0 + rng.randf() * (rw * 2.0 - 60.0)
			if absf(cx - x) < FALL_W[k] / 2.0 + 20.0:
				continue
			cr.append_array([Vector2(cx, y0 + 10.0), Vector2(cx + rng.randf_range(-14, 14), y0 + (y1 - y0) * rng.randf_range(0.4, 0.9))])
		if cr.size() > 0:
			L.draw_multiline(cr, Color("0c1424", 0.6), 3.0)
		# 水幕：上窄下寬、中間比較亮
		var w: float = FALL_W[k]
		var top := []
		for j in 9:
			var dx := -w / 2.0 + w * j / 8.0
			top.append(Vector2(x + dx, y0 + 10.0 * (1.0 - pow(dx / (w / 2.0), 2.0))))
		var cur := PackedVector2Array()
		var cc := PackedColorArray()
		for q in top:
			cur.append(q)
			cc.append(Color("8fd4f5"))
		cur.append(Vector2(x + w / 2.0 + 14.0, y1))
		cc.append(Color("e6f7ff"))
		cur.append(Vector2(x - w / 2.0 - 14.0, y1))
		cc.append(Color("e6f7ff"))
		L.draw_polygon(cur, cc)
		var band := PackedVector2Array()
		for j in int(w / 18.0):
			var bx := x - w / 2.0 + 10.0 + j * 18.0 + (j % 3) * 3.0
			band.append_array([Vector2(bx, y0 + 12.0), Vector2(bx + (bx - x) * 0.12, y1 - 8.0)])
		L.draw_multiline(band, Color("5aa8dc", 0.5), 3.0)
		L.draw_rect(Rect2(Vector2(x - w * 0.16, y0 + 8.0), Vector2(w * 0.32, y1 - y0 - 8.0)), Color(1, 1, 1, 0.22))
		# 水幕兩側的濕岩
		L.draw_polyline(PackedVector2Array([Vector2(x - w / 2.0 - 4, y0 + 6), Vector2(x - w / 2.0 - 18, y1)]), Color("0a1220", 0.7), 6.0, true)
		L.draw_polyline(PackedVector2Array([Vector2(x + w / 2.0 + 4, y0 + 6), Vector2(x + w / 2.0 + 18, y1)]), Color("0a1220", 0.7), 6.0, true)
		if k == 4:
			break
		# 小水潭（岩棚）
		var bc := Vector2(x, FALL_T[k + 1] - 40.0)
		var brx: float = FALL_RW[k + 1] + 26.0
		var rim := PackedVector2Array()
		for j in 40:
			var a := TAU * j / 40.0
			var wob := 1.0 + 0.05 * sin(a * 7.0 + k) + 0.03 * sin(a * 13.0)
			rim.append(bc + Vector2(cos(a) * brx * wob, sin(a) * 50.0 * wob))
		L.draw_colored_polygon(_shift(rim, Vector2(0, 14)), Color("142238"))
		L.draw_colored_polygon(rim, Color("3e5c82"))
		L.draw_colored_polygon(_ell(bc + Vector2(0, -2), brx - 40.0, 30, 32), Color("1e5a8a"))
		L.draw_colored_polygon(_ell(bc + Vector2(-20, -8), brx * 0.5, 14, 24), Color("3a80b4"))
		# 岩棚上的苔蘚、小松、發光的蕨
		for j in 2:
			var sd := -1.0 if j == 0 else 1.0
			var pp := bc + Vector2(sd * (brx - 24.0), -4)
			L.draw_colored_polygon(_ell(pp, 30, 14, 12), Color("2a5a4a"))
			_dot(L, pp + Vector2(sd * -6, -6), 5.0, Color("7affd2"), 32)
			if k % 2 == j:
				var tp := pp + Vector2(sd * 10, -6)
				L.draw_colored_polygon(PackedVector2Array([tp + Vector2(-26, 0), tp + Vector2(0, -78), tp + Vector2(26, 0)]), Color("173a40"))
				L.draw_colored_polygon(PackedVector2Array([tp + Vector2(-20, -30), tp + Vector2(0, -98), tp + Vector2(20, -30)]), Color("1f4a50"))
				L.draw_colored_polygon(PackedVector2Array([tp + Vector2(-2, -30), tp + Vector2(0, -98), tp + Vector2(20, -30)]), Color("2a5e64"))
	# 大水潭：石頭圍一圈，月亮的倒影、睡蓮
	var pool := FALL_POOL
	var ring := PackedVector2Array()
	for j in 56:
		var a := TAU * j / 56.0
		ring.append(pool + Vector2(cos(a) * 300.0 * (1.0 + 0.04 * sin(a * 6.0)), sin(a) * 120.0 * (1.0 + 0.05 * sin(a * 5.0 + 1.0))))
	L.draw_colored_polygon(_shift(ring, Vector2(0, 12)), Color("101a2e"))
	L.draw_colored_polygon(ring, Color("3a5070"))
	L.draw_colored_polygon(_off(ring, -22.0), Color("1a5a8a"))
	L.draw_colored_polygon(_shift(_off(ring, -70.0), Vector2(0, 6)), Color("2a72a8"))
	blob(L, pool + Vector2(90, 14), Vector2(80, 26), Color(0.9, 0.95, 1.0, 0.4))      # 月亮的倒影
	for q in [Vector2(-170, 30), Vector2(-120, 60), Vector2(160, 50), Vector2(210, 10)]:
		L.draw_colored_polygon(_ell(pool + q, 22, 10, 14), Color("2a7a5a"))
		_dot(L, pool + q + Vector2(4, -4), 4.0, Color("ffd6f0"), 32)
	for j in 16:
		var a := PI * 0.05 + PI * 0.9 * j / 15.0
		var p := pool + Vector2(cos(a) * 300.0, sin(a) * 118.0 + 6.0)
		var rr := rng.randf_range(22, 36)
		L.draw_colored_polygon(_ell(p, rr, rr * 0.6, 12), Color("2a3a56"))
		L.draw_colored_polygon(_ell(p + Vector2(-5, -5), rr * 0.6, rr * 0.3, 10), Color("46597c"))
	# 山腳的大石頭、發光苔蘚
	for k in 14:
		var side := -1.0 if k % 2 == 0 else 1.0
		var yy := rng.randf_range(3300, 3860)
		var hw := 400.0 - absf(yy - 3500.0) * 0.25
		var p := Vector2(x + side * (hw + rng.randf_range(-10, 40)), yy)
		L.draw_colored_polygon(_ell(p + Vector2(0, 10), rng.randf_range(34, 56), rng.randf_range(20, 30), 12), Color("141c30"))
		L.draw_colored_polygon(_ell(p, rng.randf_range(30, 50), rng.randf_range(18, 28), 12), Color("2e3e5c"))
		L.draw_colored_polygon(_ell(p + Vector2(-8, -8), 18, 9, 10), Color("4a5e82"))
		_dot(L, p + Vector2(10, -12), 5.0, Color("7affd2"), 32)
	# 高處的薄霧
	blob(L, Vector2(x, 3200), Vector2(420, 90), Color(0.8, 0.9, 1.0, 0.1))
	blob(L, Vector2(x, 3560), Vector2(460, 90), Color(0.8, 0.9, 1.0, 0.08))


## 星點觀測台：石頭平台、圓頂（望遠鏡在 _fx 轉）、旁邊一排高低不同的石柱
func _p_dome(L) -> void:
	var c := DOME_C
	blob(L, c + Vector2(30, 140), Vector2(380, 120), Color(0, 0, 0, 0.35))
	# 八角形的平台＋往南的階梯
	var oct := PackedVector2Array()
	for k in 8:
		var a := TAU * k / 8.0 + PI / 8.0
		oct.append(c + Vector2(cos(a) * 280, sin(a) * 190 + 60))
	L.draw_colored_polygon(_shift(oct, Vector2(0, 26)), Color("1a2236"))
	L.draw_colored_polygon(oct, Color("4a5a7a"))
	L.draw_colored_polygon(_shift(_off(oct, -26.0), Vector2(0, -4)), Color("5a6a8e"))
	for k in 4:
		L.draw_rect(Rect2(c + Vector2(-90 + k * 6, 236 + k * 22), Vector2(180 - k * 12, 20)), Color("6a7a9e").darkened(k * 0.08))
	# 圓柱形的底座
	L.draw_rect(Rect2(c + Vector2(-170, -40), Vector2(340, 130)), Color("c8cfe0"))
	L.draw_rect(Rect2(c + Vector2(60, -40), Vector2(110, 130)), Color("a8b0c8"))
	L.draw_rect(Rect2(c + Vector2(-30, 10), Vector2(60, 80)), Color("2a3046"))
	for q in [Vector2(-120, 20), Vector2(110, 20)]:
		L.draw_colored_polygon(_ell(c + q, 16, 20, 16), Color("ffe7a3"))
	L.draw_rect(Rect2(c + Vector2(-180, -52), Vector2(360, 16)), Color("8890a8"))
	# 圓頂
	L.draw_colored_polygon(_ell(c + Vector2(0, -44), 170, 160, 48, PI, TAU), Color("9aa8c8"))
	L.draw_colored_polygon(_ell(c + Vector2(-30, -54), 110, 130, 40, PI, TAU), Color("b8c6e2"))
	for k in 5:
		var a := PI + PI * (k + 1) / 6.0
		L.draw_line(c + Vector2(0, -204), c + Vector2(cos(a) * 170, -44 + sin(a) * 160 * 0.0), Color("7a88a8"), 2.0, true)
	# 開口（望遠鏡從這裡伸出去）
	L.draw_colored_polygon(PackedVector2Array([c + Vector2(-26, -200), c + Vector2(26, -200), c + Vector2(40, -52), c + Vector2(-40, -52)]), Color("141a2c"))
	# 一排石柱（高高低低，像長條圖）
	var hs := [60.0, 110.0, 170.0, 230.0, 190.0, 120.0, 70.0]
	for k in hs.size():
		var p := c + Vector2(-560 + k * 52.0, 180)
		var hh: float = hs[k]
		blob(L, p + Vector2(16, 4), Vector2(30, 10), Color(0, 0, 0, 0.3))
		L.draw_rect(Rect2(p + Vector2(-18, -hh), Vector2(36, hh)), Color("5a6a8e"))
		L.draw_rect(Rect2(p + Vector2(-18, -hh), Vector2(12, hh)), Color("7a8ab0"))
		L.draw_rect(Rect2(p + Vector2(-22, -hh - 8), Vector2(44, 10)), Color("8a9ac0"))
	# 東邊散布的地燈（亮的部分在 _fx）
	for q in _dome_lights():
		L.draw_colored_polygon(_ell(q, 12, 7, 12), Color("2a3a56"))


func _dome_lights() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for k in 16:
		var s := k / 15.0
		var base := DOME_C + Vector2(280 + s * 420, 320 - s * 330)
		out.append(base + Vector2(rng.randf_range(-40, 40), rng.randf_range(-60, 60)))
	return out


## 排列花園：四邊有入口的樹籬、四塊花圃（三色花的各種排法）、中間的噴水池、南邊的花拱門
func _p_garden(L) -> void:
	var g := GARDEN
	L.draw_rect(g.grow(30.0), Color("2a4a40"))
	L.draw_rect(g, Color("8a8aa0"))           # 碎石步道
	var gr := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for k in 240:
		gr.append(g.position + Vector2(rng.randf() * g.size.x, rng.randf() * g.size.y))
	for q in gr:
		L.draw_rect(Rect2(q, Vector2(4, 3)), Color("a2a2b8"))
	# 四塊花圃
	var cx := g.get_center().x
	var cy := g.get_center().y
	var beds := [Rect2(g.position.x + 70, g.position.y + 70, 300, 140), Rect2(cx + 90, g.position.y + 70, 300, 140),
		Rect2(g.position.x + 70, cy + 70, 300, 140), Rect2(cx + 90, cy + 70, 300, 140)]
	var fl := [Color("ff9ad5"), Color("ffd36e"), Color("8fd0ff")]
	var perms := [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]
	for bi in beds.size():
		var b: Rect2 = beds[bi]
		L.draw_rect(b.grow(8.0), Color("6a5a4a"))
		L.draw_rect(b, Color("3a5a3a"))
		for row in 3:
			var pm: Array = perms[(bi * 3 + row) % 6]
			for k in 3:
				var cc := b.position + Vector2(50 + k * 100, 26 + row * 44)
				for j in 4:
					_dot(L, cc + Vector2((j % 2) * 26 - 13, (j / 2) * 14 - 7), 10.0, fl[pm[k]], 32)
				_dot(L, cc, 5.0, Color("fff8e0"), 32)
	# 樹籬（上面亮、南面暗）
	for hg in _hedges():
		var r: Rect2 = hg
		L.draw_rect(Rect2(r.position + Vector2(0, 14), r.size), Color("1c3a30"))
		L.draw_rect(r, Color("2f6a52"))
		L.draw_rect(Rect2(r.position, Vector2(r.size.x, 8)), Color("4f9a7a"))
	# 角落的球形灌木
	for q in [g.position, Vector2(g.end.x, g.position.y), Vector2(g.position.x, g.end.y), g.end]:
		blob(L, q + Vector2(10, 30), Vector2(50, 18), Color(0, 0, 0, 0.3))
		_dot(L, q, 44.0, Color("2f6a52"), 128)
		_dot(L, q + Vector2(-12, -14), 24.0, Color("4f9a7a"), 128)
	# 噴水池
	var f := FOUNTAIN
	L.draw_colored_polygon(_ell(f + Vector2(0, 12), 104, 66, 40), Color("4a4a5e"))
	L.draw_colored_polygon(_ell(f, 100, 62, 40), Color("c8c8d8"))
	L.draw_colored_polygon(_ell(f, 84, 50, 40), Color("2a6aa0"))
	L.draw_colored_polygon(_ell(f + Vector2(0, -6), 60, 32, 32), Color("3a82b8"))
	L.draw_rect(Rect2(f + Vector2(-12, -70), Vector2(24, 70)), Color("d8d8e8"))
	L.draw_colored_polygon(_ell(f + Vector2(0, -70), 38, 16, 24), Color("c8c8d8"))
	# 南邊的花拱門
	var ar := Vector2(cx, g.end.y + 10)
	L.draw_arc(ar + Vector2(0, -40), 76, PI, TAU, 24, Color("6a4a3a"), 12.0, true)
	for q in [Vector2(-76, -40), Vector2(76, -40)]:
		L.draw_rect(Rect2(ar + q + Vector2(-6, 0), Vector2(12, 50)), Color("6a4a3a"))
	for k in 12:
		var a := PI + PI * k / 11.0
		_dot(L, ar + Vector2(0, -40) + Vector2(cos(a), sin(a)) * 76.0, 12.0, fl[k % 3], 32)


## 骰子市集：石板廣場、條紋帳篷、中間一顆巨大的骰子；帳篷之間掛著燈串（亮的部分在 _fx）
func _p_market(L) -> void:
	var c := MARKET_C
	L.draw_colored_polygon(_ell(c + Vector2(0, 30), 470, 330, 64), Color("2a2a44"))
	L.draw_colored_polygon(_ell(c, 460, 320, 64), Color("5a5a78"))
	for k in 5:
		L.draw_polyline(_ell(c, 460 - k * 80.0, 320 - k * 56.0, 48), Color("6e6e8e"), 3.0, true)
	for k in 16:
		var a := TAU * k / 16.0
		L.draw_line(c + Vector2(cos(a) * 80, sin(a) * 56), c + Vector2(cos(a) * 460, sin(a) * 320), Color("6e6e8e"), 2.0, true)
	var stripes := [[Color("ff7a7a"), Color("fff0d8")], [Color("ffb35a"), Color("fff0d8")], [Color("8fd0ff"), Color("eaf6ff")],
		[Color("c6a6ff"), Color("f4ecff")], [Color("7affd2"), Color("eafff8")]]
	for i in TENTS.size():
		var p: Vector2 = TENTS[i]
		var sc: Array = stripes[i % stripes.size()]
		blob(L, p + Vector2(20, 50), Vector2(130, 34), Color(0, 0, 0, 0.35))
		# 攤位的檯子和貨物
		L.draw_rect(Rect2(p + Vector2(-90, 0), Vector2(180, 50)), Color("6b4f2e"))
		L.draw_rect(Rect2(p + Vector2(-90, 0), Vector2(180, 10)), Color("8a6a40"))
		for k in 4:
			var q := p + Vector2(-60 + k * 40, -6)
			if (i + k) % 2 == 0:
				_die(L, q, 14.0, (i * 3 + k) % 6 + 1)
			else:
				_dot(L, q, 12.0, [Color("ff6a5a"), Color("ffd36e"), Color("9ade6a")][(i + k) % 3], 32)
		# 帳篷頂（條紋）
		var apex := p + Vector2(0, -150)
		for k in 6:
			var x0 := -110.0 + k * 220.0 / 6.0
			var x1 := x0 + 220.0 / 6.0
			L.draw_colored_polygon(PackedVector2Array([apex, p + Vector2(x0, -30), p + Vector2(x1, -30)]), sc[k % 2])
		for k in 6:
			var x0 := -110.0 + k * 220.0 / 6.0
			L.draw_colored_polygon(_ell(p + Vector2(x0 + 220.0 / 12.0, -30), 220.0 / 12.0, 12, 12, 0, PI), sc[k % 2])
		L.draw_line(apex, apex + Vector2(0, -40), Color("6b4f2e"), 4.0)
		L.draw_colored_polygon(PackedVector2Array([apex + Vector2(0, -40), apex + Vector2(34, -32), apex + Vector2(0, -24)]), sc[0])
	# 燈串的線
	for k in TENTS.size():
		var a: Vector2 = TENTS[k] + Vector2(0, -190)
		var b: Vector2 = c + Vector2(0, -260)
		L.draw_polyline(_sag(a, b, 40.0), Color(0.1, 0.1, 0.15, 0.7), 2.0, true)
	# 中間的大骰子（看得到三個面）
	var d := c + Vector2(0, -40)
	var s := 110.0
	blob(L, d + Vector2(40, 140), Vector2(150, 40), Color(0, 0, 0, 0.4))
	var front := PackedVector2Array([d + Vector2(-s / 2, 0), d + Vector2(s / 2, 0), d + Vector2(s / 2, s), d + Vector2(-s / 2, s)])
	var top := PackedVector2Array([d + Vector2(-s / 2, 0), d + Vector2(s / 2, 0), d + Vector2(s / 2 + 44, -36), d + Vector2(-s / 2 + 44, -36)])
	var side := PackedVector2Array([d + Vector2(s / 2, 0), d + Vector2(s / 2 + 44, -36), d + Vector2(s / 2 + 44, s - 36), d + Vector2(s / 2, s)])
	L.draw_colored_polygon(front, Color("fffaf0"))
	L.draw_colored_polygon(top, Color("ffffff"))
	L.draw_colored_polygon(side, Color("d8d0c0"))
	for q in [Vector2(-30, 26), Vector2(0, 55), Vector2(30, 84), Vector2(-30, 84), Vector2(30, 26)]:
		_dot(L, d + q, 9.0, Color("2a2440"), 32)
	_dot(L, d + Vector2(22, -18), 9.0, Color("d04a3a"), 32)
	for q in [Vector2(68, 20), Vector2(78, 50)]:
		_dot(L, d + q, 7.0, Color("2a2440"), 32)


static func _sag(a: Vector2, b: Vector2, depth: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in 13:
		var s := k / 12.0
		out.append(a.lerp(b, s) + Vector2(0, sin(s * PI) * depth))
	return out


static func _die(L, c: Vector2, half: float, n: int) -> void:
	L.draw_rect(Rect2(c - Vector2(half, half), Vector2(half, half) * 2.0), Color("fffaf0"))
	L.draw_rect(Rect2(c - Vector2(half, half), Vector2(half, half) * 2.0), Color("8a6a4a"), false, 1.5)
	var u := half * 0.5
	var pip := {1: [Vector2.ZERO], 2: [Vector2(-u, -u), Vector2(u, u)], 3: [Vector2(-u, -u), Vector2.ZERO, Vector2(u, u)],
		4: [Vector2(-u, -u), Vector2(u, -u), Vector2(-u, u), Vector2(u, u)],
		5: [Vector2(-u, -u), Vector2(u, -u), Vector2.ZERO, Vector2(-u, u), Vector2(u, u)],
		6: [Vector2(-u, -u), Vector2(u, -u), Vector2(-u, 0), Vector2(u, 0), Vector2(-u, u), Vector2(u, u)]}
	for q in pip[n]:
		_dot(L, c + q, half * 0.2, Color("2a2440"), 32)


## 三角燈塔：岬角的岩石、紅白相間的高塔、陽台和燈室、旁邊守塔人的小屋（光束在 _fx）
func _p_lighthouse(L) -> void:
	var lh := LIGHTHOUSE
	# 岩石岬角
	var rng := RandomNumberGenerator.new()
	rng.seed = 51
	for k in 18:
		var p := lh + Vector2(rng.randf_range(-220, 320), rng.randf_range(-40, 220))
		var rr := rng.randf_range(50, 100)
		L.draw_colored_polygon(_ell(p + Vector2(0, 16), rr, rr * 0.55, 14), Color("141c30"))
		L.draw_colored_polygon(_ell(p, rr, rr * 0.55, 14), Color("3a4660"))
		L.draw_colored_polygon(_ell(p + Vector2(-rr * 0.2, -rr * 0.18), rr * 0.6, rr * 0.3, 12), Color("566488"))
	blob(L, lh + Vector2(60, 20), Vector2(180, 40), Color(0, 0, 0, 0.4))
	# 通到燈塔的石階
	for k in 6:
		var sp := lh + Vector2(-30 - k * 26, 70 + k * 30)
		L.draw_colored_polygon(_ell(sp + Vector2(0, 6), 46, 14, 14), Color("1a2236"))
		L.draw_colored_polygon(_ell(sp, 46, 14, 14), Color("7a8298"))
	# 守塔人的小屋：石牆、煙囪、亮著的窗、小柵欄
	var hc := lh + Vector2(-190, 140)
	blob(L, hc + Vector2(10, 30), Vector2(120, 30), Color(0, 0, 0, 0.35))
	L.draw_rect(Rect2(hc + Vector2(-80, -66), Vector2(160, 90)), Color("cfd2e0"))
	L.draw_rect(Rect2(hc + Vector2(30, -66), Vector2(50, 90)), Color("aeb2c6"))
	var bricks := PackedVector2Array()
	for k in 4:
		bricks.append_array([hc + Vector2(-80, -44 + k * 20), hc + Vector2(80, -44 + k * 20)])
	L.draw_multiline(bricks, Color("9a9eb4"), 2.0)
	L.draw_rect(Rect2(hc + Vector2(36, -150), Vector2(22, 60)), Color("6a6e86"))
	L.draw_colored_polygon(PackedVector2Array([hc + Vector2(-98, -60), hc + Vector2(98, -60), hc + Vector2(60, -128), hc + Vector2(-60, -128)]), Color("34457a"))
	L.draw_colored_polygon(PackedVector2Array([hc + Vector2(-98, -60), hc + Vector2(0, -60), hc + Vector2(0, -128), hc + Vector2(-60, -128)]), Color("3e5290"))
	L.draw_rect(Rect2(hc + Vector2(-18, -30), Vector2(36, 54)), Color("3a2a22"))
	_dot(L, hc + Vector2(10, 0), 3.0, Color("e0c070"), 16)
	for wx in [-60.0, 34.0]:
		L.draw_rect(Rect2(hc + Vector2(wx, -48), Vector2(28, 24)), Color("ffe08a"))
		L.draw_line(hc + Vector2(wx + 14, -48), hc + Vector2(wx + 14, -24), Color("6a5a3a"), 2.0)
	var fence := PackedVector2Array()
	for k in 7:
		var fx := hc.x - 120.0 + k * 24.0
		fence.append_array([Vector2(fx, hc.y + 40), Vector2(fx, hc.y + 14)])
	fence.append_array([Vector2(hc.x - 124, hc.y + 22), Vector2(hc.x + 24, hc.y + 22)])
	L.draw_multiline(fence, Color("c8b48a"), 4.0)
	# 塔基：八角形的石台
	L.draw_colored_polygon(_ell(lh + Vector2(0, 14), 120, 40, 8), Color("2a3046"))
	L.draw_colored_polygon(_ell(lh, 116, 36, 8), Color("8a90a8"))
	L.draw_colored_polygon(_ell(lh + Vector2(-10, -4), 90, 24, 8), Color("a8aec4"))
	# 塔身：往上變窄，紅白相間，左亮右暗像圓柱
	var hgt := 600.0
	var wb := 150.0
	var wt := 88.0
	for k in 7:
		var y0 := -hgt * k / 7.0
		var y1 := -hgt * (k + 1) / 7.0
		var w0 := lerpf(wb, wt, k / 7.0)
		var w1 := lerpf(wb, wt, (k + 1) / 7.0)
		var col := Color("ecebf2") if k % 2 == 0 else Color("d84a4a")
		L.draw_colored_polygon(PackedVector2Array([lh + Vector2(-w0 / 2, y0), lh + Vector2(w0 / 2, y0), lh + Vector2(w1 / 2, y1), lh + Vector2(-w1 / 2, y1)]), col)
		L.draw_colored_polygon(PackedVector2Array([lh + Vector2(-w0 / 2, y0), lh + Vector2(-w0 * 0.3, y0), lh + Vector2(-w1 * 0.3, y1), lh + Vector2(-w1 / 2, y1)]), col.lightened(0.18))
		L.draw_colored_polygon(PackedVector2Array([lh + Vector2(w0 * 0.2, y0), lh + Vector2(w0 / 2, y0), lh + Vector2(w1 / 2, y1), lh + Vector2(w1 * 0.2, y1)]), col.darkened(0.22))
		L.draw_colored_polygon(PackedVector2Array([lh + Vector2(w0 * 0.38, y0), lh + Vector2(w0 / 2, y0), lh + Vector2(w1 / 2, y1), lh + Vector2(w1 * 0.38, y1)]), col.darkened(0.38))
	# 拱門、窗、塔頂的托架
	L.draw_rect(Rect2(lh + Vector2(-22, -70), Vector2(44, 70)), Color("2e2636"))
	L.draw_colored_polygon(_ell(lh + Vector2(0, -70), 22, 20, 16, PI, TAU), Color("2e2636"))
	L.draw_rect(Rect2(lh + Vector2(-26, -4), Vector2(52, 8)), Color("6a6e86"))
	for k in 3:
		var wy := -200.0 - k * 130.0
		L.draw_rect(Rect2(lh + Vector2(-12, wy), Vector2(24, 34)), Color("3a3046"))
		L.draw_rect(Rect2(lh + Vector2(-9, wy + 3), Vector2(18, 28)), Color("ffe08a"))
	var gy := lh.y - hgt
	for k in 7:
		var bx := lh.x - 42.0 + k * 14.0
		L.draw_colored_polygon(PackedVector2Array([Vector2(bx - 5, gy), Vector2(bx + 5, gy), Vector2(bx + 2, gy + 26), Vector2(bx - 2, gy + 26)]), Color("3a3a4c"))
	# 陽台和欄杆
	L.draw_colored_polygon(_ell(Vector2(lh.x, gy + 8), 82, 20, 28), Color("22222e"))
	L.draw_colored_polygon(_ell(Vector2(lh.x, gy), 82, 20, 28), Color("5a5a70"))
	L.draw_colored_polygon(_ell(Vector2(lh.x - 8, gy - 3), 60, 12, 24), Color("70708a"))
	var rail := PackedVector2Array()
	for k in 13:
		var a := PI * k / 12.0
		var rx := lh.x - cos(a) * 78.0
		var ry := gy + sin(a) * 18.0
		rail.append_array([Vector2(rx, ry), Vector2(rx, ry - 30)])
	L.draw_multiline(rail, Color("2a2a3a"), 3.0)
	L.draw_arc(Vector2(lh.x, gy - 30), 78.0, 0.0, PI, 24, Color("2a2a3a"), 4.0, true)
	L.draw_line(Vector2(lh.x - 78, gy - 30), Vector2(lh.x - 78, gy - 4), Color("2a2a3a"), 4.0)
	L.draw_line(Vector2(lh.x + 78, gy - 30), Vector2(lh.x + 78, gy - 4), Color("2a2a3a"), 4.0)
	# 燈室：玻璃窗、裡面的透鏡
	L.draw_rect(Rect2(Vector2(lh.x - 44, gy - 104), Vector2(88, 78)), Color("3a3a4c"))
	L.draw_rect(Rect2(Vector2(lh.x - 40, gy - 100), Vector2(80, 72)), Color("fff2b0"))
	L.draw_colored_polygon(_ell(Vector2(lh.x, gy - 64), 22, 28, 20), Color("fffbe6"))
	L.draw_colored_polygon(_ell(Vector2(lh.x - 6, gy - 70), 8, 12, 12), Color("ffffff"))
	for k in 4:
		L.draw_line(Vector2(lh.x - 40 + k * 26.7, gy - 100), Vector2(lh.x - 40 + k * 26.7, gy - 28), Color("3a3a4a"), 3.0)
	L.draw_line(Vector2(lh.x - 40, gy - 64), Vector2(lh.x + 40, gy - 64), Color("3a3a4a", 0.6), 2.0)
	# 屋頂：紅色圓頂、通風球、避雷針
	L.draw_rect(Rect2(Vector2(lh.x - 54, gy - 108), Vector2(108, 8)), Color("8a2a2a"))
	L.draw_colored_polygon(_ell(Vector2(lh.x, gy - 106), 54, 50, 28, PI, TAU), Color("c83a3a"))
	L.draw_colored_polygon(_ell(Vector2(lh.x - 16, gy - 118), 20, 26, 16, PI, TAU), Color("e06060"))
	_dot(L, Vector2(lh.x, gy - 158), 12.0, Color("3a3a4a"), 32)
	_dot(L, Vector2(lh.x - 3, gy - 161), 5.0, Color("7a7a8e"), 16)
	L.draw_line(Vector2(lh.x, gy - 168), Vector2(lh.x, gy - 206), Color("3a3a4a"), 4.0)
	_dot(L, Vector2(lh.x, gy - 208), 5.0, Color("c8c8d8"), 16)


## 渡口：木棧橋伸進海裡，停著一艘有燈的帆船
func _p_dock(L) -> void:
	var pr := PIER
	L.draw_rect(Rect2(pr.position + Vector2(0, 18), pr.size), Color(0, 0, 0, 0.3))
	L.draw_rect(pr, Color("8a6038"))
	var pl := PackedVector2Array()
	var x := pr.position.x + 10.0
	while x < pr.end.x:
		pl.append_array([Vector2(x, pr.position.y), Vector2(x, pr.end.y)])
		x += 24.0
	L.draw_multiline(pl, Color("6a4628"), 3.0)
	for k in 5:
		L.draw_rect(Rect2(Vector2(pr.position.x + 20 + k * 80, pr.end.y - 4), Vector2(14, 34)), Color("5a3a22"))
	# 帆船
	var bt := Vector2(7080, 4110)
	blob(L, bt + Vector2(0, 30), Vector2(150, 30), Color(0, 0, 0, 0.35))
	L.draw_colored_polygon(PackedVector2Array([bt + Vector2(-130, -20), bt + Vector2(130, -20), bt + Vector2(96, 30), bt + Vector2(-96, 30)]), Color("8a4a2e"))
	L.draw_rect(Rect2(bt + Vector2(-130, -26), Vector2(260, 10)), Color("c8955a"))
	L.draw_line(bt + Vector2(-10, -24), bt + Vector2(-10, -300), Color("5a3a22"), 7.0)
	L.draw_colored_polygon(PackedVector2Array([bt + Vector2(-4, -290), bt + Vector2(110, -50), bt + Vector2(-4, -50)]), Color("eef0ff"))
	L.draw_colored_polygon(PackedVector2Array([bt + Vector2(-16, -260), bt + Vector2(-100, -60), bt + Vector2(-16, -60)]), Color("d8dcf0"))
	# 告示牌
	var sg := EXIT_SIGN
	L.draw_rect(Rect2(sg + Vector2(-6, -20), Vector2(12, 90)), Color("6b4f2e"))
	L.draw_rect(Rect2(sg + Vector2(-130, -90), Vector2(260, 70)), Color("9fd8ff"))
	L.draw_rect(Rect2(sg + Vector2(-130, -90), Vector2(260, 70)), Color("4a7aa8"), false, 4.0)
	var font := UITheme.bold_font()
	L.draw_string(font, sg + Vector2(-130, -42), "渡口 → 高二", HORIZONTAL_ALIGNMENT_CENTER, 260, 32, Color("10223a"))


## 橋東邊的骰子攤車（彩蛋三）
func _p_cart(L) -> void:
	var p := DICE_NPC
	blob(L, p + Vector2(10, 50), Vector2(110, 26), Color(0, 0, 0, 0.35))
	L.draw_rect(Rect2(p + Vector2(-80, -10), Vector2(160, 56)), Color("8a5a3a"))
	L.draw_rect(Rect2(p + Vector2(-80, -10), Vector2(160, 10)), Color("a87a4e"))
	for q in [Vector2(-56, 50), Vector2(56, 50)]:
		L.draw_colored_polygon(_ell(p + q, 18, 18, 16), Color("3a2a22"))
		L.draw_colored_polygon(_ell(p + q, 8, 8, 12), Color("8a6a4a"))
	_die(L, p + Vector2(-24, -28), 18.0, 3)
	_die(L, p + Vector2(22, -28), 18.0, 4)
	# 大陽傘
	L.draw_line(p + Vector2(70, -10), p + Vector2(70, -150), Color("6b4f2e"), 5.0)
	for k in 6:
		var a0 := PI + PI * k / 6.0
		var a1 := PI + PI * (k + 1) / 6.0
		L.draw_colored_polygon(PackedVector2Array([p + Vector2(70, -170), p + Vector2(70, -150) + Vector2(cos(a0), sin(a0) * 0.35) * 110.0,
			p + Vector2(70, -150) + Vector2(cos(a1), sin(a1) * 0.35) * 110.0]), Color("ffb35a") if k % 2 == 0 else Color("fff0d8"))
	# 攤販
	var n := p + Vector2(-110, 0)
	L.draw_colored_polygon(PackedVector2Array([n + Vector2(-24, 40), n + Vector2(24, 40), n + Vector2(16, -20), n + Vector2(-16, -20)]), Color("5a7ab0"))
	L.draw_colored_polygon(_ell(n + Vector2(0, -40), 22, 22, 20), Color("e8c8a0"))
	L.draw_colored_polygon(_ell(n + Vector2(0, -52), 26, 12, 16, PI, TAU), Color("c8553d"))


# ================= 大門、名牌 =================

## 每個地區的大門：西邊是木頭的門（掛著布幔），東邊是會發光的石拱門；還沒開放的是灰色的
func _p_gates(L) -> void:
	var font := UITheme.bold_font()
	for i in ZONES.size():
		var z: Dictionary = ZONES[i]
		var g: Vector2 = z.gate
		var open := _open.has(z.id)
		var col: Color = z.color if open else Color(0.62, 0.6, 0.72)
		var east := i >= LEFT_ZONES
		blob(L, g + Vector2(0, 20), Vector2(140, 34), Color(0, 0, 0, 0.3))
		if east:
			var arc := PackedVector2Array()
			for k in 25:
				var a := PI + PI * k / 24.0
				arc.append(g + Vector2(cos(a) * 92.0, -110.0 + sin(a) * 92.0))
			arc.insert(0, g + Vector2(-92, 10))
			arc.append(g + Vector2(92, 10))
			L.draw_polyline(arc, Color("2a3450"), 34.0, true)
			L.draw_polyline(arc, Color("4a5a80"), 26.0, true)
			L.draw_polyline(_shift(arc, Vector2(0, -3)), col, 5.0, true)
			for k in 7:
				var a := PI + PI * (k + 0.5) / 7.0
				_dot(L, g + Vector2(cos(a) * 92.0, -110.0 + sin(a) * 92.0), 5.0, col.lightened(0.3), 32)
		else:
			for sx in [-1.0, 1.0]:
				L.draw_rect(Rect2(g + Vector2(sx * 86 - 12, -170), Vector2(24, 180)), Color("6a4630"))
				L.draw_rect(Rect2(g + Vector2(sx * 86 - 12, -170), Vector2(8, 180)), Color("8a6040"))
			L.draw_colored_polygon(PackedVector2Array([g + Vector2(-124, -190), g + Vector2(124, -190), g + Vector2(110, -168), g + Vector2(-110, -168)]), Color("5a3a26"))
			L.draw_rect(Rect2(g + Vector2(-104, -150), Vector2(208, 14)), Color("6a4630"))
			# 布幔
			for sx in [-1.0, 1.0]:
				L.draw_colored_polygon(PackedVector2Array([g + Vector2(sx * 60 - 22, -136), g + Vector2(sx * 60 + 22, -136),
					g + Vector2(sx * 60 + 22, -70), g + Vector2(sx * 60, -84), g + Vector2(sx * 60 - 22, -70)]), col)
		# 名牌
		var nm: String = z.name
		var tw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
		var plate := Rect2(g + Vector2(-tw / 2.0 - 22, -268), Vector2(tw + 44, 62))
		L.draw_rect(Rect2(plate.position + Vector2(0, 6), plate.size), Color(0, 0, 0, 0.35))
		L.draw_rect(plate, Color(col.r, col.g, col.b, 0.95))
		L.draw_rect(plate, col.darkened(0.35), false, 4.0)
		L.draw_string(font, plate.position + Vector2(22, 46), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("1a1530"))
		if not open:
			_text_ol(L, font, g + Vector2(-120, -186), "準備中", HORIZONTAL_ALIGNMENT_CENTER, 240, 26, Color("e8e4f4"), 6)


# ================= 會動的東西（每幀畫） =================

var _sea_pt := {}      # 海面光點的位置是不是在海上（快取）

func _p_fx(L) -> void:
	var v := _view().grow(120.0)
	var font := UITheme.bold_font()
	var tiny := zoom < 0.3          # 拉遠看全島時：浪花、海面的光點都小於一個像素，不畫
	# 浪花：沿著海岸一小段一小段的白色弧線
	for side in ([] if tiny else [_coast_l, _coast_r]):
		var foam := PackedVector2Array()
		for i in side.size():
			var s: Array = side[i]
			var p: Vector2 = s[0]
			if not v.has_point(p):
				continue
			var n: Vector2 = s[1]
			var k := 0.5 + 0.5 * sin(t * 1.4 + i * 0.9)
			var c := p + n * (30.0 + 26.0 * k)
			var d := n.orthogonal() * 22.0
			foam.append_array([c - d, c + n * 4.0, c + n * 4.0, c + d])
		if not foam.is_empty():
			L.draw_multiline(foam, Color(1, 1, 1, 0.38), 3.0)
	# 海面的光：西邊是晨光的金色、東邊是月光的白點
	var gl := PackedVector2Array()
	var y := floorf(v.position.y / 140.0) * 140.0
	while y < v.end.y and not tiny:
		var x := floorf(v.position.x / 220.0) * 220.0 + fmod(y, 440.0) * 0.5
		while x < v.end.x:
			var q := Vector2(x + sin(t * 0.8 + y * 0.01) * 14.0, y)
			# 「這一點是不是海」每格都問一次很花時間（要跟整條海岸線比），記起來
			var key := Vector2i(int(x), int(y))
			if not _sea_pt.has(key):
				_sea_pt[key] = not _ground(Vector2(x, y)) and not _ground(Vector2(x - 14.0, y)) and not _ground(Vector2(x + 40.0, y))
			if _sea_pt[key]:
				gl.append_array([q, q + Vector2(26, 0)])
			x += 220.0
		y += 140.0
	if not gl.is_empty():
		L.draw_multiline(gl, Color(1.0, 0.9, 0.7, 0.16), 3.0)
	# 河的水流
	var rf := PackedVector2Array()
	for i in range(0, _river.size() - 1):
		var a := _river[i]
		if not v.has_point(a):
			continue
		var b := _river[i + 1]
		var d := (b - a).normalized()
		for k in 3:
			var ph := fmod(t * 0.7 + i * 0.37 + k * 0.33, 1.0)
			var p := a.lerp(b, ph) + d.orthogonal() * ((k - 1) * 50.0)
			rf.append_array([p, p + d * 30.0])
	if not rf.is_empty():
		L.draw_multiline(rf, Color(0.8, 0.95, 1.0, 0.35), 3.0)
	# 小屋煙囪的煙
	var ch := HOUSE + Vector2(88, -262)
	if v.has_point(ch):
		for k in 5:
			var ph := fmod(t * 0.35 + k * 0.2, 1.0)
			blob(L, ch + Vector2(sin(ph * 5.0 + k) * 16.0 + ph * 40.0, -ph * 180.0), Vector2(26, 26) * (0.6 + ph), Color(0.9, 0.88, 0.85, 0.45 * (1.0 - ph)))
		blob(L, HOUSE + Vector2(-80, -48), Vector2(60, 50), Color(1.0, 0.85, 0.5, 0.18 + 0.06 * sin(t * 3.0)))
		blob(L, HOUSE + Vector2(80, -48), Vector2(60, 50), Color(1.0, 0.85, 0.5, 0.18 + 0.06 * sin(t * 3.0 + 1.0)))
	# 橋上的燈籠：西邊暖色、東邊冷色
	if v.intersects(BRIDGE):
		for k in 5:
			var x := BRIDGE.position.x + 20.0 + k * (BRIDGE.size.x - 40.0) / 4.0
			var c: Color = Color(1.0, 0.8, 0.45).lerp(Color(0.6, 0.85, 1.0), k / 4.0)
			for yy in [BRIDGE.position.y - 40, BRIDGE.end.y - 44]:
				blob(L, Vector2(x, yy), Vector2(34, 34), Color(c.r, c.g, c.b, 0.45 + 0.1 * sin(t * 2.5 + k)))
				_dot(L, Vector2(x, yy), 7.0, c.lightened(0.4), 32)
	# 帆船的燈
	var bl2 := Vector2(7080, 4110) + Vector2(-10, -40)
	if v.has_point(bl2):
		blob(L, bl2, Vector2(40, 40), Color(1.0, 0.85, 0.5, 0.45 + 0.15 * sin(t * 2.0)))
	# 螢火蟲（星夜之地）
	for f in _flies:
		var p: Vector2 = f.base + Vector2(sin(t * 0.5 * f.s + f.ph) * 60.0, cos(t * 0.4 * f.s + f.ph * 1.3) * 40.0)
		if v.has_point(p):
			var on := 0.5 + 0.5 * sin(t * 2.2 * f.s + f.ph)
			blob(L, p, Vector2(18, 18), Color(0.7, 1.0, 0.75, 0.35 * on))
			_dot(L, p, 3.0, Color(0.9, 1.0, 0.8, 0.5 + 0.5 * on), 32)
	# 極光：星夜之地北邊的天空
	if v.position.y < 1000.0 and v.end.x > 4100.0:
		for k in 3:
			var pts := PackedVector2Array()
			var cols := PackedColorArray()
			for j in 41:
				var x := lerpf(4100, 7100, j / 40.0)
				var yy := 120.0 + k * 70.0 + sin(x * 0.002 + t * 0.3 + k) * 60.0
				pts.append(Vector2(x, yy))
			var band := PackedVector2Array(pts)
			for j in range(pts.size() - 1, -1, -1):
				band.append(pts[j] + Vector2(0, 160 + 40 * sin(j * 0.4 + t * 0.5)))
			var c: Color = [Color(0.4, 1.0, 0.75), Color(0.55, 0.8, 1.0), Color(0.8, 0.6, 1.0)][k]
			for j in band.size():
				cols.append(Color(c.r, c.g, c.b, 0.16 if j < pts.size() else 0.0))
			L.draw_polygon(band, cols)
	# 數字石（彩蛋一）和寶箱
	if v.intersects(Rect2(CHEST - Vector2(500, 400), Vector2(1000, 800))):
		for i in EGG_STONES.size():
			var e: Dictionary = EGG_STONES[i]
			var lit := _has("eggs", "stones") or _egg_seq.has(i)
			var bad := t - _egg_bad_t < 0.9
			var red := bad and fmod(t - _egg_bad_t, 0.3) < 0.18
			var fill := Color("e0505e") if red else (Color("f5c84c") if lit else Color("4a4366"))
			var rim := Color("ffb0b8") if red else (Color("ffe7a3") if lit else Color("8d7fb8"))
			blob(L, e.p + Vector2(0, 14), Vector2(56, 20), Color(0, 0, 0, 0.3))
			if lit or red:
				blob(L, e.p, Vector2(80, 80), Color(fill.r, fill.g, fill.b, 0.3))
			UITheme.dot(L, e.p, 44.0, fill)
			L.draw_arc(e.p, 44.0, 0, TAU, 40, rim, 4.0, true)
			MathLabel.draw_on(L, font, e.p.x, e.p.y + 11.0, e.t, 32, Color("2a2440") if (lit or red) else Color("e4d8ff"))
		if _egg_seq.size() == EGG_STONES.size() or _has("eggs", "stones"):
			var opened := _has("eggs", "stones")
			blob(L, CHEST, Vector2(110, 110), Color(1.0, 0.85, 0.4, 0.25 + 0.1 * sin(t * 3.0)))
			L.draw_rect(Rect2(CHEST + Vector2(-40, -22), Vector2(80, 48)), Color("9a6a32"))
			L.draw_rect(Rect2(CHEST + Vector2(-40, -22 - (20 if opened else 0)), Vector2(80, 18)), Color("c98a3e"))
			L.draw_rect(Rect2(CHEST + Vector2(-40, -22), Vector2(80, 48)), Color("f5c84c"), false, 3.0)
	# 石碑解開了會發光；攤車上的問號
	if _has("eggs", "fib") and v.has_point(STELE):
		blob(L, STELE + Vector2(0, -150), Vector2(130, 170), Color(1.0, 0.6, 0.85, 0.22 + 0.08 * sin(t * 2.0)))
	if not _has("eggs", "dice") and v.has_point(DICE_NPC):
		UITheme.text_ol(L, font, DICE_NPC + Vector2(-140, -120 + sin(t * 3.0) * 6.0), "?", HORIZONTAL_ALIGNMENT_CENTER, 60, 44, Color("ffb35a"), 6)
	# 還沒開放的地區：整片蓋在雲裡
	for i in ZONES.size():
		var z: Dictionary = ZONES[i]
		if _open.has(z.id):
			continue
		var cl: Array = z.cloud
		if not v.intersects(Rect2(cl[0] - Vector2(cl[1], cl[2]) * 1.2, Vector2(cl[1], cl[2]) * 2.4)):
			continue
		_draw_cloud(L, z, i)
	# 靠近的大門發光
	if String(_near.get("kind", "")) == "zone":
		var zg: Vector2 = ZONES[int(_near.i)].gate
		var zc: Color = ZONES[int(_near.i)].color
		blob(L, zg + Vector2(0, -60), Vector2(200, 160), Color(zc.r, zc.g, zc.b, 0.18 + 0.08 * sin(t * 4.0)))
	# 點亮動畫：從地區中心擴散出去的光圈和往上冒的光點
	for b in _light_bursts():
		var box: Rect2 = b.box
		var f: float = b.f
		var c := box.get_center()
		var zc: Color = _zone_of(String(b.key)).get("color", Color.WHITE)
		var big := maxf(box.size.x, box.size.y) * 0.75
		blob(L, c, Vector2(big, big * 0.75) * (0.4 + 0.6 * f), Color(1.0, 0.95, 0.75, 0.3 * sin(f * PI)))
		for k in 3:
			var ph := clampf(f * 1.4 - k * 0.2, 0.0, 1.0)
			if ph > 0.0 and ph < 1.0:
				L.draw_arc(c, 80.0 + ph * big, 0, TAU, 64, Color(zc.r, zc.g, zc.b, 0.5 * (1.0 - ph)), 6.0, true)
		for j in 14:
			var ph := fmod(f * 2.0 + j * 0.071, 1.0)
			var q := c + Vector2(sin(j * 2.4) * box.size.x * 0.35, cos(j * 1.7) * box.size.y * 0.3 - ph * 220.0)
			_dot(L, q, 6.0, Color(1.0, 0.95, 0.7, sin(f * PI) * (1.0 - ph)), 32)
	# 光靈
	for p in _trail:
		_dot(L, p.p, 4.5 * (1.0 - p.life / 0.8), Color(1.0, 0.92, 0.6, 0.7 * (1.0 - p.life / 0.8)), 32)
	var bob := sin(t * (9.0 if walking else 3.0)) * (4.0 if walking else 3.0)
	blob(L, pos + Vector2(0, 22), Vector2(30, 11), Color(0, 0, 0, 0.35))
	blob(L, pos + Vector2(0, -6), Vector2(70, 70), Color(1.0, 0.95, 0.7, 0.15))
	if absf(face.x) > 0.2:
		_face_left = face.x < 0.0
	L.draw_set_transform(pos + Vector2(0, bob - 10.0), 0.0, Vector2(-1.0 if _face_left else 1.0, 1.0))
	SL.draw_all(L, Vector2.ZERO, SPIRIT_R, Game.of(self).equipped, t)
	L.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 一個地區自己的動態（畫在那個地區的動態層上，照點亮程度調淡）
func _p_zone_fx(L, id: String, v: Rect2) -> void:
	if not _open.has(id):
		return
	# 沒點亮的地區連時間都走得慢（風車、水流、光束都慢吞吞的）
	var t_real := t
	t = light_time(id)
	_zone_fx_body(L, id, v)
	t = t_real


func _zone_fx_body(L, id: String, v: Rect2) -> void:
	match id:
		"num":
			# 風車的葉片
			var hub := WINDMILL + Vector2(0, -300)
			if v.has_point(hub):
				var rot := t * 0.6
				for k in 4:
					var a := rot + k * PI / 2.0
					var d := Vector2.from_angle(a)
					var n := d.orthogonal()
					L.draw_line(hub, hub + d * 230.0, Color("6a4630"), 8.0, true)
					L.draw_colored_polygon(PackedVector2Array([hub + d * 50.0, hub + d * 230.0, hub + d * 230.0 + n * 46.0, hub + d * 50.0 + n * 36.0]), Color(0.96, 0.92, 0.82, 0.92))
					for j in 4:
						var s := 0.3 + j * 0.2
						L.draw_line(hub + d * (230.0 * s), hub + d * (230.0 * s) + n * (36.0 + 10.0 * s), Color("8a6a46"), 2.0)
				_dot(L, hub, 16.0, Color("5a3d2c"), 32)
		"exp":
			# 倍增峽谷上空的熱氣球
			var bl := CANYON_C + Vector2(sin(t * 0.2) * 260.0, -260 + sin(t * 0.9) * 18.0)
			if v.has_point(bl):
				blob(L, bl + Vector2(0, 330), Vector2(60, 18), Color(0, 0, 0, 0.18))
				L.draw_colored_polygon(_ell(bl, 64, 76, 32), Color("e0763f"))
				L.draw_colored_polygon(_ell(bl, 30, 76, 24), Color("f5c84c"))
				L.draw_line(bl + Vector2(-34, 60), bl + Vector2(-14, 110), Color("5a3a22"), 2.0)
				L.draw_line(bl + Vector2(34, 60), bl + Vector2(14, 110), Color("5a3a22"), 2.0)
				L.draw_rect(Rect2(bl + Vector2(-18, 106), Vector2(36, 26)), Color("8a5a36"))
		"line":
			# 圓規湖的漣漪和晨光
			if v.intersects(Rect2(LAKE_C - Vector2(LAKE_R, LAKE_R), Vector2(LAKE_R, LAKE_R) * 2.0)):
				for k in 3:
					var rr := fmod(t * 34.0 + k * 120.0, LAKE_R - 30.0)
					L.draw_arc(LAKE_C, rr, 0, TAU, 64, Color(0.8, 0.92, 1.0, 0.22 * (1.0 - rr / LAKE_R)), 3.0, true)
				blob(L, LAKE_C + Vector2(-120 + sin(t * 0.5) * 10.0, -140), Vector2(90, 30), Color(1.0, 0.95, 0.8, 0.35 + 0.15 * sin(t * 2.0)))
				var bt := LAKE_C + Vector2(140 + sin(t * 0.3) * 60.0, 60 + sin(t * 0.7) * 6.0)
				L.draw_colored_polygon(PackedVector2Array([bt + Vector2(-34, 0), bt + Vector2(34, 0), bt + Vector2(24, 14), bt + Vector2(-24, 14)]), Color("a8743e"))
				L.draw_line(bt, bt + Vector2(0, -46), Color("5a3a22"), 3.0)
				L.draw_colored_polygon(PackedVector2Array([bt + Vector2(2, -44), bt + Vector2(30, -6), bt + Vector2(2, -6)]), Color("fff4e0"))
		"poly":
			# 洞口水晶和軌道邊的燈
			if v.intersects(Rect2(HILL_C - Vector2(400, 400), Vector2(800, 900))):
				blob(L, HILL_C + Vector2(0, 220), Vector2(190, 150), Color(0.75, 0.6, 1.0, 0.18 + 0.08 * sin(t * 2.0)))
				var g3: Vector2 = ZONES[3].gate
				for k in 3:
					var lp := Vector2(HILL_C.x + (60 if k % 2 == 0 else -60), lerpf(HILL_C.y + 300, g3.y - 60, k / 2.0))
					L.draw_line(lp, lp + Vector2(0, -50), Color("5a3a22"), 4.0)
					blob(L, lp + Vector2(0, -56), Vector2(30, 30), Color(1.0, 0.85, 0.5, 0.5 + 0.15 * sin(t * 3.0 + k)))
					_dot(L, lp + Vector2(0, -56), 6.0, Color("ffe7a3"), 32)
		"seq":
			# 階梯瀑布：往下流的水紋、水花、霧
			if v.intersects(Rect2(FALLS_X - 500, 2900, 1000, 1150)):
				var streak := PackedVector2Array()
				for k in 5:
					var y0: float = FALL_T[k] + 8.0
					var hgt: float = FALL_B[k] - y0
					var w: float = FALL_W[k]
					for j in int(w / 16.0):
						var ph := fmod(t * 1.6 + j * 0.37 + k * 0.21, 1.0)
						var xx := FALLS_X - w / 2.0 + 8.0 + j * 16.0
						var sp := (xx - FALLS_X) * 0.12 / hgt
						streak.append_array([Vector2(xx + sp * ph * hgt, y0 + ph * hgt), Vector2(xx + sp * minf(hgt, ph * hgt + 30.0), y0 + minf(hgt, ph * hgt + 30.0))])
					for j in 5:
						var fx := FALLS_X - w / 2.0 - 10.0 + (w + 20.0) * (j + 0.5) / 5.0
						blob(L, Vector2(fx, FALL_B[k] - 4.0), Vector2(w / 3.2, 24), Color(1, 1, 1, 0.4 + 0.18 * sin(t * 4.0 + j * 1.7 + k)))
					blob(L, Vector2(FALLS_X, FALL_B[k] - 30.0), Vector2(w * 0.9, 40), Color(0.85, 0.95, 1.0, 0.12 + 0.05 * sin(t * 2.0 + k)))
				L.draw_multiline(streak, Color(1, 1, 1, 0.55), 3.0)
				blob(L, Vector2(FALLS_X, 2990), Vector2(90, 30), Color(0.7, 0.95, 1.0, 0.25 + 0.1 * sin(t * 2.5)))
				for k in 6:
					var ph := fmod(t * 0.22 + k / 6.0, 1.0)
					blob(L, FALL_POOL + Vector2(sin(k * 2.3) * 140.0, -40.0 - ph * 200.0), Vector2(170, 70) * (0.7 + ph), Color(0.8, 0.9, 1.0, 0.24 * (1.0 - ph)))
				for k in 3:
					var ph := fmod(t * 0.4 + k / 3.0, 1.0)
					L.draw_arc(FALL_POOL + Vector2(0, -10), 40.0 + ph * 200.0, 0.0, TAU, 40, Color(0.8, 0.92, 1.0, 0.25 * (1.0 - ph)), 3.0, true)
				L.draw_arc(FALL_POOL + Vector2(0, 40), 270.0, PI * 1.15, PI * 1.85, 32, Color(0.75, 0.85, 1.0, 0.15), 14.0, true)       # 月虹
		"data":
			# 觀測台：望遠鏡慢慢轉、地燈一閃一閃
			if v.intersects(Rect2(DOME_C - Vector2(700, 500), Vector2(1400, 1000))):
				var piv := DOME_C + Vector2(0, -120)
				var a := -PI / 2.0 + 0.5 * sin(t * 0.25)
				var d := Vector2.from_angle(a)
				var n := d.orthogonal()
				L.draw_colored_polygon(PackedVector2Array([piv + n * 16.0, piv - n * 16.0, piv + d * 170.0 - n * 22.0, piv + d * 170.0 + n * 22.0]), Color("c8b070"))
				L.draw_colored_polygon(PackedVector2Array([piv + n * 4.0, piv - n * 6.0, piv + d * 170.0 - n * 8.0, piv + d * 170.0 + n * 6.0]), Color("f2dca0"))
				_dot(L, piv + d * 172.0, 20.0, Color("3a3a4a"), 32)
				var lights := _dome_lights()
				for k in lights.size():
					var q: Vector2 = lights[k]
					blob(L, q, Vector2(30, 30), Color(0.6, 0.85, 1.0, 0.4 + 0.3 * sin(t * 2.0 + k)))
					_dot(L, q, 5.0, Color("e6f7ff"), 32)
				for k in lights.size() - 1:
					if k % 2 == 0:
						L.draw_line(lights[k], lights[k + 1], Color(0.62, 0.85, 1.0, 0.25), 3.0, true)
		"comb":
			# 噴水池的水柱
			if v.has_point(FOUNTAIN):
				var jets := PackedVector2Array()
				for k in 10:
					var a := TAU * k / 10.0 + t * 0.4
					var ph := fmod(t * 1.2 + k * 0.1, 1.0)
					var top := FOUNTAIN + Vector2(0, -78)
					var tip := top + Vector2(cos(a) * 70.0 * ph, sin(a) * 30.0 * ph - 60.0 * sin(ph * PI))
					jets.append_array([top, tip])
					_dot(L, tip, 4.0, Color(0.85, 0.95, 1.0, 0.9 * (1.0 - ph)), 32)
				L.draw_multiline(jets, Color(0.8, 0.92, 1.0, 0.45), 3.0)
		"prob":
			# 市集的燈串
			if v.intersects(Rect2(MARKET_C - Vector2(600, 500), Vector2(1200, 900))):
				for k in TENTS.size():
					var a: Vector2 = TENTS[k] + Vector2(0, -190)
					var b := MARKET_C + Vector2(0, -260)
					var pts := _sag(a, b, 40.0)
					for j in pts.size():
						var bc: Color = [Color("ffd36e"), Color("ff9ad5"), Color("8fd0ff")][(j + k) % 3]
						var on := 0.55 + 0.45 * sin(t * 3.0 + j * 1.3 + k)
						blob(L, pts[j], Vector2(14, 14), Color(bc.r, bc.g, bc.b, 0.45 * on))
						_dot(L, pts[j], 4.0, bc.lightened(0.3 * on), 32)
		"trig":
			# 燈塔的光束
			var lamp := LIGHTHOUSE + Vector2(0, -664)
			if v.grow(1400.0).has_point(lamp):
				var rot := t * 0.7
				for k in 2:
					var a := rot + k * PI
					var d := Vector2.from_angle(a)
					var n := d.orthogonal()
					L.draw_polygon(PackedVector2Array([lamp, lamp + d * 1500.0 + n * 260.0, lamp + d * 1500.0 - n * 260.0]),
						PackedColorArray([Color(1.0, 0.96, 0.7, 0.42), Color(1.0, 0.96, 0.7, 0.0), Color(1.0, 0.96, 0.7, 0.0)]))
				blob(L, lamp, Vector2(120, 120), Color(1.0, 0.95, 0.65, 0.5 + 0.2 * sin(t * 4.0)))
				# 岩石邊的浪
				for k in 6:
					var ph := fmod(t * 0.5 + k / 6.0, 1.0)
					var wp := LIGHTHOUSE + Vector2(340, 40 + k * 40)
					blob(L, wp + Vector2(-ph * 60.0, 0), Vector2(60, 18) * (0.6 + ph), Color(1, 1, 1, 0.4 * (1.0 - ph)))


## 還沒點亮的地區：壓一層暗影（點亮越多越淡）
func _p_gloom(L) -> void:
	var v := _view().grow(200.0)
	for z in ZONES:
		var id: String = z.id
		if not _open.has(id):
			continue
		var dk := 1.0 - light_e(id)
		if dk < 0.02:
			continue
		var cl: Array = z.cloud
		var r := Vector2(cl[1], cl[2]) * 1.25
		if not v.intersects(Rect2((cl[0] as Vector2) - r, r * 2.0)):
			continue
		blob(L, cl[0], r, Color(0.04, 0.05, 0.12, 0.62 * dk))
		for k in 3:
			var ph: float = float(k) * 2.1 + float(z.center.x) * 0.001
			var p: Vector2 = (cl[0] as Vector2) + Vector2(sin(t * 0.05 + ph) * r.x * 0.3, cos(t * 0.04 + ph) * r.y * 0.25)
			blob(L, p, r * 0.6, Color(0.05, 0.06, 0.13, 0.18 * dk))

## 一個地區上方的雲：一大團不透明的雲，邊緣是一圈慢慢飄動的雲朵（西邊染著晨光的桃色、東邊是夜晚的藍灰色）
func _draw_cloud(L, z: Dictionary, i: int) -> void:
	var cl: Array = z.cloud
	var c: Vector2 = cl[0]
	var rx: float = cl[1]
	var ry: float = cl[2]
	var east := i >= LEFT_ZONES
	var base := Color(0.95, 0.9, 0.92) if not east else Color(0.66, 0.72, 0.88)
	var shade := Color(0.8, 0.68, 0.76) if not east else Color(0.4, 0.46, 0.64)
	var pr := minf(rx, ry) * 0.26
	blob(L, c + Vector2(60, 120), Vector2(rx, ry) * 1.15, Color(0, 0, 0, 0.28))
	# 雲的底（陰影）→ 一圈雲朵的陰影 → 不透明的雲心 → 一圈雲朵 → 亮面
	L.draw_colored_polygon(_ell(c + Vector2(0, 24), rx * 0.86, ry * 0.86, 48), shade)
	var n := 22
	for pass_i in 2:
		for k in n:
			var a := TAU * k / n + i * 0.7
			var wob := 0.84 + 0.06 * sin(k * 2.3 + i)
			var p := c + Vector2(cos(a) * rx, sin(a) * ry) * wob + Vector2(sin(t * 0.15 + k) * 14.0, cos(t * 0.12 + k) * 10.0)
			var r := pr * (0.85 + 0.3 * absf(sin(k * 1.7 + i)))
			if pass_i == 0:
				_dot(L, p + Vector2(0, 26), r, shade, 128)
			else:
				_dot(L, p, r, base, 128)
	L.draw_colored_polygon(_ell(c, rx * 0.84, ry * 0.84, 48), base)
	# 亮面：四團就好（以前九團疊在一起，雲中間要重複畫六、七層）
	for k in 4:
		var a := TAU * k / 4.0 + t * 0.02 + i
		var p := c + Vector2(cos(a) * rx, sin(a) * ry) * 0.42 + Vector2(-rx * 0.08, -ry * 0.12)
		blob(L, p, Vector2(rx, ry) * 0.44, Color(1, 1, 1, 0.55) if not east else Color(0.88, 0.92, 1.0, 0.45))
	var font := UITheme.bold_font()
	UITheme.text_ol(L, font, c + Vector2(-400, -6), z.name, HORIZONTAL_ALIGNMENT_CENTER, 800, 72, Color(1, 1, 1, 0.95), 12)
	UITheme.text_ol(L, font, c + Vector2(-400, 66), "雲霧籠罩・準備中", HORIZONTAL_ALIGNMENT_CENTER, 800, 36, Color(1, 1, 1, 0.8), 8)


# ================= 螢幕上的東西（小地圖、主線、搖桿、飄落的葉子、晨光） =================

func _p_hud(L) -> void:
	var font := UITheme.bold_font()
	var v := _view()
	var left_k := clampf((MID_X - v.get_center().x) / 1200.0 + 0.5, 0.0, 1.0)     # 鏡頭在西岸的程度
	# 晨光：從左上斜斜照下來的光束
	if left_k > 0.01:
		for k in 4:
			var x0 := -200.0 + k * 300.0 + sin(t * 0.2 + k) * 30.0
			L.draw_polygon(PackedVector2Array([Vector2(x0, -10), Vector2(x0 + 120, -10), Vector2(x0 + 520, H + 10), Vector2(x0 + 300, H + 10)]),
				PackedColorArray([Color(1, 0.88, 0.6, 0.07 * left_k), Color(1, 0.88, 0.6, 0.07 * left_k), Color(1, 0.88, 0.6, 0.0), Color(1, 0.88, 0.6, 0.0)]))
		for lf in _leaves:
			var d := Vector2.from_angle(lf.r) * 7.0
			var n := d.orthogonal() * 0.5
			var c: Color = lf.c
			L.draw_colored_polygon(PackedVector2Array([lf.p - d, lf.p + n, lf.p + d, lf.p - n]), Color(c.r, c.g, c.b, 0.85 * left_k))
	# 星夜：畫面上方的星星
	if left_k < 0.99:
		var rng := RandomNumberGenerator.new()
		rng.seed = 99
		for k in 60:
			var p := Vector2(rng.randf() * W, rng.randf() * H)
			var a := (0.2 + 0.3 * sin(t * rng.randf_range(1.0, 2.5) + k)) * (1.0 - left_k)
			_dot(L, p, rng.randf_range(1.0, 2.2), Color(0.9, 0.95, 1.0, maxf(0.0, a)), 16)
	# 邊緣暗一點（聚焦在中間）
	for k in 4:
		var w := 60.0 - k * 14.0
		var a := 0.06
		L.draw_rect(Rect2(0, 0, W, w), Color(0, 0, 0.05, a))
		L.draw_rect(Rect2(0, H - w, W, w), Color(0, 0, 0.05, a))
	_draw_minimap(L, font)
	if not frozen() and _goal_text != "":
		var tp := Vector2(-1, -1)
		if _goal_pt.x >= 0.0:
			var C := Vector2(W, H) / 2.0
			tp = C - (cam + C) * zoom + _goal_pt * zoom
		var mm := 210.0 * WORLD.y / WORLD.x
		WS.draw_goal(L, _goal_text, tp, t, Rect2(W - 18 - 210 - 4, 66, 218, mm + 8))
	_draw_joy(L, font)
	var label := "曦光大陸 · 秋晨之地（高一上）" if pos.x < MID_X else "曦光大陸 · 星夜之地（高一下）"
	UITheme.text_ol(L, font, Vector2(20, 142), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffd9a8") if pos.x < MID_X else Color("9fd8ff"), 6)


func _draw_joy(L, font: Font) -> void:
	if frozen():
		return
	if _hold:
		UITheme.dot(L, _joy_base, JOY_R + 6.0, Color(0.05, 0.08, 0.2, 0.35))
		L.draw_arc(_joy_base, JOY_R, 0, TAU, 48, Color(1, 1, 1, 0.45), 3.0, true)
		for k in 4:
			var a := k * PI / 2.0
			var tip := _joy_base + Vector2.from_angle(a) * (JOY_R - 12.0)
			L.draw_colored_polygon(PackedVector2Array([tip + Vector2.from_angle(a) * 6.0, tip + Vector2.from_angle(a + 2.3) * 6.0,
				tip + Vector2.from_angle(a - 2.3) * 6.0]), Color(1, 1, 1, 0.4))
		UITheme.dot(L, _hold_pt, 30.0, Color(1, 0.9, 0.55, 0.85))
		UITheme.dot(L, _hold_pt + Vector2(-6, -6), 12.0, Color(1, 1, 1, 0.45))
	else:
		var c := Vector2(110, H - 120)
		L.draw_arc(c, 42.0, 0, TAU, 40, Color(1, 1, 1, 0.16), 2.0, true)
		UITheme.dot(L, c, 18.0, Color(1, 1, 1, 0.14))
		L.draw_string(font, c + Vector2(-70, 66), "按住左半邊移動", HORIZONTAL_ALIGNMENT_CENTER, 140, 13, Color(1, 1, 1, 0.35))


var _mini_cache := {}

func _draw_minimap(L, _font: Font) -> void:
	var mw := 210.0
	var k := mw / WORLD.x
	var mh := WORLD.y * k
	var o := Vector2(W - 18 - mw, 70)
	L.draw_rect(Rect2(o - Vector2(4, 4), Vector2(mw + 8, mh + 8)), Color(0.04, 0.05, 0.12, 0.85))
	if _mini_cache.is_empty():
		for key in ["l", "r"]:
			var src: PackedVector2Array = _left_poly if key == "l" else _right_poly
			var dst := PackedVector2Array()
			for q in src:
				dst.append(o + q * k)
			_mini_cache[key] = dst
		var rv := PackedVector2Array()
		for q in _river:
			rv.append(o + q * k)
		_mini_cache["river"] = rv
	L.draw_colored_polygon(_mini_cache.l, Color("7a7a48"))
	L.draw_colored_polygon(_mini_cache.r, Color("24486a"))
	L.draw_polyline(_mini_cache.river, Color("2a73a8"), 3.0)
	for z in ZONES:
		var zc: Vector2 = o + (z.center as Vector2) * k
		if _open.has(z.id):
			UITheme.dot(L, zc, 5.0, Color(0.42, 0.44, 0.52).lerp(z.color, light_e(z.id)))     # 還沒點亮的地區：灰的
		else:
			UITheme.dot(L, zc, 7.0, Color(0.9, 0.9, 0.95, 0.55))
	UITheme.dot(L, o + HOUSE * k, 3.5, Color("ffb87a"))
	L.draw_rect(Rect2(o + _view().position * k, _view().size * k), Color(1, 1, 1, 0.5), false, 1.0)
	UITheme.dot(L, o + pos * k, 3.5 + sin(t * 4.0), Color("fff3c4"))
	L.draw_rect(Rect2(o - Vector2(4, 4), Vector2(mw + 8, mh + 8)), Color(1, 1, 1, 0.2), false, 1.0)


# ================= 主線故事、教學引導 =================

func focus_point(name: String, uid: String) -> Vector2:
	match name:
		"wide":
			return WORLD / 2.0
		"house":
			return HOUSE
		"zones":
			return Vector2(2300, 2100)
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
		 "text": UITheme.kb("這是我！用方向鍵或 WASD 走路，或在左半邊按住拖曳。", "這是我！在左半邊按住拖曳就能走路。")},
		{"rect": func(): return _goal_rect(),
		 "text": "金色橫幅是下一步目標，箭頭指出方向。點橫幅可改段考範圍。"},
		{"rect": func(): return _scr(ZONES[3].gate + Vector2(0, -120), Vector2(90, 110)),
		 "text": UITheme.kb("走到地區大門前，按 Enter 或「進入」。被雲蓋住的還在準備中。", "走到地區大門前，按「進入」。被雲蓋住的還在準備中。")},
		{"rect": func(): return _tp_btn.get_global_rect(),
		 "text": UITheme.kb("不想走路？按「單元列表」（M）直接選。", "不想走路？按「單元列表」直接選。")},
		{"rect": func(): return _scr(HOUSE + Vector2(0, -80), Vector2(110, 110)),
		 "text": "這是我們的小屋：擺家具、看紀念品、接每日任務。"},
		{"rect": func(): return Rect2(W - 18 - 210, 14, 210, 44),
		 "text": "右上角切換高一、高二地圖。出發吧！"},
	]


## 螢幕上的一塊（地圖座標 → 螢幕）；整塊不在畫面上就回傳空的（教學會跳過那一句）
func _scr(p: Vector2, half: Vector2) -> Rect2:
	var C := Vector2(W, H) / 2.0
	var sp := C - (cam + C) * zoom + p * zoom
	var r := Rect2(sp - half * zoom / BASE_ZOOM * 0.75, half * 2.0 * zoom / BASE_ZOOM * 0.75)
	return r if Rect2(0, 0, W, H).encloses(r) else Rect2()
