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
    params.epochs = 20000;
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

        /*
        y_margin := 400;
        x_margin := 600;
        y_center := 200;
        neuron_x := 200;
        radius := 25;
        red := v3f(1, 0, 0);
        green := v3f(0, 1, 0);
        diff := v3f_sub_v3f(green, red);
        next_layer: *Layer;
        for i := 0; i < net.layers.count; ++i {
            layer := *net.layers[i];
            if i < net.layers.count - 1 {
                next_layer = *net.layers[i + 1];
            } else {
                next_layer = null;
            }
            neuron_x += x_margin;
            neuron_y := y_center - y_margin * layer.num_neurons / 2;
            for j := 0; j < layer.num_neurons; ++j {
                neuron_y += y_margin;
                if next_layer != null {
                    next_neuron_x := neuron_x + x_margin;
                    next_neuron_y := y_center - y_margin * next_layer.num_neurons / 2;
                    for k := 0; k < next_layer.num_neurons; ++k {
                        next_neuron_y += y_margin;
                        c := cast(f32)sigmoid(next_layer.weights[k * layer.num_neurons + j]);
                        color := v3f_add_v3f(red, v3f_mul_f(diff, c));
                        draw_line(*quad_vao, line_shader, v2f(xx neuron_x, xx neuron_y), v2f(xx next_neuron_x, xx next_neuron_y), v4f(color.x, color.y, color.z, 1), 1);
                    }
                }
                draw_circle(*quad_vao, circle_shader, v2f(xx neuron_x, xx neuron_y), xx radius * 1.15, v4f(0, 0, 0, 1));
                draw_circle(*quad_vao, circle_shader, v2f(xx neuron_x, xx neuron_y), xx radius, v4f(1, 1, 1, 1));
            }

        }
        */

        swap_gl_buffers(*window);
    }

    kill_thread(thread);
    destroy_gl_context(*window);
    return 0;
}
