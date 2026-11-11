extends CanvasLayer
## 新手教學：畫面變暗，只留一個「聚光燈」框住要看的地方；光靈飛到旁邊，用對話框一句一句說明。
## 用法：preload("res://data/ui/tutorial.gd").run(host, steps)
##   steps：[{"rect": Callable（回傳畫面座標的 Rect2；空的 Rect2 = 不框，光靈在中間說話）, "text": String, "face": "happy"…}]
##   教學進行時整個遊戲暫停（計時也停），結束後恢復。
## 操作：點畫面／Enter／空白鍵 = 下一句；Esc 或「跳過」= 直接結束。
const UITheme := preload("res://data/ui/game_theme.gd")
const Game := preload("res://data/core/game.gd")
const SL := preload("res://data/ui/spirit_look.gd")

signal finished

const W := 1152.0
const H := 648.0
const BUB_W := 330.0

var host: Node
var steps: Array = []
var i := -1
var view: View
var bubble: PanelContainer
var text_l: Label
var count_l: Label
var next_b: Button
var _was_paused := false
var bub_to := Vector2.ZERO


static func run(h: Node, st: Array) -> Node:
	var t := new()
	t.host = h
	t.steps = st
	h.add_child(t)
	return t


func _ready() -> void:
	add_to_group("tutorial")      # 關卡的小助手看到教學在跑就不說話（buddy.gd）
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	view = View.new()
	view.tut = self
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_STOP
	view.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_advance())
	add_child(view)
	view.spirit = Vector2(W / 2.0, H + 60)   # 從畫面下方飛進來
	view.hole = Rect2(W / 2.0, H / 2.0, 0, 0)
	_build_bubble()
	_go(0)


func _build_bubble() -> void:
	bubble = PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", UITheme.box(Color("fff6d8"), 16, Color("f5c84c"), 3, 14))
	bubble.custom_minimum_size = Vector2(BUB_W, 0)
	bubble.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bubble)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	bubble.add_child(vb)
	text_l = Label.new()
	text_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_l.custom_minimum_size = Vector2(BUB_W - 28, 0)
	text_l.add_theme_font_size_override("font_size", UITheme.fs(17))
	text_l.add_theme_color_override("font_color", Color("2a2440"))
	text_l.add_theme_constant_override("line_spacing", 4)
	vb.add_child(text_l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)
	count_l = Label.new()
	count_l.add_theme_font_size_override("font_size", UITheme.fs(13))
	count_l.add_theme_color_override("font_color", Color("8a7a5a"))
	count_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(count_l)
	var skip := Button.new()
	skip.text = "跳過教學"
	skip.flat = true
	skip.focus_mode = Control.FOCUS_NONE
	skip.add_theme_font_size_override("font_size", UITheme.fs(13))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		skip.add_theme_color_override(k, Color("8a7a5a"))
	skip.pressed.connect(_end)
	row.add_child(skip)
	next_b = Button.new()
	next_b.focus_mode = Control.FOCUS_NONE
	next_b.custom_minimum_size = Vector2(96, 38)
	UITheme.button_3d(next_b, UITheme.ACCENT, UITheme.ACCENT_LIP, UITheme.GOLD_INK, 15, 3, 12, 2)
	next_b.pressed.connect(_advance)
	row.add_child(next_b)


func _step_rect(k: int) -> Rect2:
	var rc = steps[k].get("rect", Rect2())
	if rc is Callable:
		rc = (rc as Callable).call()
	return rc if rc is Rect2 else Rect2()


func _go(k: int) -> void:
	i = k
	var st: Dictionary = steps[k]
	var hr := _step_rect(k)
	var has := hr.size.x > 2.0 and hr.size.y > 2.0
	# 要框的東西現在不在畫面上（例如這一步沒有送出按鈕）：這一句跳過
	if st.has("rect") and not has:
		if k + 1 < steps.size():
			_go(k + 1)
		else:
			_end()
		return
	view.target_hole = hr.grow(8) if has else Rect2(W / 2.0, H / 2.0, 0, 0)
	view.has_hole = has
	text_l.text = String(st.text)
	# 自動換行的 Label 量不準高度：自己估行數，對話框才不會把字切掉
	var fnt := text_l.get_theme_font("font")
	var fsz := text_l.get_theme_font_size("font_size")
	var lines := ceili(fnt.get_string_size(text_l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x / (BUB_W - 44.0))
	text_l.custom_minimum_size.y = maxi(1, lines) * (fnt.get_height(fsz) + 4.0)
	bubble.size = Vector2.ZERO
	text_l.visible_ratio = 0.0
	view.typing = 0.0
	count_l.text = "%d／%d" % [k + 1, steps.size()]
	next_b.text = "開始吧！" if k == steps.size() - 1 else "下一步 ▸"
	# 先量對話框大小，再決定光靈和對話框放哪裡
	bubble.reset_size()
	text_l.visible_ratio = 1.0
	var bs := bubble.get_combined_minimum_size()
	text_l.visible_ratio = 0.0
	var place := _place(hr if has else Rect2(), bs)
	view.target_spirit = place[0]
	view.arrow_to = place[2]
	bub_to = place[1]
	if i == 0 and bubble.position == Vector2.ZERO:
		bubble.position = bub_to
	bubble.modulate.a = 0.0
	bubble.create_tween().tween_property(bubble, "modulate:a", 1.0, 0.25)
	var g = Game.of(host) if host else null
	if g:
		g.play("blip", 1.3 + 0.1 * (k % 3), -10.0)


## 回傳 [光靈的位置, 對話框左上角, 箭頭指向的點]
func _place(hr: Rect2, bs: Vector2) -> Array:
	var group := Vector2(bs.x + 80.0, maxf(bs.y, 90.0))   # 光靈（左邊 80）＋對話框
	if hr.size == Vector2.ZERO:
		var p := Vector2((W - group.x) / 2.0, (H - group.y) / 2.0)
		return [p + Vector2(40, group.y / 2.0), p + Vector2(80, (group.y - bs.y) / 2.0), Vector2(-1, -1)]
	var room := {
		"right": W - hr.end.x, "left": hr.position.x,
		"below": H - hr.end.y, "above": hr.position.y,
	}
	var side := ""
	for s in ["right", "left", "below", "above"]:
		var need: float = group.x if s in ["right", "left"] else group.y
		if room[s] >= need + 16.0:
			side = s
			break
	var p := Vector2.ZERO
	match side:
		"right":
			p = Vector2(hr.end.x + 12, hr.get_center().y - group.y / 2.0)
		"left":
			p = Vector2(hr.position.x - 12 - group.x, hr.get_center().y - group.y / 2.0)
		"below":
			p = Vector2(hr.get_center().x - group.x / 2.0, hr.end.y + 12)
		"above":
			p = Vector2(hr.get_center().x - group.x / 2.0, hr.position.y - 12 - group.y)
		_:
			# 框太大（例如整個舞台）：放在框裡面的下方，畫面變暗的部分不夠就疊上去
			p = Vector2(hr.get_center().x - group.x / 2.0, hr.end.y - group.y - 24)
	p.x = clampf(p.x, 12.0, W - group.x - 12.0)
	p.y = clampf(p.y, 12.0, H - group.y - 12.0)
	var sp := p + Vector2(40, group.y / 2.0)
	var aim := Vector2(clampf(sp.x, hr.position.x + 10, hr.end.x - 10), clampf(sp.y, hr.position.y + 10, hr.end.y - 10))
	if hr.has_point(sp):
		aim = Vector2(-1, -1)          # 光靈本身就在框裡：不用箭頭
	return [sp, p + Vector2(80, (group.y - bs.y) / 2.0), aim]


func _advance() -> void:
	if _ended:
		return
	if text_l.visible_ratio < 1.0:
		text_l.visible_ratio = 1.0         # 字還在跑：先一次顯示完
		view.typing = 1.0
		return
	if i + 1 >= steps.size():
		_end()
	else:
		_go(i + 1)


var _ended := false


func _end() -> void:
	if _ended:
		return
	_ended = true
	get_tree().paused = _was_paused
	finished.emit()
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		_end()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("ui_accept"):
		_advance()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	# 對話框滑到目標位置；用真正的大小夾在畫面裡（字多換行時不會掉出畫面）
	var to := Vector2(clampf(bub_to.x, 10.0, W - bubble.size.x - 10.0), clampf(bub_to.y, 10.0, H - bubble.size.y - 10.0))
	bubble.position = bubble.position.lerp(to, 1.0 - exp(-delta * 12.0))
	if text_l.visible_ratio < 1.0:
		var n := maxi(1, text_l.text.length())
		text_l.visible_ratio = minf(1.0, text_l.visible_ratio + delta * 32.0 / n)   # 一秒大約 32 個字


## 變暗的背景、聚光燈、光靈、箭頭
class View extends Control:
	const UITheme := preload("res://data/ui/game_theme.gd")
	const SL := preload("res://data/ui/spirit_look.gd")
	const Game := preload("res://data/core/game.gd")
	var tut
	var hole := Rect2()
	var target_hole := Rect2()
	var has_hole := false
	var spirit := Vector2.ZERO
	var target_spirit := Vector2.ZERO
	var arrow_to := Vector2(-1, -1)
	var typing := 0.0
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		var k := 1.0 - exp(-delta * 10.0)
		hole = Rect2(hole.position.lerp(target_hole.position, k), hole.size.lerp(target_hole.size, k))
		spirit = spirit.lerp(target_spirit, 1.0 - exp(-delta * 6.0))
		queue_redraw()

	func _draw() -> void:
		var dim := Color(0.02, 0.03, 0.1, 0.72)
		var r := hole
		if r.size.x < 2.0 or r.size.y < 2.0:
			draw_rect(Rect2(Vector2.ZERO, size), dim)
		else:
			# 四塊暗色把聚光燈圍起來
			draw_rect(Rect2(0, 0, size.x, r.position.y), dim)
			draw_rect(Rect2(0, r.end.y, size.x, size.y - r.end.y), dim)
			draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), dim)
			draw_rect(Rect2(r.end.x, r.position.y, size.x - r.end.x, r.size.y), dim)
			# 一閃一閃的金框
			var pulse := 0.5 + 0.5 * sin(t * 4.0)
			draw_style_box(UITheme.box(Color(0, 0, 0, 0), 14, Color(0.96, 0.78, 0.3, 0.55 + 0.45 * pulse), 3, 0), r)
			draw_style_box(UITheme.box(Color(0, 0, 0, 0), 18, Color(0.96, 0.78, 0.3, 0.18 * pulse), 2, 0), r.grow(6 + 4 * pulse))
		# 箭頭：從光靈指向聚光燈，前後彈動
		if arrow_to.x >= 0.0 and has_hole:
			var d := (arrow_to - spirit)
			if d.length() > 70.0:
				var u := d.normalized()
				var tip := arrow_to - u * (10.0 + 8.0 * (0.5 + 0.5 * sin(t * 6.0)))
				var base := tip - u * 34.0
				var nrm := Vector2(-u.y, u.x)
				draw_line(base - u * 10.0, tip - u * 10.0, Color("f5c84c"), 6.0, true)
				draw_colored_polygon(PackedVector2Array([tip, tip - u * 18.0 + nrm * 12.0, tip - u * 18.0 - nrm * 12.0]), Color("f5c84c"))
		# 光靈（上下飄，往右看對話框）
		var sp := spirit + Vector2(0, sin(t * 3.0) * 5.0)
		UITheme.dot(self, sp, 44.0, Color(1, 0.9, 0.5, 0.12))
		var eq = {}
		var g = Game.of(tut.host) if tut and tut.host else null
		if g:
			eq = g.equipped
		SL.draw_all(self, sp, 28.0, eq, t)
