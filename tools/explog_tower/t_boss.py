# 試煉大題（原本的 6 題）
from elib import *

TEN = {1: "1/10", 2: "1/100", 3: "1/1000", 4: "1/10000"}


# ---------- b_drug：半衰期 ----------

def b_drug(T, t1, k):
    n1 = t1 // T
    assert n1 * T == t1
    left = F(1, 2) ** n1
    tt = T / L2
    t1d = "%.1f" % tt
    tk = round(k * tt)
    assert abs(k * float(t1d) - tk) < 0.5
    return item("b_drug", "boss", 2, "藥物代謝", 1.6,
                "某藥物在血液中的濃度每 %d 小時減半：服藥 t 小時後，濃度是 C(t) = C_{0} · (1/2)^{t/%d}。\n(1) %d 小時後剩原本的幾分之幾？\n(2) 降到原本的 1/10，約需幾小時？\n(3) 降到原本的 %s，約需幾小時？（log 2 ≈ 0.3010）"
                % (T, T, t1, TEN[k]),
                [fl("t = %d 代入，剩原本的幾分之幾？" % t1, "(1)　C(%d) = C_{0} · (1/2)^{%d/%d}，剩原本的 [0]" % (t1, t1, T), [a(left)],
                    "%d/%d = %d，算 (1/2)^{%d}" % (t1, T, n1, n1), part="(1)"),
                 ch("(1/2)^{t/%d} = 1/10。兩邊取 log，得到？" % T, ["t/%d · log 2 = 1" % T, "t/%d · log 2 = 10" % T, "t/%d = log 2" % T, "t/%d · log 2 = −1" % T],
                    "log (1/2) = −log 2、log (1/10) = −1，兩邊的負號可以消掉",
                    "(2)　t/%d · log (1/2) = log (1/10)　⇒　t/%d · log 2 = 1" % (T, T), part="(2)"),
                 fl("t = %d/log 2 ≈ %d/0.3010，算到小數點後第一位：" % (T, T), "　 　t = %d/log 2 ≈ [0]（小時）" % T, [t1d],
                    "1/0.3010 ≈ 3.32，再乘 %d" % T, part="(2)"),
                 fl("時間是 (2) 的幾倍、約幾小時？（取整數）", "(3)　%s = (1/10)^{%d}　→　時間是 [0] 倍：約 [1] 小時" % (TEN[k], k), [str(k), str(tk)],
                    "每降到 1/10 都要花 %s 小時，連續降 %d 次" % (t1d, k), part="(3)")])


# ---------- b_slope：曲線上的兩點 ----------

def b_slope(base, m):
    q = F(base) ** m
    A = 1 / (q - 1)
    B = q * A
    S = 2 * A + B
    assert B - A == 1
    la, lb_ = lg(base, float(A)), lg(base, float(B))
    assert abs(lb_ - la - m) < 1e-9
    L = 1 + m * m
    lbs = "log_{%d}" % base
    return item("b_slope", "boss", 2, "曲線上的兩點", 1.6,
                "A(a, r)、B(b, s) 是 y = %s x 圖形上的兩點，a < b。直線 AB 的斜率是 %d，\\ol{AB} = √{%d}。\n(1) 求 b − a 與 s − r　(2) b 是 a 的幾倍？　(3) 求 2a + b" % (lbs, m, L),
                [fl("斜率 %d、長度 √{%d}，求 b − a 與 s − r：" % (m, L), "(1)　b − a = [0]，s − r = [1]", ["1", str(m)],
                    "s − r = %s(b − a)，畢氏定理：(b − a)^{2} + (s − r)^{2} = %d，而且 a < b" % ("" if m == 1 else str(m), L), part="(1)"),
                 fl("s − r = %s b − %s a = %d，b 是 a 的幾倍？" % (lbs, lbs, m), "(2)　%s (b/a) = %d　→　b = [0]a" % (lbs, m), [a(q)],
                    "%s (b/a) = %d 代表 b/a = %d^{%d}" % (lbs, m, base, m), part="(2)"),
                 fl("b = %sa 代入 b − a = 1，求 a、b 與 2a + b：" % t(q), "(3)　a = [0]，b = [1]，2a + b = [2]", [a(A), a(B), a(S)],
                    "%sa − a = %sa = 1" % (t(q), t(q - 1)), part="(3)")],
                plot={"x": [-0.4, fx(float(B) + 1.6)], "y": [fx(min(la, -1.0) - 0.9), fx(max(lb_, 1.0) + 1.5)],
                      "curves": [{"f": "log(x)/log(%d)" % base, "c": "cyan", "dom": [0.02, 99.0]}],
                      "pts": [{"x": fx(float(A)), "y": fx(la), "label": "A", "at": 3}, {"x": fx(float(B)), "y": fx(lb_), "label": "B", "at": 3}]})


# ---------- b_mirror：鏡像雙根 ----------

def b_mirror(base, c):
    al = roots_in(lambda x: base ** x - (c - x), -5, c)
    be = roots_in(lambda x: lg(base, x) - (c - x), 0.001, c + 5)
    assert len(al) == 1 and len(be) == 1 and abs(al[0] + be[0] - c) < 1e-6
    al, be = al[0], be[0]
    h = F(c, 2)
    return item("b_mirror", "boss", 3, "鏡像雙根", 1.6,
                "α 是 %d^{x} = %d − x 的實根，β 是 log_{%d} x = %d − x 的實根。\n(1) y = %d^{x} 與 y = log_{%d} x 的圖形對稱於哪條直線？\n(2) 求 α + β　(3) 求 %d^{α} + log_{%d} β"
                % (base, c, base, c, base, base, base, base),
                [ch("y = %d^{x} 與 y = log_{%d} x 的圖形對稱於？" % (base, base), ["直線 y = x", "y 軸", "x 軸", "原點"], "互為反函數",
                    "(1)　兩曲線對稱於 y = x", part="(1)"),
                 fl("直線 y = %d − x 也對稱於 y = x，兩個交點互相鏡射。求中點與 α + β：" % c,
                    "(2)　中點是兩條直線的交點 ([0], [1])　→　α + β = [2]", [a(h), a(h), str(c)],
                    "中點在 y = x 與 y = %d − x 上：解 x = %d − x，中點的 x 坐標是 (α + β)/2" % (c, c), part="(2)"),
                 fl("α、β 分別滿足各自的方程式。%d^{α} + log_{%d} β = ？" % (base, base), "(3)　%d^{α} + log_{%d} β = [0]" % (base, base), [str(c)],
                    "%d^{α} = %d − α，log_{%d} β = %d − β，相加後用 (2) 的 α + β" % (base, c, base, c), part="(3)")],
                plot={"x": [-0.5, c + 1.5], "y": [-0.5, c + 1.5],
                      "curves": [{"f": "pow(%d,x)" % base, "c": "cyan"}, {"f": "log(x)/log(%d)" % base, "c": "pink", "dom": [0.02, 99.0]},
                                 {"f": "%d-x" % c, "c": "dim", "at": 1}, {"f": "x", "c": "faint"}],
                      "pts": [{"x": fx(al), "y": fx(c - al), "label": "", "at": 2}, {"x": fx(be), "y": fx(c - be), "label": "", "at": 2},
                              {"x": fx(float(h)), "y": fx(float(h)), "label": "(%s, %s)" % (t(h), t(h)), "at": 2}]})


# ---------- b_read：讀圖解謎 ----------

def b_read(p, h):
    A = F(1, p)
    c = F(1, p - h)
    d = -h * c
    assert A * p == 1 and c * h + d == 0 and c * p + d == 1
    return item("b_read", "boss", 2, "讀圖解謎", 1.6,
                "f(x) = log (ax + b) 的圖形往左越來越靠近 y 軸，g(x) = log (cx + d) 的圖形往左越來越靠近直線 x = %d，兩個圖形都通過 (%d, 0)。\n(1) 求 b　(2) 求 a　(3) 求數對 (c, d)" % (h, p),
                [fl("f 的漸近線是 y 軸（x = 0），求 b：", "(1)　x = 0 時真數 ax + b = 0　→　b = [0]", ["0"], "漸近線在真數等於 0 的地方，把 x = 0 代進真數", part="(1)"),
                 fl("f 通過 (%d, 0)，求 a：" % p, "(2)　log (%da) = 0　→　a = [0]" % p, [a(A)], "log N = 0 代表 N = 1", part="(2)"),
                 fl("g 的漸近線 x = %d、又通過 (%d, 0)，求 (c, d)：" % (h, p), "(3)　(c, d) = ([0], [1])", [a(c), a(d)],
                    "x = %d 時真數 %sc + d = 0，通過 (%d, 0)：%dc + d = 1" % (h, "" if h == 1 else str(h), p, p), part="(3)")],
                plot={"x": [-0.5, p + 3.0], "y": [-2.0, 1.2],
                      "curves": [{"f": "log(%s*x)/log(10)" % repr(float(A)), "c": "cyan", "dom": [0.02, 99.0]},
                                 {"f": "log(%s*x%s)/log(10)" % (repr(float(c)), ("%+.6g" % float(d))), "c": "pink", "dom": [h + 0.005, 99.0]}],
                      "vlines": [{"x": float(h)}], "pts": [{"x": p, "y": 0, "label": "(%d, 0)" % p, "off": [6, 20]}]})


# ---------- b_digits：等比數列的位數 ----------

def b_digits(n):
    a_ = 2 ** n - 1
    lv = n * L2
    k = math.floor(lv)
    assert len(str(a_)) == k + 1
    ld = lead_digit(lv - k)
    assert ld and int(str(a_)[0]) == ld[0]
    d_, lo, hi = ld
    u2 = [6, 2, 4, 8][n % 4]
    assert (2 ** n) % 10 == u2 and a_ % 10 == u2 - 1
    lvs = ("%.3f" % lv).rstrip("0").rstrip(".")
    frs = "0" + ("%.3f" % (lv - k)).rstrip("0").rstrip(".")[("%.3f" % (lv - k)).index("."):] if True else ""
    frs = ("%.3f" % (lv - k)).rstrip("0").rstrip(".")
    lo_t = "0" if lo == 1 else "log %d" % lo
    return item("b_digits", "boss", 3, "等比數列的位數", 1.6,
                "a = 1 + 2 + 2^{2} + … + 2^{%d}（共 %d 項）。已知 log 2 ≈ 0.3010。\n(1) 化簡 a　(2) a 是幾位數？　(3) a 的個位數字　(4) a 的最高位數字" % (n - 1, n),
                [ch("a 化簡成？", ["2^{%d} − 1" % n, "2^{%d}" % n, "2^{%d} − 1" % (n - 1), "2^{%d} − 1" % (n + 1)],
                    "等比級數：1 × (2^{%d} − 1)/(2 − 1)" % n, "(1)　等比級數：a = (2^{%d} − 1)/(2 − 1) = 2^{%d} − 1" % (n, n), part="(1)"),
                 fl("先算 log 2^{%d}，a 是幾位數？" % n, "(2)　log 2^{%d} = %d × 0.3010 = [0]　→　a 是 [1] 位數" % (n, n), [lvs, str(k + 1)],
                    "首數 %d ⇒ 2^{%d} 是 %d 位數，2^{%d} 不是 10 的次方，減 1 不會少一位" % (k, n, k + 1, n), part="(2)"),
                 fl("a 的個位數字？", "(3)　2^{%d} 的個位數字 [0]　→　a 的個位數字 [1]" % n, [str(u2), str(u2 - 1)], "2 的次方個位數：2、4、8、6 循環", part="(3)"),
                 fl("a 的最高位數字？", "(4)　2^{%d} = 10^{%s}　→　最高位數字 [0]" % (n, lvs), [str(d_)],
                    "%s < %s < log %d，所以 10^{%s} 介於 %d 和 %d 之間" % (lo_t, frs, hi, frs, lo, hi), part="(4)")])


# ---------- b_ineq：換元不等式 ----------

def b_ineq(r2, e2):
    r1 = F(1, 4)
    assert F(1, 2) ** e2 == r2
    K = 4 * (r1 + r2)
    C = 4 * r1 * r2
    assert isint(K) and isint(C)
    K, C = int(K), int(C)
    f = lambda x: 0.25 ** (x - 1) - K * 0.5 ** x + C
    for x in (-6, e2 - 0.5, e2 + 0.5, 1, 1.9, 2.1, 5):
        assert (f(x) >= -1e-12) == (x <= e2 or x >= 2), x
    r2t = t(r2)
    return item("b_ineq", "boss", 3, "換元不等式", 1.7,
                "解不等式 (1/4)^{x − 1} − %d · (1/2)^{x} + %d ≥ 0。\n(1) 令 t = (1/2)^{x}，改寫成 t 的不等式　(2) 解出 t　(3) 換回指數，求 x 的範圍" % (K, C),
                [ch("令 t = (1/2)^{x}，t 的範圍是？", ["t > 0", "t ≥ 1", "t ≥ 0", "0 < t < 1"],
                    "正數的任何次方都是正數（x 是負數時 t 也可以大於 1）", "(1)　令 t = (1/2)^{x}，t > 0", part="(1)"),
                 ch("(1/4)^{x − 1} 用 t 表示：", ["4t^{2}", "t^{2}/4", "4t", "t^{2} − 1"],
                    "(1/4)^{x − 1} = (1/4)^{x} · (1/4)^{−1}，而 (1/4)^{x} = ((1/2)^{x})^{2}", "(1/4)^{x − 1} = 4 · (1/4)^{x} = 4t^{2}", part="(1)"),
                 ch("原不等式改寫成 t 的式子：", uniq([quad_t(4, -K, C, "t") + " ≥ 0"], ["4t − %dt + %d ≥ 0" % (K, C), "4t^{2} − %dt^{2} + %d ≥ 0" % (K, C),
                                                                              quad_t(1, -K, 4 * C, "t") + " ≥ 0"]),
                    "(1/2)^{x} 直接換成 t", "原式 ⇒ %s ≥ 0" % quad_t(4, -K, C, "t"), part="(1)"),
                 ch("%s 因式分解：" % quad_t(4, -K, C, "t"), uniq([fac_t(4, -1, 1, -r2)], [fac_t(4, -r2, 1, -1), fac_t(2, -1, 2, -r2), fac_t(4, 1, 1, r2)]),
                    "4 × %s = %s，%s + 1 = %d：交叉相乘湊 −%dt" % (r2t, t(4 * r2), t(4 * r2), K, K), "(2)　%s ≥ 0" % fac_t(4, -1, 1, -r2), part="(2)"),
                 ch("t 的範圍？（別忘了 t > 0）", ["0 < t ≤ 1/4 或 t ≥ %s" % r2t, "1/4 ≤ t ≤ %s" % r2t, "0 < t ≤ 1/4", "0 < t ≤ %s" % r2t],
                    "兩根 1/4、%s，開口向上，大於等於 0 在兩根的外側" % r2t, "0 < t ≤ 1/4 或 t ≥ %s" % r2t, part="(2)"),
                 fl("換回 (1/2)^{x}，兩邊都寫成 1/2 的次方：", "(1/2)^{x} ≤ (1/2)^{[0]} 或 (1/2)^{x} ≥ (1/2)^{[1]}", ["2", str(e2)],
                    "1/4 = (1/2)^{2}，%s = 2^{%d} = (1/2)^{%d}" % (r2t, -e2, e2), part="(3)"),
                 ch("底數 1/2 < 1，比較指數：", ["x ≥ 2 或 x ≤ %d" % e2, "x ≤ 2 或 x ≥ %d" % e2, "x ≥ 2 或 x ≥ %d" % e2, "%d ≤ x ≤ 2" % e2],
                    "底數小於 1 是遞減：比較指數時不等號要反向", "(3)　底數 1/2 < 1（遞減）⇒ x ≥ 2 或 x ≤ %d" % e2, part="(3)"),
                 step("line", part="(3)", q="封印 x 的範圍（注意等號）。", row="解", marks=[str(e2), "2"], seg=[1, 0, 1], pt=[1, 1],
                      write="答：x ≤ %d 或 x ≥ 2" % e2)])


def items():
    return [
        [b_drug(6, 12, 3), b_drug(5, 15, 2), b_drug(4, 8, 4)],
        [b_slope(2, 2), b_slope(3, 1), b_slope(2, 3)],
        [b_mirror(2, 5), b_mirror(2, 4), b_mirror(3, 6)],
        [b_read(2, 1), b_read(3, 1), b_read(4, 2)],
        [b_digits(40), b_digits(33), b_digits(45)],
        [b_ineq(8, -3), b_ineq(2, -1), b_ineq(4, -2)],
    ]
