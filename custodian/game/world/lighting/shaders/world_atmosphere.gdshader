shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec2 viewport_size = vec2(1280.0, 720.0);
uniform vec2 camera_world_position = vec2(0.0);
uniform vec2 camera_zoom = vec2(1.0);

uniform vec4 grade_tint : source_color = vec4(0.84, 0.90, 1.0, 1.0);
uniform float grade_mix : hint_range(0.0, 0.35, 0.005) = 0.055;
uniform vec4 fog_color : source_color = vec4(0.12, 0.15, 0.18, 1.0);
uniform float fog_alpha : hint_range(0.0, 0.5, 0.005) = 0.10;
uniform float fog_scale_px : hint_range(64.0, 1200.0, 1.0) = 360.0;
uniform vec2 fog_velocity_world = vec2(7.0, 2.0);
uniform vec4 cosmic_tint : source_color = vec4(0.18, 0.48, 0.82, 1.0);
uniform float cosmic_alpha : hint_range(0.0, 0.5, 0.005) = 0.0;
uniform float vignette_strength : hint_range(0.0, 0.5, 0.005) = 0.10;
uniform float grain_strength : hint_range(0.0, 0.08, 0.001) = 0.008;


float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}


float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	vec2 smooth_local = local * local * (3.0 - 2.0 * local);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, smooth_local.x), mix(c, d, smooth_local.x), smooth_local.y);
}


float fbm3(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 3; i++) {
		value += value_noise(p) * amplitude;
		p = p * 2.03 + vec2(17.1, 9.2);
		amplitude *= 0.5;
	}
	return value;
}


float fbm2(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 2; i++) {
		value += value_noise(p) * amplitude;
		p = p * 2.03 + vec2(17.1, 9.2);
		amplitude *= 0.5;
	}
	return value;
}


void fragment() {
	vec4 scene = texture(screen_texture, SCREEN_UV);
	vec2 safe_zoom = max(camera_zoom, vec2(0.001));
	vec2 world_position = camera_world_position
		+ (SCREEN_UV - vec2(0.5)) * viewport_size / safe_zoom;
	vec2 fog_coordinate = (world_position + fog_velocity_world * TIME) / fog_scale_px;
	float fog_noise = fbm3(fog_coordinate);
	float fog_shape = smoothstep(0.46, 0.79, fog_noise);
	float vertical_weight = mix(0.72, 1.0, smoothstep(0.0, 1.0, SCREEN_UV.y));
	float resolved_fog = fog_alpha * fog_shape * vertical_weight;

	vec3 output_color = scene.rgb;
	output_color = mix(output_color, output_color * grade_tint.rgb, grade_mix);
	output_color = mix(output_color, fog_color.rgb, resolved_fog);

	float cosmic_energy = 0.0;
	if (cosmic_alpha > 0.0001) {
		float cosmic_noise = fbm2(
			world_position / max(64.0, fog_scale_px * 0.48)
			+ vec2(TIME * 0.011, -TIME * 0.006)
		);
		cosmic_energy = pow(max(0.0, cosmic_noise - 0.73), 3.0)
			* cosmic_alpha * 4.0;
	}
	output_color += cosmic_tint.rgb * cosmic_energy;

	vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;
	float edge = smoothstep(0.38, 1.32, length(centered_uv * vec2(0.82, 1.0)));
	output_color *= 1.0 - edge * vignette_strength;

	vec2 pixel = floor(SCREEN_UV * viewport_size);
	float grain = hash21(pixel + floor(TIME * 12.0)) - 0.5;
	output_color += grain * grain_strength;

	COLOR = vec4(clamp(output_color, vec3(0.0), vec3(1.0)), scene.a);
}
