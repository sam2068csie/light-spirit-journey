extends RefCounted
## 「打開遊戲之後先跳出什麼」的順序，全部寫在這裡。
## 每個畫面只問「現在輪到哪一步」，自己負責把那一步顯示出來；要加一步、換順序，只改這個檔案。
##
## 主畫面（main_menu.gd），一次只跳一個：
##   1. grade   第一次打開：選身分（高一／高二）。選完接著選段考範圍，再直接進那個年級的大地圖
##   2. signin  今天第一次打開：連續簽到
##   3. notify  玩過一段之後回到主畫面：問要不要讓光靈提醒（手機版、只問一次）
##
## 大地圖（world_base.gd），一步做完再問下一步：
##   1. prologue  第一次打開這張地圖：序章＋操作教學（教學在跑，這一趟就到這裡）
##   2. souvenir  點亮一個單元之後：紀念品小劇情（可能連續好幾段）
##   3. exam      這學期還沒選過段考範圍（換學期了、或是舊存檔）
const WS := preload("res://data/maps/world_story.gd")

const MENU_STEPS := ["grade", "signin", "notify"]
const MAP_STEPS := ["prologue", "souvenir", "exam"]


## 主畫面現在該跳哪一個（"" = 都不用）。args = 這次進主畫面帶的參數
## 注意：判斷 signin 會順便記下「今天彈過了」，所以每次進主畫面只問一次
static func menu_step(g, args: Dictionary) -> String:
	var page := String(args.get("page", "title"))
	if g.grade_pick == "" and page == "title" and g.stars.is_empty() and g.cleared.is_empty():
		return "grade"
	# 剛結算完（攀登結果、修煉總結）先讓他看結果，不疊簽到
	if not args.has("tower_result") and not args.has("summary") and g.streak_should_popup():
		return "signin"
	if not g.notify_asked and g.notifier.available() and not g.stars.is_empty():
		return "notify"
	return ""


## 大地圖現在該做哪一步（"" = 都不用）。world_key = "g10"／"g11"，grade = 這張地圖的年級
static func map_step(g, world_key: String, grade: String) -> String:
	if not WS.seen(g, world_key):
		return "prologue"
	if WS.pending_souvenir(g, grade) != "":
		return "souvenir"
	if WS.needs_exam_pick(g, WS.my_grade(g, grade)):
		return "exam"
	return ""
