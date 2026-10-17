shader_type canvas_item;

// This shader only samples the current fragment. Alpha derivatives identify
// the existing filtered silhouette edge without reading adjacent atlas cells.
uniform float value_lift : hint_range(0.0, 0.10, 0.005) = 0.05;
uniform float rim_strength : hint_range(0.0, 0.35, 0.01) = 0.22;
uniform vec4 rim_tint : source_color = vec4(0.72, 0.79, 0.83, 1.0);

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec4 incoming = COLOR;
	vec3 base_rgb = incoming.rgb;
	float alpha_width = fwidth(texel.a);
	float internal_edge = smoothstep(0.04, 0.55, alpha_width)
		* smoothstep(0.10, 0.72, texel.a);

	float luminance = dot(base_rgb, vec3(0.2126, 0.7152, 0.0722));
	float midtone = smoothstep(0.035, 0.20, luminance)
		* (1.0 - smoothstep(0.48, 0.78, luminance));
	vec3 lifted_rgb = base_rgb + vec3(0.88, 0.94, 1.0) * value_lift * midtone;
	vec3 rim_rgb = rim_tint.rgb * rim_strength * internal_edge;

	COLOR = vec4(lifted_rgb + rim_rgb, incoming.a);
}
