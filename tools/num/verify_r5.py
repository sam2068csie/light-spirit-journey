"""R5 篩種倉庫（有理數與無理數）：設計稿 docs/num_r5_design.md 的數字驗算。
用一個小小的「有理數 + 根號」精確運算（S），確認每顆種子是有理數還是無理數、比較係數和有理化的答案。
π、0.1010010001… 這種不循環的小數直接當作無理數（定義）。"""
from fractions import Fraction as F
from math import isqrt, sqrt, isclose


def sqfree(n):
    """n = k² m，m 沒有平方因數：回傳 (k, m)"""
    k, m, d = 1, n, 2
    while d * d <= m:
        while m % (d * d) == 0:
            m //= d * d
            k *= d
        d += 1
    return k, m


class S:
    """有理數係數的根號組合：{m: 係數}，m = 1 是有理數部分"""
    def __init__(self, terms=None):
        self.t = {m: F(c) for m, c in (terms or {}).items() if c != 0}

    @staticmethod
    def r(x):
        return S({1: F(x)})

    @staticmethod
    def root(n, c=1):
        k, m = sqfree(n)
        return S({m: F(c) * k})

    def __add__(self, o):
        o = o if isinstance(o, S) else S.r(o)
        t = dict(self.t)
        for m, c in o.t.items():
            t[m] = t.get(m, 0) + c
        return S(t)

    def __neg__(self):
        return S({m: -c for m, c in self.t.items()})

    def __sub__(self, o):
        return self + (-(o if isinstance(o, S) else S.r(o)))

    def __mul__(self, o):
        o = o if isinstance(o, S) else S.r(o)
        out = S()
        for m1, c1 in self.t.items():
            for m2, c2 in o.t.items():
                k, m = sqfree(m1 * m2)
                out = out + S({m: c1 * c2 * k})
        return out

    def div_single(self, o):
        """除以只有一項的數（有理數或 c√m）"""
        assert len(o.t) == 1
        (m, c), = o.t.items()
        return self * S({m: 1 / (c * m)}) if m != 1 else self * S.r(1 / c)

    def rational(self):
        return all(m == 1 for m in self.t)

    def val(self):
        return sum(float(c) * sqrt(m) for m, c in self.t.items())

    def __eq__(self, o):
        o = o if isinstance(o, S) else S.r(o)
        return (self - o).t == {}


rt = S.root

# 1 篩種子（第 1 組、第 2 組）：True = 有理數
seeds1 = {"√16": rt(16), "22/7": S.r(F(22, 7)), "0.3̅": S.r(F(1, 3)), "√8": rt(8), "√2 × √8": rt(2) * rt(8), "√2 + 1": rt(2) + 1}
want1 = {"√16": True, "22/7": True, "0.3̅": True, "√8": False, "√2 × √8": True, "√2 + 1": False}       # π、0.1010010001… 是無理數
seeds2 = {"√25": rt(25), "1.27̅": S.r(F(127 - 1, 99)), "−√9": -rt(9), "√12/√3": rt(12).div_single(rt(3)), "√12": rt(12), "√2/2": rt(2) * F(1, 2)}
want2 = {"√25": True, "1.27̅": True, "−√9": True, "√12/√3": True, "√12": False, "√2/2": False}       # π − 3、2.1211211121… 是無理數
for seeds, want in ((seeds1, want1), (seeds2, want2)):
    for k, v in seeds.items():
        assert v.rational() == want[k], k
assert S.r(F(127 - 1, 99)) == S.r(F(14, 11))                                    # 1.\ol{27} = \frac{14}{11}

# 2 算一算再篩
calc1 = {"√2 + (−√2)": rt(2) - rt(2), "0 × √5": rt(5) * 0, "√3 × √12": rt(3) * rt(12), "√18/√2": rt(18).div_single(rt(2)),
         "√3 + √3": rt(3) + rt(3), "3 + √2": rt(2) + 3, "√2 × √3": rt(2) * rt(3)}
calc2 = {"(1 + √3) + (2 − √3)": (rt(3) + 1) + (S.r(2) - rt(3)), "√6 × √6": rt(6) * rt(6), "√20/√5": rt(20).div_single(rt(5)),
         "√5 + 2√5": rt(5) + rt(5, 2), "4 − √3": S.r(4) - rt(3), "√2 × √5": rt(2) * rt(5)}
for calc, rats in ((calc1, 4), (calc2, 3)):
    assert sum(v.rational() for v in calc.values()) == rats                      # 0 × π 是有理數 0（第 2 組多一顆）

# 3 審判台：反例
a = rt(3) + 2
assert (a + S.r(1) * F(1)).rational() is False and (a + (S.r(2) - rt(3))).rational() and (a * (S.r(2) - rt(3))) == S.r(1)   # 1/(2 + √3) = 2 − √3
b = rt(2) + 1
assert not (b + (rt(2) - 1)).rational() and (b * (rt(2) - 1)) == S.r(1)                                                       # 1 + √2 不是反例
assert not (rt(2) + rt(2).div_single(S.r(2))).rational()                                                                      # √2 + \frac{1}{√2} 不是反例
# \frac{a√12 + b}{√3 + 1} 在 a = 1、b = 2 時是有理數：(2√3 + 2) ÷ (√3 + 1) = 2
assert (rt(12) + 2) == (rt(3) + 1) * 2
# a、b 有理，c、d 無理：a + c = 2 + √3 不一定 a = 2（a = 1、c = 1 + √3）
assert S.r(1) + (rt(3) + 1) == rt(3) + 2
# a + c = b + d 不一定 a = b（a = 0、b = 1、c = √2 + 1、d = √2）
assert S.r(0) + (rt(2) + 1) == S.r(1) + rt(2)

# 4 a、b 無理，a + b、ab 有理：用 a = 1 + √2、b = 1 − √2 找「不一定」的反例
a, b = rt(2) + 1, S.r(1) - rt(2)
assert (a + b).rational() and (a * b).rational() and not a.rational() and not b.rational()
assert (a * a + b * b).rational() and ((a - 1) * (b - 1)).rational() and not (a - b).rational()
q = a * (S.r(1) + rt(2)) * F(-1)                                                 # \frac{a}{b} = −(1 + √2)^{2}
assert isclose(q.val(), a.val() / b.val()) and not q.rational()
assert (a * a * b + a * b * b).rational() and not (a * a - b * b).rational()      # 第 2 組：a^{2}b + ab^{2} 一定、a^{2} − b^{2} 不一定

# 6 比較係數
for lhs, rhs, ab in [(lambda a, b: (rt(3) + 2) * a + (S.r(1) - rt(3)) * b, S.r(7) - rt(3), (2, 3)),
                     (lambda a, b: (rt(2, 2) + 1) * a + (S.r(3) - rt(2)) * b, rt(2, 7) + 7, (4, 1))]:
    assert lhs(S.r(ab[0]), S.r(ab[1])) == rhs
assert 2 * 2 + 3 == 7 and 2 - 3 == -1 and 4 + 3 * 1 == 7 and 2 * 4 - 1 == 7

# 7 秤盤的條件：反例 (a, b, c, d) = (√2, 0, 0, 1)
assert rt(2) + rt(2) * 0 == S.r(0) + rt(2) * 1

# 8 反證法：√5 − √2 = r ⇒ √2 = \frac{3 − r^{2}}{2r}；√7 − √3 = r ⇒ √3 = \frac{4 − r^{2}}{2r}
for p, q, top in ((5, 2, 3), (7, 3, 4)):
    r = sqrt(p) - sqrt(q)
    assert isclose((top - r * r) / (2 * r), sqrt(q)) and p - q == top

# 9 分母有理化
assert rt(3) * 2 * rt(3) == S.r(6) and (rt(5) + 1) * (rt(5) - 1) == S.r(4)
assert rt(5) * 2 * rt(5) == S.r(10) and (rt(7) - 1) * (rt(7) + 1) == S.r(6)

# 10 三項的分母
d1 = (S.r(1) + rt(2) + rt(3)) * (S.r(1) + rt(2) - rt(3))
assert d1 == rt(2, 2)
ans1 = S.r(4) + rt(2, 2) - rt(6, 2)
assert ans1 * (S.r(1) + rt(2) + rt(3)) == S.r(8)
d2 = (rt(2) + rt(3) + rt(5)) * (rt(2) + rt(3) - rt(5))
assert d2 == rt(6, 2)
ans2 = rt(3, 2) + rt(2, 3) - rt(30)
assert ans2 * (rt(2) + rt(3) + rt(5)) == S.r(12)
print("R5 verify OK")
