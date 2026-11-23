extends RefCounted
## 數與式（高一上）的終焉之塔題庫：塔頂 30 層，題目 46 題（試煉大題 12 題），每題 3 組數字
##   考法參考六校 114 學年度高一第一次段考（建中、師大附中、北一女、成功、中山女中、松山）和 docs/num_tower_backlog.md，
##   數字、情境全部換過；設計稿在 docs/num_tower_design.md。主線八關已經有的題型不收。
##   題目本身由 tools/towerlib/gen.py 產生到 num_tower_data.gd：每一題是一個模板 + 幾組手挑的數字，
##   答案、提示、錯誤選項都由程式算，每一組都用 assert 驗算（改題目請改 tools/num_tower/t_*.py 再跑 python3 tools/towerlib/gen.py num）。
##   不收三項的算幾不等式（a^{2}b 那一型）。
##
## 題目的格式和 poly_tower_bank.gd 一樣（id、kind、tier、title、stem、tmul、plot、steps）。
##   數線圖、幾何圖用 "geo": true；絕對值的解用數線封印（line 步驟）。
##   塔的填空只看數值：兩個根號相加的答案拆成兩格（√7 + √5 → [0] + [1]）。
const UITheme := preload("res://data/ui/game_theme.gd")
const Data := preload("res://data/levels/tower/num_tower_data.gd")

const RADICALS := true

const KIND_NAME := {"judge": "審判台", "frac": "小數風車", "root": "根號磨坊", "abs": "絕對值柵欄",
	"amgm": "算幾圍籬", "boss": "試煉大題"}
const KIND_COLOR := {"judge": UITheme.CYAN, "frac": UITheme.GOLD, "root": UITheme.VIOLET, "abs": UITheme.LIME,
	"amgm": UITheme.ORANGE, "boss": UITheme.ROSE}


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
