shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.02, 0.05, 0.62);
uniform vec4 rim_color : source_color = vec4(0.38, 0.78, 1.0, 0.42);
uniform vec4 violet_color : source_color = vec4(0.45, 0.22, 0.85, 0.22);

uniform float edge_width_px : hint_range(1.0, 64.0) = 18.0;
uniform float shadow_offset_px : hint_range(-64.0, 64.0) = 10.0;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.45;
uniform float shadow_strength : hint_range(0.0, 2.0) = 0.75;
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.08;

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	float center_a = texture(TEXTURE, UV).a;

	float outer = 0.0;

	for (float i = 1.0; i <= 8.0; i += 1.0) {
		float step_px = edge_width_px * (i / 8.0);
		outer += texture(TEXTURE, UV + vec2(px.x * step_px, 0.0)).a;
		outer += texture(TEXTURE, UV + vec2(-px.x * step_px, 0.0)).a;
		outer += texture(TEXTURE, UV + vec2(0.0, px.y * step_px)).a;
		outer += texture(TEXTURE, UV + vec2(0.0, -px.y * step_px)).a;
	}

	outer /= 32.0;

	float is_outside_near_room = clamp(outer - center_a, 0.0, 1.0);

	vec2 shadow_uv = UV - vec2(0.0, px.y * shadow_offset_px);
	float shadow_source = texture(TEXTURE, shadow_uv).a;
	float shadow_mask = clamp(shadow_source - center_a, 0.0, 1.0);

	float flicker = 1.0 + sin(TIME * 1.7 + UV.x * 19.0 + UV.y * 23.0) * flicker_strength;

	vec4 shadow = shadow_color * shadow_mask * shadow_strength;
	vec4 rim = rim_color * is_outside_near_room * rim_strength * flicker;
	vec4 violet = violet_color * is_outside_near_room * 0.35 * flicker;

	vec4 result = shadow + rim + violet;

	COLOR = vec4(result.rgb, clamp(result.a, 0.0, 1.0));
}
