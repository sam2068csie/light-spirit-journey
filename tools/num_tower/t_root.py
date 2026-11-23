# 根號磨坊：根號、雙重根號、整數與小數部分
from nlib import *

S = math.sqrt


# ---------- nr_peel：剝一層 ----------

def nr_peel(p, sg, inner, inner_q, coef_txt, big, small):
    """√{p ± inner}，inner = 2√{inner_q}（coef_txt 是題目裡 inner 的寫法）"""
    assert big + small == p and big * small == inner_q and big > small
    v = S(big) + (1 if sg > 0 else -1) * S(small)
    assert near(v, S(p + (1 if sg > 0 else -1) * 2 * S(inner_q)))
    op = "+" if sg > 0 else "−"
    stem = "√{%d %s %s}" % (p, op, coef_txt)
    return item("nr_peel", "root", 1, "剝一層", 1.0,
                "化簡 %s。" % stem,
                [fl("先把根號裡的根號寫成 2√{…}：", "%s = 2√{[0]}" % inner, [str(inner_q)],
                    "%s" % ("√{%d} = √{4 × %d}" % (4 * inner_q, inner_q) if inner.startswith("√") else "%s = 2 × √{%d}" % (inner, inner_q))),
                 fl("找兩個數，和是 %d、積是 %d：" % (p, inner_q), "大的 [0]、小的 [1]", [str(big), str(small)], "列出積是 %d 的兩數，看哪一組加起來是 %d" % (inner_q, p)),
                 fl("寫出答案（大的放前面）：", "%s = [0] %s [1]" % (stem, op), [rta(big), rta(small)],
                    "√{%d %s 2√{%d}} = √{%d} %s √{%d}，再化簡" % (p, op, inner_q, big, op, small))])


# ---------- nr_intfrac：小數部分代入 ----------

def nr_intfrac(c, s, n, k):
    """c + s√n 的小數部分 b，求 b^2 + kb"""
    v = Q(c, s, n)
    I = math.floor(float(v))
    b = v - I
    lo = math.floor(S(n))
    assert 0 < float(b) < 1
    val = b * (b + k)
    assert val.rat()
    numt = "%d %s √{%d}" % (c, "+" if s > 0 else "−", n)
    wrong = [b + 1, b - 1, -b, Q(c - I, -s, n) + (2 * lo if s > 0 else -2 * lo)]
    expr = poly([(1, "b^{2}"), (k, "b")])
    return item("nr_intfrac", "root", 1, "小數部分代入", 1.0,
                "%s 的小數部分是 b，求 %s 的值。" % (numt, expr),
                [fl("先估 √{%d}：" % n, "[0] < √{%d} < [1]，%s 的整數部分是 [2]" % (n, numt), [str(lo), str(lo + 1), str(I)],
                    "%d^{2} = %d、%d^{2} = %d%s" % (lo, lo * lo, lo + 1, (lo + 1) ** 2, "；前面是減號，大小要反過來" if s < 0 else "")),
                 ch("小數部分 b = ？", uniq([sf(b)], [sf(w) for w in wrong if 0 != w], 4),
                    "小數部分 = 原數 − 整數部分", "b = %s − %d = %s" % (numt, I, sf(b))),
                 fl("提出 b 再代入：", "%s = b(%s) = [0]" % (expr, poly([(1, "b"), (k, "")])), [a(val.a)],
                    "b(%s) = (%s)(%s)，用平方差" % (poly([(1, "b"), (k, "")]), sf(b), sf(b + k)))])


# ---------- nr_intfrac_sq：整數部分配小數部分 ----------

def nr_intfrac_sq(nest, v, simp, expr, f):
    """nest = √{…} 的寫法，v = 化簡後的值（Q），simp = (template, ans)，expr 和 f(a, b) 是要求的式子"""
    import re
    m = re.match(r"√\{(\d+) ([−+]) (\d*)√\{(\d+)\}\}", nest)
    inside = int(m.group(1)) + (1 if m.group(2) == "+" else -1) * int(m.group(3) or 1) * S(int(m.group(4)))
    assert near(float(v), S(inside))
    A = math.floor(float(v))
    b = v - A
    val = Q.of(f(A, b))
    assert (val.rat() or val.a == 0) and b.a < 0 < b.b
    return item("nr_intfrac_sq", "root", 2, "整數部分配小數部分", 1.15,
                "%s 的整數部分是 a、小數部分是 b，求 %s。" % (nest, expr),
                [fl("先拆掉雙重根號：", simp[0], simp[1], "根號裡寫成 p ± 2√{q}，找兩數和是 p、積是 q"),
                 fl("%s ≈ %.2f，求 a、b：" % (sf(v), float(v)), "a = [0]，b = %s − [1]" % Q(0, b.b, b.n).text(),
                    [str(A), a(-b.a)], "b = %s − a" % sf(v)),
                 fl("代入：", "%s = [0]" % expr, [val.ans()], "a = %d、b = %s 代進去，乘開後根號會消掉" % (A, sf(b)))])


# ---------- nr_ratio：分式的小數部分 ----------

def nr_ratio(p, q, k):
    d2 = p * p - q
    d = int(round(S(d2)))
    assert d * d == d2 and d > 0
    r = Q(p, 1, q) / d                 # √{(p + √q)/(p − √q)} = (p + √q)/d
    assert near(float(r), S((p + S(q)) / (p - S(q))))
    I = math.floor(float(r))
    x = r - I
    val = x + Q(k) / x
    assert val.a == 0 or val.b == 0
    wrong = [Q(p, 1, q), Q(p, 1, q) / (2 * d), Q(p, -1, q) / d, Q(0, 1, q) / d, Q(p, 1, q) / (d * d) if d > 1 else Q(p, 1, q) / 4]
    # x 的寫法：\frac{√{21} − [1]}{2}
    den = x.b.denominator
    num = Q(x.a * den, x.b * den, x.n)
    surd = Q(0, num.b, num.n).text()
    xt = ("%s − [1]" % surd) if den == 1 else "\\frac{%s − [1]}{%d}" % (surd, den)
    return item("nr_ratio", "root", 2, "分式的小數部分", 1.2,
                "\\frac{√{%d + √{%d}}}{√{%d − √{%d}}} 的小數部分是 x，求 x + \\frac{%d}{x}。" % (p, q, p, q, k),
                [ch("先化簡：分子、分母放進同一個根號，再有理化", uniq([qf(r)], [qf(w) for w in wrong], 4),
                    "\\frac{%d + √{%d}}{%d − √{%d}} 上下同乘 %d + √{%d}，分母是 %d，根號裡變成完全平方" % (p, q, p, q, p, q, d2),
                    "√{\\frac{%d + √{%d}}{%d − √{%d}}} = √{\\frac{(%d + √{%d})^{2}}{%d}} = %s" % (p, q, p, q, p, q, d2, qf(r))),
                 fl("%s ≈ %.2f，求整數部分與 x：" % (qf(r), float(r)), "整數部分 [0]，x = " + xt, [str(I), a(-num.a)],
                    "x = %s − %d" % (qf(r), I)),
                 fl("\\frac{%d}{x} 有理化，再相加：" % k, "x + \\frac{%d}{x} = [0]" % k, [val.ans()],
                    "\\frac{%d}{x} = %s" % (k, qf(Q(k) / x)))])


# ---------- nr_nest：一層層夾整數部分 ----------

def nr_nest(k, layers, steps_spec):
    v = 0.0
    for _ in range(layers):
        v = S(k + v)
    stem = "√{%d}" % k
    for _ in range(layers - 1):
        stem = "√{%d + %s}" % (k, stem)
    ans_last = math.floor(v)
    steps = []
    for (q, tpl, ans, hint) in steps_spec:
        steps.append(fl(q, tpl, [str(x) for x in ans], hint))
    assert int(steps[-1]["ans"][-1]) == ans_last
    return item("nr_nest", "root", 2, "一層層夾整數部分", 1.15, "求 %s 的整數部分。" % stem, steps)


# ---------- nr_rational：兩個分母有理化 ----------

def nr_rational(stem, val, steps):
    return item("nr_rational", "root", 2, "兩個分母有理化", 1.2, "化簡 %s。" % stem, steps)


# ---------- nr_order：根號排大小 ----------

def nr_order(names, texts, vals, step1, hint2):
    for tx, v in zip(texts, vals):
        assert v > 0
    opts = order_opts(names, vals)
    return item("nr_order", "root", 1, "根號排大小", 1.05,
                "%s，由大到小排列。" % "、".join("%s = %s" % (n, tx) for n, tx in zip(names, texts)),
                [step1, ch("由大到小：", opts, hint2, opts[0])])


# ---------- nr_golden：黃金比的次方 ----------

def nr_golden(p, q, N, v, ask_val):
    """v² = pv + q 的正根，求 v^N = a v + b"""
    x = Q(F(p, 2), F(1, 2), p * p + 4 * q)
    assert x * x == p * x + q
    co = {1: (F(1), F(0))}
    for n in range(1, N):
        a_, b_ = co[n]
        co[n + 1] = (p * a_ + b_, q * a_)
    aN, bN = co[N]
    assert x ** N == aN * x + bN
    val = aN * x + bN
    rel = "%s^{2} = %s" % (v, poly([(p, v), (q, "")]))
    a3, b3 = co[3]
    chain = "，".join("%s^{%d} = %s" % (v, n, poly([(co[n][0], v), (co[n][1], "")])) for n in range(3, N + 1))
    den = val.a.denominator
    if den == 1:
        tpl, ans = "%s^{%d} = [0] + [1]√{%d}" % (v, N, val.n), [a(val.a), a(val.b)]
    else:
        tpl, ans = "%s^{%d} = \\frac{[0] + [1]√{%d}}{%d}" % (v, N, val.n, den), [a(val.a * den), a(val.b * den)]
    stem0 = ("%s = %s 滿足 %s" % (v, qf(x), rel)) if v != "x" else ("x = %s 是 %s 的正根" % (qf(x), rel))
    return item("nr_golden", "root", 2, "黃金比的次方", 1.2,
                "%s。把 %s^{%d} 寫成 a%s + b，再求 %s^{%d} 的值。" % (stem0, v, N, v, v, N),
                [fl("用 %s 降次：" % rel, "%s^{3} = %s · %s^{2} = [0]%s + [1]" % (v, v, v, v), [a(a3), a(b3)],
                    "%s^{3} = %s(%s) = %s，再把 %s^{2} 換掉" % (v, v, poly([(p, v), (q, "")]), poly([(p, v + "^{2}"), (q, v)]), v)),
                 fl("一次一次乘 %s、降次：" % v, "%s^{%d} = [0]%s + [1]" % (v, N, v), [a(aN), a(bN)], chain),
                 fl("代入 %s = %s：" % (v, qf(x)), tpl, ans, "%s × %s + %s" % (t(aN), qf(x) if x.a.denominator > 1 else "(%s)" % qf(x), t(bN)))])


# ---------- nr_cube：立方公式湊值 ----------

def nr_cube(m):
    t_ = m - 1
    c = m ** (1 / 3)
    k = c * c + c + 1
    assert near((c - 1) * k, t_)
    e = 3 * t_ / k + 3 * t_ * t_ / k ** 2 + t_ ** 3 / k ** 3
    assert near(e, t_)
    kt = "∛{%d} + ∛{%d} + 1" % (m * m, m)
    expr = "\\frac{%d}{k} + \\frac{%d}{k^{2}} + \\frac{%d}{k^{3}}" % (3 * t_, 3 * t_ * t_, t_ ** 3)
    return item("nr_cube", "root", 3, "立方公式湊值", 1.3,
                "k = %s，求 %s。" % (kt, expr),
                [fl("先算 (∛{%d} − 1)k：" % m, "(∛{%d} − 1)(%s) = (∛{%d})^{3} − 1 = [0]" % (m, kt, m), [str(t_)],
                    "a^{3} − b^{3} = (a − b)(a^{2} + ab + b^{2})，a = ∛{%d}、b = 1" % m),
                 ch("所求的式子湊成？", ["(1 + \\frac{%d}{k})^{3} − 1" % t_, "(1 + \\frac{%d}{k})^{3}" % t_, "(\\frac{%d}{k})^{3} + 1" % t_,
                                     "(1 − \\frac{%d}{k})^{3} + 1" % t_],
                    "(1 + y)^{3} = 1 + 3y + 3y^{2} + y^{3}，y = \\frac{%d}{k}" % t_, "%s = (1 + \\frac{%d}{k})^{3} − 1" % (expr, t_)),
                 fl("\\frac{%d}{k} = ∛{%d} − 1 代入：" % (t_, m), "(1 + ∛{%d} − 1)^{3} − 1 = [0]" % m, [str(t_)], "(∛{%d})^{3} = %d" % (m, m))])


# ---------- nr_semi：半圓裡的線段 ----------

def nr_semi(D, cards_sq):
    ok_sq = set(x * (D - x) for x in range(1, D))
    cards = []
    for v2 in cards_sq:
        ok = v2 in ok_sq
        s = rt(v2)
        if ok:
            x = [x for x in range(1, D) if x * (D - x) == v2][0]
            why = "第 %d 個分點：√{%d × %d} = %s" % (x, x, D - x, s.text())
        else:
            why = "x(%d − x) 只會是 %s，沒有 %d" % (D, "、".join(str(w) for w in sorted(ok_sq)), v2)
        cards.append(cardc("垂線長可能是 %s" % s.text(), ok, why, ok))
    r = D / 2
    shapes = [{"k": "arc", "o": [fx(r), 0], "r": fx(r), "a0": 0, "a1": 180, "c": "cyan"}, seg((0, 0), (D, 0), "dim")]
    for x in range(1, D):
        h = S(x * (D - x))
        shapes.append(seg((x, 0), (x, h), "pink", w=1.5))
    shapes.append(lab((r, -0.7), str(D), "text"))
    plot = {"x": [-0.5, fx(D + 0.5)], "y": [-1.2, fx(r + 0.5)], "geo": True, "h": 150, "shapes": shapes}
    return item("nr_semi", "root", 1, "半圓裡的線段", 1.05,
                "直徑 %d 的半圓，把直徑 %d 等分，從每個分點作垂線交半圓。下列哪些是其中一條垂線的長？" % (D, D),
                [ch("分點把直徑分成 x 和 %d − x，垂線長 h 滿足？" % D,
                    ["h^{2} = x(%d − x)" % D, "h = x(%d − x)" % D, "h^{2} = x^{2} + (%d − x)^{2}" % D, "h = \\frac{%d}{2}" % D],
                    "連到直徑兩端是直角三角形，垂線把它分成兩個相似三角形", "h^{2} = x(%d − x)：h = √{x(%d − x)}" % (D, D)),
                 jd("x 是 1 到 %d 的整數，算算 √{x(%d − x)}。" % (D - 1, D), cards)])


# ---------- nr_paper：對摺後一樣的長方形 ----------

def nr_paper(k, a4=False):
    """沿長邊 k 等分（摺），小長方形和原來的相似；長 x、寬 1"""
    assert k in (2, 3)
    st = "對摺" if k == 2 else "摺成三等份"
    piece = "\\frac{x}{%d}" % k
    steps = [ch("長 x、寬 1，%s後每一小塊的長和寬是？" % st, ["長 1、寬 %s" % piece, "長 x、寬 \\frac{1}{%d}" % k, "長 %s、寬 \\frac{1}{%d}" % (piece, k), "長 %dx、寬 1" % k],
                "沿長邊%s：長邊 x 被分成 %d 份，原來的寬 1 變成長" % (st, k), "小長方形：長 1、寬 %s" % piece),
             fl("長寬比一樣：", "\\frac{x}{1} = \\frac{1}{%s}　→　x^{2} = [0]，x = [1]" % piece, [str(k), "√%d" % k], "交叉相乘，x > 0")]
    if a4:
        w = 297 / S(2)
        assert abs(w - 210) < 0.5
        steps.append(fl("A4 紙長 297 mm，寬約幾 mm？", "寬 = \\frac{297}{√{2}} ≈ [0]（取整數）", ["210"], "√{2} ≈ 1.414"))
    stem = ("一張長方形紙，長 x、寬 1，沿長邊%s後，每一小塊都和原來的紙形狀一樣（相似）。求 x。" % st) if not a4 else \
        "A4 紙的特點是對摺後的形狀和原來一樣（相似）。設長 x、寬 1，求 x；A4 紙長 297 mm，寬約多少？"
    return item("nr_paper", "root", 1, "對摺後一樣的長方形", 1.0, stem, steps)


def items():
    return [
        [nr_peel(28, -1, "√{720}", 180, "√{720}", 18, 10), nr_peel(12, 1, "√{140}", 35, "√{140}", 7, 5),
         nr_peel(11, -1, "4√{7}", 28, "4√{7}", 7, 4)],
        [nr_intfrac(2, 1, 11, 6), nr_intfrac(5, -1, 7, -6), nr_intfrac(1, 1, 19, 8)],
        [nr_intfrac_sq("√{14 + 6√{5}}", Q(3, 1, 5), ("√{14 + 6√{5}} = √{14 + 2√{45}} = [0] + √{[1]}", ["3", "5"]),
                       "(√{a} − b)^{2}", lambda A, b: (Q.sqrt(A) - b) ** 2),
         nr_intfrac_sq("√{19 − 6√{2}}", Q(-1, 3, 2), ("√{19 − 6√{2}} = √{19 − 2√{18}} = [0]√{2} − [1]", ["3", "1"]),
                       "(a + b + 1)^{2}", lambda A, b: (A + b + 1) ** 2),
         nr_intfrac_sq("√{9 + 4√{5}}", Q(2, 1, 5), ("√{9 + 4√{5}} = √{9 + 2√{20}} = [0] + √{[1]}", ["2", "5"]),
                       "\\frac{1}{b} − b", lambda A, b: 1 / b - b)],
        [nr_ratio(5, 21, 3), nr_ratio(4, 15, 6), nr_ratio(7, 48, 12)],
        [nr_nest(2025, 3, [("最裡面那一層：", "√{2025} = [0]", [45], "45^{2} = 2025"),
                           ("中間那一層：", "√{2025 + 45} = √{2070}，[0] < √{2070} < [1]", [45, 46], "45^{2} = 2025、46^{2} = 2116"),
                           ("最外面那一層：", "2070 < 2025 + √{2070} < 2071，整數部分是 [0]", [45], "根號裡夾在 45^{2} 和 46^{2} 之間")]),
         nr_nest(42, 3, [("最裡面那一層：", "[0] < √{42} < [1]", [6, 7], "6^{2} = 36、7^{2} = 49"),
                         ("中間那一層：", "48 < 42 + √{42} < 49，所以 [0] < √{42 + √{42}} < [1]", [6, 7], "根號裡比 7^{2} = 49 小"),
                         ("最外面那一層：", "48 < 42 + √{42 + √{42}} < 49，整數部分是 [0]", [6], "和上一層一樣夾在 6^{2}、7^{2} 之間")]),
         nr_nest(1600, 4, [("最裡面那一層：", "√{1600} = [0]", [40], "40^{2} = 1600"),
                           ("往外一層：", "√{1600 + 40} = √{1640}，[0] < √{1640} < [1]", [40, 41], "40^{2} = 1600、41^{2} = 1681"),
                           ("再往外：", "每一層根號裡都在 1640 和 1641 之間，整數部分是 [0]", [40], "1640 < 1600 + √{…} < 1641 < 41^{2}")])],
        [nr_rational("\\frac{1}{√{3} + √{2} + 1} + \\frac{1}{√{3} − √{2} − 1}", -S(6) / 2,
                     [ch("令 u = √{2} + 1，兩個分母相乘 (√{3} + u)(√{3} − u) = ？", ["3 − u^{2}", "3 + u^{2}", "u^{2} − 3", "3 − u"],
                         "平方差：(a + b)(a − b) = a^{2} − b^{2}", "通分：分母 (√{3} + u)(√{3} − u) = 3 − u^{2}"),
                      fl("u^{2} 展開，再算分母：", "u^{2} = [0] + [1]√{2}，3 − u^{2} = [2]", ["3", "2", "−2√2"], "(√{2} + 1)^{2} = 2 + 2√{2} + 1"),
                      fl("分子 (√{3} − u) + (√{3} + u)：", "分子 = [0]，原式 = [1]", ["2√3", "−√6/2"], "\\frac{2√{3}}{−2√{2}}，再有理化")]),
         nr_rational("\\frac{1}{√{5} + √{2} + 1} − \\frac{1}{√{5} − √{2} − 1}", 3 + 2 * S(2),
                     [ch("令 u = √{2} + 1，兩個分母相乘 (√{5} + u)(√{5} − u) = ？", ["5 − u^{2}", "5 + u^{2}", "u^{2} − 5", "5 − u"],
                         "平方差：(a + b)(a − b) = a^{2} − b^{2}", "通分：分母 (√{5} + u)(√{5} − u) = 5 − u^{2}"),
                      fl("u^{2} 展開，再算分母：", "u^{2} = [0] + [1]√{2}，5 − u^{2} = [2] − [3]√{2}", ["3", "2", "2", "2"], "(√{2} + 1)^{2} = 2 + 2√{2} + 1"),
                      fl("分子 (√{5} − u) − (√{5} + u) = −2u：", "原式 = \\frac{−2(√{2} + 1)}{2 − 2√{2}} = [0] + [1]√{2}", ["3", "2"],
                         "約掉 −2 得 \\frac{√{2} + 1}{√{2} − 1}，上下同乘 √{2} + 1")]),
         nr_rational("\\frac{1}{√{6} + √{2} + 2} + \\frac{1}{√{6} − √{2} − 2}", -S(3) / 2,
                     [ch("令 u = √{2} + 2，兩個分母相乘 (√{6} + u)(√{6} − u) = ？", ["6 − u^{2}", "6 + u^{2}", "u^{2} − 6", "6 − u"],
                         "平方差：(a + b)(a − b) = a^{2} − b^{2}", "通分：分母 (√{6} + u)(√{6} − u) = 6 − u^{2}"),
                      fl("u^{2} 展開，再算分母：", "u^{2} = [0] + [1]√{2}，6 − u^{2} = [2]", ["6", "4", "−4√2"], "(√{2} + 2)^{2} = 2 + 4√{2} + 4"),
                      fl("分子 (√{6} − u) + (√{6} + u)：", "分子 = [0]，原式 = [1]", ["2√6", "−√3/2"], "\\frac{2√{6}}{−4√{2}} = −\\frac{√{3}}{2}")])],
        [nr_order(["a", "b", "c"], ["√{2} + √{11}", "√{5} + √{8}", "√{3} + √{10}"], [S(2) + S(11), S(5) + S(8), S(3) + S(10)],
                  fl("平方後比較：", "a^{2} = 13 + 2√{[0]}，b^{2} = 13 + 2√{[1]}，c^{2} = 13 + 2√{[2]}", ["22", "40", "30"], "(√{p} + √{q})^{2} = p + q + 2√{pq}"),
                  "平方後 13 都一樣，比 2√{…} 裡面的數"),
         nr_order(["a", "b", "c"], ["√{13} − √{11}", "√{11} − 3", "√{15} − √{13}"], [S(13) - S(11), S(11) - 3, S(15) - S(13)],
                  ch("差不好比，改看倒數：\\frac{1}{a} = ？", ["\\frac{√{13} + √{11}}{2}", "√{13} + √{11}", "\\frac{√{13} − √{11}}{2}", "\\frac{1}{√{13}} − \\frac{1}{√{11}}"],
                     "上下同乘 √{13} + √{11}，分母 13 − 11 = 2", "\\frac{1}{a} = \\frac{√{13} + √{11}}{2}，\\frac{1}{b} = \\frac{√{11} + 3}{2}，\\frac{1}{c} = \\frac{√{15} + √{13}}{2}"),
                  "倒數越大，原來的數越小"),
         nr_order(["a", "b", "c"], ["√{7} − √{3}", "√{17} − √{13}", "√{11} − √{7}"], [S(7) - S(3), S(17) - S(13), S(11) - S(7)],
                  ch("差不好比，改看倒數：\\frac{1}{a} = ？", ["\\frac{√{7} + √{3}}{4}", "√{7} + √{3}", "\\frac{√{7} − √{3}}{4}", "\\frac{√{7} + √{3}}{2}"],
                     "上下同乘 √{7} + √{3}，分母 7 − 3 = 4", "\\frac{1}{a} = \\frac{√{7} + √{3}}{4}，\\frac{1}{b} = \\frac{√{17} + √{13}}{4}，\\frac{1}{c} = \\frac{√{11} + √{7}}{4}"),
                  "倒數越大，原來的數越小")],
        [nr_golden(1, 1, 6, "φ", True), nr_golden(2, 1, 5, "x", True), nr_golden(1, 3, 4, "x", True)],
        [nr_cube(5), nr_cube(3), nr_cube(7)],
        [nr_semi(8, [12, 15, 10, 16, 9]), nr_semi(6, [5, 8, 9, 6, 4]), nr_semi(10, [9, 24, 21, 10, 20])],
        [nr_paper(2), nr_paper(3), nr_paper(2, a4=True)],
    ]


def _check_rational():
    v1 = 1 / (S(3) + S(2) + 1) + 1 / (S(3) - S(2) - 1)
    v2 = 1 / (S(5) + S(2) + 1) - 1 / (S(5) - S(2) - 1)
    v3 = 1 / (S(6) + S(2) + 2) + 1 / (S(6) - S(2) - 2)
    assert near(v1, -S(6) / 2) and near(v2, 3 + 2 * S(2)) and near(v3, -S(3) / 2)


_check_rational()
