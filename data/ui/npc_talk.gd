extends Control
## NPC 對話框（動物森友會那種）：畫面下方一個對話框，左邊是說話的人的頭像，字一個一個跑出來；
##   點一下／Enter／空白鍵：字還在跑 → 直接全部顯示；跑完了 → 下一句。Esc：結束。說完最後一句自己關掉。
## 用法：NpcTalk.open(父節點, 台詞, 說完要做的事)，回傳這個 Control（地圖把它當 _overlay）。
##   台詞：[{who: 名字, npc: 那位 NPC 的腳本（畫頭像用；光靈說的話沒有）, mood: 表情, text: 句子}, ...]
##   NPC 的表情用它自己腳本的（normal／happy／think／talk），光靈的用 buddy.gd Face 的（normal／happy／surprised……）
## NPC 腳本要有：NAME、TITLE、TALKS {故事: [[說話的人, 表情, 句子], ...]}、HELLO_FIRST、HELLO、draw()
##   pick_story() 挑故事、story_lines() 組成一次對話的台詞
const UITheme := preload("res://data/ui/game_theme.gd")
const Buddy := preload("res://data/ui/buddy.gd")
const MathLabel := preload("res://data/ui/math_text.gd")

signal finished

const BOX_H := 150.0
const PORTRAIT := 124.0

var lines: Array = []
var index := -1
var typing := false
var done := Callable()
var _label: Label
var _math: Control              # 有數學排版（√{…}、上標、分數）的句子改用 MathLabel 畫（根號才有橫線），淡入代替逐字
var _who: Label
var _who_box: PanelContainer
var _portrait: Portrait
var _face: Control
var _more: Label
var _tw: Tween
var _t := 0.0
var _more_y := 0.0


## NPC 的頭像：圓框裡畫半身（頭和肩膀）
class Portrait extends Control:
	## 圓框裡的半身像：圓形底色當遮罩（clip_children），人畫在子節點 Figure 上，超出圓圈的部分（身體下緣、影子、手）切掉。
	##   不能只用 clip_contents：那是切成方形，圓圈下面的兩個角會露出身體（2026/11/20 使用者回報）
	var mood := "talk"
	var npc = null             # 那位 NPC 的腳本；null：只畫圓框（光靈的頭像疊在上面）
	var t := 0.0
	var _fig: Control
	var _ring: Control

	func _ready() -> void:
		clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		_fig = Control.new()
		_fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fig.draw.connect(_draw_figure)
		add_child(_fig)
		_ring = Control.new()
		_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ring.draw.connect(func(): _ring.draw_arc(size / 2.0, size.x / 2.0 - 2.0, 0, TAU, 64, Color("c98a3e"), 4.0, true))
		add_child(_ring)
		for n in [_fig, _ring]:
			n.size = size

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
		_fig.queue_redraw()
		_ring.queue_redraw()

	func _draw() -> void:
		draw_circle(size / 2.0, size.x / 2.0, Color("f3e6c8") if npc != null else Color("2a2f5a"))

	## 半身像：頭放大到框的一半多，腳底落在框的下緣
	func _draw_figure() -> void:
		if npc == null:
			return
		var c := size / 2.0
		var r := size.x / 2.0
		var s := r * 0.6
		npc.draw(_fig, c + Vector2(0, -r * 0.12 + s * 1.87), s, t, mood)


## 挑一個故事：還沒聽過的先說（隨機）；全部聽過了，就從頭再隨機，但不要跟上一次一樣
static func pick_story(npc, heard: Array, last := "") -> String:
	var left: Array = npc.TALKS.keys().filter(func(k): return not heard.has(k))
	if left.is_empty():
		left = npc.TALKS.keys().filter(func(k): return k != last)
	return String(left[randi() % left.size()])


## 一次對話的全部台詞：開場白（第一次見面自我介紹，之後隨機打招呼）＋一個故事
static func story_lines(npc, story: String, first: bool) -> Array:
	var raw: Array = (npc.HELLO_FIRST if first else npc.HELLO[randi() % npc.HELLO.size()]) + npc.TALKS[story]
	var out: Array = []
	for r in raw:
		var ln := {"who": r[0], "mood": r[1], "text": r[2]}
		if r[0] != "光靈":
			ln["npc"] = npc
		out.append(ln)
	return out


static func open(parent: Control, talk: Array, on_done := Callable()) -> Control:
	var n := new()
	n.lines = talk
	n.done = on_done
	parent.add_child(n)
	return n


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.shared()
	var vs := get_parent_area_size() if get_parent() is Control else Vector2(1152, 648)
	if vs == Vector2.ZERO:
		vs = Vector2(1152, 648)
	# 畫面下方淡淡的暗影，讓對話框比較清楚
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.28)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var box_w := minf(vs.x - 80.0, 900.0)
	var box := Panel.new()
	var sb := UITheme.box(Color("fdf6e6"), 26, Color("c98a3e"), 4, 0)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 14
	box.add_theme_stylebox_override("panel", sb)
	box.position = Vector2((vs.x - box_w) / 2.0, vs.y - BOX_H - 24.0)
	box.size = Vector2(box_w, BOX_H)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	# 頭像（左邊，一半凸出對話框上緣）
	_portrait = Portrait.new()
	_portrait.size = Vector2(PORTRAIT, PORTRAIT)
	_portrait.position = box.position + Vector2(22, -PORTRAIT * 0.42)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	_face = Buddy.Face.new()
	_face.radius = 24.0
	_face.size = Vector2(PORTRAIT, PORTRAIT)
	_face.position = _portrait.position
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.visible = false
	add_child(_face)
	# 名字的小牌子（頭像右邊、對話框上緣）
	_who_box = PanelContainer.new()
	_who_box.add_theme_stylebox_override("panel", UITheme.box(Color("c98a3e"), 14, Color("fdf6e6"), 3, 6))
	_who_box.position = box.position + Vector2(PORTRAIT + 34.0, -22.0)
	_who_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_who_box)
	_who = Label.new()
	_who.add_theme_font_override("font", UITheme.bold_font())
	_who.add_theme_font_size_override("font_size", UITheme.fs(18))
	_who.add_theme_color_override("font_color", Color("fffaf0"))
	_who.add_theme_constant_override("outline_size", 0)
	_who.custom_minimum_size = Vector2(80, 0)
	_who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_who_box.add_child(_who)
	_label = Label.new()
	_label.position = box.position + Vector2(PORTRAIT + 40.0, 30.0)
	_label.size = Vector2(box_w - PORTRAIT - 80.0, BOX_H - 46.0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART      # 中文照標點斷行（「」不會落單在行尾）
	_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_label.add_theme_font_size_override("font_size", UITheme.fs(20))
	_label.add_theme_color_override("font_color", Color("4a3a2a"))
	_label.add_theme_constant_override("outline_size", 0)
	_label.add_theme_constant_override("line_spacing", 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_math = MathLabel.new()
	_math.position = _label.position + Vector2(0, -4)
	_math.max_width = _label.size.x
	_math.size = _label.size

	_math.font_size = UITheme.fs(20)
	_math.color = Color("4a3a2a")
	_math.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_math.visible = false
	add_child(_math)
	# 右下角跳動的 ▼（可以按下一句）
	_more = Label.new()
	_more.text = "▼"
	_more.add_theme_font_size_override("font_size", UITheme.fs(18))
	_more.add_theme_color_override("font_color", Color("c98a3e"))
	_more.position = box.position + Vector2(box_w - 46.0, BOX_H - 40.0)
	_more_y = _more.position.y
	_more.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_more)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)
	_next()


func _process(delta: float) -> void:
	_t += delta
	_more.visible = not typing and index >= 0
	_more.position.y = _more_y + sin(_t * 6.0) * 3.0


## 現在這一句
func say(i: int) -> void:
	var ln: Dictionary = lines[i]
	var who := String(ln.get("who", ""))
	var npc = ln.get("npc", null)
	_who.text = who
	_portrait.npc = npc
	_face.visible = npc == null
	if npc != null:
		_portrait.mood = String(ln.get("mood", "talk"))
	else:
		_face.mood = String(ln.get("mood", "happy"))
		_face.jump()
	var txt := String(ln.text)
	var math := is_math(txt)
	_label.visible = not math
	_math.visible = math
	typing = true
	if _tw:
		_tw.kill()
	_tw = create_tween()
	if math:
		_math.valign_center = txt.count("√{") >= 3     # 疊了好幾層的根號比較高：放在框的中間，橫線才不會頂出框
		_math.text = txt
		_math.modulate.a = 0.0
		_tw.tween_property(_math, "modulate:a", 1.0, 0.35)
	else:
		_label.text = txt
		_label.visible_ratio = 0.0
		_tw.tween_property(_label, "visible_ratio", 1.0, maxf(0.4, txt.length() / 28.0))
	_tw.finished.connect(func(): typing = false)


## 這句有沒有數學排版（要用 MathLabel 畫）
static func is_math(txt: String) -> bool:
	return txt.contains("√{") or txt.contains("^") or txt.contains("\\frac")


func _next() -> void:
	if typing:
		if _tw:
			_tw.kill()
		_label.visible_ratio = 1.0
		_math.modulate.a = 1.0
		typing = false
		return
	index += 1
	if index >= lines.size():
		close()
		return
	say(index)


func close() -> void:
	if is_queued_for_deletion():
		return
	finished.emit()
	if done.is_valid():
		done.call()
	queue_free()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_next()
		accept_event()


func _unhandled_input(e: InputEvent) -> void:
	if not is_visible_in_tree() or not (e is InputEventKey and e.pressed and not e.echo):
		return
	match e.physical_keycode:
		KEY_ESCAPE:
			close()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_next()
		_:
			return
	get_viewport().set_input_as_handled()
