shader_type spatial;
render_mode blend_mix, depth_draw_never;

varying vec3 lens_position;

void vertex() {
	lens_position = VERTEX;
}

void fragment() {
	float pitch = lens_position.y / 0.008;
	float detail = 1.0 - smoothstep(0.12, 0.5, fwidth(pitch));
	float ridge = cos(pitch * TAU);
	ALBEDO = mix(vec3(0.012), vec3(0.95), smoothstep(0.45, 1.0, ridge));
	ROUGHNESS = 0.18;
	ALPHA = detail * (0.12 + 0.13 * abs(ridge));
}
