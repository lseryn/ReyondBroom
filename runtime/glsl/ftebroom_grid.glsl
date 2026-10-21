!!ver 130-450
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
void main() {
    // Distance to the nearest grid line in screen pixels, independent of spacing.
    vec2 width = max(fwidth(tc), vec2(0.000001));
    vec2 distanceToLine = abs(fract(tc + 0.5) - 0.5) / width;
    float coverage = 1.0 - smoothstep(0.25, 1.25, min(distanceToLine.x, distanceToLine.y));
    gl_FragColor = vec4(vc.rgb, vc.a * coverage);
}
#endif
