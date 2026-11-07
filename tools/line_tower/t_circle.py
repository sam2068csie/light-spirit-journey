# 圓與弦
from lib import *


def circ_gen(h, k, r2):
    """x^2 + y^2 + Dx + Ey + F = 0"""
    return poly([(1, "x^{2}"), (1, "y^{2}"), (-2 * h, "x"), (-2 * k, "y"), (h * h + k * k - r2, "")]) + " = 0"


# ---------- lc_nearest：動點的距離平方 ----------

def lc_nearest(K, r, Q, offs):
    kq2 = (K[0] - Q[0]) ** 2 + (K[1] - Q[1]) ** 2
    kq = rt(kq2)
    assert kq.n == 1 and kq.c > r
    kq = int(kq.c)
    lo, hi = kq - r, kq + r
    u = ((K[0] - Q[0]) / kq, (K[1] - Q[1]) / kq)
    far = (K[0] + r * u[0], K[1] + r * u[1])
    expr = sh("a", Q[0]) + "^{2} + " + sh("b", Q[1]) + "^{2}"
    xr, yr = box([Q], pad=1.0, circles=[(K, r)])
    o = lambda k: offs.get(k, (8, -8))
    Fc = K[0] ** 2 + K[1] ** 2 - r * r
    return {"id": "lc_nearest", "kind": "circle", "tier": 1, "title": "動點的距離平方", "tmul": 1.05,
            "stem": "點 (a, b) 在圓 %s 上。求 %s 的最小值與最大值。" % (circ_gen(K[0], K[1], r * r), expr),
            "plot": geo(xr, yr, [circ(K, r, "cyan", at=1), pt(K, "K", "cyan", 1, o("K")), pt(Q, "Q", "pink", 2, o("Q")),
                                 seg(Q, far, "pink", dash=True, at=3)]),
            "steps": [
                fill("配方：", "圓心 K([0], [1])，半徑 [2]", [a(K[0]), a(K[1]), a(r)],
                     "%s^{2} + %s^{2} = %s" % (sh("x", K[0]), sh("y", K[1]), " + ".join(t(v) for v in [K[0] ** 2, K[1] ** 2, -Fc] if v != 0))),
                choice("%s 是什麼？" % expr, ["(a, b) 到 Q%s 距離的平方" % P(*Q), "(a, b) 到 %s 距離的平方" % P(-Q[0], -Q[1]),
                                            "(a, b) 到 Q%s 的距離" % P(*Q), "(a, b) 到原點距離的平方"],
                       "(a − %s)^{2} + (b − %s)^{2}" % (tp(Q[0]), tp(Q[1])), "所求 = \\ol{PQ}^{2}，P(a, b) 在圓上"),
                fill("Q 到圓心：", "\\ol{KQ} = [0]", [kq], "√{%d + %d}" % ((K[0] - Q[0]) ** 2, (K[1] - Q[1]) ** 2)),
                fill("Q 在圓外，圓上離 Q 最近、最遠的點都在直線 KQ 上：", "最近 [0]，最遠 [1]", [lo, hi], "%d − %d、%d + %d" % (kq, r, kq, r)),
                fill("記得要平方：", "答：最小值 [0]，最大值 [1]", [lo * lo, hi * hi], "%d^{2}、%d^{2}" % (lo, hi))]}


# ---------- lc_twoline：夾在平行線中間的圓 ----------

def lc_twoline(a_, b_, c1, c2, pM, qM, labs):
    """兩條平行線 ax + by + c = 0；圓心在 x = p·y + q 上"""
    n = rt(a_ * a_ + b_ * b_)
    assert n.n == 1
    n = int(n.c)
    dd = F(abs(c1 - c2)) / n
    r = dd / 2
    assert isint(dd) and r != 1
    cm = F(c1 + c2) / 2
    # 圓心：x = p y + q 代進 ax + by + cm = 0
    y0 = -(a_ * qM + cm) / (a_ * pM + b_)
    x0 = pM * y0 + qM
    assert isint(x0) and isint(y0)
    half = F(abs(c1 - c2)) / 2
    assert half not in (cm, -cm)
    mids = [lin(a_, b_, cm), lin(a_, b_, -half), lin(a_, b_, half), lin(-b_, a_, cm) if -b_ > 0 else lin(b_, -a_, cm)]
    M_eq = poly([(1, "x"), (-pM, "y")]) + " = " + t(qM)
    xr, yr = box([(x0, y0)], pad=0.2, circles=[((x0, y0), float(r) * 2.3)])
    finals = [circ_eq(x0, y0, r * r), circ_eq(x0, y0, dd * dd), circ_eq(-x0, -y0, r * r), circ_eq(x0, y0, r)]
    sub = "x = %s 代進去：%s = 0" % (poly([(pM, "y"), (qM, "")]), poly([(a_ * pM, "y"), (a_ * qM, ""), (b_, "y"), (cm, "")]))
    return {"id": "lc_twoline", "kind": "circle", "tier": 2, "title": "夾在平行線中間的圓", "tmul": 1.2,
            "stem": "圓 C 和兩條平行線 L_{1}：%s、L_{2}：%s 都相切，圓心在直線 %s 上。求 C 的方程式。" % (lin(a_, b_, c1), lin(a_, b_, c2), M_eq),
            "plot": geo(xr, yr, [ln(a_, b_, c1, xr, yr, "cyan"), ln(a_, b_, c2, xr, yr, "cyan"), ln(1, -pM, -qM, xr, yr, "dim", dash=True),
                                 ln(a_, b_, cm, xr, yr, "lime", dash=True, at=3), circ((x0, y0), r, "pink", at=4), pt((x0, y0), "K", "pink", 4),
                                 lab(labs[0], "L1", "cyan"), lab(labs[1], "L2", "cyan")]),
            "steps": [
                fill("兩條平行線的距離：", "d(L_{1}, L_{2}) = \\frac{|%s − %s|}{%d} = [0]" % (t(c1), tp(c2), n), [a(dd)], "%s/%d" % (t(abs(c1 - c2)), n)),
                fill("圓夾在兩條線中間，直徑就是這個距離：", "r = [0]", [a(r)], "%s 的一半" % t(dd)),
                choice("圓心到兩條線一樣遠，在正中間那條線上：", mids, "常數取平均：(%s + %s)/2" % (t(c1), tp(c2)), "圓心在 %s 上" % mids[0]),
                fill("和 %s 聯立：" % M_eq, "圓心 ([0], [1])", [a(x0), a(y0)], sub),
                choice("C 的方程式：", finals, "右邊是 r^{2}", "答：" + finals[0])]}


# ---------- lc_count：整數距離的點 ----------

def lc_count(R, a_, b_, c_):
    n = int(math.isqrt(a_ * a_ + b_ * b_))
    assert n * n == a_ * a_ + b_ * b_
    d = F(abs(c_)) / n
    assert isint(d) and 0 < d < R
    d = int(d)
    near, far = R - d, R + d
    both = list(range(1, near))
    mid = list(range(near + 1, far))
    total = 4 * len(both) + 3 + 2 * len(mid) + 1
    assert total == 4 * R - 2
    xr = [-R - 2.6, R + 2.6]
    yr = [-R - 1.2, R + 2.6]
    sg = 1 if c_ < 0 else -1          # 直線在原點的哪一側（法向量方向）
    tp_ = (R * a_ / n, R * b_ / n)
    sh_ = [circ((0, 0), R, "cyan"), ln(a_, b_, -c_ if False else c_, xr, yr, "pink"),
           ln(a_, b_, -R * n, xr, yr, "dim", dash=True, at=1), ln(a_, b_, R * n, xr, yr, "dim", dash=True, at=1),
           pt((0, 0), "O", "cyan"), pt(tp_, "", "lime", 1), pt((-tp_[0], -tp_[1]), "", "lime", 1)]
    L = poly([(a_, "x"), (b_, "y")]) + " = " + t(-c_)
    step3 = "，".join("距離 %d 有 [%d] 個" % (v, i) for i, v in enumerate(both))
    names3 = "、".join(str(v) for v in both)
    if len(mid) == 1:
        tm = "%d 有 [0] 個，%d 有 [1] 個" % (mid[0], far)
        qm = "距離 %d 只在 O 那一側，距離 %d 是那一側最遠的切點：" % (mid[0], far)
    elif len(mid) <= 3:
        tm = "%s 各 [0] 個，%d 有 [1] 個" % ("、".join(str(v) for v in mid), far)
        qm = "距離 %s 只在 O 那一側，距離 %d 是那一側最遠的切點：" % ("、".join(str(v) for v in mid), far)
    else:
        tm = "%d 到 %d 各 [0] 個，%d 有 [1] 個" % (mid[0], mid[-1], far)
        qm = "距離 %d 到 %d 只在 O 那一側，距離 %d 是那一側最遠的切點：" % (mid[0], mid[-1], far)
    parts = [4] * len(both) + [3] + [2] * len(mid) + [1]
    return {"id": "lc_count", "kind": "circle", "tier": 2, "title": "整數距離的點", "tmul": 1.3,
            "stem": "圓 x^{2} + y^{2} = %d 上，到直線 L：%s 的距離是正整數的點，一共有幾個？" % (R * R, L),
            "plot": geo(xr, yr, sh_),
            "steps": [
                fill("圓心到 L：", "d(O, L) = [0]", [d], "%d/%d" % (abs(c_), n)),
                fill("L 把圓切成兩邊。圓上的點到 L 最遠多遠？（虛線是和圓相切、和 L 平行的線）", "和 O 同一側最遠 [0]，另一側最遠 [1]", [far, near],
                     "%d + %d、%d − %d" % (R, d, R, d)),
                fill("距離 %s：兩邊都到得了，每一邊各有 2 個點：" % names3, step3, [4] * len(both), "2 + 2"),
                fill("距離 %d：另一側最遠剛好是 %d，只有切點那 1 個：" % (near, near), "距離 %d 有 [0] 個" % near, [3], "O 那一側 2 個，加上另一側 1 個"),
                fill(qm, tm, [2, 1], "最遠的地方只有一個點"),
                fill("全部加起來：", "答：%s = [0] 個" % " + ".join(str(v) for v in parts), [total], "慢慢加")]}


# ---------- lc_semi：半圓和平移的直線 ----------

def lc_semi(R, s):
    """√{R^2 − x^2} = s·x + k（s = ±1）"""
    Rt = str(R)
    R2t = ("" if R == 1 else str(R)) + "√{2}"
    R2a = ("" if R == 1 else str(R)) + "√2"
    end = (-R, 0) if s > 0 else (R, 0)
    xr = [-R - 1.2, R + 1.2]
    yr = [-1.0, R + 1.6]
    rhs = ("x" if s > 0 else "−x") + " + k"
    side = "左" if s > 0 else "右"
    shapes = [{"k": "arc", "o": [0, 0], "r": R, "a0": 0, "a1": 180, "c": "cyan"},
              ln(s, -1, R, xr, yr, "pink", dash=True, at=3), ln(s, -1, R * math.sqrt(2), xr, yr, "pink", dash=True, at=3),
              pt((-R, 0), "", "cyan"), pt((R, 0), "", "cyan")]
    opts2 = ["斜率 %d，k 變大往上移" % s, "繞著 (0, k) 轉", "斜率是 k 的直線", "繞著原點轉"]
    return {"id": "lc_semi", "kind": "circle", "tier": 2, "title": "半圓和平移的直線", "tmul": 1.2,
            "stem": "方程式 √{%d − x^{2}} = %s 有兩個相異實根，求 k 的範圍。" % (R * R, rhs),
            "plot": geo(xr, yr, shapes),
            "steps": [
                choice("y = √{%d − x^{2}} 的圖形是？" % (R * R), ["上半圓（含左右兩個端點）", "下半圓", "整個圓", "右半圓"],
                       "兩邊平方 x^{2} + y^{2} = %d，而且 y ≥ 0" % (R * R), "y = √{%d − x^{2}}：半徑 %d 的上半圓" % (R * R, R)),
                choice("y = %s 呢？" % rhs, opts2, "斜率固定是 %d，k 是 y 截距" % s, "y = %s：斜率 %d，上下平移" % (rhs, s)),
                fill("兩個關鍵位置：剛好通過%s端點 %s，以及和半圓相切（\\frac{|k|}{√{2}} = %d）：" % (side, P(*end), R),
                     "通過 %s：k = [0]，相切：k = [1]" % P(*end), [Rt, R2a],
                     "0 = %s + k。切點在%s上方，k 取正的" % (t(s * end[0]), side)),
                {"t": "line", "q": "從下往上平移：通過 %s 時開始有兩個交點，相切時變成一個。封印 k 的範圍。" % P(*end), "row": "兩個根",
                 "marks": [Rt, R2t], "seg": [0, 1, 0], "pt": [1, 0], "write": "答：%s ≤ k < %s" % (Rt, R2t)}]}


# ---------- lc_quad：最大的四邊形 ----------

def lc_quad(R2, A, B, offs, pq_name):
    for p_ in (A, B):
        assert p_[0] ** 2 + p_[1] ** 2 == R2
    ab2 = (A[0] - B[0]) ** 2 + (A[1] - B[1]) ** 2
    d2 = F(R2) - F(ab2) / 4
    R = rt(R2)
    ab = rt(ab2)
    # 面積 = ½·AB·2R
    area = rt(F(ab2) * R2)
    # P、Q：過 O 垂直 AB 的直線和圓的交點（P 在 AB 的另一側…P 取和弦中點同側）
    M_ = ((A[0] + B[0]) / 2, (A[1] + B[1]) / 2)
    mlen = math.hypot(*M_)
    Pp = (R.val() * M_[0] / mlen, R.val() * M_[1] / mlen)
    Qp = (-Pp[0], -Pp[1])
    xr, yr = box([], pad=1.2, circles=[((0, 0), R.val())])
    o = lambda k: offs.get(k, (8, -8))
    return {"id": "lc_quad", "kind": "circle", "tier": 3, "title": "最大的四邊形", "tmul": 1.3,
            "stem": "圓 x^{2} + y^{2} = %d 上有 A%s、B%s。P、Q 是圓上的動點，分別在弦 \\ol{AB} 的兩側。求四邊形 APBQ 面積的最大值。" % (R2, P(*A), P(*B)),
            "plot": geo(xr, yr, [circ((0, 0), R.val(), "cyan"), seg(A, B, "pink"), pt(A, "A", off=o("A")), pt(B, "B", off=o("B")),
                                 ln(M_[1], -M_[0], 0, xr, yr, "dim", dash=True, at=5),
                                 poly_sh([A, Pp, B, Qp], "lime", fill="lime", alpha=0.15, at=5),
                                 pt(Pp, "P", "lime", 5, o("P")), pt(Qp, "Q", "lime", 5, o("Q"))]),
            "steps": [
                fill("弦長：", "\\ol{AB} = [0]", [ab.ans()], "√{%d + %d}" % ((A[0] - B[0]) ** 2, (A[1] - B[1]) ** 2)),
                choice("把四邊形 APBQ 沿一條對角線拆成兩個三角形，要讓底固定不動，沿哪一條拆？", ["\\ol{AB}", "\\ol{PQ}", "\\ol{AP}", "\\ol{BQ}"],
                       "P、Q 會動，固定不動的是 \\ol{AB}（\\ol{AP}、\\ol{BQ} 是邊，不是對角線）", "面積 = \\frac{1}{2} · \\ol{AB} · (P 的高 + Q 的高)"),
                fill("d(O, AB) = %s。兩邊最遠的高：一邊是 r + d(O, AB)，一邊是 r − d(O, AB)：" % rtt(d2), "兩個高加起來最大 = [0]",
                     [Surd(2 * R.c, R.n).ans()], "相加之後 d(O, AB) 消掉了，剩 2r"),
                fill("面積最大：", "答：\\frac{1}{2} · %s · %s = [0]" % (ab.text(), Surd(2 * R.c, R.n).text()), [area.ans()],
                     "%s × %s" % (ab.text(), R.text())),
                choice("這時候 P、Q 在哪裡？", ["%s 和圓的交點" % pq_name, "x 軸和圓的交點", "y 軸和圓的交點", "A、B 對 O 的對稱點"],
                       "離 \\ol{AB} 最遠的點，在過圓心且垂直 \\ol{AB} 的直線上", "P、Q 在直線 %s 上（\\ol{PQ} 是直徑）" % pq_name)]}


def items():
    return [
        [lc_nearest((2, -1), 3, (-2, 2), {}), lc_nearest((1, 2), 2, (4, -2), {"Q": (8, 4)}), lc_nearest((-3, 0), 2, (3, 8), {})],
        [lc_twoline(3, -4, 2, -18, 2, 2, [(0.6, 2.4), (7.6, 0.4)]), lc_twoline(4, -3, 8, -12, -1, 4, [(-1.6, 1.6), (4.6, 1.0)]),
         lc_twoline(3, 4, 10, -20, 1, -3, [(-5.6, 0.2), (5.0, 1.4)])],
        [lc_count(5, 3, 4, -10), lc_count(4, 4, -3, -5), lc_count(6, 3, 4, -20)],
        [lc_semi(2, 1), lc_semi(3, 1), lc_semi(2, -1)],
        [lc_quad(25, (5, 0), (0, 5), {"A": (6, 14), "B": (8, -6), "Q": (-22, 14)}, "y = x"),
         lc_quad(25, (5, 0), (3, 4), {"A": (6, 14), "Q": (-22, 14)}, "y = \\frac{1}{2}x"),
         lc_quad(10, (3, 1), (-1, 3), {"B": (-22, -6), "Q": (-22, 14)}, "y = 2x")],
    ]
