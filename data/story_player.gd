extends Control
## 劇情播放器：上下黑邊、字幕逐字出現、點一下繼續（單元地圖、大地圖的劇情都用它）
const UITheme := preload("game_theme.gd")
const SZ := Vector2(1152, 648)
signal advanced
var title := ""
var bars := 0.0
var t := 0.0
var skipped := false
var typing := false
var _label: Label
var _who: Label
var _face: Control
var _tw: Tween
var _hint_a := 0.0

func _ready() -> void:
	position = Vector2.ZERO
	size = SZ
	mouse_filter = Control.MOUSE_FILTER_STOP
	_who = Label.new()
	_who.add_theme_font_size_override("font_size", UITheme.fs(15))
	_who.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
	var vs := SZ
	_who.position = Vector2(120, vs.y - 104)
	add_child(_who)
	# 光靈說話時，左下角出現光靈的頭像（會穿著扭蛋抽到的裝扮）
	_face = preload("buddy.gd").Face.new()
	_face.radius = 20.0
	_face.mood = "happy"
	_face.position = Vector2(26, vs.y - 112)
	_face.size = Vector2(80, 80)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.visible = false
	add_child(_face)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", UITheme.fs(20))
	_label.add_theme_color_override("font_color", UITheme.TEXT)
	_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_label.position = Vector2(120, vs.y - 80)
	_label.size = Vector2(vs.x - 240, 70)
	add_child(_label)
	var skip := UITheme.ghost_button("略過  ▸▸", 15)
	skip.position = Vector2(vs.x - 120, 14)
	skip.pressed.connect(func():
		skipped = true
		advanced.emit())
	add_child(skip)

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var h := 112.0 * bars
	draw_rect(Rect2(0, 0, SZ.x, 62.0 * bars), Color(0, 0, 0, 0.82))
	draw_rect(Rect2(0, SZ.y - h, SZ.x, h), Color(0, 0, 0, 0.82))
	if title != "" and bars > 0.5:
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, 40), title, HORIZONTAL_ALIGNMENT_CENTER, SZ.x, UITheme.fs(20), Color(1, 0.85, 0.45, bars))
	if not typing and bars > 0.9:
		var a := 0.4 + 0.4 * sin(t * 4.0)
		draw_string(get_theme_default_font(), Vector2(SZ.x - 220, SZ.y - 18), "點一下繼續  ▸", HORIZONTAL_ALIGNMENT_RIGHT, 200, UITheme.fs(15), Color(1, 1, 1, a))

func intro() -> void:
	var tw := create_tween()
	tw.tween_property(self, "bars", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished

func outro() -> void:
	_label.text = ""
	_who.text = ""
	var tw := create_tween()
	tw.tween_property(self, "bars", 0.0, 0.35)
	await tw.finished

func say(text: String, who: String) -> void:
	if skipped:
		return
	_who.text = who
	_label.text = text
	_label.visible_ratio = 0.0
	if _face:
		_face.visible = who == "光靈"
		if _face.visible:
			_face.jump()
	typing = true
	_tw = create_tween()
	_tw.tween_property(_label, "visible_ratio", 1.0, maxf(0.6, text.length() / 22.0))
	_tw.finished.connect(func(): typing = false)
	await advanced

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_next()
		accept_event()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE:
			skipped = true
			advanced.emit()
		else:
			_next()
		get_viewport().set_input_as_handled()

func _next() -> void:
	if typing:
		if _tw:
			_tw.kill()
		_label.visible_ratio = 1.0
		typing = false
		return
	advanced.emit()
