extends "res://tests/test_base.gd"
func _btns(n: Node, out: Array) -> void:
	if n is Button and n.is_visible_in_tree():
		var m = n.get_node_or_null("Math")
		out.append("%s|%s|%s" % [n.text, m.text if m != null else "", n.get_global_rect()])
	for c in n.get_children():
		_btns(c, out)
func _initialize() -> void:
	await setup()
	g.tut = {"basic": true}
	g.cur_unit = "h1line"
	g.grade_pick = "高一"
	g.goto("main_menu.gd")
	await wait(1.0)
	var mm = current_scene
	mm._grade = "高一"
	mm._show_page("levels")
	await wait(1.2)
	await shot("e0_map")
	var out := []
	_btns(current_scene, out)
	print("\n".join(out))
	finish("TMP")
