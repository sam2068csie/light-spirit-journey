"""V7 弓帆工坊（3-3 重點二、三：柯西不等式、三角不等式、面積公式）設計稿 docs/vec2_v7_design.md 的驗算。
執行：python3 tools/vec2/verify_v7.py（全部 assert 通過才會印出 OK）
根號的答案用平方比較（Fraction）。最小值、最大值都另外用密密的格子掃一遍，確定真的是極值。"""
from fractions import Fraction as F
from math import cos, sin, pi, sqrt, isclose
import random


def dot(a, b): return a[0] * b[0] + a[1] * b[1]
def det(a, b): return a[0] * b[1] - a[1] * b[0]
def sub(p, q): return (q[0] - p[0], q[1] - p[1])
def n2(v): return dot(v, v)
def area(P, Q, R): return abs(F(det(sub(P, Q), sub(P, R)), 2))


# ======== 第一章 柯西不等式與三角不等式 ========

# 1 弓弦（B30＋新）：|a| 固定，轉 |b| 固定的 b，內積的範圍
for a, rb, mx in [((5, 0), 3, 15), ((3, 4), 2, 10)]:
    la = sqrt(n2(a))
    vals = [dot(a, (rb * cos(t), rb * sin(t))) for t in [k * pi / 720 for k in range(1440)]]
    assert isclose(max(vals), mx, abs_tol=1e-3) and isclose(min(vals), -mx, abs_tol=1e-3) and max(vals) <= mx + 1e-9
    assert isclose(la * rb, mx)
# 第 2 組的轉盤從 \vec{a} 的方向開始，每 15° 一格：0° 就是最大
assert isclose(dot((3, 4), (1.2, 1.6)), 10) and isclose(sqrt(1.2 ** 2 + 1.6 ** 2), 2)

# 2 一次式求平方和的最小值（B27）
for (p, q, a, b, k), mn, P in [((2, 3, 2, 3, 10), 20, (2, 2)), ((1, 2, 1, -2, 9), 27, (3, -3))]:
    # (px² + qy²)(a²/p + b²/q) ≥ (ax + by)²
    w = F(a * a, p) + F(b * b, q)
    assert F(k * k) / w == mn
    assert a * P[0] + b * P[1] == k and p * P[0] ** 2 + q * P[1] ** 2 == mn
    # 沿著直線掃：真的是最小
    xs = [P[0] + F(i, 20) for i in range(-60, 61)]
    for x in xs:
        y = (k - a * x) / F(b)
        assert p * x * x + q * y * y >= mn
# 模板的兩格：第 1 組 (2x² + 3y²)(2 + 3)、第 2 組 (x² + 2y²)(1 + 2)
assert F(2 * 2, 2) + F(3 * 3, 3) == 2 + 3 and F(1, 1) + F(4, 2) == 1 + 2

# 3 先配方再用柯西（B28）
for (cx, cy, k0), (a, b, k), (h, kk), mn, P in [((-4, 2, 0), (1, 2, 10), (2, -1), 15, (4, 3)),
                                               ((6, -2, 0), (2, -1, 3), (-3, 1), 10, (1, -1))]:
    f = lambda x, y: x * x + y * y + cx * x + cy * y
    # 配方：(x − h)² + (y − kk)² − c0
    c0 = h * h + kk * kk
    for x in range(-5, 6):
        for y in range(-5, 6):
            assert f(x, y) == (x - h) ** 2 + (y - kk) ** 2 - c0
    # u = x − h、v = y − kk：au + bv = k − (ah + b·kk)
    kn = k - (a * h + b * kk)
    assert kn == 10
    assert F(kn * kn, a * a + b * b) - c0 == mn
    assert a * P[0] + b * P[1] == k and f(*P) == mn
    for i in range(-80, 81):
        x = P[0] + F(i, 20)
        y = (k - a * x) / F(b)
        assert f(x, y) >= mn
    # 幾何：到 (h, kk) 的距離平方，垂足就是 P
    t = F(k - a * h - b * kk, a * a + b * b)
    assert (h + a * t, kk + b * t) == P

# 4 圓上的弓（B29）：x² + y² = r²，內積的最小值
for (a0, b0), r2, mn, P in [(lambda x, y: 4 * x + 3 * y, None, -25, (-4, -3)),
                            (lambda x, y: x + 2 * y, None, -5, (-1, -2))][0:0]:
    pass
for f, r2, mn, P in [(lambda x, y: 4 * x + 3 * y, 25, -25, (-4, -3)), (lambda x, y: x + 2 * y, 5, -5, (-1, -2))]:
    pts = [(x, y) for x in range(-6, 7) for y in range(-6, 7) if x * x + y * y == r2]
    assert min(f(*q) for q in pts) == mn and [q for q in pts if f(*q) == mn] == [P]
    assert min(f(sqrt(r2) * cos(t), sqrt(r2) * sin(t)) for t in [k * pi / 3600 for k in range(7200)]) >= mn - 1e-9
# 第 1 組 \vec{a} = (x, 3)、\vec{b} = (4, y)：\vec{a} · \vec{b} = 4x + 3y；第 2 組 \vec{a} = (x, 2)、\vec{b} = (1, y)：x + 2y

# 5 直角的兩根竿子（B31）：P 在第一象限，A 在 x 軸正向、B 在 y 軸正向，\vec{PA} ⊥ \vec{PB}
for P, (ca, cb, k), mn2, A, B in [((3, 1), (3, 1, 10), 10, (3, 0), (0, 1)), ((1, 2), (1, 2, 5), 5, (1, 0), (0, 2))]:
    # \vec{PA} · \vec{PB} = 0 ⇔ ca·a + cb·b = k
    for a in range(-5, 12):
        for b in range(-5, 12):
            assert (dot(sub(P, (a, 0)), sub(P, (0, b))) == 0) == (ca * a + cb * b == k)
    assert F(k * k, ca * ca + cb * cb) == mn2 == n2(P)
    assert ca * A[0] + cb * B[1] == k and n2(sub(A, B)) == mn2
    # 滑桿：A = (a, 0)，a 每 0.25 一格，B 要在 y 軸正向
    best = min((a / 4 for a in range(1, 4 * k)), key=lambda a: a * a + ((k - ca * a) / cb) ** 2)
    assert best == A[0] and (k - ca * best) / cb > 0

# 6 倒數型（B32）
for (pa, pb, k), (u, v), mn, P in [((3, 1, 10), (3, 4), F(5, 2), (2, 4)), ((1, 1, 3), (1, 4), 3, (1, 2))]:
    # (u/a + v/b)(pa·a + pb·b) ≥ (√(u·pa) + √(v·pb))²
    s = sqrt(u * pa) + sqrt(v * pb)
    assert isclose(s * s / k, float(mn))
    a, b = P
    assert pa * a + pb * b == k and F(u, a) + F(v, b) == mn
    for i in range(1, 400):
        a = F(i, 400) * F(k, pa)
        b = (k - pa * a) / F(pb)
        if b > 0:
            assert F(u) / a + F(v) / b >= mn
# 模板：第 1 組 (\frac{3}{a} + \frac{4}{b})(3a + b) ≥ (3 + 2)²、第 2 組 (\frac{1}{a} + \frac{4}{b})(a + b) ≥ (1 + 2)²
assert (sqrt(3 * 3), sqrt(4 * 1)) == (3, 2) and (sqrt(1), sqrt(4)) == (1, 2)

# 7 不等式的審判（B33）：m、n 是任意實數，○ 卡用 2000 組亂數驗，✕ 卡有寫死的反例
random.seed(7)
R = [(random.uniform(-9, 9), random.uniform(-9, 9)) for _ in range(2000)] + [(0, 0), (1, 1), (-2, 3)]
cards1 = [
    (lambda m, n: (m * m + 4) * (9 + n * n) >= (3 * m + 2 * n) ** 2 - 1e-9, True),
    (lambda m, n: (m * m + 4) * (9 + n * n) >= (3 * m - 2 * n) ** 2 - 1e-9, True),
    (lambda m, n: sqrt(m * m + 4) + sqrt(9 + n * n) >= sqrt((m + 3) ** 2 + (2 + n) ** 2) - 1e-9, True),
    (lambda m, n: (m * m + 4) + (9 + n * n) >= (m + 3) ** 2 + (2 + n) ** 2 - 1e-9, False),
]
for f, ok in cards1:
    assert all(f(m, n) for m, n in R) == ok
assert not cards1[3][0](1, 1)                    # 反例 m = n = 1：15 < 25
cards2 = [
    (lambda m, n: (1 + m * m) * (n * n + 4) >= (n + 2 * m) ** 2 - 1e-9, True),
    (lambda m, n: 1 + m * m >= n * n + 4, False),
    (lambda m, n: sqrt(1 + m * m) * sqrt(n * n + 4) >= abs(2 * m - n) - 1e-9, True),
    (lambda m, n: sqrt(1 + m * m) + sqrt(n * n + 4) >= sqrt((1 + n) ** 2 + (m + 2) ** 2) - 1e-9, True),
]
for f, ok in cards2:
    assert all(f(m, n) for m, n in R) == ok
assert not cards2[1][0](0, 0)                    # 反例 m = n = 0：1 < 4

# 8 三角形裡的距離（B34）：P 在 \ol{BC} 上，到 AB、AC 的距離 x、y
# 第 1 組：A(0, 0)、B(3, 0)、C(0, 4)（AB = 3、AC = 4、BC = 5）：x = P 的 y 坐標、y = P 的 x 坐標
A, B, C = (0, 0), (3, 0), (0, 4)
assert area(A, B, C) == 6
mn = F(12 * 12, 3 * 3 + 4 * 4)
assert mn == F(144, 25)
k = F(9, 25)                                     # P = B + k(C − B)，滑桿每 0.04 一格
P = (3 - 3 * k, 4 * k)
assert P == (F(48, 25), F(36, 25)) and 3 * P[1] + 4 * P[0] == 12 and P[0] ** 2 + P[1] ** 2 == mn
assert dot(P, sub(B, C)) == 0                   # 就是 A 到 BC 的垂足
assert all((3 - 3 * F(i, 25)) ** 2 + (4 * F(i, 25)) ** 2 >= mn for i in range(26))
# 第 2 組：A(0, 4)、B(−3, 0)、C(3, 0)（AB = AC = 5、BC = 6，面積 12）：5x + 5y = 24
A, B, C = (0, 4), (-3, 0), (3, 0)
assert area(A, B, C) == 12 and n2(sub(A, B)) == 25 == n2(sub(A, C))
def dline(p, q, r):
    """r 到直線 pq 的距離平方"""
    return F(det(sub(p, q), sub(p, r)) ** 2, n2(sub(p, q)))
for i in range(0, 21):
    Pt = (-3 + F(6 * i, 20), 0)
    x2, y2 = dline(A, B, Pt), dline(A, C, Pt)
    assert x2 + y2 >= F(288, 25)
assert dline(A, B, (0, 0)) == F(144, 25) and F(24 * 24, 50) == F(288, 25)

# 9 半圓湖（B35）：直徑 AB，C 在半圓上，∠ACB = 90°，\ol{AC} = d cos θ、\ol{CB} = d sin θ
for d, v1, v2, (ca, cb), mx in [(10, 5, 12, (F(2), F(5, 6)), F(13, 6)), (6, 3, 4, (F(2), F(3, 2)), F(5, 2))]:
    assert (F(d, v1), F(d, v2)) == (ca, cb)
    assert ca * ca + cb * cb == mx * mx
    best = max(float(ca) * cos(t) + float(cb) * sin(t) for t in [k * pi / 3600 for k in range(1801)])
    assert isclose(best, float(mx), abs_tol=1e-5)


# ======== 第二章 面積公式 ========

# 11 張開的帆（新）：\frac{1}{2}√(|a|²|b|² − (a·b)²) = \frac{1}{2}|a₁b₂ − a₂b₁|
for a, b, (aa, bb, ab), ar in [((4, 1), (1, 3), (17, 10, 7), F(11, 2)), ((3, -1), (2, 2), (10, 8, 4), 4)]:
    assert (n2(a), n2(b), dot(a, b)) == (aa, bb, ab)
    assert F(aa * bb - ab * ab) == (2 * ar) ** 2
    assert abs(F(det(a, b), 2)) == ar

# 12 向量式求面積（B36）
for p, q, kind, x, ar in [(9, 25, "AC − 3AB", 9, 6), (169, 25, "AB − 3AC", 25, 30)]:
    if kind == "AC − 3AB":
        # |AC − 3AB|² = |AC + AB|²：q − 6x + 9p = q + 2x + p
        assert q - 6 * x + 9 * p == q + 2 * x + p
    else:
        assert p - 6 * x + 9 * q == p + 2 * x + q
    assert F(p * q - x * x) == (2 * ar) ** 2
# 畫得出來：第 1 組 |AB| = 3、|AC| = 5、cos A = \frac{3}{5}：AB = (3, 0)、AC = (3, 4)
assert dot((3, 0), (3, 4)) == 9 and n2((3, 4)) == 25 and abs(det((3, 0), (3, 4))) == 12
# 第 2 組 |AB| = 13、|AC| = 5、AB · AC = 25：AB = (13, 0)、AC = (\frac{25}{13}, \frac{60}{13})
ac = (F(25, 13), F(60, 13))
assert n2(ac) == 25 and dot((13, 0), ac) == 25 and abs(det((13, 0), ac)) == 60

# 13 坐標的帆（新）
for A, B, C, ar, tr in [((1, 1), (5, 2), (2, 4), F(11, 2), [(6, 5), (-2, 3), (4, -1)]),
                        ((-2, 1), (3, -1), (1, 3), 8, [(6, 1), (-4, 5), (-5, -1)])]:
    assert area(A, B, C) == ar
    for q in tr:
        assert area(A, B, q) == ar                 # 找光點：一樣高
    ab, ac = sub(A, B), sub(A, C)
    assert abs(F(det(ab, ac), 2)) == ar

# 14 面積的審判（B37、B38）
# 第 1 組：|a| = 3、|b| = 4、a · b = 6
aa, bb, ab = 9, 16, 6
assert 12 * 12 == 9 * 16                       # ① |4a| = |3b| = 12 ⇒ 4a + 3b 平分夾角 ○
assert F(aa * bb - ab * ab) == F(108) and F(108, 4) == F(27)   # ② 面積 \frac{1}{2}√108 = 3√3 ○（(3√3)² = 27）
assert aa + 2 * ab + bb == 37                  # ③ |c| = |a + b| = √37 ○
assert bb - F(ab * ab, aa) == 12               # ④ |ta + b| 最小值是 √12 = 2√3，不是 12 ✕
# 畫得出來：a = (3, 0)、b = (2, 2√3)
assert isclose(2 * 2 + 12, 16) and 3 * 2 == 6
# 第 2 組：A(1, 0)、B(7, 2)、C(3, 6)
A, B, C = (1, 0), (7, 2), (3, 6)
G = (F(A[0] + B[0] + C[0], 3), F(A[1] + B[1] + C[1], 3))
assert G == (F(11, 3), F(8, 3))                # ① ○
assert area(A, B, C) == 16                     # ② ○
ab, ac = sub(A, B), sub(A, C)
p1 = tuple(F(dot(ab, ac), n2(ac)) * c for c in ac)
p2 = tuple(F(dot(ab, ac), n2(ab)) * c for c in ab)
assert p1 == (F(6, 5), F(18, 5))               # ③ ○
assert p1 != p2 and n2(p1) == n2(p2)           # ④ ✕：一樣長，方向不同

# 15 外作正方形（B39）
def rot(v, s):  # s = 1 逆時針 90°，−1 順時針
    return (-s * v[1], s * v[0])
for OA, OB, ar in [(2, 3, F(21, 2)), (1, 4, 12)]:
    O, Ap, Bp = (0, 0), (OA, 0), (0, OB)
    C = (OA, -OA)                              # 正方形 OACD 往下
    Fp = (-OB, 0)                              # 正方形 OBEF 往左：O → B → E → F
    E = (-OB, OB)
    assert n2(sub(Ap, C)) == OA * OA and dot(sub(Ap, C), sub(O, Ap)) == 0
    assert n2(sub(Bp, E)) == OB * OB and n2(sub(E, Fp)) == OB * OB and dot(sub(Bp, E), sub(O, Bp)) == 0
    assert area(Bp, C, Fp) == ar

# 16 斜格子的面積（B40、B41）
# 第 1 組：A(1, 1)、B(3, 2)、C(2, 4)，0 ≤ x + y ≤ 1、0 ≤ y ≤ 2
ab, ac = (2, 1), (1, 3)
assert abs(det(ab, ac)) == 5
xy = 1 * 2                                     # 每一個 y，x 從 −y 到 1 − y（寬 1），y 從 0 到 2
assert xy * 5 == 10
# 第 2 組：A(1, 0)、B(2, 1)、C(0, 1)，−1 ≤ r ≤ 2、1 ≤ s ≤ 3
ab, ac = (1, 1), (-1, 1)
assert abs(det(ab, ac)) == 2 and 3 * 2 * 2 == 12
corners = [(1 + r * ab[0] + s * ac[0], 0 + r * ab[1] + s * ac[1]) for r in (-1, 2) for s in (1, 3)]
assert sorted(corners) == sorted([(-1, 0), (-3, 2), (2, 3), (0, 5)])

# 17 面積和夾角（新）：|a|、|b|、面積已知 ⇒ θ 有兩個
for la2, lb2, ar2, s2, ab2 in [(16, 9, 9, F(1, 4), 108), (16, 4, 8, F(1, 2), 32)]:
    # 面積² = \frac{1}{4}|a|²|b|² sin²θ
    assert F(4 * ar2, la2 * lb2) == s2
    # (a · b)² = |a|²|b|²(1 − sin²θ)：第 1 組 (6√3)² = 108、第 2 組 (4√2)² = 32
    assert la2 * lb2 * (1 - s2) == ab2
# 轉盤每 30°（第 1 組）、45°（第 2 組）一格：燈亮的位置剛好是 30°、150°、210°、330°（45°、135°、225°、315°）
for step, deg in [(30, [30, 150, 210, 330]), (45, [45, 135, 225, 315])]:
    lit = [d for d in range(0, 360, step) if isclose(abs(sin(d * pi / 180)), 0.5 if step == 30 else sqrt(2) / 2, abs_tol=1e-9)]
    assert lit == deg

print("OK")
