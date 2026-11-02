# 自動測試

每次 push 到 main，GitHub Actions 會自動跑一次（`.github/workflows/tests.yml`）。結果在 GitHub 的 Actions 分頁，失敗時會寄信通知。

| 測試 | 檢查什麼 |
|---|---|
| `test_load.gd` | `data/`、`levels/` 裡所有腳本都能載入（語法錯誤、preload 找不到檔案） |
| `test_save.gd` | 存了再讀回來一樣；舊版存檔能升級（並留備份）；型別壞掉的欄位改用預設值；刪除紀錄會全部清空 |
| `test_banks.gd` | 每一關的題庫格式；每段旅程的每一種題型都能開始，推導題能一步一步走到最後、速算能答對算分 |
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
