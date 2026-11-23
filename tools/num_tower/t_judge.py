# 審判台：段考的五選題，一張一張判斷
from nlib import *

S = math.sqrt
VALS = [-3, -2, -1, -0.5, 0, 0.5, 1, 2, 3, S(2), -S(2), 2.5]


def _all3():
    for a_ in VALS:
        for b_ in VALS:
            for c_ in VALS:
                yield a_, b_, c_


def holds(hyp, concl):
    """對 VALS 裡所有 (a, b, c) 都成立嗎（找反例）"""
    for a_, b_, c_ in _all3():
        try:
            if hyp(a_, b_, c_) and not concl(a_, b_, c_):
                return False
        except (ValueError, ZeroDivisionError):
            continue
    return True


# ---------- nj_real：實數的性質 ----------

REAL = {
    1: ("若 a > b，則 ac > bc", lambda a, b, c: a > b, lambda a, b, c: a * c > b * c, "c ≤ 0 時不成立，例如 c = −1：a > b 但 −a < −b"),
    2: ("若 a > b 且 c > 0，則 ac > bc", lambda a, b, c: a > b and c > 0, lambda a, b, c: a * c > b * c, "兩邊乘正數，不等號方向不變"),
    3: ("對所有實數 a、b，只要 √{ab} 有意義，\\frac{a + b}{2} ≥ √{ab}", lambda a, b, c: a * b >= 0, lambda a, b, c: (a + b) / 2 >= S(a * b) - 1e-12,
        "a、b 都是負數時不成立，例如 a = b = −1：左邊 −1，右邊 1"),
    4: ("若 a ≥ 0、b ≥ 0，則 \\frac{a + b}{2} ≥ √{ab}", lambda a, b, c: a >= 0 and b >= 0, lambda a, b, c: (a + b) / 2 >= S(a * b) - 1e-12,
        "(√{a} − √{b})^{2} ≥ 0 展開就是算幾不等式"),
    5: ("若 |a| > b，則 a^{2} > b^{2}", lambda a, b, c: abs(a) > b, lambda a, b, c: a * a > b * b, "b 可能是負的，例如 a = 1、b = −3"),
    6: ("若 |a| > |b|，則 a^{2} > b^{2}", lambda a, b, c: abs(a) > abs(b), lambda a, b, c: a * a > b * b, "兩邊都是非負數，平方後不等號方向不變"),
    7: ("若 a > b > 0，則 \\frac{1}{a} < \\frac{1}{b}", lambda a, b, c: a > b > 0, lambda a, b, c: 1 / a < 1 / b, "兩邊同除以正數 ab"),
    8: ("若 a > b，則 \\frac{1}{a} < \\frac{1}{b}", lambda a, b, c: a > b and a * b != 0, lambda a, b, c: 1 / a < 1 / b, "a、b 異號時不成立，例如 a = 1、b = −1"),
    9: ("若 a > b，則 a^{3} > b^{3}", lambda a, b, c: a > b, lambda a, b, c: a ** 3 > b ** 3, "y = x^{3} 一直遞增；a^{3} − b^{3} = (a − b)(a^{2} + ab + b^{2})"),
    10: ("若 a > b，則 a^{2} > b^{2}", lambda a, b, c: a > b, lambda a, b, c: a * a > b * b, "例如 a = 1、b = −2：1 < 4"),
    11: ("若 a、b 都是正數，則 a + b ≥ 2√{ab}", lambda a, b, c: a > 0 and b > 0, lambda a, b, c: a + b >= 2 * S(a * b) - 1e-12, "算幾不等式兩邊乘 2"),
}


def nj_real(keys):
    cards = []
    for k in keys:
        s, h, c, why = REAL[k]
        ok = holds(h, c)
        cards.append(cardc(s, ok, why, ok))
    return item("nj_real", "judge", 1, "實數的性質", 1.0, "a、b、c 是實數。下列敘述哪些正確？",
                [jd("錯的敘述找一個反例：負數、0 最常讓人出錯。", cards)])


# ---------- nj_rational：有理還是無理 ----------

RAT = {
    "A": ("若 a^{8}、a^{13} 都是有理數，則 a 是有理數", True, "a ≠ 0 時 a^{5} = \\frac{a^{13}}{a^{8}}、a^{3} = \\frac{a^{8}}{a^{5}}、a^{2}、a 依序都是有理數"),
    "B": ("若 a^{4}、a^{8} 都是有理數，則 a 是有理數", False, "a = ∜{2}：a^{4} = 2、a^{8} = 4，但 a 是無理數"),
    "C": ("若 a^{6}、a^{10} 都是有理數，則 a 是有理數", False, "a = √{2}：a^{6} = 8、a^{10} = 32，但 a 是無理數"),
    "D": ("若 a^{9}、a^{14} 都是有理數，則 a 是有理數", True, "9、14 互質：a^{5} = \\frac{a^{14}}{a^{9}}、a^{4}、a 依序相除都是有理數"),
    "E": ("任兩個相異有理數之間一定有無理數", True, "例如 p < q 時，p + \\frac{q − p}{√{2}} 在兩數之間，而且是無理數"),
    "F": ("兩個無理數的和一定是無理數", False, "√{2} + (−√{2}) = 0"),
    "G": ("兩個無理數的積一定是無理數", False, "√{2} × √{2} = 2"),
    "H": ("有理數加無理數一定是無理數", True, "若 r + x = s 是有理數，x = s − r 也是有理數，矛盾"),
    "I": ("若 a、b、c、d 是有理數，a√{3} + b√{12} = c√{3} + d√{12}，則 a = c、b = d", False,
          "√{12} = 2√{3}，只能推出 a + 2b = c + 2d，例如 a = 2、b = 0、c = 0、d = 1"),
    "J": ("若 a、b、c、d 是有理數，a + b√{3} = c + d√{3}，則 a = c、b = d", True, "若 b ≠ d，√{3} = \\frac{a − c}{d − b} 會是有理數，矛盾"),
    "K": ("若 a + b 是有理數，則 ab 是有理數", False, "a = √{2}、b = 1 − √{2}：a + b = 1，ab = √{2} − 2"),
    "L": ("非零有理數乘以無理數一定是無理數", True, "若 rx = s 是有理數，x = \\frac{s}{r} 也是有理數，矛盾"),
    "M": ("任兩個相異無理數之間一定有有理數", True, "實數的稠密性：兩數之間一定有有理數"),
}


def nj_rational(keys):
    cards = [cardc(RAT[k][0], RAT[k][1], RAT[k][2], RAT[k][1]) for k in keys]
    return item("nj_rational", "judge", 2, "有理還是無理", 1.1, "下列敘述哪些正確？",
                [jd("錯的找反例（√{2} 最好用）；對的想想「有理數的四則運算封閉」。", cards)])


# ---------- nj_truefalse：建中是非題 ----------

def nj_truefalse(cards_spec):
    cards = []
    for s, ok, why, check in cards_spec:
        if check is not None:
            assert bool(check()) == ok, s
        cards.append(cardc(s, ok, why, ok))
    return item("nj_truefalse", "judge", 2, "建中是非題", 1.1, "下列敘述哪些正確？",
                [jd("√{x} 一定 ≥ 0；分母不能是 0；不循環的無限小數才是無理數。", cards)])


# ---------- nj_nosol：哪些無解 ----------

def nj_nosol(u, v, specs):
    D = u - v
    def f(x):
        return abs(x - u) + abs(x - v)
    def g(x):
        return abs(x - u) - abs(x - v)
    xs = [F(i, 24) for i in range(-24 * 40, 24 * 40 + 1)]
    ft = "|x %s %s| + |x %s %s|" % ("−" if u > 0 else "+", t(abs(u)), "−" if v > 0 else "+", t(abs(v)))
    gt = ft.replace(" + |", " − |", 1)
    cards = []
    for which, op, r in specs:
        fn = f if which == "f" else g
        has = any(OPS2[op](fn(x), r) for x in xs)
        nos = not has
        if which == "f":
            why = "%s 是數線上 x 到 %s、%s 的距離和，最小值 %d" % (ft, t(u), t(v), D)
        else:
            why = "%s 是距離差，範圍 −%d ≤ … ≤ %d" % (gt, D, D)
        why += "，%s" % ("所以無解" if nos else "有解")
        cards.append(cardc("%s %s %s 無解" % (ft if which == "f" else gt, op, t(r)), nos, why, nos))
    return item("nj_nosol", "judge", 2, "哪些無解", 1.15, "下列方程式或不等式，哪些無解？",
                [fl("先求兩個式子的範圍：", "%s 的最小值 [0]；[1] ≤ %s ≤ [2]" % (ft, gt), [str(D), str(-D), str(D)],
                    "看成數線上 x 到 %s、%s 兩點的距離" % (t(u), t(v))),
                 jd("右邊的數在範圍外才無解。", cards)])


OPS2 = {"=": lambda a_, b_: a_ == b_, "<": lambda a_, b_: a_ < b_, ">": lambda a_, b_: a_ > b_,
        "≤": lambda a_, b_: a_ <= b_, "≥": lambda a_, b_: a_ >= b_}


# ---------- nj_weight：數線上的加權點 ----------

def nj_weight(Ct, Dt, cards_spec):
    pairs = [(F(i), F(j)) for i in range(-5, 6) for j in range(-5, 6) if i < j]
    cards = []
    for s, ok, why, pred, pos in cards_spec:
        if pred is not None:
            ps = [(a_, b_) for a_, b_ in pairs if (a_ > 0 or not pos)]
            truth = all(pred(a_, b_) for a_, b_ in ps)
            assert truth == ok, s
        cards.append(cardc(s, ok, why, ok))
    return item("nj_weight", "judge", 2, "數線上的加權點", 1.15,
                "數線上 A(a)、B(b)，a < b。C(%s)、D(%s)。下列敘述哪些正確？" % (Ct, Dt),
                [jd("係數都是正的、加起來是 1，點才在 A、B 之間；b 的係數越大越靠近 B。", cards)])


# ---------- nj_compare：比大小審判 ----------

def nj_compare(specs):
    cards = []
    for s, why, expr in specs:
        ok = bool(expr())
        cards.append(cardc(s, ok, why, ok))
    return item("nj_compare", "judge", 2, "比大小審判", 1.15, "下列敘述哪些正確？",
                [jd("根號和：平方後比；根號差：看倒數；\\frac{x + y}{2} 和 √{xy}：用算幾。", cards)])


def items():
    return [
        [nj_real([1, 4, 5, 7, 9]), nj_real([2, 3, 6, 8, 11]), nj_real([10, 4, 6, 1, 9])],
        [nj_rational("ABEFI"), nj_rational("DCHGJ"), nj_rational("KLMFD")],
        [nj_truefalse([
            ("\\frac{2025 + 2026}{2} > √{2025 × 2026}", True, "兩數不相等，算術平均 > 幾何平均", lambda: (2025 + 2026) / 2 > S(2025 * 2026)),
            ("√{5 − 2√{6}} = √{2} − √{3}", False, "√{2} − √{3} < 0，應該是 √{3} − √{2}", lambda: near(S(5 - 2 * S(6)), S(2) - S(3))),
            ("\\frac{1 − 0.\\ol{9}}{1 − 0.\\ol{9}} = 1", False, "0.\\ol{9} = 1，分母是 0，沒有意義", None),
            ("0.1010010001…（1 之間的 0 越來越多）是無理數", True, "不循環的無限小數", None),
            ("√{2 + √{2 + √{2}}} 是實數", True, "每一層根號裡都是正數", None)]),
         nj_truefalse([
            ("\\frac{1999 + 2001}{2} > √{1999 × 2001}", True, "兩數不相等，算術平均 > 幾何平均", lambda: 2000 > S(1999 * 2001)),
            ("√{7 − 2√{10}} = √{5} − √{2}", True, "√{5} > √{2}，而且 (√{5} − √{2})^{2} = 7 − 2√{10}", lambda: near(S(7 - 2 * S(10)), S(5) - S(2))),
            ("0.\\ol{9} < 1", False, "0.\\ol{9} = \\frac{9}{9} = 1", None),
            ("0.\\ol{142857} 是無理數", False, "循環小數是有理數，它等於 \\frac{1}{7}", lambda: rep(0, "", "142857") != F(1, 7)),
            ("√{3 − √{8}} = √{2} − 1", True, "(√{2} − 1)^{2} = 3 − 2√{2} = 3 − √{8}，而且 √{2} − 1 > 0", lambda: near(S(3 - S(8)), S(2) - 1))]),
         nj_truefalse([
            ("\\frac{2024 + 2024}{2} > √{2024 × 2024}", False, "兩數相等時，算術平均 = 幾何平均", lambda: 2024 > S(2024 * 2024)),
            ("√{8 − 2√{15}} = √{3} − √{5}", False, "√{3} − √{5} < 0，應該是 √{5} − √{3}", lambda: near(S(8 - 2 * S(15)), S(3) - S(5))),
            ("0.12112111211112…（2 之間的 1 越來越多）是無理數", True, "不循環的無限小數", None),
            ("\\frac{0.\\ol{3}}{0.\\ol{6}} = \\frac{1}{2}", True, "\\frac{3/9}{6/9} = \\frac{3}{6}", lambda: rep(0, "", "3") / rep(0, "", "6") == F(1, 2)),
            ("√{4 − √{12}} = √{3} − 1", True, "(√{3} − 1)^{2} = 4 − 2√{3} = 4 − √{12}，而且 √{3} − 1 > 0", lambda: near(S(4 - S(12)), S(3) - 1))])],
        [nj_nosol(2, -5, [("f", "=", 6), ("f", "=", 7), ("g", "=", 8), ("g", "=", -7), ("f", "<", 7)]),
         nj_nosol(1, -3, [("f", "<", 4), ("f", "=", 5), ("g", "=", 4), ("g", ">", 4), ("f", "≤", 3)]),
         nj_nosol(4, -2, [("f", "=", 5), ("g", "<", -6), ("g", "=", 0), ("f", ">", 100), ("f", "≤", 6)])],
        [nj_weight("\\frac{2a + 3b}{5}", "\\frac{3a + 5b}{8}", [
            ("C 在 D 的左邊", True, "b 的係數 \\frac{3}{5} < \\frac{5}{8}，D 比較靠近 B", lambda a_, b_: (2 * a_ + 3 * b_) / 5 < (3 * a_ + 5 * b_) / 8, False),
            ("C 在 \\ol{AB} 上", True, "係數 \\frac{2}{5}、\\frac{3}{5} 都是正的，加起來是 1", lambda a_, b_: a_ <= (2 * a_ + 3 * b_) / 5 <= b_, False),
            ("\\ol{AC} : \\ol{CB} = 2 : 3", False, "\\ol{AC} : \\ol{CB} = 3 : 2（b 的份數 3 多，C 靠近 B）", lambda a_, b_: ((2 * a_ + 3 * b_) / 5 - a_) * 3 == (b_ - (2 * a_ + 3 * b_) / 5) * 2, False),
            ("E(\\frac{2a + 3b}{4}) 一定在 A、B 之間", False, "係數和 \\frac{5}{4} ≠ 1，例如 a = 2、b = 3：E = \\frac{13}{4} > 3", lambda a_, b_: a_ <= (2 * a_ + 3 * b_) / 4 <= b_, False),
            ("若 0 < a < b，則 √{ab} 在 A、B 之間", True, "a = √{a · a} < √{ab} < √{b · b} = b", lambda a_, b_: a_ <= S(a_ * b_) <= b_, True)]),
         nj_weight("\\frac{3a + b}{4}", "\\frac{5a + 2b}{7}", [
            ("C 在 D 的右邊", False, "b 的係數 \\frac{1}{4} < \\frac{2}{7}，C 在 D 的左邊", lambda a_, b_: (3 * a_ + b_) / 4 > (5 * a_ + 2 * b_) / 7, False),
            ("D 在 \\ol{AB} 上", True, "係數 \\frac{5}{7}、\\frac{2}{7} 都是正的，加起來是 1", lambda a_, b_: a_ <= (5 * a_ + 2 * b_) / 7 <= b_, False),
            ("\\ol{AD} : \\ol{DB} = 2 : 5", True, "D 離 A 的距離是 \\frac{2}{7}(b − a)，離 B 是 \\frac{5}{7}(b − a)",
             lambda a_, b_: ((5 * a_ + 2 * b_) / 7 - a_) * 5 == (b_ - (5 * a_ + 2 * b_) / 7) * 2, False),
            ("\\frac{a + b}{2} 在 C 和 D 之間", False, "C、D 的 b 係數都小於 \\frac{1}{2}，兩點都在中點左邊",
             lambda a_, b_: min((3 * a_ + b_) / 4, (5 * a_ + 2 * b_) / 7) <= (a_ + b_) / 2 <= max((3 * a_ + b_) / 4, (5 * a_ + 2 * b_) / 7), False),
            ("若 0 < a < b，則 \\frac{2ab}{a + b} 在 A、B 之間", True, "\\frac{2ab}{a + b} − a = \\frac{a(b − a)}{a + b} > 0，b − \\frac{2ab}{a + b} = \\frac{b(b − a)}{a + b} > 0",
             lambda a_, b_: a_ <= 2 * a_ * b_ / (a_ + b_) <= b_, True)]),
         nj_weight("\\frac{4a + 5b}{9}", "\\frac{2a + 3b}{5}", [
            ("C 在 D 的左邊", True, "b 的係數 \\frac{5}{9} < \\frac{3}{5}", lambda a_, b_: (4 * a_ + 5 * b_) / 9 < (2 * a_ + 3 * b_) / 5, False),
            ("\\ol{AC} : \\ol{CB} = 5 : 4", True, "C 離 A 是 \\frac{5}{9}(b − a)，離 B 是 \\frac{4}{9}(b − a)",
             lambda a_, b_: ((4 * a_ + 5 * b_) / 9 - a_) * 4 == (b_ - (4 * a_ + 5 * b_) / 9) * 5, False),
            ("E(\\frac{a + 3b}{3}) 一定在 A、B 之間", False, "係數和 \\frac{4}{3} ≠ 1，例如 a = 1、b = 2：E = \\frac{7}{3} > 2", lambda a_, b_: a_ <= (a_ + 3 * b_) / 3 <= b_, False),
            ("C 比 D 靠近 B", False, "C 在 D 的左邊，D 比較靠近 B", lambda a_, b_: b_ - (4 * a_ + 5 * b_) / 9 < b_ - (2 * a_ + 3 * b_) / 5, False),
            ("若 0 < a < b，給定單位長，可以用尺規作出長度 ∜{ab} 的線段", True, "先用半圓作出 √{ab}，再作 √{1 × √{ab}}", None, True)])],
        [nj_compare([
            ("√{5} + 2√{2} < √{6} + √{7}", "平方後：13 + 2√{40} < 13 + 2√{42}", lambda: S(5) + 2 * S(2) < S(6) + S(7)),
            ("\\frac{5^{6} + 7^{6}}{2} > 35^{3}", "算幾：\\frac{5^{6} + 7^{6}}{2} > √{5^{6} × 7^{6}} = 35^{3}（兩數不相等）", lambda: (5 ** 6 + 7 ** 6) / 2 > 35 ** 3),
            ("√{7} − √{3} < √{17} − √{13}", "倒數：\\frac{√{7} + √{3}}{4} < \\frac{√{17} + √{13}}{4}，所以 √{7} − √{3} 比較大", lambda: S(7) - S(3) < S(17) - S(13)),
            ("\\frac{3^{4} + 5^{4}}{2} < 15^{2}", "算幾：\\frac{3^{4} + 5^{4}}{2} > √{3^{4} × 5^{4}} = 15^{2}", lambda: (3 ** 4 + 5 ** 4) / 2 < 15 ** 2),
            ("若 a > b > 0，則 \\frac{2a + b}{3} > \\frac{a + 2b}{3}", "相減：\\frac{a − b}{3} > 0", lambda: (2 * 3 + 1) / 3 > (3 + 2) / 3)]),
         nj_compare([
            ("√{3} + √{10} > √{5} + √{8}", "平方後：13 + 2√{30} < 13 + 2√{40}", lambda: S(3) + S(10) > S(5) + S(8)),
            ("\\frac{2^{8} + 3^{8}}{2} > 6^{4}", "算幾：\\frac{2^{8} + 3^{8}}{2} > √{2^{8} × 3^{8}} = 6^{4}", lambda: (2 ** 8 + 3 ** 8) / 2 > 6 ** 4),
            ("√{10} − √{6} > √{14} − √{10}", "倒數：\\frac{√{10} + √{6}}{4} < \\frac{√{14} + √{10}}{4}", lambda: S(10) - S(6) > S(14) - S(10)),
            ("2√{3} > √{5} + √{2}", "平方後：12 < 7 + 2√{10}（2√{10} > 5）", lambda: 2 * S(3) > S(5) + S(2)),
            ("\\frac{5 + 7}{2} > √{35}", "算幾，5 ≠ 7", lambda: 6 > S(35))]),
         nj_compare([
            ("√{2} + √{13} < √{7} + √{8}", "平方後：15 + 2√{26} < 15 + 2√{56}", lambda: S(2) + S(13) < S(7) + S(8)),
            ("\\frac{4^{5} + 9^{5}}{2} < 6^{5}", "算幾：\\frac{4^{5} + 9^{5}}{2} > √{4^{5} × 9^{5}} = 6^{5}", lambda: (4 ** 5 + 9 ** 5) / 2 < 6 ** 5),
            ("√{19} − √{15} > √{11} − √{7}", "倒數：\\frac{√{19} + √{15}}{4} > \\frac{√{11} + √{7}}{4}，所以 √{19} − √{15} 比較小", lambda: S(19) - S(15) > S(11) - S(7)),
            ("√{11} − √{10} < √{10} − 3", "倒數：√{11} + √{10} > √{10} + 3", lambda: S(11) - S(10) < S(10) - 3),
            ("3√{3} > 2√{6}", "平方後：27 > 24", lambda: 3 * S(3) > 2 * S(6))])],
    ]
