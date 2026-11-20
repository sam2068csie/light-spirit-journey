"""V1 風向台（3-1 重點一、二）設計稿 docs/vec2_v1_design.md 的驗算。
執行：python3 tools/vec2/verify_v1.py（全部 assert 通過才會印出 OK）
向量一律用座標（Fraction）算；正六邊形用浮點數算再化成分數。"""
from fractions import Fraction as F
import itertools, math, random

def sub(p, q): return (q[0] - p[0], q[1] - p[1])          # \vec{pq}
def add(*vs): return (sum(v[0] for v in vs), sum(v[1] for v in vs))
def mul(k, v): return (k * v[0], k * v[1])
def cross(a, b): return a[0] * b[1] - a[1] * b[0]
def coef(w, a, b):                                         # w = x a + y b
    d = cross(a, b); assert d != 0
    return (F(cross(w, b)) / d, F(cross(a, w)) / d)
def div(p, q, m, n):                                       # \ol{pr} : \ol{rq} = m : n
    return ((n * F(p[0]) + m * F(q[0])) / (m + n), (n * F(p[1]) + m * F(q[1])) / (m + n))
def dist(p, q): return math.hypot(q[0] - p[0], q[1] - p[1])

# ======== 第一章 ========
# 1 同一陣風：和 \vec{a} 相等的箭頭（起點不同、向量一樣），位置和 vec1_bank.gd 一樣
for a, ref, arrows, same, P in [
        ((3, 1), ((-7, 1), (-4, 2)), {"p": ((-3, -1), (0, 0)), "q": ((7, 3), (4, 2)), "r": ((-8, -3), (-2, -1)), "s": ((5, -3), (6, 0)), "t": ((1, -3), (4, -2))},
         {"p", "t"}, (-2, 2)),
        ((-2, 3), ((-6, -3), (-8, 0)), {"p": ((1, -2), (-1, 1)), "q": ((5, 0), (7, -3)), "r": ((8, -1), (6, 2)), "s": ((1, 1), (4, 3)), "t": ((-2, -3), (-6, 3))},
         {"p", "r"}, (3, -3))]:
    assert sub(*ref) == a
    got = {k for k, (s_, e) in arrows.items() if sub(s_, e) == a}
    assert got == same, got
    wrong = sorted(sub(s_, e) for k, (s_, e) in arrows.items() if k not in same)
    # 錯的箭頭：反向、兩倍、長度一樣但方向不同，各一支
    rot = next(w for w in wrong if w not in (mul(-1, a), mul(2, a)))
    assert sorted([mul(-1, a), mul(2, a), rot]) == wrong
    assert rot[0] ** 2 + rot[1] ** 2 == a[0] ** 2 + a[1] ** 2 and cross(rot, a) != 0
    end = add(P, a)
    assert all(abs(c) <= 9 for c in end) and abs(end[1]) <= 4          # 終點在畫布裡
    for k, (s_, e) in arrows.items():                                     # 終點不和別的箭頭的頭尾重疊
        assert end != s_ and end != e

# 2 數箭頭：平行四邊形 4 點 → 12 支、8 種；加上中心 O → 20 支、12 種；每一種最多兩支
def classes(pts):
    c = {}
    for x, y in itertools.permutations(pts, 2):
        c.setdefault(sub(pts[x], pts[y]), []).append(x + y)
    return c
pg = {"A": (0, 0), "B": (4, 0), "C": (5, 3), "D": (1, 3)}
c1 = classes(pg); assert len(c1) == 8 and sum(len(v) for v in c1.values()) == 12 and max(len(v) for v in c1.values()) == 2
pg2 = dict(pg); pg2["O"] = (F(5, 2), F(3, 2))
c2 = classes(pg2); assert len(c2) == 12 and sum(len(v) for v in c2.values()) == 20 and max(len(v) for v in c2.values()) == 2
assert sum(1 for v in c1.values() if len(v) == 2) == 4 and sum(1 for v in c2.values() if len(v) == 2) == 8

# 3 減法：\vec{CB} = −\vec{AC} + \vec{AB}；\vec{AB} = \vec{AC} − \vec{BC}
A, B, C = (-4, -2), (3, -3), (0, 3)
assert add(mul(-1, sub(A, C)), sub(A, B)) == sub(C, B)
assert add(sub(A, C), mul(-1, sub(B, C))) == sub(A, B)

# 4 正六邊形：\vec{a} = \vec{AB}、\vec{b} = \vec{AF}；\vec{u} = \vec{AC}、\vec{v} = \vec{AE}
H = {n: (math.cos(math.radians(180 + 60 * i)), math.sin(math.radians(180 + 60 * i))) for i, n in enumerate("ABCDEF")}
H["O"] = (0.0, 0.0)
def hco(seg, base):
    w = sub(H[seg[0]], H[seg[1]]); a = sub(H[base[0][0]], H[base[0][1]]); b = sub(H[base[1][0]], H[base[1][1]])
    d = cross(a, b)
    return (F(cross(w, b) / d).limit_denominator(12), F(cross(a, w) / d).limit_denominator(12))
AB_AF = ("AB", "AF"); AC_AE = ("AC", "AE")
cards1 = [("AD", (2, 2), True), ("AC", (1, 2), False), ("CE", (-1, 1), True), ("BE", (-2, 0), False)]
for seg, claim, ok in cards1:
    assert (hco(seg, AB_AF) == claim) == ok, seg
assert hco("AC", AB_AF) == (2, 1) and hco("BE", AB_AF) == (0, 2)       # ✕ 卡正確的路
cards2 = [("AD", (F(2, 3), F(2, 3)), True), ("BD", (1, 0), False), ("FC", (F(4, 3), F(-2, 3)), True), ("AB", (F(2, 3), F(1, 3)), False)]
for seg, claim, ok in cards2:
    assert (hco(seg, AC_AE) == claim) == ok, seg
assert hco("BD", AC_AE) == (0, 1) and hco("AB", AC_AE) == (F(2, 3), F(-1, 3))
# ✕ 卡照錯的式子走，終點不在任何一個頂點上也沒關係，只要不是目標點
for seg, claim, ok in cards1:
    if not ok:
        a = sub(H["A"], H["B"]); b = sub(H["A"], H["F"])
        end = add(H[seg[0]], mul(claim[0], a), mul(claim[1], b))
        assert dist(end, H[seg[1]]) > 0.5

# 5 判定平行四邊形：A、B、C 固定，拖 D（E 任意）。燈亮的 D 是哪些
def sandbox(cond, A, B, C, E):
    lit = [D for D in itertools.product(range(-8, 9), repeat=2) if cond(A, B, C, tuple(D), E)]
    return lit
def para(A, B, C, D): return add(A, C) == add(B, D)       # ABCD（照順序）是平行四邊形
conds1 = [("\\vec{AB} = \\vec{CD}", lambda A, B, C, D, E: sub(A, B) == sub(C, D), "x"),
          ("\\vec{AC} = \\vec{AB} + \\vec{AD}", lambda A, B, C, D, E: sub(A, C) == add(sub(A, B), sub(A, D)), "o"),
          ("\\vec{EA} + \\vec{EC} = \\vec{EB} + \\vec{ED}", lambda A, B, C, D, E: add(sub(E, A), sub(E, C)) == add(sub(E, B), sub(E, D)), "o"),
          ("\\vec{AB} + \\vec{BC} + \\vec{CD} = \\vec{AD}", lambda A, B, C, D, E: add(sub(A, B), sub(B, C), sub(C, D)) == sub(A, D), "x")]
conds2 = [("\\vec{AD} = \\vec{BC}", lambda A, B, C, D, E: sub(A, D) == sub(B, C), "o"),
          ("\\vec{EA} + \\vec{EB} = \\vec{EC} + \\vec{ED}", lambda A, B, C, D, E: add(sub(E, A), sub(E, B)) == add(sub(E, C), sub(E, D)), "x"),
          ("\\vec{BD} = \\vec{BA} + \\vec{BC}", lambda A, B, C, D, E: sub(B, D) == add(sub(B, A), sub(B, C)), "o"),
          ("\\vec{AB} − \\vec{AD} = \\vec{DB}", lambda A, B, C, D, E: add(sub(A, B), mul(-1, sub(A, D))) == sub(D, B), "x")]
for conds, (A, B, C) in [(conds1, ((-5, -2), (0, -2), (2, 2))), (conds2, ((-3, 0), (1, -2), (3, 0)))]:
    for name, cond, ans in conds:
        for E in [(0, 0), (-5, 4), (6, -6)]:                 # E 放哪裡都一樣
            lit = sandbox(cond, A, B, C, E)
            if ans == "o":
                assert len(lit) == 1 and para(A, B, C, lit[0]), name
            else:
                # ✕：燈亮的地方有不是平行四邊形的（整片都亮，或只有一個點但是交叉的蝴蝶結）
                assert any(not para(A, B, C, D) for D in lit), name
    # 另外用 2000 組隨機的 A、B、C、D、E 驗 ○ 的條件 ⇔ 平行四邊形
    for _ in range(2000):
        A_, B_, C_, D_, E_ = [(random.randint(-9, 9), random.randint(-9, 9)) for _ in range(5)]
        if cross(sub(A_, B_), sub(A_, C_)) == 0:
            continue
        for name, cond, ans in conds:
            if ans == "o":
                assert cond(A_, B_, C_, D_, E_) == para(A_, B_, C_, D_), name

# 6 伸縮弓：\vec{OX} = k\vec{a} 射得到哪些氣球
for a, balloons in [((2, 1), {"P": ((4, 2), F(2)), "Q": ((-3, F(-3, 2)), F(-3, 2)), "R": ((3, 2), None)}),
                    ((2, -1), {"P": ((-4, 2), F(-2)), "Q": ((3, F(-3, 2)), F(3, 2)), "R": ((-3, 2), None)})]:
    for name, (pos, k) in balloons.items():
        if k is None:
            assert cross(a, pos) != 0
        else:
            assert mul(k, a) == (F(pos[0]), F(pos[1]))
            assert k % F(1, 2) == 0 and -4 <= k <= 4                 # 滑桿每格 1/2

# 7 斜方格：\vec{EF} = x\vec{AB} + y\vec{AD}（用 \vec{AB}、\vec{AD} 當座標軸）
for ae, bf_or_df, F_pt, AE_ans, AF_ans, EF_ans in [
        ((3, 1), ("BC", 2, 1), None, (F(3, 4), F(3, 4)), (F(1), F(2, 3)), (F(1, 4), F(-1, 12))),
        ((1, 1), ("DC", 2, 1), None, (F(1, 2), F(1, 2)), (F(2, 3), F(1)), (F(1, 6), F(1, 2)))]:
    A_, B_, D_ = (0, 0), (1, 0), (0, 1); C_ = (1, 1)            # 斜方格座標
    E_ = div(A_, C_, *ae)
    seg, m, n = bf_or_df
    Fp = div({"B": B_, "D": D_}[seg[0]], C_, m, n)
    assert E_ == AE_ans and Fp == AF_ans and sub(E_, Fp) == EF_ans
    assert EF_ans[0] * 12 == int(EF_ans[0] * 12) and EF_ans[1] * 12 == int(EF_ans[1] * 12)   # 斜方格 12 等分
# 同一組用真的座標驗（平行四邊形 A(0,0) B(6,0) D(2,4)）
Ar, Br, Dr = (0, 0), (6, 0), (2, 4); Cr = add(Br, sub(Ar, Dr))
Er = div(Ar, Cr, 3, 1); Fr = div(Br, Cr, 2, 1)
assert coef(sub(Er, Fr), sub(Ar, Br), sub(Ar, Dr)) == (F(1, 4), F(-1, 12))

# 8 不共線：係數都是 0
# 第 1 組：(x − 2y + 1)\vec{AB} + (x + y − 5)\vec{AC} = \vec{0}
sol = [(x, y) for x in range(-10, 11) for y in range(-10, 11) if x - 2 * y + 1 == 0 and x + y - 5 == 0]
assert sol == [(3, 2)]
# 第 2 組：x\vec{AB} + (y − 1)\vec{CB} + (x + 4)\vec{AC} = \vec{0}，\vec{CB} = \vec{AB} − \vec{AC}
# ⇒ (x + y − 1)\vec{AB} + (x − y + 5)\vec{AC} = \vec{0}
A, B, C = (0, 0), (5, 1), (1, 4)
sol = [(x, y) for x in range(-10, 11) for y in range(-10, 11)
       if add(mul(x, sub(A, B)), mul(y - 1, sub(C, B)), mul(x + 4, sub(A, C))) == (0, 0)]
assert sol == [(-2, 3)]
for x, y in [(1, 7), (-3, 2), (0, 0)]:                       # 化簡後的係數和原式一樣
    assert add(mul(x, sub(A, B)), mul(y - 1, sub(C, B)), mul(x + 4, sub(A, C))) == \
        add(mul(x + y - 1, sub(A, B)), mul(x - y + 5, sub(A, C)))

# ======== 第二章 ========
# 10 繩上珠子：\ol{BP} : \ol{PC} = m : n ⇒ \vec{AP} = \frac{n}{m+n}\vec{AB} + \frac{m}{m+n}\vec{AC}
A, B, C = (0, 4), (-4, -2), (5, -2)
for m, n, ans in [(1, 3, (F(3, 4), F(1, 4))), (3, 2, (F(2, 5), F(3, 5)))]:
    P = div(B, C, m, n)
    assert coef(sub(A, P), sub(A, B), sub(A, C)) == ans and sum(ans) == 1
    # 砝碼：B 掛 n、C 掛 m 會在 P 平衡（力矩）
    assert n * dist(B, P) == m * dist(P, C) or abs(n * dist(B, P) - m * dist(P, C)) < 1e-9

# 11 終點減起點
A, B, C = (0, 5), (-5, -1), (4, -1)
P = div(B, C, 2, 1); Q = div(A, C, 3, 1)
assert coef(sub(A, P), sub(A, B), sub(A, C)) == (F(1, 3), F(2, 3))
assert coef(sub(A, Q), sub(A, B), sub(A, C)) == (0, F(3, 4))
assert coef(sub(P, Q), sub(A, B), sub(A, C)) == (F(-1, 3), F(1, 12))
P = div(A, B, 2, 1); Q = div(B, C, 1, 1)                   # 第 2 組：\ol{AP} = 2\ol{PB}，Q 是 \ol{BC} 中點
assert coef(sub(P, Q), sub(A, B), sub(A, C)) == (F(-1, 6), F(1, 2))

# 12 梯形
for k, m, n, ans in [(3, 1, 2, (F(7, 9), F(1, 3))), (2, 1, 1, (F(3, 4), F(1, 2)))]:
    A, B, D = (0, 0), (6 * k, 0), (2, 5)                   # \ol{AB} = k\ol{DC}，DC ∥ AB
    C = add(D, (F(6 * k, k), 0))
    M = div(B, C, m, n)
    assert coef(sub(A, C), sub(A, B), sub(A, D)) == (F(1, k), 1)
    assert coef(sub(A, M), sub(A, B), sub(A, D)) == ans

# 13 角平分線：AB = 4、AC = 6、BC = 5；AB = 6、AC = 3、BC = 6
def tri(c, b, a):                                          # \ol{AB} = c、\ol{AC} = b、\ol{BC} = a；B(0,0)、C(a,0)
    x = (c * c - b * b + a * a) / (2 * a); y = math.sqrt(c * c - x * x)
    return (x, y), (0.0, 0.0), (float(a), 0.0)
for c, b, a, ratio, ans in [(4, 6, 5, (2, 3), (F(3, 5), F(2, 5))), (6, 3, 6, (2, 1), (F(1, 3), F(2, 3)))]:
    A, B, C = tri(c, b, a)
    D = div(B, C, *ratio)
    # D 真的在角平分線上：∠BAD = ∠DAC
    def ang(p, q, r):
        u, v = sub(q, p), sub(q, r); return math.acos((u[0] * v[0] + u[1] * v[1]) / (math.hypot(*u) * math.hypot(*v)))
    assert abs(ang(B, A, D) - ang(D, A, C)) < 1e-9
    assert (F(ratio[1], sum(ratio)), F(ratio[0], sum(ratio))) == ans

# 14 內切圓：切線長
for c, a, b, BD, DC, ans in [(6, 7, 5, 4, 3, (F(3, 7), F(4, 7))), (7, 8, 5, 5, 3, (F(3, 8), F(5, 8)))]:
    s = F(a + b + c, 2)
    x, y, z = s - a, s - b, s - c                          # 從 A、B、C 出發的切線長
    assert x + y == c and y + z == a and x + z == b and (y, z) == (BD, DC)
    assert (F(DC, a), F(BD, a)) == ans

# 15 高的垂足
for c, a, b, BD, ans in [(13, 14, 15, 5, (F(9, 14), F(5, 14))), (10, 21, 17, 6, (F(5, 7), F(2, 7)))]:
    sols = [x for x in range(0, a + 1) if c * c - x * x == b * b - (a - x) ** 2]
    assert sols == [BD] and c * c - BD * BD > 0
    assert (F(a - BD, a), F(BD, a)) == ans
    assert math.isqrt(c * c - BD * BD) ** 2 == c * c - BD * BD     # 高是整數（12、8）

# 16 面積比 → 邊長比 → 分點
for af, fb, area, k, fp_pc, ans in [((1, 1), None, (4, 9), F(2, 3), (3, 2), (F(4, 5), F(3, 5))),
                                    ((1, 2), None, (1, 4), F(1, 2), (2, 1), (F(7, 9), F(2, 3)))]:
    A, B, D = (0, 0), (6, 0), (2, 4); C = add(B, sub(A, D))
    Fp = div(A, B, *af)
    FB = dist(Fp, B)
    EC = float(k) * FB
    E = (C[0] - EC, C[1])                                   # E 在 \ol{DC} 上（DC 平行 AB，往左量）
    # P = BE ∩ CF
    def inter(p1, p2, p3, p4):
        d = cross(sub(p1, p2), sub(p3, p4))
        t = cross(sub(p1, p3), sub(p3, p4)) / d
        return add(p1, mul(t, sub(p1, p2)))
    P = inter(B, E, C, Fp)
    def area_t(p, q, r): return abs(cross(sub(p, q), sub(p, r))) / 2
    assert abs(area_t(P, E, C) / area_t(P, Fp, B) - area[0] / area[1]) < 1e-9
    assert abs(math.sqrt(area[0] / area[1]) - float(k)) < 1e-12
    assert abs(dist(Fp, P) / dist(P, C) - fp_pc[0] / fp_pc[1]) < 1e-9
    x, y = coef(sub(A, P), sub(A, B), sub(A, D))
    assert abs(x - float(ans[0])) < 1e-9 and abs(y - float(ans[1])) < 1e-9

print("OK")
