extends RefCounted
## 每日任務的題目與獎勵（資料與換日規則）。狀態存在 game.gd 的 quests / inv。
##
## 每天五個任務：登入、答對 3 題、答對 5 題、弱點特訓、每日挑戰（四種輪流）。
## 每完成一個任務可以領星塵；領取 1、3、5 個任務的獎勵後還有區間獎勵（星塵袋、每日寶箱、光之結晶）。

const RESET_HOUR := 5            # 早上 5 點換日：熬夜過 12 點不會被切成兩天

## 每日挑戰：依日期輪流
const CHALLENGES := {
	"perfect": {"title": "完美解題", "desc": "任選一題，拿到三顆星。", "need": 1, "go": "levels"},
	"tower3": {"title": "攀登終焉之塔", "desc": "在終焉之塔爬到第 3 層。", "need": 3, "go": "tower"},
	"timed": {"title": "限時試煉", "desc": "通過 1 題限時題（各章的試煉）。", "need": 1, "go": "levels"},
	"daily": {"title": "完成今日修煉", "desc": "到修煉之間，做完今天的修煉題。", "need": 1, "go": "review"},
}
const CH_ORDER := ["perfect", "tower3", "timed", "daily"]

## 區間獎勵：完成幾個任務可以領
const TIERS := [
	{"n": 1, "kind": "dust", "amt": 50, "name": "星塵袋", "desc": "星塵 ×50"},
	{"n": 3, "kind": "chest", "amt": 1, "name": "每日寶箱", "desc": "星塵 80～150、光之碎片 1～2"},
	{"n": 5, "kind": "crystal", "amt": 1, "name": "光之結晶", "desc": "光之結晶 ×1"},
]

## 物品
const ITEMS := {
	"dust": {"name": "星塵", "desc": "完成任務得到的星塵。"},
	"shard": {"name": "光之碎片", "desc": "從每日寶箱開出來的碎片。"},
	"crystal": {"name": "光之結晶", "desc": "五個任務全部完成才拿得到的結晶。"},
}


## 今天是哪一天（早上 5 點前算前一天），用本地時間
static func day_key() -> String:
	return Time.get_date_string_from_unix_time(_local_shifted())


static func _local_shifted() -> int:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0))
	return int(Time.get_unix_time_from_system()) + bias * 60 - RESET_HOUR * 3600


## 今天的每日挑戰（同一天每個人都一樣，老師可以在課堂上提）
static func challenge_today() -> String:
	var day_n := int(floor(_local_shifted() / 86400.0))
	return CH_ORDER[posmod(day_n, CH_ORDER.size())]


## 今天的五個任務。key：進度記在 prog 的哪一格
static func defs(ch: String) -> Array:
	var c: Dictionary = CHALLENGES.get(ch, CHALLENGES.perfect)
	return [
		{"id": "login", "key": "login", "title": "每日登入", "desc": "打開遊戲就完成了！", "need": 1, "dust": 20, "go": ""},
		{"id": "ans3", "key": "ans", "title": "小試身手", "desc": "在任意關卡答對 3 題。", "need": 3, "dust": 30, "go": "levels"},
		{"id": "ans5", "key": "ans", "title": "勤學不倦", "desc": "在任意關卡答對 5 題。", "need": 5, "dust": 40, "go": "levels"},
		{"id": "weak", "key": "weak", "title": "弱點特訓", "desc": "到修煉之間，完成 1 題修煉題。", "need": 1, "dust": 50, "go": "review"},
		{"id": "ch", "key": "ch", "title": "每日挑戰：" + c.title, "desc": c.desc, "need": c.need, "dust": 60, "go": c.go},
	]


## 打開每日寶箱：隨機的星塵和光之碎片
static func roll_chest() -> Dictionary:
	return {"dust": randi_range(80, 150), "shard": randi_range(1, 2)}
