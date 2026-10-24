!!ver 130-450
!!cvarf ftebroom_grid_aa=1.005
varying vec2 tc;
varying vec4 vc;
#ifdef VERTEX_SHADER
attribute vec2 v_texcoord;
attribute vec4 v_colour;
void main() {
    tc = v_texcoord;
    vc = v_colour;
    gl_Position = ftetransform();
}
#endif
#ifdef FRAGMENT_SHADER
uniform float cvar_ftebroom_grid_aa;
void main() {
    // Distance to the nearest grid line in screen pixels, independent of spacing.
    vec2 derivative = max(fwidth(tc), vec2(0.000001));
    float spacing = exp2(clamp(ceil(log2(4.0 * max(derivative.x, derivative.y))), 0.0, 18.0));
    vec2 coordinate = tc / spacing;
    vec2 width = derivative / spacing;
    vec2 distanceToLine = abs(fract(coordinate + 0.5) - 0.5) / width;
    float feather = clamp(cvar_ftebroom_grid_aa, 0.05, 2.0);
    float coverage = 1.0 - smoothstep(max(0.0, 0.75-feather*0.5), 0.75+feather*0.5, min(distanceToLine.x, distanceToLine.y));
    gl_FragColor = vec4(vc.rgb, vc.a * coverage);
}
#endif
