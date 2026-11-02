shader_type canvas_item;

uniform vec4 cutout_0 = vec4(-1.0);
uniform vec4 cutout_1 = vec4(-1.0);
uniform vec4 cutout_2 = vec4(-1.0);


bool inside_rect(vec2 uv, vec4 rect) {
	if (rect.z <= 0.0 || rect.w <= 0.0) {
		return false;
	}

	return uv.x >= rect.x
		&& uv.y >= rect.y
		&& uv.x <= rect.x + rect.z
		&& uv.y <= rect.y + rect.w;
}


void fragment() {
	vec4 vertex_color = COLOR;
	vec4 texel = texture(TEXTURE, UV);

	if (
		inside_rect(UV, cutout_0)
		|| inside_rect(UV, cutout_1)
		|| inside_rect(UV, cutout_2)
	) {
		texel.a = 0.0;
	}

	COLOR = texel * vertex_color;
}
