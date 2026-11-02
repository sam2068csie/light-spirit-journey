extends Control
## 大地圖（高一曦光大陸 g10_world.gd、高二光潮群島 g11_sea.gd）的共用底層
##   共用：虛擬搖桿與鍵盤移動、穿裝扮的光靈、主線目標橫幅與箭頭、序章劇情＋操作教學、紀念品小劇情、提示文字、存檔
##   子類別要提供：_world_key()（"g10"／"g11"）、_grade_name()（"高一"／"高二"）、_state()（存檔用的字典）、
##     focus_point(name, uid)（劇情鏡頭）、_goal_world(goal)（主線目標在地圖上的位置）、_tut_steps()（操作教學）

const UITheme := preload("res://data/ui/game_theme.gd")
const Game := preload("res://data/core/game.gd")
const Units := preload("res://data/core/units.gd")
const SL := preload("res://data/ui/spirit_look.gd")
const WS := preload("res://data/maps/world_story.gd")
const Tut := preload("res://data/ui/tutorial.gd")

signal enter_level(file: String)
signal story_changed(on: bool)
signal open_tower
signal pick_unit(uid: String)     # 進入地區／島（單元）：主選單接著打開那個單元的地圖

const W := 1152.0
const H := 648.0
const JOY_R := 64.0

var pos := Vector2.ZERO
var cam := Vector2.ZERO
var zoom := 1.0
var t := 0.0
var playing := false
var _busy := false
var _hold := false
var _hold_pt := Vector2.ZERO
var _joy_base := Vector2.ZERO          # 虛擬搖桿的中心（按下去的地方）
var _near := {}                        # 目前靠近的東西
var _overlay: Control
var _toast: Label
var _toast_t := 0.0
var story_focus := Vector2(-1, -1)     # 劇情播放時鏡頭看的地方；(-1, -1) = 跟著玩家
var _goal_text := ""
var _goal_pt := Vector2(-1, -1)        # 主線目標在地圖上的位置
var _goal_t := 0.0


# ================= 子類別要提供的 =================

func _world_key() -> String:
	return ""

func _grade_name() -> String:
	return ""

func _state() -> Dictionary:
	return {}

func focus_point(_name: String, _uid: String) -> Vector2:
	return Vector2(-1, -1)

func _goal_world(_gl: Dictionary) -> Vector2:
	return Vector2(-1, -1)

func _tut_steps() -> Array:
	return []


# ================= 共用 =================

## 大塊多邊形（陸地、島）：三角化只算一次，之後每幀直接畫三角形（不用每幀重新切）
var _tri := {}

func _fill(key: String, poly: PackedVector2Array, col: Color) -> void:
	if poly.size() < 3:
		return
	if not _tri.has(key):
		var idx := Geometry2D.triangulate_polygon(poly)
		_tri[key] = idx
	var idx2: PackedInt32Array = _tri[key]
	if idx2.is_empty():
		draw_colored_polygon(poly, col)
		return
	var cols := PackedColorArray()
	cols.resize(poly.size())
	cols.fill(col)
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx2, poly, cols)


func _add(key: String, id: String) -> void:
	if not _has(key, id):
		(_state()[key] as Array).append(id)
		_save()


## 畫穿著裝扮的光靈（和主畫面、衣櫃同一隻）；往左走就左右翻轉
func _draw_dressed(p: Vector2, r: float, left: bool) -> void:
	var C := Vector2(W, H) / 2.0
	var o := C - (cam + C) * zoom
	draw_set_transform(o + p * zoom, 0.0, Vector2(-zoom if left else zoom, zoom))
	SL.draw_all(self, Vector2.ZERO, r, Game.of(self).equipped, t)
	draw_set_transform(o, 0.0, Vector2(zoom, zoom))


func _draw_goal() -> void:
	if playing or _goal_text == "":
		return
	var tp := Vector2(-1, -1)
	if _goal_pt.x >= 0.0:
		var C := Vector2(W, H) / 2.0
		tp = C - (cam + C) * zoom + _goal_pt * zoom
	WS.draw_goal(self, _goal_text, tp, t)


## 虛擬搖桿（螢幕座標）：按著的時候畫在手指下面；沒按的時候左下角淡淡地提示
func _draw_joystick() -> void:
	if playing:
		return
	var font := UITheme.bold_font()
	if _hold:
		UITheme.dot(self, _joy_base, JOY_R + 6.0, Color(0.05, 0.08, 0.2, 0.35))
		draw_arc(_joy_base, JOY_R, 0, TAU, 48, Color(1, 1, 1, 0.45), 3.0, true)
		for k in 4:
			var a := k * PI / 2.0
			var tip := _joy_base + Vector2.from_angle(a) * (JOY_R - 12.0)
			draw_colored_polygon(PackedVector2Array([tip + Vector2.from_angle(a) * 6.0, tip + Vector2.from_angle(a + 2.3) * 6.0,
				tip + Vector2.from_angle(a - 2.3) * 6.0]), Color(1, 1, 1, 0.4))
		UITheme.dot(self, _hold_pt, 30.0, Color(1, 0.9, 0.55, 0.85))
		UITheme.dot(self, _hold_pt + Vector2(-6, -6), 12.0, Color(1, 1, 1, 0.45))
	else:
		var c := Vector2(110, H - 120)
		draw_arc(c, 42.0, 0, TAU, 40, Color(1, 1, 1, 0.16), 2.0, true)
		UITheme.dot(self, c, 18.0, Color(1, 1, 1, 0.14))
		draw_string(font, c + Vector2(-70, 66), "按住左半邊移動", HORIZONTAL_ALIGNMENT_CENTER, 140, 13, Color(1, 1, 1, 0.35))


func _goal_rect() -> Rect2:
	var font := UITheme.bold_font()
	var tw := font.get_string_size(_goal_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	return Rect2(Vector2((W - tw) / 2.0 - 16, 72), Vector2(tw + 32, 32))


func _gui_input(e: InputEvent) -> void:
	if playing:
		return
	# 虛擬搖桿：在畫面左半邊按下去，搖桿就出現在手指下面；拖動決定方向和速度
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and e.position.x < W * 0.5:
			_hold = true
			_joy_base = e.position
			_hold_pt = e.position
		elif not e.pressed:
			_hold = false
	elif e is InputEventMouseMotion and _hold:
		var d: Vector2 = e.position - _joy_base
		_hold_pt = _joy_base + d.limit_length(JOY_R)


func _has(key: String, id: String) -> bool:
	return (_state()[key] as Array).has(id)


func _key_dir() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		d.x -= 1
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		d.x += 1
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
		d.y -= 1
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
		d.y += 1
	return d.normalized()


func _refresh_goal() -> void:
	var g = Game.of(self)
	_goal_text = WS.goal_text(g, _grade_name())
	_goal_pt = _goal_world(WS.next_goal(g))


func _save() -> void:
	_state()["pos"] = [roundi(pos.x), roundi(pos.y)]
	Game.of(self).save_review()


## 螢幕上的一塊（地圖座標 → 螢幕）；整塊不在畫面上就回傳空的（教學會跳過那一句）
func _scr(p: Vector2, half: Vector2) -> Rect2:
	var C := Vector2(W, H) / 2.0
	var sp := C - (cam + C) * zoom + p * zoom
	var r := Rect2(sp - half, half * 2.0)
	return r if Rect2(0, 0, W, H).encloses(r) else Rect2()


func _show_toast(s: String) -> void:
	_toast.text = s
	_toast_t = 2.6


func _story_check() -> void:
	await get_tree().create_timer(0.7).timeout
	while is_inside_tree() and not is_visible_in_tree():
		await get_tree().create_timer(0.3).timeout
	if not is_inside_tree() or playing:
		return
	var g = Game.of(self)
	if not WS.seen(g, _world_key()):
		await WS.play(self, _world_key(), WS.STORY[_world_key()], WS.TITLES[_world_key()])
		if is_inside_tree():
			_refresh_goal()
			await get_tree().create_timer(0.3).timeout
			Tut.run(self, _tut_steps())
		return
	var su := WS.pending_souvenir(g, _grade_name())
	if su != "":
		await WS.play(self, "sv_" + su, WS.souvenir_lines(su), "點亮！" + String(WS.Units.unit(su).title), su)


func close_overlay() -> bool:
	if is_instance_valid(_overlay) and not _overlay.is_queued_for_deletion():
		_overlay.queue_free()
		_overlay = null
		return true
	return false


func refresh() -> void:
	queue_redraw()
