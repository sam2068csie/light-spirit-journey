# 距離鏡面
from lib import *


# ---------- ld_parallel：截距差 d 的平行線 ----------

def ld_parallel(m, diff, m2, diff2):
    n = m * m + 1
    d = rt(F(diff * diff) / n)
    d2 = rt(F(diff2 * diff2) / (m2 * m2 + 1))
    k0 = F(diff, 2) - 1
    h = float(diff) / 2 + 1.7
    xr, yr = [-3.6, 3.6], [-h, h]
    foot = (F(diff * m) / n, k0 - F(diff) / n)
    # 標籤：L1 在線的左邊、L2 在線的右下
    y1 = yr[0] + 2.2
    y2 = yr[0] + 0.8
    l1 = ((y1 - float(k0)) / m - 0.7, y1)
    l2 = ((y2 - float(k0 - diff)) / m + 0.45, y2)
    gen = lambda c: lin(m, -1, 0)[:-4] + (" + k = 0" if c == 0 else " + (k − %d) = 0" % c)
    return {"id": "ld_parallel", "kind": "dist", "tier": 1, "title": "截距差和平行線距離", "tmul": 1.0,
            "stem": "兩條平行線 L_{1}：y = %s + k、L_{2}：y = %s + k − %d，y 截距相差 %d。求 d(L_{1}, L_{2})。" % (cx(m), cx(m), diff, diff),
            "plot": geo(xr, yr, [ln(m, -1, k0, xr, yr, "cyan"), ln(m, -1, k0 - diff, xr, yr, "pink"),
                                 seg((0, k0), (0, k0 - diff), "gold", dash=True), seg((0, k0), foot, "lime", at=1),
                                 lab((0.35, float(k0) - diff / 2 + 0.5), str(diff), "gold"), lab(l1, "L1", "cyan"), lab(l2, "L2", "pink")]),
            "steps": [
                fill("寫成一般式 %s、%s，代平行線距離公式：" % (gen(0), gen(diff)),
                     "d(L_{1}, L_{2}) = \\frac{|k − (k − %d)|}{√{[0]}}" % diff, [n], "分母是 √{a^{2} + b^{2}} = √{%d + 1}" % (m * m)),
                fill("化簡：", "d(L_{1}, L_{2}) = \\frac{%d}{√{%d}} = [0]" % (diff, n), [d.ans()],
                     "有理化：\\frac{%d√{%d}}{%d}" % (diff, n, n) if not is_square(n) else "直接約分"),
                choice("截距明明差 %d，為什麼距離不是 %d？（距離要垂直於直線量）" % (diff, diff), ["%d 是鉛直方向量的" % diff, "要再乘上斜率 %d" % m, "截距差要除以斜率", "距離和截距無關"],
                       "黃色虛線是鉛直量的 %d，綠色才是垂直於直線的距離" % diff, "截距差是鉛直方向，垂直距離 = \\frac{截距差}{√{1 + m^{2}}}"),
                fill("換一組：斜率 %d、截距差 %d 的兩條平行線：" % (m2, diff2),
                     "答：d(L_{1}, L_{2}) = \\frac{%d}{√{1 + %d}} = [0]" % (diff2, m2 * m2), [d2.ans()],
                     "\\frac{%d}{√{%d}}" % (diff2, m2 * m2 + 1))]}


# ---------- ld_bounce：碰兩面牆的路 ----------

def ld_bounce(A, B, offs):
    A1 = (A[0], -A[1])
    B1 = (-B[0], B[1])
    m = F(B1[1] - A1[1]) / (B1[0] - A1[0])
    Px = A1[0] - F(A1[1]) / m
    Qy = A1[1] + m * (0 - A1[0])
    assert Px > 0 and Qy > 0
    L2 = (A1[0] - B1[0]) ** 2 + (A1[1] - B1[1]) ** 2
    xr, yr = box([A, B, A1, B1], pad=0.8)
    o = lambda k: offs.get(k, (8, -8))
    return {"id": "ld_bounce", "kind": "dist", "tier": 2, "title": "碰兩面牆的路", "tmul": 1.2,
            "stem": "A%s、B%s。P 在 x 軸上、Q 在 y 軸上，求 \\ol{AP} + \\ol{PQ} + \\ol{QB} 的最小值，以及此時 P、Q 的坐標。" % (P(*A), P(*B)),
            "plot": geo(xr, yr, [pt(A, "A", off=o("A")), pt(B, "B", off=o("B")),
                                 pt(A1, "A'", "pink", 1, o("A'")), pt(B1, "B'", "pink", 2, o("B'")),
                                 seg(A1, B1, "pink", dash=True, at=3),
                                 poly_sh([A, (Px, 0), (0, Qy), B], "lime", open=True, w=3.0, at=5),
                                 pt((Px, 0), "P", "lime", 5, o("P")), pt((0, Qy), "Q", "lime", 5, o("Q"))]),
            "steps": [
                choice("\\ol{AP} 換成 A 對 x 軸的對稱點 A' 到 P：A' = ？", [P(*A1), P(-A[0], A[1]), P(-A[0], -A[1]), P(A[1], A[0])],
                       "對 x 軸對稱：y 變號", "A'%s，\\ol{AP} = \\ol{A'P}" % P(*A1)),
                choice("\\ol{QB} 換成 B 對 y 軸的對稱點 B' 到 Q：B' = ？", [P(*B1), P(B[0], -B[1]), P(-B[0], -B[1]), P(B[1], B[0])],
                       "對 y 軸對稱：x 變號", "B'%s，\\ol{QB} = \\ol{QB'}" % P(*B1)),
                choice("\\ol{A'P} + \\ol{PQ} + \\ol{QB'} 什麼時候最小？", ["A'、P、Q、B' 共線", "P、Q 三等分 \\ol{A'B'}", "\\ol{AP} = \\ol{QB}", "\\ol{PQ} ∥ \\ol{AB}"],
                       "兩點之間直線最短", "最小值 = \\ol{A'B'}"),
                fill("算出最小值：", "\\ol{A'B'} = √{%d + %d} = [0]" % ((A1[0] - B1[0]) ** 2, (A1[1] - B1[1]) ** 2), [rta(L2)],
                     "(%s − %s)^{2} + (%s − %s)^{2}" % (t(A1[0]), tp(B1[0]), t(A1[1]), tp(B1[1]))),
                fill("直線 A'B' 的斜率是 %s，和兩軸的交點：" % t(m), "答：P([0], 0)、Q(0, [1])", [a(Px), a(Qy)],
                     "y %s %s = %s(x − %s)：令 y = 0、x = 0" % ("+" if A1[1] < 0 else M, t(abs(A1[1])), cx(m, "")[:-0] if False else ("−(" + t(abs(m)) + ")" if m < 0 else "(" + t(m) + ")"), t(A1[0])))]}


# ---------- ld_ratio：反求分割的直線 ----------

def ld_ratio(A, B, a_, b_):
    Pp = (F(2 * A[0] + B[0]) / 3, F(2 * A[1] + B[1]) / 3)
    assert isint(Pp[0]) and isint(Pp[1])
    vA, vB = a_ * A[0] + b_ * A[1], a_ * B[0] + b_ * B[1]
    k = -(a_ * Pp[0] + b_ * Pp[1])
    assert 3 * k == -(2 * vA + vB) and vA > 0 and vB > 0 and vA != vB
    L = poly([(a_, "x"), (b_, "y")]) + " + k = 0"
    xr, yr = box([A, B], pad=1.2)
    fv = lambda p: "%s + %s" % (t(a_ * p[0]), tp(b_ * p[1]))
    return {"id": "ld_ratio", "kind": "dist", "tier": 2, "title": "反求分割的直線", "tmul": 1.2,
            "stem": "A%s、B%s。直線 L：%s 交 \\ol{AB} 於 P，且 \\ol{AP} : \\ol{PB} = 1 : 2。求 k。" % (P(*A), P(*B), L),
            "plot": geo(xr, yr, [seg(A, B, "cyan"), pt(A, "A"), pt(B, "B"), ln(a_, b_, k, xr, yr, "pink", at=5), pt(Pp, "P", "pink", 5)]),
            "steps": [
                choice("L 交 \\ol{AB}（中間的一點），A、B 在 L 的？", ["兩側", "同一側", "L 上", "不一定"],
                       "線段被 L 切開", "A、B 在 L 的兩側：代入的值一正一負"),
                fill("A、B 代入 %s + k：" % poly([(a_, "x"), (b_, "y")]), "A：[0] + k，B：[1] + k", [vA, vB], "%s、%s" % (fv(A), fv(B))),
                choice("\\ol{AP} : \\ol{PB} = d(A, L) : d(B, L) = 1 : 2，而且正負相反：",
                       ["2(%d + k) = −(%d + k)" % (vA, vB), "2(%d + k) = %d + k" % (vA, vB), "%d + k = 2(%d + k)" % (vA, vB), "(%d + k) + (%d + k) = 0" % (vA, vB)],
                       "B 的距離是 A 的 2 倍，符號相反", "2(%d + k) = −(%d + k)" % (vA, vB)),
                fill("解出 k：", "3k = %s ⇒ k = [0]" % t(-(2 * vA + vB)), [a(k)], "%d + 2k = −%d − k" % (2 * vA, vB)),
                fill("驗算：用分點公式，P = (2A + B)/3：", "答：k = %s，P([0], [1])" % t(k), [a(Pp[0]), a(Pp[1])],
                     "((%s + %s)/3, (%s + %s)/3)，代進 %s 剛好成立" % (t(2 * A[0]), tp(B[0]), t(2 * A[1]), tp(B[1]), lin(a_, b_, k)))]}


# ---------- ld_incenter：斜三角形的內心 ----------

def _form(a_, b_, c_, s):
    """s(ah + bk + c)，常數放前面（s = −1）或後面（s = 1）"""
    if s < 0:
        return poly([(-c_, ""), (-a_, "h"), (-b_, "k")])
    return poly([(a_, "h"), (b_, "k"), (c_, "")])


def _collect(lhs, rhs):
    """lhs = rhs（各是 (α, β, γ) 代表 αh + βk + γ），整理成 αh + βk = γ，約分、α > 0"""
    al, be, ga = lhs[0] - rhs[0], lhs[1] - rhs[1], rhs[2] - lhs[2]
    g = math.gcd(math.gcd(al, be), ga)
    if al < 0 or (al == 0 and be < 0):
        g = -g
    return al // g, be // g, ga // g, abs(g)


def _inter(L1, L2):
    a1, b1, c1 = L1
    a2, b2, c2 = L2
    det = a1 * b2 - a2 * b1
    return (F(b1 * c2 - b2 * c1) / det, F(a2 * c1 - a1 * c2) / det)


def ld_incenter(L1, L2, L3, I, r, xr, yr, labs):
    Ls = [L1, L2, L3]
    ns = [int(math.isqrt(a_ * a_ + b_ * b_)) for a_, b_, _ in Ls]
    for (a_, b_, c_), n in zip(Ls, ns):
        assert n * n == a_ * a_ + b_ * b_
        v = a_ * I[0] + b_ * I[1] + c_
        assert abs(v) == r * n and (v > 0) == (c_ > 0), "原點和內心要同側、距離是 r"
    assert ns[0] == ns[1] == 5 and ns[2] == 13
    s = [1 if c_ > 0 else -1 for _, _, c_ in Ls]
    assert s[0] == -s[1], "不處理正負號就會錯"
    V = [_inter(L1, L2), _inter(L1, L3), _inter(L2, L3)]
    f = [_form(*L, si) for L, si in zip(Ls, s)]
    tri = lambda L, si: (si * L[0], si * L[1], si * L[2])
    t1, t2, t3 = [tri(L, si) for L, si in zip(Ls, s)]
    e1 = _collect(t1, t2)
    e2 = _collect((13 * t1[0], 13 * t1[1], 13 * t1[2]), (5 * t3[0], 5 * t3[1], 5 * t3[2]))
    for e in (e1, e2):
        assert e[0] * I[0] + e[1] * I[1] == e[2]
    raw = lambda L: poly([(L[0], "h"), (L[1], "k"), (L[2], "")])
    neg = lambda L, si: _form(L[0], L[1], L[2], -si)
    eq = lambda e: poly([(e[0], "h"), (e[1], "k")]) + " = [0]"
    sgn1 = "負的" if s[0] < 0 else "正的"
    lhs13 = "13(%s) = 5(%s)" % (f[0], f[2])
    big = (e2[0] * e2[3], e2[1] * e2[3], e2[2] * e2[3])
    if xr is None:
        xr, yr = box(V, pad=1.0)
    if labs is None:
        # 每條邊的中點，往三角形外面推一點
        sides = [(V[0], V[1], L1), (V[0], V[2], L2), (V[1], V[2], L3)]
        labs = []
        for p_, q_, L in sides:
            mx, my = (float(p_[0]) + float(q_[0])) / 2, (float(p_[1]) + float(q_[1])) / 2
            n = math.hypot(L[0], L[1])
            sg = 1 if (L[0] * I[0] + L[1] * I[1] + L[2]) < 0 else -1
            labs.append((mx + sg * 0.8 * L[0] / n - 0.3, my + sg * 0.8 * L[1] / n))
    ex = lambda m_, L, si: _form(m_ * L[0], m_ * L[1], m_ * L[2], si)
    return {"id": "ld_incenter", "kind": "dist", "tier": 3, "title": "斜三角形的內心", "tmul": 1.35,
            "stem": "三條直線 L_{1}：%s、L_{2}：%s、L_{3}：%s 圍成一個三角形，原點在三角形裡面。求內心和內切圓半徑。" % (lin(*L1), lin(*L2), lin(*L3)),
            "plot": geo(xr, yr, [poly_sh(V, "cyan"), lab(labs[0], "L1", "cyan"), lab(labs[1], "L2", "cyan"), lab(labs[2], "L3", "cyan"),
                                 pt((0, 0), "O", "dim", 0, (-20, 14)), circ(I, r, "pink", at=6), pt(I, "I", "pink", 6)]),
            "steps": [
                fill("原點代進三條線的左邊：", "L_{1}：[0]，L_{2}：[1]，L_{3}：[2]", [a(L1[2]), a(L2[2]), a(L3[2])], "x = 0、y = 0"),
                choice("內心 I(h, k) 也在三角形裡面，和原點在每一條線的同一側。所以 %s 是正的還是負的？" % raw(L1),
                       [sgn1] + [o for o in ["負的", "正的", "0", "正負都有可能"] if o != sgn1],
                       "同側 ⇔ 代入的正負號一樣，原點代入是 %s" % t(L1[2]),
                       "d(I, L_{1}) = (%s)/5，d(I, L_{2}) = (%s)/5，d(I, L_{3}) = (%s)/13" % (f[0], f[1], f[2])),
                choice("d(I, L_{1}) = d(I, L_{2})：", ["%s = %s" % (f[0], f[1]), "%s = %s" % (neg(L1, s[0]), f[1]), "%s = %s" % (f[0], neg(L2, s[1])),
                                                       "%s = %s" % (poly([(L1[0], "h"), (L1[1], "k")]), poly([(L2[0], "h"), (L2[1], "k")]))],
                       "分母都是 5，直接把分子寫成一樣", "%s = %s" % (f[0], f[1])),
                fill("整理：", eq(e1), [e1[2]], "移項：h、k 放左邊，數字放右邊"),
                fill("d(I, L_{1}) = d(I, L_{3})：%s，整理%s：" % (lhs13, "再除以 %d" % e2[3] if e2[3] > 1 else ""), eq(e2), [e2[2]],
                     "%s = %s ⇒ %s = %s" % (ex(13, L1, s[0]), ex(5, L3, s[2]), poly([(big[0], "h"), (big[1], "k")]), t(big[2]))),
                fill("聯立，再算半徑：", "答：I([0], [1])，r = [2]", [a(I[0]), a(I[1]), a(r)],
                     "兩式聯立解 h、k。r = d(I, L_{2}) = (%s)/5" % f[1])]}


def items():
    return [
        [ld_parallel(2, 5, 3, 10), ld_parallel(3, 5, 1, 4), ld_parallel(1, 6, 2, 10)],
        [ld_bounce((4, 1), (1, 3), {"B'": (-26, -6), "P": (4, 16), "Q": (8, 4)}),
         ld_bounce((2, 1), (1, 3), {"B'": (-26, -6), "P": (4, 16), "Q": (8, 4), "A": (8, -4)}),
         ld_bounce((3, 2), (1, 4), {"B'": (-26, -6), "P": (4, 16), "Q": (8, 4)})],
        [ld_ratio((1, 2), (7, 5), 2, 1), ld_ratio((0, 1), (6, 7), 1, 2), ld_ratio((-1, 4), (5, 1), 3, 1)],
        [ld_incenter((3, 4, -20), (4, -3, 5), (5, -12, -24), (2, 1), 2, [-4.8, 6.8], [-4.4, 4.6], [(4.5, 2.9), (-2.5, 1.0), (1.4, -2.9)])]
        + [ld_incenter(*v) for v in INC],
    ]


INC = [((3, 4, 12), (4, -3, -4), (5, -12, 6), (-1, -1), 1, None, None, None),
       ((4, -3, -8), (3, 4, 24), (5, -12, 12), (-2, -2), 2, None, None, None)]
