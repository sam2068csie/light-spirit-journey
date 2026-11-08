extends RefCounted
## 三角函數（高二上）的終焉之塔題庫：題目 69 題（試煉大題 12 題），每題 3 組數字
##   考法參考各校 113、114 學年度高二第一次段考（建中、北一女、師大附中、成功、中山女中、松山、大同、板橋）；
##   數字、情境全部換過。用到高一教過的正弦定理、餘弦定理、極坐標也照收。
##   題目本身由 tools/trig_tower/gen.py 產生到 trig_tower_data.gd：每一題是一個模板 + 幾組手挑的數字，
##   答案、提示、錯誤選項都由程式算，每一組都用 assert 驗算（改題目請改 tools/trig_tower/t_*.py 再跑 gen.py）。
##
## 題目的格式和 poly_tower_bank.gd 一樣（id、kind、tier、title、stem、tmul、plot、steps）。
##   座標圖的 "pi"：橫軸用 π 當刻度；"geo"：幾何圖（等比例、可以有 shapes、會動的 groups），見 boss_tower.gd 的 Plot。
##   填空的鍵盤和三角函數八大關一樣有「√」鍵；π 寫在格子外面，格子只填係數（[0]π）。
const UITheme := preload("res://data/ui/game_theme.gd")
const Data := preload("res://data/levels/tower/trig_tower_data.gd")

const RADICALS := true

const KIND_NAME := {"judge": "判讀羅盤", "graph": "波形辨識", "cross": "交點潮汐", "angle": "角的鍛造",
	"extreme": "疊合極值", "quest": "海岸委託", "boss": "試煉大題"}
const KIND_COLOR := {"judge": UITheme.CYAN, "graph": UITheme.VIOLET, "cross": UITheme.LIME, "angle": UITheme.PINK,
	"extreme": UITheme.ORANGE, "quest": UITheme.GOLD, "boss": UITheme.ROSE}


static var _items: Array = []


static func items() -> Array:
	if _items.is_empty():
		_items = Data.data().duplicate(true)
	return _items


static func by_id(id: String) -> Dictionary:
	for it in items():
		if it.id == id:
			return it
	return {}
