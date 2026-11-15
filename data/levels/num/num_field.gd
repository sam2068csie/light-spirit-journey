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
##
## 在圖上作答（2026/11/14 試作，關卡端在 num_level.gd）：begin(模式, 設定, 回呼) 開始、end() 結束
##   tap     點數線：回呼 {"v": 點到的值（吸附到 snap）}，關卡判斷對錯後呼叫 mark(v, 對不對, 錯的時候顯示的字)
##   drag    把珠子從右上角的托盤拖到繩上，吸附到 snaps（a 到 b 的幾分之幾）；drag_result() 讀位置、drag_reject(名字們) 退回托盤
##   blocks  點一塊分子積木、再點一塊一樣的分母積木就約掉；回呼 {"cut": 有沒有約掉, "left": 還剩幾對可以約}
##   sail    點風車的一片扇葉（風車先停下來）；回呼 {"k": 第幾片（0 = 循環節的第一個數字）}
##   sort    篩種子（R5）：把種子袋裡的種子拖進左右兩個籃子；drag_result() 讀 {名字: 0 左 / 1 右 / null 還在袋子}、drag_reject(名字們) 退回
##           spec：{"item"}（種子寫在 seeds 元件裡）
##   range   拉範圍（R3）：數線上第 row 排的燈條有兩個把手，拖到端點（吸附到 snap）；range_result() 讀 [左, 右]、range_flash(哪一端) 閃紅
##           spec：{"item", "row", "s": 標籤, "start": [左, 右], "snap", "demo": true（一隻手先示範怎麼拖，學生一碰就停）}
##
## 燈條（R3）：nline 加 "bars": [{"lo", "hi", "s": 標籤, "row": 第幾排（0 = 最靠近數線）, "at": 第幾步出現, "c": 顏色,
##                              "from": [a0, b0, 排]（出現時從這一段變過來：a0 → lo、b0 → hi，翻過 0 就寫反過來的端點）,
##                              "src": [[排, 值, 0 或 1], …]（出現時從那一排的那個值連一條線到這條的左端 0、右端 1）}]
##   有燈條的數線，軸往下移，燈條一排一排疊在上面。
##
## 種子（R5）：{"k": "seeds", "bins": ["左邊籃子的標籤", "右邊"], "seeds": [["名字（算式）", 0 或 1（該放哪個籃子）], …],
##             "at": 第幾步是篩種子（做完之前種子都在袋子裡，做完之後在對的籃子裡）, "hl": [[第幾步起, "名字"], …]（亮起來的種子）}
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

# ---- 在圖上作答 ----
var mode := ""                   # ""、"tap"、"drag"、"blocks"、"sail"
var spec := {}
var on_event := Callable()
var marks: Array = []            # tap：[{v, ok, text, t}]
var drag_pos := {}               # drag：名字 → 吸附到的比例（null = 還在托盤）
var dragging := ""
var drag_pt := Vector2.ZERO
var reject_t := {}               # drag：退回托盤的時間（閃紅）
var bcut: Array = []             # blocks：[[分子第幾塊, 分母第幾塊], …]
var bsel: Array = []             # blocks：選了哪一塊 [列（0 分子、1 分母）, 第幾塊]，[] = 沒選
var rng := [0.0, 0.0]            # range：兩個把手目前的值
var rng_drag := -1               # range：拖哪一個把手（−1 = 沒拖）
var rng_flash := {}              # range：哪一端剛閃紅 → 時間
var demo_t := -1.0               # range：示範動畫開始的時間（−1 = 沒有示範）
var _geo := {}                   # 每個元件畫的位置（點擊、測試要換算）：nline → {x0, x1, lo, hi, y, ry}、blocks → {n: [Rect2], d: [Rect2]}


func reset(list: Array, v: Object) -> void:
	items = list
	view = v
	_st = {}
	end()
	bcut = []
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
			"seeds":
				_draw_seeds(i, it, r)
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
	elif spin and not (mode == "sail" and int(spec.get("item", 0)) == i):
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
	var sails := []
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
		sails.append(cp)
		var tp := cp + Vector2(-cw.x / 2.0, cw.y * 0.32)
		draw_string_outline(font, tp, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, dfs, 4, Color(0.1, 0.07, 0.1, 0.9))
		draw_string(font, tp, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, dfs, Color(1, 1, 1) if lit or hi else Color(1, 1, 1, 0.8))
	UITheme.dot(self, hub, 5.5, Color(0.9, 0.85, 0.75))
	_geo[i] = {"sails": sails}
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
	var y := r.position.y + r.size.y * (0.84 if it.has("road") or it.has("bars") else 0.64)
	var x0 := r.position.x + 18.0
	var x1 := r.end.x - 22.0
	var sx := func(v: float) -> float:
		return x0 + (v - lo) / (hi - lo) * (x1 - x0)
	_geo[i] = {"x0": x0, "x1": x1, "lo": lo, "hi": hi, "y": y, "ry": y - 26.0}
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
	if it.has("bars"):
		_draw_bars(i, it.bars, sx, x0, x1, y, st, t, font)
	if mode == "range" and int(spec.get("item", 0)) == i:
		_draw_range(sx, _geo[i], font)
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
	if int(spec.get("item", 0)) == i:
		if mode == "tap":
			_draw_marks(sx, y - 26.0, font)
		elif mode == "drag":
			_draw_drag(sx, y, y - 26.0, r, font)


# ================= 在圖上作答 =================

func begin(m: String, sp: Dictionary, cb: Callable) -> void:
	mode = m
	spec = sp
	on_event = cb
	marks = []
	drag_pos = {}
	reject_t = {}
	dragging = ""
	bsel = []
	if m == "drag":
		for b in sp.get("beads", []):
			drag_pos[String(b[0])] = null
	if m == "sort":
		for sd in items[int(sp.get("item", 0))].get("seeds", []):
			drag_pos[String(sd[0])] = null
	if m == "range":
		var st0: Array = sp.get("start", [0, 1])
		rng = [float(st0[0]), float(st0[1])]
		rng_drag = -1
		rng_flash = {}
		demo_t = _t() if bool(sp.get("demo", false)) else -1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func end() -> void:
	mode = ""
	dragging = ""
	demo_t = -1.0
	rng_drag = -1
	marks = []
	drag_pos = {}
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func mark(v: float, ok: bool, text := "") -> void:
	marks.append({"v": v, "ok": ok, "text": text, "t": _t()})


func _gui_input(e: InputEvent) -> void:
	if mode == "":
		return
	var pos := Vector2.ZERO
	var press := false
	var release := false
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pos = (e as InputEventMouseButton).position
		press = e.pressed
		release = not e.pressed
	elif e is InputEventMouseMotion:
		if dragging != "":
			drag_pt = (e as InputEventMouseMotion).position
			accept_event()
		if mode == "range" and rng_drag >= 0:
			var v = _line_value((e as InputEventMouseMotion).position)
			if v != null:
				rng[rng_drag] = v
			accept_event()
		return
	else:
		return
	accept_event()
	match mode:
		"tap":
			if press:
				var v = value_at(pos)
				if v != null:
					on_event.call({"v": v})
		"drag":
			if press:
				dragging = _bead_at(pos)
				drag_pt = pos
			elif release and dragging != "":
				drag_pos[dragging] = _snap_at(pos)
				dragging = ""
		"blocks":
			if press:
				_block_click(pos)
		"sort":
			if press:
				dragging = _seed_at(pos)
				drag_pt = pos
			elif release and dragging != "":
				drag_pos[dragging] = _bin_at(pos)
				dragging = ""
		"range":
			if press:
				rng_drag = _handle_at(pos)
				if rng_drag >= 0 and demo_t >= 0.0:
					var dp := _demo_pose()
					if not dp.is_empty() and int(dp.k) == rng_drag:
						rng[rng_drag] = _line_value(pos)
				demo_t = -1.0
			elif release:
				rng_drag = -1
		"sail":
			if press:
				var sl: Array = _geo.get(int(spec.get("item", 0)), {}).get("sails", [])
				var best := -1
				var bd := 28.0
				for k in sl.size():
					var d := pos.distance_to(sl[k])
					if d < bd:
						bd = d
						best = k
				if best >= 0:
					on_event.call({"k": best})


## 點的位置 → 數線上的值（吸附到 snap）。不在數線附近回傳 null
func value_at(pos: Vector2):
	var g: Dictionary = _geo.get(int(spec.get("item", 0)), {})
	if g.is_empty() or absf(pos.y - float(g.y)) > 46.0 or pos.x < float(g.x0) - 6.0 or pos.x > float(g.x1) + 6.0:
		return null
	var v: float = float(g.lo) + (pos.x - float(g.x0)) / (float(g.x1) - float(g.x0)) * (float(g.hi) - float(g.lo))
	var sn := float(spec.get("snap", 1.0))
	return snappedf(v, sn)


## 拉範圍：點的位置 → 值（只看 x，吸附到 snap，夾在數線範圍裡）
func _line_value(pos: Vector2):
	var g: Dictionary = _geo.get(int(spec.get("item", 0)), {})
	if g.is_empty():
		return null
	var v: float = float(g.lo) + (pos.x - float(g.x0)) / (float(g.x1) - float(g.x0)) * (float(g.hi) - float(g.lo))
	v = clampf(v, float(g.lo), float(g.hi))
	return snappedf(v, float(spec.get("snap", 1.0)))


func _bar_y(g: Dictionary, row: float) -> float:
	return float(g.y) - 22.0 - 24.0 * row


func _handle_pos(k: int) -> Vector2:
	var g: Dictionary = _geo.get(int(spec.get("item", 0)), {})
	if g.is_empty():
		return Vector2(-999, -999)
	var v: float = rng[k]
	var dp := _demo_pose()
	if not dp.is_empty() and int(dp.k) == k:
		v = float(dp.v)
	var x: float = float(g.x0) + (v - float(g.lo)) / (float(g.hi) - float(g.lo)) * (float(g.x1) - float(g.x0))
	return Vector2(x, _bar_y(g, float(spec.get("row", 0))))


func _handle_at(pos: Vector2) -> int:
	var best := -1
	var bd := 30.0
	for k in 2:
		var d := pos.distance_to(_handle_pos(k))
		if d < bd:
			bd = d
			best = k
	return best


func range_result() -> Array:
	return [minf(rng[0], rng[1]), maxf(rng[0], rng[1])]


## 錯的那一端閃紅（0 = 左端、1 = 右端，照目前的大小）
func range_flash(end_k: int) -> void:
	var k := end_k if rng[0] <= rng[1] else 1 - end_k
	rng_flash[k] = _t()


## 示範動畫：一隻手把左邊的把手拖出去再拖回來，再換右邊（3.6 秒一輪）。回傳 {k: 哪一個把手, v: 現在的值, hand: 手的位置}
func _demo_pose() -> Dictionary:
	if demo_t < 0.0 or mode != "range":
		return {}
	var g: Dictionary = _geo.get(int(spec.get("item", 0)), {})
	if g.is_empty():
		return {}
	var u := fmod(_t() - demo_t, 3.6) / 1.8
	var k := 0 if u < 1.0 else 1
	var w := fmod(u, 1.0)
	var span := (float(g.hi) - float(g.lo)) * 0.16
	var base: float = rng[k]
	var off := (-span if k == 0 else span) * sin(clampf((w - 0.15) / 0.7, 0.0, 1.0) * PI)
	return {"k": k, "v": base + off, "w": w}


## 測試用：把手、數線上的值在螢幕上的位置
func global_of_handle(k: int) -> Vector2:
	return get_global_transform() * _handle_pos(k)


func global_of_line_value(v: float) -> Vector2:
	var g: Dictionary = _geo.get(int(spec.get("item", 0)), {})
	var x: float = float(g.x0) + (v - float(g.lo)) / (float(g.hi) - float(g.lo)) * (float(g.x1) - float(g.x0))
	return get_global_transform() * Vector2(x, _bar_y(g, float(spec.get("row", 0))))


func _draw_range(sx: Callable, g: Dictionary, font: Font) -> void:
	var t := _t()
	var y := _bar_y(g, float(spec.get("row", 0)))
	var p0 := _handle_pos(0)
	var p1 := _handle_pos(1)
	var a := minf(p0.x, p1.x)
	var b := maxf(p0.x, p1.x)
	var c := Color(0.75, 0.95, 0.5)
	draw_rect(Rect2(a, y - 5, b - a, 10), Color(c.r, c.g, c.b, 0.35))
	draw_rect(Rect2(a, y - 5, b - a, 10), Color(c.r, c.g, c.b, 0.8), false, 1.5)
	var lab := String(spec.get("s", ""))
	if lab != "":
		var w := MathLabel.text_width(font, lab, UITheme.fs(15))
		var lx := a - 14.0 - w / 2.0
		if lx - w / 2.0 < float(g.x0) - 14.0:
			lx = b + 14.0 + w / 2.0
		MathLabel.draw_on(self, font, lx, y + 6.0, lab, UITheme.fs(15), Color(0.85, 1.0, 0.7))
	for k in 2:
		var p := _handle_pos(k)
		var hc := Color(1, 0.95, 0.75)
		if rng_flash.has(k) and t - float(rng_flash[k]) < 1.2:
			hc = hc.lerp(COLS.bad, 0.5 + 0.5 * sin((t - float(rng_flash[k])) * 18.0))
		if rng_drag == k:
			UITheme.dot(self, p, 18.0, Color(1, 0.9, 0.5, 0.3))
		UITheme.dot(self, p, 9.0, hc)
		draw_arc(p, 9.0, 0, TAU, 20, Color(0.3, 0.4, 0.2), 2.0)
		# 把手拉到哪裡，數線上就標出那個值
		var vv: float = rng[k]
		if rng_drag == k:
			var vs := _fmt(vv, float(spec.get("snap", 1.0)))
			var vw := font.get_string_size(vs, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14)).x
			draw_string(font, Vector2(p.x - vw / 2.0, p.y - 14.0), vs, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14), Color(1, 0.95, 0.75))
		draw_line(Vector2(p.x, p.y + 9.0), Vector2(p.x, float(g.y)), Color(1, 0.95, 0.75, 0.35), 1.0)
	# 示範的手：半透明的圓＋手指
	var dp := _demo_pose()
	if not dp.is_empty():
		var hp := _handle_pos(int(dp.k)) + Vector2(10, 14)
		var press := float(dp.w) > 0.12 and float(dp.w) < 0.88
		var al := 0.85
		UITheme.dot(self, hp - Vector2(10, 14), 15.0 if press else 11.0, Color(1, 1, 1, 0.18))
		draw_colored_polygon(PackedVector2Array([hp, hp + Vector2(6, 22), hp + Vector2(20, 26), hp + Vector2(24, 12), hp + Vector2(8, 2)]), Color(1, 1, 1, 0.55 * al))
		draw_circle(hp + Vector2(1, 0), 4.5, Color(1, 1, 1, 0.8 * al))


## 數線上的值 → 螢幕上的位置（測試用）
func global_of_value(v: float) -> Vector2:
	var g: Dictionary = _geo.get(int(spec.get("item", 0)), {})
	var x: float = float(g.x0) + (v - float(g.lo)) / (float(g.hi) - float(g.lo)) * (float(g.x1) - float(g.x0))
	return get_global_transform() * Vector2(x, float(g.y))


func _draw_marks(sx: Callable, ry: float, font: Font) -> void:
	var t := _t()
	for mk in marks:
		var age := t - float(mk.t)
		var px: float = sx.call(float(mk.v))
		if bool(mk.ok):
			UITheme.dot(self, Vector2(px, ry), 14.0, Color(1, 0.85, 0.4, 0.3))
			UITheme.dot(self, Vector2(px, ry), 6.0, COLS.gold)
			continue
		var al := clampf(2.5 - age, 0.0, 1.0)
		if al <= 0.0:
			continue
		UITheme.dot(self, Vector2(px, ry), 7.0, Color(1, 0.4, 0.4, al))
		if String(mk.text) != "":
			MathLabel.draw_on(self, font, clampf(px, 90.0, size.x - 90.0), ry - 26.0, String(mk.text), UITheme.fs(16), Color(1, 0.55, 0.55, al))


# ---- 拖珠子：snaps 是 a 到 b 的幾分之幾，標在數線下面 ----

func _snap_v(f: float) -> float:
	return float(spec.a) + f * (float(spec.b) - float(spec.a))


func _tray_pos(k: int) -> Vector2:
	var n: int = spec.get("beads", []).size()
	return Vector2(size.x - 34.0 - 40.0 * (n - 1 - k), 40.0)


func _bead_pos(name: String, sx: Callable, ry: float) -> Vector2:
	var beads: Array = spec.get("beads", [])
	for k in beads.size():
		if String(beads[k][0]) == name:
			if dragging == name:
				return drag_pt
			if drag_pos.get(name) == null:
				return _tray_pos(k)
			return Vector2(sx.call(_snap_v(float(drag_pos[name]))), ry)
	return Vector2.ZERO


func _bead_at(pos: Vector2) -> String:
	var g: Dictionary = _geo.get(int(spec.get("item", 0)), {})
	if g.is_empty():
		return ""
	var sx := func(v: float) -> float:
		return float(g.x0) + (v - float(g.lo)) / (float(g.hi) - float(g.lo)) * (float(g.x1) - float(g.x0))
	var best := ""
	var bd := 30.0
	for b in spec.get("beads", []):
		var d := pos.distance_to(_bead_pos(String(b[0]), sx, float(g.ry)))
		if d < bd:
			bd = d
			best = String(b[0])
	return best


## 放開的位置 → 最近的吸附點（比例）。離繩子太遠就回托盤（null）
func _snap_at(pos: Vector2):
	var g: Dictionary = _geo.get(int(spec.get("item", 0)), {})
	if g.is_empty() or absf(pos.y - float(g.ry)) > 50.0:
		return null
	var v: float = float(g.lo) + (pos.x - float(g.x0)) / (float(g.x1) - float(g.x0)) * (float(g.hi) - float(g.lo))
	var best = null
	var bd := INF
	for sn in spec.get("snaps", []):
		var d := absf(_snap_v(float(sn[0])) - v)
		if d < bd:
			bd = d
			best = float(sn[0])
	return best


func drag_result() -> Dictionary:
	return drag_pos.duplicate()


func drag_reject(names: Array) -> void:
	for n in names:
		drag_pos[String(n)] = null
		reject_t[String(n)] = _t()


## 測試用：珠子、吸附點在螢幕上的位置
func global_of_bead(name: String) -> Vector2:
	var g: Dictionary = _geo.get(int(spec.get("item", 0)), {})
	var sx := func(v: float) -> float:
		return float(g.x0) + (v - float(g.lo)) / (float(g.hi) - float(g.lo)) * (float(g.x1) - float(g.x0))
	return get_global_transform() * _bead_pos(name, sx, float(g.ry))


func global_of_snap(f: float) -> Vector2:
	var g: Dictionary = _geo.get(int(spec.get("item", 0)), {})
	var x: float = float(g.x0) + (_snap_v(f) - float(g.lo)) / (float(g.hi) - float(g.lo)) * (float(g.x1) - float(g.x0))
	return get_global_transform() * Vector2(x, float(g.ry))


func _draw_drag(sx: Callable, y: float, ry: float, r: Rect2, font: Font) -> void:
	var t := _t()
	# 吸附點：數線下面標「a 往 b 走幾分之幾」
	var last_r := -INF
	var low := false
	var lfs := UITheme.fs(13)
	for sn in spec.get("snaps", []):
		var px: float = sx.call(_snap_v(float(sn[0])))
		draw_line(Vector2(px, ry - 5), Vector2(px, ry + 5), Color(1, 0.95, 0.8, 0.45), 1.5)
		draw_line(Vector2(px, y - 4), Vector2(px, y + 4), Color(1, 0.95, 0.8, 0.45), 1.5)
		if sn.size() > 1 and String(sn[1]) != "":
			# 標籤太擠就上下錯開
			var w := MathLabel.text_width(font, String(sn[1]), lfs)
			low = (px - w / 2.0 < last_r + 4.0) and not low
			if not low:
				last_r = px + w / 2.0
			var ly := y + (58.0 if low else 30.0)
			if low:
				draw_line(Vector2(px, y + 6), Vector2(px, ly - 22.0), Color(1, 0.95, 0.8, 0.25), 1.0)
			MathLabel.draw_on(self, font, px, ly, String(sn[1]), lfs, Color(1, 0.95, 0.8, 0.6))
	# 托盤
	var beads: Array = spec.get("beads", [])
	var tray := Rect2(_tray_pos(0) - Vector2(20, 34), Vector2(40.0 * beads.size(), 50))
	draw_rect(tray, Color(1, 1, 1, 0.05))
	draw_rect(tray, Color(1, 0.9, 0.6, 0.25), false, 1.0)
	for k in beads.size():
		var name := String(beads[k][0])
		var p := _bead_pos(name, sx, ry)
		var c: Color = COLS.gold
		if reject_t.has(name) and t - float(reject_t[name]) < 1.2:
			c = COLS.bad
		_draw_bead(p, c, 0.6 if dragging == name else 0.0, String(beads[k][1]) if beads[k].size() > 1 else name, font)


# ---- 點積木約分 ----

## 剩下的分子、分母裡，還有幾對一樣的
func blocks_left(i: int) -> int:
	var it: Dictionary = items[i]
	var num := _rows(it.num, _step())
	var den := _rows(it.den, _step())
	var used_n := {}
	var used_d := {}
	for pr in bcut:
		used_n[int(pr[0])] = true
		used_d[int(pr[1])] = true
	var left := 0
	var taken := {}
	for a in num.size():
		if used_n.has(a):
			continue
		for b in den.size():
			if used_d.has(b) or taken.has(b):
				continue
			if String(num[a]) == String(den[b]):
				taken[b] = true
				left += 1
				break
	return left


func _block_click(pos: Vector2) -> void:
	var i := int(spec.get("item", 0))
	var g: Dictionary = _geo.get(i, {})
	if g.is_empty():
		return
	var used := [{}, {}]
	for pr in bcut:
		used[0][int(pr[0])] = true
		used[1][int(pr[1])] = true
	for row in 2:
		var rects: Array = g.n if row == 0 else g.d
		for k in rects.size():
			if not (rects[k] as Rect2).grow(4).has_point(pos) or used[row].has(k):
				continue
			if bsel.is_empty() or int(bsel[0]) == row:
				bsel = [row, k]          # 同一列再點一次 = 換一塊
				return
			var kn: int = k if row == 0 else int(bsel[1])
			var kd: int = k if row == 1 else int(bsel[1])
			bsel = []
			var it: Dictionary = items[i]
			var num := _rows(it.num, _step())
			var den := _rows(it.den, _step())
			if String(num[kn]) == String(den[kd]):
				bcut.append([kn, kd])
				_st[i]["ucut_t"] = _t()
				on_event.call({"cut": true, "left": blocks_left(i)})
			else:
				on_event.call({"cut": false, "left": blocks_left(i), "pair": [String(num[kn]), String(den[kd])]})
			return


## 測試用：風車第 k 片扇葉在螢幕上的位置
func global_of_sail(k: int) -> Vector2:
	var sl: Array = _geo.get(int(spec.get("item", 0)), {}).get("sails", [])
	return get_global_transform() * (sl[k] as Vector2)


## 測試用：分子第 k 塊、分母第 k 塊在螢幕上的位置
func global_of_block(row: int, k: int) -> Vector2:
	var g: Dictionary = _geo.get(int(spec.get("item", 0)), {})
	var arr: Array = g.n if row == 0 else g.d
	return get_global_transform() * (arr[k] as Rect2).get_center()


# ---- 燈條（R3）----

func _draw_bars(i: int, bars: Array, sx: Callable, x0: float, x1: float, y: float, st: int, t: float, font: Font) -> void:
	var s: Dictionary = _st[i]
	if not s.has("bar_t"):
		s["bar_t"] = {}
	var bt: Dictionary = s.bar_t
	var g := {"y": y}
	for k in bars.size():
		var b: Dictionary = bars[k]
		if st < int(b.get("at", 0)):
			continue
		if not bt.has(k):
			bt[k] = t if int(b.get("at", 0)) > 0 else t - 10.0
		var age := t - float(bt[k])
		var u := 1.0 - pow(1.0 - clampf(age / 0.9, 0.0, 1.0), 3.0)
		var lo := float(b.lo)
		var hi := float(b.hi)
		var row := float(b.get("row", 0))
		if b.has("from"):
			var f: Array = b.from
			lo = lerpf(float(f[0]), lo, u)
			hi = lerpf(float(f[1]), hi, u)
			row = lerpf(float(f[2]), row, u)
		var by := _bar_y(g, row)
		var c: Color = COLS.get(String(b.get("c", "cyan")), COLS.cyan)
		var a := clampf(sx.call(minf(lo, hi)), x0, x1)
		var e := clampf(sx.call(maxf(lo, hi)), x0, x1)
		var fresh := clampf(1.0 - age / 1.2, 0.0, 1.0) if int(b.get("at", 0)) > 0 else 0.0
		if fresh > 0.0:
			draw_rect(Rect2(a - 4, by - 9, e - a + 8, 18), Color(c.r, c.g, c.b, 0.25 * fresh))
		draw_rect(Rect2(a, by - 5, e - a, 10), Color(c.r, c.g, c.b, 0.32))
		draw_rect(Rect2(a, by - 5, e - a, 10), Color(c.r, c.g, c.b, 0.85), false, 1.5)
		for xx in [a, e]:
			draw_line(Vector2(xx, by + 5), Vector2(xx, y), Color(c.r, c.g, c.b, 0.22), 1.0)
		var lab := String(b.get("s", ""))
		if lab != "":
			var w := MathLabel.text_width(font, lab, UITheme.fs(15))
			var lx := a - 14.0 - w / 2.0
			if lx - w / 2.0 < x0 - 14.0:
				lx = e + 14.0 + w / 2.0
			MathLabel.draw_on(self, font, lx, by + 6.0, lab, UITheme.fs(15), c.lightened(0.25))
		# 從哪裡合出來：剛出現時，從來源的端點連線過來
		if age < 2.4 and u >= 1.0:
			var la := clampf(1.0 - (age - 0.9) / 1.5, 0.0, 1.0)
			for sc in b.get("src", []):
				var py := _bar_y(g, float(sc[0]))
				var pv: float = sx.call(float(sc[1]))
				var to_x := a if int(sc[2]) == 0 else e
				draw_dashed_line(Vector2(pv, py), Vector2(to_x, by), Color(1, 0.95, 0.75, 0.7 * la), 1.5, 5.0)
	s.bar_t = bt


# ---- 種子和兩個籃子（R5）----

const SEED_FS := 14
const SEED_PAD := 6.0            # 種子上下的留白
const SEED_GAP := 6.0


## 種子的大小：寬照字的寬度，高照字的上下範圍（分數比較高，種子也跟著高，字不會超出框）
func _seed_size(font: Font, name: String) -> Vector2:
	var ext := MathLabel.line_extent(name, UITheme.fs(SEED_FS))
	return Vector2(MathLabel.text_width(font, name, UITheme.fs(SEED_FS)) + 16.0, maxf(28.0, ext.x + ext.y + 2.0 * SEED_PAD))


## 一排一排放：左邊從 x0 開始、寬度到 x1，回傳 {名字: Rect2} 和用掉的高度
func _flow(font: Font, names: Array, x0: float, x1: float, y0: float) -> Array:
	var out := {}
	var x := x0
	var y := y0
	var row_h := 0.0
	for name in names:
		var sz := _seed_size(font, String(name))
		if x + sz.x > x1 and x > x0:
			x = x0
			y += row_h + SEED_GAP
			row_h = 0.0
		out[name] = Rect2(Vector2(x, y), sz)
		x += sz.x + SEED_GAP
		row_h = maxf(row_h, sz.y)
	return [out, y + row_h - y0]


## 兩個籃子的位置：種子袋（全部種子都在袋子裡時）占上面，籃子占剩下的下半部
func _bins(r: Rect2, it: Dictionary) -> Array:
	var names := []
	for sd in it.get("seeds", []):
		names.append(String(sd[0]))
	var tray_h: float = _flow(get_theme_default_font(), names, r.position.x, r.end.x, r.position.y)[1]
	var y := r.position.y + tray_h + 8.0
	var bw := (r.size.x - 16.0) / 2.0
	var bh := maxf(60.0, r.end.y - y)
	return [Rect2(r.position.x, y, bw, bh), Rect2(r.position.x + bw + 16.0, y, bw, bh)]


## 每顆種子的位置：pos 是 {名字: null / 0 / 1}
func _seed_layout(it: Dictionary, r: Rect2, pos: Dictionary) -> Dictionary:
	var font := get_theme_default_font()
	var bins := _bins(r, it)
	var groups := [[], [], []]
	for sd in it.get("seeds", []):
		var where = pos.get(String(sd[0]))
		groups[0 if where == null else int(where) + 1].append(String(sd[0]))
	var out := {}
	out.merge(_flow(font, groups[0], r.position.x, r.end.x, r.position.y)[0])
	for k in 2:
		var b: Rect2 = bins[k]
		out.merge(_flow(font, groups[k + 1], b.position.x + 6.0, b.end.x - 6.0, b.position.y + 24.0)[0])
	return out


func _sort_rect() -> Rect2:
	var i := int(spec.get("item", 0))
	return _geo.get(i, {}).get("r", Rect2())


func _seed_at(pos: Vector2) -> String:
	var i := int(spec.get("item", 0))
	var lay := _seed_layout(items[i], _sort_rect(), drag_pos)
	for name in lay:
		if (lay[name] as Rect2).grow(4).has_point(pos):
			return String(name)
	return ""


func _bin_at(pos: Vector2):
	var bins := _bins(_sort_rect(), items[int(spec.get("item", 0))])
	for k in 2:
		if (bins[k] as Rect2).grow(10).has_point(pos):
			return k
	return null


## 測試用：種子、籃子在螢幕上的位置
func global_of_seed(name: String) -> Vector2:
	var i := int(spec.get("item", 0))
	var lay := _seed_layout(items[i], _sort_rect(), drag_pos)
	return get_global_transform() * (lay[name] as Rect2).get_center()


func global_of_bin(k: int) -> Vector2:
	var b: Rect2 = _bins(_sort_rect(), items[int(spec.get("item", 0))])[k]
	return get_global_transform() * Vector2(b.get_center().x, b.position.y + b.size.y * 0.7)


func _draw_seeds(i: int, it: Dictionary, r: Rect2) -> void:
	var font := get_theme_default_font()
	var t := _t()
	var st := _step()
	_geo[i] = {"r": r}
	var live := mode == "sort" and int(spec.get("item", 0)) == i
	var done := st > int(it.get("at", 0))
	var pos := {}
	for sd in it.get("seeds", []):
		pos[String(sd[0])] = (drag_pos.get(String(sd[0])) if live else (int(sd[1]) if done else null))
	var bins := _bins(r, it)
	var cols := [Color(0.55, 0.95, 0.55), Color(0.75, 0.7, 1.0)]
	for k in 2:
		var b: Rect2 = bins[k]
		var c: Color = cols[k]
		var hot := live and dragging != "" and b.grow(10).has_point(drag_pt)
		draw_rect(b, Color(c.r, c.g, c.b, 0.16 if hot else 0.08))
		draw_rect(b, Color(c.r, c.g, c.b, 0.6), false, 2.0)
		# 籃子的編織紋
		for yy in range(int(b.position.y) + 26, int(b.end.y), 14):
			draw_line(Vector2(b.position.x + 4, yy), Vector2(b.end.x - 4, yy), Color(c.r, c.g, c.b, 0.07), 1.0)
		var lab := String(it.bins[k]) if it.has("bins") else ""
		MathLabel.draw_on(self, font, b.get_center().x, b.position.y + 18.0, lab, UITheme.fs(14), c)
	var lay := _seed_layout(it, r, pos)
	var hl := {}
	for h in it.get("hl", []):
		if st >= int(h[0]):
			hl[String(h[1])] = true
	for sd in it.get("seeds", []):
		var name := String(sd[0])
		var rc: Rect2 = lay[name]
		if live and dragging == name:
			rc.position = drag_pt - rc.size / 2.0
		var c := Color(1, 0.92, 0.7)
		var bgc := Color(0.25, 0.2, 0.12, 0.9)
		if reject_t.has(name) and t - float(reject_t[name]) < 1.2:
			c = COLS.bad
		if hl.has(name):
			var g := 0.6 + 0.4 * sin(t * 4.0)
			draw_rect(rc.grow(5), Color(1, 0.85, 0.3, 0.25 * g))
			c = COLS.gold
		if done and not live and int(sd[1]) == 0:
			bgc = Color(0.15, 0.3, 0.15, 0.9)
		draw_rect(rc, bgc)
		draw_rect(rc, Color(c.r, c.g, c.b, 0.85), false, 1.5)
		var ext := MathLabel.line_extent(name, UITheme.fs(SEED_FS))
		MathLabel.draw_on(self, font, rc.get_center().x, rc.position.y + (rc.size.y - ext.x - ext.y) / 2.0 + ext.x, name, UITheme.fs(SEED_FS), c)


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
	var pairs: Array = bcut if not bcut.is_empty() else (cancel[1] if cut else [])
	for pr in pairs:
		gone_n[int(pr[0])] = true
		gone_d[int(pr[1])] = true
	if not bcut.is_empty():
		cut = true
		if float(s.cut_t) < 0.0:
			s.cut_t = t
		if not s.has("ucut_t"):
			s["ucut_t"] = t
	var u := clampf((t - float(s.cut_t)) / 0.9, 0.0, 1.0) if cut else 0.0
	var rects_n := []
	var rects_d := []
	var shake := 4.0 * sin(t * 40.0) * _miss()
	# 積木排在左邊 70%，右邊是小風車
	var area := Rect2(r.position, Vector2(r.size.x * 0.7, r.size.y))
	var cy := area.position.y + area.size.y * 0.5
	var bs := minf(40.0, area.size.y * 0.24)
	var gap := 24.0          # 積木之間放乘號
	var widest := maxf(num.size(), den.size()) * (bs + gap) + gap
	var bx := area.position.x + (area.size.x - widest) / 2.0
	draw_line(Vector2(bx, cy), Vector2(bx + widest, cy), Color(1, 0.95, 0.85, 0.7), 2.5)
	for row in 2:
		var arr: Array = num if row == 0 else den
		var gone: Dictionary = gone_n if row == 0 else gone_d
		var x := bx + gap + (widest - gap - arr.size() * (bs + gap)) / 2.0
		var y := cy - bs - 8.0 if row == 0 else cy + 8.0
		var shown := []      # [左邊的 x, 透明度]：相鄰兩塊（還看得到的）中間畫 ×
		for k in arr.size():
			var lab := String(arr[k])
			var c: Color = PRIME_C.get(lab, Color(0.75, 0.75, 0.85))
			var al := 1.0
			var dy := 0.0
			if gone.has(k):
				# 學生剛約掉的那一對才播掉下去的動畫，之前約掉的直接不畫
				var uu := u
				if not bcut.is_empty():
					uu = clampf((t - float(s.get("ucut_t", t))) / 0.9, 0.0, 1.0)
					var last: Array = bcut.back()
					if not ((row == 0 and int(last[0]) == k) or (row == 1 and int(last[1]) == k)):
						uu = 1.0
				al = 1.0 - uu
				dy = 60.0 * uu * uu
			(rects_n if row == 0 else rects_d).append(Rect2(x, y, bs, bs))
			if al > 0.01:
				var rc := Rect2(x + shake, y + dy, bs, bs)
				draw_rect(rc, Color(c.r, c.g, c.b, 0.35 * al))
				draw_rect(rc, Color(c.r, c.g, c.b, 0.9 * al), false, 2.0)
				var fs := UITheme.fs(18 if lab.length() <= 2 else 14)
				var w := font.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				draw_string(font, Vector2(rc.position.x + (bs - w) / 2.0, rc.position.y + bs * 0.68), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, al))
				if gone.has(k) and al < 1.0:
					draw_line(rc.position + Vector2(4, bs - 4), rc.position + Vector2(bs - 4, 4), Color(1, 0.4, 0.4, al), 3.0)
				if mode == "blocks" and not bsel.is_empty() and int(bsel[0]) == row and int(bsel[1]) == k:
					draw_rect(rc.grow(4), Color(1, 0.85, 0.4, 0.9 + 0.1 * sin(t * 8.0)), false, 3.0)
				if al > 0.01 and not shown.is_empty():
					var prev: Array = shown.back()
					var mx: float = (float(prev[0]) + bs + x) / 2.0 + shake
					var xa := minf(float(prev[1]), al)
					var xfs := UITheme.fs(18)
					var xw := font.get_string_size("×", HORIZONTAL_ALIGNMENT_LEFT, -1, xfs).x
					draw_string(font, Vector2(mx - xw / 2.0, y + bs * 0.66), "×", HORIZONTAL_ALIGNMENT_LEFT, -1, xfs, Color(1, 0.95, 0.85, 0.8 * xa))
				if al > 0.01:
					shown.append([x, al])
			x += bs + gap
	_geo[i] = {"n": rects_n, "d": rects_d}
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
