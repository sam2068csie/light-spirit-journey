# 直線與圓終焉之塔的出題工具：數字格式、式子格式、坐標圖
#   題目都寫成「模板函式 + 手挑的數字」：數字代進去，答案、提示、錯誤選項全部由程式算，
#   每一組數字都用 assert 檢查（答案漂亮、錯的選項一定錯、圖畫得下）。
from fractions import Fraction as Fr
import math

M = "−"


def F(x, d=None):
    if d is not None:
        return Fr(x, d)
    if isinstance(x, Fr):
        return x
    if isinstance(x, float):
        return Fr(x).limit_denominator(10000)
    return Fr(x)


def isint(x):
    return F(x).denominator == 1


# ---------------- 數字 ----------------

def t(x):
    """題目文字裡的數：3、−3、3/4、−3/4（a/b 會自動排成分數）"""
    x = F(x)
    s = M if x < 0 else ""
    x = abs(x)
    return s + (str(x.numerator) if x.denominator == 1 else "%d/%d" % (x.numerator, x.denominator))


def tf(x):
    """一定排成分數的寫法（用在算式中間）：\\frac{3}{4}"""
    x = F(x)
    s = M if x < 0 else ""
    x = abs(x)
    return s + (str(x.numerator) if x.denominator == 1 else "\\frac{%d}{%d}" % (x.numerator, x.denominator))


def a(x):
    """填空答案：3、−3、3/4"""
    return t(x)


def tp(x):
    """括號裡的負數加括號：(−3)"""
    return "(" + t(x) + ")" if F(x) < 0 else t(x)


class Surd:
    """c√n（n 沒有平方因數）"""

    def __init__(self, c, n):
        self.c = F(c)
        self.n = int(n)

    def val(self):
        return float(self.c) * math.sqrt(self.n)

    def sq(self):
        return self.c * self.c * self.n

    def _parts(self):
        c = self.c
        s = M if c < 0 else ""
        c = abs(c)
        return s, c.numerator, c.denominator

    def text(self):
        s, p, q = self._parts()
        if self.n == 1:
            return t(self.c)
        num = ("" if p == 1 else str(p)) + "√{%d}" % self.n
        return s + (num if q == 1 else "\\frac{%s}{%d}" % (num, q))

    def ans(self):
        s, p, q = self._parts()
        if self.n == 1:
            return a(self.c)
        num = ("" if p == 1 else str(p)) + "√%d" % self.n
        return s + (num if q == 1 else "%s/%d" % (num, q))

    def __eq__(self, o):
        return isinstance(o, Surd) and self.c == o.c and self.n == o.n


def rt(x):
    """√x 化簡成 Surd（x 是整數或分數）"""
    x = F(x)
    assert x >= 0
    p, q = x.numerator, x.denominator
    # √(p/q) = √(pq)/q
    m = p * q
    k = 1
    n = m
    i = 2
    while i * i <= n:
        while n % (i * i) == 0:
            n //= i * i
            k *= i
        i += 1
    if m == 0:
        return Surd(0, 1)
    return Surd(Fr(k, q), n)


def rtt(x):
    return rt(x).text()


def rta(x):
    return rt(x).ans()


def is_square(x):
    return rt(x).n == 1


# ---------------- 式子 ----------------

def term(c, v, first):
    c = F(c)
    ac = abs(c)
    if v and not isint(ac):
        body = "(" + t(ac) + ")" + v          # 分數係數加括號：(3/2)x
    else:
        body = ("" if (ac == 1 and v) else t(ac)) + v
    if first:
        return (M if c < 0 else "") + body
    return (" " + M + " " if c < 0 else " + ") + body


def poly(terms):
    """[(3, "x"), (−4, "y"), (12, "")] → 3x − 4y + 12"""
    out = ""
    for c, v in terms:
        if F(c) == 0:
            continue
        out += term(c, v, out == "")
    return out or "0"


def lin(a_, b_, c_):
    """ax + by + c = 0（係數 0 的省略）"""
    return poly([(a_, "x"), (b_, "y"), (c_, "")]) + " = 0"


def lin_norm(a_, b_, c_):
    """約分、讓第一個係數是正的"""
    vals = [F(a_), F(b_), F(c_)]
    den = 1
    for v in vals:
        den = den * v.denominator // math.gcd(den, v.denominator)
    ints = [int(v * den) for v in vals]
    g = 0
    for v in ints:
        g = math.gcd(g, abs(v))
    ints = [v // g for v in ints]
    lead = ints[0] if ints[0] != 0 else ints[1]
    if lead < 0:
        ints = [-v for v in ints]
    return tuple(ints)


def lin_n(a_, b_, c_):
    return lin(*lin_norm(a_, b_, c_))


def sh(v, h):
    """(x − h)；h = 0 時只寫 x"""
    h = F(h)
    if h == 0:
        return v
    return "(" + v + (" " + M + " " if h > 0 else " + ") + t(abs(h)) + ")"


def circ_eq(h, k, r2):
    return sh("x", h) + "^{2} + " + sh("y", k) + "^{2} = " + t(r2)


def cx(m, v="x"):
    """mx：分數寫成 (3/4)x、−(4/3)x"""
    m = F(m)
    if isint(m):
        return poly([(m, v)])
    return (M if m < 0 else "") + "(" + t(abs(m)) + ")" + v


def P(x, y):
    return "(" + t(x) + ", " + t(y) + ")"


def slope_int(m, k):
    """y = mx + k"""
    return "y = " + poly([(m, "x"), (k, "")])


# ---------------- 坐標圖 ----------------

def _f(x):
    x = float(x)
    r = round(x, 4)
    return int(r) if r == int(r) else r


def pp(p):
    return [_f(p[0]), _f(p[1])]


def ln(a_, b_, c_, xr, yr, col="cyan", **extra):
    a_, b_, c_ = float(a_), float(b_), float(c_)
    pts = []
    if abs(b_) > 1e-9:
        for x in (xr[0], xr[1]):
            y = -(a_ * x + c_) / b_
            if yr[0] - 1e-9 <= y <= yr[1] + 1e-9:
                pts.append([x, y])
    if abs(a_) > 1e-9:
        for y in (yr[0], yr[1]):
            x = -(b_ * y + c_) / a_
            if xr[0] + 1e-9 < x < xr[1] - 1e-9:
                pts.append([x, y])
    assert len(pts) >= 2, ("直線畫不進框", a_, b_, c_, xr, yr)
    d = {"k": "seg", "a": pp(pts[0]), "b": pp(pts[1]), "c": col}
    d.update(extra)
    return d


def seg(p, q, col="cyan", **extra):
    d = {"k": "seg", "a": pp(p), "b": pp(q), "c": col}
    d.update(extra)
    return d


def pt(p, s="", col="gold", at=0, off=(8, -8)):
    d = {"k": "dot", "p": pp(p), "s": s, "c": col, "off": [off[0], off[1]]}
    if at > 0:
        d["at"] = at
    return d


def lab(p, s, col="text", at=0):
    d = {"k": "label", "p": pp(p), "s": s, "c": col}
    if at > 0:
        d["at"] = at
    return d


def circ(o, r, col="pink", **extra):
    d = {"k": "circle", "o": pp(o), "r": _f(r), "c": col}
    d.update(extra)
    return d


def poly_sh(pts, col="cyan", **extra):
    d = {"k": "poly", "pts": [pp(p) for p in pts], "c": col}
    d.update(extra)
    return d


def geo(xr, yr, shapes):
    return {"x": [_f(xr[0]), _f(xr[1])], "y": [_f(yr[0]), _f(yr[1])], "geo": True, "axes": True, "grid": 1, "shapes": shapes}


def box(points, pad=1.2, circles=(), minw=6.0, ratio=None):
    """把所有點、圓都框進去的範圍（四捨五入到 0.2）"""
    xs = [float(p[0]) for p in points]
    ys = [float(p[1]) for p in points]
    for (o, r) in circles:
        xs += [float(o[0]) - r, float(o[0]) + r]
        ys += [float(o[1]) - r, float(o[1]) + r]
    x0, x1 = min(xs + [0]) - pad, max(xs + [0]) + pad
    y0, y1 = min(ys + [0]) - pad, max(ys + [0]) + pad
    if x1 - x0 < minw:
        c = (x0 + x1) / 2
        x0, x1 = c - minw / 2, c + minw / 2
    if y1 - y0 < minw:
        c = (y0 + y1) / 2
        y0, y1 = c - minw / 2, c + minw / 2
    r5 = lambda v: round(v * 5) / 5
    return [r5(x0), r5(x1)], [r5(y0), r5(y1)]


# ---------------- 步驟 ----------------

def choice(q, opts, hint, write, part=None):
    assert len(opts) == len(set(opts)), ("選項重複", opts)
    d = {"t": "choice", "q": q, "opts": list(opts), "hint": hint, "write": write}
    if part:
        d = {"part": part, **d}
    return d


def fill(q, template, ans, hint, part=None):
    for i in range(len(ans)):
        assert "[%d]" % i in template, template
    d = {"t": "fill", "q": q, "template": template, "ans": [str(x) for x in ans], "hint": hint}
    if part:
        d = {"part": part, **d}
    return d


def judge(q, cards):
    assert 2 <= sum(1 for c in cards if c["ok"]) <= len(cards) - 1, "審判要有真有假"
    return {"t": "judge", "q": q, "cards": cards}


def card(s, ok, why):
    return {"s": s, "ok": ok, "why": why}


def distinct(*xs):
    assert len(xs) == len(set(xs)), ("應該都不一樣", xs)
