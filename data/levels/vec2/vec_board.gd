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
##       {"k": "shadow", "o": [x, y], "a": [x, y], "g": [x, y], "area": 長方形的高（0 不畫）, "ground": true, "s": 影子的標籤}
##            影子（V3）：箭頭 o → a 在「過 o、方向 g」的地面上的正射影。陽光（虛線）從 a 垂直照到地面，
##            影子和 g 同方向是金色、反方向是紫色；area：地面另一邊畫出影子 × 高的長方形（內積的面積）
##       {"k": "expand", "p": [x, y]（左上角）, "rows": [列名], "cols": [行名], "cells": [[格子裡的字]], "sg": [[1 / −1 / 0]], "at": n}
##            展開田（V3）：兩支向量各拆成幾項，每一格是一項的乘積：正的金色、負的紫色、0 變暗
##       {"k": "right", "p", "u", "v"} 直角記號（滑桿的 lines 裡也可以放，搭配 "when"）
##   ・作答模式（level 呼叫）：
##       arrows_on(cb)        點箭頭（vtap）：點到有 id 的箭頭，cb.call(id)
##       pts_on(snap, cb)     點一個點（vpick）：吸附到格子點，cb.call(Vector2)
##       drag_on(named, fixed, cb)  拖箭頭平移（vdrag）：沒有 fixed 時先點兩個點畫一支，放開時頭尾都落在點上，cb.call({from, to})
##       place_on(cfg, cb)    拖一個點（vsandbox）：吸附到格子點，cb.call(Vector2)；cfg.lit 決定燈亮不亮
##            cfg.lit 也可以是算式（x、y 是點的坐標，例如 "abs(x * 4) < 0.01"）
##            cfg.ring = {o, r, step, a0}：只能在圓上轉（箭頭長度不變），從 a0 度起每 step 度吸附一次
##            cfg.on = {o, d, step}：只能沿著直線 o + k·d 拖，k 每 step 吸附一次
##            cfg.arrow = {o, c, s}：從 o 畫一支箭頭到拖的點；cfg.shadow = {o, g, area}：那支箭頭的影子
##            cfg.pole = {o, a}：影子＋竿子（拖的點是影子的頭 F：o → F 是影子、F → a 是竿子，垂直時亮直角）
##            cfg.trace = true：燈亮的位置留下光點（trace_pts）；cfg.read：左上角的讀數（{…} 裡是 x、y 的算式）
##            cfg.protractor = {o, r, a0, side}：量角器（V4）：a0 是底邊的方向（度），side = 1 往逆時針量、−1 往順時針
##            cfg.sum = {o}：從 o 畫一支金色箭頭到拖的點（首尾相接的和，V4）
##            cfg.ropes = [[x, y], …]：從拖的點拉繩子到那幾點，標長度（V5 外心）
##            cfg.feet = [[a, b, c], …]：從拖的點往直線 ax + by + c = 0 畫垂直的竿子，標長度（V5 內心）
##            cfg.split = [A, B, C]：拖的點把三角形分成三塊，塗三種顏色（V5 面積比）
##            cfg.snap = 0.5：吸附到半格
##       {"k": "fire", "p": [x, y], "c": "gold", "s": "G", "off": [dx, dy]}  營火（V5 四心），s 是旁邊的字母
##            cfg.read_at = "tl"／"tr"／"bl"／"br"：讀數放在哪個角落（預設左上；右上會放在燈的下面）
##       {"k": "split", "p": [x, y], "tri": [A, B, C]}  三分花圃的圖層版
##       {"k": "kite", "p": [x, y], "c": "gold", "s": "P"}  一隻風箏（V6，滑桿的 lines 裡跟著 t 飛；光點另外放一個 "trail": true 的點）
##       {"k": "sweep", "p0": [x, y], "d": [x, y], "t0": 數字或 null, "t1": 數字或 null, "ref": [A, B] 或 "ray": [S, 方向], "dur": 1.6}
##            航跡（V6）：光點照 p0 + t·d 從 t0 飛到 t1，null 那一頭飛出畫布畫箭頭；不在 ref 線段（ray 射線）上的光點是紅色
##       {"k": "ellipse", "o": [x, y], "rx": 3, "ry": 2, "c": "gold", "fill": "gold"}  橢圓（V7 的等高線，rx = ry 是圓；滑桿裡 rx、ry 可以寫算式）
##       {"k": "plot", "f": "u * u", "u0": 0, "u1": 3, "cur": "t", "s": "f"}  小函數圖（V7）：右下角的小框，cur 是目前的 u（滑桿裡跟著動）
##         "corner": "tr" 改放右上角（直線的標籤在右下角的時候）
##            cfg.sail = [A, B]：帆（V7）：拖的點和 A、B 張成三角形，塗色（燈亮時金色）
##       {"k": "beads", "a": [x, y], "b": [x, y], "n": 16}  格子點的珠子（V6）：等距的 n 顆，一顆一顆亮起來
##            cfg.mirror = {o, u, len}：鏡岩（V6）：鏡子是 o 到拖的點的直線，入射光沿 u 打到 o，反射光跟著畫（燈亮時金色）
##       {"k": "protractor", "o", "r", "a0", "side", "deg": 正確的角度, "guess": true}  量角器的圖層：指針指在 deg，
##            guess：再畫一支淡淡的指針在先猜的角度（guess_deg）
##       weigh_on(cfg)        秤桿（vweigh）：畫面上的砝碼由 level 改 weigh.wb、weigh.wc
##       path_on(from, to)    鋪路（vpath）：level 改 path_segs
##   ・看得到的後果：fx_merge（箭頭飛過去疊合）、fx_ribbon（彩帶圍成平行四邊形）、fx_walk（風箏飛一段路）
const UITheme := preload("res://data/ui/game_theme.gd")
const InkV := preload("res://data/ui/ink_audit.gd")
const MathV := preload("res://data/ui/math_text.gd")

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
var trace_pts: Array = []         # 光點描圖留下的點
var guess_deg := NAN              # 量角器先猜的角度（這一題做完之前都留著）


func reset(d: Dictionary) -> void:
	super(d)
	named = {}
	for k in d.get("named", {}).keys():
		named[k] = _v(d.named[k])
	vfx = []
	guess_deg = NAN
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
	trace_pts = []
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
	trace_pts = []
	_input_on("place", cb)


## 拖點的位置：吸附到格子點，或圓上（ring）、直線上（on）
func place_snap(w: Vector2) -> Vector2:
	if place_cfg.has("ring"):
		var rg: Dictionary = place_cfg.ring
		var o := _v(rg.o)
		var stp := deg_to_rad(float(rg.get("step", 15.0)))
		var a0 := deg_to_rad(float(rg.get("a0", 0.0)))
		var ang := a0 + roundf(((w - o).angle() - a0) / stp) * stp
		var p := o + Vector2(cos(ang), sin(ang)) * float(rg.r)
		return Vector2(snappedf(p.x, 1e-6), snappedf(p.y, 1e-6))
	if place_cfg.has("on"):
		var on: Dictionary = place_cfg.on
		var o := _v(on.o)
		var d := _v(on.d)
		var stp := float(on.get("step", 1.0))
		var k := roundf((w - o).dot(d) / d.length_squared() / stp) * stp
		return o + d * k
	var sn := float(place_cfg.get("snap", 1.0))
	var p := Vector2(snappedf(w.x, sn), snappedf(w.y, sn))
	var wr := _world()
	p.x = clampf(p.x, ceilf(wr.position.x), floorf(wr.end.x))
	p.y = clampf(p.y, ceilf(wr.position.y + 0.3), floorf(wr.end.y))
	return p


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
	if lit is String:
		return calc(lit, {"x": p.x, "y": p.y}) > 0.5
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


## 一道陽光照下去又淡掉（排隊點點錯的時候）
func fx_ray(a: Vector2, b: Vector2) -> void:
	vfx.append({"k": "ray", "a": a, "b": b, "t0": t})


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
				var p := place_snap(from_px(e.position))
				if not p.is_equal_approx(place_p):
					place_p = p
					if bool(place_cfg.get("trace", false)) and place_lit(p):
						var dup := false
						for q in trace_pts:
							if (q as Vector2).is_equal_approx(p):
								dup = true
						if not dup:
							trace_pts.append(p)
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
	if kk in ["arrow", "poly", "walk", "balloon", "tag", "label", "kite", "skew", "beam", "ruler", "plant", "shadow", "right", "fire", "plot", "ellipse"]:
		if ln.has("when") and absf(calc(String(ln.when), vals)) < 0.5:
			return {}
		var out := ln.duplicate(true)
		for key in ["p", "a", "b", "o", "g", "u", "v"]:
			if ln.has(key):
				out[key] = [calc(str(ln[key][0]), vals), calc(str(ln[key][1]), vals)]
		if ln.has("pts"):
			var arr := []
			for q in ln.pts:
				arr.append([calc(str(q[0]), vals), calc(str(q[1]), vals)])
			out["pts"] = arr
		if ln.has("r"):
			out["r"] = calc(str(ln.r), vals)
		if ln.has("cur"):
			out["cur"] = calc(str(ln.cur), vals)
		for key in ["rx", "ry"]:
			if ln.has(key):
				out[key] = calc(str(ln[key]), vals)
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
		"shadow":
			_draw_shadow(font, _v(sh.o), _v(sh.a), _v(sh.g), sh)
			return
		"expand":
			_draw_expand(font, sh)
			return
		"fire":
			var fc := _col(String(sh.get("c", "gold")))
			_draw_fire(_to(_v(sh.p)), fc, _anim_k(sh) if sh.has("at") else 1.0)
			if String(sh.get("s", "")) != "":
				_label(font, _to(_v(sh.p)), String(sh.s), sh.get("off", [12, 4]), fc)
			return
		"split":
			_draw_split(font, _v(sh.p), sh.tri)
			return
		"protractor":
			_draw_protractor(font, _v(sh.o), float(sh.r), float(sh.get("a0", 0.0)), float(sh.get("side", 1.0)))
			var dg := float(sh.get("deg", -1.0))
			if bool(sh.get("guess", false)) and is_finite(guess_deg):
				_protractor_hand(font, sh, guess_deg, Color(1, 1, 1, 0.45), 2.0)
			if dg >= 0.0:
				var k := _anim_k(sh) if sh.has("at") else 1.0
				var from := guess_deg if bool(sh.get("guess", false)) and is_finite(guess_deg) else dg
				_protractor_hand(font, sh, lerpf(from, dg, k * k * (3.0 - 2.0 * k)), UITheme.ACCENT, 3.5)
			return
		"ellipse":
			# 橢圓（V7 的等高線）：中心 o、半軸 rx、ry（rx = ry 就是圓）
			var eo := _v(sh.o)
			var rx := float(sh.rx)
			var ry := float(sh.get("ry", sh.rx))
			var ec := _col(String(sh.get("c", "gold")))
			var ep := PackedVector2Array()
			for i in 73:
				var a := TAU * i / 72.0
				ep.append(_to(eo + Vector2(rx * cos(a), ry * sin(a))))
			if sh.has("fill"):
				var fc := _col(String(sh.fill))
				draw_colored_polygon(ep.slice(0, 72), Color(fc.r, fc.g, fc.b, float(sh.get("alpha", 0.12))))
			_pl(ep, ec, float(sh.get("w", 2.0)), bool(sh.get("dash", false)))
			return
		"plot":
			_draw_plot(font, sh)
			return
		"kite":
			# 風箏（V6）：跟著滑桿的 t 飛，"s" 是旁邊的字母
			var kp := _to(_v(sh.p))
			var kc := _col(String(sh.get("c", "gold")))
			_kite(kp + Vector2(0, -6), 0.15 * sin(t * 2.0), kc.lightened(0.15))
			if String(sh.get("s", "")) != "":
				_label(font, kp, String(sh.s), sh.get("off", [12, 10]), kc)
			return
		"sweep":
			_draw_sweep(sh)
			return
		"beads":
			# 格子點的珠子（V6）：a 到 b 等距的 n 顆，一顆一顆亮起來
			var a := _v(sh.a)
			var b := _v(sh.b)
			var n := maxi(2, int(sh.get("n", 2)))
			var key := "beads" + str(sh.a) + str(sh.b)
			if not _anim0.has(key):
				_anim0[key] = t
			var age := t - float(_anim0[key])
			var per := float(sh.get("per", 0.12))
			for i in n:
				var q := _to(a.lerp(b, float(i) / (n - 1)))
				var k := clampf((age - per * i) / 0.25, 0.0, 1.0)
				if k <= 0.0:
					UITheme.dot(self, q, 3.0, Color(1, 1, 1, 0.25))
					continue
				UITheme.dot(self, q, 9.0 * k, Color(1, 0.86, 0.42, 0.22))
				UITheme.dot(self, q, 4.0, UITheme.ACCENT)
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
			for q in trace_pts:
				var tp := _to(q)
				UITheme.dot(self, tp, 9.0 + 1.5 * sin(t * 3.0 + tp.x), Color(1, 0.86, 0.42, 0.22))
				UITheme.dot(self, tp, 4.0, UITheme.ACCENT)
			if place_cfg.has("protractor"):
				var pr: Dictionary = place_cfg.protractor
				_draw_protractor(font, _v(pr.o), float(pr.r), float(pr.get("a0", 0.0)), float(pr.get("side", 1.0)))
			if is_finite(place_p.x) and place_cfg.has("split"):
				_draw_split(font, place_p, place_cfg.split)
			if is_finite(place_p.x) and place_cfg.has("sail"):
				# 帆（V7）：拖的點和 sail 的兩點張成三角形，塗色
				var sp := PackedVector2Array([_to(_v(place_cfg.sail[0])), _to(_v(place_cfg.sail[1])), _to(place_p)])
				var lit_s := place_lit(place_p)
				var scol := UITheme.ACCENT if lit_s else UITheme.LIME
				draw_colored_polygon(sp, Color(scol.r, scol.g, scol.b, 0.22))
				var sc := sp.duplicate()
				sc.append(sp[0])
				_pl(sc, Color(scol.r, scol.g, scol.b, 0.8), 2.0, false)
			if is_finite(place_p.x) and place_cfg.has("mirror"):
				_draw_mirror(font, place_cfg.mirror, place_p, place_lit(place_p))
			if is_finite(place_p.x) and place_cfg.has("ropes"):
				for q in place_cfg.ropes:
					var qv := _v(q)
					draw_line(_to(place_p), _to(qv), Color(0.95, 0.8, 0.55, 0.85), 2.0, true)
					_label(font, _to(place_p.lerp(qv, 0.5)), ("%.2f" % place_p.distance_to(qv)).rstrip("0").rstrip("."), [6, -6], Color(0.95, 0.85, 0.6))
			if is_finite(place_p.x) and place_cfg.has("feet"):
				for ln in place_cfg.feet:
					var nv := Vector2(float(ln[0]), float(ln[1]))
					var dd := (nv.dot(place_p) + float(ln[2])) / nv.length_squared()
					var ft := place_p - nv * dd
					_pl(PackedVector2Array([_to(place_p), _to(ft)]), UITheme.CYAN, 2.0, true)
					UITheme.dot(self, _to(ft), 3.5, UITheme.CYAN)
					_label(font, _to(place_p.lerp(ft, 0.5)), ("%.2f" % place_p.distance_to(ft)).rstrip("0").rstrip("."), [6, -6], UITheme.CYAN)
			if is_finite(place_p.x) and place_cfg.has("sum"):
				var so := _v(place_cfg.sum.o)
				_arrow_px(_to(so), _to(place_p), UITheme.ACCENT, 4.0, 0.5)
			if is_finite(place_p.x) and place_cfg.has("shadow"):
				var sd: Dictionary = place_cfg.shadow
				_draw_shadow(font, _v(sd.o), place_p, _v(sd.g), sd)
			if is_finite(place_p.x) and place_cfg.has("arrow"):
				var ad: Dictionary = place_cfg.arrow
				var ac := _col(String(ad.get("c", "pink")))
				var sa := _to(_v(ad.o))
				_arrow_px(sa, _to(place_p), ac, 3.0, 0.3)
				_arrow_label(font, sa, _to(place_p), String(ad.get("s", "")), ac, float(ad.get("ls", 1.0)), 0.6)
			if is_finite(place_p.x) and place_cfg.has("pole"):
				_draw_pole(font, _v(place_cfg.pole.o), place_p, _v(place_cfg.pole.a))
			if is_finite(place_p.x) and not place_cfg.has("arrow"):
				var sp := _to(place_p)
				UITheme.dot(self, sp, 10.0, Color(1, 0.86, 0.42, 0.25))
				UITheme.dot(self, sp, 6.0, UITheme.ACCENT)
				if String(place_cfg.get("label", "D")) != "":
					_label(font, sp, String(place_cfg.get("label", "D")), [9, -9], UITheme.ACCENT)
			elif is_finite(place_p.x):
				UITheme.dot(self, _to(place_p), 9.0, Color(1, 0.86, 0.42, 0.3))
			if is_finite(place_p.x) and place_cfg.has("read"):
				var txt := fill_eq(String(place_cfg.read), {"x": place_p.x, "y": place_p.y})
				var fs := UITheme.fs(15)
				var tw := InkV.math_box(font, 0.0, 0.0, txt, fs).size.x
				var at := String(place_cfg.get("read_at", "tl"))
				var rx := 14.0 if at.ends_with("l") else size.x - tw - 14.0
				var ry := 24.0 if at.begins_with("t") else size.y - 14.0
				if at == "tr":
					ry = 70.0
				_label(font, Vector2(rx, ry), txt, [0, 0], UITheme.ACCENT)
			if not place_cfg.has("protractor"):
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


## 小函數圖（V7）：右下角一個小框，畫 f(u)（u 從 u0 到 u1），目前的 u = cur 是一個點在上面跑
func _draw_plot(font: Font, sh: Dictionary) -> void:
	var box := Rect2(size.x - 176.0, 16.0 if String(sh.get("corner", "")) == "tr" else size.y - 112.0, 160.0, 96.0)
	draw_rect(box, Color(0.05, 0.07, 0.12, 0.82))
	draw_rect(box, Color(1, 1, 1, 0.18), false, 1.0)
	var u0 := float(sh.u0)
	var u1 := float(sh.u1)
	var f := String(sh.f)
	var ys := []
	var lo := INF
	var hi := -INF
	for i in 61:
		var u := lerpf(u0, u1, i / 60.0)
		var y := calc(f, {"u": u})
		ys.append(y)
		lo = minf(lo, y)
		hi = maxf(hi, y)
	if sh.has("ymax"):
		hi = minf(hi, float(sh.ymax))
	if hi - lo < 1e-6:
		hi = lo + 1.0
	var inner := box.grow(-8.0)
	var at := func(u: float, y: float) -> Vector2:
		return Vector2(inner.position.x + (u - u0) / (u1 - u0) * inner.size.x,
			inner.end.y - (clampf(y, lo, hi) - lo) / (hi - lo) * inner.size.y)
	var pts := PackedVector2Array()
	for i in 61:
		pts.append(at.call(lerpf(u0, u1, i / 60.0), float(ys[i])))
	_pl(pts, Color(0.7, 0.85, 1.0, 0.85), 2.0, false)
	if sh.has("cur"):
		var cu := float(sh.cur)
		var cp: Vector2 = at.call(cu, calc(f, {"u": cu}))
		UITheme.dot(self, cp, 9.0, Color(1, 0.86, 0.42, 0.25))
		UITheme.dot(self, cp, 4.5, UITheme.ACCENT)
	if String(sh.get("s", "")) != "":
		_label(font, box.position, String(sh.s), [6, 16], Color(1, 1, 1, 0.7))


## 航跡（V6）：光點照參數式 p0 + t·d 從 t0 飛到 t1（null = 一直飛到畫布外，畫箭頭）
##   ref = [A, B]：不在線段 AB 上的光點是紅色；ray = [S, 方向]：不在這條射線上的是紅色
func _draw_sweep(sh: Dictionary) -> void:
	var p0 := _v(sh.p0)
	var d := _v(sh.d)
	if d.length() < 1e-9:
		return
	var wr := _world().grow(0.6)
	# 飛出畫布的 t（無限的那一頭）
	var t_lo := -1e9
	var t_hi := 1e9
	for ax in 2:
		var dv := d[ax]
		if absf(dv) < 1e-9:
			continue
		var ta := (wr.position[ax] - p0[ax]) / dv
		var tb := (wr.end[ax] - p0[ax]) / dv
		t_lo = maxf(t_lo, minf(ta, tb))
		t_hi = minf(t_hi, maxf(ta, tb))
	var inf0: bool = sh.get("t0") == null
	var inf1: bool = sh.get("t1") == null
	var t0 := t_lo if inf0 else float(sh.t0)
	var t1 := t_hi if inf1 else float(sh.t1)
	var key := "sweep" + str(sh.p0) + str(sh.d) + str(sh.get("t0")) + str(sh.get("t1"))
	if not _anim0.has(key):
		_anim0[key] = t
	var k := clampf((t - float(_anim0[key])) / float(sh.get("dur", 1.6)), 0.0, 1.0)
	var px := d.length() * _scale()
	var n := maxi(2, int(absf(t1 - t0) * px / 11.0))
	var good_c := _col(String(sh.get("c", "gold")))
	var shown := int(floor(n * k))
	for i in shown + 1:
		var q := p0 + d * lerpf(t0, t1, float(i) / n)
		var c := good_c if _sweep_ok(sh, q) else UITheme.BAD
		var sp := _to(q)
		UITheme.dot(self, sp, 6.5, Color(c.r, c.g, c.b, 0.2))
		UITheme.dot(self, sp, 3.2, c)
	# 有限的端點畫一個圈，無限的那一頭畫箭頭
	if not inf0:
		draw_arc(_to(p0 + d * t0), 7.0, 0.0, TAU, 20, Color(1, 1, 1, 0.75), 2.0, true)
	if k >= 1.0:
		if not inf1:
			draw_arc(_to(p0 + d * t1), 7.0, 0.0, TAU, 20, Color(1, 1, 1, 0.75), 2.0, true)
		for e in [[t1, inf1, 1.0], [t0, inf0, -1.0]]:
			if not bool(e[1]):
				continue
			var dirv := d.normalized() * float(e[2])
			var q := p0 + d * float(e[0]) - dirv * 0.5
			var tip := _to(q)
			var back := _to(q - dirv * 0.7)
			var u := (tip - back).normalized()
			var nn := u.orthogonal() * 7.0
			var c := good_c if _sweep_ok(sh, q) else UITheme.BAD
			draw_colored_polygon(PackedVector2Array([tip + u * 5.0, back + nn, back - nn]), c)


func _sweep_ok(sh: Dictionary, q: Vector2) -> bool:
	if sh.has("ref"):
		var a := _v(sh.ref[0])
		var b := _v(sh.ref[1])
		var ab := b - a
		if absf(ab.cross(q - a)) > 1e-6 * maxf(1.0, ab.length()):
			return false
		var s := ab.dot(q - a) / ab.length_squared()
		return s >= -1e-6 and s <= 1.0 + 1e-6
	if sh.has("ray"):
		var a := _v(sh.ray[0])
		var dv := _v(sh.ray[1])
		if absf(dv.cross(q - a)) > 1e-6 * maxf(1.0, dv.length()):
			return false
		return dv.dot(q - a) >= -1e-6
	return true


## 鏡岩（V6）：鏡子是 o 到拖的點的直線，入射光沿 u 打到 o，反射光跟著鏡子轉
func _draw_mirror(font: Font, cfg: Dictionary, tp: Vector2, lit: bool) -> void:
	var o := _v(cfg.o)
	var u := _v(cfg.u).normalized()
	var m := tp - o
	if m.length() < 1e-6:
		return
	m = m.normalized()
	var ln := float(cfg.get("len", 4.0))
	var a := _to(o - m * ln)
	var b := _to(o + m * ln)
	draw_line(a, b, Color(0.75, 0.85, 0.95, 0.25), 9.0, true)
	draw_line(a, b, Color(0.85, 0.92, 1.0, 0.95), 3.0, true)
	var r := m * 2.0 * u.dot(m) - u
	_arrow_px(_to(o - u * ln), _to(o), Color(1, 1, 1, 0.85), 2.5)
	var rc := UITheme.ACCENT if lit else Color(1, 0.6, 0.55, 0.9)
	_arrow_px(_to(o), _to(o + r * ln), rc, 3.0, 0.5 if lit else 0.0)
	_label(font, _to(o - u * ln * 0.55), "\\vec{u}", [10, -10], Color(1, 1, 1, 0.85))


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
			"ray":
				if age > 1.6:
					continue
				var a := clampf(minf(age / 0.3, (1.6 - age) / 0.5), 0.0, 1.0)
				_pl(PackedVector2Array([_to(Vector2(f.a)), _to(Vector2(f.b))]), Color(1, 0.55, 0.5, 0.9 * a), 2.0, true)
				UITheme.dot(self, _to(Vector2(f.b)), 5.0, Color(1, 0.55, 0.5, a))
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



## 有根號的標籤（√13、2√3）用數學排版畫（一般的字會把根號畫壞）
func _label(font: Font, sp: Vector2, s: String, off, c: Color, center := false) -> void:
	if s.contains("√") and not s.contains("\\"):
		if not Rect2(Vector2.ZERO, size).grow(2.0).has_point(sp):
			return
		_math_label(font, sp, s, off, c, center, UITheme.fs(15))
		return
	super(font, sp, s, off, c, center)


## 營火：一團會跳動的火（k：點起來的進度）
func _draw_fire(p: Vector2, col: Color, k := 1.0) -> void:
	var h := 18.0 * k
	UITheme.dot(self, p + Vector2(0, -6), 18.0 * k, Color(col.r, col.g, col.b, 0.16))
	draw_line(p + Vector2(-9, 4), p + Vector2(9, -1), Color(0.5, 0.35, 0.25), 3.0, true)
	draw_line(p + Vector2(-9, -1), p + Vector2(9, 4), Color(0.45, 0.3, 0.22), 3.0, true)
	if h < 1.0:
		return
	for j in 3:
		var sc := 1.0 - 0.28 * j
		var wob := sin(t * 7.0 + j * 1.7) * 2.0
		var tip := p + Vector2(wob, -h * sc - 2.0)
		var c := col.lightened(0.25 * j)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-7 * sc, 0), tip, p + Vector2(7 * sc, 0), p + Vector2(0, 2)]), Color(c.r, c.g, c.b, 0.85))


## 三分花圃：P 把三角形分成 △PBC、△PCA、△PAB 三塊
func _draw_split(font: Font, P: Vector2, tri: Array) -> void:
	var A := _v(tri[0])
	var B := _v(tri[1])
	var C := _v(tri[2])
	var cols := [UITheme.CYAN, UITheme.PINK, UITheme.LIME]
	var parts := [[P, B, C], [P, C, A], [P, A, B]]
	for i in 3:
		var pp: Array = parts[i]
		var poly := PackedVector2Array([_to(pp[0]), _to(pp[1]), _to(pp[2])])
		var c: Color = cols[i]
		if absf((pp[1] - pp[0]).cross(pp[2] - pp[0])) > 1e-6:
			draw_colored_polygon(poly, Color(c.r, c.g, c.b, 0.2))
		draw_line(_to(P), _to(pp[1]), Color(1, 1, 1, 0.45), 1.4, true)


## 量角器：從底邊（a0 度）往 side 那一邊量 0°～180°，每 10° 一個刻度
func _draw_protractor(font: Font, o: Vector2, r: float, a0: float, side: float) -> void:
	var pts := PackedVector2Array()
	for k in 37:
		var ang := deg_to_rad(a0 + side * 5.0 * k)
		pts.append(_to(o + Vector2(cos(ang), sin(ang)) * r))
	var fill := pts.duplicate()
	fill.append(_to(o))
	draw_colored_polygon(fill, Color(0.95, 0.85, 0.55, 0.07))
	draw_polyline(pts, Color(0.95, 0.85, 0.55, 0.55), 1.6, true)
	var b0 := deg_to_rad(a0)
	draw_line(_to(o - Vector2(cos(b0), sin(b0)) * r), _to(o + Vector2(cos(b0), sin(b0)) * r), Color(0.95, 0.85, 0.55, 0.4), 1.4, true)
	for k in 19:
		var ang := deg_to_rad(a0 + side * 10.0 * k)
		var u := Vector2(cos(ang), sin(ang))
		var big := k % 3 == 0
		var p0 := _to(o + u * r)
		var p1 := p0 + (_to(o) - p0).normalized() * (9.0 if big else 5.0)
		draw_line(p0, p1, Color(0.95, 0.85, 0.55, 0.7 if big else 0.4), 1.2, true)


## 量角器的指針和讀數
func _protractor_hand(font: Font, sh: Dictionary, deg: float, col: Color, w: float) -> void:
	var o := _v(sh.o)
	var r := float(sh.r)
	var ang := deg_to_rad(float(sh.get("a0", 0.0)) + float(sh.get("side", 1.0)) * deg)
	var u := Vector2(cos(ang), sin(ang))
	_arrow_px(_to(o), _to(o + u * r * 0.95), col, w, 0.3 if w > 3.0 else 0.0)
	_label(font, _to(o + u * r * 1.12), "%d°" % int(roundf(deg)), [0, 0], col, true)


## 影子：o → h 的箭頭在「過 o、方向 g」的地面上的正射影
func _draw_shadow(font: Font, o: Vector2, h: Vector2, g: Vector2, sh: Dictionary) -> void:
	var gl := g.length()
	if gl < 1e-9:
		return
	var u := g / gl
	var s := (h - o).dot(u)
	var f := o + u * s
	var zero := absf(s) < 1e-6
	var col := UITheme.ACCENT if s > 0.0 else UITheme.VIOLET
	if bool(sh.get("ground", false)):
		var far := size.length() / maxf(_to(o).distance_to(_to(o + u)), 1.0)
		draw_line(_to(o - u * far), _to(o + u * far), Color(0.85, 0.75, 0.55, 0.35), 2.0, true)
	var ah := float(sh.get("area", 0.0))
	if ah > 0.0 and not zero:
		var side := -signf(u.cross(h - o))
		if side == 0.0:
			side = -1.0
		var nrm := Vector2(-u.y, u.x) * side * ah
		var poly := PackedVector2Array([_to(o), _to(f), _to(f + nrm), _to(o + nrm)])
		draw_colored_polygon(poly, Color(col.r, col.g, col.b, 0.16))
		var cl := poly.duplicate()
		cl.append(poly[0])
		draw_polyline(cl, Color(col.r, col.g, col.b, 0.55), 1.4, true)
	if h.distance_to(f) > 1e-6:
		_pl(PackedVector2Array([_to(h), _to(f)]), Color(1.0, 0.93, 0.7, 0.65), 1.5, true)
		if not zero:
			var cp := _to(f)
			var a1 := (_to(f - u * signf(s)) - cp).normalized() * 11.0
			var a2 := (_to(h) - cp).normalized() * 11.0
			_pl(PackedVector2Array([cp + a1, cp + a1 + a2, cp + a2]), Color(1, 1, 1, 0.55), 1.2, false)
	if zero:
		UITheme.dot(self, _to(o), 8.0 + 2.0 * sin(t * 5.0), Color(1, 1, 1, 0.3))
	else:
		draw_line(_to(o), _to(f), Color(col.r, col.g, col.b, 0.28), 11.0, true)
		draw_line(_to(o), _to(f), col, 5.0, true)
	if String(sh.get("s", "")) != "" and not zero:
		var side2 := signf(u.cross(h - o))
		var nr := Vector2(-u.y, u.x) * (-side2 if side2 != 0.0 else -1.0)
		var mid := _to(o.lerp(f, 0.5))
		var off := (_to(o.lerp(f, 0.5) + nr) - mid).normalized() * 16.0
		_label(font, mid + off, String(sh.s), [0, 0], col, true)


## 影子＋竿子：o → f 是影子（\vec{u}），f → a 是竿子（\vec{v}）；竿子垂直地面時亮直角
func _draw_pole(font: Font, o: Vector2, f: Vector2, a: Vector2) -> void:
	var up := (a - f).normalized()
	var ok := f.distance_to(o) > 1e-6 and absf((a - f).dot(f - o)) < 1e-6
	var pc := UITheme.ACCENT if ok else Color(0.85, 0.85, 0.9, 0.8)
	if f.distance_to(o) > 1e-6:
		_arrow_px(_to(o), _to(f), UITheme.ACCENT, 3.5, 0.4)
		_arrow_label(font, _to(o), _to(f), "\\vec{u}", UITheme.ACCENT, -1.0, 0.5)
	if a.distance_to(f) > 1e-6:
		_arrow_px(_to(f), _to(a), pc, 3.0, 0.6 if ok else 0.0)
		_arrow_label(font, _to(f), _to(a), "\\vec{v}", pc, 1.0, 0.5)
	if ok:
		var cp := _to(f)
		var a1 := (_to(o) - cp).normalized() * 13.0
		var a2 := (_to(a) - cp).normalized() * 13.0
		UITheme.dot(self, cp, 14.0 + 2.0 * sin(t * 5.0), Color(1, 0.86, 0.42, 0.22))
		_pl(PackedVector2Array([cp + a1, cp + a1 + a2, cp + a2]), UITheme.ACCENT, 2.0, false)
	UITheme.dot(self, _to(f), 5.0, UITheme.ACCENT)


## 展開田：rows × cols 的格子，每一格是一項乘積（出現時一格一格亮起來）
func _draw_expand(font: Font, sh: Dictionary) -> void:
	var tl := _to(_v(sh.p))
	var cw := float(sh.get("cw", 86.0))
	var chh := float(sh.get("ch", 46.0))
	var hw := float(sh.get("hw", 68.0))
	var rows: Array = sh.rows
	var cols: Array = sh.cols
	var k := _anim_k(sh) if sh.has("at") else 1.0
	var n := rows.size() * cols.size()
	var bg := Rect2(tl - Vector2(4, 4), Vector2(hw + cw * cols.size() + 8, chh * (rows.size() + 1) + 8))
	draw_rect(bg, Color(0.05, 0.06, 0.13, 0.82))
	for j in cols.size():
		_cell_text(font, tl + Vector2(hw + cw * (j + 0.5), chh * 0.5), String(cols[j]), UITheme.TEXT)
	for i in rows.size():
		_cell_text(font, tl + Vector2(hw * 0.5, chh * (i + 1.5)), String(rows[i]), UITheme.TEXT)
		for j in cols.size():
			var idx := i * cols.size() + j
			var a := clampf(k * n - idx, 0.0, 1.0)
			var r := Rect2(tl + Vector2(hw + cw * j, chh * (i + 1)), Vector2(cw, chh)).grow(-2.0)
			var sg := int(sh.sg[i][j])
			var c := UITheme.ACCENT if sg > 0 else (UITheme.VIOLET if sg < 0 else Color(0.35, 0.35, 0.42))
			draw_rect(r, Color(c.r, c.g, c.b, (0.22 if sg != 0 else 0.12) * a))
			draw_rect(r, Color(c.r, c.g, c.b, 0.6 * a), false, 1.2)
			if a > 0.5:
				_cell_text(font, r.get_center(), String(sh.cells[i][j]), c.lightened(0.2) if sg != 0 else Color(0.6, 0.6, 0.68))


## 展開田格子裡的字：置中畫在格子裡（不讓位、不加底色，格子本身就是底）
func _cell_text(font: Font, c: Vector2, s: String, col: Color) -> void:
	var fs := UITheme.fs(15)
	var box := InkV.math_box(font, 0.0, 0.0, s, fs)
	var base := c.y - (box.position.y + box.end.y) / 2.0
	MathV.draw_on(self, font, c.x, base, s, fs, col)


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
