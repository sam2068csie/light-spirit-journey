"""R3 天秤市集（次序不等式）：設計稿 docs/num_r3_design.md 的數字驗算。
範圍用很密的格子掃一遍（端點、0 都會掃到），和設計稿寫的答案比。"""
from fractions import Fraction as F
import itertools

def grid(lo, hi, n=240):
    lo, hi = F(lo), F(hi)
    pts = {lo + (hi - lo) * k / n for k in range(n + 1)}
    if lo < 0 < hi:
        pts.add(F(0))
    return sorted(pts)

def rng(f, xr, yr=None):
    if yr is None:
        vals = [f(x) for x in grid(*xr)]
    else:
        vals = [f(x, y) for x in grid(*xr, 60) for y in grid(*yr, 60)]
    return (min(vals), max(vals))

def absr(a, b):            # |x − a| ≤ b
    return (F(a) - F(b), F(a) + F(b))

# 1 距離寫成範圍
assert absr(1, 3) == (-2, 4) and absr(F(3, 2), F(5, 2)) == (-1, 4)        # |2y − 3| ≤ 5
assert absr(-2, 2) == (-4, 0) and absr(F(-1, 2), F(3, 2)) == (-2, 1)      # |2y + 1| ≤ 3

# 2 加和減
for xr, yr, s, ny, d, wrong in [((-1, 3), (2, 4), (1, 7), (-4, -2), (-5, 1), (-3, -1)),
                                ((-2, 5), (1, 3), (-1, 8), (-3, -1), (-5, 4), (-3, 2))]:
    assert rng(lambda x, y: x + y, xr, yr) == s and rng(lambda y: -y, yr) == ny
    assert rng(lambda x, y: x - y, xr, yr) == d
    assert wrong == (xr[0] - yr[0], xr[1] - yr[1]) and wrong != d        # 端點直接相減

# 3 四個角：最大、最小各在一個角（不能有兩個角一樣大）
def corners(f, xr, yr):
    cs = {(x, y): f(F(x), F(y)) for x in xr for y in yr}
    hi = max(cs.values()); lo = min(cs.values())
    assert list(cs.values()).count(hi) == 1 and list(cs.values()).count(lo) == 1
    return max(cs, key=cs.get), min(cs, key=cs.get), (lo, hi), cs
for xr, yr, pmax, pmin, pr, qmax, qmin, qr in [((-2, 4), (2, 4), (4, 4), (-2, 4), (-8, 16), (4, 2), (-2, 2), (-1, 2)),
                                                ((-3, 1), (1, 3), (1, 3), (-3, 3), (-9, 3), (1, 1), (-3, 1), (-3, 1))]:
    a = corners(lambda x, y: x * y, xr, yr); b = corners(lambda x, y: x / y, xr, yr)
    assert a[:3] == (pmax, pmin, pr) and rng(lambda x, y: x * y, xr, yr) == pr
    assert b[:3] == (qmax, qmin, qr) and rng(lambda x, y: x / y, xr, yr) == qr

# 4 跨過 0 的平方
for xr, yr, sq, wrong, tot in [((-3, 2), (1, 2), (0, 9), (4, 9), (1, 13)), ((-1, 4), (-2, -1), (0, 16), (1, 16), (1, 20))]:
    assert rng(lambda x: x * x, xr) == sq and wrong == tuple(sorted((xr[0] ** 2, xr[1] ** 2))) and wrong != sq
    assert rng(lambda x, y: x * x + y * y, xr, yr) == tot

# 5 哪些一定成立（三張 ○、一張 ✕ 接反例）
for xa, xb, ya, yb, d, p, q, s, s_wrong, ce in [
        (-1, 2, 3, 1, (-7, -1), (-12, 4), (F(-3, 2), F(1, 2)), (4, 25), (5, 25), (0, 2)),
        (0, 1, -3, 1, (1, 5), (-4, 4), (F(-1, 2), F(1, 2)), (4, 17), (5, 17), (0, -2))]:
    xr, yr = absr(xa, xb), absr(ya, yb)
    assert rng(lambda x, y: x - y, xr, yr) == d and rng(lambda x, y: x * y, xr, yr) == p
    assert rng(lambda x, y: x / y, xr, yr) == q and rng(lambda x, y: x * x + y * y, xr, yr) == s
    # 反例：方框裡的格子點，只有一個讓 x² + y² 比 s_wrong 的下限小
    pts = [(x, y) for x in range(int(xr[0]), int(xr[1]) + 1) for y in range(int(yr[0]), int(yr[1]) + 1)
           if x * x + y * y < s_wrong[0]]
    assert pts == [ce], pts

# 7 平方相減
for xr, yr, x2, y2, y2wrong, ans in [((2, 4), (-2, 4), (4, 16), (0, 16), (4, 16), (-12, 16)),
                                     ((-3, -1), (-1, 3), (1, 9), (0, 9), (1, 9), (-8, 9))]:
    assert rng(lambda x: x * x, xr) == x2 and rng(lambda y: y * y, yr) == y2
    assert rng(lambda x, y: x * x - y * y, xr, yr) == ans and y2wrong != y2

# 8 配方再看範圍
for xr, yr, f, h, k, c, hx, ky, mM in [
        ((-2, 3), (-4, 1), lambda x, y: x*x + y*y - 2*x + 4*y + 3, 1, -2, -2, (0, 9), (0, 9), (-2, 16)),
        ((-1, 3), (1, 4), lambda x, y: x*x + y*y + 4*x - 2*y + 1, -2, 1, -4, (1, 25), (0, 9), (-3, 30))]:
    for x, y in itertools.product(range(-5, 6), repeat=2):
        assert f(x, y) == (x - h) ** 2 + (y - k) ** 2 + c
    assert rng(lambda x: (x - h) ** 2, xr) == hx and rng(lambda y: (y - k) ** 2, yr) == ky
    assert rng(f, xr, yr) == mM == (hx[0] + ky[0] + c, hx[1] + ky[1] + c)

# 9 拆成兩個括號
for xr, yr, f, h, k, c, prod, ans in [
        ((-1, 2), (1, 4), lambda x, y: x*y - 2*x - 3*y + 1, 3, 2, -5, (-8, 4), (-13, -1)),
        ((0, 4), (-2, 1), lambda x, y: x*y + x - 2*y + 1, 2, -1, 3, (-4, 4), (-1, 7))]:
    for x, y in itertools.product(range(-5, 6), repeat=2):
        assert f(x, y) == (x - h) * (y - k) + c
    assert rng(lambda x, y: (x - h) * (y - k), xr, yr) == prod and rng(f, xr, yr) == ans
print("R3 verify OK")

# 8（使用者 2026/11/15 改成看距離）：方框裡離中心 C 最近、最遠的格子點都只有一個
for xr, yr, h, k, c, near, far, m, M in [((-2, 3), (-4, 1), 1, -2, -2, (1, -2), (-2, 1), -2, 16),
                                         ((-1, 3), (1, 4), -2, 1, -4, (-1, 1), (3, 4), -3, 30)]:
    pts = [(x, y) for x in range(xr[0], xr[1] + 1) for y in range(yr[0], yr[1] + 1)]
    d = {p: (p[0] - h) ** 2 + (p[1] - k) ** 2 for p in pts}
    assert [p for p in pts if d[p] == min(d.values())] == [near] and [p for p in pts if d[p] == max(d.values())] == [far]
    assert min(d.values()) + c == m and max(d.values()) + c == M
print("R3 distance OK")
