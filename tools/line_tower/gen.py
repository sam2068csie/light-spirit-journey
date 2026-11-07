# 產生 data/levels/tower/line_tower_data.gd：python3 tools/line_tower/gen.py
#   每一題是一個模板函式，items() 傳回 [[第 1 組, 第 2 組, 第 3 組], ...]。
#   第 1 組是題目本身，其他組放進 "vars"（只放跟第 1 組不一樣的欄位）。
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import t_judge, t_line, t_dist, t_circle, t_tangent, t_quest, t_boss

MODS = [t_judge, t_line, t_dist, t_circle, t_tangent, t_quest, t_boss]
FIXED = ["id", "kind", "tier", "title", "tmul"]
VARY = ["stem", "plot", "steps"]


def build():
    out = []
    for m in MODS:
        for group in m.items():
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
          "## 自動產生，不要手改：python3 tools/line_tower/gen.py\n"
          "##   題目模板和每一組數字在 tools/line_tower/t_*.py，答案都由程式算、assert 驗算過。\n"
          "##   每一題的 vars 是另外幾組數字（蓋過 stem、plot、steps），塔每一輪會先出沒看過的那組。\n\n"
          "static func data() -> Array:\n\treturn " + txt.replace("\n", "\n\t") + "\n")
    open(os.path.join(root, "data/levels/tower/line_tower_data.gd"), "w", encoding="utf-8").write(gd)
    n = sum(1 + len(d["vars"]) for d in data)
    print("題目 %d 題，共 %d 組數字（試煉大題 %d 題）" % (len(data), n, sum(1 for d in data if d["kind"] == "boss")))
