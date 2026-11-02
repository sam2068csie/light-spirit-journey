#!/usr/bin/env python3
"""重新產生 data/core/paths.gd（檔名 → 完整路徑）。搬檔案或新增腳本之後執行：python3 tools/gen_paths.py"""
import os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
found = {}
for d, _, fs in os.walk(os.path.join(ROOT, "data")):
    for f in fs:
        if f.endswith(".gd"):
            rel = os.path.relpath(os.path.join(d, f), ROOT).replace(os.sep, "/")
            if f in found:
                raise SystemExit("檔名重複：%s 和 %s（檔名要唯一，Paths.of 才找得到）" % (found[f], rel))
            found[f] = "res://" + rel
p = os.path.join(ROOT, "data", "core", "paths.gd")
src = open(p, encoding="utf-8").read()
a = src.index("const MAP := {")
b = src.index("}\n", a) + 2
body = "const MAP := {\n" + "".join('\t"%s": "%s",\n' % (k, found[k]) for k in sorted(found)) + "}\n"
open(p, "w", encoding="utf-8").write(src[:a] + body + src[b:])
print("paths.gd：%d 個腳本" % len(found))
