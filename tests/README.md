# 自動測試

每次 push 到 main，GitHub Actions 會自動跑一次（`.github/workflows/tests.yml`）。結果在 GitHub 的 Actions 分頁，失敗時會寄信通知。

| 測試 | 檢查什麼 |
|---|---|
| `test_load.gd` | `data/`、`levels/` 裡所有腳本都能載入（語法錯誤、preload 找不到檔案） |
| `test_save.gd` | 存了再讀回來一樣；舊版存檔能升級（並留備份）；型別壞掉的欄位改用預設值；刪除紀錄會全部清空 |
| `test_economy.gd` | 遊戲管家每一層都實際呼叫一次：音效、主線星塵、章節／黃金寶箱、終焉之塔、每日任務、扭蛋、簽到、存檔、換場景 |
| `test_banks.gd` | 每一關的題庫格式；每段旅程的每一種題型都能開始，推導題能一步一步走到最後、速算能答對算分 |
| `test_play.gd` | （不在預設清單，比較久）真的玩過每一段旅程：每一步用玩家的方式作答，檢查卡片、按鈕的字、作答框有沒有跑版，答對一定會進到下一步。`ONLY=P3 SHOTS=shots xvfb-run -a tests/run_tests.sh play` |
| `test_tower.gd` | （不在預設清單，比較久）真的爬一次終焉之塔（每個有塔的單元：指對數、多項式、三角函數）：先檢查題庫（選項不重複、填空格子對得上、數線段數、排版），再把每一題照正確答案作答（三顆星）、每一步先答錯一次（扣心、提示不擠出畫面）、心用完與時間到要示範完整解法，最後從第 1 層爬到塔頂（舊題型也真的玩），檢查樓層、帶心、試煉層、同一輪不重複、結算畫面。選擇、真假、驗根、數線、正負號、選圖、數字鍵盤都用學生的方式操作。`UNITS=h1poly`、`TMODE=items,wrong,lose,run`、`ONLY=pb_garden`、`ALLSHOTS=1` 每一步都截圖。`SHOTS=shots xvfb-run -a tests/run_tests.sh tower` |
| `test_concepts.gd` | 觀念卡片：每張卡片的空格、干擾積木、可互換的空格寫得對；真的拖一次積木；放錯不扣東西；填完＋小測答對給星塵、只給一次；解題流程要照順序 |
| `test_scenes.gd` | 主畫面、高一／高二世界地圖、兩張單元地圖、小屋、修煉之間都能打開 |

## 在自己電腦跑

```bash
GODOT=/path/to/Godot tests/run_tests.sh              # 全部（不開畫面）
GODOT=/path/to/Godot tests/run_tests.sh banks        # 只跑題庫
ONLY=L3,G7 GODOT=/path/to/Godot tests/run_tests.sh banks   # 只測某幾關
SHOTS=shots GODOT=/path/to/Godot tests/run_tests.sh scenes  # 有畫面，截圖存到 shots/
```

Windows 可以用 Git Bash 執行，或直接：`Godot.exe --headless --path . -s tests/test_banks.gd`。

## 新增測試

新增 `tests/test_xxx.gd`（`extends "test_base.gd"`），用 `ok(條件, "說明")` 做檢查，最後呼叫 `finish("XXX")`，再把 `xxx` 加進 `run_tests.sh` 的預設清單。

`tests/` 不會被匯出到遊戲裡（export_presets 已排除）。

## 腳本放在哪裡

```
data/
  core/           遊戲管家（game*.gd）、單元設定 units.gd、修煉中心、通知、paths.gd
  ui/             主畫面、各種面板、主題、數學排版、新手教學、計算紙、光靈外觀
  maps/           單元地圖（exp_map、trig_map、共用底層）、大地圖（g10、g11、共用底層）、劇情
  levels/engine/  關卡共用引擎（level_base、光橋舞台、推導題 step_level、寶箱）
  levels/exp/     指數與對數 L1～L8 的關卡、題庫、觀念卡
  levels/trig/    三角函數 G1～G7 的關卡、題庫、觀念卡
  levels/tower/   終焉之塔
  house/          光靈小屋、家具、紀念品
```

- 腳本之間一律用完整路徑：`preload("res://data/ui/game_theme.gd")`。
- 用檔名字串的地方（換場景 `goto("main_menu.gd")`、`units.gd` 的 file／bank／map）透過 `data/core/paths.gd` 找到位置；**檔名要唯一**。
- 新增或搬動腳本之後執行 `python3 tools/gen_paths.py` 更新 `paths.gd`。忘了的話，`test_load` 會提醒。
