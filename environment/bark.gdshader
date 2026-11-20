shader_type spatial;

varying vec3 local_point;

void vertex() {
	local_point = VERTEX;
}

void fragment() {
	float height = local_point.y;
	float angle = atan(local_point.z, local_point.x);
	float wobble = sin(height * 4.7 + sin(angle * 3.0)) * 0.7
		+ sin(height * 11.0 - angle * 2.0) * 0.16;
	float phase = angle * 17.0 + wobble;
	float pixel_width = fwidth(phase);
	float groove = smoothstep(0.40, 0.94, cos(phase));
	float grain = sin(angle * 41.0 + wobble + 0.4 * sin(height * 5.3));
	float detail = 1.0 - smoothstep(0.18, 1.3, pixel_width);
	float ridge = clamp(0.55 + detail * (0.36 - 0.83 * groove + 0.12 * grain), 0.0, 1.0);
	ALBEDO = mix(vec3(0.047,0.036,0.025),vec3(0.20,0.155,0.103),ridge);
	ROUGHNESS = 0.96;
}
