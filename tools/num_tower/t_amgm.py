# 算幾圍籬
from nlib import *


# ---------- nm_product：乘開再用算幾 ----------

def nm_product(p, r, s):
    """(a + p b)(r/a + s/b)，a、b > 0：乘開 r + ps + s·a/b + pr·b/a"""
    const = r + p * s
    g = math.isqrt(p * r * s)
    assert g * g == p * r * s
    best = const + 2 * g
    ratio = F(g, s)                    # s·a/b = pr·b/a → a/b = √(pr/s)
    assert ratio * ratio == F(p * r, s)
    naive = 4 * math.isqrt(p * r * s) if False else None
    # 兩次算幾直接相乘：(a + pb) ≥ 2√(p ab)、(r/a + s/b) ≥ 2√(rs/(ab)) → ≥ 4√(prs)
    nv = 4 * g
    assert nv < best
    # 數值驗算
    m = min((A + p * 1) * (F(r) / A + s) for A in [F(i, 100) for i in range(1, 3000)])
    assert m >= best and (ratio + p) * (F(r) / ratio + s) == best
    lhs = "(a + %sb)(\\frac{%d}{a} + %s)" % ("" if p == 1 else str(p), r, "\\frac{1}{b}" if s == 1 else "\\frac{%d}{b}" % s)
    sa = "" if s == 1 else str(s)
    return item("nm_product", "amgm", 1, "乘開再用算幾", 1.1,
                "a、b 是正數，求 %s 的最小值。" % lhs,
                [ch("有人分別用算幾：兩個括號各自 ≥ 2√{…}，相乘得 ≥ %d。%d 是最小值嗎？" % (nv, nv),
                    ["不是：兩個等號不能同時成立", "是，最小值 %d" % nv, "不是：最小值比 %d 小" % nv, "不能用算幾"],
                    "第一個等號要 a = %sb，第二個要 %s" % ("" if p == 1 else str(p), "a = %sb" % ("" if r == s else t(F(r, s)))),
                    "等號條件 a = %sb 和 a = %sb 互相矛盾，%d 取不到" % ("" if p == 1 else str(p), "" if r == s else t(F(r, s)), nv)),
                 fl("改成先乘開：", "%s = [0] + \\frac{%sa}{b} + \\frac{[1]b}{a}" % (lhs, sa), [str(const), str(p * r)], "四項乘開，常數的兩項加起來"),
                 fl("後兩項的積是定值，用算幾：", "\\frac{%sa}{b} + \\frac{%db}{a} ≥ 2√{%d} = [0]" % (sa, p * r, p * r * s), [str(2 * g)],
                    "兩項相乘 = %d" % (p * r * s)),
                 fl("最小值與等號成立的條件：", "最小值 [0]，這時 a : b = [1] : 1", [str(best), a(ratio)],
                    "\\frac{%sa}{b} = \\frac{%db}{a}，a^{2} = %sb^{2}" % (sa, p * r, t(ratio * ratio)))])


# ---------- nm_negative：乘積可以是負的 ----------

def nm_negative(p, q, c, ask):
    """p a^2 + q b^2 = c，求 ab 的最大值或最小值"""
    k = 2 * math.isqrt(p * q)
    assert (k // 2) ** 2 == p * q
    bound = F(c, k)
    val = bound if ask == "max" else -bound
    # 數值驗算：a = √(c/(2p)) cos-ish
    best = max(math.sqrt(c / p) * math.cos(th) * math.sqrt(c / q) * math.sin(th) for th in [i * math.pi / 2000 for i in range(4001)])
    assert near(best, float(bound), 1e-4)
    lhs = poly([(p, "a^{2}"), (q, "b^{2}")])
    return item("nm_negative", "amgm", 2, "乘積可以是負的", 1.15,
                "a、b 是實數，%s = %d，求 ab 的%s值。" % (lhs, c, "最大" if ask == "max" else "最小"),
                [ch("a、b 可能是負的，算幾要怎麼用？", ["%s ≥ %d|ab|" % (lhs, k), "%s ≥ %dab" % (lhs, k), "%s ≥ %d√{ab}" % (lhs, k),
                                              "%s ≥ %d|a + b|" % (lhs, k)],
                    "%sa^{2} 和 %sb^{2} 一定是非負的，可以用算幾；√{a^{2}b^{2}} = |ab|" % ("" if p == 1 else str(p), "" if q == 1 else str(q)),
                    "%d = %s ≥ 2√{%da^{2}b^{2}} = %d|ab|" % (c, lhs, p * q, k)),
                 fl("所以 |ab| 的範圍：", "|ab| ≤ [0]", [a(bound)], "%d ≥ %d|ab|" % (c, k)),
                 fl("ab 的%s值：" % ("最大" if ask == "max" else "最小"), "[0] ≤ ab ≤ [1]，所求 = [2]", [a(-bound), a(bound), a(val)],
                    "%s時 a、b %s" % ("最大值" if ask == "max" else "最小值", "同號" if ask == "max" else "異號"))])


# ---------- nm_chain：兩個等號連起來 ----------

def nm_chain(e1, e2, xyz, ask, val):
    """e1 = (p, q)：\\frac{px + qy}{2} = √{pq xy} ⇒ px = qy；e2 = (r, s)：ry = sz"""
    (p, q), (r, s) = e1, e2
    x, y, z = xyz
    assert p * x == q * y and r * y == s * z and math.gcd(math.gcd(x, y), z) == 1
    v = ask[1](F(x), F(y), F(z))
    assert v == F(val)
    def amgm(a_, u, b_, w):
        return "\\frac{%s%s + %s%s}{2} = √{%d%s%s}" % ("" if a_ == 1 else a_, u, "" if b_ == 1 else b_, w, a_ * b_, u, w)
    return item("nm_chain", "amgm", 2, "兩個等號連起來", 1.15,
                "正數 x、y、z 滿足 %s、%s，求 %s。" % (amgm(p, "x", q, "y"), amgm(r, "y", s, "z"), ask[0]),
                [ch("%s 代表什麼？" % amgm(p, "x", q, "y"), ["%s = %s" % (cof(p, "x", True), cof(q, "y", True)), "x = y",
                                                          "%s = %s" % (cof(q, "x", True), cof(p, "y", True)), "%s + %s = %dxy" % (cof(p, "x", True), cof(q, "y", True), 2 * p * q)],
                    "算幾的等號只在兩數相等時成立", "算術平均 = 幾何平均　⇒　%s = %s" % (cof(p, "x", True), cof(q, "y", True))),
                 fl("同理 %s = %s，求最簡整數比：" % (cof(r, "y", True), cof(s, "z", True)), "x : y : z = [0] : [1] : [2]", [str(x), str(y), str(z)],
                    "先寫 x : y = %d : %d、y : z = %d : %d，把 y 的份數調成一樣" % (q, p, s, r)),
                 fl("代入：", "%s = [0]" % ask[0], [a(v)], "設 x = %sk、y = %sk、z = %sk，k 會約掉" % tuple("" if v == 1 else str(v) for v in (x, y, z)))])


# ---------- nm_tri：三角形裡的矩形 ----------

def nm_tri(l1, l2, on):
    """直角三角形兩股 l1 < l2；on = "hyp"：矩形一邊在斜邊上；"legs"：矩形在直角那個角"""
    hyp = int(round(math.hypot(l1, l2)))
    assert hyp * hyp == l1 * l1 + l2 * l2
    if on == "hyp":
        h = F(l1 * l2, hyp)
        best = hyp * h / 4
        # 驗算：y 是矩形的高，x = hyp(1 − y/h)
        m = max((hyp * (1 - F(i, 400) * h / h) * F(i, 400) * h) for i in range(1, 400))
        assert m <= best and best == hyp * h / 4
        p_ = h / 2
        x_ = F(hyp, 2)
        hs = ("%.1f" % float(h)) if h.denominator != 1 else str(h)
        assert F(hs) == h
        foot = F(l1 * l1, hyp)
        A_, B_, C_ = (0, 0), (hyp, 0), (float(foot), float(h))
        yy = float(h) * 0.42
        xl, xr_ = float(foot) * yy / float(h), hyp - (hyp - float(foot)) * yy / float(h)
        shapes = [poly_sh([A_, B_, C_], "cyan"), poly_sh([(xl, 0), (xr_, 0), (xr_, yy), (xl, yy)], "pink", fill="pink"),
                  seg(C_, (float(foot), 0), "dim", dash=True), lab((hyp / 2, -1.0), str(hyp), "text"),
                  lab((float(foot) / 2 - 0.9, float(h) / 2 + 0.4), str(l1), "text"), lab(((float(foot) + hyp) / 2 + 0.9, float(h) / 2 + 0.4), str(l2), "text")]
        plot = {"x": [-1.0, fx(hyp + 1)], "y": [-1.8, fx(float(h) + 1)], "geo": True, "h": 150, "shapes": shapes}
        return item("nm_tri", "amgm", 2, "三角形裡的矩形", 1.2,
                    "直角三角形的兩股是 %d、%d，斜邊 %d。矩形的一邊在斜邊上，另兩個頂點在兩股上（如圖）。求矩形面積的最大值。" % (l1, l2, hyp),
                    [fl("先算斜邊上的高：", "h = \\frac{%d × %d}{%d} = [0]" % (l1, l2, hyp), [hs], "三角形面積算兩次：\\frac{1}{2} × %d × %d = \\frac{1}{2} × %d × h" % (l1, l2, hyp)),
                     ch("矩形在斜邊上的邊長 x、高 y，關係是？", ["\\frac{x}{%d} + \\frac{y}{%s} = 1" % (hyp, hs), "\\frac{x}{%d} + \\frac{y}{%d} = 1" % (l1, l2),
                                                     "x + y = %d" % hyp, "\\frac{x}{%s} + \\frac{y}{%d} = 1" % (hs, hyp)],
                        "矩形上面的小三角形和原三角形相似：\\frac{x}{%d} = \\frac{%s − y}{%s}" % (hyp, hs, hs), "\\frac{x}{%d} + \\frac{y}{%s} = 1" % (hyp, hs)),
                     fl("算幾：1 = \\frac{x}{%d} + \\frac{y}{%s} ≥ 2√{\\frac{xy}{%s}}" % (hyp, hs, t(hyp * h)), "面積 xy 的最大值 = [0]，這時 x = [1]",
                        [a(best), a(x_)], "兩項相等時：\\frac{x}{%d} = \\frac{y}{%s} = \\frac{1}{2}" % (hyp, hs))],
                    plot=plot)
    # 矩形在直角那個角：x 沿長 l2 的股、y 沿 l1 的股
    best = F(l1 * l2, 4)
    shapes = [poly_sh([(0, 0), (l2, 0), (0, l1)], "cyan"), poly_sh([(0, 0), (l2 * 0.4, 0), (l2 * 0.4, l1 * 0.6), (0, l1 * 0.6)], "pink", fill="pink"),
              lab((l2 / 2, -1.0), str(l2), "text"), lab((-1.0, l1 / 2), str(l1), "text")]
    plot = {"x": [-1.8, fx(l2 + 1)], "y": [-1.8, fx(l1 + 1)], "geo": True, "h": 150, "shapes": shapes}
    return item("nm_tri", "amgm", 2, "三角形裡的矩形", 1.2,
                "直角三角形的兩股是 %d、%d。矩形的兩邊在兩股上、第四個頂點在斜邊上（如圖）。求矩形面積的最大值。" % (l1, l2),
                [ch("矩形沿長 %d 的股的邊是 x、另一邊是 y，關係是？" % l2, ["\\frac{x}{%d} + \\frac{y}{%d} = 1" % (l2, l1), "\\frac{x}{%d} + \\frac{y}{%d} = 1" % (l1, l2),
                                                     "x + y = %d" % hyp, "xy = %d" % (l1 * l2 // 2)],
                    "頂點 (x, y) 在斜邊 \\frac{x}{%d} + \\frac{y}{%d} = 1 上" % (l2, l1), "\\frac{x}{%d} + \\frac{y}{%d} = 1" % (l2, l1)),
                 fl("算幾：1 ≥ 2√{\\frac{xy}{%d}}" % (l1 * l2), "面積 xy 的最大值 = [0]", [a(best)], "1 ≥ 2√{\\frac{xy}{%d}} → xy ≤ \\frac{%d}{4}" % (l1 * l2, l1 * l2)),
                 fl("等號成立時：", "x = [0]，y = [1]", [a(F(l2, 2)), a(F(l1, 2))], "\\frac{x}{%d} = \\frac{y}{%d} = \\frac{1}{2}" % (l2, l1))],
                plot=plot)


def items():
    return [
        [nm_product(16, 9, 1), nm_product(4, 9, 1), nm_product(2, 8, 1)],
        [nm_negative(1, 36, 8, "min"), nm_negative(4, 9, 24, "max"), nm_negative(9, 1, 12, "min")],
        [nm_chain((2, 3), (4, 5), (15, 10, 8), ("\\frac{x + y}{z}", lambda x, y, z: (x + y) / z), F(25, 8)),
         nm_chain((1, 4), (3, 2), (8, 2, 3), ("\\frac{x − z}{y}", lambda x, y, z: (x - z) / y), F(5, 2)),
         nm_chain((3, 1), (2, 1), (1, 3, 6), ("\\frac{y^{2}}{xz}", lambda x, y, z: y * y / (x * z)), F(3, 2))],
        [nm_tri(12, 16, "hyp"), nm_tri(6, 8, "hyp"), nm_tri(9, 12, "legs")],
    ]
