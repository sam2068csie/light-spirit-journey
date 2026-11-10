extends "res://data/levels/engine/level_core.gd"
## 所有關卡共用的引擎（指數與對數 L1～L8、多項式 P1～P8、三角函數 G1～G7 都繼承它）
##   ・流程：章節選單 → 題目列表 → 一段旅程（預言、各種操作、推導）→ 結算、星塵、章節寶箱
##   ・這個檔案：題目列表（完成度、解鎖、上一題／下一題）、一段旅程的結算、主線星塵與章節寶箱、觀念整理
##   ・一段旅程怎麼玩（題目、各種操作、計時、愛心、提示、光靈、新手教學）在 level_core.gd
## 一個大關＝繼承這個腳本，覆寫「這一大關的設定」那幾個函式（在 level_core.gd，例：level_01_light_bridge.gd）。
## 推導題型的大關改繼承 step_level.gd（它也繼承這個腳本）。


# ================= 題目列表（每段旅程的完成度與解鎖） =================



func _chapter_slots(ch: int) -> Array:
	return bank_slots().filter(func(sl): return sl.chapter == ch)


func _jkey(slot: Dictionary) -> String:
	return level_id() + "/" + slot.id


## 這段旅程有幾種題型答對過（0 ～ 1）
func _completion(slot: Dictionary) -> float:
	var n := 0
	for vi in Game.of(self).cleared_of(_jkey(slot)):
		if int(vi) < slot.variants.size():
			n += 1
	return float(n) / maxf(1.0, slot.variants.size())


func _chapter_completion(ch: int) -> float:
	var sl := _chapter_slots(ch)
	var sum := 0.0
	for slot in sl:
		sum += _completion(slot)
	return sum / maxf(1.0, sl.size())


## 第一題一開始就開放；之後每一題要等前一題答對過才解鎖
func _unlocked(slots: Array, i: int) -> bool:
	return i == 0 or Game.of(self).dev_unlock_all or not Game.of(self).cleared_of(_jkey(slots[i - 1])).is_empty()


func _show_journeys(ch: int) -> void:
	journey_mode = true
	chapter_now = ch
	chapter_slots = _chapter_slots(ch)
	for b in [go_btn, alt_btn, next_btn]:
		b.visible = false
	var item: Dictionary = level_chapters()[0]
	for it in level_chapters():
		if it.ch == ch:
			item = it
	var c: Color = item.color
	var o := _overlay(c, 1010)
	var layer: Control = o[0]
	layer.set_meta("journey_list", true)
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 12)
	col.add_child(_big_label(item.name, 30, c))
	col.add_child(_chest_status(ch, layer))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	col.add_child(grid)
	for i in chapter_slots.size():
		var open := _unlocked(chapter_slots, i)
		var card := _journey_card(chapter_slots[i], i, open, c)
		if open:
			var idx := i
			card.pressed.connect(func():
				layer.queue_free()
				_play_journey(ch, idx))
		grid.add_child(card)
	var back := UITheme.ghost_button("返回章節", 16)
	back.icon = UITheme.icon("back", 16, UITheme.TEXT_DIM)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func():
		layer.queue_free()
		_show_menu())
	col.add_child(back)
	# 第一次進入第二章：先看說明卡
	if ch == 2 and _chapter_completion(ch) == 0.0:
		_show_chapter_card()
	elif _chest_ready(ch):
		_open_chest(ch)      # 以前就全部通過、還沒開過寶箱的章節（更新前的存檔）
	elif _gold_ready(ch):
		_open_chest(ch, true)


## 一張旅程卡：編號、名稱、題型、最佳星數、完成度條；鎖住的卡片變暗
func _journey_card(slot: Dictionary, i: int, open: bool, c: Color) -> Button:
	var g = Game.of(self)
	var comp := _completion(slot)
	var full := comp >= 0.999
	var b := Button.new()
	b.custom_minimum_size = Vector2(228, 114)
	b.focus_mode = Control.FOCUS_NONE
	var edge := UITheme.ACCENT if full else (Color(c.r, c.g, c.b, 0.55) if open else Color(1, 1, 1, 0.08))
	var normal := UITheme.box(UITheme.PANEL_LIGHT if open else UITheme.PANEL, 14, edge, 2 if full else 1, 12)
	var hover := UITheme.box(UITheme.PANEL_LIGHT.lightened(0.1), 14, c, 2, 12)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover if open else normal)
	b.add_theme_stylebox_override("pressed", hover if open else normal)
	b.add_theme_stylebox_override("disabled", normal)
	if not open:
		b.disabled = true
		b.set_meta("silent", true)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top"]:
		m.add_theme_constant_override("margin_" + side, 12)
	m.add_theme_constant_override("margin_bottom", 18)     # 進度條和下邊框多留一點距離
	b.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	var num := Label.new()
	num.text = str(i + 1)
	num.custom_minimum_size = Vector2(28, 28)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", UITheme.fs(15))
	var nc := c if open else Color(0.42, 0.44, 0.56)
	num.add_theme_color_override("font_color", nc)
	var nb := UITheme.box(Color(nc.r, nc.g, nc.b, 0.14), 12, nc, 2, 0)
	nb.corner_detail = 16
	num.add_theme_stylebox_override("normal", nb)
	top.add_child(num)
	var name_l := Label.new()
	name_l.text = slot.title
	name_l.add_theme_font_size_override("font_size", UITheme.fs(17))
	name_l.add_theme_color_override("font_color", UITheme.TEXT if open else UITheme.TEXT_DIM)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.clip_text = true
	# 名字長（五個字以上）時字縮小一點，整個名字都放得下
	var nfs := UITheme.fs(17)
	var name_w := 228.0 - 24.0 - 28.0 - 8.0
	var nfont := name_l.get_theme_font("font")
	while nfs > UITheme.fs(13) and nfont.get_string_size(slot.title, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x > name_w:
		nfs -= 1
	name_l.add_theme_font_size_override("font_size", nfs)
	top.add_child(name_l)
	var tp := Label.new()
	tp.add_theme_font_size_override("font_size", UITheme.fs(13))
	tp.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	v.add_child(tp)
	if open:
		tp.text = slot.get("type_name", TYPE_NAMES.get(slot.type, "")) + ("　·　限時" if slot.has("time") else "")
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		v.add_child(row)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = 100
		bar.value = 100.0 * comp
		bar.custom_minimum_size = Vector2(0, 8)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.08), 4, Color(0, 0, 0, 0), 0, 0))
		bar.add_theme_stylebox_override("fill", UITheme.box(UITheme.ACCENT if full else c, 4, Color(0, 0, 0, 0), 0, 0))
		row.add_child(bar)
		var pct := Label.new()
		pct.text = "%d%%" % roundi(100.0 * comp)
		pct.custom_minimum_size = Vector2(44, 0)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pct.add_theme_font_size_override("font_size", UITheme.fs(15))
		pct.add_theme_color_override("font_color", UITheme.ACCENT if full else UITheme.TEXT)
		row.add_child(pct)
		# 星星放在進度條這一行最右邊，讓上面的名字可以用整行
		var best := int(g.stars.get(_jkey(slot), 0))
		var st := Label.new()
		st.text = _star_text(best, 3)
		st.add_theme_font_size_override("font_size", UITheme.fs(15))
		st.add_theme_color_override("font_color", UITheme.ACCENT if best > 0 else Color(1, 1, 1, 0.22))
		row.add_child(st)
	else:
		tp.text = "完成上一題解鎖"
		var lock := TextureRect.new()
		lock.texture = UITheme.icon("lock", 16, UITheme.TEXT_DIM)
		lock.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		lock.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		v.add_child(lock)
	for node in b.find_children("*", "Control", true, false):
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## 只玩一段旅程：優先抽還沒答對過的題型
func _play_journey(ch: int, i: int) -> void:
	journey_mode = true
	chapter_now = ch
	chapter_slots = _chapter_slots(ch)
	cur_slot_idx = i
	var slot: Dictionary = chapter_slots[i]
	var done: Array = Game.of(self).cleared_of(_jkey(slot))
	var cands := []
	for vi in slot.variants.size():
		if not done.has(vi):
			cands.append(vi)
	if cands.is_empty():
		cands = range(slot.variants.size())
	var total := 0.0
	for vi in cands:
		total += float(slot.variants[vi].get("weight", 1))
	var t := randf() * total
	var pick: int = cands.back()
	for vi in cands:
		t -= float(slot.variants[vi].get("weight", 1))
		if t <= 0.0:
			pick = vi
			break
	var rd := make_round(slot, slot.variants[pick])
	rd["vi"] = pick
	rounds = [rd]
	ri = 0
	score = 0
	total_stars = 0
	round_stars = 0
	_start_round()


## 從修煉之間進來：只玩指定的那一題
func _review_begin(a: Dictionary) -> void:
	var it: Dictionary = a.review
	review_mode = true
	review_i = int(a.get("review_i", 0))
	review_n = int(a.get("review_n", 1))
	review_kind = String(a.get("review_kind", "daily"))
	tower_mode = review_kind == "tower"
	tower_floor = int(a.get("tower_floor", 0))
	pause_menu.list_label = "放棄攀登" if tower_mode else "結束修煉"
	var slot: Dictionary = {}
	for sl in bank_slots():
		if sl.id == it.slot:
			slot = sl
	if slot.is_empty():
		Game.of(self).session_report(0)
		return
	var vi := clampi(int(it.vi), 0, slot.variants.size() - 1)
	journey_mode = false
	chapter_now = slot.chapter
	chapter_slots = _chapter_slots(slot.chapter)
	var rd := make_round(slot, slot.variants[vi])
	rd["vi"] = vi
	if tower_mode:
		rd["time"] = minf(float(rd.get("time", 999.0)), float(a.get("tower_time", 120.0)))
	rounds = [rd]
	ri = 0
	score = 0
	total_stars = 0
	_start_round()
	if tower_mode:
		energy = int(a.get("tower_hearts", 3))
		_update_hud()


## 上方白點兩側的「上一題／下一題」小按鈕
func _nav_q_button(text: String, tip: String) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(36, 36)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", UITheme.fs(24))
	b.add_theme_color_override("font_color", UITheme.TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.25))
	for st in [["normal", Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.12)],
			["hover", Color(1, 1, 1, 0.14), UITheme.CYAN.darkened(0.1)],
			["pressed", UITheme.CYAN.darkened(0.5), UITheme.CYAN],
			["disabled", Color(1, 1, 1, 0.03), Color(1, 1, 1, 0.06)]]:
		var sb := UITheme.box(st[1], 16, st[2], 1, 0)
		sb.corner_detail = 16
		b.add_theme_stylebox_override(st[0], sb)
	b.visible = false
	return b


func _update_q_nav() -> void:
	if prev_q_btn == null:
		return
	prev_q_btn.visible = journey_mode
	next_q_btn.visible = journey_mode
	if not journey_mode:
		return
	prev_q_btn.disabled = cur_slot_idx <= 0
	var has_next := cur_slot_idx + 1 < chapter_slots.size()
	var open := has_next and _unlocked(chapter_slots, cur_slot_idx + 1)
	next_q_btn.disabled = not open
	if open or not has_next:
		next_q_btn.text = "›"
		next_q_btn.icon = null
		next_q_btn.tooltip_text = "下一題" if has_next else "已經是最後一題"
	else:
		next_q_btn.text = ""
		next_q_btn.icon = UITheme.icon("lock", 14, Color(1, 1, 1, 0.45))
		next_q_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		next_q_btn.tooltip_text = "答對這一題才會解鎖下一題"


## 直接換到上一題／下一題（這一題目前的進度不保留）
func _jump_journey(d: int) -> void:
	if not journey_mode:
		return
	var i := cur_slot_idx + d
	if i < 0 or i >= chapter_slots.size() or not _unlocked(chapter_slots, i):
		return
	Game.of(self).play("blip", 1.1 if d > 0 else 0.9, -10.0)
	_close_modals()
	_play_journey(chapter_now, i)


## 關掉關卡畫面上開著的視窗（選單、結算、說明卡…）
func _close_modals() -> void:
	for c in get_children():
		if c is Control and c.get_child_count() == 2 and c.get_child(0) is ColorRect and c.get_child(1) is CenterContainer:
			c.queue_free()


## 暫停選單的「返回關卡列表」：停下這一題，回到這一章的題目列表
func _back_to_list() -> void:
	if tower_mode:
		Game.of(self).tower_abort()
		return
	if review_mode:
		Game.of(self).session_abort()
		return
	round_gen.bump()
	phase = Phase.END
	stage.running = false
	_close_modals()
	if journey_mode:
		_show_journeys(chapter_now)
	else:
		_show_menu()


func _finish_journey() -> void:
	var g = Game.of(self)
	var slot: Dictionary = chapter_slots[cur_slot_idx]
	var key := _jkey(slot)
	var has_next := cur_slot_idx + 1 < chapter_slots.size()
	var next_was_locked := has_next and not _unlocked(chapter_slots, cur_slot_idx + 1)
	var passed := round_stars > 0
	var new_type := false
	var rw := {"dust": 0, "lines": []}
	if passed:
		new_type = g.mark_cleared(key, int(r.get("vi", 0)))
		g.record_stars(key, round_stars)
		_record_level_stars()
		rw = g.journey_reward(key, int(r.get("vi", 0)), round_stars, slot.has("time"))
	var comp := _completion(slot)
	g.sfx("fanfare" if passed else "open")
	var item_color: Color = UITheme.ACCENT
	for it in level_chapters():
		if it.ch == chapter_now:
			item_color = it.color
	var o := UITheme.modal(self, item_color, 480)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(_big_label(slot.title, 30, UITheme.ACCENT))
	if passed:
		var big := _big_label(_star_text(round_stars, 3), 54, UITheme.ACCENT)
		big.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.1, 0.5))
		big.add_theme_constant_override("shadow_offset_y", 4)
		col.add_child(big)
	else:
		col.add_child(_big_label("這次是看示範過關的，再挑戰一次吧！", 18, UITheme.TEXT))
	if int(rw.dust) > 0:
		col.add_child(_reward_row({"dust": int(rw.dust)}, "（" + "、".join(rw.lines) + "）"))
		_dust_count_up(int(rw.dust))
	# 完成度
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	var cap := Label.new()
	cap.text = "完成度"
	cap.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	row.add_child(cap)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 100
	bar.value = 100.0 * comp
	bar.custom_minimum_size = Vector2(0, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.08), 6, Color(0, 0, 0, 0), 0, 0))
	bar.add_theme_stylebox_override("fill", UITheme.box(UITheme.ACCENT, 6, Color(0, 0, 0, 0), 0, 0))
	row.add_child(bar)
	var pct := Label.new()
	pct.text = "%d%%" % roundi(100.0 * comp)
	pct.add_theme_font_size_override("font_size", UITheme.fs(17))
	pct.add_theme_color_override("font_color", UITheme.ACCENT)
	row.add_child(pct)
	var left: int = slot.variants.size() - roundi(comp * slot.variants.size())
	var msg := ""
	if comp >= 0.999:
		msg = "這段旅程的每一種題型都答對了！"
	elif new_type:
		msg = "答對一種新題型！還有 %d 種等你挑戰。" % left
	else:
		msg = "還有 %d 種題型等你挑戰。" % left
	if next_was_locked and _unlocked(chapter_slots, cur_slot_idx + 1):
		msg += "\n解鎖下一題：「%s」" % chapter_slots[cur_slot_idx + 1].title
	var ml := _big_label(msg, 16, UITheme.TEXT)
	ml.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	ml.custom_minimum_size = Vector2(420, 0)
	col.add_child(ml)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	col.add_child(gap)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	col.add_child(btns)
	var mk := func(text: String, accent: bool, cb: Callable) -> Button:
		var bt := Button.new()
		bt.text = text
		bt.custom_minimum_size = Vector2(0, 50)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if accent:
			UITheme.accent_button(bt, 18)
		else:
			bt.add_theme_font_size_override("font_size", UITheme.fs(17))
		bt.pressed.connect(func():
			# 防呆：章節寶箱正要跳出來（或還沒開完）時先不離開，直接把寶箱叫出來，避免一按就錯過
			if _chest_showing:
				return
			if _chest_pending:
				_chest_pending = false
				_open_chest(chapter_now, _pending_gold)
				return
			layer.queue_free()
			cb.call())
		btns.add_child(bt)
		return bt
	var ch := chapter_now
	var idx := cur_slot_idx
	var can_next := has_next and _unlocked(chapter_slots, idx + 1)
	if can_next:
		mk.call("題目列表", false, func(): _show_journeys(ch))
		mk.call("再玩一次", not passed, func(): _play_journey(ch, idx))
		mk.call("下一題  ▶", true, func(): _play_journey(ch, idx + 1))
	else:
		# 這一章的最後一題：重玩在左、回到題目列表在右（往前走的方向）
		mk.call("再玩一次", not passed, func(): _play_journey(ch, idx))
		mk.call("回到題目列表  ▶", passed, func(): _show_journeys(ch))
	level_cleared.emit(round_stars)
	# 這一章的旅程全部通過了：打開章節大寶箱
	# 寶箱等 0.7 秒才跳出來；這段時間按結算的按鈕、暫停、返回鍵都會先開寶箱（_chest_pending）
	if passed and _chest_ready(ch):
		_chest_pending = true
		_pending_gold = false
		get_tree().create_timer(0.7).timeout.connect(func():
			var go := _chest_pending and is_instance_valid(layer)
			_chest_pending = false
			if go:
				_open_chest(ch))
	elif _gold_ready(ch):
		# 這一章所有題型都答對過了：打開章節黃金寶箱
		_chest_pending = true
		_pending_gold = true
		get_tree().create_timer(0.7).timeout.connect(func():
			var go := _chest_pending and is_instance_valid(layer)
			_chest_pending = false
			if go:
				_open_chest(ch, true))


## 回報問題用：現在是哪一關、哪一題、第幾種題型、第幾步
func _report_context() -> String:
	if r.is_empty():
		return "%s %s（選單）" % [level_id(), level_title()]
	var parts := PackedStringArray([level_id() + " " + level_title(), "旅程 %s「%s」" % [r.get("id", "?"), r.get("title", "")],
		"題型 %d" % (int(r.get("vi", 0)) + 1)])
	var st = get("si")
	if st != null and r.get("type", "") == "forge":
		parts.append("第 %d 步" % (int(st) + 1))
	if tower_mode:
		parts.append("終焉之塔第 %d 層" % tower_floor)
	var eq := String(r.get("eq", "")).replace("\n", " ").replace("表|", "").replace("|", " ")     # 表格寫法換成一般文字
	if eq != "":
		parts.append("題目：" + eq.left(80))
	return "，".join(parts)


# ================= 主線獎勵：星塵與章節大寶箱 =================

func _chest_key(ch: int) -> String:
	return level_id() + "_c%d" % ch


func _chest_final(ch: int) -> bool:
	var chs := level_chapters()
	return not chs.is_empty() and int(chs.back().ch) == ch


## 這一章的每段旅程都至少通過一次
func _chapter_all_cleared(ch: int) -> bool:
	var g = Game.of(self)
	for slot in _chapter_slots(ch):
		if g.cleared_of(_jkey(slot)).is_empty():
			return false
	return true


func _chest_ready(ch: int) -> bool:
	return not review_mode and _chapter_all_cleared(ch) and not Game.of(self).chest_claimed(_chest_key(ch))


## 章節黃金寶箱：這一章完成度 100%（每段旅程的每一種題型都答對過）
func _gold_key(ch: int) -> String:
	return _chest_key(ch) + "_gold"


func _gold_ready(ch: int) -> bool:
	return not review_mode and _chapter_completion(ch) >= 0.999 and not Game.of(self).chest_claimed(_gold_key(ch))


## 一排物品：圖示＋數量（例如 星塵 ×200、光之碎片 ×30）；note 是小字說明
func _reward_row(got: Dictionary, note: String = "") -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	var names := {"dust": "星塵", "shard": "光之碎片", "crystal": "光之結晶"}
	for k in ["dust", "shard", "crystal"]:
		if not got.has(k):
			continue
		var ic := QP.ItemIcon.new()
		ic.kind = k
		ic.custom_minimum_size = Vector2(30, 30)
		row.add_child(ic)
		var l := Label.new()
		l.text = "%s +%d　" % [names[k], int(got[k])]
		l.add_theme_font_override("font", UITheme.bold_font())
		l.add_theme_font_size_override("font_size", UITheme.fs(20))
		l.add_theme_color_override("font_color", UITheme.ACCENT if k == "dust" else (UITheme.CYAN_LIGHT if k == "shard" else UITheme.VIOLET_LIGHT))
		row.add_child(l)
	if note != "":
		v.add_child(_big_label(note, 13, UITheme.TEXT_DIM))
	return v


## 右上角的星塵數字從舊的值跳到新的值
func _dust_count_up(gain: int) -> void:
	var to := int(Game.of(self).inv.dust)
	var from := to - gain
	_dust_anim = true
	score_label.text = str(from)
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_method(func(v: float): score_label.text = str(int(round(v))), float(from), float(to), 0.8)
	tw.parallel().tween_property(score_label, "scale", Vector2(1.25, 1.25), 0.2)
	tw.tween_property(score_label, "scale", Vector2.ONE, 0.2)
	tw.tween_callback(func(): _dust_anim = false)
	score_label.pivot_offset = score_label.size / 2.0


## 題目列表上方：這一章的寶箱狀態
func _chest_status(ch: int, list_layer: Control) -> Control:
	# 兩個寶箱排在同一行，省下垂直空間（題目列表才不會超出畫面）
	var v := HBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 28)
	v.add_child(_chest_status_row(ch, false))
	v.add_child(_chest_status_row(ch, true))
	return v


func _chest_status_row(ch: int, gold: bool) -> Control:
	var g = Game.of(self)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var ic := QP.ItemIcon.new()
	ic.kind = "chest"
	ic.custom_minimum_size = Vector2(34, 34)
	row.add_child(ic)
	if gold:
		ic.modulate = Color(1.0, 0.85, 0.3)
		var gl := Label.new()
		gl.add_theme_font_size_override("font_size", UITheme.fs(15))
		var pc := roundi(100.0 * _chapter_completion(ch))
		if g.chest_claimed(_gold_key(ch)):
			gl.text = "章節黃金寶箱　已打開 ✓"
			gl.add_theme_color_override("font_color", UITheme.GOOD)
			ic.modulate = Color(1.0, 0.85, 0.3, 0.45)
		else:
			gl.text = "章節黃金寶箱：完成度 %d%%／100%%" % pc
			gl.add_theme_color_override("font_color", Color("ffd36e") if pc >= 100 else UITheme.TEXT_DIM)
		row.add_child(gl)
		return row
	var sl := _chapter_slots(ch)
	var done := 0
	for slot in sl:
		if not g.cleared_of(_jkey(slot)).is_empty():
			done += 1
	var l := Label.new()
	l.add_theme_font_size_override("font_size", UITheme.fs(15))
	if g.chest_claimed(_chest_key(ch)):
		l.text = "章節大寶箱　已打開 ✓"
		l.add_theme_color_override("font_color", UITheme.GOOD)
		ic.modulate = Color(1, 1, 1, 0.45)
	else:
		l.text = "章節大寶箱：通過 %d／%d 段旅程" % [done, sl.size()]
		l.add_theme_color_override("font_color", UITheme.ACCENT if done >= sl.size() else UITheme.TEXT_DIM)
	row.add_child(l)
	return row




## 章節大寶箱：寶箱跳一跳 → 點「打開」→ 東西飛出來、加進持有物品（狀態變數 _chest_showing 等在 level_core.gd）
func _open_chest(ch: int, gold := false) -> void:
	var g = Game.of(self)
	if _chest_showing or not (_gold_ready(ch) if gold else _chest_ready(ch)):
		return
	_chest_showing = true
	var item_name := level_title()
	var c: Color = UITheme.ACCENT
	for it in level_chapters():
		if it.ch == ch:
			item_name = it.name
			c = it.color
	g.sfx("open")
	var o := UITheme.modal(self, c, 440)
	var layer: Control = o[0]
	layer.tree_exited.connect(func(): _chest_showing = false)
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(_big_label(item_name, 26, c))
	col.add_child(_big_label("完成度 100%！獲得章節黃金寶箱" if gold else "全部通過！獲得章節大寶箱", 17, Color("ffd36e") if gold else UITheme.TEXT))
	var holder := CenterContainer.new()
	col.add_child(holder)
	var box := ChestFx.new()
	box.custom_minimum_size = Vector2(400, 190)
	box.glow = c
	box.gold = gold
	holder.add_child(box)
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(0, 52)
	col.add_child(info)
	var btn := Button.new()
	btn.text = "打開寶箱！"
	btn.custom_minimum_size = Vector2(240, 54)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UITheme.accent_button(btn, 19)
	col.add_child(btn)
	var state := [0]      # 0 還沒開、1 動畫中、2 開好了
	box.tapped.connect(func():
		if state[0] == 0:
			btn.pressed.emit())
	btn.pressed.connect(func():
		if state[0] == 2:
			layer.queue_free()
			_chest_showing = false
			_refresh_journey_list(ch)
			if not gold and _gold_ready(ch):
				_open_chest(ch, true)      # 一次就 100%：大寶箱之後接著開黃金寶箱
			return
		if state[0] == 1:
			return
		state[0] = 1
		btn.disabled = true
		var got: Dictionary = g.claim_chest(_gold_key(ch) if gold else _chest_key(ch), _chest_final(ch), gold)
		# 1) 寶箱抖三下（音越來越高）
		for i in 3:
			g.play("bell", Game.semi(Game.scale_semi(2 + i * 2)), -10.0, 0.18 * i)
		box.shake_open(func():
			# 2) 蓋子彈開、光芒和星星噴出來
			g.sfx("fanfare")
			# 3) 物品一個一個跳出來
			var row := _reward_row(got, "可以到扭蛋機抽裝扮、或到碎片兌換所換指定的裝扮")
			info.add_child(row)
			_pop_in_row(row)
			if got.has("dust"):
				_dust_count_up(int(got.dust))
			btn.disabled = false
			btn.text = "收下"
			state[0] = 2))


## 獎勵那一排：每個物品依序從小彈到正常大小
func _pop_in_row(row: Control) -> void:
	var items: Array = []
	var line: Node = row.get_child(0)
	for n in line.get_children():
		items.append(n)
	for i in items.size():
		var n: Control = items[i]
		n.modulate.a = 0.0
		var tw := n.create_tween()
		tw.tween_interval(0.12 * int(i / 2))
		tw.tween_callback(func():
			n.pivot_offset = n.size / 2.0
			n.scale = Vector2(0.3, 0.3)
			if i % 2 == 0:
				Game.of(self).play("bell", Game.semi(Game.scale_semi(5 + i)), -12.0))
		tw.tween_property(n, "modulate:a", 1.0, 0.12)
		tw.parallel().tween_property(n, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if row.get_child_count() > 1:
		var note: Control = row.get_child(1)
		note.modulate.a = 0.0
		note.create_tween().tween_property(note, "modulate:a", 1.0, 0.4).set_delay(0.5)




## 寶箱打開後，題目列表上的寶箱狀態跟著更新（列表開著的話重開一次）
func _refresh_journey_list(ch: int) -> void:
	for n in get_children():
		if n.has_meta("journey_list"):
			n.queue_free()
			_show_journeys.call_deferred(ch)
			return


## 章節星數 = 這一章每段旅程最佳星數的平均；大關星數 = 各章平均（都無條件捨去）
func _record_level_stars() -> void:
	var g = Game.of(self)
	var lid := level_id()
	var sum_ch := 0
	for item in level_chapters():
		var sl := _chapter_slots(item.ch)
		var sum := 0
		for slot in sl:
			sum += int(g.stars.get(_jkey(slot), 0))
		var ch_stars := int(floor(float(sum) / maxf(1.0, sl.size())))
		g.record_stars(lid + "_c%d" % item.ch, ch_stars)
		sum_ch += int(g.stars.get(lid + "_c%d" % item.ch, 0))
	g.record_stars(lid, int(floor(float(sum_ch) / level_chapters().size())))


# ================= 結算畫面 =================

func _finish() -> void:
	var max_stars := rounds.size() * 3
	var stars := 3 if total_stars >= max_stars * 0.85 else (2 if total_stars >= max_stars * 0.6 else 1)
	var g = Game.of(self)
	var lid := level_id()
	g.record_stars(lid + "_c%d" % chapter_now, stars)
	# 關卡列表上顯示的星數 = 各章最佳星數的平均（無條件捨去）
	var sum := 0
	for item in level_chapters():
		sum += int(g.stars.get(lid + "_c%d" % item.ch, 0))
	g.record_stars(lid, int(floor(float(sum) / level_chapters().size())))
	g.sfx("fanfare")
	var chapter_name := level_title()
	for item in level_chapters():
		if item.ch == chapter_now:
			chapter_name = item.name
	var o := UITheme.modal(self, UITheme.ACCENT, 460)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(_big_label(chapter_name, 30, UITheme.ACCENT))
	col.add_child(_big_label("完成！", 18, UITheme.TEXT_DIM))
	var big := _big_label(_star_text(stars, 3), 60, UITheme.ACCENT)
	big.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.1, 0.5))
	big.add_theme_constant_override("shadow_offset_x", 0)
	big.add_theme_constant_override("shadow_offset_y", 4)
	col.add_child(big)
	var info := _big_label("收集星星 %d / %d　·　總分 %d" % [total_stars, max_stars, score], 17, UITheme.TEXT)
	col.add_child(info)
	var qm = get_node_or_null("/root/QuizManager")
	if qm:
		var weak: Array = qm.weakest(2)
		if not weak.is_empty():
			var names := PackedStringArray()
			for item in weak:
				names.append(item.name)
			var w := _big_label("可以再加強\n" + "、".join(names), 15, UITheme.TEXT_DIM)
			w.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
			w.custom_minimum_size = Vector2(400, 0)
			col.add_child(w)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	col.add_child(gap)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var again := Button.new()
	again.text = "再挑戰一次"
	again.custom_minimum_size = Vector2(0, 52)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.add_theme_font_size_override("font_size", UITheme.fs(17))
	again.pressed.connect(func():
		layer.queue_free()
		_begin(chapter_now))
	row.add_child(again)
	var back := Button.new()
	back.text = "選擇章節"
	back.custom_minimum_size = Vector2(0, 52)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.accent_button(back, 19)
	back.pressed.connect(func():
		layer.queue_free()
		_show_menu())
	row.add_child(back)
	level_cleared.emit(stars)


func _record(tag: String) -> void:
	Game.of(self).record_mistake(tag)     # 錯題本（修煉之間用）
	if tower_mode and not busy:
		# 終焉之塔：每答錯一次就扣一顆心
		_recorded_frame = Engine.get_process_frames()
		energy -= 1
		_update_hud()
		if energy <= 0:
			call_deferred("_tower_out")
	var qm = get_node_or_null("/root/QuizManager")
	if qm:
		qm.record_mistake(tag)


# ================= 觀念整理（章節選單上方） =================

## 這一大關的觀念卡片（後面的關卡會自動用自己的 level_id）
func concept_cards() -> Array:
	return Concepts.cards(level_id())


func _concept_color() -> Color:
	var chs := level_chapters()
	return chs[0].color if not chs.is_empty() else UITheme.ACCENT


func _concept_button() -> Button:
	var c := _concept_color()
	var b := Button.new()
	b.custom_minimum_size = Vector2(440, 78)
	b.focus_mode = Control.FOCUS_NONE
	var normal := UITheme.box(Color(c.r, c.g, c.b, 0.12), 14, Color(c.r, c.g, c.b, 0.55), 2, 14)
	var hover := UITheme.box(Color(c.r, c.g, c.b, 0.22), 14, c, 2, 14)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18
	row.offset_right = -18
	row.offset_top = 10        # 文字和上下邊框留一點距離
	row.offset_bottom = -10
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	var ic := ConceptIcon.new()
	ic.color = c
	ic.custom_minimum_size = Vector2(34, 34)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(ic)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	var t := Label.new()
	t.text = "觀念整理"
	t.add_theme_font_size_override("font_size", UITheme.fs(20))
	t.add_theme_color_override("font_color", c.lightened(0.25))
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(t)
	var sub := Label.new()
	var done := 0
	var g = Game.of(self)
	for cd in concept_cards():
		if g != null and (g.concepts as Dictionary).has("%s|%s" % [level_id(), String(cd.title)]):
			done += 1
	sub.text = "拖積木填空、隨堂小測：%d 張卡片（已完成 %d 張）" % [concept_cards().size(), done]
	sub.add_theme_font_size_override("font_size", UITheme.fs(13))
	sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(sub)
	var go := Label.new()
	go.text = "▶"
	go.add_theme_font_size_override("font_size", UITheme.fs(17))
	go.add_theme_color_override("font_color", c)
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	go.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(go)
	return b




func _show_concepts(idx: int = -1) -> void:
	var c := _concept_color()
	var o := UITheme.modal(self, Color(c.r, c.g, c.b, 0.5), 1110, true, false)   # 觀念卡片自己會縮放，不用捲動
	Game.of(self).sfx("open")
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	var deck := ConceptDeck.new()
	deck.setup(level_title(), concept_cards(), c, _concept_progress, idx, level_id())
	deck.closed.connect(func(_start: bool):
		layer.queue_free()
		_show_menu())
	col.add_child(deck)
