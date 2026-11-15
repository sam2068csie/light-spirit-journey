"""R6 剝殼磨坊（雙重根號）：設計稿 docs/num_r6_design.md 的數字驗算。
每個化簡都用浮點數確認，配對（m + n = a、mn = b）確認只有一組，估整數部分時每一層用整數夾出來的範圍也確認落在同一段。"""
from math import sqrt, isclose, floor, isqrt


def pairs(b):
    return [(b // m, m) for m in range(1, isqrt(b) + 1) if b % m == 0]


def only_pair(a, b):
    ps = [p for p in pairs(b) if sum(p) == a]
    assert len(ps) == 1, (a, b, ps)
    return ps[0]


def eq(x, y):
    assert isclose(x, y, rel_tol=1e-12, abs_tol=1e-12), (x, y)

# 1 找兩個數
assert only_pair(11, 24) == (8, 3) and len(pairs(24)) == 4
eq(sqrt(11 + 2 * sqrt(24)), 2 * sqrt(2) + sqrt(3))
assert only_pair(13, 30) == (10, 3) and len(pairs(30)) == 4
eq(sqrt(13 + 2 * sqrt(30)), sqrt(10) + sqrt(3))

# 2 減號：大的在前
assert only_pair(8, 15) == (5, 3)
eq(sqrt(8 - 2 * sqrt(15)), sqrt(5) - sqrt(3))
assert sqrt(3) - sqrt(5) < 0
assert only_pair(12, 35) == (7, 5)
eq(sqrt(12 - 2 * sqrt(35)), sqrt(7) - sqrt(5))

# 3 先湊出 2√b
assert 4 ** 2 * 6 == 4 * 24 and only_pair(11, 24) == (8, 3)
eq(sqrt(11 - 4 * sqrt(6)), 2 * sqrt(2) - sqrt(3))
assert 6 ** 2 * 2 == 4 * 18 and only_pair(9, 18) == (6, 3)
eq(sqrt(9 + 6 * sqrt(2)), sqrt(6) + sqrt(3))

# 4 兩層
eq(sqrt(6 + 2 * sqrt(5)), sqrt(5) + 1)
eq(sqrt(5 + 4 * sqrt(6 + 2 * sqrt(5))), sqrt(9 + 4 * sqrt(5)))
eq(sqrt(9 + 4 * sqrt(5)), 2 + sqrt(5))
assert only_pair(9, 20) == (5, 4)
eq(sqrt(4 + 2 * sqrt(3)), sqrt(3) + 1)
eq(sqrt(4 + 4 * sqrt(4 + 2 * sqrt(3))), sqrt(6) + sqrt(2))
assert only_pair(8, 12) == (6, 2)

# 5 化簡後比較係數
eq(sqrt(4 - 2 * sqrt(3)), sqrt(3) - 1); eq(sqrt(7 - 4 * sqrt(3)), 2 - sqrt(3)); eq(sqrt(4 + 2 * sqrt(3)), sqrt(3) + 1)
a, b = 3, 2
assert -a + 2 * b == 1 and a - b == 1
eq(a * sqrt(4 - 2 * sqrt(3)) + b * sqrt(7 - 4 * sqrt(3)), sqrt(4 + 2 * sqrt(3)))
eq(sqrt(3 - 2 * sqrt(2)), sqrt(2) - 1); eq(sqrt(6 - 4 * sqrt(2)), 2 - sqrt(2)); eq(sqrt(9 + 4 * sqrt(2)), 2 * sqrt(2) + 1)
a, b = 5, 3
assert -a + 2 * b == 1 and a - b == 2
eq(a * sqrt(3 - 2 * sqrt(2)) + b * sqrt(6 - 4 * sqrt(2)), sqrt(9 + 4 * sqrt(2)))


# 7 由內往外夾：每一層只用上一層的整數範圍，也要確定落在哪兩個整數之間
def layer(lo, hi, f):
    """上一層在 (lo, hi) 之間，這一層 = f(上一層)，回傳用整數夾出來的範圍"""
    return f(lo), f(hi)


def same_int(lo, hi, want):
    assert want <= lo and hi <= want + 1, (lo, hi, want)          # 端點取不到（上一層嚴格在兩個整數之間）

for c1, k1, p, c2, k2, ints, x in [(30, 2, 10, 20, 2, (3, 6, 5), sqrt(20 + 2 * sqrt(30 + 2 * sqrt(10)))),
                                   (40, 3, 5, 30, 2, (2, 6, 6), sqrt(30 + 2 * sqrt(40 + 3 * sqrt(5))))]:
    r0 = ints[0]
    assert r0 ** 2 < p < (r0 + 1) ** 2
    lo, hi = layer(r0, r0 + 1, lambda t: sqrt(c1 + k1 * t))
    same_int(lo, hi, ints[1])
    lo2, hi2 = layer(ints[1], ints[1] + 1, lambda t: sqrt(c2 + k2 * t))
    same_int(lo2, hi2, ints[2])
    assert floor(x) == ints[2]

# 8 先化簡再夾
eq(sqrt(6 - 2 * sqrt(5)), sqrt(5) - 1)
eq(sqrt(13 + 4 * sqrt(6 - 2 * sqrt(5))), 2 + sqrt(5))
assert floor(2 + sqrt(5)) == 4
# 第 2 組：√(6 + 2√(4 − 2√3)) = √(4 + 2√3) = √3 + 1（講義是 √(11 + 4√(4 − √12)) = 2 + √3，數字不一樣）
eq(sqrt(4 - 2 * sqrt(3)), sqrt(3) - 1)
eq(sqrt(6 + 2 * sqrt(4 - 2 * sqrt(3))), sqrt(4 + 2 * sqrt(3)))
eq(sqrt(4 + 2 * sqrt(3)), sqrt(3) + 1)
assert floor(sqrt(3) + 1) == 2 and only_pair(4, 3) == (3, 1)

# 9 代入求值
eq(sqrt(7 - 2 * sqrt(6)), sqrt(6) - 1)
v = sqrt(9 + 2 * sqrt(7 - 2 * sqrt(6)))
eq(v, sqrt(6) + 1)
a, b = 3, sqrt(6) - 2
assert floor(v) == a
eq(2 / b + 5 / (a + b), 2 * sqrt(6) + 1)
eq(sqrt(3 - 2 * sqrt(2)), sqrt(2) - 1)
v = sqrt(5 + 2 * sqrt(3 - 2 * sqrt(2)))
eq(v, sqrt(2) + 1)
a, b = 2, sqrt(2) - 1
assert floor(v) == a
eq(1 / b + 1 / (a + b), 2 * sqrt(2))

# 10 反過來：a² + b² = S，b 是 a 的小數部分
for S, n, lin, root, k3 in [(40, 6, (6, 2), 11, (4, 6)), (20, 4, (4, 2), 6, (4, 4))]:
    a = n / 2 + sqrt(root)
    b = a - n
    assert n ** 2 < S and S - 1 < a * a < S and 0 < b < 1 and floor(a) == n
    eq(a * a + b * b, S)
    eq(b * b + lin[0] * b - lin[1], 0)
    eq(a + 3 * b, k3[0] * sqrt(root) - k3[1])
print("R6 verify OK")
