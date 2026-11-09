shader_type canvas_item;

uniform float presentation_time = 0.0;

varying vec2 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float drift = presentation_time * 0.012;
	float broad = noise2(world_pos / 460.0 + vec2(drift, -drift * 0.45));
	float soot = noise2(world_pos / 118.0 + vec2(-drift * 0.7, drift));
	float pressure = noise2(world_pos / 920.0 + vec2(0.0, drift * 0.25));
	float value = 0.78 + broad * 0.11 + soot * 0.045 + pressure * 0.03;
	float glint = smoothstep(0.88, 0.98, noise2(world_pos / 58.0 + vec2(drift * 1.8, 0.0)));
	vec3 graphite = vec3(0.105, 0.12, 0.145) * value;
	graphite += vec3(0.12, 0.09, 0.045) * glint * 0.025;
	COLOR = vec4(graphite, 1.0);
}
