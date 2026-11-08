# 角的鍛造
from tlib import *

sin, cos, tan = math.sin, math.cos, math.tan
D = PI / 180


def fr(x, d):
    """x 寫成分母 d 的分數（不約分）：−45/85"""
    x = F(x)
    n = x * d
    assert isint(n)
    return (M if n < 0 else "") + "%d/%d" % (abs(n.numerator), d)


def leg(x):
    """畢氏三元組的另一股：sin → cos 的大小"""
    v = 1 - F(x) ** 2
    r = rt(v)
    assert r.n == 1
    return r.c


# ---------- ta_tri：三角形的第三個角 ----------

def ta_tri(cA, sB):
    cA, sB = F(cA), F(sB)
    sA, cB = leg(cA), leg(sB)
    A, B = math.acos(float(cA)), math.asin(float(sB))
    assert cA < 0 and A + B < PI
    cAB = cA * cB - sA * sB
    cC = -cAB
    assert near(cC, cos(PI - A - B))
    d = cA.denominator * sB.denominator
    trip = lambda s, c: "%d、%d、%d" % tuple(sorted([abs((s * s.denominator).numerator), abs((c * c.denominator).numerator)]) + [s.denominator])
    return item("ta_tri", "angle", 1, "三角形的第三個角", 1.05,
                "△ABC 中，cos A = %s，sin B = %s。求 cos C。" % (t(cA), t(sB)),
                [ch("cos A < 0，A 是鈍角。那 B 呢？", ["B 一定是銳角", "B 一定是鈍角", "B 可能是鈍角", "B 一定是直角"],
                    "三角形最多只有一個鈍角", "A 是鈍角 ⇒ B 是銳角"),
                 fl("畫直角三角形：", "sin A = [0]，cos B = [1]", [a(sA), a(cB)],
                    "%s 和 %s，銳角的 sin、cos 都是正的" % (trip(sA, cA), trip(sB, cB))),
                 fl("和角公式，先算 cos(A + B)：", "cos(A + B) = cos A cos B − sin A sin B = [0]", [a(cAB)],
                    "(%s)(%s) − (%s)(%s) = %s − %s" % (t(cA), t(cB), t(sA), t(sB), fr(cA * cB, d), fr(sA * sB, d))),
                 fl("C = π − (A + B)：", "答：cos C = −cos(A + B) = [0]", [a(cC)], "cos(π − θ) = −cos θ")])


# ---------- ta_sixth：六次方的差 ----------

def ta_sixth(c, K):
    c = F(c)
    ab = (1 - c * c) / 4
    s2 = 1 - c * c
    q = 1 - ab
    ans = K * c * q
    assert isint(ans)
    th = math.acos(float(c)) / 2
    assert near(K * (cos(th) ** 6 - sin(th) ** 6), ans)
    return item("ta_sixth", "angle", 2, "六次方的差", 1.25,
                "cos 2θ = %s，求 %d(cos^{6}θ − sin^{6}θ)。" % (t(c), K),
                [fl("a − b、a + b 各是多少？", "a − b = [0]，a + b = [1]", [a(c), "1"], "cos^{2}θ − sin^{2}θ = cos 2θ，cos^{2}θ + sin^{2}θ = 1",
                    pre="a = cos^{2}θ、b = sin^{2}θ：a^{3} − b^{3} = (a − b)(a^{2} + ab + b^{2})"),
                 fl("ab = sin^{2}θ cos^{2}θ = (sin 2θ)^{2}/4，先求 sin^{2} 2θ：", "sin^{2} 2θ = 1 − cos^{2} 2θ = [0]", [a(s2)], "1 − %s" % t(c * c)),
                 fl("除以 4：", "ab = [0]", [a(ab)], "%s 再除以 4" % t(s2)),
                 fl("a^{2} + ab + b^{2} = (a + b)^{2} − ab：", "a^{2} + ab + b^{2} = 1 − %s = [0]" % t(ab), [a(q)],
                    "%d/%d − %s" % (ab.denominator, ab.denominator, t(ab))),
                 fl("全部代回：", "答：%d · (%s) · (%s) = [0]" % (K, t(c), t(q)), [a(ans)], "%d × %s × %s" % (K, t(c), t(q)))])


# ---------- ta_halftan：第四象限的半角 ----------

def ta_halftan(p, c0):
    """p sin²θ + q cos θ − r = 0，兩根 c0、1；θ 在第四象限"""
    c0 = F(c0)
    q = p * (c0 + 1)
    r = p * c0 + p
    assert isint(q) and isint(r)
    q, r = int(q), int(r)
    s = -rt(1 - c0 * c0).c * 1 if rt(1 - c0 * c0).n == 1 else None
    sq = -Q.sqrt(1 - c0 * c0)
    th = 2 * PI - math.acos(float(c0))
    assert near(p * sin(th) ** 2 + q * cos(th) - r, 0)
    num = 1 - c0
    th2 = Q.of(num) / sq
    assert near(th2, tan(th / 2))
    poly_ = lambda a2, a1, a0: poly([(a2, "c^{2}"), (a1, "c"), (a0, "")]) + " = 0"
    corr = poly_(p, -q, r - p)
    opts = uniq([corr], [poly_(p, q, -(r - p)), poly_(p, -q, -(r - p)), poly_(1, -q, r - p), poly_(p, q, r - p)])
    k = (c0 * c0.denominator).numerator
    fac = "(%dc − %d)(c − 1) = 0" % (c0.denominator, k) if c0.denominator != 1 else "(c − %d)(c − 1) = 0" % k
    s_hint = "√{%s} = %s" % (t(1 - c0 * c0), (-sq).text())
    return item("ta_halftan", "angle", 2, "第四象限的半角", 1.25,
                "270° < θ < 360°，且 %d sin^{2}θ + %d cos θ − %d = 0。求 tan(θ/2)。" % (p, q, r),
                [ch("令 c = cos θ，sin^{2}θ = 1 − c^{2} 代入：", opts,
                    "%d − %dc^{2} + %dc − %d = 0，整理後乘 −1" % (p, p, q, r), "%s ⇒ %s" % (corr, fac)),
                 step("roots", q="劃掉不合的根。", cands=[
                     {"v": "cos θ = %s" % t(c0), "ok": True, "why": "第四象限 cos θ 在 0 和 1 之間"},
                     {"v": "cos θ = 1", "ok": False, "why": "cos θ = 1 時 θ = 360°，不在 270° < θ < 360° 裡"}], write="cos θ = %s" % t(c0)),
                 fl("第四象限的 sin θ 是負的：", "sin θ = −√{1 − %s} = [0]" % t(c0 * c0), [sq.ans()], s_hint),
                 fl("以切表弦 tan(θ/2) = (1 − cos θ)/sin θ，先算分子：", "1 − cos θ = [0]", [a(num)], "1 − %s" % t(c0)),
                 fl("分子除以分母：", "答：tan(θ/2) = (%s)/(%s) = [0]" % (t(num), sq.text()), [th2.ans()],
                    "分子分母同乘 %d，再約分" % c0.denominator if sq.rat() else "= −1/%s，有理化" % (-sq / num).text())])


# ---------- ta_lines：兩直線的夾角 ----------

def ta_lines(L1, L2, xr, yr):
    (a1, b1, c1), (a2, b2, c2) = L1, L2
    m1, m2 = F(-a1, b1), F(-a2, b2)
    num, den = m1 - m2, 1 + m1 * m2
    tn = abs(num / den)
    cs = 1 / Q.sqrt(1 + tn * tn)
    th = math.atan(float(tn))
    assert near(cs, cos(th))
    d1, d2 = math.degrees(math.atan(float(m1))), math.degrees(math.atan(float(m2)))
    lo, hi = sorted([d1, d2])
    if hi - lo > 90:
        lo, hi = hi, lo + 180
    assert near(hi - lo, math.degrees(th), 1e-6)
    det = a1 * b2 - a2 * b1
    ox, oy = F(b1 * c2 - b2 * c1, det), F(c1 * a2 - c2 * a1, det)
    p, qd = tn.numerator, tn.denominator
    hyp = "√{%d}" % (p * p + qd * qd)
    s1 = ln(a1, b1, c1, xr, yr, "cyan")
    s2 = ln(a2, b2, c2, xr, yr, "pink")
    e1 = max([s1["a"], s1["b"]], key=lambda v: v[0])
    e2 = max([s2["a"], s2["b"]], key=lambda v: v[0])
    return item("ta_lines", "angle", 1, "兩直線的夾角", 1.05,
                "L_{1}：%s、L_{2}：%s 的銳夾角為 θ。求 tan θ 與 cos θ。" % (lin(a1, b1, c1), lin(a2, b2, c2)),
                [fl("兩條直線的斜率：", "m_{1} = [0]，m_{2} = [1]", [a(m1), a(m2)], "ax + by + c = 0 的斜率是 −a/b"),
                 fl("差角公式 tan θ = |(m_{1} − m_{2})/(1 + m_{1}m_{2})|，分子、分母分開算：", "m_{1} − m_{2} = [0]，1 + m_{1}m_{2} = [1]", [a(num), a(den)],
                    "%s %s %s、1 + (%s)(%s)" % (t(m1), "+" if m2 < 0 else "−", t(abs(m2)), t(m1), t(m2))),
                 fl("相除，取絕對值：", "tan θ = |(%s)/(%s)| = [0]" % (t(num), t(den)), [a(tn)], "兩個分數相除"),
                 fl("tan θ = %s：對邊 %d、鄰邊 %d 的直角三角形。" % (t(tn), p, qd), "答：cos θ = %d/%s = [0]" % (qd, hyp), [cs.ans()],
                    "%s = %s，有理化" % (hyp, rtt(p * p + qd * qd)) if rt(p * p + qd * qd).c != 1 else "%s 有理化" % hyp)],
                plot={"x": xr, "y": yr, "geo": True, "axes": True,
                      "shapes": [s1, s2, {"k": "angle", "o": [fx(ox), fx(oy)], "a0": fx(lo), "a1": fx(hi), "r": 18, "s": "θ"},
                                 {"k": "label", "p": [fx(e1[0] - 0.4), fx(e1[1] + 0.3)], "s": "L1", "c": "cyan"},
                                 {"k": "label", "p": [fx(e2[0] - 0.4), fx(e2[1] + 0.3)], "s": "L2", "c": "pink"}]})


# ---------- ta_roots：根與係數 ----------

def ta_roots(n, k):
    assert n - k * k == 1
    r1 = Q(-k, 1, n)
    r2 = 1 / r1
    assert r2 == Q(k, 1, n)
    S = r1 + r2
    s2 = 2 / S
    th = math.asin(float(s2)) / 2
    assert near(tan(th) + 1 / tan(th), S)
    rn = "√{%d}" % n
    return item("ta_roots", "angle", 2, "根與係數", 1.2,
                "%s − %d 是 x^{2} − (tan θ + 1/tan θ)x + 1 = 0 的一根。求 sin 2θ。" % (rn, k),
                [ch("兩根的積是 1，另一根是 1/(%s − %d)。有理化之後是？" % (rn, k),
                    ["%s + %d" % (rn, k), "%s − %d" % (rn, k), "%d − %s" % (k, rn), "−%s − %d" % (rn, k)],
                    "(%s − %d)(%s + %d) = %d − %d = 1" % (rn, k, rn, k, n, k * k), "另一根 = 1/(%s − %d) = %s + %d" % (rn, k, rn, k)),
                 fl("兩根的和 = x 的係數變號：", "tan θ + 1/tan θ = (%s − %d) + (%s + %d) = [0]" % (rn, k, rn, k), [S.ans()],
                    "−%d 和 +%d 抵消" % (k, k)),
                 ch("tan θ + 1/tan θ 化簡：", ["1/(sin θ cos θ)", "1/(sin θ + cos θ)", "sin θ cos θ", "2/cos 2θ"],
                    "通分：(sin^{2}θ + cos^{2}θ)/(sin θ cos θ)", "tan θ + 1/tan θ = 1/(sin θ cos θ) = 2/sin 2θ"),
                 fl("2/sin 2θ = %s：" % S.text(), "答：sin 2θ = 1/%s = [0]" % rn, [s2.ans()], "1/%s 有理化" % rn)])


# ---------- ta_tanpair：兩根的 tan ----------

def ta_tanpair(p, q):
    assert p * p - 4 * q > 0
    s, pr = F(-p), F(q)
    v = (1 + pr) / s
    r1 = (-p + math.sqrt(p * p - 4 * q)) / 2
    r2 = (-p - math.sqrt(p * p - 4 * q)) / 2
    al, be = math.atan(r1), math.atan(r2)
    assert near(cos(al - be) / sin(al + be), v)
    eq = poly([(1, "x^{2}"), (p, "x"), (q, "")]) + " = 0"
    return item("ta_tanpair", "angle", 2, "兩根的 tan", 1.15,
                "tan α、tan β 是 %s 的兩根。求 cos(α − β)/sin(α + β)。" % eq,
                [fl("根與係數：", "tan α + tan β = [0]，tan α tan β = [1]", [a(s), a(pr)], "和 = −b/a、積 = c/a"),
                 ch("分子、分母同除以 cos α cos β：", ["(1 + tan α tan β)/(tan α + tan β)", "(1 − tan α tan β)/(tan α + tan β)",
                                                   "(1 + tan α tan β)/(tan α − tan β)", "(tan α + tan β)/(1 + tan α tan β)"],
                    "cos α cos β + sin α sin β 除以 cos α cos β 是 1 + tan α tan β", "原式 = (1 + tan α tan β)/(tan α + tan β)"),
                 fl("代入：", "答：原式 = [0]", [a(v)], "(1 + %s)/%s" % (tp(pr), tp(s)))])


# ---------- ta_split：拆角 ----------

def ta_split(cm, sp):
    """cos(α − β) = cm，sin(α + β) = sp < 0"""
    cm, sp = F(cm), F(sp)
    smv, cpv = leg(cm), -leg(sp)
    u = math.acos(float(cm))
    v = PI + math.asin(-float(sp))
    al, be = (u + v) / 2, (v - u) / 2
    assert PI / 2 <= al <= PI and 0 <= be <= PI / 2
    p1, p2 = cpv * cm, sp * smv
    c2a = p1 - p2
    assert near(c2a, cos(2 * al))
    d = cm.denominator * sp.denominator
    trip = lambda c, s: "%d、%d、%d" % tuple(sorted([abs((c * c.denominator).numerator), abs((s * s.denominator).numerator)]) + [c.denominator])
    return item("ta_split", "angle", 3, "拆角", 1.35,
                "π/2 ≤ α ≤ π、0 ≤ β ≤ π/2，cos(α − β) = %s，sin(α + β) = %s。求 cos 2α。" % (t(cm), t(sp)),
                [fl("先寫出 α − β、α + β 的範圍：", "[0] ≤ α − β ≤ π，π/2 ≤ α + β ≤ [1]π", ["0", "3/2"], "α − β：最小 π/2 − π/2，α + β：最大 π + π/2"),
                 ch("sin(α + β) = %s < 0，α + β 落在哪裡？" % t(sp), ["π 到 3π/2（第三象限）", "π/2 到 π（第二象限）", "3π/2 到 2π（第四象限）", "0 到 π/2（第一象限）"],
                    "在 π/2 到 3π/2 之間，sin 是負的只有後半段", "π < α + β < 3π/2 ⇒ cos(α + β) < 0"),
                 fl("α − β 在 0 到 π，sin 是正的：", "sin(α − β) = [0]，cos(α + β) = [1]", [a(smv), a(cpv)], "%s 和 %s" % (trip(cm, smv), trip(sp, cpv))),
                 fl("兩項分開算：", "cos(α + β)cos(α − β) = [0]，sin(α + β)sin(α − β) = [1]", [a(p1), a(p2)],
                    "(%s)(%s)、(%s)(%s)" % (t(cpv), t(cm), t(sp), t(smv)),
                    pre="2α = (α + β) + (α − β)：cos 2α = cos(α + β)cos(α − β) − sin(α + β)sin(α − β)"),
                 fl("相減：", "答：cos 2α = %s − (%s) = [0]" % (fr(p1, d), fr(p2, d)), [a(c2a)], "%s %s %d" % (t(p1 * d), "+" if p2 < 0 else "−", abs(p2 * d)))])


# ---------- ta_grid：方格裡的角 ----------

def ta_grid(W, H):
    tt = F(W, H)
    tn = 2 * tt / (1 - tt * tt)
    cs = (1 - tt * tt) / (1 + tt * tt)
    ang = 2 * math.atan2(W / 2, H / 2)
    assert near(tn, tan(ang)) and near(cs, cos(ang))
    shapes = []
    for i in range(1, W):
        shapes.append({"k": "seg", "a": [i, 0], "b": [i, H], "c": "faint"})
    for j in range(1, H):
        shapes.append({"k": "seg", "a": [0, j], "b": [W, j], "c": "faint"})
    ox, oy = F(W, 2), F(H, 2)
    shapes += [{"k": "poly", "pts": [[0, 0], [W, 0], [W, H], [0, H]], "c": "dim"},
               {"k": "seg", "a": [0, 0], "b": [W, H], "c": "cyan"}, {"k": "seg", "a": [W, 0], "b": [0, H], "c": "cyan"},
               {"k": "seg", "a": [fx(ox), fx(oy)], "b": [fx(ox), 0], "c": "gold", "dash": True, "at": 1},
               {"k": "label", "p": [-0.25, -0.3], "s": "A"}, {"k": "label", "p": [W + 0.25, -0.3], "s": "B"},
               {"k": "label", "p": [W + 0.25, H + 0.3], "s": "C"}, {"k": "label", "p": [-0.25, H + 0.3], "s": "D"},
               {"k": "label", "p": [fx(ox), fx(oy + 0.35)], "s": "O"}, {"k": "label", "p": [fx(ox), -0.35], "s": "M", "at": 1}]
    return item("ta_grid", "angle", 2, "方格裡的角", 1.15,
                "%d 個邊長 1 的正方形排成 %d × %d 的長方形 ABCD，O 是兩條對角線的交點。求 tan∠AOB 與 cos∠AOB。" % (W * H, W, H),
                [fl("從 O 作 \\ol{AB} 的垂線，垂足 M：", "tan∠AOM = \\ol{AM}/\\ol{OM} = [0]", [a(tt)], "\\ol{AM} = %s、\\ol{OM} = %s" % (t(ox), t(oy))),
                 fl("∠AOB = 2∠AOM：", "tan∠AOB = [0]", [a(tn)], "2t/(1 − t^{2})，t = %s" % t(tt)),
                 fl("cos 2∠AOM = (1 − t^{2})/(1 + t^{2})：", "答：cos∠AOB = [0]", [a(cs)], "(1 − %s)/(1 + %s)" % (t(tt * tt), t(tt * tt)))],
                plot={"x": [-0.4, W + 0.4], "y": [-0.6, H + 0.6], "geo": True, "h": 150 if H <= 2 else 190, "shapes": shapes})


# ---------- ta_double：兩倍的角 ----------

def ta_double(b, a_):
    """∠B = 2∠A，AC = b、BC = a"""
    cA = F(b, 2 * a_)
    cB = 2 * cA * cA - 1
    assert F(1, 2) < cA < 1 and cB > 0
    sB = Q.sqrt(1 - cB * cB)
    tB = sB / cB
    A = math.acos(float(cA))
    B = 2 * A
    assert near(sin(B) / sin(A), F(b, a_)) and near(tB, tan(B))
    C = PI - A - B
    c = a_ * sin(C) / sin(A)
    Ax, Ay = c * cos(B), c * sin(B)
    s1 = math.degrees(math.atan2(-Ay, -Ax))
    s2 = math.degrees(math.atan2(-Ay, a_ - Ax))
    lo, hi = sorted([s1, s2])
    mx, my = (Ax + a_) / 2, Ay / 2
    return item("ta_double", "angle", 3, "兩倍的角", 1.35,
                "△ABC 中，∠B = 2∠A，\\ol{AC} = %d，\\ol{BC} = %d。求 tan B。" % (b, a_),
                [fl("正弦定理：\\ol{AC} 對 B、\\ol{BC} 對 A。", "sin B/sin A = \\ol{AC}/\\ol{BC} = [0]", [a(F(b, a_))], "%d/%d" % (b, a_)),
                 fl("sin B = sin 2A = 2 sin A cos A：", "sin 2A/sin A = 2 cos A = %s ⇒ cos A = [0]" % t(F(b, a_)), [a(cA)], "sin A 約掉"),
                 fl("二倍角：", "cos B = cos 2A = 2cos^{2}A − 1 = [0]", [a(cB)], "2 · %s − 1" % t(cA * cA)),
                 fl("B 是銳角，sin B 是正的：", "sin B = √{1 − %s} = [0]" % t(cB * cB), [sB.ans()], "√{%s}" % t(1 - cB * cB)),
                 fl("tan B = sin B/cos B：", "答：tan B = [0]", [tB.ans()], "(%s)/(%s)" % (sB.text(), t(cB)))],
                plot={"x": [fx(min(0, Ax) - 0.6), fx(max(a_, Ax) + 0.6)], "y": [-0.7, fx(Ay + 0.7)], "geo": True,
                      "shapes": [{"k": "poly", "pts": [[0, 0], [a_, 0], [fx(Ax), fx(Ay)]], "c": "cyan"},
                                 {"k": "angle", "o": [fx(Ax), fx(Ay)], "a0": fx(lo), "a1": fx(hi), "r": 22, "s": "θ"},
                                 {"k": "angle", "o": [0, 0], "a0": 0, "a1": fx(math.degrees(B)), "r": 18, "s": "2θ"},
                                 {"k": "label", "p": [fx(Ax), fx(Ay + 0.4)], "s": "A"}, {"k": "label", "p": [-0.3, -0.3], "s": "B"},
                                 {"k": "label", "p": [a_ + 0.3, -0.3], "s": "C"},
                                 {"k": "label", "p": [fx(mx + 0.45), fx(my + 0.1)], "s": str(b)}, {"k": "label", "p": [a_ / 2, -0.4], "s": str(a_)}]})


# ---------- ta_shift：通分再疊合 ----------

def ta_shift(cfg):
    v = cfg["val"]
    assert near(v, cfg["num"]())
    return item("ta_shift", "angle", 1, "通分再疊合", 1.0, "求 %s 的值。" % cfg["expr"],
                [fl("通分，分子疊合：%s。" % cfg["fold"], "分子 = [0] sin %d°" % cfg["n_ang"], [cfg["n_co"]], cfg["n_hint"]),
                 fl("分母用二倍角：", "分母 = %s = [0] sin %d°" % (cfg["den"], cfg["d_ang"]), ["1/2"], "sin %d° = 2 sin %d° cos %d°" % (cfg["d_ang"], cfg["x"], cfg["x"])),
                 fl("相除：", "答：原式 = [0]", [str(v)], cfg["end_hint"])])


SHIFT = [
    {"expr": "√{3}/sin 20° − 1/cos 20°", "num": lambda: S3 / sin(20 * D) - 1 / cos(20 * D), "val": 4, "x": 20,
     "fold": "√{3} cos 20° − sin 20° = 2(sin 60° cos 20° − cos 60° sin 20°)", "n_ang": 40, "n_co": "2", "n_hint": "sin(60° − 20°)",
     "den": "sin 20° cos 20°", "d_ang": 40, "end_hint": "2 除以 1/2"},
    {"expr": "3/sin 10° − 3√{3}/cos 10°", "num": lambda: 3 / sin(10 * D) - 3 * S3 / cos(10 * D), "val": 12, "x": 10,
     "fold": "3 cos 10° − 3√{3} sin 10° = 6(sin 30° cos 10° − cos 30° sin 10°)", "n_ang": 20, "n_co": "6", "n_hint": "sin(30° − 10°)",
     "den": "sin 10° cos 10°", "d_ang": 20, "end_hint": "6 除以 1/2"},
    {"expr": "1/sin 50° + √{3}/cos 50°", "num": lambda: 1 / sin(50 * D) + S3 / cos(50 * D), "val": 4, "x": 50,
     "fold": "cos 50° + √{3} sin 50° = 2(sin 30° cos 50° + cos 30° sin 50°)", "n_ang": 80, "n_co": "2", "n_hint": "sin(30° + 50°)",
     "den": "sin 50° cos 50°", "d_ang": 100, "end_hint": "sin 100° = sin 80°，2 除以 1/2"},
]


def items():
    return [
        [ta_tri(F(-3, 5), F(8, 17)), ta_tri(F(-5, 13), F(3, 5)), ta_tri(F(-4, 5), F(5, 13))],
        [ta_sixth(F(1, 3), 27), ta_sixth(F(1, 2), 32), ta_sixth(F(3, 5), 125)],
        [ta_halftan(3, F(1, 3)), ta_halftan(2, F(1, 2)), ta_halftan(5, F(3, 5))],
        [ta_lines((1, -3, 2), (2, 1, -5), [-2.5, 4.0], [-1.5, 4.2]), ta_lines((2, -1, 1), (1, 1, -4), [-1.5, 4.5], [-1.0, 5.5]),
         ta_lines((1, -4, 6), (2, 1, -6), [-1.5, 5.0], [-1.0, 5.5])],
        [ta_roots(5, 2), ta_roots(2, 1), ta_roots(10, 3)],
        [ta_tanpair(5, -3), ta_tanpair(-4, 2), ta_tanpair(3, -6)],
        [ta_split(F(5, 13), F(-3, 5)), ta_split(F(4, 5), F(-5, 13)), ta_split(F(3, 5), F(-8, 17))],
        [ta_grid(5, 2), ta_grid(4, 3), ta_grid(3, 1)],
        [ta_double(6, 4), ta_double(8, 5), ta_double(5, 3)],
        [ta_shift(c) for c in SHIFT],
    ]
