extends Control
## 光靈：關卡裡的小幫手
##   ・Face：圓滾滾的光靈臉，有表情（普通、開心、擔心、想睡、驚訝），會眨眼、會跳
##   ・這個節點本身：從舞台左下角冒出來，用對話泡泡說一句話，幾秒後自己飛走
## 台詞寫在 LINES，可以直接修改。

const UITheme := preload("game_theme.gd")

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


static func line(kind: String, arg = null) -> String:
	var arr: Array = LINES.get(kind, [""])
	var s: String = arr.pick_random()
	if arg != null and s.contains("%"):
		s = s % arg
	return s


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = SPOT
	face = Face.new()
	face.size = Vector2(60, 60)
	face.radius = 17.0
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(face)
	_bubble = PanelContainer.new()
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.position = Vector2(62, 2)
	var sb := UITheme.box(Color(1, 0.97, 0.88, 0.96), 14, Color(1, 0.85, 0.45), 2, 10)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	_bubble.add_theme_stylebox_override("panel", sb)
	add_child(_bubble)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", UITheme.fs(15))
	_label.add_theme_color_override("font_color", Color("2a2350"))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(_label)
	visible = false


## 冒出來說一句話（dur 秒後飛走）
func say(text: String, mood := "happy", dur := 2.4) -> void:
	if text == "":
		return
	_label.text = text
	face.mood = mood
	face.jump()
	_hide_at = t + dur
	if not visible:
		visible = true
		modulate.a = 0.0
		position = SPOT + Vector2(-30, 30)
		if _tw:
			_tw.kill()
		_tw = create_tween().set_parallel(true)
		_tw.tween_property(self, "modulate:a", 1.0, 0.2)
		_tw.tween_property(self, "position", SPOT, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bubble.scale = Vector2(0.85, 0.85)
	_bubble.pivot_offset = Vector2(0, 20)
	create_tween().tween_property(_bubble, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_now() -> void:
	_hide_at = t


func _process(delta: float) -> void:
	t += delta
	if visible and t >= _hide_at and (_tw == null or not _tw.is_running()):
		_tw = create_tween().set_parallel(true)
		_tw.tween_property(self, "modulate:a", 0.0, 0.25)
		_tw.tween_property(self, "position", SPOT + Vector2(-20, -30), 0.3)
		_tw.chain().tween_callback(func(): visible = false)


## 圓滾滾的光靈臉
class Face extends Control:
	const SL := preload("spirit_look.gd")
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
