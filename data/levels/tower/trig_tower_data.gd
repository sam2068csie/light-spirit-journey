extends RefCounted
## 自動產生，不要手改：python3 tools/towerlib/gen.py trig
##   題目模板和每一組數字在 tools/trig_tower/t_*.py，答案都由程式算、assert 驗算過。
##   每一題的 vars 是另外幾組數字（蓋過 stem、plot、steps），塔每一輪會先出沒看過的那組。

static func data() -> Array:
	return [
		{
			"id": "tj_radian",
			"kind": "judge",
			"tier": 1,
			"title": "沒有度的角",
			"tmul": 1.0,
			"stem": "角度沒寫 ° 的都是弧度。不查表，判斷下列敘述。",
			"steps": [
				{
					"t": "judge",
					"q": "1 弧度 ≈ 57.3°，先把角換成大約的度數，看在第幾象限。",
					"cards": [
						{
							"s": "sin 2 > sin 1",
							"ok": true,
							"why": "sin 2 = sin(π − 2)，π − 2 ≈ 1.14 比 1 大，而且都在第一象限"
						},
						{
							"s": "cos 3 > 0",
							"ok": false,
							"why": "3 ≈ 172°，在第二象限，cos 3 < 0"
						},
						{
							"s": "tan 4 > 0",
							"ok": true,
							"why": "4 ≈ 229°，在第三象限，tan 是正的"
						},
						{
							"s": "sin 6 < 0",
							"ok": true,
							"why": "6 ≈ 344°，在第四象限"
						},
						{
							"s": "sin 1° > sin 1",
							"ok": false,
							"why": "1° 比 1 弧度（≈ 57.3°）小很多，sin 1° 比較小"
						}
					]
				}
			],
			"vars": [
				{
					"stem": "角度沒寫 ° 的都是弧度。不查表，判斷下列敘述。",
					"steps": [
						{
							"t": "judge",
							"q": "1 弧度 ≈ 57.3°，先把角換成大約的度數，看在第幾象限。",
							"cards": [
								{
									"s": "sin 3 > sin 2",
									"ok": false,
									"why": "sin 3 = sin(π − 3)，π − 3 ≈ 0.14，比 π − 2 ≈ 1.14 小"
								},
								{
									"s": "cos 2 < 0",
									"ok": true,
									"why": "2 ≈ 115°，在第二象限"
								},
								{
									"s": "tan 5 > 0",
									"ok": false,
									"why": "5 ≈ 286°，在第四象限，tan 是負的"
								},
								{
									"s": "sin 4 < 0",
									"ok": true,
									"why": "4 ≈ 229°，在第三象限"
								},
								{
									"s": "cos 1 > cos 1°",
									"ok": false,
									"why": "1° 很小，cos 1° 幾乎是 1；1 弧度 ≈ 57.3°，cos 1 ≈ 0.54"
								}
							]
						}
					]
				},
				{
					"stem": "角度沒寫 ° 的都是弧度。不查表，判斷下列敘述。",
					"steps": [
						{
							"t": "judge",
							"q": "1 弧度 ≈ 57.3°，先把角換成大約的度數，看在第幾象限。",
							"cards": [
								{
									"s": "sin 1 > cos 1",
									"ok": true,
									"why": "1 > π/4 ≈ 0.79，過了 π/4 之後 sin 比 cos 大"
								},
								{
									"s": "cos 4 > 0",
									"ok": false,
									"why": "4 ≈ 229°，在第三象限，cos 4 < 0"
								},
								{
									"s": "tan 2 < 0",
									"ok": true,
									"why": "2 ≈ 115°，在第二象限，tan 是負的"
								},
								{
									"s": "sin 5 > 0",
									"ok": false,
									"why": "5 ≈ 286°，在第四象限"
								},
								{
									"s": "sin 2° < sin 2",
									"ok": true,
									"why": "2° 很小，sin 2° ≈ 0.03；sin 2 ≈ 0.91"
								}
							]
						}
					]
				}
			]
		},
		{
			"id": "tj_sign",
			"kind": "judge",
			"tier": 1,
			"title": "象限與正負",
			"tmul": 1.15,
			"stem": "tan θ = −8/15，且 3π/2 < θ < 2π。下列敘述哪些正確？",
			"steps": [
				{
					"t": "fill",
					"q": "第四象限：sin θ < 0、cos θ > 0。直角三角形的邊是 8、15、17：",
					"template": "sin θ = [0]，cos θ = [1]",
					"ans": [
						"−8/17",
						"15/17"
					],
					"hint": "斜邊 √{64 + 225} = 17，sin 加負號"
				},
				{
					"t": "judge",
					"q": "用上面的 sin θ、cos θ 判斷每一張。",
					"cards": [
						{
							"s": "sin θ + cos θ = 7/17",
							"ok": true,
							"why": "−8/17 + 15/17"
						},
						{
							"s": "cos 2θ = 161/289",
							"ok": true,
							"why": "cos^{2}θ − sin^{2}θ = (225 − 64)/289"
						},
						{
							"s": "sin 2θ > 0",
							"ok": false,
							"why": "2 sin θ cos θ = 2 · (−8/17) · (15/17) < 0"
						},
						{
							"s": "θ/2 在第二象限",
							"ok": true,
							"why": "3π/4 < θ/2 < π"
						},
						{
							"s": "tan(θ/2) = −4",
							"ok": false,
							"why": "tan(θ/2) = (1 − cos θ)/sin θ = (2/17)/(−8/17) = −1/4"
						}
					]
				}
			],
			"vars": [
				{
					"stem": "tan θ = −5/12，且 π/2 < θ < π。下列敘述哪些正確？",
					"steps": [
						{
							"t": "fill",
							"q": "第二象限：sin θ > 0、cos θ < 0。直角三角形的邊是 5、12、13：",
							"template": "sin θ = [0]，cos θ = [1]",
							"ans": [
								"5/13",
								"−12/13"
							],
							"hint": "斜邊 √{25 + 144} = 13，cos 加負號"
						},
						{
							"t": "judge",
							"q": "用上面的 sin θ、cos θ 判斷每一張。",
							"cards": [
								{
									"s": "sin θ + cos θ = −7/13",
									"ok": true,
									"why": "5/13 + (−12/13)"
								},
								{
									"s": "cos 2θ = 119/169",
									"ok": true,
									"why": "cos^{2}θ − sin^{2}θ = (144 − 25)/169"
								},
								{
									"s": "sin 2θ > 0",
									"ok": false,
									"why": "2 sin θ cos θ = 2 · (5/13) · (−12/13) < 0"
								},
								{
									"s": "θ/2 在第一象限",
									"ok": true,
									"why": "π/4 < θ/2 < π/2"
								},
								{
									"s": "tan(θ/2) = 1/5",
									"ok": false,
									"why": "tan(θ/2) = (1 − cos θ)/sin θ = (25/13)/(5/13) = 5"
								}
							]
						}
					]
				},
				{
					"stem": "tan θ = −7/24，且 3π/2 < θ < 2π。下列敘述哪些正確？",
					"steps": [
						{
							"t": "fill",
							"q": "第四象限：sin θ < 0、cos θ > 0。直角三角形的邊是 7、24、25：",
							"template": "sin θ = [0]，cos θ = [1]",
							"ans": [
								"−7/25",
								"24/25"
							],
							"hint": "斜邊 √{49 + 576} = 25，sin 加負號"
						},
						{
							"t": "judge",
							"q": "用上面的 sin θ、cos θ 判斷每一張。",
							"cards": [
								{
									"s": "sin θ + cos θ = 17/25",
									"ok": true,
									"why": "−7/25 + 24/25"
								},
								{
									"s": "cos 2θ = 527/625",
									"ok": true,
									"why": "cos^{2}θ − sin^{2}θ = (576 − 49)/625"
								},
								{
									"s": "sin 2θ > 0",
									"ok": false,
									"why": "2 sin θ cos θ = 2 · (−7/25) · (24/25) < 0"
								},
								{
									"s": "θ/2 在第二象限",
									"ok": true,
									"why": "3π/4 < θ/2 < π"
								},
								{
									"s": "tan(θ/2) = −7",
									"ok": false,
									"why": "tan(θ/2) = (1 − cos θ)/sin θ = (1/25)/(−7/25) = −1/7"
								}
							]
						}
					]
				}
			]
		},
		{
			"id": "tj_period",
			"kind": "judge",
			"tier": 1,
			"title": "挑出週期",
			"tmul": 1.0,
			"stem": "下列哪些函數的週期是 π？",
			"steps": [
				{
					"t": "judge",
					"q": "先化成 sin、cos 一次的樣子，或想想絕對值把圖形怎麼折。",
					"cards": [
						{
							"s": "y = |sin x|",
							"ok": true,
							"why": "負的那一半翻上來，每 π 重複一次"
						},
						{
							"s": "y = cos^{2} x",
							"ok": true,
							"why": "cos^{2} x = (1 + cos 2x)/2"
						},
						{
							"s": "y = tan(x/2)",
							"ok": false,
							"why": "週期是 π/(1/2) = 2π"
						},
						{
							"s": "y = sin 2x + cos x",
							"ok": false,
							"why": "兩個週期 π、2π 的最小公倍數是 2π"
						},
						{
							"s": "y = |sin x + cos x|",
							"ok": true,
							"why": "= |√{2} sin(x + π/4)|，週期 π"
						}
					]
				}
			],
			"vars": [
				{
					"stem": "下列哪些函數的週期是 π/2？",
					"steps": [
						{
							"t": "judge",
							"q": "先化成 sin、cos 一次的樣子，再用 2π/k、π/k。",
							"cards": [
								{
									"s": "y = |sin 2x|",
									"ok": true,
									"why": "sin 2x 的週期 π，負的翻上來再減半"
								},
								{
									"s": "y = tan 2x",
									"ok": true,
									"why": "tan kx 的週期是 π/k"
								},
								{
									"s": "y = sin^{2} x",
									"ok": false,
									"why": "= (1 − cos 2x)/2，週期 π"
								},
								{
									"s": "y = sin 4x + cos 2x",
									"ok": false,
									"why": "兩個週期 π/2、π 的最小公倍數是 π"
								},
								{
									"s": "y = sin 4x cos 4x",
									"ok": false,
									"why": "= (1/2) sin 8x，週期 π/4"
								}
							]
						}
					]
				},
				{
					"stem": "下列哪些函數的週期是 2π？",
					"steps": [
						{
							"t": "judge",
							"q": "兩個週期加起來取最小公倍數；絕對值會讓週期減半。",
							"cards": [
								{
									"s": "y = sin x + cos x",
									"ok": true,
									"why": "= √{2} sin(x + π/4)，週期 2π"
								},
								{
									"s": "y = |sin x|",
									"ok": false,
									"why": "負的那一半翻上來，週期變成 π"
								},
								{
									"s": "y = sin x + sin 2x",
									"ok": true,
									"why": "兩個週期 2π、π 的最小公倍數是 2π"
								},
								{
									"s": "y = tan x",
									"ok": false,
									"why": "tan x 的週期是 π"
								},
								{
									"s": "y = cos(x/2)",
									"ok": false,
									"why": "週期 2π/(1/2) = 4π"
								}
							]
						}
					]
				}
			]
		},
		{
			"id": "tj_shift",
			"kind": "judge",
			"tier": 2,
			"title": "伸縮平移的順序",
			"tmul": 1.15,
			"stem": "把 y = sin x 的圖形做下列變換，哪些敘述正確？（水平伸縮以 y 軸為基準）",
			"steps": [
				{
					"t": "judge",
					"q": "平移：x 換成 x ∓ h。伸縮：x 換成 x/k。照順序換。",
					"cards": [
						{
							"s": "右移 π/3：y = sin(x − π/3)",
							"ok": true,
							"why": "右移 h：x 換成 x − h"
						},
						{
							"s": "先水平縮成 1/2 倍、再左移 π/6：y = sin(2x + π/6)",
							"ok": false,
							"why": "先得 sin 2x，再左移：sin 2(x + π/6) = sin(2x + π/3)"
						},
						{
							"s": "先左移 π/6、再水平縮成 1/2 倍：y = sin(2x + π/6)",
							"ok": true,
							"why": "先得 sin(x + π/6)，再把 x 換成 2x"
						},
						{
							"s": "鉛直伸長 3 倍、再上移 1：y = 3 sin x + 1",
							"ok": true,
							"why": "先乘 3 再加 1"
						},
						{
							"s": "左移 π/2：y = −cos x",
							"ok": false,
							"why": "sin(x + π/2) = cos x"
						}
					]
				}
			],
			"vars": [
				{
					"stem": "把 y = sin x 的圖形做下列變換，哪些敘述正確？（水平伸縮以 y 軸為基準）",
					"steps": [
						{
							"t": "judge",
							"q": "平移：x 換成 x ∓ h。伸縮：x 換成 x/k。照順序換。",
							"cards": [
								{
									"s": "左移 π/4：y = sin(x + π/4)",
									"ok": true,
									"why": "左移 h：x 換成 x + h"
								},
								{
									"s": "先水平縮成 1/3 倍、再右移 π/12：y = sin(3x − π/12)",
									"ok": false,
									"why": "先得 sin 3x，再右移：sin 3(x − π/12) = sin(3x − π/4)"
								},
								{
									"s": "先右移 π/12、再水平縮成 1/3 倍：y = sin(3x − π/12)",
									"ok": true,
									"why": "先得 sin(x − π/12)，再把 x 換成 3x"
								},
								{
									"s": "鉛直伸長 2 倍、再下移 1：y = 2 sin x − 1",
									"ok": true,
									"why": "先乘 2 再減 1"
								},
								{
									"s": "右移 π/2：y = −cos x",
									"ok": true,
									"why": "sin(x − π/2) = −cos x"
								}
							]
						}
					]
				},
				{
					"stem": "把 y = sin x 的圖形做下列變換，哪些敘述正確？（水平伸縮以 y 軸為基準）",
					"steps": [
						{
							"t": "judge",
							"q": "平移：x 換成 x ∓ h。伸縮：x 換成 x/k。照順序換。",
							"cards": [
								{
									"s": "右移 π/6：y = sin(x − π/6)",
									"ok": true,
									"why": "右移 h：x 換成 x − h"
								},
								{
									"s": "先水平縮成 1/2 倍、再左移 π/4：y = sin(2x + π/4)",
									"ok": false,
									"why": "先得 sin 2x，再左移：sin 2(x + π/4) = sin(2x + π/2)"
								},
								{
									"s": "先左移 π/4、再水平縮成 1/2 倍：y = sin(2x + π/4)",
									"ok": true,
									"why": "先得 sin(x + π/4)，再把 x 換成 2x"
								},
								{
									"s": "鉛直伸長 4 倍、再上移 2：y = 4(sin x + 2)",
									"ok": false,
									"why": "先乘 4 再加 2：y = 4 sin x + 2"
								},
								{
									"s": "左移 π：y = −sin x",
									"ok": true,
									"why": "sin(x + π) = −sin x"
								}
							]
						}
					]
				}
			]
		},
		{
			"id": "tj_sym",
			"kind": "judge",
			"tier": 2,
			"title": "對稱軸與對稱中心",
			"tmul": 1.2,
			"stem": "f(x) = 2 sin(2x − π/3) + 1。下列敘述哪些正確？",
			"steps": [
				{
					"t": "fill",
					"q": "先讀出基本資料：",
					"template": "週期 = [0]π，中線 y = [1]，最大值 [2]",
					"ans": [
						"1",
						"1",
						"3"
					],
					"hint": "週期 2π/2，中線是加在後面的 1，最大值 2 + 1"
				},
				{
					"t": "judge",
					"q": "令 u = 2x − π/3：u = π/2 + kπ 是對稱軸，u = kπ 是對稱中心。",
					"cards": [
						{
							"s": "直線 x = 5π/12 是圖形的對稱軸",
							"ok": true,
							"why": "2x − π/3 = π/2 ⇒ x = 5π/12（最高點）"
						},
						{
							"s": "點 (π/6, 1) 是圖形的對稱中心",
							"ok": true,
							"why": "2x − π/3 = 0 ⇒ x = π/6，此時 f = 1（在中線上）"
						},
						{
							"s": "f(x) 的最小值是 −1",
							"ok": true,
							"why": "−2 + 1 = −1"
						},
						{
							"s": "0 ≤ x ≤ π/2 時，f(x) 遞增",
							"ok": false,
							"why": "u 從 −π/3 到 2π/3，過了 π/2（x = 5π/12）就開始遞減"
						},
						{
							"s": "點 (π/6, 0) 是圖形的對稱中心",
							"ok": false,
							"why": "對稱中心在中線 y = 1 上"
						}
					]
				}
			],
			"vars": [
				{
					"stem": "f(x) = 3 sin(3x − π/4) − 2。下列敘述哪些正確？",
					"steps": [
						{
							"t": "fill",
							"q": "先讀出基本資料：",
							"template": "週期 = [0]π，中線 y = [1]，最大值 [2]",
							"ans": [
								"2/3",
								"−2",
								"1"
							],
							"hint": "週期 2π/3，中線是加在後面的 −2，最大值 3 − 2"
						},
						{
							"t": "judge",
							"q": "令 u = 3x − π/4：u = π/2 + kπ 是對稱軸，u = kπ 是對稱中心。",
							"cards": [
								{
									"s": "直線 x = π/4 是圖形的對稱軸",
									"ok": true,
									"why": "3x − π/4 = π/2 ⇒ x = π/4（最高點）"
								},
								{
									"s": "點 (π/12, −2) 是圖形的對稱中心",
									"ok": true,
									"why": "3x − π/4 = 0 ⇒ x = π/12，此時 f = −2（在中線上）"
								},
								{
									"s": "f(x) 的最小值是 −5",
									"ok": true,
									"why": "−3 + (−2) = −5"
								},
								{
									"s": "0 ≤ x ≤ π/3 時，f(x) 遞增",
									"ok": false,
									"why": "u 從 −π/4 到 3π/4，過了 π/2（x = π/4）就開始遞減"
								},
								{
									"s": "點 (π/12, 0) 是圖形的對稱中心",
									"ok": false,
									"why": "對稱中心在中線 y = −2 上"
								}
							]
						}
					]
				},
				{
					"stem": "f(x) = 4 sin(x/2 − π/6) + 2。下列敘述哪些正確？",
					"steps": [
						{
							"t": "fill",
							"q": "先讀出基本資料：",
							"template": "週期 = [0]π，中線 y = [1]，最大值 [2]",
							"ans": [
								"4",
								"2",
								"6"
							],
							"hint": "週期 2π/(1/2)，中線是加在後面的 2，最大值 4 + 2"
						},
						{
							"t": "judge",
							"q": "令 u = x/2 − π/6：u = π/2 + kπ 是對稱軸，u = kπ 是對稱中心。",
							"cards": [
								{
									"s": "直線 x = 4π/3 是圖形的對稱軸",
									"ok": true,
									"why": "x/2 − π/6 = π/2 ⇒ x = 4π/3（最高點）"
								},
								{
									"s": "點 (π/3, 2) 是圖形的對稱中心",
									"ok": true,
									"why": "x/2 − π/6 = 0 ⇒ x = π/3，此時 f = 2（在中線上）"
								},
								{
									"s": "f(x) 的最小值是 −2",
									"ok": true,
									"why": "−4 + 2 = −2"
								},
								{
									"s": "0 ≤ x ≤ 2π 時，f(x) 遞增",
									"ok": false,
									"why": "u 從 −π/6 到 5π/6，過了 π/2（x = 4π/3）就開始遞減"
								},
								{
									"s": "點 (π/3, 0) 是圖形的對稱中心",
									"ok": false,
									"why": "對稱中心在中線 y = 2 上"
								}
							]
						}
					]
				}
			]
		},
		{
			"id": "tj_fold",
			"kind": "judge",
			"tier": 2,
			"title": "疊合的性質",
			"tmul": 1.2,
			"stem": "f(x) = √{3} sin x − cos x。下列敘述哪些正確？",
			"steps": [
				{
					"t": "fill",
					"q": "先疊合：√{3} sin x − cos x = 2(sin x · √{3}/2 − cos x · 1/2)。",
					"template": "f(x) = [0] sin(x − [1]π)",
					"ans": [
						"2",
						"1/6"
					],
					"hint": "cos(π/6) = √{3}/2、sin(π/6) = 1/2"
				},
				{
					"t": "judge",
					"q": "用 f(x) = 2 sin(x − π/6) 判斷每一張。",
					"cards": [
						{
							"s": "f(x) 的週期是 2π",
							"ok": true,
							"why": "sin 前面沒有乘倍數"
						},
						{
							"s": "f(x) 的最大值是 1 + √{3}",
							"ok": false,
							"why": "最大值是 2"
						},
						{
							"s": "x = 2π/3 時 f(x) 有最大值",
							"ok": true,
							"why": "x − π/6 = π/2"
						},
						{
							"s": "0 ≤ x < 2π 時，f(x) = 1 恰有兩個解",
							"ok": true,
							"why": "sin(x − π/6) = 1/2 ⇒ x − π/6 = π/6、5π/6 ⇒ x = π/3、π"
						},
						{
							"s": "y = f(x) 的圖形對稱於原點",
							"ok": false,
							"why": "f(0) = −1 ≠ 0，圖形不過原點"
						}
					]
				}
			],
			"vars": [
				{
					"stem": "f(x) = sin x + √{3} cos x。下列敘述哪些正確？",
					"steps": [
						{
							"t": "fill",
							"q": "先疊合：sin x + √{3} cos x = 2(sin x · 1/2 + cos x · √{3}/2)。",
							"template": "f(x) = [0] sin(x + [1]π)",
							"ans": [
								"2",
								"1/3"
							],
							"hint": "cos(π/3) = 1/2、sin(π/3) = √{3}/2"
						},
						{
							"t": "judge",
							"q": "用 f(x) = 2 sin(x + π/3) 判斷每一張。",
							"cards": [
								{
									"s": "f(x) 的週期是 2π",
									"ok": true,
									"why": "sin 前面沒有乘倍數"
								},
								{
									"s": "f(x) 的最大值是 1 + √{3}",
									"ok": false,
									"why": "最大值是 2"
								},
								{
									"s": "x = π/6 時 f(x) 有最大值",
									"ok": true,
									"why": "x + π/3 = π/2"
								},
								{
									"s": "0 ≤ x < 2π 時，f(x) = 1 恰有兩個解",
									"ok": true,
									"why": "sin(x + π/3) = 1/2 ⇒ x + π/3 = 5π/6、13π/6 ⇒ x = π/2、11π/6"
								},
								{
									"s": "y = f(x) 的圖形對稱於原點",
									"ok": false,
									"why": "f(0) = √{3} ≠ 0，圖形不過原點"
								}
							]
						}
					]
				},
				{
					"stem": "f(x) = 3 sin x − 3√{3} cos x。下列敘述哪些正確？",
					"steps": [
						{
							"t": "fill",
							"q": "先疊合：3 sin x − 3√{3} cos x = 6(sin x · 1/2 − cos x · √{3}/2)。",
							"template": "f(x) = [0] sin(x − [1]π)",
							"ans": [
								"6",
								"1/3"
							],
							"hint": "cos(π/3) = 1/2、sin(π/3) = √{3}/2"
						},
						{
							"t": "judge",
							"q": "用 f(x) = 6 sin(x − π/3) 判斷每一張。",
							"cards": [
								{
									"s": "f(x) 的週期是 2π",
									"ok": true,
									"why": "sin 前面沒有乘倍數"
								},
								{
									"s": "f(x) 的最大值是 3 + 3√{3}",
									"ok": false,
									"why": "最大值是 6"
								},
								{
									"s": "x = 5π/6 時 f(x) 有最大值",
									"ok": true,
									"why": "x − π/3 = π/2"
								},
								{
									"s": "0 ≤ x < 2π 時，f(x) = 3 恰有兩個解",
									"ok": true,
									"why": "sin(x − π/3) = 1/2 ⇒ x − π/3 = π/6、5π/6 ⇒ x = π/2、7π/6"
								},
								{
									"s": "y = f(x) 的圖形對稱於原點",
									"ok": false,
									"why": "f(0) = −3√{3} ≠ 0，圖形不過原點"
								}
							]
						}
					]
				}
			]
		},
		{
			"id": "tj_always",
			"kind": "judge",
			"tier": 1,
			"title": "恆成立嗎",
			"tmul": 1.0,
			"stem": "當 π/4 < x < π/2 時，下列哪些不等式恆成立？",
			"steps": [
				{
					"t": "judge",
					"q": "先寫出 2x、x + π/4 的範圍。",
					"cards": [
						{
							"s": "sin 2x > 0",
							"ok": true,
							"why": "π/2 < 2x < π，第二象限 sin > 0"
						},
						{
							"s": "cos 2x > 0",
							"ok": false,
							"why": "第二象限 cos < 0"
						},
						{
							"s": "sin x > cos x",
							"ok": true,
							"why": "x > π/4 以後 sin 比 cos 大"
						},
						{
							"s": "tan x > 1",
							"ok": true,
							"why": "tan(π/4) = 1，tan 在這裡遞增"
						},
						{
							"s": "sin x + cos x > √{2}",
							"ok": false,
							"why": "= √{2} sin(x + π/4)，最大才 √{2}，而且到不了"
						}
					]
				}
			],
			"vars": [
				{
					"stem": "當 π/2 < x < 3π/4 時，下列哪些不等式恆成立？",
					"steps": [
						{
							"t": "judge",
							"q": "先寫出 2x、x + π/4 的範圍。",
							"cards": [
								{
									"s": "sin 2x < 0",
									"ok": true,
									"why": "π < 2x < 3π/2，第三象限 sin < 0"
								},
								{
									"s": "cos 2x > 0",
									"ok": false,
									"why": "第三象限 cos < 0"
								},
								{
									"s": "sin x + cos x > 0",
									"ok": true,
									"why": "= √{2} sin(x + π/4)，3π/4 < x + π/4 < π，sin > 0"
								},
								{
									"s": "tan x < −1",
									"ok": true,
									"why": "tan 從 −∞ 升到 tan(3π/4) = −1，還沒到"
								},
								{
									"s": "sin x + cos x > 1",
									"ok": false,
									"why": "√{2} sin(x + π/4) 在 0 和 1 之間"
								}
							]
						}
					]
				},
				{
					"stem": "當 0 < x < π/6 時，下列哪些不等式恆成立？",
					"steps": [
						{
							"t": "judge",
							"q": "先寫出 2x、x + π/4 的範圍。",
							"cards": [
								{
									"s": "sin 2x < √{3}/2",
									"ok": true,
									"why": "0 < 2x < π/3，sin 遞增，到不了 sin(π/3)"
								},
								{
									"s": "cos 2x < 1/2",
									"ok": false,
									"why": "0 < 2x < π/3，cos 2x 在 1/2 和 1 之間"
								},
								{
									"s": "tan x < √{3}/3",
									"ok": true,
									"why": "tan(π/6) = √{3}/3，tan 在這裡遞增"
								},
								{
									"s": "sin x < cos x",
									"ok": true,
									"why": "x < π/4 時 cos 比 sin 大"
								},
								{
									"s": "sin x + cos x > √{2}",
									"ok": false,
									"why": "= √{2} sin(x + π/4)，最大才 √{2}"
								}
							]
						}
					]
				}
			]
		},
		{
			"id": "tj_case",
			"kind": "judge",
			"tier": 3,
			"title": "兩種可能",
			"tmul": 1.35,
			"stem": "sin α = 4/5，sin β = 5/13，且 cos α · cos β < 0。下列敘述哪些正確？",
			"steps": [
				{
					"t": "fill",
					"q": "先算 cos 的大小。cos α · cos β < 0：一正一負，兩種情形都要算。",
					"template": "(cos α, cos β) = (±[0], ∓[1])",
					"ans": [
						"3/5",
						"12/13"
					],
					"hint": "3、4、5 和 5、12、13"
				},
				{
					"t": "judge",
					"q": "兩種情形都代進去，結果一樣才算「只有一個值」。",
					"cards": [
						{
							"s": "cos(α − β) 只有一個可能的值",
							"ok": true,
							"why": "cos α cos β + sin α sin β = −36/65 + 20/65 = −16/65，兩種情形一樣"
						},
						{
							"s": "sin(α + β) 只有一個可能的值",
							"ok": false,
							"why": "第一種 −48/65 + 15/65 = −33/65，第二種 48/65 − 15/65 = 33/65"
						},
						{
							"s": "cos(α + β) = −56/65",
							"ok": true,
							"why": "cos α cos β − sin α sin β = −36/65 − 20/65"
						},
						{
							"s": "sin(α − β) 可能是 63/65",
							"ok": true,
							"why": "第二種：sin α cos β − cos α sin β = 48/65 + 15/65"
						},
						{
							"s": "tan α tan β > 0",
							"ok": false,
							"why": "sin α sin β > 0、cos α cos β < 0，所以 tan α tan β < 0"
						}
					]
				}
			],
			"vars": [
				{
					"stem": "sin α = 3/5，sin β = 12/13，且 cos α · cos β < 0。下列敘述哪些正確？",
					"steps": [
						{
							"t": "fill",
							"q": "先算 cos 的大小。cos α · cos β < 0：一正一負，兩種情形都要算。",
							"template": "(cos α, cos β) = (±[0], ∓[1])",
							"ans": [
								"4/5",
								"5/13"
							],
							"hint": "3、4、5 和 5、12、13"
						},
						{
							"t": "judge",
							"q": "兩種情形都代進去，結果一樣才算「只有一個值」。",
							"cards": [
								{
									"s": "cos(α − β) 只有一個可能的值",
									"ok": true,
									"why": "cos α cos β + sin α sin β = −20/65 + 36/65 = 16/65，兩種情形一樣"
								},
								{
									"s": "sin(α + β) 只有一個可能的值",
									"ok": false,
									"why": "第一種 −15/65 + 48/65 = 33/65，第二種 15/65 − 48/65 = −33/65"
								},
								{
									"s": "cos(α + β) = −56/65",
									"ok": true,
									"why": "cos α cos β − sin α sin β = −20/65 − 36/65"
								},
								{
									"s": "sin(α − β) 可能是 63/65",
									"ok": true,
									"why": "第二種：sin α cos β − cos α sin β = 15/65 + 48/65"
								},
								{
									"s": "tan α tan β > 0",
									"ok": false,
									"why": "sin α sin β > 0、cos α cos β < 0，所以 tan α tan β < 0"
								}
							]
						}
					]
				},
				{
					"stem": "sin α = 8/17，sin β = 3/5，且 cos α · cos β < 0。下列敘述哪些正確？",
					"steps": [
						{
							"t": "fill",
							"q": "先算 cos 的大小。cos α · cos β < 0：一正一負，兩種情形都要算。",
							"template": "(cos α, cos β) = (±[0], ∓[1])",
							"ans": [
								"15/17",
								"4/5"
							],
							"hint": "8、15、17 和 3、4、5"
						},
						{
							"t": "judge",
							"q": "兩種情形都代進去，結果一樣才算「只有一個值」。",
							"cards": [
								{
									"s": "cos(α − β) 只有一個可能的值",
									"ok": true,
									"why": "cos α cos β + sin α sin β = −60/85 + 24/85 = −36/85，兩種情形一樣"
								},
								{
									"s": "sin(α + β) 只有一個可能的值",
									"ok": false,
									"why": "第一種 −32/85 + 45/85 = 13/85，第二種 32/85 − 45/85 = −13/85"
								},
								{
									"s": "cos(α + β) = −84/85",
									"ok": true,
									"why": "cos α cos β − sin α sin β = −60/85 − 24/85"
								},
								{
									"s": "sin(α − β) 可能是 77/85",
									"ok": true,
									"why": "第二種：sin α cos β − cos α sin β = 32/85 + 45/85"
								},
								{
									"s": "tan α tan β > 0",
									"ok": false,
									"why": "sin α sin β > 0、cos α cos β < 0，所以 tan α tan β < 0"
								}
							]
						}
					]
				}
			]
		},
		{
			"id": "tj_compare",
			"kind": "judge",
			"tier": 3,
			"title": "三個數比大小",
			"tmul": 1.3,
			"stem": "0 < x < π/4，a = sin x、b = tan(x/2)、c = sin(x°)。下列哪些恆成立？",
			"steps": [
				{
					"t": "judge",
					"q": "以切表弦：tan(x/2) = sin x/(1 + cos x)。x° 是 x 的 π/180 倍。",
					"cards": [
						{
							"s": "a > b",
							"ok": true,
							"why": "b = sin x/(1 + cos x)，分母大於 1"
						},
						{
							"s": "b < c",
							"ok": false,
							"why": "b > x/2 > πx/180 > c：x° 小非常多"
						},
						{
							"s": "a > c",
							"ok": true,
							"why": "x° 比 x 弧度小，sin 在 0 到 π/2 遞增"
						},
						{
							"s": "a < √{2}/2",
							"ok": true,
							"why": "x < π/4 ⇒ sin x < sin(π/4)"
						},
						{
							"s": "2b < a",
							"ok": false,
							"why": "2b = 2 sin x/(1 + cos x)，分母小於 2，所以 2b > a"
						}
					]
				}
			],
			"vars": [
				{
					"stem": "0 < x < π/3，a = sin x、b = tan(x/2)、c = sin(x°)。下列哪些恆成立？",
					"steps": [
						{
							"t": "judge",
							"q": "以切表弦：tan(x/2) = sin x/(1 + cos x)。x° 是 x 的 π/180 倍。",
							"cards": [
								{
									"s": "b > a",
									"ok": false,
									"why": "b = sin x/(1 + cos x)，分母大於 1，b 比較小"
								},
								{
									"s": "c < b",
									"ok": true,
									"why": "x° 是 x 的 π/180 倍，c 非常小"
								},
								{
									"s": "a > c",
									"ok": true,
									"why": "x° 比 x 弧度小，sin 在 0 到 π/2 遞增"
								},
								{
									"s": "a > √{3}/2",
									"ok": false,
									"why": "x < π/3 ⇒ sin x < sin(π/3) = √{3}/2"
								},
								{
									"s": "2b > a",
									"ok": true,
									"why": "2b = 2 sin x/(1 + cos x)，分母小於 2"
								}
							]
						}
					]
				},
				{
					"stem": "0 < x < π/6，a = sin x、b = tan(x/2)、c = sin(x°)。下列哪些恆成立？",
					"steps": [
						{
							"t": "judge",
							"q": "以切表弦：tan(x/2) = sin x/(1 + cos x)。x° 是 x 的 π/180 倍。",
							"cards": [
								{
									"s": "a < 1/2",
									"ok": true,
									"why": "x < π/6 ⇒ sin x < sin(π/6)"
								},
								{
									"s": "b ≥ a",
									"ok": false,
									"why": "1 + cos x > 1，b = sin x/(1 + cos x) 比 a 小"
								},
								{
									"s": "c > a",
									"ok": false,
									"why": "x° 比 x 弧度小非常多"
								},
								{
									"s": "b > c",
									"ok": true,
									"why": "b > x/2，而 c < x°，x° 只有 x 的 π/180 倍"
								},
								{
									"s": "a < 2b",
									"ok": true,
									"why": "2b = 2 sin x/(1 + cos x)，分母小於 2"
								}
							]
						}
					]
				}
			]
		},
		{
			"id": "tj_truefalse",
			"kind": "judge",
			"tier": 2,
			"title": "觀念是非",
			"tmul": 1.15,
			"stem": "判斷下列敘述是否正確。",
			"steps": [
				{
					"t": "judge",
					"q": "說「一定」的，找一個反例就是假的。",
					"cards": [
						{
							"s": "有實數 x 使得 cos x = 3/√{7}",
							"ok": false,
							"why": "3/√{7} = √{9/7} > 1"
						},
						{
							"s": "若 sin 2x = sin 2y，且 0 < x、y < π/2，則 x = y",
							"ok": false,
							"why": "反例 x = π/6、y = π/3：sin(π/3) = sin(2π/3)"
						},
						{
							"s": "若 cos 2x = cos 2y，且 0 < x、y < π/2，則 x = y",
							"ok": true,
							"why": "0 < 2x、2y < π，cos 在這裡一對一"
						},
						{
							"s": "0 ≤ θ ≤ π/2 時，sin θ ≤ θ",
							"ok": true,
							"why": "單位圓上，弦（2 sin θ）比弧（2θ）短"
						},
						{
							"s": "tan 3 > 0",
							"ok": false,
							"why": "3 ≈ 172°，在第二象限"
						}
					]
				}
			],
			"vars": [
				{
					"stem": "判斷下列敘述是否正確。",
					"steps": [
						{
							"t": "judge",
							"q": "說「一定」的，找一個反例就是假的。",
							"cards": [
								{
									"s": "有實數 x 使得 sin x = √{5}/2",
									"ok": false,
									"why": "√{5}/2 ≈ 1.12 > 1"
								},
								{
									"s": "若 sin x = sin y，且 0 < x、y < π，則 x = y",
									"ok": false,
									"why": "反例 x = π/6、y = 5π/6"
								},
								{
									"s": "若 cos x = cos y，且 0 < x、y < π，則 x = y",
									"ok": true,
									"why": "cos 在 0 到 π 一路遞減，一對一"
								},
								{
									"s": "0 < θ < π/2 時，tan θ > θ",
									"ok": true,
									"why": "單位圓上，切線段比弧長"
								},
								{
									"s": "cos 2 > 0",
									"ok": false,
									"why": "2 ≈ 115°，在第二象限"
								}
							]
						}
					]
				},
				{
					"stem": "判斷下列敘述是否正確。",
					"steps": [
						{
							"t": "judge",
							"q": "說「一定」的，找一個反例就是假的。",
							"cards": [
								{
									"s": "有實數 x 使得 tan x = 100",
									"ok": true,
									"why": "tan 的值域是全體實數"
								},
								{
									"s": "有實數 x 使得 sin x + cos x = 3/2",
									"ok": false,
									"why": "sin x + cos x = √{2} sin(x + π/4)，最大 √{2} ≈ 1.41"
								},
								{
									"s": "若 tan x = tan y，則 x = y",
									"ok": false,
									"why": "反例 x = 0、y = π"
								},
								{
									"s": "sin 1 > sin 2",
									"ok": false,
									"why": "sin 2 = sin(π − 2)，π − 2 ≈ 1.14 比 1 大"
								},
								{
									"s": "對所有實數 x，|sin x| ≤ |x|",
									"ok": true,
									"why": "x 在 0 到 π/2 時弦比弧短，其他地方 |x| > 1"
								}
							]
						}
					]
				}
			]
		},
		{
			"id": "tj_root",
			"kind": "judge",
			"tier": 3,
			"title": "根號裡的倍角",
			"tmul": 1.35,
			"stem": "3π/4 < θ < π，A = √{1 + sin 2θ} + √{1 − sin 2θ}。下列哪些正確？",
			"steps": [
				{
					"t": "choice",
					"q": "1 ± sin 2θ = (sin θ ± cos θ)^{2}。在 3π/4 < θ < π，(sin θ + cos θ, sin θ − cos θ) 的正負是？",
					"opts": [
						"(−, +)",
						"(+, +)",
						"(+, −)",
						"(−, −)"
					],
					"hint": "sin θ > 0、cos θ < 0，而且 |cos θ| > sin θ（越過 3π/4 了）",
					"write": "sin θ + cos θ < 0，sin θ − cos θ > 0（開根號要加絕對值）"
				},
				{
					"t": "judge",
					"q": "√{x^{2}} = |x|：把絕對值拆開再判斷。",
					"cards": [
						{
							"s": "1 + sin 2θ = (sin θ + cos θ)^{2}",
							"ok": true,
							"why": "sin^{2}θ + cos^{2}θ + 2 sin θ cos θ"
						},
						{
							"s": "√{1 + sin 2θ} = sin θ + cos θ",
							"ok": false,
							"why": "sin θ + cos θ 是負的，要加負號"
						},
						{
							"s": "A = −2 cos θ",
							"ok": true,
							"why": "A = −(sin θ + cos θ) + (sin θ − cos θ)"
						},
						{
							"s": "A = 2 sin θ",
							"ok": false,
							"why": "這是兩個都當成正的才會得到的"
						},
						{
							"s": "θ = 5π/6 時，A = √{3}",
							"ok": true,
							"why": "−2 cos(5π/6) = √{3}"
						}
					]
				}
			],
			"vars": [
				{
					"stem": "π/2 < θ < 3π/4，A = √{1 + sin 2θ} + √{1 − sin 2θ}。下列哪些正確？",
					"steps": [
						{
							"t": "choice",
							"q": "1 ± sin 2θ = (sin θ ± cos θ)^{2}。在 π/2 < θ < 3π/4，(sin θ + cos θ, sin θ − cos θ) 的正負是？",
							"opts": [
								"(+, +)",
								"(−, +)",
								"(+, −)",
								"(−, −)"
							],
							"hint": "sin θ > 0、cos θ < 0，而且 sin θ > |cos θ|（還沒到 3π/4）",
							"write": "sin θ + cos θ > 0，sin θ − cos θ > 0（開根號要加絕對值）"
						},
						{
							"t": "judge",
							"q": "√{x^{2}} = |x|：把絕對值拆開再判斷。",
							"cards": [
								{
									"s": "1 + sin 2θ = (sin θ + cos θ)^{2}",
									"ok": true,
									"why": "sin^{2}θ + cos^{2}θ + 2 sin θ cos θ"
								},
								{
									"s": "√{1 + sin 2θ} = sin θ + cos θ",
									"ok": true,
									"why": "sin θ + cos θ 是正的，絕對值可以直接拿掉"
								},
								{
									"s": "A = 2 sin θ",
									"ok": true,
									"why": "A = (sin θ + cos θ) + (sin θ − cos θ)"
								},
								{
									"s": "A = −2 cos θ",
									"ok": false,
									"why": "sin θ + cos θ 在這裡是正的，不用加負號"
								},
								{
									"s": "θ = 2π/3 時，A = 1",
									"ok": false,
									"why": "2 sin(2π/3) = √{3}，不是 1"
								}
							]
						}
					]
				},
				{
					"stem": "5π/4 < θ < 3π/2，A = √{1 + sin 2θ} + √{1 − sin 2θ}。下列哪些正確？",
					"steps": [
						{
							"t": "choice",
							"q": "1 ± sin 2θ = (sin θ ± cos θ)^{2}。在 5π/4 < θ < 3π/2，(sin θ + cos θ, sin θ − cos θ) 的正負是？",
							"opts": [
								"(−, −)",
								"(+, +)",
								"(−, +)",
								"(+, −)"
							],
							"hint": "sin θ < 0、cos θ < 0，而且 |sin θ| > |cos θ|（越過 5π/4 了）",
							"write": "sin θ + cos θ < 0，sin θ − cos θ < 0（開根號要加絕對值）"
						},
						{
							"t": "judge",
							"q": "√{x^{2}} = |x|：把絕對值拆開再判斷。",
							"cards": [
								{
									"s": "1 + sin 2θ = (sin θ + cos θ)^{2}",
									"ok": true,
									"why": "sin^{2}θ + cos^{2}θ + 2 sin θ cos θ"
								},
								{
									"s": "√{1 − sin 2θ} = sin θ − cos θ",
									"ok": false,
									"why": "sin θ − cos θ 是負的，要加負號"
								},
								{
									"s": "A = −2 sin θ",
									"ok": true,
									"why": "A = −(sin θ + cos θ) − (sin θ − cos θ)"
								},
								{
									"s": "A = −2 cos θ",
									"ok": false,
									"why": "sin θ − cos θ 在這裡也是負的"
								},
								{
									"s": "θ = 4π/3 時，A = √{3}",
									"ok": true,
									"why": "−2 sin(4π/3) = √{3}"
								}
							]
						}
					]
				}
			]
		},
		{
			"id": "tj_graph",
			"kind": "judge",
			"tier": 2,
			"title": "同一條波",
			"tmul": 1.2,
			"stem": "圖是一個正弦波的一部分，最高點 (π/12, 2)、和 x 軸交於 (−π/6, 0)。下列哪些函數的圖形就是它？",
			"plot": {
				"x": [
					-1.2,
					3.6
				],
				"y": [
					-2.6,
					2.6
				],
				"pi": 12,
				"pi_lab": 6,
				"curves": [
					{
						"f": "2*sin(2.0*x+1.0471975511965976)",
						"c": "cyan"
					}
				],
				"pts": [
					{
						"x": 0.2618,
						"y": 2,
						"label": "(π/12, 2)"
					},
					{
						"x": -0.5236,
						"y": 0,
						"label": ""
					}
				]
			},
			"steps": [
				{
					"t": "judge",
					"q": "振幅 2、週期 π，最高點在 x = π/12：代進去看是不是最大值。",
					"cards": [
						{
							"s": "y = 2 sin(2x + π/3)",
							"ok": true,
							"why": "x = π/12：2x + π/3 = π/2"
						},
						{
							"s": "y = 2 cos(2x − π/6)",
							"ok": true,
							"why": "x = π/12：2x − π/6 = 0，cos 0 = 1"
						},
						{
							"s": "y = −2 sin(2x − 2π/3)",
							"ok": true,
							"why": "x = π/12：−2 sin(−π/2) = 2"
						},
						{
							"s": "y = 2 sin(2x + π/6)",
							"ok": false,
							"why": "x = π/12：2 sin(π/3) = √{3}，不是最大值"
						},
						{
							"s": "y = 2 sin 2(x + π/3)",
							"ok": false,
							"why": "= 2 sin(2x + 2π/3)，x = π/12 時是 2 sin(5π/6) = 1"
						}
					]
				}
			],
			"vars": [
				{
					"stem": "圖是一個正弦波的一部分，最高點 (5π/12, 3)、和 x 軸交於 (π/6, 0)。下列哪些函數的圖形就是它？",
					"plot": {
						"x": [
							-0.4,
							4.0
						],
						"y": [
							-3.6,
							3.6
						],
						"pi": 12,
						"pi_lab": 6,
						"curves": [
							{
								"f": "3*sin(2.0*x-1.0471975511965976)",
								"c": "cyan"
							}
						],
						"pts": [
							{
								"x": 1.309,
								"y": 3,
								"label": "(5π/12, 3)"
							},
							{
								"x": 0.5236,
								"y": 0,
								"label": ""
							}
						]
					},
					"steps": [
						{
							"t": "judge",
							"q": "振幅 3、週期 π，最高點在 x = 5π/12：代進去看是不是最大值。",
							"cards": [
								{
									"s": "y = 3 sin(2x − π/3)",
									"ok": true,
									"why": "x = 5π/12：2x − π/3 = π/2"
								},
								{
									"s": "y = 3 cos(2x − 5π/6)",
									"ok": true,
									"why": "x = 5π/12：2x − 5π/6 = 0，cos 0 = 1"
								},
								{
									"s": "y = −3 sin(2x + 2π/3)",
									"ok": true,
									"why": "x = 5π/12：−3 sin(3π/2) = 3"
								},
								{
									"s": "y = 3 sin(2x − π/6)",
									"ok": false,
									"why": "x = 5π/12：3 sin(2π/3) = 3√{3}/2，不是最大值"
								},
								{
									"s": "y = 3 sin 2(x − π/3)",
									"ok": false,
									"why": "= 3 sin(2x − 2π/3)，x = 5π/12 時是 3 sin(π/6) = 3/2"
								}
							]
						}
					]
				},
				{
					"stem": "圖是一個正弦波的一部分，最高點 (π/12, 2)、和 x 軸交於 (−π/12, 0)。下列哪些函數的圖形就是它？",
					"plot": {
						"x": [
							-0.9,
							2.5
						],
						"y": [
							-2.6,
							2.6
						],
						"pi": 12,
						"pi_lab": 4,
						"curves": [
							{
								"f": "2*sin(3.0*x+0.7853981633974483)",
								"c": "cyan"
							}
						],
						"pts": [
							{
								"x": 0.2618,
								"y": 2,
								"label": "(π/12, 2)"
							},
							{
								"x": -0.2618,
								"y": 0,
								"label": ""
							}
						]
					},
					"steps": [
						{
							"t": "judge",
							"q": "振幅 2、週期 2π/3，最高點在 x = π/12：代進去看是不是最大值。",
							"cards": [
								{
									"s": "y = 2 sin(3x + π/4)",
									"ok": true,
									"why": "x = π/12：3x + π/4 = π/2"
								},
								{
									"s": "y = 2 cos(3x − π/4)",
									"ok": true,
									"why": "x = π/12：3x − π/4 = 0，cos 0 = 1"
								},
								{
									"s": "y = −2 sin(3x − 3π/4)",
									"ok": true,
									"why": "x = π/12：−2 sin(−π/2) = 2"
								},
								{
									"s": "y = 2 sin(3x + π/12)",
									"ok": false,
									"why": "x = π/12：2 sin(π/3) = √{3}，不是最大值"
								},
								{
									"s": "y = 2 sin 3(x + π/4)",
									"ok": false,
									"why": "= 2 sin(3x + 3π/4)，x = π/12 時是 2 sin π = 0"
								}
							]
						}
					]
				}
			]
		},
		{
			"id": "tg_read",
			"kind": "graph",
			"tier": 1,
			"title": "看圖寫式子",
			"tmul": 1.1,
			"stem": "圖是 y = a sin(bx + c) + d 的一段（a > 0、b > 0、0 ≤ c < 2π），最高點 (π/6, 5)，相鄰的最低點 (2π/3, −1)。求 a、b、c、d。",
			"plot": {
				"x": [
					-0.4,
					3.4
				],
				"y": [
					-1.8,
					5.8
				],
				"pi": 6,
				"pi_lab": 6,
				"curves": [
					{
						"f": "3*sin(2.0*x+0.16666666666666666*3.141592653589793)+2",
						"c": "cyan"
					}
				],
				"pts": [
					{
						"x": 0.5236,
						"y": 5,
						"label": "(π/6, 5)"
					},
					{
						"x": 2.0944,
						"y": -1,
						"label": "(2π/3, −1)",
						"off": [
							-60,
							20
						]
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "振幅是最高和最低差的一半，中線是兩者的平均：",
					"template": "a = (5 − (−1))/2 = [0]，d = (5 + (−1))/2 = [1]",
					"ans": [
						"3",
						"2"
					],
					"hint": "6/2、4/2"
				},
				{
					"t": "fill",
					"q": "最高點到相鄰的最低點，是半個週期：",
					"template": "T/2 = 2π/3 − π/6 = [0]π",
					"ans": [
						"1/2"
					],
					"hint": "兩個 x 坐標相減"
				},
				{
					"t": "fill",
					"q": "所以週期 T = π：",
					"template": "b = 2π/T = [0]",
					"ans": [
						"2"
					],
					"hint": "2π/π"
				},
				{
					"t": "fill",
					"q": "最高點的時候 bx + c = π/2：",
					"template": "2 · π/6 + c = π/2 ⇒ c = [0]π",
					"ans": [
						"1/6"
					],
					"hint": "π/2 − π/3"
				}
			],
			"vars": [
				{
					"stem": "圖是 y = a sin(bx + c) + d 的一段（a > 0、b > 0、0 ≤ c < 2π），最高點 (π/12, 3)，相鄰的最低點 (5π/12, −1)。求 a、b、c、d。",
					"plot": {
						"x": [
							-0.3,
							2.0
						],
						"y": [
							-1.8,
							3.8
						],
						"pi": 12,
						"pi_lab": 4,
						"curves": [
							{
								"f": "2*sin(3.0*x+0.25*3.141592653589793)+1",
								"c": "cyan"
							}
						],
						"pts": [
							{
								"x": 0.2618,
								"y": 3,
								"label": "(π/12, 3)"
							},
							{
								"x": 1.309,
								"y": -1,
								"label": "(5π/12, −1)",
								"off": [
									-60,
									20
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "振幅是最高和最低差的一半，中線是兩者的平均：",
							"template": "a = (3 − (−1))/2 = [0]，d = (3 + (−1))/2 = [1]",
							"ans": [
								"2",
								"1"
							],
							"hint": "4/2、2/2"
						},
						{
							"t": "fill",
							"q": "最高點到相鄰的最低點，是半個週期：",
							"template": "T/2 = 5π/12 − π/12 = [0]π",
							"ans": [
								"1/3"
							],
							"hint": "兩個 x 坐標相減"
						},
						{
							"t": "fill",
							"q": "所以週期 T = 2π/3：",
							"template": "b = 2π/T = [0]",
							"ans": [
								"3"
							],
							"hint": "2π 除以 2π/3"
						},
						{
							"t": "fill",
							"q": "最高點的時候 bx + c = π/2：",
							"template": "3 · π/12 + c = π/2 ⇒ c = [0]π",
							"ans": [
								"1/4"
							],
							"hint": "π/2 − π/4"
						}
					]
				},
				{
					"stem": "圖是 y = a sin(bx + c) + d 的一段（a > 0、b > 0、0 ≤ c < 2π），最高點 (π/3, 3)，相鄰的最低點 (7π/3, −5)。求 a、b、c、d。",
					"plot": {
						"x": [
							-0.8,
							8.4
						],
						"y": [
							-5.8,
							3.8
						],
						"pi": 3,
						"pi_lab": 3,
						"curves": [
							{
								"f": "4*sin(0.5*x+0.3333333333333333*3.141592653589793)-1",
								"c": "cyan"
							}
						],
						"pts": [
							{
								"x": 1.0472,
								"y": 3,
								"label": "(π/3, 3)"
							},
							{
								"x": 7.3304,
								"y": -5,
								"label": "(7π/3, −5)",
								"off": [
									-60,
									20
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "振幅是最高和最低差的一半，中線是兩者的平均：",
							"template": "a = (3 − (−5))/2 = [0]，d = (3 + (−5))/2 = [1]",
							"ans": [
								"4",
								"−1"
							],
							"hint": "8/2、−2/2"
						},
						{
							"t": "fill",
							"q": "最高點到相鄰的最低點，是半個週期：",
							"template": "T/2 = 7π/3 − π/3 = [0]π",
							"ans": [
								"2"
							],
							"hint": "兩個 x 坐標相減"
						},
						{
							"t": "fill",
							"q": "所以週期 T = 4π：",
							"template": "b = 2π/T = [0]",
							"ans": [
								"1/2"
							],
							"hint": "2π 除以 4π"
						},
						{
							"t": "fill",
							"q": "最高點的時候 bx + c = π/2：",
							"template": "1/2 · π/3 + c = π/2 ⇒ c = [0]π",
							"ans": [
								"1/3"
							],
							"hint": "π/2 − π/6"
						}
					]
				}
			]
		},
		{
			"id": "tg_pick",
			"kind": "graph",
			"tier": 1,
			"title": "認出那條波",
			"tmul": 1.0,
			"stem": "(1) 哪一張的實線是 y = 2 sin(x − π/4)？（虛線是 y = 2 sin x）\n(2) 它和 y 軸交於 (0, k)，求 k",
			"steps": [
				{
					"t": "pick",
					"q": "哪一張的實線是 y = 2 sin(x − π/4)？",
					"graphs": [
						{
							"x": [
								-0.6,
								6.9
							],
							"y": [
								-3,
								3
							],
							"pi": 2,
							"curves": [
								{
									"f": "2*sin(x)",
									"c": "dim",
									"dash": true
								},
								{
									"f": "2*sin(x-0.25*3.141592653589793)",
									"c": "cyan"
								}
							]
						},
						{
							"x": [
								-0.6,
								6.9
							],
							"y": [
								-3,
								3
							],
							"pi": 2,
							"curves": [
								{
									"f": "2*sin(x)",
									"c": "dim",
									"dash": true
								},
								{
									"f": "2*sin(x+0.25*3.141592653589793)",
									"c": "cyan"
								}
							]
						},
						{
							"x": [
								-0.6,
								6.9
							],
							"y": [
								-3,
								3
							],
							"pi": 2,
							"curves": [
								{
									"f": "2*sin(x)",
									"c": "dim",
									"dash": true
								},
								{
									"f": "2*sin(2*x-0.25*3.141592653589793)",
									"c": "cyan"
								}
							]
						},
						{
							"x": [
								-0.6,
								6.9
							],
							"y": [
								-3,
								3
							],
							"pi": 2,
							"curves": [
								{
									"f": "2*sin(x)",
									"c": "dim",
									"dash": true
								},
								{
									"f": "-2*sin(x-0.25*3.141592653589793)",
									"c": "cyan"
								}
							]
						},
						{
							"x": [
								-0.6,
								6.9
							],
							"y": [
								-3,
								3
							],
							"pi": 2,
							"curves": [
								{
									"f": "2*sin(x)",
									"c": "dim",
									"dash": true
								},
								{
									"f": "sin(x-0.25*3.141592653589793)",
									"c": "cyan"
								}
							]
						}
					],
					"whys": [
						"",
						"這是往左移 π/4",
						"週期變成 π 了",
						"上下翻轉了",
						"振幅只有 1"
					],
					"hint": "x − π/4：整條波往右移 π/4，振幅還是 2",
					"write": "y = 2 sin(x − π/4)：往右移 π/4，振幅 2"
				},
				{
					"t": "fill",
					"q": "(2) x = 0 代入：",
					"template": "k = 2 sin(−π/4) = [0]",
					"ans": [
						"−√2"
					],
					"hint": "sin(−π/4) = −√{2}/2"
				}
			],
			"vars": [
				{
					"stem": "(1) 哪一張的實線是 y = 2 sin(x − π/3)？（虛線是 y = 2 sin x）\n(2) 它和 y 軸交於 (0, k)，求 k",
					"steps": [
						{
							"t": "pick",
							"q": "哪一張的實線是 y = 2 sin(x − π/3)？",
							"graphs": [
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-3,
										3
									],
									"pi": 2,
									"curves": [
										{
											"f": "2*sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "2*sin(x-0.3333333333333333*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-3,
										3
									],
									"pi": 2,
									"curves": [
										{
											"f": "2*sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "2*sin(x+0.3333333333333333*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-3,
										3
									],
									"pi": 2,
									"curves": [
										{
											"f": "2*sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "2*sin(2*x-0.3333333333333333*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-3,
										3
									],
									"pi": 2,
									"curves": [
										{
											"f": "2*sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "-2*sin(x-0.3333333333333333*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-3,
										3
									],
									"pi": 2,
									"curves": [
										{
											"f": "2*sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "sin(x-0.3333333333333333*3.141592653589793)",
											"c": "cyan"
										}
									]
								}
							],
							"whys": [
								"",
								"這是往左移 π/3",
								"週期變成 π 了",
								"上下翻轉了",
								"振幅只有 1"
							],
							"hint": "x − π/3：整條波往右移 π/3，振幅還是 2",
							"write": "y = 2 sin(x − π/3)：往右移 π/3，振幅 2"
						},
						{
							"t": "fill",
							"q": "(2) x = 0 代入：",
							"template": "k = 2 sin(−π/3) = [0]",
							"ans": [
								"−√3"
							],
							"hint": "sin(−π/3) = −√{3}/2"
						}
					]
				},
				{
					"stem": "(1) 哪一張的實線是 y = 2 sin(x + π/3)？（虛線是 y = 2 sin x）\n(2) 它和 y 軸交於 (0, k)，求 k",
					"steps": [
						{
							"t": "pick",
							"q": "哪一張的實線是 y = 2 sin(x + π/3)？",
							"graphs": [
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-3,
										3
									],
									"pi": 2,
									"curves": [
										{
											"f": "2*sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "2*sin(x+0.3333333333333333*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-3,
										3
									],
									"pi": 2,
									"curves": [
										{
											"f": "2*sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "2*sin(x-0.3333333333333333*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-3,
										3
									],
									"pi": 2,
									"curves": [
										{
											"f": "2*sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "2*sin(2*x+0.3333333333333333*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-3,
										3
									],
									"pi": 2,
									"curves": [
										{
											"f": "2*sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "-2*sin(x+0.3333333333333333*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-3,
										3
									],
									"pi": 2,
									"curves": [
										{
											"f": "2*sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "sin(x+0.3333333333333333*3.141592653589793)",
											"c": "cyan"
										}
									]
								}
							],
							"whys": [
								"",
								"這是往右移 π/3",
								"週期變成 π 了",
								"上下翻轉了",
								"振幅只有 1"
							],
							"hint": "x + π/3：整條波往左移 π/3，振幅還是 2",
							"write": "y = 2 sin(x + π/3)：往左移 π/3，振幅 2"
						},
						{
							"t": "fill",
							"q": "(2) x = 0 代入：",
							"template": "k = 2 sin(π/3) = [0]",
							"ans": [
								"√3"
							],
							"hint": "sin(π/3) = √{3}/2"
						}
					]
				}
			]
		},
		{
			"id": "tg_steps",
			"kind": "graph",
			"tier": 2,
			"title": "四個步驟",
			"tmul": 1.25,
			"stem": "y = sin x 依序 ① 鉛直伸縮 a 倍 ② 向左平移 b ③ 水平伸縮 c 倍 ④ 向上平移 d，得到 y = 3 sin(2x + π/2) − 1。\n(1) 求 a、b、c、d　(2) 若 ②、③ 對調，要向左平移多少？",
			"steps": [
				{
					"t": "fill",
					"q": "鉛直伸縮管 sin 前面的倍數，上下平移管後面加的數：",
					"template": "a = [0]，d = [1]",
					"ans": [
						"3",
						"−1"
					],
					"hint": "向上平移 −1 就是往下 1",
					"part": "(1)"
				},
				{
					"t": "choice",
					"q": "② 之後是 sin(x + b)，③ 再水平伸縮 c 倍，變成？",
					"opts": [
						"sin(x/c + b)",
						"sin(cx + b)",
						"sin(c(x + b))",
						"sin(x/c + b/c)"
					],
					"hint": "水平伸縮 c 倍：x 換成 x/c，其他不動",
					"write": "sin(x + b) → sin(x/c + b) = sin(2x + π/2)",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "對照 sin(2x + π/2)：",
					"template": "1/c = 2 ⇒ c = [0]，b = [1]π",
					"ans": [
						"1/2",
						"1/2"
					],
					"hint": "x 的係數對 x 的係數、常數對常數",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "要等於 sin(2x + π/2)：",
					"template": "2h = π/2 ⇒ h = [0]π",
					"ans": [
						"1/4"
					],
					"hint": "π/2 除以 2",
					"part": "(2)",
					"pre": "(2)　先水平伸縮：sin 2x，再左移 h：sin 2(x + h) = sin(2x + 2h)"
				}
			],
			"vars": [
				{
					"stem": "y = sin x 依序 ① 鉛直伸縮 a 倍 ② 向左平移 b ③ 水平伸縮 c 倍 ④ 向上平移 d，得到 y = 2 sin(3x + π/2) + 1。\n(1) 求 a、b、c、d　(2) 若 ②、③ 對調，要向左平移多少？",
					"steps": [
						{
							"t": "fill",
							"q": "鉛直伸縮管 sin 前面的倍數，上下平移管後面加的數：",
							"template": "a = [0]，d = [1]",
							"ans": [
								"2",
								"1"
							],
							"hint": "向上平移 1",
							"part": "(1)"
						},
						{
							"t": "choice",
							"q": "② 之後是 sin(x + b)，③ 再水平伸縮 c 倍，變成？",
							"opts": [
								"sin(x/c + b)",
								"sin(cx + b)",
								"sin(c(x + b))",
								"sin(x/c + b/c)"
							],
							"hint": "水平伸縮 c 倍：x 換成 x/c，其他不動",
							"write": "sin(x + b) → sin(x/c + b) = sin(3x + π/2)",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "對照 sin(3x + π/2)：",
							"template": "1/c = 3 ⇒ c = [0]，b = [1]π",
							"ans": [
								"1/3",
								"1/2"
							],
							"hint": "x 的係數對 x 的係數、常數對常數",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "要等於 sin(3x + π/2)：",
							"template": "3h = π/2 ⇒ h = [0]π",
							"ans": [
								"1/6"
							],
							"hint": "π/2 除以 3",
							"part": "(2)",
							"pre": "(2)　先水平伸縮：sin 3x，再左移 h：sin 3(x + h) = sin(3x + 3h)"
						}
					]
				},
				{
					"stem": "y = sin x 依序 ① 鉛直伸縮 a 倍 ② 向左平移 b ③ 水平伸縮 c 倍 ④ 向上平移 d，得到 y = 4 sin(x/2 + π/6) + 2。\n(1) 求 a、b、c、d　(2) 若 ②、③ 對調，要向左平移多少？",
					"steps": [
						{
							"t": "fill",
							"q": "鉛直伸縮管 sin 前面的倍數，上下平移管後面加的數：",
							"template": "a = [0]，d = [1]",
							"ans": [
								"4",
								"2"
							],
							"hint": "向上平移 2",
							"part": "(1)"
						},
						{
							"t": "choice",
							"q": "② 之後是 sin(x + b)，③ 再水平伸縮 c 倍，變成？",
							"opts": [
								"sin(x/c + b)",
								"sin(cx + b)",
								"sin(c(x + b))",
								"sin(x/c + b/c)"
							],
							"hint": "水平伸縮 c 倍：x 換成 x/c，其他不動",
							"write": "sin(x + b) → sin(x/c + b) = sin(x/2 + π/6)",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "對照 sin(x/2 + π/6)：",
							"template": "1/c = 1/2 ⇒ c = [0]，b = [1]π",
							"ans": [
								"2",
								"1/6"
							],
							"hint": "x 的係數對 x 的係數、常數對常數",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "要等於 sin(x/2 + π/6)：",
							"template": "h/2 = π/6 ⇒ h = [0]π",
							"ans": [
								"1/3"
							],
							"hint": "π/6 乘 2",
							"part": "(2)",
							"pre": "(2)　先水平伸縮：sin(x/2)，再左移 h：sin((x + h)/2) = sin(x/2 + h/2)"
						}
					]
				}
			]
		},
		{
			"id": "tg_cond",
			"kind": "graph",
			"tier": 2,
			"title": "從條件找波形",
			"tmul": 1.3,
			"stem": "f(x) = a sin(bx + c) + d（a > 0、b > 0、0 ≤ c < 2π），已知：\n① f(0) = f(4) = f(12) = 1　② 0 < x < 4 時 f(x) > 1\n③ 4 < x < 12 時 f(x) < 1　④ f 的最大值是 5。求 a、b、c、d。",
			"plot": {
				"x": [
					-1.0,
					13.0
				],
				"y": [
					-12.0,
					6.5
				],
				"curves": [
					{
						"f": "8*sin(0.16666666666666666*3.141592653589793*x+3.141592653589793/6)-3",
						"c": "cyan",
						"at": 4
					},
					{
						"f": "1",
						"c": "faint",
						"dash": true
					}
				],
				"pts": [
					{
						"x": 0,
						"y": 1,
						"label": ""
					},
					{
						"x": 4,
						"y": 1,
						"label": ""
					},
					{
						"x": 12,
						"y": 1,
						"label": ""
					},
					{
						"x": 2,
						"y": 5,
						"label": "(2, 5)",
						"at": 2
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "從 0 開始，大於 1、小於 1，到 12 又回到 1：剛好一個週期。",
					"template": "T = [0]，b = 2π/T = [1]π",
					"ans": [
						"12",
						"1/6"
					],
					"hint": "0 到 12 走完「上去、下來」一整輪"
				},
				{
					"t": "fill",
					"q": "0 到 4 這一段在上面，最高點在正中間，4 到 12 在下面，最低點也在正中間。",
					"template": "最高點 x = [0]，最低點 x = [1]",
					"ans": [
						"2",
						"8"
					],
					"hint": "兩段的中點"
				},
				{
					"t": "fill",
					"q": "最高點時 bx + c = π/2：",
					"template": "π/6 · 2 + c = π/2 ⇒ c = [0]π",
					"ans": [
						"1/6"
					],
					"hint": "π/2 − π/3"
				},
				{
					"t": "fill",
					"q": "f(0) = 1：",
					"template": "a sin(π/6) + d = 1 ⇒ [0]a + d = 1",
					"ans": [
						"1/2"
					],
					"hint": "sin(π/6) = 1/2"
				},
				{
					"t": "fill",
					"q": "最大值 a + d = 5，和上一行聯立：",
					"template": "答：a = [0]，d = [1]",
					"ans": [
						"8",
						"−3"
					],
					"hint": "兩式相減：a/2 = 4"
				}
			],
			"vars": [
				{
					"stem": "f(x) = a sin(bx + c) + d（a > 0、b > 0、0 ≤ c < 2π），已知：\n① f(0) = f(2) = f(6) = 2　② 0 < x < 2 時 f(x) > 2\n③ 2 < x < 6 時 f(x) < 2　④ f 的最大值是 6。求 a、b、c、d。",
					"plot": {
						"x": [
							-1.0,
							7.0
						],
						"y": [
							-11.0,
							7.5
						],
						"curves": [
							{
								"f": "8*sin(0.3333333333333333*3.141592653589793*x+3.141592653589793/6)-2",
								"c": "cyan",
								"at": 4
							},
							{
								"f": "2",
								"c": "faint",
								"dash": true
							}
						],
						"pts": [
							{
								"x": 0,
								"y": 2,
								"label": ""
							},
							{
								"x": 2,
								"y": 2,
								"label": ""
							},
							{
								"x": 6,
								"y": 2,
								"label": ""
							},
							{
								"x": 1,
								"y": 6,
								"label": "(1, 6)",
								"at": 2
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "從 0 開始，大於 2、小於 2，到 6 又回到 2：剛好一個週期。",
							"template": "T = [0]，b = 2π/T = [1]π",
							"ans": [
								"6",
								"1/3"
							],
							"hint": "0 到 6 走完「上去、下來」一整輪"
						},
						{
							"t": "fill",
							"q": "0 到 2 這一段在上面，最高點在正中間，2 到 6 在下面，最低點也在正中間。",
							"template": "最高點 x = [0]，最低點 x = [1]",
							"ans": [
								"1",
								"4"
							],
							"hint": "兩段的中點"
						},
						{
							"t": "fill",
							"q": "最高點時 bx + c = π/2：",
							"template": "π/3 · 1 + c = π/2 ⇒ c = [0]π",
							"ans": [
								"1/6"
							],
							"hint": "π/2 − π/3"
						},
						{
							"t": "fill",
							"q": "f(0) = 2：",
							"template": "a sin(π/6) + d = 2 ⇒ [0]a + d = 2",
							"ans": [
								"1/2"
							],
							"hint": "sin(π/6) = 1/2"
						},
						{
							"t": "fill",
							"q": "最大值 a + d = 6，和上一行聯立：",
							"template": "答：a = [0]，d = [1]",
							"ans": [
								"8",
								"−2"
							],
							"hint": "兩式相減：a/2 = 4"
						}
					]
				},
				{
					"stem": "f(x) = a sin(bx + c) + d（a > 0、b > 0、0 ≤ c < 2π），已知：\n① f(0) = f(6) = f(18) = 0　② 0 < x < 6 時 f(x) > 0\n③ 6 < x < 18 時 f(x) < 0　④ f 的最大值是 4。求 a、b、c、d。",
					"plot": {
						"x": [
							-1.0,
							19.0
						],
						"y": [
							-13.0,
							5.5
						],
						"curves": [
							{
								"f": "8*sin(0.1111111111111111*3.141592653589793*x+3.141592653589793/6)-4",
								"c": "cyan",
								"at": 4
							},
							{
								"f": "0",
								"c": "faint",
								"dash": true
							}
						],
						"pts": [
							{
								"x": 0,
								"y": 0,
								"label": ""
							},
							{
								"x": 6,
								"y": 0,
								"label": ""
							},
							{
								"x": 18,
								"y": 0,
								"label": ""
							},
							{
								"x": 3,
								"y": 4,
								"label": "(3, 4)",
								"at": 2
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "從 0 開始，大於 0、小於 0，到 18 又回到 0：剛好一個週期。",
							"template": "T = [0]，b = 2π/T = [1]π",
							"ans": [
								"18",
								"1/9"
							],
							"hint": "0 到 18 走完「上去、下來」一整輪"
						},
						{
							"t": "fill",
							"q": "0 到 6 這一段在上面，最高點在正中間，6 到 18 在下面，最低點也在正中間。",
							"template": "最高點 x = [0]，最低點 x = [1]",
							"ans": [
								"3",
								"12"
							],
							"hint": "兩段的中點"
						},
						{
							"t": "fill",
							"q": "最高點時 bx + c = π/2：",
							"template": "π/9 · 3 + c = π/2 ⇒ c = [0]π",
							"ans": [
								"1/6"
							],
							"hint": "π/2 − π/3"
						},
						{
							"t": "fill",
							"q": "f(0) = 0：",
							"template": "a sin(π/6) + d = 0 ⇒ [0]a + d = 0",
							"ans": [
								"1/2"
							],
							"hint": "sin(π/6) = 1/2"
						},
						{
							"t": "fill",
							"q": "最大值 a + d = 4，和上一行聯立：",
							"template": "答：a = [0]，d = [1]",
							"ans": [
								"8",
								"−4"
							],
							"hint": "兩式相減：a/2 = 4"
						}
					]
				}
			]
		},
		{
			"id": "tg_tri",
			"kind": "graph",
			"tier": 3,
			"title": "波上的正三角形",
			"tmul": 1.35,
			"stem": "y = a sin(bx)（a > 0、b > 0）的圖形上，A(1, √{3}) 是一個最高點，A 和下一個最高點 B、以及它們之間的最低點 C 剛好是正三角形。\n求 a、b 與 C 的坐標。",
			"plot": {
				"x": [
					-0.6,
					6.2
				],
				"y": [
					-2.4249,
					2.4249
				],
				"curves": [
					{
						"f": "1.7320508075688772*sin(0.5*3.141592653589793*x)",
						"c": "cyan"
					}
				],
				"shapes": [
					{
						"k": "poly",
						"pts": [
							[
								1,
								1.7321
							],
							[
								5,
								1.7321
							],
							[
								3,
								-1.7321
							]
						],
						"c": "gold",
						"fill": "gold",
						"alpha": 0.12,
						"at": 1
					}
				],
				"pts": [
					{
						"x": 1,
						"y": 1.7321,
						"label": "A"
					},
					{
						"x": 5,
						"y": 1.7321,
						"label": "B",
						"at": 3
					},
					{
						"x": 3,
						"y": -1.7321,
						"label": "C",
						"at": 5
					}
				]
			},
			"steps": [
				{
					"t": "choice",
					"q": "設週期 T。△ABC 的邊長、高各是？",
					"opts": [
						"邊長 T，高 2a",
						"邊長 T/2，高 a",
						"邊長 T，高 a",
						"邊長 2T，高 2a"
					],
					"hint": "相鄰兩個最高點差一個週期，最高到最低的落差是 2a",
					"write": "\\ol{AB} = T，高 = 2a"
				},
				{
					"t": "fill",
					"q": "A 是最高點：",
					"template": "a = [0]",
					"ans": [
						"√3"
					],
					"hint": "最高點的 y 坐標就是 a"
				},
				{
					"t": "fill",
					"q": "正三角形的高 = (√{3}/2) × 邊長：",
					"template": "2√{3} = (√{3}/2)T ⇒ T = [0]",
					"ans": [
						"4"
					],
					"hint": "兩邊同除以 √{3}/2"
				},
				{
					"t": "fill",
					"q": "週期 T = 4：",
					"template": "b = 2π/T = [0]π",
					"ans": [
						"1/2"
					],
					"hint": "2π/4"
				},
				{
					"t": "fill",
					"q": "B 的 x 坐標是 1 + T = 5。C 在 A、B 的正中間，是最低點：",
					"template": "答：C([0], [1])",
					"ans": [
						"3",
						"−√3"
					],
					"hint": "x 取中點，y 是最小值 −a"
				}
			],
			"vars": [
				{
					"stem": "y = a sin(bx)（a > 0、b > 0）的圖形上，A(2, 2√{3}) 是一個最高點，A 和下一個最高點 B、以及它們之間的最低點 C 剛好是正三角形。\n求 a、b 與 C 的坐標。",
					"plot": {
						"x": [
							-1.2,
							12.4
						],
						"y": [
							-4.8497,
							4.8497
						],
						"curves": [
							{
								"f": "3.4641016151377544*sin(0.25*3.141592653589793*x)",
								"c": "cyan"
							}
						],
						"shapes": [
							{
								"k": "poly",
								"pts": [
									[
										2,
										3.4641
									],
									[
										10,
										3.4641
									],
									[
										6,
										-3.4641
									]
								],
								"c": "gold",
								"fill": "gold",
								"alpha": 0.12,
								"at": 1
							}
						],
						"pts": [
							{
								"x": 2,
								"y": 3.4641,
								"label": "A"
							},
							{
								"x": 10,
								"y": 3.4641,
								"label": "B",
								"at": 3
							},
							{
								"x": 6,
								"y": -3.4641,
								"label": "C",
								"at": 5
							}
						]
					},
					"steps": [
						{
							"t": "choice",
							"q": "設週期 T。△ABC 的邊長、高各是？",
							"opts": [
								"邊長 T，高 2a",
								"邊長 T/2，高 a",
								"邊長 T，高 a",
								"邊長 2T，高 2a"
							],
							"hint": "相鄰兩個最高點差一個週期，最高到最低的落差是 2a",
							"write": "\\ol{AB} = T，高 = 2a"
						},
						{
							"t": "fill",
							"q": "A 是最高點：",
							"template": "a = [0]",
							"ans": [
								"2√3"
							],
							"hint": "最高點的 y 坐標就是 a"
						},
						{
							"t": "fill",
							"q": "正三角形的高 = (√{3}/2) × 邊長：",
							"template": "4√{3} = (√{3}/2)T ⇒ T = [0]",
							"ans": [
								"8"
							],
							"hint": "兩邊同除以 √{3}/2"
						},
						{
							"t": "fill",
							"q": "週期 T = 8：",
							"template": "b = 2π/T = [0]π",
							"ans": [
								"1/4"
							],
							"hint": "2π/8"
						},
						{
							"t": "fill",
							"q": "B 的 x 坐標是 2 + T = 10。C 在 A、B 的正中間，是最低點：",
							"template": "答：C([0], [1])",
							"ans": [
								"6",
								"−2√3"
							],
							"hint": "x 取中點，y 是最小值 −a"
						}
					]
				},
				{
					"stem": "y = a sin(bx)（a > 0、b > 0）的圖形上，A(1/2, √{3}/2) 是一個最高點，A 和下一個最高點 B、以及它們之間的最低點 C 剛好是正三角形。\n求 a、b 與 C 的坐標。",
					"plot": {
						"x": [
							-0.3,
							3.1
						],
						"y": [
							-1.2124,
							1.2124
						],
						"curves": [
							{
								"f": "0.8660254037844386*sin(1.0*3.141592653589793*x)",
								"c": "cyan"
							}
						],
						"shapes": [
							{
								"k": "poly",
								"pts": [
									[
										0.5,
										0.866
									],
									[
										2.5,
										0.866
									],
									[
										1.5,
										-0.866
									]
								],
								"c": "gold",
								"fill": "gold",
								"alpha": 0.12,
								"at": 1
							}
						],
						"pts": [
							{
								"x": 0.5,
								"y": 0.866,
								"label": "A"
							},
							{
								"x": 2.5,
								"y": 0.866,
								"label": "B",
								"at": 3
							},
							{
								"x": 1.5,
								"y": -0.866,
								"label": "C",
								"at": 5
							}
						]
					},
					"steps": [
						{
							"t": "choice",
							"q": "設週期 T。△ABC 的邊長、高各是？",
							"opts": [
								"邊長 T，高 2a",
								"邊長 T/2，高 a",
								"邊長 T，高 a",
								"邊長 2T，高 2a"
							],
							"hint": "相鄰兩個最高點差一個週期，最高到最低的落差是 2a",
							"write": "\\ol{AB} = T，高 = 2a"
						},
						{
							"t": "fill",
							"q": "A 是最高點：",
							"template": "a = [0]",
							"ans": [
								"√3/2"
							],
							"hint": "最高點的 y 坐標就是 a"
						},
						{
							"t": "fill",
							"q": "正三角形的高 = (√{3}/2) × 邊長：",
							"template": "√{3} = (√{3}/2)T ⇒ T = [0]",
							"ans": [
								"2"
							],
							"hint": "兩邊同除以 √{3}/2"
						},
						{
							"t": "fill",
							"q": "週期 T = 2：",
							"template": "b = 2π/T = [0]π",
							"ans": [
								"1"
							],
							"hint": "2π/2"
						},
						{
							"t": "fill",
							"q": "B 的 x 坐標是 1/2 + T = 5/2。C 在 A、B 的正中間，是最低點：",
							"template": "答：C([0], [1])",
							"ans": [
								"3/2",
								"−√3/2"
							],
							"hint": "x 取中點，y 是最小值 −a"
						}
					]
				}
			]
		},
		{
			"id": "tg_squeeze",
			"kind": "graph",
			"tier": 2,
			"title": "壓縮後的波",
			"tmul": 1.1,
			"stem": "(1) 哪一張的實線是 y = sin(2x + π/3)？（虛線是 y = sin x）\n(2) x > 0 的第一個最高點，x 坐標是多少？",
			"steps": [
				{
					"t": "pick",
					"q": "哪一張的實線是 y = sin(2x + π/3)？",
					"graphs": [
						{
							"x": [
								-0.6,
								6.9
							],
							"y": [
								-1.6,
								1.6
							],
							"pi": 2,
							"curves": [
								{
									"f": "sin(x)",
									"c": "dim",
									"dash": true
								},
								{
									"f": "sin(2.0*x+0.3333333333333333*3.141592653589793)",
									"c": "cyan"
								}
							]
						},
						{
							"x": [
								-0.6,
								6.9
							],
							"y": [
								-1.6,
								1.6
							],
							"pi": 2,
							"curves": [
								{
									"f": "sin(x)",
									"c": "dim",
									"dash": true
								},
								{
									"f": "sin(2.0*(x+0.3333333333333333*3.141592653589793))",
									"c": "cyan"
								}
							]
						},
						{
							"x": [
								-0.6,
								6.9
							],
							"y": [
								-1.6,
								1.6
							],
							"pi": 2,
							"curves": [
								{
									"f": "sin(x)",
									"c": "dim",
									"dash": true
								},
								{
									"f": "sin(x/2.0+0.3333333333333333*3.141592653589793)",
									"c": "cyan"
								}
							]
						},
						{
							"x": [
								-0.6,
								6.9
							],
							"y": [
								-1.6,
								1.6
							],
							"pi": 2,
							"curves": [
								{
									"f": "sin(x)",
									"c": "dim",
									"dash": true
								},
								{
									"f": "sin(2.0*x-0.3333333333333333*3.141592653589793)",
									"c": "cyan"
								}
							]
						},
						{
							"x": [
								-0.6,
								6.9
							],
							"y": [
								-1.6,
								1.6
							],
							"pi": 2,
							"curves": [
								{
									"f": "sin(x)",
									"c": "dim",
									"dash": true
								},
								{
									"f": "sin(x+0.3333333333333333*3.141592653589793)",
									"c": "cyan"
								}
							]
						}
					],
					"whys": [
						"",
						"這是 sin 2(x + π/3)：左移太多了",
						"週期變成 4π 了",
						"這是往右移",
						"週期還是 2π"
					],
					"hint": "sin(2x + π/3) = sin 2(x + π/6)：週期 π，往左移 π/6",
					"write": "sin(2x + π/3) = sin 2(x + π/6)：週期 π，左移 π/6"
				},
				{
					"t": "fill",
					"q": "(2) 最高點時 2x + π/3 = π/2：",
					"template": "x = [0]π",
					"ans": [
						"1/12"
					],
					"hint": "2x = π/6"
				}
			],
			"vars": [
				{
					"stem": "(1) 哪一張的實線是 y = sin(3x + π/6)？（虛線是 y = sin x）\n(2) x > 0 的第一個最高點，x 坐標是多少？",
					"steps": [
						{
							"t": "pick",
							"q": "哪一張的實線是 y = sin(3x + π/6)？",
							"graphs": [
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-1.6,
										1.6
									],
									"pi": 2,
									"curves": [
										{
											"f": "sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "sin(3.0*x+0.16666666666666666*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-1.6,
										1.6
									],
									"pi": 2,
									"curves": [
										{
											"f": "sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "sin(3.0*(x+0.16666666666666666*3.141592653589793))",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-1.6,
										1.6
									],
									"pi": 2,
									"curves": [
										{
											"f": "sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "sin(x/3.0+0.16666666666666666*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-1.6,
										1.6
									],
									"pi": 2,
									"curves": [
										{
											"f": "sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "sin(3.0*x-0.16666666666666666*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-1.6,
										1.6
									],
									"pi": 2,
									"curves": [
										{
											"f": "sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "sin(x+0.16666666666666666*3.141592653589793)",
											"c": "cyan"
										}
									]
								}
							],
							"whys": [
								"",
								"這是 sin 3(x + π/6)：左移太多了",
								"週期變成 6π 了",
								"這是往右移",
								"週期還是 2π"
							],
							"hint": "sin(3x + π/6) = sin 3(x + π/18)：週期 2π/3，往左移 π/18",
							"write": "sin(3x + π/6) = sin 3(x + π/18)：週期 2π/3，左移 π/18"
						},
						{
							"t": "fill",
							"q": "(2) 最高點時 3x + π/6 = π/2：",
							"template": "x = [0]π",
							"ans": [
								"1/9"
							],
							"hint": "3x = π/3"
						}
					]
				},
				{
					"stem": "(1) 哪一張的實線是 y = sin(2x − π/4)？（虛線是 y = sin x）\n(2) x > 0 的第一個最高點，x 坐標是多少？",
					"steps": [
						{
							"t": "pick",
							"q": "哪一張的實線是 y = sin(2x − π/4)？",
							"graphs": [
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-1.6,
										1.6
									],
									"pi": 2,
									"curves": [
										{
											"f": "sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "sin(2.0*x-0.25*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-1.6,
										1.6
									],
									"pi": 2,
									"curves": [
										{
											"f": "sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "sin(2.0*(x-0.25*3.141592653589793))",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-1.6,
										1.6
									],
									"pi": 2,
									"curves": [
										{
											"f": "sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "sin(x/2.0-0.25*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-1.6,
										1.6
									],
									"pi": 2,
									"curves": [
										{
											"f": "sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "sin(2.0*x+0.25*3.141592653589793)",
											"c": "cyan"
										}
									]
								},
								{
									"x": [
										-0.6,
										6.9
									],
									"y": [
										-1.6,
										1.6
									],
									"pi": 2,
									"curves": [
										{
											"f": "sin(x)",
											"c": "dim",
											"dash": true
										},
										{
											"f": "sin(x-0.25*3.141592653589793)",
											"c": "cyan"
										}
									]
								}
							],
							"whys": [
								"",
								"這是 sin 2(x − π/4)：右移太多了",
								"週期變成 4π 了",
								"這是往左移",
								"週期還是 2π"
							],
							"hint": "sin(2x − π/4) = sin 2(x − π/8)：週期 π，往右移 π/8",
							"write": "sin(2x − π/4) = sin 2(x − π/8)：週期 π，右移 π/8"
						},
						{
							"t": "fill",
							"q": "(2) 最高點時 2x − π/4 = π/2：",
							"template": "x = [0]π",
							"ans": [
								"3/8"
							],
							"hint": "2x = 3π/4"
						}
					]
				}
			]
		},
		{
			"id": "tg_center",
			"kind": "graph",
			"tier": 3,
			"title": "對稱中心定參數",
			"tmul": 1.35,
			"stem": "f(x) = 2 sin(ax − π/3) + b，a > 0，週期 T 滿足 2π/3 < T < π，且 y = f(x) 的圖形對稱於點 (π/2, −1)。求 a、b。",
			"steps": [
				{
					"t": "fill",
					"q": "對稱中心一定在中線 y = b 上：",
					"template": "b = [0]",
					"ans": [
						"−1"
					],
					"hint": "對稱中心的 y 坐標"
				},
				{
					"t": "fill",
					"q": "對稱中心的地方 sin 那一項是 0：a · π/2 − π/3 = kπ（k 是整數）。",
					"template": "a · π/2 = kπ + π/3 ⇒ a = 2k + [0]",
					"ans": [
						"2/3"
					],
					"hint": "兩邊乘 2/π"
				},
				{
					"t": "fill",
					"q": "週期 T = 2π/a：2π/3 < 2π/a < π，兩邊除以 2π：",
					"template": "1/3 < 1/a < [0]",
					"ans": [
						"1/2"
					],
					"hint": "π/(2π)"
				},
				{
					"t": "fill",
					"q": "取倒數，不等號反過來：",
					"template": "[0] < a < [1]",
					"ans": [
						"2",
						"3"
					],
					"hint": "1/(1/2)、1/(1/3)"
				},
				{
					"t": "fill",
					"q": "2k + 2/3 落在 2 和 3 之間，k 只能是 1：",
					"template": "答：a = [0]，b = −1",
					"ans": [
						"8/3"
					],
					"hint": "2 · 1 + 2/3"
				}
			],
			"vars": [
				{
					"stem": "f(x) = 3 sin(ax − π/4) + b，a > 0，週期 T 滿足 2π/5 < T < π/2，且 y = f(x) 的圖形對稱於點 (π/2, 2)。求 a、b。",
					"steps": [
						{
							"t": "fill",
							"q": "對稱中心一定在中線 y = b 上：",
							"template": "b = [0]",
							"ans": [
								"2"
							],
							"hint": "對稱中心的 y 坐標"
						},
						{
							"t": "fill",
							"q": "對稱中心的地方 sin 那一項是 0：a · π/2 − π/4 = kπ（k 是整數）。",
							"template": "a · π/2 = kπ + π/4 ⇒ a = 2k + [0]",
							"ans": [
								"1/2"
							],
							"hint": "兩邊乘 2/π"
						},
						{
							"t": "fill",
							"q": "週期 T = 2π/a：2π/5 < 2π/a < π/2，兩邊除以 2π：",
							"template": "1/5 < 1/a < [0]",
							"ans": [
								"1/4"
							],
							"hint": "(π/2)/(2π)"
						},
						{
							"t": "fill",
							"q": "取倒數，不等號反過來：",
							"template": "[0] < a < [1]",
							"ans": [
								"4",
								"5"
							],
							"hint": "1/(1/4)、1/(1/5)"
						},
						{
							"t": "fill",
							"q": "2k + 1/2 落在 4 和 5 之間，k 只能是 2：",
							"template": "答：a = [0]，b = 2",
							"ans": [
								"9/2"
							],
							"hint": "2 · 2 + 1/2"
						}
					]
				},
				{
					"stem": "f(x) = 2 sin(ax − π/6) + b，a > 0，週期 T 滿足 π/2 < T < π，且 y = f(x) 的圖形對稱於點 (π/3, −3)。求 a、b。",
					"steps": [
						{
							"t": "fill",
							"q": "對稱中心一定在中線 y = b 上：",
							"template": "b = [0]",
							"ans": [
								"−3"
							],
							"hint": "對稱中心的 y 坐標"
						},
						{
							"t": "fill",
							"q": "對稱中心的地方 sin 那一項是 0：a · π/3 − π/6 = kπ（k 是整數）。",
							"template": "a · π/3 = kπ + π/6 ⇒ a = 3k + [0]",
							"ans": [
								"1/2"
							],
							"hint": "兩邊乘 3/π"
						},
						{
							"t": "fill",
							"q": "週期 T = 2π/a：π/2 < 2π/a < π，兩邊除以 2π：",
							"template": "1/4 < 1/a < [0]",
							"ans": [
								"1/2"
							],
							"hint": "π/(2π)"
						},
						{
							"t": "fill",
							"q": "取倒數，不等號反過來：",
							"template": "[0] < a < [1]",
							"ans": [
								"2",
								"4"
							],
							"hint": "1/(1/2)、1/(1/4)"
						},
						{
							"t": "fill",
							"q": "3k + 1/2 落在 2 和 4 之間，k 只能是 1：",
							"template": "答：a = [0]，b = −3",
							"ans": [
								"7/2"
							],
							"hint": "3 · 1 + 1/2"
						}
					]
				}
			]
		},
		{
			"id": "tg_overlap",
			"kind": "graph",
			"tier": 2,
			"title": "移到重合",
			"tmul": 1.2,
			"stem": "y = sin(3x + π/4) 的圖形向右平移 h（h > 0）後，和 y = cos 3x 的圖形重合。求 h 的最小值。",
			"plot": {
				"x": [
					-0.3,
					3.4
				],
				"y": [
					-1.5,
					1.5
				],
				"pi": 12,
				"pi_lab": 4,
				"curves": [
					{
						"f": "cos(3.0*x)",
						"c": "dim",
						"dash": true
					},
					{
						"f": "sin(3.0*x+0.25*3.141592653589793)",
						"c": "cyan",
						"until": 4
					},
					{
						"f": "sin(3.0*(x-0.5833333333333334*3.141592653589793)+0.25*3.141592653589793)",
						"c": "pink",
						"at": 4
					}
				]
			},
			"steps": [
				{
					"t": "choice",
					"q": "cos 3x 先寫成 sin：",
					"opts": [
						"sin(3x + π/2)",
						"sin(3x − π/2)",
						"sin(3x + π)",
						"−sin 3x"
					],
					"hint": "cos θ = sin(θ + π/2)",
					"write": "cos 3x = sin(3x + π/2)"
				},
				{
					"t": "fill",
					"q": "兩邊括號裡的角差 2π 的整數倍（k 是整數）：",
					"template": "3x − 3h + π/4 = 3x + π/2 + 2kπ ⇒ −3h = [0]π + 2kπ",
					"ans": [
						"1/4"
					],
					"hint": "π/2 − π/4",
					"pre": "右移 h：sin(3(x − h) + π/4) = sin(3x + π/2)"
				},
				{
					"t": "fill",
					"q": "兩邊除以 −3：",
					"template": "h = −π/12 − [0]kπ",
					"ans": [
						"2/3"
					],
					"hint": "2kπ/3"
				},
				{
					"t": "fill",
					"q": "k 取 −1，h 是最小的正數：",
					"template": "答：h = −π/12 + 2π/3 = [0]π",
					"ans": [
						"7/12"
					],
					"hint": "−1/12 + 2/3"
				}
			],
			"vars": [
				{
					"stem": "y = sin(3x + π/3) 的圖形向右平移 h（h > 0）後，和 y = cos 3x 的圖形重合。求 h 的最小值。",
					"plot": {
						"x": [
							-0.3,
							3.4
						],
						"y": [
							-1.5,
							1.5
						],
						"pi": 18,
						"pi_lab": 6,
						"curves": [
							{
								"f": "cos(3.0*x)",
								"c": "dim",
								"dash": true
							},
							{
								"f": "sin(3.0*x+0.3333333333333333*3.141592653589793)",
								"c": "cyan",
								"until": 4
							},
							{
								"f": "sin(3.0*(x-0.6111111111111112*3.141592653589793)+0.3333333333333333*3.141592653589793)",
								"c": "pink",
								"at": 4
							}
						]
					},
					"steps": [
						{
							"t": "choice",
							"q": "cos 3x 先寫成 sin：",
							"opts": [
								"sin(3x + π/2)",
								"sin(3x − π/2)",
								"sin(3x + π)",
								"−sin 3x"
							],
							"hint": "cos θ = sin(θ + π/2)",
							"write": "cos 3x = sin(3x + π/2)"
						},
						{
							"t": "fill",
							"q": "兩邊括號裡的角差 2π 的整數倍（k 是整數）：",
							"template": "3x − 3h + π/3 = 3x + π/2 + 2kπ ⇒ −3h = [0]π + 2kπ",
							"ans": [
								"1/6"
							],
							"hint": "π/2 − π/3",
							"pre": "右移 h：sin(3(x − h) + π/3) = sin(3x + π/2)"
						},
						{
							"t": "fill",
							"q": "兩邊除以 −3：",
							"template": "h = −π/18 − [0]kπ",
							"ans": [
								"2/3"
							],
							"hint": "2kπ/3"
						},
						{
							"t": "fill",
							"q": "k 取 −1，h 是最小的正數：",
							"template": "答：h = −π/18 + 2π/3 = [0]π",
							"ans": [
								"11/18"
							],
							"hint": "−1/18 + 2/3"
						}
					]
				},
				{
					"stem": "y = sin(4x + π/6) 的圖形向右平移 h（h > 0）後，和 y = cos 4x 的圖形重合。求 h 的最小值。",
					"plot": {
						"x": [
							-0.3,
							2.6
						],
						"y": [
							-1.5,
							1.5
						],
						"pi": 12,
						"pi_lab": 4,
						"curves": [
							{
								"f": "cos(4.0*x)",
								"c": "dim",
								"dash": true
							},
							{
								"f": "sin(4.0*x+0.16666666666666666*3.141592653589793)",
								"c": "cyan",
								"until": 4
							},
							{
								"f": "sin(4.0*(x-0.4166666666666667*3.141592653589793)+0.16666666666666666*3.141592653589793)",
								"c": "pink",
								"at": 4
							}
						]
					},
					"steps": [
						{
							"t": "choice",
							"q": "cos 4x 先寫成 sin：",
							"opts": [
								"sin(4x + π/2)",
								"sin(4x − π/2)",
								"sin(4x + π)",
								"−sin 4x"
							],
							"hint": "cos θ = sin(θ + π/2)",
							"write": "cos 4x = sin(4x + π/2)"
						},
						{
							"t": "fill",
							"q": "兩邊括號裡的角差 2π 的整數倍（k 是整數）：",
							"template": "4x − 4h + π/6 = 4x + π/2 + 2kπ ⇒ −4h = [0]π + 2kπ",
							"ans": [
								"1/3"
							],
							"hint": "π/2 − π/6",
							"pre": "右移 h：sin(4(x − h) + π/6) = sin(4x + π/2)"
						},
						{
							"t": "fill",
							"q": "兩邊除以 −4：",
							"template": "h = −π/12 − [0]kπ",
							"ans": [
								"1/2"
							],
							"hint": "2kπ/4"
						},
						{
							"t": "fill",
							"q": "k 取 −1，h 是最小的正數：",
							"template": "答：h = −π/12 + π/2 = [0]π",
							"ans": [
								"5/12"
							],
							"hint": "−1/12 + 1/2"
						}
					]
				}
			]
		},
		{
			"id": "tc_count",
			"kind": "cross",
			"tier": 1,
			"title": "直線穿過波",
			"tmul": 1.05,
			"stem": "方程式 sin(πx) = x/3 有幾個實根？",
			"plot": {
				"x": [
					-3.6,
					3.6
				],
				"y": [
					-1.5,
					1.5
				],
				"curves": [
					{
						"f": "sin(3.141592653589793*x)",
						"c": "cyan",
						"at": 1
					},
					{
						"f": "x/3",
						"c": "pink",
						"at": 1
					}
				]
			},
			"steps": [
				{
					"t": "choice",
					"q": "交點的 x 一定在哪個範圍？",
					"opts": [
						"−3 ≤ x ≤ 3",
						"−1 ≤ x ≤ 1",
						"0 ≤ x ≤ 3",
						"全體實數"
					],
					"hint": "|sin(πx)| ≤ 1，所以 |x/3| ≤ 1",
					"write": "|x/3| ≤ 1 ⇒ −3 ≤ x ≤ 3"
				},
				{
					"t": "fill",
					"q": "看圖數 x > 0 的交點：sin(πx) 的波峰在 0 到 1、2 到 3。",
					"template": "0 < x < 1：[0] 個，2 < x < 3：[1] 個",
					"ans": [
						"1",
						"2"
					],
					"hint": "第一個波峰從原點出發，只再交一次；後面的波峰比直線高，各被切過兩次；波谷在直線下面"
				},
				{
					"t": "fill",
					"q": "兩邊都是奇函數，左邊和右邊一樣多，再加上原點：",
					"template": "答：共 3 + 3 + 1 = [0] 個實根",
					"ans": [
						"7"
					],
					"hint": "3 + 3 + 1"
				}
			],
			"vars": [
				{
					"stem": "方程式 sin(πx) = x/5 有幾個實根？",
					"plot": {
						"x": [
							-5.6,
							5.6
						],
						"y": [
							-1.5,
							1.5
						],
						"curves": [
							{
								"f": "sin(3.141592653589793*x)",
								"c": "cyan",
								"at": 1
							},
							{
								"f": "x/5",
								"c": "pink",
								"at": 1
							}
						]
					},
					"steps": [
						{
							"t": "choice",
							"q": "交點的 x 一定在哪個範圍？",
							"opts": [
								"−5 ≤ x ≤ 5",
								"−1 ≤ x ≤ 1",
								"0 ≤ x ≤ 5",
								"全體實數"
							],
							"hint": "|sin(πx)| ≤ 1，所以 |x/5| ≤ 1",
							"write": "|x/5| ≤ 1 ⇒ −5 ≤ x ≤ 5"
						},
						{
							"t": "fill",
							"q": "看圖數 x > 0 的交點：sin(πx) 的波峰在 0 到 1、2 到 3、4 到 5。",
							"template": "0 < x < 1：[0] 個，2 < x < 3：[1] 個，4 < x < 5：[2] 個",
							"ans": [
								"1",
								"2",
								"2"
							],
							"hint": "第一個波峰從原點出發，只再交一次；後面的波峰比直線高，各被切過兩次；波谷在直線下面"
						},
						{
							"t": "fill",
							"q": "兩邊都是奇函數，左邊和右邊一樣多，再加上原點：",
							"template": "答：共 5 + 5 + 1 = [0] 個實根",
							"ans": [
								"11"
							],
							"hint": "5 + 5 + 1"
						}
					]
				},
				{
					"stem": "方程式 sin(πx) = x/7 有幾個實根？",
					"plot": {
						"x": [
							-7.6,
							7.6
						],
						"y": [
							-1.5,
							1.5
						],
						"curves": [
							{
								"f": "sin(3.141592653589793*x)",
								"c": "cyan",
								"at": 1
							},
							{
								"f": "x/7",
								"c": "pink",
								"at": 1
							}
						]
					},
					"steps": [
						{
							"t": "choice",
							"q": "交點的 x 一定在哪個範圍？",
							"opts": [
								"−7 ≤ x ≤ 7",
								"−1 ≤ x ≤ 1",
								"0 ≤ x ≤ 7",
								"全體實數"
							],
							"hint": "|sin(πx)| ≤ 1，所以 |x/7| ≤ 1",
							"write": "|x/7| ≤ 1 ⇒ −7 ≤ x ≤ 7"
						},
						{
							"t": "fill",
							"q": "看圖數 x > 0 的交點：sin(πx) 的波峰在 0 到 1、2 到 3、4 到 5、6 到 7。",
							"template": "0 < x < 1：[0] 個，2 < x < 3：[1] 個，4 < x < 5：[2] 個，6 < x < 7：[3] 個",
							"ans": [
								"1",
								"2",
								"2",
								"2"
							],
							"hint": "第一個波峰從原點出發，只再交一次；後面的波峰比直線高，各被切過兩次；波谷在直線下面"
						},
						{
							"t": "fill",
							"q": "兩邊都是奇函數，左邊和右邊一樣多，再加上原點：",
							"template": "答：共 7 + 7 + 1 = [0] 個實根",
							"ans": [
								"15"
							],
							"hint": "7 + 7 + 1"
						}
					]
				}
			]
		},
		{
			"id": "tc_sum",
			"kind": "cross",
			"tier": 1,
			"title": "解的總和",
			"tmul": 1.05,
			"stem": "求方程式 cos x = −1/5 在 −2π ≤ x ≤ 4π 的所有解的和。",
			"plot": {
				"x": [
					-6.5832,
					12.8664
				],
				"y": [
					-1.4,
					1.4
				],
				"pi": 1,
				"pi_up": true,
				"curves": [
					{
						"f": "cos(x)",
						"c": "cyan"
					},
					{
						"f": "-0.2",
						"c": "pink",
						"dash": true
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "先看 0 ≤ x ≤ 2π 這一段：",
					"template": "有 [0] 個解，兩個解對稱於 x = [1]π",
					"ans": [
						"2",
						"1"
					],
					"hint": "cos 的圖形在一個週期內對稱於最低點 x = π"
				},
				{
					"t": "fill",
					"q": "另外兩段也一樣，各兩個解，對稱於那一段的最低點：",
					"template": "−2π 到 0 對稱於 x = [0]π，2π 到 4π 對稱於 x = [1]π",
					"ans": [
						"−1",
						"3"
					],
					"hint": "每一段的中點"
				},
				{
					"t": "fill",
					"q": "對稱的兩個解，和是對稱軸的 2 倍：",
					"template": "答：和 = 2(−π) + 2π + 2(3π) = [0]π",
					"ans": [
						"6"
					],
					"hint": "−2 + 2 + 6"
				}
			],
			"vars": [
				{
					"stem": "求方程式 sin x = 1/3 在 0 ≤ x ≤ 6π 的所有解的和。",
					"plot": {
						"x": [
							-0.3,
							19.1496
						],
						"y": [
							-1.4,
							1.4
						],
						"pi": 1,
						"pi_up": false,
						"curves": [
							{
								"f": "sin(x)",
								"c": "cyan"
							},
							{
								"f": "0.3333333333333333",
								"c": "pink",
								"dash": true
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "先看 0 ≤ x ≤ 2π 這一段：",
							"template": "有 [0] 個解，兩個解對稱於 x = [1]π",
							"ans": [
								"2",
								"1/2"
							],
							"hint": "sin x = 1/3 的兩個解都在 x 軸上方的那一段，對稱於最高點"
						},
						{
							"t": "fill",
							"q": "另外兩段也一樣，各兩個解，對稱於那一段的最高點：",
							"template": "2π 到 4π 對稱於 x = [0]π，4π 到 6π 對稱於 x = [1]π",
							"ans": [
								"5/2",
								"9/2"
							],
							"hint": "每一段的 π/2 再加上起點"
						},
						{
							"t": "fill",
							"q": "對稱的兩個解，和是對稱軸的 2 倍：",
							"template": "答：和 = 2(π/2) + 2(5π/2) + 2(9π/2) = [0]π",
							"ans": [
								"15"
							],
							"hint": "1 + 5 + 9"
						}
					]
				},
				{
					"stem": "求方程式 cos x = 2/3 在 −4π ≤ x ≤ 2π 的所有解的和。",
					"plot": {
						"x": [
							-12.8664,
							6.5832
						],
						"y": [
							-1.4,
							1.4
						],
						"pi": 1,
						"pi_up": false,
						"curves": [
							{
								"f": "cos(x)",
								"c": "cyan"
							},
							{
								"f": "0.6666666666666666",
								"c": "pink",
								"dash": true
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "先看 0 ≤ x ≤ 2π 這一段：",
							"template": "有 [0] 個解，兩個解對稱於 x = [1]π",
							"ans": [
								"2",
								"1"
							],
							"hint": "cos 的圖形在 0 到 2π 對稱於最低點 x = π"
						},
						{
							"t": "fill",
							"q": "另外兩段也一樣，各兩個解，對稱於那一段的最低點：",
							"template": "−4π 到 −2π 對稱於 x = [0]π，−2π 到 0 對稱於 x = [1]π",
							"ans": [
								"−3",
								"−1"
							],
							"hint": "每一段的中點"
						},
						{
							"t": "fill",
							"q": "對稱的兩個解，和是對稱軸的 2 倍：",
							"template": "答：和 = 2(−3π) + 2(−π) + 2π = [0]π",
							"ans": [
								"−6"
							],
							"hint": "−6 − 2 + 2"
						}
					]
				}
			]
		},
		{
			"id": "tc_center",
			"kind": "cross",
			"tier": 2,
			"title": "對稱中心配對",
			"tmul": 1.15,
			"stem": "方程式 sin 2x = (x − π)/2 的所有實數解的和是多少？",
			"plot": {
				"x": [
					0.7416,
					5.5416
				],
				"y": [
					-1.4,
					1.4
				],
				"pi": 4,
				"curves": [
					{
						"f": "sin(2*x)",
						"c": "cyan"
					},
					{
						"f": "(x-1.0*3.141592653589793)/2",
						"c": "pink"
					}
				],
				"pts": [
					{
						"x": 3.1416,
						"y": 0,
						"label": "(π, 0)",
						"off": [
							6,
							20
						]
					}
				]
			},
			"steps": [
				{
					"t": "choice",
					"q": "令 u = x − π，方程式變成？",
					"opts": [
						"sin 2u = u/2",
						"−sin 2u = u/2",
						"sin 2u = (u − π)/2",
						"cos 2u = u/2"
					],
					"hint": "sin(2u + 2π) = sin 2u",
					"write": "u = x − π：sin 2u = u/2（兩邊都是 u 的奇函數）"
				},
				{
					"t": "fill",
					"q": "看圖數交點（u 的解正負成對，加上 u = 0）：",
					"template": "共 [0] 個解",
					"ans": [
						"3"
					],
					"hint": "|u/2| ≤ 1 ⇒ |u| ≤ 2，在這個範圍裡數"
				},
				{
					"t": "fill",
					"q": "u 的解加起來是 0，換回 x = u + π：",
					"template": "答：所有解的和 = [0]π",
					"ans": [
						"3"
					],
					"hint": "每個解都加 π"
				}
			],
			"vars": [
				{
					"stem": "方程式 sin 2x = (x − π/2)/3 的所有實數解的和是多少？",
					"plot": {
						"x": [
							-1.8292,
							4.9708
						],
						"y": [
							-1.4,
							1.4
						],
						"pi": 4,
						"curves": [
							{
								"f": "sin(2*x)",
								"c": "cyan"
							},
							{
								"f": "(x-0.5*3.141592653589793)/3",
								"c": "pink"
							}
						],
						"pts": [
							{
								"x": 1.5708,
								"y": 0,
								"label": "(π/2, 0)",
								"off": [
									6,
									20
								]
							}
						]
					},
					"steps": [
						{
							"t": "choice",
							"q": "令 u = x − π/2，方程式變成？",
							"opts": [
								"−sin 2u = u/3",
								"sin 2u = u/3",
								"sin 2u = (u − π/2)/3",
								"cos 2u = u/3"
							],
							"hint": "sin(2u + π) = −sin 2u",
							"write": "u = x − π/2：−sin 2u = u/3（兩邊都是 u 的奇函數）"
						},
						{
							"t": "fill",
							"q": "看圖數交點（u 的解正負成對，加上 u = 0）：",
							"template": "共 [0] 個解",
							"ans": [
								"5"
							],
							"hint": "|u/3| ≤ 1 ⇒ |u| ≤ 3，在這個範圍裡數"
						},
						{
							"t": "fill",
							"q": "u 的解加起來是 0，換回 x = u + π/2：",
							"template": "答：所有解的和 = [0]π",
							"ans": [
								"5/2"
							],
							"hint": "每個解都加 π/2"
						}
					]
				},
				{
					"stem": "方程式 sin 3x = (x − π)/2 的所有實數解的和是多少？",
					"plot": {
						"x": [
							0.7416,
							5.5416
						],
						"y": [
							-1.4,
							1.4
						],
						"pi": 4,
						"curves": [
							{
								"f": "sin(3*x)",
								"c": "cyan"
							},
							{
								"f": "(x-1.0*3.141592653589793)/2",
								"c": "pink"
							}
						],
						"pts": [
							{
								"x": 3.1416,
								"y": 0,
								"label": "(π, 0)",
								"off": [
									6,
									20
								]
							}
						]
					},
					"steps": [
						{
							"t": "choice",
							"q": "令 u = x − π，方程式變成？",
							"opts": [
								"−sin 3u = u/2",
								"sin 3u = u/2",
								"sin 3u = (u − π)/2",
								"cos 3u = u/2"
							],
							"hint": "sin(3u + 3π) = −sin 3u",
							"write": "u = x − π：−sin 3u = u/2（兩邊都是 u 的奇函數）"
						},
						{
							"t": "fill",
							"q": "看圖數交點（u 的解正負成對，加上 u = 0）：",
							"template": "共 [0] 個解",
							"ans": [
								"5"
							],
							"hint": "|u/2| ≤ 1 ⇒ |u| ≤ 2，在這個範圍裡數"
						},
						{
							"t": "fill",
							"q": "u 的解加起來是 0，換回 x = u + π：",
							"template": "答：所有解的和 = [0]π",
							"ans": [
								"5"
							],
							"hint": "每個解都加 π"
						}
					]
				}
			]
		},
		{
			"id": "tc_tan",
			"kind": "cross",
			"tier": 2,
			"title": "tan 和直線",
			"tmul": 1.25,
			"stem": "方程式 tan x = 1 − x 在 −π < x < 2π 有幾個實根？",
			"plot": {
				"x": [
					-3.3,
					6.45
				],
				"y": [
					-6.0,
					6.0
				],
				"pi": 2,
				"curves": [
					{
						"f": "tan(x)",
						"c": "cyan"
					},
					{
						"f": "-1.0*x+1.0",
						"c": "pink"
					}
				],
				"vlines": [
					{
						"x": -1.5708
					},
					{
						"x": 1.5708
					},
					{
						"x": 4.7124
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "漸近線 x = −π/2、π/2、3π/2 把 tan 的圖形切成幾段？",
					"template": "[0] 段",
					"ans": [
						"4"
					],
					"hint": "三條線切成四段"
				},
				{
					"t": "fill",
					"q": "中間兩段是完整的一支：tan 從 −∞ 升到 ∞，直線一定穿過。",
					"template": "中間兩段：各 [0] 個",
					"ans": [
						"1"
					],
					"hint": "tan 一直往上，直線往下"
				},
				{
					"t": "fill",
					"q": "最左段（−π 到 −π/2）：tan 從 0 升到 ∞，直線的高度在 2.6 到 4.1 之間。",
					"template": "最左段：[0] 個",
					"ans": [
						"1"
					],
					"hint": "tan 從比直線低，升到比直線高"
				},
				{
					"t": "fill",
					"q": "最右段（3π/2 到 2π）：tan 從 −∞ 升到 0，直線的高度大約是 −3.7 到 −5.3。",
					"template": "最右段：[0] 個 ⇒ 答：共 [1] 個",
					"ans": [
						"1",
						"4"
					],
					"hint": "tan 從比直線低，升到 0（比直線高）"
				}
			],
			"vars": [
				{
					"stem": "方程式 tan x = 7 − x 在 −π < x < 2π 有幾個實根？",
					"plot": {
						"x": [
							-3.3,
							6.45
						],
						"y": [
							-6.0,
							6.0
						],
						"pi": 2,
						"curves": [
							{
								"f": "tan(x)",
								"c": "cyan"
							},
							{
								"f": "-1.0*x+7.0",
								"c": "pink"
							}
						],
						"vlines": [
							{
								"x": -1.5708
							},
							{
								"x": 1.5708
							},
							{
								"x": 4.7124
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "漸近線 x = −π/2、π/2、3π/2 把 tan 的圖形切成幾段？",
							"template": "[0] 段",
							"ans": [
								"4"
							],
							"hint": "三條線切成四段"
						},
						{
							"t": "fill",
							"q": "中間兩段是完整的一支：tan 從 −∞ 升到 ∞，直線一定穿過。",
							"template": "中間兩段：各 [0] 個",
							"ans": [
								"1"
							],
							"hint": "tan 一直往上，直線往下"
						},
						{
							"t": "fill",
							"q": "最左段（−π 到 −π/2）：tan 從 0 升到 ∞，直線的高度在 8.6 到 10.1 之間。",
							"template": "最左段：[0] 個",
							"ans": [
								"1"
							],
							"hint": "tan 從比直線低，升到比直線高"
						},
						{
							"t": "fill",
							"q": "最右段（3π/2 到 2π）：tan 從 −∞ 升到 0，直線的高度大約是 2.3 到 0.7。",
							"template": "最右段：[0] 個 ⇒ 答：共 [1] 個",
							"ans": [
								"0",
								"3"
							],
							"hint": "直線一直在 x 軸上方，tan 升到 0 都還比直線低"
						}
					]
				},
				{
					"stem": "方程式 tan x = −x/2 − 2 在 −π < x < 2π 有幾個實根？",
					"plot": {
						"x": [
							-3.3,
							6.45
						],
						"y": [
							-6.0,
							6.0
						],
						"pi": 2,
						"curves": [
							{
								"f": "tan(x)",
								"c": "cyan"
							},
							{
								"f": "-0.5*x-2.0",
								"c": "pink"
							}
						],
						"vlines": [
							{
								"x": -1.5708
							},
							{
								"x": 1.5708
							},
							{
								"x": 4.7124
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "漸近線 x = −π/2、π/2、3π/2 把 tan 的圖形切成幾段？",
							"template": "[0] 段",
							"ans": [
								"4"
							],
							"hint": "三條線切成四段"
						},
						{
							"t": "fill",
							"q": "中間兩段是完整的一支：tan 從 −∞ 升到 ∞，直線一定穿過。",
							"template": "中間兩段：各 [0] 個",
							"ans": [
								"1"
							],
							"hint": "tan 一直往上，直線往下"
						},
						{
							"t": "fill",
							"q": "最左段（−π 到 −π/2）：tan 從 0 升到 ∞，直線的高度在 −1.2 到 −0.4 之間。",
							"template": "最左段：[0] 個",
							"ans": [
								"0"
							],
							"hint": "tan 一開始就比直線高，之後 tan 往上、直線往下，碰不到"
						},
						{
							"t": "fill",
							"q": "最右段（3π/2 到 2π）：tan 從 −∞ 升到 0，直線的高度大約是 −4.4 到 −5.1。",
							"template": "最右段：[0] 個 ⇒ 答：共 [1] 個",
							"ans": [
								"1",
								"3"
							],
							"hint": "tan 從比直線低，升到 0（比直線高）"
						}
					]
				}
			]
		},
		{
			"id": "tc_abs",
			"kind": "cross",
			"tier": 3,
			"title": "絕對值的波",
			"tmul": 1.35,
			"stem": "方程式 4π sin|x| + x = 0 有幾個實數解？",
			"plot": {
				"x": [
					-12.9664,
					12.9664
				],
				"y": [
					-1.5,
					1.5
				],
				"pi": 1,
				"curves": [
					{
						"f": "sin(abs(x))",
						"c": "cyan"
					},
					{
						"f": "-x/(4*3.141592653589793)",
						"c": "pink"
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "|sin| ≤ 1，交點只會在這個範圍：",
					"template": "|x/(4π)| ≤ 1 ⇒ −[0]π ≤ x ≤ [1]π",
					"ans": [
						"4",
						"4"
					],
					"hint": "|x| ≤ 4π",
					"pre": "4π sin|x| + x = 0 ⇒ sin|x| = −x/(4π)"
				},
				{
					"t": "fill",
					"q": "右半邊 x ≥ 0：直線往下，原點是一個解，其他只會碰到 x 軸下方的波谷。",
					"template": "x ≥ 0：原點 1 個，π 到 2π：[0] 個，3π 到 4π：[1] 個",
					"ans": [
						"2",
						"2"
					],
					"hint": "看圖右半邊：波谷都比直線低，各被切過兩次"
				},
				{
					"t": "fill",
					"q": "左半邊 x < 0：sin|x| 左右對稱，直線在這邊往上，只會碰到 x 軸上方的波峰。",
					"template": "−π 到 0：[0] 個，−3π 到 −2π：[1] 個",
					"ans": [
						"1",
						"2"
					],
					"hint": "−π 到 0 的波峰從原點出發，只再交一次；其他波峰比直線高，各被切過兩次"
				},
				{
					"t": "fill",
					"q": "全部加起來：",
					"template": "答：共 [0] 個",
					"ans": [
						"8"
					],
					"hint": "右邊 5 個、左邊 3 個"
				}
			],
			"vars": [
				{
					"stem": "方程式 2π sin|x| + x = 0 有幾個實數解？",
					"plot": {
						"x": [
							-6.6832,
							6.6832
						],
						"y": [
							-1.5,
							1.5
						],
						"pi": 1,
						"curves": [
							{
								"f": "sin(abs(x))",
								"c": "cyan"
							},
							{
								"f": "-x/(2*3.141592653589793)",
								"c": "pink"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "|sin| ≤ 1，交點只會在這個範圍：",
							"template": "|x/(2π)| ≤ 1 ⇒ −[0]π ≤ x ≤ [1]π",
							"ans": [
								"2",
								"2"
							],
							"hint": "|x| ≤ 2π",
							"pre": "2π sin|x| + x = 0 ⇒ sin|x| = −x/(2π)"
						},
						{
							"t": "fill",
							"q": "右半邊 x ≥ 0：直線往下，原點是一個解，其他只會碰到 x 軸下方的波谷。",
							"template": "x ≥ 0：原點 1 個，π 到 2π：[0] 個",
							"ans": [
								"2"
							],
							"hint": "看圖右半邊：波谷都比直線低，各被切過兩次"
						},
						{
							"t": "fill",
							"q": "左半邊 x < 0：sin|x| 左右對稱，直線在這邊往上，只會碰到 x 軸上方的波峰。",
							"template": "−π 到 0：[0] 個",
							"ans": [
								"1"
							],
							"hint": "−π 到 0 的波峰從原點出發，只再交一次"
						},
						{
							"t": "fill",
							"q": "全部加起來：",
							"template": "答：共 [0] 個",
							"ans": [
								"4"
							],
							"hint": "右邊 3 個、左邊 1 個"
						}
					]
				},
				{
					"stem": "方程式 3π sin|x| + x = 0 有幾個實數解？",
					"plot": {
						"x": [
							-9.8248,
							9.8248
						],
						"y": [
							-1.5,
							1.5
						],
						"pi": 1,
						"curves": [
							{
								"f": "sin(abs(x))",
								"c": "cyan"
							},
							{
								"f": "-x/(3*3.141592653589793)",
								"c": "pink"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "|sin| ≤ 1，交點只會在這個範圍：",
							"template": "|x/(3π)| ≤ 1 ⇒ −[0]π ≤ x ≤ [1]π",
							"ans": [
								"3",
								"3"
							],
							"hint": "|x| ≤ 3π",
							"pre": "3π sin|x| + x = 0 ⇒ sin|x| = −x/(3π)"
						},
						{
							"t": "fill",
							"q": "右半邊 x ≥ 0：直線往下，原點是一個解，其他只會碰到 x 軸下方的波谷。",
							"template": "x ≥ 0：原點 1 個，π 到 2π：[0] 個",
							"ans": [
								"2"
							],
							"hint": "看圖右半邊：波谷都比直線低，各被切過兩次"
						},
						{
							"t": "fill",
							"q": "左半邊 x < 0：sin|x| 左右對稱，直線在這邊往上，只會碰到 x 軸上方的波峰。",
							"template": "−π 到 0：[0] 個，−3π 到 −2π：[1] 個",
							"ans": [
								"1",
								"2"
							],
							"hint": "−π 到 0 的波峰從原點出發，只再交一次；其他波峰比直線高，各被切過兩次"
						},
						{
							"t": "fill",
							"q": "全部加起來：",
							"template": "答：共 [0] 個",
							"ans": [
								"6"
							],
							"hint": "右邊 3 個、左邊 3 個"
						}
					]
				}
			]
		},
		{
			"id": "tc_double",
			"kind": "cross",
			"tier": 2,
			"title": "倍角方程式",
			"tmul": 1.15,
			"stem": "求方程式 sin 2x = √{2} sin x 在 0 ≤ x ≤ 2π 的所有解的和。",
			"steps": [
				{
					"t": "choice",
					"q": "sin 2x 展開，再提出公因式：",
					"opts": [
						"sin x(2 cos x − √{2}) = 0",
						"sin x(2 cos x + √{2}) = 0",
						"cos x(2 sin x − √{2}) = 0",
						"2 sin x(cos x − √{2}) = 0"
					],
					"hint": "sin 2x = 2 sin x cos x",
					"write": "2 sin x cos x − √{2} sin x = 0 ⇒ sin x(2 cos x − √{2}) = 0"
				},
				{
					"t": "fill",
					"q": "cos x = √{2}/2 的解（由小到大）：",
					"template": "cos x = √{2}/2 ⇒ x = [0]π、[1]π",
					"ans": [
						"1/4",
						"7/4"
					],
					"hint": "cos(π/4) = √{2}/2",
					"pre": "sin x = 0 ⇒ x = 0、π、2π"
				},
				{
					"t": "fill",
					"q": "5 個解加起來：",
					"template": "答：和 = [0]π",
					"ans": [
						"5"
					],
					"hint": "0 + π + 2π + π/4 + 7π/4"
				}
			],
			"vars": [
				{
					"stem": "求方程式 sin 2x = sin x 在 0 ≤ x ≤ π 的所有解的和。",
					"steps": [
						{
							"t": "choice",
							"q": "sin 2x 展開，再提出公因式：",
							"opts": [
								"sin x(2 cos x − 1) = 0",
								"sin x(2 cos x + 1) = 0",
								"cos x(2 sin x − 1) = 0",
								"2 sin x(cos x − 1) = 0"
							],
							"hint": "sin 2x = 2 sin x cos x",
							"write": "2 sin x cos x − sin x = 0 ⇒ sin x(2 cos x − 1) = 0"
						},
						{
							"t": "fill",
							"q": "cos x = 1/2 的解（由小到大）：",
							"template": "cos x = 1/2 ⇒ x = [0]π",
							"ans": [
								"1/3"
							],
							"hint": "cos(π/3) = 1/2",
							"pre": "sin x = 0 ⇒ x = 0、π"
						},
						{
							"t": "fill",
							"q": "3 個解加起來：",
							"template": "答：和 = [0]π",
							"ans": [
								"4/3"
							],
							"hint": "0 + π + π/3"
						}
					]
				},
				{
					"stem": "求方程式 sin 2x = −sin x 在 0 ≤ x ≤ π 的所有解的和。",
					"steps": [
						{
							"t": "choice",
							"q": "sin 2x 展開，再提出公因式：",
							"opts": [
								"sin x(2 cos x + 1) = 0",
								"sin x(2 cos x − 1) = 0",
								"cos x(2 sin x + 1) = 0",
								"2 sin x(cos x + 1) = 0"
							],
							"hint": "sin 2x = 2 sin x cos x",
							"write": "2 sin x cos x + sin x = 0 ⇒ sin x(2 cos x + 1) = 0"
						},
						{
							"t": "fill",
							"q": "cos x = −1/2 的解（由小到大）：",
							"template": "cos x = −1/2 ⇒ x = [0]π",
							"ans": [
								"2/3"
							],
							"hint": "cos(2π/3) = −1/2",
							"pre": "sin x = 0 ⇒ x = 0、π"
						},
						{
							"t": "fill",
							"q": "3 個解加起來：",
							"template": "答：和 = [0]π",
							"ans": [
								"5/3"
							],
							"hint": "0 + π + 2π/3"
						}
					]
				}
			]
		},
		{
			"id": "tc_ineq",
			"kind": "cross",
			"tier": 1,
			"title": "疊合不等式",
			"tmul": 1.0,
			"stem": "在 0 ≤ x < 2π，解不等式 sin x − √{3} cos x ≥ 1。",
			"plot": {
				"x": [
					-0.3,
					6.6
				],
				"y": [
					-2.5,
					2.5
				],
				"pi": 12,
				"pi_lab": 2,
				"curves": [
					{
						"f": "1.0*sin(x)-1.7320508075688772*cos(x)",
						"c": "cyan",
						"at": 1
					},
					{
						"f": "1.0",
						"c": "pink",
						"dash": true,
						"at": 1
					}
				],
				"band": {
					"lo": 1.5708,
					"hi": 3.6652,
					"at": 2
				}
			},
			"steps": [
				{
					"t": "fill",
					"q": "先疊合：",
					"template": "sin x − √{3} cos x = [0] sin(x − [1]π)",
					"ans": [
						"2",
						"1/3"
					],
					"hint": "√{1 + 3} = 2，cos(π/3) = 1/2、sin(π/3) = √{3}/2"
				},
				{
					"t": "fill",
					"q": "sin(x − π/3) ≥ 1/2，而 x − π/3 在 −π/3 到 5π/3 之間：",
					"template": "[0]π ≤ x − π/3 ≤ [1]π",
					"ans": [
						"1/6",
						"5/6"
					],
					"hint": "sin u ≥ 1/2 在 π/6 ≤ u ≤ 5π/6"
				},
				{
					"t": "line",
					"q": "封印 x 的範圍（兩端都可以等於）。",
					"row": "解",
					"marks": [
						"π/2",
						"7π/6"
					],
					"seg": [
						0,
						1,
						0
					],
					"pt": [
						1,
						1
					],
					"write": "答：π/2 ≤ x ≤ 7π/6"
				}
			],
			"vars": [
				{
					"stem": "在 0 ≤ x < 2π，解不等式 √{3} sin x + cos x > 1。",
					"plot": {
						"x": [
							-0.3,
							6.6
						],
						"y": [
							-2.5,
							2.5
						],
						"pi": 12,
						"pi_lab": 2,
						"curves": [
							{
								"f": "1.7320508075688772*sin(x)+1.0*cos(x)",
								"c": "cyan",
								"at": 1
							},
							{
								"f": "1.0",
								"c": "pink",
								"dash": true,
								"at": 1
							}
						],
						"band": {
							"lo": 0,
							"hi": 2.0944,
							"at": 2
						}
					},
					"steps": [
						{
							"t": "fill",
							"q": "先疊合：",
							"template": "√{3} sin x + cos x = [0] sin(x + [1]π)",
							"ans": [
								"2",
								"1/6"
							],
							"hint": "√{3 + 1} = 2，cos(π/6) = √{3}/2、sin(π/6) = 1/2"
						},
						{
							"t": "fill",
							"q": "sin(x + π/6) > 1/2，而 x + π/6 在 π/6 到 13π/6 之間：",
							"template": "[0]π < x + π/6 < [1]π",
							"ans": [
								"1/6",
								"5/6"
							],
							"hint": "sin u > 1/2 在 π/6 < u < 5π/6"
						},
						{
							"t": "line",
							"q": "封印 x 的範圍（兩端都不能等於）。",
							"row": "解",
							"marks": [
								"0",
								"2π/3"
							],
							"seg": [
								0,
								1,
								0
							],
							"pt": [
								0,
								0
							],
							"write": "答：0 < x < 2π/3"
						}
					]
				},
				{
					"stem": "在 0 ≤ x < 2π，解不等式 sin x + cos x ≥ 1。",
					"plot": {
						"x": [
							-0.3,
							6.6
						],
						"y": [
							-1.9142135623730951,
							1.9142135623730951
						],
						"pi": 12,
						"pi_lab": 2,
						"curves": [
							{
								"f": "1.0*sin(x)+1.0*cos(x)",
								"c": "cyan",
								"at": 1
							},
							{
								"f": "1.0",
								"c": "pink",
								"dash": true,
								"at": 1
							}
						],
						"band": {
							"lo": 0,
							"hi": 1.5708,
							"at": 2
						}
					},
					"steps": [
						{
							"t": "fill",
							"q": "先疊合：",
							"template": "sin x + cos x = [0] sin(x + [1]π)",
							"ans": [
								"√2",
								"1/4"
							],
							"hint": "√{1 + 1} = √{2}，cos(π/4) = √{2}/2、sin(π/4) = √{2}/2"
						},
						{
							"t": "fill",
							"q": "sin(x + π/4) ≥ √{2}/2，而 x + π/4 在 π/4 到 9π/4 之間：",
							"template": "[0]π ≤ x + π/4 ≤ [1]π",
							"ans": [
								"1/4",
								"3/4"
							],
							"hint": "sin u ≥ √{2}/2 在 π/4 ≤ u ≤ 3π/4"
						},
						{
							"t": "line",
							"q": "封印 x 的範圍（兩端都可以等於）。",
							"row": "解",
							"marks": [
								"0",
								"π/2"
							],
							"seg": [
								0,
								1,
								0
							],
							"pt": [
								1,
								1
							],
							"write": "答：0 ≤ x ≤ π/2"
						}
					]
				}
			]
		},
		{
			"id": "tc_half",
			"kind": "cross",
			"tier": 3,
			"title": "半角的不等式",
			"tmul": 1.3,
			"stem": "在 0 ≤ x < 2π，解不等式 cos x > cos(x/2)。",
			"steps": [
				{
					"t": "choice",
					"q": "令 c = cos(x/2)，cos x 用 c 表示：",
					"opts": [
						"2c^{2} − 1",
						"1 − 2c^{2}",
						"2c − 1",
						"c^{2} − 1"
					],
					"hint": "cos x = cos 2(x/2)",
					"write": "c = cos(x/2)：2c^{2} − 1 > c"
				},
				{
					"t": "fill",
					"q": "移項後因式分解：",
					"template": "(2c + 1)(c − 1) > 0 ⇒ c < [0] 或 c > 1",
					"ans": [
						"−1/2"
					],
					"hint": "兩根 −1/2、1，開口向上，大於 0 在兩根外面"
				},
				{
					"t": "roots",
					"q": "c = cos(x/2)：劃掉不可能的那一邊。",
					"cands": [
						{
							"v": "c < −1/2",
							"ok": true,
							"why": "0 ≤ x/2 < π，cos(x/2) 可以小於 −1/2"
						},
						{
							"v": "c > 1",
							"ok": false,
							"why": "cos 不會大於 1"
						}
					],
					"write": "只剩 cos(x/2) < −1/2"
				},
				{
					"t": "fill",
					"q": "0 ≤ x/2 < π 裡，cos(x/2) < −1/2：",
					"template": "[0]π < x/2 < π",
					"ans": [
						"2/3"
					],
					"hint": "cos(2π/3) = −1/2"
				},
				{
					"t": "line",
					"q": "封印 x 的範圍。",
					"row": "解",
					"marks": [
						"4π/3",
						"2π"
					],
					"seg": [
						0,
						1,
						0
					],
					"pt": [
						0,
						0
					],
					"write": "答：4π/3 < x < 2π"
				}
			],
			"vars": [
				{
					"stem": "在 0 ≤ x < 2π，解不等式 cos x > 3 cos(x/2) − 2。",
					"steps": [
						{
							"t": "choice",
							"q": "令 c = cos(x/2)，cos x 用 c 表示：",
							"opts": [
								"2c^{2} − 1",
								"1 − 2c^{2}",
								"2c − 1",
								"c^{2} − 1"
							],
							"hint": "cos x = cos 2(x/2)",
							"write": "c = cos(x/2)：2c^{2} − 1 > 3c − 2"
						},
						{
							"t": "fill",
							"q": "移項後因式分解：",
							"template": "(2c − 1)(c − 1) > 0 ⇒ c < [0] 或 c > 1",
							"ans": [
								"1/2"
							],
							"hint": "2c^{2} − 3c + 1 > 0，兩根 1/2、1，開口向上，大於 0 在兩根外面"
						},
						{
							"t": "roots",
							"q": "c = cos(x/2)：劃掉不可能的那一邊。",
							"cands": [
								{
									"v": "c < 1/2",
									"ok": true,
									"why": "π/3 < x/2 < π 時 cos(x/2) < 1/2"
								},
								{
									"v": "c > 1",
									"ok": false,
									"why": "cos 不會大於 1"
								}
							],
							"write": "只剩 cos(x/2) < 1/2"
						},
						{
							"t": "fill",
							"q": "0 ≤ x/2 < π 裡，cos(x/2) < 1/2：",
							"template": "[0]π < x/2 < π",
							"ans": [
								"1/3"
							],
							"hint": "cos(π/3) = 1/2"
						},
						{
							"t": "line",
							"q": "封印 x 的範圍。",
							"row": "解",
							"marks": [
								"2π/3",
								"2π"
							],
							"seg": [
								0,
								1,
								0
							],
							"pt": [
								0,
								0
							],
							"write": "答：2π/3 < x < 2π"
						}
					]
				},
				{
					"stem": "在 0 ≤ x < 2π，解不等式 cos x + cos(x/2) ≥ 0。",
					"steps": [
						{
							"t": "choice",
							"q": "令 c = cos(x/2)，cos x 用 c 表示：",
							"opts": [
								"2c^{2} − 1",
								"1 − 2c^{2}",
								"2c − 1",
								"c^{2} − 1"
							],
							"hint": "cos x = cos 2(x/2)",
							"write": "c = cos(x/2)：2c^{2} + c − 1 ≥ 0"
						},
						{
							"t": "fill",
							"q": "移項後因式分解：",
							"template": "(2c − 1)(c + 1) ≥ 0 ⇒ c ≤ −1 或 c ≥ [0]",
							"ans": [
								"1/2"
							],
							"hint": "兩根 −1、1/2，開口向上，大於等於 0 在兩根外面"
						},
						{
							"t": "roots",
							"q": "c = cos(x/2)：劃掉不可能的那一邊。",
							"cands": [
								{
									"v": "c ≥ 1/2",
									"ok": true,
									"why": "0 ≤ x/2 ≤ π/3 時成立"
								},
								{
									"v": "c ≤ −1",
									"ok": false,
									"why": "x/2 < π，cos(x/2) 永遠大於 −1"
								}
							],
							"write": "只剩 cos(x/2) ≥ 1/2"
						},
						{
							"t": "fill",
							"q": "0 ≤ x/2 < π 裡，cos(x/2) ≥ 1/2：",
							"template": "0 ≤ x/2 ≤ [0]π",
							"ans": [
								"1/3"
							],
							"hint": "cos(π/3) = 1/2"
						},
						{
							"t": "line",
							"q": "封印 x 的範圍。",
							"row": "解",
							"marks": [
								"0",
								"2π/3"
							],
							"seg": [
								0,
								1,
								0
							],
							"pt": [
								1,
								1
							],
							"write": "答：0 ≤ x ≤ 2π/3"
						}
					]
				}
			]
		},
		{
			"id": "tc_k",
			"kind": "cross",
			"tier": 3,
			"title": "兩個交點的 k",
			"tmul": 1.3,
			"stem": "方程式 sin x + √{3} cos x = k 在 0 ≤ x ≤ 2π/3 有兩個相異實根，求 k 的範圍（寫成 a ≤ k < b）。",
			"plot": {
				"x": [
					-0.3,
					3.4916
				],
				"y": [
					-0.9,
					2.5
				],
				"pi": 6,
				"var": "u",
				"curves": [
					{
						"f": "2.0*sin(x)",
						"c": "cyan",
						"dom": [
							1.0472,
							3.1416
						],
						"at": 2
					},
					{
						"f": "1.7320508075688772",
						"c": "pink",
						"dash": true,
						"at": 2
					}
				],
				"band": {
					"lo": 1.0472,
					"hi": 3.1416,
					"at": 2
				},
				"pts": [
					{
						"x": 1.0472,
						"y": 1.7321,
						"label": "√3",
						"off": [
							-26,
							-6
						],
						"at": 2
					},
					{
						"x": 1.5708,
						"y": 2,
						"label": "2",
						"at": 2
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "先疊合：",
					"template": "sin x + √{3} cos x = [0] sin(x + [1]π)",
					"ans": [
						"2",
						"1/3"
					],
					"hint": "√{1 + 3} = 2，cos(π/3) = 1/2、sin(π/3) = √{3}/2"
				},
				{
					"t": "fill",
					"q": "令 u = x + π/3：",
					"template": "[0]π ≤ u ≤ [1]π",
					"ans": [
						"1/3",
						"1"
					],
					"hint": "0 + π/3 到 2π/3 + π/3"
				},
				{
					"t": "fill",
					"q": "看圖：水平線 y = k 和 y = 2 sin u 交兩點的時候：",
					"template": "答：[0] ≤ k < [1]",
					"ans": [
						"√3",
						"2"
					],
					"hint": "左端點高度 2 sin(π/3) = √{3}，最高點 2 只有一個交點"
				}
			],
			"vars": [
				{
					"stem": "方程式 √{3} sin x − cos x = k 在 0 ≤ x ≤ π 有兩個相異實根，求 k 的範圍（寫成 a ≤ k < b）。",
					"plot": {
						"x": [
							-0.8236,
							2.968
						],
						"y": [
							-1.3,
							2.5
						],
						"pi": 6,
						"var": "u",
						"curves": [
							{
								"f": "2.0*sin(x)",
								"c": "cyan",
								"dom": [
									-0.5236,
									2.618
								],
								"at": 2
							},
							{
								"f": "1.0",
								"c": "pink",
								"dash": true,
								"at": 2
							}
						],
						"band": {
							"lo": -0.5236,
							"hi": 2.618,
							"at": 2
						},
						"pts": [
							{
								"x": 2.618,
								"y": 1,
								"label": "1",
								"off": [
									8,
									-6
								],
								"at": 2
							},
							{
								"x": 1.5708,
								"y": 2,
								"label": "2",
								"at": 2
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "先疊合：",
							"template": "√{3} sin x − cos x = [0] sin(x − [1]π)",
							"ans": [
								"2",
								"1/6"
							],
							"hint": "√{3 + 1} = 2，cos(π/6) = √{3}/2、sin(π/6) = 1/2"
						},
						{
							"t": "fill",
							"q": "令 u = x − π/6：",
							"template": "[0]π ≤ u ≤ [1]π",
							"ans": [
								"−1/6",
								"5/6"
							],
							"hint": "0 − π/6 到 π − π/6"
						},
						{
							"t": "fill",
							"q": "看圖：水平線 y = k 和 y = 2 sin u 交兩點的時候：",
							"template": "答：[0] ≤ k < [1]",
							"ans": [
								"1",
								"2"
							],
							"hint": "右端點高度 2 sin(5π/6) = 1，最高點 2 只有一個交點"
						}
					]
				},
				{
					"stem": "方程式 sin x + cos x = k 在 0 ≤ x ≤ π/2 有兩個相異實根，求 k 的範圍（寫成 a ≤ k < b）。",
					"plot": {
						"x": [
							-0.3,
							2.7062
						],
						"y": [
							-0.9,
							1.9142
						],
						"pi": 12,
						"var": "u",
						"curves": [
							{
								"f": "1.4142135623730951*sin(x)",
								"c": "cyan",
								"dom": [
									0.7854,
									2.3562
								],
								"at": 2
							},
							{
								"f": "1.0",
								"c": "pink",
								"dash": true,
								"at": 2
							}
						],
						"band": {
							"lo": 0.7854,
							"hi": 2.3562,
							"at": 2
						},
						"pts": [
							{
								"x": 0.7854,
								"y": 1,
								"label": "1",
								"off": [
									-26,
									-6
								],
								"at": 2
							},
							{
								"x": 1.5708,
								"y": 1.4142,
								"label": "√2",
								"at": 2
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "先疊合：",
							"template": "sin x + cos x = [0] sin(x + [1]π)",
							"ans": [
								"√2",
								"1/4"
							],
							"hint": "√{1 + 1} = √{2}，cos(π/4) = √{2}/2、sin(π/4) = √{2}/2"
						},
						{
							"t": "fill",
							"q": "令 u = x + π/4：",
							"template": "[0]π ≤ u ≤ [1]π",
							"ans": [
								"1/4",
								"3/4"
							],
							"hint": "0 + π/4 到 π/2 + π/4"
						},
						{
							"t": "fill",
							"q": "看圖：水平線 y = k 和 y = √{2} sin u 交兩點的時候：",
							"template": "答：[0] ≤ k < [1]",
							"ans": [
								"1",
								"√2"
							],
							"hint": "左端點高度 √{2} sin(π/4) = 1，最高點 √{2} 只有一個交點"
						}
					]
				}
			]
		},
		{
			"id": "ta_tri",
			"kind": "angle",
			"tier": 1,
			"title": "三角形的第三個角",
			"tmul": 1.05,
			"stem": "△ABC 中，cos A = −3/5，sin B = 8/17。求 cos C。",
			"steps": [
				{
					"t": "choice",
					"q": "cos A < 0，A 是鈍角。那 B 呢？",
					"opts": [
						"B 一定是銳角",
						"B 一定是鈍角",
						"B 可能是鈍角",
						"B 一定是直角"
					],
					"hint": "三角形最多只有一個鈍角",
					"write": "A 是鈍角 ⇒ B 是銳角"
				},
				{
					"t": "fill",
					"q": "畫直角三角形：",
					"template": "sin A = [0]，cos B = [1]",
					"ans": [
						"4/5",
						"15/17"
					],
					"hint": "3、4、5 和 8、15、17，銳角的 sin、cos 都是正的"
				},
				{
					"t": "fill",
					"q": "和角公式，先算 cos(A + B)：",
					"template": "cos(A + B) = cos A cos B − sin A sin B = [0]",
					"ans": [
						"−77/85"
					],
					"hint": "(−3/5)(15/17) − (4/5)(8/17) = −45/85 − 32/85"
				},
				{
					"t": "fill",
					"q": "C = π − (A + B)：",
					"template": "答：cos C = −cos(A + B) = [0]",
					"ans": [
						"77/85"
					],
					"hint": "cos(π − θ) = −cos θ"
				}
			],
			"vars": [
				{
					"stem": "△ABC 中，cos A = −5/13，sin B = 3/5。求 cos C。",
					"steps": [
						{
							"t": "choice",
							"q": "cos A < 0，A 是鈍角。那 B 呢？",
							"opts": [
								"B 一定是銳角",
								"B 一定是鈍角",
								"B 可能是鈍角",
								"B 一定是直角"
							],
							"hint": "三角形最多只有一個鈍角",
							"write": "A 是鈍角 ⇒ B 是銳角"
						},
						{
							"t": "fill",
							"q": "畫直角三角形：",
							"template": "sin A = [0]，cos B = [1]",
							"ans": [
								"12/13",
								"4/5"
							],
							"hint": "5、12、13 和 3、4、5，銳角的 sin、cos 都是正的"
						},
						{
							"t": "fill",
							"q": "和角公式，先算 cos(A + B)：",
							"template": "cos(A + B) = cos A cos B − sin A sin B = [0]",
							"ans": [
								"−56/65"
							],
							"hint": "(−5/13)(4/5) − (12/13)(3/5) = −20/65 − 36/65"
						},
						{
							"t": "fill",
							"q": "C = π − (A + B)：",
							"template": "答：cos C = −cos(A + B) = [0]",
							"ans": [
								"56/65"
							],
							"hint": "cos(π − θ) = −cos θ"
						}
					]
				},
				{
					"stem": "△ABC 中，cos A = −4/5，sin B = 5/13。求 cos C。",
					"steps": [
						{
							"t": "choice",
							"q": "cos A < 0，A 是鈍角。那 B 呢？",
							"opts": [
								"B 一定是銳角",
								"B 一定是鈍角",
								"B 可能是鈍角",
								"B 一定是直角"
							],
							"hint": "三角形最多只有一個鈍角",
							"write": "A 是鈍角 ⇒ B 是銳角"
						},
						{
							"t": "fill",
							"q": "畫直角三角形：",
							"template": "sin A = [0]，cos B = [1]",
							"ans": [
								"3/5",
								"12/13"
							],
							"hint": "3、4、5 和 5、12、13，銳角的 sin、cos 都是正的"
						},
						{
							"t": "fill",
							"q": "和角公式，先算 cos(A + B)：",
							"template": "cos(A + B) = cos A cos B − sin A sin B = [0]",
							"ans": [
								"−63/65"
							],
							"hint": "(−4/5)(12/13) − (3/5)(5/13) = −48/65 − 15/65"
						},
						{
							"t": "fill",
							"q": "C = π − (A + B)：",
							"template": "答：cos C = −cos(A + B) = [0]",
							"ans": [
								"63/65"
							],
							"hint": "cos(π − θ) = −cos θ"
						}
					]
				}
			]
		},
		{
			"id": "ta_sixth",
			"kind": "angle",
			"tier": 2,
			"title": "六次方的差",
			"tmul": 1.25,
			"stem": "cos 2θ = 1/3，求 27(cos^{6}θ − sin^{6}θ)。",
			"steps": [
				{
					"t": "fill",
					"q": "a − b、a + b 各是多少？",
					"template": "a − b = [0]，a + b = [1]",
					"ans": [
						"1/3",
						"1"
					],
					"hint": "cos^{2}θ − sin^{2}θ = cos 2θ，cos^{2}θ + sin^{2}θ = 1",
					"pre": "a = cos^{2}θ、b = sin^{2}θ：a^{3} − b^{3} = (a − b)(a^{2} + ab + b^{2})"
				},
				{
					"t": "fill",
					"q": "ab = sin^{2}θ cos^{2}θ = (sin 2θ)^{2}/4，先求 sin^{2} 2θ：",
					"template": "sin^{2} 2θ = 1 − cos^{2} 2θ = [0]",
					"ans": [
						"8/9"
					],
					"hint": "1 − 1/9"
				},
				{
					"t": "fill",
					"q": "除以 4：",
					"template": "ab = [0]",
					"ans": [
						"2/9"
					],
					"hint": "8/9 再除以 4"
				},
				{
					"t": "fill",
					"q": "a^{2} + ab + b^{2} = (a + b)^{2} − ab：",
					"template": "a^{2} + ab + b^{2} = 1 − 2/9 = [0]",
					"ans": [
						"7/9"
					],
					"hint": "9/9 − 2/9"
				},
				{
					"t": "fill",
					"q": "全部代回：",
					"template": "答：27 · (1/3) · (7/9) = [0]",
					"ans": [
						"7"
					],
					"hint": "27 × 1/3 × 7/9"
				}
			],
			"vars": [
				{
					"stem": "cos 2θ = 1/2，求 32(cos^{6}θ − sin^{6}θ)。",
					"steps": [
						{
							"t": "fill",
							"q": "a − b、a + b 各是多少？",
							"template": "a − b = [0]，a + b = [1]",
							"ans": [
								"1/2",
								"1"
							],
							"hint": "cos^{2}θ − sin^{2}θ = cos 2θ，cos^{2}θ + sin^{2}θ = 1",
							"pre": "a = cos^{2}θ、b = sin^{2}θ：a^{3} − b^{3} = (a − b)(a^{2} + ab + b^{2})"
						},
						{
							"t": "fill",
							"q": "ab = sin^{2}θ cos^{2}θ = (sin 2θ)^{2}/4，先求 sin^{2} 2θ：",
							"template": "sin^{2} 2θ = 1 − cos^{2} 2θ = [0]",
							"ans": [
								"3/4"
							],
							"hint": "1 − 1/4"
						},
						{
							"t": "fill",
							"q": "除以 4：",
							"template": "ab = [0]",
							"ans": [
								"3/16"
							],
							"hint": "3/4 再除以 4"
						},
						{
							"t": "fill",
							"q": "a^{2} + ab + b^{2} = (a + b)^{2} − ab：",
							"template": "a^{2} + ab + b^{2} = 1 − 3/16 = [0]",
							"ans": [
								"13/16"
							],
							"hint": "16/16 − 3/16"
						},
						{
							"t": "fill",
							"q": "全部代回：",
							"template": "答：32 · (1/2) · (13/16) = [0]",
							"ans": [
								"13"
							],
							"hint": "32 × 1/2 × 13/16"
						}
					]
				},
				{
					"stem": "cos 2θ = 3/5，求 125(cos^{6}θ − sin^{6}θ)。",
					"steps": [
						{
							"t": "fill",
							"q": "a − b、a + b 各是多少？",
							"template": "a − b = [0]，a + b = [1]",
							"ans": [
								"3/5",
								"1"
							],
							"hint": "cos^{2}θ − sin^{2}θ = cos 2θ，cos^{2}θ + sin^{2}θ = 1",
							"pre": "a = cos^{2}θ、b = sin^{2}θ：a^{3} − b^{3} = (a − b)(a^{2} + ab + b^{2})"
						},
						{
							"t": "fill",
							"q": "ab = sin^{2}θ cos^{2}θ = (sin 2θ)^{2}/4，先求 sin^{2} 2θ：",
							"template": "sin^{2} 2θ = 1 − cos^{2} 2θ = [0]",
							"ans": [
								"16/25"
							],
							"hint": "1 − 9/25"
						},
						{
							"t": "fill",
							"q": "除以 4：",
							"template": "ab = [0]",
							"ans": [
								"4/25"
							],
							"hint": "16/25 再除以 4"
						},
						{
							"t": "fill",
							"q": "a^{2} + ab + b^{2} = (a + b)^{2} − ab：",
							"template": "a^{2} + ab + b^{2} = 1 − 4/25 = [0]",
							"ans": [
								"21/25"
							],
							"hint": "25/25 − 4/25"
						},
						{
							"t": "fill",
							"q": "全部代回：",
							"template": "答：125 · (3/5) · (21/25) = [0]",
							"ans": [
								"63"
							],
							"hint": "125 × 3/5 × 21/25"
						}
					]
				}
			]
		},
		{
			"id": "ta_halftan",
			"kind": "angle",
			"tier": 2,
			"title": "第四象限的半角",
			"tmul": 1.25,
			"stem": "270° < θ < 360°，且 3 sin^{2}θ + 4 cos θ − 4 = 0。求 tan(θ/2)。",
			"steps": [
				{
					"t": "choice",
					"q": "令 c = cos θ，sin^{2}θ = 1 − c^{2} 代入：",
					"opts": [
						"3c^{2} − 4c + 1 = 0",
						"3c^{2} + 4c − 1 = 0",
						"3c^{2} − 4c − 1 = 0",
						"c^{2} − 4c + 1 = 0"
					],
					"hint": "3 − 3c^{2} + 4c − 4 = 0，整理後乘 −1",
					"write": "3c^{2} − 4c + 1 = 0 ⇒ (3c − 1)(c − 1) = 0"
				},
				{
					"t": "roots",
					"q": "劃掉不合的根。",
					"cands": [
						{
							"v": "cos θ = 1/3",
							"ok": true,
							"why": "第四象限 cos θ 在 0 和 1 之間"
						},
						{
							"v": "cos θ = 1",
							"ok": false,
							"why": "cos θ = 1 時 θ = 360°，不在 270° < θ < 360° 裡"
						}
					],
					"write": "cos θ = 1/3"
				},
				{
					"t": "fill",
					"q": "第四象限的 sin θ 是負的：",
					"template": "sin θ = −√{1 − 1/9} = [0]",
					"ans": [
						"−2√2/3"
					],
					"hint": "√{8/9} = 2√{2}/3"
				},
				{
					"t": "fill",
					"q": "以切表弦 tan(θ/2) = (1 − cos θ)/sin θ，先算分子：",
					"template": "1 − cos θ = [0]",
					"ans": [
						"2/3"
					],
					"hint": "1 − 1/3"
				},
				{
					"t": "fill",
					"q": "分子除以分母：",
					"template": "答：tan(θ/2) = (2/3)/(−2√{2}/3) = [0]",
					"ans": [
						"−√2/2"
					],
					"hint": "= −1/√{2}，有理化"
				}
			],
			"vars": [
				{
					"stem": "270° < θ < 360°，且 2 sin^{2}θ + 3 cos θ − 3 = 0。求 tan(θ/2)。",
					"steps": [
						{
							"t": "choice",
							"q": "令 c = cos θ，sin^{2}θ = 1 − c^{2} 代入：",
							"opts": [
								"2c^{2} − 3c + 1 = 0",
								"2c^{2} + 3c − 1 = 0",
								"2c^{2} − 3c − 1 = 0",
								"c^{2} − 3c + 1 = 0"
							],
							"hint": "2 − 2c^{2} + 3c − 3 = 0，整理後乘 −1",
							"write": "2c^{2} − 3c + 1 = 0 ⇒ (2c − 1)(c − 1) = 0"
						},
						{
							"t": "roots",
							"q": "劃掉不合的根。",
							"cands": [
								{
									"v": "cos θ = 1/2",
									"ok": true,
									"why": "第四象限 cos θ 在 0 和 1 之間"
								},
								{
									"v": "cos θ = 1",
									"ok": false,
									"why": "cos θ = 1 時 θ = 360°，不在 270° < θ < 360° 裡"
								}
							],
							"write": "cos θ = 1/2"
						},
						{
							"t": "fill",
							"q": "第四象限的 sin θ 是負的：",
							"template": "sin θ = −√{1 − 1/4} = [0]",
							"ans": [
								"−√3/2"
							],
							"hint": "√{3/4} = √{3}/2"
						},
						{
							"t": "fill",
							"q": "以切表弦 tan(θ/2) = (1 − cos θ)/sin θ，先算分子：",
							"template": "1 − cos θ = [0]",
							"ans": [
								"1/2"
							],
							"hint": "1 − 1/2"
						},
						{
							"t": "fill",
							"q": "分子除以分母：",
							"template": "答：tan(θ/2) = (1/2)/(−√{3}/2) = [0]",
							"ans": [
								"−√3/3"
							],
							"hint": "= −1/√{3}，有理化"
						}
					]
				},
				{
					"stem": "270° < θ < 360°，且 5 sin^{2}θ + 8 cos θ − 8 = 0。求 tan(θ/2)。",
					"steps": [
						{
							"t": "choice",
							"q": "令 c = cos θ，sin^{2}θ = 1 − c^{2} 代入：",
							"opts": [
								"5c^{2} − 8c + 3 = 0",
								"5c^{2} + 8c − 3 = 0",
								"5c^{2} − 8c − 3 = 0",
								"c^{2} − 8c + 3 = 0"
							],
							"hint": "5 − 5c^{2} + 8c − 8 = 0，整理後乘 −1",
							"write": "5c^{2} − 8c + 3 = 0 ⇒ (5c − 3)(c − 1) = 0"
						},
						{
							"t": "roots",
							"q": "劃掉不合的根。",
							"cands": [
								{
									"v": "cos θ = 3/5",
									"ok": true,
									"why": "第四象限 cos θ 在 0 和 1 之間"
								},
								{
									"v": "cos θ = 1",
									"ok": false,
									"why": "cos θ = 1 時 θ = 360°，不在 270° < θ < 360° 裡"
								}
							],
							"write": "cos θ = 3/5"
						},
						{
							"t": "fill",
							"q": "第四象限的 sin θ 是負的：",
							"template": "sin θ = −√{1 − 9/25} = [0]",
							"ans": [
								"−4/5"
							],
							"hint": "√{16/25} = 4/5"
						},
						{
							"t": "fill",
							"q": "以切表弦 tan(θ/2) = (1 − cos θ)/sin θ，先算分子：",
							"template": "1 − cos θ = [0]",
							"ans": [
								"2/5"
							],
							"hint": "1 − 3/5"
						},
						{
							"t": "fill",
							"q": "分子除以分母：",
							"template": "答：tan(θ/2) = (2/5)/(−4/5) = [0]",
							"ans": [
								"−1/2"
							],
							"hint": "分子分母同乘 5，再約分"
						}
					]
				}
			]
		},
		{
			"id": "ta_lines",
			"kind": "angle",
			"tier": 1,
			"title": "兩直線的夾角",
			"tmul": 1.05,
			"stem": "L_{1}：x − 3y + 2 = 0、L_{2}：2x + y − 5 = 0 的銳夾角為 θ。求 tan θ 與 cos θ。",
			"plot": {
				"x": [
					-2.5,
					4.0
				],
				"y": [
					-1.5,
					4.2
				],
				"geo": true,
				"axes": true,
				"shapes": [
					{
						"k": "seg",
						"a": [
							-2.5,
							-0.1667
						],
						"b": [
							4,
							2
						],
						"c": "cyan"
					},
					{
						"k": "seg",
						"a": [
							3.25,
							-1.5
						],
						"b": [
							0.4,
							4.2
						],
						"c": "pink"
					},
					{
						"k": "angle",
						"o": [
							1.8571,
							1.2857
						],
						"a0": -63.4349,
						"a1": 18.4349,
						"r": 18,
						"s": "θ"
					},
					{
						"k": "label",
						"p": [
							3.6,
							2.3
						],
						"s": "L1",
						"c": "cyan"
					},
					{
						"k": "label",
						"p": [
							2.85,
							-1.2
						],
						"s": "L2",
						"c": "pink"
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "兩條直線的斜率：",
					"template": "m_{1} = [0]，m_{2} = [1]",
					"ans": [
						"1/3",
						"−2"
					],
					"hint": "ax + by + c = 0 的斜率是 −a/b"
				},
				{
					"t": "fill",
					"q": "差角公式 tan θ = |(m_{1} − m_{2})/(1 + m_{1}m_{2})|，分子、分母分開算：",
					"template": "m_{1} − m_{2} = [0]，1 + m_{1}m_{2} = [1]",
					"ans": [
						"7/3",
						"1/3"
					],
					"hint": "1/3 + 2、1 + (1/3)(−2)"
				},
				{
					"t": "fill",
					"q": "相除，取絕對值：",
					"template": "tan θ = |(7/3)/(1/3)| = [0]",
					"ans": [
						"7"
					],
					"hint": "兩個分數相除"
				},
				{
					"t": "fill",
					"q": "tan θ = 7：對邊 7、鄰邊 1 的直角三角形。",
					"template": "答：cos θ = 1/√{50} = [0]",
					"ans": [
						"√2/10"
					],
					"hint": "√{50} = 5√{2}，有理化"
				}
			],
			"vars": [
				{
					"stem": "L_{1}：2x − y + 1 = 0、L_{2}：x + y − 4 = 0 的銳夾角為 θ。求 tan θ 與 cos θ。",
					"plot": {
						"x": [
							-1.5,
							4.5
						],
						"y": [
							-1.0,
							5.5
						],
						"geo": true,
						"axes": true,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-1,
									-1
								],
								"b": [
									2.25,
									5.5
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									-1.5,
									5.5
								],
								"b": [
									4.5,
									-0.5
								],
								"c": "pink"
							},
							{
								"k": "angle",
								"o": [
									1,
									3
								],
								"a0": 63.4349,
								"a1": 135,
								"r": 18,
								"s": "θ"
							},
							{
								"k": "label",
								"p": [
									1.85,
									5.8
								],
								"s": "L1",
								"c": "cyan"
							},
							{
								"k": "label",
								"p": [
									4.1,
									-0.2
								],
								"s": "L2",
								"c": "pink"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "兩條直線的斜率：",
							"template": "m_{1} = [0]，m_{2} = [1]",
							"ans": [
								"2",
								"−1"
							],
							"hint": "ax + by + c = 0 的斜率是 −a/b"
						},
						{
							"t": "fill",
							"q": "差角公式 tan θ = |(m_{1} − m_{2})/(1 + m_{1}m_{2})|，分子、分母分開算：",
							"template": "m_{1} − m_{2} = [0]，1 + m_{1}m_{2} = [1]",
							"ans": [
								"3",
								"−1"
							],
							"hint": "2 + 1、1 + (2)(−1)"
						},
						{
							"t": "fill",
							"q": "相除，取絕對值：",
							"template": "tan θ = |(3)/(−1)| = [0]",
							"ans": [
								"3"
							],
							"hint": "兩個分數相除"
						},
						{
							"t": "fill",
							"q": "tan θ = 3：對邊 3、鄰邊 1 的直角三角形。",
							"template": "答：cos θ = 1/√{10} = [0]",
							"ans": [
								"√10/10"
							],
							"hint": "√{10} 有理化"
						}
					]
				},
				{
					"stem": "L_{1}：x − 4y + 6 = 0、L_{2}：2x + y − 6 = 0 的銳夾角為 θ。求 tan θ 與 cos θ。",
					"plot": {
						"x": [
							-1.5,
							5.0
						],
						"y": [
							-1.0,
							5.5
						],
						"geo": true,
						"axes": true,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-1.5,
									1.125
								],
								"b": [
									5,
									2.75
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									3.5,
									-1
								],
								"b": [
									0.25,
									5.5
								],
								"c": "pink"
							},
							{
								"k": "angle",
								"o": [
									2,
									2
								],
								"a0": -63.4349,
								"a1": 14.0362,
								"r": 18,
								"s": "θ"
							},
							{
								"k": "label",
								"p": [
									4.6,
									3.05
								],
								"s": "L1",
								"c": "cyan"
							},
							{
								"k": "label",
								"p": [
									3.1,
									-0.7
								],
								"s": "L2",
								"c": "pink"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "兩條直線的斜率：",
							"template": "m_{1} = [0]，m_{2} = [1]",
							"ans": [
								"1/4",
								"−2"
							],
							"hint": "ax + by + c = 0 的斜率是 −a/b"
						},
						{
							"t": "fill",
							"q": "差角公式 tan θ = |(m_{1} − m_{2})/(1 + m_{1}m_{2})|，分子、分母分開算：",
							"template": "m_{1} − m_{2} = [0]，1 + m_{1}m_{2} = [1]",
							"ans": [
								"9/4",
								"1/2"
							],
							"hint": "1/4 + 2、1 + (1/4)(−2)"
						},
						{
							"t": "fill",
							"q": "相除，取絕對值：",
							"template": "tan θ = |(9/4)/(1/2)| = [0]",
							"ans": [
								"9/2"
							],
							"hint": "兩個分數相除"
						},
						{
							"t": "fill",
							"q": "tan θ = 9/2：對邊 9、鄰邊 2 的直角三角形。",
							"template": "答：cos θ = 2/√{85} = [0]",
							"ans": [
								"2√85/85"
							],
							"hint": "√{85} 有理化"
						}
					]
				}
			]
		},
		{
			"id": "ta_roots",
			"kind": "angle",
			"tier": 2,
			"title": "根與係數",
			"tmul": 1.2,
			"stem": "√{5} − 2 是 x^{2} − (tan θ + 1/tan θ)x + 1 = 0 的一根。求 sin 2θ。",
			"steps": [
				{
					"t": "choice",
					"q": "兩根的積是 1，另一根是 1/(√{5} − 2)。有理化之後是？",
					"opts": [
						"√{5} + 2",
						"√{5} − 2",
						"2 − √{5}",
						"−√{5} − 2"
					],
					"hint": "(√{5} − 2)(√{5} + 2) = 5 − 4 = 1",
					"write": "另一根 = 1/(√{5} − 2) = √{5} + 2"
				},
				{
					"t": "fill",
					"q": "兩根的和 = x 的係數變號：",
					"template": "tan θ + 1/tan θ = (√{5} − 2) + (√{5} + 2) = [0]",
					"ans": [
						"2√5"
					],
					"hint": "−2 和 +2 抵消"
				},
				{
					"t": "choice",
					"q": "tan θ + 1/tan θ 化簡：",
					"opts": [
						"1/(sin θ cos θ)",
						"1/(sin θ + cos θ)",
						"sin θ cos θ",
						"2/cos 2θ"
					],
					"hint": "通分：(sin^{2}θ + cos^{2}θ)/(sin θ cos θ)",
					"write": "tan θ + 1/tan θ = 1/(sin θ cos θ) = 2/sin 2θ"
				},
				{
					"t": "fill",
					"q": "2/sin 2θ = 2√{5}：",
					"template": "答：sin 2θ = 1/√{5} = [0]",
					"ans": [
						"√5/5"
					],
					"hint": "1/√{5} 有理化"
				}
			],
			"vars": [
				{
					"stem": "√{2} − 1 是 x^{2} − (tan θ + 1/tan θ)x + 1 = 0 的一根。求 sin 2θ。",
					"steps": [
						{
							"t": "choice",
							"q": "兩根的積是 1，另一根是 1/(√{2} − 1)。有理化之後是？",
							"opts": [
								"√{2} + 1",
								"√{2} − 1",
								"1 − √{2}",
								"−√{2} − 1"
							],
							"hint": "(√{2} − 1)(√{2} + 1) = 2 − 1 = 1",
							"write": "另一根 = 1/(√{2} − 1) = √{2} + 1"
						},
						{
							"t": "fill",
							"q": "兩根的和 = x 的係數變號：",
							"template": "tan θ + 1/tan θ = (√{2} − 1) + (√{2} + 1) = [0]",
							"ans": [
								"2√2"
							],
							"hint": "−1 和 +1 抵消"
						},
						{
							"t": "choice",
							"q": "tan θ + 1/tan θ 化簡：",
							"opts": [
								"1/(sin θ cos θ)",
								"1/(sin θ + cos θ)",
								"sin θ cos θ",
								"2/cos 2θ"
							],
							"hint": "通分：(sin^{2}θ + cos^{2}θ)/(sin θ cos θ)",
							"write": "tan θ + 1/tan θ = 1/(sin θ cos θ) = 2/sin 2θ"
						},
						{
							"t": "fill",
							"q": "2/sin 2θ = 2√{2}：",
							"template": "答：sin 2θ = 1/√{2} = [0]",
							"ans": [
								"√2/2"
							],
							"hint": "1/√{2} 有理化"
						}
					]
				},
				{
					"stem": "√{10} − 3 是 x^{2} − (tan θ + 1/tan θ)x + 1 = 0 的一根。求 sin 2θ。",
					"steps": [
						{
							"t": "choice",
							"q": "兩根的積是 1，另一根是 1/(√{10} − 3)。有理化之後是？",
							"opts": [
								"√{10} + 3",
								"√{10} − 3",
								"3 − √{10}",
								"−√{10} − 3"
							],
							"hint": "(√{10} − 3)(√{10} + 3) = 10 − 9 = 1",
							"write": "另一根 = 1/(√{10} − 3) = √{10} + 3"
						},
						{
							"t": "fill",
							"q": "兩根的和 = x 的係數變號：",
							"template": "tan θ + 1/tan θ = (√{10} − 3) + (√{10} + 3) = [0]",
							"ans": [
								"2√10"
							],
							"hint": "−3 和 +3 抵消"
						},
						{
							"t": "choice",
							"q": "tan θ + 1/tan θ 化簡：",
							"opts": [
								"1/(sin θ cos θ)",
								"1/(sin θ + cos θ)",
								"sin θ cos θ",
								"2/cos 2θ"
							],
							"hint": "通分：(sin^{2}θ + cos^{2}θ)/(sin θ cos θ)",
							"write": "tan θ + 1/tan θ = 1/(sin θ cos θ) = 2/sin 2θ"
						},
						{
							"t": "fill",
							"q": "2/sin 2θ = 2√{10}：",
							"template": "答：sin 2θ = 1/√{10} = [0]",
							"ans": [
								"√10/10"
							],
							"hint": "1/√{10} 有理化"
						}
					]
				}
			]
		},
		{
			"id": "ta_tanpair",
			"kind": "angle",
			"tier": 2,
			"title": "兩根的 tan",
			"tmul": 1.15,
			"stem": "tan α、tan β 是 x^{2} + 5x − 3 = 0 的兩根。求 cos(α − β)/sin(α + β)。",
			"steps": [
				{
					"t": "fill",
					"q": "根與係數：",
					"template": "tan α + tan β = [0]，tan α tan β = [1]",
					"ans": [
						"−5",
						"−3"
					],
					"hint": "和 = −b/a、積 = c/a"
				},
				{
					"t": "choice",
					"q": "分子、分母同除以 cos α cos β：",
					"opts": [
						"(1 + tan α tan β)/(tan α + tan β)",
						"(1 − tan α tan β)/(tan α + tan β)",
						"(1 + tan α tan β)/(tan α − tan β)",
						"(tan α + tan β)/(1 + tan α tan β)"
					],
					"hint": "cos α cos β + sin α sin β 除以 cos α cos β 是 1 + tan α tan β",
					"write": "原式 = (1 + tan α tan β)/(tan α + tan β)"
				},
				{
					"t": "fill",
					"q": "代入：",
					"template": "答：原式 = [0]",
					"ans": [
						"2/5"
					],
					"hint": "(1 + (−3))/(−5)"
				}
			],
			"vars": [
				{
					"stem": "tan α、tan β 是 x^{2} − 4x + 2 = 0 的兩根。求 cos(α − β)/sin(α + β)。",
					"steps": [
						{
							"t": "fill",
							"q": "根與係數：",
							"template": "tan α + tan β = [0]，tan α tan β = [1]",
							"ans": [
								"4",
								"2"
							],
							"hint": "和 = −b/a、積 = c/a"
						},
						{
							"t": "choice",
							"q": "分子、分母同除以 cos α cos β：",
							"opts": [
								"(1 + tan α tan β)/(tan α + tan β)",
								"(1 − tan α tan β)/(tan α + tan β)",
								"(1 + tan α tan β)/(tan α − tan β)",
								"(tan α + tan β)/(1 + tan α tan β)"
							],
							"hint": "cos α cos β + sin α sin β 除以 cos α cos β 是 1 + tan α tan β",
							"write": "原式 = (1 + tan α tan β)/(tan α + tan β)"
						},
						{
							"t": "fill",
							"q": "代入：",
							"template": "答：原式 = [0]",
							"ans": [
								"3/4"
							],
							"hint": "(1 + 2)/4"
						}
					]
				},
				{
					"stem": "tan α、tan β 是 x^{2} + 3x − 6 = 0 的兩根。求 cos(α − β)/sin(α + β)。",
					"steps": [
						{
							"t": "fill",
							"q": "根與係數：",
							"template": "tan α + tan β = [0]，tan α tan β = [1]",
							"ans": [
								"−3",
								"−6"
							],
							"hint": "和 = −b/a、積 = c/a"
						},
						{
							"t": "choice",
							"q": "分子、分母同除以 cos α cos β：",
							"opts": [
								"(1 + tan α tan β)/(tan α + tan β)",
								"(1 − tan α tan β)/(tan α + tan β)",
								"(1 + tan α tan β)/(tan α − tan β)",
								"(tan α + tan β)/(1 + tan α tan β)"
							],
							"hint": "cos α cos β + sin α sin β 除以 cos α cos β 是 1 + tan α tan β",
							"write": "原式 = (1 + tan α tan β)/(tan α + tan β)"
						},
						{
							"t": "fill",
							"q": "代入：",
							"template": "答：原式 = [0]",
							"ans": [
								"5/3"
							],
							"hint": "(1 + (−6))/(−3)"
						}
					]
				}
			]
		},
		{
			"id": "ta_split",
			"kind": "angle",
			"tier": 3,
			"title": "拆角",
			"tmul": 1.35,
			"stem": "π/2 ≤ α ≤ π、0 ≤ β ≤ π/2，cos(α − β) = 5/13，sin(α + β) = −3/5。求 cos 2α。",
			"steps": [
				{
					"t": "fill",
					"q": "先寫出 α − β、α + β 的範圍：",
					"template": "[0] ≤ α − β ≤ π，π/2 ≤ α + β ≤ [1]π",
					"ans": [
						"0",
						"3/2"
					],
					"hint": "α − β：最小 π/2 − π/2，α + β：最大 π + π/2"
				},
				{
					"t": "choice",
					"q": "sin(α + β) = −3/5 < 0，α + β 落在哪裡？",
					"opts": [
						"π 到 3π/2（第三象限）",
						"π/2 到 π（第二象限）",
						"3π/2 到 2π（第四象限）",
						"0 到 π/2（第一象限）"
					],
					"hint": "在 π/2 到 3π/2 之間，sin 是負的只有後半段",
					"write": "π < α + β < 3π/2 ⇒ cos(α + β) < 0"
				},
				{
					"t": "fill",
					"q": "α − β 在 0 到 π，sin 是正的：",
					"template": "sin(α − β) = [0]，cos(α + β) = [1]",
					"ans": [
						"12/13",
						"−4/5"
					],
					"hint": "5、12、13 和 3、4、5"
				},
				{
					"t": "fill",
					"q": "兩項分開算：",
					"template": "cos(α + β)cos(α − β) = [0]，sin(α + β)sin(α − β) = [1]",
					"ans": [
						"−4/13",
						"−36/65"
					],
					"hint": "(−4/5)(5/13)、(−3/5)(12/13)",
					"pre": "2α = (α + β) + (α − β)：cos 2α = cos(α + β)cos(α − β) − sin(α + β)sin(α − β)"
				},
				{
					"t": "fill",
					"q": "相減：",
					"template": "答：cos 2α = −20/65 − (−36/65) = [0]",
					"ans": [
						"16/65"
					],
					"hint": "−20 + 36"
				}
			],
			"vars": [
				{
					"stem": "π/2 ≤ α ≤ π、0 ≤ β ≤ π/2，cos(α − β) = 4/5，sin(α + β) = −5/13。求 cos 2α。",
					"steps": [
						{
							"t": "fill",
							"q": "先寫出 α − β、α + β 的範圍：",
							"template": "[0] ≤ α − β ≤ π，π/2 ≤ α + β ≤ [1]π",
							"ans": [
								"0",
								"3/2"
							],
							"hint": "α − β：最小 π/2 − π/2，α + β：最大 π + π/2"
						},
						{
							"t": "choice",
							"q": "sin(α + β) = −5/13 < 0，α + β 落在哪裡？",
							"opts": [
								"π 到 3π/2（第三象限）",
								"π/2 到 π（第二象限）",
								"3π/2 到 2π（第四象限）",
								"0 到 π/2（第一象限）"
							],
							"hint": "在 π/2 到 3π/2 之間，sin 是負的只有後半段",
							"write": "π < α + β < 3π/2 ⇒ cos(α + β) < 0"
						},
						{
							"t": "fill",
							"q": "α − β 在 0 到 π，sin 是正的：",
							"template": "sin(α − β) = [0]，cos(α + β) = [1]",
							"ans": [
								"3/5",
								"−12/13"
							],
							"hint": "3、4、5 和 5、12、13"
						},
						{
							"t": "fill",
							"q": "兩項分開算：",
							"template": "cos(α + β)cos(α − β) = [0]，sin(α + β)sin(α − β) = [1]",
							"ans": [
								"−48/65",
								"−3/13"
							],
							"hint": "(−12/13)(4/5)、(−5/13)(3/5)",
							"pre": "2α = (α + β) + (α − β)：cos 2α = cos(α + β)cos(α − β) − sin(α + β)sin(α − β)"
						},
						{
							"t": "fill",
							"q": "相減：",
							"template": "答：cos 2α = −48/65 − (−15/65) = [0]",
							"ans": [
								"−33/65"
							],
							"hint": "−48 + 15"
						}
					]
				},
				{
					"stem": "π/2 ≤ α ≤ π、0 ≤ β ≤ π/2，cos(α − β) = 3/5，sin(α + β) = −8/17。求 cos 2α。",
					"steps": [
						{
							"t": "fill",
							"q": "先寫出 α − β、α + β 的範圍：",
							"template": "[0] ≤ α − β ≤ π，π/2 ≤ α + β ≤ [1]π",
							"ans": [
								"0",
								"3/2"
							],
							"hint": "α − β：最小 π/2 − π/2，α + β：最大 π + π/2"
						},
						{
							"t": "choice",
							"q": "sin(α + β) = −8/17 < 0，α + β 落在哪裡？",
							"opts": [
								"π 到 3π/2（第三象限）",
								"π/2 到 π（第二象限）",
								"3π/2 到 2π（第四象限）",
								"0 到 π/2（第一象限）"
							],
							"hint": "在 π/2 到 3π/2 之間，sin 是負的只有後半段",
							"write": "π < α + β < 3π/2 ⇒ cos(α + β) < 0"
						},
						{
							"t": "fill",
							"q": "α − β 在 0 到 π，sin 是正的：",
							"template": "sin(α − β) = [0]，cos(α + β) = [1]",
							"ans": [
								"4/5",
								"−15/17"
							],
							"hint": "3、4、5 和 8、15、17"
						},
						{
							"t": "fill",
							"q": "兩項分開算：",
							"template": "cos(α + β)cos(α − β) = [0]，sin(α + β)sin(α − β) = [1]",
							"ans": [
								"−9/17",
								"−32/85"
							],
							"hint": "(−15/17)(3/5)、(−8/17)(4/5)",
							"pre": "2α = (α + β) + (α − β)：cos 2α = cos(α + β)cos(α − β) − sin(α + β)sin(α − β)"
						},
						{
							"t": "fill",
							"q": "相減：",
							"template": "答：cos 2α = −45/85 − (−32/85) = [0]",
							"ans": [
								"−13/85"
							],
							"hint": "−45 + 32"
						}
					]
				}
			]
		},
		{
			"id": "ta_grid",
			"kind": "angle",
			"tier": 2,
			"title": "方格裡的角",
			"tmul": 1.15,
			"stem": "10 個邊長 1 的正方形排成 5 × 2 的長方形 ABCD，O 是兩條對角線的交點。求 tan∠AOB 與 cos∠AOB。",
			"plot": {
				"x": [
					-0.4,
					5.4
				],
				"y": [
					-0.6,
					2.6
				],
				"geo": true,
				"h": 150,
				"shapes": [
					{
						"k": "seg",
						"a": [
							1,
							0
						],
						"b": [
							1,
							2
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							2,
							0
						],
						"b": [
							2,
							2
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							3,
							0
						],
						"b": [
							3,
							2
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							4,
							0
						],
						"b": [
							4,
							2
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							0,
							1
						],
						"b": [
							5,
							1
						],
						"c": "faint"
					},
					{
						"k": "poly",
						"pts": [
							[
								0,
								0
							],
							[
								5,
								0
							],
							[
								5,
								2
							],
							[
								0,
								2
							]
						],
						"c": "dim"
					},
					{
						"k": "seg",
						"a": [
							0,
							0
						],
						"b": [
							5,
							2
						],
						"c": "cyan"
					},
					{
						"k": "seg",
						"a": [
							5,
							0
						],
						"b": [
							0,
							2
						],
						"c": "cyan"
					},
					{
						"k": "seg",
						"a": [
							2.5,
							1
						],
						"b": [
							2.5,
							0
						],
						"c": "gold",
						"dash": true,
						"at": 1
					},
					{
						"k": "label",
						"p": [
							-0.25,
							-0.3
						],
						"s": "A"
					},
					{
						"k": "label",
						"p": [
							5.25,
							-0.3
						],
						"s": "B"
					},
					{
						"k": "label",
						"p": [
							5.25,
							2.3
						],
						"s": "C"
					},
					{
						"k": "label",
						"p": [
							-0.25,
							2.3
						],
						"s": "D"
					},
					{
						"k": "label",
						"p": [
							2.5,
							1.35
						],
						"s": "O"
					},
					{
						"k": "label",
						"p": [
							2.5,
							-0.35
						],
						"s": "M",
						"at": 1
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "從 O 作 \\ol{AB} 的垂線，垂足 M：",
					"template": "tan∠AOM = \\ol{AM}/\\ol{OM} = [0]",
					"ans": [
						"5/2"
					],
					"hint": "\\ol{AM} = 5/2、\\ol{OM} = 1"
				},
				{
					"t": "fill",
					"q": "∠AOB = 2∠AOM：",
					"template": "tan∠AOB = [0]",
					"ans": [
						"−20/21"
					],
					"hint": "2t/(1 − t^{2})，t = 5/2"
				},
				{
					"t": "fill",
					"q": "cos 2∠AOM = (1 − t^{2})/(1 + t^{2})：",
					"template": "答：cos∠AOB = [0]",
					"ans": [
						"−21/29"
					],
					"hint": "(1 − 25/4)/(1 + 25/4)"
				}
			],
			"vars": [
				{
					"stem": "12 個邊長 1 的正方形排成 4 × 3 的長方形 ABCD，O 是兩條對角線的交點。求 tan∠AOB 與 cos∠AOB。",
					"plot": {
						"x": [
							-0.4,
							4.4
						],
						"y": [
							-0.6,
							3.6
						],
						"geo": true,
						"h": 190,
						"shapes": [
							{
								"k": "seg",
								"a": [
									1,
									0
								],
								"b": [
									1,
									3
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									2,
									0
								],
								"b": [
									2,
									3
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									3,
									0
								],
								"b": [
									3,
									3
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									0,
									1
								],
								"b": [
									4,
									1
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									0,
									2
								],
								"b": [
									4,
									2
								],
								"c": "faint"
							},
							{
								"k": "poly",
								"pts": [
									[
										0,
										0
									],
									[
										4,
										0
									],
									[
										4,
										3
									],
									[
										0,
										3
									]
								],
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									4,
									3
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									4,
									0
								],
								"b": [
									0,
									3
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									2,
									1.5
								],
								"b": [
									2,
									0
								],
								"c": "gold",
								"dash": true,
								"at": 1
							},
							{
								"k": "label",
								"p": [
									-0.25,
									-0.3
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									4.25,
									-0.3
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									4.25,
									3.3
								],
								"s": "C"
							},
							{
								"k": "label",
								"p": [
									-0.25,
									3.3
								],
								"s": "D"
							},
							{
								"k": "label",
								"p": [
									2,
									1.85
								],
								"s": "O"
							},
							{
								"k": "label",
								"p": [
									2,
									-0.35
								],
								"s": "M",
								"at": 1
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "從 O 作 \\ol{AB} 的垂線，垂足 M：",
							"template": "tan∠AOM = \\ol{AM}/\\ol{OM} = [0]",
							"ans": [
								"4/3"
							],
							"hint": "\\ol{AM} = 2、\\ol{OM} = 3/2"
						},
						{
							"t": "fill",
							"q": "∠AOB = 2∠AOM：",
							"template": "tan∠AOB = [0]",
							"ans": [
								"−24/7"
							],
							"hint": "2t/(1 − t^{2})，t = 4/3"
						},
						{
							"t": "fill",
							"q": "cos 2∠AOM = (1 − t^{2})/(1 + t^{2})：",
							"template": "答：cos∠AOB = [0]",
							"ans": [
								"−7/25"
							],
							"hint": "(1 − 16/9)/(1 + 16/9)"
						}
					]
				},
				{
					"stem": "3 個邊長 1 的正方形排成 3 × 1 的長方形 ABCD，O 是兩條對角線的交點。求 tan∠AOB 與 cos∠AOB。",
					"plot": {
						"x": [
							-0.4,
							3.4
						],
						"y": [
							-0.6,
							1.6
						],
						"geo": true,
						"h": 150,
						"shapes": [
							{
								"k": "seg",
								"a": [
									1,
									0
								],
								"b": [
									1,
									1
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									2,
									0
								],
								"b": [
									2,
									1
								],
								"c": "faint"
							},
							{
								"k": "poly",
								"pts": [
									[
										0,
										0
									],
									[
										3,
										0
									],
									[
										3,
										1
									],
									[
										0,
										1
									]
								],
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									3,
									1
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									3,
									0
								],
								"b": [
									0,
									1
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									1.5,
									0.5
								],
								"b": [
									1.5,
									0
								],
								"c": "gold",
								"dash": true,
								"at": 1
							},
							{
								"k": "label",
								"p": [
									-0.25,
									-0.3
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									3.25,
									-0.3
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									3.25,
									1.3
								],
								"s": "C"
							},
							{
								"k": "label",
								"p": [
									-0.25,
									1.3
								],
								"s": "D"
							},
							{
								"k": "label",
								"p": [
									1.5,
									0.85
								],
								"s": "O"
							},
							{
								"k": "label",
								"p": [
									1.5,
									-0.35
								],
								"s": "M",
								"at": 1
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "從 O 作 \\ol{AB} 的垂線，垂足 M：",
							"template": "tan∠AOM = \\ol{AM}/\\ol{OM} = [0]",
							"ans": [
								"3"
							],
							"hint": "\\ol{AM} = 3/2、\\ol{OM} = 1/2"
						},
						{
							"t": "fill",
							"q": "∠AOB = 2∠AOM：",
							"template": "tan∠AOB = [0]",
							"ans": [
								"−3/4"
							],
							"hint": "2t/(1 − t^{2})，t = 3"
						},
						{
							"t": "fill",
							"q": "cos 2∠AOM = (1 − t^{2})/(1 + t^{2})：",
							"template": "答：cos∠AOB = [0]",
							"ans": [
								"−4/5"
							],
							"hint": "(1 − 9)/(1 + 9)"
						}
					]
				}
			]
		},
		{
			"id": "ta_double",
			"kind": "angle",
			"tier": 3,
			"title": "兩倍的角",
			"tmul": 1.35,
			"stem": "△ABC 中，∠B = 2∠A，\\ol{AC} = 6，\\ol{BC} = 4。求 tan B。",
			"plot": {
				"x": [
					-0.6,
					4.6
				],
				"y": [
					-0.7,
					5.6608
				],
				"geo": true,
				"shapes": [
					{
						"k": "poly",
						"pts": [
							[
								0,
								0
							],
							[
								4,
								0
							],
							[
								0.625,
								4.9608
							]
						],
						"c": "cyan"
					},
					{
						"k": "angle",
						"o": [
							0.625,
							4.9608
						],
						"a0": -97.1808,
						"a1": -55.7711,
						"r": 22,
						"s": "θ"
					},
					{
						"k": "angle",
						"o": [
							0,
							0
						],
						"a0": 0,
						"a1": 82.8192,
						"r": 18,
						"s": "2θ"
					},
					{
						"k": "label",
						"p": [
							0.625,
							5.3608
						],
						"s": "A"
					},
					{
						"k": "label",
						"p": [
							-0.3,
							-0.3
						],
						"s": "B"
					},
					{
						"k": "label",
						"p": [
							4.3,
							-0.3
						],
						"s": "C"
					},
					{
						"k": "label",
						"p": [
							2.7625,
							2.5804
						],
						"s": "6"
					},
					{
						"k": "label",
						"p": [
							2.0,
							-0.4
						],
						"s": "4"
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "正弦定理：\\ol{AC} 對 B、\\ol{BC} 對 A。",
					"template": "sin B/sin A = \\ol{AC}/\\ol{BC} = [0]",
					"ans": [
						"3/2"
					],
					"hint": "6/4"
				},
				{
					"t": "fill",
					"q": "sin B = sin 2A = 2 sin A cos A：",
					"template": "sin 2A/sin A = 2 cos A = 3/2 ⇒ cos A = [0]",
					"ans": [
						"3/4"
					],
					"hint": "sin A 約掉"
				},
				{
					"t": "fill",
					"q": "二倍角：",
					"template": "cos B = cos 2A = 2cos^{2}A − 1 = [0]",
					"ans": [
						"1/8"
					],
					"hint": "2 · 9/16 − 1"
				},
				{
					"t": "fill",
					"q": "B 是銳角，sin B 是正的：",
					"template": "sin B = √{1 − 1/64} = [0]",
					"ans": [
						"3√7/8"
					],
					"hint": "√{63/64}"
				},
				{
					"t": "fill",
					"q": "tan B = sin B/cos B：",
					"template": "答：tan B = [0]",
					"ans": [
						"3√7"
					],
					"hint": "(3√{7}/8)/(1/8)"
				}
			],
			"vars": [
				{
					"stem": "△ABC 中，∠B = 2∠A，\\ol{AC} = 8，\\ol{BC} = 5。求 tan B。",
					"plot": {
						"x": [
							-0.6,
							5.6
						],
						"y": [
							-0.7,
							8.188
						],
						"geo": true,
						"shapes": [
							{
								"k": "poly",
								"pts": [
									[
										0,
										0
									],
									[
										5,
										0
									],
									[
										2.184,
										7.488
									]
								],
								"c": "cyan"
							},
							{
								"k": "angle",
								"o": [
									2.184,
									7.488
								],
								"a0": -106.2602,
								"a1": -69.3903,
								"r": 22,
								"s": "θ"
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 0,
								"a1": 73.7398,
								"r": 18,
								"s": "2θ"
							},
							{
								"k": "label",
								"p": [
									2.184,
									7.888
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									-0.3,
									-0.3
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									5.3,
									-0.3
								],
								"s": "C"
							},
							{
								"k": "label",
								"p": [
									4.042,
									3.844
								],
								"s": "8"
							},
							{
								"k": "label",
								"p": [
									2.5,
									-0.4
								],
								"s": "5"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "正弦定理：\\ol{AC} 對 B、\\ol{BC} 對 A。",
							"template": "sin B/sin A = \\ol{AC}/\\ol{BC} = [0]",
							"ans": [
								"8/5"
							],
							"hint": "8/5"
						},
						{
							"t": "fill",
							"q": "sin B = sin 2A = 2 sin A cos A：",
							"template": "sin 2A/sin A = 2 cos A = 8/5 ⇒ cos A = [0]",
							"ans": [
								"4/5"
							],
							"hint": "sin A 約掉"
						},
						{
							"t": "fill",
							"q": "二倍角：",
							"template": "cos B = cos 2A = 2cos^{2}A − 1 = [0]",
							"ans": [
								"7/25"
							],
							"hint": "2 · 16/25 − 1"
						},
						{
							"t": "fill",
							"q": "B 是銳角，sin B 是正的：",
							"template": "sin B = √{1 − 49/625} = [0]",
							"ans": [
								"24/25"
							],
							"hint": "√{576/625}"
						},
						{
							"t": "fill",
							"q": "tan B = sin B/cos B：",
							"template": "答：tan B = [0]",
							"ans": [
								"24/7"
							],
							"hint": "(24/25)/(7/25)"
						}
					]
				},
				{
					"stem": "△ABC 中，∠B = 2∠A，\\ol{AC} = 5，\\ol{BC} = 3。求 tan B。",
					"plot": {
						"x": [
							-0.6,
							3.6
						],
						"y": [
							-0.7,
							5.6135
						],
						"geo": true,
						"shapes": [
							{
								"k": "poly",
								"pts": [
									[
										0,
										0
									],
									[
										3,
										0
									],
									[
										2.0741,
										4.9135
									]
								],
								"c": "cyan"
							},
							{
								"k": "angle",
								"o": [
									2.0741,
									4.9135
								],
								"a0": -112.8854,
								"a1": -79.3281,
								"r": 22,
								"s": "θ"
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 0,
								"a1": 67.1146,
								"r": 18,
								"s": "2θ"
							},
							{
								"k": "label",
								"p": [
									2.0741,
									5.3135
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									-0.3,
									-0.3
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									3.3,
									-0.3
								],
								"s": "C"
							},
							{
								"k": "label",
								"p": [
									2.987,
									2.5568
								],
								"s": "5"
							},
							{
								"k": "label",
								"p": [
									1.5,
									-0.4
								],
								"s": "3"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "正弦定理：\\ol{AC} 對 B、\\ol{BC} 對 A。",
							"template": "sin B/sin A = \\ol{AC}/\\ol{BC} = [0]",
							"ans": [
								"5/3"
							],
							"hint": "5/3"
						},
						{
							"t": "fill",
							"q": "sin B = sin 2A = 2 sin A cos A：",
							"template": "sin 2A/sin A = 2 cos A = 5/3 ⇒ cos A = [0]",
							"ans": [
								"5/6"
							],
							"hint": "sin A 約掉"
						},
						{
							"t": "fill",
							"q": "二倍角：",
							"template": "cos B = cos 2A = 2cos^{2}A − 1 = [0]",
							"ans": [
								"7/18"
							],
							"hint": "2 · 25/36 − 1"
						},
						{
							"t": "fill",
							"q": "B 是銳角，sin B 是正的：",
							"template": "sin B = √{1 − 49/324} = [0]",
							"ans": [
								"5√11/18"
							],
							"hint": "√{275/324}"
						},
						{
							"t": "fill",
							"q": "tan B = sin B/cos B：",
							"template": "答：tan B = [0]",
							"ans": [
								"5√11/7"
							],
							"hint": "(5√{11}/18)/(7/18)"
						}
					]
				}
			]
		},
		{
			"id": "ta_shift",
			"kind": "angle",
			"tier": 1,
			"title": "通分再疊合",
			"tmul": 1.0,
			"stem": "求 √{3}/sin 20° − 1/cos 20° 的值。",
			"steps": [
				{
					"t": "fill",
					"q": "通分，分子疊合：√{3} cos 20° − sin 20° = 2(sin 60° cos 20° − cos 60° sin 20°)。",
					"template": "分子 = [0] sin 40°",
					"ans": [
						"2"
					],
					"hint": "sin(60° − 20°)"
				},
				{
					"t": "fill",
					"q": "分母用二倍角：",
					"template": "分母 = sin 20° cos 20° = [0] sin 40°",
					"ans": [
						"1/2"
					],
					"hint": "sin 40° = 2 sin 20° cos 20°"
				},
				{
					"t": "fill",
					"q": "相除：",
					"template": "答：原式 = [0]",
					"ans": [
						"4"
					],
					"hint": "2 除以 1/2"
				}
			],
			"vars": [
				{
					"stem": "求 3/sin 10° − 3√{3}/cos 10° 的值。",
					"steps": [
						{
							"t": "fill",
							"q": "通分，分子疊合：3 cos 10° − 3√{3} sin 10° = 6(sin 30° cos 10° − cos 30° sin 10°)。",
							"template": "分子 = [0] sin 20°",
							"ans": [
								"6"
							],
							"hint": "sin(30° − 10°)"
						},
						{
							"t": "fill",
							"q": "分母用二倍角：",
							"template": "分母 = sin 10° cos 10° = [0] sin 20°",
							"ans": [
								"1/2"
							],
							"hint": "sin 20° = 2 sin 10° cos 10°"
						},
						{
							"t": "fill",
							"q": "相除：",
							"template": "答：原式 = [0]",
							"ans": [
								"12"
							],
							"hint": "6 除以 1/2"
						}
					]
				},
				{
					"stem": "求 1/sin 50° + √{3}/cos 50° 的值。",
					"steps": [
						{
							"t": "fill",
							"q": "通分，分子疊合：cos 50° + √{3} sin 50° = 2(sin 30° cos 50° + cos 30° sin 50°)。",
							"template": "分子 = [0] sin 80°",
							"ans": [
								"2"
							],
							"hint": "sin(30° + 50°)"
						},
						{
							"t": "fill",
							"q": "分母用二倍角：",
							"template": "分母 = sin 50° cos 50° = [0] sin 100°",
							"ans": [
								"1/2"
							],
							"hint": "sin 100° = 2 sin 50° cos 50°"
						},
						{
							"t": "fill",
							"q": "相除：",
							"template": "答：原式 = [0]",
							"ans": [
								"4"
							],
							"hint": "sin 100° = sin 80°，2 除以 1/2"
						}
					]
				}
			]
		},
		{
			"id": "te_quad",
			"kind": "extreme",
			"tier": 1,
			"title": "換成 sin 的二次式",
			"tmul": 1.05,
			"stem": "π/6 ≤ x ≤ 7π/6 時，f(x) = cos^{2} x − 3 sin x + 2 的最大值 M、最小值 m，求 (M, m)。",
			"plot": {
				"x": [
					-2.2,
					1.6
				],
				"y": [
					-2,
					6.25
				],
				"var": "t",
				"curves": [
					{
						"f": "-1.0*x*x-3.0*x+3.0",
						"c": "orange",
						"at": 2
					}
				],
				"band": {
					"lo": -0.5,
					"hi": 1.0,
					"at": 1
				},
				"pts": [
					{
						"x": -1.5,
						"y": 5.25,
						"label": "",
						"at": 2
					},
					{
						"x": -0.5,
						"y": 4.25,
						"label": "M",
						"at": 3
					},
					{
						"x": 1,
						"y": -1,
						"label": "m",
						"at": 4
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "令 t = sin x。x 從 π/6 走到 7π/6，會經過 π/2：",
					"template": "[0] ≤ t ≤ [1]",
					"ans": [
						"−1/2",
						"1"
					],
					"hint": "最大 sin(π/2) = 1，最小 sin(7π/6)"
				},
				{
					"t": "choice",
					"q": "cos^{2} x = 1 − t^{2}，f 用 t 表示：",
					"opts": [
						"−t^{2} − 3t + 3",
						"−t^{2} − 3t + 1",
						"t^{2} − 3t + 3",
						"−t^{2} + 3t + 3"
					],
					"hint": "1 − t^{2} − 3t + 2",
					"write": "f = −t^{2} − 3t + 3 = −(t + 3/2)^{2} + 21/4"
				},
				{
					"t": "fill",
					"q": "頂點 t = −3/2 在範圍左邊，開口向下：範圍內 f 一路遞減，最大在左端點。",
					"template": "M = f(t = −1/2) = [0]",
					"ans": [
						"17/4"
					],
					"hint": "−1/4 + 3/2 + 3"
				},
				{
					"t": "fill",
					"q": "最小在右端點：",
					"template": "答：m = f(t = 1) = [0]",
					"ans": [
						"−1"
					],
					"hint": "−1 − 3 + 3"
				}
			],
			"vars": [
				{
					"stem": "π/3 ≤ x ≤ 7π/6 時，f(x) = cos^{2} x + sin x 的最大值 M、最小值 m，求 (M, m)。",
					"plot": {
						"x": [
							-1.2,
							1.6
						],
						"y": [
							-0.75,
							2.25
						],
						"var": "t",
						"curves": [
							{
								"f": "-1.0*x*x+1.0*x+1.0",
								"c": "orange",
								"at": 2
							}
						],
						"band": {
							"lo": -0.5,
							"hi": 1.0,
							"at": 1
						},
						"pts": [
							{
								"x": 0.5,
								"y": 1.25,
								"label": "",
								"at": 2
							},
							{
								"x": 0.5,
								"y": 1.25,
								"label": "M",
								"at": 3
							},
							{
								"x": -0.5,
								"y": 0.25,
								"label": "m",
								"at": 4
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "令 t = sin x。x 從 π/3 走到 7π/6，會經過 π/2：",
							"template": "[0] ≤ t ≤ [1]",
							"ans": [
								"−1/2",
								"1"
							],
							"hint": "最大 sin(π/2) = 1，最小 sin(7π/6)"
						},
						{
							"t": "choice",
							"q": "cos^{2} x = 1 − t^{2}，f 用 t 表示：",
							"opts": [
								"−t^{2} + t + 1",
								"−t^{2} + t − 1",
								"t^{2} + t + 1",
								"−t^{2} − t + 1"
							],
							"hint": "1 − t^{2} + t",
							"write": "f = −t^{2} + t + 1 = −(t − 1/2)^{2} + 5/4"
						},
						{
							"t": "fill",
							"q": "頂點 t = 1/2 在範圍裡面，開口向下：最大值就是頂點。",
							"template": "M = f(t = 1/2) = [0]",
							"ans": [
								"5/4"
							],
							"hint": "頂點的值"
						},
						{
							"t": "fill",
							"q": "最小在離頂點比較遠的端點：",
							"template": "答：m = f(t = −1/2) = [0]",
							"ans": [
								"1/4"
							],
							"hint": "−1/4 − 1/2 + 1"
						}
					]
				},
				{
					"stem": "−π/6 ≤ x ≤ 2π/3 時，f(x) = cos^{2} x + 4 sin x − 1 的最大值 M、最小值 m，求 (M, m)。",
					"plot": {
						"x": [
							-1.2,
							2.6
						],
						"y": [
							-3.25,
							5
						],
						"var": "t",
						"curves": [
							{
								"f": "-1.0*x*x+4.0*x+0.0",
								"c": "orange",
								"at": 2
							}
						],
						"band": {
							"lo": -0.5,
							"hi": 1.0,
							"at": 1
						},
						"pts": [
							{
								"x": 2,
								"y": 4,
								"label": "",
								"at": 2
							},
							{
								"x": 1,
								"y": 3,
								"label": "M",
								"at": 3
							},
							{
								"x": -0.5,
								"y": -2.25,
								"label": "m",
								"at": 4
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "令 t = sin x。x 從 −π/6 走到 2π/3，會經過 π/2：",
							"template": "[0] ≤ t ≤ [1]",
							"ans": [
								"−1/2",
								"1"
							],
							"hint": "最大 sin(π/2) = 1，最小 sin(−π/6)"
						},
						{
							"t": "choice",
							"q": "cos^{2} x = 1 − t^{2}，f 用 t 表示：",
							"opts": [
								"−t^{2} + 4t",
								"−t^{2} + 4t − 2",
								"t^{2} + 4t",
								"−t^{2} − 4t"
							],
							"hint": "1 − t^{2} + 4t − 1",
							"write": "f = −t^{2} + 4t = −(t − 2)^{2} + 4"
						},
						{
							"t": "fill",
							"q": "頂點 t = 2 在範圍右邊，開口向下：範圍內 f 一路遞增，最大在右端點。",
							"template": "M = f(t = 1) = [0]",
							"ans": [
								"3"
							],
							"hint": "−1 + 4"
						},
						{
							"t": "fill",
							"q": "最小在左端點：",
							"template": "答：m = f(t = −1/2) = [0]",
							"ans": [
								"−9/4"
							],
							"hint": "−1/4 − 2"
						}
					]
				}
			]
		},
		{
			"id": "te_sum",
			"kind": "extreme",
			"tier": 2,
			"title": "t = sin x + cos x",
			"tmul": 1.25,
			"stem": "0 ≤ x ≤ π 時，f(x) = sin 2x + 2(sin x + cos x) − 1 的最大值 M、最小值 m，求 (M, m)。",
			"plot": {
				"x": [
					-1.8,
					2.0
				],
				"y": [
					-3.6,
					3.6284
				],
				"var": "t",
				"curves": [
					{
						"f": "1.0*x*x+2.0*x-2.0",
						"c": "orange",
						"at": 2
					}
				],
				"band": {
					"lo": -1.0,
					"hi": 1.4142,
					"at": 1
				},
				"pts": [
					{
						"x": 1.4142,
						"y": 2.8284,
						"label": "M",
						"at": 3
					},
					{
						"x": -1,
						"y": -3,
						"label": "m",
						"at": 4
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "x + π/4 從 π/4 到 5π/4，sin 最大 1、最小 sin(5π/4)：",
					"template": "[0] ≤ t ≤ [1]",
					"ans": [
						"−1",
						"√2"
					],
					"hint": "√{2} × (−√{2}/2) = −1",
					"pre": "令 t = sin x + cos x = √{2} sin(x + π/4)"
				},
				{
					"t": "fill",
					"q": "t^{2} = sin^{2}x + cos^{2}x + 2 sin x cos x = 1 + sin 2x：",
					"template": "sin 2x = t^{2} − [0] ⇒ f = (t + 1)^{2} − 3",
					"ans": [
						"1"
					],
					"hint": "f = t^{2} − 1 + 2t − 1"
				},
				{
					"t": "fill",
					"q": "開口向上，離頂點 t = −1 最遠的是右端點 t = √{2}：",
					"template": "M = (1 + √{2})^{2} − 3 = [0]",
					"ans": [
						"2√2"
					],
					"hint": "展開再化簡"
				},
				{
					"t": "fill",
					"q": "頂點 t = −1 剛好是左端點：",
					"template": "答：m = [0]",
					"ans": [
						"−3"
					],
					"hint": "頂點的值"
				}
			],
			"vars": [
				{
					"stem": "0 ≤ x ≤ π 時，f(x) = sin 2x − 2(sin x + cos x) + 3 的最大值 M、最小值 m，求 (M, m)。",
					"plot": {
						"x": [
							-1.8,
							2.0
						],
						"y": [
							0.4,
							5.8
						],
						"var": "t",
						"curves": [
							{
								"f": "1.0*x*x-2.0*x+2.0",
								"c": "orange",
								"at": 2
							}
						],
						"band": {
							"lo": -1.0,
							"hi": 1.4142,
							"at": 1
						},
						"pts": [
							{
								"x": -1,
								"y": 5,
								"label": "M",
								"at": 3
							},
							{
								"x": 1,
								"y": 1,
								"label": "m",
								"at": 4
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "x + π/4 從 π/4 到 5π/4，sin 最大 1、最小 sin(5π/4)：",
							"template": "[0] ≤ t ≤ [1]",
							"ans": [
								"−1",
								"√2"
							],
							"hint": "√{2} × (−√{2}/2) = −1",
							"pre": "令 t = sin x + cos x = √{2} sin(x + π/4)"
						},
						{
							"t": "fill",
							"q": "t^{2} = sin^{2}x + cos^{2}x + 2 sin x cos x = 1 + sin 2x：",
							"template": "sin 2x = t^{2} − [0] ⇒ f = (t − 1)^{2} + 1",
							"ans": [
								"1"
							],
							"hint": "f = t^{2} − 1 − 2t + 3"
						},
						{
							"t": "fill",
							"q": "頂點 t = 1 在範圍裡面，開口向上：最大在離頂點比較遠的端點 t = −1：",
							"template": "M = (−2)^{2} + 1 = [0]",
							"ans": [
								"5"
							],
							"hint": "展開再化簡"
						},
						{
							"t": "fill",
							"q": "最小就是頂點：",
							"template": "答：m = [0]",
							"ans": [
								"1"
							],
							"hint": "頂點的值"
						}
					]
				},
				{
					"stem": "0 ≤ x ≤ π 時，f(x) = sin 2x + 3(sin x + cos x) − 1 的最大值 M、最小值 m，求 (M, m)。",
					"plot": {
						"x": [
							-2.3,
							2.0
						],
						"y": [
							-4.85,
							5.0426
						],
						"var": "t",
						"curves": [
							{
								"f": "1.0*x*x+3.0*x-2.0",
								"c": "orange",
								"at": 2
							}
						],
						"band": {
							"lo": -1.0,
							"hi": 1.4142,
							"at": 1
						},
						"pts": [
							{
								"x": 1.4142,
								"y": 4.2426,
								"label": "M",
								"at": 3
							},
							{
								"x": -1,
								"y": -4,
								"label": "m",
								"at": 4
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "x + π/4 從 π/4 到 5π/4，sin 最大 1、最小 sin(5π/4)：",
							"template": "[0] ≤ t ≤ [1]",
							"ans": [
								"−1",
								"√2"
							],
							"hint": "√{2} × (−√{2}/2) = −1",
							"pre": "令 t = sin x + cos x = √{2} sin(x + π/4)"
						},
						{
							"t": "fill",
							"q": "t^{2} = sin^{2}x + cos^{2}x + 2 sin x cos x = 1 + sin 2x：",
							"template": "sin 2x = t^{2} − [0] ⇒ f = (t + 3/2)^{2} − 17/4",
							"ans": [
								"1"
							],
							"hint": "f = t^{2} − 1 + 3t − 1"
						},
						{
							"t": "fill",
							"q": "開口向上，離頂點 t = −3/2 最遠的是右端點 t = √{2}：",
							"template": "M = (3/2 + √{2})^{2} − 17/4 = [0]",
							"ans": [
								"3√2"
							],
							"hint": "展開再化簡"
						},
						{
							"t": "fill",
							"q": "最小在左端點 t = −1：",
							"template": "答：m = [0]",
							"ans": [
								"−4"
							],
							"hint": "(1/2)^{2} − 17/4"
						}
					]
				}
			]
		},
		{
			"id": "te_box",
			"kind": "extreme",
			"tier": 1,
			"title": "疊合找最大",
			"tmul": 1.05,
			"stem": "0 ≤ x ≤ π 時，f(x) = 3 sin x − 4 cos x 的最大值 M、最小值 m，以及最大值發生時 sin x 的值。",
			"plot": {
				"x": [
					-0.3,
					3.5
				],
				"y": [
					-5.6,
					5.8
				],
				"pi": 4,
				"curves": [
					{
						"f": "3*sin(x)-4*cos(x)",
						"c": "cyan",
						"dom": [
							0.0,
							3.1416
						],
						"at": 1
					}
				],
				"band": {
					"lo": 0.0,
					"hi": 3.1416,
					"at": 1
				},
				"pts": [
					{
						"x": 2.4981,
						"y": 5,
						"label": "M",
						"at": 2
					},
					{
						"x": 0,
						"y": -4,
						"label": "m",
						"off": [
							8,
							4
						],
						"at": 3
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "疊合成 r sin(x − φ)，φ 是銳角：",
					"template": "r = [0]，cos φ = [1]，sin φ = [2]",
					"ans": [
						"5",
						"3/5",
						"4/5"
					],
					"hint": "r = √{3^{2} + 4^{2}}，r cos φ = 3、r sin φ = 4"
				},
				{
					"t": "fill",
					"q": "x − φ 從 −φ 到 π − φ，裡面有 π/2：",
					"template": "M = [0]，此時 x = π/2 + φ，sin x = cos φ = [1]",
					"ans": [
						"5",
						"3/5"
					],
					"hint": "sin(π/2 + φ) = cos φ"
				},
				{
					"t": "fill",
					"q": "最小值在端點：比較 f(0)、f(π)。",
					"template": "答：m = [0]",
					"ans": [
						"−4"
					],
					"hint": "f(0) = −4、f(π) = 4"
				}
			],
			"vars": [
				{
					"stem": "0 ≤ x ≤ π 時，f(x) = 4 sin x − 3 cos x 的最大值 M、最小值 m，以及最大值發生時 sin x 的值。",
					"plot": {
						"x": [
							-0.3,
							3.5
						],
						"y": [
							-4.6,
							5.8
						],
						"pi": 4,
						"curves": [
							{
								"f": "4*sin(x)-3*cos(x)",
								"c": "cyan",
								"dom": [
									0.0,
									3.1416
								],
								"at": 1
							}
						],
						"band": {
							"lo": 0.0,
							"hi": 3.1416,
							"at": 1
						},
						"pts": [
							{
								"x": 2.2143,
								"y": 5,
								"label": "M",
								"at": 2
							},
							{
								"x": 0,
								"y": -3,
								"label": "m",
								"off": [
									8,
									4
								],
								"at": 3
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "疊合成 r sin(x − φ)，φ 是銳角：",
							"template": "r = [0]，cos φ = [1]，sin φ = [2]",
							"ans": [
								"5",
								"4/5",
								"3/5"
							],
							"hint": "r = √{4^{2} + 3^{2}}，r cos φ = 4、r sin φ = 3"
						},
						{
							"t": "fill",
							"q": "x − φ 從 −φ 到 π − φ，裡面有 π/2：",
							"template": "M = [0]，此時 x = π/2 + φ，sin x = cos φ = [1]",
							"ans": [
								"5",
								"4/5"
							],
							"hint": "sin(π/2 + φ) = cos φ"
						},
						{
							"t": "fill",
							"q": "最小值在端點：比較 f(0)、f(π)。",
							"template": "答：m = [0]",
							"ans": [
								"−3"
							],
							"hint": "f(0) = −3、f(π) = 3"
						}
					]
				},
				{
					"stem": "0 ≤ x ≤ π 時，f(x) = 5 sin x − 12 cos x 的最大值 M、最小值 m，以及最大值發生時 sin x 的值。",
					"plot": {
						"x": [
							-0.3,
							3.5
						],
						"y": [
							-13.6,
							13.8
						],
						"pi": 4,
						"curves": [
							{
								"f": "5*sin(x)-12*cos(x)",
								"c": "cyan",
								"dom": [
									0.0,
									3.1416
								],
								"at": 1
							}
						],
						"band": {
							"lo": 0.0,
							"hi": 3.1416,
							"at": 1
						},
						"pts": [
							{
								"x": 2.7468,
								"y": 13,
								"label": "M",
								"at": 2
							},
							{
								"x": 0,
								"y": -12,
								"label": "m",
								"off": [
									8,
									4
								],
								"at": 3
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "疊合成 r sin(x − φ)，φ 是銳角：",
							"template": "r = [0]，cos φ = [1]，sin φ = [2]",
							"ans": [
								"13",
								"5/13",
								"12/13"
							],
							"hint": "r = √{5^{2} + 12^{2}}，r cos φ = 5、r sin φ = 12"
						},
						{
							"t": "fill",
							"q": "x − φ 從 −φ 到 π − φ，裡面有 π/2：",
							"template": "M = [0]，此時 x = π/2 + φ，sin x = cos φ = [1]",
							"ans": [
								"13",
								"5/13"
							],
							"hint": "sin(π/2 + φ) = cos φ"
						},
						{
							"t": "fill",
							"q": "最小值在端點：比較 f(0)、f(π)。",
							"template": "答：m = [0]",
							"ans": [
								"−12"
							],
							"hint": "f(0) = −12、f(π) = 12"
						}
					]
				}
			]
		},
		{
			"id": "te_expand",
			"kind": "extreme",
			"tier": 2,
			"title": "先展開再疊合",
			"tmul": 1.15,
			"stem": "0 ≤ x ≤ π/2 時，f(x) = 2 sin(x + π/6) − 2 cos x 的最大值 M、最小值 m，求 (M, m)。",
			"plot": {
				"x": [
					-0.5,
					2.2708
				],
				"y": [
					-1.6,
					2.3321
				],
				"pi": 12,
				"pi_lab": 6,
				"curves": [
					{
						"f": "2.0*sin(x-0.5235987755982988)",
						"c": "cyan",
						"dom": [
							0.0,
							1.5708
						],
						"at": 2
					}
				],
				"band": {
					"lo": 0.0,
					"hi": 1.5708,
					"at": 2
				}
			},
			"steps": [
				{
					"t": "fill",
					"q": "和角公式展開：",
					"template": "2 sin(x + π/6) = [0] sin x + [1] cos x",
					"ans": [
						"√3",
						"1"
					],
					"hint": "2(sin x cos(π/6) + cos x sin(π/6))"
				},
				{
					"t": "fill",
					"q": "f = √{3} sin x − cos x，疊合：",
					"template": "f = [0] sin(x − [1]π)",
					"ans": [
						"2",
						"1/6"
					],
					"hint": "cos(π/6) = √{3}/2"
				},
				{
					"t": "fill",
					"q": "x − π/6 從 −π/6 到 π/3：",
					"template": "答：M = [0]，m = [1]",
					"ans": [
						"√3",
						"−1"
					],
					"hint": "2 sin(π/3)、2 sin(−π/6)"
				}
			],
			"vars": [
				{
					"stem": "0 ≤ x ≤ π/2 時，f(x) = 2 sin(x − π/6) + 2 cos x 的最大值 M、最小值 m，求 (M, m)。",
					"plot": {
						"x": [
							-0.5,
							2.2708
						],
						"y": [
							0.4,
							2.6
						],
						"pi": 12,
						"pi_lab": 6,
						"curves": [
							{
								"f": "2.0*sin(x+0.5235987755982988)",
								"c": "cyan",
								"dom": [
									0.0,
									1.5708
								],
								"at": 2
							}
						],
						"band": {
							"lo": 0.0,
							"hi": 1.5708,
							"at": 2
						}
					},
					"steps": [
						{
							"t": "fill",
							"q": "和角公式展開：",
							"template": "2 sin(x − π/6) = [0] sin x + [1] cos x",
							"ans": [
								"√3",
								"−1"
							],
							"hint": "2(sin x cos(−π/6) + cos x sin(−π/6))"
						},
						{
							"t": "fill",
							"q": "f = √{3} sin x + cos x，疊合：",
							"template": "f = [0] sin(x + [1]π)",
							"ans": [
								"2",
								"1/6"
							],
							"hint": "cos(π/6) = √{3}/2"
						},
						{
							"t": "fill",
							"q": "x + π/6 從 π/6 到 2π/3：",
							"template": "答：M = [0]，m = [1]",
							"ans": [
								"2",
								"1"
							],
							"hint": "2、2 sin(π/6)"
						}
					]
				},
				{
					"stem": "0 ≤ x ≤ π/2 時，f(x) = 2√{2} sin(x + π/4) − 4 cos x 的最大值 M、最小值 m，求 (M, m)。",
					"plot": {
						"x": [
							-0.5,
							2.2708
						],
						"y": [
							-2.6,
							2.6
						],
						"pi": 12,
						"pi_lab": 6,
						"curves": [
							{
								"f": "2.8284271247461903*sin(x-0.7853981633974483)",
								"c": "cyan",
								"dom": [
									0.0,
									1.5708
								],
								"at": 2
							}
						],
						"band": {
							"lo": 0.0,
							"hi": 1.5708,
							"at": 2
						}
					},
					"steps": [
						{
							"t": "fill",
							"q": "和角公式展開：",
							"template": "2√{2} sin(x + π/4) = [0] sin x + [1] cos x",
							"ans": [
								"2",
								"2"
							],
							"hint": "2√{2}(sin x cos(π/4) + cos x sin(π/4))"
						},
						{
							"t": "fill",
							"q": "f = 2 sin x − 2 cos x，疊合：",
							"template": "f = [0] sin(x − [1]π)",
							"ans": [
								"2√2",
								"1/4"
							],
							"hint": "cos(π/4) = √{2}/2"
						},
						{
							"t": "fill",
							"q": "x − π/4 從 −π/4 到 π/4：",
							"template": "答：M = [0]，m = [1]",
							"ans": [
								"2",
								"−2"
							],
							"hint": "2√{2} sin(π/4)、2√{2} sin(−π/4)"
						}
					]
				}
			]
		},
		{
			"id": "te_reduce",
			"kind": "extreme",
			"tier": 2,
			"title": "降次再疊合",
			"tmul": 1.2,
			"stem": "0 ≤ x ≤ π/2 時，f(x) = 2 sin x(sin x + √{3} cos x) 的最大值 M、最小值 m，求 (M, m)。",
			"plot": {
				"x": [
					-0.4,
					1.9708
				],
				"y": [
					-0.6,
					3.5
				],
				"pi": 12,
				"pi_lab": 4,
				"curves": [
					{
						"f": "2.0*sin(2*x-0.5235987755982988)+1",
						"c": "cyan",
						"dom": [
							0.0,
							1.5708
						],
						"at": 2
					}
				],
				"band": {
					"lo": 0.0,
					"hi": 1.5708,
					"at": 2
				},
				"pts": [
					{
						"x": 1.0473,
						"y": 3,
						"label": "M",
						"at": 3
					},
					{
						"x": 0,
						"y": 0,
						"label": "m",
						"off": [
							8,
							4
						],
						"at": 3
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "展開：2 sin^{2} x = 1 − cos 2x，2 sin x cos x = sin 2x。",
					"template": "f = 1 − cos 2x + [0] sin 2x",
					"ans": [
						"√3"
					],
					"hint": "2√{3} sin x cos x = √{3} sin 2x"
				},
				{
					"t": "fill",
					"q": "疊合 √{3} sin 2x − cos 2x：",
					"template": "f = 2 sin(2x − [0]π) + 1",
					"ans": [
						"1/6"
					],
					"hint": "和 √{3} sin x − cos x 一樣"
				},
				{
					"t": "fill",
					"q": "2x − π/6 的範圍：",
					"template": "−π/6 ≤ 2x − π/6 ≤ [0]π",
					"ans": [
						"5/6"
					],
					"hint": "x = π/2 代入"
				},
				{
					"t": "fill",
					"q": "sin 在 −π/6 到 5π/6 的範圍是 −1/2 到 1：",
					"template": "答：M = [0]，m = [1]",
					"ans": [
						"3",
						"0"
					],
					"hint": "2 · 1 + 1、2 · (−1/2) + 1"
				}
			],
			"vars": [
				{
					"stem": "0 ≤ x ≤ π/2 時，f(x) = 2 cos x(√{3} sin x + cos x) 的最大值 M、最小值 m，求 (M, m)。",
					"plot": {
						"x": [
							-0.4,
							1.9708
						],
						"y": [
							-0.6,
							3.5
						],
						"pi": 12,
						"pi_lab": 4,
						"curves": [
							{
								"f": "2.0*sin(2*x+0.5235987755982988)+1",
								"c": "cyan",
								"dom": [
									0.0,
									1.5708
								],
								"at": 2
							}
						],
						"band": {
							"lo": 0.0,
							"hi": 1.5708,
							"at": 2
						},
						"pts": [
							{
								"x": 0.5235,
								"y": 3,
								"label": "M",
								"at": 3
							},
							{
								"x": 1.5708,
								"y": 0,
								"label": "m",
								"off": [
									8,
									4
								],
								"at": 3
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "展開：2 cos^{2} x = 1 + cos 2x，2 sin x cos x = sin 2x。",
							"template": "f = [0] sin 2x + cos 2x + 1",
							"ans": [
								"√3"
							],
							"hint": "2√{3} sin x cos x = √{3} sin 2x"
						},
						{
							"t": "fill",
							"q": "疊合 √{3} sin 2x + cos 2x：",
							"template": "f = 2 sin(2x + [0]π) + 1",
							"ans": [
								"1/6"
							],
							"hint": "和 √{3} sin x + cos x 一樣"
						},
						{
							"t": "fill",
							"q": "2x + π/6 的範圍：",
							"template": "π/6 ≤ 2x + π/6 ≤ [0]π",
							"ans": [
								"7/6"
							],
							"hint": "x = π/2 代入"
						},
						{
							"t": "fill",
							"q": "sin 在 π/6 到 7π/6 的範圍是 −1/2 到 1：",
							"template": "答：M = [0]，m = [1]",
							"ans": [
								"3",
								"0"
							],
							"hint": "2 · 1 + 1、2 · (−1/2) + 1"
						}
					]
				},
				{
					"stem": "0 ≤ x ≤ π/4 時，f(x) = 2 sin x(sin x + cos x) 的最大值 M、最小值 m，求 (M, m)。",
					"plot": {
						"x": [
							-0.4,
							1.1854
						],
						"y": [
							-0.6,
							2.5
						],
						"pi": 12,
						"pi_lab": 4,
						"curves": [
							{
								"f": "1.4142135623730951*sin(2*x-0.7853981633974483)+1",
								"c": "cyan",
								"dom": [
									0.0,
									0.7854
								],
								"at": 2
							}
						],
						"band": {
							"lo": 0.0,
							"hi": 0.7854,
							"at": 2
						},
						"pts": [
							{
								"x": 0.7854,
								"y": 2,
								"label": "M",
								"at": 3
							},
							{
								"x": 0,
								"y": 0,
								"label": "m",
								"off": [
									8,
									4
								],
								"at": 3
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "展開：2 sin^{2} x = 1 − cos 2x，2 sin x cos x = sin 2x。",
							"template": "f = 1 − cos 2x + [0] sin 2x",
							"ans": [
								"1"
							],
							"hint": "2 sin x cos x = sin 2x"
						},
						{
							"t": "fill",
							"q": "疊合 sin 2x − cos 2x：",
							"template": "f = √{2} sin(2x − [0]π) + 1",
							"ans": [
								"1/4"
							],
							"hint": "√{1 + 1} = √{2}，cos(π/4) = √{2}/2"
						},
						{
							"t": "fill",
							"q": "2x − π/4 的範圍：",
							"template": "−π/4 ≤ 2x − π/4 ≤ [0]π",
							"ans": [
								"1/4"
							],
							"hint": "x = π/4 代入"
						},
						{
							"t": "fill",
							"q": "sin 在 −π/4 到 π/4 的範圍是 −√{2}/2 到 √{2}/2：",
							"template": "答：M = [0]，m = [1]",
							"ans": [
								"2",
								"0"
							],
							"hint": "√{2} · √{2}/2 + 1、√{2} · (−√{2}/2) + 1"
						}
					]
				}
			]
		},
		{
			"id": "te_frac",
			"kind": "extreme",
			"tier": 3,
			"title": "分式的最值",
			"tmul": 1.35,
			"stem": "求 y = (1 − cos x)/(3 + sin x) 的最大值與最小值。",
			"plot": {
				"x": [
					-0.3,
					6.6
				],
				"y": [
					-0.15,
					0.95
				],
				"pi": 2,
				"curves": [
					{
						"f": "(1-cos(x))/(3+sin(x))",
						"c": "cyan",
						"at": 4
					},
					{
						"f": "0.75",
						"c": "pink",
						"dash": true,
						"at": 4
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "去分母 3y + y sin x = 1 − cos x，把 sin x、cos x 移到同一邊：",
					"template": "y sin x + cos x = 1 − [0]y",
					"ans": [
						"3"
					],
					"hint": "3y 移到右邊"
				},
				{
					"t": "choice",
					"q": "左邊疊合後的範圍是 ±√{y^{2} + 1}，有解的條件：",
					"opts": [
						"(1 − 3y)^{2} ≤ y^{2} + 1",
						"1 − 3y ≤ y + 1",
						"(1 − 3y)^{2} ≥ y^{2} + 1",
						"|1 − 3y| ≤ y^{2} + 1"
					],
					"hint": "a sin x + b cos x = k 有解 ⇔ k^{2} ≤ a^{2} + b^{2}",
					"write": "(1 − 3y)^{2} ≤ y^{2} + 1"
				},
				{
					"t": "fill",
					"q": "展開：1 − 6y + 9y^{2} ≤ y^{2} + 1，移項：",
					"template": "[0]y^{2} − 6y ≤ 0",
					"ans": [
						"8"
					],
					"hint": "9y^{2} − y^{2}"
				},
				{
					"t": "fill",
					"q": "2y(4y − 3) ≤ 0，在兩根之間：",
					"template": "答：[0] ≤ y ≤ [1]",
					"ans": [
						"0",
						"3/4"
					],
					"hint": "兩根 0、3/4"
				}
			],
			"vars": [
				{
					"stem": "求 y = (1 − cos x)/(2 + sin x) 的最大值與最小值。",
					"plot": {
						"x": [
							-0.3,
							6.6
						],
						"y": [
							-0.15,
							1.5333
						],
						"pi": 2,
						"curves": [
							{
								"f": "(1-cos(x))/(2+sin(x))",
								"c": "cyan",
								"at": 4
							},
							{
								"f": "1.3333333333333333",
								"c": "pink",
								"dash": true,
								"at": 4
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "去分母 2y + y sin x = 1 − cos x，把 sin x、cos x 移到同一邊：",
							"template": "y sin x + cos x = 1 − [0]y",
							"ans": [
								"2"
							],
							"hint": "2y 移到右邊"
						},
						{
							"t": "choice",
							"q": "左邊疊合後的範圍是 ±√{y^{2} + 1}，有解的條件：",
							"opts": [
								"(1 − 2y)^{2} ≤ y^{2} + 1",
								"1 − 2y ≤ y + 1",
								"(1 − 2y)^{2} ≥ y^{2} + 1",
								"|1 − 2y| ≤ y^{2} + 1"
							],
							"hint": "a sin x + b cos x = k 有解 ⇔ k^{2} ≤ a^{2} + b^{2}",
							"write": "(1 − 2y)^{2} ≤ y^{2} + 1"
						},
						{
							"t": "fill",
							"q": "展開：1 − 4y + 4y^{2} ≤ y^{2} + 1，移項：",
							"template": "[0]y^{2} − 4y ≤ 0",
							"ans": [
								"3"
							],
							"hint": "4y^{2} − y^{2}"
						},
						{
							"t": "fill",
							"q": "y(3y − 4) ≤ 0，在兩根之間：",
							"template": "答：[0] ≤ y ≤ [1]",
							"ans": [
								"0",
								"4/3"
							],
							"hint": "兩根 0、4/3"
						}
					]
				},
				{
					"stem": "求 y = (1 − cos x)/(4 + sin x) 的最大值與最小值。",
					"plot": {
						"x": [
							-0.3,
							6.6
						],
						"y": [
							-0.15,
							0.7333
						],
						"pi": 2,
						"curves": [
							{
								"f": "(1-cos(x))/(4+sin(x))",
								"c": "cyan",
								"at": 4
							},
							{
								"f": "0.5333333333333333",
								"c": "pink",
								"dash": true,
								"at": 4
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "去分母 4y + y sin x = 1 − cos x，把 sin x、cos x 移到同一邊：",
							"template": "y sin x + cos x = 1 − [0]y",
							"ans": [
								"4"
							],
							"hint": "4y 移到右邊"
						},
						{
							"t": "choice",
							"q": "左邊疊合後的範圍是 ±√{y^{2} + 1}，有解的條件：",
							"opts": [
								"(1 − 4y)^{2} ≤ y^{2} + 1",
								"1 − 4y ≤ y + 1",
								"(1 − 4y)^{2} ≥ y^{2} + 1",
								"|1 − 4y| ≤ y^{2} + 1"
							],
							"hint": "a sin x + b cos x = k 有解 ⇔ k^{2} ≤ a^{2} + b^{2}",
							"write": "(1 − 4y)^{2} ≤ y^{2} + 1"
						},
						{
							"t": "fill",
							"q": "展開：1 − 8y + 16y^{2} ≤ y^{2} + 1，移項：",
							"template": "[0]y^{2} − 8y ≤ 0",
							"ans": [
								"15"
							],
							"hint": "16y^{2} − y^{2}"
						},
						{
							"t": "fill",
							"q": "y(15y − 8) ≤ 0，在兩根之間：",
							"template": "答：[0] ≤ y ≤ [1]",
							"ans": [
								"0",
								"8/15"
							],
							"hint": "兩根 0、8/15"
						}
					]
				}
			]
		},
		{
			"id": "te_solvable",
			"kind": "extreme",
			"tier": 2,
			"title": "有解的 k",
			"tmul": 1.15,
			"stem": "方程式 cos 2x + 4 sin x = k 有實數解，求 k 的範圍。",
			"plot": {
				"x": [
					-1.6,
					1.6
				],
				"y": [
					-5.8,
					3.8
				],
				"var": "t",
				"curves": [
					{
						"f": "-2.0*x*x+4.0*x+1.0",
						"c": "orange",
						"at": 1
					}
				],
				"band": {
					"lo": -1.0,
					"hi": 1.0,
					"at": 0
				},
				"pts": [
					{
						"x": 1,
						"y": 3,
						"label": "3",
						"at": 2
					},
					{
						"x": -1,
						"y": -5,
						"label": "−5",
						"at": 2
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "令 t = sin x（−1 ≤ t ≤ 1），cos 2x = 1 − 2t^{2}：",
					"template": "k = −2t^{2} + 4t + 1 = −2(t − 1)^{2} + [0]",
					"ans": [
						"3"
					],
					"hint": "−2(t^{2} − 2t + 1) + 2 + 1"
				},
				{
					"t": "fill",
					"q": "k 是 t 在 −1 到 1 之間時，這個二次函數取到的值：",
					"template": "答：[0] ≤ k ≤ [1]",
					"ans": [
						"−5",
						"3"
					],
					"hint": "t = 1 最大，t = −1 最小"
				}
			],
			"vars": [
				{
					"stem": "方程式 cos 2x + 2 sin x = k 有實數解，求 k 的範圍。",
					"plot": {
						"x": [
							-1.6,
							1.6
						],
						"y": [
							-3.8,
							2.3
						],
						"var": "t",
						"curves": [
							{
								"f": "-2.0*x*x+2.0*x+1.0",
								"c": "orange",
								"at": 1
							}
						],
						"band": {
							"lo": -1.0,
							"hi": 1.0,
							"at": 0
						},
						"pts": [
							{
								"x": 0.5,
								"y": 1.5,
								"label": "3/2",
								"at": 2
							},
							{
								"x": -1,
								"y": -3,
								"label": "−3",
								"at": 2
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "令 t = sin x（−1 ≤ t ≤ 1），cos 2x = 1 − 2t^{2}：",
							"template": "k = −2t^{2} + 2t + 1 = −2(t − 1/2)^{2} + [0]",
							"ans": [
								"3/2"
							],
							"hint": "−2(t^{2} − t + 1/4) + 1/2 + 1"
						},
						{
							"t": "fill",
							"q": "k 是 t 在 −1 到 1 之間時，這個二次函數取到的值：",
							"template": "答：[0] ≤ k ≤ [1]",
							"ans": [
								"−3",
								"3/2"
							],
							"hint": "t = 1/2 最大，t = −1 最小"
						}
					]
				},
				{
					"stem": "方程式 cos 2x − 6 sin x = k 有實數解，求 k 的範圍。",
					"plot": {
						"x": [
							-2.1,
							1.6
						],
						"y": [
							-7.8,
							6.3
						],
						"var": "t",
						"curves": [
							{
								"f": "-2.0*x*x-6.0*x+1.0",
								"c": "orange",
								"at": 1
							}
						],
						"band": {
							"lo": -1.0,
							"hi": 1.0,
							"at": 0
						},
						"pts": [
							{
								"x": -1,
								"y": 5,
								"label": "5",
								"at": 2
							},
							{
								"x": 1,
								"y": -7,
								"label": "−7",
								"at": 2
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "令 t = sin x（−1 ≤ t ≤ 1），cos 2x = 1 − 2t^{2}：",
							"template": "k = −2t^{2} − 6t + 1 = −2(t + 3/2)^{2} + [0]",
							"ans": [
								"11/2"
							],
							"hint": "−2(t^{2} + 3t + 9/4) + 9/2 + 1"
						},
						{
							"t": "fill",
							"q": "k 是 t 在 −1 到 1 之間時，這個二次函數取到的值：",
							"template": "答：[0] ≤ k ≤ [1]",
							"ans": [
								"−7",
								"5"
							],
							"hint": "t = −1 最大，t = 1 最小"
						}
					]
				}
			]
		},
		{
			"id": "te_halfmax",
			"kind": "extreme",
			"tier": 3,
			"title": "疊合的角再對半",
			"tmul": 1.3,
			"stem": "f(x) = 8 sin x + 15 cos x 寫成 r sin(x + θ)（r > 0、θ 是銳角）。\n(1) 求 cos^{2}(θ/2)　(2) 0 ≤ x ≤ π/2 時，f 在 x = α 有最大值 k，求 k 與 sin 2α。",
			"plot": {
				"x": [
					-0.3,
					1.9
				],
				"y": [
					-1.0,
					19.0
				],
				"pi": 4,
				"curves": [
					{
						"f": "8*sin(x)+15*cos(x)",
						"c": "cyan",
						"dom": [
							0.0,
							1.5708
						],
						"at": 2
					}
				],
				"band": {
					"lo": 0.0,
					"hi": 1.5708,
					"at": 2
				}
			},
			"steps": [
				{
					"t": "fill",
					"q": "疊合：r cos θ = 8、r sin θ = 15。",
					"template": "r = [0]，cos θ = [1]",
					"ans": [
						"17",
						"8/17"
					],
					"hint": "8、15、17",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "半角公式：",
					"template": "cos^{2}(θ/2) = (1 + cos θ)/2 = [0]",
					"ans": [
						"25/34"
					],
					"hint": "(1 + 8/17)/2",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "x + θ 從 θ 到 π/2 + θ，會經過 π/2：",
					"template": "k = [0]，α = π/2 − θ",
					"ans": [
						"17"
					],
					"hint": "sin 取到 1",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "2α = π − 2θ：",
					"template": "答：sin 2α = sin 2θ = [0]",
					"ans": [
						"240/289"
					],
					"hint": "2 · (15/17) · (8/17)",
					"part": "(2)"
				}
			],
			"vars": [
				{
					"stem": "f(x) = 3 sin x + 4 cos x 寫成 r sin(x + θ)（r > 0、θ 是銳角）。\n(1) 求 cos^{2}(θ/2)　(2) 0 ≤ x ≤ π/2 時，f 在 x = α 有最大值 k，求 k 與 sin 2α。",
					"plot": {
						"x": [
							-0.3,
							1.9
						],
						"y": [
							-1.0,
							7.0
						],
						"pi": 4,
						"curves": [
							{
								"f": "3*sin(x)+4*cos(x)",
								"c": "cyan",
								"dom": [
									0.0,
									1.5708
								],
								"at": 2
							}
						],
						"band": {
							"lo": 0.0,
							"hi": 1.5708,
							"at": 2
						}
					},
					"steps": [
						{
							"t": "fill",
							"q": "疊合：r cos θ = 3、r sin θ = 4。",
							"template": "r = [0]，cos θ = [1]",
							"ans": [
								"5",
								"3/5"
							],
							"hint": "3、4、5",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "半角公式：",
							"template": "cos^{2}(θ/2) = (1 + cos θ)/2 = [0]",
							"ans": [
								"4/5"
							],
							"hint": "(1 + 3/5)/2",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "x + θ 從 θ 到 π/2 + θ，會經過 π/2：",
							"template": "k = [0]，α = π/2 − θ",
							"ans": [
								"5"
							],
							"hint": "sin 取到 1",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "2α = π − 2θ：",
							"template": "答：sin 2α = sin 2θ = [0]",
							"ans": [
								"24/25"
							],
							"hint": "2 · (4/5) · (3/5)",
							"part": "(2)"
						}
					]
				},
				{
					"stem": "f(x) = 5 sin x + 12 cos x 寫成 r sin(x + θ)（r > 0、θ 是銳角）。\n(1) 求 cos^{2}(θ/2)　(2) 0 ≤ x ≤ π/2 時，f 在 x = α 有最大值 k，求 k 與 sin 2α。",
					"plot": {
						"x": [
							-0.3,
							1.9
						],
						"y": [
							-1.0,
							15.0
						],
						"pi": 4,
						"curves": [
							{
								"f": "5*sin(x)+12*cos(x)",
								"c": "cyan",
								"dom": [
									0.0,
									1.5708
								],
								"at": 2
							}
						],
						"band": {
							"lo": 0.0,
							"hi": 1.5708,
							"at": 2
						}
					},
					"steps": [
						{
							"t": "fill",
							"q": "疊合：r cos θ = 5、r sin θ = 12。",
							"template": "r = [0]，cos θ = [1]",
							"ans": [
								"13",
								"5/13"
							],
							"hint": "5、12、13",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "半角公式：",
							"template": "cos^{2}(θ/2) = (1 + cos θ)/2 = [0]",
							"ans": [
								"9/13"
							],
							"hint": "(1 + 5/13)/2",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "x + θ 從 θ 到 π/2 + θ，會經過 π/2：",
							"template": "k = [0]，α = π/2 − θ",
							"ans": [
								"13"
							],
							"hint": "sin 取到 1",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "2α = π − 2θ：",
							"template": "答：sin 2α = sin 2θ = [0]",
							"ans": [
								"120/169"
							],
							"hint": "2 · (12/13) · (5/13)",
							"part": "(2)"
						}
					]
				}
			]
		},
		{
			"id": "te_cosprod",
			"kind": "extreme",
			"tier": 2,
			"title": "乘開再疊合",
			"tmul": 1.25,
			"stem": "0 ≤ x ≤ π/2 時，f(x) = 2 cos x(3 sin x + 4 cos x) 的最大值 M、最小值 m，求 (M, m)。",
			"plot": {
				"x": [
					-0.3,
					1.9
				],
				"y": [
					-0.8,
					9.8
				],
				"pi": 4,
				"curves": [
					{
						"f": "2*cos(x)*(3*sin(x)+4*cos(x))",
						"c": "cyan",
						"dom": [
							0.0,
							1.5708
						],
						"at": 2
					}
				],
				"band": {
					"lo": 0.0,
					"hi": 1.5708,
					"at": 2
				}
			},
			"steps": [
				{
					"t": "fill",
					"q": "乘開：6 sin x cos x + 8 cos^{2} x，用二倍角降次：",
					"template": "f = 3 sin 2x + 4 cos 2x + [0]",
					"ans": [
						"4"
					],
					"hint": "8 cos^{2} x = 4(1 + cos 2x)"
				},
				{
					"t": "fill",
					"q": "疊合（φ 是銳角，cos φ = 3/5、sin φ = 4/5）：",
					"template": "3 sin 2x + 4 cos 2x = [0] sin(2x + φ)",
					"ans": [
						"5"
					],
					"hint": "√{9 + 16}"
				},
				{
					"t": "fill",
					"q": "2x + φ 從 φ 到 π + φ，會經過 π/2：",
					"template": "M = 5 + 4 = [0]",
					"ans": [
						"9"
					],
					"hint": "sin 取到 1"
				},
				{
					"t": "fill",
					"q": "最小在右端點 2x + φ = π + φ：",
					"template": "答：m = 5 sin(π + φ) + 4 = 5 · (−4/5) + 4 = [0]",
					"ans": [
						"0"
					],
					"hint": "sin(π + φ) = −sin φ"
				}
			],
			"vars": [
				{
					"stem": "0 ≤ x ≤ π/2 時，f(x) = 2 cos x(4 sin x + 3 cos x) 的最大值 M、最小值 m，求 (M, m)。",
					"plot": {
						"x": [
							-0.3,
							1.9
						],
						"y": [
							-0.8,
							8.8
						],
						"pi": 4,
						"curves": [
							{
								"f": "2*cos(x)*(4*sin(x)+3*cos(x))",
								"c": "cyan",
								"dom": [
									0.0,
									1.5708
								],
								"at": 2
							}
						],
						"band": {
							"lo": 0.0,
							"hi": 1.5708,
							"at": 2
						}
					},
					"steps": [
						{
							"t": "fill",
							"q": "乘開：8 sin x cos x + 6 cos^{2} x，用二倍角降次：",
							"template": "f = 4 sin 2x + 3 cos 2x + [0]",
							"ans": [
								"3"
							],
							"hint": "6 cos^{2} x = 3(1 + cos 2x)"
						},
						{
							"t": "fill",
							"q": "疊合（φ 是銳角，cos φ = 4/5、sin φ = 3/5）：",
							"template": "4 sin 2x + 3 cos 2x = [0] sin(2x + φ)",
							"ans": [
								"5"
							],
							"hint": "√{16 + 9}"
						},
						{
							"t": "fill",
							"q": "2x + φ 從 φ 到 π + φ，會經過 π/2：",
							"template": "M = 5 + 3 = [0]",
							"ans": [
								"8"
							],
							"hint": "sin 取到 1"
						},
						{
							"t": "fill",
							"q": "最小在右端點 2x + φ = π + φ：",
							"template": "答：m = 5 sin(π + φ) + 3 = 5 · (−3/5) + 3 = [0]",
							"ans": [
								"0"
							],
							"hint": "sin(π + φ) = −sin φ"
						}
					]
				},
				{
					"stem": "0 ≤ x ≤ π/4 時，f(x) = 2 cos x(5 sin x + 12 cos x) 的最大值 M、最小值 m，求 (M, m)。",
					"plot": {
						"x": [
							-0.3,
							1.9
						],
						"y": [
							-0.8,
							25.8
						],
						"pi": 4,
						"curves": [
							{
								"f": "2*cos(x)*(5*sin(x)+12*cos(x))",
								"c": "cyan",
								"dom": [
									0.0,
									0.7854
								],
								"at": 2
							}
						],
						"band": {
							"lo": 0.0,
							"hi": 0.7854,
							"at": 2
						}
					},
					"steps": [
						{
							"t": "fill",
							"q": "乘開：10 sin x cos x + 24 cos^{2} x，用二倍角降次：",
							"template": "f = 5 sin 2x + 12 cos 2x + [0]",
							"ans": [
								"12"
							],
							"hint": "24 cos^{2} x = 12(1 + cos 2x)"
						},
						{
							"t": "fill",
							"q": "疊合（φ 是銳角，cos φ = 5/13、sin φ = 12/13）：",
							"template": "5 sin 2x + 12 cos 2x = [0] sin(2x + φ)",
							"ans": [
								"13"
							],
							"hint": "√{25 + 144}"
						},
						{
							"t": "fill",
							"q": "2x + φ 從 φ 到 π/2 + φ，會經過 π/2：",
							"template": "M = 13 + 12 = [0]",
							"ans": [
								"25"
							],
							"hint": "sin 取到 1"
						},
						{
							"t": "fill",
							"q": "最小在右端點 2x + φ = π/2 + φ：",
							"template": "答：m = 13 sin(π/2 + φ) + 12 = 13 · 5/13 + 12 = [0]",
							"ans": [
								"17"
							],
							"hint": "sin(π/2 + φ) = cos φ；左端點 f(0) = 24 比較大"
						}
					]
				}
			]
		},
		{
			"id": "te_cos2",
			"kind": "extreme",
			"tier": 1,
			"title": "二倍角的二次式",
			"tmul": 1.0,
			"stem": "求 f(x) = cos 2x − 2 sin x 的最大值 M、最小值 m。",
			"plot": {
				"x": [
					-1.7,
					1.5
				],
				"y": [
					-3.6,
					2.3
				],
				"var": "t",
				"curves": [
					{
						"f": "-2.0*x*x-2.0*x+1.0",
						"c": "orange",
						"at": 1
					}
				],
				"band": {
					"lo": -1.0,
					"hi": 1.0,
					"at": 1
				},
				"pts": [
					{
						"x": -0.5,
						"y": 1.5,
						"label": "M",
						"at": 2
					},
					{
						"x": 1,
						"y": -3,
						"label": "m",
						"at": 3
					}
				]
			},
			"steps": [
				{
					"t": "choice",
					"q": "令 t = sin x，cos 2x 用 t 表示：",
					"opts": [
						"1 − 2t^{2}",
						"2t^{2} − 1",
						"1 − t^{2}",
						"2t^{2} + 1"
					],
					"hint": "cos 2x = 1 − 2 sin^{2} x",
					"write": "f = 1 − 2t^{2} − 2t = −2(t + 1/2)^{2} + 3/2，−1 ≤ t ≤ 1"
				},
				{
					"t": "fill",
					"q": "頂點 t = −1/2 在範圍內：",
					"template": "M = [0]",
					"ans": [
						"3/2"
					],
					"hint": "開口向下，頂點最高"
				},
				{
					"t": "fill",
					"q": "離頂點最遠的端點：",
					"template": "答：m = [0]（t = 1）",
					"ans": [
						"−3"
					],
					"hint": "−2 − 2 + 1"
				}
			],
			"vars": [
				{
					"stem": "求 f(x) = cos 2x + sin x 的最大值 M、最小值 m。",
					"plot": {
						"x": [
							-1.7,
							1.5
						],
						"y": [
							-2.6,
							1.925
						],
						"var": "t",
						"curves": [
							{
								"f": "-2.0*x*x+1.0*x+1.0",
								"c": "orange",
								"at": 1
							}
						],
						"band": {
							"lo": -1.0,
							"hi": 1.0,
							"at": 1
						},
						"pts": [
							{
								"x": 0.25,
								"y": 1.125,
								"label": "M",
								"at": 2
							},
							{
								"x": -1,
								"y": -2,
								"label": "m",
								"at": 3
							}
						]
					},
					"steps": [
						{
							"t": "choice",
							"q": "令 t = sin x，cos 2x 用 t 表示：",
							"opts": [
								"1 − 2t^{2}",
								"2t^{2} − 1",
								"1 − t^{2}",
								"2t^{2} + 1"
							],
							"hint": "cos 2x = 1 − 2 sin^{2} x",
							"write": "f = 1 − 2t^{2} + t = −2(t − 1/4)^{2} + 9/8，−1 ≤ t ≤ 1"
						},
						{
							"t": "fill",
							"q": "頂點 t = 1/4 在範圍內：",
							"template": "M = [0]",
							"ans": [
								"9/8"
							],
							"hint": "開口向下，頂點最高"
						},
						{
							"t": "fill",
							"q": "離頂點最遠的端點：",
							"template": "答：m = [0]（t = −1）",
							"ans": [
								"−2"
							],
							"hint": "−2 − 1 + 1"
						}
					]
				},
				{
					"stem": "求 f(x) = cos 2x − 3 sin x 的最大值 M、最小值 m。",
					"plot": {
						"x": [
							-1.7,
							1.5
						],
						"y": [
							-4.6,
							2.925
						],
						"var": "t",
						"curves": [
							{
								"f": "-2.0*x*x-3.0*x+1.0",
								"c": "orange",
								"at": 1
							}
						],
						"band": {
							"lo": -1.0,
							"hi": 1.0,
							"at": 1
						},
						"pts": [
							{
								"x": -0.75,
								"y": 2.125,
								"label": "M",
								"at": 2
							},
							{
								"x": 1,
								"y": -4,
								"label": "m",
								"at": 3
							}
						]
					},
					"steps": [
						{
							"t": "choice",
							"q": "令 t = sin x，cos 2x 用 t 表示：",
							"opts": [
								"1 − 2t^{2}",
								"2t^{2} − 1",
								"1 − t^{2}",
								"2t^{2} + 1"
							],
							"hint": "cos 2x = 1 − 2 sin^{2} x",
							"write": "f = 1 − 2t^{2} − 3t = −2(t + 3/4)^{2} + 17/8，−1 ≤ t ≤ 1"
						},
						{
							"t": "fill",
							"q": "頂點 t = −3/4 在範圍內：",
							"template": "M = [0]",
							"ans": [
								"17/8"
							],
							"hint": "開口向下，頂點最高"
						},
						{
							"t": "fill",
							"q": "離頂點最遠的端點：",
							"template": "答：m = [0]（t = 1）",
							"ans": [
								"−4"
							],
							"hint": "−2 − 3 + 1"
						}
					]
				}
			]
		},
		{
			"id": "tq_fan",
			"kind": "quest",
			"tier": 1,
			"title": "扇形花圃",
			"tmul": 1.0,
			"stem": "用 36 公尺長的籬笆圍一個扇形花圃（兩條半徑加一段弧）。半徑 r 是多少時面積最大？最大面積與圓心角各是多少？",
			"plot": {
				"x": [
					-9.8,
					9.8
				],
				"y": [
					-1.2,
					10.2
				],
				"geo": true,
				"h": 190,
				"shapes": [
					{
						"k": "sector",
						"o": [
							0,
							0
						],
						"r": 9,
						"a0": 32.7,
						"a1": 147.3,
						"c": "lime",
						"fill": "lime",
						"alpha": 0.15
					},
					{
						"k": "angle",
						"o": [
							0,
							0
						],
						"a0": 32.7,
						"a1": 147.3,
						"r": 16,
						"s": "θ"
					},
					{
						"k": "label",
						"p": [
							5.0,
							2.0
						],
						"s": "r"
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "弧長 = 36 − 2r，面積 = (1/2) · r · 弧長：",
					"template": "面積 = −r^{2} + [0]r",
					"ans": [
						"18"
					],
					"hint": "(1/2) r (36 − 2r)"
				},
				{
					"t": "fill",
					"q": "配方：−(r − 9)^{2} + 81。",
					"template": "r = [0] 時面積最大，最大面積 [1] 平方公尺",
					"ans": [
						"9",
						"81"
					],
					"hint": "頂點"
				},
				{
					"t": "fill",
					"q": "圓心角 = 弧長/半徑：",
					"template": "答：θ = (36 − 18)/9 = [0]（弧度）",
					"ans": [
						"2"
					],
					"hint": "18/9"
				}
			],
			"vars": [
				{
					"stem": "用 40 公尺長的籬笆圍一個扇形花圃（兩條半徑加一段弧）。半徑 r 是多少時面積最大？最大面積與圓心角各是多少？",
					"plot": {
						"x": [
							-9.8,
							9.8
						],
						"y": [
							-1.2,
							10.2
						],
						"geo": true,
						"h": 190,
						"shapes": [
							{
								"k": "sector",
								"o": [
									0,
									0
								],
								"r": 9,
								"a0": 32.7,
								"a1": 147.3,
								"c": "lime",
								"fill": "lime",
								"alpha": 0.15
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 32.7,
								"a1": 147.3,
								"r": 16,
								"s": "θ"
							},
							{
								"k": "label",
								"p": [
									5.0,
									2.0
								],
								"s": "r"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "弧長 = 40 − 2r，面積 = (1/2) · r · 弧長：",
							"template": "面積 = −r^{2} + [0]r",
							"ans": [
								"20"
							],
							"hint": "(1/2) r (40 − 2r)"
						},
						{
							"t": "fill",
							"q": "配方：−(r − 10)^{2} + 100。",
							"template": "r = [0] 時面積最大，最大面積 [1] 平方公尺",
							"ans": [
								"10",
								"100"
							],
							"hint": "頂點"
						},
						{
							"t": "fill",
							"q": "圓心角 = 弧長/半徑：",
							"template": "答：θ = (40 − 20)/10 = [0]（弧度）",
							"ans": [
								"2"
							],
							"hint": "20/10"
						}
					]
				},
				{
					"stem": "用 28 公尺長的籬笆圍一個扇形花圃（兩條半徑加一段弧）。半徑 r 是多少時面積最大？最大面積與圓心角各是多少？",
					"plot": {
						"x": [
							-9.8,
							9.8
						],
						"y": [
							-1.2,
							10.2
						],
						"geo": true,
						"h": 190,
						"shapes": [
							{
								"k": "sector",
								"o": [
									0,
									0
								],
								"r": 9,
								"a0": 32.7,
								"a1": 147.3,
								"c": "lime",
								"fill": "lime",
								"alpha": 0.15
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 32.7,
								"a1": 147.3,
								"r": 16,
								"s": "θ"
							},
							{
								"k": "label",
								"p": [
									5.0,
									2.0
								],
								"s": "r"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "弧長 = 28 − 2r，面積 = (1/2) · r · 弧長：",
							"template": "面積 = −r^{2} + [0]r",
							"ans": [
								"14"
							],
							"hint": "(1/2) r (28 − 2r)"
						},
						{
							"t": "fill",
							"q": "配方：−(r − 7)^{2} + 49。",
							"template": "r = [0] 時面積最大，最大面積 [1] 平方公尺",
							"ans": [
								"7",
								"49"
							],
							"hint": "頂點"
						},
						{
							"t": "fill",
							"q": "圓心角 = 弧長/半徑：",
							"template": "答：θ = (28 − 14)/7 = [0]（弧度）",
							"ans": [
								"2"
							],
							"hint": "14/7"
						}
					]
				}
			]
		},
		{
			"id": "tq_cone",
			"kind": "quest",
			"tier": 2,
			"title": "圓錐上的螞蟻",
			"tmul": 1.25,
			"stem": "圓錐的母線 \\ol{OA} = 12、底圓半徑 4，D 在母線 \\ol{OA} 上，\\ol{OD} = 6。螞蟻從 A 出發，沿側面繞一圈爬到 D，最短要爬多遠？",
			"plot": {
				"x": [
					-13.0,
					13.0
				],
				"y": [
					-2.0,
					13.0
				],
				"geo": true,
				"h": 200,
				"shapes": [
					{
						"k": "seg",
						"a": [
							-4,
							0
						],
						"b": [
							0,
							11.3137
						],
						"c": "cyan",
						"until": 2
					},
					{
						"k": "seg",
						"a": [
							4,
							0
						],
						"b": [
							0,
							11.3137
						],
						"c": "cyan",
						"until": 2
					},
					{
						"k": "ellipse",
						"o": [
							0,
							0
						],
						"rx": 4,
						"ry": 1.1,
						"c": "cyan",
						"until": 2
					},
					{
						"k": "dot",
						"p": [
							4,
							0
						],
						"s": "A",
						"off": [
							6,
							14
						],
						"until": 2
					},
					{
						"k": "dot",
						"p": [
							2,
							5.6569
						],
						"s": "D",
						"until": 2
					},
					{
						"k": "label",
						"p": [
							0,
							12.4137
						],
						"s": "O",
						"until": 2
					},
					{
						"k": "sector",
						"o": [
							0,
							0
						],
						"r": 12,
						"a0": 30,
						"a1": 150,
						"c": "cyan",
						"fill": "cyan",
						"alpha": 0.1,
						"at": 2
					},
					{
						"k": "angle",
						"o": [
							0,
							0
						],
						"a0": 30,
						"a1": 150,
						"r": 16,
						"s": "",
						"at": 2
					},
					{
						"k": "dot",
						"p": [
							10.3923,
							6
						],
						"s": "A",
						"at": 2
					},
					{
						"k": "dot",
						"p": [
							-5.1962,
							3
						],
						"s": "D",
						"off": [
							-8,
							-10
						],
						"at": 2
					},
					{
						"k": "label",
						"p": [
							-10.8923,
							7.6
						],
						"s": "A'",
						"at": 2
					},
					{
						"k": "label",
						"p": [
							0,
							-1.0
						],
						"s": "O",
						"at": 2
					},
					{
						"k": "seg",
						"a": [
							10.3923,
							6
						],
						"b": [
							-5.1962,
							3
						],
						"c": "gold",
						"w": 2.6,
						"at": 3
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "沿 \\ol{OA} 剪開攤平，是半徑 12 的扇形：",
					"template": "扇形的弧長 = 底圓周長 = [0]π",
					"ans": [
						"8"
					],
					"hint": "2π · 4"
				},
				{
					"t": "fill",
					"q": "圓心角 = 弧長/半徑：",
					"template": "∠AOA' = 8π/12 = [0]π",
					"ans": [
						"2/3"
					],
					"hint": "約分"
				},
				{
					"t": "fill",
					"q": "攤平後最短路徑是線段 \\ol{AD}（D 在 \\ol{OA'} 上）。△AOD：\\ol{OA} = 12、\\ol{OD} = 6、夾角 2π/3，用餘弦定理：",
					"template": "\\ol{AD}^{2} = 144 + 36 − 2 · 12 · 6 · cos(2π/3) = [0]",
					"ans": [
						"252"
					],
					"hint": "cos(2π/3) = −1/2，所以是 144 + 36 + 72"
				},
				{
					"t": "fill",
					"q": "開根號：",
					"template": "答：\\ol{AD} = √{252} = [0]",
					"ans": [
						"6√7"
					],
					"hint": "252 = 36 × 7"
				}
			],
			"vars": [
				{
					"stem": "圓錐的母線 \\ol{OA} = 12、底圓半徑 3，D 在母線 \\ol{OA} 上，\\ol{OD} = 4。螞蟻從 A 出發，沿側面繞一圈爬到 D，最短要爬多遠？",
					"plot": {
						"x": [
							-13.0,
							13.0
						],
						"y": [
							-2.0,
							13.0
						],
						"geo": true,
						"h": 200,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-3,
									0
								],
								"b": [
									0,
									11.619
								],
								"c": "cyan",
								"until": 2
							},
							{
								"k": "seg",
								"a": [
									3,
									0
								],
								"b": [
									0,
									11.619
								],
								"c": "cyan",
								"until": 2
							},
							{
								"k": "ellipse",
								"o": [
									0,
									0
								],
								"rx": 3,
								"ry": 0.825,
								"c": "cyan",
								"until": 2
							},
							{
								"k": "dot",
								"p": [
									3,
									0
								],
								"s": "A",
								"off": [
									6,
									14
								],
								"until": 2
							},
							{
								"k": "dot",
								"p": [
									1,
									7.746
								],
								"s": "D",
								"until": 2
							},
							{
								"k": "label",
								"p": [
									0,
									12.719
								],
								"s": "O",
								"until": 2
							},
							{
								"k": "sector",
								"o": [
									0,
									0
								],
								"r": 12,
								"a0": 45,
								"a1": 135,
								"c": "cyan",
								"fill": "cyan",
								"alpha": 0.1,
								"at": 2
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 45,
								"a1": 135,
								"r": 16,
								"s": "",
								"at": 2
							},
							{
								"k": "dot",
								"p": [
									8.4853,
									8.4853
								],
								"s": "A",
								"at": 2
							},
							{
								"k": "dot",
								"p": [
									-2.8284,
									2.8284
								],
								"s": "D",
								"off": [
									-8,
									-10
								],
								"at": 2
							},
							{
								"k": "label",
								"p": [
									-8.9853,
									10.0853
								],
								"s": "A'",
								"at": 2
							},
							{
								"k": "label",
								"p": [
									0,
									-1.0
								],
								"s": "O",
								"at": 2
							},
							{
								"k": "seg",
								"a": [
									8.4853,
									8.4853
								],
								"b": [
									-2.8284,
									2.8284
								],
								"c": "gold",
								"w": 2.6,
								"at": 3
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "沿 \\ol{OA} 剪開攤平，是半徑 12 的扇形：",
							"template": "扇形的弧長 = 底圓周長 = [0]π",
							"ans": [
								"6"
							],
							"hint": "2π · 3"
						},
						{
							"t": "fill",
							"q": "圓心角 = 弧長/半徑：",
							"template": "∠AOA' = 6π/12 = [0]π",
							"ans": [
								"1/2"
							],
							"hint": "約分"
						},
						{
							"t": "fill",
							"q": "攤平後最短路徑是線段 \\ol{AD}（D 在 \\ol{OA'} 上）。△AOD：\\ol{OA} = 12、\\ol{OD} = 4、夾角 π/2，用餘弦定理：",
							"template": "\\ol{AD}^{2} = 144 + 16 − 2 · 12 · 4 · cos(π/2) = [0]",
							"ans": [
								"160"
							],
							"hint": "cos(π/2) = 0，最後一項是 0"
						},
						{
							"t": "fill",
							"q": "開根號：",
							"template": "答：\\ol{AD} = √{160} = [0]",
							"ans": [
								"4√10"
							],
							"hint": "160 = 16 × 10"
						}
					]
				},
				{
					"stem": "圓錐的母線 \\ol{OA} = 12、底圓半徑 2，D 在母線 \\ol{OA} 上，\\ol{OD} = 6。螞蟻從 A 出發，沿側面繞一圈爬到 D，最短要爬多遠？",
					"plot": {
						"x": [
							-13.0,
							13.0
						],
						"y": [
							-2.0,
							13.0
						],
						"geo": true,
						"h": 200,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-2,
									0
								],
								"b": [
									0,
									11.8322
								],
								"c": "cyan",
								"until": 2
							},
							{
								"k": "seg",
								"a": [
									2,
									0
								],
								"b": [
									0,
									11.8322
								],
								"c": "cyan",
								"until": 2
							},
							{
								"k": "ellipse",
								"o": [
									0,
									0
								],
								"rx": 2,
								"ry": 0.55,
								"c": "cyan",
								"until": 2
							},
							{
								"k": "dot",
								"p": [
									2,
									0
								],
								"s": "A",
								"off": [
									6,
									14
								],
								"until": 2
							},
							{
								"k": "dot",
								"p": [
									1,
									5.9161
								],
								"s": "D",
								"until": 2
							},
							{
								"k": "label",
								"p": [
									0,
									12.9322
								],
								"s": "O",
								"until": 2
							},
							{
								"k": "sector",
								"o": [
									0,
									0
								],
								"r": 12,
								"a0": 60,
								"a1": 120,
								"c": "cyan",
								"fill": "cyan",
								"alpha": 0.1,
								"at": 2
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 60,
								"a1": 120,
								"r": 16,
								"s": "",
								"at": 2
							},
							{
								"k": "dot",
								"p": [
									6,
									10.3923
								],
								"s": "A",
								"at": 2
							},
							{
								"k": "dot",
								"p": [
									-3,
									5.1962
								],
								"s": "D",
								"off": [
									-8,
									-10
								],
								"at": 2
							},
							{
								"k": "label",
								"p": [
									-6.5,
									11.9923
								],
								"s": "A'",
								"at": 2
							},
							{
								"k": "label",
								"p": [
									0,
									-1.0
								],
								"s": "O",
								"at": 2
							},
							{
								"k": "seg",
								"a": [
									6,
									10.3923
								],
								"b": [
									-3,
									5.1962
								],
								"c": "gold",
								"w": 2.6,
								"at": 3
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "沿 \\ol{OA} 剪開攤平，是半徑 12 的扇形：",
							"template": "扇形的弧長 = 底圓周長 = [0]π",
							"ans": [
								"4"
							],
							"hint": "2π · 2"
						},
						{
							"t": "fill",
							"q": "圓心角 = 弧長/半徑：",
							"template": "∠AOA' = 4π/12 = [0]π",
							"ans": [
								"1/3"
							],
							"hint": "約分"
						},
						{
							"t": "fill",
							"q": "攤平後最短路徑是線段 \\ol{AD}（D 在 \\ol{OA'} 上）。△AOD：\\ol{OA} = 12、\\ol{OD} = 6、夾角 π/3，用餘弦定理：",
							"template": "\\ol{AD}^{2} = 144 + 36 − 2 · 12 · 6 · cos(π/3) = [0]",
							"ans": [
								"108"
							],
							"hint": "cos(π/3) = 1/2，所以是 144 + 36 − 72"
						},
						{
							"t": "fill",
							"q": "開根號：",
							"template": "答：\\ol{AD} = √{108} = [0]",
							"ans": [
								"6√3"
							],
							"hint": "108 = 36 × 3"
						}
					]
				}
			]
		},
		{
			"id": "tq_wheel",
			"kind": "quest",
			"tier": 2,
			"title": "滾動的輪子",
			"tmul": 1.15,
			"stem": "半徑 2 公尺的輪子沿地面向右滾動（不打滑）。輪上一點 P 一開始碰著地面。\n(1) 輪子滾了 4π/3 公尺時，P 離地多高？(2) 滾了 x 公尺時，P 離地 h(x) = ？",
			"plot": {
				"x": [
					-2.6,
					6.5888
				],
				"y": [
					-0.6,
					4.6
				],
				"geo": true,
				"h": 150,
				"shapes": [
					{
						"k": "seg",
						"a": [
							-2.6,
							0
						],
						"b": [
							6.5888,
							0
						],
						"c": "dim"
					}
				],
				"groups": [
					{
						"o": [
							0,
							2
						],
						"anim": {
							"k": "roll",
							"r": 2,
							"dist": 4.1888,
							"dur": 3.0
						},
						"trace": [
							0,
							-2
						],
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 2,
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									0,
									-2
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									2,
									0
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									-2,
									0
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									0,
									2
								],
								"c": "faint"
							},
							{
								"k": "dot",
								"p": [
									0,
									-2
								],
								"s": "P",
								"off": [
									6,
									14
								]
							}
						]
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "滾過的距離 = 轉過的弧長 = 半徑 × 轉過的弧度：",
					"template": "轉了 (4π/3)/2 = [0]π",
					"ans": [
						"2/3"
					],
					"hint": "弧長 = rθ",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "P 從最低點繞圓心轉 2π/3，離圓心的高度差是 −2 cos(2π/3)。",
					"template": "P 離地 2 − 2 cos(2π/3) = [0]",
					"ans": [
						"3"
					],
					"hint": "cos(2π/3) = −1/2",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "滾 x 公尺就轉 x/2：",
					"template": "答：h(x) = [0] − 2 cos(x/[1])",
					"ans": [
						"2",
						"2"
					],
					"hint": "圓心離地 2",
					"part": "(2)"
				}
			],
			"vars": [
				{
					"stem": "半徑 3 公尺的輪子沿地面向右滾動（不打滑）。輪上一點 P 一開始碰著地面。\n(1) 輪子滾了 π 公尺時，P 離地多高？(2) 滾了 x 公尺時，P 離地 h(x) = ？",
					"plot": {
						"x": [
							-3.6,
							6.5416
						],
						"y": [
							-0.6,
							6.6
						],
						"geo": true,
						"h": 150,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-3.6,
									0
								],
								"b": [
									6.5416,
									0
								],
								"c": "dim"
							}
						],
						"groups": [
							{
								"o": [
									0,
									3
								],
								"anim": {
									"k": "roll",
									"r": 3,
									"dist": 3.1416,
									"dur": 3.0
								},
								"trace": [
									0,
									-3
								],
								"shapes": [
									{
										"k": "circle",
										"o": [
											0,
											0
										],
										"r": 3,
										"c": "cyan"
									},
									{
										"k": "seg",
										"a": [
											0,
											0
										],
										"b": [
											0,
											-3
										],
										"c": "faint"
									},
									{
										"k": "seg",
										"a": [
											0,
											0
										],
										"b": [
											3,
											0
										],
										"c": "faint"
									},
									{
										"k": "seg",
										"a": [
											0,
											0
										],
										"b": [
											-3,
											0
										],
										"c": "faint"
									},
									{
										"k": "seg",
										"a": [
											0,
											0
										],
										"b": [
											0,
											3
										],
										"c": "faint"
									},
									{
										"k": "dot",
										"p": [
											0,
											-3
										],
										"s": "P",
										"off": [
											6,
											14
										]
									}
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "滾過的距離 = 轉過的弧長 = 半徑 × 轉過的弧度：",
							"template": "轉了 π/3 = [0]π",
							"ans": [
								"1/3"
							],
							"hint": "弧長 = rθ",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "P 從最低點繞圓心轉 π/3，離圓心的高度差是 −3 cos(π/3)。",
							"template": "P 離地 3 − 3 cos(π/3) = [0]",
							"ans": [
								"3/2"
							],
							"hint": "cos(π/3) = 1/2",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "滾 x 公尺就轉 x/3：",
							"template": "答：h(x) = [0] − 3 cos(x/[1])",
							"ans": [
								"3",
								"3"
							],
							"hint": "圓心離地 3",
							"part": "(2)"
						}
					]
				},
				{
					"stem": "半徑 4 公尺的輪子沿地面向右滾動（不打滑）。輪上一點 P 一開始碰著地面。\n(1) 輪子滾了 8π/3 公尺時，P 離地多高？(2) 滾了 x 公尺時，P 離地 h(x) = ？",
					"plot": {
						"x": [
							-4.6,
							12.7776
						],
						"y": [
							-0.6,
							8.6
						],
						"geo": true,
						"h": 150,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-4.6,
									0
								],
								"b": [
									12.7776,
									0
								],
								"c": "dim"
							}
						],
						"groups": [
							{
								"o": [
									0,
									4
								],
								"anim": {
									"k": "roll",
									"r": 4,
									"dist": 8.3776,
									"dur": 3.0
								},
								"trace": [
									0,
									-4
								],
								"shapes": [
									{
										"k": "circle",
										"o": [
											0,
											0
										],
										"r": 4,
										"c": "cyan"
									},
									{
										"k": "seg",
										"a": [
											0,
											0
										],
										"b": [
											0,
											-4
										],
										"c": "faint"
									},
									{
										"k": "seg",
										"a": [
											0,
											0
										],
										"b": [
											4,
											0
										],
										"c": "faint"
									},
									{
										"k": "seg",
										"a": [
											0,
											0
										],
										"b": [
											-4,
											0
										],
										"c": "faint"
									},
									{
										"k": "seg",
										"a": [
											0,
											0
										],
										"b": [
											0,
											4
										],
										"c": "faint"
									},
									{
										"k": "dot",
										"p": [
											0,
											-4
										],
										"s": "P",
										"off": [
											6,
											14
										]
									}
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "滾過的距離 = 轉過的弧長 = 半徑 × 轉過的弧度：",
							"template": "轉了 (8π/3)/4 = [0]π",
							"ans": [
								"2/3"
							],
							"hint": "弧長 = rθ",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "P 從最低點繞圓心轉 2π/3，離圓心的高度差是 −4 cos(2π/3)。",
							"template": "P 離地 4 − 4 cos(2π/3) = [0]",
							"ans": [
								"6"
							],
							"hint": "cos(2π/3) = −1/2",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "滾 x 公尺就轉 x/4：",
							"template": "答：h(x) = [0] − 4 cos(x/[1])",
							"ans": [
								"4",
								"4"
							],
							"hint": "圓心離地 4",
							"part": "(2)"
						}
					]
				}
			]
		},
		{
			"id": "tq_ferris",
			"kind": "quest",
			"tier": 2,
			"title": "摩天輪",
			"tmul": 1.2,
			"stem": "摩天輪直徑 60 公尺，最低點離地 10 公尺，逆時針等速轉動，12 分鐘一圈。小光從最低點上車，t 分鐘後離地 h(t) = a sin(bt + c) + d 公尺（a、b > 0，−π < c ≤ π）。\n(1) 求 a、b、c、d　(2) 一圈之中，有幾分鐘高於 55 公尺？",
			"plot": {
				"x": [
					-3.6,
					3.6
				],
				"y": [
					-0.3,
					7.4
				],
				"geo": true,
				"h": 180,
				"shapes": [
					{
						"k": "seg",
						"a": [
							-3.6,
							0
						],
						"b": [
							3.6,
							0
						],
						"c": "dim"
					},
					{
						"k": "seg",
						"a": [
							0,
							4
						],
						"b": [
							-1.6,
							0
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							0,
							4
						],
						"b": [
							1.6,
							0
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							-3.6,
							5.5
						],
						"b": [
							3.6,
							5.5
						],
						"c": "pink",
						"dash": true,
						"at": 3
					},
					{
						"k": "label",
						"p": [
							3.2,
							5.9
						],
						"s": "55",
						"c": "pink",
						"at": 3
					}
				],
				"groups": [
					{
						"o": [
							0,
							4
						],
						"anim": {
							"k": "spin",
							"period": 9.0,
							"dir": 1
						},
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 3,
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									0,
									-3
								],
								"b": [
									0,
									3
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-2.598,
									-1.5
								],
								"b": [
									2.598,
									1.5
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-2.598,
									1.5
								],
								"b": [
									2.598,
									-1.5
								],
								"c": "faint"
							},
							{
								"k": "dot",
								"p": [
									0,
									3
								],
								"c": "cyan"
							},
							{
								"k": "dot",
								"p": [
									2.598,
									1.5
								],
								"c": "cyan"
							},
							{
								"k": "dot",
								"p": [
									2.598,
									-1.5
								],
								"c": "cyan"
							},
							{
								"k": "dot",
								"p": [
									-2.598,
									1.5
								],
								"c": "cyan"
							},
							{
								"k": "dot",
								"p": [
									-2.598,
									-1.5
								],
								"c": "cyan"
							},
							{
								"k": "dot",
								"p": [
									0,
									-3
								],
								"c": "gold"
							}
						]
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "振幅是半徑，中線是圓心的高度：",
					"template": "a = [0]，d = [1]",
					"ans": [
						"30",
						"40"
					],
					"hint": "圓心離地 10 + 30",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "週期 12 分鐘：",
					"template": "b = 2π/12 = [0]π",
					"ans": [
						"1/6"
					],
					"hint": "化簡 2/12",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "t = 0 在最低點：sin c = −1。",
					"template": "c = [0]π",
					"ans": [
						"−1/2"
					],
					"hint": "−π < c ≤ π",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "一圈 0 ≤ t ≤ 12 裡，解出 t：",
					"template": "2π/3 < πt/6 < 4π/3 ⇒ [0] < t < [1]",
					"ans": [
						"4",
						"8"
					],
					"hint": "兩邊乘 6/π",
					"part": "(2)",
					"pre": "(2)　h(t) = 40 − 30 cos(πt/6) > 55 ⇒ cos(πt/6) < −1/2",
					"write": "答：每圈 4 分鐘高於 55 公尺"
				}
			],
			"vars": [
				{
					"stem": "摩天輪直徑 40 公尺，最低點離地 5 公尺，逆時針等速轉動，18 分鐘一圈。小光從最低點上車，t 分鐘後離地 h(t) = a sin(bt + c) + d 公尺（a、b > 0，−π < c ≤ π）。\n(1) 求 a、b、c、d　(2) 一圈之中，有幾分鐘高於 35 公尺？",
					"plot": {
						"x": [
							-3.6,
							3.6
						],
						"y": [
							-0.3,
							7.15
						],
						"geo": true,
						"h": 180,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-3.6,
									0
								],
								"b": [
									3.6,
									0
								],
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									0,
									3.75
								],
								"b": [
									-1.6,
									0
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									0,
									3.75
								],
								"b": [
									1.6,
									0
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-3.6,
									5.25
								],
								"b": [
									3.6,
									5.25
								],
								"c": "pink",
								"dash": true,
								"at": 3
							},
							{
								"k": "label",
								"p": [
									3.2,
									5.65
								],
								"s": "35",
								"c": "pink",
								"at": 3
							}
						],
						"groups": [
							{
								"o": [
									0,
									3.75
								],
								"anim": {
									"k": "spin",
									"period": 9.0,
									"dir": 1
								},
								"shapes": [
									{
										"k": "circle",
										"o": [
											0,
											0
										],
										"r": 3,
										"c": "cyan"
									},
									{
										"k": "seg",
										"a": [
											0,
											-3
										],
										"b": [
											0,
											3
										],
										"c": "faint"
									},
									{
										"k": "seg",
										"a": [
											-2.598,
											-1.5
										],
										"b": [
											2.598,
											1.5
										],
										"c": "faint"
									},
									{
										"k": "seg",
										"a": [
											-2.598,
											1.5
										],
										"b": [
											2.598,
											-1.5
										],
										"c": "faint"
									},
									{
										"k": "dot",
										"p": [
											0,
											3
										],
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											2.598,
											1.5
										],
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											2.598,
											-1.5
										],
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											-2.598,
											1.5
										],
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											-2.598,
											-1.5
										],
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											0,
											-3
										],
										"c": "gold"
									}
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "振幅是半徑，中線是圓心的高度：",
							"template": "a = [0]，d = [1]",
							"ans": [
								"20",
								"25"
							],
							"hint": "圓心離地 5 + 20",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "週期 18 分鐘：",
							"template": "b = 2π/18 = [0]π",
							"ans": [
								"1/9"
							],
							"hint": "化簡 2/18",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "t = 0 在最低點：sin c = −1。",
							"template": "c = [0]π",
							"ans": [
								"−1/2"
							],
							"hint": "−π < c ≤ π",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "一圈 0 ≤ t ≤ 18 裡，解出 t：",
							"template": "2π/3 < πt/9 < 4π/3 ⇒ [0] < t < [1]",
							"ans": [
								"6",
								"12"
							],
							"hint": "兩邊乘 9/π",
							"part": "(2)",
							"pre": "(2)　h(t) = 25 − 20 cos(πt/9) > 35 ⇒ cos(πt/9) < −1/2",
							"write": "答：每圈 6 分鐘高於 35 公尺"
						}
					]
				},
				{
					"stem": "摩天輪直徑 80 公尺，最低點離地 8 公尺，逆時針等速轉動，24 分鐘一圈。小光從最低點上車，t 分鐘後離地 h(t) = a sin(bt + c) + d 公尺（a、b > 0，−π < c ≤ π）。\n(1) 求 a、b、c、d　(2) 一圈之中，有幾分鐘高於 48 公尺？",
					"plot": {
						"x": [
							-3.6,
							3.6
						],
						"y": [
							-0.3,
							7
						],
						"geo": true,
						"h": 180,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-3.6,
									0
								],
								"b": [
									3.6,
									0
								],
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									0,
									3.6
								],
								"b": [
									-1.6,
									0
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									0,
									3.6
								],
								"b": [
									1.6,
									0
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-3.6,
									3.6
								],
								"b": [
									3.6,
									3.6
								],
								"c": "pink",
								"dash": true,
								"at": 3
							},
							{
								"k": "label",
								"p": [
									3.2,
									4
								],
								"s": "48",
								"c": "pink",
								"at": 3
							}
						],
						"groups": [
							{
								"o": [
									0,
									3.6
								],
								"anim": {
									"k": "spin",
									"period": 9.0,
									"dir": 1
								},
								"shapes": [
									{
										"k": "circle",
										"o": [
											0,
											0
										],
										"r": 3,
										"c": "cyan"
									},
									{
										"k": "seg",
										"a": [
											0,
											-3
										],
										"b": [
											0,
											3
										],
										"c": "faint"
									},
									{
										"k": "seg",
										"a": [
											-2.598,
											-1.5
										],
										"b": [
											2.598,
											1.5
										],
										"c": "faint"
									},
									{
										"k": "seg",
										"a": [
											-2.598,
											1.5
										],
										"b": [
											2.598,
											-1.5
										],
										"c": "faint"
									},
									{
										"k": "dot",
										"p": [
											0,
											3
										],
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											2.598,
											1.5
										],
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											2.598,
											-1.5
										],
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											-2.598,
											1.5
										],
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											-2.598,
											-1.5
										],
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											0,
											-3
										],
										"c": "gold"
									}
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "振幅是半徑，中線是圓心的高度：",
							"template": "a = [0]，d = [1]",
							"ans": [
								"40",
								"48"
							],
							"hint": "圓心離地 8 + 40",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "週期 24 分鐘：",
							"template": "b = 2π/24 = [0]π",
							"ans": [
								"1/12"
							],
							"hint": "化簡 2/24",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "t = 0 在最低點：sin c = −1。",
							"template": "c = [0]π",
							"ans": [
								"−1/2"
							],
							"hint": "−π < c ≤ π",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "一圈 0 ≤ t ≤ 24 裡，解出 t：",
							"template": "π/2 < πt/12 < 3π/2 ⇒ [0] < t < [1]",
							"ans": [
								"6",
								"18"
							],
							"hint": "兩邊乘 12/π",
							"part": "(2)",
							"pre": "(2)　h(t) = 48 − 40 cos(πt/12) > 48 ⇒ cos(πt/12) < 0",
							"write": "答：每圈 12 分鐘高於 48 公尺"
						}
					]
				}
			]
		},
		{
			"id": "tq_tide",
			"kind": "quest",
			"tier": 2,
			"title": "進港的時段",
			"tmul": 1.2,
			"stem": "港口水深 y = a sin(bx + c) + d（公尺，x 是時刻，a、b > 0、0 ≤ c < 2π）。x = 0、3、6、9、12 時，y = 5、8、5、2、5。\n水深 ≥ 6.5 時大船才能進港。一天（0 ≤ x ≤ 24）哪些時段可以進港？",
			"plot": {
				"x": [
					-0.8,
					24.8
				],
				"y": [
					0.8,
					9.5
				],
				"h": 175,
				"curves": [
					{
						"f": "3*sin(3.141592653589793/6*x+0.0)+5",
						"c": "cyan",
						"at": 2
					},
					{
						"f": "6.5",
						"c": "pink",
						"dash": true,
						"at": 2
					}
				],
				"pts": [
					{
						"x": 0,
						"y": 5,
						"label": ""
					},
					{
						"x": 3,
						"y": 8,
						"label": ""
					},
					{
						"x": 6,
						"y": 5,
						"label": ""
					},
					{
						"x": 9,
						"y": 2,
						"label": ""
					},
					{
						"x": 12,
						"y": 5,
						"label": ""
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "最高 8、最低 2，12 小時一個週期：",
					"template": "d = [0]，a = [1]，b = [2]π",
					"ans": [
						"5",
						"3",
						"1/6"
					],
					"hint": "b = 2π/12"
				},
				{
					"t": "fill",
					"q": "x = 0 時 y 在中線 5，接著往上升：",
					"template": "c = [0]",
					"ans": [
						"0"
					],
					"hint": "sin c = 0，而且要是上升的那一點"
				},
				{
					"t": "fill",
					"q": "sin u ≥ 1/2 在 π/6 ≤ u ≤ 5π/6（再加 2π 的倍數）：",
					"template": "π/6 ≤ πx/6 ≤ 5π/6 ⇒ [0] ≤ x ≤ [1]",
					"ans": [
						"1",
						"5"
					],
					"hint": "兩邊乘 6/π",
					"pre": "3 sin(πx/6) + 5 ≥ 6.5 ⇒ sin(πx/6) ≥ 1/2"
				},
				{
					"t": "line",
					"q": "加一個週期 12，封印一天之中可以進港的時段。",
					"row": "進港",
					"marks": [
						"1",
						"5",
						"13",
						"17"
					],
					"seg": [
						0,
						1,
						0,
						1,
						0
					],
					"pt": [
						1,
						1,
						1,
						1
					],
					"write": "答：1 ≤ x ≤ 5 或 13 ≤ x ≤ 17"
				}
			],
			"vars": [
				{
					"stem": "港口水深 y = a sin(bx + c) + d（公尺，x 是時刻，a、b > 0、0 ≤ c < 2π）。x = 0、3、6、9、12 時，y = 4、1、4、7、4。\n水深 ≥ 5.5 時大船才能進港。一天（0 ≤ x ≤ 24）哪些時段可以進港？",
					"plot": {
						"x": [
							-0.8,
							24.8
						],
						"y": [
							-0.2,
							8.5
						],
						"h": 175,
						"curves": [
							{
								"f": "3*sin(3.141592653589793/6*x+3.141592653589793)+4",
								"c": "cyan",
								"at": 2
							},
							{
								"f": "5.5",
								"c": "pink",
								"dash": true,
								"at": 2
							}
						],
						"pts": [
							{
								"x": 0,
								"y": 4,
								"label": ""
							},
							{
								"x": 3,
								"y": 1,
								"label": ""
							},
							{
								"x": 6,
								"y": 4,
								"label": ""
							},
							{
								"x": 9,
								"y": 7,
								"label": ""
							},
							{
								"x": 12,
								"y": 4,
								"label": ""
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "最高 7、最低 1，12 小時一個週期：",
							"template": "d = [0]，a = [1]，b = [2]π",
							"ans": [
								"4",
								"3",
								"1/6"
							],
							"hint": "b = 2π/12"
						},
						{
							"t": "fill",
							"q": "x = 0 時 y 在中線 4，接著往下降：",
							"template": "c = [0]π",
							"ans": [
								"1"
							],
							"hint": "sin c = 0，而且要是下降的那一點"
						},
						{
							"t": "fill",
							"q": "sin u ≥ 1/2 在 π/6 ≤ u ≤ 5π/6（再加 2π 的倍數）。u 從 π 開始，第一段是 13π/6 到 17π/6：",
							"template": "13π/6 ≤ πx/6 + π ≤ 17π/6 ⇒ [0] ≤ x ≤ [1]",
							"ans": [
								"7",
								"11"
							],
							"hint": "兩邊乘 6/π",
							"pre": "3 sin(πx/6 + π) + 4 ≥ 5.5 ⇒ sin(πx/6 + π) ≥ 1/2"
						},
						{
							"t": "line",
							"q": "加一個週期 12，封印一天之中可以進港的時段。",
							"row": "進港",
							"marks": [
								"7",
								"11",
								"19",
								"23"
							],
							"seg": [
								0,
								1,
								0,
								1,
								0
							],
							"pt": [
								1,
								1,
								1,
								1
							],
							"write": "答：7 ≤ x ≤ 11 或 19 ≤ x ≤ 23"
						}
					]
				},
				{
					"stem": "港口水深 y = a sin(bx + c) + d（公尺，x 是時刻，a、b > 0、0 ≤ c < 2π）。x = 0、3、6、9、12 時，y = 8、5、2、5、8。\n水深 ≥ 6.5 時大船才能進港。一天（0 ≤ x ≤ 24）哪些時段可以進港？",
					"plot": {
						"x": [
							-0.8,
							24.8
						],
						"y": [
							0.8,
							9.5
						],
						"h": 175,
						"curves": [
							{
								"f": "3*sin(3.141592653589793/6*x+1.5707963267948966)+5",
								"c": "cyan",
								"at": 2
							},
							{
								"f": "6.5",
								"c": "pink",
								"dash": true,
								"at": 2
							}
						],
						"pts": [
							{
								"x": 0,
								"y": 8,
								"label": ""
							},
							{
								"x": 3,
								"y": 5,
								"label": ""
							},
							{
								"x": 6,
								"y": 2,
								"label": ""
							},
							{
								"x": 9,
								"y": 5,
								"label": ""
							},
							{
								"x": 12,
								"y": 8,
								"label": ""
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "最高 8、最低 2，12 小時一個週期：",
							"template": "d = [0]，a = [1]，b = [2]π",
							"ans": [
								"5",
								"3",
								"1/6"
							],
							"hint": "b = 2π/12"
						},
						{
							"t": "fill",
							"q": "x = 0 時 y 是最高 8：",
							"template": "c = [0]π",
							"ans": [
								"1/2"
							],
							"hint": "sin c = 1"
						},
						{
							"t": "fill",
							"q": "sin u ≥ 1/2 在 π/6 ≤ u ≤ 5π/6（再加 2π 的倍數）：",
							"template": "π/6 ≤ πx/6 + π/2 ≤ 5π/6 ⇒ [0] ≤ x ≤ [1]",
							"ans": [
								"−2",
								"2"
							],
							"hint": "兩邊乘 6/π",
							"pre": "3 sin(πx/6 + π/2) + 5 ≥ 6.5 ⇒ sin(πx/6 + π/2) ≥ 1/2"
						},
						{
							"t": "line",
							"q": "加上週期 12 的倍數，只留 0 到 24 的部分，封印可以進港的時段。",
							"row": "進港",
							"marks": [
								"2",
								"10",
								"14",
								"22"
							],
							"seg": [
								1,
								0,
								1,
								0,
								1
							],
							"pt": [
								1,
								1,
								1,
								1
							],
							"write": "答：0 ≤ x ≤ 2、10 ≤ x ≤ 14 或 22 ≤ x ≤ 24"
						}
					]
				}
			]
		},
		{
			"id": "tq_light",
			"kind": "quest",
			"tier": 2,
			"title": "自動窗簾",
			"tmul": 1.15,
			"stem": "窗邊照度 I(t) = 500 + 300 sin(π/12 · (t − 8))，0 ≤ t < 24（時）。I(t) ≥ 650 時窗簾半閉。\n(1) 晴天從幾點半閉到幾點？(2) 陰天 I(t) = 500 + 150 sin(π/12 · (t − 8))，會怎樣？",
			"plot": {
				"x": [
					-0.5,
					24.5
				],
				"y": [
					1.5,
					8.8
				],
				"h": 175,
				"curves": [
					{
						"f": "5.0+3.0*sin(3.141592653589793/12*(x-8))",
						"c": "cyan"
					},
					{
						"f": "6.5",
						"c": "pink",
						"dash": true
					},
					{
						"f": "5.0+1.5*sin(3.141592653589793/12*(x-8))",
						"c": "lime",
						"dash": true,
						"at": 2
					}
				],
				"pts": [
					{
						"x": 10,
						"y": 6.5,
						"label": "",
						"at": 1
					},
					{
						"x": 18,
						"y": 6.5,
						"label": "",
						"at": 1
					},
					{
						"x": 14,
						"y": 6.5,
						"label": "",
						"at": 2
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "500 + 300 sin(…) ≥ 650：",
					"template": "sin(π/12 · (t − 8)) ≥ [0]",
					"ans": [
						"1/2"
					],
					"hint": "150/300",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "π/6 ≤ π/12 · (t − 8) ≤ 5π/6：",
					"template": "[0] ≤ t ≤ [1]",
					"ans": [
						"10",
						"18"
					],
					"hint": "2 ≤ t − 8 ≤ 10",
					"part": "(1)"
				},
				{
					"t": "choice",
					"q": "陰天要 150 sin(…) ≥ 150，也就是 sin(…) ≥ 1：",
					"opts": [
						"只在 14 點那一瞬間半閉",
						"10 點到 18 點都半閉",
						"12 點到 16 點半閉",
						"整天都不會半閉"
					],
					"hint": "sin 等於 1 只有一個時刻：π/12 · (t − 8) = π/2",
					"write": "答：(1) 10 點到 18 點　(2) 只在 14 點那一瞬間",
					"part": "(2)"
				}
			],
			"vars": [
				{
					"stem": "窗邊照度 I(t) = 500 + 300 sin(π/12 · (t − 6))，0 ≤ t < 24（時）。I(t) ≥ 650 時窗簾半閉。\n(1) 晴天從幾點半閉到幾點？(2) 陰天 I(t) = 500 + 150 sin(π/12 · (t − 6))，會怎樣？",
					"plot": {
						"x": [
							-0.5,
							24.5
						],
						"y": [
							1.5,
							8.8
						],
						"h": 175,
						"curves": [
							{
								"f": "5.0+3.0*sin(3.141592653589793/12*(x-6))",
								"c": "cyan"
							},
							{
								"f": "6.5",
								"c": "pink",
								"dash": true
							},
							{
								"f": "5.0+1.5*sin(3.141592653589793/12*(x-6))",
								"c": "lime",
								"dash": true,
								"at": 2
							}
						],
						"pts": [
							{
								"x": 8,
								"y": 6.5,
								"label": "",
								"at": 1
							},
							{
								"x": 16,
								"y": 6.5,
								"label": "",
								"at": 1
							},
							{
								"x": 12,
								"y": 6.5,
								"label": "",
								"at": 2
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "500 + 300 sin(…) ≥ 650：",
							"template": "sin(π/12 · (t − 6)) ≥ [0]",
							"ans": [
								"1/2"
							],
							"hint": "150/300",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "π/6 ≤ π/12 · (t − 6) ≤ 5π/6：",
							"template": "[0] ≤ t ≤ [1]",
							"ans": [
								"8",
								"16"
							],
							"hint": "2 ≤ t − 6 ≤ 10",
							"part": "(1)"
						},
						{
							"t": "choice",
							"q": "陰天要 150 sin(…) ≥ 150，也就是 sin(…) ≥ 1：",
							"opts": [
								"只在 12 點那一瞬間半閉",
								"8 點到 16 點都半閉",
								"10 點到 14 點半閉",
								"整天都不會半閉"
							],
							"hint": "sin 等於 1 只有一個時刻：π/12 · (t − 6) = π/2",
							"write": "答：(1) 8 點到 16 點　(2) 只在 12 點那一瞬間",
							"part": "(2)"
						}
					]
				},
				{
					"stem": "窗邊照度 I(t) = 400 + 200 sin(π/12 · (t − 7))，0 ≤ t < 24（時）。I(t) ≥ 500 時窗簾半閉。\n(1) 晴天從幾點半閉到幾點？(2) 陰天 I(t) = 400 + 100 sin(π/12 · (t − 7))，會怎樣？",
					"plot": {
						"x": [
							-0.5,
							24.5
						],
						"y": [
							1.5,
							6.8
						],
						"h": 175,
						"curves": [
							{
								"f": "4.0+2.0*sin(3.141592653589793/12*(x-7))",
								"c": "cyan"
							},
							{
								"f": "5.0",
								"c": "pink",
								"dash": true
							},
							{
								"f": "4.0+1.0*sin(3.141592653589793/12*(x-7))",
								"c": "lime",
								"dash": true,
								"at": 2
							}
						],
						"pts": [
							{
								"x": 9,
								"y": 5,
								"label": "",
								"at": 1
							},
							{
								"x": 17,
								"y": 5,
								"label": "",
								"at": 1
							},
							{
								"x": 13,
								"y": 5,
								"label": "",
								"at": 2
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "400 + 200 sin(…) ≥ 500：",
							"template": "sin(π/12 · (t − 7)) ≥ [0]",
							"ans": [
								"1/2"
							],
							"hint": "100/200",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "π/6 ≤ π/12 · (t − 7) ≤ 5π/6：",
							"template": "[0] ≤ t ≤ [1]",
							"ans": [
								"9",
								"17"
							],
							"hint": "2 ≤ t − 7 ≤ 10",
							"part": "(1)"
						},
						{
							"t": "choice",
							"q": "陰天要 100 sin(…) ≥ 100，也就是 sin(…) ≥ 1：",
							"opts": [
								"只在 13 點那一瞬間半閉",
								"9 點到 17 點都半閉",
								"11 點到 15 點半閉",
								"整天都不會半閉"
							],
							"hint": "sin 等於 1 只有一個時刻：π/12 · (t − 7) = π/2",
							"write": "答：(1) 9 點到 17 點　(2) 只在 13 點那一瞬間",
							"part": "(2)"
						}
					]
				}
			]
		},
		{
			"id": "tq_slope",
			"kind": "quest",
			"tier": 1,
			"title": "溜滑梯的坡度",
			"tmul": 1.05,
			"stem": "舊溜滑梯的坡道和地面夾角 θ，坡度 tan θ = 3/4。新溜滑梯的夾角是 θ/2，坡道一樣長 10 公尺。\n(1) 新的坡度 tan(θ/2) 是多少？(2) 新坡道的頂端多高？",
			"plot": {
				"x": [
					-0.6,
					4.6
				],
				"y": [
					-0.6,
					3.4
				],
				"geo": true,
				"h": 170,
				"shapes": [
					{
						"k": "poly",
						"pts": [
							[
								0,
								0
							],
							[
								4,
								0
							],
							[
								4,
								3
							]
						],
						"c": "cyan"
					},
					{
						"k": "right",
						"p": [
							4,
							0
						],
						"u": [
							-1,
							0
						],
						"v": [
							0,
							1
						]
					},
					{
						"k": "angle",
						"o": [
							0,
							0
						],
						"a0": 0,
						"a1": 36.8699,
						"r": 30,
						"s": "θ"
					},
					{
						"k": "seg",
						"a": [
							0,
							0
						],
						"b": [
							4,
							1.3333
						],
						"c": "gold",
						"dash": true,
						"at": 1
					},
					{
						"k": "label",
						"p": [
							2,
							-0.35
						],
						"s": "4"
					},
					{
						"k": "label",
						"p": [
							4.3,
							1.5
						],
						"s": "3"
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "直角三角形 3、4、5：",
					"template": "sin θ = [0]，cos θ = [1]",
					"ans": [
						"3/5",
						"4/5"
					],
					"hint": "斜邊 5",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "以切表弦：",
					"template": "tan(θ/2) = (1 − cos θ)/sin θ = (1/5)/(3/5) = [0]",
					"ans": [
						"1/3"
					],
					"hint": "分母一樣是 5",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "半角公式：",
					"template": "sin^{2}(θ/2) = (1 − cos θ)/2 = [0]",
					"ans": [
						"1/10"
					],
					"hint": "(1/5)/2",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "θ/2 是銳角，sin(θ/2) = √{1/10}：",
					"template": "答：高 = 10 sin(θ/2) = 10/√{10} = [0]",
					"ans": [
						"√10"
					],
					"hint": "10/√{10} 有理化",
					"part": "(2)"
				}
			],
			"vars": [
				{
					"stem": "舊溜滑梯的坡道和地面夾角 θ，坡度 tan θ = 5/12。新溜滑梯的夾角是 θ/2，坡道一樣長 13 公尺。\n(1) 新的坡度 tan(θ/2) 是多少？(2) 新坡道的頂端多高？",
					"plot": {
						"x": [
							-0.6,
							4.6
						],
						"y": [
							-0.6,
							2.0667
						],
						"geo": true,
						"h": 170,
						"shapes": [
							{
								"k": "poly",
								"pts": [
									[
										0,
										0
									],
									[
										4,
										0
									],
									[
										4,
										1.6667
									]
								],
								"c": "cyan"
							},
							{
								"k": "right",
								"p": [
									4,
									0
								],
								"u": [
									-1,
									0
								],
								"v": [
									0,
									1
								]
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 0,
								"a1": 22.6199,
								"r": 30,
								"s": "θ"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									4,
									0.8
								],
								"c": "gold",
								"dash": true,
								"at": 1
							},
							{
								"k": "label",
								"p": [
									2,
									-0.35
								],
								"s": "12"
							},
							{
								"k": "label",
								"p": [
									4.3,
									0.8333
								],
								"s": "5"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "直角三角形 5、12、13：",
							"template": "sin θ = [0]，cos θ = [1]",
							"ans": [
								"5/13",
								"12/13"
							],
							"hint": "斜邊 13",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "以切表弦：",
							"template": "tan(θ/2) = (1 − cos θ)/sin θ = (1/13)/(5/13) = [0]",
							"ans": [
								"1/5"
							],
							"hint": "分母一樣是 13",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "半角公式：",
							"template": "sin^{2}(θ/2) = (1 − cos θ)/2 = [0]",
							"ans": [
								"1/26"
							],
							"hint": "(1/13)/2",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "θ/2 是銳角，sin(θ/2) = √{1/26}：",
							"template": "答：高 = 13 sin(θ/2) = 13/√{26} = [0]",
							"ans": [
								"√26/2"
							],
							"hint": "13/√{26} 有理化",
							"part": "(2)"
						}
					]
				},
				{
					"stem": "舊溜滑梯的坡道和地面夾角 θ，坡度 tan θ = 8/15。新溜滑梯的夾角是 θ/2，坡道一樣長 17 公尺。\n(1) 新的坡度 tan(θ/2) 是多少？(2) 新坡道的頂端多高？",
					"plot": {
						"x": [
							-0.6,
							4.6
						],
						"y": [
							-0.6,
							2.5333
						],
						"geo": true,
						"h": 170,
						"shapes": [
							{
								"k": "poly",
								"pts": [
									[
										0,
										0
									],
									[
										4,
										0
									],
									[
										4,
										2.1333
									]
								],
								"c": "cyan"
							},
							{
								"k": "right",
								"p": [
									4,
									0
								],
								"u": [
									-1,
									0
								],
								"v": [
									0,
									1
								]
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 0,
								"a1": 28.0725,
								"r": 30,
								"s": "θ"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									4,
									1
								],
								"c": "gold",
								"dash": true,
								"at": 1
							},
							{
								"k": "label",
								"p": [
									2,
									-0.35
								],
								"s": "15"
							},
							{
								"k": "label",
								"p": [
									4.3,
									1.0667
								],
								"s": "8"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "直角三角形 8、15、17：",
							"template": "sin θ = [0]，cos θ = [1]",
							"ans": [
								"8/17",
								"15/17"
							],
							"hint": "斜邊 17",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "以切表弦：",
							"template": "tan(θ/2) = (1 − cos θ)/sin θ = (2/17)/(8/17) = [0]",
							"ans": [
								"1/4"
							],
							"hint": "分母一樣是 17",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "半角公式：",
							"template": "sin^{2}(θ/2) = (1 − cos θ)/2 = [0]",
							"ans": [
								"1/17"
							],
							"hint": "(2/17)/2",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "θ/2 是銳角，sin(θ/2) = √{1/17}：",
							"template": "答：高 = 17 sin(θ/2) = 17/√{17} = [0]",
							"ans": [
								"√17"
							],
							"hint": "17/√{17} 有理化",
							"part": "(2)"
						}
					]
				}
			]
		},
		{
			"id": "tq_mount",
			"kind": "quest",
			"tier": 3,
			"title": "測山高",
			"tmul": 1.35,
			"stem": "在 A 點測得山頂 D 的仰角是 θ。朝山腳 C 直走 100 公尺到 B，仰角變成 2θ，再走 40 公尺剛好到山腳 C（\\ol{DC} 垂直地面）。求山高 \\ol{CD} 與 cos 2θ。",
			"plot": {
				"x": [
					-0.8,
					15.0
				],
				"y": [
					-1.0,
					10.0652
				],
				"geo": true,
				"h": 180,
				"shapes": [
					{
						"k": "seg",
						"a": [
							-0.6,
							0
						],
						"b": [
							14.8,
							0
						],
						"c": "dim"
					},
					{
						"k": "seg",
						"a": [
							0,
							0
						],
						"b": [
							14,
							9.1652
						],
						"c": "cyan"
					},
					{
						"k": "seg",
						"a": [
							10,
							0
						],
						"b": [
							14,
							9.1652
						],
						"c": "cyan"
					},
					{
						"k": "seg",
						"a": [
							14,
							0
						],
						"b": [
							14,
							9.1652
						],
						"c": "cyan"
					},
					{
						"k": "right",
						"p": [
							14,
							0
						],
						"u": [
							-1,
							0
						],
						"v": [
							0,
							1
						]
					},
					{
						"k": "angle",
						"o": [
							0,
							0
						],
						"a0": 0,
						"a1": 33.2109,
						"r": 30,
						"s": "θ"
					},
					{
						"k": "angle",
						"o": [
							10,
							0
						],
						"a0": 0,
						"a1": 66.4218,
						"r": 16,
						"s": "2θ"
					},
					{
						"k": "label",
						"p": [
							0,
							-0.6
						],
						"s": "A"
					},
					{
						"k": "label",
						"p": [
							10,
							-0.6
						],
						"s": "B"
					},
					{
						"k": "label",
						"p": [
							14.4,
							-0.6
						],
						"s": "C"
					},
					{
						"k": "label",
						"p": [
							14,
							9.7152
						],
						"s": "D"
					},
					{
						"k": "label",
						"p": [
							5,
							-0.6
						],
						"s": "100"
					},
					{
						"k": "label",
						"p": [
							12,
							-0.6
						],
						"s": "40"
					}
				]
			},
			"steps": [
				{
					"t": "choice",
					"q": "∠DBC = 2θ 是 △ABD 的外角，等於兩個內對角的和。∠ADB 是多少？",
					"opts": [
						"θ",
						"2θ",
						"90° − θ",
						"180° − 3θ"
					],
					"hint": "2θ = ∠DAB + ∠ADB = θ + ∠ADB",
					"write": "∠ADB = 2θ − θ = θ ⇒ △ABD 是等腰三角形"
				},
				{
					"t": "fill",
					"q": "∠DAB = ∠ADB = θ，等角對等邊：",
					"template": "\\ol{BD} = \\ol{AB} = [0]",
					"ans": [
						"100"
					],
					"hint": "等腰三角形"
				},
				{
					"t": "fill",
					"q": "直角 △BCD，畢氏定理：",
					"template": "\\ol{CD}^{2} = 100^{2} − 40^{2} = [0]",
					"ans": [
						"8400"
					],
					"hint": "10000 − 1600"
				},
				{
					"t": "fill",
					"q": "開根號：",
					"template": "\\ol{CD} = √{8400} = [0]",
					"ans": [
						"20√21"
					],
					"hint": "8400 = 400 × 21"
				},
				{
					"t": "fill",
					"q": "直角 △BCD 中 ∠DBC = 2θ：",
					"template": "答：cos 2θ = \\ol{BC}/\\ol{BD} = [0]",
					"ans": [
						"2/5"
					],
					"hint": "40/100"
				}
			],
			"vars": [
				{
					"stem": "在 A 點測得山頂 D 的仰角是 θ。朝山腳 C 直走 50 公尺到 B，仰角變成 2θ，再走 30 公尺剛好到山腳 C（\\ol{DC} 垂直地面）。求山高 \\ol{CD} 與 cos 2θ。",
					"plot": {
						"x": [
							-0.8,
							15.0
						],
						"y": [
							-1.0,
							7.9
						],
						"geo": true,
						"h": 180,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-0.6,
									0
								],
								"b": [
									14.8,
									0
								],
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									14,
									7
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									8.75,
									0
								],
								"b": [
									14,
									7
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									14,
									0
								],
								"b": [
									14,
									7
								],
								"c": "cyan"
							},
							{
								"k": "right",
								"p": [
									14,
									0
								],
								"u": [
									-1,
									0
								],
								"v": [
									0,
									1
								]
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 0,
								"a1": 26.5651,
								"r": 30,
								"s": "θ"
							},
							{
								"k": "angle",
								"o": [
									8.75,
									0
								],
								"a0": 0,
								"a1": 53.1301,
								"r": 16,
								"s": "2θ"
							},
							{
								"k": "label",
								"p": [
									0,
									-0.6
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									8.75,
									-0.6
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									14.4,
									-0.6
								],
								"s": "C"
							},
							{
								"k": "label",
								"p": [
									14,
									7.55
								],
								"s": "D"
							},
							{
								"k": "label",
								"p": [
									4.375,
									-0.6
								],
								"s": "50"
							},
							{
								"k": "label",
								"p": [
									11.375,
									-0.6
								],
								"s": "30"
							}
						]
					},
					"steps": [
						{
							"t": "choice",
							"q": "∠DBC = 2θ 是 △ABD 的外角，等於兩個內對角的和。∠ADB 是多少？",
							"opts": [
								"θ",
								"2θ",
								"90° − θ",
								"180° − 3θ"
							],
							"hint": "2θ = ∠DAB + ∠ADB = θ + ∠ADB",
							"write": "∠ADB = 2θ − θ = θ ⇒ △ABD 是等腰三角形"
						},
						{
							"t": "fill",
							"q": "∠DAB = ∠ADB = θ，等角對等邊：",
							"template": "\\ol{BD} = \\ol{AB} = [0]",
							"ans": [
								"50"
							],
							"hint": "等腰三角形"
						},
						{
							"t": "fill",
							"q": "直角 △BCD，畢氏定理：",
							"template": "\\ol{CD}^{2} = 50^{2} − 30^{2} = [0]",
							"ans": [
								"1600"
							],
							"hint": "2500 − 900"
						},
						{
							"t": "fill",
							"q": "開根號：",
							"template": "\\ol{CD} = √{1600} = [0]",
							"ans": [
								"40"
							],
							"hint": "1600 = 40^{2}"
						},
						{
							"t": "fill",
							"q": "直角 △BCD 中 ∠DBC = 2θ：",
							"template": "答：cos 2θ = \\ol{BC}/\\ol{BD} = [0]",
							"ans": [
								"3/5"
							],
							"hint": "30/50"
						}
					]
				},
				{
					"stem": "在 A 點測得山頂 D 的仰角是 θ。朝山腳 C 直走 65 公尺到 B，仰角變成 2θ，再走 25 公尺剛好到山腳 C（\\ol{DC} 垂直地面）。求山高 \\ol{CD} 與 cos 2θ。",
					"plot": {
						"x": [
							-0.8,
							15.0
						],
						"y": [
							-1.0,
							10.2333
						],
						"geo": true,
						"h": 180,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-0.6,
									0
								],
								"b": [
									14.8,
									0
								],
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									14,
									9.3333
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									10.1111,
									0
								],
								"b": [
									14,
									9.3333
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									14,
									0
								],
								"b": [
									14,
									9.3333
								],
								"c": "cyan"
							},
							{
								"k": "right",
								"p": [
									14,
									0
								],
								"u": [
									-1,
									0
								],
								"v": [
									0,
									1
								]
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 0,
								"a1": 33.6901,
								"r": 30,
								"s": "θ"
							},
							{
								"k": "angle",
								"o": [
									10.1111,
									0
								],
								"a0": 0,
								"a1": 67.3801,
								"r": 16,
								"s": "2θ"
							},
							{
								"k": "label",
								"p": [
									0,
									-0.6
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									10.1111,
									-0.6
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									14.4,
									-0.6
								],
								"s": "C"
							},
							{
								"k": "label",
								"p": [
									14,
									9.8833
								],
								"s": "D"
							},
							{
								"k": "label",
								"p": [
									5.0556,
									-0.6
								],
								"s": "65"
							},
							{
								"k": "label",
								"p": [
									12.0556,
									-0.6
								],
								"s": "25"
							}
						]
					},
					"steps": [
						{
							"t": "choice",
							"q": "∠DBC = 2θ 是 △ABD 的外角，等於兩個內對角的和。∠ADB 是多少？",
							"opts": [
								"θ",
								"2θ",
								"90° − θ",
								"180° − 3θ"
							],
							"hint": "2θ = ∠DAB + ∠ADB = θ + ∠ADB",
							"write": "∠ADB = 2θ − θ = θ ⇒ △ABD 是等腰三角形"
						},
						{
							"t": "fill",
							"q": "∠DAB = ∠ADB = θ，等角對等邊：",
							"template": "\\ol{BD} = \\ol{AB} = [0]",
							"ans": [
								"65"
							],
							"hint": "等腰三角形"
						},
						{
							"t": "fill",
							"q": "直角 △BCD，畢氏定理：",
							"template": "\\ol{CD}^{2} = 65^{2} − 25^{2} = [0]",
							"ans": [
								"3600"
							],
							"hint": "4225 − 625"
						},
						{
							"t": "fill",
							"q": "開根號：",
							"template": "\\ol{CD} = √{3600} = [0]",
							"ans": [
								"60"
							],
							"hint": "3600 = 60^{2}"
						},
						{
							"t": "fill",
							"q": "直角 △BCD 中 ∠DBC = 2θ：",
							"template": "答：cos 2θ = \\ol{BC}/\\ol{BD} = [0]",
							"ans": [
								"5/13"
							],
							"hint": "25/65"
						}
					]
				}
			]
		},
		{
			"id": "tb_gun",
			"kind": "boss",
			"tier": 2,
			"title": "兩座砲台",
			"tmul": 1.65,
			"stem": "砲台 A 在砲台 B 的正東方 14 公里。A 向西偏北 θ、B 向東偏北 θ 發射，同時命中離兩砲台都是 18 公里的目標 P。接著 A 改向西偏北 θ/2 發射，落在 12 公里外的 Q 點。\n(1) 求 cos θ　(2) 求 cos(θ/2)　(3) 求 \\ol{BQ}",
			"plot": {
				"x": [
					-1.99,
					15.99
				],
				"y": [
					-1.99,
					18.5731
				],
				"geo": true,
				"h": 210,
				"shapes": [
					{
						"k": "seg",
						"a": [
							0,
							0
						],
						"b": [
							14,
							0
						],
						"c": "dim"
					},
					{
						"k": "seg",
						"a": [
							0,
							0
						],
						"b": [
							7,
							16.5831
						],
						"c": "cyan"
					},
					{
						"k": "seg",
						"a": [
							14,
							0
						],
						"b": [
							7,
							16.5831
						],
						"c": "cyan"
					},
					{
						"k": "seg",
						"a": [
							7,
							16.5831
						],
						"b": [
							7,
							0
						],
						"c": "faint",
						"dash": true
					},
					{
						"k": "angle",
						"o": [
							14,
							0
						],
						"a0": 112.8854,
						"a1": 180,
						"r": 26,
						"s": "θ"
					},
					{
						"k": "angle",
						"o": [
							0,
							0
						],
						"a0": 0,
						"a1": 67.1146,
						"r": 22,
						"s": "θ"
					},
					{
						"k": "seg",
						"a": [
							14,
							0
						],
						"b": [
							4,
							6.6332
						],
						"c": "pink",
						"dash": true,
						"at": 1
					},
					{
						"k": "seg",
						"a": [
							0,
							0
						],
						"b": [
							4,
							6.6332
						],
						"c": "gold",
						"w": 2.6,
						"at": 3
					},
					{
						"k": "label",
						"p": [
							-0.796,
							-1.194
						],
						"s": "B"
					},
					{
						"k": "label",
						"p": [
							14.796,
							-1.194
						],
						"s": "A"
					},
					{
						"k": "label",
						"p": [
							7,
							17.7771
						],
						"s": "P"
					},
					{
						"k": "label",
						"p": [
							7,
							-1.194
						],
						"s": "7"
					},
					{
						"k": "dot",
						"p": [
							4,
							6.6332
						],
						"s": "Q",
						"off": [
							-18,
							-6
						],
						"at": 1
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "\\ol{PA} = \\ol{PB}：P 往 \\ol{AB} 的垂線落在中點，切出直角三角形（鄰邊 7、斜邊 18）。",
					"template": "(1)　cos θ = [0]",
					"ans": [
						"7/18"
					],
					"hint": "cos = 鄰邊/斜邊",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "θ 是銳角，半角公式 cos(θ/2) = √{(1 + cos θ)/2}，先算根號裡面：",
					"template": "(2)　(1 + cos θ)/2 = (25/18)/2 = [0]",
					"ans": [
						"25/36"
					],
					"hint": "1 + 7/18 = 25/18",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "開根號：",
					"template": "cos(θ/2) = √{25/36} = [0]",
					"ans": [
						"5/6"
					],
					"hint": "25、36 都是平方數",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "△ABQ 中 \\ol{AB} = 14、\\ol{AQ} = 12、∠BAQ = θ/2。餘弦定理的最後一項：",
					"template": "(3)　2 · 14 · 12 · cos(θ/2) = [0]",
					"ans": [
						"280"
					],
					"hint": "336 × 5/6",
					"part": "(3)"
				},
				{
					"t": "fill",
					"q": "代進餘弦定理：",
					"template": "\\ol{BQ}^{2} = 14^{2} + 12^{2} − 280 = [0]",
					"ans": [
						"60"
					],
					"hint": "196 + 144 − 280",
					"part": "(3)"
				},
				{
					"t": "fill",
					"q": "開根號：",
					"template": "答：\\ol{BQ} = √{60} = [0]",
					"ans": [
						"2√15"
					],
					"hint": "60 = 4 × 15",
					"part": "(3)"
				}
			],
			"vars": [
				{
					"stem": "砲台 A 在砲台 B 的正東方 14 公里。A 向西偏北 θ、B 向東偏北 θ 發射，同時命中離兩砲台都是 25 公里的目標 P。接著 A 改向西偏北 θ/2 發射，落在 10 公里外的 Q 點。\n(1) 求 cos θ　(2) 求 cos(θ/2)　(3) 求 \\ol{BQ}",
					"plot": {
						"x": [
							-2.88,
							16.88
						],
						"y": [
							-2.88,
							26.88
						],
						"geo": true,
						"h": 210,
						"shapes": [
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									14,
									0
								],
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									7,
									24
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									14,
									0
								],
								"b": [
									7,
									24
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									7,
									24
								],
								"b": [
									7,
									0
								],
								"c": "faint",
								"dash": true
							},
							{
								"k": "angle",
								"o": [
									14,
									0
								],
								"a0": 106.2602,
								"a1": 180,
								"r": 26,
								"s": "θ"
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 0,
								"a1": 73.7398,
								"r": 22,
								"s": "θ"
							},
							{
								"k": "seg",
								"a": [
									14,
									0
								],
								"b": [
									6,
									6
								],
								"c": "pink",
								"dash": true,
								"at": 1
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									6,
									6
								],
								"c": "gold",
								"w": 2.6,
								"at": 3
							},
							{
								"k": "label",
								"p": [
									-1.152,
									-1.728
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									15.152,
									-1.728
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									7,
									25.728
								],
								"s": "P"
							},
							{
								"k": "label",
								"p": [
									7,
									-1.728
								],
								"s": "7"
							},
							{
								"k": "dot",
								"p": [
									6,
									6
								],
								"s": "Q",
								"off": [
									-18,
									-6
								],
								"at": 1
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "\\ol{PA} = \\ol{PB}：P 往 \\ol{AB} 的垂線落在中點，切出直角三角形（鄰邊 7、斜邊 25）。",
							"template": "(1)　cos θ = [0]",
							"ans": [
								"7/25"
							],
							"hint": "cos = 鄰邊/斜邊",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "θ 是銳角，半角公式 cos(θ/2) = √{(1 + cos θ)/2}，先算根號裡面：",
							"template": "(2)　(1 + cos θ)/2 = (32/25)/2 = [0]",
							"ans": [
								"16/25"
							],
							"hint": "1 + 7/25 = 32/25",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "開根號：",
							"template": "cos(θ/2) = √{16/25} = [0]",
							"ans": [
								"4/5"
							],
							"hint": "16、25 都是平方數",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "△ABQ 中 \\ol{AB} = 14、\\ol{AQ} = 10、∠BAQ = θ/2。餘弦定理的最後一項：",
							"template": "(3)　2 · 14 · 10 · cos(θ/2) = [0]",
							"ans": [
								"224"
							],
							"hint": "280 × 4/5",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "代進餘弦定理：",
							"template": "\\ol{BQ}^{2} = 14^{2} + 10^{2} − 224 = [0]",
							"ans": [
								"72"
							],
							"hint": "196 + 100 − 224",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "開根號：",
							"template": "答：\\ol{BQ} = √{72} = [0]",
							"ans": [
								"6√2"
							],
							"hint": "72 = 36 × 2",
							"part": "(3)"
						}
					]
				},
				{
					"stem": "砲台 A 在砲台 B 的正東方 4 公里。A 向西偏北 θ、B 向東偏北 θ 發射，同時命中離兩砲台都是 16 公里的目標 P。接著 A 改向西偏北 θ/2 發射，落在 6 公里外的 Q 點。\n(1) 求 cos θ　(2) 求 cos(θ/2)　(3) 求 \\ol{BQ}",
					"plot": {
						"x": [
							-1.9049,
							5.9049
						],
						"y": [
							-1.9049,
							17.7794
						],
						"geo": true,
						"h": 210,
						"shapes": [
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									4,
									0
								],
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									2,
									15.8745
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									4,
									0
								],
								"b": [
									2,
									15.8745
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									2,
									15.8745
								],
								"b": [
									2,
									0
								],
								"c": "faint",
								"dash": true
							},
							{
								"k": "angle",
								"o": [
									4,
									0
								],
								"a0": 97.1808,
								"a1": 180,
								"r": 26,
								"s": "θ"
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 0,
								"a1": 82.8192,
								"r": 22,
								"s": "θ"
							},
							{
								"k": "seg",
								"a": [
									4,
									0
								],
								"b": [
									-0.5,
									3.9686
								],
								"c": "pink",
								"dash": true,
								"at": 1
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									-0.5,
									3.9686
								],
								"c": "gold",
								"w": 2.6,
								"at": 3
							},
							{
								"k": "label",
								"p": [
									-0.762,
									-1.143
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									4.762,
									-1.143
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									2,
									17.0175
								],
								"s": "P"
							},
							{
								"k": "label",
								"p": [
									2,
									-1.143
								],
								"s": "2"
							},
							{
								"k": "dot",
								"p": [
									-0.5,
									3.9686
								],
								"s": "Q",
								"off": [
									-18,
									-6
								],
								"at": 1
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "\\ol{PA} = \\ol{PB}：P 往 \\ol{AB} 的垂線落在中點，切出直角三角形（鄰邊 2、斜邊 16）。",
							"template": "(1)　cos θ = [0]",
							"ans": [
								"1/8"
							],
							"hint": "cos = 鄰邊/斜邊",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "θ 是銳角，半角公式 cos(θ/2) = √{(1 + cos θ)/2}，先算根號裡面：",
							"template": "(2)　(1 + cos θ)/2 = (9/8)/2 = [0]",
							"ans": [
								"9/16"
							],
							"hint": "1 + 1/8 = 9/8",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "開根號：",
							"template": "cos(θ/2) = √{9/16} = [0]",
							"ans": [
								"3/4"
							],
							"hint": "9、16 都是平方數",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "△ABQ 中 \\ol{AB} = 4、\\ol{AQ} = 6、∠BAQ = θ/2。餘弦定理的最後一項：",
							"template": "(3)　2 · 4 · 6 · cos(θ/2) = [0]",
							"ans": [
								"36"
							],
							"hint": "48 × 3/4",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "代進餘弦定理：",
							"template": "\\ol{BQ}^{2} = 4^{2} + 6^{2} − 36 = [0]",
							"ans": [
								"16"
							],
							"hint": "16 + 36 − 36",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "開根號：",
							"template": "答：\\ol{BQ} = √{16} = [0]",
							"ans": [
								"4"
							],
							"hint": "16 = 4^{2}",
							"part": "(3)"
						}
					]
				}
			]
		},
		{
			"id": "tb_path",
			"kind": "boss",
			"tier": 3,
			"title": "池塘步道",
			"tmul": 1.65,
			"stem": "半徑 20 公尺的圓形池塘裡修「工」字步道：上下兩條等長且平行的弦 \\ol{AB}、\\ol{CD}，加上連接兩弦中點 M、N 的步道（經過圓心 O）。設 ∠AOM = θ（0 < θ < π/2）。\n(1) 把總長 L 用 θ 表示　(2) L 最長多少？(3) 此時 \\ol{MN} 多長？",
			"plot": {
				"x": [
					-21.5,
					21.5
				],
				"y": [
					-21.5,
					21.5
				],
				"geo": true,
				"h": 200,
				"shapes": [
					{
						"k": "circle",
						"o": [
							0,
							0
						],
						"r": 20,
						"c": "dim"
					},
					{
						"k": "seg",
						"a": [
							-17.8885,
							8.9443
						],
						"b": [
							17.8885,
							8.9443
						],
						"c": "cyan",
						"w": 2.6
					},
					{
						"k": "seg",
						"a": [
							-17.8885,
							-8.9443
						],
						"b": [
							17.8885,
							-8.9443
						],
						"c": "cyan",
						"w": 2.6
					},
					{
						"k": "seg",
						"a": [
							0,
							8.9443
						],
						"b": [
							0,
							-8.9443
						],
						"c": "cyan",
						"w": 2.6
					},
					{
						"k": "seg",
						"a": [
							0,
							0
						],
						"b": [
							-17.8885,
							8.9443
						],
						"c": "faint",
						"dash": true
					},
					{
						"k": "angle",
						"o": [
							0,
							0
						],
						"a0": 90,
						"a1": 153.4349,
						"r": 18,
						"s": "θ"
					},
					{
						"k": "label",
						"p": [
							-19.2885,
							10.8443
						],
						"s": "A"
					},
					{
						"k": "label",
						"p": [
							19.2885,
							10.8443
						],
						"s": "B"
					},
					{
						"k": "label",
						"p": [
							-19.2885,
							-11.0443
						],
						"s": "C"
					},
					{
						"k": "label",
						"p": [
							19.2885,
							-11.0443
						],
						"s": "D"
					},
					{
						"k": "label",
						"p": [
							2.6,
							11.0443
						],
						"s": "M"
					},
					{
						"k": "label",
						"p": [
							2.6,
							-11.2443
						],
						"s": "N"
					},
					{
						"k": "label",
						"p": [
							2.8,
							-1.6
						],
						"s": "O"
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "\\ol{AB} = 2\\ol{AM}，\\ol{MN} = 2\\ol{OM}：",
					"template": "L = 2\\ol{AB} + \\ol{MN} = [0] sin θ + [1] cos θ",
					"ans": [
						"80",
						"40"
					],
					"hint": "\\ol{AB} = 2\\ol{AM}，\\ol{MN} = 2\\ol{OM}",
					"part": "(1)",
					"pre": "(1)　直角 △AOM：\\ol{AM} = 20 sin θ、\\ol{OM} = 20 cos θ"
				},
				{
					"t": "fill",
					"q": "提出 40 再疊合：",
					"template": "(2)　L = 40(2 sin θ + cos θ)，最長 [0] 公尺",
					"ans": [
						"40√5"
					],
					"hint": "40 √{2^{2} + 1^{2}}",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "最長時 sin θ : cos θ = 2 : 1（和係數成比例）：",
					"template": "(3)　tan θ = [0]，cos θ = [1]",
					"ans": [
						"2",
						"√5/5"
					],
					"hint": "斜邊 √{5}",
					"part": "(3)"
				},
				{
					"t": "fill",
					"q": "\\ol{MN} = 40 cos θ：",
					"template": "答：\\ol{MN} = [0] 公尺",
					"ans": [
						"8√5"
					],
					"hint": "40 · √{5}/5",
					"part": "(3)"
				}
			],
			"vars": [
				{
					"stem": "半徑 10 公尺的圓形池塘裡修「T」字步道：一條弦 \\ol{AB}，加上從 \\ol{AB} 的中點 M 經過圓心 O、一直走到池塘最低點 N 的步道。設 ∠AOM = θ（0 < θ < π/2）。\n(1) 把總長 L 用 θ 表示　(2) L 最長多少？(3) 此時 \\ol{MN} 多長？",
					"plot": {
						"x": [
							-21.5,
							21.5
						],
						"y": [
							-21.5,
							21.5
						],
						"geo": true,
						"h": 200,
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 20,
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									-17.8885,
									8.9443
								],
								"b": [
									17.8885,
									8.9443
								],
								"c": "cyan",
								"w": 2.6
							},
							{
								"k": "seg",
								"a": [
									0,
									8.9443
								],
								"b": [
									0,
									-20
								],
								"c": "cyan",
								"w": 2.6
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									-17.8885,
									8.9443
								],
								"c": "faint",
								"dash": true
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 90,
								"a1": 153.4349,
								"r": 18,
								"s": "θ"
							},
							{
								"k": "label",
								"p": [
									-19.2885,
									10.8443
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									19.2885,
									10.8443
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									2.6,
									11.0443
								],
								"s": "M"
							},
							{
								"k": "label",
								"p": [
									2.6,
									-22.3
								],
								"s": "N"
							},
							{
								"k": "label",
								"p": [
									2.8,
									-1.6
								],
								"s": "O"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "\\ol{AB} = 2\\ol{AM}，\\ol{MN} = \\ol{OM} + \\ol{ON}：",
							"template": "L = [0] sin θ + [1] cos θ + [2]",
							"ans": [
								"20",
								"10",
								"10"
							],
							"hint": "\\ol{ON} 是半徑 10",
							"part": "(1)",
							"pre": "(1)　直角 △AOM：\\ol{AM} = 10 sin θ、\\ol{OM} = 10 cos θ"
						},
						{
							"t": "fill",
							"q": "前兩項提出 10 再疊合：",
							"template": "(2)　L = 10(2 sin θ + cos θ) + 10，最長 [0]√5 + [1] 公尺",
							"ans": [
								"10",
								"10"
							],
							"hint": "10 √{2^{2} + 1^{2}} + 10",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "最長時 sin θ : cos θ = 2 : 1（和係數成比例）：",
							"template": "(3)　tan θ = [0]，cos θ = [1]",
							"ans": [
								"2",
								"√5/5"
							],
							"hint": "斜邊 √{5}",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "\\ol{MN} = 10 cos θ + 10：",
							"template": "答：\\ol{MN} = [0]√5 + [1] 公尺",
							"ans": [
								"2",
								"10"
							],
							"hint": "10 · √{5}/5",
							"part": "(3)"
						}
					]
				},
				{
					"stem": "半徑 10 公尺的圓形池塘，A、B 是一條水平直徑的兩端，S 是池塘最低點。要修「Y」字步道：在半徑 \\ol{OS} 上選一點 J，修 \\ol{JA}、\\ol{JB}、\\ol{JS} 三段。設 ∠JAO = θ（0 ≤ θ < π/4）。\n(1) 把總長 L 用 θ 表示　(2) L 最短多少？(3) 此時 θ 是多少？",
					"plot": {
						"x": [
							-21.5,
							21.5
						],
						"y": [
							-21.5,
							21.5
						],
						"geo": true,
						"h": 200,
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 20,
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									-20,
									0
								],
								"b": [
									20,
									0
								],
								"c": "faint",
								"dash": true
							},
							{
								"k": "seg",
								"a": [
									-20,
									0
								],
								"b": [
									0,
									-11.547
								],
								"c": "cyan",
								"w": 2.6
							},
							{
								"k": "seg",
								"a": [
									20,
									0
								],
								"b": [
									0,
									-11.547
								],
								"c": "cyan",
								"w": 2.6
							},
							{
								"k": "seg",
								"a": [
									0,
									-11.547
								],
								"b": [
									0,
									-20
								],
								"c": "cyan",
								"w": 2.6
							},
							{
								"k": "angle",
								"o": [
									-20,
									0
								],
								"a0": -30,
								"a1": 0,
								"r": 24,
								"s": "θ"
							},
							{
								"k": "label",
								"p": [
									-21.0,
									2.0
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									21.0,
									2.0
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									2.4,
									-22.3
								],
								"s": "S"
							},
							{
								"k": "label",
								"p": [
									2.6,
									-12.747
								],
								"s": "J"
							},
							{
								"k": "label",
								"p": [
									1.6,
									1.8
								],
								"s": "O"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "直角 △JOA：\\ol{OA} = 10 是鄰邊。",
							"template": "(1)　\\ol{JA} = [0]/cos θ，\\ol{JS} = [1] − 10 tan θ",
							"ans": [
								"10",
								"10"
							],
							"hint": "\\ol{OJ} = 10 tan θ，\\ol{JS} = \\ol{OS} − \\ol{OJ}",
							"part": "(1)"
						},
						{
							"t": "choice",
							"q": "L = 2\\ol{JA} + \\ol{JS}，通分：",
							"opts": [
								"L = 10 + 10(2 − sin θ)/cos θ",
								"L = 10 + 10(2 + sin θ)/cos θ",
								"L = 10(2 − sin θ)/cos θ",
								"L = 10 + 10(1 − sin θ)/cos θ"
							],
							"hint": "−10 tan θ = −10 sin θ/cos θ，和 20/cos θ 合起來",
							"write": "L = 10 + 10 k，k = (2 − sin θ)/cos θ",
							"part": "(1)"
						},
						{
							"t": "choice",
							"q": "k = (2 − sin θ)/cos θ ⇒ k cos θ + sin θ = 2。這個方程式有解的條件：",
							"opts": [
								"k^{2} + 1 ≥ 4",
								"k + 1 ≥ 2",
								"k^{2} + 1 ≤ 4",
								"k ≥ 2"
							],
							"hint": "a cos θ + b sin θ 的範圍是 ±√{a^{2} + b^{2}}",
							"write": "(2)　√{k^{2} + 1} ≥ 2 ⇒ k ≥ √{3}（k > 0）",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "k 最小 √{3}：",
							"template": "L 最短 = [0] + [1]√3 公尺",
							"ans": [
								"10",
								"10"
							],
							"hint": "10 + 10 · √{3}",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "等號成立時 √{3} cos θ + sin θ = 2，疊合成 2 sin(θ + π/3) = 2：",
							"template": "答：(3)　θ = [0]π",
							"ans": [
								"1/6"
							],
							"hint": "θ + π/3 = π/2",
							"part": "(3)"
						}
					]
				}
			]
		},
		{
			"id": "tb_coin",
			"kind": "boss",
			"tier": 2,
			"title": "滾動的圓盤",
			"tmul": 1.6,
			"stem": "半徑 6 的圓盤內接正方形 ABCD（A、B、C、D 依逆時針排列），一開始 A 碰著地面、B 在圓心正右方。圓盤沿地面向右滾動（不打滑），滾了 x 之後 B 離地 y = a sin(bx + c) + d（a、b > 0，0 ≤ c < 2π）。\n(1) 求 a、b、c、d　(2) 滾了 7π 時 B 離地多高？(3) 滾了多遠 B 第一次碰到地面？",
			"plot": {
				"x": [
					-7.0,
					16.4248
				],
				"y": [
					-1.2,
					13.0
				],
				"geo": true,
				"h": 170,
				"shapes": [
					{
						"k": "seg",
						"a": [
							-7.0,
							0
						],
						"b": [
							16.4248,
							0
						],
						"c": "dim"
					}
				],
				"groups": [
					{
						"o": [
							0,
							6
						],
						"anim": {
							"k": "roll",
							"r": 6,
							"dist": 9.4248,
							"dur": 3.2
						},
						"trace": [
							6,
							0
						],
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 6,
								"c": "cyan"
							},
							{
								"k": "poly",
								"pts": [
									[
										0,
										-6
									],
									[
										6,
										0
									],
									[
										0,
										6
									],
									[
										-6,
										0
									]
								],
								"c": "faint"
							},
							{
								"k": "dot",
								"p": [
									0,
									-6
								],
								"s": "A",
								"c": "cyan",
								"off": [
									6,
									14
								]
							},
							{
								"k": "dot",
								"p": [
									6,
									0
								],
								"s": "B",
								"c": "gold",
								"off": [
									8,
									-6
								]
							},
							{
								"k": "dot",
								"p": [
									0,
									6
								],
								"s": "C",
								"c": "cyan"
							},
							{
								"k": "dot",
								"p": [
									-6,
									0
								],
								"s": "D",
								"c": "cyan",
								"off": [
									-18,
									-6
								]
							}
						]
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "B 繞著圓心轉，圓心離地 6：",
					"template": "(1)　a = [0]，d = [1]",
					"ans": [
						"6",
						"6"
					],
					"hint": "半徑、圓心高度",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "滾 x 就順時針轉 x/6（弧長 = 半徑 × 弧度）：",
					"template": "b = [0]",
					"ans": [
						"1/6"
					],
					"hint": "轉過的角 = x/6",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "把它寫成 sin(x/6 + c)：",
					"template": "y = 6 sin(x/6 + c) + 6 ⇒ c = [0]π",
					"ans": [
						"1"
					],
					"hint": "sin(θ + π) = −sin θ",
					"part": "(1)",
					"pre": "B 從中線往下：y = 6 − 6 sin(x/6)"
				},
				{
					"t": "fill",
					"q": "x = 7π 代入：",
					"template": "(2)　y = 6 sin(7π/6 + π) + 6 = [0]",
					"ans": [
						"9"
					],
					"hint": "sin(13π/6) = 1/2",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "y = 0 ⇒ sin(x/6 + π) = −1，取最小的 x > 0：",
					"template": "答：滾了 [0]π",
					"ans": [
						"3"
					],
					"hint": "x/6 + π = 3π/2",
					"part": "(3)"
				}
			],
			"vars": [
				{
					"stem": "半徑 4 的圓盤內接正方形 ABCD（A、B、C、D 依逆時針排列），一開始 A 碰著地面、B 在圓心正右方。圓盤沿地面向右滾動（不打滑），滾了 x 之後 D 離地 y = a sin(bx + c) + d（a、b > 0，0 ≤ c < 2π）。\n(1) 求 a、b、c、d　(2) 滾了 14π/3 時 D 離地多高？(3) 滾了多遠 D 第一次碰到地面？",
					"plot": {
						"x": [
							-5.0,
							23.8496
						],
						"y": [
							-1.2,
							9.0
						],
						"geo": true,
						"h": 170,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-5.0,
									0
								],
								"b": [
									23.8496,
									0
								],
								"c": "dim"
							}
						],
						"groups": [
							{
								"o": [
									0,
									4
								],
								"anim": {
									"k": "roll",
									"r": 4,
									"dist": 18.8496,
									"dur": 3.2
								},
								"trace": [
									-4,
									0
								],
								"shapes": [
									{
										"k": "circle",
										"o": [
											0,
											0
										],
										"r": 4,
										"c": "cyan"
									},
									{
										"k": "poly",
										"pts": [
											[
												0,
												-4
											],
											[
												4,
												0
											],
											[
												0,
												4
											],
											[
												-4,
												0
											]
										],
										"c": "faint"
									},
									{
										"k": "dot",
										"p": [
											0,
											-4
										],
										"s": "A",
										"c": "cyan",
										"off": [
											6,
											14
										]
									},
									{
										"k": "dot",
										"p": [
											4,
											0
										],
										"s": "B",
										"c": "cyan",
										"off": [
											8,
											-6
										]
									},
									{
										"k": "dot",
										"p": [
											0,
											4
										],
										"s": "C",
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											-4,
											0
										],
										"s": "D",
										"c": "gold",
										"off": [
											-18,
											-6
										]
									}
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "D 繞著圓心轉，圓心離地 4：",
							"template": "(1)　a = [0]，d = [1]",
							"ans": [
								"4",
								"4"
							],
							"hint": "半徑、圓心高度",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "滾 x 就順時針轉 x/4（弧長 = 半徑 × 弧度）：",
							"template": "b = [0]",
							"ans": [
								"1/4"
							],
							"hint": "轉過的角 = x/4",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "把它寫成 sin(x/4 + c)：",
							"template": "y = 4 sin(x/4 + c) + 4 ⇒ c = [0]",
							"ans": [
								"0"
							],
							"hint": "本來就是 sin(x/4) 的樣子",
							"part": "(1)",
							"pre": "D 從中線往上：y = 4 + 4 sin(x/4)"
						},
						{
							"t": "fill",
							"q": "x = 14π/3 代入：",
							"template": "(2)　y = 4 sin(7π/6) + 4 = [0]",
							"ans": [
								"2"
							],
							"hint": "sin(7π/6) = −1/2",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "y = 0 ⇒ sin(x/4) = −1，取最小的 x > 0：",
							"template": "答：滾了 [0]π",
							"ans": [
								"6"
							],
							"hint": "x/4 = 3π/2",
							"part": "(3)"
						}
					]
				},
				{
					"stem": "半徑 6 的圓盤內接正方形 ABCD（A、B、C、D 依逆時針排列），一開始 A 碰著地面、B 在圓心正右方。圓盤沿地面向右滾動（不打滑），滾了 x 之後 C 離地 y = a sin(bx + c) + d（a、b > 0，0 ≤ c < 2π）。\n(1) 求 a、b、c、d　(2) 滾了 4π 時 C 離地多高？(3) 滾了多遠 C 第一次碰到地面？",
					"plot": {
						"x": [
							-7.0,
							25.8496
						],
						"y": [
							-1.2,
							13.0
						],
						"geo": true,
						"h": 170,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-7.0,
									0
								],
								"b": [
									25.8496,
									0
								],
								"c": "dim"
							}
						],
						"groups": [
							{
								"o": [
									0,
									6
								],
								"anim": {
									"k": "roll",
									"r": 6,
									"dist": 18.8496,
									"dur": 3.2
								},
								"trace": [
									0,
									6
								],
								"shapes": [
									{
										"k": "circle",
										"o": [
											0,
											0
										],
										"r": 6,
										"c": "cyan"
									},
									{
										"k": "poly",
										"pts": [
											[
												0,
												-6
											],
											[
												6,
												0
											],
											[
												0,
												6
											],
											[
												-6,
												0
											]
										],
										"c": "faint"
									},
									{
										"k": "dot",
										"p": [
											0,
											-6
										],
										"s": "A",
										"c": "cyan",
										"off": [
											6,
											14
										]
									},
									{
										"k": "dot",
										"p": [
											6,
											0
										],
										"s": "B",
										"c": "cyan",
										"off": [
											8,
											-6
										]
									},
									{
										"k": "dot",
										"p": [
											0,
											6
										],
										"s": "C",
										"c": "gold"
									},
									{
										"k": "dot",
										"p": [
											-6,
											0
										],
										"s": "D",
										"c": "cyan",
										"off": [
											-18,
											-6
										]
									}
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "C 繞著圓心轉，圓心離地 6：",
							"template": "(1)　a = [0]，d = [1]",
							"ans": [
								"6",
								"6"
							],
							"hint": "半徑、圓心高度",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "滾 x 就順時針轉 x/6（弧長 = 半徑 × 弧度）：",
							"template": "b = [0]",
							"ans": [
								"1/6"
							],
							"hint": "轉過的角 = x/6",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "把它寫成 sin(x/6 + c)：",
							"template": "y = 6 sin(x/6 + c) + 6 ⇒ c = [0]π",
							"ans": [
								"1/2"
							],
							"hint": "cos θ = sin(θ + π/2)",
							"part": "(1)",
							"pre": "C 從最高點往下：y = 6 + 6 cos(x/6)"
						},
						{
							"t": "fill",
							"q": "x = 4π 代入：",
							"template": "(2)　y = 6 sin(2π/3 + π/2) + 6 = [0]",
							"ans": [
								"3"
							],
							"hint": "sin(7π/6) = −1/2",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "y = 0 ⇒ sin(x/6 + π/2) = −1，取最小的 x > 0：",
							"template": "答：滾了 [0]π",
							"ans": [
								"6"
							],
							"hint": "x/6 + π/2 = 3π/2",
							"part": "(3)"
						}
					]
				}
			]
		},
		{
			"id": "tb_wave",
			"kind": "boss",
			"tier": 2,
			"title": "讀圖找疊合",
			"tmul": 1.65,
			"stem": "圖是 y = a sin x + b cos x 的一段，最高點 (π/3, 4)。\n(1) 求 a、b　(2) −π/2 ≤ x ≤ π/2 時的最小值　(3) 0 ≤ x ≤ 2π 時，y = 2 的所有解的和",
			"plot": {
				"x": [
					-1.8,
					6.6
				],
				"y": [
					-4.8,
					4.8
				],
				"pi": 6,
				"pi_lab": 2,
				"curves": [
					{
						"f": "4.0*sin(x+0.5235987755982988)",
						"c": "cyan"
					},
					{
						"f": "2.0",
						"c": "pink",
						"dash": true,
						"at": 4
					}
				],
				"band": {
					"lo": -1.5708,
					"hi": 1.5708,
					"at": 2
				},
				"pts": [
					{
						"x": 1.0472,
						"y": 4,
						"label": "(π/3, 4)"
					},
					{
						"x": -1.5708,
						"y": -3.4641,
						"label": "",
						"at": 3
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "最高點時 x + φ = π/2：",
					"template": "π/3 + φ = π/2 ⇒ φ = [0]π",
					"ans": [
						"1/6"
					],
					"hint": "π/2 − π/3",
					"part": "(1)",
					"pre": "(1)　最大值 4 ⇒ y = 4 sin(x + φ)"
				},
				{
					"t": "fill",
					"q": "和角公式展開，對照 a sin x + b cos x：",
					"template": "a = 4 cos(π/6) = [0]，b = 4 sin(π/6) = [1]",
					"ans": [
						"2√3",
						"2"
					],
					"hint": "4 · √{3}/2、4 · 1/2",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "x + π/6 從 −π/3 到 2π/3，sin 最小在左端：",
					"template": "(2)　最小值 4 sin(−π/3) = [0]",
					"ans": [
						"−2√3"
					],
					"hint": "sin(−π/3) = −√{3}/2",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "x + π/6 從 π/6 走到 13π/6，sin = 1/2 的角（由小到大）：",
					"template": "x + π/6 = [0]π、[1]π、[2]π",
					"ans": [
						"1/6",
						"5/6",
						"13/6"
					],
					"hint": "第一、第二象限各一個，再看有沒有多繞一圈",
					"part": "(3)",
					"pre": "(3)　4 sin(x + π/6) = 2 ⇒ sin(x + π/6) = 1/2"
				},
				{
					"t": "fill",
					"q": "各減 π/6：",
					"template": "x = [0]π、[1]π、[2]π",
					"ans": [
						"0",
						"2/3",
						"2"
					],
					"hint": "每一個都減 π/6",
					"part": "(3)"
				},
				{
					"t": "fill",
					"q": "三個解加起來：",
					"template": "答：和 = [0]π",
					"ans": [
						"8/3"
					],
					"hint": "0 + 2π/3 + 2π",
					"part": "(3)"
				}
			],
			"vars": [
				{
					"stem": "圖是 y = a sin x + b cos x 的一段，最高點 (π/6, 2)。\n(1) 求 a、b　(2) −π/2 ≤ x ≤ π/2 時的最小值　(3) 0 ≤ x ≤ 2π 時，y = 1 的所有解的和",
					"plot": {
						"x": [
							-1.8,
							6.6
						],
						"y": [
							-2.8,
							2.8
						],
						"pi": 6,
						"pi_lab": 2,
						"curves": [
							{
								"f": "2.0*sin(x+1.0471975511965976)",
								"c": "cyan"
							},
							{
								"f": "1.0",
								"c": "pink",
								"dash": true,
								"at": 4
							}
						],
						"band": {
							"lo": -1.5708,
							"hi": 1.5708,
							"at": 2
						},
						"pts": [
							{
								"x": 0.5236,
								"y": 2,
								"label": "(π/6, 2)"
							},
							{
								"x": -1.5708,
								"y": -1,
								"label": "",
								"at": 3
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "最高點時 x + φ = π/2：",
							"template": "π/6 + φ = π/2 ⇒ φ = [0]π",
							"ans": [
								"1/3"
							],
							"hint": "π/2 − π/6",
							"part": "(1)",
							"pre": "(1)　最大值 2 ⇒ y = 2 sin(x + φ)"
						},
						{
							"t": "fill",
							"q": "和角公式展開，對照 a sin x + b cos x：",
							"template": "a = 2 cos(π/3) = [0]，b = 2 sin(π/3) = [1]",
							"ans": [
								"1",
								"√3"
							],
							"hint": "2 · 1/2、2 · √{3}/2",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "x + π/3 從 −π/6 到 5π/6，sin 最小在左端：",
							"template": "(2)　最小值 2 sin(−π/6) = [0]",
							"ans": [
								"−1"
							],
							"hint": "sin(−π/6) = −1/2",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "x + π/3 從 π/3 走到 7π/3，sin = 1/2 的角（由小到大）：",
							"template": "x + π/3 = [0]π、[1]π",
							"ans": [
								"5/6",
								"13/6"
							],
							"hint": "第一、第二象限各一個，再看有沒有多繞一圈",
							"part": "(3)",
							"pre": "(3)　2 sin(x + π/3) = 1 ⇒ sin(x + π/3) = 1/2"
						},
						{
							"t": "fill",
							"q": "各減 π/3：",
							"template": "x = [0]π、[1]π",
							"ans": [
								"1/2",
								"11/6"
							],
							"hint": "每一個都減 π/3",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "兩個解加起來：",
							"template": "答：和 = [0]π",
							"ans": [
								"7/3"
							],
							"hint": "π/2 + 11π/6",
							"part": "(3)"
						}
					]
				},
				{
					"stem": "圖是 y = a sin x + b cos x 的一段，最高點 (π/4, 2√{2})。\n(1) 求 a、b　(2) −π/2 ≤ x ≤ π/2 時的最小值　(3) 0 ≤ x ≤ 2π 時，y = √{2} 的所有解的和",
					"plot": {
						"x": [
							-1.8,
							6.6
						],
						"y": [
							-3.6284,
							3.6284
						],
						"pi": 12,
						"pi_lab": 2,
						"curves": [
							{
								"f": "2.8284271247461903*sin(x+0.7853981633974483)",
								"c": "cyan"
							},
							{
								"f": "1.4142135623730951",
								"c": "pink",
								"dash": true,
								"at": 4
							}
						],
						"band": {
							"lo": -1.5708,
							"hi": 1.5708,
							"at": 2
						},
						"pts": [
							{
								"x": 0.7854,
								"y": 2.8284,
								"label": "(π/4, 2√2)"
							},
							{
								"x": -1.5708,
								"y": -2,
								"label": "",
								"at": 3
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "最高點時 x + φ = π/2：",
							"template": "π/4 + φ = π/2 ⇒ φ = [0]π",
							"ans": [
								"1/4"
							],
							"hint": "π/2 − π/4",
							"part": "(1)",
							"pre": "(1)　最大值 2√{2} ⇒ y = 2√{2} sin(x + φ)"
						},
						{
							"t": "fill",
							"q": "和角公式展開，對照 a sin x + b cos x：",
							"template": "a = 2√{2} cos(π/4) = [0]，b = 2√{2} sin(π/4) = [1]",
							"ans": [
								"2",
								"2"
							],
							"hint": "2√{2} · √{2}/2、2√{2} · √{2}/2",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "x + π/4 從 −π/4 到 3π/4，sin 最小在左端：",
							"template": "(2)　最小值 2√{2} sin(−π/4) = [0]",
							"ans": [
								"−2"
							],
							"hint": "sin(−π/4) = −√{2}/2",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "x + π/4 從 π/4 走到 9π/4，sin = 1/2 的角（由小到大）：",
							"template": "x + π/4 = [0]π、[1]π",
							"ans": [
								"5/6",
								"13/6"
							],
							"hint": "第一、第二象限各一個，再看有沒有多繞一圈",
							"part": "(3)",
							"pre": "(3)　2√{2} sin(x + π/4) = √{2} ⇒ sin(x + π/4) = 1/2"
						},
						{
							"t": "fill",
							"q": "各減 π/4：",
							"template": "x = [0]π、[1]π",
							"ans": [
								"7/12",
								"23/12"
							],
							"hint": "每一個都減 π/4",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "兩個解加起來：",
							"template": "答：和 = [0]π",
							"ans": [
								"5/2"
							],
							"hint": "7π/12 + 23π/12",
							"part": "(3)"
						}
					]
				}
			]
		},
		{
			"id": "tb_hex",
			"kind": "boss",
			"tier": 3,
			"title": "翻滾的多邊形",
			"tmul": 1.65,
			"stem": "邊長 2 的正六邊形放在直線上，頂點 P 碰著直線。六邊形沿直線向右翻滾（每次繞著右下角的頂點轉），直到 P 再次碰到直線。\n(1) 一共翻了幾次？每次轉多少？(2) P 走過的路徑長",
			"plot": {
				"x": [
					-1.6,
					15.6
				],
				"y": [
					-0.6,
					4.6641
				],
				"geo": true,
				"h": 130,
				"shapes": [
					{
						"k": "seg",
						"a": [
							-1.6,
							0
						],
						"b": [
							15.6,
							0
						],
						"c": "dim"
					}
				],
				"groups": [
					{
						"o": [
							0,
							0
						],
						"anim": {
							"k": "polyroll",
							"side": 2,
							"sides": 6,
							"n": 5,
							"dur": 0.9
						},
						"trace": [
							0,
							0
						],
						"shapes": [
							{
								"k": "poly",
								"pts": [
									[
										0,
										0
									],
									[
										2,
										0
									],
									[
										3,
										1.7321
									],
									[
										2,
										3.4641
									],
									[
										0,
										3.4641
									],
									[
										-1,
										1.7321
									]
								],
								"c": "cyan"
							},
							{
								"k": "dot",
								"p": [
									0,
									0
								],
								"s": "P",
								"off": [
									-14,
									-6
								]
							}
						]
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "每翻一次，下一個頂點落地。六個頂點輪一圈回到 P，P 自己落地那次不用再翻。",
					"template": "(1)　翻 [0] 次",
					"ans": [
						"5"
					],
					"hint": "6 個頂點，扣掉 P",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "每次轉的角度是正六邊形的外角：",
					"template": "每次轉 2π/6 = [0]π",
					"ans": [
						"1/3"
					],
					"hint": "約分",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "每翻一次，P 繞轉動的頂點畫一段圓弧，半徑是 P 到那個頂點的距離。和 P 相隔一個頂點的距離是 2√{3}，正對面的是：",
					"template": "(2)　半徑依序 2、2√3、[0]、2√3、2",
					"ans": [
						"4"
					],
					"hint": "正對面的頂點：通過中心，2 × 邊長",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "把五個半徑加起來：",
					"template": "半徑的和 = [0] + [1]√3",
					"ans": [
						"8",
						"4"
					],
					"hint": "2 + 4 + 2，以及 2√{3} + 2√{3}",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "每段弧長 = 半徑 × π/3，五段加起來：",
					"template": "答：路徑長 = ([0] + [1]√3)π/3",
					"ans": [
						"8",
						"4"
					],
					"hint": "半徑的和乘 π/3",
					"part": "(2)"
				}
			],
			"vars": [
				{
					"stem": "邊長 2 的正方形放在直線上，頂點 P 碰著直線。正方形沿直線向右翻滾（每次繞著右下角的頂點轉），直到 P 再次碰到直線。\n(1) 一共翻了幾次？每次轉多少？(2) P 走過的路徑長",
					"plot": {
						"x": [
							-1.6,
							11.6
						],
						"y": [
							-0.6,
							3.2
						],
						"geo": true,
						"h": 130,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-1.6,
									0
								],
								"b": [
									11.6,
									0
								],
								"c": "dim"
							}
						],
						"groups": [
							{
								"o": [
									0,
									0
								],
								"anim": {
									"k": "polyroll",
									"side": 2,
									"sides": 4,
									"n": 3,
									"dur": 0.9
								},
								"trace": [
									0,
									0
								],
								"shapes": [
									{
										"k": "poly",
										"pts": [
											[
												0,
												0
											],
											[
												2,
												0
											],
											[
												2,
												2
											],
											[
												0,
												2
											]
										],
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											0,
											0
										],
										"s": "P",
										"off": [
											-14,
											-6
										]
									}
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "每翻一次，下一個頂點落地。四個頂點輪一圈回到 P，P 自己落地那次不用再翻。",
							"template": "(1)　翻 [0] 次",
							"ans": [
								"3"
							],
							"hint": "4 個頂點，扣掉 P",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "每次轉的角度是正方形的外角：",
							"template": "每次轉 2π/4 = [0]π",
							"ans": [
								"1/2"
							],
							"hint": "約分",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "每翻一次，P 繞轉動的頂點畫一段圓弧，半徑是 P 到那個頂點的距離。相鄰的頂點距離 2，對角的是：",
							"template": "(2)　半徑依序 2、[0]、2",
							"ans": [
								"2√2"
							],
							"hint": "對角線 = 邊長 × √{2}",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "把三個半徑加起來：",
							"template": "半徑的和 = [0] + [1]√2",
							"ans": [
								"4",
								"2"
							],
							"hint": "2 + 2，以及 2√{2}",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "每段弧長 = 半徑 × π/2，三段加起來：",
							"template": "答：路徑長 = ([0] + [1]√2)π/2",
							"ans": [
								"4",
								"2"
							],
							"hint": "半徑的和乘 π/2",
							"part": "(2)"
						}
					]
				},
				{
					"stem": "邊長 3 的正六邊形放在直線上，頂點 P 碰著直線。六邊形沿直線向右翻滾（每次繞著右下角的頂點轉），直到 P 再次碰到直線。\n(1) 一共翻了幾次？每次轉多少？(2) P 走過的路徑長",
					"plot": {
						"x": [
							-1.6,
							22.6
						],
						"y": [
							-0.6,
							6.3962
						],
						"geo": true,
						"h": 130,
						"shapes": [
							{
								"k": "seg",
								"a": [
									-1.6,
									0
								],
								"b": [
									22.6,
									0
								],
								"c": "dim"
							}
						],
						"groups": [
							{
								"o": [
									0,
									0
								],
								"anim": {
									"k": "polyroll",
									"side": 3,
									"sides": 6,
									"n": 5,
									"dur": 0.9
								},
								"trace": [
									0,
									0
								],
								"shapes": [
									{
										"k": "poly",
										"pts": [
											[
												0,
												0
											],
											[
												3,
												0
											],
											[
												4.5,
												2.5981
											],
											[
												3,
												5.1962
											],
											[
												0,
												5.1962
											],
											[
												-1.5,
												2.5981
											]
										],
										"c": "cyan"
									},
									{
										"k": "dot",
										"p": [
											0,
											0
										],
										"s": "P",
										"off": [
											-14,
											-6
										]
									}
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "每翻一次，下一個頂點落地。六個頂點輪一圈回到 P，P 自己落地那次不用再翻。",
							"template": "(1)　翻 [0] 次",
							"ans": [
								"5"
							],
							"hint": "6 個頂點，扣掉 P",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "每次轉的角度是正六邊形的外角：",
							"template": "每次轉 2π/6 = [0]π",
							"ans": [
								"1/3"
							],
							"hint": "約分",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "每翻一次，P 繞轉動的頂點畫一段圓弧，半徑是 P 到那個頂點的距離。和 P 相隔一個頂點的距離是 3√{3}，正對面的是：",
							"template": "(2)　半徑依序 3、3√3、[0]、3√3、3",
							"ans": [
								"6"
							],
							"hint": "正對面的頂點：通過中心，2 × 邊長",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "把五個半徑加起來：",
							"template": "半徑的和 = [0] + [1]√3",
							"ans": [
								"12",
								"6"
							],
							"hint": "3 + 6 + 3，以及 3√{3} + 3√{3}",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "每段弧長 = 半徑 × π/3，五段加起來：",
							"template": "答：路徑長 = ([0] + [1]√3)π/3",
							"ans": [
								"12",
								"6"
							],
							"hint": "半徑的和乘 π/3",
							"part": "(2)"
						}
					]
				}
			]
		},
		{
			"id": "tb_circum",
			"kind": "boss",
			"tier": 3,
			"title": "外心的圓心角",
			"tmul": 1.65,
			"stem": "O 是 △ABC 的外心，tan A = 4/3、tan B = 2，外接圓半徑 5。\n(1) 求 tan C　(2) 求 tan∠AOB　(3) 求 \\ol{AB} 與 △AOB 的面積",
			"plot": {
				"x": [
					-5.8,
					5.8
				],
				"y": [
					-5.8,
					5.8
				],
				"geo": true,
				"h": 200,
				"shapes": [
					{
						"k": "circle",
						"o": [
							0,
							0
						],
						"r": 5,
						"c": "dim"
					},
					{
						"k": "poly",
						"pts": [
							[
								-4.4721,
								-2.2361
							],
							[
								4.4721,
								-2.2361
							],
							[
								0.8944,
								4.9193
							]
						],
						"c": "cyan"
					},
					{
						"k": "seg",
						"a": [
							0,
							0
						],
						"b": [
							-4.4721,
							-2.2361
						],
						"c": "pink",
						"at": 2
					},
					{
						"k": "seg",
						"a": [
							0,
							0
						],
						"b": [
							4.4721,
							-2.2361
						],
						"c": "pink",
						"at": 2
					},
					{
						"k": "angle",
						"o": [
							0,
							0
						],
						"a0": 206.5651,
						"a1": 333.4349,
						"r": 14,
						"s": "",
						"at": 2
					},
					{
						"k": "label",
						"p": [
							-5.0535,
							-2.5268
						],
						"s": "A"
					},
					{
						"k": "label",
						"p": [
							5.0535,
							-2.5268
						],
						"s": "B"
					},
					{
						"k": "label",
						"p": [
							0.9838,
							5.4112
						],
						"s": "C"
					},
					{
						"k": "dot",
						"p": [
							0,
							0
						],
						"s": "O",
						"off": [
							6,
							-6
						]
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "先算 tan(A + B)：",
					"template": "(1)　tan(A + B) = (4/3 + 2)/(1 − 4/3 · 2) = [0]",
					"ans": [
						"−2"
					],
					"hint": "分子 10/3，分母 −5/3",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "C = π − (A + B)：",
					"template": "tan C = −tan(A + B) = [0]",
					"ans": [
						"2"
					],
					"hint": "tan(π − θ) = −tan θ",
					"part": "(1)"
				},
				{
					"t": "choice",
					"q": "三個角的 tan 都是正的，都是銳角，O 在三角形裡面。∠AOB 和 C 的關係：",
					"opts": [
						"∠AOB = 2∠C",
						"∠AOB = ∠C",
						"∠AOB = 180° − ∠C",
						"∠AOB = 2∠A"
					],
					"hint": "同弧所對的圓心角是圓周角的兩倍",
					"write": "(2)　∠AOB = 2C",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "二倍角 tan 2C = 2 tan C/(1 − tan^{2} C)：",
					"template": "tan∠AOB = tan 2C = 4/(1 − 4) = [0]",
					"ans": [
						"−4/3"
					],
					"hint": "4/(−3)",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "tan C = 2：對邊 2、鄰邊 1、斜邊 √{5}。",
					"template": "(3)　sin C = [0]",
					"ans": [
						"2√5/5"
					],
					"hint": "對邊/斜邊，有理化",
					"part": "(3)"
				},
				{
					"t": "fill",
					"q": "正弦定理 \\ol{AB} = 2R sin C：",
					"template": "\\ol{AB} = 10 · 2√{5}/5 = [0]",
					"ans": [
						"4√5"
					],
					"hint": "10 × 2√{5}/5",
					"part": "(3)"
				},
				{
					"t": "fill",
					"q": "sin 2C = 2 sin C cos C = 4/5：",
					"template": "答：△AOB 面積 = (1/2) · 5 · 5 · sin 2C = [0]",
					"ans": [
						"10"
					],
					"hint": "(25/2) · (4/5)",
					"part": "(3)"
				}
			],
			"vars": [
				{
					"stem": "O 是 △ABC 的外心，tan A = 3、tan B = 1/2，外接圓半徑 5。\n(1) 求 tan C　(2) 求 tan∠AOB　(3) 求 \\ol{AB} 與 △AOB 的面積",
					"plot": {
						"x": [
							-5.8,
							5.8
						],
						"y": [
							-5.8,
							5.8
						],
						"geo": true,
						"h": 200,
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 5,
								"c": "dim"
							},
							{
								"k": "poly",
								"pts": [
									[
										-4.9497,
										-0.7071
									],
									[
										4.9497,
										-0.7071
									],
									[
										-3.5355,
										3.5355
									]
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									-4.9497,
									-0.7071
								],
								"c": "pink",
								"at": 2
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									4.9497,
									-0.7071
								],
								"c": "pink",
								"at": 2
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 188.1301,
								"a1": 351.8699,
								"r": 14,
								"s": "",
								"at": 2
							},
							{
								"k": "label",
								"p": [
									-5.5932,
									-0.799
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									5.5932,
									-0.799
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									-3.8891,
									3.8891
								],
								"s": "C"
							},
							{
								"k": "dot",
								"p": [
									0,
									0
								],
								"s": "O",
								"off": [
									6,
									-6
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "先算 tan(A + B)：",
							"template": "(1)　tan(A + B) = (3 + 1/2)/(1 − 3 · 1/2) = [0]",
							"ans": [
								"−7"
							],
							"hint": "分子 7/2，分母 −1/2",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "C = π − (A + B)：",
							"template": "tan C = −tan(A + B) = [0]",
							"ans": [
								"7"
							],
							"hint": "tan(π − θ) = −tan θ",
							"part": "(1)"
						},
						{
							"t": "choice",
							"q": "三個角的 tan 都是正的，都是銳角，O 在三角形裡面。∠AOB 和 C 的關係：",
							"opts": [
								"∠AOB = 2∠C",
								"∠AOB = ∠C",
								"∠AOB = 180° − ∠C",
								"∠AOB = 2∠A"
							],
							"hint": "同弧所對的圓心角是圓周角的兩倍",
							"write": "(2)　∠AOB = 2C",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "二倍角 tan 2C = 2 tan C/(1 − tan^{2} C)：",
							"template": "tan∠AOB = tan 2C = 14/(1 − 49) = [0]",
							"ans": [
								"−7/24"
							],
							"hint": "14/(−48)",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "tan C = 7：對邊 7、鄰邊 1、斜邊 5√{2}。",
							"template": "(3)　sin C = [0]",
							"ans": [
								"7√2/10"
							],
							"hint": "對邊/斜邊，有理化",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "正弦定理 \\ol{AB} = 2R sin C：",
							"template": "\\ol{AB} = 10 · 7√{2}/10 = [0]",
							"ans": [
								"7√2"
							],
							"hint": "10 × 7√{2}/10",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "sin 2C = 2 sin C cos C = 7/25：",
							"template": "答：△AOB 面積 = (1/2) · 5 · 5 · sin 2C = [0]",
							"ans": [
								"7/2"
							],
							"hint": "(25/2) · (7/25)",
							"part": "(3)"
						}
					]
				},
				{
					"stem": "O 是 △ABC 的外心，tan A = 1、tan B = 2，外接圓半徑 5。\n(1) 求 tan C　(2) 求 tan∠AOB　(3) 求 \\ol{AB} 與 △AOB 的面積",
					"plot": {
						"x": [
							-5.8,
							5.8
						],
						"y": [
							-5.8,
							5.8
						],
						"geo": true,
						"h": 200,
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 5,
								"c": "dim"
							},
							{
								"k": "poly",
								"pts": [
									[
										-4.7434,
										-1.5811
									],
									[
										4.7434,
										-1.5811
									],
									[
										1.5811,
										4.7434
									]
								],
								"c": "cyan"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									-4.7434,
									-1.5811
								],
								"c": "pink",
								"at": 2
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									4.7434,
									-1.5811
								],
								"c": "pink",
								"at": 2
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 198.4349,
								"a1": 341.5651,
								"r": 14,
								"s": "",
								"at": 2
							},
							{
								"k": "label",
								"p": [
									-5.36,
									-1.7866
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									5.36,
									-1.7866
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									1.7392,
									5.2177
								],
								"s": "C"
							},
							{
								"k": "dot",
								"p": [
									0,
									0
								],
								"s": "O",
								"off": [
									6,
									-6
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "先算 tan(A + B)：",
							"template": "(1)　tan(A + B) = (1 + 2)/(1 − 1 · 2) = [0]",
							"ans": [
								"−3"
							],
							"hint": "分子 3，分母 −1",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "C = π − (A + B)：",
							"template": "tan C = −tan(A + B) = [0]",
							"ans": [
								"3"
							],
							"hint": "tan(π − θ) = −tan θ",
							"part": "(1)"
						},
						{
							"t": "choice",
							"q": "三個角的 tan 都是正的，都是銳角，O 在三角形裡面。∠AOB 和 C 的關係：",
							"opts": [
								"∠AOB = 2∠C",
								"∠AOB = ∠C",
								"∠AOB = 180° − ∠C",
								"∠AOB = 2∠A"
							],
							"hint": "同弧所對的圓心角是圓周角的兩倍",
							"write": "(2)　∠AOB = 2C",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "二倍角 tan 2C = 2 tan C/(1 − tan^{2} C)：",
							"template": "tan∠AOB = tan 2C = 6/(1 − 9) = [0]",
							"ans": [
								"−3/4"
							],
							"hint": "6/(−8)",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "tan C = 3：對邊 3、鄰邊 1、斜邊 √{10}。",
							"template": "(3)　sin C = [0]",
							"ans": [
								"3√10/10"
							],
							"hint": "對邊/斜邊，有理化",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "正弦定理 \\ol{AB} = 2R sin C：",
							"template": "\\ol{AB} = 10 · 3√{10}/10 = [0]",
							"ans": [
								"3√10"
							],
							"hint": "10 × 3√{10}/10",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "sin 2C = 2 sin C cos C = 3/5：",
							"template": "答：△AOB 面積 = (1/2) · 5 · 5 · sin 2C = [0]",
							"ans": [
								"15/2"
							],
							"hint": "(25/2) · (3/5)",
							"part": "(3)"
						}
					]
				}
			]
		},
		{
			"id": "tb_triple",
			"kind": "boss",
			"tier": 2,
			"title": "三倍角",
			"tmul": 1.6,
			"stem": "θ 是銳角，sin θ = 1/3。\n(1) 求 cos 2θ　(2) 求 sin 3θ　(3) 解 4cos^{3}x − 3cos x = 1/2（0 ≤ x ≤ π），求所有解的和",
			"plot": {
				"x": [
					-0.3,
					3.5
				],
				"y": [
					-1.4,
					1.4
				],
				"pi": 9,
				"pi_lab": 3,
				"curves": [
					{
						"f": "cos(3*x)",
						"c": "cyan",
						"dom": [
							0.0,
							3.1416
						],
						"at": 3
					},
					{
						"f": "0.5",
						"c": "pink",
						"dash": true,
						"at": 3
					}
				],
				"band": {
					"lo": 0.0,
					"hi": 3.1416,
					"at": 3
				}
			},
			"steps": [
				{
					"t": "fill",
					"q": "二倍角：",
					"template": "(1)　cos 2θ = 1 − 2 sin^{2}θ = [0]",
					"ans": [
						"7/9"
					],
					"hint": "1 − 2 · 1/9",
					"part": "(1)"
				},
				{
					"t": "choice",
					"q": "sin 3θ = sin(2θ + θ)，展開後全部換成 sin θ：",
					"opts": [
						"3 sin θ − 4 sin^{3}θ",
						"4 sin^{3}θ − 3 sin θ",
						"3 sin θ + 4 sin^{3}θ",
						"3 sin θ − sin^{3}θ"
					],
					"hint": "sin 2θ cos θ + cos 2θ sin θ = 2 sin θ cos^{2}θ + (1 − 2 sin^{2}θ) sin θ，再把 cos^{2}θ 換成 1 − sin^{2}θ",
					"write": "(2)　sin 3θ = 3 sin θ − 4 sin^{3}θ",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "代入 sin θ = 1/3：",
					"template": "sin 3θ = 3 · 1/3 − 4 · 1/27 = [0]",
					"ans": [
						"23/27"
					],
					"hint": "1 − 4/27",
					"part": "(2)"
				},
				{
					"t": "choice",
					"q": "同樣的方法，4cos^{3}x − 3cos x 是？",
					"opts": [
						"cos 3x",
						"sin 3x",
						"cos^{3} x",
						"−cos 3x"
					],
					"hint": "cos 3x = cos 2x cos x − sin 2x sin x，全部換成 cos x",
					"write": "(3)　4cos^{3}x − 3cos x = cos 3x",
					"part": "(3)"
				},
				{
					"t": "fill",
					"q": "0 ≤ 3x ≤ 3π，cos 3x = 1/2 的角（由小到大）：",
					"template": "3x = [0]π、[1]π、[2]π",
					"ans": [
						"1/3",
						"5/3",
						"7/3"
					],
					"hint": "cos(π/3) = 1/2；再看 2π ± π/3",
					"part": "(3)"
				},
				{
					"t": "fill",
					"q": "每個除以 3 再加起來：",
					"template": "答：和 = [0]π",
					"ans": [
						"13/9"
					],
					"hint": "(π/3 + 5π/3 + 7π/3)/3",
					"part": "(3)"
				}
			],
			"vars": [
				{
					"stem": "θ 是銳角，sin θ = 1/4。\n(1) 求 cos 2θ　(2) 求 sin 3θ　(3) 解 4cos^{3}x − 3cos x = −1/2（0 ≤ x ≤ π），求所有解的和",
					"plot": {
						"x": [
							-0.3,
							3.5
						],
						"y": [
							-1.4,
							1.4
						],
						"pi": 9,
						"pi_lab": 3,
						"curves": [
							{
								"f": "cos(3*x)",
								"c": "cyan",
								"dom": [
									0.0,
									3.1416
								],
								"at": 3
							},
							{
								"f": "-0.5",
								"c": "pink",
								"dash": true,
								"at": 3
							}
						],
						"band": {
							"lo": 0.0,
							"hi": 3.1416,
							"at": 3
						}
					},
					"steps": [
						{
							"t": "fill",
							"q": "二倍角：",
							"template": "(1)　cos 2θ = 1 − 2 sin^{2}θ = [0]",
							"ans": [
								"7/8"
							],
							"hint": "1 − 2 · 1/16",
							"part": "(1)"
						},
						{
							"t": "choice",
							"q": "sin 3θ = sin(2θ + θ)，展開後全部換成 sin θ：",
							"opts": [
								"3 sin θ − 4 sin^{3}θ",
								"4 sin^{3}θ − 3 sin θ",
								"3 sin θ + 4 sin^{3}θ",
								"3 sin θ − sin^{3}θ"
							],
							"hint": "sin 2θ cos θ + cos 2θ sin θ = 2 sin θ cos^{2}θ + (1 − 2 sin^{2}θ) sin θ，再把 cos^{2}θ 換成 1 − sin^{2}θ",
							"write": "(2)　sin 3θ = 3 sin θ − 4 sin^{3}θ",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "代入 sin θ = 1/4：",
							"template": "sin 3θ = 3 · 1/4 − 4 · 1/64 = [0]",
							"ans": [
								"11/16"
							],
							"hint": "3/4 − 1/16",
							"part": "(2)"
						},
						{
							"t": "choice",
							"q": "同樣的方法，4cos^{3}x − 3cos x 是？",
							"opts": [
								"cos 3x",
								"sin 3x",
								"cos^{3} x",
								"−cos 3x"
							],
							"hint": "cos 3x = cos 2x cos x − sin 2x sin x，全部換成 cos x",
							"write": "(3)　4cos^{3}x − 3cos x = cos 3x",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "0 ≤ 3x ≤ 3π，cos 3x = −1/2 的角（由小到大）：",
							"template": "3x = [0]π、[1]π、[2]π",
							"ans": [
								"2/3",
								"4/3",
								"8/3"
							],
							"hint": "cos(2π/3) = −1/2；再看 2π ± 2π/3",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "每個除以 3 再加起來：",
							"template": "答：和 = [0]π",
							"ans": [
								"14/9"
							],
							"hint": "(2π/3 + 4π/3 + 8π/3)/3",
							"part": "(3)"
						}
					]
				},
				{
					"stem": "θ 是銳角，sin θ = 2/5。\n(1) 求 cos 2θ　(2) 求 sin 3θ　(3) 解 4cos^{3}x − 3cos x = √{2}/2（0 ≤ x ≤ π），求所有解的和",
					"plot": {
						"x": [
							-0.3,
							3.5
						],
						"y": [
							-1.4,
							1.4
						],
						"pi": 12,
						"pi_lab": 4,
						"curves": [
							{
								"f": "cos(3*x)",
								"c": "cyan",
								"dom": [
									0.0,
									3.1416
								],
								"at": 3
							},
							{
								"f": "0.7071067811865476",
								"c": "pink",
								"dash": true,
								"at": 3
							}
						],
						"band": {
							"lo": 0.0,
							"hi": 3.1416,
							"at": 3
						}
					},
					"steps": [
						{
							"t": "fill",
							"q": "二倍角：",
							"template": "(1)　cos 2θ = 1 − 2 sin^{2}θ = [0]",
							"ans": [
								"17/25"
							],
							"hint": "1 − 2 · 4/25",
							"part": "(1)"
						},
						{
							"t": "choice",
							"q": "sin 3θ = sin(2θ + θ)，展開後全部換成 sin θ：",
							"opts": [
								"3 sin θ − 4 sin^{3}θ",
								"4 sin^{3}θ − 3 sin θ",
								"3 sin θ + 4 sin^{3}θ",
								"3 sin θ − sin^{3}θ"
							],
							"hint": "sin 2θ cos θ + cos 2θ sin θ = 2 sin θ cos^{2}θ + (1 − 2 sin^{2}θ) sin θ，再把 cos^{2}θ 換成 1 − sin^{2}θ",
							"write": "(2)　sin 3θ = 3 sin θ − 4 sin^{3}θ",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "代入 sin θ = 2/5：",
							"template": "sin 3θ = 3 · 2/5 − 4 · 8/125 = [0]",
							"ans": [
								"118/125"
							],
							"hint": "6/5 − 32/125",
							"part": "(2)"
						},
						{
							"t": "choice",
							"q": "同樣的方法，4cos^{3}x − 3cos x 是？",
							"opts": [
								"cos 3x",
								"sin 3x",
								"cos^{3} x",
								"−cos 3x"
							],
							"hint": "cos 3x = cos 2x cos x − sin 2x sin x，全部換成 cos x",
							"write": "(3)　4cos^{3}x − 3cos x = cos 3x",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "0 ≤ 3x ≤ 3π，cos 3x = √{2}/2 的角（由小到大）：",
							"template": "3x = [0]π、[1]π、[2]π",
							"ans": [
								"1/4",
								"7/4",
								"9/4"
							],
							"hint": "cos(π/4) = √{2}/2；再看 2π ± π/4",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "每個除以 3 再加起來：",
							"template": "答：和 = [0]π",
							"ans": [
								"17/12"
							],
							"hint": "(π/4 + 7π/4 + 9π/4)/3",
							"part": "(3)"
						}
					]
				}
			]
		},
		{
			"id": "tb_segment",
			"kind": "boss",
			"tier": 2,
			"title": "弓形草皮",
			"tmul": 1.6,
			"stem": "半徑 6 公尺的圓形廣場上，弦 \\ol{AB} 所對的圓心角是 2π/3。弦和劣弧 AB 圍成的弓形要鋪草皮、外圈圍上燈條。\n(1) 劣弧長　(2) 扇形 OAB 與 △OAB 的面積　(3) 弓形的面積與周長",
			"plot": {
				"x": [
					-7.0,
					7.0
				],
				"y": [
					-7.0,
					7.0
				],
				"geo": true,
				"h": 200,
				"shapes": [
					{
						"k": "circle",
						"o": [
							0,
							0
						],
						"r": 6,
						"c": "dim"
					},
					{
						"k": "sector",
						"o": [
							0,
							0
						],
						"r": 6,
						"a0": 30,
						"a1": 150,
						"c": "lime",
						"fill": "lime",
						"alpha": 0.15,
						"at": 1
					},
					{
						"k": "poly",
						"pts": [
							[
								0,
								0
							],
							[
								5.1962,
								3
							],
							[
								-5.1962,
								3
							]
						],
						"c": "cyan",
						"fill": "cyan",
						"alpha": 0.12,
						"at": 2
					},
					{
						"k": "seg",
						"a": [
							5.1962,
							3
						],
						"b": [
							-5.1962,
							3
						],
						"c": "gold",
						"w": 2.6
					},
					{
						"k": "angle",
						"o": [
							0,
							0
						],
						"a0": 30,
						"a1": 150,
						"r": 16,
						"s": "θ"
					},
					{
						"k": "dot",
						"p": [
							5.1962,
							3
						],
						"s": "A",
						"off": [
							8,
							-6
						]
					},
					{
						"k": "dot",
						"p": [
							-5.1962,
							3
						],
						"s": "B",
						"off": [
							-18,
							-6
						]
					},
					{
						"k": "dot",
						"p": [
							0,
							0
						],
						"s": "O",
						"off": [
							6,
							14
						]
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "弧長 = 半徑 × 圓心角：",
					"template": "(1)　弧長 = [0]π",
					"ans": [
						"4"
					],
					"hint": "6 × 2π/3",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "扇形面積 = (1/2) r^{2} θ：",
					"template": "(2)　扇形面積 = [0]π",
					"ans": [
						"12"
					],
					"hint": "(1/2) · 36 · 2π/3",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "△OAB 的面積 = (1/2) r^{2} sin θ：",
					"template": "△OAB = (1/2) · 36 · sin(2π/3) = [0]",
					"ans": [
						"9√3"
					],
					"hint": "sin(2π/3) = √{3}/2",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "弓形 = 扇形 − 三角形：",
					"template": "(3)　弓形面積 = [0]π − [1]√3",
					"ans": [
						"12",
						"9"
					],
					"hint": "12π − 9√{3}",
					"part": "(3)"
				},
				{
					"t": "fill",
					"q": "弦長：從 O 作 \\ol{AB} 的垂線，切成兩個直角三角形，\\ol{AB} = 2r sin(θ/2)。",
					"template": "\\ol{AB} = 12 sin(π/3) = [0]",
					"ans": [
						"6√3"
					],
					"hint": "sin(π/3) = √{3}/2",
					"part": "(3)"
				},
				{
					"t": "fill",
					"q": "周長 = 弧長 + 弦長：",
					"template": "答：周長 = [0]π + [1]√3",
					"ans": [
						"4",
						"6"
					],
					"hint": "4π + 6√{3}",
					"part": "(3)"
				}
			],
			"vars": [
				{
					"stem": "半徑 4 公尺的圓形廣場上，弦 \\ol{AB} 所對的圓心角是 π/2。弦和劣弧 AB 圍成的弓形要鋪草皮、外圈圍上燈條。\n(1) 劣弧長　(2) 扇形 OAB 與 △OAB 的面積　(3) 弓形的面積與周長",
					"plot": {
						"x": [
							-5.0,
							5.0
						],
						"y": [
							-5.0,
							5.0
						],
						"geo": true,
						"h": 200,
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 4,
								"c": "dim"
							},
							{
								"k": "sector",
								"o": [
									0,
									0
								],
								"r": 4,
								"a0": 45,
								"a1": 135,
								"c": "lime",
								"fill": "lime",
								"alpha": 0.15,
								"at": 1
							},
							{
								"k": "poly",
								"pts": [
									[
										0,
										0
									],
									[
										2.8284,
										2.8284
									],
									[
										-2.8284,
										2.8284
									]
								],
								"c": "cyan",
								"fill": "cyan",
								"alpha": 0.12,
								"at": 2
							},
							{
								"k": "seg",
								"a": [
									2.8284,
									2.8284
								],
								"b": [
									-2.8284,
									2.8284
								],
								"c": "gold",
								"w": 2.6
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 45,
								"a1": 135,
								"r": 16,
								"s": "θ"
							},
							{
								"k": "dot",
								"p": [
									2.8284,
									2.8284
								],
								"s": "A",
								"off": [
									8,
									-6
								]
							},
							{
								"k": "dot",
								"p": [
									-2.8284,
									2.8284
								],
								"s": "B",
								"off": [
									-18,
									-6
								]
							},
							{
								"k": "dot",
								"p": [
									0,
									0
								],
								"s": "O",
								"off": [
									6,
									14
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "弧長 = 半徑 × 圓心角：",
							"template": "(1)　弧長 = [0]π",
							"ans": [
								"2"
							],
							"hint": "4 × π/2",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "扇形面積 = (1/2) r^{2} θ：",
							"template": "(2)　扇形面積 = [0]π",
							"ans": [
								"4"
							],
							"hint": "(1/2) · 16 · π/2",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "△OAB 的面積 = (1/2) r^{2} sin θ：",
							"template": "△OAB = (1/2) · 16 · sin(π/2) = [0]",
							"ans": [
								"8"
							],
							"hint": "sin(π/2) = 1",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "弓形 = 扇形 − 三角形：",
							"template": "(3)　弓形面積 = [0]π − [1]",
							"ans": [
								"4",
								"8"
							],
							"hint": "4π − 8",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "弦長：從 O 作 \\ol{AB} 的垂線，切成兩個直角三角形，\\ol{AB} = 2r sin(θ/2)。",
							"template": "\\ol{AB} = 8 sin(π/4) = [0]",
							"ans": [
								"4√2"
							],
							"hint": "sin(π/4) = √{2}/2",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "周長 = 弧長 + 弦長：",
							"template": "答：周長 = [0]π + [1]√2",
							"ans": [
								"2",
								"4"
							],
							"hint": "2π + 4√{2}",
							"part": "(3)"
						}
					]
				},
				{
					"stem": "半徑 6 公尺的圓形廣場上，弦 \\ol{AB} 所對的圓心角是 π/3。弦和劣弧 AB 圍成的弓形要鋪草皮、外圈圍上燈條。\n(1) 劣弧長　(2) 扇形 OAB 與 △OAB 的面積　(3) 弓形的面積與周長",
					"plot": {
						"x": [
							-7.0,
							7.0
						],
						"y": [
							-7.0,
							7.0
						],
						"geo": true,
						"h": 200,
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 6,
								"c": "dim"
							},
							{
								"k": "sector",
								"o": [
									0,
									0
								],
								"r": 6,
								"a0": 60,
								"a1": 120,
								"c": "lime",
								"fill": "lime",
								"alpha": 0.15,
								"at": 1
							},
							{
								"k": "poly",
								"pts": [
									[
										0,
										0
									],
									[
										3,
										5.1962
									],
									[
										-3,
										5.1962
									]
								],
								"c": "cyan",
								"fill": "cyan",
								"alpha": 0.12,
								"at": 2
							},
							{
								"k": "seg",
								"a": [
									3,
									5.1962
								],
								"b": [
									-3,
									5.1962
								],
								"c": "gold",
								"w": 2.6
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 60,
								"a1": 120,
								"r": 16,
								"s": "θ"
							},
							{
								"k": "dot",
								"p": [
									3,
									5.1962
								],
								"s": "A",
								"off": [
									8,
									-6
								]
							},
							{
								"k": "dot",
								"p": [
									-3,
									5.1962
								],
								"s": "B",
								"off": [
									-18,
									-6
								]
							},
							{
								"k": "dot",
								"p": [
									0,
									0
								],
								"s": "O",
								"off": [
									6,
									14
								]
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "弧長 = 半徑 × 圓心角：",
							"template": "(1)　弧長 = [0]π",
							"ans": [
								"2"
							],
							"hint": "6 × π/3",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "扇形面積 = (1/2) r^{2} θ：",
							"template": "(2)　扇形面積 = [0]π",
							"ans": [
								"6"
							],
							"hint": "(1/2) · 36 · π/3",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "△OAB 的面積 = (1/2) r^{2} sin θ：",
							"template": "△OAB = (1/2) · 36 · sin(π/3) = [0]",
							"ans": [
								"9√3"
							],
							"hint": "sin(π/3) = √{3}/2",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "弓形 = 扇形 − 三角形：",
							"template": "(3)　弓形面積 = [0]π − [1]√3",
							"ans": [
								"6",
								"9"
							],
							"hint": "6π − 9√{3}",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "弦長：從 O 作 \\ol{AB} 的垂線，切成兩個直角三角形，\\ol{AB} = 2r sin(θ/2)。",
							"template": "\\ol{AB} = 12 sin(π/6) = [0]",
							"ans": [
								"6"
							],
							"hint": "sin(π/6) = 1/2",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "周長 = 弧長 + 弦長：",
							"template": "答：周長 = [0]π + [1]",
							"ans": [
								"2",
								"6"
							],
							"hint": "2π + 6",
							"part": "(3)"
						}
					]
				}
			]
		},
		{
			"id": "tb_clock",
			"kind": "boss",
			"tier": 2,
			"title": "時鐘的兩根針",
			"tmul": 1.6,
			"stem": "時鐘的分針長 6 公分、時針長 4 公分。\n(1) 分針、時針每分鐘各轉幾弧度？(2) 2 點整時，兩針尖端相距多遠？(3) 2 點整之後，再過幾分鐘兩針第一次重合？",
			"plot": {
				"x": [
					-7.6,
					7.6
				],
				"y": [
					-7.6,
					7.6
				],
				"geo": true,
				"h": 200,
				"shapes": [
					{
						"k": "circle",
						"o": [
							0,
							0
						],
						"r": 7,
						"c": "dim"
					},
					{
						"k": "seg",
						"a": [
							0,
							6.4
						],
						"b": [
							0,
							7
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							3.2,
							5.5426
						],
						"b": [
							3.5,
							6.0622
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							5.5426,
							3.2
						],
						"b": [
							6.0622,
							3.5
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							6.4,
							0
						],
						"b": [
							7,
							0
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							5.5426,
							-3.2
						],
						"b": [
							6.0622,
							-3.5
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							3.2,
							-5.5426
						],
						"b": [
							3.5,
							-6.0622
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							0,
							-6.4
						],
						"b": [
							0,
							-7
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							-3.2,
							-5.5426
						],
						"b": [
							-3.5,
							-6.0622
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							-5.5426,
							-3.2
						],
						"b": [
							-6.0622,
							-3.5
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							-6.4,
							0
						],
						"b": [
							-7,
							0
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							-5.5426,
							3.2
						],
						"b": [
							-6.0622,
							3.5
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							-3.2,
							5.5426
						],
						"b": [
							-3.5,
							6.0622
						],
						"c": "faint"
					},
					{
						"k": "seg",
						"a": [
							0,
							0
						],
						"b": [
							0,
							6
						],
						"c": "cyan",
						"w": 2.6
					},
					{
						"k": "seg",
						"a": [
							0,
							0
						],
						"b": [
							3.4641,
							2
						],
						"c": "pink",
						"w": 3.2
					},
					{
						"k": "angle",
						"o": [
							0,
							0
						],
						"a0": 30,
						"a1": 90,
						"r": 16,
						"s": "",
						"at": 1
					},
					{
						"k": "seg",
						"a": [
							0,
							6
						],
						"b": [
							3.4641,
							2
						],
						"c": "gold",
						"dash": true,
						"at": 2
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "分針 60 分鐘轉一圈，時針 12 小時（720 分鐘）轉一圈：",
					"template": "(1)　分針 [0]π，時針 [1]π",
					"ans": [
						"1/30",
						"1/360"
					],
					"hint": "2π/60、2π/720",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "2 點整：分針指著 12，時針指著 2，中間隔 2 格（一格 π/6）：",
					"template": "(2)　夾角 = [0]π",
					"ans": [
						"1/3"
					],
					"hint": "2 × π/6",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "兩針和中心構成三角形，用餘弦定理：",
					"template": "d^{2} = 6^{2} + 4^{2} − 2 · 6 · 4 · cos(π/3) = [0]",
					"ans": [
						"28"
					],
					"hint": "cos(π/3) = 1/2",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "開根號：",
					"template": "d = √{28} = [0] 公分",
					"ans": [
						"2√7"
					],
					"hint": "28 = 4 × 7",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "分針每分鐘比時針多轉：",
					"template": "(3)　π/30 − π/360 = [0]π",
					"ans": [
						"11/360"
					],
					"hint": "12/360 − 1/360",
					"part": "(3)"
				},
				{
					"t": "fill",
					"q": "分針要追上時針領先的 π/3：",
					"template": "答：π/3 ÷ (11π/360) = [0] 分鐘",
					"ans": [
						"120/11"
					],
					"hint": "1/3 × 360/11",
					"part": "(3)"
				}
			],
			"vars": [
				{
					"stem": "時鐘的分針長 6 公分、時針長 4 公分。\n(1) 分針、時針每分鐘各轉幾弧度？(2) 3 點整時，兩針尖端相距多遠？(3) 3 點整之後，再過幾分鐘兩針第一次重合？",
					"plot": {
						"x": [
							-7.6,
							7.6
						],
						"y": [
							-7.6,
							7.6
						],
						"geo": true,
						"h": 200,
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 7,
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									0,
									6.4
								],
								"b": [
									0,
									7
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									3.2,
									5.5426
								],
								"b": [
									3.5,
									6.0622
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									5.5426,
									3.2
								],
								"b": [
									6.0622,
									3.5
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									6.4,
									0
								],
								"b": [
									7,
									0
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									5.5426,
									-3.2
								],
								"b": [
									6.0622,
									-3.5
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									3.2,
									-5.5426
								],
								"b": [
									3.5,
									-6.0622
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									0,
									-6.4
								],
								"b": [
									0,
									-7
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-3.2,
									-5.5426
								],
								"b": [
									-3.5,
									-6.0622
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-5.5426,
									-3.2
								],
								"b": [
									-6.0622,
									-3.5
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-6.4,
									0
								],
								"b": [
									-7,
									0
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-5.5426,
									3.2
								],
								"b": [
									-6.0622,
									3.5
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-3.2,
									5.5426
								],
								"b": [
									-3.5,
									6.0622
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									0,
									6
								],
								"c": "cyan",
								"w": 2.6
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									4,
									0
								],
								"c": "pink",
								"w": 3.2
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 0,
								"a1": 90,
								"r": 16,
								"s": "",
								"at": 1
							},
							{
								"k": "seg",
								"a": [
									0,
									6
								],
								"b": [
									4,
									0
								],
								"c": "gold",
								"dash": true,
								"at": 2
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "分針 60 分鐘轉一圈，時針 12 小時（720 分鐘）轉一圈：",
							"template": "(1)　分針 [0]π，時針 [1]π",
							"ans": [
								"1/30",
								"1/360"
							],
							"hint": "2π/60、2π/720",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "3 點整：分針指著 12，時針指著 3，中間隔 3 格（一格 π/6）：",
							"template": "(2)　夾角 = [0]π",
							"ans": [
								"1/2"
							],
							"hint": "3 × π/6",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "兩針和中心構成三角形，用餘弦定理：",
							"template": "d^{2} = 6^{2} + 4^{2} − 2 · 6 · 4 · cos(π/2) = [0]",
							"ans": [
								"52"
							],
							"hint": "cos(π/2) = 0",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "開根號：",
							"template": "d = √{52} = [0] 公分",
							"ans": [
								"2√13"
							],
							"hint": "52 = 4 × 13",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "分針每分鐘比時針多轉：",
							"template": "(3)　π/30 − π/360 = [0]π",
							"ans": [
								"11/360"
							],
							"hint": "12/360 − 1/360",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "分針要追上時針領先的 π/2：",
							"template": "答：π/2 ÷ (11π/360) = [0] 分鐘",
							"ans": [
								"180/11"
							],
							"hint": "1/2 × 360/11",
							"part": "(3)"
						}
					]
				},
				{
					"stem": "時鐘的分針長 6 公分、時針長 4 公分。\n(1) 分針、時針每分鐘各轉幾弧度？(2) 4 點整時，兩針尖端相距多遠？(3) 4 點整之後，再過幾分鐘兩針第一次重合？",
					"plot": {
						"x": [
							-7.6,
							7.6
						],
						"y": [
							-7.6,
							7.6
						],
						"geo": true,
						"h": 200,
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 7,
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									0,
									6.4
								],
								"b": [
									0,
									7
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									3.2,
									5.5426
								],
								"b": [
									3.5,
									6.0622
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									5.5426,
									3.2
								],
								"b": [
									6.0622,
									3.5
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									6.4,
									0
								],
								"b": [
									7,
									0
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									5.5426,
									-3.2
								],
								"b": [
									6.0622,
									-3.5
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									3.2,
									-5.5426
								],
								"b": [
									3.5,
									-6.0622
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									0,
									-6.4
								],
								"b": [
									0,
									-7
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-3.2,
									-5.5426
								],
								"b": [
									-3.5,
									-6.0622
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-5.5426,
									-3.2
								],
								"b": [
									-6.0622,
									-3.5
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-6.4,
									0
								],
								"b": [
									-7,
									0
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-5.5426,
									3.2
								],
								"b": [
									-6.0622,
									3.5
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									-3.2,
									5.5426
								],
								"b": [
									-3.5,
									6.0622
								],
								"c": "faint"
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									0,
									6
								],
								"c": "cyan",
								"w": 2.6
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									3.4641,
									-2
								],
								"c": "pink",
								"w": 3.2
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": -30,
								"a1": 90,
								"r": 16,
								"s": "",
								"at": 1
							},
							{
								"k": "seg",
								"a": [
									0,
									6
								],
								"b": [
									3.4641,
									-2
								],
								"c": "gold",
								"dash": true,
								"at": 2
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "分針 60 分鐘轉一圈，時針 12 小時（720 分鐘）轉一圈：",
							"template": "(1)　分針 [0]π，時針 [1]π",
							"ans": [
								"1/30",
								"1/360"
							],
							"hint": "2π/60、2π/720",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "4 點整：分針指著 12，時針指著 4，中間隔 4 格（一格 π/6）：",
							"template": "(2)　夾角 = [0]π",
							"ans": [
								"2/3"
							],
							"hint": "4 × π/6",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "兩針和中心構成三角形，用餘弦定理：",
							"template": "d^{2} = 6^{2} + 4^{2} − 2 · 6 · 4 · cos(2π/3) = [0]",
							"ans": [
								"76"
							],
							"hint": "cos(2π/3) = −1/2",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "開根號：",
							"template": "d = √{76} = [0] 公分",
							"ans": [
								"2√19"
							],
							"hint": "76 = 4 × 19",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "分針每分鐘比時針多轉：",
							"template": "(3)　π/30 − π/360 = [0]π",
							"ans": [
								"11/360"
							],
							"hint": "12/360 − 1/360",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "分針要追上時針領先的 2π/3：",
							"template": "答：2π/3 ÷ (11π/360) = [0] 分鐘",
							"ans": [
								"240/11"
							],
							"hint": "2/3 × 360/11",
							"part": "(3)"
						}
					]
				}
			]
		},
		{
			"id": "tb_homog",
			"kind": "boss",
			"tier": 2,
			"title": "只給 tan",
			"tmul": 1.6,
			"stem": "tan θ = 2。求\n(1) (sin θ + cos θ)/(sin θ − cos θ)　(2) sin θ cos θ 與 cos 2θ　(3) tan(θ + π/4)",
			"steps": [
				{
					"t": "choice",
					"q": "(1) 分子、分母都是 sin、cos 的一次式，同除以 cos θ：",
					"opts": [
						"(tan θ + 1)/(tan θ − 1)",
						"(tan θ − 1)/(tan θ + 1)",
						"(1 + tan θ)/(1 − tan θ)",
						"tan θ + 1"
					],
					"hint": "sin θ/cos θ = tan θ，cos θ/cos θ = 1",
					"write": "(1)　原式 = (tan θ + 1)/(tan θ − 1)",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "代入 tan θ = 2：",
					"template": "(2 + 1)/(2 − 1) = [0]",
					"ans": [
						"3"
					],
					"hint": "3/1",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "二次式：sin θ cos θ = sin θ cos θ/(sin^{2}θ + cos^{2}θ)，同除以 cos^{2}θ：",
					"template": "(2)　sin θ cos θ = tan θ/(1 + tan^{2}θ) = [0]",
					"ans": [
						"2/5"
					],
					"hint": "2/(1 + 4)",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "同樣的方法：",
					"template": "cos 2θ = (cos^{2}θ − sin^{2}θ)/(cos^{2}θ + sin^{2}θ) = (1 − tan^{2}θ)/(1 + tan^{2}θ) = [0]",
					"ans": [
						"−3/5"
					],
					"hint": "(1 − 4)/(1 + 4)",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "和角公式，tan(π/4) = 1：",
					"template": "答：(3)　tan(θ + π/4) = (tan θ + 1)/(1 − tan θ) = [0]",
					"ans": [
						"−3"
					],
					"hint": "3/(−1)",
					"part": "(3)"
				}
			],
			"vars": [
				{
					"stem": "tan θ = 3。求\n(1) (sin θ + cos θ)/(sin θ − cos θ)　(2) sin θ cos θ 與 cos 2θ　(3) tan(θ + π/4)",
					"steps": [
						{
							"t": "choice",
							"q": "(1) 分子、分母都是 sin、cos 的一次式，同除以 cos θ：",
							"opts": [
								"(tan θ + 1)/(tan θ − 1)",
								"(tan θ − 1)/(tan θ + 1)",
								"(1 + tan θ)/(1 − tan θ)",
								"tan θ + 1"
							],
							"hint": "sin θ/cos θ = tan θ，cos θ/cos θ = 1",
							"write": "(1)　原式 = (tan θ + 1)/(tan θ − 1)",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "代入 tan θ = 3：",
							"template": "(3 + 1)/(3 − 1) = [0]",
							"ans": [
								"2"
							],
							"hint": "4/2",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "二次式：sin θ cos θ = sin θ cos θ/(sin^{2}θ + cos^{2}θ)，同除以 cos^{2}θ：",
							"template": "(2)　sin θ cos θ = tan θ/(1 + tan^{2}θ) = [0]",
							"ans": [
								"3/10"
							],
							"hint": "3/(1 + 9)",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "同樣的方法：",
							"template": "cos 2θ = (cos^{2}θ − sin^{2}θ)/(cos^{2}θ + sin^{2}θ) = (1 − tan^{2}θ)/(1 + tan^{2}θ) = [0]",
							"ans": [
								"−4/5"
							],
							"hint": "(1 − 9)/(1 + 9)",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "和角公式，tan(π/4) = 1：",
							"template": "答：(3)　tan(θ + π/4) = (tan θ + 1)/(1 − tan θ) = [0]",
							"ans": [
								"−2"
							],
							"hint": "4/(−2)",
							"part": "(3)"
						}
					]
				},
				{
					"stem": "tan θ = 1/2。求\n(1) (sin θ + cos θ)/(sin θ − cos θ)　(2) sin θ cos θ 與 cos 2θ　(3) tan(θ + π/4)",
					"steps": [
						{
							"t": "choice",
							"q": "(1) 分子、分母都是 sin、cos 的一次式，同除以 cos θ：",
							"opts": [
								"(tan θ + 1)/(tan θ − 1)",
								"(tan θ − 1)/(tan θ + 1)",
								"(1 + tan θ)/(1 − tan θ)",
								"tan θ + 1"
							],
							"hint": "sin θ/cos θ = tan θ，cos θ/cos θ = 1",
							"write": "(1)　原式 = (tan θ + 1)/(tan θ − 1)",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "代入 tan θ = 1/2：",
							"template": "(1/2 + 1)/(1/2 − 1) = [0]",
							"ans": [
								"−3"
							],
							"hint": "(3/2)/(−1/2)",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "二次式：sin θ cos θ = sin θ cos θ/(sin^{2}θ + cos^{2}θ)，同除以 cos^{2}θ：",
							"template": "(2)　sin θ cos θ = tan θ/(1 + tan^{2}θ) = [0]",
							"ans": [
								"2/5"
							],
							"hint": "(1/2)/(1 + 1/4)",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "同樣的方法：",
							"template": "cos 2θ = (cos^{2}θ − sin^{2}θ)/(cos^{2}θ + sin^{2}θ) = (1 − tan^{2}θ)/(1 + tan^{2}θ) = [0]",
							"ans": [
								"3/5"
							],
							"hint": "(1 − 1/4)/(1 + 1/4)",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "和角公式，tan(π/4) = 1：",
							"template": "答：(3)　tan(θ + π/4) = (tan θ + 1)/(1 − tan θ) = [0]",
							"ans": [
								"3"
							],
							"hint": "(3/2)/(1/2)",
							"part": "(3)"
						}
					]
				}
			]
		},
		{
			"id": "tb_rect",
			"kind": "boss",
			"tier": 3,
			"title": "扇形裡的矩形",
			"tmul": 1.65,
			"stem": "扇形 OAB 的半徑 6、圓心角 π/3。P 在弧上，∠POA = θ；矩形 PQRS 的一邊 \\ol{QR} 在 \\ol{OA} 上，頂點 S 在 \\ol{OB} 上。\n(1) 把矩形面積寫成 θ 的式子　(2) θ 是多少時面積最大？最大面積是多少？",
			"plot": {
				"x": [
					-0.6,
					6.6
				],
				"y": [
					-0.6,
					5.7962
				],
				"geo": true,
				"h": 190,
				"shapes": [
					{
						"k": "sector",
						"o": [
							0,
							0
						],
						"r": 6,
						"a0": 0,
						"a1": 60,
						"c": "cyan",
						"fill": "cyan",
						"alpha": 0.08
					},
					{
						"k": "poly",
						"pts": [
							[
								1.7321,
								0
							],
							[
								5.1962,
								0
							],
							[
								5.1962,
								3
							],
							[
								1.7321,
								3
							]
						],
						"c": "gold",
						"fill": "gold",
						"alpha": 0.15
					},
					{
						"k": "seg",
						"a": [
							0,
							0
						],
						"b": [
							5.1962,
							3
						],
						"c": "faint",
						"dash": true
					},
					{
						"k": "angle",
						"o": [
							0,
							0
						],
						"a0": 0,
						"a1": 30,
						"r": 26,
						"s": "θ"
					},
					{
						"k": "dot",
						"p": [
							5.1962,
							3
						],
						"s": "P",
						"off": [
							8,
							-6
						]
					},
					{
						"k": "label",
						"p": [
							1.3821,
							3.3
						],
						"s": "S"
					},
					{
						"k": "label",
						"p": [
							5.1962,
							-0.4
						],
						"s": "Q"
					},
					{
						"k": "label",
						"p": [
							1.7321,
							-0.4
						],
						"s": "R"
					},
					{
						"k": "label",
						"p": [
							-0.3,
							-0.3
						],
						"s": "O"
					},
					{
						"k": "label",
						"p": [
							6.3,
							-0.3
						],
						"s": "A"
					},
					{
						"k": "label",
						"p": [
							2.8,
							5.4962
						],
						"s": "B"
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "P 的高 = 6 sin θ。S 和 P 一樣高，S 在 \\ol{OB} 上，橫坐標 = 高/tan(π/3)：",
					"template": "(1)　寬 = 6 cos θ − [0] sin θ",
					"ans": [
						"2√3"
					],
					"hint": "6/√{3} = 2√{3}",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "面積 = 高 × 寬，再用二倍角降次：",
					"template": "面積 = [0] sin 2θ + 6√{3} cos 2θ − 6√{3}",
					"ans": [
						"18"
					],
					"hint": "6^{2} sin θ cos θ = (36/2) sin 2θ，sin^{2}θ = (1 − cos 2θ)/2",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "前兩項疊合：",
					"template": "18 sin 2θ + 6√{3} cos 2θ = [0] sin(2θ + [1]π)",
					"ans": [
						"12√3",
						"1/6"
					],
					"hint": "√{324 + 108} = 12√{3}",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "0 < θ < π/3 ⇒ π/6 < 2θ + π/6 < 5π/6，sin 可以取到 1：",
					"template": "(2)　2θ + π/6 = π/2 ⇒ θ = [0]π",
					"ans": [
						"1/6"
					],
					"hint": "2θ = π/3",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "最大面積：",
					"template": "答：12√{3} − 6√{3} = [0]",
					"ans": [
						"6√3"
					],
					"hint": "12√{3} − 6√{3}",
					"part": "(2)"
				}
			],
			"vars": [
				{
					"stem": "半徑 5 的半圓，矩形 ABCD 的 A、B 在直徑上，C、D 在半圓上，O 是圓心，∠COB = θ（0 < θ < π/2）。\n(1) 用 θ 表示 \\ol{AB}、\\ol{BC}　(2) 矩形周長的最大值　(3) 周長最大時，矩形的面積",
					"plot": {
						"x": [
							-5.6,
							5.6
						],
						"y": [
							-0.6,
							5.6
						],
						"geo": true,
						"h": 160,
						"shapes": [
							{
								"k": "sector",
								"o": [
									0,
									0
								],
								"r": 5,
								"a0": 0,
								"a1": 180,
								"c": "cyan",
								"fill": "cyan",
								"alpha": 0.08
							},
							{
								"k": "seg",
								"a": [
									-5,
									0
								],
								"b": [
									5,
									0
								],
								"c": "cyan"
							},
							{
								"k": "poly",
								"pts": [
									[
										-4.4721,
										0
									],
									[
										4.4721,
										0
									],
									[
										4.4721,
										2.2361
									],
									[
										-4.4721,
										2.2361
									]
								],
								"c": "gold",
								"fill": "gold",
								"alpha": 0.15
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									4.4721,
									2.2361
								],
								"c": "faint",
								"dash": true
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 0,
								"a1": 26.5651,
								"r": 26,
								"s": "θ"
							},
							{
								"k": "label",
								"p": [
									-4.4721,
									-0.4
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									4.4721,
									-0.4
								],
								"s": "B"
							},
							{
								"k": "dot",
								"p": [
									4.4721,
									2.2361
								],
								"s": "C",
								"off": [
									8,
									-6
								]
							},
							{
								"k": "label",
								"p": [
									-4.8221,
									2.5361
								],
								"s": "D"
							},
							{
								"k": "label",
								"p": [
									0,
									-0.4
								],
								"s": "O"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "C 的坐標是 (5 cos θ, 5 sin θ)，矩形左右對稱：",
							"template": "(1)　\\ol{AB} = [0] cos θ，\\ol{BC} = [1] sin θ",
							"ans": [
								"10",
								"5"
							],
							"hint": "\\ol{OB} = 5 cos θ，\\ol{AB} = 2\\ol{OB}",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "周長 = 2(\\ol{AB} + \\ol{BC})：",
							"template": "(2)　周長 = [0] cos θ + [1] sin θ",
							"ans": [
								"20",
								"10"
							],
							"hint": "2 × 10、2 × 5",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "提出 10 再疊合：10(2 cos θ + sin θ)。",
							"template": "周長最長 = [0]√5",
							"ans": [
								"10"
							],
							"hint": "10 √{2^{2} + 1^{2}}",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "最長時 cos θ : sin θ = 2 : 1（和係數成比例）：",
							"template": "(3)　tan θ = [0]",
							"ans": [
								"1/2"
							],
							"hint": "sin θ/cos θ",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "sin θ = √{5}/5、cos θ = 2√{5}/5：",
							"template": "答：面積 = \\ol{AB} · \\ol{BC} = [0]",
							"ans": [
								"20"
							],
							"hint": "10 cos θ × 5 sin θ",
							"part": "(3)"
						}
					]
				},
				{
					"stem": "半徑 4 的四分之一圓 OAB（∠AOB = π/2），P 在弧上，∠POA = θ。矩形 OQPS 的 Q 在 \\ol{OA} 上、S 在 \\ol{OB} 上。\n(1) 用 θ 表示矩形的面積　(2) 面積的最大值與此時的 θ　(3) 矩形周長的最大值",
					"plot": {
						"x": [
							-0.6,
							4.6
						],
						"y": [
							-0.6,
							4.6
						],
						"geo": true,
						"h": 180,
						"shapes": [
							{
								"k": "sector",
								"o": [
									0,
									0
								],
								"r": 4,
								"a0": 0,
								"a1": 90,
								"c": "cyan",
								"fill": "cyan",
								"alpha": 0.08
							},
							{
								"k": "poly",
								"pts": [
									[
										0,
										0
									],
									[
										2.8284,
										0
									],
									[
										2.8284,
										2.8284
									],
									[
										0,
										2.8284
									]
								],
								"c": "gold",
								"fill": "gold",
								"alpha": 0.15
							},
							{
								"k": "seg",
								"a": [
									0,
									0
								],
								"b": [
									2.8284,
									2.8284
								],
								"c": "faint",
								"dash": true
							},
							{
								"k": "angle",
								"o": [
									0,
									0
								],
								"a0": 0,
								"a1": 45,
								"r": 26,
								"s": "θ"
							},
							{
								"k": "dot",
								"p": [
									2.8284,
									2.8284
								],
								"s": "P",
								"off": [
									8,
									-6
								]
							},
							{
								"k": "label",
								"p": [
									2.8284,
									-0.4
								],
								"s": "Q"
							},
							{
								"k": "label",
								"p": [
									-0.35,
									2.8284
								],
								"s": "S"
							},
							{
								"k": "label",
								"p": [
									-0.3,
									-0.3
								],
								"s": "O"
							},
							{
								"k": "label",
								"p": [
									4.3,
									-0.3
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									-0.3,
									4.3
								],
								"s": "B"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "直角 △OQP：\\ol{OP} = 4 是斜邊。",
							"template": "(1)　\\ol{OQ} = [0] cos θ，\\ol{OS} = \\ol{QP} = [1] sin θ",
							"ans": [
								"4",
								"4"
							],
							"hint": "鄰邊、對邊",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "面積 = \\ol{OQ} · \\ol{OS}，用二倍角：",
							"template": "面積 = [0] sin θ cos θ = [1] sin 2θ",
							"ans": [
								"16",
								"8"
							],
							"hint": "sin θ cos θ = (1/2) sin 2θ",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "0 < 2θ < π，sin 2θ 最大是 1：",
							"template": "(2)　面積最大 [0]，此時 θ = [1]π",
							"ans": [
								"8",
								"1/4"
							],
							"hint": "2θ = π/2",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "周長 = 8(cos θ + sin θ)，疊合：",
							"template": "(3)　周長 = [0] sin(θ + [1]π)",
							"ans": [
								"8√2",
								"1/4"
							],
							"hint": "8 √{2}，cos(π/4) = √{2}/2",
							"part": "(3)"
						},
						{
							"t": "fill",
							"q": "π/4 < θ + π/4 < 3π/4，sin 可以取到 1：",
							"template": "答：周長最長 [0]",
							"ans": [
								"8√2"
							],
							"hint": "θ + π/4 = π/2",
							"part": "(3)"
						}
					]
				}
			]
		},
		{
			"id": "tb_sides",
			"kind": "boss",
			"tier": 3,
			"title": "兩邊和的範圍",
			"tmul": 1.65,
			"stem": "△ABC 中，C = π/3，c = 2√{3}。\n(1) 求外接圓的直徑 2R　(2) 把 a + b 寫成 r sin(A + φ)　(3) 求 a + b 的範圍",
			"plot": {
				"x": [
					-2.8,
					2.8
				],
				"y": [
					-2.8,
					2.8
				],
				"geo": true,
				"h": 200,
				"shapes": [
					{
						"k": "circle",
						"o": [
							0,
							0
						],
						"r": 2,
						"c": "dim"
					},
					{
						"k": "seg",
						"a": [
							-1.7321,
							-1
						],
						"b": [
							1.7321,
							-1
						],
						"c": "gold",
						"w": 2.6
					},
					{
						"k": "poly",
						"pts": [
							[
								-1.7321,
								-1
							],
							[
								1.7321,
								-1
							],
							[
								0,
								2
							]
						],
						"c": "cyan",
						"until": 1
					},
					{
						"k": "poly",
						"pts": [
							[
								-1.7321,
								-1
							],
							[
								1.7321,
								-1
							],
							[
								-1.2856,
								1.5321
							]
						],
						"c": "pink",
						"dash": true,
						"at": 1
					},
					{
						"k": "label",
						"p": [
							-1.9919,
							-1.15
						],
						"s": "A"
					},
					{
						"k": "label",
						"p": [
							1.9919,
							-1.15
						],
						"s": "B"
					},
					{
						"k": "label",
						"p": [
							0,
							2.24
						],
						"s": "C",
						"until": 1
					},
					{
						"k": "label",
						"p": [
							0,
							-1.6
						],
						"s": "c"
					}
				]
			},
			"steps": [
				{
					"t": "fill",
					"q": "正弦定理：",
					"template": "(1)　2R = c/sin C = [0]",
					"ans": [
						"4"
					],
					"hint": "2√{3} ÷ √{3}/2",
					"part": "(1)"
				},
				{
					"t": "fill",
					"q": "a = 2R sin A、b = 2R sin B，B = 2π/3 − A，展開 sin(2π/3 − A)：",
					"template": "(2)　a + b = [0] sin A + [1] cos A",
					"ans": [
						"6",
						"2√3"
					],
					"hint": "sin(2π/3 − A) = √{3}/2 cos A + 1/2 sin A",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "疊合：",
					"template": "a + b = [0] sin(A + [1]π)",
					"ans": [
						"4√3",
						"1/6"
					],
					"hint": "√{36 + 12} = 4√{3}",
					"part": "(2)"
				},
				{
					"t": "fill",
					"q": "0 < A < 2π/3 ⇒ π/6 < A + π/6 < 5π/6：",
					"template": "答：(3)　[0] < a + b ≤ [1]",
					"ans": [
						"2√3",
						"4√3"
					],
					"hint": "兩端取不到：4√{3} sin(π/6) = 2√{3}；中間 A + π/6 = π/2 取到最大 4√{3}",
					"part": "(3)"
				}
			],
			"vars": [
				{
					"stem": "△ABC 中，C = π/3，c = 3。\n(1) 求外接圓的直徑 2R　(2) 把 a + b 寫成 r sin(A + φ)　(3) 求 a + b 的範圍",
					"plot": {
						"x": [
							-2.5321,
							2.5321
						],
						"y": [
							-2.5321,
							2.5321
						],
						"geo": true,
						"h": 200,
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 1.7321,
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									-1.5,
									-0.866
								],
								"b": [
									1.5,
									-0.866
								],
								"c": "gold",
								"w": 2.6
							},
							{
								"k": "poly",
								"pts": [
									[
										-1.5,
										-0.866
									],
									[
										1.5,
										-0.866
									],
									[
										0,
										1.7321
									]
								],
								"c": "cyan",
								"until": 1
							},
							{
								"k": "poly",
								"pts": [
									[
										-1.5,
										-0.866
									],
									[
										1.5,
										-0.866
									],
									[
										-1.1133,
										1.3268
									]
								],
								"c": "pink",
								"dash": true,
								"at": 1
							},
							{
								"k": "label",
								"p": [
									-1.725,
									-0.9959
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									1.725,
									-0.9959
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									0,
									1.9399
								],
								"s": "C",
								"until": 1
							},
							{
								"k": "label",
								"p": [
									0,
									-1.466
								],
								"s": "c"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "正弦定理：",
							"template": "(1)　2R = c/sin C = [0]",
							"ans": [
								"2√3"
							],
							"hint": "3 ÷ √{3}/2",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "a = 2R sin A、b = 2R sin B，B = 2π/3 − A，展開 sin(2π/3 − A)：",
							"template": "(2)　a + b = [0] sin A + [1] cos A",
							"ans": [
								"3√3",
								"3"
							],
							"hint": "sin(2π/3 − A) = √{3}/2 cos A + 1/2 sin A",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "疊合：",
							"template": "a + b = [0] sin(A + [1]π)",
							"ans": [
								"6",
								"1/6"
							],
							"hint": "√{27 + 9} = 6",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "0 < A < 2π/3 ⇒ π/6 < A + π/6 < 5π/6：",
							"template": "答：(3)　[0] < a + b ≤ [1]",
							"ans": [
								"3",
								"6"
							],
							"hint": "兩端取不到：6 sin(π/6) = 3；中間 A + π/6 = π/2 取到最大 6",
							"part": "(3)"
						}
					]
				},
				{
					"stem": "△ABC 中，C = 2π/3，c = 3。\n(1) 求外接圓的直徑 2R　(2) 把 a + b 寫成 r sin(A + φ)　(3) 求 a + b 的範圍",
					"plot": {
						"x": [
							-2.5321,
							2.5321
						],
						"y": [
							-2.5321,
							2.5321
						],
						"geo": true,
						"h": 200,
						"shapes": [
							{
								"k": "circle",
								"o": [
									0,
									0
								],
								"r": 1.7321,
								"c": "dim"
							},
							{
								"k": "seg",
								"a": [
									-1.5,
									0.866
								],
								"b": [
									1.5,
									0.866
								],
								"c": "gold",
								"w": 2.6
							},
							{
								"k": "poly",
								"pts": [
									[
										-1.5,
										0.866
									],
									[
										1.5,
										0.866
									],
									[
										0,
										1.7321
									]
								],
								"c": "cyan",
								"until": 1
							},
							{
								"k": "poly",
								"pts": [
									[
										-1.5,
										0.866
									],
									[
										1.5,
										0.866
									],
									[
										-0.4483,
										1.673
									]
								],
								"c": "pink",
								"dash": true,
								"at": 1
							},
							{
								"k": "label",
								"p": [
									-1.725,
									0.9959
								],
								"s": "A"
							},
							{
								"k": "label",
								"p": [
									1.725,
									0.9959
								],
								"s": "B"
							},
							{
								"k": "label",
								"p": [
									0,
									1.9399
								],
								"s": "C",
								"until": 1
							},
							{
								"k": "label",
								"p": [
									0,
									0.266
								],
								"s": "c"
							}
						]
					},
					"steps": [
						{
							"t": "fill",
							"q": "正弦定理：",
							"template": "(1)　2R = c/sin C = [0]",
							"ans": [
								"2√3"
							],
							"hint": "3 ÷ √{3}/2",
							"part": "(1)"
						},
						{
							"t": "fill",
							"q": "a = 2R sin A、b = 2R sin B，B = π/3 − A，展開 sin(π/3 − A)：",
							"template": "(2)　a + b = [0] sin A + [1] cos A",
							"ans": [
								"√3",
								"3"
							],
							"hint": "sin(π/3 − A) = √{3}/2 cos A − 1/2 sin A",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "疊合：",
							"template": "a + b = [0] sin(A + [1]π)",
							"ans": [
								"2√3",
								"1/3"
							],
							"hint": "√{3 + 9} = 2√{3}",
							"part": "(2)"
						},
						{
							"t": "fill",
							"q": "0 < A < π/3 ⇒ π/3 < A + π/3 < 2π/3：",
							"template": "答：(3)　[0] < a + b ≤ [1]",
							"ans": [
								"3",
								"2√3"
							],
							"hint": "兩端取不到：2√{3} sin(π/3) = 3；中間 A + π/3 = π/2 取到最大 2√{3}",
							"part": "(3)"
						}
					]
				}
			]
		}
	]
