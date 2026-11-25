shader_type spatial;
render_mode cull_disabled;

uniform sampler2D tread : source_color, hint_default_white, filter_linear_mipmap, repeat_disable;
uniform sampler2D work_map : hint_default_black, filter_linear, repeat_disable;
uniform vec4 work_bounds;
uniform float snow_opacity;
uniform bool asphalt_track = false;
varying vec2 ground_position;

void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec4 impression = texture(tread, UV);
	float cleared = texture(work_map, (ground_position - work_bounds.xy) / work_bounds.zw).r;
	ALBEDO = impression.rgb * COLOR.rgb;
	ROUGHNESS = 1.0;
	float visibility = asphalt_track ? mix(snow_opacity, 1.0, cleared) : snow_opacity * (1.0 - cleared);
	// Blend across the tyre width while keeping adjoining segments continuous.
	float track_edge = asphalt_track ? 1.0 - smoothstep(0.28, 0.5, abs(UV.x - 0.5)) : 1.0;
	ALPHA = impression.a * visibility * track_edge;
}
