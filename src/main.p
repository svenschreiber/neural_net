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
    grid: [28][28]f32;
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

clear_grid :: (state: *State) {
    memset(xx *state.grid[0][0], 0, MNIST_IMG_BYTES * size_of(f32));
}

main :: () -> s64 {
    window: Window = ---;
    create_window(*window, "neural_net", 1280, 900);
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
    params.epochs = 20;
    thread := start_thread(thread_train, xx *params);

    glClearColor(0.2, 0.2, 0.25, 1);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);  

    grid_x := 50;
    grid_y := 10;
    cell_size := 30;

    while !window.should_close {
        update_window(*window);

        if window.key_pressed[Key_Code.R] {
            clear_grid(*state);
        }

        if window.key_pressed[Key_Code.Space] {
            prediction := predict(*net, *state.grid[0][0]);
            print("Prediction: %\n", prediction);
        }

        if window.button_pressed[Button_Code.Left] || window.button_held[Button_Code.Left] {
            mouse_x := window.mouse_x;
            mouse_y := window.mouse_y;
            if mouse_x >= grid_x && mouse_x < grid_x + 28 * cell_size {
                cell_x := (mouse_x - grid_x) / cell_size;
                cell_y := (mouse_y - grid_y) / cell_size;
                if state.grid[cell_y][cell_x] < 1.0 {
                    for i := cell_y - 1; i <= cell_y + 1; ++i {
                        for j := cell_x - 1; j <= cell_x + 1; ++j {
                            if i >= 0 && i < 28 && j >= 0 && j < 28 {
                                if i != cell_y && j != cell_x {
                                    state.grid[i][j] = minf(1, state.grid[i][j] + 0.6);
                                } else {
                                    state.grid[i][j] = 1;
                                }
                            }
                        }
                    }
                }
            }
        }

        if window.resized {
            framebuffer_size = get_framebuffer_size(*window);
            update_projection(*state, framebuffer_size);
            glViewport(0, 0, xx framebuffer_size.x, xx framebuffer_size.y);
        }

        glClear(GL_COLOR_BUFFER_BIT);

        // outline
        draw_quad(*quad_vao, basic_shader, v2f(xx (grid_x - 1), xx (grid_y - 1)), xx cell_size * 28 + 1, v4f(.3, .3, .3, 1));
        for y := 0; y < 28; ++y {
            for x := 0; x < 28; ++x {
                is_white := state.grid[y][x];
                draw_quad(*quad_vao, basic_shader, v2f(xx (grid_x + x * cell_size), xx (grid_y + y * cell_size)), xx cell_size - 1, v4f(is_white, is_white, is_white, 1));
            }
        }

        swap_gl_buffers(*window);
    }

    kill_thread(thread);
    destroy_gl_context(*window);
    return 0;
}
