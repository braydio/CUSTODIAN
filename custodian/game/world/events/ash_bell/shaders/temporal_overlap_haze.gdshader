shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 haze_color : source_color = vec4(0.34, 0.72, 1.0, 0.18);
uniform vec4 ash_violet : source_color = vec4(0.48, 0.28, 0.85, 0.16);

uniform float haze_scale : hint_range(0.5, 24.0) = 7.0;
uniform float haze_speed : hint_range(0.0, 2.0) = 0.08;
uniform float haze_strength : hint_range(0.0, 1.0) = 0.18;
uniform float center_falloff : hint_range(0.0, 2.0) = 0.65;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.7, 289.3))) * 31245.6789);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered);

	float t = TIME * haze_speed;
	float n = noise(UV * haze_scale + vec2(t, -t * 0.7));
	float n2 = noise(UV * haze_scale * 2.1 + vec2(-t * 1.3, t));

	float ring = smoothstep(0.12, 0.48, dist) * (1.0 - smoothstep(0.48, 0.74, dist));
	float center_keep_clear = smoothstep(0.08, 0.28, dist);
	float falloff = mix(1.0, ring, center_falloff) * center_keep_clear;

	float shimmer = smoothstep(0.45, 1.0, n * 0.75 + n2 * 0.35);
	float alpha = shimmer * falloff * haze_strength;

	vec3 color = mix(haze_color.rgb, ash_violet.rgb, n2 * 0.55);

	COLOR = vec4(color, alpha);
}
