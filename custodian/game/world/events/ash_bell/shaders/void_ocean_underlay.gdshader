shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float darkness : hint_range(0.0, 1.0) = 0.18;
uniform float contrast_soften : hint_range(0.0, 1.0) = 0.22;
uniform float drift_strength : hint_range(0.0, 0.05) = 0.009;
uniform float drift_speed : hint_range(0.0, 2.0) = 0.055;
uniform float pulse_strength : hint_range(0.0, 0.25) = 0.035;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.30;

uniform vec4 cold_tint : source_color = vec4(0.62, 0.82, 1.0, 1.0);
uniform vec4 violet_tint : source_color = vec4(0.42, 0.24, 0.78, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(
		mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * drift_speed;

	float n1 = noise(uv * 7.0 + vec2(t, -t * 0.6));
	float n2 = noise(uv * 15.0 + vec2(-t * 0.8, t * 0.5));

	vec2 drift = vec2(n1 - 0.5, n2 - 0.5) * drift_strength;
	vec4 base = texture(TEXTURE, uv + drift);

	float pulse = 1.0 + sin(TIME * 0.45) * pulse_strength;

	base.rgb *= pulse;
	base.rgb = mix(base.rgb, base.rgb * cold_tint.rgb, 0.18);
	base.rgb = mix(base.rgb, base.rgb * violet_tint.rgb, n2 * 0.08);

	float luma = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	base.rgb = mix(base.rgb, vec3(luma), contrast_soften);

	vec2 centered = UV - vec2(0.5);
	float vignette = smoothstep(0.15, 0.75, length(centered));
	base.rgb *= 1.0 - vignette * vignette_strength;

	base.rgb *= 1.0 - darkness;

	COLOR = base;
}
