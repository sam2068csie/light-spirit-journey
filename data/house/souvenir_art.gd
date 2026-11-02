extends RefCounted
## 紀念品：每個單元一件，造型和特效都不一樣。
##   state 0 = 還沒拿到（暗色剪影）、1 = 拿到了（點亮整個單元的聖地）、2 = 全單元 100%（發光＋專屬特效）
## draw(ci, uid, b, s, t, state)：b 是底部中心，s 是高度（約略）
const UITheme := preload("res://data/ui/game_theme.gd")

const INFO := {
	"h1num": {"name": "金色算盤", "col": Color("f5c84c"), "fx": "beads",
		"story": "數之原野的老商人用了一輩子的算盤。據說每顆珠子都記得一個無理數。"},
	"h1exp": {"name": "倍增沙漏", "col": Color("ff9a5a"), "fx": "sand",
		"story": "沙子每往下一層就多一倍。倍增峽谷的守護者用它計算時間。"},
	"h1line": {"name": "光之圓規", "col": Color("5fd4ff"), "fx": "orbit",
		"story": "圓規湖畔撿到的圓規，針腳一轉就能在空中畫出完美的圓。"},
	"h1poly": {"name": "根之果樹", "col": Color("c59bff"), "fx": "fruit",
		"story": "根之洞窟深處長出的小樹，每一顆果實都是方程式的一個根。"},
	"h1seq": {"name": "階梯水晶", "col": Color("6ee7a0"), "fx": "drops",
		"story": "階梯瀑布的水滴凝結成的水晶，每一階都比上一階多一點點。"},
	"h1data": {"name": "星點長條儀", "col": Color("7aa8ff"), "fx": "bars",
		"story": "星點觀測台的小儀器，會把夜空的星星排成長條圖。"},
	"h1comb": {"name": "排列花環", "col": Color("ff8ac8"), "fx": "spin",
		"story": "排列花園的花朵編成的花環，換個順序就是全新的花環。"},
	"h1prob": {"name": "幸運骰塔", "col": Color("fffaf0"), "fx": "hop",
		"story": "骰子市集的攤販送的三顆骰子，疊起來永遠不會倒。"},
	"h1trig": {"name": "直角燈塔", "col": Color("ffd36e"), "fx": "beam",
		"story": "三角燈塔的縮小模型，斜邊、對邊、鄰邊剛好是 5、4、3。"},
	"trig": {"name": "月輪島模型", "col": Color("ff9ad5"), "fx": "moon",
		"story": "圓環島、正弦海岸和羅盤礁，晚上潟湖會倒映月光。"},
	"exp": {"name": "雙島光橋", "col": Color("f5c84c"), "fx": "bridge",
		"story": "指數島和對數島，中間連著一道光之橋。兩座島互為反函數，就像照鏡子。"},
	"vec2": {"name": "向量風向標", "col": Color("5fd4ff"), "fx": "arrows",
		"story": "風向標的兩支箭頭相加，就指向風真正吹來的方向。"},
	"vec3": {"name": "立方水晶", "col": Color("c59bff"), "fx": "cube",
		"story": "三個方向的向量撐起的水晶方塊，從哪個角度看都不一樣。"},
	"plane": {"name": "交錯光面", "col": Color("6ee7a0"), "fx": "seam",
		"story": "兩片光做成的平面交成一條直線，那條線會閃閃發亮。"},
	"prob": {"name": "樹狀圖盆景", "col": Color("ff9a5a"), "fx": "path",
		"story": "每根樹枝上都寫著機率，沿著樹枝走到葉子就能算出答案。"},
	"matrix": {"name": "矩陣魔方", "col": Color("7aa8ff"), "fx": "cells",
		"story": "九格的小魔方，轉一下就是一次線性變換。"},
}


static func info(uid: String) -> Dictionary:
	return INFO.get(uid, {"name": "紀念品", "col": Color("c8d0f0"), "fx": "",
		"story": "點亮這個單元的所有聖地就會出現。"})


static func _p(ci: CanvasItem, pts: Array, c: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array(pts), c)


static func _dot(ci: CanvasItem, p: Vector2, r: float, c: Color) -> void:
	UITheme.dot(ci, p, r, c)


static func _star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 8:
		var a := k * PI / 4.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if k % 2 == 0 else r * 0.35))
	ci.draw_colored_polygon(pts, col)


static func draw(ci: CanvasItem, uid: String, b: Vector2, s: float, t: float, state: int) -> void:
	var inf := info(uid)
	var c: Color = inf.col
	if state == 0:
		c = Color(0.3, 0.26, 0.3, 0.75)   # 剪影：看得出形狀，但沒有顏色
	var m := Color(0.55, 0.45, 0.35) if state > 0 else Color(0.26, 0.22, 0.26, 0.75)   # 底座／木頭
	var full := state == 2
	# 全單元 100%：背後一圈呼吸的光暈
	if full:
		for k in 3:
			_dot(ci, b + Vector2(0, -s * 0.5), s * (0.75 - k * 0.15) * (1.0 + 0.06 * sin(t * 2.5)), Color(c.r, c.g, c.b, 0.12))
	var u := s / 40.0      # 以 40 高為基準的單位
	match uid:
		"h1num":     # 算盤：外框＋三排珠子
			var r := Rect2(b + Vector2(-17, -30) * u, Vector2(34, 28) * u)
			ci.draw_rect(r, m.darkened(0.2), false, 3.0 * u)
			for row in 3:
				var y := r.position.y + (7 + row * 7) * u
				ci.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), m, 1.0)
				for q in 4:
					var off := 0.0
					if full and q == (int(t * 2.0) + row) % 4:
						off = sin(t * 8.0) * 2.0 * u
					_dot(ci, Vector2(r.position.x + (6 + q * 7) * u + off, y), 2.6 * u, c)
		"h1exp":     # 沙漏
			var top := b + Vector2(0, -34 * u)
			ci.draw_rect(Rect2(top + Vector2(-12, -2) * u, Vector2(24, 4) * u), m)
			ci.draw_rect(Rect2(b + Vector2(-12, -3) * u, Vector2(24, 4) * u), m)
			_p(ci, [top + Vector2(-10, 2) * u, top + Vector2(10, 2) * u, top + Vector2(1.5, 16) * u, top + Vector2(-1.5, 16) * u], Color(c.r, c.g, c.b, 0.35))
			_p(ci, [b + Vector2(-10, -3) * u, b + Vector2(10, -3) * u, top + Vector2(1.5, 16) * u, top + Vector2(-1.5, 16) * u], Color(c.r, c.g, c.b, 0.35))
			_p(ci, [b + Vector2(-9, -3) * u, b + Vector2(9, -3) * u, b + Vector2(0, -12) * u], c)
			_p(ci, [top + Vector2(-6, 7) * u, top + Vector2(6, 7) * u, top + Vector2(0, 14) * u], c)
			if full:
				for k in 5:
					var f := fmod(t * 1.2 + k * 0.2, 1.0)
					_dot(ci, top + Vector2(0, (14 + f * 14) * u), 1.2 * u, c.lightened(0.4))
		"h1line":    # 圓規＋畫好的圓弧
			var hinge := b + Vector2(0, -34 * u)
			ci.draw_arc(b + Vector2(0, -8 * u), 13 * u, PI * 1.05, PI * 1.95, 20, Color(c.r, c.g, c.b, 0.5), 2.0 * u, true)
			ci.draw_line(hinge, b + Vector2(-11, -2) * u, c, 3.0 * u, true)
			ci.draw_line(hinge, b + Vector2(11, -2) * u, c, 3.0 * u, true)
			_dot(ci, hinge, 3.5 * u, m)
			if full:
				var a := t * 2.0
				ci.draw_arc(b + Vector2(0, -18 * u), 20 * u, a, a + 4.0, 24, Color(c.r, c.g, c.b, 0.8), 2.0 * u, true)
				_star(ci, b + Vector2(0, -18 * u) + Vector2(cos(a + 4.0), sin(a + 4.0)) * 20 * u, 4 * u, Color.WHITE)
		"h1poly":    # 小果樹
			ci.draw_rect(Rect2(b + Vector2(-8, -7) * u, Vector2(16, 7) * u), m)
			ci.draw_line(b + Vector2(0, -7 * u), b + Vector2(0, -22 * u), m.darkened(0.2), 3.0 * u)
			_dot(ci, b + Vector2(0, -27 * u), 12 * u, Color(0.3, 0.6, 0.4) if state > 0 else c)
			for k in 3:
				var fp := b + Vector2(-7 + k * 7, -30 + (k % 2) * 7) * u
				var rr := 3.0 * u * (1.0 + (0.3 * sin(t * 3.0 + k * 2.0) if full else 0.0))
				if full:
					_dot(ci, fp, rr * 2.2, Color(c.r, c.g, c.b, 0.25))
				_dot(ci, fp, rr, c)
		"h1seq":     # 階梯水晶
			for k in 4:
				var h := (8 + k * 7) * u
				var x := (-16 + k * 8) * u
				_p(ci, [b + Vector2(x, 0), b + Vector2(x + 8 * u, 0), b + Vector2(x + 8 * u, -h), b + Vector2(x + 4 * u, -h - 5 * u), b + Vector2(x, -h)], c.darkened(0.08 * (3 - k)))
			if full:
				var f := fmod(t * 0.8, 1.0)
				var k2 := int(f * 4.0)
				var hx := (-12 + k2 * 8) * u
				var hy := -(8 + k2 * 7) * u - 7 * u - sin(fmod(f * 4.0, 1.0) * PI) * 6 * u
				_dot(ci, b + Vector2(hx, hy), 2.4 * u, Color(0.8, 1, 1))
		"h1data":    # 長條圖
			ci.draw_rect(Rect2(b + Vector2(-16, -3) * u, Vector2(32, 3) * u), m)
			var hs := [12.0, 22.0, 30.0, 17.0]
			for k in 4:
				var h: float = hs[k]
				if full:
					h *= 0.8 + 0.25 * (0.5 + 0.5 * sin(t * 3.0 + k * 1.3))
				ci.draw_rect(Rect2(b + Vector2(-14 + k * 7.5, -3 - h) * u, Vector2(5.5, h) * u), c.darkened(0.1 * (k % 2)))
		"h1comb":    # 花環
			var cc := b + Vector2(0, -18 * u)
			ci.draw_arc(cc, 12 * u, 0, TAU, 28, Color(0.3, 0.6, 0.4) if state > 0 else c, 3.0 * u, true)
			var cols := [Color("ff8ac8"), Color("ffd36e"), Color("5fd4ff"), Color("c59bff"), Color("6ee7a0"), Color("ff9a5a")]
			var rot := t * 0.8 if full else 0.0
			for k in 6:
				var a := rot + k * TAU / 6.0
				_dot(ci, cc + Vector2(cos(a), sin(a)) * 12 * u, 3.6 * u, cols[k] if state > 0 else c)
		"h1prob":    # 三顆疊起來的骰子
			var ds := 10.0 * u
			var pos := [b + Vector2(-ds - 1, -ds), b + Vector2(1, -ds), b + Vector2(-ds * 0.5, -ds * 2 - 1)]
			for k in 3:
				var p: Vector2 = pos[k]
				if full and k == 2:
					p.y -= absf(sin(t * 4.0)) * 5 * u
				ci.draw_rect(Rect2(p, Vector2(ds, ds)), c)
				ci.draw_rect(Rect2(p, Vector2(ds, ds)), Color(0.5, 0.4, 0.3) if state > 0 else c, false, 1.0)
				if state > 0:
					_dot(ci, p + Vector2(ds, ds) * 0.5, 1.3 * u, Color("c0392b") if k == 2 else Color("2a2440"))
		"h1trig":    # 直角三角形燈塔
			_p(ci, [b + Vector2(-12, 0) * u, b + Vector2(12, 0) * u, b + Vector2(-12, -32) * u], c.darkened(0.15))
			ci.draw_rect(Rect2(b + Vector2(-12, -6) * u, Vector2(6, 6) * u), Color(1, 1, 1, 0.5) if state > 0 else c, false, 1.0)
			_dot(ci, b + Vector2(-12, -34) * u, 3.5 * u, Color("fff3c4") if state > 0 else c)
			if full:
				var a := -PI * 0.5 + sin(t * 1.5) * 0.9
				var o := b + Vector2(-12, -34) * u
				_p(ci, [o, o + Vector2(cos(a - 0.15), sin(a - 0.15)) * 26 * u, o + Vector2(cos(a + 0.15), sin(a + 0.15)) * 26 * u], Color(1, 0.95, 0.6, 0.45))
		"trig":      # 月輪島：圓環＋月亮
			var cc := b + Vector2(0, -16 * u)
			ci.draw_rect(Rect2(b + Vector2(-16, -4) * u, Vector2(32, 4) * u), m)
			ci.draw_arc(cc, 11 * u, 0, TAU, 28, c, 4.0 * u, true)
			var ma := t * 1.5 if full else -0.8
			var mp := cc + Vector2(cos(ma), sin(ma)) * 17 * u
			_dot(ci, mp, 4 * u, Color("fff3d6") if state > 0 else c)
			if full:
				var pts := PackedVector2Array()
				for k in 17:
					var x := -16.0 + k * 2.0
					pts.append(b + Vector2(x, -2 + sin(x * 0.4 + t * 4.0) * 1.5) * u)
				ci.draw_polyline(pts, Color(0.6, 0.9, 1.0, 0.8), 1.5 * u, true)
		"exp":       # 兩座島＋光橋
			_p(ci, [b + Vector2(-20, 0) * u, b + Vector2(-6, 0) * u, b + Vector2(-10, -12) * u, b + Vector2(-17, -10) * u], Color(0.4, 0.65, 0.45) if state > 0 else c)
			_p(ci, [b + Vector2(6, 0) * u, b + Vector2(20, 0) * u, b + Vector2(17, -10) * u, b + Vector2(10, -12) * u], Color(0.4, 0.65, 0.45) if state > 0 else c)
			var pts := PackedVector2Array()
			for k in 13:
				var x := -10.0 + k * 20.0 / 12.0
				pts.append(b + Vector2(x, -12 - 14 * sin(PI * k / 12.0)) * u)
			ci.draw_polyline(pts, c, 2.5 * u, true)
			if full:
				var f := fmod(t * 0.6, 1.0)
				var k := int(f * 12.0)
				_star(ci, pts[k].lerp(pts[mini(k + 1, 12)], fmod(f * 12.0, 1.0)), 4 * u, Color.WHITE)
		"vec2":      # 風向標：兩支箭頭＋合成
			var o := b + Vector2(0, -6 * u)
			ci.draw_line(b, o, m, 2.0 * u)
			var ang := sin(t * 1.2) * 0.4 if full else 0.0
			var v1 := Vector2(18, -6).rotated(ang) * u
			var v2 := Vector2(-4, -20).rotated(ang) * u
			for v in [v1, v2]:
				ci.draw_line(o, o + v, c.darkened(0.25), 2.0 * u, true)
			ci.draw_line(o, o + v1 + v2, c, 3.0 * u, true)
			var tip: Vector2 = o + v1 + v2
			var dirv: Vector2 = (v1 + v2).normalized()
			_p(ci, [tip + dirv * 4 * u, tip - dirv * 3 * u + dirv.orthogonal() * 4 * u, tip - dirv * 3 * u - dirv.orthogonal() * 4 * u], c)
			if full:
				ci.draw_dashed_line(o + v1, tip, Color(1, 1, 1, 0.5), 1.0, 3.0)
				ci.draw_dashed_line(o + v2, tip, Color(1, 1, 1, 0.5), 1.0, 3.0)
		"vec3":      # 線框立方體（100% 會轉）
			var cc := b + Vector2(0, -18 * u)
			var ry := t * 0.8 if full else 0.6
			var vs := []
			for k in 8:
				var p := Vector3(-1 if k & 1 else 1, -1 if k & 2 else 1, -1 if k & 4 else 1)
				var x := p.x * cos(ry) - p.z * sin(ry)
				var z := p.x * sin(ry) + p.z * cos(ry)
				vs.append(cc + Vector2(x * 10 + z * 2, p.y * 10 - z * 3) * u)
			var edges := [[0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [0, 4], [1, 5], [2, 6], [3, 7]]
			_p(ci, [vs[0], vs[1], vs[3], vs[2]], Color(c.r, c.g, c.b, 0.25))
			for e in edges:
				ci.draw_line(vs[e[0]], vs[e[1]], c, 1.6 * u, true)
		"plane":     # 兩片交錯的平面
			_p(ci, [b + Vector2(-18, -6) * u, b + Vector2(6, -2) * u, b + Vector2(18, -26) * u, b + Vector2(-6, -30) * u], Color(c.r, c.g, c.b, 0.55))
			_p(ci, [b + Vector2(-16, -24) * u, b + Vector2(16, -24) * u, b + Vector2(16, -8) * u, b + Vector2(-16, -8) * u], Color(0.5, 0.75, 1.0, 0.45) if state > 0 else c)
			var l0 := b + Vector2(-9, -16) * u
			var l1 := b + Vector2(9, -16) * u
			ci.draw_line(l0, l1, Color.WHITE if state > 0 else c, 2.0 * u)
			if full:
				var f := 0.5 + 0.5 * sin(t * 3.0)
				_star(ci, l0.lerp(l1, f), 4 * u, Color.WHITE)
		"prob":      # 樹狀圖盆景
			ci.draw_rect(Rect2(b + Vector2(-8, -6) * u, Vector2(16, 6) * u), Color("c97b5a") if state > 0 else c)
			var root := b + Vector2(0, -6 * u)
			var n1 := [root + Vector2(-9, -12) * u, root + Vector2(9, -12) * u]
			var leaves := [n1[0] + Vector2(-5, -12) * u, n1[0] + Vector2(5, -12) * u, n1[1] + Vector2(-5, -12) * u, n1[1] + Vector2(5, -12) * u]
			var lit := int(t * 1.5) % 4 if full else -1
			for k in 2:
				ci.draw_line(root, n1[k], c if lit >= 0 and lit / 2 == k else m, 2.0 * u, true)
			for k in 4:
				var on := k == lit
				ci.draw_line(n1[k / 2], leaves[k], c if on else m, 1.6 * u, true)
				_dot(ci, leaves[k], (3.5 if on else 2.5) * u, c if (on or state > 0) else c)
		"matrix":    # 3×3 魔方
			var o := b + Vector2(-15, -32) * u
			for q in 9:
				var x := q % 3
				var y := q / 3
				var cc := c.darkened(0.15 * ((x + y) % 2))
				if full and q == int(t * 3.0) % 9:
					cc = Color.WHITE
				ci.draw_rect(Rect2(o + Vector2(x * 10 + 0.5, y * 10 + 0.5) * u, Vector2(9, 9) * u), cc)
		_:
			_p(ci, [b + Vector2(-10, 0) * u, b + Vector2(10, 0) * u, b + Vector2(7, -30) * u, b + Vector2(-7, -30) * u], c)
	# 全單元 100%：飄出幾顆閃光
	if full:
		for k in 4:
			var f := fmod(t * 0.5 + k * 0.25, 1.0)
			var p := b + Vector2(sin(k * 2.3 + t) * 16, -6 - f * 40) * u
			_star(ci, p, (2.0 + 1.5 * sin(t * 5.0 + k)) * u, Color(1, 1, 1, 0.9 * (1.0 - f)))
