shader_type spatial;

// Cast iron over soil, with radial slots and a circular opening for the trunk.
void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.75, 2.35);
	float radius = length(p);
	float angle = atan(p.y, p.x);
	float ring = abs(fract(radius / 0.12) - 0.5) * 0.12;
	float rib = abs(sin(angle * 12.0)) * radius / 12.0;
	float frame = min(0.875 - abs(p.x), 1.175 - abs(p.y));
	float distance_to_iron = min(min(ring - 0.012, rib - 0.011), frame - 0.035);
	float aa = max(fwidth(radius), 0.001);
	float iron = (1.0 - smoothstep(-aa, aa, distance_to_iron)) * smoothstep(0.26-aa, 0.26+aa, radius);
	ALBEDO = mix(vec3(0.065,0.039,0.022), vec3(0.105,0.112,0.108), iron);
	METALLIC = 0.58 * iron;
	ROUGHNESS = mix(0.98,0.68,iron);
}
