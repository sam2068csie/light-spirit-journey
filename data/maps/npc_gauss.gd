extends RefCounted
## Q 版高斯（地圖 NPC）：頭大身體小、圓圓的大眼睛，程式畫的（不用圖檔）
##   參考 1840 年 Jensen 的肖像：黑色絨布軟帽、白髮與白色落腮鬚、藍眼睛、白色高領＋皺褶領巾、深色外袍配酒紅色絨布翻領
##   GaussNpc.draw(ci, 腳底的位置, 頭的半徑, 時間, 表情)
##   表情：normal（平常，會眨眼）、happy（眼睛彎彎、張嘴笑）、think（一手摸下巴、眼睛往上看）、talk（嘴巴一開一合、舉起食指）
const UITheme := preload("res://data/ui/game_theme.gd")

const SKIN := Color("f7d9c0")
const SKIN_SH := Color("e9bfa2")
const HAIR := Color("f3f1ec")
const HAIR_SH := Color("cfcac2")
const CAP := Color("1e1c26")
const CAP_HI := Color("3a3646")
const COAT := Color("2b3430")
const COAT_HI := Color("3d4842")
const LAPEL := Color("6e2a3c")
const LAPEL_HI := Color("8c3a50")
const SHIRT := Color("fbf8ef")
const SHIRT_SH := Color("ddd6c4")
const EYE := Color("2a2440")
const IRIS := Color("4f7fd6")
const SHOE := Color("4a3426")


static func draw(ci: CanvasItem, p: Vector2, s: float, t: float, mood := "normal") -> void:
	var bob := sin(t * 2.2) * s * 0.025                 # 呼吸
	var body_h := s * 0.95
	var head := p + Vector2(0, -body_h - s * 0.82 + bob)
	var blink := fposmod(t, 3.7) < 0.12 and mood == "normal"
	# 影子
	_ell(ci, p + Vector2(0, s * 0.04), s * 0.78, s * 0.16, Color(0, 0, 0, 0.28))
	# 腳
	for sx in [-1.0, 1.0]:
		_ell(ci, p + Vector2(sx * s * 0.2, -s * 0.04), s * 0.17, s * 0.1, SHOE)
	_body(ci, p + Vector2(0, bob * 0.5), s, body_h, t, mood)
	_head(ci, head, s, t, mood, blink)
	_collar(ci, p + Vector2(0, bob * 0.5), head, s, body_h)
	# 要畫在頭前面的手：思考時摸下巴、說話時舉起食指
	if mood == "think":
		var chin := head + Vector2(s * 0.32, s * 0.86)
		_ell(ci, chin + Vector2(s * 0.04, s * 0.06), s * 0.13, s * 0.1, LAPEL)
		UITheme.dot(ci, chin, s * 0.11, SKIN)
		ci.draw_line(chin, chin + Vector2(-s * 0.12, -s * 0.08), SKIN, maxf(2.0, s * 0.08), true)
	elif mood == "talk":
		var up := head + Vector2(s * 1.22, s * 0.18 + sin(t * 6.0) * s * 0.04)
		UITheme.dot(ci, up, s * 0.11, SKIN)
		ci.draw_line(up, up + Vector2(0, -s * 0.24), SKIN, maxf(2.0, s * 0.09), true)
		UITheme.dot(ci, up + Vector2(0, -s * 0.24), maxf(1.0, s * 0.045), SKIN)


# ───────────────────────── 身體 ─────────────────────────

static func _body(ci: CanvasItem, p: Vector2, s: float, h: float, t: float, mood: String) -> void:
	var top := p.y - h
	# 外袍：上窄下寬的圓角梯形
	var coat := PackedVector2Array([
		Vector2(p.x - s * 0.36, top + s * 0.06), Vector2(p.x + s * 0.36, top + s * 0.06),
		Vector2(p.x + s * 0.58, p.y - s * 0.1), Vector2(p.x + s * 0.5, p.y - s * 0.02),
		Vector2(p.x - s * 0.5, p.y - s * 0.02), Vector2(p.x - s * 0.58, p.y - s * 0.1)])
	ci.draw_colored_polygon(coat, COAT)
	ci.draw_colored_polygon(PackedVector2Array([coat[0], coat[1] + Vector2(-s * 0.2, 0), coat[4] + Vector2(s * 0.3, 0), coat[5]]), COAT_HI)
	# 白襯衫（V 字露出來）
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - s * 0.24, top + s * 0.06), Vector2(p.x + s * 0.24, top + s * 0.06), Vector2(p.x, p.y - s * 0.2)]), SHIRT)
	# 酒紅色絨布翻領（兩條從肩膀斜到下擺）
	for sx in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(p.x + sx * s * 0.24, top + s * 0.05), Vector2(p.x + sx * s * 0.4, top + s * 0.08),
			Vector2(p.x + sx * s * 0.16, p.y - s * 0.08), Vector2(p.x + sx * s * 0.02, p.y - s * 0.16)]), LAPEL)
		ci.draw_line(Vector2(p.x + sx * s * 0.3, top + s * 0.1), Vector2(p.x + sx * s * 0.1, p.y - s * 0.16), LAPEL_HI, maxf(1.0, s * 0.03), true)
	# 皺褶領巾：一層層白色小波浪
	for k in 4:
		var y := top + s * (0.14 + 0.11 * k)
		var w := s * (0.12 - 0.015 * k)
		_ell(ci, Vector2(p.x, y), w, s * 0.06, SHIRT)
		ci.draw_arc(Vector2(p.x, y + s * 0.01), w * 0.8, 0.2, PI - 0.2, 8, SHIRT_SH, maxf(1.0, s * 0.02), true)
	# 手
	var arm_y := top + s * 0.3
	match mood:
		"think":
			# 右手摸下巴
			_arm(ci, Vector2(p.x + s * 0.38, arm_y), Vector2(p.x + s * 0.5, top - s * 0.02), s)
			_arm(ci, Vector2(p.x - s * 0.38, arm_y), Vector2(p.x - s * 0.52, p.y - s * 0.34), s)
		"talk":
			# 舉起食指：「我想到了！」
			_arm(ci, Vector2(p.x + s * 0.38, arm_y), Vector2(p.x + s * 0.9, top - s * 0.1), s)
			_arm(ci, Vector2(p.x - s * 0.38, arm_y), Vector2(p.x - s * 0.52, p.y - s * 0.34), s)
		_:
			for sx in [-1.0, 1.0]:
				_arm(ci, Vector2(p.x + sx * s * 0.38, arm_y), Vector2(p.x + sx * s * 0.54, p.y - s * 0.32 + sin(t * 2.2 + sx) * s * 0.02), s)


## 白色高領：下巴兩旁往上翹的兩片尖領
static func _collar(ci: CanvasItem, p: Vector2, head: Vector2, s: float, h: float) -> void:
	var neck_y := p.y - h + s * 0.08
	for sx in [-1.0, 1.0]:
		var pts := PackedVector2Array([
			Vector2(p.x + sx * s * 0.06, neck_y + s * 0.08),
			Vector2(p.x + sx * s * 0.42, neck_y + s * 0.02),
			Vector2(p.x + sx * s * 0.5, head.y + s * 0.66),
			Vector2(p.x + sx * s * 0.2, neck_y - s * 0.05)])
		ci.draw_colored_polygon(pts, SHIRT)
		ci.draw_polyline(PackedVector2Array([pts[1], pts[2], pts[3]]), SHIRT_SH, maxf(1.0, s * 0.03), true)


## 袖子＋圓圓的手
static func _arm(ci: CanvasItem, from: Vector2, hand: Vector2, s: float) -> void:
	ci.draw_line(from, hand, COAT, s * 0.2, true)
	UITheme.dot(ci, from, s * 0.1, COAT)
	_ell(ci, hand + (hand - from).normalized() * s * 0.02, s * 0.12, s * 0.1, LAPEL)     # 袖口
	UITheme.dot(ci, hand, s * 0.1, SKIN)


# ───────────────────────── 頭 ─────────────────────────

static func _head(ci: CanvasItem, c: Vector2, s: float, t: float, mood: String, blink: bool) -> void:
	# 耳朵旁蓬鬆的白髮（後面一層）
	for sx in [-1.0, 1.0]:
		for k in 3:
			UITheme.dot(ci, c + Vector2(sx * s * (0.9 + 0.06 * k), -s * (0.1 - 0.17 * k)), s * (0.24 - 0.03 * k), HAIR_SH)
	# 臉
	UITheme.dot(ci, c, s, SKIN)
	_ell(ci, c + Vector2(0, s * 0.52), s * 0.7, s * 0.32, Color(SKIN_SH.r, SKIN_SH.g, SKIN_SH.b, 0.35))
	# 白色落腮鬚：沿著兩頰往下到下巴旁
	for sx in [-1.0, 1.0]:
		var pts := PackedVector2Array()
		for k in 11:
			var a := lerpf(-0.2, 0.82, k / 10.0)
			pts.append(c + Vector2(sx * cos(a) * s * 1.01, sin(a) * s * 1.0))
		for k in range(10, -1, -1):
			var a := lerpf(-0.2, 0.72, k / 10.0)
			var th := 0.84 - 0.06 * sin(k / 10.0 * PI)          # 中間厚、兩頭尖
			pts.append(c + Vector2(sx * cos(a) * s * th, sin(a) * s * th + s * 0.04))
		ci.draw_colored_polygon(pts, HAIR)
	# 前面的蓬鬆白髮（耳朵上）
	for sx in [-1.0, 1.0]:
		for k in 3:
			UITheme.dot(ci, c + Vector2(sx * s * (0.86 + 0.05 * k), -s * (0.16 - 0.15 * k)), s * (0.19 - 0.025 * k), HAIR)
	# 腮紅
	for sx in [-1.0, 1.0]:
		_ell(ci, c + Vector2(sx * s * 0.5, s * 0.3), s * 0.14, s * 0.09, Color(1.0, 0.55, 0.55, 0.45))
	_face(ci, c, s, t, mood, blink)
	_cap(ci, c, s, t)


static func _face(ci: CanvasItem, c: Vector2, s: float, t: float, mood: String, blink: bool) -> void:
	var lw := maxf(1.5, s * 0.07)
	# 白色短眉毛
	for sx in [-1.0, 1.0]:
		var bc := c + Vector2(sx * s * 0.34, -s * 0.24 - (s * 0.05 if mood == "think" else 0.0))
		ci.draw_line(bc + Vector2(-s * 0.12, s * 0.02 * sx), bc + Vector2(s * 0.12, -s * 0.02 * sx), HAIR_SH, maxf(2.0, s * 0.09), true)
	# 眼睛
	for sx in [-1.0, 1.0]:
		var e := c + Vector2(sx * s * 0.33, -s * 0.02)
		if mood == "happy":
			ci.draw_arc(e + Vector2(0, s * 0.06), s * 0.13, PI * 1.15, PI * 1.85, 10, EYE, lw, true)
		elif blink:
			ci.draw_line(e + Vector2(-s * 0.12, 0), e + Vector2(s * 0.12, 0), EYE, lw, true)
		else:
			var look := Vector2(s * 0.03, -s * 0.06) if mood == "think" else Vector2.ZERO
			_ell(ci, e, s * 0.13, s * 0.17, EYE)
			_ell(ci, e + look + Vector2(0, s * 0.04), s * 0.09, s * 0.1, IRIS)
			_ell(ci, e + look + Vector2(0, s * 0.05), s * 0.05, s * 0.06, EYE)
			UITheme.dot(ci, e + look + Vector2(-s * 0.04, -s * 0.06), s * 0.045, Color.WHITE)
			UITheme.dot(ci, e + look + Vector2(s * 0.05, s * 0.07), s * 0.022, Color(1, 1, 1, 0.8))
	# 鼻子
	_ell(ci, c + Vector2(0, s * 0.18), s * 0.09, s * 0.07, Color("eaa58c"))
	# 嘴巴
	var m := c + Vector2(0, s * 0.42)
	match mood:
		"happy":
			ci.draw_colored_polygon(PackedVector2Array([m + Vector2(-s * 0.14, -s * 0.02), m + Vector2(s * 0.14, -s * 0.02), m + Vector2(s * 0.07, s * 0.1), m + Vector2(-s * 0.07, s * 0.1)]), Color("b8485a"))
		"talk":
			var o := 0.03 + 0.06 * absf(sin(t * 9.0))
			_ell(ci, m + Vector2(0, s * 0.02), s * 0.08, s * o, Color("b8485a"))
		"think":
			ci.draw_line(m + Vector2(-s * 0.08, s * 0.02), m + Vector2(s * 0.08, -s * 0.01), EYE, maxf(1.2, s * 0.05), true)
		_:
			ci.draw_arc(m + Vector2(0, -s * 0.06), s * 0.11, 0.35, PI - 0.35, 10, EYE, maxf(1.2, s * 0.05), true)


## 黑色絨布軟帽：軟軟地蓋住頭頂（沒有硬帽緣），往左上方鼓起、微微歪
static func _cap(ci: CanvasItem, c: Vector2, s: float, t: float) -> void:
	# 上緣：往左上鼓起的軟帽頂（左邊高一點）；下緣：兩端接回上緣、中間往下彎一點，蓋住額頭
	var top_arc := PackedVector2Array()
	for k in 17:
		var a := PI + PI * k / 16.0
		var lean := 1.0 + 0.22 * clampf(-cos(a), 0.0, 1.0)
		top_arc.append(c + Vector2(cos(a) * s * 1.05 - s * 0.05, -s * 0.42 + sin(a) * s * 0.8 * lean))
	var cap := PackedVector2Array(top_arc)
	var right: Vector2 = top_arc[top_arc.size() - 1]
	var left: Vector2 = top_arc[0]
	for k in range(1, 12):
		var u := k / 12.0
		cap.append(right.lerp(left, u) + Vector2(0, s * 0.1 * sin(u * PI)))
	ci.draw_colored_polygon(cap, CAP)
	# 絨布的光澤和一條折痕
	_ell(ci, c + Vector2(-s * 0.36, -s * 1.04), s * 0.3, s * 0.1, CAP_HI)
	ci.draw_arc(c + Vector2(s * 0.12, -s * 0.54), s * 0.6, PI * 1.12, PI * 1.6, 12, Color(0, 0, 0, 0.4), maxf(1.0, s * 0.04), true)


static func _ell(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)
