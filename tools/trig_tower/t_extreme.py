# 疊合極值
from tlib import *

sin, cos = math.sin, math.cos


def gf(k):
    return repr(float(k))


def sq_(h, v="t"):
    """(t − h)^{2}"""
    h = F(h)
    if h == 0:
        return v + "^{2}"
    return "(%s %s %s)^{2}" % (v, M if h > 0 else "+", t(abs(h)))


def vform(a_, b_, c_, v="t"):
    """at² + bt + c 配方：−2(t + 1/2)^{2} + 3/2"""
    a_, b_, c_ = F(a_), F(b_), F(c_)
    h = -b_ / (2 * a_)
    k = c_ - a_ * h * h
    co = "" if a_ == 1 else (M if a_ == -1 else t(a_))
    s = co + sq_(h, v)
    if k != 0:
        s += (" + " if k > 0 else " " + M + " ") + t(abs(k))
    return s, h, k


def quad(a_, b_, c_, v="t"):
    return poly([(a_, v + "^{2}"), (b_, v), (c_, "")])


def qf(a_, b_, c_):
    return lambda x: float(a_) * x * x + float(b_) * x + float(c_)


def qx(a_, b_, c_):
    """Godot 式子"""
    return "%s*x*x+%s*x+%s" % (gf(a_), gf(b_), gf(c_))


# ---------- te_quad：換成 sin 的二次式 ----------

def te_quad(p, q, lo, hi):
    """f = cos²x + p sin x + q，x 在 [lo, hi]（經過 π/2）"""
    lo, hi = F(lo), F(hi)
    assert lo < F(1, 2) < hi
    tl = min(sv(lo), sv(hi), key=float)
    a_, b_, c_ = -1, p, 1 + q
    g = qf(a_, b_, c_)
    vt, h, k = vform(a_, b_, c_)
    f = lambda x: cos(x) ** 2 + p * sin(x) + q
    mn, mx = ext(f, float(lo) * PI, float(hi) * PI)
    tlo = float(tl)
    gv = lambda tt: F(a_) * tt * tt + b_ * tt + c_
    if h <= tl:
        Mv, Mt, mv, mt = gv(tl.a), tl, gv(1), 1
        s3q = "頂點 t = %s 在範圍左邊，開口向下：範圍內 f 一路遞減，最大在左端點。" % t(h)
        s4q = "最小在右端點："
    elif h >= 1:
        Mv, Mt, mv, mt = gv(1), 1, gv(tl.a), tl
        s3q = "頂點 t = %s 在範圍右邊，開口向下：範圍內 f 一路遞增，最大在右端點。" % t(h)
        s4q = "最小在左端點："
    else:
        Mv, Mt = k, h
        e = [(gv(tl.a), tl), (gv(1), Q(1))]
        mv, mt = min(e, key=lambda z: z[0])
        s3q = "頂點 t = %s 在範圍裡面，開口向下：最大值就是頂點。" % t(h)
        s4q = "最小在離頂點比較遠的端點："
    assert near(Mv, mx, 1e-6) and near(mv, mn, 1e-6)
    Mt, mt = Q.of(Mt), Q.of(mt)
    wrong = [quad(-1, p, q - 1), quad(1, p, c_), quad(-1, -p, c_)]
    return item("te_quad", "extreme", 1, "換成 sin 的二次式", 1.05,
                "%s ≤ x ≤ %s 時，f(x) = cos^{2} x%s%s 的最大值 M、最小值 m，求 (M, m)。" % (pt_(lo), pt_(hi), cof(p, "sin x"), cof(q, "") if q else ""),
                [fl("令 t = sin x。x 從 %s 走到 %s，會經過 π/2：" % (pt_(lo), pt_(hi)), "[0] ≤ t ≤ [1]", [tl.ans(), "1"],
                    "最大 sin(π/2) = 1，最小 sin(%s)" % pt_(lo if sv(lo) == tl else hi)),
                 ch("cos^{2} x = 1 − t^{2}，f 用 t 表示：", uniq([quad(a_, b_, c_)], wrong),
                    "1 − t^{2}%s%s" % (cof(p, "t"), cof(q, "") if q else ""), "f = %s = %s" % (quad(a_, b_, c_), vt)),
                 fl(s3q, "M = f(t = %s) = [0]" % Mt.text(), [a(Mv)], evq(a_, b_, c_, Mt.a) if Mt != Q(h) else "頂點的值"),
                 fl(s4q, "答：m = f(t = %s) = [0]" % mt.text(), [a(mv)], evq(a_, b_, c_, mt.a))],
                plot={"x": [fx(min(float(h), tlo) - 0.7), fx(max(float(h), 1) + 0.6)], "y": [fx(min(float(mv), float(k)) - 1.0), fx(max(float(Mv), float(k)) + 1.0)],
                      "var": "t", "curves": [{"f": qx(a_, b_, c_), "c": "orange", "at": 2}],
                      "band": {"lo": fx(tlo), "hi": 1.0, "at": 1},
                      "pts": [{"x": fx(h), "y": fx(k), "label": "", "at": 2}, {"x": fx(Mt), "y": fx(Mv), "label": "M", "at": 3},
                              {"x": fx(mt), "y": fx(mv), "label": "m", "at": 4}]})


# ---------- te_sum：t = sin x + cos x ----------

def te_sum(p, q):
    """f = sin 2x + p(sin x + cos x) + q，0 ≤ x ≤ π；t 在 [−1, √2]"""
    a_, b_, c_ = 1, p, q - 1
    vt, h, k = vform(a_, b_, c_)
    T0, T1 = Q(-1), Q(0, 1, 2)
    gv = lambda tt: Q.of(tt) * Q.of(tt) + Q.of(tt) * b_ + c_
    f = lambda x: sin(2 * x) + p * (sin(x) + cos(x)) + q
    mn, mx = ext(f, 0, PI)
    e0, e1 = gv(T0), gv(T1)
    if h <= -1:
        Mv, Mt, mv, mt = e1, T1, e0, T0
        s3 = "開口向上，離頂點 t = %s 最遠的是右端點 t = √{2}：" % t(h)
        s4 = "頂點 t = −1 剛好是左端點：" if h == -1 else "最小在左端點 t = −1："
    else:
        Mv, Mt = max([(e0, T0), (e1, T1)], key=lambda z: float(z[0]))
        mv, mt = Q(k), Q(h)
        s3 = "頂點 t = %s 在範圍裡面，開口向上：最大在離頂點比較遠的端點 t = %s：" % (t(h), Mt.text())
        s4 = "最小就是頂點："
    assert near(Mv, mx, 1e-6) and near(mv, mn, 1e-6)
    stem_f = "sin 2x%s%s" % (cof(p, "(sin x + cos x)"), cof(q, "") if q else "")

    def sub(tt):
        """把 t 代進配方式"""
        inner = Q.of(tt) - h
        s_ = "(%s)^{2}" % inner.text() if not (inner.rat() and inner.a >= 0 and isint(inner.a)) else "%s^{2}" % inner.text()
        if inner.a != 0 and inner.b != 0:
            s_ = "(%s)^{2}" % inner.text()
        elif inner.rat() and inner.a < 0:
            s_ = "(%s)^{2}" % inner.text()
        return s_ + ((" + " + t(k)) if k > 0 else ((" − " + t(-k)) if k < 0 else ""))
    return item("te_sum", "extreme", 2, "t = sin x + cos x", 1.25,
                "0 ≤ x ≤ π 時，f(x) = %s 的最大值 M、最小值 m，求 (M, m)。" % stem_f,
                [fl("x + π/4 從 π/4 到 5π/4，sin 最大 1、最小 sin(5π/4)：", "[0] ≤ t ≤ [1]", ["−1", "√2"], "√{2} × (−√{2}/2) = −1",
                    pre="令 t = sin x + cos x = √{2} sin(x + π/4)"),
                 fl("t^{2} = sin^{2}x + cos^{2}x + 2 sin x cos x = 1 + sin 2x：", "sin 2x = t^{2} − [0] ⇒ f = %s" % vt, ["1"],
                    "f = t^{2} − 1%s%s" % (cof(p, "t"), cof(q, "") if q else "")),
                 fl(s3, "M = %s = [0]" % sub(Mt), [Mv.ans()], "展開再化簡"),
                 fl(s4, "答：m = [0]", [mv.ans()], "頂點的值" if mt == Q(h) else sub(mt))],
                plot={"x": [fx(min(float(h), -1) - 0.8), 2.0], "y": [fx(min(float(mv), float(k)) - 0.6), fx(float(Mv) + 0.8)], "var": "t",
                      "curves": [{"f": qx(a_, b_, c_), "c": "orange", "at": 2}],
                      "band": {"lo": -1.0, "hi": 1.4142, "at": 1},
                      "pts": [{"x": fx(Mt), "y": fx(Mv), "label": "M", "at": 3}, {"x": fx(mt), "y": fx(mv), "label": "m", "at": 4}]})


# ---------- te_box：疊合找最大 ----------

def te_box(a_, b_):
    """f = a sin x − b cos x，0 ≤ x ≤ π"""
    r = math.isqrt(a_ * a_ + b_ * b_)
    assert r * r == a_ * a_ + b_ * b_
    ph = math.atan2(b_, a_)
    f = lambda x: a_ * sin(x) - b_ * cos(x)
    mn, mx = ext(f, 0, PI)
    xm = PI / 2 + ph
    assert near(mx, r, 1e-6) and near(mn, -b_, 1e-6) and near(sin(xm), F(a_, r))
    return item("te_box", "extreme", 1, "疊合找最大", 1.05,
                "0 ≤ x ≤ π 時，f(x) = %d sin x − %d cos x 的最大值 M、最小值 m，以及最大值發生時 sin x 的值。" % (a_, b_),
                [fl("疊合成 r sin(x − φ)，φ 是銳角：", "r = [0]，cos φ = [1]，sin φ = [2]", [str(r), a(F(a_, r)), a(F(b_, r))],
                    "r = √{%d^{2} + %d^{2}}，r cos φ = %d、r sin φ = %d" % (a_, b_, a_, b_)),
                 fl("x − φ 從 −φ 到 π − φ，裡面有 π/2：", "M = [0]，此時 x = π/2 + φ，sin x = cos φ = [1]", [str(r), a(F(a_, r))],
                    "sin(π/2 + φ) = cos φ"),
                 fl("最小值在端點：比較 f(0)、f(π)。", "答：m = [0]", [a(-b_)], "f(0) = %s、f(π) = %d" % (t(-b_), b_))],
                plot={"x": [-0.3, 3.5], "y": [-b_ - 1.6, r + 0.8], "pi": 4,
                      "curves": [{"f": "%d*sin(x)-%d*cos(x)" % (a_, b_), "c": "cyan", "dom": [0.0, 3.1416], "at": 1}],
                      "band": {"lo": 0.0, "hi": 3.1416, "at": 1},
                      "pts": [{"x": fx(xm), "y": r, "label": "M", "at": 2}, {"x": 0, "y": -b_, "label": "m", "off": [8, 4], "at": 3}]})


# ---------- te_expand：先展開再疊合 ----------

def te_expand(A, al, c, r, ph, hi):
    """f = A sin(x + αl π) + c cos x = r sin(x + φπ)，0 ≤ x ≤ hi π"""
    A, c, r, al, ph, hi = Q.of(A), Q.of(c), Q.of(r), F(al), F(ph), F(hi)
    cs, cc = A * cv(al), A * sv(al)
    cc2 = cc + c
    assert cs == r * cv(ph) and cc2 == r * sv(ph)
    u0, u1 = ph, ph + hi
    vals = [r * sv(u0), r * sv(u1)] + ([r] if u0 <= F(1, 2) <= u1 else [])
    Mv, mv = max(vals, key=float), min(vals, key=float)
    us = [u0, u1] + ([F(1, 2)] if u0 <= F(1, 2) <= u1 else [])
    uM = max(us, key=lambda u: float(sv(u)))
    um = min(us, key=lambda u: float(sv(u)))
    f = lambda x: float(A) * sin(x + float(al) * PI) + float(c) * cos(x)
    mn, mx = ext(f, 0, float(hi) * PI)
    assert near(mx, Mv, 1e-6) and near(mn, mv, 1e-6)
    sg = "+" if ph > 0 else "−"
    fx_ = lin_tr([(cs, "sin x"), (cc2, "cos x")])
    stem_f = "%s sin(x%s)%s" % (A.text(), (" + " if al > 0 else " − ") + pt_(abs(al)), cof(c, "cos x"))
    return item("te_expand", "extreme", 2, "先展開再疊合", 1.15,
                "0 ≤ x ≤ %s 時，f(x) = %s 的最大值 M、最小值 m，求 (M, m)。" % (pt_(hi), stem_f),
                [fl("和角公式展開：", "%s sin(x%s) = [0] sin x + [1] cos x" % (A.text(), (" + " if al > 0 else " − ") + pt_(abs(al))), [cs.ans(), cc.ans()],
                    "%s(sin x cos(%s) + cos x sin(%s))" % (A.text(), pt_(al), pt_(al))),
                 fl("f = %s，疊合：" % fx_, "f = [0] sin(x %s [1]π)" % sg, [r.ans(), a(abs(ph))], "cos(%s) = %s" % (pt_(abs(ph)), cv(abs(ph)).text())),
                 fl("x %s %s 從 %s 到 %s：" % (sg, pt_(abs(ph)), pt_(u0), pt_(u1)), "答：M = [0]，m = [1]", [Mv.ans(), mv.ans()],
                    "%s、%s" % tuple(("%s sin(%s)" % (r.text(), pt_(u)) if u != F(1, 2) else r.text()) for u in (uM, um)))],
                plot={"x": [-0.5, fx(float(hi) * PI + 0.7)], "y": [fx(float(mv) - 0.6), fx(float(Mv) + 0.6)], "pi": 12, "pi_lab": 6,
                      "curves": [{"f": "%s*sin(x+%s)" % (gf(float(r)), gf(float(ph) * PI)), "c": "cyan", "dom": [0.0, fx(float(hi) * PI)], "at": 2}],
                      "band": {"lo": 0.0, "hi": fx(float(hi) * PI), "at": 2}})


# ---------- te_reduce：降次再疊合 ----------

def te_reduce(cfg):
    r, ph, hi, B = Q.of(cfg["r"]), F(cfg["ph"]), F(cfg["hi"]), cfg["B"]
    f = cfg["f"]
    g = lambda x: float(r) * sin(2 * x + float(ph) * PI) + B
    assert all(near(f(x), g(x)) for x in (0.1, 0.5, 1.2))
    u0, u1 = ph, ph + 2 * hi
    vals = [r * sv(u0) + B, r * sv(u1) + B] + ([r + B] if u0 <= F(1, 2) <= u1 else [])
    Mv, mv = max(vals, key=float), min(vals, key=float)
    mn, mx = ext(f, 0, float(hi) * PI)
    assert near(mx, Mv, 1e-6) and near(mn, mv, 1e-6)
    sg = "+" if ph > 0 else "−"
    ss = [sv(u0), sv(u1)] + ([Q(1)] if u0 <= F(1, 2) <= u1 else [])
    smax, smin = max(ss, key=float), min(ss, key=float)
    xs_ = [float(hi) * PI * i / 4000 for i in range(4001)]
    xMv = max(xs_, key=f)
    xmv = min(xs_, key=f)
    return item("te_reduce", "extreme", 2, "降次再疊合", 1.2,
                "0 ≤ x ≤ %s 時，f(x) = %s 的最大值 M、最小值 m，求 (M, m)。" % (pt_(hi), cfg["stem"]),
                [fl(cfg["q1"], cfg["t1"], cfg["a1"], cfg["h1"]),
                 fl("疊合 %s：" % cfg["fold"], "f = %s sin(2x %s [0]π) + %d" % (r.text(), sg, B), [a(abs(ph))], cfg["h2"]),
                 fl("2x %s %s 的範圍：" % (sg, pt_(abs(ph))), "%s ≤ 2x %s %s ≤ [0]π" % (pt_(u0), sg, pt_(abs(ph))), [a(u1)], "x = %s 代入" % pt_(hi)),
                 fl("sin 在 %s 到 %s 的範圍是 %s 到 %s：" % (pt_(u0), pt_(u1), min([sv(u0), sv(u1)] + ([Q(1)] if u0 <= F(1, 2) <= u1 else []), key=float).text(),
                                                     max([sv(u0), sv(u1)] + ([Q(1)] if u0 <= F(1, 2) <= u1 else []), key=float).text()),
                    "答：M = [0]，m = [1]", [Mv.ans(), mv.ans()], "%s · %s + %d、%s · %s + %d" % (r.text(), smax.tp(), B, r.text(), smin.tp(), B))],
                plot={"x": [-0.4, fx(float(hi) * PI + 0.4)], "y": [fx(float(mv) - 0.6), fx(float(Mv) + 0.5)], "pi": 12, "pi_lab": 4,
                      "curves": [{"f": "%s*sin(2*x+%s)+%d" % (gf(float(r)), gf(float(ph) * PI), B), "c": "cyan", "dom": [0.0, fx(float(hi) * PI)], "at": 2}],
                      "band": {"lo": 0.0, "hi": fx(float(hi) * PI), "at": 2},
                      "pts": [{"x": fx(xMv), "y": fx(Mv), "label": "M", "at": 3}, {"x": fx(xmv), "y": fx(mv), "label": "m", "off": [8, 4], "at": 3}]})


REDUCE = [
    {"stem": "2 sin x(sin x + √{3} cos x)", "f": lambda x: 2 * sin(x) * (sin(x) + S3 * cos(x)), "r": 2, "ph": F(-1, 6), "hi": F(1, 2), "B": 1,
     "q1": "展開：2 sin^{2} x = 1 − cos 2x，2 sin x cos x = sin 2x。", "t1": "f = 1 − cos 2x + [0] sin 2x", "a1": ["√3"],
     "h1": "2√{3} sin x cos x = √{3} sin 2x", "fold": "√{3} sin 2x − cos 2x", "h2": "和 √{3} sin x − cos x 一樣"},
    {"stem": "2 cos x(√{3} sin x + cos x)", "f": lambda x: 2 * cos(x) * (S3 * sin(x) + cos(x)), "r": 2, "ph": F(1, 6), "hi": F(1, 2), "B": 1,
     "q1": "展開：2 cos^{2} x = 1 + cos 2x，2 sin x cos x = sin 2x。", "t1": "f = [0] sin 2x + cos 2x + 1", "a1": ["√3"],
     "h1": "2√{3} sin x cos x = √{3} sin 2x", "fold": "√{3} sin 2x + cos 2x", "h2": "和 √{3} sin x + cos x 一樣"},
    {"stem": "2 sin x(sin x + cos x)", "f": lambda x: 2 * sin(x) * (sin(x) + cos(x)), "r": Q(0, 1, 2), "ph": F(-1, 4), "hi": F(1, 4), "B": 1,
     "q1": "展開：2 sin^{2} x = 1 − cos 2x，2 sin x cos x = sin 2x。", "t1": "f = 1 − cos 2x + [0] sin 2x", "a1": ["1"],
     "h1": "2 sin x cos x = sin 2x", "fold": "sin 2x − cos 2x", "h2": "√{1 + 1} = √{2}，cos(π/4) = √{2}/2"},
]


# ---------- te_frac：分式的最值 ----------

def te_frac(k):
    hi = F(2 * k, k * k - 1)
    f = lambda x: (1 - cos(x)) / (k + sin(x))
    mn, mx = ext(f, 0, 2 * PI, 40000)
    assert near(mn, 0, 1e-6) and near(mx, hi, 1e-6)
    return item("te_frac", "extreme", 3, "分式的最值", 1.35,
                "求 y = (1 − cos x)/(%d + sin x) 的最大值與最小值。" % k,
                [fl("去分母 %dy + y sin x = 1 − cos x，把 sin x、cos x 移到同一邊：" % k, "y sin x + cos x = 1 − [0]y", [str(k)], "%dy 移到右邊" % k),
                 ch("左邊疊合後的範圍是 ±√{y^{2} + 1}，有解的條件：", ["(1 − %dy)^{2} ≤ y^{2} + 1" % k, "1 − %dy ≤ y + 1" % k, "(1 − %dy)^{2} ≥ y^{2} + 1" % k,
                                                          "|1 − %dy| ≤ y^{2} + 1" % k],
                    "a sin x + b cos x = k 有解 ⇔ k^{2} ≤ a^{2} + b^{2}", "(1 − %dy)^{2} ≤ y^{2} + 1" % k),
                 fl("展開：1 − %dy + %dy^{2} ≤ y^{2} + 1，移項：" % (2 * k, k * k), "[0]y^{2} − %dy ≤ 0" % (2 * k), [str(k * k - 1)], "%dy^{2} − y^{2}" % (k * k)),
                 fl("%sy(%dy − %d) ≤ 0，在兩根之間：" % ("" if math.gcd(k * k - 1, 2 * k) == 1 else str(math.gcd(k * k - 1, 2 * k)),
                                                  (k * k - 1) // math.gcd(k * k - 1, 2 * k), 2 * k // math.gcd(k * k - 1, 2 * k)),
                    "答：[0] ≤ y ≤ [1]", ["0", a(hi)], "兩根 0、%s" % t(hi))],
                plot={"x": [-0.3, 6.6], "y": [-0.15, fx(float(hi) + 0.2)], "pi": 2,
                      "curves": [{"f": "(1-cos(x))/(%d+sin(x))" % k, "c": "cyan", "at": 4}, {"f": gf(hi), "c": "pink", "dash": True, "at": 4}]})


# ---------- te_solvable：有解的 k ----------

def te_solvable(p):
    a_, b_, c_ = -2, p, 1
    vt, h, kk = vform(a_, b_, c_)
    gv = lambda tt: F(a_) * tt * tt + b_ * tt + c_
    if -1 <= h <= 1:
        hi, ht = kk, h
        lo, lt = min((gv(-1), -1), (gv(1), 1))
    else:
        (lo, lt), (hi, ht) = sorted([(gv(-1), -1), (gv(1), 1)])
    f = lambda x: cos(2 * x) + p * sin(x)
    mn, mx = ext(f, 0, 2 * PI)
    assert near(mn, lo, 1e-6) and near(mx, hi, 1e-6)
    return item("te_solvable", "extreme", 2, "有解的 k", 1.15,
                "方程式 cos 2x%s = k 有實數解，求 k 的範圍。" % cof(p, "sin x"),
                [fl("令 t = sin x（−1 ≤ t ≤ 1），cos 2x = 1 − 2t^{2}：", "k = %s = −2%s + [0]" % (quad(a_, b_, c_), sq_(h)), [a(kk)],
                    "−2(%s) + %s + 1" % (quad(1, -F(p, 2), h * h), t(2 * h * h))),
                 fl("k 是 t 在 −1 到 1 之間時，這個二次函數取到的值：", "答：[0] ≤ k ≤ [1]", [a(lo), a(hi)],
                    "t = %s 最大，t = %s 最小" % (t(ht), t(lt)))],
                plot={"x": [fx(min(float(h), -1) - 0.6), fx(max(float(h), 1) + 0.6)], "y": [fx(float(lo) - 0.8), fx(max(float(hi), float(kk)) + 0.8)], "var": "t",
                      "curves": [{"f": qx(a_, b_, c_), "c": "orange", "at": 1}],
                      "band": {"lo": -1.0, "hi": 1.0, "at": 0},
                      "pts": [{"x": fx(ht), "y": fx(hi), "label": t(hi), "at": 2}, {"x": fx(lt), "y": fx(lo), "label": t(lo), "at": 2}]})


# ---------- te_halfmax：疊合的角再對半 ----------

def te_halfmax(a_, b_):
    r = math.isqrt(a_ * a_ + b_ * b_)
    assert r * r == a_ * a_ + b_ * b_
    ct, st = F(a_, r), F(b_, r)
    c2h = (1 + ct) / 2
    s2 = 2 * st * ct
    th = math.atan2(b_, a_)
    al = PI / 2 - th
    f = lambda x: a_ * sin(x) + b_ * cos(x)
    assert near(f(al), r) and near(sin(2 * al), s2) and near(cos(th / 2) ** 2, c2h)
    return item("te_halfmax", "extreme", 3, "疊合的角再對半", 1.3,
                "f(x) = %d sin x + %d cos x 寫成 r sin(x + θ)（r > 0、θ 是銳角）。\n(1) 求 cos^{2}(θ/2)　(2) 0 ≤ x ≤ π/2 時，f 在 x = α 有最大值 k，求 k 與 sin 2α。" % (a_, b_),
                [fl("疊合：r cos θ = %d、r sin θ = %d。" % (a_, b_), "r = [0]，cos θ = [1]", [str(r), a(ct)], "%d、%d、%d" % (min(a_, b_), max(a_, b_), r), part="(1)"),
                 fl("半角公式：", "cos^{2}(θ/2) = (1 + cos θ)/2 = [0]", [a(c2h)], "(1 + %s)/2" % t(ct), part="(1)"),
                 fl("x + θ 從 θ 到 π/2 + θ，會經過 π/2：", "k = [0]，α = π/2 − θ", [str(r)], "sin 取到 1", part="(2)"),
                 fl("2α = π − 2θ：", "答：sin 2α = sin 2θ = [0]", [a(s2)], "2 · (%s) · (%s)" % (t(st), t(ct)), part="(2)")],
                plot={"x": [-0.3, 1.9], "y": [-1.0, r + 2.0], "pi": 4,
                      "curves": [{"f": "%d*sin(x)+%d*cos(x)" % (a_, b_), "c": "cyan", "dom": [0.0, 1.5708], "at": 2}],
                      "band": {"lo": 0.0, "hi": 1.5708, "at": 2}})


# ---------- te_cosprod：乘開再疊合 ----------

def te_cosprod(a_, b_, hi):
    """f = 2 cos x(a sin x + b cos x) = a sin 2x + b cos 2x + b，0 ≤ x ≤ hi π"""
    hi = F(hi)
    r = math.isqrt(a_ * a_ + b_ * b_)
    assert r * r == a_ * a_ + b_ * b_
    cp, sp = F(a_, r), F(b_, r)
    ph = math.atan2(b_, a_)
    f = lambda x: 2 * cos(x) * (a_ * sin(x) + b_ * cos(x))
    mn, mx = ext(f, 0, float(hi) * PI)
    Mv = r + b_
    assert near(mx, Mv, 1e-6)
    if hi == F(1, 2):
        mv = -r * sp + b_
        last = ("最小在右端點 2x + φ = π + φ：", "答：m = %d sin(π + φ) + %d = %d · (−%s) + %d = [0]" % (r, b_, r, t(sp), b_), "sin(π + φ) = −sin φ")
    else:
        assert hi == F(1, 4)
        mv = r * cp + b_
        last = ("最小在右端點 2x + φ = π/2 + φ：", "答：m = %d sin(π/2 + φ) + %d = %d · %s + %d = [0]" % (r, b_, r, t(cp), b_),
                "sin(π/2 + φ) = cos φ；左端點 f(0) = %d 比較大" % (2 * b_))
        assert 2 * b_ > mv
    assert near(mn, mv, 1e-6)
    return item("te_cosprod", "extreme", 2, "乘開再疊合", 1.25,
                "0 ≤ x ≤ %s 時，f(x) = 2 cos x(%d sin x + %d cos x) 的最大值 M、最小值 m，求 (M, m)。" % (pt_(hi), a_, b_),
                [fl("乘開：%d sin x cos x + %d cos^{2} x，用二倍角降次：" % (2 * a_, 2 * b_), "f = %d sin 2x + %d cos 2x + [0]" % (a_, b_), [str(b_)],
                    "%d cos^{2} x = %d(1 + cos 2x)" % (2 * b_, b_)),
                 fl("疊合（φ 是銳角，cos φ = %s、sin φ = %s）：" % (t(cp), t(sp)), "%d sin 2x + %d cos 2x = [0] sin(2x + φ)" % (a_, b_), [str(r)],
                    "√{%d + %d}" % (a_ * a_, b_ * b_)),
                 fl("2x + φ 從 φ 到 %s + φ，會經過 π/2：" % pt_(2 * hi), "M = %d + %d = [0]" % (r, b_), [str(Mv)], "sin 取到 1"),
                 fl(last[0], last[1], [a(mv)], last[2])],
                plot={"x": [-0.3, 1.9], "y": [fx(min(float(mv), 0) - 0.8), fx(Mv + 0.8)], "pi": 4,
                      "curves": [{"f": "2*cos(x)*(%d*sin(x)+%d*cos(x))" % (a_, b_), "c": "cyan", "dom": [0.0, fx(float(hi) * PI)], "at": 2}],
                      "band": {"lo": 0.0, "hi": fx(float(hi) * PI), "at": 2}})


# ---------- te_cos2：二倍角的二次式 ----------

def te_cos2(p):
    a_, b_, c_ = -2, p, 1
    vt, h, k = vform(a_, b_, c_)
    assert -1 < h < 1
    gv = lambda tt: F(a_) * tt * tt + b_ * tt + c_
    mv, mt = min((gv(-1), -1), (gv(1), 1))
    f = lambda x: cos(2 * x) + p * sin(x)
    mn, mx = ext(f, 0, 2 * PI)
    assert near(mx, k, 1e-6) and near(mn, mv, 1e-6)
    return item("te_cos2", "extreme", 1, "二倍角的二次式", 1.0,
                "求 f(x) = cos 2x%s 的最大值 M、最小值 m。" % cof(p, "sin x"),
                [ch("令 t = sin x，cos 2x 用 t 表示：", ["1 − 2t^{2}", "2t^{2} − 1", "1 − t^{2}", "2t^{2} + 1"],
                    "cos 2x = 1 − 2 sin^{2} x", "f = 1 − 2t^{2}%s = %s，−1 ≤ t ≤ 1" % (cof(p, "t"), vt)),
                 fl("頂點 t = %s 在範圍內：" % t(h), "M = [0]", [a(k)], "開口向下，頂點最高"),
                 fl("離頂點最遠的端點：", "答：m = [0]（t = %s）" % t(mt), [a(mv)], evq(-2, p, 1, mt).replace("+ −", "− "))],
                plot={"x": [-1.7, 1.5], "y": [fx(float(mv) - 0.6), fx(float(k) + 0.8)], "var": "t",
                      "curves": [{"f": qx(a_, b_, c_), "c": "orange", "at": 1}],
                      "band": {"lo": -1.0, "hi": 1.0, "at": 1},
                      "pts": [{"x": fx(h), "y": fx(k), "label": "M", "at": 2}, {"x": mt, "y": fx(mv), "label": "m", "at": 3}]})


def items():
    return [
        [te_quad(-3, 2, F(1, 6), F(7, 6)), te_quad(1, 0, F(1, 3), F(7, 6)), te_quad(4, -1, F(-1, 6), F(2, 3))],
        [te_sum(2, -1), te_sum(-2, 3), te_sum(3, -1)],
        [te_box(3, 4), te_box(4, 3), te_box(5, 12)],
        [te_expand(2, F(1, 6), -2, 2, F(-1, 6), F(1, 2)), te_expand(2, F(-1, 6), 2, 2, F(1, 6), F(1, 2)),
         te_expand(Q(0, 2, 2), F(1, 4), -4, Q(0, 2, 2), F(-1, 4), F(1, 2))],
        [te_reduce(c) for c in REDUCE],
        [te_frac(3), te_frac(2), te_frac(4)],
        [te_solvable(4), te_solvable(2), te_solvable(-6)],
        [te_halfmax(8, 15), te_halfmax(3, 4), te_halfmax(5, 12)],
        [te_cosprod(3, 4, F(1, 2)), te_cosprod(4, 3, F(1, 2)), te_cosprod(5, 12, F(1, 4))],
        [te_cos2(-2), te_cos2(1), te_cos2(-3)],
    ]
