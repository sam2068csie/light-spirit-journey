extends RefCounted
## 高二「平面向量」單元（V1～V8）的「觀念整理」卡片內容（介面在 concept_deck.gd，入口在 concept_cards.gd）
## 卡片的寫法見 concepts_exp.gd 開頭的說明（?{…} 先藏起來、[b]…[/b] 強調、check 隨堂小測）。
const UITheme := preload("res://data/ui/game_theme.gd")


static func cards(level: String) -> Array:
	match level:
		"V1":
			return [
				{"title": "相等向量", "decoys": ["起點", "位置"], "tag": "定義", "glyph": "→",
				 "formulas": ["\\vec{AB} = \\vec{CD}：長度一樣、?{方向}一樣", "起點在哪裡都可以：向量可以 ?{平移}"],
				 "notes": ["反向的箭頭是 −\\vec{a}，不是 \\vec{a}", "平行四邊形 ABCD：\\vec{AB} = \\vec{DC}"],
				 "example": "平行四邊形的四個頂點：12 支箭頭裡有 4 對一樣，共 8 個不同的向量",
				 "check": {"q": "平行四邊形 ABCD，哪一個等於 \\vec{AB}？", "opts": ["\\vec{DC}", "\\vec{CD}", "\\vec{BA}"], "a": 0,
					"why": "從 D 到 C 和從 A 到 B 方向一樣。", "hint": "注意方向。"}},
				{"title": "加法與減法", "decoys": ["\\vec{BC}", "起點減終點"], "tag": "定理", "glyph": "−",
				 "formulas": ["首尾相接：\\vec{AB} + \\vec{BC} = ?{\\vec{AC}}", "\\vec{AB} − \\vec{AC} = ?{\\vec{CB}}（終點減起點）"],
				 "notes": ["平行四邊形法：兩支同起點，對角線是和", "減一支箭頭 = 加上它的反方向"],
				 "example": "\\vec{PQ} = \\vec{AQ} − \\vec{AP}：兩個點都從 A 出發再相減",
				 "check": {"q": "\\vec{AC} − \\vec{BC} = ？", "opts": ["\\vec{AB}", "\\vec{BA}", "\\vec{CB}"], "a": 0,
					"why": "\\vec{AC} + \\vec{CB} = \\vec{AB}。", "hint": "減 \\vec{BC} = 加 \\vec{CB}。"}},
				{"title": "平行與倍數", "decoys": ["相同", "1"], "tag": "定理", "glyph": "k→",
				 "formulas": ["\\vec{b} ∥ \\vec{a} ⇔ \\vec{b} = ?{k}\\vec{a}", "k < 0 時方向 ?{相反}，長度是 |k| 倍"],
				 "notes": ["\\vec{a} ≠ \\vec{0} 才能這樣判斷", "k 不管多少，k\\vec{a} 都在同一條直線上"],
				 "example": "(3, −6) = 3(1, −2)：平行而且同方向",
				 "check": {"q": "(−4, 2) 和 (2, −1) 的關係？", "opts": ["平行、反方向", "平行、同方向", "不平行"], "a": 0,
					"why": "(−4, 2) = −2(2, −1)。", "hint": "看是不是倍數。"}},
				{"title": "不共線的係數", "decoys": ["1", "相等"], "tag": "定理", "glyph": "=0",
				 "formulas": ["A、B、C 不共線：x\\vec{AB} + y\\vec{AC} = \\vec{0} ⇒ x = y = ?{0}",
					"x\\vec{AB} + y\\vec{AC} = x'\\vec{AB} + y'\\vec{AC} ⇒ 係數 ?{對應相等}"],
				 "notes": ["有 \\vec{CB} 這種，先拆成 \\vec{AB} − \\vec{AC}", "共線的話就不唯一"],
				 "example": "(x − 2y + 1)\\vec{AB} + (x + y − 5)\\vec{AC} = \\vec{0} ⇒ (x, y) = (3, 2)",
				 "check": {"q": "不共線，(a − 1)\\vec{AB} + (b + 2)\\vec{AC} = \\vec{0}，a + b = ？", "opts": ["−1", "1", "3"], "a": 0,
					"why": "a = 1、b = −2。", "hint": "兩個係數都是 0。"}},
				{"title": "分點公式", "decoys": ["\\frac{m}{n}", "同側"], "tag": "公式", "glyph": "m:n",
				 "formulas": ["\\ol{BP} : \\ol{PC} = m : n ⇒ \\vec{AP} = ?{\\frac{n}{m + n}}\\vec{AB} + ?{\\frac{m}{m + n}}\\vec{AC}",
					"係數 ?{交叉}，加起來是 1"],
				 "notes": ["靠近 B，\\vec{AB} 的係數就大", "角平分線：\\ol{BD} : \\ol{DC} = \\ol{AB} : \\ol{AC}"],
				 "example": "\\ol{BP} : \\ol{PC} = 1 : 3 ⇒ \\vec{AP} = \\frac{3}{4}\\vec{AB} + \\frac{1}{4}\\vec{AC}",
				 "check": {"q": "P 是 \\ol{BC} 中點，\\vec{AP} = ？", "opts": ["\\frac{1}{2}\\vec{AB} + \\frac{1}{2}\\vec{AC}", "\\vec{AB} + \\vec{AC}", "\\frac{1}{2}\\vec{BC}"], "a": 0,
					"why": "1 : 1，兩個係數都是 \\frac{1}{2}。", "hint": "係數加起來是 1。"}},
			]
	return []
