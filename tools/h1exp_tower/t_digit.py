# 深谷測繩：位數、科學記號
from xlib import *


# ---------- xd_count：是幾位數 ----------

def xd_count(b, n, logv, logt, red=None):
    """b^n：logv 是題目給的 log 值（log b 或 red 的 log），red = (底數, 次方)：b = red[0]^{red[1]}"""
    if red:
        k = n * red[1]
        L = k * logv
        first = fl("先換成 %d 的次方：" % red[0], "%d^{%d} = %d^{[0]}" % (b, n, red[0]), [str(k)], "%d = %d^{%d}" % (b, red[0], red[1]))
        lt = "log %d^{%d} = %d × %s" % (red[0], k, k, logt)
    else:
        L = n * logv
        first = None
        lt = "log %d^{%d} = %d × %s" % (b, n, n, logt)
    Ls = ("%.4f" % L).rstrip("0").rstrip(".")
    digits = math.floor(L) + 1
    assert len(str(b ** n)) == digits
    steps = ([first] if first else []) + [
        fl("取 log：", "a = %s = [0]" % lt, [Ls], "log x^{n} = n log x"),
        fl("10^{%s} 是幾位數？" % Ls, "10^{%d} ≤ %d^{%d} < 10^{%d}，是 [0] 位數" % (math.floor(L), b, n, math.floor(L) + 1), [str(digits)], "10^{k} 是 k + 1 位數")]
    return item("xd_count", "digit", 1, "是幾位數", 1.0,
                "%d^{%d} = 10^{a}，%d^{%d} 是幾位數？（log %d ≈ %s）" % (b, n, b, n, red[0] if red else b, logt),
                steps)


# ---------- xd_mass：兩個量的比 ----------

def xd_mass(ctx, m1, e1, m2, e2, unit_q):
    r = (m1 * 10 ** e1) / (m2 * 10 ** e2)
    q = m1 / m2
    qs = "%.3g" % q
    if q < 1:
        qs = "%.3f" % q if q >= 0.1 else "%.4f" % q
    ms, e = sci(r, 3)
    assert near(float(ms) * 10 ** e, r, 0.006 * r)
    return item("xd_mass", "digit", 1, "兩個量的比", 1.05,
                "%s（取三位有效數字，寫成科學記號）" % ctx,
                [fl("係數和 10 的次方分開算：", "\\frac{%.2f}{%.2f} ≈ [0]（三位有效數字），10^{%d − %s} = 10^{[1]}" % (m1, m2, e1, tp(e2)), [qs, str(e1 - e2)],
                    "係數相除；指數相減"),
                 fl("調成 1 ≤ 係數 < 10：", "%s = [0] × 10^{[1]}" % unit_q, [ms, str(e)], "係數 %s 不到 1，就往右移一位、指數減 1" % qs if q < 1 else "係數已經在 1 和 10 之間")])


# ---------- xd_light：一光年 ----------

def xd_light(ctx, v, ve, secs, sl, ans_name):
    """速度 v × 10^{ve}，時間 secs 秒（sl 是算式）"""
    ts, te = sci(secs, 5)
    ts = ts.rstrip("0").rstrip(".")
    prod = v * float(ts)
    ms, e = sci(v * 10 ** ve * secs, 4)
    assert near(float(ms) * 10 ** e, v * 10 ** ve * secs, 0.0006 * v * 10 ** ve * secs)
    pm, pe = sci(prod, 4)
    assert pe in (0, 1)
    pps = "%.*f" % (max(0, 4 - (math.floor(lg(prod)) + 1)), prod)
    assert near(float(pps) * 10 ** (ve + te), float(ms) * 10 ** e, 1e-9 * 10 ** e)
    return item("xd_light", "digit", 1, "一光年", 1.05,
                "%s（取四位有效數字）" % ctx,
                [fl("時間換成秒，寫成科學記號：", "%s = [0] × 10^{[1]} 秒" % sl, [ts, str(te)], "%d 秒" % secs),
                 fl("係數相乘，取四位有效數字：", "%s × %s ≈ [0]" % (("%g" % v), ts), [pps], "%s × %s = %s…" % (("%g" % v), ts, ("%.6f" % prod)[:7])),
                 fl("調整成科學記號：", "%s ≈ [0] × 10^{[1]} 公尺" % ans_name, [ms, str(e)],
                    "%s × 10^{%d}%s" % (pps, ve + te, "，係數超過 10 要再調一次" if pe else ""))])


# ---------- xd_mantissa：尾數決定最高位 ----------

def xd_mantissa(L, lo, hi, llo, lhi):
    """log x = L（L 可以是負的）；尾數 f 夾在 log lo、log hi 之間"""
    k = math.floor(L)
    f = round(L - k, 4)
    assert abs(lg(lo) - llo) < 6e-5 and abs(lg(hi) - lhi) < 6e-5 and llo < f < lhi
    A = int(lo)
    assert int(hi) == A and 10 ** f > lo
    ratio = F(k, A)
    fs = ("%.2f" % f)
    Ls = ("%.2f" % L).replace("-", "−")
    return item("xd_mantissa", "digit", 2, "尾數決定最高位", 1.15,
                "log x = %s，x 寫成 a.△△… × 10^{b}（a 是 1 到 9 的整數），求 \\frac{b}{a}。（log %s ≈ %.4f、log %s ≈ %.4f）" % (Ls, "%g" % lo, llo, "%g" % hi, lhi),
                [fl("把 log x 拆成整數 + 0 到 1 之間的小數：", "%s = %s + [0]，x = 10^{%s} × 10^{[1]}" % (Ls, fs, fs, ), [str(k), str(k)],
                    "小數部分要在 0 和 1 之間%s" % ("：%s = −%d + %s" % (Ls, -k, fs) if k < 0 else "")),
                 ch("10^{%s} 夾在哪裡？" % fs, ["%g 和 %g 之間" % (lo, hi), "%g 和 %g 之間" % (lo - 0.1, lo), "%g 和 %g 之間" % (hi, hi + 0.1), "%d 和 %d 之間" % (A + 1, A + 2)],
                    "和 log %g、log %g 比" % (lo, hi), "log %g < %s < log %g　→　%g < 10^{%s} < %g" % (lo, fs, hi, lo, fs, hi)),
                 fl("所以 x = %s… × 10^{%d}：" % (("%g" % lo)[:3], k), "a = [0]，b = %s，\\frac{b}{a} = [1]" % t(k), [str(A), a(ratio)], "a 是最高位數字")])


# ---------- xd_decimal：小數點後第幾位 ----------

def xd_decimal(e, n, mode):
    """a = 10^{e}，a^{n}"""
    L = round(float(e) * n, 4)
    Ls = ("%g" % L).replace("-", "−")
    if mode == "zeros":
        assert L < 0
        k = -math.floor(L)
        fr = round(L + k, 4)
        steps = [fl("先寫成 10 的次方：", "a^{%s} = 10^{[0]}" % t(n), [Ls], "(10^{%s})^{%s}，指數相乘" % (e, t(n))),
                 fl("拆成 0 到 1 的小數加整數：", "%s = %s + ([0])" % (Ls, ("%g" % fr)), [str(-k)], "小數部分要在 0 和 1 之間"),
                 fl("10^{%g} 在 1 和 10 之間：" % fr, "a^{%s} = 10^{%g} × 10^{−%d}，從小數點後第 [0] 位開始不是 0" % (t(n), fr, k), [str(k)],
                    "10^{%g} 是 %d 點多，乘 10^{−%d} 小數點往左移 %d 位" % (fr, int(10 ** fr), k, k))]
        q = "a^{%s} 從小數點後第幾位開始不是 0？" % t(n)
    else:
        assert L > 0
        dg = math.floor(L) + 1
        steps = [fl("先寫成 10 的次方：", "a^{%s} = 10^{[0]}" % t(n), [Ls], "(10^{%s})^{%s}，指數相乘" % (e, n)),
                 fl("10^{%s} 是幾位數？" % Ls, "10^{%d} ≤ a^{%d} < 10^{%d}，是 [0] 位數" % (math.floor(L), n, math.floor(L) + 1), [str(dg)], "10^{k} 是 k + 1 位數")]
        q = "a^{%d} 的整數部分是幾位數？" % n
    return item("xd_decimal", "digit", 2, "小數點後第幾位", 1.1,
                "a = 10^{%s}，%s" % (e, q), steps)


def items():
    return [
        [xd_count(3, 100, L3, "0.4771"), xd_count(128, 114, L2, "0.3010", red=(2, 7)), xd_count(7, 50, L7, "0.8451")],
        [xd_mass("太陽的質量約 1.99 × 10^{30} 公斤，地球約 5.97 × 10^{24} 公斤，太陽是地球的幾倍？", 1.99, 30, 5.97, 24, "太陽與地球的比"),
         xd_mass("木星的質量約 1.90 × 10^{27} 公斤，地球約 5.97 × 10^{24} 公斤，木星是地球的幾倍？", 1.90, 27, 5.97, 24, "木星與地球的比"),
         xd_mass("台灣人口約 2.34 × 10^{7} 人，世界人口約 8.12 × 10^{9} 人，台灣人口占世界的幾分之幾？", 2.34, 7, 8.12, 9, "占的比例")],
        [xd_light("光速約 2.998 × 10^{8} 公尺／秒，一年有 365 天。一光年（光走一年的距離）約幾公尺？", 2.998, 8, 365 * 24 * 3600, "365 × 24 × 60 × 60", "一光年"),
         xd_light("光速約 2.998 × 10^{8} 公尺／秒。光走一天的距離約幾公尺？", 2.998, 8, 24 * 3600, "24 × 60 × 60", "光走一天"),
         xd_light("聲速約 3.43 × 10^{2} 公尺／秒，一年有 365 天。聲音不停地走一年，約幾公尺？", 3.43, 2, 365 * 24 * 3600, "365 × 24 × 60 × 60", "聲音走一年")],
        [xd_mantissa(56.66, 4.5, 4.6, 0.6532, 0.6628), xd_mantissa(30.35, 2.2, 2.3, 0.3424, 0.3617), xd_mantissa(-4.08, 8.3, 8.4, 0.9191, 0.9243)],
        [xd_decimal("0.301", -100, "zeros"), xd_decimal("0.477", -50, "zeros"), xd_decimal("0.845", 30, "digits")],
    ]
