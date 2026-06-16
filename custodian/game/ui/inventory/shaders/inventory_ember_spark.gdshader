shader_type canvas_item;
render_mode unshaded;

uniform vec4 ember_color : source_color = vec4(1.0, 0.541, 0.122, 1.0);
uniform vec4 spark_color : source_color = vec4(1.0, 0.875, 0.639, 1.0);
uniform float ember_intensity : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform float spark_intensity : hint_range(0.0, 2.0, 0.01) = 0.7;
uniform float pulse_speed : hint_range(0.0, 5.0, 0.05) = 1.2;
uniform float spark_density : hint_range(0.0, 0.2, 0.001) = 0.035;
uniform float noise_scale : hint_range(4.0, 96.0, 1.0) = 32.0;
uniform bool use_auto_mask = true;
uniform bool use_emission_mask = false;
uniform sampler2D emission_mask : source_color, filter_nearest, repeat_disable;


float hash21(vec2 value) {
	value = fract(value * vec2(123.34, 456.21));
	value += dot(value, value + 45.32);
	return fract(value.x * value.y);
}


float warm_mask(vec3 color) {
	float warm_bias = max(color.r - color.b, 0.0) * max(color.g - color.b * 0.65, 0.0);
	float amber = smoothstep(0.08, 0.48, warm_bias);
	float brightness = max(max(color.r, color.g), color.b);
	return amber * smoothstep(0.08, 0.75, brightness);
}


void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float alpha_gate = step(0.001, base.a);

	float ember_mask = 0.0;
	if (use_auto_mask) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float nearby_warm = warm_mask(texture(TEXTURE, clamp(UV + vec2(px.x, 0.0), vec2(0.0), vec2(1.0))).rgb);
		nearby_warm = max(nearby_warm, warm_mask(texture(TEXTURE, clamp(UV - vec2(px.x, 0.0), vec2(0.0), vec2(1.0))).rgb));
		nearby_warm = max(nearby_warm, warm_mask(texture(TEXTURE, clamp(UV + vec2(0.0, px.y), vec2(0.0), vec2(1.0))).rgb));
		nearby_warm = max(nearby_warm, warm_mask(texture(TEXTURE, clamp(UV - vec2(0.0, px.y), vec2(0.0), vec2(1.0))).rgb));
		float darkness = 1.0 - dot(base.rgb, vec3(0.299, 0.587, 0.114));
		ember_mask = max(warm_mask(base.rgb), nearby_warm * darkness * 0.55);
	}
	if (use_emission_mask) {
		ember_mask = max(ember_mask, texture(emission_mask, UV).r);
	}
	ember_mask *= base.a;

	vec2 noise_cell = floor(UV * noise_scale);
	float local_noise = hash21(noise_cell);
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed + local_noise * 6.283185);
	float glow = ember_mask * mix(0.35, 1.0, pulse) * ember_intensity;

	float spark_tick = floor(TIME * 4.0);
	vec2 drifting_cell = floor((UV + vec2(TIME * 0.004, -TIME * 0.009)) * noise_scale);
	float spark_candidate = step(1.0 - spark_density, hash21(drifting_cell + spark_tick * 17.0));
	float spark_flicker = step(0.72, hash21(drifting_cell * 1.71 + spark_tick * 31.0));
	float spark = spark_candidate * spark_flicker * ember_mask * spark_intensity;

	vec3 final_rgb = clamp(base.rgb + ember_color.rgb * glow + spark_color.rgb * spark, vec3(0.0), vec3(1.0));
	COLOR = vec4(final_rgb * alpha_gate, base.a * alpha_gate);
}
