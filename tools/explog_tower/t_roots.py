# 驗根之刃
from elib import *


def DOM(opts, hint, write):
    return ch("先找出定義域（真數 > 0，底數 > 0 且 ≠ 1）：", opts, hint, write)


def R(cands, q, write):
    return step("roots", q=q, cands=[{"v": v, "ok": ok, "why": w} for v, ok, w in cands], write=write)


def fac_pair(r1, r2, v="x"):
    """(x − r1)(x − r2)：整數根"""
    return "(%s)(%s)" % (poly([(1, v), (-r1, "")]), poly([(1, v), (-r2, "")]))


# ---------- r_logsum：log (x − a) + log x = k ----------

def r_logsum(b, k, p, q):
    """根 p（合）、−q（不合）：x(x − a) = b^k，a = p − q"""
    N = b ** k
    assert p * q == N and p > q > 0
    a_ = p - q
    lb = logb(b)
    assert abs(lg(b, p - a_) + lg(b, p) - k) < 1e-9
    rhs = str(k)
    return item("r_logsum", "roots", 1, "對數方程式", 1.0,
                "解方程式 %s (x − %d) + %s x = %s。" % (lb, a_, lb, rhs),
                [DOM(["x > %d" % a_, "x > 0", "0 < x < %d" % a_, "x > −%d" % a_], "x − %d > 0 且 x > 0，兩個都要成立" % a_, "定義域：x > %d" % a_),
                 ch("兩個 log 相加，先合併成？", ["%s [x(x − %d)] = %s" % (lb, a_, rhs), "%s (2x − %d) = %s" % (lb, a_, rhs),
                                         "%s x · %s (x − %d) = %s" % (lb, lb, a_, rhs), "%s [(x − %d)/x] = %s" % (lb, a_, rhs)],
                    "log M + log N = log MN", "%s [x(x − %d)] = %s" % (lb, a_, rhs)),
                 fl("拿掉 log：x(x − %d) 等於多少？" % a_, "x(x − %d) = [0]" % a_, [str(N)],
                    "%s N = %d 代表 N = %d^{%d}" % (lb, k, b, k)),
                 ch("展開、移項：", uniq([quad_t(1, -a_, -N) + " = 0"], [quad_t(1, -a_, N) + " = 0", quad_t(1, a_, -N) + " = 0", quad_t(1, -N, -a_) + " = 0"]),
                    "x(x − %d) = x^{2} − %dx，再把 %d 移到左邊" % (a_, a_, N), "%s = 0　→　%s = 0" % (quad_t(1, -a_, -N), fac_pair(p, -q))),
                 R([("x = %d" % p, True, "%s %d + %s %d = %d ✓" % (lb, p - a_, lb, p, k)), ("x = −%d" % q, False, "%s (−%d) 真數是負的，沒有意義" % (lb, q + a_))],
                   "和定義域 x > %d 比對，把不合的根劃掉。" % a_, "答：x = %d" % p)])


# ---------- r_sub2：b^{2x} + c · b^{x + s} − N = 0 ----------

def r_sub2(b, cs, s, N, root, bad):
    """t² + K t − N = 0，K = cs · b^s；根 t = root（= b^x）和 bad（負）"""
    K = cs * b ** s
    assert root * bad == -N and root + bad == -K and bad < 0 < root
    x = round(math.log(root, b))
    assert b ** x == root
    sq = b * b
    term = ("%s^{x + %d}" % (b, s)) if s > 1 else "%s^{x + 1}" % b
    co = "" if abs(cs) == 1 else str(abs(cs)) + " · "
    stem_eq = "%d^{x} %s %s%s − %d = 0" % (sq, "+" if cs > 0 else "−", co, term, N)
    return item("r_sub2", "roots", 1, "指數換元", 1.0, "解方程式 %s。" % stem_eq,
                [ch("令 t = %d^{x}，方程式變成？" % b,
                    uniq([quad_t(1, K, -N, "t") + " = 0"], [quad_t(1, cs, -N, "t") + " = 0", quad_t(1, -K, -N, "t") + " = 0",
                                                            "t^{2} %s %d^{t} − %d = 0" % ("+" if K > 0 else "−", abs(K), N)]),
                    "%d^{x} = (%d^{x})^{2} = t^{2}，%s = %d · %d^{x} = %dt" % (sq, b, term, b ** s, b, b ** s),
                    "%s = 0　→　(t %s %d)(t − %d) = 0" % (quad_t(1, K, -N, "t"), "+", -bad, root),
                    pre="令 t = %d^{x}（t > 0）" % b),
                 R([("t = %d" % root, True, "%d^{x} = %d 可以做到" % (b, root)), ("t = %d" % bad, False, "t = %d^{x} 一定大於 0" % b)],
                   "t 的兩個解，哪個不合？劃掉它。", "t = %d 不合（t > 0）　→　%d^{x} = %d" % (bad, b, root)),
                 fl("%d^{x} = %d，所以 x = ？" % (b, root), "答：x = [0]", [str(x)], "%d = %d^{%d}" % (root, b, x))])


# ---------- r_logsq：(log_b x)^2 − log_b x^m + c = 0 ----------

def r_logsq(b, m, c, u1, u2):
    assert u1 + u2 == m and u1 * u2 == c
    lb = logb(b)
    xs = [F(b) ** u for u in (u1, u2)]
    for u, x in zip((u1, u2), xs):
        assert abs(lg(b, float(x)) ** 2 - m * lg(b, float(x)) + c) < 1e-9
    cterm = ("+ %d" % c) if c > 0 else ("− %d" % -c)
    stem = "(%s x)^{2} − %s x^{%d} %s = 0" % (lb, lb, m, cterm)
    opts = uniq([quad_t(1, -m, c, "u") + " = 0"], ["u^{2} − u^{%d} %s = 0" % (m, cterm), "u^{2} − %d %s = 0" % (m, cterm),
                                                  "2u − %du %s = 0" % (m, cterm), quad_t(1, m, c, "u") + " = 0"])
    ut = lambda u: ("u = %d" % u)
    xw = lambda u, x: "x = %d^{%d} = %s" % (b, u, t(x))
    return item("r_logsq", "roots", 2, "對數換元", 1.0, "解方程式 %s。" % stem,
                [DOM(["x > 0", "x ≠ 0", "x > 1", "全體實數"], "%s x 的真數 x > 0" % lb, "定義域：x > 0"),
                 ch("令 u = %s x，方程式變成？" % lb, opts, "%s x^{%d} = %d %s x = %du" % (lb, m, m, lb, m),
                    "%s = 0　→　u = %d 或 u = %d" % (quad_t(1, -m, c, "u"), u1, u2), pre="%s x^{%d} = %d %s x，令 u = %s x" % (lb, m, m, lb, lb)),
                 R([("x = %s" % t(xs[0]), True, "x > 0，代回成立"), ("x = %s" % t(xs[1]), True, "x > 0，代回成立" if u2 >= 0 else "u 是負的沒關係，x = %s > 0" % t(xs[1]))],
                   "換回 x（x = %d^{u}），和定義域 x > 0 比對：有沒有不合的根？（沒有就直接確認）" % b,
                   "%s、%s，都 > 0　→　答：x = %s 或 x = %s" % (xw(u1, xs[0]), xw(u2, xs[1]), t(xs[0]), t(xs[1])))])


# ---------- r_base：log_x (px + q) = 2 ----------

def r_base(p, q):
    r = sorted([(p + math.sqrt(p * p + 4 * q)) / 2, (p - math.sqrt(p * p + 4 * q)) / 2], reverse=True)
    r1, r2 = [round(v) for v in r]
    assert r1 * r1 == p * r1 + q and r2 * r2 == p * r2 + q
    arg = poly([(p, "x"), (q, "")])
    lim = F(-q, p)
    if q > 0:
        dom, dh = "x > 0 且 x ≠ 1", "底數 x > 0 且 x ≠ 1，這時 %s > 0 自動成立" % arg
        dopts = [dom, "x > %s" % t(lim), "x > 0", "x ≠ 1"]
    else:
        dom, dh = "x > %s 且 x ≠ 1" % t(lim), "底數 x > 0 且 x ≠ 1，真數 %s > 0 ⇒ x > %s" % (arg, t(lim))
        dopts = [dom, "x > 0 且 x ≠ 1", "x > %s" % t(lim), "x ≠ 1"]
    ok = lambda x: x > 0 and x != 1 and p * x + q > 0
    bad = r2
    assert ok(r1) and not ok(bad)
    why_bad = "底數必須大於 0 且不等於 1" if bad <= 0 or bad == 1 else ""
    if bad == 1:
        why_bad = "底數不能是 1（log_{1} 沒有意義）"
    cands = [("x = %d" % r1, True, "log_{%d} %d = 2 ✓" % (r1, r1 * r1)), ("x = %d" % bad, False, why_bad)]
    return item("r_base", "roots", 2, "底數陷阱", 1.0, "解方程式 log_{x} (%s) = 2。" % arg,
                [DOM(dopts, dh, "定義域：" + dom),
                 ch("依照對數的定義，改寫成？", ["x^{2} = %s" % arg, "2^{x} = %s" % arg, "%s = 2x" % arg, "x = (%s)^{2}" % arg],
                    "log_{a} N = k 代表 a^{k} = N", "x^{2} = %s" % arg),
                 ch("移項：", uniq([quad_t(1, -p, -q) + " = 0"], [quad_t(1, p, -q) + " = 0", quad_t(1, -p, q) + " = 0", quad_t(1, p, q) + " = 0"]),
                    "%s 整個移到左邊要變號" % arg, "%s = 0　→　%s = 0" % (quad_t(1, -p, -q), fac_pair(r1, r2))),
                 R(cands, "和定義域比對（底數也有條件！），把不合的根劃掉。", "答：x = %d" % r1)])


# ---------- r_diff：log_b (x + c) + log_b (x − c) = k ----------

def r_diff(b, c, k):
    N = b ** k
    r = math.isqrt(N + c * c)
    assert r * r == N + c * c and r > c
    lb = logb(b)
    return item("r_diff", "roots", 2, "真數檢查", 1.0, "解方程式 %s (x + %d) + %s (x − %d) = %d。" % (lb, c, lb, c, k),
                [DOM(["x > %d" % c, "x > −%d" % c, "−%d < x < %d" % (c, c), "x > 0"], "x + %d > 0 且 x − %d > 0，取比較嚴格的" % (c, c), "定義域：x > %d" % c),
                 ch("合併之後得到？", uniq(["x^{2} − %d = %d" % (c * c, N)], ["x^{2} − %d = %d" % (c * c, k), "2x = %d" % N, "x^{2} − %d = %d" % (c * c, b * k), "x^{2} − %d = %d" % (c, N)]),
                    "(x + %d)(x − %d) = %d^{%d}" % (c, c, b, k), "%s [(x + %d)(x − %d)] = %d　→　x^{2} − %d = %d　→　x = ±%d" % (lb, c, c, k, c * c, N, r)),
                 R([("x = %d" % r, True, "%s %d + %s %d = %d ✓" % (lb, r + c, lb, r - c, k)), ("x = −%d" % r, False, "x − %d = −%d，真數是負的" % (c, r + c))],
                   "和定義域 x > %d 比對，把不合的根劃掉。" % c, "答：x = %d" % r)])


# ---------- r_pq：a · 4^x − K · 2^x + c = 0 的兩根 p、q ----------

def r_pq(A, s, c, f1, f2):
    """A t² − K t + c，K = 2^s；因式 f1 = (a1, c1)、f2 = (a2, c2)：(a1 t + c1)(a2 t + c2)"""
    K = 2 ** s
    (a1, c1), (a2, c2) = f1, f2
    assert a1 * a2 == A and a1 * c2 + a2 * c1 == -K and c1 * c2 == c
    t1, t2 = F(-c1, a1), F(-c2, a2)
    assert t1 > 0 and t2 > 0
    prod = t1 * t2
    v8 = prod ** 3
    assert prod == F(c, A)
    opts = uniq([quad_t(A, -K, c, "t") + " = 0"], [quad_t(A, -2, c, "t") + " = 0", "%dt − %dt + %d = 0" % (A, K, c), quad_t(4 * A, -K, c, "t") + " = 0",
                                                    quad_t(A, -K // 2, c, "t") + " = 0"])
    Ac = "" if A == 1 else "%d · " % A
    return item("r_pq", "roots", 3, "兩根的和", 1.15,
                "方程式 %s4^{x} − 2^{x + %d} + %d = 0 的兩根為 p、q，求 8^{p + q}。" % (Ac, s, c),
                [ch("令 t = 2^{x}，方程式變成？", opts, "2^{x + %d} = %d · 2^{x} = %dt" % (s, K, K),
                    "%s = 0　→　%s = 0" % (quad_t(A, -K, c, "t"), fac_t(a1, c1, a2, c2)), pre="令 t = 2^{x}（t > 0），4^{x} = (2^{x})^{2} = t^{2}"),
                 R([("t = %s" % t(t2), True, "t > 0 就可以"), ("t = %s" % t(t1), True, "分數也大於 0，可以" if not isint(t1) else "t > 0 就可以")],
                   "兩個 t 都要檢查：哪個不合？（都合就直接確認）", "兩個 t 就是 2^{p}、2^{q}"),
                 fl("兩根相乘，指數相加：", "2^{p} · 2^{q} = %s × %s　→　2^{p + q} = [0]" % (t(t2), t(t1)), [a(prod)],
                    "同底數相乘，指數相加：2^{p} · 2^{q} = 2^{p + q}"),
                 fl("把 8 寫成 2 的次方，求 8^{p + q}：", "答：8^{p + q} = (2^{p + q})^{[0]} = [1]", ["3", a(v8)], "8 = 2^{3}，而 2^{p + q} = %s" % t(prod))])


# ---------- r_xlog：x^{log x} = 10^k x^m ----------

def r_xlog(k, m, u1, u2):
    assert u1 + u2 == m and u1 * u2 == -k
    xs = [F(10) ** u for u in (u1, u2)]
    for x in xs:
        lx = math.log10(float(x))
        assert abs(lx * lx - (k + m * lx)) < 1e-9
    rhs = ("%d" % 10 ** k if k <= 3 else "10^{%d}" % k) + ("x" if m == 1 else "x^{%d}" % m)
    logr = "%d + %slog x" % (k, "" if m == 1 else "%d " % m)
    corr = "u^{2} = %d + %su" % (k, "" if m == 1 else str(m))
    opts = uniq([corr], ["u^{2} = %du" % (10 ** k) if k <= 3 else "u^{2} = %d" % k, "2u = %d + %su" % (k, "" if m == 1 else str(m)),
                         "u = %d + %su" % (k, "" if m == 1 else str(m)), "u^{2} = %du" % (k * m)])
    xt = lambda u, x: "x = 10^{%d} = %s" % (u, t(x))
    return item("r_xlog", "roots", 3, "取對數", 1.15, "解方程式 x^{log x} = %s。" % rhs,
                [DOM(["x > 0", "x ≠ 0", "x > 1", "全體實數"], "次方裡有 log x，x 要 > 0", "定義域：x > 0"),
                 ch("兩邊取 log，令 u = log x，得到？", opts, "log x^{log x} = (log x)(log x)，log %s = %s" % (rhs, logr),
                    "%s = 0　→　u = %d 或 u = %d" % (quad_t(1, -m, -k, "u"), u1, u2), pre="兩邊取 log：log x^{log x} = log (%s)" % rhs),
                 R([("x = %s" % t(xs[0]), True, "代回兩邊都是 10^{%d} ✓" % (u1 * u1)),
                    ("x = %s" % t(xs[1]), True, "u = %d 是負的沒關係，x = 10^{%d} > 0，代回成立" % (u2, u2))],
                   "換回 x（x = 10^{u}），和定義域 x > 0 比對：有沒有不合的根？",
                   "%s、%s，都 > 0　→　答：x = %s 或 x = %s" % (xt(u1, xs[0]), xt(u2, xs[1]), t(xs[0]), t(xs[1])))])


def items():
    return [
        [r_logsum(10, 1, 10, 1), r_logsum(10, 1, 5, 2), r_logsum(2, 3, 4, 2)],
        [r_sub2(2, 1, 1, 24, 4, -6), r_sub2(3, -1, 1, 54, 9, -6), r_sub2(2, -1, 2, 32, 8, -4)],
        [r_logsq(2, 3, 2, 1, 2), r_logsq(3, 4, 3, 1, 3), r_logsq(2, 2, -3, 3, -1)],
        [r_base(2, 3), r_base(1, 6), r_base(5, -4)],
        [r_diff(2, 1, 3), r_diff(3, 4, 2), r_diff(2, 2, 5)],
        [r_pq(3, 3, 4, (3, -2), (1, -2)), r_pq(3, 3, 5, (3, -5), (1, -1)), r_pq(5, 4, 3, (5, -1), (1, -3))],
        [r_xlog(2, 1, 2, -1), r_xlog(6, 1, 3, -2), r_xlog(3, 2, 3, -1)],
    ]


# ================= 擴充（2026/11/09） =================

# ---------- r_abs：絕對值的真數 ----------

def r_abs(b, c, k):
    N = b ** k
    x1, x2 = c + N, c - N
    lb = logb(b)
    xc = poly([(1, "x"), (-c, "")])
    for x in (x1, x2):
        assert abs(lg(b, abs(x - c)) - k) < 1e-9
    return item("r_abs", "roots", 1, "絕對值的真數", 1.0, "解方程式 %s |%s| = %d。" % (lb, xc, k),
                [DOM(["x ≠ %s" % t(c), "x > %s" % t(c), "x > 0", "全體實數"], "真數 |%s| > 0，只要 %s ≠ 0" % (xc, xc), "定義域：x ≠ %s" % t(c)),
                 fl("拿掉 log：", "|%s| = [0]" % xc, [str(N)], "%s N = %d 代表 N = %d^{%d}" % (lb, k, b, k)),
                 ch("絕對值拆開：", ["%s = %d 或 %s = −%d" % (xc, N, xc, N), "%s = %d" % (xc, N), "%s = ±%d^{2}" % (xc, N), "x = ±%d" % N],
                    "|A| = N 代表 A = N 或 A = −N", "%s = ±%d　→　x = %s 或 x = %s" % (xc, N, t(x1), t(x2))),
                 R([("x = %s" % t(x1), True, "x ≠ %s，代回成立" % t(c)), ("x = %s" % t(x2), True, "絕對值裡是負的沒關係：|%s| = %d" % (t(x2 - c), N))],
                   "和定義域比對：有沒有不合的根？（沒有就直接確認）", "答：x = %s 或 x = %s" % (t(x1), t(x2)))])


# ---------- r_chain：底數是次方 ----------

def r_chain(b, m, k):
    u = F(k * m, m + 1)
    assert isint(u)
    u = int(u)
    x = b ** u
    assert abs(lg(b, x) + lg(b ** m, x) - k) < 1e-9
    bm = b ** m
    return item("r_chain", "roots", 1, "換成同底數", 1.0, "解方程式 log_{%d} x + log_{%d} x = %d。" % (b, bm, k),
                [DOM(["x > 0", "x ≠ 0", "x > 1", "全體實數"], "真數 x > 0", "定義域：x > 0"),
                 ch("log_{%d} x 換成以 %d 為底：" % (bm, b), ["(1/%d) log_{%d} x" % (m, b), "%d log_{%d} x" % (m, b), "log_{%d} x − %d" % (b, m), "log_{%d} (x/%d)" % (b, m)],
                    "%d = %d^{%d}，log_{a^{m}} x = (1/m) log_{a} x" % (bm, b, m), "log_{%d} x = (1/%d) log_{%d} x" % (bm, m, b)),
                 fl("令 u = log_{%d} x：u + u/%d = %d。" % (b, m, k), "u = [0]", [str(u)], "(%d/%d)u = %d" % (m + 1, m, k)),
                 fl("換回 x：", "答：x = %d^{%d} = [0]" % (b, u), [str(x)], "u = log_{%d} x 代表 x = %d^{u}" % (b, b))])


# ---------- r_recip：互為倒數 ----------

def r_recip(b, k, c, u1, u2):
    assert u1 + u2 == c and u1 * u2 == -k and u1 > 0 > u2
    xs = [F(b) ** u for u in (u1, u2)]
    for x in xs:
        x = float(x)
        assert abs(lg(b, x) - k * lg(x, b) - c) < 1e-9
    kc = "" if k == 1 else "%d " % k
    stem = "log_{%d} x − %slog_{x} %d = %d" % (b, kc, b, c)
    eqt = quad_t(1, -c, -k, "u") + " = 0"
    return item("r_recip", "roots", 2, "互為倒數", 1.1, "解方程式 %s。" % stem,
                [DOM(["x > 0 且 x ≠ 1", "x > 0", "x ≠ 1", "x > 1"], "log_{x} 的底數 x > 0 而且 x ≠ 1", "定義域：x > 0 且 x ≠ 1"),
                 ch("log_{x} %d 和 log_{%d} x 的關係：" % (b, b), ["log_{x} %d = 1/log_{%d} x" % (b, b), "log_{x} %d = −log_{%d} x" % (b, b),
                                                          "log_{x} %d = log_{%d} x" % (b, b), "log_{x} %d = %d log_{%d} x" % (b, b, b)],
                    "換底：log_{x} %d = log %d/log x" % (b, b), "令 u = log_{%d} x，log_{x} %d = 1/u" % (b, b)),
                 ch("u − %s/u = %d，兩邊乘 u：" % (str(k), c), uniq([eqt], [quad_t(1, -c, k, "u") + " = 0", quad_t(1, c, -k, "u") + " = 0", quad_t(1, -k, -c, "u") + " = 0"]),
                    "u ≠ 0（x ≠ 1），可以乘", "%s　→　(%s)(%s) = 0" % (eqt, poly([(1, "u"), (-u1, "")]), poly([(1, "u"), (-u2, "")]))),
                 R([("x = %s" % t(xs[0]), True, "u = %d，x = %d^{%d}" % (u1, b, u1)), ("x = %s" % t(xs[1]), True, "u = %d，x = %d^{%d} > 0 而且 ≠ 1" % (u2, b, u2))],
                   "換回 x，和定義域比對：有沒有不合的根？", "答：x = %s 或 x = %s" % (t(xs[0]), t(xs[1])))])


# ---------- r_ratio：兩種底數 ----------

def r_ratio(p, q, B, C):
    """p^{2x} − B (pq)^x + C q^{2x} = 0；t = (p/q)^x：t² − Bt + C = 0，兩根 1 和 C"""
    assert 1 + C == B
    r = F(p, q)
    stem = "%d^{x} − %d · %d^{x} + %d · %d^{x} = 0" % (p * p, B, p * q, C, q * q)
    f = lambda x: (p * p) ** x - B * (p * q) ** x + C * (q * q) ** x
    x2 = math.log(C) / math.log(float(r))
    assert abs(f(0)) < 1e-9 and abs(f(x2)) < 1e-6
    rt_ = t(r)
    return item("r_ratio", "roots", 3, "兩種底數", 1.15, "解方程式 %s。" % stem,
                [ch("同除以 %d^{x}，令 t = (%s)^{x}：" % (q * q, rt_), ["t^{2} − %dt + %d = 0" % (B, C), "t^{2} − %dt + %d = 0" % (B, q * q), "t − %d + %d = 0" % (B, C),
                                                                "t^{2} + %dt + %d = 0" % (B, C)],
                    "%d^{x}/%d^{x} = (%s)^{2x} = t^{2}，%d^{x}/%d^{x} = (%s)^{x} = t" % (p * p, q * q, rt_, p * q, q * q, rt_),
                    "t^{2} − %dt + %d = 0　→　(t − 1)(t − %d) = 0" % (B, C, C), pre="t = (%s)^{x} > 0" % rt_),
                 R([("t = 1", True, "t > 0"), ("t = %d" % C, True, "t > 0")], "兩個 t 都要檢查：哪個不合？（都合就直接確認）", "t = 1 或 t = %d" % C),
                 fl("(%s)^{x} = 1：" % rt_, "x = [0]", ["0"], "任何正數的 0 次方是 1"),
                 ch("(%s)^{x} = %d，x = ？" % (rt_, C), ["log_{%s} %d" % (rt_, C), "log_{%d} (%s)" % (C, rt_), "%d/(%s)" % (C, rt_), "%d" % C],
                    "a^{x} = N 代表 x = log_{a} N", "答：x = 0 或 x = log_{%s} %d" % (rt_, C))])


_items0 = items


def items():
    return _items0() + [
        [r_abs(2, 1, 2), r_abs(3, -2, 2), r_abs(10, 3, 1)],
        [r_chain(2, 2, 6), r_chain(3, 2, 3), r_chain(2, 3, 8)],
        [r_recip(2, 2, 1, 2, -1), r_recip(3, 6, 1, 3, -2), r_recip(2, 3, 2, 3, -1)],
        [r_ratio(3, 2, 4, 3), r_ratio(2, 3, 3, 2), r_ratio(5, 2, 6, 5)],
    ]
