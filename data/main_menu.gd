extends Control
## 主畫面：標題頁（開始冒險／設定／離開）＋ 選擇關卡頁。
## 用法：新增場景，根節點選 Control，掛上這個腳本，存成 main_menu.tscn 並設為主場景。

const UITheme := preload("game_theme.gd")
const Game := preload("game.gd")
const SettingsPanel := preload("settings_panel.gd")
const Center := preload("review_center.gd")
const WorldMap := preload("world_map.gd")
const TowerView := preload("tower_view.gd")
const TowerBank := preload("tower_bank.gd")
const QuestPanel := preload("quest_panel.gd")
const GachaPage := preload("gacha_page.gd")

const Units := preload("units.gd")

var _title_page: Control
var _title_spirit      # 標題旁邊的大光靈（TitleSpirit）
var _wardrobe          # 打開中的衣櫃
var _level_page: Control
var _units_page: Control
var _units_body: Control
var _map_unit := ""
var _review_page: Control
var _map: Control
var _tower_page: Control
var _tower_back: Button
var _tower_body: Control
var _review_body: Control
var _page := "title"
var _settings: Control = null
var _quest_panel: Control = null
var _quest_chips: Array = []
var _gacha_chips: Array = []
var _gacha: Control = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.shared()
	var g = Game.of(self)
	var sky := NightSky.new()
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	_build_title_page()
	_build_units_page()
	_build_level_page()
	_build_review_page()
	_build_tower_page()
	var a: Dictionary = g.take_args()
	var pg: String = a.get("page", "title")
	_show_page(pg if pg in ["levels", "review", "tower"] else "title", false)
	if a.has("tower_result"):
		_show_tower_result(a.tower_result)
	if a.has("summary"):
		_show_summary(a.summary, a.get("summary_kind", "daily"))
	# 今天第一次打開：自動跳出連續簽到
	if not a.has("tower_result") and not a.has("summary") and g.streak_should_popup():
		_open_signin.call_deferred()
	# 第一次玩完一段之後回到主畫面：問要不要讓光靈提醒（手機版、只問一次）
	elif not g.notify_asked and g.notifier.available() and not g.stars.is_empty():
		_ask_notify.call_deferred()


func _ask_notify() -> void:
	var g = Game.of(self)
	g.notify_asked = true
	g.save_settings()
	var o := UITheme.modal(self, UITheme.ACCENT, 440)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 12)
	var sp := TitleSpirit.new()
	sp.custom_minimum_size = Vector2(0, 130)
	col.add_child(sp)
	col.add_child(UITheme.title_label("要讓光靈提醒你嗎？", 24, UITheme.ACCENT))
	var l := Label.new()
	l.text = "好幾天沒來的時候，光靈會在 %s 傳一則通知想念你。\n每天都有來玩的話，就不會打擾你。（可以在設定裡關掉或改時間）" % g.notify_time
	l.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	l.custom_minimum_size = Vector2(400, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", UITheme.fs(15))
	l.add_theme_color_override("font_color", UITheme.TEXT)
	col.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	var no := Button.new()
	no.text = "先不要"
	no.custom_minimum_size = Vector2(0, 50)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(func():
		g.notify_on = false
		g.save_settings()
		layer.queue_free())
	row.add_child(no)
	var yes := Button.new()
	yes.text = "好呀！"
	yes.custom_minimum_size = Vector2(0, 50)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.accent_button(yes, 19)
	yes.pressed.connect(func():
		g.notify_on = true
		g.save_settings()
		g.notifier.request_permission()
		layer.queue_free())
	row.add_child(yes)


# ================= 標題頁 =================

func _build_title_page() -> void:
	_title_page = Control.new()
	_title_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_title_page)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_page.add_child(center)
	# 右下角的版本號：裝到手機上之後，可以確認是不是最新匯出的版本
	var ver := Label.new()
	ver.text = "版本 " + Game.BUILD
	ver.add_theme_font_size_override("font_size", UITheme.fs(12))
	ver.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.position = Vector2(852, 620)
	ver.size = Vector2(280, 20)
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_page.add_child(ver)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)

	# 標題＋旁邊一隻大光靈（左邊留一樣寬的空位，標題才會在正中間）
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 0)
	col.add_child(head)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(170, 0)
	head.add_child(pad)
	var title := Title3D.new()
	title.text = "光靈的旅程"
	title.custom_minimum_size = Vector2(560, 136)
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	var spot := Control.new()            # 光靈的「家」：版面上留一格空位，光靈本體疊在整頁最上層，可以拖著到處丟
	spot.custom_minimum_size = Vector2(170, 170)
	spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(spot)
	_title_spirit = TitleSpirit.new()
	_title_spirit.home = spot
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	col.add_child(gap)

	var start := _menu_button("開始冒險", 68)
	UITheme.button_3d(start, UITheme.ACCENT, Color("c27a14"), Color("3a2306"), 24, 7)
	start.pressed.connect(func(): _show_page("units"))
	col.add_child(start)
	var rv := _menu_button("修煉之間", 52)
	rv.pressed.connect(func(): _show_page("review"))
	col.add_child(rv)
	var tw_b := _menu_button("終焉之塔", 52)
	tw_b.pressed.connect(func():
		Game.of(self).tower_from = "title"
		_show_page("tower"))
	col.add_child(tw_b)
	var settings := _menu_button("設定", 52)
	settings.pressed.connect(_open_settings)
	col.add_child(settings)
	if not (OS.has_feature("web") or OS.has_feature("mobile")):
		var quit := _menu_button("離開遊戲", 52)
		quit.pressed.connect(func(): get_tree().quit())
		col.add_child(quit)
	_quest_chip(_title_page, Vector2(1152 - 140 - 18, 14))
	_gacha_chip(_title_page, Vector2(1152 - 140 - 18 - 150, 14))
	_wardrobe_chip(_title_page, Vector2(1152 - 140 - 18 - 300, 14))
	# 光靈最後加入：整頁大小的透明層，只有點在光靈身上才會接住（其他地方照常點得到按鈕）
	_title_spirit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_page.add_child(_title_spirit)


func _menu_button(text: String, h: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(380, h)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UITheme.button_3d(b, Color("3d46a8"), Color("191b52"), UITheme.TEXT, 20, 7)
	return b


# ================= 選擇關卡頁 =================

func _build_level_page() -> void:
	_level_page = Control.new()
	_level_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_level_page)
	# 世界地圖：目前單元的地圖（指數與對數：指數島與對數島，八大關坐落在島上）
	_ensure_map()

	# 返回鍵最後加入，才會在最上層接到點擊
	var back := UITheme.ghost_button("返回", 18)
	back.icon = UITheme.icon("back", 18, UITheme.TEXT_DIM)
	back.custom_minimum_size = Vector2(96, 44)
	back.position = Vector2(16, 14)
	back.pressed.connect(_level_back)
	_level_page.add_child(back)
	var to_rv := UITheme.ghost_button("修煉之間  ▶", 17)
	to_rv.custom_minimum_size = Vector2(150, 44)
	to_rv.position = Vector2(1152 - 150 - 18, 14)
	to_rv.pressed.connect(func(): _show_page("review"))
	_level_page.add_child(to_rv)
	var qc := _quest_chip(_level_page, Vector2(120, 14))
	var gc := _gacha_chip(_level_page, Vector2(270, 14))
	_map_chrome = [back, to_rv, qc, gc]
	_hook_map_story()


var _map_chrome: Array = []


## 換單元時換一張世界地圖（每個單元一張）
func _ensure_map() -> void:
	var g = Game.of(self)
	if _map != null and is_instance_valid(_map) and _map_unit == g.cur_unit:
		return
	if _map != null and is_instance_valid(_map):
		_map.queue_free()
	_map_unit = g.cur_unit
	var path: String = Units.unit(g.cur_unit).map
	var scr: Script = load(get_script().resource_path.get_base_dir() + "/" + path) if path != "" else WorldMap
	_map = scr.new()
	_level_page.add_child(_map)
	_level_page.move_child(_map, 0)
	_map.enter_level.connect(func(f: String): Game.of(self).goto(f))
	_map.open_tower.connect(func():
		Game.of(self).tower_from = "levels"
		_show_page("tower"))
	if not _map_chrome.is_empty():
		_hook_map_story()


func _hook_map_story() -> void:
	_map.story_changed.connect(func(on: bool):
		for c in _map_chrome:
			c.visible = not on)


# ================= 選單元 =================

func _build_units_page() -> void:
	_units_page = Control.new()
	_units_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_units_page)
	_units_body = Control.new()
	_units_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_units_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_units_page.add_child(_units_body)
	var back := UITheme.ghost_button("返回", 18)
	back.icon = UITheme.icon("back", 18, UITheme.TEXT_DIM)
	back.custom_minimum_size = Vector2(96, 44)
	back.position = Vector2(16, 14)
	back.pressed.connect(func(): _show_page("title"))
	_units_page.add_child(back)
	_quest_chip(_units_page, Vector2(120, 14))
	_gacha_chip(_units_page, Vector2(270, 14))


func _refresh_units() -> void:
	for c in _units_body.get_children():
		c.queue_free()
	var g = Game.of(self)
	var title := UITheme.title_label("選擇冒險", 30, UITheme.ACCENT)
	title.position = Vector2(0, 52)
	title.size = Vector2(1152, 40)
	_units_body.add_child(title)
	# 每個學期一排：左邊是學期標籤，右邊照章節順序排卡片，卡片之間有小箭頭
	var cw := UNIT_CARD.x
	var gap := 22.0
	var x0 := 148.0
	var y := 126.0
	var no := 1
	for term in Units.TERMS:
		var list: Array = Units.units_of_term(term)
		var tag := PanelContainer.new()
		tag.add_theme_stylebox_override("panel", UITheme.box(Color(1, 1, 1, 0.05), 16, Color(1, 1, 1, 0.14), 1, 8))
		tag.position = Vector2(26, y)
		tag.custom_minimum_size = Vector2(100, UNIT_CARD.y)
		var tl := Label.new()
		tl.text = "\n".join(Array(String(term).split("")))
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tl.add_theme_font_override("font", UITheme.bold_font())
		tl.add_theme_font_size_override("font_size", UITheme.fs(24))
		tl.add_theme_constant_override("line_spacing", 4)
		tl.add_theme_color_override("font_color", UITheme.TEXT)
		tag.add_child(tl)
		_units_body.add_child(tag)
		for i in list.size():
			var card := _unit_card(g, list[i], no)
			no += 1
			card.position = Vector2(x0 + i * (cw + gap), y)
			_units_body.add_child(card)
			if i < list.size() - 1:
				var ar := Label.new()
				ar.text = "›"
				ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				ar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				ar.position = Vector2(x0 + i * (cw + gap) + cw, y)
				ar.size = Vector2(gap, UNIT_CARD.y)
				ar.add_theme_font_size_override("font_size", UITheme.fs(26))
				ar.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
				ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_units_body.add_child(ar)
		y += UNIT_CARD.y + 18.0


const UNIT_CARD := Vector2(228, 240)


func _unit_card(g, u: Dictionary, no: int) -> Control:
	var open: bool = Units.is_open(u)
	var cur: bool = open and g.cur_unit == u.id
	var col: Color = u.color
	var p := PanelContainer.new()
	var sb := UITheme.box(Color(0.09, 0.1, 0.24, 0.94) if open else Color(0.07, 0.07, 0.15, 0.9), 18,
		UITheme.ACCENT if cur else Color(col.r, col.g, col.b, 0.5 if open else 0.15), 3 if cur else 1, 12)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = UNIT_CARD
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var em := UnitEmblem.new()
	em.uid = u.id
	em.col = col if open else Color(0.45, 0.47, 0.6)
	em.custom_minimum_size = Vector2(0, 58)
	v.add_child(em)
	# 章節編號（左上角）
	var nl := Label.new()
	nl.text = str(no)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nl.size = Vector2(28, 28)
	nl.add_theme_font_override("font", UITheme.bold_font())
	nl.add_theme_font_size_override("font_size", UITheme.fs(15))
	nl.add_theme_color_override("font_color", Color("1a1530") if open else UITheme.TEXT_DIM)
	var nb := Panel.new()
	nb.add_theme_stylebox_override("panel", UITheme.box(col if open else Color(1, 1, 1, 0.08), 14, Color(0, 0, 0, 0), 0, 0))
	nb.size = Vector2(28, 28)
	nb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nb.add_child(nl)
	em.add_child(nb)
	var tl := Label.new()
	tl.text = u.title
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.add_theme_font_override("font", UITheme.bold_font())
	var tfs := 22 if String(u.title).length() <= 6 else 18
	tl.add_theme_font_size_override("font_size", UITheme.fs(tfs))
	tl.add_theme_color_override("font_color", col if open else UITheme.TEXT_DIM)
	v.add_child(tl)
	var ex := Label.new()
	ex.text = u.exam if String(u.exam) != "" else ("" if open else "新的世界還在建造中")
	ex.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ex.add_theme_font_size_override("font_size", UITheme.fs(13))
	ex.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	v.add_child(ex)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 46)
	if open:
		var lit := 0
		var prog := 0.0
		for l in u.levels:
			var pr: float = Center.level_progress(g, l.id)
			prog += pr
			if pr >= 0.999:
				lit += 1
		prog /= maxf(1.0, u.levels.size())
		var pl := Label.new()
		pl.text = "世界之光 %d／%d · %d%%" % [lit, u.levels.size(), roundi(prog * 100.0)]
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.add_theme_font_size_override("font_size", UITheme.fs(13))
		v.add_child(pl)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = 100
		bar.value = prog * 100.0
		bar.custom_minimum_size = Vector2(0, 8)
		bar.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.08), 4, Color(0, 0, 0, 0), 0, 0))
		bar.add_theme_stylebox_override("fill", UITheme.box(col, 4, Color(0, 0, 0, 0), 0, 0))
		v.add_child(bar)
		b.text = "繼續冒險 ▶" if cur else "進入世界 ▶"
		UITheme.accent_button(b, 17)
		var uid: String = u.id
		b.pressed.connect(func():
			g.set_unit(uid)
			_ensure_map()
			_show_page("levels"))
	else:
		b.text = "即將開放"
		b.icon = UITheme.icon("lock", 16, UITheme.TEXT_DIM)
		b.disabled = true
		UITheme.tight(b, 4)
		b.add_theme_font_size_override("font_size", UITheme.fs(16))
	v.add_child(b)
	return p


## 滑鼠移上卡片時輕輕放大
func _lift(b: Control, on: bool) -> void:
	b.pivot_offset = b.size / 2.0
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2.ONE * (1.035 if on else 1.0), 0.12).set_trans(Tween.TRANS_SINE)


# ================= 修煉之間：錯題本＋每日修煉 =================

func _build_review_page() -> void:
	_review_page = Control.new()
	_review_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_review_page)
	_review_body = Control.new()
	_review_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_review_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_review_page.add_child(_review_body)
	var back := UITheme.ghost_button("返回", 18)
	back.icon = UITheme.icon("back", 18, UITheme.TEXT_DIM)
	back.custom_minimum_size = Vector2(96, 44)
	back.position = Vector2(16, 14)
	back.pressed.connect(func(): _show_page("title"))
	_review_page.add_child(back)
	var lv := UITheme.ghost_button("世界地圖  ▶", 17)
	lv.custom_minimum_size = Vector2(140, 44)
	lv.position = Vector2(1152 - 140 - 18, 14)
	lv.pressed.connect(func(): _show_page("levels"))
	_review_page.add_child(lv)
	_quest_chip(_review_page, Vector2(120, 14))


## 每次打開都重新整理（剛修煉完、剛闖完關，數字都會變）
func _refresh_review() -> void:
	for c in _review_body.get_children():
		c.queue_free()
	var g = Game.of(self)
	var title := UITheme.title_label("修煉之間", 32, UITheme.ACCENT)
	title.position = Vector2(0, 4)
	title.size = Vector2(1152, 44)
	_review_body.add_child(title)
	_review_body.add_child(_unit_chip(false))

	# 左：八大關的觀念熟練度
	var left := _panel(Rect2(36, 98, 470, 520))
	var lcol := VBoxContainer.new()
	lcol.add_theme_constant_override("separation", 6)
	left.add_child(lcol)
	lcol.add_child(_h("觀念熟練度", UITheme.TEXT))
	var radar := Radar.new()
	radar.custom_minimum_size = Vector2(430, 380)
	var total := 0
	var solid := 0
	var weak := 0
	for info in Units.unit(g.cur_unit).levels:
		var m: Dictionary = Center.level_mastery(g, info.id)
		total += m.total
		solid += m.solid
		weak += m.weak
		radar.axes.append({"name": info.name, "color": info.color,
			"v": float(m.solid) / maxf(1.0, m.total), "w": float(m.weak) / maxf(1.0, m.total)})
	lcol.add_child(radar)
	var foot := Label.new()
	foot.text = "已掌握 %d ／ %d 個觀念　·　待加強 %d 個" % [solid, total, weak]
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", UITheme.fs(16))
	foot.add_theme_color_override("font_color", UITheme.TEXT)
	lcol.add_child(foot)
	var legend := Label.new()
	legend.text = "金色：已掌握　　紅色：待加強"
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.add_theme_font_size_override("font_size", UITheme.fs(13))
	legend.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	lcol.add_child(legend)

	# 右上：今日修煉
	var items: Array = g.daily_items(Center)
	var right := _panel(Rect2(530, 98, 586, 240))
	var dcol := VBoxContainer.new()
	dcol.add_theme_constant_override("separation", 8)
	right.add_child(dcol)
	var dh := HBoxContainer.new()
	dcol.add_child(dh)
	var dt := _h("今日修煉", UITheme.ACCENT)
	dt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dh.add_child(dt)
	var streak := Label.new()
	streak.text = "✦ 累積修煉 %d 天" % g.review_days.size() if not g.review_days.is_empty() else Game.today()
	streak.add_theme_font_size_override("font_size", UITheme.fs(15))
	streak.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	dh.add_child(streak)
	if items.is_empty():
		var empty := Label.new()
		empty.text = "還沒有可以複習的題目。\n先去「世界地圖」闖幾段旅程吧！答錯的觀念會自動收進這裡。"
		empty.add_theme_font_size_override("font_size", UITheme.fs(16))
		empty.add_theme_color_override("font_color", UITheme.TEXT)
		dcol.add_child(empty)
		var go := Button.new()
		go.text = "去闖關  ▶"
		go.custom_minimum_size = Vector2(0, 50)
		UITheme.accent_button(go, 19)
		go.pressed.connect(func(): _show_page("levels"))
		dcol.add_child(go)
	else:
		var chips := HBoxContainer.new()
		chips.add_theme_constant_override("separation", 8)
		dcol.add_child(chips)
		var res: Array = g.daily.get("results", [])
		for i in items.size():
			chips.add_child(_daily_chip(items[i], int(res[i]) if i < res.size() else -1, i == res.find(-1)))
		var note := Label.new()
		var n_weak := items.filter(func(it): return not it.get("refresh", false)).size()
		note.text = "%d 題弱點題%s，約 5 分鐘。" % [n_weak, "＋%d 題回鍋複習" % (items.size() - n_weak) if items.size() > n_weak else ""]
		note.add_theme_font_size_override("font_size", UITheme.fs(14))
		note.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		dcol.add_child(note)
		var go2 := Button.new()
		go2.custom_minimum_size = Vector2(0, 44)
		UITheme.accent_button(go2, 19)
		if g.daily_done():
			go2.text = "今天完成了 ✓　再練一組弱點  ▶"
			go2.pressed.connect(func():
				var extra: Array = Center.make_daily(g).slice(0, 3)
				if extra.is_empty():
					return
				g.start_session("free", extra))
		else:
			var done_n: int = res.size() - res.count(-1)
			go2.text = "開始今日修煉  ▶" if done_n == 0 else "繼續修煉（%d／%d）  ▶" % [done_n, res.size()]
			go2.pressed.connect(func(): g.start_session("daily", g.daily.items))
		dcol.add_child(go2)

	# 右下：最需要加強（位置跟著上面「今日修煉」的實際高度往下排，字放大時才不會疊在一起）
	var weak_p := _panel(Rect2(530, 352, 586, 266))
	_stack_below.call_deferred(right, weak_p)
	var wcol := VBoxContainer.new()
	wcol.add_theme_constant_override("separation", 6)
	weak_p.add_child(wcol)
	wcol.add_child(_h("最需要加強的觀念", UITheme.TEXT))
	var weakest: Array = Center.weakest(g, 8, g.cur_unit)
	if weakest.is_empty():
		var ok := Label.new()
		ok.text = "目前沒有待加強的觀念，太厲害了！\n繼續闖關，或做今日修煉保持手感。" if total > 0 and solid > 0 \
			else "還沒有錯題紀錄。闖關時答錯的觀念，會排在這裡等你回來練。"
		ok.add_theme_font_size_override("font_size", UITheme.fs(15))
		ok.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		ok.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wcol.add_child(ok)
		return
	# 清單放在捲動區裡：面板高度固定，放不下的往下捲
	wcol.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var wscroll := ScrollContainer.new()
	wscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	wscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vsb := wscroll.get_v_scroll_bar()
	vsb.custom_minimum_size = Vector2(5, 0)
	vsb.add_theme_stylebox_override("scroll", UITheme.box(Color(1, 1, 1, 0.04), 3, Color(0, 0, 0, 0), 0, 0))
	for st in ["grabber", "grabber_highlight", "grabber_pressed"]:
		vsb.add_theme_stylebox_override(st, UITheme.box(Color(1, 1, 1, 0.25), 3, Color(0, 0, 0, 0), 0, 0))
	wcol.add_child(wscroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", 14)      # 留位置給捲軸
	wscroll.add_child(pad)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	pad.add_child(rows)
	var wmax := 1
	for t in weakest:
		wmax = maxi(wmax, Center.weakness(g, t))
	for t in weakest:
		var row := _weak_row(t, float(Center.weakness(g, t)) / wmax)
		rows.add_child(row)
		for b in row.find_children("*", "BaseButton", true, false):
			b.mouse_filter = Control.MOUSE_FILTER_PASS     # 按在「練一題」上拖動也能捲動


## 把 lower 排在 upper 的正下方，並延伸到畫面底部（留 30 的邊）
func _stack_below(upper: Control, lower: Control) -> void:
	if not is_instance_valid(upper) or not is_instance_valid(lower):
		return
	upper.reset_size()
	var y := upper.position.y + upper.size.y + 14.0
	lower.position.y = y
	lower.custom_minimum_size.y = maxf(120.0, 648.0 - 30.0 - y)
	lower.reset_size()


func _panel(r: Rect2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = r.position
	p.custom_minimum_size = r.size
	p.size = r.size
	p.add_theme_stylebox_override("panel", UITheme.box(Color(0.09, 0.11, 0.23, 0.92), 18, Color(1, 1, 1, 0.08), 1, 18))
	_review_body.add_child(p)
	p.modulate.a = 0.0
	p.create_tween().tween_property(p, "modulate:a", 1.0, 0.25).set_delay(0.04 * _review_body.get_child_count())
	return p


func _h(text: String, c: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", UITheme.fs(20))
	l.add_theme_color_override("font_color", c)
	return l


static func _short(tag: String, n: int = 9) -> String:
	var s := Center.tag_name(tag)
	for sep in ["（", "：", " "]:
		var k := s.find(sep)
		if k > 1:
			s = s.substr(0, k)
	return s if s.length() <= n else s.substr(0, n - 1) + "…"


## 今日修煉的一題：觀念名稱、所屬大關顏色、做完的星數
func _daily_chip(it: Dictionary, res: int, is_next: bool) -> PanelContainer:
	var info: Dictionary = Center.level_info(it.level)
	var c: Color = info.color
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(102, 80)
	var bd := UITheme.ACCENT if is_next else Color(c.r, c.g, c.b, 0.5)
	p.add_theme_stylebox_override("panel", UITheme.box(Color(c.r, c.g, c.b, 0.10 if res < 0 else 0.2), 12, bd, 2 if is_next else 1, 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var lv := Label.new()
	lv.text = info.name
	lv.add_theme_font_size_override("font_size", UITheme.fs(12))
	lv.add_theme_color_override("font_color", c)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lv)
	var nm := Label.new()
	nm.text = _short(it.tag, 12)
	nm.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	nm.custom_minimum_size = Vector2(86, 22)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", UITheme.fs(14))
	nm.add_theme_color_override("font_color", UITheme.TEXT)
	v.add_child(nm)
	var st := Label.new()
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.add_theme_font_size_override("font_size", UITheme.fs(14))
	if res < 0:
		st.text = "▶ 下一題" if is_next else ("回鍋" if it.get("refresh", false) else "弱點")
		st.add_theme_color_override("font_color", UITheme.ACCENT if is_next else UITheme.TEXT_DIM)
	elif res == 0:
		st.text = "看過示範"
		st.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	else:
		st.text = "★".repeat(res) + "☆".repeat(3 - res)
		st.add_theme_color_override("font_color", UITheme.ACCENT)
	v.add_child(st)
	return p


## 弱點清單的一列：觀念、大關、答錯次數、還差多少、練一題
func _weak_row(tag: String, k: float) -> HBoxContainer:
	var g = Game.of(self)
	var info: Dictionary = Center.level_info(Center.home_level(tag))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var dot := ColorRect.new()
	dot.color = info.color
	dot.custom_minimum_size = Vector2(6, 38)
	row.add_child(dot)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	var nm := Label.new()
	nm.text = Center.tag_name(tag)
	nm.clip_text = true
	nm.custom_minimum_size = Vector2(300, 0)
	nm.add_theme_font_size_override("font_size", UITheme.fs(16))
	nm.add_theme_color_override("font_color", UITheme.TEXT)
	v.add_child(nm)
	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 10)
	v.add_child(meta)
	var ml := Label.new()
	ml.text = "%s　·　答錯 %d 次" % [info.name, int(g.mistakes.get(tag, 0))]
	ml.add_theme_font_size_override("font_size", UITheme.fs(13))
	ml.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	meta.add_child(ml)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.value = clampf(k, 0.08, 1.0)
	bar.custom_minimum_size = Vector2(90, 6)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", UITheme.box(Color(1, 1, 1, 0.08), 3, Color(0, 0, 0, 0), 0, 0))
	bar.add_theme_stylebox_override("fill", UITheme.box(UITheme.BAD, 3, Color(0, 0, 0, 0), 0, 0))
	meta.add_child(bar)
	var b := Button.new()
	b.text = "練一題"
	b.custom_minimum_size = Vector2(92, 38)
	b.add_theme_font_size_override("font_size", UITheme.fs(16))
	b.pressed.connect(func():
		var it: Dictionary = Center.pick_for(g, tag)
		if not it.is_empty():
			g.start_session("free", [it]))
	row.add_child(b)
	return row


## 修煉結束：每一題的結果，以及變強的觀念
func _show_summary(results: Array, kind: String) -> void:
	if results.is_empty():
		return
	var o := UITheme.modal(self, UITheme.ACCENT, 520)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	var g = Game.of(self)
	var done_today: bool = kind == "daily" and g.daily_done()
	col.add_child(UITheme.title_label("今日修煉完成！" if done_today else "修煉結束", 30, UITheme.ACCENT))
	var got := 0
	for rr in results:
		got += int(rr.stars)
	col.add_child(UITheme.title_label("★ × %d" % got, 22, UITheme.TEXT))
	for rr in results:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var info: Dictionary = Center.level_info(rr.level)
		var dot := ColorRect.new()
		dot.color = info.color
		if rr.level == "T":
			dot.color = TowerBank.KIND_COLOR.get(rr.get("type", ""), info.color)
		dot.custom_minimum_size = Vector2(6, 26)
		row.add_child(dot)
		var nm := Label.new()
		nm.text = Center.tag_name(rr.tag)
		nm.clip_text = true
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.custom_minimum_size = Vector2(300, 0)
		nm.add_theme_font_size_override("font_size", UITheme.fs(15))
		row.add_child(nm)
		var st := Label.new()
		var s_: int = int(rr.stars)
		st.text = ("★".repeat(s_) + "☆".repeat(3 - s_)) if s_ > 0 else "看過示範"
		st.add_theme_color_override("font_color", UITheme.ACCENT if s_ > 0 else UITheme.TEXT_DIM)
		row.add_child(st)
		col.add_child(row)
	var msg := Label.new()
	var better := results.filter(func(rr): return int(rr.stars) > 0).size()
	msg.text = ("%d 個觀念變強了！" % better if better > 0 else "這次比較難，沒關係，明天再來練。") \
		+ ("\n已經累積修煉 %d 天，明天見！" % g.review_days.size() if done_today else "")
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", UITheme.fs(16))
	msg.add_theme_color_override("font_color", UITheme.TEXT)
	col.add_child(msg)
	var ok := Button.new()
	ok.text = "好"
	ok.custom_minimum_size = Vector2(0, 50)
	UITheme.accent_button(ok, 19)
	ok.pressed.connect(func():
		layer.queue_free()
		_refresh_review())
	col.add_child(ok)
	if done_today:
		Game.of(self).sfx("fanfare")


# ================= 終焉之塔（綜合大考） =================

func _build_tower_page() -> void:
	_tower_page = Control.new()
	_tower_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_tower_page)
	_tower_body = Control.new()
	_tower_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tower_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tower_page.add_child(_tower_body)
	_tower_back = UITheme.ghost_button("世界地圖", 18)
	_tower_back.icon = UITheme.icon("back", 18, UITheme.TEXT_DIM)
	_tower_back.custom_minimum_size = Vector2(120, 44)
	_tower_back.position = Vector2(16, 14)
	_tower_back.pressed.connect(func(): _show_page(_tower_origin()))
	_tower_page.add_child(_tower_back)
	_quest_chip(_tower_page, Vector2(146, 14))


# ================= 切換單元（修煉之間、終焉之塔共用） =================

## 標題下方的單元按鈕：「◆ 指數與對數 ▾」，點了可以換單元
func _unit_chip(tower: bool) -> Control:
	var g = Game.of(self)
	var u: Dictionary = Units.unit(g.cur_unit)
	var col: Color = u.color
	var b := Button.new()
	b.text = "◆  %s  ▾" % u.title
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", UITheme.fs(15))
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, UITheme.box(Color(col.r, col.g, col.b, 0.14 if st == "normal" else 0.24), 16,
			Color(col.r, col.g, col.b, 0.6), 1, 4))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, col.lightened(0.2))
	b.tooltip_text = "切換單元"
	var w := maxf(180.0, b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(15)).x + 44.0)
	b.custom_minimum_size = Vector2(w, 30)
	b.size = Vector2(w, 30)
	b.position = Vector2((1152.0 - w) / 2.0, 60)      # 和上面的大標題、下面的面板都留一點距離
	b.pressed.connect(func(): _open_unit_picker(tower))
	return b


## 選單元的小視窗：照課本章節順序，分高二上、高二下；還沒開放的變暗
func _open_unit_picker(tower: bool) -> void:
	var g = Game.of(self)
	var o := UITheme.modal(self, UITheme.ACCENT, 560)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	col.add_child(UITheme.title_label("切換單元", 26, UITheme.ACCENT))
	for term in Units.TERMS:
		var h := Label.new()
		h.text = term
		h.add_theme_font_override("font", UITheme.bold_font())
		h.add_theme_font_size_override("font_size", UITheme.fs(16))
		h.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		col.add_child(h)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 8)
		col.add_child(grid)
		for u in Units.units_of_term(term):
			var ok: bool = Units.is_open(u) and (not tower or String(u.get("tower", "")) != "")
			var cur: bool = u.id == g.cur_unit
			var c: Color = u.color
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(260, 50)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.text = "  %s%s" % [u.title, "　✓ 目前" if cur else ("" if ok else ("　即將開放" if not Units.is_open(u) else "　還沒有塔"))]
			b.add_theme_font_size_override("font_size", UITheme.fs(16))
			var edge := UITheme.ACCENT if cur else Color(c.r, c.g, c.b, 0.5 if ok else 0.12)
			b.add_theme_stylebox_override("normal", UITheme.box(Color(c.r, c.g, c.b, 0.12 if ok else 0.03), 12, edge, 2 if cur else 1, 8))
			b.add_theme_stylebox_override("hover", UITheme.box(Color(c.r, c.g, c.b, 0.22), 12, c, 2, 8))
			b.add_theme_stylebox_override("pressed", UITheme.box(Color(c.r, c.g, c.b, 0.3), 12, c, 2, 8))
			b.add_theme_stylebox_override("disabled", UITheme.box(Color(1, 1, 1, 0.02), 12, edge, 1, 8))
			b.add_theme_color_override("font_color", c.lightened(0.25) if ok else UITheme.TEXT_DIM)
			b.add_theme_color_override("font_disabled_color", Color(UITheme.TEXT_DIM.r, UITheme.TEXT_DIM.g, UITheme.TEXT_DIM.b, 0.6))
			if not ok:
				b.disabled = true
				b.icon = UITheme.icon("lock", 14, UITheme.TEXT_DIM)
			var uid: String = u.id
			b.pressed.connect(func():
				layer.queue_free()
				if uid != g.cur_unit:
					g.set_unit(uid)
					g.sfx("success")
				if tower:
					_refresh_tower()
				else:
					_refresh_review())
			grid.add_child(b)
	var close := UITheme.ghost_button("關閉", 16)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): layer.queue_free())
	col.add_child(close)


## 終焉之塔的返回鍵：從哪一頁進來就回哪一頁
func _tower_origin() -> String:
	var f: String = Game.of(self).tower_from
	return f if f in ["title", "levels"] else "levels"


## 地圖頁的返回：上面開著視窗（例如劇情回顧）就先關掉視窗、留在地圖；否則回主畫面
func _level_back() -> void:
	if _map.close_overlay():
		return
	_show_page("units")


func _refresh_tower() -> void:
	_tower_back.text = "主畫面" if _tower_origin() == "title" else "世界地圖"
	for c in _tower_body.get_children():
		c.queue_free()
	var g = Game.of(self)
	var tname := String(Units.unit(g.cur_unit).get("tower_name", ""))
	var title := UITheme.title_label(tname if tname != "" else "終焉之塔", 32, Color("ff8fa0"))
	title.position = Vector2(0, 4)
	title.size = Vector2(1152, 44)
	_tower_body.add_child(title)
	_tower_body.add_child(_unit_chip(true))

	var tv := TowerView.new()
	tv.best = g.tower_best
	tv.top_floor = Center.tower_top()
	tv.position = Vector2(40, 98)
	tv.size = Vector2(470, 524)
	_tower_body.add_child(tv)

	var p := PanelContainer.new()
	p.position = Vector2(536, 98)
	p.custom_minimum_size = Vector2(578, 524)
	p.add_theme_stylebox_override("panel", UITheme.box(Color(0.09, 0.11, 0.23, 0.92), 18, Color(1, 0.55, 0.6, 0.25), 1, 26))
	_tower_body.add_child(p)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	p.add_child(col)
	col.add_child(_h("挑戰規則", Color("ff8fa0")))
	for rule in [["▲", "共 %d 層，每層一題，段考題型與八大關混合" % Center.tower_top()],
			["◷", "每層限時，從 260 秒開始越來越短"],
			["♥", "只有三顆心：答錯、超時扣一顆（真假審判錯 2 張以上才扣）"],
			["✦", "每 5 層是「試煉層」大題，同一趟不重複"],
			["◎", "通過一層得星塵，同一層每天限領一次"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var ic := Label.new()
		ic.text = rule[0]
		ic.custom_minimum_size = Vector2(26, 0)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic.add_theme_font_size_override("font_size", UITheme.fs(18))
		ic.add_theme_color_override("font_color", Color("ff8fa0"))
		row.add_child(ic)
		var tx := Label.new()
		tx.text = rule[1]
		tx.add_theme_font_size_override("font_size", UITheme.fs(17))
		tx.add_theme_color_override("font_color", UITheme.TEXT)
		tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(tx)
		col.add_child(row)
	var rec := HBoxContainer.new()
	rec.add_theme_constant_override("separation", 30)
	col.add_child(rec)
	for pair in [["最高紀錄", ("登頂！（%d 層）" % g.tower_best if g.tower_best >= Center.tower_top() else "第 %d 層" % g.tower_best) if g.tower_best > 0 else "還沒有"], ["累積攀登", "%d 次" % g.tower_runs],
			["今日星塵", ("領到第 %d 層" % g.tower_paid_today()) if g.tower_paid_today() > 0 else "還沒領"]]:
		var v := VBoxContainer.new()
		var l1 := Label.new()
		l1.text = pair[0]
		l1.add_theme_font_size_override("font_size", UITheme.fs(14))
		l1.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		v.add_child(l1)
		var l2 := Label.new()
		l2.text = pair[1]
		l2.add_theme_font_size_override("font_size", UITheme.fs(26))
		l2.add_theme_color_override("font_color", UITheme.ACCENT)
		v.add_child(l2)
		rec.add_child(v)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(fill)
	var tip := Label.new()
	tip.text = "題型改編自各校段考。卡住就去世界地圖或修煉之間練習！"
	tip.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	tip.custom_minimum_size = Vector2(520, 0)
	tip.add_theme_font_size_override("font_size", UITheme.fs(14))
	tip.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	col.add_child(tip)
	var go := Button.new()
	go.text = "開始攀登  ▲"
	go.custom_minimum_size = Vector2(0, 58)
	UITheme.accent_button(go, 21)
	go.pressed.connect(func(): Game.of(self).start_tower())
	col.add_child(go)


## 攀登結束：這次爬到第幾層、是不是新紀錄、每一層的結果
func _show_tower_result(res: Dictionary) -> void:
	var o := UITheme.modal(self, Color("ff8fa0"), 520)
	var layer: Control = o[0]
	var col: VBoxContainer = o[1]
	col.add_theme_constant_override("separation", 10)
	var summit: bool = res.get("summit", false)
	col.add_child(UITheme.title_label("登頂成功！" if summit else "攀登結束", 28, Color("ff8fa0")))
	var floors := int(res.floors)
	col.add_child(UITheme.title_label(("爬完全部 %d 層，終焉之塔被你征服了！" % floors) if summit else ("這次爬到第 %d 層" % floors if floors > 0 else "還沒爬上第 1 層"), 26 if not summit else 22, UITheme.ACCENT))
	if summit:
		Game.of(self).sfx("fanfare")
	if res.get("record", false) and floors > 0:
		col.add_child(UITheme.title_label("✦ 新紀錄！ ✦", 20, UITheme.ACCENT))
		Game.of(self).sfx("fanfare")
	# 星塵：每天每層只領一次
	var rw: Dictionary = res.get("reward", {})
	var rl := HBoxContainer.new()
	rl.alignment = BoxContainer.ALIGNMENT_CENTER
	rl.add_theme_constant_override("separation", 6)
	var ic := QuestPanel.ItemIcon.new()
	ic.kind = "dust"
	ic.custom_minimum_size = Vector2(28, 28)
	rl.add_child(ic)
	var tl := Label.new()
	tl.add_theme_font_size_override("font_size", UITheme.fs(17))
	if int(rw.get("dust", 0)) > 0:
		var span := ("第 %d 層" % int(rw.from)) if int(rw.from) == int(rw.to) else ("第 %d～%d 層" % [int(rw.from), int(rw.to)])
		tl.text = "星塵 +%d（%s）" % [int(rw.dust), span]
		tl.add_theme_color_override("font_color", UITheme.ACCENT)
	elif floors > 0:
		tl.text = "今天第 1～%d 層的星塵已經領過了，爬得更高才有新的星塵" % int(rw.get("paid", floors))
		tl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		tl.add_theme_font_size_override("font_size", UITheme.fs(14))
	else:
		ic.visible = false
	rl.add_child(tl)
	if floors > 0:
		col.add_child(rl)
	var hist: Array = res.get("history", [])
	for rr in hist.slice(maxi(0, hist.size() - 6)):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var info: Dictionary = Center.level_info(rr.level)
		var dot := ColorRect.new()
		dot.color = info.color
		if rr.level == "T":
			dot.color = TowerBank.KIND_COLOR.get(rr.get("type", ""), info.color)
		dot.custom_minimum_size = Vector2(6, 24)
		row.add_child(dot)
		var nm := Label.new()
		nm.text = ("第 %d 層　%s" % [int(rr.floor), rr.title]) if rr.level == "T" else ("第 %d 層　%s・%s" % [int(rr.floor), info.name, rr.title])
		nm.clip_text = true
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.custom_minimum_size = Vector2(300, 0)
		nm.add_theme_font_size_override("font_size", UITheme.fs(15))
		row.add_child(nm)
		var st := Label.new()
		var s_: int = int(rr.stars)
		st.text = ("★".repeat(s_) + "☆".repeat(3 - s_)) if s_ > 0 else "✗"
		st.add_theme_color_override("font_color", UITheme.ACCENT if s_ > 0 else UITheme.BAD)
		row.add_child(st)
		col.add_child(row)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	col.add_child(btns)
	var again := Button.new()
	again.text = "再挑戰一次"
	again.custom_minimum_size = Vector2(0, 50)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(func():
		layer.queue_free()
		Game.of(self).start_tower())
	btns.add_child(again)
	var ok := Button.new()
	ok.text = "好"
	ok.custom_minimum_size = Vector2(0, 50)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.accent_button(ok, 19)
	ok.pressed.connect(func(): layer.queue_free())
	btns.add_child(ok)


# ================= 換頁、設定、Esc =================

func _show_page(p: String, animate: bool = true) -> void:
	_page = p
	var pages := {"title": _title_page, "units": _units_page, "levels": _level_page, "review": _review_page, "tower": _tower_page}
	for k in pages:
		pages[k].visible = k == p
	var show_node: Control = pages[p]
	if p == "title" and _title_spirit != null:
		_title_spirit.eq = Game.of(self).equipped.duplicate()     # 換過裝扮就跟著換
	if p == "review":
		_refresh_review()
	elif p == "levels":
		_ensure_map()
		_map.on_shown()
	elif p == "units":
		_refresh_units()
	elif p == "tower":
		_refresh_tower()
	_refresh_quest_badges()
	if animate:
		show_node.modulate.a = 0.0
		show_node.position = Vector2(0, 14)
		var tw := show_node.create_tween().set_parallel()
		tw.tween_property(show_node, "modulate:a", 1.0, 0.2)
		tw.tween_property(show_node, "position", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ================= 每日任務入口 =================

## 每日任務的入口按鈕（主畫面、地圖、修煉之間、終焉之塔都有）；有東西可以領時右上角亮紅色驚嘆號
func _quest_chip(parent: Control, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = "每日任務"
	b.icon = UITheme.icon("quest", 20, UITheme.ACCENT)
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(140, 44)
	b.position = pos
	b.add_theme_font_override("font", UITheme.bold_font())
	b.add_theme_font_size_override("font_size", UITheme.fs(16))
	b.add_theme_constant_override("h_separation", 8)
	var face := Color(0.07, 0.08, 0.19, 0.88)
	b.add_theme_stylebox_override("normal", UITheme.box(face, 12, Color(1, 1, 1, 0.14), 1, 10))
	b.add_theme_stylebox_override("hover", UITheme.box(face.lightened(0.08), 12, Color(UITheme.ACCENT.r, UITheme.ACCENT.g, UITheme.ACCENT.b, 0.6), 1, 10))
	b.add_theme_stylebox_override("pressed", UITheme.box(face.lightened(0.14), 12, UITheme.ACCENT, 2, 10))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, UITheme.TEXT)
	var dot := QuestDot.new()
	dot.position = Vector2(140 - 14, -8)
	dot.size = Vector2(22, 22)
	dot.visible = false
	b.add_child(dot)
	b.set_meta("dot", dot)
	b.pressed.connect(_open_quests)
	parent.add_child(b)
	_quest_chips.append(b)
	return b


func _refresh_quest_badges() -> void:
	var g = Game.of(self)
	var on: bool = g.quest_badge()
	for b in _quest_chips:
		if is_instance_valid(b):
			b.get_meta("dot").visible = on
	# 扭蛋：今天的首抽半價還沒用、而且星塵夠
	var gon: bool = g.gacha_half_ready() and g.gacha_can("one")
	for b in _gacha_chips:
		if is_instance_valid(b):
			b.get_meta("dot").visible = gon


## 光靈扭蛋機的入口（主畫面、世界地圖）
func _gacha_chip(parent: Control, pos: Vector2) -> Button:
	var b := _quest_chip(parent, pos)
	_quest_chips.erase(b)
	b.text = "光靈扭蛋"
	b.icon = UITheme.icon("capsule", 20, Color("ff8fc0"))
	for c in b.pressed.get_connections():
		b.pressed.disconnect(c.callable)
	b.pressed.connect(_open_gacha)
	_gacha_chips.append(b)
	return b


## 主畫面的「光靈衣櫃」按鈕（不用先進扭蛋機）
func _wardrobe_chip(parent: Control, pos: Vector2) -> Button:
	var b := _quest_chip(parent, pos)
	_quest_chips.erase(b)
	b.text = "光靈衣櫃"
	b.icon = UITheme.icon("hanger", 20, Color("8fe0ff"))
	for c in b.pressed.get_connections():
		b.pressed.disconnect(c.callable)
	b.pressed.connect(_open_wardrobe)
	return b


func _open_wardrobe() -> void:
	if _wardrobe != null:
		return
	_wardrobe = preload("wardrobe.gd").new()
	add_child(_wardrobe)
	_wardrobe.closed.connect(func():
		_wardrobe = null
		if _page == "levels":
			_map.queue_redraw())


func _open_gacha() -> void:
	if _gacha != null:
		return
	_gacha = GachaPage.new()
	add_child(_gacha)
	_gacha.closed.connect(func():
		_gacha = null
		if _page == "levels":
			_map.queue_redraw()
		_refresh_quest_badges())


func _open_signin() -> void:
	var p := preload("signin_panel.gd").new()
	add_child(p)
	p.closed.connect(_refresh_quest_badges)


func _open_quests() -> void:
	if _quest_panel != null:
		return
	_quest_panel = QuestPanel.new()
	add_child(_quest_panel)
	_quest_panel.closed.connect(func():
		_quest_panel = null
		_refresh_quest_badges())
	_quest_panel.go.connect(func(dest: String):
		if dest == "tower":
			Game.of(self).tower_from = "title" if _page == "title" else "levels"
		if dest != _page:
			_show_page(dest))


func _open_settings() -> void:
	if _settings:
		return
	_settings = SettingsPanel.new()
	add_child(_settings)
	_settings.closed.connect(func(): _settings = null)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") and _settings == null and _quest_panel == null and _gacha == null and _page != "title" and not (_page == "levels" and _map.playing):
		get_viewport().set_input_as_handled()
		if _page == "levels":
			_level_back()
		elif _page == "units":
			_show_page("title")
		elif _page == "tower":
			_show_page(_tower_origin())
		else:
			_show_page("title")


# ================= 小元件 =================

## 立體標題字：柔和陰影 → 往下疊出的厚度 → 深紫描邊 → 上淺下深的金色字面
## 標題旁邊的大光靈（原版樣子）：穿著目前的裝扮，飄浮，身邊有小星星繞；點一下會跳起來
class TitleSpirit extends Control:
	const SL := preload("spirit_look.gd")
	const UITheme := preload("game_theme.gd")
	const Game := preload("game.gd")
	const R := 54.0          # 光靈半徑
	const HIT := 70.0        # 點得到的範圍（比身體大一點，手指比較好抓）
	const EDGE := 60.0       # 碰牆時，光靈中心離畫面邊緣的距離
	const BOUNCE := 0.72     # 反彈後保留的速度
	const FRICTION := 1.3    # 飛行時速度衰減（越大停得越快）
	var eq: Dictionary = {}
	var t := 0.0
	var hop := -10.0        # 上一次被點的時間
	## 主畫面用：版面上的空位。有設定時，光靈可以拖曳、丟出去、碰到畫面邊緣反彈；
	## 沒設定（例如通知詢問視窗裡）就是原本在格子正中間飄的樣子。
	var home: Control = null
	var pos := Vector2(NAN, NAN)    # 目前位置（本元件座標）；NAN = 還沒放過，待在家
	var vel := Vector2.ZERO
	var dragging := false
	var grab := Vector2.ZERO        # 手指按下的位置和光靈中心的差
	var press_at := Vector2.ZERO
	var moved := false
	var last_mouse := Vector2.ZERO
	var last_ms := 0
	var hit_t := -10.0              # 上一次撞牆的時間
	var hit_x := true               # 撞的是左右牆（true）還是上下牆
	var tilt := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		eq = Game.of(self).equipped.duplicate()

	func _center() -> Vector2:
		if home == null:
			return size / 2.0
		if is_nan(pos.x):
			return home.get_global_rect().get_center() - get_global_rect().position
		return pos

	func _has_point(p: Vector2) -> bool:
		if home == null:
			return Rect2(Vector2.ZERO, size).has_point(p)
		return p.distance_to(_center() + Vector2(0, 6)) < HIT

	func _gui_input(e: InputEvent) -> void:
		if home == null:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_hop()
				accept_event()
			return
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				pos = _center()
				dragging = true
				moved = false
				vel = Vector2.ZERO
				grab = e.position - pos
				press_at = e.position
				last_mouse = e.position
				last_ms = Time.get_ticks_msec()
			elif dragging:
				dragging = false
				if not moved:
					_hop()
				elif Time.get_ticks_msec() - last_ms > 120:
					vel = Vector2.ZERO       # 停住一下才放手：就放在那裡，不丟出去
				vel = vel.limit_length(3200.0)
			accept_event()
		elif e is InputEventMouseMotion and dragging:
			if e.position.distance_to(press_at) > 8.0:
				moved = true
			if moved:
				var now := Time.get_ticks_msec()
				var dt := maxf((now - last_ms) / 1000.0, 0.001)
				var v: Vector2 = (e.position - last_mouse) / dt
				vel = vel.lerp(v, 0.6)       # 平滑一點，放手時的速度比較穩
				last_mouse = e.position
				last_ms = now
				pos = _clamp(e.position - grab)
			accept_event()

	func _hop() -> void:
		if t - hop > 0.5:
			hop = t
			Game.of(self).play("bell", Game.semi(Game.scale_semi(4 + randi() % 4)), -8.0)

	func _clamp(p: Vector2) -> Vector2:
		var lo := Vector2(EDGE, EDGE)
		var hi := size - Vector2(EDGE, EDGE)
		return Vector2(clampf(p.x, lo.x, maxf(lo.x, hi.x)), clampf(p.y, lo.y, maxf(lo.y, hi.y)))

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		t += delta
		eq = Game.of(self).equipped      # 在衣櫃換了裝扮，馬上跟著換（不用重開主畫面）
		if home != null and not is_nan(pos.x) and not dragging:
			_fly(minf(delta, 0.05))
		var want := 0.0 if dragging else clampf(vel.x / 2600.0, -0.35, 0.35)
		if dragging:
			want = clampf(vel.x / 3000.0, -0.25, 0.25)
		tilt = lerpf(tilt, want, minf(1.0, delta * 10.0))
		queue_redraw()

	func _fly(dt: float) -> void:
		if vel.length() < 15.0:
			vel = Vector2.ZERO
			pos = _clamp(pos)
			return
		pos += vel * dt
		vel *= exp(-FRICTION * dt)
		var lo := Vector2(EDGE, EDGE)
		var hi := size - Vector2(EDGE, EDGE)
		var hx := 0.0
		var hy := 0.0
		if pos.x < lo.x or pos.x > hi.x:
			pos.x = clampf(pos.x, lo.x, hi.x)
			hx = absf(vel.x)
			vel.x = -vel.x * BOUNCE
		if pos.y < lo.y or pos.y > hi.y:
			pos.y = clampf(pos.y, lo.y, hi.y)
			hy = absf(vel.y)
			vel.y = -vel.y * BOUNCE
		var hit := maxf(hx, hy)
		if hit > 0.0:
			hit_x = hx >= hy
		if hit > 120.0:
			hit_t = t
			if hit > 500.0:
				Game.of(self).play("bell", Game.semi(Game.scale_semi(randi() % 4)), -14.0)

	func _draw() -> void:
		var r := R
		var k := t - hop
		var jump := 0.0
		var squash := Vector2.ONE
		if k < 0.6:
			jump = -sin(k / 0.6 * PI) * 34.0
			if k < 0.08:
				squash = Vector2(1.12, 0.88)
		var hk := t - hit_t
		if hk < 0.18:                      # 撞牆：往撞的方向壓扁一下再彈回來
			var s := sin(hk / 0.18 * PI) * 0.18
			squash = Vector2(1.0 - s, 1.0 + s) if hit_x else Vector2(1.0 + s, 1.0 - s)
		var flying := home != null and (dragging or vel != Vector2.ZERO)
		var bob := 0.0 if flying else sin(t * 1.8) * 6.0
		if dragging:
			squash *= 1.08                 # 抓起來的時候大一點點
		var c := _center() + Vector2(0, 6 + bob + jump)
		# 柔和的光暈
		for i in 3:
			UITheme.dot(self, c, r * (1.38 - i * 0.12), Color(1.0, 0.9, 0.5, 0.05))
		# 身邊繞圈的小星星
		for i in 5:
			var a := t * (0.9 + 0.3 * float(k < 0.6 or flying)) * (1.0 + i * 0.08) + i * TAU / 5.0
			var p := c + Vector2(cos(a) * r * 1.55, sin(a) * r * 0.55 - 4.0)
			var front := sin(a) > 0.0
			var col := Color(1, 0.9, 0.55, 0.85 if front else 0.35)
			_spark(p, 4.0 + 1.5 * sin(t * 3.0 + i), col)
		# 光靈本體（裝扮也一起畫）
		draw_set_transform(c, tilt, squash)
		SL.draw_all(self, Vector2.ZERO, r, eq, t)      # 原版的光靈＋衣櫃裡穿的裝扮
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _spark(p: Vector2, rr: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 8:
			var a := i * PI / 4.0
			pts.append(p + Vector2(cos(a), sin(a)) * (rr if i % 2 == 0 else rr * 0.35))
		draw_colored_polygon(pts, col)


class Title3D extends Control:
	const UITheme := preload("game_theme.gd")
	const FACE_SHADER := """
shader_type canvas_item;
uniform vec4 top_col : source_color;
uniform vec4 bot_col : source_color;
uniform float y0;
uniform float y1;
varying float ly;
void vertex() { ly = VERTEX.y; }
void fragment() {
	float a = texture(TEXTURE, UV).a * COLOR.a;
	float t = clamp((ly - y0) / max(1.0, y1 - y0), 0.0, 1.0);
	COLOR = vec4(mix(top_col.rgb, bot_col.rgb, t), a);
}
"""
	var text := ""
	var font_size := 88
	const DEPTH := 12
	var _face: Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 字面另外一層，套用漸層（只在這一層用著色器）
		_face = Control.new()
		_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var sh := Shader.new()
		sh.code = FACE_SHADER
		var mat := ShaderMaterial.new()
		mat.shader = sh
		mat.set_shader_parameter("top_col", Color("fff3b0"))
		mat.set_shader_parameter("bot_col", Color("ffae2b"))
		_face.material = mat
		_face.draw.connect(_draw_face)
		add_child(_face)
		resized.connect(func(): _face.queue_redraw())

	func _base() -> Vector2:
		return Vector2(0, size.y * 0.5 + font_size * 0.36 - DEPTH * 0.5)

	func _draw() -> void:
		var f := UITheme.bold_font()
		var p := _base()
		var w := size.x
		# 柔和的落地陰影
		draw_string_outline(f, p + Vector2(0, DEPTH + 8), text, HORIZONTAL_ALIGNMENT_CENTER, w, font_size, 16, Color(0, 0, 0, 0.32))
		# 厚度：一層一層往下疊，越下面越深
		for d in range(DEPTH, 0, -1):
			var c := Color("4a2fa8").lerp(Color("24145e"), float(d) / DEPTH)
			draw_string_outline(f, p + Vector2(0, d), text, HORIZONTAL_ALIGNMENT_CENTER, w, font_size, 11, c)
			draw_string(f, p + Vector2(0, d), text, HORIZONTAL_ALIGNMENT_CENTER, w, font_size, c)
		# 字面的描邊
		draw_string_outline(f, p, text, HORIZONTAL_ALIGNMENT_CENTER, w, font_size, 11, Color("2c1a6e"))

	func _draw_face() -> void:
		var f := UITheme.bold_font()
		var p := _base()
		var mat := _face.material as ShaderMaterial
		mat.set_shader_parameter("y0", p.y - font_size * 0.80)
		mat.set_shader_parameter("y1", p.y + font_size * 0.10)
		_face.draw_string(f, p, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color.WHITE)


## 八大關的熟練度雷達圖：金色是已掌握、紅色是待加強
class Radar extends Control:
	var axes: Array = []
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var n := axes.size()
		if n == 0:
			return
		var c := size / 2.0 + Vector2(0, 6)
		var R := minf(size.x, size.y) / 2.0 - 52.0
		var grow := clampf(t / 0.8, 0.0, 1.0)
		grow = 1.0 - pow(1.0 - grow, 3.0)
		var dir := func(i: int) -> Vector2:
			var ang := -PI / 2.0 + TAU * i / n
			return Vector2(cos(ang), sin(ang))
		for ring in [0.25, 0.5, 0.75, 1.0]:
			var pts := PackedVector2Array()
			for i in n + 1:
				pts.append(c + dir.call(i % n) * R * ring)
			draw_polyline(pts, Color(1, 1, 1, 0.10 if ring < 1.0 else 0.22), 1.0, true)
		for i in n:
			draw_line(c, c + dir.call(i) * R, Color(1, 1, 1, 0.08), 1.0)
		# 已掌握 + 待加強（外圈）
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for i in n:
			var a: Dictionary = axes[i]
			var v: float = maxf(0.03, a.v) * grow
			var w: float = minf(1.0, a.v + a.w) * grow
			inner.append(c + dir.call(i) * R * v)
			outer.append(c + dir.call(i) * R * maxf(w, v))
		draw_colored_polygon(outer, Color(1, 0.42, 0.48, 0.16))
		draw_polyline(outer + PackedVector2Array([outer[0]]), Color(1, 0.42, 0.48, 0.55), 1.5, true)
		draw_colored_polygon(inner, Color(1, 0.81, 0.35, 0.28))
		draw_polyline(inner + PackedVector2Array([inner[0]]), Color(1, 0.81, 0.35, 0.95), 2.5, true)
		var font := get_theme_default_font()
		for i in n:
			var a: Dictionary = axes[i]
			var p: Vector2 = inner[i]
			UITheme.dot(self, p, 5.0 + 1.0 * sin(t * 3.0 + i), a.color)
			var lp: Vector2 = c + dir.call(i) * (R + 30.0)
			var txt: String = a.name
			draw_string(font, lp + Vector2(-60, 0), txt, HORIZONTAL_ALIGNMENT_CENTER, 120, UITheme.fs(14), a.color)
			draw_string(font, lp + Vector2(-60, 17), "%d%%" % roundi(100.0 * a.v), HORIZONTAL_ALIGNMENT_CENTER, 120, UITheme.fs(13),
				Color(1, 1, 1, 0.7))


## 背景：漸層夜空、閃爍的星星、緩緩上升的水晶碎片，以及一條有光點奔跑的指數曲線
class NightSky extends Control:
	var t := 0.0
	var stars: Array = []
	var shards: Array = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		for i in 140:
			stars.append({"p": Vector2(rng.randf(), rng.randf() * 0.8), "s": rng.randf_range(0.6, 2.1), "ph": rng.randf() * TAU})
		for i in 22:
			shards.append({"x": rng.randf(), "y": rng.randf(), "v": rng.randf_range(0.01, 0.03),
				"s": rng.randf_range(3.0, 7.0), "ph": rng.randf() * TAU})

	func _process(delta: float) -> void:
		t += delta
		for sh in shards:
			sh.y -= sh.v * delta
			if sh.y < -0.05:
				sh.y = 1.05
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color("1b1650"), Color("1b1650"), Color("0b2a3f"), Color("0b2a3f")]))
		for s in stars:
			var a: float = 0.3 + 0.35 * sin(t * 1.5 + s.ph)
			UITheme.dot(self, Vector2(s.p.x * w, s.p.y * h), s.s, Color(1, 1, 1, a))
		for sh in shards:
			var c := Vector2(sh.x * w + 10.0 * sin(t * 0.6 + sh.ph), sh.y * h)
			var sz: float = sh.s
			var a2: float = 0.25 + 0.2 * sin(t * 2.0 + sh.ph)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -sz), c + Vector2(sz * 0.6, 0),
				c + Vector2(0, sz), c + Vector2(-sz * 0.6, 0)]), Color(0.6, 0.9, 1.0, a2))

		# 標題後方的柔光
		var glow_c := Vector2(w / 2.0, h * 0.27)
		for k in 28:
			UITheme.dot(self, glow_c, 40.0 + k * 7.0, Color(1.0, 0.8, 0.4, 0.006))

		# 指數曲線與奔跑的光點
		var pts := PackedVector2Array()
		for i in 121:
			var u := i / 120.0
			pts.append(_curve(u, w, h))
		draw_polyline(UITheme.thin(pts), Color(0.35, 0.85, 1.0, 0.07), 18.0)
		draw_polyline(UITheme.thin(pts), Color(0.35, 0.85, 1.0, 0.18), 7.0)
		draw_polyline(UITheme.thin(pts), Color(0.55, 0.9, 1.0, 0.6), 2.0, true)
		var u0 := fmod(t * 0.12, 1.0)
		for k in 18:
			var uu := u0 - k * 0.006
			if uu < 0.0:
				continue
			var p := _curve(uu, w, h)
			UITheme.dot(self, p, 7.0 - k * 0.35, Color(1.0, 0.95, 0.7, 0.5 * (1.0 - k / 18.0)))
		var head := _curve(u0, w, h)
		UITheme.dot(self, head, 16.0, Color(1.0, 0.9, 0.5, 0.15))
		UITheme.dot(self, head, 7.0, Color(1.0, 0.98, 0.85))

		_mountain(h - 60, 46.0, 0.008, Color(0.12, 0.13, 0.30, 0.9))
		_mountain(h - 22, 30.0, 0.015, Color(0.06, 0.08, 0.18, 1.0))

	func _curve(u: float, w: float, h: float) -> Vector2:
		var x := lerpf(-4.0, 3.2, u)
		return Vector2(u * w, h - 70.0 - 26.0 * pow(2.0, x))

	func _mountain(base: float, amp: float, freq: float, c: Color) -> void:
		var pts := PackedVector2Array()
		var x := 0.0
		while x <= size.x + 20.0:
			pts.append(Vector2(x, base - amp * (0.6 + 0.4 * sin(x * freq + 1.3)) - amp * 0.35 * sin(x * freq * 2.7)))
			x += 20.0
		pts.append(Vector2(size.x, size.y))
		pts.append(Vector2(0, size.y))
		draw_colored_polygon(pts, c)


## 紅色驚嘆號（有任務獎勵可以領）：輕輕跳動
class QuestDot extends Control:
	const UITheme := preload("game_theme.gd")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pivot_offset = Vector2(11, 11)
		var tw := create_tween().set_loops()
		tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.45).set_trans(Tween.TRANS_SINE)
		tw.tween_property(self, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)

	func _draw() -> void:
		UITheme.dot(self, Vector2(11, 11), 11.0, Color("7a1020"))
		UITheme.dot(self, Vector2(11, 10), 10.0, Color("ff4d5e"))
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, 17), "!", HORIZONTAL_ALIGNMENT_CENTER, 22, UITheme.fs(15), Color.WHITE)


## 選單元卡片上的圖騰（用程式畫）
class UnitEmblem extends Control:
	const UITheme := preload("game_theme.gd")
	var uid := ""
	var col := Color.WHITE

	func _draw() -> void:
		# 圖案以 130 高設計，卡片比較小時整個縮放
		var ks := clampf(size.y / 130.0, 0.3, 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(ks, ks))
		var c := size / (2.0 * ks)
		UITheme.dot(self, c, 58.0, Color(col.r, col.g, col.b, 0.12))
		UITheme.dot(self, c, 44.0, Color(col.r, col.g, col.b, 0.22))
		draw_arc(c, 52.0, 0, TAU, 48, Color(col.r, col.g, col.b, 0.6), 2.0, true)
		match uid:
			"exp":
				# 指數曲線和對數曲線（對稱於 y = x）
				var a := PackedVector2Array()
				var b := PackedVector2Array()
				for k in 21:
					var x := -1.6 + 3.2 * k / 20.0
					var y := pow(2.0, x) - 1.2
					a.append(c + Vector2(x * 22.0, -y * 22.0))
					b.append(c + Vector2(y * 22.0, -x * 22.0))
				draw_polyline(a, col, 3.0, true)
				draw_polyline(b, col.lightened(0.35), 3.0, true)
				draw_line(c + Vector2(-34, 34), c + Vector2(34, -34), Color(1, 1, 1, 0.3), 1.5, true)
			"vec2":
				# 兩支箭頭和合成向量
				var o := c + Vector2(-30, 24)
				for v in [[Vector2(52, -8), col], [Vector2(14, -46), col.lightened(0.3)], [Vector2(66, -54), Color.WHITE]]:
					var e: Vector2 = o + v[0]
					draw_line(o, e, v[1], 3.0, true)
					var d: Vector2 = (v[0] as Vector2).normalized()
					var nrm := Vector2(-d.y, d.x)
					draw_colored_polygon(PackedVector2Array([e, e - d * 10.0 + nrm * 5.0, e - d * 10.0 - nrm * 5.0]), v[1])
			"vec3":
				# 立方體（斜投影）
				var s := 26.0
				var dx := Vector2(14, -10)
				var f := [c + Vector2(-s, -s * 0.6), c + Vector2(s * 0.6, -s * 0.6), c + Vector2(s * 0.6, s), c + Vector2(-s, s)]
				var bk := f.map(func(p): return p + dx)
				for k in 4:
					draw_line(f[k], f[(k + 1) % 4], col, 2.5, true)
					draw_line(bk[k], bk[(k + 1) % 4], Color(col.r, col.g, col.b, 0.6), 2.0, true)
					draw_line(f[k], bk[k], Color(col.r, col.g, col.b, 0.8), 2.0, true)
			"trig":
				# 單位圓和正弦波
				draw_arc(c + Vector2(-18, 0), 20.0, 0, TAU, 32, Color(col.r, col.g, col.b, 0.7), 2.0, true)
				var ang := 0.9
				var pt := c + Vector2(-18, 0) + Vector2(cos(ang), -sin(ang)) * 20.0
				draw_line(c + Vector2(-18, 0), pt, col.lightened(0.3), 2.0, true)
				UITheme.dot(self, pt, 3.5, Color.WHITE)
				var w := PackedVector2Array()
				for q in 25:
					var x := q / 24.0
					w.append(c + Vector2(-18 + x * 56.0, -sin(x * TAU) * 20.0))
				draw_polyline(w, col, 3.0, true)
			"plane":
				# 斜放的平面和一條穿過它的直線
				var pl := PackedVector2Array([c + Vector2(-38, 8), c + Vector2(6, -14), c + Vector2(38, 4), c + Vector2(-6, 26)])
				draw_colored_polygon(pl, Color(col.r, col.g, col.b, 0.3))
				pl.append(pl[0])
				draw_polyline(pl, col, 2.5, true)
				draw_line(c + Vector2(-12, -38), c + Vector2(0, 6), col.lightened(0.4), 3.0, true)
				draw_line(c + Vector2(0, 6), c + Vector2(8, 34), Color(col.lightened(0.4).r, col.lightened(0.4).g, col.lightened(0.4).b, 0.45), 3.0, true)
				UITheme.dot(self, c + Vector2(0, 6), 4.0, Color.WHITE)
			"prob":
				# 機率樹：一個根分成兩枝，每枝再分兩枝
				var r0 := c + Vector2(-34, 0)
				var mids := [c + Vector2(-4, -22), c + Vector2(-4, 22)]
				for m in mids:
					draw_line(r0, m, col, 2.5, true)
					for dy in [-11.0, 11.0]:
						var e: Vector2 = m + Vector2(30, dy)
						draw_line(m, e, col.lightened(0.3), 2.0, true)
						UITheme.dot(self, e, 3.5, col.lightened(0.5))
					UITheme.dot(self, m, 4.0, col)
				UITheme.dot(self, r0, 5.0, Color.WHITE)
			"matrix":
				# 方括號裡的 3×3 小點
				var hw := 30.0
				var hh := 30.0
				for sd in [-1.0, 1.0]:
					var xe: float = c.x + sd * hw
					var br := PackedVector2Array([Vector2(xe + sd * -8.0, c.y - hh), Vector2(xe, c.y - hh), Vector2(xe, c.y + hh), Vector2(xe + sd * -8.0, c.y + hh)])
					draw_polyline(br, col, 3.0, true)
				for rr in 3:
					for cc in 3:
						var on := rr == cc
						UITheme.dot(self, c + Vector2((cc - 1) * 17.0, (rr - 1) * 17.0), 4.5 if on else 3.5,
							col.lightened(0.4) if on else Color(col.r, col.g, col.b, 0.6))
