extends RefCounted
## 世代號碼：判斷 await 回來時，畫面是不是已經換了（換題、換步驟、換頁）
##
## 用法（全專案統一這一種寫法）：
##   var round_gen := Gen.new()
##   round_gen.bump()                         # 換題／換步驟／換頁的地方呼叫
##   var g := round_gen.now()                 # await 之前先記下來
##   await get_tree().create_timer(0.7).timeout
##   if round_gen.stale(g): return            # 已經換了：這段動畫或提示作廢

var _n := 0


func bump() -> int:
	_n += 1
	return _n


func now() -> int:
	return _n


func stale(g: int) -> bool:
	return g != _n
