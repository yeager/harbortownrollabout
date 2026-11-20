shader_type spatial;

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
	ROUGHNESS = 0.94;
}
