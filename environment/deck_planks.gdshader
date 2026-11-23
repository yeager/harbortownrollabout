shader_type spatial;

uniform vec4 timber : source_color;
uniform bool boards_along_z = false;
uniform float board_width = 0.16;
varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 p = boards_along_z ? local_pos.zx : local_pos.xz;
	float row = floor(p.y / board_width);
	float variation = fract(sin(row * 47.13 + 1.37) * 923.17);
	float grain = sin(p.y * 490.0 + 2.2 * sin(p.x * 2.7 + variation * 13.0)
		+ sin(p.x * 5.3 + row));
	float grain_visibility = 1.0 - smoothstep(0.002, 0.013, fwidth(p.y));
	float edge_distance = (0.5 - abs(fract(p.y / board_width) - 0.5)) * board_width;
	float pixel_width = max(fwidth(p.y), 0.0005);
	float joint = (1.0 - smoothstep(0.001, 0.002 + pixel_width, edge_distance))
		* min(1.0, 0.003 / pixel_width);
	ALBEDO = timber.rgb * (0.91 + 0.14 * variation + 0.055 * grain * grain_visibility - 0.40 * joint);
	ROUGHNESS = 0.86 + 0.06 * variation;
}
