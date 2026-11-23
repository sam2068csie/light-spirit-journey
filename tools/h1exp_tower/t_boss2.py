# 試煉大題（二）：指數的代數、位數、計數、算幾、比大小、應用
from xlib import *

LOGS = {2: "0.3010", 3: "0.4771", 5: "0.6990", 7: "0.8451"}


def _one(x):
    return "%.1f" % (x + 1e-9)


# ---------- xb_sum：3^{x} + 2^{x} = a ----------

def xb_sum(p, q, k):
    """p^x + q^x = a，(p²q)^x + (pq²)^x = k a ⇒ (pq)^x = k"""
    m = p * q
    x = math.log(k) / math.log(m)
    av = p ** x + q ** x
    assert near((p * p * q) ** x + (p * q * q) ** x, k * av)
    assert near((p ** 3) ** x + (q ** 3) ** x, av ** 3 - 3 * k * av)
    assert near((p * p) ** x + (q * q) ** x, av * av - 2 * k)
    A, B = p * p * q, p * q * q
    return item("xb_sum", "boss", 3, "提出公因式的指數", 1.65,
                "%d^{x} + %d^{x} = a，%d^{x} + %d^{x} = %da。\n(1) 求 %d^{x}　(2) 用 a 表示 %d^{x} + %d^{x}　(3) 用 a 表示 %d^{x} + %d^{x}" % (p, q, A, B, k, m, p * p, q * q, p ** 3, q ** 3),
                [ch("%d^{x} + %d^{x} 可以提出？" % (A, B), ["%d^{x}(%d^{x} + %d^{x})" % (m, p, q), "%d^{x}(%d^{x} − %d^{x})" % (m, p, q), "%d^{2x}(%d + %d)" % (m, p, q),
                                                    "(%d^{x} + %d^{x})^{2}" % (p, q)],
                    "%d = %d × %d、%d = %d × %d" % (A, m, p, B, m, q), "%d^{x} + %d^{x} = %d^{x}(%d^{x} + %d^{x}) = %d^{x} · a" % (A, B, m, p, q, m), part="(1)"),
                 fl("和 %da 比較（a > 0）：" % k, "(1)　%d^{x} = [0]" % m, [str(k)], "兩邊除以 a", part="(1)"),
                 fl("平方和：", "(2)　%d^{x} + %d^{x} = (%d^{x} + %d^{x})^{2} − 2 · %d^{x} = a^{2} − [0]" % (p * p, q * q, p, q, m), [str(2 * k)], "(u + v)^{2} = u^{2} + v^{2} + 2uv，uv = %d^{x}" % m, part="(2)"),
                 ch("立方和：%d^{x} + %d^{x} = ？" % (p ** 3, q ** 3), ["a^{3} − %da" % (3 * k), "a^{3} − %da" % k, "a^{3} + %da" % (3 * k), "a^{3} − %d" % (3 * k)],
                    "u^{3} + v^{3} = (u + v)^{3} − 3uv(u + v)，uv = %d" % k, "(3)　%d^{x} + %d^{x} = a^{3} − 3 × %d × a = a^{3} − %da" % (p ** 3, q ** 3, k, 3 * k), part="(3)")])


# ---------- xb_factor：乘開後的位數 ----------

def xb_factor(n, kind, lg_parts):
    """kind = "six"：(n − 1)(n + 1)(n² + n + 1)(n² − n + 1) = n^6 − 1；"four"：(n − 1)(n + 1)(n² + 1) = n^4 − 1"""
    if kind == "six":
        e = 6
        val = (n - 1) * (n + 1) * (n * n + n + 1) * (n * n - n + 1)
        stem = "%d × %d × (%d^{2} + %d + 1)(%d^{2} − %d + 1)" % (n - 1, n + 1, n, n, n, n)
        pair = ch("先配對：%d × (%d^{2} + %d + 1) = ？" % (n - 1, n, n), ["%d^{3} − 1" % n, "%d^{3} + 1" % n, "%d^{3}" % (n - 1), "%d^{3} − %d" % (n, n - 1)],
                  "立方差：(a − 1)(a^{2} + a + 1) = a^{3} − 1", "(1)　%d × (%d^{2} + %d + 1) = %d^{3} − 1，%d × (%d^{2} − %d + 1) = %d^{3} + 1" % (n - 1, n, n, n, n + 1, n, n, n), part="(1)")
        hint2 = "(%d^{3} − 1)(%d^{3} + 1) 是平方差" % (n, n)
    else:
        e = 4
        val = (n - 1) * (n + 1) * (n * n + 1)
        stem = "%d × %d × (%d^{2} + 1)" % (n - 1, n + 1, n)
        pair = ch("先算：%d × %d = ？" % (n - 1, n + 1), ["%d^{2} − 1" % n, "%d^{2} + 1" % n, "%d^{2}" % n, "%d^{2} − 2" % n],
                  "平方差：(a − 1)(a + 1) = a^{2} − 1", "(1)　%d × %d = %d^{2} − 1" % (n - 1, n + 1, n), part="(1)")
        hint2 = "(%d^{2} − 1)(%d^{2} + 1) 也是平方差" % (n, n)
    assert val == n ** e - 1
    lv = sum(c * float(LOGS[pp]) for pp, c in lg_parts)
    assert abs(lv - lg(n)) < 3e-4
    L = e * lv
    digits = math.floor(L) + 1
    assert len(str(val)) == digits == len(str(n ** e))
    lt = " + ".join(("%d log %d" % (c, pp) if c != 1 else "log %d" % pp) for pp, c in lg_parts)
    lvs = "%.4f" % lv
    Ls = ("%.4f" % (e * float(lvs))).rstrip("0").rstrip(".")
    fac = " × ".join(("%d^{%d}" % (pp, c) if c != 1 else str(pp)) for pp, c in lg_parts)
    return item("xb_factor", "boss", 3, "乘開後的位數", 1.7,
                "N = %s。（log 2 ≈ 0.3010、log 3 ≈ 0.4771、log 7 ≈ 0.8451）\n(1) 化簡 N　(2) N 是幾位數？" % stem,
                [pair,
                 fl("全部乘起來：", "　 　N = %d^{[0]} − 1" % n, [str(e)], hint2, part="(1)"),
                 fl("%d = %s：" % (n, fac), "(2)　log %d = %s ≈ [0]" % (n, lt), [lvs], "log 的乘法變加法", part="(2)"),
                 fl("位數：", "　 　log %d^{%d} ≈ [0]，%d^{%d} 和 N 都是 [1] 位數" % (n, e, n, e), [Ls, str(digits)],
                    "%d^{%d} 不是 10 的次方，減 1 不會少一位" % (n, e), part="(2)")])


# ---------- xb_count：正整數解有幾組 ----------

def xb_count(base, ks, total, Nt):
    """base^{k} (base^{ks[1]})^{m} (base^{ks[2]})^{n} = base^{total}：k + ks[1] m + ks[2] n = total（正整數）"""
    c1, c2 = ks[1], ks[2]
    sols = [(k, m, n) for n in range(1, total) for m in range(1, total) for k in range(1, total) if k + c1 * m + c2 * n == total]
    by_n = {}
    for k, m, n in sols:
        by_n[n] = by_n.get(n, 0) + 1
    ns = sorted(set(range(1, max(by_n) + 2)))
    ns = [n for n in ns if total - c2 * n - c1 >= 1] or ns
    counts = [by_n.get(n, 0) for n in ns]
    assert sum(counts) == len(sols) and len(ns) <= 4
    B1, B2 = base ** c1, base ** c2
    parts = "；".join("n = %d：k + %dm = %d，[%d] 組" % (n, c1, total - c2 * n, i) for i, n in enumerate(ns))
    return item("xb_count", "boss", 3, "正整數解有幾組", 1.65,
                "k、m、n 都是正整數，%d^{k} × %d^{m} × %d^{n} = %s。\n(1) 寫成 k、m、n 的關係式　(2) 依 n 分類，數出 (k, m, n) 有幾組" % (base, B1, B2, Nt),
                [fl("全部換成 %d 的次方：" % base, "(1)　%d^{k + %dm + %dn} = %d^{[0]}" % (base, c1, c2, base, ), [str(total)], "%d = %d^{%d}、%d = %d^{%d}；%s = %d^{%d}" % (B1, base, c1, B2, base, c2, Nt, base, total), part="(1)"),
                 fl("n 從 1 開始試，k、m 都要 ≥ 1：", "(2)　" + parts, [str(c) for c in counts],
                    "k = %d − %dn − %dm ≥ 1，數 m 可以是幾" % (total, c2, c1), part="(2)"),
                 fl("n 再大，k + %dm 就不到 %d（k、m 至少是 1）：" % (c1, c1 + 1), "　 　共 [0] 組", [str(len(sols))], "把每一類加起來", part="(2)")])


# ---------- xb_amgm：指數的算幾 ----------

def xb_amgm(b, p, q, c, bp, bq):
    """p x + q y = c，求 b1^{x} + b2^{y} 的最小值；b1 = b^{p}、b2 = b^{q}"""
    B1, B2 = b ** p, b ** q
    mn = 2 * b ** F(c, 2)
    assert isint(mn)
    X, Y = F(c, 2 * p), F(c, 2 * q)
    m = min(B1 ** (i / 100) + B2 ** ((c - p * i / 100) / q) for i in range(-300, 1000))
    assert m >= float(mn) - 1e-9
    return item("xb_amgm", "boss", 3, "指數的算幾", 1.65,
                "x、y 是實數，%s = %d，求 %d^{x} + %d^{y} 的最小值，以及這時的 x、y。" % (poly([(p, "x"), (q, "y")]), c, B1, B2),
                [fl("兩項都是正數，乘積是定值：", "(1)　%d^{x} × %d^{y} = %d^{%s} = %d^{[0]}" % (B1, B2, b, poly([(p, "x"), (q, "y")]), b), [str(c)],
                    "%d^{x} = %d^{%s}、%d^{y} = %d^{%s}" % (B1, b, cof(p, "x", True), B2, b, cof(q, "y", True)), part="(1)"),
                 fl("算幾：", "(2)　%d^{x} + %d^{y} ≥ 2√{%d^{%d}} = [0]" % (B1, B2, b, c), [a(mn)], "2√{%d^{%d}} = 2 × %d^{%s}" % (b, c, b, tf(F(c, 2))), part="(2)"),
                 fl("等號成立時兩項相等：", "　 　%s = %s = [0]，x = [1]，y = [2]" % (cof(p, "x", True), cof(q, "y", True)), [a(F(c, 2)), a(X), a(Y)],
                    "%d^{x} = %d^{y} 代表 %s = %s，又 %s = %d" % (B1, B2, cof(p, "x", True), cof(q, "y", True), poly([(p, "x"), (q, "y")]), c), part="(2)")])


# ---------- xb_order：三個根號比大小 ----------

def xb_order(trip):
    """trip = [(底數, 根次, log 的寫法, log 的近似值)]"""
    names = ["%d^{\\frac{1}{%d}}" % (bb, r) for bb, r, _, _ in trip]
    vs = [lv / r for bb, r, _, lv in trip]
    true_vs = [lg(bb) / r for bb, r, _, _ in trip]
    rs = ["%.4f" % v for v in vs]
    assert len(set(rs)) == 3
    idx = sorted(range(3), key=lambda i: -vs[i])
    assert idx == sorted(range(3), key=lambda i: -true_vs[i])
    s = lambda ix: " > ".join(names[i] for i in ix)
    opts = uniq([s(idx)], [s(idx[::-1]), s([idx[1], idx[0], idx[2]]), s([idx[0], idx[2], idx[1]])], 4)
    given = "、".join("log %d ≈ %.4f" % (bb, lv) for bb, r, _, lv in trip if bb != 10)
    return item("xb_order", "boss", 3, "三個根號比大小", 1.65,
                "比較 %s 的大小。（%s）\n(1) 分別取 log　(2) 由大到小排列" % ("、".join(names), given),
                [fl("取 log，真數越大 log 越大：", "(1)　log %s ≈ [0]，log %s ≈ [1]，log %s ≈ [2]（取到小數第四位）" % tuple(names), rs,
                    "log a^{\\frac{1}{r}} = \\frac{log a}{r}，例如 %s 除以 %d" % (("%.4f" % trip[0][3]), trip[0][1]), part="(1)"),
                 ch("由大到小：", opts, "log 值越大，數越大", "(2)　" + opts[0], part="(2)")])


# ---------- xb_tv：電視牆加深 ----------

def xb_tv(N, each, limit, lgN_t, lgN, k, lk, lk1, each2):
    tot = each + 10 * lgN
    assert near(lgN, lg(N), 2e-4)
    c = F(limit - each, 10)
    assert lg(k) <= float(c) < lg(k + 1) and lk <= float(c) < lk1
    tot2 = each2 + 10 * lgN
    over = tot2 > limit
    assert (each2 + 10 * lg(N) > limit) == over
    cs = ("%.2f" % float(c)).rstrip("0").rstrip(".")
    return item("xb_tv", "boss", 3, "電視牆加深", 1.7,
                "電視牆 %d 台，每台 %d 分貝；k 台一起開是 %d + 10 log k 分貝。（log 2 ≈ 0.3010、log %d ≈ %.4f、log %d ≈ %.4f）\n(1) 全開幾分貝？　(2) 不超過 %d 分貝，最多開幾台？　(3) 換成每台 %d 分貝，全開會超過 %d 分貝嗎？" %
                (N, each, each, k, lk, k + 1, lk1, limit, each2, limit),
                [fl("k = %d 代入：" % N, "(1)　%d + 10 %s ≈ [0]（取一位小數）" % (each, lgN_t), [_one(tot)], "%s ≈ %s" % ({25: "log 25 = 2 − 2 log 2", 40: "log 40 = 1 + 2 log 2", 20: "log 20 = 1 + log 2"}[N], ("%.4f" % lgN).rstrip("0")), part="(1)"),
                 fl("列不等式：", "(2)　%d + 10 log k ≤ %d → log k ≤ [0]，最多 [1] 台" % (each, limit), [cs, str(k)], "log %d ≤ %s < log %d" % (k, cs, k + 1), part="(2)"),
                 ch("每台 %d 分貝，%d 台全開：" % (each2, N), ["不會超過" if not over else "會超過", "會超過" if not over else "不會超過", "剛好 %d 分貝" % limit, "要看是哪幾台"],
                    "%d + 10 %s，和 %d 比" % (each2, lgN_t, limit), "(3)　%d + 10 %s ≈ %s，%s %d" % (each2, lgN_t, _one(tot2), ">" if over else "≤", limit), part="(3)")])


# ---------- xb_grow：細菌何時破百萬 ----------

def xb_grow(h, n1, N1, n2, N2, thr_e, d1, d2):
    q = F(N2, N1)
    k = n2 - n1
    r = round(float(q) ** (1 / k))
    assert F(r) ** k == q
    N0 = F(N1, r ** n1)
    assert isint(N0)
    N0 = int(N0)
    lr = {2: L2, 3: L3}[r]
    rhs = thr_e - {1: 0, 2: L2, 3: L3, 5: 1 - L2}[N0]           # n log r > thr − log N0
    need = rhs / lr
    n = math.floor(need) + 1
    assert N0 * r ** n > 10 ** thr_e >= N0 * r ** (n - 1)
    rhs_s = ("%.4f" % rhs).rstrip("0").rstrip(".")
    lgN0 = {1: "0", 2: "log 2", 3: "log 3", 5: "log 5"}[N0]
    return item("xb_grow", "boss", 3, "細菌何時破表", 1.7,
                "一種細菌每 %d 小時數量變成原來的 r 倍。%s後有 %d 隻，%s後有 %d 隻。（log 2 ≈ 0.3010、log 3 ≈ 0.4771）\n(1) 求 r 和最初的數量　(2) 從最初算起，最少經過幾個 %d 小時，數量會超過 10^{%d} 隻？" % (h, d1, N1, d2, N2, h, thr_e),
                [fl("兩個時刻相除：", "(1)　r^{%d} = \\frac{%d}{%d}，r = [0]，最初 [1] 隻" % (k, N2, N1), [str(r), str(N0)], "%s = %d 個 %d 小時、%s = %d 個" % (d1, n1, h, d2, n2), part="(1)"),
                 fl("經過 n 個 %d 小時：%d × %d^{n} > 10^{%d}，取 log：" % (h, N0, r, thr_e), "(2)　n log %d > %d − %s ≈ [0]" % (r, thr_e, lgN0), [rhs_s],
                    ("log %d + n log %d > %d" % (N0, r, thr_e) + ("；log 5 = 1 − log 2" if N0 == 5 else "")) if N0 != 1 else "n log %d > %d" % (r, thr_e), part="(2)"),
                 fl("解出 n（n 是整數）：", "　 　n > \\frac{%s}{%s} ≈ %.1f，最少 [0] 個 %d 小時，也就是 [1] 小時" % (rhs_s, LOGS[r], need, h), [str(n), str(n * h)],
                    "比 %.1f 大的最小整數" % need, part="(2)")])


def items():
    return [
        [xb_sum(3, 2, 5), xb_sum(5, 2, 3), xb_sum(3, 4, 7)],
        [xb_factor(168, "six", [(2, 3), (3, 1), (7, 1)]), xb_factor(24, "six", [(2, 3), (3, 1)]), xb_factor(36, "four", [(2, 2), (3, 2)])],
        [xb_count(2, (1, 2, 3), 10, "1024"), xb_count(3, (1, 2, 3), 12, "531441"), xb_count(2, (1, 2, 4), 14, "16384")],
        [xb_amgm(2, 2, 1, 6, 4, 2), xb_amgm(3, 1, 3, 4, 3, 27), xb_amgm(2, 3, 2, 10, 8, 4)],
        [xb_order([(2, 3, "log 2", L2), (3, 5, "log 3", L3), (5, 7, "log 5", 1 - L2)]),
         xb_order([(2, 2, "log 2", L2), (3, 3, "log 3", L3), (5, 5, "log 5", 1 - L2)]),
         xb_order([(6, 4, "log 6", L2 + L3), (3, 3, "log 3", L3), (10, 6, "log 10", 1.0)])],
        [xb_tv(25, 108, 120, "log 25", 2 * (1 - L2), 15, 1.1761, 1.2041, 105), xb_tv(40, 100, 113, "log 40", 1 + 2 * L2, 19, 1.2788, 1.3010, 98),
         xb_tv(20, 102, 114, "log 20", 1 + L2, 15, 1.1761, 1.2041, 99)],
        [xb_grow(12, 8, 1280, 13, 40960, 6, "4 天", "6.5 天"), xb_grow(8, 6, 1458, 9, 39366, 6, "2 天", "3 天"), xb_grow(6, 4, 80, 10, 5120, 5, "1 天", "2.5 天")],
    ]
