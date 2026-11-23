# 峽谷委託：生活應用
from xlib import *


# ---------- xq_bacteria：細菌最初幾隻 ----------

def xq_bacteria(h, d1, n1, N1, d2, n2, N2):
    q = F(N2, N1)
    k = n2 - n1
    r = round(float(q) ** (1 / k))
    assert F(r) ** k == q
    a_ = r - 1
    N0 = F(N1, r ** n1)
    assert isint(N0) and N0 * r ** n2 == N2
    return item("xq_bacteria", "quest", 1, "細菌最初幾隻", 1.05,
                "一種細菌每 %d 小時數量增加 a 倍（變成原來的 1 + a 倍）。%s後有 %d 隻，%s後有 %d 隻。求 a 和最初的數量。" % (h, d1, N1, d2, N2),
                [fl("先換成幾個 %d 小時：" % h, "%s = [0] 個 %d 小時，%s = [1] 個" % (d1, h, d2), [str(n1), str(n2)], "1 天 = 24 小時"),
                 fl("兩個時刻相除，最初的數量會消掉：", "(1 + a)^{[0]} = \\frac{%d}{%d} = [1]，a = [2]" % (N2, N1), [str(k), str(q.numerator), str(a_)],
                    "x(1 + a)^{%d} 除以 x(1 + a)^{%d}" % (n2, n1)),
                 fl("代回第一個時刻：", "x × %d^{%d} = %d，最初 x = [0] 隻" % (r, n1, N1), [a(N0)], "%d^{%d} = %d" % (r, n1, r ** n1))])


# ---------- xq_decay：剩下不到 1 克 ----------

def xq_decay(M0, t1, M1, thr, thr_t, lg_t, lg_v):
    """M0 克，t1 年後剩 M1 克；最少幾年後剩不到 thr 克。lg_t、lg_v：log(M0/thr) 的寫法和近似值"""
    j = round(math.log2(M0 / M1))
    assert M0 / 2 ** j == M1 and t1 % j == 0
    h = t1 // j
    R = M0 / thr
    assert near(lg(R), lg_v, 2e-4)
    need = h * lg_v / L2
    n = math.floor(need) + 1
    # 用真正的 log 也一樣
    assert math.floor(h * lg(R) / lg(2)) + 1 == n and M0 * 0.5 ** (n / h) < thr <= M0 * 0.5 ** ((n - 1) / h)
    ex_ = "n" if h == 1 else "\\frac{n}{%d}" % h
    ns = "%.1f" % need
    return item("xq_decay", "quest", 1, "最少幾年衰變", 1.1,
                "某放射性物質 %d 克，%d 年後剩下 %s 克。最少要幾年，才會剩下不到 %s 克？（log 2 ≈ 0.3010，年數取整數）" % (M0, t1, t(M1), thr_t),
                [fl("先求半衰期：", "%d 年剩 \\frac{%s}{%d} = (\\frac{1}{2})^{[0]}，半衰期 [1] 年" % (t1, t(M1), M0), [str(j), str(h)], "%d 年減半了 %d 次" % (t1, j)),
                 ch("n 年後剩不到 %s 克，列式：" % thr_t, ["%d × (\\frac{1}{2})^{%s} < %s" % (M0, ex_, thr_t), "%d × (\\frac{1}{2})^{%s} > %s" % (M0, ex_, thr_t),
                                                    "%d × (\\frac{1}{2})^{%dn} < %s" % (M0, h, thr_t) if h > 1 else "%d × (\\frac{1}{2})^{2n} < %s" % (M0, thr_t),
                                                    "%d − \\frac{1}{2}n < %s" % (M0, thr_t)],
                    "每 %d 年乘一次 \\frac{1}{2}，n 年乘 %s 次" % (h, ex_), "%d × (\\frac{1}{2})^{%s} < %s　→　2^{%s} > %s" % (M0, ex_, thr_t, ex_, t(F(R).limit_denominator(1000)))),
                 fl("兩邊取 log：", "%s × 0.3010 > %s ≈ [0]" % (ex_, lg_t), [("%.4f" % lg_v).rstrip("0").rstrip(".")], "log 2^{%s} = %s log 2" % (ex_, ex_)),
                 fl("解出 n：", "n > \\frac{%s%s}{0.3010} ≈ [0]（取到小數第一位），最少 [1] 年" % ("" if h == 1 else "%d × " % h, ("%.4f" % lg_v).rstrip("0").rstrip(".")), [ns, str(n)],
                    "n 要是整數，而且要大於 %s" % ns)])


# ---------- xq_tv：關掉幾台電視牆 ----------

def xq_tv(N, each, limit, k, lk, lk1):
    """N 台、每台 each 分貝；總音量 ≤ limit：最多 k 台（lk、lk1 是 log k、log(k + 1) 的近似值）"""
    c = F(limit - each, 10)
    assert lg(k) <= float(c) < lg(k + 1)
    assert abs(lg(k) - lk) < 6e-5 and abs(lg(k + 1) - lk1) < 6e-5 and lk <= float(c) < lk1
    cs = ("%.2f" % float(c)).rstrip("0").rstrip(".")
    return item("xq_tv", "quest", 2, "關掉幾台電視牆", 1.15,
                "電視牆有 %d 台電視，每台 %d 分貝（分貝 = 10 log \\frac{I}{I_{0}}，k 台一起開強度是 k 倍）。總音量不超過 %d 分貝，至少要關幾台？（log %d ≈ %.4f、log %d ≈ %.4f）" % (N, each, limit, k, lk, k + 1, lk1),
                [ch("k 台一起開的音量是？", ["%d + 10 log k" % each, "%dk" % each, "%d + log k" % each, "%d × 10 log k" % each],
                    "10 log \\frac{kI}{I_{0}} = 10 log k + 10 log \\frac{I}{I_{0}}", "k 台：%d + 10 log k 分貝" % each),
                 fl("列不等式：", "%d + 10 log k ≤ %d　→　log k ≤ [0]" % (each, limit), [cs], "移項再除以 10"),
                 fl("和題目給的 log 比：", "log %d ≤ %s < log %d，最多開 [0] 台，至少關掉 [1] 台" % (k, cs, k + 1), [str(k), str(N - k)], "k 越大 log k 越大")])


def items():
    return [
        [xq_bacteria(12, "4 天", 8, 1280, "6.5 天", 13, 40960), xq_bacteria(8, "2 天", 6, 1458, "3 天", 9, 39366),
         xq_bacteria(6, "1 天", 4, 405, "2.5 天", 10, 295245)],
        [xq_decay(100, 4, 25, 1, "1", "log 100", 2.0), xq_decay(80, 6, 10, 0.5, "0.5", "log 160", 4 * L2 + 1),
         xq_decay(200, 3, 25, 1, "1", "log 200", 2 + L2)],
        [xq_tv(25, 108, 120, 15, 1.1761, 1.2041), xq_tv(30, 100, 113, 19, 1.2788, 1.3010), xq_tv(40, 95, 110, 31, 1.4914, 1.5051)],
    ]
