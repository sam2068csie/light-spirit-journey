"""V4 長弓靶場（3-2 重點二、三：求長度、求夾角）設計稿 docs/vec2_v4_design.md 的驗算。
執行：python3 tools/vec2/verify_v4.py（全部 assert 通過才會印出 OK）
長度平方、內積用 Fraction 算；有根號的答案再用浮點數對一次。"""
from fractions import Fraction as F
import math, random

def dot(a, b): return a[0] * b[0] + a[1] * b[1]
def cross(a, b): return a[0] * b[1] - a[1] * b[0]
def sub(p, q): return (q[0] - p[0], q[1] - p[1])
def add(*vs): return tuple(sum(v[i] for v in vs) for i in range(2))
def mul(k, v): return (k * v[0], k * v[1])
def n2(a): return dot(a, a)
COS = {0: F(1), 60: F(1, 2), 90: F(0), 120: F(-1, 2), 180: F(-1)}

def sq(ca, cb, la2, lb2, ab):
    """|ca·a + cb·b|^2，la2 = |a|^2、lb2 = |b|^2、ab = a·b"""
    return ca * ca * la2 + 2 * ca * cb * ab + cb * cb * lb2

def ang(u, v):
    c = dot(u, v) / math.sqrt(n2(u) * n2(v))
    return math.degrees(math.acos(max(-1.0, min(1.0, c))))

# ======== 第一章 求長度 ========
# 1 兩條對角線：|a ± b|^2
for la, lb, th, plus, minus in [(3, 4, 60, 37, 13), (4, 2, 120, 12, 28)]:
    ab = la * lb * COS[th]
    assert sq(1, 1, la * la, lb * lb, ab) == plus and sq(1, -1, la * la, lb * lb, ab) == minus
    assert plus + minus == 2 * (la * la + lb * lb)                       # 平行四邊形定理

# 2 已知內積求長度（A51 型）：\vec{PQ} = \vec{OQ} − \vec{OP}
for la, lb, th, P, Q, d, want in [(3, 1, 60, (1, 2), (2, 3), (1, 1), 13), (2, 2, 120, (3, -1), (4, 1), (1, 2), 12)]:
    ab = la * lb * COS[th]
    assert (Q[0] - P[0], Q[1] - P[1]) == d
    assert sq(d[0], d[1], la * la, lb * lb, ab) == want                  # √13、2√3

# 3 已知長度求內積（A52 型）
for la, lb, c1, L1, c2, ab_want, L2 in [(2, 1, (1, 3), 19, (2, -1), 1, 13), (3, 2, (2, 1), 28, (1, -1), -3, 19)]:
    # L1 = c1a^2 la^2 + 2 c1a c1b ab + c1b^2 lb^2
    ab = F(L1 - c1[0] ** 2 * la * la - c1[1] ** 2 * lb * lb, 2 * c1[0] * c1[1])
    assert ab == ab_want
    assert abs(ab) <= la * lb                                             # 這樣的夾角存在
    assert sq(c2[0], c2[1], la * la, lb * lb, ab) == L2
# 對照：第 1 組 cos θ = \frac{1}{2}（60°）、第 2 組 cos θ = −\frac{1}{2}（120°）
assert F(1, 2 * 1) == F(1, 2) and F(-3, 3 * 2) == F(-1, 2)

# 4 長度的範圍（A53 型）：|a + kb| 在 ||a| − k|b|| 到 |a| + k|b| 之間
for la, lb, k, th, lo, hi, at in [(3, 2, 2, 120, 1, 7, 13), (5, 1, 3, 60, 2, 8, 49)]:
    vals = [math.sqrt(la * la + k * k * lb * lb + 2 * la * k * lb * math.cos(math.radians(d))) for d in range(0, 360, 15)]
    assert abs(min(vals) - lo) < 1e-9 and abs(max(vals) - hi) < 1e-9
    assert sq(1, k, la * la, lb * lb, la * lb * COS[th]) == at              # √13、7

# 5 |a + tb| 的最小值（A55 型）：最短時 (a + tb) ⊥ b
for la, lb, th, t, m2 in [(2, 1, 120, 1, 3), (4, 2, 60, -1, 12)]:
    ab = la * lb * COS[th]
    tt = -ab / (lb * lb)
    assert tt == t
    assert sq(1, tt, la * la, lb * lb, ab) == m2                          # √3、2√3
    for k in range(-40, 41):
        s = F(k, 8)
        assert sq(1, s, la * la, lb * lb, ab) >= m2                       # 真的是最小
    assert ab + tt * lb * lb == 0                                          # (a + tb)·b = 0
# 講義 A55：|a| = 4、|b| = 3、60° ⇒ t = −\frac{2}{3}、最小 2√3
assert -F(6) / 9 == F(-2, 3) and sq(1, F(-2, 3), 16, 9, 6) == 12

# 6 變化 A：外心（A54 型），R = 4，∠A = 75°、∠B = 45°、∠C = 60°
R = 4
cen = {"BOC": 150, "COA": 90, "AOB": 120}                                 # 圓心角 = 2 × 圓周角
assert cen == {"BOC": 2 * 75, "COA": 2 * 45, "AOB": 2 * 60}
s = 3 * R * R + 2 * R * R * sum(math.cos(math.radians(v)) for v in cen.values())
assert abs(s - (32 - 16 * math.sqrt(3))) < 1e-9                           # 32 − 16√3
assert abs(math.sqrt(s) - (2 * math.sqrt(6) - 2 * math.sqrt(2))) < 1e-9   # 2√6 − 2√2
# 畫出來驗：O 在原點，A、B、C 在半徑 4 的圓上
pa = (R * math.cos(math.radians(90)), R * math.sin(math.radians(90)))
pb = (R * math.cos(math.radians(90 + 120)), R * math.sin(math.radians(90 + 120)))
pc = (R * math.cos(math.radians(90 - 90)), R * math.sin(math.radians(90 - 90)))
def angle_at(P, Q, S): return ang(sub(P, Q), sub(P, S))
assert abs(angle_at(pa, pb, pc) - 75) < 1e-9 and abs(angle_at(pb, pa, pc) - 45) < 1e-9
tot = add(pa, pb, pc)
assert abs(math.hypot(*tot) - (2 * math.sqrt(6) - 2 * math.sqrt(2))) < 1e-9
# 變化 B：角平分線（A56 型），AB = 3、AC = 6、BC = 7
AB, AC, BC = 3, 6, 7
abac = F(AB * AB + AC * AC - BC * BC, 2)
assert abac == -2
x, y = F(AC, AB + AC), F(AB, AB + AC)                                     # BD : DC = AB : AC = 1 : 2
assert (x, y) == (F(2, 3), F(1, 3))
assert sq(x, y, AB * AB, AC * AC, abac) == F(64, 9)                       # AD = \frac{8}{3}

# 7 速算：|a|、|b|、θ ∈ {0, 60, 90, 120, 180}，|a + b|^2 是整數
for la in range(1, 6):
    for lb in range(1, 6):
        for th in COS:
            assert sq(1, 1, la * la, lb * lb, la * lb * COS[th]).denominator == 1

# ======== 第二章 求夾角 ========
# 8 內積的正負和夾角：反例
a = (3, 0)
assert dot(a, (2, 0)) > 0 and ang(a, (2, 0)) == 0                       # a·b > 0 但夾角 0°（不是銳角）
assert dot(a, (-2, 0)) < 0 and abs(ang(a, (-2, 0)) - 180) < 1e-9        # a·b < 0 但夾角 180°（不是鈍角）
assert dot(a, (0, 2)) == 0                                                # a·b = 0：a、b 都不是 0
for _ in range(2000):                                                     # 銳角 ⇒ 內積 > 0、鈍角 ⇒ 內積 < 0
    u = (random.randint(-6, 6), random.randint(-6, 6)); v = (random.randint(-6, 6), random.randint(-6, 6))
    if u == (0, 0) or v == (0, 0):
        continue
    t = ang(u, v)
    if 1e-6 < t < 90 - 1e-6:
        assert dot(u, v) > 0
    if 90 + 1e-6 < t < 180 - 1e-6:
        assert dot(u, v) < 0

# 9 坐標求角（A57 型）
for A, B, C, d, deg in [((4, 5), (1, 1), (8, 2), 25, 45), ((4, 0), (2, -1), (-1, 0), -5, 135)]:
    BA, BC = sub(B, A), sub(B, C)
    assert dot(BA, BC) == d and abs(ang(BA, BC) - deg) < 1e-9
assert n2((3, 4)) == 25 and n2((7, 1)) == 50 and n2((2, 1)) == 5 and n2((-3, 1)) == 10

# 10 已知夾角求未知數（A58 型）：平方之後的二次方程式有一個假根
def roots(a, b, deg):
    """a = (a1, a2)，b = (x, b2)；cos θ = ±\frac{1}{√2}"""
    out = []
    for num in range(-200, 201):
        for den in (1, 2, 3, 4):
            x = F(num, den)
            bb = (x, b)
            lhs = 2 * dot(a, bb) ** 2
            if lhs == n2(a) * n2(bb):
                out.append(x)
    return sorted(set(out))
r1 = roots((3, 1), 2, 135)
assert r1 == [-4, 1]
assert abs(ang((3, 1), (-4, 2)) - 135) < 1e-9 and abs(ang((3, 1), (1, 2)) - 45) < 1e-9
r2 = roots((2, 1), 3, 45)
assert r2 == [-9, 1]
assert abs(ang((2, 1), (1, 3)) - 45) < 1e-9 and abs(ang((2, 1), (-9, 3)) - 135) < 1e-9
# 化簡後的方程式：第 1 組 x^2 + 3x − 4 = 0、第 2 組 x^2 + 8x − 9 = 0
assert all(x * x + 3 * x - 4 == 0 for x in r1) and all(x * x + 8 * x - 9 == 0 for x in r2)

# 11 外作正方形（A59 型）：B 在原點，A 在 x 軸、C 在 y 軸
for ab, bc, d1, cos2 in [(4, 2, 16, (1, 26)), (3, 3, 9, (1, 10))]:
    B, A, C = (0, 0), (ab, 0), (0, bc)
    D, E = (0, -ab), (ab, -ab)                                             # 正方形 ABDE 在 AB 下面
    H, I = (-bc, bc), (-bc, 0)                                             # 正方形 BCHI 在 BC 左邊
    nrm = (bc, ab)                                                         # \vec{AC} = (−ab, bc) 轉 90°，往外（離開 B）
    F_, G = add(C, nrm), add(A, nrm)
    assert dot(nrm, sub(B, mul(F(1, 2), add(A, C)))) > 0
    assert dot(sub(A, D), sub(A, H)) == d1
    BG, BE = sub(B, G), sub(B, E)
    c = F(dot(BG, BE)) ** 2 / (n2(BG) * n2(BE))
    assert c == F(cos2[0], cos2[1]) and dot(BG, BE) > 0                    # cos^2 = \frac{1}{26}、\frac{1}{10}
    assert (F_, G) in [((2, 6), (6, 4)), ((3, 6), (6, 3))]

# 12 已知長度求夾角（A60、A62、A63 型）
# 變化 A：|a| = 2、|b| = 1、|a − 2b| = 2√3 ⇒ a·b = −1、cos θ = −\frac{1}{2}、120°
ab = F(4 + 4 - 12, 4)
assert ab == -1 and ab / 2 == F(-1, 2)
# 變化 B：|a| = |b| = |a + b| ⇒ 2a·b = −|a|^2、cos θ = −\frac{1}{2}、120°
assert F(-1, 2) == COS[120]
# 變化 C：|u| = 3|v| = |u + 2v|，設 |v| = 1：9 + 4u·v + 4 = 9 ⇒ u·v = −1、cos θ = −\frac{1}{3}
uv = F(9 - 9 - 4, 4)
assert uv == -1 and uv / 3 == F(-1, 3)
assert 105 < math.degrees(math.acos(-1 / 3)) < 110                        # 量角器猜大約 109°

# 13 垂直的兩支組合出的夾角（A61 型）：放上坐標
for a, b, p, q, num, den2 in [((3, 0), (0, 1), (1, 3), (2, -3), 9, (18, 45)), ((2, 0), (0, 2), (1, 1), (1, -3), -8, (8, 40))]:
    P = add(mul(p[0], a), mul(p[1], b)); Q = add(mul(q[0], a), mul(q[1], b))
    assert dot(P, Q) == num and (n2(P), n2(Q)) == den2
cos1 = F(9) ** 2 / (18 * 45); cos2_ = F(-8) ** 2 / (8 * 40)
assert cos1 == F(1, 10) and cos2_ == F(1, 5)                              # \frac{√10}{10}、−\frac{√5}{5}

# 14 速算：格子點向量轉 45°、90°、135°
def rot(v, k):
    x, y = v
    return {45: (x - y, x + y), 90: (-y, x), 135: (-x - y, x - y)}[k]
for _ in range(500):
    v = (random.randint(-3, 3), random.randint(-3, 3))
    if v == (0, 0):
        continue
    for k in (45, 90, 135):
        assert abs(ang(v, rot(v, k)) - k) < 1e-9

print("OK")
