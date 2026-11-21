"""V5 四心營火（3-2 重點四、五：三角形的四心、面積比）設計稿 docs/vec2_v5_design.md 的驗算。
執行：python3 tools/vec2/verify_v5.py（全部 assert 通過才會印出 OK）
用 \vec{AB}、\vec{AC} 的係數 (x, y) 表示向量；內積用 |AB|^2、|AC|^2、AB·AC 算（Fraction）。"""
from fractions import Fraction as F
import math, random

def dot(a, b): return a[0] * b[0] + a[1] * b[1]
def cross(a, b): return a[0] * b[1] - a[1] * b[0]
def sub(p, q): return (q[0] - p[0], q[1] - p[1])
def add(*vs): return tuple(sum(v[i] for v in vs) for i in range(2))
def mul(k, v): return (k * v[0], k * v[1])
def ex(u, v, aa, ab, cc):
    """(u0 AB + u1 AC)·(v0 AB + v1 AC)"""
    return u[0] * v[0] * aa + (u[0] * v[1] + u[1] * v[0]) * ab + u[1] * v[1] * cc
def solve2(a1, b1, c1, a2, b2, c2):
    d = F(a1 * b2 - a2 * b1)
    return (F(c1 * b2 - c2 * b1) / d, F(a1 * c2 - a2 * c1) / d)
def area(P, Q, R): return abs(F(cross(sub(P, Q), sub(P, R)), 2))
def wavg(ws, pts):
    s = sum(ws)
    return (sum(F(w) * p[0] for w, p in zip(ws, pts)) / s, sum(F(w) * p[1] for w, p in zip(ws, pts)) / s)

# ======== 第一章 三角形的四心 ========
# 1 重心的觀念（A64）：三人拉繩的三角形，重心在格子點
A, B, C = (0, 4), (-3, -2), (6, 1)
G = wavg([1, 1, 1], [A, B, C])
assert G == (1, 1)
assert add(sub(G, A), sub(G, B), sub(G, C)) == (0, 0)
# ✕ 卡：D 在 AB 中垂線上，\vec{AD} − \vec{BD} = \vec{AB}（不是 \vec{0}）
A1, B1, D1 = (-2, 0), (2, 0), (0, 3)
assert math.dist(A1, D1) == math.dist(B1, D1) and add(sub(A1, D1), mul(-1, sub(B1, D1))) == sub(A1, B1)
# ✕ 卡：凸四邊形對角線交點 E，\vec{EA} + \vec{EB} + \vec{EC} + \vec{ED} 不一定是 \vec{0}
Q = [(0, 0), (6, 0), (5, 4), (1, 3)]
# 畫面上的四邊形（第 1 組第四張卡）：交點 E、四支箭的和
Qs = [(-7.0, -2.6), (-2.5, -2.6), (-3.2, 1.0), (-6.4, 0.2)]
def interf(p1, p2, p3, p4):
    d1, d2 = sub(p1, p2), sub(p3, p4)
    t = cross(sub(p1, p3), d2) / cross(d1, d2)
    return add(p1, mul(t, d1))
Es = interf(Qs[0], Qs[2], Qs[1], Qs[3])
assert abs(Es[0] + 5.0599676) < 1e-6 and abs(Es[1] + 0.7620746) < 1e-6
assert math.hypot(*add(*[sub(Es, q) for q in Qs])) > 1.4                 # 金色的和看得到
# 對角線 AC、BD 的交點
def inter(p1, p2, p3, p4):
    d1, d2 = sub(p1, p2), sub(p3, p4)
    t = F(cross(sub(p1, p3), d2), cross(d1, d2))
    return add(p1, mul(t, d1))
E = inter(Q[0], Q[2], Q[1], Q[3])
assert add(*[sub(E, q) for q in Q]) != (0, 0)
# ✕ 卡（第 2 組）：M 是 BC 中點，\vec{AM} = \frac{1}{2}(\vec{AB} + \vec{AC})，不是 \vec{AB} + \vec{AC}

# 2 重心和內積（A65 型）：正三角形邊長 s，D、E 三等分 BC
for s, D, want in [(3, (F(2, 3), F(1, 3)), F(9, 2)), (6, (F(1, 3), F(2, 3)), 18)]:
    aa = cc = s * s; ab = F(s * s, 2)
    AG = (F(1, 3), F(1, 3))
    assert ex(D, AG, aa, ab, cc) == want

# 3 三支向量和為零（A66 型）
# 第 1 組：a + 2b + 3c = 0、a·b = 2、c·a = −3 ⇒ |a|^2 + 2(2) + 3(−3) = 0 ⇒ |a| = √5
a, b = (1, 2), (2, 0)
c = mul(F(-1, 3), add(a, mul(2, b)))
assert add(a, mul(2, b), mul(3, c)) == (0, 0) and dot(a, b) == 2 and dot(c, a) == -3 and dot(a, a) == 5
# 第 2 組：a + b + 2c = 0、a·b = −1、b·c = −1 ⇒ −1 + |b|^2 − 2 = 0 ⇒ |b| = √3
bb = F(1 + 2)
assert -1 + bb + 2 * (-1) == 0 and bb == 3
b2 = (math.sqrt(3), 0.0)
a2 = (-1 / math.sqrt(3), 1.7)           # a·b = −1
c2 = mul(-0.5, add(a2, b2))
assert abs(dot(a2, b2) + 1) < 1e-9 and abs(dot(b2, c2) + 1) < 1e-9

# 4 小三角形的重心（A67 型）
for ap, bq, cr, want in [(F(1, 3), F(1, 2), F(1, 3), (F(5, 18), F(7, 18))), (F(1, 2), F(2, 3), F(1, 4), (F(5, 18), F(17, 36)))]:
    P = (ap, F(0))
    Qp = (1 - bq, bq)                     # \vec{AQ} = \vec{AB} + bq(\vec{AC} − \vec{AB})
    R = (F(0), 1 - cr)                    # \vec{AR} = \vec{AC} + cr(\vec{CA})
    Gs = ((P[0] + Qp[0] + R[0]) / 3, (P[1] + Qp[1] + R[1]) / 3)
    assert Gs == want, Gs

# 5 過重心的蹺蹺板（A68 型）：C 當起點，\vec{CP} = p\vec{CA}，\vec{CQ} = t\vec{CB}
for ap_pc, t_want, ratio in [((2, 3), F(3, 4), (4, 3)), ((1, 2), F(2, 3), (3, 2))]:
    p = F(ap_pc[1], sum(ap_pc))           # \vec{CP} = \frac{PC}{AC}\vec{CA}
    # \vec{CG} = \frac{1}{3}\vec{CA} + \frac{1}{3}\vec{CB} = \frac{1}{3p}\vec{CP} + \frac{1}{3t}\vec{CQ}，係數和 = 1
    t = 1 / (3 * (1 - F(1, 3) / p))
    assert t == t_want
    assert F(1) / t == F(ratio[0], ratio[1])                 # △ABC : △AQC = CB : CQ
# 用坐標驗一次：A(0, 6)、B(−4, 0)、C(5, 0)
A, B, C = (F(0), F(6)), (F(-4), F(0)), (F(5), F(0))
G = wavg([1, 1, 1], [A, B, C])
P = add(A, mul(F(2, 5), sub(A, C)))
Qx = inter(P, G, B, C)
assert area(A, B, C) / area(A, Qx, C) == F(4, 3)

# 6 內心（A69 型）：AI = \frac{b + c}{a + b + c}\vec{AD}，面積比 = 三邊比
def incenter_coef(AB, BC, AC):
    a, b, c = BC, AC, AB
    # \vec{AI} = \frac{b}{a + b + c}\vec{AB} + \frac{c}{a + b + c}\vec{AC}
    return (F(b, a + b + c), F(c, a + b + c))
# 第 1 組：AB = 4、BC = 5、AC = 6
AI = incenter_coef(4, 5, 6)
assert AI == (F(2, 5), F(4, 15))
AD = (F(6, 10), F(4, 10))                                   # BD : DC = 4 : 6
assert (AI[0] / AD[0], AI[1] / AD[1]) == (F(2, 3), F(2, 3))  # AI = \frac{2}{3}AD
# OI = \frac{a\vec{OA} + b\vec{OB} + c\vec{OC}}{a + b + c} = \frac{1}{3}\vec{OA} + \frac{2}{5}\vec{OB} + \frac{4}{15}\vec{OC}
assert (F(5, 15), F(6, 15), F(4, 15)) == (F(1, 3), F(2, 5), F(4, 15))
# 第 2 組：AB = 5、BC = 8、AC = 7
AI = incenter_coef(5, 8, 7)
assert AI == (F(7, 20), F(1, 4))
AD = (F(7, 12), F(5, 12))
assert (AI[0] / AD[0], AI[1] / AD[1]) == (F(3, 5), F(3, 5))
# 坐標驗：第 2 組 A(0, 0)、B(5, 0)、C(1, 4√3)（cos A = \frac{1}{7}）
A, B, C = (0.0, 0.0), (5.0, 0.0), (1.0, 4 * math.sqrt(3))
assert abs(math.dist(B, C) - 8) < 1e-9 and abs(math.dist(A, C) - 7) < 1e-9
Ii = (8 * A[0] + 7 * B[0] + 5 * C[0]) / 20, (8 * A[1] + 7 * B[1] + 5 * C[1]) / 20
def tri(P, Q, R): return abs(cross(sub(P, Q), sub(P, R))) / 2
s1, s2, s3 = tri(A, B, Ii), tri(B, C, Ii), tri(A, C, Ii)
assert abs(s1 / s2 - 5 / 8) < 1e-9 and abs(s3 / s2 - 7 / 8) < 1e-9

# 7 找營火：A(0, 0)、B(12, 0)、C(0, 9)（第 2 組左右翻過來：B(−12, 0)）
for B, C, G, O, I in [((12, 0), (0, 9), (4, 3), (6, F(9, 2)), (3, 3)), ((-12, 0), (0, 9), (-4, 3), (-6, F(9, 2)), (-3, 3))]:
    A = (0, 0)
    assert wavg([1, 1, 1], [A, B, C]) == G
    assert dot(sub(O, A), sub(O, A)) == dot(sub(O, B), sub(O, B)) == dot(sub(O, C), sub(O, C))
    a, b, c = math.dist(B, C), math.dist(A, C), math.dist(A, B)
    Ix = ((a * A[0] + b * B[0] + c * C[0]) / (a + b + c), (a * A[1] + b * B[1] + c * C[1]) / (a + b + c))
    assert abs(Ix[0] - I[0]) < 1e-9 and abs(Ix[1] - I[1]) < 1e-9
    # 垂心：直角頂點 A
    assert dot(sub(A, B), sub(A, C)) == 0

# 8 四心的觀念（A70、A71）
# 第 1 組：AB = 3、BC = 5、CA = 4（∠A = 90°）：A(0, 0)、B(3, 0)、C(0, 4)
aa, cc, ab = 9, 16, 0
AI = incenter_coef(3, 5, 4)
assert AI == (F(1, 3), F(1, 4))                                       # ○
AO = (F(1, 2), F(1, 2))                                               # 外心是斜邊中點 ○
assert ex(AO, (0, 1), aa, ab, cc) == 8                                # \vec{AO}·\vec{AC} = 8 ○
assert ex(AO, (1, 0), aa, ab, cc) == F(9, 2)                          # \vec{AO}·\vec{AB} = \frac{9}{2}，不是 8 ✕
# 垂心是 A：\vec{AH} = \vec{0}，\vec{AH}·\vec{BC} = 0 ○
# 第 2 組（A71）：一般的三角形，H 垂心、O 外心
for _ in range(300):
    A = (random.randint(-9, 9), random.randint(-9, 9)); B = (random.randint(-9, 9), random.randint(-9, 9)); C = (random.randint(-9, 9), random.randint(-9, 9))
    if cross(sub(A, B), sub(A, C)) == 0:
        continue
    # 外心 O：|OA| = |OB| = |OC|
    a1, b1 = 2 * (B[0] - A[0]), 2 * (B[1] - A[1]); c1 = dot(B, B) - dot(A, A)
    a2, b2 = 2 * (C[0] - A[0]), 2 * (C[1] - A[1]); c2 = dot(C, C) - dot(A, A)
    O = solve2(a1, b1, c1, a2, b2, c2)
    H = add(A, B, C, mul(-2, O))                                      # \vec{OH} = \vec{OA} + \vec{OB} + \vec{OC}
    assert dot(sub(B, H), sub(A, C)) == 0 == dot(sub(C, H), sub(A, B))   # ○ \vec{BH}·\vec{AC} = \vec{CH}·\vec{AB}（都是 0）
    assert dot(sub(A, H), sub(A, B)) == dot(sub(A, C), sub(A, B))     # ○ \vec{AH}·\vec{AB} = \vec{AC}·\vec{AB}（AH ⊥ BC）
    assert dot(sub(A, O), sub(A, B)) == F(dot(sub(A, B), sub(A, B)), 2)  # \vec{AO}·\vec{AB} = \frac{1}{2}|\vec{AB}|^{2}
# ✕ 的反例：\vec{AO}·\vec{AB} = \vec{AO}·\vec{AC} 只在 AB = AC 時成立；OH·AB = OH·AC 也不一定
A, B, C = (0, 0), (6, 0), (1, 4)
O = solve2(12, 0, 36, 2, 8, 17)
assert dot(sub(A, O), sub(A, B)) != dot(sub(A, O), sub(A, C))
H = add(A, B, C, mul(-2, O))
assert dot(sub(O, H), sub(A, B)) != dot(sub(O, H), sub(A, C))

# 9 外心、垂心的計算
# 變化 A（A72 型）：AB = 4、AC = 6、BC = 2√7（∠A = 60°），外心 K、垂心 H
aa, cc = 16, 36
ab = F(aa + cc - 28, 2)
assert ab == 12
al, be = solve2(aa, ab, F(aa, 2), ab, cc, F(cc, 2))                 # \vec{AK}·\vec{AB} = \frac{1}{2}|AB|^{2}、\vec{AK}·\vec{AC} = \frac{1}{2}|AC|^{2}
assert (al, be) == (F(1, 6), F(4, 9))
s = al + be
assert (al / s, be / s) == (F(3, 11), F(8, 11))                       # \vec{AD}（D 在 BC 上）
assert (1 - 2 * al, 1 - 2 * be) == (F(2, 3), F(1, 9))                 # \vec{AH} = \vec{AB} + \vec{AC} − 2\vec{AK}
# 用坐標驗：A(0, 0)、B(4, 0)、C(3, 3√3)
A, B, C = (0.0, 0.0), (4.0, 0.0), (3.0, 3 * math.sqrt(3))
K = (al * B[0] + be * C[0], al * B[1] + be * C[1])
assert abs(math.dist(K, A) - math.dist(K, B)) < 1e-9 and abs(math.dist(K, A) - math.dist(K, C)) < 1e-9
Hh = (F(2, 3) * B[0] + F(1, 9) * C[0], F(2, 3) * B[1] + F(1, 9) * C[1])
Hh = (float(Hh[0]), float(Hh[1]))
assert abs(dot(sub(A, Hh), sub(B, C))) < 1e-9 and abs(dot(sub(B, Hh), sub(A, C))) < 1e-9
# 變化 B（A73 型）：AB = 6、AC = 4、BC = 5，角平分線 AD、AB 的中垂線交 AD 於 P
aa, cc = 36, 16
ab = F(aa + cc - 25, 2)
AD = (F(4, 10), F(6, 10))                                             # BD : DC = 6 : 4
k = F(aa, 2) / ex(AD, (1, 0), aa, ab, cc)
assert k == F(4, 5)
AP = (k * AD[0], k * AD[1])
assert AP == (F(8, 25), F(12, 25))
s = 1 / (1 - AP[0])                                                   # B + s(P − B) 落在 AC 上
AE = s * AP[1]
assert AE == F(12, 17)                                                # AE : EC = 12 : 5
# 變化 C（A74 型）：A(1, 1)、B(1, 7)、C(9, 1)
A, B, C = (1, 1), (1, 7), (9, 1)
assert dot(sub(A, B), sub(C, A)) == 0
assert wavg([1, 1, 1], [A, B, C]) == (F(11, 3), 3)
a, b, c = 10, 8, 6
assert wavg([a, b, c], [A, B, C]) == (3, 3)                           # 內心
assert (F(1 + 9, 2), F(7 + 1, 2)) == (5, 4)                           # 外心 = 斜邊中點
# 垂心是 A(1, 1)，不是 (5, 4)

# 10 速算：四心的關係式（按鈕）——產生器只用固定的四種寫法，不用驗

# ======== 第二章 面積比 ========
# 11 三分花圃：A(0, 0)、B(6, 0)、C(0, 6)（第 2 組 B(6, 0)、C(0, 9)）
for B, C, eq, P123, w in [((6, 0), (0, 6), (2, 2), (2, 3), (1, 2, 3)), ((6, 0), (0, 9), (2, 3), (2, 4), (2, 3, 4))]:
    A = (0, 0)
    assert area(eq, B, C) == area(eq, C, A) == area(eq, A, B)
    s = (area(P123, B, C), area(P123, C, A), area(P123, A, B))
    assert s[0] * w[1] == s[1] * w[0] and s[1] * w[2] == s[2] * w[1]
    assert wavg(list(w), [A, B, C]) == P123                           # P = \frac{w_{A}A + w_{B}B + w_{C}C}{w_{A} + w_{B} + w_{C}}

# 12 等高的三角形：BD : DC = 2 : 3 ⇒ △ABD : △ADC = 2 : 3，\vec{AD} = \frac{3}{5}\vec{AB} + \frac{2}{5}\vec{AC}
A, B, C = (0, 5), (-5, 0), (5, 0)
D = add(B, mul(F(2, 5), sub(B, C)))
assert area(A, B, D) / area(A, D, C) == F(2, 3) and area(A, B, D) / area(A, B, C) == F(2, 5)
# 第 2 組：BD : DC = 3 : 1
D = add(B, mul(F(3, 4), sub(B, C)))
assert area(A, B, D) / area(A, D, C) == 3 and area(A, B, D) / area(A, B, C) == F(3, 4)

# 13 已知關係式求面積比（A75 型）：\vec{AP} = x\vec{AB} + y\vec{AC} ⇒ △ABP = y△ABC、△ACP = x△ABC、△BCP = (1 − x − y)△ABC
for x, y in [(F(1, 5), F(2, 5)), (F(1, 2), F(1, 6))]:
    A, B, C = (F(0), F(0)), (F(6), F(0)), (F(2), F(5))
    P = add(mul(x, B), mul(y, C))
    T = area(A, B, C)
    assert area(A, B, P) / T == y and area(A, C, P) / T == x and area(B, C, P) / T == 1 - x - y

# 14 w_{A}\vec{PA} + w_{B}\vec{PB} + w_{C}\vec{PC} = \vec{0}：面積比 △PBC : △PCA : △PAB = w_{A} : w_{B} : w_{C}
for w, A, B, C, P in [((1, 2, 3), (6, 0), (0, 6), (0, 0), (1, 2)), ((2, 3, 4), (9, 0), (0, 9), (0, 0), (2, 3))]:
    assert wavg(list(w), [A, B, C]) == P
    assert add(mul(w[0], sub(P, A)), mul(w[1], sub(P, B)), mul(w[2], sub(P, C))) == (0, 0)
    s = (area(P, B, C), area(P, C, A), area(P, A, B))
    assert s[0] * w[1] == s[1] * w[0] and s[1] * w[2] == s[2] * w[1]

# 15 已知面積比求點（A76 型）：△PAB : △PBC : △PCA = 1 : 2 : 3（第 2 組 2 : 1 : 1）
for A, B, C, r, w, P in [((0, 4), (-3, -2), (6, 1), (1, 2, 3), (2, 3, 1), (F(-1, 2), F(1, 2))),
                          ((2, 5), (-2, -1), (6, -3), (2, 1, 1), (1, 1, 2), (F(3), F(-1, 2)))]:
    # 權重：A ↔ △PBC、B ↔ △PCA、C ↔ △PAB
    assert w == (r[1], r[2], r[0])
    assert wavg(list(w), [A, B, C]) == P
    s = (area(P, A, B), area(P, B, C), area(P, C, A))
    assert s[0] * r[1] == s[1] * r[0] and s[1] * r[2] == s[2] * r[1]

# 16 面積比反推係數：△PBC : △PCA : △PAB = 1 : 2 : 3 ⇒ \vec{AP} = \frac{2}{6}\vec{AB} + \frac{3}{6}\vec{AC}
for r, xy in [((1, 2, 3), (F(1, 3), F(1, 2))), ((3, 4, 5), (F(1, 3), F(5, 12)))]:
    s = sum(r)
    assert (F(r[1], s), F(r[2], s)) == xy

# 17 四心的面積比：重心 1 : 1 : 1、內心 = 三邊的比（BC : CA : AB）
A, B, C = (0.0, 0.0), (5.0, 0.0), (1.0, 4 * math.sqrt(3))         # AB = 5、BC = 8、CA = 7
Ii = ((8 * A[0] + 7 * B[0] + 5 * C[0]) / 20, (8 * A[1] + 7 * B[1] + 5 * C[1]) / 20)
sb, sc, sa = tri(Ii, C, A), tri(Ii, A, B), tri(Ii, B, C)          # △ICA、△IAB、△IBC
assert abs(sa / sb - 8 / 7) < 1e-9 and abs(sb / sc - 7 / 5) < 1e-9
# 直角三角形的外心是斜邊中點：△OAB = △OAC
A, B, C = (0, 0), (6, 0), (0, 8)
O = (3, 4)
assert area(O, A, B) == area(O, A, C)

# 18 速算：w_{A}、w_{B}、w_{C} ∈ 1～5，△PAB : △ABC = \frac{w_{C}}{w_{A} + w_{B} + w_{C}}
for wa in range(1, 6):
    for wb in range(1, 6):
        for wc in range(1, 6):
            A, B, C = (F(0), F(0)), (F(7), F(0)), (F(2), F(5))
            P = wavg([wa, wb, wc], [A, B, C])
            assert area(P, A, B) / area(A, B, C) == F(wc, wa + wb + wc)

print("OK")
