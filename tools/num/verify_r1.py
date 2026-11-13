"""R1 風車小數（data/levels/num/num1_bank.gd）的驗算：每一題的答案、錯的選項、反例、排序。
執行：python3 tools/num/verify_r1.py（全部 assert 通過才會印出 OK）"""
from fractions import Fraction as F
from math import sqrt, gcd
import random

def rep(i, pre, r):
    """i.pre(r) 循環小數的值，例如 rep(1, "2", "36") = 1.2363636…"""
    n, k = len(pre), len(r)
    a = int(str(i) + pre + r); b = int(str(i) + pre)
    return F(a - b, (10**k - 1) * 10**n)

def finite(f):
    d = f.denominator
    for p in (2, 5):
        while d % p == 0: d //= p
    return d == 1

def digits(f, n):
    x = f - int(f); out = ""
    for _ in range(n):
        x *= 10; out += str(int(x)); x -= int(x)
    return out

# ---- 第一章 ----
# dense
assert (F(3, 10) + F(31, 100)) / 2 == F(61, 200) == F("0.305")
assert (F(3, 10) + F("0.305")) / 2 == F(121, 400) == F("0.3025")
assert (F(1, 3) + F(1, 2)) / 2 == F(5, 12) and (F(1, 3) + F(5, 12)) / 2 == F(3, 8)
# pure / mixed
assert rep(0, "", "27") == F(27, 99) == F(3, 11)
assert rep(0, "", "153") == F(153, 999) == F(17, 111)
assert rep(1, "2", "36") == F(1236 - 12, 990) == F(68, 55)
assert rep(0, "58", "3") == F(583 - 58, 900) == F(7, 12)
# nine
assert rep(0, "", "9") == 1 and rep(0, "1", "9") == F(18, 90) == F(1, 5) and rep(2, "4", "9") == F(5, 2)
# bound：a 唯一
assert [a for a in range(1, 10) if F(4, 9) < F(10 * a + 3, 99) < F(7, 11)] == [5]
assert F(4, 9) == F(44, 99) and F(7, 11) == F(63, 99)
assert [a for a in range(1, 10) if F(2, 9) < F(10 * a + 7, 99) < F(29, 99)] == [2]
assert F(2, 9) == F(22, 99)
# f2d
assert F(41, 33) == F(123, 99) == 1 + F(24, 99) == rep(1, "", "24")
for wrong in [rep(1, "2", "4"), rep(1, "", "240"), F("1.24")]:
    assert wrong != F(41, 33)
assert F(17, 3) == 5 + F(2, 3) and F(2, 3) == rep(0, "", "6")
for wrong in [F("0.6"), rep(0, "", "3"), rep(0, "", "60")]:
    assert wrong != F(2, 3)
assert F(17, 30) == rep(0, "5", "6")
for wrong in [rep(0, "", "56"), rep(5, "", "6"), F("0.56")]:
    assert wrong != F(17, 30)
# fin
assert F(21, 56) == F(3, 8) and finite(F(3, 8))
assert [finite(F(a, b)) for a, b in [(9, 42), (33, 75), (14, 45), (27, 120)]] == [False, True, False, True]
assert F(26, 65) == F(2, 5) and finite(F(2, 5))
assert [finite(F(a, b)) for a, b in [(18, 48), (35, 42), (39, 130), (12, 54)]] == [True, False, True, False]
# hidden：a 唯一
assert [a for a in range(1, 10) if finite(F(30 + a, 70))] == [5]
assert [a for a in range(0, 10) if finite(F(102 + 10 * a, 110))] == [3]
assert F(30, 70) != F(1, 2) and not finite(F(30, 70))       # 「分子是 10 的倍數」錯：30 不行
assert not finite(F(32, 70)) and not finite(F(35, 70)) is False   # 「2 的倍數」不夠（32 不行）；35 是 5 的倍數也是 7 的倍數，關鍵是 7
assert not finite(F(30, 70)) and not finite(F(31 + 4, 70)) is False
# nth
d = digits(F(1, 7), 100); assert d[:6] == "142857" and 100 == 6 * 16 + 4 and d[99] == "8"
d = digits(F(5, 13), 60); assert d[:6] == "384615" and 50 == 6 * 8 + 2 and d[49] == "8"
# add
s = rep(0, "", "4") + rep(0, "", "36"); assert s == F(80, 99) == rep(0, "", "80")
for wrong in [rep(0, "", "40"), rep(0, "", "8"), F("0.80")]:
    assert wrong != s
s = rep(0, "", "6") + rep(0, "", "45"); assert s == F(111, 99) == rep(1, "", "12")
for wrong in [rep(0, "", "51"), rep(1, "", "11"), F("1.12")]:
    assert wrong != s

# ---- 第二章 ----
# ratio：相似三角形
A, Q = 2, -6; P = A + F(Q - A, 3); assert P == F(-2, 3) and A - Q == 8 and F(A - Q, 3) == F(8, 3)
A, Q = 3, -6; P = A + F(2, 5) * (Q - A); assert P == F(-3, 5) and A - Q == 9 and F(2, 5) * 9 == F(18, 5)
for B, D, Qp, Px in [((1.5, 1.2), (0.5, 3.6), (-6, 0), -2 / 3), ((2.2, 1.6), (1, 4), (-6, 0), -0.6)]:
    # \ol{BP} ∥ \ol{DQ}：斜率一樣（P 不是整數，從方格上讀不出來）
    m1 = B[1] / (B[0] - Px); m2 = D[1] / (D[0] - Qp[0]); assert abs(m1 - m2) < 1e-9
# semi
assert abs(sqrt(2 * 3) - sqrt(6)) < 1e-12 and 1 * 6 == 6 and 1 * 10 == 10
for _ in range(10000):
    a, b = random.uniform(0.01, 20), random.uniform(0.01, 20)
    assert (a + b) / 2 >= sqrt(a * b) - 1e-12
# negfrac
vals = {"a": -F(13, 17), "b": -F(23, 27), "c": -F(43, 47)}
assert sorted(vals, key=vals.get) == ["c", "b", "a"] and 1 - F(13, 17) == F(4, 17)
vals = {"a": F(5, 11), "b": F(10, 23), "c": F(15, 34)}
assert sorted(vals, key=vals.get) == ["b", "c", "a"] and F(5, 11) == F(30, 66) and F(10, 23) == F(30, 69) and F(15, 34) == F(30, 68)
# mean：○ 的卡掃過沒有反例，✕ 的卡只有正解那組是反例
for _ in range(100000):
    b = random.uniform(0.01, 10); a = b + random.uniform(1e-3, 10)
    assert b < (3 * a + 5 * b) / 8 < a and b < (4 * a + b) / 5 < a
    x, y, z, w = [random.uniform(0.01, 10) for _ in range(4)]
    if y / x < w / z:
        assert y / x < (y + w) / (x + z) < w / z
out7 = lambda a, b: not (b < (3 * a + 5 * b) / 7 < a)
assert [out7(a, b) for a, b in [(11, 10), (2, 1), (7, 0.5), (3, 2)]] == [True, False, False, False]
out6 = lambda a, b: not (b < (4 * a + 3 * b) / 6 < a)
assert [out6(a, b) for a, b in [(3, 2.5), (3, 1), (6, 2), (9, 3)]] == [True, False, False, False]
assert F(83, 8) == F(33 + 50, 8) and 4 * 3 + 2.5 == 14.5 and (4 * 3 + 2.5) / 5 == 2.9 and (12 + 7.5) / 6 == 3.25
# rootadd
a, b, c = sqrt(11) + sqrt(3), sqrt(10) + 2, sqrt(8) + sqrt(6); assert a < b < c
assert abs(a * a - (14 + 2 * sqrt(33))) < 1e-9 and abs(b * b - (14 + 2 * sqrt(40))) < 1e-9 and abs(c * c - (14 + 2 * sqrt(48))) < 1e-9
a, b, c = sqrt(11) + 1, 3 + sqrt(3), sqrt(7) + sqrt(5); assert a < b < c
assert abs(a * a - (12 + 2 * sqrt(11))) < 1e-9 and abs(b * b - (12 + 2 * sqrt(27))) < 1e-9 and abs(c * c - (12 + 2 * sqrt(35))) < 1e-9
# rootsub
a, b, c = sqrt(15) - sqrt(13), sqrt(12) - sqrt(10), 3 - sqrt(7); assert a < b < c and abs(a - 2 / (sqrt(15) + sqrt(13))) < 1e-12
a, b, c = sqrt(14) - sqrt(11), sqrt(10) - sqrt(7), sqrt(6) - sqrt(3); assert a < b < c and abs(a - 3 / (sqrt(14) + sqrt(11))) < 1e-12
# round
def rnd1(f):  # 四捨五入到小數第一位
    return int(f * 10 + F(1, 2)) / F(10)
for total, target, cands, keep in [(50, F(4, 10), [13, 14, 15], 13), (40, F(3, 10), [8, 9, 10], 9)]:
    xs = [x for x in range(1, total) if rnd1(F(x, total - x)) == target]
    assert xs == cands, (total, xs)
    assert [x for x in xs if gcd(x, total - x) == 1] == [keep]
# rules
a, b, c, d = 1, -1, -1, -2; assert a > b and c > d and not a * c > b * d and not 1 / a < 1 / b
for q in [(3, 2, 5, 4), (4, 1, 3, 2), (2, 1, 6, 5)]:
    assert q[0] > q[1] and q[2] > q[3] and q[0] * q[2] > q[1] * q[3]
for q in [(5, 1, 2, 1), (6, 2, 3, 2), (4, 2, 1, 0)]:
    assert q[0] > q[1] and q[2] > q[3] and q[0] - q[2] > q[1] - q[3]
a, b, c, d = 2, 1, 5, 0; assert a > b and c > d and not a - c > b - d
for _ in range(100000):
    b, d = random.uniform(-10, 10), random.uniform(-10, 10); a, c = b + random.uniform(1e-3, 9), d + random.uniform(1e-3, 9)
    assert a + c > b + d and a + 2 * c > b + 2 * d
    if c * c < d * d: assert abs(c) < abs(d)
assert not (1 ** 2 > (-2) ** 2)
# signs
a, b, c = -2, -1.5, 3; assert a < b < c and a * b * c > 0 and a + b + c < 0 and not abs(a) > abs(c)
a, b, c = -5, 1, 6; assert a < b < c and a * b * c < 0 and a + b + c > 0 and not a + b > 0
print("R1 verify OK")
