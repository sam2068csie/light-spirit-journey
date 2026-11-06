extends Control
## 大地圖（高一曦光大陸 g10_world.gd、高二光潮群島 g11_sea.gd）的共用底層
##   共用：虛擬搖桿與鍵盤移動、穿裝扮的光靈、主線目標橫幅與箭頭、序章劇情＋操作教學、紀念品小劇情、提示文字、存檔
##   點亮：每個地區／島的亮度跟著單元完成度（沒點亮時灰暗、動態又淡又慢）；完成度變高後回到地圖，會播一段點亮動畫
##   子類別要提供：_world_key()（"g10"／"g11"）、_grade_name()（"高一"／"高二"）、_state()（存檔用的字典）、
##     focus_point(name, uid)（劇情鏡頭）、_goal_world(goal)（主線目標在地圖上的位置）、_tut_steps()（操作教學）

const UITheme := preload("res://data/ui/game_theme.gd")
const Game := preload("res://data/core/game.gd")
const Units := preload("res://data/core/units.gd")
const SL := preload("res://data/ui/spirit_look.gd")
const WS := preload("res://data/maps/world_story.gd")
const Tut := preload("res://data/ui/tutorial.gd")
const ExamPick := preload("res://data/ui/exam_pick.gd")

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
var _exam_open := false                # 「這次段考考什麼？」開著


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

func _view() -> Rect2:
	return Rect2()

## 點亮用：有哪些地區／島（key = 單元 id）、各自的完成度（0～1）、在地圖上的範圍、名字
func _light_keys() -> Array:
	return []

func _light_target(_key: String) -> float:
	return 1.0

func _light_box(_key: String) -> Rect2:
	return Rect2()

func _light_name(_key: String) -> String:
	return ""


# ================= 點亮：地區／島的亮度 =================
## 亮度 k（0～1）＝單元完成度；畫面上用 lit_curve(k)（前半段亮得慢，全部點亮才是原本的樣子）
##   陸地、地標那層套 island_light.gdshader（lit 0 → 冷灰偏暗）；地區自己的動態層跟著調淡（0.3 + 0.7e²）、時間變慢
##   存檔 _state().lit_seen 記著「上次在地圖上看到的亮度」：完成度變高了，等那一區出現在畫面上，花 LIGHT_DUR 秒慢慢亮起來
const LIGHT_SHADER := preload("res://data/maps/island_light.gdshader")
const LIGHT_DUR := 2.8

var _lit := {}            # key → 畫面上現在的亮度（動畫中會在 from、to 之間）
var _lit_mat := {}        # key → 陸地／地標那層的材質
var _lit_fx := {}         # key → 那一區自己的動態層
var _lit_anim := {}       # key → {from, to, t}（t < 0：等那一區出現在畫面上才開始）
var debug_lit := -1.0     # 截圖用：>= 0 時每一區都用這個亮度（不播動畫）


static func lit_curve(k: float) -> float:
	return pow(clampf(k, 0.0, 1.0), 1.5)


## 畫面上的亮度（0～1，還沒算過就當作全亮）
func light_k(key: String) -> float:
	var k := float(_lit.get(key, 1.0))
	return 1.0 if k < 0.0 else k


func light_e(key: String) -> float:
	return lit_curve(light_k(key))


## 動態層的時間：沒點亮的地區走得慢（風車、水流、光點都慢吞吞的）
func light_time(key: String) -> float:
	return t * (0.2 + 0.8 * light_e(key))


func _light_mat(key: String) -> ShaderMaterial:
	if not _lit_mat.has(key):
		var m := ShaderMaterial.new()
		m.shader = LIGHT_SHADER
		_lit_mat[key] = m
		_lit[key] = -1.0
	return _lit_mat[key]


func _light_show(key: String, k: float) -> void:
	_lit[key] = k
	var e := lit_curve(k)
	(_lit_mat[key] as ShaderMaterial).set_shader_parameter("lit", e)
	if _lit_fx.has(key):
		(_lit_fx[key] as CanvasItem).modulate.a = 0.3 + 0.7 * e * e


func _lit_seen() -> Dictionary:
	var st := _state()
	if not (st.get("lit_seen") is Dictionary):
		st["lit_seen"] = {}
	return st["lit_seen"]


## 照完成度更新亮度；比上次看到的亮 → 排一段點亮動畫
func _apply_light() -> void:
	if _lit_mat.is_empty():
		return
	var seen := _lit_seen()
	for key in _light_keys():
		if not _lit_mat.has(key):
			continue
		var target := clampf(debug_lit if debug_lit >= 0.0 else _light_target(key), 0.0, 1.0)
		if debug_lit >= 0.0:
			_lit_anim.erase(key)
			_light_show(key, target)
			continue
		if _lit_anim.has(key):
			_lit_anim[key]["to"] = maxf(float(_lit_anim[key]["to"]), target)
			continue
		var was := float(seen.get(key, -1.0))
		if was >= 0.0 and target > was + 0.001:
			_lit_anim[key] = {"from": was, "to": target, "t": -1.0}
			_light_show(key, was)
			continue
		if not is_equal_approx(target, float(_lit[key])):
			_light_show(key, target)
		if was < 0.0 or not is_equal_approx(was, target):
			seen[key] = target       # 第一次看到（或完成度變低）：直接記下來，不播動畫


## 每幀：點亮動畫（那一區出現在畫面上、沒有劇情或視窗擋著才開始）
func _light_tick(delta: float) -> void:
	for key in _lit_anim.keys():
		var a: Dictionary = _lit_anim[key]
		if float(a.t) < 0.0:
			if playing or _busy or not is_visible_in_tree() or is_instance_valid(_overlay):
				continue
			if not _view().grow(-60.0).intersects(_light_box(key)):
				continue
			a.t = 0.0
			_light_start(key, a)
		a.t = float(a.t) + delta
		var f := clampf(float(a.t) / LIGHT_DUR, 0.0, 1.0)
		_light_show(key, lerpf(float(a.from), float(a.to), f * f * (3.0 - 2.0 * f)))
		if f >= 1.0:
			_lit_seen()[key] = float(a.to)
			_lit_anim.erase(key)
			Game.of(self).save_review()


func _light_start(key: String, a: Dictionary) -> void:
	var g = Game.of(self)
	for i in 4:
		g.play("bell", Game.semi(Game.scale_semi(2 + i * 2)), -12.0, 0.22 * i)
	var nm := _light_name(key)
	if nm != "" and _toast != null:
		_show_toast("「%s」的世界之光全部點亮了！" % nm if float(a.to) >= 0.999 else "「%s」又亮了一點" % nm)


## 正在播的點亮動畫：[{box, f（0～1）}]，子類別在動態層畫光圈和光點
func _light_bursts() -> Array:
	var out := []
	for key in _lit_anim:
		var a: Dictionary = _lit_anim[key]
		if float(a.t) >= 0.0:
			out.append({"key": key, "box": _light_box(key), "f": clampf(float(a.t) / LIGHT_DUR, 0.0, 1.0)})
	return out


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
	# 點上方的金色主線橫幅：選這次段考的範圍（主線先帶你去那些單元）
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed and _goal_text != "" \
			and _goal_rect().grow(6.0).has_point(e.position):
		open_exam_pick()
		accept_event()
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
	_goal_pt = _goal_world(WS.next_goal(g, WS.my_grade(g, _grade_name())))


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
	# 這學期還沒選過段考範圍（換學期了、或是舊存檔）：問一次
	if is_inside_tree() and not playing and WS.needs_exam_pick(g, WS.my_grade(g, _grade_name())):
		open_exam_pick()


## 「這次段考考什麼？」：放在最上層（主畫面），選完更新主線橫幅和箭頭
func open_exam_pick() -> void:
	if playing or _exam_open:
		return
	var host: Node = get_tree().current_scene if get_tree().current_scene is Control else self
	_exam_open = true
	_hold = false
	playing = true          # 視窗開著時地圖不動、橫幅先收起來
	var layer := ExamPick.open(host, WS.my_grade(Game.of(self), _grade_name()), func(_gr: String):
		if is_inside_tree():
			_refresh_goal())
	layer.tree_exited.connect(func():
		_exam_open = false
		playing = false)


func close_overlay() -> bool:
	if is_instance_valid(_overlay) and not _overlay.is_queued_for_deletion():
		_overlay.queue_free()
		_overlay = null
		return true
	return false


func refresh() -> void:
	queue_redraw()
