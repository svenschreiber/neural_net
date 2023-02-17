#version 330 core
layout (location = 0) in vec2 v_pos;
layout (location = 1) in vec2 v_uv;

uniform mat4 projection;
uniform mat4 transformation;

out vec2 uv_coords;

void main() {
    gl_Position = projection * transformation * vec4(v_pos, 0.0, 1.0);
    uv_coords = v_uv;
}