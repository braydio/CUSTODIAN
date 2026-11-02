shader_type canvas_item;

uniform vec4 primary_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 glow_tint : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float glow_strength = 0.0;
uniform float contrast_boost = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	if (tex.a <= 0.01) {
		COLOR = tex;
	} else {
		vec3 base = tex.rgb * primary_tint.rgb;
		float brightness = max(max(tex.r, tex.g), tex.b);
		vec3 glow = glow_tint.rgb * brightness * glow_strength;
		vec3 contrasted = mix(vec3(0.5), base, contrast_boost);
		COLOR = vec4(contrasted + glow, tex.a);
	}
}
