# 倍增岩壁：指數律
from xlib import *


# ---------- xp_base：拆成兩個質數 ----------

def xp_base(p, q, num, den):
    """num、den = [(寫法, p 的指數, q 的指數, 數值)]"""
    np_ = sum(F(f[1]) for f in num)
    nq_ = sum(F(f[2]) for f in num)
    dp_ = sum(F(f[1]) for f in den)
    dq_ = sum(F(f[2]) for f in den)
    for f in num + den:
        assert near(f[3], p ** float(f[1]) * q ** float(f[2]))
    m, n = np_ - dp_, nq_ - dq_
    val = 1.0
    for f in num:
        val *= f[3]
    for f in den:
        val /= f[3]
    assert near(val, p ** float(m) * q ** float(n), 1e-6 * max(1, val))
    nt = " × ".join(f[0] for f in num)
    dt = " × ".join(f[0] for f in den)
    def parts(fs):
        return "，".join("%s = %d^{%s} × %d^{%s}" % (f[0], p, tf(f[1]), q, tf(f[2])) for f in fs)
    return item("xp_base", "pow", 2, "拆成兩個質數", 1.15,
                "\\frac{%s}{%s} = %d^{m} × %d^{n}，求 m、n。" % (nt, dt, p, q),
                [fl("分子每一個數都拆成 %d、%d 的次方，指數相加：" % (p, q), "分子 = %d^{[0]} × %d^{[1]}" % (p, q), [a(np_), a(nq_)], parts(num)),
                 fl("分母：", "分母 = %d^{[0]} × %d^{[1]}" % (p, q), [a(dp_), a(dq_)], parts(den)),
                 fl("相除，指數相減：", "m = [0]，n = [1]", [a(m), a(n)], "%s − %s、%s − %s" % (t(np_), tp(dp_), t(nq_), tp(dq_)))])


# ---------- xp_nest：根號套根號 ----------

def xp_nest(inner, ie, k, d1, d2, dk):
    """∛{a^{2}√{a^{3}}}：inner 是根號裡的寫法、ie 是它的指數、k 是外面的根；分母 (\\frac{a^{d1}}{a^{d2}})^{dk}"""
    ie, d1, d2 = F(ie), F(d1), F(d2)
    up = ie / k
    dd = (d1 - d2) * dk
    n = up - dd
    x = 1.7
    rt_ = "√" if k == 2 else {3: "∛", 4: "∜"}[k]
    numt = "%s{%s}" % (rt_, inner)
    assert near(eval_inner(inner, x) ** (1 / k), x ** float(up))
    dent = "(\\frac{a^{%s}}{a^{%s}})^{%d}" % (tf(d1), tf(d2), dk)
    return item("xp_nest", "pow", 1, "根號套根號", 1.05,
                "a > 0，\\frac{%s}{%s} = a^{n}，求 n。" % (numt, dent),
                [fl("分子由內往外寫成分數指數：", "%s = a^{[0]}，%s = a^{[1]}" % (inner, numt), [a(ie), a(up)],
                    "√{a^{m}} = a^{\\frac{m}{2}}，同底數相乘指數相加；外面的 %s 再除以 %d" % (rt_, k)),
                 fl("分母：", "%s = (a^{[0]})^{%d} = a^{[1]}" % (dent, dk), [a(d1 - d2), a(dd)], "相除指數相減，再乘 %d" % dk),
                 fl("分子除以分母：", "n = [0]", [a(n)], "%s − %s" % (t(up), tp(dd)))])


def eval_inner(s, x):
    """a^{2}√{a^{3}} 這種寫法代入 a = x"""
    import re
    m = re.match(r"a\^\{(\d+)\}(√|∛)\{a(?:\^\{(\d+)\})?\}", s)
    e1 = int(m.group(1))
    r = 2 if m.group(2) == "√" else 3
    e2 = int(m.group(3) or 1)
    return x ** e1 * (x ** e2) ** (1 / r)


# ---------- xp_target：反過來的次方 ----------

def xp_target(e, rhs, b, rhs_exp, tgt_t, tgt, tgt_exp):
    """a^{e} = rhs = b^{rhs_exp}；a^{x} = tgt = b^{tgt_exp}"""
    ae = F(rhs_exp, e)           # a = b^{ae}
    assert near(b ** float(rhs_exp), rhs) and near(b ** float(tgt_exp), tgt)
    x = F(tgt_exp) / ae
    av = b ** float(ae)
    assert near(av ** float(x), tgt)
    return item("xp_target", "pow", 1, "反過來的次方", 1.0,
                "a > 0，a^{%s} = %s。a 的幾次方等於 %s？" % (t(e), t(rhs), tgt_t),
                [fl("先把 a 寫成 %d 的次方：" % b, "a = %s^{%s} = %d^{[0]}" % (t(rhs), tf(F(1, e)), b), [a(ae)],
                    "%s = %d^{%s}，兩邊同時 %s 次方" % (t(rhs), b, t(rhs_exp), tf(F(1, e)))),
                 fl("目標也寫成 %d 的次方：" % b, "%s = %d^{[0]}" % (tgt_t, b), [a(tgt_exp)], ("分母 %d 寫成 %d 的次方" % (round(1 / tgt), b)) if tgt_t.startswith("\\frac") else ("%s = \\frac{1}{%d}，分母寫成 %d 的次方" % (tgt_t, round(1 / tgt), b))),
                 fl("比較指數：", "a^{x} = %d^{%s x} = %d^{%s}，x = [0]" % (b, tf(ae), b, tf(tgt_exp)), [a(x)], "%s x = %s" % (tf(ae), t(tgt_exp)))])


# ---------- xp_pair：兩個指數式找關係 ----------

def xp_pair(B1, k1, B2, k2, base, rel, r, ask, val):
    """B1^x = base^k1、B2^y = base^k2；rel = "div"：B2 = B1 × base^r；"mul"：B1 × B2 = base^r"""
    if rel == "div":
        assert near(B2 / B1, base ** r)
    else:
        assert near(B1 * B2, base ** r)
    x = k1 * math.log(base) / math.log(B1)
    y = k2 * math.log(base) / math.log(B2)
    assert near(ask[1](x, y), val)
    B1t, B2t = ("%g" % B1), ("%g" % B2)
    return item("xp_pair", "pow", 2, "兩個指數式找關係", 1.15,
                "%s^{x} = %d、%s^{y} = %d，求 %s。" % (B1t, base ** k1, B2t, base ** k2, ask[0]),
                [fl("兩邊同時開次方，把底數寫成 %d 的次方：" % base, "%s = %d^{\\frac{[0]}{x}}，%s = %d^{\\frac{[1]}{y}}" % (B1t, base, B2t, base), [str(k1), str(k2)],
                    "%d = %d^{%d}，%s = %d^{\\frac{%d}{x}}" % (base ** k1, base, k1, B1t, base, k1)),
                 ch("%s 和 %s 的關係？" % (B1t, B2t),
                    (["%s = %s × %d" % (B2t, B1t, base ** r), "%s = %s^{%d}" % (B2t, B1t, r + 1), "%s = %s + %d" % (B2t, B1t, base ** r), "%s = %d × %s^{2}" % (B2t, base, B1t)]
                     if rel == "div" else
                     ["%s × %s = %d" % (B1t, B2t, base ** r), "%s + %s = %d" % (B1t, B2t, base ** r), "%s = %s^{%d}" % (B1t, B2t, r), "%s × %s = 1" % (B1t, B2t)]),
                    "看看兩個底數相除、相乘是不是 %d 的次方" % base,
                    ("\\frac{%s}{%s} = %d　→　%d^{\\frac{%d}{y} − \\frac{%d}{x}} = %d^{%d}" % (B2t, B1t, base ** r, base, k2, k1, base, r)) if rel == "div" else
                    ("%s × %s = %d　→　%d^{\\frac{%d}{x} + \\frac{%d}{y}} = %d^{%d}" % (B1t, B2t, base ** r, base, k1, k2, base, r))),
                 fl("比較指數：", "%s = [0]" % ask[0], [a(val)], "同底數的次方相等，指數就相等")])


# ---------- xp_cosh：a + a^{−1} 的比值 ----------

def xp_cosh(b, s, kind):
    """b^x + b^{−x} = s；kind = "diff"：(b³ˣ − b⁻³ˣ)/(b²ˣ − b⁻²ˣ)；"sum"：(b³ˣ + b⁻³ˣ)/(b²ˣ + b⁻²ˣ)"""
    u = math.log((s + S(s * s - 4)) / 2) / math.log(b)       # x > 0
    B2, B3 = b * b, b ** 3
    sq = s * s - 2
    if kind == "diff":
        val = F(s * s - 1, s)
        num = B3 ** u - B3 ** -u
        den = B2 ** u - B2 ** -u
        assert near(num / den, float(val))
        return item("xp_cosh", "pow", 2, "倒數和的比值", 1.2,
                    "%d^{x} + %d^{−x} = %d，求 \\frac{%d^{x} − %d^{−x}}{%d^{x} − %d^{−x}}。" % (b, b, s, B3, B3, B2, B2),
                    [ch("令 t = %d^{x}。分子 t^{3} − t^{−3} 用立方差：" % b, ["(t − t^{−1})(t^{2} + 1 + t^{−2})", "(t − t^{−1})(t^{2} − 1 + t^{−2})", "(t − t^{−1})^{3}", "(t + t^{−1})(t^{2} − 1 + t^{−2})"],
                        "a^{3} − b^{3} = (a − b)(a^{2} + ab + b^{2})，t · t^{−1} = 1", "分子 = (t − t^{−1})(t^{2} + 1 + t^{−2})，分母 = (t − t^{−1})(t + t^{−1})"),
                     fl("先算 t^{2} + t^{−2}：", "%d^{x} + %d^{−x} = %d^{2} − 2 = [0]" % (B2, B2, s), [str(sq)], "(t + t^{−1})^{2} = t^{2} + 2 + t^{−2}"),
                     fl("約掉 t − t^{−1}（x ≠ 0）：", "原式 = \\frac{%d + 1}{%d} = [0]" % (sq, s), [a(val)], "\\frac{t^{2} + 1 + t^{−2}}{t + t^{−1}}")])
    val = F(s ** 3 - 3 * s, sq)
    num = B3 ** u + B3 ** -u
    den = B2 ** u + B2 ** -u
    assert near(num / den, float(val))
    return item("xp_cosh", "pow", 2, "倒數和的比值", 1.2,
                "%d^{x} + %d^{−x} = %d，求 \\frac{%d^{x} + %d^{−x}}{%d^{x} + %d^{−x}}。" % (b, b, s, B3, B3, B2, B2),
                [ch("令 t = %d^{x}。分子 t^{3} + t^{−3} 用哪個公式？" % b, ["(t + t^{−1})^{3} − 3(t + t^{−1})", "(t + t^{−1})^{3}", "(t + t^{−1})^{3} + 3(t + t^{−1})", "(t + t^{−1})^{3} − 3"],
                    "(a + b)^{3} = a^{3} + b^{3} + 3ab(a + b)，ab = t · t^{−1} = 1", "t^{3} + t^{−3} = (t + t^{−1})^{3} − 3(t + t^{−1})"),
                 fl("分子、分母分別算：", "分子 = %d^{3} − 3 × %d = [0]，分母 = %d^{2} − 2 = [1]" % (s, s, s), [str(s ** 3 - 3 * s), str(sq)], "分母：(t + t^{−1})^{2} − 2"),
                 fl("相除：", "原式 = [0]", [a(val)], "\\frac{%d}{%d} 約分" % (s ** 3 - 3 * s, sq))])


# ---------- xp_tower：一層層的根號 ----------

def xp_tower(b, k, layers):
    rt_ = "√" if k == 2 else "∛"
    s = "%s{%d}" % (rt_, b)
    for _ in range(layers - 1):
        s = "%s{%d%s}" % (rt_, b, s)
    e = F(0)
    for i in range(1, layers + 1):
        e += F(1, k ** i)
    v = 0.0
    for _ in range(layers):
        v = (b * v) ** (1 / k) if v else b ** (1 / k)
    assert near(v, b ** float(e))
    e1 = F(1, k)
    e2 = F(1, k) + F(1, k * k)
    terms = " + ".join("\\frac{1}{%d}" % (k ** i) for i in range(1, layers + 1))
    return item("xp_tower", "pow", 1, "一層層的根號", 1.0,
                "%s = %d^{x}，求 x。" % (s, b),
                [fl("最裡面那一層：", "%s{%d} = %d^{[0]}" % (rt_, b, b), [a(e1)], "開%s就是 \\frac{1}{%d} 次方" % ("平方" if k == 2 else "立方", k)),
                 fl("往外一層：", "%s{%d × %d^{%s}} = %d^{[0]}" % (rt_, b, b, tf(e1), b), [a(e2)], "(%d^{1 + %s})^{\\frac{1}{%d}}" % (b, tf(e1), k)),
                 fl("每往外一層，指數多一項：", "x = %s = [0]" % terms, [a(e)], "通分：分母都換成 %d" % (k ** layers))])


# ---------- xp_bracket：乘開是立方差 ----------

def xp_bracket(b, sign):
    """[(√b)^{1/3} ∓ (√b)^{−1/3}][(√{b²})^{1/3} + (√{b²})^{−1/3} ± 1]"""
    tt = b ** (1 / 6)
    if sign < 0:
        val = (tt - 1 / tt) * (tt * tt + 1 / (tt * tt) + 1)
        exact = Q(0, 1, b) - Q(0, 1, b) / b          # √b − 1/√b
        op1, op2, res, nm = "−", "+", "t^{3} − t^{−3}", "立方差"
    else:
        val = (tt + 1 / tt) * (tt * tt + 1 / (tt * tt) - 1)
        exact = Q(0, 1, b) + Q(0, 1, b) / b
        op1, op2, res, nm = "+", "−", "t^{3} + t^{−3}", "立方和"
    assert near(val, float(exact))
    stem = "[(√{%d})^{\\frac{1}{3}} %s (√{%d})^{−\\frac{1}{3}}][(√{%d})^{\\frac{1}{3}} + (√{%d})^{−\\frac{1}{3}} %s 1]" % (b, op1, b, b * b, b * b, op2)
    return item("xp_bracket", "pow", 2, "乘開是立方差", 1.15,
                "化簡 %s。" % stem,
                [fl("令 t = (√{%d})^{\\frac{1}{3}}：" % b, "t = %d^{[0]}，(√{%d})^{\\frac{1}{3}} = t^{[1]}" % (b, b * b), ["1/6", "2"], "√{%d} = %d^{\\frac{1}{2}}；√{%d} = %d = (√{%d})^{2}" % (b, b, b * b, b, b)),
                 ch("原式變成 (t %s t^{−1})(t^{2} + t^{−2} %s 1)，乘開是？" % (op1, op2), [res, "t^{3} − t^{−3}" if sign > 0 else "t^{3} + t^{−3}", "(t %s t^{−1})^{3}" % op1, "t^{3} %s 1" % op1],
                    "%s：t · t^{−1} = 1" % nm, "原式 = %s = (√{%d})^{\\frac{1}{3} × 3} %s (√{%d})^{−1}" % (res, b, op1, b)),
                 fl("化簡：", "√{%d} %s \\frac{1}{√{%d}} = [0]" % (b, op1, b), [exact.ans()], "\\frac{1}{√{%d}} = \\frac{√{%d}}{%d}" % (b, b, b))])


# ---------- xp_compare：同次方比大小 ----------

def xp_compare(trip, g):
    names = ["%d^{%d}" % (bb, e) for bb, e in trip]
    small = [bb ** (e // g) for bb, e in trip]
    for bb, e in trip:
        assert e % g == 0
    idx = sorted(range(3), key=lambda i: -small[i])
    s = lambda ix: " > ".join(names[i] for i in ix)
    opts = uniq([s(idx)], [s(idx[::-1]), s([idx[1], idx[0], idx[2]]), s([idx[0], idx[2], idx[1]])], 4)
    return item("xp_compare", "pow", 1, "同次方比大小", 1.0,
                "比較 %s 的大小。" % "、".join(names),
                [fl("指數的最大公因數是 %d，都寫成 (…)^{%d}：" % (g, g), "%s = ([0])^{%d}，%s = ([1])^{%d}，%s = ([2])^{%d}" % (names[0], g, names[1], g, names[2], g),
                    [str(v) for v in small], "%s = (%d^{%d})^{%d}" % (names[0], trip[0][0], trip[0][1] // g, g)),
                 ch("由大到小：", opts, "次方一樣，比括號裡的數", opts[0])])


def items():
    S2 = S(2)
    S3 = S(3)
    S5 = S(5)
    return [
        [xp_base(2, 3, [("∛{729}", 0, 2, 9.0), ("(\\frac{1}{6})^{−5}", 5, 5, 6.0 ** 5), ("36^{\\frac{1}{3}}", F(2, 3), F(2, 3), 36 ** (1 / 3))], [("72^{3}", 9, 6, 72.0 ** 3)]),
         xp_base(2, 5, [("∛{125}", 0, 1, 5.0), ("10^{4}", 4, 4, 1e4), ("16^{\\frac{3}{4}}", 3, 0, 8.0)], [("(\\frac{1}{20})^{−3}", 6, 3, 8000.0)]),
         xp_base(2, 3, [("√{\\frac{1}{8}}", F(-3, 2), 0, S(1 / 8)), ("54^{\\frac{1}{3}}", F(1, 3), 1, 54 ** (1 / 3)), ("12^{2}", 4, 2, 144.0)], [("∜{9}", 0, F(1, 2), 9 ** 0.25)])],
        [xp_nest("a^{2}√{a^{3}}", F(7, 2), 3, F(3, 2), F(4, 3), 2), xp_nest("a^{3}∛{a^{2}}", F(11, 3), 2, F(5, 4), F(1, 2), 2),
         xp_nest("a^{3}√{a}", F(7, 2), 4, F(2, 3), F(1, 4), 3)],
        [xp_target(-3, 4, 2, 2, "0.125", 0.125, -3), xp_target(-4, 9, 3, 2, "\\frac{1}{27}", 1 / 27, -3), xp_target(3, 25, 5, 2, "0.2", 0.2, -1)],
        [xp_pair(31, 2, 93, 3, 3, "div", 1, ("\\frac{3}{y} − \\frac{2}{x}", lambda x, y: 3 / y - 2 / x), 1),
         xp_pair(12, 4, 48, 6, 2, "div", 2, ("\\frac{6}{y} − \\frac{4}{x}", lambda x, y: 6 / y - 4 / x), 2),
         xp_pair(20, 3, 0.2, 4, 2, "mul", 2, ("\\frac{3}{x} + \\frac{4}{y}", lambda x, y: 3 / x + 4 / y), 2)],
        [xp_cosh(3, 7, "diff"), xp_cosh(2, 5, "diff"), xp_cosh(2, 4, "sum")],
        [xp_tower(3, 2, 5), xp_tower(5, 2, 4), xp_tower(2, 3, 3)],
        [xp_bracket(3, -1), xp_bracket(2, -1), xp_bracket(5, 1)],
        [xp_compare([(3, 50), (5, 40), (7, 30)], 10), xp_compare([(2, 60), (3, 40), (5, 20)], 20), xp_compare([(2, 48), (3, 36), (6, 24)], 12)],
        [_irr(2, "4", 2, "3 + √{2}", 3, "3 − 2√{2}", 6, F(3, 2), "2√2"),
         _irr(3, "9", 2, "1 + √{3}", 3, "4 − 2√{3}", 6, F(1), "3"),
         _irr(5, "25", 2, "2 + √{5}", 3, "5 − 2√{5}", 6, F(3, 2), "5√5")],
    ]


def _irr(b, B, k, e1, r1, e2, r2, tot, ans):
    """∛{√{B^{e1}}} × (b^{e2})^{1/r2}，B = b^k"""
    import re
    def ev(s):
        m = re.match(r"(\d+) ([+−]) (\d*)√\{(\d+)\}", s)
        return int(m.group(1)) + (1 if m.group(2) == "+" else -1) * int(m.group(3) or 1) * S(int(m.group(4)))
    x1, x2 = ev(e1), ev(e2)
    v = ((int(B) ** x1) ** 0.5) ** (1 / r1) * (b ** x2) ** (1 / r2)
    assert near(v, b ** float(tot), 1e-6) and near(num(ans), b ** float(tot), 1e-6)
    assert near(k * x1 / 2 / r1 + x2 / r2, float(tot))
    stem = "%s{√{%s^{%s}}} × (%d^{%s})^{\\frac{1}{%d}}" % ("∛" if r1 == 3 else "√", B, e1, b, e2, r2)
    # 第一項的指數 = k(e1)/(2 r1)
    c1 = F(k, 2 * r1)
    return item("xp_irr", "pow", 2, "無理數次方", 1.2, "化簡 %s。" % stem,
                [fl("第一項換成 %d 的次方：" % b, "%s^{%s} = %d^{%d(%s)}，開平方再開立方：%d^{\\frac{%s}{[0]}}" % (B, e1, b, k, e1, b, e1), [a(1 / c1)],
                    "%s = %d^{%d}；開平方指數 × \\frac{1}{2}，開立方再 × \\frac{1}{3}" % (B, b, k)),
                 fl("第二項：", "(%d^{%s})^{\\frac{1}{%d}} = %d^{\\frac{%s}{[0]}}" % (b, e2, r2, b, e2), [str(r2)], "次方的次方，指數相乘"),
                 fl("指數相加，√ 會消掉：", "\\frac{%s}{%s} + \\frac{%s}{%d} = [0]，原式 = [1]" % (e1, t(1 / c1), e2, r2), [a(tot), ans],
                    "通分成分母 %d 再相加" % r2)])
