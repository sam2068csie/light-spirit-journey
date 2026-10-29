extends Control
## 世界地圖：黯淡的指數島與對數島、八座聖地、光靈與劇情動畫
##   ・俯瞰的兩座島：指數島往東北越來越陡（像 y = aˣ），對數島先往北陡升、再往東越來越平（像 y = logₐ x）
##   ・每座島分成幾個區域（虛線是邊界），每個區域是一個大關
##   ・每個大關的旅程答對越多，那一區就越亮；整個大關完成時播放一段劇情，區域完全點亮
##   ・點聖地選取（光靈會飛過去），再按「出發」或再點一次進入關卡
## 劇情文字寫在下面的 STORY，可以直接修改。

const UITheme := preload("game_theme.gd")
const SL := preload("spirit_look.gd")
const Game := preload("game.gd")
const Center := preload("review_center.gd")

const W := 1152.0
const H := 648.0
## 兩座島（俯瞰）：沿著一條「脊線」長出來
##   指數島：從西南的海岸出發往東北延伸，越往後越陡——像 y = aˣ
##   對數島：從南方的小海角往北陡升，接著越來越平緩地往東延伸——像 y = logₐ x
const ISLES := [
	{"a": Vector2(118, 474), "b": Vector2(500, 158), "kind": "exp", "w": 50.0, "seed": 1.3},
	{"a": Vector2(616, 572), "b": Vector2(1084, 246), "kind": "log", "w": 46.0, "seed": 4.1},
]

## 每個區域鼓起來的大小（寬度倍率）與交界處腰身的寬度
const BEAD := [1.5, 1.38, 1.55, 1.3, 1.22, 1.45, 1.28, 1.42]
const NECK := 0.78

## （舊版的胖瘦表，保留做參考，目前沒有使用）
const PROFILE := [
	[[0.0, 1.0], [0.16, 1.45], [0.30, 0.95], [0.36, 0.55], [0.50, 1.25], [0.62, 1.0], [0.69, 0.62], [0.82, 1.4], [0.93, 1.05], [1.0, 0.9]],
	[[0.0, 1.0], [0.05, 1.35], [0.11, 0.58], [0.20, 1.1], [0.31, 0.62], [0.42, 1.55], [0.55, 0.66], [0.65, 1.25],
	 [0.72, 0.95], [0.78, 0.6], [0.89, 1.4], [1.0, 1.0]],
]

## 半島（amp > 0）與海灣（amp < 0）：讓海岸線像真的島一樣凹凸不平
##   u：在脊線的哪裡　side：哪一側（1 / −1）　amp：凸出多少（以島寬為單位）　k：範圍
const CAPES := [   # （目前沒有使用：圓滑版的島不加半島和海灣）
	[{"u": 0.10, "side": -1.0, "amp": 0.75, "k": 0.045}, {"u": 0.24, "side": 1.0, "amp": -0.35, "k": 0.04},
	 {"u": 0.33, "side": 1.0, "amp": 0.55, "k": 0.035}, {"u": 0.50, "side": -1.0, "amp": -0.4, "k": 0.05},
	 {"u": 0.60, "side": -1.0, "amp": 0.6, "k": 0.03}, {"u": 0.74, "side": 1.0, "amp": 0.45, "k": 0.04},
	 {"u": 0.86, "side": -1.0, "amp": -0.3, "k": 0.04}, {"u": 0.95, "side": 1.0, "amp": 0.8, "k": 0.03}],
	[{"u": 0.04, "side": -1.0, "amp": 0.9, "k": 0.03}, {"u": 0.16, "side": 1.0, "amp": 0.5, "k": 0.04},
	 {"u": 0.28, "side": -1.0, "amp": -0.4, "k": 0.04}, {"u": 0.42, "side": 1.0, "amp": -0.35, "k": 0.05},
	 {"u": 0.50, "side": -1.0, "amp": 0.7, "k": 0.035}, {"u": 0.66, "side": 1.0, "amp": 0.55, "k": 0.04},
	 {"u": 0.74, "side": -1.0, "amp": -0.35, "k": 0.03}, {"u": 0.88, "side": -1.0, "amp": 0.75, "k": 0.03},
	 {"u": 0.96, "side": 1.0, "amp": 0.5, "k": 0.03}],
]

## 島的外形："map" = 地圖風格的真實海岸線（指數島用本州的輪廓）；"bead" = 圓滑的珠串
const EXP_SHAPE := "map"
const LOG_SHAPE := "map"

## 本州海岸線（經度, 緯度），畫面上會換算成座標
const HONSHU := [
	Vector2(130.90, 33.95),
	Vector2(131.00, 34.30),
	Vector2(131.40, 34.45),
	Vector2(131.90, 34.70),
	Vector2(132.40, 35.05),
	Vector2(132.70, 35.40),
	Vector2(133.10, 35.60),
	Vector2(133.30, 35.55),
	Vector2(133.60, 35.50),
	Vector2(134.20, 35.55),
	Vector2(134.80, 35.65),
	Vector2(135.20, 35.70),
	Vector2(135.40, 35.55),
	Vector2(135.70, 35.50),
	Vector2(136.00, 35.70),
	Vector2(136.00, 36.00),
	Vector2(136.10, 36.30),
	Vector2(136.60, 36.70),
	Vector2(136.75, 37.00),
	Vector2(136.80, 37.30),
	Vector2(137.10, 37.50),
	Vector2(137.35, 37.45),
	Vector2(137.00, 37.10),
	Vector2(137.10, 36.85),
	Vector2(137.30, 36.75),
	Vector2(137.60, 36.95),
	Vector2(138.20, 37.15),
	Vector2(138.80, 37.60),
	Vector2(139.10, 37.95),
	Vector2(139.40, 38.20),
	Vector2(139.60, 38.60),
	Vector2(139.80, 39.00),
	Vector2(140.00, 39.40),
	Vector2(139.70, 39.90),
	Vector2(140.00, 40.00),
	Vector2(140.00, 40.50),
	Vector2(140.20, 40.80),
	Vector2(140.35, 41.15),
	Vector2(140.65, 41.20),
	Vector2(140.80, 40.90),
	Vector2(141.20, 41.20),
	Vector2(141.00, 41.45),
	Vector2(141.45, 41.40),
	Vector2(141.45, 40.90),
	Vector2(141.65, 40.40),
	Vector2(141.90, 40.00),
	Vector2(142.05, 39.50),
	Vector2(141.90, 39.00),
	Vector2(141.60, 38.40),
	Vector2(141.00, 38.30),
	Vector2(140.95, 37.80),
	Vector2(141.00, 37.30),
	Vector2(140.90, 36.90),
	Vector2(140.60, 36.40),
	Vector2(140.60, 36.00),
	Vector2(140.85, 35.70),
	Vector2(140.40, 35.20),
	Vector2(139.85, 34.90),
	Vector2(139.90, 35.35),
	Vector2(139.70, 35.30),
	Vector2(139.60, 35.10),
	Vector2(139.15, 35.25),
	Vector2(138.95, 34.65),
	Vector2(138.75, 34.80),
	Vector2(138.80, 35.10),
	Vector2(138.40, 34.70),
	Vector2(137.70, 34.65),
	Vector2(137.20, 34.70),
	Vector2(137.00, 34.60),
	Vector2(136.85, 34.90),
	Vector2(136.60, 34.70),
	Vector2(136.90, 34.30),
	Vector2(136.40, 33.90),
	Vector2(135.80, 33.45),
	Vector2(135.40, 33.70),
	Vector2(135.10, 34.20),
	Vector2(135.40, 34.60),
	Vector2(135.10, 34.70),
	Vector2(134.50, 34.75),
	Vector2(133.90, 34.55),
	Vector2(133.30, 34.40),
	Vector2(132.70, 34.25),
	Vector2(132.30, 34.20),
	Vector2(131.90, 33.95),
	Vector2(131.50, 34.00),
	Vector2(131.20, 33.95),
]
## 把經緯度換算成畫面座標（西南角在左下、東北角在右上）
const HON_ORIGIN := Vector2(130.9, 33.45)
const HON_SCALE := 49.5
const HON_BASE := Vector2(92, 520)
## 本州上三座聖地的位置（經緯度）與分區的切線（兩點連線，切開島）
const HON_SITES := [Vector2(132.9, 34.85), Vector2(136.6, 35.5), Vector2(140.6, 38.6)]
const HON_CUTS := [[Vector2(134.75, 33.0), Vector2(134.75, 36.6)], [Vector2(138.7, 38.6), Vector2(141.8, 36.7)]]

## 對數島（地圖風格）：南端的海角往北陡升，再往東延伸、越來越平；海岸線有半島和海灣（畫面座標）
const LOG_COAST := [
	Vector2(648, 594), Vector2(628, 580), Vector2(612, 558), Vector2(618, 534), Vector2(600, 514), Vector2(592, 490),
	Vector2(606, 472), Vector2(626, 464), Vector2(622, 442), Vector2(604, 426), Vector2(600, 404), Vector2(614, 386),
	Vector2(632, 372), Vector2(636, 350), Vector2(626, 330), Vector2(640, 306), Vector2(662, 292), Vector2(684, 268),
	Vector2(708, 256), Vector2(734, 262), Vector2(752, 248), Vector2(772, 236), Vector2(800, 240), Vector2(818, 226),
	Vector2(836, 206), Vector2(852, 200), Vector2(862, 218), Vector2(882, 226), Vector2(910, 222), Vector2(936, 206),
	Vector2(958, 204), Vector2(980, 214), Vector2(1004, 206), Vector2(1030, 196), Vector2(1052, 182), Vector2(1072, 186),
	Vector2(1080, 204), Vector2(1100, 214), Vector2(1108, 236), Vector2(1094, 252), Vector2(1100, 272), Vector2(1082, 290),
	Vector2(1056, 286), Vector2(1034, 298), Vector2(1010, 292), Vector2(990, 306), Vector2(964, 302), Vector2(944, 318),
	Vector2(918, 320), Vector2(898, 334), Vector2(872, 338), Vector2(856, 350), Vector2(834, 344), Vector2(808, 350),
	Vector2(790, 342), Vector2(770, 352), Vector2(750, 372), Vector2(732, 396), Vector2(724, 424), Vector2(712, 446),
	Vector2(700, 470), Vector2(694, 498), Vector2(682, 520), Vector2(684, 548), Vector2(672, 570), Vector2(662, 590),
]
## 對數島五座聖地的位置與分區切線（兩點連成一條線把島切開）
const LOG_SITES := [Vector2(644, 548), Vector2(664, 430), Vector2(760, 306), Vector2(925, 280), Vector2(1048, 252)]
const LOG_CUTS := [[Vector2(560, 482), Vector2(760, 482)], [Vector2(600, 344), Vector2(800, 379)],
	[Vector2(862, 150), Vector2(862, 430)], [Vector2(988, 150), Vector2(988, 430)]]

## 八座聖地：在哪座島、負責脊線上的哪一段（u 從 0 到 1）
const SITES := [
	{"id": "L1", "isle": 0, "u": Vector2(0.0, 0.36), "topic": "指數函數的圖形"},
	{"id": "L2", "isle": 0, "u": Vector2(0.36, 0.69), "topic": "指數方程式"},
	{"id": "L3", "isle": 0, "u": Vector2(0.69, 1.0), "topic": "指數不等式與極值"},
	{"id": "L4", "isle": 1, "u": Vector2(0.0, 0.11), "topic": "對數的運算性質"},
	{"id": "L5", "isle": 1, "u": Vector2(0.11, 0.31), "topic": "對數函數的圖形"},
	{"id": "L6", "isle": 1, "u": Vector2(0.31, 0.55), "topic": "對數方程式"},
	{"id": "L7", "isle": 1, "u": Vector2(0.55, 0.78), "topic": "對數不等式"},
	{"id": "L8", "isle": 1, "u": Vector2(0.78, 1.0), "topic": "首數、尾數與應用"},
]

## 劇情：每一句 {text, who（說話的人，空白是旁白）, cam（"wide"、"site"、"isle0"、"isle1"）,
##   site（鏡頭／光靈對準第幾座聖地）, zoom, light（點亮第幾座）, spirit（光靈飛到第幾座）}
const STORY := {
	"prologue": [
		{"text": "很久以前，數學世界被兩座島嶼照亮——指數島和對數島。", "cam": "wide"},
		{"text": "指數島從西南的海岸出發，一路往東北延伸，越往後越陡——就像一條 y = aˣ 的曲線。", "cam": "isle0", "zoom": 1.4},
		{"text": "對數島剛好相反：從南方的海角陡直往北爬，接著越來越平緩地向東伸展。兩座島，正好是彼此的鏡像。", "cam": "isle1", "zoom": 1.35},
		{"text": "直到某天，混亂之霧湧來。曲線斷裂、數字失序，聖地的光一盞一盞熄滅了……", "cam": "wide"},
		{"text": "……咦？咦咦？我、我還在發光耶！我是光靈，大概是世界上最後一顆小光球～", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.7, "spirit": 0, "appear": true},
		{"text": "聽說把聖地的謎題解開，光就會回來？那、那我們先去海邊的光之橋看看好不好！", "who": "光靈", "cam": "site", "site": 0, "zoom": 1.5},
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
		{"text": "我們做到了！謝謝你一直陪著我～以後也要常常回修煉之間找我玩喔，約好了！", "who": "光靈", "cam": "wide"},
	],
}

const STORY_TITLES := {"prologue": "序章．熄滅的世界", "L1": "第一幕．光之橋", "L2": "第二幕．換元鍛造所",
	"L3": "第三幕．天秤神殿", "L4": "第四幕．對數鍊金術", "L5": "第五幕．鏡像之塔", "L6": "第六幕．真數守門員",
	"L7": "第七幕．正負羅盤", "L8": "第八幕．位數望遠鏡", "epilogue": "終章．兩座島的光"}

signal enter_level(file: String)
signal story_changed(on: bool)
signal open_tower                     # 點了海上的終焉之塔

## 終焉之塔：立在兩座島之間的海上
const TOWER_P := Vector2(578, 214)       # 劇情播放中（主畫面把上方的按鈕藏起來）

var t := 0.0
var glow: Array = []        # 每座聖地目前的亮度（畫面上的）
var progress: Array = []    # 每座聖地的完成度 0 ～ 1
var done: Array = []        # 整個大關完成了嗎
var sel := 0
var spirit := Vector2(130, 380)
var spirit_target := Vector2(130, 380)
var spirit_on := true
var trail: Array = []
var cam := Vector2(W / 2.0, H / 2.0)
var zoom := 1.0
var particles: Array = []
var sky_stars: Array = []
var fog: Array = []
var islets: Array = []      # 隨機的小離島
var playing := false
var _hover := -1
# ---- 手機效能：批次繪圖與快取（畫面和原本一樣，只是少很多 draw call 與重複計算）----
var _tri_cache := {}        # 多邊形 key → 三角化後的頂點索引
var _detail_cache := {}     # 島 → 山／樹的位置（固定亂數種子，只需要算一次）
## 分層繪製（手機效能）：
##   本體：海＋星光倒影（每幀）
##   _land：島、區域底色、山和樹、邊界——不會動的東西，只在亮度改變時重畫，鏡頭移動只改變這一層的位置
##   _fx：脈動的光圈、小路、塔、聖地、霧、光點、名牌、光靈（每幀）
var _tgt: CanvasItem            # 目前要畫在哪一層
var _land: _Layer
var _fx: _Layer
var _land_glow: Array = []      # _land 上次畫的時候的亮度

var _cv := PackedVector2Array()   # 批次圓形：頂點
var _cc := PackedColorArray()     # 批次圓形：顏色
var _ci := PackedInt32Array()     # 批次圓形：索引

var _card: PanelContainer
var _card_bar: ColorRect
var _card_name: Label
var _card_topic: Label
var _card_stars: Label
var _card_bar_fill: ProgressBar
var _card_go: Button
var _story_btn: Button
var _player: StoryPlayer


func _ready() -> void:
	_tgt = self
	_land = _Layer.new()
	_land.painter = _draw_land
	add_child(_land)
	_fx = _Layer.new()
	_fx.painter = _draw_fx
	add_child(_fx)
	position = Vector2.ZERO
	size = Vector2(W, H)       # 固定 1152 × 648（和其他介面一樣），點擊範圍才會涵蓋整張地圖
	mouse_filter = Control.MOUSE_FILTER_STOP
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 150:
		sky_stars.append({"p": Vector2(rng.randf() * W, rng.randf() * H), "s": rng.randf_range(0.5, 1.6), "ph": rng.randf() * TAU})
	for i in SITES.size():
		var p := site_point(i)
		for k in 7:
			fog.append({"site": i, "o": Vector2(rng.randf_range(-50, 50), rng.randf_range(-50, 30)),
				"r": rng.randf_range(18, 34), "ph": rng.randf() * TAU})
		glow.append(0.0)
		progress.append(0.0)
		done.append(false)
	_make_islets()
	_build_card()
	_story_btn = UITheme.ghost_button("劇情回顧", 17)
	_story_btn.custom_minimum_size = Vector2(120, 44)
	_story_btn.position = Vector2(W - 150 - 18 - 130, 14)
	_story_btn.pressed.connect(_show_story_list)
	add_child(_story_btn)
	refresh()


# ================= 資料 =================

func refresh() -> void:
	var g = Game.of(self)
	for i in SITES.size():
		progress[i] = Center.level_progress(g, SITES[i].id)
		done[i] = progress[i] >= 0.999
		glow[i] = _rest_glow(i)
	_update_story_btn()


## 平常的亮度：完成且看過劇情 = 全亮；還沒完成就依完成度微微發光
func _rest_glow(i: int) -> float:
	var g = Game.of(self)
	if done[i] and g.story_seen.has(SITES[i].id):
		return 1.0
	return 0.32 * progress[i]


## 切到地圖頁時呼叫：選好預設的聖地，需要的話播放劇情
func on_shown() -> void:
	refresh()
	var first := 0
	for i in SITES.size():
		if not done[i]:
			first = i
			break
		first = i
	# 從關卡回來：光靈停在剛剛選的那一關；第一次進來才停在下一個還沒完成的大關
	var g = Game.of(self)
	select(g.map_sel if g.map_sel >= 0 else first, false)
	spirit = spirit_target
	cam = Vector2(W / 2.0, H / 2.0)
	zoom = 1.0
	call_deferred("_play_pending")


func _pending_stories() -> Array:
	var g = Game.of(self)
	var out := []
	if not g.story_seen.has("prologue"):
		out.append("prologue")
	for i in SITES.size():
		if done[i] and not g.story_seen.has(SITES[i].id):
			out.append(SITES[i].id)
	var all_done := not done.has(false)
	if all_done and not g.story_seen.has("epilogue"):
		out.append("epilogue")
	return out


func _play_pending() -> void:
	if playing or not is_visible_in_tree():
		return
	var queue := _pending_stories()
	if queue.is_empty():
		return
	play_story(queue[0], true)


# ================= 地形 =================

## 脊線上的一點
static func spine(isle: int, u: float) -> Vector2:
	var d: Dictionary = ISLES[isle]
	var a: Vector2 = d.a
	var b: Vector2 = d.b
	var f := (pow(2.0, 3.0 * u) - 1.0) / 7.0 if d.kind == "exp" else log(1.0 + 12.0 * u) / log(13.0)
	# 脊線本身也彎來彎去，島才不會像一條管子
	var side := (b - a).normalized().orthogonal()
	return Vector2(lerpf(a.x, b.x, u), lerpf(a.y, b.y, f))


## 寬度倍率：每個區域鼓成一顆圓圓的「珠子」，區域交界收成平滑的腰身
static func _profile(isle: int, u: float) -> float:
	for i in SITES.size():
		var st: Dictionary = SITES[i]
		if int(st.isle) != isle or u < st.u.x or u > st.u.y:
			continue
		var tl: float = (u - st.u.x) / maxf(0.001, st.u.y - st.u.x)
		# 島頭、島尾的區域：從端點就是最胖的，只在跟下一區交界的地方收腰
		if st.u.x <= 0.0:
			tl = 0.5 + 0.5 * tl
		elif st.u.y >= 1.0:
			tl = 0.5 * tl
		var peak: float = BEAD[i]
		return NECK + (peak - NECK) * pow(sin(PI * tl), 0.75)
	return NECK


static func spine_normal(isle: int, u: float) -> Vector2:
	var e := 0.004
	var dv := spine(isle, minf(1.0, u + e)) - spine(isle, maxf(0.0, u - e))
	return dv.normalized().orthogonal()


## 島在脊線兩側的寬度：海岸線用幾個正弦波弄得彎彎曲曲，兩端收成圓頭
static func half_w(isle: int, u: float, side: float) -> float:
	var d: Dictionary = ISLES[isle]
	# 兩端收成半圓：脊線走得慢的那一端（指數島西南、對數島東邊）圓弧要拉長一點
	var c0: float = 0.15 if d.kind == "exp" else 0.05
	var c1: float = 0.06 if d.kind == "exp" else 0.13
	var k := clampf(minf(u / c0, (1.0 - u) / c1), 0.0, 1.0)
	var cap := sqrt(1.0 - (1.0 - k) * (1.0 - k))
	var wob := _profile(isle, u)
	return d.w * maxf(0.25, wob) * cap


static func edge(isle: int, u: float, side: float, pad: float = 0.0) -> Vector2:
	return spine(isle, u) + spine_normal(isle, u) * (half_w(isle, u, side) + pad) * side


## 取樣的 u：陡的地方取密一點（指數島在尾端、對數島在開頭）
static func _us(isle: int, ua: float, ub: float) -> Array:
	var exp_isle: bool = ISLES[isle].kind == "exp"
	var ta := 1.0 - sqrt(1.0 - ua) if exp_isle else sqrt(ua)
	var tb := 1.0 - sqrt(1.0 - ub) if exp_isle else sqrt(ub)
	var n := maxi(4, int(ceil((tb - ta) * 220.0)))
	var out := []
	for k in n + 1:
		var tt := lerpf(ta, tb, float(k) / n)
		out.append(1.0 - (1.0 - tt) * (1.0 - tt) if exp_isle else tt * tt)
	return out


## 一段島（u 從 ua 到 ub）的外框；pad > 0 是往外擴（淺灘）
static func region_poly(isle: int, ua: float, ub: float, pad: float = 0.0) -> PackedVector2Array:
	var us := _us(isle, ua, ub)
	var pts := PackedVector2Array()
	for u in us:
		pts.append(edge(isle, u, 1.0, pad))
	for k in range(us.size() - 1, -1, -1):
		pts.append(edge(isle, us[k], -1.0, pad))
	return pts


static func island_poly(isle: int, pad: float = 0.0) -> PackedVector2Array:
	if _custom(isle):
		return _coast_poly(isle, pad)
	return region_poly(isle, 0.0, 1.0, pad)


static func site_poly(i: int) -> PackedVector2Array:
	var st: Dictionary = SITES[i]
	if _custom(int(st.isle)):
		return _map_region(i)
	return region_poly(int(st.isle), st.u.x, st.u.y)


static func site_point(i: int) -> Vector2:
	var st: Dictionary = SITES[i]
	if _custom(int(st.isle)):
		return geo(HON_SITES[i]) if int(st.isle) == 0 else LOG_SITES[i - 3]
	return spine(int(st.isle), (st.u.x + st.u.y) / 2.0) + Vector2(0, 16)


# ---------- 地圖風格的島（真實的海岸線） ----------

static var _cache: Dictionary = {}


static func _custom(isle: int) -> bool:
	return (EXP_SHAPE if isle == 0 else LOG_SHAPE) == "map"


static func geo(ll: Vector2) -> Vector2:
	return HON_BASE + Vector2((ll.x - HON_ORIGIN.x) * 0.8, -(ll.y - HON_ORIGIN.y)) * HON_SCALE


## 最大的那一塊（offset／intersect 可能切出好幾塊）
static func _largest(polys: Array) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_a := -1.0
	for p in polys:
		var a := 0.0
		for k in p.size():
			a += p[k].cross(p[(k + 1) % p.size()])
		if absf(a) > best_a:
			best_a = absf(a)
			best = p
	return best


## 去掉太密的點（offset／intersect 會產生上千個點，畫起來很慢、也容易讓三角化失敗）
static func _decimate(poly: PackedVector2Array, d: float = 2.5) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		if out.is_empty() or p.distance_to(out[out.size() - 1]) >= d:
			out.append(p)
	if out.size() > 3 and out[0].distance_to(out[out.size() - 1]) < d:
		out.remove_at(out.size() - 1)
	return out


## 海岸線的控制點（畫面座標）
static func _coast_pts(isle: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	if isle == 0:
		for ll in HONSHU:
			out.append(geo(ll))
	else:
		for p in LOG_COAST:
			out.append(p)
	return out


## 用 Catmull-Rom 曲線把控制點連成圓滑的海岸線
static func _smooth(pts: PackedVector2Array, sub: int = 5) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	for k in n:
		var p0 := pts[(k - 1 + n) % n]
		var p1 := pts[k]
		var p2 := pts[(k + 1) % n]
		var p3 := pts[(k + 2) % n]
		for j in sub:
			var tt := float(j) / sub
			var t2 := tt * tt
			var t3 := t2 * tt
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * tt + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	return out


## 島的外框；pad ≠ 0 時往外（或往內）推
static func _coast_poly(isle: int, pad: float = 0.0) -> PackedVector2Array:
	var key := "c%d_%d" % [isle, int(pad)]
	if _cache.has(key):
		return _cache[key]
	var base: PackedVector2Array
	if _cache.has("base%d" % isle):
		base = _cache["base%d" % isle]
	else:
		# 平滑後可能有小地方自己交叉：往外推 1 再往內推 1，讓 Clipper 把它整理成乾淨的多邊形
		base = _smooth(_coast_pts(isle))
		base = _largest(Geometry2D.offset_polygon(base, 1.0, Geometry2D.JOIN_ROUND))
		base = _decimate(_largest(Geometry2D.offset_polygon(base, -1.0, Geometry2D.JOIN_ROUND)))
		_cache["base%d" % isle] = base
	var out := base
	if absf(pad) > 0.01:
		out = _decimate(_largest(Geometry2D.offset_polygon(base, pad, Geometry2D.JOIN_ROUND)))
	_cache[key] = out
	return out


## 這座島的聖地編號與切線（畫面座標）
static func _isle_sites(isle: int) -> Array:
	return [0, 1, 2] if isle == 0 else [3, 4, 5, 6, 7]


static func _isle_cuts(isle: int) -> Array:
	var out := []
	if isle == 0:
		for cut in HON_CUTS:
			out.append([geo(cut[0]), geo(cut[1])])
	else:
		for cut in LOG_CUTS:
			out.append([cut[0], cut[1]])
	return out


## 一條切線的哪一側：做一個很大的四邊形當「半平面」
static func _half_plane(a: Vector2, b: Vector2, keep_left: bool) -> PackedVector2Array:
	var d := (b - a).normalized()
	var n := d.orthogonal() * (1.0 if keep_left else -1.0)
	var a2 := a - d * 3000.0
	var b2 := b + d * 3000.0
	return PackedVector2Array([a2, b2, b2 + n * 3000.0, a2 + n * 3000.0])


## 切線某一側的半平面：留下點 q 那一側
static func _toward(a: Vector2, b: Vector2, q: Vector2) -> PackedVector2Array:
	var hp := _half_plane(a, b, true)
	return hp if Geometry2D.is_point_in_polygon(q, hp) else _half_plane(a, b, false)


## 第 i 座聖地的區域：每一條切線都留下聖地那一側
static func _map_region(i: int) -> PackedVector2Array:
	var key := "r%d" % i
	if _cache.has(key):
		return _cache[key]
	var isle: int = SITES[i].isle
	var res := _coast_poly(isle)
	var q := site_point(i)
	for cut in _isle_cuts(isle):
		res = _largest(Geometry2D.intersect_polygons(res, _toward(cut[0], cut[1], q)))
	res = _decimate(res)
	_cache[key] = res
	return res


## 在多邊形裡隨機取一點
static func _rand_in(poly: PackedVector2Array, rng: RandomNumberGenerator) -> Vector2:
	var r := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		r = r.expand(p)
	for k in 60:
		var q := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
		if Geometry2D.is_point_in_polygon(q, poly):
			return q
	return r.get_center()


## 名牌在圖示上方
static func label_dy(i: int) -> float:
	return -112.0 if i == 4 else -86.0


## 光靈停在名牌上方
static func hover_point(i: int) -> Vector2:
	return site_point(i) + Vector2(0, label_dy(i) - 36.0)


## 畫面固定是 1152 × 648（和其他介面一樣用絕對座標）
const SCREEN_C := Vector2(W / 2.0, H / 2.0)


func _to_world(p: Vector2) -> Vector2:
	return (p - SCREEN_C) / zoom + cam


func _to_screen(p: Vector2) -> Vector2:
	return (p - cam) * zoom + SCREEN_C


func _site_at(screen_p: Vector2) -> int:
	var wp := _to_world(screen_p)
	if wp.distance_to(TOWER_P + Vector2(0, -30)) < 38.0:
		return 99
	for i in SITES.size():
		if wp.distance_to(site_point(i) + Vector2(0, -24)) < 40.0:
			return i
	for i in SITES.size():
		if Geometry2D.is_point_in_polygon(wp, site_poly(i)):
			return i
	return -1


func _gui_input(e: InputEvent) -> void:
	if playing:
		return
	if e is InputEventMouseMotion:
		var hv := _site_at(e.position)
		if hv != _hover:
			_hover = hv
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hv >= 0 else Control.CURSOR_ARROW
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var i := _site_at(e.position)
		if i == 99:
			Game.of(self).sfx("open")
			open_tower.emit()
			accept_event()
			return
		if i < 0:
			return
		if i == sel:
			_enter(i)
		else:
			select(i)
		accept_event()


func select(i: int, sound := true) -> void:
	sel = i
	Game.of(self).map_sel = i
	spirit_target = hover_point(i)
	if sound:
		Game.of(self).play("blip", 1.0 + 0.06 * i, -10.0)
	_update_card()


func _enter(i: int) -> void:
	var info: Dictionary = Center.level_info(SITES[i].id)
	enter_level.emit(info.file)


# ================= 下方的資訊卡 =================

func _build_card() -> void:
	_card = PanelContainer.new()
	_card.position = Vector2(724, 526)
	_card.custom_minimum_size = Vector2(412, 100)
	_card.add_theme_stylebox_override("panel", UITheme.box(Color(0.07, 0.09, 0.2, 0.92), 18, Color(1, 1, 1, 0.12), 1, 14))
	add_child(_card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_card.add_child(row)
	_card_bar = ColorRect.new()
	_card_bar.custom_minimum_size = Vector2(6, 0)
	row.add_child(_card_bar)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	_card_name = Label.new()
	_card_name.add_theme_font_size_override("font_size", UITheme.fs(24))
	top.add_child(_card_name)
	_card_stars = Label.new()
	_card_stars.add_theme_font_size_override("font_size", UITheme.fs(17))
	_card_stars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_card_stars)
	_card_topic = Label.new()
	_card_topic.add_theme_font_size_override("font_size", UITheme.fs(15))
	_card_topic.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_card_topic.clip_text = true
	_card_topic.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_card_topic.custom_minimum_size = Vector2(300, 0)
	v.add_child(_card_topic)
	_card_bar_fill = ProgressBar.new()
	_card_bar_fill.show_percentage = false
	_card_bar_fill.max_value = 1.0
	_card_bar_fill.custom_minimum_size = Vector2(0, 6)
	v.add_child(_card_bar_fill)
	_card_go = Button.new()
	_card_go.text = "出發  ▶"
	_card_go.custom_minimum_size = Vector2(124, 54)
	_card_go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UITheme.accent_button(_card_go, 20)
	_card_go.pressed.connect(func(): _enter(sel))
	row.add_child(_card_go)


func _update_card() -> void:
	var info: Dictionary = Center.level_info(SITES[sel].id)
	var c: Color = info.color
	var g = Game.of(self)
	_card_bar.color = c
	_card_name.text = "%d．%s" % [sel + 1, info.name]
	_card_name.add_theme_color_override("font_color", c.lightened(0.15))
	var st := int(g.stars.get(SITES[sel].id, 0))
	_card_stars.text = "★".repeat(st) + "☆".repeat(3 - st)
	_card_stars.add_theme_color_override("font_color", UITheme.ACCENT if st > 0 else Color(1, 1, 1, 0.25))
	var p: float = progress[sel]
	_card_topic.text = "%s　·　%s" % [SITES[sel].topic, ("已點亮 ✓" if done[sel] else "點亮進度 %d%%" % roundi(100.0 * p))]
	_card_bar_fill.value = p
	_card_bar_fill.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.08), 3, Color(0, 0, 0, 0), 0, 0))
	_card_bar_fill.add_theme_stylebox_override("fill", UITheme.box(UITheme.ACCENT if done[sel] else c, 3, Color(0, 0, 0, 0), 0, 0))
	_card_go.text = "再訪  ▶" if done[sel] else ("出發  ▶" if p == 0.0 else "繼續  ▶")
	_place_card.call_deferred()


## 卡片靠右下角對齊：寬度會隨文字（和字級）改變，所以每次都從右邊往回算位置
func _place_card() -> void:
	if not is_instance_valid(_card):
		return
	_card.reset_size()
	_card.position = Vector2(W - 16.0 - _card.size.x, H - 16.0 - _card.size.y)


# ================= 更新與繪圖 =================

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return          # 別的頁面開著時不用算、不用重畫
	t += delta
	var k := 1.0 - exp(-4.0 * delta)
	spirit = spirit.lerp(spirit_target + Vector2(0, 5.0 * sin(t * 2.4)), k)
	trail.push_front(spirit)
	if trail.size() > 16:
		trail.pop_back()
	# 亮起來的區域冒出光點
	for i in SITES.size():
		if glow[i] > 0.5 and randf() < 0.12 * glow[i]:
			var st: Dictionary = SITES[i]
			var u := randf_range(st.u.x, st.u.y)
			var isle: int = st.isle
			var sp := spine(isle, u) + spine_normal(isle, u) * half_w(isle, u, 1.0) * randf_range(-0.7, 0.7)
			if _custom(isle):
				var rr := RandomNumberGenerator.new()
				rr.randomize()
				sp = _rand_in(site_poly(i), rr)
			var info: Dictionary = Center.level_info(SITES[i].id)
			particles.append({"p": sp, "v": Vector2(randf_range(-6, 6), randf_range(-24, -10)),
				"life": 1.0, "c": info.color, "r": randf_range(1.2, 2.6)})
	for p in particles:
		p.p += p.v * delta
		p.life -= delta * 0.5
	particles = particles.filter(func(p): return p.life > 0.0)
	queue_redraw()
	_fx.queue_redraw()
	_land.position = SCREEN_C - cam * zoom
	_land.scale = Vector2(zoom, zoom)
	if glow != _land_glow:
		_land_glow = glow.duplicate()
		_land.queue_redraw()


## 單位圓的頂點（預先算好，省掉每一幀幾千次 sin／cos）
static var _unit: Dictionary = {}


static func _unit_circle(n: int) -> PackedVector2Array:
	if not _unit.has(n):
		var u := PackedVector2Array()
		for k in n:
			u.append(Vector2(cos(TAU * k / n), sin(TAU * k / n)))
		_unit[n] = u
	return _unit[n]


## 把一個實心圓加進批次（和 draw_circle 外觀相同），最後用 _flush_circles() 一次畫出
func _bcircle(c: Vector2, r: float, col: Color, n: int = 0) -> void:
	if n <= 0:
		n = 12 if r < 3.0 else (20 if r < 10.0 else 32)
	var u := _unit_circle(n)
	var base := _cv.size()
	_cv.append(c)
	for k in n:
		_cv.append(c + u[k] * r)
	var cs := _cc.size()
	_cc.resize(cs + n + 1)
	for k in n + 1:
		_cc[cs + k] = col
	var ii := _ci.size()
	_ci.resize(ii + 3 * n)
	for k in n:
		_ci[ii] = base
		_ci[ii + 1] = base + 1 + k
		_ci[ii + 2] = base + 1 + (k + 1) % n
		ii += 3


func _flush_circles() -> void:
	if not _ci.is_empty():
		RenderingServer.canvas_item_add_triangle_array(_tgt.get_canvas_item(), _ci, _cv, _cc)
	_cv = PackedVector2Array()
	_cc = PackedColorArray()
	_ci = PackedInt32Array()


## 固定形狀的大多邊形：三角化結果快取起來，不用每一幀重算（外觀和 draw_colored_polygon 相同）
func _fill_poly(key: String, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3:
		return
	var idx: PackedInt32Array
	if _tri_cache.has(key) and _tri_cache[key][0] == pts.size():
		idx = _tri_cache[key][1]
	else:
		idx = Geometry2D.triangulate_polygon(pts)
		_tri_cache[key] = [pts.size(), idx]
	if idx.is_empty():
		_tgt.draw_colored_polygon(pts, col)
		return
	var cols := PackedColorArray()
	cols.resize(pts.size())
	cols.fill(col)
	RenderingServer.canvas_item_add_triangle_array(_tgt.get_canvas_item(), idx, pts, cols)


func _draw() -> void:
	_tgt = self
	# 世界座標（鏡頭）
	_tgt.draw_set_transform(SCREEN_C - cam * zoom, 0.0, Vector2(zoom, zoom))
	_draw_sea()
	for st in sky_stars:   # 海面上的星光倒影
		var a: float = 0.12 + 0.14 * sin(t * 1.5 + st.ph)
		_bcircle(st.p, st.s, Color(0.85, 0.93, 1.0, a))
	_flush_circles()


## 不會動的陸地（畫在 _land；鏡頭由 _land 的位置／縮放處理）
func _draw_land(layer: CanvasItem) -> void:
	_tgt = layer
	_draw_islets()
	for isle in 2:
		_draw_island(isle)
	for i in SITES.size():
		_draw_region_fill(i)
	for isle in 2:
		_draw_details(isle)
	_draw_borders()
	_tgt = self


## 每幀都在動的東西（畫在 _fx）
func _draw_fx(layer: CanvasItem) -> void:
	_tgt = layer
	var font := get_theme_default_font()
	_tgt.draw_set_transform(SCREEN_C - cam * zoom, 0.0, Vector2(zoom, zoom))
	for i in SITES.size():
		_draw_region_ring(i)
	_draw_path()
	_draw_tower(font)
	for i in SITES.size():
		_draw_landmark(i)
	_draw_fog()
	for p in particles:
		_bcircle(p.p, p.r, Color(p.c.r, p.c.g, p.c.b, p.life * 0.8))
	_flush_circles()
	for i in SITES.size():
		_draw_label(font, i)
	if spirit_on:
		_draw_spirit()
	_draw_isle_names(font)
	_tgt.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 標題
	if not playing:
		var lit := 0
		for d in done:
			if d:
				lit += 1
		UITheme.text_ol(_tgt, font, Vector2(0, 46), "光靈的旅程", HORIZONTAL_ALIGNMENT_CENTER, W, UITheme.fs(30), UITheme.ACCENT, 6)
		UITheme.text_ol(_tgt, font, Vector2(0, 74), "世界之光  %d ／ 8" % lit, HORIZONTAL_ALIGNMENT_CENTER, W, UITheme.fs(15), UITheme.TEXT_DIM)
	_tgt = self


## 小離島：只在大島旁邊放兩三座（島、脊線位置、在哪一側、離海岸多遠、大小）
const ISLETS := [
	{"isle": 0, "u": 0.24, "side": -1.0, "gap": 34.0, "r": 13.0, "seed": 3},
	{"isle": 0, "u": 0.93, "side": 1.0, "gap": 30.0, "r": 9.0, "seed": 7, "buddy": true},
	{"isle": 1, "u": 0.62, "side": -1.0, "gap": 40.0, "r": 15.0, "seed": 11},
]


## 本州版的小離島：佐渡、隱岐、淡路（經緯度、大小）
const HON_ISLETS := [[Vector2(138.4, 38.05), 12.0], [Vector2(134.85, 34.1), 6.5]]   # 佐渡、淡路
## 地圖風格對數島旁的小島（畫面座標、大小）
const LOG_ISLETS := [[Vector2(962, 352), 11.0], [Vector2(744, 222), 6.0]]


func _make_islets() -> void:
	if LOG_SHAPE == "map":
		for k in LOG_ISLETS.size():
			var rng1 := RandomNumberGenerator.new()
			rng1.seed = 60 + k
			_add_islet(rng1, LOG_ISLETS[k][0], LOG_ISLETS[k][1])
	if EXP_SHAPE == "map":
		for k in HON_ISLETS.size():
			var rng0 := RandomNumberGenerator.new()
			rng0.seed = 40 + k
			_add_islet(rng0, geo(HON_ISLETS[k][0]), HON_ISLETS[k][1])
	for d in ISLETS:
		if _custom(int(d.isle)):
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = d.seed
		var isle: int = d.isle
		var c: Vector2 = edge(isle, d.u, d.side) + spine_normal(isle, d.u) * d.side * (d.gap + d.r)
		_add_islet(rng, c, d.r)
		if d.get("buddy", false):
			_add_islet(rng, c + Vector2(d.r + 10.0, -4.0), 4.5)


static func _dist_to_poly(p: Vector2, poly: PackedVector2Array) -> float:
	var best := INF
	for k in poly.size():
		var q := Geometry2D.get_closest_point_to_segment(p, poly[k], poly[(k + 1) % poly.size()])
		best = minf(best, p.distance_to(q))
	return best


func _add_islet(rng: RandomNumberGenerator, c: Vector2, r: float) -> void:
	var ph := rng.randf() * TAU
	var ph2 := rng.randf() * TAU
	var stretch := rng.randf_range(0.7, 1.3)
	var rot := rng.randf() * PI
	var pts := PackedVector2Array()
	for k in 36:
		var a := TAU * k / 36.0
		pts.append(c + Vector2(cos(a) * r * (1.0 + 0.15 * (stretch - 1.0)), sin(a) * r).rotated(rot))
	var near := 0
	for i in SITES.size():
		if c.distance_to(site_point(i)) < c.distance_to(site_point(near)):
			near = i
	islets.append({"c": c, "r": r, "pts": pts, "tree": r > 9.0 and rng.randf() < 0.6, "site": near})


func _draw_islets() -> void:
	for n in islets.size():
		var it: Dictionary = islets[n]
		var pts: PackedVector2Array = it.pts
		var c: Vector2 = it.c
		if not it.has("halo"):
			var halo := PackedVector2Array()
			for p in pts:
				halo.append(c + (p - c) * (1.0 + 9.0 / it.r))
			it["halo"] = halo
		_fill_poly("islet_halo%d" % n, it.halo, Color(0.4, 0.75, 1.0, 0.07))
		var g: float = glow[it.site]
		var info: Dictionary = Center.level_info(SITES[it.site].id)
		var col: Color = info.color
		_fill_poly("islet%d" % n, pts, Color("1f2647").lerp(col.darkened(0.45), 0.55 * g))
		var coast := pts.duplicate()
		coast.append(pts[0])
		_tgt.draw_polyline(coast, Color(0.85, 0.8, 0.62, 0.28).lerp(col.lightened(0.2), 0.6 * g), 1.6, true)
		if it.tree:
			UITheme.dot(_tgt, c + Vector2(-2, -1), 3.2, Color(0.16, 0.2, 0.4).lerp(col.darkened(0.25), 0.8 * g))


## 海：深藍漸層＋一道一道的小波紋
func _draw_sea() -> void:
	var r := Rect2(-W, -H, 3.0 * W, 3.0 * H)
	_tgt.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([Color("10264a"), Color("10264a"), Color("071526"), Color("071526")]))
	# 300 道波紋合成一次繪製（手機上每道各畫一次會非常慢）
	var segs := PackedVector2Array()
	var cols := PackedColorArray()
	segs.resize(15 * 20 * 6)
	cols.resize(15 * 20 * 3)
	var si := 0
	var ci := 0
	for gy in 15:
		var dx := 10.0 * sin(t * 0.5 + gy)
		for gx in 20:
			var p := Vector2(gx * 62.0 + (31.0 if gy % 2 == 1 else 0.0) + dx, gy * 46.0 + 20.0)
			var a := 0.05 + 0.04 * sin(t * 1.3 + gx * 1.7 + gy)
			var p1 := p + Vector2(7, -3)
			var p2 := p + Vector2(14, 0)
			var p3 := p + Vector2(21, -3)
			segs[si] = p; segs[si + 1] = p1; segs[si + 2] = p1; segs[si + 3] = p2; segs[si + 4] = p2; segs[si + 5] = p3
			si += 6
			var c := Color(0.65, 0.85, 1.0, a)
			cols[ci] = c; cols[ci + 1] = c; cols[ci + 2] = c
			ci += 3
	_tgt.draw_multiline_colors(segs, cols, 1.2, true)


## 島：淺灘、陸地、沙灘海岸線
func _draw_island(isle: int) -> void:
	_fill_poly("isle%d_22" % isle, island_poly(isle, 22.0), Color(0.35, 0.7, 0.95, 0.05))
	_fill_poly("isle%d_11" % isle, island_poly(isle, 11.0), Color(0.4, 0.75, 1.0, 0.08))
	var poly := island_poly(isle)
	_fill_poly("isle%d" % isle, poly, Color("1f2647"))
	# 內陸比較亮（像高地）
	_fill_poly("isle%d_in" % isle, _coast_poly(isle, -9.0) if _custom(isle) else _inner_poly(isle, 0.55), Color("272f58"))
	var coast := poly.duplicate()
	coast.append(poly[0])
	_tgt.draw_polyline(coast, Color(0.85, 0.8, 0.62, 0.30), 3.0, true)


static func _inner_poly(isle: int, k: float) -> PackedVector2Array:
	var us := _us(isle, 0.0, 1.0)
	var pts := PackedVector2Array()
	for u in us:
		pts.append(spine(isle, u) + spine_normal(isle, u) * half_w(isle, u, 1.0) * k)
	for j in range(us.size() - 1, -1, -1):
		pts.append(spine(isle, us[j]) - spine_normal(isle, us[j]) * half_w(isle, us[j], -1.0) * k)
	return pts


## 點亮的區域：整片染上這一關的顏色，海岸線也發光
func _draw_region_fill(i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var st: Dictionary = SITES[i]
	var isle: int = st.isle
	var info: Dictionary = Center.level_info(st.id)
	var c: Color = info.color
	var poly := site_poly(i)
	_fill_poly("site%d" % i, poly, Color(c.r, c.g, c.b, 0.30 * gl).darkened(0.1))
	if _custom(isle):
		var ikey := "in%d" % i
		if not _cache.has(ikey):
			_cache[ikey] = _decimate(_largest(Geometry2D.offset_polygon(poly, -8.0, Geometry2D.JOIN_ROUND)))
		var inner2: PackedVector2Array = _cache[ikey]
		if inner2.size() >= 3:
			_fill_poly(ikey, inner2, Color(c.r, c.g, c.b, 0.22 * gl))
		return
	# 內陸再亮一點
	var us := _us(isle, st.u.x, st.u.y)
	var inner := PackedVector2Array()
	for u in us:
		inner.append(spine(isle, u) + spine_normal(isle, u) * half_w(isle, u, 1.0) * 0.5)
	for j in range(us.size() - 1, -1, -1):
		inner.append(spine(isle, us[j]) - spine_normal(isle, us[j]) * half_w(isle, us[j], -1.0) * 0.5)
	_tgt.draw_colored_polygon(inner, Color(c.r, c.g, c.b, 0.22 * gl))


## 點亮的區域：海岸線發光（會脈動，所以每幀畫）
func _draw_region_ring(i: int) -> void:
	var gl: float = glow[i]
	if gl <= 0.01:
		return
	var st: Dictionary = SITES[i]
	var isle: int = st.isle
	var info: Dictionary = Center.level_info(st.id)
	var c: Color = info.color
	if _custom(isle):
		var rkey := "ring%d" % i
		if not _cache.has(rkey):
			var ring := site_poly(i).duplicate()
			ring.append(ring[0])
			_cache[rkey] = UITheme.thin(ring)
		var pulse2 := 0.85 + 0.15 * sin(t * 2.0 + i)
		_tgt.draw_polyline(_cache[rkey], Color(c.r, c.g, c.b, 0.25 * gl * pulse2), 7.0)
		_tgt.draw_polyline(_cache[rkey], Color(c.r, c.g, c.b, 0.9 * gl).lightened(0.3), 2.0, true)
		return
	var us := _us(isle, st.u.x, st.u.y)
	var pulse := 0.85 + 0.15 * sin(t * 2.0 + i)
	for side in [1.0, -1.0]:
		var line := PackedVector2Array()
		for u in us:
			line.append(edge(isle, u, side))
		_tgt.draw_polyline(line, Color(c.r, c.g, c.b, 0.25 * gl * pulse), 8.0, true)
		_tgt.draw_polyline(line, Color(c.r, c.g, c.b, 0.9 * gl).lightened(0.3), 2.0, true)


## 地形小裝飾：山（三角形）、樹（小圓點），亮起來時跟著上色
func _draw_details(isle: int) -> void:
	if not _detail_cache.has(isle):
		_detail_cache[isle] = _make_details(isle)
	var mounts := PackedVector2Array()
	var mcols := PackedColorArray()
	var hl := PackedVector2Array()
	var hcols := PackedColorArray()
	for d in _detail_cache[isle]:
		var p: Vector2 = d.p
		var si: int = d.si
		var g: float = glow[si] if si >= 0 else 0.0
		var info: Dictionary = Center.level_info(SITES[maxi(si, 0)].id)
		var c: Color = info.color
		if d.k % 3 == 0:
			# 山：兩筆畫成一座小山
			var col := Color(0.42, 0.46, 0.7, 0.55).lerp(c.lightened(0.2), g * 0.8)
			mounts.append_array([p + Vector2(-9, 4), p + Vector2(0, -8), p + Vector2(0, -8), p + Vector2(9, 4)])
			mcols.append_array([col, col])
			hl.append_array([p + Vector2(0, -8), p + Vector2(3, -3)])
			hcols.append(Color(1, 1, 1, 0.25 + 0.4 * g))
		else:
			var col2 := Color(0.16, 0.2, 0.4).lerp(c.darkened(0.25), g * 0.85)
			_bcircle(p, 3.6, col2)
			_bcircle(p + Vector2(-1, -1), 1.4, Color(1, 1, 1, 0.06 + 0.2 * g))
	if not mounts.is_empty():
		_tgt.draw_multiline_colors(mounts, mcols, 2.0, true)
		_tgt.draw_multiline_colors(hl, hcols, 1.5)
	_flush_circles()


## 山、樹的位置（固定亂數種子，結果每次都一樣，所以只算一次）
func _make_details(isle: int) -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 91 + isle
	var inner := _coast_poly(isle, -7.0) if _custom(isle) else PackedVector2Array()
	for k in 46:
		var u := rng.randf_range(0.04, 0.96)
		var side := rng.randf_range(-0.8, 0.8)
		var p := spine(isle, u) + spine_normal(isle, u) * half_w(isle, u, 1.0 if side > 0.0 else -1.0) * absf(side) * signf(side)
		var si := _site_of(isle, u)
		if _custom(isle):
			p = _rand_in(inner, rng)
			si = -1
			for j in _isle_sites(isle):
				if Geometry2D.is_point_in_polygon(p, site_poly(j)):
					si = j
		if si >= 0 and p.distance_to(site_point(si) + Vector2(0, -20)) < 46.0:
			continue
		out.append({"p": p, "si": si, "k": k})
	return out


static func _site_of(isle: int, u: float) -> int:
	for i in SITES.size():
		var st: Dictionary = SITES[i]
		if int(st.isle) == isle and u >= st.u.x and u <= st.u.y:
			return i
	return -1


## 區域之間的虛線邊界
func _draw_borders() -> void:
	for i in SITES.size():
		var st: Dictionary = SITES[i]
		if st.u.y >= 0.999:
			continue
		var isle: int = st.isle
		var both: bool = glow[i] > 0.6 and glow[i + 1] > 0.6
		var bc := Color(1, 0.88, 0.55, 0.65) if both else Color(1, 1, 1, 0.28)
		if _custom(isle):
			var sites_here := _isle_sites(isle)
			var ci: int = sites_here.find(i)
			if ci < sites_here.size() - 1:
				var cut: Array = _isle_cuts(isle)[ci]
				var pa: Vector2 = cut[0]
				var pb: Vector2 = cut[1]
				# 切線和海岸線的交點，兩兩一組就是在陸地上的那幾段
				var poly := _coast_poly(isle)
				var ts := []
				for k in poly.size():
					var hit = Geometry2D.segment_intersects_segment(pa, pb, poly[k], poly[(k + 1) % poly.size()])
					if hit != null:
						ts.append(pa.distance_to(hit))
				ts.sort()
				var dir := (pb - pa).normalized()
				for k in range(0, ts.size() - 1, 2):
					_tgt.draw_dashed_line(pa + dir * ts[k], pa + dir * ts[k + 1], bc, 2.0, 7.0)
			continue
		var a := edge(isle, st.u.y, 1.0)
		var b := edge(isle, st.u.y, -1.0)
		_tgt.draw_dashed_line(a, b, bc, 2.0, 7.0)


## 海上的終焉之塔：細長的塔身、塔頂的紅光、繞著塔轉的光點
func _draw_tower(font: Font) -> void:
	var p := TOWER_P
	var hov := _hover == 99 and not playing
	var sh := PackedVector2Array()
	for k in 25:
		var ang := TAU * k / 24.0
		sh.append(p + Vector2(cos(ang) * 26.0, sin(ang) * 7.0 + 3.0))
	_tgt.draw_colored_polygon(sh, Color(0.35, 0.7, 0.95, 0.10))
	var body := Color("3a2f66").lightened(0.15 if hov else 0.0)
	_tgt.draw_colored_polygon(PackedVector2Array([p + Vector2(-13, 2), p + Vector2(13, 2), p + Vector2(7, -58), p + Vector2(-7, -58)]), body)
	for yy in [-14.0, -28.0, -42.0]:
		_tgt.draw_line(p + Vector2(-11 + absf(yy) * 0.08, yy), p + Vector2(11 - absf(yy) * 0.08, yy), Color(0, 0, 0, 0.3), 1.5)
		_tgt.draw_rect(Rect2(p + Vector2(-2, yy - 9), Vector2(4, 6)), Color(1, 0.5, 0.55, 0.7))
	_tgt.draw_colored_polygon(PackedVector2Array([p + Vector2(-10, -58), p + Vector2(10, -58), p + Vector2(0, -76)]), body.lightened(0.15))
	var pulse := 0.6 + 0.4 * sin(t * 2.5)
	UITheme.dot(_tgt, p + Vector2(0, -80), 14.0, Color(1, 0.35, 0.45, 0.12 * pulse))
	UITheme.dot(_tgt, p + Vector2(0, -80), 4.0, Color(1, 0.5, 0.55, 0.9))
	for k in 3:
		var a := t * 1.6 + k * TAU / 3.0
		UITheme.dot(_tgt, p + Vector2(cos(a) * 20.0, -34.0 + sin(a) * 6.0), 1.8, Color(1, 0.6, 0.65, 0.7))
	UITheme.text_ol(_tgt, font, p + Vector2(-60, 22), "終焉之塔", HORIZONTAL_ALIGNMENT_CENTER, 120, UITheme.fs(15),
		Color(1, 0.78, 0.8, 1.0 if hov else 0.92))
	var g = Game.of(self)
	if g.tower_best > 0:
		UITheme.text_ol(_tgt, font, p + Vector2(-60, 38), "最高 %d 層" % g.tower_best, HORIZONTAL_ALIGNMENT_CENTER, 120, UITheme.fs(12), Color(1, 0.85, 0.5, 0.92))


## 八座聖地之間的虛線小路（完成的路段發亮）
func _draw_path() -> void:
	for i in SITES.size() - 1:
		var a := site_point(i) + Vector2(0, -20)
		var b := site_point(i + 1) + Vector2(0, -20)
		var lit: bool = done[i]
		var c := Color(1, 0.85, 0.45, 0.55) if lit else Color(1, 1, 1, 0.10)
		# 第三到第四座：光靈直接飛過海峽（弧線拱高一點）
		var m := (a + b) / 2.0 + (b - a).orthogonal().normalized() * (60.0 if i == 2 else 14.0)
		var prev := a
		for k in range(1, 13):
			var u := k / 12.0
			var p := a.lerp(m, u).lerp(m.lerp(b, u), u)
			if k % 2 == 1:
				_tgt.draw_line(prev, p, c, 2.0)
			prev = p


func _draw_landmark(i: int) -> void:
	var info: Dictionary = Center.level_info(SITES[i].id)
	var col: Color = info.color
	var gl: float = glow[i]
	var p := site_point(i)
	var base := Color("3a4170").lerp(col.darkened(0.15), clampf(0.15 + 0.75 * gl, 0.0, 1.0))
	var dark := Color("1c2142").lerp(col.darkened(0.55), gl)
	var light := Color(col.r, col.g, col.b, gl)
	# 腳下的影子
	var sh := PackedVector2Array()
	for k in 25:
		var ang := TAU * k / 24.0
		sh.append(p + Vector2(cos(ang) * 30.0, sin(ang) * 7.0 + 2.0))
	_tgt.draw_colored_polygon(sh, Color(0, 0, 0, 0.25))
	if i == sel and not playing:
		var pts := PackedVector2Array()
		for k in 33:
			var ang := TAU * k / 32.0
			pts.append(p + Vector2(cos(ang) * 44.0, sin(ang) * 11.0 + 2.0))
		var pa := 0.5 + 0.3 * sin(t * 4.0)
		_tgt.draw_polyline(pts, Color(1, 0.85, 0.45, pa), 2.0, true)
	if gl > 0.05:
		UITheme.dot(_tgt, p + Vector2(0, -30), 46.0, Color(col.r, col.g, col.b, 0.07 * gl))
	match i:
		0:   # 光之橋：拱橋
			var arc := PackedVector2Array()
			for k in 25:
				var u := k / 24.0
				arc.append(p + Vector2(-30.0 + 60.0 * u, -4.0 - 26.0 * sin(PI * u)))
			if gl > 0.05:
				_tgt.draw_polyline(arc, Color(col.r, col.g, col.b, 0.3 * gl), 11.0, true)
			_tgt.draw_polyline(arc, base, 5.0, true)
			for xx in [-24.0, -12.0, 0.0, 12.0, 24.0]:
				var top := p + Vector2(xx, -4.0 - 26.0 * sin(PI * (xx + 30.0) / 60.0))
				_tgt.draw_line(top, Vector2(top.x, p.y - 2.0), base, 2.0)
			if gl > 0.05:
				var u2 := fposmod(t * 0.4, 1.0)
				UITheme.dot(_tgt, p + Vector2(-30.0 + 60.0 * u2, -4.0 - 26.0 * sin(PI * u2) - 4.0), 4.0, Color(1, 1, 0.85, gl))
		1:   # 鍛造所：屋子、煙囪、爐火
			_tgt.draw_rect(Rect2(p + Vector2(-20, -30), Vector2(40, 30)), base)
			_tgt.draw_colored_polygon(PackedVector2Array([p + Vector2(-25, -30), p + Vector2(25, -30), p + Vector2(0, -48)]), dark.lightened(0.15))
			_tgt.draw_rect(Rect2(p + Vector2(9, -50), Vector2(8, 16)), base.darkened(0.2))
			_tgt.draw_rect(Rect2(p + Vector2(-7, -16), Vector2(14, 16)), Color(1, 0.55, 0.2, 0.2 + 0.8 * gl))
			if gl > 0.05:
				UITheme.dot(_tgt, p + Vector2(0, -8), 16.0, Color(1, 0.5, 0.2, 0.18 * gl))
				for k in 3:
					var u3 := fposmod(t * 0.35 + k / 3.0, 1.0)
					UITheme.dot(_tgt, p + Vector2(13.0 + 6.0 * sin(u3 * 6.0), -54.0 - 30.0 * u3), 3.0 + 4.0 * u3, Color(0.8, 0.8, 0.9, 0.25 * (1.0 - u3) * gl))
		2:   # 天秤神殿：柱子、屋頂、天秤
			_tgt.draw_rect(Rect2(p + Vector2(-28, -6), Vector2(56, 6)), base)
			for xx in [-20.0, -3.0, 14.0]:
				_tgt.draw_rect(Rect2(p + Vector2(xx, -32), Vector2(6, 26)), base)
			_tgt.draw_colored_polygon(PackedVector2Array([p + Vector2(-31, -32), p + Vector2(31, -32), p + Vector2(0, -48)]), dark.lightened(0.15))
			var tilt := 0.18 * sin(t * 1.3) * (1.0 - gl) + 0.03 * sin(t * 2.0) * gl
			var c0 := p + Vector2(0, -60)
			var dv := Vector2(cos(tilt), sin(tilt)) * 18.0
			_tgt.draw_line(p + Vector2(0, -48), c0, base, 2.0)
			_tgt.draw_line(c0 - dv, c0 + dv, base.lightened(0.2), 2.5)
			for e in [c0 - dv, c0 + dv]:
				_tgt.draw_arc(e + Vector2(0, 6), 5.0, 0.0, PI, 10, base.lightened(0.2), 2.0)
		3:   # 鍊金塔：塔身＋燒瓶
			_tgt.draw_rect(Rect2(p + Vector2(-11, -40), Vector2(22, 40)), base)
			_tgt.draw_rect(Rect2(p + Vector2(-4, -30), Vector2(8, 9)), light if gl > 0.05 else dark)
			UITheme.dot(_tgt, p + Vector2(0, -52), 12.0, dark.lightened(0.2))
			UITheme.dot(_tgt, p + Vector2(0, -50), 9.0, Color(col.r, col.g, col.b, 0.2 + 0.7 * gl))
			_tgt.draw_rect(Rect2(p + Vector2(-3, -70), Vector2(6, 9)), dark.lightened(0.2))
			if gl > 0.05:
				for k in 3:
					var u4 := fposmod(t * 0.5 + k / 3.0, 1.0)
					_tgt.draw_arc(p + Vector2(4.0 * sin(k + t), -72.0 - 26.0 * u4), 2.0 + 2.0 * u4, 0, TAU, 12, Color(col.r, col.g, col.b, (1.0 - u4) * gl), 1.5)
		4:   # 鏡像之塔：細長的塔＋旋轉的鏡子
			_tgt.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, 0), p + Vector2(9, 0), p + Vector2(5, -64), p + Vector2(-5, -64)]), base)
			for yy in [-18.0, -34.0, -50.0]:
				_tgt.draw_rect(Rect2(p + Vector2(-2, yy), Vector2(4, 6)), light if gl > 0.05 else dark)
			var s := absf(cos(t * 1.4)) * 10.0 + 2.0
			var mc := p + Vector2(0, -76)
			_tgt.draw_colored_polygon(PackedVector2Array([mc + Vector2(0, -11), mc + Vector2(s, 0), mc + Vector2(0, 11), mc + Vector2(-s, 0)]),
				Color(0.75, 0.8, 1.0, 0.35).lerp(col.lightened(0.3), gl))
			if gl > 0.05:
				UITheme.dot(_tgt, mc, 18.0, Color(col.r, col.g, col.b, 0.15 * gl))
		5:   # 守門員：球門
			var gc := base.lightened(0.25)
			_tgt.draw_line(p + Vector2(-26, 0), p + Vector2(-26, -32), gc, 3.0)
			_tgt.draw_line(p + Vector2(26, 0), p + Vector2(26, -32), gc, 3.0)
			_tgt.draw_line(p + Vector2(-27, -32), p + Vector2(27, -32), gc, 3.0)
			for k in range(1, 6):
				var xx := -26.0 + k * 52.0 / 6.0
				_tgt.draw_line(p + Vector2(xx, -32), p + Vector2(xx, 0), Color(1, 1, 1, 0.08 + 0.15 * gl), 1.0)
			for k in range(1, 4):
				_tgt.draw_line(p + Vector2(-26, -32 + k * 8), p + Vector2(26, -32 + k * 8), Color(1, 1, 1, 0.08 + 0.15 * gl), 1.0)
			_tgt.draw_line(p + Vector2(26, -32), p + Vector2(26, -46), gc, 1.5)
			_tgt.draw_colored_polygon(PackedVector2Array([p + Vector2(26, -46), p + Vector2(40, -42), p + Vector2(26, -38)]), light if gl > 0.05 else dark)
		6:   # 羅盤：台座＋轉動的指針
			_tgt.draw_rect(Rect2(p + Vector2(-9, -14), Vector2(18, 14)), base)
			var cc := p + Vector2(0, -34)
			UITheme.dot(_tgt, cc, 18.0, dark.lightened(0.1))
			_tgt.draw_arc(cc, 18.0, 0, TAU, 32, base.lightened(0.3), 2.0, true)
			var ang := 0.6 + (t * 0.7 if gl > 0.5 else 1.2 * sin(t * 3.1) + 0.8 * sin(t * 1.7))
			var d := Vector2(cos(ang), sin(ang))
			var n := d.orthogonal() * 4.0
			_tgt.draw_colored_polygon(PackedVector2Array([cc + d * 15.0, cc + n, cc - n]), Color(1, 0.4, 0.45, 0.5 + 0.5 * gl))
			_tgt.draw_colored_polygon(PackedVector2Array([cc - d * 15.0, cc + n, cc - n]), Color(0.85, 0.88, 1.0, 0.5 + 0.4 * gl))
		7:   # 望遠鏡：天文台的圓頂＋光束
			_tgt.draw_rect(Rect2(p + Vector2(-22, -18), Vector2(44, 18)), base)
			UITheme.dot(_tgt, p + Vector2(0, -18), 20.0, base.lightened(0.1))
			_tgt.draw_rect(Rect2(p + Vector2(-22, -18), Vector2(44, 3)), base)
			var tip := p + Vector2(18, -50)
			_tgt.draw_line(p + Vector2(0, -26), tip, dark.lightened(0.35), 6.0)
			if gl > 0.05:
				var dir := (tip - (p + Vector2(0, -26))).normalized()
				var far := tip + dir * 420.0
				var o := dir.orthogonal()
				_tgt.draw_colored_polygon(PackedVector2Array([tip + o * 3.0, tip - o * 3.0, far - o * 40.0, far + o * 40.0]),
					Color(col.r, col.g, col.b, 0.10 * gl))


func _draw_fog() -> void:
	for f in fog:
		var i: int = f.site
		var dim: float = 1.0 - glow[i]
		if dim <= 0.02:
			continue
		var c: Vector2 = site_point(i) + f.o + Vector2(8.0 * sin(t * 0.4 + f.ph), 3.0 * sin(t * 0.7 + f.ph))
		# 四層半透明圓一層一層疊（邊緣才柔和）：預先烤成一張貼圖，每團霧只要畫一個方塊
		var r: float = f.r
		_tgt.draw_texture_rect(_fog_tex(), Rect2(c.x - r, c.y - r, 2.0 * r, 2.0 * r), false,
			Color(0.5, 0.55, 0.8, 1.0 - pow(1.0 - 0.025 * dim, 4.0)))


## 霧團貼圖：半徑 1、0.8、0.6、0.4 四個圓疊起來的樣子（中心最濃、往外一圈一圈變淡）
static var _fog_texture: Texture2D

static func _fog_tex() -> Texture2D:
	if _fog_texture:
		return _fog_texture
	var n := 128
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	var half := n / 2.0
	var full := 1.0 - pow(1.0 - 0.025, 4.0)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - half, y + 0.5 - half).length()
			var keep := 1.0
			for k in 4:
				var cover := clampf(half * (1.0 - 0.2 * k) - d + 0.5, 0.0, 1.0)
				keep *= 1.0 - 0.025 * cover
			img.set_pixel(x, y, Color(1, 1, 1, (1.0 - keep) / full))
	_fog_texture = ImageTexture.create_from_image(img)
	return _fog_texture


func _draw_label(font: Font, i: int) -> void:
	var info: Dictionary = Center.level_info(SITES[i].id)
	var c: Color = info.color
	var gl: float = glow[i]
	var p := site_point(i) + Vector2(0, label_dy(i))
	var tc := Color(0.74, 0.78, 0.94, 0.9).lerp(c.lightened(0.2), clampf(gl * 1.2, 0.0, 1.0))
	if i == sel and not playing:
		tc = Color(1, 0.9, 0.6)
	var r := 11.0
	var cx := p + Vector2(-font.get_string_size(info.name, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15)).x / 2.0 - 16.0, -5.0)
	UITheme.dot(_tgt, cx, r, Color(c.r, c.g, c.b, 0.18 + 0.5 * gl))
	_tgt.draw_arc(cx, r, 0, TAU, 24, Color(c.r, c.g, c.b, 0.5 + 0.5 * gl), 1.5, true)
	UITheme.text_ol(_tgt, font, cx + Vector2(-10, 5), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 20, UITheme.fs(13), Color(1, 1, 1, 0.95), 3)
	UITheme.text_ol(_tgt, font, p + Vector2(-70, 0), info.name, HORIZONTAL_ALIGNMENT_CENTER, 140, UITheme.fs(15), tc)
	if done[i]:
		UITheme.text_ol(_tgt, font, p + Vector2(-70, 17), "✦ 已點亮", HORIZONTAL_ALIGNMENT_CENTER, 140, UITheme.fs(12), Color(1, 0.85, 0.45, 0.95))
	elif progress[i] > 0.0:
		_tgt.draw_rect(Rect2(p + Vector2(-22, 8), Vector2(44, 4)), Color(1, 1, 1, 0.12))
		_tgt.draw_rect(Rect2(p + Vector2(-22, 8), Vector2(44.0 * progress[i], 4)), c)


func _draw_spirit() -> void:
	# 光靈（含扭蛋抽到的裝扮）：地圖上比較小，所以裝扮畫大一點點才看得到
	var eq := SL.eq_of(self)
	SL.draw_path_trail(_tgt, trail, 6.5, eq, t)
	var r := 6.5 if eq.is_empty() else 8.0
	SL.draw_back(_tgt, spirit, r, eq, t, false)
	SL.draw_body(_tgt, spirit, r, eq, t)
	SL.draw_eyes(_tgt, spirit, r)
	SL.draw_front(_tgt, spirit, r, eq, t)
	if not eq.has("pet"):
		for k in 3:
			var a := t * 2.0 + k * TAU / 3.0
			UITheme.dot(_tgt, spirit + Vector2(cos(a), sin(a) * 0.5) * 16.0, 1.8, Color(1, 0.95, 0.7, 0.7))


func _draw_isle_names(font: Font) -> void:
	UITheme.text_ol(_tgt, font, Vector2(56, 150), "指數島", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(30), Color(0.6, 0.85, 1.0, 0.85), 6)
	UITheme.text_ol(_tgt, font, Vector2(800, 474), "對數島", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(30), Color(1.0, 0.68, 0.86, 0.85), 6)


# ================= 劇情 =================

func _update_story_btn() -> void:
	if _story_btn:
		_story_btn.visible = not Game.of(self).story_seen.is_empty()


## 播放一段劇情。auto = true：看完自動接著播下一段還沒看過的
func play_story(key: String, auto := false) -> void:
	if not STORY.has(key) or playing:
		return
	playing = true
	story_changed.emit(true)
	_card.visible = false
	_story_btn.visible = false
	var g = Game.of(self)
	# 重看已經點亮的劇情：先把那一區暗下來，再重新點亮一次
	var steps: Array = STORY[key]
	for st in steps:
		if st.has("light"):
			glow[st.light] = 0.32 * progress[st.light]
	if key == "prologue":
		spirit_on = false
	_player = StoryPlayer.new()
	_player.title = STORY_TITLES.get(key, "")
	add_child(_player)
	await _player.intro()
	for st in steps:
		await _story_step(st)
		await _player.say(st.get("text", ""), st.get("who", ""))
		if not is_instance_valid(_player):
			break
		if _player.skipped:
			break
	# 結束（或略過）：把該亮的都點亮；光靈停在劇情最後帶去的那一關
	var last_spirit := -1
	for st in steps:
		if st.has("light"):
			glow[st.light] = 1.0
		if st.has("spirit"):
			last_spirit = int(st.spirit)
	if last_spirit >= 0 and auto:
		select(last_spirit, false)
	else:
		spirit_target = hover_point(sel)     # 重看舊劇情：光靈回到原本選的地方
	spirit_on = true
	g.mark_story(key)
	if is_instance_valid(_player):
		await _player.outro()
		_player.queue_free()
	_player = null
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "cam", Vector2(W / 2.0, H / 2.0), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "zoom", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	playing = false
	story_changed.emit(false)
	_card.visible = true
	refresh()
	_update_card()
	if auto:
		call_deferred("_play_pending")


func _story_step(st: Dictionary) -> void:
	var target := Vector2(W / 2.0, H / 2.0)
	var z: float = st.get("zoom", 1.0)
	match st.get("cam", "wide"):
		"site":
			target = site_point(int(st.site)) + Vector2(0, -40)
		"isle0":
			target = geo(Vector2(137.0, 37.0)) if _custom(0) else spine(0, 0.55)
		"isle1":
			target = Vector2(820, 360) if _custom(1) else spine(1, 0.4)
		_:
			z = 1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "cam", target, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "zoom", z, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if st.has("spirit"):
		spirit_target = hover_point(int(st.spirit))
		if st.get("appear", false):
			spirit = spirit_target
			spirit_on = true
			trail.clear()
			_burst(spirit, Color(1, 0.95, 0.7), 40)
			Game.of(self).sfx("open")
	if st.has("light"):
		var i: int = st.light
		tw.tween_method(func(v: float): glow[i] = v, glow[i], 1.0, 1.6).set_delay(0.5)
		var info: Dictionary = Center.level_info(SITES[i].id)
		get_tree().create_timer(0.6).timeout.connect(func():
			_burst(site_point(i) + Vector2(0, -30), info.color, 50)
			Game.of(self).sfx("fanfare"))
	if st.get("all", false):
		for i in SITES.size():
			var info2: Dictionary = Center.level_info(SITES[i].id)
			get_tree().create_timer(0.15 * i).timeout.connect(func(): _burst(site_point(i) + Vector2(0, -30), info2.color, 24))
		Game.of(self).sfx("fanfare")
	await get_tree().create_timer(0.35).timeout


func _burst(at: Vector2, c: Color, n: int) -> void:
	for k in n:
		var ang := randf() * TAU
		var sp := randf_range(30, 120)
		particles.append({"p": at, "v": Vector2(cos(ang), sin(ang)) * sp, "life": 1.0, "c": c, "r": randf_range(1.5, 3.5)})


## 劇情回顧：看過的劇情可以重播
func _show_story_list() -> void:
	if playing:
		return
	var g = Game.of(self)
	var o := UITheme.modal(self, Color(1, 0.85, 0.45, 0.5), 420)
	var layer: Control = o[0]
	_overlay = layer
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(UITheme.title_label("劇情回顧", 26, UITheme.ACCENT))
	# 章節列表放在捲動區裡：整張卡片上下和畫面邊緣都留空
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, H - 2 * 40.0 - 2 * 24.0 - 140.0)
	var vsb := scroll.get_v_scroll_bar()
	vsb.custom_minimum_size = Vector2(5, 0)
	vsb.add_theme_stylebox_override("scroll", UITheme.box(Color(1, 1, 1, 0.04), 3, Color(0, 0, 0, 0), 0, 0))
	for st in ["grabber", "grabber_highlight", "grabber_pressed"]:
		vsb.add_theme_stylebox_override(st, UITheme.box(Color(1, 1, 1, 0.25), 3, Color(0, 0, 0, 0), 0, 0))
	col.add_child(scroll)
	# 右邊留出捲軸的位置，選項方塊才不會和捲軸重疊
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", 14)
	scroll.add_child(pad)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	pad.add_child(list)
	var keys := ["prologue", "L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "epilogue"]
	for k in keys:
		var seen: bool = g.story_seen.has(k)
		var b := Button.new()
		b.text = STORY_TITLES[k] if seen else "？？？（點亮聖地後解鎖）"
		b.custom_minimum_size = Vector2(0, 44)
		b.add_theme_font_size_override("font_size", UITheme.fs(15))
		b.disabled = not seen
		b.mouse_filter = Control.MOUSE_FILTER_PASS     # 手指按在按鈕上拖動也能捲動列表
		if not seen:
			b.set_meta("silent", true)
		var key: String = k
		b.pressed.connect(func():
			layer.queue_free()
			play_story(key))
		list.add_child(b)
	var close := UITheme.ghost_button("關閉", 16)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): layer.queue_free())
	col.add_child(close)


## 地圖上開著的視窗（劇情回顧）：返回鍵會先關掉它
var _overlay: Control

func close_overlay() -> bool:
	if is_instance_valid(_overlay) and not _overlay.is_queued_for_deletion():
		_overlay.queue_free()
		_overlay = null
		return true
	return false

## 劇情播放器：上下黑邊、字幕逐字出現、點一下繼續
class StoryPlayer extends Control:
	const UITheme := preload("game_theme.gd")
	const SZ := Vector2(1152, 648)
	signal advanced
	var title := ""
	var bars := 0.0
	var t := 0.0
	var skipped := false
	var typing := false
	var _label: Label
	var _who: Label
	var _face: Control
	var _tw: Tween
	var _hint_a := 0.0

	func _ready() -> void:
		position = Vector2.ZERO
		size = SZ
		mouse_filter = Control.MOUSE_FILTER_STOP
		_who = Label.new()
		_who.add_theme_font_size_override("font_size", UITheme.fs(15))
		_who.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
		var vs := SZ
		_who.position = Vector2(120, vs.y - 104)
		add_child(_who)
		# 光靈說話時，左下角出現光靈的頭像（會穿著扭蛋抽到的裝扮）
		_face = preload("buddy.gd").Face.new()
		_face.radius = 20.0
		_face.mood = "happy"
		_face.position = Vector2(26, vs.y - 112)
		_face.size = Vector2(80, 80)
		_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_face.visible = false
		add_child(_face)
		_label = Label.new()
		_label.add_theme_font_size_override("font_size", UITheme.fs(20))
		_label.add_theme_color_override("font_color", UITheme.TEXT)
		_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		_label.position = Vector2(120, vs.y - 80)
		_label.size = Vector2(vs.x - 240, 70)
		add_child(_label)
		var skip := UITheme.ghost_button("略過  ▸▸", 15)
		skip.position = Vector2(vs.x - 120, 14)
		skip.pressed.connect(func():
			skipped = true
			advanced.emit())
		add_child(skip)

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var h := 112.0 * bars
		draw_rect(Rect2(0, 0, SZ.x, 62.0 * bars), Color(0, 0, 0, 0.82))
		draw_rect(Rect2(0, SZ.y - h, SZ.x, h), Color(0, 0, 0, 0.82))
		if title != "" and bars > 0.5:
			var font := get_theme_default_font()
			draw_string(font, Vector2(0, 40), title, HORIZONTAL_ALIGNMENT_CENTER, SZ.x, UITheme.fs(20), Color(1, 0.85, 0.45, bars))
		if not typing and bars > 0.9:
			var a := 0.4 + 0.4 * sin(t * 4.0)
			draw_string(get_theme_default_font(), Vector2(SZ.x - 220, SZ.y - 18), "點一下繼續  ▸", HORIZONTAL_ALIGNMENT_RIGHT, 200, UITheme.fs(15), Color(1, 1, 1, a))

	func intro() -> void:
		var tw := create_tween()
		tw.tween_property(self, "bars", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await tw.finished

	func outro() -> void:
		_label.text = ""
		_who.text = ""
		var tw := create_tween()
		tw.tween_property(self, "bars", 0.0, 0.35)
		await tw.finished

	func say(text: String, who: String) -> void:
		if skipped:
			return
		_who.text = who
		_label.text = text
		_label.visible_ratio = 0.0
		if _face:
			_face.visible = who == "光靈"
			if _face.visible:
				_face.jump()
		typing = true
		_tw = create_tween()
		_tw.tween_property(_label, "visible_ratio", 1.0, maxf(0.6, text.length() / 22.0))
		_tw.finished.connect(func(): typing = false)
		await advanced

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_next()
			accept_event()

	func _unhandled_input(e: InputEvent) -> void:
		if e is InputEventKey and e.pressed and not e.echo:
			if e.keycode == KEY_ESCAPE:
				skipped = true
				advanced.emit()
			else:
				_next()
			get_viewport().set_input_as_handled()

	func _next() -> void:
		if typing:
			if _tw:
				_tw.kill()
			_label.visible_ratio = 1.0
			typing = false
			return
		advanced.emit()



## 一層畫布：把 _draw 交給地圖本體的函式來畫
class _Layer extends Node2D:
	var painter: Callable

	func _draw() -> void:
		painter.call(self)
