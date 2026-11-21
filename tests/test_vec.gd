extends "test_base.gd"
## 平面向量的箭頭畫布：用「真的滑鼠事件」作答（test_play 是直接放答案，這裡檢查拖、點、鋪路的操作本身）
##   ・vtap：點相等的箭頭（點錯扣一顆心）
##   ・vdrag：拖 \vec{AB} 疊到 DC；自己點兩點畫箭頭再拖；太早按「找齊了」
##   ・vplace：判斷的時候拖 D 看燈；把 D 拖到燈亮的地方
##   ・vpath：點磁磚鋪路，鋪錯不會過、鋪對會過
##   ・vweigh：掛砝碼，平衡才過
##   ・V3：轉箭頭（ring）、排隊點（vorder）、光點描圓（trace）、拖影子讓竿子站直（pole）
## GODOT=… tests/run_tests.sh vec

const Bank := preload("res://data/levels/vec2/vec1_bank.gd")
const Bank2 := preload("res://data/levels/vec2/vec2_bank.gd")
const Bank3 := preload("res://data/levels/vec2/vec3_bank.gd")

var lv


func _initialize() -> void:
	await setup()
	g.goto("level_vec1_wind.gd")
	await wait(0.8)
	lv = current_scene
	for n in lv.get_children():
		if n is Control and n.mouse_filter == Control.MOUSE_FILTER_STOP and n.get_index() > 3:
			n.queue_free()
	await frames()
	lv.journey_mode = true
	await _check_tap()
	await _check_drag()
	await _check_place()
	await _check_path()
	await _check_weigh()
	# V2：斜格子播種、加權拉力
	g.goto("level_vec2_field.gd")
	await wait(0.8)
	lv = current_scene
	for n in lv.get_children():
		if n is Control and n.mouse_filter == Control.MOUSE_FILTER_STOP and n.get_index() > 3:
			n.queue_free()
	await frames()
	lv.journey_mode = true
	await _check_sow()
	await _check_pull()
	# V3：轉箭頭、排隊點、光點描圓、竿子
	g.goto("level_vec3_sundial.gd")
	await wait(0.8)
	lv = current_scene
	for n in lv.get_children():
		if n is Control and n.mouse_filter == Control.MOUSE_FILTER_STOP and n.get_index() > 3:
			n.queue_free()
	await frames()
	lv.journey_mode = true
	await _check_ring()
	await _check_order()
	await _check_trace()
	await _check_pole()
	finish("VEC")


func _slot(id: String) -> Dictionary:
	for s in Bank.slots() + Bank2.slots() + Bank3.slots():
		if String(s.id) == id:
			return s
	return {}


func _start(id: String, vi: int) -> void:
	var slot := _slot(id)
	lv.rounds = [lv.make_round(slot, slot.variants[vi])]
	lv.ri = 0
	lv._start_round()
	await frames(3)
	if lv.get("intro_block") != null:
		lv._intro_finish()
	await wait(0.4)


func _pl():
	return lv._vp()


## 世界坐標 → 畫布上的位置
func _px(w: Vector2) -> Vector2:
	return _pl()._to(w)


func _press(p: Vector2, down := true) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = p
	_pl()._gui_input(e)


func _move(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	e.position = p
	_pl()._gui_input(e)


func _drag(a: Vector2, b: Vector2) -> void:
	_press(a)
	for k in 6:
		_move(a.lerp(b, (k + 1) / 6.0))
	_press(b, false)
	await frames(2)


func _shape(id: String) -> Dictionary:
	return _pl()._shape_by_id(id)


func _check_tap() -> void:
	await _start("same", 0)
	ok(String(lv.steps[lv.si].kind) == "vtap", "同一陣風：第一步是點箭頭")
	var e0: int = lv.energy
	var q := _shape("q")
	_press((_px(Vector2(q.a[0], q.a[1])) + _px(Vector2(q.b[0], q.b[1]))) / 2.0)
	await frames(2)
	ok(lv.energy == e0 - 1 and lv.si == 0, "點到反向的箭頭：扣一顆心、還在這一步")
	for id in ["p", "t"]:
		var sh := _shape(id)
		_press((_px(Vector2(sh.a[0], sh.a[1])) + _px(Vector2(sh.b[0], sh.b[1]))) / 2.0)
		await frames(2)
	await wait(1.0)
	ok(lv.si == 1, "點到兩支相等的箭頭就過")
	# 從 P 出發：點錯、點對
	var st: Dictionary = lv.steps[1]
	_press(_px(Vector2(0, 0)))
	await frames(2)
	ok(lv.si == 1, "點錯終點不會過")
	_press(_px(Vector2(st.target[0], st.target[1])))
	await frames(2)
	ok(lv.si == 2, "點對終點就過")


func _check_drag() -> void:
	await _start("dex", 0)
	var nm: Dictionary = _pl().named
	var A: Vector2 = nm.A
	var B: Vector2 = nm.B
	var C: Vector2 = nm.C
	var D: Vector2 = nm.D
	# 第一步只能拖 \vec{AB}：點兩點不能畫別的
	_press(_px(B))
	_press(_px(A))
	ok(_pl().drag_start == "" and String(_pl().drag_arrow.src) == "AB", "疊疊看：只能拖題目給的 \\vec{AB}")
	await _drag(_px(A.lerp(B, 0.5)), _px(D.lerp(C, 0.5)))
	await wait(0.9)
	ok(lv.si == 1, "把 \\vec{AB} 拖到 DC 上就過（現在第 %d 步）" % lv.si)
	lv.slot_vals = ["4", "3", "12"]
	lv._fill_submit()
	await frames(3)
	ok(lv.si == 2, "4 × 3 = 12")
	# 自己畫 \vec{BA}，拖到 CD
	_press(_px(B))
	_press(_px(A))
	ok(String(_pl().drag_arrow.get("src", "")) == "BA", "點 B 再點 A 畫出 \\vec{BA}")
	await _drag(_px(B.lerp(A, 0.5)), _px(C.lerp(D, 0.5)))
	ok(lv.vd_found.size() == 2, "找到 \\vec{BA} = \\vec{CD}（共 %d 對）" % lv.vd_found.size())
	# 拖到不是點的地方：彈回去
	await _drag(_px(B.lerp(A, 0.5)), _px(B.lerp(A, 0.5) + Vector2(0.4, 1.3)))
	ok(lv.vd_found.size() == 2 and Vector2(_pl().drag_arrow.a).is_equal_approx(B), "沒對到點就彈回原位")
	# 太早按找齊了
	var e0: int = lv.energy
	lv._custom_go()
	await frames(2)
	ok(lv.si == 2 and lv.energy == e0 - 1, "還沒找齊就按「找齊了」：扣一顆心")
	for pr in [["A", "D", "B", "C"], ["D", "A", "C", "B"]]:
		_press(_px(nm[pr[0]]))
		_press(_px(nm[pr[1]]))
		await _drag(_px(Vector2(nm[pr[0]]).lerp(nm[pr[1]], 0.5)), _px(Vector2(nm[pr[2]]).lerp(nm[pr[3]], 0.5)))
	ok(lv.vd_found.size() == 4, "四對都找到了（%d）" % lv.vd_found.size())
	lv._custom_go()
	await frames(3)
	ok(lv.si == 3, "找齊了就過")


func _check_place() -> void:
	await _start("flag", 0)
	ok(String(lv.steps[0].kind) == "choice" and lv.steps[0].has("sandbox"), "第四根旗桿：判斷時可以拖 D")
	_press(_px(Vector2(-3, 2)))
	await frames(2)
	ok(not _pl().place_lit(_pl().place_p), "\\vec{AB} = \\vec{CD}：平行四邊形的位置燈不亮")
	_press(_px(Vector2(7, 2)))
	await frames(2)
	ok(_pl().place_lit(_pl().place_p), "蝴蝶結的位置燈亮")
	lv._on_answer(int(lv.cur_q.correct))
	await frames(3)
	ok(lv.si == 1 and String(lv.steps[1].kind) == "vplace", "判 ✕ 之後要找反例")
	_press(_px(Vector2(0, 2)))
	lv._custom_go()
	await frames(2)
	ok(lv.si == 1, "燈沒亮的地方不算")
	_press(_px(Vector2(7, 2)))
	lv._custom_go()
	await frames(3)
	ok(lv.si == 2, "拖到燈亮的地方就過")


func _check_path() -> void:
	await _start("detour", 0)
	lv._tile_add(0, 1)
	lv._custom_go()
	await frames(2)
	ok(lv.si == 0, "只鋪 \\vec{AB}：停在別的地方，不會過")
	lv._tile_reset()
	lv._tile_add(1, -1)
	lv._tile_add(0, 1)
	ok(String(lv.vpath_expr.text).contains("−\\vec{AC} + \\vec{AB}"), "鋪好的路寫成 −\\vec{AC} + \\vec{AB}（%s）" % lv.vpath_expr.text)
	lv._custom_go()
	await frames(3)
	ok(lv.si == 1, "−\\vec{AC} + \\vec{AB} 鋪到 B 就過")


func _check_weigh() -> void:
	await _start("bead", 0)
	lv.slide_vals = {"n": 1.0}
	lv._slide_submit()
	await frames(3)
	ok(lv.si == 1 and String(lv.steps[1].kind) == "vweigh", "拖好珠子，下一步掛砝碼")
	lv._weigh_add("wb", 1)
	lv._custom_go()
	await frames(2)
	ok(lv.si == 1, "B 掛 2、C 掛 1：不平衡")
	lv._weigh_add("wb", 1)
	lv._custom_go()
	await frames(3)
	ok(lv.si == 2, "B 掛 3、C 掛 1：平衡")


func _check_sow() -> void:
	await _start("sow", 0)
	lv._on_answer(int(lv.cur_q.correct))
	await frames(3)
	ok(lv.si == 1 and String(lv.steps[1].kind) == "vpick" and lv.steps[1].has("skew"), "菱形田：第二步是斜格子播種")
	var st: Dictionary = lv.steps[1]
	var tgt := Vector2(float(st.target[0]), float(st.target[1]))
	# 點在目標旁邊一點點：會吸附到斜格子的交點
	_press(_px(tgt) + Vector2(4, -3))
	await frames(2)
	ok(lv.si == 2, "點在斜格子交點附近就吸附、種對了（現在第 %d 步）" % lv.si)
	var e0: int = lv.energy
	var st2: Dictionary = lv.steps[2]
	var wrong := Vector2(float(st2.target[0]), float(st2.target[1])) + Vector2(1.5, 0)
	_press(_px(wrong))
	await frames(2)
	ok(lv.si == 2 and lv.energy == e0 - 1, "種錯地方：扣一顆心、還在這一步")


func _check_pull() -> void:
	await _start("bands", 0)
	var st: Dictionary = lv.steps[0]
	ok(String(st.kind) == "vplace" and st.sandbox.has("pull"), "三條橡皮筋：拖 P 的沙盒有拉力")
	_press(_px(Vector2(-1, 2)))
	lv._custom_go()
	await frames(2)
	ok(lv.si == 0, "合力不是 0 的地方不算")
	_press(_px(Vector2(float(st.ans[0]), float(st.ans[1]))))
	ok(_pl().place_lit(_pl().place_p), "拖到平衡點燈亮")
	lv._custom_go()
	await frames(3)
	ok(lv.si == 1, "平衡就過")


func _check_ring() -> void:
	await _start("turn", 0)
	var st: Dictionary = lv.steps[0]
	ok(String(st.kind) == "vplace" and st.sandbox.has("ring"), "轉動的影子：第一步是轉箭頭")
	# 點在 (3, 3) 的方向：吸附到圓上 45°
	_press(_px(Vector2(3, 3)))
	var p: Vector2 = _pl().place_p
	ok(absf(p.length() - 2.0) < 1e-4 and absf(p.x - p.y) < 1e-4, "點在斜上方：箭頭轉到 45°、長度不變（%s）" % str(p))
	lv._custom_go()
	await frames(2)
	ok(lv.si == 0, "45° 的內積不是最大，不會過")
	_press(_px(Vector2(5, 0.2)))
	ok(_pl().place_lit(_pl().place_p), "轉到 0° 燈亮")
	lv._custom_go()
	await frames(3)
	ok(lv.si == 1, "內積最大就過")
	_press(_px(Vector2(-0.1, -3)))
	lv._custom_go()
	await frames(3)
	ok(lv.si == 2, "轉到 270°：內積是 0 也算")


func _check_order() -> void:
	await _start("queue", 0)
	lv._on_answer(int(lv.cur_q.correct))
	await frames(3)
	ok(lv.si == 1 and String(lv.steps[1].kind) == "vorder", "影子排隊：第二步是照順序點頂點")
	var order: Array = lv.steps[1].order
	var e0: int = lv.energy
	_press(_px(Vector2(float(order[1][0]), float(order[1][1]))))
	await frames(2)
	ok(lv.vo_i == 0 and lv.energy == e0 - 1, "先點第二名：扣一顆心")
	for o in order:
		_press(_px(Vector2(float(o[0]), float(o[1]))))
		await frames(2)
	await wait(0.9)
	ok(lv.si == 2, "照順序點完就過（現在第 %d 步）" % lv.si)


func _check_trace() -> void:
	await _start("dialcircle", 0)
	var st: Dictionary = lv.steps[0]
	ok(String(st.goal) == "trace", "日晷的圓：找光點")
	_press(_px(Vector2(1, 1)))
	_press(_px(Vector2(5, 0)), false)
	_press(_px(Vector2(5, 0)))
	_press(_px(Vector2(3, 4)))
	lv._custom_go()
	await frames(2)
	ok(lv.si == 0 and _pl().trace_pts.size() == 2, "找到 2 個還不夠（%d）" % _pl().trace_pts.size())
	for q in [Vector2(0, 5), Vector2(-4, -3)]:
		_press(_px(q))
		await frames(1)
	await wait(0.8)
	ok(lv.si == 1, "找到 4 個光點就過")


func _check_pole() -> void:
	await _start("pole", 0)
	_press(_px(Vector2(2, 4)))
	ok(not _pl().place_lit(_pl().place_p), "F 在 (2, 4)：竿子歪的")
	_press(_px(Vector2(3.2, 5.7)))
	ok(_pl().place_p.is_equal_approx(Vector2(3, 6)), "F 只能沿著 \\vec{b} 的直線吸附（%s）" % str(_pl().place_p))
	ok(_pl().place_lit(_pl().place_p), "F 在 (3, 6)：竿子站直")
	lv._custom_go()
	await frames(3)
	ok(lv.si == 1, "竿子站直就過")
