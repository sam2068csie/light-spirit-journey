extends "test_base.gd"
## 4. 存檔：存了再讀回來一樣；舊版存檔（沒有版本號）能升級；型別壞掉的欄位改用預設值；刪除紀錄會全部清空


func _write(data: Dictionary) -> void:
	var f := FileAccess.open(g.REVIEW_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()


func _read() -> Dictionary:
	return JSON.parse_string(FileAccess.open(g.REVIEW_PATH, FileAccess.READ).get_as_text())


func _initialize() -> void:
	await setup()
	# ---- 存了再讀回來 ----
	g.inv = {"dust": 1234, "shard": 5, "crystal": 2}
	g.house = {"owned": ["frame"], "placed": {"0": "frame"}}
	g.grade_pick = "高一"
	g.story_seen = ["prologue", "world/g10"]
	g.mistakes = {"exp_value": 3}
	g.save_review()
	ok(int(_read().get("version", 0)) == g.SAVE_VERSION, "存檔有版本號")
	g.inv = {"dust": 0, "shard": 0, "crystal": 0}
	g.house = {}
	g.grade_pick = ""
	g.story_seen = []
	g.mistakes = {}
	g._load_review()
	ok(int(g.inv.dust) == 1234 and int(g.inv.crystal) == 2, "星塵、結晶讀回來")
	ok(g.house.get("placed", {}).get("0", "") == "frame", "小屋擺設讀回來")
	ok(g.grade_pick == "高一", "身分讀回來")
	ok(g.story_seen.has("world/g10"), "劇情紀錄讀回來")
	ok(int(g.mistakes.get("exp_value", 0)) == 3, "錯題本讀回來（數字是 int）")
	# ---- 舊版存檔（沒有 version）＋型別壞掉的欄位 ----
	_write({"mistakes": {"a": 2.0}, "inv": {"dust": 50}, "house": "壞掉的字串", "tut": [1, 2], "story": ["L1"]})
	g._load_review()
	ok(int(g.inv.dust) == 50, "舊存檔：星塵")
	ok(g.house is Dictionary and g.house.is_empty(), "舊存檔：小屋型別錯 → 用預設值")
	ok(g.tut is Dictionary, "舊存檔：教學紀錄型別錯 → 用預設值")
	ok(g.story_seen == ["L1"], "舊存檔：劇情")
	ok(typeof(g.mistakes.a) == TYPE_INT, "舊存檔：錯題次數轉成 int")
	ok(int(_read().get("version", 0)) == g.SAVE_VERSION, "舊存檔讀完之後升級成新版本")
	ok(FileAccess.file_exists(g.REVIEW_PATH + ".v1.bak"), "升級前留了備份")
	# ---- 刪除所有紀錄 ----
	g.wipe_progress()
	ok(int(g.inv.dust) == 0 and g.house.is_empty() and g.grade_pick == "" and g.story_seen.is_empty(), "刪除紀錄：全部回到預設值")
	g.inv.dust = 7
	ok(int(load("res://data/game.gd").SAVE_FIELDS[6][2].dust) == 0, "預設值沒有被改到（有複製一份）")
	finish("SAVE")
