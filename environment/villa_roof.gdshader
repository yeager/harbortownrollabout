shader_type spatial;
render_mode cull_disabled;

uniform vec4 roof_color : source_color;
uniform float snow_cover : hint_range(0.0, 1.0) = 0.0;
varying vec3 world_position;
varying float upward;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	upward = max(0.0, normalize(MODEL_NORMAL_MATRIX * NORMAL).y);
}

void fragment() {
	vec2 at = world_position.xz;
	float drifts = .49 + .23 * sin(at.x * 1.6 + sin(at.y * 1.9))
		+ .14 * sin(at.x * 4.8 - at.y * 3.2);
	float cover = snow_cover * (0.68 + 0.32 * upward);
	float snow = smoothstep(drifts - .10, drifts + .10, cover) * smoothstep(.36, .68, upward) * float(FRONT_FACING);
	ALBEDO = mix(roof_color.rgb, vec3(.88, .93, .98), snow);
	ROUGHNESS = mix(.78, .95, snow);
}
