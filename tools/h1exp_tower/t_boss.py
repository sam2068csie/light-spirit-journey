# 試煉大題（一）：pH、分貝、細菌、雙重根號
from xlib import *


def _one(x):
    return ("%.1f" % (x + 1e-9))


# ---------- xb_ph：蜂蜜檸檬水 ----------

def xb_ph(p_lo, p_hi, vol, target, tot, gap):
    """甲 pH p_hi、乙 pH p_lo（比較酸），各 vol ml；調成 pH target 的 tot ml"""
    d = round(p_hi - p_lo)
    assert near(p_hi - p_lo, d)
    R = 10 ** d                       # 乙的 [H+] 是甲的 R 倍
    mix = -lg((10 ** -p_hi + 10 ** -p_lo) / 2)
    approx = p_lo + L2
    assert _one(mix) == _one(approx)
    # (3) x ml 甲 + (tot − x) ml 乙 = tot ml、pH target
    k = round(target - p_lo)
    assert near(target - p_lo, k)
    # x·10^{−p_hi} + (tot − x)·10^{−p_lo} = tot·10^{−target}，除以 10^{−p_hi}：x + R(tot − x) = tot·10^{d − k}
    rhs = tot * 10 ** (d - k)
    x = F(R * tot - rhs, R - 1)
    assert isint(x) and 0 < x < tot
    x = int(x)
    assert near(x * 10 ** -p_hi + (tot - x) * 10 ** -p_lo, tot * 10 ** -target, 1e-12)
    ph = lambda v: ("%g" % v)
    return item("xb_ph", "boss", 2, "蜂蜜檸檬水", 1.65,
                "兩杯蜂蜜檸檬水：甲 pH %s、乙 pH %s，各 %d ml。pH = −log [H^{+}]，混合時 H^{+} 的總量不變。（log 2 ≈ 0.3010）\n(1) 乙的 [H^{+}] 是甲的幾倍？　(2) 兩杯全部混合後的 pH　(3) 要調出 pH %s 的 %d ml，甲、乙各取多少？" % (ph(p_hi), ph(p_lo), vol, ph(target), tot),
                [fl("[H^{+}] = 10^{−pH}：", "(1)　10^{−%s} 是 10^{−%s} 的 10^{[0]} = [1] 倍" % (ph(p_lo), ph(p_hi)), [str(d), str(R)], "指數相減：−%s − (−%s)" % (ph(p_lo), ph(p_hi)), part="(1)"),
                 fl("混合後體積加倍，甲的 H^{+} 少到可以忽略：", "(2)　[H^{+}] ≈ \\frac{10^{−%s}}{2}，pH ≈ %s + log 2 ≈ [0]（取一位小數）" % (ph(p_lo), ph(p_lo)), [_one(approx)],
                    "−log \\frac{10^{−%s}}{2} = %s + log 2" % (ph(p_lo), ph(p_lo)), part="(2)"),
                 fl("甲取 x ml，H^{+} 的總量：x × 10^{−%s} + (%d − x) × 10^{−%s} = %d × 10^{−%s}" % (ph(p_hi), tot, ph(p_lo), tot, ph(target)),
                    "(3)　兩邊除以 10^{−%s}：x + %d(%d − x) = %d，甲 [0] ml、乙 [1] ml" % (ph(p_hi), R, tot, rhs), [str(x), str(tot - x)],
                    "%d − %dx = %d" % (R * tot, R - 1, rhs), part="(3)")])


# ---------- xb_pressure：聲壓與分貝 ----------

def xb_pressure(P, k, k_dec, dB3):
    """分貝 = 20 log (P/20)：(1) 聲壓 P 的分貝 (2) 聲壓變 k 倍，分貝多多少 (3) dB3 分貝時的聲壓"""
    r = P // 20
    assert r * 20 == P and 10 ** round(lg(r)) == r
    d1 = 20 * round(lg(r))
    inc = 20 * lg(k)
    incs = ("%d" % round(inc)) if near(inc, round(inc)) else _one(20 * (L2 if k == 2 else lg(k)))
    e3 = F(dB3, 20)
    assert isint(e3)
    P3 = 20 * 10 ** int(e3)
    return item("xb_pressure", "boss", 2, "聲壓與分貝", 1.6,
                "聲音的分貝 = 20 log \\frac{P}{20}（P 是聲壓）。（log 2 ≈ 0.3010）\n(1) 聲壓 %d 時是幾分貝？　(2) 聲壓變成原來的 %s 倍，分貝增加多少？　(3) %d 分貝時的聲壓" % (P, k_dec, dB3),
                [fl("代入：", "(1)　20 log \\frac{%d}{20} = 20 log [0] = [1] 分貝" % P, [str(r), str(d1)], "log 10^{n} = n", part="(1)"),
                 fl("20 log \\frac{kP}{20} = 20 log k + 20 log \\frac{P}{20}：", "(2)　增加 20 log %s ≈ [0] 分貝" % k_dec, [incs],
                    "log %s %s" % (k_dec, "≈ 0.3010" if k == 2 else "= %d" % round(lg(k))), part="(2)"),
                 fl("反過來解 P：", "(3)　20 log \\frac{P}{20} = %d　→　log \\frac{P}{20} = [0]，P = [1]" % dB3, [a(e3), str(P3)], "\\frac{P}{20} = 10^{%s}" % t(e3), part="(3)")])


# ---------- xb_car：汽車和汽笛 ----------

def xb_car(e1, d_big, n, d_small):
    """d = 10 log \\frac{I}{10^{−12}}：(1) I = 10^{e1} 的分貝 (2) 一個 d_big 分貝加 n 個 d_small 分貝"""
    d1 = 10 * (e1 + 12)
    Ib, Is = F(1, 10 ** (12 - d_big // 10)), F(1, 10 ** (12 - d_small // 10))
    tot = Ib + n * Is
    c = tot / Ib
    assert isint(c)
    c = int(c)
    dB = d_big + 10 * lg(c)
    approx = d_big + 10 * {2: L2, 3: L3, 4: 2 * L2, 5: 1 - L2}[c]
    assert _one(dB) == _one(approx)
    return item("xb_car", "boss", 2, "汽車和汽笛", 1.65,
                "聲音強度 I 的分貝數 d = 10 log \\frac{I}{10^{−12}}，幾個聲音一起響時強度相加。（log 2 ≈ 0.3010、log 3 ≈ 0.4771）\n(1) I = 10^{%d} 是幾分貝？　(2) 一支 %d 分貝的汽笛和 %d 支 %d 分貝的汽笛一起響，是幾分貝？" % (e1, d_big, n, d_small),
                [fl("代入：", "(1)　10 log 10^{%d − (−12)} = 10 × [0] = [1] 分貝" % e1, [str(e1 + 12), str(d1)], "指數相減：%d − (−12)" % e1, part="(1)"),
                 fl("分貝換回強度：", "(2)　%d 分貝：I = 10^{[0]}；%d 分貝：I = 10^{[1]}" % (d_big, d_small), [str(d_big // 10 - 12), str(d_small // 10 - 12)],
                    "\\frac{d}{10} = log \\frac{I}{10^{−12}}", part="(2)"),
                 fl("強度相加：", "　 　10^{%d} + %d × 10^{%d} = [0] × 10^{%d}" % (d_big // 10 - 12, n, d_small // 10 - 12, d_big // 10 - 12), [str(c)],
                    "%d × 10^{%d} = %s × 10^{%d}" % (n, d_small // 10 - 12, t(F(n, 10)), d_big // 10 - 12), part="(2)"),
                 fl("換回分貝：", "　 　d = 10 log \\frac{%d × 10^{%d}}{10^{−12}} = %d + 10 log %d ≈ [0]（取一位小數）" % (c, d_big // 10 - 12, d_big, c), [_one(approx)],
                    "log %d ≈ %s" % (c, {2: "0.3010", 3: "0.4771", 4: "0.6020", 5: "0.6990"}[c]), part="(2)")])


# ---------- xb_twin：兩種細菌 ----------

def xb_twin(pa, ha, pb, hb, T, t1, t2, base):
    """A 每 ha 小時變 pa 倍、B 每 hb 小時變 pb 倍，T 小時後一樣多；pa、pb 都是 base 的次方"""
    ea, eb = round(math.log(pa, base)), round(math.log(pb, base))
    assert base ** ea == pa and base ** eb == pb
    # a·base^{ea T/ha} = b·base^{eb T/hb}
    ka, kb = F(ea * T, ha), F(eb * T, hb)
    ab = kb - ka                    # a/b = base^{ab}
    assert isint(ab) and ab > 0
    ratio_ab = base ** int(ab)
    def r_at(tt):
        return ab + F(ea * tt, ha) - F(eb * tt, hb)        # A/B = base^{…}
    r1, r2 = r_at(t1), r_at(t2)
    assert r1.denominator in (1, 2) and r2.denominator in (1, 2) and r_at(T) == 0
    ans1, ans2 = half_pow(base, r1), half_pow(base, r2)
    chk(ans1, base ** float(r1))
    chk(ans2, base ** float(r2))
    return item("xb_twin", "boss", 2, "兩種細菌", 1.65,
                "細菌 A 每 %d 小時變成 %d 倍，細菌 B 每 %d 小時變成 %d 倍。最初 A 有 a 隻、B 有 b 隻，%d 小時後兩種一樣多。\n(1) a : b　(2) %d 小時後 A : B　(3) %d 小時後 A : B" % (ha, pa, hb, pb, T, t1, t2),
                [fl("%d 小時後一樣多：" % T, "(1)　a × %d^{[0]} = b × %d^{[1]}，a : b = [2] : 1" % (pa, pb), [a(F(T, ha)), a(F(T, hb)), str(ratio_ab)],
                    "A 變了 \\frac{%d}{%d} 次、B 變了 \\frac{%d}{%d} 次；都寫成 %d 的次方" % (T, ha, T, hb, base), part="(1)"),
                 fl("t 小時後 A = a × %d^{\\frac{t}{%d}}、B = b × %d^{\\frac{t}{%d}}：" % (pa, ha, pb, hb), "(2)　%d 小時後 A : B = [0] : 1" % t1, [ans1],
                    "\\frac{A}{B} = %d × \\frac{%d^{\\frac{%d}{%d}}}{%d^{\\frac{%d}{%d}}}，都換成 %d 的次方" % (ratio_ab, pa, t1, ha, pb, t1, hb, base), part="(2)"),
                 fl("同樣的算法：", "(3)　%d 小時後 A : B = [0] : 1" % t2, [ans2], "過了 %d 小時之後 B 長得比較快" % T, part="(3)")])


# ---------- xb_half：x^{1/2} + x^{−1/2} ----------

def xb_half(xs, root, root_t, simp, s_val, s_ans, s3_ans):
    """x = xs（寫法），x^{1/2} = root（數值）"""
    xv = root * root
    assert near(xv, num_x(xs))
    s = root + 1 / root
    assert near(s, s_val) and near(num(s_ans), s) and near(num(s3_ans), s ** 3 - 3 * s)
    return item("xb_half", "boss", 2, "二分之一次方的和", 1.6,
                "x = %s。\n(1) 求 x^{\\frac{1}{2}} + x^{−\\frac{1}{2}}　(2) 求 x^{\\frac{3}{2}} + x^{−\\frac{3}{2}}" % xs,
                [fl("x 是一個完全平方：", "(1)　%s" % simp[0], simp[1], "根號裡寫成 p − 2√{q}，找兩數和是 p、積是 q", part="(1)"),
                 fl("x^{\\frac{1}{2}} = %s，倒數有理化再相加：" % root_t, "　 　x^{\\frac{1}{2}} + x^{−\\frac{1}{2}} = [0]", [s_ans], "x^{−\\frac{1}{2}} = \\frac{1}{%s}，上下同乘共軛" % root_t, part="(1)"),
                 ch("令 s = x^{\\frac{1}{2}} + x^{−\\frac{1}{2}}，x^{\\frac{3}{2}} + x^{−\\frac{3}{2}} = ？", ["s^{3} − 3s", "s^{3} + 3s", "s^{3} − 3", "s^{3}"],
                    "(a + b)^{3} = a^{3} + b^{3} + 3ab(a + b)，ab = 1", "(2)　x^{\\frac{3}{2}} + x^{−\\frac{3}{2}} = s^{3} − 3s", part="(2)"),
                 fl("代入 s：", "　 　s^{3} − 3s = [0]", [s3_ans], "s = %s" % s_ans.replace("√", "√{") + ("}" if "√" in s_ans else ""), part="(2)")])


def num_x(s):
    import re
    m = re.match(r"(\d+) − √\{(\d+)\}", s)
    return int(m.group(1)) - S(int(m.group(2)))


def items():
    return [
        [xb_ph(2.3, 4.3, 300, 3.3, 330, 2), xb_ph(3.2, 5.2, 200, 4.2, 220, 2), xb_ph(3, 6, 500, 4, 333, 3)],
        [xb_pressure(20000, 10, "10", 80), xb_pressure(2000, 100, "100", 100), xb_pressure(200, 2, "2", 60)],
        [xb_car(-4, 50, 20, 40), xb_car(-6, 70, 10, 60), xb_car(-9, 60, 30, 50)],
        [xb_twin(2, 2, 4, 3, 6, 3, 9, 2), xb_twin(3, 2, 9, 3, 6, 3, 9, 3), xb_twin(2, 3, 8, 4, 12, 6, 18, 2)],
        [xb_half("9 − √{80}", S(5) - 2, "√{5} − 2", ("9 − √{80} = 9 − 2√{20} = (√{[0]} − [1])^{2}", ["5", "2"]), 2 * S(5), "2√5", "34√5"),
         xb_half("7 − √{48}", 2 - S(3), "2 − √{3}", ("7 − √{48} = 7 − 2√{12} = ([0] − √{[1]})^{2}", ["2", "3"]), 4, "4", "52"),
         xb_half("11 − √{120}", S(6) - S(5), "√{6} − √{5}", ("11 − √{120} = 11 − 2√{30} = (√{[0]} − √{[1]})^{2}", ["6", "5"]), 2 * S(6), "2√6", "42√6")],
    ]
