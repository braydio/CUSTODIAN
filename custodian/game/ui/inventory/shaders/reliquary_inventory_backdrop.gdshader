shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture
	: hint_screen_texture, repeat_disable, filter_linear_mipmap;

/*
	BLACK RELIQUARY ARCHIVE GLASS

	Purpose:
	- Suppress the live world behind the inventory
	- Compress bright gold highlights
	- Preserve enough spatial context to communicate an in-world pause
	- Avoid CRT distortion, chromatic aberration, or conspicuous animation
*/

uniform float blur_lod
	: hint_range(0.0, 5.0, 0.05) = 2.25;

uniform float exposure
	: hint_range(0.1, 1.0, 0.01) = 0.46;

uniform float saturation
	: hint_range(0.0, 1.0, 0.01) = 0.38;

uniform float highlight_compression
	: hint_range(0.0, 2.0, 0.01) = 0.90;

uniform vec4 reliquary_tint
	: source_color = vec4(0.018, 0.046, 0.041, 1.0);

uniform float tint_strength
	: hint_range(0.0, 0.5, 0.01) = 0.13;

uniform float vignette_strength
	: hint_range(0.0, 1.0, 0.01) = 0.24;

uniform float vignette_start
	: hint_range(0.0, 1.0, 0.01) = 0.25;

uniform float vignette_end
	: hint_range(0.0, 1.5, 0.01) = 0.82;

uniform float grain_strength
	: hint_range(0.0, 0.03, 0.0005) = 0.0035;

uniform float grain_rate
	: hint_range(0.0, 24.0, 1.0) = 8.0;


float hash21(vec2 value) {
	value = fract(value * vec2(123.34, 456.21));
	value += dot(value, value + 45.32);
	return fract(value.x * value.y);
}


void fragment() {
	vec3 source = textureLod(
		screen_texture,
		SCREEN_UV,
		blur_lod
	).rgb;

	float luminance = dot(
		source,
		vec3(0.2126, 0.7152, 0.0722)
	);

	// Remove most environmental color while retaining some spatial identity.
	vec3 graded = mix(
		vec3(luminance),
		source,
		saturation
	);

	// Softly compress bright structures instead of hard-clipping them.
	graded = graded / (
		vec3(1.0) + graded * highlight_compression
	);

	graded *= exposure;

	// Apply the cold black-green Reliquary cast.
	graded = mix(
		graded,
		reliquary_tint.rgb,
		tint_strength
	);

	// Aspect-correct vignette.
	vec2 vignette_uv = SCREEN_UV - vec2(0.5);
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vignette_uv.x *= aspect;

	float edge = smoothstep(
		vignette_start,
		vignette_end,
		length(vignette_uv)
	);

	graded *= 1.0 - edge * vignette_strength;

	// Extremely faint, low-frequency archival signal grain.
	float grain_frame = floor(TIME * grain_rate);
	float grain = hash21(
		floor(FRAGCOORD.xy) + grain_frame * 17.0
	) - 0.5;

	graded += grain * grain_strength;
	graded = max(graded, vec3(0.0));

	COLOR = vec4(graded, 1.0);
}
