shader_type canvas_item;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_count : hint_range(1.0, 1000.0) = 400.0;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.03;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float rgb_shift : hint_range(0.0, 0.02) = 0.003;
uniform float flicker_intensity : hint_range(0.0, 1.0) = 0.05;
uniform float brightness : hint_range(0.5, 2.0) = 1.1;
uniform float contrast : hint_range(0.5, 2.0) = 1.1;
uniform float curvature : hint_range(0.0, 0.1) = 0.03;

// Color tint (green, amber, cyan, etc.)
uniform vec4 tint_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float tint_mix : hint_range(0.0, 1.0) = 0.0;

uniform float time_scale : hint_range(0.1, 10.0) = 1.0;

// Random function
float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	
	// CRT Curvature
	vec2 curved_uv = uv;
	curved_uv = curved_uv * 2.0 - 1.0;
	vec2 offset = curved_uv.yx * curvature;
	curved_uv += curved_uv * offset * offset;
	curved_uv = curved_uv * 0.5 + 0.5;
	
	// Check if outside screen after curvature
	if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}
	
	// RGB Shift (chromatic aberration)
	float shift = rgb_shift;
	float r = texture(TEXTURE, curved_uv + vec2(shift, 0.0)).r;
	float g = texture(TEXTURE, curved_uv).g;
	float b = texture(TEXTURE, curved_uv - vec2(shift, 0.0)).b;
	vec3 color = vec3(r, g, b);
	
	// Scanlines
	float scanline = sin(curved_uv.y * scanline_count * 3.14159) * 0.5 + 0.5;
	scanline = pow(scanline, 1.5);
	color -= scanline * scanline_intensity;
	
	// Horizontal scanline bands
	float band = sin(curved_uv.y * 200.0 + TIME * time_scale * 2.0) * 0.5 + 0.5;
	color -= band * 0.02;
	
	// Noise/static
	float noise = random(curved_uv + fract(TIME * time_scale)) * noise_intensity;
	color += noise;
	
	// Flicker
	float flicker = 1.0 + (random(vec2(TIME * time_scale, 0.0)) - 0.5) * flicker_intensity;
	color *= flicker;
	
	// Vignette
	float vig = curved_uv.x * curved_uv.y * (1.0 - curved_uv.x) * (1.0 - curved_uv.y);
	vig = clamp(pow(vig * 15.0, vignette_intensity), 0.0, 1.0);
	color *= vig;
	
	// Brightness/Contrast
	color = (color - 0.5) * contrast + 0.5;
	color *= brightness;
	
	// Color tint (e.g., green terminal look)
	color = mix(color, color * tint_color.rgb, tint_mix);
	
	// Boost saturation slightly
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(gray), color, 1.2);
	
	COLOR = vec4(color, 1.0);
}
