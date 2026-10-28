extends Control
## 連續簽到日曆：14 天一輪，第 3、7、14 天有大獎（第 14 天第一次拿到「簽到圍巾」）
## 光靈的守護：漏簽時自動補上；守護不夠時連續天數保留一半
## 每天第一次打開遊戲會自動跳出來；之後可以從每日任務頁的「連續簽到」打開

signal closed

const UITheme := preload("game_theme.gd")
const Game := preload("game.gd")
const Cos := preload("cosmetics.gd")
const SL := preload("spirit_look.gd")
const QP := preload("quest_panel.gd")

const W := 840.0

var _card: PanelContainer
var _body: VBoxContainer
var _toast: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_card = PanelContainer.new()
	var sb := UITheme.box(Color("151a37"), 20, Color(1, 0.81, 0.35, 0.35), 1, 22)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	_card.add_theme_stylebox_override("panel", sb)
	_card.custom_minimum_size = Vector2(W, 0)
	_card.position = Vector2((1152.0 - W) / 2.0, 30)
	add_child(_card)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 12)
	_card.add_child(_body)
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_override("font", UITheme.bold_font())
	_toast.add_theme_font_size_override("font_size", UITheme.fs(22))
	_toast.add_theme_color_override("font_color", UITheme.ACCENT)
	_toast.add_theme_constant_override("outline_size", 7)
	_toast.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.1, 0.95))
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	add_child(_toast)
	_build()
	_card.pivot_offset = Vector2(W / 2.0, 260)
	_card.scale = Vector2(0.95, 0.95)
	_card.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "modulate:a", 1.0, 0.18)
	Game.of(self).sfx("open")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()


func _build() -> void:
	for c in _body.get_children():
		c.queue_free()
	var g = Game.of(self)
	var pv: Dictionary = g.streak_preview()

	# 標題列
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_body.add_child(head)
	var title := Label.new()
	title.text = "連續簽到"
	title.add_theme_font_override("font", UITheme.bold_font())
	title.add_theme_font_size_override("font_size", UITheme.fs(24))
	title.add_theme_color_override("font_color", UITheme.ACCENT)
	head.add_child(title)
	var sub := Label.new()
	sub.text = "每天早上 5:00 換日"
	sub.add_theme_font_size_override("font_size", UITheme.fs(13))
	sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(sub)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var close := UITheme.ghost_button("✕", 20)
	close.custom_minimum_size = Vector2(44, 40)
	close.pressed.connect(_close)
	head.add_child(close)

	# 狀態：連續天數、最佳紀錄、守護
	var st := HBoxContainer.new()
	st.add_theme_constant_override("separation", 16)
	_body.add_child(st)
	var big := Label.new()
	var shown: int = int(g.streak.count)
	big.text = "已連續 %d 天" % shown
	big.add_theme_font_override("font", UITheme.bold_font())
	big.add_theme_font_size_override("font_size", UITheme.fs(22))
	st.add_child(big)
	var best := Label.new()
	best.text = "最佳紀錄 %d 天" % int(g.streak.best)
	best.add_theme_font_size_override("font_size", UITheme.fs(15))
	best.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	best.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	st.add_child(best)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st.add_child(sp2)
	var gl := Label.new()
	gl.text = "光靈的守護"
	gl.add_theme_font_size_override("font_size", UITheme.fs(15))
	gl.add_theme_color_override("font_color", Color("7fe3ff"))
	gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	st.add_child(gl)
	for k in g.GUARD_MAX:
		var sh := Shield.new()
		sh.full = k < int(g.streak.guards)
		sh.custom_minimum_size = Vector2(30, 34)
		sh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		st.add_child(sh)

	# 14 格日曆
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_body.add_child(grid)
	var pos: int = int(pv.pos)
	var can: bool = pv.can
	for k in range(1, g.STREAK_CYCLE + 1):
		var state := "future"
		if can:
			if k < pos:
				state = "done"
			elif k == pos:
				state = "today"
		elif k <= pos:
			state = "done"
		grid.add_child(_cell(g, k, state))

	# 說明＋中斷提示
	var info := Label.new()
	info.text = "漏簽的日子，光靈的守護會自動補上（每連續簽到 7 天多一個，最多 %d 個）。守護不夠時，連續天數保留一半，不會歸零。" % g.GUARD_MAX
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", UITheme.fs(14))
	info.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_body.add_child(info)
	if can and int(pv.missed) > 0:
		var warn := Label.new()
		if int(pv.guards_used) > 0:
			warn.text = "上次簽到後漏了 %d 天：這次簽到會用掉 %d 個守護補上，連續天數不中斷！" % [int(pv.missed), int(pv.guards_used)]
			warn.add_theme_color_override("font_color", Color("7fe3ff"))
		else:
			warn.text = "上次簽到後漏了 %d 天，守護不夠：連續天數會保留一半（%d → %d 天）。" % [int(pv.missed), int(g.streak.count), int(g.streak.count) / 2]
			warn.add_theme_color_override("font_color", Color("ffb454"))
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warn.add_theme_font_size_override("font_size", UITheme.fs(15))
		_body.add_child(warn)

	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 60)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if can:
		b.text = "簽到　第 %d 天" % int(pv.next)
		UITheme.accent_button(b, 20)
		b.pressed.connect(_claim)
		var tw := b.create_tween().set_loops()
		tw.tween_property(b, "modulate", Color(1.1, 1.08, 0.95), 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(b, "modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE)
	else:
		b.text = "今天已簽到 ✓　明天再來！"
		b.disabled = true
		UITheme.accent_button(b, 18)
	_body.add_child(b)


func _cell(g, k: int, state: String) -> Control:
	var milestone: bool = k in [3, 7, 14]
	var p := PanelContainer.new()
	var face := Color(0.1, 0.11, 0.25, 0.95)
	var edge := Color(1, 1, 1, 0.1)
	if milestone:
		face = Color(0.24, 0.18, 0.1, 0.9)
		edge = Color(1, 0.81, 0.35, 0.55)
	if state == "today":
		edge = UITheme.ACCENT
	p.add_theme_stylebox_override("panel", UITheme.box(face, 12, edge, 3 if state == "today" else 1, 4))
	p.custom_minimum_size = Vector2(102, 120)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var dl := Label.new()
	dl.text = "第 %d 天" % k
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.add_theme_font_size_override("font_size", UITheme.fs(13))
	dl.add_theme_color_override("font_color", UITheme.ACCENT if milestone or state == "today" else UITheme.TEXT_DIM)
	v.add_child(dl)
	var rw: Dictionary = g.streak_reward(k, not g.owned.has("streak_scarf"))
	var icon_box := Control.new()
	icon_box.custom_minimum_size = Vector2(0, 56)
	v.add_child(icon_box)
	if rw.has("item"):
		var pvw := SL.Preview.new()
		pvw.eq = {"face": String(rw.item)}
		pvw.radius = 15.0
		pvw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_box.add_child(pvw)
	else:
		var kind := "crystal" if rw.has("crystal") else "dust"
		var ii := QP.ItemIcon.new()
		ii.kind = kind
		ii.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_box.add_child(ii)
	var parts := PackedStringArray()
	if rw.has("item"):
		parts.append("簽到圍巾")
	if rw.has("crystal"):
		parts.append("◇ %d" % int(rw.crystal))
	if rw.has("dust"):
		parts.append("✦ %d" % int(rw.dust))
	if rw.has("shard"):
		parts.append("◆ %d" % int(rw.shard))
	var al := Label.new()
	al.text = "  ".join(parts)
	al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	al.add_theme_font_size_override("font_size", UITheme.fs(12))
	v.add_child(al)
	if state == "done":
		p.modulate = Color(1, 1, 1, 0.45)
		var ck := Label.new()
		ck.text = "✓"
		ck.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ck.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ck.add_theme_font_size_override("font_size", UITheme.fs(40))
		ck.add_theme_color_override("font_color", Color("6ee7a0"))
		ck.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ck.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(ck)
	elif state == "today":
		var tw := p.create_tween().set_loops()
		tw.tween_property(p, "modulate", Color(1.15, 1.12, 0.95), 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(p, "modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE)
	return p


func _claim() -> void:
	var g = Game.of(self)
	var res: Dictionary = g.streak_claim()
	if res.is_empty():
		return
	var rw: Dictionary = res.reward
	var parts := PackedStringArray()
	if rw.has("item"):
		parts.append("限定裝扮「%s」" % Cos.item(String(rw.item)).name)
	if rw.has("crystal"):
		parts.append("光之結晶 ×%d" % int(rw.crystal))
	if rw.has("dust"):
		parts.append("星塵 ×%d" % int(rw.dust))
	if rw.has("shard"):
		parts.append("光之碎片 ×%d" % int(rw.shard))
	var lines := PackedStringArray()
	if int(res.guards_used) > 0:
		lines.append("光靈的守護補上了漏簽的 %d 天！" % int(res.guards_used))
	elif res.halved:
		lines.append("中斷了一下，連續天數保留一半，繼續加油！")
	lines.append("連續第 %d 天：獲得 %s" % [int(res.count), "、".join(parts)])
	if res.new_guard:
		lines.append("連續 7 天！多了一個光靈的守護")
	g.sfx("fanfare" if rw.has("item") or rw.has("crystal") else "success")
	_build()
	_toast.text = "\n".join(lines)
	_toast.size = Vector2(1152, 120)
	_toast.position = Vector2(0, 250)
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)


## 守護的小盾牌
class Shield extends Control:
	const UITheme := preload("game_theme.gd")
	var full := true

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var pts := PackedVector2Array([Vector2(w * 0.5, 2), Vector2(w - 3, h * 0.2), Vector2(w - 4, h * 0.55),
			Vector2(w * 0.5, h - 2), Vector2(4, h * 0.55), Vector2(3, h * 0.2)])
		if full:
			draw_colored_polygon(pts, Color("5ad8ff"))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color("e8fbff"), 1.5, true)
			UITheme.dot(self, Vector2(w * 0.5, h * 0.45), w * 0.16, Color(1, 1, 1, 0.9))
		else:
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1, 1, 1, 0.3), 1.5, true)
