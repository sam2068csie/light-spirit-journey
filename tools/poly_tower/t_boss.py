# 試煉大題（原本的 6 題）
from plib import *


def sg(v):
    return ("+ " + t(v)) if v >= 0 else (M + " " + t(-v))


def co1(v, s):
    """係數 × 式子：1 不寫、−1 寫 −"""
    v = F(v)
    if v == 1:
        return s
    if v == -1:
        return M + s
    if not isint(v):
        return (M if v < 0 else "") + "(" + t(abs(v)) + ")" + s
    return t(v) + s


# ---------- pb_cubic：三次函數的身分 ----------

def pb_cubic(L, ra, rb, xq, Y):
    """兩個候選：L(x − ra)^2(x − rb)、L(x − ra)(x − rb)^2；用 f(xq) 選"""
    c1 = Poly.roots([ra, ra, rb], L)
    c2 = Poly.roots([ra, rb, rb], L)
    v1, v2 = c1(xq), c2(xq)
    assert v1 != v2
    # 選第二個（重根在 rb）
    f = c2
    dbl = rb
    h = F(-f.c[2], 3 * f.c[3])
    k = f(h)
    other = (2 * h - dbl, 2 * k)
    lo, hi = sorted([F(0), other[1]])
    n = 3 if lo < Y < hi else 1
    assert Y not in (lo, hi)
    s1 = "%s%s^{2}%s" % (co1(L, ""), fac(ra), fac(rb))
    s2 = "%s%s%s^{2}" % (co1(L, ""), fac(ra), fac(rb))
    kind = "最低" if (other[1] > 0) else "最高"
    okind = "最高" if kind == "最低" else "最低"
    return item("pb_cubic", "boss", 2, "三次函數的身分", 1.7,
                "三次函數 y = f(x) 滿足：\n甲、圖形和 x 軸只交於 (%s, 0)、(%s, 0) 兩點\n乙、大域特徵近似 y = %s\n丙、f(x) 除以 %s 的餘式為 %s\n(1) 求 f(x)　(2) 求對稱中心　(3) 圖形和 y = %s 有幾個交點？" % (
                    t(ra), t(rb), cx(L, "x^{3}"), fac(xq).strip("()") if xq != 0 else "x", t(v2), t(Y)),
                [ch("三次函數只交 x 軸兩點，代表？", ["其中一個是二重根", "有一根不是實數", "兩個都是二重根", "題目矛盾"],
                    "三次有三個根（算重數），實根只出現兩個，有一個要重複", "(1)　f(x) = %s 或 %s" % (s1, s2), part="(1)"),
                 ch("用丙判斷是哪一個：", ["f(x) = %s" % s2, "f(x) = %s" % s1, "兩個都可以", "兩個都不合"],
                    "x = %s 代入：%s 是 %s，%s 是 %s" % (t(xq), s1, t(v1), s2, t(v2)),
                    "%s 在 x = %s 是 %s，%s 是 %s　→　f(x) = %s = %s" % (s1, t(xq), t(v1), s2, t(v2), s2, f.text()), part="(1)"),
                 fl("ax^{3} + bx^{2} + … 的對稱中心 x 坐標 h = −b/(3a)：", "(2)　h = −(%s)/(3 · %s) = [0]" % (t(f.c[2]), tp(L)), [a(h)],
                    "%s/%s" % (t(-f.c[2]), t(3 * L)), part="(2)"),
                 fl("k = f(h)：", "k = f(%s) = [0] ⇒ 對稱中心 (%s, k)" % (t(h), t(h)), [a(k)], "代 x = %s 進 %s" % (t(h), f.text()), part="(2)"),
                 ch("x = %s 是二重根（圖形在那裡碰 x 軸，是局部%s）。對稱過去，局部%s點是？" % (t(dbl), kind, okind),
                    uniq([P(*other)], [P(other[0], k), P(ra, 0), P(h, other[1]), P(other[0], -other[1])]),
                    "(%s, 0) 對 (%s, %s) 對稱的點是 %s" % (t(dbl), t(h), t(k), P(*other)),
                    "(3)　局部%s (%s, 0)，對稱的局部%s %s" % (kind, t(dbl), okind, P(*other)), part="(3)"),
                 ch("和 y = %s 有幾個交點？" % t(Y), uniq(["%d 個" % n], ["3 個", "1 個", "2 個", "4 個"]),
                    "%s 在局部最低 %s 和局部最高 %s %s" % (t(Y), t(lo), t(hi), "之間" if n == 3 else "外面"),
                    "答：%d 個交點" % n, part="(3)")])


# ---------- pb_power：餘式的次方 ----------

def pb_power(r1, r2):
    R1, R2 = Poly(list(reversed(r1))), Poly(list(reversed(r2)))
    G = R1 * R1 - R2
    assert G.deg() == 2 and G.lead() == 1
    prod = R1 * R2
    R3 = prod % G
    rx = (-(G - Poly([0, 0, 1]))).text()
    return item("pb_power", "boss", 3, "餘式的次方", 1.7,
                "f(x)、g(x) 的首項係數都是 1，f(x) 是三次多項式。f(x) 除以 g(x) 的餘式為 %s，[f(x)]^{2} 除以 g(x) 的餘式為 %s。\n(1) 求 g(x)　(2) [f(x)]^{3} 除以 g(x) 的餘式為 ax + b，求 (a, b)　(3) 滿足條件的 f(x) 唯一嗎？" % (R1.text(), R2.text()),
                [ch("[f(x)]^{2} 和誰除以 g(x) 的餘式相同？", ["(%s)^{2}" % R1.text(), R1.text(), "2(%s)" % R1.text(), "(%s)^{2}" % R2.text()],
                    "f(x) = g(x)Q(x) + %s，平方後除了 (%s)^{2} 都是 g(x) 的倍式" % (R1.text(), R1.text()), "(1)　[f(x)]^{2} 和 (%s)^{2} 除以 g(x) 的餘式相同" % R1.text(), part="(1)"),
                 ch("(%s)^{2} 除以 g(x) 的餘式是 %s，所以 g(x) 整除？" % (R1.text(), R2.text()), uniq([G.text()], [(R1 * R1 + R2).text(), (2 * R1 - R2).text(), (R1 * R1).text()]),
                    "(%s)^{2} − (%s) 除以 g(x) 餘 0" % (R1.text(), R2.text()), "g(x) 整除 (%s)^{2} − (%s) = %s" % (R1.text(), R2.text(), G.text()), part="(1)"),
                 ch("g(x) 是？", [G.text(), R1.text() if False else Poly([G.c[0] if G.c[0] else 1, 1]).text(), "%s 或 1" % G.text(), "(%s)^{2}" % G.text()],
                    "餘式 %s 是一次 ⇒ g 至少二次，又要整除二次式、首項係數 1" % R1.text(), "g 至少二次，又整除 %s　→　g(x) = %s" % (G.text(), G.text()), part="(1)"),
                 fl("把 x^{2} 換成 %s 降次：" % rx, "%s ⇒ [0]x + [1]" % (prod.text()), [a(R3.c[1] if R3.deg() >= 1 else 0), a(R3.c[0])],
                    "%s 裡的 x^{2} 換成 %s" % (prod.text(), rx), write="(a, b) = (%s, %s)" % (t(R3.c[1] if R3.deg() >= 1 else 0), t(R3.c[0])), part="(2)",
                    pre="(2)　[f(x)]^{3} 和 (%s)(%s) = %s 除以 g(x) 的餘式相同" % (R1.text(), R2.text(), prod.text())),
                 ch("c 可以是任何數嗎？所以 f(x)？", ["不唯一：c 任意", "唯一：c = 0", "唯一：c = 2", "不存在"],
                    "首項係數 1 的三次式除以 %s，商式是 x + c" % G.text(), "c 任意 ⇒ f(x) 不唯一", part="(3)",
                    pre="(3)　f(x) = (%s)(x + c) + %s（首項係數 1，商式是 x + c）" % (G.text(), R1.text()))])


# ---------- pb_shiftfit：平移後的近似直線 ----------

def pb_shiftfit(A, B, s, m, n):
    """f = Ax^3 + Bx^2 + cx + d；g(x) = f(x − s)；g 在 x = s 附近 ≈ mx + n"""
    c, d = m, n + m * s
    f = Poly([d, c, B, A])
    h = F(-B, 3 * A)
    k = f(h)
    dirw = ("向右" if s > 0 else "向左") + "平移 %d 單位" % abs(s)
    gx = "f(x − %d)" % s if s > 0 else "f(x + %d)" % (-s)
    return item("pb_shiftfit", "boss", 2, "平移後的近似直線", 1.7,
                "f(x) = %s。y = g(x) 是把 y = f(x) %s得到的。\n(1) 求 y = f(x) 對稱中心的 x 坐標　(2) y = g(x) 在 x = %d 附近的一次近似是 y = %s，求 (c, d)　(3) 求 y = g(x) 的對稱中心" % (
                    poly([(A, "x^{3}"), (B, "x^{2}"), (1, "cx"), (1, "d")]), dirw, s, poly([(m, "x"), (n, "")])),
                [ch("y = f(x) 對稱中心的 x 坐標 h = ？", uniq([t(h)], [t(-h), t(3 * h), t(h - 1), t(h + 1), t(2 * h), t(h + 2), t(h - 2)]), "h = −b/(3a) = −(%s)/%s" % (t(B), t(3 * A)),
                    "(1)　h = %s" % t(h), part="(1)"),
                 ch("g(x) = %s。g 在 x = %d 附近，對應 f 在哪裡附近？" % (gx, s), uniq(["x = 0"], ["x = %d" % (2 * s), "x = %d" % s, "x = %d" % (-s)]),
                    "x %s = 0" % sg(-s), "(2)　g 在 x = %d 附近 ↔ f 在 x = 0 附近：f(x) ≈ cx + d" % s, part="(2)"),
                 ch("所以 g(x) 在 x = %d 附近 ≈ ？" % s, ["c%s + d" % fac(s), "cx + d", "c%s + d" % fac(-s), "d%s + c" % fac(s)],
                    "把 f 的近似 cx + d 裡的 x 換成 %s" % fac(s).strip("()"), "g(x) ≈ c%s + d = cx + (d %s)" % (fac(s), _dc(s)), part="(2)"),
                 fl("和 y = %s 比較：" % poly([(m, "x"), (n, "")]), "c = %s，d %s = %s　→　(c, d) = ([0], [1])" % (t(m), _dc(s), t(n)),
                    [a(c), a(d)], "d = %s %s" % (t(n), ("+ %d · %s" % (s, tp(m))) if s > 0 else ("− %d · %s" % (-s, tp(m)))), part="(2)"),
                 ch("y = g(x) 的對稱中心？", uniq([P(h + s, k)], [P(h - s, k), P(h + s, k + 1), P(h, k), P(h + s, -k)]),
                    "f 的對稱中心 (%s, f(%s)) %s" % (t(h), t(h), dirw.replace("平移", "移")), "(3)　f(%s) = %s，%s　→　%s" % (t(h), t(k), dirw, P(h + s, k)), part="(3)")])


def _dc(s):
    """d − 2c、d + c"""
    return ("− " if s > 0 else "+ ") + ("" if abs(s) == 1 else str(abs(s))) + "c"


# ---------- pb_solset：由解集合還原函數 ----------

def pb_solset(m, r, tt):
    a2 = F(m * m, 4 * (tt - r * r))
    a_ = -rt(a2).c
    assert rt(a2).n == 1 and a_ < 0
    f = Poly([-a_ * r * r, m, a_])
    hx = F(-m, 2 * a_)
    mx = f(hx)
    return item("pb_solset", "boss", 3, "由解集合還原函數", 1.7,
                "二次函數 f(x) = ax^{2} + bx + c。已知 f(x) > %s 的解為 −%d < x < %d，且方程式 f(x) + %sa = 0 有兩相等實根。\n(1) 用 a 表示 f(x)　(2) 求 a　(3) 求 f(x) 的最大值" % (
                    cx(m), r, r, t(tt) if tt != 1 else ""),
                [ch("f(x) − %s > 0 的解是 −%d < x < %d（在兩根之間），所以 f(x) − %s = ？" % (cx(m), r, r, cx(m)),
                    ["a%s%s，a < 0" % (fac(-r), fac(r)), "a%s%s，a > 0" % (fac(-r), fac(r)), "a%s%s + %s" % (fac(-r), fac(r), cx(m)), "%s%s" % (fac(-r), fac(r))],
                    "> 0 的解夾在兩根中間 ⇒ 開口向下", "(1)　f(x) − %s = a(x^{2} − %d)，a < 0　→　f(x) = ax^{2} + %s − %sa" % (cx(m), r * r, cx(m), t(r * r) if r != 1 else ""), part="(1)"),
                 ch("f(x) + %sa = ax^{2} + %s + %sa = 0 有兩相等實根：" % (t(tt), cx(m), t(tt - r * r) if tt - r * r != 1 else ""),
                    uniq(["%d − %sa^{2} = 0" % (m * m, t(4 * (tt - r * r)))], ["%d + %sa^{2} = 0" % (m * m, t(4 * (tt - r * r))), "%d − %sa = 0" % (m * m, t(4 * (tt - r * r))), "%d − %sa^{2} = 0" % (m, t(4 * (tt - r * r)))]),
                    "判別式 %s^{2} − 4 · a · %sa" % (t(m), t(tt - r * r) if tt - r * r != 1 else ""), "(2)　判別式 %d − %sa^{2} = 0" % (m * m, t(4 * (tt - r * r))), part="(2)"),
                 step("roots", part="(2)", q="a 的兩個解，哪個不合？劃掉它。", cands=[{"v": "a = %s" % t(a_), "ok": True, "why": "a < 0 ✓"}, {"v": "a = %s" % t(-a_), "ok": False, "why": "(1) 要求 a < 0"}],
                      write="a = %s（a = %s 不合）" % (t(a_), t(-a_))),
                 ch("f(x) = %s，配方：" % f.text(), uniq(["%s%s^{2} + %s" % (co1(a_, ""), fac(hx), t(mx))],
                                                     ["%s%s^{2} + %s" % (co1(a_, ""), fac(hx), t(f(0))), "%s%s^{2} + %s" % (co1(a_, ""), fac(-hx), t(mx)), "%s%s^{2} + %s" % (co1(a_, ""), fac(hx + 1), t(mx))]),
                    "提出 %s 再配方" % t(a_), "(3)　f(x) = %s%s^{2} + %s" % (co1(a_, ""), fac(hx), t(mx)), part="(3)"),
                 fl("f(x) 的最大值？", "答：x = %s 時最大值 [0]" % t(hx), [a(mx)], "開口向下，頂點最高", part="(3)")])


# ---------- pb_recip：倒數的多項式 ----------

def pb_recip(n):
    fact = math.factorial(n)
    prod0 = (-1) ** n * fact
    c = F(-1, prod0)
    g_next = c * fact
    f_next = (g_next + 1) / (n + 1)
    return item("pb_recip", "boss", 3, "倒數的多項式", 1.65,
                "f(x) 是 %d 次多項式，且 f(k) = 1/k，k = 1、2、3、…、%d。\n(1) 令 g(x) = x f(x) − 1，寫出 g(x)　(2) 求 g(x) 的首項係數　(3) 求 f(%d)" % (n - 1, n, n + 1),
                [ch("g(x) = x f(x) − 1 是幾次式？有哪些根？", ["%d 次，根是 1、2、…、%d" % (n, n), "%d 次，根是 1、2、…、%d" % (n - 1, n - 1), "%d 次，根是 0、1、…、%d" % (n, n - 1),
                                                         "%d 次，根是 1、2、…、%d" % (n - 1, n)],
                    "x f(x) 比 f(x) 多一次，k f(k) − 1 = 1 − 1 = 0", "(1)　g(k) = k · (1/k) − 1 = 0（k = 1～%d）　→　g(x) = c(x − 1)(x − 2)…(x − %d)" % (n, n), part="(1)"),
                 ch("代哪個 x 最容易求 c？", ["x = 0：g(0) = −1", "x = 1：g(1) = 0", "x = %d" % (n + 1), "x = −1"],
                    "x f(x) 在 x = 0 時是 0，不用知道 f(0)", "(2)　g(0) = 0 · f(0) − 1 = −1", part="(2)"),
                 fl("x = 0 代進 c(x − 1)(x − 2)…(x − %d)：%d 個負數相乘。" % (n, n), "(−1)(−2)…(−%d) = [0]" % n, [a(prod0)],
                    "%s(1 × 2 × … × %d)" % ("−" if n % 2 else "", n), part="(2)"),
                 fl("所以 −1 = %sc：" % t(prod0), "c = [0]", [a(c)], "兩邊除以 %s" % t(prod0), part="(2)"),
                 fl("x = %d 代入：g(%d) = c · %d · %d · … · 1 = %dc。" % (n + 1, n + 1, n, n - 1, fact), "(3)　g(%d) = [0]" % (n + 1), [a(g_next)],
                    "%d × %s" % (fact, tp(c)), part="(3)"),
                 fl("g(%d) = %df(%d) − 1：" % (n + 1, n + 1, n + 1), "%df(%d) − 1 = %s ⇒ f(%d) = [0]" % (n + 1, n + 1, t(g_next), n + 1), [a(f_next)],
                    "%df(%d) = %s" % (n + 1, n + 1, t(g_next + 1)), part="(3)")])


# ---------- pb_garden：花圃的圍籬 ----------

def pb_garden(w, Lf, rlo, rhi):
    S = F(Lf + w, 2)
    assert isint(S)
    x_lo = S * rlo / (1 + rlo)
    x_hi = S * rhi / (1 + rhi)
    assert isint(x_lo) and isint(x_hi)
    hS = S / 2
    assert x_lo <= hS <= x_hi
    Mx = hS * hS
    mn = min(x_lo * (S - x_lo), x_hi * (S - x_hi))
    assert x_lo * (S - x_lo) == x_hi * (S - x_hi)
    return item("pb_garden", "boss", 2, "花圃的圍籬", 1.7,
                "光靈要圍一塊長方形花圃 ABCD：\\ol{AB} 這一邊正中間留 %d 公尺的出入口，其他部分用 %d 公尺長的竹籬圍起來，並且要 %s ≤ \\frac{\\ol{DC}}{\\ol{CB}} ≤ %s。\n設 \\ol{AB} = x、\\ol{CB} = y（公尺）。\n(1) 求 x + y　(2) 求 x 的範圍　(3) 面積的最大值 M、最小值 m" % (
                    w, Lf, t(rlo), t(rhi)),
                [fl("竹籬的長度（\\ol{AB} 扣掉出入口）：", "(1)　(x − %d) + x + 2y = %d　→　x + y = [0]" % (w, Lf), [a(S)], "2x + 2y = %d" % (Lf + w), part="(1)"),
                 fl("左邊：x/(%s − x) ≥ %s，兩邊乘 %s − x（正的）：" % (t(S), t(rlo), t(S)), "x ≥ %s(%s − x) ⇒ x ≥ [0]" % (t(rlo), t(S)), [a(x_lo)],
                    "%s ≥ %s" % (cx(1 + rlo), t(S * rlo)), part="(2)", pre="(2)　\\ol{DC} = x、y = %s − x：%s ≤ x/(%s − x) ≤ %s" % (t(S), t(rlo), t(S), t(rhi))),
                 fl("右邊：x/(%s − x) ≤ %s：" % (t(S), t(rhi)), "x ≤ %s(%s − x) ⇒ x ≤ [0]" % (t(rhi), t(S)), [a(x_hi)], "%s ≤ %s" % (cx(1 + rhi), t(S * rhi)),
                    write="%s ≤ x ≤ %s" % (t(x_lo), t(x_hi)), part="(2)"),
                 ch("面積 S = x(%s − x)，配方：" % t(S), uniq(["−(x − %s)^{2} + %s" % (t(hS), t(Mx))], ["−(x − %s)^{2} + %s" % (t(hS), t(S)), "(x − %s)^{2} − %s" % (t(hS), t(Mx)),
                                                                                         "−(x − %s)^{2} + %s" % (t(S), t(S * S))]),
                    "−(x^{2} − %sx) = −(x − %s)^{2} + %s" % (t(S), t(hS), t(Mx)), "(3)　S = −(x − %s)^{2} + %s" % (t(hS), t(Mx)), part="(3)"),
                 fl("頂點 x = %s 在 %s ≤ x ≤ %s 裡：" % (t(hS), t(x_lo), t(x_hi)), "M = [0]", [a(Mx)], "開口向下，頂點最高", part="(3)"),
                 fl("兩端 x = %s、%s 離 %s 一樣遠，都是最小：" % (t(x_lo), t(x_hi), t(hS)), "答：m = %s × %s = [0]" % (t(x_lo), t(S - x_lo)), [a(mn)],
                    "%s × %s" % (t(x_lo), t(S - x_lo)), part="(3)")])


def items():
    return [
        [pb_cubic(2, -1, 2, 1, 7), pb_cubic(-1, 1, -2, 0, 1), pb_cubic(1, 3, 0, 1, -5)],
        [pb_power((1, 2), (3, 1)), pb_power((1, -1), (2, 3)), pb_power((1, 3), (-1, 2))],
        [pb_shiftfit(2, 3, 1, -4, 5), pb_shiftfit(1, -3, 2, 3, -1), pb_shiftfit(-1, 6, -1, 2, 7)],
        [pb_solset(3, 1, 2), pb_solset(4, 1, 5), pb_solset(2, 2, 8)],
        [pb_recip(7), pb_recip(6), pb_recip(5)],
        [pb_garden(3, 45, F(1, 2), 2), pb_garden(2, 34, F(1, 2), 2), pb_garden(2, 46, F(1, 3), 3)],
    ]
