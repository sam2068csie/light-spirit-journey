extends "level_base.gd"
## 第一大關「光之橋」（講義 2-1 重點一：指數函數之圖形與性質）
## 題庫在 level01_bank.gd；遊戲流程、各種旅程的操作都在 level_base.gd（共用引擎）。

const Bank := preload("level01_bank.gd")

const CHAPTERS := [
	{"ch": 1, "name": "第一章．指數之光", "topic": "圖形、平移、象限與交點", "color": UITheme.CYAN},
	{"ch": 2, "name": "第二章．鏡之谷", "topic": "絕對值：對稱與翻折", "color": UITheme.PINK},
]


func level_id() -> String:
	return "L1"

func level_title() -> String:
	return "光之橋"

func level_subtitle() -> String:
	return "指數函數 y = a^{x} 的圖形與性質"

func level_chapters() -> Array:
	return CHAPTERS

func bank_slots() -> Array:
	return Bank.slots()

## 舞台外觀：極光
func stage_style() -> Dictionary:
	return {"ambient": "aurora"}

## 進入第二章時跳出的說明卡
func chapter_card() -> Dictionary:
	return {"title": "第二章．鏡之谷", "button": "進入鏡之谷  ▶",
		"text": "絕對值會讓光橋「照鏡子」：\n\n" \
			+ "・y = a^{|x|}　右半邊對 y 軸翻過去\n" \
			+ "・|y| = a^{x}　上半部對 x 軸翻下來\n" \
			+ "・y = |a^{x} + k|　x 軸下方翻到上方\n\n" \
			+ "就看絕對值包住了誰！"}
