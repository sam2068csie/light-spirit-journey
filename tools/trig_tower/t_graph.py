# 波形辨識
from tlib import *

sin, cos = math.sin, math.cos


def kx(k, v="x"):
    """2x、x/2、x"""
    k = F(k)
    if k == 1:
        return v
    if isint(k):
        return "%d%s" % (k.numerator, v)
    assert k.numerator == 1
    return "%s/%d" % (v, k.denominator)


def kxp(k, inner):
    """k(x + h)：2(x + h)、(x + h)/2"""
    k = F(k)
    if isint(k):
        return "%d(%s)" % (k.numerator, inner)
    return "(%s)/%d" % (inner, k.denominator)


def addpi(k):
    """ + π/6、 − π/4（角加在後面）"""
    k = F(k)
    if k == 0:
        return ""
    return (" + " if k > 0 else " − ") + pt_(abs(k))


def addn(v):
    v = F(v)
    if v == 0:
        return ""
    return (" + " if v > 0 else " − ") + t(abs(v))


def gf(k):
    """Godot 式子裡的數"""
    return repr(float(k))


def ang(k):
    """Godot 式子裡的角（π 的倍數）"""
    return "%s*PI" % gf(k)


# ---------- tg_read：看圖寫式子 ----------

def tg_read(A, b, c, d, xr, pi_n, pi_lab):
    b, c = F(b), F(c)
    xM = (F(1, 2) - c) / b
    T = 2 / b
    xm = xM + T / 2
    Mx, mn = A + d, d - A
    assert 0 < xM and 0 <= c < 2
    f = lambda x: A * sin(float(b) * x + float(c) * PI) + d
    assert near(f(float(xM) * PI), Mx) and near(f(float(xm) * PI), mn)
    assert xr[0] < 0 and float(xm) * PI < xr[1]
    return item("tg_read", "graph", 1, "看圖寫式子", 1.1,
                "圖是 y = a sin(bx + c) + d 的一段（a > 0、b > 0、0 ≤ c < 2π），最高點 (%s, %d)，相鄰的最低點 (%s, %s)。求 a、b、c、d。" % (pt_(xM), Mx, pt_(xm), t(mn)),
                [fl("振幅是最高和最低差的一半，中線是兩者的平均：", "a = (%d − %s)/2 = [0]，d = (%d + %s)/2 = [1]" % (Mx, tp(mn), Mx, tp(mn)), [a(A), a(d)],
                    "%d/2、%s/2" % (Mx - mn, t(Mx + mn))),
                 fl("最高點到相鄰的最低點，是半個週期：", "T/2 = %s − %s = [0]π" % (pt_(xm), pt_(xM)), [a(T / 2)], "兩個 x 坐標相減"),
                 fl("所以週期 T = %s：" % pt_(T), "b = 2π/T = [0]", [a(b)], "2π/%s" % ptp(T) if T == 1 else "2π 除以 %s" % pt_(T)),
                 fl("最高點的時候 bx + c = π/2：", "%s · %s + c = π/2 ⇒ c = [0]π" % (t(b), pt_(xM)), [a(c)], "π/2 − %s" % pt_(b * xM))],
                plot={"x": xr, "y": [mn - 0.8, Mx + 0.8], "pi": pi_n, "pi_lab": pi_lab,
                      "curves": [{"f": "%d*sin(%s*x+%s)%s" % (A, gf(b), ang(c), ("+%d" % d) if d >= 0 else str(d)), "c": "cyan"}],
                      "pts": [{"x": fx(float(xM) * PI), "y": Mx, "label": "(%s, %d)" % (pt_(xM), Mx)},
                              {"x": fx(float(xm) * PI), "y": mn, "label": "(%s, %s)" % (pt_(xm), t(mn)), "off": [-60, 20]}]})


# ---------- tg_pick：認出那條波 ----------

def tg_pick(A, h):
    """y = A sin(x − h)：h > 0 右移、h < 0 左移"""
    h = F(h)
    hs = pt_(abs(h))
    inside = "x %s %s" % ("−" if h > 0 else "+", hs)
    yr = (-A - 1.0, A + 1.0)
    G = lambda s: gsm(s, "%d*sin(x)" % A, yr=yr)
    sh = lambda hh: "%s*x-%s" % ("", ang(hh))
    k = Q.of(A) * sv(-h)
    chk(k.ans(), A * sin(-float(h) * PI))
    dirw, dirr = ("右", "左") if h > 0 else ("左", "右")
    return item("tg_pick", "graph", 1, "認出那條波", 1.0,
                "(1) 哪一張的實線是 y = %d sin(%s)？（虛線是 y = %d sin x）\n(2) 它和 y 軸交於 (0, k)，求 k" % (A, inside, A),
                [pick("哪一張的實線是 y = %d sin(%s)？" % (A, inside),
                      [G("%d*sin(x-%s)" % (A, ang(h))), G("%d*sin(x+%s)" % (A, ang(h))), G("%d*sin(2*x-%s)" % (A, ang(h))),
                       G("%d*sin(x-%s)" % (-A, ang(h))), G("sin(x-%s)" % ang(h))],
                      ["", "這是往%s移 %s" % (dirr, hs), "週期變成 π 了", "上下翻轉了", "振幅只有 1"],
                      "%s：整條波往%s移 %s，振幅還是 %d" % (inside, dirw, hs, A),
                      "y = %d sin(%s)：往%s移 %s，振幅 %d" % (A, inside, dirw, hs, A)),
                 fl("(2) x = 0 代入：", "k = %d sin(%s) = [0]" % (A, pt_(-h)), [k.ans()], "sin(%s) = %s" % (pt_(-h), sv(-h).text()))])


# ---------- tg_steps：四個步驟 ----------

def tg_steps(A, k, ph, B):
    k, ph = F(k), F(ph)
    c = 1 / k
    hh = ph / k
    f = lambda x: A * sin(float(k) * x + float(ph) * PI) + B
    g = lambda x: A * sin(float(k) * (x + float(hh) * PI)) + B
    assert all(near(f(x), g(x)) for x in (0.1, 0.7, 2.3))
    eq = "y = %d sin(%s + %s)%s" % (A, kx(k), pt_(ph), addn(B))
    up = "向上平移 %s 就是往下 %d" % (t(B), -B) if B < 0 else "向上平移 %d" % B
    sin_k = ("sin %s" % kx(k)) if isint(k) else ("sin(%s)" % kx(k))
    sin_kh = ("sin %s" % kxp(k, "x + h")) if isint(k) else ("sin(%s)" % kxp(k, "x + h"))
    return item("tg_steps", "graph", 2, "四個步驟", 1.25,
                "y = sin x 依序 ① 鉛直伸縮 a 倍 ② 向左平移 b ③ 水平伸縮 c 倍 ④ 向上平移 d，得到 %s。\n(1) 求 a、b、c、d　(2) 若 ②、③ 對調，要向左平移多少？" % eq,
                [fl("鉛直伸縮管 sin 前面的倍數，上下平移管後面加的數：", "a = [0]，d = [1]", [a(A), a(B)], up, part="(1)"),
                 ch("② 之後是 sin(x + b)，③ 再水平伸縮 c 倍，變成？", ["sin(x/c + b)", "sin(cx + b)", "sin(c(x + b))", "sin(x/c + b/c)"],
                    "水平伸縮 c 倍：x 換成 x/c，其他不動", "sin(x + b) → sin(x/c + b) = sin(%s + %s)" % (kx(k), pt_(ph)), part="(1)"),
                 fl("對照 sin(%s + %s)：" % (kx(k), pt_(ph)), "1/c = %s ⇒ c = [0]，b = [1]π" % t(k), [a(c), a(ph)], "x 的係數對 x 的係數、常數對常數",
                    part="(1)"),
                 fl("要等於 sin(%s + %s)：" % (kx(k), pt_(ph)), "%s = %s ⇒ h = [0]π" % (kx(k, "h"), pt_(ph)), [a(hh)],
                    "%s 除以 %s" % (pt_(ph), t(k)) if isint(k) else "%s 乘 %d" % (pt_(ph), k.denominator), part="(2)",
                    pre="(2)　先水平伸縮：%s，再左移 h：%s = sin(%s + %s)" % (sin_k, sin_kh, kx(k), kx(k, "h")))])


# ---------- tg_cond：從條件找波形 ----------

def tg_cond(T, L, Mx):
    """f(0) = f(p) = f(T) = L，p = T/3；最大值 Mx"""
    assert T % 3 == 0
    p = T // 3
    b = F(2, T)                    # b = bπ
    xM, xm = F(p, 2), F(p + T, 2)
    c = F(1, 2) - b * xM
    assert c == F(1, 6)
    A = 2 * (Mx - L)
    d = Mx - A
    f = lambda x: A * sin(float(b) * PI * x + PI / 6) + d
    assert all(near(f(x), L) for x in (0, p, T))
    assert all(f(x) > L for x in (p * 0.2, p * 0.5, p * 0.8)) and all(f(x) < L for x in (p + 0.1, (p + T) / 2, T - 0.1))
    return item("tg_cond", "graph", 2, "從條件找波形", 1.3,
                "f(x) = a sin(bx + c) + d（a > 0、b > 0、0 ≤ c < 2π），已知：\n① f(0) = f(%d) = f(%d) = %s　② 0 < x < %d 時 f(x) > %s\n③ %d < x < %d 時 f(x) < %s　④ f 的最大值是 %d。求 a、b、c、d。"
                % (p, T, t(L), p, t(L), p, T, t(L), Mx),
                [fl("從 0 開始，大於 %s、小於 %s，到 %d 又回到 %s：剛好一個週期。" % (t(L), t(L), T, t(L)), "T = [0]，b = 2π/T = [1]π", [str(T), a(b)],
                    "0 到 %d 走完「上去、下來」一整輪" % T),
                 fl("0 到 %d 這一段在上面，最高點在正中間，%d 到 %d 在下面，最低點也在正中間。" % (p, p, T), "最高點 x = [0]，最低點 x = [1]", [a(xM), a(xm)],
                    "兩段的中點"),
                 fl("最高點時 bx + c = π/2：", "%s · %s + c = π/2 ⇒ c = [0]π" % (pt_(b), t(xM)), [a(c)], "π/2 − %s" % pt_(b * xM)),
                 fl("f(0) = %s：" % t(L), "a sin(π/6) + d = %s ⇒ [0]a + d = %s" % (t(L), t(L)), ["1/2"], "sin(π/6) = 1/2"),
                 fl("最大值 a + d = %d，和上一行聯立：" % Mx, "答：a = [0]，d = [1]", [a(A), a(d)], "兩式相減：a/2 = %s" % t(Mx - L))],
                plot={"x": [-1.0, T + 1.0], "y": [d - A - 1.0, Mx + 1.5],
                      "curves": [{"f": "%d*sin(%s*PI*x+PI/6)%s" % (A, gf(b), ("+%d" % d) if d >= 0 else str(d)), "c": "cyan", "at": 4},
                                 {"f": str(L), "c": "faint", "dash": True}],
                      "pts": [{"x": 0, "y": L, "label": ""}, {"x": p, "y": L, "label": ""}, {"x": T, "y": L, "label": ""},
                              {"x": fx(xM), "y": Mx, "label": "(%s, %d)" % (t(xM), Mx), "at": 2}]})


# ---------- tg_tri：波上的正三角形 ----------

def tg_tri(aq):
    """y = a sin(bx)，a = aq（Q）"""
    T = aq * 4 / Q(0, 1, 3)
    assert T.rat()
    T = T.a
    b = 2 / T
    x0 = T / 4
    C = (x0 + T / 2, -aq)
    av = float(aq)
    f = lambda x: av * sin(float(b) * PI * x)
    assert near(f(float(x0)), av) and near(f(float(C[0])), -av)
    side = float(T)
    assert near(2 * av, S3 / 2 * side)
    xr = [-0.15 * side, float(x0 + T) + 0.3 * side]
    return item("tg_tri", "graph", 3, "波上的正三角形", 1.35,
                "y = a sin(bx)（a > 0、b > 0）的圖形上，A(%s, %s) 是一個最高點，A 和下一個最高點 B、以及它們之間的最低點 C 剛好是正三角形。\n求 a、b 與 C 的坐標。"
                % (t(x0), aq.text()),
                [ch("設週期 T。△ABC 的邊長、高各是？", ["邊長 T，高 2a", "邊長 T/2，高 a", "邊長 T，高 a", "邊長 2T，高 2a"],
                    "相鄰兩個最高點差一個週期，最高到最低的落差是 2a", "\\ol{AB} = T，高 = 2a"),
                 fl("A 是最高點：", "a = [0]", [aq.ans()], "最高點的 y 坐標就是 a"),
                 fl("正三角形的高 = (√{3}/2) × 邊長：", "%s = (√{3}/2)T ⇒ T = [0]" % (aq * 2).text(), [a(T)], "兩邊同除以 √{3}/2"),
                 fl("週期 T = %s：" % t(T), "b = 2π/T = [0]π", [a(b)], "2π/%s" % t(T)),
                 fl("B 的 x 坐標是 %s + T = %s。C 在 A、B 的正中間，是最低點：" % (t(x0), t(x0 + T)), "答：C([0], [1])", [a(C[0]), (-aq).ans()],
                    "x 取中點，y 是最小值 −a")],
                plot={"x": [fx(xr[0]), fx(xr[1])], "y": [fx(-av * 1.4), fx(av * 1.4)],
                      "curves": [{"f": "%s*sin(%s*PI*x)" % (repr(av), gf(b)), "c": "cyan"}],
                      "shapes": [{"k": "poly", "pts": [[fx(x0), fx(av)], [fx(x0 + T), fx(av)], [fx(C[0]), fx(-av)]], "c": "gold", "fill": "gold", "alpha": 0.12, "at": 1}],
                      "pts": [{"x": fx(x0), "y": fx(av), "label": "A"}, {"x": fx(x0 + T), "y": fx(av), "label": "B", "at": 3},
                              {"x": fx(C[0]), "y": fx(-av), "label": "C", "at": 5}]})


# ---------- tg_squeeze：壓縮後的波 ----------

def tg_squeeze(k, ph):
    k, ph = F(k), F(ph)
    yr = (-1.6, 1.6)
    G = lambda s: gsm(s, "sin(x)", yr=yr)
    sh = ph / k
    xM = (F(1, 2) - ph) / k
    while xM <= 0:
        xM += 2 / k
    f = lambda x: sin(float(k) * x + float(ph) * PI)
    assert near(f(float(xM) * PI), 1)
    dirw, dirr = ("左", "右") if ph > 0 else ("右", "左")
    expr = "sin(%s%s)" % (kx(k), addpi(ph))
    T = 2 / k
    return item("tg_squeeze", "graph", 2, "壓縮後的波", 1.1,
                "(1) 哪一張的實線是 y = %s？（虛線是 y = sin x）\n(2) x > 0 的第一個最高點，x 坐標是多少？" % expr,
                [pick("哪一張的實線是 y = %s？" % expr,
                      [G("sin(%s*x+%s)" % (gf(k), ang(ph))), G("sin(%s*(x+%s))" % (gf(k), ang(ph))), G("sin(x/%s+%s)" % (gf(k), ang(ph))),
                       G("sin(%s*x-%s)" % (gf(k), ang(ph))), G("sin(x+%s)" % ang(ph))],
                      ["", "這是 sin %s(x%s)：%s移太多了" % (t(k), addpi(ph), dirw), "週期變成 %s 了" % pt_(2 * k), "這是往%s移" % dirr, "週期還是 2π"],
                      "%s = sin %s(x%s)：週期 %s，往%s移 %s" % (expr, t(k), addpi(sh), pt_(T), dirw, pt_(abs(sh))),
                      "%s = sin %s(x%s)：週期 %s，%s移 %s" % (expr, t(k), addpi(sh), pt_(T), dirw, pt_(abs(sh)))),
                 fl("(2) 最高點時 %s%s = π/2：" % (kx(k), addpi(ph)), "x = [0]π", [a(xM)],
                    "%s = %s" % (kx(k), pt_(F(1, 2) - ph)) if xM == (F(1, 2) - ph) / k else "π/2 − (%s) 是負的，再加一個週期" % pt_(ph))])


# ---------- tg_center：對稱中心定參數 ----------

def tg_center(A, ph, X0, B, lo, hi):
    """f = A sin(ax − φπ) + B 對稱於 (X0π, B)，lo π < T < hi π"""
    ph, X0, lo, hi = F(ph), F(X0), F(lo), F(hi)
    alo, ahi = 2 / hi, 2 / lo
    cands = []
    for k in range(-5, 10):
        av = (k + ph) / X0
        if alo < av < ahi:
            cands.append((k, av))
    assert len(cands) == 1, cands
    k, av = cands[0]
    f = lambda x: A * sin(float(av) * x - float(ph) * PI) + B
    xc = float(X0) * PI
    assert all(near(f(xc + d) + f(xc - d), 2 * B) for d in (0.3, 0.9))
    m = 1 / X0
    assert isint(m)
    m = int(m)
    return item("tg_center", "graph", 3, "對稱中心定參數", 1.35,
                "f(x) = %d sin(ax − %s)%s，a > 0，週期 T 滿足 %s < T < %s，且 y = f(x) 的圖形對稱於點 (%s, %s)。求 a、b。"
                % (A, pt_(ph), " + b", pt_(lo), pt_(hi), pt_(X0), t(B)),
                [fl("對稱中心一定在中線 y = b 上：", "b = [0]", [a(B)], "對稱中心的 y 坐標"),
                 fl("對稱中心的地方 sin 那一項是 0：a · %s − %s = kπ（k 是整數）。" % (pt_(X0), pt_(ph)),
                    "a · %s = kπ + %s ⇒ a = %sk + [0]" % (pt_(X0), pt_(ph), "" if m == 1 else str(m)), [a(ph * m)], "兩邊乘 %d/π" % m),
                 fl("週期 T = 2π/a：%s < 2π/a < %s，兩邊除以 2π：" % (pt_(lo), pt_(hi)), "%s < 1/a < [0]" % t(lo / 2), [a(hi / 2)],
                    ("%s/(2π)" if isint(hi) else "(%s)/(2π)") % pt_(hi)),
                 fl("取倒數，不等號反過來：", "[0] < a < [1]", [a(alo), a(ahi)], "1/(%s)、1/(%s)" % (t(hi / 2), t(lo / 2))),
                 fl("%dk + %s 落在 %s 和 %s 之間，k 只能是 %d：" % (m, t(ph * m), t(alo), t(ahi), k), "答：a = [0]，b = %s" % t(B), [a(av)],
                    "%d · %d + %s" % (m, k, t(ph * m)))])


# ---------- tg_overlap：移到重合 ----------

def tg_overlap(k, ph, xr, pi_n, pi_lab):
    """sin(kx + φπ) 右移 h 和 cos kx 重合"""
    k, ph = F(k), F(ph)
    c0 = F(1, 2) - ph                     # −kh = c0 + 2mπ
    base = -c0 / k
    stepm = 2 / k
    m = 0
    h = base
    while h <= 0:
        m -= 1
        h = base - stepm * m
    g = lambda x: sin(float(k) * (x - float(h) * PI) + float(ph) * PI)
    assert all(near(g(x), cos(float(k) * x)) for x in (0.1, 0.8, 1.9))
    hh = h - stepm
    assert hh <= 0
    return item("tg_overlap", "graph", 2, "移到重合", 1.2,
                "y = sin(%s + %s) 的圖形向右平移 h（h > 0）後，和 y = cos %s 的圖形重合。求 h 的最小值。" % (kx(k), pt_(ph), kx(k)),
                [ch("cos %s 先寫成 sin：" % kx(k), ["sin(%s + π/2)" % kx(k), "sin(%s − π/2)" % kx(k), "sin(%s + π)" % kx(k), "−sin %s" % kx(k)],
                    "cos θ = sin(θ + π/2)", "cos %s = sin(%s + π/2)" % (kx(k), kx(k))),
                 fl("兩邊括號裡的角差 2π 的整數倍（k 是整數）：",
                    "%s − %s + %s = %s + π/2 + 2kπ ⇒ −%s = [0]π + 2kπ" % (kx(k), kx(k, "h"), pt_(ph), kx(k), kx(k, "h")), [a(c0)],
                    "π/2 − %s" % pt_(ph), pre="右移 h：sin(%s + %s) = sin(%s + π/2)" % (kxp(k, "x − h"), pt_(ph), kx(k))),
                 fl("兩邊除以 −%s：" % t(k), "h = %s − [0]kπ" % pt_(base), [a(stepm)], "2kπ/%s" % t(k)),
                 fl("k 取 %d，h 是最小的正數：" % m, "答：h = %s + %s = [0]π" % (pt_(base), pt_(-stepm * m)), [a(h)],
                    "%s + %s" % (t(base), t(-stepm * m)))],
                plot={"x": xr, "y": [-1.5, 1.5], "pi": pi_n, "pi_lab": pi_lab,
                      "curves": [{"f": "cos(%s*x)" % gf(k), "c": "dim", "dash": True}, {"f": "sin(%s*x+%s)" % (gf(k), ang(ph)), "c": "cyan", "until": 4},
                                 {"f": "sin(%s*(x-%s)+%s)" % (gf(k), ang(h), ang(ph)), "c": "pink", "at": 4}]})


def items():
    return [
        [tg_read(3, 2, F(1, 6), 2, [-0.4, 3.4], 6, 6), tg_read(2, 3, F(1, 4), 1, [-0.3, 2.0], 12, 4),
         tg_read(4, F(1, 2), F(1, 3), -1, [-0.8, 8.4], 3, 3)],
        [tg_pick(2, F(1, 4)), tg_pick(2, F(1, 3)), tg_pick(2, F(-1, 3))],
        [tg_steps(3, 2, F(1, 2), -1), tg_steps(2, 3, F(1, 2), 1), tg_steps(4, F(1, 2), F(1, 6), 2)],
        [tg_cond(12, 1, 5), tg_cond(6, 2, 6), tg_cond(18, 0, 4)],
        [tg_tri(Q(0, 1, 3)), tg_tri(Q(0, 2, 3)), tg_tri(Q(0, F(1, 2), 3))],
        [tg_squeeze(2, F(1, 3)), tg_squeeze(3, F(1, 6)), tg_squeeze(2, F(-1, 4))],
        [tg_center(2, F(1, 3), F(1, 2), -1, F(2, 3), 1), tg_center(3, F(1, 4), F(1, 2), 2, F(2, 5), F(1, 2)),
         tg_center(2, F(1, 6), F(1, 3), -3, F(1, 2), 1)],
        [tg_overlap(3, F(1, 4), [-0.3, 3.4], 12, 4), tg_overlap(3, F(1, 3), [-0.3, 3.4], 18, 6), tg_overlap(4, F(1, 6), [-0.3, 2.6], 12, 4)],
    ]
