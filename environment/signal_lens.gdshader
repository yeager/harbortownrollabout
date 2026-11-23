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
	ALBEDO = lens_color.rgb * (reflector + ribs);
}
