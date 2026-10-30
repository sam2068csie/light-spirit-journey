extends "level_01_light_bridge.gd"
## 第五大關「鏡像之塔」（對應講義 重點二：對數函數之圖形與性質）
## 用法：根節點選 Control，掛上這個腳本（主選單會自動開啟它）。
## 需要同資料夾的 level_01_light_bridge.gd（共用的遊戲引擎）與 level05_bank.gd（題庫）。
##
## 第一章．鏡中之光：對數圖形、底數、鉛直漸近線、平移、真數拆解、對 y = x 的鏡像、
##                   指數與對數的交點（a > 1 時交點都在鏡子上）
## 第二章．交點之鏡：log|x|、|log x| 的對稱與翻折、交點個數（調頻、列表、徒手畫圖數交點）

const Bank5 := preload("level05_bank.gd")

const CHAPTERS5 := [
	{"ch": 1, "name": "第一章．鏡中之光", "topic": "對數圖形、平移與 y = x 對稱", "color": UITheme.PINK},
	{"ch": 2, "name": "第二章．交點之鏡", "topic": "絕對值與交點個數", "color": UITheme.VIOLET},
]


func level_id() -> String:
	return "L5"

func level_title() -> String:
	return "鏡像之塔"

func level_subtitle() -> String:
	return "對數函數 y = log_{a} x 的圖形與性質"

func level_chapters() -> Array:
	return CHAPTERS5

func bank_slots() -> Array:
	return Bank5.slots()

func stage_style() -> Dictionary:
	return {"sky_top": Color("26113f"), "sky_bot": Color("0d2035"), "scenery": "lake"}

func chapter_card() -> Dictionary:
	return {"title": "第二章．交點之鏡", "button": "進入交點之鏡  ▶",
		"text": "這一章要數交點：\n\n" \
			+ "・y = log_{a}|x|　左右對稱，中間是鉛直雷射牆\n" \
			+ "・y = |log_{a} x|　x 軸下方翻到上方\n" \
			+ "・一增一減的兩條線，最多只交一次\n" \
			+ "・算不出來？列表比大小！\n\n" \
			+ "解方程式 ⇔ 數兩個圖形的交點。"}
