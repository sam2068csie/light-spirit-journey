extends RefCounted
## Q 版牛頓（地圖 NPC，草稿）：和 npc_gauss.gd、npc_ramanujan.gd 同一套比例（頭大身體小），程式畫的
##   參考他最常見的肖像（Kneller 1702）：及肩的灰白長捲髮（中分）、偏長的臉、高挺的鼻子、銳利的眼睛；
##   深棕色外套配金鈕扣（他後來當過皇家鑄幣局局長）、白色領巾。
##   招牌道具：一顆紅蘋果（左手）；開心時另一手舉起三稜鏡，把白光分成彩虹（和「光」的世界觀呼應）
##   NewtonNpc.draw(ci, 腳底的位置, 頭的大小, 時間, 表情, 步伐, 呼叫的人設好的畫布變換)
##   表情：normal（拿著蘋果，會眨眼）、happy（眼睛彎彎、舉起三稜鏡分出彩虹）、think（手摸下巴、看著蘋果）、
##         talk（嘴巴一開一合、張開手掌揮手）
const UITheme := preload("res://data/ui/game_theme.gd")

const SKIN := Color("f4d3b8")
const SKIN_SH := Color("dfae8e")
const SKIN_HI := Color("fbe6d4")
const HAIR := Color("e6e1d8")
const HAIR_SH := Color("bdb4a7")
const HAIR_LINE := Color(0.55, 0.5, 0.44, 0.7)
const BROW := Color("8d8478")
const COAT := Color("4b3528")
const COAT_HI := Color("5d4433")
const COAT_SH := Color("3a281e")
const GOLD := Color("d9b65c")
const CRAVAT := Color("fbf8f0")
const CRAVAT_SH := Color("dcd5c6")
const EYE := Color("2b2a33")
const LINE := Color(0.45, 0.28, 0.2, 0.55)
const SHOE := Color("2a2226")
const APPLE := Color("d8363a")
const APPLE_HI := Color("f0675e")
const LEAF := Color("5f9a3e")
const FW := 0.8                 # 偏長的臉：半寬 0.8、半高 0.98（乘頭的大小 s）
const FH := 0.98

const NAME := "牛頓"
const TITLE := "散步中"           # 靠近時下方卡片的副標（暫定）

static var _base := Transform2D.IDENTITY


static func draw(ci: CanvasItem, p: Vector2, s: float, t: float, mood := "normal", walk := -1.0, base := Transform2D.IDENTITY) -> void:
	_base = base
	var bob := sin(t * 2.1) * s * 0.025
	if walk >= 0.0:
		bob = -absf(sin(walk)) * s * 0.07
	var body_h := s * 0.95
	var head := p + Vector2(0, -body_h - s * 0.9 + bob)
	var blink := fposmod(t + 0.6, 3.6) < 0.12 and mood == "normal"
	var bp := p + Vector2(0, bob * 0.5)
	_ell(ci, p + Vector2(0, s * 0.04), s * 0.78, s * 0.16, Color(0, 0, 0, 0.28))
	for sx in [-1.0, 1.0]:
		var lift := maxf(0.0, sin(walk) * sx) * s * 0.12 if walk >= 0.0 else 0.0
		_ell(ci, p + Vector2(sx * s * 0.2, -s * 0.04 - lift), s * 0.17, s * 0.1, SHOE)
	_hair_back(ci, head, s)
	_body(ci, bp, s, body_h, t, mood, walk)
	_head(ci, head, s, t, mood, blink)
	# 畫在頭前面的手
	match mood:
		"think":
			UITheme.dot(ci, head + Vector2(s * 0.3, s * 0.94), s * 0.1, SKIN)            # 摸下巴
		"talk":
			# 張開手掌揮手（和高斯一樣：四根手指張成扇形＋大拇指，不要只伸一根手指）
			var palm := head + Vector2(s * 1.22, s * 0.58)
			var sway := sin(t * 7.0) * 0.3
			for k in 4:
				var a := -PI / 2.0 + sway + (k - 1.5) * 0.36
				var d := Vector2(cos(a), sin(a))
				ci.draw_line(palm + d * s * 0.06, palm + d * s * 0.2, SKIN, maxf(2.0, s * 0.075), true)
				UITheme.dot(ci, palm + d * s * 0.2, maxf(1.0, s * 0.037), SKIN)
			var td := Vector2.from_angle(sway + 0.15)
			ci.draw_line(palm, palm + td * s * 0.16, SKIN, maxf(2.0, s * 0.08), true)
			UITheme.dot(ci, palm, s * 0.12, SKIN)
		"happy":
			_prism(ci, head + Vector2(s * 1.22, s * 0.34), s, t)


# ───────────────────────── 身體 ─────────────────────────

static func _body(ci: CanvasItem, p: Vector2, s: float, h: float, t: float, mood: String, walk := -1.0) -> void:
	var top := p.y - h
	# 長外套：下襬寬、到腳邊
	var coat := PackedVector2Array([
		Vector2(p.x - s * 0.38, top + s * 0.04), Vector2(p.x + s * 0.38, top + s * 0.04),
		Vector2(p.x + s * 0.62, p.y - s * 0.12), Vector2(p.x + s * 0.55, p.y - s * 0.02),
		Vector2(p.x - s * 0.55, p.y - s * 0.02), Vector2(p.x - s * 0.62, p.y - s * 0.12)])
	ci.draw_colored_polygon(coat, COAT)
	ci.draw_colored_polygon(PackedVector2Array([coat[0], coat[1] + Vector2(-s * 0.26, 0), coat[4] + Vector2(s * 0.32, 0), coat[5]]), COAT_HI)
	# 前襟的開口和金鈕扣
	ci.draw_line(Vector2(p.x, top + s * 0.3), Vector2(p.x, p.y - s * 0.04), COAT_SH, maxf(1.5, s * 0.05), true)
	for k in 4:
		UITheme.dot(ci, Vector2(p.x + s * 0.09, top + s * 0.36 + k * h * 0.17), maxf(1.2, s * 0.042), GOLD)
	# 口袋蓋
	for sx in [-1.0, 1.0]:
		ci.draw_line(Vector2(p.x + sx * s * 0.22, p.y - s * 0.3), Vector2(p.x + sx * s * 0.44, p.y - s * 0.3), COAT_SH, maxf(1.5, s * 0.05), true)
	# 白領巾：脖子一圈＋結＋垂下來的兩條（下面有一點蕾絲波浪）
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - s * 0.24, top), Vector2(p.x + s * 0.24, top),
		Vector2(p.x + s * 0.16, top + s * 0.14), Vector2(p.x - s * 0.16, top + s * 0.14)]), CRAVAT)
	for sx in [-1.0, 1.0]:
		var tab := PackedVector2Array([Vector2(p.x + sx * s * 0.01, top + s * 0.1), Vector2(p.x + sx * s * 0.13, top + s * 0.12),
			Vector2(p.x + sx * s * 0.16, top + s * 0.42), Vector2(p.x + sx * s * 0.02, top + s * 0.44)])
		ci.draw_colored_polygon(tab, CRAVAT)
		for k in 3:
			UITheme.dot(ci, Vector2(p.x + sx * s * (0.04 + k * 0.05), top + s * 0.44), s * 0.035, CRAVAT)
		ci.draw_line(Vector2(p.x + sx * s * 0.07, top + s * 0.16), Vector2(p.x + sx * s * 0.09, top + s * 0.38), CRAVAT_SH, maxf(1.0, s * 0.02), true)
	_ell(ci, Vector2(p.x, top + s * 0.11), s * 0.07, s * 0.06, CRAVAT_SH)
	# 手
	var arm_y := top + s * 0.28
	var rest_l := Vector2(p.x - s * 0.56, p.y - s * 0.34)
	var rest_r := Vector2(p.x + s * 0.56, p.y - s * 0.34)
	var sw := -sin(walk) * s * 0.09 if walk >= 0.0 else 0.0
	match mood:
		"think":
			# 右手摸下巴（手畫在頭前面）、左手把蘋果舉到胸前看著它
			_arm(ci, Vector2(p.x + s * 0.38, arm_y), Vector2(p.x + s * 0.3, top - s * 0.04), s)
			var hold := Vector2(p.x - s * 0.5, top + s * 0.1)
			_arm(ci, Vector2(p.x - s * 0.38, arm_y), hold, s)
			_apple(ci, hold + Vector2(0, -s * 0.2), s * 0.21)
			UITheme.dot(ci, hold, s * 0.1, SKIN)
		"talk":
			_arm(ci, Vector2(p.x + s * 0.38, arm_y), Vector2(p.x + s * 1.22, top - s * 0.34), s)
			_arm(ci, Vector2(p.x - s * 0.38, arm_y), rest_l, s)
			_apple(ci, rest_l + Vector2(-s * 0.04, s * 0.04), s * 0.19)
			UITheme.dot(ci, rest_l + Vector2(s * 0.04, -s * 0.02), s * 0.09, SKIN)
		"happy":
			_arm(ci, Vector2(p.x + s * 0.38, arm_y), Vector2(p.x + s * 1.1, top - s * 0.48), s)
			_arm(ci, Vector2(p.x - s * 0.38, arm_y), rest_l, s)
			_apple(ci, rest_l + Vector2(-s * 0.04, s * 0.04), s * 0.19)
			UITheme.dot(ci, rest_l + Vector2(s * 0.04, -s * 0.02), s * 0.09, SKIN)
		_:
			_arm(ci, Vector2(p.x + s * 0.38, arm_y), rest_r + Vector2(0, -sw + sin(t * 2.1) * s * 0.02), s)
			_arm(ci, Vector2(p.x - s * 0.38, arm_y), rest_l + Vector2(0, sw), s)
			_apple(ci, rest_l + Vector2(-s * 0.04, s * 0.04 + sw), s * 0.19)
			UITheme.dot(ci, rest_l + Vector2(s * 0.04, -s * 0.02 + sw), s * 0.09, SKIN)


## 袖子（反摺的寬袖口）＋白色的袖口蕾絲＋圓圓的手
static func _arm(ci: CanvasItem, from: Vector2, hand: Vector2, s: float) -> void:
	var d := (hand - from).normalized()
	ci.draw_line(from, hand - d * s * 0.04, COAT, s * 0.21, true)
	UITheme.dot(ci, from, s * 0.105, COAT)
	_ell(ci, hand - d * s * 0.08, s * 0.14, s * 0.13, COAT_HI)                          # 反摺的袖口
	_ell(ci, hand - d * s * 0.01, s * 0.1, s * 0.09, CRAVAT)                             # 蕾絲袖口
	UITheme.dot(ci, hand, s * 0.1, SKIN)


## 紅蘋果：圓圓的、上面凹一點，有梗、有一片葉子
static func _apple(ci: CanvasItem, c: Vector2, r: float) -> void:
	_ell(ci, c + Vector2(-r * 0.32, 0), r * 0.72, r * 0.86, APPLE)
	_ell(ci, c + Vector2(r * 0.32, 0), r * 0.72, r * 0.86, APPLE)
	_ell(ci, c + Vector2(-r * 0.4, -r * 0.3), r * 0.22, r * 0.3, APPLE_HI)
	ci.draw_line(c + Vector2(0, -r * 0.62), c + Vector2(r * 0.12, -r * 1.05), Color("6b4a2e"), maxf(1.2, r * 0.16), true)
	_ell(ci, c + Vector2(r * 0.42, -r * 0.92), r * 0.32, r * 0.15, LEAF)


## 三稜鏡：白光從左下射進來，右邊分成彩虹（開心時舉在手上）
static func _prism(ci: CanvasItem, c: Vector2, s: float, t: float) -> void:
	var r := s * 0.26
	var tri := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.9, r * 0.6), c + Vector2(-r * 0.9, r * 0.6)])
	# 白光進來
	ci.draw_line(c + Vector2(-r * 2.4, r * 0.5), c + Vector2(-r * 0.42, r * 0.02), Color(1, 1, 0.95, 0.85), maxf(1.5, s * 0.05), true)
	# 彩虹出去（微微閃爍）
	var cols := [Color("ff5a5a"), Color("ffa63d"), Color("ffe14d"), Color("6fd96a"), Color("4fb0ff"), Color("8a6bff")]
	for k in cols.size():
		var a := 0.12 + k * 0.07
		var o := c + Vector2(r * 0.44, r * 0.02)
		var col: Color = cols[k]
		col.a = 0.75 + 0.2 * sin(t * 4.0 + k)
		ci.draw_line(o, o + Vector2.from_angle(a) * r * 2.6, col, maxf(1.2, s * 0.045), true)
	ci.draw_colored_polygon(tri, Color(0.85, 0.95, 1.0, 0.75))
	ci.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color(1, 1, 1, 0.95), maxf(1.2, s * 0.035), true)
	UITheme.dot(ci, c + Vector2(0, r * 0.75), s * 0.1, SKIN)                                 # 拿著它的手


# ───────────────────────── 頭 ─────────────────────────

## 後面的頭髮：又長又捲、垂到肩膀（畫在身體後面，肩膀上的捲髮在 _head 裡再畫一次蓋在外套上）
static func _hair_back(ci: CanvasItem, c: Vector2, s: float) -> void:
	_ell(ci, c + Vector2(0, -s * 0.12), s * 1.08, s * 1.02, HAIR_SH)
	_ell(ci, c + Vector2(0, -s * 0.18), s * 1.02, s * 0.96, HAIR)


## 一串垂下來的捲髮（左右兩邊）：一顆一顆的圓，左右交錯，下面越來越小
static func _curls(ci: CanvasItem, c: Vector2, s: float, sx: float) -> void:
	for k in 6:
		var y := -s * 0.1 + k * s * 0.24
		var x := sx * (s * 0.86 + (s * 0.08 if k % 2 == 0 else -s * 0.02) + k * s * 0.03)
		var r := s * (0.26 - k * 0.015)
		_ell(ci, c + Vector2(x + sx * s * 0.02, y + s * 0.03), r, r * 0.92, HAIR_SH)
		_ell(ci, c + Vector2(x, y), r, r * 0.9, HAIR)
		ci.draw_arc(c + Vector2(x - sx * r * 0.1, y + r * 0.05), r * 0.5, PI * 0.1, PI * 1.1, 8, HAIR_LINE, maxf(1.0, s * 0.03), true)


static func _head(ci: CanvasItem, c: Vector2, s: float, t: float, mood: String, blink: bool) -> void:
	# 垂到肩膀的捲髮（蓋在外套上）
	for sx in [-1.0, 1.0]:
		_curls(ci, c, s, sx)
	# 臉：偏長的蛋形
	_ell(ci, c, s * FW, s * FH, SKIN)
	_ell(ci, c + Vector2(0, s * 0.6), s * FW * 0.6, s * 0.3, Color(SKIN_SH.r, SKIN_SH.g, SKIN_SH.b, 0.18))
	_ell(ci, c + Vector2(-s * 0.24, -s * 0.3), s * 0.28, s * 0.2, Color(SKIN_HI.r, SKIN_HI.g, SKIN_HI.b, 0.5))
	# 前面的頭髮：中分，兩邊蓬蓬地往下蓋住太陽穴
	var hair := PackedVector2Array()
	for k in 19:
		var a := PI + PI * k / 18.0
		hair.append(c + Vector2(cos(a) * s * FW * 1.12, sin(a) * s * FH * 1.1 - s * 0.04))
	for k in range(18, -1, -1):
		var x := lerpf(-1.0, 1.0, k / 18.0)
		# 髮際線：中間分線往上尖、兩邊往下蓋到太陽穴
		# （兩端要比外圈的弧低，多邊形才不會自己交叉、畫不出來）
		var y := -s * 0.52 + x * x * s * 0.5 - exp(-pow(x * 9.0, 2.0)) * s * 0.16
		hair.append(c + Vector2(x * s * FW * 1.12, y))
	ci.draw_colored_polygon(hair, HAIR)
	# 捲捲的紋路：沿著頭頂兩邊往外彎的小弧線
	for sx in [-1.0, 1.0]:
		for k in 3:
			var o := c + Vector2(sx * s * (0.2 + k * 0.22), -s * (0.78 - k * 0.12))
			ci.draw_arc(o, s * 0.14, PI * (0.6 if sx < 0.0 else -0.6), PI * (1.4 if sx < 0.0 else 0.4), 8, HAIR_LINE, maxf(1.0, s * 0.03), true)
	ci.draw_line(c + Vector2(0, -s * 0.7), c + Vector2(0, -s * 1.02), HAIR_LINE, maxf(1.0, s * 0.03), true)   # 分線
	# 腮紅
	for sx in [-1.0, 1.0]:
		_ell(ci, c + Vector2(sx * s * 0.42, s * 0.36), s * 0.12, s * 0.07, Color(0.95, 0.5, 0.5, 0.3))
	_face(ci, c, s, t, mood, blink)


static func _face(ci: CanvasItem, c: Vector2, s: float, t: float, mood: String, blink: bool) -> void:
	var lw := maxf(1.4, s * 0.06)
	# 眉毛：平平的、內側稍微低一點（很專注的樣子，但不是生氣）
	for sx in [-1.0, 1.0]:
		var bc := c + Vector2(sx * s * 0.3, -s * 0.2 - (s * 0.05 if mood == "think" else 0.0))
		ci.draw_line(bc + Vector2(-sx * s * 0.12, s * 0.015), bc + Vector2(sx * s * 0.12, -s * 0.015), BROW, maxf(2.0, s * 0.07), true)
	# 眼睛：小一點、銳利（深灰藍）
	for sx in [-1.0, 1.0]:
		var e := c + Vector2(sx * s * 0.3, s * 0.02)
		if mood == "happy":
			ci.draw_arc(e + Vector2(0, s * 0.05), s * 0.1, PI * 1.15, PI * 1.85, 10, EYE, lw, true)
		elif blink:
			ci.draw_line(e + Vector2(-s * 0.08, 0), e + Vector2(s * 0.08, 0), EYE, lw, true)
		else:
			var look := Vector2(-s * 0.04, s * 0.02) if mood == "think" else Vector2.ZERO        # 想事情：看著手上的蘋果
			_ell(ci, e + look, s * 0.075, s * 0.09, EYE)
			UITheme.dot(ci, e + look + Vector2(-s * 0.025, -s * 0.03), maxf(1.0, s * 0.025), Color(1, 1, 1, 0.9))
			ci.draw_line(e + Vector2(-s * 0.11, -s * 0.07), e + Vector2(s * 0.11, -s * 0.07), EYE, maxf(1.2, s * 0.04), true)   # 上眼皮
	# 鼻子：長長、挺挺的
	var nose := PackedVector2Array([c + Vector2(s * 0.04, s * 0.06), c + Vector2(s * 0.09, s * 0.27), c + Vector2(s * 0.01, s * 0.3)])
	ci.draw_polyline(nose, Color(LINE.r, LINE.g, LINE.b, 0.4), maxf(1.0, s * 0.03), true)
	_ell(ci, c + Vector2(s * 0.02, s * 0.29), s * 0.07, s * 0.045, Color(SKIN_SH.r, SKIN_SH.g, SKIN_SH.b, 0.7))
	# 嘴巴
	var m := c + Vector2(0, s * 0.55)
	var lip := Color("a5524a")
	match mood:
		"happy":
			ci.draw_colored_polygon(PackedVector2Array([m + Vector2(-s * 0.15, -s * 0.03), m + Vector2(s * 0.15, -s * 0.03), m + Vector2(s * 0.07, s * 0.09), m + Vector2(-s * 0.07, s * 0.09)]), lip)
		"talk":
			_ell(ci, m + Vector2(0, s * 0.01), s * 0.08, s * (0.03 + 0.045 * absf(sin(t * 9.0))), lip)
		"think":
			ci.draw_line(m + Vector2(-s * 0.06, 0), m + Vector2(s * 0.08, -s * 0.02), lip, lw, true)
		_:
			var pts := PackedVector2Array()
			for k in 9:
				var x := lerpf(-1.0, 1.0, k / 8.0)
				pts.append(m + Vector2(x * s * 0.11, s * 0.03 * (1.0 - x * x)))
			ci.draw_polyline(pts, lip, maxf(1.4, s * 0.05), true)


static func _ell(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)
