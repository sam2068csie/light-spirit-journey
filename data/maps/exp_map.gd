extends "res://data/maps/unit_map_base.gd"
## 指數與對數的地圖：指數島與對數島（幾何版）
##   ・兩座島的形狀就是 y = 2ˣ 和 y = log₂ x，隔著一道「鏡面海峽」（y = x）互為鏡像
##   ・指數島左邊的尾巴碎成一串小島，一個比一個小一半，越來越靠近「雷射牆」（漸近線 y = 0）卻永遠碰不到；
##     對數島的下端也一樣，靠近另一道雷射牆（x = 0）
##   ・對數島在「海平面」（y = 0）以下是潮間帶的淺灘：log 是負的那一段；海平面以上才是乾的陸地
##   ・光之橋跨過海峽，連起互為鏡像的兩點
##   ・八座聖地都由左下往右上排：指數島 1→3，對數島 4→8
##   ・劇情文字在下面的 STORY（key 沒有前綴，沿用舊地圖的紀錄，看過的不會不見）


const UNIT := "exp"
const PREFIX := ""
## 劇情：每一句 {text, who（說話的人，空白是旁白）, cam（"wide"、"site"、"isle0"、"isle1"）,
##   site（鏡頭／光靈對準第幾座聖地）, zoom, light（點亮第幾座）, spirit（光靈飛到第幾座）}
const STORY := {
	"prologue": [
		{"text": "光潮群島北邊，有兩座對望的島——指數島和對數島。", "cam": "wide"},
		{"text": "指數島往東北越爬越陡，就像 y = aˣ。", "cam": "isle0", "zoom": 1.4},
		{"text": "對數島剛好相反，先陡後緩。兩座島正好是彼此的鏡像。", "cam": "isle1", "zoom": 1.35},
		{"text": "混亂之霧也籠罩了這裡，八座聖地的光一盞一盞熄滅了……", "cam": "wide"},
		{"text": "上岸囉！這兩座島的形狀……一個越爬越陡、一個越走越平，好像在照鏡子耶！", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.7, "spirit": 0, "appear": true},
		{"text": "先去海邊的光之橋看看吧～", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.5},
	],
	"L1": [
		{"text": "斷掉的光橋重新連起來了！光從 (0, 1) 出發，一路往天空延伸。", "cam": "site", "site": 0, "zoom": 1.8, "light": 0},
		{"text": "哇～亮晶晶的！原來底數比 1 大就往上爬、比 1 小就溜下去呀。下一站是鍛造所，咻～", "who": "光靈", "cam": "site", "site": 1, "zoom": 1.4, "spirit": 1},
	],
	"L2": [
		{"text": "鍛造所的爐火再次燃起，叮叮噹噹的敲打聲響遍了整座島。", "cam": "site", "site": 1, "zoom": 1.8, "light": 1},
		{"text": "好燙好燙！不過我學會了：看到 a²ˣ 跟 aˣ 黏在一起，就說一聲「令 t = aˣ」！嘿嘿～", "who": "光靈", "cam": "site", "site": 2, "zoom": 1.4, "spirit": 2},
	],
	"L3": [
		{"text": "天秤神殿恢復了平衡，整座指數島都亮了起來！", "cam": "site", "site": 2, "zoom": 1.7, "light": 2},
		{"text": "唔哇——身體暖烘烘的，能量滿滿！這樣我應該……飛、飛得過海峽了吧？", "who": "光靈", "cam": "wide"},
		{"text": "底數比 1 小的時候，不等號要翻個跟斗，我記住啦！對數島，我來囉～咻——", "who": "光靈", "cam": "site", "site": 3, "zoom": 1.4, "spirit": 3},
	],
	"L4": [
		{"text": "鍊金塔的燒瓶冒出光泡泡，失傳的對數律回來了。", "cam": "site", "site": 3, "zoom": 1.8, "light": 3},
		{"text": "啵、啵、啵～泡泡好好玩！相加變相乘、相減變相除……嗯，我全部背起來了！大概！", "who": "光靈", "cam": "site", "site": 4, "zoom": 1.4, "spirit": 4},
	],
	"L5": [
		{"text": "鏡像之塔的鏡子重新映出光芒——", "cam": "site", "site": 4, "zoom": 1.8, "light": 4},
		{"text": "原來對數曲線，就是指數曲線對 y = x 照出來的倒影。", "cam": "wide"},
		{"text": "鏡子裡也有一個我耶！……他是不是也在想同一件事？我們繼續往東走吧！", "who": "光靈", "cam": "site", "site": 5, "zoom": 1.4, "spirit": 5},
	],
	"L6": [
		{"text": "守門員回到球門前，假的解再也混不進來。", "cam": "site", "site": 5, "zoom": 1.8, "light": 5},
		{"text": "撲——擋下來了！真數要大於 0，假的解不准進門～我也要當守門員！", "who": "光靈", "cam": "site", "site": 6, "zoom": 1.4, "spirit": 6},
	],
	"L7": [
		{"text": "羅盤的指針不再亂轉，穩穩指向前方。", "cam": "site", "site": 6, "zoom": 1.8, "light": 6},
		{"text": "轉呀轉……頭好暈。不過我知道了：底數跟真數站在 1 的同一邊，就是正的喔！", "who": "光靈", "cam": "site", "site": 7, "zoom": 1.4, "spirit": 7},
	],
	"L8": [
		{"text": "島嶼最東邊的望遠鏡亮了，一道光束射向星空。", "cam": "site", "site": 7, "zoom": 1.8, "light": 7},
		{"text": "哇啊，看得好遠好遠！首數說星星有多大、尾數說它長什麼樣子……星星在跟我揮手耶～", "who": "光靈", "cam": "site", "site": 7, "zoom": 1.5},
	],
	"epilogue": [
		{"text": "八座聖地全部點亮，混亂之霧散去了。", "cam": "wide", "all": true},
		{"text": "指數島與對數島在夜空下閃閃發光，海面映出兩條互為鏡像的曲線。", "cam": "wide"},
		{"text": "雙島的光回來了！紀念品「雙島光橋」也送到小屋囉～", "who": "光靈", "cam": "wide"},
	],
}

const STORY_TITLES := {"prologue": "序章．雙島的倒影", "L1": "第一幕．光之橋", "L2": "第二幕．換元鍛造所",
	"L3": "第三幕．天秤神殿", "L4": "第四幕．對數鍊金術", "L5": "第五幕．鏡像之塔", "L6": "第六幕．真數守門員",
	"L7": "第七幕．正負羅盤", "L8": "第八幕．位數望遠鏡", "epilogue": "終章．兩座島的光"}



# ---------------- 地形 ----------------
## 數學座標 → 畫面：原點 O，一單位 S 像素
const O := Vector2(470, 420)
const SC := Vector2(115, 74)     # 一單位：橫的拉寬一點，畫面比較不擠
const CW := 46.0                  # 島的陸地寬度
const EXP_U := Vector2(-1.3, 2.3)       # 指數島：x 的範圍
const LOG_V := Vector2(-1.75, 1.9)      # 對數島：y 的範圍（對數島上的點 = 指數島上的點對 y = x 翻過去）
const TAILS := [-1.85, -2.3, -2.75, -3.2, -3.65]      # 碎成小島的尾巴（參數），一個比一個小
const TAIL_R := [10.0, 7.0, 5.0, 3.5, 2.5]

## 八座聖地：isle 0 指數島（參數 u = x）、1 對數島（參數 u = y）；r 是這一區的參數範圍，at 是地標的位置，lab 是名牌
const SITES := [
	{"id": "L1", "isle": 0, "r": Vector2(-1.3, 0.3), "at": -0.4, "lab": Vector2(-84, -12)},
	{"id": "L2", "isle": 0, "r": Vector2(0.3, 1.45), "at": 0.95, "lab": Vector2(-92, 4)},
	{"id": "L3", "isle": 0, "r": Vector2(1.45, 2.3), "at": 1.95, "lab": Vector2(-90, 10)},
	{"id": "L4", "isle": 1, "r": Vector2(-1.75, -0.85), "at": -1.3, "lab": Vector2(-96, 18)},
	{"id": "L5", "isle": 1, "r": Vector2(-0.85, 0.0), "at": -0.42, "lab": Vector2(84, 26)},
	{"id": "L6", "isle": 1, "r": Vector2(0.0, 0.95), "at": 0.48, "lab": Vector2(88, 28)},
	{"id": "L7", "isle": 1, "r": Vector2(0.95, 1.9), "at": 1.42, "lab": Vector2(70, 34)},
	{"id": "L8", "isle": 2, "r": Vector2(0.0, 0.0), "at": 0.0, "lab": Vector2(0, 62)},
]

## 終焉之塔：鏡面海峽的上游（y = x 上）
const TOWER_P := Vector2(470 + 2.95 * 115.0, 420 - 2.95 * 74.0 + 6.0)
## 天文台小島（位數望遠鏡）：對數島的東北外海
const OBS_C := Vector2(1062, 192)
const OBS_R := 46.0

## 小離島（位置、大小）
const ISLETS := [[Vector2(1040, 120), 10.0], [Vector2(1090, 420), 13.0], [Vector2(170, 150), 9.0], [Vector2(300, 560), 11.0]]



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
	return isle_p(0, 0.8) if k == 0 else isle_p(1, 0.2)

func _fx_under() -> void:
	_draw_mirror_shine()
	_draw_bridge()





# ================= 資料 =================












# ================= 幾何 =================

## 島上參數 u 的點（isle 0：(u, 2^u)；isle 1：(2^u, u)）
static func isle_p(isle: int, u: float) -> Vector2:
	var a := pow(2.0, u)
	if isle == 0:
		return O + Vector2(u, -a) * SC
	if isle == 2:
		return OBS_C
	return O + Vector2(a, -u) * SC


## 島上參數 u 的法向量（指數島：往左上那一側；對數島：往右下那一側）
static func isle_n(isle: int, u: float) -> Vector2:
	var d := isle_p(isle, u + 0.01) - isle_p(isle, u - 0.01)
	d = d.normalized()
	return Vector2(d.y, -d.x) if isle == 0 else Vector2(-d.y, d.x)


static func isle_range(isle: int) -> Vector2:
	return EXP_U if isle == 0 else LOG_V


## 島中線的取樣點（照弧長大約每 6 像素一點）
static func isle_pts(isle: int, a: float, b: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var u := a
	pts.append(isle_p(isle, a))
	while u < b:
		var p := isle_p(isle, u)
		var q := isle_p(isle, u + 0.01)
		var step := clampf(0.01 * 6.0 / maxf(0.1, p.distance_to(q)), 0.002, 0.08)
		u = minf(u + step, b)
		pts.append(isle_p(isle, u))
	return pts


## 島的一側邊緣
static func isle_edge(isle: int, a: float, b: float, side: float, pad: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var mid := isle_pts(isle, a, b)
	for k in mid.size():
		var u := _u_of(isle, mid[k])
		pts.append(mid[k] + isle_n(isle, u) * side * (CW / 2.0 + pad))
	return pts


static func _u_of(isle: int, p: Vector2) -> float:
	var v := (p - O) / SC
	return v.x if isle == 0 else -v.y


## 一段島的色塊（兩側邊緣圍起來）
static func isle_band(isle: int, a: float, b: float, half: float) -> PackedVector2Array:
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for p in isle_pts(isle, a, b):
		var n := isle_n(isle, _u_of(isle, p))
		top.append(p + n * half)
		bot.append(p - n * half)
	bot.reverse()
	top.append_array(bot)
	return top


## 整座島的外形（給高二大地圖畫縮圖用；兩端是半圓）
static func island_poly(isle: int) -> PackedVector2Array:
	var r := isle_range(isle)
	var mid := isle_pts(isle, r.x, r.y)
	var m := mid.size()
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for k in m:
		var d := (mid[mini(k + 1, m - 1)] - mid[maxi(k - 1, 0)]).normalized()
		var n := d.orthogonal()
		left.append(mid[k] + n * CW / 2.0)
		right.append(mid[k] - n * CW / 2.0)
	# 頭尾往外收成半圓：從一側繞過端點到另一側
	var out := PackedVector2Array(left)
	var de := (mid[m - 1] - mid[m - 2]).normalized()
	var ne := de.orthogonal()
	for k in range(1, 16):
		var a := PI * k / 16.0
		out.append(mid[m - 1] + (ne * cos(a) + de * sin(a)) * CW / 2.0)
	right.reverse()
	out.append_array(right)
	var d0 := (mid[0] - mid[1]).normalized()
	var n0 := d0.orthogonal()
	for k in range(1, 16):
		var a := PI * k / 16.0
		out.append(mid[0] + (n0 * cos(a) + d0 * sin(a)) * CW / 2.0)
	return out


## 聖地的位置（地標站的地方）
static func site_point(i: int) -> Vector2:
	var st: Dictionary = SITES[i]
	return isle_p(int(st.isle), float(st.at))


static func label_point(i: int) -> Vector2:
	return site_point(i) + Vector2(SITES[i].lab)


## 光靈停在名牌上方
static func hover_point(i: int) -> Vector2:
	return label_point(i) + Vector2(0, -36)


## 這一點在陸地上的哪一座聖地（−1：海上）
static func region_at(p: Vector2) -> int:
	if p.distance_to(OBS_C) <= OBS_R:
		return 7
	var best := -1
	var bd := CW / 2.0 + 4.0
	for isle in 2:
		var r := isle_range(isle)
		var u := r.x
		while u <= r.y:
			var d := p.distance_to(isle_p(isle, u))
			if d < bd:
				bd = d
				best = _site_of(isle, u)
			u += 0.02
	return best


static func _site_of(isle: int, u: float) -> int:
	for i in SITES.size():
		var st: Dictionary = SITES[i]
		if int(st.isle) == isle and u >= st.r.x - 0.0001 and u <= st.r.y + 0.0001:
			return i
	return -1



# ================= 點選 =================















# ================= 下方的資訊卡 =================







# ================= 更新 =================




## 這座聖地的陸地上隨機一點（冒光點用）
func _rand_point(i: int) -> Vector2:
	var st: Dictionary = SITES[i]
	var isle: int = st.isle
	if isle == 2:
		return OBS_C + Vector2.from_angle(randf() * TAU) * randf_range(4.0, OBS_R - 6.0)
	var u := randf_range(st.r.x, st.r.y)
	return isle_p(isle, u) + isle_n(isle, u) * randf_range(-0.4, 0.4) * CW


# ================= 繪圖 =================





const LAND := Color("1f2647")
const HIGH := Color("272f58")
const TIDE := Color("1d4152")       # 對數島海平面以下：潮間帶淺灘
const TIDE_HI := Color("245468")
const SAND := Color(0.85, 0.8, 0.62, 0.30)
const MIRROR_A := Vector2(470 - 1.4 * 115.0, 420 + 1.4 * 74.0)      # 鏡面海峽的兩端（y = x）
const MIRROR_B := Vector2(470 + 3.2 * 115.0, 420 - 3.2 * 74.0)


## 不會動的陸地（畫在 _land）
func _draw_land(layer: CanvasItem) -> void:
	_tgt = layer
	var L := layer
	# ---- 鏡面海峽：沿著 y = x 一道平靜、比較亮的海水 ----
	# 兩端淡出：一段一段畫，越靠近兩端越淡
	for k in 24:
		var a0 := MIRROR_A.lerp(MIRROR_B, k / 24.0)
		var a1 := MIRROR_A.lerp(MIRROR_B, (k + 1) / 24.0)
		var f := sin(PI * (k + 0.5) / 24.0)
		L.draw_line(a0, a1, Color(0.6, 0.78, 1.0, 0.06 * f), 40.0)
	# ---- 雷射牆的底座（光束每幀畫在 _fx）----
	# 小離島
	for it in ISLETS:
		_islet(L, it[0], it[1], false)
	# 尾巴碎成的小島：一個比一個小，越來越靠近雷射牆
	for k in TAILS.size():
		_islet(L, isle_p(0, TAILS[k]), TAIL_R[k], false)
		_islet(L, isle_p(1, TAILS[k] - 0.4), TAIL_R[k], true)
	# 塔下的小島
	_islet(L, TOWER_P + Vector2(0, -4), 26.0, false)
	# ---- 兩座島 ----
	var e := isle_pts(0, EXP_U.x, EXP_U.y)
	var lw := isle_pts(1, LOG_V.x, 0.0)
	var lu := isle_pts(1, 0.0, LOG_V.y)
	var ea := isle_pts(0, EXP_U.x, EXP_U.y)
	var la := isle_pts(1, LOG_V.x, LOG_V.y)
	for pts in [ea, la]:
		_round_line(L, pts, Color(0.35, 0.7, 0.95, 0.05), CW + 44.0)
		_round_line(L, pts, Color(0.4, 0.75, 1.0, 0.08), CW + 22.0)
	UITheme.dot(L, OBS_C, OBS_R + 22.0, Color(0.35, 0.7, 0.95, 0.05))
	UITheme.dot(L, OBS_C, OBS_R + 11.0, Color(0.4, 0.75, 1.0, 0.08))
	# 頭尾都收成圓的
	_round_line(L, e, LAND, CW)
	_round_line(L, lu, LAND, CW, false, true)
	_round_line(L, lw, TIDE, CW, true, false)
	_round_line(L, e, HIGH, CW - 18.0)
	_round_line(L, lu, HIGH, CW - 18.0, false, true)
	_round_line(L, lw, TIDE_HI, CW - 18.0, true, false)
	# 天文台小島
	UITheme.dot(L, OBS_C, OBS_R, LAND)
	UITheme.dot(L, OBS_C, OBS_R - 9.0, HIGH)
	L.draw_arc(OBS_C, OBS_R, 0, TAU, 48, SAND, 3.0, true)
	# 點亮的區域
	for i in SITES.size():
		_draw_region_fill(L, i)
	# 淺灘上的水紋
	var v := LOG_V.x + 0.1
	while v < -0.05:
		var p := isle_p(1, v)
		var n := isle_n(1, v)
		var tg := n.orthogonal()
		for s: float in [-0.25, 0.25]:
			var c := p + n * s * CW
			L.draw_polyline(PackedVector2Array([c - tg * 7.0, c - tg * 2.0 + n * 2.0, c + tg * 2.0, c + tg * 7.0 + n * 2.0]),
				Color(0.7, 0.95, 1.0, 0.22), 1.3, true)
		v += 0.17
	# 海平面：對數島從水裡冒出來的地方
	var w0 := isle_p(1, 0.0)
	var wn := isle_n(1, 0.0)
	L.draw_line(w0 - wn * (CW / 2.0 + 18.0), w0 + wn * (CW / 2.0 + 18.0), Color(0.75, 0.95, 1.0, 0.45), 2.0, true)
	# 沙灘
	_draw_sand(L)
	# 山和樹
	_draw_details(L)
	# 區域之間的虛線邊界
	_draw_borders(L)
	_tgt = self


## 粗線，兩端加半圓（島的頭尾收圓）
func _round_line(L: CanvasItem, pts: PackedVector2Array, c: Color, w: float, cap0 := true, cap1 := true) -> void:
	L.draw_polyline(pts, c, w, true)
	if cap0:
		_half_cap(L, pts[0], pts[0] - pts[1], c, w / 2.0)
	if cap1:
		_half_cap(L, pts[pts.size() - 1], pts[pts.size() - 1] - pts[pts.size() - 2], c, w / 2.0)


func _half_cap(L: CanvasItem, c: Vector2, dir: Vector2, col: Color, r: float) -> void:
	var d := dir.normalized()
	var n := d.orthogonal()
	var poly := PackedVector2Array()
	for k in 17:
		var a := PI * k / 16.0
		poly.append(c + n * cos(a) * r + d * sin(a) * r)
	L.draw_colored_polygon(poly, col)


func _islet(L: CanvasItem, c: Vector2, r: float, tide: bool) -> void:
	UITheme.dot(L, c, r + 9.0, Color(0.35, 0.7, 0.95, 0.06))
	UITheme.dot(L, c, r, TIDE if tide else LAND)
	UITheme.dot(L, c + Vector2(-1, -1), r * 0.55, TIDE_HI if tide else HIGH)
	L.draw_arc(c, r, 0, TAU, 24, SAND, 2.0, true)


func _draw_sand(L: CanvasItem) -> void:
	if not _cache.has("sand"):
		var lines := []
		for isle in 2:
			var r := isle_range(isle)
			for side in [1.0, -1.0]:
				lines.append(isle_edge(isle, r.x, r.y, side))
			var mid := isle_pts(isle, r.x, r.y)
			var m := mid.size()
			for end in [[mid[0], mid[0] - mid[1]], [mid[m - 1], mid[m - 1] - mid[m - 2]]]:
				var c: Vector2 = end[0]
				var d: Vector2 = (end[1] as Vector2).normalized()
				var n := d.orthogonal()
				var arc := PackedVector2Array()
				for k in 17:
					var a := PI * k / 16.0
					arc.append(c + (n * cos(a) + d * sin(a)) * CW / 2.0)
				lines.append(arc)
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
	if int(st.isle) == 2:
		UITheme.dot(L, OBS_C, OBS_R, Color(c.r, c.g, c.b, 0.30 * gl).darkened(0.1))
		UITheme.dot(L, OBS_C, OBS_R - 9.0, Color(c.r, c.g, c.b, 0.22 * gl))
		return
	var isle: int = st.isle
	var rr := isle_range(isle)
	var pts := isle_pts(isle, st.r.x, st.r.y)
	var c0 := Color(c.r, c.g, c.b, 0.30 * gl).darkened(0.1)
	var c1 := Color(c.r, c.g, c.b, 0.22 * gl)
	var at0: bool = absf(st.r.x - rr.x) < 0.001
	var at1: bool = absf(st.r.y - rr.y) < 0.001
	L.draw_polyline(pts, c0, CW, false)
	L.draw_polyline(pts, c1, CW - 18.0, false)
	if at0 or at1:
		if at0:
			_half_cap(L, pts[0], pts[0] - pts[1], c0, CW / 2.0)
			_half_cap(L, pts[0], pts[0] - pts[1], c1, CW / 2.0 - 9.0)
		if at1:
			var n := pts.size()
			_half_cap(L, pts[n - 1], pts[n - 1] - pts[n - 2], c0, CW / 2.0)
			_half_cap(L, pts[n - 1], pts[n - 1] - pts[n - 2], c1, CW / 2.0 - 9.0)


## 點亮區域的發光邊（會脈動，所以每幀畫）
func _draw_region_ring(i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var st: Dictionary = SITES[i]
	var c: Color = Center.level_info(st.id).color
	var pulse := 0.85 + 0.15 * sin(t * 2.0 + i)
	var key := "ring%d" % i
	if not _cache.has(key):
		if int(st.isle) == 2:
			var circ := PackedVector2Array()
			for k in 49:
				circ.append(OBS_C + Vector2.from_angle(TAU * k / 48.0) * OBS_R)
			_cache[key] = [circ]
		else:
			_cache[key] = [isle_edge(int(st.isle), st.r.x, st.r.y, 1.0), isle_edge(int(st.isle), st.r.x, st.r.y, -1.0)]
	for ln in _cache[key]:
		_tgt.draw_polyline(ln, Color(c.r, c.g, c.b, 0.25 * gl * pulse), 7.0)
		_tgt.draw_polyline(ln, Color(c.r, c.g, c.b, 0.9 * gl).lightened(0.3), 2.0, true)


func _make_details() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 29
	for k in 80:
		var isle := 0 if k < 34 else 1
		var r := isle_range(isle)
		var u := rng.randf_range(r.x + 0.05, r.y - 0.05)
		var p := isle_p(isle, u) + isle_n(isle, u) * rng.randf_range(-0.3, 0.3) * CW
		var si := _site_of(isle, u)
		if si < 0:
			continue
		var near := false
		for j in SITES.size():
			if p.distance_to(site_point(j)) < 44.0:
				near = true
		if isle == 1 and u < 0.0:
			near = true          # 淺灘上不長樹
		if not near:
			out.append({"p": p, "si": si, "k": k})
	return out




## 區域之間的虛線邊界（兩邊都點亮時變成金色）
func _draw_borders(L: CanvasItem) -> void:
	for i in SITES.size() - 1:
		if SITES[i].isle != SITES[i + 1].isle:
			continue
		var isle: int = SITES[i].isle
		var u: float = SITES[i].r.y
		var p := isle_p(isle, u)
		var n := isle_n(isle, u)
		var both: bool = glow[i] > 0.6 and glow[i + 1] > 0.6
		L.draw_dashed_line(p + n * CW / 2.0, p - n * CW / 2.0, Color(1, 0.88, 0.55, 0.65) if both else Color(1, 1, 1, 0.28), 2.0, 7.0)




## 鏡面海峽的水面反光：一道道斜斜的亮紋慢慢流動
func _draw_mirror_shine() -> void:
	var d := (MIRROR_B - MIRROR_A).normalized()
	var n := d.orthogonal()
	var mlen := MIRROR_A.distance_to(MIRROR_B)
	for k in 22:
		var s := fposmod(k * 37.0 + t * 14.0, mlen)
		var p := MIRROR_A + d * s + n * (sin(k * 2.3) * 14.0)
		var a := (0.12 + 0.1 * sin(t * 1.8 + k)) * sin(PI * s / mlen)
		_tgt.draw_line(p - d * 6.0, p + d * 6.0, Color(0.9, 0.95, 1.0, a), 1.5, true)


## 雷射牆：柱子之間的光束（會閃）
func _draw_walls() -> void:
	var a := 0.55 + 0.25 * sin(t * 6.0)
	var y0 := Vector2(-40.0, O.y)
	var y1 := O + Vector2(-1.55, 0.0) * SC
	var x0 := O + Vector2(0.0, 1.95) * SC
	var x1 := Vector2(O.x, H + 40.0)
	for seg in [[y0, y1], [x0, x1]]:
		_tgt.draw_line(seg[0], seg[1], Color(1, 0.42, 0.66, 0.16), 9.0)
		_tgt.draw_line(seg[0], seg[1], Color(1, 0.62, 0.8, a), 2.0)


## 光之橋：跨過鏡面海峽，連起光之橋（指數島）和鏡像之塔（對數島）這一對鏡像點
func _draw_bridge() -> void:
	var a := isle_p(0, -0.4) + isle_n(0, -0.4) * -14.0
	var b := isle_p(1, -0.45) + isle_n(1, -0.45) * -14.0
	var mid := (a + b) / 2.0 + Vector2(10, -10) * 2.0
	var pts := PackedVector2Array()
	for k in 21:
		var s := k / 20.0
		pts.append(a.lerp(mid, s).lerp(mid.lerp(b, s), s))
	var gl: float = maxf(glow[0], glow[4])
	_tgt.draw_polyline(pts, Color(0.37, 0.83, 1.0, 0.10 + 0.18 * gl), 12.0, true)
	_tgt.draw_polyline(pts, Color(0.75, 0.94, 1.0, 0.35 + 0.6 * gl), 3.0, true)
	if gl > 0.5:
		var u := fposmod(t * 0.4, 1.0)
		UITheme.dot(_tgt, pts[int(u * 20.0)], 3.5, Color(1, 1, 0.9, 0.9))


## 旅程路線：一串光點（走過的路段是金色）；第 3 → 4 座從指數島飛過海峽
func _route(i: int) -> PackedVector2Array:
	var key := "route%d" % i
	if _cache.has(key):
		return _cache[key]
	var pts := PackedVector2Array()
	var a: Dictionary = SITES[i]
	var b: Dictionary = SITES[i + 1]
	if a.isle == b.isle:
		pts = isle_pts(int(a.isle), a.at, b.at)
	else:
		var p0 := site_point(i)
		var p1 := site_point(i + 1)
		var ctl := O + Vector2(1.9, -1.9) * SC if i == 2 else (p0 + p1) / 2.0 + Vector2(0, -50)
		for k in 31:
			var s := k / 30.0
			pts.append(p0.lerp(ctl, s).lerp(ctl.lerp(p1, s), s))
	_cache[key] = pts
	return pts








## 八座聖地的地標
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
		0:   # 光之橋：橋頭的拱門和一盞燈（橋本身跨過海峽，畫在 _draw_bridge）
			var c0 := p + Vector2(0, -2)
			T.draw_line(c0 + Vector2(-16, 0), c0 + Vector2(-16, -30), base, 5.0)
			T.draw_line(c0 + Vector2(16, 0), c0 + Vector2(16, -30), base, 5.0)
			var arc := PackedVector2Array()
			for k in 13:
				var a := PI * k / 12.0
				arc.append(c0 + Vector2(cos(a) * 16.0, -30.0 - sin(a) * 12.0))
			T.draw_polyline(arc, base.lightened(0.15), 5.0, true)
			UITheme.dot(T, c0 + Vector2(0, -50), 5.0, light if gl > 0.05 else dark.lightened(0.2))
			if gl > 0.05:
				UITheme.dot(T, c0 + Vector2(0, -50), 13.0, Color(col.r, col.g, col.b, 0.22 * gl))
		1:   # 換元鍛造所：爐子＋煙囪，爐火上方一道拋物線的火花（換元之後變成二次式）
			T.draw_rect(Rect2(p + Vector2(-20, -26), Vector2(40, 26)), base)
			T.draw_rect(Rect2(p + Vector2(8, -42), Vector2(9, 16)), base.darkened(0.1))
			T.draw_rect(Rect2(p + Vector2(-10, -16), Vector2(16, 12)), dark)
			var fire := Color(1, 0.6, 0.25, 0.4 + 0.5 * (gl if gl > 0.05 else 0.3 + 0.2 * sin(t * 5.0)))
			UITheme.dot(T, p + Vector2(-2, -9), 5.0, fire)
			var para := PackedVector2Array()
			for k in 17:
				var x := -18.0 + 36.0 * k / 16.0
				para.append(p + Vector2(x - 2.0, -46.0 + x * x / 26.0))
			T.draw_polyline(para, Color(1, 0.75, 0.4, 0.25 + 0.7 * gl), 2.0, true)
			for k in 3:
				var sp := fposmod(t * 0.8 + k * 0.33, 1.0)
				UITheme.dot(T, p + Vector2(12.5, -46.0 - 24.0 * sp), 3.0 * (1.0 - sp), Color(0.8, 0.8, 0.9, 0.35 * (1.0 - sp)))
		2:   # 天秤神殿：柱子＋橫桿，兩邊的秤盤（亮了之後平衡）
			T.draw_rect(Rect2(p + Vector2(-18, -6), Vector2(36, 6)), base)
			T.draw_line(p + Vector2(0, -6), p + Vector2(0, -44), base.lightened(0.1), 4.0)
			var tilt := 0.0 if gl > 0.5 else 0.25 * sin(t * 1.4)
			var arm := Vector2(cos(tilt), sin(tilt)) * 24.0
			var top := p + Vector2(0, -44)
			T.draw_line(top - arm, top + arm, base.lightened(0.25), 3.0, true)
			for sg in [-1.0, 1.0]:
				var e: Vector2 = top + arm * sg
				T.draw_line(e, e + Vector2(0, 12), base.lightened(0.2), 1.5)
				T.draw_arc(e + Vector2(0, 12), 8.0, 0.0, PI, 10, light if gl > 0.05 else base.lightened(0.3), 2.5, true)
			UITheme.dot(T, top, 3.5, light if gl > 0.05 else base.lightened(0.35))
		3:   # 對數鍊金術：燒瓶，冒出一顆比一顆大的泡泡（相乘變相加）
			var fc := p + Vector2(0, -14)
			UITheme.dot(T, fc, 13.0, dark.lightened(0.12))
			T.draw_arc(fc, 13.0, 0, TAU, 28, base.lightened(0.3), 2.0, true)
			T.draw_rect(Rect2(fc + Vector2(-4, -26), Vector2(8, 16)), dark.lightened(0.12))
			T.draw_rect(Rect2(fc + Vector2(-4, -26), Vector2(8, 16)), base.lightened(0.3), false, 2.0)
			UITheme.dot(T, fc + Vector2(0, 3), 8.0, Color(col.r, col.g, col.b, 0.3 + 0.5 * gl))
			for k in 4:
				var u := fposmod(t * 0.35 + k * 0.25, 1.0)
				var r := 1.5 + 1.6 * k * (0.6 + 0.4 * u)
				var bp := fc + Vector2(4.0 * sin(t * 2.0 + k) + 2.0 * k, -30.0 - 40.0 * u)
				T.draw_arc(bp, r, 0, TAU, 16, Color(col.r, col.g, col.b, (0.3 + 0.6 * gl) * (1.0 - u)).lightened(0.3), 1.5, true)
		4:   # 鏡像之塔：淺灘上的塔，倒影映在水裡
			var body := PackedVector2Array([p + Vector2(-10, 0), p + Vector2(10, 0), p + Vector2(6, -46), p + Vector2(-6, -46)])
			var ref := PackedVector2Array([p + Vector2(-10, 0), p + Vector2(10, 0), p + Vector2(6, 30), p + Vector2(-6, 30)])
			T.draw_colored_polygon(ref, Color(col.r, col.g, col.b, 0.10 + 0.2 * gl) if gl > 0.05 else Color(0.5, 0.6, 0.9, 0.12))
			T.draw_colored_polygon(body, base)
			T.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -46), p + Vector2(9, -46), p + Vector2(0, -62)]), base.lightened(0.15))
			T.draw_rect(Rect2(p + Vector2(-4, -36), Vector2(8, 10)), light if gl > 0.05 else dark.lightened(0.3))
			for k in 3:
				var yy := 6.0 + k * 8.0 + 2.0 * sin(t * 2.0 + k)
				T.draw_line(p + Vector2(-12 + k * 2, yy), p + Vector2(12 - k * 2, yy), Color(0.8, 0.95, 1.0, 0.25), 1.2)
		5:   # 真數守門員：一道門，假的解進不來
			for sg in [-1.0, 1.0]:
				T.draw_rect(Rect2(p + Vector2(sg * 18.0 - 3.0, -40), Vector2(6, 40)), base.lightened(0.1))
			T.draw_line(p + Vector2(-18, -40), p + Vector2(18, -40), base.lightened(0.2), 4.0)
			var net := Color(1, 1, 1, 0.12 + 0.2 * gl)
			for k in 4:
				T.draw_line(p + Vector2(-15 + k * 10, -38), p + Vector2(-15 + k * 10, -2), net, 1.0)
			for k in 3:
				T.draw_line(p + Vector2(-15, -30 + k * 10), p + Vector2(15, -30 + k * 10), net, 1.0)
			var bx := 22.0 * sin(t * 1.3) if gl < 0.5 else 0.0
			UITheme.dot(T, p + Vector2(bx, -20), 6.0, light if gl > 0.05 else dark.lightened(0.35))
		6:   # 正負羅盤：圓盤上半寫 ＋、下半寫 －，指針擺動（亮了之後停在正確的一邊）
			var cc := p + Vector2(0, -28)
			T.draw_rect(Rect2(p + Vector2(-6, -12), Vector2(12, 12)), base)
			UITheme.dot(T, cc, 19.0, dark.lightened(0.1))
			T.draw_arc(cc, 19.0, 0, TAU, 32, base.lightened(0.3), 2.0, true)
			T.draw_line(cc + Vector2(-17, 0), cc + Vector2(17, 0), Color(1, 1, 1, 0.25), 1.0)
			T.draw_line(cc + Vector2(-4, -10), cc + Vector2(4, -10), light, 2.0)
			T.draw_line(cc + Vector2(0, -14), cc + Vector2(0, -6), light, 2.0)
			T.draw_line(cc + Vector2(-4, 10), cc + Vector2(4, 10), Color(0.6, 0.75, 1.0, 0.5 + 0.5 * gl), 2.0)
			var a := -PI / 2.0 + (0.5 * sin(t * 0.9) if gl > 0.5 else 1.4 * sin(t * 1.7))
			T.draw_line(cc, cc + Vector2(cos(a), sin(a)) * 15.0, Color(1, 0.85, 0.45, 0.6 + 0.4 * gl), 2.5, true)
			UITheme.dot(T, cc, 2.5, Color(1, 1, 1, 0.8))
		7:   # 位數望遠鏡：天文台小島上的圓頂，旁邊一架望遠鏡對著星星
			var dm := p + Vector2(-14, 0)
			T.draw_rect(Rect2(dm + Vector2(-16, -16), Vector2(32, 16)), base)
			var dome := PackedVector2Array()
			for k in 17:
				var a := PI * k / 16.0
				dome.append(dm + Vector2(cos(a) * 16.0, -16.0 - sin(a) * 16.0))
			T.draw_colored_polygon(dome, base.lightened(0.15))
			T.draw_line(dm + Vector2(-2, -31), dm + Vector2(4, -18), dark, 3.0)
			p = p + Vector2(20, 2)
			T.draw_line(p + Vector2(0, -16), p + Vector2(-12, 0), base, 2.5)
			T.draw_line(p + Vector2(0, -16), p + Vector2(12, 0), base, 2.5)
			T.draw_line(p + Vector2(0, -16), p + Vector2(0, 0), base, 2.5)
			var aim := Vector2(cos(-0.95), sin(-0.95))
			var c7 := p + Vector2(0, -20)
			T.draw_line(c7 - aim * 14.0, c7 + aim * 22.0, base.lightened(0.2), 8.0, true)
			UITheme.dot(T, c7 + aim * 23.0, 5.0, light if gl > 0.05 else dark.lightened(0.3))
			if gl > 0.05:
				var tip := c7 + aim * 24.0
				T.draw_colored_polygon(PackedVector2Array([tip, tip + aim.rotated(-0.12) * 140.0, tip + aim.rotated(0.12) * 140.0]),
					Color(col.r, col.g, col.b, 0.08 * gl))
				for k in 4:
					var sp := tip + aim.rotated(0.08 * (k - 1.5)) * (60.0 + 24.0 * k)
					UITheme.dot(T, sp, 2.0 + 0.8 * sin(t * 3.0 + k), Color(1, 0.97, 0.8, 0.8 * gl))


func _draw_names(font: Font) -> void:
	UITheme.text_ol(_tgt, font, Vector2(214, 300), "指數島", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(30), Color(1.0, 0.86, 0.5, 0.85), 6)
	UITheme.text_ol(_tgt, font, Vector2(760, 470), "對數島", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(30), Color(0.6, 0.85, 1.0, 0.85), 6)











# ================= 劇情 =================











