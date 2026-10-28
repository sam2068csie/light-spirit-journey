extends Control
## 終焉之塔的插圖：一座往雲裡延伸的高塔，爬過的樓層亮著金色的窗，光靈停在最高紀錄那一層

const UITheme := preload("game_theme.gd")

var best := 0               # 最高紀錄（通過的層數）
var top_floor := 0          # 塔頂是第幾層（0 = 沒有上限）
var t := 0.0
var stars: Array = []

const FLOOR_H := 38.0
const SHOW := 12            # 畫面上看得到幾層


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 90:
		stars.append({"p": Vector2(rng.randf(), rng.randf()), "s": rng.randf_range(0.6, 1.8), "ph": rng.randf() * TAU})


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return          # 別的頁面開著時不用算、不用重畫
	t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var bg := UITheme.box(Color(0.06, 0.07, 0.17, 0.9), 22, Color(1, 1, 1, 0.08), 1, 0)
	draw_style_box(bg, Rect2(Vector2.ZERO, size))
	for s in stars:
		var a: float = 0.2 + 0.3 * sin(t * 1.4 + s.ph)
		UITheme.dot(self, Vector2(s.p.x * w, s.p.y * h * 0.8), s.s, Color(1, 1, 1, a))
	var font := get_theme_default_font()
	# 最底下那層是第幾層：讓最高紀錄附近都看得到
	var lowest := maxi(1, best - SHOW + 4)
	if top_floor > 0:
		lowest = clampi(lowest, 1, maxi(1, top_floor - SHOW + 3))     # 留兩層的空間畫塔頂
	var cx := w / 2.0
	var ground := h - 46.0
	# 地面與海
	draw_rect(Rect2(0, ground, w, h - ground), Color(0.05, 0.12, 0.22, 0.9))
	draw_line(Vector2(16, ground), Vector2(w - 16, ground), Color(0.6, 0.85, 1.0, 0.25), 1.5)
	var shown := SHOW
	for k in SHOW:
		var f := lowest + k
		if top_floor > 0 and f > top_floor:
			shown = k
			break
		var y1 := ground - k * FLOOR_H
		var y0 := y1 - FLOOR_H
		var shrink := 1.0 - 0.025 * k
		var half := 70.0 * shrink
		var cleared := f <= best
		var body := Color("262d57").lerp(Color("3b3270"), 0.4 if cleared else 0.0)
		# 每五層是試煉層，外觀寬一點
		if f % 5 == 0:
			half += 10.0
			body = body.lightened(0.08)
		draw_colored_polygon(PackedVector2Array([Vector2(cx - half, y1), Vector2(cx + half, y1),
			Vector2(cx + half * 0.97, y0), Vector2(cx - half * 0.97, y0)]), body)
		draw_line(Vector2(cx - half, y1), Vector2(cx + half, y1), Color(0, 0, 0, 0.35), 2.0)
		# 窗戶
		for j in 3:
			var wx := cx - half * 0.55 + j * half * 0.55
			var lit_c := Color(1, 0.85, 0.45, 0.9 + 0.1 * sin(t * 3.0 + f + j)) if cleared else Color(0.3, 0.33, 0.55, 0.6)
			draw_rect(Rect2(wx - 6, y0 + 10, 12, FLOOR_H - 18), lit_c)
			if cleared:
				UITheme.dot(self, Vector2(wx, y0 + FLOOR_H / 2.0), 12.0, Color(1, 0.85, 0.45, 0.10))
		# 樓層號碼
		var tc := Color(1, 0.88, 0.55) if cleared else Color(0.7, 0.74, 0.9, 0.6)
		draw_string(font, Vector2(cx + half + 10, y0 + FLOOR_H / 2.0 + 6), "%d F" % f, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14), tc)
		if f % 5 == 0:
			draw_string(font, Vector2(cx - half - 70, y0 + FLOOR_H / 2.0 + 6), "試煉層", HORIZONTAL_ALIGNMENT_RIGHT, 60, UITheme.fs(13), Color(1, 0.55, 0.6, 0.8))
	# 塔頂：有上限就畫尖頂和旗子；沒有就伸進雲裡
	var top := ground - shown * FLOOR_H
	if top_floor > 0 and shown < SHOW:
		var half_top := 70.0 * (1.0 - 0.025 * shown)
		var summit := best >= top_floor
		var roof := Color("ff8fa0") if summit else Color("3b3270")
		draw_colored_polygon(PackedVector2Array([Vector2(cx - half_top - 6, top), Vector2(cx + half_top + 6, top),
			Vector2(cx, top - 62)]), roof.darkened(0.15))
		draw_line(Vector2(cx, top - 62), Vector2(cx, top - 96), Color(1, 1, 1, 0.7), 2.0)
		var wave := 4.0 * sin(t * 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(cx, top - 96), Vector2(cx + 30, top - 88 + wave), Vector2(cx, top - 80)]),
			Color(1, 0.85, 0.45) if summit else Color(0.7, 0.74, 0.9, 0.6))
		draw_string(font, Vector2(cx + 36, top - 70), "塔頂 %d F" % top_floor, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14),
			Color(1, 0.88, 0.55) if summit else Color(0.8, 0.82, 0.95, 0.8))
	else:
		_clouds(font, top, cx, w)
	_spirit(font, lowest, ground, cx)


func _clouds(font: Font, top: float, cx: float, w: float) -> void:
	for k in 7:
		var cxk := cx + (k - 3) * 46.0 + 10.0 * sin(t * 0.5 + k)
		UITheme.dot(self, Vector2(cxk, top + 4.0 * sin(t * 0.7 + k)), 34.0, Color(0.55, 0.6, 0.85, 0.10))
		UITheme.dot(self, Vector2(cxk, top - 10.0), 24.0, Color(0.55, 0.6, 0.85, 0.08))
	draw_string(font, Vector2(0, top - 30), "？", HORIZONTAL_ALIGNMENT_CENTER, w, UITheme.fs(26), Color(1, 1, 1, 0.35 + 0.15 * sin(t * 2.0)))


## 光靈：停在最高紀錄那一層的右邊（還沒爬過就在塔腳）
func _spirit(font: Font, lowest: int, ground: float, cx: float) -> void:
	var k_best := clampi(best - lowest, -1, SHOW - 1)
	var sy := ground - (k_best + 0.5) * FLOOR_H if best > 0 else ground - 14.0
	var sp := Vector2(cx - 110.0, sy + 4.0 * sin(t * 2.4))
	UITheme.dot(self, sp, 20.0, Color(1.0, 0.9, 0.5, 0.12))
	UITheme.dot(self, sp, 12.0, Color(1.0, 0.9, 0.5, 0.30))
	UITheme.dot(self, sp, 8.0, Color(1.0, 0.98, 0.85))
	UITheme.dot(self, sp + Vector2(1.8, -1.8), 1.6, Color(0.15, 0.1, 0.3))
	UITheme.dot(self, sp + Vector2(5.4, -1.8), 1.6, Color(0.15, 0.1, 0.3))
	if best > 0:
		draw_string(font, sp + Vector2(-70, -22), "最高紀錄", HORIZONTAL_ALIGNMENT_CENTER, 140, UITheme.fs(12), Color(1, 0.88, 0.55, 0.9))
