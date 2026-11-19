extends "res://data/core/game_economy.gd"
## 遊戲管家（第 3.5 層）：光靈的親密度（養成系統第一、二期）。提案：Claude Docs「光靈養成系統提案」，摘要在 docs/bond_plan.md
##
## 原則：親密度主要靠「一起學數學」累積，小屋互動只是每天幾分鐘的小甜頭；只增不減，沒來不會倒退。
## 存檔：bond = {pts（累計，只增不減）, day（今天，早上 5 點換日）, today: {種類: 次數}, hello（小屋第一句話）, lvup（還沒播的升級）,
##   seed（這個玩家的口味種子）, found: {week, ids}（這週試出來的喜好）, mem: [回憶照片], nick（光靈怎麼叫你）}
## 等級由 pts 算出來，不另外存。

## 10 級：累計多少點、名稱（暫定，世界觀定了再改）、解鎖什麼（ready：這一期做好了沒）
const BOND_LEVELS := [
	{"lv": 1, "need": 0, "name": "初識", "unlock": "小屋互動：摸摸頭、聊天", "ready": true},
	{"lv": 2, "need": 40, "name": "打招呼", "unlock": "主畫面愛心特效", "ready": true},
	{"lv": 3, "need": 120, "name": "熟悉", "unlock": "表情「害羞」、點心", "ready": true},
	{"lv": 4, "need": 250, "name": "好朋友", "unlock": "頭飾「友誼之星」、家具「光靈的小床」", "ready": true},
	{"lv": 5, "need": 450, "name": "陪讀夥伴", "unlock": "自訂暱稱", "ready": true},
	{"lv": 6, "need": 700, "name": "默契", "unlock": "小屋互動：教光靈", "ready": false},
	{"lv": 7, "need": 1000, "name": "心有靈犀", "unlock": "簽到守護上限 +1", "ready": true},
	{"lv": 8, "need": 1400, "name": "知己", "unlock": "限定光環", "ready": false},
	{"lv": 9, "need": 1900, "name": "羈絆", "unlock": "光靈外觀進化", "ready": false},
	{"lv": 10, "need": 2500, "name": "永恆之光", "unlock": "拖尾特效、稱號", "ready": false},
]

## 每一種行為給多少親密度
const BOND_PTS := {
	"learn": 1,       # 答對（過關）一題：一次答對、答錯後改對都一樣 +1（不會有人故意答錯）
	"journey": 5,     # 第一次通過一段旅程
	"card": 3,        # 第一次完成一張觀念卡片
	"daily": 5,       # 做完今日修煉
	"quests": 5,      # 每日任務全部完成
	"pet": 1,         # 小屋：摸摸頭
	"chat": 2,        # 小屋：聊天
	"welcome": 5,     # 3 天以上沒來：歡迎回來的小禮（不管幾天都一樣）
	"snack": 1,       # 小屋：點心（Lv 3）
	"snack_like": 3,  # 點心剛好是這週喜歡的口味
}

## 每天最多幾次（沒寫的不限：旅程、卡片本身就有限）
const BOND_CAP := {"learn": 30, "daily": 1, "quests": 1, "pet": 3, "chat": 1, "snack": 1, "photo": 1}

const WELCOME_DAYS := 3
const SNACK_LV := 3
const NICK_LV := 5
const NICK_MAX := 6
const MEM_MAX := 80                   # 相簿最多幾張（滿了先丟最舊的每日合照）

## 點心：用星塵買、當場餵。每個人每週喜歡其中 2 種（週一早上 5 點換口味）
const SNACKS := [
	{"id": "moon_cake", "name": "月光餅", "price": 10},
	{"id": "star_candy", "name": "星星糖", "price": 15},
	{"id": "dew_jelly", "name": "露珠果凍", "price": 15},
	{"id": "rainbow_puff", "name": "彩虹棉花糖", "price": 20},
	{"id": "honey_orb", "name": "蜂蜜光球", "price": 25},
	{"id": "comet_pudding", "name": "流星布丁", "price": 30},
]
const FRIEND_STAR := "friend_star"     # Lv 4 的限定頭飾（cosmetics.gd）


## 整理存檔、換日（換日時看看是不是好幾天沒來）
func bond_state() -> Dictionary:
	if not bond.has("pts"):
		bond["pts"] = 0
	bond["pts"] = maxi(0, int(bond.pts))
	if not (bond.get("today") is Dictionary):
		bond["today"] = {}
	var day := DQ.day_key()
	var last := String(bond.get("day", ""))
	if last != day:
		bond["day"] = day
		bond["today"] = {}
		bond["hello"] = ""
		if last != "" and _day_n(day) - _day_n(last) >= WELCOME_DAYS:
			bond["hello"] = "welcome"
			_bond_add(int(BOND_PTS.welcome))
		save_review()
	return bond


static func bond_level_of(pts: int) -> int:
	var lv := 1
	for l in BOND_LEVELS:
		if pts >= int(l.need):
			lv = int(l.lv)
	return lv


static func bond_info(lv: int) -> Dictionary:
	return BOND_LEVELS[clampi(lv, 1, BOND_LEVELS.size()) - 1]


func bond_level() -> int:
	return bond_level_of(int(bond.get("pts", 0)))


## 進度條用：{lv, name, frac（這一級走了多少）, next（下一級的資料，滿級是空的）}
func bond_progress() -> Dictionary:
	var pts := int(bond_state().pts)
	var lv := bond_level_of(pts)
	var cur := bond_info(lv)
	var nxt: Dictionary = {} if lv >= BOND_LEVELS.size() else bond_info(lv + 1)
	var frac := 1.0
	if not nxt.is_empty():
		frac = float(pts - int(cur.need)) / float(int(nxt.need) - int(cur.need))
	return {"lv": lv, "name": cur.name, "frac": clampf(frac, 0.0, 1.0), "next": nxt, "pts": pts}


## 今天某一種還能拿幾次（不限的回傳 −1）
func bond_left(kind: String) -> int:
	if not BOND_CAP.has(kind):
		return -1
	return maxi(0, int(BOND_CAP[kind]) - int(bond_state().today.get(kind, 0)))


## 發生了一件會增加親密度的事。回傳加了幾點（今天的次數用完了回傳 0）
func bond_gain(kind: String) -> int:
	var b := bond_state()
	if BOND_CAP.has(kind):
		if bond_left(kind) <= 0:
			return 0
		b.today[kind] = int(b.today.get(kind, 0)) + 1
	var n := int(BOND_PTS.get(kind, 0))
	_bond_add(n)
	save_review()
	return n


func _bond_add(n: int) -> void:
	var before := bond_level()
	bond["pts"] = int(bond.get("pts", 0)) + n
	var after := bond_level()
	if after > before:
		bond["lvup"] = maxi(int(bond.get("lvup", 0)), after)
		for lv in range(before + 1, after + 1):
			bond_memory("lv:%d" % lv, "親密度 Lv.%d" % lv, "levelup")
	_bond_unlocks()


## 等級到了就發的東西（重複呼叫沒關係）
func _bond_unlocks() -> void:
	if bond_level() >= 4 and not owned.has(FRIEND_STAR):
		owned[FRIEND_STAR] = 1


## 還沒播的升級（0 = 沒有）
func bond_lvup_pending() -> int:
	return int(bond.get("lvup", 0))


## 播升級畫面時拿走：回傳升到第幾級
func bond_take_levelup() -> int:
	var lv := int(bond.get("lvup", 0))
	if lv > 0:
		bond.erase("lvup")
		save_review()
	return lv


## 小屋第一句話（"welcome"：好幾天沒來）；拿一次就清掉
func bond_take_hello() -> String:
	var h := String(bond_state().get("hello", ""))
	if h != "":
		bond["hello"] = ""
		save_review()
	return h


# ================= 接在現有的事件上 =================

func quest_event(kind: String, data: Dictionary = {}) -> void:
	super(kind, data)
	match kind:
		"correct":
			bond_gain("learn")
		"daily_done":
			bond_gain("daily")
	var list := quest_list()
	if not list.is_empty() and quest_done_count() >= list.size():
		bond_gain("quests")


func journey_reward(key: String, vi: int, stars: int, boss: bool) -> Dictionary:
	var first: bool = not main_rw.slots.has(key)
	var r := super(key, vi, stars, boss)
	if first:
		r["bond"] = bond_gain("journey")
	if stars >= 3:
		bond_memory("first_star3", "第一次三顆星", "map")
	return r


## Lv 7：簽到守護上限 +1（親密度唯一的遊戲好處）
func _guard_bonus() -> int:
	return 1 if bond_level() >= 7 else 0


# ================= 聊天：說的是你真的做過的事 =================

## 今天的聊天內容。first = 今天第一次聊（說最有內容的那一句）
func bond_chat_line(first: bool) -> String:
	var b := bond_state()
	var facts := []
	var learn := int(b.today.get("learn", 0))
	if learn >= int(BOND_CAP.learn):
		facts.append("你今天答對超過 %d 題了！休息一下也沒關係喔～" % learn)
	elif learn > 0:
		facts.append("你今天答對了 %d 題耶！我都有看到喔～" % learn)
	if int(b.today.get("daily", 0)) > 0:
		facts.append("今天的修煉做完了，好厲害！")
	var left := quest_list().size() - quest_done_count()
	if left > 0 and learn > 0:
		facts.append("布告欄上的每日任務還剩 %d 個喔。" % left)
	elif left == 0:
		facts.append("今天的每日任務全部完成了！我要轉圈圈～")
	if int(streak.get("count", 0)) >= 2 and String(streak.get("last", "")) == DQ.day_key():
		facts.append("我們已經連續見面 %d 天了！" % int(streak.count))
	if learn == 0:
		facts.append("今天還沒一起解題呢，要不要去點亮一座聖地？")
	var lv := bond_level()
	var nk := bond_nick()
	var you := (nk + "，") if nk != "" else ""
	var warm := [you + "和你聊天最開心了～", you + "今天的你看起來也很努力喔！"]
	if lv >= 3:
		warm.append("和你在一起，我的光好像變亮了一點。")
	if lv >= 4:
		warm.append("嘿嘿，我們是好朋友了吧？")
	if lv >= SNACK_LV:
		var f := bond_found()
		if f.size() < 2:
			warm.append("這週我想吃的點心……你猜得到嗎？")
		else:
			warm.append("這週喜歡的口味都被你發現了！")
	if first and not facts.is_empty():
		return you + String(facts[0])
	return String((facts + warm).pick_random())


# ================= 點心（第二期） =================

## 第幾週（週一早上 5 點換週）
func bond_week() -> int:
	return int(floor((_day_n(DQ.day_key()) + 3) / 7.0))


## 這個玩家這週喜歡的 2 種點心（每個人不一樣，每週換）
func bond_likes() -> Array:
	var b := bond_state()
	if int(b.get("seed", 0)) == 0:
		b["seed"] = randi_range(1, 2000000000)
		save_review()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([int(b.seed), bond_week()])
	var ids := []
	for sn in SNACKS:
		ids.append(String(sn.id))
	var out := []
	while out.size() < 2:
		var id: String = ids[rng.randi_range(0, ids.size() - 1)]
		if not out.has(id):
			out.append(id)
	return out


## 這週已經試出來的喜好
func bond_found() -> Array:
	var b := bond_state()
	var f = b.get("found", {})
	if not (f is Dictionary) or int(f.get("week", -1)) != bond_week():
		f = {"week": bond_week(), "ids": []}
		b["found"] = f
	return f.ids


static func snack_info(id: String) -> Dictionary:
	for sn in SNACKS:
		if sn.id == id:
			return sn
	return {}


## 餵點心：扣星塵、加親密度。回傳 {ok, why（不行的原因）, liked, first（這週第一次發現）, pts}
func bond_feed(id: String) -> Dictionary:
	var sn := snack_info(id)
	if sn.is_empty():
		return {"ok": false, "why": "沒有這種點心"}
	if bond_level() < SNACK_LV:
		return {"ok": false, "why": "親密度 Lv.%d 解鎖" % SNACK_LV}
	if bond_left("snack") <= 0:
		return {"ok": false, "why": "今日已餵食"}
	if int(inv.get("dust", 0)) < int(sn.price):
		return {"ok": false, "why": "星塵不足"}
	inv["dust"] = int(inv.get("dust", 0)) - int(sn.price)
	var liked := bond_likes().has(id)
	var found := bond_found()
	var first := liked and not found.has(id)
	if first:
		found.append(id)
	var b := bond_state()
	b.today["snack"] = int(b.today.get("snack", 0)) + 1
	var n := int(BOND_PTS.snack_like if liked else BOND_PTS.snack)
	_bond_add(n)
	save_review()
	return {"ok": true, "liked": liked, "first": first, "pts": n}


# ================= 回憶相簿（第二期） =================

## 拍一張回憶照片：id 一樣的只拍一次。scene 決定背景（house／levelup／map／tower／unit:單元 id）
func bond_memory(id: String, title: String, scene: String) -> bool:
	var b := bond
	if not (b.get("mem") is Array):
		b["mem"] = []
	for m in b.mem:
		if String(m.get("id", "")) == id:
			return false
	b.mem.append({"id": id, "title": title, "scene": scene, "day": DQ.day_key(), "eq": equipped.duplicate(true)})
	while (b.mem as Array).size() > MEM_MAX:
		var k := 0
		for i in (b.mem as Array).size():
			if String(b.mem[i].id).begins_with("photo:"):
				k = i
				break
		(b.mem as Array).remove_at(k)
	save_review()
	return true


func bond_memories() -> Array:
	var m = bond.get("mem", [])
	return m if m is Array else []


## 小屋：今天的合照（每天 1 張，不加親密度）
func bond_photo() -> bool:
	if bond_left("photo") <= 0:
		return false
	var b := bond_state()
	b.today["photo"] = int(b.today.get("photo", 0)) + 1
	return bond_memory("photo:" + DQ.day_key(), "小屋合照", "house")


# ================= 暱稱（第二期） =================

## 光靈怎麼叫你（Lv 5 以前、沒取的話是空的）
func bond_nick() -> String:
	if bond_level() < NICK_LV:
		return ""
	return String(bond.get("nick", ""))


## 設定暱稱：去掉頭尾空白，1～6 個字。回傳 true = 成功
func bond_set_nick(s: String) -> bool:
	var t := s.strip_edges().replace("\n", "")
	if t.length() < 1 or t.length() > NICK_MAX or bond_level() < NICK_LV:
		return false
	bond["nick"] = t
	save_review()
	return true
