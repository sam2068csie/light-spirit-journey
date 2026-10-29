extends RefCounted
## 單元清單：每一次段考範圍是一個「單元」（一個新世界），共用同一個遊戲外殼
## （主畫面、每日任務、簽到、扭蛋、衣櫃、修煉之間、終焉之塔、數學排版、存檔）。
##
## 新增單元的步驟（例如平面向量）：
##   1. 在 UNITS 找到那一筆（已經照課本章節順序排好）：填段考、world、open = true、levels（每一大關的 id、檔案、題庫）
##      關卡繼承 step_level.gd（通用的步驟推導引擎），題庫用 step_bank.gd 的小工具寫
##   2. 大關 id 和觀念標籤（tag）不能和別的單元重複：
##        指數與對數用 "L1"～"L8"、tag 用 exp_／log_／digits_… 開頭
##        平面向量建議用 "V1"～、tag 用 "vec_" 開頭；空間向量用 "S1"～、tag 用 "svec_" 開頭
##        三角函數 "G1"～／"trig_"、平面與直線 "P1"～／"pl_"、條件機率 "B1"～／"prob_"、矩陣 "M1"～／"mat_"
##      （check() 會檢查重複；這樣存檔裡的星星、錯題本、熟練度不會互相打架，舊存檔也不用轉換）
##   3. map：這個單元的世界地圖腳本；tower：終焉之塔的題庫（沒有就先留空）
##      concepts：觀念卡片檔（例如 "concepts_vec2.gd"，寫法照 concepts_exp.gd）
##   4. 劇情的 key 加上單元前綴（例如 "vec2/prologue"）
const UITheme := preload("game_theme.gd")

const UNITS := [
	# ======================= 高二上 =======================
	# 三角函數：建造中。preview = true → 開發者功能「一鍵開放全部關卡」打開時可以先進去看（學生看不到）
	{"id": "trig", "term": "高二上", "title": "三角函數", "exam": "", "color": UITheme.PINK, "open": false, "preview": true,
	 "world": "光靈的旅程：月輪島與正弦海岸", "map": "trig_map.gd", "tower": "", "tower_name": "終焉之塔", "concepts": "concepts_trig.gd",
	 "levels": [
		{"id": "G1", "name": "弧之渡口", "topic": "弧度量", "file": "level_trig1_arc.gd", "bank": "trig1_bank.gd", "color": UITheme.CYAN},
		{"id": "G2", "name": "扇形潟湖", "topic": "扇形弧長與面積", "file": "level_trig2_sector.gd", "bank": "trig2_bank.gd", "color": UITheme.ORANGE},
		{"id": "G3", "name": "浪之階梯", "topic": "三角函數的圖形", "file": "level_trig3_wave.gd", "bank": "trig3_bank.gd", "color": UITheme.LIME},
		{"id": "G4", "name": "潮汐調音台", "topic": "伸縮與平移", "file": "", "bank": "", "color": UITheme.VIOLET},
		{"id": "G5", "name": "和角羅盤", "topic": "和角公式", "file": "", "bank": "", "color": UITheme.PINK},
		{"id": "G6", "name": "倍角鏡池", "topic": "二倍角與半角公式", "file": "", "bank": "", "color": UITheme.GOLD},
		{"id": "G7", "name": "疊合燈塔", "topic": "正餘弦函數的疊合", "file": "", "bank": "", "color": UITheme.GOOD},
	 ]},
	{"id": "exp", "term": "高二上", "title": "指數與對數", "exam": "高二上・第二次段考", "color": UITheme.GOLD, "open": true,
	 "world": "光靈的旅程：指數島與對數島", "map": "world_map.gd", "tower": "tower_bank.gd", "tower_name": "終焉之塔",
	 "concepts": "concepts_exp.gd",
	 "levels": [
		{"id": "L1", "name": "光之橋", "topic": "指數函數的圖形", "file": "level_01_light_bridge.gd", "bank": "level01_bank.gd", "color": UITheme.CYAN},
		{"id": "L2", "name": "換元鍛造所", "topic": "指數方程式", "file": "level_02_forge.gd", "bank": "level02_bank.gd", "color": UITheme.ORANGE},
		{"id": "L3", "name": "天秤神殿", "topic": "指數不等式與極值", "file": "level_03_scale.gd", "bank": "level03_bank.gd", "color": UITheme.LIME},
		{"id": "L4", "name": "對數鍊金術", "topic": "對數的運算性質", "file": "level_04_alchemy.gd", "bank": "level04_bank.gd", "color": UITheme.VIOLET},
		{"id": "L5", "name": "鏡像之塔", "topic": "對數函數的圖形", "file": "level_05_mirror_tower.gd", "bank": "level05_bank.gd", "color": UITheme.PINK},
		{"id": "L6", "name": "真數守門員", "topic": "對數方程式", "file": "level_06_keeper.gd", "bank": "level06_bank.gd", "color": UITheme.GOLD},
		{"id": "L7", "name": "正負羅盤", "topic": "對數不等式", "file": "level_07_compass.gd", "bank": "level07_bank.gd", "color": UITheme.GOOD},
		{"id": "L8", "name": "位數望遠鏡", "topic": "首數、尾數與應用", "file": "level_08_telescope.gd", "bank": "level08_bank.gd", "color": UITheme.BLUE},
	 ]},
	{"id": "vec2", "term": "高二上", "title": "平面向量", "exam": "", "color": UITheme.CYAN, "open": false,
	 "world": "", "map": "", "tower": "", "tower_name": "", "concepts": "", "levels": []},
	# ======================= 高二下 =======================
	{"id": "vec3", "term": "高二下", "title": "空間向量", "exam": "", "color": UITheme.VIOLET, "open": false,
	 "world": "", "map": "", "tower": "", "tower_name": "", "concepts": "", "levels": []},
	{"id": "plane", "term": "高二下", "title": "空間中的平面與直線", "exam": "", "color": UITheme.GOOD, "open": false,
	 "world": "", "map": "", "tower": "", "tower_name": "", "concepts": "", "levels": []},
	{"id": "prob", "term": "高二下", "title": "條件機率與貝氏定理", "exam": "", "color": UITheme.ORANGE, "open": false,
	 "world": "", "map": "", "tower": "", "tower_name": "", "concepts": "", "levels": []},
	{"id": "matrix", "term": "高二下", "title": "矩陣", "exam": "", "color": UITheme.BLUE, "open": false,
	 "world": "", "map": "", "tower": "", "tower_name": "", "concepts": "", "levels": []},
]

## 選擇冒險頁面的分組（依課本的章節順序；UNITS 也照這個順序排）
const TERMS := ["高二上", "高二下"]

const DEFAULT := "exp"


static func unit(id: String) -> Dictionary:
	for u in UNITS:
		if u.id == id:
			return u
	for u in UNITS:
		if u.id == DEFAULT:
			return u
	return UNITS[0]


## 某個學期的單元（照章節順序）
static func units_of_term(term: String) -> Array:
	return UNITS.filter(func(u): return u.term == term)


static func open_units() -> Array:
	return UNITS.filter(func(u): return is_open(u))


## 這個單元能不能進去：正式開放，或是建造中（preview）但開了開發者的「一鍵開放全部關卡」
static func is_open(u: Dictionary) -> bool:
	if bool(u.get("open", false)):
		return true
	if not bool(u.get("preview", false)):
		return false
	var ml = Engine.get_main_loop()
	var g = ml.root.get_node_or_null("Game") if ml is SceneTree else null
	return g != null and bool(g.get("dev_unlock_all"))


## 所有單元的所有大關（修煉之間的觀念索引用）
static func all_levels() -> Array:
	var out := []
	for u in UNITS:
		out.append_array(u.levels)
	return out


static func level_ids(uid: String) -> Array:
	return unit(uid).levels.map(func(l): return l.id)


## 這一大關屬於哪個單元（終焉之塔的題目 "T" 算在指數與對數）
static func unit_of_level(level_id: String) -> String:
	for u in UNITS:
		for l in u.levels:
			if l.id == level_id:
				return u.id
	return DEFAULT


## 檢查大關 id 不重複；回傳問題清單（空的就是沒問題）
static func check() -> Array:
	var seen := {}
	var problems := []
	for u in UNITS:
		for l in u.levels:
			if seen.has(l.id):
				problems.append("大關 id「%s」在 %s 和 %s 重複了" % [l.id, seen[l.id], u.id])
			seen[l.id] = u.id
	return problems
