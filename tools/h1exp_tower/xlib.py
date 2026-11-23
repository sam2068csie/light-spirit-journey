# 指數與常用對數（高一上）的終焉之塔：共用工具
#   a + b√n、數值驗算、審判卡、步驟借用 tools/towerlib/tlib.py（它再借同資料夾的 lib.py）。
#   和高二的塔（tools/explog_tower）分開：這座只用常用對數，不用換底、對數函數圖形、指對數方程式。
import os, sys, math
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "towerlib"))   # 放最後：t_*.py 同名的要用這座塔自己的
from tlib import *          # noqa: F401,F403

L2, L3, L7 = 0.3010, 0.4771, 0.8451      # 題目給的近似值
S = math.sqrt
lg = math.log10


def dec(x, n):
    """x 四捨五入到小數點後 n 位的字串（去掉不必要的 0 以外，保留 n 位）"""
    s = "%.*f" % (n, x + (1e-12 if x >= 0 else -1e-12))
    return s.replace("-", "−")


def sci(x, n):
    """x 寫成 n 位有效數字的科學記號：(係數字串, 指數)"""
    e = math.floor(lg(abs(x)))
    m = x / 10 ** e
    ms = "%.*f" % (n - 1, m + 1e-12)
    if float(ms) >= 10:
        e += 1
        ms = "%.*f" % (n - 1, x / 10 ** e + 1e-12)
    return ms, e


def pw(b, e):
    """b^{e}"""
    return "%s^{%s}" % (b, tf(e))


def half_pow(base, e):
    """base^e（e 是整數或半整數）的答案字串：√2、√3/3、4√2"""
    e = F(e)
    if isint(e):
        return a(F(base) ** int(e))
    assert e.denominator == 2
    n = math.floor(e)
    return Surd(F(base) ** n, base).ans()


def jcards(specs):
    """[(敘述, 理由, 真假的算法)]：真假由程式算"""
    out = []
    for s, why, f in specs:
        ok = bool(f()) if callable(f) else bool(f)
        out.append(cardc(s, ok, why, ok))
    return out
