#!/usr/bin/env bash
# 跑全部測試。用法：
#   GODOT=/path/to/godot tests/run_tests.sh            （headless，CI 用）
#   SHOTS=/tmp/shots xvfb-run -a tests/run_tests.sh     （有畫面，存截圖）
#   ONLY=L3 tests/run_tests.sh banks                    （只跑題庫測試、只測 L3）
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
if [ -n "${SHOTS:-}" ]; then MODE=(--rendering-driver opengl3); else MODE=(--headless); fi
WHICH="${1:-load banks scenes}"
status=0
# 第一次在乾淨的環境跑：先匯入資源（字型、圖片），否則 load 會失敗
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
for t in $WHICH; do
  echo "=== test_$t ==="
  out=$("$GODOT" "${MODE[@]}" --path . -s "tests/test_$t.gd" 2>&1)
  code=$?
  echo "$out" | grep -E "FAIL:|SCRIPT ERROR|Parse Error|DONE|：.*種題型|at: res://" | head -200
  if [ $code -ne 0 ] || echo "$out" | grep -q "SCRIPT ERROR\|Parse Error"; then
    echo ">>> test_$t 失敗"
    status=1
  elif ! echo "$out" | grep -q "DONE"; then
    echo ">>> test_$t 沒有跑完"
    status=1
  fi
done
exit $status
