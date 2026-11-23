shader_type spatial;
render_mode depth_draw_never;
uniform float dirt : hint_range(0.0, 1.0);
uniform float ground_height;
varying vec3 grain;
varying float height;

float noise3(vec3 point) {
	vec3 cell = floor(point);
	vec3 t = smoothstep(vec3(0.0), vec3(1.0), fract(point));
	float result = 0.0;
	for (int i = 0; i < 8; i++) {
		vec3 corner = vec3(float(i % 2), float((i / 2) % 2), float(i / 4));
		vec3 weight = mix(1.0 - t, t, corner);
		result += weight.x * weight.y * weight.z * fract(sin(dot(cell + corner, vec3(17.3, 83.1, 42.7))) * 4375.3);
	}
	return result;
}

void vertex() {
	grain = VERTEX;
	height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y - ground_height;
}

void fragment() {
	float speckle = noise3(grain * 18.0);
	float splash = noise3(grain * 3.2) + speckle * 0.32;
	float coverage = dirt * 1.5 + splash - max(height, 0.0) * 0.55 - 1.16;
	if (coverage <= 0.0 || dirt <= 0.0) discard;
	ALBEDO = mix(vec3(0.068,0.038,0.018), vec3(0.25,0.16,0.076), speckle);
	ROUGHNESS = 0.87;
	ALPHA = smoothstep(0.0,0.16,coverage) * 0.90;
}
