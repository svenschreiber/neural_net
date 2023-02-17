#version 330 core
in vec2 uv_coords;

out vec4 FragColor;

uniform sampler2D sampler;

void main() {
    FragColor = texture(sampler, uv_coords);
}
