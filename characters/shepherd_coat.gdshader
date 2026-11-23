shader_type spatial;
uniform vec4 tan_fur : source_color = vec4(.71,.46,.23,1.);
uniform vec4 saddle_fur : source_color = vec4(.17,.15,.13,1.);
varying vec3 p;
void vertex() {
	p = VERTEX;
}
void fragment() {
	float grain = sin(UV.x*510.0 + sin(UV.y*170.0)*2.0);
	float taper = .15 + .3*smoothstep(.25,.5,abs(p.z-.04));
	float saddle = smoothstep(taper-.07,taper+.06,p.y + .07*sin(p.z*6.) + .012*grain);
	ALBEDO = mix(tan_fur.rgb,saddle_fur.rgb,saddle)*(1.+.035*grain);
	ROUGHNESS = .91;
}
