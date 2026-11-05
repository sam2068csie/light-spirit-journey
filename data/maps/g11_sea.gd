extends "res://data/maps/world_base.gd"
## 高二的「選擇單元」世界地圖：光潮群島。划光舟在海上自由航行，一個單元一座島。
##   ・北邊（高二上：三角、指對數、平面向量）是黃昏的海：金色的夕陽光帶、海鷗、鯨魚
##     南邊（高二下：空間向量、平面與直線、條件機率、矩陣）是深夜的海：極光、會發光的浮游生物、水母、鬼蝠魟
##   ・每座島的地形藏著它的數學（不寫算式）：
##     月輪島＝圓環環礁與正弦海岸　指數對數雙島＝隔著鏡面海峽互為倒影　箭羽高原＝平行四邊形的田、箭形石碑
##     立方浮島＝浮在空中的方塊、三根互相垂直的水晶　平面峽灣＝兩道平直的岩壁交成一條線、纜車穿過岩壁
##     機率樹海＝一路分岔的巨樹（樹狀圖）　矩陣城＝排成行與列的街區與運河
##   ・還沒開放的島整座藏在海霧裡（霧擋住航行），碼頭和浮標留在霧外
##   ・開放的島一開始是暗的、灰灰冷冷的（世界之光還沒點亮），聖地越點越亮；全部點亮才恢復原本的色彩和島上的動態
##   ・靠近碼頭跳出靠岸卡片，「上岸」進入原本的單元地圖；從單元地圖返回，光舟停在那座島的碼頭旁
##   ・海上的彩蛋：沉船（對數）、漩渦（弧度）、瓶中信（向量的長度）；還有背著小島的海龜
## 存檔：Game.world11 {pos: [x, y], visited: [], eggs: [], ret: 上岸時記下的單元, v2: 地圖放大後的座標}
const Center := preload("res://data/core/review_center.gd")
const TM := preload("res://data/maps/trig_map.gd")     # 月輪島：照單元地圖的形狀放大（圓環＋正弦海岸＋羅盤礁）
const EM := preload("res://data/maps/exp_map.gd")     # 指數島、對數島：照單元地圖的海岸線放大
const GW := preload("res://data/maps/g10_world.gd")   # 共用的幾何工具（圓滑、外擴、切環）
const MapLayer := preload("res://data/maps/map_layer.gd")

const WORLD := Vector2(7200, 4400)
const SEA_C := Vector2(3700, 2240)
const BASE_ZOOM := 0.62
const WIDE_ZOOM := 0.16
const SPEED := 620.0
const R_BOAT := 30.0
const DUSK_Y := 2240.0          # 黃昏和深夜的交界（南北之間慢慢變暗）
const LAND_K := 1.5             # 月輪島、雙島：陸地比單元地圖寬一點，大地圖上才看得清楚

## 七座島（章節順序）：unit 對應 units.gd 的單元 id；night：在深夜的那一半
const ISLANDS := [
	{"n": 1, "unit": "trig", "name": "月輪島", "c": Vector2(1500, 900), "r": Vector2(1000, 560), "col": Color("ff9ad5"), "night": false},
	{"n": 2, "unit": "exp", "name": "指數對數雙島", "c": Vector2(3840, 820), "r": Vector2(880, 500), "col": Color("f5c84c"), "night": false},
	{"n": 3, "unit": "vec2", "name": "箭羽高原", "c": Vector2(6060, 900), "r": Vector2(780, 470), "col": Color("5fd4ff"), "night": false},
	{"n": 4, "unit": "vec3", "name": "立方浮島", "c": Vector2(6150, 2640), "r": Vector2(620, 420), "col": Color("c59bff"), "night": true},
	{"n": 5, "unit": "plane", "name": "平面峽灣", "c": Vector2(5900, 3700), "r": Vector2(860, 430), "col": Color("6ee7a0"), "night": true},
	{"n": 6, "unit": "prob", "name": "機率樹海", "c": Vector2(3700, 3720), "r": Vector2(820, 440), "col": Color("ffb35a"), "night": true},
	{"n": 7, "unit": "matrix", "name": "矩陣城", "c": Vector2(1450, 3560), "r": Vector2(760, 460), "col": Color("8fb4ff"), "night": true},
]
const HARBOR := Vector2(150, 2240)       # 晨曦港（西邊的岬角，剛好在黃昏與深夜的交界）
const PIER := Rect2(470, 2200, 170, 64)  # 港口的木棧橋
const FERRY := Vector2(560, 2380)        # 停在港口的渡船（從高一的渡口開過來的那一艘）
const SPAWN := Vector2(760, 2240)
const WRECK := Vector2(2480, 2380)       # 彩蛋：沉船（對數）
const WHIRL := Vector2(4980, 2300)       # 彩蛋：漩渦（弧度）
const BOTTLE := Vector2(2960, 1720)      # 彩蛋：瓶中信（向量的長度）
const TURTLE_C := Vector2(3720, 2250)    # 背著小島的海龜繞著海中央慢慢游
const TURTLE_R := Vector2(560, 330)

var vel := Vector2.ZERO
var heading := 0.0
var _shape: Array = []        # 每座島：{kind, lands: [多邊形], blk: [加寬的碰撞多邊形], box, …}
var _docks: Array = []
var _shores: Array = []       # 碼頭的棧橋接到岸邊的那一點
var _fog: Array = []          # 每座島的海霧橢圓 [中心, rx, ry]
var _open := {}
var _seen_open := ""
var debug_open := false       # 截圖用：霧全部散開
var _wake: Array = []
var _card: PanelContainer
var _card_no: Label
var _card_title: Label
var _card_sub: Label
var _card_bar: ProgressBar
var _card_btn: Button
var _fade: ColorRect
var _tp: Button
var _zoom_hold := 0.0     # 離島動畫播放中，先不要自動縮放
var _zoom_lock := false
var _whirl_spin := 0.0
var _wall_t := -10.0
var _save_t := 0.0
var _root: Node2D
var _pieces: Array = []
var _fx: MapLayer
var _hud: MapLayer
var _harbor_poly := PackedVector2Array()
var _harbor_blk := PackedVector2Array()
var _rng_seed := 2026
# 海上的生物（_ready 時決定位置，fx 每幀照時間算出現在在哪）
var _schools: Array = []
var _jellies: Array = []
var _plankton_grid := {}     # 1000×1000 一格（只算畫面附近那幾格）
var _stars: Array = []
var _coast: Array = []        # 每座島的海岸取樣 [[點, 往外的法向量], …]（浪花用）
var _sea_pt := {}


func _init() -> void:
	pos = SPAWN
	zoom = BASE_ZOOM


func _world_key() -> String:
	return "g11"


func _grade_name() -> String:
	return "高二"


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_refresh_open()
	_build_harbor()
	for i in ISLANDS.size():
		_shape.append(_make_shape(i))
	for i in ISLANDS.size():
		var isl: Dictionary = ISLANDS[i]
		var b: Rect2 = _shape[i].box
		_fog.append([b.get_center(), b.size.x / 2.0 + 150.0, b.size.y / 2.0 + 140.0])
	_find_docks()
	_build_life()
	_build_layers()
	_build_ui()
	var st := _state()
	# 舊存檔（地圖放大之前）的位置換成新的座標
	if not st.has("v2"):
		st["v2"] = true
		var sp0 = st.get("pos", [])
		if sp0 is Array and sp0.size() == 2:
			st["pos"] = [int(sp0[0]) * 2, int(sp0[1]) * 2]
	var sp = st.get("pos", [])
	if sp is Array and sp.size() == 2:
		var p0 := Vector2(float(sp[0]), float(sp[1]))
		if _free(p0):
			pos = p0
	# 從單元地圖回來：光舟停在那座島的碼頭旁，播離島動畫
	var ret := String(st.get("ret", ""))
	if ret != "":
		for i in ISLANDS.size():
			if ISLANDS[i].unit == ret:
				pos = _docks[i]
				heading = (_docks[i] - _shores[i]).angle()
		st["ret"] = ""
		zoom = BASE_ZOOM * 1.8
		_fade.color.a = 1.0
		_zoom_lock = true
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "zoom", BASE_ZOOM, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_fade, "color:a", 0.0, 0.6)
		tw.chain().tween_callback(func(): _zoom_lock = false)
		vel = Vector2.from_angle(heading) * 220.0
	cam = _cam_target()
	_place_root()
	_refresh_goal()
	_story_check.call_deferred()


func _state() -> Dictionary:
	var g = Game.of(self)
	for k in ["visited", "eggs"]:
		if not g.world11.has(k):
			g.world11[k] = []
	return g.world11


func on_shown() -> void:
	_apply_light()
	queue_redraw()


# ---------- 點亮（共用的做法在 world_base.gd；這裡告訴它有哪些島） ----------

func _light_keys() -> Array:
	var out := []
	for isl in ISLANDS:
		out.append(String(isl.unit))
	return out


func _light_target(key: String) -> float:
	return float(_progress(key).p)


func _light_box(key: String) -> Rect2:
	for i in ISLANDS.size():
		if String(ISLANDS[i].unit) == key:
			return _shape[i].box
	return Rect2()


func _light_name(key: String) -> String:
	for isl in ISLANDS:
		if String(isl.unit) == key:
			return String(isl.name)
	return ""


func _exit_tree() -> void:
	_save()


func _refresh_open() -> void:
	_open = {}
	for i in ISLANDS.size():
		if debug_open or _unit_open(i):
			_open[ISLANDS[i].unit] = true


func _unit_open(i: int) -> bool:
	var u: Dictionary = Units.unit(ISLANDS[i].unit)
	return u.id == ISLANDS[i].unit and Units.is_open(u)


func _open_i(i: int) -> bool:
	return _open.has(ISLANDS[i].unit)


# ================= 形狀 =================

## 晨曦港：從西邊伸出來的岬角
func _build_harbor() -> void:
	var pts := []
	for q in [[-120, -330], [60, -300], [190, -230], [300, -120], [360, 0], [310, 120], [200, 230], [60, 300], [-120, 330]]:
		pts.append(HARBOR + Vector2(q[0], q[1]))
	_harbor_poly = GW._smooth(pts, 6)
	_harbor_blk = GW._off(_harbor_poly, R_BOAT + 6.0)


## 一座島的形狀：月輪島、雙島照單元地圖放大；其他照各自的地標設計
func _make_shape(i: int) -> Dictionary:
	var isl: Dictionary = ISLANDS[i]
	var c: Vector2 = isl.c
	var r: Vector2 = isl.r
	var sh := {"kind": String(isl.unit), "lands": [], "blk": []}
	match String(isl.unit):
		"trig":
			var lo := Vector2(TM.O.x - TM.R - TM.RW, TM.WY - TM.R - TM.RW)
			var hi := Vector2(TM.X_END, TM.WY + TM.R + TM.RW)
			var k: float = minf(2.0 * r.x / (hi.x - lo.x), 2.0 * r.y / (hi.y - lo.y)) * 1.15
			var mid := (lo + hi) / 2.0
			var tf := func(q: Vector2) -> Vector2: return c + (q - mid) * k
			var band := PackedVector2Array()
			for q in TM.coast_band(TM.WX0, TM.X_END, TM.CW / 2.0 * LAND_K):
				band.append(tf.call(q))
			var wave := PackedVector2Array()
			for q in TM.wave_pts(TM.WX0, TM.X_END, 10.0):
				wave.append(tf.call(q))
			var sites := []
			for j in TM.SITES.size():
				sites.append(tf.call(TM.site_point(j)))
			var o: Vector2 = tf.call(TM.O)
			var cp: Vector2 = tf.call(TM.CP)
			sh.merge({"k": k, "o": o, "rr": TM.R * k, "rw": TM.RW * k * LAND_K, "wave": wave, "cw": TM.CW * k * LAND_K,
				"cp": cp, "dr": TM.DR * k * 1.15, "sites": sites, "band": band})
			sh.lands = [band]
			sh.blk = [GW._off(band, R_BOAT)]
		"exp":
			var obs := PackedVector2Array()      # 天文台小島（位數望遠鏡）
			for j in 32:
				obs.append(EM.OBS_C + Vector2.from_angle(TAU * j / 32.0) * EM.OBS_R * 1.25)
			var raw := [GW._off(EM.island_poly(0), EM.CW * (LAND_K - 1.0) / 2.0), GW._off(EM.island_poly(1), EM.CW * (LAND_K - 1.0) / 2.0), obs]
			var lo := Vector2(INF, INF)
			var hi := Vector2(-INF, -INF)
			for poly in raw:
				for q in poly:
					lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
					hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
			var k: float = minf(2.0 * r.x / (hi.x - lo.x), 2.0 * r.y / (hi.y - lo.y)) * 1.15
			var mid := (lo + hi) / 2.0
			var tf := func(q: Vector2) -> Vector2: return c + (q - mid) * k
			for poly in raw:
				var pp := PackedVector2Array()
				for q in poly:
					pp.append(tf.call(q))
				sh.lands.append(pp)
				sh.blk.append(GW._off(pp, R_BOAT))
			var sites := []
			for j in 8:
				sites.append(tf.call(EM.site_point(j)))
			sh.merge({"k": k, "sites": sites, "ma": tf.call(EM.MIRROR_A), "mb": tf.call(EM.MIRROR_B), "obs": tf.call(EM.OBS_C),
				"tower": tf.call(EM.TOWER_P), "tf": tf})
		"vec2":
			# 箭羽高原：往東北的箭頭，西南角是兩道箭羽中間夾著缺口
			var q := [[0.98, -0.92], [0.7, -0.42], [0.92, 0.12], [0.62, 0.66], [0.1, 0.86], [-0.42, 0.8], [-0.98, 0.96],
				[-0.66, 0.46], [-1.0, 0.04], [-0.72, -0.5], [-0.2, -0.84], [0.42, -0.9]]
			sh.lands = [_blob(c, r, q, 7, 0.02, 31)]
		"vec3":
			# 立方浮島：底下一座岩石小島（浮在空中的方塊畫在上面）
			var q := [[0.0, -0.62], [0.55, -0.42], [0.72, 0.1], [0.5, 0.58], [-0.1, 0.7], [-0.62, 0.42], [-0.74, -0.12], [-0.46, -0.52]]
			sh.lands = [_blob(c + Vector2(0, 80), r, q, 6, 0.04, 41)]
		"plane":
			# 平面峽灣：從西北邊切進去的峽灣，兩道岩壁是直的，在最裡面交成一條線
			var mouth_a := c + Vector2(-0.86, -0.42) * r
			var mouth_b := c + Vector2(-0.6, 0.12) * r
			var apex := c + Vector2(0.38, -0.05) * r
			var outer := []
			for p in [[-0.6, 0.12], [-0.92, 0.5], [-0.5, 0.92], [0.1, 0.94], [0.66, 0.78], [1.0, 0.3], [0.96, -0.32], [0.6, -0.82], [0.0, -0.96], [-0.52, -0.86], [-0.86, -0.42]]:
				outer.append(c + Vector2(p[0], p[1]) * r)
			var poly := GW._smooth_open(outer, 7)
			poly.append(mouth_a)
			# 峽灣的兩道岩壁（直線）
			for k in range(1, 12):
				poly.append(mouth_a.lerp(apex, k / 12.0))
			poly.append(apex)
			for k in range(1, 12):
				poly.append(apex.lerp(mouth_b, k / 12.0))
			sh.lands = [poly]
			sh.merge({"apex": apex, "ma": mouth_a, "mb": mouth_b})
		"prob":
			var q := [[0.0, -0.95], [0.5, -0.82], [0.92, -0.42], [1.0, 0.12], [0.7, 0.66], [0.22, 0.92], [-0.3, 0.86],
				[-0.78, 0.6], [-1.0, 0.1], [-0.84, -0.46], [-0.42, -0.86]]
			sh.lands = [_blob(c, r, q, 7, 0.05, 61)]
		"matrix":
			# 矩陣城：方方正正的島（圓角），四周是石砌的堤岸
			var q := []
			var rx: float = r.x
			var ry: float = r.y
			var rc := 120.0
			for corner in [[1, 1], [-1, 1], [-1, -1], [1, -1]]:
				var cc := c + Vector2((rx - rc) * corner[0], (ry - rc) * corner[1])
				var a0 := atan2(float(corner[1]), float(corner[0])) - PI / 4.0
				for k in 7:
					var a := a0 + PI / 2.0 * k / 6.0
					q.append(cc + Vector2.from_angle(a) * rc)
			var poly := PackedVector2Array()
			for p in q:
				poly.append(p)
			sh.lands = [poly]
	# 海岸線減點（幾乎在一直線上的點省掉）：三角形少很多，看不出差別
	var simp := []
	for poly in sh.lands:
		simp.append(_simplify(poly, 1.5))
	sh.lands = simp
	if sh.has("band"):
		sh.band = sh.lands[0]
	if sh.blk.is_empty() or sh.kind == "exp" or sh.kind == "trig":
		sh.blk = []
		for poly in sh.lands:
			sh.blk.append(GW._off(poly, R_BOAT))
	var box := Rect2((sh.lands[0] as PackedVector2Array)[0], Vector2.ZERO)
	for poly in sh.lands:
		for q in poly:
			box = box.expand(q)
	if sh.kind == "vec3":
		box = box.merge(Rect2(c + Vector2(-500, -620), Vector2(1000, 760)))
	if sh.kind == "trig":
		var rr: float = sh.rr + sh.rw / 2.0
		box = box.merge(Rect2(sh.o - Vector2(rr, rr), Vector2(rr, rr) * 2.0))
		box = box.merge(Rect2(sh.cp - Vector2(sh.dr, sh.dr), Vector2(sh.dr, sh.dr) * 2.0))
	sh["box"] = box
	sh["bbox"] = []
	for poly in sh.blk:
		var bb := Rect2((poly as PackedVector2Array)[0], Vector2.ZERO)
		for q in poly:
			bb = bb.expand(q)
		sh.bbox.append(bb)
	return sh


## 封閉多邊形減點（Ramer–Douglas–Peucker）
static func _simplify(poly: PackedVector2Array, tol: float) -> PackedVector2Array:
	var n := poly.size()
	if n < 8:
		return poly
	var keep := PackedByteArray()
	keep.resize(n)
	keep.fill(0)
	# 先找離第 0 點最遠的點，切成兩段開放折線
	var far := 0
	var best := -1.0
	for k in n:
		var d := poly[0].distance_squared_to(poly[k])
		if d > best:
			best = d
			far = k
	keep[0] = 1
	keep[far] = 1
	var stack := [[0, far], [far, n]]
	while not stack.is_empty():
		var seg: Array = stack.pop_back()
		var a: int = seg[0]
		var b: int = seg[1]
		var pa := poly[a]
		var pb := poly[b % n]
		var md := -1.0
		var mi := -1
		for k in range(a + 1, b):
			var d := Geometry2D.get_closest_point_to_segment(poly[k], pa, pb).distance_to(poly[k])
			if d > md:
				md = d
				mi = k
		if mi >= 0 and md > tol:
			keep[mi] = 1
			stack.append([a, mi])
			stack.append([mi, b])
	var out := PackedVector2Array()
	for k in n:
		if keep[k] == 1:
			out.append(poly[k])
	return out


## 照幾個控制點（以 r 為單位）圍出圓滑的島，再加一點不規則的起伏
static func _blob(c: Vector2, r: Vector2, q: Array, seg: int, wob: float, seed: int) -> PackedVector2Array:
	var pts := []
	for p in q:
		pts.append(c + Vector2(p[0], p[1]) * r)
	var sm := GW._smooth(pts, seg)
	var out := PackedVector2Array()
	for k in sm.size():
		var p: Vector2 = sm[k]
		var d := (p - c)
		var f := 1.0 + wob * sin(k * 0.7 + seed) + wob * 0.6 * sin(k * 1.9 + seed * 2.0)
		out.append(c + d * f)
	return out


## 碼頭：從島往海中央走，碰到陸地之後第一個船能停的地方（還沒開放的島要在霧外面）
func _find_docks() -> void:
	_docks.clear()
	_shores.clear()
	for i in ISLANDS.size():
		var isl: Dictionary = ISLANDS[i]
		var start: Vector2 = isl.c
		var dir: Vector2 = (SEA_C - start).normalized()
		match String(isl.unit):
			"trig":
				start = _shape[i].o + Vector2(_shape[i].rr, 0).rotated(-0.35)
				dir = Vector2(0.55, 1.0).normalized()
			"exp":
				start = isl.c + Vector2(0, 120)
				dir = Vector2(-0.1, 1.0).normalized()
			"plane":
				# 碼頭在峽灣口外面
				start = (_shape[i].ma + _shape[i].mb) / 2.0 + Vector2(60, -10)
				dir = Vector2(-1.0, -0.15).normalized()
			"vec3":
				dir = Vector2(-1.0, -0.2).normalized()
		var q := start
		var hit := false
		var shore := start
		for k in 800:
			q += dir * 8.0
			var on_land := _on_island(q, i, 0.0)
			if on_land:
				hit = true
				shore = q
			elif hit or k > 60:
				if not hit:
					shore = q
				break
		var dock := shore + dir * 110.0
		# 霧外面
		var fg: Array = _fog[i]
		while not _unit_open(i) and _fog_k(fg, dock) < 1.08:
			dock += dir * 20.0
		_shores.append(shore)
		_docks.append(dock)


## 這一點在第 i 座島的陸地上嗎（m：往外加寬多少）
func _on_island(p: Vector2, i: int, m: float) -> bool:
	var sh: Dictionary = _shape[i]
	if sh.kind == "trig":
		if absf(p.distance_to(sh.o) - sh.rr) < sh.rw / 2.0 + m:
			return true
		if p.distance_to(sh.cp) < sh.dr + m:
			return true
	var polys: Array = sh.blk if m > 0.0 else sh.lands
	for j in polys.size():
		if m > 0.0 and not (sh.bbox[j] as Rect2).has_point(p):
			continue
		if Geometry2D.is_point_in_polygon(p, polys[j]):
			return true
	return false


static func _fog_k(fg: Array, p: Vector2) -> float:
	var d: Vector2 = p - fg[0]
	return sqrt(pow(d.x / float(fg[1]), 2.0) + pow(d.y / float(fg[2]), 2.0))


## 在哪一座還沒開放的島的霧裡（−1：不在）
func _in_fog(p: Vector2) -> int:
	for i in ISLANDS.size():
		if not _open_i(i) and _fog_k(_fog[i], p) < 0.92:
			return i
	return -1


## 船能不能在這裡：在海上（不在島、港口、霧裡），也不能出地圖
func _free(p: Vector2) -> bool:
	if p.x < 80.0 or p.y < 80.0 or p.x > WORLD.x - 80.0 or p.y > WORLD.y - 80.0:
		return false
	if p.x < HARBOR.x + 700.0:
		if Geometry2D.is_point_in_polygon(p, _harbor_blk) or PIER.grow(R_BOAT).has_point(p) or p.distance_to(FERRY) < 120.0 + R_BOAT:
			return false
	if _in_fog(p) >= 0:
		return false
	for i in ISLANDS.size():
		var b: Rect2 = _shape[i].box
		if not b.grow(R_BOAT + 10.0).has_point(p):
			continue
		if _on_island(p, i, R_BOAT):
			return false
	if p.distance_to(_turtle_pos()) < 120.0:
		return false
	if p.distance_to(WRECK + Vector2(-30, 10)) < 110.0:
		return false
	return true


## 海龜現在在哪（繞著海中央慢慢游，一圈約四分鐘）
func _turtle_pos() -> Vector2:
	var a := t * TAU / 240.0
	return TURTLE_C + Vector2(cos(a) * TURTLE_R.x, sin(a) * TURTLE_R.y)


# ================= 介面 =================

func _build_ui() -> void:
	var tp := Button.new()
	_tp = tp
	tp.text = UITheme.kb("☰ 單元列表（M）", "☰ 單元列表")
	tp.focus_mode = Control.FOCUS_NONE
	tp.custom_minimum_size = Vector2(160, 44)
	tp.position = Vector2(16, 70)
	UITheme.button_3d(tp, Color("1f4a6e"), Color("12304a"), Color("c8f0ff"), 16, 4, 14, 4)
	tp.pressed.connect(_open_sail_menu)
	add_child(tp)
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(560, 0)
	_card.visible = false
	add_child(_card)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	_card.add_child(hb)
	_card_no = Label.new()
	_card_no.custom_minimum_size = Vector2(48, 48)
	_card_no.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_no.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card_no.add_theme_font_override("font", UITheme.bold_font())
	_card_no.add_theme_font_size_override("font_size", UITheme.fs(22))
	_card_no.add_theme_color_override("font_color", Color("2a2440"))
	_card_no.add_theme_stylebox_override("normal", UITheme.box(UITheme.ACCENT, 24, Color(0, 0, 0, 0), 0, 0))
	hb.add_child(_card_no)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 3)
	hb.add_child(vb)
	_card_title = Label.new()
	_card_title.add_theme_font_override("font", UITheme.bold_font())
	_card_title.add_theme_font_size_override("font_size", UITheme.fs(22))
	vb.add_child(_card_title)
	_card_sub = Label.new()
	_card_sub.add_theme_font_size_override("font_size", UITheme.fs(14))
	_card_sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	vb.add_child(_card_sub)
	_card_bar = ProgressBar.new()
	_card_bar.show_percentage = false
	_card_bar.max_value = 100
	_card_bar.custom_minimum_size = Vector2(0, 7)
	_card_bar.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.1), 4, Color(0, 0, 0, 0), 0, 0))
	vb.add_child(_card_bar)
	_card_btn = Button.new()
	_card_btn.focus_mode = Control.FOCUS_NONE
	_card_btn.custom_minimum_size = Vector2(120, 50)
	UITheme.accent_button(_card_btn, 17)
	_card_btn.pressed.connect(_interact)
	hb.add_child(_card_btn)
	var tip := Label.new()
	tip.text = UITheme.kb("方向鍵／WASD 划船，或按住左半邊用搖桿　·　Enter 上岸　·　M 單元列表", "按住畫面左半邊，用搖桿划船")
	tip.position = Vector2(18, H - 34)
	tip.add_theme_font_size_override("font_size", UITheme.fs(13))
	tip.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tip)
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(0, 124)
	_toast.size = Vector2(W, 40)
	_toast.add_theme_font_override("font", UITheme.bold_font())
	_toast.add_theme_font_size_override("font_size", UITheme.fs(20))
	_toast.add_theme_color_override("font_color", Color("ffe7a3"))
	_toast.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.12))
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	add_child(_toast)
	# 上岸／離島的轉場：黑幕
	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.04, 0.1, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _progress(uid: String) -> Dictionary:
	var u: Dictionary = Units.unit(uid)
	var lit := 0
	var prog := 0.0
	var nxt := ""
	var g = Game.of(self)
	for l in u.levels:
		var pr: float = Center.level_progress(g, l.id)
		prog += pr
		if pr >= 0.999:
			lit += 1
		elif nxt == "":
			nxt = l.name
	return {"lit": lit, "n": u.levels.size(), "p": prog / maxf(1.0, u.levels.size()), "next": nxt}


const EGGS := {
	"wreck": {"title": "沉船殘骸", "hint": "船艙裡有一本泡水的航海日誌……", "q": "航海日誌最後一頁寫著：\nlog₂ 8 + log₂ 4 = ？",
		"opts": ["5", "6", "12", "32"], "ans": "5", "why": "log₂ 8 = 3、log₂ 4 = 2，合起來是 5。", "gain": 30},
	"whirl": {"title": "海上的漩渦", "hint": "光舟被捲著轉了一圈……", "q": "光舟被漩渦捲著轉了整整一圈。\n轉了幾弧度？",
		"opts": ["π", "2π", "360", "π/2"], "ans": "2π", "why": "一整圈是 360°，也就是 2π 弧度。", "gain": 20},
	"bottle": {"title": "漂來的瓶中信", "hint": "瓶子裡塞著一張捲起來的紙條……", "q": "紙條上寫著：「從這裡往東 3 海里、再往北 4 海里，\n就到我埋寶藏的地方。」\n寶藏離這裡直線距離幾海里？",
		"opts": ["5", "7", "1", "12"], "ans": "5", "why": "往東 3、往北 4，合起來的位移長度是 √(3² + 4²) = 5。", "gain": 25},
}


func _update_card() -> void:
	var k := String(_near.get("kind", ""))
	_card.visible = k != "" and not is_instance_valid(_overlay) and not _busy and not playing
	if not _card.visible:
		return
	match k:
		"dock":
			var i: int = _near.i
			var isl: Dictionary = ISLANDS[i]
			var u: Dictionary = Units.unit(isl.unit)
			var col: Color = isl.col
			_card.add_theme_stylebox_override("panel", UITheme.box(Color(0.06, 0.08, 0.18, 0.95), 16, col, 2, 14))
			_card_no.text = str(isl.n)
			_card_no.visible = true
			_card_title.text = "%s　%s" % [isl.name, u.title if u.id == isl.unit else ""]
			_card_title.add_theme_color_override("font_color", col.lightened(0.35))
			if _unit_open(i):
				var pr := _progress(isl.unit)
				_card_sub.text = "世界之光 %d／%d%s" % [pr.lit, pr.n, ("　·　下一站：" + pr.next) if pr.next != "" else "　·　全部點亮！"]
				_card_bar.visible = true
				_card_bar.value = pr.p * 100.0
				_card_bar.add_theme_stylebox_override("fill", UITheme.box(col, 4, Color(0, 0, 0, 0), 0, 0))
				_card_btn.text = "上岸 ▶"
				_card_btn.disabled = false
			else:
				_card_sub.text = "島上還籠罩在海霧裡（準備中）"
				_card_bar.visible = false
				_card_btn.text = "還不能上岸"
				_card_btn.disabled = true
		"wreck", "whirl", "bottle":
			var e: Dictionary = EGGS[k]
			_card.add_theme_stylebox_override("panel", UITheme.box(Color(0.06, 0.08, 0.18, 0.95), 16, Color("ff9ad5"), 2, 14))
			_card_no.visible = false
			_card_title.text = e.title
			_card_title.add_theme_color_override("font_color", Color("ffd6ec"))
			_card_sub.text = e.hint if not _has("eggs", k) else "已經解開了"
			_card_bar.visible = false
			_card_btn.text = "調查"
			_card_btn.disabled = false
		"harbor":
			_card.add_theme_stylebox_override("panel", UITheme.box(Color(0.06, 0.08, 0.18, 0.95), 16, UITheme.ACCENT, 2, 14))
			_card_no.visible = false
			_card_title.text = "晨曦港"
			_card_title.add_theme_color_override("font_color", Color("ffe7a3"))
			_card_sub.text = "從這裡搭船回高一的曦光大陸"
			_card_bar.visible = false
			_card_btn.text = "回高一"
			_card_btn.disabled = false
	_card.reset_size()
	_card.position = Vector2((W - _card.size.x) / 2.0, H - _card.size.y - 48.0)


func _interact() -> void:
	var k := String(_near.get("kind", ""))
	if k == "" or is_instance_valid(_overlay) or _busy:
		return
	match k:
		"dock":
			if _unit_open(int(_near.i)):
				_land(int(_near.i))
		"wreck", "whirl", "bottle":
			_open_egg(k)
		"harbor":
			var mm := get_parent()
			while mm != null and not mm.has_method("_set_grade"):
				mm = mm.get_parent()
			if mm != null:
				mm._set_grade("高一")


## 上岸：鏡頭往碼頭推進、畫面變暗，然後進入單元地圖
func _land(i: int) -> void:
	_busy = true
	Game.of(self).sfx("success")
	var uid: String = ISLANDS[i].unit
	_state()["ret"] = uid
	_save()
	_zoom_lock = true
	var target: Vector2 = _shores[i]
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "zoom", BASE_ZOOM * 1.9, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "pos", pos.lerp(target, 0.35), 0.55)
	tw.tween_property(_fade, "color:a", 1.0, 0.5).set_delay(0.08)
	await tw.finished
	pick_unit.emit(uid)


## 單元列表：不想划船，直接選一座島上岸
func _open_sail_menu() -> void:
	if is_instance_valid(_overlay) or _busy:
		return
	Game.of(self).sfx("click")
	var o := UITheme.modal(self, UITheme.ACCENT, 560)
	_overlay = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 8)
	col.add_child(UITheme.title_label("☰ 單元列表", 26, UITheme.ACCENT))
	for i in ISLANDS.size():
		var isl: Dictionary = ISLANDS[i]
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		col.add_child(hb)
		var nm := Label.new()
		nm.text = "%d　%s" % [isl.n, Units.unit(isl.unit).title]
		nm.custom_minimum_size = Vector2(250, 0)
		nm.add_theme_font_override("font", UITheme.bold_font())
		nm.add_theme_font_size_override("font_size", UITheme.fs(16))
		var ok := _unit_open(i)
		nm.add_theme_color_override("font_color", (isl.col as Color).lightened(0.3) if ok else UITheme.TEXT_DIM)
		hb.add_child(nm)
		var sb := Label.new()
		sb.text = isl.name
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.add_theme_font_size_override("font_size", UITheme.fs(14))
		sb.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		hb.add_child(sb)
		var go := Button.new()
		go.focus_mode = Control.FOCUS_NONE
		go.custom_minimum_size = Vector2(110, 38)
		go.text = "上岸 ▶" if ok else "準備中"
		go.disabled = not ok
		UITheme.button_3d(go, Color("2a6f9e"), Color("17405e"), Color("e6f7ff"), 14, 4, 12, 3)
		var ii: int = i
		go.pressed.connect(func():
			close_overlay()
			pos = _docks[ii]
			vel = Vector2.ZERO
			cam = _cam_target()
			_land(ii))
		hb.add_child(go)
	var cb := Button.new()
	cb.text = "關閉"
	cb.focus_mode = Control.FOCUS_NONE
	cb.custom_minimum_size = Vector2(0, 46)
	UITheme.accent_button(cb, 17)
	cb.pressed.connect(func(): close_overlay())
	col.add_child(cb)


## 海上的彩蛋：沉船（對數）、漩渦（弧度）、瓶中信（向量的長度）
func _open_egg(id: String) -> void:
	var e: Dictionary = EGGS[id]
	var o := UITheme.modal(self, Color("ff9ad5"), 520)
	_overlay = o[0]
	var col: VBoxContainer = o[1]
	col.add_child(UITheme.title_label(e.title, 26, Color("ff9ad5")))
	var l := Label.new()
	l.text = e.q
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", UITheme.fs(18))
	l.add_theme_color_override("font_color", UITheme.TEXT)
	col.add_child(l)
	var msg := Label.new()
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", UITheme.fs(15))
	msg.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	if _has("eggs", id):
		msg.text = "答案是 %s：%s" % [e.ans, e.why]
	else:
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 10)
		col.add_child(grid)
		for v in e.opts:
			var b := Button.new()
			b.text = v
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(96, 48)
			UITheme.button_3d(b, Color("3a3360"), Color("231e40"), UITheme.TEXT, 18, 4, 12, 3)
			var vv: String = v
			b.pressed.connect(func():
				if vv == e.ans:
					_add("eggs", id)
					Game.of(self).inv["dust"] = int(Game.of(self).inv.get("dust", 0)) + int(e.gain)
					Game.of(self).sfx("success")
					close_overlay()
					_show_toast("答對了！獲得 星塵 ×%d" % int(e.gain))
				else:
					Game.of(self).sfx("wrong")
					msg.text = "好像不對……再想想？")
			grid.add_child(b)
	col.add_child(msg)
	var cb := Button.new()
	cb.text = "離開"
	cb.focus_mode = Control.FOCUS_NONE
	cb.custom_minimum_size = Vector2(0, 46)
	UITheme.accent_button(cb, 17)
	cb.pressed.connect(func(): close_overlay())
	col.add_child(cb)


# ================= 輸入、移動、鏡頭 =================

func _unhandled_input(e: InputEvent) -> void:
	if playing:
		return
	if not is_visible_in_tree() or is_instance_valid(_overlay) or _busy:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_interact()
				get_viewport().set_input_as_handled()
			KEY_M, KEY_TAB:
				_open_sail_menu()
				get_viewport().set_input_as_handled()


func _view() -> Rect2:
	var C := Vector2(W, H) / 2.0
	var half := C / zoom
	return Rect2(cam + C - half, half * 2.0)


## 靠近碼頭（跳出卡片）時：整座島和光舟都要入鏡 → 回傳 [中心, 縮放]；沒有就回傳 []
func _dock_view() -> Array:
	if String(_near.get("kind", "")) != "dock" or story_focus.x >= 0.0:
		return []
	var i := int(_near.i)
	var box: Rect2 = (_shape[i].box as Rect2).grow(60.0).expand(pos + Vector2(80, 80)).expand(pos - Vector2(80, 80))
	# 上面留給橫幅、按鈕，下面留給卡片
	var z := minf((W - 80.0) / box.size.x, (H - 260.0) / box.size.y)
	return [box.get_center() + Vector2(0, 30.0 / z), clampf(z, 0.3, BASE_ZOOM)]


func _cam_target() -> Vector2:
	var C := Vector2(W, H) / 2.0
	var dv := _dock_view()
	var focus: Vector2 = dv[0] if not dv.is_empty() else (story_focus if story_focus.x >= 0.0 else pos)
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
		var fz: String = pc.fog
		var show: bool = (pc.rect as Rect2).intersects(v) and (z == "" or _open.has(z)) and (fz == "" or not _open.has(fz))
		(pc.node as CanvasItem).visible = show
		if show and fz != "":
			var ph := float(fz.hash() % 100)
			(pc.node as Node2D).position = Vector2(sin(t * 0.15 + ph) * 14.0, cos(t * 0.12 + ph) * 9.0)


func _process(delta: float) -> void:
	t += delta
	_zoom_hold -= delta
	_fade.visible = _fade.color.a > 0.004
	var active := is_visible_in_tree() and not is_instance_valid(_overlay) and not _busy and not playing
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
	# 有一點慣性的划船
	vel = vel.lerp(dir * SPEED, 1.0 - exp(-(3.0 if dir != Vector2.ZERO else 1.6) * delta))
	if _whirl_spin > 0.0:
		_whirl_spin -= delta
		vel = vel.rotated(delta * 5.0)
	if vel.length() > 8.0 and not _busy:
		heading = lerp_angle(heading, vel.angle(), 1.0 - exp(-6.0 * delta))
		var step := vel * delta
		if _free(pos + step):
			pos += step
		elif _free(pos + Vector2(step.x, 0)):
			pos += Vector2(step.x, 0)
			vel.y = 0.0
		elif _free(pos + Vector2(0, step.y)):
			pos += Vector2(0, step.y)
			vel.x = 0.0
		else:
			if _in_fog(pos + step) >= 0 and t - _wall_t > 2.5:
				_wall_t = t
				_show_toast("海霧太濃了，「%s」還在準備中" % ISLANDS[_in_fog(pos + step)].name)
			vel *= 0.3
		if randf() < vel.length() / SPEED:
			var back := Vector2.from_angle(heading + PI)
			_wake.append({"p": pos + back * 40.0 + back.orthogonal() * randf_range(-10, 10), "life": 0.0, "s": randf_range(0.7, 1.3)})
		_save_t += delta
		if _save_t > 4.0:
			_save_t = 0.0
			_state()["pos"] = [roundi(pos.x), roundi(pos.y)]
	for w in _wake:
		w.life += delta
	_wake = _wake.filter(func(w): return w.life < 1.8)
	if not _busy:
		# 鏡頭縮放：靠近碼頭時拉遠到看得到整座島；劇情的全景拉到整片海
		if not _zoom_lock and _zoom_hold <= 0.0:
			var dv := _dock_view()
			var zt: float = dv[1] if not dv.is_empty() else BASE_ZOOM
			if story_focus.x >= 0.0 and story_focus.distance_to(focus_point("wide", "")) < 1.0:
				zt = WIDE_ZOOM
			zoom = lerpf(zoom, zt, 1.0 - exp(-3.5 * delta))
		cam = cam.lerp(_cam_target(), 1.0 - exp(-6.0 * delta))
	_check_world()
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)
	_update_card()
	_prewarm()
	_place_root()
	_fx.queue_redraw()
	_light_tick(delta)
	for fl in _lit_fx.values():
		fl.queue_redraw()
	_hud.queue_redraw()
	queue_redraw()


## 地圖剛打開時：每幀先把一塊還沒算過的畫布算好（第一次划到那裡就不會卡一下）
func _prewarm() -> void:
	for pc in _pieces:
		var n: MapLayer = pc.node
		var z: String = pc.zone
		var fz: String = pc.fog
		if not n.built and (z == "" or _open.has(z)) and (fz == "" or not _open.has(fz)):
			n.prebuild()
			return


func _check_world() -> void:
	_near = {}
	for i in ISLANDS.size():
		var isl: Dictionary = ISLANDS[i]
		if pos.distance_to(_docks[i]) < 150.0:
			_near = {"kind": "dock", "i": i}
			if not _has("visited", isl.unit):
				_add("visited", isl.unit)
				_show_toast("發現 %d 號島：%s" % [isl.n, isl.name])
	if pos.distance_to(WRECK) < 220.0:
		_near = {"kind": "wreck"}
	if pos.distance_to(BOTTLE) < 130.0:
		_near = {"kind": "bottle"}
	if pos.distance_to(WHIRL) < 170.0:
		_near = {"kind": "whirl"}
		if _whirl_spin <= 0.0 and not _has("eggs", "whirl") and vel.length() > 80.0:
			_whirl_spin = 1.2
	if pos.distance_to(HARBOR) < 560.0:
		_near = {"kind": "harbor"}


# ================= 海上的生物、浪花的位置 =================

func _build_life() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _rng_seed
	# 小魚群：在各島的淺灘附近繞圈
	for i in ISLANDS.size():
		var sh: Dictionary = _shape[i]
		var b: Rect2 = sh.box
		for k in 2:
			var a := rng.randf() * TAU
			var p := b.get_center() + Vector2(cos(a) * (b.size.x / 2.0 + 260.0), sin(a) * (b.size.y / 2.0 + 220.0))
			if _free(p):
				_schools.append({"c": p, "r": rng.randf_range(60, 110), "n": rng.randi_range(9, 14), "ph": rng.randf() * TAU,
					"night": ISLANDS[i].night, "sp": rng.randf_range(0.5, 0.9)})
	# 水母群（深夜的海）
	for sw in [[Vector2(4700, 3250), 260.0], [Vector2(2600, 3900), 240.0], [Vector2(5000, 4150), 200.0]]:
		for k in 12:
			var a := rng.randf() * TAU
			var d := sqrt(rng.randf()) * float(sw[1])
			_jellies.append({"p": (sw[0] as Vector2) + Vector2(cos(a), sin(a) * 0.7) * d, "s": rng.randf_range(0.7, 1.3), "ph": rng.randf() * TAU,
				"c": [Color("ff9ad5"), Color("8ff0ff"), Color("c6a6ff"), Color("7affd2")][k % 4]})
	# 會發光的浮游生物（南邊的海面上一片一片）
	for k in 260:
		var p := Vector2(rng.randf_range(200, 7000), rng.randf_range(2500, 4300))
		var key := Vector2i(int(p.x / 1000.0), int(p.y / 1000.0))
		if not _plankton_grid.has(key):
			_plankton_grid[key] = []
		_plankton_grid[key].append({"p": p, "ph": rng.randf() * TAU, "s": rng.randf_range(1.5, 3.4)})
	for k in 70:
		_stars.append({"p": Vector2(rng.randf() * W, rng.randf() * H * 0.7), "s": rng.randf_range(0.8, 2.0), "ph": rng.randf() * TAU})
	# 海岸線取樣（浪花）
	for i in ISLANDS.size():
		var sh: Dictionary = _shape[i]
		var pts := []
		for poly in sh.lands:
			pts.append_array(_coast_samples(poly, 80.0))
		if sh.kind == "trig":
			for k in 60:
				var a := TAU * k / 60.0
				var d := Vector2.from_angle(a)
				pts.append([sh.o + d * (sh.rr + sh.rw / 2.0), d])
				if k % 2 == 0:
					pts.append([sh.o + d * (sh.rr - sh.rw / 2.0), -d])
		_coast.append(pts)
	_coast.append(_coast_samples(_harbor_poly, 80.0))


static func _coast_samples(poly: PackedVector2Array, step: float) -> Array:
	var out := []
	var cw := Geometry2D.is_polygon_clockwise(poly)
	var acc := 0.0
	for k in poly.size():
		var a := poly[k]
		var b := poly[(k + 1) % poly.size()]
		var seg := a.distance_to(b)
		if seg < 0.01:
			continue
		var d := (b - a) / seg
		var n := Vector2(d.y, -d.x) if not cw else Vector2(-d.y, d.x)
		while acc < seg:
			out.append([a + d * acc, n])
			acc += step
		acc -= seg
	return out


# ================= 畫布 =================

## 一塊靜態畫布：rect 是它的範圍（不在畫面裡就隱藏）；dyn = 開放狀態改變時要重畫；zone：還沒開放就不畫（在霧底下）
func _piece(rect: Rect2, painter: Callable, dyn := false, zone := "", fog := "") -> MapLayer:
	var n := MapLayer.new()
	n.painter = painter
	n.batched = true
	_root.add_child(n)
	_pieces.append({"node": n, "rect": rect, "dyn": dyn, "zone": zone, "fog": fog})
	return n


func _build_layers() -> void:
	_root = Node2D.new()
	add_child(_root)
	_piece(Rect2(Vector2.ZERO, WORLD), _p_floor)
	_piece(Rect2(-200, 1700, 1100, 1100), _p_harbor)
	_piece(Rect2(WRECK - Vector2(400, 360), Vector2(800, 640)), _p_wreck)
	for i in ISLANDS.size():
		var ii: int = i
		var b: Rect2 = (_shape[i].box as Rect2).grow(420.0)
		var n := _piece(b, func(L): _p_island(L, ii), false, String(ISLANDS[i].unit))
		n.material = _light_mat(String(ISLANDS[i].unit))     # 還沒點亮的島：灰暗（world_base 的點亮）
	_piece(Rect2(Vector2.ZERO, WORLD), _p_docks, true)
	# 海霧：每座島一塊（還沒開放才顯示），整塊慢慢飄動
	for i in ISLANDS.size():
		var ii: int = i
		var fg: Array = _fog[i]
		var fr := Rect2((fg[0] as Vector2) - Vector2(fg[1], fg[2]) * 1.3, Vector2(fg[1], fg[2]) * 2.6)
		_piece(fr, func(L): _draw_fog(L, ii), false, "", String(ISLANDS[i].unit))
	# 每座島自己的動態（風箏、纜車、光點……）：一層一層分開，才能照點亮程度調淡
	for i in ISLANDS.size():
		var ii: int = i
		var fl := MapLayer.new()
		fl.painter = func(L): _island_fx_one(L, ii, _view().grow(160.0))
		fl.batched = true
		fl.cache = false
		fl.lines_native = true
		fl.material = _light_mat(String(ISLANDS[i].unit))
		_root.add_child(fl)
		_lit_fx[String(ISLANDS[i].unit)] = fl
	_apply_light()
	_fx = MapLayer.new()
	_fx.painter = _p_fx
	_fx.batched = true          # 每幀也收成網格：魚、水母、浮游生物一隻一隻畫會變成好幾百次繪圖
	_fx.cache = false
	_fx.lines_native = true
	_root.add_child(_fx)
	_hud = MapLayer.new()
	_hud.painter = _p_hud
	add_child(_hud)
	_seen_open = ",".join(_open.keys())


# ================= 海（每幀畫，螢幕座標） =================

## 海的顏色：北邊黃昏的玫瑰紫、往南變成夜晚的深藍
static func _sea_col(wy: float) -> Color:
	var stops := [[0.0, Color("6e5a8e")], [900.0, Color("4e5c96")], [1700.0, Color("33487e")], [DUSK_Y, Color("1f3366")],
		[2900.0, Color("0f2150")], [4400.0, Color("08163a")]]
	if wy <= 0.0:
		return stops[0][1]
	for k in stops.size() - 1:
		var a: Array = stops[k]
		var b: Array = stops[k + 1]
		if wy <= float(b[0]):
			return (a[1] as Color).lerp(b[1], (wy - float(a[0])) / (float(b[0]) - float(a[0])))
	return stops[stops.size() - 1][1]


## 這裡有多「夜」（0：黃昏，1：深夜）
static func _night_k(wy: float) -> float:
	return clampf((wy - (DUSK_Y - 500.0)) / 1000.0, 0.0, 1.0)


func _draw() -> void:
	var v := _view()
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var rows := 8
	for k in rows + 1:
		var sy := H * k / rows
		var wy := v.position.y + sy / H * v.size.y
		var cl := _sea_col(wy)
		pts.append(Vector2(0, sy))
		pts.append(Vector2(W, sy))
		cols.append(cl)
		cols.append(cl.darkened(0.06))
	var idx := PackedInt32Array()
	for k in rows:
		var a := k * 2
		idx.append_array([a, a + 1, a + 3, a, a + 3, a + 2])
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols)


# ================= 共用的小畫法 =================

static func blob(ci, c: Vector2, r: Vector2, col: Color) -> void:
	GW.blob(ci, c, r, col)


static func _dot(ci, c: Vector2, r: float, col: Color, n: int) -> void:
	GW._dot(ci, c, r, col, n)


## 島的配色（黃昏／深夜）
static func _pal(night: bool) -> Dictionary:
	if night:
		return {"shallow": Color(0.2, 0.75, 0.85), "wet": Color("4a5a86"), "sand": Color("7c86b0"), "sand_hi": Color("98a2c8"),
			"grass": Color("1f3d4c"), "grass_hi": Color("29505e"), "high": Color("336272"), "cliff": Color("18223e"), "cliff_dk": Color("0c1226"),
			"rim": Color("13293a"), "tree": [Color("0f2a36"), Color("17404e"), Color("23606c"), Color("7fe0e0")], "rock": Color("3a4566")}
	return {"shallow": Color(0.62, 0.86, 0.86), "wet": Color("b88a74"), "sand": Color("e9b98c"), "sand_hi": Color("f6d3a6"),
		"grass": Color("6d7f4a"), "grass_hi": Color("86924f"), "high": Color("9a9a58"), "cliff": Color("7a4e52"), "cliff_dk": Color("4e3040"),
		"rim": Color("55663a"), "tree": [Color("3b5236"), Color("56713f"), Color("7f944c"), Color("e8c27a")], "rock": Color("8a7a7a")}


## 一塊陸地的基本層次：淺灘一圈一圈 → 濕沙 → 南邊的崖壁 → 沙灘 → 草地 → 高地
func _land_layers(L, poly: PackedVector2Array, pal: Dictionary, cliff := 40.0, sand := 46.0) -> PackedVector2Array:
	if poly.size() < 3:
		return PackedVector2Array()
	var sc: Color = pal.shallow
	var prev := poly
	var ds := [60.0, 130.0, 210.0, 300.0]
	var rings := []
	for k in ds.size():
		rings.append(GW._ring(GW._off(poly, ds[k]), poly if k == 0 else GW._off(poly, ds[k - 1])))
	for k in range(ds.size() - 1, -1, -1):
		var a := 0.07 + 0.07 * (ds.size() - 1 - k)
		for pc in rings[k]:
			L.draw_colored_polygon(pc, Color(sc.r, sc.g, sc.b, a))
	for pc in Geometry2D.clip_polygons(GW._shift(poly, Vector2(0, cliff + 18.0)), poly):
		L.draw_colored_polygon(pc, pal.cliff_dk)
	for pc in Geometry2D.clip_polygons(GW._shift(poly, Vector2(0, cliff)), poly):
		L.draw_colored_polygon(pc, pal.cliff)
	for pc in GW._ring(GW._off(poly, 12.0), poly):
		L.draw_colored_polygon(pc, Color(1, 1, 1, 0.22))
	var inner := GW._off(poly, -sand)
	if inner.size() < 3:
		L.draw_colored_polygon(poly, pal.sand)
		return PackedVector2Array()
	for pc in GW._ring(poly, GW._off(poly, -sand * 0.4)):
		L.draw_colored_polygon(pc, pal.sand)
	for pc in GW._ring(GW._off(poly, -sand * 0.4), inner):
		L.draw_colored_polygon(pc, pal.sand_hi)
	L.draw_colored_polygon(inner, pal.grass)
	var rim := inner.duplicate()
	rim.append(rim[0])
	L.draw_polyline(rim, pal.rim, 5.0, true)
	var hi := GW._off(inner, -70.0)
	if hi.size() >= 3:
		L.draw_colored_polygon(GW._shift(hi, Vector2(-14, -12)), pal.grass_hi)
	return inner


## 一棵樹：dusk 用圓圓的闊葉樹（夕陽照到的那面亮），night 用深色的松或發光的樹
func _tree(L, p: Vector2, r: float, pal: Dictionary, kind: String, v: float) -> void:
	var tc: Array = pal.tree
	blob(L, p + Vector2(r * 0.4, r * 0.25), Vector2(r * 1.1, r * 0.45), Color(0, 0, 0, 0.3))
	match kind:
		"pine":
			L.draw_rect(Rect2(p + Vector2(-4, -r * 0.2), Vector2(8, r * 0.4)), Color("3a2a22"))
			for k in 3:
				var y0 := -r * 0.2 - k * r * 0.5
				var w := r * (0.95 - k * 0.22)
				L.draw_colored_polygon(PackedVector2Array([p + Vector2(-w, y0), p + Vector2(w, y0), p + Vector2(0, y0 - r * 0.95)]), tc[0])
				L.draw_colored_polygon(PackedVector2Array([p + Vector2(-w, y0), p + Vector2(-w * 0.05, y0), p + Vector2(0, y0 - r * 0.95)]), tc[1])
		"palm":
			var top := p + Vector2(r * 0.3, -r * 1.5)
			L.draw_polyline(PackedVector2Array([p, p + Vector2(r * 0.05, -r * 0.6), p + Vector2(r * 0.18, -r * 1.1), top]), Color("8a6a48"), 7.0, true)
			for k in 6:
				var a := -PI / 2.0 + (k - 2.5) * 0.62 + v
				var e := top + Vector2.from_angle(a) * r * 1.05 + Vector2(0, r * 0.35)
				var m := top + Vector2.from_angle(a) * r * 0.55 + Vector2(0, -r * 0.05)
				L.draw_polyline(PackedVector2Array([top, m, e]), tc[1] if k % 2 == 0 else tc[2], 9.0, true)
			_dot(L, top + Vector2(0, 4), 6.0, Color("6a4a2a"), 32)
		"glow":
			L.draw_colored_polygon(PackedVector2Array([p + Vector2(-5, 0), p + Vector2(5, 0), p + Vector2(3, -r * 0.8), p + Vector2(-3, -r * 0.8)]), Color("1a2238"))
			var c0 := p + Vector2(0, -r * 1.05)
			_dot(L, c0 + Vector2(-r * 0.4, r * 0.15), r * 0.66, tc[0], 128)
			_dot(L, c0 + Vector2(r * 0.42, r * 0.2), r * 0.62, tc[0], 128)
			_dot(L, c0, r * 0.78, tc[1], 128)
			_dot(L, c0 + Vector2(-r * 0.24, -r * 0.28), r * 0.44, tc[2], 128)
			for k in 5:
				_dot(L, c0 + Vector2.from_angle(TAU * k / 5.0 + v * 6.0) * r * 0.5, 3.0, tc[3], 32)
		_:
			L.draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 0), p + Vector2(6, 0), p + Vector2(4, -r * 0.85), p + Vector2(-4, -r * 0.85)]), Color("5a3d2c"))
			var c0 := p + Vector2(0, -r * 1.05)
			_dot(L, c0 + Vector2(-r * 0.42, r * 0.16), r * 0.68, tc[0], 128)
			_dot(L, c0 + Vector2(r * 0.44, r * 0.2), r * 0.64, tc[0], 128)
			_dot(L, c0, r * 0.8, tc[1], 128)
			_dot(L, c0 + Vector2(-r * 0.26, -r * 0.3), r * 0.46, tc[2], 128)
			_dot(L, c0 + Vector2(-r * 0.34, -r * 0.42), r * 0.16, tc[3], 128)


## 在 area（陸地內緣）裡撒一些樹，避開 avoid（一串 Rect2）
func _forest(L, area: PackedVector2Array, pal: Dictionary, n: int, kinds: Array, avoid: Array, seed: int, rmin := 30.0, rmax := 46.0) -> void:
	if area.size() < 3:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var bb := Rect2(area[0], Vector2.ZERO)
	for q in area:
		bb = bb.expand(q)
	var pts := []
	var tries := 0
	while pts.size() < n and tries < n * 30:
		tries += 1
		var p := Vector2(rng.randf_range(bb.position.x, bb.end.x), rng.randf_range(bb.position.y, bb.end.y))
		if not Geometry2D.is_point_in_polygon(p, area):
			continue
		var bad := false
		for r in avoid:
			if (r as Rect2).has_point(p):
				bad = true
				break
		for q in pts:
			if (q[0] as Vector2).distance_to(p) < 52.0:
				bad = true
				break
		if bad:
			continue
		pts.append([p, rng.randf_range(rmin, rmax), kinds[rng.randi() % kinds.size()], rng.randf()])
	pts.sort_custom(func(a, b): return a[0].y < b[0].y)
	for q in pts:
		_tree(L, q[0], q[1], pal, q[2], q[3])


static func _rock(L, p: Vector2, s: float, col: Color) -> void:
	L.draw_colored_polygon(GW._ell(p + Vector2(0, 8 * s), 26 * s, 12 * s, 12), Color(0, 0, 0, 0.25))
	L.draw_colored_polygon(PackedVector2Array([p + Vector2(-24, 6) * s, p + Vector2(-16, -14) * s, p + Vector2(6, -20) * s,
		p + Vector2(24, -4) * s, p + Vector2(18, 8) * s]), col)
	L.draw_colored_polygon(PackedVector2Array([p + Vector2(-16, -14) * s, p + Vector2(6, -20) * s, p + Vector2(2, -8) * s, p + Vector2(-12, -5) * s]), col.lightened(0.22))


## 一間小屋子（斜屋頂、亮著的窗）
static func _house(L, p: Vector2, s: float, wall: Color, roof: Color, lit: bool) -> void:
	L.draw_colored_polygon(GW._ell(p + Vector2(10, 6) * s, 46 * s, 12 * s, 12), Color(0, 0, 0, 0.28))
	L.draw_rect(Rect2(p + Vector2(-34, -40) * s, Vector2(68, 44) * s), wall)
	L.draw_rect(Rect2(p + Vector2(14, -40) * s, Vector2(20, 44) * s), wall.darkened(0.18))
	L.draw_colored_polygon(PackedVector2Array([p + Vector2(-42, -38) * s, p + Vector2(42, -38) * s, p + Vector2(26, -70) * s, p + Vector2(-26, -70) * s]), roof)
	L.draw_colored_polygon(PackedVector2Array([p + Vector2(-42, -38) * s, p + Vector2(0, -38) * s, p + Vector2(0, -70) * s, p + Vector2(-26, -70) * s]), roof.lightened(0.12))
	L.draw_rect(Rect2(p + Vector2(-8, -20) * s, Vector2(16, 24) * s), Color("3a2a22"))
	var wc := Color("ffd27a") if lit else Color("6a7898")
	L.draw_rect(Rect2(p + Vector2(-28, -32) * s, Vector2(14, 12) * s), wc)
	L.draw_rect(Rect2(p + Vector2(16, -32) * s, Vector2(12, 12) * s), wc)


## 一叢珊瑚（淺灘裡）
static func _coral(L, p: Vector2, s: float, v: float) -> void:
	var cs := [Color("ff8a9a"), Color("ffb36a"), Color("c99aff"), Color("ff9ad5"), Color("6ee7c0")]
	var c: Color = cs[int(v * 5.0) % 5]
	for k in 5:
		var a := TAU * k / 5.0 + v * 4.0
		GW._dot(L, p + Vector2.from_angle(a) * 9.0 * s, 7.0 * s, Color(c.r, c.g, c.b, 0.55), 32)
	GW._dot(L, p, 6.0 * s, Color(c.r, c.g, c.b, 0.8).lightened(0.2), 32)


## 沿著海岸外面撒珊瑚
func _reefs(L, poly: PackedVector2Array, n: int, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var sm := _coast_samples(poly, 40.0)
	if sm.is_empty():
		return
	for k in n:
		var s: Array = sm[rng.randi() % sm.size()]
		var p: Vector2 = s[0] + (s[1] as Vector2) * rng.randf_range(70, 170)
		_coral(L, p, rng.randf_range(0.8, 1.4), rng.randf())


# ================= 海底、航道（整張地圖，只畫一次） =================

func _p_floor(L) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	# 深海的暗影、比較淺的沙洲
	for k in 26:
		var p := Vector2(rng.randf_range(300, 6900), rng.randf_range(300, 4100))
		blob(L, p, Vector2(rng.randf_range(400, 700), rng.randf_range(220, 380)), Color(0.0, 0.02, 0.1, 0.16))
	for q in [[Vector2(2700, 1500), 320.0], [Vector2(4700, 1650), 260.0], [Vector2(2500, 3000), 280.0], [Vector2(4900, 2950), 240.0], [Vector2(3600, 2900), 200.0]]:
		var c: Vector2 = q[0]
		var rr: float = q[1]
		var nk := _night_k(c.y)
		blob(L, c, Vector2(rr, rr * 0.45), Color(0.5, 0.8, 0.8, 0.12 * (1.0 - nk * 0.6)))
		blob(L, c + Vector2(-20, -8), Vector2(rr * 0.6, rr * 0.22), Color(0.95, 0.85, 0.6, 0.12 * (1.0 - nk * 0.7)))
	# 海藻林（深夜的海裡會亮）
	for q in [Vector2(2950, 2600), Vector2(4400, 2700), Vector2(1100, 2700), Vector2(5600, 1800), Vector2(2400, 1600)]:
		var nk := _night_k(q.y)
		for k in 18:
			var p: Vector2 = q + Vector2(rng.randf_range(-180, 180), rng.randf_range(-110, 110))
			var pl := PackedVector2Array()
			var h := rng.randf_range(30, 60)
			for j in 6:
				pl.append(p + Vector2(sin(j * 0.9 + k) * 6.0, -h * j / 5.0))
			L.draw_polyline(pl, Color(0.2, 0.55, 0.4, 0.35).lerp(Color(0.3, 0.9, 0.75, 0.4), nk), 4.0, true)
	# 海面上一道一道的浪紋（靜態的，浪花在 fx 裡動）
	var wv := PackedVector2Array()
	var y := 120.0
	while y < WORLD.y:
		var x := 80.0 + fmod(y * 0.7, 300.0)
		while x < WORLD.x:
			var c := Vector2(x + rng.randf_range(-40, 40), y + rng.randf_range(-20, 20))
			var on := false
			for i in ISLANDS.size():
				if (_shape[i].box as Rect2).grow(160.0).has_point(c):
					on = true
					break
			if not on and c.distance_to(HARBOR) > 520.0:
				for k in 3:
					wv.append(c + Vector2.from_angle(PI * (1.15 + 0.23 * k)) * 26.0)
					wv.append(c + Vector2.from_angle(PI * (1.15 + 0.23 * (k + 1))) * 26.0)
			x += 300.0
		y += 170.0
	L.draw_multiline(wv, Color(0.8, 0.88, 1.0, 0.13), 3.0)
	# 航道：從港口照章節順序連到每座島的碼頭（光潮的流動在 fx）
	var route := [SPAWN]
	route.append_array(_docks)
	var dots := PackedVector2Array()
	for i in route.size() - 1:
		var a: Vector2 = route[i]
		var b: Vector2 = route[i + 1]
		var n := int(a.distance_to(b) / 70.0)
		for k in n:
			var p := a.lerp(b, (k + 0.5) / maxf(1.0, n))
			if _free(p):
				_dot(L, p, 6.0, Color(1.0, 0.86, 0.5, 0.22), 32)


# ================= 晨曦港 =================

func _p_harbor(L) -> void:
	var pal := _pal(false)
	pal.grass = Color("5e6c48")
	pal.grass_hi = Color("717a4c")
	var inner := _land_layers(L, _harbor_poly, pal, 46.0, 40.0)
	var h := HARBOR
	# 石砌的碼頭邊、木棧橋
	L.draw_rect(Rect2(h + Vector2(250, -110), Vector2(90, 220)), Color("8a7f86"))
	L.draw_rect(Rect2(h + Vector2(250, -110), Vector2(90, 10)), Color("a89ea4"))
	var bricks := PackedVector2Array()
	for k in 10:
		bricks.append_array([h + Vector2(250, -96 + k * 22), h + Vector2(340, -96 + k * 22)])
	L.draw_multiline(bricks, Color("6e646c"), 2.0)
	L.draw_rect(Rect2(PIER.position + Vector2(0, 14), PIER.size), Color(0, 0, 0, 0.3))
	L.draw_rect(PIER, Color("9a6e42"))
	var pl := PackedVector2Array()
	var x := PIER.position.x + 8.0
	while x < PIER.end.x:
		pl.append_array([Vector2(x, PIER.position.y), Vector2(x, PIER.end.y)])
		x += 20.0
	L.draw_multiline(pl, Color("74502e"), 3.0)
	for k in 4:
		var px := PIER.position.x + 20.0 + k * 46.0
		L.draw_rect(Rect2(Vector2(px, PIER.end.y - 4), Vector2(12, 30)), Color("5a3a22"))
		L.draw_rect(Rect2(Vector2(px, PIER.position.y - 22), Vector2(12, 26)), Color("5a3a22"))
	# 倉庫、貨箱、木桶
	_house(L, h + Vector2(40, -90), 1.5, Color("d8c8b0"), Color("8a4a3a"), true)
	_house(L, h + Vector2(80, 150), 1.3, Color("c8d0dc"), Color("3e5288"), true)
	for q in [Vector2(210, 40), Vector2(232, 62), Vector2(206, 70)]:
		var cp: Vector2 = h + q
		L.draw_rect(Rect2(cp - Vector2(16, 16), Vector2(32, 32)), Color("a87a48"))
		L.draw_rect(Rect2(cp - Vector2(16, 16), Vector2(32, 32)), Color("6a4a2a"), false, 3.0)
		L.draw_line(cp - Vector2(16, 16), cp + Vector2(16, 16), Color("6a4a2a"), 2.0)
	for q in [Vector2(196, -40), Vector2(214, -28)]:
		L.draw_colored_polygon(GW._ell(h + q, 12, 15, 14), Color("7a5232"))
		L.draw_line(h + q + Vector2(-12, -4), h + q + Vector2(12, -4), Color("4a3020"), 2.0)
	# 小燈塔
	var lh := h + Vector2(150, -230)
	L.draw_colored_polygon(GW._ell(lh + Vector2(10, 6), 46, 14, 14), Color(0, 0, 0, 0.3))
	for k in 4:
		var y0 := -k * 34.0
		var w0 := 36.0 - k * 4.0
		var w1 := 36.0 - (k + 1) * 4.0
		var cl := Color("ecebf2") if k % 2 == 0 else Color("d84a4a")
		L.draw_colored_polygon(PackedVector2Array([lh + Vector2(-w0 / 2, y0), lh + Vector2(w0 / 2, y0), lh + Vector2(w1 / 2, y0 - 34), lh + Vector2(-w1 / 2, y0 - 34)]), cl)
		L.draw_colored_polygon(PackedVector2Array([lh + Vector2(w0 * 0.2, y0), lh + Vector2(w0 / 2, y0), lh + Vector2(w1 / 2, y0 - 34), lh + Vector2(w1 * 0.2, y0 - 34)]), cl.darkened(0.25))
	L.draw_rect(Rect2(lh + Vector2(-14, -166), Vector2(28, 28)), Color("fff2b0"))
	L.draw_colored_polygon(GW._ell(lh + Vector2(0, -166), 18, 16, 16, PI, TAU), Color("c83a3a"))
	_forest(L, inner, pal, 6, ["palm", "round"], [Rect2(h + Vector2(-60, -180), Vector2(420, 400))], 7)
	# 渡船（和高一渡口的那一艘一樣：紅褐色船身、白帆）
	var bt := FERRY
	blob(L, bt + Vector2(0, 34), Vector2(170, 36), Color(0, 0, 0, 0.35))
	L.draw_colored_polygon(PackedVector2Array([bt + Vector2(-150, -22), bt + Vector2(150, -22), bt + Vector2(110, 34), bt + Vector2(-110, 34)]), Color("8a4a2e"))
	L.draw_colored_polygon(PackedVector2Array([bt + Vector2(-150, -22), bt + Vector2(150, -22), bt + Vector2(140, -6), bt + Vector2(-140, -6)]), Color("a85e3a"))
	L.draw_rect(Rect2(bt + Vector2(-150, -30), Vector2(300, 10)), Color("c8955a"))
	for k in 5:
		L.draw_colored_polygon(GW._ell(bt + Vector2(-90 + k * 45, 8), 7, 7, 12), Color("e8d8b0"))
	L.draw_line(bt + Vector2(-10, -28), bt + Vector2(-10, -340), Color("5a3a22"), 8.0)
	L.draw_colored_polygon(PackedVector2Array([bt + Vector2(-4, -330), bt + Vector2(128, -56), bt + Vector2(-4, -56)]), Color("eef0ff"))
	L.draw_colored_polygon(PackedVector2Array([bt + Vector2(-4, -330), bt + Vector2(40, -150), bt + Vector2(-4, -56)]), Color("d6dcf2"))
	L.draw_colored_polygon(PackedVector2Array([bt + Vector2(-16, -300), bt + Vector2(-116, -66), bt + Vector2(-16, -66)]), Color("d8dcf0"))
	L.draw_colored_polygon(PackedVector2Array([bt + Vector2(-10, -340), bt + Vector2(30, -330), bt + Vector2(-10, -318)]), Color("f5c84c"))
	L.draw_line(bt + Vector2(-10, -330), bt + Vector2(140, -22), Color("4a3a2a"), 2.0)
	L.draw_line(bt + Vector2(-10, -330), bt + Vector2(-140, -22), Color("4a3a2a"), 2.0)


# ================= 沉船 =================

func _p_wreck(L) -> void:
	var w := WRECK
	var rot := -0.38
	var tf := func(q: Vector2) -> Vector2: return w + q.rotated(rot)
	# 周圍的礁石、淺一點的水
	blob(L, w, Vector2(320, 190), Color(0.45, 0.75, 0.8, 0.16))
	for q in [Vector2(-210, 70), Vector2(190, -90), Vector2(230, 60), Vector2(-160, -110)]:
		_rock(L, w + q, 1.6, Color("4a4a62"))
	# 船身（往一邊斜，船頭沉在水裡）
	var hull := PackedVector2Array()
	for q in [Vector2(-190, -10), Vector2(-150, -58), Vector2(120, -62), Vector2(200, -18), Vector2(170, 40), Vector2(-150, 46)]:
		hull.append(tf.call(q))
	L.draw_colored_polygon(GW._shift(hull, Vector2(10, 22)), Color(0, 0, 0, 0.3))
	L.draw_colored_polygon(hull, Color("4e3626"))
	var deck := PackedVector2Array()
	for q in [Vector2(-160, -20), Vector2(-130, -46), Vector2(110, -50), Vector2(170, -16), Vector2(140, 22), Vector2(-130, 28)]:
		deck.append(tf.call(q))
	L.draw_colored_polygon(deck, Color("7a5a3a"))
	var planks := PackedVector2Array()
	for k in 6:
		var yy := -40.0 + k * 12.0
		planks.append_array([tf.call(Vector2(-140, yy)), tf.call(Vector2(150, yy))])
	L.draw_multiline(planks, Color("5a3e28"), 2.0)
	# 破洞、斷掉的桅杆、破帆
	L.draw_colored_polygon(GW._ell(tf.call(Vector2(20, -10)), 34, 18, 16), Color("1a1410"))
	L.draw_colored_polygon(GW._ell(tf.call(Vector2(-80, 6)), 20, 11, 12), Color("1a1410"))
	L.draw_line(tf.call(Vector2(40, -20)), tf.call(Vector2(-60, -230)), Color("5a3e28"), 10.0, true)
	L.draw_line(tf.call(Vector2(-30, -150)), tf.call(Vector2(-110, -120)), Color("5a3e28"), 6.0, true)
	L.draw_colored_polygon(PackedVector2Array([tf.call(Vector2(-50, -210)), tf.call(Vector2(30, -110)), tf.call(Vector2(-10, -90)), tf.call(Vector2(-40, -140)), tf.call(Vector2(-70, -120))]), Color(0.86, 0.82, 0.72, 0.85))
	# 船頭沉在水裡：蓋一層半透明的海水
	var sunk := PackedVector2Array()
	for q in [Vector2(-200, -80), Vector2(-90, -80), Vector2(-110, 70), Vector2(-210, 70)]:
		sunk.append(tf.call(q))
	L.draw_colored_polygon(sunk, Color(0.2, 0.32, 0.55, 0.55))
	# 藤壺、海草、漂著的木桶和木板
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for k in 16:
		_dot(L, tf.call(Vector2(rng.randf_range(-130, 170), rng.randf_range(20, 44))), rng.randf_range(3, 6), Color("c8c0b0"), 16)
	for q in [Vector2(250, 20), Vector2(-260, -30), Vector2(150, 120)]:
		L.draw_colored_polygon(GW._ell(w + q, 18, 13, 14), Color("7a5232"))
		L.draw_line(w + q + Vector2(-18, -2), w + q + Vector2(18, -2), Color("4a3020"), 3.0)
	L.draw_rect(Rect2(w + Vector2(-260, 90), Vector2(90, 14)), Color("8a6a48"))
	# 停在桅杆上的海鷗
	var gp: Vector2 = tf.call(Vector2(-60, -232))
	L.draw_colored_polygon(GW._ell(gp, 14, 9, 12), Color("f2f2f8"))
	L.draw_colored_polygon(GW._ell(gp + Vector2(10, -6), 7, 6, 10), Color("f2f2f8"))
	L.draw_colored_polygon(PackedVector2Array([gp + Vector2(16, -6), gp + Vector2(24, -4), gp + Vector2(16, -3)]), Color("f5c84c"))
	L.draw_colored_polygon(PackedVector2Array([gp + Vector2(-14, -2), gp + Vector2(2, -4), gp + Vector2(-6, 4)]), Color("8a8a9a"))


# ================= 碼頭、浮標、島名（開放狀態改變時重畫） =================

func _p_docks(L) -> void:
	var font := UITheme.bold_font()
	for i in ISLANDS.size():
		var isl: Dictionary = ISLANDS[i]
		var d: Vector2 = _docks[i]
		var sh_p: Vector2 = _shores[i]
		var dir := (d - sh_p).normalized()
		var n := dir.orthogonal()
		var open := _open_i(i)
		# 木棧橋：從岸邊伸到碼頭（還沒開放的島，只畫霧外面那一段）
		var a := sh_p - dir * 30.0
		if not open:
			a = d - dir * 140.0
		var b := d + dir * 10.0
		var plank := PackedVector2Array([a + n * 28.0, b + n * 28.0, b - n * 28.0, a - n * 28.0])
		L.draw_colored_polygon(GW._shift(plank, Vector2(0, 14)), Color(0, 0, 0, 0.3))
		L.draw_colored_polygon(plank, Color("9a6e42"))
		var lines := PackedVector2Array()
		var len := a.distance_to(b)
		var k := 10.0
		while k < len:
			var q := a + dir * k
			lines.append_array([q + n * 28.0, q - n * 28.0])
			k += 20.0
		L.draw_multiline(lines, Color("74502e"), 3.0)
		for j in int(len / 80.0) + 1:
			var q := a + dir * minf(len, j * 80.0 + 20.0)
			for sd in [-1.0, 1.0]:
				L.draw_rect(Rect2(q + n * 30.0 * sd - Vector2(6, 6), Vector2(12, 24)), Color("5a3a22"))
		# 浮標：編號
		var bp := d + n * 92.0
		L.draw_colored_polygon(GW._ell(bp + Vector2(0, 14), 30, 10, 16), Color(0, 0, 0, 0.3))
		L.draw_colored_polygon(GW._ell(bp, 26, 26, 28), Color("f5c84c") if open else Color("8a90b0"))
		L.draw_colored_polygon(GW._ell(bp + Vector2(-6, -6), 12, 10, 16), Color(1, 1, 1, 0.35))
		L.draw_arc(bp, 26.0, 0, TAU, 28, Color("fff3c4") if open else Color("c8cce0"), 3.0, true)
		var ns := str(isl.n)
		var nw := font.get_string_size(ns, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		L.draw_string(font, bp + Vector2(-nw / 2.0, 11), ns, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("2a2440"))
		# 開放的島：島名寫在島的上方
		if open:
			var box: Rect2 = _shape[i].box
			var lp := Vector2(box.get_center().x, box.position.y - 60.0)
			if String(isl.unit) == "vec3":
				lp.y += 40.0
			var u: Dictionary = Units.unit(isl.unit)
			GW._text_ol(L, font, lp + Vector2(-400, 0), isl.name, HORIZONTAL_ALIGNMENT_CENTER, 800, 64, Color("fff3d6"), 12)
			var pr := _progress(isl.unit)
			var sub := "%s　·　世界之光 %d／%d" % [u.title, pr.lit, pr.n]
			GW._text_ol(L, font, lp + Vector2(-400, 46), sub, HORIZONTAL_ALIGNMENT_CENTER, 800, 30, (isl.col as Color).lightened(0.4), 8)
	GW._text_ol(L, font, HARBOR + Vector2(-300, -330), "晨曦港", HORIZONTAL_ALIGNMENT_CENTER, 600, 60, Color("ffe7a3"), 12)
	GW._text_ol(L, font, HARBOR + Vector2(-300, -284), "← 高一 · 曦光大陸", HORIZONTAL_ALIGNMENT_CENTER, 600, 28, Color("c9d1f0"), 8)


# ================= 島 =================

func _p_island(L, i: int) -> void:
	match String(ISLANDS[i].unit):
		"trig":
			_p_trig(L, i)
		"exp":
			_p_exp(L, i)
		"vec2":
			_p_vec2(L, i)
		"vec3":
			_p_vec3(L, i)
		"plane":
			_p_plane(L, i)
		"prob":
			_p_prob(L, i)
		"matrix":
			_p_matrix(L, i)
	_p_sites(L, i)


## 聖地（單元裡的每一關）：石台上的寶石，點亮的會發光（光在 fx）
func _p_sites(L, i: int) -> void:
	var sh: Dictionary = _shape[i]
	if not sh.has("sites"):
		return
	var u: Dictionary = Units.unit(ISLANDS[i].unit)
	var g = Game.of(self)
	for j in (sh.sites as Array).size():
		var sp: Vector2 = sh.sites[j]
		var lit: bool = j < u.levels.size() and Center.level_progress(g, u.levels[j].id) >= 0.999
		var lc: Color = u.levels[j].color if j < u.levels.size() else ISLANDS[i].col
		L.draw_colored_polygon(GW._ell(sp + Vector2(0, 10), 26, 10, 16), Color(0, 0, 0, 0.3))
		L.draw_colored_polygon(PackedVector2Array([sp + Vector2(-20, 8), sp + Vector2(20, 8), sp + Vector2(14, -6), sp + Vector2(-14, -6)]), Color("8a8098"))
		L.draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -40), sp + Vector2(12, -18), sp + Vector2(0, -4), sp + Vector2(-12, -18)]), lc if lit else Color("6a7090"))
		L.draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -40), sp + Vector2(0, -4), sp + Vector2(-12, -18)]), (lc if lit else Color("6a7090")).lightened(0.3))


func _p_trig(L, i: int) -> void:
	var sh: Dictionary = _shape[i]
	var pal := _pal(false)
	var o: Vector2 = sh.o
	var rr: float = sh.rr
	var rw: float = sh.rw
	var cp: Vector2 = sh.cp
	var dr: float = sh.dr
	var sc: Color = pal.shallow
	# 淺灘：圓環和羅盤礁外面一圈一圈
	for k in 4:
		var d := 300.0 - k * 75.0
		var a := 0.07 + 0.05 * k
		L.draw_arc(o, rr, 0, TAU, 160, Color(sc.r, sc.g, sc.b, a), rw + d * 2.0)
		_dot(L, cp, dr + d, Color(sc.r, sc.g, sc.b, a), 128)
	# 潟湖：中間深一點，邊緣淺
	var lag := rr - rw / 2.0
	_dot(L, o, lag + 4.0, Color("3a9cb0"), 128)
	_dot(L, o, lag * 0.72, Color("2d84a4"), 128)
	_dot(L, o, lag * 0.4, Color("2674a0"), 128)
	# 正弦海岸
	var band: PackedVector2Array = sh.band
	var inner := _land_layers(L, band, pal, 34.0, 30.0)
	# 圓環：崖壁 → 沙 → 草
	L.draw_arc(o + Vector2(0, 30), rr, 0, TAU, 160, pal.cliff_dk, rw)
	L.draw_arc(o + Vector2(0, 18), rr, 0, TAU, 160, pal.cliff, rw)
	L.draw_arc(o, rr, 0, TAU, 160, Color(1, 1, 1, 0.22), rw + 22.0)
	L.draw_arc(o, rr, 0, TAU, 160, pal.sand, rw)
	L.draw_arc(o, rr, 0, TAU, 160, pal.sand_hi, rw - 18.0)
	L.draw_arc(o, rr, 0, TAU, 160, pal.grass, rw - 52.0)
	L.draw_arc(o, rr, 0, TAU, 160, pal.rim, 3.0, true)
	# 羅盤礁：石砌的圓台、刻著八個方位的羅盤
	_dot(L, cp + Vector2(0, 26), dr, pal.cliff_dk, 128)
	_dot(L, cp + Vector2(0, 14), dr, pal.cliff, 128)
	_dot(L, cp, dr + 10.0, Color(1, 1, 1, 0.2), 128)
	_dot(L, cp, dr, pal.sand, 128)
	_dot(L, cp, dr * 0.78, Color("c9b79a"), 128)
	_dot(L, cp, dr * 0.72, Color("b4a284"), 128)
	for k in 8:
		var a := TAU * k / 8.0 - PI / 2.0
		var ln := dr * (0.68 if k % 2 == 0 else 0.42)
		var tip := cp + Vector2.from_angle(a) * ln
		var s1 := cp + Vector2.from_angle(a + PI / 2.0) * dr * 0.1
		var s2 := cp + Vector2.from_angle(a - PI / 2.0) * dr * 0.1
		L.draw_colored_polygon(PackedVector2Array([cp, s1, tip]), Color("f5c84c") if k % 2 == 0 else Color("e0d0b0"))
		L.draw_colored_polygon(PackedVector2Array([cp, tip, s2]), Color("c8962e") if k % 2 == 0 else Color("b0a080"))
	L.draw_arc(cp, dr * 0.75, 0, TAU, 64, Color("8a7a5a"), 4.0, true)
	for k in 16:
		var a := TAU * k / 16.0
		_rock(L, cp + Vector2.from_angle(a) * dr * 0.9, 0.6, pal.rock)
	# 圓環上十二根觀月石柱（每 30° 一根），夕陽從西北邊照過來，影子拉得很長
	for k in 12:
		var a := TAU * k / 12.0
		var b := o + Vector2(cos(a), -sin(a)) * rr
		L.draw_colored_polygon(PackedVector2Array([b + Vector2(-8, 2), b + Vector2(8, 2), b + Vector2(66, 64), b + Vector2(50, 66)]), Color(0, 0, 0, 0.22))
		L.draw_rect(Rect2(b + Vector2(-10, -52), Vector2(20, 54)), Color("b8aa98"))
		L.draw_rect(Rect2(b + Vector2(2, -52), Vector2(8, 54)), Color("8a7e70"))
		L.draw_rect(Rect2(b + Vector2(-13, -58), Vector2(26, 8)), Color("d8ccb8"))
	# 圓環上的椰子樹
	var ring_trees := []
	for k in 24:
		var a := TAU * (k + 0.5) / 24.0
		var side := 1.0 if k % 2 == 0 else -1.0
		ring_trees.append([o + Vector2(cos(a), -sin(a)) * (rr + side * rw * 0.22), k])
	ring_trees.sort_custom(func(x, y): return x[0].y < y[0].y)
	for q in ring_trees:
		_tree(L, q[0], 34.0, pal, "palm" if int(q[1]) % 3 != 0 else "round", float(q[1]) * 0.37)
	# 潟湖中間：月亮的倒影、小島上的終焉之塔
	blob(L, o + Vector2(-60, 70), Vector2(80, 30), Color(1.0, 0.96, 0.85, 0.35))
	for k in 3:
		L.draw_arc(o + Vector2(-60, 70), 60.0 + k * 26.0, PI * 0.1, PI * 0.9, 24, Color(1, 1, 1, 0.18 - k * 0.05), 2.0, true)
	_dot(L, o + Vector2(0, 16), 74.0, pal.cliff, 128)
	_dot(L, o, 74.0, pal.sand, 128)
	_dot(L, o, 54.0, pal.grass, 128)
	var tw := o + Vector2(0, 10)
	for k in 4:
		var w0 := 50.0 - k * 10.0
		var y0 := -k * 46.0
		L.draw_colored_polygon(PackedVector2Array([tw + Vector2(-w0 / 2, y0), tw + Vector2(w0 / 2, y0), tw + Vector2(w0 / 2 - 4, y0 - 46), tw + Vector2(-w0 / 2 + 4, y0 - 46)]), Color("b4a0e8").darkened(k * 0.06))
		L.draw_colored_polygon(PackedVector2Array([tw + Vector2(w0 * 0.15, y0), tw + Vector2(w0 / 2, y0), tw + Vector2(w0 / 2 - 4, y0 - 46), tw + Vector2(w0 * 0.15, y0 - 46)]), Color("8a76c0").darkened(k * 0.06))
		L.draw_rect(Rect2(tw + Vector2(-w0 / 2 - 4, y0 - 50), Vector2(w0 + 8, 6)), Color("d8ccff"))
	L.draw_colored_polygon(PackedVector2Array([tw + Vector2(-10, -184), tw + Vector2(10, -184), tw + Vector2(0, -236)]), Color("e8dcff"))
	_dot(L, tw + Vector2(0, -192), 9.0, Color("fff3d6"), 32)
	# 海岸上的小路、波峰和波谷的燈柱、村子
	var wave: PackedVector2Array = sh.wave
	L.draw_polyline(wave, Color("c8a878"), 10.0, true)
	var k0: float = sh.k
	var crest := []
	var xx := TM.WX0 + TM.PER * 0.25
	while xx < TM.X_END - 20.0:
		crest.append(_shape[i].o + (TM.wave_p(xx) - TM.O) * k0)
		xx += TM.PER * 0.5
	var avoid := [Rect2(cp - Vector2(dr, dr), Vector2(dr, dr) * 2.0).grow(30.0)]
	for q in crest:
		var p: Vector2 = q
		L.draw_line(p + Vector2(0, 4), p + Vector2(0, -64), Color("5a4a3a"), 5.0)
		L.draw_rect(Rect2(p + Vector2(-9, -80), Vector2(18, 18)), Color("ffd27a"))
		L.draw_rect(Rect2(p + Vector2(-9, -80), Vector2(18, 18)), Color("5a4a3a"), false, 2.0)
		avoid.append(Rect2(p - Vector2(60, 90), Vector2(120, 120)))
	for j in crest.size():
		if j % 2 == 0:
			var hp: Vector2 = (crest[j] as Vector2) + Vector2(70, 10)
			_house(L, hp, 1.0, Color("e8d8c0"), Color("b0564a"), true)
			avoid.append(Rect2(hp - Vector2(60, 80), Vector2(120, 100)))
	for s in sh.sites:
		avoid.append(Rect2((s as Vector2) - Vector2(40, 50), Vector2(80, 70)))
	_forest(L, inner, pal, 18, ["palm", "round", "round"], avoid, 13, 26.0, 36.0)
	_reefs(L, band, 22, 5)


func _p_exp(L, i: int) -> void:
	var sh: Dictionary = _shape[i]
	var pal := _pal(false)
	var k: float = sh.k
	var tf: Callable = sh.tf
	# 鏡面海峽：沿著 y = x 的那條線，一路淺淺的沙洲和踏腳石
	var ma: Vector2 = sh.ma
	var mb: Vector2 = sh.mb
	var md := (mb - ma).normalized()
	blob(L, (ma + mb) / 2.0, Vector2(ma.distance_to(mb) * 0.55, 110), Color(0.7, 0.9, 0.95, 0.0))
	var ln := ma.distance_to(mb)
	var band := PackedVector2Array([ma + md.orthogonal() * 46.0, mb + md.orthogonal() * 46.0, mb - md.orthogonal() * 46.0, ma - md.orthogonal() * 46.0])
	L.draw_colored_polygon(band, Color(0.75, 0.92, 0.95, 0.14))
	var inners := []
	for poly in sh.lands:
		inners.append(_land_layers(L, poly, pal, 30.0, 28.0))
	var st := 40.0
	while st < ln - 20.0:
		var p := ma + md * st
		var on := false
		for poly in sh.lands:
			if Geometry2D.is_point_in_polygon(p, poly):
				on = true
		if not on:
			L.draw_colored_polygon(GW._ell(p + Vector2(0, 6), 22, 10, 12), Color(0, 0, 0, 0.2))
			L.draw_colored_polygon(GW._ell(p, 20, 11, 12), Color("d8c8b0"))
		st += 56.0
	# 海峽兩端的方尖碑
	for e in [ma, mb]:
		var ep: Vector2 = e
		_dot(L, ep + Vector2(0, 14), 46.0, pal.cliff, 64)
		_dot(L, ep, 46.0, pal.sand_hi, 64)
		L.draw_colored_polygon(PackedVector2Array([ep + Vector2(-14, 0), ep + Vector2(14, 0), ep + Vector2(8, -120), ep + Vector2(0, -136), ep + Vector2(-8, -120)]), Color("d8d0e8"))
		L.draw_colored_polygon(PackedVector2Array([ep + Vector2(4, 0), ep + Vector2(14, 0), ep + Vector2(8, -120), ep + Vector2(0, -136)]), Color("a8a0c0"))
	# 兩座島的山丘：沿著島走，山丘一座比一座大（大小是 2 的次方倍）；兩座島在同樣的參數長得一樣大 → 互為倒影
	var hills := []
	for isle in 2:
		var u := -1.2
		while u <= 1.85:
			var p: Vector2 = tf.call(EM.isle_p(isle, u))
			hills.append([p, 16.0 + 15.0 * pow(2.0, u), isle])
			u += 0.42
	hills.sort_custom(func(a, b): return a[0].y < b[0].y)
	for hl in hills:
		var p: Vector2 = hl[0]
		var r: float = hl[1]
		L.draw_colored_polygon(GW._ell(p + Vector2(r * 0.3, r * 0.5), r * 1.3, r * 0.55, 20), Color(0, 0, 0, 0.22))
		L.draw_colored_polygon(GW._ell(p + Vector2(0, r * 0.18), r * 1.24, r * 0.82, 24), pal.cliff)
		L.draw_colored_polygon(GW._ell(p, r * 1.2, r * 0.8, 24), pal.grass.darkened(0.12))
		L.draw_colored_polygon(GW._ell(p + Vector2(-r * 0.2, -r * 0.22), r * 0.9, r * 0.55, 24), pal.grass_hi)
		L.draw_colored_polygon(GW._ell(p + Vector2(-r * 0.32, -r * 0.34), r * 0.42, r * 0.24, 16), pal.high)
	# 天文台小島：圓頂和望遠鏡
	var ob: Vector2 = sh.obs
	L.draw_colored_polygon(GW._ell(ob + Vector2(8, 14), 64, 20, 20), Color(0, 0, 0, 0.3))
	L.draw_rect(Rect2(ob + Vector2(-50, -30), Vector2(100, 34)), Color("d8d4e4"))
	L.draw_colored_polygon(GW._ell(ob + Vector2(0, -30), 50, 46, 24, PI, TAU), Color("e8e6f2"))
	L.draw_colored_polygon(GW._ell(ob + Vector2(14, -30), 30, 42, 20, PI * 1.5, TAU), Color("c4c0d6"))
	L.draw_line(ob + Vector2(-4, -50), ob + Vector2(40, -104), Color("3a3a50"), 12.0, true)
	L.draw_rect(Rect2(ob + Vector2(-12, -20), Vector2(24, 24)), Color("3a3046"))
	# 塔（單元地圖裡那座）
	var tp: Vector2 = sh.tower
	L.draw_colored_polygon(GW._ell(tp + Vector2(10, 6), 30, 10, 14), Color(0, 0, 0, 0.3))
	L.draw_colored_polygon(PackedVector2Array([tp + Vector2(-16, 0), tp + Vector2(16, 0), tp + Vector2(10, -130), tp + Vector2(-10, -130)]), Color("e0c88a"))
	L.draw_colored_polygon(PackedVector2Array([tp + Vector2(4, 0), tp + Vector2(16, 0), tp + Vector2(10, -130), tp + Vector2(4, -130)]), Color("b89a5a"))
	L.draw_colored_polygon(PackedVector2Array([tp + Vector2(-16, -128), tp + Vector2(16, -128), tp + Vector2(0, -166)]), Color("c8562e"))
	L.draw_rect(Rect2(tp + Vector2(-5, -100), Vector2(10, 14)), Color("ffd27a"))
	# 村子、樹
	var avoid := [Rect2(ob - Vector2(80, 120), Vector2(160, 160)), Rect2(tp - Vector2(40, 180), Vector2(80, 200))]
	for s in sh.sites:
		avoid.append(Rect2((s as Vector2) - Vector2(40, 50), Vector2(80, 70)))
	for hl in hills:
		avoid.append(Rect2((hl[0] as Vector2) - Vector2(hl[1], hl[1]) * 1.2, Vector2(hl[1], hl[1]) * 2.4))
	for isle in 2:
		for u in [-0.6, 0.6]:
			var hp: Vector2 = tf.call(EM.isle_p(isle, u)) + Vector2(40, 20)
			_house(L, hp, 0.9, Color("efe0c8"), Color("c0703a"), true)
			avoid.append(Rect2(hp - Vector2(50, 70), Vector2(100, 90)))
	for j in 2:
		_forest(L, inners[j], pal, 12, ["round", "palm", "round"], avoid, 21 + j, 24.0, 34.0)
	for poly in sh.lands:
		_reefs(L, poly, 10, 9)


## 箭羽高原：高高的台地、照兩個方向排成平行四邊形的田、箭形的大石碑、一叢叢像羽毛的芒草、從崖邊落下的小瀑布
func _p_vec2(L, i: int) -> void:
	var isl: Dictionary = ISLANDS[i]
	var sh: Dictionary = _shape[i]
	var pal := _pal(false)
	var c: Vector2 = isl.c
	var poly: PackedVector2Array = sh.lands[0]
	var inner := _land_layers(L, poly, pal, 120.0, 40.0)
	if inner.size() < 3:
		return
	# 崖壁的岩層紋
	var cl := Geometry2D.clip_polygons(GW._shift(poly, Vector2(0, 120)), poly)
	for pc in cl:
		var pp: PackedVector2Array = pc
		for k in 4:
			var y := 30.0 + k * 24.0
			var seg := PackedVector2Array()
			for q in pp:
				var qq := q + Vector2(0, -120.0 + y)
				if Geometry2D.is_point_in_polygon(qq, pp):
					seg.append(qq)
			if seg.size() > 1:
				L.draw_polyline(seg, Color(0, 0, 0, 0.14), 3.0)
	# 田：沿著兩個方向（a、b）排成平行四邊形，三種作物輪流
	var a := Vector2(150, -46)
	var b := Vector2(52, 120)
	var field_area := GW._off(inner, -40.0)
	var mon := c + Vector2(-260, -60)
	var crops := [Color("d8b45a"), Color("8fa24e"), Color("a990c8"), Color("c48a4a")]
	for ii in range(-6, 7):
		for jj in range(-4, 5):
			var o := c + a * ii + b * jj + Vector2(80, 40)
			var q := PackedVector2Array([o, o + a, o + a + b, o + b])
			var ctr := o + (a + b) / 2.0
			if ctr.distance_to(mon) < 330.0:
				continue
			for pc in Geometry2D.intersect_polygons(q, field_area):
				var col: Color = crops[posmod(ii * 2 + jj * 3, 4)]
				L.draw_colored_polygon(GW._off(pc, -5.0) if GW._off(pc, -5.0).size() >= 3 else pc, col)
				# 田裡的壟（和 a 平行）
				var fl := PackedVector2Array()
				for k in range(1, 4):
					var s0 := o + b * (k / 4.0)
					var s1 := s0 + a
					if Geometry2D.is_point_in_polygon(s0 + a * 0.1, pc) and Geometry2D.is_point_in_polygon(s1 - a * 0.1, pc):
						fl.append_array([s0 + a * 0.08, s1 - a * 0.08])
				if not fl.is_empty():
					L.draw_multiline(fl, col.darkened(0.18), 2.0)
	# 田埂上的小路
	for jj in range(-4, 5):
		var o := c + b * jj + Vector2(80, 40)
		var seg := PackedVector2Array()
		for ii in range(-7, 8):
			var p := o + a * ii
			if Geometry2D.is_point_in_polygon(p, field_area):
				seg.append(p)
		if seg.size() > 1:
			L.draw_polyline(seg, Color("b89a6a"), 5.0)
	# 箭形的大石碑：躺在小丘上，指向東北；箭尾有三對箭羽
	_dot(L, mon + Vector2(20, 40), 220.0, Color(0, 0, 0, 0.12), 128)
	L.draw_colored_polygon(GW._ell(mon, 230, 130, 40), pal.grass_hi)
	L.draw_colored_polygon(GW._ell(mon + Vector2(-30, -26), 150, 76, 32), pal.high)
	var ad := Vector2(1.0, -0.55).normalized()
	var an := ad.orthogonal()
	var tail := mon - ad * 170.0
	var head := mon + ad * 150.0
	L.draw_colored_polygon(PackedVector2Array([tail + an * 12 + Vector2(10, 18), head + an * 12 + Vector2(10, 18), head - an * 12 + Vector2(10, 18), tail - an * 12 + Vector2(10, 18)]), Color(0, 0, 0, 0.25))
	L.draw_colored_polygon(PackedVector2Array([tail + an * 12, head + an * 12, head - an * 12, tail - an * 12]), Color("c8c0b0"))
	L.draw_colored_polygon(PackedVector2Array([tail + an * 12, head + an * 12, head + an * 2, tail + an * 2]), Color("e0d8c8"))
	L.draw_colored_polygon(PackedVector2Array([head + an * 40, head + ad * 76, head - an * 40]), Color("b8ae9a"))
	L.draw_colored_polygon(PackedVector2Array([head + an * 40, head + ad * 76, head]), Color("d8d0c0"))
	for k in 3:
		var fp := tail + ad * (16.0 + k * 34.0)
		for sd in [-1.0, 1.0]:
			L.draw_colored_polygon(PackedVector2Array([fp + an * 10 * sd, fp + an * 54 * sd - ad * 30, fp + an * 54 * sd - ad * 6, fp + an * 10 * sd + ad * 20]), Color("d86a5a") if k % 2 == 0 else Color("f0e0c8"))
	# 風向標（全部指著同一個風向）
	var vanes := [c + Vector2(360, -220), c + Vector2(420, 180), c + Vector2(-120, 280), c + Vector2(80, -300)]
	for vp in vanes:
		var p: Vector2 = vp
		L.draw_line(p + Vector2(0, 4), p + Vector2(0, -90), Color("5a4a3a"), 5.0)
		L.draw_colored_polygon(PackedVector2Array([p + Vector2(-34, -96), p + Vector2(26, -96), p + Vector2(26, -104), p + Vector2(42, -92), p + Vector2(26, -80), p + Vector2(26, -88), p + Vector2(-34, -88)]), Color("2a3046"))
		L.draw_colored_polygon(PackedVector2Array([p + Vector2(-34, -98), p + Vector2(-48, -110), p + Vector2(-40, -92), p + Vector2(-48, -74), p + Vector2(-34, -86)]), Color("d86a5a"))
	# 石屋和防風林
	_house(L, c + Vector2(420, -40), 1.2, Color("d8cdb8"), Color("6a7a9a"), true)
	_house(L, c + Vector2(500, 40), 1.0, Color("d8cdb8"), Color("8a5a4a"), true)
	# 崖邊的芒草：一叢叢像箭羽
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	var edge := _coast_samples(inner, 60.0)
	for k in edge.size():
		if k % 2 == 1:
			continue
		var s: Array = edge[k]
		var p: Vector2 = s[0] - (s[1] as Vector2) * rng.randf_range(10, 40)
		for j in 5:
			var ang := -PI / 2.0 + (j - 2) * 0.22 + 0.35
			var tip := p + Vector2.from_angle(ang) * rng.randf_range(34, 50)
			var mid := p + Vector2.from_angle(ang - 0.12) * 18.0
			L.draw_polyline(PackedVector2Array([p, mid, tip]), Color("c8b080"), 3.0, true)
			L.draw_colored_polygon(GW._ell(tip, 5, 12, 10), Color("f6ead0"))
	# 從崖邊落下的小瀑布（在南邊）
	var wf := c + Vector2(120, 0)
	for q in poly:
		if q.y > wf.y and absf(q.x - (c.x + 120.0)) < 30.0:
			wf = q
	L.draw_polyline(PackedVector2Array([wf + Vector2(0, -160), wf + Vector2(-10, -60), wf + Vector2(0, -4)]), Color("6ab8e8"), 28.0, true)
	L.draw_polygon(PackedVector2Array([wf + Vector2(-16, 0), wf + Vector2(16, 0), wf + Vector2(22, 120), wf + Vector2(-22, 120)]),
		PackedColorArray([Color("9ad8f5"), Color("9ad8f5"), Color("eaf8ff"), Color("eaf8ff")]))
	blob(L, wf + Vector2(0, 130), Vector2(70, 26), Color(1, 1, 1, 0.5))
	var avoid := [Rect2(mon - Vector2(260, 160), Vector2(520, 300)), Rect2(c + Vector2(340, -120), Vector2(240, 220))]
	for vp in vanes:
		avoid.append(Rect2((vp as Vector2) - Vector2(60, 120), Vector2(120, 140)))
	# 樹只長在田外面（邊緣一圈）
	var ring_area := GW._ring(inner, GW._off(inner, -150.0))
	for j in ring_area.size():
		_forest(L, ring_area[j], pal, 10, ["round", "round", "pine"], avoid, 81 + j, 26.0, 36.0)
	_reefs(L, poly, 14, 17)
	# 岸邊礁石上的海豹
	var sp := _coast_samples(poly, 200.0)
	if sp.size() > 3:
		var sr: Array = sp[3]
		var p: Vector2 = sr[0] + (sr[1] as Vector2) * 120.0
		_rock(L, p, 2.2, Color("7a7080"))
		L.draw_colored_polygon(GW._ell(p + Vector2(4, -26), 30, 14, 16), Color("6a6a7a"))
		L.draw_colored_polygon(GW._ell(p + Vector2(30, -36), 13, 11, 12), Color("7a7a8a"))
		_dot(L, p + Vector2(36, -40), 2.0, Color("1a1a22"), 16)


## 立方浮島：底下的岩石小島、浮在空中的方塊（地上有它們的影子）、方塊上的格線、三根互相垂直的水晶、從方塊邊緣落下的光瀑
func _p_vec3(L, i: int) -> void:
	var isl: Dictionary = ISLANDS[i]
	var sh: Dictionary = _shape[i]
	var pal := _pal(true)
	var c: Vector2 = isl.c
	var poly: PackedVector2Array = sh.lands[0]
	var inner := _land_layers(L, poly, pal, 60.0, 34.0)
	# 岩石小島上的水晶叢
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for k in 9:
		var p := c + Vector2(rng.randf_range(-380, 380), rng.randf_range(-120, 300))
		if inner.size() < 3 or not Geometry2D.is_point_in_polygon(p, inner):
			continue
		for j in 3:
			var q := p + Vector2((j - 1) * 14.0, 0)
			var hgt := rng.randf_range(30, 60)
			L.draw_colored_polygon(PackedVector2Array([q + Vector2(-9, 0), q + Vector2(0, -hgt), q + Vector2(9, 0), q + Vector2(0, 8)]), Color("8a6ad6"))
			L.draw_colored_polygon(PackedVector2Array([q + Vector2(-9, 0), q + Vector2(0, -hgt), q + Vector2(0, 8)]), Color("c6aaff"))
	_forest(L, inner, pal, 8, ["pine", "glow"], [Rect2(c - Vector2(300, 260), Vector2(600, 460))], 93, 24.0, 32.0)
	# 方塊：[相對島中心的位置, 半寬, 浮起來的高度]（照前後順序畫）
	var cubes := [[Vector2(-220, -250), 64.0, 330.0], [Vector2(300, -40), 110.0, 290.0], [Vector2(0, -40), 170.0, 220.0], [Vector2(-330, 60), 92.0, 150.0], [Vector2(150, 230), 72.0, 120.0]]
	cubes.sort_custom(func(x, y): return x[0].y < y[0].y)
	# 先畫影子（在地上／海面上，看得出方塊浮在空中）
	for cb in cubes:
		var g0: Vector2 = c + (cb[0] as Vector2)
		var s: float = cb[1]
		L.draw_colored_polygon(PackedVector2Array([g0 + Vector2(0, -s * 0.5), g0 + Vector2(s, 0), g0 + Vector2(0, s * 0.5), g0 + Vector2(-s, 0)]), Color(0, 0, 0.05, 0.35))
	for cb in cubes:
		var g0: Vector2 = c + (cb[0] as Vector2)
		var s: float = cb[1]
		var h: float = cb[2]
		var tp := g0 - Vector2(0, h)
		var d := s * 0.95
		var top := PackedVector2Array([tp + Vector2(0, -s * 0.5), tp + Vector2(s, 0), tp + Vector2(0, s * 0.5), tp + Vector2(-s, 0)])
		var left := PackedVector2Array([tp + Vector2(-s, 0), tp + Vector2(0, s * 0.5), tp + Vector2(0, s * 0.5 + d), tp + Vector2(-s, d)])
		var right := PackedVector2Array([tp + Vector2(0, s * 0.5), tp + Vector2(s, 0), tp + Vector2(s, d), tp + Vector2(0, s * 0.5 + d)])
		L.draw_polygon(left, PackedColorArray([Color("3a3270"), Color("332b66"), Color("1e1a44"), Color("231e4c")]))
		L.draw_polygon(right, PackedColorArray([Color("2a2458"), Color("4a3e8a"), Color("2a2458"), Color("181438")]))
		# 底下垂著的岩石和根
		L.draw_colored_polygon(PackedVector2Array([tp + Vector2(-s, d), tp + Vector2(0, s * 0.5 + d), tp + Vector2(s, d), tp + Vector2(s * 0.3, d + s * 0.9), tp + Vector2(-s * 0.2, d + s * 1.1)]), Color("1a1838"))
		L.draw_colored_polygon(top, Color("4e6a8a"))
		L.draw_colored_polygon(GW._shift(PackedVector2Array([tp + Vector2(0, -s * 0.5), tp + Vector2(s, 0), tp + Vector2(0, s * 0.5), tp + Vector2(-s, 0)]), Vector2(0, 0)), Color("4e6a8a"))
		# 上面的草和格線
		var grass := PackedVector2Array()
		for q in top:
			grass.append(tp + (q - tp) * 0.9)
		L.draw_colored_polygon(grass, Color("2f5a5e"))
		var gl := PackedVector2Array()
		for k in range(1, 4):
			var f := k / 4.0
			gl.append_array([top[0].lerp(top[3], f), top[1].lerp(top[2], f)])
			gl.append_array([top[0].lerp(top[1], f), top[3].lerp(top[2], f)])
		L.draw_multiline(gl, Color(0.6, 0.9, 1.0, 0.35), 2.0)
		L.draw_polyline(PackedVector2Array([top[3], top[0], top[1]]), Color("8ab8d8"), 3.0, true)
		L.draw_line(top[3], left[2] - Vector2(0, s * 0.5) + Vector2(0, s * 0.5 - s * 0.5), Color(0, 0, 0, 0), 1.0)
		L.draw_line(tp + Vector2(0, s * 0.5), tp + Vector2(0, s * 0.5 + d), Color("6a5aa8"), 2.0)
		# 大方塊上面：三根互相垂直的水晶（從同一個角長出來）、小樹
		if s > 150.0:
			var corner := top[3].lerp(top[0], 0.25) + Vector2(s * 0.35, 0)
			var axes := [[Vector2(1.0, 0.5).normalized() * 150.0, Color("ff7a8a")], [Vector2(-1.0, 0.5).normalized() * 150.0, Color("7affb0")], [Vector2(0, -170), Color("7ab8ff")]]
			for ax in axes:
				var v: Vector2 = ax[0]
				var n := v.normalized().orthogonal() * 10.0
				var col: Color = ax[1]
				L.draw_colored_polygon(PackedVector2Array([corner + n, corner + v * 0.92 + n, corner + v, corner + v * 0.92 - n, corner - n]), col.darkened(0.25))
				L.draw_colored_polygon(PackedVector2Array([corner + n, corner + v * 0.92 + n, corner + v, corner]), col.lightened(0.25))
			_dot(L, corner, 14.0, Color("f0f0ff"), 32)
			for q in [Vector2(-70, -10), Vector2(-40, 20), Vector2(60, 26)]:
				_tree(L, tp + q, 22.0, pal, "glow", q.x * 0.01)
		# 光瀑：從方塊前緣落到下面
		if s > 100.0:
			var fp := tp + Vector2(s * 0.45, s * 0.28 + d)
			L.draw_polygon(PackedVector2Array([fp + Vector2(-14, -d * 0.6), fp + Vector2(14, -d * 0.6), fp + Vector2(20, h - d - 10), fp + Vector2(-20, h - d - 10)]),
				PackedColorArray([Color(0.6, 0.9, 1.0, 0.8), Color(0.6, 0.9, 1.0, 0.8), Color(0.8, 0.95, 1.0, 0.2), Color(0.8, 0.95, 1.0, 0.2)]))
	_reefs(L, poly, 12, 19)


## 平面峽灣：峽灣的兩道岩壁是直的，在最裡面交成一條線（那條線一路延伸成山脊）；平頂的雪山、纜車、峽灣盡頭的漁村
func _p_plane(L, i: int) -> void:
	var isl: Dictionary = ISLANDS[i]
	var sh: Dictionary = _shape[i]
	var pal := _pal(true)
	var c: Vector2 = isl.c
	var poly: PackedVector2Array = sh.lands[0]
	var ma: Vector2 = sh.ma
	var mb: Vector2 = sh.mb
	var apex: Vector2 = sh.apex
	# 峽灣裡的水比較深、像鏡子
	L.draw_colored_polygon(PackedVector2Array([ma + (ma - apex).normalized() * 160.0, apex, mb + (mb - apex).normalized() * 160.0]), Color(0.02, 0.05, 0.14, 0.45))
	var inner := _land_layers(L, poly, pal, 70.0, 30.0)
	# 兩道岩壁（平面）：一條條平行的岩層，壁頂亮、壁面暗
	for wall in [[ma, apex, 1.0], [mb, apex, -1.0]]:
		var a: Vector2 = wall[0]
		var b: Vector2 = wall[1]
		var d := (b - a).normalized()
		var n := d.orthogonal() * float(wall[2])
		# n 指向陸地那一側
		if Geometry2D.is_point_in_polygon((a + b) / 2.0 + n * 40.0, poly) == false:
			n = -n
		var face := PackedVector2Array([a + n * 4.0, b + n * 4.0, b + n * 120.0, a + n * 120.0])
		L.draw_polygon(face, PackedColorArray([Color("0e162c"), Color("0e162c"), Color("3a5478"), Color("3a5478")]))
		var st := PackedVector2Array()
		for k in range(1, 6):
			var f := k / 6.0
			st.append_array([a + n * (4.0 + 116.0 * f), b + n * (4.0 + 116.0 * f)])
		L.draw_multiline(st, Color(0.55, 0.7, 0.9, 0.22), 2.0)
		L.draw_line(a + n * 120.0, b + n * 120.0, Color("9ab8e0"), 4.0, true)
	# 兩道岩壁交成的那條線：一路往內陸延伸成筆直的山脊
	var ax := (apex - (ma + mb) / 2.0).normalized()
	var ridge_end := apex + ax * 520.0
	L.draw_line(apex, ridge_end, Color("dfe9ff"), 10.0, true)
	L.draw_line(apex + ax.orthogonal() * 6.0, ridge_end + ax.orthogonal() * 6.0, Color("8aa4cc"), 6.0, true)
	# 平頂的雪山（台地）：邊是直的
	var mesas := [[c + Vector2(300, -230), 150.0, 0.2], [c + Vector2(420, 170), 130.0, -0.3], [c + Vector2(-240, 270), 120.0, 0.5]]
	for ms in mesas:
		var p: Vector2 = ms[0]
		var r: float = ms[1]
		var rot: float = ms[2]
		var hx := PackedVector2Array()
		for k in 6:
			hx.append(p + Vector2.from_angle(TAU * k / 6.0 + rot) * Vector2(r, r * 0.6).length() * Vector2(1.0, 0.6))
		var side := PackedVector2Array()
		for q in hx:
			side.append(q + Vector2(0, 50))
		L.draw_colored_polygon(GW._shift(hx, Vector2(0, 54)), Color("0a1022"))
		for k in 6:
			var q0 := hx[k]
			var q1 := hx[(k + 1) % 6]
			if q0.y + q1.y > p.y * 2.0 - 10.0:
				L.draw_colored_polygon(PackedVector2Array([q0, q1, q1 + Vector2(0, 54), q0 + Vector2(0, 54)]), Color("26365a"))
		L.draw_colored_polygon(hx, Color("dfe9ff"))
		var inn := PackedVector2Array()
		for q in hx:
			inn.append(p + (q - p) * 0.75 + Vector2(-6, -4))
		L.draw_colored_polygon(inn, Color("f4f8ff"))
	# 纜車：兩座塔、一條筆直的纜線橫過峽灣（穿過岩壁）
	var t1 := ma.lerp(apex, 0.45) + (apex - ma).normalized().orthogonal() * -170.0
	var t2 := mb.lerp(apex, 0.45) + (apex - mb).normalized().orthogonal() * 170.0
	if not Geometry2D.is_point_in_polygon(t1, poly):
		t1 = ma.lerp(apex, 0.45) + (apex - ma).normalized().orthogonal() * 170.0
	if not Geometry2D.is_point_in_polygon(t2, poly):
		t2 = mb.lerp(apex, 0.45) + (apex - mb).normalized().orthogonal() * -170.0
	sh["cable"] = [t1, t2]
	for tp in [t1, t2]:
		var q: Vector2 = tp
		L.draw_colored_polygon(GW._ell(q + Vector2(10, 8), 30, 10, 12), Color(0, 0, 0, 0.3))
		L.draw_colored_polygon(PackedVector2Array([q + Vector2(-16, 0), q + Vector2(16, 0), q + Vector2(6, -110), q + Vector2(-6, -110)]), Color("5a6a8a"))
		L.draw_line(q + Vector2(-14, -20), q + Vector2(10, -70), Color("3a4a6a"), 3.0)
		L.draw_line(q + Vector2(14, -20), q + Vector2(-10, -70), Color("3a4a6a"), 3.0)
		L.draw_rect(Rect2(q + Vector2(-20, -118), Vector2(40, 10)), Color("8a9ab8"))
	L.draw_line(t1 + Vector2(0, -112), t2 + Vector2(0, -112), Color("c8d4ea"), 3.0, true)
	# 峽灣盡頭的漁村、小船
	var head := apex + ax * 120.0
	var vill := [head + Vector2(-60, -110), head + Vector2(40, -130), head + Vector2(-30, 110), head + Vector2(70, 120)]
	for hp in vill:
		_house(L, hp, 0.9, Color("c8d0e4"), Color("8a3a4a"), true)
	for k in 2:
		var bp := apex - ax * (140.0 + k * 120.0)
		L.draw_colored_polygon(PackedVector2Array([bp + Vector2(-34, -8), bp + Vector2(34, -8), bp + Vector2(24, 10), bp + Vector2(-24, 10)]), Color("8a5a3a"))
		L.draw_line(bp + Vector2(0, -8), bp + Vector2(0, -50), Color("5a3a22"), 3.0)
	var avoid := [Rect2(head - Vector2(140, 200), Vector2(280, 380)), Rect2(apex - Vector2(80, 80), Vector2(600, 160))]
	for ms in mesas:
		avoid.append(Rect2((ms[0] as Vector2) - Vector2(ms[1], ms[1]) * 1.1, Vector2(ms[1], ms[1]) * 2.2))
	for tp in [t1, t2]:
		avoid.append(Rect2((tp as Vector2) - Vector2(50, 130), Vector2(100, 150)))
	# 樹不要長在岩壁上
	var safe := inner
	_forest(L, safe, pal, 34, ["pine", "pine", "glow"], avoid + [_wall_box(ma, apex), _wall_box(mb, apex)], 101, 24.0, 36.0)
	_reefs(L, poly, 12, 23)


static func _wall_box(a: Vector2, b: Vector2) -> Rect2:
	return Rect2(a, Vector2.ZERO).expand(b).grow(150.0)


## 機率樹海：紅樹林的根拱進海裡、整片樹冠、正中央的巨樹（一路分岔兩次、三次，像樹狀圖），每一枝結著不同顏色的燈果
func _p_prob(L, i: int) -> void:
	var isl: Dictionary = ISLANDS[i]
	var sh: Dictionary = _shape[i]
	var pal := _pal(true)
	var c: Vector2 = isl.c
	var poly: PackedVector2Array = sh.lands[0]
	# 紅樹林的根（在岸邊的淺水裡拱起來）
	var rng := RandomNumberGenerator.new()
	rng.seed = 111
	for s in _coast_samples(poly, 46.0):
		var p: Vector2 = s[0]
		var n: Vector2 = s[1]
		for j in 2:
			var b := p + n * rng.randf_range(10, 40) + n.orthogonal() * rng.randf_range(-20, 20)
			var e := b + n * rng.randf_range(30, 60) + n.orthogonal() * rng.randf_range(-24, 24)
			var m := (b + e) / 2.0 + n * 24.0
			L.draw_polyline(PackedVector2Array([b, b.lerp(m, 0.5) + n * 6.0, m, m.lerp(e, 0.5) + n * 4.0, e]), Color("3a2a2a"), 4.0, true)
	var inner := _land_layers(L, poly, pal, 40.0, 26.0)
	# 小路：從碼頭往巨樹走，在半路分成兩條，繞到樹的兩邊（岔口有一盞燈）
	var shore: Vector2 = _shores[i]
	var root := c + Vector2(0, 210)
	var fork := shore.lerp(c, 0.45)
	L.draw_polyline(PackedVector2Array([shore, fork]), Color("5a4c44"), 14.0, true)
	for sd in [-1.0, 1.0]:
		L.draw_polyline(GW._smooth_open([fork, fork.lerp(root, 0.4) + Vector2(300 * sd, 0), root + Vector2(160 * sd, 40)], 8), Color("5a4c44"), 12.0, true)
	L.draw_line(fork + Vector2(30, 0), fork + Vector2(30, -70), Color("3a2a22"), 5.0)
	# 樹冠：島上鋪滿（中間留給巨樹）
	var giant := Rect2(c - Vector2(560, 360), Vector2(1120, 640))
	_forest(L, inner, pal, 60, ["glow", "glow", "pine"], [giant, Rect2(fork - Vector2(60, 100), Vector2(120, 140))], 113, 28.0, 44.0)
	# 巨樹：樹幹往上分兩枝、每枝再分兩枝、再分兩枝（共八個枝頭），左右兩邊的燈果顏色不一樣
	var base := c + Vector2(0, 210)
	var top := c + Vector2(0, 30)
	blob(L, c + Vector2(30, 120), Vector2(560, 260), Color(0, 0, 0, 0.32))
	blob(L, c + Vector2(0, -60), Vector2(620, 360), Color(1.0, 0.85, 0.55, 0.08))
	# 板根：往四周伸開
	for k in 7:
		var a := PI * (0.05 + 0.9 * k / 6.0)
		var e := base + Vector2(cos(a) * 130.0, sin(a) * 50.0) + Vector2(0, -6)
		L.draw_polyline(PackedVector2Array([base + Vector2((k - 3) * 10.0, -20), base.lerp(e, 0.5) + Vector2(0, -12), e]), Color("3a2a30"), 16.0, true)
		L.draw_polyline(PackedVector2Array([base + Vector2((k - 3) * 10.0, -24), base.lerp(e, 0.5) + Vector2(0, -16), e]), Color("5a4048"), 5.0, true)
	L.draw_colored_polygon(PackedVector2Array([base + Vector2(-58, 0), base + Vector2(58, 0), top + Vector2(30, 0), top + Vector2(-30, 0)]), Color("3a2a30"))
	L.draw_colored_polygon(PackedVector2Array([base + Vector2(-58, 0), base + Vector2(-18, 0), top + Vector2(-8, 0), top + Vector2(-30, 0)]), Color("5a4048"))
	var tips := []
	var lv := [[top, Vector2(0, -1), 0, 0]]
	var lens := [170.0, 135.0, 100.0]
	var spread := [0.72, 0.52, 0.4]
	for depth in 3:
		var nxt := []
		for bq in lv:
			var p: Vector2 = bq[0]
			var d: Vector2 = bq[1]
			for sd in [-1.0, 1.0]:
				var nd: Vector2 = d.rotated(sd * float(spread[depth]))
				var e: Vector2 = p + Vector2(nd.x, nd.y * 0.72) * float(lens[depth])
				var w := 30.0 - depth * 8.0
				var bend: Vector2 = p.lerp(e, 0.5) + nd.orthogonal() * sd * 10.0
				L.draw_polyline(PackedVector2Array([p, bend, e]), Color("3a2a30"), w, true)
				L.draw_polyline(PackedVector2Array([p + Vector2(-w * 0.2, 0), bend + Vector2(-w * 0.2, 0), e]), Color("5a4048"), w * 0.3, true)
				var side: int = int(bq[2]) if depth > 0 else (0 if sd < 0 else 1)
				nxt.append([e, nd, side, int(bq[3]) * 2 + (0 if sd < 0 else 1)])
		lv = nxt
	tips = lv
	var tc: Array = pal.tree
	tips.sort_custom(func(x, y): return x[0].y < y[0].y)
	for tp in tips:
		var p: Vector2 = tp[0]
		_dot(L, p + Vector2(0, 18), 104.0, tc[0].darkened(0.2), 128)
		_dot(L, p + Vector2(-30, 8), 80.0, tc[0], 128)
		_dot(L, p + Vector2(34, 10), 76.0, tc[0], 128)
		_dot(L, p, 82.0, tc[1], 128)
		_dot(L, p + Vector2(-22, -24), 50.0, tc[2], 128)
		_dot(L, p + Vector2(-30, -34), 16.0, tc[3], 64)
	# 燈果：左半邊是暖色、右半邊是冷色（每個枝頭還分兩種深淺）
	for tp in tips:
		var p: Vector2 = tp[0]
		var warm: bool = int(tp[2]) == 0
		var fc := Color("ffb35a") if warm else Color("8ff0ff")
		var fc2 := Color("ff7a5a") if warm else Color("c6a6ff")
		for k in 6:
			var q := p + Vector2.from_angle(TAU * k / 6.0 + float(tp[3])) * 52.0 + Vector2(0, 20)
			L.draw_line(q + Vector2(0, -18), q, Color("2a2030"), 2.0)
			_dot(L, q + Vector2(0, 5), 11.0, fc if (k + int(tp[3])) % 2 == 0 else fc2, 32)
			_dot(L, q + Vector2(-3, 2), 4.0, Color(1, 1, 1, 0.7), 16)
	# 發光的菇
	for k in 14:
		var p := c + Vector2(rng.randf_range(-600, 600), rng.randf_range(-260, 320))
		if inner.size() < 3 or not Geometry2D.is_point_in_polygon(p, inner) or giant.has_point(p):
			continue
		for j in 3:
			var q := p + Vector2((j - 1) * 12.0, (j % 2) * 6.0)
			L.draw_rect(Rect2(q + Vector2(-2, -10), Vector2(4, 10)), Color("d8d0e8"))
			L.draw_colored_polygon(GW._ell(q + Vector2(0, -10), 9, 6, 12, PI, TAU), Color("7affd2"))


## 矩陣城：方正的島、運河把城市切成一行一行、一列一列的街區；中央廣場的地磚（會轉的在 fx）、鐘塔、拱橋
func _p_matrix(L, i: int) -> void:
	var isl: Dictionary = ISLANDS[i]
	var sh: Dictionary = _shape[i]
	var pal := _pal(true)
	pal.sand = Color("5a6488")
	pal.sand_hi = Color("6e7aa0")
	pal.grass = Color("2a3456")
	var c: Vector2 = isl.c
	var poly: PackedVector2Array = sh.lands[0]
	_land_layers(L, poly, pal, 60.0, 30.0)
	var r: Vector2 = isl.r
	var area := Rect2(c - r + Vector2(80, 80), r * 2.0 - Vector2(160, 160))
	var rows := 3
	var cols := 5
	var cw := 54.0
	var bw := (area.size.x - cw * (cols - 1)) / cols
	var bh := (area.size.y - cw * (rows - 1)) / rows
	sh["blocks"] = []
	# 運河
	for k in range(1, cols):
		var x := area.position.x + k * (bw + cw) - cw
		L.draw_rect(Rect2(x, area.position.y - 80, cw, area.size.y + 160), Color("1d4470"))
		L.draw_line(Vector2(x + cw * 0.5, area.position.y - 70), Vector2(x + cw * 0.5, area.end.y + 70), Color(0.6, 0.8, 1.0, 0.12), 6.0)
	for k in range(1, rows):
		var y := area.position.y + k * (bh + cw) - cw
		L.draw_rect(Rect2(area.position.x - 80, y, area.size.x + 160, cw), Color("1d4470"))
		L.draw_line(Vector2(area.position.x - 70, y + cw * 0.5), Vector2(area.end.x + 70, y + cw * 0.5), Color(0.6, 0.8, 1.0, 0.12), 6.0)
	# 街區
	var rng := RandomNumberGenerator.new()
	rng.seed = 131
	var mid := Vector2i(cols / 2, rows / 2)
	var bl := []
	for rr in rows:
		for cc in cols:
			var br := Rect2(area.position + Vector2(cc * (bw + cw), rr * (bh + cw)), Vector2(bw, bh))
			bl.append([br, Vector2i(cc, rr)])
	for e in bl:
		var br: Rect2 = e[0]
		L.draw_rect(br, Color("3a4468"))
		L.draw_rect(br.grow(-6.0), Color("323b5e"))
		L.draw_rect(br, Color("6a74a0"), false, 3.0)
	for e in bl:
		var br: Rect2 = e[0]
		var id: Vector2i = e[1]
		if id == mid:
			# 中央廣場：3×3 的地磚
			var tile := Vector2(br.size.x / 3.0, br.size.y / 3.0)
			for ty in 3:
				for tx in 3:
					var tr := Rect2(br.position + Vector2(tx, ty) * tile, tile).grow(-6.0)
					L.draw_rect(tr, Color("8a94c0") if (tx + ty) % 2 == 0 else Color("5a6494"))
			sh["plaza"] = br
			continue
		# 每個街區 2 × 2 棟房子（等角的方塊、屋頂、亮著的窗）
		for by in 2:
			for bx in 2:
				var hw := br.size.x / 4.0 - 14.0
				var bc := br.position + Vector2((bx + 0.5) * br.size.x / 2.0, (by + 0.5) * br.size.y / 2.0 + 20.0)
				var hgt := rng.randf_range(50, 130)
				var roof: Color = [Color("8a3a4a"), Color("3a5a8a"), Color("5a4a8a"), Color("2a6a6a")][rng.randi() % 4]
				_tower_block(L, bc, hw, hgt, roof)
	# 鐘塔（左上的街區）
	var tb: Rect2 = bl[0][0]
	var ct := tb.get_center() + Vector2(0, 40)
	L.draw_colored_polygon(GW._ell(ct + Vector2(16, 8), 50, 14, 16), Color(0, 0, 0, 0.3))
	L.draw_rect(Rect2(ct + Vector2(-30, -260), Vector2(60, 260)), Color("b8b4d0"))
	L.draw_rect(Rect2(ct + Vector2(10, -260), Vector2(20, 260)), Color("8a86a8"))
	L.draw_colored_polygon(PackedVector2Array([ct + Vector2(-38, -258), ct + Vector2(38, -258), ct + Vector2(0, -330)]), Color("3a4a7a"))
	_dot(L, ct + Vector2(0, -210), 22.0, Color("fff3d6"), 64)
	L.draw_line(ct + Vector2(0, -210), ct + Vector2(0, -226), Color("2a2a3a"), 3.0)
	L.draw_line(ct + Vector2(0, -210), ct + Vector2(12, -206), Color("2a2a3a"), 3.0)
	# 運河交叉口的拱橋
	for rr in range(1, rows):
		for cc in range(0, cols):
			var x := area.position.x + cc * (bw + cw) + bw / 2.0
			var y := area.position.y + rr * (bh + cw) - cw
			L.draw_rect(Rect2(x - 30, y - 4, 60, cw + 8), Color("8a7e96"))
			L.draw_rect(Rect2(x - 30, y - 4, 60, 6), Color("a89eb8"))
			L.draw_rect(Rect2(x - 30, y + cw - 2, 60, 6), Color("a89eb8"))
	for rr in range(0, rows):
		for cc in range(1, cols):
			var x := area.position.x + cc * (bw + cw) - cw
			var y := area.position.y + rr * (bh + cw) + bh / 2.0
			L.draw_rect(Rect2(x - 4, y - 24, cw + 8, 48), Color("8a7e96"))
			L.draw_rect(Rect2(x - 4, y - 24, 6, 48), Color("a89eb8"))
	sh["area"] = area
	sh["grid"] = [bw, bh, cw, rows, cols]


## 一棟等角的方塊房子
static func _tower_block(L, bc: Vector2, hw: float, hgt: float, roof: Color) -> void:
	var s := hw
	var tp := bc - Vector2(0, hgt)
	L.draw_colored_polygon(PackedVector2Array([bc + Vector2(-s, 0), bc + Vector2(0, s * 0.5), bc + Vector2(s, 0), bc + Vector2(s + 30, 20), bc + Vector2(30, s * 0.5 + 20)]), Color(0, 0, 0, 0.3))
	var left := PackedVector2Array([tp + Vector2(-s, 0), tp + Vector2(0, s * 0.5), bc + Vector2(0, s * 0.5), bc + Vector2(-s, 0)])
	var right := PackedVector2Array([tp + Vector2(0, s * 0.5), tp + Vector2(s, 0), bc + Vector2(s, 0), bc + Vector2(0, s * 0.5)])
	L.draw_colored_polygon(left, Color("6a6a90"))
	L.draw_colored_polygon(right, Color("4a4a70"))
	var top := PackedVector2Array([tp + Vector2(0, -s * 0.5), tp + Vector2(s, 0), tp + Vector2(0, s * 0.5), tp + Vector2(-s, 0)])
	L.draw_colored_polygon(top, roof)
	L.draw_colored_polygon(PackedVector2Array([top[0], top[3], top[2]]), roof.lightened(0.15))
	# 窗：一排一排
	var wins := PackedVector2Array()
	var floors := int(hgt / 26.0)
	for f in floors:
		var yy := 14.0 + f * 26.0
		for k in 2:
			var fx := (k + 0.5) / 2.0
			var pl := tp.lerp(tp + Vector2(-s, 0), 1.0 - fx) + Vector2(0, s * 0.5 * fx + yy)
			wins.append_array([pl, pl + Vector2(0, 10)])
			var pr := (tp + Vector2(0, s * 0.5)).lerp(tp + Vector2(s, 0), fx) + Vector2(0, yy)
			wins.append_array([pr, pr + Vector2(0, 10)])
	L.draw_multiline(wins, Color("ffd27a"), 6.0)


# ================= 會動的東西（每幀畫，地圖座標） =================

var _route: Array = []        # 光潮的流動：航道折線 [點]、累積長度
var _route_len: Array = []


func _build_route() -> void:
	_route = [SPAWN]
	_route.append_array(_docks)
	_route_len = [0.0]
	for k in range(1, _route.size()):
		_route_len.append(float(_route_len[k - 1]) + (_route[k - 1] as Vector2).distance_to(_route[k]))


func _route_at(d: float) -> Vector2:
	for k in range(1, _route.size()):
		if d <= float(_route_len[k]):
			var a: float = _route_len[k - 1]
			return (_route[k - 1] as Vector2).lerp(_route[k], (d - a) / maxf(1.0, float(_route_len[k]) - a))
	return _route[_route.size() - 1]


func _p_fx(L) -> void:
	var v := _view().grow(160.0)
	var font := UITheme.bold_font()
	var tiny := zoom < 0.3
	if _route.is_empty():
		_build_route()
	# 夕陽：北邊海面上一大片暖光、金色的光帶
	if v.position.y < 2100.0:
		blob(L, Vector2(3600, -300), Vector2(2800, 1100), Color(1.0, 0.7, 0.45, 0.2))
		if not tiny:
			var gl := PackedVector2Array()
			var y := maxf(40.0, floorf(v.position.y / 70.0) * 70.0)
			while y < minf(v.end.y, 2000.0):
				var x := maxf(2800.0, floorf(v.position.x / 110.0) * 110.0) + fmod(y * 0.5, 110.0)
				var xe := minf(v.end.x, 4400.0)
				var fall := 1.0 - y / 2000.0
				var spread := 500.0 + y * 0.45
				while x < xe:
					if absf(x - 3600.0) < spread and _sea_at(Vector2i(int(x), int(y))):
						var tw := 0.5 + 0.5 * sin(t * 2.2 + x * 0.05 + y * 0.11)
						if tw > 0.45:
							var ln := 18.0 + 40.0 * tw * fall
							var q := Vector2(x + sin(t + y) * 10.0, y)
							gl.append_array([q, q + Vector2(ln, 0)])
					x += 110.0
				y += 70.0
			if not gl.is_empty():
				L.draw_multiline(gl, Color(1.0, 0.85, 0.55, 0.55), 5.0)
	# 整片海面的小光點：黃昏是粉金色、深夜是銀藍色
	if not tiny:
		var gs := PackedVector2Array()
		var gn := PackedVector2Array()
		var y := floorf(v.position.y / 150.0) * 150.0
		while y < v.end.y:
			var x := floorf(v.position.x / 230.0) * 230.0 + fmod(y, 460.0) * 0.5
			while x < v.end.x:
				if _sea_at(Vector2i(int(x), int(y))):
					var q := Vector2(x + sin(t * 0.8 + y * 0.01) * 14.0, y)
					if y < DUSK_Y:
						gs.append_array([q, q + Vector2(26, 0)])
					else:
						gn.append_array([q, q + Vector2(18, 0)])
				x += 230.0
			y += 150.0
		if not gs.is_empty():
			L.draw_multiline(gs, Color(1.0, 0.82, 0.8, 0.2), 3.0)
		if not gn.is_empty():
			L.draw_multiline(gn, Color(0.75, 0.85, 1.0, 0.16), 3.0)
	# 浪花：開放的島和港口的海岸
	if not tiny:
		var foam := PackedVector2Array()
		for i in _coast.size():
			if i < ISLANDS.size() and not _open_i(i):
				continue
			var pts: Array = _coast[i]
			for j in pts.size():
				var s: Array = pts[j]
				var p: Vector2 = s[0]
				if not v.has_point(p):
					continue
				var n: Vector2 = s[1]
				var k := 0.5 + 0.5 * sin(t * 1.4 + j * 0.9)
				var c := p + n * (34.0 + 30.0 * k)
				var d := n.orthogonal() * 26.0
				foam.append_array([c - d, c + n * 5.0, c + n * 5.0, c + d])
		if not foam.is_empty():
			L.draw_multiline(foam, Color(1, 1, 1, 0.36), 3.0)
	# 會發光的浮游生物（深夜的海，船經過的地方特別亮）
	if v.end.y > 2400.0 and not tiny:
		var cells := []
		for gy in range(int(v.position.y / 1000.0), int(v.end.y / 1000.0) + 1):
			for gx in range(int(v.position.x / 1000.0), int(v.end.x / 1000.0) + 1):
				if _plankton_grid.has(Vector2i(gx, gy)):
					cells.append_array(_plankton_grid[Vector2i(gx, gy)])
		for pl in cells:
			var p: Vector2 = pl.p
			if not v.has_point(p):
				continue
			var near := clampf(1.0 - p.distance_to(pos) / 420.0, 0.0, 1.0)
			var a := (0.18 + 0.16 * sin(t * 1.6 + pl.ph)) * _night_k(p.y) + near * 0.6
			_dot(L, p, pl.s * (1.0 + near), Color(0.5, 1.0, 0.92, a), 16)
			if near > 0.1:
				blob(L, p, Vector2(18, 18) * (1.0 + near), Color(0.4, 1.0, 0.9, 0.25 * near))
	# 極光：南邊的天空映在海面上
	if v.end.y > 2900.0:
		_aurora(L, v)
	# 光潮：沿著航道一顆一顆往前流的光
	var total: float = _route_len[_route_len.size() - 1]
	var dd := fmod(t * 140.0, 260.0)
	while dd < total:
		var p := _route_at(dd)
		if v.has_point(p):
			var nk := _night_k(p.y)
			var col := Color(1.0, 0.86, 0.5).lerp(Color(0.55, 1.0, 0.9), nk)
			blob(L, p, Vector2(30, 30), Color(col.r, col.g, col.b, 0.35))
			_dot(L, p, 5.0, col.lightened(0.4), 32)
		dd += 260.0
	_sea_life(L, v)
	_gloom_fx(L, v)
	_burst_fx(L)
	_egg_fx(L, v, font)
	# 港口的燈塔光束、渡船的燈
	var lamp := HARBOR + Vector2(150, -396)
	if v.grow(1200.0).has_point(lamp):
		for k in 2:
			var a := t * 0.6 + k * PI
			var d := Vector2.from_angle(a)
			var n := d.orthogonal()
			L.draw_polygon(PackedVector2Array([lamp, lamp + d * 1100.0 + n * 200.0, lamp + d * 1100.0 - n * 200.0]),
				PackedColorArray([Color(1.0, 0.95, 0.7, 0.35), Color(1.0, 0.95, 0.7, 0.0), Color(1.0, 0.95, 0.7, 0.0)]))
		blob(L, lamp, Vector2(90, 90), Color(1.0, 0.95, 0.65, 0.5 + 0.2 * sin(t * 4.0)))
		blob(L, FERRY + Vector2(120, -40), Vector2(40, 40), Color(1.0, 0.85, 0.5, 0.45 + 0.15 * sin(t * 2.0)))
	# 開放的島：點亮的聖地發光
	for i in ISLANDS.size():
		if not _open_i(i) or not _shape[i].has("sites"):
			continue
		if not v.intersects(_shape[i].box):
			continue
		var u: Dictionary = Units.unit(ISLANDS[i].unit)
		var g = Game.of(self)
		for j in (_shape[i].sites as Array).size():
			if j < u.levels.size() and Center.level_progress(g, u.levels[j].id) >= 0.999:
				var lc: Color = u.levels[j].color
				blob(L, _shape[i].sites[j] + Vector2(0, -20), Vector2(60, 60), Color(lc.r, lc.g, lc.b, 0.35 + 0.12 * sin(t * 2.0 + j)))
	# 船跡：兩道往外散開的白浪；深夜的海會發光
	for w in _wake:
		var a: float = 1.0 - w.life / 1.8
		var p: Vector2 = w.p
		var nk := _night_k(p.y)
		var rr := 8.0 + 34.0 * (1.0 - a)
		_ring_fx(L, p, rr * float(w.s), Color(1, 1, 1, 0.32 * a))
		if nk > 0.2:
			_dot(L, p, 6.0 * a + 2.0, Color(0.5, 1.0, 0.9, 0.6 * a * nk), 16)
	_draw_boat(L)
	# 靠近的碼頭：浮標亮起來
	if String(_near.get("kind", "")) == "dock":
		var i := int(_near.i)
		var bp: Vector2 = _docks[i] + (_docks[i] - _shores[i]).normalized().orthogonal() * 92.0
		blob(L, bp, Vector2(90, 90), Color(1.0, 0.85, 0.4, 0.35 + 0.15 * sin(t * 4.0)))


## 空心圓：畫在 CanvasBatch 上就是一個方塊
static func _ring_fx(L, c: Vector2, r: float, col: Color) -> void:
	if L is CanvasItem:
		L.draw_arc(c, r, 0, TAU, 24, col, 3.0, true)
	else:
		L.ring(c, r + 1.5, col)


## 這一格的海面光點是不是在海上（快取：每格只問一次）
func _sea_at(key: Vector2i) -> bool:
	if not _sea_pt.has(key):
		var p := Vector2(key)
		var ok := true
		for i in ISLANDS.size():
			if (_shape[i].box as Rect2).grow(80.0).has_point(p) and (_on_island(p, i, 40.0) or _on_island(p + Vector2(40, 0), i, 40.0)):
				ok = false
				break
		if ok and Geometry2D.is_point_in_polygon(p, _harbor_blk):
			ok = false
		_sea_pt[key] = ok
	return _sea_pt[key]


func _aurora(L, v: Rect2) -> void:
	var specs := [[3150.0, Color(0.4, 1.0, 0.7), 0.0], [3500.0, Color(0.55, 0.8, 1.0), 2.0], [4050.0, Color(0.8, 0.55, 1.0), 4.0]]
	var x0 := maxf(0.0, v.position.x - 100.0)
	var x1 := minf(WORLD.x, v.end.x + 100.0)
	for sp in specs:
		var y0: float = sp[0]
		if y0 + 260.0 < v.position.y or y0 - 260.0 > v.end.y:
			continue
		var col: Color = sp[1]
		var ph: float = sp[2]
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var idx := PackedInt32Array()
		var x := x0
		var n := 0
		while x <= x1:
			var yy := y0 + sin(x * 0.0016 + t * 0.25 + ph) * 90.0 + sin(x * 0.004 + t * 0.6) * 30.0
			var hgt := 170.0 + 70.0 * sin(x * 0.003 + t * 0.4 + ph)
			var a := 0.16 + 0.08 * sin(x * 0.006 + t * 1.1 + ph)
			pts.append(Vector2(x, yy))
			pts.append(Vector2(x, yy - hgt))
			cols.append(Color(col.r, col.g, col.b, a))
			cols.append(Color(col.r, col.g, col.b, 0.0))
			if n > 0:
				var b := (n - 1) * 2
				idx.append_array([b, b + 1, b + 3, b, b + 3, b + 2])
			n += 1
			x += 80.0
		if n > 1:
			if L is CanvasItem:
				RenderingServer.canvas_item_add_triangle_array(L.get_canvas_item(), idx, pts, cols)
			else:
				L.tris(pts, cols, idx)


## 海上的生物：鯨魚、海豚、海鷗、魚群、水母、鬼蝠魟、背著小島的海龜
func _sea_life(L, v: Rect2) -> void:
	# 鯨魚：沿著一個大圈慢慢游，每 16 秒浮上來一次（先噴水、再露出背、最後舉起尾巴）
	for wh in [[Vector2(2950, 1650), Vector2(820, 230), 0.0, false], [Vector2(2700, 3150), Vector2(650, 190), 7.0, true]]:
		var c: Vector2 = wh[0]
		var r: Vector2 = wh[1]
		var tt: float = t + float(wh[2])
		var a := tt * TAU / 90.0
		var p := c + Vector2(cos(a) * r.x, sin(a) * r.y)
		if not v.grow(300.0).has_point(p):
			continue
		var d := Vector2(-sin(a) * r.x, cos(a) * r.y).normalized()
		var ph := fmod(tt, 16.0)
		var night: bool = wh[3]
		var body := Color("2a3450") if not night else Color("1a2a44")
		if ph < 6.0:
			var up := sin(clampf(ph / 6.0, 0.0, 1.0) * PI)
			_ring_fx(L, p, 120.0 + ph * 30.0, Color(1, 1, 1, 0.18 * (1.0 - ph / 6.0)))
			var n := d.orthogonal()
			var back := PackedVector2Array()
			for k in 13:
				var s := -1.0 + 2.0 * k / 12.0
				back.append(p + d * s * 130.0 + n * (1.0 - s * s) * 34.0 * up)
			for k in 13:
				var s := 1.0 - 2.0 * k / 12.0
				back.append(p + d * s * 130.0 - n * (1.0 - s * s) * 34.0 * up)
			L.draw_colored_polygon(back, body)
			L.draw_colored_polygon(GW._ell(p + d * 30.0 - n * 8.0, 60 * up + 1.0, 12 * up + 1.0, 16), body.lightened(0.25))
			if night:
				for k in 6:
					_dot(L, p + d * (-90.0 + k * 34.0) + n * sin(k) * 10.0, 5.0, Color(0.5, 1.0, 0.95, 0.8 * up), 16)
			if ph < 1.6:
				# 噴水
				for k in 6:
					var sp := p + d * 100.0 + Vector2(sin(k * 1.7) * 18.0, -ph * 90.0 - k * 10.0)
					blob(L, sp, Vector2(22, 22) * (1.0 + ph), Color(1, 1, 1, 0.5 * (1.0 - ph / 1.6)))
			if ph > 4.6:
				# 尾巴
				var tp := p - d * 150.0
				var k2 := sin((ph - 4.6) / 1.4 * PI)
				var n2 := d.orthogonal()
				L.draw_colored_polygon(PackedVector2Array([tp, tp - d * 30.0 + n2 * 70.0 * k2 + Vector2(0, -50 * k2), tp - d * 10.0, tp - d * 30.0 - n2 * 70.0 * k2 + Vector2(0, -50 * k2)]), body)
				blob(L, tp, Vector2(80, 30), Color(1, 1, 1, 0.35 * k2))
		else:
			blob(L, p, Vector2(150, 60), Color(0.0, 0.03, 0.12, 0.25))
	# 海豚：三隻一群，輪流跳出水面
	for pd in [[Vector2(4850, 1550), Vector2(520, 220), 0.0], [Vector2(2200, 2150), Vector2(420, 180), 3.0]]:
		var c: Vector2 = pd[0]
		var r: Vector2 = pd[1]
		for k in 3:
			var tt: float = t + float(pd[2]) + k * 0.7
			var a := tt * TAU / 40.0 - k * 0.09
			var p := c + Vector2(cos(a) * r.x, sin(a) * r.y)
			if not v.grow(200.0).has_point(p):
				continue
			var d := Vector2(-sin(a) * r.x, cos(a) * r.y).normalized()
			var ph := fmod(tt, 2.6) / 2.6
			if ph < 0.45:
				var s := ph / 0.45
				var hgt := sin(s * PI) * 60.0
				var bp := p + Vector2(0, -hgt)
				var n := d.orthogonal()
				var tilt := d.rotated(-0.9 + 1.8 * s)
				var body := PackedVector2Array([bp + tilt * 46.0, bp + tilt * 10.0 + n * 12.0, bp - tilt * 34.0 + n * 6.0, bp - tilt * 50.0, bp - tilt * 34.0 - n * 6.0, bp + tilt * 10.0 - n * 12.0])
				blob(L, p, Vector2(50, 16), Color(0, 0, 0, 0.18))
				L.draw_colored_polygon(body, Color("6a7c9a"))
				L.draw_colored_polygon(PackedVector2Array([bp + tilt * 46.0, bp + tilt * 10.0 + n * 12.0, bp - tilt * 34.0 + n * 6.0, bp - tilt * 20.0]), Color("9aaccc"))
				L.draw_colored_polygon(PackedVector2Array([bp - tilt * 4.0, bp - tilt * 16.0 - n * 22.0, bp - tilt * 20.0]), Color("5a6a88"))
				if s < 0.15 or s > 0.85:
					_ring_fx(L, p, 20.0 + 30.0 * (s if s < 0.5 else 1.0 - s), Color(1, 1, 1, 0.5))
			else:
				_ring_fx(L, p, 14.0 + (ph - 0.45) * 50.0, Color(1, 1, 1, 0.3 * (1.0 - ph)))
	# 海鷗（黃昏的海）：幾隻一群在海上繞圈，海面上有牠們的影子
	var gull := PackedVector2Array()
	for fl in [[Vector2(2300, 1250), 380.0, 0.0], [Vector2(4800, 1100), 420.0, 2.0], [Vector2(900, 1900), 300.0, 4.0], [Vector2(5200, 2000), 360.0, 1.0]]:
		var c: Vector2 = fl[0]
		if not v.grow(500.0).has_point(c):
			continue
		var rr: float = fl[1]
		for k in 5:
			var a := t * 0.25 + float(fl[2]) + k * 0.32
			var p := c + Vector2(cos(a), sin(a) * 0.55) * (rr + k * 26.0)
			var flap := sin(t * 7.0 + k * 1.3) * 10.0
			var d := Vector2(-sin(a), cos(a) * 0.55).normalized()
			var n := d.orthogonal()
			_dot(L, p + Vector2(60, 90), 6.0, Color(0, 0, 0, 0.16), 16)
			var w := [p + n * 22.0 + Vector2(0, flap), p + n * 9.0 + d * 4.0 + Vector2(0, -4), p, p - n * 9.0 + d * 4.0 + Vector2(0, -4), p - n * 22.0 + Vector2(0, flap)]
			for j in 4:
				gull.append_array([w[j], w[j + 1]])
	if not gull.is_empty():
		L.draw_multiline(gull, Color("f2f2f8"), 4.0)
	var small := zoom < 0.3          # 拉遠看全島：魚、水母小到看不見
	# 魚群：在淺灘附近繞圈
	for sc in ([] if small else _schools):
		var c: Vector2 = sc.c
		if not v.grow(150.0).has_point(c):
			continue
		var night: bool = sc.night
		var col := Color(0.85, 0.9, 1.0, 0.55) if not night else Color(0.5, 1.0, 0.9, 0.6)
		for k in int(sc.n):
			var a: float = t * float(sc.sp) + float(sc.ph) + k * TAU / float(sc.n)
			var wob := sin(t * 2.0 + k) * 12.0
			var p := c + Vector2(cos(a), sin(a) * 0.6) * (float(sc.r) + wob)
			var d := Vector2(-sin(a), cos(a) * 0.6).normalized()
			L.draw_colored_polygon(PackedVector2Array([p + d * 10.0, p + d.orthogonal() * 4.0, p - d * 8.0, p - d * 12.0 + d.orthogonal() * 5.0, p - d * 12.0 - d.orthogonal() * 5.0, p - d.orthogonal() * 4.0]), col)
	# 水母：一顆一顆的傘一縮一放、慢慢漂（觸手全部收成一次畫）
	var tent := PackedVector2Array()
	var tent2 := PackedVector2Array()
	for jf in ([] if small else _jellies):
		var p: Vector2 = jf.p + Vector2(sin(t * 0.3 + jf.ph) * 30.0, cos(t * 0.23 + jf.ph) * 20.0)
		if not v.has_point(p):
			continue
		var s: float = jf.s
		var pulse := 1.0 + 0.15 * sin(t * 2.4 + jf.ph)
		var col: Color = jf.c
		blob(L, p, Vector2(46, 46) * s, Color(col.r, col.g, col.b, 0.25))
		for k in 4:
			var tx := (k - 1.5) * 7.0 * s
			var prev := p + Vector2(tx, 6.0 * s)
			for j in range(1, 5):
				var q := p + Vector2(tx + sin(t * 3.0 + j + k + jf.ph) * 4.0, 6.0 * s + j * 9.0 * s)
				(tent if k % 2 == 0 else tent2).append_array([prev, q])
				prev = q
		L.draw_colored_polygon(GW._ell(p, 20 * s * pulse, 15 * s / pulse, 16, PI, TAU), Color(col.r, col.g, col.b, 0.65))
		L.draw_colored_polygon(GW._ell(p + Vector2(-4, -5) * s, 9 * s * pulse, 6 * s, 12, PI, TAU), Color(1, 1, 1, 0.45))
	if not tent.is_empty():
		L.draw_multiline(tent, Color(1.0, 0.75, 0.9, 0.5), 2.0)
		L.draw_multiline(tent2, Color(0.7, 0.95, 1.0, 0.5), 2.0)
	# 鬼蝠魟（深夜）：沿著 8 字形滑過去，邊緣會發光
	var mt := t * TAU / 50.0
	var mc := Vector2(4750, 2900) + Vector2(sin(mt) * 480.0, sin(mt * 2.0) * 160.0)
	if v.grow(200.0).has_point(mc):
		var md := Vector2(cos(mt) * 480.0, cos(mt * 2.0) * 320.0).normalized()
		var mn := md.orthogonal()
		var fl := sin(t * 2.2) * 16.0
		var ray := PackedVector2Array([mc + md * 60.0, mc + mn * 110.0 + md * (-10.0 + fl), mc - md * 40.0, mc - mn * 110.0 + md * (-10.0 + fl)])
		blob(L, mc, Vector2(140, 80), Color(0, 0, 0, 0.18))
		L.draw_colored_polygon(ray, Color("1e2c50"))
		var edge := ray.duplicate()
		edge.append(ray[0])
		L.draw_polyline(edge, Color(0.5, 1.0, 0.95, 0.55), 3.0, true)
		L.draw_line(mc - md * 40.0, mc - md * 150.0 + mn * sin(t * 2.0) * 14.0, Color(0.5, 1.0, 0.95, 0.4), 2.0, true)
	# 背著小島的海龜
	var tp := _turtle_pos()
	if v.grow(300.0).has_point(tp):
		var ta := t * TAU / 240.0
		var td := Vector2(-sin(ta) * TURTLE_R.x, cos(ta) * TURTLE_R.y).normalized()
		var tn := td.orthogonal()
		var pad := sin(t * 2.0)
		blob(L, tp + Vector2(10, 16), Vector2(130, 90), Color(0, 0, 0, 0.22))
		for sd in [-1.0, 1.0]:
			for fb in [1.0, -1.0]:
				var fp: Vector2 = tp + td * 40.0 * fb + tn * 62.0 * sd
				var tip: Vector2 = fp + tn * 34.0 * sd + td * (18.0 * pad * fb * sd - 10.0)
				L.draw_colored_polygon(PackedVector2Array([fp + td * 12.0, tip, fp - td * 12.0]), Color("4a7a5a"))
		L.draw_colored_polygon(GW._ell(tp + td * 92.0, 22, 22, 14), Color("5a8a6a"))
		_dot(L, tp + td * 104.0 + tn * 9.0, 3.0, Color("1a1a22"), 16)
		_dot(L, tp + td * 104.0 - tn * 9.0, 3.0, Color("1a1a22"), 16)
		var shell := GW._ell(tp, 84, 64, 24)
		L.draw_colored_polygon(shell, Color("6a5a3a"))
		for k in 6:
			var hp := tp + Vector2.from_angle(TAU * k / 6.0) * 44.0
			L.draw_colored_polygon(GW._ell(hp, 18, 14, 6), Color("8a7a4a"))
		L.draw_colored_polygon(GW._ell(tp, 20, 16, 6), Color("8a7a4a"))
		# 背上的小島：沙、草、一棵椰子樹
		L.draw_colored_polygon(GW._ell(tp + Vector2(0, -6), 56, 34, 20), Color("e9c99c"))
		L.draw_colored_polygon(GW._ell(tp + Vector2(-4, -10), 40, 22, 16), Color("6d8f4a"))
		_tree(L, tp + Vector2(4, -8), 30.0, _pal(_night_k(tp.y) > 0.5), "palm", 0.3)
		if not v.has_point(tp):
			pass


## 開放的島上會動的東西
## 還沒點亮的島：上面壓著一層慢慢飄的灰暗雲影（點亮越多越淡）
func _gloom_fx(L, v: Rect2) -> void:
	for i in ISLANDS.size():
		if not _open_i(i):
			continue
		var dk := 1.0 - light_e(String(ISLANDS[i].unit))
		if dk < 0.02:
			continue
		var b: Rect2 = _shape[i].box
		if not v.intersects(b.grow(200.0)):
			continue
		var c := b.get_center()
		for k in 5:
			var ph := float(k) * 1.7 + i
			var p := c + Vector2(sin(t * 0.05 + ph) * b.size.x * 0.32, cos(t * 0.04 + ph * 1.3) * b.size.y * 0.28)
			blob(L, p, Vector2(b.size.x * 0.34, b.size.y * 0.3), Color(0.05, 0.06, 0.12, 0.22 * dk))


## 點亮動畫：從島的中心擴散出去的光圈，聖地一顆顆往上冒光點
func _burst_fx(L) -> void:
	for b in _light_bursts():
		var box: Rect2 = b.box
		var f: float = b.f
		var c := box.get_center()
		var col: Color = ISLANDS[0].col
		var sites: Array = []
		for i in ISLANDS.size():
			if String(ISLANDS[i].unit) == String(b.key):
				col = ISLANDS[i].col
				sites = _shape[i].get("sites", [])
		var big := maxf(box.size.x, box.size.y) * 0.7
		blob(L, c, Vector2(big, big * 0.7) * (0.4 + 0.6 * f), Color(1.0, 0.95, 0.75, 0.32 * sin(f * PI)))
		for k in 3:
			var ph := clampf(f * 1.4 - k * 0.2, 0.0, 1.0)
			if ph > 0.0 and ph < 1.0:
				_ring_fx(L, c, 80.0 + ph * big, Color(col.r, col.g, col.b, 0.5 * (1.0 - ph)))
		for j in sites.size():
			var sp: Vector2 = sites[j]
			for k in 4:
				var ph := fmod(f * 2.2 + k * 0.25 + j * 0.13, 1.0)
				var a := sin(f * PI) * (1.0 - ph)
				_dot(L, sp + Vector2(sin(j * 2.0 + k * 1.7) * 26.0, -30.0 - ph * 160.0), 5.0, Color(1.0, 0.95, 0.7, a), 16)


## 一座島自己的動態（畫在那座島的動態層，照點亮程度調淡）
func _island_fx_one(L, i: int, v: Rect2) -> void:
	if not _open_i(i):
		return
	# 沒點亮的島連時間都走得慢（風箏、纜車、光點都慢吞吞的）
	var t_real := t
	t = light_time(String(ISLANDS[i].unit))
	_island_fx_body(L, i, v)
	t = t_real


func _island_fx_body(L, i: int, v: Rect2) -> void:
	var sh: Dictionary = _shape[i]
	if not v.intersects((sh.box as Rect2).grow(200.0)):
		return
	var c: Vector2 = ISLANDS[i].c
	match String(sh.kind):
		"trig":
			var o: Vector2 = sh.o
			blob(L, o + Vector2(0, -190), Vector2(70, 70), Color(0.9, 0.85, 1.0, 0.45 + 0.2 * sin(t * 2.0)))
			for k in 3:
				var ph := fmod(t * 0.4 + k / 3.0, 1.0)
				_ring_fx(L, o + Vector2(0, 30), 80.0 + ph * 120.0, Color(1, 1, 1, 0.22 * (1.0 - ph)))
			var k0: float = sh.k
			var xx := TM.WX0 + TM.PER * 0.25
			var j := 0
			while xx < TM.X_END - 20.0:
				var p: Vector2 = o + (TM.wave_p(xx) - TM.O) * k0
				blob(L, p + Vector2(0, -72), Vector2(36, 36), Color(1.0, 0.82, 0.45, 0.4 + 0.15 * sin(t * 3.0 + j)))
				xx += TM.PER * 0.5
				j += 1
		"exp":
			var ma: Vector2 = sh.ma
			var mb: Vector2 = sh.mb
			for k in 10:
				var f := fmod(t * 0.08 + k / 10.0, 1.0)
				var p := ma.lerp(mb, f)
				blob(L, p, Vector2(50, 18), Color(1.0, 0.95, 0.8, 0.35 * sin(f * PI)))
			blob(L, sh.tower + Vector2(0, -94), Vector2(40, 40), Color(1.0, 0.85, 0.5, 0.45 + 0.15 * sin(t * 3.0)))
		"vec2":
			# 風箏
			for k in 2:
				var base := c + Vector2(-80 + k * 300, 120 - k * 200)
				var kp := base + Vector2(180 + sin(t * 0.9 + k) * 40.0, -260 + cos(t * 1.1 + k) * 30.0)
				L.draw_polyline(PackedVector2Array([base, base.lerp(kp, 0.5) + Vector2(20, 30), kp]), Color(1, 1, 1, 0.5), 2.0, true)
				var kd := (kp - base).normalized()
				var kn := kd.orthogonal()
				L.draw_colored_polygon(PackedVector2Array([kp + kd * 40.0, kp + kn * 24.0, kp - kd * 26.0, kp - kn * 24.0]), Color("ff7a8a") if k == 0 else Color("5fd4ff"))
				L.draw_polyline(PackedVector2Array([kp - kd * 26.0, kp - kd * 46.0 + kn * sin(t * 4.0) * 10.0, kp - kd * 66.0]), Color("f5c84c"), 3.0, true)
			# 風吹過田的一道道白線
			var wl := PackedVector2Array()
			for k in 8:
				var ph := fmod(t * 0.35 + k / 8.0, 1.0)
				var s := c + Vector2(-600 + ph * 1200.0, -300 + k * 80.0) + Vector2(0, -ph * 260.0)
				wl.append_array([s, s + Vector2(90, -28)])
			L.draw_multiline(wl, Color(1, 1, 1, 0.25), 3.0)
			# 雁群：兩隊往同一個方向飛，合成一隊
			for k in 7:
				var ph := fmod(t * 0.05, 1.0)
				var lead := c + Vector2(-700, 500) + Vector2(1400, -1000) * ph
				var off := Vector2(-k * 26.0, k * 18.0) if k % 2 == 0 else Vector2(-k * 26.0, -k * 10.0)
				var p := lead + off
				var flap := sin(t * 6.0 + k) * 6.0
				L.draw_polyline(PackedVector2Array([p + Vector2(-14, flap), p, p + Vector2(14, flap)]), Color("2a2a3a"), 3.0, true)
		"vec3":
			for ax in 3:
				blob(L, c + Vector2(-100 + ax * 100, -320), Vector2(60, 60), Color([Color(1, 0.5, 0.55), Color(0.5, 1, 0.7), Color(0.5, 0.7, 1)][ax], 0.0))
			for k in 14:
				var ph := fmod(t * 0.2 + k / 14.0, 1.0)
				var p := c + Vector2(sin(k * 2.1) * 360.0, 200.0 - ph * 520.0)
				_dot(L, p, 3.0, Color(0.8, 0.9, 1.0, 0.7 * sin(ph * PI)), 16)
			blob(L, c + Vector2(-100, -300), Vector2(140, 100), Color(0.6, 0.75, 1.0, 0.12 + 0.05 * sin(t * 1.5)))
		"plane":
			if sh.has("cable"):
				var t1: Vector2 = sh.cable[0] + Vector2(0, -112)
				var t2: Vector2 = sh.cable[1] + Vector2(0, -112)
				var f := 0.5 + 0.5 * sin(t * 0.25)
				var gp := t1.lerp(t2, f)
				L.draw_line(gp, gp + Vector2(0, 26), Color("3a4a6a"), 3.0)
				L.draw_rect(Rect2(gp + Vector2(-22, 26), Vector2(44, 32)), Color("d84a4a"))
				L.draw_rect(Rect2(gp + Vector2(-16, 32), Vector2(32, 12)), Color("ffe08a"))
			var apex: Vector2 = sh.apex
			for k in 8:
				var p := apex.lerp((sh.ma + sh.mb) / 2.0, 0.15 + k * 0.1) + Vector2(sin(k * 3.0) * 30.0, cos(k * 2.0) * 20.0)
				_dot(L, p, 2.5, Color(1, 1, 1, 0.3 + 0.4 * absf(sin(t * 1.3 + k))), 16)
		"prob":
			for k in 30:
				var a := k * 2.4 + t * 0.3
				var p := c + Vector2(cos(a) * (200.0 + k * 14.0), sin(a * 1.3) * (120.0 + k * 6.0)) + Vector2(0, -60)
				_dot(L, p, 3.0, Color(1.0, 0.95, 0.5, 0.4 + 0.4 * sin(t * 3.0 + k)), 16)
			blob(L, c + Vector2(0, -300), Vector2(420, 260), Color(1.0, 0.8, 0.5, 0.06 + 0.03 * sin(t)))
		"matrix":
			if sh.has("plaza"):
				var br: Rect2 = sh.plaza
				var tile := br.size / 3.0
				var k := int(t * 1.2) % 9
				var order := [0, 1, 2, 5, 8, 7, 6, 3, 4]
				var idx: int = order[k]
				var tr := Rect2(br.position + Vector2(idx % 3, idx / 3) * tile, tile).grow(-6.0)
				L.draw_rect(tr, Color(1.0, 0.95, 0.6, 0.35))
			if sh.has("area"):
				var area: Rect2 = sh.area
				var gd: Array = sh.grid
				for k in 10:
					var ph := fmod(t * 0.03 + k / 10.0, 1.0)
					var cc := 1 + k % (int(gd[4]) - 1)
					var x: float = area.position.x + cc * (float(gd[0]) + float(gd[2])) - float(gd[2]) * 0.5
					var p := Vector2(x, area.position.y - 60.0 + (area.size.y + 120.0) * ph)
					blob(L, p, Vector2(24, 24), Color(1.0, 0.8, 0.45, 0.5))
					_dot(L, p, 5.0, Color("ffe7a3"), 16)


## 彩蛋：瓶中信在海上漂、漩渦在轉、沉船旁邊冒泡
func _egg_fx(L, v: Rect2, _font: Font) -> void:
	if v.grow(200.0).has_point(BOTTLE):
		var bob := sin(t * 2.0) * 6.0
		var bp := BOTTLE + Vector2(0, bob)
		var rot := sin(t * 1.3) * 0.25
		var d := Vector2.from_angle(rot) * 1.8
		var n := d.orthogonal()
		_ring_fx(L, BOTTLE + Vector2(0, 10), 60.0 + 8.0 * sin(t * 2.0), Color(1, 1, 1, 0.3))
		_ring_fx(L, BOTTLE + Vector2(0, 10), 90.0 + 8.0 * sin(t * 2.0 + 1.0), Color(1, 1, 1, 0.16))
		L.draw_colored_polygon(PackedVector2Array([bp - d * 26.0 + n * 11.0, bp + d * 10.0 + n * 11.0, bp + d * 20.0 + n * 5.0, bp + d * 30.0 + n * 5.0,
			bp + d * 30.0 - n * 5.0, bp + d * 20.0 - n * 5.0, bp + d * 10.0 - n * 11.0, bp - d * 26.0 - n * 11.0]), Color(0.6, 0.9, 0.8, 0.75))
		L.draw_colored_polygon(PackedVector2Array([bp - d * 16.0 + n * 6.0, bp + d * 6.0 + n * 6.0, bp + d * 6.0 - n * 4.0, bp - d * 16.0 - n * 4.0]), Color("f2e6c8"))
		L.draw_line(bp + d * 30.0, bp + d * 36.0, Color("8a5a3a"), 14.0)
		if not _has("eggs", "bottle"):
			_dot(L, bp - d * 18.0 + n * 8.0, 3.0 + 2.0 * absf(sin(t * 3.0)), Color(1, 1, 1, 0.9), 16)
	if v.grow(300.0).has_point(WHIRL):
		# 漩渦：幾條螺線一直轉
		_dot(L, WHIRL, 150.0, Color(0.05, 0.12, 0.3, 0.35), 128)
		_dot(L, WHIRL, 60.0, Color(0.02, 0.06, 0.18, 0.45), 64)
		for arm in 4:
			var sp := PackedVector2Array()
			for k in 30:
				var a := -t * 1.6 + arm * TAU / 4.0 + k * 0.22
				sp.append(WHIRL + Vector2.from_angle(a) * (16.0 + k * 5.2))
			L.draw_polyline(sp, Color(0.8, 0.92, 1.0, 0.45), 4.0, true)
	if v.grow(300.0).has_point(WRECK):
		for k in 6:
			var ph := fmod(t * 0.5 + k / 6.0, 1.0)
			var p := WRECK + Vector2(-60 + k * 30.0, 30.0 - ph * 60.0)
			_ring_fx(L, p, 3.0 + ph * 4.0, Color(1, 1, 1, 0.5 * (1.0 - ph)))


## 光舟：帆會轉向、船頭掛一盞燈；光靈坐在船上
func _draw_boat(L) -> void:
	var bob := sin(t * 2.4) * 3.0
	var f := Vector2.from_angle(heading)
	var s := f.orthogonal()
	var p := pos + Vector2(0, bob)
	var nk := _night_k(pos.y)
	blob(L, pos + Vector2(6, 18), Vector2(60, 26), Color(0, 0, 0, 0.25))
	var hull := PackedVector2Array([p + f * 54.0, p + f * 18.0 + s * 24.0, p - f * 42.0 + s * 20.0, p - f * 46.0, p - f * 42.0 - s * 20.0, p + f * 18.0 - s * 24.0])
	L.draw_colored_polygon(GW._shift(hull, Vector2(0, 8)), Color("6a4628"))
	L.draw_colored_polygon(hull, Color("c8945a"))
	var deck := PackedVector2Array()
	for q in hull:
		deck.append(p + (q - p) * 0.78)
	L.draw_colored_polygon(deck, Color("e8c48a"))
	var pl := PackedVector2Array()
	for k in 3:
		var o := s * (-12.0 + k * 12.0)
		pl.append_array([p - f * 30.0 + o, p + f * 22.0 + o * 0.8])
	L.draw_multiline(pl, Color("c89a62"), 2.0)
	var rim := hull.duplicate()
	rim.append(hull[0])
	L.draw_polyline(rim, Color("8a5a2e"), 3.0, true)
	# 船頭的燈（深夜比較亮）
	var lamp := p + f * 50.0 + Vector2(0, -24)
	L.draw_line(p + f * 46.0, lamp, Color("5a3a22"), 3.0)
	blob(L, lamp, Vector2(40, 40) * (1.0 + nk), Color(1.0, 0.85, 0.5, 0.35 + 0.35 * nk))
	_dot(L, lamp, 6.0, Color("ffe7a3"), 32)
	# 光靈坐在船尾
	var ci: CanvasItem = L if L is CanvasItem else L.ci
	if not (L is CanvasItem):
		L.flush()
	ci.draw_set_transform(p - f * 14.0 + Vector2(0, -18), 0.0, Vector2(-1.0 if f.x < -0.1 else 1.0, 1.0))
	SL.draw_all(ci, Vector2.ZERO, 22.0, Game.of(self).equipped, t)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 桅杆和帆（帆面對著前進方向的側邊，被風吹得鼓起來）
	var mast := p + f * 8.0
	var mtop := mast + Vector2(0, -120)
	L.draw_line(mast, mtop, Color("5a3a22"), 5.0, true)
	var side := 1.0 if s.x >= 0.0 else -1.0
	var sw := s * side
	var billow := 14.0 + 6.0 * sin(t * 3.0)
	var sail := PackedVector2Array([mtop + Vector2(0, 6), mast + Vector2(0, -10) + sw * 6.0])
	for k in 7:
		var u := k / 6.0
		sail.append(mast.lerp(mtop, 1.0 - u) + Vector2(0, -10 * (1.0 - u)) + sw * (64.0 * (1.0 - u) + billow * sin(u * PI)) + Vector2(0, 0))
	L.draw_colored_polygon(sail, Color("f4f2ff"))
	L.draw_polyline(PackedVector2Array([mtop + Vector2(0, 6), mast + Vector2(0, -10) + sw * 64.0]), Color("c8c8e0"), 2.0, true)
	L.draw_colored_polygon(PackedVector2Array([mtop, mtop + Vector2(26, 6 + sin(t * 6.0) * 4.0), mtop + Vector2(0, 12)]), Color("f5c84c"))


## 海霧：還沒開放的島整座蓋起來（中間不透明，邊緣一團一團）
func _draw_fog(L, i: int) -> void:
	var fg: Array = _fog[i]
	var c: Vector2 = fg[0]
	var rx: float = fg[1]
	var ry: float = fg[2]
	var night: bool = ISLANDS[i].night
	var base := Color(0.93, 0.86, 0.88) if not night else Color(0.62, 0.68, 0.84)
	var shade := Color(0.8, 0.7, 0.78) if not night else Color(0.42, 0.48, 0.66)
	var pr := minf(rx, ry) * 0.26
	blob(L, c + Vector2(50, 90), Vector2(rx, ry) * 1.12, Color(0, 0, 0, 0.22))
	L.draw_colored_polygon(GW._ell(c + Vector2(0, 24), rx * 0.86, ry * 0.86, 48), shade)
	var n := 24
	for pass_i in 2:
		for k in n:
			var a := TAU * k / n + i * 0.7
			var wob := 0.84 + 0.06 * sin(k * 2.3 + i)
			var p := c + Vector2(cos(a) * rx, sin(a) * ry) * wob
			var r := pr * (0.85 + 0.3 * absf(sin(k * 1.7 + i)))
			if pass_i == 0:
				_dot(L, p + Vector2(0, 26), r, shade, 128)
			else:
				_dot(L, p, r, base, 128)
	L.draw_colored_polygon(GW._ell(c, rx * 0.84, ry * 0.84, 48), base)
	for k in 4:
		var a := TAU * k / 4.0 + i
		var p := c + Vector2(cos(a) * rx, sin(a) * ry) * 0.42 + Vector2(-rx * 0.08, -ry * 0.12)
		blob(L, p, Vector2(rx, ry) * 0.44, Color(1, 1, 1, 0.5) if not night else Color(0.88, 0.92, 1.0, 0.4))
	var font := UITheme.bold_font()
	GW._text_ol(L, font, c + Vector2(-500, -6), ISLANDS[i].name, HORIZONTAL_ALIGNMENT_CENTER, 1000, 76, Color(1, 1, 1, 0.95), 12)
	GW._text_ol(L, font, c + Vector2(-500, 66), "%s　·　海霧籠罩・準備中" % Units.unit(ISLANDS[i].unit).title, HORIZONTAL_ALIGNMENT_CENTER, 1000, 34, Color(1, 1, 1, 0.82), 8)


# ================= 螢幕上的東西（小地圖、主線、搖桿、天色） =================

func _p_hud(L) -> void:
	var font := UITheme.bold_font()
	var v := _view()
	var nk := _night_k(v.get_center().y)
	# 黃昏：畫面上方一片暖暖的天光
	if nk < 0.99:
		var a := 0.12 * (1.0 - nk)
		L.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, 220), Vector2(0, 220)]),
			PackedColorArray([Color(1.0, 0.6, 0.4, a), Color(1.0, 0.7, 0.45, a), Color(1.0, 0.7, 0.45, 0.0), Color(1.0, 0.6, 0.4, 0.0)]))
	# 深夜：天上的星星
	if nk > 0.01:
		for st in _stars:
			var a := (0.25 + 0.3 * sin(t * st.s + st.ph)) * nk
			_dot(L, st.p, st.s, Color(0.9, 0.95, 1.0, maxf(0.0, a)), 16)
	for k in 4:
		var w := 60.0 - k * 14.0
		L.draw_rect(Rect2(0, 0, W, w), Color(0, 0, 0.05, 0.06))
		L.draw_rect(Rect2(0, H - w, W, w), Color(0, 0, 0.05, 0.06))
	_draw_minimap(L)
	if not playing and _goal_text != "":
		var tp := Vector2(-1, -1)
		if _goal_pt.x >= 0.0:
			var C := Vector2(W, H) / 2.0
			tp = C - (cam + C) * zoom + _goal_pt * zoom
		var mm := 210.0 * WORLD.y / WORLD.x
		WS.draw_goal(L, _goal_text, tp, t, Rect2(W - 18 - 210 - 4, 66, 218, mm + 8))
	_draw_joy(L, font)
	var label := "光潮群島 · 黃昏之海（高二上）" if pos.y < DUSK_Y else "光潮群島 · 深夜之海（高二下）"
	UITheme.text_ol(L, font, Vector2(20, 142), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffd2b0") if pos.y < DUSK_Y else Color("9fd8ff"), 6)


func _draw_joy(L, font: Font) -> void:
	if playing:
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

func _draw_minimap(L) -> void:
	var mw := 210.0
	var k := mw / WORLD.x
	var mh := WORLD.y * k
	var o := Vector2(W - 18 - mw, 70)
	L.draw_rect(Rect2(o - Vector2(4, 4), Vector2(mw + 8, mh + 8)), Color(0.04, 0.05, 0.12, 0.85))
	L.draw_polygon(PackedVector2Array([o, o + Vector2(mw, 0), o + Vector2(mw, mh * 0.5), o + Vector2(0, mh * 0.5)]),
		PackedColorArray([_sea_col(0), _sea_col(0), _sea_col(DUSK_Y), _sea_col(DUSK_Y)]))
	L.draw_polygon(PackedVector2Array([o + Vector2(0, mh * 0.5), o + Vector2(mw, mh * 0.5), o + Vector2(mw, mh), o + Vector2(0, mh)]),
		PackedColorArray([_sea_col(DUSK_Y), _sea_col(DUSK_Y), _sea_col(WORLD.y), _sea_col(WORLD.y)]))
	if _mini_cache.is_empty():
		for i in ISLANDS.size():
			var arr := []
			for poly in _shape[i].lands:
				var dst := PackedVector2Array()
				for q in poly:
					dst.append(o + q * k)
				arr.append(dst)
			_mini_cache[i] = arr
		var hp := PackedVector2Array()
		for q in _harbor_poly:
			hp.append(o + q * k)
		_mini_cache["h"] = hp
	L.draw_colored_polygon(_mini_cache["h"], Color("8a7a6a"))
	for i in ISLANDS.size():
		var mc: Color = (ISLANDS[i].col as Color).darkened(0.25) if _open_i(i) else Color(0.75, 0.78, 0.9, 0.6)
		if _open_i(i):
			mc = Color(0.36, 0.38, 0.46).lerp(mc, light_e(String(ISLANDS[i].unit)))     # 還沒點亮的島：小地圖上也是灰的
		if not _open_i(i):
			var fg: Array = _fog[i]
			L.draw_colored_polygon(GW._ell(o + (fg[0] as Vector2) * k, float(fg[1]) * k * 0.9, float(fg[2]) * k * 0.9, 20), Color(0.8, 0.82, 0.92, 0.5))
		for poly in _mini_cache[i]:
			L.draw_colored_polygon(poly, mc)
		var sh: Dictionary = _shape[i]
		if sh.kind == "trig":
			L.draw_arc(o + (sh.o as Vector2) * k, float(sh.rr) * k, 0, TAU, 32, mc, maxf(1.5, float(sh.rw) * k), true)
			UITheme.dot(L, o + (sh.cp as Vector2) * k, float(sh.dr) * k, mc)
	var vr := _view()
	L.draw_rect(Rect2(o + vr.position * k, vr.size * k), Color(1, 1, 1, 0.5), false, 1.0)
	UITheme.dot(L, o + pos * k, 3.5 + sin(t * 4.0), Color("fff3c4"))


# ================= 主線故事、教學引導 =================

func focus_point(name: String, uid: String) -> Vector2:
	match name:
		"wide":
			return WORLD / 2.0       # 劇情的全景：整片海
		"harbor":
			return HARBOR + Vector2(600, 0)
		"goal":
			return _goal_pt if _goal_pt.x >= 0.0 else pos
		"unit":
			for i in ISLANDS.size():
				if ISLANDS[i].unit == uid:
					return ISLANDS[i].c
	return Vector2(-1, -1)


func _goal_world(gl: Dictionary) -> Vector2:
	if gl.is_empty():
		return Vector2(-1, -1)
	if gl.grade != "高二":
		return HARBOR + Vector2(300, 0)
	for i in ISLANDS.size():
		if ISLANDS[i].unit == gl.uid:
			return _docks[i]
	return Vector2(-1, -1)


func _tut_steps() -> Array:
	return [
		{"rect": func(): return _scr(pos, Vector2(50, 50)),
		 "text": UITheme.kb("這是我們的光舟！用方向鍵或 WASD 划船；也可以在畫面左半邊按住，用出現的搖桿掌舵。", "這是我們的光舟！在畫面左半邊按住，用出現的搖桿掌舵。")},
		{"rect": func(): return _goal_rect(),
		 "text": "上面的金色橫幅是「主線目標」；畫面邊緣的金色箭頭指著要去的島。"},
		{"rect": func(): return _scr(_goal_pt, Vector2(60, 60)) if _goal_pt.x >= 0.0 else Rect2(),
		 "text": UITheme.kb("這是島的碼頭。船開到碼頭旁邊會跳出卡片，按 Enter 或「上岸」就能登島。", "這是島的碼頭。船開到碼頭旁邊會跳出卡片，按「上岸」就能登島。")},
		{"rect": func(): return _tp.get_global_rect(),
		 "text": UITheme.kb("想直接過去的話，按「單元列表」（M），選好島就會開船過去。", "想直接過去的話，按「單元列表」，選好島就會開船過去。")},
		{"rect": func(): return Rect2(W - 18 - 210, 14, 210, 44),
		 "text": "右上角可以切回高一的曦光大陸。出航吧！"},
	]


func _scr(p: Vector2, half: Vector2) -> Rect2:
	var C := Vector2(W, H) / 2.0
	var sp := C - (cam + C) * zoom + p * zoom
	var half2 := half * zoom / BASE_ZOOM
	var r := Rect2(sp - half2, half2 * 2.0)
	return r if Rect2(0, 0, W, H).encloses(r) else Rect2()
