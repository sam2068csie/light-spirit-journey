extends "game_audio.gd"
## 遊戲管家（第 3 層）：主線獎勵（星塵、章節寶箱、終焉之塔）、每日任務、光靈扭蛋、裝扮、連續簽到、碎片兌換

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


## 章節黃金寶箱：這一章完成度 100%（每段旅程的每一種題型都答對過）才能打開
const GOLD_CHEST := {"dust": 300, "shard": 40, "crystal": 2}


const GOLD_CHEST_FINAL := {"dust": 400, "shard": 60, "crystal": 3}


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
func claim_chest(ckey: String, final: bool, gold := false) -> Dictionary:
	if main_rw.chests.has(ckey):
		return {}
	main_rw.chests[ckey] = true
	var got: Dictionary
	if gold:
		got = (GOLD_CHEST_FINAL if final else GOLD_CHEST).duplicate()
	else:
		got = (CHEST_FINAL if final else CHEST).duplicate()
	for k in got:
		inv[k] = int(inv.get(k, 0)) + int(got[k])
	save_review()
	return got


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
