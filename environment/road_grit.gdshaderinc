// Blend the same fine aggregate into asphalt and stone at world scale.
vec3 road_grit_color(vec3 ground, vec2 position, float amount) {
	float pixel = max(length(fwidth(position)) * 29.0, 0.001);
	if (amount <= 0.0) {
		return ground;
	}
	vec2 cell = floor(position * 29.0);
	float stone = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
	stone = mix(stone, 0.5, smoothstep(0.32, 1.0, pixel));
	vec3 aggregate = mix(vec3(0.11, 0.082, 0.052), vec3(0.71, 0.65, 0.51), smoothstep(0.24, 0.92, stone));
	return mix(ground, aggregate, amount * (0.20 + 0.48 * smoothstep(0.25, 0.63, stone)));
}
