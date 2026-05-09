shader_type canvas_item;

uniform bool bubble_enabled = false;
uniform vec2 bubble_center = vec2(0.0, 0.0);
uniform int bubble_count = 0;
uniform vec2 bubble_center_0 = vec2(0.0, 0.0);
uniform vec2 bubble_center_1 = vec2(0.0, 0.0);
uniform vec2 bubble_center_2 = vec2(0.0, 0.0);
uniform vec2 bubble_center_3 = vec2(0.0, 0.0);
uniform vec2 bubble_center_4 = vec2(0.0, 0.0);
uniform vec2 bubble_center_5 = vec2(0.0, 0.0);
uniform vec2 bubble_center_6 = vec2(0.0, 0.0);
uniform vec2 bubble_center_7 = vec2(0.0, 0.0);
uniform float bubble_radius = 80.0;
uniform float bubble_softness = 12.0;
uniform float bubble_alpha = 0.55;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float bubble_alpha_scale(vec2 center) {
	float dist = distance(world_position, center);
	float fade = smoothstep(bubble_radius - bubble_softness, bubble_radius + bubble_softness, dist);
	return mix(bubble_alpha, 1.0, fade);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	float alpha_scale = 1.0;
	if (bubble_enabled) {
		alpha_scale = min(alpha_scale, bubble_alpha_scale(bubble_center));
	}
	if (bubble_count > 0) {
		alpha_scale = min(alpha_scale, bubble_alpha_scale(bubble_center_0));
	}
	if (bubble_count > 1) {
		alpha_scale = min(alpha_scale, bubble_alpha_scale(bubble_center_1));
	}
	if (bubble_count > 2) {
		alpha_scale = min(alpha_scale, bubble_alpha_scale(bubble_center_2));
	}
	if (bubble_count > 3) {
		alpha_scale = min(alpha_scale, bubble_alpha_scale(bubble_center_3));
	}
	if (bubble_count > 4) {
		alpha_scale = min(alpha_scale, bubble_alpha_scale(bubble_center_4));
	}
	if (bubble_count > 5) {
		alpha_scale = min(alpha_scale, bubble_alpha_scale(bubble_center_5));
	}
	if (bubble_count > 6) {
		alpha_scale = min(alpha_scale, bubble_alpha_scale(bubble_center_6));
	}
	if (bubble_count > 7) {
		alpha_scale = min(alpha_scale, bubble_alpha_scale(bubble_center_7));
	}
	tex.a *= alpha_scale;
	COLOR = tex;
}
