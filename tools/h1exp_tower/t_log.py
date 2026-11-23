# 十倍石階：常用對數
from xlib import *


# ---------- xl_between：10 的幾次方在哪裡 ----------

def xl_between(e, lo, hi, given, ctx):
    """10^e 在 lo、hi 之間；given = [(n, log n 的近似值字串)]"""
    assert lo < 10 ** e < hi and hi == lo + 1
    gv = {n: float(v) for n, v in given}
    assert gv[lo] < e < gv[hi]
    for n, v in given:
        assert abs(lg(n) - float(v)) < 6e-5
    gt = "、".join("log %d ≈ %s" % (n, v) for n, v in given)
    es = ("%g" % e)
    return item("xl_between", "log", 1, "10 的幾次方在哪裡", 1.0,
                "%s 10^{%s} 倍。這個倍數在哪兩個相鄰的整數之間？（%s）" % (ctx, es, gt),
                [ch("%s 夾在哪兩個 log 之間？" % es, ["log %d < %s < log %d" % (lo, es, hi), "log %d < %s < log %d" % (lo - 1, es, lo), "log %d < %s < log %d" % (hi, es, hi + 1),
                                                   "%d < %s < %d" % (lo, es, hi)],
                    "和題目給的 log 值比大小", "log %d ≈ %s < %s < log %d ≈ %s" % (lo, dict(given)[lo], es, hi, dict(given)[hi])),
                 fl("10^{x} 隨 x 變大而變大：", "[0] < 10^{%s} < [1]" % es, [str(lo), str(hi)], "10^{log n} = n")])


# ---------- xl_quad：log 的二次方程式 ----------

def xl_quad(s, p, q):
    """x^2 − s x + log p × log q = 0，log p + log q = s"""
    assert p * q == 10 ** s
    val = p + q
    r1, r2 = lg(p), lg(q)
    assert near(r1 + r2, s)
    return item("xl_quad", "log", 2, "log 的二次方程式", 1.15,
                "方程式 %s + log %d × log %d = 0 的兩根是 α、β，求 10^{α} + 10^{β}。" % (poly([(1, "x^{2}"), (-s, "x")]), p, q),
                [fl("先看 log %d + log %d：" % (p, q), "log %d + log %d = log %d = [0]" % (p, q, p * q), [str(s)], "log a + log b = log ab"),
                 ch("所以方程式可以因式分解成？", ["(x − log %d)(x − log %d) = 0" % (p, q), "(x + log %d)(x + log %d) = 0" % (p, q),
                                              "(x − %d)(x − %d) = 0" % (p, q), "(x − log %d)(x + log %d) = 0" % (p, q)],
                    "兩根的和是 %d、積是 log %d × log %d" % (s, p, q), "兩根是 log %d 和 log %d" % (p, q)),
                 fl("代回去：", "10^{α} + 10^{β} = 10^{log %d} + 10^{log %d} = [0]" % (p, q), [str(val)], "10^{log n} = n")])


# ---------- xl_value：log 的四則運算 ----------

def xl_value(terms, op, val):
    """terms = [(寫法, 值)] 四個，算 t0 × t1 op t2 × t3"""
    vs = [F(v) for _, v in terms]
    for (s_, v) in terms:
        x = eval_log(s_)
        assert near(x, float(v)), s_
    res = vs[0] * vs[1] + (vs[2] * vs[3] if op == "+" else -vs[2] * vs[3])
    assert res == F(val)
    expr = "%s × %s %s %s × %s" % (terms[0][0], terms[1][0], op, terms[2][0], terms[3][0])
    return item("xl_value", "log", 1, "log 的四則運算", 1.0,
                "求 %s 的值。" % expr,
                [fl("每一個 log 先算出來：", "%s = [0]，%s = [1]，%s = [2]，%s = [3]" % tuple(s_ for s_, _ in terms), [a(v) for v in vs],
                    "把真數寫成 10 的次方：√{10} = 10^{\\frac{1}{2}}，0.01 = 10^{−2}"),
                 fl("代進去：", "原式 = [0]", [a(res)], "先乘再%s" % ("加" if op == "+" else "減"))])


def eval_log(s):
    import re
    m = re.match(r"log (.*)", s)
    body = m.group(1)
    body = body.replace("√{", "math.sqrt(").replace("∛{", "cbrt(").replace("∜{", "qrt(").replace("}", ")")
    return lg(eval(body, {"math": math, "cbrt": lambda v: v ** (1 / 3), "qrt": lambda v: v ** 0.25}))


# ---------- xl_ratio：log 差幾 ----------

def xl_ratio(la, lb, ask, combo):
    """log a = la、log b = lb；ask = ("b/a" 或 "a/b")；combo = (係數 p, 係數 q, 符號) 求 pa ± qb 的科學記號"""
    A, B = 10.0 ** la, 10.0 ** lb
    if ask == "b/a":
        k = lb - la
        rq = "b 是 a 的幾倍"
        rt_ = "\\frac{b}{a} = 10^{log b − log a} = 10^{[0]} = [1]"
    else:
        k = la - lb
        rq = "a 是 b 的幾倍"
        rt_ = "\\frac{a}{b} = 10^{log a − log b} = 10^{[0]} = [1]"
    assert k == int(k) and k > 0
    p_, q_, sg = combo
    v = p_ * A + (q_ * B if sg > 0 else -q_ * B)
    m, e = sci(v, 6)
    m = m.rstrip("0").rstrip(".")
    assert near(float(m) * 10 ** e, v, 1e-9 * abs(v))
    ct = "%sa %s %sb" % ("" if p_ == 1 else p_, "+" if sg > 0 else "−", "" if q_ == 1 else q_)
    big = "b" if lb > la else "a"
    return item("xl_ratio", "log", 1, "log 差幾", 1.0,
                "log a = %s、log b = %s。(1) %s？ (2) 把 %s 寫成科學記號。" % (t(la), t(lb), rq, ct),
                [fl("log 相減就是相除：", rt_, [str(int(k)), str(10 ** int(k))], "log b − log a = log \\frac{b}{a}" if ask == "b/a" else "log a − log b = log \\frac{a}{b}"),
                 fl("a = 10^{%s}、b = 10^{%s}：" % (t(la), t(lb)), "%s = [0] × 10^{[1]}" % ct, [m, str(e)],
                    "%s = %s × 10^{%s} %s %s × 10^{%s}，提出 10^{%d}" % (ct, p_, t(la), "+" if sg > 0 else "−", q_, t(lb), e))])


# ---------- xl_digits：乘起來的位數 ----------

def xl_digits(la, lb, pa, pb, expr, form, mode):
    """log a、log b；求 a^{pa} b^{pb}（expr、form 是寫法）；mode = "digits"：整數部分幾位；"zeros"：小數點後第幾位開始不是 0"""
    L = pa * la + pb * lb
    Ls = dec(L, 2).rstrip("0").rstrip(".")
    assert near(float(Ls.replace("−", "-")), L)
    if mode == "digits":
        n = math.floor(L) + 1
        assert L > 0
        last = fl("所以 %s 的整數部分是幾位數？" % expr, "%s = 10^{%s}，整數部分是 [0] 位數" % (expr, Ls), [str(n)], "10^{%d} ≤ %s < 10^{%d}" % (n - 1, expr, n))
        q = "%s 的整數部分是幾位數？" % expr
    else:
        k = -math.floor(L)
        assert L < 0
        last = fl("%s < 1，從小數點後第幾位開始不是 0？" % expr, "%s = (%s) + %s，從小數點後第 [0] 位開始不是 0" % (Ls, t(-k), dec(L + k, 2).rstrip("0")), [str(k)],
                  "寫成 10^{小數} × 10^{−%d}，10^{小數} 在 1 到 10 之間" % k)
        q = "%s 從小數點後第幾位開始不是 0？" % expr
    return item("xl_digits", "log", 1, "乘起來的位數", 1.05,
                "log a = %s、log b = %s，%s" % (dec(la, 2).rstrip("0").rstrip("."), dec(lb, 2).rstrip("0").rstrip("."), q),
                [fl("取 log：", "log %s = %s = [0]" % (expr, form), [Ls], "log 的乘法變加法、次方變係數"), last])


# ---------- xl_system：兩個方程式解 a ----------

def xl_system(e1, r1, e2, r2, ask):
    """a^{e1[0]} b^{e1[1]} = 10^{r1}、a^{e2[0]} b^{e2[1]} = 10^{r2}"""
    (p1, q1), (p2, q2) = e1, e2
    d = p1 * q2 - p2 * q1
    x = F(r1 * q2 - r2 * q1, d)
    y = F(p1 * r2 - p2 * r1, d)
    assert p1 * x + q1 * y == r1 and p2 * x + q2 * y == r2
    def mono(p, q):
        return ("a" if p == 1 else "a^{%d}" % p) + ("b" if q == 1 else "b^{%d}" % q)
    name, val, how = ask
    v = how(x, y)
    return item("xl_system", "log", 2, "兩個方程式取 log", 1.15,
                "a、b 是正數，%s = 10^{%d}、%s = 10^{%d}，求 %s。" % (mono(p1, q1), r1, mono(p2, q2), r2, name),
                [fl("兩邊取 log，設 log a = x、log b = y：", "[0]x + [1]y = %d，[2]x + [3]y = %d" % (r1, r2), [str(p1), str(q1), str(p2), str(q2)], "log a^{m}b^{n} = m log a + n log b"),
                 fl("解聯立：", "x = [0]，y = [1]", [a(x), a(y)], "加減消去法"),
                 fl("換回 a、b：", "%s = [0]" % name, [v], "a = 10^{x}、b = 10^{y}")])


def items():
    return [
        [xl_between(0.8, 6, 7, [(6, "0.7782"), (7, "0.8451")], "甲溶液的鹹度是乙溶液的"),
         xl_between(0.45, 2, 3, [(2, "0.3010"), (3, "0.4771")], "某次地震釋放的能量是另一次的"),
         xl_between(1.3, 19, 20, [(19, "1.2788"), (20, "1.3010")], "一種細菌一天後的數量是原來的")],
        [xl_quad(1, 2, 5), xl_quad(2, 4, 25), xl_quad(3, 8, 125)],
        [xl_value([("log 1", 0), ("log √{1000}", F(3, 2)), ("log 100", 2), ("log √{10}", F(1, 2))], "+", 1),
         xl_value([("log 0.01", -2), ("log ∛{100}", F(2, 3)), ("log √{1000}", F(3, 2)), ("log 10", 1)], "−", F(-17, 6)),
         xl_value([("log ∜{10}", F(1, 4)), ("log 10000", 4), ("log 0.1", -1), ("log √{10}", F(1, 2))], "+", F(1, 2))],
        [xl_ratio(10, 13, "b/a", (3, 2, 1)), xl_ratio(7, 5, "a/b", (4, 5, -1)), xl_ratio(-3, 1, "b/a", (5, 1, 1))],
        [xl_digits(-1.2, 4.7, 2, 1, "a^{2}b", "2 log a + log b", "digits"), xl_digits(1.6, -0.9, 1, 3, "ab^{3}", "log a + 3 log b", "zeros"),
         xl_digits(2.25, 0.15, 3, -1, "\\frac{a^{3}}{b}", "3 log a − log b", "digits")],
        [xl_system((1, 3), 5, (3, 1), 3, ("a", None, lambda x, y: "√10" if x == F(1, 2) else a(10 ** x))),
         xl_system((2, 1), 4, (1, 3), 7, ("ab", None, lambda x, y: str(10 ** int(x + y)))),
         xl_system((3, 2), 8, (2, 3), 7, ("\\frac{a}{b}", None, lambda x, y: str(10 ** int(x - y))))],
    ]
