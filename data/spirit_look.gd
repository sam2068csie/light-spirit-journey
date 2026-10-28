extends RefCounted
## 光靈的樣子（含裝扮），所有畫光靈的地方共用：世界地圖、關卡左下角的光靈、提示框的臉、第一關奔跑的光靈、
## 劇情對話的頭像、扭蛋機、衣櫃。
##
## 畫的順序：draw_back（光暈、原地拖尾、身後的小夥伴）→ draw_body（奶油色圓球）→ 呼叫端自己畫眼睛（表情）
##           → draw_front（臉部裝飾、頭飾、身前的小夥伴）
## eq：穿戴中的裝扮 {"hat": id, "face": id, "aura": id, "trail": id, "pet": id}（沒穿就沒有那一格）
## 光靈朝右看：眼睛在 c + (0.22r, −0.22r)、c + (0.67r, −0.22r)

const UITheme := preload("game_theme.gd")
const Cos := preload("cosmetics.gd")
const Game := preload("game.gd")

const BASE_GLOW := Color(1.0, 0.9, 0.5)
const BODY := Color(1.0, 0.98, 0.85)
const INK := Color(0.15, 0.1, 0.3)


## 目前穿戴中的裝扮
static func eq_of(n: Node) -> Dictionary:
	if n == null or not n.is_inside_tree():
		return {}
	var g = Game.of(n)
	return g.equipped if g != null else {}


static func glow_color(eq: Dictionary, t: float) -> Color:
	var a := String(eq.get("aura", ""))
	match a:
		"aurora":
			var cols := [Color("7ef0c0"), Color("5ad8ff"), Color("c792ff")]
			var x := fposmod(t * 0.35, 3.0)
			var i := int(x)
			return cols[i].lerp(cols[(i + 1) % 3], x - i)
		"rainbow":
			return Color.from_hsv(fposmod(t * 0.18, 1.0), 0.5, 1.0)
		"galaxy":
			return Color("8f7bff").lerp(Color("5a3fd0"), 0.5 + 0.5 * sin(t * 0.8))
		"gold_aura":
			return Color("ffc93a").lerp(Color("fff1a8"), 0.5 + 0.5 * sin(t * 2.0))
		"":
			return BASE_GLOW
	var it := Cos.item(a)
	return it.get("col", BASE_GLOW)


## 光暈＋原地拖尾＋身後的小夥伴。idle_trail = false：呼叫端自己畫移動軌跡（地圖、奔跑）
static func draw_back(ci: CanvasItem, c: Vector2, r: float, eq: Dictionary, t: float, idle_trail := true) -> void:
	var g := glow_color(eq, t)
	if idle_trail and eq.get("trail", "") != "":
		_idle_trail(ci, c, r, String(eq.trail), t)
	UITheme.dot(ci, c, r * 2.45, Color(g.r, g.g, g.b, 0.12))
	UITheme.dot(ci, c, r * 1.55, Color(g.r, g.g, g.b, 0.30))
	if eq.get("aura", "") == "galaxy":
		for k in 9:
			var a := t * 0.35 + k * TAU / 9.0
			var d := r * (1.45 + 0.55 * fposmod(k * 0.618, 1.0))
			var tw := 0.5 + 0.5 * sin(t * 4.0 + k * 1.7)
			_spark(ci, c + Vector2(cos(a), sin(a) * 0.85) * d, r * (0.08 + 0.1 * tw), Color(1, 1, 1, 0.5 + 0.5 * tw))
	if eq.get("aura", "") == "rainbow":
		for k in 6:
			var a := t * 0.9 + k * TAU / 6.0
			_spark(ci, c + Vector2(cos(a), sin(a)) * r * 1.95, r * 0.22, Color.from_hsv(fposmod(k / 6.0 + t * 0.1, 1.0), 0.55, 1.0, 0.9))
	if eq.get("aura", "") == "gold_aura":
		# 金色光點慢慢往上飄
		for k in 6:
			var ph := fposmod(t * 0.35 + k / 6.0, 1.0)
			var x := sin(k * 2.3 + t * 0.7) * r * 1.3
			_spark(ci, c + Vector2(x, r * (1.2 - 2.6 * ph)), r * 0.16 * sin(ph * PI), Color(1.0, 0.88, 0.4, 0.9 * sin(ph * PI)))
	if eq.get("pet", "") != "":
		_pet(ci, c, r, String(eq.pet), t, true)


static func draw_body(ci: CanvasItem, c: Vector2, r: float, eq: Dictionary = {}, t: float = 0.0) -> void:
	var g := glow_color(eq, t)
	UITheme.dot(ci, c, r, BODY.lerp(g, 0.10) if eq.has("aura") else BODY)


## 一般的兩顆小眼睛（沒有表情需求的地方用）
static func draw_eyes(ci: CanvasItem, c: Vector2, r: float) -> void:
	var er := maxf(0.9, r * 0.2)
	UITheme.dot(ci, c + Vector2(r * 0.22, -r * 0.22), er, INK)
	UITheme.dot(ci, c + Vector2(r * 0.67, -r * 0.22), er, INK)


static func draw_front(ci: CanvasItem, c: Vector2, r: float, eq: Dictionary, t: float) -> void:
	if eq.get("face", "") != "":
		_face(ci, c, r, String(eq.face), t)
	if eq.get("hat", "") != "":
		_hat(ci, c, r, String(eq.hat), t)
	if eq.get("pet", "") != "":
		_pet(ci, c, r, String(eq.pet), t, false)


## 全部畫完（沒有表情的地方：地圖、奔跑、預覽）
static func draw_all(ci: CanvasItem, c: Vector2, r: float, eq: Dictionary, t: float, idle_trail := true) -> void:
	draw_back(ci, c, r, eq, t, idle_trail)
	draw_body(ci, c, r, eq, t)
	draw_eyes(ci, c, r)
	draw_front(ci, c, r, eq, t)


## 移動中的軌跡：pts[0] 是最新的位置
static func draw_path_trail(ci: CanvasItem, pts: Array, r: float, eq: Dictionary, t: float) -> void:
	var kind := String(eq.get("trail", ""))
	var n := pts.size()
	for k in n:
		var f := 1.0 - float(k) / n
		var p: Vector2 = pts[k]
		match kind:
			"star_trail":
				if k % 3 == 1:
					_star(ci, p, r * (0.25 + 0.35 * f), Color(1, 0.95, 0.6, 0.85 * f))
			"bubbles":
				if k % 4 == 2:
					ci.draw_arc(p + Vector2(0, -k * 0.25), r * (0.2 + 0.25 * (1.0 - f)), 0, TAU, 14, Color(0.75, 0.9, 1.0, 0.7 * f), maxf(1.0, r * 0.07), true)
			"expo_spark":
				if k % 2 == 0:
					var fl := 0.6 + 0.4 * sin(t * 20.0 + k)
					UITheme.dot(ci, p, r * (0.12 + 0.3 * f) * fl, Color(1.0, 0.55 + 0.3 * f, 0.2, 0.85 * f))
			"hearts":
				if k % 4 == 1:
					_heart(ci, p, r * (0.22 + 0.25 * f), Color(1.0, 0.45, 0.6, 0.85 * f))
			"notes":
				if k % 5 == 2:
					_note(ci, p + Vector2(0, -r * 0.3 * sin(k * 0.7)), r * (0.25 + 0.2 * f), Color(0.85, 0.9, 1.0, 0.85 * f))
			"petals":
				if k % 3 == 1:
					_petal(ci, p + Vector2(0, k * 0.4), r * (0.2 + 0.2 * f), t * 2.0 + k, Color(1.0, 0.7, 0.82, 0.85 * f))
			"digits":
				if k % 4 == 1:
					_digit(ci, p + Vector2(0, k * 0.3), r * (0.5 + 0.4 * f), str((k * 7) % 10), Color(0.6, 1.0, 0.75, 0.85 * f))
			"sine_wave":
				if k + 1 < n:
					var q: Vector2 = pts[k + 1]
					var w1 := sin(k * 0.6 - t * 8.0) * r * 0.5 * f
					var w2 := sin((k + 1) * 0.6 - t * 8.0) * r * 0.5 * f
					ci.draw_line(p + Vector2(0, w1), q + Vector2(0, w2), Color(0.4, 0.85, 1.0, 0.85 * f), maxf(1.0, r * 0.14 * f + 0.5), true)
			"snow":
				if k % 3 == 1:
					_flake(ci, p + Vector2(0, k * 0.5), r * (0.18 + 0.2 * f), t + k, Color(0.92, 0.97, 1.0, 0.9 * f))
			"comet":
				UITheme.dot(ci, p, r * (0.15 + 0.75 * f * f), Color(0.6, 0.85, 1.0, 0.35 * f))
				if k % 2 == 0:
					UITheme.dot(ci, p, r * 0.12 * f + 0.6, Color(1, 1, 1, 0.8 * f))
			"fireworks":
				if k % 6 == 3:
					var fc := Color.from_hsv(fposmod(k * 0.13, 1.0), 0.55, 1.0, 0.9 * f)
					for j in 6:
						var aa := j * TAU / 6.0 + k
						UITheme.dot(ci, p + Vector2(cos(aa), sin(aa)) * r * 0.45 * (1.2 - f), r * 0.07 + 0.5, fc)
			"fib_spiral":
				var fib := [1, 1, 2, 3, 5, 8]
				if k % 3 == 0:
					var fs: float = float(fib[(k / 3) % fib.size()]) / 8.0
					UITheme.dot(ci, p, r * (0.1 + 0.3 * fs) * (0.4 + 0.6 * f), Color(1.0, 0.82, 0.35, 0.9 * f))
			_:
				UITheme.dot(ci, p, r * (0.3 + 0.9 * f), Color(1.0, 0.95, 0.7, 0.18 * f))


# ---------------- 原地拖尾（關卡的光靈、預覽） ----------------

static func _idle_trail(ci: CanvasItem, c: Vector2, r: float, kind: String, t: float) -> void:
	match kind:
		"star_trail":
			for k in 4:
				var ph := fposmod(t * 0.8 + k * 0.25, 1.0)
				var p := c + Vector2(-r * (1.2 + 2.0 * ph), r * (0.3 * sin(t * 2.0 + k) + 0.2))
				_star(ci, p, r * 0.32 * (1.0 - ph), Color(1, 0.95, 0.6, 0.9 * (1.0 - ph)))
		"bubbles":
			for k in 4:
				var ph := fposmod(t * 0.5 + k * 0.25, 1.0)
				var p := c + Vector2(-r * (1.1 + 0.9 * ph) + 0.15 * r * sin(t * 3.0 + k), r * (0.5 - 1.6 * ph))
				ci.draw_arc(p, r * (0.16 + 0.14 * ph), 0, TAU, 16, Color(0.75, 0.9, 1.0, 0.85 * (1.0 - ph)), maxf(1.0, r * 0.07), true)
		"hearts":
			for k in 3:
				var ph := fposmod(t * 0.6 + k / 3.0, 1.0)
				_heart(ci, c + Vector2(-r * (1.2 + 1.6 * ph), r * (0.4 - 1.0 * ph)), r * 0.28 * (1.0 - 0.5 * ph), Color(1.0, 0.45, 0.6, 0.9 * (1.0 - ph)))
		"notes":
			for k in 3:
				var ph := fposmod(t * 0.5 + k / 3.0, 1.0)
				_note(ci, c + Vector2(-r * (1.2 + 1.5 * ph), r * (0.2 - 1.1 * ph) + r * 0.2 * sin(t * 4.0 + k)), r * 0.32, Color(0.85, 0.9, 1.0, 0.9 * (1.0 - ph)))
		"petals":
			for k in 4:
				var ph := fposmod(t * 0.4 + k / 4.0, 1.0)
				_petal(ci, c + Vector2(-r * (1.0 + 1.6 * ph) + r * 0.3 * sin(t * 2.0 + k), r * (-0.6 + 1.6 * ph)), r * 0.24, t * 2.5 + k, Color(1.0, 0.7, 0.82, 0.9 * (1.0 - ph)))
		"digits":
			for k in 4:
				var ph := fposmod(t * 0.45 + k / 4.0, 1.0)
				_digit(ci, c + Vector2(-r * (1.2 + 0.5 * k), r * (-0.7 + 1.8 * ph)), r * 0.6, str((k * 3 + int(t * 0.45 + k / 4.0)) % 10), Color(0.6, 1.0, 0.75, 0.9 * (1.0 - ph)))
		"sine_wave":
			var pts := PackedVector2Array()
			for k in 25:
				var s := k / 24.0
				pts.append(c + Vector2(-r * (1.0 + 2.2 * s), sin(s * TAU * 1.5 - t * 5.0) * r * 0.45 * (1.0 - s) + r * 0.15))
			ci.draw_polyline(pts, Color(0.4, 0.85, 1.0, 0.85), maxf(1.0, r * 0.12), true)
		"expo_spark":
			# 火花沿著 y = 2^{x} 的形狀往光靈竄
			for k in 7:
				var s := fposmod(t * 0.9 + k / 7.0, 1.0)
				var x := -2.6 + 2.2 * s
				var y := (pow(2.0, s * 3.0) - 1.0) / 7.0
				var p := c + Vector2(x * r, (0.7 - 1.3 * y) * r)
				UITheme.dot(ci, p, r * (0.08 + 0.12 * s), Color(1.0, 0.45 + 0.4 * s, 0.15, 0.3 + 0.6 * s))
		"snow":
			for k in 5:
				var ph := fposmod(t * 0.3 + k / 5.0, 1.0)
				var p := c + Vector2(-r * (1.1 + 0.4 * k) + r * 0.25 * sin(t * 1.5 + k), r * (-0.9 + 2.0 * ph))
				_flake(ci, p, r * 0.2, t * 0.8 + k, Color(0.92, 0.97, 1.0, 0.9 * sin(ph * PI)))
		"comet":
			# 往後拖的一條藍白色光尾
			for k in 14:
				var s := k / 13.0
				var p := c + Vector2(-r * (0.9 + 2.4 * s), r * (0.25 * s + 0.08 * sin(t * 3.0 - s * 4.0)))
				UITheme.dot(ci, p, r * 0.55 * (1.0 - s) + 0.5, Color(0.6, 0.85, 1.0, 0.28 * (1.0 - s)))
			for k in 4:
				var ph := fposmod(t * 1.2 + k / 4.0, 1.0)
				UITheme.dot(ci, c + Vector2(-r * (1.0 + 2.2 * ph), r * 0.2 * ph), r * 0.07, Color(1, 1, 1, 0.9 * (1.0 - ph)))
		"fireworks":
			# 身後一朵一朵綻開的小煙火
			for b in 2:
				var ph := fposmod(t * 0.6 + b * 0.5, 1.0)
				var bc := c + Vector2(-r * (1.5 + 0.6 * b), -r * (0.6 - 0.9 * b))
				var fc := Color.from_hsv(fposmod(floor(t * 0.6 + b * 0.5) * 0.31 + b * 0.4, 1.0), 0.6, 1.0, 1.0 - ph)
				for j in 8:
					var aa := j * TAU / 8.0
					UITheme.dot(ci, bc + Vector2(cos(aa), sin(aa)) * r * 0.75 * ph + Vector2(0, r * 0.2 * ph * ph), r * 0.07 + 0.5, fc)
		"fib_spiral":
			# 費氏（黃金）螺旋：每轉四分之一圈放大 φ 倍，慢慢轉
			var o := c + Vector2(-r * 1.55, r * 0.1)
			var phi := 1.618034
			var pts := PackedVector2Array()
			for k in 61:
				var th := k * (1.75 * TAU) / 60.0
				var rr := r * 0.05 * pow(phi, th / (PI / 2.0))
				pts.append(o + Vector2(cos(-th + t * 0.6), sin(-th + t * 0.6)) * rr)
			var gc := Color(1.0, 0.82, 0.35)
			ci.draw_polyline(pts, Color(gc.r, gc.g, gc.b, 0.25), maxf(2.0, r * 0.18), true)
			ci.draw_polyline(pts, gc, maxf(1.0, r * 0.07), true)
			var tip := pts[int(fposmod(t * 20.0, pts.size()))]
			UITheme.dot(ci, tip, r * 0.1, Color.WHITE)


# ---------------- 臉部 ----------------

static func _face(ci: CanvasItem, c: Vector2, r: float, id: String, t: float) -> void:
	var e1 := c + Vector2(r * 0.22, -r * 0.22)
	var e2 := c + Vector2(r * 0.67, -r * 0.22)
	var lw := maxf(1.0, r * 0.08)
	match id:
		"blush":
			UITheme.dot(ci, e1 + Vector2(-r * 0.12, r * 0.34), r * 0.15, Color(1.0, 0.5, 0.6, 0.55))
			UITheme.dot(ci, e2 + Vector2(r * 0.1, r * 0.34), r * 0.15, Color(1.0, 0.5, 0.6, 0.55))
		"round_glasses":
			var col := Color("5a3a2a")
			ci.draw_arc(e1, r * 0.24, 0, TAU, 20, col, lw, true)
			ci.draw_arc(e2, r * 0.24, 0, TAU, 20, col, lw, true)
			ci.draw_line(e1 + Vector2(r * 0.24, 0), e2 - Vector2(r * 0.24, 0), col, lw, true)
		"pi_glasses":
			# π 墨鏡：上面一條橫槓（π 的頭），兩片深色鏡片當兩隻腳
			var col := Color("2a2350")
			for e in [e1, e2]:
				ci.draw_colored_polygon(_round_rect(Rect2(e.x - r * 0.2, e.y - r * 0.13, r * 0.4, r * 0.3)), col)
				UITheme.dot(ci, e + Vector2(-r * 0.08, -r * 0.03), r * 0.05, Color(1, 1, 1, 0.7))
			ci.draw_line(Vector2(e1.x - r * 0.32, e1.y - r * 0.2), Vector2(e2.x + r * 0.32, e2.y - r * 0.2), col, maxf(1.2, r * 0.1), true)
		"star_eyes":
			var tw := 1.0 + 0.12 * sin(t * 5.0)
			for e in [e1, e2]:
				_star(ci, e, r * 0.27 * tw, Color("ffcf5a"))
				UITheme.dot(ci, e, r * 0.07, Color(1, 1, 1, 0.9))
		"streak_scarf":
			# 簽到圍巾：繞在身體下半部的紅圍巾，尾巴隨風擺動
			var red := Color("e84a5f")
			var band := PackedVector2Array()
			for k in 13:
				var a := deg_to_rad(25.0 + 130.0 * k / 12.0)
				band.append(c + Vector2(cos(a), sin(a)) * r * 0.98)
			for k in 13:
				var a := deg_to_rad(155.0 - 130.0 * k / 12.0)
				band.append(c + Vector2(cos(a), sin(a)) * r * 0.7)
			ci.draw_colored_polygon(band, red)
			var knot := c + Vector2(-r * 0.55, r * 0.68)
			var sw := sin(t * 3.0) * r * 0.08
			ci.draw_colored_polygon(PackedVector2Array([knot, knot + Vector2(-r * 0.42, r * 0.28 + sw), knot + Vector2(-r * 0.3, r * 0.52 + sw), knot + Vector2(r * 0.05, r * 0.15)]), red.darkened(0.12))
			for k in 3:
				var a := deg_to_rad(50.0 + 35.0 * k)
				ci.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.72, c + Vector2(cos(a), sin(a)) * r * 0.96, Color(1, 1, 1, 0.55), maxf(1.0, r * 0.06), true)
		"mustache":
			var m := c + Vector2(r * 0.45, r * 0.18)
			var col := Color("5a3a2a")
			for sd in [-1.0, 1.0]:
				var pts := PackedVector2Array()
				for k in 9:
					var u := k / 8.0
					pts.append(m + Vector2(sd * (r * 0.04 + r * 0.4 * u), r * 0.07 * sin(u * PI) - r * 0.2 * u * u))
				ci.draw_polyline(pts, col, maxf(1.2, r * 0.12), true)
				UITheme.dot(ci, pts[8], maxf(0.8, r * 0.07), col)
		"monocle":
			var gold := Color("e8b040")
			ci.draw_arc(e2, r * 0.27, 0, TAU, 22, gold, maxf(1.0, r * 0.08), true)
			UITheme.dot(ci, e2 + Vector2(-r * 0.1, -r * 0.1), r * 0.06, Color(1, 1, 1, 0.6))
			var chain := PackedVector2Array()
			for k in 9:
				var s := k / 8.0
				chain.append(e2 + Vector2(r * 0.25, r * 0.12) + Vector2(r * 0.15 * s, r * 0.75 * s + sin(s * PI) * r * 0.1))
			ci.draw_polyline(chain, gold, maxf(0.8, r * 0.04), true)
		"heart_eyes":
			var tw := 1.0 + 0.15 * sin(t * 6.0)
			for e in [e1, e2]:
				_heart(ci, e, r * 0.26 * tw, Color("ff4d7a"))
		"star_sticker":
			_star(ci, e2 + Vector2(r * 0.12, r * 0.42), r * 0.17, Color("ffcf5a"))
			UITheme.dot(ci, e2 + Vector2(r * 0.07, r * 0.37), r * 0.035, Color(1, 1, 1, 0.8))
		"freckles":
			for e in [e1, e2]:
				for k in 3:
					UITheme.dot(ci, e + Vector2(r * (-0.12 + 0.12 * k), r * (0.34 + 0.05 * (k % 2))), maxf(0.6, r * 0.035), Color("c27a4a"))
		"bandaid":
			# OK 繃：斜斜貼在臉頰上
			var bc := c + Vector2(-r * 0.12, r * 0.22)
			var ax := Vector2(cos(-0.45), sin(-0.45))
			var ay := Vector2(-ax.y, ax.x)
			var hw := r * 0.3
			var hh := r * 0.09
			ci.draw_colored_polygon(PackedVector2Array([bc - ax * hw - ay * hh, bc + ax * hw - ay * hh, bc + ax * hw + ay * hh, bc - ax * hw + ay * hh]), Color("f2c9a0"))
			ci.draw_colored_polygon(PackedVector2Array([bc - ax * hw * 0.35 - ay * hh, bc + ax * hw * 0.35 - ay * hh, bc + ax * hw * 0.35 + ay * hh, bc - ax * hw * 0.35 + ay * hh]), Color("e0ad80"))
			for k in 2:
				UITheme.dot(ci, bc + ax * hw * (k - 0.5) * 0.25, maxf(0.5, r * 0.025), Color(0.6, 0.4, 0.3, 0.7))
		"hero_mask":
			# 英雄眼罩：紅色的帶子蓋住眼睛，後面兩條飄帶
			var red := Color("e23d5a")
			var y0 := e1.y
			var band := PackedVector2Array([Vector2(e1.x - r * 0.42, y0 - r * 0.18), Vector2(e2.x + r * 0.32, y0 - r * 0.2),
				Vector2(e2.x + r * 0.3, y0 + r * 0.17), Vector2(e1.x - r * 0.42, y0 + r * 0.16)])
			ci.draw_colored_polygon(band, red)
			var knot := Vector2(c.x - r * 0.62, y0)
			var sw := sin(t * 4.0) * r * 0.07
			ci.draw_colored_polygon(PackedVector2Array([knot, knot + Vector2(-r * 0.45, -r * 0.1 + sw), knot + Vector2(-r * 0.4, r * 0.06 + sw)]), red.darkened(0.15))
			ci.draw_colored_polygon(PackedVector2Array([knot, knot + Vector2(-r * 0.38, r * 0.22 - sw), knot + Vector2(-r * 0.3, r * 0.32 - sw)]), red.darkened(0.15))
			for e in [e1, e2]:
				UITheme.dot(ci, e, r * 0.15, Color.WHITE)        # 英雄面具的白色眼睛
				UITheme.dot(ci, e + Vector2(r * 0.03, 0), maxf(0.7, r * 0.08), INK)


# ---------------- 頭飾 ----------------

static func _hat(ci: CanvasItem, c: Vector2, r: float, id: String, t: float) -> void:
	var hx := c.x + r * 0.12
	var top := c.y - r * 0.92
	var lw := maxf(1.0, r * 0.1)
	match id:
		"sprout":
			var base := Vector2(hx, top + r * 0.05)
			var tipp := base + Vector2(0, -r * 0.42)
			ci.draw_line(base, tipp, Color("4caf50"), lw, true)
			var sway := 0.08 * sin(t * 2.0)
			for s in [-1.0, 1.0]:
				var d := Vector2(s * r * 0.42, -r * (0.12 + sway * s))
				var m := tipp + d * 0.5
				var nrm := Vector2(-d.y, d.x).normalized() * r * 0.13
				ci.draw_colored_polygon(PackedVector2Array([tipp, m + nrm, tipp + d, m - nrm]), Color("7ed957"))
		"bow":
			var b := c + Vector2(-r * 0.42, -r * 0.82)
			var col := Color("ff7eb6")
			ci.draw_colored_polygon(PackedVector2Array([b, b + Vector2(-r * 0.42, -r * 0.25), b + Vector2(-r * 0.38, r * 0.22)]), col)
			ci.draw_colored_polygon(PackedVector2Array([b, b + Vector2(r * 0.42, -r * 0.28), b + Vector2(r * 0.36, r * 0.2)]), col)
			UITheme.dot(ci, b, r * 0.12, col.darkened(0.2))
		"grad_cap":
			var col := Color("2a2350")
			ci.draw_colored_polygon(_round_rect(Rect2(hx - r * 0.42, top - r * 0.08, r * 0.84, r * 0.26)), col)
			var board := PackedVector2Array([Vector2(hx - r * 0.85, top - r * 0.12), Vector2(hx, top - r * 0.42),
				Vector2(hx + r * 0.85, top - r * 0.12), Vector2(hx, top + r * 0.14)])
			ci.draw_colored_polygon(board, col)
			ci.draw_polyline(board + PackedVector2Array([board[0]]), col.lightened(0.25), maxf(1.0, r * 0.05), true)
			var knot := Vector2(hx, top - r * 0.14)
			var tip := Vector2(hx + r * 0.62, top - r * 0.02)
			ci.draw_line(knot, tip, Color("ffcf5a"), maxf(1.0, r * 0.06), true)
			ci.draw_line(tip, tip + Vector2(0, r * 0.38 + r * 0.04 * sin(t * 3.0)), Color("ffcf5a"), maxf(1.0, r * 0.07), true)
			UITheme.dot(ci, knot, r * 0.07, Color("ffcf5a"))
		"root_crown":
			# 根號皇冠：金色的 √ 坐在頭上
			var gold := Color("ffcf5a")
			var dark := Color("b07a14")
			var pts := PackedVector2Array([Vector2(hx - r * 0.62, top - r * 0.22), Vector2(hx - r * 0.45, top - r * 0.3),
				Vector2(hx - r * 0.22, top + r * 0.02), Vector2(hx + r * 0.05, top - r * 0.72), Vector2(hx + r * 0.68, top - r * 0.72)])
			ci.draw_polyline(pts, dark, maxf(2.0, r * 0.2), true)
			ci.draw_polyline(pts, gold, maxf(1.4, r * 0.12), true)
			for k in 3:
				var gp := pts[3].lerp(pts[4], (k + 0.5) / 3.0) + Vector2(0, -r * 0.1)
				UITheme.dot(ci, gp, r * 0.07, [Color("ff7eb6"), Color("5ad8ff"), Color("a6f05a")][k])
			var sh := 0.5 + 0.5 * sin(t * 3.0)
			_spark(ci, pts[4] + Vector2(r * 0.05, -r * 0.18), r * 0.16, Color(1, 1, 1, 0.5 + 0.5 * sh))
		"daisy":
			var f := c + Vector2(-r * 0.32, -r * 0.82)
			for k in 8:
				var a := k * TAU / 8.0 + 0.2
				UITheme.dot(ci, f + Vector2(cos(a), sin(a)) * r * 0.17, r * 0.11, Color(1, 1, 1, 0.97))
			UITheme.dot(ci, f, r * 0.11, Color("ffcf3a"))
		"cat_ears":
			for s in [-1.0, 1.0]:
				var b := Vector2(c.x + s * r * 0.48 + r * 0.08, c.y - r * 0.72)
				var outer := PackedVector2Array([b + Vector2(-r * 0.28, r * 0.12), b + Vector2(s * r * 0.08, -r * 0.5), b + Vector2(r * 0.28, r * 0.12)])
				ci.draw_colored_polygon(outer, BODY.darkened(0.04))
				var inner := PackedVector2Array([b + Vector2(-r * 0.14, r * 0.04), b + Vector2(s * r * 0.06, -r * 0.3), b + Vector2(r * 0.14, r * 0.04)])
				ci.draw_colored_polygon(inner, Color(1.0, 0.65, 0.75))
		"wizard_hat":
			var col := Color("6b4bd6")
			var tip := Vector2(hx + r * 0.35 + r * 0.06 * sin(t * 2.0), top - r * 1.15)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(hx - r * 0.5, top + r * 0.02), tip, Vector2(hx + r * 0.55, top + r * 0.02)]), col)
			ci.draw_colored_polygon(_round_rect(Rect2(hx - r * 0.78, top - r * 0.04, r * 1.56, r * 0.18)), col.darkened(0.2))
			_star(ci, Vector2(hx + r * 0.05, top - r * 0.4), r * 0.16, Color("ffcf5a"))
			UITheme.dot(ci, tip, r * 0.07, Color("ffcf5a"))
		"star_tiara":
			ci.draw_arc(Vector2(hx, top + r * 0.55), r * 0.62, PI * 1.18, PI * 1.82, 18, Color("e8ecff"), maxf(1.2, r * 0.1), true)
			var tw := 0.5 + 0.5 * sin(t * 4.0)
			for k in 3:
				var a := PI * (1.32 + 0.18 * k)
				var p := Vector2(hx, top + r * 0.55) + Vector2(cos(a), sin(a)) * r * 0.62
				var big := 0.3 if k == 1 else 0.2
				_star(ci, p + Vector2(0, -r * big * 0.6), r * big, [Color("5ad8ff"), Color("ffcf5a"), Color("ff7eb6")][k])
			_spark(ci, Vector2(hx + r * 0.1, top - r * 0.62), r * 0.14 * tw, Color(1, 1, 1, tw))
		"spiral_crown":
			# 對數螺旋：r = a·e^{bθ}，慢慢旋轉
			var cc := Vector2(hx, top - r * 0.42)
			var pts := PackedVector2Array()
			for k in 60:
				var th := k * 0.17
				var rr := r * 0.075 * exp(0.22 * th)
				pts.append(cc + Vector2(cos(th + t * 1.2), sin(th + t * 1.2) * 0.8) * rr)
			var g := Color("ffcf5a")
			ci.draw_polyline(pts, Color(g.r, g.g, g.b, 0.3), maxf(2.0, r * 0.22), true)
			ci.draw_polyline(pts, g, maxf(1.0, r * 0.09), true)
			UITheme.dot(ci, pts[pts.size() - 1], r * 0.09, Color.WHITE)
		"inf_halo":
			# 無限光環：∞ 形狀浮在頭上，有一顆光點沿著它跑
			var cc := Vector2(hx, top - r * 0.45 + r * 0.05 * sin(t * 2.0))
			var pts := PackedVector2Array()
			for k in 41:
				var s := TAU * k / 40.0
				var d := 1.0 + sin(s) * sin(s)
				pts.append(cc + Vector2(cos(s) / d * r * 0.8, sin(s) * cos(s) / d * r * 0.75))
			var g := Color("5ad8ff").lerp(Color("ffcf5a"), 0.5 + 0.5 * sin(t * 1.5))
			ci.draw_polyline(pts, Color(g.r, g.g, g.b, 0.3), maxf(2.0, r * 0.26), true)
			ci.draw_polyline(pts, g, maxf(1.0, r * 0.1), true)
			var s2 := fposmod(t * 1.4, TAU)
			var d2 := 1.0 + sin(s2) * sin(s2)
			UITheme.dot(ci, cc + Vector2(cos(s2) / d2 * r * 0.8, sin(s2) * cos(s2) / d2 * r * 0.75), r * 0.1, Color.WHITE)
		"headphones":
			var band := Color("5ad8ff")
			ci.draw_arc(c + Vector2(0, -r * 0.05), r * 1.02, deg_to_rad(195), deg_to_rad(345), 24, band.darkened(0.3), maxf(2.0, r * 0.2), true)
			ci.draw_arc(c + Vector2(0, -r * 0.05), r * 1.02, deg_to_rad(195), deg_to_rad(345), 24, band, maxf(1.2, r * 0.12), true)
			for sd in [-1.0, 1.0]:
				var cup := c + Vector2(sd * r * 0.98, -r * 0.18)
				ci.draw_colored_polygon(_round_rect(Rect2(cup.x - r * 0.17, cup.y - r * 0.26, r * 0.34, r * 0.52)), Color("2a2350"))
				UITheme.dot(ci, cup, r * 0.09, band)
			# 音樂開著：旁邊冒出小音符
			var ph := fposmod(t * 0.7, 1.0)
			_note(ci, c + Vector2(r * 1.25, -r * (0.6 + 0.6 * ph)), r * 0.22, Color(0.85, 0.95, 1.0, 1.0 - ph))
		"laurel":
			# 月桂冠：兩條葉子枝從兩側繞到頭頂
			var green := Color("8fcf4a")
			var gold := Color("ffcf5a")
			for sd in [-1.0, 1.0]:
				for k in 6:
					var ang := deg_to_rad(270.0 + sd * (18.0 + 14.0 * k))
					var p := c + Vector2(cos(ang), sin(ang)) * r * 0.98 + Vector2(r * 0.05, 0)
					var rot: float = ang + PI / 2.0 + sd * 0.5
					_petal(ci, p, r * 0.18, rot, green if k % 2 == 0 else green.darkened(0.15))
				UITheme.dot(ci, c + Vector2(cos(deg_to_rad(270.0 + sd * 100.0)), sin(deg_to_rad(270.0 + sd * 100.0))) * r * 0.98, r * 0.06, gold)
			var tw := 0.5 + 0.5 * sin(t * 3.0)
			_spark(ci, c + Vector2(r * 0.05, -r * 1.12), r * 0.15 * (0.6 + 0.4 * tw), Color(1, 0.95, 0.6, tw))


# ---------------- 小夥伴（繞著光靈轉） ----------------

static func _pet(ci: CanvasItem, c: Vector2, r: float, id: String, t: float, back: bool) -> void:
	var a := t * 1.5
	var behind := sin(a) < 0.0
	if behind != back:
		return
	var p := c + Vector2(cos(a) * r * 1.95, sin(a) * r * 0.55 - r * 0.35)
	var sc := 0.85 if behind else 1.0
	match id:
		"firefly":
			var bl := 0.5 + 0.5 * sin(t * 6.0)
			UITheme.dot(ci, p, r * 0.42 * sc, Color(0.85, 1.0, 0.4, 0.18 + 0.2 * bl))
			UITheme.dot(ci, p, r * 0.16 * sc, Color(0.9, 1.0, 0.5, 0.7 + 0.3 * bl))
		"paper_plane":
			var dir := Vector2(-sin(a) * 1.95, cos(a) * 0.55).normalized()
			var nrm := Vector2(-dir.y, dir.x)
			var s := r * 0.42 * sc
			ci.draw_colored_polygon(PackedVector2Array([p + dir * s, p - dir * s * 0.7 + nrm * s * 0.55, p - dir * s * 0.35]), Color(0.95, 0.97, 1.0))
			ci.draw_colored_polygon(PackedVector2Array([p + dir * s, p - dir * s * 0.35, p - dir * s * 0.7 - nrm * s * 0.4]), Color(0.78, 0.84, 0.95))
		"chick":
			var hop := absf(sin(t * 6.0)) * r * 0.12
			var q := p + Vector2(0, -hop)
			UITheme.dot(ci, q, r * 0.32 * sc, Color("ffe066"))
			UITheme.dot(ci, q + Vector2(r * 0.1, -r * 0.08) * sc, r * 0.05 * sc, INK)
			ci.draw_colored_polygon(PackedVector2Array([q + Vector2(r * 0.28, -r * 0.02) * sc, q + Vector2(r * 0.44, r * 0.04) * sc, q + Vector2(r * 0.28, r * 0.1) * sc]), Color("ff9a3a"))
		"pencil":
			var dir := Vector2(-sin(a) * 1.95, cos(a) * 0.55).normalized()
			var nrm := Vector2(-dir.y, dir.x)
			var L := r * 0.55 * sc
			var w := r * 0.12 * sc
			var tipp := p + dir * L
			var tail := p - dir * L
			ci.draw_colored_polygon(PackedVector2Array([tail + nrm * w, p + dir * L * 0.55 + nrm * w, p + dir * L * 0.55 - nrm * w, tail - nrm * w]), Color("ffcf3a"))
			ci.draw_colored_polygon(PackedVector2Array([p + dir * L * 0.55 + nrm * w, tipp, p + dir * L * 0.55 - nrm * w]), Color("f3d9b0"))
			UITheme.dot(ci, tipp - dir * L * 0.08, w * 0.45, INK)
			ci.draw_colored_polygon(PackedVector2Array([tail + nrm * w, tail - nrm * w, tail - dir * w * 1.4 - nrm * w, tail - dir * w * 1.4 + nrm * w]), Color("ff8fa3"))
		"moon":
			var mr := r * 0.34 * sc
			UITheme.dot(ci, p, mr * 1.7, Color(1.0, 0.95, 0.6, 0.15))
			var pts := PackedVector2Array()
			for k in 17:
				var aa := -PI / 2.0 + PI * k / 16.0
				pts.append(p + Vector2(cos(aa), sin(aa)) * mr)
			for k in 17:
				var aa := PI / 2.0 - PI * k / 16.0
				pts.append(p + Vector2(cos(aa) * mr * 0.35, sin(aa) * mr))
			ci.draw_colored_polygon(pts, Color("fff3a0"))
		"e_sprite":
			UITheme.dot(ci, p, r * 0.5 * sc, Color(0.78, 0.57, 1.0, 0.18))
			UITheme.dot(ci, p, r * 0.3 * sc, Color("c792ff"))
			var font: Font = (ci as Control).get_theme_default_font() if ci is Control else ThemeDB.fallback_font
			var fs := int(maxf(7.0, r * 0.42 * sc))
			ci.draw_string(font, p + Vector2(-r * 0.3, fs * 0.36), "e", HORIZONTAL_ALIGNMENT_CENTER, r * 0.6, fs, Color.WHITE)
		"kitten":
			var q := p + Vector2(0, -absf(sin(t * 5.0)) * r * 0.08)
			var fur := Color("ffb86b")
			for sd in [-1.0, 1.0]:
				var b := q + Vector2(sd * r * 0.18, -r * 0.2) * sc
				ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-r * 0.1, r * 0.05) * sc, b + Vector2(sd * r * 0.04, -r * 0.18) * sc, b + Vector2(r * 0.1, r * 0.05) * sc]), fur)
			UITheme.dot(ci, q, r * 0.3 * sc, fur)
			UITheme.dot(ci, q + Vector2(0, r * 0.08) * sc, r * 0.16 * sc, Color("fff0dc"))
			for sd in [-1.0, 1.0]:
				UITheme.dot(ci, q + Vector2(sd * r * 0.11, -r * 0.04) * sc, r * 0.045 * sc, INK)
		"goldfish":
			var q := p + Vector2(0, sin(t * 3.0) * r * 0.06)
			var dir := -1.0 if cos(t * 1.5) > 0.0 else 1.0
			var body := PackedVector2Array()
			for k in 16:
				var aa := TAU * k / 16.0
				body.append(q + Vector2(cos(aa) * r * 0.3, sin(aa) * r * 0.19) * sc)
			var flap := sin(t * 10.0) * r * 0.06
			ci.draw_colored_polygon(PackedVector2Array([q + Vector2(-dir * r * 0.24, 0) * sc, q + Vector2(-dir * r * 0.5, -r * 0.2 + flap) * sc, q + Vector2(-dir * r * 0.5, r * 0.2 - flap) * sc]), Color("ff9a3a"))
			ci.draw_colored_polygon(body, Color("ff7a2a"))
			UITheme.dot(ci, q + Vector2(dir * r * 0.15, -r * 0.04) * sc, r * 0.045 * sc, INK)
			var bp := fposmod(t * 0.8, 1.0)
			ci.draw_arc(q + Vector2(dir * r * 0.35, -r * (0.2 + 0.4 * bp)) * sc, r * 0.06 * sc, 0, TAU, 10, Color(0.8, 0.95, 1.0, 1.0 - bp), maxf(0.8, r * 0.03), true)
		"calculator":
			var rc := Rect2(p.x - r * 0.24 * sc, p.y - r * 0.33 * sc, r * 0.48 * sc, r * 0.66 * sc)
			ci.draw_colored_polygon(_round_rect(rc), Color("3a4170"))
			ci.draw_rect(Rect2(rc.position + Vector2(r * 0.06, r * 0.06) * sc, Vector2(r * 0.36, r * 0.15) * sc), Color("a6f0c0"))
			for k in 6:
				var kx := rc.position.x + r * (0.1 + 0.14 * (k % 3)) * sc
				var ky := rc.position.y + r * (0.32 + 0.14 * (k / 3)) * sc
				UITheme.dot(ci, Vector2(kx, ky), r * 0.045 * sc, Color("ffcf5a") if k == 5 else Color(0.85, 0.88, 1.0))
		"owl":
			var q := p + Vector2(0, sin(t * 2.0) * r * 0.05)
			var brown := Color("a0703a")
			var wing := sin(t * 8.0) * r * 0.08
			for sd in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([q + Vector2(sd * r * 0.2, -r * 0.05) * sc, q + Vector2(sd * (r * 0.42 + wing), r * 0.05) * sc, q + Vector2(sd * r * 0.22, r * 0.2) * sc]), brown.darkened(0.15))
			UITheme.dot(ci, q, r * 0.3 * sc, brown)
			UITheme.dot(ci, q + Vector2(0, r * 0.12) * sc, r * 0.15 * sc, Color("e8d0a8"))
			var blink := fposmod(t, 3.0) > 2.85
			for sd in [-1.0, 1.0]:
				var e := q + Vector2(sd * r * 0.12, -r * 0.07) * sc
				UITheme.dot(ci, e, r * 0.11 * sc, Color.WHITE)
				if blink:
					ci.draw_line(e - Vector2(r * 0.08, 0) * sc, e + Vector2(r * 0.08, 0) * sc, INK, maxf(0.8, r * 0.03), true)
				else:
					UITheme.dot(ci, e, r * 0.055 * sc, INK)
			ci.draw_colored_polygon(PackedVector2Array([q + Vector2(-r * 0.04, r * 0.0) * sc, q + Vector2(r * 0.04, r * 0.0) * sc, q + Vector2(0, r * 0.08) * sc]), Color("ffb84a"))
		"robot":
			var q := p + Vector2(0, sin(t * 4.0) * r * 0.05)
			var rc := Rect2(q.x - r * 0.26 * sc, q.y - r * 0.22 * sc, r * 0.52 * sc, r * 0.44 * sc)
			ci.draw_line(q + Vector2(0, -r * 0.22) * sc, q + Vector2(0, -r * 0.42) * sc, Color("9aa4c8"), maxf(1.0, r * 0.04), true)
			var bl := 0.5 + 0.5 * sin(t * 6.0)
			UITheme.dot(ci, q + Vector2(0, -r * 0.44) * sc, r * 0.06 * sc, Color(1.0, 0.35, 0.4, 0.5 + 0.5 * bl))
			ci.draw_colored_polygon(_round_rect(rc), Color("c8d0e8"))
			ci.draw_rect(Rect2(rc.position + Vector2(r * 0.06, r * 0.08) * sc, Vector2(r * 0.4, r * 0.18) * sc), Color("2a2350"))
			for sd in [-1.0, 1.0]:
				UITheme.dot(ci, q + Vector2(sd * r * 0.1, -r * 0.05) * sc, r * 0.045 * sc, Color("5ad8ff"))
		"dragon":
			# 傳說：小龍，翅膀拍動，偶爾噴一口小火
			var q := p + Vector2(0, sin(t * 3.0) * r * 0.07)
			var dir := -1.0 if cos(t * 1.5) > 0.0 else 1.0
			var green := Color("6ee7a0")
			var flap := sin(t * 9.0)
			for sd in [-1.0, 1.0]:
				var root := q + Vector2(-dir * r * 0.05, -r * 0.1) * sc
				var tip := root + Vector2(-dir * r * (0.3 + 0.05 * sd), -r * (0.32 + 0.14 * flap * sd)) * sc
				ci.draw_colored_polygon(PackedVector2Array([root, tip, root + Vector2(-dir * r * 0.32, r * 0.02) * sc]), Color("b48cff") if sd > 0 else Color("9a72e6"))
			var tail := PackedVector2Array()
			for k in 8:
				var s := k / 7.0
				tail.append(q + Vector2(-dir * r * (0.2 + 0.35 * s), r * (0.1 + 0.12 * sin(s * 3.0 + t * 4.0))) * sc)
			ci.draw_polyline(tail, green.darkened(0.1), maxf(1.0, r * 0.1 * sc), true)
			UITheme.dot(ci, q, r * 0.24 * sc, green)
			UITheme.dot(ci, q + Vector2(dir * r * 0.2, -r * 0.08) * sc, r * 0.15 * sc, green)
			UITheme.dot(ci, q + Vector2(dir * r * 0.25, -r * 0.12) * sc, r * 0.04 * sc, INK)
			for sd in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([q + Vector2(dir * r * 0.12 + sd * r * 0.04, -r * 0.2) * sc, q + Vector2(dir * r * 0.1 + sd * r * 0.06, -r * 0.34) * sc, q + Vector2(dir * r * 0.18 + sd * r * 0.02, -r * 0.2) * sc]), Color("ffcf5a"))
			var fl := fposmod(t * 0.5, 1.0)
			if fl > 0.75:
				var k2 := (fl - 0.75) / 0.25
				for j in 3:
					UITheme.dot(ci, q + Vector2(dir * r * (0.38 + 0.18 * j * k2), -r * 0.08) * sc, r * (0.08 - 0.02 * j) * sc, Color(1.0, 0.55 + 0.15 * j, 0.2, 1.0 - k2))


# ---------------- 小工具 ----------------

static func _star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var a := -PI / 2.0 + k * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, col)


static func _heart(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		var x := 16.0 * pow(sin(a), 3)
		var y := 13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a)
		pts.append(c + Vector2(x, -y) * s / 16.0)
	ci.draw_colored_polygon(pts, col)


static func _flake(ci: CanvasItem, p: Vector2, s: float, rot: float, col: Color) -> void:
	for k in 3:
		var d := Vector2(cos(rot + k * PI / 3.0), sin(rot + k * PI / 3.0)) * s
		ci.draw_line(p - d, p + d, col, maxf(0.8, s * 0.22), true)
	UITheme.dot(ci, p, s * 0.18, col)


static func _note(ci: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	UITheme.dot(ci, p, s * 0.42, col)
	ci.draw_line(p + Vector2(s * 0.38, 0), p + Vector2(s * 0.38, -s * 1.3), col, maxf(1.0, s * 0.14), true)
	ci.draw_line(p + Vector2(s * 0.38, -s * 1.3), p + Vector2(s * 0.85, -s * 1.0), col, maxf(1.0, s * 0.14), true)


static func _petal(ci: CanvasItem, p: Vector2, s: float, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 12:
		var a := TAU * k / 12.0
		pts.append(p + Vector2(cos(a) * s, sin(a) * s * 0.55).rotated(rot))
	ci.draw_colored_polygon(pts, col)


static func _digit(ci: CanvasItem, p: Vector2, s: float, d: String, col: Color) -> void:
	var font: Font = (ci as Control).get_theme_default_font() if ci is Control else ThemeDB.fallback_font
	var fs := int(maxf(7.0, s))
	ci.draw_string(font, p + Vector2(-s, fs * 0.35), d, HORIZONTAL_ALIGNMENT_CENTER, s * 2.0, fs, col)


static func _spark(ci: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.3, 0), p + Vector2(0, s), p + Vector2(-s * 0.3, 0)]), col)
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s, 0), p + Vector2(0, -s * 0.3), p + Vector2(s, 0), p + Vector2(0, s * 0.3)]), col)


static func _round_rect(rc: Rect2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rr := minf(rc.size.x, rc.size.y) * 0.35
	var cs := [rc.position + Vector2(rr, rr), Vector2(rc.end.x - rr, rc.position.y + rr), rc.end - Vector2(rr, rr), Vector2(rc.position.x + rr, rc.end.y - rr)]
	for i in 4:
		for k in 4:
			var a := PI + i * PI / 2.0 + k * (PI / 2.0) / 3.0
			pts.append(cs[i] + Vector2(cos(a), sin(a)) * rr)
	return pts


## 預覽用的小元件：畫一隻穿著 eq 的光靈（衣櫃、扭蛋結果、圖鑑格子）
class Preview extends Control:
	const SL := preload("spirit_look.gd")
	var eq: Dictionary = {}
	var radius := 30.0
	var t := 0.0
	var animate := true
	var silhouette := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		t = randf() * 5.0

	func _process(delta: float) -> void:
		if animate and is_visible_in_tree():
			t += delta
			queue_redraw()

	func _draw() -> void:
		var c := size / 2.0 + Vector2(0, sin(t * 2.4) * radius * 0.06)
		if silhouette:
			UITheme.dot(self, c, radius * 1.4, Color(1, 1, 1, 0.04))
			UITheme.dot(self, c, radius, Color(1, 1, 1, 0.10))
			var font := get_theme_default_font()
			draw_string(font, c + Vector2(-radius, radius * 0.38), "？", HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, int(radius * 1.0), Color(1, 1, 1, 0.35))
			return
		SL.draw_all(self, c, radius, eq, t)
