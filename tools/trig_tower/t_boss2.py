# 試煉大題（新加的 6 題：難度 2 四題、難度 3 兩題）
from tlib import *

sin, cos, tan = math.sin, math.cos, math.tan


def gf(k):
    return repr(float(k))


def sols_cos(k, lo, hi):
    """cos u = k 在 [lo π, hi π] 的解（π 的倍數）"""
    al = None
    for d in (F(0), F(1, 6), F(1, 4), F(1, 3), F(1, 2), F(2, 3), F(3, 4), F(5, 6), F(1)):
        if cv(d) == k:
            al = d
            break
    assert al is not None
    out = set()
    for m in range(-4, 5):
        for u in (al + 2 * m, -al + 2 * m):
            if lo <= u <= hi:
                out.add(u)
    return al, sorted(out)


# ---------- tb_triple：三倍角 ----------

def tb_triple(s, k):
    s, k = F(s), Q.of(k)
    c2 = 1 - 2 * s * s
    s3 = 3 * s - 4 * s ** 3
    th = math.asin(float(s))
    assert near(c2, cos(2 * th)) and near(s3, sin(3 * th))
    al, us = sols_cos(k, 0, 3)
    xs = [u / 3 for u in us]
    rs = roots_in(lambda x: 4 * cos(x) ** 3 - 3 * cos(x) - float(k), 0, PI)
    assert len(rs) == len(xs) == 3 and near(sum(rs) / PI, sum(xs), 1e-6)
    S = sum(xs)
    return item("tb_triple", "boss", 2, "三倍角", 1.6,
                "θ 是銳角，sin θ = %s。\n(1) 求 cos 2θ　(2) 求 sin 3θ　(3) 解 4cos^{3}x − 3cos x = %s（0 ≤ x ≤ π），求所有解的和" % (t(s), k.text()),
                [fl("二倍角：", "(1)　cos 2θ = 1 − 2 sin^{2}θ = [0]", [a(c2)], "1 − 2 · %s" % t(s * s), part="(1)"),
                 ch("sin 3θ = sin(2θ + θ)，展開後全部換成 sin θ：", ["3 sin θ − 4 sin^{3}θ", "4 sin^{3}θ − 3 sin θ", "3 sin θ + 4 sin^{3}θ", "3 sin θ − sin^{3}θ"],
                    "sin 2θ cos θ + cos 2θ sin θ = 2 sin θ cos^{2}θ + (1 − 2 sin^{2}θ) sin θ，再把 cos^{2}θ 換成 1 − sin^{2}θ",
                    "(2)　sin 3θ = 3 sin θ − 4 sin^{3}θ", part="(2)"),
                 fl("代入 sin θ = %s：" % t(s), "sin 3θ = 3 · %s − 4 · %s = [0]" % (t(s), t(s ** 3)), [a(s3)], "%s − %s" % (t(3 * s), t(4 * s ** 3)), part="(2)"),
                 ch("同樣的方法，4cos^{3}x − 3cos x 是？", ["cos 3x", "sin 3x", "cos^{3} x", "−cos 3x"],
                    "cos 3x = cos 2x cos x − sin 2x sin x，全部換成 cos x", "(3)　4cos^{3}x − 3cos x = cos 3x", part="(3)"),
                 fl("0 ≤ 3x ≤ 3π，cos 3x = %s 的角（由小到大）：" % k.text(), "3x = [0]π、[1]π、[2]π", [a(u) for u in us],
                    "cos(%s) = %s；再看 2π ± %s" % (pt_(al), k.text(), pt_(al)), part="(3)"),
                 fl("每個除以 3 再加起來：", "答：和 = [0]π", [a(S)], "(%s)/3" % " + ".join(pt_(u) for u in us), part="(3)")],
                plot={"x": [-0.3, 3.5], "y": [-1.4, 1.4], "pi": 9 if al.denominator == 3 else 12, "pi_lab": 3 if al.denominator == 3 else 4,
                      "curves": [{"f": "cos(3*x)", "c": "cyan", "dom": [0.0, 3.1416], "at": 3}, {"f": gf(float(k)), "c": "pink", "dash": True, "at": 3}],
                      "band": {"lo": 0.0, "hi": 3.1416, "at": 3}})


# ---------- tb_segment：弓形 ----------

def tb_segment(r, th):
    th = F(th)
    arc = r * th
    sec = F(r * r, 2) * th
    tri = Q(F(r * r, 2)) * sv(th)
    chord = Q(2 * r) * sv(th / 2)
    assert near(tri, 0.5 * r * r * sin(float(th) * PI)) and near(chord, 2 * r * sin(float(th) * PI / 2))
    tri_t = "[0] − [1]√%d" % tri.n if not tri.rat() else "[0] − [1]"
    tri_b = a(tri.b) if not tri.rat() else a(tri.a)
    ch_t = "[0]π + [1]√%d" % chord.n if not chord.rat() else "[0]π + [1]"
    ch_b = a(chord.b) if not chord.rat() else a(chord.a)
    deg_ = float(th) * 180
    a0, a1 = 90 - deg_ / 2, 90 + deg_ / 2
    A_ = (r * cos(math.radians(a0)), r * sin(math.radians(a0)))
    B_ = (r * cos(math.radians(a1)), r * sin(math.radians(a1)))
    return item("tb_segment", "boss", 2, "弓形草皮", 1.6,
                "半徑 %d 公尺的圓形廣場上，弦 \\ol{AB} 所對的圓心角是 %s。弦和劣弧 AB 圍成的弓形要鋪草皮、外圈圍上燈條。\n(1) 劣弧長　(2) 扇形 OAB 與 △OAB 的面積　(3) 弓形的面積與周長" % (r, pt_(th)),
                [fl("弧長 = 半徑 × 圓心角：", "(1)　弧長 = [0]π", [a(arc)], "%d × %s" % (r, pt_(th)), part="(1)"),
                 fl("扇形面積 = (1/2) r^{2} θ：", "(2)　扇形面積 = [0]π", [a(sec)], "(1/2) · %d · %s" % (r * r, pt_(th)), part="(2)"),
                 fl("△OAB 的面積 = (1/2) r^{2} sin θ：", "△OAB = (1/2) · %d · sin(%s) = [0]" % (r * r, pt_(th)), [tri.ans()], "sin(%s) = %s" % (pt_(th), sv(th).text()),
                    part="(2)"),
                 fl("弓形 = 扇形 − 三角形：", "(3)　弓形面積 = [0]π − %s" % tri.text() if False else "(3)　弓形面積 = " + tri_t.replace("[0]", "[0]π"),
                    [a(sec), tri_b], "%s − %s" % (pt_(sec), tri.text()), part="(3)"),
                 fl("弦長：從 O 作 \\ol{AB} 的垂線，切成兩個直角三角形，\\ol{AB} = 2r sin(θ/2)。", "\\ol{AB} = %d sin(%s) = [0]" % (2 * r, pt_(th / 2)), [chord.ans()],
                    "sin(%s) = %s" % (pt_(th / 2), sv(th / 2).text()), part="(3)"),
                 fl("周長 = 弧長 + 弦長：", "答：周長 = " + ch_t, [a(arc), ch_b], "%s + %s" % (pt_(arc), chord.text()), part="(3)")],
                plot={"x": [-r - 1.0, r + 1.0], "y": [-r - 1.0, r + 1.0], "geo": True, "h": 200,
                      "shapes": [{"k": "circle", "o": [0, 0], "r": r, "c": "dim"},
                                 {"k": "sector", "o": [0, 0], "r": r, "a0": fx(a0), "a1": fx(a1), "c": "lime", "fill": "lime", "alpha": 0.15, "at": 1},
                                 {"k": "poly", "pts": [[0, 0], [fx(A_[0]), fx(A_[1])], [fx(B_[0]), fx(B_[1])]], "c": "cyan", "fill": "cyan", "alpha": 0.12, "at": 2},
                                 {"k": "seg", "a": [fx(A_[0]), fx(A_[1])], "b": [fx(B_[0]), fx(B_[1])], "c": "gold", "w": 2.6},
                                 {"k": "angle", "o": [0, 0], "a0": fx(a0), "a1": fx(a1), "r": 16, "s": "θ"},
                                 {"k": "dot", "p": [fx(A_[0]), fx(A_[1])], "s": "A", "off": [8, -6]}, {"k": "dot", "p": [fx(B_[0]), fx(B_[1])], "s": "B", "off": [-18, -6]},
                                 {"k": "dot", "p": [0, 0], "s": "O", "off": [6, 14]}]})


# ---------- tb_clock：時鐘 ----------

def tb_clock(X, Lm=6, Lh=4):
    ang = F(X, 6)
    if ang > 1:
        ang = 2 - ang
    d2 = Lm * Lm + Lh * Lh - 2 * Lm * Lh * cv(ang)
    assert d2.rat()
    d2 = d2.a
    d = Q.sqrt(d2)
    rel = F(1, 30) - F(1, 360)
    tt = F(X, 6) / rel
    hx, hy = Lh * sin(float(F(X, 6)) * PI), Lh * cos(float(F(X, 6)) * PI)
    assert near(d, math.hypot(hx, hy - Lm))
    # 第一次重合：分針追上時針
    m = lambda t_: (t_ * PI / 30) % (2 * PI)
    h = lambda t_: (X * PI / 6 + t_ * PI / 360) % (2 * PI)
    assert near(m(float(tt)), h(float(tt)), 1e-9) or near(abs(m(float(tt)) - h(float(tt))), 2 * PI, 1e-9)
    deg_h = 90 - 30 * X
    return item("tb_clock", "boss", 2, "時鐘的兩根針", 1.6,
                "時鐘的分針長 %d 公分、時針長 %d 公分。\n(1) 分針、時針每分鐘各轉幾弧度？(2) %d 點整時，兩針尖端相距多遠？(3) %d 點整之後，再過幾分鐘兩針第一次重合？" % (Lm, Lh, X, X),
                [fl("分針 60 分鐘轉一圈，時針 12 小時（720 分鐘）轉一圈：", "(1)　分針 [0]π，時針 [1]π", ["1/30", "1/360"], "2π/60、2π/720", part="(1)"),
                 fl("%d 點整：分針指著 12，時針指著 %d，中間隔 %d 格（一格 π/6）：" % (X, X, min(X, 12 - X)), "(2)　夾角 = [0]π", [a(ang)], "%d × π/6" % min(X, 12 - X), part="(2)"),
                 fl("兩針和中心構成三角形，用餘弦定理：", "d^{2} = %d^{2} + %d^{2} − 2 · %d · %d · cos(%s) = [0]" % (Lm, Lh, Lm, Lh, pt_(ang)), [a(d2)],
                    "cos(%s) = %s" % (pt_(ang), cv(ang).text()), part="(2)"),
                 fl("開根號：", "d = √{%s} = [0] 公分" % t(d2), [d.ans()], ("%s = %d × %d" % (t(d2), int(d.b ** 2), d.n)) if d.n != 1 else "%s = %s^{2}" % (t(d2), t(d.a)),
                    part="(2)"),
                 fl("分針每分鐘比時針多轉：", "(3)　π/30 − π/360 = [0]π", [a(rel)], "12/360 − 1/360", part="(3)"),
                 fl("分針要追上時針領先的 %s：" % pt_(F(X, 6)), "答：%s ÷ (11π/360) = [0] 分鐘" % pt_(F(X, 6)), [a(tt)], "%s × 360/11" % t(F(X, 6)), part="(3)")],
                plot={"x": [-7.6, 7.6], "y": [-7.6, 7.6], "geo": True, "h": 200,
                      "shapes": [{"k": "circle", "o": [0, 0], "r": 7, "c": "dim"}] +
                                [{"k": "seg", "a": [fx(6.4 * sin(i * PI / 6)), fx(6.4 * cos(i * PI / 6))], "b": [fx(7 * sin(i * PI / 6)), fx(7 * cos(i * PI / 6))], "c": "faint"}
                                 for i in range(12)] +
                                [{"k": "seg", "a": [0, 0], "b": [0, Lm], "c": "cyan", "w": 2.6},
                                 {"k": "seg", "a": [0, 0], "b": [fx(hx), fx(hy)], "c": "pink", "w": 3.2},
                                 {"k": "angle", "o": [0, 0], "a0": fx(min(deg_h, 90) if X <= 6 else 90), "a1": fx(90 if X <= 6 else deg_h + 360), "r": 16, "s": "", "at": 1},
                                 {"k": "seg", "a": [0, Lm], "b": [fx(hx), fx(hy)], "c": "gold", "dash": True, "at": 2}]})


# ---------- tb_homog：齊次式 ----------

def pp_(x):
    """分數、負數加括號"""
    x = F(x)
    return "(" + t(x) + ")" if (x < 0 or not isint(x)) else t(x)


def tb_homog(k):
    k = F(k)
    v1 = (k + 1) / (k - 1)
    v2 = k / (1 + k * k)
    v3 = (1 - k * k) / (1 + k * k)
    v4 = (k + 1) / (1 - k)
    th = math.atan(float(k))
    assert near(v1, (sin(th) + cos(th)) / (sin(th) - cos(th))) and near(v2, sin(th) * cos(th)) and near(v3, cos(2 * th)) and near(v4, tan(th + PI / 4))
    return item("tb_homog", "boss", 2, "只給 tan", 1.6,
                "tan θ = %s。求\n(1) (sin θ + cos θ)/(sin θ − cos θ)　(2) sin θ cos θ 與 cos 2θ　(3) tan(θ + π/4)" % t(k),
                [ch("(1) 分子、分母都是 sin、cos 的一次式，同除以 cos θ：", ["(tan θ + 1)/(tan θ − 1)", "(tan θ − 1)/(tan θ + 1)", "(1 + tan θ)/(1 − tan θ)", "tan θ + 1"],
                    "sin θ/cos θ = tan θ，cos θ/cos θ = 1", "(1)　原式 = (tan θ + 1)/(tan θ − 1)", part="(1)"),
                 fl("代入 tan θ = %s：" % t(k), "(%s + 1)/(%s − 1) = [0]" % (t(k), t(k)), [a(v1)], "%s/%s" % (pp_(k + 1), pp_(k - 1)), part="(1)"),
                 fl("二次式：sin θ cos θ = sin θ cos θ/(sin^{2}θ + cos^{2}θ)，同除以 cos^{2}θ：", "(2)　sin θ cos θ = tan θ/(1 + tan^{2}θ) = [0]", [a(v2)],
                    "%s/(1 + %s)" % (pp_(k), t(k * k)), part="(2)"),
                 fl("同樣的方法：", "cos 2θ = (cos^{2}θ − sin^{2}θ)/(cos^{2}θ + sin^{2}θ) = (1 − tan^{2}θ)/(1 + tan^{2}θ) = [0]", [a(v3)],
                    "(1 − %s)/(1 + %s)" % (t(k * k), t(k * k)), part="(2)"),
                 fl("和角公式，tan(π/4) = 1：", "答：(3)　tan(θ + π/4) = (tan θ + 1)/(1 − tan θ) = [0]", [a(v4)], "%s/%s" % (pp_(k + 1), pp_(1 - k)), part="(3)")])


# ---------- tb_rect：扇形裡的矩形 ----------

def tb_rect(R):
    """扇形 OAB，半徑 R、圓心角 π/3；P 在弧上，∠POA = θ，矩形 PQRS 的 \\ol{QR} 在 \\ol{OA} 上、S 在 \\ol{OB} 上"""
    w2 = Q(0, F(R, 3), 3)                        # 寬 = R cos θ − (R√3/3) sin θ
    A2 = F(R * R, 2)                             # sin 2θ 的係數
    B2 = Q(0, F(R * R, 6), 3)                    # cos 2θ 的係數（= 常數項）
    r = Q.sqrt(F(R ** 4, 4) + F(R ** 4, 12))
    assert near(r, float(Q(0, F(R * R, 3), 3)))
    r = Q(0, F(R * R, 3), 3)
    assert A2 == r * cv(F(1, 6)) and B2 == r * sv(F(1, 6))
    mx = r - B2
    area = lambda th: R * sin(th) * (R * cos(th) - R * sin(th) / S3)
    _, amax = ext(area, 0, PI / 3)
    assert near(amax, mx, 1e-6)
    th = PI / 6
    P = (R * cos(th), R * sin(th))
    Sx = P[1] / S3
    return item("tb_rect", "boss", 3, "扇形裡的矩形", 1.65,
                "扇形 OAB 的半徑 %d、圓心角 π/3。P 在弧上，∠POA = θ；矩形 PQRS 的一邊 \\ol{QR} 在 \\ol{OA} 上，頂點 S 在 \\ol{OB} 上。\n(1) 把矩形面積寫成 θ 的式子　(2) θ 是多少時面積最大？最大面積是多少？" % R,
                [fl("P 的高 = %d sin θ。S 和 P 一樣高，S 在 \\ol{OB} 上，橫坐標 = 高/tan(π/3)：" % R, "(1)　寬 = %d cos θ − [0] sin θ" % R, [w2.ans()],
                    "%d/√{3} = %s" % (R, w2.text()), part="(1)"),
                 fl("面積 = 高 × 寬，再用二倍角降次：", "面積 = [0] sin 2θ + %s cos 2θ − %s" % (B2.text(), B2.text()), [a(A2)],
                    "%d^{2} sin θ cos θ = (%d/2) sin 2θ，sin^{2}θ = (1 − cos 2θ)/2" % (R, R * R), part="(1)"),
                 fl("前兩項疊合：", "%s sin 2θ + %s cos 2θ = [0] sin(2θ + [1]π)" % (t(A2), B2.text()), [r.ans(), "1/6"],
                    "√{%s + %s} = %s" % (t(A2 * A2), t((B2 * B2).a), r.text()), part="(1)"),
                 fl("0 < θ < π/3 ⇒ π/6 < 2θ + π/6 < 5π/6，sin 可以取到 1：", "(2)　2θ + π/6 = π/2 ⇒ θ = [0]π", ["1/6"], "2θ = π/3", part="(2)"),
                 fl("最大面積：", "答：%s − %s = [0]" % (r.text(), B2.text()), [mx.ans()], "%s − %s" % (r.text(), B2.text()), part="(2)")],
                plot={"x": [-0.6, R + 0.6], "y": [-0.6, fx(R * S3 / 2 + 0.6)], "geo": True, "h": 190,
                      "shapes": [{"k": "sector", "o": [0, 0], "r": R, "a0": 0, "a1": 60, "c": "cyan", "fill": "cyan", "alpha": 0.08},
                                 {"k": "poly", "pts": [[fx(Sx), 0], [fx(P[0]), 0], [fx(P[0]), fx(P[1])], [fx(Sx), fx(P[1])]], "c": "gold", "fill": "gold", "alpha": 0.15},
                                 {"k": "seg", "a": [0, 0], "b": [fx(P[0]), fx(P[1])], "c": "faint", "dash": True},
                                 {"k": "angle", "o": [0, 0], "a0": 0, "a1": 30, "r": 26, "s": "θ"},
                                 {"k": "dot", "p": [fx(P[0]), fx(P[1])], "s": "P", "off": [8, -6]}, {"k": "label", "p": [fx(Sx - 0.35), fx(P[1] + 0.3)], "s": "S"},
                                 {"k": "label", "p": [fx(P[0]), -0.4], "s": "Q"}, {"k": "label", "p": [fx(Sx), -0.4], "s": "R"},
                                 {"k": "label", "p": [-0.3, -0.3], "s": "O"}, {"k": "label", "p": [R + 0.3, -0.3], "s": "A"},
                                 {"k": "label", "p": [fx(R / 2 - 0.2), fx(R * S3 / 2 + 0.3)], "s": "B"}]})


def tb_rect_semi(R):
    """半圓裡的矩形：周長 4R cos θ + 2R sin θ 疊合求最大（tan θ = 1/2），再求那時的面積"""
    P = lambda th: 4 * R * cos(th) + 2 * R * sin(th)
    _, mx = ext(P, 0, PI / 2)
    assert near(mx, 2 * R * math.sqrt(5), 1e-6)
    th = math.atan(0.5)
    area = F(4 * R * R, 5)
    assert near(area, 2 * R * cos(th) * R * sin(th))
    Cx, Cy = R * cos(th), R * sin(th)
    return item("tb_rect", "boss", 3, "扇形裡的矩形", 1.65,
                "半徑 %d 的半圓，矩形 ABCD 的 A、B 在直徑上，C、D 在半圓上，O 是圓心，∠COB = θ（0 < θ < π/2）。\n(1) 用 θ 表示 \\ol{AB}、\\ol{BC}　(2) 矩形周長的最大值　(3) 周長最大時，矩形的面積" % R,
                [fl("C 的坐標是 (%d cos θ, %d sin θ)，矩形左右對稱：" % (R, R), "(1)　\\ol{AB} = [0] cos θ，\\ol{BC} = [1] sin θ", [str(2 * R), str(R)],
                    "\\ol{OB} = %d cos θ，\\ol{AB} = 2\\ol{OB}" % R, part="(1)"),
                 fl("周長 = 2(\\ol{AB} + \\ol{BC})：", "(2)　周長 = [0] cos θ + [1] sin θ", [str(4 * R), str(2 * R)], "2 × %d、2 × %d" % (2 * R, R), part="(2)"),
                 fl("提出 %d 再疊合：%d(2 cos θ + sin θ)。" % (2 * R, 2 * R), "周長最長 = [0]√5", [str(2 * R)], "%d √{2^{2} + 1^{2}}" % (2 * R), part="(2)"),
                 fl("最長時 cos θ : sin θ = 2 : 1（和係數成比例）：", "(3)　tan θ = [0]", ["1/2"], "sin θ/cos θ", part="(3)"),
                 fl("sin θ = √{5}/5、cos θ = 2√{5}/5：", "答：面積 = \\ol{AB} · \\ol{BC} = [0]", [a(area)], "%d cos θ × %d sin θ" % (2 * R, R), part="(3)")],
                plot={"x": [-R - 0.6, R + 0.6], "y": [-0.6, R + 0.6], "geo": True, "h": 160,
                      "shapes": [{"k": "sector", "o": [0, 0], "r": R, "a0": 0, "a1": 180, "c": "cyan", "fill": "cyan", "alpha": 0.08},
                                 {"k": "seg", "a": [-R, 0], "b": [R, 0], "c": "cyan"},
                                 {"k": "poly", "pts": [[fx(-Cx), 0], [fx(Cx), 0], [fx(Cx), fx(Cy)], [fx(-Cx), fx(Cy)]], "c": "gold", "fill": "gold", "alpha": 0.15},
                                 {"k": "seg", "a": [0, 0], "b": [fx(Cx), fx(Cy)], "c": "faint", "dash": True},
                                 {"k": "angle", "o": [0, 0], "a0": 0, "a1": fx(math.degrees(th)), "r": 26, "s": "θ"},
                                 {"k": "label", "p": [fx(-Cx), -0.4], "s": "A"}, {"k": "label", "p": [fx(Cx), -0.4], "s": "B"},
                                 {"k": "dot", "p": [fx(Cx), fx(Cy)], "s": "C", "off": [8, -6]}, {"k": "label", "p": [fx(-Cx - 0.35), fx(Cy + 0.3)], "s": "D"},
                                 {"k": "label", "p": [0, -0.4], "s": "O"}]})


def tb_rect_quarter(R):
    """四分之一圓裡、一個頂點在圓心的矩形：面積用二倍角、周長用疊合，最大都在 θ = π/4"""
    Ar = lambda th: R * cos(th) * R * sin(th)
    Pr = lambda th: 2 * R * (cos(th) + sin(th))
    _, amax = ext(Ar, 0, PI / 2)
    _, pmax = ext(Pr, 0, PI / 2)
    pm = Q(0, 2 * R, 2)
    assert near(amax, F(R * R, 2), 1e-6) and near(pmax, pm, 1e-6)
    th = PI / 4
    Px, Py = R * cos(th), R * sin(th)
    return item("tb_rect", "boss", 3, "扇形裡的矩形", 1.65,
                "半徑 %d 的四分之一圓 OAB（∠AOB = π/2），P 在弧上，∠POA = θ。矩形 OQPS 的 Q 在 \\ol{OA} 上、S 在 \\ol{OB} 上。\n(1) 用 θ 表示矩形的面積　(2) 面積的最大值與此時的 θ　(3) 矩形周長的最大值" % R,
                [fl("直角 △OQP：\\ol{OP} = %d 是斜邊。" % R, "(1)　\\ol{OQ} = [0] cos θ，\\ol{OS} = \\ol{QP} = [1] sin θ", [str(R), str(R)], "鄰邊、對邊", part="(1)"),
                 fl("面積 = \\ol{OQ} · \\ol{OS}，用二倍角：", "面積 = [0] sin θ cos θ = [1] sin 2θ", [str(R * R), a(F(R * R, 2))], "sin θ cos θ = (1/2) sin 2θ", part="(1)"),
                 fl("0 < 2θ < π，sin 2θ 最大是 1：", "(2)　面積最大 [0]，此時 θ = [1]π", [a(F(R * R, 2)), "1/4"], "2θ = π/2", part="(2)"),
                 fl("周長 = %d(cos θ + sin θ)，疊合：" % (2 * R), "(3)　周長 = [0] sin(θ + [1]π)", [pm.ans(), "1/4"],
                    "%d √{2}，cos(π/4) = √{2}/2" % (2 * R), part="(3)"),
                 fl("π/4 < θ + π/4 < 3π/4，sin 可以取到 1：", "答：周長最長 [0]", [pm.ans()], "θ + π/4 = π/2", part="(3)")],
                plot={"x": [-0.6, R + 0.6], "y": [-0.6, R + 0.6], "geo": True, "h": 180,
                      "shapes": [{"k": "sector", "o": [0, 0], "r": R, "a0": 0, "a1": 90, "c": "cyan", "fill": "cyan", "alpha": 0.08},
                                 {"k": "poly", "pts": [[0, 0], [fx(Px), 0], [fx(Px), fx(Py)], [0, fx(Py)]], "c": "gold", "fill": "gold", "alpha": 0.15},
                                 {"k": "seg", "a": [0, 0], "b": [fx(Px), fx(Py)], "c": "faint", "dash": True},
                                 {"k": "angle", "o": [0, 0], "a0": 0, "a1": 45, "r": 26, "s": "θ"},
                                 {"k": "dot", "p": [fx(Px), fx(Py)], "s": "P", "off": [8, -6]}, {"k": "label", "p": [fx(Px), -0.4], "s": "Q"},
                                 {"k": "label", "p": [-0.35, fx(Py)], "s": "S"}, {"k": "label", "p": [-0.3, -0.3], "s": "O"},
                                 {"k": "label", "p": [R + 0.3, -0.3], "s": "A"}, {"k": "label", "p": [-0.3, R + 0.3], "s": "B"}]})


# ---------- tb_sides：兩邊和的範圍 ----------

def tb_sides(C, c):
    C, c = F(C), Q.of(c)
    D2 = c / sv(C)                               # 2R
    Bs = 1 - C                                   # B = (1 − C)π − A
    # sin B = sin(Bs π − A) = sin(Bsπ) cos A − cos(Bsπ) sin A
    ka = D2 * (1 - cv(Bs))                        # sin A 的係數
    kc = D2 * sv(Bs)                              # cos A 的係數
    r = Q.sqrt((ka * ka + kc * kc).a)
    ph = None
    for d in (F(1, 6), F(1, 4), F(1, 3)):
        if ka == r * cv(d) and kc == r * sv(d):
            ph = d
    assert ph is not None
    u0, u1 = ph, Bs + ph
    lo = r * sv(u0)
    assert near(lo, r * sv(u1)) and u0 < F(1, 2) < u1
    f = lambda A: float(D2) * (sin(A) + sin(float(Bs) * PI - A))
    mn, mx = ext(f, 1e-6, float(Bs) * PI - 1e-6)
    assert near(mx, r, 1e-6) and near(mn, lo, 1e-3)
    Rr = float(D2) / 2
    Ad = 90 + float(C) * 180
    Bd = 90 - float(C) * 180
    pa = [fx(Rr * cos(math.radians(270 - float(C) * 180))), fx(Rr * sin(math.radians(270 - float(C) * 180)))]
    pb = [fx(Rr * cos(math.radians(270 + float(C) * 180))), fx(Rr * sin(math.radians(270 + float(C) * 180)))]
    return item("tb_sides", "boss", 3, "兩邊和的範圍", 1.65,
                "△ABC 中，C = %s，c = %s。\n(1) 求外接圓的直徑 2R　(2) 把 a + b 寫成 r sin(A + φ)　(3) 求 a + b 的範圍" % (pt_(C), c.text()),
                [fl("正弦定理：", "(1)　2R = c/sin C = [0]", [D2.ans()], "%s ÷ %s" % (c.text(), sv(C).text()), part="(1)"),
                 fl("a = 2R sin A、b = 2R sin B，B = %s − A，展開 sin(%s − A)：" % (pt_(Bs), pt_(Bs)),
                    "(2)　a + b = [0] sin A + [1] cos A", [ka.ans(), kc.ans()],
                    "sin(%s − A) = %s cos A %s %s sin A" % (pt_(Bs), sv(Bs).text(), "−" if cv(Bs) > 0 else "+", (cv(Bs) if cv(Bs) > 0 else -cv(Bs)).text()), part="(2)"),
                 fl("疊合：", "a + b = [0] sin(A + [1]π)", [r.ans(), a(ph)], "√{%s + %s} = %s" % (t((ka * ka).a), t((kc * kc).a), r.text()), part="(2)"),
                 fl("0 < A < %s ⇒ %s < A + %s < %s：" % (pt_(Bs), pt_(u0), pt_(ph), pt_(u1)), "答：(3)　[0] < a + b ≤ [1]", [lo.ans(), r.ans()],
                    "兩端取不到：%s sin(%s) = %s；中間 A + %s = π/2 取到最大 %s" % (r.text(), pt_(u0), lo.text(), pt_(ph), r.text()), part="(3)")],
                plot={"x": [fx(-Rr - 0.8), fx(Rr + 0.8)], "y": [fx(-Rr - 0.8), fx(Rr + 0.8)], "geo": True, "h": 200,
                      "shapes": [{"k": "circle", "o": [0, 0], "r": fx(Rr), "c": "dim"},
                                 {"k": "seg", "a": pa, "b": pb, "c": "gold", "w": 2.6},
                                 {"k": "poly", "pts": [pa, pb, [0, fx(Rr)]], "c": "cyan", "until": 1},
                                 {"k": "poly", "pts": [pa, pb, [fx(Rr * cos(math.radians(130))), fx(Rr * sin(math.radians(130)))]], "c": "pink", "dash": True, "at": 1}
                                 if C < F(1, 2) else {"k": "poly", "pts": [pa, pb, [fx(Rr * cos(math.radians(105))), fx(Rr * sin(math.radians(105)))]], "c": "pink", "dash": True, "at": 1},
                                 {"k": "label", "p": [fx(pa[0] * 1.15), fx(pa[1] * 1.15)], "s": "A"}, {"k": "label", "p": [fx(pb[0] * 1.15), fx(pb[1] * 1.15)], "s": "B"},
                                 {"k": "label", "p": [0, fx(Rr * 1.12)], "s": "C", "until": 1},
                                 {"k": "label", "p": [0, fx(pa[1] - 0.6)], "s": "c"}]})


def items():
    return [
        [tb_triple(F(1, 3), F(1, 2)), tb_triple(F(1, 4), F(-1, 2)), tb_triple(F(2, 5), Q(0, F(1, 2), 2))],
        [tb_segment(6, F(2, 3)), tb_segment(4, F(1, 2)), tb_segment(6, F(1, 3))],
        [tb_clock(2), tb_clock(3), tb_clock(4)],
        [tb_homog(2), tb_homog(3), tb_homog(F(1, 2))],
        [tb_rect(6), tb_rect_semi(5), tb_rect_quarter(4)],
        [tb_sides(F(1, 3), Q(0, 2, 3)), tb_sides(F(1, 3), 3), tb_sides(F(2, 3), 3)],
    ]
