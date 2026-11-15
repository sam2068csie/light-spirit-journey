"""R4 圍籬牧場（算幾不等式）：設計稿 docs/num_r4_design.md 的數字驗算。
最大值、最小值都用很密的掃描確認，等號成立的地方也確認只有一個。"""
from fractions import Fraction as F
from math import sqrt, isclose

def scan(f, lo, hi, n=200000):
    best = None
    for k in range(1, n):
        x = lo + (hi - lo) * k / n
        v = f(x)
        if v is None:
            continue
        if best is None or v < best[1]:
            best = (x, v)
    return best

def near(a, b, tol=1e-3):
    return abs(a - b) < tol

# 1 半圓：a + b = 8（10），√ab 最長在 a = b，等於半徑
for s in (8, 10):
    x, v = scan(lambda a: -sqrt(a * (s - a)), 0, s)
    assert near(x, s / 2) and near(-v, s / 2)

# 2 給和求積
for p, q, tot, amax, at in [(3, 4, 24, 12, (4, 3)), (1, 4, 8, 4, (4, 1))]:
    x, v = scan(lambda a: -(a * (tot - p * a) / q), 0, tot / p)
    assert near(-v, amax) and near(x, at[0]) and p * at[0] + q * at[1] == tot and at[0] * at[1] == amax
    assert (p * at[0]) == (q * at[1]) == tot // 2                    # 長方形是正方形

# 3 給積求和
for p, q, prod, mn, at in [(1, 2, 8, 8, (4, 2)), (2, 3, 6, 12, (3, 2))]:
    x, v = scan(lambda x: p * x + q * prod / x, 0.01, 50)
    assert near(v, mn) and near(x, at[0]) and at[0] * at[1] == prod and p * at[0] == q * at[1]

# 4 給平方和：9a² + b² = 18、a² + 4b² = 8
for p, q, tot, amax, at in [(9, 1, 18, 3, (1, 3)), (1, 4, 8, 2, (2, 1))]:
    x, v = scan(lambda a: None if tot - p * a * a <= 0 else -(a * sqrt((tot - p * a * a) / q)), 0, sqrt(tot / p))
    assert near(-v, amax) and near(x, at[0]) and p * at[0] ** 2 + q * at[1] ** 2 == tot

# 5 先乘開：a + 2b = 6 求 (a + 2)(b + 1)、2a + b = 8 求 (a + 1)(b + 2)
for f, lo, hi, mx, at in [(lambda a: (a + 2) * ((6 - a) / 2 + 1), 0, 6, 12.5, (3, 1.5)),
                          (lambda a: (a + 1) * ((8 - 2 * a) + 2), 0, 4, 18, (2, 4))]:
    x, v = scan(lambda a: -f(a), lo, hi)
    assert near(-v, mx) and near(x, at[0])

# 6 步道：草地 150、上下寬 2、左右寬 3；草地 96、上下寬 3、左右寬 2（x 是橫的長、y 是直的寬）
for area, tb, lr, coef, mn, at in [(150, 2, 3, (4, 6, 24), 144, (15, 10)), (96, 3, 2, (6, 4, 24), 120, (8, 12))]:
    path = lambda x: (x + 2 * lr) * (area / x + 2 * tb) - area
    for x in (3, 7.5, 20):
        assert isclose(path(x), coef[0] * x + coef[1] * area / x + coef[2])
    x, v = scan(path, 0.5, 200)
    assert near(v, mn) and near(x, at[0]) and at[0] * at[1] == area

# 7 直角三角形斜邊 6（10）：面積最大 9（25）
for c, mx in ((6, 9), (10, 25)):
    x, v = scan(lambda a: -(a * sqrt(c * c - a * a) / 2), 0, c)
    assert near(-v, mx) and near(x, c / sqrt(2))

# 8 等腰直角三角形斜邊 16（12）裡的長方形水池（一邊在斜邊上）
for c, mx, at in ((16, 32, (8, 4)), (12, 18, (6, 3))):
    x, v = scan(lambda h: -((c - 2 * h) * h), 0, c / 2)       # 寬 w = c − 2h
    assert near(-v, mx) and near(x, at[1]) and c - 2 * at[1] == at[0]

# 9 倒數型
for f, lo, hi, mn, at in [(lambda x: x + 9 / x + 2, 0.01, 30, 8, 3), (lambda x: 4 * x + 1 / x - 1, 0.01, 30, 3, 0.5)]:
    x, v = scan(f, lo, hi)
    assert near(v, mn) and near(x, at)

# 10 分式型
for f, lo, mn, at in [(lambda x: (x * x + 2 * x + 5) / (x + 1), -1, 4, 1), (lambda x: (x * x - 2 * x + 10) / (x - 1), 1, 6, 4)]:
    x, v = scan(f, lo + 1e-4, lo + 40)
    assert near(v, mn) and near(x, at)

# 11 正數才能用：兩邊各一個最小、最大
for f, pole, lmin, rmin in [(lambda x: x + 4 / (x - 1), 1, (-1, -3), (3, 5)), (lambda x: x + 9 / (x + 2), -2, (-5, -8), (1, 4))]:
    x, v = scan(f, pole + 1e-4, pole + 40)
    assert near(x, rmin[0]) and near(v, rmin[1])
    x, v = scan(lambda x: -f(x), pole - 40, pole - 1e-4)
    assert near(x, lmin[0]) and near(-v, lmin[1])

# 12 根號型
for f, lo, mn, at in [(lambda x: (x + 5) / sqrt(x - 4), 4, 6, 13), (lambda x: (x + 21) / sqrt(x + 5), -5, 8, 11)]:
    x, v = scan(f, lo + 1e-4, lo + 80)
    assert near(v, mn) and near(x, at, 2e-3)

# 13 兩組一起：兩個等號都要成立
for a, b, c, d, rhs, at in [(1, 4, 4, 1, 8, (F(2), F(1, 2))), (9, 1, 1, 9, 12, (F(1, 3), F(3)))]:
    x, y = at
    assert a * x + c / x == 2 * sqrt(a * c) and b * y + d / y == 2 * sqrt(b * d)
    assert 2 * sqrt(a * c) + 2 * sqrt(b * d) == rhs and a * x + b * y + c / x + d / y == rhs
print("R4 verify OK")
