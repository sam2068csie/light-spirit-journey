# 圖形辨識（選圖題）
from plib import *


def _e(s):
    """Python 數學式 → Godot Expression（只用 pow、*、/）"""
    return s


def cub(c, h=0, v=0, sg=1):
    """sg·[(x − h)^3 − c(x − h)] + v"""
    xs = "x" if h == 0 else ("(x-%s)" % repr(float(h)) if h > 0 else "(x+%s)" % repr(float(-h)))
    s = "pow(%s,3)-%s*%s" % (xs, repr(float(c)), xs)
    if sg < 0:
        s = "-(" + s + ")"
    if v:
        s += ("+%s" % repr(float(v))) if v > 0 else ("-%s" % repr(float(-v)))
    return s


# ---------- pg_shift：平移 ----------

def pg_shift(c, h, v):
    base = cub(c)
    f = lambda x: x ** 3 - c * x
    k = f(F(-h)) + v
    dirx = lambda hh: ("右" if hh > 0 else "左") + " %d" % abs(hh)
    diry = lambda vv: ("上" if vv > 0 else "下") + " %d" % abs(vv)
    target = "f(%s) %s %d" % (fac(h).strip("()") if h != 0 else "x", "+" if v > 0 else M, abs(v))
    gs = [g_small(cub(c, h, v), base), g_small(cub(c, -h, v), base), g_small(cub(c, h, -v), base),
          g_small(cub(c, -v, h), base) if (-v, h) != (h, v) else g_small(cub(c, h + 1, v), base), g_small(cub(c, h, v, -1) + "", base)]
    # 第 5 張：上下翻轉（翻轉後再往上移 v）
    gs[4] = g_small("-(" + cub(c, h) + ")" + (("+%s" % float(v)) if v > 0 else ("-%s" % float(-v))), base)
    whys = ["", "這是往%s" % dirx(-h), "這是往%s" % diry(-v), "這是往%s、往%s" % (dirx(-v), diry(h)) if (-v, h) != (h, v) else "", "這張還上下翻轉了"]
    if whys[3] == "":
        whys[3] = "這是往%s" % dirx(h + 1)
    return item("pg_shift", "graph", 1, "平移", 1.0,
                "虛線是 y = f(x) = x^{3} − %dx 的圖形。\n(1) 哪一張的實線最接近 y = %s？\n(2) y = %s 的圖形和 y 軸交於 (0, k)，求 k" % (c, target, target),
                [pick("哪一張的實線最接近 y = %s？" % target, gs, whys,
                      "%s 是往%s，再 %s %d 是往%s：對稱中心從 (0, 0) 移到 (%d, %d)" % ("f(%s)" % fac(h).strip("()"), dirx(h), "+" if v > 0 else M, abs(v), diry(v), h, v),
                      "y = %s：往%s、往%s，對稱中心 (0, 0) → (%d, %d)" % (target, dirx(h), diry(v), h, v)),
                 fl("(2) x = 0 代入，求 k：", "k = f(%d) %s %d = [0]" % (-h, "+" if v > 0 else M, abs(v)), [a(k)],
                    "f(%d) = %s" % (-h, t(f(F(-h)))))])


# ---------- pg_scale：伸縮 ----------

def pg_scale(den, r, xr, yr):
    """f(x) = (x^3 − r^2 x)/den，交 x 軸於 0、±r；問 f(2x)"""
    fs = lambda inner: "(pow(%s,3)-%s*%s)/%s" % (inner, float(r * r), inner, float(den))
    base = fs("x")
    gs = [g_small(fs("(2*x)"), base, xr, yr), g_small(fs("(x/2)"), base, xr, yr), g_small("2*" + base, base, xr, yr),
          g_small(base + "/2", base, xr, yr), g_small("-" + fs("(2*x)"), base, xr, yr)]
    whys = ["", "這是 f(x/2)：水平拉寬了", "這是 2f(x)：交點沒變，只是變高", "這是 f(x)/2：交點沒變，只是變扁", "這張上下翻轉了"]
    return item("pg_scale", "graph", 2, "伸縮", 1.0,
                "虛線是 y = f(x) = \\frac{x^{3} − %dx}{%d} 的圖形，它和 x 軸交在 x = 0、±%d。哪一張的實線最接近 y = f(2x)？" % (r * r, den, r),
                [pick("哪一張的實線最接近 y = f(2x)？", gs, whys,
                      "f(2x) = 0 的解是 2x = 0、±%d：交點變成 x = 0、±%s，水平壓縮成一半" % (r, t(F(r, 2))),
                      "f(2x) = 0 ⇒ 2x = 0、±%d ⇒ x = 0、±%s（水平壓縮）" % (r, t(F(r, 2))))])


# ---------- pg_flip：一次項變號 ----------

def pg_flip(sa, sc):
    """虛線 y = ax^3 + cx，a = sa/4，c = 2·sc"""
    A, C = sa * 0.25, sc * 2.0
    f = lambda a_, c_, d=0.0: "%s*pow(x,3)+%s*x%s" % (a_, c_, ("+%s" % d) if d else "")
    dashed = f(A, C)
    target = f(A, -C)
    sgn = lambda v: ">" if v > 0 else "<"
    right = "a %s 0，c %s 0" % (sgn(sa), sgn(sc))
    opts = [right] + [o for o in ["a > 0，c < 0", "a > 0，c > 0", "a < 0，c < 0", "a < 0，c > 0"] if o != right]
    up_end = "往右越來越高" if sa > 0 else "往右越來越低"
    near = "往右上升" if -sc > 0 else "往右下降"
    gs = [g_small(target, dashed), g_small(f(-A, -C), dashed), g_small(f(-A, C), dashed), g_small(f(A, -C, 2.0), dashed), g_small(f(A, 2 * C), dashed)]
    whys = ["", "首項係數還是 a %s 0，%s" % (sgn(sa), up_end), "首項係數還是 a %s 0，右端的方向不會變" % sgn(sa), "y = ax^{3} − cx 一定通過原點",
            "−c %s 0，在原點附近要%s" % (sgn(-sc), near)]
    return item("pg_flip", "graph", 2, "一次項變號", 1.0,
                "虛線是 y = ax^{3} + cx 的圖形（a、c 是實數）。哪一張的實線最接近 y = ax^{3} − cx？",
                [ch("從虛線判斷 a、c 的正負：", opts,
                    "%s ⇒ a %s 0，在原點附近%s ⇒ 一次項係數 c %s 0" % (up_end, sgn(sa), "往右上升" if sc > 0 else "往右下降", sgn(sc)),
                    "虛線：%s ⇒ a %s 0，原點附近%s ⇒ c %s 0" % (up_end, sgn(sa), "上升" if sc > 0 else "下降", sgn(sc))),
                 pick("哪一張的實線最接近 y = ax^{3} − cx？", gs, whys,
                      "a %s 0 不變、一次項 −c %s 0：通過原點、原點附近%s" % (sgn(sa), sgn(-sc), near),
                      "y = ax^{3} − cx：a %s 0、−c %s 0 ⇒ 過原點、原點附近%s" % (sgn(sa), sgn(-sc), near))])


# ---------- pg_pair：兩個圖形的搭配 ----------

def pg_pair(A, B, C, xr, yr):
    q = lambda a_, b_, c_: "%s*x*x+%s*x+%s" % (float(a_), float(b_), float(c_))
    cu = lambda a_, b_, c_: "%s*pow(x,3)+%s*x+%s" % (float(a_), float(b_), float(c_))
    P1 = q(A, B, C)
    gs = [g_small(P1, "", xr, yr, cu(A, B, C)), g_small(P1, "", xr, yr, cu(A, B, -C)), g_small(P1, "", xr, yr, cu(-A, B, C)),
          g_small(P1, "", xr, yr, cu(A, -B, C)), g_small(q(-A, B, C), "", xr, yr, cu(A, B, C))]
    vtx = "右" if -B / (2 * A) > 0 else "左"
    whys = ["", "兩個圖形和 y 軸的交點都是 (0, c)，要一樣",
            "拋物線開口向%s ⇒ a %s 0，三次函數應該往右越來越%s" % ("上" if A > 0 else "下", ">" if A > 0 else "<", "高" if A > 0 else "低"),
            "拋物線的頂點在%s邊 ⇒ ab %s 0，b %s 0，三次函數在 y 軸上應該往右%s" % (vtx, "<" if vtx == "右" else ">", ">" if B > 0 else "<", "上升" if B > 0 else "下降"),
            "拋物線開口向%s ⇒ a %s 0，三次函數卻往右越來越%s" % ("下" if A > 0 else "上", "<" if A > 0 else ">", "高" if A > 0 else "低")]
    return item("pg_pair", "graph", 2, "兩個圖形的搭配", 1.1,
                "Γ_{1}：y = ax^{2} + bx + c（實線），Γ_{2}：y = ax^{3} + bx + c（虛線），a、b、c 是同一組數。哪一張的搭配可能正確？",
                [pick("哪一張的搭配可能正確？", gs, whys,
                      "三個線索：y 截距都是 c，a 決定開口和三次函數的右端，b 決定頂點左右和三次函數在 y 軸上的升降",
                      "同一組 a、b、c：y 截距相同、開口 ↔ 右端、頂點位置 ↔ y 軸上的升降")])


# ---------- pg_which：認出三次函數 ----------

def pg_which(s, h, m, xr, yr):
    """y = s[(x − h)^3 − m^2(x − h)]"""
    ts = "t" if True else ""
    xs = fac(h)
    roots = [h - m, h, h + m]
    rs = "、".join(t(r) for r in roots)
    inner = "%s^{3} − %s" % (xs, (str(m * m) if m != 1 else "") + xs) if True else ""
    stem_f = ("−" if s < 0 else "") + ("[%s]" % inner if s < 0 else inner)
    if s < 0:
        stem_f = "−%s^{3} + %s%s" % (xs, "" if m == 1 else str(m * m), xs)
    else:
        stem_f = "%s^{3} − %s%s" % (xs, "" if m == 1 else str(m * m), xs)
    right = "(%s, 0)，x = %s" % (t(h), rs)
    opts = uniq([right], ["(%s, 0)，x = %s" % (t(-h), "、".join(t(-r) for r in reversed(roots))), "(%s, 0)，x = %s" % (t(h), t(h)),
                          "(0, %s)，x = %s" % (t(h), rs), "(%s, 0)，x = %s" % (t(h + 1), rs)])
    ex = lambda hh, ss, mm, v=0.0: cub(mm * mm, hh, v, ss)
    one = ("-(" if s < 0 else "(") + "pow(%s,3)+%s*%s)" % ("(x-%s)" % float(h) if h > 0 else ("(x+%s)" % float(-h) if h < 0 else "x"), float(m * m),
                                                            "(x-%s)" % float(h) if h > 0 else ("(x+%s)" % float(-h) if h < 0 else "x"))
    gs = [g_small(ex(h, s, m), "", xr, yr), g_small(ex(h, -s, m), "", xr, yr), g_small(ex(-h if h != 0 else 1, s, m), "", xr, yr),
          g_small(one, "", xr, yr), g_small(ex(h, s, m, 1.0), "", xr, yr)]
    lead = "負" if s < 0 else "正"
    whys = ["", "首項係數是%s的，往右要越來越%s" % (lead, "低" if s < 0 else "高"), "對稱中心在 (%s, 0)，位置不對" % t(-h if h != 0 else 1),
            "這張只和 x 軸交一點", "這張往上移了 1，對稱中心不在 x 軸上"]
    return item("pg_which", "graph", 1, "認出三次函數", 1.0,
                "下列哪一張是 y = %s 的圖形？" % stem_f,
                [ch("它的對稱中心和 x 截距是？", opts, "令 t = %s：y = %s" % (xs.strip("()"), "−t(t − %d)(t + %d)" % (m, m) if s < 0 else "t(t − %d)(t + %d)" % (m, m)),
                    "t = %s：對稱中心 (%s, 0)，x = %s" % (xs.strip("()"), t(h), rs)),
                 pick("哪一張是它的圖形？", gs, whys,
                      "首項 %sx^{3}：往右越來越%s，對稱中心 (%s, 0)，和 x 軸交三點" % ("−" if s < 0 else "", "低" if s < 0 else "高", t(h)),
                      "往右越來越%s、對稱中心 (%s, 0)、交 x 軸於 %s" % ("低" if s < 0 else "高", t(h), rs))])


# ---------- pg_lineparab：拋物線與直線 ----------

def pg_lineparab(A, B, xr, yr):
    pq = lambda a_, b_, c_=0: "%s*x*x+%s*x+%s" % (float(a_), float(b_), float(c_))
    ln_ = lambda a_, b_: "%s*x+%s" % (float(a_), float(b_))
    gs = [g_small(pq(A, B), "", xr, yr, ln_(A, B)), g_small(pq(A, B), "", xr, yr, ln_(-A, -B)), g_small(pq(A, B), "", xr, yr, ln_(A, -B)),
          g_small(pq(-A, -B), "", xr, yr, ln_(A, B)), g_small(pq(A, B, 1), "", xr, yr, ln_(A, B))]
    whys = ["", "開口向%s ⇒ a %s 0，直線的斜率 a 也要是%s的" % ("上" if A > 0 else "下", ">" if A > 0 else "<", "正" if A > 0 else "負"),
            "直線的 x 截距要等於拋物線的另一個根",
            "開口向%s ⇒ a %s 0，直線卻往右%s" % ("下" if A > 0 else "上", "<" if A > 0 else ">", "上升" if A > 0 else "下降"),
            "y = ax^{2} + bx 一定通過原點"]
    return item("pg_lineparab", "graph", 2, "拋物線與直線", 1.0,
                "a、b 都不是 0。y = ax^{2} + bx（實線）和 y = ax + b（虛線）畫在同一個坐標平面上，可能是哪一張？",
                [ch("直線 y = ax + b 的 x 截距是 −b/a。拋物線 y = ax^{2} + bx 的 x 截距是？", ["0 和 −b/a", "0 和 b/a", "只有 0", "0 和 −a/b"],
                    "ax^{2} + bx = x(ax + b)", "ax^{2} + bx = x(ax + b)：直線的 x 截距 −b/a 也是拋物線的根"),
                 pick("哪一張可能正確？", gs, whys, "開口方向 ↔ 直線斜率 a 的正負，直線一定穿過拋物線的另一個 x 截距，拋物線過原點",
                      "開口 ↔ 斜率同號，直線過拋物線的另一個根，拋物線過原點")])


# ---------- pg_mult：重根的樣子 ----------

def pg_mult(s, r3, r2, xr, yr):
    """y = s(x − r3)^3 (x − r2)^2"""
    px = lambda r: "(x-%s)" % float(r) if r > 0 else ("(x+%s)" % float(-r) if r < 0 else "x")
    e = lambda ss, a3, m3, a2, m2: ("-" if ss < 0 else "") + "pow(%s,%d)*pow(%s,%d)" % (px(a3), m3, px(a2), m2)
    gs = [g_small(e(s, r3, 3, r2, 2), "", xr, yr), g_small(e(-s, r3, 3, r2, 2), "", xr, yr), g_small(e(s, r3, 2, r2, 3), "", xr, yr),
          g_small(e(s, r3, 3, r2, 1), "", xr, yr), g_small(e(s, -r3, 3, -r2, 2), "", xr, yr)]
    lead = "−x^{5}" if s < 0 else "x^{5}"
    side = "左高右低" if s < 0 else "左低右高"
    whys = ["", "首項係數是%s的（%s），往右要越來越%s" % ("負" if s < 0 else "正", lead, "低" if s < 0 else "高"),
            "這張在 x = %s 彈回、x = %s 穿過，反了" % (t(r3), t(r2)), "這張在 x = %s 穿過去" % t(r2),
            "交點的位置在 %s 和 %s，不對" % (t(-r3), t(-r2))]
    a_, b_ = sorted([r3, r2])
    opts_all = {(True, False): "%s 穿過、%s 彈回", (False, True): "%s 彈回、%s 穿過"}
    first_is_3 = a_ == r3
    right = ("%s 穿過、%s 彈回" if first_is_3 else "%s 彈回、%s 穿過") % (t(a_), t(b_))
    wrong1 = ("%s 彈回、%s 穿過" if first_is_3 else "%s 穿過、%s 彈回") % (t(a_), t(b_))
    return item("pg_mult", "graph", 3, "重根的樣子", 1.1,
                "下列哪一張最可能是 y = %s%s^{3}%s^{2} 的圖形？" % ("−" if s < 0 else "", fac(r3), fac(r2)),
                [ch("圖形在 x = %s、x = %s 怎麼經過 x 軸？" % (t(a_), t(b_)), [right, wrong1, "兩個都穿過", "兩個都彈回"],
                    "奇數次的因式會穿過 x 軸（3 次的在交點附近變平坦），偶數次的只碰一下",
                    "%s^{3}：穿過、變平坦　%s^{2}：碰一下彈回" % (fac(r3), fac(r2))),
                 pick("哪一張最可能是它的圖形？", gs, whys,
                      "首項 %s：%s，%s 平坦地穿過，%s 碰一下彈回" % (lead, side, t(r3), t(r2)),
                      "首項 %s：%s，%s 平坦穿過、%s 碰一下" % (lead, side, t(r3), t(r2)))])


def items():
    return [
        [pg_shift(3, 2, 1), pg_shift(3, -1, 2), pg_shift(4, 1, -2)],
        [pg_scale(4, 3, (-4.0, 4.0), (-5.0, 5.0)), pg_scale(2, 2, (-5.0, 5.0), (-4.0, 4.0)), pg_scale(8, 4, (-5.0, 5.0), (-5.0, 5.0))],
        [pg_flip(1, -1), pg_flip(-1, 1), pg_flip(1, 1)],
        [pg_pair(1, -2, 1, (-3.0, 3.5), (-4.0, 6.0)), pg_pair(-1, -2, 2, (-3.5, 3.0), (-5.0, 5.0)), pg_pair(1, 3, -1, (-3.5, 3.0), (-5.0, 5.0))],
        [pg_which(-1, -1, 1, (-3.5, 2.5), (-3.0, 3.0)), pg_which(1, 1, 1, (-2.5, 3.5), (-3.0, 3.0)), pg_which(-1, 1, 2, (-2.5, 4.5), (-4.0, 4.0))],
        [pg_lineparab(1, -2, (-3.0, 4.0), (-4.0, 5.0)), pg_lineparab(-1, -2, (-4.0, 3.0), (-5.0, 4.0)), pg_lineparab(1, 3, (-4.5, 2.5), (-4.0, 5.0))],
        [pg_mult(-1, -1, 2, (-2.4, 3.2), (-12.0, 12.0)), pg_mult(1, 1, -2, (-3.2, 2.4), (-12.0, 12.0)), pg_mult(-1, 2, -1, (-2.2, 3.4), (-12.0, 12.0))],
    ]
