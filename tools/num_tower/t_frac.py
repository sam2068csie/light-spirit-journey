# 小數風車：循環小數、分點
from nlib import *


# ---------- nf_divide：循環小數相除 ----------

def nf_divide(x, y):
    """x、y = (位數字串)：0.\\ol{x}、0.\\ol{y}"""
    vx, vy = rep(0, "", x), rep(0, "", y)
    q = vx / vy
    dx, dy = "9" * len(x), "9" * len(y)
    assert F(int(x), int(dx)) == vx and F(int(y), int(dy)) == vy
    if len(x) == len(y):
        mid = "\\frac{%s}{%s}" % (x, y)
        hint2 = "分母都是 %s，相除時約掉，剩 \\frac{%s}{%s}，再約分" % (dx, x, y)
    else:
        mid = "\\frac{%s}{%s} × \\frac{%s}{%s}" % (x, dx, dy, y)
        hint2 = "除以 \\frac{%s}{%s} 就是乘 \\frac{%s}{%s}，再約分" % (y, dy, dy, y)
    assert not isint(q) or True
    return item("nf_divide", "frac", 1, "循環小數相除", 1.0,
                "求 \\frac{0.\\ol{%s}}{0.\\ol{%s}}，化成最簡分數。" % (x, y),
                [fl("先把兩個循環小數都化成分數：", "0.\\ol{%s} = \\frac{[0]}{%s}，0.\\ol{%s} = \\frac{[1]}{%s}" % (x, dx, y, dy),
                    [x.lstrip("0"), y.lstrip("0")], "循環節有幾位，分母就是幾個 9，分子是循環節"),
                 fl("相除，再約分：", "\\frac{0.\\ol{%s}}{0.\\ol{%s}} = %s = [0]" % (x, y, mid), [a(q)], hint2)])


# ---------- nf_finite：能化成有限小數的分數 ----------

def nf_finite(fracs):
    cards = []
    for p, q in fracs:
        v = F(p, q)
        ok = finite(v)
        d = v.denominator
        if d == 1:
            why = "約分後是 %s，是整數（也是有限小數）" % t(v)
        else:
            fs = []
            m = d
            for pr in (2, 3, 5, 7, 11, 13):
                k = 0
                while m % pr == 0:
                    m //= pr
                    k += 1
                if k:
                    fs.append(str(pr) if k == 1 else "%d^{%d}" % (pr, k))
            assert m == 1
            fac = " × ".join(fs)
            why = "約分後是 \\frac{%d}{%d}，分母 %d%s" % (v.numerator, d, d, ("" if len(fs) == 1 and "^" not in fac else " = " + fac))
            why += "，只有 2、5" if ok else "，有 2、5 以外的質因數"
        cards.append(cardc("\\frac{%d}{%d} 可以化成有限小數" % (p, q), ok, why, ok))
    return item("nf_finite", "frac", 1, "能化成有限小數的分數", 1.0,
                "下列分數哪些可以化成有限小數？",
                [jd("先約分，再看分母：只有質因數 2、5 的才是有限小數。", cards)])


# ---------- nf_bar：循環節畫在哪裡 ----------

def nf_bar(A, B, P, Q, k):
    """比較 A、B（(整數, 不循環, 循環)），再求 P/Q 小數點後第 k 位"""
    va, vb = rep(*A), rep(*B)
    assert va != vb
    ta, tb = rep_t(*A), rep_t(*B)
    def first(v, n=7):
        return "%d." % int(v) + "".join(str(digit(v, i)) for i in range(1, n + 1))
    big = "%s 比較大" % (ta if va > vb else tb)
    small = "%s 比較大" % (tb if va > vb else ta)
    # 找第一個不同的位數
    i = 1
    while digit(va, i) == digit(vb, i):
        i += 1
    v = F(P, Q)
    # P/Q 的循環小數
    found = None
    for n in range(0, 4):
        for c in range(1, 7):
            ip = int(v)
            s = "".join(str(digit(v, j)) for j in range(1, n + c + 1))
            if rep(ip, s[:n], s[n:]) == v:
                found = (ip, s[:n], s[n:])
                break
        if found:
            break
    ip, nr, cy = found
    assert (len(nr), len(cy)) in ((1, 2), (1, 3), (2, 2))
    dk = digit(v, k)
    r = (k - len(nr)) % len(cy)
    pos = r if r else len(cy)
    assert int(cy[pos - 1]) == dk
    wrong = [rep_t(ip, "", nr + cy), rep_t(ip, "", (nr + cy)[:len(cy)]), rep_t(ip, nr, cy[::-1])]
    wrong = [w for w in wrong if w != rep_t(*found)]
    for w in wrong:
        import re as _re
        mm = _re.match(r"(\d+)\.(\d*)\\ol\{(\d+)\}", w)
        assert rep(int(mm.group(1)), mm.group(2), mm.group(3)) != v, w
    return item("nf_bar", "frac", 1, "循環節畫在哪裡", 1.05,
                "(1) %s 和 %s 哪一個比較大？\n(2) \\frac{%d}{%d} 化成循環小數，小數點後第 %d 位是多少？" % (ta, tb, P, Q, k),
                [ch("把兩個數多寫幾位再比：", [big, small, "一樣大", "無法比較"],
                    "%s = %s…，%s = %s…" % (ta, first(va), tb, first(vb)),
                    "%s…　%s…：第 %d 位 %d %s %d" % (first(va), first(vb), i, digit(va, i), ">" if va > vb else "<", digit(vb, i))),
                 ch("\\frac{%d}{%d} 寫成循環小數是？" % (P, Q), uniq([rep_t(*found)], wrong, 4 if len(wrong) >= 3 else 3),
                    "直接做除法，看哪一段開始重複", "\\frac{%d}{%d} = %s" % (P, Q, rep_t(*found))),
                 fl("第 %d 位：%s" % (k, "前 %d 位不循環" % len(nr)),
                    "(%d − %d) 除以 %d 餘 %d　→　第 %d 位是循環節的第 %d 個：[0]" % (k, len(nr), len(cy), r, k, pos), [str(dk)],
                    "從第 %d 位開始 %s 一直重複，餘 0 就是循環節的最後一個" % (len(nr) + 1, cy))])


# ---------- nf_digit：由兩個位數反求分子 ----------

CYC = {13: ["076923", "153846"], 7: ["142857"]}


def nf_digit(d, k1, v1, k2, v2):
    n = None
    for m in range(1, d):
        if digit(F(m, d), k1) == v1 and digit(F(m, d), k2) == v2:
            assert n is None, "答案不唯一"
            n = m
    assert n
    L = 6
    r1, r2 = (k1 - 1) % L + 1, (k2 - 1) % L + 1
    cyc = "".join(str(digit(F(n, d), j)) for j in range(1, 7))
    # 錯的選項：其他輪轉
    rots = []
    for base in CYC[d]:
        for s in range(6):
            rr = base[s:] + base[:s]
            if rr != cyc:
                rots.append(rr)
    # 優先選第 r1 位也對的（只看一個條件會選錯）
    trap = [rr for rr in rots if int(rr[r1 - 1]) == v1] + [rr for rr in rots if int(rr[r2 - 1]) == v2]
    opts = uniq(["0.\\ol{%s}" % cyc], ["0.\\ol{%s}" % rr for rr in trap + rots], 4)
    given = "、".join("\\frac{1}{%d} = 0.\\ol{%s}" % (d, c) if i == 0 else "\\frac{2}{%d} = 0.\\ol{%s}" % (d, c) for i, c in enumerate(CYC[d]))
    return item("nf_digit", "frac", 2, "由兩個位數反求分子", 1.15,
                "已知 %s。正整數 n < %d，\\frac{n}{%d} 小數點後第 %d 位是 %d、第 %d 位是 %d，求 n。" % (given, d, d, k1, v1, k2, v2),
                [fl("循環節有 6 位。第 %d、%d 位各是循環節的第幾個？" % (k1, k2), "%d = 6 × %d + [0]，%d = 6 × %d + [1]" % (k1, (k1 - r1) // 6, k2, (k2 - r2) // 6),
                    [str(r1), str(r2)], "除以 6 的餘數；剛好整除的話是第 6 個"),
                 ch("\\frac{n}{%d} 的循環節第 %d 個是 %d、第 %d 個是 %d，是哪一個？" % (d, r1, v1, r2, v2), opts,
                    "\\frac{n}{%d} 的循環節是 %s 的輪轉；兩個條件都要對" % (d, "或".join(CYC[d])), "\\frac{n}{%d} = 0.\\ol{%s}" % (d, cyc)),
                 fl("求 n：", "n = %d × \\frac{%s}{999999} = [0]" % (d, cyc.lstrip("0") or "0"), [str(n)], "0.\\ol{%s} = \\frac{%s}{999999}，乘 %d" % (cyc, cyc.lstrip("0"), d))])


# ---------- nf_two：兩個分點 ----------

def nf_two(A, B, m, n):
    """\\ol{PA} : \\ol{PB} = m : n，內分 P1、外分 P2"""
    P1 = F(n * A + m * B, m + n)
    P2 = F(n * A - m * B, n - m)
    assert abs(P1 - A) / abs(P1 - B) == F(m, n) and abs(P2 - A) / abs(P2 - B) == F(m, n)
    assert not (A < P2 < B)
    d = abs(P1 - P2)
    side = "A" if m < n else "B"
    return item("nf_two", "frac", 1, "兩個分點", 1.05,
                "數線上 A(%s)、B(%s)。P_{1}、P_{2} 都滿足 \\ol{PA} : \\ol{PB} = %d : %d，P_{1} 在 \\ol{AB} 上，P_{2} 在 \\ol{AB} 外。求 \\ol{P_{1}P_{2}}。" % (t(A), t(B), m, n),
                [fl("內分點 P_{1}：", "P_{1} = \\frac{%d × %s + %d × %s}{%d} = [0]" % (n, tp(A), m, tp(B), m + n), [a(P1)],
                    "\\ol{AP_{1}} : \\ol{P_{1}B} = %d : %d，份數交叉相乘：A 乘 %d、B 乘 %d，再除以 %d" % (m, n, n, m, m + n)),
                 ch("P_{2} 在哪一邊？", ["%s 的外側（靠近 %s）" % (side, side), "%s 的外側" % ("B" if side == "A" else "A"), "A、B 中間", "原點"],
                    "P_{2} 到 %s 比較近（%d < %d），所以在 %s 外面" % (side, min(m, n), max(m, n), side),
                    "\\ol{PA} %s \\ol{PB}：P_{2} 在 %s 的外側" % ("<" if m < n else ">", side)),
                 fl("外分點 P_{2}，再求距離：", "P_{2} = [0]，\\ol{P_{1}P_{2}} = [1]", [a(P2), a(d)],
                    "設 P_{2}(x)：\\frac{|x − %s|}{|x − %s|} = \\frac{%d}{%d}，x 在 %s 外側；距離是 |P_{1} − P_{2}|" % (tp(A), tp(B), m, n, side))])


# ---------- nf_root_pt：根號端點的分點 ----------

def nf_root_pt(sa, ra, ra_fill, sb, rb, rb_fill, k, inside, p_ans):
    """A(sa)、B(sb)：根號端點，ra、rb 是化簡後的值（Q），\\ol{PB} = k\\ol{PA}"""
    import math as _m
    assert near(float(ra), _m.sqrt(float(eval_nest(sa)))) and near(float(rb), _m.sqrt(float(eval_nest(sb))))
    if inside:
        P = (k * ra + rb) / (k + 1)
        form = "\\frac{%d a + b}{%d}" % (k, k + 1)
    else:
        P = (k * ra - rb) / (k - 1)
        form = "\\frac{%d a − b}{%d}" % (k, k - 1)
    assert abs(float(P) - float(rb)) / abs(float(P) - float(ra)) - k < 1e-9
    assert (min(float(ra), float(rb)) < float(P) < max(float(ra), float(rb))) == inside
    chk(p_ans, float(P))
    return item("nf_root_pt", "frac", 2, "根號端點的分點", 1.2,
                "數線上 A(%s)、B(%s)，點 P 在 \\ol{AB} %s，\\ol{PB} = %d\\ol{PA}。求 P 的坐標。" % (sa, sb, "上" if inside else "外", k),
                [fl("先把 A 的坐標化簡：", ra_fill[0], ra_fill[1], "寫成 √{p − 2√{q}}：找兩數，和是 p、積是 q；大的減小的"),
                 fl("B 的坐標化簡：", rb_fill[0], rb_fill[1], "寫成 √{p + 2√{q}}：找兩數，和是 p、積是 q"),
                 fl("A(a)、B(b)：\\ol{PA} : \\ol{PB} = 1 : %d，P 在 \\ol{AB} %s：" % (k, "上" if inside else "外（靠近 A）"), "P = %s = [0]" % form, [p_ans],
                    "%s" % ("內分點：靠近 A，A 要乘 %d" % k if inside else "外分點：P 在 A 外側，P = \\frac{%d a − b}{%d}" % (k, k - 1)))])


def eval_nest(s):
    """√{p − √{q}} 的根號裡：p ± √q 或 p ± c√q"""
    import re
    m = re.match(r"√\{(\d+) ([−+]) (\d*)√\{?(\d+)\}?\}", s)
    p, sg, c, q = int(m.group(1)), m.group(2), int(m.group(3) or 1), int(m.group(4))
    return p + (1 if sg == "+" else -1) * c * math.sqrt(q)


# ---------- nf_parallel：平行線截出的分點 ----------

def nf_parallel(C, B, big, small):
    """△ACQ，P 在 \\ol{CQ} 上，\\ol{PB} ∥ \\ol{QA}，\\ol{CQ} : \\ol{PQ} = big : small"""
    cp = big - small
    A = C + F(B - C) * F(big, cp)
    assert isint(A)
    # 圖：A、B、C 在橫軸上，Q 在上方
    xs = [C, B, A]
    lo, hi = min(xs), max(xs)
    span = hi - lo
    qx = float(C) + float(A - C) * 0.35
    qy = span * 0.42
    Qp = (qx, qy)
    Pp = (float(C) + (qx - float(C)) * cp / big, qy * cp / big)
    xr = (float(lo) - span * 0.12, float(hi) + span * 0.12)
    shapes = [seg((xr[0], 0), (xr[1], 0), "dim"), seg((float(C), 0), Qp, "cyan"), seg(Qp, (float(A), 0), "pink"),
              seg(Pp, (float(B), 0), "pink", dash=True),
              pt((float(C), 0), "C(%s)" % t(C), "gold", off=(-14, 22)), pt((float(B), 0), "B(%s)" % t(B), "gold", off=(-14, 22)),
              pt((float(A), 0), "A", "gold", off=(-6, 22)), pt(Qp, "Q", "text", off=(-6, -10)), pt(Pp, "P", "text", off=(-18, -4))]
    plot = {"x": [fx(xr[0]), fx(xr[1])], "y": [fx(-span * 0.16), fx(qy + span * 0.1)], "geo": True, "h": 170, "shapes": shapes}
    return item("nf_parallel", "frac", 2, "平行線截出的分點", 1.15,
                "△ACQ 中，A、B、C 在數線上，P 在 \\ol{CQ} 上，\\ol{PB} ∥ \\ol{QA}，\\ol{CQ} : \\ol{PQ} = %d : %d。已知 B(%s)、C(%s)，求 A 的坐標。" % (big, small, t(B), t(C)),
                [fl("\\ol{CP} 占 \\ol{CQ} 的幾份？", "\\ol{CP} : \\ol{CQ} = [0] : %d" % big, [str(cp)], "\\ol{CP} = \\ol{CQ} − \\ol{PQ}"),
                 ch("\\ol{PB} ∥ \\ol{QA}，所以 \\ol{CB} : \\ol{CA} = ？", ["%d : %d" % (cp, big), "%d : %d" % (small, big), "%d : %d" % (cp, small), "%d : %d" % (small, cp)],
                    "平行線截出的線段成比例：\\ol{CB} : \\ol{CA} = \\ol{CP} : \\ol{CQ}", "\\ol{CB} : \\ol{CA} = %d : %d" % (cp, big)),
                 fl("\\ol{CB} = |%s − %s| = %s，求 A：" % (t(B), tp(C), t(abs(B - C))), "\\ol{CA} = [0]，A 的坐標 = [1]", [a(abs(A - C)), a(A)],
                    "\\ol{CA} = \\ol{CB} × \\frac{%d}{%d}；A 和 B 在 C 的同一邊" % (big, cp))],
                plot=plot)


def items():
    return [
        [nf_divide("126", "315"), nf_divide("36", "81"), nf_divide("6", "148")],
        [nf_finite([(21, 60), (15, 36), (39, 48), (45, 14), (72, 24)]),
         nf_finite([(27, 150), (35, 84), (18, 75), (22, 96), (56, 7)]),
         nf_finite([(33, 55), (49, 140), (26, 91), (51, 68), (10, 24)])],
        [nf_bar((1, "", "234"), (1, "2", "34"), 329, 990, 2025), nf_bar((2, "", "51"), (2, "5", "1"), 3, 22, 2026),
         nf_bar((0, "", "307"), (0, "30", "7"), 2143, 9990, 1000)],
        [nf_digit(13, 22, 3, 32, 1), nf_digit(7, 20, 2, 40, 5), nf_digit(13, 50, 4, 99, 6)],
        [nf_two(-3, 9, 1, 3), nf_two(-4, 11, 4, 1), nf_two(1, 22, 2, 5)],
        [nf_root_pt("√{3 − √{8}}", Q(-1, 1, 2), ("√{3 − √{8}} = √{3 − 2√{2}} = √{[0]} − [1]", ["2", "1"]),
                    "√{17 + 12√{2}}", Q(3, 2, 2), ("√{17 + 12√{2}} = √{17 + 2√{72}} = [0] + [1]√{2}", ["3", "2"]), 3, True, "5√2/4"),
         nf_root_pt("√{7 − √{48}}", Q(2, -1, 3), ("√{7 − √{48}} = √{7 − 2√{12}} = [0] − √{[1]}", ["2", "3"]),
                    "√{13 + √{48}}", Q(1, 2, 3), ("√{13 + √{48}} = √{13 + 2√{12}} = [0] + [1]√{3}", ["1", "2"]), 2, True, "5/3"),
         nf_root_pt("√{4 − √{12}}", Q(-1, 1, 3), ("√{4 − √{12}} = √{4 − 2√{3}} = √{[0]} − [1]", ["3", "1"]),
                    "√{28 + 6√{3}}", Q(1, 3, 3), ("√{28 + 6√{3}} = √{28 + 2√{27}} = [0] + [1]√{3}", ["1", "3"]), 3, False, "−2")],
        [nf_parallel(-2, 4, 5, 3), nf_parallel(6, 0, 7, 4), nf_parallel(1, 7, 4, 1)],
    ]
