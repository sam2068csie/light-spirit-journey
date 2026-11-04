extends RefCounted
## 把一大堆「沒有貼圖」的多邊形、線條收集成一個 ArrayMesh，一次畫出去
##   ・相容模式（手機用的 gl_compatibility）每個 draw_colored_polygon、反鋸齒線條都是一次 draw call
##     → 靜態的地圖一畫就是上千次；收成網格之後只剩「貼圖和網格交替的次數」
##   ・用法和 CanvasItem 一樣（L.draw_colored_polygon(...)），畫的順序完全保留：
##     遇到有貼圖的東西（draw_texture_rect、draw_string）就先把累積的網格送出，再畫它
##   ・圓點（disc）和柔光（soft）用同一張小貼圖集（atlas）裡的圖：每個只要 2 個三角形，
##     多邊形就取貼圖集裡的白色小方塊 → 全部共用一張貼圖，整層還是一次畫完
##   ・網格要一直留著（keep），否則資源被釋放，畫面上的東西就不見了

var ci: CanvasItem
var keep: Array = []
var _v := PackedVector2Array()
var _c := PackedColorArray()
var _i := PackedInt32Array()
var _u := PackedVector2Array()
static var _atlas: Texture2D
const AW := 512.0
const AH := 136.0
## 貼圖集裡每張圖的位置（左上角 x、邊長），中間留 6 像素空隙，線性取樣才不會吃到隔壁
const DISC := {128: [2.0, 128.0], 64: [136.0, 64.0], 32: [206.0, 32.0], 16: [244.0, 16.0]}
const SOFT := [266.0, 128.0]
const WHITE_UV := Vector2(408.0 / AW, 10.0 / AH)


static func atlas() -> Texture2D:
	if _atlas != null:
		return _atlas
	var img := Image.create_empty(int(AW), int(AH), false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for key in DISC:
		var n: int = key
		var x0: float = DISC[n][0]
		var half := n / 2.0
		var ramp := maxf(1.0, n / 96.0)
		for y in n:
			for x in n:
				var d := Vector2(x + 0.5 - half, y + 0.5 - half).length()
				img.set_pixel(int(x0) + x, 2 + y, Color(1, 1, 1, clampf((half - d) / ramp + 0.5, 0.0, 1.0)))
	var sn := int(SOFT[1])
	for y in sn:
		for x in sn:
			var d := Vector2(x + 0.5 - sn / 2.0, y + 0.5 - sn / 2.0).length() / (sn / 2.0)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(int(SOFT[0]) + x, 2 + y, Color(1, 1, 1, a * a * (3.0 - 2.0 * a)))
	for y in 16:
		for x in 16:
			img.set_pixel(400 + x, 2 + y, Color.WHITE)
	_atlas = ImageTexture.create_from_image(img)
	return _atlas
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
	arr[Mesh.ARRAY_TEX_UV] = _u
	arr[Mesh.ARRAY_INDEX] = _i
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	ci.draw_mesh(m, atlas())
	keep.append(m)
	_v = PackedVector2Array()
	_c = PackedColorArray()
	_u = PackedVector2Array()
	_i = PackedInt32Array()


## 補上白色方塊的 UV（多邊形、線條用）
func _white(n: int) -> void:
	for k in n:
		_u.append(WHITE_UV)


## 一個貼圖集裡的方塊（2 個三角形）
func _quad(r: Rect2, color: Color, x0: float, size: float) -> void:
	var base := _v.size()
	_v.append_array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var u0 := Vector2(x0 / AW, 2.0 / AH)
	var u1 := Vector2((x0 + size) / AW, (2.0 + size) / AH)
	_u.append_array([u0, Vector2(u1.x, u0.y), u1, Vector2(u0.x, u1.y)])
	for k in 4:
		_c.append(color)
	_i.append_array([base, base + 1, base + 2, base, base + 2, base + 3])


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
	_white(pts.size())
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
		_white(4)
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


## 實心圓：貼圖集裡的圓（n 和 UITheme.dot_n 一樣，越小的圓用越小的圖，邊緣才不會糊）
func disc(c: Vector2, r: float, color: Color, n := 128) -> void:
	var key := 128 if n >= 128 else (64 if n >= 64 else (32 if n >= 32 else 16))
	_quad(Rect2(c.x - r, c.y - r, 2.0 * r, 2.0 * r), color, DISC[key][0], DISC[key][1])


## 柔光橢圓（中間最亮、往外平滑變透明）
func soft(c: Vector2, r: Vector2, color: Color) -> void:
	_quad(Rect2(c - r, r * 2.0), color, SOFT[0], SOFT[1])


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
		_u.append(WHITE_UV)
		_u.append(WHITE_UV)
		if aa:
			_v.append(p + nm * (hw + FEATHER))
			_v.append(p - nm * (hw + FEATHER))
			_c.append(clear)
			_c.append(clear)
			_u.append(WHITE_UV)
			_u.append(WHITE_UV)
	for k in n - 1:
		var a := base + k * per
		var b := a + per
		_i.append_array([a, b, a + 1, a + 1, b, b + 1])
		if aa:
			_i.append_array([a + 2, b + 2, a, a, b + 2, b])
			_i.append_array([a + 1, b + 1, a + 3, a + 3, b + 1, b + 3])
