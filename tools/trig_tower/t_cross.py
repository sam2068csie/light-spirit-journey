# 交點潮汐
from tlib import *

sin, cos, tan = math.sin, math.cos, math.tan


def gf(k):
    return repr(float(k))


def ang(k):
    return "%s*PI" % gf(k)


def dec1(x):
    s = "%.1f" % abs(x)
    return (M if x < 0 else "") + s


# ---------- tc_count：直線穿過波 ----------

def tc_count(n):
    f = lambda x: sin(PI * x) - x / n
    roots = roots_in(f, -n - 0.01, n + 0.01, 400000)
    pos = [r for r in roots if r > 1e-6]
    humps = [(2 * i, 2 * i + 1) for i in range((n + 1) // 2)]
    counts = [sum(1 for r in pos if lo < r < hi) for lo, hi in humps]
    assert sum(counts) == len(pos)
    total = 2 * len(pos) + 1
    assert len(roots) == total
    tmpl = "，".join("%d < x < %d：[%d] 個" % (lo, hi, i) for i, (lo, hi) in enumerate(humps))
    return item("tc_count", "cross", 1, "直線穿過波", 1.05,
                "方程式 sin(πx) = x/%d 有幾個實根？" % n,
                [ch("交點的 x 一定在哪個範圍？", ["−%d ≤ x ≤ %d" % (n, n), "−1 ≤ x ≤ 1", "0 ≤ x ≤ %d" % n, "全體實數"],
                    "|sin(πx)| ≤ 1，所以 |x/%d| ≤ 1" % n, "|x/%d| ≤ 1 ⇒ −%d ≤ x ≤ %d" % (n, n, n)),
                 fl("看圖數 x > 0 的交點：sin(πx) 的波峰在 %s。" % "、".join("%d 到 %d" % h for h in humps), tmpl, [str(c) for c in counts],
                    "第一個波峰從原點出發，只再交一次；後面的波峰比直線高，各被切過兩次；波谷在直線下面"),
                 fl("兩邊都是奇函數，左邊和右邊一樣多，再加上原點：", "答：共 %d + %d + 1 = [0] 個實根" % (len(pos), len(pos)), [str(total)],
                    "%d + %d + 1" % (len(pos), len(pos)))],
                plot={"x": [-n - 0.6, n + 0.6], "y": [-1.5, 1.5],
                      "curves": [{"f": "sin(PI*x)", "c": "cyan", "at": 1}, {"f": "x/%d" % n, "c": "pink", "at": 1}]})


# ---------- tc_sum：解的總和 ----------

def tc_sum(fn, k, segs, first):
    """segs：[(起, 訖, 對稱軸)]（π 的倍數）；first：先講哪一段"""
    g = (lambda x: cos(x)) if fn == "cos" else (lambda x: sin(x))
    lo, hi = float(min(s[0] for s in segs)) * PI, float(max(s[1] for s in segs)) * PI
    roots = roots_in(lambda x: g(x) - float(k), lo, hi)
    assert len(roots) == 2 * len(segs)
    tot = sum(roots) / PI
    S = 2 * sum(s[2] for s in segs)
    assert near(tot, S)
    s0 = segs[first]
    others = [s for i, s in enumerate(segs) if i != first]
    why = "cos 的圖形在一個週期內對稱於最低點" if fn == "cos" else "sin x = %s 的兩個解都在 x 軸上方的那一段，對稱於最高點" % t(k)
    if fn == "cos" and k > 0:
        why = "cos 的圖形在 0 到 2π 對稱於最低點 x = π"
    axes_sum = " + ".join(("2π" if s[2] == 1 else "2(%s)" % pt_(s[2])) for s in segs)
    return item("tc_sum", "cross", 1, "解的總和", 1.05,
                "求方程式 %s x = %s 在 %s ≤ x ≤ %s 的所有解的和。" % (fn, t(k), pt_(segs[0][0]), pt_(segs[-1][1])),
                [fl("先看 %s ≤ x ≤ %s 這一段：" % (pt_(s0[0]), pt_(s0[1])), "有 [0] 個解，兩個解對稱於 x = [1]π", ["2", a(s0[2])], why + " x = " + pt_(s0[2]) if fn == "cos" and k < 0 else why),
                 fl("另外兩段也一樣，各兩個解，對稱於那一段的%s：" % ("最低點" if fn == "cos" else "最高點"),
                    "%s 到 %s 對稱於 x = [0]π，%s 到 %s 對稱於 x = [1]π" % (pt_(others[0][0]), pt_(others[0][1]), pt_(others[1][0]), pt_(others[1][1])),
                    [a(others[0][2]), a(others[1][2])], "每一段的中點" if fn == "cos" else "每一段的 π/2 再加上起點"),
                 fl("對稱的兩個解，和是對稱軸的 2 倍：", "答：和 = %s = [0]π" % axes_sum, [a(S)], " + ".join(t(2 * s[2]) for s in segs).replace("+ −", "− "))],
                plot={"x": [fx(lo - 0.3), fx(hi + 0.3)], "y": [-1.4, 1.4], "pi": 1, "pi_up": bool(k < 0),
                      "curves": [{"f": "%s(x)" % fn, "c": "cyan"}, {"f": gf(k), "c": "pink", "dash": True}]})


# ---------- tc_center：對稱中心配對 ----------

def tc_center(k, c, m, opts):
    """sin(kx) = (x − cπ)/m；u = x − cπ"""
    c = F(c)
    sg = 1 if (k * c) % 2 == 0 else -1
    assert (k * c).denominator == 1
    roots = roots_in(lambda x: sin(k * x) - (x - float(c) * PI) / m, float(c) * PI - m - 0.01, float(c) * PI + m + 0.01)
    us = [r - float(c) * PI for r in roots]
    assert near(sum(us), 0, 1e-6)
    n = len(roots)
    S = n * c
    assert near(sum(roots) / PI, S, 1e-6)
    eq = ("sin %du = u/%d" if sg > 0 else "−sin %du = u/%d") % (k, m)
    xs = "x − %s" % pt_(c)
    return item("tc_center", "cross", 2, "對稱中心配對", 1.15,
                "方程式 sin %dx = (%s)/%d 的所有實數解的和是多少？" % (k, xs, m),
                [ch("令 u = %s，方程式變成？" % xs, uniq([eq], opts), "sin(%du + %s) = %ssin %du" % (k, pt_(k * c), "" if sg > 0 else "−", k),
                    "u = %s：%s（兩邊都是 u 的奇函數）" % (xs, eq)),
                 fl("看圖數交點（u 的解正負成對，加上 u = 0）：", "共 [0] 個解", [str(n)], "|u/%d| ≤ 1 ⇒ |u| ≤ %d，在這個範圍裡數" % (m, m)),
                 fl("u 的解加起來是 0，換回 x = u + %s：" % pt_(c), "答：所有解的和 = [0]π", [a(S)], "每個解都加 %s" % pt_(c))],
                plot={"x": [fx(float(c) * PI - m - 0.4), fx(float(c) * PI + m + 0.4)], "y": [-1.4, 1.4], "pi": 4,
                      "curves": [{"f": "sin(%d*x)" % k, "c": "cyan"}, {"f": "(x-%s)/%d" % (ang(c), m), "c": "pink"}],
                      "pts": [{"x": fx(float(c) * PI), "y": 0, "label": "(%s, 0)" % pt_(c), "off": [6, 20]}]})


# ---------- tc_tan：tan 和直線 ----------

def tc_tan(sl, b0, line_txt):
    """tan x = sl · x + b0（sl < 0），−π < x < 2π"""
    L = lambda x: sl * x + b0
    segs = [(-PI, -PI / 2), (-PI / 2, PI / 2), (PI / 2, 3 * PI / 2), (3 * PI / 2, 2 * PI)]
    cnt = []
    for lo, hi in segs:
        cnt.append(len(roots_in(lambda x: tan(x) - L(x), lo + 1e-6, hi - 1e-6)) if True else 0)
    # 漸近線附近的假根（tan 跳號）要去掉：只留 |tan − L| 真的接近 0 的
    cnt = []
    for lo, hi in segs:
        rs = [r for r in roots_in(lambda x: tan(x) - L(x), lo + 1e-4, hi - 1e-4) if abs(tan(r) - L(r)) < 1e-6]
        cnt.append(len(rs))
    assert cnt[1] == 1 and cnt[2] == 1
    left = 1 if L(-PI) > 0 else 0
    right = 1 if L(2 * PI) < 0 else 0
    assert cnt[0] == left and cnt[3] == right
    tot = sum(cnt)
    lh = "直線的高度在 %s 到 %s 之間" % (dec1(L(-PI / 2)), dec1(L(-PI)))
    rh = "直線的高度大約是 %s 到 %s" % (dec1(L(3 * PI / 2)), dec1(L(2 * PI)))
    return item("tc_tan", "cross", 2, "tan 和直線", 1.25,
                "方程式 tan x = %s 在 −π < x < 2π 有幾個實根？" % line_txt,
                [fl("漸近線 x = −π/2、π/2、3π/2 把 tan 的圖形切成幾段？", "[0] 段", ["4"], "三條線切成四段"),
                 fl("中間兩段是完整的一支：tan 從 −∞ 升到 ∞，直線一定穿過。", "中間兩段：各 [0] 個", ["1"], "tan 一直往上，直線往下"),
                 fl("最左段（−π 到 −π/2）：tan 從 0 升到 ∞，%s。" % lh, "最左段：[0] 個", [str(left)],
                    "tan 從比直線低，升到比直線高" if left else "tan 一開始就比直線高，之後 tan 往上、直線往下，碰不到"),
                 fl("最右段（3π/2 到 2π）：tan 從 −∞ 升到 0，%s。" % rh, "最右段：[0] 個 ⇒ 答：共 [1] 個", [str(right), str(tot)],
                    "tan 從比直線低，升到 0（比直線高）" if right else "直線一直在 x 軸上方，tan 升到 0 都還比直線低")],
                plot={"x": [-3.3, 6.45], "y": [-6.0, 6.0], "pi": 2,
                      "curves": [{"f": "tan(x)", "c": "cyan"}, {"f": "%s*x+%s" % (gf(sl), gf(b0)), "c": "pink"}],
                      "vlines": [{"x": -1.5708}, {"x": 1.5708}, {"x": 4.7124}]})


# ---------- tc_abs：絕對值的波 ----------

def tc_abs(n):
    """nπ sin|x| + x = 0"""
    f = lambda x: sin(abs(x)) + x / (n * PI)
    R = n * PI
    roots = roots_in(f, -R - 0.01, R + 0.01, 400000)
    right = [(F(2 * i - 1), F(2 * i)) for i in range(1, n // 2 + 1)]           # 波谷 (π, 2π)、(3π, 4π)…
    left = [(F(-2 * i - 1), F(-2 * i)) for i in range(0, (n + 1) // 2)]          # 波峰 (−π, 0)、(−3π, −2π)…
    cnt = lambda lo, hi: sum(1 for r in roots if float(lo) * PI + 1e-6 < r < float(hi) * PI - 1e-6)
    rc = [cnt(lo, hi) for lo, hi in right]
    lc = [cnt(lo, hi) for lo, hi in left]
    assert sum(rc) + sum(lc) + 1 == len(roots)
    rt_ = "x ≥ 0：原點 1 個，" + "，".join("%s 到 %s：[%d] 個" % (pt_(lo), pt_(hi), i) for i, (lo, hi) in enumerate(right))
    lt_ = "，".join("%s 到 %s：[%d] 個" % (pt_(lo), pt_(hi), i) for i, (lo, hi) in enumerate(left))
    nn = "" if n == 1 else str(n)
    return item("tc_abs", "cross", 3, "絕對值的波", 1.35,
                "方程式 %sπ sin|x| + x = 0 有幾個實數解？" % nn,
                [fl("|sin| ≤ 1，交點只會在這個範圍：", "|x/(%sπ)| ≤ 1 ⇒ −[0]π ≤ x ≤ [1]π" % nn, [str(n), str(n)], "|x| ≤ %sπ" % nn,
                    pre="%sπ sin|x| + x = 0 ⇒ sin|x| = −x/(%sπ)" % (nn, nn)),
                 fl("右半邊 x ≥ 0：直線往下，原點是一個解，其他只會碰到 x 軸下方的波谷。", rt_, [str(c) for c in rc],
                    "看圖右半邊：波谷都比直線低，各被切過兩次"),
                 fl("左半邊 x < 0：sin|x| 左右對稱，直線在這邊往上，只會碰到 x 軸上方的波峰。", lt_, [str(c) for c in lc],
                    "−π 到 0 的波峰從原點出發，只再交一次" + ("；其他波峰比直線高，各被切過兩次" if len(left) > 1 else "")),
                 fl("全部加起來：", "答：共 [0] 個", [str(len(roots))], "右邊 %d 個、左邊 %d 個" % (sum(rc) + 1, sum(lc)))],
                plot={"x": [fx(-R - 0.4), fx(R + 0.4)], "y": [-1.5, 1.5], "pi": 1,
                      "curves": [{"f": "sin(abs(x))", "c": "cyan"}, {"f": "-x/(%d*PI)" % n, "c": "pink"}]})


# ---------- tc_double：倍角方程式 ----------

def tc_double(cq, al, lo, hi):
    """sin 2x = c sin x，c = 2 cos(αlπ)；lo ≤ x ≤ hi（π 的倍數）"""
    cq, al, lo, hi = Q.of(cq), F(al), F(lo), F(hi)
    assert cq == 2 * cv(al)
    roots = roots_in(lambda x: sin(2 * x) - float(cq) * sin(x), float(lo) * PI - 1e-9, float(hi) * PI + 1e-9)
    zs = [F(k) for k in range(-4, 5) if lo <= k <= hi]
    cs = sorted(set(x for x in [al + 2 * k for k in range(-2, 3)] + [-al + 2 * k for k in range(-2, 3)] if lo <= x <= hi))
    assert len(roots) == len(zs) + len(cs)
    S = sum(zs) + sum(cs)
    assert near(sum(roots) / PI, S, 1e-6)
    c2 = cq / 2
    ct = cq.text()
    ctp = ct if not ct.startswith(M) else ct
    corr = "sin x(2 cos x %s %s) = 0" % ("−" if float(cq) > 0 else "+", (cq if float(cq) > 0 else -cq).text())
    w1 = "sin x(2 cos x %s %s) = 0" % ("+" if float(cq) > 0 else "−", (cq if float(cq) > 0 else -cq).text())
    w2 = "cos x(2 sin x %s %s) = 0" % ("−" if float(cq) > 0 else "+", (cq if float(cq) > 0 else -cq).text())
    w3 = "2 sin x(cos x %s %s) = 0" % ("−" if float(cq) > 0 else "+", (cq if float(cq) > 0 else -cq).text())
    rhs = ("%s sin x" % ct) if not cq == 1 else "sin x"
    if cq == -1:
        rhs = "−sin x"
    tmpl = "cos x = %s ⇒ x = %s" % (c2.text(), "、".join("[%d]π" % i for i in range(len(cs))))
    return item("tc_double", "cross", 2, "倍角方程式", 1.15,
                "求方程式 sin 2x = %s 在 %s ≤ x ≤ %s 的所有解的和。" % (rhs, pt_(lo), pt_(hi)),
                [ch("sin 2x 展開，再提出公因式：", [corr, w1, w2, w3], "sin 2x = 2 sin x cos x",
                    "2 sin x cos x%s = 0 ⇒ %s" % (cof(-cq, "sin x"), corr)),
                 fl("cos x = %s 的解（由小到大）：" % c2.text(), tmpl, [a(x) for x in cs], "cos(%s) = %s" % (pt_(al), c2.text()),
                    pre="sin x = 0 ⇒ x = %s" % "、".join(pt_(z) for z in zs)),
                 fl("%d 個解加起來：" % (len(zs) + len(cs)), "答：和 = [0]π", [a(S)], " + ".join(pt_(x) for x in zs + cs))])


# ---------- tc_ineq：疊合不等式 ----------

def tc_ineq(cs, cc, r, ph, k, strict):
    """cs sin x + cc cos x ≥ k（或 >），= r sin(x + φπ)；0 ≤ x < 2π"""
    cs, cc, r, ph, k = Q.of(cs), Q.of(cc), Q.of(r), F(ph), Q.of(k)
    assert cs == r * cv(ph) and cc == r * sv(ph)
    s = k / r
    al = None
    for d in (F(1, 6), F(1, 4), F(1, 3)):
        if sv(d) == s:
            al = d
    assert al is not None
    u0, u1 = al, 1 - al
    x0, x1 = u0 - ph, u1 - ph
    assert 0 <= x0 < x1 < 2
    f = lambda x: float(cs) * sin(x) + float(cc) * cos(x)
    ok = lambda x: (f(x) > float(k) + 1e-12) if strict else (f(x) >= float(k) - 1e-12)
    xs = [2 * PI * i / 7200 for i in range(7200)]
    for x in xs:
        assert ok(x) == (float(x0) * PI - 1e-9 <= x <= float(x1) * PI + 1e-9) or near(x, float(x0) * PI, 1e-3) or near(x, float(x1) * PI, 1e-3)
    op = ">" if strict else "≥"
    sg = "+" if ph > 0 else "−"
    fx_ = lin_tr([(cs, "sin x"), (cc, "cos x")])
    pts = [0, 0] if strict else [1, 1]
    return item("tc_ineq", "cross", 1, "疊合不等式", 1.0,
                "在 0 ≤ x < 2π，解不等式 %s %s %s。" % (fx_, op, k.text()),
                [fl("先疊合：", "%s = [0] sin(x %s [1]π)" % (fx_, sg), [r.ans(), a(abs(ph))],
                    "√{%s} = %s，cos(%s) = %s、sin(%s) = %s" % (" + ".join(t((v * v).a) for v in (cs, cc)), r.text(), pt_(abs(ph)), cv(abs(ph)).text(),
                                                              pt_(abs(ph)), sv(abs(ph)).text())),
                 fl("sin(x %s %s) %s %s，而 x %s %s 在 %s 到 %s 之間：" % (sg, pt_(abs(ph)), op, s.text(), sg, pt_(abs(ph)), pt_(ph), pt_(2 + ph)),
                    "[0]π %s x %s %s %s [1]π" % ("<" if strict else "≤", sg, pt_(abs(ph)), "<" if strict else "≤"), [a(u0), a(u1)],
                    "sin u %s %s 在 %s %s u %s %s" % (op, s.text(), pt_(u0), "<" if strict else "≤", "<" if strict else "≤", pt_(u1))),
                 step("line", q="封印 x 的範圍%s。" % ("（兩端都不能等於）" if strict else "（兩端都可以等於）"), row="解", marks=[pt_(x0), pt_(x1)],
                      seg=[0, 1, 0], pt=pts, write="答：%s %s x %s %s" % (pt_(x0), "<" if strict else "≤", "<" if strict else "≤", pt_(x1)))],
                plot={"x": [-0.3, 6.6], "y": [-float(r) - 0.5, float(r) + 0.5], "pi": 12, "pi_lab": 2,
                      "curves": [{"f": "%s*sin(x)+%s*cos(x)" % (gf(float(cs)), gf(float(cc))), "c": "cyan", "at": 1},
                                 {"f": gf(float(k)), "c": "pink", "dash": True, "at": 1}],
                      "band": {"lo": fx(float(x0) * PI), "hi": fx(float(x1) * PI), "at": 2}})


# ---------- tc_half：半角的不等式 ----------

def tc_half(cfg):
    op, rel = cfg["op"], cfg["rel"]
    f = lambda x: rel(cos(x), cos(x / 2))
    lo, hi = cfg["ans"]
    for i in range(1, 2000):
        x = 2 * PI * i / 2000
        if near(x, float(lo) * PI, 1e-3) or near(x, float(hi) * PI, 1e-3):
            continue
        assert f(x) == (float(lo) * PI < x < float(hi) * PI or (cfg["closed"] and near(x, float(lo) * PI))), (x, cfg["stem"])
    return item("tc_half", "cross", 3, "半角的不等式", 1.3,
                "在 0 ≤ x < 2π，解不等式 %s。" % cfg["stem"],
                [ch("令 c = cos(x/2)，cos x 用 c 表示：", ["2c^{2} − 1", "1 − 2c^{2}", "2c − 1", "c^{2} − 1"],
                    "cos x = cos 2(x/2)", "c = cos(x/2)：%s" % cfg["inc"]),
                 fl("移項後因式分解：", cfg["fac"], cfg["fac_ans"], cfg["fac_hint"]),
                 step("roots", q="c = cos(x/2)：劃掉不可能的那一邊。", cands=cfg["cands"], write=cfg["cand_write"]),
                 fl("0 ≤ x/2 < π 裡，%s：" % cfg["half"], cfg["half_t"], cfg["half_ans"], cfg["half_hint"]),
                 step("line", q="封印 x 的範圍。", row="解", marks=[pt_(lo), pt_(hi)], seg=[0, 1, 0], pt=cfg["pts"], write="答：%s" % cfg["write"])])


HALF = [
    {"stem": "cos x > cos(x/2)", "op": ">", "rel": lambda u, v: u > v + 1e-12, "inc": "2c^{2} − 1 > c",
     "fac": "(2c + 1)(c − 1) > 0 ⇒ c < [0] 或 c > 1", "fac_ans": ["−1/2"], "fac_hint": "兩根 −1/2、1，開口向上，大於 0 在兩根外面",
     "cands": [{"v": "c < −1/2", "ok": True, "why": "0 ≤ x/2 < π，cos(x/2) 可以小於 −1/2"}, {"v": "c > 1", "ok": False, "why": "cos 不會大於 1"}],
     "cand_write": "只剩 cos(x/2) < −1/2", "half": "cos(x/2) < −1/2", "half_t": "[0]π < x/2 < π", "half_ans": ["2/3"], "half_hint": "cos(2π/3) = −1/2",
     "ans": (F(4, 3), F(2)), "closed": False, "pts": [0, 0], "write": "4π/3 < x < 2π"},
    {"stem": "cos x > 3 cos(x/2) − 2", "op": ">", "rel": lambda u, v: u > 3 * v - 2 + 1e-12, "inc": "2c^{2} − 1 > 3c − 2",
     "fac": "(2c − 1)(c − 1) > 0 ⇒ c < [0] 或 c > 1", "fac_ans": ["1/2"], "fac_hint": "2c^{2} − 3c + 1 > 0，兩根 1/2、1，開口向上，大於 0 在兩根外面",
     "cands": [{"v": "c < 1/2", "ok": True, "why": "π/3 < x/2 < π 時 cos(x/2) < 1/2"}, {"v": "c > 1", "ok": False, "why": "cos 不會大於 1"}],
     "cand_write": "只剩 cos(x/2) < 1/2", "half": "cos(x/2) < 1/2", "half_t": "[0]π < x/2 < π", "half_ans": ["1/3"], "half_hint": "cos(π/3) = 1/2",
     "ans": (F(2, 3), F(2)), "closed": False, "pts": [0, 0], "write": "2π/3 < x < 2π"},
    {"stem": "cos x + cos(x/2) ≥ 0", "op": "≥", "rel": lambda u, v: u + v >= -1e-12, "inc": "2c^{2} + c − 1 ≥ 0",
     "fac": "(2c − 1)(c + 1) ≥ 0 ⇒ c ≤ −1 或 c ≥ [0]", "fac_ans": ["1/2"], "fac_hint": "兩根 −1、1/2，開口向上，大於等於 0 在兩根外面",
     "cands": [{"v": "c ≥ 1/2", "ok": True, "why": "0 ≤ x/2 ≤ π/3 時成立"}, {"v": "c ≤ −1", "ok": False, "why": "x/2 < π，cos(x/2) 永遠大於 −1"}],
     "cand_write": "只剩 cos(x/2) ≥ 1/2", "half": "cos(x/2) ≥ 1/2", "half_t": "0 ≤ x/2 ≤ [0]π", "half_ans": ["1/3"], "half_hint": "cos(π/3) = 1/2",
     "ans": (F(0), F(2, 3)), "closed": True, "pts": [1, 1], "write": "0 ≤ x ≤ 2π/3"},
]


# ---------- tc_k：兩個交點的 k ----------

def tc_k(cs, cc, r, ph, D):
    """cs sin x + cc cos x = k 在 0 ≤ x ≤ Dπ 有兩根；= r sin(x + φπ)"""
    cs, cc, r, ph, D = Q.of(cs), Q.of(cc), Q.of(r), F(ph), F(D)
    assert cs == r * cv(ph) and cc == r * sv(ph)
    u0, u1 = ph, ph + D
    assert u0 < F(1, 2) < u1
    e0, e1 = r * sv(u0), r * sv(u1)
    lo = max(e0, e1, key=float)
    f = lambda x: float(cs) * sin(x) + float(cc) * cos(x)
    cnt = lambda k: len([x for x in roots_in(lambda x: f(x) - k, 0, float(D) * PI) ])
    assert cnt(float(lo) + 1e-4) == 2 and cnt(float(r) - 1e-4) == 2 and cnt(float(lo) - 1e-3) < 2 and cnt(float(r)) <= 1
    assert cnt(float(lo)) == 2
    sg = "+" if ph > 0 else "−"
    fx_ = lin_tr([(cs, "sin x"), (cc, "cos x")])
    left_is = e0 >= e1
    hint = "%s端點高度 %s sin(%s) = %s，最高點 %s 只有一個交點" % ("左" if left_is else "右", r.text(), pt_(u0 if left_is else u1), lo.text(), r.text())
    return item("tc_k", "cross", 3, "兩個交點的 k", 1.3,
                "方程式 %s = k 在 0 ≤ x ≤ %s 有兩個相異實根，求 k 的範圍（寫成 a ≤ k < b）。" % (fx_, pt_(D)),
                [fl("先疊合：", "%s = [0] sin(x %s [1]π)" % (fx_, sg), [r.ans(), a(abs(ph))],
                    "√{%s} = %s，cos(%s) = %s、sin(%s) = %s" % (" + ".join(t((v * v).a) for v in (cs, cc)), r.text(), pt_(abs(ph)), cv(abs(ph)).text(),
                                                              pt_(abs(ph)), sv(abs(ph)).text())),
                 fl("令 u = x %s %s：" % (sg, pt_(abs(ph))), "[0]π ≤ u ≤ [1]π", [a(u0), a(u1)], "0 %s %s 到 %s %s %s" % (sg, pt_(abs(ph)), pt_(D), sg, pt_(abs(ph)))),
                 fl("看圖：水平線 y = k 和 y = %s sin u 交兩點的時候：" % r.text(), "答：[0] ≤ k < [1]", [lo.ans(), r.ans()], hint)],
                plot={"x": [fx(min(0, float(u0) * PI) - 0.3), fx(float(u1) * PI + 0.35)], "y": [fx(min(-0.6, float(e0), float(e1)) - 0.3), fx(float(r) + 0.5)],
                      "pi": 12 if (u0.denominator == 4 or u1.denominator == 4 or u0.denominator == 12) else 6, "var": "u",
                      "curves": [{"f": "%s*sin(x)" % gf(float(r)), "c": "cyan", "dom": [fx(float(u0) * PI), fx(float(u1) * PI)], "at": 2},
                                 {"f": gf(float(lo)), "c": "pink", "dash": True, "at": 2}],
                      "band": {"lo": fx(float(u0) * PI), "hi": fx(float(u1) * PI), "at": 2},
                      "pts": [{"x": fx(float(u0 if left_is else u1) * PI), "y": fx(float(lo)), "label": lo.lab(), "off": [-26, -6] if left_is else [8, -6], "at": 2},
                              {"x": fx(PI / 2), "y": fx(float(r)), "label": r.lab(), "at": 2}]})


def items():
    return [
        [tc_count(3), tc_count(5), tc_count(7)],
        [tc_sum("cos", F(-1, 5), [(-2, 0, -1), (0, 2, 1), (2, 4, 3)], 1),
         tc_sum("sin", F(1, 3), [(0, 2, F(1, 2)), (2, 4, F(5, 2)), (4, 6, F(9, 2))], 0),
         tc_sum("cos", F(2, 3), [(-4, -2, -3), (-2, 0, -1), (0, 2, 1)], 2)],
        [tc_center(2, 1, 2, ["−sin 2u = u/2", "sin 2u = (u − π)/2", "cos 2u = u/2", "sin 2u = u/2"]),
         tc_center(2, F(1, 2), 3, ["sin 2u = u/3", "sin 2u = (u − π/2)/3", "cos 2u = u/3", "−cos 2u = u/3"]),
         tc_center(3, 1, 2, ["sin 3u = u/2", "sin 3u = (u − π)/2", "cos 3u = u/2", "−cos 3u = u/2"])],
        [tc_tan(-1, 1, "1 − x"), tc_tan(-1, 7, "7 − x"), tc_tan(-0.5, -2, "−x/2 − 2")],
        [tc_abs(4), tc_abs(2), tc_abs(3)],
        [tc_double(Q(0, 1, 2), F(1, 4), 0, 2), tc_double(1, F(1, 3), 0, 1), tc_double(-1, F(2, 3), 0, 1)],
        [tc_ineq(1, Q(0, -1, 3), 2, F(-1, 3), 1, False), tc_ineq(Q(0, 1, 3), 1, 2, F(1, 6), 1, True),
         tc_ineq(1, 1, Q(0, 1, 2), F(1, 4), 1, False)],
        [tc_half(c) for c in HALF],
        [tc_k(1, Q(0, 1, 3), 2, F(1, 3), F(2, 3)), tc_k(Q(0, 1, 3), -1, 2, F(-1, 6), 1), tc_k(1, 1, Q(0, 1, 2), F(1, 4), F(1, 2))],
    ]
