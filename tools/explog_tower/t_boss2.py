# 試煉大題（新加的 6 題：難度 2 四題、難度 3 兩題）
from elib import *


def pw(b, e):
    """b^e 的值（e 整數，可負）"""
    return F(b) ** e


# ---------- b_logsys：對數聯立 ----------

def b_logsys(b, S, D):
    u, v = F(S + D, 2), F(S - D, 2)
    assert isint(u) and isint(v) and u != 0 and v != 0
    u, v = int(u), int(v)
    x, y = pw(b, u), pw(b, v)
    r3 = F(v, u)
    r4 = F(S, v)
    assert abs(lg(float(x), float(y)) - float(r3)) < 1e-9 and abs(lg(float(y), float(x * y)) - float(r4)) < 1e-9
    lb = "log_{%d}" % b
    return item("b_logsys", "boss", 2, "對數聯立", 1.6,
                "x、y 是正數，%s x + %s y = %d，%s x − %s y = %d。\n(1) 求 x、y　(2) 求 log_{x} y　(3) 求 log_{y} (xy)" % (lb, lb, S, lb, lb, D),
                [ch("令 u = %s x、v = %s y，方程組變成？" % (lb, lb), ["u + v = %d，u − v = %d" % (S, D), "uv = %d，u/v = %d" % (S, D),
                                                               "u + v = %d，u − v = %d" % (b ** S, D), "u + v = %d，u − v = %d" % (D, S)],
                    "%s x、%s y 各是一個數，直接相加減" % (lb, lb), "(1)　u + v = %d，u − v = %d" % (S, D), part="(1)"),
                 fl("兩式相加、相減：", "u = [0]，v = [1]", [str(u), str(v)], "2u = %d + %s" % (S, tp(D)), part="(1)"),
                 fl("換回 x、y：", "x = %d^{%d} = [0]，y = %d^{%d} = [1]" % (b, u, b, v), [a(x), a(y)], "u = %s x 代表 x = %d^{u}" % (lb, b), part="(1)"),
                 fl("換底：log_{x} y = %s y / %s x：" % (lb, lb), "(2)　log_{x} y = v/u = [0]", [a(r3)], "%s ÷ %d" % (tp(v), u), part="(2)"),
                 fl("log_{y} (xy) = %s (xy) / %s y：" % (lb, lb), "答：(3)　log_{y} (xy) = (u + v)/v = [0]", [a(r4)], "%d ÷ %s" % (S, tp(v)), part="(3)")])


# ---------- b_star：星等 ----------

def b_star(d1, ma, mb, k, approx, how):
    r1 = 10 ** (d1 / 2.5)
    assert abs(r1 - round(r1)) < 1e-6
    r1 = round(r1)
    r2 = 10 ** ((mb - ma) / 2.5)
    assert abs(r2 - round(r2)) < 1e-6
    r2 = round(r2)
    dm = 2.5 * math.log10(k)
    assert abs(dm - float(approx)) < 0.05
    return item("b_star", "boss", 2, "星等與亮度", 1.6,
                "天文學用星等 m 表示星星的亮度 L：m_{1} − m_{2} = −2.5 log (L_{1}/L_{2})（星等越小越亮）。\n(1) 星等相差 %s 的兩顆星，亮度差幾倍？(2) A 星星等 %s、B 星星等 %s，A 的亮度是 B 的幾倍？(3) 亮度是 %d 倍的星，星等小多少？（log 2 ≈ 0.3010）"
                % (("%g" % d1), ("%g" % ma).replace("-", "−"), "%g" % mb, k),
                [ch("把式子改寫成亮度比：", ["L_{1}/L_{2} = 10^{(m_{2} − m_{1})/2.5}", "L_{1}/L_{2} = 10^{(m_{1} − m_{2})/2.5}", "L_{1}/L_{2} = 2.5^{m_{2} − m_{1}}",
                                      "L_{1}/L_{2} = (m_{2} − m_{1})/2.5"],
                    "兩邊除以 −2.5：log (L_{1}/L_{2}) = (m_{2} − m_{1})/2.5", "L_{1}/L_{2} = 10^{(m_{2} − m_{1})/2.5}"),
                 fl("星等差 %g：" % d1, "(1)　10^{%g/2.5} = 10^{%g} = [0] 倍" % (d1, d1 / 2.5), [str(r1)], "%g ÷ 2.5 = %g" % (d1, d1 / 2.5), part="(1)"),
                 fl("A 的星等比較小，比較亮：", "(2)　10^{(%g − %s)/2.5} = [0] 倍" % (mb, ("(%g)" % ma) if ma < 0 else "%g" % ma), [str(r2)],
                    "%g − %s = %g，再除以 2.5" % (mb, ("(%g)" % ma) if ma < 0 else "%g" % ma, mb - ma), part="(2)"),
                 fl("亮度比 %d：" % k, "答：(3)　星等差 = 2.5 log %d ≈ [0]（取到小數點後第一位）" % k, [approx], how, part="(3)")])


# ---------- b_inverse：反函數 ----------

def b_inverse(b, h, k, V):
    n = round(math.log(V - k, b))
    assert b ** n == V - k
    val = n + h
    f = lambda x: b ** (x - h) + k
    g = lambda x: lg(b, x - k) + h
    assert abs(f(g(V)) - V) < 1e-9 and abs(g(V) - val) < 1e-9
    xh = "x %s %d" % ("−" if h > 0 else "+", abs(h))
    fx_ = "%d^{%s} %s %d" % (b, xh, "+" if k > 0 else "−", abs(k))
    return item("b_inverse", "boss", 2, "指數的反函數", 1.6,
                "f(x) = %s。\n(1) f 的值域　(2) 求反函數 f^{−1}(x)　(3) 求 f^{−1}(%d)　(4) y = f^{−1}(x) 的漸近線" % (fx_, V),
                [ch("%d^{%s} 可以是任何正數，所以 f 的值域是？" % (b, xh), ["y > %d" % k, "y > 0", "y ≥ %d" % k, "全體實數"],
                    "正數再加 %s" % t(k) if k > 0 else "正數再減 %d" % -k, "(1)　值域：y > %d" % k, part="(1)"),
                 fl("令 y = %s，把 x 解出來，再把 x、y 互換：" % fx_, "(2)　f^{−1}(x) = log_{%d} (x − [0]) + [1]" % b, [str(k), str(h)],
                    "%d^{%s} = y %s %d ⇒ %s = log_{%d} (y %s %d)" % (b, xh, "−" if k > 0 else "+", abs(k), xh, b, "−" if k > 0 else "+", abs(k)), part="(2)"),
                 fl("代入 x = %d：" % V, "(3)　f^{−1}(%d) = log_{%d} %d + %s = [0]" % (V, b, V - k, tp(h)), [str(val)],
                    "%d = %d^{%d}" % (V - k, b, n), part="(3)"),
                 ch("y = f^{−1}(x) 的漸近線是？", ["x = %d" % k, "y = %d" % k, "x = %d" % h, "x = 0"],
                    "f 的水平漸近線 y = %d 對直線 y = x 鏡射" % k, "答：(4)　漸近線 x = %d" % k, part="(4)")],
                plot={"x": [-2.5, 9.0], "y": [-2.5, 9.0],
                      "curves": [{"f": "pow(%d,x-%d)+%d" % (b, h, k), "c": "cyan"}, {"f": "x", "c": "faint"},
                                 {"f": "log(x-%d)/log(%d)+%d" % (k, b, h), "c": "pink", "dom": [k + 0.005, 99.0], "at": 2}],
                      "vlines": [{"x": float(k), "at": 4}]})


# ---------- b_twoexp：兩個相異實根的 k ----------

def b_twoexp(b, q):
    m0 = 2 * math.isqrt(q)
    assert (m0 // 2) ** 2 == q
    sq = b * b
    S = round(math.log(q, b))
    assert b ** S == q
    for kk, want in ((m0 + 0.5, 2), (m0 - 0.5, 0), (m0, 1), (-m0 - 1, 0)):
        rs = roots_in(lambda x: sq ** x - kk * b ** x + q, -12, 12, 240000)
        assert len(rs) == want, (kk, rs)
    return item("b_twoexp", "boss", 3, "兩個實根的條件", 1.65,
                "方程式 %d^{x} − k · %d^{x} + %d = 0 有兩個相異實根 x_{1}、x_{2}。\n(1) 求 k 的範圍　(2) 求 x_{1} + x_{2}" % (sq, b, q),
                [ch("令 t = %d^{x}（t > 0）。原方程式有兩個相異實根，等於 t^{2} − kt + %d = 0 要？" % (b, q),
                    ["有兩個相異的正根", "有兩個相異實根", "有一個正根", "有兩個相異的負根"],
                    "每個正的 t 剛好對到一個 x，負的 t 對不到", "(1)　t^{2} − kt + %d = 0 有兩個相異的正根" % q, part="(1)"),
                 fl("相異實根：判別式 > 0。", "k^{2} − 4 · %d > 0 ⇒ k^{2} > [0]" % q, [str(4 * q)], "判別式 b^{2} − 4ac", part="(1)"),
                 ch("兩根都是正的，還要？", ["兩根和 k > 0、兩根積 %d > 0" % q, "兩根和 k < 0", "兩根積 %d < 0" % q, "不用其他條件"],
                    "兩個正數：和是正的、積也是正的", "兩根和 k > 0，兩根積 %d > 0" % q, part="(1)"),
                 fl("k^{2} > %d 而且 k > 0：" % (4 * q), "k > [0]", [str(m0)], "k > %d 或 k < −%d，再取 k > 0" % (m0, m0), part="(1)"),
                 fl("兩根的積：%d^{x_{1}} · %d^{x_{2}} = %d。" % (b, b, q), "答：(2)　%d^{x_{1} + x_{2}} = %d ⇒ x_{1} + x_{2} = [0]" % (b, q), [str(S)],
                    "%d = %d^{%d}" % (q, b, S), part="(2)")])


# ---------- b_twoxy：兩個變數的最值 ----------

def b_twoxy(k):
    mx = F(k * k, 4)
    h = F(k, 2)
    mn = F(4, k)
    xv = F(10) ** h if isint(h) else None
    assert xv is not None
    us = [i / 1000 * k for i in range(1, 1000)]
    assert abs(max(u * (k - u) for u in us) - float(mx)) < 1e-3
    assert abs(min(1 / u + 1 / (k - u) for u in us) - float(mn)) < 1e-3
    return item("b_twoxy", "boss", 3, "兩個變數的最值", 1.65,
                "x > 1、y > 1，而且 xy = %s。\n(1) log x + log y = ？　(2) log x · log y 的最大值，以及此時 x、y　(3) log_{x} 10 + log_{y} 10 的最小值" % t(F(10) ** k),
                [fl("兩邊取 log：", "(1)　log x + log y = log (xy) = [0]", [str(k)], "%s = 10^{%d}" % (t(F(10) ** k), k), part="(1)"),
                 ch("令 u = log x、v = log y。x > 1、y > 1，所以 u、v 都是正的。uv 最大是？", ["((u + v)/2)^{2}", "(u + v)^{2}", "(u + v)/2", "u^{2} + v^{2}"],
                    "算幾不等式：(u + v)/2 ≥ √{uv}", "(2)　u + v = %d，uv ≤ (%d/2)^{2}" % (k, k), part="(2)"),
                 fl("等號成立在 u = v：", "uv 最大 [0]，此時 x = y = [1]", [a(mx), a(xv)], "u = v = %s，x = 10^{%s}" % (t(h), t(h)), part="(2)"),
                 fl("換底：log_{x} 10 = 1/log x = 1/u。", "答：(3)　1/u + 1/v = (u + v)/(uv) = %d/(uv) ≥ [0]" % k, [a(mn)],
                    "uv 最大 %s 的時候，%d/(uv) 最小" % (t(mx), k), part="(3)")])


# ---------- b_hline：水平線截兩條曲線 ----------

def b_hline(b, L):
    L = F(L)
    k = F(b) ** (2 * L)
    assert isint(k)
    k = int(k)
    xa = lg(b, k)
    xb = lg(b * b, k)
    assert abs(xa - xb - float(L)) < 1e-9
    XA, XB = 2 * L, L
    area = L * k / 2
    sq = b * b
    return item("b_hline", "boss", 2, "水平線截兩條曲線", 1.6,
                "水平線 y = k（k > 1）和 y = %d^{x}、y = %d^{x} 的圖形分別交於 A、B，\\ol{AB} = %s。\n(1) 用 k 表示 A、B 的 x 坐標　(2) 求 k　(3) 求 △OAB 的面積（O 是原點）" % (b, sq, t(L)),
                [fl("%d^{x} = k ⇒ x = log_{%d} k；%d^{x} = k ⇒ x = log_{%d} k = log_{%d} k / log_{%d} %d：" % (b, b, sq, sq, b, b, sq),
                    "(1)　x_{A} = log_{%d} k，x_{B} = [0] log_{%d} k" % (b, b), ["1/2"], "log_{%d} %d = 2" % (b, sq), part="(1)"),
                 fl("A 在 B 的右邊：", "(2)　\\ol{AB} = (1/2) log_{%d} k = %s ⇒ k = [0]" % (b, t(L)), [str(k)], "log_{%d} k = %s，k = %d^{%s}" % (b, t(2 * L), b, t(2 * L)),
                    part="(2)"),
                 fl("k = %d 代回：" % k, "A([0], %d)、B([1], %d)" % (k, k), [a(XA), a(XB)], "x_{A} = log_{%d} %d" % (b, k), part="(3)"),
                 fl("底 \\ol{AB} = %s，高是 A、B 到 x 軸的距離 %d：" % (t(L), k), "答：(3)　△OAB 面積 = [0]", [a(area)], "(1/2) · %s · %d" % (t(L), k), part="(3)")],
                plot={"x": [-0.8, float(XA) + 1.0], "y": [-0.6, k + 1.5],
                      "curves": [{"f": "pow(%d,x)" % b, "c": "cyan"}, {"f": "pow(%d,x)" % sq, "c": "pink"}, {"f": str(k), "c": "dim", "dash": True, "at": 2}],
                      "pts": [{"x": fx(float(XA)), "y": k, "label": "A", "at": 2}, {"x": fx(float(XB)), "y": k, "label": "B", "off": [-18, -6], "at": 2},
                              {"x": 0, "y": 0, "label": "O", "off": [-16, 14], "at": 3}]})


def items():
    return [
        [b_logsys(2, 5, 1), b_logsys(3, 4, 2), b_logsys(2, 3, 5)],
        [b_star(5, 1.3, 3.8, 4, "1.5", "2.5 × 2 log 2 = 5 × 0.3010"), b_star(7.5, 2.1, 4.6, 8, "2.3", "2.5 × 3 log 2 = 7.5 × 0.3010"),
         b_star(2.5, -0.5, 4.5, 2, "0.8", "2.5 × 0.3010 ≈ 0.75")],
        [b_inverse(2, 1, 3, 11), b_inverse(3, 2, 1, 10), b_inverse(2, -1, 5, 7)],
        [b_twoexp(2, 4), b_twoexp(3, 9), b_twoexp(2, 16)],
        [b_twoxy(2), b_twoxy(4), b_twoxy(6)],
        [b_hline(2, 1), b_hline(3, 1), b_hline(2, F(3, 2))],
    ]
