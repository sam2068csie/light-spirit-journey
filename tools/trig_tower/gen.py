# 產生 data/levels/tower/trig_tower_data.gd：python3 tools/trig_tower/gen.py
#   每一題是一個模板函式，items() 傳回 [[第 1 組, 第 2 組, 第 3 組], ...]。
#   第 1 組是題目本身，其他組放進 "vars"（只放跟第 1 組不一樣的欄位）。
import json, os, sys, importlib
sys.path.insert(0, os.path.dirname(__file__))

NAMES = ["t_judge", "t_graph", "t_cross", "t_angle", "t_extreme", "t_quest", "t_boss", "t_boss2"]
FIXED = ["id", "kind", "tier", "title", "tmul"]
VARY = ["stem", "plot", "steps", "routes"]


def mods(only=None):
    out = []
    for n in NAMES:
        if only and n not in only:
            continue
        try:
            out.append(importlib.import_module(n))
        except ModuleNotFoundError as e:
            if e.name != n:
                raise
    return out


import re
_NEG = re.compile(r"(?<![A-Za-z0-9_])-(?=[0-9])")


def fix(v, key=""):
    """題目文字裡的負號一律用 −；畫圖的式子 f 裡的 PI 換成數字（Godot 的 Expression 不認得 PI）"""
    if isinstance(v, dict):
        return {k: fix(x, k) for k, x in v.items()}
    if isinstance(v, list):
        return [fix(x, key) for x in v]
    if isinstance(v, str) and key != "f":
        return _NEG.sub("−", v)
    if isinstance(v, str):
        return v.replace("PI", "3.141592653589793").replace("+-", "-").replace("--", "+")
    return v


def build(only=None):
    out = []
    for m in mods(only):
        for group in m.items():
            group = [fix(g) for g in group]
            base = dict(group[0])
            for g in group[1:]:
                for k in FIXED:
                    assert g[k] == base[k], (base["id"], k)
            base["vars"] = [{k: g[k] for k in VARY if k in g} for g in group[1:]]
            out.append(base)
    return out


if __name__ == "__main__":
    data = build()
    root = os.path.join(os.path.dirname(__file__), "..", "..")
    if len(sys.argv) > 1 and sys.argv[1] == "--json":
        json.dump(data, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        sys.exit(0)
    txt = json.dumps(data, ensure_ascii=False, indent="\t")
    gd = ("extends RefCounted\n"
          "## 自動產生，不要手改：python3 tools/trig_tower/gen.py\n"
          "##   題目模板和每一組數字在 tools/trig_tower/t_*.py，答案都由程式算、assert 驗算過。\n"
          "##   每一題的 vars 是另外幾組數字（蓋過 stem、plot、steps），塔每一輪會先出沒看過的那組。\n\n"
          "static func data() -> Array:\n\treturn " + txt.replace("\n", "\n\t") + "\n")
    open(os.path.join(root, "data/levels/tower/trig_tower_data.gd"), "w", encoding="utf-8").write(gd)
    n = sum(1 + len(d["vars"]) for d in data)
    print("題目 %d 題，共 %d 組數字（試煉大題 %d 題）" % (len(data), n, sum(1 for d in data if d["kind"] == "boss")))
