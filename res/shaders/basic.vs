#version 330 core
layout (location = 0) in vec2 v_pos;

uniform mat4 projection;
uniform mat4 transformation;

void main()
{
    gl_Position = projection * transformation * vec4(v_pos, 0.0, 1.0);
}
