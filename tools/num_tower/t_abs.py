# 絕對值柵欄
from nlib import *

OPS = {"≥": lambda v: v >= 0, "≤": lambda v: v <= 0, ">": lambda v: v > 0, "<": lambda v: v < 0, "=": lambda v: v == 0}
FLIP = {"≥": "≤", "≤": "≥", ">": "<", "<": ">", "=": "="}


def line_ok(f, op, marks, seg, pt):
    """檢查數線的答案：每一段中間取一點、每個端點代進去"""
    ms = [F(m) for m in marks]
    xs = [ms[0] - 3] + [(ms[i] + ms[i + 1]) / 2 for i in range(len(ms) - 1)] + [ms[-1] + 3]
    for x, s in zip(xs, seg):
        assert OPS[op](f(x)) == bool(s), ("數線的段不對", x)
    for x, p in zip(ms, pt):
        assert OPS[op](f(x)) == bool(p), ("數線的端點不對", x)


def sol_text(marks, seg, pt):
    ms = [t(m) for m in marks]
    parts = []
    n = len(marks)
    i = 0
    while i <= n:
        if seg[i]:
            j = i
            while j < n and seg[j + 1] and pt[j]:
                j += 1
            lo = "" if i == 0 else ms[i - 1] + (" ≤ " if pt[i - 1] else " < ")
            hi = "" if j == n else (" ≤ " if pt[j] else " < ") + ms[j]
            parts.append(lo + "x" + hi if (lo or hi) else "全體實數")
            i = j + 1
        else:
            if i < n and pt[i] and not seg[i + 1] and (i == 0 or True):
                parts.append("x = " + ms[i])
            i += 1
    return " 或 ".join(parts)


# ---------- na_graph：看數線反求 ----------

def na_graph(c, op, lo, hi):
    m, r = F(lo + hi, 2), F(hi - lo, 2)
    A, B = -c * m, abs(c) * r
    f = lambda x: abs(c * x + A) - B
    outside = op in ("≥", ">")
    closed = op in ("≥", "≤")
    marks = [lo, hi]
    seg = [1, 0, 1] if outside else [0, 1, 0]
    line_ok(f, op, marks, seg, [int(closed)] * 2)
    xr = (lo - (hi - lo) * 0.45, hi + (hi - lo) * 0.45)
    shapes = (ray(lo, False, closed, xr) + ray(hi, True, closed, xr)) if outside else band(lo, hi, closed, closed, xr)
    ac = abs(c)
    sg = "−" if c < 0 else "+"
    expr = "|%s + a|" % cx(c)
    opts = ["|x %s \\frac{a}{%d}| %s \\frac{b}{%d}" % (sg, ac, op, ac), "|x %s \\frac{a}{%d}| %s \\frac{b}{%d}" % ("+" if c < 0 else "−", ac, op, ac),
            "|x %s \\frac{a}{%d}| %s %db" % (sg, ac, op, ac), "|x %s %da| %s \\frac{b}{%d}" % (sg, ac, op, ac)]
    return item("na_graph", "abs", 1, "看數線反求", 1.05,
                "不等式 %s %s b 的解畫在右邊的數線上，求數對 (a, b)。" % (expr, op),
                [fl("先讀圖：解是「到中點的距離 %s 半徑」" % op, "中點 = [0]，半徑 = [1]", [a(m), a(r)], "中點是兩個端點的平均，半徑是距離的一半"),
                 ch("%s %s b 兩邊除以 %d，變成？" % (expr, op, ac), opts,
                    "%s = %d|x %s \\frac{a}{%d}|%s" % (expr, ac, sg, ac, "（−3x = −3 · x，提出 −3 後絕對值變正）".replace("3", str(ac)) if c < 0 else ""),
                    "%s %s b　⇔　%s" % (expr, op, opts[0])),
                 fl("和讀圖的結果比較：", "%s\\frac{a}{%d} = %s，\\frac{b}{%d} = %s　→　(a, b) = ([0], [1])" % ("" if c < 0 else "−", ac, t(m), ac, t(r)),
                    [a(A), a(B)], "a = %s × %s，b = %d × %s" % (t(-c), tp(m), ac, tp(r)))],
                plot=nl_plot(xr, shapes))


# ---------- na_vs_x：右邊有 x ----------

def na_vs_x(kind):
    if kind == 1:
        f = lambda x: abs(3 * x - 5) - 2 * x
        line_ok(f, "≤", [1, 5], [0, 1, 0], [1, 1])
        return item("na_vs_x", "abs", 1, "右邊有 x", 1.05, "解不等式 |3x − 5| ≤ 2x，用區間寫出答案。",
                    [ch("|3x − 5| ≤ 2x 等價於？", ["−2x ≤ 3x − 5 ≤ 2x", "3x − 5 ≤ 2x", "3x − 5 ≤ −2x 或 3x − 5 ≥ 2x", "−5 ≤ 3x − 5 ≤ 5"],
                        "|A| ≤ B 就是 −B ≤ A ≤ B（B 是負的話兩邊會矛盾，自動無解）", "|3x − 5| ≤ 2x　⇔　−2x ≤ 3x − 5 ≤ 2x"),
                     fl("兩個不等式分開解：", "−2x ≤ 3x − 5 → x ≥ [0]；3x − 5 ≤ 2x → x ≤ [1]", ["1", "5"], "移項：5x ≥ 5；x ≤ 5"),
                     step("line", q="封印兩個條件都成立的部分。", row="解", marks=["1", "5"], seg=[0, 1, 0], pt=[1, 1], write="答：[1, 5]")])
    if kind == 2:
        f = lambda x: abs(2 * x - 4) - (x - 3)
        line_ok(f, ">", [1, F(7, 3)], [1, 1, 1], [1, 1])
        return item("na_vs_x", "abs", 1, "右邊有 x", 1.05, "解不等式 |2x − 4| > x − 3，用區間寫出答案。",
                    [ch("|2x − 4| > x − 3 等價於？", ["2x − 4 > x − 3 或 2x − 4 < 3 − x", "3 − x < 2x − 4 < x − 3", "2x − 4 > x − 3", "2x − 4 < x − 3 或 2x − 4 > 3 − x"],
                        "|A| > B 就是 A > B 或 A < −B", "|2x − 4| > x − 3　⇔　2x − 4 > x − 3 或 2x − 4 < 3 − x"),
                     fl("兩個不等式分開解：", "x > [0] 或 x < [1]", ["1", "7/3"], "2x − 4 > x − 3 → x > 1；3x < 7"),
                     step("line", q="封印「或」的部分（兩段合起來）。", row="解", marks=["1", "7/3"], seg=[1, 1, 1], pt=[1, 1],
                          write="答：兩段合起來蓋滿數線，解是 (−∞, ∞)（全體實數）")])
    f = lambda x: abs(x + 2) - (x - 4)
    for x in range(-20, 30):
        assert not (f(F(x, 3)) < 0)
    return item("na_vs_x", "abs", 1, "右邊有 x", 1.05, "解不等式 |x + 2| < x − 4，用區間寫出答案。",
                [ch("|x + 2| < x − 4 等價於？", ["4 − x < x + 2 < x − 4", "x + 2 < x − 4", "x + 2 > x − 4 或 x + 2 < 4 − x", "−4 < x + 2 < 4"],
                    "|A| < B 就是 −B < A < B", "|x + 2| < x − 4　⇔　4 − x < x + 2 < x − 4"),
                 ch("右半邊 x + 2 < x − 4 化簡成？", ["不可能成立", "x < −3", "x > 1", "恆成立"], "兩邊都減 x", "x + 2 < x − 4　→　2 < −4（矛盾）"),
                 ch("所以解是？", ["無解", "(1, ∞)", "(4, ∞)", "(−∞, ∞)"], "「且」的其中一個條件不可能成立", "答：無解")])


# ---------- 分段：一段一段解 ----------

def _rng(cuts, i):
    if i == 0:
        return "x < %s" % t(cuts[0])
    if i == len(cuts):
        return "x ≥ %s" % t(cuts[-1])
    return "%s ≤ x < %s" % (t(cuts[i - 1]), t(cuts[i]))


def _region_result(lo, hi, k, m, op):
    """[lo, hi)（None = 無窮）裡 kx + m op 0 的解：(文字, 不管區間時的解)"""
    def inr(x):
        return (lo is None or x >= lo) and (hi is None or x < hi)
    if k == 0:
        return ("這一段全部成立" if OPS[op](m) else "這一段無解"), None
    c = -m / k
    if op == "=":
        return ("x = %s" % t(c) if inr(c) else "這一段無解"), "x = %s" % t(c)
    o = op if k > 0 else FLIP[op]
    raw = "x %s %s" % (o, t(c))
    if o in ("≥", ">"):
        if lo is None or c > lo:
            L, Lin = c, o == "≥"
        elif c == lo:
            L, Lin = lo, o == "≥"
        else:
            L, Lin = lo, True
        R, Rin = hi, False
    else:
        L, Lin = lo, True
        if hi is None or c < hi:
            R, Rin = c, o == "≤"
        else:
            R, Rin = hi, False
    if L is not None and R is not None and (L > R or (L == R and not (Lin and Rin))):
        return "這一段無解", raw
    if L == lo and (lo is None or Lin) and R == hi and not Rin:
        return "這一段全部成立", raw
    if L is not None and L == R:
        return "x = %s" % t(L), raw
    left = "" if L is None else t(L) + (" ≤ " if Lin else " < ")
    right = "" if R is None else (" ≤ " if Rin else " < ") + t(R)
    return left + "x" + right, raw


def piece_steps(left, rk, rs, op):
    """left：Pw（只有絕對值），右邊 rk x + rs"""
    cuts = left.cuts()
    steps = []
    for i in range(len(cuts) + 1):
        lo = None if i == 0 else cuts[i - 1]
        hi = None if i == len(cuts) else cuts[i]
        sample = (lo + 1) if hi is None and lo is not None else ((hi - 1) if lo is None else (lo + hi) / 2)
        al, be = left.on(sample)
        k, m = al - rk, be - rs
        res, raw = _region_result(lo, hi, k, m, op)
        form = "%s %s %s" % (lin_t(al, be), op, lin_t(rk, rs))
        base = ["這一段全部成立", "這一段無解"]
        if res in base:
            bd = lo if lo is not None else hi
            opts = uniq([res], base + ["x = %s" % t(bd)], 3)
        else:
            opts = uniq([res], base, 3)
        hint = ("這一段裡 %s，化簡後 %s" % (form, raw if raw else ("左右兩邊一樣" if m == 0 or OPS[op](m) else "不可能成立"))) + \
            ("，再和 %s 取交集" % _rng(cuts, i) if raw else "")
        steps.append(ch("%s：化成 %s，這一段的解？" % (_rng(cuts, i), form), opts, hint,
                        "%s：%s　→　%s" % (_rng(cuts, i), form, res.replace("這一段", ""))))
    return steps


# ---------- na_piece：兩個絕對值的不等式 ----------

def na_piece(absts, rk, rs, op, marks, seg, pt):
    left = Pw(absts)
    f = lambda x: left(x) - (rk * x + rs)
    line_ok(f, op, marks, seg, pt)
    lt = ""
    for c, u in absts:
        term_ = ("" if abs(c) == 1 else str(abs(c))) + "|%s|" % poly([(1, "x"), (-u, "")])
        lt += (("−" if c < 0 else "") + term_) if lt == "" else ((" − " if c < 0 else " + ") + term_)
    stem = "%s %s %s" % (lt, op, lin_t(rk, rs))
    cuts = left.cuts()
    return item("na_piece", "abs", 2, "兩個絕對值的不等式", 1.25,
                "解不等式 %s。" % stem,
                [ch("用哪兩個點分段？", ["x = %s 和 x = %s" % (t(cuts[0]), t(cuts[1])), "x = %s 和 x = %s" % (t(-cuts[0]), t(-cuts[1])), "只要 x = 0", "x = %s 和 x = 0" % t(cuts[0])],
                    "讓絕對值裡面等於 0 的點", "分段點 x = %s、x = %s" % (t(cuts[0]), t(cuts[1])))] +
                piece_steps(left, rk, rs, op) +
                [step("line", q="三段的解合起來，封印在數線上。", row="解", marks=[t(m) for m in marks], seg=seg, pt=pt,
                      write="答：" + sol_text(marks, seg, pt))])


# ---------- na_eq：兩個絕對值的方程式 ----------

def na_eq(absts, rk, rs, ask, ans):
    """ask = "sum"：所有解的和；"range"：解是一整段 [lo, hi]"""
    left = Pw(absts)
    f = lambda x: left(x) - (rk * x + rs)
    lt = ""
    for c, u in absts:
        term_ = ("" if abs(c) == 1 else str(abs(c))) + "|%s|" % poly([(1, "x"), (-u, "")])
        lt += (("−" if c < 0 else "") + term_) if lt == "" else ((" − " if c < 0 else " + ") + term_)
    stem = "%s = %s" % (lt, lin_t(rk, rs))
    cuts = left.cuts()
    # 驗算：在一大片有理數上找解
    sols = [F(x, 6) for x in range(-120, 121) if f(F(x, 6)) == 0]
    if ask == "sum":
        assert sum(sols) == F(ans) and len(sols) <= 3
        last = fl("所有解的和？", "解是 %s，和 = [0]" % "、".join(t(s) for s in sols), [a(ans)], "把留下來的解加起來")
        q = "求方程式 %s 所有實數解的和。" % stem
    else:
        lo_, hi_ = ans
        assert sols[0] == lo_ and sols[-1] == hi_ and len(sols) == (hi_ - lo_) * 6 + 1
        last = fl("解是一整段：", "[0] ≤ x ≤ [1]", [a(lo_), a(hi_)], "中間那一段全部都是解，再看兩個端點")
        q = "解方程式 %s。" % stem
    return item("na_eq", "abs", 2, "兩個絕對值的方程式", 1.2, q,
                piece_steps(left, rk, rs, "=") + [last])


# ---------- na_back：聯立的解反求參數 ----------

def na_back(c1, r1, keep, sol, a_ans, b_known=None):
    """{|x − c1| ≤ r1、|x − a| ≥ b} 的解；keep = "R"／"L"／"both"""
    lo, hi = c1 - r1, c1 + r1
    def solve(a_, b_):
        out = []
        for i in range(-400, 401):
            x = F(i, 4)
            if abs(x - c1) <= r1 and abs(x - a_) >= b_:
                out.append(x)
        return out
    if keep == "both":
        a_, b_ = a_ans
        got = solve(a_, b_)
        want = [F(i, 4) for i in range(-400, 401) if (sol[0][0] <= F(i, 4) <= sol[0][1]) or (sol[1][0] <= F(i, 4) <= sol[1][1])]
        assert got == want
        stxt = "%s ≤ x ≤ %s 或 %s ≤ x ≤ %s" % (t(sol[0][0]), t(sol[0][1]), t(sol[1][0]), t(sol[1][1]))
        return item("na_back", "abs", 2, "聯立的解反求參數", 1.2,
                    "聯立不等式 {|x − %s| ≤ %s、|x − a| ≥ b} 的解是 %s，求 (a, b)。" % (t(c1), t(r1), stxt) if c1 > 0 else
                    "聯立不等式 {|x + %s| ≤ %s、|x − a| ≥ b} 的解是 %s，求 (a, b)。" % (t(-c1), t(r1), stxt),
                    [fl("先解第一式：", "[0] ≤ x ≤ [1]", [a(lo), a(hi)], "|x − %s| ≤ %s：%s − %s ≤ x ≤ %s + %s" % (t(c1), t(r1), t(c1), t(r1), t(c1), t(r1))),
                     ch("|x − a| ≥ b 的解 x ≤ a − b 或 x ≥ a + b，留下的是？", ["兩邊都留下", "只留右邊", "只留左邊", "中間一段"],
                        "答案有兩段，左邊從 %s 開始、右邊到 %s 結束" % (t(lo), t(hi)), "兩邊各留一段：a − b = %s，a + b = %s" % (t(sol[0][1]), t(sol[1][0]))),
                     fl("兩個缺口的端點：", "a − b = [0]，a + b = [1]　→　(a, b) = ([2], [3])", [a(sol[0][1]), a(sol[1][0]), a(a_), a(b_)],
                        "左段的右端是 a − b，右段的左端是 a + b，兩式相加、相減")])
    b_ = b_known
    a_ = a_ans
    got = solve(a_, b_)
    want = [F(i, 4) for i in range(-400, 401) if sol[0] <= F(i, 4) <= sol[1]]
    assert got == want
    # 其他 a 不行（答案唯一）
    for i in range(-200, 201):
        if F(i, 4) != a_:
            assert solve(F(i, 4), b_) != want
    side = "x ≥ a + %s" % t(b_) if keep == "R" else "x ≤ a − %s" % t(b_)
    other = "x ≤ a − %s" % t(b_) if keep == "R" else "x ≥ a + %s" % t(b_)
    edge = sol[0] if keep == "R" else sol[1]
    eq = ("a + %s" if keep == "R" else "a − %s") % t(b_)
    first = ("|x − %s| ≤ %s" % (t(c1), t(r1))) if c1 > 0 else ("|x + %s| ≤ %s" % (t(-c1), t(r1)))
    return item("na_back", "abs", 2, "聯立的解反求參數", 1.2,
                "聯立不等式 {%s、|x − a| ≥ %s} 的解是 %s ≤ x ≤ %s，求 a。" % (first, t(b_), t(sol[0]), t(sol[1])),
                [fl("先解第一式：", "[0] ≤ x ≤ [1]", [a(lo), a(hi)], "%s − %s ≤ x ≤ %s + %s" % (t(c1), t(r1), t(c1), t(r1))),
                 ch("答案貼著第一式的%s端，|x − a| ≥ %s 留下的是？" % ("右" if keep == "R" else "左", t(b_)),
                    [side, other, "兩邊都留下", "a − %s ≤ x ≤ a + %s" % (t(b_), t(b_))],
                    "答案的%s端 %s 是第一式的端點，另一端 %s 是 |x − a| ≥ %s 切出來的" % ("右" if keep == "R" else "左", t(sol[1] if keep == "R" else sol[0]), t(edge), t(b_)),
                    "留下 %s，另一邊完全落在 %s ≤ x ≤ %s 外面" % (side, t(lo), t(hi))),
                 fl("切出來的端點：", "%s = %s　→　a = [0]" % (eq, t(edge)), [a(a_)], "%s 是 %s 的端點" % (t(edge), side))])


# ---------- na_same：和聯立同解 ----------

def na_same(i1, i2, inter, k, A, B):
    """i1、i2 = (文字, 解的文字, 填空模板, 答案, 函式)；交集 inter = (lo, hi)；|kx + ...| 乘幾倍"""
    lo, hi = F(inter[0]), F(inter[1])
    for i in range(-200, 201):
        x = F(i, 4)
        both = i1[4](x) and i2[4](x)
        assert both == (lo < x < hi)
        assert (abs(A * x - k) < B) == both
    m, r = (lo + hi) / 2, (hi - lo) / 2
    d = (m).denominator
    base = "|%s| < %s" % (poly([(d, "x"), (-d * m, "")]), t(d * r))
    mul = F(A, d)
    return item("na_same", "abs", 2, "和聯立同解", 1.25,
                "聯立不等式 {%s、%s} 和 |ax − %s| < b 的解相同，求 a − b。" % (i1[0], i2[0], t(k)),
                [fl("解第一式：", i1[2], i1[3], "|A| < c 就是 −c < A < c"),
                 fl("解第二式：", i2[2], i2[3], "|A| > c 就是 A > c 或 A < −c"),
                 fl("取交集：", "[0] < x < [1]", [a(lo), a(hi)], "在數線上畫出兩個解，找重疊的部分"),
                 fl("寫成「到中點的距離」再配係數：", "%s　→　乘 [0] 倍：(a, b) = ([1], [2])，a − b = [3]" % base,
                    [a(mul), a(A), a(B), a(A - B)], "中點 %s、半徑 %s；要讓常數項變成 −%s，整個式子乘 %s（絕對值裡乘負數沒關係，b 要乘它的絕對值）" % (t(m), t(r), t(k), t(mul)))])


def items():
    return [
        [na_graph(-3, "≥", -6, 2), na_graph(2, "≤", -1, 7), na_graph(-2, "<", -3, 4)],
        [na_vs_x(1), na_vs_x(2), na_vs_x(3)],
        [na_piece([(2, -1), (-1, 6)], 3, -4, "≥", [6], [1, 0], [1]),
         na_piece([(1, 1), (2, -2)], 2, 7, "≤", [-2, 4], [0, 1, 0], [1, 1]),
         na_piece([(2, 2), (-1, -1)], 1, -5, ">", [2], [1, 0], [0])],
        [na_eq([(2, -1), (1, 2)], 1, 8, "sum", 2), na_eq([(1, 3), (1, -1)], 3, -2, "sum", 2),
         na_eq([(1, 3), (2, -1)], 1, 5, "range", (-1, 3))],
        [na_back(1, 3, "R", (3, 4), -3, 6), na_back(-2, 5, "L", (-7, -1), 3, 4), na_back(2, 6, "both", [(-4, -1), (7, 8)], (3, 4))],
        [na_same(("|1 + 2x| < 3", "", "[0] < x < [1]", ["−2", "1"], lambda x: abs(1 + 2 * x) < 3),
                 ("|1 − x| > 2", "", "x < [0] 或 x > [1]", ["−1", "3"], lambda x: abs(1 - x) > 2), (-2, -1), 9, -6, 3),
         na_same(("|x − 3| < 4", "", "[0] < x < [1]", ["−1", "7"], lambda x: abs(x - 3) < 4),
                 ("|x + 1| > 5", "", "x < [0] 或 x > [1]", ["−6", "4"], lambda x: abs(x + 1) > 5), (4, 7), 22, 4, 6),
         na_same(("|2x − 1| < 7", "", "[0] < x < [1]", ["−3", "4"], lambda x: abs(2 * x - 1) < 7),
                 ("|x − 5| > 3", "", "x < [0] 或 x > [1]", ["2", "8"], lambda x: abs(x - 5) > 3), (-3, 2), 3, -6, 15)],
    ]
