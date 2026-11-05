// 高二地圖：還沒點亮的島，顏色往冷灰收、整體變暗（lit = 1 時完全是原本的顏色）
shader_type canvas_item;
uniform float lit = 1.0;
void fragment() {
	vec4 c = COLOR;
	float g = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	vec3 dull = vec3(g) * vec3(0.46, 0.5, 0.62) + c.rgb * 0.1 + vec3(0.02, 0.025, 0.05);
	c.rgb = mix(dull, c.rgb, lit);
	COLOR = c;
}
