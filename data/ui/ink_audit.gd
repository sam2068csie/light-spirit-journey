extends RefCounted
## 排版檢查（docs/design_rules.md 1.9：根號、分數不能超出框，也不能和別的圖形疊在一起）
##
## 畫圖的節點（數與式的 NumField、座標平面 Plot）每一幀把畫上去的字、實心圖形的外框記在 ink：
##   {"r": Rect2, "s": 字（圖形是 ""）, "own": 屬於哪一格, "shape": 是不是圖形}
## tests/test_play.gd、test_real.gd 每一個畫面都呼叫 issues() 檢查：
##   1. 字不能超出整張圖
##   2. 寫在格子裡面的字（own 和某個圖形一樣）要整個在那一格裡面（種子、積木、名牌……）
##   3. 字和字不能疊在一起
##   4. 字不能壓到別的圖形（例如長方形左邊的 √3 壓到旁邊那個長方形）
## 很淡的字（透明度 < 0.35，例如正在淡出的提示）不記。

const MathLabel := preload("res://data/ui/math_text.gd")

const MIN_ALPHA := 0.35
const SLACK := 1.5      # 邊緣差一點點（反鋸齒、字型的留白）不算


## 用 MathLabel.draw_on 畫的一行（center_x 是中心、baseline_y 是基線）佔的範圍
static func math_box(font: Font, center_x: float, baseline_y: float, markup: String, fs: float) -> Rect2:
	var w := MathLabel.text_width(font, markup, fs)
	var ext := MathLabel.line_extent(markup, fs)
	return Rect2(center_x - w / 2.0, baseline_y - ext.x, w, ext.x + ext.y)


## 用 draw_string 畫的一般文字（pos 是左邊的基線）佔的範圍
static func plain_box(font: Font, pos: Vector2, s: String, fs: int) -> Rect2:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	return Rect2(pos.x, pos.y - fs * 0.78, w, fs * 1.0)


static func add_text(ink: Array, r: Rect2, s: String, col: Color, own := "") -> void:
	if col.a < MIN_ALPHA or s.strip_edges() == "" or r.size.x <= 0.0:
		return
	ink.append({"r": r, "s": s, "own": own, "shape": false})


static func add_shape(ink: Array, r: Rect2, own: String) -> void:
	ink.append({"r": r.abs(), "s": "", "own": own, "shape": true})


static func _hit(a: Rect2, b: Rect2) -> bool:
	return a.grow(-SLACK).intersects(b.grow(-SLACK))


## 回傳發現的問題（中文說明），沒有問題就是空的
static func issues(ink: Array, bounds: Rect2) -> Array:
	var out := []
	var texts := ink.filter(func(e): return not e.shape)
	var shapes := ink.filter(func(e): return e.shape)
	for e in texts:
		var r: Rect2 = e.r
		if not bounds.grow(SLACK).encloses(r):
			out.append("「%s」超出圖的邊框（%s，圖 %s）" % [e.s, _rs(r), _rs(bounds)])
			continue
		var own := String(e.own)
		if own != "":
			for sh in shapes:
				if String(sh.own) == own and not (sh.r as Rect2).grow(SLACK).encloses(r):
					out.append("「%s」超出它的框（%s）" % [e.s, own])
					break
		for sh in shapes:
			if String(sh.own) != own and _hit(r, sh.r):
				out.append("「%s」壓到別的圖形（%s）" % [e.s, sh.own])
				break
	for i in texts.size():
		for j in range(i + 1, texts.size()):
			var a: Dictionary = texts[i]
			var b: Dictionary = texts[j]
			if a.s == b.s and (a.r as Rect2).is_equal_approx(b.r):
				continue   # 同一個字畫兩次（外框＋字）
			if _hit(a.r, b.r):
				out.append("「%s」和「%s」疊在一起（%s、%s）" % [a.s, b.s, _rs(a.r), _rs(b.r)])
	return out


static func _rs(r: Rect2) -> String:
	return "%d,%d %d×%d" % [int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)]
