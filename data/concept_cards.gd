extends RefCounted
## 觀念卡片的入口：依照大關所屬的單元，到那個單元自己的卡片檔拿資料
##   指數與對數 → concepts_exp.gd（L1～L8）
##   新單元：在 units.gd 那一筆寫 "concepts": "concepts_vec2.gd"，檔案裡寫
##       static func cards(level: String) -> Array: match level: "V1": return [...]
##   卡片的寫法（一般卡片、拼流程卡片、小圖、隨堂小測）見 concepts_exp.gd 開頭的說明。

const Units := preload("units.gd")

static var _cache := {}


static func cards(level: String) -> Array:
	var u: Dictionary = Units.unit(Units.unit_of_level(level))
	var path := String(u.get("concepts", ""))
	if path == "":
		return []
	if not _cache.has(path):
		var full: String = (Units as Script).resource_path.get_base_dir() + "/" + path
		_cache[path] = load(full) if ResourceLoader.exists(full) else null
	var src = _cache[path]
	return [] if src == null else src.cards(level)
