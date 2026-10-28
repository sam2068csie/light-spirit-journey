extends RefCounted
## 步驟推導題庫的小工具（所有單元共用，配合 step_level.gd）
## 新單元的題庫（例如平面向量 vec2_01_bank.gd）這樣開頭：
##
##   extends RefCounted
##   const SB := preload("step_bank.gd")
##
##   static func slots() -> Array:
##       return [
##           SB.slot("dot", 1, "內積入門",
##               "兩個向量的內積，分量對應相乘再相加。",          ← story：開頭的一句話
##               "a·b = x₁x₂ + y₁y₂；a ⊥ b ⇔ a·b = 0。",          ← insight：最後的重點
##               [
##                   SB.forge("a = (3, −2)，b = (4, 5)，求 a·b", [
##                       SB.fill("分量相乘", "x 分量相乘、y 分量相乘。", "[0] + ([1])", ["12", "-10"],
##                           "a·b = 3·4 + (−2)·5", "3·4 = ?，(−2)·5 = ?", "vec_dot"),
##                       SB.fill("相加", "算出內積。", "a·b = [0]", ["2"], "a·b = 12 − 10 = 2", "12 + (−10)", "vec_dot"),
##                   ]),
##               ]),
##       ]
##
## 寫完可以呼叫 SB.check(slots()) 檢查格式（回傳問題清單，空的就是沒問題）。
## 觀念標籤 tag 請用單元前綴（平面向量 "vec_…"、空間向量 "svec_…"），不要和別的單元重複。
##
## 文字裡可以用數學排版：^{上標}、_{下標}、√{…}、\frac{分子}{分母}、[color=#ffcf5a]…[/color]


## 一道「旅程」（一個 slot）：同一種題型，variants 裡放好幾題，每次隨機抽一題
static func slot(id: String, chapter: int, title: String, story: String, insight: String, variants: Array,
		type := "forge") -> Dictionary:
	# plain：舞台只畫背景，內容由左邊的推導台負責；params：沒有滑桿
	return {"id": id, "chapter": chapter, "type": type, "title": title, "story": story, "insight": insight,
		"variants": variants, "plain": true, "params": []}


## 一題推導：eq 是左邊鍛造台上的題目（大字），steps 是一步一步的步驟
## extra 可以加 "pre"、"time"（限時秒數）等欄位
static func forge(eq: String, steps: Array, extra := {}) -> Dictionary:
	var v := {"eq": eq, "steps": steps}
	v.merge(extra, true)
	return v


## 選擇題步驟：options 的第 correct 個是正解（畫面上會自動打亂順序）
##   why：答對後的說明　nudge：答錯時的提示　line：答對後寫進推導紀錄的那一行
static func choice(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag := "") -> Dictionary:
	return _tag({"kind": "choice", "name": name, "q": q, "options": options, "correct": correct,
		"why": why, "nudge": nudge, "line": line}, tag)


## 數字鍵盤填空：template 裡的 [0]、[1]… 是空格，answers 是每一格的答案（可以寫 "−3/2"、"1/4"）
##   mode："ordered" 依序比對（預設）、"set" 順序不限、"prop" 成比例就算對（例如方程式的係數）
static func fill(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag := "", mode := "ordered") -> Dictionary:
	return _tag({"kind": "fill", "name": name, "q": q, "template": template, "answers": answers,
		"line": line, "nudge": nudge, "mode": mode}, tag)


## 篩選：cands 是候選值，keep 是每一個該不該留下（例如不合條件的根要丟掉）
static func filter(name: String, q: String, cands: Array, keep: Array, line: String, nudge: String,
		tag := "") -> Dictionary:
	return _tag({"kind": "filter", "name": name, "q": q, "cands": cands, "keep": keep, "line": line,
		"nudge": nudge}, tag)


## 排序（由小到大）：items 用 item() 做，順序隨意（依 v 判斷）
static func order(q: String, items: Array, line: String, nudge: String, tag := "", name := "排序") -> Dictionary:
	return _tag({"kind": "order", "name": name, "q": q, "items": items, "line": line, "nudge": nudge}, tag)


## 排序的一個項目：k 是排好後顯示的短名字（例如 "a"），text 是按鈕上的式子，v 是實際大小
static func item(k: String, text: String, v: float) -> Dictionary:
	return {"k": k, "text": text, "v": v}


## 這一步開始前，先寫進推導紀錄的已知條件（一行或多行）
static func with_pre(step: Dictionary, pre) -> Dictionary:
	var s := step.duplicate()
	s["pre"] = pre
	return s


static func _tag(d: Dictionary, tag: String) -> Dictionary:
	if tag != "":
		d["tag"] = tag
	return d


## 檢查題庫格式，回傳問題清單（空的就是沒問題）
static func check(slots: Array) -> Array:
	var out := []
	var ids := {}
	for s in slots:
		var sid := String(s.get("id", "?"))
		if ids.has(sid):
			out.append("slot id 重複：" + sid)
		ids[sid] = true
		for k in ["chapter", "type", "title", "variants"]:
			if not s.has(k):
				out.append("%s 少了 %s" % [sid, k])
		if s.get("type", "") != "forge":
			continue
		for vi in s.get("variants", []).size():
			var v: Dictionary = s.variants[vi]
			var where := "%s 第 %d 題" % [sid, vi + 1]
			if not v.has("eq"):
				out.append(where + " 少了 eq")
			for st in v.get("steps", []):
				out.append_array(_check_step(st, where))
	return out


static func _check_step(st: Dictionary, where: String) -> Array:
	var out := []
	var w := "%s「%s」" % [where, st.get("name", "?")]
	for k in ["kind", "name", "q", "line", "nudge"]:
		if not st.has(k):
			out.append(w + " 少了 " + k)
	match st.get("kind", ""):
		"choice":
			if int(st.correct) < 0 or int(st.correct) >= st.options.size():
				out.append(w + " 正解編號超出選項範圍")
		"fill":
			var n := 0
			while String(st.template).contains("[%d]" % n):
				n += 1
			if n != st.answers.size():
				out.append(w + " 空格 %d 個，答案卻有 %d 個" % [n, st.answers.size()])
		"filter":
			if st.cands.size() != st.keep.size():
				out.append(w + " cands 和 keep 數量不一樣")
		"order":
			var vs := {}
			for it in st.items:
				if vs.has(float(it.v)):
					out.append(w + " 有兩個項目一樣大，排序會有兩種答案")
				vs[float(it.v)] = true
	return out


## 題庫裡的根號寫成「√48」「√(64 − 16)」也可以：這個函式把要顯示的文字都改成排版用的 √{48}、√{64 − 16}
## （上面才會有一槓蓋住）。答案（answers、cands）保持原樣，給數字鍵盤比對用。
static func fix_roots(x, key := ""):
	if x is Dictionary:
		for k in x.keys():
			if String(k) in ["answers", "cands", "keep", "ans"]:
				continue
			x[k] = fix_roots(x[k], String(k))
	elif x is Array:
		for i in x.size():
			x[i] = fix_roots(x[i], key)
	elif x is String:
		return root_markup(x)
	return x


static var _re_paren: RegEx
static var _re_num: RegEx

static func root_markup(s: String) -> String:
	if not s.contains("√"):
		return s
	if _re_paren == null:
		_re_paren = RegEx.new()
		_re_paren.compile("√\\(([^()]*)\\)")
		_re_num = RegEx.new()
		_re_num.compile("√(\\d+)")
	s = _re_paren.sub(s, "√{$1}", true)
	return _re_num.sub(s, "√{$1}", true)
