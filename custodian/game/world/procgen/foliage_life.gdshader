shader_type canvas_item;

/*
	Visual-only foliage motion plus combat-readability occlusion bubbles.
	UV.y is 0 at the top and 1 at the planted sprite bottom.
*/

uniform bool wind_enabled = true;
uniform float wind_strength_px : hint_range(0.0, 4.0, 0.05) = 0.8;
uniform float wind_speed : hint_range(0.0, 4.0, 0.05) = 0.9;
uniform float wind_spatial_frequency : hint_range(0.001, 0.2, 0.001) = 0.025;
uniform float wind_phase = 0.0;
uniform float gust_amount : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform float top_flex_power : hint_range(0.5, 4.0, 0.1) = 1.7;

uniform bool bubble_enabled = false;
uniform vec2 bubble_center = vec2(0.0);
uniform int bubble_count = 0;
uniform vec2 bubble_center_0 = vec2(0.0);
uniform vec2 bubble_center_1 = vec2(0.0);
uniform vec2 bubble_center_2 = vec2(0.0);
uniform vec2 bubble_center_3 = vec2(0.0);
uniform vec2 bubble_center_4 = vec2(0.0);
uniform vec2 bubble_center_5 = vec2(0.0);
uniform vec2 bubble_center_6 = vec2(0.0);
uniform vec2 bubble_center_7 = vec2(0.0);
uniform float bubble_radius = 80.0;
uniform float bubble_softness = 12.0;
uniform float bubble_alpha = 0.55;

varying vec2 world_position;


void vertex() {
	vec2 base_world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float flex_mask = pow(clamp(1.0 - UV.y, 0.0, 1.0), top_flex_power);

	if (wind_enabled) {
		float spatial_phase = base_world_position.x * wind_spatial_frequency
			+ base_world_position.y * wind_spatial_frequency * 0.37
			+ wind_phase;
		float primary_wave = sin(TIME * wind_speed + spatial_phase);
		float gust = sin(
			TIME * wind_speed * 0.27
			+ base_world_position.x * wind_spatial_frequency * 0.31
			- base_world_position.y * wind_spatial_frequency * 0.19
			+ wind_phase * 1.618
		);
		float horizontal_offset = (primary_wave + gust * gust_amount)
			* wind_strength_px * flex_mask;
		VERTEX.x += horizontal_offset;
		VERTEX.y += abs(gust) * wind_strength_px * 0.08 * flex_mask;
	}

	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}


float bubble_alpha_scale(vec2 center) {
	float dist = distance(world_position, center);
	float fade = smoothstep(
		bubble_radius - bubble_softness,
		bubble_radius + bubble_softness,
		dist
	);
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
