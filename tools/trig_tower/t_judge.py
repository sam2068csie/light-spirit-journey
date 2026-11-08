# 判讀羅盤（多選、是非）
#   觀念題的每一組卡片是手挑的，但每一張的真假都用數值驗算（cardc 會 assert）。
from tlib import *

sin, cos, tan = math.sin, math.cos, math.tan


def grid(lo, hi, n=4000, open_=True):
    """開區間裡的取樣點"""
    if open_:
        return [lo + (hi - lo) * (i + 0.5) / n for i in range(n)]
    return [lo + (hi - lo) * i / n for i in range(n + 1)]


def always(f, lo, hi):
    return all(f(x) for x in grid(lo, hi))


# ---------- tj_radian：沒有度的角 ----------

def tj_radian(cards):
    return item("tj_radian", "judge", 1, "沒有度的角", 1.0,
                "角度沒寫 ° 的都是弧度。不查表，判斷下列敘述。",
                [jd("1 弧度 ≈ 57.3°，先把角換成大約的度數，看在第幾象限。", [cardc(*c) for c in cards])])


D = PI / 180
RADIAN = [
    [("sin 2 > sin 1", True, "sin 2 = sin(π − 2)，π − 2 ≈ 1.14 比 1 大，而且都在第一象限", sin(2) > sin(1)),
     ("cos 3 > 0", False, "3 ≈ 172°，在第二象限，cos 3 < 0", cos(3) > 0),
     ("tan 4 > 0", True, "4 ≈ 229°，在第三象限，tan 是正的", tan(4) > 0),
     ("sin 6 < 0", True, "6 ≈ 344°，在第四象限", sin(6) < 0),
     ("sin 1° > sin 1", False, "1° 比 1 弧度（≈ 57.3°）小很多，sin 1° 比較小", sin(D) > sin(1))],
    [("sin 3 > sin 2", False, "sin 3 = sin(π − 3)，π − 3 ≈ 0.14，比 π − 2 ≈ 1.14 小", sin(3) > sin(2)),
     ("cos 2 < 0", True, "2 ≈ 115°，在第二象限", cos(2) < 0),
     ("tan 5 > 0", False, "5 ≈ 286°，在第四象限，tan 是負的", tan(5) > 0),
     ("sin 4 < 0", True, "4 ≈ 229°，在第三象限", sin(4) < 0),
     ("cos 1 > cos 1°", False, "1° 很小，cos 1° 幾乎是 1；1 弧度 ≈ 57.3°，cos 1 ≈ 0.54", cos(1) > cos(D))],
    [("sin 1 > cos 1", True, "1 > π/4 ≈ 0.79，過了 π/4 之後 sin 比 cos 大", sin(1) > cos(1)),
     ("cos 4 > 0", False, "4 ≈ 229°，在第三象限，cos 4 < 0", cos(4) > 0),
     ("tan 2 < 0", True, "2 ≈ 115°，在第二象限，tan 是負的", tan(2) < 0),
     ("sin 5 > 0", False, "5 ≈ 286°，在第四象限", sin(5) > 0),
     ("sin 2° < sin 2", True, "2° 很小，sin 2° ≈ 0.03；sin 2 ≈ 0.91", sin(2 * D) < sin(2))],
]


# ---------- tj_sign：象限與正負 ----------

def tj_sign(o, d, h, quad):
    """tan θ = −o/d；quad = 2 或 4"""
    assert o * o + d * d == h * h
    s = F(o, h) * (1 if quad == 2 else -1)
    c = F(d, h) * (-1 if quad == 2 else 1)
    assert near(s / c, F(-o, d))
    rng = "π/2 < θ < π" if quad == 2 else "3π/2 < θ < 2π"
    half_q, half_txt, half_why = (("第一", "θ/2 在第一象限", "π/4 < θ/2 < π/2") if quad == 2 else
                                  ("第二", "θ/2 在第二象限", "3π/4 < θ/2 < π"))
    th = math.atan2(float(s), float(c)) % (2 * PI)
    hq = int((th / 2) // (PI / 2)) + 1
    assert hq == (1 if quad == 2 else 2)
    sc = s + c
    c2 = c * c - s * s
    t_half = (1 - c) / s
    wrong = s / (1 - c)
    assert wrong != t_half
    assert near(t_half, math.tan(th / 2))
    sign_txt = "第二象限：sin θ > 0、cos θ < 0" if quad == 2 else "第四象限：sin θ < 0、cos θ > 0"
    return item("tj_sign", "judge", 1, "象限與正負", 1.15,
                "tan θ = %s，且 %s。下列敘述哪些正確？" % (t(F(-o, d)), rng),
                [fl("%s。直角三角形的邊是 %d、%d、%d：" % (sign_txt, o, d, h), "sin θ = [0]，cos θ = [1]", [a(s), a(c)],
                    "斜邊 √{%d + %d} = %d，%s 加負號" % (o * o, d * d, h, "cos" if quad == 2 else "sin")),
                 jd("用上面的 sin θ、cos θ 判斷每一張。", [
                     cardc("sin θ + cos θ = %s" % t(sc), True, "%s + %s" % (t(s), tp(c)), True),
                     cardc("cos 2θ = %s" % t(c2), True, "cos^{2}θ − sin^{2}θ = (%d − %d)/%d" % (d * d, o * o, h * h), near(c2, math.cos(2 * th))),
                     cardc("sin 2θ > 0", False, "2 sin θ cos θ = 2 · (%s) · (%s) < 0" % (t(s), t(c)), math.sin(2 * th) > 0),
                     cardc(half_txt, True, half_why, True),
                     cardc("tan(θ/2) = %s" % t(wrong), False,
                           "tan(θ/2) = (1 − cos θ)/sin θ = (%s)/(%s) = %s" % (t(1 - c), t(s), t(t_half)), near(wrong, t_half))])])


# ---------- tj_period：週期 ----------

def fund_period(f, p):
    """p 是 f 的（最小）週期：f(x + p) = f(x)，而且 p/2、p/3、p/4、p/6 都不是"""
    xs = [0.1 + 0.37 * i for i in range(40)]
    ok = all(abs(f(x + p) - f(x)) < 1e-7 for x in xs if abs(cos(x)) > 1e-3)
    for k in (2, 3, 4, 6):
        if all(abs(f(x + p / k) - f(x)) < 1e-7 for x in xs):
            return False
    return ok


def tj_period(ptxt, p, q, cards):
    return item("tj_period", "judge", 1, "挑出週期", 1.0,
                "下列哪些函數的週期是 %s？" % ptxt,
                [jd(q, [cardc(s, ok, why, fund_period(f, p)) for s, ok, why, f in cards])])


PERIOD = [
    ("π", PI, "先化成 sin、cos 一次的樣子，或想想絕對值把圖形怎麼折。", [
        ("y = |sin x|", True, "負的那一半翻上來，每 π 重複一次", lambda x: abs(sin(x))),
        ("y = cos^{2} x", True, "cos^{2} x = (1 + cos 2x)/2", lambda x: cos(x) ** 2),
        ("y = tan(x/2)", False, "週期是 π/(1/2) = 2π", lambda x: tan(x / 2)),
        ("y = sin 2x + cos x", False, "兩個週期 π、2π 的最小公倍數是 2π", lambda x: sin(2 * x) + cos(x)),
        ("y = |sin x + cos x|", True, "= |√{2} sin(x + π/4)|，週期 π", lambda x: abs(sin(x) + cos(x)))]),
    ("π/2", PI / 2, "先化成 sin、cos 一次的樣子，再用 2π/k、π/k。", [
        ("y = |sin 2x|", True, "sin 2x 的週期 π，負的翻上來再減半", lambda x: abs(sin(2 * x))),
        ("y = tan 2x", True, "tan kx 的週期是 π/k", lambda x: tan(2 * x)),
        ("y = sin^{2} x", False, "= (1 − cos 2x)/2，週期 π", lambda x: sin(x) ** 2),
        ("y = sin 4x + cos 2x", False, "兩個週期 π/2、π 的最小公倍數是 π", lambda x: sin(4 * x) + cos(2 * x)),
        ("y = sin 4x cos 4x", False, "= (1/2) sin 8x，週期 π/4", lambda x: sin(4 * x) * cos(4 * x))]),
    ("2π", 2 * PI, "兩個週期加起來取最小公倍數；絕對值會讓週期減半。", [
        ("y = sin x + cos x", True, "= √{2} sin(x + π/4)，週期 2π", lambda x: sin(x) + cos(x)),
        ("y = |sin x|", False, "負的那一半翻上來，週期變成 π", lambda x: abs(sin(x))),
        ("y = sin x + sin 2x", True, "兩個週期 2π、π 的最小公倍數是 2π", lambda x: sin(x) + sin(2 * x)),
        ("y = tan x", False, "tan x 的週期是 π", lambda x: tan(x)),
        ("y = cos(x/2)", False, "週期 2π/(1/2) = 4π", lambda x: cos(x / 2))]),
]


# ---------- tj_shift：伸縮平移的順序 ----------

def tj_shift(cards):
    return item("tj_shift", "judge", 2, "伸縮平移的順序", 1.15,
                "把 y = sin x 的圖形做下列變換，哪些敘述正確？（水平伸縮以 y 軸為基準）",
                [jd("平移：x 換成 x ∓ h。伸縮：x 換成 x/k。照順序換。",
                    [cardc(s, ok, why, all(abs(g(x) - f(x)) < 1e-9 for x in grid(-3, 3, 50))) for s, ok, why, g, f in cards])])


SHIFT = [
    [("右移 π/3：y = sin(x − π/3)", True, "右移 h：x 換成 x − h", lambda x: sin(x - PI / 3), lambda x: sin(x - PI / 3)),
     ("先水平縮成 1/2 倍、再左移 π/6：y = sin(2x + π/6)", False, "先得 sin 2x，再左移：sin 2(x + π/6) = sin(2x + π/3)",
      lambda x: sin(2 * (x + PI / 6)), lambda x: sin(2 * x + PI / 6)),
     ("先左移 π/6、再水平縮成 1/2 倍：y = sin(2x + π/6)", True, "先得 sin(x + π/6)，再把 x 換成 2x",
      lambda x: sin(2 * x + PI / 6), lambda x: sin(2 * x + PI / 6)),
     ("鉛直伸長 3 倍、再上移 1：y = 3 sin x + 1", True, "先乘 3 再加 1", lambda x: 3 * sin(x) + 1, lambda x: 3 * sin(x) + 1),
     ("左移 π/2：y = −cos x", False, "sin(x + π/2) = cos x", lambda x: sin(x + PI / 2), lambda x: -cos(x))],
    [("左移 π/4：y = sin(x + π/4)", True, "左移 h：x 換成 x + h", lambda x: sin(x + PI / 4), lambda x: sin(x + PI / 4)),
     ("先水平縮成 1/3 倍、再右移 π/12：y = sin(3x − π/12)", False, "先得 sin 3x，再右移：sin 3(x − π/12) = sin(3x − π/4)",
      lambda x: sin(3 * (x - PI / 12)), lambda x: sin(3 * x - PI / 12)),
     ("先右移 π/12、再水平縮成 1/3 倍：y = sin(3x − π/12)", True, "先得 sin(x − π/12)，再把 x 換成 3x",
      lambda x: sin(3 * x - PI / 12), lambda x: sin(3 * x - PI / 12)),
     ("鉛直伸長 2 倍、再下移 1：y = 2 sin x − 1", True, "先乘 2 再減 1", lambda x: 2 * sin(x) - 1, lambda x: 2 * sin(x) - 1),
     ("右移 π/2：y = −cos x", True, "sin(x − π/2) = −cos x", lambda x: sin(x - PI / 2), lambda x: -cos(x))],
    [("右移 π/6：y = sin(x − π/6)", True, "右移 h：x 換成 x − h", lambda x: sin(x - PI / 6), lambda x: sin(x - PI / 6)),
     ("先水平縮成 1/2 倍、再左移 π/4：y = sin(2x + π/4)", False, "先得 sin 2x，再左移：sin 2(x + π/4) = sin(2x + π/2)",
      lambda x: sin(2 * (x + PI / 4)), lambda x: sin(2 * x + PI / 4)),
     ("先左移 π/4、再水平縮成 1/2 倍：y = sin(2x + π/4)", True, "先得 sin(x + π/4)，再把 x 換成 2x",
      lambda x: sin(2 * x + PI / 4), lambda x: sin(2 * x + PI / 4)),
     ("鉛直伸長 4 倍、再上移 2：y = 4(sin x + 2)", False, "先乘 4 再加 2：y = 4 sin x + 2",
      lambda x: 4 * sin(x) + 2, lambda x: 4 * (sin(x) + 2)),
     ("左移 π：y = −sin x", True, "sin(x + π) = −sin x", lambda x: sin(x + PI), lambda x: -sin(x))],
]


# ---------- tj_sym：對稱軸與對稱中心 ----------

def kx(k):
    """2x、x/2、3x"""
    k = F(k)
    if k == 1:
        return "x"
    if isint(k):
        return "%dx" % k.numerator
    assert k.numerator == 1
    return "x/%d" % k.denominator


def tj_sym(A, k, ph, B, X2):
    """f(x) = A sin(kx − φπ) + B；X2：遞增的卡片的右端（π 的倍數）"""
    k, ph, X2 = F(k), F(ph), F(X2)
    f = lambda x: A * sin(float(k) * x - float(ph) * PI) + B
    T = 2 / k
    X1 = (F(1, 2) + ph) / k            # 對稱軸（最高點）
    X0 = ph / k                        # 對稱中心
    u_hi = k * X2 - ph
    assert -ph >= F(-1, 2) and u_hi > F(1, 2) and u_hi <= F(3, 2) and 0 < X1 < X2
    inc = all(f(x2) > f(x1) for x1, x2 in zip(grid(0, float(X2) * PI, 400, False)[:-1], grid(0, float(X2) * PI, 400, False)[1:]))
    assert abs(f(float(X1) * PI) - (A + B)) < 1e-9 and abs(f(float(X0) * PI) - B) < 1e-9
    assert B != 0
    fx_ = "%d sin(%s − %s)%s" % (A, kx(k), pt_(ph), (" + %d" % B) if B > 0 else (" − %d" % -B))
    return item("tj_sym", "judge", 2, "對稱軸與對稱中心", 1.2,
                "f(x) = %s。下列敘述哪些正確？" % fx_,
                [fl("先讀出基本資料：", "週期 = [0]π，中線 y = [1]，最大值 [2]", [a(T), a(B), a(A + B)],
                    "週期 2π/%s，中線是加在後面的 %s，最大值 %d %s" % (t(k) if isint(k) else "(" + t(k) + ")", t(B), A, ("+ %d" % B) if B > 0 else ("− %d" % -B))),
                 jd("令 u = %s − %s：u = π/2 + kπ 是對稱軸，u = kπ 是對稱中心。" % (kx(k), pt_(ph)), [
                     cardc("直線 x = %s 是圖形的對稱軸" % pt_(X1), True, "%s − %s = π/2 ⇒ x = %s（最高點）" % (kx(k), pt_(ph), pt_(X1)), True),
                     cardc("點 (%s, %s) 是圖形的對稱中心" % (pt_(X0), t(B)), True,
                           "%s − %s = 0 ⇒ x = %s，此時 f = %s（在中線上）" % (kx(k), pt_(ph), pt_(X0), t(B)), True),
                     cardc("f(x) 的最小值是 %s" % t(B - A), True, "%s + %s = %s" % (t(-A), tp(B), t(B - A)), True),
                     cardc("0 ≤ x ≤ %s 時，f(x) 遞增" % pt_(X2), False,
                           "u 從 %s 到 %s，過了 π/2（x = %s）就開始遞減" % (pt_(-ph), pt_(u_hi), pt_(X1)), inc),
                     cardc("點 (%s, 0) 是圖形的對稱中心" % pt_(X0), False, "對稱中心在中線 y = %s 上" % t(B), B == 0)])])


# ---------- tj_fold：疊合的性質 ----------

def tj_fold(cs, cc, r, ph):
    """f = cs sin x + cc cos x = r sin(x + φπ)；cs、cc、r 是 Q"""
    ph = F(ph)
    assert cs == r * cv(ph) and cc == r * sv(ph)
    f = lambda x: float(cs) * sin(x) + float(cc) * cos(x)
    xm = (F(1, 2) - ph) % 2
    assert abs(f(float(xm) * PI) - float(r)) < 1e-9
    c = r / 2
    s1, s2 = (F(1, 6) - ph) % 2, (F(5, 6) - ph) % 2
    sols = roots_in(lambda x: f(x) - float(c), 0, 2 * PI - 1e-9)
    assert len(sols) == 2
    assert all(abs(f(float(s) * PI) - float(c)) < 1e-9 for s in (s1, s2))
    sg = "−" if ph < 0 else "+"
    fx_ = lin_tr([(cs, "sin x"), (cc, "cos x")])
    abs_sum = (cs if cs > 0 else -cs) + (cc if cc > 0 else -cc)
    assert not near(abs_sum, r)
    phs = pt_(abs(ph))
    cphi, sphi = cv(abs(ph)), sv(abs(ph))
    inner = "sin x · %s %s cos x · %s" % (qt(cv(abs(ph))), sg, qt(sv(abs(ph))))
    s_lo, s_hi = sorted([s1, s2])
    return item("tj_fold", "judge", 2, "疊合的性質", 1.2,
                "f(x) = %s。下列敘述哪些正確？" % fx_,
                [fl("先疊合：%s = %s(%s)。" % (fx_, qt(r), inner), "f(x) = [0] sin(x %s [1]π)" % sg, [qa(r), a(abs(ph))],
                    "cos(%s) = %s、sin(%s) = %s" % (phs, qt(cphi), phs, qt(sphi))),
                 jd("用 f(x) = %s sin(x %s %s) 判斷每一張。" % (qt(r), sg, phs), [
                     cardc("f(x) 的週期是 2π", True, "sin 前面沒有乘倍數", True),
                     cardc("f(x) 的最大值是 %s" % abs_sum.text(), False, "最大值是 %s" % qt(r), near(abs_sum, r)),
                     cardc("x = %s 時 f(x) 有最大值" % pt_(xm), True, "x %s %s = π/2" % (sg, phs), True),
                     cardc("0 ≤ x < 2π 時，f(x) = %s 恰有兩個解" % qt(c), True,
                           "sin(x %s %s) = 1/2 ⇒ x %s %s = %s、%s ⇒ x = %s、%s" % (sg, phs, sg, phs, pt_(s_lo + ph), pt_(s_hi + ph), pt_(s_lo), pt_(s_hi)), len(sols) == 2),
                     cardc("y = f(x) 的圖形對稱於原點", False, "f(0) = %s ≠ 0，圖形不過原點" % qt(cc), abs(f(0)) < 1e-9)])])


# ---------- tj_always：恆成立嗎 ----------

def tj_always(lo, hi, cards):
    return item("tj_always", "judge", 1, "恆成立嗎", 1.0,
                "當 %s < x < %s 時，下列哪些不等式恆成立？" % (pt_(lo), pt_(hi)),
                [jd("先寫出 2x、x + π/4 的範圍。",
                    [cardc(s, ok, why, always(f, float(lo) * PI, float(hi) * PI)) for s, ok, why, f in cards])])


ALWAYS = [
    (F(1, 4), F(1, 2), [
        ("sin 2x > 0", True, "π/2 < 2x < π，第二象限 sin > 0", lambda x: sin(2 * x) > 0),
        ("cos 2x > 0", False, "第二象限 cos < 0", lambda x: cos(2 * x) > 0),
        ("sin x > cos x", True, "x > π/4 以後 sin 比 cos 大", lambda x: sin(x) > cos(x)),
        ("tan x > 1", True, "tan(π/4) = 1，tan 在這裡遞增", lambda x: tan(x) > 1),
        ("sin x + cos x > √{2}", False, "= √{2} sin(x + π/4)，最大才 √{2}，而且到不了", lambda x: sin(x) + cos(x) > S2)]),
    (F(1, 2), F(3, 4), [
        ("sin 2x < 0", True, "π < 2x < 3π/2，第三象限 sin < 0", lambda x: sin(2 * x) < 0),
        ("cos 2x > 0", False, "第三象限 cos < 0", lambda x: cos(2 * x) > 0),
        ("sin x + cos x > 0", True, "= √{2} sin(x + π/4)，3π/4 < x + π/4 < π，sin > 0", lambda x: sin(x) + cos(x) > 0),
        ("tan x < −1", True, "tan 從 −∞ 升到 tan(3π/4) = −1，還沒到", lambda x: tan(x) < -1),
        ("sin x + cos x > 1", False, "√{2} sin(x + π/4) 在 0 和 1 之間", lambda x: sin(x) + cos(x) > 1)]),
    (F(0), F(1, 6), [
        ("sin 2x < √{3}/2", True, "0 < 2x < π/3，sin 遞增，到不了 sin(π/3)", lambda x: sin(2 * x) < S3 / 2),
        ("cos 2x < 1/2", False, "0 < 2x < π/3，cos 2x 在 1/2 和 1 之間", lambda x: cos(2 * x) < 0.5),
        ("tan x < √{3}/3", True, "tan(π/6) = √{3}/3，tan 在這裡遞增", lambda x: tan(x) < S3 / 3),
        ("sin x < cos x", True, "x < π/4 時 cos 比 sin 大", lambda x: sin(x) < cos(x)),
        ("sin x + cos x > √{2}", False, "= √{2} sin(x + π/4)，最大才 √{2}", lambda x: sin(x) + cos(x) > S2)]),
]


# ---------- tj_case：兩種可能 ----------

def tj_case(sa, ca, sb, cb):
    """sin α = sa、sin β = sb（都 > 0），|cos α| = ca、|cos β| = cb"""
    assert sa * sa + ca * ca == 1 and sb * sb + cb * cb == 1
    cases = [(ca, -cb), (-ca, cb)]
    cm = [x * y + sa * sb for x, y in cases]          # cos(α − β)
    sp = [sa * y + x * sb for x, y in cases]          # sin(α + β)
    cp = [x * y - sa * sb for x, y in cases]          # cos(α + β)
    sm = [sa * y - x * sb for x, y in cases]          # sin(α − β)
    assert cm[0] == cm[1] and sp[0] != sp[1] and cp[0] == cp[1]
    pick_sm = max(sm)
    D_ = sa.denominator * sb.denominator
    fd = lambda x: (M if x < 0 else "") + "%d/%d" % (abs(x) * D_, D_)
    two = lambda p_, q_: "%s %s %s" % (fd(p_), "+" if q_ >= 0 else M, fd(abs(q_)))
    return item("tj_case", "judge", 3, "兩種可能", 1.35,
                "sin α = %s，sin β = %s，且 cos α · cos β < 0。下列敘述哪些正確？" % (t(sa), t(sb)),
                [fl("先算 cos 的大小。cos α · cos β < 0：一正一負，兩種情形都要算。", "(cos α, cos β) = (±[0], ∓[1])", [a(ca), a(cb)],
                    "%d、%d、%d 和 %d、%d、%d" % tuple(sorted([sa.numerator, ca.numerator]) + [sa.denominator] + sorted([sb.numerator, cb.numerator]) + [sb.denominator])),
                 jd("兩種情形都代進去，結果一樣才算「只有一個值」。", [
                     cardc("cos(α − β) 只有一個可能的值", True,
                           "cos α cos β + sin α sin β = %s = %s，兩種情形一樣" % (two(-ca * cb, sa * sb), t(cm[0])), cm[0] == cm[1]),
                     cardc("sin(α + β) 只有一個可能的值", False,
                           "第一種 %s = %s，第二種 %s = %s" % (two(sa * cases[0][1], cases[0][0] * sb), t(sp[0]), two(sa * cases[1][1], cases[1][0] * sb), t(sp[1])), sp[0] == sp[1]),
                     cardc("cos(α + β) = %s" % t(cp[0]), True, "cos α cos β − sin α sin β = %s" % two(-ca * cb, -sa * sb), True),
                     cardc("sin(α − β) 可能是 %s" % t(pick_sm), True,
                           "%s：sin α cos β − cos α sin β = %s" % ("第二種" if pick_sm == sm[1] else "第一種", two(sa * cases[sm.index(pick_sm)][1], -cases[sm.index(pick_sm)][0] * sb)), pick_sm in sm),
                     cardc("tan α tan β > 0", False, "sin α sin β > 0、cos α cos β < 0，所以 tan α tan β < 0", False)])])


# ---------- tj_compare：三個數比大小 ----------

def tj_compare(U, cards):
    lo, hi = 0.0, float(U) * PI
    return item("tj_compare", "judge", 3, "三個數比大小", 1.3,
                "0 < x < %s，a = sin x、b = tan(x/2)、c = sin(x°)。下列哪些恆成立？" % pt_(U),
                [jd("以切表弦：tan(x/2) = sin x/(1 + cos x)。x° 是 x 的 π/180 倍。",
                    [cardc(s, ok, why, always(lambda x: f(sin(x), tan(x / 2), sin(x * D)), lo, hi)) for s, ok, why, f in cards])])


COMPARE = [
    (F(1, 4), [
        ("a > b", True, "b = sin x/(1 + cos x)，分母大於 1", lambda a_, b_, c_: a_ > b_),
        ("b < c", False, "b > x/2 > πx/180 > c：x° 小非常多", lambda a_, b_, c_: b_ < c_),
        ("a > c", True, "x° 比 x 弧度小，sin 在 0 到 π/2 遞增", lambda a_, b_, c_: a_ > c_),
        ("a < √{2}/2", True, "x < π/4 ⇒ sin x < sin(π/4)", lambda a_, b_, c_: a_ < S2 / 2),
        ("2b < a", False, "2b = 2 sin x/(1 + cos x)，分母小於 2，所以 2b > a", lambda a_, b_, c_: 2 * b_ < a_)]),
    (F(1, 3), [
        ("b > a", False, "b = sin x/(1 + cos x)，分母大於 1，b 比較小", lambda a_, b_, c_: b_ > a_),
        ("c < b", True, "x° 是 x 的 π/180 倍，c 非常小", lambda a_, b_, c_: c_ < b_),
        ("a > c", True, "x° 比 x 弧度小，sin 在 0 到 π/2 遞增", lambda a_, b_, c_: a_ > c_),
        ("a > √{3}/2", False, "x < π/3 ⇒ sin x < sin(π/3) = √{3}/2", lambda a_, b_, c_: a_ > S3 / 2),
        ("2b > a", True, "2b = 2 sin x/(1 + cos x)，分母小於 2", lambda a_, b_, c_: 2 * b_ > a_)]),
    (F(1, 6), [
        ("a < 1/2", True, "x < π/6 ⇒ sin x < sin(π/6)", lambda a_, b_, c_: a_ < 0.5),
        ("b ≥ a", False, "1 + cos x > 1，b = sin x/(1 + cos x) 比 a 小", lambda a_, b_, c_: b_ >= a_),
        ("c > a", False, "x° 比 x 弧度小非常多", lambda a_, b_, c_: c_ > a_),
        ("b > c", True, "b > x/2，而 c < x°，x° 只有 x 的 π/180 倍", lambda a_, b_, c_: b_ > c_),
        ("a < 2b", True, "2b = 2 sin x/(1 + cos x)，分母小於 2", lambda a_, b_, c_: a_ < 2 * b_)]),
]


# ---------- tj_truefalse：觀念是非 ----------

def tj_truefalse(cards):
    return item("tj_truefalse", "judge", 2, "觀念是非", 1.15, "判斷下列敘述是否正確。",
                [jd("說「一定」的，找一個反例就是假的。", [cardc(*c) for c in cards])])


TF = [
    [("有實數 x 使得 cos x = 3/√{7}", False, "3/√{7} = √{9/7} > 1", 3 / math.sqrt(7) <= 1),
     ("若 sin 2x = sin 2y，且 0 < x、y < π/2，則 x = y", False, "反例 x = π/6、y = π/3：sin(π/3) = sin(2π/3)",
      not near(sin(PI / 3), sin(2 * PI / 3))),
     ("若 cos 2x = cos 2y，且 0 < x、y < π/2，則 x = y", True, "0 < 2x、2y < π，cos 在這裡一對一", True),
     ("0 ≤ θ ≤ π/2 時，sin θ ≤ θ", True, "單位圓上，弦（2 sin θ）比弧（2θ）短", always(lambda x: sin(x) <= x, 0, PI / 2)),
     ("tan 3 > 0", False, "3 ≈ 172°，在第二象限", tan(3) > 0)],
    [("有實數 x 使得 sin x = √{5}/2", False, "√{5}/2 ≈ 1.12 > 1", math.sqrt(5) / 2 <= 1),
     ("若 sin x = sin y，且 0 < x、y < π，則 x = y", False, "反例 x = π/6、y = 5π/6", not near(sin(PI / 6), sin(5 * PI / 6))),
     ("若 cos x = cos y，且 0 < x、y < π，則 x = y", True, "cos 在 0 到 π 一路遞減，一對一", True),
     ("0 < θ < π/2 時，tan θ > θ", True, "單位圓上，切線段比弧長", always(lambda x: tan(x) > x, 0, PI / 2)),
     ("cos 2 > 0", False, "2 ≈ 115°，在第二象限", cos(2) > 0)],
    [("有實數 x 使得 tan x = 100", True, "tan 的值域是全體實數", True),
     ("有實數 x 使得 sin x + cos x = 3/2", False, "sin x + cos x = √{2} sin(x + π/4)，最大 √{2} ≈ 1.41", S2 >= 1.5),
     ("若 tan x = tan y，則 x = y", False, "反例 x = 0、y = π", not near(tan(0), tan(PI))),
     ("sin 1 > sin 2", False, "sin 2 = sin(π − 2)，π − 2 ≈ 1.14 比 1 大", sin(1) > sin(2)),
     ("對所有實數 x，|sin x| ≤ |x|", True, "x 在 0 到 π/2 時弦比弧短，其他地方 |x| > 1", always(lambda x: abs(sin(x)) <= abs(x) + 1e-15, -10, 10))],
]


# ---------- tj_root：根號裡的倍角 ----------

def tj_root(lo, hi, cfg):
    lo, hi = F(lo), F(hi)
    xs = grid(float(lo) * PI, float(hi) * PI, 200)
    sp = 1 if all(sin(x) + cos(x) > 0 for x in xs) else -1
    sm = 1 if all(sin(x) - cos(x) > 0 for x in xs) else -1
    assert all((sin(x) + cos(x)) * sp > 0 and (sin(x) - cos(x)) * sm > 0 for x in xs)
    A = lambda x: math.sqrt(1 + sin(2 * x)) + math.sqrt(1 - sin(2 * x))
    form = {(1, 1): ("2 sin θ", lambda x: 2 * sin(x)), (-1, 1): ("−2 cos θ", lambda x: -2 * cos(x)),
            (-1, -1): ("−2 sin θ", lambda x: -2 * sin(x)), (1, -1): ("2 cos θ", lambda x: 2 * cos(x))}
    right, rf = form[(sp, sm)]
    assert all(abs(A(x) - rf(x)) < 1e-9 for x in xs)
    sg = lambda v: "+" if v > 0 else "−"
    pair = "(%s, %s)" % (sg(sp), sg(sm))
    opts = uniq([pair], ["(+, +)", "(−, +)", "(+, −)", "(−, −)"])
    wrong_form, wf = cfg["wrong"]
    th, aval = cfg["at"]
    assert not all(abs(A(x) - wf(x)) < 1e-9 for x in xs)
    val = Q.of(cfg["val"])
    truth_val = near(A(float(th) * PI), val)
    eq_card = cfg["eq"]
    return item("tj_root", "judge", 3, "根號裡的倍角", 1.35,
                "%s < θ < %s，A = √{1 + sin 2θ} + √{1 − sin 2θ}。下列哪些正確？" % (pt_(lo), pt_(hi)),
                [ch("1 ± sin 2θ = (sin θ ± cos θ)^{2}。在 %s < θ < %s，(sin θ + cos θ, sin θ − cos θ) 的正負是？" % (pt_(lo), pt_(hi)), opts,
                    cfg["hint"], "sin θ + cos θ %s 0，sin θ − cos θ %s 0（開根號要加絕對值）" % (">" if sp > 0 else "<", ">" if sm > 0 else "<")),
                 jd("√{x^{2}} = |x|：把絕對值拆開再判斷。", [
                     cardc("1 + sin 2θ = (sin θ + cos θ)^{2}", True, "sin^{2}θ + cos^{2}θ + 2 sin θ cos θ", True),
                     cardc(eq_card[0], eq_card[1], eq_card[2], eq_card[3](xs)),
                     cardc("A = %s" % right, True, cfg["why_right"], True),
                     cardc("A = %s" % wrong_form, False, cfg["why_wrong"], False),
                     cardc("θ = %s 時，A = %s" % (pt_(th), val.text()), aval, cfg["why_val"], truth_val)])])


ROOT = [
    (F(3, 4), 1, {"hint": "sin θ > 0、cos θ < 0，而且 |cos θ| > sin θ（越過 3π/4 了）",
                  "eq": ("√{1 + sin 2θ} = sin θ + cos θ", False, "sin θ + cos θ 是負的，要加負號",
                         lambda xs: all(abs(math.sqrt(1 + sin(2 * x)) - (sin(x) + cos(x))) < 1e-9 for x in xs)),
                  "why_right": "A = −(sin θ + cos θ) + (sin θ − cos θ)",
                  "wrong": ("2 sin θ", lambda x: 2 * sin(x)), "why_wrong": "這是兩個都當成正的才會得到的",
                  "at": (F(5, 6), True), "val": Q(0, 1, 3), "why_val": "−2 cos(5π/6) = √{3}"}),
    (F(1, 2), F(3, 4), {"hint": "sin θ > 0、cos θ < 0，而且 sin θ > |cos θ|（還沒到 3π/4）",
                        "eq": ("√{1 + sin 2θ} = sin θ + cos θ", True, "sin θ + cos θ 是正的，絕對值可以直接拿掉",
                               lambda xs: all(abs(math.sqrt(1 + sin(2 * x)) - (sin(x) + cos(x))) < 1e-9 for x in xs)),
                        "why_right": "A = (sin θ + cos θ) + (sin θ − cos θ)",
                        "wrong": ("−2 cos θ", lambda x: -2 * cos(x)), "why_wrong": "sin θ + cos θ 在這裡是正的，不用加負號",
                        "at": (F(2, 3), False), "val": Q(1), "why_val": "2 sin(2π/3) = √{3}，不是 1"}),
    (F(5, 4), F(3, 2), {"hint": "sin θ < 0、cos θ < 0，而且 |sin θ| > |cos θ|（越過 5π/4 了）",
                        "eq": ("√{1 − sin 2θ} = sin θ − cos θ", False, "sin θ − cos θ 是負的，要加負號",
                               lambda xs: all(abs(math.sqrt(1 - sin(2 * x)) - (sin(x) - cos(x))) < 1e-9 for x in xs)),
                        "why_right": "A = −(sin θ + cos θ) − (sin θ − cos θ)",
                        "wrong": ("−2 cos θ", lambda x: -2 * cos(x)), "why_wrong": "sin θ − cos θ 在這裡也是負的",
                        "at": (F(4, 3), True), "val": Q(0, 1, 3), "why_val": "−2 sin(4π/3) = √{3}"}),
]


# ---------- tj_graph：同一條波 ----------

def tj_graph(A, k, ph, plot_x, pi_n, pi_lab, cards):
    """y = A sin(kx + φπ)"""
    k, ph = F(k), F(ph)
    f = lambda x: A * sin(float(k) * x + float(ph) * PI)
    xm = (F(1, 2) - ph) / k
    xz = -ph / k
    assert abs(f(float(xm) * PI) - A) < 1e-9 and abs(f(float(xz) * PI)) < 1e-9
    assert plot_x[0] < float(xz) * PI < float(xm) * PI < plot_x[1]
    T = 2 / k
    xs = grid(-3, 3, 60)
    cs = []
    for s, ok, why, g in cards:
        cs.append(cardc(s, ok, why, all(abs(g(x) - f(x)) < 1e-9 for x in xs)))
    return item("tj_graph", "judge", 2, "同一條波", 1.2,
                "圖是一個正弦波的一部分，最高點 (%s, %d)、和 x 軸交於 (%s, 0)。下列哪些函數的圖形就是它？" % (pt_(xm), A, pt_(xz)),
                [jd("振幅 %d、週期 %s，最高點在 x = %s：代進去看是不是最大值。" % (A, pt_(T), pt_(xm)), cs)],
                plot={"x": plot_x, "y": [-A - 0.6, A + 0.6], "pi": pi_n, "pi_lab": pi_lab,
                      "curves": [{"f": "%d*sin(%s*x+%s)" % (A, repr(float(k)), repr(float(ph) * PI)), "c": "cyan"}],
                      "pts": [{"x": fx(float(xm) * PI), "y": A, "label": "(%s, %d)" % (pt_(xm), A)}, {"x": fx(float(xz) * PI), "y": 0, "label": ""}]})


GRAPH = [
    (2, 2, F(1, 3), [-1.2, 3.6], 12, 6, [
        ("y = 2 sin(2x + π/3)", True, "x = π/12：2x + π/3 = π/2", lambda x: 2 * sin(2 * x + PI / 3)),
        ("y = 2 cos(2x − π/6)", True, "x = π/12：2x − π/6 = 0，cos 0 = 1", lambda x: 2 * cos(2 * x - PI / 6)),
        ("y = −2 sin(2x − 2π/3)", True, "x = π/12：−2 sin(−π/2) = 2", lambda x: -2 * sin(2 * x - 2 * PI / 3)),
        ("y = 2 sin(2x + π/6)", False, "x = π/12：2 sin(π/3) = √{3}，不是最大值", lambda x: 2 * sin(2 * x + PI / 6)),
        ("y = 2 sin 2(x + π/3)", False, "= 2 sin(2x + 2π/3)，x = π/12 時是 2 sin(5π/6) = 1", lambda x: 2 * sin(2 * (x + PI / 3)))]),
    (3, 2, F(-1, 3), [-0.4, 4.0], 12, 6, [
        ("y = 3 sin(2x − π/3)", True, "x = 5π/12：2x − π/3 = π/2", lambda x: 3 * sin(2 * x - PI / 3)),
        ("y = 3 cos(2x − 5π/6)", True, "x = 5π/12：2x − 5π/6 = 0，cos 0 = 1", lambda x: 3 * cos(2 * x - 5 * PI / 6)),
        ("y = −3 sin(2x + 2π/3)", True, "x = 5π/12：−3 sin(3π/2) = 3", lambda x: -3 * sin(2 * x + 2 * PI / 3)),
        ("y = 3 sin(2x − π/6)", False, "x = 5π/12：3 sin(2π/3) = 3√{3}/2，不是最大值", lambda x: 3 * sin(2 * x - PI / 6)),
        ("y = 3 sin 2(x − π/3)", False, "= 3 sin(2x − 2π/3)，x = 5π/12 時是 3 sin(π/6) = 3/2", lambda x: 3 * sin(2 * (x - PI / 3)))]),
    (2, 3, F(1, 4), [-0.9, 2.5], 12, 4, [
        ("y = 2 sin(3x + π/4)", True, "x = π/12：3x + π/4 = π/2", lambda x: 2 * sin(3 * x + PI / 4)),
        ("y = 2 cos(3x − π/4)", True, "x = π/12：3x − π/4 = 0，cos 0 = 1", lambda x: 2 * cos(3 * x - PI / 4)),
        ("y = −2 sin(3x − 3π/4)", True, "x = π/12：−2 sin(−π/2) = 2", lambda x: -2 * sin(3 * x - 3 * PI / 4)),
        ("y = 2 sin(3x + π/12)", False, "x = π/12：2 sin(π/3) = √{3}，不是最大值", lambda x: 2 * sin(3 * x + PI / 12)),
        ("y = 2 sin 3(x + π/4)", False, "= 2 sin(3x + 3π/4)，x = π/12 時是 2 sin π = 0", lambda x: 2 * sin(3 * (x + PI / 4)))]),
]


def items():
    return [
        [tj_radian(c) for c in RADIAN],
        [tj_sign(8, 15, 17, 4), tj_sign(5, 12, 13, 2), tj_sign(7, 24, 25, 4)],
        [tj_period(*p) for p in PERIOD],
        [tj_shift(c) for c in SHIFT],
        [tj_sym(2, 2, F(1, 3), 1, F(1, 2)), tj_sym(3, 3, F(1, 4), -2, F(1, 3)), tj_sym(4, F(1, 2), F(1, 6), 2, 2)],
        [tj_fold(Q(0, 1, 3), Q(-1), Q(2), F(-1, 6)), tj_fold(Q(1), Q(0, 1, 3), Q(2), F(1, 3)),
         tj_fold(Q(3), Q(0, -3, 3), Q(6), F(-1, 3))],
        [tj_always(*c) for c in ALWAYS],
        [tj_case(F(4, 5), F(3, 5), F(5, 13), F(12, 13)), tj_case(F(3, 5), F(4, 5), F(12, 13), F(5, 13)),
         tj_case(F(8, 17), F(15, 17), F(3, 5), F(4, 5))],
        [tj_compare(*c) for c in COMPARE],
        [tj_truefalse(c) for c in TF],
        [tj_root(*c) for c in ROOT],
        [tj_graph(*c) for c in GRAPH],
    ]
