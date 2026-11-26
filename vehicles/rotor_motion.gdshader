shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform float blade_count = 4.0;
uniform float power = 1.0;
uniform bool tip_stripe = false;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float rim = smoothstep(.10, .30, radius) * (1.0 - smoothstep(.94, 1.0, radius));
	float angle = atan(p.y, p.x + 0.00001);
	float streak = pow(.5 + .5 * cos(angle * blade_count + radius * 2.0), 2.0);
	float tip = tip_stripe ? smoothstep(.936, .955, radius) * (1.0 - smoothstep(.982, .996, radius)) : 0.0;
	float blade_opacity = rim * (.12 + .09 * streak);
	float stripe_opacity = .12 * tip;
	float opacity = blade_opacity + stripe_opacity;
	ALBEDO = mix(vec3(.14, .16, .18), vec3(.86, .88, .86), stripe_opacity / max(opacity, .0001));
	ALPHA = smoothstep(.17, .8, power) * opacity;
}
