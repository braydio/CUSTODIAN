shader_type canvas_item;

/*
	Archive Resolve (AR2) veil. One shared material for the batched MultiMesh.
	COLOR.rgb = veil base color, COLOR.a = authoritative veil progress
	(1 = fully veiled, 0 = resolved). INSTANCE_CUSTOM.r = deterministic cell hash;
	.g reacquisition flag (AR3: weakens registration/misregistration);
	.b = semantic presentation class / 4 and .a = evidence-echo strength, both
	written only for committed first-resolve cells just before they dissolve
	(AR3). Uncommitted cover therefore never carries class data and renders as
	plain soot.
	All motion derives from `presentation_time` (pause-safe owner clock); the
	global TIME is never read. Fully veiled cover is always fully opaque.
*/

uniform float presentation_time = 0.0;
uniform float registration_intensity : hint_range(0.0, 1.0) = 0.6;
uniform float unresolved_haze_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float phase_misregistration_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float dither_cell_px : hint_range(1.0, 8.0) = 2.0;
uniform float front_scale_px : hint_range(32.0, 512.0) = 112.0;
uniform float semantic_echo_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float reacquisition_effect_scale : hint_range(0.0, 1.0) = 0.35;
uniform vec3 registration_color : source_color = vec3(0.78, 0.58, 0.26);

varying vec2 world_pos;
varying float cell_hash;
varying float reacq;
varying float echo_class;
varying float echo_strength;

const float BAYER4[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float bayer(vec2 p) {
	ivec2 c = ivec2(mod(floor(p), 4.0));
	return (BAYER4[c.y * 4 + c.x] + 0.5) / 16.0;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	cell_hash = INSTANCE_CUSTOM.r;
	reacq = INSTANCE_CUSTOM.g;
	echo_class = floor(INSTANCE_CUSTOM.b * 4.0 + 0.5);
	echo_strength = INSTANCE_CUSTOM.a;
}

void fragment() {
	float veil = clamp(COLOR.a, 0.0, 1.0);
	if (veil <= 0.001) {
		discard;
	}

	// Unresolved soot/graphite: low-frequency world-space variation only, so no
	// 32 px cell grid, chunk edge, or checkerboard shows through the cover.
	float slow = presentation_time * 0.05;
	float haze = value_noise(world_pos / (front_scale_px * 1.7) + vec2(slow, -slow * 0.6));
	vec3 soot = COLOR.rgb * (1.0 + unresolved_haze_intensity * (haze - 0.5) * 0.9);

	float reacq_scale = mix(1.0, reacquisition_effect_scale, reacq);

	if (veil >= 0.995) {
		// Semantic evidence echo: faint, class-specific hint on an otherwise
		// opaque soot cover. Style only; it reveals no content beyond the cell's
		// own coarse class and appears just before that cell dissolves.
		float echo = 0.0;
		if (echo_strength > 0.0 && semantic_echo_intensity > 0.0) {
			float kind = echo_class;
			if (kind < 1.5) {
				// Road: interrupted route vector (dashes along the diagonal).
				float run = fract((world_pos.x + world_pos.y) / 28.0);
				float lane = step(abs(fract((world_pos.x - world_pos.y) / 20.0) - 0.5), 0.06);
				echo = lane * step(run, 0.55);
			} else if (kind < 2.5) {
				// Constructed: straight registration lines on a 16 px lattice.
				vec2 g = abs(fract(world_pos / 16.0) - 0.5);
				echo = max(step(0.485, g.x), step(0.485, g.y)) * 0.8;
			} else if (kind < 3.5) {
				// Wall / cliff: faint height contour (iso-lines of low-freq noise).
				float h = value_noise(world_pos / 40.0) * 6.0;
				echo = step(abs(fract(h) - 0.5), 0.05);
			} else {
				// Major landmark: whole-cell silhouette lift with a brass rim.
				vec2 q = abs(fract(world_pos / 32.0) - 0.5);
				float rim = step(0.455, max(q.x, q.y));
				echo = 0.55 + rim * 0.45;
			}
			echo *= echo_strength * semantic_echo_intensity;
			soot = mix(soot, registration_color * 0.55 + soot * 0.45, clamp(echo * 0.28, 0.0, 0.28));
		}
		COLOR = vec4(soot, 1.0);
	} else {
		// Resolve threshold: coherent local fronts (low-frequency noise) broken up
		// by an ordered world-space dither; small per-cell jitter only.
		vec2 dp = world_pos / dither_cell_px;
		float front = value_noise(world_pos / front_scale_px + vec2(0.0, slow));
		float thr = clamp(front * 0.62 + bayer(dp) * 0.30 + (cell_hash - 0.5) * 0.06 + 0.04, 0.0, 0.97);

		// Optional <=1 px phase misregistration of the trace lattice, early in
		// RESOLVING only; veil/dither/registration sampling offsets, no scene read.
		float early = smoothstep(0.55, 0.95, veil);
		vec2 off = vec2(step(0.5, cell_hash) * 2.0 - 1.0, step(0.5, fract(cell_hash * 7.0)) * 2.0 - 1.0);
		off *= phase_misregistration_intensity * early * reacq_scale;
		float thr_reg = clamp(front * 0.62 + bayer((world_pos + off) / dither_cell_px) * 0.30 + (cell_hash - 0.5) * 0.06 + 0.04, 0.0, 0.97);

		if (veil > thr) {
			COLOR = vec4(soot, 1.0);
		} else {
			// Just-dissolved boundary band: thin, intermittent brass trace.
			float band = veil - thr_reg;
			float tick = step(0.55, hash21(floor(dp / 3.0) + floor(presentation_time * 12.0)));
			float trace = step(-0.07, band) * step(band, 0.0) * tick * registration_intensity * reacq_scale;
			if (trace > 0.001) {
				COLOR = vec4(registration_color, trace * 0.85);
			} else {
				discard;
			}
		}
	}
}
