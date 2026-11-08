# 海岸委託
from tlib import *

sin, cos = math.sin, math.cos


def gf(k):
    return repr(float(k))


# ---------- tq_fan：扇形花圃 ----------

def tq_fan(L):
    r = F(L, 4)
    area = r * r
    th = (L - 2 * r) / r
    assert isint(r) and th == 2
    g = lambda x: x * (L - 2 * x) / 2
    assert max(g(i / 100) for i in range(0, L * 50)) <= float(area) + 1e-9
    return item("tq_fan", "quest", 1, "扇形花圃", 1.0,
                "用 %d 公尺長的籬笆圍一個扇形花圃（兩條半徑加一段弧）。半徑 r 是多少時面積最大？最大面積與圓心角各是多少？" % L,
                [fl("弧長 = %d − 2r，面積 = (1/2) · r · 弧長：" % L, "面積 = −r^{2} + [0]r", [str(L // 2)], "(1/2) r (%d − 2r)" % L),
                 fl("配方：−(r − %s)^{2} + %s。" % (t(r), t(area)), "r = [0] 時面積最大，最大面積 [1] 平方公尺", [a(r), a(area)], "頂點"),
                 fl("圓心角 = 弧長/半徑：", "答：θ = (%d − %s)/%s = [0]（弧度）" % (L, t(2 * r), t(r)), [a(th)], "%s/%s" % (t(L - 2 * r), t(r)))],
                plot={"x": [-9.8, 9.8], "y": [-1.2, 10.2], "geo": True, "h": 190,
                      "shapes": [{"k": "sector", "o": [0, 0], "r": 9, "a0": 32.7, "a1": 147.3, "c": "lime", "fill": "lime", "alpha": 0.15},
                                 {"k": "angle", "o": [0, 0], "a0": 32.7, "a1": 147.3, "r": 16, "s": "θ"},
                                 {"k": "label", "p": [5.0, 2.0], "s": "r"}]})


# ---------- tq_cone：圓錐上的螞蟻 ----------

def tq_cone(L, R, d):
    ang = F(2 * R, L)                     # 圓心角（π 的倍數）
    assert ang < 1
    c = cv(ang)
    AD2 = L * L + d * d - 2 * L * d * c
    assert AD2.rat()
    AD2 = AD2.a
    AD = Q.sqrt(AD2)
    th = float(ang) * PI
    assert near(AD, math.sqrt(L * L + d * d - 2 * L * d * cos(th)))
    h = math.sqrt(L * L - R * R)
    a0 = 90 - math.degrees(th) / 2
    a1 = 90 + math.degrees(th) / 2
    A2 = (L * cos(math.radians(a0)), L * sin(math.radians(a0)))
    D2 = (d * cos(math.radians(a1)), d * sin(math.radians(a1)))
    Dc = (R * d / L, h * (1 - d / L))
    term = 2 * L * d * c
    hint3 = "cos(%s) = %s，所以是 %d + %d %s %s" % (pt_(ang), c.text(), L * L, d * d, "+" if term < 0 else "−", t(abs(term.a))) if term != 0 else \
        "cos(%s) = 0，最後一項是 0" % pt_(ang)
    return item("tq_cone", "quest", 2, "圓錐上的螞蟻", 1.25,
                "圓錐的母線 \\ol{OA} = %d、底圓半徑 %d，D 在母線 \\ol{OA} 上，\\ol{OD} = %d。螞蟻從 A 出發，沿側面繞一圈爬到 D，最短要爬多遠？" % (L, R, d),
                [fl("沿 \\ol{OA} 剪開攤平，是半徑 %d 的扇形：" % L, "扇形的弧長 = 底圓周長 = [0]π", [str(2 * R)], "2π · %d" % R),
                 fl("圓心角 = 弧長/半徑：", "∠AOA' = %dπ/%d = [0]π" % (2 * R, L), [a(ang)], "約分"),
                 fl("攤平後最短路徑是線段 \\ol{AD}（D 在 \\ol{OA'} 上）。△AOD：\\ol{OA} = %d、\\ol{OD} = %d、夾角 %s，用餘弦定理：" % (L, d, pt_(ang)),
                    "\\ol{AD}^{2} = %d + %d − 2 · %d · %d · cos(%s) = [0]" % (L * L, d * d, L, d, pt_(ang)), [a(AD2)], hint3),
                 fl("開根號：", "答：\\ol{AD} = √{%s} = [0]" % t(AD2), [AD.ans()], "%s = %d × %d" % (t(AD2), int(AD.b ** 2), AD.n) if AD.b != 1 else "不能再化簡")],
                plot={"x": [-L - 1.0, L + 1.0], "y": [-2.0, L + 1.0], "geo": True, "h": 200,
                      "shapes": [
                          {"k": "seg", "a": [-R, 0], "b": [0, fx(h)], "c": "cyan", "until": 2}, {"k": "seg", "a": [R, 0], "b": [0, fx(h)], "c": "cyan", "until": 2},
                          {"k": "ellipse", "o": [0, 0], "rx": R, "ry": fx(R * 0.275), "c": "cyan", "until": 2},
                          {"k": "dot", "p": [R, 0], "s": "A", "off": [6, 14], "until": 2}, {"k": "dot", "p": [fx(Dc[0]), fx(Dc[1])], "s": "D", "until": 2},
                          {"k": "label", "p": [0, fx(h + 1.1)], "s": "O", "until": 2},
                          {"k": "sector", "o": [0, 0], "r": L, "a0": fx(a0), "a1": fx(a1), "c": "cyan", "fill": "cyan", "alpha": 0.1, "at": 2},
                          {"k": "angle", "o": [0, 0], "a0": fx(a0), "a1": fx(a1), "r": 16, "s": "", "at": 2},
                          {"k": "dot", "p": [fx(A2[0]), fx(A2[1])], "s": "A", "at": 2}, {"k": "dot", "p": [fx(D2[0]), fx(D2[1])], "s": "D", "off": [-8, -10], "at": 2},
                          {"k": "label", "p": [fx(-A2[0] - 0.5), fx(A2[1] + 1.6)], "s": "A'", "at": 2}, {"k": "label", "p": [0, -1.0], "s": "O", "at": 2},
                          {"k": "seg", "a": [fx(A2[0]), fx(A2[1])], "b": [fx(D2[0]), fx(D2[1])], "c": "gold", "w": 2.6, "at": 3}]})


# ---------- tq_wheel：滾動的輪子 ----------

def tq_wheel(R, s):
    s = F(s)
    ang = s / R
    hv = R - R * cv(ang)
    assert near(hv, R - R * cos(float(ang) * PI))
    return item("tq_wheel", "quest", 2, "滾動的輪子", 1.15,
                "半徑 %d 公尺的輪子沿地面向右滾動（不打滑）。輪上一點 P 一開始碰著地面。\n(1) 輪子滾了 %s 公尺時，P 離地多高？(2) 滾了 x 公尺時，P 離地 h(x) = ？" % (R, pt_(s)),
                [fl("滾過的距離 = 轉過的弧長 = 半徑 × 轉過的弧度：", "轉了 %s/%d = [0]π" % (pt_(s) if s == 1 else "(%s)" % pt_(s), R), [a(ang)], "弧長 = rθ", part="(1)"),
                 fl("P 從最低點繞圓心轉 %s，離圓心的高度差是 −%d cos(%s)。" % (pt_(ang), R, pt_(ang)), "P 離地 %d − %d cos(%s) = [0]" % (R, R, pt_(ang)), [hv.ans()],
                    "cos(%s) = %s" % (pt_(ang), cv(ang).text()), part="(1)"),
                 fl("滾 x 公尺就轉 x/%d：" % R, "答：h(x) = [0] − %d cos(x/[1])" % R, [str(R), str(R)], "圓心離地 %d" % R, part="(2)")],
                plot={"x": [-R - 0.6, fx(R + float(s) * PI + 0.4)], "y": [-0.6, 2 * R + 0.6], "geo": True, "h": 150,
                      "shapes": [{"k": "seg", "a": [-R - 0.6, 0], "b": [fx(R + float(s) * PI + 0.4), 0], "c": "dim"}],
                      "groups": [{"o": [0, R], "anim": {"k": "roll", "r": R, "dist": fx(float(s) * PI), "dur": 3.0}, "trace": [0, -R],
                                  "shapes": [{"k": "circle", "o": [0, 0], "r": R, "c": "cyan"}, {"k": "seg", "a": [0, 0], "b": [0, -R], "c": "faint"},
                                             {"k": "seg", "a": [0, 0], "b": [R, 0], "c": "faint"}, {"k": "seg", "a": [0, 0], "b": [-R, 0], "c": "faint"},
                                             {"k": "seg", "a": [0, 0], "b": [0, R], "c": "faint"},
                                             {"k": "dot", "p": [0, -R], "s": "P", "off": [6, 14]}]}]})


# ---------- tq_ferris：摩天輪 ----------

def tq_ferris(Dm, low, P, H):
    r = Dm // 2
    d = low + r
    b = F(2, P)                             # bπ
    c0 = F(d - H, r)                        # cos(2πt/P) < c0
    al = None
    for k in (F(1, 3), F(1, 2), F(2, 3)):
        if cv(k) == c0:
            al = k
    assert al is not None
    t0, t1 = al / b, (2 - al) / b
    hfun = lambda tt: d - r * cos(2 * PI * tt / P)
    xs = [P * i / 2400 for i in range(2401)]
    above = [x for x in xs if hfun(x) > H]
    assert near(min(above), float(t0), 0.02) and near(max(above), float(t1), 0.02)
    s = 3.0 / r
    cy = d * s
    sp = 1.6
    return item("tq_ferris", "quest", 2, "摩天輪", 1.2,
                "摩天輪直徑 %d 公尺，最低點離地 %d 公尺，逆時針等速轉動，%d 分鐘一圈。小光從最低點上車，t 分鐘後離地 h(t) = a sin(bt + c) + d 公尺（a、b > 0，−π < c ≤ π）。\n(1) 求 a、b、c、d　(2) 一圈之中，有幾分鐘高於 %d 公尺？"
                % (Dm, low, P, H),
                [fl("振幅是半徑，中線是圓心的高度：", "a = [0]，d = [1]", [str(r), str(d)], "圓心離地 %d + %d" % (low, r), part="(1)"),
                 fl("週期 %d 分鐘：" % P, "b = 2π/%d = [0]π" % P, [a(b)], "化簡 2/%d" % P, part="(1)"),
                 fl("t = 0 在最低點：sin c = −1。", "c = [0]π", ["−1/2"], "−π < c ≤ π", part="(1)"),
                 fl("一圈 0 ≤ t ≤ %d 裡，解出 t：" % P, "%s < %s < %s ⇒ [0] < t < [1]" % (pt_(al), pt_(b).replace("π", "πt"), pt_(2 - al)), [a(t0), a(t1)],
                    "兩邊乘 %s" % ("%d/π" % (P // 2) if P % 2 == 0 else "%d/(2π)" % P), part="(2)",
                    pre="(2)　h(t) = %d − %d cos(%s) > %d ⇒ cos(%s) < %s" % (d, r, pt_(b).replace("π", "πt"), H, pt_(b).replace("π", "πt"), t(c0)),
                    write="答：每圈 %s 分鐘高於 %d 公尺" % (t(t1 - t0), H))],
                plot={"x": [-3.6, 3.6], "y": [-0.3, fx(cy + 3.4)], "geo": True, "h": 180,
                      "shapes": [{"k": "seg", "a": [-3.6, 0], "b": [3.6, 0], "c": "dim"}, {"k": "seg", "a": [0, fx(cy)], "b": [-sp, 0], "c": "faint"},
                                 {"k": "seg", "a": [0, fx(cy)], "b": [sp, 0], "c": "faint"},
                                 {"k": "seg", "a": [-3.6, fx(H * s)], "b": [3.6, fx(H * s)], "c": "pink", "dash": True, "at": 3},
                                 {"k": "label", "p": [3.2, fx(H * s + 0.4)], "s": str(H), "c": "pink", "at": 3}],
                      "groups": [{"o": [0, fx(cy)], "anim": {"k": "spin", "period": 9.0, "dir": 1},
                                  "shapes": [{"k": "circle", "o": [0, 0], "r": 3, "c": "cyan"},
                                             {"k": "seg", "a": [0, -3], "b": [0, 3], "c": "faint"}, {"k": "seg", "a": [-2.598, -1.5], "b": [2.598, 1.5], "c": "faint"},
                                             {"k": "seg", "a": [-2.598, 1.5], "b": [2.598, -1.5], "c": "faint"},
                                             {"k": "dot", "p": [0, 3], "c": "cyan"}, {"k": "dot", "p": [2.598, 1.5], "c": "cyan"}, {"k": "dot", "p": [2.598, -1.5], "c": "cyan"},
                                             {"k": "dot", "p": [-2.598, 1.5], "c": "cyan"}, {"k": "dot", "p": [-2.598, -1.5], "c": "cyan"}, {"k": "dot", "p": [0, -3], "c": "gold"}]}]})


# ---------- tq_tide：進港的時段 ----------

def tq_tide(cfg):
    A, Dd, c, H = cfg["a"], cfg["d"], F(cfg["c"]), cfg["H"]
    y = lambda x: A * sin(PI / 6 * x + float(c) * PI) + Dd
    assert [round(y(x), 9) for x in (0, 3, 6, 9, 12)] == cfg["vals"]
    lo, hi = cfg["win"]
    assert near(y(lo), H) and near(y(hi), H) and y((lo + hi) / 2) > H
    # 一天裡的解：和 marks/seg 對得上
    marks = cfg["marks"]
    seg = cfg["seg"]
    pts = [0] + [float(num(m)) for m in marks] + [24]
    for i in range(len(seg)):
        a0, b0 = max(pts[i], 0), min(pts[i + 1], 24)
        if b0 - a0 < 1e-9:
            continue
        mid = (a0 + b0) / 2
        assert (y(mid) >= H) == bool(seg[i]), (cfg["vals"], i)
    vs = cfg["vals"]
    ch_ = "，".join(str(int(v)) for v in vs)
    return item("tq_tide", "quest", 2, "進港的時段", 1.2,
                "港口水深 y = a sin(bx + c) + d（公尺，x 是時刻，a、b > 0、0 ≤ c < 2π）。x = 0、3、6、9、12 時，y = %s。\n水深 ≥ %s 時大船才能進港。一天（0 ≤ x ≤ 24）哪些時段可以進港？"
                % ("、".join(str(int(v)) for v in vs), cfg["Ht"]),
                [fl("最高 %d、最低 %d，12 小時一個週期：" % (Dd + A, Dd - A), "d = [0]，a = [1]，b = [2]π", [str(Dd), str(A), "1/6"], "b = 2π/12"),
                 fl(cfg["cq"], cfg.get("ct", "c = [0]π"), [cfg["ca"]], cfg["ch"]),
                 fl(cfg["wq"], cfg["wt"], [a(F(lo)), a(F(hi))], "兩邊乘 6/π",
                    pre="%d sin(%s) + %d ≥ %s ⇒ sin(%s) ≥ 1/2" % (A, cfg["u"], Dd, cfg["Ht"], cfg["u"])),
                 step("line", q=cfg["lq"], row="進港", marks=marks, seg=seg, pt=[1] * len(marks), write="答：" + cfg["write"])],
                plot={"x": [-0.8, 24.8], "y": [fx(Dd - A - 1.2), fx(Dd + A + 1.5)], "h": 175,
                      "curves": [{"f": "%d*sin(PI/6*x+%s)+%d" % (A, gf(float(c) * PI), Dd), "c": "cyan", "at": 2}, {"f": gf(H), "c": "pink", "dash": True, "at": 2}],
                      "pts": [{"x": x, "y": fx(y(x)), "label": ""} for x in (0, 3, 6, 9, 12)]})


TIDE = [
    {"a": 3, "d": 5, "c": 0, "H": 6.5, "Ht": "6.5", "vals": [5, 8, 5, 2, 5], "u": "πx/6",
     "cq": "x = 0 時 y 在中線 5，接著往上升：", "ca": "0", "ct": "c = [0]", "ch": "sin c = 0，而且要是上升的那一點",
     "win": (1, 5), "wq": "sin u ≥ 1/2 在 π/6 ≤ u ≤ 5π/6（再加 2π 的倍數）：", "wt": "π/6 ≤ πx/6 ≤ 5π/6 ⇒ [0] ≤ x ≤ [1]",
     "lq": "加一個週期 12，封印一天之中可以進港的時段。", "marks": ["1", "5", "13", "17"], "seg": [0, 1, 0, 1, 0], "write": "1 ≤ x ≤ 5 或 13 ≤ x ≤ 17"},
    {"a": 3, "d": 4, "c": 1, "H": 5.5, "Ht": "5.5", "vals": [4, 1, 4, 7, 4], "u": "πx/6 + π",
     "cq": "x = 0 時 y 在中線 4，接著往下降：", "ca": "1", "ch": "sin c = 0，而且要是下降的那一點",
     "win": (7, 11), "wq": "sin u ≥ 1/2 在 π/6 ≤ u ≤ 5π/6（再加 2π 的倍數）。u 從 π 開始，第一段是 13π/6 到 17π/6：",
     "wt": "13π/6 ≤ πx/6 + π ≤ 17π/6 ⇒ [0] ≤ x ≤ [1]",
     "lq": "加一個週期 12，封印一天之中可以進港的時段。", "marks": ["7", "11", "19", "23"], "seg": [0, 1, 0, 1, 0], "write": "7 ≤ x ≤ 11 或 19 ≤ x ≤ 23"},
    {"a": 3, "d": 5, "c": F(1, 2), "H": 6.5, "Ht": "6.5", "vals": [8, 5, 2, 5, 8], "u": "πx/6 + π/2",
     "cq": "x = 0 時 y 是最高 8：", "ca": "1/2", "ch": "sin c = 1",
     "win": (-2, 2), "wq": "sin u ≥ 1/2 在 π/6 ≤ u ≤ 5π/6（再加 2π 的倍數）：", "wt": "π/6 ≤ πx/6 + π/2 ≤ 5π/6 ⇒ [0] ≤ x ≤ [1]",
     "lq": "加上週期 12 的倍數，只留 0 到 24 的部分，封印可以進港的時段。", "marks": ["2", "10", "14", "22"], "seg": [1, 0, 1, 0, 1],
     "write": "0 ≤ x ≤ 2、10 ≤ x ≤ 14 或 22 ≤ x ≤ 24"},
]


# ---------- tq_light：自動窗簾 ----------

def tq_light(base, amp, sh, H, amp2):
    """I(t) = base + amp sin(π/12 (t − sh))，I ≥ H 半閉；陰天振幅 amp2 = H − base"""
    k = F(H - base, amp)
    assert k == F(1, 2) and amp2 == H - base
    t0, t1 = sh + 2, sh + 10
    tp_ = sh + 6
    I = lambda tt: base + amp * sin(PI / 12 * (tt - sh))
    assert near(I(t0), H) and near(I(t1), H) and I(tp_) > H
    opts = ["只在 %d 點那一瞬間半閉" % tp_, "%d 點到 %d 點都半閉" % (t0, t1), "%d 點到 %d 點半閉" % (tp_ - 2, tp_ + 2), "整天都不會半閉"]
    s = 1.0 / 100
    return item("tq_light", "quest", 2, "自動窗簾", 1.15,
                "窗邊照度 I(t) = %d + %d sin(π/12 · (t − %d))，0 ≤ t < 24（時）。I(t) ≥ %d 時窗簾半閉。\n(1) 晴天從幾點半閉到幾點？(2) 陰天 I(t) = %d + %d sin(π/12 · (t − %d))，會怎樣？"
                % (base, amp, sh, H, base, amp2, sh),
                [fl("%d + %d sin(…) ≥ %d：" % (base, amp, H), "sin(π/12 · (t − %d)) ≥ [0]" % sh, ["1/2"], "%d/%d" % (H - base, amp), part="(1)"),
                 fl("π/6 ≤ π/12 · (t − %d) ≤ 5π/6：" % sh, "[0] ≤ t ≤ [1]", [str(t0), str(t1)], "2 ≤ t − %d ≤ 10" % sh, part="(1)"),
                 ch("陰天要 %d sin(…) ≥ %d，也就是 sin(…) ≥ 1：" % (amp2, H - base), opts,
                    "sin 等於 1 只有一個時刻：π/12 · (t − %d) = π/2" % sh, "答：(1) %d 點到 %d 點　(2) 只在 %d 點那一瞬間" % (t0, t1, tp_), part="(2)")],
                plot={"x": [-0.5, 24.5], "y": [fx((base - amp) * s - 0.5), fx((base + amp) * s + 0.8)], "h": 175,
                      "curves": [{"f": "%s+%s*sin(PI/12*(x-%d))" % (gf(base * s), gf(amp * s), sh), "c": "cyan"}, {"f": gf(H * s), "c": "pink", "dash": True},
                                 {"f": "%s+%s*sin(PI/12*(x-%d))" % (gf(base * s), gf(amp2 * s), sh), "c": "lime", "dash": True, "at": 2}],
                      "pts": [{"x": t0, "y": fx(H * s), "label": "", "at": 1}, {"x": t1, "y": fx(H * s), "label": "", "at": 1},
                              {"x": tp_, "y": fx(H * s), "label": "", "at": 2}]})


# ---------- tq_slope：溜滑梯的坡度 ----------

def tq_slope(o, adj, hyp, L):
    assert o * o + adj * adj == hyp * hyp
    s, c = F(o, hyp), F(adj, hyp)
    th2 = (1 - c) / s
    s2 = (1 - c) / 2
    height = L * Q.sqrt(s2)
    th = math.atan2(o, adj)
    assert near(th2, math.tan(th / 2)) and near(height, L * sin(th / 2))
    sc = 4.0 / adj
    W, Hh = adj * sc, o * sc
    return item("tq_slope", "quest", 1, "溜滑梯的坡度", 1.05,
                "舊溜滑梯的坡道和地面夾角 θ，坡度 tan θ = %s。新溜滑梯的夾角是 θ/2，坡道一樣長 %d 公尺。\n(1) 新的坡度 tan(θ/2) 是多少？(2) 新坡道的頂端多高？" % (t(F(o, adj)), L),
                [fl("直角三角形 %d、%d、%d：" % (o, adj, hyp), "sin θ = [0]，cos θ = [1]", [a(s), a(c)], "斜邊 %d" % hyp, part="(1)"),
                 fl("以切表弦：", "tan(θ/2) = (1 − cos θ)/sin θ = (%s)/(%s) = [0]" % (t(1 - c), t(s)), [a(th2)], "分母一樣是 %d" % hyp, part="(1)"),
                 fl("半角公式：", "sin^{2}(θ/2) = (1 − cos θ)/2 = [0]", [a(s2)], "(%s)/2" % t(1 - c), part="(2)"),
                 fl("θ/2 是銳角，sin(θ/2) = √{%s}：" % t(s2), "答：高 = %d sin(θ/2) = %s = [0]" % (L, "%d/√{%d}" % (L, s2.denominator) if s2.numerator == 1 else "%d√{%s}" % (L, t(s2))),
                    [height.ans()], "%d/√{%d} 有理化" % (L, s2.denominator) if s2.numerator == 1 else "化簡", part="(2)")],
                plot={"x": [-0.6, fx(W + 0.6)], "y": [-0.6, fx(Hh + 0.4)], "geo": True, "h": 170,
                      "shapes": [{"k": "poly", "pts": [[0, 0], [fx(W), 0], [fx(W), fx(Hh)]], "c": "cyan"}, {"k": "right", "p": [fx(W), 0], "u": [-1, 0], "v": [0, 1]},
                                 {"k": "angle", "o": [0, 0], "a0": 0, "a1": fx(math.degrees(th)), "r": 30, "s": "θ"},
                                 {"k": "seg", "a": [0, 0], "b": [fx(W), fx(W * float(th2))], "c": "gold", "dash": True, "at": 1},
                                 {"k": "label", "p": [fx(W / 2), -0.35], "s": str(adj)}, {"k": "label", "p": [fx(W + 0.3), fx(Hh / 2)], "s": str(o)}]})


# ---------- tq_mount：測山高 ----------

def tq_mount(AB, BC):
    CD2 = AB * AB - BC * BC
    CD = Q.sqrt(CD2)
    c2 = F(BC, AB)
    th2 = math.acos(float(c2))
    th = th2 / 2
    assert near(math.tan(th) * (AB + BC), CD) and near(math.tan(th2) * BC, CD)
    s = 14.0 / (AB + BC)
    Bx, Cx, Dy = AB * s, (AB + BC) * s, float(CD) * s
    return item("tq_mount", "quest", 3, "測山高", 1.35,
                "在 A 點測得山頂 D 的仰角是 θ。朝山腳 C 直走 %d 公尺到 B，仰角變成 2θ，再走 %d 公尺剛好到山腳 C（\\ol{DC} 垂直地面）。求山高 \\ol{CD} 與 cos 2θ。" % (AB, BC),
                [ch("∠DBC = 2θ 是 △ABD 的外角，等於兩個內對角的和。∠ADB 是多少？", ["θ", "2θ", "90° − θ", "180° − 3θ"],
                    "2θ = ∠DAB + ∠ADB = θ + ∠ADB", "∠ADB = 2θ − θ = θ ⇒ △ABD 是等腰三角形"),
                 fl("∠DAB = ∠ADB = θ，等角對等邊：", "\\ol{BD} = \\ol{AB} = [0]", [str(AB)], "等腰三角形"),
                 fl("直角 △BCD，畢氏定理：", "\\ol{CD}^{2} = %d^{2} − %d^{2} = [0]" % (AB, BC), [str(CD2)], "%d − %d" % (AB * AB, BC * BC)),
                 fl("開根號：", "\\ol{CD} = √{%d} = [0]" % CD2, [CD.ans()], ("%d = %d × %d" % (CD2, int(CD.b ** 2), CD.n)) if CD.n != 1 else "%d = %d^{2}" % (CD2, CD.a)),
                 fl("直角 △BCD 中 ∠DBC = 2θ：", "答：cos 2θ = \\ol{BC}/\\ol{BD} = [0]", [a(c2)], "%d/%d" % (BC, AB))],
                plot={"x": [-0.8, 15.0], "y": [-1.0, fx(Dy + 0.9)], "geo": True, "h": 180,
                      "shapes": [{"k": "seg", "a": [-0.6, 0], "b": [14.8, 0], "c": "dim"}, {"k": "seg", "a": [0, 0], "b": [fx(Cx), fx(Dy)], "c": "cyan"},
                                 {"k": "seg", "a": [fx(Bx), 0], "b": [fx(Cx), fx(Dy)], "c": "cyan"}, {"k": "seg", "a": [fx(Cx), 0], "b": [fx(Cx), fx(Dy)], "c": "cyan"},
                                 {"k": "right", "p": [fx(Cx), 0], "u": [-1, 0], "v": [0, 1]},
                                 {"k": "angle", "o": [0, 0], "a0": 0, "a1": fx(math.degrees(th)), "r": 30, "s": "θ"},
                                 {"k": "angle", "o": [fx(Bx), 0], "a0": 0, "a1": fx(math.degrees(th2)), "r": 16, "s": "2θ"},
                                 {"k": "label", "p": [0, -0.6], "s": "A"}, {"k": "label", "p": [fx(Bx), -0.6], "s": "B"}, {"k": "label", "p": [fx(Cx + 0.4), -0.6], "s": "C"},
                                 {"k": "label", "p": [fx(Cx), fx(Dy + 0.55)], "s": "D"},
                                 {"k": "label", "p": [fx(Bx / 2), -0.6], "s": str(AB)}, {"k": "label", "p": [fx((Bx + Cx) / 2), -0.6], "s": str(BC)}]})


def items():
    return [
        [tq_fan(36), tq_fan(40), tq_fan(28)],
        [tq_cone(12, 4, 6), tq_cone(12, 3, 4), tq_cone(12, 2, 6)],
        [tq_wheel(2, F(4, 3)), tq_wheel(3, 1), tq_wheel(4, F(8, 3))],
        [tq_ferris(60, 10, 12, 55), tq_ferris(40, 5, 18, 35), tq_ferris(80, 8, 24, 48)],
        [tq_tide(c) for c in TIDE],
        [tq_light(500, 300, 8, 650, 150), tq_light(500, 300, 6, 650, 150), tq_light(400, 200, 7, 500, 100)],
        [tq_slope(3, 4, 5, 10), tq_slope(5, 12, 13, 13), tq_slope(8, 15, 17, 17)],
        [tq_mount(100, 40), tq_mount(50, 30), tq_mount(65, 25)],
    ]
