"""V6 風箏航道（3-3 重點一：直線的參數式、法向量、距離、極值、投影、反射、夾角）設計稿 docs/vec2_v6_design.md 的驗算。
執行：python3 tools/vec2/verify_v6.py（全部 assert 通過才會印出 OK）
根號的答案用平方比較（Fraction），例如 cos θ = √2/10 寫成 cos² θ = 2/100。"""
from fractions import Fraction as F
from math import gcd


def dot(a, b): return a[0] * b[0] + a[1] * b[1]
def cross(a, b): return a[0] * b[1] - a[1] * b[0]
def sub(p, q): return (q[0] - p[0], q[1] - p[1])          # \vec{pq}
def add(*vs): return tuple(sum(v[i] for v in vs) for i in range(2))
def mul(k, v): return (k * v[0], k * v[1])
def n2(v): return dot(v, v)
def on(abc, p): return abc[0] * p[0] + abc[1] * p[1] + abc[2] == 0       # ax + by + c = 0
def val(abc, p): return abc[0] * p[0] + abc[1] * p[1] + abc[2]
def par(u, v): return cross(u, v) == 0
def pt(p0, d, t): return (p0[0] + d[0] * t, p0[1] + d[1] * t)
def cos2(u, v): return F(dot(u, v) ** 2, n2(u) * n2(v))
def proj(v, d): return mul(F(dot(v, d), n2(d)), d)
def foot(abc, p):
    k = F(-val(abc, p), abc[0] ** 2 + abc[1] ** 2)
    return add(p, mul(k, (abc[0], abc[1])))
def seg_pts(a, b, t0, t1, steps=400):
    """參數式 a + t·b（t0 ≤ t ≤ t1）走過的點（抽樣）"""
    return [pt(a, b, t0 + (t1 - t0) * F(i, steps)) for i in range(steps + 1)]
def same_set(p0, d, lo, hi, q0, e, lo2, hi2):
    """兩個參數式（有界或無界：None）是不是同一個圖形：方向平行、起點在同一條線上、端點一樣"""
    if not par(d, e) or not par(sub(p0, q0), d):
        return False
    # 把第二個參數式的端點換成第一個的參數
    def to_t(p):
        return F(dot(sub(p0, p), d), n2(d))
    ends1 = sorted([(lo is None, lo), (hi is None, hi)], key=str)
    a = None if lo2 is None else to_t(pt(q0, e, lo2))
    b = None if hi2 is None else to_t(pt(q0, e, hi2))
    # 端點的方向：第二個參數式往 +∞ 時，第一個參數往哪邊
    s = F(dot(e, d), n2(d))
    span2 = []
    for v, inf_side in ((a, -1), (b, 1)):
        if v is None:
            span2.append(("inf", 1 if s * inf_side > 0 else -1))
        else:
            span2.append(("fin", v))
    def norm(span):
        lo_, hi_ = None, None
        for kind, v in span:
            if kind == "inf":
                if v < 0: lo_ = "-inf"
                else: hi_ = "+inf"
        fins = sorted(v for kind, v in span if kind == "fin")
        if lo_ is None: lo_ = fins.pop(0)
        if hi_ is None: hi_ = fins.pop(-1)
        return (lo_, hi_)
    span1 = [("inf", -1) if lo is None else ("fin", lo), ("inf", 1) if hi is None else ("fin", hi)]
    return norm(span1) == norm(span2)


# ======== 第一章 參數式與法向量 ========

# 1 參數式是時間（新）：P = A + t\vec{v}
for A, v, t, P, axis, goal, tt in [((-3, 1), (2, 1), 2, (1, 3), 0, 5, 4),
                                   ((4, -2), (-3, 2), 2, (-2, 2), 1, 6, 4)]:
    assert pt(A, v, t) == P
    assert pt(A, v, tt)[axis] == goal

# 2 線段、射線的參數式（B1、B2）
A, B = (5, 1), (1, 3)
d = sub(A, B)                                                  # (−4, 2)
cards = [((5, 1), (-4, 2), 0, 1, True), ((5, 1), (4, -2), -1, 0, True),
         ((1, 3), (-2, 1), -1, 0, False), ((1, 3), (6, -2), 0, F(2, 3), False)]
for q0, e, lo, hi, ok in cards:
    assert same_set(A, d, 0, 1, q0, e, lo, hi) == ok, (q0, e)
assert pt((1, 3), (-2, 1), -1) == (3, 2)                        # ③ 只走到中點
assert pt((1, 3), (6, -2), F(2, 3)) == (5, F(5, 3))             # ④ 終點不在 B
assert not par(sub((1, 3), (5, F(5, 3))), d)                    # 根本不在直線 AB 上
# 第 2 組：射線 x = 3 − 2s, y = −2 + s, s ≥ 1：起點 (1, −1)、往 (−2, 1)
S, e0 = pt((3, -2), (-2, 1), 1), (-2, 1)
assert S == (1, -1)
cards = [((1, -1), (-2, 1), 0, None, True), ((1, -1), (4, -2), None, 0, True),
         ((-3, 1), (2, -1), 2, None, False), ((5, -3), (-2, 1), 2, None, True)]
for q0, e, lo, hi, ok in cards:
    assert same_set(S, e0, 0, None, q0, e, lo, hi) == ok, (q0, e)
assert pt((-3, 1), (2, -1), 2) == (1, -1)                       # ③ 起點對了，方向反了

# 3 線段參數式的審判卡（B7）
A, B = pt((2, -1), (4, 3), -1), pt((2, -1), (4, 3), 1)
assert n2(sub(A, B)) == 100                                     # 第 1 組 \ol{AB} = 10
# 第 1 組：A(−2, −4)、B(6, 2)
A, B = (-2, -4), (6, 2)
assert F(3, 4) == F(B[1] - A[1], B[0] - A[0])                   # ① 斜率 ○
assert dot((4, 3), (4, 3)) != 0 and par((4, 3), sub(A, B))      # ② (4, 3) 是方向向量，不是法向量 ✕
assert pt((2, -1), (4, 3), -2) == (-6, -7)                      # ③ (−6, −7) 在直線上但 t = −2 不在 [−1, 1] ✕
# 第 2 組（畫面放得下）：x = 1 − 3t，y = −2 + 4t，0 ≤ t ≤ 1：A(1, −2)、B(−2, 2)
A, B = pt((1, -2), (-3, 4), 0), pt((1, -2), (-3, 4), 1)
assert (A, B) == ((1, -2), (-2, 2)) and n2(sub(A, B)) == 25
assert F(B[1] - A[1], B[0] - A[0]) == F(-4, 3)                  # ① ○
assert dot((4, 3), sub(A, B)) == 0                              # ② (4, 3) 是法向量 ○
assert pt((1, -2), (-3, 4), -1) == (4, -6)                      # ③ (4, −6) 是 t = −1 ✕
assert pt((1, -2), (-3, 4), F(1, 2)) == mul(F(1, 2), add(A, B)) == (F(-1, 2), 0)   # ④ 中點 ○

# 4 線段上的格子點（B3）
for A, B, step, n in [((2, -30), (47, 30), (3, 4), 16), ((-20, 7), (36, -35), (4, -3), 15)]:
    v = sub(A, B)
    g = gcd(abs(v[0]), abs(v[1]))
    assert (v[0] // g, v[1] // g) == step and g + 1 == n
    lattice = [(x, y) for x in range(min(A[0], B[0]), max(A[0], B[0]) + 1)
               for y in range(min(A[1], B[1]), max(A[1], B[1]) + 1)
               if cross(sub(A, (x, y)), v) == 0]
    assert len(lattice) == n

# 5 用法向量寫直線（B4）
for P, nv, c, pts in [((2, 1), (3, -4), 2, [(6, 4), (-2, -2)]), ((-1, 3), (2, 5), 13, [(4, 1), (-6, 5)])]:
    assert dot(nv, P) == c
    for q in pts:
        assert dot(sub(P, q), nv) == 0                          # 拖到這些點燈會亮

# 6 方向向量、法向量和直線（B5、B6、B8）
# A：(4, b) 是 3x + 2y − 7 = 0 的方向向量，P(t, 4 − t) 在 L 上
b = F(-12, 2)
assert dot((4, b), (3, 2)) == 0 and b == -6
t = -1
assert on((3, 2, -7), (t, 4 - t)) and (t, 4 - t) == (-1, 5)
# B：和 10x − 15y + 4 = 0 平行的向量
L = (10, -15, 4)
assert par((2, -3), (10, -15))
for v, ok in [((3, 2), True), ((-6, -4), True), ((2, -3), False), ((-3, 2), False)]:
    assert (dot(v, (10, -15)) == 0) == ok
# C：2x + 5y − 9 = 0 的參數式 x = 2 + at, y = b − 2t
a = 5
assert dot((a, -2), (2, 5)) == 0
b = 1
assert on((2, 5, -9), (2, b))

# 7 兩直線的交點（B9、B10）
# A：L1：2x − y − 7 = 0，L2：x = −1 + 2t, y = 1 − t
L1 = (2, -1, -7)
t = 2
assert val(L1, pt((-1, 1), (2, -1), t)) == 0 and pt((-1, 1), (2, -1), t) == (3, -1)
assert [s for s in range(-10, 11) if val(L1, pt((-1, 1), (2, -1), s)) == 0] == [2]
# B：從 (−4, 5) 沿 (3, −1) 前進，碰到 x − 2y = 1
L = (1, -2, -1)
t = 3
assert val(L, pt((-4, 5), (3, -1), t)) == 0 and pt((-4, 5), (3, -1), t) == (5, 2) and t > 0

# 8 點到直線的距離（B11）
for P, Q0, dd, nv, c, dist2 in [((2, -1), (1, 4), (3, -4), (4, 3), 16, F(121, 25)),
                                ((0, 2), (3, -1), (4, 3), (3, -4), 13, F(441, 25))]:
    assert dot(nv, dd) == 0 and dot(nv, Q0) == c
    assert F((dot(nv, P) - c) ** 2, n2(nv)) == dist2
    # 用 \vec{QP} 在法向量上的正射影算，也一樣
    assert F(dot(sub(Q0, P), nv) ** 2, n2(nv)) == dist2
# 第 1 組 11/5、第 2 組 21/5

# 9 沿直線走固定距離（B15）
for L, A, dd, unit2, k, ans in [((1, 2, -5), (1, 2), (2, -1), 5, 3, [(7, -1), (-5, 5)]),
                                ((4, 3, 5), (-2, 1), (3, -4), 25, 1, [(1, -3), (-5, 5)])]:
    assert on(L, A) and dot(dd, L[:2]) == 0 and n2(dd) == unit2
    got = [pt(A, dd, k), pt(A, dd, -k)]
    assert got == ans and all(on(L, p) for p in got)
    assert all(n2(sub(A, p)) == k * k * unit2 for p in got)     # 3√5、5

# 10 菱形、正方形的頂點（B16、B17）
# A：菱形 A(1, 1)、C(5, 3)，面積 20，D 在第一象限
A, C = (1, 1), (5, 3)
M = mul(F(1, 2), add(A, C))
assert M == (3, 2)
AC2 = n2(sub(A, C))                                             # 20 ⇒ \ol{AC} = 2√5
BD = F(2 * 20) ** 2 / AC2                                       # \ol{BD}^{2}
assert BD == 80                                                 # \ol{BD} = 4√5
perp = (-1, 2)
assert dot(perp, sub(A, C)) == 0
k = 2                                                           # |\vec{MD}| = 2√5 = 2|(−1, 2)|
assert n2(mul(k, perp)) * 4 == BD
Ds = [add(M, mul(k, perp)), add(M, mul(-k, perp))]
assert Ds == [(1, 6), (5, -2)]
D = [p for p in Ds if p[0] > 0 and p[1] > 0]
assert D == [(1, 6)]
Bv = add(M, mul(-1, sub(M, D[0])))
assert F(cross(sub(A, C), sub(Bv, D[0]))).__abs__() / 2 == 20
# B：正方形 A(1, −2)、B(−1, 2)
A, B = (1, -2), (-1, 2)
ab = sub(A, B)
assert ab == (-2, 4)
for r in [(4, 2), (-4, -2)]:
    assert dot(r, ab) == 0 and n2(r) == n2(ab)
sols = [(add(B, r), add(A, r)) for r in [(4, 2), (-4, -2)]]     # (C, D)
assert sols == [((3, 4), (5, 0)), ((-5, 0), (-3, -4))]
cand = {(5, 0): True, (3, 4): True, (-5, 0): True, (5, 4): False, (-3, 4): False}
allpts = {p for s in sols for p in s}
for p, ok in cand.items():
    assert (p in allpts) == ok

# 11 平行、垂直、夾角綜合（B18，移到終焉之塔：docs/vec2_tower_backlog.md）
for L1, L2, Ans, Bans, OC, line in [((3, 1, -5), (1, 2, -10), (-1, 3), (2, 4), (3, 1), (3, 1, 10)),
                                    ((2, -1, -7), (3, -1, 10), (-1, -2), (-3, 1), (-2, 3), (-2, 3, 13))]:
    dd = (L1[1], -L1[0]) if L1[1] != 0 else (0, 1)
    # \vec{OA} ∥ L1，|\vec{OA}| = |方向向量|（題目給的長度）
    cands = [dd, mul(-1, dd)]
    # B 是 O 到 L2 的垂足
    Bp = foot(L2, (0, 0))
    assert Bp == Bans
    good = [a for a in cands if dot(a, Bp) > 0]
    assert good == [Ans]
    oc = sub(Ans, Bp)
    assert oc == OC
    C = oc
    assert dot(OC, C) == line[2] and (line[0], line[1]) == OC

# ======== 第二章 極值、投影、反射與夾角 ========

# 12 參數式求極值（B12、B13、B14）
# A：A(−3, 2)、B(2, −1)，f = 2x − 3y + 4 在線段上的最大值
A, B = (-3, 2), (2, -1)
f = lambda p: 2 * p[0] - 3 * p[1] + 4
assert f(A) == -8 and f(B) == 11
assert all(f(pt(A, sub(A, B), F(i, 100))) == 19 * F(i, 100) - 8 for i in range(101))
assert max(f(pt(A, sub(A, B), F(i, 100))) for i in range(101)) == 11
# B：A(3, 1)、B(−1, 3)，P 在 x + y − 1 = 0 上，\ol{AP}^{2} + \ol{BP}^{2} 最小
A, B = (3, 1), (-1, 3)
g = lambda t: n2(sub(A, (t, 1 - t))) + n2(sub(B, (t, 1 - t)))
assert all(g(F(i, 10)) == 4 * F(i, 10) ** 2 + 14 for i in range(-50, 51))
assert foot((1, 1, -1), mul(F(1, 2), add(A, B))) == (0, 1)      # 就是 AB 中點的垂足
# C：A(3, 0)、B(0, 3)、C(−1, 0)，P 在直線 AB 上，\vec{PA} · \vec{PC} 最小
A, B, C = (3, 0), (0, 3), (-1, 0)
h = lambda t: dot(sub(pt(A, sub(A, B), t), A), sub(pt(A, sub(A, B), t), C))
assert all(h(F(i, 12)) == 18 * F(i, 12) ** 2 - 12 * F(i, 12) for i in range(-24, 25))
assert h(F(1, 3)) == -2 and pt(A, sub(A, B), F(1, 3)) == (2, 1)

# 13 垂足和 PA + PB 的最小值（B19）
for L, A, B, Fo, Ap, ans2 in [((4, 3, -5), (-2, -4), (1, -3), (2, -1), (6, 2), 50),
                              ((1, -2, 3), (-4, 2), (1, 4), (-3, 0), (-2, -2), 45)]:
    assert foot(L, A) == Fo
    assert add(A, mul(2, sub(A, Fo))) == Ap
    assert val(L, A) * val(L, B) > 0                            # 同一側，要先對稱
    assert n2(sub(Ap, B)) == ans2                               # 5√2、3√5
    # 交點 P 在 L 上，而且 A'、P、B 共線
    d = sub(Ap, B)
    t = F(-val(L, Ap), L[0] * d[0] + L[1] * d[1])
    P = pt(Ap, d, t)
    assert on(L, P) and 0 < t < 1

# 14 反射求鏡子的斜率（B20）
def refl(u, m):
    """u 對方向 m 的鏡子反射"""
    return sub(u, mul(2, proj(u, m)))
for u, v, mirror, slope in [((3, 4), (5, 0), (2, 1), F(1, 2)), ((-6, 8), (5, 0), (1, 2), F(2, 1))]:
    r = refl(u, mirror)
    assert par(r, v) and dot(r, v) > 0
    assert F(mirror[1], mirror[0]) == slope
# 第 2 組：\|\vec{u}\| ≠ \|\vec{v}\|，要先換成單位向量
u, v = (-6, 8), (5, 0)
s = add(mul(F(1, 10), u), mul(F(1, 5), v))
assert s == (F(2, 5), F(4, 5)) and par(s, (1, 2))
assert not par(add(u, v), (1, 2))                               # 直接相加不對
# 拖鏡子：鏡子是 O 到拖的格子點 T 的直線，燈亮的位置
assert [(x, y) for x in range(-6, 7) for y in range(-3, 4) if (x, y) != (0, 0) and par((x, y), (2, 1))] == [(-6, -3), (-4, -2), (-2, -1), (2, 1), (4, 2), (6, 3)]

# 15 向量在直線上的正射影（B21）
for A, B, L, dd, ans in [((4, 1), (-1, 6), (1, -2, 1), (2, 1), (-2, -1)),
                         ((-2, -3), (3, 2), (3, 1, -4), (1, -3), (-1, 3))]:
    assert dot(dd, L[:2]) == 0
    assert proj(sub(A, B), dd) == ans

# 16 投影點（B22）
for L, A1, AB, dd, step, B1 in [((1, 2, -5), (1, 2), (6, 2), (2, -1), (4, -2), (5, 0)),
                                ((3, -1, -1), (1, 2), (-5, -5), (1, 3), (-2, -6), (-1, -4))]:
    assert on(L, A1) and dot(dd, L[:2]) == 0
    assert proj(AB, dd) == step
    assert add(A1, step) == B1 and on(L, B1)
    # 畫面上的 A、B（其中一種）：A = A' ± 法向量（第 2 組放另一邊，B 才不會剛好落在 L 上），B = A + \vec{AB}
    sg = 1 if L == (1, 2, -5) else -1
    A = add(A1, mul(sg, L[:2]))
    B = add(A, AB)
    assert foot(L, A) == A1 and foot(L, B) == B1 and not on(L, B)

# 17 兩直線的銳角交角（B23）
for n1, n2v, c2 in [((1, 3), (2, -1), F(2, 100)), ((1, 2), (3, 1), F(1, 2))]:
    assert cos2(n1, n2v) == c2
assert dot((1, 3), (2, -1)) < 0                                 # 第 1 組不加絕對值會變成負的

# 18 參數式的交點和夾角（B24）
for P1, d1, P2, d2, t, s, P, c2 in [((-1, 1), (2, 1), (2, 0), (1, 3), 2, 1, (3, 3), F(1, 2)),
                                    ((2, -1), (3, -1), (-2, 3), (1, -3), -1, 1, (-1, 0), F(9, 25))]:
    assert pt(P1, d1, t) == P and pt(P2, d2, s) == P
    assert cos2(d1, d2) == c2
# 第 1 組 sin θ = √2/2、第 2 組 sin θ = 4/5

# 19 已知斜率求交角（B25）
for d1, d2, c2, s2 in [((2, 1), (1, -3), F(1, 50), F(49, 50)), ((1, 3), (1, 2), F(49, 50), F(1, 50))]:
    assert cos2(d1, d2) == c2 and 1 - c2 == s2
# √2/10 的平方是 1/50、7√2/10 的平方是 49/50
assert F(2, 100) == F(1, 50) and F(98, 100) == F(49, 50)

# 20 已知夾角求直線（B26）
# 第 1 組：x − 3y + 5 = 0、ax + y − 4 = 0 夾 45°：2a² + 3a − 2 = 0
for a in [F(1, 2), F(-2)]:
    assert cos2((1, -3), (a, 1)) == F(1, 2)
    assert 2 * a * a + 3 * a - 2 == 0
# 第 2 組：3x + y − 1 = 0、x + ay + 2 = 0 夾 135°：2a² − 3a − 2 = 0
for a in [F(2), F(-1, 2)]:
    assert cos2((3, 1), (1, a)) == F(1, 2)
    assert 2 * a * a - 3 * a - 2 == 0
# 滑桿每 0.5 一格，兩個答案都在格子上；格子上沒有別的 a 會讓燈亮
for (n1, mk, sols) in [((1, -3), lambda a: (a, 1), {F(1, 2), F(-2)}), ((3, 1), lambda a: (1, a), {F(2), F(-1, 2)})]:
    hits = {F(i, 2) for i in range(-10, 11) if cos2(n1, mk(F(i, 2))) == F(1, 2)}
    assert hits == sols

print("OK")
