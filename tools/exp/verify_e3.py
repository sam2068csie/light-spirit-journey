"""E3 深谷測繩（科學記號與位數問題）：設計稿 docs/exp_e3_design.md 的數字驗算。

位數、最高位數字都用「真的整數」（Python 大整數、分數）確認，不只看 log 的近似值；
尾數尺上的判斷用題目給的近似值 log 2 ≈ 0.3010、log 3 ≈ 0.4771、log 7 ≈ 0.8451，
並確認尾數離格線至少 0.01（四捨五入的誤差不會讓學生點錯格）。
"""
from fractions import Fraction as F
from math import log10 as L, floor, isclose

l2, l3, l7 = 0.3010, 0.4771, 0.8451
TAB = [None, 0.0, l2, l3, 2 * l2, 1 - l2, l2 + l3, l7, 3 * l2, 2 * l3, 1.0]   # TAB[d] = log d


def ruler(m):
    """尾數 m 落在哪兩格之間：回傳左邊那一格（最高位數字）和離格線的距離"""
    for d in range(1, 10):
        if TAB[d] <= m < TAB[d + 1]:
            return d, min(m - TAB[d], TAB[d + 1] - m)
    raise ValueError(m)


def digits(n: int) -> int:
    return len(str(n))


def first_nonzero(x: F):
    """很小的正數：小數點後第幾位開始不是 0、那個數字"""
    k = 0
    while True:
        k += 1
        x *= 10
        if x >= 1:
            return k, int(x)


def ok(a, b, msg="", tol=1e-9):
    assert isclose(a, b, rel_tol=tol, abs_tol=tol), (a, b, msg)


# ============ 第一章 科學記號 ============
# 1 拖小數點：有效數字
def sci(n_str, sig):
    x = float(n_str)
    e = floor(L(x))
    return round(x / 10 ** e, sig - 1), e

assert sci("23412976", 2) == (2.3, 7) and sci("23412976", 3) == (2.34, 7)
assert sci("299792458", 2) == (3.0, 8)                 # 光速：2.99… 進位成 3.0，0 要留著
assert sci("0.0000075", 2) == (7.5, -6)                 # 紅血球直徑 7.5 微米

# 2 科學記號審判卡
a, b = F(406, 100) * 10 ** 17, F(81, 10) * F(1, 10 ** 6)
assert digits(int(a)) == 18                              # 「a 有 17 位數」✕
assert first_nonzero(b) == (6, 8)                        # 「b 從小數點後第 5 位開始不是 0」✕
assert str(int(a + b))[0] == "4"                         # 「a + b 的最高位數字是 4」○
a, b = F(250, 100) * 10 ** 9, F(6, 1000)
assert digits(int(a)) == 10                              # 「a 有 10 位數」○
assert first_nonzero(b) == (3, 6)                        # 「b 從小數點後第 3 位開始不是 0」○
assert digits(int(a * b)) == 8                           # 「a × b 是 7 位數」✕（1.5 × 10^{7}）

# 3 有效數字的運算（加減：準到最後一位比較高的那個；乘除：有效數字個數比較少的那個）
ok(3 + 5.6, 8.6); assert round(8.6) == 9                 # (3 × 10^{4}) + (5.6 × 10^{4}) ≈ 9 × 10^{4}
ok(3 * 5.6, 16.8); assert round(1.68) == 2               # (3 × 10^{4}) × (5.6 × 10^{3}) ≈ 2 × 10^{8}
ok(6 + 2.3, 8.3); assert round(8.3) == 8                 # (6 × 10^{5}) + (2.3 × 10^{5}) ≈ 8 × 10^{5}
ok(8.4 / 2, 4.2); assert round(4.2) == 4                 # \frac{8.4 × 10^{9}}{2 × 10^{3}} ≈ 4 × 10^{6}

# 4 天文距離
ok(4.2 * 1.5, 6.3); ok(2 * 6.3e11, 1.26e12); ok(1.26e12 / 3e8, 4.2e3)
ok(1.5e11 / 3e8, 500); assert round(500 / 60) == 8      # 陽光到地球約 8 分鐘

# 5 先猜再算：位數、最高位數字
m = 100 * l2; ok(m, 30.1)
assert digits(2 ** 100) == 31 and str(2 ** 100)[0] == "1" and ruler(m - floor(m))[0] == 1
m = 60 * l3; ok(m, 28.626)
d, gap = ruler(m - floor(m)); assert d == 4 and gap > 0.02
assert digits(3 ** 60) == 29 and str(3 ** 60)[0] == "4"
m = 40 * (l3 - (1 - l2)); ok(m, -8.876); ok(m + 9, 0.124)
assert ruler(m + 9)[0] == 1 and first_nonzero(F(3, 5) ** 40) == (9, 1)

# 6 位數判斷審判卡
ok(1 - l2, 0.6990)
assert digits(int(10 ** 5.3)) == 6                       # 「10^{5.3} 的整數部分是 5 位數」✕
assert first_nonzero(F(10 ** -3.4)) == (4, 3)             # 「10^{−3.4} 小數點後第 4 位開始不是 0」○
ok(1 + (1 - l2), 1.6990)                                 # log 50
assert digits(int(10 ** 8.02)) == 9                      # 「10^{8.02} 是 9 位數」○
assert first_nonzero(F(10 ** -2.9))[0] == 3               # 「10^{−2.9} 小數點後第 2 位」✕
assert digits(2 ** 50) == 16                             # 「2^{50} 是 15 位數」✕

# ============ 第二章 位數的應用 ============
# 1 已知位數反推
assert digits(43 ** 100) == 164 and 1.63 <= L(43) < 1.64
assert 32.6 <= 20 * L(43) < 32.8 and digits(43 ** 20) == 33
m = 2 * 8.4; ok(m, 16.8)
assert ruler(0.8)[0] == 6 and ruler(0.8)[1] > 0.02       # p ≈ 6.3 × 10^{16}：17 位數、最高位 6
assert floor(m) + 1 == 17

# 2 比大小（測繩比長短）
ok(500 * l2, 150.5); ok(120 * (1 + l3 - l2), 141.132)
assert 15 ** 120 < 10 ** 150 < 2 ** 500
ok(200 * l3, 95.42); ok(120 * (l2 + l3), 93.372)
assert 6 ** 120 < 10 ** 95 < 3 ** 200

# 3 反求 n
lg125 = 0.0969
assert 82 * lg125 < 8 <= 83 * lg125
assert digits(int(F(5, 4) ** 82)) == 8 and digits(int(F(5, 4) ** 83)) == 9
lg15 = l3 - l2; ok(lg15, 0.1761)
ns = [n for n in range(1, 60) if digits(int(F(3, 2) ** n)) == 5]
assert ns == list(range(23, 29)), ns
assert 2 ** 10 <= 2000 < 2 ** 11; ok(L(2000), 3.30103, tol=1e-4); ok(3.301 / l2, 10.967, tol=1e-3)

# 4 加起來有幾位數
m = 64 * l2; ok(m, 19.264)
assert ruler(m - floor(m))[0] == 1 and digits(2 ** 64 - 1) == 20 and str(2 ** 64 - 1)[0] == "1"
ma, mb = 41 * l3, 66 * l2
assert floor(ma) == floor(mb) == 19
da, ga = ruler(ma - 19); db, gb = ruler(mb - 19)
assert (da, db) == (3, 7) and min(ga, gb) > 0.015          # 3.… × 10^{19} + 7.… × 10^{19}：至少 10，一定進位
assert digits(3 ** 41 + 2 ** 66) == 21 and str(3 ** 41 + 2 ** 66)[0] == "1"

# 5 位數的應用
assert digits(int("11010", 2)) == 2 and int("11010", 2) == 26 and 2 ** 4 <= 26 < 2 ** 5
ok(100 / l2, 332.2, tol=1e-3)
n = floor(100 / L(2)) + 1; assert n == 333 and 2 ** (n - 1) <= 10 ** 100 < 2 ** n
ok(5.24 + 1.44 * 6.5, 14.6)
ok(1 + 2 * l2, 1.602)
ok(1.602 / 1.44, 1.1125); assert round(6.5 - 1.602 / 1.44, 1) == 5.4
# 分貝計換成地震：拖 M 時 10^{1.44 × (6.5 − M)} 最接近 40 的是 M = 5.4
best = min((abs(10 ** (1.44 * (6.5 - k / 10)) - 40), k / 10) for k in range(40, 66))[1]
assert best == 5.4

print("E3 驗算全部通過")
