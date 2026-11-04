extends RefCounted
## 把一大堆「沒有貼圖」的多邊形、線條收集成一個 ArrayMesh，一次畫出去
##   ・相容模式（手機用的 gl_compatibility）每個 draw_colored_polygon、反鋸齒線條都是一次 draw call
##     → 靜態的地圖一畫就是上千次；收成網格之後只剩「貼圖和網格交替的次數」
##   ・用法和 CanvasItem 一樣（L.draw_colored_polygon(...)），畫的順序完全保留：
##     遇到有貼圖的東西（draw_texture_rect、draw_string）就先把累積的網格送出，再畫它
##   ・圓點（disc）和柔光（soft）也直接做成網格：邊緣用透明的頂點淡出，看起來跟貼圖一樣，又不用換貼圖
##   ・網格要一直留著（keep），否則資源被釋放，畫面上的東西就不見了

var ci: CanvasItem
var keep: Array = []
var _v := PackedVector2Array()
var _c := PackedColorArray()
var _i := PackedInt32Array()
const HAIR := 1.6          # width = -1（一像素的細線）在世界座標裡的粗細
const FEATHER := 1.4       # 反鋸齒：線條外側淡出的寬度


func _init(target: CanvasItem) -> void:
	ci = target


func flush() -> void:
	if _i.is_empty():
		return
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = _v
	arr[Mesh.ARRAY_COLOR] = _c
	arr[Mesh.ARRAY_INDEX] = _i
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	ci.draw_mesh(m, null)
	keep.append(m)
	_v = PackedVector2Array()
	_c = PackedColorArray()
	_i = PackedInt32Array()


# ---------- 會用到貼圖的：直接交給真正的畫布 ----------

func draw_texture_rect(tex: Texture2D, rect: Rect2, tile: bool, modulate := Color.WHITE, transpose := false) -> void:
	flush()
	ci.draw_texture_rect(tex, rect, tile, modulate, transpose)


func draw_string(font: Font, pos: Vector2, text: String, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, size := 16, color := Color.WHITE) -> void:
	flush()
	ci.draw_string(font, pos, text, align, width, size, color)


func draw_string_outline(font: Font, pos: Vector2, text: String, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, size := 16, ow := 1, color := Color.WHITE) -> void:
	flush()
	ci.draw_string_outline(font, pos, text, align, width, size, ow, color)


func draw_set_transform(pos: Vector2, rot := 0.0, scale := Vector2.ONE) -> void:
	flush()
	ci.draw_set_transform(pos, rot, scale)


# ---------- 收進網格的 ----------

func _tri(pts: PackedVector2Array, cols: PackedColorArray) -> void:
	if pts.size() < 3:
		return
	var idx := Geometry2D.triangulate_polygon(pts)
	if idx.is_empty():
		return
	var base := _v.size()
	_v.append_array(pts)
	_c.append_array(cols)
	for k in idx:
		_i.append(base + k)


func draw_colored_polygon(pts: PackedVector2Array, color: Color, _uvs := PackedVector2Array(), _tex: Texture2D = null) -> void:
	var cols := PackedColorArray()
	cols.resize(pts.size())
	cols.fill(color)
	_tri(pts, cols)


func draw_polygon(pts: PackedVector2Array, cols: PackedColorArray, _uvs := PackedVector2Array(), _tex: Texture2D = null) -> void:
	if cols.size() == 1:
		draw_colored_polygon(pts, cols[0])
		return
	_tri(pts, cols)


func draw_rect(r: Rect2, color: Color, filled := true, width := -1.0, aa := false) -> void:
	if filled:
		var base := _v.size()
		_v.append_array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		for k in 4:
			_c.append(color)
		_i.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
		return
	var w := HAIR if width <= 0.0 else width
	var g := r.grow(w / 2.0)
	_strip(PackedVector2Array([g.position, Vector2(g.end.x, g.position.y), g.end, Vector2(g.position.x, g.end.y), g.position]), color, w, aa)


func draw_line(a: Vector2, b: Vector2, color: Color, width := -1.0, aa := false) -> void:
	_strip(PackedVector2Array([a, b]), color, HAIR if width <= 0.0 else width, aa)


func draw_multiline(pts: PackedVector2Array, color: Color, width := -1.0, aa := false) -> void:
	var w := HAIR if width <= 0.0 else width
	for k in range(0, pts.size() - 1, 2):
		_strip(PackedVector2Array([pts[k], pts[k + 1]]), color, w, aa)


func draw_polyline(pts: PackedVector2Array, color: Color, width := -1.0, aa := false) -> void:
	_strip(pts, color, HAIR if width <= 0.0 else width, aa)


func draw_arc(c: Vector2, r: float, a0: float, a1: float, n: int, color: Color, width := -1.0, aa := false) -> void:
	var pts := PackedVector2Array()
	for k in n:
		pts.append(c + Vector2.from_angle(lerpf(a0, a1, k / float(n - 1))) * r)
	_strip(pts, color, HAIR if width <= 0.0 else width, aa)


## 實心圓（邊緣反鋸齒）：取代 UITheme.dot_n 的圓形貼圖
func disc(c: Vector2, r: float, color: Color) -> void:
	var n := clampi(int(r * 0.7) + 10, 12, 64)
	var clear := Color(color.r, color.g, color.b, 0.0)
	var base := _v.size()
	_v.append(c)
	_c.append(color)
	var ri := maxf(0.0, r - FEATHER * 0.5)
	var ro := r + FEATHER * 0.5
	for k in n:
		var d := Vector2.from_angle(TAU * k / n)
		_v.append(c + d * ri)
		_v.append(c + d * ro)
		_c.append(color)
		_c.append(clear)
	for k in n:
		var a := base + 1 + k * 2
		var b := base + 1 + ((k + 1) % n) * 2
		_i.append_array([base, a, b, a, a + 1, b, b, a + 1, b + 1])


## 柔光橢圓（中間最亮、往外平滑變透明）：取代柔光貼圖
const _SOFT_D := [0.0, 0.25, 0.5, 0.75, 1.0]
const _SOFT_A := [1.0, 0.844, 0.5, 0.156, 0.0]
func soft(c: Vector2, r: Vector2, color: Color) -> void:
	var n := 28
	var base := _v.size()
	_v.append(c)
	_c.append(color)
	for j in range(1, 5):
		var col := Color(color.r, color.g, color.b, color.a * _SOFT_A[j])
		for k in n:
			var d := Vector2.from_angle(TAU * k / n)
			_v.append(c + Vector2(d.x * r.x, d.y * r.y) * _SOFT_D[j])
			_c.append(col)
	for k in n:
		_i.append_array([base, base + 1 + k, base + 1 + (k + 1) % n])
	for j in 3:
		var r0 := base + 1 + j * n
		var r1 := r0 + n
		for k in n:
			var k1 := (k + 1) % n
			_i.append_array([r0 + k, r1 + k, r0 + k1, r0 + k1, r1 + k, r1 + k1])


## 一條有寬度的折線：每個點往兩邊推出去（轉角用兩段法線的平均），反鋸齒就在外側再加一圈透明的邊
func _strip(src: PackedVector2Array, color: Color, w: float, aa: bool) -> void:
	var pts := PackedVector2Array()
	for q in src:
		if pts.is_empty() or pts[pts.size() - 1].distance_squared_to(q) > 0.0001:
			pts.append(q)
	var n := pts.size()
	if n < 2:
		return
	var hw := w / 2.0
	var clear := Color(color.r, color.g, color.b, 0.0)
	var base := _v.size()
	var per := 4 if aa else 2
	for k in n:
		var d: Vector2
		var sc := 1.0
		if k == 0:
			d = (pts[1] - pts[0]).normalized()
		elif k == n - 1:
			d = (pts[k] - pts[k - 1]).normalized()
		else:
			var d0 := (pts[k] - pts[k - 1]).normalized()
			var d1 := (pts[k + 1] - pts[k]).normalized()
			d = d0 + d1
			if d.length_squared() < 0.0001:
				d = d0
			d = d.normalized()
			sc = 1.0 / maxf(0.35, d.dot(d0))
		var nm := d.orthogonal() * sc
		var p := pts[k]
		_v.append(p + nm * hw)
		_v.append(p - nm * hw)
		_c.append(color)
		_c.append(color)
		if aa:
			_v.append(p + nm * (hw + FEATHER))
			_v.append(p - nm * (hw + FEATHER))
			_c.append(clear)
			_c.append(clear)
	for k in n - 1:
		var a := base + k * per
		var b := a + per
		_i.append_array([a, b, a + 1, a + 1, b, b + 1])
		if aa:
			_i.append_array([a + 2, b + 2, a, a, b + 2, b])
			_i.append_array([a + 1, b + 1, a + 3, a + 3, b + 1, b + 3])
