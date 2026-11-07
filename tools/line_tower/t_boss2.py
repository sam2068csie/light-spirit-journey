# 試煉大題（新增的 6 題：lb_touch、lb_square、lb_pencil 難度 2；lb_kite、lb_diff、lb_count3 難度 3）
from lib import *
from t_tangent import _fac


def _eqf(a_, b_, c_):
    """ax + by = c"""
    return poly([(a_, "x"), (b_, "y")]) + " = " + t(c_)


def _ps(m, p):
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


def _gen_circle(h, k, r2):
    return poly([(1, "x^{2}"), (1, "y^{2}"), (-2 * h, "x"), (-2 * k, "y"), (h * h + k * k - r2, "")]) + " = 0"


# ---------- lb_touch：切於一點的圓（難度 2） ----------

def lb_touch(L, T, Q, offs):
    a_, b_, c_ = L
    assert a_ * T[0] + b_ * T[1] + c_ == 0 and a_ * Q[0] + b_ * Q[1] + c_ != 0
    n2 = a_ * a_ + b_ * b_
    dx, dy = T[0] - Q[0], T[1] - Q[1]
    tt = F(-(dx * dx + dy * dy), 2 * (a_ * dx + b_ * dy))
    C = (T[0] + tt * a_, T[1] + tt * b_)
    r2 = tt * tt * n2
    assert isint(C[0]) and isint(C[1]) and isint(r2)
    # 過 T 垂直 L：b x − a y = b T0 − a T1（約分、首項正）
    pa, pb, pc = lin_norm(b_, -a_, -(b_ * T[0] - a_ * T[1]))
    perp = _eqf(pa, pb, -pc)
    assert pa * C[0] + pb * C[1] + pc == 0
    opts_p = [perp, _eqf(pa, pb, 0) if pc != 0 else _eqf(pa, pb, 1), _eqf(a_, b_, -c_), _eqf(pa, -pb, -pc) if pb != 0 else _eqf(pa, 1, -pc)]
    if T[1] == Q[1]:
        mid = F(T[0] + Q[0], 2)
        bis = "x = %s" % t(mid)
        bopts = [bis, "y = %s" % t(mid), "x = %s" % t(mid + 1), "x = %s" % t(T[0])]
        sub = "x = %s 代進 %s" % (t(mid), perp)
    else:
        mid = F(T[1] + Q[1], 2)
        bis = "y = %s" % t(mid)
        bopts = [bis, "x = %s" % t(mid), "y = %s" % t(mid + 1), "y = %s" % t(T[1])]
        sub = "y = %s 代進 %s" % (t(mid), perp)
    finals = [circ_eq(C[0], C[1], r2), circ_eq(C[0], C[1], rt(r2).val() if False else r2 * 2), circ_eq(-C[0], -C[1], r2), circ_eq(T[0], T[1], r2)]
    r = math.sqrt(r2)
    xr, yr = box([T, Q], pad=1.0, circles=[(C, r)])
    o = lambda k: offs.get(k, (8, -8))
    return {"id": "lb_touch", "kind": "boss", "tier": 2, "title": "切於一點的圓", "tmul": 1.6,
            "stem": "圓 C 和直線 L：%s 切於 T%s，而且通過 Q%s。(1) 圓心在哪條直線上 (2) 圓心與半徑 (3) C 的方程式" % (lin(*L), P(*T), P(*Q)),
            "plot": geo(xr, yr, [ln(a_, b_, c_, xr, yr, "cyan"), pt(T, "T", "gold", 0, o("T")), pt(Q, "Q", "pink", 0, o("Q")),
                                 ln(pa, pb, pc, xr, yr, "dim", dash=True, at=2), seg(T, Q, "pink", dash=True, at=3),
                                 circ(C, r, "lime", at=5), pt(C, "K", "lime", 5, o("K"))]),
            "steps": [
                choice("圓和 L 切於 T，圓心一定在？", ["過 T 且和 L 垂直的直線上", "過 T 且和 L 平行的直線上", "L 上", "過 Q 且和 L 垂直的直線上"],
                       "切線和半徑垂直：半徑 \\ol{KT} ⊥ L", "(1)　\\ol{KT} ⊥ L", part="(1)"),
                choice("L 的法向量是 %s。過 T%s 且和 L 垂直的直線：" % (P(a_, b_), P(*T)), opts_p,
                       "方向就是 L 的法向量 %s，代 T 進去求常數" % P(a_, b_), "圓心在 %s 上" % perp),
                choice("圓心到 T、Q 一樣遠，也在 \\ol{TQ} 的中垂線上：", bopts, "T、Q 的 %s 坐標一樣，中垂線看中點" % ("y" if T[1] == Q[1] else "x"),
                       "\\ol{TQ} 的中垂線 %s" % bis, part="(2)"),
                fill("聯立：", "(2)　圓心 K([0], [1])，r^{2} = [2]", [a(C[0]), a(C[1]), a(r2)],
                     "%s。r^{2} = \\ol{KT}^{2} = %s^{2} + %s^{2}" % (sub, tp(T[0] - C[0]), tp(T[1] - C[1]))),
                choice("驗算 Q 也在圓上，寫出 C：", finals, "%s^{2} + %s^{2} = %s ✓" % (tp(Q[0] - C[0]), tp(Q[1] - C[1]), t(r2)),
                       "答：(3)　" + finals[0], part="(3)")]}


# ---------- lb_square：穿過方形水池的直線（難度 2） ----------

def lb_square(V0, s, Pp, offs):
    x0, y0 = V0
    V = [(x0, y0), (x0 + s, y0), (x0 + s, y0 + s), (x0, y0 + s)]
    names = ["A", "B", "C", "D"]
    assert not (x0 <= Pp[0] <= x0 + s) and Pp[1] not in (y0, y0 + s)
    sl = [F(v[1] - Pp[1], v[0] - Pp[0]) for v in V]
    assert len(set(sl)) == 4
    lo, hi = min(sl), max(sl)
    ctr = (x0 + F(s, 2), y0 + F(s, 2))
    mc = F(ctr[1] - Pp[1]) / (ctr[0] - Pp[0])
    lineS = ("y = mx %s %s" % ("+" if Pp[1] > 0 else M, t(abs(Pp[1])))) if Pp[0] == 0 else "y = m(%s) %s %s" % ("x" if Pp[0] == 0 else "x %s %s" % ("+" if Pp[0] < 0 else M, t(abs(Pp[0]))), "+" if Pp[1] > 0 else M, t(abs(Pp[1])))
    if Pp[1] == 0:
        lineS = "y = m(%s)" % ("x" if Pp[0] == 0 else "x %s %s" % ("+" if Pp[0] < 0 else M, t(abs(Pp[0]))))
    xr, yr = box(V + [Pp], pad=1.0)
    il, ih = sl.index(lo), sl.index(hi)
    o = lambda k: offs.get(k, (8, -8))

    def ray(p, q):
        dx, dy = q[0] - p[0], q[1] - p[1]
        best = None
        for tt in [(xr[0] - p[0]) / dx if dx else None, (xr[1] - p[0]) / dx if dx else None,
                   (yr[0] - p[1]) / dy if dy else None, (yr[1] - p[1]) / dy if dy else None]:
            if tt is not None and tt > 1e-9:
                x, y = p[0] + tt * dx, p[1] + tt * dy
                if xr[0] - 1e-6 <= x <= xr[1] + 1e-6 and yr[0] - 1e-6 <= y <= yr[1] + 1e-6:
                    best = tt if best is None else min(best, tt)
        return (p[0] + best * dx, p[1] + best * dy)
    hs = lambda v: "(%s − %s)/(%s − %s)" % (t(v[1]), tp(Pp[1]), t(v[0]), tp(Pp[0]))
    return {"id": "lb_square", "kind": "boss", "tier": 2, "title": "穿過方形水池的直線", "tmul": 1.6,
            "stem": "方形水池的四個頂點是 A%s、B%s、C%s、D%s。直線 L：%s。(1) L 和水池的邊恰有兩個交點時，m 的範圍 (2) L 把水池面積平分時的 m" % (P(*V[0]), P(*V[1]), P(*V[2]), P(*V[3]), lineS),
            "plot": geo(xr, yr, [poly_sh(V, "cyan", fill="cyan", alpha=0.18)] + [pt(v, n, "gold", 0, o(n)) for v, n in zip(V, names)] +
                    [pt(Pp, "P", "pink", 1, o("P")), seg(Pp, ray(Pp, V[il]), "pink", at=4), seg(Pp, ray(Pp, V[ih]), "pink", at=4),
                     pt(ctr, "", "lime", 6), ln(mc, -1, Pp[1] - mc * Pp[0], xr, yr, "lime", dash=True, at=6)]),
            "steps": [
                choice("不管 m 是多少，L 都通過？", _uniq([P(*Pp)], [P(-Pp[0], Pp[1]), P(Pp[0], -Pp[1]), P(Pp[1], Pp[0]), P(-Pp[0], -Pp[1]), P(0, Pp[1] + 1)]),
                       "讓 m 的係數是 0", "L 繞著 P%s 轉" % P(*Pp), part="(1)"),
                fill("P 到四個頂點的斜率：", "m_{PA} = [0]，m_{PB} = [1]，m_{PC} = [2]，m_{PD} = [3]", [a(v) for v in sl], "、".join(hs(v) for v in V)),
                choice("L 剛好通過 %s（斜率最小）的時候，和水池的邊有幾個交點？" % names[il], ["1 個", "2 個", "0 個", "無限多個"],
                       "從 P 看過去，%s 是最邊緣的頂點，L 只擦過那一點" % names[il], "斜率最大、最小時只碰到一個頂點：不算"),
                fill("在兩個極端中間才是恰有兩個交點：", "(1)　[0] < m < [1]", [a(lo), a(hi)], " < ".join(t(v) for v in sorted(sl))),
                choice("哪一種直線一定把正方形的面積平分？", ["通過正方形中心的直線", "通過一個頂點的直線", "和一邊平行的直線", "通過一邊中點的直線"],
                       "正方形對中心點對稱：過中心的直線把它切成一模一樣的兩塊", "(2)　L 要通過中心 %s" % P(*ctr), part="(2)"),
                fill("L 通過中心 %s：" % P(*ctr), "(2)　m = [0]", [a(mc)], hs(ctr))]}


# ---------- lb_pencil：交點圓系（難度 2） ----------

def lb_pencil(R2, L, Mline, X, Y):
    a_, b_, c_ = L
    for p_ in (X, Y):
        assert p_[0] ** 2 + p_[1] ** 2 == R2 and a_ * p_[0] + b_ * p_[1] + c_ == 0
    if X[0] > Y[0]:
        X, Y = Y, X
    p, q, s = Mline
    k = F(-2 * s, p * a_ + q * b_)
    ctr = (-k * a_ / 2, -k * b_ / 2)
    assert p * ctr[0] + q * ctr[1] == s
    D, E, Fc = k * a_, k * b_, -R2 + k * c_
    r2 = ctr[0] ** 2 + ctr[1] ** 2 - Fc
    for p_ in (X, Y):
        assert p_[0] ** 2 + p_[1] ** 2 + D * p_[0] + E * p_[1] + Fc == 0
    fam = "x^{2} + y^{2} − %d + k(%s) = 0" % (R2, poly([(a_, "x"), (b_, "y"), (c_, "")]))
    eq2 = poly([(1, "x^{2}"), (1, "y^{2}"), (D, "x"), (E, "y"), (Fc, "")]) + " = 0"
    wrong = [poly([(1, "x^{2}"), (1, "y^{2}"), (-D, "x"), (-E, "y"), (Fc, "")]) + " = 0",
             poly([(1, "x^{2}"), (1, "y^{2}"), (D, "x"), (E, "y"), (-R2, "")]) + " = 0",
             poly([(1, "x^{2}"), (1, "y^{2}"), (2 * D, "x"), (2 * E, "y"), (-R2 + 2 * k * c_, "")]) + " = 0"]
    mid = (F(X[0] + Y[0], 2), F(X[1] + Y[1], 2))
    sr2 = (mid[0] - X[0]) ** 2 + (mid[1] - X[1]) ** 2
    Ms = _eqf(p, q, s)
    xr, yr = box([], pad=1.2, circles=[((0, 0), math.sqrt(R2)), (ctr, math.sqrt(r2))])
    cxk = lambda c: ("−" if c > 0 else "") + ("" if abs(F(c, 2)) == 1 else tf(abs(F(c, 2)))) + "k"
    return {"id": "lb_pencil", "kind": "boss", "tier": 2, "title": "交點圓系", "tmul": 1.6,
            "stem": "圓 C：x^{2} + y^{2} = %d，直線 L：%s。(1) C 和 L 的交點 (2) 過這兩個交點、圓心在直線 %s 上的圓 (3) 過這兩個交點最小的圓" % (R2, lin(*L), Ms),
            "plot": geo(xr, yr, [circ((0, 0), math.sqrt(R2), "cyan"), ln(a_, b_, c_, xr, yr, "pink"), ln(p, q, -s, xr, yr, "dim", dash=True),
                                 pt(X, "", "lime", 1), pt(Y, "", "lime", 1), circ(ctr, math.sqrt(r2), "gold", at=5), pt(ctr, "", "gold", 5),
                                 circ(mid, math.sqrt(sr2), "lime", at=7)]),
            "steps": [
                fill("L 代進 C 解聯立：", "(1)　交點 ([0], [1])、([2], [3])（x 小的先寫）", [a(X[0]), a(X[1]), a(Y[0]), a(Y[1])],
                     "從 L 解出一個變數，代進 x^{2} + y^{2} = %d" % R2, part="(1)"),
                choice("記 C = x^{2} + y^{2} − %d、L = %s。過兩個交點的圓都可以寫成：" % (R2, poly([(a_, "x"), (b_, "y"), (c_, "")])),
                       ["C + kL = 0", "C · L = 0", "C + L = k", "kC = L + 1"],
                       "C + kL = 0：交點同時讓 C、L 都是 0", "(2)　" + fam, part="(2)"),
                choice("展開後 x、y 的係數是 %s、%s，所以圓心是：" % (cx(a_, "k"), cx(b_, "k")),
                       _uniq(["(%s, %s)" % (cx(F(-a_, 2), "k"), cx(F(-b_, 2), "k"))],
                             ["(%s, %s)" % (cx(F(a_, 2), "k"), cx(F(b_, 2), "k")), "(%s, %s)" % (cx(-a_, "k"), cx(-b_, "k")),
                              "(%s, %s)" % (cx(F(-b_, 2), "k"), cx(F(-a_, 2), "k")), "(%s, %s)" % (cx(F(-a_, 2), "k"), cx(F(b_, 2), "k"))]),
                       "x^{2} + y^{2} + Dx + Ey + F = 0 的圓心是 (−D/2, −E/2)", "圓心 (%s, %s)" % (cx(F(-a_, 2), "k"), cx(F(-b_, 2), "k"))),
                fill("圓心代進 %s：" % Ms, "k = [0]", [a(k)], "%s × (%sk) + %s × (%sk) = %s" % (t(p), t(F(-a_, 2)), tp(q), t(F(-b_, 2)), t(s))),
                choice("k 代回去：", [eq2] + wrong, "x^{2} + y^{2} − %d + (%s)(%s) = 0" % (R2, t(k), poly([(a_, "x"), (b_, "y"), (c_, "")])), "(2)　" + eq2),
                choice("過兩個交點的圓，哪一個最小？", ["以兩交點連線為直徑的圓", "圓心在原點的圓", "圓心在 %s 上的那個" % Ms, "和 L 相切的圓"],
                       "弦是圓裡面最長的就是直徑：兩交點的距離當直徑，圓最小", "(3)　最小的圓：兩交點連線是直徑", part="(3)"),
                fill("圓心是兩交點的中點：", "(3)　圓心 ([0], [1])，r^{2} = [2]", [a(mid[0]), a(mid[1]), a(sr2)],
                     "r 是兩交點距離的一半")]}


# ---------- lb_kite：兩條切線圍成的風箏（難度 3） ----------

def lb_kite(K, r2, Pp):
    h, k = K
    u, v = Pp[0] - h, Pp[1] - k
    pk2 = u * u + v * v
    t2 = pk2 - r2
    assert t2 > 0
    tl = rt(t2)
    # 切線：y − p2 = m(x − p1)，d(K) = r：(m(h − p1) − (k − p2))^2 = r2(m^2 + 1)
    qa, qb, qc = u * u - r2, -2 * u * v, v * v - r2
    g = math.gcd(math.gcd(qa, qb), qc)
    qa, qb, qc = qa // g, qb // g, qc // g
    if qa < 0:
        qa, qb, qc = -qa, -qb, -qc
    Dd = qb * qb - 4 * qa * qc
    sd = math.isqrt(Dd)
    assert sd * sd == Dd and qa != 0
    ms = sorted([F(-qb + sd, 2 * qa), F(-qb - sd, 2 * qa)])
    # 切點弦：C − (以 PK 為直徑的圓)
    Cg = (-2 * h, -2 * k, h * h + k * k - r2)
    Dg = (-(Pp[0] + h), -(Pp[1] + k), Pp[0] * h + Pp[1] * k)
    ch = lin_norm(Cg[0] - Dg[0], Cg[1] - Dg[1], Cg[2] - Dg[2])
    # 切點
    pts = []
    for m in ms:
        c_ = Pp[1] - m * Pp[0]
        vv = m * h - k + c_
        n2 = m * m + 1
        pts.append((h - m * vv / n2, k + vv / n2))
    for T in pts:
        assert ch[0] * T[0] + ch[1] * T[1] + ch[2] == 0
    area = rt(r2 * t2)
    Ceq = "x^{2} + y^{2} = %d" % r2 if K == (0, 0) else _gen_circle(h, k, r2)
    Deq = poly([(1, "x^{2}"), (1, "y^{2}"), (Dg[0], "x"), (Dg[1], "y"), (Dg[2], "")]) + " = 0"
    ys = "y" if Pp[1] == 0 else "y %s %d" % ("+" if Pp[1] < 0 else M, abs(Pp[1]))
    xs = "x" if Pp[0] == 0 else "x %s %d" % ("+" if Pp[0] < 0 else M, abs(Pp[0]))
    num = poly([(-u, "m"), (v, "")])
    if -u < 0:
        num = poly([(u, "m"), (-v, "")])
    xr, yr = box([Pp] + pts, pad=1.0, circles=[(K, math.sqrt(r2))])
    TL = [lin_norm(m, -1, Pp[1] - m * Pp[0]) for m in ms]
    return {"id": "lb_kite", "kind": "boss", "tier": 3, "title": "兩條切線圍成的風箏", "tmul": 1.7,
            "stem": "從 P%s 對圓 C：%s 作兩條切線，切點是 A、B。(1) 切線段長 (2) 兩條切線的斜率 (3) 直線 AB (4) 四邊形 PAKB 的面積（K 是圓心）" % (P(*Pp), Ceq),
            "plot": geo(xr, yr, [circ(K, math.sqrt(r2), "cyan"), pt(K, "K", "cyan"), pt(Pp, "P", "pink"),
                                 ln(*TL[0], xr, yr, "pink", at=3), ln(*TL[1], xr, yr, "pink", at=3),
                                 pt(pts[0], "", "gold", 3), pt(pts[1], "", "gold", 3),
                                 circ(((h + Pp[0]) / 2, (k + Pp[1]) / 2), math.sqrt(pk2) / 2, "dim", dash=True, at=5),
                                 ln(*ch, xr, yr, "lime", at=6), poly_sh([Pp, pts[0], K, pts[1]], "lime", fill="lime", alpha=0.15, at=7)]),
            "steps": [
                fill("切線段、半徑、\\ol{PK} 是直角三角形：", "(1)　\\ol{PK}^{2} = [0]，切線段長 = √{%d − %d} = [1]" % (pk2, r2), [pk2, tl.ans()],
                     "%s^{2} + %s^{2}" % (tp(u), tp(v)), part="(1)"),
                fill("設 %s = m(%s)，和圓相切：\\frac{|%s|}{√{m^{2} + 1}} = %s，平方整理成 %s（由小到大填）：" % (ys, xs, num, rtt(r2), poly([(qa, "m^{2}"), (qb, "m"), (qc, "")]) + " = 0"),
                     "(2)　m = [0] 或 [1]", [a(ms[0]), a(ms[1])], "因式分解：%s = 0" % _fac(ms, qa), part="(2)"),
                choice("切點 A 在以 \\ol{PK} 為直徑的圓上，因為？", ["∠PAK = 90°", "\\ol{PA} = \\ol{AK}", "\\ol{PA} = \\ol{PK}", "A 是 \\ol{PK} 的中點"],
                       "切線 ⊥ 半徑；直角的頂點在以斜邊為直徑的圓上", "(3)　A、B 在以 \\ol{PK} 為直徑的圓上", part="(3)"),
                choice("以 \\ol{PK} 為直徑的圓：%s%s + %s%s = 0，展開：" % (_fx("x", Pp[0]), _fx("x", h), _fx("y", Pp[1]), _fx("y", k)),
                       [Deq, poly([(1, "x^{2}"), (1, "y^{2}"), (-Dg[0], "x"), (-Dg[1], "y"), (Dg[2], "")]) + " = 0",
                        poly([(1, "x^{2}"), (1, "y^{2}"), (Dg[0], "x"), (Dg[1], "y"), (-Dg[2] if Dg[2] != 0 else 1, "")]) + " = 0",
                        poly([(1, "x^{2}"), (1, "y^{2}"), (Dg[0], "x"), (Dg[1], "y"), (pk2, "")]) + " = 0"],
                       "(x − a)(x − b) = x^{2} − (a + b)x + ab", "以 \\ol{PK} 為直徑的圓 " + Deq),
                choice("A、B 是兩個圓的交點，兩式相減得到直線 AB：", [lin(*ch), lin(ch[0], -ch[1], ch[2]), lin(ch[0], ch[1], -ch[2]), lin(ch[1], ch[0], ch[2])],
                       "兩個圓的式子相減，x^{2}、y^{2} 消掉就是公共弦", "(3)　AB：" + lin(*ch)),
                fill("四邊形 PAKB 是兩個全等的直角三角形：", "(4)　面積 = 2 × \\frac{1}{2} × %s × %s = [0]" % (rtt(r2), tl.text()), [area.ans()],
                     "半徑 × 切線段長", part="(4)")]}


# ---------- lb_diff：距離差最大（難度 3） ----------

def lb_diff(A, B):
    assert A[1] > 0 and B[1] > 0 and A[1] != B[1]
    def rterm(p):
        return "√{%s^{2} + %d}" % (sh("x", p[0]), p[1] * p[1])
    fA, fB = rterm(A), rterm(B)
    A1 = (A[0], -A[1])
    s2 = (A1[0] - B[0]) ** 2 + (A1[1] - B[1]) ** 2
    m1 = F(B[1] - A1[1], B[0] - A1[0])
    xs = A1[0] - F(A1[1]) / m1
    ab2 = (A[0] - B[0]) ** 2 + (A[1] - B[1]) ** 2
    ab = rt(ab2)
    m2 = F(B[1] - A[1], B[0] - A[0])
    xi = A[0] - F(A[1]) / m2
    xr, yr = box([A, B, A1, (xi, 0), (xs, 0)], pad=1.0)
    dis = _uniq(["(x, 0) 到 %s" % P(*A)], ["(x, 0) 到 %s" % P(A[0], A[1] * A[1]), "(x, 0) 到 %s" % P(-A[0], A[1]), "(x, 0) 到 %s" % P(A[1], A[0]),
                                       "(x, 0) 到 %s" % P(A[0], 2 * A[1]), "(x, 0) 到 %s" % P(A[0] + 1, A[1])])
    return {"id": "lb_diff", "kind": "boss", "tier": 3, "title": "距離和與距離差", "tmul": 1.6,
            "stem": "f(x) = %s + %s，g(x) = |%s − %s|。(1) f(x) 的最小值 (2) g(x) 的最大值，以及這時的 x" % (fA, fB, fA, fB),
            "plot": geo(xr, yr, [pt(A, "A", "gold", 1), pt(B, "B", "gold", 1), pt(A1, "A'", "pink", 2, (-26, 10)),
                                 seg(A1, B, "pink", dash=True, at=3), pt((xs, 0), "", "pink", 3),
                                 ln(B[1] - A[1], -(B[0] - A[0]), (B[0] - A[0]) * A[1] - (B[1] - A[1]) * A[0], xr, yr, "lime", dash=True, at=5),
                                 pt((xi, 0), "", "lime", 6)]),
            "steps": [
                choice("%s 是哪兩點的距離？" % fA, dis,
                       "√{(x − a)^{2} + (0 − b)^{2}}：b^{2} = %d，b = %d" % (A[1] * A[1], A[1]), "設 P(x, 0)、A%s、B%s：f = \\ol{PA} + \\ol{PB}" % (P(*A), P(*B)), part="(1)"),
                choice("A、B 在 x 軸的同一側，\\ol{PA} + \\ol{PB} 要最小，先？", ["把 A 對 x 軸對稱到 A'", "取 \\ol{AB} 的中點", "把 A、B 都對 x 軸對稱", "直接連 \\ol{AB}"],
                       "對稱後 \\ol{PA} = \\ol{PA'}，A'、B 在兩側，連起來最短", "A'%s，f = \\ol{PA'} + \\ol{PB} ≥ \\ol{A'B}" % P(*A1)),
                fill("最小值是 \\ol{A'B}：", "(1)　f 最小 = √{%d + %d} = [0]，這時 x = [1]" % ((A1[0] - B[0]) ** 2, (A1[1] - B[1]) ** 2), [rta(s2), a(xs)],
                     "直線 A'B 的斜率 %s，令 y = 0" % t(m1)),
                choice("g = |\\ol{PA} − \\ol{PB}|。三角形兩邊的差 < 第三邊，所以 g 最大是？", ["\\ol{AB}", "\\ol{A'B}", "\\ol{PA} + \\ol{PB}", "沒有最大值"],
                       "|\\ol{PA} − \\ol{PB}| ≤ \\ol{AB}，P、A、B 共線時等號成立", "g = |\\ol{PA} − \\ol{PB}| ≤ \\ol{AB}", part="(2)"),
                fill("P 在直線 AB 和 x 軸的交點時最大：", "(2)　g 最大 = [0]，這時 x = [1]", [ab.ans(), a(xi)],
                     "\\ol{AB} = √{%d + %d}。直線 AB 的斜率 %s，令 y = 0" % ((A[0] - B[0]) ** 2, (A[1] - B[1]) ** 2, t(m2)))]}


# ---------- lb_count3：剛好三個點（難度 3） ----------

def lb_count3(R, k, a_, b_):
    n = rt(a_ * a_ + b_ * b_)
    assert 0 < k < R
    c3 = Surd(n.c * (R - k), n.n)
    c1 = Surd(n.c * (R + k), n.n)
    nt = n.text()
    L = poly([(a_, "x"), (b_, "y")]) + " = c"
    xr = [-R - k - 1.0, R + k + 1.0]
    yr = [-R - k - 1.0, R + k + 1.0]
    dsh = n.val()
    return {"id": "lb_count3", "kind": "boss", "tier": 3, "title": "剛好三個點", "tmul": 1.6,
            "stem": "圓 x^{2} + y^{2} = %d 上，到直線 L：%s 的距離是 %d 的點。(1) 恰有 3 個時 c 的值 (2) 有 4 個時 c 的範圍 (3) 恰有 1 個時 c 的值" % (R * R, L, k),
            "plot": geo(xr, yr, [circ((0, 0), R, "cyan"), pt((0, 0), "O", "cyan", 0, (-20, 16)),
                                 ln(a_, b_, -c3.val(), xr, yr, "pink", at=3), ln(a_, b_, -(c3.val() - k * dsh), xr, yr, "gold", dash=True, at=3),
                                 ln(a_, b_, -(c3.val() + k * dsh), xr, yr, "gold", dash=True, at=3)]),
            "steps": [
                fill("圓心到 L：", "d(O, L) = \\frac{|c|}{[0]}", [n.ans()], "√{%d + %d}" % (a_ * a_, b_ * b_)),
                choice("到 L 的距離是 %d 的點，都在哪裡？" % k, ["平行 L、距離 %d 的兩條線上" % k, "以 O 為圓心、半徑 %d 的圓上" % k, "和 L 垂直的直線上", "L 上"],
                       "到一條直線距離固定的點，是兩條平行線", "這些點 = 圓和兩條平行線的交點"),
                choice("恰有 3 個點：一條平行線和圓相切（1 點），另一條交兩點。這時", ["d(O, L) = %d − %d" % (R, k), "d(O, L) = %d + %d" % (R, k), "d(O, L) = %d" % k, "d(O, L) = %d" % R],
                       "離圓心比較遠的那條平行線要剛好相切：d(O, L) + %d = %d" % (k, R), "3 個點 ⇔ d(O, L) = %d" % (R - k), part="(1)"),
                fill("|c| = %d × %s：" % (R - k, nt), "(1)　c = ±[0]", [c3.ans()], "\\frac{|c|}{%s} = %d" % (nt, R - k)),
                fill("兩條平行線都交圓兩點：d(O, L) < %d：" % (R - k), "(2)　[0] < c < [1]", [Surd(-c3.c, c3.n).ans(), c3.ans()],
                     "|c| < %s" % c3.text(), part="(2)"),
                choice("恰有 1 個點：兩條平行線，一條相切、另一條碰不到。這時", ["d(O, L) = %d + %d" % (R, k), "d(O, L) = %d − %d" % (R, k), "d(O, L) = %d" % R, "d(O, L) = 0"],
                       "離圓心近的那條平行線剛好相切：d(O, L) − %d = %d" % (k, R), "1 個點 ⇔ d(O, L) = %d" % (R + k), part="(3)"),
                fill("|c| = %d × %s：" % (R + k, nt), "(3)　c = ±[0]", [c1.ans()], "\\frac{|c|}{%s} = %d" % (nt, R + k))]}


def _fx(v, a_):
    """(x − a)；a = 0 時只寫 x"""
    return v if a_ == 0 else "(%s %s %s)" % (v, M if a_ > 0 else "+", t(abs(a_)))


def _uniq(first, rest):
    """正確選項 + 三個不重複的錯誤選項"""
    out = list(first)
    for x in rest:
        if x not in out:
            out.append(x)
        if len(out) == 4:
            break
    assert len(out) == 4
    return out


def items():
    return [
        [lb_touch((1, -2, 3), (-3, 0), (1, 0), {"T": (-20, -8), "Q": (6, -8)}), lb_touch((3, -4, 9), (-3, 0), (3, 0), {"T": (-20, -8)}),
         lb_touch((1, 3, 9), (-3, -2), (-3, 4), {"T": (-22, 14), "Q": (-22, -6)})],
        [lb_square((1, 1), 2, (-2, 0), {"A": (-4, 18), "B": (6, 16), "D": (-22, -6)}), lb_square((1, 1), 2, (0, -2), {"A": (-22, 10), "B": (6, 16)}),
         lb_square((1, 1), 2, (4, -2), {"A": (-22, 10), "B": (6, 16)})],
        [lb_pencil(25, (2, 1, -10), (1, -1, 1), (3, 4), (5, 0)), lb_pencil(10, (1, 1, -4), (1, 2, 3), (1, 3), (3, 1)),
         lb_pencil(25, (1, -1, 1), (1, 2, 2), (3, 4), (-4, -3))],
        [lb_kite((0, 0), 25, (7, 1)), lb_kite((0, 0), 10, (4, 2)), lb_kite((1, -1), 5, (4, 0))],
        [lb_diff((1, 1), (4, 5)), lb_diff((0, 1), (8, 7)), lb_diff((0, 3), (8, 9))],
        [lb_count3(5, 2, 3, 4), lb_count3(4, 1, 4, -3), lb_count3(3, 1, 1, 1)],
    ]
