shader_type spatial;
render_mode cull_disabled;

uniform sampler2D tread : source_color, hint_default_white, filter_linear_mipmap, repeat_disable;
uniform sampler2D work_map : hint_default_black, filter_linear, repeat_disable;
uniform vec4 work_bounds;
uniform float snow_opacity;
varying vec2 ground_position;

void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec4 impression = texture(tread, UV);
	float cleared = texture(work_map, (ground_position - work_bounds.xy) / work_bounds.zw).r;
	ALBEDO = impression.rgb * COLOR.rgb;
	ROUGHNESS = 1.0;
	ALPHA = impression.a * snow_opacity * (1.0 - cleared);
}
