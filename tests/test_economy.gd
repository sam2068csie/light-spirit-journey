extends "test_base.gd"
## 5. 遊戲管家各層的功能真的跑得動（存檔、音效、星塵獎勵、寶箱、每日任務、扭蛋、簽到、換場景）
##    管家分成好幾層，有些呼叫要到執行時才知道對不對，所以每一層都實際呼叫一次


func _initialize() -> void:
	await setup()
	g.wipe_progress()
	await setup()
	# 第 2 層：音效
	g.sfx("correct")
	g.play("bell", 1.2, -10.0)
	g.set_volume("sfx", 0.5)
	ok(absf(g.sfx_vol - 0.5) < 0.001, "音量設定")
	# 第 3 層：主線獎勵
	var rw: Dictionary = g.journey_reward("L1/rise", 0, 3, false)
	ok(int(rw.dust) == g.RW_FIRST + g.RW_STAR3, "第一次通過＋三星的星塵：%s" % str(rw))
	var rw2: Dictionary = g.journey_reward("L1/rise", 0, 3, false)
	ok(int(rw2.dust) == 0, "同一題重玩不再給星塵")
	var before := int(g.inv.dust)
	var got: Dictionary = g.claim_chest("L1_c1", false)
	ok(int(got.get("dust", 0)) == int(g.CHEST.dust) and int(g.inv.dust) == before + int(g.CHEST.dust), "章節寶箱")
	ok(g.claim_chest("L1_c1", false).is_empty(), "寶箱只能開一次")
	var gold: Dictionary = g.claim_chest("L1_c1_gold", false, true)
	ok(int(gold.get("crystal", 0)) == int(g.GOLD_CHEST.crystal), "黃金寶箱")
	var tr: Dictionary = g.tower_reward(5)
	ok(int(tr.dust) > 0, "終焉之塔獎勵")
	# 每日任務
	g.quest_event("correct", {"stars": 3, "review": false, "timed": false})
	ok(g.quest_list().size() > 0, "每日任務清單")
	# 扭蛋
	g.inv.dust = 10000
	g.inv.crystal = 100
	var res: Array = g.gacha_pull("one")
	ok(res.size() == 1, "單抽")
	ok(g.gacha_pull("ten").size() == 10, "十連")
	ok(not g.owned.is_empty(), "抽到的裝扮有記下來")
	# 簽到
	var sc: Dictionary = g.streak_claim()
	ok(not sc.is_empty() and int(g.streak.count) >= 1, "連續簽到")
	# 存檔：剛剛的星塵、裝扮讀回來
	g.save_review()
	var dust := int(g.inv.dust)
	g.inv.dust = 0
	g._load_review()
	ok(int(g.inv.dust) == dust, "存檔讀回來")
	# 第 4 層：換場景
	g.goto("main_menu.gd")
	await wait(1.0)
	ok(current_scene != null and String(current_scene.get_script().resource_path).ends_with("main_menu.gd"), "換場景")
	finish("ECONOMY")
