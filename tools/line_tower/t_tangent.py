# 切線圓系
from lib import *


def _line_pm(m, p):
    """過 p、斜率 m 的直線，一般式（約分）"""
    m = F(m)
    return lin_norm(m, -1, p[1] - m * p[0])


def _pt_slope(m, p):
    """y − 2 = (1/3)(x − 1)"""
    ys = "y" if p[1] == 0 else "y %s %s" % ("+" if p[1] < 0 else M, t(abs(p[1])))
    xs = "x" if p[0] == 0 else "x %s %s" % ("+" if p[0] < 0 else M, t(abs(p[0])))
    m = F(m)
    if abs(m) == 1:
        co = "" if m > 0 else M
    elif isint(m):
        co = t(m)
    else:
        co = (M if m < 0 else "") + "(" + t(abs(m)) + ")"
    return "%s = %s(%s)" % (ys, co, xs)


# ---------- lt_param：先求參數的切線 ----------

def lt_param(K, Pp):
    h, k = K
    r2 = (Pp[0] - h) ** 2 + (Pp[1] - k) ** 2
    D, E, Fc = -2 * h, -2 * k, h * h + k * k - r2
    assert Pp[1] != 0
    stem_eq = poly([(1, "x^{2}"), (1, "y^{2}"), (D, "x"), (1, "ky"), (Fc, "")]) + " = 0"
    # 代 P
    sub_terms = [t(Pp[0] ** 2), t(Pp[1] ** 2)]
    sub = poly([(Pp[0] ** 2, ""), (Pp[1] ** 2, ""), (D * Pp[0], ""), (Pp[1], "k"), (Fc, "")])
    rest = Pp[0] ** 2 + Pp[1] ** 2 + D * Pp[0] + Fc
    kk = F(-rest) / Pp[1]
    assert kk == E
    mkp = F(Pp[1] - k) / (Pp[0] - h)
    mt = -1 / mkp
    T = _line_pm(mt, Pp)
    R = _line_pm(mkp, Pp)
    opts = [lin(*T), lin(*R), lin(T[0], T[1], -T[2]), lin(*_line_pm(-mt, Pp))]
    xr, yr = box([Pp], pad=1.4, circles=[(K, math.sqrt(r2))])
    full = poly([(1, "x^{2}"), (1, "y^{2}"), (D, "x"), (E, "y"), (Fc, "")]) + " = 0"
    return {"id": "lt_param", "kind": "tangent", "tier": 1, "title": "先求參數的切線", "tmul": 1.1,
            "stem": "點 P%s 在圓 C：%s 上。求 k，以及 C 在 P 的切線。" % (P(*Pp), stem_eq),
            "plot": geo(xr, yr, [circ(K, math.sqrt(r2), "cyan", at=2), pt(K, "K", "cyan", 2), pt(Pp, "P", "pink"),
                                 seg(K, Pp, "dim", dash=True, at=2), ln(*T, xr, yr, "pink", at=5)]),
            "steps": [
                fill("P 在圓上，代進去：", "%s = 0 ⇒ k = [0]" % sub, [a(kk)], "%s = 0" % poly([(Pp[1], "k"), (rest, "")])),
                fill("配方：%s" % full, "圓心 K([0], [1])，r^{2} = [2]", [a(h), a(k), a(r2)],
                     "%s^{2} + %s^{2} = %s" % (sh("x", h), sh("y", k), " + ".join(t(v) for v in [-Fc, h * h, k * k] if v != 0))),
                fill("半徑 \\ol{KP} 的斜率：", "m_{KP} = [0]", [a(mkp)], "(%s − %s)/(%s − %s)" % (t(Pp[1]), tp(k), t(Pp[0]), tp(h))),
                fill("切線和半徑垂直：", "切線的斜率 = [0]", [a(mt)], "%s × m = −1" % tp(mkp)),
                choice("過 P%s、斜率 %s 的切線：" % (P(*Pp), t(mt)), opts, "%s，%s移項" % (_pt_slope(mt, Pp), "乘 %d " % F(mt).denominator if not isint(mt) else ""),
                       "答：k = %s，切線 %s" % (t(kk), opts[0]))]}


# ---------- lt_inner：內公切線 ----------

def lt_inner(r1, r2, D):
    assert D > r1 + r2
    p = F(D * r1, r1 + r2)
    m2 = F(r1 * r1) / (p * p - r1 * r1)
    m = rt(m2)
    pt_ = tf(p)
    if r1 == r2:
        right = "\\ol{OK} 的中點"
        opts = [right, "\\ol{OK} 延長線上", "\\ol{OK} 上，2 : 1", "O 和 K 中間，靠近 O"]
        hint = "相似三角形：比等於半徑比 1 : 1，P 是中點"
        wr = "P 是 \\ol{OK} 的中點"
    else:
        right = "\\ol{OK} 上，%d : %d" % (r1, r2)
        opts = [right, "\\ol{OK} 延長線上，%d : %d" % (r1, r2), "\\ol{OK} 的中點", "\\ol{OK} 上，%d : %d" % (r2, r1)]
        hint = "相似三角形：比等於半徑比 %d : %d，而且在兩圓中間（內分）" % (r1, r2)
        wr = "P 內分 \\ol{OK} 成 %d : %d" % (r1, r2)
    xr = [-r1 - 0.6, D + r2 + 0.4]
    yr = [-max(r1, r2) - 0.6, max(r1, r2) + 0.6]
    mv = m.val()
    pm = "%sm" % (t(p) if isint(p) else tf(p))
    qk = F(D) - p
    return {"id": "lt_inner", "kind": "tangent", "tier": 2, "title": "內公切線", "tmul": 1.25,
            "stem": "圓 C_{1}：x^{2} + y^{2} = %d、圓 C_{2}：(x − %d)^{2} + y^{2} = %d。求兩條內公切線的斜率。" % (r1 * r1, D, r2 * r2),
            "plot": geo(xr, yr, [circ((0, 0), r1, "cyan"), circ((D, 0), r2, "pink"), pt((0, 0), "O", "cyan", 0, (-20, 16)), pt((D, 0), "K", "pink", 0, (6, 18)),
                                 pt((p, 0), "P", "gold", 3, (4, 18)), ln(mv, -1, -mv * float(p), xr, yr, "lime", at=5), ln(-mv, -1, mv * float(p), xr, yr, "lime", at=5)]),
            "steps": [
                choice("兩圓的位置：圓心距 %d，半徑 %d 和 %d。" % (D, r1, r2), ["外離，有 4 條公切線", "外切，有 3 條公切線", "相交，有 2 條公切線", "內含，沒有公切線"],
                       "%d > %d + %d" % (D, r1, r2), "外離：外公切線 2 條、內公切線 2 條"),
                choice("內公切線從兩圓中間穿過去，兩條的交點 P 在哪裡？\\ol{OP} : \\ol{PK} = ？", opts, hint, wr),
                fill("算出 P：", "P([0], 0)", [a(p)], "(%d × %d + %d × 0)/%d" % (r1, D, r2, r1 + r2)),
                fill("設切線 y = m(x − %s)，即 mx − y − %s = 0。和 C_{1} 相切：d(O, L) = %d。" % (pt_, pm, r1),
                     "\\frac{|%s|}{√{m^{2} + 1}} = %d ⇒ m^{2} = [0]" % (pm, r1), [a(m2)],
                     "%sm^{2} = %dm^{2} + %d" % (t(p * p), r1 * r1, r1 * r1)),
                fill("開根號：", "答：m = ±[0]", [m.ans()], ("√{%s} 有理化" % t(m2)) if not is_square(m2) else "√{%s}" % t(m2)),
                fill("驗算：這兩條也要和 C_{2} 相切。", "d(K, L) = \\frac{|%dm − %s|}{√{m^{2} + 1}} = [0]" % (D, pm), [r2],
                     "\\frac{|%sm|}{√{m^{2} + 1}}，m^{2} = %s" % (tf(qk) if not isint(qk) else t(qk), t(m2)))]}


# ---------- lt_mirror：斜鏡子的反射 ----------

def _fac(roots, lead):
    """lead·(m − r1)(m − r2) 寫成整數係數的乘積"""
    parts = []
    c = F(lead)
    for r in roots:
        r = F(r)
        if r == 0:
            parts.append("m")
        else:
            q, p_ = r.denominator, r.numerator
            c /= q
            parts.append("(%sm %s %d)" % ("" if q == 1 else str(q), "+" if p_ < 0 else M, abs(p_)))
    return ("" if c == 1 else t(c)) + "".join(parts)


def lt_mirror(K, r, A, offs):
    h, k = K
    A1 = (A[1], A[0])
    a1, a2 = A1
    u, v = h - a1, a2 - k
    qa, qb, qc = u * u - r * r, 2 * u * v, v * v - r * r
    g = math.gcd(math.gcd(qa, qb), qc)
    qa, qb, qc = qa // g, qb // g, qc // g
    D = qb * qb - 4 * qa * qc
    sd = math.isqrt(D)
    assert sd * sd == D
    ms = sorted([F(-qb + sd, 2 * qa), F(-qb - sd, 2 * qa)])
    info = []
    for m in ms:
        Rx = (a2 - m * a1) / (1 - m)
        Rp = (Rx, Rx)
        c = a2 - m * a1
        vv = m * h - k + c
        n2 = m * m + 1
        T = (h - m * vv / n2, k + vv / n2)
        d = (Rp[0] - a1, Rp[1] - a2)
        assert (T[0] - Rp[0]) * d[0] + (T[1] - Rp[1]) * d[1] > 0
        assert Rp[0] < h - r
        info.append((m, Rp, T, lin_norm(m, -1, c)))
    # y = 0 那條（斜率 0）放前面
    info.sort(key=lambda x: (x[0] != 0, x[0]))
    E = [lin(*x[3]) if x[3] != (0, 1, 0) else "y = 0" for x in info]
    E = [("y = 0" if x[3][0] == 0 and x[3][2] == 0 else lin(*x[3])) for x in info]
    flip = lambda L: lin(L[0], -L[1], L[2])
    alt0 = "x = 0" if info[0][0] == 0 and info[0][3][2] == 0 else flip(info[0][3])
    finals = ["%s 或 %s" % (E[0], E[1]), "只有 %s" % E[1], "%s 或 %s" % (E[0], flip(info[1][3])), "%s 或 %s" % (alt0, E[1])]
    shapes = [ln(1, -1, 0, *_box_mirror(K, r, A, A1, info), "dim"), circ(K, r, "cyan"), pt(K, "K", "cyan"), pt(A, "A", "gold", 0, offs.get("A", (-22, 10))),
              pt(A1, "A'", "pink", 1, offs.get("A'", (-26, -8)))]
    xr, yr = _box_mirror(K, r, A, A1, info)
    cols = ["lime", "gold"]
    names = ["T", "T'"]
    for i, (m, Rp, T, L) in enumerate(info):
        shapes.append(seg(A1, Rp, "pink", dash=True, at=3))
    for i, (m, Rp, T, L) in enumerate(info):
        shapes.append(poly_sh([A, Rp, T], cols[i], open=True, w=3.0, at=4))
        shapes.append(pt(T, names[i], cols[i], 4, offs.get(names[i], (6, -8) if i == 0 else (-26, 12))))
    mstr = lambda m: t(m)
    lhs = "|%s|" % poly([(u, "m"), (v, "")])
    quad = poly([(qa, "m^{2}"), (qb, "m"), (qc, "")]) + " = 0"
    sub = "x" if a1 == 0 else "x %s %s" % ("+" if a1 < 0 else M, t(abs(a1)))
    ys = "y" if a2 == 0 else "y %s %s" % ("+" if a2 < 0 else M, t(abs(a2)))
    hitq = "，".join("m = %s 先打到鏡子 %s" % (mstr(m), P(*Rp)) for m, Rp, T, L in info)
    return {"id": "lt_mirror", "kind": "tangent", "tier": 3, "title": "斜鏡子的反射", "tmul": 1.35,
            "stem": "光從 A%s 射到鏡面 y = x，反射後剛好和圓 %s 相切。求反射光線所在的直線。" % (P(*A), circ_eq(h, k, r * r)),
            "plot": geo(xr, yr, shapes),
            "steps": [
                choice("A 對鏡面 y = x 的對稱點：", ["A'" + P(*A1), "A'" + P(-A[1], -A[0]), "A'" + P(A[0], -A[1]), "A'" + P(-A[1], A[1])],
                       "對 y = x 對稱：x、y 互換", "A'" + P(*A1)),
                choice("反射後的光線往回延長，會通過哪一點？", ["A'", "A", "圓心", "原點"],
                       "鏡子裡的 A 看起來在 A'", "反射光線 = 過 A' 的直線"),
                fill("設 %s = m(%s)，和圓相切：\\frac{%s}{√{m^{2} + 1}} = %d，平方整理成 %s（由小到大填）：" % (ys, sub, lhs, r, quad),
                     "m = [0] 或 [1]", [a(ms[0]), a(ms[1])], "因式分解：%s = 0" % _fac(ms, qa)),
                choice("照順序檢查 A → 鏡子 → 圓：%s。哪幾條反射光真的會擦過圓？" % hitq,
                       ["兩條都會", "只有 m = %s" % mstr(info[0][0]), "只有 m = %s" % mstr(info[1][0]), "兩條都不會"],
                       "兩個打到鏡子的點都在圓的左邊，反射後都往右走，切點就在前面",
                       "兩條都合：切點 %s、%s" % (P(*info[0][2]), P(*info[1][2]))),
                choice("反射光線所在的直線：", finals, "%s，乘開移項" % "、".join(_pt_slope(m, A1) if m != 0 else "y = 0" for m, _, _, _ in info),
                       "答：%s 或 %s" % (E[0], E[1]))]}


def _box_mirror(K, r, A, A1, info):
    pts = [A, A1] + [x[1] for x in info] + [x[2] for x in info]
    return box(pts, pad=0.9, circles=[(K, r)])


def items():
    return [
        [lt_param((2, -1), (1, 2)), lt_param((-1, 3), (1, 4)), lt_param((3, 1), (1, -2))],
        [lt_inner(2, 1, 6), lt_inner(4, 4, 10), lt_inner(6, 3, 15)],
        [lt_mirror((3, -2), 2, (0, -3), {}), lt_mirror((2, -5), 1, (0, -3), {"T": (8, 6), "T'": (8, -8)}),
         lt_mirror((3, -2), 2, (0, -1), {})],
    ]
