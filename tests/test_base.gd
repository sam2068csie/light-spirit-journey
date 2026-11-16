extends SceneTree
## 測試共用的小工具（每個測試腳本都 extends 這個檔案）
##   ・ok(條件, 說明)：記錄一個檢查；失敗會印出 "FAIL: …"
##   ・finish()：印出結果並結束（有失敗時結束碼是 1，CI 會變紅）
##   ・shot(名字)：有設定環境變數 SHOTS（資料夾）時存一張截圖；headless 模式不截圖

var fails := 0
var checks := 0
var g      # Game


func wait(s: float) -> void:
	await create_timer(s).timeout


func frames(n: int = 2) -> void:
	for i in n:
		await process_frame


func ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL: ", what)


func shot(name: String) -> void:
	var dir := OS.get_environment("SHOTS")
	if dir == "" or DisplayServer.get_name() == "headless":
		return
	await wait(0.4)
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_texture().get_image().save_png(dir + "/" + name + ".png")


## 建立 Game（存檔放在 user://，CI 每次都是全新的）；把新手教學都標成看過，免得跳出來擋住
func setup() -> void:
	var helper := Node.new()
	root.add_child.call_deferred(helper)
	await process_frame
	g = load("res://data/core/game.gd").of(helper)
	g.notify_asked = true
	g.grade_pick = "高二"
	var seen := {"basic": true, "tower": true}
	for k in ["fit", "draw", "cross", "table", "rank", "quadrant", "count", "chord", "forge", "speed", "tune"]:
		seen["type:" + k] = true
	g.tut = seen
	g.story_seen = ["world/g10", "world/g11"]
	# 今天的連續簽到視窗當作已經跳過（全新的存檔會自動跳出來，蓋住主畫面、量效能也會多算）
	g.streak["popup"] = load("res://data/core/daily_quests.gd").day_key()
	# 這學期的段考範圍當作已經選過（還不確定＝照課本順序），大地圖才不會一打開就跳「這次段考考什麼？」
	var U = load("res://data/core/units.gd")
	g.exam_pick = {"高一": {"term": U.term_now("高一"), "units": []}, "高二": {"term": U.term_now("高二"), "units": []}}
	await wait(0.3)


func finish(label: String) -> void:
	print("%s DONE checks=%d fails=%d" % [label, checks, fails])
	quit(1 if fails > 0 else 0)


## 排版檢查（design_rules 1.9）：畫面上所有會記錄 ink 的圖（數與式的原野、座標平面），
## 根號、分數、標籤有沒有超出框、和別的字或圖形疊在一起。回傳問題的說明（同一個問題只回報一次）
## 動畫進行中（燈條滑進來、數線縮放）一時疊到不算：有問題時等 1.5 秒再看一次，還在才算
var _ink_seen := {}

func ink_scan(root_n: Node) -> Array:
	var first := _ink_collect(root_n)
	if first.is_empty():
		return []
	await wait(1.5)
	var out := []
	for msg in _ink_collect(root_n):
		if not _ink_seen.has(msg):
			_ink_seen[msg] = true
			out.append("排版：" + String(msg))
	return out


func _ink_collect(root_n: Node) -> Array:
	var out := []
	if root_n == null:
		return out
	var stack: Array = [root_n]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
			continue
		if n.has_method("ink_issues"):
			out.append_array(n.ink_issues())
		for c in n.get_children():
			stack.append(c)
	return out
