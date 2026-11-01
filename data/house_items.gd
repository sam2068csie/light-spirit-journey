extends RefCounted
## 光靈小屋的家具清單
##   slots：可以放在哪一種格位（wall 牆面、big 大型家具（高窄）、wide 窗下大型（寬）、sill 窗台、top 桌上、floor 地板、rug 地毯）
##   price：商店價格（星塵）；src：不在商店賣、要達成條件才拿得到（"egg:彩蛋 id"）
##   draw：畫法（house.gd 的 _draw_item）
## 紀念品（每個單元一件）不在這裡：放在紀念品櫃，見 souvenir()

const ITEMS := [
	# ---- 商店：小家具（每天都買得起一件）----
	{"id": "lamp_moon", "name": "月亮夜燈", "slots": ["sill", "top"], "price": 200, "draw": "moonlamp", "col": Color("fff3d6")},
	{"id": "cactus", "name": "仙人掌", "slots": ["sill", "top", "floor"], "price": 150, "draw": "cactus", "col": Color("6ee7a0")},
	{"id": "frame", "name": "星空小畫", "slots": ["wall"], "price": 120, "draw": "frame", "col": Color("5fd4ff")},
	{"id": "clock", "name": "掛鐘", "slots": ["wall"], "price": 180, "draw": "clock", "col": Color("f0d29a")},
	{"id": "books", "name": "一疊書", "slots": ["top", "floor"], "price": 100, "draw": "books", "col": Color("ff9a5a")},
	{"id": "candle", "name": "香氛蠟燭", "slots": ["sill", "top"], "price": 80, "draw": "candle", "col": Color("ffd6ec")},
	{"id": "stars", "name": "星星吊飾", "slots": ["wall"], "price": 160, "draw": "starstring", "col": Color("f5c84c")},
	{"id": "rug_blue", "name": "藍色圓地毯", "slots": ["rug"], "price": 250, "draw": "rug", "col": Color("3f6fb0")},
	{"id": "rug_pink", "name": "粉紅圓地毯", "slots": ["rug"], "price": 250, "draw": "rug", "col": Color("b0507a")},
	{"id": "stool", "name": "小板凳", "slots": ["floor"], "price": 220, "draw": "stool", "col": Color("c98a5a")},
	{"id": "tree", "name": "盆栽小樹", "slots": ["floor", "big", "wide"], "price": 300, "draw": "pottree", "col": Color("4d9a6a")},
	{"id": "cushion", "name": "懶骨頭", "slots": ["floor"], "price": 280, "draw": "cushion", "col": Color("c59bff")},
	# ---- 商店：昂貴的大家具 ----
	{"id": "bookcase", "name": "大書櫃", "slots": ["big", "wide"], "price": 1500, "draw": "bookcase", "col": Color("8a5a3a")},
	{"id": "globe", "name": "地球儀", "slots": ["floor", "big", "wide"], "price": 1800, "draw": "globe", "col": Color("5fd4ff")},
	{"id": "sofa", "name": "雙人沙發", "slots": ["wide"], "price": 2200, "draw": "sofa", "col": Color("b0507a")},
	{"id": "scope", "name": "天文望遠鏡", "slots": ["big", "wide", "floor"], "price": 2500, "draw": "telescope", "col": Color("c8d0f0")},
	{"id": "piano", "name": "直立鋼琴", "slots": ["wide"], "price": 3000, "draw": "piano", "col": Color("2a2440")},
	# ---- 彩蛋獎勵（地圖上解開才拿得到）----
	{"id": "stonepot", "name": "數字石盆栽", "slots": ["sill", "floor", "top"], "src": "egg10:stones", "how": "曦光大陸 · 數之原野的數字石", "draw": "stonepot", "col": Color("f5c84c")},
	{"id": "shell", "name": "螺旋貝殼", "slots": ["sill", "top"], "src": "egg10:fib", "how": "曦光大陸 · 古老的石碑", "draw": "shell", "col": Color("ffd6ec")},
	{"id": "dice", "name": "大骰子", "slots": ["top", "floor"], "src": "egg10:dice", "how": "曦光大陸 · 骰子市集的攤販", "draw": "dice", "col": Color("fffaf0")},
	{"id": "shipbottle", "name": "瓶中船", "slots": ["sill", "top"], "src": "egg11:wreck", "how": "光潮群島 · 沉船殘骸", "draw": "shipbottle", "col": Color("9fd8ff")},
	{"id": "orb", "name": "漩渦水晶球", "slots": ["top", "sill"], "src": "egg11:whirl", "how": "光潮群島 · 海上的漩渦", "draw": "orb", "col": Color("6ee7c0")},
]

## 每個單元的紀念品（點亮整個單元的所有聖地才拿得到）
const SOUVENIRS := {
	"exp": {"name": "雙島模型", "story": "指數島和對數島，中間連著光之橋。點亮八座聖地時，島上的光靈們送你的模型。", "col": Color("f5c84c")},
	"trig": {"name": "月輪島模型", "story": "圓環島、正弦海岸和羅盤礁，晚上潟湖會倒映月光。", "col": Color("ff9ad5")},
}

## 小屋等級：點亮幾座聖地升級（高一、高二、高三都算）
const LEVELS := [
	{"lv": 1, "name": "小木屋", "need": 0, "desc": "一個房間：紀念品櫃、書桌、布告欄，10 個格位。"},
	{"lv": 2, "name": "加蓋閣樓", "need": 10, "desc": "多一層閣樓：床、天窗，8 個新格位。"},
	{"lv": 3, "name": "前院陽台", "need": 25, "desc": "門口多一個陽台：盆栽、鞦韆，季節會換景色。"},
	{"lv": 4, "name": "觀星塔", "need": 50, "desc": "小屋旁邊的觀星塔：看各單元熟練度的星盤。"},
]


static func item(id: String) -> Dictionary:
	for it in ITEMS:
		if it.id == id:
			return it
	return {}


static func souvenir(uid: String) -> Dictionary:
	return SOUVENIRS.get(uid, {"name": "紀念品", "story": "點亮這個單元的所有聖地就會出現。", "col": Color("c8d0f0")})
