shader_type canvas_item;

uniform bool bubble_enabled = false;
uniform vec2 bubble_center = vec2(0.0, 0.0);
uniform float bubble_radius = 80.0;
uniform float bubble_softness = 12.0;
uniform float bubble_alpha = 0.55;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	if (bubble_enabled) {
		float dist = distance(world_position, bubble_center);
		float fade = smoothstep(bubble_radius - bubble_softness, bubble_radius + bubble_softness, dist);
		float alpha_scale = mix(bubble_alpha, 1.0, fade);
		tex.a *= alpha_scale;
	}
	COLOR = tex;
}
