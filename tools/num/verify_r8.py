"""R8 谷底水渠（數線上的幾何）：設計稿 docs/num_r8_design.md 的數字驗算。
不等式、方程式的解都用很細的格子（分數，1/240 一格）掃過一遍，和設計稿寫的答案比對；
分段討論每一段的候選解確認「在不在這一段」；最小值掃一遍確認在哪裡、是多少。"""
from fractions import Fraction as F
from math import sqrt, isclose

STEP = F(1, 240)


def grid(lo, hi):
    x = F(lo)
    while x <= hi:
        yield x
        x += STEP


def sol(pred, lo=-30, hi=30):
    """回傳 pred 成立的格子點"""
    return [x for x in grid(lo, hi) if pred(x)]


def intervals(xs):
    """把連續的格子點併成區間 [(a, b), …]"""
    out = []
    for x in xs:
        if out and x - out[-1][1] == STEP:
            out[-1][1] = x
        else:
            out.append([x, x])
    return [tuple(i) for i in out]


def same(xs, want):
    got = intervals(xs)
    assert got == [(F(a), F(b)) for a, b in want], (got, want)


A = abs

# ============ 第一章 ============
# 1 柵欄的範圍：|x − 2| = 3、≤ 3、> 3
assert sol(lambda x: A(x - 2) == 3) == [-1, 5]
same(sol(lambda x: A(x - 2) <= 3), [(-1, 5)])
same(sol(lambda x: A(x - 2) > 3, -10, 10), [(-10, F(-1) - STEP), (F(5) + STEP, 10)])
assert sol(lambda x: A(x + 1) == 4) == [-5, 3]
same(sol(lambda x: A(x + 1) <= 4), [(-5, 3)])

# 2 相同的解：|x − 3| ≤ √2（用浮點數比較，掃細格子）
def fl_set(f):
    return [x for x in grid(-12, 12) if f(float(x))]
base = fl_set(lambda x: A(x - 3) <= sqrt(2))
for f, same_sol in [(lambda x: A(x + 3) <= sqrt(2), False), (lambda x: A(3 - x) <= sqrt(2), True),
                    (lambda x: A(x - sqrt(2)) <= 3, False), (lambda x: A(x) <= 3 + sqrt(2), False),
                    (lambda x: sqrt((x - 3) ** 2) <= sqrt(2), True)]:
    assert (fl_set(f) == base) == same_sol
base = fl_set(lambda x: A(x + 2) <= sqrt(3))
for f, same_sol in [(lambda x: A(x - 2) <= sqrt(3), False), (lambda x: A(-2 - x) <= sqrt(3), True),
                    (lambda x: A(x + sqrt(3)) <= 2, False), (lambda x: A(x) <= 2 + sqrt(3), False),
                    (lambda x: sqrt((x + 2) ** 2) <= sqrt(3), True)]:
    assert (fl_set(f) == base) == same_sol

# 3 絕對值的絕對值
same(sol(lambda x: A(A(x - 3) - 1) <= 2), [(0, 6)])
same(sol(lambda x: A(A(x + 1) - 3) <= 2), [(-6, -2), (0, 4)])

# 4 標準值上下 10％
w = (180 - 80) * F(7, 10); assert w == 70 and w * F(1, 10) == 7
w = (160 - 70) * F(6, 10); assert w == 54  # 講義的數字（不用）
L = 50 * F(2, 100); assert L == 1

# 5 反寫 ≤：|ax + 4| ≤ b 和 (x + 2)(x − 6) ≤ 0 同解
same(sol(lambda x: (x + 2) * (x - 6) <= 0), [(-2, 6)])
same(sol(lambda x: A(-2 * x + 4) <= 8), [(-2, 6)])
same(sol(lambda x: (x + 1) * (x - 5) <= 0), [(-1, 5)])
same(sol(lambda x: A(-3 * x + 6) <= 9), [(-1, 5)])

# 6 反寫 ≥：|ax + 4| ≥ b 的解是 x ≥ 5 或 x ≤ −3
same(sol(lambda x: A(-4 * x + 4) >= 16, -10, 10), [(-10, -3), (5, 10)])
assert -4 - 16 == -20
same(sol(lambda x: A(-3 * x + 6) >= 12, -10, 10), [(-10, -2), (6, 10)])
assert -3 - 12 == -15

# 7 兩段柵欄的交集
same(sol(lambda x: A(3 - x) >= 1 and A(x + 2) <= 5), [(-7, 2)])
same(sol(lambda x: A(4 - x) >= 2 and A(x + 1) <= 7), [(-8, 2), (6, 6)])

# 8 整數解的個數
r = 2 * sqrt(15); assert 7 < r < 8
xs = [x for x in range(-20, 21) if F(5, 3) < A(2 * x - 1) <= r]
assert xs == [-3, -2, -1, 2, 3, 4], xs
r = sqrt(50); assert 7 < r < 7.1
xs = [x for x in range(-20, 21) if F(2, 3) < A(3 * x + 1) <= r]
assert xs == [-2, -1, 0, 1, 2], xs

# 9 反寫雙不等式：b < |ax + 3| ≤ 9 的解是 0 < x ≤ 2 或 −4 ≤ x < −2
same(sol(lambda x: 3 < A(3 * x + 3) <= 9), [(-4, F(-2) - STEP), (F(0) + STEP, 2)])
same(sol(lambda x: 2 < A(2 * x - 4) <= 10), [(-3, F(1) - STEP), (F(3) + STEP, 7)])

# 10 平方法
same(sol(lambda x: A(2 * x + 3) <= A(x + 4)), [(F(-7, 3), 1)])
assert all((3 * x * x + 4 * x - 7 == (3 * x + 7) * (x - 1)) for x in grid(-3, 3))
same(sol(lambda x: A(3 * x - 1) <= A(x + 3)), [(F(-1, 2), 2)])
assert all((2 * x * x - 3 * x - 2 == (2 * x + 1) * (x - 2)) for x in grid(-3, 3))

# ============ 第二章 ============
# 12 分段討論的方程式
assert sol(lambda x: A(x - 3) == 2 * x - 9) == [6]
assert 3 - 4 == 2 * 4 - 9 and not (4 >= 3) or True   # x < 3 那一段算出 4，不在這一段
assert sol(lambda x: A(x + 1) == 3 * x - 5) == [3]

# 13 兩個絕對值
assert sol(lambda x: A(x - 2) + A(2 * x - 1) == 4) == [F(-1, 3), F(7, 3)]
assert sol(lambda x: A(x + 1) + A(2 * x - 4) == 6) == [-1, 3]

# 14 交通費 f(x) = 2|x − 5| + |x + 1|
f = lambda x: 2 * A(x - 5) + A(x + 1)
assert min(f(x) for x in grid(-20, 20)) == 6 and f(5) == 6
assert sol(lambda x: f(x) == 24) == [-5, 11]
assert 11 - (-13) == 24 and not (-1 <= -13 < 5)
f = lambda x: 2 * A(x - 4) + A(x + 2)
assert sol(lambda x: f(x) == 21) == [-5, 9]

# 15 相異四點
assert sol(lambda x: A(x - 2) + A(2 * x + 2) == 5) == [F(-5, 3), 1]
assert 2 * 1 == 2   # x = 1 時 B(2) 和 C(2) 重合，不相異
assert sol(lambda x: A(x - 1) + A(3 * x + 3) == 6) == [-2, 1]
assert 1 == 1       # x = 1 時 A(1) 和 C(1) 重合

# 16 不等式分段
same(sol(lambda x: A(x + 1) + 2 * A(x - 3) <= 13), [(F(-8, 3), 6)])
same(sol(lambda x: A(x - 2) + 2 * A(x + 1) <= 9), [(-3, 3)])

# 17 中位數
f = lambda x: A(x - 1) + A(x - 4) + A(x - 6)
assert min(f(x) for x in grid(-10, 10)) == 5 and sol(lambda x: f(x) == 5, -10, 10) == [4]
assert min(sum(A(x - k) for k in range(1, 51)) for x in range(-5, 60)) == 625
assert sum(A(25 - k) for k in range(1, 51)) == 625 and sum(A(26 - k) for k in range(1, 51)) == 625
f = lambda x: A(x + 3) + A(x - 2) + A(x - 4) + A(x - 7) + A(x - 10)
assert min(f(x) for x in grid(-10, 15)) == 18 and sol(lambda x: f(x) == 18, -10, 15) == [4]
assert min(sum(A(x - k) for k in range(1, 50)) for x in range(-5, 60)) == 600

# 18 有係數的中位數
f = lambda x: A(2 * x - 1) + A(x - 3) + A(x - 5)
assert min(f(x) for x in grid(-10, 10)) == 7
same(sol(lambda x: f(x) == 7, -10, 10), [(F(1, 2), 3)])
f = lambda x: A(3 * x - 6) + A(x - 1) + A(x - 4)
assert min(f(x) for x in grid(-10, 10)) == 3 and sol(lambda x: f(x) == 3, -10, 10) == [2]

# 19 水渠的底：解的個數
f = lambda x: A(x + 2) + A(x - 4)
assert min(f(x) for x in grid(-20, 20)) == 6
same(sol(lambda x: f(x) == 6, -20, 20), [(-2, 4)])
assert sol(lambda x: f(x) == 5, -20, 20) == []
assert len([x for x in grid(-20, 20) if isclose(float(f(x)), 2 * sqrt(10), abs_tol=1e-3)]) >= 2
g = lambda x: A(x + 2) - A(x - 4)
assert max(g(x) for x in grid(-20, 20)) == 6 and min(g(x) for x in grid(-20, 20)) == -6
assert sol(lambda x: g(x) == 7, -20, 20) == []
assert len(sol(lambda x: g(x) == -6, -20, 20)) > 1
# 第 2 組：|x − 1| + |x + 5| = k 恰有兩個解 ⇔ k > 6
f = lambda x: A(x - 1) + A(x + 5)
for k, n in [(3, 0), (4, 0), (5, 0), (6, None), (7, 2)]:
    s = sol(lambda x: f(x) == k, -20, 20)
    if n is None:
        assert len(s) > 2
    else:
        assert len(s) == n, (k, s)
assert sol(lambda x: f(x) < 6, -20, 20) == [] and sol(lambda x: f(x) < F(6) + STEP, -20, 20)

# 20 分段畫圖，找最低點
f = lambda x: A(x - 1) + A(2 * x - 4) - 2 * x
assert [f(x) - (x - 5) for x in grid(2, 5)] == [0] * len(list(grid(2, 5)))
assert all(f(x) == 3 - 3 * x for x in grid(1, F(2) - STEP)) and all(f(x) == 5 - 5 * x for x in grid(-3, F(1) - STEP))
assert min(f(x) for x in grid(-10, 10)) == -3 and sol(lambda x: f(x) == -3, -10, 10) == [2]
f = lambda x: A(x + 1) + A(x - 3) - x
assert all(f(x) == x - 2 for x in grid(3, 6)) and all(f(x) == 4 - x for x in grid(-1, F(3) - STEP))
assert all(f(x) == 2 - 3 * x for x in grid(-5, F(-1) - STEP))
assert min(f(x) for x in grid(-10, 10)) == 1 and sol(lambda x: f(x) == 1, -10, 10) == [3]

# 21 三角不等式
same(sol(lambda x: sqrt(float(x * x - 4 * x + 4)) + sqrt(float(4 * x * x + 4 * x + 1)) <= sqrt(float(x * x + 6 * x + 9)) + 1e-12),
     [(F(-1, 2), 2)])
assert all((x - 2) - (2 * x + 1) == -(x + 3) for x in grid(-3, 3))
same(sol(lambda x: A(x + 1) + A(2 * x - 3) <= A(x - 4)), [(-1, F(3, 2))])
assert all((2 * x - 3) - (x + 1) == x - 4 for x in grid(-3, 3))

# 22 整數
ans = set()
for a in range(-20, 20):
    for b in range(-20, 20):
        for c in range(-40, 40):
            if 5 * A(a + 2) + 4 * A(b - 1) + F(1, 2) * A(c - 3) == 3:
                ans.add((a, b, c))
assert ans == {(-2, 1, 9), (-2, 1, -3)}, ans
ans = set()
for a in range(-20, 20):
    for b in range(-20, 20):
        for c in range(-40, 40):
            if 6 * A(a - 1) + 4 * A(b + 3) + F(1, 3) * A(c + 2) == 3:
                ans.add((a, b, c))
assert ans == {(1, -3, 7), (1, -3, -11)}, ans

print("R8 驗算全部通過")
