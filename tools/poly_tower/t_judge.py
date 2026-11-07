# 真假審判
from plib import *


def _ok(cards):
    n = sum(1 for c in cards if c["ok"])
    assert 2 <= n <= len(cards) - 1, [c["s"] for c in cards]
    return cards


# ---------- pj_coef：乘積的係數 ----------

def pj_coef(A, B, flags):
    """A 三次、B 二次（係數由高到低）"""
    pa, pb = Poly(list(reversed(A))), Poly(list(reversed(B)))
    f = pa * pb
    a3, a2, a1, a0 = A
    b2, b1, b0 = B
    lead = a3 * b2
    c4 = f.c[4]
    c3 = f.c[3]
    f1, fm1 = f(1), f(-1)
    even = (f1 + fm1) / 2
    odd = (f1 - fm1) / 2
    cards = []
    # 1 領導係數
    w = a3 + b2
    assert w != lead
    cards.append(card("f(x) 的領導係數是 %s" % t(lead if flags[0] else w), bool(flags[0]),
                      "最高次項 %s · %s = %s" % (cx(a3, "x^{3}"), cx(b2, "x^{2}"), cx(lead, "x^{5}"))))
    # 2 x^4
    w4 = a3 * b1
    assert w4 != c4
    cards.append(card("x^{4} 項的係數是 %s" % t(c4 if flags[1] else w4), bool(flags[1]),
                      "%s · %s + %s · %s = %s" % (cx(a3, "x^{3}"), cx(b1, "x"), tp_t(cx(a2, "x^{2}")), cx(b2, "x^{2}"), cx(c4, "x^{4}"))))
    # 3 x^3（錯的：漏掉 a1·b2）
    w3 = c3 - a1 * b2
    assert w3 != c3 and a1 * b2 != 0
    cards.append(card("x^{3} 項的係數是 %s" % t(c3 if flags[2] else w3), bool(flags[2]),
                      "%s · %s + %s · %s + %s · %s = %s" % (t(a3), tp(b0), tp(a2), tp(b1), tp(a1), tp(b2), t(c3))))
    # 4 係數和
    ws = pa(1) + pb(1)
    assert ws != f1
    cards.append(card("各項係數的總和是 %s" % t(f1 if flags[3] else ws), bool(flags[3]),
                      "係數和 = f(1) = %s × %s = %s" % (tp(pa(1)), tp(pb(1)), t(f1))))
    # 5 偶次項係數和
    assert odd != even
    cards.append(card("偶次項係數的和是 %s" % t(even if flags[4] else odd), bool(flags[4]),
                      "f(−1) = %s × %s = %s，偶次項和 = \\frac{f(1) + f(−1)}{2} = %s" % (tp(pa(-1)), tp(pb(-1)), t(fm1), t(even))))
    return item("pj_coef", "judge", 1, "乘積的係數", 1.1,
                "設 f(x) = (%s)(%s)。下列敘述哪些正確？" % (pa.text(), pb.text()),
                [judge("不用全部展開：只挑會乘出那一項的組合。", _ok(cards))])


def tp_t(s):
    return "(" + s + ")" if s.startswith(M) else s


# ---------- pj_divrule：除法原理 ----------

def pj_divrule(c, q, R):
    D = Poly([-c ** 3, 0, 0, 1])
    Q = Poly([q, 1])
    Rp = Poly(list(reversed(R)))
    f = D * Q + Rp
    D2 = Poly([c * c, c, 1])
    r2 = Rp % D2
    r3 = f % Poly.roots([c, c])
    assert not (r3 == Rp)
    dt = "x^{3} %s %d" % (M, c ** 3)
    cards = [
        card("f(%d) = %s" % (c, t(f(c))), True, "x = %d 時 %s = 0，f(%d) = %s" % (c, dt, c, t(Rp(c)))),
        card("f(x) 除以 2x − %d 的餘式為 %s" % (2 * c, t(2 * f(c))), False, "除以 2x − %d 的餘式還是 f(%d) = %s，不會乘 2" % (2 * c, c, t(f(c)))),
        card("f(x) 除以 %s 的餘式為 %s" % (D2.text(), r2.text()), True,
             "%s = %s(%s) + (%s)" % (Rp.text(), "" if Rp.lead() == 1 else t(Rp.lead()), D2.text(), r2.text())),
        card("f(x) 除以 (x − %d)^{2} 的餘式為 %s" % (c, Rp.text()), False,
             "餘式要比 (x − %d)^{2} 低次，%s 還要再除一次（真正的餘式是 %s）" % (c, Rp.text(), r3.text())),
        card("f(x) 的常數項是 %s" % t(f(0)), True, "f(0) = (%s)(%s) + (%s) = %s" % (t(-c ** 3), t(q), t(Rp(0)), t(f(0))))]
    return item("pj_divrule", "judge", 2, "除法原理", 1.2,
                "多項式 f(x) 除以 %s 的商式為 %s，餘式為 %s。下列敘述哪些正確？" % (dt, Q.text(), Rp.text()),
                [judge("先寫出 f(x) = (%s)(%s) + %s，再拆除式 %s = (x − %d)(%s)。" % (dt, Q.text(), Rp.text(), dt, c, D2.text()), _ok(cards))])


# ---------- pj_tworem：能決定的值 ----------

def pj_tworem(p, q, r1, r2, s, u):
    d = Poly.roots([p, q])
    R1, R2 = Poly(list(reversed(r1))), Poly(list(reversed(r2)))
    assert s not in (p, q) and u not in (p, q)
    comb = 3 * R1 - 2 * R2
    cards = [
        card("f(%d) = %s" % (p, t(R1(p))), True, "x = %d 是除式的根，f(%d) = %s" % (p, p, t(R1(p)))),
        card("f(%d) = %s" % (s, t(R1(s))), False, "x = %d 不是除式的根，f(%d) 由題目決定不了" % (s, s)),
        card("f(x) + x g(x) 除以 %s 的餘式為 %s" % (fac(p).strip("()"), t(R1(p) + p * R2(p))), True,
             "f(%d) + %s · g(%d) = %s + %s · %s = %s" % (p, tp(p), p, t(R1(p)), tp(p), tp(R2(p)), t(R1(p) + p * R2(p)))),
        card("3f(x) − 2g(x) 除以 %s 的餘式為 %s" % (d.text(), comb.text()), True, "3(%s) − 2(%s) = %s" % (R1.text(), R2.text(), comb.text())),
        card("f(x) g(x) 除以 %s 的餘式為 0" % fac(u).strip("()"), False, "x = %d 不是除式的根，f(%d)、g(%d) 都不確定" % (u, u, u))]
    return item("pj_tworem", "judge", 2, "能決定的值", 1.2,
                "以 %s 分別除多項式 f(x)、g(x)，餘式依序是 %s、%s。下列敘述哪些正確？" % (d.text(), R1.text(), R2.text()),
                [judge("除式 %s = %s%s：只有 x = %d、x = %d 的值能確定。" % (d.text(), fac(p), fac(q), p, q), _ok(cards))])


# ---------- pj_axis：對稱軸的範圍 ----------

def pj_axis(n):
    assert n % 2 == 1
    k = (n - 1) // 2
    cards = [
        card("b < 0", True, "f(%d) = %da(%d − r) < 0 ⇒ r > %d，f(%d) > 0 ⇒ r < %d。b = −ar < 0" % (n, n, n, n, n + 1, n + 1)),
        card("a + b > 0", False, "a + b = a(1 − r)，r > %d 所以是負的" % n),
        card("f(%d) > f(%d)" % (k, k + 1), True, "對稱軸 x = r/2 在 %s 和 %d 之間，%d 離對稱軸比 %d 遠，開口向上所以 f(%d) 比較大" % (dec(F(n, 2), 1), k + 1, k, k + 1, k)),
        card("f(%d) < f(%d)" % (k - 1, k + 2), False, "%d 到對稱軸的距離在 %s～%s 之間，%d 只有 %s～%s，所以 f(%d) > f(%d)" % (
            k - 1, dec(F(3, 2), 1), "2", k + 2, "1", dec(F(3, 2), 1), k - 1, k + 2)),
        card("%da + b > 0" % (n + 1), True, "%da + b = a(%d − r) = f(%d)/%d > 0" % (n + 1, n + 1, n + 1, n + 1))]
    return item("pj_axis", "judge", 2, "對稱軸的範圍", 1.25,
                "二次函數 f(x) = ax^{2} + bx，其中 a > 0，且 f(%d) < 0、f(%d) > 0。下列敘述哪些正確？" % (n, n + 1),
                [judge("f(x) = ax(x − r)，r = −b/a 是另一個根。先找出 r、對稱軸的範圍。", _ok(cards))])


# ---------- pj_cubrange：先求範圍再判斷 ----------

def pj_cubrange(h, m):
    lo, hi = F(-m), F(-m, 4)
    xs = fac(h)
    f = lambda a_, x: a_ * (x - h) ** 3 + m * (x - h)
    # 檢查：範圍內每個 a 都對
    for a_ in [lo + (hi - lo) * F(i, 10) for i in range(1, 10)]:
        assert f(a_, h + 1) > 0 and f(a_, h + 2) < 0 and f(a_, h - 2) > 0
        r = h - math.sqrt(float(-m / a_))
        assert h - 2 < r < h - 1
    cards = [
        card("a < 0", True, "f(%d) = a + %d > 0、f(%d) = 8a + %d < 0 ⇒ %s < a < %s" % (h + 1, m, h + 2, 2 * m, t(lo), t(hi))),
        card("y = f(x) 的圖形與 x 軸恰有一個交點", False,
             "f(x) = %s[a%s^{2} + %d]，a < 0 時 %s^{2} = −%d/a 有兩根，共三個交點" % (xs, xs, m, xs, m)),
        card("f(%d) > 0" % (h - 2), True, "f(%d) = −8a − %d，a < %s ⇒ −8a > %d" % (h - 2, 2 * m, t(hi), 2 * m)),
        card("f(x) = 0 在 %d 和 %d 之間恰有一個實根" % (h - 2, h - 1), True,
             "根 x = %s − √{−%d/a}，而 1 < −%d/a < 4，所以 √{−%d/a} 在 1 和 2 之間" % (t(h), m, m, m)),
        card("y = f(x) 圖形的對稱中心是 (%d, 0)" % (-h), False, "f(x) = a%s^{3} + %d%s，對稱中心是 (%d, 0)" % (xs, m, xs, h))]
    return item("pj_cubrange", "judge", 3, "先求範圍再判斷", 1.3,
                "三次函數 f(x) = a%s^{3} + %d%s，滿足 f(%d) > 0、f(%d) < 0。下列敘述哪些正確？" % (xs, m, xs, h + 1, h + 2),
                [fl("先由 f(%d) = a + %d > 0、f(%d) = 8a + %d < 0 求出 a 的範圍：" % (h + 1, m, h + 2, 2 * m), "[0] < a < [1]", [a(lo), a(hi)],
                    "a > %s，而且 8a < %s" % (t(lo), t(-2 * m))),
                 judge("用 %s < a < %s 判斷每一張。" % (t(lo), t(hi)), _ok(cards))])


# ---------- pj_center：三次函數的特徵 ----------

def pj_center(A, h, p, k, d):
    f = A * Poly([-h, 1]) ** 3 + p * Poly([-h, 1]) + k
    assert p * A < 0
    r = rt(F(-p, A))
    xs = fac(h)
    lin_m, lin_c = p, k - p * h
    cards = [
        card("y = f(x) 圖形的對稱中心是 (%d, %d)" % (h, k), True, "f(x) = %d%s^{3} %s %d%s + %d" % (A, xs, "+" if p > 0 else M, abs(p), xs, k)),
        card("y = f(x) 與直線 y = %d 有三個交點" % k, True, "%dt^{3} %s %dt = 0 ⇒ t = 0、±%s，三個交點" % (A, "+" if p > 0 else M, abs(p), r.text())),
        card("在對稱中心附近，圖形近似於直線 y = %s" % poly([(lin_m, "x"), (lin_c, "")]), True,
             "對稱中心附近 f(x) ≈ %d%s + %d" % (p, xs, k)),
        card("f(%d) + f(%d) = %d" % (h - d, h + d, k), False, "%d、%d 對稱於 x = %d，f(%d) + f(%d) = 2 × %d = %d" % (h - d, h + d, h, h - d, h + d, k, 2 * k)),
        card("若三次函數 g(x) 的首項係數也是 %d、對稱中心也是 (%d, %d)，則 g(x) = f(x)" % (A, h, k), False,
             "g(x) = %d%s^{3} + p%s + %d，p 不一定是 %d" % (A, xs, xs, k, p))]
    return item("pj_center", "judge", 2, "三次函數的特徵", 1.25,
                "f(x) = %s。下列敘述哪些正確？" % f.text(),
                [fl("連續用 %s 做綜合除法，寫成 %d%s^{3} + p%s^{2} + q%s + k：" % (fac(h).strip("()"), A, xs, xs, xs),
                    "f(x) = %d%s^{3} + [0]%s^{2} + [1]%s + [2]" % (A, xs, xs, xs), ["0", a(p), a(k)],
                    "k = f(%d) = %d，二次項係數是 0，因為對稱中心的 x 坐標 %s = %d" % (h, k, "\\frac{%s}{%s}" % (t(-f.c[2]), t(3 * A)), h)),
                 judge("用 f(x) = %d%s^{3} %s %d%s + %d 判斷每一張。" % (A, xs, "+" if p > 0 else M, abs(p), xs, k), _ok(cards))])


# ---------- pj_ineq：不等式的解 ----------

def pj_ineq(cards):
    return item("pj_ineq", "judge", 1, "不等式的解", 1.0, "下列各不等式的解，哪些正確？",
                [judge("注意平方因式和恆正的因式。", _ok(cards))])


def ineq_sets():
    return [
        [card("(x − 1)^{2}(x + 2) > 0 的解為 x > −2", False, "x = 1 時左邊是 0，不合，解為 x > −2 且 x ≠ 1"),
         card("(x − 3)^{2} ≤ 0 的解為 x = 3", True, "平方不會小於 0，只剩等於 0"),
         card("x^{2} + x + 1 > 0 對所有實數 x 都成立", True, "首項係數 > 0，判別式 1 − 4 < 0"),
         card("(x + 1)(x − 2)^{3} < 0 的解為 −1 < x < 2", True, "(x − 2)^{3} 和 x − 2 同號"),
         card("x^{2} > 4 的解為 x > 2", False, "x < −2 也成立")],
        [card("(x + 2)^{2}(x − 3) ≥ 0 的解為 x ≥ 3", False, "x = −2 時左邊是 0，也成立：解為 x ≥ 3 或 x = −2"),
         card("(x − 1)^{2} > 0 的解為 x ≠ 1", True, "平方只有在 x = 1 時是 0"),
         card("x^{2} − 2x + 3 < 0 無解", True, "首項係數 > 0，判別式 4 − 12 < 0，恆正"),
         card("(x − 4)^{3}(x + 1) > 0 的解為 −1 < x < 4", False, "(x − 4)^{3} 和 x − 4 同號：解為 x < −1 或 x > 4"),
         card("x^{2} ≤ 9 的解為 −3 ≤ x ≤ 3", True, "(x − 3)(x + 3) ≤ 0")],
        [card("(x − 2)^{2}(x + 1) < 0 的解為 x < −1", True, "(x − 2)^{2} ≥ 0，x = 2 時是 0 不合，所以只看 x + 1 < 0"),
         card("(x + 5)^{2} ≥ 0 的解為 x = −5", False, "平方一定 ≥ 0，所有實數都是解"),
         card("−x^{2} + 4x − 5 < 0 對所有實數 x 都成立", True, "x^{2} − 4x + 5 > 0：首項係數 > 0，判別式 16 − 20 < 0"),
         card("x(x − 3)^{4} ≤ 0 的解為 x ≤ 0", False, "x = 3 時左邊是 0，也成立：解為 x ≤ 0 或 x = 3"),
         card("x^{3} > x 的解為 −1 < x < 0 或 x > 1", True, "x(x − 1)(x + 1) > 0，穿根")],
    ]


# ---------- pj_quadrant：象限的邏輯 ----------

def pj_quadrant(cards):
    return item("pj_quadrant", "judge", 3, "象限的邏輯", 1.3,
                "a、b、c 是實數，a ≠ 0，Γ 是 y = ax^{2} + bx + c 的圖形。下列敘述哪些正確？",
                [judge("「一定」的敘述，找得到一個反例就是假的。", _ok(cards))])


def quadrant_sets():
    return [
        [card("若 a < 0，Γ 一定通過第三象限", True, "開口向下，x 很負時 y 也很負，落在第三象限"),
         card("若 b^{2} − 4ac < 0，Γ 一定通過第二象限", False, "反例 y = −x^{2} − 1：整個圖形都在 x 軸下方"),
         card("若 c < 0，Γ 一定通過第四象限", True, "(0, c) 在 y 軸負半邊，x 取很小的正數時 y 還是負的"),
         card("若 Γ 只通過第一、二象限，則 b^{2} − 4ac < 0", False, "反例 y = (x − 1)^{2}：碰到 x 軸的點不屬於任何象限，判別式是 0"),
         card("若 a > 0、b > 0、c > 0，則 Γ 不通過第四象限", True, "x > 0 時三項都是正的，y > 0")],
        [card("若 a > 0，Γ 一定通過第一象限", True, "開口向上，x 很大時 y 也很大，落在第一象限"),
         card("若 a < 0，Γ 一定通過第一象限", False, "反例 y = −x^{2} − 1：整個圖形都在 x 軸下方"),
         card("若 Γ 和 x 軸有兩個交點，則 Γ 一定通過第一象限", False, "反例 y = −(x + 1)(x + 2)：x > 0 時 y < 0"),
         card("若 a < 0、c > 0，則 Γ 通過四個象限", True, "兩根之積 c/a < 0：一正一負。x 很大、很負時 y < 0，靠近 y 軸時 y 接近 c > 0"),
         card("若 b = 0，Γ 對稱於 y 軸", True, "y = ax^{2} + c，x 換成 −x 不變")],
        [card("若 a > 0、b < 0、c > 0，Γ 一定通過第四象限", False, "反例 y = x^{2} − x + 1：判別式 < 0，整個圖形在 x 軸上方"),
         card("若 a > 0、c < 0，Γ 一定通過第二象限", True, "開口向上，x 很負時 y 很大，落在第二象限"),
         card("若 Γ 不通過第三、四象限，則 a > 0", True, "a < 0 時 x 很大或很負，y 都是負的，一定經過第三、四象限"),
         card("若 c > 0，Γ 一定通過第二象限", True, "(0, c) 在 y 軸正半邊，x 取很小的負數時 y 還是正的"),
         card("若 a > 0，Γ 的頂點一定在 x 軸下方", False, "反例 y = x^{2} + 1：頂點 (0, 1)")],
    ]


# ---------- pj_meetline：和 y = x 的交點 ----------

def pj_meetline(specs):
    """specs：(式子文字, Poly, why)。和 y = x 恰有兩個交點才是對的"""
    cards = []
    for s, p, why in specs:
        n = len((p - X).real_roots())
        cards.append(card("y = " + s, n == 2, why))
    return item("pj_meetline", "judge", 2, "和 y = x 的交點", 1.2, "下列哪些函數的圖形與直線 y = x 恰有兩個交點？",
                [judge("聯立 f(x) = x，數實根的個數。", _ok(cards))])


def meet_sets():
    return [
        [("(x − 1)^{2} + 1", Poly.roots([1, 1]) + 1, "x^{2} − 3x + 2 = 0，x = 1、2"),
         ("(x + 2)^{2}", Poly.roots([-2, -2]), "x^{2} + 3x + 4 = 0，判別式 9 − 16 < 0，沒有交點"),
         ("x^{3}", X ** 3, "x^{3} = x，x = 0、±1，三個交點"),
         ("(x − 3)^{4}", Poly.roots([3, 3, 3, 3]), "g(x) = (x − 3)^{4} − x：g(1) > 0、g(2) < 0、g(4) < 0、g(5) > 0，凹口向上的曲線和直線最多交兩點"),
         ("−x^{2} + 3x", Poly([0, 3, -1]), "x^{2} − 2x = 0，x = 0、2")],
        [("x^{2} − 3x + 4", Poly([4, -3, 1]), "x^{2} − 4x + 4 = 0，x = 2 是重根，只有一個交點"),
         ("(x − 1)^{2}", Poly.roots([1, 1]), "x^{2} − 3x + 1 = 0，判別式 9 − 4 > 0，兩個交點"),
         ("x^{3} − 3x", X ** 3 - 3 * X, "x^{3} − 4x = 0，x = 0、±2，三個交點"),
         ("−x^{2} + 4", Poly([4, 0, -1]), "x^{2} + x − 4 = 0，判別式 1 + 16 > 0，兩個交點"),
         ("x^{2} + 1", Poly([1, 0, 1]), "x^{2} − x + 1 = 0，判別式 1 − 4 < 0，沒有交點")],
        [("x^{2} + 2x", Poly([0, 2, 1]), "x^{2} + x = 0，x = 0、−1"),
         ("x^{3} + x", X ** 3 + X, "x^{3} = 0，只有 x = 0 一個交點"),
         ("x^{2} − x + 1", Poly([1, -1, 1]), "x^{2} − 2x + 1 = 0，x = 1 是重根，只有一個交點"),
         ("−(x − 2)^{2} + 3", -Poly.roots([2, 2]) + 3, "x^{2} − 3x + 1 = 0，判別式 9 − 4 > 0，兩個交點"),
         ("(x − 1)^{4}", Poly.roots([1, 1, 1, 1]), "g(x) = (x − 1)^{4} − x：g(0) > 0、g(1) < 0、g(2) < 0、g(3) > 0，凹口向上的曲線和直線最多交兩點")],
    ]


# ---------- pj_recur：遞迴的多項式 ----------

def _seq(p0, p1, c, n):
    a0, a1 = F(p0(c)), F(p1(c))
    if n == 0:
        return a0
    for _ in range(n - 1):
        a0, a1 = a1, c * a1 - a0
    return a1


def pj_recur(p0, p1, specs):
    P0, P1 = Poly([p0]), Poly([0, 1]) if p1 == "x" else Poly([p1])
    P2 = X * P1 - P0
    P3 = X * P2 - P1
    cards = []
    for kind, n, c, ok, why in specs:
        if kind == "P3":
            s = P3.text() if ok else (P3 + X).text()
            cards.append(card("P_{3}(x) = %s" % s, ok, why % {"P2": P2.text(), "P3": P3.text()}))
        else:
            v = _seq(P0, P1, c, n)
            shown = v if ok else kind
            assert ok or shown != v
            div = "x" if c == 0 else fac(c).strip("()")
            cards.append(card("P_{%d}(x) 除以 %s 的餘式為 %s" % (n, div, t(shown)), ok, why % {"v": t(v)}))
    p1s = "x" if p1 == "x" else t(p1)
    return item("pj_recur", "judge", 3, "遞迴的多項式", 1.3,
                "多項式數列 P_{0}(x) = %s，P_{1}(x) = %s，之後 P_{n + 1}(x) = x · P_{n}(x) − P_{n − 1}(x)。下列敘述哪些正確？" % (t(p0), p1s),
                [judge("除以 x − c 的餘式是 P_{n}(c)：把 c 代進遞迴式，看數字怎麼循環。", _ok(cards))])


# ---------- pj_struct：重根除式的結構 ----------

def pj_struct(p, q, k, r, A_val_t):
    """f = (x − p)(x − q)^2 Q + k(x − q)^2 + r(x)，r = (r1, r0)"""
    R = Poly([r[1], r[0]])
    fp = k * (p - q) ** 2 + R(p)
    fq = R(q)
    tt = A_val_t
    rem2 = Poly([-q, 1]) * (k * (p - q)) + R
    xp, xq = fac(p), fac(q)
    cards = [
        card("f(x) 除以 %s 的餘式為 r(%d)" % (xp.strip("()"), p), False, "f(%d) = %d · %d + r(%d) = %d + r(%d)" % (p, k, (p - q) ** 2, p, k * (p - q) ** 2, p)),
        card("若 f(%d) = %s、f(%d) = %s，則 r(%d) = %s" % (p, t(fp), q, t(fq), tt, t(R(tt))), True,
             "r(%d) = %s、r(%d) = %s，所以 r(x) = %s" % (p, t(R(p)), q, t(fq), R.text())),
        card("f(x) 除以 %s^{2} 的商式為 %s Q(x) + %d" % (xq, xp, k), True, "前兩項都有 %s^{2}，提出來就是商式，剩下 r(x) 是餘式" % xq),
        card("f(x) 除以 %s^{2} 的餘式為 f(%d)" % (xq, q), False, "餘式是一次式 r(x)，不是常數 f(%d)" % q),
        card("f(x) 除以 %s%s 的餘式為 %s + r(x)" % (xp, xq, Poly([-q * k * (p - q), k * (p - q)]).text()), True,
             "%d%s^{2} = %d%s%s %s %d%s" % (k, xq, k, xp, xq, "+" if k * (p - q) > 0 else M, abs(k * (p - q)), xq))]
    return item("pj_struct", "judge", 3, "重根除式的結構", 1.35,
                "f(x) 除以 %s%s^{2} 的商式為 Q(x)，餘式為 %d%s^{2} + r(x)，其中 r(x) 是一次多項式。下列敘述哪些正確？" % (xp, xq, k, xq),
                [judge("f(x) = %s%s^{2}Q(x) + %d%s^{2} + r(x)。換一個除式時，把式子重新組合。" % (xp, xq, k, xq), _ok(cards))])


# ---------- pj_cubgraph：從交點寫出三次函數 ----------

def pj_cubgraph(rs, k, m, s, xr, yr):
    f = Poly.roots(rs, k)
    y0 = f(0)
    assert k != 1 and y0 != 0
    n2 = len((f - m * X).real_roots())
    assert n2 == 3
    g = f - y0
    sum3 = sum(g.real_roots())
    assert abs(sum3 - float(sum(rs))) < 1e-6
    assert len(g.real_roots()) == 3 and k > 0
    r1, r2, r3 = sorted(rs)
    h = F(sum(rs), 3)
    facs = "".join(fac(r) for r in rs)
    ftext = f.text()
    cards = [
        card("f(x) = %s" % facs, False, "這樣 f(0) = %s，要乘 %s 才會過 (0, %s)" % (t(y0 / k), t(k), t(y0))),
        card("f(x) = %s 有三個相異實根" % cx(m), True, "g(x) = f(x) − %s 的圖形和 x 軸交三點（變號三次）" % cx(m)),
        card("f(2x) ≤ 0 的解為 x ≤ %s 或 %s ≤ x ≤ %s" % (t(F(r1, 2)), t(F(r2, 2)), t(F(r3, 2))), True,
             "f(t) ≤ 0 的解是 t ≤ %s 或 %s ≤ t ≤ %s，t = 2x" % (t(r1), t(r2), t(r3))),
        card("y = f(x) 圖形的對稱中心的 x 坐標為 %s" % t(h), True, "f(x) = %s，h = −b/(3a) = %s" % (ftext, t(h))),
        card("若 f(x) ≥ %s 的解為 a ≤ x ≤ b 或 x ≥ c，則 a + b + c = %s" % (t(y0), t(sum(rs) + s)), False,
             "f(x) − %s 的三根之和 = −b/a = %s" % (tp(y0), t(sum(rs))))]
    return item("pj_cubgraph", "judge", 2, "從交點寫出三次函數", 1.3,
                "三次函數 y = f(x) 的圖形通過 %s、(0, %s)。下列敘述哪些正確？" % ("、".join("(%s, 0)" % t(r) for r in rs), t(y0)),
                [judge("先寫 f(x) = k%s，用 (0, %s) 求 k：%sk = %s。" % (facs, t(y0), t(y0 / k), t(y0)), _ok(cards))],
                plot=grid(xr, yr, [{"f": f.expr(), "c": "cyan"}],
                          [{"x": float(r), "y": 0, "label": ""} for r in rs] + [{"x": 0, "y": float(y0), "label": "(0, %s)" % t(y0)}]))


def items():
    return [
        [pj_coef((3, -2, 1, -4), (2, 1, -3), [1, 1, 0, 1, 0]), pj_coef((2, 1, -3, 1), (1, -2, 4), [1, 0, 1, 0, 1]),
         pj_coef((1, -4, 2, 3), (3, 1, -1), [0, 1, 1, 1, 0])],
        [pj_divrule(2, 1, (1, 3, -1)), pj_divrule(1, -2, (1, -2, 5)), pj_divrule(3, 2, (2, 1, -3))],
        [pj_tworem(3, -2, (2, 5), (-1, 4), 1, 4), pj_tworem(2, -1, (3, -1), (1, 4), 0, 3), pj_tworem(4, 1, (-2, 3), (1, -5), 2, -1)],
        [pj_axis(9), pj_axis(7), pj_axis(5)],
        [pj_cubrange(-1, 2), pj_cubrange(1, 3), pj_cubrange(2, 4)],
        [pj_center(2, 1, -12, 5, 2), pj_center(1, 2, -3, 1, 2), pj_center(3, -1, -6, 2, 2)],
        [pj_ineq(s) for s in ineq_sets()],
        [pj_quadrant(s) for s in quadrant_sets()],
        [pj_meetline(s) for s in meet_sets()],
        [pj_recur(2, "x", [("P3", 3, 0, True, "P_{2} = %(P2)s，P_{3} = x(%(P2)s) − x"),
                           (F(2), 2026, 0, False, "P_{n}(0)：2、0、−2、0、2…四個一循環，2026 除以 4 餘 2，所以是 %(v)s"),
                           (None, 2025, 0, True, "n 是奇數時 P_{n}(0) = 0"),
                           (None, 100, 2, True, "x = 2：P_{n + 1}(2) = 2P_{n}(2) − P_{n − 1}(2)，從 2、2 開始一直是 2"),
                           (F(2), 2025, -2, False, "P_{n}(−2)：2、−2、2、−2…奇數項是 %(v)s")]),
         pj_recur(1, "x", [("P3", 3, 0, False, "P_{2} = %(P2)s，P_{3} = x(%(P2)s) − x = %(P3)s"),
                           (None, 2026, 0, True, "P_{n}(0)：1、0、−1、0、1…四個一循環，2026 除以 4 餘 2，所以是 %(v)s"),
                           (None, 100, 2, True, "x = 2：1、2、3、4…P_{n}(2) = n + 1，所以是 %(v)s"),
                           (F(1), 2025, 1, False, "P_{n}(1)：1、1、0、−1、−1、0、1…六個一循環，2025 除以 6 餘 3，所以是 %(v)s"),
                           (None, 2024, -1, True, "P_{n}(−1)：1、−1、0、1、−1、0…三個一循環，2024 除以 3 餘 2，所以是 %(v)s")]),
         pj_recur(0, 1, [("P3", 3, 0, True, "P_{2} = x · 1 − 0 = %(P2)s，P_{3} = x · x − 1"),
                         (F(1), 2026, 0, False, "P_{n}(0)：0、1、0、−1、0…四個一循環，2026 除以 4 餘 2，所以是 %(v)s"),
                         (None, 2027, 0, True, "P_{n}(0)：0、1、0、−1…2027 除以 4 餘 3，所以是 %(v)s"),
                         (F(1), 100, 2, False, "x = 2：0、1、2、3…P_{n}(2) = n，所以是 %(v)s"),
                         (None, 2025, -1, True, "P_{n}(−1)：0、1、−1、0、1、−1…三個一循環，2025 除以 3 餘 0，所以是 %(v)s")])],
        [pj_struct(-1, 4, 2, (1, 6), 1), pj_struct(2, -1, 3, (2, -1), 1), pj_struct(3, 1, 4, (-1, 5), 2)],
        [pj_cubgraph((-2, 1, 3), 2, 2, -1, [-3.0, 4.2], [-12.0, 16.0]), pj_cubgraph((-1, 2, 4), F(1, 2), 1, 2, [-2.0, 5.0], [-6.0, 8.0]),
         pj_cubgraph((-3, -1, 1), 2, -2, 1, [-4.0, 2.0], [-10.0, 10.0])],
    ]
