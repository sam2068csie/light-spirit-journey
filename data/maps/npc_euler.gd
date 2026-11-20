extends RefCounted
## Q 版歐拉（海上 NPC）：和 npc_gauss.gd 同一套比例（頭大身體小），程式畫的
##   參考他最常見的肖像（Handmann 1753）：頭上包著一頂米白色的布帽、圓圓的臉、大鼻子、溫和的笑；
##   右眼瞇瞇的（他 1738 年左右右眼看不見了，肖像上看得出來，畫得很輕）。深青色外套、白領巾。
##   招牌道具：一支羽毛筆（他一輩子寫了非常多論文）
##   在海上坐一艘掛著燈籠的小划船（和光舟分得開：沒有帆、船尾一根燈籠桿、小旗子上寫 e）
##   EulerNpc.draw(ci, 腳底的位置, 頭的大小, 時間, 表情, 步伐, 呼叫的人設好的畫布變換)：站著（對話框的頭像）
##   EulerNpc.draw_boat(ci, 水面上船的位置, 頭的大小, 時間, 表情, 划槳, 畫布變換)：坐在船上（正面：停著、聊天）
##   EulerNpc.draw_boat_side(ci, 水面上船的位置, 頭的大小, 時間, 划槳, 畫布變換)：側面划船（移動中，船頭朝右；往左時整個翻）
##   表情：normal（會眨眼）、happy（眼睛彎彎、張嘴笑）、think（拿羽毛筆點下巴、眼睛往上看）、talk（嘴巴一開一合、揮手）
##   划槳（row）：弧度，一直加上去；< 0 是停著（槳放在船邊）
const UITheme := preload("res://data/ui/game_theme.gd")

const SKIN := Color("f2cdb0")
const SKIN_SH := Color("dca88a")
const SKIN_HI := Color("fbe3cf")
const WRAP := Color("efe4cc")          # 布帽
const WRAP_SH := Color("cdbb98")
const WRAP_LINE := Color(0.62, 0.52, 0.38, 0.75)
const HAIR := Color("6b4a35")
const BROW := Color("7a5640")
const COAT := Color("2f5d62")
const COAT_HI := Color("3f7479")
const COAT_SH := Color("22474b")
const CRAVAT := Color("fbf8f0")
const CRAVAT_SH := Color("dcd5c6")
const EYE := Color("3a2a22")
const LINE := Color(0.45, 0.28, 0.2, 0.5)
const SHOE := Color("2a2226")
const QUILL := Color("fbfaf4")
const QUILL_SH := Color("cfd6e0")
const WOOD := Color("b97c45")
const WOOD_SH := Color("7a4d28")
const WOOD_HI := Color("d9a065")
const FW := 0.86                # 圓臉：半寬 0.86、半高 0.92（乘頭的大小 s）
const FH := 0.92

const NAME := "歐拉"
const TITLE := "海上的計算家 · 划船中"     # 靠近時下方卡片的副標

## ───────────── 對話：六個小故事（2026/11/20 使用者決定；和高斯一樣，聊聊時隨機挑一個） ─────────────
## 每一句：[說話的人, 表情, 句子]；歐拉的表情 normal／happy／think／talk，光靈的 happy／surprised／normal
## 史實（查過資料：MacTutor、孔多塞的悼詞、AMS）：
##   mast    1727 年（19～20 歲）巴黎科學院徵文「船的桅桿怎麼擺最好」，拿到第二名（第一名是布格）；在瑞士山區長大，沒有航海經驗
##   symbols f(x)（1734）、e（1727）、Σ（1755）、i（1777）是他開始用的；π 不是他第一個用，是他用了以後才普及
##   bridges 柯尼斯堡：兩座小島、七座橋（1736 年的論文）；四塊陸地連的橋數都是奇數 → 不可能一次走完；圖論的開始
##   blind   三十出頭右眼就看不見；1766 年（59 歲）回聖彼得堡後幾乎全盲，之後完成一生將近一半的作品（記憶力、兒子和學生幫忙寫）
##   basel   1735 年算出 1 + 1/4 + 1/9 + … = π²/6
##   poly    多面體：頂點 − 邊 + 面 = 2（1750 年寫給哥德巴赫的信）
## 不放：e^{iπ} + 1 = 0（高三才學複數）、他過世那天的事、「少一隻眼睛少一些分心」（出處不可靠）
const TALKS := {
	"mast": [
		["歐拉", "talk", "我十九歲那年，巴黎科學院出了一道徵文題目：船上的桅桿，要怎麼擺才最好？"],
		["歐拉", "happy", "我寫了一篇論文寄過去，拿到了第二名！"],
		["光靈", "surprised", "好厲害！你一定很常坐船吧？"],
		["歐拉", "think", "其實……我在瑞士的山裡長大，那時候幾乎沒出過海。全部都是用算的。"],
		["歐拉", "happy", "所以現在能自己划船出海，我開心得不得了！"],
	],
	"symbols": [
		["歐拉", "talk", "你們課本裡，有好多符號是我開始用的喔。"],
		["歐拉", "happy", "函數寫成 f(x)、加總用的 Σ，還有一個很重要的數，我叫它 e。"],
		["光靈", "surprised", "那 π 也是你發明的嗎？"],
		["歐拉", "think", "π 不是我第一個用的。不過我在書裡一直用它，後來大家就都跟著這樣寫了。"],
		["歐拉", "talk", "把 √{−1} 寫成 i，也是我。這個你們高三才會遇到。"],
		["歐拉", "happy", "好的符號就像好用的工具，用起來順手，大家就會一直用下去。"],
	],
	"bridges": [
		["歐拉", "talk", "有一座叫柯尼斯堡的城市，河上有兩座小島，一共有七座橋。"],
		["歐拉", "think", "那裡的人問：能不能每座橋都只走一次，就把七座橋全部走完？"],
		["光靈", "surprised", "走走看不就知道了？"],
		["歐拉", "happy", "走法太多了，試不完！我換個想法：每塊陸地當一個點，每座橋當一條線。"],
		["歐拉", "talk", "要一筆畫走完，連著奇數條線的點最多只能有兩個。那裡四塊陸地全都是奇數——所以不可能！"],
		["歐拉", "happy", "後來大家說，這是一門新數學的開始。"],
	],
	"blind": [
		["歐拉", "talk", "我三十出頭的時候，右眼就看不見了。"],
		["歐拉", "think", "年紀大了以後，另一隻眼睛也越來越看不清楚，最後幾乎什麼都看不見。"],
		["光靈", "surprised", "那……還能做數學嗎？"],
		["歐拉", "happy", "能！我把算式記在腦子裡算，再說給兒子和學生聽，請他們幫我寫下來。"],
		["歐拉", "talk", "我一輩子的作品，差不多有一半，是在看不見以後完成的。"],
		["歐拉", "happy", "眼睛看不見，數學還是在我的腦子裡，清清楚楚的。"],
	],
	"basel": [
		["歐拉", "talk", "你算算看：1 + 1/4 + 1/9 + 1/16 + ……把每個平方數的倒數一直加下去。"],
		["光靈", "normal", "越加越多……會變成無限大嗎？"],
		["歐拉", "think", "不會，它會越來越靠近某一個數。可是那個數是多少，好多數學家都算不出來。"],
		["歐拉", "happy", "1735 年，我終於算出來了：答案是 π^{2}/6！"],
		["光靈", "surprised", "π？可是這裡又沒有圓！"],
		["歐拉", "happy", "對吧！圓周率跑到這裡來，連我自己都嚇了一跳。"],
	],
	"poly": [
		["歐拉", "talk", "你看過立方浮島上的大方塊嗎？來數數看：一個正方體有幾個頂點？"],
		["光靈", "normal", "8 個！"],
		["歐拉", "happy", "邊有 12 條，面有 6 個。算算看：8 − 12 + 6 = 2。"],
		["歐拉", "think", "換成三角錐呢？4 個頂點、6 條邊、4 個面：4 − 6 + 4，還是 2！"],
		["歐拉", "talk", "只要是沒有洞的多面體，頂點數減邊數再加面數，永遠是 2。"],
		["歐拉", "happy", "1750 年左右，我在寫給朋友的信裡，提到了這件事。"],
	],
}
const HELLO_FIRST := [["歐拉", "happy", "哈囉，小光靈！我是歐拉，從瑞士來的。"], ["歐拉", "talk", "在海上划船真好玩。要不要聽我說個故事？"]]
const HELLO := [
	[["歐拉", "happy", "又見面了！今天的海風真舒服。"]],
	[["歐拉", "think", "我剛剛在船上算了一題……先聽我說個故事吧。"]],
	[["歐拉", "talk", "小光靈！你的船跑得好快呀。來，聽我說。"]],
	[["歐拉", "happy", "這片海上的每一座島，都藏著好多數學呢。"]],
]

static var _base := Transform2D.IDENTITY


## 站著（頭像、或之後要上岸時用）
static func draw(ci: CanvasItem, p: Vector2, s: float, t: float, mood := "normal", walk := -1.0, base := Transform2D.IDENTITY) -> void:
	_base = base
	var bob := sin(t * 2.0) * s * 0.025
	if walk >= 0.0:
		bob = -absf(sin(walk)) * s * 0.07
	_ell(ci, p + Vector2(0, s * 0.04), s * 0.8, s * 0.16, Color(0, 0, 0, 0.28))
	for sx in [-1.0, 1.0]:
		var lift := maxf(0.0, sin(walk) * sx) * s * 0.12 if walk >= 0.0 else 0.0
		_ell(ci, p + Vector2(sx * s * 0.21, -s * 0.04 - lift), s * 0.18, s * 0.1, SHOE)
	_figure(ci, p + Vector2(0, bob * 0.5), s, t, mood, -1.0, bob * 0.5)


## 坐在小划船上：p 是船在水面上的中心（船身擋住腰以下）
static func draw_boat(ci: CanvasItem, p: Vector2, s: float, t: float, mood := "normal", row := -1.0, base := Transform2D.IDENTITY) -> void:
	_base = base
	var bob := sin(t * 2.3) * s * 0.04
	var w := s * 1.9                  # 船身半寬
	var rim := p + Vector2(0, -s * 0.12 + bob)
	# 水面上的影子和波紋
	_ell(ci, p + Vector2(0, s * 0.22), w * 1.25, s * 0.26, Color(0, 0, 0, 0.18))
	# 船邊的小水波：左右各兩條短短的白線，慢慢往外飄
	for sx in [-1.0, 1.0]:
		for k in 2:
			var ph := fposmod(t * 0.5 + k * 0.5, 1.0)
			var wx := p + Vector2(sx * (w * 0.9 + ph * s * 0.9), s * (0.42 + k * 0.1))
			ci.draw_line(wx, wx + Vector2(sx * s * 0.4, 0), Color(1, 1, 1, 0.45 * (1.0 - ph)), maxf(1.0, s * 0.04), true)
	# 船的內側（看得到一點點船底）
	_ell(ci, rim, w * 0.94, s * 0.24, WOOD_SH)
	# 船尾的燈籠桿和寫著 e 的小旗子（在人的後面）
	_lantern(ci, rim + Vector2(-w * 0.8, 0), s, t)
	# 人（坐著：腳底放在船身裡面，腰以下會被船身擋住）
	_figure(ci, rim + Vector2(0, s * 0.42), s, t, mood, row, bob)
	# 船身（正面）：上緣一條亮邊，下面圓圓的
	var hull := PackedVector2Array()
	for k in 13:
		var u := k / 12.0
		hull.append(rim + Vector2(lerpf(w, -w, u), 0))
	for k in 13:
		var a := PI * k / 12.0
		hull.append(rim + Vector2(-cos(a) * w * (0.86 + 0.14 * sin(a)), sin(a) * s * 0.62))
	ci.draw_colored_polygon(hull, WOOD)
	for k in 2:
		var y := s * (0.2 + k * 0.18)
		ci.draw_line(rim + Vector2(-w * (0.95 - k * 0.08), y), rim + Vector2(w * (0.95 - k * 0.08), y), WOOD_SH, maxf(1.0, s * 0.035), true)
	ci.draw_line(rim + Vector2(-w, 0), rim + Vector2(w, 0), WOOD_HI, maxf(2.0, s * 0.08), true)
	# 槳：從兩手斜斜伸到水裡（划的時候前後擺）；停著的時候槳靠在船邊
	for sx in [-1.0, 1.0]:
		var hand := _oar_hand(rim + Vector2(0, s * 0.42), s, row, sx)
		var blade: Vector2
		if row >= 0.0:
			blade = rim + Vector2(sx * w * 1.45 + sin(row) * s * 0.35 * sx, s * 0.62 - cos(row) * s * 0.12)
		else:
			blade = rim + Vector2(sx * w * 1.35, s * 0.55)
		ci.draw_line(hand, blade, WOOD_SH, maxf(1.6, s * 0.06), true)
		_ell(ci, blade, s * 0.13, s * 0.07, WOOD)
		if row >= 0.0 and cos(row) > 0.7:
			UITheme.dot(ci, blade + Vector2(sx * s * 0.12, -s * 0.05), s * 0.05, Color(1, 1, 1, 0.7))      # 水花


## 划槳時手的位置（_figure 和 draw_boat 共用，手和槳才會接在一起）
static func _oar_hand(foot: Vector2, s: float, row: float, sx: float) -> Vector2:
	var top := foot.y - s * 0.95
	var fwd := sin(row) * s * 0.14 if row >= 0.0 else 0.0
	return Vector2(foot.x + sx * (s * 0.62 + fwd), top + s * 0.5)


## 身體＋頭＋前面的手（腳底在 p）
static func _figure(ci: CanvasItem, p: Vector2, s: float, t: float, mood: String, row: float, bob: float) -> void:
	var body_h := s * 0.95
	var head := p + Vector2(0, -body_h - s * 0.82 + bob * 0.5)
	var blink := fposmod(t + 2.1, 3.4) < 0.12 and mood == "normal"
	_body(ci, p, s, body_h, t, mood, row)
	_head(ci, head, s, t, mood, blink)
	match mood:
		"think":
			# 拿羽毛筆點下巴
			var chin := head + Vector2(s * 0.32, s * 0.88)
			var q0 := chin + Vector2(-s * 0.02, s * 0.02)
			var q1 := chin + Vector2(s * 0.34, -s * 0.62)
			var dir := (q1 - q0).normalized()
			var nrm := dir.orthogonal()
			var vane := PackedVector2Array()
			for k in 9:
				var u := k / 8.0
				vane.append(q0.lerp(q1, 0.25 + u * 0.75) + nrm * sin(u * PI) * s * 0.13)
			for k in range(8, -1, -1):
				var u := k / 8.0
				vane.append(q0.lerp(q1, 0.25 + u * 0.75) - nrm * sin(u * PI) * s * 0.07)
			ci.draw_colored_polygon(vane, QUILL)
			ci.draw_line(q0, q1, QUILL_SH, maxf(1.0, s * 0.03), true)
			UITheme.dot(ci, chin, s * 0.1, SKIN)
		"talk":
			if row < 0.0:
				# 張開手掌揮手（和高斯一樣：四根手指張成扇形＋大拇指，不要只伸一根手指）
				var palm := head + Vector2(s * 1.2, s * 0.56)
				var sway := sin(t * 7.0) * 0.3
				for k in 4:
					var a := -PI / 2.0 + sway + (k - 1.5) * 0.36
					var d := Vector2(cos(a), sin(a))
					ci.draw_line(palm + d * s * 0.06, palm + d * s * 0.2, SKIN, maxf(2.0, s * 0.075), true)
					UITheme.dot(ci, palm + d * s * 0.2, maxf(1.0, s * 0.037), SKIN)
				var td := Vector2.from_angle(sway + 0.15)
				ci.draw_line(palm, palm + td * s * 0.16, SKIN, maxf(2.0, s * 0.08), true)
				UITheme.dot(ci, palm, s * 0.12, SKIN)


# ───────────────────────── 身體 ─────────────────────────

static func _body(ci: CanvasItem, p: Vector2, s: float, h: float, t: float, mood: String, row: float) -> void:
	var top := p.y - h
	var coat := PackedVector2Array([
		Vector2(p.x - s * 0.4, top + s * 0.04), Vector2(p.x + s * 0.4, top + s * 0.04),
		Vector2(p.x + s * 0.6, p.y - s * 0.14), Vector2(p.x + s * 0.54, p.y - s * 0.02),
		Vector2(p.x - s * 0.54, p.y - s * 0.02), Vector2(p.x - s * 0.6, p.y - s * 0.14)])
	ci.draw_colored_polygon(coat, COAT)
	ci.draw_colored_polygon(PackedVector2Array([coat[0], coat[1] + Vector2(-s * 0.26, 0), coat[4] + Vector2(s * 0.3, 0), coat[5]]), COAT_HI)
	# 翻領
	for sx in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x + sx * s * 0.16, top + s * 0.06), Vector2(p.x + sx * s * 0.36, top + s * 0.1),
			Vector2(p.x + sx * s * 0.12, top + s * 0.5), Vector2(p.x + sx * s * 0.04, top + s * 0.42)]), COAT_SH)
	# 白領巾：圍一圈、前面打個小結
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - s * 0.2, top), Vector2(p.x + s * 0.2, top),
		Vector2(p.x + s * 0.13, top + s * 0.4), Vector2(p.x - s * 0.13, top + s * 0.4)]), CRAVAT)
	ci.draw_line(Vector2(p.x, top + s * 0.14), Vector2(p.x, top + s * 0.38), CRAVAT_SH, maxf(1.0, s * 0.025), true)
	_ell(ci, Vector2(p.x, top + s * 0.1), s * 0.08, s * 0.06, CRAVAT_SH)
	# 鈕扣
	for k in 3:
		UITheme.dot(ci, Vector2(p.x + s * 0.2, top + s * 0.5 + k * h * 0.14), maxf(1.0, s * 0.035), Color("c9a85a"))
	# 手
	var arm_y := top + s * 0.28
	var rest_l := Vector2(p.x - s * 0.56, p.y - s * 0.34)
	var rest_r := Vector2(p.x + s * 0.56, p.y - s * 0.34)
	if row >= 0.0:
		for sx in [-1.0, 1.0]:
			_arm(ci, Vector2(p.x + sx * s * 0.38, arm_y), _oar_hand(p, s, row, sx), s)
		return
	match mood:
		"think":
			_arm(ci, Vector2(p.x + s * 0.38, arm_y), Vector2(p.x + s * 0.32, top - s * 0.04), s)
			_arm(ci, Vector2(p.x - s * 0.38, arm_y), rest_l, s)
		"talk":
			_arm(ci, Vector2(p.x + s * 0.38, arm_y), Vector2(p.x + s * 1.2, top - s * 0.32), s)
			_arm(ci, Vector2(p.x - s * 0.38, arm_y), rest_l, s)
		"happy":
			# 兩手攤開（很開心地在說話）
			for sx in [-1.0, 1.0]:
				_arm(ci, Vector2(p.x + sx * s * 0.38, arm_y), Vector2(p.x + sx * s * 0.82, top + s * 0.06 + sin(t * 4.0 + sx) * s * 0.03), s)
		_:
			for sx in [-1.0, 1.0]:
				_arm(ci, Vector2(p.x + sx * s * 0.38, arm_y), (rest_r if sx > 0.0 else rest_l) + Vector2(0, sin(t * 2.0 + sx) * s * 0.02), s)


static func _arm(ci: CanvasItem, from: Vector2, hand: Vector2, s: float) -> void:
	ci.draw_line(from, hand, COAT, s * 0.21, true)
	UITheme.dot(ci, from, s * 0.105, COAT)
	_ell(ci, hand + (hand - from).normalized() * s * 0.0, s * 0.11, s * 0.09, CRAVAT)      # 白袖口
	UITheme.dot(ci, hand, s * 0.1, SKIN)


# ───────────────────────── 頭 ─────────────────────────

static func _head(ci: CanvasItem, c: Vector2, s: float, t: float, mood: String, blink: bool) -> void:
	# 耳朵、耳邊一點點棕色頭髮（大部分藏在布帽裡）
	for sx in [-1.0, 1.0]:
		_ell(ci, c + Vector2(sx * s * FW * 0.98, s * 0.1), s * 0.13, s * 0.17, SKIN_SH)
		_ell(ci, c + Vector2(sx * s * FW * 0.97, s * 0.1), s * 0.07, s * 0.1, SKIN)
		_ell(ci, c + Vector2(sx * s * FW * 0.95, -s * 0.12), s * 0.11, s * 0.15, HAIR)
	# 臉：圓圓的，下巴豐滿
	_ell(ci, c, s * FW, s * FH, SKIN)
	_ell(ci, c + Vector2(0, s * 0.62), s * FW * 0.6, s * 0.26, Color(SKIN_SH.r, SKIN_SH.g, SKIN_SH.b, 0.18))
	_cap(ci, c, s, 1.0)
	# 腮紅
	for sx in [-1.0, 1.0]:
		_ell(ci, c + Vector2(sx * s * 0.44, s * 0.34), s * 0.13, s * 0.08, Color(0.95, 0.5, 0.5, 0.3))
	_face(ci, c, s, t, mood, blink)


static func _face(ci: CanvasItem, c: Vector2, s: float, t: float, mood: String, blink: bool) -> void:
	var lw := maxf(1.4, s * 0.06)
	for sx in [-1.0, 1.0]:
		var bc := c + Vector2(sx * s * 0.31, -s * 0.2 - (s * 0.05 if mood == "think" else 0.0))
		ci.draw_arc(bc + Vector2(0, s * 0.1), s * 0.13, PI * 1.25, PI * 1.75, 8, BROW, maxf(2.0, s * 0.07), true)
	for sx in [-1.0, 1.0]:
		var e := c + Vector2(sx * s * 0.31, s * 0.03)
		# 他的右眼（畫面左邊）瞇瞇的：眼皮低一點、眼睛扁一點
		var squint: bool = sx < 0.0
		if mood == "happy":
			ci.draw_arc(e + Vector2(0, s * 0.05), s * 0.1, PI * 1.15, PI * 1.85, 10, EYE, lw, true)
		elif blink:
			ci.draw_line(e + Vector2(-s * 0.08, 0), e + Vector2(s * 0.08, 0), EYE, lw, true)
		else:
			var look := Vector2(s * 0.03, -s * 0.05) if mood == "think" else Vector2.ZERO
			var ry := s * (0.06 if squint else 0.095)
			_ell(ci, e + look + Vector2(0, s * 0.015 if squint else 0.0), s * 0.08, ry, EYE)
			if not squint:
				UITheme.dot(ci, e + look + Vector2(-s * 0.025, -s * 0.03), maxf(1.0, s * 0.025), Color(1, 1, 1, 0.9))
			ci.draw_arc(e + Vector2(0, s * (0.06 if squint else 0.04)), s * 0.11, PI * 1.15, PI * 1.85, 10, EYE, maxf(1.2, s * 0.04), true)
	# 鼻子：圓圓大大的
	ci.draw_line(c + Vector2(s * 0.03, s * 0.04), c + Vector2(s * 0.06, s * 0.2), LINE, maxf(1.0, s * 0.03), true)
	_ell(ci, c + Vector2(s * 0.01, s * 0.27), s * 0.12, s * 0.09, SKIN_SH)
	_ell(ci, c + Vector2(-s * 0.02, s * 0.25), s * 0.07, s * 0.05, SKIN_HI)
	# 嘴巴：溫和的笑
	var m := c + Vector2(0, s * 0.53)
	var lip := Color("a5524a")
	match mood:
		"happy":
			ci.draw_colored_polygon(PackedVector2Array([m + Vector2(-s * 0.16, -s * 0.04), m + Vector2(s * 0.16, -s * 0.04), m + Vector2(s * 0.07, s * 0.1), m + Vector2(-s * 0.07, s * 0.1)]), lip)
		"talk":
			_ell(ci, m + Vector2(0, s * 0.01), s * 0.08, s * (0.03 + 0.045 * absf(sin(t * 9.0))), lip)
		"think":
			_ell(ci, m + Vector2(s * 0.04, 0), s * 0.05, s * 0.03, lip)
		_:
			var pts := PackedVector2Array()
			for k in 9:
				var x := lerpf(-1.0, 1.0, k / 8.0)
				pts.append(m + Vector2(x * s * 0.15, s * 0.05 * (1.0 - x * x)))
			ci.draw_polyline(pts, lip, maxf(1.4, s * 0.05), true)


## 布帽（2026/11/20 改）：只包住頭頂，下緣是一圈捲起來的布邊，停在額頭上面（眉毛、眼睛整個露出來）；
##   上面的布比頭寬一點、一圈一圈斜斜地纏上去，垂一條布尾到耳朵旁（tail：1 右邊、-1 左邊；側面時垂在後腦勺那邊）。
##   不要畫成從臉上蓋下來的大橢圓：眼睛會「被遮住又沒遮住」，整頂看起來像包子
static func _cap(ci: CanvasItem, c: Vector2, s: float, tail: float) -> void:
	var cap := PackedVector2Array()
	for k in 17:                                           # 下緣：額頭中間最高、兩邊往下到太陽穴
		var x := lerpf(-1.0, 1.0, k / 16.0)
		cap.append(c + Vector2(x * s * 0.92, -s * 0.42 + x * x * s * 0.26))
	for k in 21:                                           # 上面：從右邊繞過頭頂到左邊，比頭寬、比頭高
		var a := TAU - PI * k / 20.0
		cap.append(c + Vector2(s * 0.03 + cos(a) * s * 0.98, -s * 0.5 + sin(a) * s * 0.66))
	ci.draw_colored_polygon(GW_shift(cap, Vector2(s * 0.04, s * 0.04)), WRAP_SH)
	ci.draw_colored_polygon(cap, WRAP)
	# 纏上去的布：幾條斜斜的弧線（左下往右上）
	for k in 3:
		var o := c + Vector2(s * (0.5 - k * 0.32), s * (0.2 - k * 0.06))
		ci.draw_arc(o, s, PI * 1.25, PI * 1.45, 12, WRAP_LINE, maxf(1.0, s * 0.032), true)
	# 捲起來的布邊：沿著下緣一條比較深的帶子，上面幾道短短的斜紋
	var band := PackedVector2Array()
	for k in 17:
		var x := lerpf(-1.0, 1.0, k / 16.0)
		band.append(c + Vector2(x * s * 0.92, -s * 0.42 + x * x * s * 0.26))
	for k in range(16, -1, -1):
		var x := lerpf(-1.0, 1.0, k / 16.0)
		band.append(c + Vector2(x * s * 0.94, -s * 0.58 + x * x * s * 0.24))
	ci.draw_colored_polygon(band, WRAP_SH)
	for k in 7:
		var x := lerpf(-0.8, 0.8, k / 6.0)
		var y := -s * 0.5 + x * x * s * 0.25
		ci.draw_line(c + Vector2(x * s * 0.93 - s * 0.04, y + s * 0.07), c + Vector2(x * s * 0.93 + s * 0.05, y - s * 0.07), WRAP_LINE, maxf(1.0, s * 0.03), true)
	# 布尾
	var tl := PackedVector2Array([c + Vector2(tail * s * 0.8, -s * 0.36), c + Vector2(tail * s * 1.02, -s * 0.42),
		c + Vector2(tail * s * 1.12, s * 0.12), c + Vector2(tail * s * 0.96, s * 0.2)])
	ci.draw_colored_polygon(tl, WRAP_SH)
	ci.draw_polyline(PackedVector2Array([tl[1], tl[2]]), WRAP_LINE, maxf(1.0, s * 0.03), true)

# ───────────────────────── 側面划船（移動中） ─────────────────────────
## 移動中用側面：船頭朝右（往左划時呼叫的人把整個左右翻），他側身朝前划；停下來、光靈靠近時用正面的 draw_boat
## （真的划船是背對前進方向坐的；這裡讓他面向前方，玩家比較看得懂他要去哪裡）
static func draw_boat_side(ci: CanvasItem, p: Vector2, s: float, t: float, row: float, base := Transform2D.IDENTITY) -> void:
	_base = base
	var bob := sin(t * 2.3) * s * 0.04
	var L := s * 2.1                  # 船身半長
	var rim := p + Vector2(0, -s * 0.12 + bob)
	var r := maxf(row, 0.0)
	_ell(ci, p + Vector2(0, s * 0.3), L * 1.1, s * 0.24, Color(0, 0, 0, 0.18))
	# 船尾拖出去的水紋（往後飄）
	for k in 3:
		var ph := fposmod(t * 0.7 + k / 3.0, 1.0)
		var wx := p + Vector2(-L * (0.95 + ph * 0.8), s * (0.36 + 0.06 * sin(k * 2.0)))
		ci.draw_line(wx, wx + Vector2(-s * 0.5, 0), Color(1, 1, 1, 0.45 * (1.0 - ph)), maxf(1.0, s * 0.04), true)
	# 船的內側
	_ell(ci, rim + Vector2(0, -s * 0.02), L * 0.9, s * 0.16, WOOD_SH)
	# 船尾的燈籠桿（在人的後面）
	_lantern(ci, rim + Vector2(-L * 0.8, 0), s, t)
	# 人：遠的那隻手和槳、身體、頭、近的那隻手
	var foot := rim + Vector2(s * 0.05, s * 0.5)
	var top := foot.y - s * 0.95
	var pull := sin(r) * s * 0.3                         # 手前後拉
	var hand_far := Vector2(foot.x + s * 0.42 + pull, top + s * 0.5)
	var hand_near := Vector2(foot.x + s * 0.48 + pull, top + s * 0.56)
	var blade_far := rim + Vector2(-s * 0.4 - pull * 2.2, s * 0.46 - cos(r) * s * 0.1)
	ci.draw_line(hand_far, blade_far, WOOD_SH.darkened(0.2), maxf(1.4, s * 0.05), true)
	_arm(ci, Vector2(foot.x + s * 0.06, top + s * 0.26), hand_far, s)
	_body_side(ci, foot, s)
	_head_side(ci, foot + Vector2(0, -s * 0.95 - s * 0.82 + bob * 0.5), s, t)
	# 船身（側面）：船頭翹起來
	var hull := PackedVector2Array([rim + Vector2(-L, -s * 0.04), rim + Vector2(-L * 0.5, s * 0.02), rim + Vector2(0, s * 0.03),
		rim + Vector2(L * 0.55, 0), rim + Vector2(L * 0.88, -s * 0.12), rim + Vector2(L * 1.08, -s * 0.34),
		rim + Vector2(L * 0.88, s * 0.18), rim + Vector2(L * 0.45, s * 0.46), rim + Vector2(0, s * 0.54),
		rim + Vector2(-L * 0.5, s * 0.48), rim + Vector2(-L * 0.94, s * 0.28)])
	ci.draw_colored_polygon(hull, WOOD)
	for k in 2:
		var y := s * (0.2 + k * 0.16)
		ci.draw_line(rim + Vector2(-L * (0.92 - k * 0.06), y), rim + Vector2(L * (0.84 - k * 0.12), y - s * 0.02), WOOD_SH, maxf(1.0, s * 0.035), true)
	ci.draw_polyline(hull.slice(0, 6), WOOD_HI, maxf(2.0, s * 0.08), true)
	# 近的那支槳和那隻手（蓋在船身前面）
	var blade := rim + Vector2(-s * 0.2 - pull * 2.4, s * 0.62 - cos(r) * s * 0.12)
	ci.draw_line(hand_near, blade, WOOD_SH, maxf(1.6, s * 0.06), true)
	_ell(ci, blade, s * 0.2, s * 0.07, WOOD)
	if cos(r) > 0.7:
		UITheme.dot(ci, blade + Vector2(-s * 0.2, -s * 0.06), s * 0.06, Color(1, 1, 1, 0.7))     # 水花
	_arm(ci, Vector2(foot.x + s * 0.02, top + s * 0.3), hand_near, s)


## 船尾的燈籠桿、寫著 e 的小旗子、燈籠（正面和側面共用）
static func _lantern(ci: CanvasItem, pole: Vector2, s: float, t: float) -> void:
	var ptop := pole + Vector2(-s * 0.15, -s * 2.6)
	ci.draw_line(pole, ptop, WOOD_SH, maxf(2.0, s * 0.07), true)
	var flag := PackedVector2Array([ptop + Vector2(0, s * 0.05), ptop + Vector2(s * 0.62, s * 0.18 + sin(t * 5.0) * s * 0.05), ptop + Vector2(0, s * 0.42)])
	ci.draw_colored_polygon(flag, Color("f5c84c"))
	if s >= 22.0:
		# 小旗子上的 e：船整個左右翻（往左划）時，字不要變成鏡像
		var xf := _base * Transform2D(0.0, ptop + Vector2(s * 0.24, s * 0.22))
		if _base.determinant() < 0.0:
			xf = xf * Transform2D.FLIP_X
		ci.draw_set_transform_matrix(xf)
		var fs := int(s * 0.32)
		ci.draw_string(UITheme.bold_font(), Vector2(-s * 0.3, fs * 0.36), "e", HORIZONTAL_ALIGNMENT_CENTER, s * 0.6, fs, Color("7a4d28"))
		ci.draw_set_transform_matrix(_base)
	var lamp := ptop + Vector2(s * 0.05, s * 0.62)
	ci.draw_line(ptop + Vector2(0, s * 0.42), lamp + Vector2(0, -s * 0.12), Color("5a3a22"), maxf(1.0, s * 0.03), true)
	var glow := 0.75 + 0.25 * sin(t * 3.0)
	UITheme.dot(ci, lamp, s * 0.55, Color(1.0, 0.85, 0.5, 0.18 * glow))
	UITheme.dot(ci, lamp, s * 0.3, Color(1.0, 0.85, 0.5, 0.3 * glow))
	ci.draw_rect(Rect2(lamp + Vector2(-s * 0.11, -s * 0.14), Vector2(s * 0.22, s * 0.28)), Color("ffe7a3"))
	ci.draw_rect(Rect2(lamp + Vector2(-s * 0.13, -s * 0.18), Vector2(s * 0.26, s * 0.06)), Color("5a3a22"))
	ci.draw_rect(Rect2(lamp + Vector2(-s * 0.13, s * 0.13), Vector2(s * 0.26, s * 0.05)), Color("5a3a22"))


## 側面的身體（面向右）：外套、前面的白領巾和鈕扣在右邊
static func _body_side(ci: CanvasItem, p: Vector2, s: float) -> void:
	var top := p.y - s * 0.95
	var coat := PackedVector2Array([Vector2(p.x - s * 0.34, top + s * 0.06), Vector2(p.x + s * 0.3, top + s * 0.04),
		Vector2(p.x + s * 0.46, p.y - s * 0.1), Vector2(p.x - s * 0.48, p.y - s * 0.1)])
	ci.draw_colored_polygon(coat, COAT)
	ci.draw_colored_polygon(PackedVector2Array([coat[0], coat[0] + Vector2(s * 0.3, -s * 0.02), coat[3] + Vector2(s * 0.34, 0), coat[3]]), COAT_SH)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x + s * 0.08, top), Vector2(p.x + s * 0.3, top + s * 0.02),
		Vector2(p.x + s * 0.3, top + s * 0.36), Vector2(p.x + s * 0.14, top + s * 0.36)]), CRAVAT)
	for k in 3:
		UITheme.dot(ci, Vector2(p.x + s * 0.32 + k * s * 0.03, top + s * 0.46 + k * s * 0.13), maxf(1.0, s * 0.035), Color("c9a85a"))


## 側面的頭（面向右）：Q 版的轉頭只要把五官整組往右挪一點、遠的那隻眼睛小一點就好，臉還是圓的
##   （2026/11/20 使用者：之前的版本畫了大耳朵、鼻子凸出臉的輪廓，「超醜」→ 不要寫實的側臉）
static func _head_side(ci: CanvasItem, c: Vector2, s: float, t: float) -> void:
	_ell(ci, c + Vector2(-s * 0.74, -s * 0.06), s * 0.13, s * 0.17, HAIR)               # 後腦勺露出一點頭髮
	_ell(ci, c, s * FW, s * FH, SKIN)
	_ell(ci, c + Vector2(s * 0.08, s * 0.62), s * FW * 0.58, s * 0.25, Color(SKIN_SH.r, SKIN_SH.g, SKIN_SH.b, 0.18))
	_cap(ci, c + Vector2(-s * 0.04, 0), s, -1.0)
	var sh := s * 0.17                                                                     # 五官往右挪多少
	for x in [-0.44, 0.44]:
		_ell(ci, c + Vector2(x * s + sh * (1.3 if x > 0.0 else 0.6), s * 0.34), s * (0.11 if x > 0.0 else 0.13), s * 0.08, Color(0.95, 0.5, 0.5, 0.3))
	var blink := fposmod(t + 2.1, 3.4) < 0.12
	var lw := maxf(1.4, s * 0.06)
	for k in 2:
		var far := k == 1
		var e := c + Vector2((s * 0.29 if far else -s * 0.31) + sh, s * 0.03)
		var k_sz := 0.85 if far else 1.0                                                  # 遠的那隻小一點
		ci.draw_arc(e + Vector2(0, -s * 0.1), s * 0.13 * k_sz, PI * 1.25, PI * 1.75, 8, BROW, maxf(2.0, s * 0.07), true)
		if blink:
			ci.draw_line(e + Vector2(-s * 0.08, 0), e + Vector2(s * 0.08, 0), EYE, lw, true)
		else:
			_ell(ci, e, s * 0.08 * k_sz, s * 0.095 * k_sz, EYE)
			UITheme.dot(ci, e + Vector2(-s * 0.025, -s * 0.03), maxf(1.0, s * 0.025), Color(1, 1, 1, 0.9))
			ci.draw_arc(e + Vector2(0, s * 0.04), s * 0.11 * k_sz, PI * 1.15, PI * 1.85, 10, EYE, maxf(1.2, s * 0.04), true)
	# 鼻子、嘴巴：和正面一樣的畫法，跟著往右挪
	ci.draw_line(c + Vector2(s * 0.03 + sh * 1.2, s * 0.04), c + Vector2(s * 0.06 + sh * 1.2, s * 0.2), LINE, maxf(1.0, s * 0.03), true)
	_ell(ci, c + Vector2(s * 0.01 + sh * 1.3, s * 0.27), s * 0.12, s * 0.09, SKIN_SH)
	_ell(ci, c + Vector2(-s * 0.02 + sh * 1.3, s * 0.25), s * 0.07, s * 0.05, SKIN_HI)
	var pts := PackedVector2Array()
	for k in 9:
		var x := lerpf(-1.0, 1.0, k / 8.0)
		pts.append(c + Vector2(sh * 1.1 + x * s * 0.14, s * 0.53 + s * 0.05 * (1.0 - x * x)))
	ci.draw_polyline(pts, Color("a5524a"), maxf(1.4, s * 0.05), true)


static func GW_shift(pts: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pts:
		out.append(q + d)
	return out


static func _ell(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)
