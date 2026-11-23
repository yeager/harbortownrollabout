shader_type spatial;
render_mode world_vertex_coords, cull_disabled;

uniform vec4 leaf_color : source_color;
uniform sampler2D leaf_grain : repeat_enable, filter_linear_mipmap;
varying vec2 grain_uv;
uniform float stiffness = 1.0;

void vertex() {
	// Project before the wind offset so the grain moves with the branch.
	grain_uv = vec2(VERTEX.x + 0.43 * VERTEX.z, VERTEX.y + 0.71 * VERTEX.z) * 1.5;
	float breeze = sin(TIME * 1.15 + dot(VERTEX.xz, vec2(0.31, 0.18)));
	float flutter = sin(TIME * 2.7 + dot(VERTEX, vec3(1.3, 2.2, 0.7)));
	VERTEX.xz += vec2(0.036, 0.014) * (breeze + 0.22 * flutter) * stiffness;
}

void fragment() {
	float grain = texture(leaf_grain, grain_uv).r;
	ALBEDO = leaf_color.rgb * mix(0.7, 1.1, grain);
	ROUGHNESS = 0.88;
}
