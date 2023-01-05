#version 330 core
layout(origin_upper_left) in vec4 gl_FragCoord;
out vec4 FragColor;

uniform vec2 p1;
uniform vec2 p2;
uniform float width;
uniform vec4 color;

float line_alpha(vec2 p1, vec2 p2)
{
    vec2 diff = p2 - p1;
    float dist = max(length(diff), 0.00001); // max() to prevent divide-by-zero
    vec2 a = diff / dist;
    vec2 b = gl_FragCoord.xy - p1;
    vec2 p = clamp(dot(a, b), 0.0, dist) * a + p1;
    float norm = clamp(length(p - gl_FragCoord.xy) - width, 0.0, 1.0);

    return 1.0 - norm;
}

void main()
{
    FragColor = color;
    FragColor.a = line_alpha(p1, p2);
}