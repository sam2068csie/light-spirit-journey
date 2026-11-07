# 餘式迴響
from plib import *


def sgt(v):
    """ + 3、 − 3；0 時不寫"""
    if v == 0:
        return ""
    return (" + " + t(v)) if v > 0 else (" " + M + " " + t(-v))


def sgc(v, s):
    """ + 3(x + 1)、 − (x + 1)"""
    if v == 0:
        return ""
    co = "" if abs(v) == 1 else t(abs(v))
    return (" + " if v > 0 else " " + M + " ") + co + s


def co1(v):
    """係數：1 不寫、−1 寫 −"""
    return "" if v == 1 else (M if v == -1 else t(v))


def P(cs):
    """係數由高到低"""
    return Poly(list(reversed(cs)))


def dv(r):
    """除式 x − r 的寫法"""
    return fac(r).strip("()") if r != 0 else "x"


# ---------- pr_two：兩個餘式拼一個 ----------

def pr_two(p, u, q, v):
    a_ = F(u - v, p - q)
    b_ = u - p * a_
    assert isint(a_) and isint(b_)
    d = Poly.roots([p, q])
    R = Poly([b_, a_])
    return item("pr_two", "remain", 1, "兩個餘式拼一個", 1.05,
                "多項式 f(x) 除以 %s 的餘式為 %s，除以 %s 的餘式為 %s。求 f(x) 除以 %s 的餘式。" % (dv(p), t(u), dv(q), t(v), d.text()),
                [ch("除式是二次式，餘式最多幾次？怎麼假設？", ["設餘式為 ax + b", "設餘式為 ax^{2} + bx + c", "設餘式為 a", "設餘式為 a%s" % fac(p)],
                    "餘式的次數要比除式低", "f(x) = %s%sQ(x) + ax + b" % (fac(p), fac(q))),
                 fl("代 x = %d 和 x = %d（%s%sQ(x) 變成 0）：" % (p, q, fac(p), fac(q)),
                    "f(%d) = %s = [0]，f(%d) = %s = [1]" % (p, poly([(p, "a"), (1, "b")]), q, poly([(q, "a"), (1, "b")])), [a(u), a(v)],
                    "f(%d) = %s、f(%d) = %s" % (p, t(u), q, t(v))),
                 fl("兩式相減，b 消掉：", "(%s) − (%s) = %sa = [0]" % (poly([(p, "a"), (1, "b")]), poly([(q, "a"), (1, "b")]), t(p - q)), [a(u - v)],
                    "%s − %s" % (t(u), tp(v))),
                 fl("求 a、b：", "a = [0]，b = [1]", [a(a_), a(b_)], "a = %s/%s，再代回 %s = %s" % (t(u - v), t(p - q), poly([(p, "a"), (1, "b")]), t(u)),
                    write="答：餘式 %s" % R.text())])


# ---------- pr_square：除以平方式 ----------

def pr_square(cs, c):
    f = P(cs)
    q1, r1 = f.divmod(Poly([-c, 1]))
    fc = f(c)
    qc = q1(c)
    R = qc * Poly([-c, 1]) + fc
    assert R == f % Poly.roots([c, c])
    opts1 = uniq([t(fc)], [t(f(-c)), t(qc), t(fc + 1), t(fc - 3)])
    optsR = uniq([R.text()], [t(qc), Poly([0, qc]).text(), t(fc), (qc * Poly([c, 1]) + fc).text()])
    return item("pr_square", "remain", 2, "除以平方式", 1.2,
                "求 f(x) = %s 除以 %s^{2} 的餘式。" % (f.text(), fac(c)),
                [ch("連續兩次用 %s 做綜合除法。第一次的餘數 f(%d) = ？" % (dv(c), c), opts1,
                    " + ".join(t(co * c ** i) for i, co in reversed(list(enumerate(f.c))) if co != 0).replace("+ −", "− "),
                    "第一次：f(x) = %sq(x)%s，q(x) = %s" % (fac(c), sgt(fc), q1.text())),
                 fl("第二次：再把 q(x) 除以 %s：" % dv(c), "q(%d) = [0]" % c, [a(qc)], "代 x = %d 進 q(x) = %s" % (c, q1.text()),
                    write="第二次：q(x) = %sQ(x) %s" % (fac(c), ("+ " + t(qc)) if qc >= 0 else (M + " " + t(-qc)))),
                 ch("所以 f(x) 除以 %s^{2} 的餘式是？" % fac(c), optsR,
                    "f(x) = %s[%sQ(x)%s]%s = %s^{2}Q(x)%s%s" % (fac(c), fac(c), sgt(qc), sgt(fc), fac(c), sgc(qc, fac(c)), sgt(fc)),
                    "f(x) = %s^{2}Q(x)%s%s　→　答：%s" % (fac(c), sgc(qc, fac(c)), sgt(fc), R.text()))])


# ---------- pr_mod4：降次的陷阱 ----------

def pr_mod4(k, terms, const):
    """除以 x^k − x；terms = [(係數, 次方)]"""
    m = k - 1
    red = lambda n: n if n < k else ((n - 1) % m) + 1
    D = Poly([0, -1] + [0] * (k - 2) + [1])
    f = Poly([const])
    R = Poly([const])
    for co, n in terms:
        f = f + Poly([0] * n + [co])
        R = R + Poly([0] * red(n) + [co])
    assert R == f % D
    wrongR = Poly([const])
    for co, n in terms:
        wrongR = wrongR + Poly([0] * (n % m) + [co])
    big = [(co, n) for co, n in terms if n >= k]
    n1, n2 = big[0][1], big[1][1]
    xp = lambda n: "x" if n == 1 else ("1" if n == 0 else "x^{%d}" % n)
    ftext = poly([(co, xp(n)) for co, n in terms] + [(const, "")])
    optsR = uniq([R.text()], [wrongR.text(), (R + 3).text(), (R - Poly([const])).text(), (R + X).text()])
    return item("pr_mod4", "remain", 3, "降次的陷阱", 1.2,
                "求 %s 除以 x^{%d} − x 的餘式。" % (ftext, k),
                [ch("除以 x^{%d} − x 時，x^{%d} 可以換成什麼？" % (k, k), ["x", "1", "0", "x^{%d}" % (k - 1)],
                    "x^{%d} − x 除以自己餘 0，所以 x^{%d} 和 x 的餘式一樣" % (k, k), "除以 x^{%d} − x 時，x^{%d} 可以換成 x（餘式不變）" % (k, k)),
                 ch("x^{n}（n ≥ %d）每換一次，次方會？最後停在幾次？" % k,
                    ["減 %d，停在 1～%d 次" % (m, m), "減 %d，停在 0～%d 次" % (m, m - 1), "減 %d，停在 0～%d 次" % (k, m), "減 1，停在 1 次"],
                    "x^{n} = x^{n − %d} · x^{%d}，x^{%d} 換成 x 就是 x^{n − %d}。x^{%d} 不能再降成 x^{0}（只有 %d 次以上才能換）" % (k, k, k, m, m, k),
                    "x^{n} 換成 x^{n − %d}，只降到 %s" % (m, "、".join(xp(i) for i in range(1, k)))),
                 ch("x^{%d}、x^{%d} 各降成？" % (n1, n2), uniq(["%s、%s" % (xp(red(n1)), xp(red(n2)))],
                                                       ["%s、%s" % (xp(n1 % m), xp(n2 % m)), "%s、%s" % (xp(red(n2)), xp(red(n1))), "1、x", "x^{2}、x^{3}"]),
                    "%d = %d × %d + %d，%d = %d × %d + %d" % (n1, m, (n1 - red(n1)) // m, red(n1), n2, m, (n2 - red(n2)) // m, red(n2)),
                    "，".join("%s → %s" % (poly([(co, xp(n))]), poly([(co, xp(red(n)))])) for co, n in terms if n >= k)),
                 ch("餘式是？", optsR, "把每一項降次後加起來", "答：%s" % R.text())])


# ---------- pr_back：反推餘式 ----------

def ab(ca, cb, c0=0):
    """ca·a + cb·b + c0（用來寫含 a、b 的式子），b 寫在前面"""
    return poly([(cb, "b"), (ca, "a"), (c0, "")])


def pr_back(s, p, q, A, B):
    D = Poly([q, p, 1])
    R = (Poly([-s, 1]) * Poly([B, A])) % D
    xa, xb = -s - p, 1          # x 係數：(b − s a − p a)
    ca, cb = -q, -s             # 常數：−s b − q a
    good = "(%s)x %s" % (ab(xa, xb), ("+ " + ab(ca, cb)) if not ab(ca, cb).startswith(M) else (M + " " + ab(-ca, -cb)))
    def lin_ab(xa_, xb_, ca_, cb_):
        c = ab(ca_, cb_)
        xs_ = ("%sx" % ab(xa_, xb_)) if xa_ == 0 and xb_ == 1 else "(%s)x" % ab(xa_, xb_)
        return "%s %s" % (xs_, ("+ " + c) if not c.startswith(M) else (M + " " + c[1:]))
    opts = uniq([lin_ab(xa, xb, ca, cb)], [lin_ab(-s, 1, 0, -s), lin_ab(-s + p, 1, q, -s), lin_ab(xa, xb, -ca, cb), lin_ab(-s, 1, -q, -s)])
    # 比較係數
    eqx = "%s = %s" % (ab(xa, xb), t(R.c[1] if R.deg() >= 1 else 0))
    eqc = "%s = %s" % (ab(ca, cb), t(R.c[0]))
    return item("pr_back", "remain", 2, "反推餘式", 1.25,
                "%sf(x) 除以 %s 的餘式為 %s，求 f(x) 除以 %s 的餘式。" % (fac(s), D.text(), R.text(), D.text()),
                [ch("設 f(x) 除以 %s 的餘式為 ax + b，則 %sf(x) 和誰的餘式一樣？" % (D.text(), fac(s)),
                    ["%s(ax + b)" % fac(s), "ax + b", "%s + (ax + b)" % fac(s), R.text()],
                    "f(x) = (%s)Q(x) + ax + b，乘上 %s 以後第一項還是 %s 的倍式" % (D.text(), dv(s), D.text()),
                    "%sf(x) 和 %s(ax + b) 除以 %s 的餘式相同" % (fac(s), fac(s), D.text())),
                 ch("%s(ax + b) = ax^{2} + (%s)x %s。把 x^{2} 換成 %s 降次，餘式是？" % (fac(s), ab(-s, 1), (M + " " + ("" if s == 1 else t(s)) + "b") if s > 0 else ("+ " + ("" if s == -1 else t(-s)) + "b"), (-(D - Poly([0, 0, 1]))).text()),
                    opts, "ax^{2} 換成 a(%s)" % (-(D - Poly([0, 0, 1]))).text(), "%s(ax + b) 除以 %s 的餘式 = %s" % (fac(s), D.text(), opts[0])),
                 fl("和 %s 比較係數：%s，%s。解聯立：" % (R.text(), eqx, eqc), "a = [0]，b = [1]", [a(A), a(B)], "兩式消去一個未知數",
                    write="答：餘式 %s" % Poly([B, A]).text())])


# ---------- pr_nest：兩層除法 ----------

def pr_nest(L, r1, r2):
    Lp = P(L)
    Ls = Lp.text()
    R = r1 * Lp + r2
    opts = uniq([R.text()], [t(r1 + r2), (-r1 * Lp + r2).text(), (r1 * Lp).text(), (r1 * Lp - r2).text()])
    sg = lambda v: ("+ " + t(v)) if v >= 0 else (M + " " + t(-v))
    return item("pr_nest", "remain", 2, "兩層除法", 1.1,
                "g(x) 除以 %s 的餘式為 %s，f(x) 除以 g(x) 的商式為 %s、餘式為 %s。求 f(x) 除以 (%s)^{2} 的餘式。" % (Ls, t(r1), Ls, t(r2), Ls),
                [ch("f(x) 除以 g(x) 的除法寫成：f(x) = ？", ["(%s)g(x) %s" % (Ls, sg(r2)), "g(x)h(x) %s" % sg(r2), "(%s) + g(x) %s" % (Ls, sg(r2)), "%sg(x) + %s" % (co1(r2), Ls)],
                    "被除式 = 除式 × 商式 + 餘式", "f(x) = (%s)g(x) %s" % (Ls, sg(r2)), pre="g(x) = (%s)h(x) %s" % (Ls, sg(r1))),
                 ch("把 g(x) 代進去，f(x) = ？", uniq(["(%s)^{2}h(x) %s(%s) %s" % (Ls, "+ " + t(r1) if r1 > 0 else M + " " + (t(-r1) if r1 != -1 else ""), Ls, sg(r2))],
                                                 ["(%s)^{2}h(x) %s" % (Ls, sg(r1 + r2)), "(%s)h(x) %s" % (Ls, sg(r1 + r2)), "(%s)^{2}h(x) %s" % (Ls, sg(-r2))]),
                    "(%s)[(%s)h(x) %s] %s" % (Ls, Ls, sg(r1), sg(r2)), "f(x) = (%s)^{2}h(x) %s(%s) %s" % (Ls, "+ " + t(r1) if r1 > 0 else M + " " + (t(-r1) if r1 != -1 else ""), Ls, sg(r2))),
                 ch("f(x) 除以 (%s)^{2} 的餘式？" % Ls, opts, "%s(%s) %s 是一次式，次數已經比 (%s)^{2} 低" % (co1(r1), Ls, sg(r2), Ls),
                    "答：%s(%s) %s = %s" % (co1(r1), Ls, sg(r2), R.text()))])


# ---------- pr_twosq：兩個平方因式 ----------

def pr_twosq(p, q, A, B, r1):
    R1 = P(r1)
    Rx = Poly.roots([p, p]) * Poly([B, A]) + R1
    r2 = Rx % Poly.roots([q, q])
    d = q - p
    # u = x − q
    al, be = R1.c[1], R1.c[0]       # r1 = αx + β = αu + (αq + β)
    aqb = "%s" % poly([(q, "a"), (1, "b")])
    aqbp = "(%s)" % aqb if q != 0 else aqb
    c0 = d * d
    c1 = 2 * d
    r2u1, r2u0 = r2.c[1], r2(q)     # r2 = r2u1·u + r2(q)
    const_lhs = r2u0 - (al * q + be)
    s_ab = F(const_lhs, c0)          # qa + b
    assert q * A + B == s_ab
    # u 係數：2d(qa + b) + d^2 a + α = r2u1
    assert c1 * s_ab + c0 * A + al == r2u1
    xp, xq = fac(p), fac(q)
    D = Poly.roots([p, p, q, q])
    wrong = [(Poly.roots([p, p]) * Poly([A, B]) + R1).text(), (Poly.roots([p, p]) * Poly([B, A])).text(), (Rx + 2).text(), (-Rx + 2 * R1).text()]
    u_sub = "u %s %s" % ("+" if q > 0 else M, t(abs(q))) if q != 0 else "u"
    return item("pr_twosq", "remain", 3, "兩個平方因式", 1.35,
                "f(x) 除以 %s^{2} 的餘式為 %s，除以 %s^{2} 的餘式為 %s。求 f(x) 除以 %s^{2}%s^{2} 的餘式。" % (xp, R1.text(), xq, r2.text(), xp, xq),
                [ch("R(x) 怎麼假設最好？", ["%s^{2}(ax + b) + %s" % (xp, R1.text()), "ax + b", "%s(ax + b) + %s" % (xp, R1.text()), "%s^{2} + %s" % (xp, R1.text())],
                    "R(x) 最多三次，它除以 %s^{2} 的餘式也要是 %s" % (xp, R1.text()), "R(x) = %s^{2}(ax + b) + %s" % (xp, R1.text()),
                    pre="除式 %s^{2}%s^{2} 是四次，餘式 R(x) 最多三次" % (xp, xq)),
                 fl("%s^{2} = (u %s %s)^{2} = u^{2} %s %su + %s，ax + b = au + %s。R 除以 u^{2} 的餘式只看常數項和 u 項。常數項：" % (
                     xp, "+" if d > 0 else M, t(abs(d)), "+" if c1 > 0 else M, t(abs(c1)), t(c0), aqbp),
                    "常數項 = [0]%s%s" % (aqbp, addp(t(al * q + be))), [a(c0)], "%s × %s" % (t(c0), aqbp),
                    pre=("令 u = %s，x = %s" % (fac(q).strip("()"), u_sub)) if q != 0 else "令 u = x"),
                 fl("比較常數項：要等於 %s 除以 u^{2} 的常數項 %s。" % (r2.text(), t(r2u0)), "%s = [0]" % aqb, [a(s_ab)],
                    "%s%s = %s − %s" % (t(c0), aqbp, t(r2u0), tp(al * q + be))),
                 fl("u 的係數：%s%s + %sa%s 要等於 %s。代入 %s = %s：" % (t(c1), aqbp, t(c0), addp(t(al)), t(r2u1), aqb, t(s_ab)),
                    "a = [0]，b = [1]", [a(A), a(B)], "%sa = %s − %s − %s" % (t(c0), t(r2u1), tp(al), tp(c1 * s_ab))),
                 ch("所以餘式 R(x) = ？", uniq([Rx.text()], wrong), "%s^{2}(%s) + %s" % (xp, Poly([B, A]).text(), R1.text()),
                    "答：%s^{2}(%s) + %s = %s" % (xp, Poly([B, A]).text(), R1.text(), Rx.text()))])


# ---------- pr_near：近似值 ----------

def pr_near(cs, c, dx):
    f = P(cs)
    q1, r1 = f.divmod(Poly([-c, 1]))
    q2, r2 = q1.divmod(Poly([-c, 1]))
    q3, r3 = q2.divmod(Poly([-c, 1]))
    C, B, A = f(c), q1(c), q2(c)
    d = F(dx)
    exact = f(c + d)
    lin_ = C + B * d
    assert dec(lin_) == dec(exact) and dec(lin_ + A * d * d) == dec(exact)
    x0 = c + d
    xs = dec(x0, len(str(dx).split(".")[1]))
    cs_s = "、".join(t(v) for v in cs)
    sq = A * d * d
    return item("pr_near", "remain", 1, "近似值", 1.2,
                "f(x) = %s，求 f(%s) 的近似值（四捨五入到小數點後第二位）。" % (f.text(), xs),
                [fl("第一次綜合除法（係數 %s，除以 %s）：餘數就是 c。" % (cs_s, dv(c)), "c = f(%d) = [0]" % c, [a(C)],
                    "代 x = %d" % c, write="第一次的商：%s" % q1.text(),
                    pre="連續用 %s 做綜合除法，把 f(x) 寫成 %s(x − %d)^{3} + a(x − %d)^{2} + b(x − %d) + c" % (dv(c), "" if cs[0] == 1 else t(cs[0]), c, c, c)),
                 fl("第二次：把商 %s 再除以 %s，餘數就是 b。" % (q1.text(), dv(c)), "b = [0]", [a(B)], "代 x = %d 進 %s" % (c, q1.text()),
                    write="第二次的商：%s" % q2.text()),
                 fl("第三次：把 %s 除以 %s，餘數就是 a。" % (q2.text(), dv(c)), "a = [0]", [a(A)], "代 x = %d 進 %s" % (c, q2.text()),
                    write="f(x) = %s(x − %d)^{3}%s(x − %d)^{2}%s(x − %d)%s" % ("" if cs[0] == 1 else t(cs[0]), c, addp(t(A)), c, addp(t(B)), c, addp(t(C)))),
                 ch("x = %s 時 x − %d = %s。到小數點後第二位，要算到哪一項？" % (xs, c, str(dx)),
                    ["一次項就夠：%s + %s(%s)" % (t(C), tp(B), str(dx)), "只看常數項 %s" % t(C), "要四項全部算", "只算三次項"],
                    "%s(%s)^{2} = %s，不會影響第二位" % (t(A), str(dx), dec(sq, 6).rstrip("0")),
                    "f(%s) ≈ %s + %s(%s) + %s(%s)^{2} + …" % (xs, t(C), tp(B), str(dx), tp(A), str(dx))),
                 fl("到小數點後第二位：", "答：f(%s) ≈ %s%s%s ≈ [0]" % (xs, t(C), addp(dec(B * d, 4).rstrip("0").rstrip(".")), addp(dec(sq, 6).rstrip("0"))),
                    [dec(exact)], "%s 四捨五入" % dec(lin_ + sq, 6).rstrip("0"))])


# ---------- pr_basis：換一個基底 ----------

def pr_basis(m, n, A, B, C, x_big):
    """f = u^3 + A u^2 + B u + C，u = mx + n"""
    U = Poly([n, m])
    f = U ** 3 + A * U ** 2 + B * U + C
    x0 = F(-n, m)
    x1 = F(1 - n, m)
    xm = F(-1 - n, m)
    ub = m * F(x_big) + n
    assert ub == 100
    us = U.text()
    big = 100 ** 3 + A * 100 ** 2 + B * 100 + C
    return item("pr_basis", "remain", 2, "換一個基底", 1.3,
                "f(x) = %s = (%s)^{3} + a(%s)^{2} + b(%s) + c。\n(1) 求 (a, b, c)　(2) 求 f(%s)" % (f.text(), us, us, us, dec(x_big, 1) if not isint(x_big) else t(x_big)),
                [ch("令 u = %s。x = %s 時 u = 0，只剩 c。c = f(%s) = ？" % (us, t(x0), t(x0)), uniq([t(C)], [t(C + 1), t(f(0)), "0", t(C - 1)]),
                    "代 x = %s 進 f(x)" % t(x0), "u = %s，c = f(%s) = %s" % (us, t(x0), t(C))),
                 fl("x = %s 時 u = 1：右邊 = 1 + a + b + %s，左邊 f(%s) = %s。" % (t(x1), tp(C), t(x1), t(f(x1))), "a + b = [0]", [a(A + B)],
                    "%s − 1 − %s" % (t(f(x1)), tp(C))),
                 fl("x = %s 時 u = −1：右邊 = −1 + a − b + %s，左邊 f(%s) = %s。" % (t(xm), tp(C), t(xm), t(f(xm))), "a − b = [0]", [a(A - B)],
                    "%s + 1 − %s" % (t(f(xm)), tp(C))),
                 fl("兩式聯立：", "(1)　(a, b, c) = ([0], [1], %s)" % t(C), [a(A), a(B)], "相加：2a = %s" % t(2 * A)),
                 fl("x = %s 時 u = %s = 100：" % (dec(x_big, 1) if not isint(x_big) else t(x_big), us),
                    "(2)　f(%s) = 100^{3} %s · 100^{2} %s · 100 %s = [0]" % (dec(x_big, 1) if not isint(x_big) else t(x_big),
                                                                       ("+ " + t(A)) if A >= 0 else (M + " " + t(-A)), ("+ " + t(B)) if B >= 0 else (M + " " + t(-B)),
                                                                       ("+ " + t(C)) if C >= 0 else (M + " " + t(-C))), [a(big)],
                    "%s %s %s %s" % ("1000000", ("+ " + t(A * 10000)) if A >= 0 else (M + " " + t(-A * 10000)), ("+ " + t(B * 100)) if B >= 0 else (M + " " + t(-B * 100)),
                                     ("+ " + t(C)) if C >= 0 else (M + " " + t(-C))))])


# ---------- pr_lagr：三個一樣的值 ----------

def pr_lagr(rs, v, f0, x1):
    prod0 = 1
    for r in rs:
        prod0 *= -r
    k = F(f0 - v, prod0)
    assert isint(k)
    val = k
    for r in rs:
        val *= (x1 - r)
    val += v
    facs = "".join(fac(r) for r in rs)
    terms = " · ".join(tp(-r) for r in rs)
    return item("pr_lagr", "remain", 2, "三個一樣的值", 1.1,
                "三次多項式 f(x) 滿足 %s = %s，且 f(0) = %s。求 f(%d)。" % (" = ".join("f(%s)" % t(r) for r in rs), t(v), t(f0), x1),
                [ch("f(x) %s %s 有哪些根？" % ("−" if v >= 0 else "+", t(abs(v))),
                    ["x = " + "、".join(t(r) for r in rs), "x = " + "、".join(t(-r) for r in rs), "x = %s" % t(v), "x = " + "、".join(t(r) for r in rs) + "、0"],
                    "f(%s) %s %s = 0…" % (t(rs[0]), "−" if v >= 0 else "+", t(abs(v))), "f(x) %s %s = k%s" % ("−" if v >= 0 else "+", t(abs(v)), facs)),
                 fl("代 x = 0 求 k：", "f(0) %s %s = %s = k · %s　→　k = [0]" % ("−" if v >= 0 else "+", t(abs(v)), t(f0 - v), terms), [a(k)],
                    "%s = %sk" % (t(f0 - v), t(prod0))),
                 fl("求 f(%d)：" % x1, "答：f(%d) = %s%s %s %s = [0]" % (x1, "" if k == 1 else (t(k) + " · "), " · ".join(tp(x1 - r) for r in rs),
                                                                  "+" if v >= 0 else M, t(abs(v))), [a(val)], "先乘再加")])


# ---------- pr_prime：因式定理與整數 ----------

def pr_prime(pm, sgn):
    """x(x − a)(x − b) − sgn·pm：c(c − a)(c − b) = sgn·pm"""
    target = sgn * pm
    trip = (1, -1, -pm) if sgn > 0 else (pm, 1, -1)
    c_, ca, cb = trip
    assert c_ * ca * cb == target and c_ > ca > cb
    A, B = c_ - ca, c_ - cb
    assert 0 < A < B
    stem_c = ("− %d" % pm) if sgn > 0 else ("+ %d" % pm)
    alt = ["%s × 1 × 1" % t(target), "(−1) × (−1) × %s" % t(target), "1 × %s × (−1)" % t(-target)]
    right = "%s × %s × %s" % (tp(c_), tp(ca), tp(cb))
    return item("pr_prime", "remain", 3, "因式定理與整數", 1.25,
                "a、b、c 是整數，0 < a < b。若 x − c 是 x(x − a)(x − b) %s 的因式，求 (a, b, c)。" % stem_c,
                [ch("因式定理告訴我們：", ["c(c − a)(c − b) = %s" % t(target), "c(c − a)(c − b) = 0", "abc = %s" % t(target), "c − a − b = %s" % t(target)],
                    "x − c 是因式 ⇔ x = c 代入等於 0", "c(c − a)(c − b) %s = 0　→　c(c − a)(c − b) = %s" % (stem_c, t(target))),
                 ch("c > c − a > c − b 是三個不同的整數，乘積是 %s。只可能是？" % t(target), uniq([right], alt),
                    "0 < a < b 讓三個數一定不同。%d 是質數，拆成三個整數相乘，只能用 ±1、±%d，要三個都不同，只剩一組" % (pm, pm),
                    "0 < a < b ⇒ c > c − a > c − b，三個不同的整數乘積是 %s\n%d 是質數：只能是 %s\n由大到小：c = %s，c − a = %s，c − b = %s" % (
                        t(target), pm, right, t(c_), t(ca), t(cb))),
                 fl("求 (a, b, c)：", "答：(a, b, c) = ([0], [1], [2])", [A, B, c_], "%s − a = %s，%s − b = %s" % (t(c_), t(ca), t(c_), t(cb)))])


# ---------- pr_hidden：藏起來的平移 ----------

def pr_hidden(g, s, i1, sq2, sq3):
    """f(t) = g(t + s)。i1：整數輸入；sq2 = (n, d) 表示 f(√n + d)；sq3 = (num, n, e) 表示 f(num/(√n + e))，num/(√n + e) = √n − e"""
    G = P(g)
    Fp = G.compose(Poly([s, 1]))
    n3, rad3, e3 = sq3
    assert n3 == rad3 - e3 * e3
    sh = lambda v: ("%s + %s" if v > 0 else "%s − %s") % ("%s", t(abs(v)))
    f2 = "√{%d} %s %s" % (sq2[0], "+" if sq2[1] > 0 else M, t(abs(sq2[1])))
    g2 = "√{%d} %s %s" % (sq2[0], "+" if sq2[1] + s > 0 else M, t(abs(sq2[1] + s))) if sq2[1] + s != 0 else "√{%d}" % sq2[0]
    f3 = "%d/(√{%d} %s %s)" % (n3, rad3, "+" if e3 > 0 else M, t(abs(e3)))
    simp3 = "√{%d} %s %s" % (rad3, M if e3 > 0 else "+", t(abs(e3)))
    g3v = -e3 + s
    g3 = "√{%d} %s %s" % (rad3, "+" if g3v > 0 else M, t(abs(g3v))) if g3v != 0 else "√{%d}" % rad3
    rel = ("多 %s" % t(s)) if s > 0 else ("少 %s" % t(-s))
    return item("pr_hidden", "remain", 3, "藏起來的平移", 1.3,
                "f(x) = ax^{2} + bx + c，g(x) = %s。已知 f(%s) = g(%s)、f(%s) = g(%s)、f(%s) = g(%s)。求 a + b + c。" % (
                    G.text(), t(i1), t(i1 + s), f2, g2, f3, g3),
                [ch("先化簡 %s：" % f3, uniq([simp3], ["√{%d} %s %s" % (rad3, "+" if e3 > 0 else M, t(abs(e3))), "(%s)/%d" % (simp3, n3), "%d√{%d} %s %d" % (n3, rad3, M if e3 > 0 else "+", n3 * abs(e3))]),
                    "分子分母同乘 √{%d} %s %s：%d(%s)/(%d − %d)" % (rad3, M if e3 > 0 else "+", t(abs(e3)), n3, simp3, rad3, e3 * e3), "%s = %s" % (f3, simp3)),
                 ch("三組的輸入有什麼共同點？", ["g 的輸入都比 f 的輸入%s" % rel, "g 的輸入都是 f 的輸入的 2 倍", "f、g 的輸入相加都是 %s" % t(s), "沒有共同點"],
                    "%s → %s、%s → %s、%s → %s" % (t(i1), t(i1 + s), f2, g2, simp3, g3), "f(t) = g(t %s %s) 在三個 t 都成立" % ("+" if s > 0 else M, t(abs(s)))),
                 ch("f(x) − g(x %s %s) 最多二次，卻有三個不同的根。所以？" % ("+" if s > 0 else M, t(abs(s))),
                    ["f(x) = g(x %s %s) 恆成立" % ("+" if s > 0 else M, t(abs(s))), "f(x) = g(x) 恆成立", "f(x) − g(x %s %s) 是一次式" % ("+" if s > 0 else M, t(abs(s))), "無法確定 f(x)"],
                    "次數 ≤ 2 的多項式有 3 個根，只能是零多項式", "f(x) = g(x %s %s) = %s" % ("+" if s > 0 else M, t(abs(s)), Fp.text())),
                 fl("求 a + b + c：", "答：a + b + c = f(1) = [0]", [a(Fp(1))], "f(1) = g(%s)" % t(1 + s))])


# ---------- pr_powmod：整組代換 ----------

def pr_powmod(D, k, c, n):
    """(k·(x^2 + px) + c)^n 除以 x^2 + px + q；D = (p, q)"""
    p, q = D
    Dp = Poly([q, p, 1])
    inner = k * Poly([0, p, 1]) + c
    base = k * (-q) + c
    ans = base ** n
    assert (inner ** n) % Dp == Poly([ans])
    pa = Poly([0, p, 1]).text()
    return item("pr_powmod", "remain", 1, "整組代換", 1.0,
                "求 (%s)^{%d} 除以 %s 的餘式。" % (inner.text(), n, Dp.text()),
                [ch("除以 %s 時，%s 可以換成什麼？" % (Dp.text(), pa), uniq([t(-q)], [t(q), "0", "x", t(-q + 1)]),
                    "%s 除以自己餘 0" % Dp.text(), "除以 %s 時，%s 可以換成 %s" % (Dp.text(), pa, t(-q))),
                 ch("%s 可以換成？" % inner.text(), uniq([t(base)], [t(k * q + c), t(c), t(base + 1), t(base - 2)]),
                    "%s(%s) %s %s" % (t(k) if k != 1 else "", pa, "+" if c > 0 else M, t(abs(c))),
                    "%s = %s(%s) %s %s → %s(%s) %s %s = %s" % (inner.text(), t(k) if k != 1 else "", pa, "+" if c > 0 else M, t(abs(c)),
                                                            t(k) if k != 1 else "", t(-q), "+" if c > 0 else M, t(abs(c)), t(base))),
                 fl("餘式是？", "答：餘式 = %s^{%d} = [0]" % (tp(base), n), [a(ans)], "%s 連乘 %d 次" % (tp(base), n))])


def items():
    return [
        [pr_two(3, 5, -1, -3), pr_two(2, 7, -3, -8), pr_two(4, 1, 1, -5)],
        [pr_square((1, 1, 2, 0, 1, 3), -1), pr_square((2, -1, 1, 0, 3), -1), pr_square((1, 0, 0, -3, 0, 2), 1)],
        [pr_mod4(4, [(1, 50), (-2, 25), (3, 4)], 1), pr_mod4(3, [(1, 40), (3, 21), (-1, 3)], 2), pr_mod4(5, [(1, 30), (-1, 17), (2, 6)], 3)],
        [pr_back(2, -1, 2, 2, -1), pr_back(1, 1, 3, 3, 2), pr_back(-1, -2, 4, 1, -3)],
        [pr_nest((3, 1), -1, 2), pr_nest((2, -1), 3, -1), pr_nest((1, 2), -2, 5)],
        [pr_twosq(-1, 1, 1, -2, (1, 5)), pr_twosq(1, -1, 2, 1, (1, -3)), pr_twosq(2, 0, -1, 3, (2, 1))],
        [pr_near((2, -9, 7, 5), 3, 0.02), pr_near((1, -4, 2, 3), 2, 0.03), pr_near((3, 1, -5, 2), 1, 0.01)],
        [pr_basis(2, -1, 4, 2, 2, F(101, 2)), pr_basis(2, 1, -3, 5, 1, F(99, 2)), pr_basis(1, -3, 2, -1, 4, 103)],
        [pr_lagr((-2, 1, 3), 4, 10, 4), pr_lagr((-1, 2, 4), -3, 5, 5), pr_lagr((1, 3, -2), 2, -10, 2)],
        [pr_prime(23, 1), pr_prime(13, -1), pr_prime(17, 1)],
        [pr_hidden((1, -4, 1), 3, -1, (3, -2), (4, 5, 1)), pr_hidden((1, 2, -3), -2, 3, (2, 1), (2, 3, -1)), pr_hidden((2, -1, 1), 1, 0, (3, -1), (6, 7, 1))],
        [pr_powmod((-1, 1), 2, 9, 4), pr_powmod((1, 1), 2, 5, 3), pr_powmod((-3, 5), 1, 2, 4)],
    ]
