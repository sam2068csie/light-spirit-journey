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
##        三角函數 "G1"～／"trig_"、高一多項式 "P1"～／"poly_"、高一直線與圓 "C1"～／"line_"、高一數與式 "R1"～／"num_"、平面與直線 "N1"～／"pl_"、條件機率 "B1"～／"prob_"、矩陣 "M1"～／"mat_"
##      （check() 會檢查重複；這樣存檔裡的星星、錯題本、熟練度不會互相打架，舊存檔也不用轉換）
##   3. map：這個單元的世界地圖腳本；tower：終焉之塔的題庫（沒有就先留空）
##      concepts：觀念卡片檔（例如 "concepts_vec2.gd"，寫法照 concepts_exp.gd）
##   4. 劇情的 key 加上單元前綴（例如 "vec2/prologue"）
const UITheme := preload("res://data/ui/game_theme.gd")

const UNITS := [
	# ======================= 高一 =======================
	# 高一的單元：在「曦光大陸」（g10_world.gd）上，一個地區一個單元。題目還沒放，先 open = false（進去會顯示準備中）
	# 數與式：R1 做好了，其他七關建造中。先用 preview（開發者的「一鍵開放全部關卡」才進得去），八關做完再 open = true
	{"id": "h1num", "term": "高一上", "title": "數與式", "exam": "", "color": UITheme.GOLD, "open": false, "preview": true,
	 "world": "光靈的旅程：數之原野", "map": "num_map.gd", "tower": "", "tower_name": "終焉之塔", "concepts": "concepts_num.gd",
	 "levels": [
		{"id": "R1", "name": "風車小數", "topic": "數線、循環小數與比大小", "file": "level_num1_mill.gd", "bank": "num1_bank.gd", "color": UITheme.GOLD},
		{"id": "R2", "name": "繩上珠子", "topic": "分點公式", "file": "", "bank": "", "color": UITheme.CYAN},
		{"id": "R3", "name": "天秤市集", "topic": "次序不等式", "file": "", "bank": "", "color": UITheme.LIME},
		{"id": "R4", "name": "圍籬牧場", "topic": "算幾不等式", "file": "", "bank": "", "color": UITheme.GOOD},
		{"id": "R5", "name": "篩種倉庫", "topic": "有理數與無理數", "file": "", "bank": "", "color": UITheme.ORANGE},
		{"id": "R6", "name": "剝殼磨坊", "topic": "雙重根號", "file": "", "bank": "", "color": UITheme.VIOLET},
		{"id": "R7", "name": "方田拼圖", "topic": "乘法公式", "file": "", "bank": "", "color": UITheme.PINK},
		{"id": "R8", "name": "谷底水渠", "topic": "數線上的幾何", "file": "", "bank": "", "color": UITheme.BLUE},
	 ]},
	{"id": "h1exp", "term": "高一上", "title": "指數與常用對數", "exam": "", "color": UITheme.ORANGE, "open": false,
	 "world": "", "map": "", "tower": "", "tower_name": "", "concepts": "", "levels": []},
	# 直線與圓：八大關＋終焉之塔都做好了，2026/11/08 正式開放
	{"id": "h1line", "term": "高一上", "title": "直線與圓", "exam": "", "color": UITheme.CYAN, "open": true,
	 "world": "光靈的旅程：圓規湖", "map": "line_map.gd", "tower": "line_tower_bank.gd", "tower_name": "終焉之塔", "concepts": "concepts_line.gd",
	 "levels": [
		{"id": "C1", "name": "坐標燈標", "topic": "坐標與斜率", "file": "level_line1_coord.gd", "bank": "line1_bank.gd", "color": UITheme.CYAN},
		{"id": "C2", "name": "直線棧橋", "topic": "直線方程式", "file": "level_line2_pier.gd", "bank": "line2_bank.gd", "color": UITheme.GOLD},
		{"id": "C3", "name": "鏡面渡口", "topic": "對稱與距離", "file": "level_line3_mirror.gd", "bank": "line3_bank.gd", "color": UITheme.LIME},
		{"id": "C4", "name": "分光稻田", "topic": "二元一次不等式", "file": "level_line4_paddy.gd", "bank": "line4_bank.gd", "color": UITheme.ORANGE},
		{"id": "C5", "name": "圓規工坊", "topic": "圓方程式與求圓", "file": "level_line5_compass.gd", "bank": "line5_bank.gd", "color": UITheme.VIOLET},
		{"id": "C6", "name": "割弦漣漪", "topic": "圓與直線", "file": "level_line6_ripple.gd", "bank": "line6_bank.gd", "color": UITheme.BLUE},
		{"id": "C7", "name": "切線燈環", "topic": "切線", "file": "level_line7_lamp.gd", "bank": "line7_bank.gd", "color": UITheme.PINK},
		{"id": "C8", "name": "軌跡星環", "topic": "圓系與軌跡", "file": "level_line8_star.gd", "bank": "line8_bank.gd", "color": UITheme.GOOD},
	 ]},
	# 多項式：P1～P8 全部做好，正式開放
	{"id": "h1poly", "term": "高一上", "title": "多項式", "exam": "", "color": UITheme.VIOLET, "open": true,
	 "world": "光靈的旅程：根之洞窟", "map": "poly_map.gd", "tower": "poly_tower_bank.gd", "tower_name": "終焉之塔", "concepts": "concepts_poly.gd",
	 "levels": [
		{"id": "P1", "name": "係數礦燈", "topic": "多項式與係數", "file": "level_poly1_lamp.gd", "bank": "poly1_bank.gd", "color": UITheme.GOLD},
		{"id": "P2", "name": "綜合除法水車", "topic": "多項式的除法", "file": "level_poly2_wheel.gd", "bank": "poly2_bank.gd", "color": UITheme.CYAN},
		{"id": "P3", "name": "回音石廊", "topic": "餘式定理與因式定理", "file": "level_poly3_echo.gd", "bank": "poly3_bank.gd", "color": UITheme.BLUE},
		{"id": "P4", "name": "根之鑄模", "topic": "求多項式", "file": "level_poly4_mold.gd", "bank": "poly4_bank.gd", "color": UITheme.ORANGE},
		{"id": "P5", "name": "拋物鏡湖", "topic": "二次函數的圖形", "file": "level_poly5_lake.gd", "bank": "poly5_bank.gd", "color": UITheme.GOOD},
		{"id": "P6", "name": "極值燈芯", "topic": "二次函數的極值", "file": "level_poly6_wick.gd", "bank": "poly6_bank.gd", "color": UITheme.LIME},
		{"id": "P7", "name": "對稱水晶", "topic": "三次函數的圖形", "file": "level_poly7_crystal.gd", "bank": "poly7_bank.gd", "color": UITheme.VIOLET},
		{"id": "P8", "name": "符號地下河", "topic": "多項式不等式", "file": "level_poly8_river.gd", "bank": "poly8_bank.gd", "color": UITheme.PINK},
	 ]},
	{"id": "h1seq", "term": "高一下", "title": "數列與級數", "exam": "", "color": UITheme.GOOD, "open": false,
	 "world": "", "map": "", "tower": "", "tower_name": "", "concepts": "", "levels": []},
	{"id": "h1data", "term": "高一下", "title": "數據分析", "exam": "", "color": UITheme.BLUE, "open": false,
	 "world": "", "map": "", "tower": "", "tower_name": "", "concepts": "", "levels": []},
	{"id": "h1comb", "term": "高一下", "title": "排列組合", "exam": "", "color": UITheme.PINK, "open": false,
	 "world": "", "map": "", "tower": "", "tower_name": "", "concepts": "", "levels": []},
	{"id": "h1prob", "term": "高一下", "title": "機率", "exam": "", "color": UITheme.ORANGE, "open": false,
	 "world": "", "map": "", "tower": "", "tower_name": "", "concepts": "", "levels": []},
	{"id": "h1trig", "term": "高一下", "title": "三角比", "exam": "", "color": UITheme.GOLD, "open": false,
	 "world": "", "map": "", "tower": "", "tower_name": "", "concepts": "", "levels": []},
	# ======================= 高二上 =======================
	# 三角函數：G1～G7 全部做好，正式開放
	{"id": "trig", "term": "高二上", "title": "三角函數", "exam": "", "color": UITheme.PINK, "open": true,
	 "world": "光靈的旅程：月輪島與正弦海岸", "map": "trig_map.gd", "tower": "trig_tower_bank.gd", "tower_name": "終焉之塔", "concepts": "concepts_trig.gd",
	 "levels": [
		{"id": "G1", "name": "弧之渡口", "topic": "弧度量", "file": "level_trig1_arc.gd", "bank": "trig1_bank.gd", "color": UITheme.CYAN},
		{"id": "G2", "name": "扇形潟湖", "topic": "扇形弧長與面積", "file": "level_trig2_sector.gd", "bank": "trig2_bank.gd", "color": UITheme.ORANGE},
		{"id": "G3", "name": "浪之階梯", "topic": "三角函數的圖形", "file": "level_trig3_wave.gd", "bank": "trig3_bank.gd", "color": UITheme.LIME},
		{"id": "G4", "name": "潮汐調音盤", "topic": "圖形的伸縮與平移", "file": "level_trig4_tide.gd", "bank": "trig4_bank.gd", "color": UITheme.VIOLET},
		{"id": "G5", "name": "和角羅盤", "topic": "和角公式", "file": "level_trig5_compass.gd", "bank": "trig5_bank.gd", "color": UITheme.PINK},
		{"id": "G6", "name": "倍角鏡池", "topic": "二倍角與半角公式", "file": "level_trig6_mirror.gd", "bank": "trig6_bank.gd", "color": UITheme.GOLD},
		{"id": "G7", "name": "疊合燈塔", "topic": "正餘弦函數的疊合", "file": "level_trig7_lighthouse.gd", "bank": "trig7_bank.gd", "color": UITheme.GOOD},
	 ]},
	{"id": "exp", "term": "高二上", "title": "指數與對數", "exam": "高二上・第二次段考", "color": UITheme.GOLD, "open": true,
	 "world": "光靈的旅程：指數島與對數島", "map": "exp_map.gd", "tower": "tower_bank.gd", "tower_name": "終焉之塔",
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
const TERMS := ["高一上", "高一下", "高二上", "高二下"]
## 年級分頁：選擇冒險一次只排一個年級（兩排），免得超出畫面
const GRADES := {"高一": ["高一上", "高一下"], "高二": ["高二上", "高二下"]}


static func grade_of(uid: String) -> String:
	var term := String(unit(uid).term)
	for g in GRADES:
		if term in GRADES[g]:
			return g
	return "高二"

const DEFAULT := "exp"


## 今天是哪個學期：7/1～隔年 1/31 是上學期，2/1～6/30 是下學期（grade = "高一"／"高二" → "高一上"、"高二下"…）
static func term_now(grade: String, month := -1) -> String:
	var m := month if month > 0 else int(Time.get_date_dict_from_system().month)
	return grade + ("上" if m >= 7 or m == 1 else "下")


## 某個學期的所有單元（照課本順序）
static func term_units(term: String) -> Array:
	var out := []
	for u in UNITS:
		if String(u.term) == term:
			out.append(u)
	return out


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


## 這一大關屬於哪個單元（終焉之塔的題目 "T" 不屬於任何大關，回傳預設單元）
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
