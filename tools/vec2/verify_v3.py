"""V3 日晷影場（3-2 重點一、六：內積、垂直與平行、正射影）設計稿 docs/vec2_v3_design.md 的驗算。
執行：python3 tools/vec2/verify_v3.py（全部 assert 通過才會印出 OK）
有理數用 Fraction；正五邊形、夾角這類無理數用浮點數比大小（差距都遠大於誤差）。"""
from fractions import Fraction as F
import math, random

def add(*vs): return tuple(sum(v[i] for v in vs) for i in range(2))
def mul(k, v): return (k * v[0], k * v[1])
def sub(p, q): return (q[0] - p[0], q[1] - p[1])      # 從 p 指向 q
def dot(a, b): return a[0] * b[0] + a[1] * b[1]
def cross(a, b): return a[0] * b[1] - a[1] * b[0]
def n2(a): return dot(a, a)
def proj(a, b): return mul(F(dot(a, b)) / n2(b), b)   # a 在 b 上的正射影
def rnd_v(): return (F(random.randint(-9, 9)), F(random.randint(-9, 9)))
def rnd_nz():
    while True:
        v = rnd_v()
        if v != (0, 0):
            return v
def solve2(a1, b1, c1, a2, b2, c2):                     # a1 x + b1 y = c1, a2 x + b2 y = c2
    d = F(a1 * b2 - a2 * b1)
    return (F(c1 * b2 - c2 * b1) / d, F(a1 * c2 - a2 * c1) / d)
def rot(v, deg):
    r = math.radians(deg)
    return (v[0] * math.cos(r) - v[1] * math.sin(r), v[0] * math.sin(r) + v[1] * math.cos(r))
def convex(P):
    s = [cross(sub(P[i], P[(i + 1) % len(P)]), sub(P[(i + 1) % len(P)], P[(i + 2) % len(P)])) for i in range(len(P))]
    return all(x > 0 for x in s) or all(x < 0 for x in s)

# ======== 第一章 內積的意義與計算 ========
# 1 轉動的影子：a 躺在地上，b 繞著起點轉（每 15°）。a·b = |a||b|cosθ
for la, lb, want in [(4, 2, "max"), (3, 4, "min")]:
    vals = {th: la * lb * math.cos(math.radians(th)) for th in range(0, 360, 15)}
    best = max(vals, key=vals.get) if want == "max" else min(vals, key=vals.get)
    assert best == (0 if want == "max" else 180)
    assert abs(vals[best]) == la * lb                      # 最大 8、最小 −12
    zeros = [th for th, v in vals.items() if abs(v) < 1e-9]
    assert zeros == [90, 270]
    assert all(v < 0 for th, v in vals.items() if 90 < th < 270)

# 2 觀念審判卡（隨機向量驗 ○ 恆成立、✕ 找得到反例）
def check(name, holds, expect, n=3000):
    bad = 0
    for _ in range(n):
        a, b, c = rnd_nz(), rnd_nz(), rnd_nz()
        r = holds(a, b, c)
        if r is None:
            continue
        bad += not r
    assert (bad == 0) == expect, name
def imp(p, q): return None if not p else q
# 第 1 組（A35）
check("a+b=a+c ⇒ b=c", lambda a, b, c: imp(add(a, b) == add(a, c), b == c), True)
check("a·b=a·c ⇒ b=c", lambda a, b, c: imp(dot(a, b) == dot(a, c), b == c), False)
check("(b·c)a−(c·a)b ⊥ c", lambda a, b, c: dot(add(mul(dot(b, c), a), mul(-dot(c, a), b)), c) == 0, True)
check("正射影相等 ⇒ (a−b) ∥ c", lambda a, b, c: imp(proj(a, c) == proj(b, c), cross(add(a, mul(-1, b)), c) == 0), False)
check("正射影相等 ⇒ (a−b) ⊥ c", lambda a, b, c: imp(proj(a, c) == proj(b, c), dot(add(a, mul(-1, b)), c) == 0), True)
# ✕ 卡的反例：a = (4, 0)、b = (2, 3)、c = (2, −1)：a·b = a·c = 8，b ≠ c（c 和 b 在同一道陽光上）
a, b, c = (4, 0), (2, 3), (2, -1)
assert dot(a, b) == dot(a, c) == 8 and b != c
# 第 2 組（A36，(D) 改成垂直的版本）
def norm(v): return math.hypot(*v)
check("||a|−|b|| ≤ |a−b|", lambda a, b, c: abs(norm(a) - norm(b)) <= norm(add(a, mul(-1, b))) + 1e-9, True)
check("|a·b|=|a||b| ⇒ a∥b", lambda a, b, c: imp(abs(abs(dot(a, b)) - norm(a) * norm(b)) < 1e-9, cross(a, b) == 0), True)
check("|a+b|=|a−b| ⇔ a⊥b", lambda a, b, c: (n2(add(a, b)) == n2(add(a, mul(-1, b)))) == (dot(a, b) == 0), True)
# 「a⊥b、b⊥c ⇒ a⊥c」✕：隨機很少同時垂直，改用下面的反例
check("a⊥b、b⊥c ⇒ a∥c", lambda a, b, c: imp(dot(a, b) == 0 and dot(b, c) == 0, cross(a, c) == 0), True)
# 有反例的機會：b = (1, 2) 時 a、c 都在 (2, −1) 方向上
a, b, c = (2, -1), (1, 2), (-4, 2)
assert dot(a, b) == 0 and dot(b, c) == 0 and dot(a, c) != 0 and cross(a, c) == 0

# 3 三點共線（O 在直線 AB 外，隨機 O、A、B，解出 P，看 A、B、P 是否共線）
def coll(A, B, P): return cross(sub(A, B), sub(A, P)) == 0
def solve_P(eq, O, A, B):
    """eq(P) 回傳一支向量（要等於 0）；eq 對 P 是一次的，用兩個未知數解。"""
    e0 = eq((F(0), F(0))); ex = sub(e0, eq((F(1), F(0)))); ey = sub(e0, eq((F(0), F(1))))
    d = cross(ex, ey)
    if d == 0:
        return None
    return solve2(ex[0], ey[0], -e0[0], ex[1], ey[1], -e0[1])
def vec(P, Q): return sub(P, Q)
cards3 = {
    # 第 1 組（A37）
    "3OP=4OA−2OB": (lambda O, A, B: lambda P: add(mul(3, vec(O, P)), mul(-4, vec(O, A)), mul(2, vec(O, B))), False),
    "AB=2PA+3PB": (lambda O, A, B: lambda P: add(vec(A, B), mul(-2, vec(P, A)), mul(-3, vec(P, B))), True),
    "3PB=OA−OB": (lambda O, A, B: lambda P: add(mul(3, vec(P, B)), mul(-1, vec(O, A)), vec(O, B)), True),
    # 第 2 組
    "2OP=3OA−OB": (lambda O, A, B: lambda P: add(mul(2, vec(O, P)), mul(-3, vec(O, A)), vec(O, B)), True),
    "OP=OA+OB": (lambda O, A, B: lambda P: add(vec(O, P), mul(-1, vec(O, A)), mul(-1, vec(O, B))), False),
    "AB=2PA−3PB": (lambda O, A, B: lambda P: add(vec(A, B), mul(-2, vec(P, A)), mul(3, vec(P, B))), True),
}
for name, (mk, ok) in cards3.items():
    bad = 0
    for _ in range(500):
        O, A, B = rnd_v(), rnd_v(), rnd_v()
        if cross(sub(O, A), sub(O, B)) == 0 or A == B:
            continue
        P = solve_P(mk(O, A, B), O, A, B)
        assert P is not None, name
        bad += coll(A, B, P) != ok
    assert bad == 0, name
# 內積當係數的卡：(OA·AP)AB = (OA·AB)AP（第 1 組）、(OB·BP)BA = (OB·BA)BP（第 2 組）
# P 不是一次式解得出來的，改成掃格子點：滿足等式的 P 全部在直線 AB 上
for k in range(200):
    O, A, B = rnd_v(), rnd_v(), rnd_v()
    if cross(sub(O, A), sub(O, B)) == 0 or A == B:
        continue
    for x in range(-12, 13):
        for y in range(-12, 13):
            P = (F(x), F(y))
            if P in (A, B):
                continue
            e1 = add(mul(dot(vec(O, A), vec(A, P)), vec(A, B)), mul(-dot(vec(O, A), vec(A, B)), vec(A, P)))
            e2 = add(mul(dot(vec(O, B), vec(B, P)), vec(B, A)), mul(-dot(vec(O, B), vec(B, A)), vec(B, P)))
            if e1 == (0, 0):
                assert coll(A, B, P)
            if e2 == (0, 0):
                assert coll(A, B, P)
# ✕：PA·PB = 0 的 P 在以 AB 為直徑的圓上（不一定在直線 AB 上）
A, B, P = (0, 0), (4, 0), (2, 2)
assert dot(vec(P, A), vec(P, B)) == 0 and not coll(A, B, P)

# 4 影子排隊
# 變化 A（A38）：六邊形，AB 躺在地上（水平），\vec{AB}·\vec{AX} = |AB| × X 的 x 坐標
for hexa, order in [
    ([(0, 0), (2, 0), (4, 2), (3, 5), (0, 4), (-2, 2)], "CDBEF"),     # b > c > a > d > e
    ([(0, 0), (3, 0), (5, 3), (2, 5), (-1, 4), (-2, 1)], "CBDEF"),    # b > a > c > d > e
]:
    assert convex(hexa)
    A, B = hexa[0], hexa[1]
    names = "ABCDEF"
    d = {names[i]: dot(vec(A, B), vec(A, hexa[i])) for i in range(1, 6)}
    got = "".join(sorted(d, key=lambda k: -d[k]))
    assert got == order, (got, d)
    assert len(set(d.values())) == 5                     # 沒有一樣大的
# 變化 B（A39）：正五邊形 ABCDE（A 在上，B 左上、E 右上、C 左下、D 右下），對角線交點 I = BD ∩ CE
P5 = {n: (math.cos(math.radians(90 + 72 * k)), math.sin(math.radians(90 + 72 * k))) for k, n in enumerate("ABCDE")}
# 照講義的圖：A 上、B 左、C 左下、D 右下、E 右（逆時針 A→B→C→D→E）
def V(p, q): return sub(P5[p], P5[q])
def inter(p1, p2, p3, p4):
    d1, d2 = sub(p1, p2), sub(p3, p4)
    t = cross(sub(p1, p3), d2) / cross(d1, d2)
    return add(p1, mul(t, d1))
I = inter(P5["B"], P5["D"], P5["C"], P5["E"])
ABAE = add(V("A", "B"), V("A", "E"))
assert math.dist(add(P5["A"], ABAE), I) < 1e-9                         # (A) ○
lhs = add(V("A", "B"), mul(-1, V("A", "E"))); rhs = add(V("E", "C"), mul(-1, V("B", "C")))
assert math.dist(lhs, rhs) < 1e-9                                       # (B) ○
c_l, c_r = dot(V("C", "D"), V("E", "A")), dot(V("C", "D"), V("C", "B"))
d_l, d_r = dot(V("C", "D"), V("B", "A")), dot(V("C", "D"), V("D", "E"))
e_l, e_r = dot(V("A", "B"), V("A", "D")), dot(V("A", "B"), V("A", "B"))
assert c_l < c_r - 0.1        # (C) ○：CD·EA < CD·CB
assert d_l > d_r + 0.1        # (D) ✕：CD·BA > CD·DE（BA 的影子在 CD 方向上比較長）
assert e_l < e_r - 0.1        # (E) ○：AB·AD < AB·AB（∠BAD = 72°，D 的影子落在 AB 中點）
s = math.dist(P5["A"], P5["B"])
assert abs(e_l / s ** 2 - 0.5) < 1e-9                                   # AB·AD = \frac{1}{2}|AB|^{2}
ac = dot(V("A", "B"), V("A", "C"))
assert ac > e_r + 0.1                                                   # 對照：AB·AC > AB·AB（∠BAC = 36°）

# 5 已知三邊求內積：|AC|² = |AB|² + 2AB·BC + |BC|²
for AB2, BC2, CA2, want in [(4, 7, 3, -4), (5, 9, 8, -3)]:
    x = F(CA2 - AB2 - BC2, 2)
    assert x == want
    a, b, c = AB2 ** 0.5, BC2 ** 0.5, CA2 ** 0.5
    assert a + b > c and b + c > a and a + c > b
    cosB = (AB2 + BC2 - CA2) / (2 * a * b)
    assert abs(x - (-a * b * cosB)) < 1e-9 and cosB > 0           # ∠B 是銳角，但 AB、BC 夾的是 180° − B

# 6 圖形中的內積
# 變化 A（A43）：平行四邊形，AB = 6、AD = 4，3\ol{PD} = \ol{CD}，AP·BP = 4 ⇒ AB·AD = 12
k = F(12)
AP = (F(1, 3), F(1))              # (AB 的係數, AD 的係數)
BP = (F(1, 3) - 1, F(1))
def ex(u, v, aa, ab, bb): return u[0] * v[0] * aa + (u[0] * v[1] + u[1] * v[0]) * ab + u[1] * v[1] * bb
assert ex(AP, BP, 36, k, 16) == 4
assert (F(-2, 9), F(-1, 3), F(1)) == (AP[0] * BP[0], AP[0] * BP[1] + AP[1] * BP[0], AP[1] * BP[1])
assert 16 - 8 - k / 3 == 4
# 變化 B（A44）：正三角形邊長 3，M、N 三等分 BC
AM = (F(2, 3), F(1, 3)); AN = (F(1, 3), F(2, 3))
assert ex(AM, AN, 9, F(9, 2), 9) == F(13, 2)
# 變化 C（A45）：∠A = 90°、AB = 2、AC = 4，以 BC 向外作正方形 BCDE
A, B, C = (0, 0), (2, 0), (0, 4)
BC = vec(B, C); out = (BC[1], -BC[0])                 # 轉 90°（離開 A 的那一邊）
assert dot(out, sub(A, mul(F(1, 2), add(B, C)))) > 0
D, E = add(C, out), add(B, out)
assert D == (4, 6) and E == (6, 2)
assert dot(D, E) == 36
assert (F(E[0], 2), F(E[1], 4)) == (3, F(1, 2))        # AE = 3AB + \frac{1}{2}AC
inward = (-BC[1], BC[0])
assert add(B, inward) == (-2, -2)                      # 往內作的 E'：正方形蓋住 A
# 變化 D（A46）：(1) 平行四邊形 AB = 5、AD = 3：AC·BD = |AD|² − |AB|² = −16
assert 9 - 25 == -16
#              (2) 等腰梯形 ∠A = ∠B = 60°、AD = DC = CB = 4（AB = 8），M、N 是 BC、CD 中點
r3 = 3 ** 0.5
A, B, C, D = (0, 0), (8, 0), (6, 2 * r3), (2, 2 * r3)
M = mul(0.5, add(B, C)); N = mul(0.5, add(C, D))
assert abs(dot(vec(A, C), vec(M, N)) - (-12)) < 1e-9
# 用基底 AB、AD 算：AC = AD + \frac{1}{2}AB、MN = \frac{1}{2}BD = \frac{1}{2}(AD − AB)；AB·AD = 8·4·cos60° = 16
AC_ = (F(1, 2), F(1)); MN_ = (F(-1, 2), F(1, 2))
assert ex(AC_, MN_, 64, 16, 16) == -12

# 7 垂足：AD = xAB + yAC，D 在 BC 上（x + y = 1），AD ⊥ BC
for aa, cc, ac, want in [(4, 9, 3, (F(6, 7), F(1, 7))), (9, 4, -1, (F(1, 3), F(2, 3)))]:
    # (x a + y c)·(c − a) = x(ac − aa) + y(cc − ac) = 0
    p, q = ac - aa, cc - ac
    xy = solve2(1, 1, 1, p, q, 0)
    assert xy == want, xy
    # 真的畫出來驗：|AB| = √aa、|AC| = √cc、AB·AC = ac
    a = (aa ** 0.5, 0.0)
    cos = ac / (aa ** 0.5 * cc ** 0.5)
    c = (cc ** 0.5 * cos, cc ** 0.5 * math.sqrt(1 - cos ** 2))
    Dp = add(mul(float(xy[0]), a), mul(float(xy[1]), c))
    assert abs(dot(Dp, sub(a, c))) < 1e-9
    assert 0 < xy[0] < 1 and 0 < xy[1] < 1                # 垂足在 BC 線段上

# 8 日晷的圓：PA·PB = k ⇔ |PM|² = |MA|² + k
for A, B, k, line, want in [((4, 0), (-4, 0), 9, (3, -4, 40), 13), ((1, 3), (1, -5), 9, (4, 3, 36), 12)]:
    M = mul(F(1, 2), add(A, B)); r2 = n2(vec(M, A)) + k
    assert r2 == 25
    pts = [(M[0] + x, M[1] + y) for x in range(-5, 6) for y in range(-5, 6) if x * x + y * y == 25]
    assert len(pts) == 12
    for P in pts:
        assert dot(vec(P, A), vec(P, B)) == k
    a_, b_, c_ = line
    dist = abs(a_ * M[0] + b_ * M[1] - c_) / math.hypot(a_, b_)
    assert dist == want - 5 and dist > 5                    # 直線在圓外，最大 = 距離 + 半徑

# ======== 第二章 垂直、平行與正射影 ========
# 10 坐標的內積：a·b = a1b1 + a2b2，b 在 a 上的影子長 = a·b / |a|
for a, b, want, shadow in [((3, 4), (2, 1), 10, 2), ((4, -3), (-1, 3), -13, F(-13, 5))]:
    assert dot(a, b) == want and F(dot(a, b)) / 5 == shadow
    assert n2(a) == 25

# 11 垂直求 t：(u + v)·(u + tv) = |u|² + (1 + t)u·v + t|v|² = 0
def perp_t(uu, vv, uv, s):   # (u + s v)·(u + t v) = uu + (t + s) uv + s t vv
    return F(-(uu + s * uv), uv + s * vv)
assert perp_t(16, 4, -1, 1) == -5                      # 講義 A47
assert perp_t(9, 4, 2, -1) == F(7, 2)                  # 第 2 組：(u − v) ⊥ (u + tv)
assert perp_t(16, 4, 2, 1) == -3                       # 第 1 組：|u| = 4、|v| = 2、u·v = 2
# 12 平行求 t
def par_t(a, b_of_t, m1, n1, m2, n2_):
    for num in range(-40, 41):
        for den in range(1, 9):
            t = F(num, den)
            b = b_of_t(t)
            if cross(add(mul(m1, a), mul(n1, b)), add(mul(m2, a), mul(n2_, b))) == 0:
                return t
assert par_t((1, 2), lambda t: (t, 1), 1, 2, 2, -1) == F(1, 2)     # 講義 A48
assert par_t((2, -1), lambda t: (1, t), 1, 1, 3, -1) == F(-1, 2)   # 第 2 組
assert par_t((3, 1), lambda t: (t, 2), 1, 1, 1, -2) == 6           # 第 1 組：a + b ∥ a − 2b
# 答案代回去兩支向量都不是零向量（不然「平行」是假的）
for a, bt, m1, n1, m2, n2_, t in [((1, 2), lambda t: (t, 1), 1, 2, 2, -1, F(1, 2)),
                                   ((3, 1), lambda t: (t, 2), 1, 1, 1, -2, 6),
                                   ((2, -1), lambda t: (1, t), 1, 1, 3, -1, F(-1, 2))]:
    assert add(mul(m1, a), mul(n1, bt(t))) != (0, 0) and add(mul(m2, a), mul(n2_, bt(t))) != (0, 0)
for a, bt, t in [((3, 1), lambda t: (t, 2), 6), ((2, -1), lambda t: (1, t), F(-1, 2))]:
    assert cross(a, bt(t)) == 0                                       # 平行的時候 a ∥ b

# 13 垂直加平行求向量：OC ⊥ OB、BC ∥ OA、OD = OC − OA
for OA, OB, C, OD in [((2, 1), (-1, 1), (3, 3), (1, 2)), ((3, 1), (1, 2), (-2, 1), (-5, 0))]:
    assert dot(C, OB) == 0 and cross(vec(OB, C), OA) == 0
    assert sub(OA, C) == OD

# 14 影子＋竿子：a = u + v，u ∥ b、v ⊥ b
for a, b, k, u, v, ask, ans in [((7, 4), (1, 2), 3, (3, 6), (4, -2), (1, 3), (15, 0)),
                                ((1, 8), (2, 1), 2, (4, 2), (-3, 6), (2, 1), (5, 10))]:
    assert proj(a, b) == mul(k, b) == u and sub(u, a) == v and dot(v, b) == 0
    assert add(mul(ask[0], u), mul(ask[1], v)) == ans

# 15 正射影的公式（影子落在格子點中間，拖不準）
for a, b, sh in [((5, 2), (1, 3), (F(11, 10), F(33, 10))), ((-3, 4), (2, 1), (F(-4, 5), F(-2, 5)))]:
    assert proj(a, b) == sh
    assert not all(x.denominator == 1 for x in sh)
    assert dot(sub(sh, a), b) == 0
# 16 正射影的計算（A78 型）
for A, B, C, sh, ln, foot in [((-1, 2), (9, 7), (2, 6), (6, 8), 10, (5, 10)),
                              ((1, -1), (12, 1), (5, 2), (8, 6), 10, (9, 5))]:
    AB, AC = vec(A, B), vec(A, C)
    assert n2(AC) == 25 and proj(AB, AC) == sh
    assert F(dot(AB, AC)) / 5 == ln
    assert add(A, sh) == foot
    assert proj(AB, AC) != mul(F(1, 2), sh)              # ✕ 卡：一半的影子
# 17 正射影的觀念（A77 型）：OA·OB = OB·OC ⇔ (OA − OC)·OB = 0 ⇔ CA ⊥ OB ⇔ 兩個正射影相同
for _ in range(2000):
    a, b, c = rnd_nz(), rnd_nz(), rnd_nz()
    if dot(a, b) == dot(b, c):
        assert dot(sub(c, a), b) == 0 and proj(a, b) == proj(c, b)
a, b, c = (1, 3), (2, 0), (1, -2)                         # ✕ 的反例：OA ≠ OC、OA 不垂直 OB
assert dot(a, b) == dot(b, c) and a != c and dot(a, b) != 0
# 第 2 組：OA·OC = OB·OC
a, b, c = (2, 3), (2, -1), (3, 0)
assert dot(a, c) == dot(b, c) and norm(a) != norm(b) and dot(sub(b, a), c) == 0
# 18 竿子垂直影子：(a − c)·(5b) = 0、(a − c)·(b + 2c) = 0
for a, b in [((23, 9), (31, 5)), ((26, 7), (12, 35))]:
    c = proj(a, b)
    pole = sub(c, a)
    assert dot(pole, mul(5, b)) == 0 and dot(pole, add(b, mul(2, c))) == 0

# 19 速算的出題範圍：a、b 各分量 −6..6，垂直、平行、都不是三種都出得來
kinds = set()
for _ in range(2000):
    a, b = rnd_nz(), rnd_nz()
    kinds.add("垂直" if dot(a, b) == 0 else "平行" if cross(a, b) == 0 else "都不是")
assert kinds == {"垂直", "平行", "都不是"}

print("OK")
