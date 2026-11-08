# 新題目的第 1 組數字和目前題庫比對（只印不一樣的地方），改寫手寫題庫成模板時用：
#   python3 tools/towerlib/compare.py trig /tmp/舊題庫.json [t_judge,t_boss]
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen as G


def walk(a, b, path):
    if isinstance(a, dict) and isinstance(b, dict):
        for k in sorted(set(a) | set(b)):
            if k == "vars":
                continue
            if k not in a or k not in b:
                print("  %s.%s 只在%s" % (path, k, "新" if k in a else "舊"))
                continue
            walk(a[k], b[k], path + "." + k)
    elif isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            print("  %s 長度 %d vs %d" % (path, len(a), len(b)))
        for i, (x, y) in enumerate(zip(a, b)):
            walk(x, y, "%s[%d]" % (path, i))
    elif isinstance(a, (int, float)) and isinstance(b, (int, float)) and not isinstance(a, bool):
        if abs(a - b) > 0.02:
            print("  %s：%s vs %s" % (path, a, b))
    elif a != b:
        print("  %s\n    新：%s\n    舊：%s" % (path, a, b))


if __name__ == "__main__":
    tower = sys.argv[1]
    cur = {d["id"]: d for d in json.load(open(sys.argv[2], encoding="utf-8"))}
    only = sys.argv[3].split(",") if len(sys.argv) > 3 else None
    G.setup(tower)
    for m in G.mods(tower, only):
        for g in m.items():
            d = G.fix(g[0])
            print("==", d["id"])
            if d["id"] in cur:
                walk(d, cur[d["id"]], d["id"])
            else:
                print("  （新題）")
