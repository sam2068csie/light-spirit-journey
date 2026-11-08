# 真假審判
#   觀念題的每一組卡片是手挑的，但每一張的真假都用數值驗算（cardc 會 assert）。
from elib import *

log10 = math.log10


def J(id_, tier, title, tmul, stem, q, cards, plot=None):
    return item(id_, "judge", tier, title, tmul, stem, [jd(q, [cardc(*c) for c in cards])], plot=plot)


def eq(x, y):
    return abs(x - y) < 1e-9


# ---------- j_rules ----------

RULES = [
    [("log (2 + 3) = log 2 + log 3", False, "log 2 + log 3 = log 6，不是 log 5", eq(log10(5), log10(2) + log10(3))),
     ("log_{2} 3 · log_{3} 2 = 1", True, "兩個互為倒數，相乘是 1", eq(lg(2, 3) * lg(3, 2), 1)),
     ("對所有 x ≠ 0，log x^{2} = 2 log x", False, "x < 0 時右邊沒有意義，應該是 2 log |x|", False),
     ("2^{−log_{2} 3} = −3", False, "2^{−log_{2} 3} = 2^{log_{2} (1/3)} = 1/3，2 的任何次方都是正的", eq(2 ** -lg(2, 3), -3)),
     ("log_{√{2}} √{3} = log_{2} 3", True, "底數和真數同時開平方，值不變", eq(lg(S2, S3), lg(2, 3)))],
    [("log (2 × 5) = log 2 · log 5", False, "log (2 × 5) = log 2 + log 5 = 1", eq(1, log10(2) * log10(5))),
     ("log_{4} 9 = log_{2} 3", True, "底數和真數同時開平方，值不變", eq(lg(4, 9), lg(2, 3))),
     ("對所有 x ≠ 0，log x^{4} = 4 log x", False, "x < 0 時右邊沒有意義，應該是 4 log |x|", False),
     ("3^{log_{3} 5} = 5", True, "a^{log_{a} N} = N", eq(3 ** lg(3, 5), 5)),
     ("log_{2} 8 − log_{2} 2 = log_{2} 6", False, "相減是相除：log_{2} (8/2) = log_{2} 4 = 2", eq(lg(2, 8) - lg(2, 2), lg(2, 6)))],
    [("log 6 − log 2 = log 4", False, "相減是相除：log (6/2) = log 3", eq(log10(6) - log10(2), log10(4))),
     ("log_{5} 2 · log_{2} 5 = 1", True, "兩個互為倒數，相乘是 1", eq(lg(5, 2) * lg(2, 5), 1)),
     ("(log 3)^{2} = 2 log 3", False, "2 log 3 = log 9；(log 3)^{2} ≈ 0.23", eq(log10(3) ** 2, 2 * log10(3))),
     ("10^{−log 4} = 1/4", True, "10^{−log 4} = 10^{log (1/4)} = 1/4", eq(10 ** -log10(4), 0.25)),
     ("log_{8} 27 = log_{2} 3", True, "底數和真數同時開立方，值不變", eq(lg(8, 27), lg(2, 3)))],
]

# ---------- j_value ----------

VALUE = [
    [("log_{2} 24 − log_{2} 3 = 3", True, "log_{2} (24/3) = log_{2} 8 = 3", eq(lg(2, 24) - lg(2, 3), 3)),
     ("log_{3} 5 · log_{5} 9 = 2", True, "連鎖：log_{3} 9 = 2", eq(lg(3, 5) * lg(5, 9), 2)),
     ("log_{4} 8 = 3/2", True, "log_{2^{2}} 2^{3} = 3/2", eq(lg(4, 8), 1.5)),
     ("5^{log_{25} 9} = 9", False, "log_{25} 9 = log_{5} 3，所以 5^{log_{5} 3} = 3", eq(5 ** lg(25, 9), 9)),
     ("log_{9} 27 = 2/3", False, "log_{3^{2}} 3^{3} = 3/2，分子分母放反了", eq(lg(9, 27), 2 / 3))],
    [("log_{3} 54 − log_{3} 2 = 3", True, "log_{3} (54/2) = log_{3} 27 = 3", eq(lg(3, 54) - lg(3, 2), 3)),
     ("log_{2} 7 · log_{7} 32 = 5", True, "連鎖：log_{2} 32 = 5", eq(lg(2, 7) * lg(7, 32), 5)),
     ("log_{8} 4 = 2/3", True, "log_{2^{3}} 2^{2} = 2/3", eq(lg(8, 4), 2 / 3)),
     ("4^{log_{16} 25} = 25", False, "log_{16} 25 = log_{4} 5，所以 4^{log_{4} 5} = 5", eq(4 ** lg(16, 25), 25)),
     ("log_{27} 9 = 3/2", False, "log_{3^{3}} 3^{2} = 2/3，分子分母放反了", eq(lg(27, 9), 1.5))],
    [("log_{5} 75 − log_{5} 3 = 2", True, "log_{5} (75/3) = log_{5} 25 = 2", eq(lg(5, 75) - lg(5, 3), 2)),
     ("log_{2} 3 · log_{3} 16 = 3", False, "連鎖：log_{2} 16 = 4", eq(lg(2, 3) * lg(3, 16), 3)),
     ("log_{25} 125 = 3/2", True, "log_{5^{2}} 5^{3} = 3/2", eq(lg(25, 125), 1.5)),
     ("9^{log_{3} 2} = 4", True, "(3^{2})^{log_{3} 2} = (3^{log_{3} 2})^{2} = 2^{2}", eq(9 ** lg(3, 2), 4)),
     ("log_{16} 8 = 4/3", False, "log_{2^{4}} 2^{3} = 3/4，分子分母放反了", eq(lg(16, 8), 4 / 3))],
]

# ---------- j_expcmp ----------

EXPCMP = [
    [("2^{0.3} < 2^{0.4}", True, "底數 2 > 1，指數大的比較大", 2 ** 0.3 < 2 ** 0.4),
     ("0.5^{0.3} < 0.5^{0.4}", False, "底數 0.5 < 1 是遞減，指數大的反而小", 0.5 ** 0.3 < 0.5 ** 0.4),
     ("0.3^{√{2}} < 0.6^{√{2}}", True, "指數都是 √{2} > 0，底數大的比較大", 0.3 ** S2 < 0.6 ** S2),
     ("3^{0.2} > 1", True, "底數 > 1、指數 > 0，結果 > 1", 3 ** 0.2 > 1),
     ("(1/2)^{−2} < 1", False, "(1/2)^{−2} = 2^{2} = 4", 0.5 ** -2 < 1)],
    [("3^{0.5} < 3^{0.7}", True, "底數 3 > 1，指數大的比較大", 3 ** 0.5 < 3 ** 0.7),
     ("0.4^{0.5} < 0.4^{0.7}", False, "底數 0.4 < 1 是遞減，指數大的反而小", 0.4 ** 0.5 < 0.4 ** 0.7),
     ("0.2^{√{3}} < 0.7^{√{3}}", True, "指數都是 √{3} > 0，底數大的比較大", 0.2 ** S3 < 0.7 ** S3),
     ("0.8^{0.2} > 1", False, "底數 < 1、指數 > 0，結果 < 1", 0.8 ** 0.2 > 1),
     ("(1/3)^{−2} > 1", True, "(1/3)^{−2} = 3^{2} = 9", (1 / 3) ** -2 > 1)],
    [("5^{−0.3} < 5^{−0.2}", True, "底數 5 > 1，指數 −0.3 < −0.2", 5 ** -0.3 < 5 ** -0.2),
     ("0.7^{−1} < 0.7^{−2}", True, "底數 0.7 < 1 是遞減：−1 > −2，所以 0.7^{−1} 比較小", 0.7 ** -1 < 0.7 ** -2),
     ("0.3^{−0.5} < 0.6^{−0.5}", False, "指數是負的，底數大的反而小", 0.3 ** -0.5 < 0.6 ** -0.5),
     ("2^{−0.1} > 1", False, "底數 > 1、指數 < 0，結果 < 1", 2 ** -0.1 > 1),
     ("(2/3)^{0} = 1", True, "任何正數的 0 次方都是 1", True)],
]

# ---------- j_curve ----------


def j_curve(b, xs, cards, xr, yr):
    pts = []
    for lab, x in zip("ABCD", xs):
        y = F(b) ** x
        pts.append({"x": x, "y": fx(float(y)), "label": lab})
    return J("j_curve", 1, "指數曲線上的點", 1.0,
             "在 y = %s^{x} 的圖形上取 A、B、C、D 四點，x 坐標分別是 %s。" % (t(F(b)) if isint(F(b)) else "(" + t(F(b)) + ")", "、".join(t(x) for x in xs)),
             "看著下面的圖判斷。", cards,
             plot={"x": xr, "y": yr, "curves": [{"f": "pow(%s,x)" % repr(float(b)), "c": "cyan"}], "pts": pts})


def slope(b, x1, x2):
    return (b ** x2 - b ** x1) / (x2 - x1)


def nroots(f, lo, hi):
    return len(roots_in(f, lo, hi, 200000))


CURVE = [
    (2, [-1, 0, 1, 2], [-2.5, 3.0], [-0.8, 5.0], [
        ("y = 2^{x} 的圖形凹口向上", True, "指數函數的圖形都是凹口向上", True),
        ("\\ol{AB}、\\ol{BC}、\\ol{CD} 之中，\\ol{CD} 的斜率最大", True, "斜率依序是 1/2、1、2，越往右越陡",
         slope(2, 1, 2) > max(slope(2, -1, 0), slope(2, 0, 1))),
        ("直線 y = 2x 和 y = 2^{x} 恰有兩個交點", True, "交在 x = 1 和 x = 2", nroots(lambda x: 2 ** x - 2 * x, -5, 8) == 2),
        ("A 和 C 對稱於 y 軸", False, "A(−1, 1/2)、C(1, 2)，y 坐標不同", False),
        ("B 在直線 AC 的下方", True, "凹口向上，弦 \\ol{AC} 在曲線上方，所以 B 在直線 AC 下方", 1 < (0.5 + 2) / 2)]),
    (3, [-1, 0, 1, 2], [-2.5, 3.0], [-1.0, 10.0], [
        ("y = 3^{x} 的圖形凹口向上", True, "指數函數的圖形都是凹口向上", True),
        ("\\ol{AB}、\\ol{BC}、\\ol{CD} 之中，\\ol{AB} 的斜率最大", False, "斜率依序是 2/3、2、6，越往右越陡",
         slope(3, -1, 0) > max(slope(3, 0, 1), slope(3, 1, 2))),
        ("直線 y = 2x + 1 和 y = 3^{x} 恰有兩個交點", True, "交在 x = 0 和 x = 1", nroots(lambda x: 3 ** x - 2 * x - 1, -6, 6) == 2),
        ("A 和 C 對稱於 y 軸", False, "A(−1, 1/3)、C(1, 3)，y 坐標不同", False),
        ("B 在直線 AC 的下方", True, "凹口向上，弦 \\ol{AC} 在曲線上方，所以 B 在直線 AC 下方", 1 < (1 / 3 + 3) / 2)]),
    (F(1, 2), [-2, -1, 0, 1], [-3.0, 2.5], [-0.8, 5.0], [
        ("y = (1/2)^{x} 的圖形凹口向上", True, "指數函數的圖形都是凹口向上（不管底數大於還是小於 1）", True),
        ("\\ol{AB} 的斜率是 −2", True, "A(−2, 4)、B(−1, 2)：(2 − 4)/1 = −2", eq(slope(0.5, -2, -1), -2)),
        ("直線 y = 1 − x/2 和 y = (1/2)^{x} 恰有兩個交點", True, "交在 x = 0 和 x = 1", nroots(lambda x: 0.5 ** x - 1 + x / 2, -6, 8) == 2),
        ("A 和 C 對稱於 y 軸", False, "A(−2, 4)、C(0, 1)，C 在 y 軸上", False),
        ("x 越大，y 越大", False, "底數 1/2 < 1，遞減", False)]),
]

# ---------- j_logcmp ----------

LOGCMP = [
    [("log_{0.5} 3 < log_{0.5} 2", True, "底數 0.5 < 1 是遞減，真數大的反而小", lg(0.5, 3) < lg(0.5, 2)),
     ("log_{2} 5 > log_{3} 5", True, "log 5/log 2 > log 5/log 3，分母越小越大", lg(2, 5) > lg(3, 5)),
     ("log_{1/2} 3 < log_{1/3} 2", True, "左邊 = −log_{2} 3 < −1，右邊 = −log_{3} 2 > −1", lg(0.5, 3) < lg(1 / 3, 2)),
     ("log_{4} 5 < log_{16} 24", False, "log_{16} 24 = log_{4} √{24}，而 √{24} < 5", lg(4, 5) < lg(16, 24)),
     ("(log_{2} 3 + log_{2} 12)/2 < log_{2} 6", False, "左邊 = (1/2)log_{2} 36 = log_{2} 6，兩邊相等", (lg(2, 3) + lg(2, 12)) / 2 < lg(2, 6) - 1e-12)],
    [("log_{0.3} 5 < log_{0.3} 4", True, "底數 0.3 < 1 是遞減，真數大的反而小", lg(0.3, 5) < lg(0.3, 4)),
     ("log_{3} 7 > log_{5} 7", True, "log 7/log 3 > log 7/log 5，分母越小越大", lg(3, 7) > lg(5, 7)),
     ("log_{1/3} 2 < log_{1/2} 3", False, "左邊 = −log_{3} 2 > −1，右邊 = −log_{2} 3 < −1", lg(1 / 3, 2) < lg(0.5, 3)),
     ("log_{9} 10 < log_{3} 4", True, "log_{9} 10 = log_{3} √{10}，而 √{10} < 4", lg(9, 10) < lg(3, 4)),
     ("(log_{3} 2 + log_{3} 8)/2 < log_{3} 4", False, "左邊 = (1/2)log_{3} 16 = log_{3} 4，兩邊相等", (lg(3, 2) + lg(3, 8)) / 2 < lg(3, 4) - 1e-12)],
    [("log_{0.2} 0.5 > 0", True, "底數、真數都在 0 和 1 之間，值是正的", lg(0.2, 0.5) > 0),
     ("log_{2} 3 > log_{4} 10", False, "log_{4} 10 = log_{2} √{10}，而 √{10} > 3", lg(2, 3) > lg(4, 10)),
     ("log_{1/2} 5 < log_{1/5} 2", True, "左邊 = −log_{2} 5 < −1，右邊 = −log_{5} 2 > −1", lg(0.5, 5) < lg(0.2, 2)),
     ("log_{5} 4 < 1", True, "4 < 5，所以 log_{5} 4 < log_{5} 5 = 1", lg(5, 4) < 1),
     ("log_{3} 2 · log_{2} 5 > 2", False, "連鎖：log_{3} 5，而 5 < 9 = 3^{2}", lg(3, 2) * lg(2, 5) > 2)],
]

# ---------- j_graph ----------

GRAPH = [
    [("y = 0.5^{x} 與 y = 2^{x} 的圖形對稱於 y 軸", True, "0.5^{x} = 2^{−x}，x 換成 −x", True),
     ("y = 2^{x} 與 y = log_{2} x 的圖形對稱於直線 y = x", True, "兩者互為反函數", True),
     ("若 a > 1，y = a^{x} 與 y = log_{a} x 的圖形一定沒有交點", False, "例如 a = √{2}，兩圖形交於 (2, 2) 和 (4, 4)",
      not (eq(S2 ** 2, 2) and eq(lg(S2, 2), 2))),
     ("y = log_{2} (2x) 是 y = log_{2} x 向上平移 1 單位", True, "log_{2} (2x) = 1 + log_{2} x", eq(lg(2, 2 * 3.7), 1 + lg(2, 3.7))),
     ("y = 2 log_{2} x 可由 y = log_{2} x 平移得到", False, "乘 2 是鉛直伸縮，平移做不到", False)],
    [("y = 3^{−x} 與 y = 3^{x} 的圖形對稱於 y 軸", True, "x 換成 −x", True),
     ("y = 3^{x} 與 y = log_{3} x 的圖形對稱於直線 y = x", True, "兩者互為反函數", True),
     ("y = log_{1/2} x 與 y = log_{2} x 的圖形對稱於 x 軸", True, "log_{1/2} x = −log_{2} x", eq(lg(0.5, 3.3), -lg(2, 3.3))),
     ("y = log_{3} (x/3) 是 y = log_{3} x 向下平移 1 單位", True, "log_{3} (x/3) = log_{3} x − 1", eq(lg(3, 2.2 / 3), lg(3, 2.2) - 1)),
     ("y = log_{3} x^{2} 和 y = 2 log_{3} x 的圖形一樣", False, "log_{3} x^{2} 在 x < 0 也有定義，圖形多了左邊一支", False)],
    [("y = 2^{x + 1} 是 y = 2^{x} 向右平移 1 單位", False, "x 換成 x + 1 是向左平移", False),
     ("y = 2^{x + 1} 也是 y = 2^{x} 鉛直伸長 2 倍", True, "2^{x + 1} = 2 · 2^{x}", eq(2 ** 1.3, 2 * 2 ** 0.3)),
     ("y = −2^{x} 與 y = 2^{x} 的圖形對稱於 x 軸", True, "y 換成 −y", True),
     ("y = log_{2} (x − 1) 的漸近線是 x = 1", True, "真數 x − 1 = 0 的地方", True),
     ("y = 2^{x} 與 y = log_{2} x 有交點", False, "2^{x} > x > log_{2} x，兩條曲線被直線 y = x 隔開",
      nroots(lambda x: 2 ** x - lg(2, x), 0.001, 20) > 0)],
]

# ---------- j_fg ----------


def fg_ok(a_, f):
    return f(a_)


FG = [
    ("可以代一個 a 試試看。", [
        ("若 f(2) = 9，則 g(27) = 3", True, "a^{2} = 9，a = 3，log_{3} 27 = 3", eq(lg(3, 27), 3)),
        ("g(40) − g(5) = g(16) − g(2)", True, "兩邊都是 log_{a} 8", all(eq(lg(a_, 40) - lg(a_, 5), lg(a_, 16) - lg(a_, 2)) for a_ in (2, 0.5, 7))),
        ("f(5) − f(3) = f(4) − f(2)", False, "左邊 = a^{3}(a^{2} − 1)，右邊 = a^{2}(a^{2} − 1)，a ≠ 1 時不相等",
         all(eq(a_ ** 5 - a_ ** 3, a_ ** 4 - a_ ** 2) for a_ in (2, 0.5))),
        ("y = g(x) 圖形上任兩點連線的斜率必為正", False, "0 < a < 1 時 g 是遞減，斜率是負的", lg(0.5, 3) > lg(0.5, 2)),
        ("對所有 x > 0，f(g(x)) = x", True, "a^{log_{a} x} = x", all(eq(a_ ** lg(a_, 3.7), 3.7) for a_ in (2, 0.5)))]),
    ("可以代一個 a 試試看。", [
        ("若 f(3) = 8，則 g(16) = 4", True, "a^{3} = 8，a = 2，log_{2} 16 = 4", eq(lg(2, 16), 4)),
        ("g(18) − g(2) = g(27) − g(3)", True, "兩邊都是 log_{a} 9", all(eq(lg(a_, 18) - lg(a_, 2), lg(a_, 27) - lg(a_, 3)) for a_ in (2, 0.5, 7))),
        ("f(4) − f(2) = f(3) − f(1)", False, "左邊 = a^{2}(a^{2} − 1)，右邊 = a(a^{2} − 1)，a ≠ 1 時不相等",
         all(eq(a_ ** 4 - a_ ** 2, a_ ** 3 - a_) for a_ in (2, 0.5))),
        ("y = f(x) 的圖形一定通過 (0, 1)", True, "a^{0} = 1", True),
        ("若 0 < a < 1，則 g(2) < g(3)", False, "0 < a < 1 時 g 是遞減，g(2) > g(3)", lg(0.5, 2) < lg(0.5, 3))]),
    ("可以代一個 a 試試看。", [
        ("若 g(9) = 2，則 f(3) = 27", True, "a^{2} = 9，a = 3，3^{3} = 27", eq(3 ** 3, 27)),
        ("g(12) + g(3) = g(6) + g(6)", True, "兩邊都是 log_{a} 36", all(eq(lg(a_, 12) + lg(a_, 3), 2 * lg(a_, 6)) for a_ in (2, 0.5, 7))),
        ("f(2) · f(3) = f(6)", False, "相乘是指數相加：f(2) · f(3) = f(5)", all(eq(a_ ** 5, a_ ** 6) for a_ in (2, 0.5))),
        ("y = g(x) 圖形上任兩點連線的斜率都不是 0", True, "g 不是一直遞增就是一直遞減，兩點的 y 不會一樣", True),
        ("f(x) 的值可以是 0", False, "a^{x} 一定是正的", False)]),
]

# ---------- j_digits ----------


def j_digits(m, n):
    A, B = 2 ** m, 3 ** n
    la, lb = m * L2, n * L3
    ka, kb = math.floor(la), math.floor(lb)
    assert ka == len(str(A)) - 1 and kb == len(str(B)) - 1
    ld = lead_digit(lb - kb)
    assert ld and int(str(B)[0]) == ld[0]
    d_, lo, hi = ld
    S = A + B
    big, small = (A, B) if A > B else (B, A)
    nd = len(str(S))
    assert nd == len(str(big))
    lab = la + lb
    assert math.floor(lab) == len(str(A * B)) - 1
    fa = la - ka
    big_t = lambda v: "%.1f × 10^{%d}" % (v / 10 ** (len(str(v)) - 1), len(str(v)) - 1)
    cards = [
        ("a 是 %d 位數" % (ka + 1), True, "log a = %d × 0.3010 = %s，首數 %d，所以是 %d 位數" % (m, ("%.2f" % la).rstrip("0").rstrip("."), ka, ka + 1), True),
        ("b 的最高位數字是 %d" % d_, True, "log b = %s，%s < %s < %s，介於 log %d 和 log %d 之間" % (tf3(lb), tf3(LG[lo]), tf3(lb - kb), tf3(LG[hi]), lo, hi), True),
        ("a + b 是 %d 位數" % (nd + 1), False, "%s ≈ %s，%s 小很多，加起來還是 %d 位數" % ("a" if A > B else "b", big_t(big), "b" if A > B else "a", nd), False),
        ("1/a 寫成小數，從小數點後第 %d 位開始不為 0" % ka, False, "log (1/a) = −%s = −%d + %s，從第 %d 位開始" % (("%.2f" % la).rstrip("0").rstrip("."), ka + 1, ("%.2f" % (1 - fa)).rstrip("0"), ka + 1), False),
        ("ab 是 %d 位數" % (math.floor(lab) + 1), True, "log ab = %s + %s = %s，首數 %d" % (("%.2f" % la).rstrip("0").rstrip("."), tf3(lb), tf3(lab), math.floor(lab)), True)]
    assert 1 / A < 10 ** -ka and 1 / A >= 10 ** -(ka + 1)
    return J("j_digits", 2, "位數與首位", 1.25,
             "已知 log 2 ≈ 0.3010，log 3 ≈ 0.4771。設 a = 2^{%d}，b = 3^{%d}。" % (m, n), "先算 log a、log b，再判斷。", cards)


# ---------- j_roots ----------


def rc(f, lo, hi):
    return nroots(f, lo, hi)


ROOTS = [
    [("x^{2} = 2^{x}", False, "x = 2、x = 4，再加上負數那邊還有一個，共 3 個", rc(lambda x: x * x - 2 ** x, -5, 10) == 2),
     ("2^{x} = x + 1", True, "x = 0 和 x = 1，凹口向上的曲線和直線最多交兩點", rc(lambda x: 2 ** x - x - 1, -8, 8) == 2),
     ("log_{2} x = x − 1", True, "x = 1 和 x = 2，正好是 B 卡對直線 y = x 鏡射的結果", rc(lambda x: lg(2, x) - x + 1, 0.001, 30) == 2),
     ("(1/2)^{x} = x", False, "左邊遞減、右邊遞增，只交一點", rc(lambda x: 0.5 ** x - x, -8, 8) == 2),
     ("2^{|x|} = 3", True, "x = ±log_{2} 3", rc(lambda x: 2 ** abs(x) - 3, -8, 8.01) == 2)],
    [("x^{2} = 4^{x}", False, "x > 0 時 4^{x} > x^{2}；只有負數那邊交一次", rc(lambda x: x * x - 4 ** x, -6, 6) == 2),
     ("3^{x} = 2x + 1", True, "x = 0 和 x = 1，凹口向上的曲線和直線最多交兩點", rc(lambda x: 3 ** x - 2 * x - 1, -8, 6) == 2),
     ("log_{3} x = (x − 1)/2", True, "x = 1 和 x = 3", rc(lambda x: lg(3, x) - (x - 1) / 2, 0.001, 40) == 2),
     ("(1/3)^{x} = x", False, "左邊遞減、右邊遞增，只交一點", rc(lambda x: (1 / 3) ** x - x, -6, 6) == 2),
     ("3^{|x|} = 5", True, "x = ±log_{3} 5", rc(lambda x: 3 ** abs(x) - 5, -6, 6.01) == 2)],
    [("2^{x} = −x", False, "左邊遞增、右邊遞減，只交一點", rc(lambda x: 2 ** x + x, -8, 8) == 2),
     ("2^{x} = 2x", True, "x = 1 和 x = 2", rc(lambda x: 2 ** x - 2 * x, -8, 8) == 2),
     ("log_{2} x = x/2", True, "x = 2 和 x = 4", rc(lambda x: lg(2, x) - x / 2, 0.001, 40) == 2),
     ("|log_{2} x| = 1", True, "x = 2 和 x = 1/2", rc(lambda x: abs(lg(2, x)) - 1, 0.001, 40) == 2),
     ("2^{x} = 1 − x", False, "左邊遞增、右邊遞減，只交在 x = 0", rc(lambda x: 2 ** x - 1 + x, -8, 8) == 2)],
]

# ---------- j_shift ----------

SHIFT = [
    ("f(x) = log_{2} x，g(x) = log_{2} (x + 2)，h(x) = log_{2} 4x，p(x) = 2 log_{2} x，q(x) = 2^{x + 2}。", [
        ("y = g(x) 的圖形可由 y = f(x) 平移得到", True, "向左平移 2 單位", True),
        ("y = h(x) 的圖形可由 y = f(x) 平移得到", True, "h(x) = 2 + log_{2} x，向上平移 2 單位", eq(lg(2, 4 * 3.3), 2 + lg(2, 3.3))),
        ("y = p(x) 的圖形可由 y = f(x) 平移得到", False, "p 是 f 的鉛直伸縮 2 倍", False),
        ("y = q(x) 對直線 y = x 鏡射後是 y = log_{2} x − 2", True, "x = 2^{y + 2}，所以 y = log_{2} x − 2", eq(2 ** (lg(2, 5.0) - 2 + 2), 5.0)),
        ("y = f(x)、y = h(x)、y = p(x) 的漸近線都相同", True, "漸近線都是 y 軸（x = 0）", True)]),
    ("f(x) = log_{3} x，g(x) = log_{3} (x − 1)，h(x) = log_{3} 9x，p(x) = 3 log_{3} x，q(x) = 3^{x − 1}。", [
        ("y = g(x) 的圖形可由 y = f(x) 平移得到", True, "向右平移 1 單位", True),
        ("y = h(x) 的圖形可由 y = f(x) 平移得到", True, "h(x) = 2 + log_{3} x，向上平移 2 單位", eq(lg(3, 9 * 2.3), 2 + lg(3, 2.3))),
        ("y = p(x) 的圖形可由 y = f(x) 平移得到", False, "p 是 f 的鉛直伸縮 3 倍", False),
        ("y = q(x) 對直線 y = x 鏡射後是 y = log_{3} x + 1", True, "x = 3^{y − 1}，所以 y = log_{3} x + 1", eq(3 ** (lg(3, 5.0) + 1 - 1), 5.0)),
        ("y = f(x)、y = g(x)、y = h(x) 的漸近線都相同", False, "g 的漸近線是 x = 1，其他是 y 軸", False)]),
    ("f(x) = log_{2} x，g(x) = log_{2} (x + 3)，h(x) = log_{2} (x/2)，p(x) = log_{2} x^{3}，q(x) = 2^{x} + 1。", [
        ("y = g(x) 的圖形可由 y = f(x) 平移得到", True, "向左平移 3 單位", True),
        ("y = h(x) 的圖形可由 y = f(x) 平移得到", True, "h(x) = log_{2} x − 1，向下平移 1 單位", eq(lg(2, 3.3 / 2), lg(2, 3.3) - 1)),
        ("y = p(x) 的圖形可由 y = f(x) 平移得到", False, "p(x) = 3 log_{2} x，是鉛直伸縮 3 倍", False),
        ("y = q(x) 對直線 y = x 鏡射後是 y = log_{2} x − 1", False, "x = 2^{y} + 1，所以 y = log_{2} (x − 1)", eq(lg(2, 5.0 - 1), lg(2, 5.0) - 1)),
        ("y = f(x)、y = h(x)、y = p(x) 的漸近線都相同", True, "漸近線都是 y 軸（x = 0）", True)]),
]

# ---------- j_ab ----------

AB = [
    ("2^{a} = 3，3^{b} = 4", lg(2, 3), lg(3, 4), [
        ("ab = 2", True, "a = log_{2} 3，b = log_{3} 4，連鎖得 log_{2} 4 = 2", eq(lg(2, 3) * lg(3, 4), 2)),
        ("a > 3/2", True, "2^{3/2} = 2√{2} ≈ 2.83 < 3", lg(2, 3) > 1.5),
        ("b > a", False, "b = log_{3} 4 < 3/2 < a（因為 3^{3/2} ≈ 5.2 > 4）", lg(3, 4) > lg(2, 3)),
        ("4^{a} = 9", True, "4^{a} = (2^{a})^{2} = 9", eq(4 ** lg(2, 3), 9)),
        ("8^{a} < 9^{b}", False, "8^{a} = 3^{3} = 27，9^{b} = 4^{2} = 16", 8 ** lg(2, 3) < 9 ** lg(3, 4))]),
    ("3^{a} = 5，5^{b} = 9", lg(3, 5), lg(5, 9), [
        ("ab = 2", True, "a = log_{3} 5，b = log_{5} 9，連鎖得 log_{3} 9 = 2", eq(lg(3, 5) * lg(5, 9), 2)),
        ("a > 3/2", False, "3^{3/2} = 3√{3} ≈ 5.2 > 5", lg(3, 5) > 1.5),
        ("b > 1", True, "9 > 5，所以 log_{5} 9 > log_{5} 5 = 1", lg(5, 9) > 1),
        ("9^{a} = 25", True, "9^{a} = (3^{a})^{2} = 25", eq(9 ** lg(3, 5), 25)),
        ("27^{a} < 25^{b}", False, "27^{a} = 5^{3} = 125，25^{b} = 9^{2} = 81", 27 ** lg(3, 5) < 25 ** lg(5, 9))]),
    ("5^{a} = 2，2^{b} = 25", lg(5, 2), lg(2, 25), [
        ("ab = 2", True, "a = log_{5} 2，b = log_{2} 25，連鎖得 log_{5} 25 = 2", eq(lg(5, 2) * lg(2, 25), 2)),
        ("a < 1/2", True, "5^{1/2} = √{5} ≈ 2.24 > 2", lg(5, 2) < 0.5),
        ("b > 4", True, "2^{4} = 16 < 25", lg(2, 25) > 4),
        ("25^{a} = 4", True, "25^{a} = (5^{a})^{2} = 4", eq(25 ** lg(5, 2), 4)),
        ("125^{a} > 32^{b}", False, "125^{a} = 2^{3} = 8，32^{b} = 25^{5}", 125 ** lg(5, 2) > 32 ** lg(2, 25))]),
]

# ---------- j_big ----------


def j_big(n):
    X = 6 ** n
    l6 = L2 + L3
    lx = n * l6
    k = math.floor(lx)
    assert k == len(str(X)) - 1
    ld = lead_digit(lx - k)
    assert ld and int(str(X)[0]) == ld[0]
    d_, lo, hi = ld
    neg = 1 - (lx - k)
    ld2 = lead_digit(neg)
    assert ld2
    inv = str(10 ** (k + 30) // X).rjust(k + 30, "0")
    first = next(i for i, ch_ in enumerate(inv) if ch_ != "0")
    assert first + 1 == k + 1 and int(inv[first]) == ld2[0]
    fr = lambda v: "0" + ("%.3f" % v)[("%.3f" % v).index("."):]
    cards = [
        ("x 是 %d 位數" % (k + 1), True, "log x = %d × 0.7781 = %s，首數 %d" % (n, ("%.4f" % lx).rstrip("0"), k), True),
        ("x 的最高位數字是 %d" % (d_ + 1), False, "%s < %s < %s，最高位數字是 %d" % (fr(LG[lo]) if lo != 1 else "0", fr(lx - k), fr(LG[hi]), d_), False),
        ("x = 10^{%d log 6}" % n, True, "10^{log x} = x，而 log x = %d log 6" % n, True),
        ("1/x 寫成小數，從小數點後第 %d 位開始不為 0" % k, False, "log (1/x) = −%d + %s，從第 %d 位開始" % (k + 1, fr(neg), k + 1), False),
        ("1/x 小數點後第一個不為 0 的數字是 %d" % ld2[0], True, "%s < %s < %s，介於 log %d 和 log %d 之間" % (fr(LG[ld2[1]]) if ld2[1] != 1 else "0", fr(neg), fr(LG[ld2[2]]), ld2[1], ld2[2]), True)]
    return J("j_big", 3, "大數的首尾", 1.25, "已知 log 2 ≈ 0.3010，log 3 ≈ 0.4771。設 x = 6^{%d}。" % n,
             "log 6 = log 2 + log 3 ≈ 0.7781。", cards)


def items():
    return [
        [J("j_rules", 1, "對數性質", 1.0, "下列關於對數的運算，哪些正確？", "逐一判斷每張卡片的真假。", c) for c in RULES],
        [J("j_value", 1, "對數求值", 1.0, "下列各式的值，哪些正確？", "逐一判斷每張卡片的真假。", c) for c in VALUE],
        [J("j_expcmp", 1, "指數大小", 1.0, "下列大小關係，哪些正確？", "先看底數大於 1 還是小於 1。", c) for c in EXPCMP],
        [j_curve(b, xs, c, xr, yr) for b, xs, xr, yr, c in CURVE],
        [J("j_logcmp", 2, "對數大小", 1.1, "下列大小關係，哪些正確？", "換成同底數，或拿 0、1 當中間值。", c) for c in LOGCMP],
        [J("j_graph", 2, "圖形的對稱與平移", 1.1, "下列關於圖形的敘述，哪些正確？", "想一想每個圖形怎麼變過來的。", c) for c in GRAPH],
        [J("j_fg", 2, "指對互換", 1.1, "設 a > 0 且 a ≠ 1，f(x) = a^{x}，g(x) = log_{a} x。下列敘述哪些正確？", q, c) for q, c in FG],
        [j_digits(40, 20), j_digits(50, 30), j_digits(30, 25)],
        [J("j_roots", 3, "交點的個數", 1.25, "下列各方程式，哪些恰有兩個相異實根？", "在腦中畫出兩邊的圖形，數交點。", c) for c in ROOTS],
        [J("j_shift", 3, "平移與鏡射", 1.25, s, "把每個函數都化成 f(x) 的變形。", c) for s, c in SHIFT],
        [J("j_ab", 3, "指數條件", 1.25, "設 %s。下列敘述哪些正確？" % s, "先把 a、b 寫成對數。", c) for s, _, _, c in AB],
        [j_big(20), j_big(30), j_big(15)],
    ]
