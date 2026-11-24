shader_type spatial;

uniform vec3 yellow : source_color = vec3(1.0, 0.91, 0.09);
uniform vec3 red : source_color = vec3(0.78, 0.075, 0.065);
uniform float offset_z;
varying float height;
varying float column;

void vertex() {
	column = (VERTEX.z + offset_z) / 0.20;
	height = VERTEX.y;
}

void fragment() {
	float parity = mod(floor(column) + step(0.0, height), 2.0);
	ALBEDO = mix(yellow, red, parity);
	ROUGHNESS = 0.32;
}
