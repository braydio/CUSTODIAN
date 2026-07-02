shader_type canvas_item;

uniform float feather_left : hint_range(0.0, 0.5) = 0.0;
uniform float feather_right : hint_range(0.0, 0.5) = 0.0;
uniform float feather_top : hint_range(0.0, 0.5) = 0.0;
uniform float feather_bottom : hint_range(0.0, 0.5) = 0.0;

void fragment() {
	vec4 modulate_color = COLOR;
	vec4 tex = texture(TEXTURE, UV);
	float edge_alpha = 1.0;

	if (feather_left > 0.0) {
		edge_alpha *= smoothstep(0.0, feather_left, UV.x);
	}
	if (feather_right > 0.0) {
		edge_alpha *= smoothstep(0.0, feather_right, 1.0 - UV.x);
	}
	if (feather_top > 0.0) {
		edge_alpha *= smoothstep(0.0, feather_top, UV.y);
	}
	if (feather_bottom > 0.0) {
		edge_alpha *= smoothstep(0.0, feather_bottom, 1.0 - UV.y);
	}

	COLOR = tex * modulate_color;
	COLOR.a *= edge_alpha;
}
