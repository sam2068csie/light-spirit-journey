"""R7 方田拼圖（乘法公式）：設計稿 docs/num_r7_design.md 的數字驗算。
多項式的恆等式用很多組隨機數字代入確認（兩邊相等），等式審判的錯卡確認真的找得到讓兩邊不相等的數字，
天秤上的數字卡確認錯卡至少有一張會歪，根號的值用浮點數確認。"""
import random
from math import sqrt, isclose, floor

random.seed(7)
cbrt = lambda v: v ** (1 / 3) if v >= 0 else -((-v) ** (1 / 3))


def eq(x, y):
    assert isclose(x, y, rel_tol=1e-9, abs_tol=1e-9), (x, y)


def ident(f, g, n=3):
    """f、g 是 n 個變數的函數，隨機代 200 組都相等"""
    for _ in range(200):
        v = [random.uniform(-3, 3) for _ in range(n)]
        eq(f(*v), g(*v))


def not_ident(f, g, samples):
    """錯的等式：數字卡裡至少有一張讓天秤歪掉"""
    bad = [s for s in samples if not isclose(f(*s), g(*s), abs_tol=1e-9)]
    assert bad, "錯卡沒有一張數字卡會歪"
    return bad


# ============ 第一章 ============
# 1 等式審判（天秤：數字卡 (a, b) = (1, 1)、(2, 1)、(1, −1)、(2, −1)）
CARDS = [(1, 1), (2, 1), (1, -1), (2, -1), (0, 1)]
# 第 1 組
ident(lambda a, b: (a + 3 * b) ** 3, lambda a, b: a**3 + 9 * a**2 * b + 27 * a * b**2 + 27 * b**3, 2)      # ○
not_ident(lambda a, b: a**3 + 8 * b**3, lambda a, b: (a + 2 * b) * (a * a + 2 * a * b + 4 * b * b), CARDS)  # ✕（中間要 −2ab）
ident(lambda a, b: a**3 + 8 * b**3, lambda a, b: (a + 2 * b) * (a * a - 2 * a * b + 4 * b * b), 2)
ident(lambda a, b: a**3 - b**3, lambda a, b: (a - b) ** 3 + 3 * a * b * (a - b), 2)                            # ○
not_ident(lambda a, b: a * a + b * b, lambda a, b: (a - b) ** 2 - 2 * a * b, CARDS)                           # ✕（要 + 2ab）
ident(lambda a, b, c: a * a + b * b + c * c, lambda a, b, c: (a + b + c) ** 2 - 2 * (a * b + b * c + c * a), 3)  # ○
# 第 2 組
ident(lambda a, b: (2 * a - b) ** 3, lambda a, b: 8 * a**3 - 12 * a * a * b + 6 * a * b * b - b**3, 2)         # ○
not_ident(lambda a, b: 27 * a**3 - b**3, lambda a, b: (3 * a - b) * (9 * a * a - 3 * a * b + b * b), CARDS)    # ✕（要 + 3ab）
ident(lambda a, b: 27 * a**3 - b**3, lambda a, b: (3 * a - b) * (9 * a * a + 3 * a * b + b * b), 2)
ident(lambda a, b: a**3 + b**3, lambda a, b: (a + b) ** 3 - 3 * a * b * (a + b), 2)                            # ○
not_ident(lambda a, b: (a + b) ** 2 - (a - b) ** 2, lambda a, b: 2 * a * b, CARDS)                             # ✕（是 4ab）
ident(lambda a, b, c: (a + b + c) ** 2, lambda a, b, c: a*a + b*b + c*c + 2 * (a*b + b*c + c*a), 3)          # ○

# 2 看成一整塊
ident(lambda x, y: (x + 3 * y - 2) * (x - 3 * y + 2), lambda x, y: x * x - (3 * y - 2) ** 2, 2)
ident(lambda x, y: (x + 3 * y - 2) * (x - 3 * y + 2), lambda x, y: x * x - 9 * y * y + 12 * y - 4, 2)
ident(lambda x, y: (2 * x - y + 1) * (2 * x + y - 1), lambda x, y: 4 * x * x - y * y + 2 * y - 1, 2)

# 3 湊成平方差：點「剩下的剛好是正方形」那一個
ident(lambda x, y: x**4 - 7 * x * x * y * y + y**4, lambda x, y: (x * x + y * y) ** 2 - 9 * x * x * y * y, 2)
ident(lambda x, y: x**4 - 7 * x * x * y * y + y**4, lambda x, y: (x * x - y * y) ** 2 - 5 * x * x * y * y, 2)   # 5 不是平方數
ident(lambda x, y: x**4 - 7 * x * x * y * y + y**4, lambda x, y: (x * x + 3 * x * y + y * y) * (x * x - 3 * x * y + y * y), 2)
ident(lambda x, y: 4 * x**4 - 13 * x * x * y * y + y**4, lambda x, y: (2 * x * x - y * y) ** 2 - 9 * x * x * y * y, 2)
ident(lambda x, y: 4 * x**4 - 13 * x * x * y * y + y**4, lambda x, y: (2 * x * x + y * y) ** 2 - 17 * x * x * y * y, 2)  # 17 不是平方數
ident(lambda x, y: 4 * x**4 - 13 * x * x * y * y + y**4, lambda x, y: (2 * x * x + 3 * x * y - y * y) * (2 * x * x - 3 * x * y - y * y), 2)

# 4 兩兩配對
ident(lambda x: (x + 2) * (x - 2) * (x * x + 2 * x + 4) * (x * x - 2 * x + 4), lambda x: x**6 - 64, 1)
ident(lambda x: (x - 2) * (x * x + 2 * x + 4), lambda x: x**3 - 8, 1)
ident(lambda x: (x + 2) * (x * x - 2 * x + 4), lambda x: x**3 + 8, 1)
ident(lambda a: (2 * a + 1) * (2 * a - 1) * (4 * a * a + 2 * a + 1) * (4 * a * a - 2 * a + 1), lambda a: 64 * a**6 - 1, 1)

# 5 四次方的平方差
ident(lambda x, y: (3 * x - y) ** 4 - (x - 3 * y) ** 4, lambda x, y: 16 * (x + y) * (x - y) * (5 * x * x - 6 * x * y + 5 * y * y), 2)
ident(lambda x, y: (3 * x - y) ** 2 + (x - 3 * y) ** 2, lambda x, y: 10 * x * x - 12 * x * y + 10 * y * y, 2)
ident(lambda x, y: (3 * x - y) ** 2 - (x - 3 * y) ** 2, lambda x, y: 8 * (x + y) * (x - y), 2)
ident(lambda x, y: (x + 2 * y) ** 4 - (2 * x + y) ** 4, lambda x, y: -3 * (x + y) * (x - y) * (5 * x * x + 8 * x * y + 5 * y * y), 2)

# 6 立方根的有理化
eq(10 / (cbrt(36) + cbrt(6) + 1), 2 * cbrt(6) - 2)
eq((sqrt(3) + 1) / (sqrt(3) - 1) - sqrt(3) + cbrt(3 / 4) + 10 / (cbrt(36) + cbrt(6) + 1), 2.5 * cbrt(6))
eq(cbrt(3 / 4), cbrt(6) / 2)
eq(6 / (cbrt(16) + cbrt(4) + 1), 2 * cbrt(4) - 2)
eq((sqrt(2) + 1) / (sqrt(2) - 1) - 2 * sqrt(2) + cbrt(1 / 2) + 6 / (cbrt(16) + cbrt(4) + 1), 1 + 2.5 * cbrt(4))
eq(cbrt(1 / 2), cbrt(4) / 2)

# 7 三個殼一起剝（第三個要先乘 2 再除 2）
eq(sqrt(6 + sqrt(20)), sqrt(5) + 1)
eq(sqrt(14 - 6 * sqrt(5)), 3 - sqrt(5))
eq(sqrt(3 - sqrt(5)), (sqrt(10) - sqrt(2)) / 2)
eq(sqrt(6 + sqrt(20)) + sqrt(14 - 6 * sqrt(5)) + sqrt(3 - sqrt(5)), 4 + (sqrt(10) - sqrt(2)) / 2)
eq(sqrt(9 + sqrt(56)), sqrt(7) + sqrt(2))
eq(sqrt(23 - 8 * sqrt(7)), 4 - sqrt(7))
eq(sqrt(4 - sqrt(7)), (sqrt(14) - sqrt(2)) / 2)
eq(sqrt(9 + sqrt(56)) + sqrt(23 - 8 * sqrt(7)) + sqrt(4 - sqrt(7)), 4 + (sqrt(14) + sqrt(2)) / 2)

# 8 x + y + z = 0 的立方和
ident(lambda x, y, z: (x - 2 * y) ** 3 + (2 * y - 3 * z) ** 3 + (3 * z - x) ** 3, lambda x, y, z: 3 * (x - 2 * y) * (2 * y - 3 * z) * (3 * z - x), 3)
ident(lambda a, b, c: (a + b - 2 * c) ** 3 + (b + c - 2 * a) ** 3 + (c + a - 2 * b) ** 3,
      lambda a, b, c: 3 * (a + b - 2 * c) * (b + c - 2 * a) * (c + a - 2 * b), 3)

# ============ 第二章 ============
# 10 先分解再代
v = sqrt(12 - 6 * sqrt(3)); eq(v, 3 - sqrt(3)); a = floor(v); b = v - a
assert a == 1; eq(b, 2 - sqrt(3))
ident(lambda a, b: b**3 - 6 * a * b * b + 12 * a * a * b - 8 * a**3, lambda a, b: (b - 2 * a) ** 3, 2)
eq(b - 2 * a, -sqrt(3)); eq((b - 2 * a) ** 3, -3 * sqrt(3))
v = sqrt(11 - 6 * sqrt(2)); eq(v, 3 - sqrt(2)); a = floor(v); b = v - a
assert a == 1; eq(b, 2 - sqrt(2)); eq(b - 2 * a, -sqrt(2)); eq((b - 2 * a) ** 3, -2 * sqrt(2))

# 11 倒數的梯子（x 是根號式）
for x, xm, xp, x2p, x2m, x3p, x4m in [
        (3 + sqrt(10), 6, 2 * sqrt(10), 38, 12 * sqrt(10), 74 * sqrt(10), 456 * sqrt(10)),
        (-1 + sqrt(2), -2, 2 * sqrt(2), 6, -4 * sqrt(2), 10 * sqrt(2), -24 * sqrt(2))]:
    eq(x - 1 / x, xm); eq(x + 1 / x, xp); eq(x * x + 1 / x**2, x2p); eq(x * x - 1 / x**2, x2m)
    eq(x**3 + 1 / x**3, x3p); eq(x**4 - 1 / x**4, x4m)
eq(1 / (3 + sqrt(10)), sqrt(10) - 3); eq(1 / (-1 + sqrt(2)), sqrt(2) + 1)

# 12 梯子：t + 1/t = k
for k, t2, t3, t4, t6, tm in [(sqrt(6), 4, 3 * sqrt(6), 14, 52, sqrt(2)), (3, 7, 18, 47, 322, sqrt(5))]:
    t = (k + sqrt(k * k - 4)) / 2
    eq(t + 1 / t, k); eq(t * t + 1 / t**2, t2); eq(t**3 + 1 / t**3, t3); eq(t**4 + 1 / t**4, t4); eq(t**6 + 1 / t**6, t6)
    eq(abs(t - 1 / t), tm); eq((1 / t) - t, -tm)   # t − 1/t 可正可負

# 13 雙重根號相加，再代進去
for p, q, a2, ans in [(5, 21, 14, 211), (3, 5, 10, 111)]:
    a = sqrt(p + sqrt(q)) + sqrt(p - sqrt(q))
    eq(a * a, a2); eq((a * a + a + 1) * (a * a - a + 1), ans); eq(a**4 + a * a + 1, ans)
ident(lambda a: (a * a + a + 1) * (a * a - a + 1), lambda a: a**4 + a * a + 1, 1)

# 14 對稱式互求
for s, p, s2, s3, s5 in [(4, 2, 12, 40, 464), (5, 3, 19, 80, 1475)]:
    a = (s + sqrt(s * s - 4 * p)) / 2; b = s - a
    eq(a * b, p); eq(a * a + b * b, s2); eq(a**3 + b**3, s3); eq(a**5 + b**5, s5)
    eq(s2 * s3 - p * p * s, s5)

# 15 根號裡的絕對值
for lo, hi, f, ab in [
        (1 / 3, 1 / 2, lambda x: sqrt(9*x*x - 6*x + 1) + sqrt(x*x + 4 + 4/x**2) - 2 * sqrt(x*x - 2 + 1/x**2), (6, -1)),
        (1 / 2, 1, lambda x: sqrt(4*x*x - 4*x + 1) + sqrt(x*x + 2 + 1/x**2) - sqrt(x*x - 2 + 1/x**2), (4, -1))]:
    for _ in range(100):
        x = random.uniform(lo + 1e-6, hi - 1e-6)
        eq(f(x), ab[0] * x + ab[1])
for _ in range(100):  # 正負號
    x = random.uniform(1 / 3, 1 / 2); assert 3 * x - 1 > 0 and x + 2 / x > 0 and x - 1 / x < 0
    x = random.uniform(1 / 2, 1); assert 2 * x - 1 > 0 and x + 1 / x > 0 and x - 1 / x < 0

# 16 平方和 ≤ 0
for _ in range(200):
    a, b, c, d = (random.uniform(-3, 3) for _ in range(4))
    eq(a*a + b*b + c*c + d*d + 10 - (2*a + 4*b - 2*c + 4*d), (a-1)**2 + (b-2)**2 + (c+1)**2 + (d-2)**2)
    eq(a*a + b*b + c*c + 6 - (2*a - 4*b + 2*c), (a-1)**2 + (b+2)**2 + (c-1)**2)
assert 1 + 2 - 1 + 2 == 4 and 1 - 2 + 1 == 0

# 17 三個平方（p² + q² + r² − pq − qr − rp = ½[(p − q)² + (q − r)² + (r − p)²]）
ident(lambda p, q, r: p*p + q*q + r*r - p*q - q*r - r*p, lambda p, q, r: ((p-q)**2 + (q-r)**2 + (r-p)**2) / 2, 3)
ident(lambda x, y: 4*x*x + y*y - 2*x*y + 6*x + 3*y + 9, lambda x, y: (lambda p, q, r: p*p + q*q + r*r - p*q - q*r - r*p)(2*x, y, -3), 2)
eq(4*2.25 + 9 - 2*(-1.5)*(-3) + 6*(-1.5) + 3*(-3) + 9, 0)                 # x = −3/2、y = −3
ident(lambda x, y: x*x + 9*y*y - 3*x*y + 2*x + 6*y + 4, lambda x, y: (lambda p, q, r: p*p + q*q + r*r - p*q - q*r - r*p)(x, 3*y, -2), 2)
eq(4 + 9 * (4 / 9) - 3 * (-2) * (-2 / 3) + 2 * (-2) + 6 * (-2 / 3) + 4, 0)    # x = −2、y = −2/3

print("R7 驗算全部通過")
