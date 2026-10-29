extends Node
## 遊戲管家：設定、音樂、音效、換場景、星數紀錄。
## 不需要設定 Autoload：任何腳本呼叫 Game.of(self) 時，會自動建立並掛在場景樹的根節點上，
## 換場景也不會消失（背景音樂因此能不中斷地播放）。
##
##   const Game := preload("game.gd")
##   Game.of(self).sfx("correct")
##   Game.of(self).goto("main_menu.gd", {"page": "levels"})
##
## 背景音樂由程式生成（水晶音色的琶音 + 柔和和弦墊底），第一次啟動時生成，之後讀取快取。

const _SELF := preload("game.gd")
const SETTINGS_PATH := "user://settings.cfg"
const STARS_PATH := "user://stars.cfg"
const CLEARED_PATH := "user://cleared.cfg"
const REVIEW_PATH := "user://review.json"
const BGM_CACHE := "user://crystal_bgm_v2.res"   # v2：結尾補了防越界的波形
const BGM_BAKED := "res://audio/crystal_bgm.res"
const SR := 22050
const D5 := 587.33
const PENTA := [0, 2, 4, 7, 9]        # D 大調五聲音階（相對 D 的半音數）

static var _inst: Node = null

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
var _changing := false
var _last_tick := 0
var _duck_tween: Tween


## 取得（必要時建立）唯一的遊戲管家
static func of(n: Node):   # 不標回傳型別，方便直接呼叫 sfx() 等方法
	if is_instance_valid(_inst):
		return _inst
	var root := n.get_tree().root
	var g: Node = root.get_node_or_null("Game")
	if g == null:
		g = _SELF.new()
		g.name = "Game"
		root.add_child.call_deferred(g)
	_inst = g
	return g


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_load_stars()
	_load_cleared()
	_load_review()
	_ensure_buses()
	_apply_audio()
	_build_sounds()
	_bgm = AudioStreamPlayer.new()
	_bgm.bus = "Music"
	add_child(_bgm)
	notifier = preload("notifier.gd").new()
	add_child(notifier)
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.04, 0.09, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


func _ready() -> void:
	get_tree().set_quit_on_go_back(false)   # 手機的「返回鍵」交給各畫面自己處理
	if OS.has_feature("mobile"):
		# 手機常是 90／120 Hz 螢幕：鎖在 60 幀，節奏穩定不忽快忽慢，也比較不會發熱降頻
		Engine.max_fps = FPS_ACTIVE
		# 3D 物理用不到：降低物理更新頻率，省一點運算
		Engine.physics_ticks_per_second = 30
	wake()
	set_fps_display(show_fps)
	if res_index != 1:          # 沒改過解析度就照專案設定，不去動視窗
		apply_resolution.call_deferred()
	_hook_tree(get_tree().root)
	get_tree().node_added.connect(_hook)
	_start_bgm()


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
	mistakes = {}
	fixed = {}
	last_wrong = {}
	_per_unit = {}
	cur_unit = "exp"
	review_days = []
	session = {}
	story_seen = []
	quests = {}
	inv = {"dust": 0, "shard": 0, "crystal": 0}
	main_rw = {"slots": {}, "types": {}, "star3": {}, "chests": {}, "tower_day": {}}
	owned = {}
	equipped = {}
	streak = {"last": "", "count": 0, "best": 0, "guards": 1, "log": [], "popup": ""}
	gacha = {"pity_sr": 0, "pity_ssr": 0, "half_day": "", "pulls": 0}

	for path in [STARS_PATH, CLEARED_PATH, REVIEW_PATH, "user://progress.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# 寫一份空的錯題本，避免下次啟動又從舊版 progress.json 搬資料
	save_review()

func set_volume(kind: String, v: float) -> void:
	match kind:
		"master":
			master_vol = v
		"music":
			music_vol = v
		"sfx":
			sfx_vol = v
	_apply_audio()


# ---------- 幀數顯示（開發者功能） ----------

var _fps_label: Label
var _fps_t := 0.0
var _fps_frames := 0
var _fps_worst := 0.0


func set_fps_display(on: bool) -> void:
	show_fps = on
	if on and _fps_label == null:
		var layer := CanvasLayer.new()
		layer.layer = 101
		add_child(layer)
		_fps_label = Label.new()
		_fps_label.position = Vector2(8, 4)
		_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fps_label.add_theme_font_size_override("font_size", 16)
		_fps_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
		_fps_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		_fps_label.add_theme_constant_override("outline_size", 4)
		layer.add_child(_fps_label)
	if _fps_label:
		_fps_label.visible = on
	set_process(true)        # 一直要跑：省電模式要判斷閒置


func _process(delta: float) -> void:
	# 省電：一陣子沒操作、也沒有播特效音效，就降到 30 幀
	if power_save and Engine.max_fps != FPS_IDLE and Time.get_ticks_msec() > _active_until:
		Engine.max_fps = FPS_IDLE
	if _fps_label == null or not _fps_label.visible:
		return
	_fps_t += delta
	_fps_frames += 1
	_fps_worst = maxf(_fps_worst, delta)
	if _fps_t >= 0.5:
		var fps := _fps_frames / _fps_t
		_fps_label.text = "%d fps　最慢一幀 %d ms　繪圖 %d 次" % [roundi(fps), roundi(_fps_worst * 1000.0),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))]
		_fps_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7) if fps >= 50.0 else (Color(1, 0.85, 0.4) if fps >= 30.0 else Color(1, 0.45, 0.5)))
		_fps_t = 0.0
		_fps_frames = 0
		_fps_worst = 0.0


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


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")
			# 一點殘響讓水晶音色更有空間感（手機上音效不加殘響，省一點運算）
			if bus_name == "SFX" and OS.has_feature("mobile"):
				continue
			var rv := AudioEffectReverb.new()
			rv.room_size = 0.8 if bus_name == "Music" else 0.55
			rv.damping = 0.35
			rv.spread = 1.0
			rv.wet = 0.3 if bus_name == "Music" else 0.16
			rv.dry = 0.9
			AudioServer.add_bus_effect(i, rv)


func _apply_audio() -> void:
	for pair in [["Master", master_vol], ["Music", music_vol], ["SFX", sfx_vol]]:
		var i := AudioServer.get_bus_index(pair[0])
		if i == -1:
			continue
		var v: float = pair[1]
		AudioServer.set_bus_mute(i, v <= 0.001)
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))


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


# ================= 旅程完成度 =================

## 記下「這段旅程的第 vi 種題型答對過了」；第一次答對時回傳 true
# ================= 主線獎勵 =================
## 每段旅程（題目列表裡的一題）第一次通過給星塵；之後每答對一種新題型、第一次三顆星再加一點。
## 一章的旅程全部通過：章節大寶箱（每章只能開一次）。重玩同一題不會再給，免得刷星塵。
const RW_FIRST := 20          # 第一次通過一段旅程
const RW_FIRST_BOSS := 40     # 限時的試煉關
const RW_TYPE := 5            # 之後每答對一種新題型
const RW_STAR3 := 10          # 第一次拿到三顆星
const CHEST := {"dust": 150, "shard": 20, "crystal": 1}
const CHEST_FINAL := {"dust": 200, "shard": 40, "crystal": 1}   # 一大關的最後一章
## 終焉之塔：每通過一層給一點星塵；同一天同一層只給一次（今天第一次爬到 5 層給 1～5 層，再爬到 10 層只給 6～10 層）
const TOWER_DUST := 3         # 每一層
const TOWER_DUST_BONUS := 5   # 每第 5 層再多給


## 這一層值多少星塵
static func tower_floor_dust(f: int) -> int:
	return TOWER_DUST + (TOWER_DUST_BONUS if f % 5 == 0 else 0)


## 今天（目前單元）已經領過幾層
func tower_paid_today() -> int:
	var td: Dictionary = main_rw.get("tower_day", {})
	if String(td.get("day", "")) != DQ.day_key():
		return 0
	return int(td.get("max", {}).get(cur_unit, 0))


## 攀登結束：發放今天還沒領過的那幾層的星塵，回傳 {"dust", "from", "to"}
func tower_reward(floors: int) -> Dictionary:
	var day := DQ.day_key()
	var td: Dictionary = main_rw.get("tower_day", {})
	if String(td.get("day", "")) != day:
		td = {"day": day, "max": {}}
	var paid := int(td.max.get(cur_unit, 0))
	var got := 0
	for f in range(paid + 1, floors + 1):
		got += tower_floor_dust(f)
	if floors > paid:
		td.max[cur_unit] = floors
	main_rw["tower_day"] = td
	if got > 0:
		inv.dust = int(inv.dust) + got
	return {"dust": got, "from": paid + 1, "to": floors, "paid": paid}


## 通過一段旅程的獎勵：回傳 {"dust": 總數, "lines": ["第一次通過 +30", …]}，已經加進持有物品
func journey_reward(key: String, vi: int, stars: int, boss: bool) -> Dictionary:
	var got := 0
	var lines := []
	var tk := "%s#%d" % [key, vi]
	if not main_rw.slots.has(key):
		main_rw.slots[key] = true
		var n := RW_FIRST_BOSS if boss else RW_FIRST
		got += n
		lines.append("第一次通過 +%d" % n)
	elif not main_rw.types.has(tk):
		got += RW_TYPE
		lines.append("新題型 +%d" % RW_TYPE)
	main_rw.types[tk] = true
	if stars >= 3 and not main_rw.star3.has(key):
		main_rw.star3[key] = true
		got += RW_STAR3
		lines.append("第一次三顆星 +%d" % RW_STAR3)
	if got > 0:
		inv.dust = int(inv.dust) + got
		save_review()
	return {"dust": got, "lines": lines}


func chest_claimed(ckey: String) -> bool:
	return main_rw.chests.has(ckey)


## 打開章節寶箱（ckey 例如 "L1_c1"）：回傳拿到的東西，已經開過就回傳 {}
func claim_chest(ckey: String, final: bool) -> Dictionary:
	if main_rw.chests.has(ckey):
		return {}
	main_rw.chests[ckey] = true
	var got: Dictionary = (CHEST_FINAL if final else CHEST).duplicate()
	for k in got:
		inv[k] = int(inv.get(k, 0)) + int(got[k])
	save_review()
	return got


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


func save_review() -> void:
	var f := FileAccess.open(REVIEW_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"mistakes": mistakes, "fixed": fixed, "last_wrong": last_wrong,
			"days": review_days, "story": story_seen, "unit": cur_unit, "units": _per_unit, "quests": quests, "inv": inv,
			"owned": owned, "equipped": equipped, "gacha": gacha, "streak": streak, "main_rw": main_rw}))


func _load_review() -> void:
	if FileAccess.file_exists(REVIEW_PATH):
		var data = JSON.parse_string(FileAccess.open(REVIEW_PATH, FileAccess.READ).get_as_text())
		if data is Dictionary:
			mistakes = data.get("mistakes", {})
			fixed = data.get("fixed", {})
			last_wrong = data.get("last_wrong", {})
			_load_units(data)
			review_days = data.get("days", [])
			story_seen = data.get("story", [])

			_load_quests(data)
			for d in [mistakes, fixed]:
				for k in d:
					d[k] = int(d[k])

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
## 版本號（主畫面右下角會顯示）：每次交給你新的檔案時更新，方便確認手機上裝的是不是最新版
const BUILD := "2026.10.29-e"


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


## 今天的任務狀態（換日就重新開始；打開遊戲就算登入）
func quest_state() -> Dictionary:
	var day := DQ.day_key()
	if String(quests.get("day", "")) != day:
		quests = {"day": day, "prog": {"login": 1}, "got": [], "tiers": [], "ch": DQ.challenge_today()}
		save_review()
	return quests


## 今天五個任務的完整資料：再加上 have（目前進度）、done（完成）、got（已領）
func quest_list() -> Array:
	var q := quest_state()
	var out := []
	for d in DQ.defs(q.ch):
		var it: Dictionary = d.duplicate()
		it["have"] = mini(int(q.prog.get(d.key, 0)), int(d.need))
		it["done"] = int(it.have) >= int(d.need)
		it["got"] = q.got.has(d.id)
		out.append(it)
	return out


func quest_done_count() -> int:
	var n := 0
	for it in quest_list():
		if it.done:
			n += 1
	return n


## 遊戲裡發生的事，更新任務進度
##   "correct"：答對（過關）一題，data = {stars, review（修煉之間）, timed（限時題）}
##   "tower_floor"：終焉之塔通過一層，data = {floor}
##   "daily_done"：做完今日修煉
func quest_event(kind: String, data: Dictionary = {}) -> void:
	var q := quest_state()
	var p: Dictionary = q.prog
	match kind:
		"correct":
			p["ans"] = int(p.get("ans", 0)) + 1
			if data.get("review", false):
				p["weak"] = int(p.get("weak", 0)) + 1
			if q.ch == "perfect" and int(data.get("stars", 0)) >= 3:
				p["ch"] = 1
			if q.ch == "timed" and data.get("timed", false):
				p["ch"] = 1
		"tower_floor":
			if q.ch == "tower3":
				p["ch"] = maxi(int(p.get("ch", 0)), int(data.get("floor", 0)))
		"daily_done":
			if q.ch == "daily":
				p["ch"] = 1
	save_review()


## 領一個任務的星塵；回傳領到多少（不能領回傳 0）
func quest_claim(id: String) -> int:
	for it in quest_list():
		if it.id == id and it.done and not it.got:
			quests.got.append(id)
			inv.dust = int(inv.dust) + int(it.dust)
			save_review()
			return int(it.dust)
	return 0


## 已經領過獎勵的任務數（區間獎勵的進度條看這個：完成「並領取」才前進）
func quest_got_count() -> int:
	return quest_state().got.size()


## 一次領完所有完成、還沒領的任務；回傳總共領到多少星塵
func quest_claim_all() -> int:
	var total := 0
	for it in quest_list():
		if it.done and not it.got:
			quests.got.append(it.id)
			total += int(it.dust)
	if total > 0:
		inv.dust = int(inv.dust) + total
		save_review()
	return total


## 一次領完所有可以領的區間獎勵；回傳 [拿到的物品合計, 領了哪幾個 n]
func quest_claim_tiers_all() -> Array:
	var sum := {}
	var ns := []
	for t in DQ.TIERS:
		var n := int(t.n)
		if quest_tier_ready(n):
			var got := quest_claim_tier(n)
			ns.append(n)
			for k in got:
				sum[k] = int(sum.get(k, 0)) + int(got[k])
	return [sum, ns]


## 區間獎勵能不能領（要先把任務獎勵領走，進度才算）
func quest_tier_ready(n: int) -> bool:
	return quest_got_count() >= n and not quest_state().tiers.has(n)


## 領區間獎勵；回傳拿到的物品 {dust, shard, crystal}
func quest_claim_tier(n: int) -> Dictionary:
	if not quest_tier_ready(n):
		return {}
	var got := {}
	for t in DQ.TIERS:
		if int(t.n) == n:
			match String(t.kind):
				"dust":
					got = {"dust": int(t.amt)}
				"chest":
					got = DQ.roll_chest()
				"crystal":
					got = {"crystal": int(t.amt)}
	for k in got:
		inv[k] = int(inv.get(k, 0)) + int(got[k])
	quests.tiers.append(n)
	save_review()
	return got


## 有沒有可以領的東西（入口按鈕上的紅色驚嘆號）
func quest_badge() -> bool:
	if String(streak.last) != DQ.day_key():
		return true          # 今天還沒簽到
	for it in quest_list():
		if it.done and not it.got:
			return true
	for t in DQ.TIERS:
		if quest_tier_ready(int(t.n)):
			return true
	return false


# ================= 光靈扭蛋 =================

const COS := preload("cosmetics.gd")


## kind："one" 單抽、"ten" 十連、"shine" 閃光抽。回傳 {res: "dust"/"crystal", amt}
func gacha_cost(kind: String) -> Dictionary:
	match kind:
		"ten":
			return {"res": "dust", "amt": COS.COST_TEN}
		"shine":
			return {"res": "crystal", "amt": COS.COST_SHINE}
	return {"res": "dust", "amt": COS.COST_ONE / 2 if gacha_half_ready() else COS.COST_ONE}


## 今天的首抽半價還沒用
func gacha_half_ready() -> bool:
	return String(gacha.get("half_day", "")) != DQ.day_key()


func gacha_can(kind: String) -> bool:
	var c := gacha_cost(kind)
	return int(inv.get(c.res, 0)) >= int(c.amt)


## 抽！回傳每一抽的結果 [{id, r, new, shards}]；資源不夠回傳 []
func gacha_pull(kind: String) -> Array:
	if not gacha_can(kind):
		return []
	var c := gacha_cost(kind)
	inv[c.res] = int(inv[c.res]) - int(c.amt)
	if kind == "one" and gacha_half_ready():
		gacha.half_day = DQ.day_key()
	var n := 10 if kind == "ten" else 1
	var out := []
	var best := 0
	for i in n:
		gacha.pity_sr = int(gacha.pity_sr) + 1
		gacha.pity_ssr = int(gacha.pity_ssr) + 1
		gacha.pulls = int(gacha.pulls) + 1
		var min_r := 2 if kind == "shine" else 0
		if int(gacha.pity_ssr) >= COS.PITY_SSR:
			min_r = 3
		elif int(gacha.pity_sr) >= COS.PITY_SR:
			min_r = maxi(min_r, 2)
		if kind == "ten" and i == n - 1 and best == 0:
			min_r = maxi(min_r, 1)            # 十連保證至少一個稀有
		var r := COS.roll_rarity(min_r)
		best = maxi(best, r)
		if r >= 2:
			gacha.pity_sr = 0
		if r >= 3:
			gacha.pity_ssr = 0
		var it: Dictionary = COS.pick_of_rarity(r)
		var is_new := not owned.has(it.id)
		owned[it.id] = int(owned.get(it.id, 0)) + 1
		var sh := 0
		if not is_new:
			sh = int(COS.RARITY[r].shards)       # 重複的變成光之碎片
			inv.shard = int(inv.shard) + sh
		out.append({"id": it.id, "r": r, "new": is_new, "shards": sh})
	save_review()
	return out


## 穿上（同一類只能穿一件）；id 已經穿著就脫下
func toggle_equip(id: String) -> void:
	var it := COS.item(id)
	if it.is_empty() or not owned.has(id):
		return
	if equipped.get(it.cat, "") == id:
		equipped.erase(it.cat)
	else:
		equipped[it.cat] = id
	save_review()


func equip(id: String) -> void:
	var it := COS.item(id)
	if not it.is_empty() and owned.has(id):
		equipped[it.cat] = id
		save_review()


# ================= 連續簽到 =================
## 每天（早上 5 點換日）可以簽到一次；14 天一輪，第 3、7、14 天有大獎。
## 光靈的守護：漏簽的日子自動補上（最多存 2 個，每連續簽到 7 天多一個）；守護不夠時連續天數保留一半，不會歸零。

const STREAK_CYCLE := 14
const GUARD_MAX := 2

## 一輪 14 天的獎勵
static func streak_reward(pos: int, first_scarf: bool) -> Dictionary:
	match pos:
		3:
			return {"dust": 100}
		7:
			return {"dust": 100, "crystal": 1}
		14:
			return {"item": "streak_scarf"} if first_scarf else {"crystal": 2, "shard": 50}
	return {"dust": 40 if pos > 7 else 30}


static func _day_n(key: String) -> int:
	if key == "":
		return -1
	return int(Time.get_unix_time_from_datetime_string(key + "T12:00:00") / 86400)


## 今天簽到的狀況：{can（今天還沒簽）, missed（中間漏了幾天）, guards_used, halved, next（簽完是第幾天）, pos（這一輪第幾天）}
func streak_preview() -> Dictionary:
	var today := DQ.day_key()
	var can := String(streak.last) != today
	var missed := 0
	if can and String(streak.last) != "":
		missed = maxi(0, _day_n(today) - _day_n(String(streak.last)) - 1)
	var cnt := int(streak.count)
	var used := 0
	var halved := false
	if missed > 0:
		if int(streak.guards) >= missed:
			used = missed
		else:
			halved = true
			cnt = cnt / 2
	var nxt := cnt + 1 if can else cnt
	var pos := (nxt - 1) % STREAK_CYCLE + 1 if nxt > 0 else 0
	return {"can": can, "missed": missed, "guards_used": used, "halved": halved, "next": nxt, "pos": pos}


## 簽到！回傳 {reward, guards_used, halved, count, new_guard}；今天簽過了回傳 {}
func streak_claim() -> Dictionary:
	var pv := streak_preview()
	if not pv.can:
		return {}
	var today := DQ.day_key()
	var log: Array = streak.log
	if pv.guards_used > 0:
		streak.guards = int(streak.guards) - int(pv.guards_used)
		for k in int(pv.guards_used):
			log.append({"n": _day_n(today) - int(pv.missed) + k, "kind": "guard"})
	streak.count = int(pv.next)
	streak.best = maxi(int(streak.best), int(streak.count))
	streak.last = today
	log.append({"n": _day_n(today), "kind": "in"})
	while log.size() > 30:
		log.pop_front()
	var new_guard := false
	if int(streak.count) % 7 == 0 and int(streak.guards) < GUARD_MAX:
		streak.guards = int(streak.guards) + 1
		new_guard = true
	var rw := streak_reward(int(pv.pos), not owned.has("streak_scarf"))
	for k in ["dust", "shard", "crystal"]:
		if rw.has(k):
			inv[k] = int(inv[k]) + int(rw[k])
	if rw.has("item"):
		owned[String(rw.item)] = 1
	save_review()
	return {"reward": rw, "guards_used": pv.guards_used, "halved": pv.halved, "count": streak.count, "new_guard": new_guard}


## 今天第一次打開：要不要自動跳出簽到（跳過一次就不再跳）
func streak_should_popup() -> bool:
	var today := DQ.day_key()
	if String(streak.last) == today or String(streak.popup) == today:
		return false
	streak.popup = today
	save_review()
	return true


## 碎片兌換所：用光之碎片指定換一件還沒有的裝扮
func exchange_cost(id: String) -> int:
	var it := COS.item(id)
	return int(COS.EXCHANGE[int(it.r)]) if not it.is_empty() else 0


func exchange(id: String) -> bool:
	var it := COS.item(id)
	if it.is_empty() or owned.has(id) or int(inv.shard) < exchange_cost(id):
		return false
	inv.shard = int(inv.shard) - exchange_cost(id)
	owned[id] = 1
	save_review()
	return true


func unequip_all() -> void:
	equipped = {}
	save_review()


## 今天的修煉題（換日就重新出題）
func daily_items(center) -> Array:
	# 今天的題目裡有已經刪掉的旅程（例如舊版的「列表作圖」）：重新出題
	var stale := false
	for it in daily.get("items", []):
		if it is Dictionary and not center.slot_exists(String(it.get("level", "")), String(it.get("slot", ""))):
			stale = true
	if daily.get("date", "") != today() or stale:
		var items: Array = center.make_daily(self)
		var res := []
		res.resize(items.size())
		res.fill(-1)
		daily = {"date": today(), "items": items, "results": res}
		save_review()
	return daily.items


func daily_done() -> bool:
	return daily.get("date", "") == today() and not daily.get("items", []).is_empty() \
		and not daily.get("results", []).has(-1)


## 開始一場修煉。kind = "daily"（今日修煉，可以從中斷的地方繼續）或 "free"（自由練習）
func start_session(kind: String, items: Array) -> void:
	if items.is_empty():
		return
	var start := 0
	if kind == "daily":
		var res: Array = daily.get("results", [])
		start = maxi(0, res.find(-1))
	session = {"kind": kind, "items": items, "i": start, "results": []}
	_launch_session_item()


func _launch_session_item() -> void:
	var it: Dictionary = session.items[session.i]
	var center = load(get_script().resource_path.get_base_dir() + "/review_center.gd")
	var info: Dictionary = center.level_info(it.level)
	goto(info.file, {"review": it, "review_i": session.i, "review_n": session.items.size(), "review_kind": session.kind})


## 關卡回報這一題的結果（stars = 0 表示看示範過關）
func session_report(stars: int) -> void:
	if session.is_empty():
		return
	var it: Dictionary = session.items[session.i]
	session.results.append({"tag": it.tag, "stars": stars, "title": it.get("title", ""), "level": it.level})
	if stars > 0:
		credit(it.tag, 2 if stars >= 3 else 1)
		mark_cleared(it.level + "/" + it.slot, int(it.vi))
	if session.kind == "daily" and daily.get("date", "") == today():
		daily.results[session.i] = stars
		if not daily.results.has(-1) and not review_days.has(today()):
			review_days.append(today())
		if not daily.results.has(-1):
			quest_event("daily_done")
		save_review()
	session.i += 1
	if session.i < session.items.size():
		_launch_session_item()
	else:
		var summary: Array = session.results
		var kind: String = session.kind
		if kind == "daily" and daily.get("date", "") == today():
			# 今日修煉可能分好幾次做完：結算時列出今天全部的題目
			summary = []
			for k in daily.items.size():
				var di: Dictionary = daily.items[k]
				summary.append({"tag": di.tag, "stars": maxi(0, int(daily.results[k])), "title": di.get("title", ""), "level": di.level})
		session = {}
		goto("main_menu.gd", {"page": "review", "summary": summary, "summary_kind": kind})


# ---------- 終焉之塔 ----------

const TOWER_HEARTS := 3


## 開始攀登：從第 1 層、三顆心開始
func start_tower() -> void:
	session = {"kind": "tower", "floor": 1, "hearts": TOWER_HEARTS, "history": []}
	_launch_tower_floor()


func _launch_tower_floor() -> void:
	var center = load(get_script().resource_path.get_base_dir() + "/review_center.gd")
	var f: int = session.floor
	var it: Dictionary = center.tower_pick(f, session.history, cur_unit)
	session["cur"] = it
	var info: Dictionary = center.level_info(it.level)
	goto(info.file, {"review": it, "review_kind": "tower", "review_i": f - 1, "review_n": f,
		"tower_floor": f, "tower_hearts": int(session.hearts),
		"tower_time": center.tower_time(f) * float(it.get("tmul", 1.0))})


## 關卡回報這一層的結果：hearts = 剩下幾顆心
func tower_report(stars: int, hearts: int) -> void:
	if session.get("kind", "") != "tower":
		return
	var it: Dictionary = session.cur
	session.history.append({"level": it.level, "slot": it.slot, "title": it.title, "stars": stars, "floor": session.floor,
		"type": it.get("type", "")})
	session.hearts = hearts
	if stars > 0 and it.level != "T":
		mark_cleared(it.level + "/" + it.slot, int(it.vi))
	var center = load(get_script().resource_path.get_base_dir() + "/review_center.gd")
	if hearts > 0:
		quest_event("tower_floor", {"floor": int(session.floor)})
	if hearts > 0 and int(session.floor) >= int(center.tower_top()):
		_tower_end(int(session.floor), true)       # 登頂！
	elif hearts > 0:
		session.floor += 1
		# 先播「往上爬一層」的小動畫（tower_climb.gd），播完再進下一層
		goto("tower_climb.gd", {"from": int(session.floor) - 1, "to": int(session.floor), "stars": stars,
			"hearts": hearts, "best": tower_best})
	else:
		_tower_end(int(session.floor) - 1)


## 爬塔動畫播完：進入下一層
func tower_continue() -> void:
	if session.get("kind", "") == "tower":
		_launch_tower_floor()


## 放棄攀登（暫停選單）：目前這一層不算
func tower_abort() -> void:
	if session.get("kind", "") != "tower":
		session_abort()
		return
	_tower_end(int(session.floor) - 1)


func _tower_end(floors: int, summit := false) -> void:
	var record := floors > tower_best
	tower_best = maxi(tower_best, floors)
	tower_runs += 1
	var rw := tower_reward(floors)
	save_review()
	var res := {"floors": floors, "record": record, "history": session.history, "summit": summit, "reward": rw}
	session = {}
	goto("main_menu.gd", {"page": "tower", "tower_result": res})


func session_abort() -> void:
	session = {}
	goto("main_menu.gd", {"page": "review"})


# ================= 換場景 =================

## 切換到同資料夾裡的某個腳本（自動建立場景），附帶淡出淡入
func goto(script_file: String, with_args: Dictionary = {}) -> void:
	wake(3000)          # 換畫面的淡入淡出、開場動畫
	if _changing:
		return
	_changing = true
	args = with_args
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.22)
	await tw.finished
	get_tree().paused = false
	duck(false)
	var script: Script = load(get_script().resource_path.get_base_dir() + "/" + script_file)
	var node := Control.new()
	node.set_script(script)
	var ps := PackedScene.new()
	ps.pack(node)
	node.free()
	get_tree().change_scene_to_packed(ps)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.3)
	await tw2.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_changing = false


## 下一個場景取用參數（取一次就清空）
func take_args() -> Dictionary:
	var a := args
	args = {}
	return a


# ================= 音效 =================

static func semi(s: float) -> float:
	return pow(2.0, s / 12.0)


## 五聲音階第 i 個音（相對 D5 的半音數）
static func scale_semi(i: int) -> int:
	return 12 * int(floor(i / 5.0)) + PENTA[posmod(i, 5)]


func play(snd: String, pitch: float = 1.0, db: float = 0.0, delay: float = 0.0) -> void:
	if not is_inside_tree() or not _snd.has(snd):
		return
	if delay > 0.0:
		get_tree().create_timer(delay, true).timeout.connect(play.bind(snd, pitch, db, 0.0))
		return
	var p: AudioStreamPlayer = _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	p.stream = _snd[snd]
	p.pitch_scale = pitch
	p.volume_db = db
	p.play()


## 常用音效。i 為額外參數（例如第幾顆寶石，音會越來越高）
## 有操作或動畫：保持 60 幀一段時間（ms 毫秒）
func wake(ms: int = IDLE_AFTER_MS) -> void:
	_active_until = maxi(_active_until, Time.get_ticks_msec() + ms)
	if Engine.max_fps != FPS_ACTIVE:
		Engine.max_fps = FPS_ACTIVE


func set_power_save(on: bool) -> void:
	power_save = on
	wake()
	save_settings()


## 碰螢幕、滑鼠、鍵盤：回到 60 幀
func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or e is InputEventScreenDrag or e is InputEventMouseButton or e is InputEventKey \
			or (e is InputEventMouseMotion and e.button_mask != 0):
		wake()


func sfx(kind: String, i: int = 0) -> void:
	# 有音效通常也有動畫（答對、過關、開寶箱…）：動畫播完之前維持 60 幀
	wake(2200)
	match kind:
		"click":
			play("blip", 1.0, -9.0)
		"tick":
			var now := Time.get_ticks_msec()
			if now - _last_tick < 45:
				return
			_last_tick = now
			play("blip", 1.5 + 0.08 * i, -17.0)
		"open":
			play("bell", semi(-5), -15.0)
			play("bell", semi(2), -17.0, 0.05)
		"correct":
			play("bell", semi(7), -5.0)
			play("bell", semi(12), -3.0, 0.08)
		"wrong":
			play("bonk", 1.0, -4.0)
		"gem":
			play("bell", semi(scale_semi(5 + i)), -4.0)
		"fall":
			play("fall", 1.0, -7.0)
		"hole":
			play("fall", 0.75, -6.0)
		"ping":
			play("bell", semi(12), -3.0)
			play("bell", semi(0), -9.0)
		"lamp":
			play("bell", semi(scale_semi(4 + i)), -6.0)
		"count":
			play("bell", semi(scale_semi(2 + 2 * i)), -12.0)
		"success":
			for k in 5:
				play("bell", semi(scale_semi(k + 3)), -6.0 + k, 0.065 * k)
		"fanfare":
			var seq := [0, 2, 4, 5, 7, 10]
			for k in seq.size():
				play("bell", semi(scale_semi(seq[k])), -5.0, 0.11 * k)
			play("bell", semi(-12), -8.0, 0.66)
			play("bell", semi(scale_semi(10)), -2.0, 0.66)


## 光靈奔跑時的音：t 為 0（畫面底部）～1（畫面頂端），對應五聲音階
func note(t: float, db: float = -14.0) -> void:
	var idx := clampi(roundi(clampf(t, 0.0, 1.0) * 14.0), 0, 14)
	play("bell", semi(scale_semi(idx) - 12), db)


# ================= 背景音樂 =================

## 暫停時把音樂壓小
func duck(on: bool) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_bgm, "volume_db", -9.0 if on else 0.0, 0.35)


func _start_bgm() -> void:
	var stream: AudioStreamWAV = null
	# 預先生成好的音樂（res://audio/crystal_bgm.res，用 generate_bgm() 產生）。
	# 手機上即時合成要好幾秒、還會讓畫面卡住，所以直接打包進遊戲。
	if ResourceLoader.exists(BGM_BAKED):
		stream = load(BGM_BAKED) as AudioStreamWAV
	if stream == null and ResourceLoader.exists(BGM_CACHE):
		stream = load(BGM_CACHE) as AudioStreamWAV
	if stream == null:
		stream = await generate_bgm()
		ResourceSaver.save(stream, BGM_CACHE)
	_bgm.stream = stream
	_bgm.volume_db = -40.0
	_bgm.play()
	var tw := create_tween()
	tw.tween_property(_bgm, "volume_db", 0.0, 3.0).set_trans(Tween.TRANS_SINE)


## 水晶音樂：D 大調，72 BPM，四個和弦各兩小節，約 27 秒無縫循環
func generate_bgm() -> AudioStreamWAV:
	var beat := 60.0 / 72.0
	var chord_len := beat * 8.0
	var n := int(chord_len * 4.0 * SR)
	var mix := PackedFloat32Array()
	mix.resize(n)

	# 和弦：arp = 琶音用的五個音、pad = 墊底的三個音（皆為相對 D5 的半音數）
	var chords := [
		{"arp": [0, 4, 7, 11, 14], "pad": [-24, -17, -8]},     # Dmaj9
		{"arp": [-3, 0, 4, 7, 14], "pad": [-27, -20, -12]},    # Bm7(11)
		{"arp": [0, 4, 5, 7, 9], "pad": [-31, -24, -15]},      # Gmaj9
		{"arp": [-5, -1, 2, 7, 9], "pad": [-29, -22, -13]},    # A(add9)
	]
	var patterns := [[0, 2, 1, 3, 2, 4, 3, 1], [4, 3, 1, 2, 0, 2, 3, 1]]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026

	# 1) 琶音：先把會用到的音高各算一次波形，再疊進音軌
	var ref := _bell_wave(D5, 2.2, 1.0)
	var cache := {}
	var work := 0
	for c in 4:
		var ch: Dictionary = chords[c]
		for b in 2:
			var pat: Array = patterns[b]
			for e in 8:
				var s: int = ch.arp[pat[e]]
				if not cache.has(s):
					cache[s] = _resample(ref, semi(s))
				var t := (c * 8 + b * 4) * beat + e * beat / 2.0 + rng.randf_range(-0.006, 0.006)
				var vel := 0.34 if e == 0 else (0.24 if e % 2 == 0 else 0.18)
				vel *= rng.randf_range(0.85, 1.0)
				_add(mix, cache[s], int(t * SR), vel)
				work += cache[s].size()
				if work > 200000:
					work = 0
					await get_tree().process_frame
			# 每兩小節在反拍加一顆高八度的「閃光」
			if b == 1:
				var top: int = ch.arp[4] + 12
				if not cache.has(top):
					cache[top] = _resample(ref, semi(top))
				_add(mix, cache[top], int(((c * 8 + 6) * beat + beat / 2.0) * SR), 0.1)

	# 2) 和弦墊：柔和的正弦，慢慢淡入淡出，接到下一個和弦
	for c in 4:
		for s in chords[c].pad:
			var f := D5 * semi(s)
			var start := int(c * chord_len * SR)
			var length := int((chord_len + 2.2) * SR)
			var att := 1.8 * SR
			var rel := 2.2 * SR
			var w := TAU * f / SR
			for j in length:
				var env := minf(j / att, 1.0) * minf((length - j) / rel, 1.0)
				var ph := w * j
				var v := (sin(ph) + 0.18 * sin(2.0 * ph) + 0.05 * sin(3.0 * ph)) * env * 0.075
				mix[(start + j) % n] += v * (1.0 + 0.15 * sin(TAU * 0.21 * j / SR))
			await get_tree().process_frame

	# 3) 正規化並轉成 16 位元
	var peak := 0.001
	for i in n:
		peak = maxf(peak, absf(mix[i]))
	var g := 0.8 / peak
	for i in n:
		mix[i] *= g
	return to_wav(mix, n)


# ================= 合成工具 =================

static func to_wav(buf: PackedFloat32Array, loop_end: int = 0) -> AudioStreamWAV:
	# 循環音樂：在結尾後面多接一小段開頭的波形（循環點不變）。
	# Godot 播到循環點時會為了內插往後多讀幾個取樣；如果循環點剛好是資料最後一格，
	# 就會讀到緩衝區外面 → Android 上音訊執行緒直接崩潰（約開啟 30 秒時閃退）。
	const LOOP_PAD := 512
	var n := buf.size()
	var total := n + (mini(LOOP_PAD, n) if loop_end > 0 else 0)
	var bytes := PackedByteArray()
	bytes.resize(total * 2)
	for i in total:
		var v: float = buf[i] if i < n else buf[i - n]
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = bytes
	if loop_end > 0:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = loop_end
	return w


## 水晶鐘音色：幾個泛音各自指數衰減
static func _bell_wave(freq: float, dur: float, amp: float) -> PackedFloat32Array:
	var n := int(dur * SR)
	var out := PackedFloat32Array()
	out.resize(n)
	var parts := [[1.0, 1.0, 1.1], [2.0, 0.42, 0.5], [3.0, 0.15, 0.28], [4.16, 0.08, 0.16], [5.43, 0.035, 0.09]]
	for p in parts:
		var w: float = TAU * freq * p[0] / SR
		var k := exp(-1.0 / (float(p[2]) * SR))
		var e: float = p[1] * amp
		for i in n:
			out[i] += e * sin(w * i)
			e *= k
	var att := int(0.004 * SR)
	for i in att:
		out[i] *= float(i) / att
	return out


## 用線性內插把波形升降調
static func _resample(src: PackedFloat32Array, ratio: float) -> PackedFloat32Array:
	var n := int((src.size() - 1) / ratio)
	var out := PackedFloat32Array()
	out.resize(n)
	for j in n:
		var x := j * ratio
		var i0 := int(x)
		var fr := x - i0
		out[j] = src[i0] * (1.0 - fr) + src[i0 + 1] * fr
	return out


## 把 src 疊加到 mix 的 start 位置（超過結尾就繞回開頭，確保無縫循環）
static func _add(mix: PackedFloat32Array, src: PackedFloat32Array, start: int, vel: float) -> void:
	var n := mix.size()
	for j in src.size():
		mix[(start + j) % n] += vel * src[j]


func _build_sounds() -> void:
	_snd["bell"] = to_wav(_bell_wave(D5, 1.8, 0.85))

	# 按鈕：短促柔和的「嘀」
	var n := int(0.07 * SR)
	var blip := PackedFloat32Array()
	blip.resize(n)
	for i in n:
		var e := exp(-i / (0.014 * SR))
		blip[i] = (sin(TAU * 1500.0 * i / SR) + 0.3 * sin(TAU * 3000.0 * i / SR)) * e * 0.55
	_snd["blip"] = to_wav(blip)

	# 答錯：往下滑的圓潤低音
	n = int(0.34 * SR)
	var bonk := PackedFloat32Array()
	bonk.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / SR
		var f := 320.0 * pow(190.0 / 320.0, minf(t / 0.2, 1.0))
		ph += TAU * f / SR
		var e := minf(t / 0.006, 1.0) * exp(-t / 0.11)
		bonk[i] = (sin(ph) + 0.22 * sin(3.0 * ph)) * e * 0.6
	_snd["bonk"] = to_wav(bonk)

	# 掉落：長長的下滑音
	n = int(0.8 * SR)
	var fall := PackedFloat32Array()
	fall.resize(n)
	ph = 0.0
	for i in n:
		var t := float(i) / SR
		var f := 900.0 * pow(120.0 / 900.0, t / 0.8) * (1.0 + 0.02 * sin(TAU * 9.0 * t))
		ph += TAU * f / SR
		var e := minf(t / 0.01, 1.0) * exp(-t / 0.32)
		fall[i] = (sin(ph) + 0.25 * sin(2.0 * ph)) * e * 0.5
	_snd["fall"] = to_wav(fall)


# ================= 自動幫按鈕、滑桿加上音效 =================

func _hook_tree(node: Node) -> void:
	_hook(node)
	for c in node.get_children():
		_hook_tree(c)


## 按鈕自動加上「嘀」聲、滑桿加上「滴答」聲；不想要的加 meta "silent"
func _hook(node: Node) -> void:
	if node.has_meta("_snd_hooked") or node.has_meta("silent"):
		return
	if node is BaseButton:
		node.set_meta("_snd_hooked", true)
		node.pressed.connect(_on_btn.bind(node))
	elif node is HSlider:
		node.set_meta("_snd_hooked", true)
		node.value_changed.connect(_on_slider.bind(node))


## 手機的返回鍵：轉成和 Esc 一樣的「ui_cancel」；離開遊戲時重排提醒通知
func _notification(what: int) -> void:
	# 離開遊戲（切到背景、關掉）：重新排好提醒通知
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if notifier != null:
			notifier.reschedule()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_inside_tree():
		var ev := InputEventAction.new()
		ev.action = "ui_cancel"
		ev.pressed = true
		get_viewport().push_input(ev)


func _on_btn(b: BaseButton) -> void:
	if not b.has_meta("silent"):
		sfx("click")


func _on_slider(_v: float, s: HSlider) -> void:
	if s.max_value > s.min_value:
		sfx("tick", int(10.0 * (s.value - s.min_value) / (s.max_value - s.min_value)))
