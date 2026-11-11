extends Control
## 光靈：關卡裡的小幫手
##   ・Face：圓滾滾的光靈臉，有表情（普通、開心、擔心、想睡、驚訝），會眨眼、會跳
##   ・這個節點本身：從舞台左下角冒出來，用對話泡泡說一句話，幾秒後自己飛走
## 台詞寫在 LINES，可以直接修改。
##   ・dock_after：關卡頂端列的標籤。設了的話，光靈改在頂端列這個標籤的字後面冒出來（不蓋住題目）；
##     頂端列放不下這句話時，才回到舞台左下角
##   ・畫面上已經有別的光靈（新手教學、提示框上的臉 blocked() 為 true）時不說話，正在說的也先飛走

const UITheme := preload("res://data/ui/game_theme.gd")

const LINES := {
	"start": ["出發囉！這題是「%s」～", "「%s」！我們一起加油！", "嘿咻～來挑戰「%s」吧！", "準備好了嗎？「%s」來囉！"],
	"wrong": ["唔……不是這個啦！", "咦？差一點點！", "沒關係，再想想看～", "嗚哇，滑掉了！再一次！", "看看右邊的提示嘛～"],
	"wrong3": ["別灰心！我們一步一步來～", "錯了好幾次也沒關係，我陪你！", "深呼吸～先看提示，再慢慢想！"],
	"perfect": ["全對！你好厲害～", "哇啊，一次就過！好帥！", "三顆星！我要轉圈圈～"],
	"pass": ["過關了！耶～", "做到了！下一題也交給我們！", "成功！光又亮了一點點～"],
	"streak": ["連續 %d 題全對！停不下來了～", "%d 連勝！你是天才吧？"],
	"reveal": ["沒關係！看我示範一次～", "這題有點難，我們一起看答案吧！"],
	"idle": ["呼……zzz……啊！我、我沒睡著喔！慢慢想沒關係～", "還在想嗎？可以先看看左邊的題目喔～"],
}

const SPOT := Vector2(40, 560)     # 舞台左下角

var face: Face
var _bubble: PanelContainer
var _label: Label
var _tw: Tween
var _hide_at := 0.0
var t := 0.0
var dock_after: Label             # 頂端列：跟在這個標籤的字後面
var blocked := Callable()         # 回傳 true：畫面上已經有別的光靈，先不說話
var _home := SPOT                 # 這一次冒出來的位置
var _docked := false
var _frames := 0                  # 出現在畫面上幾個畫面了（頂端列排版好了沒）
var _sb_stage: StyleBoxFlat
var _sb_dock: StyleBoxFlat


static func line(kind: String, arg = null) -> String:
	var arr: Array = LINES.get(kind, [""])
	var s: String = arr.pick_random()
	if arg != null and s.contains("%"):
		s = s % arg
	return s


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS     # 新手教學會暫停遊戲：要能自己飛走
	position = SPOT
	face = Face.new()
	face.size = Vector2(60, 60)
	face.radius = 17.0
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(face)
	_bubble = PanelContainer.new()
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.position = Vector2(62, 2)
	_sb_stage = UITheme.box(Color(1, 0.97, 0.88, 0.96), 14, Color(1, 0.85, 0.45), 2, 10)
	_sb_stage.content_margin_left = 14
	_sb_stage.content_margin_right = 14
	_sb_dock = _sb_stage.duplicate()
	_sb_dock.content_margin_top = 4
	_sb_dock.content_margin_bottom = 4
	_sb_dock.content_margin_left = 12
	_sb_dock.content_margin_right = 12
	_bubble.add_theme_stylebox_override("panel", _sb_stage)
	add_child(_bubble)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", UITheme.fs(15))
	_label.add_theme_color_override("font_color", Color("2a2350"))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(_label)
	visible = false


func is_blocked() -> bool:
	if not get_tree().get_nodes_in_group("tutorial").filter(func(n): return not n.is_queued_for_deletion()).is_empty():
		return true
	return blocked.is_valid() and bool(blocked.call())


## 頂端列放得下這句話的話，回傳冒出來的位置（全域座標）；放不下回傳 null
func _dock_spot(text: String) -> Variant:
	if dock_after == null or not is_instance_valid(dock_after) or not dock_after.is_visible_in_tree():
		return null
	var bar := dock_after.get_parent() as Control
	if bar == null:
		return null
	var font := dock_after.get_theme_font("font")
	var x0 := dock_after.global_position.x + font.get_string_size(dock_after.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		dock_after.get_theme_font_size("font_size")).x + 20.0
	var x1 := INF
	for c in bar.get_children():
		if c is Control and c.get_index() > dock_after.get_index() and c.is_visible_in_tree():
			x1 = minf(x1, (c as Control).global_position.x)
	if x1 == INF:
		x1 = bar.global_position.x + bar.size.x
	var lf := _label.get_theme_font("font")
	var need := 50.0 + lf.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UITheme.fs(14)).x + 26.0
	if x1 - 12.0 - x0 < need:
		return null
	return Vector2(x0, dock_after.global_position.y + dock_after.size.y / 2.0 - 22.0)


## 換成頂端列（小一號）或舞台左下角的樣子
func _layout(docked: bool) -> void:
	_docked = docked
	if docked:
		face.size = Vector2(44, 44)
		face.radius = 13.0
		_bubble.position = Vector2(50, 5)
		_bubble.add_theme_stylebox_override("panel", _sb_dock)
		_label.add_theme_font_size_override("font_size", UITheme.fs(14))
	else:
		face.size = Vector2(60, 60)
		face.radius = 17.0
		_bubble.position = Vector2(62, 2)
		_bubble.add_theme_stylebox_override("panel", _sb_stage)
		_label.add_theme_font_size_override("font_size", UITheme.fs(15))
	_bubble.reset_size()


## 冒出來說一句話（dur 秒後飛走）
func say(text: String, mood := "happy", dur := 2.4) -> void:
	if text == "" or is_blocked():
		return
	# 剛建好的畫面，頂端列還沒排版（量不到位置）：第一句話等兩個畫面再說
	if dock_after != null and _frames < 2 and is_inside_tree():
		get_tree().process_frame.connect(say.bind(text, mood, dur), CONNECT_ONE_SHOT)
		return
	var spot = _dock_spot(text)
	_layout(spot != null)
	_home = (spot - get_parent().global_position) if spot != null else SPOT
	_label.text = text
	face.mood = mood
	face.jump()
	_hide_at = t + dur
	if not visible or position.distance_to(_home) > 1.0:
		visible = true
		modulate.a = 0.0
		position = _home + (Vector2(0, -14) if _docked else Vector2(-30, 30))
		if _tw:
			_tw.kill()
		_tw = create_tween().set_parallel(true)
		_tw.tween_property(self, "modulate:a", 1.0, 0.2)
		_tw.tween_property(self, "position", _home, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bubble.scale = Vector2(0.85, 0.85)
	_bubble.pivot_offset = Vector2(0, 20)
	create_tween().tween_property(_bubble, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_now() -> void:
	_hide_at = t


func _process(delta: float) -> void:
	t += delta
	_frames += 1
	# 教學或提示框的光靈出現了：這邊先飛走，畫面上只留一隻
	if visible and t < _hide_at and is_blocked():
		_hide_at = t
		if _tw:
			_tw.kill()
	if visible and t >= _hide_at and (_tw == null or not _tw.is_running()):
		_tw = create_tween().set_parallel(true)
		_tw.tween_property(self, "modulate:a", 0.0, 0.25)
		_tw.tween_property(self, "position", _home + (Vector2(0, -12) if _docked else Vector2(-20, -30)), 0.3)
		_tw.chain().tween_callback(func(): visible = false)


## 圓滾滾的光靈臉
class Face extends Control:
	const SL := preload("res://data/ui/spirit_look.gd")
	var mood := "normal"     # normal / happy / worried / sleepy / surprised
	var radius := 15.0
	var t := 0.0
	var bounce := 0.0
	var _blink := 2.0

	func _process(delta: float) -> void:
		t += delta
		bounce = maxf(0.0, bounce - delta * 2.2)
		_blink -= delta
		if _blink < -0.13:
			_blink = randf_range(2.2, 4.5)
		queue_redraw()

	func jump() -> void:
		bounce = 1.0

	## 和第一關在曲線上奔跑的光靈同一個樣子：光暈＋奶油色圓球＋兩顆小眼睛（表情只靠眼睛）
	func _draw() -> void:
		var r := radius
		var hop := -sin(bounce * PI) * r * 0.7
		var shake := sin(t * 40.0) * 1.5 * bounce if mood == "worried" else 0.0
		var c := size / 2.0 + Vector2(shake, hop + sin(t * 2.4) * 1.2)
		var eq := SL.eq_of(self)
		SL.draw_back(self, c, r, eq, t)
		SL.draw_body(self, c, r, eq, t)
		var ink := Color(0.15, 0.1, 0.3)
		var er := r * 0.2
		var e1 := c + Vector2(r * 0.22, -r * 0.22)
		var e2 := c + Vector2(r * 0.67, -r * 0.22)
		match mood:
			"happy":
				# 開心：一樣是小圓點眼睛，身邊冒小星星、跳一跳
				for e in [e1, e2]:
					UITheme.dot(self, e, er, ink)
				for k in 3:
					var a := t * 2.0 + k * TAU / 3.0
					_spark(c + Vector2(cos(a), sin(a)) * r * 1.9, maxf(2.5, r * 0.25), Color(1, 0.88, 0.45, 0.9))
			"worried":
				# 眼睛往下看、微微發抖
				for e in [e1 + Vector2(-r * 0.12, r * 0.12), e2 + Vector2(-r * 0.12, r * 0.12)]:
					UITheme.dot(self, e, er * 0.9, ink)
			"sleepy":
				for e in [e1, e2]:
					draw_line(e + Vector2(-er * 1.2, 0), e + Vector2(er * 1.2, 0), ink, maxf(1.4, r * 0.12), true)
				var font := get_theme_default_font()
				var z := fposmod(t * 0.8, 1.0)
				draw_string(font, c + Vector2(r * 1.0 + 6.0 * z, -r * 0.9 - 10.0 * z), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 11 + int(5 * z),
					Color(0.9, 0.93, 1.0, 1.0 - z))
			"surprised":
				for e in [e1, e2]:
					UITheme.dot(self, e, er * 1.35, ink)
			_:
				# 平常：小圓點眼睛，偶爾眨眼
				for e in [e1, e2]:
					if _blink < 0.0:
						draw_line(e + Vector2(-er, 0), e + Vector2(er, 0), ink, maxf(1.2, r * 0.11), true)
					else:
						UITheme.dot(self, e, er, ink)
		SL.draw_front(self, c, r, eq, t)

	static func _half_disc(c: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for k in 11:
			var a := PI * k / 10.0
			pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.9))
		return pts

	func _spark(p: Vector2, s: float, col: Color) -> void:
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.3, 0), p + Vector2(0, s), p + Vector2(-s * 0.3, 0)]), col)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-s, 0), p + Vector2(0, -s * 0.3), p + Vector2(s, 0), p + Vector2(0, s * 0.3)]), col)
