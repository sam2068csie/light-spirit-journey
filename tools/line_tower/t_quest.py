# 湖畔委託（應用題）
from lib import *


def _perp_bis(A, B):
    """AB 的中垂線：ax + by = c（約分）"""
    dx, dy = B[0] - A[0], B[1] - A[1]
    M_ = (F(A[0] + B[0]) / 2, F(A[1] + B[1]) / 2)
    a_, b_, c_ = lin_norm(dx, dy, -(dx * M_[0] + dy * M_[1]))
    return a_, b_, -c_


def _eq(a_, b_, c_):
    return poly([(a_, "x"), (b_, "y")]) + " = " + t(c_)


# ---------- lq_boats：同時抵達的救生艇 ----------

def lq_boats(A, B, axis, c, offs):
    M_ = (F(A[0] + B[0]) / 2, F(A[1] + B[1]) / 2)
    mab = F(B[1] - A[1]) / (B[0] - A[0])
    mp = -1 / mab
    pa, pb, pc = _perp_bis(A, B)
    if axis == "x":
        y = (pc - pa * c) / F(pb)
        Pp = (F(c), y)
        sub = "%s = %s" % (poly([(pa * c, ""), (pb, "y")]), t(pc))
        tmpl, ans = "P(%s, [0])" % t(c), [a(y)]
    else:
        x = (pc - pb * c) / F(pa)
        Pp = (x, F(c))
        sub = "%s = %s" % (poly([(pa, "x"), (pb * c, "")]), t(pc))
        tmpl, ans = "P([0], %s)" % t(c), [a(x)]
    assert isint(Pp[0]) and isint(Pp[1])
    da = (Pp[0] - A[0]) ** 2 + (Pp[1] - A[1]) ** 2
    db = (Pp[0] - B[0]) ** 2 + (Pp[1] - B[1]) ** 2
    assert da == db
    lab_ab = lin_norm(B[1] - A[1], -(B[0] - A[0]), 0)
    ab_line = _eq(lab_ab[0], lab_ab[1], -(lab_ab[0] * A[0] + lab_ab[1] * A[1]))
    pA = _eq(pa, pb, pa * A[0] + pb * A[1])
    pB = _eq(pa, pb, pa * B[0] + pb * B[1])
    right = _eq(pa, pb, pc)
    xr, yr = box([A, B, Pp], pad=1.0)
    o = lambda k: offs.get(k, (8, -8))
    gl = ln(1, 0, -c, xr, yr, "dim", dash=True) if axis == "x" else ln(0, 1, -c, xr, yr, "dim", dash=True)
    where = "直線 %s = %s 上" % (axis, t(c))
    return {"id": "lq_boats", "kind": "quest", "tier": 1, "title": "同時抵達的救生艇", "tmul": 1.1,
            "stem": "湖邊兩個碼頭 A%s、B%s。一根漂流木在%s，兩艘一樣快的救生艇從 A、B 同時出發，要同時抵達。漂流木在哪裡？" % (P(*A), P(*B), where),
            "plot": geo(xr, yr, [pt(A, "A", off=o("A")), pt(B, "B", off=o("B")), gl,
                                 ln(pa, pb, -pc, xr, yr, "lime", at=4), pt(M_, "M", "lime", 3, o("M")), pt(Pp, "P", "pink", 5, o("P"))]),
            "steps": [
                choice("一樣快、同時出發、同時抵達，漂流木 P 滿足？", ["\\ol{PA} = \\ol{PB}", "\\ol{PA} + \\ol{PB} 最小", "P 在 \\ol{AB} 上", "\\ol{PA} = 2\\ol{PB}"],
                       "走的時間一樣、速度一樣 ⇒ 路程一樣", "\\ol{PA} = \\ol{PB}"),
                choice("到 A、B 一樣遠的點在哪裡？", ["\\ol{AB} 的中垂線上", "\\ol{AB} 上", "以 A 為圓心的圓上", "過 A 垂直 \\ol{AB} 的線上"],
                       "等距點的軌跡", "P 在 \\ol{AB} 的中垂線上"),
                fill("\\ol{AB} 的中點和斜率：", "M([0], [1])，m_{AB} = [2]", [a(M_[0]), a(M_[1]), a(mab)],
                     "((%s + %s)/2, (%s + %s)/2)、(%s − %s)/(%s − %s)" % (t(A[0]), tp(B[0]), t(A[1]), tp(B[1]), t(B[1]), tp(A[1]), t(B[0]), tp(A[0]))),
                choice("中垂線：過 M、斜率 %s。" % t(mp), [right, ab_line, pA, pB],
                       "%s = %s(%s)，乘開移項" % ("y" if M_[1] == 0 else "y %s %s" % ("+" if M_[1] < 0 else M, t(abs(M_[1]))),
                                             (M if mp < 0 else "") + ("(" + t(abs(mp)) + ")" if not isint(mp) else ("" if abs(mp) == 1 else t(abs(mp)))),
                                             "x" if M_[0] == 0 else "x %s %s" % ("+" if M_[0] < 0 else M, t(abs(M_[0])))),
                       "中垂線 " + right),
                fill("和 %s = %s 的交點：" % (axis, t(c)), tmpl, ans, sub),
                fill("驗算：", "答：\\ol{PA}^{2} = [0]，\\ol{PB}^{2} = [1]", [da, db],
                     "%s + %s、%s + %s" % (t((Pp[0] - A[0]) ** 2), t((Pp[1] - A[1]) ** 2), t((Pp[0] - B[0]) ** 2), t((Pp[1] - B[1]) ** 2)))]}


# ---------- lq_signal：步道上的訊號 ----------

def lq_signal(K, r, L, chord2, offs):
    a_, b_, c_ = L
    n = int(math.isqrt(a_ * a_ + b_ * b_))
    assert n * n == a_ * a_ + b_ * b_
    v = a_ * K[0] + b_ * K[1] + c_
    d = F(abs(v)) / n
    assert isint(d) and d < r
    half = rt(r * r - d * d)
    assert half.n == 1
    half = half.c
    tt = -F(v) / (n * n)
    nv = (a_, b_) if tt > 0 else (-a_, -b_)
    H = (K[0] + tt * a_, K[1] + tt * b_)
    u = (-b_ / n, a_ / n)
    E1 = (float(H[0]) + float(half) * u[0], float(H[1]) + float(half) * u[1])
    E2 = (float(H[0]) - float(half) * u[0], float(H[1]) - float(half) * u[1])
    newr2 = d * d + F(chord2, 2) ** 2
    xr, yr = box([K], pad=0.6, circles=[(K, r)])
    return {"id": "lq_signal", "kind": "quest", "tier": 2, "title": "步道上的訊號", "tmul": 1.25,
            "stem": "基地台在 K%s，訊號範圍是半徑 %d 的圓。湖濱步道沿著直線 L：%s。(1) 步道上收得到訊號的那一段多長？(2) 離基地台最近的點？(3) 想讓收得到訊號的那段變成 %d，半徑要調成多少？" % (P(*K), r, lin(*L), chord2),
            "plot": geo(xr, yr, [circ(K, r, "cyan"), pt(K, "K", "cyan", 0, offs.get("K", (8, -8))), ln(a_, b_, c_, xr, yr, "pink"),
                                 seg(K, H, "gold", dash=True, at=1), pt(H, "H", "gold", 4, offs.get("H", (8, -8))),
                                 seg(E1, E2, "lime", w=4.0, at=3)]),
            "steps": [
                fill("基地台到步道：", "d(K, L) = [0]", [a(d)], "|%s|/%d" % (poly([(a_ * K[0], ""), (b_ * K[1], ""), (c_, "")]).replace(" + ", " + "), n)),
                choice("d(K, L) = %s < r = %d，表示？" % (t(d), r), ["有一段收得到", "只碰到一點", "整條都收不到", "整條都收得到"],
                       "d(K, L) < r 是相交", "d(K, L) < r：步道和圓交於兩點"),
                fill("(1) 收得到的那段是弦。畢氏定理：", "半弦長 = √{%d − %s} = [0]，全長 [1]" % (r * r, t(d * d)), [a(half), a(2 * half)], "全長是半弦長的 2 倍"),
                fill("(2) 最近的點是垂足 H：從 K 沿 L 的法向量 %s 走 %s 倍。" % (P(*nv), t(abs(tt))), "H([0], [1])", [a(H[0]), a(H[1])],
                     "(%s + %s, %s + %s)" % (t(K[0]), tp(tt * a_), t(K[1]), tp(tt * b_))),
                fill("(3) 弦長 %d，半弦長 %s，d(K, L) 還是 %s：" % (chord2, t(F(chord2, 2)), t(d)),
                     "答：r = √{%s + %s} = [0]" % (t(d * d), t(F(chord2, 2) ** 2)), [rta(newr2)], "r^{2} = d(K, L)^{2} + %s^{2}" % t(F(chord2, 2)))]}


# ---------- lq_apollo：兩倍遠的小船 ----------

def lq_apollo(a0, k):
    h = F(a0 * (k * k + 1), k * k - 1)
    R2 = h * h - a0 * a0
    R = rt(R2)
    assert isint(h) and R.n == 1
    R = R.c
    area = a0 * R
    far = h + a0 + R
    farP = h + R
    assert farP + a0 == k * (farP - a0)
    k2 = k * k
    xr, yr = box([(-a0, 0)], pad=0.8, circles=[((h, 0), float(R))])
    word = {2: "2 倍", 3: "3 倍"}[k]
    return {"id": "lq_apollo", "kind": "quest", "tier": 3, "title": "燈塔和小船", "tmul": 1.3,
            "stem": "湖上兩座燈塔 A(−%d, 0)、B(%d, 0)。小船 P 一直保持「到 A 的距離是到 B 的 %s」。(1) 小船的航線 (2) △PAB 面積的最大值 (3) 小船離 A 最遠多遠？" % (a0, a0, word),
            "plot": geo(xr, yr, [pt((-a0, 0), "A", "gold", 0, (-8, 18)), pt((a0, 0), "B", "gold", 0, (-8, 18)),
                                 circ((h, 0), R, "cyan", at=3), pt((h, 0), "K", "cyan", 3, (6, 18)),
                                 poly_sh([(-a0, 0), (a0, 0), (h, R)], "lime", fill="lime", alpha=0.15, at=3), pt((h, R), "P", "lime", 3)]),
            "steps": [
                choice("設 P(x, y)，條件寫成：", ["\\ol{PA}^{2} = %d\\ol{PB}^{2}" % k2, "\\ol{PA} = %d\\ol{PB}" % k2, "\\ol{PA}^{2} = %d\\ol{PB}^{2}" % k, "%d\\ol{PA} = \\ol{PB}" % k],
                       "\\ol{PA} = %d\\ol{PB} 兩邊平方" % k, "(x + %d)^{2} + y^{2} = %d[(x − %d)^{2} + y^{2}]" % (a0, k2, a0)),
                fill("展開整理（兩邊除以 %d）：" % (k2 - 1), "x^{2} + y^{2} − [0]x + [1] = 0", [a(2 * h), a0 * a0],
                     "%sx^{2} + %sy^{2} − %sx + %s = 0" % (k2 - 1, k2 - 1, t(2 * h * (k2 - 1)), t(a0 * a0 * (k2 - 1)))),
                fill("(1) 配方：", "圓心 ([0], 0)，半徑 [1]", [a(h), a(R)], "(x − %s)^{2} + y^{2} = %s − %d" % (t(h), t(h * h), a0 * a0)),
                fill("(2) 底 \\ol{AB} = %d 固定，高最大是半徑：" % (2 * a0), "△PAB 面積最大 = [0]", [a(area)], "\\frac{1}{2} × %d × %s" % (2 * a0, t(R))),
                fill("(3) A 在圓外，最遠 = A 到圓心 + 半徑：", "答：最遠 [0]", [a(far)],
                     "%s + %s。那一點是 (%s, 0)：\\ol{PA} = %s、\\ol{PB} = %s，真的是 %d 倍" % (t(h + a0), t(R), t(farP), t(farP + a0), t(farP - a0), k))]}


def items():
    return [
        [lq_boats((0, 0), (6, 4), "x", 1, {"A": (-20, 14)}), lq_boats((1, 6), (7, 2), "y", 1, {"P": (-8, 18)}),
         lq_boats((-2, 1), (4, 3), "x", 2, {"P": (8, 10)})],
        [lq_signal((3, 4), 5, (3, 4, -40), 16, {}), lq_signal((-2, 1), 5, (4, -3, -9), 10, {}), lq_signal((1, -2), 5, (4, 3, 17), 12, {"H": (-22, -6)})],
        [lq_apollo(3, 2), lq_apollo(4, 3), lq_apollo(6, 2)],
    ]
