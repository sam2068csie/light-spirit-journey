# 第 1 組數字和目前的題庫比對（只印不一樣的地方）
import json, sys, os
sys.path.insert(0, os.path.dirname(__file__))
import gen
cur = {d["id"]: d for d in json.load(open(sys.argv[1], encoding="utf-8"))}
mods = sys.argv[2].split(",") if len(sys.argv) > 2 else None
def walk(a, b, path):
    if isinstance(a, dict) and isinstance(b, dict):
        for k in sorted(set(a) | set(b)):
            if k == "vars": continue
            if k not in a or k not in b:
                print("  %s.%s 只在%s" % (path, k, "新" if k in a else "舊")); continue
            walk(a[k], b[k], path + "." + k)
    elif isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            print("  %s 長度 %d vs %d" % (path, len(a), len(b)))
        for i, (x, y) in enumerate(zip(a, b)): walk(x, y, "%s[%d]" % (path, i))
    elif isinstance(a, (int, float)) and isinstance(b, (int, float)) and not isinstance(a, bool):
        if abs(a - b) > 0.02: print("  %s：%s vs %s" % (path, a, b))
    elif a != b:
        print("  %s\n    新：%s\n    舊：%s" % (path, a, b))
for m in gen.MODS:
    if mods and m.__name__ not in mods: continue
    for g in m.items():
        d = g[0]
        print("==", d["id"])
        if d["id"] in cur: walk(d, cur[d["id"]], d["id"])
        else: print("  （新題）")
