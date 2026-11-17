"""E2 十倍石階（常用對數）：設計稿 docs/exp_e2_design.md 的數字驗算。"""
from math import log10 as L, sqrt, isclose, floor

def ok(a, b, msg="", tol=1e-9):
    assert isclose(a, b, rel_tol=tol, abs_tol=tol), (a, b, msg)

# ============ 第一章 ============
# 1 數量級階梯：整數部分（第幾階）
for x, n in ((508, 2), (0.005, -3), (3952, 3), (2e-6, -6)):
    assert floor(L(x)) == n, (x, L(x))

# 2 觀念審判卡（不需要數值；只確認會算的那幾張）
ok(L(4) + L(9), L(36)); ok(L(25) + L(4), L(100))
for n in (1, 3):
    assert not isclose(10 ** (n * L(2)), 2 * n) or n == 1   # n = 1 時剛好相等，所以審判卡寫一般的 n
ok(10 ** (5 * L(2)), 32); assert not isclose(10 ** (5 * L(2)), 10)

# 3 數線上幾個相異點
assert 3 - 2 * sqrt(10) < 0 and 5 - 2 * sqrt(7) < 0
ok(1 / sqrt(10), 10 ** -0.5); ok(L(sqrt(10)), 0.5)
assert len({round(v, 9) for v in (1 / sqrt(10), L(sqrt(10)), 10 ** -0.5)}) == 2
ok(1 / 10 ** (1 / 3), 10 ** (-1 / 3)); ok(L(10 ** (1 / 3)), 1 / 3)
assert len({round(v, 9) for v in (10 ** (-1 / 3), 1 / 3, 10 ** (-1 / 3), L(1))}) == 3

# 4 自己發現 log 2、log 3、log 7
assert 2 ** 10 == 1024 and 3 ** 4 == 81 and 7 ** 2 == 49
ok((3 * 0.3 + 1) / 4, 0.475); assert abs(0.475 - L(3)) < 0.003
ok((2 - 0.3) / 2, 0.85); assert abs(0.85 - L(7)) < 0.005

# 5 10^{log a} = a
ok(100 ** L(3), 9); ok(sqrt(10) ** L(16), 4); ok((100 ** (1 / 3)) ** L(27 / 8), 9 / 4)
a, b, c = L(sqrt(10) / 1000), 0.1 ** L(3), 100 ** L(2)
ok(a, -2.5); ok(b, 1 / 3); ok(c, 4)
ok(sqrt(a * a + b * b + c * c + 2 * a * b - 2 * b * c - 2 * c * a), 37 / 6)
assert not isclose(abs(a - b + c), 37 / 6) and not isclose(abs(a + b + c), 37 / 6)

# 6 計算尺、對數的運算
ok(L(2) + L(3), L(6)); ok(L(2) + L(5), 1.0); ok(L(6) - L(3), L(2))
ok(2 * L(3) + 3 * L(2) - 0.5 * L(36), L(12))
ok(L(sqrt(13) + sqrt(3)) + L(sqrt(13) - sqrt(3)), 1)
ok(3 * 1.2 + 2.5 - 3.1, 3.0)

# 7 首數平移
ok(2.71 + 3, 5.71); ok(2.71 - 1, 1.71)
ok(L(0.0169), L(169) - 4)

# 8 用 log 比倍數
ok(10 ** (-1.8 - 1.2), 1 / 1000)
a = 10 ** 2.03; ok(0.001 ** 0.01, 100 / a)
for w in (a / 100, 100 * a, a - 2):
    assert not isclose(w, 0.001 ** 0.01)

# ============ 第二章 ============
# 1 log 2、log 3、log 7 的組合（a、b、c）
a, b, c = L(2), L(3), L(7)
ok(a + b, L(6)); assert not isclose(L(20), 10 * a); ok(1000 ** c, 343); assert not isclose(L(14), 2 * c)
ok(a + c, L(14)); assert not isclose(L(30), 3 * b); ok(100 ** b, 9); assert not isclose(L(3.5), c / a)

# 2 夾在哪兩階
assert floor(L(3870)) == 3 and floor(L(0.0387)) == -2
ok(2 * 0.3010, 0.602); assert abs(10 ** 2.6 - 400) < 2.5
assert min((40, 400, 600, 4000), key=lambda v: abs(v - 10 ** 2.6)) == 400

# 3 範圍審判卡
ok(10 ** (5 * L(3)), 243); ok(10 ** (3 * L(5)), 125)
ok(L(sqrt(sqrt(sqrt(10)))), 1 / 8); assert -3 < L(0.0035) < -2
ok(L((10 ** 0.6) ** 0.25), 0.15); ok(10 ** (2 * L(5)), 25); ok(10 ** (3 * L(2)), 8)
ok(L(sqrt(sqrt(10))), 0.25); assert -2 < L(0.042) < -1

# 4 分貝
d = lambda I: 10 * L(I / 1e-12)
ok(10 ** ((80 - 30) / 10), 1e5); ok(d(1e-1), 110); ok(10 ** ((20 - 10) / 10), 10)
ok(10 ** ((70 - 40) / 10), 1e3); ok(d(1e-9), 30); assert abs(10 ** 1.5 - 15) > 10

# 5 對數公式的應用
ok(2 / 4, 0.5); ok(10 ** 0.5, sqrt(10))                              # T = 2 + 4log E
ok(1.5 * (7.2 - 6.1), 1.65, tol=1e-9); assert abs(10 * 4.467 - 10 ** 1.65) < 0.05
assert round(10 ** 1.65) == 45

print("E2 全部驗算通過")
