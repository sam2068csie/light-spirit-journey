extends Control
## 光靈扭蛋機（整個畫面）：左邊是扭蛋機，右邊是抽法、保底、衣櫃／機率／圖鑑
## 抽的流程：把手轉一圈 → 扭蛋掉到出口 → 開蛋畫面（殼的顏色先透露稀有度）→ 光靈穿上新裝扮的樣子
## 用法：var p := GachaPage.new(); add_child(p)；關掉時送 closed

signal closed

const UITheme := preload("game_theme.gd")
const Game := preload("game.gd")
const Cos := preload("cosmetics.gd")
const SL := preload("spirit_look.gd")
const QP := preload("quest_panel.gd")
const Wardrobe := preload("wardrobe.gd")
const Exchange := preload("exchange.gd")

var _machine: Machine
var _hold: HBoxContainer
var _btn_one: Button
var _btn_ten: Button
var _btn_shine: Button
var _pity_label: Label
var _pity_bar: ProgressBar
var _ssr_label: Label
var _book_label: Label
var _busy := false
var _reveal: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := Bg.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var back := UITheme.ghost_button("返回", 18)
	back.icon = UITheme.icon("back", 18, UITheme.TEXT_DIM)
	back.custom_minimum_size = Vector2(96, 44)
	back.position = Vector2(16, 14)
	back.pressed.connect(_close)
	add_child(back)
	var title := UITheme.title_label("光靈扭蛋機", 30, UITheme.ACCENT)
	title.position = Vector2(376, 14)
	title.size = Vector2(400, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	_hold = HBoxContainer.new()
	_hold.add_theme_constant_override("separation", 6)
	_hold.position = Vector2(880, 22)
	add_child(_hold)

	_machine = Machine.new()
	_machine.position = Vector2(40, 74)
	_machine.size = Vector2(460, 560)
	add_child(_machine)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.box(Color(0.08, 0.08, 0.2, 0.9), 18, Color(1, 1, 1, 0.12), 1, 20))
	card.position = Vector2(530, 78)
	card.custom_minimum_size = Vector2(590, 548)
	add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)

	# 本期主打：兩件傳說
	var feat := Label.new()
	feat.text = "本期：光靈初登場　★ 傳說裝扮"
	feat.add_theme_font_override("font", UITheme.bold_font())
	feat.add_theme_font_size_override("font_size", UITheme.fs(18))
	feat.add_theme_color_override("font_color", Cos.RARITY[3].color)
	col.add_child(feat)
	var fr := HBoxContainer.new()
	fr.add_theme_constant_override("separation", 12)
	col.add_child(fr)
	for it in _featured():
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", UITheme.box(Color(1, 0.81, 0.35, 0.08), 14, Color(1, 0.81, 0.35, 0.45), 1, 8))
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fr.add_child(box)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		box.add_child(h)
		var pv := SL.Preview.new()
		pv.eq = {it.cat: it.id}
		pv.radius = 20.0
		pv.custom_minimum_size = Vector2(96, 92)
		h.add_child(pv)
		var nv := VBoxContainer.new()
		nv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(nv)
		var nl := Label.new()
		nl.text = it.name
		nl.add_theme_font_override("font", UITheme.bold_font())
		nl.add_theme_font_size_override("font_size", UITheme.fs(17))
		nl.add_theme_color_override("font_color", Cos.RARITY[3].color)
		nv.add_child(nl)
		var cl := Label.new()
		cl.text = "傳說・" + _cat_name(it.cat)
		cl.add_theme_font_size_override("font_size", UITheme.fs(13))
		cl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		nv.add_child(cl)

	# 保底
	var pv2 := VBoxContainer.new()
	pv2.add_theme_constant_override("separation", 4)
	col.add_child(pv2)
	_pity_label = Label.new()
	_pity_label.add_theme_font_size_override("font_size", UITheme.fs(15))
	pv2.add_child(_pity_label)
	_pity_bar = ProgressBar.new()
	_pity_bar.show_percentage = false
	_pity_bar.max_value = Cos.PITY_SR
	_pity_bar.custom_minimum_size = Vector2(0, 10)
	_pity_bar.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.08), 5, Color(0, 0, 0, 0), 0, 0))
	_pity_bar.add_theme_stylebox_override("fill", UITheme.box(Cos.RARITY[2].color, 5, Color(0, 0, 0, 0), 0, 0))
	pv2.add_child(_pity_bar)
	_ssr_label = Label.new()
	_ssr_label.add_theme_font_size_override("font_size", UITheme.fs(13))
	_ssr_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	pv2.add_child(_ssr_label)

	# 三種抽法
	var br := HBoxContainer.new()
	br.add_theme_constant_override("separation", 12)
	col.add_child(br)
	_btn_one = _pull_button(br, UITheme.ACCENT, Color("c27a14"), Color("3a2306"))
	_btn_one.pressed.connect(func(): _pull("one"))
	_btn_ten = _pull_button(br, Color("8f6bff"), Color("4b2fa8"), Color.WHITE)
	_btn_ten.pressed.connect(func(): _pull("ten"))
	_btn_shine = _pull_button(br, Color("5ad8ff"), Color("1f7fa8"), Color("082436"))
	_btn_shine.pressed.connect(func(): _pull("shine"))
	var note := Label.new()
	note.text = "十連保證至少一個稀有；閃光抽保證史詩以上。重複的裝扮會變成光之碎片。"
	note.add_theme_font_size_override("font_size", UITheme.fs(13))
	note.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(sp)
	# 衣櫃、機率、圖鑑
	var lr := HBoxContainer.new()
	lr.add_theme_constant_override("separation", 10)
	col.add_child(lr)
	var wb := Button.new()
	wb.text = "衣櫃"
	wb.custom_minimum_size = Vector2(120, 50)
	UITheme.button_3d(wb, Color("3d46a8"), Color("191b52"), UITheme.TEXT, 18, 6, 14, 6)
	wb.pressed.connect(_open_wardrobe)
	lr.add_child(wb)
	var xb := Button.new()
	xb.text = "碎片兌換所"
	xb.custom_minimum_size = Vector2(150, 50)
	UITheme.button_3d(xb, Color("1f7fa8"), Color("0d3a52"), UITheme.TEXT, 16, 6, 14, 6)
	xb.pressed.connect(_open_exchange)
	lr.add_child(xb)
	var rb := Button.new()
	rb.text = "機率說明"
	rb.custom_minimum_size = Vector2(120, 50)
	UITheme.button_3d(rb, Color("2c3170"), Color("15183f"), UITheme.TEXT, 16, 6, 14, 6)
	rb.pressed.connect(_open_rates)
	lr.add_child(rb)
	_book_label = Label.new()
	_book_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_book_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_book_label.add_theme_font_size_override("font_size", UITheme.fs(16))
	_book_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	lr.add_child(_book_label)

	_refresh()


## 本期主打：四件傳說裡挑兩件，每天輪換
func _featured() -> Array:
	var ss: Array = Cos.items_of_rarity(3)
	var day_n := int(floor(Time.get_unix_time_from_system() / 86400.0))
	var k := posmod(day_n, ss.size())
	return [ss[k], ss[(k + 1) % ss.size()]]


func _cat_name(cat: String) -> String:
	for c in Cos.CATS:
		if c.id == cat:
			return c.name
	return ""


func _pull_button(parent: Control, face: Color, lip: Color, ink: Color) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 76)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.button_3d(b, face, lip, ink, 17, 7, 16, 6)
	parent.add_child(b)
	return b


func _refresh() -> void:
	var g = Game.of(self)
	for c in _hold.get_children():
		c.queue_free()
	for k in ["dust", "shard", "crystal"]:
		var ii := QP.ItemIcon.new()
		ii.kind = k
		ii.custom_minimum_size = Vector2(24, 24)
		ii.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_hold.add_child(ii)
		var n := Label.new()
		n.text = str(int(g.inv.get(k, 0)))
		n.add_theme_font_size_override("font_size", UITheme.fs(16))
		n.custom_minimum_size = Vector2(40, 0)
		_hold.add_child(n)
	var c1: Dictionary = g.gacha_cost("one")
	_btn_one.text = ("單抽（今日首抽半價）\n✦ %d" if g.gacha_half_ready() else "單抽\n✦ %d") % int(c1.amt)
	_btn_ten.text = "十連\n✦ %d" % Cos.COST_TEN
	_btn_shine.text = "閃光抽\n◇ 光之結晶 %d" % Cos.COST_SHINE
	_btn_one.disabled = not g.gacha_can("one")
	_btn_ten.disabled = not g.gacha_can("ten")
	_btn_shine.disabled = not g.gacha_can("shine")
	var left: int = Cos.PITY_SR - int(g.gacha.pity_sr)
	_pity_label.text = "再 %d 抽，必得史詩以上" % left
	_pity_bar.value = int(g.gacha.pity_sr)
	_ssr_label.text = "傳說保底：再 %d 抽必得傳說　（已經抽了 %d 次）" % [Cos.PITY_SSR - int(g.gacha.pity_ssr), int(g.gacha.pulls)]
	_book_label.text = "圖鑑 %d / %d" % [g.owned.size(), Cos.ITEMS.size()]


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _reveal != null and is_instance_valid(_reveal):
			return
		_close()


func _close() -> void:
	if _busy:
		return
	closed.emit()
	queue_free()


# ---------- 抽 ----------

func _pull(kind: String) -> void:
	if _busy:
		return
	var g = Game.of(self)
	var res: Array = g.gacha_pull(kind)
	if res.is_empty():
		return
	_busy = true
	_refresh()
	var best := 0
	for r in res:
		best = maxi(best, int(r.r))
	g.sfx("open")
	await _machine.play(best, kind == "shine")
	_busy = false
	_show_reveal(res)


func _show_reveal(res: Array) -> void:
	_reveal = Reveal.new()
	_reveal.results = res
	add_child(_reveal)
	_reveal.done.connect(func():
		_reveal = null
		_refresh())


func _open_exchange() -> void:
	var w := Exchange.new()
	add_child(w)
	w.closed.connect(_refresh)


func _open_wardrobe() -> void:
	var w := Wardrobe.new()
	add_child(w)
	w.closed.connect(_refresh)


func _open_rates() -> void:
	var o := UITheme.modal(self, Color(1, 1, 1, 0.3), 520)
	var layer: Control = o[0]
	var c: VBoxContainer = o[1]
	c.add_theme_constant_override("separation", 8)
	c.add_child(UITheme.title_label("機率說明", 24, UITheme.ACCENT))
	for r in 4:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		c.add_child(row)
		var nl := Label.new()
		nl.text = "%s　%.1f%%" % [Cos.RARITY[r].name, Cos.RARITY[r].rate * 100.0]
		nl.custom_minimum_size = Vector2(120, 0)
		nl.add_theme_color_override("font_color", Cos.RARITY[r].color)
		nl.add_theme_font_size_override("font_size", UITheme.fs(16))
		row.add_child(nl)
		# 只寫件數和每件的機率（全部名稱太長了；想看有哪些可以去衣櫃）
		var n: int = Cos.items_of_rarity(r).size()
		var il := Label.new()
		il.text = "共 %d 件，每件約 %.2f%%" % [n, Cos.RARITY[r].rate * 100.0 / maxf(1.0, n)]
		il.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		il.add_theme_font_size_override("font_size", UITheme.fs(15))
		il.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		row.add_child(il)
	var rules := Label.new()
	rules.text = "・同一稀有度裡每件機率相同\n・連續 %d 抽沒出史詩以上，第 %d 抽保證史詩\n・連續 %d 抽沒出傳說，第 %d 抽保證傳說\n・重複的裝扮變成光之碎片：普通 5、稀有 15、史詩 50、傳說 150\n・全部的裝扮可以在衣櫃裡看到" % [Cos.PITY_SR, Cos.PITY_SR, Cos.PITY_SSR, Cos.PITY_SSR]
	rules.add_theme_font_size_override("font_size", UITheme.fs(15))
	rules.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	c.add_child(rules)
	var ok := Button.new()
	ok.text = "知道了"
	ok.custom_minimum_size = Vector2(200, 50)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UITheme.accent_button(ok, 18)
	ok.pressed.connect(func(): layer.queue_free())
	c.add_child(ok)


# ================= 背景 =================

class Bg extends Control:
	const UITheme := preload("game_theme.gd")

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("120f2e"))
		UITheme.dot(self, Vector2(270, 330), 330.0, Color(0.55, 0.35, 1.0, 0.06))
		UITheme.dot(self, Vector2(270, 330), 210.0, Color(1.0, 0.8, 0.4, 0.05))
		for i in 60:
			var p := Vector2(fposmod(i * 0.7548777, 1.0) * size.x, fposmod(i * 0.5698403 + 0.11, 1.0) * size.y)
			UITheme.dot(self, p, 0.8 + fposmod(i * 0.29, 1.0) * 1.2, Color(1, 1, 1, 0.12 + 0.2 * fposmod(i * 0.37, 1.0)))


# ================= 扭蛋機 =================

class Machine extends Control:
	const UITheme := preload("game_theme.gd")
	const Cos := preload("cosmetics.gd")
	const CAP_COLS := [Color("ff7eb6"), Color("5ad8ff"), Color("a6f05a"), Color("ffcf5a"), Color("c792ff"), Color("ffb454")]
	var t := 0.0
	var crank := 0.0          # 把手角度
	var shake := 0.0          # 玻璃罩裡的扭蛋晃多大
	var drop := -1.0          # 掉出來的扭蛋：-1 沒有；0～1 掉落中；之後停在出口
	var drop_col := Color.WHITE
	var _caps: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 16:
			var a := rng.randf() * TAU
			var d := sqrt(rng.randf()) * 120.0
			_caps.append({"p": Vector2(cos(a) * d, sin(a) * d * 0.8 + 30.0), "c": CAP_COLS[i % CAP_COLS.size()],
				"ph": rng.randf() * TAU, "rot": rng.randf() * TAU})

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	## 播一次：轉把手 → 扭蛋晃 → 掉一顆出來（顏色 = 這次最好的稀有度）
	func play(best: int, shine: bool) -> void:
		drop = -1.0
		drop_col = Cos.RARITY[best].color if best > 0 else Color(0.92, 0.93, 1.0)
		var g = preload("game.gd").of(self)
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "crank", crank + TAU, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(self, "shake", 1.0, 0.3)
		for k in 4:
			g.play("blip", 0.9 + 0.15 * k, -10.0, 0.2 * k)
		await tw.finished
		var tw2 := create_tween()
		tw2.tween_property(self, "shake", 0.0, 0.3)
		drop = 0.0
		var tw3 := create_tween()
		tw3.tween_property(self, "drop", 1.0, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		await tw3.finished
		g.sfx("success" if best < 2 else "fanfare")
		await get_tree().create_timer(0.35 if not shine else 0.5).timeout

	func _draw() -> void:
		var cx := size.x / 2.0
		var dome_c := Vector2(cx, 190)
		var R := 160.0
		# 底座（後面）
		var base_top := 300.0
		var base := PackedVector2Array([Vector2(cx - 150, base_top), Vector2(cx + 150, base_top), Vector2(cx + 175, 520), Vector2(cx - 175, 520)])
		draw_colored_polygon(PackedVector2Array([base[0] + Vector2(0, 10), base[1] + Vector2(0, 10), base[2] + Vector2(0, 14), base[3] + Vector2(0, 14)]), Color("8e2a63"))
		draw_colored_polygon(base, Color("e05a9a"))
		draw_rect(Rect2(cx - 175, 505, 350, 20), Color("6a1f4a"))
		draw_rect(Rect2(cx - 150, base_top, 300, 18), Color("ff8fc0"))
		# 玻璃罩＋扭蛋
		UITheme.dot(self, dome_c, R, Color(0.75, 0.88, 1.0, 0.10))
		for cp in _caps:
			var wob := Vector2(sin(t * 1.3 + cp.ph), cos(t * 1.1 + cp.ph)) * 2.0
			var sh := Vector2(sin(t * 23.0 + cp.ph * 3.0), cos(t * 19.0 + cp.ph)) * 10.0 * shake
			_capsule(dome_c + cp.p + wob + sh, 26.0, cp.c, cp.rot + shake * t * 6.0)
		draw_arc(dome_c, R + 5.0, 0, TAU, 96, Color("ff8fc0"), 10.0, true)
		draw_arc(dome_c, R, 0, TAU, 72, Color(1, 1, 1, 0.35), 3.0, true)
		draw_arc(dome_c + Vector2(-50, -50), R * 0.55, PI * 1.05, PI * 1.45, 16, Color(1, 1, 1, 0.5), 6.0, true)
		# 正面：投幣口、出口、把手
		var font := get_theme_default_font()
		draw_string(font, Vector2(cx - 150, 360), "✦ 光靈扭蛋 ✦", HORIZONTAL_ALIGNMENT_CENTER, 300, UITheme.fs(20), Color(1, 1, 1, 0.92))
		var outlet := Rect2(cx - 120, 410, 110, 80)
		draw_style_box(UITheme.boxc(Color("3a0f2a"), 16, Color("ff8fc0"), 3, 0), outlet)
		var knob := Vector2(cx + 85, 450)
		UITheme.dot(self, knob, 46.0, Color("ffcf5a"))
		UITheme.dot(self, knob, 38.0, Color("f4b532"))
		var hd := Vector2(cos(crank), sin(crank))
		draw_line(knob - hd * 34.0, knob + hd * 34.0, Color("8a5a10"), 12.0, true)
		UITheme.dot(self, knob + hd * 34.0, 9.0, Color("fff3c4"))
		UITheme.dot(self, knob, 8.0, Color("8a5a10"))
		# 掉出來的扭蛋
		if drop >= 0.0:
			var y := lerpf(330.0, outlet.position.y + outlet.size.y - 34.0, clampf(drop, 0.0, 1.0))
			var glow := 0.5 + 0.5 * sin(t * 6.0)
			UITheme.dot(self, Vector2(outlet.get_center().x, y), 44.0, Color(drop_col.r, drop_col.g, drop_col.b, 0.18 + 0.15 * glow))
			_capsule(Vector2(outlet.get_center().x, y), 30.0, drop_col, 0.3)

	func _capsule(p: Vector2, r: float, col: Color, rot: float) -> void:
		var top := PackedVector2Array()
		var bot := PackedVector2Array()
		for k in 13:
			var a := rot + PI * k / 12.0
			top.append(p + Vector2(cos(a + PI), sin(a + PI)) * r)
			bot.append(p + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(top, col)
		draw_colored_polygon(bot, Color(0.96, 0.96, 1.0))
		draw_arc(p, r, 0, TAU, 26, col.darkened(0.35), 2.0, true)
		draw_line(p + Vector2(cos(rot), sin(rot)) * r, p - Vector2(cos(rot), sin(rot)) * r, col.darkened(0.35), 2.0, true)
		UITheme.dot(self, p + Vector2(-r * 0.35, -r * 0.4), r * 0.16, Color(1, 1, 1, 0.6))


# ================= 開蛋畫面 =================

class Reveal extends Control:
	signal done
	const UITheme := preload("game_theme.gd")
	const Cos := preload("cosmetics.gd")
	const SL := preload("spirit_look.gd")
	var results: Array = []
	var _box: Control
	var _ten_cards: Array = []
	var _opened := 0

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var dim := ColorRect.new()
		dim.color = Color(0.02, 0.02, 0.07, 0.86)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		if results.size() == 1:
			_single(results[0])
		else:
			_ten()

	# ----- 單抽：大扭蛋晃一晃 → 打開 → 卡片 -----
	func _single(res: Dictionary) -> void:
		var cap := BigCapsule.new()
		cap.col = Cos.RARITY[int(res.r)].color if int(res.r) > 0 else Color(0.92, 0.93, 1.0)
		cap.rarity = int(res.r)
		cap.position = Vector2(376, 124)
		cap.size = Vector2(400, 400)
		add_child(cap)
		var tip := Label.new()
		tip.text = "點一下打開！"
		tip.add_theme_font_size_override("font_size", UITheme.fs(18))
		tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip.position = Vector2(376, 540)
		tip.size = Vector2(400, 30)
		add_child(tip)
		var opened := [false]
		var open_it := func():
			if opened[0]:
				return
			opened[0] = true
			tip.queue_free()
			await cap.burst()
			cap.queue_free()
			_card(res)
		gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed:
				open_it.call())
		await get_tree().create_timer(0.9 + 0.5 * int(res.r)).timeout
		if is_instance_valid(self):
			open_it.call()

	func _card(res: Dictionary) -> void:
		var it := Cos.item(String(res.id))
		var r := int(res.r)
		var rc: Color = Cos.RARITY[r].color
		var g = preload("game.gd").of(self)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UITheme.box(Color(0.09, 0.09, 0.22, 0.97), 22, rc, 3, 24))
		card.custom_minimum_size = Vector2(520, 0)
		card.position = Vector2(316, 70)
		add_child(card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		card.add_child(v)
		var tag := Label.new()
		tag.text = ("NEW！　" if res.new else "") + Cos.RARITY[r].name + "・" + _cat(it.cat)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_theme_font_override("font", UITheme.bold_font())
		tag.add_theme_font_size_override("font_size", UITheme.fs(17))
		tag.add_theme_color_override("font_color", rc)
		v.add_child(tag)
		var pv := SL.Preview.new()
		var eq: Dictionary = g.equipped.duplicate()
		eq[it.cat] = it.id
		pv.eq = eq
		pv.radius = 52.0
		pv.custom_minimum_size = Vector2(0, 250)
		v.add_child(pv)
		var nm := Label.new()
		nm.text = it.name
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.add_theme_font_override("font", UITheme.bold_font())
		nm.add_theme_font_size_override("font_size", UITheme.fs(28))
		nm.add_theme_color_override("font_color", rc if r > 0 else UITheme.TEXT)
		v.add_child(nm)
		var ds := preload("math_text.gd").new()
		ds.text = it.desc
		ds.font_size = UITheme.fs(16)
		ds.max_width = 470
		ds.align_center = true
		ds.color = UITheme.TEXT_DIM
		v.add_child(ds)
		if not res.new:
			var dup := Label.new()
			dup.text = "已經有了 → 光之碎片 +%d" % int(res.shards)
			dup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dup.add_theme_font_size_override("font_size", UITheme.fs(15))
			dup.add_theme_color_override("font_color", Color("7fe3ff"))
			v.add_child(dup)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(row)
		if g.equipped.get(it.cat, "") != it.id:
			var wear := Button.new()
			wear.text = "立即穿上"
			wear.custom_minimum_size = Vector2(190, 52)
			UITheme.accent_button(wear, 18)
			wear.pressed.connect(func():
				g.equip(it.id)
				_finish())
			row.add_child(wear)
		var keep := Button.new()
		keep.text = "收進衣櫃"
		keep.custom_minimum_size = Vector2(190, 52)
		UITheme.button_3d(keep, Color("3d46a8"), Color("191b52"), UITheme.TEXT, 18, 6, 14, 6)
		keep.pressed.connect(_finish)
		row.add_child(keep)
		card.pivot_offset = Vector2(260, 240)
		card.scale = Vector2(0.7, 0.7)
		card.modulate.a = 0.0
		var tw := create_tween().set_parallel()
		tw.tween_property(card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "modulate:a", 1.0, 0.2)

	func _cat(c: String) -> String:
		for x in Cos.CATS:
			if x.id == c:
				return x.name
		return ""

	# ----- 十連：十顆扭蛋排兩排，一顆一顆打開 -----
	func _ten() -> void:
		var title := UITheme.title_label("十連結果", 26, UITheme.ACCENT)
		title.position = Vector2(376, 40)
		title.size = Vector2(400, 40)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(title)
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		grid.position = Vector2(126, 100)
		add_child(grid)
		for res in results:
			var c := TenCard.new()
			c.res = res
			c.custom_minimum_size = Vector2(170, 200)
			grid.add_child(c)
			_ten_cards.append(c)
			c.gui_input.connect(func(e: InputEvent):
				if e is InputEventMouseButton and e.pressed:
					c.open())
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.position = Vector2(376, 560)
		row.size = Vector2(400, 56)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(row)
		var all := Button.new()
		all.text = "全部打開"
		all.custom_minimum_size = Vector2(180, 54)
		UITheme.accent_button(all, 18)
		row.add_child(all)
		var fin := Button.new()
		fin.text = "完成"
		fin.custom_minimum_size = Vector2(180, 54)
		UITheme.button_3d(fin, Color("3d46a8"), Color("191b52"), UITheme.TEXT, 18, 6, 14, 6)
		fin.visible = false
		row.add_child(fin)
		fin.pressed.connect(_finish)
		all.pressed.connect(func():
			all.visible = false
			for c in _ten_cards:
				if not c.opened:
					c.open()
					await get_tree().create_timer(0.14).timeout
			fin.visible = true)
		for c in _ten_cards:
			c.opened_sig.connect(func():
				var n := 0
				for c2 in _ten_cards:
					if c2.opened:
						n += 1
				if n == _ten_cards.size():
					all.visible = false
					fin.visible = true)

	func _finish() -> void:
		done.emit()
		queue_free()


## 單抽的大扭蛋：越稀有晃越久，打開時噴光
class BigCapsule extends Control:
	const UITheme := preload("game_theme.gd")
	var col := Color.WHITE
	var rarity := 0
	var t := 0.0
	var split := 0.0
	var flash := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func burst() -> void:
		var g = preload("game.gd").of(self)
		g.sfx("success" if rarity < 2 else "fanfare")
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "split", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "flash", 1.0, 0.25)
		await tw.finished
		await get_tree().create_timer(0.15).timeout

	func _draw() -> void:
		var c := size / 2.0
		var amp := (2.0 + 4.0 * rarity) * (1.0 - split)
		var rot := sin(t * (10.0 + 4.0 * rarity)) * 0.08 * amp / 4.0
		var r := 110.0
		var glow := 0.5 + 0.5 * sin(t * 5.0)
		UITheme.dot(self, c, r * (1.6 + 0.6 * flash), Color(col.r, col.g, col.b, 0.10 + 0.08 * glow + 0.4 * flash))
		if rarity >= 2:
			for k in 12:
				var a := t * 0.6 + k * TAU / 12.0
				draw_line(c + Vector2(cos(a), sin(a)) * r * 1.2, c + Vector2(cos(a), sin(a)) * r * 1.9, Color(col.r, col.g, col.b, 0.25), 6.0, true)
		var off := split * 70.0
		var top := PackedVector2Array()
		var bot := PackedVector2Array()
		for k in 25:
			var a := PI * k / 24.0
			top.append(c + Vector2(cos(a + PI) * r, sin(a + PI) * r - off).rotated(rot))
			bot.append(c + Vector2(cos(a) * r, sin(a) * r + off).rotated(rot))
		draw_colored_polygon(top, col)
		draw_colored_polygon(bot, Color(0.96, 0.96, 1.0))
		draw_polyline(top, col.darkened(0.3), 4.0, true)
		draw_polyline(bot, Color(0.7, 0.72, 0.85), 4.0, true)
		UITheme.dot(self, c + Vector2(-r * 0.38, -r * 0.45 - off), r * 0.14, Color(1, 1, 1, 0.6))
		if flash > 0.0:
			UITheme.dot(self, c, r * 0.9 * flash, Color(1, 1, 1, 0.8 * flash))


## 十連的一格：先是扭蛋，點開變成光靈穿新裝扮的小卡
class TenCard extends Control:
	signal opened_sig
	const UITheme := preload("game_theme.gd")
	const Cos := preload("cosmetics.gd")
	const SL := preload("spirit_look.gd")
	var res: Dictionary = {}
	var opened := false
	var t := 0.0
	var _pv: Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		t = randf() * 3.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func open() -> void:
		if opened:
			return
		opened = true
		var g = preload("game.gd").of(self)
		g.play("bell", 1.0 + 0.12 * int(res.r), -8.0)
		var it := Cos.item(String(res.id))
		_pv = SL.Preview.new()
		_pv.eq = {it.cat: it.id}
		_pv.radius = 22.0
		_pv.position = Vector2(0, 14)
		_pv.size = Vector2(size.x, 120)
		add_child(_pv)
		pivot_offset = size / 2.0
		scale = Vector2(0.85, 0.85)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		opened_sig.emit()

	func _draw() -> void:
		var r := int(res.get("r", 0))
		var rc: Color = Cos.RARITY[r].color
		var rect := Rect2(Vector2.ZERO, size)
		draw_style_box(UITheme.boxc(Color(0.1, 0.1, 0.24, 0.95), 16, rc if opened else Color(1, 1, 1, 0.15), 3 if opened and r >= 2 else 1, 0), rect)
		var font := get_theme_default_font()
		if not opened:
			var c := size / 2.0 + Vector2(0, sin(t * 3.0) * 3.0)
			var col := rc if r > 0 else Color(0.92, 0.93, 1.0)
			UITheme.dot(self, c, 52.0, Color(col.r, col.g, col.b, 0.15))
			var top := PackedVector2Array()
			var bot := PackedVector2Array()
			for k in 13:
				var a := PI * k / 12.0
				top.append(c + Vector2(cos(a + PI), sin(a + PI)) * 38.0)
				bot.append(c + Vector2(cos(a), sin(a)) * 38.0)
			draw_colored_polygon(top, col)
			draw_colored_polygon(bot, Color(0.96, 0.96, 1.0))
			draw_arc(c, 38.0, 0, TAU, 26, col.darkened(0.3), 2.0, true)
			draw_string(font, Vector2(0, size.y - 14), "點一下", HORIZONTAL_ALIGNMENT_CENTER, size.x, UITheme.fs(13), Color(1, 1, 1, 0.4))
			return
		var it := Cos.item(String(res.id))
		draw_string(font, Vector2(0, 150), it.name, HORIZONTAL_ALIGNMENT_CENTER, size.x, UITheme.fs(16), rc if r > 0 else UITheme.TEXT)
		var sub: String = Cos.RARITY[r].name + ("・NEW" if res.new else "・碎片 +%d" % int(res.shards))
		draw_string(font, Vector2(0, 176), sub, HORIZONTAL_ALIGNMENT_CENTER, size.x, UITheme.fs(13),
			Color("ffcf5a") if res.new else Color("7fe3ff"))
