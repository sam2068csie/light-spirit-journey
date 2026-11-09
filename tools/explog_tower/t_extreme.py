# 極值換元
from elib import *


def vf(h, k, v="t"):
    """(t − h)^{2} + k"""
    h, k = F(h), F(k)
    s = ("%s^{2}" % v) if h == 0 else "(%s)^{2}" % poly([(1, v), (-h, "")])
    if k != 0:
        s += (" + " if k > 0 else " − ") + t(abs(k))
    return s


def gq(a_, b_, c_):
    return "%s*x*x+%s*x+%s" % (repr(float(a_)), repr(float(b_)), repr(float(c_)))


def pl(x):
    return t(F(x))


# ---------- e_basic：b^{2x} − k b^{x + s} + C ----------

def e_basic(b, k, s, C):
    K = k * b ** s
    h = F(K, 2)
    m = round(math.log(h, b))
    assert F(b) ** m == h
    mn = C - h * h
    f = lambda x: b ** (2 * x) - k * b ** (x + s) + C
    assert abs(f(m) - mn) < 1e-9 and min(f(m + d) for d in (-0.3, 0.2, 0.7)) > float(mn)
    sq = b * b
    kc = "" if k == 1 else "%d · " % k
    stem = "%d^{x} − %s%d^{x + %d} + %d" % (sq, kc, b, s, C)
    return item("e_basic", "extreme", 1, "指數二次式", 1.0, "求 f(x) = %s 的最小值，以及此時 x 的值。" % stem,
                [ch("令 t 等於什麼最好算？", ["t = %d^{x}" % b, "t = %d^{x}" % sq, "t = x^{2}", "t = %dx" % b],
                    "%d^{x} 和 %d^{x + %d} 都能用 %d^{x} 表示" % (sq, b, s, b), "令 t = %d^{x}" % b),
                 ch("t 的範圍是？", ["t > 0", "t ≥ 1", "t ≥ 2", "全體實數"], "%d^{x} 可以是任何正數" % b, "t > 0"),
                 ch("f 用 t 表示：", uniq([quad_t(1, -K, C, "t")], [quad_t(1, -k * b, C, "t") if k * b != K else quad_t(1, -K // b, C, "t"), quad_t(1, -K, -C, "t"),
                                                                "%dt − %dt + %d" % (2, K, C), quad_t(1, K, C, "t")]),
                    "%s%d^{x + %d} = %d · %d^{x} = %dt" % (kc, b, s, K, b, K), "f(x) = %s" % quad_t(1, -K, C, "t")),
                 ch("配方：f(x) = ？", uniq([vf(h, mn)], [vf(h, C), vf(K, C), vf(-h, mn), vf(h, mn + 2)]),
                    "t^{2} − %dt = %s − %s" % (K, vf(h, 0), t(h * h)), "f(x) = %s，頂點 t = %s" % (vf(h, mn), t(h))),
                 fl("頂點 t = %s 在 t > 0 裡面。最小值是？" % t(h), "t = %s 時，最小值 [0]" % t(h), [a(mn)], "頂點的值就是配方後的常數項"),
                 fl("此時 x = ？", "答：%d^{x} = %s ⇒ x = [0] 時，最小值 %s" % (b, t(h), t(mn)), [str(m)], "%s = %d^{%d}" % (t(h), b, m))],
                plot={"x": [-1.0, float(h) * 2 + 1.0], "y": [-1.0, float(C) + 2.0], "var": "t",
                      "curves": [{"f": gq(1, -K, C), "c": "orange", "dom": [0.0, 99.0], "at": 3}],
                      "pts": [{"x": float(h), "y": float(mn), "label": "(%s, %s)" % (t(h), t(mn)), "at": 5}], "band": {"lo": 0.0, "at": 2}})


# ---------- e_inside：(b²^x + b²^{−x}) − K(b^x + b^{−x}) + c ----------

def e_inside(b, K, c):
    h = F(K, 2)
    mn = c - 2 - h * h
    assert h >= 2
    sq = b * b
    f = lambda x: sq ** x + sq ** -x - K * (b ** x + b ** -x) + c
    xs = [i / 200 for i in range(-800, 801)]
    assert abs(min(f(x) for x in xs) - mn) < 1e-3
    T = "%d^{x} + %d^{−x}" % (b, b)
    T2 = "%d^{x} + %d^{−x}" % (sq, sq)
    return item("e_inside", "extreme", 2, "頂點在範圍內", 1.1, "求 f(x) = (%s) − %d(%s) + %d 的最小值。" % (T2, K, T, c),
                [ch("令 t 等於什麼？", ["t = %s" % T, "t = %d^{x}" % b, "t = %d^{x}" % sq, "t = %d^{x} − %d^{−x}" % (b, b)],
                    "式子裡一整組 %s 一起出現" % T, "令 t = %s" % T),
                 ch("t 的範圍是？（關鍵！）", ["t ≥ 2", "t > 0", "t ≥ 0", "全體實數"],
                    "算幾不等式：%s ≥ 2√{%d^{x} · %d^{−x}} = 2" % (T, b, b), "t ≥ 2"),
                 ch("%s 用 t 表示：" % T2, ["t^{2} − 2", "t^{2}", "t^{2} + 2", "2t"], "t^{2} = %d^{x} + 2 + %d^{−x}" % (sq, sq), "%s = t^{2} − 2" % T2),
                 ch("代入並配方：f(x) = ？", uniq([vf(h, mn)], [vf(h, mn + 2), vf(K, c - 2 - K * K), vf(-h, mn), vf(h, c)]),
                    "(t^{2} − 2) − %dt + %d = %s" % (K, c, quad_t(1, -K, c - 2, "t")),
                    "f(x) = (t^{2} − 2) − %dt + %d = %s = %s" % (K, c, quad_t(1, -K, c - 2, "t"), vf(h, mn))),
                 fl("頂點 t = %s 在 t ≥ 2 裡面嗎？最小值發生在哪個 t、是多少？" % t(h), "答：t = [0] 時，最小值 [1]", [a(h), a(mn)],
                    "%s ≥ 2，頂點在範圍內，最小值就在頂點" % t(h))],
                plot={"x": [-1.0, float(h) * 2], "y": [-1.0, float(mn) + 7.0], "var": "t",
                      "curves": [{"f": gq(1, -K, c - 2), "c": "orange", "dom": [2.0, 99.0], "at": 4}],
                      "pts": [{"x": float(h), "y": float(mn), "label": "(%s, %s)" % (t(h), t(mn)), "at": 5}], "band": {"lo": 2.0, "at": 2}})


# ---------- e_edge：頂點不在 t ≥ 2 ----------

def e_edge(K, c):
    h = F(-K, 2)
    k0 = c - 2 - h * h
    mn = 4 + 2 * K + c - 2
    assert h < 2
    f = lambda x: 4 ** x + 4 ** -x + K * (2 ** x + 2 ** -x) + c
    xs = [i / 200 for i in range(-800, 801)]
    assert abs(min(f(x) for x in xs) - mn) < 1e-6 and abs(f(0) - mn) < 1e-9
    T = "2^{x} + 2^{−x}"
    Kt = ("+ %d(%s)" % (K, T)) if K > 0 else ("− %d(%s)" % (-K, T))
    return item("e_edge", "extreme", 2, "頂點不在範圍內", 1.1, "求 f(x) = (4^{x} + 4^{−x}) %s + %d 的最小值，以及此時 x 的值。" % (Kt, c),
                [ch("令 t = %s，t 的範圍是？" % T, ["t ≥ 2", "t > 0", "t ≥ −2", "全體實數"], "算幾不等式", "t = %s ≥ 2" % T),
                 ch("f 用 t 表示：", uniq([quad_t(1, K, c - 2, "t")], [quad_t(1, K, c, "t"), quad_t(1, K, c + 2, "t"), quad_t(1, K, c - 4, "t")]),
                    "4^{x} + 4^{−x} = t^{2} − 2", "f(x) = (t^{2} − 2)%s + %d = %s" % (cof(K, "t"), c, quad_t(1, K, c - 2, "t"))),
                 ch("配方：f(x) = ？", uniq([vf(h, k0)], [vf(h, c - 2), vf(-h, k0), vf(-K, c - 2 - K * K), vf(h, k0 + 4)]),
                    "t^{2}%s = %s − %s" % (cof(K, "t"), vf(h, 0), t(h * h)), "f(x) = %s，頂點 t = %s" % (vf(h, k0), t(h))),
                 fl("頂點 t = %s 在 t ≥ 2 裡面嗎？最小值發生在哪個 t、是多少？" % t(h), "t = [0] 時，最小值 [1]", ["2", a(mn)],
                    "頂點不在範圍內：t ≥ 2 時遞增，最小值在左端點"),
                 fl("t = %s = 2 時，x = ？" % T, "答：x = [0] 時，最小值 %s" % t(mn), ["0"], "算幾的等號成立：2^{x} = 2^{−x}")],
                plot={"x": [float(min(h, 0)) - 2.5, 4.0], "y": [float(min(k0, 0)) - 1.0, float(mn) + 3.0], "var": "t",
                      "curves": [{"f": gq(1, K, c - 2), "c": "orange", "at": 3}],
                      "pts": [{"x": float(h), "y": float(k0), "label": "(%s, %s)" % (t(h), t(k0)), "at": 3}, {"x": 2, "y": float(mn), "label": "(2, %s)" % t(mn), "at": 4}],
                      "band": {"lo": 2.0, "at": 1}})


# ---------- e_closed：x1 ≤ x ≤ x2，(1/4)^x − K(1/2)^x + C ----------

def e_closed(x1, x2, K, C):
    tl, th = F(2) ** (-x2), F(2) ** (-x1)
    h = F(K, 2)
    assert tl <= h <= th
    g = lambda tt: tt * tt - K * tt + C
    m = g(h)
    far = tl if abs(tl - h) > abs(th - h) else th
    assert abs(tl - h) != abs(th - h)
    M = g(far)
    xh = -round(math.log2(h))
    xf = -round(math.log2(far))
    f = lambda x: 0.25 ** x - K * 0.5 ** x + C
    xs = [x1 + (x2 - x1) * i / 3000 for i in range(3001)]
    assert abs(min(map(f, xs)) - m) < 1e-6 and abs(max(map(f, xs)) - M) < 1e-6
    near_ = th if far == tl else tl
    return item("e_closed", "extreme", 3, "閉區間的最值", 1.2,
                "當 %d ≤ x ≤ %d 時，f(x) = (1/4)^{x} − %d · (1/2)^{x} + %d 的最大值 M、最小值 m，求 (M, m)，以及各發生在 x 為多少時。" % (x1, x2, K, C),
                [fl("令 t = (1/2)^{x}，t 的範圍是？", "t = (1/2)^{x}，[0] ≤ t ≤ [1]", [a(tl), a(th)], "(1/2)^{x} 是遞減：x = %d、x = %d 分別代進去，小的寫左邊" % (x1, x2)),
                 ch("f 用 t 表示：", uniq([quad_t(1, -K, C, "t")], [quad_t(1, -K // 2, C, "t"), "2t − %dt + %d" % (K, C), "t^{4} − %dt + %d" % (K, C)]),
                    "(1/4)^{x} = [(1/2)^{x}]^{2}", "f(x) = %s" % quad_t(1, -K, C, "t")),
                 ch("配方：f(x) = ？", uniq([vf(h, m)], [vf(h, C), vf(K, C), vf(-h, m)]),
                    "t^{2} − %dt = %s − %s" % (K, vf(h, 0), t(h * h)), "f(x) = %s，頂點 t = %s" % (vf(h, m), t(h))),
                 fl("頂點 t = %s 在 %s ≤ t ≤ %s 裡面。最小值 m = ？" % (t(h), t(tl), t(th)), "頂點 t = %s 在範圍內 ⇒ 最小值 m = [0]" % t(h), [a(m)],
                    "頂點在範圍內，最小值就是配方後的常數項"),
                 fl("最小值發生時，x = ？", "t = %s ⇒ (1/2)^{x} = %s ⇒ x = [0]" % (t(h), t(h)), [str(xh)], "%s = (1/2)^{%d}" % (t(h), xh)),
                 fl("最大值 M 在哪個端點、是多少？", "端點 t = [0] 離頂點較遠 ⇒ M = [1]", [a(far), a(M)],
                    "最大值在離頂點 t = %s 較遠的端點：比較 |%s − %s| 和 |%s − %s|" % (t(h), t(far), t(h), t(near_), t(h))),
                 fl("最大值發生時，x = ？", "答：M = %s（x = [0]），m = %s（x = %d）" % (t(M), t(m), xh), [str(xf)], "(1/2)^{x} = %s = (1/2)^{%d}" % (t(far), xf))],
                plot={"x": [-0.5, float(th) + 1.0], "y": [-0.8, float(M) + 2.0], "var": "t",
                      "curves": [{"f": gq(1, -K, C), "c": "orange", "dom": [float(tl), float(th)], "at": 3}],
                      "pts": [{"x": float(h), "y": float(m), "label": "m", "at": 4}, {"x": float(far), "y": float(M), "label": "M", "at": 6},
                              {"x": float(near_), "y": float(g(near_)), "label": "", "at": 6}],
                      "band": {"lo": float(tl), "hi": float(th), "at": 1}})


# ---------- e_xpow：b^{u1} ≤ x ≤ b^{u2}，g = x^{k − log_b x} ----------

def e_xpow(b, k, u1, u2):
    v = F(k, 2)
    assert u1 <= v <= u2 and isint(v)
    v = int(v)
    hv = lambda u: k * u - u * u
    top = hv(v)
    far = u1 if abs(u1 - v) > abs(u2 - v) else u2
    assert abs(u1 - v) != abs(u2 - v)
    low = hv(far)
    M, m = F(b) ** top, F(b) ** low
    xl, xr = F(b) ** u1, F(b) ** u2
    xv, xf = F(b) ** v, F(b) ** far
    g = lambda x: x ** (k - lg(b, x))
    xs = [float(xl) + (float(xr) - float(xl)) * i / 4000 for i in range(4001)]
    assert abs(max(map(g, xs)) - float(M)) < 1e-6 * float(M) and abs(min(map(g, xs)) - float(m)) < 1e-9
    lb = "log_{%d}" % b
    return item("e_xpow", "extreme", 3, "取對數找最值", 1.2,
                "當 %s ≤ x ≤ %s 時，g(x) = x^{%d − %s x} 的最大值 M、最小值 m，求 (M, m)，以及各發生在 x 為多少時。" % (t(xl), t(xr), k, lb),
                [ch("兩邊取 %s，令 u = %s x：%s g = ？" % (lb, lb, lb), ["%du − u^{2}" % k, "%d − u^{2}" % k, "%du" % k, "(%d − u)^{2}" % k],
                    "%s x^{p} = p · %s x，這裡 p = %d − u" % (lb, lb, k),
                    "令 u = %s x，兩邊取 %s：%s g = (%d − u) %s x = (%d − u)u = %du − u^{2}" % (lb, lb, lb, k, lb, k, k)),
                 fl("u 的範圍？", "%s ≤ x ≤ %s ⇒ [0] ≤ u = %s x ≤ [1]" % (t(xl), t(xr), lb), [str(u1), str(u2)],
                    "%s = %d^{%d}，%s = %d^{%d}" % (t(xl), b, u1, t(xr), b, u2)),
                 ch("配方：%s g = %du − u^{2} = ？" % (lb, k), uniq(["−(u − %d)^{2} + %d" % (v, top)], ["−(u − %d)^{2} − %d" % (v, top), "−(u + %d)^{2} + %d" % (v, top),
                                                                               "(u − %d)^{2} + %d" % (v, top)]),
                    "%du − u^{2} = −(u^{2} − %du) = −(u − %d)^{2} + %d" % (k, k, v, top), "%s g = −(u − %d)^{2} + %d，開口向下，頂點 u = %d" % (lb, v, top, v)),
                 fl("頂點 u = %d 在 %d ≤ u ≤ %d 裡面，開口向下。g 的最大值 M = ？" % (v, u1, u2), "u = %d 時 %s g 最大 = [0] ⇒ M = [1]" % (v, lb), [str(top), a(M)],
                    "頂點時 %s g 是配方後的常數項，還要換回 g：g = %d^{%s g}" % (lb, b, lb)),
                 fl("最大值發生時，x = ？", "u = %s x = %d ⇒ x = [0]" % (lb, v), [a(xv)], "x = %d^{u}" % b),
                 fl("g 的最小值 m 在哪個端點、是多少？", "端點 u = [0] 離頂點較遠 ⇒ %s g = [1] ⇒ m = [2]" % lb, [str(far), str(low), a(m)],
                    "開口向下：最小在離頂點 u = %d 最遠的端點。算出 %s g，再換回 g" % (v, lb)),
                 fl("最小值發生時，x = ？", "答：M = %s（x = %s），m = %s（x = [0]）" % (t(M), t(xv), t(m)), [a(xf)], "u = %s x = %d ⇒ x = %d^{%d}" % (lb, far, b, far))],
                plot={"x": [u1 - 1.0, u2 + 1.0], "y": [low - 1.0, top + 1.0], "var": "u",
                      "curves": [{"f": gq(-1, k, 0), "c": "orange", "dom": [float(u1), float(u2)], "at": 3}],
                      "pts": [{"x": v, "y": top, "label": "(%d, %d)" % (v, top), "at": 4}, {"x": far, "y": low, "label": "(%d, %d)" % (far, low), "at": 6}],
                      "band": {"lo": float(u1), "hi": float(u2), "at": 2}})


def items():
    return [
        [e_basic(2, 1, 2, 7), e_basic(3, 2, 1, 10), e_basic(2, 1, 3, 20)],
        [e_inside(2, 6, 12), e_inside(2, 8, 20), e_inside(3, 10, 30)],
        [e_edge(4, 3), e_edge(2, 5), e_edge(-2, 4)],
        [e_closed(-2, 1, 4, 5), e_closed(-1, 2, 2, 3), e_closed(-3, 0, 8, 20)],
        [e_xpow(3, 4, -1, 3), e_xpow(2, 4, 0, 5), e_xpow(2, 2, -1, 4)],
    ]


# ================= 擴充（2026/11/09） =================

def bpow(b, h):
    """b^h，h 是整數或半整數：Q"""
    h = F(h)
    if isint(h):
        return Q(F(b) ** int(h))
    assert (2 * h).denominator == 1
    return Q.sqrt(F(b) ** int(2 * h))


# ---------- e_logquad：對數的二次式 ----------

def e_logquad(b, K, C):
    h = F(K, 2)
    mn = C - h * h
    x0 = bpow(b, h)
    f = lambda x: lg(b, x) ** 2 - K * lg(b, x) + C
    xs = [float(x0) * 2 ** (i / 400) for i in range(-2000, 2001)]
    assert abs(min(map(f, xs)) - float(mn)) < 1e-9 and abs(f(float(x0)) - float(mn)) < 1e-9
    lb = "log_{%d}" % b
    return item("e_logquad", "extreme", 1, "對數的二次式", 1.0,
                "求 f(x) = (%s x)^{2} − %d %s x + %d 的最小值，以及此時 x 的值。" % (lb, K, lb, C),
                [ch("令 u = %s x，u 的範圍是？" % lb, ["全體實數", "u > 0", "u ≥ 1", "u ≥ 2"], "x 可以是任何正數，%s x 可以是任何實數" % lb, "令 u = %s x，u 是任何實數" % lb),
                 ch("配方：f(x) = ？", uniq([vf(h, mn, "u")], [vf(h, C, "u"), vf(K, C - K * K, "u"), vf(-h, mn, "u"), vf(h, mn + 1, "u")]),
                    "u^{2} − %du = %s − %s" % (K, vf(h, 0, "u"), t(h * h)), "f(x) = %s，頂點 u = %s" % (vf(h, mn, "u"), t(h))),
                 fl("u 是任何實數，頂點就在範圍裡：", "最小值 [0]", [a(mn)], "配方後的常數項"),
                 fl("此時 x = ？", "答：%s x = %s ⇒ x = [0]" % (lb, t(h)), [x0.ans()], "x = %d^{%s}" % (b, t(h)))],
                plot={"x": [float(h) - 3.0, float(h) + 3.0], "y": [float(mn) - 1.0, float(mn) + 6.0], "var": "u",
                      "curves": [{"f": gq(1, -K, C), "c": "orange", "at": 1}], "pts": [{"x": float(h), "y": float(mn), "label": "(%s, %s)" % (t(h), t(mn)), "at": 2}]})


# ---------- e_prodlog：兩個對數相乘 ----------

def lg_arg(b, r):
    """log_b (x / b^r) 的真數寫法：x/8、3x、x"""
    if r == 0:
        return "x"
    v = b ** abs(r)
    return "x/%d" % v if r > 0 else "%dx" % v


def e_prodlog(b, r1, r2):
    """f = log_b (x/b^{r1}) · log_b (x/b^{r2}) = (u − r1)(u − r2)"""
    h = F(r1 + r2, 2)
    mn = -F(r2 - r1, 2) ** 2
    x0 = bpow(b, h)
    f = lambda x: (lg(b, x) - r1) * (lg(b, x) - r2)
    xs = [float(x0) * 2 ** (i / 400) for i in range(-2000, 2001)]
    assert abs(min(map(f, xs)) - float(mn)) < 1e-9 and abs(f(float(x0)) - float(mn)) < 1e-9
    lb = "log_{%d}" % b
    ex = quad_t(1, -(r1 + r2), r1 * r2, "u")
    fac = "(%s)(%s)" % (poly([(1, "u"), (-r1, "")]), poly([(1, "u"), (-r2, "")]))
    return item("e_prodlog", "extreme", 2, "兩個對數相乘", 1.1,
                "求 f(x) = %s (%s) · %s (%s) 的最小值，以及此時 x 的值。" % (lb, lg_arg(b, r1), lb, lg_arg(b, r2)),
                [ch("令 u = %s x，%s (%s) = ？" % (lb, lb, lg_arg(b, r1)), uniq(["u %s %d" % ("−" if r1 > 0 else "+", abs(r1))],
                                                                       ["u %s %d" % ("+" if r1 > 0 else "−", abs(r1)), "%du" % b ** abs(r1), "u/%d" % b ** abs(r1)]),
                    "log (MN) = log M + log N，log (M/N) = log M − log N", "f = %s = %s" % (fac, ex)),
                 ch("配方：f = ？", uniq([vf(h, mn, "u")], [vf(h, r1 * r2, "u"), vf(-h, mn, "u"), vf(h, -mn, "u")]),
                    "u^{2}%s 配方" % cof(-(r1 + r2), "u"), "f = %s，頂點 u = %s" % (vf(h, mn, "u"), t(h))),
                 fl("u 是任何實數，頂點就在範圍裡：", "最小值 [0]", [a(mn)], "配方後的常數項"),
                 fl("此時 x = ？", "答：%s x = %s ⇒ x = [0]" % (lb, t(h)), [x0.ans()], "x = %d^{%s}" % (b, t(h)))],
                plot={"x": [float(h) - 3.0, float(h) + 3.0], "y": [float(mn) - 1.0, float(mn) + 6.0], "var": "u",
                      "curves": [{"f": gq(1, -(r1 + r2), r1 * r2), "c": "orange", "at": 1}],
                      "pts": [{"x": float(h), "y": float(mn), "label": "(%s, %s)" % (t(h), t(mn)), "at": 2}]})


# ---------- e_sumxy：條件下的對數和 ----------

def e_sumxy(b, A, B, S):
    """x, y > 0，Ax + By = S，log_b x + log_b y 的最大值（算幾）"""
    P = F(S * S, 4 * A * B)
    xv, yv = F(S, 2 * A), F(S, 2 * B)
    assert xv * yv == P
    k = round(math.log(P, b))
    assert F(b) ** k == P
    xs = [S / A * i / 4000 for i in range(1, 4000)]
    assert abs(max(lg(b, x) + lg(b, (S - A * x) / B) for x in xs) - k) < 1e-6
    lb = logb(b)
    ax = "%sx" % ("" if A == 1 else str(A))
    by = "%sy" % ("" if B == 1 else str(B))
    return item("e_sumxy", "extreme", 2, "條件下的對數和", 1.1,
                "x > 0、y > 0，且 %s + %s = %d。求 %s x + %s y 的最大值，以及此時的 x、y。" % (ax, by, S, lb, lb),
                [ch("%s x + %s y = ？" % (lb, lb), ["%s (xy)" % lb, "%s (x + y)" % lb, "(%s x)(%s y)" % (lb, lb), "%s (x/y)" % lb],
                    "log M + log N = log (MN)", "%s x + %s y = %s (xy)，xy 越大越大" % (lb, lb, lb)),
                 ch("%s 和 %s 都是正的，用算幾不等式：" % (ax, by), ["%s · %s ≤ (%d/2)^{2}" % (ax, by, S), "%s + %s ≤ 2√{xy}" % (ax, by),
                                                          "%s · %s ≥ (%d/2)^{2}" % (ax, by, S), "xy ≤ %d" % S],
                    "(a + b)/2 ≥ √{ab} ⇒ ab ≤ ((a + b)/2)^{2}", "%s · %s ≤ %d" % (ax, by, (S // 2) ** 2) if S % 2 == 0 else ""),
                 fl("所以 xy 最大是多少？", "xy ≤ [0]", [a(P)], "%d ÷ %d" % ((S // 2) ** 2, A * B) if A * B != 1 else "(%d/2)^{2}" % S),
                 fl("%s (xy) 的最大值：" % lb, "最大值 %s %s = [0]" % (lb, t(P)), [str(k)], "%s = %d^{%d}" % (t(P), b, k)),
                 fl("等號成立在 %s = %s：" % (ax, by), "答：x = [0]，y = [1]", [a(xv), a(yv)], "%s = %s = %d/2" % (ax, by, S))])


_items0 = items


def items():
    return _items0() + [
        [e_logquad(2, 4, 5), e_logquad(3, 2, 4), e_logquad(2, 6, 10)],
        [e_prodlog(2, 1, 3), e_prodlog(3, -1, 2), e_prodlog(2, -2, 1)],
        [e_sumxy(10, 1, 1, 20), e_sumxy(10, 1, 4, 40), e_sumxy(2, 2, 1, 16)],
    ]
