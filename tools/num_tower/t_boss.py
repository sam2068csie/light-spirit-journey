# 試煉大題（一）：證明、反例、圍籬
from nlib import *

S = math.sqrt


# ---------- nb_proof：證明不是有理數 ----------

def nb_proof(m, n):
    """證明 √m + √n 不是有理數：平方得 m + n + 2√(mn)，2√(mn) = c√r"""
    s = rt(m * n)
    c2 = 2 * s.c
    r = s.n
    assert r > 1 and isint(c2)
    c2 = int(c2)
    k2 = m + n
    x = "√{%d} + √{%d}" % (m, n)
    return item("nb_proof", "boss", 2, "證明不是有理數", 1.6,
                "證明 %s 不是有理數。\n(1) 假設 %s = k 是有理數，兩邊平方　(2) 解出 √{%d}　(3) 指出矛盾" % (x, x, r),
                [fl("兩邊平方：", "(1)　k^{2} = %d + 2√{%d} = [0] + [1]√{%d}" % (k2, m * n, r), [str(k2), str(c2)],
                    "(√{%d} + √{%d})^{2} = %d + %d + 2√{%d}，再把 √{%d} 化簡" % (m, n, m, n, m * n, m * n), part="(1)"),
                 ch("把 √{%d} 單獨留在一邊：" % r, ["√{%d} = \\frac{k^{2} − %d}{%d}" % (r, k2, c2), "√{%d} = \\frac{k^{2} + %d}{%d}" % (r, k2, c2),
                                                 "√{%d} = k^{2} − %d" % (r, k2), "√{%d} = \\frac{k − %d}{%d}" % (r, k2, c2)],
                    "移項：%d√{%d} = k^{2} − %d" % (c2, r, k2), "(2)　√{%d} = \\frac{k^{2} − %d}{%d}" % (r, k2, c2), part="(2)"),
                 ch("矛盾在哪裡？", ["左邊無理、右邊有理", "k 不能是整數", "分母不能是 %d" % c2, "k^{2} 一定是無理數"],
                    "k 是有理數，有理數加減乘除（分母不是 0）還是有理數", "(3)　k 有理 ⇒ \\frac{k^{2} − %d}{%d} 有理，但 √{%d} 是無理數，矛盾" % (k2, c2, r), part="(3)")])


# ---------- nb_counter：找反例 ----------

def nb_counter(p, n):
    """a = (p + √n)^2、b = (p − √n)^2：都是無理數，但 √a + √b = 2p"""
    assert p * p > n
    A, B = Q(p, 1, n) ** 2, Q(p, -1, n) ** 2
    assert not A.rat() and not B.rat()
    assert near(S(float(A)) + S(float(B)), 2 * p)
    return item("nb_counter", "boss", 2, "找反例", 1.6,
                "「a、b 都是無理數，則 √{a} + √{b} 一定是無理數。」\n(1) 這句話對嗎？　(2) 取 a = (%d + √{%d})^{2}、b = (%d − √{%d})^{2}，展開　(3) 算 √{a} + √{b}" % (p, n, p, n),
                [ch("先猜猜看：", ["不一定", "一定對", "一定是有理數", "要看 a、b 是不是整數"],
                    "試試看 a、b 是兩個互相「抵消」的平方", "(1)　不一定成立，下面找反例", part="(1)"),
                 fl("展開 a、b：", "(2)　a = [0] + [1]√{%d}，b = [0] − [1]√{%d}，都是無理數" % (n, n), [a(A.a), a(A.b)],
                    "(%d ± √{%d})^{2} = %d + %d ± %d√{%d}" % (p, n, p * p, n, 2 * p, n), part="(2)"),
                 fl("算 √{a} + √{b}（注意 %d − √{%d} > 0）：" % (p, n), "(3)　√{a} + √{b} = (%d + √{%d}) + (%d − √{%d}) = [0]" % (p, n, p, n), [str(2 * p)],
                    "√{x^{2}} = |x|，%d − √{%d} 是正的" % (p, n), part="(3)")])


# ---------- nb_river：臨河的牧場 ----------

def nb_river(area, k):
    """一邊靠河，垂直河岸的柵欄有 k 道（k = 2：只有兩側；k = 3：中間再加一道），面積 area"""
    g = math.isqrt(k * area)
    assert g * g == k * area
    best = 2 * g
    x = F(g, k)              # 垂直河岸的邊
    y = g                    # 平行河岸的邊
    assert x * y == area and isint(x)
    m = min(k * F(i, 10) + F(area) / F(i, 10) for i in range(1, 3000))
    assert m >= best
    W = float(y)
    H = float(x)
    shapes = [seg((-W * 0.15, H), (W * 1.15, H), "cyan", w=4.0), poly_sh([(0, H), (W, H), (W, 0), (0, 0)], "lime", fill="lime")]
    if k == 3:
        shapes.append(seg((W / 2, H), (W / 2, 0), "lime"))
    shapes += [lab((W / 2, H + H * 0.18), "y", "text"), lab((-W * 0.09, H / 2), "x", "text")]
    plot = {"x": [fx(-W * 0.2), fx(W * 1.2)], "y": [fx(-H * 0.25), fx(H * 1.45)], "geo": True, "h": 150, "shapes": shapes}
    fence = "%dx + y" % k
    return item("nb_river", "boss", 2, "臨河的牧場", 1.6,
                "沿著河岸圍一塊面積 %d 平方公尺的長方形牧場，靠河的一邊不用柵欄%s。\n(1) 柵欄至少要多長？　(2) 這時長方形的長、寬各是多少？" % (area, "，中間再用一道柵欄隔成兩塊（如圖）" if k == 3 else "（如圖）"),
                [ch("垂直河岸的邊 x、平行河岸的邊 y，柵欄總長是？", [fence, "%dx + 2y" % k, "x + y" if k == 2 else "2x + y", "x + 2y" if k == 2 else "2x + 2y"],
                    "數一數：垂直河岸的有 %d 道，平行河岸的只有遠離河的那一道" % k, "柵欄長 = %s，xy = %d" % (fence, area), part="(1)"),
                 fl("用算幾：", "(1)　%s ≥ 2√{%dxy} = 2√{%d} = [0]" % (fence, k, k * area), [str(best)], "%dx 和 y 的積是 %d × %d" % (k, k, area), part="(1)"),
                 fl("等號成立時 %dx = y：" % k, "(2)　y = [0]，x = [1]（公尺）", [str(y), a(x)], "%dx = y = \\frac{%d}{2}" % (k, best), part="(2)")],
                plot=plot)


# ---------- nb_posts：伸縮圍欄柱 ----------

def nb_posts(n, need):
    per = 2 * n
    side = F(per, 4)
    best = side * side
    assert isint(side)
    # 邊長是 2 的倍數：2m × 2p，面積 4mp ≥ need，m + p 最小
    mn = None
    for s_ in range(1, 200):
        if any(4 * m * (s_ - m) >= need for m in range(1, s_)):
            mn = s_
            break
    perim = 4 * mn
    posts = perim // 2
    more = posts - n
    assert best < need and more > 0 and side % 2 == 0
    q = math.ceil(F(need, 4))
    return item("nb_posts", "boss", 2, "伸縮圍欄柱", 1.65,
                "每兩支相鄰的伸縮柱之間拉 2 公尺的圍欄，柱子擺在長方形的邊上（四個角都有柱子），圍成一圈。\n(1) %d 支柱子圍出的長方形，面積最大多少？　(2) 能圍出 %d 平方公尺嗎？　(3) 至少要再補幾支？" % (n, need),
                [fl("周長固定時，正方形面積最大：", "(1)　周長 = %d × 2 = [0]，最大面積 = [1]" % n, [str(per), a(best)],
                    "周長 %d 的正方形邊長 %s" % (per, t(side)), part="(1)"),
                 ch("面積 %d 夠不夠？" % need, ["不能", "能", "剛好可以", "要看形狀"],
                    "周長不變時，正方形的面積最大", "(2)　%s < %d，圍不出來" % (t(best), need), part="(2)"),
                 fl("邊長是 2 的倍數：設長 2m、寬 2p（m、p 是正整數）", "(3)　4mp ≥ %d，mp ≥ %d，m + p 最小是 [0]" % (need, q), [str(mn)],
                    "m + p 固定時 m、p 越接近乘積越大：試 m + p = %d、%d" % (mn - 1, mn), part="(3)"),
                 fl("需要幾支柱子？", "　 　周長 = 4 × %d = %d，柱子 %d 支，至少再補 [0] 支" % (mn, perim, posts), [str(more)], "一圈的柱子數 = 周長除以 2", part="(3)")])


# ---------- nb_stairs：階梯形的農地 ----------

def nb_stairs(rows, align, L):
    """rows：由上到下每一列的塊數；align = "center"／"left"；L：柵欄總長"""
    nh = rows[0] + sum(max(rows[i], rows[i + 1]) for i in range(len(rows) - 1)) + rows[-1]
    nv = sum(r + 1 for r in rows)
    assert all(rows[i] <= rows[i + 1] for i in range(len(rows) - 1))
    X, Y = F(L, 2 * nh), F(L, 2 * nv)
    xy = X * Y
    N = sum(rows)
    assert isint(X) and isint(Y)
    m = max(F(i, 4) * (F(L) - nh * F(i, 4)) / nv for i in range(1, 4 * L // nh))
    assert m <= xy
    # 圖：每塊寬 1、高 0.8
    w, h = 1.0, 0.75
    W = max(rows)
    shapes = []
    for i, r in enumerate(rows):
        y0 = (len(rows) - 1 - i) * h
        x0 = (W - r) / 2 if align == "center" else 0
        for j in range(r):
            shapes.append(poly_sh([(x0 + j * w, y0), (x0 + (j + 1) * w, y0), (x0 + (j + 1) * w, y0 + h), (x0 + j * w, y0 + h)], "lime", fill="lime"))
    shapes += [lab((W / 2, -0.35), "x", "text"), lab((-0.3, h / 2), "y", "text")]
    plot = {"x": [-0.7, fx(W + 0.4)], "y": [-0.7, fx(len(rows) * h + 0.3)], "geo": True, "h": 120, "shapes": shapes}
    desc = "、".join(str(r) for r in rows)
    return item("nb_stairs", "boss", 2, "階梯形的農地", 1.6,
                "%d 塊一樣的長方形農地（寬 x、高 y）排成 %s 塊的階梯（如圖），每塊都圍柵欄（共用的邊只圍一次），總長 %d 公尺。\n(1) 數柵欄　(2) 一塊面積最大多少？　(3) 這時總面積與 x、y" % (N, desc, L),
                [fl("數一數橫的、直的柵欄各有幾段：", "(1)　橫的 [0] 段 x，直的 [1] 段 y", [str(nh), str(nv)],
                    "橫線：每一條水平線的長度看上下兩列比較長的那一列；直線：每一列有「塊數 + 1」條", part="(1)"),
                 fl("用算幾：", "(2)　%d = %dx + %dy ≥ 2√{%dxy}，xy ≤ [0]" % (L, nh, nv, nh * nv), [a(xy)],
                    "%d ≥ 2√{%dxy}，兩邊除以 2 再平方" % (L, nh * nv), part="(2)"),
                 fl("等號成立時 %dx = %dy = %d：" % (nh, nv, L // 2), "(3)　總面積 = [0]，x = [1]，y = [2]", [a(N * xy), a(X), a(Y)],
                    "總面積是 %d 塊" % N, part="(3)")],
                plot=plot)


# ---------- nb_semi：半圓作 √ab 和 ∜ab ----------

def nb_semi(A, B):
    """A、B 是小數字串：∜(ab) > a + b 的反例"""
    a_, b_ = F(A), F(B)
    pr = a_ * b_
    r4 = None
    for d in range(1, 1001):
        for nm in range(1, 1001):
            if F(nm, d) ** 4 == pr:
                r4 = F(nm, d)
                break
        if r4:
            break
    assert r4 and r4 > a_ + b_
    r4s = ("%g" % float(r4))
    ss = ("%g" % float(a_ + b_))
    assert F(r4s) == r4 and F(ss) == a_ + b_
    shapes = [{"k": "arc", "o": [0, 0], "r": 2, "a0": 0, "a1": 180, "c": "cyan"}, seg((-2, 0), (2, 0), "dim"),
              seg((0.6, 0), (0.6, S(4 - 0.36)), "pink"), seg((-2, 0), (0.6, S(4 - 0.36)), "dim", w=1.2), seg((2, 0), (0.6, S(4 - 0.36)), "dim", w=1.2),
              lab((-0.7, -0.4), "a", "text"), lab((1.3, -0.4), "b", "text"), lab((0.85, 1.0), "h", "pink")]
    plot = {"x": [-2.4, 2.4], "y": [-0.8, 2.3], "geo": True, "h": 140, "shapes": shapes}
    return item("nb_semi", "boss", 3, "半圓作 √ab 和 ∜ab", 1.65,
                "a、b 是正數。以 a + b 為直徑畫半圓，直徑上的分點把直徑分成 a、b，從分點作垂線交半圓，垂線長 h。\n(1) h 和 a、b 的關係　(2) 圓內一定有長度 ∜{ab} 的弦嗎？用 a = %s、b = %s 檢驗" % (A, B),
                [ch("連接垂足以外的三點，h 滿足？", ["h^{2} = ab", "h = \\frac{a + b}{2}", "h^{2} = a^{2} + b^{2}", "h = |a − b|"],
                    "半圓上的圓周角是直角，垂線把直角三角形分成兩個相似三角形：\\frac{h}{a} = \\frac{b}{h}", "(1)　兩個小三角形相似：h^{2} = ab，h = √{ab}", part="(1)"),
                 fl("a = %s、b = %s 代入：" % (A, B), "(2)　∜{ab} = [0]，直徑 a + b = [1]", [r4s, ss],
                    "ab = %s，%s 的四次方是 %s" % ("%g" % float(pr), r4s, "%g" % float(pr)), part="(2)"),
                 ch("所以圓內一定有長度 ∜{ab} 的弦嗎？", ["不一定", "一定有", "一定沒有", "a = b 時才有"],
                    "圓內最長的弦是直徑", "　 　%s > %s：弦不可能比直徑長，所以不一定有" % (r4s, ss), part="(2)")],
                plot=plot)


def items():
    return [
        [nb_proof(6, 2), nb_proof(10, 2), nb_proof(6, 3)],
        [nb_counter(2, 2), nb_counter(3, 5), nb_counter(2, 3)],
        [nb_river(1800, 2), nb_river(1200, 3), nb_river(800, 2)],
        [nb_posts(60, 1000), nb_posts(48, 700), nb_posts(40, 450)],
        [nb_stairs([1, 3, 5], "center", 168), nb_stairs([1, 2, 3], "left", 108), nb_stairs([2, 3, 4], "left", 312)],
        [nb_semi("0.16", "0.01"), nb_semi("0.08", "0.02"), nb_semi("0.18", "0.045")],
    ]
