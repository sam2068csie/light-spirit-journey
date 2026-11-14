extends Control
## 數與式的「原野」：推導紀錄下方的小舞台（R1 起共用）。題目的 "field" 是元件的清單，由左到右排：
##   mill    風車：{"k": "mill", "int": "1", "pre": "2", "rep": "36", "lit": 1, "spin": 2, "hl": [第幾步, 第幾片], "w": 1}
##           扇葉片數 = 循環節的位數，每片寫一個數字。不循環的部分（1.2）寫在柱子上。
##           做完 lit 步扇葉亮起來，做完 spin 步開始轉，旁邊流出 1.2363636…，下面寫出 1.2\ol{36}。
##           hl：轉幾圈之後停下來，那一片扇葉亮起（第 n 位）。
##   nline   數線：{"k": "nline", "x": [左, 右], "pts": [{v, s, at, lit, c, to, to_at, below}], "zoom": [[左, 右, 第幾步], …],
##                  "segs": [[從, 到, 第幾步, 顏色], …], "noticks": true（不寫刻度，免得洩漏答案）, "zero": true（只標 0）}
##           點在第 at 步出現，第 lit 步亮起燈柱（照大小由左到右一根一根亮），to：第 to_at 步滑到 to。
##           R2 起：
##             rope    {"a": 左柱, "b": 右柱, "ext": [[延伸到, 第幾步], …]}：兩根柱子之間的繩子，外分點在外面時繩子拉長過去
##             點加 "bead": true → 畫成穿在繩上的珠子，"slide": "t" → 位置跟著滑桿 t 走，"wrong": [第幾步, 錯的位置] → 那一步答錯時閃一顆紅珠子
##             weights {"at": 第幾步, "a": [位置, 個數], "b": [位置, 個數]}：柱子上疊砝碼（權重）
##             run     {"a": 起點, "b": 起點, "meet": 會合點, "at": 第幾步, "s": ["A", "B"]}：兩個光點往會合點跑（同時到）
##             road    {"pin": {"A": 1, "C": 5}, "cases": [{"at": 第幾步, "km": {"A": 0, "B": 6, "C": 8}, "show": {"B": 第幾步}}, …]}
##                     數線上方畫真的路（風車和公里數），風車對齊它在數線上的位置，虛線連下來
##   blocks  質因數積木：{"k": "blocks", "num": ["3", "7"]（或 [[第幾步, [...]], …] 換分子）, "den": [...],
##                        "cancel": [第幾步, [[分子第幾塊, 分母第幾塊], …]], "judge": [第幾步, 有限小數？]}
##           約掉的積木掉下去。判斷那一步做完：有限小數 → 旁邊的小風車停下、燈亮，循環小數 → 小風車一直轉。
## 「第幾步」都是「做完第幾步之後」（0 = 一開始就有）。答錯時（view.miss_t）元件會晃一下、閃紅。
## 圖上不寫中文：只有數字、字母。

const UITheme := preload("res://data/ui/game_theme.gd")
const MathLabel := preload("res://data/ui/math_text.gd")

const COLS := {"gold": Color(1.0, 0.82, 0.38), "cyan": Color(0.45, 0.85, 1.0), "bad": Color(1.0, 0.45, 0.45),
	"dim": Color(0.7, 0.72, 0.85), "lime": Color(0.7, 0.95, 0.45)}
const PRIME_C := {"2": Color("5fc8ff"), "5": Color("9be36a"), "3": Color("ffa65a"), "7": Color("ff8ac8"),
	"11": Color("c59bff"), "13": Color("6ee7c0")}

var items: Array = []
var view: Object = null          # 推導台（ForgeView）：讀 step、done、miss_t、t
var _st := {}                    # 每個元件的動畫狀態（開始轉的時間、目前的角度、數線的範圍…）


func reset(list: Array, v: Object) -> void:
	items = list
	view = v
	_st = {}
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _step() -> int:
	if view == null:
		return 0
	if bool(view.get("done")):
		return 99
	return int(view.get("step"))


func _t() -> float:
	return float(view.get("t")) if view != null else 0.0


## 答錯之後的 0.6 秒：0～1（1 = 剛答錯）
func _miss() -> float:
	if view == null:
		return 0.0
	return clampf(1.0 - (_t() - float(view.get("miss_t"))) / 0.6, 0.0, 1.0)


func _process(_d: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if items.is_empty():
		return
	var bg := Rect2(Vector2.ZERO, size)
	draw_rect(bg, Color(0.05, 0.05, 0.1, 0.55))
	var m := _miss()
	if m > 0.0:
		draw_rect(bg, Color(1, 0.25, 0.3, 0.12 * m))
	draw_rect(bg, Color(1, 0.9, 0.6, 0.14), false, 1.0)
	var total := 0.0
	for it in items:
		total += float(it.get("w", 1.0))
	var x := 0.0
	for i in items.size():
		var it: Dictionary = items[i]
		var w := size.x * float(it.get("w", 1.0)) / total
		var r := Rect2(x, 0, w, size.y).grow(-8)
		match String(it.k):
			"mill":
				_draw_mill(i, it, r)
			"nline":
				_draw_nline(i, it, r)
			"blocks":
				_draw_blocks(i, it, r)
		x += w


# ================= 風車 =================

func _draw_mill(i: int, it: Dictionary, r: Rect2) -> void:
	var font := get_theme_default_font()
	var st := _step()
	var t := _t()
	var s: Dictionary = _st.get(i, {"spin_t": -1.0, "ang": 0.0, "last": t, "hl_t": -1.0, "hl_a0": 0.0})
	var rep := String(it.rep)
	var n := maxi(1, rep.length())
	var lit := st >= int(it.get("lit", 0))
	var spin := st >= int(it.get("spin", 99))
	var hl: Array = it.get("hl", [])
	var hl_on := not hl.is_empty() and st >= int(hl[0])
	var dt := clampf(t - float(s.last), 0.0, 0.1)
	s.last = t
	if spin and float(s.spin_t) < 0.0:
		s.spin_t = t
	var ang: float = s.ang
	if hl_on:
		# 停在第 hl[1] 片扇葉朝上：先多轉兩圈再慢慢停
		if float(s.hl_t) < 0.0:
			s.hl_t = t
			s.hl_a0 = ang
		var target := -TAU * int(hl[1]) / n
		var a0: float = s.hl_a0
		var goal := a0 + fposmod(target - a0, TAU) + TAU
		var u := clampf((t - float(s.hl_t)) / 1.4, 0.0, 1.0)
		ang = lerpf(a0, goal, 1.0 - pow(1.0 - u, 3.0))
	elif spin:
		ang += dt * 2.6
	s.ang = ang
	_st[i] = s
	var wob := 0.25 * sin(t * 30.0) * _miss()
	# 位置：風車在左邊，右邊是流出來的小數。扇葉不能碰到柱子上的牌子
	var hub := Vector2(r.position.x + minf(r.size.x * 0.28, 92.0), r.position.y + r.size.y * 0.4)
	var ground := r.end.y - 12.0
	var plate_top := ground - 30.0
	var L := minf(minf(r.size.y * 0.34, plate_top - hub.y - 6.0), 64.0)
	draw_line(Vector2(r.position.x, ground), Vector2(r.end.x, ground), Color(1, 0.9, 0.6, 0.18), 2.0)
	# 柱子（木頭塔身）＋牌子（不循環的部分）
	var body := Color("4a3f5e").lerp(Color("7a5a3a"), 0.6 if lit else 0.0)
	draw_colored_polygon(PackedVector2Array([Vector2(hub.x - 15, ground), Vector2(hub.x + 15, ground), Vector2(hub.x + 6, hub.y), Vector2(hub.x - 6, hub.y)]), body)
	draw_colored_polygon(PackedVector2Array([Vector2(hub.x - 9, hub.y + 4), Vector2(hub.x + 9, hub.y + 4), Vector2(hub.x, hub.y - 10)]), body.lightened(0.15))
	var head := String(it.get("int", "0")) + "." + String(it.get("pre", ""))
	var fs := UITheme.fs(15)
	var hw := font.get_string_size(head, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var plate := Rect2(hub.x - hw / 2.0 - 6, plate_top, hw + 12, 22)
	draw_rect(plate, Color(0.12, 0.1, 0.16, 0.95))
	draw_rect(plate, Color(1, 0.86, 0.5, 0.5), false, 1.0)
	draw_string(font, Vector2(plate.position.x + 6, plate.end.y - 6), head, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.92, 0.75))
	# 扇葉：木頭的臂＋偏一邊的帆布，帆布上寫一個數字（字保持正的）
	var sail := Color(0.5, 0.5, 0.62, 0.75).lerp(Color(1.0, 0.9, 0.62, 0.92), 1.0 if lit else 0.0)
	if _miss() > 0.0:
		sail = sail.lerp(Color(1, 0.45, 0.45, 0.9), _miss())
	var arm := Color("8a7058") if lit else Color("5a5070")
	var sw := 17.0
	for k in n:
		var a := -PI / 2.0 + TAU * k / n + ang + wob
		var d := Vector2(cos(a), sin(a))
		var nm := Vector2(-d.y, d.x)
		var hi := hl_on and k == int(hl[1]) and float(t - float(s.hl_t)) > 1.4
		var c := Color(1.0, 0.95, 0.7) if hi else sail
		var p0 := hub + d * L * 0.22
		var p1 := hub + d * L
		var quad := PackedVector2Array([p0, p1, p1 + nm * sw, p0 + nm * sw * 0.7])
		if hi:
			UITheme.dot(self, hub + d * L * 0.64 + nm * sw * 0.45, 24.0, Color(1, 0.85, 0.4, 0.28))
		draw_colored_polygon(quad, c)
		for q in [0.45, 0.72]:
			draw_line(hub + d * L * q, hub + d * L * q + nm * sw * (0.7 + 0.3 * q), Color(0.3, 0.22, 0.18, 0.35), 1.0)
		draw_line(hub, p1, arm, 3.0, true)
		var ch := rep.substr(k, 1)
		var dfs := UITheme.fs(16)
		var cw := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, dfs)
		var cp := hub + d * L * 0.64 + nm * sw * 0.45
		var tp := cp + Vector2(-cw.x / 2.0, cw.y * 0.32)
		draw_string_outline(font, tp, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, dfs, 4, Color(0.1, 0.07, 0.1, 0.9))
		draw_string(font, tp, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, dfs, Color(1, 1, 1) if lit or hi else Color(1, 1, 1, 0.8))
	UITheme.dot(self, hub, 5.5, Color(0.9, 0.85, 0.75))
	# 右邊：轉起來之後，小數一位一位流出來，下面寫出循環小數的記號
	var sx := hub.x + L + 26.0
	if sx > r.end.x - 50.0:
		return
	var y := r.position.y + r.size.y * 0.36
	var sfs := UITheme.fs(20)
	if spin:
		var u2 := t - float(s.spin_t)
		var shown := int(u2 * 6.0)
		var dw := font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, sfs).x
		var room := maxi(1, int((r.end.x - sx - 16.0) / dw) - head.length() - 1)
		var tail := ""
		var k2 := 0
		while tail.length() < mini(shown, room):
			tail += rep.substr(k2 % n, 1)
			k2 += 1
		var txt := head + tail + ("…" if tail.length() >= room else "")
		draw_string(font, Vector2(sx, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, Color(1, 0.92, 0.7))
		if u2 > 1.4:
			var al := clampf((u2 - 1.4) / 0.5, 0.0, 1.0)
			var mark := "= " + head + "\\ol{" + rep + "}"
			var mfs := UITheme.fs(24)
			var mw := MathLabel.text_width(font, mark, mfs)
			if mw > r.end.x - sx - 8.0:
				mfs = int(maxf(14.0, mfs * (r.end.x - sx - 8.0) / mw))
				mw = MathLabel.text_width(font, mark, mfs)
			MathLabel.draw_on(self, font, sx + mw / 2.0, y + 46.0, mark, mfs, Color(1, 0.86, 0.45, al))
	else:
		draw_string(font, Vector2(sx, y), head + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, Color(1, 1, 1, 0.3))


# ================= 數線 =================

func _draw_nline(i: int, it: Dictionary, r: Rect2) -> void:
	var font := get_theme_default_font()
	var st := _step()
	var t := _t()
	var s: Dictionary = _st.get(i, {"lo": float(it.x[0]), "hi": float(it.x[1]), "last": t, "lit_t": {}, "mv_t": {}})
	# 目前要的範圍：做完的步驟裡最後一個 zoom
	var want := [float(it.x[0]), float(it.x[1])]
	for z in it.get("zoom", []):
		if st >= int(z[2]):
			want = [float(z[0]), float(z[1])]
	var dt := clampf(t - float(s.last), 0.0, 0.1)
	s.last = t
	var kz := 1.0 - exp(-5.0 * dt)
	s.lo = lerpf(float(s.lo), want[0], kz)
	s.hi = lerpf(float(s.hi), want[1], kz)
	_st[i] = s
	var lo: float = s.lo
	var hi: float = s.hi
	var y := r.position.y + r.size.y * (0.84 if it.has("road") else 0.64)
	var x0 := r.position.x + 18.0
	var x1 := r.end.x - 22.0
	var sx := func(v: float) -> float:
		return x0 + (v - lo) / (hi - lo) * (x1 - x0)
	var shake := 4.0 * sin(t * 40.0) * _miss()
	# 亮起來的區段
	for sg in it.get("segs", []):
		if st < int(sg[2]):
			continue
		var c: Color = COLS.get(String(sg[3]), COLS.cyan)
		var a := clampf(sx.call(float(sg[0])), x0, x1)
		var b := clampf(sx.call(float(sg[1])), x0, x1)
		draw_rect(Rect2(a, y - 7, b - a, 14), Color(c.r, c.g, c.b, 0.22))
		draw_line(Vector2(a, y - 12), Vector2(a, y + 12), c, 2.0)
		draw_line(Vector2(b, y - 12), Vector2(b, y + 12), c, 2.0)
	# 數線本身＋箭頭
	draw_line(Vector2(x0 - 8, y), Vector2(x1 + 6, y), Color(1, 0.95, 0.85, 0.75), 2.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(x1 + 14, y), Vector2(x1 + 4, y - 6), Vector2(x1 + 4, y + 6)]), Color(1, 0.95, 0.85, 0.75))
	# 刻度
	if not bool(it.get("noticks", false)):
		var stp := _nice_step((hi - lo) / 6.0)
		var v := ceilf(lo / stp) * stp
		var guard := 0
		while v <= hi + 1e-9 and guard < 40:
			guard += 1
			var px: float = sx.call(v)
			if px >= x0 - 1.0 and px <= x1 + 1.0:
				draw_line(Vector2(px, y - 6), Vector2(px, y + 6), Color(1, 0.95, 0.85, 0.5), 1.5)
				var lab := _fmt(v, stp)
				var w := font.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13)).x
				draw_string(font, Vector2(px - w / 2.0, y + 22), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(13), Color(1, 0.95, 0.85, 0.5))
			v += stp
	if bool(it.get("zero", false)) and lo < 0.0 and hi > 0.0:
		var pz: float = sx.call(0.0)
		draw_line(Vector2(pz, y - 9), Vector2(pz, y + 9), Color(1, 1, 1, 0.8), 2.0)
		draw_string(font, Vector2(pz - 4, y + 24), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14), Color(1, 1, 1, 0.8))
	if it.has("road"):
		_draw_road(it.road, sx, y, r, st)
	var rope_y := y - 26.0
	if it.has("rope"):
		_draw_rope(i, it.rope, sx, y, rope_y, st, t)
	if it.has("weights") and st >= int(it.weights.get("at", 0)):
		_draw_weights(it.weights, sx, rope_y, t - float(s.get("w_t", t)))
		if not s.has("w_t"):
			s["w_t"] = t
	if it.has("run"):
		_draw_runners(i, it.run, sx, y, st, t)
	# 點：照大小排名（燈柱由左到右一根一根亮）
	var pts: Array = it.get("pts", [])
	var order := []
	for k in pts.size():
		order.append(k)
	order.sort_custom(func(a, b): return float(pts[a].v) < float(pts[b].v))
	var rank := {}
	for k in order.size():
		rank[order[k]] = k
	var lit_t: Dictionary = s.lit_t
	var mv_t: Dictionary = s.mv_t
	var shown := 0
	for k in pts.size():
		var p: Dictionary = pts[k]
		if st < int(p.get("at", 0)):
			continue
		var v: float = float(p.v)
		if p.has("slide"):
			v = _slide_val(String(p.slide), v)
		if p.has("wrong") and st == int(p.wrong[0]) and _miss() > 0.0:
			var wx: float = sx.call(float(p.wrong[1]))
			UITheme.dot(self, Vector2(wx, rope_y), 16.0, Color(1, 0.3, 0.3, 0.25 * _miss()))
			UITheme.dot(self, Vector2(wx, rope_y), 7.0, Color(1, 0.4, 0.4, _miss()))
		if p.has("to") and st >= int(p.get("to_at", 99)):
			if not mv_t.has(k):
				mv_t[k] = t
			var u := clampf((t - float(mv_t[k])) / 0.9, 0.0, 1.0)
			v = lerpf(v, float(p.to), 1.0 - pow(1.0 - u, 3.0))
		var px: float = sx.call(v) + shake
		if px < x0 - 4.0 or px > x1 + 4.0:
			continue
		var c: Color = COLS.get(String(p.get("c", "gold")), COLS.gold)
		var lit := int(p.get("lit", -1)) >= 0 and st >= int(p.get("lit", -1))
		var glow := 0.0
		if lit:
			if not lit_t.has(k):
				lit_t[k] = t + 0.28 * int(rank[k])
			glow = clampf((t - float(lit_t[k])) / 0.5, 0.0, 1.0)
		if bool(p.get("bead", false)):
			_draw_bead(Vector2(px, rope_y), c, glow, String(p.get("s", "")), font)
			continue
		# 燈柱：亮起來時從數線上長出來
		var hpost := 26.0 * glow
		if glow > 0.0:
			draw_line(Vector2(px, y), Vector2(px, y - hpost), c.darkened(0.2), 3.0)
			UITheme.dot(self, Vector2(px, y - hpost), 14.0 * glow, Color(c.r, c.g, c.b, 0.22 * glow))
			UITheme.dot(self, Vector2(px, y - hpost), 4.0, c.lightened(0.3))
		UITheme.dot(self, Vector2(px, y), 5.0, c if glow > 0.0 or int(p.get("lit", -1)) < 0 else c.darkened(0.35))
		var lab := String(p.get("s", ""))
		if lab != "":
			var below := bool(p.get("below", false))
			var ly := y + 30.0 if below else y - hpost - 14.0 - 16.0 * float(rank[k] % 2 if pts.size() > 2 and not bool(it.get("flat", false)) else 0)
			MathLabel.draw_on(self, font, px, ly, lab, UITheme.fs(16), c.lightened(0.2) if glow > 0.0 else Color(1, 1, 1, 0.85))
		shown += 1
	s.lit_t = lit_t
	s.mv_t = mv_t


## 滑桿的值（line_level 的 slide 步驟寫在 plane.dyn_vals）
func _slide_val(name: String, dflt: float) -> float:
	if view == null:
		return dflt
	var pl = view.get("plane")
	if pl == null:
		return dflt
	var dv = pl.get("dyn_vals")
	if dv is Dictionary and dv.has(name):
		return float(dv[name])
	return dflt


func _draw_bead(p: Vector2, c: Color, glow: float, lab: String, font: Font) -> void:
	if glow > 0.0:
		UITheme.dot(self, p, 18.0 * glow, Color(c.r, c.g, c.b, 0.25 * glow))
	UITheme.dot(self, p, 8.0, c.darkened(0.25))
	UITheme.dot(self, p, 6.0, c)
	UITheme.dot(self, p + Vector2(-2, -2), 2.2, Color(1, 1, 1, 0.8))
	if lab != "":
		MathLabel.draw_on(self, font, p.x, p.y - 18.0, lab, UITheme.fs(16), c.lightened(0.25))


## 繩子：兩根柱子＋中間微微下垂的繩，答對外分點後往外拉長（0.8 秒長出去）
func _draw_rope(i: int, rp: Dictionary, sx: Callable, y: float, ry: float, st: int, t: float) -> void:
	var s: Dictionary = _st[i]
	var ext_t: Dictionary = s.get("ext_t", {})
	var lo_v := minf(float(rp.a), float(rp.b))
	var hi_v := maxf(float(rp.a), float(rp.b))
	var ex := [lo_v, hi_v]
	for k in rp.get("ext", []).size():
		var e: Array = rp.ext[k]
		if st < int(e[1]):
			continue
		if not ext_t.has(k):
			ext_t[k] = t
		var u := clampf((t - float(ext_t[k])) / 0.8, 0.0, 1.0)
		var to := float(e[0])
		if to > hi_v:
			ex[1] = maxf(ex[1], lerpf(hi_v, to, u))
		elif to < lo_v:
			ex[0] = minf(ex[0], lerpf(lo_v, to, u))
	s["ext_t"] = ext_t
	var rope_c := Color(0.95, 0.8, 0.55, 0.85)
	var pts := PackedVector2Array()
	var xa: float = sx.call(ex[0])
	var xb: float = sx.call(ex[1])
	for k in 25:
		var u := k / 24.0
		pts.append(Vector2(lerpf(xa, xb, u), ry + 3.0 * sin(PI * u)))
	draw_polyline(pts, rope_c, 2.0, true)
	var names: Array = rp.get("s", [])
	var ends := [float(rp.a), float(rp.b)]
	for k in 2:
		var px: float = sx.call(ends[k])
		draw_line(Vector2(px, y), Vector2(px, ry - 10.0), Color("8a6a48"), 4.0)
		UITheme.dot(self, Vector2(px, ry - 10.0), 3.0, Color("b08a60"))
		if k < names.size():
			# 柱子的名字寫在柱子頂端的外側（左邊那根寫左邊、右邊那根寫右邊），不擋繩上的珠子
			var side := -1.0 if ends[k] <= ends[1 - k] else 1.0
			MathLabel.draw_on(self, get_theme_default_font(), px + side * 13.0, ry - 14.0, String(names[k]), UITheme.fs(16), Color(1, 0.92, 0.75))


## 砝碼：疊在柱子頂端，個數 = 權重（靠近誰，誰的權重大）
func _draw_weights(w: Dictionary, sx: Callable, ry: float, age: float) -> void:
	var font := get_theme_default_font()
	var g := clampf(age / 0.6, 0.0, 1.0)
	for key in ["a", "b"]:
		if not w.has(key):
			continue
		var px: float = sx.call(float(w[key][0]))
		var n := int(w[key][1])
		for k in n:
			var rc := Rect2(px - 9, ry - 22.0 - 13.0 * k - 8.0 * (1.0 - g), 18, 11)
			draw_rect(rc, Color(0.75, 0.7, 0.9, 0.85 * g))
			draw_rect(rc, Color(1, 1, 1, 0.6 * g), false, 1.0)
		# 個數寫在內側（朝另一根柱子），外側留給柱子的名字
		var other: float = sx.call(float(w["b" if key == "a" else "a"][0])) if w.has("b" if key == "a" else "a") else px + 1.0
		var lab := str(n)
		var lw := font.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14)).x
		var lx := px + 12.0 if other > px else px - 12.0 - lw
		draw_string(font, Vector2(lx, ry - 14.0 - 13.0 * (n - 1)), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14), Color(1, 1, 1, g))


## 兩個光點往右跑：第 at 步之前停在起點，之後 2.4 秒內同時跑到會合點
func _draw_runners(i: int, rn: Dictionary, sx: Callable, y: float, st: int, t: float) -> void:
	var font := get_theme_default_font()
	var s: Dictionary = _st[i]
	var u := 0.0
	if st >= int(rn.get("at", 99)):
		if not s.has("run_t"):
			s["run_t"] = t
		u = clampf((t - float(s.run_t)) / 2.4, 0.0, 1.0)
	var meet := float(rn.meet)
	var names: Array = rn.get("s", ["A", "B"])
	var cols := [COLS.cyan, COLS.gold]
	for k in 2:
		var v0 := float(rn.a) if k == 0 else float(rn.b)
		var v := lerpf(v0, meet, u)
		var p := Vector2(sx.call(v), y - 12.0 - 14.0 * k)
		if u > 0.0:
			draw_line(Vector2(sx.call(v0), p.y), p, Color(cols[k].r, cols[k].g, cols[k].b, 0.35), 3.0)
		UITheme.dot(self, p, 12.0, Color(cols[k].r, cols[k].g, cols[k].b, 0.25))
		UITheme.dot(self, p, 5.5, cols[k])
		MathLabel.draw_on(self, font, p.x - 12.0, p.y - 4.0, String(names[k]), UITheme.fs(14), cols[k])
	if u >= 1.0:
		var age := t - float(s.run_t) - 2.4
		var pm := Vector2(sx.call(meet), y - 19.0)
		UITheme.dot(self, pm, 16.0 + 10.0 * clampf(age, 0.0, 1.0), Color(1, 0.9, 0.5, 0.3 * clampf(1.5 - age, 0.3, 1.0)))


## 縮小地圖：每一種排法一條路（風車＋公里數），風車對齊它在數線上的位置
func _draw_road(rd: Dictionary, sx: Callable, y: float, r: Rect2, st: int) -> void:
	var font := get_theme_default_font()
	var pin: Dictionary = rd.pin
	var keys := pin.keys()
	var row := 0
	for cs in rd.get("cases", []):
		if st < int(cs.get("at", 0)):
			continue
		var km: Dictionary = cs.km
		var k0 = keys[0]
		var k1 = keys[1]
		var scale := (float(pin[k1]) - float(pin[k0])) / (float(km[k1]) - float(km[k0]))
		var ry := r.position.y + 24.0 + 48.0 * row
		row += 1
		var pos := {}
		for name in km.keys():
			pos[name] = float(pin[k0]) + (float(km[name]) - float(km[k0])) * scale
		var xs := []
		for name in pos.keys():
			xs.append(sx.call(pos[name]))
		draw_line(Vector2(xs.min() - 10, ry), Vector2(xs.max() + 10, ry), Color(0.75, 0.68, 0.55, 0.7), 5.0)
		# 公里數：相鄰兩座風車之間
		var names := pos.keys()
		names.sort_custom(func(a, b): return pos[a] < pos[b])
		for j in names.size() - 1:
			var d := absf(float(km[names[j + 1]]) - float(km[names[j]]))
			var mx := (float(sx.call(pos[names[j]])) + float(sx.call(pos[names[j + 1]]))) / 2.0
			var lab := ("%d" % d if is_equal_approx(d, roundf(d)) else "%.1f" % d) + " km"
			var lw := font.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(12)).x
			draw_string(font, Vector2(mx - lw / 2.0, ry + 16.0), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(12), Color(1, 0.92, 0.75, 0.75))
		var show: Dictionary = cs.get("show", {})
		for name in names:
			var px: float = sx.call(pos[name])
			var vis := not show.has(name) or st >= int(show[name])
			# 小風車
			var hub := Vector2(px, ry - 12.0)
			draw_line(Vector2(px, ry), hub, Color("8a7058"), 2.0)
			for b in 4:
				var a := _t() * 1.2 + b * PI / 2.0
				var d := Vector2(cos(a), sin(a))
				draw_colored_polygon(PackedVector2Array([hub, hub + d * 8.0 + Vector2(-d.y, d.x) * 3.0, hub + d * 8.0]), Color(1, 0.9, 0.62, 0.9))
			UITheme.dot(self, hub, 1.8, Color(0.9, 0.85, 0.75))
			MathLabel.draw_on(self, font, px + 12.0, ry - 12.0, String(name), UITheme.fs(14), Color(1, 1, 1, 0.9))
			if vis:
				draw_dashed_line(Vector2(px, ry + 4.0), Vector2(px, y - 4.0), Color(1, 0.9, 0.6, 0.35), 1.0, 4.0)


static func _nice_step(raw: float) -> float:
	var e := pow(10.0, floorf(log(raw) / log(10.0)))
	for m in [1.0, 2.0, 5.0, 10.0]:
		if m * e >= raw:
			return m * e
	return 10.0 * e


static func _fmt(v: float, stp: float) -> String:
	var dec := maxi(0, int(ceilf(-log(stp) / log(10.0) - 1e-9)))
	var s := ("%." + str(dec) + "f") % v
	if s == "-0" or s.begins_with("-0.") and float(s) == 0.0:
		s = s.substr(1)
	return s.replace("-", "−")


# ================= 質因數積木 =================

func _rows(spec, st: int) -> Array:
	if spec is Array and not spec.is_empty() and spec[0] is Array:
		var cur: Array = []
		for stage in spec:
			if st >= int(stage[0]):
				cur = stage[1]
		return cur
	return spec


func _draw_blocks(i: int, it: Dictionary, r: Rect2) -> void:
	var font := get_theme_default_font()
	var st := _step()
	var t := _t()
	var s: Dictionary = _st.get(i, {"cut_t": -1.0, "judge_t": -1.0, "ang": 0.0, "last": t, "num_n": -1})
	var dt := clampf(t - float(s.last), 0.0, 0.1)
	s.last = t
	var num := _rows(it.num, st)
	var den := _rows(it.den, st)
	var cancel: Array = it.get("cancel", [])
	var cut := not cancel.is_empty() and st >= int(cancel[0])
	if cut and float(s.cut_t) < 0.0:
		s.cut_t = t
	var judge: Array = it.get("judge", [])
	var judged := not judge.is_empty() and st >= int(judge[0])
	if judged and float(s.judge_t) < 0.0:
		s.judge_t = t
	var gone_n := {}
	var gone_d := {}
	if cut:
		for pr in cancel[1]:
			gone_n[int(pr[0])] = true
			gone_d[int(pr[1])] = true
	var u := clampf((t - float(s.cut_t)) / 0.9, 0.0, 1.0) if cut else 0.0
	var shake := 4.0 * sin(t * 40.0) * _miss()
	# 積木排在左邊 70%，右邊是小風車
	var area := Rect2(r.position, Vector2(r.size.x * 0.7, r.size.y))
	var cy := area.position.y + area.size.y * 0.5
	var bs := minf(40.0, area.size.y * 0.24)
	var gap := 8.0
	var widest := maxf(num.size(), den.size()) * (bs + gap) + gap
	var bx := area.position.x + (area.size.x - widest) / 2.0
	draw_line(Vector2(bx, cy), Vector2(bx + widest, cy), Color(1, 0.95, 0.85, 0.7), 2.5)
	for row in 2:
		var arr: Array = num if row == 0 else den
		var gone: Dictionary = gone_n if row == 0 else gone_d
		var x := bx + gap + (widest - gap - arr.size() * (bs + gap)) / 2.0
		var y := cy - bs - 8.0 if row == 0 else cy + 8.0
		for k in arr.size():
			var lab := String(arr[k])
			var c: Color = PRIME_C.get(lab, Color(0.75, 0.75, 0.85))
			var al := 1.0
			var dy := 0.0
			if gone.has(k):
				al = 1.0 - u
				dy = 60.0 * u * u
			if al > 0.01:
				var rc := Rect2(x + shake, y + dy, bs, bs)
				draw_rect(rc, Color(c.r, c.g, c.b, 0.35 * al))
				draw_rect(rc, Color(c.r, c.g, c.b, 0.9 * al), false, 2.0)
				var fs := UITheme.fs(18 if lab.length() <= 2 else 14)
				var w := font.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string(font, Vector2(rc.position.x + (bs - w) / 2.0, rc.position.y + bs * 0.68), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, al))
				if gone.has(k) and u > 0.0:
					draw_line(rc.position + Vector2(4, bs - 4), rc.position + Vector2(bs - 4, 4), Color(1, 0.4, 0.4, al), 3.0)
			x += bs + gap
	# 小風車：判斷之前慢慢晃，有限小數 → 停下來、燈亮，循環小數 → 一直轉
	var mc := Vector2(r.position.x + r.size.x * 0.86, r.position.y + r.size.y * 0.42)
	var fin := judged and bool(judge[1])
	var spd := 0.4
	if judged:
		spd = 0.0 if fin else 3.0
	s.ang = float(s.ang) + dt * spd
	_st[i] = s
	var ground := r.end.y - 14.0
	draw_colored_polygon(PackedVector2Array([Vector2(mc.x - 9, ground), Vector2(mc.x + 9, ground), Vector2(mc.x + 3, mc.y), Vector2(mc.x - 3, mc.y)]), Color("4a3f5e"))
	var bl := minf(r.size.y * 0.24, 34.0)
	for k in 4:
		var a := float(s.ang) + k * PI / 2.0
		var d := Vector2(cos(a), sin(a))
		var nm := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([mc + nm * 2.0, mc + d * bl + nm * 5.0, mc + d * bl - nm * 2.0, mc - nm * 2.0]), Color(0.7, 0.65, 0.85, 0.8))
	UITheme.dot(self, mc, 3.5, Color(0.9, 0.85, 0.75))
	if fin:
		var g := clampf((t - float(s.judge_t)) / 0.6, 0.0, 1.0)
		var lp := mc + Vector2(0, -bl - 14.0)
		UITheme.dot(self, lp, 22.0 * g, Color(0.6, 1.0, 0.5, 0.25 * g))
		UITheme.dot(self, lp, 6.0, Color(0.75, 1.0, 0.6, g))
