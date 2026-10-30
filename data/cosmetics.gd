extends RefCounted
## 光靈裝扮的資料（共 60 件：扭蛋池 59 件＋簽到限定 1 件），和扭蛋機的機率、保底規則。
## 樣子畫在 spirit_look.gd（全部用程式畫），持有與穿戴狀態存在 game.gd（owned / equipped / gacha）。

## 類別（衣櫃頁籤的順序）
const CATS := [
	{"id": "hat", "name": "頭飾"},
	{"id": "face", "name": "臉部"},
	{"id": "aura", "name": "光芒"},
	{"id": "trail", "name": "拖尾"},
	{"id": "pet", "name": "小夥伴"},
]

## 稀有度：0 普通、1 稀有、2 史詩、3 傳說
const RARITY := [
	{"name": "普通", "rate": 0.60, "color": Color("e8ecff"), "shards": 5},
	{"name": "稀有", "rate": 0.30, "color": Color("5ad8ff"), "shards": 15},
	{"name": "史詩", "rate": 0.085, "color": Color("c792ff"), "shards": 50},
	{"name": "傳說", "rate": 0.015, "color": Color("ffcf5a"), "shards": 150},
]

const COST_ONE := 120          # 單抽（每天第一抽半價）
const COST_TEN := 1080         # 十連（九折，保證至少一個稀有）
const COST_SHINE := 3          # 閃光抽：光之結晶 ×3，保證史詩以上
const PITY_SR := 10            # 連續 10 抽沒出史詩以上，第 10 抽保證史詩
const PITY_SSR := 60           # 連續 60 抽沒出傳說，第 60 抽保證傳說

const EXCHANGE := [30, 80, 250, 600]   # 碎片兌換所：各稀有度要幾個光之碎片

## 共 60 件，每一類 12 件。扭蛋池：普通 23、稀有 18、史詩 12、傳說 6（另有簽到限定的史詩「簽到圍巾」）
const ITEMS := [
	# 頭飾
	{"id": "sprout", "cat": "hat", "r": 0, "name": "小草芽", "desc": "頭上冒出兩片小葉子，每天長一點點。"},
	{"id": "bow", "cat": "hat", "r": 0, "name": "蝴蝶結", "desc": "粉紅色的蝴蝶結，出門前要綁好。"},
	{"id": "grad_cap", "cat": "hat", "r": 1, "name": "畢業帽", "desc": "學會指數與對數，就可以戴上它！"},
	{"id": "root_crown", "cat": "hat", "r": 2, "name": "根號皇冠", "desc": "√ 形狀的皇冠。√ 這個符號是從拉丁文 radix（根）的 r 變來的。"},
	{"id": "inf_halo", "cat": "hat", "r": 3, "name": "無限光環", "desc": "∞ 形的光環。指數函數 2^{x} 往右走，會一直長到無限大。"},
	{"id": "daisy", "cat": "hat", "r": 0, "name": "小雛菊", "desc": "別在頭上的小白花。"},
	{"id": "cat_ears", "cat": "hat", "r": 0, "name": "貓耳", "desc": "喵～聽題目聽得更清楚了。"},
	{"id": "wizard_hat", "cat": "hat", "r": 1, "name": "魔法師帽", "desc": "念一句「令 t = 2^{x}」，方程式就變簡單了。"},
	{"id": "star_tiara", "cat": "hat", "r": 2, "name": "星光頭冠", "desc": "鑲著三顆星星的頭冠，在暗處也會發亮。"},
	{"id": "spiral_crown", "cat": "hat", "r": 3, "name": "對數螺旋冠", "desc": "對數螺旋 r = e^{bθ}：每轉一圈放大固定倍數，鸚鵡螺殼就是這個形狀。"},
	{"id": "headphones", "cat": "hat", "r": 1, "name": "耳機", "desc": "戴上耳機專心算題，旁邊還會冒出小音符。"},
	{"id": "laurel", "cat": "hat", "r": 2, "name": "月桂冠", "desc": "古希臘送給勝利者的葉子頭冠。解出難題的你也值得一頂！"},
	# 臉部
	{"id": "blush", "cat": "face", "r": 0, "name": "腮紅", "desc": "害羞的時候臉頰會紅紅的。"},
	{"id": "round_glasses", "cat": "face", "r": 0, "name": "圓框眼鏡", "desc": "戴上之後，看題目好像更清楚了。"},
	{"id": "pi_glasses", "cat": "face", "r": 1, "name": "π 墨鏡", "desc": "π ≈ 3.14159…，小數點後永遠寫不完。"},
	{"id": "star_eyes", "cat": "face", "r": 2, "name": "星星眼", "desc": "看到漂亮的解法時，眼睛會變成星星。"},
	{"id": "mustache", "cat": "face", "r": 0, "name": "小鬍子", "desc": "看起來很有學問的捲捲鬍子。"},
	{"id": "monocle", "cat": "face", "r": 1, "name": "單片眼鏡", "desc": "紳士偵探的必備品，專門找出不合的根。"},
	{"id": "heart_eyes", "cat": "face", "r": 2, "name": "愛心眼", "desc": "愛上數學的時候，眼睛就會變成這樣。"},
	{"id": "star_sticker", "cat": "face", "r": 0, "name": "星星貼紙", "desc": "臉頰上的小星星，答對一題就貼一顆。"},
	{"id": "freckles", "cat": "face", "r": 0, "name": "小雀斑", "desc": "曬太陽留下的可愛小點點。"},
	{"id": "bandaid", "cat": "face", "r": 0, "name": "OK 繃", "desc": "算錯了沒關係，貼一下就好，再試一次！"},
	{"id": "hero_mask", "cat": "face", "r": 1, "name": "英雄眼罩", "desc": "函數俠參上！專門打倒不合的根。"},
	{"id": "streak_scarf", "cat": "face", "r": 2, "name": "簽到圍巾", "pool": false, "how": "連續簽到 14 天獲得",
		"desc": "連續簽到 14 天才拿得到的紅圍巾。每天一點點，累積起來就很可觀，就像 1.01^{365} ≈ 37.8。"},
	# 光芒
	{"id": "mint", "cat": "aura", "r": 0, "name": "薄荷綠", "col": Color("7ef0c0"), "desc": "清清涼涼的綠色光芒。"},
	{"id": "sakura", "cat": "aura", "r": 0, "name": "櫻花粉", "col": Color("ff9ccf"), "desc": "像春天花瓣一樣的粉紅光芒。"},
	{"id": "sky", "cat": "aura", "r": 1, "name": "天空藍", "col": Color("7cc8ff"), "desc": "晴天的顏色。"},
	{"id": "aurora", "cat": "aura", "r": 2, "name": "極光漸層", "desc": "綠、青、紫慢慢變換，像北極的極光。"},
	{"id": "rainbow", "cat": "aura", "r": 3, "name": "彩虹流光", "desc": "七種顏色輪流流動的傳說光芒。"},
	{"id": "lemon", "cat": "aura", "r": 0, "name": "檸檬黃", "col": Color("fff07a"), "desc": "酸酸甜甜的黃色光芒。"},
	{"id": "lavender", "cat": "aura", "r": 0, "name": "薰衣草紫", "col": Color("c3a6ff"), "desc": "淡淡的紫色光芒，讓人靜下心來算題目。"},
	{"id": "sunset", "cat": "aura", "r": 1, "name": "夕陽橘", "col": Color("ffa36b"), "desc": "放學時天空的顏色。"},
	{"id": "ocean", "cat": "aura", "r": 0, "name": "海洋藍綠", "col": Color("5fe0d6"), "desc": "像淺海一樣透亮的藍綠色光芒。"},
	{"id": "ruby", "cat": "aura", "r": 1, "name": "紅寶石", "col": Color("ff6b8a"), "desc": "閃著紅寶石光澤的光芒。"},
	{"id": "gold_aura", "cat": "aura", "r": 2, "name": "黃金光輝", "desc": "金色光芒一明一暗，身邊飄著金色的光點。"},
	{"id": "galaxy", "cat": "aura", "r": 3, "name": "銀河星光", "desc": "身邊繞著小星星的深紫光芒。銀河裡大約有 10^{11} 顆星星。"},
	# 拖尾
	{"id": "star_trail", "cat": "trail", "r": 0, "name": "小星星", "desc": "飛過的地方會留下閃亮的小星星。"},
	{"id": "bubbles", "cat": "trail", "r": 1, "name": "泡泡", "desc": "啵、啵、啵～一路冒泡泡。"},
	{"id": "expo_spark", "cat": "trail", "r": 2, "name": "指數火花", "desc": "火花沿著 y = 2^{x} 的形狀往上竄，越來越快！"},
	{"id": "hearts", "cat": "trail", "r": 0, "name": "愛心", "desc": "飛過的地方會冒出小愛心。"},
	{"id": "notes", "cat": "trail", "r": 0, "name": "音符", "desc": "一邊飛一邊哼歌。"},
	{"id": "petals", "cat": "trail", "r": 1, "name": "櫻花瓣", "desc": "粉紅色的花瓣輕輕飄落。"},
	{"id": "digits", "cat": "trail", "r": 1, "name": "數字雨", "desc": "0～9 的數字一路灑下來。"},
	{"id": "sine_wave", "cat": "trail", "r": 2, "name": "波浪軌跡", "desc": "身後拖著一條會動的波浪，一高一低、規律重複。"},
	{"id": "snow", "cat": "trail", "r": 0, "name": "雪花", "desc": "飛過的地方會飄下小雪花。"},
	{"id": "comet", "cat": "trail", "r": 1, "name": "彗星尾", "desc": "像彗星一樣拖著一條藍白色的光尾巴。"},
	{"id": "fireworks", "cat": "trail", "r": 2, "name": "小煙火", "desc": "身後一朵一朵綻開的彩色煙火。"},
	{"id": "fib_spiral", "cat": "trail", "r": 3, "name": "費氏螺旋", "desc": "四分之一圓的半徑照 1、1、2、3、5、8 長大，相鄰兩項的比會越來越接近黃金比例 1.618…。"},
	# 小夥伴
	{"id": "firefly", "cat": "pet", "r": 0, "name": "螢火蟲", "desc": "一閃一閃，陪光靈一起發光。"},
	{"id": "paper_plane", "cat": "pet", "r": 1, "name": "紙飛機", "desc": "用寫滿算式的草稿紙摺的。"},
	{"id": "e_sprite", "cat": "pet", "r": 1, "name": "迷你 e 精靈", "desc": "e ≈ 2.71828，是自然對數 ln 的底數。"},
	{"id": "chick", "cat": "pet", "r": 0, "name": "小雞", "desc": "嗶嗶～跟在光靈後面跑。"},
	{"id": "pencil", "cat": "pet", "r": 1, "name": "飛天鉛筆", "desc": "會自己飛的鉛筆，隨時準備寫算式。"},
	{"id": "moon", "cat": "pet", "r": 2, "name": "迷你月亮", "desc": "繞著光靈轉的小月亮，就像月球繞著地球。"},
	{"id": "kitten", "cat": "pet", "r": 0, "name": "小橘貓", "desc": "喜歡在草稿紙上睡覺的小貓。"},
	{"id": "goldfish", "cat": "pet", "r": 0, "name": "小金魚", "desc": "在空中游來游去，偶爾吐一顆泡泡。"},
	{"id": "calculator", "cat": "pet", "r": 1, "name": "計算機", "desc": "會飛的計算機。不過考試的時候要收起來喔！"},
	{"id": "owl", "cat": "pet", "r": 1, "name": "貓頭鷹", "desc": "熬夜讀書的好夥伴，會一直眨眼睛。"},
	{"id": "robot", "cat": "pet", "r": 2, "name": "小機器人", "desc": "頭上的燈一閃一閃，正在幫你檢查計算。"},
	{"id": "dragon", "cat": "pet", "r": 3, "name": "小飛龍", "desc": "傳說中的小飛龍，拍著翅膀偶爾噴出一小口火。"},
]


static func item(id: String) -> Dictionary:
	for it in ITEMS:
		if it.id == id:
			return it
	return {}


## 依稀有度排序（普通 → 傳說）；同稀有度保持原本順序
static func by_rarity(list: Array) -> Array:
	var idx := {}
	for i in ITEMS.size():
		idx[ITEMS[i].id] = i
	var out := list.duplicate()
	out.sort_custom(func(a, b):
		if int(a.r) != int(b.r):
			return int(a.r) < int(b.r)
		return int(idx.get(a.id, 0)) < int(idx.get(b.id, 0)))
	return out


static func items_of(cat: String) -> Array:
	return ITEMS.filter(func(it): return it.cat == cat)


## 扭蛋池裡的（簽到限定之類的不在裡面）
static func items_of_rarity(r: int) -> Array:
	return ITEMS.filter(func(it): return int(it.r) == r and it.get("pool", true))


## 抽一次稀有度。min_r：至少多少（保底用）
static func roll_rarity(min_r: int = 0) -> int:
	if min_r >= 3:
		return 3
	var total := 0.0
	for k in range(min_r, 4):
		total += float(RARITY[k].rate)
	var x := randf() * total
	for k in range(min_r, 4):
		x -= float(RARITY[k].rate)
		if x <= 0.0:
			return k
	return 3


static func pick_of_rarity(r: int) -> Dictionary:
	var pool := items_of_rarity(r)
	return pool.pick_random() if not pool.is_empty() else ITEMS.pick_random()
