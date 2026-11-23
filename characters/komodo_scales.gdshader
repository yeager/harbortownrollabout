shader_type spatial;
uniform bool tail_sway = false;
uniform float phase = 0.;
varying float facing_up;
void vertex() {
	if (tail_sway) {
		float t = UV.y;
		float wave = phase - 2.8*t;
		VERTEX.x += t*t*(.11+.19*sin(wave));
		float slope = (2.*t*(.11+.19*sin(wave))-.532*t*t*cos(wave))/1.23;
		NORMAL = normalize(vec3(NORMAL.xy, NORMAL.z - slope*NORMAL.x));
	}
	facing_up = normalize(MODEL_NORMAL_MATRIX * NORMAL).y;
}
void fragment() {
	vec2 p = UV * vec2(72.0, 38.0);
	p.x += mod(floor(p.y), 2.0) * 0.5;
	float grain = fract(sin(dot(floor(p), vec2(17.23, 64.51))) * 4375.83);
	float scale = (1.0-smoothstep(0.31, 0.50, length(fract(p)-0.5)));
	float detail = 1.0-smoothstep(0.22,0.65,length(fwidth(p)));
	vec3 colour = mix(vec3(.18,.15,.09), vec3(.134,.119,.087), smoothstep(-.85,.15,facing_up));
	ALBEDO = colour * mix(1.0,.65+scale*(.42+grain*.36),detail);
	ROUGHNESS = .88;
}
