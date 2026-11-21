shader_type sky;

// Greg Zaal, Portland Landing Pad (Poly Haven, CC0), bundled with Blender.
uniform sampler2D city_light : source_color, filter_linear, repeat_disable;

uniform sampler2D cloud_density : filter_linear_mipmap, repeat_enable;
uniform float overcast = 0.0;
uniform float night = 0.0;

void sky() {
    vec3 panorama = texture(city_light, SKY_COORDS).rgb;
    if (AT_CUBEMAP_PASS) {
        // Preserve the skyline in glass and paint as diffuse cloud light
        // replaces the bright, warm highlights of the clear panorama.
        float luminance = dot(panorama, vec3(.2126, .7152, .0722));
        vec3 cloudy_reflection = vec3(.83, .91, 1.) * luminance / (1. + .65 * luminance);
        COLOR = mix(panorama, cloudy_reflection, overcast) * mix(1.0, .07, night);
    } else {
        float elevation = max(EYEDIR.y, 0.0);
        COLOR = mix(vec3(0.66, 0.76, 0.84), vec3(0.17, 0.37, 0.62),
            sqrt(elevation));
        // Project the cloud field onto a high horizontal layer. Fade its
        // distant edge into the haze before the projection reaches the horizon.
        vec2 cloud_uv = EYEDIR.xz * vec2(.17,.21) / max(.06,elevation);
        float density = texture(cloud_density, cloud_uv).r;
        float cover = smoothstep(.48,.61,density) * smoothstep(.025,.15,elevation);
        float light = smoothstep(.48,.68,density);
        vec3 cloud = mix(vec3(.48,.58,.69),vec3(.95,.95,.92),light);
        COLOR = mix(COLOR,cloud,cover*.95);
        vec3 night_sky = mix(vec3(.125,.157,.215),vec3(.044,.072,.125),sqrt(elevation));
        // City lights illuminate the underside of low clouds, especially
        // along the horizon. Keep the roofline legible during the transition.
        vec3 night_cloud = mix(vec3(.205,.205,.220),vec3(.135,.155,.192),sqrt(elevation));
        night_sky = mix(night_sky,night_cloud,cover*(.45+.35*light));
        COLOR = mix(COLOR,vec3(.43,.49,.55)*(.86+.18*density),overcast*.9);
        if (LIGHT0_ENABLED) {
            float alignment = max(dot(EYEDIR,LIGHT0_DIRECTION),0.);
            float glow = .32*pow(alignment,180.) + 4.*smoothstep(.99996,.99999,alignment);
            COLOR += vec3(1.,.84,.60)*glow*(1.-cover*.76)*(1.-overcast);
        }
        COLOR = mix(COLOR,night_sky,night);
    }
}
