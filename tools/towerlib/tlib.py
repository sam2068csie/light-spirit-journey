# 終焉之塔的共用出題工具（第二層）：角（π 的倍數）、特別角的值、a + b√n、數值驗算、審判卡
#   最早給三角函數的塔用，指數與對數的塔也在用。底層的數字格式、選擇題／填空借用同資料夾的 lib.py。
import math, re
from lib import *          # noqa: F401,F403
from lib import _f         # noqa: F401

PI = math.pi
S2, S3 = math.sqrt(2), math.sqrt(3)


# ---------------- 角：π 的倍數 ----------------

def pt_(k):
    """k 是 π 的倍數：0、π、−π、π/6、5π/6、2π、3π/2"""
    k = F(k)
    if k == 0:
        return "0"
    s = M if k < 0 else ""
    k = abs(k)
    p, q = k.numerator, k.denominator
    num = ("" if p == 1 else str(p)) + "π"
    return s + (num if q == 1 else "%s/%d" % (num, q))


def ptp(k):
    """加括號的負角：(−π/6)"""
    return "(" + pt_(k) + ")" if F(k) < 0 else pt_(k)


def deg(k):
    """π 的倍數換成度"""
    return F(k) * 180


# ---------------- a + b√n ----------------

def _sqfree(n):
    k, m, i = 1, n, 2
    while i * i <= m:
        while m % (i * i) == 0:
            m //= i * i
            k *= i
        i += 1
    return k, m


class Q:
    """a + b√n（n 沒有平方因數；n = 1 就是有理數）"""

    def __init__(self, a_=0, b_=0, n=1):
        a_, b_ = F(a_), F(b_)
        if n != 1:
            k, n = _sqfree(n)
            b_ *= k
        if n == 1:
            a_, b_ = a_ + b_, F(0)
        if b_ == 0:
            n = 1
        self.a, self.b, self.n = a_, b_, n

    @staticmethod
    def of(x):
        return x if isinstance(x, Q) else Q(x)

    @staticmethod
    def sqrt(x):
        """√x（x 是有理數）"""
        s = rt(x)
        return Q(0, s.c, s.n)

    def _n(self, o):
        if self.n == 1:
            return o.n
        if o.n == 1:
            return self.n
        assert self.n == o.n, ("根號不一樣", self.n, o.n)
        return self.n

    def __add__(self, o):
        o = Q.of(o)
        return Q(self.a + o.a, self.b + o.b, self._n(o))

    __radd__ = __add__

    def __neg__(self):
        return Q(-self.a, -self.b, self.n)

    def __sub__(self, o):
        return self + (-Q.of(o))

    def __rsub__(self, o):
        return Q.of(o) - self

    def __mul__(self, o):
        o = Q.of(o)
        if self.b != 0 and o.b != 0 and self.n != o.n:
            # √m √n = √(mn)，只允許兩個都是純根號
            assert self.a == 0 and o.a == 0, "混合根號相乘"
            s = rt(self.n * o.n)
            return Q(0, self.b * o.b * s.c, s.n)
        n = self._n(o)
        return Q(self.a * o.a + self.b * o.b * n, self.a * o.b + self.b * o.a, n)

    __rmul__ = __mul__

    def conj(self):
        return Q(self.a, -self.b, self.n)

    def __truediv__(self, o):
        o = Q.of(o)
        if o.b == 0:
            return Q(self.a / o.a, self.b / o.a, self.n)
        if self.b != 0 and self.n != o.n:
            assert self.a == 0 and o.a == 0
            s = rt(F(self.n, o.n))
            return Q(0, self.b / o.b * s.c, s.n)
        d = o.a * o.a - o.b * o.b * o.n
        num = self * o.conj()
        return Q(num.a / d, num.b / d, num.n)

    def __rtruediv__(self, o):
        return Q.of(o) / self

    def __pow__(self, k):
        r = Q(1)
        for _ in range(k):
            r = r * self
        return r

    def __float__(self):
        return float(self.a) + float(self.b) * math.sqrt(self.n)

    def __eq__(self, o):
        o = Q.of(o)
        return self.a == o.a and self.b == o.b and (self.b == 0 or self.n == o.n)

    def __hash__(self):
        return hash((self.a, self.b, self.n))

    def __lt__(self, o):
        return float(self) < float(o)

    def __gt__(self, o):
        return float(self) > float(o)

    def __le__(self, o):
        return float(self) <= float(o)

    def __ge__(self, o):
        return float(self) >= float(o)

    def rat(self):
        return self.b == 0

    def _surd(self, braces):
        """b√n 的寫法：2√3、√3/2、−2√2/3"""
        b_ = self.b
        s = M if b_ < 0 else ""
        b_ = abs(b_)
        p, q = b_.numerator, b_.denominator
        r = ("√{%d}" if braces else "√%d") % self.n
        num = ("" if p == 1 else str(p)) + r
        return s + (num if q == 1 else "%s/%d" % (num, q))

    def text(self):
        """題目文字：√{3}/2、1 + √{2}、−2√{3}"""
        if self.b == 0:
            return t(self.a)
        sv = self._surd(True)
        if self.a == 0:
            return sv
        return t(self.a) + (" − " + sv[1:] if sv.startswith(M) else " + " + sv)

    def ans(self):
        """填空答案：√3/2、−2√2/3（只能是單項）"""
        assert self.a == 0 or self.b == 0, ("答案不能是兩項", self.text())
        if self.b == 0:
            return a(self.a)
        return self._surd(False)

    def lab(self):
        """圖上的標籤：√3、2√3"""
        return self.ans() if (self.a == 0 or self.b == 0) else self.text().replace("{", "").replace("}", "")

    def tp(self):
        s = self.text()
        return "(" + s + ")" if (s.startswith(M) or (self.a != 0 and self.b != 0)) else s


def qt(x):
    return Q.of(x).text()


def qa(x):
    return Q.of(x).ans()


# ---------------- 特別角 ----------------

def sv(k):
    """sin(kπ)，k 的分母是 1、2、3、4、6"""
    k = F(k) % 2
    d = k.denominator
    assert d in (1, 2, 3, 4, 6), ("不是特別角", k)
    ref = k if k <= F(1, 2) else (1 - k if k <= 1 else (k - 1 if k <= F(3, 2) else 2 - k))
    sgn = 1 if k <= 1 else -1
    base = {F(0): Q(0), F(1, 6): Q(F(1, 2)), F(1, 4): Q(0, F(1, 2), 2), F(1, 3): Q(0, F(1, 2), 3), F(1, 2): Q(1)}[ref]
    r = base * sgn
    assert abs(float(r) - math.sin(float(F(k)) * PI)) < 1e-9
    return r


def cv(k):
    return sv(F(k) + F(1, 2))


def tv(k):
    return sv(k) / cv(k)


# ---------------- 驗算 ----------------

_SURD = re.compile(r"(\d*)√\{?(\d+)\}?")


def num(s):
    """答案字串的值：−2√3/3、5/6、√{2}"""
    s = str(s).replace(M, "-").replace(" ", "")
    s = _SURD.sub(lambda m: "(%s*math.sqrt(%s))" % (m.group(1) or "1", m.group(2)), s)
    return float(eval(s, {"math": math}))


def chk(ans, val, tol=1e-7):
    """填空答案和算出來的值一樣"""
    if isinstance(ans, (list, tuple)):
        assert len(ans) == len(val), (ans, val)
        for x, y in zip(ans, val):
            chk(x, y, tol)
        return
    assert abs(num(ans) - float(val)) < tol, ("答案不對", ans, float(val))


def near(x, y, tol=1e-7):
    return abs(float(x) - float(y)) < tol


def cardc(s, ok, why, truth):
    """審判卡：ok 要和程式算出來的 truth 一樣"""
    assert bool(ok) == bool(truth), ("審判卡的真假不對", s)
    return card(s, ok, why)


def roots_in(f, lo, hi, n=200000):
    """f 在 [lo, hi] 的根（數值，數變號 + 碰到 0）"""
    out = []
    step_ = (hi - lo) / n
    prev = f(lo)
    if abs(prev) < 1e-12:
        out.append(lo)
    x0 = lo
    for i in range(1, n + 1):
        x1 = lo + i * step_
        cur = f(x1)
        if abs(cur) < 1e-12:
            out.append(x1)
        elif prev * cur < 0 and abs(prev) > 1e-12:
            a_, b_ = x0, x1
            for _ in range(60):
                m = (a_ + b_) / 2
                if f(a_) * f(m) <= 0:
                    b_ = m
                else:
                    a_ = m
            out.append((a_ + b_) / 2)
        prev, x0 = cur, x1
    res = []
    for r in out:
        if all(abs(r - y) > 1e-6 for y in res):
            res.append(r)
    return res


def ext(f, lo, hi, n=20000):
    """f 在 [lo, hi] 的 (最小, 最大)（數值）"""
    vs = [f(lo + (hi - lo) * i / n) for i in range(n + 1)]
    return min(vs), max(vs)


# ---------------- 步驟 ----------------

def step(tp_, **kw):
    d = {"t": tp_}
    d.update(kw)
    return d


def ch(q, opts, hint, write, **kw):
    d = choice(q, opts, hint, write)
    for k, v in kw.items():
        d[k] = v
    return d


def fl(q, template, ans, hint, **kw):
    d = fill(q, template, ans, hint)
    for k, v in kw.items():
        d[k] = v
    return d


def jd(q, cards):
    return judge(q, cards)


def uniq(first, rest, n=4):
    out = list(first)
    for x in rest:
        if x not in out:
            out.append(x)
        if len(out) == n:
            break
    assert len(out) == n, out
    return out


def pick(q, graphs, whys, hint, write):
    assert len(graphs) == len(whys)
    return {"t": "pick", "q": q, "graphs": graphs, "whys": whys, "hint": hint, "write": write}


def gsm(solid, dashed="", xr=(-0.6, 6.9), yr=(-3.0, 3.0)):
    """選圖題的小圖：虛線（題目給的）＋實線（選項），橫軸用 π 當刻度"""
    cs = []
    if dashed:
        cs.append({"f": dashed, "c": "dim", "dash": True})
    cs.append({"f": solid, "c": "cyan"})
    return {"x": [_f(xr[0]), _f(xr[1])], "y": [_f(yr[0]), _f(yr[1])], "pi": 2, "curves": cs}


def item(id_, kind, tier, title, tmul, stem, steps, plot=None):
    d = {"id": id_, "kind": kind, "tier": tier, "title": title, "tmul": tmul, "stem": stem}
    if plot:
        d["plot"] = plot
    d["steps"] = steps
    return d


def fx(x):
    """圖上的數字（四捨五入到 4 位）"""
    return _f(x)


def ex(s):
    """把 Godot 式子裡的 PI 換成數值後算出 f(x)（驗算畫的圖）"""
    code = s.replace("PI", repr(PI)).replace("pow", "math.pow")
    for fn in ("sin", "cos", "tan", "sqrt", "abs"):
        code = re.sub(r"(?<![a-z.])%s\(" % fn, ("math.%s(" % fn) if fn != "abs" else "abs(", code)
    return lambda x: eval(code, {"math": math, "x": x, "abs": abs})


def cof(c, v, first=False):
    """係數 × 項：1 不寫、−1 寫 −；c 可以是 Q"""
    c = Q.of(c)
    if c.rat():
        ac = abs(c.a)
        co = "" if (ac == 1 and v) else t(ac)
        body = co + (" " if co and v[:3] in ("sin", "cos", "tan") else "") + v
        if first:
            return (M if c.a < 0 else "") + body
        return (" " + M + " " if c.a < 0 else " + ") + body
    s = c.text()
    if c.a != 0:
        s = "(" + s + ")"
        return (s if first else " + " + s) + (" " + v if v else "")
    neg = s.startswith(M)
    body = s[1:] if neg else s
    body = body + (" " + v if v else "")
    if first:
        return (M if neg else "") + body
    return (" " + M + " " if neg else " + ") + body


def lin_tr(terms):
    """[(Q 或數, "sin x"), …] → √{3} sin x − cos x"""
    out = ""
    for c, v in terms:
        if float(Q.of(c)) == 0 and Q.of(c) == 0:
            continue
        out += cof(c, v, out == "")
    return out or "0"


def evq(a_, b_, c_, x):
    """a x² + b x + c 代入有理數 x 的算式：−1/4 + 3/2 + 3"""
    x = F(x)
    parts = [F(a_) * x * x, F(b_) * x, F(c_)]
    out = ""
    for i, v in enumerate(parts):
        if v == 0 and (i == 2 or (F(a_) if i == 0 else F(b_)) == 0):
            continue
        if out == "":
            out = t(v)
        else:
            out += (" + " if v >= 0 else " − ") + t(abs(v))
    return out
