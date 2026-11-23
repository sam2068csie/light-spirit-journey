# 試煉大題（二）：題組、整數解、巢狀絕對值、立方根
from nlib import *

S = math.sqrt


def _abs_t(d):
    """|x − d| 的寫法"""
    return "|x − %s|" % t(d) if d > 0 else ("|x + %s|" % t(-d) if d < 0 else "|x|")


# ---------- nb_group_abs：四個數都滿足 ----------

def nb_group_abs(nums, test, tv):
    lo, hi = min(nums), max(nums)
    assert lo <= tv <= hi
    w = hi - lo
    bmin = F(w, 2)
    good = lo - 1
    bad = [lo + 1, lo + 3, hi]
    for v in bad:
        assert v > lo
    return item("nb_group_abs", "boss", 3, "四個數都滿足", 1.65,
                "%s 都滿足 |x − a| ≤ b。\n(1) %s 也一定滿足嗎？　(2) 求 b 的最小值　(3) a − b 可能是多少？" % ("、".join(t(v) for v in nums), test),
                [ch("|x − a| ≤ b 的解是 a − b ≤ x ≤ a + b。%s ≈ %.2f 一定滿足嗎？" % (test, tv), ["一定滿足", "一定不滿足", "不一定", "要看 a 的值"],
                    "解是一整段區間；包含 %s 和 %s，就包含它們中間所有的數" % (t(lo), t(hi)), "(1)　%s 在 %s 和 %s 之間，一定滿足" % (test, t(lo), t(hi)), part="(1)"),
                 fl("區間要蓋住最小的 %s 和最大的 %s：" % (t(lo), t(hi)), "(2)　a − b ≤ [0]，a + b ≥ [1]", [a(lo), a(hi)], "左端點不能比 %s 大，右端點不能比 %s 小" % (t(lo), t(hi)), part="(2)"),
                 fl("兩式相減：", "　 　(a + b) − (a − b) = 2b ≥ [0]，b 的最小值 [1]", [a(w), a(bmin)], "%s − (%s) = %s" % (t(hi), t(lo), t(w)), part="(2)"),
                 ch("a − b 可能是下列哪一個？", [t(good)] + [t(v) for v in bad], "a − b ≤ %s" % t(lo), "(3)　a − b ≤ %s，只有 %s 可以" % (t(lo), t(good)), part="(3)")])


# ---------- nb_group_amgm：等號不能同時成立 ----------

def nb_group_amgm(p, q, c, r):
    """(1) px + qy = c（x、y > 0）求 xy 的最大值；(2) a^2 + b^2 = r^2 的審判"""
    mx = F(c * c, 4 * p * q)
    X, Y = F(c, 2 * p), F(c, 2 * q)
    assert X * Y == mx
    ths = [i * math.pi / 3600 for i in range(7201)]
    pts = [(r * math.cos(th), r * math.sin(th)) for th in ths]
    r2 = r * r
    half = F(r2, 2)
    bound = Q(half, half, 2)               # r²/2 + r²√2/2
    m_ab_rb = max(a_ * b_ + r * b_ for a_, b_ in pts)
    rs = "" if r == 1 else str(r)
    cards = [
        cardc("ab ≤ %s" % tf(half), True, "a^{2} + b^{2} ≥ 2ab", max(a_ * b_ for a_, b_ in pts) <= float(half) + 1e-9),
        cardc("a + b ≤ %s√{2}" % rs, True, "(a + b)^{2} = %d + 2ab ≤ %d" % (r2, 2 * r2), max(a_ + b_ for a_, b_ in pts) <= r * S(2) + 1e-9),
        cardc("ab + %sb ≤ %s" % (rs, qf(bound)), False,
              "右邊是 a = b = %s 代進去的值，但那時 ab + %sb 不是最大。例如 a = %s、b = %s：ab + %sb ≈ %.2f > %.2f" %
              (qf(Q(0, F(r, 2), 2)), rs, tf(F(r, 2)), qf(Q(0, F(r, 2), 3)), rs, 3 * S(3) * r2 / 4, float(bound)),
              m_ab_rb <= float(bound) + 1e-9),
        cardc("ab ≥ −%s" % tf(half), True, "a^{2} + b^{2} ≥ −2ab", min(a_ * b_ for a_, b_ in pts) >= -float(half) - 1e-9),
        cardc("a = b 時，ab 取到最大值", True, "算幾的等號在 a^{2} = b^{2}、ab > 0 時成立", True)]
    assert near(m_ab_rb, 3 * S(3) * r2 / 4, 1e-3)
    lhs = poly([(p, "x"), (q, "y")])
    return item("nb_group_amgm", "boss", 3, "等號不能同時成立", 1.65,
                "(1) x、y > 0，%s = %d，求 xy 的最大值和這時的 x、y。\n(2) a、b 是實數，a^{2} + b^{2} = %d，判斷下列敘述。" % (lhs, c, r2),
                [fl("用算幾：%d = %s ≥ 2√{%dxy}" % (c, lhs, p * q), "(1)　xy ≤ [0]，等號在 %s = %s 時：x = [1]，y = [2]" % (cof(p, "x", True), cof(q, "y", True)), [a(mx), a(X), a(Y)],
                    "兩邊除以 2 再平方：%s ≥ %dxy；等號成立時兩項都是 %s" % (t(F(c * c, 4)), p * q, t(F(c, 2))), part="(1)"),
                 jd("(2) 每一個「≤」都要檢查等號取不取得到。", cards)])


# ---------- nb_int：整數解剛好 N 個 ----------

def nb_int(c, d, r, N):
    L, R = d - r, d + r

    def cnt(a_):
        return sum(1 for x in range(-500, 501) if abs(x - c) <= a_ and abs(x - d) > r)
    sols = [a_ for a_ in range(0, 200) if cnt(a_) == N]
    assert len(sols) == 1
    ans = sols[0]
    k1 = c - R                          # 不跨過：a + (c − R)
    k2 = L - R                          # 跨過：2a + (L − R)
    v1 = F(N - k1)
    v2 = F(N - k2, 2)
    ok1 = isint(v1) and c - v1 >= L and c - v1 <= R + 1
    ok2 = isint(v2) and c - v2 < L
    assert ok1 != ok2 and (v1 if ok1 else v2) == ans
    # 公式驗算
    for a_ in range(max(R + 1 - c, c - R - 1, 0), c - L + 1):
        assert cnt(a_) == a_ + k1
    for a_ in range(c - L + 1, c - L + 20):
        assert cnt(a_) == 2 * a_ + k2
    f1 = poly([(1, "a"), (k1, "")])
    f2 = poly([(2, "a"), (k2, "")])
    def verdict(v, ok, cond):
        if not isint(v):
            return "a = %s 不是整數，不合" % t(v)
        return "a = %s，%s，%s" % (t(v), cond(v), "合" if ok else "不合")
    t1 = verdict(v1, ok1, lambda v: "%d − %s = %s %s %s" % (c, t(v), t(c - v), "≥" if c - v >= L else "<", t(L)))
    t2 = verdict(v2, ok2, lambda v: "%d − %s = %s %s %s" % (c, t(v), t(c - v), "<" if c - v < L else "≥", t(L)))
    return item("nb_int", "boss", 3, "整數解的個數", 1.7,
                "a 是正整數，聯立不等式 {|x − %s| ≤ a、%s > %d} 的整數解剛好有 %d 個，求 a。" % (t(c), _abs_t(d), r, N),
                [fl("先解第二式：", "(1)　x < [0] 或 x > [1]", [a(L), a(R)], "%s > %d：%s > %d 或 %s < −%d" % (_abs_t(d), r, poly([(1, "x"), (-d, "")]), r, poly([(1, "x"), (-d, "")]), r), part="(1)"),
                 ch("第一式是 %s − a ≤ x ≤ %s + a。若左端 %s − a ≥ %s（沒有跨過 %s），整數解的個數是？" % (t(c), t(c), t(c), t(L), t(L)),
                    uniq([f1], [poly([(2, "a"), (1, "")]), poly([(1, "a"), (k1 + 1, "")]), poly([(1, "a"), (k1 - 1, "")])], 4),
                    "只剩右邊：%s、%s、…、%s + a" % (t(R + 1), t(R + 2), t(c)), "(2)　沒跨過：整數解 %s、…、%s + a，共 %s 個" % (t(R + 1), t(c), f1), part="(2)"),
                 ch("%s = %d，解出的 a 合不合？" % (f1, N), ["合" if ok1 else "不合", "不合" if ok1 else "合", "要再看 x 的值"],
                    "解出 a，再檢查 a 是正整數、而且 %s − a ≥ %s" % (t(c), t(L)), "　 　" + t1, part="(2)"),
                 ch("若左端跨過 %s（%s − a < %s），整數解的個數是？" % (t(L), t(c), t(L)),
                    uniq([f2], [poly([(2, "a"), (1, "")]), poly([(2, "a"), (k2 + 1, "")]), f1], 4),
                    "左邊再多 %s − a、…、%s，共 a %s 個" % (t(c), t(L - 1), ("+ %d" % (L - c) if L - c > 0 else "− %d" % (c - L))),
                    "(3)　跨過：右邊 %s 個，左邊 %s 個，共 %s 個" % (f1, poly([(1, "a"), (L - c, "")]), f2), part="(3)"),
                 fl("%s = %d：%s。所以：" % (f2, N, t2), "　 　a = [0]", [str(ans)], "只有合的那一種情況", part="(3)")])


# ---------- nb_nested：絕對值裡的絕對值 ----------

def nb_nested(p, q, op):
    """||x − p| − |x + q|| op x"""
    f = lambda x: abs(abs(x - p) - abs(x + q)) - x
    stem = "||x − %d| − |x + %d|| %s x" % (p, q, op)
    first = ch("左邊 ≥ 0，所以 x 要滿足？", ["x ≥ 0", "x > %d" % p, "x ≤ −%d" % q, "x 可以是任意實數"],
               "絕對值一定 ≥ 0，右邊的 x 至少要 ≥ 0", "(1)　左邊 ≥ 0　⇒　x ≥ 0，這時 |x + %d| = x + %d" % (q, q), part="(1)")
    if op == "=":
        s1, s2 = F(p - q, 3), F(p - q)
        s3 = F(p + q)
        assert 0 <= s1 < p and 0 <= s2 < p and s3 >= p
        sols = [F(i, 3) for i in range(-60, 61) if f(F(i, 3)) == 0]
        assert sols == [s1, s2, s3]
        return item("nb_nested", "boss", 3, "絕對值裡的絕對值", 1.7,
                    "解方程式 %s，並求所有解的和。" % stem,
                    [first,
                     fl("0 ≤ x < %d：|x − %d| = %d − x" % (p, p, p), "(2)　|%d − 2x| = x　→　較小的 x = [0]，較大的 x = [1]" % (p - q), [a(s1), a(s2)],
                        "%d − 2x = x 或 %d − 2x = −x，兩個都在 0 ≤ x < %d 裡" % (p - q, p - q, p), part="(2)"),
                     fl("x ≥ %d：|x − %d| = x − %d" % (p, p, p), "(3)　|(x − %d) − (x + %d)| = %d = x　→　x = [0]" % (p, q, p + q), [a(s3)],
                        "裡面變成常數 −%d" % (p + q), part="(3)"),
                     fl("所有解的和：", "　 　所有解的和 = [0]", [a(s1 + s2 + s3)], "%s + %s + %s" % (t(s1), t(s2), t(s3)), part="(3)")])
    # 不等式 ≤
    lo, hi = F(p - q, 3), F(p - q)
    big = F(p + q)
    assert 0 <= lo < hi < p <= big
    xs = [F(i, 6) for i in range(-60, 121)]
    for x in xs:
        want = (lo <= x <= hi) or x >= big
        assert (f(x) <= 0) == want
    marks = [lo, hi, big]
    return item("nb_nested", "boss", 3, "絕對值裡的絕對值", 1.7,
                "解不等式 %s。" % stem,
                [first,
                 fl("0 ≤ x < %d：|x − %d| = %d − x" % (p, p, p), "(2)　|%d − 2x| ≤ x　→　[0] ≤ x ≤ [1]" % (p - q), [a(lo), a(hi)],
                    "−x ≤ %d − 2x ≤ x" % (p - q), part="(2)"),
                 fl("x ≥ %d：" % p, "(3)　|(x − %d) − (x + %d)| = %d ≤ x　→　x ≥ [0]" % (p, q, p + q), [a(big)], "裡面變成常數 −%d" % (p + q), part="(3)"),
                 step("line", q="把兩段的解合起來，封印在數線上。", row="解", marks=[t(m) for m in marks], seg=[0, 1, 0, 1], pt=[1, 1, 1],
                      write="答：%s ≤ x ≤ %s 或 x ≥ %s" % (t(lo), t(hi), t(big)), part="(3)")])


# ---------- nb_cuberoot：立方根的雙重根號 ----------

def nb_cuberoot(a_, b_):
    assert a_ < b_
    s = a_ + b_
    u, v = a_ * a_ * b_, a_ * b_ * b_
    lhs = (s + 3 * u ** (1 / 3) + 3 * v ** (1 / 3)) ** (1 / 3)
    assert near(lhs, a_ ** (1 / 3) + b_ ** (1 / 3))
    stem = "∛{%d + 3∛{%d} + 3∛{%d}}" % (s, u, v)
    return item("nb_cuberoot", "boss", 3, "立方根的雙重根號", 1.7,
                "%s = ∛{a} + ∛{b}，a、b 是正整數，a < b。\n(1) 兩邊立方，比較有理部分　(2) 求 ab　(3) 求 (a, b)" % stem,
                [fl("(∛{a} + ∛{b})^{3} = a + b + 3∛{a^{2}b} + 3∛{ab^{2}}：", "(1)　a + b = [0]", [str(s)], "沒有根號的部分對應", part="(1)"),
                 fl("根號部分：a^{2}b = %d、ab^{2} = %d" % (u, v), "(2)　兩式相乘 (ab)^{3} = [0]，ab = [1]", [str(u * v), str(a_ * b_)],
                    "%d × %d = %d，開立方" % (u, v, u * v), part="(2)"),
                 fl("a + b = %d、ab = %d：" % (s, a_ * b_), "(3)　(a, b) = ([0], [1])", [str(a_), str(b_)], "兩數和 %d、積 %d，a < b" % (s, a_ * b_), part="(3)")])


# ---------- nb_proof_cube：反證法進階 ----------

def nb_proof_cube(m, n):
    P = 1.37
    assert near((P - S(n)) ** 3, (P ** 3 + 3 * n * P) - (3 * P * P + n) * S(n))
    x = "∛{%d} + √{%d}" % (m, n)
    return item("nb_proof_cube", "boss", 3, "反證法進階", 1.7,
                "證明 %s 是無理數。\n(1) 假設 %s = P 是有理數，先移項　(2) 兩邊立方　(3) 指出矛盾" % (x, x),
                [ch("怎麼移項，立方後比較好算？", ["∛{%d} = P − √{%d}" % (m, n), "√{%d} = P − ∛{%d}" % (n, m), "P^{3} = %d + %d√{%d}" % (m, n, n), "P^{2} = ∛{%d} + %d" % (m * m, n)],
                    "把 ∛{%d} 單獨留下，立方之後它就變成 %d" % (m, m), "(1)　∛{%d} = P − √{%d}" % (m, n), part="(1)"),
                 fl("兩邊立方，把有 √{%d} 的項放一起：" % n, "(2)　%d = P^{3} + [0]P − ([1]P^{2} + [2])√{%d}" % (m, n), [str(3 * n), "3", str(n)],
                    "(P − √{%d})^{3} = P^{3} − 3P^{2}√{%d} + %dP − %d√{%d}" % (n, n, 3 * n, n, n), part="(2)"),
                 ch("整理得 √{%d} = \\frac{P^{3} + %dP − %d}{3P^{2} + %d}，矛盾在哪裡？" % (n, 3 * n, m, n),
                    ["左邊無理、右邊有理", "分母可能是 0", "P 一定是整數", "∛{%d} 是有理數" % m],
                    "P 有理，分母 3P^{2} + %d > 0，右邊是有理數" % n, "(3)　右邊有理、√{%d} 無理，矛盾，所以 %s 是無理數" % (n, x), part="(3)")])


def items():
    return [
        [nb_group_abs([-6, -1, 0, 4], "√{15}", S(15)), nb_group_abs([-3, 1, 2, 7], "√{30}", S(30)), nb_group_abs([-8, -2, 3, 6], "−√{50}", -S(50))],
        [nb_group_amgm(2, 1, 6, 1), nb_group_amgm(1, 3, 12, 2), nb_group_amgm(3, 2, 12, 3)],
        [nb_int(6, -2, 3, 16), nb_int(3, 1, 4, 10), nb_int(4, -1, 2, 9)],
        [nb_nested(2, 1, "="), nb_nested(3, 1, "≤"), nb_nested(4, 2, "=")],
        [nb_cuberoot(2, 3), nb_cuberoot(3, 4), nb_cuberoot(2, 5)],
        [nb_proof_cube(2, 5), nb_proof_cube(3, 2), nb_proof_cube(5, 3)],
    ]
