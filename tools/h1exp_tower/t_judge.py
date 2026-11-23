# 審判台：指數、對數的五選題
from xlib import *

AS = [0.01, 0.3, 0.5, 1.0, 2.0, 7.5, 40.0, 1234.0]


def every(f):
    """a、b 取一堆正數都成立嗎"""
    return all(f(a_, b_) for a_ in AS for b_ in AS)


# ---------- xj_log10：10 的 log a 次方 ----------

def xj_log10(specs):
    cards = []
    for s, why, f in specs:
        ok = every(f)
        cards.append(cardc(s, ok, why, ok))
    return item("xj_log10", "judge", 1, "10 的 log a 次方", 1.0, "a、b 都是正數。下列敘述哪些正確？",
                [jd("10^{log a} = a；log 的乘法變加法、次方變係數；log 本身可能是負的。", cards)])


# ---------- xj_conj：a = 2^{√3} + 2^{−√3} ----------

def xj_conj(b, r, specs):
    u = b ** S(r)
    av = u + 1 / u
    cards = jcards([(s, why, (lambda f=f: f(u, av))) for s, why, f in specs])
    return item("xj_conj", "judge", 2, "指數的倒數和", 1.15,
                "設 a = %d^{√{%d}} + %d^{−√{%d}}。下列敘述哪些正確？" % (b, r, b, r),
                [jd("令 t = %d^{√{%d}}，a = t + t^{−1}；t > 1。" % (b, r), cards)])


# ---------- xj_defined：有沒有意義 ----------

def xj_defined(specs):
    cards = [cardc(s, ok, why, ok) for s, ok, why in specs]
    return item("xj_defined", "judge", 2, "有沒有意義", 1.1, "下列敘述哪些正確？",
                [jd("課本的分數指數、無理數指數，底數都要是正數；log 的真數也要是正數。", cards)])


# ---------- xj_table：用 log 2、log 3 判斷 ----------

def xj_table(specs):
    return item("xj_table", "judge", 1, "指數與 log 的轉換", 1.05, "下列敘述哪些正確？",
                [jd("10^{x} = N 和 x = log N 是同一件事；10^{m log N} = N^{m}。", jcards(specs))])


# ---------- xj_truefalse：建中是非題 ----------

def xj_truefalse(specs):
    return item("xj_truefalse", "judge", 1, "建中是非題", 1.05, "下列敘述哪些正確？",
                [jd("底數大於 1，指數越大值越大；底數在 0 和 1 之間，指數越大值越小。", jcards(specs))])


# ---------- xj_compare：指數比大小 ----------

def xj_compare(specs):
    return item("xj_compare", "judge", 2, "指數比大小審判", 1.15, "下列敘述哪些正確？",
                [jd("分數次方比大小：兩邊同時乘到整數次方（分母的最小公倍數）。", jcards(specs))])


def items():
    return [
        [xj_log10([("10^{log a} = a", "log a 就是「10 的幾次方等於 a」", lambda a_, b_: near(10 ** lg(a_), a_, 1e-9 * a_)),
                   ("log a 一定是正數", "0 < a < 1 時 log a < 0，例如 log 0.5 ≈ −0.3", lambda a_, b_: lg(a_) > 0),
                   ("log 10^{log a} = log a", "log 10^{x} = x", lambda a_, b_: near(lg(10 ** lg(a_)), lg(a_))),
                   ("10^{−log a} = \\frac{1}{a}", "10^{−log a} = (10^{log a})^{−1}", lambda a_, b_: near(10 ** -lg(a_), 1 / a_, 1e-9 / a_)),
                   ("10^{2 log a} = 2a", "10^{2 log a} = (10^{log a})^{2} = a^{2}", lambda a_, b_: near(10 ** (2 * lg(a_)), 2 * a_, 1e-9 * a_))]),
         xj_log10([("10^{\\frac{1}{2} log a} = √{a}", "(10^{log a})^{\\frac{1}{2}}", lambda a_, b_: near(10 ** (lg(a_) / 2), S(a_), 1e-9 * S(a_))),
                   ("log (10a) = 10 log a", "log (10a) = 1 + log a", lambda a_, b_: near(lg(10 * a_), 10 * lg(a_))),
                   ("(10^{log a})^{2} = a^{2}", "10^{log a} = a", lambda a_, b_: near((10 ** lg(a_)) ** 2, a_ * a_, 1e-9 * a_ * a_)),
                   ("10^{log a + 1} = 10a", "10^{log a} × 10^{1}", lambda a_, b_: near(10 ** (lg(a_) + 1), 10 * a_, 1e-9 * a_)),
                   ("log a^{2} = (log a)^{2}", "log a^{2} = 2 log a；例如 a = 1000：6 ≠ 9", lambda a_, b_: near(lg(a_ * a_), lg(a_) ** 2))]),
         xj_log10([("若 a < 1，則 log a < 0", "10^{x} < 1 時 x < 0", lambda a_, b_: a_ >= 1 or lg(a_) < 0),
                   ("10^{log a} × 10^{log b} = ab", "10^{log a} = a、10^{log b} = b", lambda a_, b_: near(10 ** lg(a_) * 10 ** lg(b_), a_ * b_, 1e-9 * a_ * b_)),
                   ("log (a + b) = log a × log b", "log ab = log a + log b，沒有 log (a + b) 的公式；例如 a = b = 1：log 2 ≠ 0", lambda a_, b_: near(lg(a_ + b_), lg(a_) * lg(b_))),
                   ("\\frac{log a}{log b} = log \\frac{a}{b}（b ≠ 1）", "log \\frac{a}{b} = log a − log b，不是相除", lambda a_, b_: b_ == 1 or near(lg(a_) / lg(b_), lg(a_ / b_))),
                   ("10^{3 log a} = a^{3}", "(10^{log a})^{3}", lambda a_, b_: near(10 ** (3 * lg(a_)), a_ ** 3, 1e-9 * a_ ** 3))])],
        [xj_conj(2, 3, [("4^{√{3}} + 4^{−√{3}} = a^{2} − 2", "t^{2} + t^{−2} = (t + t^{−1})^{2} − 2", lambda u, av: near(u * u + 1 / (u * u), av * av - 2)),
                        ("8^{√{3}} + 8^{−√{3}} = a^{3} − 3a", "t^{3} + t^{−3} = (t + t^{−1})^{3} − 3(t + t^{−1})", lambda u, av: near(u ** 3 + u ** -3, av ** 3 - 3 * av)),
                        ("(\\frac{1}{2})^{√{3}} + 2^{√{3}} = a", "(\\frac{1}{2})^{√{3}} = 2^{−√{3}}", lambda u, av: near(0.5 ** S(3) + u, av)),
                        ("2^{√{3}} − 2^{−√{3}} = √{a^{2} − 4}", "(t − t^{−1})^{2} = a^{2} − 4，而且 t > 1，t − t^{−1} > 0", lambda u, av: near(u - 1 / u, S(av * av - 4))),
                        ("a < 2", "t + t^{−1} ≥ 2（算幾），t ≠ 1 所以 a > 2", lambda u, av: av < 2)]),
         xj_conj(3, 2, [("9^{√{2}} + 9^{−√{2}} = a^{2} + 2", "t^{2} + t^{−2} = a^{2} − 2，不是 + 2", lambda u, av: near(u * u + 1 / (u * u), av * av + 2)),
                        ("27^{√{2}} + 27^{−√{2}} = a^{3} − 3a", "t^{3} + t^{−3} = a^{3} − 3a", lambda u, av: near(u ** 3 + u ** -3, av ** 3 - 3 * av)),
                        ("3^{√{2}} − 3^{−√{2}} = √{a^{2} − 4}", "(t − t^{−1})^{2} = a^{2} − 4，t − t^{−1} > 0", lambda u, av: near(u - 1 / u, S(av * av - 4))),
                        ("a > 2", "算幾：t + t^{−1} ≥ 2，t ≠ 1", lambda u, av: av > 2),
                        ("(\\frac{1}{3})^{√{2}} = a − 3^{√{2}}", "(\\frac{1}{3})^{√{2}} = 3^{−√{2}}", lambda u, av: near((1 / 3) ** S(2), av - u))]),
         xj_conj(5, 5, [("25^{√{5}} + 25^{−√{5}} = a^{2} − 2", "(t + t^{−1})^{2} = t^{2} + 2 + t^{−2}", lambda u, av: near(u * u + 1 / (u * u), av * av - 2, 1e-6 * av * av)),
                        ("125^{√{5}} + 125^{−√{5}} = a^{3} − 2a", "t^{3} + t^{−3} = a^{3} − 3a，不是 − 2a", lambda u, av: near(u ** 3 + u ** -3, av ** 3 - 2 * av, 1e-6 * av ** 3)),
                        ("5^{−√{5}} − 5^{√{5}} = √{a^{2} − 4}", "t > 1，t^{−1} − t < 0，但根號 ≥ 0", lambda u, av: near(1 / u - u, S(av * av - 4), 1e-6 * av)),
                        ("a ≥ 2", "算幾：t + t^{−1} ≥ 2", lambda u, av: av >= 2),
                        ("a^{2} = 25^{√{5}} + 25^{−√{5}} + 2", "(t + t^{−1})^{2} = t^{2} + t^{−2} + 2", lambda u, av: near(av * av, u * u + 1 / (u * u) + 2, 1e-6 * av * av))])],
        [xj_defined([("(−2)^{−√{3}} 有意義", False, "負數的無理數次方沒有定義"),
                     ("若 a > 0 且 a^{\\frac{1}{2}} + a^{−\\frac{1}{2}} = 2，則 a = 1", True, "(a^{\\frac{1}{4}} − a^{−\\frac{1}{4}})^{2} = 0，或用算幾的等號"),
                     ("(−2)^{\\frac{1}{6}} 是實數", False, "負數開偶次方根不是實數"),
                     ("10^{n log 2} = 2^{n}", True, "10^{n log 2} = (10^{log 2})^{n}"),
                     ("log (−2)^{2} + log 3^{2} = log (−2 × 3)^{2}", True, "左邊 = log 4 + log 9 = log 36，右邊 = log 36")]),
         xj_defined([("∛{−8} = −2", True, "(−2)^{3} = −8，奇次方根可以開負數"),
                     ("(−8)^{\\frac{1}{3}} 有意義", False, "課本的分數指數只定義在底數 > 0（∛{−8} 可以，但不寫成 (−8)^{\\frac{1}{3}}）"),
                     ("若 a > 0 且 a + a^{−1} = 2，則 a = 1", True, "算幾：a + a^{−1} ≥ 2，等號只在 a = 1"),
                     ("10^{2 log 3} = 6", False, "10^{2 log 3} = 3^{2} = 9"),
                     ("log (−3)^{2} = 2 log 3", True, "log (−3)^{2} = log 9 = 2 log 3")]),
         xj_defined([("(−3)^{0} = 1", True, "非零數的 0 次方是 1"),
                     ("0^{0} = 1", False, "0^{0} 沒有定義"),
                     ("(√{2})^{√{2}} 有意義", True, "底數 √{2} > 0，無理數次方有定義"),
                     ("log (−5)^{2} = 2 log (−5)", False, "log (−5) 沒有意義；log (−5)^{2} = log 25 = 2 log 5"),
                     ("10^{−log 4} = 0.25", True, "10^{−log 4} = \\frac{1}{4}")])],
        [xj_table([("若 10^{x} = 3，則 10^{√{x}} = √{3}", "10^{\\frac{x}{2}} 才是 √{3}；√{x} ≠ \\frac{x}{2}", lambda: near(10 ** S(lg(3)), S(3))),
                   ("y = log x 中，x > 1 時 y > 0", "10^{y} = x > 1，所以 y > 0", True),
                   ("10^{2 log 3} = 9", "(10^{log 3})^{2} = 3^{2}", lambda: near(10 ** (2 * lg(3)), 9)),
                   ("10^{log 9} × 100^{log 3} = 81", "100^{log 3} = 10^{2 log 3} = 9，9 × 9", lambda: near(10 ** lg(9) * 100 ** lg(3), 81)),
                   ("若 log x = 1 + log y，則 x = 10y", "log x − log y = 1，\\frac{x}{y} = 10", True)]),
         xj_table([("若 10^{x} = 2，則 10^{2x} = 4", "10^{2x} = (10^{x})^{2}", lambda: near(10 ** (2 * lg(2)), 4)),
                   ("若 10^{x} = 2，則 10^{x + 1} = 3", "10^{x + 1} = 10 × 10^{x} = 20", lambda: near(10 ** (lg(2) + 1), 3)),
                   ("1000^{log 2} = 8", "1000^{log 2} = 10^{3 log 2} = 2^{3}", lambda: near(1000 ** lg(2), 8)),
                   ("若 log x = 2 log y（y > 0），則 x = 2y", "2 log y = log y^{2}，所以 x = y^{2}", lambda: near(10 ** (2 * lg(3.0)), 2 * 3.0)),
                   ("10^{log 6 − log 3} = 2", "10^{log \\frac{6}{3}} = 2", lambda: near(10 ** (lg(6) - lg(3)), 2))]),
         xj_table([("若 10^{x} = 5，則 10^{−x} = 0.2", "10^{−x} = \\frac{1}{10^{x}} = \\frac{1}{5}", lambda: near(10 ** -lg(5), 0.2)),
                   ("若 10^{x} = 5，則 10^{\\frac{x}{2}} = √{5}", "10^{\\frac{x}{2}} = (10^{x})^{\\frac{1}{2}}", lambda: near(10 ** (lg(5) / 2), S(5))),
                   ("若 log x + log y = 0，則 xy = 1", "log xy = 0，xy = 10^{0}", True),
                   ("100^{log 3} = 6", "100^{log 3} = 10^{2 log 3} = 9", lambda: near(100 ** lg(3), 6)),
                   ("log 12 = log 3 × log 4", "log 12 = log 3 + log 4", lambda: near(lg(12), lg(3) * lg(4)))])],
        [xj_truefalse([("10^{log 119} = 119", "10^{log N} = N", lambda: near(10 ** lg(119), 119)),
                       ("\\frac{log 6}{log 3} = 2", "\\frac{log 6}{log 3} ≈ \\frac{0.778}{0.477} ≈ 1.63；log \\frac{6}{3} 才是 log 6 − log 3", lambda: near(lg(6) / lg(3), 2)),
                       ("(√{2})^{((√{2})^{√{2}})} > (√{2})^{√{2}}", "底數 √{2} > 1，比指數：(√{2})^{√{2}} > (√{2})^{1} = √{2}", lambda: S(2) ** (S(2) ** S(2)) > S(2) ** S(2)),
                       ("log 6 = log 2 × log 3", "log 6 = log 2 + log 3", lambda: near(lg(6), lg(2) * lg(3))),
                       ("log \\frac{6}{3} = log 6 − log 3", "log 的除法變減法", lambda: near(lg(2), lg(6) - lg(3)))]),
         xj_truefalse([("10^{log 2026} = 2026", "10^{log N} = N", lambda: near(10 ** lg(2026), 2026, 1e-6)),
                       ("\\frac{log 8}{log 2} = 3", "log 8 = 3 log 2", lambda: near(lg(8) / lg(2), 3)),
                       ("\\frac{log 8}{log 2} = log 4", "\\frac{log 8}{log 2} = 3，log 4 是 log 8 − log 2", lambda: near(lg(8) / lg(2), lg(4))),
                       ("(0.5)^{(0.5^{0.5})} > (0.5)^{0.5}", "底數 0.5 < 1，指數越大值越小；0.5^{0.5} ≈ 0.71 > 0.5", lambda: 0.5 ** (0.5 ** 0.5) > 0.5 ** 0.5),
                       ("log 2 + log 5 = 1", "log 2 + log 5 = log 10", lambda: near(lg(2) + lg(5), 1))]),
         xj_truefalse([("10^{2 log 5} = 25", "(10^{log 5})^{2}", lambda: near(10 ** (2 * lg(5)), 25)),
                       ("\\frac{log 9}{log 3} = 3", "log 9 = 2 log 3，比值是 2", lambda: near(lg(9) / lg(3), 3)),
                       ("log 9 − log 3 = log 6", "log 9 − log 3 = log \\frac{9}{3} = log 3", lambda: near(lg(9) - lg(3), lg(6))),
                       ("(√{3})^{((√{3})^{√{3}})} > (√{3})^{√{3}}", "底數 √{3} > 1，比指數：(√{3})^{√{3}} > (√{3})^{1}", lambda: S(3) ** (S(3) ** S(3)) > S(3) ** S(3)),
                       ("10^{log 3 + log 4} = 12", "10^{log 12} = 12", lambda: near(10 ** (lg(3) + lg(4)), 12))])],
        [xj_compare([("2^{\\frac{1}{3}} > 5^{\\frac{1}{7}}", "兩邊 21 次方：2^{7} = 128 > 5^{3} = 125", lambda: 2 ** (1 / 3) > 5 ** (1 / 7)),
                     ("10^{log 2025} > (\\frac{1}{2})^{−10}", "左邊 2025，右邊 2^{10} = 1024", lambda: 2025 > 2 ** 10),
                     ("3^{\\frac{1}{2}} < 2^{\\frac{1}{3}}", "兩邊 6 次方：27 > 4", lambda: 3 ** 0.5 < 2 ** (1 / 3)),
                     ("0.5^{−3} > 4^{1.5}", "0.5^{−3} = 8，4^{1.5} = 8，一樣大", lambda: 0.5 ** -3 > 4 ** 1.5 + 1e-12),
                     ("(\\frac{1}{3})^{−2} = 9", "(\\frac{1}{3})^{−2} = 3^{2}", lambda: near((1 / 3) ** -2, 9))]),
         xj_compare([("3^{\\frac{1}{5}} > 2^{\\frac{1}{3}}", "兩邊 15 次方：3^{3} = 27 < 2^{5} = 32", lambda: 3 ** 0.2 > 2 ** (1 / 3)),
                     ("10^{log 500} < 2^{9}", "500 < 512", lambda: 500 < 2 ** 9),
                     ("5^{\\frac{1}{2}} > 3^{\\frac{2}{3}}", "兩邊 6 次方：5^{3} = 125 > 3^{4} = 81", lambda: 5 ** 0.5 > 3 ** (2 / 3)),
                     ("0.2^{−2} < 5^{1.5}", "0.2^{−2} = 25，5^{1.5} = 5√{5} ≈ 11.2", lambda: 0.2 ** -2 < 5 ** 1.5),
                     ("2^{30} > 10^{9}", "2^{10} = 1024 > 10^{3}，三次方", lambda: 2 ** 30 > 10 ** 9)]),
         xj_compare([("7^{\\frac{1}{3}} < 3^{\\frac{1}{2}}", "兩邊 6 次方：7^{2} = 49 > 3^{3} = 27", lambda: 7 ** (1 / 3) < 3 ** 0.5),
                     ("10^{log 3 + 1} = 30", "10^{log 3} × 10", lambda: near(10 ** (lg(3) + 1), 30)),
                     ("2^{\\frac{3}{4}} < 3^{\\frac{1}{2}}", "兩邊 4 次方：2^{3} = 8 < 3^{2} = 9", lambda: 2 ** 0.75 < 3 ** 0.5),
                     ("4^{−\\frac{1}{2}} > 8^{−\\frac{1}{3}}", "兩個都是 \\frac{1}{2}", lambda: 4 ** -0.5 > 8 ** (-1 / 3) + 1e-12),
                     ("9^{0.25} = √{3}", "9^{\\frac{1}{4}} = 3^{\\frac{1}{2}}", lambda: near(9 ** 0.25, S(3)))])],
    ]
