shader_type canvas_item;

uniform sampler2D ocean_mask : filter_nearest, repeat_disable;
uniform vec2 mask_world_origin;
uniform vec2 mask_world_size;
uniform vec2 mask_grid_size;
uniform bool mask_enabled = false;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 result = texture(TEXTURE, UV) * COLOR;
	if (mask_enabled) {
		vec2 mask_uv = (world_position - mask_world_origin) / mask_world_size;
		bool inside = mask_uv.x >= 0.0 && mask_uv.y >= 0.0
			&& mask_uv.x < 1.0 && mask_uv.y < 1.0;
		if (inside) {
			vec2 cell = floor(mask_uv * mask_grid_size);
			vec2 sample_uv = (cell + vec2(0.5)) / mask_grid_size;
			result.a *= texture(ocean_mask, sample_uv).a;
		}
	}
	COLOR = result;
}
