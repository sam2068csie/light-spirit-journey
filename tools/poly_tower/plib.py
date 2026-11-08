# 多項式的終焉之塔：多項式運算、式子格式、各種步驟
#   數字格式、選擇題／填空／審判卡的共用工具借用 tools/towerlib/lib.py。
import os, sys, math
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "towerlib"))   # 放最後：t_*.py 同名的要用這座塔自己的
from lib import *          # noqa: F401,F403  F、t、tf、tp、a、rt、Surd、poly、choice、fill、judge、card…
import numpy as np


class Poly:
    """係數由低次到高次（Fraction）"""

    def __init__(self, cs):
        cs = [F(c) for c in cs]
        while len(cs) > 1 and cs[-1] == 0:
            cs.pop()
        self.c = cs or [F(0)]

    @staticmethod
    def x():
        return Poly([0, 1])

    @staticmethod
    def lin(a_, b_):
        """ax + b"""
        return Poly([b_, a_])

    @staticmethod
    def roots(rs, lead=1):
        p = Poly([lead])
        for r in rs:
            p = p * Poly([-F(r), 1])
        return p

    def deg(self):
        return len(self.c) - 1

    def lead(self):
        return self.c[-1]

    def __add__(self, o):
        o = o if isinstance(o, Poly) else Poly([o])
        n = max(len(self.c), len(o.c))
        return Poly([(self.c[i] if i < len(self.c) else 0) + (o.c[i] if i < len(o.c) else 0) for i in range(n)])

    __radd__ = __add__

    def __neg__(self):
        return Poly([-c for c in self.c])

    def __sub__(self, o):
        return self + (-(o if isinstance(o, Poly) else Poly([o])))

    def __rsub__(self, o):
        return Poly([o]) - self

    def __mul__(self, o):
        o = o if isinstance(o, Poly) else Poly([o])
        out = [F(0)] * (len(self.c) + len(o.c) - 1)
        for i, a_ in enumerate(self.c):
            for j, b_ in enumerate(o.c):
                out[i + j] += a_ * b_
        return Poly(out)

    __rmul__ = __mul__

    def __pow__(self, n):
        p = Poly([1])
        for _ in range(n):
            p = p * self
        return p

    def divmod(self, d):
        r = Poly(self.c)
        q = [F(0)] * max(1, len(self.c) - len(d.c) + 1)
        while r.deg() >= d.deg() and not (r.deg() == 0 and r.c[0] == 0):
            k = r.deg() - d.deg()
            co = r.lead() / d.lead()
            q[k] = co
            r = r - Poly([0] * k + [co]) * d
        return Poly(q), r

    def __mod__(self, d):
        return self.divmod(d)[1]

    def __call__(self, x):
        v = F(0) if not isinstance(x, float) else 0.0
        for co in reversed(self.c):
            v = v * x + (co if not isinstance(x, float) else float(co))
        return v

    def compose(self, q):
        """self(q(x))"""
        out = Poly([0])
        for co in reversed(self.c):
            out = out * q + Poly([co])
        return out

    def shift(self, h):
        """self(x − h)"""
        return self.compose(Poly([-F(h), 1]))

    def __eq__(self, o):
        o = o if isinstance(o, Poly) else Poly([o])
        return self.c == o.c

    def text(self, v="x"):
        terms = []
        for i in range(len(self.c) - 1, -1, -1):
            if i == 0:
                terms.append((self.c[i], ""))
            elif i == 1:
                terms.append((self.c[i], v))
            else:
                terms.append((self.c[i], "%s^{%d}" % (v, i)))
        return poly(terms)

    def expr(self):
        """Godot Expression（畫圖用）"""
        out = []
        for i in range(len(self.c) - 1, -1, -1):
            co = self.c[i]
            if co == 0:
                continue
            cs = repr(float(co))
            if i == 0:
                out.append(cs)
            elif i == 1:
                out.append("%s*x" % cs)
            else:
                out.append("%s*pow(x,%d)" % (cs, i))
        return "+".join(out).replace("+-", "-") or "0"

    def real_roots(self):
        """實根（去掉重複，四捨五入）"""
        if self.deg() < 1:
            return []
        rs = np.roots([float(c) for c in reversed(self.c)])
        out = []
        for r in rs:
            if abs(r.imag) < 1e-7:
                x = round(r.real, 6)
                if all(abs(x - y) > 1e-5 for y in out):
                    out.append(x)
        return sorted(out)


X = Poly.x()


def fac(r, v="x"):
    """(x − r)、x、(x + 3)"""
    r = F(r)
    if r == 0:
        return v
    return "(%s %s %s)" % (v, M if r > 0 else "+", t(abs(r)))


def facp(r, m, v="x"):
    """(x − r)^{m}"""
    s = fac(r, v)
    if m == 1:
        return s
    if s == v:
        return "%s^{%d}" % (v, m)
    return "%s^{%d}" % (s, m)


def step(tp_, **kw):
    """任意步驟：sign、line、pick、roots…（choice、fill 用 lib 的）"""
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


def uniq(first, rest, n=4):
    out = list(first)
    for x in rest:
        if x not in out:
            out.append(x)
        if len(out) == n:
            break
    assert len(out) == n, out
    return out


def dec(x, nd=2):
    """小數（四捨五入，負號用 −）"""
    v = round(float(x) + (1e-12 if float(x) >= 0 else -1e-12), nd)
    s = ("%." + str(nd) + "f") % abs(v)
    return (M if v < 0 else "") + s


def sign_runs(p, marks):
    """p 在每一段的正負號（marks 由小到大）"""
    pts = [float(m) for m in marks]
    tests = [pts[0] - 1] + [(pts[i] + pts[i + 1]) / 2 for i in range(len(pts) - 1)] + [pts[-1] + 1]
    return [1 if p(x) > 0 else -1 for x in tests]


def solve_line(p, marks, op):
    """p(x) op 0 的解：seg、pt（line 步驟用）"""
    sg = sign_runs(p, marks)
    want = (lambda s: s > 0) if op in (">", "≥") else (lambda s: s < 0)
    seg = [1 if want(s) else 0 for s in sg]
    eq = op in ("≥", "≤")
    pt = [1 if eq else 0 for _ in marks]
    return sg, seg, pt


def grid(xr, yr, curves, pts=None, extra=None):
    d = {"x": [float(xr[0]), float(xr[1])], "y": [float(yr[0]), float(yr[1])], "curves": curves}
    if pts:
        d["pts"] = pts
    if extra:
        d.update(extra)
    return d


def g_small(solid, dashed="", xr=(-4.0, 4.0), yr=(-5.0, 5.0), solid2=""):
    """選圖題的小圖（和 poly_tower_bank.gd 的 _g 一樣）"""
    cs = []
    if dashed:
        cs.append({"f": dashed, "c": "dim", "dash": True})
    cs.append({"f": solid, "c": "cyan"})
    if solid2:
        cs.append({"f": solid2, "c": "pink", "dash": True})
    return {"x": [float(xr[0]), float(xr[1])], "y": [float(yr[0]), float(yr[1])], "curves": cs}


def pick(q, graphs, whys, hint, write):
    assert len(graphs) == len(whys)
    return {"t": "pick", "q": q, "graphs": graphs, "whys": whys, "hint": hint, "write": write}


def item(id_, kind, tier, title, tmul, stem, steps, plot=None, routes=None):
    d = {"id": id_, "kind": kind, "tier": tier, "title": title, "tmul": tmul, "stem": stem}
    if plot:
        d["plot"] = plot
    if routes:
        d["routes"] = routes
    d["steps"] = steps
    return d


def addp(s):
    """「 + 式子」：式子是負的開頭就寫成「 − …」"""
    return (" " + M + " " + s[1:]) if s.startswith(M) else (" + " + s)
