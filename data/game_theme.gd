extends RefCounted
## 全遊戲共用的視覺主題：配色、圓角卡片、按鈕、滑桿。
## 用法：在關卡腳本開頭寫  const UITheme := preload("game_theme.gd")
##       然後在 _ready() 裡寫  theme = UITheme.shared()
## 字型：res://fonts/game_font.tres（同時設為專案預設字型 gui/theme/custom_font），手機上才不會缺字。

const BG := Color("0d1024")
const PANEL := Color("171c3a")
const PANEL_LIGHT := Color("232b55")
const ACCENT := Color("ffcf5a")     # 金色：主要按鈕、星星
const CYAN := Color("5ad8ff")       # 參數 a
const PINK := Color("ff7eb6")       # 參數 h
const LIME := Color("a6f05a")       # 參數 k
const TEXT := Color("eef1ff")
const TEXT_DIM := Color("9aa3c7")
const GOOD := Color("6ee7a0")
const BAD := Color("ff6b7a")
const FONT_PATH := "res://fonts/game_font.tres"   # 思源黑體繁中子集 + DejaVu 數學符號後備


## 數字轉文字：最多 decimals 位小數，並去掉多餘的 0（4.0 → 4、0.50 → 0.5、−0.0 → 0）
## 不同版本的 Godot 對 String.num 的格式不一樣，統一用這個
## ---------- 圓點（效能） ----------
## 實心圓：用預先做好的圓點貼圖畫成一個方塊，外觀和 draw_circle 一樣（邊緣還多了一點抗鋸齒）
## 手機（相容性渲染器）上 draw_circle 每一個都會建立並釋放一組 64 邊形的 GPU 緩衝區，畫面一多就掉幀；
## 貼圖方塊則可以合併成一批畫完。
const DISC_SIZES := [8, 16, 32, 64, 128, 256]
static var _discs: Dictionary = {}

static func dot(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	if r <= 0.0 or col.a <= 0.0:
		return
	# 依螢幕上的大小挑貼圖（手機畫面大約放大 2 倍，地圖還會再拉近）
	var px := r * 5.2
	var k := 0
	while k < DISC_SIZES.size() - 1 and DISC_SIZES[k] < px:
		k += 1
	ci.draw_texture_rect(_disc(DISC_SIZES[k]), Rect2(c.x - r, c.y - r, 2.0 * r, 2.0 * r), false, col)


static func _disc(n: int) -> Texture2D:
	if _discs.has(n):
		return _discs[n]
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	var half := n / 2.0
	var ramp := maxf(1.0, n / 96.0)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - half, y + 0.5 - half).length()
			img.set_pixel(x, y, Color(1, 1, 1, clampf((half - d) / ramp + 0.5, 0.0, 1.0)))
	var tex := ImageTexture.create_from_image(img)
	_discs[n] = tex
	return tex


## 折線減點：幾乎在一直線上的中間點省掉（偏差 < tol 像素），畫出來看不出差別，三角形少很多
static func thin(pts: PackedVector2Array, tol: float = 0.15, max_len: float = 60.0) -> PackedVector2Array:
	var n := pts.size()
	if n <= 3:
		return pts
	var out := PackedVector2Array()
	out.append(pts[0])
	var anchor := pts[0]
	var h_prev := (pts[1] - pts[0]).angle()
	var turn := 0.0
	for i in range(1, n - 1):
		var h := (pts[i + 1] - pts[i]).angle()
		turn += absf(angle_difference(h_prev, h))
		h_prev = h
		# 從 anchor 直接連到 i+1 時，被省掉的點離直線最遠大約是「弦長 × 累積轉角 ÷ 4」
		var chord := anchor.distance_to(pts[i + 1])
		if chord * turn * 0.25 > tol or chord > max_len:
			out.append(pts[i])
			anchor = pts[i]
			turn = 0.0
	out.append(pts[n - 1])
	return out


## ---------- 字級 ----------
## 全遊戲的字級都經過這裡：程式裡寫的是「設計字級」，實際顯示放大 TEXT_SCALE 倍（手機上才看得清楚）。
## 想再調大或調小，只要改 TEXT_SCALE。超過 26 的大標題只加一點，免得版面爆掉。
const TEXT_SCALE := 1.2

static func fs(n: float) -> int:
	if n <= 26.0:
		return int(round(n * TEXT_SCALE))
	return int(round(n + 26.0 * (TEXT_SCALE - 1.0)))


static func num(v: float, decimals: int = 2) -> String:
	var t := String.num(snappedf(v, pow(10.0, -decimals)), decimals)
	if "." in t:
		t = t.rstrip("0").rstrip(".")
	if t == "-0":
		t = "0"
	return t


## 底數之類的顯示文字：0.5 → 1/2、1/3 → 1/3、2 → 2
static func nice_text(v: float) -> String:
	for pair in [[0.5, "1/2"], [0.25, "1/4"], [0.2, "1/5"], [1.0 / 3.0, "1/3"], [2.0 / 3.0, "2/3"]]:
		if absf(v - float(pair[0])) < 1e-4:
			return pair[1]
	return num(v, 2)


## 產生一個圓角色塊（卡片、按鈕底、提示框都用它）
static func box(bg: Color, radius: int = 14, border: Color = Color(0, 0, 0, 0),
		border_w: int = 0, pad: int = 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	sb.set_content_margin_all(pad)
	sb.anti_aliasing = true
	return sb


## 和 box() 一樣，但同樣的參數共用同一個樣式（給每一幀都在畫的 draw_style_box 用，不要拿去修改）
static var _box_cache: Dictionary = {}

static func boxc(bg: Color, radius: int = 14, border: Color = Color(0, 0, 0, 0),
		border_w: int = 0, pad: int = 12) -> StyleBoxFlat:
	var key := "%s|%d|%s|%d|%d" % [bg.to_html(), radius, border.to_html(), border_w, pad]
	var sb = _box_cache.get(key)
	if sb == null:
		if _box_cache.size() > 1500:
			_box_cache.clear()
		sb = box(bg, radius, border, border_w, pad)
		_box_cache[key] = sb
	return sb


static var _shared: Theme = null


## 共用同一份主題（第一次呼叫時建立）
static func shared() -> Theme:
	if _shared == null:
		_shared = build()
	return _shared


static func build() -> Theme:
	var th := Theme.new()
	if ResourceLoader.exists(FONT_PATH):
		th.default_font = load(FONT_PATH)
	th.default_font_size = fs(18)

	# 按鈕
	th.set_stylebox("normal", "Button", box(PANEL_LIGHT, 12, Color(1, 1, 1, 0.08), 1, 10))
	th.set_stylebox("hover", "Button", box(PANEL_LIGHT.lightened(0.12), 12, CYAN.darkened(0.2), 1, 10))
	th.set_stylebox("pressed", "Button", box(CYAN.darkened(0.5), 12, CYAN, 2, 10))
	th.set_stylebox("hover_pressed", "Button", box(CYAN.darkened(0.5), 12, CYAN, 2, 10))
	th.set_stylebox("disabled", "Button", box(PANEL.darkened(0.15), 12, Color(1, 1, 1, 0.04), 1, 10))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", TEXT)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color.WHITE)
	th.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	th.set_color("font_disabled_color", "Button", TEXT_DIM.darkened(0.35))

	# 文字
	th.set_color("font_color", "Label", TEXT)
	th.set_color("default_color", "RichTextLabel", TEXT)

	# 卡片
	th.set_stylebox("panel", "PanelContainer", box(PANEL, 18, Color(1, 1, 1, 0.07), 1, 18))
	th.set_stylebox("panel", "Panel", box(PANEL, 18))

	# 滑桿
	th.set_stylebox("slider", "HSlider", _bar(Color(1, 1, 1, 0.10)))
	th.set_stylebox("grabber_area", "HSlider", _bar(CYAN))
	th.set_stylebox("grabber_area_highlight", "HSlider", _bar(CYAN.lightened(0.2)))
	th.set_icon("grabber", "HSlider", circle_icon(22, Color.WHITE))
	th.set_icon("grabber_highlight", "HSlider", circle_icon(24, ACCENT))
	th.set_icon("grabber_disabled", "HSlider", circle_icon(20, TEXT_DIM.darkened(0.3)))

	# 開關
	var clear := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		th.set_stylebox(st, "CheckButton", clear)
	th.set_icon("checked", "CheckButton", switch_icon(true))
	th.set_icon("unchecked", "CheckButton", switch_icon(false))
	th.set_icon("checked_disabled", "CheckButton", switch_icon(true))
	th.set_icon("unchecked_disabled", "CheckButton", switch_icon(false))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		th.set_color(key, "CheckButton", TEXT)

	# 下拉選單
	th.set_stylebox("panel", "PopupMenu", box(PANEL_LIGHT, 12, Color(1, 1, 1, 0.12), 1, 6))
	th.set_stylebox("hover", "PopupMenu", box(CYAN.darkened(0.55), 8, Color(0, 0, 0, 0), 0, 4))
	th.set_color("font_color", "PopupMenu", TEXT)
	th.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	return th


## 滑桿的軌道（細長圓角條）
static func _bar(c: Color) -> StyleBoxFlat:
	var sb := box(c, 6, Color(0, 0, 0, 0), 0, 0)
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb


## ---------- 手機友善的滑桿 ----------
## Godot 內建滑桿拖動時是用「手指移動了多少」去推算數值；在手機（觸控模擬成滑鼠）上
## 這個相對位移有時會被放大，結果一拖就跳到最左或最右。
## TouchSlider 改成直接看手指「現在在哪裡」決定數值，不管哪種輸入都一樣準。
const _TouchSlider := preload("touch_slider.gd")
const _StepButton := preload("step_button.gd")

## 建立手機友善的滑桿（見 touch_slider.gd）
static func touch_slider() -> HSlider:
	return _TouchSlider.new()


## 在滑桿左右兩邊加上 ‹ › 按鈕（滑桿要先放進一個 HBoxContainer）
static func add_step_buttons(s: Range, c: Color) -> void:
	var row := s.get_parent()
	for dir in [-1, 1]:
		var b = _StepButton.new()
		b.slider = s
		b.dir = dir
		b.text = "‹" if dir < 0 else "›"
		b.custom_minimum_size = Vector2(36, 36)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_stylebox_override("normal", box(Color(c.r, c.g, c.b, 0.10), 10, Color(c.r, c.g, c.b, 0.45), 1, 0))
		b.add_theme_stylebox_override("hover", box(Color(c.r, c.g, c.b, 0.20), 10, c, 1, 0))
		b.add_theme_stylebox_override("pressed", box(Color(c.r, c.g, c.b, 0.32), 10, c, 2, 0))
		b.add_theme_stylebox_override("disabled", box(Color(1, 1, 1, 0.03), 10, Color(1, 1, 1, 0.10), 1, 0))
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(key, c)
		b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.2))
		row.add_child(b)
		row.move_child(b, s.get_index() + (1 if dir > 0 else 0))


## 讓滑桿的「已拖動」部分換成指定顏色（a、h、k 各用不同顏色）
static func tint_slider(s: HSlider, c: Color) -> void:
	s.add_theme_stylebox_override("grabber_area", _bar(c))
	s.add_theme_stylebox_override("grabber_area_highlight", _bar(c.lightened(0.2)))


## 金色的主要行動按鈕
static func accent_button(b: Button, size: int = 22) -> void:
	# 全遊戲統一：和主畫面「開始冒險」一樣的立體金色按鈕
	button_3d(b, ACCENT, ACCENT_LIP, Color("3a2306"), size, 6, 14, 10)
	b.add_theme_color_override("font_disabled_color", Color(0.78, 0.76, 0.70, 0.8))


## 用程式畫一個抗鋸齒圓點，當作滑桿把手
static func circle_icon(d: int, c: Color) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var r := d / 2.0
	for y in d:
		for x in d:
			var dist := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			img.set_pixel(x, y, Color(c.r, c.g, c.b, clampf(r - dist, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## 步驟列：已完成的打勾變綠、目前步驟金色、之後的步驟灰色
## 例：step_bar(["分區", "排序"], 1) → 「✓ 分區  ›  ② 排序」
static func step_bar(names: Array, current: int) -> String:
	var nums := ["①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩", "⑪", "⑫", "⑬", "⑭", "⑮", "⑯", "⑰", "⑱", "⑲", "⑳"]
	var parts := PackedStringArray()
	for i in names.size():
		var col := TEXT_DIM
		var label: String = "%s %s" % [nums[i] if i < nums.size() else "(%d)" % (i + 1), names[i]]
		if i < current:
			col = GOOD
			label = "✓ " + names[i]
		elif i == current:
			col = ACCENT
		parts.append("[color=#%s]%s[/color]" % [col.to_html(false), label])
	return "  ›  ".join(parts)


## 用程式畫圖示（不依賴字型裡有沒有該符號）："pause"、"back"、"lock"
static func icon(kind: String, d: int = 20, c: Color = Color.WHITE) -> ImageTexture:
	var ss := 4                     # 超取樣抗鋸齒
	var big := d * ss
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	for y in d:
		for x in d:
			var hit := 0
			for sy in ss:
				for sx in ss:
					var u := (x * ss + sx + 0.5) / big
					var v := (y * ss + sy + 0.5) / big
					if _icon_hit(kind, u, v):
						hit += 1
			img.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * hit / float(ss * ss)))
	return ImageTexture.create_from_image(img)


static func _icon_hit(kind: String, u: float, v: float) -> bool:
	match kind:
		"pause":
			var in_y := v > 0.2 and v < 0.8
			return in_y and ((u > 0.24 and u < 0.42) or (u > 0.58 and u < 0.76))
		"back":
			# 左箭頭：橫桿 + 兩條斜線
			if u > 0.25 and u < 0.82 and absf(v - 0.5) < 0.075:
				return true
			var d := absf(v - 0.5)
			return u > 0.2 and u < 0.56 and absf((u - 0.2) - d) < 0.1
		"capsule":
			# 扭蛋：圓形外框＋中間一條線，上半塗滿
			var d := Vector2(u - 0.5, v - 0.5).length()
			var ring := d > 0.3 and d < 0.4
			var top_half := d < 0.4 and v < 0.47
			var mid := absf(v - 0.5) < 0.04 and d < 0.4
			return ring or top_half or mid
		"quest":
			# 任務板：外框 + 上面的夾子 + 三條橫線
			var inside := u > 0.2 and u < 0.8 and v > 0.16 and v < 0.92
			var hole := u > 0.29 and u < 0.71 and v > 0.25 and v < 0.83
			var clip := u > 0.35 and u < 0.65 and v > 0.08 and v < 0.26
			var lines := u > 0.36 and u < 0.64 and (absf(v - 0.42) < 0.04 or absf(v - 0.56) < 0.04 or absf(v - 0.70) < 0.04)
			return (inside and not hole) or clip or lines
		"hanger":
			# 衣架：上面的小勾＋三角形骨架
			var p := Vector2(u, v)
			var apex := Vector2(0.5, 0.38)
			var lft := Vector2(0.1, 0.76)
			var rgt := Vector2(0.9, 0.76)
			var w := 0.055
			if _seg_d(p, apex, lft) < w or _seg_d(p, apex, rgt) < w or _seg_d(p, lft, rgt) < w:
				return true
			var hr := Vector2(u - 0.5, v - 0.22).length()
			var hook := hr > 0.09 and hr < 0.15 and not (u < 0.5 and v > 0.22)
			return hook or _seg_d(p, Vector2(0.5, 0.36), Vector2(0.5, 0.3)) < w
		"lock":
			var body := u > 0.22 and u < 0.78 and v > 0.45 and v < 0.88
			var r := Vector2(u - 0.5, v - 0.45).length()
			var shackle := v < 0.47 and r > 0.15 and r < 0.25
			return body or shackle
	return false


static func _seg_d(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## 開關圖示（CheckButton 用）
static func switch_icon(on: bool) -> ImageTexture:
	var w := 46
	var h := 26
	var ss := 3
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var track := ACCENT if on else Color(1, 1, 1, 0.16)
	var knob := Color("1a1530") if on else Color.WHITE
	var kx := w - h / 2.0 if on else h / 2.0
	for y in h:
		for x in w:
			var tr := 0
			var kn := 0
			for sy in ss:
				for sx in ss:
					var px := x + (sx + 0.5) / ss
					var py := y + (sy + 0.5) / ss
					var cx := clampf(px, h / 2.0, w - h / 2.0)
					if Vector2(px - cx, py - h / 2.0).length() <= h / 2.0:
						tr += 1
					if Vector2(px - kx, py - h / 2.0).length() <= h / 2.0 - 3.0:
						kn += 1
			var a_t := tr / float(ss * ss)
			var a_k := kn / float(ss * ss)
			var col := track.lerp(knob, a_k)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, maxf(a_t * track.a, a_k)))
	return ImageTexture.create_from_image(img)


## 圓形的小圖示按鈕（例如暫停）
static func round_button(kind: String, size: int = 44) -> Button:
	var b := Button.new()
	b.icon = icon(kind, 20, TEXT)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.expand_icon = false
	b.custom_minimum_size = Vector2(size, size)
	b.focus_mode = Control.FOCUS_NONE
	var r := size / 2 - 2
	for st in [["normal", Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.12), 1],
			["hover", Color(1, 1, 1, 0.14), CYAN.darkened(0.1), 1],
			["pressed", CYAN.darkened(0.5), CYAN, 2]]:
		var sb := box(st[1], r, st[2], st[3], 0)
		sb.corner_detail = 16
		b.add_theme_stylebox_override(st[0], sb)
	return b


## 一般按鈕，但左右內距比較小（一排放很多個按鈕時用，字放大後才放得下）
static func tight(b: Button, pad: int = 4) -> void:
	b.add_theme_stylebox_override("normal", box(PANEL_LIGHT, 12, Color(1, 1, 1, 0.08), 1, pad))
	b.add_theme_stylebox_override("hover", box(PANEL_LIGHT.lightened(0.12), 12, CYAN.darkened(0.2), 1, pad))
	b.add_theme_stylebox_override("pressed", box(CYAN.darkened(0.5), 12, CYAN, 2, pad))
	b.add_theme_stylebox_override("disabled", box(PANEL.darkened(0.15), 12, Color(1, 1, 1, 0.04), 1, pad))


## ---------- 立體風格（主畫面） ----------
## 粗體字：用目前的字型加粗（不用另外放粗體字型檔）
static var _bold_font: FontVariation

static func bold_font() -> Font:
	if _bold_font == null:
		_bold_font = FontVariation.new()
		_bold_font.base_font = shared().default_font if shared().default_font else ThemeDB.fallback_font
		_bold_font.variation_embolden = 0.3
	return _bold_font


## 立體按鈕：底下有一條較深色的「厚度」，按下去時按鈕面往下沉、厚度變薄
##   face：按鈕面的顏色　lip：厚度（底邊）的顏色　text：文字顏色
const ACCENT_LIP := Color("c27a14")   # 金色按鈕底下的厚度顏色

static func button_3d(b: Button, face: Color, lip: Color, text: Color, size: int = 20, depth: int = 6,
		radius: int = 18, pad: int = 6) -> void:
	var mk := func(f: Color, d: int, sink: int, l: Color = lip) -> StyleBoxFlat:
		var sb := StyleBoxFlat.new()
		sb.bg_color = f
		sb.set_corner_radius_all(radius)
		sb.border_color = l
		sb.border_width_bottom = d
		sb.border_blend = false
		sb.anti_aliasing = true
		# 按下時：整塊往下沉 sink，底邊變薄，文字一起往下
		sb.expand_margin_top = -sink
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = pad + sink
		sb.content_margin_bottom = pad + d
		sb.shadow_color = Color(0, 0, 0, 0.35 if sink == 0 else 0.25)
		sb.shadow_size = 8 if sink == 0 else 4
		sb.shadow_offset = Vector2(0, 5 if sink == 0 else 2)
		return sb
	b.add_theme_stylebox_override("normal", mk.call(face, depth, 0))
	b.add_theme_stylebox_override("hover", mk.call(face.lightened(0.10), depth, 0))
	b.add_theme_stylebox_override("pressed", mk.call(face.darkened(0.04), 2, depth - 2))
	b.add_theme_stylebox_override("hover_pressed", mk.call(face.darkened(0.04), 2, depth - 2))
	# 不能按：灰色、沒有陰影浮起感（厚度變淺，看起來「按不下去」）
	var dis: StyleBoxFlat = mk.call(Color(0.33, 0.32, 0.30), depth, 0, Color(0.22, 0.21, 0.20))
	dis.shadow_size = 0
	b.add_theme_stylebox_override("disabled", dis)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, text)
	b.add_theme_font_override("font", bold_font())
	b.add_theme_font_size_override("font_size", fs(size))


## 次要的文字按鈕（透明底，例如「返回」）
static func ghost_button(text: String, size: int = 17) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", box(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 10))
	b.add_theme_stylebox_override("hover", box(Color(1, 1, 1, 0.08), 12, Color(0, 0, 0, 0), 0, 10))
	b.add_theme_stylebox_override("pressed", box(Color(1, 1, 1, 0.14), 12, Color(0, 0, 0, 0), 0, 10))
	b.add_theme_color_override("font_color", TEXT_DIM)
	b.add_theme_color_override("font_hover_color", TEXT)
	b.add_theme_font_size_override("font_size", fs(size))
	# 細深色描邊：在亮暗不一的背景上也看得清楚
	b.add_theme_constant_override("outline_size", 4)
	b.add_theme_color_override("font_outline_color", OUTLINE_DARK)
	return b


## 地圖等畫面上的文字描邊顏色（深藍黑，比背景再深一點）
const OUTLINE_DARK := Color(0.02, 0.03, 0.10, 0.9)

## 帶細描邊的文字：先畫描邊、再畫字。ow 是描邊總寬（實際每邊約 ow/2 像素），
## 預設 4 → 每邊 2px，讓字更明顯但筆劃不會糊在一起
static func text_ol(ci: CanvasItem, font: Font, pos: Vector2, text: String, align: int, w: float,
		size: int, col: Color, ow: int = 4, oc: Color = OUTLINE_DARK) -> void:
	ci.draw_string_outline(font, pos, text, align, w, size, ow, Color(oc.r, oc.g, oc.b, oc.a * col.a))
	ci.draw_string(font, pos, text, align, w, size, col)


## 全螢幕的半透明遮罩 + 置中的卡片。回傳 [遮罩層, 卡片內的直排容器]
static func modal(parent: Node, border: Color, width: int = 0, fade: bool = true) -> Array:
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.theme = shared()        # 放在 CanvasLayer 底下時也能套用主題
	parent.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var card := PanelContainer.new()
	var sb := box(PANEL, 22, border, 2, 24)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 24
	card.add_theme_stylebox_override("panel", sb)
	if width > 0:
		card.custom_minimum_size = Vector2(width, 0)
	center.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	card.add_child(col)
	if fade:
		layer.modulate.a = 0.0
		var tw := layer.create_tween()
		tw.tween_property(layer, "modulate:a", 1.0, 0.16)
	return [layer, col]


## 置中的大標題文字
static func title_label(text: String, size: int, c: Color) -> Label:
	var t := Label.new()
	t.text = text
	t.add_theme_font_size_override("font_size", fs(size))
	t.add_theme_color_override("font_color", c)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return t
