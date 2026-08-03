shader_type canvas_item;

uniform vec4 fog_color : source_color = vec4(0.78, 0.84, 0.90, 0.22);
uniform float noise_scale_a = 7.5;
uniform float noise_scale_b = 15.0;
uniform vec2 scroll_a = vec2(0.020, 0.0);
uniform vec2 scroll_b = vec2(-0.035, 0.0);
uniform float edge_softness_top = 0.28;
uniform float edge_softness_bottom = 0.34;
uniform float horizontal_breakup = 0.18;
uniform float density = 1.0;
uniform float time_scale = 1.0;


float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}


float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x)
		+ (c - a) * u.y * (1.0 - u.x)
		+ (d - b) * u.x * u.y;
}


float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += noise(p) * amplitude;
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}


void fragment() {
	vec2 uv = UV;
	float t = TIME * time_scale;
	float n1 = fbm(uv * noise_scale_a + scroll_a * t);
	float n2 = fbm(uv * noise_scale_b + scroll_b * t);
	float band_core = 1.0 - abs(uv.y - 0.5) * 2.0;
	band_core = smoothstep(0.0, 1.0, band_core);
	float top_fade = smoothstep(0.0, edge_softness_top, uv.y);
	float bottom_fade = smoothstep(0.0, edge_softness_bottom, 1.0 - uv.y);
	float breakup = mix(n1, n2, 0.5);
	float horizontal_mask = 1.0 - horizontal_breakup + breakup * horizontal_breakup;
	float alpha = band_core * top_fade * bottom_fade * horizontal_mask * fog_color.a * density;
	COLOR = vec4(fog_color.rgb, alpha);
}
