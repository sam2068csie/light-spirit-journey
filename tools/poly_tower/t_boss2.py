# 試煉大題（新增的 6 題）：pb_threerem、pb_ineqk、pb_cubicroot 難度 2；pb_maxbox、pb_remsys、pb_paramroots 難度 3
from plib import *


def sg(v):
    return ("+ " + t(v)) if v >= 0 else (M + " " + t(-v))


def dv(r):
    return fac(r).strip("()") if r != 0 else "x"


# ---------- pb_threerem：三個餘式 ----------

def pb_threerem(p, R, tt):
    Rp = Poly(list(reversed(R)))
    ps = [p, p + 1, p + 2]
    vs = [Rp(x) for x in ps]
    a_, b_, c_ = Rp.c[2], Rp.c[1], Rp.c[0]
    d1, d2 = vs[1] - vs[0], vs[2] - vs[1]
    D3 = Poly.roots(ps)
    f = D3 + Rp
    facs = "".join(fac(x) for x in ps)
    return item("pb_threerem", "boss", 2, "三個餘式", 1.6,
                "f(x) 除以 %s 的餘式依序是 %s。\n(1) 求 f(x) 除以 %s 的餘式　(2) 若 f(x) 是首項係數 1 的三次式，求 f(%d)" % (
                    "、".join(dv(x) for x in ps), "、".join(t(v) for v in vs), facs, tt),
                [ch("除式是三次式，餘式 R(x) 怎麼假設？", ["ax^{2} + bx + c", "ax + b", "ax^{3} + bx^{2} + cx + d", "a"],
                    "餘式的次數比除式低：最多二次", "(1)　f(x) = %sQ(x) + ax^{2} + bx + c" % facs, part="(1)"),
                 fl("R(%d)、R(%d)、R(%d) 就是三個餘式。相鄰的兩個相減，c 消掉：" % tuple(ps),
                    "R(%d) − R(%d) = %s = [0]，R(%d) − R(%d) = %s = [1]" % (ps[1], ps[0], poly([(2 * p + 1, "a"), (1, "b")]), ps[2], ps[1], poly([(2 * p + 3, "a"), (1, "b")])),
                    [a(d1), a(d2)], "%s − %s、%s − %s" % (t(vs[1]), tp(vs[0]), t(vs[2]), tp(vs[1])), part="(1)"),
                 fl("兩式再相減：2a = %s。" % t(d2 - d1), "a = [0]，b = [1]，c = [2]", [a(a_), a(b_), a(c_)],
                    "a 代回求 b，再用 R(%d) = %s 求 c" % (ps[0], t(vs[0])), write="(1)　餘式 %s" % Rp.text(), part="(1)"),
                 ch("記 D(x) = %s、R(x) = %s。f(x) 是首項係數 1 的三次式，所以 f(x) = ？" % (facs, Rp.text()), ["D(x) + R(x)", "D(x) · R(x)", "x^{3} + R(x)", "D(x) − R(x)"],
                    "商式是常數，首項係數 1 ⇒ 商式就是 1", "(2)　f(x) = %s + (%s)" % (facs, Rp.text()), part="(2)"),
                 fl("求 f(%d)：" % tt, "答：f(%d) = %s + %s = [0]" % (tt, " · ".join(tp(tt - x) for x in ps), tp(Rp(tt))), [a(f(tt))], "先乘再加", part="(2)")])


# ---------- pb_ineqk：整數解恰有幾個 ----------

def _cnt(p, k, op):
    lo, hi = sorted([F(p), F(k)])
    n = 0
    for x in range(-40, 41):
        v = (x - p) * (x - k)
        if (v < 0) if op == "<" else (v <= 0):
            n += 1
    return n


def pb_ineqk(p, op, N):
    if op == "<":
        A = (p + N, p + N + 1, "<", "≤")
        B = (p - N - 1, p - N, "≤", "<")
        k0 = "沒有解"
        k0_ok = _cnt(p, p, op) == N
    else:
        A = (p + N - 1, p + N, "≤", "<")
        B = (p - N, p - N + 1, "<", "≤")
        k0 = "只有 x = %d" % p
        k0_ok = _cnt(p, p, op) == N
    assert not k0_ok
    # 檢查：k 掃過去，恰 N 個的 k 就是 A、B 兩段
    for i in range(-1200, 1201):
        k = F(i, 100)
        inA = (k > A[0] if A[2] == "<" else k >= A[0]) and (k < A[1] if A[3] == "<" else k <= A[1])
        inB = (k > B[0] if B[2] == "<" else k >= B[0]) and (k < B[1] if B[3] == "<" else k <= B[1])
        assert (_cnt(p, k, op) == N) == (inA or inB), (p, op, N, k)
    ia = list(range(p + 1, p + N + 1)) if op == "<" else list(range(p, p + N))
    ib = list(range(p - N, p)) if op == "<" else list(range(p - N + 1, p + 1))
    rng = lambda r: "%s %s k %s %s" % (t(r[0]), r[2], r[3], t(r[1]))
    ans = "%s 或 %s" % (rng(B), rng(A))
    sol = "%s %s x %s k" % (t(p), "<" if op == "<" else "≤", "<" if op == "<" else "≤")
    solB = "k %s x %s %s" % ("<" if op == "<" else "≤", "<" if op == "<" else "≤", t(p))
    return item("pb_ineqk", "boss", 2, "整數解恰有幾個", 1.6,
                "k 是實數。不等式 %s(x − k) %s 0 的整數解恰有 %d 個，求 k 的範圍。" % (fac(p), op, N),
                [ch("兩根是 %d 和 k。k = %d 時，不等式的解是？" % (p, p), uniq([k0], ["沒有解", "只有 x = %d" % p, "所有實數", "x ≠ %d" % p]),
                    "%s^{2} %s 0" % (fac(p), op), "k = %d：%s，不合" % (p, k0)),
                 ch("k > %d 時解是 %s，要恰好包含哪些整數？" % (p, sol), uniq(["、".join(str(v) for v in ia)],
                                                                   ["、".join(str(v) for v in range(p, p + N + 1)), "、".join(str(v) for v in range(p + 1, p + N)), "、".join(str(v) for v in range(p + 2, p + N + 2))]),
                    "從 %d %s開始往右數 %d 個整數" % (p, "的下一個" if op == "<" else "自己", N), "k > %d：整數解是 %s" % (p, "、".join(str(v) for v in ia)), col="A"),
                 fl("下一個整數 %d 不能是解：" % (ia[-1] + 1), "[0] %s k %s [1]" % (A[2], A[3]), [a(A[0]), a(A[1])],
                    "k %s %d 才包含 %d，k %s %d 才不包含 %d" % (">" if op == "<" else "≥", ia[-1], ia[-1], "≤" if op == "<" else "<", ia[-1] + 1, ia[-1] + 1), col="A"),
                 ch("k < %d 時解是 %s，要恰好包含哪些整數？" % (p, solB), uniq(["、".join(str(v) for v in ib)],
                                                                    ["、".join(str(v) for v in range(p - N, p + 1)), "、".join(str(v) for v in range(p - N + 1, p)), "、".join(str(v) for v in range(p - N - 1, p - 1))]),
                    "從 %d %s開始往左數 %d 個整數" % (p, "的前一個" if op == "<" else "自己", N), "k < %d：整數解是 %s" % (p, "、".join(str(v) for v in ib)), col="B"),
                 fl("再前一個整數 %d 不能是解：" % (ib[0] - 1), "[0] %s k %s [1]" % (B[2], B[3]), [a(B[0]), a(B[1])],
                    "k %s %d 才包含 %d，k %s %d 才不包含 %d" % ("<" if op == "<" else "≤", ib[0], ib[0], "≥" if op == "<" else ">", ib[0] - 1, ib[0] - 1), col="B"),
                 ch("兩條路線合起來：", uniq([ans], [rng(A), rng(B), "%s %s k %s %s" % (t(B[0]), B[2], A[3], t(A[1]))]),
                    "k = %d 不合，兩邊的範圍都要" % p, "答：" + ans)],
                routes={"A": "k > %d" % p, "B": "k < %d" % p})


# ---------- pb_cubicroot：有理根 ----------

def pb_cubicroot(lead, ri, rf, rj, op, rng):
    """f = lead(x − ri)(x − rf)(x − rj)，ri 是唯一的正整數根"""
    f = Poly.roots([ri, rf, rj], lead)
    assert all(isint(c) for c in f.c)
    pos_int = [r for r in (ri, rf, rj) if isint(r) and r > 0]
    assert pos_int == [ri]
    q_, r_ = f.divmod(Poly([-ri, 1]))
    assert r_ == Poly([0])
    lead_c, const_c = f.c[3], f.c[0]
    rr = F(rf)
    fx = "(%sx %s %d)" % ("" if rr.denominator == 1 else str(rr.denominator), M if rr.numerator > 0 else "+", abs(rr.numerator))
    full = "%s%s%s" % (fac(ri), fx, fac(rj))
    marks = sorted([F(ri), rr, F(rj)])
    sgns, seg, pt = solve_line(f, marks, op)
    ints = [x for x in range(rng[0], rng[1] + 1) if (f(x) < 0 if op == "<" else f(x) <= 0)]
    wrong_q = [(q_ + Poly([0, 1])).text(), (q_ - 2).text(), Poly([q_.c[0], -q_.c[1], q_.c[2]]).text()]
    wrong_f = ["%s(%sx %s %d)%s" % (fac(-ri), "" if rr.denominator == 1 else str(rr.denominator), "+" if rr.numerator > 0 else M, abs(rr.numerator), fac(-rj)),
               "%s%s%s" % (fac(ri), fx, fac(-rj)), "%s(%sx %s %d)%s" % (fac(ri), "" if rr.denominator == 1 else str(rr.denominator), "+" if rr.numerator > 0 else M, abs(rr.numerator), fac(rj))]
    from t_line import _sol_text, _signs_text
    return item("pb_cubicroot", "boss", 2, "有理根", 1.6,
                "f(x) = %s。\n(1) 把 f(x) 因式分解　(2) 解 f(x) %s 0　(3) %d ≤ x ≤ %d 裡，滿足 f(x) %s 0 的整數有幾個？" % (f.text(), op, rng[0], rng[1], op),
                [ch("整係數多項式的有理根 p/q（最簡分數）：", ["p 整除 %s、q 整除 %s" % (t(abs(const_c)), t(abs(lead_c))), "p 整除 %s、q 整除 %s" % (t(abs(lead_c)), t(abs(const_c))),
                                                    "p、q 都整除 %s" % t(abs(const_c)), "只能是整數"],
                    "分子看常數項、分母看首項係數", "(1)　有理根 p/q：p 整除常數項 %s，q 整除首項係數 %s" % (t(const_c), t(lead_c)), part="(1)"),
                 fl("從小的正整數試起：f(1)、f(2)、f(3)…第一個等於 0 的是？", "x = [0]", [a(ri)], "代進去算，等於 0 就是根", part="(1)"),
                 ch("用 %s 做綜合除法，商式是？" % dv(ri), uniq([q_.text()], wrong_q), "係數 %s，除以 %s" % ("、".join(t(c) for c in reversed(f.c)), dv(ri)),
                    "f(x) = %s(%s)" % (fac(ri), q_.text()), part="(1)"),
                 ch("再分解商式，f(x) = ？", uniq([full], wrong_f), "%s 用十字交乘" % q_.text(), "(1)　f(x) = " + full, part="(1)"),
                 step("sign", part="(2)", q="標出 f(x) 在每一段的正負號。", row="正負", marks=[t(m) for m in marks], signs=sgns,
                      hint="首項係數是正的：最右邊是＋，往左每過一個根就變號一次", write=_signs_text(marks, sgns)),
                 step("line", part="(2)", q="封印 f(x) %s 0 的部分。" % op, row="解", marks=[t(m) for m in marks], seg=seg, pt=pt, write="(2)　" + _sol_text(marks, seg, pt)),
                 fl("%d ≤ x ≤ %d 裡的整數解：" % rng, "(3)　共 [0] 個", [len(ints)], "一個一個數：%s" % "、".join(str(v) for v in ints), part="(3)")])


# ---------- pb_maxbox：拋物線裡的菜園 ----------

def pb_maxbox(H, w, T):
    """y = H − x^2/w；周長 P(t) = 4t + 2(H − t^2/w)"""
    Pt = Poly([2 * H, 4, F(-2, w)])
    tv = F(w)
    Pmax = Pt(tv)
    assert T > tv and T * T < w * H
    PT = Pt(F(T))
    ys = "%d − x^{2}" % H if w == 1 else "%d − \\frac{x^{2}}{%d}" % (H, w)
    hy = "%d − t^{2}" % H if w == 1 else "%d − \\frac{t^{2}}{%d}" % (H, w)
    return item("pb_maxbox", "boss", 3, "拋物線裡的菜園", 1.65,
                "拋物線 y = %s 和 x 軸圍成一塊地。要在裡面圍一個長方形菜園：一邊在 x 軸上，上面兩個角在拋物線上。\n(1) 菜園周長的最大值　(2) 如果菜園的寬（x 軸上那一邊）至少 %d，周長的最大值" % (ys, 2 * T),
                [ch("設右上角是 (t, %s)，t > 0。周長 P(t) = ？" % hy, uniq(["4t + 2(%s)" % hy], ["2t + 2(%s)" % hy, "4t + (%s)" % hy, "2t(%s)" % hy]),
                    "寬是 2t、高是 %s，周長 = 2 × 寬 + 2 × 高" % hy, "(1)　P(t) = 4t + 2(%s) = %s" % (hy, Pt.text("t")), part="(1)"),
                 fl("配方找頂點：", "頂點 t = [0]，周長最大 [1]", [a(tv), a(Pmax)], "%s 的頂點 t = −4/(2 × %s)" % (Pt.text("t"), tp(Pt.c[2])),
                    write="(1)　t = %s 時周長最大 %s" % (t(tv), t(Pmax)), part="(1)"),
                 ch("寬至少 %d ⇒ t ≥ %d。頂點 t = %s 在範圍裡嗎？" % (2 * T, T, t(tv)),
                    ["不在：t = %d 時最大" % T, "在：最大值還是 %s" % t(Pmax), "不在：t 越大越大", "不在：沒有最大值"],
                    "開口向下，頂點右邊是遞減的", "(2)　t ≥ %d 在頂點右邊，遞減：t = %d 時最大" % (T, T), part="(2)"),
                 fl("算 P(%d)：" % T, "(2)　周長最大 = [0]", [a(PT)], "代 t = %d 進 %s" % (T, Pt.text("t")), part="(2)")])


# ---------- pb_remsys：重根除式和一次除式 ----------

def pb_remsys(p, r1, q, gam, tt):
    R1 = Poly(list(reversed(r1)))
    a_ = F(gam - R1(q), (q - p) ** 2)
    assert isint(a_) and a_ != 0
    R = a_ * Poly.roots([p, p]) + R1
    f = Poly.roots([p, p, q]) + R
    xp, xq = fac(p), fac(q)
    return item("pb_remsys", "boss", 3, "重根除式和一次除式", 1.65,
                "f(x) 除以 %s^{2} 的餘式為 %s，除以 %s 的餘式為 %s。\n(1) 求 f(x) 除以 %s^{2}%s 的餘式　(2) 求 f(x) 除以 %s 的餘式　(3) 若 f(x) 是首項係數 1 的三次式，求 f(%d)" % (
                    xp, R1.text(), dv(q), t(gam), xp, xq, dv(p), tt),
                [ch("餘式 R(x) 最多二次。R(x) 除以 %s^{2} 的餘式也要是 %s，所以 R(x) = ？" % (xp, R1.text()),
                    ["a%s^{2}%s" % (xp, addp(R1.text())), "a%s%s%s" % (xp, xq, addp(R1.text())), "a%s^{2}%s" % (xq, addp(R1.text())), "%s + a" % R1.text()],
                    "f(x) = %s^{2}%sQ(x) + R(x)：前一項是 %s^{2} 的倍式" % (xp, xq, xp), "(1)　R(x) = a%s^{2}%s" % (xp, addp(R1.text())), part="(1)"),
                 fl("代 x = %d：f(%d) = R(%d) = %s。" % (q, q, q, t(gam)), "a · %s + %s = %s ⇒ a = [0]" % (t((q - p) ** 2), tp(R1(q)), t(gam)), [a(a_)],
                    "%sa = %s − %s" % (t((q - p) ** 2), t(gam), tp(R1(q))), part="(1)"),
                 ch("展開 R(x)：", uniq([R.text()], [(R1 - a_ * Poly.roots([p, p])).text(), (a_ * Poly.roots([q, q]) + R1).text(), (a_ * Poly.roots([p, p])).text()]),
                    "%s%s^{2}%s" % (t(a_) if a_ not in (1, -1) else ("" if a_ == 1 else M), xp, addp(R1.text())), "(1)　R(x) = %s" % R.text(), part="(1)"),
                 fl("f(x) 除以 %s 的餘式 = f(%d) = R(%d)：" % (dv(p), p, p), "(2)　餘式 = [0]", [a(R1(p))], "R(%d) = %s" % (p, t(R(p))), part="(2)"),
                 fl("f(x) = %s^{2}%s + R(x)（首項係數 1，商式是 1）：" % (xp, xq), "(3)　f(%d) = %s + %s = [0]" % (tt, t((tt - p) ** 2 * (tt - q)), tp(R(tt))), [a(f(tt))],
                    "%s^{2} × %s" % (tp(tt - p), tp(tt - q)), part="(3)")])


# ---------- pb_paramroots：兩根都大於 t ----------

def pb_paramroots(al, be, t0):
    """x^2 − 2mx + (αm + β) = 0 兩相異實根都大於 t0"""
    D = Poly([-be, -al, 1])        # m^2 − αm − β
    rd = sorted(F(r).limit_denominator(100) for r in D.real_roots())
    assert all(D(r) == 0 for r in rd)
    cf = al - 2 * t0               # f(t0) = t0^2 + (α − 2t0)m + β
    c0 = t0 * t0 + be
    mf = F(-c0, cf)
    def ok(m):
        disc = m * m - al * m - be
        if disc <= 0:
            return False
        r = math.sqrt(disc)
        return m - r > t0
    def cond(m):
        return D(m) > 0 and m > t0 and (cf * m + c0) > 0
    marks = sorted(set([rd[0], rd[1], F(t0), mf]))
    tests = [marks[0] - 1] + [(marks[i] + marks[i + 1]) / 2 for i in range(len(marks) - 1)] + [marks[-1] + 1]
    seg = [1 if cond(x) else 0 for x in tests]
    for i in range(-800, 801):
        m = F(i, 37)
        assert ok(float(m)) == cond(m), m
    from t_line import _sol_text
    ans = _sol_text(marks, seg, [0] * len(marks)).replace("x", "m")
    feq = poly([(t0 * t0, ""), (-2 * t0, "m"), (al, "m"), (be, "")])
    fsimp = poly([(cf, "m"), (c0, "")])
    rel = ">" if cf > 0 else "<"
    eqn = "x^{2} − 2mx + (%s) = 0" % poly([(al, "m"), (be, "")])
    return item("pb_paramroots", "boss", 3, "兩根都在右邊", 1.65,
                "方程式 %s 的兩個相異實根都大於 %s。求 m 的範圍。" % (eqn, t(t0)),
                [ch("令 f(x) = x^{2} − 2mx + (%s)。兩個相異實根都大於 %s，要哪三個條件？（D 是判別式，對稱軸是 x = m）" % (poly([(al, "m"), (be, "")]), t(t0)),
                    ["D > 0、m > %s、f(%s) > 0" % (t(t0), t(t0)), "D > 0、f(%s) > 0" % t(t0), "D ≥ 0、m > %s" % t(t0), "f(%s) < 0" % t(t0)],
                    "兩根都在 %s 右邊：開口向上的拋物線，頂點在 %s 右邊、在 x = %s 時是正的、和 x 軸交兩點" % (t(t0), t(t0), t(t0)),
                    "判別式 > 0、對稱軸 m > %s、f(%s) > 0" % (t(t0), t(t0))),
                 fl("判別式 > 0：\\frac{判別式}{4} = %s > 0。" % D.text("m"), "m < [0] 或 m > [1]", [a(rd[0]), a(rd[1])], "%s 因式分解" % D.text("m")),
                 fl(("f(%s) = %s = %s > 0：" % (t(t0), feq, fsimp)) if feq != fsimp else ("f(%s) = %s > 0：" % (t(t0), fsimp)), "m %s [0]" % rel, [a(mf)], "移項%s" % ("，除以負數要變號" if cf < 0 else "")),
                 step("line", q="三個條件（m > %s、判別式、f(%s)）一起成立的部分封印起來。" % (t(t0), t(t0)), row="m", marks=[t(x) for x in marks], seg=seg, pt=[0] * len(marks),
                      write="答：" + ans)])


def items():
    return [
        [pb_threerem(1, (1, -2, 3), 4), pb_threerem(-1, (2, 1, -1), 2), pb_threerem(0, (-1, 4, 1), 3)],
        [pb_ineqk(2, "<", 3), pb_ineqk(-1, "<", 2), pb_ineqk(-1, "≤", 4)],
        [pb_cubicroot(2, 3, F(1, 2), -2, "<", (-5, 5)), pb_cubicroot(3, 1, F(2, 3), -3, "≤", (-5, 5)), pb_cubicroot(2, 2, F(1, 2), -3, "≤", (-5, 5))],
        [pb_maxbox(12, 1, 2), pb_maxbox(10, 2, 3), pb_maxbox(6, 3, 4)],
        [pb_remsys(1, (2, 1), -2, 6, 2), pb_remsys(-1, (1, -3), 1, 6, 0), pb_remsys(2, (-1, 4), 0, 0, 1)],
        [pb_paramroots(1, 6, 1), pb_paramroots(3, -2, 0), pb_paramroots(1, 2, -1)],
    ]
