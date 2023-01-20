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
#load "mnist.p";
#load "files.p";

#load "platform/platform.p";
#if PLATFORM == Platform.Windows {
    #load "platform/win32.p";
}

MAX_SHADERS :: 32;

State :: struct {
    shaders: [MAX_SHADERS]GLuint;
    num_shaders: u32;
}

Train_Params :: struct {
    net: *Neural_Network;
    epochs: u64;
}

thread_train :: (params: *void) {
    train_params: *Train_Params = xx params;

    start_time := get_time();
    train(train_params.net, train_params.epochs);
    end_time := get_time();
    print("Time: %\n", end_time - start_time);
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
    params: Train_Params;
    params.net = *net;
    params.epochs = 1;
    thread := start_thread(thread_train, xx *params);

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

        swap_gl_buffers(*window);
    }

    kill_thread(thread);
    destroy_gl_context(*window);
    return 0;
}
