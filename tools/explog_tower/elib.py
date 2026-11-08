# 指數與對數的終焉之塔：共用工具
#   a + b√n、數值驗算、審判卡、步驟借用 tools/trig_tower/tlib.py（它再借 tools/line_tower/lib.py）。
import os, sys, math
sys.path.append(os.path.join(os.path.dirname(__file__), "..", "trig_tower"))   # 放最後：t_*.py 同名的要用指對數自己的
from tlib import *          # noqa: F401,F403

L2, L3 = 0.3010, 0.4771      # 題目給的 log 2、log 3
LG = {1: 0.0, 2: L2, 3: L3, 4: 2 * L2, 5: 1 - L2, 6: L2 + L3, 8: 3 * L2, 9: 2 * L3, 10: 1.0}


def lead_digit(fr):
    """首位數字：fr 是小數部分（用題目給的近似值），回傳 (數字, 下界的 log 名稱, 上界的 log 名稱)"""
    ks = [1, 2, 3, 4, 5, 6, 8, 9, 10]
    for lo, hi in zip(ks, ks[1:]):
        if LG[lo] <= fr < LG[hi]:
            if lo == 6:
                return None          # 6、7 之間需要 log 7，不出這種
            return lo, lo, hi
    return None


def tf3(x):
    return "%.3f" % x


def exp_t(b, e):
    """b^{e}：e 可以是字串"""
    return "%s^{%s}" % (b, e)


def quad_t(a_, b_, c_, v="x"):
    return poly([(a_, v + "^{2}"), (b_, v), (c_, "")])


def fac_t(a1, c1, a2, c2, v="t"):
    """(a1 v + c1)(a2 v + c2)"""
    def one(a_, c_):
        return "(" + poly([(a_, v), (c_, "")]) + ")"
    return one(a1, c1) + one(a2, c2)


def logb(b):
    """log 的底數寫法：10 → log、2 → log_{2}"""
    return "log" if b == 10 else "log_{%s}" % b


def lg(b, x):
    return math.log(x) / math.log(b)
