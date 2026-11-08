# 產生終焉之塔的題庫：data/levels/tower/<塔>_tower_data.gd
#
#   python3 tools/towerlib/gen.py              四座塔全部重新產生
#   python3 tools/towerlib/gen.py trig         只產生一座（line、poly、trig、explog）
#   python3 tools/towerlib/gen.py --check      不寫檔，只檢查 repo 裡的 *_data.gd 和產生器一致（測試用）
#   python3 tools/towerlib/gen.py trig --json /tmp/trig.json   輸出 JSON（比對、除錯用）
#
#   每一座塔的題目模板在 tools/<塔>_tower/t_*.py：每一題是一個模板函式，items() 傳回 [[第 1 組, 第 2 組, 第 3 組], ...]。
#   第 1 組是題目本身，其他組放進 "vars"（只放 stem、plot、steps、routes）。id、kind、tier、title、tmul 每一組都要一樣。
#   共用工具在這個資料夾：lib.py（數字格式、選擇題／填空／審判卡、坐標圖）、tlib.py（π 的倍數、a + b√n、數值驗算）。
#   各座塔的模組名稱一樣（t_judge、t_boss…），所以一座塔一個子行程，不會互相蓋掉。
import json, os, sys, re, importlib, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))

TOWERS = {
    "line": ["t_judge", "t_line", "t_dist", "t_circle", "t_tangent", "t_quest", "t_boss"],
    "poly": ["t_judge", "t_graph", "t_remain", "t_line", "t_param", "t_boss", "t_boss2"],
    "trig": ["t_judge", "t_graph", "t_cross", "t_angle", "t_extreme", "t_quest", "t_boss", "t_boss2"],
    "explog": ["t_judge", "t_roots", "t_line", "t_extreme", "t_quest", "t_boss", "t_boss2"],
}
FIXED = ["id", "kind", "tier", "title", "tmul"]
VARY = ["stem", "plot", "steps", "routes"]


def out_path(tower):
    return os.path.join(ROOT, "data", "levels", "tower", "%s_tower_data.gd" % tower)


def setup(tower):
    """這座塔的資料夾放最前面，共用工具放後面"""
    sys.path.insert(0, HERE)
    sys.path.insert(0, os.path.join(HERE, "..", "%s_tower" % tower))


def mods(tower, only=None):
    out = []
    for n in TOWERS[tower]:
        if only and n not in only:
            continue
        out.append(importlib.import_module(n))
    return out


_NEG = re.compile(r"(?<![A-Za-z0-9_])-(?=[0-9])")


def fix(v, key=""):
    """題目文字裡的負號一律用 −；畫圖的式子 f 保留 -，PI 換成數字（Godot 的 Expression 不認得 PI）"""
    if isinstance(v, dict):
        return {k: fix(x, k) for k, x in v.items()}
    if isinstance(v, list):
        return [fix(x, key) for x in v]
    if isinstance(v, str) and key != "f":
        return _NEG.sub("−", v)
    if isinstance(v, str):
        return v.replace("PI", "3.141592653589793").replace("+-", "-").replace("--", "+")
    return v


def build(tower, only=None):
    out = []
    for m in mods(tower, only):
        for group in m.items():
            group = [fix(g) for g in group]
            base = dict(group[0])
            for g in group[1:]:
                for k in FIXED:
                    assert g[k] == base[k], (base["id"], k)
            base["vars"] = [{k: g[k] for k in VARY if k in g} for g in group[1:]]
            out.append(base)
    ids = [d["id"] for d in out]
    assert len(ids) == len(set(ids)), "題目 id 重複"
    return out


def render(tower, data):
    txt = json.dumps(data, ensure_ascii=False, indent="\t")
    return ("extends RefCounted\n"
            "## 自動產生，不要手改：python3 tools/towerlib/gen.py %s\n"
            "##   題目模板和每一組數字在 tools/%s_tower/t_*.py，答案都由程式算、assert 驗算過。\n"
            "##   每一題的 vars 是另外幾組數字（蓋過 stem、plot、steps），塔每一輪會先出沒看過的那組。\n\n"
            "static func data() -> Array:\n\treturn " % (tower, tower) + txt.replace("\n", "\n\t") + "\n")


def one(tower, args):
    """在這個行程裡處理一座塔；傳回 0 = 成功"""
    setup(tower)
    try:
        data = build(tower)
    except Exception:
        import traceback
        traceback.print_exc()
        print("✗ %s：產生題目時出錯（多半是哪一組數字的 assert 沒過，看上面最後幾行）" % tower)
        return 3
    if "--json" in args:
        json.dump(data, open(args[args.index("--json") + 1], "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        return 0
    gd = render(tower, data)
    path = out_path(tower)
    rel = os.path.relpath(path, ROOT)
    n = sum(1 + len(d["vars"]) for d in data)
    stat = "題目 %d 題，共 %d 組數字（試煉大題 %d 題）" % (len(data), n, sum(1 for d in data if d["kind"] == "boss"))
    if "--check" in args:
        old = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
        if old != gd:
            print("✗ %s 和產生器不一致：請改 tools/%s_tower/t_*.py，再跑 python3 tools/towerlib/gen.py %s（不要直接改 .gd）" % (rel, tower, tower))
            return 1
        print("✓ %s：%s" % (rel, stat))
        return 0
    open(path, "w", encoding="utf-8").write(gd)
    print("%s：%s" % (rel, stat))
    return 0


def main(argv):
    names = [a for a in argv if a in TOWERS]
    flags = [a for a in argv if a not in TOWERS]
    bad = [a for a in argv if a not in TOWERS and not a.startswith("--") and (argv.index(a) == 0 or argv[argv.index(a) - 1] != "--json")]
    if bad:
        print("不認得：%s（可用的塔：%s）" % ("、".join(bad), "、".join(TOWERS)))
        return 2
    if len(names) == 1:
        return one(names[0], flags)
    status = 0
    for t in names or list(TOWERS):
        r = subprocess.run([sys.executable, os.path.abspath(__file__), t] + flags)
        if r.returncode != 0:
            status = 1
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
