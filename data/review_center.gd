extends RefCounted
## 錯題本與每日修煉的「大腦」：
##   ・觀念索引：每個觀念標籤（tag）可以用哪些題目（大關／旅程／題型）來練
##   ・熟練度：答錯幾次、複習答對幾次 → 哪些觀念還需要加強
##   ・每日修煉：每天從最弱的觀念各挑一題，湊成 5 題
## 存檔資料放在 Game（game.gd）裡；這個檔案只負責計算。

const QuizInfo := preload("quiz_manager.gd")
const TowerBank := preload("tower_bank.gd")

## 終焉之塔的段考風格題目（不在八大關裡，level 記成 "T"）
const TOWER_INFO := {"id": "T", "name": "終焉之塔", "file": "boss_tower.gd", "bank": "", "color": Color("ff8fa0")}

const Units := preload("units.gd")

## 所有單元的所有大關（觀念索引橫跨全部單元；顯示時再依目前單元篩選）
static func levels() -> Array:
	return Units.all_levels()

const DAILY_SIZE := 5
const SKIP_TYPES := ["speed"]      # 限時連續速算不適合單獨拿來複習

## 某些題型沒有寫 tag，用預設值
const TYPE_DEFAULT_TAG := {"cross": "exp_quad_cross", "draw": "draw_graph", "table": "exp_quad_cross"}

static var _index: Dictionary = {}       # tag → [{level, slot, vi, title, type}]
static var _level_tags: Dictionary = {}  # 大關 id → [tag…]
static var _built := false
static var _slots: Dictionary = {}       # 大關 id → [旅程 id…]（世界地圖算完成度用）


static func level_info(id: String) -> Dictionary:
	if id == "T":
		return TOWER_INFO
	for lv in levels():
		if lv.id == id:
			return lv
	return levels()[0]


## 這段旅程還存在嗎？（舊存檔裡可能有已經刪掉的題目）
static func slot_exists(level: String, slot: String) -> bool:
	if level == "T":
		return true
	build()
	return _slots.get(level, []).has(slot)


static func tag_name(tag: String) -> String:
	return QuizInfo.MISTAKE_INFO.get(tag, {}).get("name", tag)


# ================= 觀念索引 =================

static func build() -> void:
	if _built:
		return
	_built = true
	var base: String = (QuizInfo as Script).resource_path.get_base_dir()
	for lv in levels():
		if String(lv.bank) == "":
			continue      # 建造中的大關（還沒有題庫）
		var bank: Script = load(base + "/" + lv.bank)
		if bank == null:
			continue
		var tags_here := {}
		_slots[lv.id] = []
		for slot in bank.slots():
			_slots[lv.id].append(slot.id)
			if SKIP_TYPES.has(slot.type):
				continue
			var slot_tags := {}
			var head: Dictionary = slot.duplicate()
			head.erase("variants")
			_collect(head, slot_tags)
			for vi in slot.variants.size():
				var tags := slot_tags.duplicate()
				_collect(slot.variants[vi], tags)
				if tags.is_empty() and TYPE_DEFAULT_TAG.has(slot.type):
					tags[TYPE_DEFAULT_TAG[slot.type]] = true
				for t in tags:
					if not _index.has(t):
						_index[t] = []
					_index[t].append({"level": lv.id, "slot": slot.id, "vi": vi, "title": slot.title, "type": slot.type})
					tags_here[t] = true
		_level_tags[lv.id] = tags_here.keys()


## 把字典／陣列裡所有 "tag" 的值收集起來
static func _collect(v, out: Dictionary) -> void:
	if v is Dictionary:
		for k in v:
			if k == "tag" and v[k] is String and v[k] != "":
				out[v[k]] = true
			elif v[k] is Dictionary or v[k] is Array:
				_collect(v[k], out)
	elif v is Array:
		for e in v:
			if e is Dictionary or e is Array:
				_collect(e, out)


static func items_for(tag: String) -> Array:
	build()
	return _index.get(tag, [])


static func tags_of_level(id: String) -> Array:
	build()
	return _level_tags.get(id, [])


static func all_tags() -> Array:
	build()
	return _index.keys()


## 這一大關的旅程有幾成答對過（每段旅程至少答對一種題型才算）；1.0 = 整個大關完成
static func level_progress(g, id: String) -> float:
	build()
	var sl: Array = _slots.get(id, [])
	if sl.is_empty():
		return 0.0
	var n := 0
	for sid in sl:
		if not g.cleared_of(id + "/" + sid).is_empty():
			n += 1
	return float(n) / sl.size()


# ================= 熟練度 =================

## 還欠多少：答錯次數 − 複習分數（> 0 表示還需要加強）
## 複習時一次全對 +2、答對 +1：答錯 3 次的觀念，大約要複習 2 次才會「已掌握」
static func weakness(g, tag: String) -> int:
	return int(g.mistakes.get(tag, 0)) - int(g.fixed.get(tag, 0))


## 學生碰過這個觀念嗎（答錯過，或某段用到它的旅程答對過）
static func seen(g, tag: String) -> bool:
	if int(g.mistakes.get(tag, 0)) > 0 or int(g.fixed.get(tag, 0)) > 0:
		return true
	for it in items_for(tag):
		if g.cleared_of(it.level + "/" + it.slot).has(it.vi):
			return true
	return false


## 一個觀念的狀態："weak" 待加強、"solid" 已掌握、"new" 還沒碰過
static func status(g, tag: String) -> String:
	if weakness(g, tag) > 0:
		return "weak"
	return "solid" if seen(g, tag) else "new"


## 每一大關的熟練度：{掌握, 待加強, 總數}
static func level_mastery(g, id: String) -> Dictionary:
	var tags := tags_of_level(id)
	var solid := 0
	var weak := 0
	for t in tags:
		match status(g, t):
			"solid":
				solid += 1
			"weak":
				weak += 1
	return {"solid": solid, "weak": weak, "total": tags.size()}


## 這個觀念屬於哪個單元
static func unit_of_tag(tag: String) -> String:
	return Units.unit_of_level(home_level(tag))


## 最需要加強的觀念（由弱到強）。unit：只看這個單元（空白 = 全部單元）
static func weakest(g, n: int = 5, unit: String = "") -> Array:
	var out := []
	for t in g.mistakes:
		if weakness(g, t) > 0 and not items_for(t).is_empty() and (unit == "" or unit_of_tag(t) == unit):
			out.append(t)
	out.sort_custom(func(a, b):
		var wa := weakness(g, a)
		var wb := weakness(g, b)
		if wa != wb:
			return wa > wb
		return float(g.last_wrong.get(a, 0)) > float(g.last_wrong.get(b, 0)))
	return out.slice(0, n)


## 這個觀念主要屬於哪一大關（第一個用到它的大關）
static func home_level(tag: String) -> String:
	var its := items_for(tag)
	return its[0].level if not its.is_empty() else "L1"


# ================= 挑題 =================

## 這一題學生能玩嗎：所屬大關已經開始玩過（有任何一段旅程答對過，或在那裡答錯過）
static func _playable(g, it: Dictionary) -> bool:
	for k in g.cleared:
		if String(k).begins_with(it.level + "/"):
			return true
	return false


## 替一個觀念挑一題：優先挑還沒答對過的題型
static func pick_for(g, tag: String, avoid: Dictionary = {}) -> Dictionary:
	var its := items_for(tag).filter(func(it): return _playable(g, it) and not avoid.has(it.level + "/" + it.slot))
	if its.is_empty():
		its = items_for(tag).filter(func(it): return not avoid.has(it.level + "/" + it.slot))
	if its.is_empty():
		return {}
	var fresh := its.filter(func(it): return not g.cleared_of(it.level + "/" + it.slot).has(it.vi))
	var pool := fresh if not fresh.is_empty() else its
	var it: Dictionary = pool.pick_random().duplicate()
	it["tag"] = tag
	return it


## 今日修煉：最弱的觀念各一題；不夠 5 題就從玩過的旅程裡抽回鍋題（只出目前單元的題目）
static func make_daily(g) -> Array:
	var unit: String = g.cur_unit
	var out := []
	var used := {}
	for t in weakest(g, DAILY_SIZE, unit):
		var it := pick_for(g, t, used)
		if not it.is_empty():
			used[it.level + "/" + it.slot] = true
			out.append(it)
	# 回鍋題：玩過、但已經一段時間沒碰的觀念
	var others := []
	for t in all_tags():
		if seen(g, t) and weakness(g, t) <= 0 and unit_of_tag(t) == unit:
			others.append(t)
	others.shuffle()
	for t in others:
		if out.size() >= DAILY_SIZE:
			break
		var it := pick_for(g, t, used)
		if it.is_empty() or not _playable(g, it):
			continue
		it["refresh"] = true
		used[it.level + "/" + it.slot] = true
		out.append(it)
	return out


# ================= 終焉之塔（綜合大考） =================

## 能放進塔裡的題型（有限時、可以單獨玩完一題的類型）
const TOWER_TYPES := ["forge", "fit", "rank", "quadrant", "draw", "cross", "chord"]

static var _tower: Dictionary = {}      # 單元 → 題目清單


## 這個單元各大關所有能用的題目：{level, slot, vi, title, type, chapter, boss}
static func tower_pool(unit: String = Units.DEFAULT) -> Array:
	if _tower.has(unit):
		return _tower[unit]
	var pool := []
	_tower[unit] = pool
	var base: String = (QuizInfo as Script).resource_path.get_base_dir()
	for lv in Units.unit(unit).levels:
		if String(lv.bank) == "":
			continue
		var bank: Script = load(base + "/" + lv.bank)
		if bank == null:
			continue
		for slot in bank.slots():
			if not TOWER_TYPES.has(slot.type):
				continue
			for vi in slot.variants.size():
				pool.append({"level": lv.id, "slot": slot.id, "vi": vi, "title": slot.title, "type": slot.type,
					"chapter": int(slot.get("chapter", 1)), "boss": String(slot.id).contains("boss")})
	return pool


## 每一層出哪一題：
##   ・每 5 層是「試煉層」：段考風格的多段大題（第 5 層只出難度 2 以下的）
##   ・其他樓層大約七成出段考風格的新題型（真假審判、驗根、數線、極值、應用），三成出八大關的舊題型喘口氣
##   ・新題型的難度跟著樓層上升：1～4 層難度 1，6～9 層難度 2 以下，之後全部都會出
##   ・避開最近出過的題目，也不連續出同一種題型／同一個大關
static func tower_pick(floor_n: int, recent: Array, unit: String = Units.DEFAULT) -> Dictionary:
	var used := {}
	for it in recent.slice(maxi(0, recent.size() - 12)):
		used[String(it.level) + "/" + String(it.slot)] = true
	var last: Dictionary = recent.back() if not recent.is_empty() else {}
	if floor_n % 5 == 0:
		# 試煉層：同一輪攀登裡不重複（用完就是塔頂，見 tower_top）
		for it in recent:
			used[String(it.level) + "/" + String(it.slot)] = true
		return _tower_new(floor_n, used, last, true)
	if floor_n == 1 or randf() < 0.7:
		var it := _tower_new(floor_n, used, last, false)
		if not it.is_empty():
			return it
	return _tower_old(floor_n, used, last, unit)


static func tower_max_tier(floor_n: int) -> int:
	return 1 if floor_n <= 4 else (2 if floor_n <= 10 else 3)


static func _tower_new(floor_n: int, used: Dictionary, last: Dictionary, boss: bool) -> Dictionary:
	var tier := tower_max_tier(floor_n)
	var last_kind := String(last.get("type", ""))
	var pool := TowerBank.items().filter(func(q):
		return (q.kind == "boss") == boss and int(q.tier) <= maxi(tier, 2 if boss else 1))
	var cands := pool.filter(func(q): return not used.has("T/" + q.id) and q.kind != last_kind)
	if boss and cands.is_empty():
		# 試煉層：難度合適的都出過了，就從還沒出過的試煉題裡挑（一輪之內絕不重複）
		cands = TowerBank.items().filter(func(q): return q.kind == "boss" and not used.has("T/" + q.id))
	if cands.is_empty():
		cands = pool.filter(func(q): return q.kind != last_kind)
	if cands.is_empty():
		cands = pool
	if cands.is_empty():
		return {}
	# 高樓層偏好難一點的題目
	var top := cands.filter(func(q): return int(q.tier) == tier)
	var q: Dictionary = (top if not top.is_empty() and randf() < 0.6 else cands).pick_random()
	return {"level": "T", "slot": q.id, "vi": 0, "title": TowerBank.KIND_NAME[q.kind] + "・" + q.title,
		"type": q.kind, "tmul": float(q.get("tmul", 1.0)), "tag": ""}


static func _tower_old(floor_n: int, used: Dictionary, last: Dictionary, unit: String = Units.DEFAULT) -> Dictionary:
	var pool := tower_pool(unit)
	var last_level := String(last.get("level", ""))
	var cands := pool.filter(func(it):
		if used.has(it.level + "/" + it.slot) or it.level == last_level or it.boss:
			return false
		return it.chapter == 1 if floor_n <= 4 else true)
	if cands.is_empty():
		cands = pool.filter(func(it): return it.level != last_level)
	var it: Dictionary = cands.pick_random().duplicate()
	it["tag"] = ""
	return it


## 塔頂：每 5 層一個試煉層，試煉題用完（一輪不重複）就是塔頂
static func tower_top() -> int:
	return 5 * TowerBank.items().filter(func(q): return q.kind == "boss").size()


## 每一層的限時（越高越短）
static func tower_time(floor_n: int) -> float:
	return maxf(105.0, 260.0 - 10.0 * (floor_n - 1))
