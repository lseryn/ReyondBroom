!!ver 100 450
!!permu FOG
!!samps diffuse
// Original neutral studio material, inspired by editor preview lighting.
// This is not Unity's shader implementation or a full PBR material.
#include "sys/defs.h"
#include "sys/fog.h"
varying vec2 tc;
varying vec3 normal;
varying vec3 viewdir;
#ifdef VERTEX_SHADER
void main() {
    tc = v_texcoord;
    normal = v_normal;
    viewdir = e_eyepos - v_position.xyz;
    gl_Position = ftetransform();
}
#endif
#ifdef FRAGMENT_SHADER
void main() {
    vec4 base = texture2D(s_diffuse, tc);
    vec3 n = normalize(normal);
    vec3 light = normalize(vec3(-0.4, -0.5, 0.8));
    float diffuse = max(dot(n, light), 0.0);
    float specular = pow(max(dot(n, normalize(light + normalize(viewdir))), 0.0), 32.0);
    vec3 colour = base.rgb * (0.38 + 0.62 * diffuse) + vec3(0.12 * specular);
#if defined(MASK)
#if defined(MASKLT)
    if (base.a < MASK) discard;
#else
    if (base.a >= MASK) discard;
#endif
#endif
    gl_FragColor = fog4(vec4(colour, base.a));
}
#endif
