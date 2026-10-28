extends CanvasLayer
## 遊戲中的暫停選單：繼續遊戲／設定／返回關卡列表／返回地圖（Esc 也能開關）。
## 用法：在關卡裡 var pause := PauseMenu.new(); add_child(pause)，暫停按鈕呼叫 pause.open()

const UITheme := preload("game_theme.gd")
const Game := preload("game.gd")
const SettingsPanel := preload("settings_panel.gd")

var _modal: Control = null
var _settings: Control = null
var _confirming := false
var list_action := Callable()   # 關卡設定後，暫停選單會多一個「返回關卡列表」
var list_label := "返回關卡列表"
var report_info := Callable()   # 回傳「現在是哪一題」的文字；有設定時，暫停選單會多一個「回報這一題」


func _init() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_open() -> bool:
	return _modal != null or _settings != null


func open() -> void:
	if is_open():
		return
	get_tree().paused = true
	Game.of(self).duck(true)
	Game.of(self).sfx("open")
	_show_menu(true)


func resume() -> void:
	_clear()
	get_tree().paused = false
	Game.of(self).duck(false)


func _clear() -> void:
	if _modal:
		_modal.queue_free()
		_modal = null


func _show_menu(fade: bool = false) -> void:
	_clear()
	_confirming = false
	var m := UITheme.modal(self, Color(1, 1, 1, 0.14), 340, fade)
	_modal = m[0]
	var col: VBoxContainer = m[1]
	col.add_theme_constant_override("separation", 12)
	col.add_child(UITheme.title_label("暫停", 30, UITheme.ACCENT))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	col.add_child(gap)

	var resume_b := _button("繼續遊戲", 54)
	UITheme.accent_button(resume_b, 20)
	resume_b.pressed.connect(resume)
	col.add_child(resume_b)

	var set_b := _button("設定", 50)
	set_b.pressed.connect(_open_settings)
	col.add_child(set_b)

	if list_action.is_valid():
		var list_b := _button(list_label, 50)
		list_b.pressed.connect(func():
			resume()
			list_action.call())
		col.add_child(list_b)

	if report_info.is_valid():
		var rep_b := _button("回報這一題", 50)
		rep_b.pressed.connect(func(): preload("feedback.gd").open(self, String(report_info.call())))
		col.add_child(rep_b)

	var home_b := _button("返回地圖", 50)
	home_b.pressed.connect(_show_confirm)
	col.add_child(home_b)


func _show_confirm() -> void:
	_clear()
	_confirming = true
	var m := UITheme.modal(self, Color(1, 1, 1, 0.14), 380, false)
	_modal = m[0]
	var col: VBoxContainer = m[1]
	col.add_child(UITheme.title_label("返回地圖？", 26, UITheme.TEXT))
	var d := Label.new()
	d.text = "這一關目前的進度不會保留。"
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	col.add_child(d)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var back := _button("取消", 50)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(_show_menu.bind(false))
	row.add_child(back)
	var go := _button("返回地圖", 50)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var red := UITheme.BAD
	go.add_theme_stylebox_override("normal", UITheme.box(red.darkened(0.45), 12, red.darkened(0.1), 1, 10))
	go.add_theme_stylebox_override("hover", UITheme.box(red.darkened(0.3), 12, red, 2, 10))
	go.pressed.connect(func(): Game.of(self).goto("main_menu.gd", {"page": "levels"}))
	row.add_child(go)


func _open_settings() -> void:
	_clear()
	_settings = SettingsPanel.new()
	_settings.instant = true
	add_child(_settings)
	_settings.closed.connect(func():
		_settings = null
		_show_menu())


func _button(text: String, h: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, h)
	b.add_theme_font_size_override("font_size", UITheme.fs(19))
	return b


func _unhandled_input(e: InputEvent) -> void:
	if not e.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _settings != null:
		return      # 設定視窗自己會處理 Esc
	if _modal == null:
		open()
	elif _confirming:
		_show_menu(false)
	else:
		resume()
