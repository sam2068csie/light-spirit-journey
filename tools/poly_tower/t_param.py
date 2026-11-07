# 參數討論
from plib import *


def sg(v):
    return ("+ " + t(v)) if v >= 0 else (M + " " + t(-v))


def _vert_ends(h, L, R):
    dl, dr = abs(L - h), abs(R - h)
    assert dl != dr
    far = L if dl > dr else R
    near = R if far == L else L
    return far, near


# ---------- pp_twoway：開口向上還是向下 ----------

def pp_twoway(h, L, R, M_, m_):
    far, near = _vert_ends(h, L, R)
    d2 = (far - h) ** 2
    aA = F(M_ - m_, d2)
    aB = -aA
    bA = m_ + aA * h * h
    bB = M_ + aB * h * h
    for v in (aA, bA, bB):
        assert isint(v)
    f = lambda a_, b_: Poly([b_, -2 * a_ * h, a_])
    for a_, b_ in ((aA, bA), (aB, bB)):
        vals = [f(a_, b_)(x) for x in (L, R, h)]
        assert max(vals) == M_ and min(vals) == m_
    lin2 = poly([(1, "ax^{2}"), (-2 * h, "ax"), (1, "b")])
    vtx = poly([(1, "b"), (-h * h, "a")])
    endv = poly([(far * far - 2 * h * far, "a"), (1, "b")])
    return item("pp_twoway", "param", 2, "開口向上還是向下", 1.35,
                "二次函數 f(x) = %s 在 %s ≤ x ≤ %s 的最大值為 %s、最小值為 %s。求數對 (a, b)。（有兩解）" % (lin2, t(L), t(R), t(M_), t(m_)),
                [ch("對稱軸是？", uniq(["x = %s" % t(h)], ["x = %s" % t(-h), "x = %s" % t(2 * h), "x = %s" % t(-2 * h), "x = %s" % t(h + 1)]),
                    "x = −(%s)/(2a)" % cx(-2 * h, "a"), "對稱軸 x = %s，在 %s ≤ x ≤ %s 裡面" % (t(h), t(L), t(R))),
                 ch("離對稱軸最遠的端點是？", ["x = %s" % t(far), "x = %s" % t(near), "兩端一樣遠"],
                    "%s 到 %s 的距離 %s，%s 到 %s 只有 %s" % (t(far), t(h), t(abs(far - h)), t(near), t(h), t(abs(near - h))),
                    "頂點 f(%s) = %s，最遠的端點 f(%s) = %s" % (t(h), vtx, t(far), endv)),
                 fl("開口向上：頂點最小 %s = %s、x = %s 最大 %s = %s。兩式相減：" % (vtx, t(m_), t(far), endv, t(M_)), "%sa = [0]" % t(d2), [a(M_ - m_)],
                    "%s − %s" % (t(M_), tp(m_)), col="A"),
                 fl("a = %s，代回 %s = %s：" % (t(aA), vtx, t(m_)), "(a, b) = ([0], [1])", [a(aA), a(bA)], "b = %s + %s" % (t(m_), tp(aA * h * h)), col="A"),
                 fl("開口向下：頂點最大 %s = %s、x = %s 最小 %s = %s。兩式相減：" % (vtx, t(M_), t(far), endv, t(m_)), "%sa = [0]" % t(d2), [a(m_ - M_)],
                    "%s − %s" % (t(m_), tp(M_)), col="B"),
                 fl("a = %s，代回 %s = %s：" % (t(aB), vtx, t(M_)), "(a, b) = ([0], [1])", [a(aB), a(bB)], "b = %s + %s" % (t(M_), tp(aB * h * h)), col="B"),
                 ch("兩條路線都合，答案是？", ["(%s, %s) 或 (%s, %s)" % (t(aA), t(bA), t(aB), t(bB)), "只有 (%s, %s)" % (t(aA), t(bA)), "只有 (%s, %s)" % (t(aB), t(bB)),
                                          "(%s, %s) 或 (%s, %s)" % (t(aA), t(bB), t(aB), t(bA))],
                    "兩組都滿足自己那一條路線的 a 的正負", "答：(a, b) = (%s, %s) 或 (%s, %s)" % (t(aA), t(bA), t(aB), t(bB)))],
                routes={"A": "a > 0（開口向上）", "B": "a < 0（開口向下）"})


# ---------- pp_pos：恆為正 ----------

def pp_pos(al, be):
    """x^2 + (αm)x + (m + β) > 0：判別式 α^2 m^2 − 4m − 4β < 0"""
    D = Poly([-4 * be, -4, al * al])
    rts = sorted(D.real_roots())
    r1, r2 = F(rts[0]).limit_denominator(100), F(rts[1]).limit_denominator(100)
    assert D(r1) == 0 and D(r2) == 0 and isint(r1) and isint(r2)
    g = al * al
    Dn = D * F(1, g)
    stem = "x^{2} %s + (m %s) > 0" % (("+ " if al > 0 else M + " ") + ("" if abs(al) == 1 else t(abs(al))) + "mx", sg(be))
    fac_ok = "%s%s < 0" % (fac(r2, "m"), fac(r1, "m"))
    wrong = ["%s%s < 0" % (fac(-r2, "m"), fac(-r1, "m")), "%s%s < 0" % (fac(r2, "m"), fac(-r1, "m")), "%s%s < 0" % (fac(r2 * 2, "m"), fac(r1 / 2 if isint(r1 / 2) else -r1 * 2, "m"))]
    return item("pp_pos", "param", 1, "恆為正", 1.0, "對所有實數 x，%s 都成立。求 m 的範圍。" % stem,
                [ch("首項係數 1 > 0，還需要？", ["判別式 < 0", "判別式 > 0", "判別式 ≥ 0", "常數項 > 0 就夠"],
                    "開口向上又和 x 軸沒有交點，才會恆正", "判別式 %s − 4(m %s) < 0" % ("m^{2}" if g == 1 else "%dm^{2}" % g, sg(be))),
                 ch("%s < 0 因式分解：" % Dn.text("m"), uniq([fac_ok], wrong), "兩數相乘 %s、相加 %s" % (t(r1 * r2), t(-(r1 + r2))), fac_ok),
                 step("line", q="封印 m 的範圍。", row="m", marks=[t(r1), t(r2)], seg=[0, 1, 0], pt=[0, 0], write="答：%s < m < %s" % (t(r1), t(r2)))])


# ---------- pp_below：恆在直線下方 ----------

def pp_below(p, u, v, w, z):
    """y = (k − p)x^2 + (k + u)x + v 恆在 y = wx + z 下方；u − w = −p"""
    assert u - w == -p
    C = v - z
    assert C < 0
    lo = p + 4 * C
    curve = "(k %s)x^{2} + (k %s)x %s" % (sg(-p), sg(u), sg(v) if v != 0 else "")
    curve = curve.rstrip()
    diff = "(k %s)x^{2} + (k %s)x %s" % (sg(-p), sg(-p), sg(C))
    kp = "(k %s)" % sg(-p)
    disc = "%s^{2} %s%s" % (kp, sg(-4 * C), kp)
    line = "y = %s" % poly([(w, "x"), (z, "")])
    return item("pp_below", "param", 2, "恆在直線下方", 1.35,
                "y = %s 的圖形恆在直線 %s 的下方。求 k 的範圍。" % (curve, line),
                [ch("圖形恆在直線下方，代表對所有 x：", uniq(["%s < 0" % diff],
                                                    ["(k %s)x^{2} + (k %s)x %s < 0" % (sg(-p), sg(u + w), sg(v + z)), "%s > 0" % diff, "%s < 0" % curve]),
                    "%s − (%s) < 0" % (curve, poly([(w, "x"), (z, "")])), "對所有 x：%s < 0" % diff),
                 ch("k = %s 時式子變成什麼？成立嗎？" % t(p), ["%s < 0，恆成立" % t(C), "0 < 0，不成立", "%s < 0，不恆成立" % poly([(2, "x"), (C, "")]), "%s < 0，不恆成立" % poly([(-1, "x"), (C, "")])],
                    "k %s = 0，兩項都消失" % sg(-p), "k = %s：%s < 0 恆成立 ✓" % (t(p), t(C)), col="A"),
                 ch("判別式 = ？", uniq([disc], ["%s^{2} %s%s" % (kp, sg(4 * C), kp), "(k %s)^{2} %s%s" % (sg(u), sg(-4 * C), kp), "%s^{2} %s%s" % (kp, ("+ " if -C > 0 else M + " ") + ("" if abs(C) == 1 else t(abs(C))), kp)]),
                    "%s^{2} − 4%s(%s)" % (kp, kp, t(C)), "判別式 = %s = %s(k %s) < 0" % (disc, kp, sg(-lo)), col="B",
                    pre="k ≠ %s：二次式恆負 ⇔ 開口向下 k %s < 0、判別式 < 0" % (t(p), sg(-p))),
                 fl("%s(k %s) < 0 在兩根之間，再配合 k %s < 0：" % (kp, sg(-lo), sg(-p)), "[0] < k < [1]", [a(lo), a(p)], "兩根 %s、%s" % (t(lo), t(p)), col="B"),
                 ch("兩條路線合起來：", ["%s < k ≤ %s" % (t(lo), t(p)), "%s < k < %s" % (t(lo), t(p)), "k ≤ %s" % t(p), "%s < k ≤ %s" % (t(lo - 1), t(p))],
                    "路線 B 的 %s < k < %s，再加上路線 A 的 k = %s" % (t(lo), t(p), t(p)), "答：%s < k ≤ %s" % (t(lo), t(p)))],
                routes={"A": "k = %s（不是二次式）" % t(p), "B": "k ≠ %s" % t(p)})


# ---------- pp_frac：分式恆成立 ----------

def pp_frac(be, ga):
    """(kx^2 + βx + k)/(x^2 + γx + 1) > 1"""
    assert ga * ga < 4
    den = Poly([1, ga, 1])
    dlt = be - ga
    th = F(abs(dlt), 2)
    num = "kx^{2} %s + k" % (sg(be) + "x" if abs(be) != 1 else ("+ x" if be > 0 else M + " x"))
    lx = poly([(dlt, "x")])
    diff = "(k − 1)x^{2} %s + (k − 1)" % (("+ " + lx) if dlt > 0 else (M + " " + lx[1:]))
    return item("pp_frac", "param", 3, "分式恆成立", 1.35,
                "對所有實數 x，\\frac{%s}{%s} > 1 都成立。求 k 的範圍。" % (num, den.text()),
                [ch("能直接去分母嗎？", ["可以：分母恆正", "不行：分母可能是負的", "不行：分母可能是 0", "不行：要先平方"],
                    "%s 的判別式 %s − 4 < 0、首項 > 0" % (den.text(), t(ga * ga)), "%s 恆正，兩邊同乘不變號" % den.text()),
                 ch("去分母、移項，對所有 x：", uniq(["%s > 0" % diff],
                                              ["(k − 1)x^{2} %s + (k − 1) > 0" % (("+ " if be + ga > 0 else M + " ") + poly([(abs(be + ga), "x")])),
                                               "(k + 1)x^{2} %s + (k + 1) > 0" % (("+ " + lx) if dlt > 0 else (M + " " + lx[1:])),
                                               "(k − 1)x^{2} %s + (k + 1) > 0" % (("+ " + lx) if dlt > 0 else (M + " " + lx[1:])),
                                               "%s < 0" % diff]),
                    "%s − (%s)" % (num, den.text()), "%s > 0 對所有 x 成立" % diff),
                 ch("判別式 = ？", ["%s − 4(k − 1)^{2}" % t(dlt * dlt), "%s − 4(k − 1)" % t(dlt * dlt), "%s − 4(k − 1)^{2}" % t(dlt * dlt + 3), "%s + 4(k − 1)^{2}" % t(dlt * dlt)],
                    "%s^{2} − 4(k − 1)(k − 1)" % tp(dlt), "%s − 4(k − 1)^{2} < 0" % t(dlt * dlt),
                    pre="k = 1 時是 %s > 0，不恆成立。k ≠ 1：要開口向上 k − 1 > 0、判別式 < 0" % lx),
                 fl("移項：", "(k − 1)^{2} > [0]", [a(th * th)], "4(k − 1)^{2} > %s" % t(dlt * dlt)),
                 ch("k − 1 > 0，而且 (k − 1)^{2} > %s，所以 k 的範圍：" % t(th * th),
                    ["k > %s" % t(1 + th), "k > %s" % t(th), "k < %s 或 k > %s" % (t(1 - th), t(1 + th)), "1 < k < %s" % t(1 + th)],
                    "k − 1 是正的：k − 1 > %s" % t(th), "答：k > %s" % t(1 + th))])


# ---------- pp_nosol：無解 ----------

def pp_nosol(h, c, e):
    """ax^2 + 2h·a x + (ca + e) < 0 無解"""
    co = 4 * (h * h - c)
    assert co > 0 and e > 0
    top = F(4 * e, co)
    const = "(%s)" % poly([(c, "a"), (e, "")]) if c >= 0 else "(%s)" % poly([(e, ""), (c, "a")])
    lin_ = "ax^{2} %s %s" % (("+ " if h > 0 else M + " ") + ("" if abs(2 * h) == 1 else t(abs(2 * h))) + "ax", "+ " + const)
    return item("pp_nosol", "param", 3, "無解", 1.35, "不等式 %s < 0 無解。求 a 的範圍。" % lin_,
                [ch("「左邊 < 0」無解，等於說對所有 x：", ["左邊 ≥ 0", "左邊 > 0", "左邊 ≤ 0", "左邊 = 0"],
                    "沒有任何 x 讓它 < 0，就是每個 x 都讓它 ≥ 0（等號也可以）", "無解 ⇔ 對所有 x：%s ≥ 0" % lin_),
                 ch("a = 0 時不等式變成什麼？", ["%d < 0，無解，a = 0 可以" % e, "%d < 0，有解" % e, "0 < 0，有解", "%s < 0，有解" % poly([(2 * h, "x"), (e, "")])],
                    "a = 0：只剩常數 %d" % e, "a = 0：%d < 0 無解 ✓" % e, col="A"),
                 ch("a ≠ 0 時，二次式恆 ≥ 0 的條件：", ["a > 0 且判別式 ≤ 0", "a > 0 且判別式 < 0", "a < 0 且判別式 ≤ 0", "判別式 ≥ 0"],
                    "開口向上，可以碰到 x 軸（判別式 = 0 也行）", "a > 0 且判別式 ≤ 0", col="B"),
                 fl("算判別式：", "(%sa)^{2} − 4a%s = [0]a^{2} %s" % (t(2 * h), const, sg(-4 * e) + "a"), [a(co)],
                    poly([(4 * h * h, "a^{2}"), (-4 * c, "a^{2}")]), col="B"),
                 fl("%sa(a %s) ≤ 0，再配合 a > 0：" % (t(co), sg(-top)), "[0] < a ≤ [1]", ["0", a(top)], "兩根 0、%s" % t(top), col="B"),
                 ch("兩條路線合起來：", ["0 ≤ a ≤ %s" % t(top), "0 < a ≤ %s" % t(top), "0 < a < %s" % t(top), "a ≤ %s" % t(top)],
                    "路線 B 的 0 < a ≤ %s，再加上路線 A 的 a = 0" % t(top), "答：0 ≤ a ≤ %s" % t(top))],
                routes={"A": "a = 0", "B": "a ≠ 0"})


# ---------- pp_ratio：兩個截距的比 ----------

def pp_ratio(n, s, C):
    A0 = F(s, 1 - n)
    B0 = -n * A0
    assert A0 < 0 < B0
    k = F(C, A0 * B0)
    assert k < 0 and isint(k)
    stem_f = "kx^{2} %s + %d" % (("− " + ("" if s == 1 else str(s)) + "kx") if s > 0 else ("+ " + str(-s) + "kx"), C)
    return item("pp_ratio", "param", 2, "兩個截距的比", 1.2,
                "開口向下的二次函數 f(x) = %s 與 x 軸交於 A(a, 0)、B(b, 0)，b > a，且 %s\\ol{AO} = \\ol{BO}（O 是原點）。求 k。" % (stem_f, "" if n == 1 else str(n)),
                [ch("開口向下 ⇒ k < 0。兩根之積 ab = %d/k，所以兩根？" % C, ["一正一負：a < 0 < b", "都是正的", "都是負的", "有一根是 0"],
                    "%d/k < 0" % C, "ab = %d/k < 0　→　a < 0 < b" % C),
                 ch("\\ol{AO} = −a、\\ol{BO} = b，所以？", ["b = −%da" % n, "b = %da" % n, "a = −%db" % n, "a = %db" % n],
                    "%s\\ol{AO} = \\ol{BO} ⇒ %s(−a) = b" % (n, n), "b = −%da" % n),
                 fl("兩根之和 = %s：" % t(s), "a + b = %s，b = −%da　→　a = [0]，b = [1]" % (t(s), n), [a(A0), a(B0)],
                    "a + (−%da) = %sa = %s" % (n, (M if 1 - n == -1 else t(1 - n)), t(s))),
                 fl("求 k：", "答：ab = %d/k = %s　→　k = [0]" % (C, t(A0 * B0)), [a(k)], "%d/k = %s" % (C, t(A0 * B0)))])


# ---------- pp_maxat：參數在常數項 ----------

def pp_maxat(h, Mx, Pc):
    """y = ax^2 + bx + Pc/a 在 x = h 有最大值 Mx"""
    q = Poly([-Pc, Mx, h * h])       # h^2 a^2 + M a − P = 0
    rts = q.real_roots()
    rs = sorted(F(r).limit_denominator(100) for r in rts)
    assert all(q(r) == 0 for r in rs)
    aneg = [r for r in rs if r < 0][0]
    apos = [r for r in rs if r > 0][0]
    b = -2 * h * aneg
    g = h * h
    eq = Poly([-Pc, Mx, g])
    return item("pp_maxat", "param", 2, "參數在常數項", 1.15,
                "二次函數 y = ax^{2} + bx + %d/a 在 x = %d 時有最大值 %s。求數對 (a, b)。" % (Pc, h, t(Mx)),
                [ch("對稱軸 x = %d 告訴我們：" % h, ["b = %s" % cx(-2 * h, "a"), "b = %s" % cx(2 * h, "a"), "b = %s" % cx(-h, "a"), "a + b = %d" % h],
                    "−b/(2a) = %d" % h, "−b/(2a) = %d　→　b = %s" % (h, cx(-2 * h, "a"))),
                 ch("f(%d) = %s，代入整理：" % (h, t(Mx)), uniq(["%s = 0" % eq.text("a")],
                                                       ["%s = 0" % Poly([-Pc, -Mx, g]).text("a"), "%s = 0" % Poly([Pc, Mx, g]).text("a"), "%s = 0" % Poly([Pc, -Mx, g]).text("a")]),
                    "%sa − %sa + %d/a = %s，兩邊乘 a" % (t(h * h) if h != 1 else "", t(2 * h * h) if h != 1 else "2", Pc, t(Mx)),
                    "%s = 0　→　a = %s 或 %s" % (eq.text("a"), t(rs[0]), t(rs[1]))),
                 step("roots", q="有「最大值」：把不合的 a 劃掉。", cands=[{"v": "a = %s" % t(aneg), "ok": True, "why": "a < 0 開口向下，才有最大值"},
                                                                {"v": "a = %s" % t(apos), "ok": False, "why": "a > 0 開口向上，只有最小值"}],
                      write="a = %s（a = %s 開口向上，不合）" % (t(aneg), t(apos))),
                 fl("求 b：", "b = %s = [0]" % cx(-2 * h, "a"), [a(b)], "%s × %s" % (t(-2 * h), tp(aneg)), write="答：(a, b) = (%s, %s)" % (t(aneg), t(b)))])


# ---------- pp_quadrants：通過四個象限 ----------

def _roots_say(a_, b_, c_):
    D = b_ * b_ - 4 * a_ * c_
    if D < 0:
        return "沒有實根", False
    prod = F(c_, a_)
    s_ = F(-b_, a_)
    if prod < 0:
        return "兩根一正一負", True
    if prod == 0:
        return "有一根是 0", False
    return ("兩根都正" if s_ > 0 else "兩根都負"), False


def pp_quadrants(h, L, R, M_, m_):
    far, near = _vert_ends(h, L, R)
    d2 = (far - h) ** 2
    aA, aB = F(M_ - m_, d2), F(m_ - M_, d2)
    bA, bB = m_ + aA * h * h, M_ + aB * h * h
    fA, fB = Poly([bA, -2 * aA * h, aA]), Poly([bB, -2 * aB * h, aB])
    sA, okA = _roots_say(aA, -2 * aA * h, bA)
    sB, okB = _roots_say(aB, -2 * aB * h, bB)
    assert okA or okB
    q_opts = lambda s_, ok: uniq([("會：" if ok else "不會：") + s_], ["會：兩根一正一負", "不會：兩根都正", "不會：兩根都負", "不會：沒有實根"])
    if okA and okB:
        ans = "(%s, %s) 或 (%s, %s)" % (t(aA), t(bA), t(aB), t(bB))
    elif okA:
        ans = "(%s, %s)" % (t(aA), t(bA))
    else:
        ans = "(%s, %s)" % (t(aB), t(bB))
    finals = uniq([ans], ["(%s, %s)" % (t(aB), t(bB)), "(%s, %s)" % (t(aA), t(bA)), "(%s, %s) 或 (%s, %s)" % (t(aA), t(bA), t(aB), t(bB)), "(%s, %s)" % (t(aB), t(bA))])
    vtx = poly([(1, "b"), (-h * h, "a")])
    endv = poly([(far * far - 2 * h * far, "a"), (1, "b")])
    f_stem = poly([(1, "ax^{2}"), (-2 * h, "ax"), (1, "b")])
    return item("pp_quadrants", "param", 3, "通過四個象限", 1.35,
                "二次函數 f(x) = %s 在 %s ≤ x ≤ %s 的最大值為 %s、最小值為 %s，且圖形通過四個象限。求數對 (a, b)。" % (f_stem, t(L), t(R), t(M_), t(m_)),
                [ch("對稱軸 x = %s 在範圍內，離它最遠的端點是？" % t(h),
                    uniq(["x = %s，f(%s) = %s" % (t(far), t(far), endv)], ["x = %s，f(%s) = %s" % (t(near), t(near), poly([(near * near - 2 * h * near, "a"), (1, "b")])),
                                                                          "x = %s，f(%s) = %s" % (t(far), t(far), poly([(far * far, "a"), (1, "b")])), "兩端一樣遠"]),
                    "%s − %s = %s > %s" % (t(max(far, h)), tp(min(far, h)), t(abs(far - h)), t(abs(near - h))), "f(%s) = %s，f(%s) = %s" % (t(h), vtx, t(far), endv)),
                 fl("a > 0：頂點最小 %s = %s、x = %s 最大 %s = %s。相減後再代回：" % (vtx, t(m_), t(far), endv, t(M_)),
                    "%sa = [0] ⇒ (a, b) = ([1], [2])" % t(d2), [a(M_ - m_), a(aA), a(bA)], "%s − %s = %s" % (t(M_), tp(m_), t(M_ - m_)), col="A",
                    write="f(x) = %s" % fA.text()),
                 ch("f(x) = %s 通過四個象限嗎？" % fA.text(), q_opts(sA, okA), "兩根之積 %s、和 %s" % (t(bA / aA), t(2 * h)),
                    "%s ⇒ %s" % (sA, "通過四個象限 ✓" if okA else "不合 ✗"), col="A"),
                 fl("a < 0：頂點最大 %s = %s、x = %s 最小 %s = %s。相減後再代回：" % (vtx, t(M_), t(far), endv, t(m_)),
                    "%sa = [0] ⇒ (a, b) = ([1], [2])" % t(d2), [a(m_ - M_), a(aB), a(bB)], "%s − %s = %s" % (t(m_), tp(M_), t(m_ - M_)), col="B",
                    write="f(x) = %s" % fB.text()),
                 ch("f(x) = %s 通過四個象限嗎？" % fB.text(), q_opts(sB, okB), "兩根之積 %s、和 %s" % (t(bB / aB), t(2 * h)),
                    "%s ⇒ %s" % (sB, "通過四個象限 ✓" if okB else "不合 ✗"), col="B"),
                 ch("答案是？", finals, "要看哪一條路線的圖形通過四個象限", "答：(a, b) = " + ans)],
                routes={"A": "a > 0", "B": "a < 0"})


# ---------- pp_chord：平移後的弦長 ----------

def pp_chord(d1, s, d2):
    a_ = F(4 * s, d2 * d2 - d1 * d1)
    return item("pp_chord", "param", 2, "平移後的弦長", 1.25,
                "y = ax^{2} + bx + c 與 x 軸交於 P、Q，\\ol{PQ} = %d。把圖形向下平移 %d 單位，交 x 軸於 R、S，\\ol{RS} = %d。求 a。" % (d1, s, d2),
                [ch("兩根的差：\\ol{PQ}^{2} = ？", ["(b^{2} − 4ac)/a^{2}", "(b^{2} − 4ac)/a", "b^{2} − 4ac", "(b^{2} − 4ac)/(4a^{2})"],
                    "|α − β| = \\frac{√{b^{2} − 4ac}}{|a|}", "\\ol{PQ}^{2} = (b^{2} − 4ac)/a^{2} = %d" % (d1 * d1)),
                 ch("向下平移 %d：c 變成 c − %d。新的判別式？" % (s, s), uniq(["b^{2} − 4ac + %da" % (4 * s)], ["b^{2} − 4ac − %da" % (4 * s), "b^{2} − 4ac + %da" % s, "b^{2} − 4ac + %d" % (4 * s)]),
                    "b^{2} − 4a(c − %d)" % s, "\\ol{RS}^{2} = (b^{2} − 4ac + %da)/a^{2} = %d + %d/a = %d" % (4 * s, d1 * d1, 4 * s, d2 * d2)),
                 fl("求 a：", "答：%d/a = %d　→　a = [0]" % (4 * s, d2 * d2 - d1 * d1), [a(a_)], "a = %d/%d" % (4 * s, d2 * d2 - d1 * d1))])


# ---------- pp_negx：x < 0 的代換 ----------

def pp_negx(p, q):
    vt = F(-p, 2)
    if vt <= -2:
        mn, at = q - F(p * p, 4), vt
        inside = True
    else:
        mn, at = 4 - 2 * p + q, -2
        inside = False
    sq = "(t %s)^{2} %s" % (sg(F(p, 2)), sg(q - F(p * p, 4)))
    f_t = poly([(1, "t^{2}"), (p, "t"), (q, "")])
    right = ("在：t = %s 時最小值 %s" % (t(vt), t(mn))) if inside else ("不在：t = −2 時最小 %s" % t(mn))
    others = ["在：最小值 %s" % t(q - F(p * p, 4)) if not inside else "不在：t = −2 時最小 %s" % t(4 - 2 * p + q),
              "不在：t = −2 時最小 %s" % t(4 + 2 * p + q), "不在：沒有最小值"]
    return item("pp_negx", "param", 2, "x < 0 的代換", 1.2,
                "設 x < 0，求 f(x) = (x + 1/x)^{2} %s(x + 1/x) %s 的最小值。" % (sg(p), sg(q)),
                [ch("令 t = x + 1/x。x < 0 時 t 的範圍？", ["t ≤ −2", "t ≥ 2", "t < 0", "全體實數"],
                    "−x > 0：(−x) + 1/(−x) ≥ 2，等號在 x = −1", "x < 0：t = x + 1/x ≤ −2"),
                 ch("f = %s 配方：" % f_t, uniq([sq], ["(t %s)^{2} %s" % (sg(F(-p, 2)), sg(q - F(p * p, 4))), "(t %s)^{2} %s" % (sg(F(p, 2)), sg(q)),
                                                    "(t %s)^{2} %s" % (sg(p), sg(q - p * p))]),
                    "t^{2} %st = (t %s)^{2} − %s" % (sg(p), sg(F(p, 2)), t(F(p * p, 4))), "f = %s，頂點 t = %s" % (sq, t(vt))),
                 ch("頂點 t = %s 在 t ≤ −2 裡面嗎？最小值？" % t(vt), uniq([right], others),
                    "t = %s %s −2" % (t(vt), "≤" if inside else ">") + ("，頂點就是最低點" if inside else "：t ≤ −2 這一段在頂點左邊，是遞減的，越靠近 −2 越小"),
                    "答：" + (("頂點在範圍內，t = %s 時最小值 %s" % (t(vt), t(mn))) if inside else ("頂點不在範圍內，t = −2（x = −1）時最小值 %s" % t(mn))))])


# ---------- pp_abs：絕對值的交點 ----------

def pp_abs(c, xr, yr):
    """|x^2 − cx| = x + k 恰有兩個相異實根"""
    f = lambda x: abs(x * x - c * x) - x
    top_x = F(c - 1, 2)
    top = top_x * top_x
    low = F(-c)
    # 數交點
    def cnt(k):
        xs = np.linspace(-20, 20, 400001) + 1e-7
        ys = np.abs(xs * xs - c * xs) - xs - k
        s = np.sign(ys)
        n = int(np.sum(s[:-1] * s[1:] < 0))
        # 相切（碰一下）：數值找不到變號，用頂點補
        if abs(k - float(top)) < 1e-9:
            n += 1
        return n
    for k, want in [(float(low) - 0.5, 0), (float(low) + 0.01, 2), (-0.01, 2), (0.01, 4), (float(top) - 0.01, 4), (float(top) + 0.01, 2), (50, 2)]:
        assert cnt(k) == want, (c, k, cnt(k), want)
    ans = "%s < k < 0 或 k > %s" % (t(low), t(top))
    return item("pp_abs", "param", 3, "絕對值的交點", 1.35, "方程式 |x^{2} − %dx| = x + k 恰有兩個相異實根。求 k 的範圍。" % c,
                [ch("移項：把它看成哪兩個圖形的交點？", ["y = |x^{2} − %dx| − x 和水平線 y = k" % c, "y = |x^{2} − %dx| 和 y = k" % c, "y = x^{2} − %dx 和 y = x + k" % c, "y = |x^{2} − %dx| + x 和 y = k" % c],
                    "k 單獨放一邊，交點個數就是水平線和曲線的交點個數", "f(x) = |x^{2} − %dx| − x 與 y = k 的交點" % c),
                 ch("0 < x < %d 時 x^{2} − %dx < 0，f(x) = ？" % (c, c), uniq([Poly([0, c - 1, -1]).text()], [Poly([0, -(c + 1), 1]).text(), Poly([0, c + 1, -1]).text(), Poly([0, -(c - 1), -1]).text()]),
                    "|x^{2} − %dx| = −(x^{2} − %dx)，再減 x" % (c, c), "0 < x < %d 時：f(x) = %s" % (c, Poly([0, c - 1, -1]).text()),
                    pre="x ≤ 0 或 x ≥ %d 時 x^{2} − %dx ≥ 0：f(x) = %s" % (c, c, Poly([0, -(c + 1), 1]).text())),
                 ch("轉折的地方：f(0)、中間的最高點、f(%d) 依序是？" % c,
                    uniq(["0、%s（x = %s）、%s" % (t(top), t(top_x), t(low)), ], ["0、%s（x = %s）、%s" % (t(top_x), t(top_x), t(low)), "0、%s（x = %s）、%s" % (t(top), t(top_x), t(-low)),
                                                                            "0、%s（x = %s）、%s" % (t(top + 2), t(top_x + 1), t(low)), "0、%s（x = %s）、%s" % (t(top * 4), t(top_x), t(low))]),
                    "%s = −(x − %s)^{2} + %s" % (Poly([0, c - 1, -1]).text(), t(top_x), t(top)), "f(0) = 0，f(%s) = %s，f(%d) = %s" % (t(top_x), t(top), c, t(low))),
                 ch("看右邊的圖，水平線 y = k 和曲線恰交兩點：", uniq([ans], ["k > %s" % t(low), "%s < k < %s" % (t(low), t(top)), "k < 0 或 k > %s" % t(top)]),
                    "k = 0、k = %s 時交三點，0 < k < %s 交四點，k = %s 只交一點" % (t(top), t(top), t(low)), "答：" + ans)],
                plot=grid(xr, yr, [{"f": "abs(x*x-%s*x)-x" % float(c), "c": "orange", "at": 2}],
                          [{"x": 0, "y": 0, "label": "", "at": 3}, {"x": float(top_x), "y": float(top), "label": "", "at": 3},
                           {"x": float(c), "y": float(low), "label": "(%s, %s)" % (t(c), t(low)), "at": 3}]))


def items():
    return [
        [pp_twoway(-2, -3, 1, 12, -6), pp_twoway(1, -2, 2, 10, 1), pp_twoway(2, 1, 5, 14, -4)],
        [pp_pos(-1, 8), pp_pos(1, 3), pp_pos(-2, 6)],
        [pp_below(1, 1, -2, 2, 1), pp_below(2, 1, 0, 3, 1), pp_below(-1, -1, -3, -2, -1)],
        [pp_frac(-2, -1), pp_frac(-3, 1), pp_frac(6, 0)],
        [pp_nosol(2, 3, 2), pp_nosol(3, 5, 4), pp_nosol(-1, -3, 6)],
        [pp_ratio(2, 1, 8), pp_ratio(3, 2, 9), pp_ratio(4, 3, 12)],
        [pp_maxat(1, 2, 48), pp_maxat(1, -3, 18), pp_maxat(2, 4, 8)],
        [pp_quadrants(1, -1, 2, 7, -1), pp_quadrants(1, -1, 2, 1, -7), pp_quadrants(2, 0, 5, 9, -9)],
        [pp_chord(4, 2, 6), pp_chord(2, 3, 4), pp_chord(6, 1, 8)],
        [pp_negx(2, -5), pp_negx(6, 1), pp_negx(3, -2)],
        [pp_abs(2, (-1.5, 4.0), (-3.0, 4.0)), pp_abs(3, (-1.5, 5.0), (-4.0, 4.0)), pp_abs(4, (-1.5, 6.0), (-5.0, 5.0))],
    ]
