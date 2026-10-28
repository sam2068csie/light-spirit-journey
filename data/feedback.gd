extends RefCounted
## 回報問題／建議：打開老師的 Google 表單，並自動附上「版本、手機型號、哪一題」等資訊
##
## 設定方式（只要做一次）：
##   1. 做一份 Google 表單，至少一題「簡答」或「段落」題目叫「題目資訊」，再加一題讓學生寫「發生了什麼事」。
##   2. FORM_URL 填表單的「填答網址」（https://docs.google.com/forms/d/e/……/viewform）。
##   3.（建議）讓資訊自動填進「題目資訊」那一題：
##      表單右上角 ⋮ →「取得預先填入的連結」→ 在「題目資訊」隨便打幾個字 →「取得連結」，
##      連結裡會有一段 entry.數字=你打的字，把「entry.數字」填到 FORM_ENTRY。
##   沒有填 FORM_URL 時，回報視窗會請學生把資訊截圖傳給老師。

const FORM_URL := "https://docs.google.com/forms/d/e/1FAIpQLSfeF3gwPXu876TvzrFa0z1NAaTtWan7EeE0ur_N-9xUPK5EOA/viewform?usp=header"
const FORM_ENTRY := "entry.1898081000"

const UITheme := preload("game_theme.gd")
const Units := preload("units.gd")


## 自動附上的資訊（一行一項）。context：哪一題（關卡裡才有）
static func info_text(g, context: String = "") -> String:
	var lines := PackedStringArray()
	lines.append("版本：" + String(g.BUILD))
	lines.append("裝置：%s %s（%s）" % [OS.get_name(), OS.get_model_name(), OS.get_version()])
	var ss := DisplayServer.screen_get_size()
	lines.append("螢幕：%d × %d" % [ss.x, ss.y])
	lines.append("單元：" + String(Units.unit(g.cur_unit).title))
	if context != "":
		lines.append("題目：" + context)
	lines.append("時間：" + Time.get_datetime_string_from_system(false, true))
	return "\n".join(lines)


## 打開回報視窗（parent 可以是任何節點；暫停選單裡也能用）
static func open(parent: Node, context: String = "") -> void:
	var g = parent.get_tree().root.get_node_or_null("Game")
	if g == null:
		return
	var info := info_text(g, context)
	var o := UITheme.modal(parent, UITheme.ACCENT, 480)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(UITheme.title_label("回報問題／建議", 24, UITheme.ACCENT))
	var tip := Label.new()
	tip.text = ("題目算錯、畫面怪怪的、卡住了，或有想法都可以告訴老師！\n下面的資訊會一起送出，老師才知道是哪一題。" if FORM_URL != ""
		else "老師還沒設定回報表單。\n請把這個畫面截圖，連同發生的事情一起傳給老師。")
	tip.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	tip.custom_minimum_size = Vector2(440, 0)
	tip.add_theme_font_size_override("font_size", UITheme.fs(15))
	tip.add_theme_color_override("font_color", UITheme.TEXT)
	col.add_child(tip)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.box(Color(1, 1, 1, 0.05), 12, Color(1, 1, 1, 0.12), 1, 10))
	col.add_child(box)
	var il := Label.new()
	il.text = info
	il.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	il.custom_minimum_size = Vector2(420, 0)
	il.add_theme_font_size_override("font_size", UITheme.fs(13))
	il.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	box.add_child(il)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	var close := Button.new()
	close.text = "關閉"
	close.custom_minimum_size = Vector2(0, 50)
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.pressed.connect(func(): layer.queue_free())
	row.add_child(close)
	var copy := Button.new()
	copy.text = "複製資訊"
	copy.custom_minimum_size = Vector2(0, 50)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.pressed.connect(func():
		DisplayServer.clipboard_set(info)
		copy.text = "已複製 ✓")
	row.add_child(copy)
	if FORM_URL != "":
		var go := Button.new()
		go.text = "打開回報表單"
		go.custom_minimum_size = Vector2(0, 50)
		go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.accent_button(go, 17)
		go.pressed.connect(func():
			DisplayServer.clipboard_set(info)     # 沒設定自動填入時，學生可以直接貼上
			OS.shell_open(form_link(info))
			layer.queue_free())
		row.add_child(go)


## 表單網址；有 FORM_ENTRY 時把資訊預先填進那一題
static func form_link(info: String) -> String:
	if FORM_ENTRY == "":
		return FORM_URL
	var sep := "&" if FORM_URL.contains("?") else "?"
	return FORM_URL + sep + "usp=pp_url&" + FORM_ENTRY + "=" + info.uri_encode()
