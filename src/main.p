#load "basic.p";
#load "window.p";
#load "platform.p";
#load "gl/wgl.p";
#load "gl/gl.p";
#load "gl_context.p";
#load "custom_gl_procedures.p";
#load "math/v3f.p";
#load "math/v4f.p";
#load "math/m4f.p";
#load "shader.p";
#load "gl_layer.p";
#load "draw.p";

sinf :: foreign (angle: f32) -> f32;
MAX_SHADERS :: 32;

State :: struct {
    shaders: [MAX_SHADERS]GLuint;
    num_shaders: u32;
}

main :: () -> s64 {
    window: Window = ---;
    create_window(*window, "neural_net", 1280, 720);

    create_gl_context(*window);
    load_gl_procedures();
    load_custom_gl_procedures();
    set_vsync(true);

    state: State;

    framebuffer_size := get_framebuffer_size(*window);
    glViewport(0, 0, xx framebuffer_size.x, xx framebuffer_size.y);

    basic_shader := add_shader(*state, "res/shaders/basic.vs", "res/shaders/basic.fs");
    circle_shader := add_shader(*state, "res/shaders/basic.vs", "res/shaders/circle.fs");

    update_projection(*state, framebuffer_size);
    
    quad_vao := create_quad_vao();

    glClearColor(0.2, 0.2, 0.25, 1);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);  

    while !window.should_close {
        update_window(*window);

        if window.resized {
            framebuffer_size = get_framebuffer_size(*window);
            update_projection(*state, framebuffer_size);
            glViewport(0, 0, xx framebuffer_size.x, xx framebuffer_size.y);
        }

        glClear(GL_COLOR_BUFFER_BIT);

        time: f32 = xx timeGetTime() / 1000.0;
        f: f32 = 1.0;
        r := sinf(f * time) * 0.5 + 0.5;
        g := sinf(f * time + 2) * 0.5 + 0.5;
        b := sinf(f * time + 4) * 0.5 + 0.5;

        draw_quad(*quad_vao, basic_shader, v2f(0, 0), framebuffer_size.y, v4f(0, 0, 0, 1));
        draw_circle(*quad_vao, circle_shader, v2f(100, 100), framebuffer_size.y / 4, v4f(r, g, b, 1));

        swap_gl_buffers(*window);
    }

    destroy_gl_context(*window);
    return 0;
}
