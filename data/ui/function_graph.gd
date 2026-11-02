@tool
class_name FunctionGraph
extends Node2D
## 繪製指數 / 對數函數圖形（Godot 4.x）
##   指數：y = a^(x - h) + k
##   對數：y = log_a(x - h) + k
## 可在編輯器中即時預覽（@tool），所有關卡共用這個節點。

enum FuncType { EXPONENTIAL, LOGARITHM }

@export var func_type: FuncType = FuncType.EXPONENTIAL:
	set(v):
		func_type = v
		queue_redraw()
@export_range(0.1, 5.0, 0.01) var base_a: float = 2.0:
	set(v):
		base_a = v
		queue_redraw()
@export var shift_h: float = 0.0:
	set(v):
		shift_h = v
		queue_redraw()
@export var shift_k: float = 0.0:
	set(v):
		shift_k = v
		queue_redraw()

@export_group("座標範圍與外觀")
@export var x_range := Vector2(-6, 6)
@export var y_range := Vector2(-4, 8)
@export var plot_size := Vector2(600, 400)
@export var curve_color := Color(0.25, 0.55, 1.0)
@export var show_asymptote := true
@export var tolerance := 0.15  ## 判定「通過某點」的容許誤差（y 方向）

## 關卡中的目標點（寶石、鎖孔…），通過時會亮起
var markers: Array[Vector2] = []:
	set(v):
		markers = v
		queue_redraw()


# ---------- 數學 ----------

func is_valid_base() -> bool:
	return base_a > 0.0 and not is_equal_approx(base_a, 1.0)


func f(x: float) -> float:
	if func_type == FuncType.EXPONENTIAL:
		return pow(base_a, x - shift_h) + shift_k
	var t := x - shift_h
	if t <= 0.0:
		return NAN  # 對數的定義域：x > h
	return log(t) / log(base_a) + shift_k


func passes_through(p: Vector2) -> bool:
	var y := f(p.x)
	return not is_nan(y) and absf(y - p.y) < tolerance


## 漸近線：指數為水平線 y = k，對數為鉛直線 x = h
func asymptote_text() -> String:
	if func_type == FuncType.EXPONENTIAL:
		return "y = %s" % _fmt(shift_k)
	return "x = %s" % _fmt(shift_h)


# ---------- 座標轉換 ----------

func to_screen(p: Vector2) -> Vector2:
	var sx := (p.x - x_range.x) / (x_range.y - x_range.x) * plot_size.x
	var sy := plot_size.y - (p.y - y_range.x) / (y_range.y - y_range.x) * plot_size.y
	return Vector2(sx, sy)


func to_world(s: Vector2) -> Vector2:
	var wx := s.x / plot_size.x * (x_range.y - x_range.x) + x_range.x
	var wy := (plot_size.y - s.y) / plot_size.y * (y_range.y - y_range.x) + y_range.x
	return Vector2(wx, wy)


# ---------- 繪圖 ----------

func _draw() -> void:
	_draw_grid()
	if not is_valid_base():
		draw_string(ThemeDB.fallback_font, Vector2(12, 28),
			"底數必須 a > 0 且 a ≠ 1（a = 1 時只是水平線 y = 1）",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.ORANGE_RED)
		_draw_markers()
		return
	if show_asymptote:
		_draw_asymptote()
	_draw_curve()
	_draw_markers()


func _draw_grid() -> void:
	var grid_col := Color(1, 1, 1, 0.08)
	var axis_col := Color(1, 1, 1, 0.6)
	var font := ThemeDB.fallback_font
	for x in range(ceili(x_range.x), floori(x_range.y) + 1):
		var a := to_screen(Vector2(x, y_range.x))
		var b := to_screen(Vector2(x, y_range.y))
		draw_line(a, b, axis_col if x == 0 else grid_col, 2.0 if x == 0 else 1.0)
		if x != 0:
			draw_string(font, to_screen(Vector2(x, 0)) + Vector2(-4, 18), str(x),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, axis_col)
	for y in range(ceili(y_range.x), floori(y_range.y) + 1):
		var a := to_screen(Vector2(x_range.x, y))
		var b := to_screen(Vector2(x_range.y, y))
		draw_line(a, b, axis_col if y == 0 else grid_col, 2.0 if y == 0 else 1.0)
		if y != 0:
			draw_string(font, to_screen(Vector2(0, y)) + Vector2(-20, 4), str(y),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, axis_col)


func _draw_curve() -> void:
	# 取樣 600 點；超出畫面或不在定義域就斷開，避免畫出錯誤的連線
	var steps := 600
	var pts := PackedVector2Array()
	for i in steps + 1:
		var x := lerpf(x_range.x, x_range.y, float(i) / steps)
		var y := f(x)
		if is_nan(y) or y < y_range.x - 0.5 or y > y_range.y + 0.5:
			_flush(pts)
			pts = PackedVector2Array()
			continue
		pts.append(to_screen(Vector2(x, y)))
	_flush(pts)


func _flush(pts: PackedVector2Array) -> void:
	if pts.size() >= 2:
		draw_polyline(pts, curve_color, 3.0, true)


func _draw_asymptote() -> void:
	var col := Color(1.0, 0.35, 0.35, 0.9)  # 遊戲中當作「雷射牆」
	if func_type == FuncType.EXPONENTIAL:
		draw_dashed_line(to_screen(Vector2(x_range.x, shift_k)),
			to_screen(Vector2(x_range.y, shift_k)), col, 2.0, 10.0)
	else:
		draw_dashed_line(to_screen(Vector2(shift_h, y_range.x)),
			to_screen(Vector2(shift_h, y_range.y)), col, 2.0, 10.0)


func _draw_markers() -> void:
	for m in markers:
		var lit := is_valid_base() and passes_through(m)
		var c := Color.GOLD if lit else Color(0.6, 0.6, 0.6)
		draw_circle(to_screen(m), 9.0 if lit else 7.0, c)


func _fmt(v: float) -> String:
	return str(snappedf(v, 0.01))
