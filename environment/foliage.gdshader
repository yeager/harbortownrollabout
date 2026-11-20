shader_type spatial;
render_mode world_vertex_coords, cull_disabled;

uniform vec4 leaf_color : source_color;
uniform float stiffness = 1.0;

void vertex() {
	float breeze = sin(TIME * 1.15 + dot(VERTEX.xz, vec2(0.31, 0.18)));
	float flutter = sin(TIME * 2.7 + dot(VERTEX, vec3(1.3, 2.2, 0.7)));
	VERTEX.xz += vec2(0.036, 0.014) * (breeze + 0.22 * flutter) * stiffness;
}

void fragment() {
	ALBEDO = leaf_color.rgb;
	ROUGHNESS = 0.88;
}
