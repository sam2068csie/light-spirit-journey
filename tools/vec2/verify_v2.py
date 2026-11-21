"""V2 斜紋麥田（3-1 重點三、四）設計稿 docs/vec2_v2_design.md 的驗算。
執行：python3 tools/vec2/verify_v2.py（全部 assert 通過才會印出 OK）
向量用 \\vec{AB}、\\vec{AC} 的斜坐標 (x, y) 或直角坐標（Fraction）。"""
from fractions import Fraction as F
import math, random, itertools

def add(*vs): return tuple(sum(v[i] for v in vs) for i in range(2))
def mul(k, v): return (k * v[0], k * v[1])
def sub(p, q): return (q[0] - p[0], q[1] - p[1])
def cross(a, b): return a[0] * b[1] - a[1] * b[0]
def solve2(a1, b1, c1, a2, b2, c2):                     # a1 x + b1 y = c1, a2 x + b2 y = c2
    d = F(a1 * b2 - a2 * b1)
    return (F(c1 * b2 - c2 * b1) / d, F(a1 * c2 - a2 * c1) / d)
def rnd_pt(): return (F(random.randint(-9, 9)), F(random.randint(-9, 9)))

# ======== 第一章 ========
# 1 共線判斷：條件 ⇒ A、B、C 共線？（隨機 O、A、B，算出 C，看三點是否共線）
def collinear(A, B, C): return cross(sub(A, B), sub(A, C)) == 0
cards = {
    "AB=-2AC": (lambda O, A, B: add(A, mul(F(-1, 2), sub(A, B))), True),
    "OC=2OA+OB": (lambda O, A, B: add(O, mul(2, sub(O, A)), sub(O, B)), False),
    "2OA-3OB+OC=0": (lambda O, A, B: add(O, mul(-2, sub(O, A)), mul(3, sub(O, B))), True),
    "OA+OB+OC=0": (lambda O, A, B: add(O, mul(-1, sub(O, A)), mul(-1, sub(O, B))), False),
    "BC=1/2AB": (lambda O, A, B: add(B, mul(F(1, 2), sub(A, B))), True),
    "OC=1/3OA+2/3OB": (lambda O, A, B: add(O, mul(F(1, 3), sub(O, A)), mul(F(2, 3), sub(O, B))), True),
    "OC=1/2OA+1/3OB": (lambda O, A, B: add(O, mul(F(1, 2), sub(O, A)), mul(F(1, 3), sub(O, B))), False),
}
for name, (mk, ok) in cards.items():
    bad = 0
    for _ in range(500):
        O, A, B = rnd_pt(), rnd_pt(), rnd_pt()
        if cross(sub(O, A), sub(O, B)) == 0:
            continue
        C = mk(O, A, B)
        bad += collinear(A, B, C) != ok
    assert bad == 0, name
# |AB| + |BC| = |AC| ⇔ B 在 A、C 之間（共線）；|AB| = |AC| 不保證（等腰）
A, B, C = (0, 0), (3, 4), (6, 8)
assert math.dist(A, B) + math.dist(B, C) == math.dist(A, C) and collinear(A, B, C)
A, B, C = (0, 0), (3, 4), (5, 0)
assert math.dist(A, B) == math.dist(A, C) and not collinear(A, B, C)

# 2 P 在直線 BC 上 ⇒ x + y = 1；B'C'（B' = 2B、C' = 2C）上 ⇒ x + y = 2
for s in [F(-1, 2), F(1, 4), F(3, 2)]:
    x, y = 1 - s, s
    assert x + y == 1
    x, y = 2 * (1 - s), 2 * s
    assert x + y == 2

# 3 兩線交點
def inter_xy(c1, c2):  # 兩條「係數和 = 1」的式子：c1 = (p, q) 代表 p x + q y = 1
    return solve2(c1[0], c1[1], 1, c2[0], c2[1], 1)
# 變化 A：AD = 1/3 AB、AE = 1/2 AC、BQ : QC = 1 : 2，DE ∩ AQ
AQ = (F(2, 3), F(1, 3))
t = F(1) / (3 * AQ[0] + 2 * AQ[1])
assert (t * AQ[0], t * AQ[1]) == (F(1, 4), F(1, 8)) and t == F(3, 8)
# 變化 B：AD = 1/3 AB、AE = 3/4 AC，CD ∩ BE ⇒ 3x + y = 1、x + 4/3 y = 1
assert inter_xy((3, 1), (1, F(4, 3))) == (F(1, 9), F(2, 3))
# 變化 C：AD = 1/4 AB、AE = 2/3 AC，BE ∩ CD ⇒ 4x + y = 1、x + 3/2 y = 1
assert inter_xy((4, 1), (1, F(3, 2))) == (F(1, 10), F(3, 5))
# 用真的坐標再驗一次（交點）
def inter(p1, p2, p3, p4):
    d = cross(sub(p1, p2), sub(p3, p4)); t_ = F(cross(sub(p1, p3), sub(p3, p4))) / d
    return add(p1, mul(t_, sub(p1, p2)))
A, B, C = (F(0), F(0)), (F(6), F(0)), (F(2), F(5))
def coef(P):
    d = cross(B, C); return (F(cross(P, C)) / d, F(cross(B, P)) / d)
def at(x, y): return add(mul(x, B), mul(y, C))
assert coef(inter(at(F(1, 3), 0), at(0, F(1, 2)), A, at(F(2, 3), F(1, 3)))) == (F(1, 4), F(1, 8))
assert coef(inter(C, at(F(1, 3), 0), B, at(0, F(3, 4)))) == (F(1, 9), F(2, 3))
assert coef(inter(B, at(0, F(2, 3)), C, at(F(1, 4), 0))) == (F(1, 10), F(3, 5))

# 4 交點分線段的比
# 變化 A：BD : DC = 1 : 3、BE : EA = 1 : 2（AE = 2/3 AB），CE ∩ AD = F ⇒ AF : FD = 8 : 3
AD = (F(3, 4), F(1, 4))
t = F(1) / (AD[0] * F(3, 2) + AD[1])
assert t == F(8, 11)
D_ = at(*AD); E_ = at(F(2, 3), 0)
Fp = inter(C, E_, A, D_)
assert coef(Fp) == (t * AD[0], t * AD[1])
# 變化 B：平行四邊形 ABCD（u = AB、v = AD），BE : EC = 1 : 1、CF : FD = 1 : 2，DE ∩ AF = P ⇒ AP : PF = 3 : 4−3
u, v = (F(6), F(0)), (F(2), F(4))
Pa, Pb, Pd = (F(0), F(0)), u, v
Pc = add(u, v)
E_ = add(Pb, mul(F(1, 2), v)); F_ = add(Pc, mul(F(-1, 3), u))
P = inter(Pd, E_, Pa, F_)
assert math.isclose(math.dist(Pa, P) / math.dist(P, F_), 3.0)

# 5 孟氏定理（判斷）
for am, an, xy, bd_dc, ap_pd, bp_pn, cp_pm in [
        ((2, 1), (1, 1), (F(1, 2), F(1, 4)), (1, 2), (3, 1), (1, 1), (3, 1)),
        ((1, 1), (2, 1), (F(1, 4), F(1, 2)), (2, 1), (3, 1), (3, 1), (1, 1))]:
    M = at(F(am[0], sum(am)), 0); N = at(0, F(an[0], sum(an)))
    P = inter(B, N, C, M)
    assert coef(P) == xy
    assert inter_xy((F(sum(am), am[0]), 1), (1, F(sum(an), an[0]))) == xy
    D_ = inter(A, P, B, C)
    r = lambda p, q, s_: F(math.dist(p, q) / math.dist(q, s_)).limit_denominator(20)
    assert r(B, D_, C) == F(*bd_dc) and r(A, P, D_) == F(*ap_pd) and r(B, P, N) == F(*bp_pn) and r(C, P, M) == F(*cp_pm)

# 6 三角形內部：x > 0、y > 0、x + y < 1
for xk, yk, lo, hi in [(lambda k: (2 - k) / F(6), lambda k: F(1, 2), -1, 2), (lambda k: F(2, 5), lambda k: (k - 1) / F(5), 1, 4)]:
    for k10 in range(-60, 61):
        k = F(k10, 10)
        x, y = xk(k), yk(k)
        assert (x > 0 and y > 0 and x + y < 1) == (lo < k < hi)

# 7 菱形 OBCD 裡的 △BCD（斜坐標 u 沿 \vec{OA}、v 沿 \vec{OB}）
for m, plants in [(2, [((F(3, 2), F(1, 2)), "in"), ((F(1, 2), F(3, 4)), "edge"), ((F(1), F(1)), "edge")]),
                  (3, [((F(2), F(2, 3)), "in"), ((F(1), F(1, 2)), "out"), ((F(3, 2), F(1, 2)), "edge")])]:
    for (uu, vv), want in plants:
        f = uu / m + vv                        # BD：u / m + v = 1
        inside = uu < m and vv < 1 and f > 1
        edge = (f == 1 and 0 <= uu <= m) or (vv == 1 and 0 <= uu <= m) or (uu == m and 0 <= vv <= 1)
        got = "in" if inside else ("edge" if edge else "out")
        assert got == want, (m, uu, vv, got)

# 8 七個區域（號碼照 x、y、x + y − 1 的正負）
def region(x, y): return (x > 0, y > 0, x + y < 1)
assert region(F(1, 2), F(1, 5)) == (True, True, True)            # 三角形裡面
assert region(2, 1) == (True, True, False)
assert region(-1, -2) == (False, False, True)
assert region(F(-1, 2), 1) == (False, True, True)
assert region(3, -1) == (True, False, False)
assert region(F(1, 3), F(1, 3)) == (True, True, True)

# 9 區域的面積：一小格平行四邊形 = 2△ABC
for sides, area, xr, yr, total in [((5, 5, 6), 12, (-1, 2), (0, 2), 144), ((4, 3, 5), 6, (0, 3), (-1, 1), 72)]:
    a, b, c = sides
    s = F(a + b + c, 2)
    assert s * (s - a) * (s - b) * (s - c) == area * area
    assert (xr[1] - xr[0]) * (yr[1] - yr[0]) * 2 * area == total

# ======== 第二章 ========
# 11 p = x a + y b
for a, b, p, xy in [((2, 1), (-1, 2), (3, 4), (2, 1)), ((1, 3), (2, -1), (-1, 4), (1, -1))]:
    assert add(mul(xy[0], a), mul(xy[1], b)) == p

# 12 Q 是 \ol{AC} 中點，\vec{PC} = 2\vec{PQ} − \vec{PA}
for PA, PQ, k, BC in [((2, -1), (1, 1), 2, (0, 6)), ((1, -2), (1, 0), 3, (3, 6))]:
    PC = add(mul(2, PQ), mul(-1, PA))
    assert mul(k, PC) == BC                    # P 是中點：BC = 2PC；BP = 2CP：BC = 3PC

# 13 梯形：\vec{DC} 和 \vec{AB} 同方向，長 5
for A, B, C, D, Dbad in [((0, 0), (8, 6), (9, -1), (5, -4), (13, 2)), ((0, 0), (-6, 8), (2, 12), (5, 8), (-1, 16))]:
    ab = sub(A, B); L = math.hypot(*ab)
    assert L == 10 and sub(D, C) == (ab[0] / 2, ab[1] / 2) and math.dist(C, D) == 5 and math.dist(C, Dbad) == 5
    assert cross(sub(D, C), ab) == 0 and cross(sub(Dbad, C), ab) == 0
    # 好的 D：ABCD 是凸四邊形（每一個轉角同方向）
    def convex(Q):
        ss = [cross(sub(Q[i], Q[(i + 1) % 4]), sub(Q[(i + 1) % 4], Q[(i + 2) % 4])) for i in range(4)]
        return all(x > 0 for x in ss) or all(x < 0 for x in ss)
    assert convex([A, B, C, D]) and not convex([A, B, C, Dbad])

# 14 加權的零向量：w_A \vec{PA} + w_B \vec{PB} + w_C \vec{PC} = \vec{0} ⇒ P = 加權平均
for pts, w, P in [(((-4, 3), (2, -1), (4, 3)), (1, 2, 1), (1, 1)), (((1, 3), (-5, -1), (7, -5)), (2, 1, 1), (1, 0))]:
    tot = sum(w)
    assert tuple(F(sum(w[i] * pts[i][k] for i in range(3)), tot) for k in range(2)) == P
    assert add(*[mul(w[i], sub(P, pts[i])) for i in range(3)]) == (0, 0)

# 15 拼不出來（共線）
# 變化 A：A(2, 0)、B(0, 1)、C(k, 3)：\vec{AC} ∥ \vec{AB} ⇒ k = −4
k = -4
assert cross(sub((2, 0), (0, 1)), sub((2, 0), (k, 3))) == 0 and sub((2, 0), (k, 3)) == mul(3, sub((2, 0), (0, 1)))
assert [kk for kk in range(-20, 21) if cross(sub((2, 0), (0, 1)), sub((2, 0), (kk, 3))) == 0] == [-4]
# 變化 B：P(6 − 3t, 0)、Q(0, 8 − 2t)、R(2t, 2t)：t^{2} − 4t + 3 = 0 ⇒ t = 1、3
def cr(t):
    P_, Q_, R_ = (6 - 3 * t, 0), (0, 8 - 2 * t), (2 * t, 2 * t)
    return cross(sub(P_, Q_), sub(P_, R_))
for t in [F(1), F(3)]:
    assert cr(t) == 0
for t in [F(0), F(2), F(1, 2), F(5, 2), F(4)]:
    assert cr(t) != 0
for t in range(-5, 6):                             # cr(t) = 16(t^{2} − 4t + 3)
    assert cr(F(t)) == 16 * (t * t - 4 * t + 3)

# 16 由中點找頂點、重心
for A, B, C in [((1, 5), (-1, 1), (5, 1)), ((0, 6), (-4, 0), (6, 2))]:
    D = mul(F(1, 2), add(B, C)); E = mul(F(1, 2), add(C, A)); Fm = mul(F(1, 2), add(A, B))
    assert add(D, Fm, mul(-1, E)) == B
    G = mul(F(1, 3), add(D, E, Fm))
    assert G == mul(F(1, 3), add(A, B, C))
assert mul(F(1, 3), add((2, 1), (3, 3), (0, 3))) == (F(5, 3), F(7, 3))
assert mul(F(1, 3), add((1, 1), (3, 4), (-2, 3))) == (F(2, 3), F(8, 3))

# 17 |2\vec{PA} + \vec{PB}| 的最小值（P 在 x 軸上）= 3 × G 到 x 軸的距離
for A, B, G, m in [((4, 1), (-2, 4), (2, 2), 6), ((3, -2), (0, 7), (2, 1), 3)]:
    assert mul(F(1, 3), add(mul(2, A), B)) == G
    best = min(math.hypot(*add(mul(2, sub((x / 10, 0), A)), sub((x / 10, 0), B))) for x in range(-200, 201))
    assert math.isclose(best, m)

# 18 單位向量
for a, k, e in [((3, -4), F(1, 5), (F(3, 5), F(-4, 5))), ((-8, 6), F(1, 10), (F(-4, 5), F(3, 5)))]:
    assert mul(k, a) == e and e[0] ** 2 + e[1] ** 2 == 1

# 19 角平分向量：\frac{\vec{a}}{|\vec{a}|} + \frac{\vec{b}}{|\vec{b}|} 的倍數
for la, lb, opts, ok in [(4, 3, [(3, 4), (4, 3), (1, 1), (F(1, 3), F(1, 4))], 0), (2, 5, [(5, 2), (2, 5), (1, 1), (F(1, 5), F(1, 2))], 0)]:
    want = (F(1, la), F(1, lb))
    for i, o in enumerate(opts):
        assert (cross(o, want) == 0) == (i == ok)

# 20 坐標的分點
A, B = (4, -1), (-6, 4)
assert mul(F(1, 5), add(mul(2, A), mul(3, B))) == (-2, 2)                # \ol{AP} : \ol{PB} = 3 : 2，P 在 \ol{AB} 上
A, B = (-3, 2), (1, 4)
P = mul(F(1, 2), add(mul(3, B), mul(-1, A)))                              # P 在 B 外面，\ol{AP} : \ol{PB} = 3 : 1
assert P == (3, 5) and math.isclose(math.dist(A, P) / math.dist(P, B), 3)

print("OK")
