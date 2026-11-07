extends RefCounted
## 多項式（高一）的終焉之塔題庫：題目 60 題（試煉大題 12 題），每題 3 組數字
##   考法參考各校 113 學年度高一第三次段考（建中、北一女、師大附中、成功、中山女中、松山）
##   和輔導班講義裡八大關沒有收的難題；數字、情境全部換過。
##   題目本身由 tools/poly_tower/gen.py 產生到 poly_tower_data.gd：每一題是一個模板 + 幾組手挑的數字，
##   答案、提示、錯誤選項都由程式算，每一組都用 assert 驗算（改題目請改 tools/poly_tower/t_*.py 再跑 gen.py）。
##
## 題目的格式和 tower_bank.gd 一樣（id、kind、tier、title、stem、tmul、plot、steps），另外：
##   {t: "pick", q, graphs: [正確的圖, 錯誤的圖…], whys: [每張圖錯在哪（第 0 張留空）], hint, write}
##       選圖題：每張圖是一份小座標圖資料，curves 可以加 "dash": true（虛線）
##   {t: "sign", q, row, marks, signs: [每一段的正負號 1／−1], write}
##       數線標正負號（穿根），和後面的 line 步驟共用同一條數線
##   {t: "fill", q, template: "f(4) = [0]", ans: ["22"], hint, write}
##       數字鍵盤填答案（分數寫 a/b，看數值比較）
##   分類討論：題目加 "routes": {"A": "a > 0", "B": "a < 0"}，步驟加 "col": "A"／"B"，推導板分成兩欄
const UITheme := preload("res://data/ui/game_theme.gd")
const Data := preload("res://data/levels/tower/poly_tower_data.gd")

const KIND_NAME := {"judge": "真假審判", "graph": "圖形辨識", "remain": "餘式迴響", "line": "數線封印",
	"param": "參數討論", "boss": "試煉大題"}
const KIND_COLOR := {"judge": UITheme.CYAN, "graph": UITheme.VIOLET, "remain": UITheme.PINK, "line": UITheme.LIME,
	"param": UITheme.ORANGE, "boss": UITheme.ROSE}


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
