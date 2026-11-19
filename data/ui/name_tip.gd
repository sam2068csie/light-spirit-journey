extends Control
## 點一下就在旁邊跳出來的小名牌（例如貨幣的中文名稱）
##   NameTip.show_for(按到的節點, "星塵")：名牌出現在它下方、箭頭指著它
##   1.8 秒後自己淡出；點畫面其他地方也會收起來（那一下照常傳下去，不會被吃掉）
##   同一時間只有一個名牌
const UITheme := preload("res://data/ui/game_theme.gd")

const FS := 16
const PAD := Vector2(14, 8)
const ARROW := 7.0

static var _cur: Control = null

var text := ""
var _font: Font
var _box := Vector2.ZERO          # 名牌本體（不含箭頭）的大小
var _ax := 0.0                     # 箭頭在名牌上的 x


static func show_for(anchor: Control, s: String) -> void:
	hide_now()
	var layer := CanvasLayer.new()
	layer.layer = 120
	anchor.get_tree().root.add_child(layer)
	var t := new()
	t.text = s
	layer.add_child(t)
	t._place(anchor.get_global_rect())
	_cur = t


static func hide_now() -> void:
	if is_instance_valid(_cur):
		_cur.get_parent().queue_free()
	_cur = null


func _place(r: Rect2) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UITheme.bold_font()
	var tw := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(FS)).x
	_box = Vector2(tw, UITheme.fs(FS)) + PAD * 2.0
	size = _box + Vector2(0, ARROW)
	var vp := get_viewport_rect().size
	var x := clampf(r.get_center().x - _box.x / 2.0, 8.0, vp.x - _box.x - 8.0)
	position = Vector2(x, r.end.y + 4.0)
	_ax = clampf(r.get_center().x - x, 14.0, _box.x - 14.0)
	pivot_offset = Vector2(_ax, 0)
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0
	var tw_in := create_tween().set_parallel(true)
	tw_in.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(self, "modulate:a", 1.0, 0.1)
	var tw_out := create_tween()
	tw_out.tween_interval(1.8)
	tw_out.tween_property(self, "modulate:a", 0.0, 0.25)
	tw_out.tween_callback(func():
		if _cur == self:
			hide_now())
	queue_redraw()


func _input(e: InputEvent) -> void:
	if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed and _cur == self:
		hide_now()


func _draw() -> void:
	var bg := Color(0.1, 0.07, 0.2, 0.96)
	var edge := Color(1, 1, 1, 0.35)
	var top := ARROW
	var sb := UITheme.box(bg, 10, edge, 1, 0)
	draw_style_box(sb, Rect2(Vector2(0, top), _box))
	# 箭頭（往上指著按到的東西）
	var tri := PackedVector2Array([Vector2(_ax - ARROW, top + 1), Vector2(_ax, 0), Vector2(_ax + ARROW, top + 1)])
	draw_colored_polygon(tri, bg)
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2]]), edge, 1.0, true)
	draw_string(_font, Vector2(PAD.x, top + PAD.y + UITheme.fs(FS) * 0.85), text, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(FS), Color.WHITE)
