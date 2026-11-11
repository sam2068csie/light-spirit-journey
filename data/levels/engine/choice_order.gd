extends RefCounted
## 是非題的選項位置固定：「對、是、成立……」永遠在左邊（第一個），「錯、不是、不成立……」永遠在右邊。
## 其他選擇題照樣打亂；只有兩個選項剛好是一對肯定／否定時才固定。
##   選項可以帶說明，例如「成立（0 > −1）」「不在，所以 r = 1」：只看開頭那個詞。

## 肯定在前、否定在後
const PAIRS := [
	["對", "錯"], ["正確", "錯誤"], ["○", "✕"], ["真", "假"],
	["是", "不是"], ["是", "否"], ["成立", "不成立"], ["符合", "不符合"], ["合", "不合"],
	["在", "不在"], ["能", "不能"], ["會", "不會"], ["可以", "不可以"], ["有", "沒有"], ["有解", "無解"],
]
## 開頭的詞後面可以接這些（或是整個選項就是那個詞）
const AFTER := ["，", "（", "(", "：", ":", " ", "、"]


static func _starts(opt: String, word: String) -> bool:
	if opt == word:
		return true
	if not opt.begins_with(word):
		return false
	return opt.substr(word.length(), 1) in AFTER


## 兩個選項是一對肯定／否定：回傳 [肯定的索引, 否定的索引]；不是的話回傳 []
static func yes_no(options: Array) -> Array:
	if options.size() != 2:
		return []
	var a := String(options[0]).strip_edges()
	var b := String(options[1]).strip_edges()
	for p in PAIRS:
		if _starts(a, p[0]) and _starts(b, p[1]):
			return [0, 1]
		if _starts(b, p[0]) and _starts(a, p[1]):
			return [1, 0]
	return []


## 選項要排成的順序（原本的索引）：是非題固定肯定在左，其他打亂
static func order(options: Array) -> Array:
	var yn := yes_no(options)
	if not yn.is_empty():
		return yn
	var idx := range(options.size())
	idx.shuffle()
	return idx
