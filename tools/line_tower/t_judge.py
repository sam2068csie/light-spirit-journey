# 真假燈標
from lib import *


# ---------- lj_slope：直線的斜率與截距 ----------
# 五張卡各有「對的說法」和「錯的說法」，每組數字選不一樣的真假組合

def lj_slope(A, B, C, flags):
    m = -F(A) / B
    xi = -F(C) / A
    yi = -F(C) / B
    assert xi != 0 and yi != 0 and xi != yi and isint(xi) and isint(yi)
    area = abs(xi * yi) / 2
    L = lin(A, B, C)
    pa, pb, pc = lin_norm(B, -A, 0)
    perp = poly([(pa, "x"), (pb, "y")]) + " = 0"
    qa, qb, qc = lin_norm(A, B, 0)
    par = poly([(qa, "x"), (qb, "y")]) + " = 0"
    mp = -1 / m
    cards = []
    # 1 斜率
    if flags[0]:
        cards.append(card("L 的斜率是 %s" % t(m), True, "ax + by + c = 0 的斜率 −a/b = %s" % (("−%s/%s = " % (t(A), tp(B))) if B < 0 else "") + t(m)))
    else:
        cards.append(card("L 的斜率是 %s" % t(-m), False, "斜率是 −a/b = %s，正負號相反了" % t(m)))
    # 2 y 截距
    if flags[1]:
        cards.append(card("L 的 y 截距是 %s" % t(yi), True, "x = 0：%s，y = %s" % (lin(0, B, C), t(yi))))
    else:
        cards.append(card("L 的 y 截距是 %s" % t(xi), False, "x = 0 才是 y 截距：%s，y = %s（%s 是 x 截距）" % (lin(0, B, C), t(yi), t(xi))))
    # 3 x 截距
    if flags[2]:
        cards.append(card("L 的 x 截距是 %s" % t(xi), True, "y = 0：%s，x = %s" % (lin(A, 0, C), t(xi))))
    else:
        cards.append(card("L 的 x 截距是 %s" % t(-xi), False, "y = 0：%s，x = %s" % (lin(A, 0, C), t(xi))))
    # 4 過原點的垂線
    if flags[3]:
        cards.append(card("過原點且和 L 垂直的直線是 %s" % perp, True, "垂直的斜率是 %s，過原點：y = %s" % (t(mp), cx(mp))))
    else:
        cards.append(card("過原點且和 L 垂直的直線是 %s" % par, False, "%s 的斜率也是 %s，和 L 平行，不是垂直" % (par, t(m))))
    # 5 面積
    if flags[4]:
        cards.append(card("L 和兩軸圍成的三角形面積是 %s" % t(area), True, "兩截距的長是 %s 和 %s，面積 = \\frac{1}{2} × %s × %s = %s" % (t(abs(xi)), t(abs(yi)), t(abs(xi)), t(abs(yi)), t(area))))
    else:
        cards.append(card("L 和兩軸圍成的三角形面積是 %s" % t(2 * area), False, "兩截距的長是 %s 和 %s，面積 = \\frac{1}{2} × %s × %s = %s" % (t(abs(xi)), t(abs(yi)), t(abs(xi)), t(abs(yi)), t(area))))
    xr, yr = box([(xi, 0), (0, yi)], pad=2.2)
    # 標籤放在線上靠框邊的地方
    s = ln(A, B, C, xr, yr)
    p = s["b"] if s["b"][1] > s["a"][1] else s["a"]
    lp = (p[0] * 0.85 + (xi if p[0] != xi else 0) * 0.15, p[1] * 0.85)
    return {"id": "lj_slope", "kind": "judge", "tier": 1, "title": "直線的斜率與截距", "tmul": 1.0,
            "stem": "直線 L：%s。下列敘述哪些正確？" % L,
            "plot": geo(xr, yr, [s, lab((p[0] + (0.5 if p[0] < xr[1] - 1 else -0.6), p[1] - 0.6), "L", "cyan")]),
            "steps": [judge("x = 0 求 y 截距、y = 0 求 x 截距，斜率是 −a/b。", cards)]}


# ---------- lj_circle：畫得出圓嗎 ----------

def _circ_card(cx, cy, D, E, Fc):
    s = poly([(cx, "x^{2}"), (cy, "y^{2}"), (D, "x"), (E, "y"), (Fc, "")]) + " = 0"
    if cx != cy:
        return card(s, False, "x^{2}、y^{2} 的係數不一樣，不是圓")
    c = F(cx)
    h, k = -F(D) / (2 * c), -F(E) / (2 * c)
    R = h * h + k * k - F(Fc) / c
    eqs = circ_eq(h, k, R)
    pre = "" if c == 1 else "兩邊除以 %s：" % t(c)
    if R > 0:
        why = pre + eqs + ("，半徑 " + rtt(R) if c == 1 else " > 0")
        return card(s, True, why)
    if R == 0:
        return card(s, False, pre + eqs + "，只有一個點 " + P(h, k))
    return card(s, False, pre + eqs + " < 0，沒有點")


def lj_circle(eqs):
    return {"id": "lj_circle", "kind": "judge", "tier": 1, "title": "畫得出圓嗎", "tmul": 1.05,
            "stem": "下列方程式的圖形，哪些是圓？",
            "steps": [judge("配方成 (x − h)^{2} + (y − k)^{2} = 右邊：右邊要大於 0 才是圓，等於 0 是一個點，小於 0 畫不出來。",
                            [_circ_card(*e) for e in eqs])]}


# ---------- lj_relation：兩個圓和一條線 ----------
# 卡片是每組數字各自寫的，這裡用程式驗證每一張的真假

def _d(p, L):
    a_, b_, c_ = L
    return abs(F(a_) * p[0] + F(b_) * p[1] + c_) / math.sqrt(a_ * a_ + b_ * b_)


def lj_relation(c1, c2, cards, xr, yr):
    (o1, r1), (o2, r2) = c1, c2
    for cd in cards:
        assert cd["ok"] == cd.pop("check")(), cd["s"]
    return {"id": "lj_relation", "kind": "judge", "tier": 2, "title": "兩個圓和一條線", "tmul": 1.2,
            "stem": "圓 C_{1}：%s，圓 C_{2}：%s。下列敘述哪些正確？" % (circ_eq(o1[0], o1[1], r1 * r1), circ_eq(o2[0], o2[1], r2 * r2)),
            "plot": geo(xr, yr, [circ(o1, r1, "cyan"), circ(o2, r2, "pink"), pt(o1, "O" if o1 == (0, 0) else "K₁", "cyan"), pt(o2, "K" if o1 == (0, 0) else "K₂", "pink")]),
            "steps": [judge("兩圓比圓心距和半徑的和、差。直線和圓比 d(圓心, L) 和 r。", cards)]}


def _ck(s, ok, why, check):
    """check 當場算（不要等到後面，變數會被改掉）"""
    r = bool(check())
    return {"s": s, "ok": ok, "why": why, "check": lambda: r}


def lj_relation_sets():
    d2 = lambda p, q: (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2
    out = []
    # v0：外切
    o1, o2 = (0, 0), (6, 8)
    out.append(((o1, 5), (o2, 5), [
        _ck("C_{1}、C_{2} 外切", True, "圓心距 √{36 + 64} = 10 = 5 + 5", lambda: d2(o1, o2) == 100),
        _ck("C_{1}、C_{2} 有 4 條公切線", False, "外切的兩圓只有 3 條公切線", lambda: False),
        _ck("直線 3x + 4y = 25 和兩個圓都相切", True, "d(O, L) = 25/5 = 5，d(K, L) = |18 + 32 − 25|/5 = 5，都等於半徑",
            lambda: _d(o1, (3, 4, -25)) == 5 and _d(o2, (3, 4, -25)) == 5),
        _ck("直線 x = 1 和 C_{2} 交於兩點", False, "d(K, L) = |6 − 1| = 5 = r，相切，只有一個交點", lambda: _d(o2, (1, 0, -1)) < 5),
        _ck("點 (3, 4) 在兩個圓上", True, "9 + 16 = 25，(3 − 6)^{2} + (4 − 8)^{2} = 25，它就是切點",
            lambda: d2((3, 4), o1) == 25 and d2((3, 4), o2) == 25)], [-6.2, 12.2], [-6.2, 14.2]))
    # v1：相交
    o1, o2 = (0, 0), (4, 3)
    out.append(((o1, 5), (o2, 5), [
        _ck("C_{1}、C_{2} 外切", False, "圓心距 √{16 + 9} = 5 < 5 + 5，是相交", lambda: d2(o1, o2) == 100),
        _ck("C_{1}、C_{2} 有 2 條公切線", True, "|5 − 5| < 5 < 5 + 5，相交的兩圓有 2 條公切線", lambda: 0 < d2(o1, o2) < 100),
        _ck("直線 x = −5 和 C_{1} 相切", True, "d(O, L) = 5 = r", lambda: _d(o1, (1, 0, 5)) == 5),
        _ck("直線 x = −5 也和 C_{2} 相切", False, "d(K, L) = |4 + 5| = 9 > 5，和 C_{2} 不相交", lambda: _d(o2, (1, 0, 5)) == 5),
        _ck("原點在 C_{2} 上", True, "(0 − 4)^{2} + (0 − 3)^{2} = 25，剛好在圓上", lambda: d2((0, 0), o2) == 25)], [-6.2, 10.2], [-6.2, 9.2]))
    # v2：外離
    o1, o2 = (0, 0), (6, 8)
    out.append(((o1, 2), (o2, 4), [
        _ck("C_{1}、C_{2} 外離", True, "圓心距 10 > 2 + 4", lambda: d2(o1, o2) > 36),
        _ck("C_{1}、C_{2} 有 3 條公切線", False, "外離的兩圓有 4 條公切線（外切才是 3 條）", lambda: False),
        _ck("直線 3x + 4y = 10 和 C_{1} 相切", True, "d(O, L) = 10/5 = 2 = r", lambda: _d(o1, (3, 4, -10)) == 2),
        _ck("直線 3x + 4y = 10 也和 C_{2} 相切", False, "d(K, L) = |18 + 32 − 10|/5 = 8 > 4，不相交", lambda: _d(o2, (3, 4, -10)) == 4),
        _ck("C_{2} 上離原點最近的點，距離原點 6", True, "原點在 C_{2} 外：最近 = 圓心距 − r = 10 − 4", lambda: math.sqrt(d2(o1, o2)) - 4 == 6)], [-3.2, 11.2], [-3.2, 13.2]))
    return out


# ---------- lj_locus：哪些是完整的圓 ----------

def lj_locus(a_, cards):
    for cd in cards:
        assert cd["ok"] == cd.pop("check")(), cd["s"]
    return {"id": "lj_locus", "kind": "judge", "tier": 3, "title": "哪些是完整的圓", "tmul": 1.3,
            "stem": "A(−%d, 0)、B(%d, 0)。下列各動點 P 的軌跡，哪些是「完整的圓」？" % (a_, a_),
            "steps": [judge("設 P(x, y) 代進條件整理。最後記得檢查：有沒有要拿掉的點？", cards)]}


def _apollo(a_, k):
    """PA = k·PB，A(−a, 0)、B(a, 0)：圓心 (h, 0)、r^2"""
    h = F(a_) * (k * k + 1) / (k * k - 1)
    return h, h * h - a_ * a_


def lj_locus_sets():
    out = []
    h, r2 = _apollo(2, 2)
    out.append((2, [
        _ck("\\ol{PA} = 2\\ol{PB}", True, "整理成 %s，每一點都符合（阿波羅尼斯圓）" % circ_eq(h, 0, r2), lambda: r2 > 0),
        _ck("∠APB = 90°", False, "以 \\ol{AB} 為直徑的圓 x^{2} + y^{2} = 4，但要拿掉 A、B（那裡沒有角）", lambda: False),
        _ck("P 到原點和到 (4, 0) 一樣遠", False, "是原點和 (4, 0) 的中垂線 x = 2，是直線不是圓", lambda: False),
        _ck("Q 在 x^{2} + y^{2} = 4 上走，P 是 Q 和 (6, 0) 的中點", True, "Q = (2x − 6, 2y) 代進去：(x − 3)^{2} + y^{2} = 1，完整的圓", lambda: True),
        _ck("\\ol{PA}^{2} + \\ol{PB}^{2} = 8", False, "2x^{2} + 2y^{2} + 8 = 8，x^{2} + y^{2} = 0，只有原點一個點", lambda: (8 - 2 * 4) / 2 > 0)]))
    h, r2 = _apollo(4, 3)
    assert (h, r2) == (5, 9)
    out.append((4, [
        _ck("\\ol{PA} = 3\\ol{PB}", True, "整理成 %s，每一點都符合（阿波羅尼斯圓）" % circ_eq(h, 0, r2), lambda: r2 > 0),
        _ck("\\ol{PA} + \\ol{PB} = 8", False, "\\ol{PA} + \\ol{PB} ≥ \\ol{AB} = 8，等號只在 \\ol{AB} 上：是一條線段", lambda: False),
        _ck("Q 在 x^{2} + y^{2} = 16 上走，P 是 Q 和 (0, 6) 的中點", True, "Q = (2x, 2y − 6) 代進去：x^{2} + (y − 3)^{2} = 4，完整的圓", lambda: True),
        _ck("\\ol{PA}^{2} + \\ol{PB}^{2} = 50", True, "2x^{2} + 2y^{2} + 32 = 50，x^{2} + y^{2} = 9，完整的圓", lambda: (50 - 2 * 16) / 2 > 0),
        _ck("∠APB = 90°", False, "以 \\ol{AB} 為直徑的圓 x^{2} + y^{2} = 16，但要拿掉 A、B（那裡沒有角）", lambda: False)]))
    h, r2 = _apollo(3, 2)
    assert (h, r2) == (5, 16)
    out.append((3, [
        _ck("\\ol{PA} = \\ol{PB}", False, "\\ol{AB} 的中垂線 x = 0，是直線不是圓", lambda: False),
        _ck("\\ol{PA} = 2\\ol{PB}", True, "整理成 %s，每一點都符合（阿波羅尼斯圓）" % circ_eq(h, 0, r2), lambda: r2 > 0),
        _ck("\\ol{PA}^{2} + \\ol{PB}^{2} = 10", False, "2x^{2} + 2y^{2} + 18 = 10，x^{2} + y^{2} = −4 < 0，沒有點", lambda: (10 - 18) / 2 > 0),
        _ck("Q 在 (x − 6)^{2} + y^{2} = 4 上走，P 是 \\ol{QA} 的中點", True, "Q = (2x + 3, 2y) 代進去：(x − 3/2)^{2} + y^{2} = 1，完整的圓", lambda: True),
        _ck("∠APB = 90°", False, "以 \\ol{AB} 為直徑的圓 x^{2} + y^{2} = 9，但要拿掉 A、B（那裡沒有角）", lambda: False)]))
    return out


def items():
    return [
        [lj_slope(3, -4, 12, [1, 1, 0, 1, 0]), lj_slope(2, 5, -10, [0, 1, 1, 0, 1]), lj_slope(5, -3, -15, [1, 0, 1, 1, 0])],
        [lj_circle([(1, 1, -4, 6, 4), (1, 1, 2, -4, 5), (2, 2, -8, 0, 1), (1, 2, 0, 0, -4), (1, 1, 0, 6, 10)]),
         lj_circle([(1, 1, 6, -2, 10), (1, 1, -2, 0, -8), (2, 1, 0, 0, -8), (3, 3, -6, 12, -3), (1, 1, 4, -6, 14)]),
         lj_circle([(1, -1, 0, 0, -4), (1, 1, 0, -8, 7), (1, 1, -6, 2, 10), (2, 2, 4, 0, -6), (1, 1, 2, 2, 5)])],
        [lj_relation(*s) for s in lj_relation_sets()],
        [lj_locus(*s) for s in lj_locus_sets()],
    ]
