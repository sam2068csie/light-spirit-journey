"""R2 繩上珠子（分點公式）設計稿 docs/num_r2_design.md 的驗算。
執行：python3 tools/num/verify_r2.py（全部 assert 通過才會印出 OK）"""
from fractions import Fraction as F
from math import sqrt
import random

def inner(a, b, m, n):      # \ol{AP} : \ol{PB} = m : n，P 在 \ol{AB} 上
    return F(n * a + m * b, m + n)
def outer(a, b, m, n):      # \ol{AP} : \ol{PB} = m : n，P 在 \ol{AB} 外面（m ≠ n）
    return F(m * b - n * a, m - n)
def ratio_ok(a, b, p, m, n):
    return abs(p - a) * n == abs(p - b) * m

# ---- 第一章 ----
# 1 繩上的珠子：A(−3)、B(9)，AP:PB = 1:2 ⇒ P = 1；錯的公式（權重放反）得 5
assert inner(-3, 9, 1, 2) == 1 and F(2 * -3 + 1 * 9, 3) == 1 and F(1 * -3 + 2 * 9, 3) == 5
assert inner(-4, 11, 2, 3) == 2 and F(3 * -4 + 2 * 11, 5) == 2 and F(2 * -4 + 3 * 11, 5) == 5      # 第 2 組
# 2 兩個位置：AC:BC = 3:2（A(−2)、B(8)），4:3（A(−5)、B(9)）
assert inner(-2, 8, 3, 2) == 4 and outer(-2, 8, 3, 2) == 28 and ratio_ok(-2, 8, 4, 3, 2) and ratio_ok(-2, 8, 28, 3, 2)
assert inner(-5, 9, 4, 3) == 3 and outer(-5, 9, 4, 3) == 51 and ratio_ok(-5, 9, 3, 4, 3) and ratio_ok(-5, 9, 51, 4, 3)
for a, b, m, n, sols in [(-2, 8, 3, 2, {4, 28}), (-5, 9, 4, 3, {3, 51})]:      # 只有這兩個解，外分點在比較近的 B 那一邊
    found = {F(x, 4) for x in range(-1000, 1000) if ratio_ok(a, b, F(x, 4), m, n)}
    assert found == sols and max(sols) > b
# 3 縮小比例：甲乙 6、乙丙 2，甲 = 1、丙 = 5；甲乙 4、乙丙 1，甲 = 2、丙 = 7
for d_ab, d_bc, x_a, x_c, ans in [(6, 2, 1, 5, {4, 7}), (4, 1, 2, 7, {6, F(26, 3)})]:
    got = set()
    # 乙在中間：甲丙 = d_ab + d_bc；丙在中間：甲丙 = d_ab − d_bc；甲在中間：甲丙 = d_bc − d_ab（< 0，不可能）
    assert d_bc - d_ab <= 0
    for d_ac, mid in [(d_ab + d_bc, "乙"), (d_ab - d_bc, "丙")]:
        k = F(x_c - x_a, d_ac)               # 每公里幾單位
        got.add(x_a + k * d_ab)
    assert got == ans, got
assert inner(1, 5, 3, 1) == 4 and F(1 + 2 * 7, 3) == 5                 # 乙 = (1·1 + 3·5)/4；丙 = (1 + 2乙)/3
assert inner(2, 7, 4, 1) == 6 and F(2 + 3 * F(26, 3), 4) == 7
# 4 追趕：甲 −3、乙 9、甲 4 倍；甲 −4、乙 6、甲 3 倍
for a, b, k, ans in [(-3, 9, 4, 13), (-4, 6, 3, 11)]:
    d = F(b - a, k - 1); assert a + k * d == b + d == ans and outer(a, b, k, 1) == ans and ans > b

# ---- 第二章 ----
# 5 比例的判斷：2|x − a| = 3|x − b|（a = 0、b = 5）、3|x − a| = |x − b|（a = 0、b = 8）
for _ in range(2000):
    a = random.randint(-20, 20); b = a + random.randint(1, 20)
    for x in [inner(a, b, 3, 2), outer(a, b, 3, 2)]:
        assert 2 * abs(x - a) == 3 * abs(x - b) and x > F(a + b, 2)      # ○：PA:PB = 3:2、x > (a + b)/2
    assert outer(a, b, 3, 2) > b                                          # ✕：不一定在 \ol{AB} 上
    assert 5 * abs(outer(a, b, 3, 2) - a) != 3 * abs(a - b)               # ✕：5|x − a| = 3|a − b| 只有內分點對
    for x in [inner(a, b, 1, 3), outer(a, b, 1, 3)]:
        assert 3 * abs(x - a) == abs(x - b) and x < F(a + b, 2)          # ○：PA:PB = 1:3、x < (a + b)/2
    assert outer(a, b, 1, 3) < a                                          # ✕：x > a 不一定
assert inner(0, 5, 3, 2) == 3 and outer(0, 5, 3, 2) == 15 and inner(0, 8, 1, 3) == 2 and outer(0, 8, 1, 3) == -4
# 6 加權平均的位置（以 a 到 c 的比例表示位置：\frac{ma + nc}{m + n} 在 n/(m + n)）
pos = lambda wa, wc: F(wc, wa + wc)
# 第 1 組：|c − a| = 4|b − a| ⇒ b = (3a + c)/4；r = (a + 3b)/4 = (13a + 3c)/16
assert pos(3, 1) == F(1, 4)
r = F(1, 4) * 0 + F(3, 4) * F(1, 4); assert r == F(3, 16) == pos(13, 3)
P, Q = pos(3, 5), pos(1, 1); assert r < Q < P               # r < q < p
# 第 2 組：|c − b| = 2|b − a| ⇒ b = (2a + c)/3；q = (a + 2b)/3 = (7a + 2c)/9；r = (b + c)/2 = (a + 2c)/3
bpos = F(1, 3); assert bpos == pos(2, 1)
q = F(2, 3) * bpos; assert q == pos(7, 2) == F(2, 9)
r = (bpos + 1) / 2; assert r == pos(1, 2) == F(2, 3)
p = pos(2, 3); assert q < p < r                              # q < p < r
for _ in range(1000):                                        # 換成真的數字也對
    a = random.uniform(-10, 10); c = a + random.uniform(0.1, 10)
    b = (3 * a + c) / 4; assert (a + 3 * b) / 4 < (a + c) / 2 < (3 * a + 5 * c) / 8
    b = (2 * a + c) / 3; assert (a + 2 * b) / 3 < (2 * a + 3 * c) / 5 < (b + c) / 2
# 7 根號的分點
a, b = sqrt(3), sqrt(6)
p, q, r = (2 * a + b) / 3, (a + 3 * b) / 4, (5 * b - a) / 4
assert a < p < q < b < r and abs(p - (a + (b - a) / 3)) < 1e-12 and abs(r - (b + (b - a) / 4)) < 1e-12
a, b = sqrt(2), sqrt(5)
p, q, r = (3 * a + b) / 4, (a + 2 * b) / 3, (4 * a - b) / 3
assert r < a < p < q < b and abs(r - (a - (b - a) / 3)) < 1e-12
print("R2 verify OK")
