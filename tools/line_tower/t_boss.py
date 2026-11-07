# 試煉大題（原本的 6 題）
from lib import *
import t_boss2


def _through(m, p):
    m = F(m)
    return lin_norm(m, -1, p[1] - m * p[0])


def _ps(m, p):
    """點斜式 y − 2 = −2(x − 4)"""
    m = F(m)
    ys = "y" if p[1] == 0 else "y %s %s" % ("+" if p[1] < 0 else M, t(abs(p[1])))
    xs = "x" if p[0] == 0 else "x %s %s" % ("+" if p[0] < 0 else M, t(abs(p[0])))
    if abs(m) == 1:
        co = "" if m > 0 else M
    elif isint(m):
        co = t(m)
    else:
        co = (M if m < 0 else "") + "(" + t(abs(m)) + ")"
    return "%s = %s(%s)" % (ys, co, xs)


# ---------- lb_chord：過定點的弦 ----------

def lb_chord(R, Pp, offs):
    s = Pp[0] ** 2 + Pp[1] ** 2
    assert s < R * R and Pp[0] != 0 and Pp[1] != 0
    mop = F(Pp[1], Pp[0])
    mperp = -1 / mop
    short = rt(R * R - s)
    short = Surd(2 * short.c, short.n)
    S = _through(mperp, Pp)
    OPl = lin_norm(Pp[1], -Pp[0], 0)
    dis1 = _through(-mop, Pp)
    mid = (F(Pp[0], 2), F(Pp[1], 2))
    dis2 = _through(mperp, mid)
    le = lambda L: poly([(L[0], "x"), (L[1], "y")]) + " = " + t(-L[2])
    opts = [le(S), le(OPl), le(dis1), le(dis2)]
    xr, yr = box([], pad=1.4, circles=[((0, 0), R)])
    return {"id": "lb_chord", "kind": "boss", "tier": 2, "title": "過定點的弦", "tmul": 1.6,
            "stem": "圓 x^{2} + y^{2} = %d 內有一點 P%s。(1) 過 P 最短的弦，長度與方程式 (2) 過 P 最長的弦 (3) 過 P 的弦，中點 M 的軌跡" % (R * R, P(*Pp)),
            "plot": geo(xr, yr, [circ((0, 0), R, "cyan"), pt((0, 0), "O", "cyan", 0, (-20, 16)), pt(Pp, "P", "pink", 0, offs.get("P", (8, -8))),
                                 ln(*S, xr, yr, "lime", at=3), ln(*OPl, xr, yr, "dim", dash=True, at=4),
                                 circ(mid, math.sqrt(s) / 2, "gold", at=6)]),
            "steps": [
                choice("過 P 的弦，什麼時候最短？", ["和 \\ol{OP} 垂直的時候", "和 \\ol{OP} 平行的時候", "和 \\ol{OP} 夾 45° 的時候", "通過圓心的時候"],
                       "d(O, 弦) 越大，弦越短。d(O, 弦) 最大就是 \\ol{OP} 本身", "(1)　最短的弦 ⊥ \\ol{OP}，此時 d(O, 弦) = \\ol{OP}", part="(1)"),
                fill("算長度：", "\\ol{OP}^{2} = [0]，最短弦長 = 2√{%d − %d} = [1]" % (R * R, s), [s, short.ans()], "%d + %d" % (Pp[0] ** 2, Pp[1] ** 2)),
                choice("\\ol{OP} 的斜率是 %s，最短弦過 P、斜率 %s：" % (t(mop), t(mperp)), opts, _ps(mperp, Pp),
                       "最短弦 %s，長 %s" % (le(S), short.text())),
                fill("最長的弦是通過圓心的直徑：", "(2)　最長弦長 [0]，在直線 %s 上" % le(OPl), [2 * R], "2r", part="(2)"),
                choice("弦的中點 M 和圓心連線，會和弦垂直。所以？", ["\\ol{OM} ⊥ \\ol{MP}", "\\ol{OM} = \\ol{MP}", "\\ol{OM} ∥ \\ol{MP}", "\\ol{OM} = %d" % R],
                       "P 也在弦上", "(3)　\\ol{OM} ⊥ \\ol{MP}：M 在以 \\ol{OP} 為直徑的圓上", part="(3)"),
                fill("以 \\ol{OP} 為直徑的圓：", "圓心 ([0], [1])，r^{2} = [2]", [a(mid[0]), a(mid[1]), a(F(s, 4))], "\\ol{OP} 的中點，半徑 √{%d}/2" % s),
                choice("最後檢查：這個圓上的每一點都會是某條弦的中點嗎？", ["會，是完整的圓", "要拿掉 O", "要拿掉 P", "只有半個圓"],
                       "O：直徑的中點。P：最短弦的中點。小圓整個在大圓裡面", "答：%s（完整的圓）" % circ_eq(mid[0], mid[1], F(s, 4)))]}


# ---------- lb_twocircle：兩個圓的交點 ----------

def lb_twocircle(R, K2, X, Y, xr, yr):
    r2 = (K2[0] - X[0]) ** 2 + (K2[1] - X[1]) ** 2
    assert (K2[0] - Y[0]) ** 2 + (K2[1] - Y[1]) ** 2 == r2
    for p_ in (X, Y):
        assert p_[0] ** 2 + p_[1] ** 2 == R * R
    D, E, Fc = -2 * K2[0], -2 * K2[1], K2[0] ** 2 + K2[1] ** 2 - r2
    # C1 − C2：−R^2 − (Dx + Ey + F) = 0 → −Dx − Ey = R^2 + F
    La, Lb, Lc = lin_norm(-D, -E, -(R * R + Fc))
    assert La * X[0] + Lb * X[1] + Lc == 0 and La * Y[0] + Lb * Y[1] + Lc == 0 and La > 0 and Lb > 0 and Lc < 0
    dd2 = F(Lc * Lc, La * La + Lb * Lb)
    chord = rt(F(R * R) - dd2)
    chord = Surd(2 * chord.c, chord.n)
    cd2 = K2[0] ** 2 + K2[1] ** 2
    rr = rt(r2)
    assert abs(R - rr.val()) < math.sqrt(cd2) < R + rr.val()
    k = F(-R * R, -Lc)
    kk = -k  # 係數是 −kk·La…
    fam = "x^{2} + y^{2} − %d + k(%s)" % (R * R, poly([(La, "x"), (Lb, "y"), (Lc, "")]))
    L = lin(La, Lb, Lc)
    Lstr = poly([(La, "x"), (Lb, "y")]) + " = " + t(-Lc)
    # 最後的圓：x^2 + y^2 + k(La x + Lb y) = 0
    fa, fb = -k * La, -k * Lb
    oc = (fa / 2, fb / 2)
    xs = lambda c_: poly([(c_[0], "x"), (c_[1], "y")]) + " = " + t(c_[2])
    oc_ = lin_norm(K2[1], -K2[0], 0)
    opts1 = [Lstr, poly([(oc_[0], "x"), (oc_[1], "y")]) + " = 0",
             poly([(La, "x"), (Lb, "y")]) + " = " + t(-2 * Lc), poly([(La, "x"), (Lb, "y")]) + " = " + t(Lc)]
    d2t = dd2
    return {"id": "lb_twocircle", "kind": "boss", "tier": 2, "title": "兩個圓的交點", "tmul": 1.6,
            "stem": "C_{1}：x^{2} + y^{2} = %d，C_{2}：%s。(1) 兩圓的公共弦 (2) 公共弦長 (3) 過兩個交點和原點的圓" % (R * R, poly([(1, "x^{2}"), (1, "y^{2}"), (D, "x"), (E, "y"), (Fc, "")]) + " = 0"),
            "plot": geo(xr, yr, [circ((0, 0), R, "cyan"), circ(K2, rr.val(), "pink"),
                                 ln(La, Lb, Lc, xr, yr, "lime", at=2), pt(X, "", "lime", 2), pt(Y, "", "lime", 2),
                                 circ(oc, math.sqrt(float(oc[0] ** 2 + oc[1] ** 2)), "gold", at=6)]),
            "steps": [
                choice("先看位置：圓心距 %s，兩個半徑是 %d 和 %s。" % (rtt(cd2), R, rr.text()) if rr.val() != R else "先看位置：圓心距 %s，兩個半徑都是 %d。" % (rtt(cd2), R),
                       ["相交於兩點", "外切", "外離", "內含"],
                       "|r_{1} − r_{2}| < %s < r_{1} + r_{2}" % rtt(cd2), "|r_{1} − r_{2}| < %s < r_{1} + r_{2}：相交" % rtt(cd2)),
                choice("兩式相減，x^{2}、y^{2} 消掉：", opts1, "%s − (%s) = 0" % (t(-R * R), poly([(D, "x"), (E, "y"), (Fc, "")])),
                       "(1)　公共弦 %s（交點 %s、%s）" % (Lstr, P(*X), P(*Y)), part="(1)"),
                fill("d(O, 公共弦) = %s，用畢氏定理：" % rtt(dd2), "(2)　公共弦長 = 2√{%d − %s} = [0]" % (R * R, t(d2t)), [chord.ans()],
                     "√{%s} 再乘 2" % t(F(R * R) - dd2), part="(2)"),
                choice("過兩個交點的圓（圓系）可以寫成：", [fam + " = 0", "(x^{2} + y^{2} − %d)(%s) = 0" % (R * R, poly([(La, "x"), (Lb, "y"), (Lc, "")])),
                                                     "x^{2} + y^{2} − %d + %s = k" % (R * R, poly([(La, "x"), (Lb, "y"), (Lc, "")])), "(1 + k)(x^{2} + y^{2}) − %d = 0" % (R * R)],
                       "C + kL = 0：交點同時讓 C、L 都是 0", "(3)　" + fam + " = 0", part="(3)"),
                fill("過原點：", "%s %s k = 0 ⇒ k = [0]" % (t(-R * R), "+" if Lc > 0 else "−") if False else "−%d − %sk = 0 ⇒ k = [0]" % (R * R, "" if -Lc == 1 else str(-Lc)),
                     [a(k)], "x = y = 0 代進去"),
                fill("代回去：", "答：x^{2} + y^{2} − [0]x − [1]y = 0", [a(fa), a(fb)], "%s + %s" % (t(-R * R), "(" + t(k) + ")(" + poly([(La, "x"), (Lb, "y"), (Lc, "")]) + ")"))]}


# ---------- lb_triangle：三邊圍出的三角形 ----------

def lb_triangle(K, r2, A, B, C, xr, yr):
    assert B[1] == C[1]
    for p_ in (A, B, C):
        assert (p_[0] - K[0]) ** 2 + (p_[1] - K[1]) ** 2 == r2
    L1 = lin_norm(*(_line2(A, B)))
    L2 = (0, 1, -B[1])
    L3 = lin_norm(*(_line2(A, C)))
    mx = F(B[0] + C[0], 2)
    assert mx == K[0]
    Mac = (F(A[0] + C[0], 2), F(A[1] + C[1], 2))
    mac = F(C[1] - A[1], C[0] - A[0])
    mp = -1 / mac
    bint = Mac[1] - mp * Mac[0]
    assert K[1] == mp * K[0] + bint
    mka = F(A[1] - K[1], A[0] - K[0])
    mt = -1 / mka
    T = _through(mt, A)
    opts_t = t_boss2._uniq([lin(*T)], [lin(*_through(-mt, A)), lin(T[0], T[1], -T[2]), lin(*_through(mka, A)), lin(*_through(mt, K)), lin(*_through(2 * mt, A))])
    xopts = ["x = %s" % t(mx), "y = %s" % t(mx), "x = %s" % t(mx + 1), "x = %s" % t(-mx) if mx != 0 else "x = −1"]
    perp_s = "y = %s" % cx(mp) + " + [0]" if True else ""
    # A 是 L1、L3 的交點；B 是 L1、L2；C 是 L2、L3
    return {"id": "lb_triangle", "kind": "boss", "tier": 3, "title": "三邊圍出的三角形", "tmul": 1.7,
            "stem": "三條直線 L_{1}：%s、L_{2}：%s、L_{3}：%s 圍成 △ABC（A = L_{1}、L_{3} 的交點，B = L_{1}、L_{2}，C = L_{2}、L_{3}）。(1) 三個頂點 (2) 外接圓 (3) 外接圓在 A 的切線" % (lin(*L1), lin(*L2), lin(*L3)),
            "plot": geo(xr, yr, [ln(*L1, xr, yr, "cyan"), ln(*L2, xr, yr, "cyan"), ln(*L3, xr, yr, "cyan"),
                                 pt(A, "A", "gold", 1, (-22, -6)), pt(B, "B", "gold", 1, (-22, 16)), pt(C, "C", "gold", 1, (6, 16)),
                                 circ(K, math.sqrt(r2), "pink", at=4), pt(K, "K", "pink", 4), ln(*T, xr, yr, "lime", at=6)]),
            "steps": [
                fill("兩兩聯立：", "(1)　A([0], [1])、B([2], %s)、C([3], %s)" % (t(B[1]), t(C[1])), [a(A[0]), a(A[1]), a(B[0]), a(C[0])],
                     "B、C：y = %s 代進去。A：L_{1}、L_{3} 聯立" % t(B[1]), part="(1)"),
                choice("外心到三個頂點一樣遠，在 \\ol{BC} 的中垂線上：", xopts,
                       "B、C 的 y 一樣，中點 x = (%s + %s)/2" % (t(B[0]), tp(C[0])), "(2)　外心在 x = %s 上" % t(mx), part="(2)"),
                fill("\\ol{AC} 的中點 %s，斜率 %s，中垂線斜率 %s：" % (P(*Mac), t(mac), t(mp)), "\\ol{AC} 的中垂線：y = %s + [0]" % cx(mp), [a(bint)],
                     "%s = %s × %s + b" % (t(Mac[1]), tp(mp), tp(Mac[0]))),
                fill("外心和半徑：", "K([0], [1])，r^{2} = [2]", [a(K[0]), a(K[1]), r2],
                     "x = %s 代進中垂線。r^{2} = %s^{2} + %s^{2}" % (t(mx), tp(C[0] - K[0]), tp(C[1] - K[1]))),
                fill("切線和半徑 \\ol{KA} 垂直：", "(3)　m_{KA} = [0]，切線斜率 [1]", [a(mka), a(mt)],
                     "(%s − %s)/(%s − %s)" % (t(A[1]), tp(K[1]), t(A[0]), tp(K[0])), part="(3)"),
                choice("過 A%s、斜率 %s：" % (P(*A), t(mt)), opts_t, _ps(mt, A),
                       "答：%s，切線 %s" % (circ_eq(K[0], K[1], r2), lin(*T)))]}


def _line2(p, q):
    """過 p、q 的直線 ax + by + c = 0"""
    a_ = q[1] - p[1]
    b_ = p[0] - q[0]
    return a_, b_, -(a_ * p[0] + b_ * p[1])


# ---------- lb_region：區域裡最大的圓 ----------

def lb_region(a1, b1, a2, b2, c):
    n1 = int(math.isqrt(a1 * a1 + b1 * b1))
    n2 = int(math.isqrt(a2 * a2 + b2 * b2))
    hr = F(n1 + b1, a1)          # h = hr·r
    r = F(c) / (a2 * hr + b2 + n2)
    h = hr * r
    A = F(c, a2)
    Bx = F(c) / (a2 + b2 * F(a1, b1))
    By = F(a1, b1) * Bx
    for v in (r, h, A, Bx, By):
        assert isint(v)
    xr, yr = box([(A, 0), (Bx, By)], pad=1.0)
    l1 = poly([(a1, "x"), (-b1, "y")])
    l2 = poly([(a2, "x"), (b2, "y")])
    finals = [circ_eq(h, r, r * r), circ_eq(h, r, r), circ_eq(r, h, r * r), circ_eq(-h, -r, r * r)]
    tot = a2 * hr + b2 + n2
    return {"id": "lb_region", "kind": "boss", "tier": 3, "title": "區域裡最大的圓", "tmul": 1.7,
            "stem": "區域 R：y ≥ 0、%s ≥ 0、%s ≤ %d。(1) R 的頂點 (2) R 裡面能放的最大圓：圓心與半徑 (3) 這個圓的方程式" % (l1, l2, c),
            "plot": geo(xr, yr, [poly_sh([(0, 0), (A, 0), (Bx, By)], "cyan", fill="cyan", alpha=0.15),
                                 pt((0, 0), "O", "gold", 0, (-20, 16)), pt((A, 0), "A", "gold", 1, (6, 16)), pt((Bx, By), "B", "gold", 1),
                                 circ((h, r), r, "pink", at=5), pt((h, r), "I", "pink", 5)]),
            "steps": [
                fill("三條邊界兩兩聯立：", "(1)　O(0, 0)、A([0], 0)、B([1], [2])", [a(A), a(Bx), a(By)],
                     "A：y = 0 代進 %s = %d。B：y = %s 代進去" % (l2, c, cx(F(a1, b1))), part="(1)"),
                choice("三角形區域裡最大的圓是？", ["內切圓", "以 \\ol{OA} 為直徑的圓", "外接圓", "以重心為圓心的圓"],
                       "要碰到三條邊又不跑出去", "(2)　最大的圓 = 內切圓，圓心 I(h, r)（到 y = 0 的距離是 r）", part="(2)"),
                choice("I 在 R 裡面，%s 是正的還是負的？" % poly([(a1, "h"), (-b1, "r")]), ["正的（R 裡面 %s ≥ 0）" % l1, "負的", "0", "正負都有可能"],
                       "看區域的不等式", "d(I, %s = 0) = (%s)/%d，d(I, %s = %d) = (%s)/%d" % (l1, poly([(a1, "h"), (-b1, "r")]), n1, l2, c, poly([(c, ""), (-a2, "h"), (-b2, "r")]), n2)),
                fill("(%s)/%d = r：" % (poly([(a1, "h"), (-b1, "r")]), n1), "h = [0]r", [a(hr)], "%sh = %sr" % (a1, n1 + b1)),
                fill("(%s)/%d = r，代 h = %s：" % (poly([(c, ""), (-a2, "h"), (-b2, "r")]), n2, cx(hr, "r")), "%d = %sr ⇒ r = [0]，圓心 ([1], [2])" % (c, t(tot)), [a(r), a(h), a(r)],
                     "%d − %sr − %dr = %dr" % (c, t(a2 * hr), b2, n2)),
                choice("圓的方程式：", finals, "圓心 %s、半徑 %s" % (P(h, r), t(r)), "答：(3)　" + finals[0], part="(3)")]}


# ---------- lb_reflect：取水再去花圃 ----------

def lb_reflect(a0, K, r, offs):
    A = (0, a0)
    A1 = (0, -a0)
    ak2 = K[0] ** 2 + (K[1] + a0) ** 2
    ak = rt(ak2)
    assert ak.n == 1 and ak.c > r
    ak = int(ak.c)
    m = F(K[1] + a0, K[0])
    Px = F(a0) / m
    AK2 = K[0] ** 2 + (K[1] - a0) ** 2
    tl = rt(AK2 - r * r)
    u = (K[0] / ak, (K[1] + a0) / ak)
    E = (K[0] - r * u[0], K[1] - r * u[1])
    xr, yr = box([A, A1], pad=1.0, circles=[(K, r)])
    return {"id": "lb_reflect", "kind": "boss", "tier": 3, "title": "取水再去花圃", "tmul": 1.6,
            "stem": "小光在 A%s，要先走到湖岸（x 軸）取水，再走到圓形花圃 %s 的邊緣。(1) 最短要走多遠？(2) 在哪裡取水？(3) 從 A 看花圃，切線段多長？" % (P(*A), circ_eq(K[0], K[1], r * r)),
            "plot": geo(xr, yr, [circ(K, r, "lime"), pt(K, "K", "lime"), pt(A, "A", "gold", 0, (-22, -6)),
                                 pt(A1, "A'", "pink", 1, (-26, 10)), seg(A1, (Px, 0), "pink", dash=True, at=2),
                                 poly_sh([A, (Px, 0), E], "gold", open=True, w=3.0, at=4), pt((Px, 0), "P", "gold", 4, offs.get("P", (4, 18)))]),
            "steps": [
                choice("A 對 x 軸的對稱點：", ["A'" + P(*A1), "A'" + P(*A), "A'" + P(-a0, 0), "A'" + P(a0, 0)], "y 變號",
                       "(1)　A'%s，\\ol{AP} = \\ol{A'P}" % P(*A1), part="(1)"),
                choice("A'、P、K 在同一直線上的時候最短。最短是？", ["\\ol{A'K} − r", "\\ol{A'K} + r", "\\ol{AK} − r", "\\ol{A'K}"],
                       "到圓的最近距離：到圓心的距離減半徑", "最短 = \\ol{A'K} − %d" % r),
                fill("算出來：", "\\ol{A'K} = [0]，最短 [1]", [ak, ak - r], "√{%d + %d}" % (K[0] ** 2, (K[1] + a0) ** 2)),
                fill("直線 A'K 的斜率 %s，和 x 軸的交點：" % ("%d/%d = %s" % (K[1] + a0, K[0], t(m)) if F(K[1] + a0, K[0]).denominator != K[0] else t(m)),
                     "(2)　P([0], 0)", [a(Px)], "y = %s − %d，令 y = 0" % (cx(m), a0), part="(2)"),
                fill("切線段和半徑垂直，用畢氏定理：", "(3)　\\ol{AK}^{2} = [0]，切線段長 = √{%d − %d} = [1]" % (AK2, r * r), [AK2, tl.ans()],
                     "%d + %d。√{%d} = %s" % (K[0] ** 2, (K[1] - a0) ** 2, AK2 - r * r, tl.text()) if tl.n != AK2 - r * r else "%d + %d" % (K[0] ** 2, (K[1] - a0) ** 2), part="(3)")]}


# ---------- lb_family：繞定點轉的直線 ----------

def lb_family(K, r, Pp):
    h, k = K
    p1, p2 = Pp
    u, v = h - p1, k - p2
    kp2 = u * u + v * v
    assert kp2 < r * r and u != 0 and v != 0
    d4 = abs(u)
    m4 = F(v * v - u * u, 2 * u * v)
    assert m4 != -F(u, v)    # 和最短弦那條不一樣
    # 最短：L ⊥ KP
    mkp = F(p2 - k, p1 - h)
    ms = -1 / mkp
    short = rt(r * r - kp2)
    short = Surd(2 * short.c, short.n)
    c4 = rt(r * r - d4 * d4)
    c4full = Surd(2 * c4.c, c4.n)
    Fc = h * h + k * k - r * r
    Ceq = poly([(1, "x^{2}"), (1, "y^{2}"), (-2 * h, "x"), (-2 * k, "y"), (Fc, "")]) + " = 0"
    Leq = poly([(1, "mx"), (-1, "y"), (-p1, "m"), (p2, "")]) + " = 0"
    xs = "x" if p1 == 0 else "(x %s %d)" % (M if p1 > 0 else "+", abs(p1))
    ys = "y" if p2 == 0 else "(y %s %d)" % (M if p2 > 0 else "+", abs(p2))
    pin = poly([(p1 * p1, ""), (p2 * p2, ""), (-2 * h * p1, ""), (-2 * k * p2, ""), (Fc, "")])
    pval = p1 * p1 + p2 * p2 - 2 * h * p1 - 2 * k * p2 + Fc
    assert pval < 0
    # |m u − v|，首項變正
    s_ = 1 if u > 0 else -1
    num = poly([(s_ * u, "m"), (-s_ * v, "")])
    lhs = "(%s)^{2}" % num
    rhs = "m^{2} + 1" if d4 == 1 else "%d(m^{2} + 1)" % (d4 * d4)
    xr, yr = box([], pad=1.0, circles=[(K, r)])
    # 最短弦那條線、(4) 的那條、鉛直線
    Ls = lin_norm(ms, -1, p2 - ms * p1)
    L4 = lin_norm(m4, -1, p2 - m4 * p1)
    return {"id": "lb_family", "kind": "boss", "tier": 3, "title": "繞定點轉的直線", "tmul": 1.7,
            "stem": "圓 C：%s，直線 L：%s。(1) L 一定通過的點 (2) L 和 C 的關係 (3) 弦最短時的 m 與弦長 (4) 弦長是 %s 時的 m" % (Ceq, Leq, c4full.text()),
            "plot": geo(xr, yr, [circ(K, r, "cyan"), pt(K, "K", "cyan"), pt(Pp, "P", "pink", 1),
                                 ln(*Ls, xr, yr, "lime", at=5), ln(*L4, xr, yr, "gold", dash=True, at=8), ln(1, 0, -p1, xr, yr, "dim", dash=True, at=9)]),
            "steps": [
                choice("整理成 m%s − %s = 0，不管 m 是多少都通過：" % (xs, ys), t_boss2._uniq([P(p1, p2)], [P(-p1, p2), P(p1, -p2), P(p2, p1), P(-p1, -p2), P(p1, p2 + 1)]),
                       "%s = 0 而且 %s = 0" % (xs.strip("()"), ys.strip("()")), "(1)　L 一定通過 P%s" % P(p1, p2), part="(1)"),
                fill("配方：", "圓心 K([0], [1])，半徑 [2]", [a(h), a(k), r], "%s^{2} + %s^{2} = %s" % (sh("x", h), sh("y", k), " + ".join(t(v_) for v_ in [-Fc, h * h, k * k] if v_ != 0))),
                choice("P 代進圓的式子：%s = %s < 0，表示？" % (pin, t(pval)), ["P 在圓內，一定交兩點", "P 在圓外，可能不交", "P 在圓上，一定相切", "L 一定過圓心"],
                       "式子 < 0 ⇔ 點到圓心的距離 < r", "(2)　P 在圓內 ⇒ L 和 C 一定交於兩點", part="(2)"),
                choice("繞著 P 轉，弦什麼時候最短？", ["L ⊥ \\ol{KP}", "L 通過圓心", "L ∥ \\ol{KP}", "L 是水平線"],
                       "d(K, L) 最大就是 \\ol{KP}", "(3)　最短弦 ⊥ \\ol{KP}", part="(3)"),
                fill("斜率：", "m_{KP} = [0] ⇒ m = [1]", [a(mkp), a(ms)], "(%s − %s)/(%s − %s)，垂直就是負倒數" % (t(p2), tp(k), t(p1), tp(h))),
                fill("\\ol{KP}^{2} = %d：" % kp2, "最短弦長 = 2√{%d − %d} = [0]" % (r * r, kp2), [short.ans()], "直接寫 %s" % short.text()),
                fill("弦長 %s，半弦長 %s：" % (c4full.text(), c4.text()), "(4)　d(K, L) = √{%d − %s} = [0]" % (r * r, t(c4.sq())), [d4],
                     "(%s)^{2} = %s" % (c4.text(), t(c4.sq())), part="(4)"),
                fill("d(K, L) = \\frac{|%s|}{√{m^{2} + 1}} = %d，平方：" % (num, d4), "%s = %s ⇒ m = [0]" % (lhs, rhs), [a(m4)],
                     "m^{2} 消掉了：%s = %s" % (poly([(-2 * u * v, "m")]), t(u * u - v * v))),
                choice("直線 x = %d 也通過 P，d(K, L) = %d，弦長也是 %s。為什麼答案只有 m = %s？" % (p1, d4, c4full.text(), t(m4)),
                       ["它不在這組直線裡", "x = %d 和圓不相交" % p1, "x = %d 不通過 P" % p1, "它的弦長是 %s" % short.text()],
                       "y 的係數固定是 −1，L 不會是鉛直線", "答：(4)　m = %s（x = %d 不在這組直線裡）" % (t(m4), p1))]}


def items():
    return [
        [lb_chord(5, (4, 2), {}), lb_chord(6, (2, 4), {}), lb_chord(7, (-4, 2), {"P": (-20, -8)})],
        [lb_twocircle(5, (5, 5), (5, 0), (0, 5), [-6.4, 11.4], [-6.4, 11.4]),
         lb_twocircle(5, (8, 4), (3, 4), (5, 0), [-6.4, 14.2], [-6.4, 9.8]),
         lb_twocircle(5, (1, 7), (4, 3), (-3, 4), [-6.4, 7.4], [-6.4, 12.6])],
        [lb_triangle((1, 2), 25, (-2, 6), (-3, -1), (5, -1), [-5.0, 7.0], [-4.0, 8.0]),
         lb_triangle((2, 1), 20, (0, 5), (-2, -1), (6, -1), [-4.0, 8.4], [-4.0, 6.8]),
         lb_triangle((1, -1), 50, (-4, 4), (-6, 0), (8, 0), [-8.4, 9.6], [-9.0, 7.4])],
        [lb_region(12, 5, 4, 3, 56), lb_region(4, 3, 4, 3, 48), lb_region(4, 3, 12, 5, 168)],
        [lb_reflect(2, (6, 6), 2, {}), lb_reflect(1, (3, 3), 1, {}), lb_reflect(2, (8, 4), 2, {})],
        [lb_family((1, 2), 5, (2, 1)), lb_family((1, 2), 5, (2, 0)), lb_family((-1, 1), 5, (1, 0))],
    ] + t_boss2.items()
