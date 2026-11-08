# 現實委託
from elib import *


def d2(x, nd=2):
    return ("%." + str(nd) + "f") % x


# ---------- q_bact ----------

def q_bact(r, k):
    lr = LG[r]
    need = k / lr
    n = math.floor(need) + 1
    assert r ** n > 10 ** k > r ** (n - 1)
    lrs = "%.4f" % lr
    return item("q_bact", "quest", 1, "細菌繁殖", 1.0,
                "實驗室的細菌每小時數量變成 %d 倍。至少要經過幾小時，細菌數會超過原來的 %d 倍？\n（log %d ≈ %s）" % (r, 10 ** k, r, lrs),
                [ch("經過 n 小時後，要滿足？", ["%d^{n} > %d" % (r, 10 ** k), "%dn > %d" % (r, 10 ** k), "n^{%d} > %d" % (r, 10 ** k), "%d^{n} > %d" % (10 ** k, r)],
                    "每小時乘 %d，n 小時乘了 n 次" % r, "%d^{n} > %d" % (r, 10 ** k)),
                 ch("兩邊取 log：", ["n > %d / %s" % (k, lrs), "n > %d × %s" % (k, lrs), "n > %s / %d" % (lrs, k), "n > %d / %s" % (10 ** k, lrs)],
                    "n log %d > log %d = %d" % (r, 10 ** k, k), "n log %d > log %d = %d　→　n > %d / %s ≈ %s" % (r, 10 ** k, k, k, lrs, d2(need))),
                 fl("n 是整數，至少幾小時？", "答：至少 [0] 小時", [str(n)], "n 要是大於 %s 的整數" % d2(need))])


# ---------- q_interest ----------

def q_interest(pct, lr, target):
    r = 1 + pct / 100
    lt = LG[target]
    lrs = "%.4f" % lr
    need = lt / lr
    n = math.floor(need) + 1
    assert r ** n > target > r ** (n - 1)
    assert lr * (n - 1) < lt < lr * n
    prev = lr * (n - 1)
    rs = ("%.2f" % r).rstrip("0")
    return item("q_interest", "quest", 2, "複利翻倍", 1.1,
                "一筆存款年利率 %d%%，每年複利一次。至少要存幾年，本利和才會超過本金的 %d 倍？\n（log %d ≈ %s，log %s ≈ %s）" % (pct, target, target, "%.4f" % lt, rs, lrs),
                [ch("存 n 年後，要滿足？", ["%s^{n} > %d" % (rs, target), "1 + %sn > %d" % (("%.2f" % (pct / 100)).rstrip("0"), target), "%sn > %d" % (rs, target),
                                       "%d^{n} > %s" % (target, rs)],
                    "複利：每年乘 %s" % rs, "%s^{n} > %d" % (rs, target)),
                 ch("取 log 之後：", ["n · log %s > log %d" % (rs, target), "log n · %s > log %d" % (rs, target), "n + log %s > log %d" % (rs, target),
                                  "n > log %d · log %s" % (target, rs)],
                    "log a^{n} = n log a", "n log %s > log %d　→　%sn > %s" % (rs, target, lrs, "%.4f" % lt)),
                 fl("n 是整數，至少幾年？（%s × %d ≈ %s）" % (lrs, n - 1, "%.4f" % prev),
                    "%s × %d ≈ %s < %s　→　答：至少 [0] 年" % (lrs, n - 1, "%.4f" % prev, "%.4f" % lt), [str(n)], "%d 年還不夠 %s，要再多一年" % (n - 1, "%.4f" % lt))])


# ---------- q_ph ----------

def q_ph(pa, pb, mult, how):
    d = round(pb - pa, 1)
    v = 10 ** d
    assert abs(v - mult) / mult < 0.02
    ds = ("%.1f" % d)
    return item("q_ph", "quest", 2, "酸鹼度", 1.0,
                "pH = −log [H^{+}]。洗面乳 A 的 pH 是 %s，洗面乳 B 的 pH 是 %s。A 的氫離子濃度大約是 B 的幾倍？\n（log 2 ≈ 0.3010）" % (pa, pb),
                [ch("氫離子濃度用 pH 表示：", ["[H^{+}] = 10^{−pH}", "[H^{+}] = −10^{pH}", "[H^{+}] = 10^{pH}", "[H^{+}] = log pH"],
                    "−log [H^{+}] = pH，所以 log [H^{+}] = −pH", "[H^{+}] = 10^{−pH}"),
                 ch("A 的濃度是 B 的幾倍？10^{−%s}/10^{−%s} = ？" % (pa, pb), ["10^{%s}" % ds, "10^{−%s}" % ds, "%s/%s" % (pa, pb), "10^{%s}" % ("%.1f" % (pa + pb))],
                    "同底數相除，指數相減：(−%s) − (−%s)" % (pa, pb), "10^{−%s}/10^{−%s} = 10^{−%s + %s} = 10^{%s}" % (pa, pb, pa, pb, ds)),
                 fl("10^{%s} 大約是幾倍？（用 log 2 ≈ 0.3010 找出整數）" % ds, "答：10^{%s} 約 [0] 倍" % ds, [str(mult)], how)])


# ---------- q_db ----------

def q_db(one, limit):
    k = (limit - one) / 10
    assert k == int(k)
    k = int(k)
    n = 10 ** k
    return item("q_db", "quest", 2, "噪音管制", 1.0,
                "分貝 dB = 120 + 10 log ω（ω 是聲音能量）。一支哨子會發出 %d 分貝，場內規定不能超過 %d 分貝。最多能同時吹幾支？" % (one, limit),
                [ch("n 支哨子同時吹，能量變成 nω，分貝變成？", ["%d + 10 log n" % one, "%dn" % one, "%d + log n" % one, "%d log n" % (one * 10)],
                    "120 + 10 log (nω) = (120 + 10 log ω) + 10 log n", "120 + 10 log (nω) = %d + 10 log n ≤ %d" % (one, limit)),
                 fl("最多幾支？", "10 log n ≤ %d　→　答：最多 [0] 支" % (limit - one), [str(n)], "log n ≤ %d 代表 n ≤ 10^{%d}" % (k, k))])


# ---------- q_quake ----------

def q_quake(r1, r2, given, mult, how):
    d = round(1.5 * (r1 - r2), 2)
    v = 10 ** d
    assert abs(v - mult) / mult < 0.02
    ds = ("%g" % d)
    return item("q_quake", "quest", 3, "地震能量", 1.0,
                "芮氏規模 r 的地震釋放能量 E 滿足 log E = 11.8 + 1.5r。規模 %s 的地震，能量大約是規模 %s 的幾倍？\n（%s）" % (r1, r2, given),
                [fl("規模 %s 和 %s，log E 差多少？" % (r1, r2), "log E_{1} − log E_{2} = [0]", [ds],
                    "(11.8 + 1.5 × %s) − (11.8 + 1.5 × %s)" % (r1, r2), write="E_{1}/E_{2} = 10^{%s}" % ds),
                 fl("大約是幾倍？（四捨五入到整數）", "答：10^{%s} 約 [0] 倍" % ds, [str(mult)], how)])


def items():
    return [
        [q_bact(2, 3), q_bact(3, 4), q_bact(2, 5)],
        [q_interest(5, 0.0212, 2), q_interest(8, 0.0334, 2), q_interest(4, 0.0170, 3)],
        [q_ph(5.3, 6.2, 8, "0.9 ≈ 3 × 0.3010 = 3 log 2"), q_ph(4.1, 4.7, 4, "0.6 ≈ 2 × 0.3010 = 2 log 2"),
         q_ph(6.5, 7.2, 5, "0.7 ≈ 1 − 0.3010 = log 10 − log 2 = log 5")],
        [q_db(50, 70), q_db(40, 70), q_db(45, 55)],
        [q_quake(7.2, 6.2, "√{10} ≈ 3.16", 32, "10^{1.5} = 10√{10}，√{10} ≈ 3.16"),
         q_quake(6.8, 6.4, "log 2 ≈ 0.3010", 4, "0.6 ≈ 2 × 0.3010 = 2 log 2"),
         q_quake(5.6, 5.0, "log 2 ≈ 0.3010", 8, "0.9 ≈ 3 × 0.3010 = 3 log 2")],
    ]
