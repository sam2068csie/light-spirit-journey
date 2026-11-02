extends "test_base.gd"
## 1. 所有腳本都能載入（語法錯誤、找不到 preload 的檔案都會在這裡抓到）


func _initialize() -> void:
	for dir in ["res://data", "res://levels"]:
		var d := DirAccess.open(dir)
		if d == null:
			continue
		for f in d.get_files():
			if not f.ends_with(".gd"):
				continue
			var s = load(dir + "/" + f)
			ok(s != null and s.can_instantiate(), "載入 %s/%s" % [dir, f])
	finish("LOAD")
