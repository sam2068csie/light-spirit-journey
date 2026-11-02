extends "test_base.gd"
## 1. 所有腳本都能載入（語法錯誤、找不到 preload 的檔案都會在這裡抓到）
##    也檢查 paths.gd：每個腳本都登記了、單元設定裡的 file／bank／map 都找得到

const Paths := preload("res://data/core/paths.gd")
const Units := preload("res://data/core/units.gd")


func _scan(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		_scan(dir + "/" + sub, out)


func _initialize() -> void:
	var all := []
	_scan("res://data", all)
	_scan("res://levels", all)
	for path in all:
		var s = load(path)
		ok(s != null and s.can_instantiate(), "載入 %s" % path)
		if String(path).begins_with("res://data/"):
			ok(Paths.of(String(path).get_file()) == path, "paths.gd 有登記 %s（請執行 tools/gen_paths.py）" % path)
	for u in Units.UNITS:
		for key in ["map", "tower", "concepts"]:
			var v := String(u.get(key, ""))
			if v != "":
				ok(ResourceLoader.exists(Paths.of(v)), "單元 %s 的 %s：%s" % [u.id, key, v])
		for l in u.levels:
			for key in ["file", "bank"]:
				var v := String(l.get(key, ""))
				if v != "":
					ok(ResourceLoader.exists(Paths.of(v)), "大關 %s 的 %s：%s" % [l.id, key, v])
	finish("LOAD")
