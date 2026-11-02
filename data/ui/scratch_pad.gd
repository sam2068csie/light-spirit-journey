extends Control
## 計算紙：整個關卡畫面都可以手寫
##   ・右上角暫停鍵左邊的筆按鈕：按一下進入「書寫中」——畫面蓋一層淡淡的暗色，點到哪裡就寫在哪裡（底下的畫面點不到）
##   ・工具列：筆、橡皮擦（擦掉碰到的整筆）、復原、全部清除、收起
##   ・收起：筆跡留在畫面上，但點擊會穿透，可以直接作答；再按一次筆按鈕就能繼續寫
##   ・同一題的各步驟都保留；換下一題時，關卡呼叫 clear() 清掉
##   ・計時不會暫停（它是計算紙，不是暫停鍵）
## 用法：var pad = preload("res://data/ui/scratch_pad.gd").attach(self, top_bar, pause_button)
const UITheme := preload("res://data/ui/game_theme.gd")
const Game := preload("res://data/core/game.gd")

const INK := Color(1.0, 0.93, 0.62)
const INK_W := 3.0
const ERASE_R := 14.0

var drawing := false          # 書寫中（擋住底下的點擊）
var tool := "pen"             # "pen"／"eraser"
var strokes: Array = []       # 每一筆：PackedVector2Array
var history: Array = []       # 復原用：{"add": 筆} 或 {"erase": [[index, 筆], …]} 或 {"clear": [全部的筆]}
var _cur := PackedVector2Array()
var _down := false
var _erased_now: Array = []
var _btn: Button
var _dot: Control
var _bar: PanelContainer
var _tool_btns := {}
var _dim_a := 0.0


static func attach(host: Control, top: Container, before: Control) -> Control:
	var pad = new()
	host.add_child(pad)
	pad._make_button(top, before)
	pad.move_to_front.call_deferred()      # 蓋在關卡畫面最上面（之後跳出的視窗還是在它上面）
	return pad


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_bar()


func _make_button(top: Container, before: Control) -> void:
	_btn = UITheme.round_button("pen", 44)
	_btn.tooltip_text = UITheme.kb("計算紙（D）", "計算紙")
	_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_btn.pressed.connect(toggle)
	top.add_child(_btn)
	top.move_child(_btn, before.get_index())
	# 收起時有筆跡：按鈕右上角一個小金點
	_dot = Control.new()
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dot.position = Vector2(30, 2)
	_dot.size = Vector2(12, 12)
	_dot.draw.connect(func(): UITheme.dot(_dot, Vector2(6, 6), 5.0, UITheme.ACCENT))
	_dot.visible = false
	_btn.add_child(_dot)


func _build_bar() -> void:
	_bar = PanelContainer.new()
	_bar.add_theme_stylebox_override("panel", UITheme.box(Color(0.06, 0.08, 0.2, 0.96), 16, UITheme.ACCENT, 2, 8))
	_bar.visible = false
	_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	_bar.add_child(hb)
	for spec in [["pen", "✎ 筆"], ["eraser", "◌ 橡皮擦"], ["undo", "↶ 復原"], ["clear", "清除"], ["close", "✓ 收起"]]:
		var b := Button.new()
		b.text = spec[1]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 44)
		b.add_theme_font_size_override("font_size", UITheme.fs(15))
		var id: String = spec[0]
		if id == "close":
			UITheme.accent_button(b, 15)
		else:
			UITheme.tight(b, 10)
		b.pressed.connect(func(): _on_tool(id))
		hb.add_child(b)
		_tool_btns[id] = b
	_refresh_tools()


func _on_tool(id: String) -> void:
	match id:
		"pen", "eraser":
			tool = id
		"undo":
			undo()
		"clear":
			if not strokes.is_empty():
				history.append({"clear": strokes.duplicate()})
				strokes.clear()
		"close":
			set_drawing(false)
			return
	_refresh_tools()
	queue_redraw()


func _refresh_tools() -> void:
	for id in ["pen", "eraser"]:
		var b: Button = _tool_btns[id]
		var on: bool = tool == id
		b.add_theme_color_override("font_color", UITheme.ACCENT if on else UITheme.TEXT)
		b.add_theme_stylebox_override("normal", UITheme.box(Color(0.96, 0.78, 0.3, 0.22) if on else UITheme.PANEL_LIGHT, 12,
			UITheme.ACCENT if on else Color(1, 1, 1, 0.08), 2 if on else 1, 10))
	(_tool_btns["undo"] as Button).disabled = history.is_empty()
	(_tool_btns["clear"] as Button).disabled = strokes.is_empty()


func toggle() -> void:
	set_drawing(not drawing)


func set_drawing(on: bool) -> void:
	drawing = on
	_down = false
	_cur = PackedVector2Array()
	mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	_bar.visible = on
	if on:
		_bar.reset_size()
		var r := _btn.get_global_rect()
		_bar.position = Vector2(clampf(r.end.x - _bar.size.x, 8.0, size.x - _bar.size.x - 8.0), r.end.y + 8.0)
		Game.of(self).play("blip", 1.3, -12.0)
	_refresh_tools()
	_dot.visible = not on and not strokes.is_empty()
	_dot.queue_redraw()
	queue_redraw()


## 換下一題：清掉筆跡（也收起來）
func clear() -> void:
	strokes.clear()
	history.clear()
	if drawing:
		set_drawing(false)
	_dot.visible = false
	queue_redraw()


func undo() -> void:
	if history.is_empty():
		return
	var h: Dictionary = history.pop_back()
	if h.has("add"):
		strokes.erase(h.add)
	elif h.has("erase"):
		var list: Array = h.erase
		for k in range(list.size() - 1, -1, -1):
			strokes.insert(mini(int(list[k][0]), strokes.size()), list[k][1])
	elif h.has("clear"):
		strokes = (h.clear as Array).duplicate()
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if not drawing:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_down = true
			if tool == "pen":
				_cur = PackedVector2Array([e.position])
			else:
				_erased_now = []
				_erase_at(e.position)
		else:
			_down = false
			if tool == "pen" and _cur.size() > 0:
				if _cur.size() == 1:
					_cur.append(_cur[0] + Vector2(0.5, 0.5))     # 點一下也留一個點
				strokes.append(_cur)
				history.append({"add": _cur})
				_cur = PackedVector2Array()
			elif tool == "eraser" and not _erased_now.is_empty():
				history.append({"erase": _erased_now})
			_refresh_tools()
		accept_event()
		queue_redraw()
	elif e is InputEventMouseMotion and _down:
		if tool == "pen":
			if _cur.is_empty() or _cur[_cur.size() - 1].distance_to(e.position) > 1.5:
				_cur.append(e.position)
		else:
			_erase_at(e.position)
		accept_event()
		queue_redraw()


func _erase_at(p: Vector2) -> void:
	for k in range(strokes.size() - 1, -1, -1):
		var s: PackedVector2Array = strokes[k]
		for q in s:
			if q.distance_to(p) < ERASE_R:
				_erased_now.append([k, s])
				strokes.remove_at(k)
				break


func _unhandled_input(e: InputEvent) -> void:
	if UITheme.is_touch():
		return
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_D:
		var fo := get_viewport().gui_get_focus_owner()
		if fo is LineEdit or fo is TextEdit:
			return
		toggle()
		get_viewport().set_input_as_handled()
	elif drawing and e.is_action_pressed("ui_cancel"):
		set_drawing(false)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var target := 0.18 if drawing else 0.0
	if absf(_dim_a - target) > 0.002:
		_dim_a = lerpf(_dim_a, target, 1.0 - exp(-12.0 * delta))
		queue_redraw()


func _draw() -> void:
	if _dim_a > 0.003:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.1, _dim_a))
	var a := 1.0 if drawing else 0.8
	var c := Color(INK.r, INK.g, INK.b, a)
	var outline := Color(0.05, 0.05, 0.12, 0.55 * a)
	for s in strokes:
		_line(s, outline, INK_W + 3.0)
	if _cur.size() > 1:
		_line(_cur, outline, INK_W + 3.0)
	for s in strokes:
		_line(s, c, INK_W)
	if _cur.size() > 1:
		_line(_cur, c, INK_W)
	if drawing and tool == "eraser" and _down:
		var mp := get_local_mouse_position()
		draw_arc(mp, ERASE_R, 0, TAU, 24, Color(1, 1, 1, 0.6), 1.5, true)


func _line(s: PackedVector2Array, c: Color, w: float) -> void:
	draw_polyline(s, c, w, true)
	UITheme.dot(self, s[0], w / 2.0, c)
	UITheme.dot(self, s[s.size() - 1], w / 2.0, c)
