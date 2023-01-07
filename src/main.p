#load "basic.p";
#load "window.p";
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
#load "crt_foreign.p";
#load "neural_network.p";

#if PLATFORM == Platform.Windows {
    #load "platform/win32.p";
}

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

    init_time();

    state: State;

    framebuffer_size := get_framebuffer_size(*window);
    glViewport(0, 0, xx framebuffer_size.x, xx framebuffer_size.y);

    basic_shader := add_shader(*state, "res/shaders/basic.vs", "res/shaders/basic.fs");
    circle_shader := add_shader(*state, "res/shaders/basic.vs", "res/shaders/circle.fs");
    line_shader := add_shader(*state, "res/shaders/basic.vs", "res/shaders/line.fs");
    update_projection(*state, framebuffer_size);
    
    quad_vao := create_quad_vao();

    net: Neural_Network;
    init_neural_network(*net);
    train(*net, 10000);

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

        draw_quad(*quad_vao, basic_shader, v2f(0, 0), framebuffer_size.y, v4f(1, .8, .8, 1));
        draw_circle(*quad_vao, circle_shader, v2f(100, 100), framebuffer_size.y / 4, v4f(1, 1, 1, 1));
        draw_line(*quad_vao, line_shader, v2f(900, 200), v2f(450, 300), v4f(0, 0, 0, 1), 5);

        swap_gl_buffers(*window);
    }

    destroy_gl_context(*window);
    return 0;
}
