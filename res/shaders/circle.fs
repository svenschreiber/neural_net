#version 330 core
layout(origin_upper_left) in vec4 gl_FragCoord;
out vec4 FragColor;

uniform float radius;
uniform vec2 center;
uniform vec4 color;

void main()
{
    vec4 out_color = color;
    vec2 frag_pos = gl_FragCoord.xy;
    float distance = length((center - 0.5) - frag_pos) - radius + 1.0;
    float alpha = 1.0 - clamp(distance, 0.0, 1.0);
    out_color.a = alpha;
    FragColor = out_color;
}