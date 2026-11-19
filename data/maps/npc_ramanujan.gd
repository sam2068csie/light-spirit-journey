extends RefCounted
## Q 版拉馬努金（地圖 NPC，草稿）：和 npc_gauss.gd 同一套比例（頭大身體小），程式畫的
##   參考他最常見的照片：圓臉、溫暖的深棕膚色、往後梳的濃密黑髮（額頭高）、又大又深的眼睛、濃眉、沒有鬍子；
##   深色西裝、白襯衫、領帶。招牌道具：一塊寫著 1729 的小石板（他年輕時用石板演算）
##   RamanujanNpc.draw(ci, 腳底的位置, 頭的大小, 時間, 表情, 步伐)
##   表情：normal（拿著石板，會眨眼）、happy（眼睛彎彎、張嘴笑）、think（拿粉筆點下巴、眼睛往上看、石板抱在胸前）、
##         talk（嘴巴一開一合、張開手掌揮手）
##   walk：走路的步伐（弧度；< 0 是站著）
const UITheme := preload("res://data/ui/game_theme.gd")

const SKIN := Color("b97a52")
const SKIN_SH := Color("9c6241")
const SKIN_HI := Color("cf9469")
const HAIR := Color("1b1820")
const HAIR_HI := Color("3b3644")
const SUIT := Color("2f3550")
const SUIT_HI := Color("414869")
const SHIRT := Color("fbf8ef")
const SHIRT_SH := Color("ddd6c4")
const TIE := Color("9a3d2f")
const TIE_HI := Color("b9553f")
const EYE := Color("221a1c")
const LINE := Color(0.35, 0.2, 0.14, 0.6)
const SHOE := Color("2a2226")
const SLATE := Color("34423c")
const SLATE_RIM := Color("a8794a")
const CHALK := Color(0.95, 0.95, 0.9, 0.9)
const FW := 0.88                # 圓臉：半寬 0.88、半高 0.94（乘頭的大小 s）
const FH := 0.94


static func draw(ci: CanvasItem, p: Vector2, s: float, t: float, mood := "normal", walk := -1.0) -> void:
	var bob := sin(t * 2.0) * s * 0.025
	if walk >= 0.0:
		bob = -absf(sin(walk)) * s * 0.07
	var body_h := s * 0.95
	var head := p + Vector2(0, -body_h - s * 0.8 + bob)
	var blink := fposmod(t + 1.3, 3.3) < 0.12 and mood == "normal"
	var bp := p + Vector2(0, bob * 0.5)
	_ell(ci, p + Vector2(0, s * 0.04), s * 0.8, s * 0.16, Color(0, 0, 0, 0.28))
	for sx in [-1.0, 1.0]:
		var lift := maxf(0.0, sin(walk) * sx) * s * 0.12 if walk >= 0.0 else 0.0
		_ell(ci, p + Vector2(sx * s * 0.21, -s * 0.04 - lift), s * 0.18, s * 0.1, SHOE)
	_body(ci, bp, s, body_h, t, mood, walk)
	_head(ci, head, s, t, mood, blink)
	# 畫在頭前面的手
	if mood == "think":
		# 石板抱在胸前（左手），右手拿粉筆點下巴
		_slate(ci, bp + Vector2(-s * 0.08, -body_h * 0.42), s * 0.95, -0.12)
		UITheme.dot(ci, bp + Vector2(-s * 0.46, -body_h * 0.36), s * 0.1, SKIN)
		var chin := head + Vector2(s * 0.34, s * 0.86)
		ci.draw_line(chin + Vector2(-s * 0.02, s * 0.02), chin + Vector2(-s * 0.16, -s * 0.06), CHALK, maxf(2.0, s * 0.06), true)
		UITheme.dot(ci, chin, s * 0.1, SKIN)
	elif mood == "talk":
		# 張開手掌揮手（和高斯一樣：四根手指張成扇形＋大拇指，不要只伸一根手指）
		var palm := head + Vector2(s * 1.2, s * 0.55)
		var sway := sin(t * 7.0) * 0.3
		for k in 4:
			var a := -PI / 2.0 + sway + (k - 1.5) * 0.36
			var d := Vector2(cos(a), sin(a))
			ci.draw_line(palm + d * s * 0.06, palm + d * s * 0.2, SKIN, maxf(2.0, s * 0.075), true)
			UITheme.dot(ci, palm + d * s * 0.2, maxf(1.0, s * 0.037), SKIN)
		var td := Vector2.from_angle(sway + 0.15)
		ci.draw_line(palm, palm + td * s * 0.16, SKIN, maxf(2.0, s * 0.08), true)
		UITheme.dot(ci, palm, s * 0.12, SKIN)


# ───────────────────────── 身體 ─────────────────────────

static func _body(ci: CanvasItem, p: Vector2, s: float, h: float, t: float, mood: String, walk := -1.0) -> void:
	var top := p.y - h
	# 西裝外套：比高斯的外袍圓一點、壯一點
	var suit := PackedVector2Array([
		Vector2(p.x - s * 0.4, top + s * 0.05), Vector2(p.x + s * 0.4, top + s * 0.05),
		Vector2(p.x + s * 0.6, p.y - s * 0.16), Vector2(p.x + s * 0.54, p.y - s * 0.03),
		Vector2(p.x - s * 0.54, p.y - s * 0.03), Vector2(p.x - s * 0.6, p.y - s * 0.16)])
	ci.draw_colored_polygon(suit, SUIT)
	ci.draw_colored_polygon(PackedVector2Array([suit[0], suit[1] + Vector2(-s * 0.24, 0), suit[4] + Vector2(s * 0.3, 0), suit[5]]), SUIT_HI)
	# 白襯衫的 V 字＋領帶
	var v_bot := Vector2(p.x, p.y - s * 0.34)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - s * 0.22, top + s * 0.05), Vector2(p.x + s * 0.22, top + s * 0.05), v_bot]), SHIRT)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - s * 0.05, top + s * 0.12), Vector2(p.x + s * 0.05, top + s * 0.12),
		Vector2(p.x + s * 0.07, v_bot.y - s * 0.02), Vector2(p.x, v_bot.y + s * 0.06), Vector2(p.x - s * 0.07, v_bot.y - s * 0.02)]), TIE)
	ci.draw_line(Vector2(p.x - s * 0.02, top + s * 0.2), Vector2(p.x + s * 0.03, top + s * 0.3), TIE_HI, maxf(1.0, s * 0.025), true)
	_ell(ci, Vector2(p.x, top + s * 0.1), s * 0.06, s * 0.045, TIE)                     # 領結的結
	# 西裝翻領（深一點的兩片）
	for sx in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(p.x + sx * s * 0.22, top + s * 0.04), Vector2(p.x + sx * s * 0.36, top + s * 0.08),
			Vector2(p.x + sx * s * 0.16, v_bot.y + s * 0.02), Vector2(p.x + sx * s * 0.04, v_bot.y - s * 0.04)]), Color("252a40"))
	# 鈕扣
	UITheme.dot(ci, Vector2(p.x, v_bot.y + s * 0.14), maxf(1.0, s * 0.035), Color("1a1d2c"))
	# 白襯衫的翻領（下巴下面兩個小三角）
	for sx in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x + sx * s * 0.02, top + s * 0.06), Vector2(p.x + sx * s * 0.2, top - s * 0.02),
			Vector2(p.x + sx * s * 0.14, top + s * 0.16)]), SHIRT)
		ci.draw_line(Vector2(p.x + sx * s * 0.2, top - s * 0.02), Vector2(p.x + sx * s * 0.14, top + s * 0.16), SHIRT_SH, maxf(1.0, s * 0.025), true)
	# 手
	var arm_y := top + s * 0.28
	var rest_l := Vector2(p.x - s * 0.56, p.y - s * 0.34)
	var rest_r := Vector2(p.x + s * 0.56, p.y - s * 0.34)
	match mood:
		"think":
			_arm(ci, Vector2(p.x + s * 0.4, arm_y), Vector2(p.x + s * 0.5, top - s * 0.06), s)
			_arm(ci, Vector2(p.x - s * 0.4, arm_y), Vector2(p.x - s * 0.46, top + h * 0.58), s)
		"talk":
			_arm(ci, Vector2(p.x + s * 0.4, arm_y), Vector2(p.x + s * 1.2, top - s * 0.38), s)
			_arm(ci, Vector2(p.x - s * 0.4, arm_y), rest_l, s)
			_slate(ci, rest_l + Vector2(-s * 0.05, s * 0.12), s * 0.62, 0.18)
			UITheme.dot(ci, rest_l, s * 0.1, SKIN)
		_:
			var sw := 0.0
			if walk >= 0.0:
				sw = -sin(walk) * s * 0.09
			_arm(ci, Vector2(p.x + s * 0.4, arm_y), rest_r + Vector2(0, -sw + sin(t * 2.0) * s * 0.02), s)
			_arm(ci, Vector2(p.x - s * 0.4, arm_y), rest_l + Vector2(0, sw), s)
			# 左手提著石板（垂在身體旁邊）
			_slate(ci, rest_l + Vector2(-s * 0.05, s * 0.12 + sw), s * 0.62, 0.18)
			UITheme.dot(ci, rest_l + Vector2(0, sw), s * 0.1, SKIN)


## 袖子＋圓圓的手
static func _arm(ci: CanvasItem, from: Vector2, hand: Vector2, s: float) -> void:
	ci.draw_line(from, hand, SUIT, s * 0.21, true)
	UITheme.dot(ci, from, s * 0.105, SUIT)
	_ell(ci, hand + (hand - from).normalized() * s * 0.01, s * 0.11, s * 0.09, SHIRT)     # 白襯衫的袖口
	UITheme.dot(ci, hand, s * 0.1, SKIN)


## 小石板：木框、深綠灰的板面、粉筆寫的 1729（太小就畫幾條短線代替字）
static func _slate(ci: CanvasItem, c: Vector2, w: float, rot: float) -> void:
	var h := w * 0.72
	ci.draw_set_transform(c, rot, Vector2.ONE)
	ci.draw_rect(Rect2(-w / 2.0, -h / 2.0, w, h), SLATE_RIM)
	var iw := w - w * 0.14
	var ih := h - w * 0.14
	ci.draw_rect(Rect2(-iw / 2.0, -ih / 2.0, iw, ih), SLATE)
	if w >= 26.0:
		var font := UITheme.bold_font()
		var fs := int(w * 0.3)
		ci.draw_string(font, Vector2(-iw / 2.0, fs * 0.36), "1729", HORIZONTAL_ALIGNMENT_CENTER, iw, fs, CHALK)
	else:
		for k in 2:
			var y := -ih * 0.18 + k * ih * 0.36
			ci.draw_line(Vector2(-iw * 0.32, y), Vector2(iw * (0.3 - 0.2 * k), y), CHALK, maxf(1.0, w * 0.05))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ───────────────────────── 頭 ─────────────────────────

static func _head(ci: CanvasItem, c: Vector2, s: float, t: float, mood: String, blink: bool) -> void:
	# 後面一層的頭髮：濃密、往後梳，頭頂高高鼓起（不是蓋住額頭的瀏海）
	_ell(ci, c + Vector2(0, -s * 0.4), s * 0.97, s * 0.74, HAIR)
	_ell(ci, c + Vector2(s * 0.06, -s * 0.78), s * 0.8, s * 0.46, HAIR)
	# 耳朵
	for sx in [-1.0, 1.0]:
		_ell(ci, c + Vector2(sx * s * FW * 0.98, s * 0.08), s * 0.13, s * 0.18, SKIN_SH)
		_ell(ci, c + Vector2(sx * s * FW * 0.97, s * 0.08), s * 0.07, s * 0.11, SKIN)
	# 臉：圓圓的，下巴豐滿
	_ell(ci, c, s * FW, s * FH, SKIN)
	_ell(ci, c + Vector2(0, s * 0.6), s * FW * 0.62, s * 0.28, Color(SKIN_SH.r, SKIN_SH.g, SKIN_SH.b, 0.16))
	_ell(ci, c + Vector2(-s * 0.26, -s * 0.3), s * 0.3, s * 0.2, Color(SKIN_HI.r, SKIN_HI.g, SKIN_HI.b, 0.35))
	# 前面的頭髮：額頭露出來（髮際線高、圓弧），左邊分線，往後梳
	var hair := PackedVector2Array()
	for k in 19:
		var a := PI + PI * k / 18.0
		hair.append(c + Vector2(cos(a) * s * FW * 1.04, sin(a) * s * FH * 1.08 - s * 0.06))
	for k in range(18, -1, -1):
		var x := lerpf(-1.0, 1.0, k / 18.0)
		# 髮際線：中間最高（額頭）、兩側往下到太陽穴；分線那裡微微凹進去
		var y := -s * 0.66 + x * x * s * 0.48 + exp(-pow((x + 0.38) * 6.0, 2.0)) * s * 0.06
		hair.append(c + Vector2(x * s * FW * 1.0, y))
	ci.draw_colored_polygon(hair, HAIR)
	# 往後梳的光澤：從髮際線往頭頂後方彎上去的亮線
	for k in 4:
		var x0 := -0.42 + k * 0.26
		var pts := PackedVector2Array()
		for j in 6:
			var u := j / 5.0
			pts.append(c + Vector2((x0 + u * 0.12 + u * u * 0.05) * s, (-0.74 - u * 0.4) * s))
		ci.draw_polyline(pts, HAIR_HI, maxf(1.0, s * 0.035), true)
	# 鬢角
	for sx in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(sx * s * FW * 0.97, -s * 0.24), c + Vector2(sx * s * FW * 0.82, -s * 0.2),
			c + Vector2(sx * s * FW * 0.9, s * 0.02), c + Vector2(sx * s * FW * 1.0, -s * 0.02)]), HAIR)
	# 腮紅（深膚色上淡淡的玫瑰色）
	for sx in [-1.0, 1.0]:
		_ell(ci, c + Vector2(sx * s * 0.46, s * 0.34), s * 0.13, s * 0.08, Color(0.85, 0.35, 0.35, 0.25))
	_face(ci, c, s, t, mood, blink)


static func _face(ci: CanvasItem, c: Vector2, s: float, t: float, mood: String, blink: bool) -> void:
	var lw := maxf(1.4, s * 0.06)
	# 濃黑的眉毛：溫和的弧形（不要斜斜的，會像在生氣）；想事情時抬高
	for sx in [-1.0, 1.0]:
		var bc := c + Vector2(sx * s * 0.32, -s * 0.2 - (s * 0.06 if mood == "think" else 0.0))
		ci.draw_arc(bc + Vector2(0, s * 0.1), s * 0.14, PI * 1.22, PI * 1.78, 10, HAIR, maxf(2.4, s * 0.09), true)
	# 眼睛：又大又深、亮亮的（比高斯大）
	for sx in [-1.0, 1.0]:
		var e := c + Vector2(sx * s * 0.31, s * 0.02)
		if mood == "happy":
			ci.draw_arc(e + Vector2(0, s * 0.06), s * 0.12, PI * 1.15, PI * 1.85, 10, EYE, lw, true)
		elif blink:
			ci.draw_line(e + Vector2(-s * 0.1, 0), e + Vector2(s * 0.1, 0), EYE, lw, true)
		else:
			var look := Vector2(s * 0.03, -s * 0.05) if mood == "think" else Vector2.ZERO
			_ell(ci, e, s * 0.13, s * 0.11, Color(1, 0.98, 0.95))                        # 眼白
			_ell(ci, e + look, s * 0.09, s * 0.1, EYE)
			UITheme.dot(ci, e + look + Vector2(-s * 0.03, -s * 0.035), maxf(1.0, s * 0.03), Color(1, 1, 1, 0.9))
			ci.draw_arc(e + Vector2(0, s * 0.02), s * 0.13, PI * 1.08, PI * 1.92, 12, EYE, maxf(1.2, s * 0.045), true)   # 上眼皮
	# 鼻子：圓圓寬寬的鼻頭
	ci.draw_line(c + Vector2(s * 0.03, s * 0.06), c + Vector2(s * 0.05, s * 0.2), LINE, maxf(1.0, s * 0.03), true)
	_ell(ci, c + Vector2(0, s * 0.28), s * 0.13, s * 0.08, SKIN_SH)
	_ell(ci, c + Vector2(-s * 0.02, s * 0.26), s * 0.08, s * 0.05, SKIN_HI)
	# 嘴巴：厚厚的嘴唇
	var m := c + Vector2(0, s * 0.53)
	var lip := Color("7a3a33")
	match mood:
		"happy":
			ci.draw_colored_polygon(PackedVector2Array([m + Vector2(-s * 0.17, -s * 0.04), m + Vector2(s * 0.17, -s * 0.04), m + Vector2(s * 0.08, s * 0.1), m + Vector2(-s * 0.08, s * 0.1)]), lip)
			ci.draw_colored_polygon(PackedVector2Array([m + Vector2(-s * 0.13, -s * 0.03), m + Vector2(s * 0.13, -s * 0.03), m + Vector2(s * 0.1, s * 0.01), m + Vector2(-s * 0.1, s * 0.01)]), Color(1, 1, 1, 0.9))
		"talk":
			var o := 0.03 + 0.05 * absf(sin(t * 9.0))
			_ell(ci, m + Vector2(0, s * 0.01), s * 0.09, s * o, lip)
		"think":
			_ell(ci, m + Vector2(s * 0.04, 0), s * 0.06, s * 0.035, lip)
		_:
			var pts := PackedVector2Array()
			for k in 9:
				var x := lerpf(-1.0, 1.0, k / 8.0)
				pts.append(m + Vector2(x * s * 0.14, s * 0.04 * (1.0 - x * x)))
			ci.draw_polyline(pts, lip, maxf(1.6, s * 0.06), true)


static func _ell(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)
