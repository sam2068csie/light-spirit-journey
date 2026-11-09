# 試煉大題（原本的 6 題）
from tlib import *

sin, cos, tan = math.sin, math.cos, math.tan


def gf(k):
    return repr(float(k))


# ---------- tb_gun：兩座砲台 ----------

def tb_gun(h, s, AQ):
    """\\ol{AB} = 2h，\\ol{PA} = \\ol{PB} = s，A 再向西偏北 θ/2 打 AQ"""
    AB = 2 * h
    ct = F(h, s)
    half2 = (1 + ct) / 2
    ch_ = Q.sqrt(half2)
    assert ch_.rat()
    ch_ = ch_.a
    X = 2 * AB * AQ * ch_
    BQ2 = AB * AB + AQ * AQ - X
    assert isint(X) and BQ2 > 0
    BQ = Q.sqrt(BQ2)
    th = math.acos(float(ct))
    Py = math.sqrt(s * s - h * h)
    Q_ = (AB - AQ * cos(th / 2), AQ * sin(th / 2))
    assert near(math.hypot(*Q_), BQ)
    pad = 0.12 * max(AB, Py)
    return item("tb_gun", "boss", 2, "兩座砲台", 1.65,
                "砲台 A 在砲台 B 的正東方 %d 公里。A 向西偏北 θ、B 向東偏北 θ 發射，同時命中離兩砲台都是 %d 公里的目標 P。接著 A 改向西偏北 θ/2 發射，落在 %d 公里外的 Q 點。\n(1) 求 cos θ　(2) 求 cos(θ/2)　(3) 求 \\ol{BQ}"
                % (AB, s, AQ),
                [fl("\\ol{PA} = \\ol{PB}：P 往 \\ol{AB} 的垂線落在中點，切出直角三角形（鄰邊 %d、斜邊 %d）。" % (h, s), "(1)　cos θ = [0]", [a(ct)],
                    "cos = 鄰邊/斜邊", part="(1)"),
                 fl("θ 是銳角，半角公式 cos(θ/2) = √{(1 + cos θ)/2}，先算根號裡面：", "(2)　(1 + cos θ)/2 = (%s)/2 = [0]" % t(1 + ct), [a(half2)],
                    "1 + %s = %s" % (t(ct), t(1 + ct)), part="(2)"),
                 fl("開根號：", "cos(θ/2) = √{%s} = [0]" % t(half2), [a(ch_)], "%d、%d 都是平方數" % (half2.numerator, half2.denominator), part="(2)"),
                 fl("△ABQ 中 \\ol{AB} = %d、\\ol{AQ} = %d、∠BAQ = θ/2。餘弦定理的最後一項：" % (AB, AQ), "(3)　2 · %d · %d · cos(θ/2) = [0]" % (AB, AQ), [a(X)],
                    "%d × %s" % (2 * AB * AQ, t(ch_)), part="(3)"),
                 fl("代進餘弦定理：", "\\ol{BQ}^{2} = %d^{2} + %d^{2} − %s = [0]" % (AB, AQ, t(X)), [a(BQ2)], "%d + %d − %s" % (AB * AB, AQ * AQ, t(X)), part="(3)"),
                 fl("開根號：", "答：\\ol{BQ} = √{%s} = [0]" % t(BQ2), [BQ.ans()],
                    ("%s = %d × %d" % (t(BQ2), int(BQ.b ** 2), BQ.n)) if BQ.n != 1 else "%s = %s^{2}" % (t(BQ2), t(BQ.a)), part="(3)")],
                plot={"x": [fx(-pad), fx(AB + pad)], "y": [fx(-pad), fx(Py + pad)], "geo": True, "h": 210,
                      "shapes": [{"k": "seg", "a": [0, 0], "b": [AB, 0], "c": "dim"}, {"k": "seg", "a": [0, 0], "b": [h, fx(Py)], "c": "cyan"},
                                 {"k": "seg", "a": [AB, 0], "b": [h, fx(Py)], "c": "cyan"},
                                 {"k": "seg", "a": [h, fx(Py)], "b": [h, 0], "c": "faint", "dash": True},
                                 {"k": "angle", "o": [AB, 0], "a0": fx(180 - math.degrees(th)), "a1": 180, "r": 26, "s": "θ"},
                                 {"k": "angle", "o": [0, 0], "a0": 0, "a1": fx(math.degrees(th)), "r": 22, "s": "θ"},
                                 {"k": "seg", "a": [AB, 0], "b": [fx(Q_[0]), fx(Q_[1])], "c": "pink", "dash": True, "at": 1},
                                 {"k": "seg", "a": [0, 0], "b": [fx(Q_[0]), fx(Q_[1])], "c": "gold", "w": 2.6, "at": 3},
                                 {"k": "label", "p": [fx(-pad * 0.4), fx(-pad * 0.6)], "s": "B"}, {"k": "label", "p": [fx(AB + pad * 0.4), fx(-pad * 0.6)], "s": "A"},
                                 {"k": "label", "p": [h, fx(Py + pad * 0.6)], "s": "P"}, {"k": "label", "p": [h, fx(-pad * 0.6)], "s": str(h)},
                                 {"k": "dot", "p": [fx(Q_[0]), fx(Q_[1])], "s": "Q", "off": [-18, -6], "at": 1}]})


# ---------- tb_path：「工」字步道 ----------

def tb_path(R):
    c1, c2 = 4 * R, 2 * R
    Lmax = Q(0, 2 * R, 5)
    ct = Q(0, F(1, 5), 5)
    MN = c2 * ct
    L = lambda th: c1 * sin(th) + c2 * cos(th)
    mn, mx = ext(L, 0, PI / 2)
    assert near(mx, Lmax, 1e-6)
    th = math.atan(2)
    s = 20.0 / R
    Ax, Ay = R * sin(th) * s, R * cos(th) * s
    return item("tb_path", "boss", 3, "池塘步道", 1.65,
                "半徑 %d 公尺的圓形池塘裡修「工」字步道：上下兩條等長且平行的弦 \\ol{AB}、\\ol{CD}，加上連接兩弦中點 M、N 的步道（經過圓心 O）。設 ∠AOM = θ（0 < θ < π/2）。\n(1) 把總長 L 用 θ 表示　(2) L 最長多少？(3) 此時 \\ol{MN} 多長？" % R,
                [fl("\\ol{AB} = 2\\ol{AM}，\\ol{MN} = 2\\ol{OM}：", "L = 2\\ol{AB} + \\ol{MN} = [0] sin θ + [1] cos θ", [str(c1), str(c2)],
                    "\\ol{AB} = 2\\ol{AM}，\\ol{MN} = 2\\ol{OM}", part="(1)", pre="(1)　直角 △AOM：\\ol{AM} = %d sin θ、\\ol{OM} = %d cos θ" % (R, R)),
                 fl("提出 %d 再疊合：" % c2, "(2)　L = %d(2 sin θ + cos θ)，最長 [0] 公尺" % c2, [Lmax.ans()], "%d √{2^{2} + 1^{2}}" % c2, part="(2)"),
                 fl("最長時 sin θ : cos θ = 2 : 1（和係數成比例）：", "(3)　tan θ = [0]，cos θ = [1]", ["2", ct.ans()], "斜邊 √{5}", part="(3)"),
                 fl("\\ol{MN} = %d cos θ：" % c2, "答：\\ol{MN} = [0] 公尺", [MN.ans()], "%d · √{5}/5" % c2, part="(3)")],
                plot={"x": [-21.5, 21.5], "y": [-21.5, 21.5], "geo": True, "h": 200,
                      "shapes": [{"k": "circle", "o": [0, 0], "r": 20, "c": "dim"},
                                 {"k": "seg", "a": [fx(-Ax), fx(Ay)], "b": [fx(Ax), fx(Ay)], "c": "cyan", "w": 2.6},
                                 {"k": "seg", "a": [fx(-Ax), fx(-Ay)], "b": [fx(Ax), fx(-Ay)], "c": "cyan", "w": 2.6},
                                 {"k": "seg", "a": [0, fx(Ay)], "b": [0, fx(-Ay)], "c": "cyan", "w": 2.6},
                                 {"k": "seg", "a": [0, 0], "b": [fx(-Ax), fx(Ay)], "c": "faint", "dash": True},
                                 {"k": "angle", "o": [0, 0], "a0": 90, "a1": fx(90 + math.degrees(th)), "r": 18, "s": "θ"},
                                 {"k": "label", "p": [fx(-Ax - 1.4), fx(Ay + 1.9)], "s": "A"}, {"k": "label", "p": [fx(Ax + 1.4), fx(Ay + 1.9)], "s": "B"},
                                 {"k": "label", "p": [fx(-Ax - 1.4), fx(-Ay - 2.1)], "s": "C"}, {"k": "label", "p": [fx(Ax + 1.4), fx(-Ay - 2.1)], "s": "D"},
                                 {"k": "label", "p": [2.6, fx(Ay + 2.1)], "s": "M"}, {"k": "label", "p": [2.6, fx(-Ay - 2.3)], "s": "N"},
                                 {"k": "label", "p": [2.8, -1.6], "s": "O"}]})


def tb_path_T(R):
    """「T」字：弦 AB ＋ 從中點 M 經過 O 到最低點 N；L = 2R sin θ + R cos θ + R"""
    L = lambda th: 2 * R * sin(th) + R * cos(th) + R
    _, mx = ext(L, 0, PI / 2)
    assert near(mx, R * math.sqrt(5) + R, 1e-6)
    MNb = Q(0, F(R, 5), 5)                       # R cos θ 的部分（cos θ = √5/5）
    assert near(float(MNb) + R, R / math.sqrt(5) + R)
    th = math.atan(2)
    Ax, Ay = 20 * sin(th), 20 * cos(th)
    return item("tb_path", "boss", 3, "池塘步道", 1.65,
                "半徑 %d 公尺的圓形池塘裡修「T」字步道：一條弦 \\ol{AB}，加上從 \\ol{AB} 的中點 M 經過圓心 O、一直走到池塘最低點 N 的步道。設 ∠AOM = θ（0 < θ < π/2）。\n(1) 把總長 L 用 θ 表示　(2) L 最長多少？(3) 此時 \\ol{MN} 多長？" % R,
                [fl("\\ol{AB} = 2\\ol{AM}，\\ol{MN} = \\ol{OM} + \\ol{ON}：", "L = [0] sin θ + [1] cos θ + [2]", [str(2 * R), str(R), str(R)],
                    "\\ol{ON} 是半徑 %d" % R, part="(1)", pre="(1)　直角 △AOM：\\ol{AM} = %d sin θ、\\ol{OM} = %d cos θ" % (R, R)),
                 fl("前兩項提出 %d 再疊合：" % R, "(2)　L = %d(2 sin θ + cos θ) + %d，最長 [0]√5 + [1] 公尺" % (R, R), [str(R), str(R)],
                    "%d √{2^{2} + 1^{2}} + %d" % (R, R), part="(2)"),
                 fl("最長時 sin θ : cos θ = 2 : 1（和係數成比例）：", "(3)　tan θ = [0]，cos θ = [1]", ["2", Q(0, F(1, 5), 5).ans()], "斜邊 √{5}", part="(3)"),
                 fl("\\ol{MN} = %d cos θ + %d：" % (R, R), "答：\\ol{MN} = [0]√5 + [1] 公尺", [a(MNb.b), str(R)], "%d · √{5}/5" % R, part="(3)")],
                plot={"x": [-21.5, 21.5], "y": [-21.5, 21.5], "geo": True, "h": 200,
                      "shapes": [{"k": "circle", "o": [0, 0], "r": 20, "c": "dim"},
                                 {"k": "seg", "a": [fx(-Ax), fx(Ay)], "b": [fx(Ax), fx(Ay)], "c": "cyan", "w": 2.6},
                                 {"k": "seg", "a": [0, fx(Ay)], "b": [0, -20], "c": "cyan", "w": 2.6},
                                 {"k": "seg", "a": [0, 0], "b": [fx(-Ax), fx(Ay)], "c": "faint", "dash": True},
                                 {"k": "angle", "o": [0, 0], "a0": 90, "a1": fx(90 + math.degrees(th)), "r": 18, "s": "θ"},
                                 {"k": "label", "p": [fx(-Ax - 1.4), fx(Ay + 1.9)], "s": "A"}, {"k": "label", "p": [fx(Ax + 1.4), fx(Ay + 1.9)], "s": "B"},
                                 {"k": "label", "p": [2.6, fx(Ay + 2.1)], "s": "M"}, {"k": "label", "p": [2.6, -22.3], "s": "N"},
                                 {"k": "label", "p": [2.8, -1.6], "s": "O"}]})


def tb_path_Y(R):
    """「Y」字：A、B 是水平直徑的兩端，J 在 O 正下方，\\ol{JA}、\\ol{JB}、\\ol{JS}（S 是最低點）；∠JAO = θ
       L = 2R/cos θ + R − R tan θ = R + R(2 − sin θ)/cos θ，最短在 sin θ = 1/2"""
    L = lambda th: 2 * R / cos(th) + R - R * tan(th)
    mn, _ = ext(L, 0, PI / 4)
    assert near(mn, R + R * S3, 1e-6) and near(L(PI / 6), R + R * S3)
    th = PI / 6
    Jy = -20 * tan(th)
    return item("tb_path", "boss", 3, "池塘步道", 1.65,
                "半徑 %d 公尺的圓形池塘，A、B 是一條水平直徑的兩端，S 是池塘最低點。要修「Y」字步道：在半徑 \\ol{OS} 上選一點 J，修 \\ol{JA}、\\ol{JB}、\\ol{JS} 三段。設 ∠JAO = θ（0 ≤ θ < π/4）。\n(1) 把總長 L 用 θ 表示　(2) L 最短多少？(3) 此時 θ 是多少？" % R,
                [fl("直角 △JOA：\\ol{OA} = %d 是鄰邊。" % R, "(1)　\\ol{JA} = [0]/cos θ，\\ol{JS} = [1] − %d tan θ" % R, [str(R), str(R)],
                    "\\ol{OJ} = %d tan θ，\\ol{JS} = \\ol{OS} − \\ol{OJ}" % R, part="(1)"),
                 ch("L = 2\\ol{JA} + \\ol{JS}，通分：", ["L = %d + %d(2 − sin θ)/cos θ" % (R, R), "L = %d + %d(2 + sin θ)/cos θ" % (R, R),
                                                       "L = %d(2 − sin θ)/cos θ" % R, "L = %d + %d(1 − sin θ)/cos θ" % (R, R)],
                    "−%d tan θ = −%d sin θ/cos θ，和 %d/cos θ 合起來" % (R, R, 2 * R), "L = %d + %d k，k = (2 − sin θ)/cos θ" % (R, R), part="(1)"),
                 ch("k = (2 − sin θ)/cos θ ⇒ k cos θ + sin θ = 2。這個方程式有解的條件：", ["k^{2} + 1 ≥ 4", "k + 1 ≥ 2", "k^{2} + 1 ≤ 4", "k ≥ 2"],
                    "a cos θ + b sin θ 的範圍是 ±√{a^{2} + b^{2}}", "(2)　√{k^{2} + 1} ≥ 2 ⇒ k ≥ √{3}（k > 0）", part="(2)"),
                 fl("k 最小 √{3}：", "L 最短 = [0] + [1]√3 公尺", [str(R), str(R)], "%d + %d · √{3}" % (R, R), part="(2)"),
                 fl("等號成立時 √{3} cos θ + sin θ = 2，疊合成 2 sin(θ + π/3) = 2：", "答：(3)　θ = [0]π", ["1/6"], "θ + π/3 = π/2", part="(3)")],
                plot={"x": [-21.5, 21.5], "y": [-21.5, 21.5], "geo": True, "h": 200,
                      "shapes": [{"k": "circle", "o": [0, 0], "r": 20, "c": "dim"},
                                 {"k": "seg", "a": [-20, 0], "b": [20, 0], "c": "faint", "dash": True},
                                 {"k": "seg", "a": [-20, 0], "b": [0, fx(Jy)], "c": "cyan", "w": 2.6},
                                 {"k": "seg", "a": [20, 0], "b": [0, fx(Jy)], "c": "cyan", "w": 2.6},
                                 {"k": "seg", "a": [0, fx(Jy)], "b": [0, -20], "c": "cyan", "w": 2.6},
                                 {"k": "angle", "o": [-20, 0], "a0": fx(-math.degrees(th)), "a1": 0, "r": 24, "s": "θ"},
                                 {"k": "label", "p": [-21.0, 2.0], "s": "A"}, {"k": "label", "p": [21.0, 2.0], "s": "B"},
                                 {"k": "label", "p": [2.4, -22.3], "s": "S"}, {"k": "label", "p": [2.6, fx(Jy - 1.2)], "s": "J"},
                                 {"k": "label", "p": [1.6, 1.8], "s": "O"}]})


# ---------- tb_coin：滾動的圓盤 ----------

COIN_PT = {"B": (0, F(1), "B 從中線往下：y = %d − %d sin(x/%d)", "sin(θ + π) = −sin θ"),
           "D": (1, F(0), "D 從中線往上：y = %d + %d sin(x/%d)", "本來就是 sin(x/%d) 的樣子"),
           "C": (F(1, 2), F(1, 2), "C 從最高點往下：y = %d + %d cos(x/%d)", "cos θ = sin(θ + π/2)")}


def tb_coin(R, P, x2):
    """P：B（右）、D（左）、C（上）；滾 x 之後 P 離地 = R sin(x/R + c) + R"""
    phi0, c, pre_t, c_hint = COIN_PT[P]
    phi0 = F(phi0)
    assert (F(1) - phi0) % 2 == c % 2 or True
    x2 = F(x2)
    y = lambda x: R + R * sin(float(phi0) * PI - x / R)
    yf = lambda x: R * sin(x / R + float(c) * PI) + R
    assert all(near(y(x), yf(x)) for x in (0.3, 2.1, 7.7))
    u2 = x2 / R + c
    y2 = R * sv(u2) + R
    assert near(y2, y(float(x2) * PI))
    xt = (F(3, 2) - c) * R
    while xt <= 0:
        xt += 2 * R
    assert near(y(float(xt) * PI), 0) and all(y(float(xt) * PI * i / 50) > 1e-9 for i in range(1, 50))
    pos = {"B": [R, 0], "D": [-R, 0], "C": [0, R]}[P]
    pre = pre_t % ((R, R, R) if P != "D" else (R, R, R))
    ct = "y = %d sin(x/%d + c) + %d ⇒ c = [0]π" % (R, R, R) if c != 0 else "y = %d sin(x/%d + c) + %d ⇒ c = [0]" % (R, R, R)
    return item("tb_coin", "boss", 2, "滾動的圓盤", 1.6,
                "半徑 %d 的圓盤內接正方形 ABCD（A、B、C、D 依逆時針排列），一開始 A 碰著地面、B 在圓心正右方。圓盤沿地面向右滾動（不打滑），滾了 x 之後 %s 離地 y = a sin(bx + c) + d（a、b > 0，0 ≤ c < 2π）。\n(1) 求 a、b、c、d　(2) 滾了 %s 時 %s 離地多高？(3) 滾了多遠 %s 第一次碰到地面？"
                % (R, P, pt_(x2), P, P),
                [fl("%s 繞著圓心轉，圓心離地 %d：" % (P, R), "(1)　a = [0]，d = [1]", [str(R), str(R)], "半徑、圓心高度", part="(1)"),
                 fl("滾 x 就順時針轉 x/%d（弧長 = 半徑 × 弧度）：" % R, "b = [0]", [a(F(1, R))], "轉過的角 = x/%d" % R, part="(1)"),
                 fl("把它寫成 sin(x/%d + c)：" % R, ct, [a(c)], c_hint % R if "%d" in c_hint else c_hint, part="(1)", pre=pre),
                 fl("x = %s 代入：" % pt_(x2), "(2)　y = %d sin(%s%s) + %d = [0]" % (R, pt_(x2 / R), (" + " + pt_(c)) if c else "", R), [y2.ans()],
                    "sin(%s) = %s" % (pt_(u2), sv(u2).text()), part="(2)"),
                 fl("y = 0 ⇒ sin(x/%d%s) = −1，取最小的 x > 0：" % (R, (" + " + pt_(c)) if c else ""), "答：滾了 [0]π", [a(xt)],
                    "x/%d%s = 3π/2" % (R, (" + " + pt_(c)) if c else "") if (F(3, 2) - c) * R > 0 else "x/%d%s = 7π/2" % (R, (" + " + pt_(c)) if c else ""), part="(3)")],
                plot={"x": [-R - 1.0, fx(float(xt) * PI + R + 1.0)], "y": [-1.2, 2 * R + 1.0], "geo": True, "h": 170,
                      "shapes": [{"k": "seg", "a": [-R - 1.0, 0], "b": [fx(float(xt) * PI + R + 1.0), 0], "c": "dim"}],
                      "groups": [{"o": [0, R], "anim": {"k": "roll", "r": R, "dist": fx(float(xt) * PI), "dur": 3.2}, "trace": pos,
                                  "shapes": [{"k": "circle", "o": [0, 0], "r": R, "c": "cyan"}, {"k": "poly", "pts": [[0, -R], [R, 0], [0, R], [-R, 0]], "c": "faint"},
                                             {"k": "dot", "p": [0, -R], "s": "A", "c": "cyan", "off": [6, 14]},
                                             {"k": "dot", "p": [R, 0], "s": "B", "c": "gold" if P == "B" else "cyan", "off": [8, -6]},
                                             {"k": "dot", "p": [0, R], "s": "C", "c": "gold" if P == "C" else "cyan"},
                                             {"k": "dot", "p": [-R, 0], "s": "D", "c": "gold" if P == "D" else "cyan", "off": [-18, -6]}]}]})


# ---------- tb_wave：讀圖找疊合 ----------

def tb_wave(xm, r):
    """最高點 (xm π, r)：y = r sin(x + φ)，φ = π/2 − xm"""
    xm, r = F(xm), Q.of(r)
    ph = F(1, 2) - xm
    aa, bb = r * cv(ph), r * sv(ph)
    f = lambda x: float(aa) * sin(x) + float(bb) * cos(x)
    assert near(f(float(xm) * PI), r)
    u0, u1 = F(-1, 2) + ph, F(1, 2) + ph
    us = [u0, u1] + ([F(-1, 2)] if u0 <= F(-1, 2) <= u1 else [])
    um = min(us, key=lambda u: float(sv(u)))
    mv = r * sv(um)
    mn, _ = ext(f, -PI / 2, PI / 2)
    assert near(mn, mv, 1e-6)
    half = r / 2
    sols_u = sorted(u for u in [F(1, 6) + 2 * k for k in range(-1, 3)] + [F(5, 6) + 2 * k for k in range(-1, 3)] if ph <= u <= ph + 2)
    sols_x = [u - ph for u in sols_u]
    rs = roots_in(lambda x: f(x) - float(half), 0, 2 * PI)
    assert len(rs) == len(sols_x) and near(sum(rs) / PI, sum(sols_x), 1e-6)
    S = sum(sols_x)
    ut = "x + %s = %s" % (pt_(ph), "、".join("[%d]π" % i for i in range(len(sols_u))))
    xt = "x = %s" % "、".join("[%d]π" % i for i in range(len(sols_x)))
    return item("tb_wave", "boss", 2, "讀圖找疊合", 1.65,
                "圖是 y = a sin x + b cos x 的一段，最高點 (%s, %s)。\n(1) 求 a、b　(2) −π/2 ≤ x ≤ π/2 時的最小值　(3) 0 ≤ x ≤ 2π 時，y = %s 的所有解的和" % (pt_(xm), r.text(), half.text()),
                [fl("最高點時 x + φ = π/2：", "%s + φ = π/2 ⇒ φ = [0]π" % pt_(xm), [a(ph)], "π/2 − %s" % pt_(xm), part="(1)",
                    pre="(1)　最大值 %s ⇒ y = %s sin(x + φ)" % (r.text(), r.text())),
                 fl("和角公式展開，對照 a sin x + b cos x：",
                    "a = %s cos(%s) = [0]，b = %s sin(%s) = [1]" % (r.text(), pt_(ph), r.text(), pt_(ph)), [aa.ans(), bb.ans()],
                    "%s · %s、%s · %s" % (r.text(), cv(ph).text(), r.text(), sv(ph).text()), part="(1)"),
                 fl("x + %s 從 %s 到 %s，sin 最小在%s：" % (pt_(ph), pt_(u0), pt_(u1), "左端" if um == u0 else ("右端" if um == u1 else " −π/2")),
                    "(2)　最小值 %s sin(%s) = [0]" % (r.text(), pt_(um)), [mv.ans()], "sin(%s) = %s" % (pt_(um), sv(um).text()), part="(2)"),
                 fl("x + %s 從 %s 走到 %s，sin = 1/2 的角（由小到大）：" % (pt_(ph), pt_(ph), pt_(ph + 2)), ut, [a(u) for u in sols_u],
                    "第一、第二象限各一個，再看有沒有多繞一圈", part="(3)",
                    pre="(3)　%s sin(x + %s) = %s ⇒ sin(x + %s) = 1/2" % (r.text(), pt_(ph), half.text(), pt_(ph))),
                 fl("各減 %s：" % pt_(ph), xt, [a(x) for x in sols_x], "每一個都減 %s" % pt_(ph), part="(3)"),
                 fl("%s個解加起來：" % ("三" if len(sols_x) == 3 else "兩"), "答：和 = [0]π", [a(S)], " + ".join(pt_(x) for x in sols_x), part="(3)")],
                plot={"x": [-1.8, 6.6], "y": [fx(-float(r) - 0.8), fx(float(r) + 0.8)], "pi": 12 if ph.denominator == 4 else 6, "pi_lab": 2,
                      "curves": [{"f": "%s*sin(x+%s)" % (gf(float(r)), gf(float(ph) * PI)), "c": "cyan"}, {"f": gf(float(half)), "c": "pink", "dash": True, "at": 4}],
                      "band": {"lo": -1.5708, "hi": 1.5708, "at": 2},
                      "pts": [{"x": fx(float(xm) * PI), "y": fx(float(r)), "label": "(%s, %s)" % (pt_(xm), r.lab())},
                              {"x": fx(float(um - ph) * PI), "y": fx(float(mv)), "label": "", "at": 3}]})


# ---------- tb_hex：翻滾的多邊形 ----------

def tb_hex(n, s):
    """正 n 邊形（n = 4 或 6），邊長 s"""
    R = s / (2 * sin(PI / n))
    dists = [2 * R * sin(j * PI / n) for j in range(1, n)]
    if n == 6:
        rad = [Q(s), Q(0, s, 3), Q(2 * s), Q(0, s, 3), Q(s)]
        mid = 2
        why = "正對面的頂點：通過中心，2 × 邊長"
        lead = "和 P 相隔一個頂點的距離是 %s，正對面的是：" % rad[1].text()
        name = "六"
        shape = "正六邊形"
    else:
        rad = [Q(s), Q(0, s, 2), Q(s)]
        mid = 1
        why = "對角線 = 邊長 × √{2}"
        lead = "相鄰的頂點距離 %d，對角的是：" % s
        name = "四"
        shape = "正方形"
    assert all(near(x, y) for x, y in zip(rad, dists))
    A = sum(x.a for x in rad)
    B = sum(x.b for x in rad)
    k = rad[1].n
    step_ = F(2, n)
    tot = Q(A, B, k) * step_
    shown = "、".join("[0]" if i == mid else rad[i].lab() for i in range(len(rad)))
    pts = []
    for j in range(n):
        ang = 2 * PI * j / n
        if j == 0:
            p = (0.0, 0.0)
        else:
            p = (pts[-1][0] + s * cos(ang - 2 * PI / n * 0 - 0), pts[-1][1] + s * sin(ang))
        pts.append(p)
    # 正多邊形，第一條邊在地上
    pts = [(0.0, 0.0)]
    for j in range(1, n):
        ang = 2 * PI * (j - 1) / n
        pts.append((pts[-1][0] + s * cos(ang), pts[-1][1] + s * sin(ang)))
    total_w = s * n + s
    hh = max(p[1] for p in pts)
    return item("tb_hex", "boss", 3, "翻滾的多邊形", 1.65,
                "邊長 %d 的%s放在直線上，頂點 P 碰著直線。%s沿直線向右翻滾（每次繞著右下角的頂點轉），直到 P 再次碰到直線。\n(1) 一共翻了幾次？每次轉多少？(2) P 走過的路徑長"
                % (s, shape, shape[1:] if n == 6 else shape),
                [fl("每翻一次，下一個頂點落地。%s個頂點輪一圈回到 P，P 自己落地那次不用再翻。" % name, "(1)　翻 [0] 次", [str(n - 1)],
                    "%d 個頂點，扣掉 P" % n, part="(1)"),
                 fl("每次轉的角度是%s的外角：" % shape, "每次轉 2π/%d = [0]π" % n, [a(step_)], "約分", part="(1)"),
                 fl("每翻一次，P 繞轉動的頂點畫一段圓弧，半徑是 P 到那個頂點的距離。%s" % lead, "(2)　半徑依序 %s" % shown, [rad[mid].ans()], why, part="(2)"),
                 fl("把%s個半徑加起來：" % ("五" if n == 6 else "三"), "半徑的和 = [0] + [1]√%d" % k, [str(A), a(B)],
                    "%s，以及 %s" % (" + ".join(x.lab() for x in rad if x.rat()), " + ".join(x.text() for x in rad if not x.rat())), part="(2)"),
                 fl("每段弧長 = 半徑 × %s，%s段加起來：" % (pt_(step_), "五" if n == 6 else "三"), "答：路徑長 = ([0] + [1]√%d)π/%d" % (k, n // 2), [str(A), a(B)],
                    "半徑的和乘 %s" % pt_(step_), part="(2)")],
                plot={"x": [-1.6, fx(total_w + 1.6)], "y": [-0.6, fx(hh + 1.2)], "geo": True, "h": 130,
                      "shapes": [{"k": "seg", "a": [-1.6, 0], "b": [fx(total_w + 1.6), 0], "c": "dim"}],
                      "groups": [{"o": [0, 0], "anim": {"k": "polyroll", "side": s, "sides": n, "n": n - 1, "dur": 0.9}, "trace": [0, 0],
                                  "shapes": [{"k": "poly", "pts": [[fx(p[0]), fx(p[1])] for p in pts], "c": "cyan"},
                                             {"k": "dot", "p": [0, 0], "s": "P", "off": [-14, -6]}]}]})


# ---------- tb_circum：外心的圓心角 ----------

def tb_circum(tA, tB, R):
    tA, tB = F(tA), F(tB)
    tAB = (tA + tB) / (1 - tA * tB)
    tC = -tAB
    assert tC > 0 and tA * tB > 1
    t2C = 2 * tC / (1 - tC * tC)
    sC = tC / Q.sqrt(1 + tC * tC)
    AB = 2 * R * sC
    s2C = 2 * tC / (1 + tC * tC)
    area = F(R * R, 2) * s2C
    A, B = math.atan(tA), math.atan(tB)
    C = PI - A - B
    assert near(tan(C), tC) and near(tan(2 * C), t2C) and near(AB, 2 * R * sin(C)) and near(area, 0.5 * R * R * sin(2 * C))
    angA = 1.5 * PI - C
    angB = 1.5 * PI + C
    angC = angB + 2 * A
    P = lambda ang: [fx(R * cos(ang)), fx(R * sin(ang))]
    pa, pb, pc = P(angA), P(angB), P(angC)
    hyp = 1 + tC * tC
    return item("tb_circum", "boss", 3, "外心的圓心角", 1.65,
                "O 是 △ABC 的外心，tan A = %s、tan B = %s，外接圓半徑 %d。\n(1) 求 tan C　(2) 求 tan∠AOB　(3) 求 \\ol{AB} 與 △AOB 的面積" % (t(tA), t(tB), R),
                [fl("先算 tan(A + B)：", "(1)　tan(A + B) = (%s + %s)/(1 − %s · %s) = [0]" % (t(tA), t(tB), tp(tA) if not isint(tA) else t(tA), t(tB)), [a(tAB)],
                    "分子 %s，分母 %s" % (t(tA + tB), t(1 - tA * tB)), part="(1)"),
                 fl("C = π − (A + B)：", "tan C = −tan(A + B) = [0]", [a(tC)], "tan(π − θ) = −tan θ", part="(1)"),
                 ch("三個角的 tan 都是正的，都是銳角，O 在三角形裡面。∠AOB 和 C 的關係：", ["∠AOB = 2∠C", "∠AOB = ∠C", "∠AOB = 180° − ∠C", "∠AOB = 2∠A"],
                    "同弧所對的圓心角是圓周角的兩倍", "(2)　∠AOB = 2C", part="(2)"),
                 fl("二倍角 tan 2C = 2 tan C/(1 − tan^{2} C)：", "tan∠AOB = tan 2C = %s/(1 − %s) = [0]" % (t(2 * tC), t(tC * tC)), [a(t2C)],
                    "%s/(%s)" % (t(2 * tC), t(1 - tC * tC)), part="(2)"),
                 fl("tan C = %s：對邊 %d、鄰邊 %d、斜邊 %s。" % (t(tC), tC.numerator, tC.denominator, Q.sqrt(tC.numerator ** 2 + tC.denominator ** 2).text()),
                    "(3)　sin C = [0]", [sC.ans()], "對邊/斜邊，有理化", part="(3)"),
                 fl("正弦定理 \\ol{AB} = 2R sin C：", "\\ol{AB} = %d · %s = [0]" % (2 * R, sC.text()), [AB.ans()], "%d × %s" % (2 * R, sC.text()), part="(3)"),
                 fl("sin 2C = 2 sin C cos C = %s：" % t(s2C), "答：△AOB 面積 = (1/2) · %d · %d · sin 2C = [0]" % (R, R), [a(area)],
                    "(%s) · (%s)" % (t(F(R * R, 2)), t(s2C)), part="(3)")],
                plot={"x": [-R - 0.8, R + 0.8], "y": [-R - 0.8, R + 0.8], "geo": True, "h": 200,
                      "shapes": [{"k": "circle", "o": [0, 0], "r": R, "c": "dim"},
                                 {"k": "poly", "pts": [pa, pb, pc], "c": "cyan"},
                                 {"k": "seg", "a": [0, 0], "b": pa, "c": "pink", "at": 2}, {"k": "seg", "a": [0, 0], "b": pb, "c": "pink", "at": 2},
                                 {"k": "angle", "o": [0, 0], "a0": fx(math.degrees(angA)), "a1": fx(math.degrees(angB)), "r": 14, "s": "", "at": 2},
                                 {"k": "label", "p": [fx(pa[0] * 1.13), fx(pa[1] * 1.13)], "s": "A"}, {"k": "label", "p": [fx(pb[0] * 1.13), fx(pb[1] * 1.13)], "s": "B"},
                                 {"k": "label", "p": [fx(pc[0] * 1.1), fx(pc[1] * 1.1)], "s": "C"},
                                 {"k": "dot", "p": [0, 0], "s": "O", "off": [6, -6]}]})


def items():
    return [
        [tb_gun(7, 18, 12), tb_gun(7, 25, 10), tb_gun(2, 16, 6)],
        [tb_path(20), tb_path_T(10), tb_path_Y(10)],
        [tb_coin(6, "B", 7), tb_coin(4, "D", F(14, 3)), tb_coin(6, "C", 4)],
        [tb_wave(F(1, 3), 4), tb_wave(F(1, 6), 2), tb_wave(F(1, 4), Q(0, 2, 2))],
        [tb_hex(6, 2), tb_hex(4, 2), tb_hex(6, 3)],
        [tb_circum(F(4, 3), 2, 5), tb_circum(3, F(1, 2), 5), tb_circum(1, 2, 5)],
    ]
