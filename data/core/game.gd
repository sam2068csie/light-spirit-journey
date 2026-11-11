extends "res://data/core/game_economy.gd"
const Paths := preload("res://data/core/paths.gd")
## 遊戲管家：設定、音樂、音效、換場景、存檔……（分成四層，見 game_state.gd 開頭的說明）
## 不需要設定 Autoload：任何腳本呼叫 Game.of(self) 時，會自動建立並掛在場景樹的根節點上，
## 換場景也不會消失（背景音樂因此能不中斷地播放）。
##
##   const Game := preload("res://data/core/game.gd")
##   Game.of(self).sfx("correct")
##   Game.of(self).goto("main_menu.gd", {"page": "levels"})
##
## 這一層（第 4 層）：建立管家、換場景、今日修煉／弱點練習、終焉之塔的流程

const _SELF := preload("res://data/core/game.gd")


static var _inst: Node = null


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
	notifier = preload("res://data/core/notifier.gd").new()
	add_child(notifier)
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	var fxl := CanvasLayer.new()
	fxl.layer = 90
	add_child(fxl)
	fx = preload("res://data/ui/fx_layer.gd").new()
	fxl.add_child(fx)
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
	get_tree().node_added.connect(_on_node_added)
	for b in get_tree().root.find_children("*", "BaseButton", true, false):
		_on_node_added(b)
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


## 版本號（主畫面右下角會顯示）：每次交給你新的檔案時更新，方便確認手機上裝的是不是最新版
const BUILD := "2026.11.11-a"


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


# ---------- 進行中的一趟（session） ----------
# session 是「靠 kind 分辨形狀」的字典，只在這一段裡建立、推進、清空：
#   {}                                                  沒有在修煉或攀登
#   {kind: "daily"／"free", items, i, results}          修煉：做到第 i 題，results 是做完的
#   {kind: "tower", floor, hearts, history, cur}        攀登：在第 floor 層，cur 是這一層的題目
# 關卡只呼叫 level_report／level_abort，不用管自己是修煉還是攀登。

const REVIEW_KINDS := ["daily", "free"]


func in_review() -> bool:
	return String(session.get("kind", "")) in REVIEW_KINDS


func in_tower() -> bool:
	return String(session.get("kind", "")) == "tower"


## 關卡回報這一題／這一層的結果：修煉就往下一題，攀登就往上一層（hearts = 剩下幾顆心，只有攀登用得到）
##   沒有在修煉或攀登（例如測試直接開關卡）就什麼都不做
func level_report(stars: int, hearts: int) -> void:
	if in_tower():
		_tower_report(stars, hearts)
	elif in_review():
		_review_report(stars)


## 暫停選單的「結束修煉／放棄攀登」：攀登的話，目前這一層不算
func level_abort() -> void:
	if in_tower():
		_tower_end(int(session.floor) - 1)
	else:
		session = {}
		goto("main_menu.gd", {"page": "review"})


## 開始一場修煉。kind = "daily"（今日修煉，可以從中斷的地方繼續）或 "free"（自由練習）
func start_session(kind: String, items: Array) -> void:
	assert(kind in REVIEW_KINDS, "start_session：不認得的 kind " + kind)
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
	var center = load(Paths.of("review_center.gd"))
	var info: Dictionary = center.level_info(it.level)
	goto(info.file, {"review": it, "review_i": session.i, "review_n": session.items.size(), "review_kind": session.kind})


## 修煉的一題做完了（stars = 0 表示看示範過關）
func _review_report(stars: int) -> void:
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
const TOWER_SEEN_MAX := 200       # 跨輪記憶最多記幾題（夠蓋過好幾輪）


## 開始攀登：從第 1 層、三顆心開始
func start_tower() -> void:
	session = {"kind": "tower", "floor": 1, "hearts": TOWER_HEARTS, "history": []}
	_launch_tower_floor()


func _launch_tower_floor() -> void:
	var center = load(Paths.of("review_center.gd"))
	var f: int = session.floor
	var it: Dictionary = center.tower_pick(f, session.history, cur_unit, tower_seen)
	session["cur"] = it
	var info: Dictionary = center.level_info(it.level)
	goto(info.file, {"review": it, "review_kind": "tower", "review_i": f - 1, "review_n": f,
		"tower_floor": f, "tower_hearts": int(session.hearts),
		"tower_time": center.tower_time(f) * float(it.get("tmul", 1.0))})


## 攀登的一層結束了：hearts = 剩下幾顆心
func _tower_report(stars: int, hearts: int) -> void:
	var it: Dictionary = session.cur
	session.history.append({"level": it.level, "slot": it.slot, "title": it.title, "stars": stars, "floor": session.floor,
		"type": it.get("type", "")})
	session.hearts = hearts
	if stars > 0 and it.level != "T":
		mark_cleared(it.level + "/" + it.slot, int(it.vi))
	if it.level == "T":
		# 跨輪記憶：最近出過的新題（代號#變體），下一輪先出沒看過的
		var key := "%s#%d" % [it.slot, int(it.get("vi", 0))]
		var seen: Array = tower_seen.filter(func(x): return x != key)
		seen.append(key)
		tower_seen = seen.slice(maxi(0, seen.size() - TOWER_SEEN_MAX))
	var center = load(Paths.of("review_center.gd"))
	if hearts > 0:
		quest_event("tower_floor", {"floor": int(session.floor)})
	if hearts > 0 and int(session.floor) >= int(center.tower_top(cur_unit)):
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
	if in_tower():
		_launch_tower_floor()


func _tower_end(floors: int, summit := false) -> void:
	var record := floors > tower_best
	tower_best = maxi(tower_best, floors)
	tower_runs += 1
	var rw := tower_reward(floors)
	save_review()
	var res := {"floors": floors, "record": record, "history": session.history, "summit": summit, "reward": rw}
	session = {}
	goto("main_menu.gd", {"page": "tower", "tower_result": res})


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
	var script: Script = load(Paths.of(script_file))
	var node := Control.new()
	node.set_script(script)
	var ps := PackedScene.new()
	ps.pack(node)
	node.free()
	get_tree().change_scene_to_packed(ps)
	await get_tree().process_frame
	await get_tree().process_frame
	# 新畫面從稍微放大、偏下的位置滑進來，配合黑幕淡出
	var sc := get_tree().current_scene as Control
	if sc != null:
		sc.pivot_offset = sc.size / 2.0
		sc.scale = Vector2(1.03, 1.03)
		sc.position = Vector2(0, 10)
		var tw3 := sc.create_tween().set_parallel()
		tw3.tween_property(sc, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw3.tween_property(sc, "position", Vector2.ZERO, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
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
