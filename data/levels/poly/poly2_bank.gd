extends RefCounted
## 多項式 第二大關「綜合除法水車」題庫（對應講義 4-1 重點二：多項式的除法）
##
## 旅程（引擎見 step_level.gd，這一關的畫面見 level_poly2_wheel.gd）：
##   forge  一步一步推導，用 choice、fill。這一關多一種填空：
##            綜合除法（_synth 做出來的 fill，多了 "synth" 欄位）：下方照課本的寫法畫出三排的綜合除法
##            （k 寫在右邊、每個數帶正負號、餘式圈起來）。學生填第三排；第二排會自動算出「前一格 × k」。
##            除式是 mx + n 時，_divrow 再把商除以 m 寫在第四排；連續使用時（base、chain）算式一路往下疊。
##            答案由程式從係數算出來，不用手寫。
##   speed  速算：gen = "synth"（三次式除以 x − a 的餘式或商式的常數項）
##
## 觀念標籤都用 poly_ 開頭（名稱寫在 quiz_manager.gd 的 MISTAKE_INFO）。
## 題目的數字都用程式驗算過（綜合除法、長除法、三步驟求值、連續綜合除法）。

const SB := preload("res://data/levels/engine/step_bank.gd")

const T_SYN := "poly_synth"        # 綜合除法的操作（缺項補 0、寫的數）
const T_LIN := "poly_divlin"       # 除式是 ax + b：商式要除以 a
const T_RULE := "poly_divrule"     # 除法原理：被除式 = 除式 × 商式 + 餘式
const T_QUAD := "poly_divquad"     # 除式是二次式（整除、餘式相同）
const T_EVAL := "poly_eval3"       # 三步驟求值
const T_SHIFT := "poly_shift"      # 多項式的變形（連續綜合除法）


static func _c(name: String, q: String, options: Array, correct: int, why: String, nudge: String,
		line: String, tag: String) -> Dictionary:
	return SB.choice(name, q, options, correct, why, nudge, line, tag)


static func _f(name: String, q: String, template: String, answers: Array, line: String, nudge: String,
		tag: String, mode := "ordered") -> Dictionary:
	return SB.fill(name, q, template, answers, line, nudge, tag, mode)


# ================= 分數的小工具（綜合除法可能除以 x − 1/2） =================

static func _gcd(a: int, b: int) -> int:
	a = absi(a)
	b = absi(b)
	while b != 0:
		var t := a % b
		a = b
		b = t
	return maxi(a, 1)

static func _q(n: int, d := 1) -> Array:
	if d < 0:
		n = -n
		d = -d
	var g := _gcd(n, d)
	return [n / g, d / g]

static func _qadd(a: Array, b: Array) -> Array:
	return _q(a[0] * b[1] + b[0] * a[1], a[1] * b[1])

static func _qmul(a: Array, b: Array) -> Array:
	return _q(a[0] * b[0], a[1] * b[1])

## 答案用的寫法：−3 寫成 "-3"、1/2 寫成 "1/2"
static func _qa(a: Array) -> String:
	return str(a[0]) if a[1] == 1 else "%d/%d" % [a[0], a[1]]

## 顯示用的寫法：負號用 −
static func _qs(a: Array) -> String:
	var s := str(absi(a[0])) if a[1] == 1 else "%d/%d" % [absi(a[0]), a[1]]
	return ("−" if a[0] < 0 else "") + s

## 係數（由高次到低次）寫成多項式：[2, 1, 6] → 2x^{2} + x + 6
static func poly_text(cs: Array) -> String:
	var out := ""
	var n := cs.size() - 1
	for i in cs.size():
		var c: Array = cs[i] if cs[i] is Array else _q(int(cs[i]))
		if c[0] == 0:
			continue
		var k := n - i
		var mag := _qs(_q(absi(c[0]), c[1]))
		var body := ""
		if k == 0:
			body = mag
		else:
			body = ("" if mag == "1" else mag) + ("x" if k == 1 else "x^{%d}" % k)
		if out == "":
			out = ("−" if c[0] < 0 else "") + body
		else:
			out += (" − " if c[0] < 0 else " + ") + body
	return out if out != "" else "0"

## 綜合除法的第三排（商式的係數＋最後的餘式）
static func synth_row(coef: Array, a: Array) -> Array:
	var b := [_q(int(coef[0]))]
	for i in range(1, coef.size()):
		b.append(_qadd(_q(int(coef[i])), _qmul(a, b[i - 1])))
	return b

## 除式 x − a 的寫法
static func divisor_text(a: Array) -> String:
	if a[0] == 0:
		return "x"
	return "x %s %s" % ["−" if a[0] > 0 else "+", _qs(_q(absi(a[0]), a[1]))]


## 綜合除法的填空（課本的寫法）：學生填第三排（商式的係數、圈起來的餘式），答案由程式算
##   coef：被除式的係數（由高次到低次，缺項補 0），a：除以 x − a 的 a（寫在右邊；分數寫成 [分子, 分母]）
##   extra 可以加：
##     "base": 最初的係數、"chain": 第幾次（從 0 開始）→ 綜合除法的連續使用，前面幾次的算式會疊在上面
static func _synth(coef: Array, a: Array, line := "", name := "綜合除法", extra := {}) -> Dictionary:
	var row := synth_row(coef, a)
	var n := row.size()
	var slots := []
	for i in n - 1:
		slots.append("[%d]" % i)
	var tpl := "第三排：%s ｜ 餘式 [%d]" % ["，".join(slots), n - 1]
	var answers := row.map(func(v): return _qa(v))
	var q := row.slice(0, n - 1)
	if line == "":
		line = "商式 %s，餘式 %s" % [poly_text(q), _qs(row[n - 1])]
	var spec := {"coef": coef, "a": a}
	spec.merge(extra, true)
	return {"kind": "fill", "name": name,
		"q": "完成綜合除法的第三排：第一個係數直接寫下來，乘以 %s 寫到下一格的第二排，上下相加寫到第三排。" % _qs(a),
		"template": tpl, "answers": answers, "line": line,
		"nudge": "第三排的每一格 = 第一排 + 第二排\n第二排 = 前一格的第三排 × %s。" % _qs(a), "tag": T_SYN,
		"synth": spec}


## 除式是 mx + n：用 −n/m 做完綜合除法之後，第三排的商再除以 m，寫在第四排（餘式不變）
static func _divrow(coef: Array, a: Array, m: int, line: String) -> Dictionary:
	var row := synth_row(coef, a)
	var q := row.slice(0, row.size() - 1).map(func(v): return _qmul(v, _q(1, m)))
	var slots := []
	for i in q.size():
		slots.append("[%d]" % i)
	return {"kind": "fill", "name": "商除以 %d" % m, "q": "把第三排的商（不含餘式）都除以 %d，寫到第四排。餘式不變。" % m,
		"template": "第四排：%s" % "，".join(slots), "answers": q.map(func(v): return _qa(v)), "line": line,
		"nudge": "第三排的每個數都除以 %d。" % m, "tag": T_LIN, "synth": {"coef": coef, "a": a, "m": m, "divrow": true}}


# ================= 長除法（可以有 a、b 這種未知係數） =================
## 係數用「一次式」表示：{"c": [分子, 分母], "s": {"a": [分子, 分母]}}，例如 a + 8 → {"c": [8, 1], "s": {"a": [1, 1]}}
## 被除式的係數可以寫整數，或 "a"、"-k" 這種（代表 a、−k）；除式的係數都是整數，首項係數是 1

static func lx(v) -> Dictionary:
	if v is String:
		var neg: bool = v.begins_with("-")
		return {"c": [0, 1], "s": {v.trim_prefix("-"): [-1 if neg else 1, 1]}}
	if v is Array:
		return {"c": v, "s": {}}
	return {"c": _q(int(v)), "s": {}}

static func lx_sub(a: Dictionary, b: Dictionary) -> Dictionary:
	var s := {}
	for k in a.s:
		s[k] = a.s[k]
	for k in b.s:
		s[k] = _qadd(s.get(k, [0, 1]), _qmul(b.s[k], [-1, 1]))
	for k in s.keys():
		if s[k][0] == 0:
			s.erase(k)
	return {"c": _qadd(a.c, _qmul(b.c, [-1, 1])), "s": s}

static func lx_mul(a: Dictionary, q: Array) -> Dictionary:
	var s := {}
	for k in a.s:
		s[k] = _qmul(a.s[k], q)
	return {"c": _qmul(a.c, q), "s": s}

static func lx_num(a: Dictionary) -> bool:
	return a.s.is_empty()

static func lx_zero(a: Dictionary) -> bool:
	return a.s.is_empty() and a.c[0] == 0

## 係數的文字（不含正負號以外的括號處理）：a + 8、−k − 5、−3
static func lx_text(a: Dictionary) -> String:
	var parts := []
	for k in a.s:
		var q: Array = a.s[k]
		var m := _qs(_q(absi(q[0]), q[1]))
		parts.append([q[0] < 0, ("" if m == "1" else m) + k])
	if a.c[0] != 0 or parts.is_empty():
		parts.append([a.c[0] < 0, _qs(_q(absi(a.c[0]), a.c[1]))])
	var out := ""
	for i in parts.size():
		if i == 0:
			out = ("−" if parts[i][0] else "") + parts[i][1]
		else:
			out += (" − " if parts[i][0] else " + ") + parts[i][1]
	return out

## 一項的文字：係數 × x^{k}；first：這一排的第一項（正號不寫）
static func term_text(a: Dictionary, k: int, first: bool) -> String:
	var xs := "" if k == 0 else ("x" if k == 1 else "x^{%d}" % k)
	var body := ""
	var neg := false
	if lx_num(a):
		neg = a.c[0] < 0
		var m := _qs(_q(absi(a.c[0]), a.c[1]))
		body = (m if (m != "1" or k == 0) else "") + xs
	else:
		var t := lx_text(a)
		if a.c[0] == 0 and a.s.size() == 1:
			neg = t.begins_with("−")
			body = t.trim_prefix("−") + xs
		else:
			body = "(" + t + ")" + xs
	if first:
		return ("−" if neg else "") + body
	return ("− " if neg else "+ ") + body

## 長除法：f 除以 g（係數由高到低）；qv：已經知道的商式係數（null 表示還沒填，之後的都先不算）
## 回傳 {"q": 商式係數, "rows": [{"terms": [[次數, 係數]], "line": 下面要不要畫橫線}], "rem": 餘式係數（[次數, 係數]）}
static func long_rows(f: Array, g: Array, qv = null) -> Dictionary:
	var cur: Array = f.map(func(v): return lx(v))
	var dg := g.size() - 1
	var df := f.size() - 1
	var nq := df - dg + 1
	var q := []
	var rows := []
	var complete := true
	for i in nq:
		var top := df - i                      # 這一輪要消掉的次數
		var lead: Dictionary = cur[i]
		var qi: Dictionary = lx_mul(lead, _q(1, int(g[0])))
		if qv != null:
			if i >= qv.size() or qv[i] == null:
				complete = false
				break
			qi = lx(qv[i])
		q.append(qi)
		# 乘回去：qi × g，對齊次數 top … top − dg
		var prod := []
		for j in g.size():
			prod.append([top - j, lx_mul(qi, _q(int(g[j])))])
		rows.append({"terms": prod, "line": true, "kind": "prod"})
		for j in g.size():
			cur[i + j] = lx_sub(cur[i + j], prod[j][1])
		# 相減之後的那一排：次數 top − 1 … top − dg − 1（多帶下來一項）
		if i < nq - 1:
			var diff := []
			for d in range(top - 1, maxi(top - dg - 2, -1), -1):
				diff.append([d, cur[df - d]])
			rows.append({"terms": diff, "line": false, "kind": "diff"})
	var rem := []
	if complete:
		for d in range(dg - 1, -1, -1):
			rem.append([d, cur[df - d]])
	return {"q": q, "rows": rows, "rem": rem, "complete": complete}


## 長除法的填空：下方畫出完整的長除法（直式），學生填商式的係數（rem = true 時也填餘式的係數）
static func _long(f: Array, g: Array, line: String, rem := true, name := "長除法") -> Dictionary:
	var res := long_rows(f, g)
	var df := f.size() - 1
	var dg := g.size() - 1
	var parts := []
	var answers := []
	var n := 0
	for i in res.q.size():
		var k: int = df - dg - i
		parts.append("[%d]" % n + ("" if k == 0 else ("x" if k == 1 else "x^{%d}" % k)))
		answers.append(_qa(res.q[i].c))
		n += 1
	var tpl := "商式：" + " + ".join(parts)
	if rem:
		var rp := []
		for t in res.rem:
			rp.append("[%d]" % n + ("" if t[0] == 0 else ("x" if t[0] == 1 else "x^{%d}" % t[0])))
			answers.append(_qa(t[1].c))
			n += 1
		tpl += "　　餘式：" + " + ".join(rp)
	var ask := "填出商式的係數" + ("和餘式" if rem else "") + "（每一輪：最高次項相除、乘回去、相減）。"
	return {"kind": "fill", "name": name, "q": ask, "template": tpl, "answers": answers, "line": line,
		"nudge": "先用被除式的最高次項除以除式的最高次項，得到商的一項\n乘回去、相減，再做下一輪。", "tag": T_QUAD,
		"longdiv": {"f": f, "g": g, "rem": rem}}


static func slots() -> Array:
	var out := _slots()
	for slot in out:
		slot["plain"] = true          # 舞台只畫背景，內容由推導台負責
		SB.fix_roots(slot)
		slot["params"] = slot.get("params", [])
	return out


static func _slots() -> Array:
	return [
		# ======================= 第一章．水車入門 =======================
		{"id": "synth1", "chapter": 1, "type": "forge", "title": "轉動水車",
		 "story": "綜合除法三排數字：乘以 k、上下相加，最後一個數是餘式。",
		 "insight": "除以 x − k：k 寫在右邊。第一排是被除式的係數（由高次到低次，缺項補 0）\n第三排前面是商式的係數（少一次），最後圈起來的是餘式。",
		 "variants": [
			{"eq": "2x^{3} − 3x^{2} + 4x − 5 除以 x − 2",
			 "steps": [
				_c("寫哪個數", "除式是 x − 2，綜合除法右邊要寫哪個數？", ["2", "−2", "1", "−5"], 0,
					"x − 2 = 0 ⇒ x = 2，右邊寫 +2。", "讓除式等於 0 的 x。", "除以 x − 2：右邊寫 +2", T_SYN),
				_synth([2, -3, 4, -5], [2, 1]),
				_c("讀出結果", "第三排是 +2、+1、+6，圈起來的是 +7。商式和餘式是？",
					["商 2x^{2} + x + 6，餘 7", "商 2x^{3} + x^{2} + 6x，餘 7", "商 2x^{2} + x + 6，餘 0", "商 x^{2} + 6，餘 7"], 0,
					"三次式除以一次式，商式是二次：2x^{2} + x + 6\n最後一格 7 是餘式。", "商式比被除式少一次。",
					"2x^{3} − 3x^{2} + 4x − 5 = (x − 2)(2x^{2} + x + 6) + 7", T_SYN),
			 ]},
			{"eq": "x^{3} − 7x + 6 除以 x + 3",
			 "steps": [
				_c("缺項補 0", "被除式沒有 x^{2} 項。第一排要怎麼寫？", ["+1 +0 −7 +6", "+1 −7 +6", "+0 +1 −7 +6", "+1 +7 +6"], 0,
					"缺的 x^{2} 項係數是 0，要寫 +0 佔住位置，才不會對錯格。", "x^{3}、x^{2}、x、常數，四個位置都要有。", "x^{3} + 0x^{2} − 7x + 6：第一排寫 +1 +0 −7 +6", T_SYN),
				_c("寫哪個數", "除式是 x + 3，綜合除法右邊要寫哪個數？", ["−3", "3", "1", "6"], 0,
					"x + 3 = 0 ⇒ x = −3。", "讓除式等於 0 的 x。", "除以 x + 3：右邊寫 −3", T_SYN),
				_synth([1, 0, -7, 6], [-3, 1]),
				_c("餘式是 0", "餘式是 0，代表什麼？", ["x + 3 整除 x^{3} − 7x + 6（是它的因式）", "商式是 0", "x = 0 是根", "算錯了"], 0,
					"餘式 0 ⇒ x^{3} − 7x + 6 = (x + 3)(x^{2} − 3x + 2)，x + 3 是因式。", "被除式 = 除式 × 商式 + 0。",
					"x^{3} − 7x + 6 = (x + 3)(x^{2} − 3x + 2)", T_SYN),
			 ]},
			{"eq": "3x^{4} − 5x^{3} + x − 2 除以 x − 1",
			 "steps": [
				_c("缺項補 0", "被除式沒有 x^{2} 項。第一排要怎麼寫？", ["+3 −5 +0 +1 −2", "+3 −5 +1 −2", "+3 −5 +1 +0 −2", "+0 +3 −5 +1 −2"], 0,
					"由高次到低次：x^{4}、x^{3}、x^{2}（+0）、x、常數。", "x^{2} 項放在 x^{3} 和 x 中間。", "第一排寫 +3 −5 +0 +1 −2", T_SYN),
				_synth([3, -5, 0, 1, -2], [1, 1]),
				_c("商式幾次", "商式是幾次？", ["3 次", "4 次", "2 次", "1 次"], 0,
					"四次式除以一次式，商式少一次。", "被除式的次數 − 除式的次數。", "商式 3x^{3} − 2x^{2} − 2x − 1（三次），餘式 −3", T_SYN),
			 ]},
		 ]},

		{"id": "linear", "chapter": 1, "type": "forge", "title": "斜斜的水道",
		 "story": "除式是 2x − 1 時，先用 1/2 做綜合除法，再把商除以 2。",
		 "insight": "除以 mx + n：先以 −n/m 做綜合除法（等於除以 x + n/m），第三排的商再除以 m 寫到第四排，餘式不變。",
		 "variants": [
			{"eq": "4x^{3} − 2x^{2} + 6x − 1 除以 2x − 1",
			 "steps": [
				_c("寫哪個數", "2x − 1 = 0 的 x 是？", ["1/2", "2", "−1/2", "1"], 0,
					"2x − 1 = 0 ⇒ x = 1/2。", "解 2x − 1 = 0。", "2x − 1 = 0 ⇒ 右邊寫 +1/2", T_LIN),
				_synth([4, -2, 6, -1], [1, 2], "除以 x − 1/2：商式 4x^{2} + 6，餘式 2"),
				_c("調整商式", "剛剛算的是除以 x − 1/2。改成除以 2x − 1，要怎麼調整？",
					["商式除以 2，餘式不變", "商式乘以 2，餘式不變", "商式和餘式都除以 2", "都不用改"], 0,
					"(x − 1/2)(4x^{2} + 6) = (2x − 1)(2x^{2} + 3)：把 2 分給除式，商式就要除以 2。餘式 2 不動。", "x − 1/2 是 2x − 1 的一半。",
					"(x − 1/2)(4x^{2} + 6) + 2 = (2x − 1)(2x^{2} + 3) + 2", T_LIN),
				_divrow([4, -2, 6, -1], [1, 2], 2, "除以 2x − 1：商式 2x^{2} + 3，餘式 2"),
			 ]},
			{"eq": "6x^{3} + x^{2} − 5x + 3 除以 3x + 2",
			 "steps": [
				_c("寫哪個數", "3x + 2 = 0 的 x 是？", ["−2/3", "2/3", "−3/2", "−2"], 0,
					"3x + 2 = 0 ⇒ x = −2/3。", "解 3x + 2 = 0。", "3x + 2 = 0 ⇒ 右邊寫 −2/3", T_LIN),
				_synth([6, 1, -5, 3], [-2, 3], "除以 x + 2/3：商式 6x^{2} − 3x − 3，餘式 5"),
				_c("調整商式", "改成除以 3x + 2，要怎麼調整？",
					["商式除以 3，餘式不變", "商式乘以 3，餘式不變", "商式和餘式都除以 3", "餘式除以 3"], 0,
					"x + 2/3 是 3x + 2 的三分之一，商式要除以 3 補回來。", "把 3 分給除式。", "(x + 2/3)(6x^{2} − 3x − 3) = (3x + 2)(2x^{2} − x − 1)", T_LIN),
				_divrow([6, 1, -5, 3], [-2, 3], 3, "除以 3x + 2：商式 2x^{2} − x − 1，餘式 5"),
			 ]},
		 ]},

		{"id": "rule", "chapter": 1, "type": "forge", "title": "水車的帳本",
		 "story": "被除式 = 除式 × 商式 + 餘式。知道其中幾項，就能找回未知數。",
		 "insight": "除法原理：f(x) = g(x)·q(x) + r(x)，餘式的次數比除式低。把右邊展開，再和左邊比較係數。",
		 "variants": [
			{"eq": "3x^{3} + ax^{2} + 2x + b 除以 x^{2} − x + 1\n商式 cx + 2，餘式 dx − 1，求 a + b + c + d",
			 "steps": [
				_c("除法原理", "被除式、除式、商式、餘式的關係是？",
					["被除式 = 除式 × 商式 + 餘式", "被除式 = 除式 × 餘式 + 商式", "除式 = 被除式 × 商式 + 餘式", "被除式 = (除式 + 餘式) × 商式"], 0,
					"這就是除法原理，跟整數 17 = 5 × 3 + 2 一樣。", "想想 17 除以 5，商 3 餘 2。",
					"3x^{3} + ax^{2} + 2x + b = (x^{2} − x + 1)(cx + 2) + dx − 1", T_RULE),
				_f("比 x³ 項", "右邊的 x^{3} 只來自 x^{2} · cx。", "c = [0]", ["3"], "x^{3} 項：c = 3", "左邊 x^{3} 的係數是 3。", T_RULE),
				_f("展開右邊", "c = 3：(x^{2} − x + 1)(3x + 2) + dx − 1 = 3x^{3} − x^{2} + (d + 1)x + 1。比較其他項。",
					"a = [0]，d = [1]，b = [2]", ["-1", "1", "1"],
					"x^{2} 項：a = −1\nx 項：d + 1 = 2 ⇒ d = 1\n常數：b = 1", "x 項：d + 1 要等於左邊的 2。", T_RULE),
				_f("求和", "算出 a + b + c + d。", "a + b + c + d = [0]", ["4"], "a + b + c + d = −1 + 1 + 3 + 1 = 4", "−1 + 1 + 3 + 1。", T_RULE),
			 ]},
			{"eq": "x^{3} − 2x^{2} + ax + b 除以 x^{2} − x + 2\n商式 x + c，餘式 3x − 1，求 a + b + c",
			 "steps": [
				_c("除法原理", "被除式 x^{3} − 2x^{2} + ax + b 要寫成哪一個？",
					["(x^{2} − x + 2)(x + c) + 3x − 1", "(x^{2} − x + 2)(3x − 1) + x + c", "(x + c)(3x − 1) + x^{2} − x + 2", "(x^{2} − x + 2)(x + c)"], 0,
					"被除式 = 除式 × 商式 + 餘式。", "餘式加在最後面。", "x^{3} − 2x^{2} + ax + b = (x^{2} − x + 2)(x + c) + 3x − 1", T_RULE),
				_f("比 x² 項", "右邊展開：x^{3} + (c − 1)x^{2} + (5 − c)x + (2c − 1)。比較 x^{2} 項。", "c = [0]", ["-1"],
					"c − 1 = −2 ⇒ c = −1", "c − 1 要等於左邊的 −2。", T_RULE),
				_f("比其他項", "c = −1 代進去，比較 x 項和常數項。", "a = [0]，b = [1]", ["6", "-3"],
					"a = 5 − c = 6，b = 2c − 1 = −3", "x 項：a = 5 − c\n常數：b = 2c − 1。", T_RULE),
				_f("求和", "算出 a + b + c。", "a + b + c = [0]", ["2"], "a + b + c = 6 − 3 − 1 = 2", "6 + (−3) + (−1)。", T_RULE),
			 ]},
		 ]},

		{"id": "speed1", "chapter": 1, "type": "speed", "title": "水車速算", "time": 150.0,
		 "story": "用綜合除法算出餘式或商式的常數項！",
		 "insight": "除以 x − k：右邊寫 k。第三排 = 第一排 + 第二排，第二排 = 前一格 × k。",
		 "variants": [{"gen": "synth", "count": 6}]},

		# ======================= 第二章．深層水車 =======================
		{"id": "quad", "chapter": 2, "type": "forge", "title": "雙槽水車",
		 "story": "除式是二次式就用長除法：除、乘回去、相減，一層一層往下。",
		 "insight": "長除法：最高次項相除得到商的一項，乘回去、相減，重複到剩下的次數比除式低。除式是二次式時，餘式最多一次（px + q）。",
		 "variants": [
			{"eq": "x^{3} + 2x^{2} + ax + b 除以 x^{2} + x − 2\n餘式是 3x + 1，求 a + b",
			 "steps": [
				_long([1, 2, "a", "b"], [1, 1, -2], "商式 x + 1，餘式 (a + 1)x + (b + 2)", false),
				_f("比較餘式", "長除法的餘式是 (a + 1)x + (b + 2)，要等於 3x + 1。", "a = [0]，b = [1]", ["2", "-1"],
					"a + 1 = 3、b + 2 = 1 ⇒ a = 2，b = −1", "a + 1 = 3、b + 2 = 1。", T_QUAD),
				_f("求和", "算出 a + b。", "a + b = [0]", ["1"], "a + b = 2 + (−1) = 1", "2 − 1。", T_QUAD),
			 ]},
			{"eq": "x^{2} − 3x + 1 = 0 的兩根，也是\nx^{4} − 2x^{3} − 3x^{2} + mx + n = 0 的根，求 m + n",
			 "steps": [
				_c("代表什麼", "x^{2} − 3x + 1 的兩根都是四次式的根，代表？",
					["x^{2} − 3x + 1 整除那個四次式（餘式 = 0）", "兩個式子相等", "m = n", "x^{2} − 3x + 1 = 0 沒有實根"], 0,
					"兩個根都讓四次式等於 0，所以四次式除以 x^{2} − 3x + 1 的餘式是 0。", "根都一樣，就能整除。",
					"x^{2} − 3x + 1 整除 ⇒ 餘式 = 0", T_QUAD),
				_long([1, -2, -3, "m", "n"], [1, -3, 1], "商式 x^{2} + x − 1，餘式 (m − 4)x + (n + 1)", false),
				_f("餘式 = 0", "(m − 4)x + (n + 1) = 0 恆成立：兩個係數都是 0。", "m = [0]，n = [1]", ["4", "-1"],
					"m − 4 = 0、n + 1 = 0 ⇒ m = 4，n = −1", "m − 4 = 0、n + 1 = 0。", T_QUAD),
				_f("求和", "算出 m + n。", "m + n = [0]", ["3"], "m + n = 4 + (−1) = 3", "4 − 1。", T_QUAD),
			 ]},
			{"eq": "2x^{3} + x^{2} − kx + 2 與 x^{3} − x^{2} + x + 1\n除以 x^{2} + x + 1 的餘式相同，求 k",
			 "steps": [
				_long([2, 1, "-k", 2], [1, 1, 1], "第一個：商式 2x − 1，餘式 (−k − 1)x + 3", false, "第一個"),
				_long([1, -1, 1, 1], [1, 1, 1], "第二個：商式 x − 2，餘式 2x + 3", true, "第二個"),
				_f("求 k", "兩個餘式相同：(−k − 1)x + 3 = 2x + 3。", "k = [0]", ["-3"], "−k − 1 = 2 ⇒ k = −3", "−k − 1 = 2。", T_QUAD),
			 ]},
		 ]},

		{"id": "eval3", "chapter": 2, "type": "forge", "title": "三步驟求值",
		 "story": "√2 − 1 代進三次式太辛苦。先找它滿足的二次方程式，再用長除法降次。",
		 "insight": "三步驟：① x = √2 − 1 ⇒ x + 1 = √2，平方得 x^{2} + 2x − 1 = 0\n② f(x) 除以 x^{2} + 2x − 1\n③ f(√2 − 1) = 餘式在 √2 − 1 的值。",
		 "variants": [
			{"eq": "x = √2 − 1，求 2x^{3} + 3x^{2} − 3x + 4 的值",
			 "steps": [
				_f("① 找方程式", "x + 1 = √2，兩邊平方。", "x^{2} + [0]x + [1] = 0", ["2", "-1"],
					"(x + 1)^{2} = 2 ⇒ x^{2} + 2x − 1 = 0", "x^{2} + 2x + 1 = 2。", T_EVAL),
				_c("為什麼要除", "f(x) = (x^{2} + 2x − 1)·q(x) + 餘式。x = √2 − 1 代進去，會怎樣？",
					["前面那項變 0，只剩餘式", "整個式子變 0", "q(x) 變成 0", "沒有差別"], 0,
					"x^{2} + 2x − 1 = 0，所以 (x^{2} + 2x − 1)·q(x) = 0。", "x = √2 − 1 是 x^{2} + 2x − 1 = 0 的根。",
					"f(√2 − 1) = 餘式在 x = √2 − 1 的值", T_EVAL),
				_long([2, 3, -3, 4], [1, 2, -1], "② 商式 2x − 1，餘式 x + 3", true, "② 長除法"),
				_f("③ 代入餘式", "把 x = √2 − 1 代進餘式 x + 3。", "f(√2 − 1) = √2 + [0]", ["2"],
					"f(√2 − 1) = (√2 − 1) + 3 = √2 + 2", "√2 − 1 + 3。", T_EVAL),
			 ]},
			{"eq": "x = √3 + 1，求 x^{3} − x^{2} − 3x + 5 的值",
			 "steps": [
				_f("① 找方程式", "x − 1 = √3，兩邊平方。", "x^{2} − [0]x − [1] = 0", ["2", "2"],
					"(x − 1)^{2} = 3 ⇒ x^{2} − 2x − 2 = 0", "x^{2} − 2x + 1 = 3。", T_EVAL),
				_long([1, -1, -3, 5], [1, -2, -2], "② 商式 x + 1，餘式 x + 7", true, "② 長除法"),
				_f("③ 代入餘式", "把 x = √3 + 1 代進餘式 x + 7。", "f(√3 + 1) = √3 + [0]", ["8"],
					"f(√3 + 1) = √3 + 1 + 7 = √3 + 8", "√3 + 1 + 7。", T_EVAL),
			 ]},
		 ]},

		{"id": "shift", "chapter": 2, "type": "forge", "title": "綜合除法的連續使用",
		 "story": "一直除以 x − 2，每次的餘式由下往上，就是 x − 2 的多項式的係數。",
		 "insight": "f(x) = a(x − k)^{3} + b(x − k)^{2} + c(x − k) + d：連續用 x − k 做綜合除法，餘式依序是 d、c、b，最後剩 a。",
		 "variants": [
			{"eq": "x^{3} − 6x^{2} + 11x − 4 = a(x − 2)^{3} + b(x − 2)^{2} + c(x − 2) + d 恆成立",
			 "steps": [
				_synth([1, -6, 11, -4], [2, 1], "第一次：餘式 d = 2，商 x^{2} − 4x + 3", "第一次", {"base": [1, -6, 11, -4], "chain": 0}),
				_synth([1, -4, 3], [2, 1], "第二次：商繼續除以 x − 2，餘式 c = −1", "第二次", {"base": [1, -6, 11, -4], "chain": 1}),
				_synth([1, -2], [2, 1], "第三次：餘式 b = 0，最後剩下 a = 1", "第三次", {"base": [1, -6, 11, -4], "chain": 2}),
				_f("寫出係數", "圈起來的數由下往上讀：最後剩下的是 a，再來是 b、c、d。", "a = [0]，b = [1]，c = [2]，d = [3]", ["1", "0", "-1", "2"],
					"x^{3} − 6x^{2} + 11x − 4 = (x − 2)^{3} − (x − 2) + 2", "d 是第一圈的餘式。", T_SHIFT),
			 ]},
			{"eq": "2x^{3} + 3x^{2} − x + 5 = a(x + 1)^{3} + b(x + 1)^{2} + c(x + 1) + d 恆成立",
			 "steps": [
				_c("寫哪個數", "用 (x + 1) 來寫，綜合除法右邊要寫哪個數？", ["−1", "1", "5", "2"], 0,
					"x + 1 = 0 ⇒ x = −1。", "讓 x + 1 = 0。", "連續除以 x + 1：右邊寫 −1", T_SHIFT),
				_synth([2, 3, -1, 5], [-1, 1], "第一次：餘式 d = 7，商 2x^{2} + x − 2", "第一次", {"base": [2, 3, -1, 5], "chain": 0}),
				_synth([2, 1, -2], [-1, 1], "第二次：商繼續除以 x + 1，餘式 c = −1", "第二次", {"base": [2, 3, -1, 5], "chain": 1}),
				_synth([2, -1], [-1, 1], "第三次：餘式 b = −3，最後剩下 a = 2", "第三次", {"base": [2, 3, -1, 5], "chain": 2}),
				_f("寫出係數", "圈起來的數由下往上讀：a、b、c、d。", "a = [0]，b = [1]，c = [2]，d = [3]", ["2", "-3", "-1", "7"],
					"2x^{3} + 3x^{2} − x + 5 = 2(x + 1)^{3} − 3(x + 1)^{2} − (x + 1) + 7", "d 是第一圈的餘式。", T_SHIFT),
			 ]},
		 ]},

		{"id": "rule2", "chapter": 2, "type": "forge", "title": "帳本的變形",
		 "story": "f(x) = (3x − 4)Q(x) + r。換個除式，商式和餘式怎麼變？",
		 "insight": "從 f(x) = (3x − 4)Q(x) + r 出發，把除式寫成題目要的樣子，商式就跟著調整。餘式的次數一定要比除式低。",
		 "variants": [
			{"eq": "f(x) 除以 3x − 4 的商式為 Q(x)，餘式為 r",
			 "steps": [
				_c("(A)", "f(x) 除以 x − \\frac{4}{3}：商式是 3Q(x)，餘式是 r。對嗎？", ["正確", "錯誤"], 0,
					"(3x − 4)Q(x) = (x − \\frac{4}{3})·3Q(x)，餘式 r 不變。", "3x − 4 = 3(x − \\frac{4}{3})。",
					"(A) 正確：f(x) = (x − \\frac{4}{3})·3Q(x) + r", T_RULE),
				_c("(B)", "f(x) 除以 2(3x − 4)：商式是 \\frac{Q(x)}{2}，餘式是 r。對嗎？", ["正確", "錯誤"], 0,
					"(3x − 4)Q(x) = 2(3x − 4)·\\frac{Q(x)}{2}，r 還是比除式低次。", "把 2 從商式借給除式。",
					"(B) 正確：f(x) = 2(3x − 4)·\\frac{Q(x)}{2} + r", T_RULE),
				_c("(C)", "x·f(x) 除以 3x − 4：商式是 xQ(x)，餘式是 r。對嗎？", ["錯誤", "正確"], 0,
					"x·f(x) = (3x − 4)·xQ(x) + rx，多出來的是 rx，不是 r\n而且 rx 是一次，還要再除下去。", "兩邊都乘以 x，r 也要乘。",
					"(C) 錯誤：x·f(x) = (3x − 4)·xQ(x) + rx", T_RULE),
				_c("(D)", "f(\\frac{x}{3}) 除以 x − 4：商式是 Q(\\frac{x}{3})，餘式是 r。對嗎？", ["正確", "錯誤"], 0,
					"把 x 換成 \\frac{x}{3}：3 · \\frac{x}{3} − 4 = x − 4。", "f(\\frac{x}{3}) = (3 · \\frac{x}{3} − 4)Q(\\frac{x}{3}) + r。",
					"(D) 正確：f(\\frac{x}{3}) = (x − 4)Q(\\frac{x}{3}) + r", T_RULE),
			 ]},
		 ]},
	]
