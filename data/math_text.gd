@tool
extends Control
## 顯示真正上標、下標的數學式，可以和中文混排、自動換行。
## 使用方式：在要用的腳本開頭寫  const MathLabel := preload("math_text.gd")
## （本檔需與使用它的腳本放在同一個資料夾）
##
## 標記語法（寫在 text 裡）：
##   2^{0.3}               上標（單一字元可省略大括號：x^2）
##   log_{2} 0.3           下標
##   log_{2^{2}} 3^{2}     可以巢狀
##   √{a + 1}             根號（上面有一槓蓋住整個 a + 1，可以巢狀）
##   ∛{4}、∜{2}           三次、四次方根（橫線一樣蓋住裡面，左上角有小小的 3、4）
##   [color=#5ad8ff]2[/color]   上色（可放在上標裡）
##   \n                    換行
##   a/b、(x + 1)/2、a ÷ b 自動畫成上下的分數（上下標裡也會，例如 3^{1/2}、log_{1/2} x）
##   \frac{a}{b}           直接指定分數
##
## 其他用法：
##   MathLabel.make_button("log_{2} 3")         產生顯示數學式的按鈕
##   MathLabel.draw_on(canvas, font, cx, y, "2^{x}", 16, Color.WHITE)   在 _draw() 裡直接畫

const _SELF := preload("math_text.gd")
const _UI := preload("game_theme.gd")
const SUP_SCALE := 0.66     # 上標／下標字級比例
const SUP_RISE := 0.42      # 上標抬高（以字級為單位）
const SUB_DROP := 0.24      # 下標下降
const LINE_HEIGHT := 1.75
const NO_BREAK_BEFORE := "，。！？、）)」』：；,.:;!?"
const NO_BREAK_AFTER := "(（「『"
const FRAC_SCALE := 0.82    # 分子、分母的字級比例
const FRAC_AXIS := 0.30     # 分數線離基線的高度（以字級為單位）
const FRAC_GAP := 0.16      # 分數線和分子、分母的間隔

## 數學字體：數字、運算符號用襯線正體，變數用襯線斜體（像課本、MathType 的樣子）；中文仍用原本的字型
const MATH_REG_PATH := "res://fonts/MathSerif-Regular.otf"
const MATH_IT_PATH := "res://fonts/MathSerif-Italic.otf"
const MATH_SCALE := 1.12   # 襯線字的 x 高度比黑體小：放大一點，和中文看起來一樣大
const IT_EXTRA := 0.03     # 斜體字右上角會往外凸：多留一點寬度，免得撞到後面的上標或括號
## 用數學正體畫的符號（英數字以外）
const MATH_SYMS := "+−-=<>≤≥≠≈±×÷·()[]|,.:;'%∞"
## 襯線字的乘號點太窄：左右各多留一點空隙（以字級為單位）
const SIDE_PAD := {"·": 0.14}
## 這些字母組合是函數名稱，維持正體（數學排版慣例）
const UPRIGHT_WORDS := ["log", "ln", "lg", "sin", "cos", "tan", "cot", "sec", "csc", "lim", "max", "min", "exp", "mod", "gcd",
	"pH", "Ct", "dB", "PCR", "Esc", "fps", "ms", "zzz", "II", "III", "IV", "OK", "sub"]   # 單位、縮寫也不斜
const GREEK_VARS := "αβγθλμφω"

static var italic_vars := true   ## false：變數不用斜體
static var auto_frac := true     ## false：不自動把 a/b 轉成分數
static var _frac_depth := 0

@export_multiline var text := "":
	set(v):
		text = v
		_changed()
@export var font_size := 22:
	set(v):
		font_size = v
		_changed()
@export var color := _UI.TEXT:
	set(v):
		color = v
		_changed()
@export var max_width := 0.0:   ## 0 = 不自動換行
	set(v):
		max_width = v
		_changed()
@export var align_center := false:
	set(v):
		align_center = v
		_changed()
@export var valign_center := false:
	set(v):
		valign_center = v
		_changed()

var _glyphs: Array = []
var _breaks: Array = []
var _content := Vector2.ZERO
var _dirty := true


func _changed() -> void:
	_dirty = true
	update_minimum_size()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_ENTER_TREE:
		_changed()


func _get_minimum_size() -> Vector2:
	if _dirty:
		_layout()
	return _content


func _draw() -> void:
	if _dirty:
		_layout()
	var font := get_theme_default_font()
	var off := Vector2.ZERO
	if align_center and size.x > _content.x:
		off.x = (size.x - _content.x) / 2.0
	if valign_center and size.y > _content.y:
		off.y = (size.y - _content.y) / 2.0
	for g in _glyphs:
		if g.has("frac"):
			draw_frac(self, font, g.pos + off, g.frac, g.size, g.color)
		elif g.rad < 0 and g.ch != " ":
			var mf: int = g.get("mf", 0)
			var px: float = g.size * SIDE_PAD.get(g.ch, 0.0)
			draw_string(font_for(font, mf), g.pos + off + Vector2(px, 0), g.ch, HORIZONTAL_ALIGNMENT_LEFT, -1, _msize(g.size, mf), g.color)
	draw_radicals(self, _glyphs, off)


# ================= 解析 =================

## 把標記文字拆成逐字的清單：{ch, scale, dy, color, glue}
## dy 以字級為單位（負值往上）；glue = true 表示不能和前一字斷開（上下標）
static func parse(markup: String, base_color: Color) -> Array:
	# 同一段文字每一幀都會被重畫：解析結果快取起來（手機上逐字解析很花時間）
	var key := "%s|%s|%s" % [markup, base_color.to_html(), auto_frac]
	if _parse_cache.has(key):
		return _parse_cache[key]
	if _parse_cache.size() > 3000:
		_parse_cache.clear()
	var res := _parse_uncached(markup, base_color)
	_parse_cache[key] = res
	return res


static var _parse_cache: Dictionary = {}


static func _parse_uncached(markup: String, base_color: Color) -> Array:
	var out := []
	if auto_frac and (markup.contains("/") or markup.contains("÷")):
		markup = frac_markup(markup)
	_frac_depth = 0
	_parse_into(markup, 0, 1.0, 0.0, [base_color], out, false, false, [])
	if italic_vars:
		_mark_italic(out)
	# 包住分數的括號放大一點：(½)^{x}
	for k in range(1, out.size() - 1):
		var f: Dictionary = out[k]
		if f.has("frac") and f.scale > 0.99 and out[k - 1].ch == "(" and out[k + 1].ch == ")" \
				and out[k - 1].scale == f.scale and out[k + 1].scale == f.scale:
			for pk in [k - 1, k + 1]:
				out[pk] = out[pk].duplicate()
				out[pk].scale = f.scale * 1.32
				out[pk].dy = f.dy + 0.1
	return out


static func _parse_into(s: String, i: int, scale: float, dy: float, colors: Array,
		out: Array, glue: bool, in_group: bool, rads: Array) -> int:
	while i < s.length():
		var c := s[i]
		if in_group and c == "}":
			return i + 1
		# 分數：\frac{分子}{分母}（分數裡面再出現分數就寫成一行，免得字太小）
		if c == "\\" and s.substr(i, 6) == "\\frac{":
			var num := []
			var den := []
			_frac_depth += 1
			var nested := _frac_depth > 1
			# 分子分母的字級是相對於分數本身的比例；上下標裡的分數不再縮那麼多，免得看不清楚
			var fs := FRAC_SCALE if scale > 0.99 else 0.92
			i = _parse_into(s, i + 6, scale if nested else fs, dy if nested else 0.0, colors, num, glue, true, rads if nested else [])
			if i < s.length() and s[i] == "{":
				i = _parse_into(s, i + 1, scale if nested else fs, dy if nested else 0.0, colors, den, glue, true, rads if nested else [])
			_frac_depth -= 1
			if nested:
				# 寫成一行：分子 / 分母
				out.append_array(num)
				out.append({"ch": "/", "scale": scale, "dy": dy, "color": colors.back(), "glue": true, "rads": rads})
				for d in den:
					d.glue = true
				out.append_array(den)
			else:
				out.append({"ch": "", "frac": {"num": num, "den": den}, "scale": scale, "dy": dy,
					"color": colors.back(), "glue": glue, "rads": rads})
			continue
		# 線段的上橫線：\ol{AB}（用根號的機制，只畫上面那條槓、不畫勾）
		if c == "\\" and s.substr(i, 4) == "\\ol{":
			var oid := out.size()
			out.append({"ch": "", "scale": scale, "dy": dy, "color": colors.back(), "glue": glue, "rad": oid, "rads": rads, "idx": "ol"})
			var inner_o := rads.duplicate()
			inner_o.append(oid)
			i = _parse_into(s, i + 4, scale, dy, colors, out, true, true, inner_o)
			continue
		# 根號：√{…}，裡面的字都記得自己在哪個根號底下
		if (c == "√" or c == "∛" or c == "∜") and i + 1 < s.length() and s[i + 1] == "{":
			var rid := out.size()
			# ∛{…}、∜{…}：一樣畫根號和上面的橫線，左上角多一個小小的 3、4（寬度用 √ 量，指數畫在勾的上方）
			var rd := {"ch": "√", "scale": scale, "dy": dy, "color": colors.back(), "glue": glue, "rad": rid, "rads": rads}
			if c != "√":
				rd["idx"] = "3" if c == "∛" else "4"
			out.append(rd)
			var inner := rads.duplicate()
			inner.append(rid)
			i = _parse_into(s, i + 2, scale, dy, colors, out, true, true, inner)
			continue
		if c == "[" and s.substr(i, 8) == "[color=#":
			var end := s.find("]", i)
			colors.push_back(Color(s.substr(i + 7, end - i - 7)))
			i = end + 1
			continue
		if c == "[" and s.substr(i, 8) == "[/color]":
			if colors.size() > 1:
				colors.pop_back()
			i += 8
			continue
		if c == "^" or c == "_":
			var s2 := maxf(scale * SUP_SCALE, 0.52)   # 巢狀時不要縮到看不見
			var dy2 := dy + (-SUP_RISE if c == "^" else SUB_DROP) * scale
			i += 1
			if i < s.length() and s[i] == "{":
				i = _parse_into(s, i + 1, s2, dy2, colors, out, true, true, rads)
			elif i < s.length():
				out.append({"ch": s[i], "scale": s2, "dy": dy2, "color": colors.back(), "glue": true, "rads": rads})
				i += 1
			continue
		if c == "{":
			i = _parse_into(s, i + 1, scale, dy, colors, out, glue, true, rads)
			continue
		out.append({"ch": c, "scale": scale, "dy": dy, "color": colors.back(), "glue": glue, "rads": rads})
		i += 1
	return i


## 把變數（單獨的英文字母、希臘字母）標成斜體；log、sin 這類函數名稱維持正體
## 連續的英文字母（同字級、同高度）算一組：組成函數名稱、或太長（像英文單字）就不斜
static func _mark_italic(arr: Array) -> void:
	var i := 0
	while i < arr.size():
		var ch: Dictionary = arr[i]
		if ch.has("frac"):
			_mark_italic(ch.frac.num)
			_mark_italic(ch.frac.den)
			i += 1
			continue
		if not _is_letter(ch.ch):
			var cc: String = ch.ch
			if cc.length() == 1 and ((cc >= "0" and cc <= "9") or MATH_SYMS.contains(cc)) and not ch.has("rad"):
				ch["mf"] = 1
				if SIDE_PAD.has(cc):
					ch["solo"] = true
			i += 1
			continue
		var j := i
		var word := ""
		while j < arr.size() and _is_letter(arr[j].ch) and arr[j].scale == ch.scale and arr[j].dy == ch.dy:
			word += arr[j].ch
			j += 1
		var greek := GREEK_VARS.contains(word.substr(0, 1))
		var ital := greek or (word.length() <= 3 and not UPRIGHT_WORDS.has(word))
		for k in range(i, j):
			arr[k]["mf"] = 2 if ital else 1
			if ital:
				arr[k]["it"] = true
				arr[k]["solo"] = true     # 斜體字寬度多留了一點：自己畫一段
		i = j


static func _is_letter(c: String) -> bool:
	if c.length() != 1:
		return false
	var u := c.unicode_at(0)
	return (u >= 65 and u <= 90) or (u >= 97 and u <= 122) or GREEK_VARS.contains(c)


## 呼叫端如果用了 draw_set_transform，可以改用這個（保留給舊程式碼呼叫）
static var xform := Transform2D.IDENTITY

static func set_xform(ci: CanvasItem, t: Transform2D) -> void:
	xform = t
	ci.draw_set_transform_matrix(t)


static var _math_fonts: Dictionary = {}

## 依字的種類選字型：0 = 原本字型（中文）、1 = 數學正體、2 = 數學斜體
## 數學字型找不到中文或特殊符號時，會自動退回原本的字型
static func font_for(font: Font, mf: int) -> Font:
	if mf == 0 or font == null:
		return _run_font(font)
	var key := "%d|%d" % [font.get_instance_id(), mf]
	if not _math_fonts.has(key):
		var path := MATH_IT_PATH if mf == 2 else MATH_REG_PATH
		var f: Font = null
		if ResourceLoader.exists(path):
			var base = load(path)
			if base is Font:
				var fv := FontVariation.new()
				fv.base_font = base
				fv.fallbacks = [font]
				var ts := TextServerManager.get_primary_interface()
				fv.opentype_features = {ts.name_to_tag("kern"): 0, ts.name_to_tag("liga"): 0}
				f = fv
		_math_fonts[key] = f if f != null else _run_font(font)
	return _math_fonts[key]


## 字型可以用嗎（沒有數學字型檔時，一律用原本字型、正常大小）
static func _has_math() -> bool:
	return ResourceLoader.exists(MATH_REG_PATH)


static var _math_ok := -1

## 這個字實際畫出來比字級大多少（數學字型放大過）
static func _hk(ch: Dictionary) -> float:
	if ch.get("mf", 0) == 0:
		return 1.0
	if _math_ok < 0:
		_math_ok = 1 if _has_math() else 0
	return MATH_SCALE if _math_ok == 1 else 1.0

static func _msize(sz: float, mf: int) -> int:
	if mf == 0:
		return int(round(sz))
	if _math_ok < 0:
		_math_ok = 1 if _has_math() else 0
	return int(round(sz * (MATH_SCALE if _math_ok == 1 else 1.0)))


static func _is_word(c: String) -> bool:
	if c.length() != 1:
		return false
	var u := c.unicode_at(0)
	return (u >= 48 and u <= 57) or (u >= 65 and u <= 90) or (u >= 97 and u <= 122) or c == "." or c == "/"


# ================= 排版 =================

func _layout() -> void:
	_dirty = false
	_glyphs.clear()
	var font := get_theme_default_font()
	var chars := parse(text, color)

	# 1) 組成不可斷開的單位（英數字串、上下標、標點都黏在前一字上）
	var atoms := []
	var prev := ""
	for ch in chars:
		var c: String = ch.ch
		var w := 0.0
		if c != "\n":
			w = char_w(font, ch, font_size)
		ch["w"] = w
		var join: bool = not atoms.is_empty() and c != "\n" and prev != "\n" and (ch.glue
			or (_is_word(prev) and _is_word(c)) or NO_BREAK_BEFORE.contains(c)
			or (prev != "" and NO_BREAK_AFTER.contains(prev)))
		if join:
			atoms.back().items.append(ch)
			atoms.back().w += w
		else:
			atoms.append({"items": [ch], "w": w})
		prev = c

	# 2) 逐行擺放
	var lines := [[]]
	var widths := [0.0]
	for ai in atoms.size():
		var atom: Dictionary = atoms[ai]
		var first: String = atom.items[0].ch
		if first == "\n":
			lines.append([])
			widths.append(0.0)
			continue
		var last := lines.size() - 1
		if max_width > 0.0 and widths[last] + atom.w > max_width and not lines[last].is_empty():
			# 優先在「，；：⇒」這類地方換行，不要把一個算式從中間切開
			var cut := 0
			if _mathy(lines[last].back()) and _mathy(atom):
				# 整個算式放得進一行：整段一起移到下一行（不要在「y =」後面就斷開）
				cut = _whole_math_cut(lines[last], atoms, ai, max_width)
				if cut == 0:
					cut = _pref_cut(lines[last], max_width)
			if cut == 0:
				cut = _soft_cut(lines[last], atom, max_width)
			var carry: Array = []
			if cut > 0:
				carry = lines[last].slice(cut)
				lines[last] = lines[last].slice(0, cut)
				widths[last] = _atoms_w(lines[last])
			lines.append([])
			widths.append(0.0)
			last += 1
			for c2 in carry:
				if lines[last].is_empty() and c2.items[0].ch == " ":
					continue
				lines[last].append(c2)
				widths[last] += c2.w
			if first == " " and lines[last].is_empty():
				continue
		lines[last].append(atom)
		widths[last] += atom.w

	# 給測試用：記下每個自動換行的位置（前一行最後一個字、下一行第一個字、括號深度）
	_breaks = []
	var dd := 0
	for li in lines.size():
		for atom in lines[li]:
			for it in atom.items:
				if it.ch == "(" or it.ch == "（":
					dd += 1
				elif it.ch == ")" or it.ch == "）":
					dd = maxi(0, dd - 1)
		if li + 1 < lines.size() and not lines[li].is_empty() and not lines[li + 1].is_empty():
			_breaks.append([lines[li].back().items.back().ch, lines[li + 1][0].items[0].ch, dd])
	var widest := 0.0
	for w in widths:
		widest = maxf(widest, w)
	var box_w := max_width if max_width > 0.0 else widest
	var lh := font_size * LINE_HEIGHT
	var cursor := 0.0
	for li in lines.size():
		var x: float = (box_w - widths[li]) / 2.0 if align_center else 0.0
		# 有分數的那一行比較高：上下各多留一點空間
		var up := 0.0
		var down := 0.0
		for atom in lines[li]:
			for ch in atom.items:
				if ch.has("frac"):
					var ext := frac_extent(ch.frac, font_size * ch.scale)
					up = maxf(up, ext.x - ch.dy * font_size - font_size * 0.95)
					down = maxf(down, ext.y + ch.dy * font_size - font_size * 0.4)
		var base_y := cursor + font_size * 1.2 + up
		for atom in lines[li]:
			for ch in atom.items:
				if ch.ch != " " or not ch.rads.is_empty() or ch.has("frac"):
					var g := {"ch": ch.ch, "pos": Vector2(x, base_y + ch.dy * font_size),
						"size": int(round(font_size * ch.scale)), "color": ch.color, "w": ch.w,
						"rad": ch.get("rad", -1), "idx": ch.get("idx", ""), "rads": ch.rads, "mf": ch.get("mf", 0)}
					if ch.has("frac"):
						g["frac"] = ch.frac
					_glyphs.append(g)
				x += ch.w
		cursor += lh + up + down
	_content = Vector2(box_w, cursor)
	# 數學式按鈕（make_button）：式子比按鈕高（例如有分數）時，把按鈕撐高一點，不要讓字貼到或超出按鈕邊
	var par := get_parent()
	if name == "Math" and par is Button:
		var need := cursor + 4.0
		if (par as Button).custom_minimum_size.y < need:
			(par as Button).custom_minimum_size.y = need


## 這一行結尾的算式（從最後一個中文字之後開始）加上後面還沒排的部分，如果整段放得進一行，
## 就回傳算式開始的位置（整段移到下一行）；放不下或算式就是整行，回傳 0
static func _whole_math_cut(line: Array, atoms: Array, ai: int, max_w: float) -> int:
	var k := line.size()
	while k > 0 and _mathy(line[k - 1]) and not _has_break_punct(line[k - 1]):
		k -= 1
	if k <= 0 or k >= line.size():
		return 0
	var w := _atoms_w(line.slice(k))
	var j := ai
	while j < atoms.size() and atoms[j].items[0].ch != "\n" and _mathy(atoms[j]) and not _has_break_punct(atoms[j]):
		w += atoms[j].w
		j += 1
	# 開頭的空白到下一行會被拿掉
	if line[k].items[0].ch == " ":
		w -= line[k].w
	return k if w <= max_w else 0


static func _has_break_punct(atom: Dictionary) -> bool:
	for it in atom.items:
		if PREFER_BREAK.contains(String(it.ch)) and String(it.ch) != "":
			return true
	return false


const PREFER_BREAK := "，；。：⇒⇔→、"
const RELATION_BREAK := "=<>≤≥≈≠"     # 次好的換行位置：關係符號之後（括號外）


## 這一行如果要斷開，最好斷在哪裡（第幾個單位之後）；找不到好位置就回傳 0
## 優先順序：「，；⇒→」這類標點之後 ＞ 括號外的「= < >」之後；括號裡面絕對不斷
static func _pref_cut(line: Array, max_w: float) -> int:
	# 每個切點前面的括號深度
	var depth := []
	var d := 0
	for a in line:
		for it in a.items:
			var c: String = it.ch
			if c == "(" or c == "[" or c == "（":
				d += 1
			elif c == ")" or c == "]" or c == "）":
				d = maxi(0, d - 1)
		depth.append(d)
	var best2 := 0
	var w := _atoms_w(line)
	for j in range(line.size() - 1, 0, -1):
		w -= line[j].w
		if w < max_w * 0.3:
			break
		var lastch: String = line[j - 1].items.back().ch
		if lastch == " " and line[j - 1].items.size() > 1:
			lastch = line[j - 1].items[line[j - 1].items.size() - 2].ch
		if depth[j - 1] > 0:
			continue
		if PREFER_BREAK.contains(lastch):
			return j
		if best2 == 0 and RELATION_BREAK.contains(lastch) and lastch != "":
			best2 = j
	return best2


## 中英數混排時的補救：不要把括號裡的算式拆開、不要把數字和後面的單位（「100 支」）拆開
static func _soft_cut(line: Array, atom: Dictionary, max_w: float) -> int:
	# 1) 這一行最後有還沒關上的括號：整個括號移到下一行
	var d := 0
	var open_at := -1
	for k in line.size():
		for it in line[k].items:
			var c: String = it.ch
			if c == "(" or c == "（":
				if d == 0:
					open_at = k
				d += 1
			elif c == ")" or c == "）":
				d = maxi(0, d - 1)
				if d == 0:
					open_at = -1
	if d > 0 and open_at > 0 and _atoms_w(line.slice(0, open_at)) >= max_w * 0.3:
		return open_at
	# 2) 下一個字是中文、這一行結尾是一段算式（例如「x > 0 」「100 」）：整段算式跟著一起換行，不從中間切開
	var first: String = atom.items[0].ch
	if first != "" and first.unicode_at(0) >= 0x3400 and line.size() >= 2 and line.back().items[0].ch == " ":
		var k := line.size() - 1
		while k > 0:
			var a: Dictionary = line[k - 1]
			var stop := false
			for it in a.items:
				var c: String = it.ch
				if c != "" and (c.unicode_at(0) >= 0x3000 or PREFER_BREAK.contains(c)):
					stop = true
			if stop:
				break
			k -= 1
		if k > 0 and k < line.size() - 1 and _atoms_w(line.slice(0, k)) >= max_w * 0.3 and _atoms_w(line.slice(k)) < max_w * 0.7:
			return k
	return 0


## 這個單位是算式的一部分（裡面沒有中文字）
static func _mathy(atom: Dictionary) -> bool:
	for it in atom.items:
		var c: String = it.ch
		if c == "" or c == " ":
			continue
		var u := c.unicode_at(0)
		if u >= 0x3400 and u <= 0x9fff:      # 中文字（全形括號、標點不算）
			return false
	return true


static func _atoms_w(line: Array) -> float:
	var w := 0.0
	for a in line:
		w += a.w
	return w


# ================= 工具函式 =================

## 在任何 CanvasItem 的 _draw() 裡畫一行數學式（以 center_x 置中，y 為基線）
## reveal ≥ 0：只畫前 reveal 個字（逐字出現的動畫；小數部分是正在浮現的那個字）
static func draw_on(ci: CanvasItem, font: Font, center_x: float, baseline_y: float,
		markup: String, fs: int, col: Color, reveal: float = -1.0) -> void:
	if reveal < 0.0:
		# 完整顯示（最常見）：整行的排版結果快取起來，每一幀只剩幾個 draw_string
		var ops := _line_ops(font, markup, fs, col)
		var off := Vector2(center_x, baseline_y)
		var rf := _run_font(font)
		for r in ops.runs:
			ci.draw_string(rf if r[5] == 0 else font_for(font, r[5]), off + r[1], r[0], HORIZONTAL_ALIGNMENT_LEFT, -1, r[6], r[3])
		for f in ops.fracs:
			draw_frac(ci, font, off + f[0], f[1], f[2], f[3])
		if ops.rad:
			draw_radicals(ci, ops.gl, off)
		return
	var chars := parse(markup, col)
	var ws := _widths(font, chars, markup, fs)
	var total := 0.0
	for w in ws:
		total += w
	var x := center_x - total / 2.0
	var gl := []
	# 同字級、同顏色、同基線的連續字合成一次 draw_string（逐字畫在手機上很慢）
	var run := ""
	var run_pos := Vector2.ZERO
	var run_fs := 0
	var run_col := Color()
	var run_next := -1
	var run_mf := 0
	var run_solo := false
	for i in chars.size():
		var ch: Dictionary = chars[i]
		var a := 1.0 if reveal < 0.0 else clampf(reveal - i, 0.0, 1.0)
		if a <= 0.0:
			break
		var pos := Vector2(x, baseline_y + ch.dy * fs + (1.0 - a) * fs * 0.35)
		var c: Color = ch.color
		c.a *= a
		var gfs := int(round(fs * ch.scale))
		if ch.has("frac"):
			draw_frac(ci, font, pos, ch.frac, gfs, c)
		elif not ch.has("rad"):
			# 只能接在「緊鄰的前一個字」後面：中間隔著分數、根號、換字型時要另起一段，不然位置會跑掉
			var mf: int = ch.get("mf", 0)
			var solo: bool = ch.get("solo", false)
			if run != "" and run_next == i and gfs == run_fs and c == run_col and pos.y == run_pos.y and mf == run_mf and not solo and not run_solo:
				run += ch.ch
			else:
				if run != "":
					ci.draw_string(font_for(font, run_mf), run_pos, run, HORIZONTAL_ALIGNMENT_LEFT, -1, _msize(run_fs, run_mf), run_col)
				run = ch.ch
				run_pos = pos + Vector2(gfs * SIDE_PAD.get(ch.ch, 0.0), 0)
				run_fs = gfs
				run_col = c
				run_mf = mf
				run_solo = solo
			run_next = i + 1
		gl.append({"ch": ch.ch, "pos": pos, "size": int(round(fs * ch.scale)), "color": c, "w": ws[i],
			"rad": ch.get("rad", -1), "idx": ch.get("idx", ""), "rads": ch.rads})
		x += ws[i]
	if run != "":
		ci.draw_string(font_for(font, run_mf), run_pos, run, HORIZONTAL_ALIGNMENT_LEFT, -1, _msize(run_fs, run_mf), run_col)
	draw_radicals(ci, gl, Vector2.ZERO)


## 和 draw_string 一樣的用法（左上角對齊方式、寬度），但用數學排版畫：變數會是斜體
## 不自動轉分數（圖上的小標籤維持一行），align / width 的意思和 draw_string 相同
static func draw_text(ci: CanvasItem, font: Font, pos: Vector2, markup: String, align: int, width: float,
		fs: int, col: Color) -> void:
	var keep := auto_frac
	auto_frac = false
	var w := text_width(font, markup, fs)
	var cx := pos.x + w / 2.0
	if width > 0.0:
		if align == HORIZONTAL_ALIGNMENT_CENTER:
			cx = pos.x + width / 2.0
		elif align == HORIZONTAL_ALIGNMENT_RIGHT:
			cx = pos.x + width - w / 2.0
	draw_on(ci, font, cx, pos.y, markup, fs, col)
	auto_frac = keep


static var _ops_cache: Dictionary = {}
static var _run_fonts: Dictionary = {}

## 合併字串用的字型：關掉字距微調與連字，和逐字畫的位置完全一樣
static func _run_font(font: Font) -> Font:
	if font == null:
		return font
	var id := font.get_instance_id()
	if not _run_fonts.has(id):
		var ts := TextServerManager.get_primary_interface()
		var fv := FontVariation.new()
		fv.base_font = font
		fv.opentype_features = {ts.name_to_tag("kern"): 0, ts.name_to_tag("liga"): 0, ts.name_to_tag("clig"): 0, ts.name_to_tag("calt"): 0}
		_run_fonts[id] = fv
	return _run_fonts[id]

## draw_on 的排版結果（以中心 0、基線 0 為準）：合併好的字串、分數、根號
static func _line_ops(font: Font, markup: String, fs: int, col: Color) -> Dictionary:
	var key := "%d|%d|%s|%s|%s" % [font.get_instance_id() if font else 0, fs, col.to_html(), auto_frac, markup]
	if _ops_cache.has(key):
		return _ops_cache[key]
	if _ops_cache.size() > 2000:
		_ops_cache.clear()
	var chars := parse(markup, col)
	var ws := _widths(font, chars, markup, fs)
	var total := 0.0
	for w in ws:
		total += w
	var x := -total / 2.0
	var runs := []
	var fracs := []
	var gl := []
	var rad := false
	for i in chars.size():
		var ch: Dictionary = chars[i]
		var pos := Vector2(x, ch.dy * fs)
		var c: Color = ch.color
		var gfs := int(round(fs * ch.scale))
		if ch.has("frac"):
			fracs.append([pos, ch.frac, gfs, c])
		elif not ch.has("rad"):
			# [字串, 位置, 字級, 顏色, 下一個字的編號, 字型種類, 實際字級]；斜體字各自一段（寬度多留了一點）
			var mf: int = ch.get("mf", 0)
			var last = runs.back() if not runs.is_empty() else null
			var solo: bool = ch.get("solo", false)
			if last != null and last[4] == i and last[2] == gfs and last[3] == c and last[1].y == pos.y and last[5] == mf and not solo and not last[7]:
				last[0] += ch.ch
				last[4] = i + 1
			else:
				runs.append([ch.ch, pos + Vector2(gfs * SIDE_PAD.get(ch.ch, 0.0), 0), gfs, c, i + 1, mf, _msize(gfs, mf), solo])
		if ch.get("rad", -1) >= 0:
			rad = true
		gl.append({"ch": ch.ch, "pos": pos, "size": gfs, "color": c, "w": ws[i],
			"rad": ch.get("rad", -1), "idx": ch.get("idx", ""), "rads": ch.rads})
		x += ws[i]
	var res := {"runs": runs, "fracs": fracs, "gl": gl, "rad": rad}
	_ops_cache[key] = res
	return res


## 一行數學式因為分數（含上下標裡的分數）比平常的字多出來的高度：Vector2(上方多出, 下方多出)
## 用來在 draw_on 一行一行畫的時候，替有分數的那一行多留空間
static var _extra_cache: Dictionary = {}

static func line_extra(font: Font, markup: String, fs: float) -> Vector2:
	if not (markup.contains("/") or markup.contains("÷") or markup.contains("\\frac")):
		return Vector2.ZERO
	# 版面計算每一幀會問很多次：結果快取起來
	var key := "%s|%s|%s" % [fs, auto_frac, markup]
	if _extra_cache.has(key):
		return _extra_cache[key]
	if _extra_cache.size() > 3000:
		_extra_cache.clear()
	var res := _line_extra_calc(font, markup, fs)
	_extra_cache[key] = res
	return res


static func _line_extra_calc(font: Font, markup: String, fs: float) -> Vector2:
	var up := 0.0
	var down := 0.0
	for ch in parse(markup, Color.WHITE):
		if ch.has("frac"):
			var ext := frac_extent(ch.frac, fs * ch.scale)
			up = maxf(up, ext.x - ch.dy * fs - fs * 0.95)
			down = maxf(down, ext.y + ch.dy * fs - fs * 0.4)
	return Vector2(up, down)


## 一行數學式在基線上方、下方實際占多高（Vector2(上, 下)，含上下標、分數）：替圖上的小標籤量框框用
static func line_extent(markup: String, fs: float) -> Vector2:
	var up := fs * 0.78
	var down := fs * 0.22
	for ch in parse(markup, Color.WHITE):
		if ch.has("frac"):
			var ext := frac_extent(ch.frac, fs * ch.scale)
			up = maxf(up, ext.x - ch.dy * fs)
			down = maxf(down, ext.y + ch.dy * fs)
		elif ch.ch != " ":
			up = maxf(up, -ch.dy * fs + ch.scale * fs * 0.78 * _hk(ch))
			down = maxf(down, ch.dy * fs + ch.scale * fs * 0.22 * _hk(ch))
	return Vector2(up, down)


## 一個字（或一整個分數）的寬度
static func char_w(font: Font, ch: Dictionary, fs: float) -> float:
	if ch.has("frac"):
		var sz: float = fs * ch.scale
		return maxf(_row_w(font, ch.frac.num, sz), _row_w(font, ch.frac.den, sz)) + sz * 0.36
	var sz := int(round(fs * ch.scale))
	var mf: int = ch.get("mf", 0)
	var w := font_for(font, mf).get_string_size(ch.ch, HORIZONTAL_ALIGNMENT_LEFT, -1, _msize(sz, mf)).x
	if mf == 2:
		w += sz * IT_EXTRA
	w += sz * SIDE_PAD.get(ch.ch, 0.0) * 2.0
	if ch.get("idx", "") != "":
		w += sz * IDX_PAD          # 三次、四次方根：左邊多留位置給根指數
	return w


static func _row_w(font: Font, row: Array, fs: float) -> float:
	var w := 0.0
	for ch in row:
		w += char_w(font, ch, fs)
	return w


## 整段標記文字畫出來的寬度
static func text_width(font: Font, markup: String, fs: float) -> float:
	var total := 0.0
	for w in _widths(font, parse(markup, Color.WHITE), markup, fs):
		total += w
	return total


## 每個字的寬度：同一字型、字級、內容只量一次（每一幀逐字量寬度在手機上很花時間）
static var _width_cache: Dictionary = {}

static func _widths(font: Font, chars: Array, markup: String, fs: float) -> Array:
	var key := "%d|%s|%s|%s" % [font.get_instance_id() if font else 0, fs, auto_frac, markup]
	if _width_cache.has(key):
		return _width_cache[key]
	if _width_cache.size() > 3000:
		_width_cache.clear()
	var ws := []
	for ch in chars:
		ws.append(char_w(font, ch, fs))
	_width_cache[key] = ws
	return ws


## 分數在基線上方、下方各占多高（Vector2(上, 下)，單位是像素）
static func frac_extent(fr: Dictionary, fs: float) -> Vector2:
	var axis := fs * FRAC_AXIS
	var gap := fs * FRAC_GAP
	var top := 0.0
	for ch in fr.num:
		top = maxf(top, -ch.dy * fs + ch.scale * fs * 0.78 * _hk(ch))
	var bot := 0.0
	for ch in fr.den:
		bot = maxf(bot, ch.dy * fs + ch.scale * fs * 0.22 * _hk(ch))
	var den_asc := 0.0
	for ch in fr.den:
		den_asc = maxf(den_asc, -ch.dy * fs + ch.scale * fs * 0.74 * _hk(ch))
	return Vector2(axis + gap + top, -axis + gap + den_asc + bot)


## 畫一個分數：pos 是左邊、基線的位置
static func draw_frac(ci: CanvasItem, font: Font, pos: Vector2, fr: Dictionary, fs: int, col: Color) -> void:
	var nw := _row_w(font, fr.num, fs)
	var dw := _row_w(font, fr.den, fs)
	var w := maxf(nw, dw) + fs * 0.36
	var axis_y := pos.y - fs * FRAC_AXIS
	var gap := fs * FRAC_GAP
	ci.draw_line(Vector2(pos.x + fs * 0.06, axis_y), Vector2(pos.x + w - fs * 0.06, axis_y), col, maxf(1.2, fs * 0.07), true)
	# 分子：底部（含下標）貼著分數線上方
	var num_desc := 0.0
	for ch in fr.num:
		num_desc = maxf(num_desc, ch.dy * fs + ch.scale * fs * 0.2 * _hk(ch))
	_draw_row(ci, font, Vector2(pos.x + (w - nw) / 2.0, axis_y - gap - num_desc), fr.num, fs, col)
	var den_asc := 0.0
	for ch in fr.den:
		den_asc = maxf(den_asc, -ch.dy * fs + ch.scale * fs * 0.74 * _hk(ch))
	_draw_row(ci, font, Vector2(pos.x + (w - dw) / 2.0, axis_y + gap + den_asc), fr.den, fs, col)


static func _draw_row(ci: CanvasItem, font: Font, base: Vector2, row: Array, fs: float, col: Color) -> void:
	var x := base.x
	var gl := []
	for ch in row:
		var w := char_w(font, ch, fs)
		var c: Color = ch.color
		c.a *= col.a
		var p := Vector2(x, base.y + ch.dy * fs)
		var sz := int(round(fs * ch.scale))
		if ch.has("frac"):
			draw_frac(ci, font, p, ch.frac, sz, c)
		elif not ch.has("rad"):
			var mf: int = ch.get("mf", 0)
			ci.draw_string(font_for(font, mf), p + Vector2(sz * SIDE_PAD.get(ch.ch, 0.0), 0), ch.ch, HORIZONTAL_ALIGNMENT_LEFT, -1, _msize(sz, mf), c)
		gl.append({"ch": ch.ch, "pos": p, "size": sz, "color": c, "w": w, "rad": ch.get("rad", -1), "idx": ch.get("idx", ""), "rads": ch.rads})
		x += w
	draw_radicals(ci, gl, Vector2.ZERO)


# ================= 自動分數 =================

## 把最外層的「a/b」改寫成 \frac{a}{b}：
##   分子／分母可以是：數字或字母（含上下標）、括號整組（外層括號拿掉）、log_{a} b、log (…)、√{…}
##   上下標、根號裡的 / 不動；兩邊有中文、太長、或看不出是什麼的就保持原樣
static func frac_markup(s: String) -> String:
	var i := 0
	while i < s.length():
		var c := s[i]
		if c == "[" and (s.substr(i, 8) == "[/color]" or s.substr(i, 8) == "[color=#"):
			i = s.find("]", i) + 1
			continue
		if (c == "/" or c == "÷") and not (i > 0 and s[i - 1] == ":") and not (i + 1 < s.length() and s[i + 1] == "/"):
			var j := i - 1
			while j >= 0 and s[j] == " ":
				j -= 1
			var ns := _tok_back(s, j)
			var k := i + 1
			while k < s.length() and s[k] == " ":
				k += 1
			var de := _tok_fwd(s, k)
			if ns >= 0 and de > k:
				var num := _strip_group(s.substr(ns, j - ns + 1))
				var den := _strip_group(s.substr(k, de - k))
				# 「3 / 5 題」這種前後有空白的整數 / 整數是進度，不是分數
				var counter := c == "/" and num.is_valid_int() and den.is_valid_int() and j < i - 1 and k > i + 1
				if _frac_ok(num) and _frac_ok(den) and not counter and not num.contains("%") and not den.contains("%"):
					var rep := "\\frac{" + num + "}{" + den + "}"
					s = s.substr(0, ns) + rep + s.substr(de)
					i = ns + rep.length()
					continue
		i += 1
	return s


static func _frac_ok(t: String) -> bool:
	if t.strip_edges() == "" or t.length() > 60:
		return false
	for ch in t:
		var u := ch.unicode_at(0)
		if (u >= 0x3000 and u <= 0x9fff) or (u >= 0xff00 and u <= 0xffef):
			return false
	return true


static func _is_tok(c: String) -> bool:
	if c.length() != 1:
		return false
	var u := c.unicode_at(0)
	return (u >= 48 and u <= 57) or (u >= 65 and u <= 90) or (u >= 97 and u <= 122) or c == "." \
		or (u >= 0x3b1 and u <= 0x3c9) or c == "π" or c == "′"


## 外層是一整組括號就拿掉：(x + 1) → x + 1（但 (a)(b) 這種不是同一組的不拿）
static func _strip_group(t: String) -> String:
	t = t.strip_edges()
	if t.length() >= 2 and ((t[0] == "(" and t[-1] == ")") or (t[0] == "[" and t[-1] == "]")):
		if _match_fwd(t, 0) == t.length() - 1:
			return t.substr(1, t.length() - 2)
	return t


static func _match_fwd(s: String, i: int) -> int:
	var open := s[i]
	var close := ")" if open == "(" else ("]" if open == "[" else "}")
	var d := 0
	for k in range(i, s.length()):
		if s[k] == open:
			d += 1
		elif s[k] == close:
			d -= 1
			if d == 0:
				return k
	return -1


static func _match_back(s: String, j: int) -> int:
	var close := s[j]
	var open := "(" if close == ")" else ("[" if close == "]" else "{")
	var d := 0
	var k := j
	while k >= 0:
		if s[k] == close:
			d += 1
		elif s[k] == open:
			d -= 1
			if d == 0:
				return k
		k -= 1
	return -1


## 往前找「log」或「log_{…}」（中間可以隔一個空白）：找到就回傳 log 的開頭，否則 −1
static func _log_before(s: String, k: int) -> int:
	if k >= 0 and s[k] == " ":
		k -= 1
	if k < 0:
		return -1
	if s[k] == "}":
		var m := _match_back(s, k)
		if m >= 4 and s[m - 1] == "_" and s.substr(m - 4, 3) == "log":
			return m - 4
		return -1
	if k >= 2 and s.substr(k - 2, 3) == "log":
		return k - 2
	return -1


## 分子：j 是分子最後一個字，回傳分子開頭（−1 = 不是可以轉的分子）
static func _tok_back(s: String, j: int) -> int:
	if j < 0:
		return -1
	var c := s[j]
	var start := -1
	if c == "]":
		# 這個 ] 是顏色標記的結尾（[color=#…] 或 [/color]）：不是分子
		var lb := s.rfind("[", j)
		if lb >= 0 and (s.substr(lb, 7) == "[/color" or s.substr(lb, 7) == "[color="):
			return -1
	if c == ")" or c == "]":
		start = _match_back(s, j)
		if start < 0:
			return -1
		var lg := _log_before(s, start - 1)
		if lg >= 0:
			start = lg
		else:
			# 係數或函數名稱緊貼著括號：3(m + 2)/3、f(x)/2 → 整個當分子
			while start - 1 >= 0 and _is_tok(s[start - 1]):
				start -= 1
	elif c == "}":
		var m := _match_back(s, j)
		if m < 1:
			return -1
		var mk := s[m - 1]
		if mk == "^" or mk == "_":
			start = _tok_back(s, m - 2)
		elif mk == "√" or mk == "∛" or mk == "∜":
			start = m - 1
		else:
			return -1
	elif _is_tok(c):
		start = j
		while start - 1 >= 0 and _is_tok(s[start - 1]):
			start -= 1
		if s.substr(start, 3) != "log":
			var lg2 := _log_before(s, start - 1)
			if lg2 >= 0:
				start = lg2
	# 前面緊接著三角函數名稱（中間一個空白）：sin 2θ ÷ cos 2θ 的分子是整個 sin 2θ
	if start >= 4 and s[start - 1] == " " and s.substr(start - 4, 3) in ["sin", "cos", "tan", "cot", "sec", "csc"] \
			and (start - 4 == 0 or not _is_tok(s[start - 5])):
		start -= 4
		# 前面還有係數：2 tan θ ÷ (1 − tan²θ) 的分子是 2 tan θ
		if start >= 2 and s[start - 1] == " " and s[start - 2].is_valid_int():
			start -= 1
			while start - 1 >= 0 and s[start - 1].is_valid_int():
				start -= 1
	return start


## 分母：k 是分母第一個字，回傳分母結尾的下一個位置（≤ k 表示不是可以轉的分母）
static func _tok_fwd(s: String, k: int) -> int:
	if k >= s.length():
		return k
	var c := s[k]
	var e := k
	# 顏色標記不是分母（例如輸入到一半的「−33/」後面緊接著 [/color]）
	if s.substr(k, 7) == "[/color" or s.substr(k, 7) == "[color=":
		return k
	if c == "(" or c == "[":
		var m := _match_fwd(s, k)
		if m < 0:
			return k
		e = m + 1
	elif (c == "√" or c == "∛" or c == "∜") and k + 1 < s.length() and s[k + 1] == "{":
		var m2 := _match_fwd(s, k + 1)
		if m2 < 0:
			return k
		e = m2 + 1
	elif s.substr(k, 3) == "log":
		e = k + 3
		if e + 1 < s.length() and s[e] == "_" and s[e + 1] == "{":
			e = _match_fwd(s, e + 1) + 1
		if e < s.length() and s[e] == " ":
			e += 1
		var e2 := _tok_fwd(s, e)
		if e2 <= e:
			return k
		e = e2
		return e
	elif _is_tok(c):
		while e < s.length() and _is_tok(s[e]):
			e += 1
		# 函數名稱後面緊接著括號：sin(θ/2) ÷ cos(θ/2) 的分母是整個 cos(θ/2)
		var word := s.substr(k, e - k)
		if word in ["sin", "cos", "tan", "cot", "sec", "csc"] and e < s.length() and s[e] == "(":
			var mf := _match_fwd(s, e)
			if mf > 0:
				e = mf + 1
		elif word in ["sin", "cos", "tan", "cot", "sec", "csc"] and e + 1 < s.length() and s[e] == " " and _is_tok(s[e + 1]):
			# cos 2θ：函數名稱、空白、角度一起當分母
			e += 1
			while e < s.length() and _is_tok(s[e]):
				e += 1
	else:
		return k
	# 後面接著的上下標也算進來：x^{2}、x_{1}
	while e + 1 < s.length() and (s[e] == "^" or s[e] == "_"):
		if s[e + 1] == "{":
			var m3 := _match_fwd(s, e + 1)
			if m3 < 0:
				break
			e = m3 + 1
		else:
			e += 2
	return e


## 這段標記文字有幾個字（逐字動畫用）
static func glyph_count(markup: String) -> int:
	return parse(markup, Color.WHITE).size()


## 畫根號：打勾的形狀，再往右拉一條槓蓋住裡面的字（裡面的根號先畫，外面的槓要更高）
static func draw_radicals(ci: CanvasItem, glyphs: Array, off: Vector2) -> void:
	var opens := []
	for g in glyphs:
		if g.rad >= 0:
			opens.append(g)
	if opens.is_empty():
		return
	opens.sort_custom(func(a, b): return a.rads.size() > b.rads.size())
	var bar_y := {}
	for o in opens:
		var rid: int = o.rad
		var sz: float = o.size
		var base: float = o.pos.y + off.y
		var top := base - sz * 0.86
		var low := sz * 0.06
		var x_end: float = o.pos.x + off.x + o.w
		for g in glyphs:
			if not g.rads.has(rid):
				continue
			x_end = maxf(x_end, g.pos.x + off.x + g.w)
			top = minf(top, g.pos.y + off.y - g.size * 0.86)
			if g.has("frac"):
				# 根號裡面是直式分數：槓要畫在分子上面，勾要伸到分母下面
				var fe := frac_extent(g.frac, g.size)
				top = minf(top, g.pos.y + off.y - fe.x - g.size * 0.1)
				low = maxf(low, fe.y)
			if g.rad >= 0 and bar_y.has(g.rad):
				top = minf(top, bar_y[g.rad] - maxf(4.0, sz * 0.18))
		bar_y[rid] = top
		if o.get("idx", "") == "ol":
			# 線段符號：字的上方一條橫線
			var olw := maxf(1.0, sz * 0.06)
			var oy := top - sz * 0.02
			ci.draw_line(Vector2(o.pos.x + off.x + sz * 0.04, oy), Vector2(x_end - sz * 0.02, oy), o.color, olw, true)
			continue
		var x0: float = o.pos.x + off.x
		var w: float = o.w
		var has_idx: bool = o.get("idx", "") != ""
		if has_idx:
			x0 += sz * IDX_PAD
			w -= sz * IDX_PAD
		var lw := maxf(1.2, sz * 0.075)
		var pts := PackedVector2Array([
			Vector2(x0 + w * 0.04, base - sz * 0.30),
			Vector2(x0 + w * 0.24, base - sz * 0.38),
			Vector2(x0 + w * 0.50, base + low),
			Vector2(x0 + w * 0.88, top),
			Vector2(x_end + sz * 0.05, top)])
		ci.draw_polyline(pts, o.color, lw, true)
		if o.get("idx", "") != "":
			# 根指數：畫在根號勾勾的左上方
			var ifs := int(maxf(10.0, sz * 0.6))
			ci.draw_string(_idx_font(), Vector2(o.pos.x + off.x + sz * 0.02, base - sz * 0.36), o.idx, HORIZONTAL_ALIGNMENT_LEFT, -1, ifs, o.color)


const IDX_PAD := 0.24       # 根指數占的寬度（字級的比例）
static var _idx_f: Font

## 根指數用的字型（數學字型的正體；沒有就用預設字型）
static func _idx_font() -> Font:
	if _idx_f == null:
		_idx_f = font_for(ThemeDB.fallback_font, 1)
	return _idx_f


## 產生一個顯示數學式的按鈕（按鈕本身沒有文字，數學式畫在子節點上）
static func make_button(markup: String, fs: int = 20, min_size: Vector2 = Vector2(0, 44),
		centered: bool = true) -> Button:
	var b := Button.new()
	b.custom_minimum_size = min_size
	var m: Control = _SELF.new()
	m.name = "Math"
	m.text = markup
	m.font_size = _UI.fs(fs)
	m.align_center = centered
	m.valign_center = true
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not centered:
		m.offset_left = 14
	b.add_child(m)
	return b
