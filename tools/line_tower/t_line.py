# 直線工法
from lib import *
import itertools


def _len_text(p, q):
    return rtt((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2)


def _slope(p, q):
    assert p[0] != q[0]
    return F(q[1] - p[1]) / (q[0] - p[0])


def ray(p, q, xr, yr):
    """從 p 經過 q 一直走到框邊"""
    dx, dy = q[0] - p[0], q[1] - p[1]
    best = None
    for tt in [(xr[0] - p[0]) / dx if dx else None, (xr[1] - p[0]) / dx if dx else None,
               (yr[0] - p[1]) / dy if dy else None, (yr[1] - p[1]) / dy if dy else None]:
        if tt is not None and tt > 1e-9:
            x, y = p[0] + tt * dx, p[1] + tt * dy
            if xr[0] - 1e-6 <= x <= xr[1] + 1e-6 and yr[0] - 1e-6 <= y <= yr[1] + 1e-6:
                best = tt if best is None else min(best, tt)
    return (p[0] + best * dx, p[1] + best * dy)


# ---------- ll_rhombus ----------

def ll_rhombus(A, B, D, offs=None):
    offs = offs or {}
    ab2 = (B[0] - A[0]) ** 2 + (B[1] - A[1]) ** 2
    ad2 = (D[0] - A[0]) ** 2 + (D[1] - A[1]) ** 2
    assert ab2 == ad2, "要是菱形"
    C = (B[0] + D[0] - A[0], B[1] + D[1] - A[1])
    mac, mbd = _slope(A, C), _slope(B, D)
    assert mac * mbd == -1
    ac2 = (C[0] - A[0]) ** 2 + (C[1] - A[1]) ** 2
    bd2 = (D[0] - B[0]) ** 2 + (D[1] - B[1]) ** 2
    area = rt(ac2 * bd2).c / 2
    assert rt(ac2 * bd2).n == 1 and isint(area)
    acT, bdT = rtt(ac2), rtt(bd2)
    xr, yr = box([A, B, C, D], pad=1.0)
    o = lambda k: offs.get(k, (8, -8))
    return {"id": "ll_rhombus", "kind": "line", "tier": 1, "title": "菱形的第四個頂點", "tmul": 1.05,
            "stem": "菱形 ABCD 的三個頂點是 A%s、B%s、D%s。求 C 的坐標，以及菱形的面積。" % (P(*A), P(*B), P(*D)),
            "plot": geo(xr, yr, [poly_sh([A, B, C, D], "cyan", fill="cyan", alpha=0.12, at=2),
                                 seg(A, C, "pink", dash=True, at=3), seg(B, D, "pink", dash=True, at=3),
                                 pt(A, "A", off=o("A")), pt(B, "B", off=o("B")), pt(D, "D", off=o("D")), pt(C, "C", "cyan", 2, o("C"))]),
            "steps": [
                choice("菱形（平行四邊形）的對角線互相平分：\\ol{AC} 和 \\ol{BD} 的中點一樣。所以 C = ？",
                       ["B + D − A", "A + B − D", "A + D − B", "2B − A"], "A + C = B + D", "A + C = B + D ⇒ C = B + D − A"),
                fill("算出 C：", "C = ([0], [1])", [a(C[0]), a(C[1])],
                     "(%s + %s − %s, %s + %s − %s)" % (t(B[0]), tp(D[0]), tp(A[0]), t(B[1]), tp(D[1]), tp(A[1]))),
                fill("兩條對角線的斜率：", "m_{AC} = [0]，m_{BD} = [1]", [a(mac), a(mbd)],
                     "(%s − %s)/(%s − %s)、(%s − %s)/(%s − %s)" % (t(C[1]), tp(A[1]), t(C[0]), tp(A[0]), t(D[1]), tp(B[1]), t(D[0]), tp(B[0]))),
                choice("斜率相乘是 −1，代表兩條對角線？", ["互相垂直", "互相平行", "一樣長", "不會相交"],
                       "m_{1}m_{2} = −1 ⇔ 垂直", "對角線互相垂直（菱形）"),
                fill("\\ol{AC} = %s、\\ol{BD} = %s，菱形面積 = 對角線相乘的一半：" % (acT, bdT),
                     "答：面積 = \\frac{1}{2} · %s · %s = [0]" % (acT, bdT), [a(area)],
                     "%s · %s = %s" % (acT, bdT, t(2 * area)))]}


# ---------- ll_three：看圖比係數 ----------

def _order(names_vals, with_zero=False):
    items = sorted(names_vals, key=lambda nv: -nv[1])
    if with_zero:
        items = sorted(items + [("0", 0)], key=lambda nv: -nv[1])
    return " > ".join(n for n, v in items)


def ll_three(m, k1, k2, m3, k3, labs):
    assert len({k1, k2, k3, 0}) == 4 and m != m3 and m != 0 and m3 != 0
    ks = [("k_{1}", k1), ("k_{2}", k2), ("k_{3}", k3)]
    right = _order(ks)
    perms = [" > ".join(p) for p in itertools.permutations(["k_{1}", "k_{2}", "k_{3}"])]
    others = [p for p in perms if p != right]
    # 固定挑三個錯的（每組數字不一樣）
    wrong = [others[i] for i in (0, 2, 4)]
    # 斜率
    opts_m = ["m_{1} = m_{2} > m_{3}", "m_{3} > m_{1} = m_{2}", "m_{1} > m_{2} > m_{3}", "m_{1} = m_{2} = m_{3}"]
    mr = opts_m[0] if m > m3 else opts_m[1]
    up = lambda s: "往右上升" if s > 0 else "往右下降"
    mw = "m_{1} = m_{2} %s 0 %s m_{3}" % ((">", ">") if m > 0 > m3 else ("<", "<") if m < 0 < m3 else (">", ">") if m3 > 0 and m > m3 else ("<", "<"))
    # 寫法：m_{1} = m_{2} > m_{3} > 0 之類
    vals = sorted([("m_{1} = m_{2}", m), ("m_{3}", m3), ("0", 0)], key=lambda nv: -nv[1])
    mw = " > ".join(n for n, v in vals)
    hi = max(ks, key=lambda nv: nv[1])[0].replace("k", "L")
    lo = min(ks, key=lambda nv: nv[1])[0].replace("k", "L")
    xr, yr = [-3.4, 3.4], [-3.4, 4.6]
    for k in (k1, k2, k3):
        assert yr[0] + 0.5 < k < yr[1] - 0.5
    lines = [(m, -1, k1, "cyan"), (m, -1, k2, "pink"), (m3, -1, k3, "lime")]
    shapes = [ln(A_, B_, C_, xr, yr, c) for (A_, B_, C_, c) in lines]
    shapes += [lab(labs[0], "L1", "cyan"), lab(labs[1], "L2", "pink"), lab(labs[2], "L3", "lime")]
    return {"id": "ll_three", "kind": "line", "tier": 1, "title": "看圖比係數", "tmul": 1.05,
            "stem": "圖中是三條直線 L_{1}：y = m_{1}x + k_{1}、L_{2}：y = m_{2}x + k_{2}、L_{3}：y = m_{3}x + k_{3}，其中 L_{1}、L_{2} 平行。",
            "plot": geo(xr, yr, shapes),
            "steps": [
                choice("y 截距是直線和 y 軸的交點。k_{1}、k_{2}、k_{3} 由大到小：", [right] + wrong,
                       "看三條線和 y 軸交在哪裡：%s 最高，%s 最低" % (hi.replace("L_{", "L_{"), lo), _order(ks, True)),
                choice("斜率：", [mr] + [o for o in opts_m if o != mr],
                       "L_{1}、L_{2} 平行，%s，L_{3} %s" % (up(m), up(m3)) if (m > 0) != (m3 > 0) else
                       "L_{1}、L_{2} 平行；L_{3} 也%s，但%s" % (up(m3), "比較平" if abs(m3) < abs(m) else "比較陡"), mw),
                fill("兩兩聯立，解的組數就是交點的個數：", "L_{1} 與 L_{2}：[0] 組，L_{1} 與 L_{3}：[1] 組，三條一起：[2] 組", ["0", "1", "0"],
                     "平行線沒有交點。三條一起要同時在三條線上"),
                choice("方程式 (m_{1} − m_{3})x = k_{3} − k_{1} 的解是？", ["L_{1}、L_{3} 交點的 x 坐標", "L_{1} 的 x 截距", "L_{3} 的 x 截距", "L_{1}、L_{2} 交點的 x 坐標"],
                       "它是 m_{1}x + k_{1} = m_{3}x + k_{3} 移項來的", "m_{1}x + k_{1} = m_{3}x + k_{3}：L_{1}、L_{3} 的交點")]}


# ---------- ll_external：外角平分線 ----------

def ll_external(A, B, C, xr, yr, offs):
    ab2 = (B[0] - A[0]) ** 2 + (B[1] - A[1]) ** 2
    ac2 = (C[0] - A[0]) ** 2 + (C[1] - A[1]) ** 2
    assert ab2 == 4 * ac2 and is_square(ab2)
    D = (2 * C[0] - B[0], 2 * C[1] - B[1])
    E = (F(B[0] + 2 * C[0]) / 3, F(B[1] + 2 * C[1]) / 3)
    mad, mae = _slope(A, D), _slope(A, E)
    assert mad * mae == -1
    ab, ac = rt(ab2).c, rt(ac2).c
    o = lambda k: offs.get(k, (8, -8))
    hint_len = "√{%s + %s}、√{%s + %s}" % (t((B[0] - A[0]) ** 2), t((B[1] - A[1]) ** 2), t((C[0] - A[0]) ** 2), t((C[1] - A[1]) ** 2))
    return {"id": "ll_external", "kind": "line", "tier": 2, "title": "外角平分線", "tmul": 1.2,
            "stem": "△ABC 中，A%s、B%s、C%s。∠A 的外角平分線交直線 BC 於 D，內角平分線交 \\ol{BC} 於 E。求 D、E 的坐標。" % (P(*A), P(*B), P(*C)),
            "plot": geo(xr, yr, [poly_sh([A, B, C], "cyan"), seg(B, D, "dim", dash=True, at=2),
                                 seg(A, D, "pink", at=4), seg(A, E, "lime", at=5),
                                 pt(A, "A", off=o("A")), pt(B, "B", off=o("B")), pt(C, "C", off=o("C")), pt(D, "D", "pink", 4, o("D")), pt(E, "E", "lime", 5, o("E"))]),
            "steps": [
                fill("兩邊長：", "\\ol{AB} = [0]，\\ol{AC} = [1]", [a(ab), a(ac)], hint_len),
                choice("外角平分線分 BC 的比也是 \\ol{AB} : \\ol{AC}，只是分在外面。D 在哪裡？\\ol{DB} : \\ol{DC} = ？",
                       ["C 的外側，2 : 1", "\\ol{BC} 上，2 : 1", "B 的外側，2 : 1", "\\ol{BC} 上，1 : 2"],
                       "外分：D 在線段外面。\\ol{DB} 比 \\ol{DC} 長，所以 D 離 C 比較近", "\\ol{DB} : \\ol{DC} = \\ol{AB} : \\ol{AC} = 2 : 1（外分）"),
                choice("\\ol{DB} = 2\\ol{DC}，而且 C 在 B、D 中間。C 是 \\ol{BD} 的什麼點？", ["中點", "靠近 B 的三等分點", "靠近 D 的三等分點", "外分點"],
                       "\\ol{BC} = \\ol{DB} − \\ol{DC} = \\ol{DC}", "C 是 \\ol{BD} 的中點 ⇒ D = 2C − B"),
                fill("算出 D：", "D = 2C − B = ([0], [1])", [a(D[0]), a(D[1])],
                     "(%s − %s, %s − %s)" % (t(2 * C[0]), tp(B[0]), t(2 * C[1]), tp(B[1]))),
                fill("內角平分線的 E 內分 \\ol{BC} 成 2 : 1：", "E = (B + 2C)/3 = ([0], [1])", [a(E[0]), a(E[1])],
                     "((%s + %s)/3, (%s + %s)/3)" % (t(B[0]), tp(2 * C[0]), t(B[1]), tp(2 * C[1]))),
                choice("m_{AD} = %s、m_{AE} = %s，相乘是 −1。這告訴我們？" % (tf(mad), tf(mae)),
                       ["內、外角平分線互相垂直", "內、外角平分線互相平行", "\\ol{AD} = \\ol{AE}", "D、E 對稱於 C"],
                       "%s × %s = −1" % (t(mad), tp(mae)), "答：D%s、E%s，\\ol{AD} ⊥ \\ol{AE}" % (P(*D), P(*E)))]}


# ---------- ll_beam：照進區域的光 ----------

def ll_beam(ca, q, s, Pp, offs):
    A, B = (F(s) / ca, 0), (0, F(s) / q)
    assert isint(A[0])
    O = (0, 0)
    assert isint(B[1])
    sl = {"O": _slope(Pp, O), "A": _slope(Pp, A), "B": _slope(Pp, B)}
    assert len(set(sl.values())) == 3
    assert not (0 <= Pp[0] <= s), "鉛直線不能碰到區域"
    lo = min(sl, key=lambda k: sl[k])
    hi = max(sl, key=lambda k: sl[k])
    xr, yr = box([A, B, O, Pp], pad=1.2)
    o = lambda k: offs.get(k, (8, -8))
    pxs = "x %s %s" % ("+" if Pp[0] < 0 else M, t(abs(Pp[0])))
    lineS = "y = m(%s) %s %s" % (pxs, "+" if Pp[1] > 0 else M, t(abs(Pp[1])))
    region = "x ≥ 0、y ≥ 0、%s ≤ %s" % (poly([(ca, "x"), (q, "y")]), t(s))
    V = {"O": O, "A": A, "B": B}
    hs = lambda k: "(%s %s %s)/(%s %s %s)" % (t(V[k][1]), "+" if Pp[1] < 0 else M, t(abs(Pp[1])), t(V[k][0]), "+" if Pp[0] < 0 else M, t(abs(Pp[0])))
    return {"id": "ll_beam", "kind": "line", "tier": 2, "title": "照進區域的光", "tmul": 1.2,
            "stem": "區域 R：%s。直線 %s 和 R 有交點，求 m 的範圍。" % (region, lineS),
            "plot": geo(xr, yr, [poly_sh([O, A, B], "cyan", fill="cyan", alpha=0.2), pt(Pp, "P", "pink", 1, o("P")),
                                 seg(Pp, ray(Pp, V[lo], xr, yr), "pink", at=4), seg(Pp, ray(Pp, V[hi], xr, yr), "pink", at=4),
                                 pt(A, "A", "gold", 2, o("A")), pt(B, "B", "gold", 2, o("B"))]),
            "steps": [
                choice("不管 m 是多少，直線 %s 都通過？" % lineS, [P(*Pp), P(-Pp[0], Pp[1]), P(Pp[0], -Pp[1]), P(0, Pp[1])],
                       "%s = 0 時 y = %s" % (pxs, t(Pp[1])), "直線繞著 P%s 轉" % P(*Pp)),
                fill("區域是三角形，頂點是 O(0, 0)、A 和 B：", "A([0], 0)、B(0, [1])", [a(A[0]), a(B[1])], "%s = %s 和兩軸的交點" % (poly([(ca, "x"), (q, "y")]), t(s))),
                choice("繞著 P 轉，m 最大、最小的時候，直線通過 R 的哪裡？", ["R 的頂點", "R 的重心", "某條邊的中點", "R 外面的點"],
                       "R 是三角形，從 P 看過去，最邊緣的就是頂點", "最大、最小的斜率在 P 連到頂點的地方"),
                fill("P 到三個頂點的斜率：", "m_{PO} = [0]，m_{PA} = [1]，m_{PB} = [2]", [a(sl["O"]), a(sl["A"]), a(sl["B"])],
                     "、".join(hs(k) for k in "OAB")),
                fill("最小的和最大的就是範圍的兩端：", "答：[0] ≤ m ≤ [1]", [a(sl[lo]), a(sl[hi])],
                     " < ".join(t(v) for v in sorted(sl.values())))]}


# ---------- ll_minarea：最小的三角形 ----------

def ll_minarea(p, q):
    A_, B_ = 2 * p, 2 * q
    xr, yr = box([(A_, 0), (0, B_), (p, q)], pad=0.6)
    opts = [lin_eqs(q, p, 2 * p * q), lin_eqs(p, q, 2 * p * q), lin_eqs(q, p, p * q), "x + y = %d" % (p + q)]
    return {"id": "ll_minarea", "kind": "line", "tier": 3, "title": "最小的三角形", "tmul": 1.3,
            "stem": "過點 P(%d, %d) 的直線 L，和 x 軸、y 軸的正向分別交於 A(a, 0)、B(0, b)。求 △OAB 面積的最小值，以及此時 L 的方程式。" % (p, q),
            "plot": geo(xr, yr, [pt((p, q), "P", "pink"), poly_sh([(0, 0), (A_, 0), (0, B_)], "cyan", fill="cyan", alpha=0.15, at=6),
                                 pt((A_, 0), "A", "gold", 6, (6, 12)), pt((0, B_), "B", "gold", 6, (8, 0))]),
            "steps": [
                choice("x 截距 a、y 截距 b 的直線（截距式）：", ["x/a + y/b = 1", "ax + by = 1", "x/a − y/b = 1", "ax + by = ab"],
                       "代 (a, 0)、(0, b) 都要成立", "L：x/a + y/b = 1"),
                fill("P(%d, %d) 在 L 上：" % (p, q), "\\frac{[0]}{a} + \\frac{[1]}{b} = 1", [p, q], "x = %d、y = %d 代進去" % (p, q)),
                choice("a、b 都是正的，用算幾不等式：1 = %d/a + %d/b ≥ ？" % (p, q),
                       ["2√{%d/(ab)}" % (p * q), "2√{%d/(ab)}" % (p + q), "√{%d/(ab)}" % (p * q), "2√{%dab}" % (p * q)],
                       "u + v ≥ 2√{uv}，uv = (%d/a)(%d/b) = %d/(ab)" % (p, q, p * q), "1 = %d/a + %d/b ≥ 2√{%d/(ab)}" % (p, q, p * q)),
                fill("兩邊平方，再把 ab 移過去：", "1 ≥ %d/(ab) ⇒ ab ≥ [0]" % (4 * p * q), [4 * p * q], "4 × %d/(ab)" % (p * q)),
                fill("面積 = ab/2：", "△OAB 面積 ≥ [0]", [2 * p * q], "%d/2" % (4 * p * q)),
                fill("等號成立的時候 %d/a = %d/b，加起來是 1，所以各是 1/2：" % (p, q), "a = [0]，b = [1]", [A_, B_], "%d/a = 1/2、%d/b = 1/2" % (p, q)),
                choice("L 的方程式：", opts, "x/%d + y/%d = 1，兩邊乘 %d" % (A_, B_, A_ * B_ // math.gcd(A_, B_)),
                       "答：面積最小 %d，L：%s" % (2 * p * q, opts[0]))]}


def lin_eqs(a_, b_, c_):
    """ax + by = c（不移項的寫法，約分）"""
    g = math.gcd(math.gcd(a_, b_), c_)
    return poly([(a_ // g, "x"), (b_ // g, "y")]) + " = " + t(c_ // g)


def items():
    return [
        [ll_rhombus((1, 1), (5, 2), (2, 5)), ll_rhombus((0, 0), (3, 4), (5, 0), {"A": (-20, 14), "D": (6, 14)}),
         ll_rhombus((1, 1), (4, 5), (1, 6), {"A": (-20, 14), "D": (-22, -6)})],
        [ll_three(1, 2, -1, -2, 1, [(1.9, 4.2), (3.1, 1.6), (-1.2, 4.2)]),
         ll_three(-1, -2, 3, 2, 1, [(-3.0, 0.4), (-1.0, 4.2), (1.3, 4.2)]),
         ll_three(2, 1, -2, Fr(1, 2), 3, [(1.2, 4.2), (2.9, 2.2), (-3.0, 1.9)])],
        [ll_external((0, 0), (6, 8), (5, 0), [-1.2, 7.6], [-9.4, 9.2], {"A": (-22, -6), "C": (10, 4)}),
         ll_external((0, 0), (8, 6), (0, 5), [-9.4, 9.4], [-1.2, 7.6], {"A": (-20, 16), "C": (-22, -6), "D": (-8, 18)}),
         ll_external((0, 0), (-6, 8), (4, 3), [-7.2, 15.2], [-3.4, 9.4], {"A": (-20, 16), "B": (-22, -6), "D": (-8, 18)})],
        [ll_beam(1, 2, 6, (-5, -2), {"A": (6, 12), "B": (8, -8)}), ll_beam(2, 1, 4, (5, -1), {"A": (-4, 16), "B": (8, -6)}),
         ll_beam(1, 1, 4, (-4, 2), {"A": (6, 14), "B": (8, -8), "P": (-8, -10)})],
        [ll_minarea(2, 3), ll_minarea(1, 4), ll_minarea(4, 2)],
    ]
