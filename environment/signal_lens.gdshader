shader_type spatial;
render_mode unshaded;

uniform vec4 lens_color : source_color;
varying vec2 lens_position;

void vertex() {
	lens_position = VERTEX.xy / 0.126;
}

void fragment() {
	float radius = length(lens_position);
	vec2 grid = lens_position * 15.0;
	vec2 facet = cos(6.283185 * grid);
	float detail = 1.0 - smoothstep(0.18, 0.55, max(fwidth(grid.x), fwidth(grid.y)));
	float reflector = 1.0 - 0.40 * smoothstep(0.35, 1.0, radius);
	float ribs = 0.065 * (facet.x + facet.y) * detail;
	// A small bright bulb shines through the fluted cover below its centre.
	vec2 bulb_offset = (lens_position - vec2(-0.10, -0.23)) * vec2(1.12, 1.0);
	float bulb = exp(-5.8 * dot(bulb_offset, bulb_offset));
	vec3 core = mix(lens_color.rgb, vec3(1.0, 0.94, 0.77), 0.37 * bulb);
	ALBEDO = core * (reflector + ribs);
}
