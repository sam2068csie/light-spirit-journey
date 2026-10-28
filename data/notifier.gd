extends Node
## 提醒通知：學生好幾天沒來，光靈會傳訊息「想念」他（手機上的本機通知，不需要網路）
##
## 運作方式：
##   每次離開遊戲（切到背景、關掉）就把之前排好的提醒全部取消，重新排：
##   1、2、3、5、7、14 天後的同一個時間（預設晚上 7:30）各一則。
##   只要學生在那之前回來玩，這些提醒就會被取消、重排，所以天天來玩的人不會收到。
##
## 需要 Android 通知外掛 NotificationScheduler 5.2（addons/NotificationSchedulerPlugin，已附在交付的壓縮檔裡），
## 而且要用 Gradle 建置匯出。手機上沒有這個外掛（例如電腦版）時，這個檔案什麼都不做，也不會出錯。
##
## 外掛的類別名稱（NotificationScheduler、NotificationData、NotificationChannel）都用名稱動態載入，
## 所以沒裝外掛時這個檔案也能正常編譯。

const CHANNEL_ID := "spirit_reminder"
const ICON := "ic_spirit"              # assets/NotificationSchedulerPlugin/drawable-*/ic_spirit.png（匯出時外掛會複製進 APK）
const SINGLETON := "NotificationSchedulerPlugin"   # 外掛在 Android 上提供的原生物件
const IDS := [101, 102, 103, 105, 107, 114]     # 第 1、2、3、5、7、14 天
const DAYS := [1, 2, 3, 5, 7, 14]
const TIMES := ["17:30", "19:30", "21:00"]

## 每一天的訊息（隨機挑一則）。{n} = 連續簽到天數、{d} = 幾天沒來
const MSGS := {
	1: [
		["光靈在等你 ✦", "今天的每日任務準備好了，光靈已經把星塵擦得亮晶晶～"],
		["今天也來一下吧！", "只要 5 分鐘，答對 3 題就能領星塵。光靈幫你留了位子。"],
		["光靈戳戳你", "昨天的你很棒，今天的你也可以！"],
	],
	2: [
		["兩天沒見了……", "光靈一直坐在光之橋上，等你回來一起算數學。"],
		["光靈有點想你", "已經兩天了。今天回來，簽到的火苗還來得及救！"],
	],
	3: [
		["光靈會寂寞的……", "你已經三天沒有進來算數學了，光靈會寂寞的……"],
		["三天了。", "光靈把你的錯題本翻了三遍，還是等不到你。"],
	],
	5: [
		["光靈在數星星", "數到第五天了。每一顆星星，都是在等你的一天。"],
		["光靈有話想說", "題目們都很想你。光靈……也是。"],
	],
	7: [
		["一個禮拜了", "光靈還留著你的位置。段考可不會等人喔。"],
		["光靈寫了一封信", "親愛的冒險者：已經七天了。回來看看我好嗎？——光靈"],
	],
	14: [
		["光靈決定不哭了", "它只是……每天都會看一下門口而已。"],
		["好久不見", "兩個禮拜了。光靈還是相信你會回來的 ✦"],
	],
}

var _sched: Node = null       # 外掛的 NotificationScheduler 節點
var _ready_ok := false


func _ready() -> void:
	# 只有手機上、外掛真的有裝進 APK 時才啟動（電腦版直接略過，不會一直跳錯誤訊息）
	if not Engine.has_singleton(SINGLETON):
		return
	_sched = _make("NotificationScheduler")
	if _sched == null:
		return
	add_child(_sched)
	_connect_signal("initialization_completed", _on_init)
	_connect_signal("post_notifications_permission_granted", _on_granted)
	if _sched.has_method("initialize"):
		_sched.initialize()
	else:
		_on_init()


func _on_init(_a = null) -> void:
	_ready_ok = true
	_init_channel()
	reschedule()


## 外掛有沒有裝好（手機版才會有）
func available() -> bool:
	return _sched != null


func has_permission() -> bool:
	if not _ready_ok:
		return false
	if _sched.has_method("has_post_notifications_permission"):
		return bool(_sched.has_post_notifications_permission())
	return true


func request_permission() -> void:
	if _sched != null and _sched.has_method("request_post_notifications_permission"):
		_sched.request_post_notifications_permission()


func _init_channel() -> void:
	var ch = _make("NotificationChannel")
	if ch == null or not _sched.has_method("create_notification_channel"):
		return
	_call(ch, "set_id", CHANNEL_ID)
	_call(ch, "set_name", "光靈的提醒")
	_call(ch, "set_description", "好幾天沒來時，光靈會提醒你回來練習")
	_call(ch, "set_importance", 3)      # DEFAULT
	_sched.create_notification_channel(ch)


## 取消舊的提醒、照設定重新排（離開遊戲時呼叫；沒裝外掛或關掉提醒時只會取消）
func reschedule() -> void:
	if not _ready_ok:
		return
	for id in IDS:
		if _sched.has_method("cancel"):
			_sched.cancel(id)
	var g = get_parent()
	if g == null or not bool(g.notify_on) or not has_permission():
		return
	var hm: PackedStringArray = String(g.notify_time).split(":")
	var hh := int(hm[0])
	var mm := int(hm[1]) if hm.size() > 1 else 0
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var now := int(Time.get_unix_time_from_system())
	var local := now + bias
	var today0 := local - posmod(local, 86400)          # 今天 0 點（本地時間）
	for i in DAYS.size():
		var d: int = DAYS[i]
		var when := today0 + d * 86400 + hh * 3600 + mm * 60
		var delay := when - local
		if delay < 3600 * 6:
			continue      # 太近了（例如半夜才玩完）：這一則不排
		var msg := pick_message(d, int(g.streak.get("count", 0)))
		var nd = _make("NotificationData")
		if nd == null:
			return
		_call(nd, "set_id", int(IDS[i]))
		_call(nd, "set_channel_id", CHANNEL_ID)
		_call(nd, "set_title", msg[0])
		_call(nd, "set_content", msg[1])
		_call(nd, "set_small_icon_name", ICON)
		_call(nd, "set_delay", delay)
		_sched.schedule(nd)


## 測試用：10 秒後跳一則（設定的開發者功能裡有按鈕）。回傳有沒有排成功
func test_now() -> bool:
	if not _ready_ok:
		return false
	var msg := pick_message(3, 0)
	var nd = _make("NotificationData")
	if nd == null:
		return false
	_call(nd, "set_id", 199)
	_call(nd, "set_channel_id", CHANNEL_ID)
	_call(nd, "set_title", msg[0])
	_call(nd, "set_content", msg[1])
	_call(nd, "set_small_icon_name", ICON)
	_call(nd, "set_delay", 10)
	_sched.schedule(nd)
	return true


## 挑一則訊息：[標題, 內容]（測試和設定頁的「預覽」也用它）
static func pick_message(d: int, streak_n: int) -> Array:
	if d == 1 and streak_n >= 2:
		return ["連續 %d 天的火苗！" % streak_n, "今天簽到，連續紀錄才不會斷掉。光靈幫你顧著火～"]
	var pool: Array = MSGS.get(d, MSGS[3])
	var m: Array = pool[randi() % pool.size()]
	return [String(m[0]).replace("{d}", str(d)), String(m[1]).replace("{d}", str(d)).replace("{n}", str(streak_n))]


# ---------- 用名稱建立外掛的類別（沒裝外掛時回傳 null） ----------

static func _make(cls: String):
	for info in ProjectSettings.get_global_class_list():
		if String(info.get("class", "")) == cls:
			var scr = load(String(info.path))
			if scr != null and scr.can_instantiate():
				return scr.new()
	if ClassDB.class_exists(cls) and ClassDB.can_instantiate(cls):
		return ClassDB.instantiate(cls)
	return null


static func _call(obj, method: String, arg) -> void:
	if obj != null and obj.has_method(method):
		obj.call(method, arg)


func _on_granted(_a = null) -> void:
	reschedule()


func _connect_signal(sig: String, cb: Callable) -> void:
	if _sched != null and _sched.has_signal(sig):
		_sched.connect(sig, cb)
