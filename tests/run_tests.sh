#!/usr/bin/env bash
# 跑全部測試。用法：
#   GODOT=/path/to/godot tests/run_tests.sh            （headless，CI 用）
#   SHOTS=/tmp/shots xvfb-run -a tests/run_tests.sh     （有畫面，存截圖）
#   ONLY=L3 tests/run_tests.sh banks                    （只跑題庫測試、只測 L3）
#   tests/run_tests.sh markup                         （排版檢查：根號、分數、上標有沒有寫對）
#   tests/run_tests.sh answers                        （「其實也對」的答案要算對：正負號、成比例、點斜式用別的點…）
#   ONLY=P3 SHOTS=/tmp/s xvfb-run -a tests/run_tests.sh play  （真的玩一次，檢查每一步的版面）
#   SHOTS=/tmp/s xvfb-run -a tests/run_tests.sh perf   （效能：各畫面 draw calls 不可超過預算）
#   SHOTS=/tmp/s xvfb-run -a tests/run_tests.sh tower  （真的爬一次終焉之塔：每一題、答錯、心用完、爬到塔頂）
#   SHOTS=/tmp/s xvfb-run -a tests/run_tests.sh shots  （美術檢查：每一關的背景、大地圖各地區 0%／50%／100% 的亮度，只存截圖）
#   ONLY=C2 SHOTS=/tmp/s xvfb-run -a tests/run_tests.sh real  （真的玩一關：從大地圖點進去，所有操作都是滑鼠點擊，每題先答錯一次，每個畫面截圖）
#   tests/run_tests.sh gen                            （終焉之塔的 *_data.gd 要和 tools/towerlib/gen.py 產生的一模一樣：不能直接手改 .gd）
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
if [ -n "${SHOTS:-}" ]; then MODE=(--rendering-driver opengl3); else MODE=(--headless); fi
WHICH="${1:-gen load save economy banks scenes markup concepts world guards goal answers}"
status=0
# 第一次在乾淨的環境跑：先匯入資源（字型、圖片），否則 load 會失敗
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
for t in $WHICH; do
  echo "=== test_$t ==="
  if [ "$t" = gen ]; then
    # 這一項不用 Godot：重跑四座塔的產生器（只比對、不寫檔）
    PY="${PYTHON:-python3}"
    if ! command -v "$PY" >/dev/null 2>&1 || ! "$PY" -c "import numpy" >/dev/null 2>&1; then
      echo "（跳過：需要 python3 和 numpy）"
      continue
    fi
    if ! "$PY" tools/towerlib/gen.py --check; then
      echo ">>> test_gen 失敗"
      status=1
    fi
    continue
  fi
  out=$("$GODOT" "${MODE[@]}" --path . -s "tests/test_$t.gd" 2>&1)
  code=$?
  echo "$out" | grep -E "FAIL:|✗|SCRIPT ERROR|Parse Error|DONE|：.*種題型|at: res://|^MARKUP " | head -200
  if [ $code -ne 0 ] || echo "$out" | grep -q "SCRIPT ERROR\|Parse Error"; then
    echo ">>> test_$t 失敗"
    status=1
  elif ! echo "$out" | grep -q "DONE"; then
    echo ">>> test_$t 沒有跑完"
    status=1
  fi
done
exit $status
