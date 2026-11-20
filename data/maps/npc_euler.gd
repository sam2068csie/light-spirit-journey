extends RefCounted
## Q 版歐拉（海上 NPC，草稿）：和 npc_gauss.gd 同一套比例（頭大身體小），程式畫的
##   參考他最常見的肖像（Handmann 1753）：頭上包著一頂米白色的布帽、圓圓的臉、大鼻子、溫和的笑；
##   右眼瞇瞇的（他 1738 年左右右眼看不見了，肖像上看得出來，畫得很輕）。深青色外套、白領巾。
##   招牌道具：一支羽毛筆（他一輩子寫了非常多論文）
##   在海上坐一艘掛著燈籠的小划船（和光舟分得開：沒有帆、船尾一根燈籠桿、小旗子上寫 e）
##   EulerNpc.draw(ci, 腳底的位置, 頭的大小, 時間, 表情, 步伐, 呼叫的人設好的畫布變換)：站著（對話框的頭像）
##   EulerNpc.draw_boat(ci, 水面上船的位置, 頭的大小, 時間, 表情, 划槳, 畫布變換)：坐在船上
##   表情：normal（會眨眼）、happy（眼睛彎彎、張嘴笑）、think（拿羽毛筆點下巴、眼睛往上看）、talk（嘴巴一開一合、揮手）
##   划槳（row）：弧度，一直加上去；< 0 是停著（槳放在船邊）
const UITheme := preload("res://data/ui/game_theme.gd")

const SKIN := Color("f2cdb0")
const SKIN_SH := Color("dca88a")
const SKIN_HI := Color("fbe3cf")
const WRAP := Color("efe4cc")          # 布帽
const WRAP_SH := Color("cdbb98")
const WRAP_LINE := Color(0.62, 0.52, 0.38, 0.75)
const HAIR := Color("6b4a35")
const BROW := Color("7a5640")
const COAT := Color("2f5d62")
const COAT_HI := Color("3f7479")
const COAT_SH := Color("22474b")
const CRAVAT := Color("fbf8f0")
const CRAVAT_SH := Color("dcd5c6")
const EYE := Color("3a2a22")
const LINE := Color(0.45, 0.28, 0.2, 0.5)
const SHOE := Color("2a2226")
const QUILL := Color("fbfaf4")
const QUILL_SH := Color("cfd6e0")
const WOOD := Color("b97c45")
const WOOD_SH := Color("7a4d28")
const WOOD_HI := Color("d9a065")
const FW := 0.86                # 圓臉：半寬 0.86、半高 0.92（乘頭的大小 s）
const FH := 0.92

const NAME := "歐拉"
const TITLE := "划船中"              # 靠近時下方卡片的副標（暫定）

static var _base := Transform2D.IDENTITY


## 站著（頭像、或之後要上岸時用）
static func draw(ci: CanvasItem, p: Vector2, s: float, t: float, mood := "normal", walk := -1.0, base := Transform2D.IDENTITY) -> void:
	_base = base
	var bob := sin(t * 2.0) * s * 0.025
	if walk >= 0.0:
		bob = -absf(sin(walk)) * s * 0.07
	_ell(ci, p + Vector2(0, s * 0.04), s * 0.8, s * 0.16, Color(0, 0, 0, 0.28))
	for sx in [-1.0, 1.0]:
		var lift := maxf(0.0, sin(walk) * sx) * s * 0.12 if walk >= 0.0 else 0.0
		_ell(ci, p + Vector2(sx * s * 0.21, -s * 0.04 - lift), s * 0.18, s * 0.1, SHOE)
	_figure(ci, p + Vector2(0, bob * 0.5), s, t, mood, -1.0, bob * 0.5)


## 坐在小划船上：p 是船在水面上的中心（船身擋住腰以下）
static func draw_boat(ci: CanvasItem, p: Vector2, s: float, t: float, mood := "normal", row := -1.0, base := Transform2D.IDENTITY) -> void:
	_base = base
	var bob := sin(t * 2.3) * s * 0.04
	var w := s * 1.9                  # 船身半寬
	var rim := p + Vector2(0, -s * 0.12 + bob)
	# 水面上的影子和波紋
	_ell(ci, p + Vector2(0, s * 0.22), w * 1.25, s * 0.26, Color(0, 0, 0, 0.18))
	# 船邊的小水波：左右各兩條短短的白線，慢慢往外飄
	for sx in [-1.0, 1.0]:
		for k in 2:
			var ph := fposmod(t * 0.5 + k * 0.5, 1.0)
			var wx := p + Vector2(sx * (w * 0.9 + ph * s * 0.9), s * (0.42 + k * 0.1))
			ci.draw_line(wx, wx + Vector2(sx * s * 0.4, 0), Color(1, 1, 1, 0.45 * (1.0 - ph)), maxf(1.0, s * 0.04), true)
	# 船的內側（看得到一點點船底）
	_ell(ci, rim, w * 0.94, s * 0.24, WOOD_SH)
	# 船尾的燈籠桿和寫著 e 的小旗子（在人的後面）
	var pole := rim + Vector2(-w * 0.8, 0)
	var ptop := pole + Vector2(-s * 0.15, -s * 2.6)
	ci.draw_line(pole, ptop, WOOD_SH, maxf(2.0, s * 0.07), true)
	var flag := PackedVector2Array([ptop + Vector2(0, s * 0.05), ptop + Vector2(s * 0.62, s * 0.18 + sin(t * 5.0) * s * 0.05), ptop + Vector2(0, s * 0.42)])
	ci.draw_colored_polygon(flag, Color("f5c84c"))
	if s >= 22.0:
		# 小旗子上的 e：船整個左右翻（往左划）時，字不要變成鏡像
		var xf := _base * Transform2D(0.0, ptop + Vector2(s * 0.24, s * 0.22))
		if _base.determinant() < 0.0:
			xf = xf * Transform2D.FLIP_X
		ci.draw_set_transform_matrix(xf)
		var fs := int(s * 0.32)
		ci.draw_string(UITheme.bold_font(), Vector2(-s * 0.3, fs * 0.36), "e", HORIZONTAL_ALIGNMENT_CENTER, s * 0.6, fs, Color("7a4d28"))
		ci.draw_set_transform_matrix(_base)
	var lamp := ptop + Vector2(s * 0.05, s * 0.62)
	ci.draw_line(ptop + Vector2(0, s * 0.42), lamp + Vector2(0, -s * 0.12), Color("5a3a22"), maxf(1.0, s * 0.03), true)
	var glow := 0.75 + 0.25 * sin(t * 3.0)
	UITheme.dot(ci, lamp, s * 0.55, Color(1.0, 0.85, 0.5, 0.18 * glow))
	UITheme.dot(ci, lamp, s * 0.3, Color(1.0, 0.85, 0.5, 0.3 * glow))
	ci.draw_rect(Rect2(lamp + Vector2(-s * 0.11, -s * 0.14), Vector2(s * 0.22, s * 0.28)), Color("ffe7a3"))
	ci.draw_rect(Rect2(lamp + Vector2(-s * 0.13, -s * 0.18), Vector2(s * 0.26, s * 0.06)), Color("5a3a22"))
	ci.draw_rect(Rect2(lamp + Vector2(-s * 0.13, s * 0.13), Vector2(s * 0.26, s * 0.05)), Color("5a3a22"))
	# 人（坐著：腳底放在船身裡面，腰以下會被船身擋住）
	_figure(ci, rim + Vector2(0, s * 0.42), s, t, mood, row, bob)
	# 船身（正面）：上緣一條亮邊，下面圓圓的
	var hull := PackedVector2Array()
	for k in 13:
		var u := k / 12.0
		hull.append(rim + Vector2(lerpf(w, -w, u), 0))
	for k in 13:
		var a := PI * k / 12.0
		hull.append(rim + Vector2(-cos(a) * w * (0.86 + 0.14 * sin(a)), sin(a) * s * 0.62))
	ci.draw_colored_polygon(hull, WOOD)
	for k in 2:
		var y := s * (0.2 + k * 0.18)
		ci.draw_line(rim + Vector2(-w * (0.95 - k * 0.08), y), rim + Vector2(w * (0.95 - k * 0.08), y), WOOD_SH, maxf(1.0, s * 0.035), true)
	ci.draw_line(rim + Vector2(-w, 0), rim + Vector2(w, 0), WOOD_HI, maxf(2.0, s * 0.08), true)
	# 槳：從兩手斜斜伸到水裡（划的時候前後擺）；停著的時候槳靠在船邊
	for sx in [-1.0, 1.0]:
		var hand := _oar_hand(rim + Vector2(0, s * 0.42), s, row, sx)
		var blade: Vector2
		if row >= 0.0:
			blade = rim + Vector2(sx * w * 1.45 + sin(row) * s * 0.35 * sx, s * 0.62 - cos(row) * s * 0.12)
		else:
			blade = rim + Vector2(sx * w * 1.35, s * 0.55)
		ci.draw_line(hand, blade, WOOD_SH, maxf(1.6, s * 0.06), true)
		_ell(ci, blade, s * 0.13, s * 0.07, WOOD)
		if row >= 0.0 and cos(row) > 0.7:
			UITheme.dot(ci, blade + Vector2(sx * s * 0.12, -s * 0.05), s * 0.05, Color(1, 1, 1, 0.7))      # 水花


## 划槳時手的位置（_figure 和 draw_boat 共用，手和槳才會接在一起）
static func _oar_hand(foot: Vector2, s: float, row: float, sx: float) -> Vector2:
	var top := foot.y - s * 0.95
	var fwd := sin(row) * s * 0.14 if row >= 0.0 else 0.0
	return Vector2(foot.x + sx * (s * 0.62 + fwd), top + s * 0.5)


## 身體＋頭＋前面的手（腳底在 p）
static func _figure(ci: CanvasItem, p: Vector2, s: float, t: float, mood: String, row: float, bob: float) -> void:
	var body_h := s * 0.95
	var head := p + Vector2(0, -body_h - s * 0.82 + bob * 0.5)
	var blink := fposmod(t + 2.1, 3.4) < 0.12 and mood == "normal"
	_body(ci, p, s, body_h, t, mood, row)
	_head(ci, head, s, t, mood, blink)
	match mood:
		"think":
			# 拿羽毛筆點下巴
			var chin := head + Vector2(s * 0.32, s * 0.88)
			var q0 := chin + Vector2(-s * 0.02, s * 0.02)
			var q1 := chin + Vector2(s * 0.34, -s * 0.62)
			var dir := (q1 - q0).normalized()
			var nrm := dir.orthogonal()
			var vane := PackedVector2Array()
			for k in 9:
				var u := k / 8.0
				vane.append(q0.lerp(q1, 0.25 + u * 0.75) + nrm * sin(u * PI) * s * 0.13)
			for k in range(8, -1, -1):
				var u := k / 8.0
				vane.append(q0.lerp(q1, 0.25 + u * 0.75) - nrm * sin(u * PI) * s * 0.07)
			ci.draw_colored_polygon(vane, QUILL)
			ci.draw_line(q0, q1, QUILL_SH, maxf(1.0, s * 0.03), true)
			UITheme.dot(ci, chin, s * 0.1, SKIN)
		"talk":
			if row < 0.0:
				# 張開手掌揮手（和高斯一樣：四根手指張成扇形＋大拇指，不要只伸一根手指）
				var palm := head + Vector2(s * 1.2, s * 0.56)
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

static func _body(ci: CanvasItem, p: Vector2, s: float, h: float, t: float, mood: String, row: float) -> void:
	var top := p.y - h
	var coat := PackedVector2Array([
		Vector2(p.x - s * 0.4, top + s * 0.04), Vector2(p.x + s * 0.4, top + s * 0.04),
		Vector2(p.x + s * 0.6, p.y - s * 0.14), Vector2(p.x + s * 0.54, p.y - s * 0.02),
		Vector2(p.x - s * 0.54, p.y - s * 0.02), Vector2(p.x - s * 0.6, p.y - s * 0.14)])
	ci.draw_colored_polygon(coat, COAT)
	ci.draw_colored_polygon(PackedVector2Array([coat[0], coat[1] + Vector2(-s * 0.26, 0), coat[4] + Vector2(s * 0.3, 0), coat[5]]), COAT_HI)
	# 翻領
	for sx in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x + sx * s * 0.16, top + s * 0.06), Vector2(p.x + sx * s * 0.36, top + s * 0.1),
			Vector2(p.x + sx * s * 0.12, top + s * 0.5), Vector2(p.x + sx * s * 0.04, top + s * 0.42)]), COAT_SH)
	# 白領巾：圍一圈、前面打個小結
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - s * 0.2, top), Vector2(p.x + s * 0.2, top),
		Vector2(p.x + s * 0.13, top + s * 0.4), Vector2(p.x - s * 0.13, top + s * 0.4)]), CRAVAT)
	ci.draw_line(Vector2(p.x, top + s * 0.14), Vector2(p.x, top + s * 0.38), CRAVAT_SH, maxf(1.0, s * 0.025), true)
	_ell(ci, Vector2(p.x, top + s * 0.1), s * 0.08, s * 0.06, CRAVAT_SH)
	# 鈕扣
	for k in 3:
		UITheme.dot(ci, Vector2(p.x + s * 0.2, top + s * 0.5 + k * h * 0.14), maxf(1.0, s * 0.035), Color("c9a85a"))
	# 手
	var arm_y := top + s * 0.28
	var rest_l := Vector2(p.x - s * 0.56, p.y - s * 0.34)
	var rest_r := Vector2(p.x + s * 0.56, p.y - s * 0.34)
	if row >= 0.0:
		for sx in [-1.0, 1.0]:
			_arm(ci, Vector2(p.x + sx * s * 0.38, arm_y), _oar_hand(p, s, row, sx), s)
		return
	match mood:
		"think":
			_arm(ci, Vector2(p.x + s * 0.38, arm_y), Vector2(p.x + s * 0.32, top - s * 0.04), s)
			_arm(ci, Vector2(p.x - s * 0.38, arm_y), rest_l, s)
		"talk":
			_arm(ci, Vector2(p.x + s * 0.38, arm_y), Vector2(p.x + s * 1.2, top - s * 0.32), s)
			_arm(ci, Vector2(p.x - s * 0.38, arm_y), rest_l, s)
		"happy":
			# 兩手攤開（很開心地在說話）
			for sx in [-1.0, 1.0]:
				_arm(ci, Vector2(p.x + sx * s * 0.38, arm_y), Vector2(p.x + sx * s * 0.82, top + s * 0.06 + sin(t * 4.0 + sx) * s * 0.03), s)
		_:
			for sx in [-1.0, 1.0]:
				_arm(ci, Vector2(p.x + sx * s * 0.38, arm_y), (rest_r if sx > 0.0 else rest_l) + Vector2(0, sin(t * 2.0 + sx) * s * 0.02), s)


static func _arm(ci: CanvasItem, from: Vector2, hand: Vector2, s: float) -> void:
	ci.draw_line(from, hand, COAT, s * 0.21, true)
	UITheme.dot(ci, from, s * 0.105, COAT)
	_ell(ci, hand + (hand - from).normalized() * s * 0.0, s * 0.11, s * 0.09, CRAVAT)      # 白袖口
	UITheme.dot(ci, hand, s * 0.1, SKIN)


# ───────────────────────── 頭 ─────────────────────────

static func _head(ci: CanvasItem, c: Vector2, s: float, t: float, mood: String, blink: bool) -> void:
	# 耳朵、耳邊一點點棕色頭髮（大部分藏在布帽裡）
	for sx in [-1.0, 1.0]:
		_ell(ci, c + Vector2(sx * s * FW * 0.98, s * 0.1), s * 0.13, s * 0.17, SKIN_SH)
		_ell(ci, c + Vector2(sx * s * FW * 0.97, s * 0.1), s * 0.07, s * 0.1, SKIN)
		_ell(ci, c + Vector2(sx * s * FW * 0.92, -s * 0.24), s * 0.12, s * 0.16, HAIR)
	# 臉：圓圓的，下巴豐滿
	_ell(ci, c, s * FW, s * FH, SKIN)
	_ell(ci, c + Vector2(0, s * 0.62), s * FW * 0.6, s * 0.26, Color(SKIN_SH.r, SKIN_SH.g, SKIN_SH.b, 0.18))
	# 布帽：圓鼓鼓地包住頭頂，前面一道折起來的邊，右上角垂下一小段布尾
	_ell(ci, c + Vector2(s * 0.04, -s * 0.6), s * 1.0, s * 0.66, WRAP_SH)
	_ell(ci, c + Vector2(0, -s * 0.64), s * 0.97, s * 0.64, WRAP)
	_ell(ci, c + Vector2(-s * 0.18, -s * 1.0), s * 0.5, s * 0.3, WRAP)                    # 頭頂鼓起來的一團布
	var band := PackedVector2Array()
	for k in 13:
		var x := lerpf(-1.0, 1.0, k / 12.0)
		band.append(c + Vector2(x * s * FW * 1.08, -s * 0.46 + x * x * s * 0.12))
	for k in range(12, -1, -1):
		var x := lerpf(-1.0, 1.0, k / 12.0)
		band.append(c + Vector2(x * s * FW * 1.04, -s * 0.7 + x * x * s * 0.1))
	ci.draw_colored_polygon(band, WRAP_SH)
	ci.draw_polyline(band.slice(0, 13), WRAP_LINE, maxf(1.0, s * 0.03), true)
	# 布的折痕：斜斜的幾條弧線
	for k in 3:
		var o := c + Vector2(-s * 0.5 + k * s * 0.38, -s * 0.94 + absf(k - 1.0) * s * 0.1)
		ci.draw_arc(o, s * 0.32, PI * 1.05, PI * 1.55, 10, WRAP_LINE, maxf(1.0, s * 0.03), true)
	# 布尾
	var tail := PackedVector2Array([c + Vector2(s * 0.72, -s * 0.7), c + Vector2(s * 0.98, -s * 0.58),
		c + Vector2(s * 1.06, -s * 0.2), c + Vector2(s * 0.9, -s * 0.26)])
	ci.draw_colored_polygon(tail, WRAP)
	ci.draw_polyline(PackedVector2Array([tail[1], tail[2]]), WRAP_LINE, maxf(1.0, s * 0.03), true)
	# 腮紅
	for sx in [-1.0, 1.0]:
		_ell(ci, c + Vector2(sx * s * 0.44, s * 0.34), s * 0.13, s * 0.08, Color(0.95, 0.5, 0.5, 0.3))
	_face(ci, c, s, t, mood, blink)


static func _face(ci: CanvasItem, c: Vector2, s: float, t: float, mood: String, blink: bool) -> void:
	var lw := maxf(1.4, s * 0.06)
	for sx in [-1.0, 1.0]:
		var bc := c + Vector2(sx * s * 0.31, -s * 0.2 - (s * 0.05 if mood == "think" else 0.0))
		ci.draw_arc(bc + Vector2(0, s * 0.1), s * 0.13, PI * 1.25, PI * 1.75, 8, BROW, maxf(2.0, s * 0.07), true)
	for sx in [-1.0, 1.0]:
		var e := c + Vector2(sx * s * 0.31, s * 0.03)
		# 他的右眼（畫面左邊）瞇瞇的：眼皮低一點、眼睛扁一點
		var squint: bool = sx < 0.0
		if mood == "happy":
			ci.draw_arc(e + Vector2(0, s * 0.05), s * 0.1, PI * 1.15, PI * 1.85, 10, EYE, lw, true)
		elif blink:
			ci.draw_line(e + Vector2(-s * 0.08, 0), e + Vector2(s * 0.08, 0), EYE, lw, true)
		else:
			var look := Vector2(s * 0.03, -s * 0.05) if mood == "think" else Vector2.ZERO
			var ry := s * (0.06 if squint else 0.095)
			_ell(ci, e + look + Vector2(0, s * 0.015 if squint else 0.0), s * 0.08, ry, EYE)
			if not squint:
				UITheme.dot(ci, e + look + Vector2(-s * 0.025, -s * 0.03), maxf(1.0, s * 0.025), Color(1, 1, 1, 0.9))
			ci.draw_arc(e + Vector2(0, s * (0.06 if squint else 0.04)), s * 0.11, PI * 1.15, PI * 1.85, 10, EYE, maxf(1.2, s * 0.04), true)
	# 鼻子：圓圓大大的
	ci.draw_line(c + Vector2(s * 0.03, s * 0.04), c + Vector2(s * 0.06, s * 0.2), LINE, maxf(1.0, s * 0.03), true)
	_ell(ci, c + Vector2(s * 0.01, s * 0.27), s * 0.12, s * 0.09, SKIN_SH)
	_ell(ci, c + Vector2(-s * 0.02, s * 0.25), s * 0.07, s * 0.05, SKIN_HI)
	# 嘴巴：溫和的笑
	var m := c + Vector2(0, s * 0.53)
	var lip := Color("a5524a")
	match mood:
		"happy":
			ci.draw_colored_polygon(PackedVector2Array([m + Vector2(-s * 0.16, -s * 0.04), m + Vector2(s * 0.16, -s * 0.04), m + Vector2(s * 0.07, s * 0.1), m + Vector2(-s * 0.07, s * 0.1)]), lip)
		"talk":
			_ell(ci, m + Vector2(0, s * 0.01), s * 0.08, s * (0.03 + 0.045 * absf(sin(t * 9.0))), lip)
		"think":
			_ell(ci, m + Vector2(s * 0.04, 0), s * 0.05, s * 0.03, lip)
		_:
			var pts := PackedVector2Array()
			for k in 9:
				var x := lerpf(-1.0, 1.0, k / 8.0)
				pts.append(m + Vector2(x * s * 0.15, s * 0.05 * (1.0 - x * x)))
			ci.draw_polyline(pts, lip, maxf(1.4, s * 0.05), true)


static func _ell(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)
