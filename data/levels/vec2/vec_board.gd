extends "res://data/levels/line/line_level.gd".CoordPlane
## 平面向量的「箭頭畫布」（V1 起各關共用）：直線與圓的坐標方格（CoordPlane）再加上
##   ・格線："grid": "plain"（淡淡的方格、沒有坐標軸，預設）、"axes"（有坐標軸，和直線與圓一樣）、"none"
##   ・新的圖層（data.shapes 或滑桿的 lines 裡都可以用，每個圖層一樣可以寫 at、until）：
##       {"k": "arrow", "a": [x, y], "b": [x, y], "c": "cyan", "s": "\\vec{a}", "w": 3, "dash": false, "ls": 1（標籤在左 1／右 −1）, "id": "p"}
##       {"k": "skew", "o": [x, y], "a": [x, y], "b": [x, y], "i": [i0, i1], "j": [j0, j1], "div": 1, "c": "cyan"}   斜方格
##       {"k": "walk", "pts": [[x, y], …], "c": "gold", "arrows": true, "bad": false, "target": [x, y], "dur": 0.55（每一段）}
##            風箏沿著折線飛（arrows：每一段畫成箭頭）。bad：終點打紅叉、風箏打轉掉下來，target：虛線連到真正的目標
##       {"k": "balloon", "p": [x, y], "c": "pink", "pop": 第幾步之後破掉}
##       {"k": "tag", "p": [x, y], "s": "D", "c": "gold"}   只有名字的點（小一點）
##   ・作答模式（level 呼叫）：
##       arrows_on(cb)        點箭頭（vtap）：點到有 id 的箭頭，cb.call(id)
##       pts_on(snap, cb)     點一個點（vpick）：吸附到格子點，cb.call(Vector2)
##       drag_on(named, fixed, cb)  拖箭頭平移（vdrag）：沒有 fixed 時先點兩個點畫一支，放開時頭尾都落在點上，cb.call({from, to})
##       place_on(cfg, cb)    拖一個點（vsandbox）：吸附到格子點，cb.call(Vector2)；cfg.lit 決定燈亮不亮
##       weigh_on(cfg)        秤桿（vweigh）：畫面上的砝碼由 level 改 weigh.wb、weigh.wc
##       path_on(from, to)    鋪路（vpath）：level 改 path_segs
##   ・看得到的後果：fx_merge（箭頭飛過去疊合）、fx_ribbon（彩帶圍成平行四邊形）、fx_walk（風箏飛一段路）
const UITheme := preload("res://data/ui/game_theme.gd")

var mode := ""                    # 目前的作答模式
var _cb := Callable()
var named: Dictionary = {}        # 名字 → 坐標（點選、拖箭頭吸附用）
var snap_v := 1.0
# 點箭頭
var merged: Array = []            # 已經疊合的箭頭 id
var ref_id := ""
# 拖箭頭
var drag_arrow: Dictionary = {}   # {a, b, oa, ob, src}
var drag_start := ""              # 畫箭頭：先點的起點名字
var _dragging := false
var _drag_off := Vector2.ZERO
var found_pairs: Array = []       # [[起點, 終點, 起點, 終點]]
# 拖點
var place_cfg: Dictionary = {}
var place_p := Vector2(INF, INF)
# 秤桿
var weigh: Dictionary = {}
# 鋪路
var path_from := Vector2(INF, INF)
var path_to := Vector2(INF, INF)
var path_segs: Array = []         # [Vector2…]
var vfx: Array = []               # 這一關自己的後果動畫


func reset(d: Dictionary) -> void:
	super(d)
	named = {}
	for k in d.get("named", {}).keys():
		named[k] = _v(d.named[k])
	vfx = []
	_off_all()


func _off_all() -> void:
	mode = ""
	_cb = Callable()
	merged = []
	drag_arrow = {}
	drag_start = ""
	_dragging = false
	found_pairs = []
	place_cfg = {}
	place_p = Vector2(INF, INF)
	weigh = {}
	path_from = Vector2(INF, INF)
	path_to = Vector2(INF, INF)
	path_segs = []
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 結束作答模式（畫面上的結果有些要留著：疊合的箭頭、找到的對、鋪好的路由 level 決定要不要變成圖層）
func vec_off() -> void:
	mode = ""
	_cb = Callable()
	_dragging = false
	if not picking:
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input_on(m: String, cb: Callable) -> void:
	mode = m
	_cb = cb
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()


func arrows_on(ref: String, cb: Callable) -> void:
	merged = []
	ref_id = ref
	_input_on("arrows", cb)


var pick_skew: Dictionary = {}   # 斜格子點選：{o, a, b, div}
var hover_p := Vector2(INF, INF)


func pts_on(sn: float, cb: Callable, skew := {}) -> void:
	snap_v = sn if sn > 0.0 else 1.0
	pick_skew = skew
	hover_p = Vector2(INF, INF)
	_input_on("pts", cb)


## 點選的位置吸附到格子點（有 pick_skew 時吸附到斜格子的交點）
func _snap_pick(w: Vector2) -> Vector2:
	if pick_skew.is_empty():
		return Vector2(snappedf(w.x, snap_v), snappedf(w.y, snap_v))
	var uv := skew_uv(w)
	var dv := float(pick_skew.get("div", 1))
	uv = Vector2(roundf(uv.x * dv) / dv, roundf(uv.y * dv) / dv)
	return skew_pt(uv)


## 斜坐標 ↔ 畫布坐標
func skew_uv(w: Vector2) -> Vector2:
	var o := _v(pick_skew.o)
	var a := _v(pick_skew.a)
	var b := _v(pick_skew.b)
	var d := w - o
	var det := a.x * b.y - a.y * b.x
	return Vector2((d.x * b.y - d.y * b.x) / det, (a.x * d.y - a.y * d.x) / det)


func skew_pt(uv: Vector2) -> Vector2:
	return _v(pick_skew.o) + _v(pick_skew.a) * uv.x + _v(pick_skew.b) * uv.y


var drag_free := true             # false：只能拖題目給的那一支（不能自己畫）


func drag_on(fixed: Array, cb: Callable) -> void:
	drag_arrow = {}
	drag_start = ""
	drag_free = fixed.size() != 2
	if fixed.size() == 2:
		_make_drag(String(fixed[0]), String(fixed[1]))
	_input_on("drag", cb)


func place_on(cfg: Dictionary, cb: Callable) -> void:
	place_cfg = cfg
	place_p = _v(cfg.start) if cfg.has("start") else Vector2(INF, INF)
	_input_on("place", cb)


func weigh_on(cfg: Dictionary) -> void:
	weigh = cfg.duplicate()
	weigh["wb"] = int(cfg.get("wb0", 1))
	weigh["wc"] = int(cfg.get("wc0", 1))
	mode = "weigh"
	queue_redraw()


func path_on(from: Vector2, to: Vector2) -> void:
	path_from = from
	path_to = to
	path_segs = []
	mode = "path"
	queue_redraw()


## 鋪到哪裡了
func path_end() -> Vector2:
	var p := path_from
	for s in path_segs:
		p += s
	return p


func path_pts() -> Array:
	var out := [[path_from.x, path_from.y]]
	var p := path_from
	for s in path_segs:
		p += s
		out.append([p.x, p.y])
	return out


func _make_drag(s: String, e: String) -> void:
	var a: Vector2 = named[s]
	var b: Vector2 = named[e]
	drag_arrow = {"a": a, "b": b, "oa": a, "ob": b, "src": s + e}


## 燈亮不亮（拖點）：lit 是 "all"（哪裡都亮）或一串點
func place_lit(p: Vector2) -> bool:
	if not is_finite(p.x):
		return false
	var lit = place_cfg.get("lit", [])
	if lit is String and lit == "all":
		return true
	for q in lit:
		if _v(q).is_equal_approx(p):
			return true
	return false


## 秤桿平衡了沒：wb × \ol{BP} = wc × \ol{PC}
func weigh_torque() -> float:
	if weigh.is_empty():
		return 0.0
	var b := _v(weigh.b)
	var c := _v(weigh.c)
	var p := _v(weigh.p)
	return float(weigh.wb) * b.distance_to(p) - float(weigh.wc) * c.distance_to(p)


# ================= 後果動畫 =================

func fx_merge(id: String, ok: bool) -> void:
	vfx.append({"k": "merge", "id": id, "ok": ok, "t0": t})
	if ok:
		merged.append(id)


func fx_ribbon(pts: Array, col := "gold", fill := true) -> void:
	vfx.append({"k": "ribbon", "pts": pts, "c": col, "t0": t, "fill": fill})


func fx_walk(pts: Array, bad: bool, col := "gold", target = null) -> void:
	var sh := {"k": "walk", "pts": pts, "c": col, "arrows": false, "bad": bad, "t0": t, "fx": true}
	if target != null:
		sh["target"] = target
	vfx.append(sh)


func fx_x(p: Vector2) -> void:
	vfx.append({"k": "x", "p": p, "t0": t})


# ================= 輸入 =================

func _gui_input(e: InputEvent) -> void:
	if mode == "" or mode == "weigh" or mode == "path":
		super(e)
		return
	if _view_input(e):
		accept_event()
		return
	var press: bool = e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed
	var release: bool = e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed
	var motion: bool = e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	match mode:
		"arrows":
			if press:
				var id := _arrow_at(e.position)
				if id != "" and _cb.is_valid():
					_cb.call(id)
				accept_event()
		"pts":
			if e is InputEventMouseMotion:
				hover_p = _snap_pick(from_px(e.position))
			if press:
				var p := _snap_pick(from_px(e.position))
				hover_p = p
				if _cb.is_valid():
					_cb.call(p)
				accept_event()
		"place":
			if press or motion:
				var w := from_px(e.position)
				var p := Vector2(roundf(w.x), roundf(w.y))
				var wr := _world()
				p.x = clampf(p.x, ceilf(wr.position.x), floorf(wr.end.x))
				p.y = clampf(p.y, ceilf(wr.position.y + 0.3), floorf(wr.end.y))
				if not p.is_equal_approx(place_p):
					place_p = p
					if _cb.is_valid():
						_cb.call(p)
				accept_event()
		"drag":
			_drag_input(e, press, release, motion)


func _drag_input(e: InputEvent, press: bool, release: bool, motion: bool) -> void:
	if press:
		# 點兩個點畫一支新的箭頭（點在點上優先；要拖箭頭就抓箭頭的中間）
		var nm := _named_at(e.position) if drag_free else ""
		if nm == "" and not drag_arrow.is_empty() and _seg_dist(e.position, _to(drag_arrow.a), _to(drag_arrow.b)) < 18.0:
			_dragging = true
			_drag_off = from_px(e.position) - Vector2(drag_arrow.a)
			accept_event()
			return
		if nm != "":
			if drag_start == "" or drag_start == nm:
				drag_start = nm
			else:
				_make_drag(drag_start, nm)
				drag_start = ""
		accept_event()
		return
	if motion and _dragging:
		var w := from_px(e.position) - _drag_off
		var d: Vector2 = Vector2(drag_arrow.ob) - Vector2(drag_arrow.oa)
		drag_arrow.a = w
		drag_arrow.b = w + d
		accept_event()
		return
	if release and _dragging:
		_dragging = false
		var d: Vector2 = Vector2(drag_arrow.ob) - Vector2(drag_arrow.oa)
		# 起點吸附到最近的點，頭尾都落在點上才算
		var s := _nearest_named(Vector2(drag_arrow.a), 0.45)
		var en := _nearest_named(Vector2(drag_arrow.a) + d, 0.45) if s != "" else ""
		if s != "" and en != "" and named[s] + d == named[en] and s + en != String(drag_arrow.src):
			drag_arrow.a = named[s]
			drag_arrow.b = named[en]
			if _cb.is_valid():
				_cb.call({"from": String(drag_arrow.src), "to": s + en})
		else:
			drag_arrow.a = drag_arrow.oa
			drag_arrow.b = drag_arrow.ob
		accept_event()


## 拖好之後：這一對記下來，箭頭回到原位（同一支可以再拖去找別的）
func drag_found(from: String, to: String) -> void:
	found_pairs.append([from, to])
	vfx.append({"k": "pair", "a": named[to[0]], "b": named[to[1]], "a0": named[from[0]], "b0": named[from[1]], "t0": t})
	drag_arrow.a = drag_arrow.oa
	drag_arrow.b = drag_arrow.ob


func _nearest_named(w: Vector2, tol: float) -> String:
	var best := ""
	var bd := tol
	for k in named.keys():
		var d: float = (named[k] as Vector2).distance_to(w)
		if d < bd:
			bd = d
			best = k
	return best


func _named_at(sp: Vector2) -> String:
	var best := ""
	var bd := 16.0
	for k in named.keys():
		var d := _to(named[k]).distance_to(sp)
		if d < bd:
			bd = d
			best = k
	return best


func _arrow_at(sp: Vector2) -> String:
	var best := ""
	var bd := 16.0
	for sh in data.get("shapes", []):
		if String(sh.get("k", "")) != "arrow" or not sh.has("id") or not _vis(sh) or String(sh.id) == ref_id:
			continue
		var d := _seg_dist(sp, _to(_v(sh.a)), _to(_v(sh.b)))
		if d < bd:
			bd = d
			best = String(sh.id)
	return best


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


func _shape_by_id(id: String) -> Dictionary:
	for sh in data.get("shapes", []):
		if String(sh.get("id", "")) == id:
			return sh
	return {}


# ================= 會動的圖層（滑桿） =================

func eval_line(ln: Dictionary, vals: Dictionary) -> Dictionary:
	var kk := String(ln.get("k", "line"))
	if kk in ["arrow", "poly", "walk", "balloon", "tag", "label", "kite", "skew", "beam", "ruler", "plant"]:
		if ln.has("when") and absf(calc(String(ln.when), vals)) < 0.5:
			return {}
		var out := ln.duplicate(true)
		for key in ["p", "a", "b", "o"]:
			if ln.has(key):
				out[key] = [calc(str(ln[key][0]), vals), calc(str(ln[key][1]), vals)]
		if ln.has("pts"):
			var arr := []
			for q in ln.pts:
				arr.append([calc(str(q[0]), vals), calc(str(q[1]), vals)])
			out["pts"] = arr
		if ln.has("r"):
			out["r"] = calc(str(ln.r), vals)
		out.erase("at")
		return out
	return super(ln, vals)


# ================= 繪圖 =================

func _draw_grid(font: Font) -> void:
	match String(data.get("grid", "plain")):
		"axes":
			super(font)
		"none":
			pass
		_:
			var wr := _world()
			for ix in range(int(ceilf(wr.position.x)), int(floorf(wr.end.x)) + 1):
				draw_line(_to(Vector2(ix, wr.position.y)), _to(Vector2(ix, wr.end.y)), Color(1, 1, 1, 0.06), 1.0)
			for iy in range(int(ceilf(wr.position.y)), int(floorf(wr.end.y)) + 1):
				draw_line(_to(Vector2(wr.position.x, iy)), _to(Vector2(wr.end.x, iy)), Color(1, 1, 1, 0.06), 1.0)


func _draw_geo(font: Font) -> void:
	super(font)
	_draw_modes(font)
	_draw_vfx(font)


## 箭頭：畫面上的位置 sa → sb
func _arrow_px(sa: Vector2, sb: Vector2, col: Color, w := 3.0, glow := 0.0, dash := false) -> void:
	var d := sb - sa
	var L := d.length()
	if L < 2.0:
		UITheme.dot(self, sa, 3.0, col)
		return
	var u := d / L
	var n := Vector2(-u.y, u.x)
	var hl := minf(13.0, L * 0.45)
	var base := sb - u * hl
	if glow > 0.01:
		draw_line(sa, sb, Color(col.r, col.g, col.b, 0.22 * glow), w + 7.0, true)
	if dash:
		_pl(PackedVector2Array([sa, base]), col, w, true)
	else:
		draw_line(sa, base + u * 1.5, col, w, true)
	draw_colored_polygon(PackedVector2Array([sb, base + n * hl * 0.42, base - n * hl * 0.42]), col)


func _arrow_label(font: Font, sa: Vector2, sb: Vector2, s: String, col: Color, side: float, at := 0.5) -> void:
	if s == "":
		return
	var d := sb - sa
	if d.length() < 2.0:
		return
	var u := d.normalized()
	var n := Vector2(u.y, -u.x) * side       # side = 1：箭頭前進方向的左手邊
	_label(font, sa.lerp(sb, at) + n * 16.0, s, [0, 0], col, true)


func _kite(p: Vector2, ang: float, col: Color, sc := 1.0) -> void:
	var up := Vector2(0, -1).rotated(ang)
	var rt := Vector2(1, 0).rotated(ang)
	var top := p + up * 13.0 * sc
	var bot := p - up * 17.0 * sc
	var l := p - rt * 9.0 * sc
	var r := p + rt * 9.0 * sc
	draw_colored_polygon(PackedVector2Array([top, r, bot, l]), col)
	draw_colored_polygon(PackedVector2Array([top, r, p]), col.lightened(0.35))
	draw_line(top, bot, Color(1, 1, 1, 0.5), 1.0, true)
	draw_line(l, r, Color(1, 1, 1, 0.5), 1.0, true)
	var tail := PackedVector2Array()
	for k in 7:
		tail.append(bot - up * k * 4.0 * sc + rt * sin(t * 6.0 + k) * 3.0 * sc)
	draw_polyline(tail, Color(col.r, col.g, col.b, 0.7), 1.2, true)


## 風箏沿著折線飛：k 是 0～1（整段的進度）
func _draw_walk(font: Font, sh: Dictionary, k: float) -> void:
	var pts: Array = sh.pts
	if pts.size() < 2:
		return
	var col := _col(String(sh.get("c", "gold")))
	var n := pts.size() - 1
	var prog := k * n
	var tip := _to(_v(pts[0]))
	var dir := Vector2.UP
	for i in n:
		var a := _to(_v(pts[i]))
		var b := _to(_v(pts[i + 1]))
		var f := clampf(prog - i, 0.0, 1.0)
		if f <= 0.0:
			break
		var e := a.lerp(b, f)
		if bool(sh.get("arrows", true)):
			_arrow_px(a, e, col, 3.0, 0.6)
		else:
			_pl(PackedVector2Array([a, e]), Color(col.r, col.g, col.b, 0.55), 1.6, true)
		tip = e
		if (b - a).length() > 1.0:
			dir = (b - a).normalized()
	var fin := k >= 1.0
	var bad: bool = sh.get("bad", false)
	var ang := clampf(dir.x * 0.5, -0.6, 0.6)
	var kp := tip + Vector2(0, -6)
	if fin and bad:
		# 打轉掉下來
		var age := t - float(sh.get("_end", t))
		if not sh.has("_end"):
			sh["_end"] = t
		ang = age * 9.0
		kp += Vector2(0, minf(age, 1.2) * 30.0)
		var xp := _to(_v(pts[n]))
		var xc := UITheme.BAD
		draw_line(xp + Vector2(-8, -8), xp + Vector2(8, 8), xc, 3.0, true)
		draw_line(xp + Vector2(-8, 8), xp + Vector2(8, -8), xc, 3.0, true)
		if sh.has("target"):
			_pl(PackedVector2Array([xp, _to(_v(sh.target))]), Color(1, 0.85, 0.45, 0.7), 2.0, true)
	elif fin:
		UITheme.dot(self, tip, 12.0 + 3.0 * sin(t * 4.0), Color(col.r, col.g, col.b, 0.18))
	_kite(kp, ang, col.lightened(0.15))


func _shape(sh: Dictionary, o: Vector2, rot: float, font: Font) -> void:
	match String(sh.get("k", "")):
		"arrow":
			var col := _col(String(sh.get("c", "cyan")))
			var sa := _to(o + _v(sh.a))
			var sb := _to(o + _v(sh.b))
			var id := String(sh.get("id", ""))
			var glow := 0.0
			if id != "" and (id == ref_id and mode == "arrows" or merged.has(id)):
				glow = 0.6 + 0.3 * sin(t * 3.0)
			if merged.has(id):
				col = Color(col.r, col.g, col.b, 0.35)
			_arrow_px(sa, sb, col, float(sh.get("w", 3.0)), glow, bool(sh.get("dash", false)))
			_arrow_label(font, sa, sb, String(sh.get("s", "")), col, float(sh.get("ls", 1.0)), float(sh.get("lt", 0.5)))
			return
		"skew":
			var oo := _v(sh.o)
			var a := _v(sh.a)
			var b := _v(sh.b)
			var dv := maxi(1, int(sh.get("div", 1)))
			var col := _col(String(sh.get("c", "cyan")))
			var ir: Array = sh.get("i", [-3, 3])
			var jr: Array = sh.get("j", [-3, 3])
			for q in range(int(ir[0]) * dv, int(ir[1]) * dv + 1):
				var main := q % dv == 0
				var p0 := oo + a * (float(q) / dv) + b * float(jr[0])
				var p1 := oo + a * (float(q) / dv) + b * float(jr[1])
				draw_line(_to(p0), _to(p1), Color(col.r, col.g, col.b, 0.22 if main else 0.08), 1.2 if main else 1.0, true)
			for q in range(int(jr[0]) * dv, int(jr[1]) * dv + 1):
				var main := q % dv == 0
				var p0 := oo + b * (float(q) / dv) + a * float(ir[0])
				var p1 := oo + b * (float(q) / dv) + a * float(ir[1])
				draw_line(_to(p0), _to(p1), Color(col.r, col.g, col.b, 0.22 if main else 0.08), 1.2 if main else 1.0, true)
			return
		"walk":
			var per := float(sh.get("dur", 0.55))
			var shc := sh.duplicate()
			shc["dur"] = per * maxi(1, (sh.pts as Array).size() - 1)
			_draw_walk(font, sh, _anim_k(shc))
			return
		"balloon":
			var p := _to(_v(sh.p))
			var col := _col(String(sh.get("c", "pink")))
			if sh.has("pop") and stage >= int(sh.pop):
				var key := "pop" + str(sh.p)
				if not _anim0.has(key):
					_anim0[key] = t
				var age := t - float(_anim0[key])
				if age < 0.6:
					for k in 8:
						var ang := TAU * k / 8.0
						var r := 8.0 + age * 50.0
						UITheme.dot(self, p + Vector2(cos(ang), sin(ang)) * r, 3.0 * (1.0 - age / 0.6), col)
				return
			var bob := sin(t * 2.0 + p.x) * 2.0
			var c := p + Vector2(0, -10 + bob)
			var pts := PackedVector2Array()
			for k in 25:
				var ang := TAU * k / 24.0
				pts.append(c + Vector2(cos(ang) * 9.0, sin(ang) * 11.0))
			draw_colored_polygon(pts, col)
			UITheme.dot(self, c + Vector2(-3, -4), 2.5, Color(1, 1, 1, 0.55))
			draw_line(c + Vector2(0, 11), p + Vector2(0, 6), Color(1, 1, 1, 0.45), 1.0, true)
			if String(sh.get("s", "")) != "":
				_label(font, c, String(sh.s), [12, -8], col)
			return
		"beam":
			# 光束：從 a 往 b 的方向一直射到畫布邊緣（出現的時候慢慢射出去）
			var a := _to(_v(sh.a))
			var d := (_to(_v(sh.b)) - a).normalized()
			var far := a + d * (size.length() * float(sh.get("len", 1.0)))
			var k := _anim_k(sh) if sh.has("at") else 1.0
			var e := a.lerp(far, k)
			var col := _col(String(sh.get("c", "gold")))
			draw_line(a, e, Color(col.r, col.g, col.b, 0.16), 10.0, true)
			draw_line(a, e, Color(col.r, col.g, col.b, 0.85), 2.2, true)
			return
		"ruler":
			# 刻度尺：a 到 b 分成 n 格，前 m 格亮起來
			var a := _to(_v(sh.a))
			var b := _to(_v(sh.b))
			var n := maxi(1, int(sh.get("n", 2)))
			var m := int(sh.get("m", 0))
			var col := _col(String(sh.get("c", "gold")))
			var nr := (b - a).normalized().orthogonal() * 6.0
			for i in n:
				var p0 := a.lerp(b, float(i) / n)
				var p1 := a.lerp(b, float(i + 1) / n)
				var c := col if i < m else Color(1, 1, 1, 0.55)
				draw_line(p0 + nr * 0.6, p1 + nr * 0.6, c, 3.0, true)
			for i in n + 1:
				var p := a.lerp(b, float(i) / n)
				draw_line(p - nr + nr * 0.6, p + nr + nr * 0.6, Color(1, 1, 1, 0.8), 1.5, true)
			return
		"plant":
			# 種子：grow 長出稻子、edge 卡在田埂上、dead 長不出來
			var p := _to(_v(sh.p))
			var stt := String(sh.get("state", "grow"))
			var k := _anim_k(sh) if sh.has("at") else 1.0
			if stt == "grow":
				for j in 5:
					var ang := -PI / 2.0 + (j - 2) * 0.28
					var tip := p + Vector2.from_angle(ang) * 18.0 * k
					draw_line(p, tip, Color(0.6, 0.85, 0.35), 2.0, true)
					UITheme.dot(self, tip, 2.4 * k, Color(1.0, 0.85, 0.45))
			elif stt == "edge":
				UITheme.dot(self, p, 5.0, Color(0.85, 0.7, 0.45))
				draw_arc(p, 9.0, 0.0, TAU, 20, Color(1, 1, 1, 0.5), 1.2, true)
			else:
				UITheme.dot(self, p, 4.5, Color(0.55, 0.4, 0.3))
				draw_line(p + Vector2(-6, -6), p + Vector2(6, 6), Color(0.6, 0.3, 0.25), 2.0, true)
			if String(sh.get("s", "")) != "":
				_label(font, p, String(sh.s), [8, 12], Color(1, 0.9, 0.7))
			return
		"tag":
			var p := _to(o + _v(sh.p))
			var col := _col(String(sh.get("c", "text")))
			UITheme.dot(self, p, 3.5, col)
			if String(sh.get("s", "")) != "":
				_label(font, p, String(sh.s), sh.get("off", [7, -7]), col)
			return
	super(sh, o, rot, font)


## 作答模式畫在最上面：拖的箭頭、拖的點、秤桿、鋪的路
func _draw_modes(font: Font) -> void:
	match mode:
		"pts":
			if is_finite(hover_p.x):
				var sp := _to(hover_p)
				UITheme.dot(self, sp, 9.0, Color(1, 0.86, 0.42, 0.25))
				UITheme.dot(self, sp, 4.5, Color(1, 0.86, 0.42, 0.9))
				if not pick_skew.is_empty():
					var uv := skew_uv(hover_p)
					_label(font, sp, "(%s, %s)" % [_fr_s(uv.x), _fr_s(uv.y)], [10, -10], Color(1, 0.86, 0.42))
		"drag":
			if drag_start != "":
				var sp := _to(named[drag_start])
				var ph := fmod(t * 1.4, 1.0)
				draw_arc(sp, 8.0 + 12.0 * ph, 0.0, TAU, 32, Color(1, 0.86, 0.42, 0.7 * (1.0 - ph)), 2.0, true)
			if not drag_arrow.is_empty():
				var sa := _to(Vector2(drag_arrow.a))
				var sb := _to(Vector2(drag_arrow.b))
				if _dragging or not Vector2(drag_arrow.a).is_equal_approx(Vector2(drag_arrow.oa)):
					_arrow_px(_to(Vector2(drag_arrow.oa)), _to(Vector2(drag_arrow.ob)), Color(1, 0.86, 0.42, 0.25), 2.0)
				_arrow_px(sa, sb, UITheme.ACCENT, 3.5, 0.5 + 0.3 * sin(t * 4.0))
		"place":
			var pts: Array = place_cfg.get("poly", [])
			if is_finite(place_p.x) and pts.size() >= 3:
				var poly := PackedVector2Array()
				for nm in pts:
					poly.append(_to(place_p if String(nm) == String(place_cfg.get("label", "D")) else named[nm]))
				var lit := place_lit(place_p)
				var lc := UITheme.ACCENT if lit else Color(1, 1, 1, 0.35)
				var closed := poly.duplicate()
				closed.append(poly[0])
				_pl(closed, lc, 2.0 if lit else 1.4, not lit)
			if is_finite(place_p.x) and place_cfg.has("pull"):
				# 加權拉力：從 P 拉出 w\vec{PQ} 的橡皮筋，再加起來的合力（金色）
				var tot := Vector2.ZERO
				var cols := [UITheme.CYAN, UITheme.PINK, UITheme.LIME, UITheme.VIOLET]
				var k := 0
				for q in place_cfg.pull:
					var v := (Vector2(float(q[0]), float(q[1])) - place_p) * float(q[2])
					tot += v
					var qc: Color = cols[k % cols.size()]
					_arrow_px(_to(place_p), _to(place_p + v), Color(qc.r, qc.g, qc.b, 0.55), 2.0)
					k += 1
				if tot.length() > 1e-6:
					_arrow_px(_to(place_p), _to(place_p + tot), UITheme.ACCENT, 4.0, 0.6)
			if is_finite(place_p.x):
				var sp := _to(place_p)
				UITheme.dot(self, sp, 10.0, Color(1, 0.86, 0.42, 0.25))
				UITheme.dot(self, sp, 6.0, UITheme.ACCENT)
				_label(font, sp, String(place_cfg.get("label", "D")), [9, -9], UITheme.ACCENT)
			_draw_place_lamp(place_lit(place_p))
		"weigh":
			_draw_beam(font)
		"path":
			if is_finite(path_to.x):
				var tp := _to(path_to)
				var ph := fmod(t * 1.2, 1.0)
				draw_arc(tp, 9.0 + 12.0 * ph, 0.0, TAU, 32, Color(1, 0.86, 0.42, 0.7 * (1.0 - ph)), 2.0, true)
			var p := path_from
			for i in path_segs.size():
				var q: Vector2 = p + Vector2(path_segs[i])
				_arrow_px(_to(p), _to(q), UITheme.ACCENT, 3.0, 0.3)
				p = q
			if is_finite(path_from.x):
				_kite(_to(p) + Vector2(0, -8), 0.0, UITheme.ACCENT, 0.8)


## 拖點的燈：右上角，條件成立時亮起來
func _draw_place_lamp(on: bool) -> void:
	var c := Vector2(size.x - 30.0, 30.0)
	if on:
		UITheme.dot(self, c, 22.0 + 2.0 * sin(t * 5.0), Color(1, 0.86, 0.42, 0.22))
	UITheme.dot(self, c, 11.0, Color(1, 0.86, 0.42) if on else Color(0.3, 0.3, 0.38))
	draw_rect(Rect2(c + Vector2(-6, 10), Vector2(12, 7)), Color(0.55, 0.55, 0.62))


## 秤桿：BC 下方一根橫桿，支點在 P 的正下方，兩端掛砝碼；力矩不平衡就往重的那一邊歪
func _draw_beam(font: Font) -> void:
	var b := _to(_v(weigh.b))
	var c := _to(_v(weigh.c))
	var p := _to(_v(weigh.p))
	var y := maxf(b.y, c.y) + 34.0
	var piv := Vector2(p.x, y)
	var tq := weigh_torque()
	var ang := clampf(tq * 0.05, -0.28, 0.28)
	var ok := absf(tq) < 1e-6
	var L1 := Vector2(b.x - p.x, 0).rotated(-ang)
	var L2 := Vector2(c.x - p.x, 0).rotated(-ang)
	var bc := UITheme.ACCENT if ok else Color(0.85, 0.8, 0.7)
	draw_line(piv + L1, piv + L2, bc, 4.0, true)
	draw_colored_polygon(PackedVector2Array([piv, piv + Vector2(-9, 16), piv + Vector2(9, 16)]), Color(0.6, 0.55, 0.5))
	draw_line(p, piv, Color(1, 1, 1, 0.25), 1.0, true)
	for side in [[L1, int(weigh.wb)], [L2, int(weigh.wc)]]:
		var end: Vector2 = piv + Vector2(side[0])
		var n: int = side[1]
		draw_line(end, end + Vector2(0, 14), Color(1, 1, 1, 0.5), 1.0, true)
		var h := 10.0 + 4.0 * n
		var box := Rect2(end + Vector2(-13, 14), Vector2(26, h))
		draw_rect(box, Color(0.45, 0.42, 0.55))
		draw_rect(box, Color(1, 1, 1, 0.3), false, 1.0)
		var s := str(n)
		var fs := UITheme.fs(13)
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, box.get_center() + Vector2(-w / 2.0, fs * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1))
	if ok:
		UITheme.dot(self, p, 14.0 + 2.0 * sin(t * 5.0), Color(1, 0.86, 0.42, 0.25))


func _draw_vfx(font: Font) -> void:
	var keep := []
	for f in vfx:
		var age := t - float(f.t0)
		match String(f.k):
			"merge":
				var sh := _shape_by_id(String(f.id))
				var rf := _shape_by_id(ref_id)
				if sh.is_empty() or rf.is_empty():
					continue
				var d := _v(sh.b) - _v(sh.a)
				var a0 := _v(sh.a)
				var a1 := _v(rf.a)
				var k := 0.0
				if age < 0.5:
					k = age / 0.5
				elif f.ok or age < 1.4:
					k = 1.0
				elif age < 1.9:
					k = 1.0 - (age - 1.4) / 0.5
				else:
					continue
				k = k * k * (3.0 - 2.0 * k)
				var pa := a0.lerp(a1, k)
				var col := UITheme.GOOD if f.ok else UITheme.BAD
				_arrow_px(_to(pa), _to(pa + d), Color(col.r, col.g, col.b, 0.9), 3.5, 0.6)
				keep.append(f)
			"ribbon":
				var life := 3.0 if bool(f.get("fill", true)) else 4.5
				if age > life:
					continue
				var a := clampf(minf(age / 0.4, (life - age) / 0.6), 0.0, 1.0)
				var poly := PackedVector2Array()
				for q in f.pts:
					poly.append(_to(_v(q)))
				var col := _col(String(f.c))
				if bool(f.get("fill", true)):
					draw_colored_polygon(poly, Color(col.r, col.g, col.b, 0.18 * a))
				var closed := poly.duplicate()
				closed.append(poly[0])
				draw_polyline(closed, Color(col.r, col.g, col.b, 0.9 * a), 3.0, true)
				keep.append(f)
			"walk":
				var per := 0.55
				var dur := per * maxi(1, (f.pts as Array).size() - 1)
				if age > dur + 2.5:
					continue
				_draw_walk(font, f, clampf(age / dur, 0.0, 1.0))
				keep.append(f)
			"pair":
				if age > 1.6:
					continue
				var k := clampf(age / 0.6, 0.0, 1.0)
				var a := 1.0 - clampf((age - 1.0) / 0.6, 0.0, 1.0)
				var c := Color(UITheme.GOOD.r, UITheme.GOOD.g, UITheme.GOOD.b, a)
				_arrow_px(_to(Vector2(f.a0).lerp(Vector2(f.a), k)), _to(Vector2(f.b0).lerp(Vector2(f.b), k)), c, 3.5, 0.6)
				keep.append(f)
			"x":
				if age > 1.2:
					continue
				var p := _to(Vector2(f.p))
				var a := 1.0 - age / 1.2
				var xc := Color(UITheme.BAD.r, UITheme.BAD.g, UITheme.BAD.b, a)
				draw_line(p + Vector2(-8, -8), p + Vector2(8, 8), xc, 3.0, true)
				draw_line(p + Vector2(-8, 8), p + Vector2(8, -8), xc, 3.0, true)
				keep.append(f)
	vfx = keep



## 斜坐標的讀數：整數、分數（分母到 12）
static func _fr_s(v: float) -> String:
	for d in range(1, 13):
		var n := v * d
		if absf(n - roundf(n)) < 1e-6:
			var ni := int(roundf(n))
			if d == 1:
				return str(ni).replace("-", "−")
			return "%s%d/%d" % ["−" if ni < 0 else "", absi(ni), d]
	return ("%.2f" % v).replace("-", "−")
