# 數線封印（高次不等式）
from plib import *


def _sol_text(marks, seg, pt):
    """把數線的 seg、pt 寫成解的文字"""
    ms = [t(m) for m in marks]
    parts = []
    n = len(marks)
    i = 0
    while i <= n:
        if seg[i]:
            j = i
            while j < n and seg[j + 1] and pt[j]:
                j += 1
            # 區間 i..j（第 i 段到第 j 段）
            lo = None if i == 0 else i - 1
            hi = None if j == n else j
            if lo is None and hi is None:
                parts.append("所有實數")
            elif lo is None:
                parts.append("x %s %s" % ("≤" if pt[hi] else "<", ms[hi]))
            elif hi is None:
                parts.append("x %s %s" % ("≥" if pt[lo] else ">", ms[lo]))
            else:
                parts.append("%s %s x %s %s" % (ms[lo], "≤" if pt[lo] else "<", "≤" if pt[hi] else "<", ms[hi]))
            i = j + 1
        else:
            i += 1
    # 孤立的點
    for k in range(n):
        if pt[k] and not seg[k] and not seg[k + 1]:
            parts.append("x = %s" % ms[k])
    return " 或 ".join(parts)


def _signs_text(marks, sg):
    ms = [t(m) for m in marks]
    out = []
    for i, s in enumerate(sg):
        if i == 0:
            rng = "x < %s" % ms[0]
        elif i == len(marks):
            rng = "x > %s" % ms[-1]
        else:
            rng = "%s < x < %s" % (ms[i - 1], ms[i])
        out.append("%s：%s" % (rng, "＋" if s > 0 else "−"))
    return "　".join(out)


# ---------- pl_sign：穿根 ----------

def pl_sign(rs, op):
    p = Poly.roots(rs)
    marks = sorted(rs)
    sg, seg, pt = solve_line(p, marks, op)
    facs = "".join(fac(r) for r in rs)
    return item("pl_sign", "line", 1, "穿根", 1.0, "解不等式 %s %s 0。" % (facs, op),
                [step("sign", q="標出 %s 在每一段的正負號。" % facs, row="正負", marks=[t(m) for m in marks], signs=sg,
                      hint="最右邊三個因式都是正的，往左每過一個根就變號一次", write=_signs_text(marks, sg)),
                 step("line", q="封印 %s 0 的部分（%s）。" % (op, "含等號" if op in ("≤", "≥") else "不含等號"), row="解",
                      marks=[t(m) for m in marks], seg=seg, pt=pt, write="答：" + _sol_text(marks, seg, pt))])


# ---------- pl_repeat：重根不變號 ----------

def pl_repeat(fs, op, hint, write1):
    """fs = [(根, 次方)]"""
    p = Poly([1])
    for r, m in fs:
        p = p * Poly.roots([r] * m)
    marks = sorted(r for r, m in fs)
    sg, seg, pt = solve_line(p, marks, op)
    if op in ("<", ">"):
        pt = [0] * len(marks)
    facs = "".join(facp(r, m) for r, m in fs)
    return item("pl_repeat", "line", 2, "重根不變號", 1.1, "解不等式 %s %s 0。" % (facs, op),
                [step("sign", q="標出每一段的正負號（偶次方的因式不變號）。", row="正負", marks=[t(m) for m in marks], signs=sg, hint=hint, write=write1),
                 step("line", q="封印 %s 0 的部分（注意每個根都讓左邊等於 0）。" % op, row="解", marks=[t(m) for m in marks], seg=seg, pt=pt,
                      write="答：" + _sol_text(marks, seg, pt))])


# ---------- pl_intsum：整數解的和 ----------

def pl_intsum(r1, r2, pos):
    """(−(x − r1)(x − r2))·(恆正的二次式) ≥ 0"""
    neg = -Poly.roots([r1, r2])
    P2 = Poly(list(reversed(pos)))
    assert P2.c[1] ** 2 - 4 * P2.c[2] * P2.c[0] < 0 and P2.lead() > 0
    ints = list(range(r1, r2 + 1))
    tot = sum(ints)
    return item("pl_intsum", "line", 2, "整數解的和", 1.15,
                "求滿足 (%s)(%s) ≥ 0 的所有整數 x 的和。" % (neg.text(), P2.text()),
                [ch("%s 的正負？" % P2.text(), ["恆正", "恆負", "有正有負", "恆為 0"],
                    "判別式 %s − %s < 0，首項係數 > 0" % (t(P2.c[1] ** 2), t(4 * P2.c[2] * P2.c[0])), "%s 恆正（判別式 < 0）" % P2.text()),
                 ch("所以不等式等價於？", ["%s ≤ 0" % (-neg).text(), "%s ≥ 0" % (-neg).text(), "%s ≤ 0" % neg.text(), "%s ≥ 0" % P2.text()],
                    "兩邊除以恆正的式子，再乘 −1 要變號", "%s ≥ 0　→　%s%s ≤ 0" % (neg.text(), fac(r2), fac(r1))),
                 step("line", q="封印 x 的範圍。", row="解", marks=[t(r1), t(r2)], seg=[0, 1, 0], pt=[1, 1], write="%s ≤ x ≤ %s" % (t(r1), t(r2))),
                 fl("範圍內所有整數的和？", "答：%s = [0]" % " + ".join((t(v) if i == 0 else tp(v)) for i, v in enumerate(ints)), [a(tot)], "正負相同的整數互相抵消")])


# ---------- pl_cube：立方差的陷阱 ----------

def pl_cube(c, d, op):
    """(c^3 − x^3)(x − c)(x + d) op 0"""
    q2 = Poly.roots([c, -d])
    cube = Poly([c ** 3, 0, 0, -1])
    sq = Poly([c * c, c, 1])
    flip = {"<": ">", ">": "<", "≤": "≥", "≥": "≤"}[op]
    core = Poly.roots([c, c, -d])
    marks = sorted([c, -d])
    sg, seg, pt = solve_line(core, marks, flip)
    if flip in ("<", ">"):
        pt = [0, 0]
    return item("pl_cube", "line", 2, "立方差的陷阱", 1.2, "解不等式 (%d − x^{3})(%s) %s 0。" % (c ** 3, q2.text(), op),
                [ch("%d − x^{3} 因式分解：" % (c ** 3), ["(%d − x)(%s)" % (c, sq.text()), "(%d − x)(%s)" % (c, Poly([c * c, -c, 1]).text()), "(%d − x)^{3}" % c,
                                                       "(%d + x)(%s)" % (c, Poly([c * c, -c, 1]).text())],
                    "a^{3} − b^{3} = (a − b)(a^{2} + ab + b^{2})", "%d − x^{3} = (%d − x)(%s)，%s 恆正" % (c ** 3, c, sq.text(), sq.text())),
                 ch("%s = %s%s。整理後不等式變成？" % (q2.text(), fac(-d), fac(c)),
                    ["%s^{2}%s %s 0" % (fac(c), fac(-d), flip), "%s^{2}%s %s 0" % (fac(c), fac(-d), op), "%s%s %s 0" % (fac(c), fac(-d), op), "%s%s %s 0" % (fac(c), fac(-d), flip)],
                    "(%d − x)%s = −%s^{2}，兩邊乘 −1 要變號" % (c, fac(c), fac(c)), "−%s^{2}%s %s 0　→　%s^{2}%s %s 0" % (fac(c), fac(-d), op, fac(c), fac(-d), flip)),
                 step("sign", q="標出 %s^{2}%s 的正負號。" % (fac(c), fac(-d)), row="正負", marks=[t(m) for m in marks], signs=sg,
                      hint="%s^{2} 不變號，只看 %s" % (fac(c), fac(-d).strip("()")), write=_signs_text(marks, sg)),
                 step("line", q="封印 %s 0 的部分。" % flip, row="解", marks=[t(m) for m in marks], seg=seg, pt=pt, write="答：" + _sol_text(marks, seg, pt))])


# ---------- pl_reverse：由解反推係數 ----------

def pl_reverse(r1, r2, C):
    """ax^2 + bx + C < 0 的解 x < r1 或 x > r2"""
    a_ = F(C, r1 * r2)
    b_ = -a_ * (r1 + r2)
    assert a_ < 0 and isint(a_) and isint(b_)
    Q = Poly([a_, b_, C])           # C x^2 + b x + a
    rr = sorted([F(1, r1), F(1, r2)])
    # 因式：C(x − 1/r1)(x − 1/r2) 寫成整數
    def fx(r):
        r = F(r)
        q_, p_ = r.denominator, r.numerator
        return "(%sx %s %d)" % ("" if q_ == 1 else str(q_), M if p_ > 0 else "+", abs(p_))
    k = F(C, F(rr[0]).denominator * F(rr[1]).denominator)
    good = "%s%s%s > 0" % ("" if k == 1 else t(k), fx(rr[0]), fx(rr[1]))
    bad = "%s%s%s > 0" % ("" if k == 1 else t(k), fx(-rr[0]), fx(-rr[1]))
    wrong2 = "%s%s%s > 0" % ("" if k == 1 else t(k), fx(rr[0]), fx(-rr[1]))
    marks = [t(rr[0]), t(rr[1])]
    return item("pl_reverse", "line", 2, "由解反推係數", 1.25,
                "不等式 ax^{2} + bx + %d < 0 的解為 x < %s 或 x > %s。再解 %dx^{2} + bx + a > 0。" % (C, t(r1), t(r2), C),
                [ch("解在兩根的外側，而且是 < 0。所以 a？", ["a < 0", "a > 0", "a = 0", "無法判斷"],
                    "開口向下，兩根外側的值才是負的", "a < 0，ax^{2} + bx + %d = a%s%s" % (C, fac(r1), fac(r2))),
                 fl("和 ax^{2} + bx + %d 比較係數：" % C, "%s = %d，b = %s　→　a = [0]，b = [1]" % (cx(r1 * r2, "a"), C, cx(-(r1 + r2), "a")), [a(a_), a(b_)],
                    "a = %d/%s" % (C, tp(r1 * r2)), pre="a%s%s = %s" % (fac(r1), fac(r2), poly([(1, "ax^{2}"), (-(r1 + r2), "ax"), (r1 * r2, "a")]))),
                 ch("%s > 0 因式分解：" % Q.text(), uniq([good], [bad, wrong2, "%s%s > 0" % (fx(rr[0]), fx(rr[1])), "%s%s > 0" % (fac(r1), fac(r2)), "%s%s%s > 0" % (t(C), fx(rr[0]), fx(-rr[1]))]),
                    "兩根是 %s、%s（原來兩根的倒數）" % (t(rr[0]), t(rr[1])), "%s = %s" % (Q.text(), good[:-4])),
                 step("line", q="封印解的範圍。", row="解", marks=marks, seg=[1, 0, 1], pt=[0, 0], write="答：x < %s 或 x > %s" % (marks[0], marks[1]))])


# ---------- pl_findk：讓解剛好是區間 ----------

def _check_findk(L, Qf, ks_ok, kr):
    for k in range(kr[0], kr[1] + 1):
        f = lambda x: x * (x - L) * (x - k) ** 2 * Qf(x, k)
        xs = [i / 20 for i in range(-200, 200)] + [k, L, 0]
        good = all((f(x) <= 1e-12) == (0 <= x <= L) for x in xs)
        assert good == (k in ks_ok), (L, k)


def pl_findk(L, Qs, Qf, ks, steps2, opts3, hint3, kr=(-6, 10)):
    _check_findk(L, Qf, ks, kr)
    ans = "、".join(str(k) for k in ks)
    lo, hi = 0, L
    return item("pl_findk", "line", 3, "讓解剛好是區間", 1.35,
                "k 是整數。已知 x(x − %d)(x − k)^{2}(%s) ≤ 0 的解為 0 ≤ x ≤ %d，求所有可能的 k。" % (L, Qs, L),
                [ch("x = k 時左邊是 0，一定是解。所以 k 必須？", ["0 ≤ k ≤ %d" % L, "k < 0", "k > %d" % L, "k 可以是任何整數"],
                    "解只有 0 ≤ x ≤ %d，x = k 不能跑到外面" % L, "x = k 是解　→　0 ≤ k ≤ %d" % L),
                 steps2,
                 ch("所有可能的 k？", uniq([ans], opts3), hint3, "答：k = " + ans.replace("、", " 或 "))])


def items():
    return [
        [pl_sign((1, -2, 3), "<"), pl_sign((-3, 1, 4), ">"), pl_sign((-2, 0, 5), "≥")],
        [pl_repeat([(-1, 2), (2, 3), (4, 1)], "≥", "(x + 1)^{2} ≥ 0 不影響正負，(x − 2)^{3} 和 x − 2 同號", "正負和 (x − 2)(x − 4) 一樣，只是 x = −1 也是 0"),
         pl_repeat([(3, 2), (-1, 3), (1, 1)], "<", "(x − 3)^{2} ≥ 0 不影響正負，(x + 1)^{3} 和 x + 1 同號", "正負和 (x + 1)(x − 1) 一樣，只是 x = 3 也是 0"),
         pl_repeat([(-2, 4), (0, 1), (3, 3)], "≤", "(x + 2)^{4} ≥ 0 不影響正負，(x − 3)^{3} 和 x − 3 同號", "正負和 x(x − 3) 一樣，只是 x = −2 也是 0")],
        [pl_intsum(-2, 4, (1, -2, 5)), pl_intsum(-2, 3, (1, 2, 3)), pl_intsum(-5, 3, (1, -4, 5))],
        [pl_cube(2, 3, ">"), pl_cube(3, 2, ">"), pl_cube(1, 3, "≥")],
        [pl_reverse(-1, 4, 8), pl_reverse(-2, 3, 6), pl_reverse(-1, 6, 6)],
        [pl_findk(3, "x^{2} + 2x + k", lambda x, k: x * x + 2 * x + k, [2, 3],
                  ch("x < 0 或 x > 3 時 x(x − 3) > 0。為了不多出解，x^{2} + 2x + k 需要？", ["恆正：判別式 4 − 4k < 0", "恆負：判別式 < 0", "有兩個相異實根", "x^{2} + 2x + k 不影響"],
                     "0 ≤ k ≤ 1 時 x^{2} + 2x + k 的根 −1 ± √{1 − k} 在 −2 和 0 之間，那裡會多出解", "x^{2} + 2x + k 恆正　→　4 − 4k < 0　→　k > 1"),
                  ["1、2、3", "0、1、2、3", "3"], "0 ≤ k ≤ 3 且 k > 1，k = 1 時 x^{2} + 2x + 1 = (x + 1)^{2}，x = −1 會多出一個解"),
         pl_findk(4, "x^{2} − 2x + k", lambda x, k: x * x - 2 * x + k, [1, 2, 3, 4],
                  ch("0 < x < 4 時 x(x − 4) < 0。為了解不缺一段，x^{2} − 2x + k 需要？", ["不能變負：判別式 4 − 4k ≤ 0", "恆負：判別式 < 0", "有兩個相異實根", "x^{2} − 2x + k 不影響"],
                     "x^{2} − 2x + k 的根 1 ± √{1 − k} 都在 0 和 4 之間，兩根中間它是負的，那一段就不是解了",
                     "x^{2} − 2x + k ≥ 0　→　4 − 4k ≤ 0　→　k ≥ 1"),
                  ["2、3、4", "0、1、2、3、4", "1"], "0 ≤ k ≤ 4 且 k ≥ 1。k = 1 時 x^{2} − 2x + 1 = (x − 1)^{2} ≥ 0，只在 x = 1 是 0，那裡本來就是解"),
         pl_findk(5, "x^{2} + 4x + k", lambda x, k: x * x + 4 * x + k, [5],
                  ch("x < 0 或 x > 5 時 x(x − 5) > 0。為了不多出解，x^{2} + 4x + k 需要？", ["恆正：判別式 16 − 4k < 0", "恆負：判別式 < 0", "有兩個相異實根", "x^{2} + 4x + k 不影響"],
                     "0 ≤ k ≤ 4 時 x^{2} + 4x + k 的根 −2 ± √{4 − k} 在 −4 和 0 之間，那裡會多出解", "x^{2} + 4x + k 恆正　→　16 − 4k < 0　→　k > 4"),
                  ["4、5", "0、1、2、3、4、5", "1、2、3、4、5"], "0 ≤ k ≤ 5 且 k > 4，只剩 k = 5。k = 4 時 (x + 2)^{2}，x = −2 會多出一個解")],
    ]
