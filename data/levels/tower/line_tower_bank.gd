extends RefCounted
## 直線與圓（高一上）的終焉之塔題庫：塔頂 30 層，題目 36 題（試煉大題 12 題），每題 3 組數字
##   題目從 docs/line_tower_backlog.md 挑八大關沒有收的題型，數字、情境全部重新設計。
##   題目本身由 tools/line_tower/gen.py 產生到 line_tower_data.gd：每一題是一個模板 + 幾組手挑的數字，
##   答案、提示、錯誤選項都由程式算，每一組都用 assert 驗算（改題目請改 tools/line_tower/t_*.py 再跑 gen.py）。
##   不收圓冪、不收線性規劃；直線和圓的關係不用判別式，一律用 d 和 r 比。
##
## 題目的格式和 poly_tower_bank.gd 一樣（id、kind、tier、title、stem、tmul、plot、steps）。
##   坐標圖用幾何圖（"geo": true、"axes": true、"grid": 1），直線畫成框裡的一段，
##   每個圖形可以有 at：做到第幾步才出現（答對了圖上就多一樣東西：看得到的後果）。
##   塔的填空只看數值，沒有 groups／prop：式子都寫成只有一種填法（± 裡的格子正負號都可以）。
const UITheme := preload("res://data/ui/game_theme.gd")
const Data := preload("res://data/levels/tower/line_tower_data.gd")

const RADICALS := true

const KIND_NAME := {"judge": "真假燈標", "line": "直線工法", "dist": "距離鏡面", "circle": "圓與弦",
	"tangent": "切線圓系", "quest": "湖畔委託", "boss": "試煉大題"}
const KIND_COLOR := {"judge": UITheme.CYAN, "line": UITheme.LIME, "dist": UITheme.VIOLET, "circle": UITheme.PINK,
	"tangent": UITheme.ORANGE, "quest": UITheme.GOLD, "boss": UITheme.ROSE}


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
