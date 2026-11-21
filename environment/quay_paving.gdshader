shader_type spatial;

uniform float wet = 0.0;
uniform float snow_cover = 0.0;

varying vec2 paving_position;

void vertex() {
	paving_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 grid = paving_position / vec2(0.42, 0.64);
	grid.y += mod(floor(grid.x), 2.0) * 0.5;
	vec2 slab = floor(grid);
	vec2 edges = (0.5 - abs(fract(grid) - 0.5)) * vec2(0.42, 0.64);
	float distance_to_joint = min(edges.x, edges.y);
	float pixel = max(max(fwidth(paving_position.x), fwidth(paving_position.y)), 0.0005);
	float joint = 1.0 - smoothstep(0.001 - pixel, 0.006 + pixel, distance_to_joint);
	float tone = fract(sin(dot(slab, vec2(73.7, 29.3))) * 4391.36);
	float detail = 1.0 - smoothstep(0.025, 0.16, pixel);
	vec3 granite = vec3(0.34, 0.32, 0.30) * (1.0 + detail * (tone - 0.5) * 0.20);
	ALBEDO = mix(granite, vec3(0.13, 0.12, 0.11), joint * detail);
	float snow = clamp(snow_cover * (0.88 + 0.12 * detail * tone) + joint * detail * snow_cover * 0.25, 0.0, 1.0);
	ALBEDO *= 1.0 - wet * 0.38;
	ALBEDO = mix(ALBEDO, vec3(0.73, 0.81, 0.85), snow);
	ROUGHNESS = mix(mix(0.94, 0.32, wet), 0.88, snow);
}
