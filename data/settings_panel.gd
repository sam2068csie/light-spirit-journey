extends Control
## 設定視窗：主音量、音樂、音效，以及折疊起來的「開發者功能」（解析度、一鍵開放全部關卡、刪除紀錄）。
## 改動會立刻生效，關閉時存檔。
## 用法：var p := SettingsPanel.new(); add_child(p); p.closed.connect(...)

signal closed

const UITheme := preload("game_theme.gd")
const Game := preload("game.gd")

var _layer: Control
var instant := false        ## true：不播淡入（從另一個視窗切換過來時用）
var _dev_box: VBoxContainer
var _dev_btn: Button
var _res_label: Label
var _unlock_btn: Button
var _fps_btn: Button
var _notify_btn: Button
var _notify_time: Label
var _notify_note: Label
var _scroll: ScrollContainer
var _power_btn: Button
var _inner: VBoxContainer
const MAX_SCROLL_H := 420.0     # 中間可捲動區最高多少（再高就捲動）
static var _dev_open := false    # 開發者功能有沒有展開（這次開遊戲期間記住）


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g = Game.of(self)
	var m := UITheme.modal(self, Color(1, 1, 1, 0.14), 460, not instant)
	_layer = m[0]
	var col: VBoxContainer = m[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(UITheme.title_label("設定", 28, UITheme.ACCENT))

	# 中間的內容可以上下捲動（展開開發者功能後會比螢幕高）；標題和「完成」固定不動
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var vsb := _scroll.get_v_scroll_bar()
	vsb.custom_minimum_size = Vector2(5, 0)
	vsb.add_theme_stylebox_override("scroll", UITheme.box(Color(1, 1, 1, 0.04), 3, Color(0, 0, 0, 0), 0, 0))
	for st in ["grabber", "grabber_highlight", "grabber_pressed"]:
		vsb.add_theme_stylebox_override(st, UITheme.box(Color(1, 1, 1, 0.25), 3, Color(0, 0, 0, 0), 0, 0))
	col.add_child(_scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", 12)
	_scroll.add_child(pad)
	_inner = VBoxContainer.new()
	_inner.add_theme_constant_override("separation", 10)
	_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(_inner)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	_inner.add_child(rows)
	rows.add_child(_volume_row("主音量", "master", g.master_vol))
	rows.add_child(_volume_row("音樂", "music", g.music_vol))
	rows.add_child(_volume_row("音效", "sfx", g.sfx_vol))
	rows.add_child(_notify_row())
	rows.add_child(_power_row())
	# 進度備份說明＋回報問題
	var bk := Label.new()
	#bk.text = "遊戲進度會跟著手機的 Google 備份一起備份：換手機時登入同一個 Google 帳號，重新安裝就能接著玩。"
	bk.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	bk.custom_minimum_size = Vector2(380, 0)
	bk.add_theme_font_size_override("font_size", UITheme.fs(13))
	bk.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	rows.add_child(bk)
	var fb := UITheme.ghost_button("回報問題／給老師建議", 16)
	fb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fb.pressed.connect(func(): preload("feedback.gd").open(self))
	rows.add_child(fb)

	_dev_btn = UITheme.ghost_button("", 16)
	_dev_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_dev_btn.pressed.connect(func():
		_dev_open = not _dev_open
		_refresh_dev())
	_inner.add_child(_dev_btn)
	_dev_box = VBoxContainer.new()
	_dev_box.add_theme_constant_override("separation", 12)
	_inner.add_child(_dev_box)
	_build_dev()
	_refresh_dev()

	var done := Button.new()
	done.text = "完成"
	done.custom_minimum_size = Vector2(0, 48)
	UITheme.accent_button(done, 20)
	done.pressed.connect(close)
	col.add_child(done)


func _volume_row(title: String, kind: String, value: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(72, 0)
	row.add_child(l)
	var s := UITheme.touch_slider()
	s.min_value = 0
	s.max_value = 100
	s.step = 1
	s.value = roundf(value * 100.0)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.custom_minimum_size = Vector2(0, 28)
	UITheme.tint_slider(s, UITheme.ACCENT)
	row.add_child(s)
	var v := Label.new()
	v.custom_minimum_size = Vector2(52, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	v.text = "%d%%" % int(s.value)
	row.add_child(v)
	s.value_changed.connect(func(x):
		v.text = "%d%%" % int(x)
		Game.of(self).set_volume(kind, x / 100.0))
	return row


# ================= 開發者功能 =================

func _build_dev() -> void:
	var g = Game.of(self)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.box(Color(1, 1, 1, 0.04), 14, Color(1, 0.55, 0.6, 0.35), 1, 12))
	_dev_box.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	# 解析度：‹ 1280 × 720 ›
	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 8)
	var rl := Label.new()
	rl.text = "解析度"
	rl.custom_minimum_size = Vector2(72, 0)
	res_row.add_child(rl)
	var prev := _arrow("‹")
	prev.pressed.connect(func(): _step_res(-1))
	res_row.add_child(prev)
	_res_label = Label.new()
	_res_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_res_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_res_label.add_theme_color_override("font_color", UITheme.ACCENT)
	res_row.add_child(_res_label)
	var nxt := _arrow("›")
	nxt.pressed.connect(func(): _step_res(1))
	res_row.add_child(nxt)
	box.add_child(res_row)
	if not g.can_resize_window():
		var note := Label.new()
		note.text = "此裝置不能調整視窗大小。\n要測試解析度，請關掉編輯器的「內嵌遊戲」再執行。" if OS.has_feature("editor") else "這個平台不能調整視窗大小。"
		note.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		note.custom_minimum_size = Vector2(340, 0)
		note.add_theme_font_size_override("font_size", UITheme.fs(13))
		note.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		box.add_child(note)

	# 一鍵開放全部關卡
	var un_row := HBoxContainer.new()
	un_row.add_theme_constant_override("separation", 8)
	var ul := VBoxContainer.new()
	ul.add_theme_constant_override("separation", 0)
	ul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var u1 := Label.new()
	u1.text = "開放全部關卡"
	ul.add_child(u1)
	var u2 := Label.new()
	u2.text = "每一章的旅程不用照順序解鎖"
	u2.add_theme_font_size_override("font_size", UITheme.fs(13))
	u2.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	ul.add_child(u2)
	un_row.add_child(ul)
	_unlock_btn = Button.new()
	_unlock_btn.flat = true
	_unlock_btn.focus_mode = Control.FOCUS_NONE
	_unlock_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_unlock_btn.pressed.connect(func():
		g.dev_unlock_all = not g.dev_unlock_all
		g.sfx("click")
		_refresh_dev())
	un_row.add_child(_unlock_btn)
	box.add_child(un_row)

	# 顯示幀數
	var fps_row := HBoxContainer.new()
	fps_row.add_theme_constant_override("separation", 8)
	var fl := VBoxContainer.new()
	fl.add_theme_constant_override("separation", 0)
	fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var f1 := Label.new()
	f1.text = "顯示幀數"
	fl.add_child(f1)
	var f2 := Label.new()
	f2.text = "左上角顯示每秒幀數"
	f2.add_theme_font_size_override("font_size", UITheme.fs(13))
	f2.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	fl.add_child(f2)
	fps_row.add_child(fl)
	_fps_btn = Button.new()
	_fps_btn.flat = true
	_fps_btn.focus_mode = Control.FOCUS_NONE
	_fps_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_fps_btn.pressed.connect(func():
		g.set_fps_display(not g.show_fps)
		g.sfx("click")
		_refresh_dev())
	fps_row.add_child(_fps_btn)
	box.add_child(fps_row)

	# 試發通知：10 秒後跳一則（在手機上確認外掛、圖示都裝好了）
	var tn := Button.new()
	tn.text = "試發一則提醒通知（10 秒後，先切到桌面）"
	tn.custom_minimum_size = Vector2(0, 40)
	tn.focus_mode = Control.FOCUS_NONE
	tn.add_theme_font_size_override("font_size", UITheme.fs(15))
	tn.pressed.connect(func():
		var ok: bool = g.notifier.test_now()
		_notify_note.text = "已排好，10 秒後會跳出來。" if ok else "沒有找到通知外掛（電腦版或還沒安裝），沒辦法試發。"
		_notify_note.visible = true)
	box.add_child(tn)

	# 刪除紀錄
	var del := Button.new()
	del.text = "刪除所有遊玩紀錄"
	del.custom_minimum_size = Vector2(0, 44)
	del.focus_mode = Control.FOCUS_NONE
	del.add_theme_color_override("font_color", UITheme.BAD)
	del.add_theme_color_override("font_hover_color", UITheme.ROSE)
	del.add_theme_stylebox_override("normal", UITheme.box(Color(1, 0.42, 0.48, 0.08), 12, Color(1, 0.42, 0.48, 0.5), 1, 8))
	del.add_theme_stylebox_override("hover", UITheme.box(Color(1, 0.42, 0.48, 0.16), 12, UITheme.BAD, 1, 8))
	del.add_theme_stylebox_override("pressed", UITheme.box(Color(1, 0.42, 0.48, 0.24), 12, UITheme.BAD, 2, 8))
	del.pressed.connect(_confirm_wipe)
	box.add_child(del)


## 省電模式：畫面沒在操作時降到 30 幀
func _power_row() -> Control:
	var g = Game.of(self)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var l := Label.new()
	l.text = "省電模式"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	_power_btn = Button.new()
	_power_btn.flat = true
	_power_btn.focus_mode = Control.FOCUS_NONE
	_power_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_power_btn.icon = UITheme.switch_icon(g.power_save)
	_power_btn.pressed.connect(func():
		g.set_power_save(not g.power_save)
		g.sfx("click")
		_power_btn.icon = UITheme.switch_icon(g.power_save))
	row.add_child(_power_btn)
	var n := Label.new()
	n.text = "畫面沒在操作時降低更新頻率"
	n.add_theme_font_size_override("font_size", UITheme.fs(13))
	n.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	n.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	n.custom_minimum_size = Vector2(380, 0)
	v.add_child(n)
	return v


## 光靈提醒：開關＋提醒時間
func _notify_row() -> Control:
	var g = Game.of(self)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var l := Label.new()
	l.text = "光靈提醒"
	l.custom_minimum_size = Vector2(72, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var prev := _arrow("‹")
	row.add_child(prev)
	_notify_time = Label.new()
	_notify_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notify_time.custom_minimum_size = Vector2(64, 0)
	_notify_time.add_theme_color_override("font_color", UITheme.ACCENT)
	row.add_child(_notify_time)
	var nxt := _arrow("›")
	row.add_child(nxt)
	var step := func(d: int):
		var ts: Array = g.notifier.TIMES
		var i := ts.find(g.notify_time)
		g.notify_time = ts[posmod((i if i >= 0 else 1) + d, ts.size())]
		g.save_settings()
		g.sfx("click")
		_refresh_notify()
	prev.pressed.connect(step.bind(-1))
	nxt.pressed.connect(step.bind(1))
	_notify_btn = Button.new()
	_notify_btn.flat = true
	_notify_btn.focus_mode = Control.FOCUS_NONE
	_notify_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_notify_btn.pressed.connect(func():
		g.notify_on = not g.notify_on
		g.save_settings()
		g.sfx("click")
		if g.notify_on and g.notifier.available() and not g.notifier.has_permission():
			g.notifier.request_permission()
		_refresh_notify())
	row.add_child(_notify_btn)
	_notify_note = Label.new()
	_notify_note.add_theme_font_size_override("font_size", UITheme.fs(13))
	_notify_note.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	_notify_note.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_notify_note.custom_minimum_size = Vector2(380, 0)
	v.add_child(_notify_note)
	_refresh_notify()
	return v


func _refresh_notify() -> void:
	if _notify_btn == null:
		return
	var g = Game.of(self)
	_notify_btn.icon = UITheme.switch_icon(g.notify_on)
	_notify_time.text = g.notify_time
	_notify_time.modulate.a = 1.0 if g.notify_on else 0.4
	if not g.notifier.available():
		_notify_note.text = "光靈會在這個時間傳通知想念你（手機版）"
	elif g.notify_on and not g.notifier.has_permission():
		_notify_note.text = "手機還沒允許通知：請在跳出的視窗按「允許」"
	else:
		_notify_note.text = "好幾天沒來時，光靈會在這個時間傳通知想念你"


func _arrow(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(40, 36)
	b.add_theme_font_size_override("font_size", UITheme.fs(24))
	return b


func _step_res(d: int) -> void:
	var g = Game.of(self)
	var n: int = g.RESOLUTIONS.size()
	g.set_resolution(posmod(g.res_index + d, n))
	g.sfx("click")
	_refresh_dev()


func _refresh_dev() -> void:
	var g = Game.of(self)
	_dev_btn.text = ("▾  開發者功能" if _dev_open else "▸  開發者功能")
	_dev_box.visible = _dev_open
	_res_label.text = g.RESOLUTIONS[g.res_index].name
	_unlock_btn.icon = UITheme.switch_icon(g.dev_unlock_all)
	_fps_btn.icon = UITheme.switch_icon(g.show_fps)
	_refresh_notify()
	_fit_scroll.call_deferred()


## 捲動區的高度：內容放得下就剛好，放不下就停在 MAX_SCROLL_H、可以捲
func _fit_scroll() -> void:
	if _scroll == null or not is_instance_valid(_inner):
		return
	var want := minf(_inner.get_combined_minimum_size().y, MAX_SCROLL_H)
	_scroll.custom_minimum_size = Vector2(400, want)


## 刪除紀錄前再確認一次
func _confirm_wipe() -> void:
	var o := UITheme.modal(self, UITheme.BAD, 420)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_child(UITheme.title_label("刪除所有遊玩紀錄？", 24, UITheme.BAD))
	var msg := Label.new()
	msg.text = "星數、旅程進度、錯題本、每日修煉、看過的劇情、終焉之塔紀錄都會清空，而且不能復原。"
	msg.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	msg.custom_minimum_size = Vector2(360, 0)
	msg.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	msg.add_theme_font_size_override("font_size", UITheme.fs(15))
	col.add_child(msg)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	col.add_child(btns)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(0, 48)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(func(): layer.queue_free())
	btns.add_child(cancel)
	var ok := Button.new()
	ok.text = "確定刪除"
	ok.custom_minimum_size = Vector2(0, 48)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.add_theme_color_override("font_color", Color.WHITE)
	ok.add_theme_stylebox_override("normal", UITheme.box(UITheme.BAD.darkened(0.15), 12, Color(0, 0, 0, 0), 0, 8))
	ok.add_theme_stylebox_override("hover", UITheme.box(UITheme.BAD, 12, Color.WHITE, 1, 8))
	ok.pressed.connect(func():
		var g = Game.of(self)
		g.wipe_progress()
		g.save_settings()
		get_tree().paused = false
		g.goto("main_menu.gd"))
	btns.add_child(ok)


func close() -> void:
	Game.of(self).save_settings()
	closed.emit()
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
