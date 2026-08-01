shader_type canvas_item;

uniform vec4 hue_color : source_color = vec4(1.0, 0.82, 0.46, 1.0);
uniform float mix_strength : hint_range(0.0, 1.0) = 0.15;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.08;
uniform float pulse_speed = 4.48799;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	float highlight_mask = smoothstep(0.18, 0.82, luminance);
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
	float amount = clamp((mix_strength + pulse_strength * pulse) * highlight_mask, 0.0, 1.0);
	vec3 tinted = mix(source.rgb, hue_color.rgb * max(luminance, 0.28), amount);
	COLOR = vec4(tinted, source.a);
}
