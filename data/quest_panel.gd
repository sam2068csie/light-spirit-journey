extends Control
## 每日任務頁：蓋在主畫面／世界地圖／修煉之間／終焉之塔上面的視窗
##   上面：區間獎勵（完成 1、3、5 個任務各有一份）
##   下面：五個任務，完成後按「領取」拿星塵；還沒完成的可以按「前往」直接過去做
## 用法：var p := QuestPanel.new(); add_child(p)；p.go 送出要前往的頁面（"levels"/"review"/"tower"）

signal closed
signal go(page: String)

const UITheme := preload("game_theme.gd")
const Game := preload("game.gd")
const DQ := preload("daily_quests.gd")

const W := 820.0
const GREEN := UITheme.GOOD
const GREEN_FACE := Color("4fd18b")
const GREEN_LIP := Color("2a8a57")

var _card: PanelContainer
var _list: VBoxContainer
var _tier: TierStrip
var _hold: HBoxContainer
var _toast: Label
var _toast_tw: Tween
var _sign_btn: Button
var _sign_dot: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_close())

	_card = PanelContainer.new()
	var sb := UITheme.box(Color("151a37"), 20, Color(1, 1, 1, 0.12), 1, 20)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	_card.add_theme_stylebox_override("panel", sb)
	_card.custom_minimum_size = Vector2(W, 0)
	_card.position = Vector2((1152.0 - W) / 2.0, 22)
	add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_card.add_child(col)

	# 標題列：圖示、標題、換日時間、持有物品、關閉
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	col.add_child(head)
	var ic := TextureRect.new()
	ic.texture = UITheme.icon("quest", 30, UITheme.ACCENT)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(ic)
	var title := Label.new()
	title.text = "每日任務"
	title.add_theme_font_override("font", UITheme.bold_font())
	title.add_theme_font_size_override("font_size", UITheme.fs(24))
	title.add_theme_color_override("font_color", UITheme.ACCENT)
	head.add_child(title)
	var sub := Label.new()
	sub.text = "每天早上 5:00 更新"
	sub.add_theme_font_size_override("font_size", UITheme.fs(13))
	sub.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(sub)
	# 連續簽到的入口（今天還沒簽會亮紅點）
	_sign_btn = Button.new()
	_sign_btn.focus_mode = Control.FOCUS_NONE
	_sign_btn.custom_minimum_size = Vector2(150, 38)
	_sign_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sign_btn.add_theme_font_size_override("font_size", UITheme.fs(15))
	UITheme.tight(_sign_btn, 4)
	_sign_btn.pressed.connect(_open_signin)
	head.add_child(_sign_btn)
	_sign_dot = load(get_script().resource_path.get_base_dir() + "/main_menu.gd").QuestDot.new()
	_sign_dot.position = Vector2(150 - 14, -8)
	_sign_dot.size = Vector2(22, 22)
	_sign_btn.add_child(_sign_dot)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	_hold = HBoxContainer.new()
	_hold.add_theme_constant_override("separation", 6)
	head.add_child(_hold)
	var close := UITheme.ghost_button("✕", 20)
	close.custom_minimum_size = Vector2(44, 40)
	close.pressed.connect(_close)
	head.add_child(close)

	_tier = TierStrip.new()
	_tier.panel = self
	_tier.custom_minimum_size = Vector2(W - 40, 92)
	col.add_child(_tier)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	col.add_child(_list)

	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_override("font", UITheme.bold_font())
	_toast.add_theme_font_size_override("font_size", UITheme.fs(20))
	_toast.add_theme_color_override("font_color", UITheme.ACCENT)
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.1, 0.95))
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	add_child(_toast)

	_refresh()
	_card.modulate.a = 0.0
	_card.scale = Vector2(0.96, 0.96)
	_card.pivot_offset = Vector2(W / 2.0, 280)
	var tw := create_tween().set_parallel()
	tw.tween_property(_card, "modulate:a", 1.0, 0.18)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Game.of(self).sfx("open")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()


# ---------- 畫面 ----------

func _open_signin() -> void:
	var p := preload("signin_panel.gd").new()
	add_child(p)
	p.closed.connect(_refresh)


func _refresh() -> void:
	var g = Game.of(self)
	var signed: bool = String(g.streak.last) == g.DQ.day_key()
	_sign_btn.text = "連續簽到 %d 天" % int(g.streak.count)
	_sign_dot.visible = not signed
	# 持有物品
	for c in _hold.get_children():
		c.queue_free()
	for k in ["dust", "shard", "crystal"]:
		var ii := ItemIcon.new()
		ii.kind = k
		ii.custom_minimum_size = Vector2(24, 24)
		ii.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ii.tooltip_text = DQ.ITEMS[k].name
		_hold.add_child(ii)
		var n := Label.new()
		n.text = str(int(g.inv.get(k, 0)))
		n.add_theme_font_size_override("font_size", UITheme.fs(15))
		n.custom_minimum_size = Vector2(34, 0)
		_hold.add_child(n)
	# 區間獎勵
	_tier.done_n = g.quest_got_count()      # 完成並領取的任務數
	_tier.claimed = g.quest_state().tiers.duplicate()
	_tier.rebuild()
	# 任務列表
	for c in _list.get_children():
		c.queue_free()
	for it in g.quest_list():
		_list.add_child(_row(it))


func _row(it: Dictionary) -> Control:
	var ready: bool = it.done and not it.got
	var p := PanelContainer.new()
	var bg := Color(0.25, 0.62, 0.42, 0.16) if ready else Color(1, 1, 1, 0.035)
	var edge := Color(GREEN.r, GREEN.g, GREEN.b, 0.45) if ready else Color(1, 1, 1, 0.07)
	p.add_theme_stylebox_override("panel", UITheme.box(bg, 12, edge, 1, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	# 獎勵：星塵圖示＋數量
	var tile := PanelContainer.new()
	tile.add_theme_stylebox_override("panel", UITheme.box(Color(0, 0, 0, 0.28), 10, Color(1, 1, 1, 0.08), 1, 0))
	tile.custom_minimum_size = Vector2(54, 54)
	h.add_child(tile)
	var ii := ItemIcon.new()
	ii.kind = "dust"
	ii.custom_minimum_size = Vector2(54, 54)
	tile.add_child(ii)
	var amt := Label.new()
	amt.text = "%d" % int(it.dust)
	amt.add_theme_font_size_override("font_size", UITheme.fs(12))
	amt.add_theme_constant_override("outline_size", 4)
	amt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	amt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amt.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	amt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	amt.offset_right = -3
	amt.offset_bottom = 1
	ii.add_child(amt)
	if it.got:
		tile.modulate = Color(1, 1, 1, 0.45)
	# 標題、進度、說明
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(tv)
	var tr := HBoxContainer.new()
	tr.add_theme_constant_override("separation", 10)
	tv.add_child(tr)
	var tl := Label.new()
	tl.text = it.title
	tl.add_theme_font_override("font", UITheme.bold_font())
	tl.add_theme_font_size_override("font_size", UITheme.fs(17))
	tl.add_theme_color_override("font_color", UITheme.TEXT_DIM if it.got else UITheme.TEXT)
	tr.add_child(tl)
	var pl := Label.new()
	pl.text = "%d / %d" % [int(it.have), int(it.need)]
	pl.add_theme_font_size_override("font_size", UITheme.fs(15))
	pl.add_theme_color_override("font_color", GREEN if it.done else UITheme.TEXT_DIM)
	pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tr.add_child(pl)
	var dl := Label.new()
	dl.text = it.desc
	dl.add_theme_font_size_override("font_size", UITheme.fs(15))
	dl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	tv.add_child(dl)
	# 右邊的按鈕：領取／已領取／前往
	var b := Button.new()
	b.custom_minimum_size = Vector2(118, 46)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	if ready:
		b.text = "領取"
		UITheme.button_3d(b, GREEN_FACE, GREEN_LIP, Color("0b2416"), 17, 5, 14, 4)
		var id: String = it.id
		b.pressed.connect(func(): _claim(id))
		_pulse(b)
		b.add_child(make_dot(Vector2(118 - 14, -8)))
	elif it.got:
		b.text = "✓ 已領取"
		b.disabled = true
		UITheme.tight(b, 4)
		b.add_theme_font_size_override("font_size", UITheme.fs(15))
	elif String(it.go) != "":
		b.text = "前往  ▶"
		UITheme.tight(b, 4)
		b.add_theme_font_size_override("font_size", UITheme.fs(15))
		var dest: String = it.go
		b.pressed.connect(func():
			go.emit(dest)
			_close())
	else:
		b.modulate.a = 0.0
		b.disabled = true
	h.add_child(b)
	return p


## 可以領的按鈕輕輕呼吸（提醒點它）
func _pulse(c: Control) -> void:
	var tw := c.create_tween().set_loops()
	tw.tween_property(c, "modulate", Color(1.12, 1.12, 1.12), 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "modulate", Color.WHITE, 0.6).set_trans(Tween.TRANS_SINE)


## 紅色驚嘆號（還沒領的獎勵）
func make_dot(pos: Vector2) -> Control:
	var d: Control = load(get_script().resource_path.get_base_dir() + "/main_menu.gd").QuestDot.new()
	d.position = pos
	d.size = Vector2(22, 22)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


## 按任何一個「領取」：所有完成的任務一起領
func _claim(_id: String) -> void:
	var g = Game.of(self)
	var cnt := 0
	for it in g.quest_list():
		if it.done and not it.got:
			cnt += 1
	var n: int = g.quest_claim_all()
	if n <= 0:
		return
	g.sfx("correct")
	_show_toast(("一次領取 %d 個任務：" % cnt if cnt > 1 else "") + "星塵 +%d" % n)
	_refresh()


## 按任何一個可以領的區間獎勵：可以領的全部一起領
func claim_tier(n: int) -> void:
	var g = Game.of(self)
	if not g.quest_tier_ready(n):
		for t in DQ.TIERS:
			if int(t.n) == n:
				var msg := ("已經領過了：" if g.quest_state().tiers.has(n) else "領取 %d 個任務的獎勵後可以領：" % n) + "%s（%s）" % [t.name, t.desc]
				_show_toast(msg, UITheme.TEXT)
		return
	var res: Array = g.quest_claim_tiers_all()
	var got: Dictionary = res[0]
	var parts := PackedStringArray()
	for k in ["dust", "shard", "crystal"]:
		if got.has(k):
			parts.append("%s ×%d" % [DQ.ITEMS[k].name, int(got[k])])
	g.sfx("fanfare" if (res[1] as Array).has(5) else "success")
	_show_toast("獲得：" + "、".join(parts))
	_refresh()


func _show_toast(text: String, col: Color = UITheme.ACCENT) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", col)
	_toast.size = Vector2(W, 40)
	_toast.position = Vector2((1152.0 - W) / 2.0, 300)
	if _toast_tw:
		_toast_tw.kill()
	_toast.modulate.a = 1.0
	_toast_tw = create_tween()
	_toast_tw.tween_property(_toast, "position:y", 270.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_toast_tw.tween_interval(1.4)
	_toast_tw.tween_property(_toast, "modulate:a", 0.0, 0.4)


# ================= 區間獎勵：進度條＋三個獎勵 =================

class TierStrip extends Control:
	const UITheme := preload("game_theme.gd")
	const DQ := preload("daily_quests.gd")
	var panel
	var done_n := 0
	var claimed: Array = []
	var _btns: Array = []

	func _x(n: float) -> float:
		var x0 := 120.0
		var x1 := size.x - 24.0
		return x0 + (x1 - x0) * n / 5.0

	func rebuild() -> void:
		for b in _btns:
			b.queue_free()
		_btns = []
		for t in DQ.TIERS:
			var n := int(t.n)
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(60, 50)
			b.size = Vector2(60, 50)
			var ready := done_n >= n and not claimed.has(n)
			var got := claimed.has(n)
			var face := Color(0.06, 0.07, 0.15, 0.9)
			var edge := UITheme.ACCENT if ready else Color(1, 1, 1, 0.12)
			for st in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(st, UITheme.box(face.lightened(0.06 if st == "hover" else 0.0), 10, edge, 2 if ready else 1, 0))
			b.tooltip_text = "%s：%s" % [t.name, t.desc]
			var ii := ItemIcon.new()
			ii.kind = String(t.kind)
			ii.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			ii.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(ii)
			if got:
				ii.modulate = Color(1, 1, 1, 0.35)
				var ck := Label.new()
				ck.text = "✓"
				ck.add_theme_font_size_override("font_size", UITheme.fs(24))
				ck.add_theme_color_override("font_color", UITheme.GOOD)
				ck.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				ck.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				ck.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				ck.mouse_filter = Control.MOUSE_FILTER_IGNORE
				b.add_child(ck)
			b.pressed.connect(func(): panel.claim_tier(n))
			add_child(b)
			_btns.append(b)
			if ready:
				b.add_child(panel.make_dot(Vector2(60 - 14, -8)))
				var tw := b.create_tween().set_loops()
				tw.tween_property(b, "modulate", Color(1.2, 1.15, 0.9), 0.55).set_trans(Tween.TRANS_SINE)
				tw.tween_property(b, "modulate", Color.WHITE, 0.55).set_trans(Tween.TRANS_SINE)
		_place()
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_place()

	func _place() -> void:
		for i in _btns.size():
			_btns[i].position = Vector2(_x(float(DQ.TIERS[i].n)) - 30.0, 0)

	func _draw() -> void:
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, 30), "區間獎勵", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15), UITheme.TEXT_DIM)
		var y := 72.0
		var x0 := _x(0.0)
		var x1 := _x(5.0)
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.12), 8.0)
		var fx := _x(float(mini(done_n, 5)))
		if done_n > 0:
			draw_line(Vector2(x0, y), Vector2(fx, y), UITheme.ACCENT, 8.0)
		for n in [1, 2, 3, 4, 5]:
			var c := Vector2(_x(float(n)), y)
			var big: bool = n in [1, 3, 5]
			var on: bool = done_n >= int(n)
			UITheme.dot(self, c, 13.0 if big else 6.0, UITheme.ACCENT if on else Color("2a3058"))
			if big:
				draw_string(font, c + Vector2(-12, 6), str(n), HORIZONTAL_ALIGNMENT_CENTER, 24, UITheme.fs(15),
					Color("2a1a04") if on else UITheme.TEXT)


# ================= 物品圖示（用程式畫，畫一次就好） =================

class ItemIcon extends Control:
	const UITheme := preload("game_theme.gd")
	var kind := "dust"

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE if tooltip_text == "" else Control.MOUSE_FILTER_PASS
		resized.connect(queue_redraw)

	func _draw() -> void:
		var s := minf(size.x, size.y)
		var c := size / 2.0
		match kind:
			"dust":
				_coin(c, s * 0.36)
			"chest":
				_chest(c, s * 0.36)
			"shard":
				_gem(c, s * 0.30, UITheme.CYAN_LIGHT, 4)
			"crystal":
				_gem(c, s * 0.38, UITheme.VIOLET_DEEP, 6)

	## 星塵：金色圓幣，中間一顆星
	func _coin(c: Vector2, r: float) -> void:
		UITheme.dot(self, c + Vector2(0, r * 0.12), r, Color("a86a12"))
		UITheme.dot(self, c, r, UITheme.GOLD)
		UITheme.dot(self, c, r * 0.78, UITheme.GOLD_DEEP)
		_star(c, r * 0.55, UITheme.GOLD_PALE)
		UITheme.dot(self, c + Vector2(-r * 0.45, -r * 0.45), r * 0.14, Color(1, 1, 1, 0.7))

	## 寶箱：木箱＋金邊＋鎖
	func _chest(c: Vector2, r: float) -> void:
		var body := Rect2(c.x - r, c.y - r * 0.15, r * 2.0, r * 0.95)
		var lid := PackedVector2Array([Vector2(c.x - r, c.y - r * 0.15), Vector2(c.x - r * 0.85, c.y - r * 0.75),
			Vector2(c.x + r * 0.85, c.y - r * 0.75), Vector2(c.x + r, c.y - r * 0.15)])
		draw_colored_polygon(lid, Color("a0582a"))
		draw_rect(body, Color("8a4520"))
		draw_rect(Rect2(body.position.x, body.position.y, body.size.x, r * 0.16), UITheme.GOLD)
		draw_rect(Rect2(c.x - r * 0.62, c.y - r * 0.75, r * 0.16, r * 1.55), UITheme.GOLD_DEEP)
		draw_rect(Rect2(c.x + r * 0.46, c.y - r * 0.75, r * 0.16, r * 1.55), UITheme.GOLD_DEEP)
		draw_rect(Rect2(c.x - r * 0.17, c.y - r * 0.28, r * 0.34, r * 0.42), UITheme.GOLD_LIGHT)
		UITheme.dot(self, c + Vector2(0, -r * 0.05), r * 0.07, Color("5a2c10"))

	## 寶石：多邊形＋亮面
	func _gem(c: Vector2, r: float, col: Color, sides: int) -> void:
		var pts := PackedVector2Array()
		for k in sides:
			var a := -PI / 2.0 + k * TAU / sides
			pts.append(c + Vector2(cos(a) * r * (0.82 if sides == 4 else 1.0), sin(a) * r * (1.15 if sides == 4 else 1.0)))
		draw_colored_polygon(pts, col.darkened(0.25))
		var inner := PackedVector2Array()
		for p in pts:
			inner.append(c + (p - c) * 0.6)
		draw_colored_polygon(inner, col)
		draw_colored_polygon(PackedVector2Array([pts[0], inner[0], inner[sides - 1], pts[sides - 1]]), col.lightened(0.35))
		draw_polyline(pts + PackedVector2Array([pts[0]]), col.lightened(0.5), 1.5, true)

	func _star(c: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for k in 10:
			var a := -PI / 2.0 + k * PI / 5.0
			var rr := r if k % 2 == 0 else r * 0.45
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(pts, col)
