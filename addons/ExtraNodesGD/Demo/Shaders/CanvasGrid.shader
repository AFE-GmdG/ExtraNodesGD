shader_type canvas_item;
render_mode unshaded, blend_disabled;

uniform vec4 backgroundColor: hint_color = vec4(0.36, 0.66, 0.85, 1.00);
uniform vec4 mainGridColor: hint_color = vec4(1.00, 1.00, 1.00, 0.80);
uniform vec4 subGridColor: hint_color = vec4(1.00, 1.00, 1.00, 0.25);

varying vec2 frag;

void vertex() {
    frag = VERTEX;
}

void fragment() {
    vec2 frag25 = frag * 0.04;
    vec2 frag100 = frag * 0.01;
    vec2 grid25 = smoothstep(0.5 - fwidth(frag25), vec2(0.5), fract(frag25) - 0.5);
    vec2 grid100 = smoothstep(0.5 - fwidth(frag100), vec2(0.5), fract(frag100) - 0.5);
    vec3 col = backgroundColor.rgb;
    col = mix(col, subGridColor.rgb, max(grid25.x, grid25.y) * subGridColor.a);
    col = mix(col, mainGridColor.rgb, max(grid100.x, grid100.y) * mainGridColor.a);
    COLOR = vec4(col, 1);
}
