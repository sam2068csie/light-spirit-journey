"""V8 雙線織坊（3-3 重點四：二階行列式與克拉瑪法則）設計稿 docs/vec2_v8_design.md 的驗算。
執行：python3 tools/vec2/verify_v8.py（全部 assert 通過才會印出 OK）
審判卡的 ○ 用亂數驗過（行列式的性質對任何 a、b、c、d 都成立），✕ 卡都有寫死的反例。"""
from fractions import Fraction as F
from math import sqrt, isclose
import random

random.seed(20261122)


def det(a, b, c, d): return a * d - b * c
def vdet(u, v): return u[0] * v[1] - u[1] * v[0]
def add(u, v, p=1, q=1): return (p * u[0] + q * v[0], p * u[1] + q * v[1])


def solve(a1, b1, c1, a2, b2, c2):
    """a1x + b1y = c1、a2x + b2y = c2：一組解回傳 (x, y)，不然回傳 'inf' 或 'none'"""
    D = det(a1, b1, a2, b2)
    Dx = det(c1, b1, c2, b2)
    Dy = det(a1, c1, a2, c2)
    if D:
        return (F(Dx, D), F(Dy, D))
    return "inf" if Dx == 0 and Dy == 0 else "none"


def rnd():
    return [random.randint(-20, 20) for _ in range(4)]


# ======== 第一章 二階行列式 ========

# 1 張開的布：行列式、翻面的例子、壓扁的例子
for a, b, D, neg, zero in [((3, 1), (1, 2), 5, (2, -1), (-3, -1)), ((2, 3), (-1, 2), 7, (1, -2), (-2, -3))]:
    assert vdet(a, b) == D and vdet(a, neg) == -D and vdet(a, zero) == 0

# 2 大數字、根號
assert det(198, 205, 202, 195) == -2800 == (200 - 2) * (200 - 5) - (200 + 5) * (200 + 2)
assert 40000 - 1400 + 10 - (40000 + 1400 + 10) == -2800
r2 = sqrt(2)
assert isclose((3 + r2) * (3 - r2) - 2 * r2 * r2, 3) and isclose((3 + r2) * (3 - r2), 7) and isclose(2 * r2 * r2, 4)

# 3 整數的織法：(a, b) 的組數
for m0, m1, v, pts in [(3, 4, 6, [(1, 6), (2, 3), (3, 2), (6, 1)]), (2, 9, 9, [(1, 9), (3, 3), (9, 1)])]:
    sols = [(x, y) for x in range(-40, 41) for y in range(-40, 41) if det(m0, x, y, m1) == v]
    assert sorted(p for p in sols if p[0] > 0) == sorted(pts) and len(sols) == 2 * len(pts)

# 4 拉長、推斜的布：推斜不變、係數的行列式
u, v = (2, 1), (-1, 2)
for k in [-2, -1.5, 0, 0.5, 2]:
    assert isclose(vdet(u, add(v, u, 1, k)), vdet(u, v))
assert vdet(u, v) == 5 and vdet(add(u, v, 2, 1), add(u, v, 1, -3)) == -35
for _ in range(500):
    a, b, c, d = rnd()
    D = det(a, b, c, d)
    assert det(2 * a + c, 2 * b + d, a - 3 * c, b - 3 * d) == -7 * D
    assert det(-3 * a + b, 4 * a - b, -3 * c + d, 4 * c - d) == -D and det(3 * d, 6 * c, b, 2 * a) == 6 * D
assert 5 * 4 == 20 and vdet((2, 1), (0, 2)) == 4

# 5 疊起來的布
a, b = (3, 0), (1, 1)
c = add(a, b, 2, 5)
assert vdet(c, b) == 2 * vdet(a, b) == 6
a, b = (2, 0), (1, 2)
c = add(a, b, 3, -2)
assert vdet(a, c) == -2 * vdet(a, b) and abs(vdet(a, c)) == 8 and vdet(a, b) == 4

# 6 第三根釘子
for A, B, cy, ks, co, big in [((1, 1), (3, 2), 0, [5, -7], (3, 1, 1, -1), 24), ((3, 1), (0, 2), 2, [6, -6], (2, 1, 1, 2), 18)]:
    ab = (B[0] - A[0], B[1] - A[1])
    found = [k for k in range(-30, 31) if abs(vdet(ab, (k - A[0], cy - A[1]))) == 6]
    assert sorted(found) == sorted(ks)
    for k in ks:
        ac = (k - A[0], cy - A[1])
        p = add(ab, ac, co[0], co[1])
        q = add(ab, ac, co[2], co[3])
        assert abs(vdet(p, q)) == big == abs(det(*co)) * 6

# 7 織布機的審判
for _ in range(2000):
    a, b, c, d = rnd()
    D = det(a, b, c, d)
    assert det(a, 3 * b, c, 3 * d) == 3 * D and det(a + 2 * b, b, c + 2 * d, d) == D
    assert det(2 * a, 2 * c, 5 * b, 5 * d) == 10 * D
assert 2 * det(1, 0, 0, 1) != det(2, 0, 0, 2)          # ③ ✕
assert det(0, 1, 1, 0) != det(1, 0, 0, 1)              # ④ ✕
assert det(108, 2019, 109, 2018) == -2127
assert det(1, 1, -1, 2) == 3 and det(1, 1, 1, 4) == 3   # 第 2 組 ② ✕（平方的不是 9）
assert det(1, 0, 0, -3) == -3 and F(abs(det(1, 0, 0, -3)), 2) == F(3, 2)   # 第 2 組 ④ ✕

# ======== 第二章 克拉瑪法則 ========

# 9 交叉的線
assert solve(2, 1, 7, 1, -3, -7) == (2, 3) and det(2, 1, 1, -3) == -7 and det(7, 1, -7, -3) == -14 and det(2, 7, 1, -7) == -21
assert det(2023, -2024, 2026, -2027) == 3 == -(2025 ** 2 - 4) + (2025 ** 2 - 1)
assert det(2025, -2024, 2028, -2027) == -3 and det(2023, 2025, 2026, 2028) == -6
assert solve(2023, -2024, 2025, 2026, -2027, 2028) == (-1, -2)

# 10 只知道三塊布：u = (a, d)、v = (b, e)、w = (c, f) 用例子驗
for _ in range(200):
    while True:
        u = (random.randint(-5, 5), random.randint(-5, 5))
        v = (random.randint(-5, 5), random.randint(-5, 5))
        if vdet(u, v):
            break
    # 第 1 組：det(u, v) = 3、det(u, w) = 6、det(v, w) = −9 ⇒ w = 3u + 2v（再縮放到 det(u, v) = 3）
    s = F(3, vdet(u, v))
    uu = (u[0] * s, u[1] * s)
    w = add(uu, v, 3, 2)
    assert vdet(uu, v) == 3 and vdet(uu, w) == 6 and vdet(v, w) == -9
    sol = solve(uu[0], 2 * v[0], -3 * w[0], uu[1], 2 * v[1], -3 * w[1])
    assert sol == (-9, -3)
    # 第 2 組：det(u, v) = −2、det(u, w) = 4、det(v, w) = 6 ⇒ w = 3u − 2v
    s = F(-2, vdet(u, v))
    uu = (u[0] * s, u[1] * s)
    w = add(uu, v, 3, -2)
    assert vdet(uu, v) == -2 and vdet(uu, w) == 4 and vdet(v, w) == 6
    assert solve(2 * uu[0], v[0], -2 * w[0], 2 * uu[1], v[1], -2 * w[1]) == (-3, 4)   # 2ax + by + 2c = 0
    assert det(-2 * w[0], v[0], -2 * w[1], v[1]) == 12 and det(2 * uu[0], -2 * w[0], 2 * uu[1], -2 * w[1]) == -16

# 11 用布量係數
for a, b, c, ar, xy in [((2, 0), (1, 1), (F(11, 2), F(5, 2)), (2, 3, 5), (F(3, 2), F(5, 2))),
                        ((2, 0), (1, 2), (F(1, 2), 3), (4, 2, 6), (F(-1, 2), F(3, 2)))]:
    assert (abs(vdet(a, b)), abs(vdet(b, c)), abs(vdet(a, c))) == ar
    assert solve(a[0], b[0], c[0], a[1], b[1], c[1]) == xy

# 12 換一組線（用好幾組 u、v 驗）
for _ in range(200):
    while True:
        u = (random.randint(-5, 5), random.randint(-5, 5))
        v = (random.randint(-5, 5), random.randint(-5, 5))
        if vdet(u, v):
            break
    w = add(u, v, 2, -1)
    assert solve(u[0], v[0], w[0], u[1], v[1], w[1]) == (2, -1)
    assert solve(3 * v[0], 4 * u[0], w[0], 3 * v[1], 4 * u[1], w[1]) == (F(-1, 3), F(1, 2))
    w = add(u, v, 2, 1)
    assert solve(2 * v[0], u[0] - v[0], w[0], 2 * v[1], u[1] - v[1], w[1]) == (F(3, 2), 2)

# 13 交線的審判（向量 a、b、c 的行列式；c = αa + βb）
a, b = (2, 0), (0, 1)
c = add(a, b, 2, 3)
assert (vdet(a, b), vdet(b, c), vdet(a, c)) == (2, -4, 6)
assert vdet(add(a, b), c) == 2 and F(abs(vdet(a, b)), 2) == 1
assert vdet(add(a, c, 2, -1), b) == 0                       # ③ Δ = 0、常數 0：無限多組
assert solve(a[0], b[0], c[0], a[1], b[1], c[1]) == (2, 3)   # ④ 卡上的 (−2, 3) ✕
a, b = (3, 0), (0, 1)
c = add(a, b, 0, 2)
assert (vdet(a, b), vdet(a, c), vdet(b, c)) == (3, 6, 0)
assert vdet((15, 0), (0, 5)) == 75 and F(abs(vdet(a, c)), 2) == 3
assert solve(a[0], b[0], c[0], a[1], b[1], c[1]) == (0, 2)
d = (6, 0)
assert solve(a[0], b[0], d[0], a[1], b[1], d[1]) != "none" and solve(a[0], d[0], b[0], a[1], d[1], b[1]) == "none"

# 14 有幾組解
assert solve(1, 3, 5, 2, 1, 5) == (2, 1)
assert solve(1, -2, 3, 2, -4, 6) == "inf"
assert solve(1, 2, 2, 2, 4, 1) == "none"
assert solve(2, -1, 3, 1, 2, -4) == (F(2, 5), F(-11, 5))

# 15 轉動的線
for L1, L2, roots, cards in [
        (lambda a: (1, 2 - a, a + 1), lambda a: (2 - a, 1, 3 * a - 1), (1, 3), [(2, (3, 5)), (1, "inf"), (3, "none"), (0, (-1, 1))]),
        (lambda a: (3, 4 - a, a + 2), lambda a: (4 - a, 3, 2 * a + 1), (1, 7), [(4, (2, 3)), (7, "none"), (1, "inf"), (3, (1, 2))])]:
    for a in range(-10, 11):
        p, q = L1(a), L2(a)
        assert (det(p[0], p[1], q[0], q[1]) == 0) == (a in roots)
    for a, want in cards:
        p, q = L1(a), L2(a)
        assert solve(p[0], p[1], p[2], q[0], q[1], q[2]) == want

# 16 永遠碰不到
for L1, L2, roots, ans in [(lambda a: (a + 3, 5 - a, 2), lambda a: (3 - a, 2, 2 - a), (1, 9), 9),
                           (lambda a: (a - 1, 3 - a, 4), lambda a: (1 - a, 1, 3 - a), (1, 4), 4)]:
    zs = [a for a in range(-20, 21) if det(L1(a)[0], L1(a)[1], L2(a)[0], L2(a)[1]) == 0]
    assert tuple(zs) == roots
    kinds = {a: solve(*L1(a), *L2(a)) for a in roots}
    assert kinds[roots[0]] == "inf" and kinds[roots[1]] == "none" and ans == roots[1]

# 17 疊在一起
assert solve(-8, -4, 0, 2, 1, 0) == "inf" and solve(2, -6, 0, 1, -3, 0) == "inf"
assert all(solve(a, -4, 0, 2, 1, 0) == (0, 0) for a in range(-20, 21) if a != -8)
assert all(solve(2, a, 0, 1, -3, 0) == (0, 0) for a in range(-20, 21) if a != -6)

print("OK")
