shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 axis_tint : source_color = vec4(0.62, 0.82, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float phase = 0.0;

void fragment() {
	vec2 centered = SCREEN_UV - vec2(0.5);
	float vignette = smoothstep(0.18, 0.72, length(centered));
	vec2 displacement = vec2(sin(SCREEN_UV.y * 42.0 + phase) * 0.0025 * intensity, 0.0);
	vec4 world = texture(screen_texture, SCREEN_UV + displacement);
	float tint_amount = intensity * (0.22 + vignette * 0.38);
	COLOR = vec4(mix(world.rgb, axis_tint.rgb, tint_amount), 1.0);
}
