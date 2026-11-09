# 數線封印
from elib import *


def LN(q, row, marks, seg, pt, write=None):
    d = step("line", q=q, row=row, marks=[t(m) if not isinstance(m, str) else m for m in marks], seg=seg, pt=pt)
    if write:
        d["write"] = write
    return d


def sat(f, lo, hi, n=2000):
    return [f(lo + (hi - lo) * (i + 0.5) / n) for i in range(n)]


def check_line(cond, marks, seg, pt, lo=-50.0, hi=50.0):
    """數值檢查：每一段和每個點的選不選"""
    ms = [float(m) for m in marks]
    edges = [lo] + ms + [hi]
    for i in range(len(seg)):
        mid = (edges[i] + edges[i + 1]) / 2
        assert bool(cond(mid)) == bool(seg[i]), ("段", i, mid)
    for i, m in enumerate(ms):
        assert bool(cond(m)) == bool(pt[i]), ("點", i, m)


def bt(b):
    return t(F(b)) if not isinstance(b, str) else b


# ---------- l_flip：log_b (x − a) ? log_b (c − x) ----------

def l_flip(b, a_, c):
    b = F(b)
    m = F(a_ + c, 2)
    lb = "log_{%s}" % (("%g" % float(b)) if b < 1 and b.denominator in (2, 5, 10) else t(b))
    dec = b < 1
    def cond(x):
        if not (x > a_ and x < c):
            return False
        return (lg(float(b), x - a_) > lg(float(b), c - x) + 1e-12)
    marks = [a_, m, c]
    seg = [0, 1, 0, 0] if dec else [0, 0, 1, 0]
    check_line(cond, marks, seg, [0, 0, 0])
    rel = "x − %s < %d − x" % (t(a_), c) if dec else "x − %s > %d − x" % (t(a_), c)
    xa = poly([(1, "x"), (-a_, "")])
    opts = ["反向：%s < %d − x" % (xa, c), "不變：%s > %d − x" % (xa, c)]
    if not dec:
        opts = opts[::-1]
    return item("l_flip", "line", 1, "底數與不等號", 1.0,
                "解不等式 %s (%s) > %s (%d − x)。" % (lb, xa, lb, c),
                [LN("先封印定義域：兩個真數都要大於 0。", "定義域", marks, [0, 1, 1, 0], [0, 1, 0], "定義域：%s < x < %d" % (t(a_), c)),
                 ch("底數 %s %s 1，拿掉 log 後不等號？" % (t(b) if b >= 1 else "%g" % float(b), "<" if dec else ">"), opts,
                    "底數小於 1 的對數是遞減函數" if dec else "底數大於 1 的對數是遞增函數",
                    "%s %s %d − x　→　x %s %s" % (xa, "<" if dec else ">", c, "<" if dec else ">", t(m))),
                 LN("和定義域取交集，封印最後的解。", "解", marks, seg, [0, 0, 0],
                    "答：%s < x < %s" % ((t(a_), t(m)) if dec else (t(m), str(c))))])


# ---------- l_expineq ----------

def l_expineq(cfg):
    r1, r2 = cfg["r"]
    f = cfg["cond"]
    check_line(f, [r1, r2], [0, 1, 0], [1, 1], -20, 20)
    return item("l_expineq", "line", 1, "指數不等式", 1.0, "解不等式 %s。" % cfg["stem"],
                [ch(cfg["q1"], cfg["o1"], cfg["h1"], cfg["w1"]),
                 ch("比較指數，得到？", cfg["o2"], cfg["h2"], cfg["w2"]),
                 ch("移項整理：", cfg["o3"], cfg["h3"], "%s ≤ 0　→　%s ≤ x ≤ %s" % (cfg["q"], t(r1), t(r2))),
                 LN("封印解的範圍（注意等號）。", "解", [r1, r2], [0, 1, 0], [1, 1], "答：%s ≤ x ≤ %s" % (t(r1), t(r2)))])


EXPINEQ = [
    {"stem": "(1/2)^{x^{2} − 3x} ≥ (1/4)^{x − 2}", "r": (1, 4), "q": "x^{2} − 5x + 4",
     "cond": lambda x: 0.5 ** (x * x - 3 * x) >= 0.25 ** (x - 2) * (1 - 1e-12),
     "q1": "右邊化成底數 1/2：", "o1": ["(1/2)^{2x − 4}", "(1/2)^{x − 4}", "(1/2)^{2x − 2}", "(1/2)^{x^{2} − 4}"], "h1": "1/4 = (1/2)^{2}",
     "w1": "(1/2)^{x^{2} − 3x} ≥ (1/2)^{2x − 4}",
     "o2": ["x^{2} − 3x ≤ 2x − 4", "x^{2} − 3x ≥ 2x − 4"], "h2": "底數 1/2 < 1，不等號要反向", "w2": "x^{2} − 3x ≤ 2x − 4（底數 < 1，反向）",
     "o3": ["x^{2} − 5x + 4 ≤ 0", "x^{2} − x − 4 ≤ 0", "x^{2} − 5x − 4 ≤ 0", "x^{2} + 5x + 4 ≤ 0"], "h3": "2x − 4 整個移到左邊要變號"},
    {"stem": "(1/3)^{x^{2} − x} ≥ (1/9)^{x + 2}", "r": (-1, 4), "q": "x^{2} − 3x − 4",
     "cond": lambda x: (1 / 3) ** (x * x - x) >= (1 / 9) ** (x + 2) * (1 - 1e-12),
     "q1": "右邊化成底數 1/3：", "o1": ["(1/3)^{2x + 4}", "(1/3)^{x + 4}", "(1/3)^{2x + 2}", "(1/3)^{x^{2} + 4}"], "h1": "1/9 = (1/3)^{2}",
     "w1": "(1/3)^{x^{2} − x} ≥ (1/3)^{2x + 4}",
     "o2": ["x^{2} − x ≤ 2x + 4", "x^{2} − x ≥ 2x + 4"], "h2": "底數 1/3 < 1，不等號要反向", "w2": "x^{2} − x ≤ 2x + 4（底數 < 1，反向）",
     "o3": ["x^{2} − 3x − 4 ≤ 0", "x^{2} + x − 4 ≤ 0", "x^{2} − 3x + 4 ≤ 0", "x^{2} − x − 4 ≤ 0"], "h3": "2x + 4 整個移到左邊要變號"},
    {"stem": "2^{x^{2} + x} ≤ 4^{x + 3}", "r": (-2, 3), "q": "x^{2} − x − 6",
     "cond": lambda x: 2 ** (x * x + x) <= 4 ** (x + 3) * (1 + 1e-12),
     "q1": "右邊化成底數 2：", "o1": ["2^{2x + 6}", "2^{x + 6}", "2^{2x + 3}", "2^{x^{2} + 3}"], "h1": "4 = 2^{2}",
     "w1": "2^{x^{2} + x} ≤ 2^{2x + 6}",
     "o2": ["x^{2} + x ≤ 2x + 6", "x^{2} + x ≥ 2x + 6"], "h2": "底數 2 > 1，不等號方向不變", "w2": "x^{2} + x ≤ 2x + 6（底數 > 1，不變）",
     "o3": ["x^{2} − x − 6 ≤ 0", "x^{2} + 3x − 6 ≤ 0", "x^{2} − x + 6 ≤ 0", "x^{2} + x − 6 ≤ 0"], "h3": "2x + 6 整個移到左邊要變號"},
]


# ---------- l_twolog：log_b (x − p) + log_b (x − q) ≥ log_b N（b < 1） ----------

def l_twolog(b, p, q, N, r1, r2):
    bf = float(F(b))
    assert (r1 - p) * (r1 - q) == N and (r2 - p) * (r2 - q) == N and r1 < q < r2
    S, P = p + q, p * q
    lb = "log_{%s}" % ("%g" % bf if F(b).denominator in (2, 5, 10) else t(F(b)))
    cond_dom = lambda x: x > q
    cond_ineq = lambda x: (x - p) * (x - q) <= N
    cond = lambda x: cond_dom(x) and lg(bf, x - p) + lg(bf, x - q) >= lg(bf, N) - 1e-12
    marks = [r1, q, r2]
    check_line(cond_dom, marks, [0, 0, 1, 1], [0, 0, 1])
    check_line(cond_ineq, marks, [0, 1, 1, 0], [1, 1, 1])
    check_line(cond, marks, [0, 0, 1, 0], [0, 0, 1])
    pr = "(%s)(%s)" % (poly([(1, "x"), (-p, "")]), poly([(1, "x"), (-q, "")]))
    qd = quad_t(1, -S, P - N)
    return item("l_twolog", "line", 2, "合併再比較", 1.15,
                "解不等式 %s (%s) + %s (%s) ≥ %s %d。" % (lb, poly([(1, "x"), (-p, "")]), lb, poly([(1, "x"), (-q, "")]), lb, N),
                [LN("先封印定義域。", "定義域", marks, [0, 0, 1, 1], [0, 0, 1], "定義域：x > %d" % q),
                 ch("合併並拿掉 log 之後？", ["%s ≤ %d" % (pr, N), "%s ≥ %d" % (pr, N), "(%s) + (%s) ≤ %d" % (poly([(1, "x"), (-p, "")]), poly([(1, "x"), (-q, "")]), N),
                                         "%s ≤ log %d" % (pr, N)],
                    "相加變相乘，底數 %s < 1 要變號" % ("%g" % bf if F(b).denominator in (2, 5, 10) else t(F(b))),
                    "%s %s ≥ %s %d　→　%s ≤ %d（反向）" % (lb, "[" + pr + "]", lb, N, pr, N)),
                 ch("展開、移項：", uniq([qd + " ≤ 0"], [quad_t(1, -S, P) + " ≤ 0", quad_t(1, -S, P - 2 * N) + " ≤ 0", quad_t(1, S, P - N) + " ≤ 0"]),
                    "%s = %s，再減 %d" % (pr, quad_t(1, -S, P), N), "%s ≤ 0　→　%s ≤ x ≤ %s" % (qd, t(r1), t(r2))),
                 LN("封印不等式的解。", "不等式", marks, [0, 1, 1, 0], [1, 1, 1]),
                 LN("兩列取交集。", "交集", marks, [0, 0, 1, 0], [0, 0, 1], "答：%d < x ≤ %d" % (q, r2))])


# ---------- l_meaning：log_2 [log_b (x + c)] 有意義 ----------

def l_meaning(outer, b, c):
    bf = float(F(b))
    xc = poly([(1, "x"), (c, "")])
    inner = "log_{%s} (%s)" % (t(F(b)), xc)
    if F(b) < 1:
        lo, hi = -c, 1 - c
        marks, seg, pt = [lo, hi], [0, 1, 0], [0, 0]
        o2 = ["0 < %s < 1" % xc, "%s > 1" % xc, "%s > 0" % xc, "%s < 0" % xc]
        h2 = "底數 %s < 1：真數在 0 和 1 之間，值才是正的" % t(F(b))
        w2 = "0 < %s < 1" % xc
        ans = "%s < x < %s" % (t(lo), t(hi))
    else:
        lo = 1 - c
        marks, seg, pt = [-c, lo], [0, 0, 1], [0, 0]
        o2 = ["%s > 1" % xc, "0 < %s < 1" % xc, "%s > 0" % xc, "%s > %s" % (xc, t(F(b)))]
        h2 = "底數 %s > 1：真數大於 1，值才是正的" % t(F(b))
        w2 = "%s > 1" % xc
        ans = "x > %s" % t(lo)
    cond = lambda x: x + c > 0 and lg(bf, x + c) > 1e-12
    check_line(cond, marks, seg, pt)
    return item("l_meaning", "line", 2, "有意義的範圍", 1.0,
                "若 log_{%d} [%s] 有意義，求 x 的範圍。" % (outer, inner),
                [ch("外層的 log_{%d} 要有意義，需要？" % outer, ["%s > 0" % inner, "%s > 1" % inner, "%s > 0" % xc, "%s ≥ 0" % inner],
                    "外層的真數必須大於 0", "%s > 0" % inner),
                 ch("%s > 0 代表？" % inner, o2, h2, w2),
                 LN("封印 x 的範圍。", "解", marks, seg, pt, "答：" + ans)])


# ---------- l_quad3：A b^{2x} − K b^x + C < 0 ----------

def l_quad3(b, A, f1, f2, e1, e2):
    """(a1 t + c1)(a2 t + c2) < 0，兩根 b^{e1} < b^{e2}"""
    (a1, c1), (a2, c2) = f1, f2
    A_ = a1 * a2
    K = -(a1 * c2 + a2 * c1)
    C = c1 * c2
    assert A_ == A
    t1, t2 = F(b) ** e1, F(b) ** e2
    assert sorted([F(-c1, a1), F(-c2, a2)]) == [t1, t2]
    sq = b * b
    Ac = "" if A == 1 else str(A) + " · "
    stem = "%s%d^{x} − %d · %d^{x} + %d < 0" % (Ac, sq, K, b, C)
    cond = lambda x: A * sq ** x - K * b ** x + C < 0
    check_line(cond, [e1, e2], [0, 1, 0], [0, 0])
    tq = quad_t(A, -K, C, "t")
    opts = uniq([tq + " < 0"], [quad_t(A, -K, -C, "t") + " < 0", quad_t(A, K, C, "t") + " < 0", "%st − %dt + %d < 0" % ("" if A == 1 else str(A), K, C)])
    return item("l_quad3", "line", 3, "換元不等式", 1.15, "解不等式 %s。" % stem,
                [ch("令 t = %d^{x}，不等式變成？" % b, opts, "%d^{x} = (%d^{x})^{2} = t^{2}" % (sq, b),
                    "%s < 0　→　%s < t < %s" % (tq, t(t1), t(t2)), pre="令 t = %d^{x}（t > 0）" % b),
                 ch("%s < %d^{x} < %s，所以？" % (t(t1), b, t(t2)),
                    uniq(["%d < x < %d" % (e1, e2)], ["%s < x < %s" % (t(t1), t(t2)), "%d < x < %d" % (e1, e2 + 1), "%d < x < %d" % (e1 + 1, e2), "%d < x < %d" % (e1 - 1, e2)]),
                    "%s = %d^{%d}，%s = %d^{%d}" % (t(t1), b, e1, t(t2), b, e2), "%d^{%d} < %d^{x} < %d^{%d}　→　%d < x < %d" % (b, e1, b, b, e2, e1, e2)),
                 LN("封印 x 的範圍。", "解", [e1, e2], [0, 1, 0], [0, 0], "答：%d < x < %d" % (e1, e2))])


# ---------- l_basecond：log_x (−x² + Sx + P) ----------

def l_basecond(r1, r2):
    S, P = r1 + r2, -r1 * r2
    arg = quad_t(-1, S, P)
    cond_b = lambda x: x > 0 and x != 1
    cond_a = lambda x: -x * x + S * x + P > 0
    marks = [r1, 0, 1, r2]
    check_line(cond_b, marks, [0, 0, 1, 1, 1], [0, 0, 0, 1])
    check_line(cond_a, marks, [0, 1, 1, 1, 0], [0, 1, 1, 0])
    ints = [x for x in range(-20, 20) if cond_b(x) and cond_a(x)]
    n = len(ints)
    assert n == r2 - 2
    return item("l_basecond", "line", 3, "底數與真數", 1.25,
                "若 log_{x} (%s) 有意義，滿足條件的整數 x 共有幾個？" % arg,
                [LN("底數條件：x > 0 且 x ≠ 1。", "底數", marks, [0, 0, 1, 1, 1], [0, 0, 0, 1], "底數：x > 0 且 x ≠ 1"),
                 ch("真數條件：%s > 0，兩邊乘 −1：" % arg, uniq([quad_t(1, -S, -P) + " < 0"], [quad_t(1, -S, -P) + " > 0", quad_t(1, S, -P) + " < 0", quad_t(1, -S, P) + " < 0"]),
                    "乘上負數，不等號要反向", "%s < 0　→　%d < x < %d" % (quad_t(1, -S, -P), r1, r2)),
                 LN("封印真數條件 %d < x < %d。" % (r1, r2), "真數", marks, [0, 1, 1, 1, 0], [0, 1, 1, 0]),
                 LN("兩個條件同時成立。", "同時", marks, [0, 0, 1, 1, 0], [0, 0, 0, 0], "0 < x < %d 且 x ≠ 1" % r2),
                 fl("0 < x < %d 且 x ≠ 1 的整數有幾個？" % r2, "答：整數 x 共 [0] 個", [str(n)], "1 到 %d 裡面，整數 1 不行（底數不能是 1）" % (r2 - 1),
                    write="（x = %s）" % "、".join(str(x) for x in ints))])


def items():
    return [
        [l_flip(F(1, 2), 1, 5), l_flip(F(1, 5), -2, 6), l_flip(3, 2, 10)],
        [l_expineq(c) for c in EXPINEQ],
        [l_twolog(F(1, 2), 1, 2, 6, -1, 4), l_twolog(F(1, 2), 1, 3, 8, -1, 5), l_twolog(F(1, 3), 2, 4, 3, 1, 5)],
        [l_meaning(2, F(1, 2), 1), l_meaning(3, 2, -1), l_meaning(2, F(1, 3), -2)],
        [l_quad3(3, 1, (1, -1), (1, -9), 0, 2), l_quad3(2, 1, (1, -2), (1, -8), 1, 3), l_quad3(2, 2, (2, -1), (1, -4), -1, 2)],
        [l_basecond(-1, 6), l_basecond(-2, 5), l_basecond(-3, 7)],
    ]


# ================= 擴充（2026/11/09） =================

# ---------- l_exp1：同底數比指數 ----------

def l_exp1(cfg):
    m = cfg["m"]
    check_line(cfg["cond"], [m], cfg["seg"], cfg["pt"])
    return item("l_exp1", "line", 1, "同底數比指數", 1.0, "解不等式 %s。" % cfg["stem"],
                [ch(cfg["q1"], cfg["o1"], cfg["h1"], cfg["w1"]),
                 ch("比較指數，得到？", cfg["o2"], cfg["h2"], cfg["w2"]),
                 LN("封印解的範圍（注意等號）。", "解", [m], cfg["seg"], cfg["pt"], "答：" + cfg["ans"])])


EXP1 = [
    {"stem": "3^{x − 1} > 1/9", "m": -1, "seg": [0, 1], "pt": [0], "cond": lambda x: 3 ** (x - 1) > 1 / 9 * (1 + 1e-12),
     "q1": "右邊寫成 3 的次方：", "o1": ["3^{−2}", "3^{2}", "9^{−1}", "3^{−1/2}"], "h1": "1/9 = 1/3^{2}", "w1": "3^{x − 1} > 3^{−2}",
     "o2": ["x − 1 > −2", "x − 1 < −2", "x − 1 > 2", "x − 1 < 2"], "h2": "底數 3 > 1，不等號方向不變", "w2": "x − 1 > −2　→　x > −1", "ans": "x > −1"},
    {"stem": "(1/2)^{2x − 1} ≤ 8", "m": -1, "seg": [0, 1], "pt": [1], "cond": lambda x: 0.5 ** (2 * x - 1) <= 8 * (1 + 1e-12),
     "q1": "右邊寫成 1/2 的次方：", "o1": ["(1/2)^{−3}", "(1/2)^{3}", "2^{3}", "(1/2)^{8}"], "h1": "8 = 2^{3} = (1/2)^{−3}", "w1": "(1/2)^{2x − 1} ≤ (1/2)^{−3}",
     "o2": ["2x − 1 ≥ −3", "2x − 1 ≤ −3", "2x − 1 ≥ 3", "2x − 1 ≤ 3"], "h2": "底數 1/2 < 1，不等號要反向", "w2": "2x − 1 ≥ −3　→　x ≥ −1", "ans": "x ≥ −1"},
    {"stem": "25^{x} < 5^{3 − x}", "m": 1, "seg": [1, 0], "pt": [0], "cond": lambda x: 25 ** x < 5 ** (3 - x) * (1 - 1e-12),
     "q1": "左邊寫成 5 的次方：", "o1": ["5^{2x}", "5^{x + 2}", "5^{x^{2}}", "5^{x/2}"], "h1": "25 = 5^{2}，(5^{2})^{x} = 5^{2x}", "w1": "5^{2x} < 5^{3 − x}",
     "o2": ["2x < 3 − x", "2x > 3 − x", "x + 2 < 3 − x", "2x < 3 + x"], "h2": "底數 5 > 1，不等號方向不變", "w2": "2x < 3 − x　→　x < 1", "ans": "x < 1"},
]


# ---------- l_logrange：拿掉 log 再加上定義域 ----------

def l_logrange(cfg):
    lo, hi = cfg["lo"], cfg["hi"]
    check_line(cfg["dom"], [lo, hi], [0, 1, 1], [0, 1])
    check_line(cfg["cond"], [lo, hi], [0, 1, 0], [0, cfg["hi_pt"]])
    return item("l_logrange", "line", 2, "對數不等式", 1.1, "解不等式 %s。" % cfg["stem"],
                [LN("先封印定義域：真數 > 0。", "定義域", [lo, hi], [0, 1, 1], [0, 1], "定義域：x > %s" % t(F(lo))),
                 ch(cfg["q2"], cfg["o2"], cfg["h2"], cfg["w2"]),
                 LN("和定義域取交集，封印最後的解。", "解", [lo, hi], [0, 1, 0], [0, cfg["hi_pt"]], "答：" + cfg["ans"])])


LOGRANGE = [
    {"stem": "log_{2} (x − 1) < 3", "lo": 1, "hi": 9, "hi_pt": 0, "dom": lambda x: x > 1, "cond": lambda x: x > 1 and lg(2, x - 1) < 3 - 1e-12,
     "q2": "拿掉 log：", "o2": ["x − 1 < 8", "x − 1 > 8", "x − 1 < 6", "x − 1 < 3"], "h2": "底數 2 > 1，方向不變；3 = log_{2} 8",
     "w2": "x − 1 < 2^{3} = 8　→　x < 9", "ans": "1 < x < 9"},
    {"stem": "log_{3} (2x + 1) ≤ 2", "lo": F(-1, 2), "hi": 4, "hi_pt": 1, "dom": lambda x: 2 * x + 1 > 0, "cond": lambda x: 2 * x + 1 > 0 and lg(3, 2 * x + 1) <= 2 + 1e-12,
     "q2": "拿掉 log：", "o2": ["2x + 1 ≤ 9", "2x + 1 ≥ 9", "2x + 1 ≤ 6", "2x + 1 ≤ 8"], "h2": "底數 3 > 1，方向不變；2 = log_{3} 9",
     "w2": "2x + 1 ≤ 3^{2} = 9　→　x ≤ 4", "ans": "−1/2 < x ≤ 4"},
    {"stem": "log_{1/2} (x + 2) > −2", "lo": -2, "hi": 2, "hi_pt": 0, "dom": lambda x: x + 2 > 0, "cond": lambda x: x + 2 > 0 and lg(0.5, x + 2) > -2 + 1e-12,
     "q2": "拿掉 log：", "o2": ["x + 2 < 4", "x + 2 > 4", "x + 2 < 1/4", "x + 2 > 1/4"], "h2": "底數 1/2 < 1，不等號要反向；−2 = log_{1/2} 4",
     "w2": "x + 2 < (1/2)^{−2} = 4　→　x < 2", "ans": "−2 < x < 2"},
]


# ---------- l_logquad：對數的二次不等式 ----------

def l_logquad(b, c1, c0, op, r1, r2):
    """u² + c1 u + c0 op 0，u = log_b x，兩根 r1 < r2"""
    assert r1 + r2 == -c1 and r1 * r2 == c0 and r1 < r2
    x1, x2 = F(b) ** r1, F(b) ** r2
    inside = op in ("<", "≤")
    eqv = lambda u: (u * u + c1 * u + c0 < 0) if op == "<" else (u * u + c1 * u + c0 <= 1e-12 if op == "≤" else u * u + c1 * u + c0 > 0)
    cond = lambda x: x > 0 and eqv(lg(b, x))
    eq_ = op in ("≤",)
    if inside:
        marks, seg, pt = [x1, x2], [0, 1, 0], [1 if eq_ else 0] * 2
        urange = "%d %s u %s %d" % (r1, "≤" if eq_ else "<", "≤" if eq_ else "<", r2)
        xr = "%s %s x %s %s" % (t(x1), "≤" if eq_ else "<", "≤" if eq_ else "<", t(x2))
        o2 = [urange, "u < %d 或 u > %d" % (r1, r2), "%d < u < %d" % (r1 - 1, r2), "u > %d" % r2]
    else:
        marks, seg, pt = [0, x1, x2], [0, 1, 0, 1], [0, 0, 0]
        urange = "u < %d 或 u > %d" % (r1, r2)
        xr = "0 < x < %s 或 x > %s" % (t(x1), t(x2))
        o2 = [urange, "%d < u < %d" % (r1, r2), "u > %d" % r2, "u < %d" % r1]
    check_line(cond, marks, seg, pt, -5.0, 60.0)
    lb = "log_{%d}" % b
    stem = "(%s x)^{2}%s%s %s 0" % (lb, cof(c1, "%s x" % lb).replace(" " + lb, lb) if False else (" − %s%s x" % ("" if c1 == -1 else str(-c1) + " ", lb) if c1 < 0 else " + %s%s x" % ("" if c1 == 1 else str(c1) + " ", lb)),
                                   (" + %d" % c0) if c0 > 0 else " − %d" % -c0, op)
    qeq = quad_t(1, c1, c0, "u") + " %s 0" % op
    return item("l_logquad", "line", 3, "對數的二次不等式", 1.2, "解不等式 %s。" % stem,
                [ch("令 u = %s x（x > 0），不等式變成？" % lb, uniq([qeq], [quad_t(1, -c1, c0, "u") + " %s 0" % op, quad_t(1, c1, -c0, "u") + " %s 0" % op,
                                                                  quad_t(2, c1, c0, "u") + " %s 0" % op]),
                    "(%s x)^{2} = u^{2}" % lb, "%s　→　%s" % (qeq, urange), pre="定義域：x > 0"),
                 ch("u 的範圍是？", o2, "兩根 %d、%d，開口向上，%s" % (r1, r2, "小於 0 在兩根中間" if inside else "大於 0 在兩根外面"), urange),
                 fl("換回 x = %d^{u}：" % b, "u = %d 時 x = [0]，u = %d 時 x = [1]" % (r1, r2), [a(x1), a(x2)], "%d^{%d}、%d^{%d}" % (b, r1, b, r2)),
                 LN("底數 %d > 1，方向不變。和定義域 x > 0 一起封印 x 的範圍。" % b, "解", marks, seg, pt, "答：" + xr)])


_items0 = items


def items():
    return _items0() + [
        [l_exp1(c) for c in EXP1],
        [l_logrange(c) for c in LOGRANGE],
        [l_logquad(2, -3, 2, "<", 1, 2), l_logquad(3, -1, -2, "≤", -1, 2), l_logquad(2, -2, -3, ">", -1, 3)],
    ]
