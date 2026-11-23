extends RefCounted
## 指數與常用對數（高一上）的終焉之塔題庫：塔頂 30 層，題目 41 題（試煉大題 12 題），每題 3 組數字
##   考法參考六校 114 學年度高一第一次段考（建中、師大附中、北一女、成功、中山女中、松山），
##   數字、情境全部換過；設計稿在 docs/h1exp_tower_design.md。和高二「指數與對數」的塔（tower_bank.gd）分開，代號一律 x 開頭。
##   只用常用對數：不用換底公式、對數函數圖形、指對數方程式（和主線 E1～E3 一致）。
##   題目本身由 tools/towerlib/gen.py 產生到 h1exp_tower_data.gd：每一題是一個模板 + 幾組手挑的數字，
##   答案、提示、錯誤選項都由程式算，每一組都用 assert 驗算（改題目請改 tools/h1exp_tower/t_*.py 再跑 python3 tools/towerlib/gen.py h1exp）。
##
## 題目的格式和 poly_tower_bank.gd 一樣（id、kind、tier、title、stem、tmul、plot、steps）。
##   近似值的答案寫成固定位數的小數（例如 2.6、0.1003），填空看數值比較；答案有小數點時鍵盤多一個「.」。
const UITheme := preload("res://data/ui/game_theme.gd")
const Data := preload("res://data/levels/tower/h1exp_tower_data.gd")

const KIND_NAME := {"judge": "審判台", "pow": "倍增岩壁", "log": "十倍石階", "digit": "深谷測繩",
	"quest": "峽谷委託", "boss": "試煉大題"}
const KIND_COLOR := {"judge": UITheme.CYAN, "pow": UITheme.ORANGE, "log": UITheme.GOLD, "digit": UITheme.VIOLET,
	"quest": UITheme.LIME, "boss": UITheme.ROSE}


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
