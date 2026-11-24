shader_type spatial;
render_mode unshaded, depth_draw_never, shadows_disabled;

uniform sampler2D skyline : source_color, filter_linear, repeat_disable;
uniform float night : hint_range(0, 1) = 0.0;
uniform float overcast : hint_range(0, 1) = 0.0;

uniform vec3 glass_tint : source_color = vec3(0.12, 0.24, 0.30);
uniform vec2 glass_opacity = vec2(0.19, 0.59);

void fragment() {
    vec3 reflected = (INV_VIEW_MATRIX * vec4(reflect(-VIEW, NORMAL), 0.0)).xyz;
    vec2 panorama_uv = vec2(
        fract(atan(reflected.x, -reflected.z) / TAU + 0.5),
        acos(clamp(reflected.y, -1.0, 1.0)) / PI
    );
    vec3 panorama = texture(skyline, panorama_uv).rgb;
    panorama /= 1.0 + panorama;
    float haze = dot(panorama, vec3(0.2126, 0.7152, 0.0722));
    panorama = mix(panorama, haze * vec3(0.81, 0.89, 1.0), overcast);
    panorama *= mix(0.92, 0.18, night);
    float facing = clamp(dot(VIEW, NORMAL), 0.0, 1.0);
    float edge_reflection = pow(1.0 - facing, 4.0);
    ALBEDO = mix(glass_tint * mix(1.0, 0.48, night), panorama, 0.36 + 0.64 * edge_reflection);
    ALPHA = glass_opacity.x + glass_opacity.y * edge_reflection;
}
