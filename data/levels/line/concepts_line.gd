extends RefCounted
## 直線與圓單元（C1～C8）的「觀念整理」卡片內容（介面在 concept_deck.gd，入口在 concept_cards.gd）
## 卡片的寫法見 concepts_exp.gd 開頭的說明（?{…} 先藏起來、[b]…[/b] 強調、check 隨堂小測、kind = "order" 拼流程）。
const UITheme := preload("res://data/ui/game_theme.gd")


static func cards(level: String) -> Array:
	match level:
		"C1":
			return [
				{"title": "中點與距離", "decoys": ["相減除以 2", "x 差 + y 差"], "tag": "公式", "glyph": "M",
				 "formulas": ["中點 M = (?{\\frac{x₁ + x₂}{2}}, ?{\\frac{y₁ + y₂}{2}})", "\\ol{AB} = ?{√((x₂ − x₁)^{2} + (y₂ − y₁)^{2})}"],
				 "notes": ["距離就是橫向、縱向走的格數用 ?{畢氏定理}", "常見的畢氏數：3、4、5，?{5、12、13}，8、15、17"],
				 "example": "A(−1, 2)、B(5, 6)：M = (2, 4)，\\ol{AB} = √(36 + 16) = 2√13",
				 "check": {"q": "A(1, 1)、B(4, 5) 的距離是？", "opts": ["5", "7", "25"], "a": 0,
					"why": "橫向 3、縱向 4：√(9 + 16) = 5。", "hint": "3、4、5。"}},
				{"title": "分點公式", "decoys": ["\\frac{m·A + n·B}{m + n}", "\\frac{A + B}{m + n}"], "tag": "公式", "glyph": "m : n",
				 "formulas": ["P 在 \\ol{AB} 上、\\ol{AP} : \\ol{PB} = m : n ⇒ P = ?{\\frac{n·A + m·B}{m + n}}"],
				 "notes": ["P 離 ?{B} 越近，B 的權重越大（權重交叉放）", "也可以想成：從 A 往 B 走全程的 ?{\\frac{m}{m + n}}"],
				 "example": "A(−2, 1)、B(6, 5)、\\ol{AP} : \\ol{PB} = 3 : 1 ⇒ P = \\frac{A + 3B}{4} = (4, 4)",
				 "trap": "\\ol{AP} : \\ol{PB} = 3 : 1，A 的權重是 [b]1[/b]、B 的權重是 [b]3[/b]，不是反過來！",
				 "check": {"q": "\\ol{AP} : \\ol{PB} = 2 : 3，P = ？", "opts": ["\\frac{3A + 2B}{5}", "\\frac{2A + 3B}{5}", "\\frac{A + B}{2}"], "a": 0,
					"why": "\\ol{AP} 比較短，P 靠近 A，A 的權重比較大（3）。", "hint": "靠近誰，誰的權重就大。"}},
				{"title": "平行四邊形的第四點", "decoys": ["A + B = C + D", "1 種"], "tag": "技巧", "glyph": "▱",
				 "formulas": ["平行四邊形 ABCD：?{A + C = B + D}（對角線中點相同）"],
				 "notes": ["只給三點、沒說順序：第四點有 ?{3} 種", "D 的對角頂點是誰，就把另外兩點加起來減掉它"],
				 "example": "A(1, 1)、B(5, 2)、C(6, 5)，ABCD ⇒ D = A + C − B = (2, 4)",
				 "check": {"q": "平行四邊形 ABCD：A(0, 0)、B(3, 0)、C(4, 2)，D = ？", "opts": ["(1, 2)", "(7, 2)", "(−1, −2)"], "a": 0,
					"why": "D = A + C − B = (1, 2)。", "hint": "A + C = B + D。"}},
				{"title": "斜率", "decoys": ["\\frac{x₂ − x₁}{y₂ − y₁}", "鉛直線斜率 0"], "tag": "定義", "glyph": "m",
				 "formulas": ["m = ?{\\frac{y₂ − y₁}{x₂ − x₁}}：往右走 1 格，往上走 m 格"],
				 "notes": ["m > 0 往 ?{右上}、m < 0 往 ?{右下}", "水平線 m = ?{0}，鉛直線 ?{沒有斜率}",
					"共線 ⇔ 斜率 ?{相等}，垂直 ⇔ 斜率相乘 ?{−1}"],
				 "example": "A(−1, −2)、B(3, 4)：m = \\frac{6}{4} = \\frac{3}{2}",
				 "check": {"q": "斜率 2 的直線，和它垂直的直線斜率是？", "opts": ["−\\frac{1}{2}", "\\frac{1}{2}", "−2"], "a": 0,
					"why": "2 × (−\\frac{1}{2}) = −1。", "hint": "倒數再變號。"}},
				{"title": "三角形的三心", "decoys": ["重心到三頂點等距", "垂心是中線的交點"], "tag": "定義", "glyph": "△",
				 "formulas": ["重心 G = ?{三頂點坐標的平均}，是三條 ?{中線} 的交點", "外心：三條 ?{中垂線} 的交點，到 ?{三頂點} 等距",
					"垂心：三條 ?{高} 的交點"],
				 "notes": ["重心把中線分成 ?{2 : 1}（靠頂點那段長）", "∠A 的平分線交 \\ol{BC} 於 D ⇒ \\ol{BD} : \\ol{DC} = ?{\\ol{AB} : \\ol{AC}}"],
				 "example": "A(0, 0)、B(8, 0)、C(2, 6) 的外心 (4, 2)",
				 "check": {"q": "到三角形三個頂點等距離的點是？", "opts": ["外心", "重心", "垂心"], "a": 0,
					"why": "外接圓的圓心到三個頂點都是半徑。", "hint": "外接圓。"}},
			]
	return []
