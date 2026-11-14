extends "test_base.gd"
## 閱讀量檢查（design_rules 1.8「看圖作答、少讀字」）：數與式之後的單元，學生每一步要讀的中文字有上限
##   只數中文字（數學式、標點不算）。數學本身就是題目，要減少的是「用文字重述」。
##   上限見 LIMITS。超過就是要改寫：把位置、順序、約分改成在圖上作答，提示只說要做什麼。
##   解釋（why、nudge、insight、line）是答完才出現的，不在這裡管。
## GODOT=… tests/run_tests.sh reading

const Units := preload("res://data/core/units.gd")
const Paths := preload("res://data/core/paths.gd")

## 套用這條規則的單元
const READ_UNITS := ["h1num"]
const LIMITS := {
	"story": 24,       # 故事一句話
	"eq": 20,          # 題目：數學＋要回答的問題
	"eq_lines": 3,
	"q": 10,           # 每一步的提示
	"judge": 14,       # 審判卡的敘述（敘述本身就是問題）
	"option": 8,       # 每一個選項
	"template": 6,     # 填空模板裡的字
	"speed_q": 10,
	"speed_eq": 12,
}

var over: Array = []


static func cjk(s: String) -> int:
	var n := 0
	for ch in s:
		var c := ch.unicode_at(0)
		if c >= 0x4E00 and c <= 0x9FFF:
			n += 1
	return n


func _limit(where: String, what: String, s: String, key: String) -> void:
	checks += 1
	var n := cjk(s)
	if n > int(LIMITS[key]):
		fails += 1
		print("FAIL: %s %s 有 %d 個字（上限 %d）：%s" % [where, what, n, LIMITS[key], s.replace("\n", " / ")])


func _initialize() -> void:
	await setup()
	for u in Units.UNITS:
		if not READ_UNITS.has(String(u.id)):
			continue
		for l in u.levels:
			if String(l.get("bank", "")) == "":
				continue
			var lid := String(l.id)
			var bank = load(Paths.of(String(l.bank)))
			for slot in bank.slots():
				var where := "%s/%s" % [lid, slot.id]
				_limit(where, "story", String(slot.get("story", "")), "story")
				if String(slot.type) == "speed":
					_speed(l, bank, slot, where)
					continue
				for vi in slot.variants.size():
					var v: Dictionary = slot.variants[vi]
					var w2 := "%s 第 %d 組" % [where, vi + 1]
					var eq := String(v.get("eq", ""))
					_limit(w2, "題目", eq, "eq")
					checks += 1
					if eq.split("\n").size() > int(LIMITS.eq_lines):
						fails += 1
						print("FAIL: %s 題目超過 %d 行" % [w2, LIMITS.eq_lines])
					for st in v.get("steps", []):
						var nm := "「%s」" % String(st.get("name", ""))
						var opts: Array = st.get("options", [])
						var judge := opts.size() == 2 and String(opts[0]).contains("成立")
						_limit(w2, nm + "提示", String(st.get("q", "")), "judge" if judge else "q")
						if not judge:
							for o in opts:
								_limit(w2, nm + "選項", String(o), "option")
						if st.has("template"):
							_limit(w2, nm + "填空", String(st.template), "template")
	finish("READING")


func _speed(l: Dictionary, bank, slot: Dictionary, where: String) -> void:
	var gen := String(slot.variants[0].get("gen", ""))
	var srcs := [bank]
	if String(l.get("file", "")) != "":
		srcs.append(load(Paths.of(String(l.file))))
	for src in srcs:
		var names: Array = (src as Script).get_script_method_list().map(func(m): return m.name)
		if names.has("gen_problems"):
			for pb in src.gen_problems(gen, 12):
				_limit(where + " 速算", "提示", String(pb.get("q", "")), "speed_q")
				_limit(where + " 速算", "題目", String(pb.get("eq", "")), "speed_eq")
				for o in pb.get("choices", []):
					_limit(where + " 速算", "選項", String(o), "option")
			return
