extends RefCounted
## Q 版阿基米德（海上 NPC）：和 npc_gauss.gd 同一套比例（頭大身體小），程式畫的
##   經典形象：頭頂禿禿亮亮的、兩邊和後腦勺是白色捲髮、一大把白色捲捲的鬍子、粗粗的白眉毛、曬得黝黑的皮膚。
##   泡在木桶浴缸裡（只露出肩膀和手）；水面上漂著一頂金王冠（「我發現了！」的王冠故事）；
##   浴缸邊放一盞古希臘的小油燈（深夜的海上也看得到他）；熱水冒出一縷一縷的蒸氣。
##   整個浴缸在海上漂（不划槳），所以只有正面。
##   ArchimedesNpc.draw(ci, 浴缸底的位置, 頭的大小, 時間, 表情, 步伐(不用), 畫布變換)：浴缸＋人（對話框的頭像也用這個）
##   ArchimedesNpc.draw_sea(ci, 水面上的位置, 頭的大小, 時間, 表情, 畫布變換)：在海上漂（多了水面的影子、波紋、浴缸跟著浪搖）
##   表情：normal（泡得很舒服，眼睛瞇瞇的、會眨眼）、happy（兩手舉高大喊「我發現了！」、水花四濺）、
##         think（摸著鬍子、眼睛往上看）、talk（嘴巴一開一合、揮手）
const UITheme := preload("res://data/ui/game_theme.gd")

const SKIN := Color("e3a97c")
const SKIN_SH := Color("c98d62")
const SKIN_HI := Color("f2c8a2")
const BEARD := Color("f5f2ea")
const BEARD_SH := Color("d8d1c3")
const BEARD_LINE := Color(0.6, 0.55, 0.48, 0.6)
const EYE := Color("2e2420")
const LINE := Color(0.45, 0.28, 0.2, 0.5)
const TOWEL := Color("fbfaf6")
const TOWEL_SH := Color("dcd8cc")
const WOOD := Color("b67a44")
const WOOD_SH := Color("7d4f2a")
const WOOD_HI := Color("d79a5f")
const BAND := Color("c9a44c")
const BAND_SH := Color("9a7a30")
const WATER := Color("7fc8ea")
const WATER_HI := Color("bfe8fa")
const GOLD := Color("f2c84a")
const GOLD_SH := Color("c99a22")
const CLAY := Color("c0703f")
const FW := 0.84                 # 圓臉：半寬 0.84、半高 0.88（乘頭的大小 s）
const FH := 0.88

const NAME := "阿基米德"
const TITLE := "泡澡中 · 在海上漂"         # 靠近時下方卡片的副標

## ───────────── 對話：六個小故事（2026/11/20 使用者：直接用推薦的六個；和高斯一樣，聊聊時隨機挑一個） ─────────────
## 每一句：[說話的人, 表情, 句子]；阿基米德的表情 normal／happy／think／talk，光靈的 happy／surprised／normal
## 史實（查過資料：MacTutor、Scientific American、紐約大學 Rorres 的阿基米德網站、Wikipedia）：
##   crown  王冠和「我發現了！」：最早是維特魯威（西元前一世紀）寫的，離事情發生大約兩百年；用排開的水比體積，
##          理論上可以但實際很難量準，伽利略認為他比較可能用天平＋浮力 → 台詞說是「故事」，最後提伽利略的看法
##   pi     《圓的測量》：用正 96 邊形夾住圓，算出 3又10/71 < π < 3又1/7（223/71 < π < 22/7）
##   lever  普魯塔克：他寫信給希倫國王說任何重物都能用一定的力移動，國王要他示範，他用滑輪一個人拉動一艘裝滿貨的船。
##          「給我一個支點……」的說法來自更後來的作者
##   sand   《數沙者》：希臘的數字最大只到「一萬個一萬」，他發明新的數法，算出填滿整個宇宙的沙粒不超過 8 × 10⁶³
##   sphere 球的體積和表面積都是外切圓柱的 2/3，他最得意，希望刻在墓碑上；西元前 75 年西塞羅在西西里找到長滿雜草的墓，
##          上面真的有球和圓柱
##   book   他的書約 950 年被抄成一本，1229 年被刮掉、改寫成禱告書；1906 年海貝格認出底下的字；1998 年拍賣（兩百萬美元）；
##          之後用紫外線、紅外線等不同的光，2005 年在 SLAC 用 X 光，把被蓋住的字讀出來（裡面有《方法論》唯一的抄本）
## 不放：他過世那天的事（「別弄亂我的圓」）、燃燒鏡（太陽光燒船，可靠度低）
const TALKS := {
	"crown": [
		["阿基米德", "talk", "國王做了一頂金王冠，可是他懷疑工匠偷偷摻了銀子。要怎麼查，又不能把王冠弄壞？"],
		["阿基米德", "think", "我想了好久都想不出來，就先去泡個澡……結果一坐進浴缸，水嘩啦啦地滿出來！"],
		["阿基米德", "happy", "我一下子就想通了：用排開的水，就能比出王冠的體積！我高興得大喊「我發現了！」"],
		["光靈", "surprised", "那你有穿好衣服再跑出去嗎？"],
		["阿基米德", "happy", "哈哈，這個嘛……故事是兩百年後的人寫的，就當它是個傳說吧！"],
		["阿基米德", "talk", "後來伽利略說，我比較可能是用天平和浮力來比。不管哪一種，王冠真的被摻了銀子。"],
	],
	"pi": [
		["阿基米德", "talk", "圓的周長是直徑的幾倍？我想把這個數夾出來。"],
		["阿基米德", "think", "我在圓裡面畫一個正多邊形，外面也畫一個，圓的周長一定夾在它們中間。"],
		["光靈", "surprised", "邊數越多，就越接近圓嗎？"],
		["阿基米德", "happy", "沒錯！我從六邊形開始，一路加倍到九十六邊形。"],
		["阿基米德", "talk", "最後算出來：它比 223/71 大、比 22/7 小，也就是大約 3.14。"],
		["阿基米德", "happy", "後來的人把這個數叫做 π。夾、夾、再夾，答案就跑不掉了！"],
	],
	"lever": [
		["阿基米德", "talk", "我發現了槓桿的祕密：支點的一邊重，就把另一邊拉長，再重的東西都抬得起來。"],
		["阿基米德", "happy", "我寫信跟國王說：如果有另一個地球讓我站上去，我連這個地球都推得動！"],
		["光靈", "surprised", "國王相信了嗎？"],
		["阿基米德", "think", "他要我證明給他看。所以我在一艘裝滿貨物的大船上，接了一組滑輪。"],
		["阿基米德", "happy", "然後我一個人坐著，慢慢拉繩子，那艘大船就從船塢裡穩穩地被拉了出來！"],
		["阿基米德", "talk", "後來大家都說，我講過「給我一個支點，我就能舉起地球」。這句話，是後人幫我整理的版本喔。"],
	],
	"sand": [
		["阿基米德", "talk", "有人說：沙子多到數不完，這輩子都算不出來。"],
		["阿基米德", "think", "那時候的希臘數字，最大只寫到「一萬個一萬」。再大，就沒有名字可以叫了。"],
		["光靈", "surprised", "那要怎麼數？"],
		["阿基米德", "happy", "我自己發明了一套更大的數法，一層一層往上疊，就像你們學的指數一樣。"],
		["阿基米德", "talk", "然後我估算：把整個宇宙都裝滿沙子，也不會超過 8 × 10^{63} 粒。"],
		["阿基米德", "happy", "很多很多，可是不是「數不完」。再大的數，都能寫得出來！"],
	],
	"sphere": [
		["阿基米德", "talk", "一顆球，剛好放進一個圓柱裡：上下左右都貼得緊緊的。"],
		["阿基米德", "think", "你猜，球的體積是圓柱的多少？"],
		["光靈", "normal", "嗯……一半？"],
		["阿基米德", "happy", "是三分之二！而且球的表面積，也剛好是圓柱表面積的三分之二。"],
		["阿基米德", "talk", "這是我最得意的發現。我跟大家說：以後要在我的墓碑上，刻一顆球和一個圓柱。"],
		["阿基米德", "happy", "一百多年後，有個叫西塞羅的羅馬人，在雜草堆裡找到了那塊刻著球和圓柱的石碑呢。"],
	],
	"book": [
		["阿基米德", "talk", "我寫的書，有一本被抄在羊皮紙上，傳了好幾百年。"],
		["阿基米德", "think", "可是後來有人把上面的字刮掉，在同一張紙上改寫成一本禱告書。"],
		["光靈", "surprised", "那你的書不就不見了嗎？"],
		["阿基米德", "happy", "還沒有！1906 年，有位學者發現禱告書的字底下，隱隱約約還有我的字。"],
		["阿基米德", "talk", "後來科學家用紫外線、紅外線，還有 X 光，一頁一頁照，把被蓋住的字讀了出來。"],
		["阿基米德", "happy", "你看，光能讓消失的東西重新出現。跟你們點亮世界，是不是有點像？"],
	],
}
const HELLO_FIRST := [["阿基米德", "happy", "啊，小光靈！我是阿基米德，從西西里島的敘拉古來的。"], ["阿基米德", "talk", "泡著熱水在海上漂，最適合想事情了。要不要聽個故事？"]]
const HELLO := [
	[["阿基米德", "happy", "呼——今天的水溫剛剛好。來，聽我說個故事。"]],
	[["阿基米德", "think", "我泡著泡著，又想起一件以前的事……"]],
	[["阿基米德", "talk", "小光靈！你看，浴缸漂得多穩。這也是浮力的功勞喔。"]],
	[["阿基米德", "happy", "又見面了！要不要也來泡一下？……好啦，先聽故事。"]],
]

static var _base := Transform2D.IDENTITY


## 浴缸＋人：p 是浴缸底（和其他 NPC 的「腳底」一樣，頭的位置才會對齊）
static func draw(ci: CanvasItem, p: Vector2, s: float, t: float, mood := "normal", _walk := -1.0, base := Transform2D.IDENTITY) -> void:
	_base = base
	_scene(ci, p, s, t, mood, 0.0)


## 在海上漂：p 是水面上的位置；浴缸跟著浪上下搖、微微左右晃
static func draw_sea(ci: CanvasItem, p: Vector2, s: float, t: float, mood := "normal", base := Transform2D.IDENTITY) -> void:
	_base = base
	var bob := sin(t * 1.7) * s * 0.06
	var tilt := sin(t * 1.3) * 0.05
	# 水面上的影子和一圈一圈往外的波紋
	_ell(ci, p + Vector2(0, s * 0.05), s * 1.9, s * 0.36, Color(0, 0, 0, 0.18))
	for k in 2:
		var ph := fposmod(t * 0.35 + k * 0.5, 1.0)
		_ring(ci, p + Vector2(0, s * 0.05), s * (1.7 + ph * 1.2), s * (0.32 + ph * 0.22), Color(1, 1, 1, 0.4 * (1.0 - ph)), maxf(1.0, s * 0.04))
	# 微微左右晃：整組繞著浴缸底轉一點點
	var xf := _base * Transform2D(tilt, p + Vector2(0, bob))
	ci.draw_set_transform_matrix(xf)
	_base = xf
	_scene(ci, Vector2.ZERO, s, t, mood, 1.0)
	_base = base
	ci.draw_set_transform_matrix(base)


## 浴缸、水、人、王冠、油燈、蒸氣（sea：1 在海上，浴缸的下半截泡在海裡看不到）
static func _scene(ci: CanvasItem, p: Vector2, s: float, t: float, mood: String, sea: float) -> void:
	var w := s * 1.45                     # 浴缸口的半寬
	var rim := p + Vector2(0, -s * 0.62)  # 浴缸口（橢圓）的中心
	var ry := s * 0.3
	var water := rim + Vector2(0, s * 0.08)
	# 浴缸的內壁（後半圈）
	_ell(ci, rim, w, ry, WOOD_SH)
	_ell(ci, water, w * 0.92, ry * 0.86, WATER)
	# 蒸氣：一縷一縷往上飄
	for k in 3:
		var ph := fposmod(t * 0.4 + k / 3.0, 1.0)
		var sx := rim.x + (k - 1) * s * 0.75
		var pts := PackedVector2Array()
		for j in 7:
			var u := j / 6.0
			pts.append(Vector2(sx + sin(u * 5.0 + t * 2.0 + k) * s * 0.08, rim.y - s * (0.2 + ph * 1.6 + u * 0.5)))
		ci.draw_polyline(pts, Color(1, 1, 1, 0.35 * (1.0 - ph)), maxf(1.2, s * 0.06), true)
	# 人：肩膀以上露出水面
	var sh := water + Vector2(0, -s * 0.05)              # 兩肩中間（水面的位置）
	var head := sh + Vector2(0, -s * 1.12)
	_shoulders(ci, sh, s)
	_head(ci, head, s, t, mood)
	# 水面的前半圈蓋住身體下面、一圈泡泡
	var front := PackedVector2Array()
	for k in 17:
		var a := PI * k / 16.0
		front.append(water + Vector2(cos(a) * w * 0.92, sin(a) * ry * 0.86))
	front.append(water + Vector2(-w * 0.92, -s * 0.02))
	front.append(water + Vector2(w * 0.92, -s * 0.02))
	ci.draw_colored_polygon(_hull(front), WATER)
	_arc_e(ci, water + Vector2(0, -s * 0.02), w * 0.6, ry * 0.5, PI * 0.15, PI * 0.85, WATER_HI, maxf(1.2, s * 0.04))
	# 泡泡：浮在他身體周圍的水面上（不要排在浴缸口上，會像一圈釘子）
	for k in 7:
		var a := 0.25 + k * 0.45
		var bp := water + Vector2(cos(a) * w * 0.55, sin(a) * ry * 0.3 - s * 0.01)
		UITheme.dot(ci, bp, s * (0.06 + 0.025 * sin(k * 2.3 + t * 2.0)), Color(1, 1, 1, 0.85))
	# 漂在水面上的金王冠（開心時被他舉起來）
	if mood != "happy":
		_crown(ci, water + Vector2(-w * 0.32, s * 0.1 + sin(t * 2.5) * s * 0.03), s * 0.32, sin(t * 1.4) * 0.15)
	# 浴缸的前面：木板＋兩條銅箍；下面圓圓的（在海上時下半截泡在海裡）
	var bot := p.y if sea < 0.5 else rim.y + s * 0.42
	# 浴缸往下收窄；在海上只露出上面一小截，兩邊要幾乎直直往下（太斜會和浴缸口的弧線交叉，多邊形畫不出來）
	var taper := 0.86 if sea < 0.5 else 0.96
	var body := PackedVector2Array()
	for k in 17:
		var a := PI * k / 16.0
		body.append(rim + Vector2(cos(a) * w, sin(a) * ry))
	body.append(Vector2(rim.x - w * taper, bot - s * 0.08))
	for k in 9:
		var u := k / 8.0
		body.append(Vector2(lerpf(rim.x - w * taper, rim.x + w * taper, u), bot + sin(u * PI) * s * 0.1))
	body.append(Vector2(rim.x + w * taper, bot - s * 0.08))
	ci.draw_colored_polygon(body, WOOD)
	for k in 6:
		var x := lerpf(-0.78, 0.78, k / 5.0)
		ci.draw_line(rim + Vector2(x * w, ry * sqrt(1.0 - x * x) + s * 0.04), Vector2(rim.x + x * w * taper, bot), WOOD_SH, maxf(1.0, s * 0.03), true)
	for k in 2:
		var y := rim.y + ry + s * (0.12 + k * 0.28)
		if y < bot - s * 0.04:
			ci.draw_line(Vector2(rim.x - w * (0.98 - k * 0.07), y), Vector2(rim.x + w * (0.98 - k * 0.07), y), BAND_SH, maxf(2.0, s * 0.1), true)
			ci.draw_line(Vector2(rim.x - w * (0.98 - k * 0.07), y - s * 0.02), Vector2(rim.x + w * (0.98 - k * 0.07), y - s * 0.02), BAND, maxf(1.2, s * 0.05), true)
	_arc_e(ci, rim, w, ry, 0.0, PI, WOOD_HI, maxf(2.0, s * 0.08))    # 浴缸口的亮邊（前半圈）
	if sea > 0.5:
		# 海面切過浴缸：下緣一條白白的浪
		# 海面切過浴缸：下緣一條淡淡的白浪（細細的波浪線，不要一顆一顆的圓點，會像一排釘子）
		var foam := PackedVector2Array()
		for k in 25:
			var x := lerpf(-taper, taper, k / 24.0)
			foam.append(Vector2(rim.x + x * w, bot + sin(u_wave(x, t)) * s * 0.035 + sin(x * PI * 0.5 + PI / 2.0) * s * 0.08))
		ci.draw_polyline(foam, Color(1, 1, 1, 0.5), maxf(1.5, s * 0.07), true)
	# 油燈：放在浴缸口的右邊，小小的火焰會晃
	_lamp(ci, rim + Vector2(w * 0.86, -s * 0.02), s, t)
	# 手（畫在浴缸口前面）
	_hands(ci, sh, rim, w, s, t, mood, head)


## 肩膀：光溜溜的肩膀（大部分泡在水裡）
static func _shoulders(ci: CanvasItem, sh: Vector2, s: float) -> void:
	_ell(ci, sh + Vector2(0, s * 0.02), s * 0.62, s * 0.3, SKIN)
	_ell(ci, sh + Vector2(0, -s * 0.12), s * 0.22, s * 0.16, SKIN_SH)          # 脖子的影子


static func _hands(ci: CanvasItem, sh: Vector2, rim: Vector2, w: float, s: float, t: float, mood: String, head: Vector2) -> void:
	var arm := s * 0.2
	match mood:
		"happy":
			# 兩手舉高：「我發現了！」右手拿著王冠，水花四濺
			var up := sin(t * 6.0) * s * 0.05
			for sx in [-1.0, 1.0]:
				var hand := sh + Vector2(sx * s * 0.95, -s * 1.15 + up)
				ci.draw_line(sh + Vector2(sx * s * 0.5, 0), hand, SKIN, arm, true)
				UITheme.dot(ci, hand, s * 0.11, SKIN)
			_crown(ci, sh + Vector2(s * 0.98, -s * 1.42 + up), s * 0.34, 0.15)
			for k in 6:
				var ph := fposmod(t * 1.5 + k / 6.0, 1.0)
				var a := PI * (1.15 + k * 0.14)
				var dp := rim + Vector2(cos(a) * w * (0.6 + ph * 0.6), sin(a) * s * (0.2 + ph * 0.9) + ph * ph * s * 0.6)
				UITheme.dot(ci, dp, s * 0.06 * (1.0 - ph * 0.5), Color(0.8, 0.95, 1.0, 0.85 * (1.0 - ph)))
		"think":
			# 右手摸鬍子，左手搭在浴缸邊
			var chin := head + Vector2(s * 0.28, s * 1.0)
			ci.draw_line(sh + Vector2(s * 0.45, s * 0.02), chin, SKIN, arm, true)
			UITheme.dot(ci, chin, s * 0.11, SKIN)
			_rest(ci, sh, rim, w, s, -1.0)
		"talk":
			# 右手揮手（張開手掌：四根手指張成扇形＋大拇指，不要只伸一根手指），左手搭在浴缸邊
			var palm := head + Vector2(s * 1.18, s * 0.5)
			ci.draw_line(sh + Vector2(s * 0.5, 0), palm, SKIN, arm, true)
			var sway := sin(t * 7.0) * 0.3
			for k in 4:
				var a := -PI / 2.0 + sway + (k - 1.5) * 0.36
				var d := Vector2(cos(a), sin(a))
				ci.draw_line(palm + d * s * 0.06, palm + d * s * 0.2, SKIN, maxf(2.0, s * 0.075), true)
				UITheme.dot(ci, palm + d * s * 0.2, maxf(1.0, s * 0.037), SKIN)
			var td := Vector2.from_angle(sway + 0.15)
			ci.draw_line(palm, palm + td * s * 0.16, SKIN, maxf(2.0, s * 0.08), true)
			UITheme.dot(ci, palm, s * 0.12, SKIN)
			_rest(ci, sh, rim, w, s, -1.0)
		_:
			# 兩手搭在浴缸邊，很放鬆
			for sx in [-1.0, 1.0]:
				_rest(ci, sh, rim, w, s, sx)


## 手搭在浴缸口上
static func _rest(ci: CanvasItem, sh: Vector2, rim: Vector2, w: float, s: float, sx: float) -> void:
	var hand := rim + Vector2(sx * w * 0.8, s * 0.12)
	ci.draw_line(sh + Vector2(sx * s * 0.5, 0), hand, SKIN, s * 0.2, true)
	_ell(ci, hand, s * 0.13, s * 0.09, SKIN)


## 金王冠：一圈底座＋五個尖尖、尖端圓珠
static func _crown(ci: CanvasItem, c: Vector2, r: float, rot: float) -> void:
	var xf := Transform2D(rot, c)
	var pts := PackedVector2Array([Vector2(-r, r * 0.35), Vector2(-r, -r * 0.35), Vector2(-r * 0.6, 0.0), Vector2(-r * 0.3, -r * 0.55),
		Vector2(0.0, -r * 0.05), Vector2(r * 0.3, -r * 0.55), Vector2(r * 0.6, 0.0), Vector2(r, -r * 0.35), Vector2(r, r * 0.35)])
	var wp := PackedVector2Array()
	for q in pts:
		wp.append(xf * q)
	ci.draw_colored_polygon(wp, GOLD)
	ci.draw_line(xf * Vector2(-r, r * 0.18), xf * Vector2(r, r * 0.18), GOLD_SH, maxf(1.0, r * 0.12), true)
	for q in [Vector2(-r, -r * 0.35), Vector2(-r * 0.3, -r * 0.55), Vector2(r * 0.3, -r * 0.55), Vector2(r, -r * 0.35)]:
		UITheme.dot(ci, xf * q, r * 0.12, GOLD)
	UITheme.dot(ci, xf * Vector2(0, r * 0.18), r * 0.12, Color("e2554e"))


## 古希臘的小油燈：陶土做的、像一隻扁扁的小壺，壺嘴上一朵火
static func _lamp(ci: CanvasItem, c: Vector2, s: float, t: float) -> void:
	var glow := 0.75 + 0.25 * sin(t * 6.0)
	UITheme.dot(ci, c + Vector2(s * 0.18, -s * 0.22), s * 0.6, Color(1.0, 0.8, 0.45, 0.16 * glow))
	UITheme.dot(ci, c + Vector2(s * 0.18, -s * 0.22), s * 0.3, Color(1.0, 0.8, 0.45, 0.28 * glow))
	_ell(ci, c, s * 0.2, s * 0.1, CLAY)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.1, -s * 0.06), c + Vector2(s * 0.24, -s * 0.06), c + Vector2(s * 0.2, s * 0.02)]), CLAY)
	var f := c + Vector2(s * 0.22, -s * 0.12)
	var fl := PackedVector2Array([f + Vector2(-s * 0.05, 0), f + Vector2(sin(t * 9.0) * s * 0.03, -s * (0.2 + 0.03 * sin(t * 7.0))), f + Vector2(s * 0.05, 0)])
	ci.draw_colored_polygon(fl, Color("ffb347"))
	UITheme.dot(ci, f + Vector2(0, -s * 0.03), s * 0.03, Color("fff2b0"))


# ───────────────────────── 頭 ─────────────────────────

static func _head(ci: CanvasItem, c: Vector2, s: float, t: float, mood: String) -> void:
	# 後腦勺和兩邊的白色捲髮（一顆一顆的圓）
	for sx in [-1.0, 1.0]:
		for k in 4:
			var q := c + Vector2(sx * s * (0.82 + (0.06 if k % 2 == 0 else 0.0)), -s * 0.32 + k * s * 0.2)
			_ell(ci, q + Vector2(0, s * 0.03), s * 0.2, s * 0.18, BEARD_SH)
			_ell(ci, q, s * 0.2, s * 0.17, BEARD)
	# 臉：圓圓的；頭頂禿禿亮亮的
	_ell(ci, c, s * FW, s * FH, SKIN)
	_ell(ci, c + Vector2(-s * 0.2, -s * 0.58), s * 0.26, s * 0.13, Color(1, 1, 1, 0.35))
	_ell(ci, c + Vector2(-s * 0.32, -s * 0.5), s * 0.06, s * 0.04, Color(1, 1, 1, 0.5))
	# 耳朵（被捲髮蓋住一半）
	for sx in [-1.0, 1.0]:
		_ell(ci, c + Vector2(sx * s * 0.82, s * 0.06), s * 0.1, s * 0.14, SKIN_SH)
	# 大鬍子：從兩頰一路捲到下巴下面，一顆一顆的圓疊起來
	var beard_pts := [Vector2(-0.72, 0.22), Vector2(0.72, 0.22), Vector2(-0.66, 0.5), Vector2(0.66, 0.5), Vector2(-0.48, 0.74),
		Vector2(0.48, 0.74), Vector2(-0.22, 0.9), Vector2(0.22, 0.9), Vector2(0.0, 1.02), Vector2(-0.3, 0.6), Vector2(0.3, 0.6), Vector2(0.0, 0.72)]
	for q in beard_pts:
		_ell(ci, c + q * s + Vector2(0, s * 0.03), s * 0.22, s * 0.2, BEARD_SH)
	for q in beard_pts:
		_ell(ci, c + q * s, s * 0.22, s * 0.19, BEARD)
	for q in beard_pts:
		ci.draw_arc(c + q * s + Vector2(s * 0.02, s * 0.02), s * 0.1, PI * 0.1, PI * 1.0, 6, BEARD_LINE, maxf(1.0, s * 0.025), true)
	# 腮紅（泡熱水泡得紅通通）
	for sx in [-1.0, 1.0]:
		_ell(ci, c + Vector2(sx * s * 0.42, s * 0.2), s * 0.14, s * 0.08, Color(0.95, 0.42, 0.42, 0.35))
	_face(ci, c, s, t, mood)


static func _face(ci: CanvasItem, c: Vector2, s: float, t: float, mood: String) -> void:
	var lw := maxf(1.4, s * 0.06)
	# 粗粗的白眉毛（毛茸茸：兩三顆小圓）
	for sx in [-1.0, 1.0]:
		var bc := c + Vector2(sx * s * 0.3, -s * 0.24 - (s * 0.05 if mood == "think" else 0.0))
		for k in 3:
			_ell(ci, bc + Vector2(sx * (k - 1) * s * 0.08, -absf(k - 1.0) * s * 0.0 - (s * 0.02 if k == 1 else 0.0)), s * 0.08, s * 0.05, BEARD)
	# 眼睛：平常泡得很舒服、瞇瞇的；想事情往上看
	var blink := fposmod(t + 0.9, 3.8) < 0.12 and mood == "normal"
	for sx in [-1.0, 1.0]:
		var e := c + Vector2(sx * s * 0.3, -s * 0.06)
		if mood == "happy":
			ci.draw_arc(e + Vector2(0, s * 0.05), s * 0.1, PI * 1.15, PI * 1.85, 10, EYE, lw, true)
		elif mood == "normal":
			if blink:
				ci.draw_line(e + Vector2(-s * 0.08, 0), e + Vector2(s * 0.08, 0), EYE, lw, true)
			else:
				# 舒服得瞇起來：下半圓的眼睛
				ci.draw_arc(e + Vector2(0, -s * 0.03), s * 0.08, PI * 0.1, PI * 0.9, 8, EYE, lw, true)
		else:
			var look := Vector2(s * 0.03, -s * 0.05) if mood == "think" else Vector2.ZERO
			_ell(ci, e + look, s * 0.075, s * 0.09, EYE)
			UITheme.dot(ci, e + look + Vector2(-s * 0.025, -s * 0.03), maxf(1.0, s * 0.025), Color(1, 1, 1, 0.9))
	# 鼻子：圓圓的
	_ell(ci, c + Vector2(0, s * 0.18), s * 0.12, s * 0.09, SKIN_SH)
	_ell(ci, c + Vector2(-s * 0.03, s * 0.16), s * 0.06, s * 0.045, SKIN_HI)
	# 八字鬍＋嘴巴（嘴巴在鬍子中間露出來）
	var m := c + Vector2(0, s * 0.42)
	var lip := Color("8e3f38")
	match mood:
		"happy":
			_ell(ci, m + Vector2(0, s * 0.06), s * 0.15, s * 0.12, lip)
		"talk":
			_ell(ci, m + Vector2(0, s * 0.04), s * 0.09, s * (0.03 + 0.05 * absf(sin(t * 9.0))), lip)
		_:
			_ell(ci, m + Vector2(0, s * 0.04), s * 0.08, s * 0.03, lip)
	for sx in [-1.0, 1.0]:
		_ell(ci, m + Vector2(sx * s * 0.14, -s * 0.04), s * 0.17, s * 0.08, BEARD)
		ci.draw_arc(m + Vector2(sx * s * 0.14, -s * 0.03), s * 0.12, PI * 0.15, PI * 0.85, 6, BEARD_LINE, maxf(1.0, s * 0.025), true)


static func _ell(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)


static func u_wave(x: float, t: float) -> float:
	return x * 9.0 + t * 3.0


## 橢圓的一段弧（draw_arc 只能畫正圓）
static func _arc_e(ci: CanvasItem, c: Vector2, rx: float, ry: float, a0: float, a1: float, col: Color, wd: float) -> void:
	var pts := PackedVector2Array()
	for k in 25:
		var a := lerpf(a0, a1, k / 24.0)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_polyline(pts, col, wd, true)


static func _ring(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, wd: float) -> void:
	var pts := PackedVector2Array()
	for k in 33:
		var a := TAU * k / 32.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_polyline(pts, col, wd, true)


## 點的凸包（浴缸前面、水面前半圈這種「半個橢圓＋一條直線」的形狀，保證畫得出來）
static func _hull(pts: PackedVector2Array) -> PackedVector2Array:
	return Geometry2D.convex_hull(pts)
