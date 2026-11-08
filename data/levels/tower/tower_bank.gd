extends RefCounted
## 指數與對數的終焉之塔題庫（參考各校 114 學年度高二上第二次段考的考法改編，數字與情境都換過）
##   題目 47 題（試煉大題 12 題），每題 3 組數字。題目本身由 tools/explog_tower/gen.py 產生到 explog_tower_data.gd：
##   每一題是一個模板 + 幾組手挑的數字，答案、提示、錯誤選項都由程式算，每一組都用 assert 驗算
##   （改題目請改 tools/explog_tower/t_*.py 再跑 gen.py）。
##
## 每一題：
##   id      唯一代號
##   kind    judge 真假審判／roots 驗根之刃／line 數線封印／extreme 極值換元／quest 現實委託／boss 試煉大題
##   tier    難度 1～3（越高的樓層越會出到難的）
##   title   題目名稱（結算畫面會顯示）
##   stem    題目敘述（MathLabel 標記，\n 換行）
##   tmul    限時倍數（大題比較長，時間多給一點）
##   plot    （可省略）左邊的小座標圖，見 boss_tower.gd 的 Plot
##   steps   一步一步作答：
##     {t: "choice", q, opts: [正確, 錯誤…], hint, write, part}
##         選擇題。opts[0] 是正確答案（畫面上會打亂）。答錯扣一顆心、顯示 hint，可以再選。
##         write：答對後寫在左邊推導板上的一行。part：大題的小題編號，例如 "(1)"。
##     {t: "judge", q, cards: [{s: 敘述, ok: 真/假, why: 理由}]}
##         一次判斷所有敘述，整題判錯兩張以上才扣一顆心。
##     {t: "roots", q, cands: [{v: 候選根, ok: 要不要留下, why}], write}
##         把不合的根劃掉（點一下劃掉，再點一下復原），按「確認」。
##     {t: "line", q, row: 這一列的名稱, marks: [數線上的關鍵點…], seg: [每一段選不選], pt: [每個點包不包含], write}
##         數線封印：點選數線上的區段和端點。同一題連續的 line 步驟共用同一條數線，前面完成的列會留著當參考。
##         seg 有 marks.size()+1 段（由左到右），pt 有 marks.size() 個；1 = 選、0 = 不選。
const UITheme := preload("res://data/ui/game_theme.gd")

const KIND_NAME := {"judge": "真假審判", "roots": "驗根之刃", "line": "數線封印", "extreme": "極值換元",
	"quest": "現實委託", "boss": "試煉大題"}
const KIND_COLOR := {"judge": UITheme.CYAN, "roots": UITheme.PINK, "line": UITheme.LIME,
	"extreme": UITheme.ORANGE, "quest": UITheme.VIOLET, "boss": UITheme.ROSE}


const Data := preload("res://data/levels/tower/explog_tower_data.gd")


static var _items: Array = []


static func items() -> Array:
	if _items.is_empty():
		_items = Data.data().duplicate(true)
		for it in _items:
			_add_factor_steps(it)
			# 另外幾組數字也補上因式分解（限時倍數跟著題目本身，不另外算）
			for v in it.get("vars", []):
				_add_factor_steps(v)
				v.erase("tmul")
	return _items


# ================= 自動補上「因式分解」 =================
## 推導板上寫「x^{2} − 5x + 4 ≤ 0　→　…」的那一步之後，補一題讓學生自己因式分解：
## 原本那一步只寫二次式，新的一步寫因式分解的結果（後面原本寫的範圍或解也接在後面）。
## 因式分解的選項（正解＋正負號、常數放錯的錯誤選項）沿用換元鍛造所的產生方式。

const B2 := preload("res://data/levels/exp/level02_bank.gd")


static func _add_factor_steps(it: Dictionary) -> void:
	var re := RegEx.new()
	re.compile("^((?:\\(\\d\\)　)?)([^=≤≥<>]*?([a-z])\\^\\{2\\}[^=≤≥<>]*?)\\s*(=|≤|≥|<|>)\\s*0(?:　→　(.*))?$")
	var steps: Array = it.steps
	var i := 0
	while i < steps.size():
		var st: Dictionary = steps[i]
		var m := re.search(String(st.get("write", "")))
		if m == null:
			i += 1
			continue
		var pre := m.get_string(1)
		var poly := m.get_string(2).strip_edges()
		var v := m.get_string(3)
		var rel := m.get_string(4)
		var rest := m.get_string(5)
		var abc := _parse_poly(poly, v)
		var fac := B2._parse_factors(rest + " = 0", v) if rest.contains(")(") else []
		if fac.size() != 2 and not abc.is_empty():
			fac = _factor_int(abc)
		if fac.size() != 2 or abc.is_empty() or B2._expand(fac) != abc:
			i += 1
			continue
		var fs := B2._factor_step({"fac_line": B2._pair_text(fac, v) + " = 0"}, v)
		var fwrite := pre.replace("(1)", "　 ").replace("(2)", "　 ").replace("(3)", "　 ") + B2._pair_text(fac, v) + " " + rel + " 0"
		if rest != "" and not rest.contains(")("):
			fwrite += "　→　" + rest
		var step := {"t": "choice", "q": "先因式分解：%s = ？" % poly, "opts": fs.options, "hint": fs.nudge, "write": fwrite}
		if st.has("part"):
			step["part"] = st.part
		st["write"] = pre + poly + " " + rel + " 0"
		steps.insert(i + 1, step)
		it["tmul"] = float(it.get("tmul", 1.0)) + 0.1
		# 圖上「完成第幾步才出現」的圖層，排在新步驟後面的要往後挪一格
		if it.has("plot"):
			for key in ["curves", "pts", "vlines"]:
				for layer in it.plot.get(key, []):
					if int(layer.get("at", 0)) > i:
						layer["at"] = int(layer.at) + 1
			if it.plot.has("band") and int(it.plot.band.get("at", 0)) > i:
				it.plot.band["at"] = int(it.plot.band.at) + 1
		i += 2


## 「2t^{2} − 9t + 4」→ [2, −9, 4]（看不懂就回傳 []）
static func _parse_poly(poly: String, v: String) -> Array:
	var re := RegEx.new()
	re.compile("^(\\d*)" + v + "\\^\\{2\\}\\s*([+−-])\\s*(\\d*)" + v + "\\s*([+−-])\\s*(\\d+)$")
	var m := re.search(poly)
	if m == null:
		return []
	var a := 1 if m.get_string(1) == "" else int(m.get_string(1))
	var b := (1 if m.get_string(3) == "" else int(m.get_string(3))) * (1 if m.get_string(2) == "+" else -1)
	var c := int(m.get_string(5)) * (1 if m.get_string(4) == "+" else -1)
	return [a, b, c]


## 整數係數的十字交乘：找 (k1·v + c1)(k2·v + c2)
static func _factor_int(abc: Array) -> Array:
	var a: int = abc[0]
	var c: int = abc[2]
	for k1 in range(1, a + 1):
		if a % k1 != 0:
			continue
		var k2 := a / k1
		for d in range(1, absi(c) + 1):
			if c % d != 0:
				continue
			for c1 in [d, -d]:
				var c2: int = c / int(c1)
				if k1 * c2 + k2 * c1 == abc[1]:
					return [[k1, c1], [k2, c2]]
	return []


static func by_id(id: String) -> Dictionary:
	for it in items():
		if it.id == id:
			return it
	return {}
