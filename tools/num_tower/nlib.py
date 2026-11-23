# 數與式（高一上）的終焉之塔：共用工具
#   a + b√n、數值驗算、審判卡、步驟借用 tools/towerlib/tlib.py（它再借同資料夾的 lib.py）。
import os, sys, math
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "towerlib"))   # 放最後：t_*.py 同名的要用這座塔自己的
from tlib import *          # noqa: F401,F403


def rep(ip, nonrep, cyc):
    """循環小數 ip.nonrep\\ol{cyc} 的分數值"""
    n, c = len(nonrep), len(cyc)
    whole = int(nonrep + cyc) - (int(nonrep) if nonrep else 0)
    return F(ip) + F(whole, (10 ** c - 1) * 10 ** n)


def rep_t(ip, nonrep, cyc):
    return "%d.%s\\ol{%s}" % (ip, nonrep, cyc)


def digit(x, k):
    """x 的小數點後第 k 位"""
    x = F(x)
    return (x.numerator * 10 ** k // x.denominator) % 10


def finite(x):
    """約分後分母只有 2、5"""
    d = F(x).denominator
    for p in (2, 5):
        while d % p == 0:
            d //= p
    return d == 1


def ints_in(lo, hi, lo_in=True, hi_in=True):
    out = []
    for v in range(math.floor(lo) - 1, math.ceil(hi) + 2):
        if (v > lo or (lo_in and v == lo)) and (v < hi or (hi_in and v == hi)):
            out.append(v)
    return out


# ---------- 分段的一次式：sum c|x − u| + rx + s ----------

class Pw:
    def __init__(self, absts, r=0, s=0):
        """absts = [(c, u)]：c|x − u|"""
        self.absts = [(F(c), F(u)) for c, u in absts]
        self.r, self.s = F(r), F(s)

    def __call__(self, x):
        x = F(x)
        return sum(c * abs(x - u) for c, u in self.absts) + self.r * x + self.s

    def cuts(self):
        return sorted(set(u for c, u in self.absts))

    def on(self, x):
        """x 所在那一段的 (斜率, 截距)"""
        x = F(x)
        al = self.r
        be = self.s
        for c, u in self.absts:
            sg = 1 if x >= u else -1
            al += c * sg
            be -= c * sg * u
        return al, be


def lin_t(al, be, v="x"):
    return poly([(al, v), (be, "")])


def nl_plot(xr, shapes, h=110):
    """數線圖：只有一條橫軸（不畫格線）"""
    x0, x1 = xr
    base = [{"k": "seg", "a": [fx(x0), 0], "b": [fx(x1), 0], "c": "dim", "w": 2.0}]
    return {"x": [fx(x0), fx(x1)], "y": [-1.0, 1.0], "geo": True, "h": h, "shapes": base + shapes}


def _dot(x, closed, col, span):
    if closed:
        return [{"k": "dot", "p": [fx(x), 0], "s": t(x), "c": col, "off": [-6, 24]}]
    return [{"k": "circle", "o": [fx(x), 0], "r": fx(span * 0.018), "c": col, "w": 2.0},
            {"k": "label", "p": [fx(x), 0], "s": t(x), "c": col, "off": [0, 22]}]


def ray(x, right, closed, xr, col="cyan"):
    span = xr[1] - xr[0]
    end = xr[1] if right else xr[0]
    a_ = x + (span * 0.018 if (right and not closed) else (-span * 0.018 if not closed else 0))
    return [{"k": "seg", "a": [fx(a_), 0], "b": [fx(end), 0], "c": col, "w": 5.0}] + _dot(x, closed, col, span)


def band(x0, x1, c0, c1, xr, col="cyan"):
    span = xr[1] - xr[0]
    e = span * 0.018
    return ([{"k": "seg", "a": [fx(x0 + (0 if c0 else e)), 0], "b": [fx(x1 - (0 if c1 else e)), 0], "c": col, "w": 5.0}]
            + _dot(x0, c0, col, span) + _dot(x1, c1, col, span))


def qf(x):
    """a + b√n 寫成一個分數：\\frac{5 + √{21}}{2}"""
    x = Q.of(x)
    den = x.a.denominator * x.b.denominator // math.gcd(x.a.denominator, x.b.denominator)
    num = Q(x.a * den, x.b * den, x.n).text()
    return num if den == 1 else "\\frac{%s}{%d}" % (num, den)


def order_opts(names, vals):
    """由大到小排列的選項：正確的、倒過來、前兩個對調、後兩個對調"""
    idx = sorted(range(len(vals)), key=lambda i: -float(vals[i]))
    assert len(set(round(float(v), 9) for v in vals)) == len(vals)
    s = lambda ix: " > ".join(names[i] for i in ix)
    return uniq([s(idx)], [s(idx[::-1]), s([idx[1], idx[0], idx[2]]), s([idx[0], idx[2], idx[1]]), s([idx[2], idx[0], idx[1]])], 4)


def sf(x):
    """a + b√n 把根號寫在前面：√{5} − 2（a < 0 < b 的時候）"""
    x = Q.of(x)
    if x.a != 0 and x.b > 0:
        return "%s %s %s" % (Q(0, x.b, x.n).text(), "−" if x.a < 0 else "+", t(abs(x.a)))
    return x.text()
