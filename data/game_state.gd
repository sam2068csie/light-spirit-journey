extends Node
## 遊戲管家（第 1 層）：所有存檔資料、設定、存檔／讀檔、星數、旅程完成度、錯題本
## 管家分成四層，一層繼承一層，外面一律用 Game.of(self) 拿到同一個物件，呼叫方式不變：
##   game_state.gd（資料與存檔）→ game_audio.gd（音效、音樂）→ game_economy.gd（星塵、寶箱、每日任務、扭蛋、簽到）→ game.gd（換場景、修煉、終焉之塔）
## 下面的層不能呼叫上面的層（例如存檔不能播音效）；要加新功能時放在用得到的最低那一層。

const SETTINGS_PATH := "user://settings.cfg"


const STARS_PATH := "user://stars.cfg"


const CLEARED_PATH := "user://cleared.cfg"


const REVIEW_PATH := "user://review.json"


const BGM_CACHE := "user://crystal_bgm_v2.res"   # v2：結尾補了防越界的波形


const BGM_BAKED := "res://audio/crystal_bgm.res"


const SR := 22050


const D5 := 587.33


const PENTA := [0, 2, 4, 7, 9]        # D 大調五聲音階（相對 D 的半音數）


var master_vol := 0.8


var music_vol := 0.55


var sfx_vol := 0.8


var stars := {}                        # 關卡 id → 最佳星數


var cleared := {}                      # 旅程 id（例如 "L1/rise"）→ 已答對過的題型編號陣列


var args := {}                         # 換場景時傳給下一個場景的參數


# 錯題本與每日修煉（計算在 review_center.gd）
var mistakes := {}                     # 觀念 tag → 答錯次數


var fixed := {}                        # 觀念 tag → 複習分數（答對 +1、一次全對 +2）


var last_wrong := {}                   # 觀念 tag → 最後一次答錯的時間


# ---- 單元：每次段考範圍是一個單元（units.gd）。下面幾項每個單元各一份 ----
var cur_unit := "exp"                  # 目前在玩的單元


var _per_unit := {}                    # 單元 → {daily, tower_best, tower_runs, map_sel}


func _pu() -> Dictionary:
	if not _per_unit.has(cur_unit):
		_per_unit[cur_unit] = {"daily": {}, "tower_best": 0, "tower_runs": 0, "map_sel": -1}
	return _per_unit[cur_unit]


var daily: Dictionary:                 # 目前單元的今日修煉 {date, items: [...], results: [...]}
	get:
		return _pu().daily
	set(v):
		_pu().daily = v


var review_days: Array = []            # 完成每日修煉的日期


var session := {}                      # 進行中的修煉：{kind, items, i, results}


var map_sel: int:                      # 世界地圖上最後選的聖地（從關卡回來時光靈停在這裡）
	get:
		return int(_pu().map_sel)
	set(v):
		_pu().map_sel = v


var story_seen: Array = []


var tower_best: int:                   # 終焉之塔（目前單元）：最高爬到第幾層（通過的層數）
	get:
		return int(_pu().tower_best)
	set(v):
		_pu().tower_best = v


var tower_runs: int:                   # 累積攀登次數
	get:
		return int(_pu().tower_runs)
	set(v):
		_pu().tower_runs = v


var quests := {}                       # 每日任務：{day, prog: {key: 次數}, got: [已領的任務], tiers: [已領的區間], ch: 今日挑戰}


var inv := {"dust": 0, "shard": 0, "crystal": 0}   # 持有物品：星塵、光之碎片、光之結晶


var main_rw := {"slots": {}, "types": {}, "star3": {}, "chests": {}, "tower_day": {}}   # 主線、終焉之塔的獎勵領過哪些


var owned := {}                        # 光靈裝扮：id → 抽到幾次


var streak := {"last": "", "count": 0, "best": 0, "guards": 1, "log": [], "popup": ""}   # 連續簽到（log：最近的簽到／守護紀錄）


var equipped := {}                     # 穿戴中：類別 → id


var tut := {}                          # 新手教學看過哪些：{"basic": true, "type:fit": true…}


var grade_pick := ""                   # 第一次打開時選的身分（"高一"／"高二"）；空字串＝還沒選


var house := {}                        # 光靈小屋：{owned:[], placed:{格位:id}}


var world11 := {}                      # 高二世界地圖（光潮群島）：{pos, visited, eggs, ret}


var world10 := {}                      # 高一世界地圖（曦光大陸）：{stones: 啟用的傳送石, visited: 去過的地區, eggs: 找到的彩蛋, pos: [x, y]}


var gacha := {"pity_sr": 0, "pity_ssr": 0, "half_day": "", "pulls": 0}   # 扭蛋：保底計數、今天首抽半價用掉了沒


var tower_from := "levels"             # 從哪一頁進終焉之塔（"title" 主畫面／"levels" 世界地圖），返回鍵就回那裡


# 開發者功能（存在 settings.cfg）
var dev_unlock_all := false            # 一鍵開放全部關卡：每一章的旅程都不用照順序解鎖


var res_index := 1                     # 解析度：RESOLUTIONS 的第幾個


var show_fps := false                  # 在畫面左上角顯示幀數（手機上檢查效能用）


# 提醒通知（notifier.gd）
var notify_on := true                  # 好幾天沒來時，光靈傳通知提醒


var notify_time := "19:30"             # 幾點提醒


var notify_asked := false              # 已經問過「要不要讓光靈提醒你」了


var notifier: Node


# 省電：畫面沒在操作時降到 30 幀（手機比較不會發燙），一碰螢幕馬上回到 60 幀
var power_save := true


const FPS_ACTIVE := 60


const FPS_IDLE := 30


const IDLE_AFTER_MS := 1800             # 多久沒操作算「閒置」


var _active_until := 0


var _bgm: AudioStreamPlayer


var _pool: Array = []


var _pool_i := 0


var _snd := {}


var _fade: ColorRect


var fx: Control                 # 回饋特效層（fx_layer.gd）：答對星星、答錯晃動、過關紙花


var _last_press := Vector2(-1, -1)    # 最後一次按下的位置：答對的星星從這裡炸開


var _changing := false


var _last_tick := 0


var _duck_tween: Tween


# ================= 設定 =================

## 開發者功能：視窗解析度（遊戲畫面固定以 1152 × 648 設計，視窗大小改變時等比例縮放）
const BASE_SIZE := Vector2i(1152, 648)


const RESOLUTIONS := [
	{"name": "960 × 540", "size": Vector2i(960, 540)},
	{"name": "1152 × 648", "size": Vector2i(1152, 648)},
	{"name": "1280 × 720", "size": Vector2i(1280, 720)},
	{"name": "1600 × 900", "size": Vector2i(1600, 900)},
	{"name": "1920 × 1080", "size": Vector2i(1920, 1080)},
	{"name": "全螢幕", "size": Vector2i.ZERO},
]


## 能不能改視窗大小（Godot 4.4 起，編輯器裡「內嵌執行」的遊戲視窗不能改）
func can_resize_window() -> bool:
	if OS.has_feature("mobile") or OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return false
	if Engine.has_method("is_embedded_in_editor") and Engine.call("is_embedded_in_editor"):
		return false
	return true


func set_resolution(i: int) -> void:
	res_index = clampi(i, 0, RESOLUTIONS.size() - 1)
	apply_resolution()


func apply_resolution() -> void:
	if not is_inside_tree() or DisplayServer.get_name() == "headless":
		return
	var win := get_tree().root
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = BASE_SIZE
	# 手機、網頁版、編輯器裡的內嵌視窗都不能改視窗大小，只套用縮放
	if not can_resize_window():
		return
	var r: Dictionary = RESOLUTIONS[res_index]
	if r.size == Vector2i.ZERO:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var scr := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(scr)
	var sz: Vector2i = r.size
	sz = Vector2i(mini(sz.x, usable.size.x), mini(sz.y, usable.size.y))
	DisplayServer.window_set_size(sz)
	DisplayServer.window_set_position(usable.position + (usable.size - sz) / 2)


## 開發者功能：刪除所有遊玩紀錄（星數、旅程、錯題本、修煉、劇情、終焉之塔），音量設定保留
func wipe_progress() -> void:
	stars = {}
	cleared = {}
	_per_unit = {}
	cur_unit = "exp"
	session = {}
	for f in SAVE_FIELDS:
		set(f[0], f[2].duplicate(true) if f[2] is Dictionary or f[2] is Array else f[2])

	for path in [STARS_PATH, CLEARED_PATH, REVIEW_PATH, "user://progress.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# 寫一份空的錯題本，避免下次啟動又從舊版 progress.json 搬資料
	save_review()


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "master", master_vol)
	cf.set_value("audio", "music", music_vol)
	cf.set_value("audio", "sfx", sfx_vol)
	cf.set_value("dev", "unlock_all", dev_unlock_all)
	cf.set_value("dev", "resolution", res_index)
	cf.set_value("dev", "show_fps", show_fps)
	cf.set_value("dev", "power_save", power_save)
	cf.set_value("notify", "on", notify_on)
	cf.set_value("notify", "time", notify_time)
	cf.set_value("notify", "asked", notify_asked)
	cf.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		return
	master_vol = float(cf.get_value("audio", "master", master_vol))
	music_vol = float(cf.get_value("audio", "music", music_vol))
	sfx_vol = float(cf.get_value("audio", "sfx", sfx_vol))
	dev_unlock_all = bool(cf.get_value("dev", "unlock_all", false))
	res_index = clampi(int(cf.get_value("dev", "resolution", res_index)), 0, RESOLUTIONS.size() - 1)
	show_fps = bool(cf.get_value("dev", "show_fps", false))
	power_save = bool(cf.get_value("dev", "power_save", true))
	notify_on = bool(cf.get_value("notify", "on", true))
	notify_time = String(cf.get_value("notify", "time", "19:30"))
	notify_asked = bool(cf.get_value("notify", "asked", false))


# ================= 星數紀錄 =================

func record_stars(level_id: String, n: int) -> void:
	if n <= int(stars.get(level_id, 0)):
		return
	stars[level_id] = n
	var cf := ConfigFile.new()
	for k in stars:
		cf.set_value("stars", k, stars[k])
	cf.save(STARS_PATH)


func _load_stars() -> void:
	var cf := ConfigFile.new()
	if cf.load(STARS_PATH) != OK:
		return
	for k in cf.get_section_keys("stars"):
		stars[k] = int(cf.get_value("stars", k, 0))


func mark_cleared(journey: String, vi: int) -> bool:
	var arr: Array = cleared.get(journey, [])
	if arr.has(vi):
		return false
	arr.append(vi)
	cleared[journey] = arr
	var cf := ConfigFile.new()
	for k in cleared:
		cf.set_value("cleared", k, cleared[k])
	cf.save(CLEARED_PATH)
	return true


func cleared_of(journey: String) -> Array:
	return cleared.get(journey, [])


func _load_cleared() -> void:
	var cf := ConfigFile.new()
	if cf.load(CLEARED_PATH) != OK:
		return
	for k in cf.get_section_keys("cleared"):
		var v = cf.get_value("cleared", k, [])
		cleared[k] = Array(v) if v is Array else []


# ================= 錯題本與修煉 =================

func record_mistake(tag: String) -> void:
	if tag == "":
		return
	mistakes[tag] = int(mistakes.get(tag, 0)) + 1
	last_wrong[tag] = Time.get_unix_time_from_system()
	save_review()


func credit(tag: String, pts: int) -> void:
	if tag == "" or pts <= 0:
		return
	fixed[tag] = int(fixed.get(tag, 0)) + pts
	save_review()


## 「今天」：早上 5 點換日（每日修煉、每日任務、簽到、扭蛋半價都用同一個時間）
static func today() -> String:
	return DQ.day_key()


# ================= 存檔（review.json） =================
## 新增要存的東西：只要在 SAVE_FIELDS 加一行 [變數名, 存檔裡的 key, 預設值]，
## 存檔、讀檔、「刪除所有紀錄」都會自動處理，讀到的型別和預設值不同時會用預設值（壞掉的存檔不會讓遊戲當掉）。
## 存檔格式要改（改名、搬資料）時：把 SAVE_VERSION 加 1，在 _migrate() 寫「舊版 → 新版」怎麼轉。
## 讀檔要額外整理的欄位（數字轉 int、過濾不存在的裝扮……）在 _load_units()／_load_quests() 處理。
const SAVE_VERSION := 2      # 1：沒有版本號的舊存檔；2：加上 version


const SAVE_FIELDS := [
	["mistakes", "mistakes", {}],
	["fixed", "fixed", {}],
	["last_wrong", "last_wrong", {}],
	["review_days", "days", []],
	["story_seen", "story", []],
	["quests", "quests", {}],
	["inv", "inv", {"dust": 0, "shard": 0, "crystal": 0}],
	["owned", "owned", {}],
	["equipped", "equipped", {}],
	["gacha", "gacha", {"pity_sr": 0, "pity_ssr": 0, "half_day": "", "pulls": 0}],
	["streak", "streak", {"last": "", "count": 0, "best": 0, "guards": 1, "log": [], "popup": ""}],
	["main_rw", "main_rw", {"slots": {}, "types": {}, "star3": {}, "chests": {}, "tower_day": {}}],
	["world10", "world10", {}],
	["world11", "world11", {}],
	["house", "house", {}],
	["tut", "tut", {}],
	["grade_pick", "grade_pick", ""],
]


## 這幾個欄位讀進來之後由 _load_quests() 再整理一次
const _NORMALIZED := ["quests", "inv", "main_rw", "owned", "equipped", "streak", "gacha"]


func save_review() -> void:
	var data := {"version": SAVE_VERSION, "unit": cur_unit, "units": _per_unit}
	for f in SAVE_FIELDS:
		data[f[1]] = get(f[0])
	var f := FileAccess.open(REVIEW_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


## 舊版存檔 → 目前的版本（一版一版往上升）
static func _migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 1))
	while v < SAVE_VERSION:
		match v:
			1:
				pass      # 1 → 2：格式沒變，只是開始記版本號
		v += 1
	data["version"] = v
	return data


static func _same_type(value, default) -> bool:
	if default is Dictionary:
		return value is Dictionary
	if default is Array:
		return value is Array
	if default is String:
		return value is String
	return typeof(value) in [TYPE_INT, TYPE_FLOAT]


func _load_review() -> void:
	if FileAccess.file_exists(REVIEW_PATH):
		var data = JSON.parse_string(FileAccess.open(REVIEW_PATH, FileAccess.READ).get_as_text())
		if data is Dictionary:
			var old_v := int(data.get("version", 1))
			if old_v < SAVE_VERSION:
				# 升級前留一份備份（review.json.v1.bak），升級出問題還救得回來
				var bak := FileAccess.open(REVIEW_PATH + ".v%d.bak" % old_v, FileAccess.WRITE)
				if bak:
					bak.store_string(JSON.stringify(data))
			data = _migrate(data)
			for f in SAVE_FIELDS:
				if f[0] in _NORMALIZED:
					continue
				var val = data.get(f[1], null)
				set(f[0], val if val != null and _same_type(val, f[2]) else (f[2].duplicate(true) if f[2] is Dictionary or f[2] is Array else f[2]))
			_load_units(data)
			_load_quests(data)
			for d in [mistakes, fixed]:
				for k in d:
					d[k] = int(d[k])
			if old_v < SAVE_VERSION:
				save_review()
			return
	# 第一次：把舊版錯題本（progress.json）的紀錄搬過來
	if FileAccess.file_exists("user://progress.json"):
		var old = JSON.parse_string(FileAccess.open("user://progress.json", FileAccess.READ).get_as_text())
		if old is Dictionary:
			for k in old.get("mistake_book", {}):
				mistakes[k] = int(old.mistake_book[k])


func mark_story(key: String) -> void:
	if not story_seen.has(key):
		story_seen.append(key)
		save_review()


# ================= 每日任務 =================

const DQ := preload("daily_quests.gd")


## 讀取各單元的資料；舊存檔（還沒有單元的版本）的今日修煉、終焉之塔紀錄搬到「指數與對數」
func _load_units(data: Dictionary) -> void:
	_per_unit = {}
	var u = data.get("units", null)
	if u is Dictionary:
		for k in u:
			var d: Dictionary = u[k]
			_per_unit[String(k)] = {"daily": d.get("daily", {}), "tower_best": int(d.get("tower_best", 0)),
				"tower_runs": int(d.get("tower_runs", 0)), "map_sel": int(d.get("map_sel", -1))}
	else:
		_per_unit["exp"] = {"daily": data.get("daily", {}), "tower_best": int(data.get("tower_best", 0)),
			"tower_runs": int(data.get("tower_runs", 0)), "map_sel": -1}
	cur_unit = String(data.get("unit", "exp"))
	var cu: Dictionary = preload("units.gd").unit(cur_unit)
	if not (bool(cu.open) or (bool(cu.get("preview", false)) and dev_unlock_all)):
		cur_unit = "exp"
	for k in _per_unit:
		var dl: Dictionary = _per_unit[k].daily
		for it in dl.get("items", []):
			it["vi"] = int(it.vi)
		if dl.has("results"):
			dl["results"] = Array(dl.get("results", [])).map(func(v): return int(v))


## 切換單元（選單元畫面用）
func set_unit(uid: String) -> void:
	if cur_unit != uid:
		cur_unit = uid
		save_review()


func _load_quests(data: Dictionary) -> void:
	var q = data.get("quests", {})
	if q is Dictionary and q.has("day"):
		var prog := {}
		for k in q.get("prog", {}):
			prog[k] = int(q.prog[k])
		quests = {"day": String(q.day), "prog": prog, "got": Array(q.get("got", [])).map(func(v): return String(v)),
			"tiers": Array(q.get("tiers", [])).map(func(v): return int(v)), "ch": String(q.get("ch", "perfect"))}
	var iv = data.get("inv", {})
	if iv is Dictionary:
		for k in inv:
			inv[k] = int(iv.get(k, 0))
	var mr = data.get("main_rw", {})
	if mr is Dictionary:
		for k in main_rw:
			if mr.get(k) is Dictionary:
				main_rw[k] = mr[k]
	var ow = data.get("owned", {})
	if ow is Dictionary:
		for k in ow:
			if not COS.item(String(k)).is_empty():
				owned[String(k)] = int(ow[k])
	var eqd = data.get("equipped", {})
	if eqd is Dictionary:
		for k in eqd:
			if owned.has(String(eqd[k])):
				equipped[String(k)] = String(eqd[k])
	var st = data.get("streak", {})
	if st is Dictionary and st.has("count"):
		streak = {"last": String(st.get("last", "")), "count": int(st.get("count", 0)), "best": int(st.get("best", 0)),
			"guards": int(st.get("guards", 1)), "log": Array(st.get("log", [])), "popup": String(st.get("popup", ""))}
	var ga = data.get("gacha", {})
	if ga is Dictionary:
		gacha = {"pity_sr": int(ga.get("pity_sr", 0)), "pity_ssr": int(ga.get("pity_ssr", 0)),
			"half_day": String(ga.get("half_day", "")), "pulls": int(ga.get("pulls", 0))}


# ================= 光靈扭蛋 =================

const COS := preload("cosmetics.gd")
