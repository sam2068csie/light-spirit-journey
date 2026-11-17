"""E1 倍增岩壁（指數律）：設計稿 docs/exp_e1_design.md 的數字驗算。
指數律用「質數 → 分數指數」的字典精確計算（光柱積木的高度）；其他用浮點數確認。"""
from fractions import Fraction as F
from math import sqrt, isclose, log2, ceil

def ok(a, b, msg=""):
    assert isclose(a, b, rel_tol=1e-9, abs_tol=1e-9), (a, b, msg)

def fac(n):
    d, p = {}, 2
    while n > 1:
        while n % p == 0:
            d[p] = d.get(p, 0) + 1
            n //= p
        p += 1
    return d

def frac(num, den=1):
    d = {k: F(v) for k, v in fac(num).items()}
    for k, v in fac(den).items():
        d[k] = d.get(k, 0) - v
    return d

def mul(*ds):
    r = {}
    for d in ds:
        for k, v in d.items():
            r[k] = r.get(k, 0) + v
    return {k: v for k, v in r.items() if v != 0}

def pw(d, e):
    return {k: v * F(e) for k, v in d.items()}

def val(d):
    x = 1.0
    for k, v in d.items():
        x *= k ** float(v)
    return x

# ============ 第一章 指數律 ============
# 1 有意義嗎：0^0 ✕、0 的負次方 ✕、負數的無理數次方 ✕，其他 ○
v0 = {"0^0": 0, "(-3)^0": 1, "(-1/3)^-2": 1, "(-5)^√2": 0, "0^-1/2": 0, "2.5^-1.5": 1}
v1 = {"(-2)^0": 1, "0^3": 1, "0^-3": 0, "(-1/2)^-3": 1, "(-3)^√3": 0, "7^-√2": 1}
assert sum(v0.values()) == 3 and sum(v1.values()) == 4
ok((-1 / 3) ** -2, 9); ok((-0.5) ** -3, -8)

# 2 偵錯：前兩個等號、最後一個都對，錯在 [(-2)^2]^{1/2} = (-2)^{2·1/2}
ok(4 ** 0.5, 2); ok((-2) ** 2, 4)
ok(81 ** 0.25, 3); ok((-3) ** 4, 81)          # 第 2 組：3 = 9^{1/2} = 81^{1/4} = [(-3)^4]^{1/4} ✕ (-3)^{4·1/4}

# 3 共軛相乘
ok((7 + 2 * sqrt(6)) ** 1.5 * (7 - 2 * sqrt(6)) ** 1.5, 125)
ok((5 + sqrt(17)) ** (4 / 3) * (5 - sqrt(17)) ** (4 / 3), 16)

# 4 光柱積木
A1 = mul(pw(frac(9), F(-2, 3)), pw(frac(243), F(1, 3)), pw(mul(frac(3), pw(frac(3), F(1, 3)), frac(1, 16)), F(1, 2)))
assert A1 == {3: 1, 2: -2}, A1                                  # 3/4
A2 = mul(pw(frac(4), F(-2, 3)), pw(frac(32), F(1, 3)), pw(mul(frac(2), pw(frac(2), F(1, 3)), frac(1, 25)), F(1, 2)))
assert A2 == {2: 1, 5: -1}, A2                                  # 2/5
assert pw(frac(9), F(-2, 3)) == {3: F(-4, 3)}                   # 關鍵卡：9^{-2/3} = 3^{-4/3}
ok(64 ** (-2 / 3) * 16 ** 0.25 * 3 ** (1 - sqrt(5)) * 6 ** (1 + sqrt(5)) / 2 ** sqrt(5), 9 / 4)
ok(125 ** (-2 / 3) * 81 ** 0.25 * 2 ** (1 - sqrt(3)) * 10 ** (1 + sqrt(3)) / 5 ** sqrt(3), 12 / 5)
C1 = mul(pw(frac(1, 2), F(1, 4) * 2), pw(frac(9, 16), F(-1, 2)), pw(frac(8), F(-1, 6)))
assert C1 == {2: 1, 3: -1}, C1                                  # 2/3

# 5 解方程（x > 0）
x = 0.5; ok((x ** 8) ** 0.25 / (3 * x ** -1) * 6 / x ** 6, 16); ok(2 * x ** -3, 16)
x = 3.0; ok(sqrt(x ** 6) / (4 * x ** -2) * 8 / x ** 3, 18); ok(2 * x ** 2, 18)

# 6 提公因式
for x in (0.3, 1.7):
    ok(3 ** x + 3 ** (x + 1) + 3 ** (x + 2), 13 * 3 ** x)
    ok(2 ** x + 2 ** (x + 1) + 2 ** (x + 2) + 2 ** (x + 3), 15 * 2 ** x)
    ok(5 ** x + 5 ** (x + 1), 6 * 5 ** x)
x = 0
from math import log
x = log(15 / 13) / log(1.5); ok(3 ** x + 3 ** (x + 1) + 3 ** (x + 2), 2 ** x + 2 ** (x + 1) + 2 ** (x + 2) + 2 ** (x + 3))
x = log(7 / 6) / log(2.5); ok(5 ** x + 5 ** (x + 1), 2 ** x + 2 ** (x + 1) + 2 ** (x + 2))

# 7 代換
x = log(7) / log(9); ok(27 ** (x + 1) * 81 ** (-x), 27 / sqrt(7))
x = log(5) / log(4); ok(8 ** (x + 1) * 16 ** (-x), 8 / sqrt(5))
a, b = 5 ** 0.4, 5 ** 0.15; ok(5 ** -0.1, b * b / a)
a, b = 3 ** 0.6, 3 ** 0.25; ok(3 ** 0.1, a / (b * b))
for wrong in (a * a / b, 2 * b - a, b * b - a):                # 錯的選項（第 2 組）
    assert not isclose(wrong, 3 ** 0.1)

# 8 找關係式
x, y = log(27) / log(45), log(3) / log(5); ok(3 / x - 1 / y, 2)
x, y = log(4) / log(24), log(2) / log(3); ok(2 / x - 1 / y, 3)
for k in (50.0, 1000.0):
    x, y = log(k) / log(2), log(k) / log(7)
    z = 2 / (1 / x + 1 / y)
    ok(k ** (1 / z), sqrt(14))
    x, y, z = log(k) / log(4), log(k) / log(3), log(k) / log(12)
    ok(1 / z, 1 / x + 1 / y)
    assert not isclose(1 / z, 1 / x - 1 / y) and not isclose(1 / z - 1 / x, 1 / (2 * y)) and not isclose(z, x + y)

# ============ 第二章 乘法公式與應用 ============
# 1 已知 a^{2x}
u = 3 + 2 * sqrt(2); t = sqrt(u); ok((t ** 3 + t ** -3) / (t + 1 / t), 5); ok(1 / u, 3 - 2 * sqrt(2))
u = 4 + sqrt(15); t = sqrt(u); ok((t ** 3 + t ** -3) / (t + 1 / t), 7)
u = 7 - 4 * sqrt(3); t = sqrt(u)
ok(t, 2 - sqrt(3)); ok(t + 1 / t, 4); ok(u + 1 / u, 14); ok(t ** 3 + t ** -3, 52)
assert not isclose(u + 1 / u, 16)                               # 審判卡 ✕

# 2 回音階梯往上爬
s = ((3 + sqrt(13)) / 2) ** 2                                   # a^{1/2} - a^{-1/2} = 3
ok(sqrt(s) - 1 / sqrt(s), 3); ok(s + 1 / s, 11); ok(s ** 1.5 - s ** -1.5, 36); ok(36 / 11, (s ** 1.5 - s ** -1.5) / (s + 1 / s))
s = 7 + 4 * sqrt(3)                                             # a + a^{-1} = 14
ok(s + 1 / s, 14); ok(sqrt(s) + 1 / sqrt(s), 4); ok(s ** 1.5 + s ** -1.5, 52); ok(s * s + s ** -2, 194)
ok((s ** 1.5 + s ** -1.5) / (s * s + s ** -2), 26 / 97)

# 3 往下開根號、決定正負
for s in (7 + 4 * sqrt(3), 7 - 4 * sqrt(3)):                    # a 比 1 大或小，兩個都可能
    ok(abs(sqrt(s) - 1 / sqrt(s)), 2 * sqrt(3))
s = (7 + sqrt(45)) / 2; ok(s + 1 / s, 7); ok(abs(sqrt(s) - 1 / sqrt(s)), sqrt(5))
s = (sqrt(10) - sqrt(6)) / 2; assert 0 < s < 1; ok(s + 1 / s, sqrt(10)); ok(s - 1 / s, -sqrt(6))

# 4 開立方
for z_sum, t in ((18, 3), (110, 5)):
    ok(t ** 3 - 3 * t, z_sum)
    z = ((z_sum + sqrt(z_sum ** 2 - 4)) / 2)
    ok(z ** (1 / 3) + z ** (-1 / 3), t)

# 5 折紙：0.1 mm = 1e-4 m
def fold(h):
    return ceil(log2(h / 1e-4))
assert (fold(508), fold(3952), fold(8849), fold(3.844e8)) == (23, 26, 27, 42)
assert fold(1.496e11) == 51
assert 1e-4 * 2 ** 41 < 3.844e8 < 1e-4 * 2 ** 42

# 6 兩筆資料反求
r = (240 / 30) ** (1 / 1.5); ok(r, 4); ok(30 * 4 ** 3, 1920)          # a = 3，b = 2 + 3 = 5
k = sqrt(480 / 120); xx = 120 / k ** 3; ok(k, 2); ok(xx, 15); ok(xx * k ** 8, 3840)
uu = 120 / 80 - 1; aa = 80 / (1 - uu); ok(uu, 0.5); ok(aa, 160); ok(aa * (1 - uu ** 3), 140)

# 7 發光礦石
ma = lambda t: 4 * 0.5 ** (t / 10)
mb = lambda t: 0.5 ** (t / 15)
ok(ma(60), mb(60)); ok(ma(30), 2 * mb(30)); ok(mb(120), 4 * ma(120)); assert not isclose(ma(90), mb(90))
ok(2 * 0.5 ** (24 / 8), 0.5 ** (24 / 12))
ok(2 * 0.5 ** (12 / 8), 2 ** 0.5 * 0.5 ** (12 / 12))            # 第 2 組審判卡：12 年後 a 是 b 的 √2 倍

# 8 選模型：每 3 天加倍
f = lambda t: 100 * 2 ** (t / 3)
ok(f(3), 200); ok(f(6), 400)
assert not isclose(100 / 3 * 3 + 100, 400)                       # 一次函數在 t = 6 不是 400
assert not isclose(100 * (2 / 3) ** 3, 200)
assert not isclose(100 / 3 * 2 ** 0, 100)                         # (a/3)·2^t 在 t = 0 不是 a
g = lambda t: 160 * 0.5 ** (t / 2); ok(g(2), 80); ok(g(4), 40)

# 9 代公式
ok(27 ** (5 / 3), 243); ok(243 ** 0.6, 27)
ok(1000 * 0.64 ** 1.5, 512); ok(0.8 ** 3, 0.512)
M = lambda t: 1000 * 0.64 ** t
for t in (0.0, 2.5): ok((M(t) - M(t + 1)) / M(t), 0.36)

# 10 賽跑
ok(2 ** (12 / 2), 64); ok(3 ** (12 / 3), 81); ok(4 ** (12 / 4), 64); ok(6 ** (12 / 6), 36)
for t in (1, 5, 12, 30):
    ok(2 ** (t / 2), 4 ** (t / 4))                                # 甲、丙永遠並排
    assert 3 ** (t / 3) > 2 ** (t / 2) > 6 ** (t / 6)
vals = [9 / 3 ** (1 / 3), 3 ** 1.25, 2 ** 2.5, 1]
ok(vals[0], 3 ** (5 / 3)); assert 3 ** 10 > 2 ** 15
assert sorted(range(4), key=lambda i: vals[i]) == [3, 1, 2, 0]   # 1 < 3^{5/4} < 2^{5/2} < 9/∛3

print("E1 全部驗算通過")
