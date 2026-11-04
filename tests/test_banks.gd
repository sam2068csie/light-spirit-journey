extends "test_base.gd"
## 2. 每個單元、每個大關、每段旅程的每一種題型，都能從頭自動作答到最後一步
##   ・推導題（forge）：一步一步呼叫 _step_done（等於每一步都答對）
##   ・速算（speed）：連答 3 題（正／負按鈕題用 _speed_pick）
##   ・其他題型（光橋、作圖……）：確認題目能正常開始
##   ・題庫格式檢查（step_bank.check）
## 環境變數 ONLY=L3 只測某一關；SHOTS=資料夾 會在每一步截圖（需要有畫面，不能 --headless）

const Units := preload("res://data/core/units.gd")


func _initialize() -> void:
	await setup()
	var only := OS.get_environment("ONLY")
	var SB := load("res://data/levels/engine/step_bank.gd")
	for u in Units.UNITS:
		for l in u.levels:
			if String(l.get("bank", "")) == "" or String(l.get("file", "")) == "":
				continue
			if only != "" and not (String(l.id) in only.split(",")):
				continue
			var bank = load(preload("res://data/core/paths.gd").of(String(l.bank)))
			ok(bank != null, "題庫 %s" % l.bank)
			if bank == null:
				continue
			var problems: Array = SB.check(bank.slots())
			ok(problems.is_empty(), "題庫格式 %s：%s" % [l.bank, str(problems)])
			await _tour_level(String(l.id), String(l.file), bank)
	finish("BANKS")


func _tour_level(lid: String, file: String, bank) -> void:
	g.goto(file)
	await wait(0.8)
	var lv = current_scene
	# 腳本有語法錯誤時，場景還是會建出來（只是沒有腳本）：要確認真的是關卡
	ok(lv != null and lv.has_method("make_round"), "%s 開得起來（腳本有載入）" % lid)
	if lv == null or not lv.has_method("make_round"):
		return
	# 關掉開場的章節選單
	for n in lv.get_children():
		if n is Control and n.mouse_filter == Control.MOUSE_FILTER_STOP and n.get_index() > 3:
			n.queue_free()
	await frames()
	lv.journey_mode = true
	var n_var := 0
	for slot in bank.slots():
		for vi in slot.variants.size():
			n_var += 1
			var tag := "%s/%s#%d" % [lid, slot.id, vi]
			lv.rounds = [lv.make_round(slot, slot.variants[vi])]
			lv.ri = 0
			lv._start_round()
			await frames(3)
			if lv.get("intro_block") != null:
				lv._intro_finish()
			ok(not lv.r.is_empty(), "%s 題目開始" % tag)
			var t := String(slot.type)
			if t == "speed":
				for k in 3:
					if lv.problems.is_empty() or lv.sp_i >= lv.problems.size():
						break
					if lv.problems[lv.sp_i].has("choices"):
						lv._speed_pick(int(lv.problems[lv.sp_i].correct))
					else:
						lv.slot_vals = lv.problems[lv.sp_i].get("answers", [lv.problems[lv.sp_i].ans]).duplicate()
						lv._fill_submit()
					await frames(2)
				ok(int(lv.get("streak")) > 0, "%s 速算答對有算分" % tag)
			elif lv.get("steps") != null and t == "forge":
				var guard := 0
				while lv.si < lv.steps.size() and guard < 40:
					guard += 1
					await shot("%s_%s_%d_%02d" % [lid, slot.id, vi, lv.si])
					lv._step_done(lv.steps[lv.si], "")
					await frames(2)
				ok(lv.si >= lv.steps.size(), "%s 推導題能走到最後一步（停在第 %d／%d 步）" % [tag, lv.si, lv.steps.size()])
			await shot("%s_%s_%d_end" % [lid, slot.id, vi])
	print("  %s：%d 種題型" % [lid, n_var])
