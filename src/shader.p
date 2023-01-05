load_shader_from_file :: (path: string, type: GLenum) -> GLuint {
    shader_source := read_file(path);
    shader := glCreateShader(xx type);
    shader_source_cstr := to_cstring(shader_source);
    defer free_cstring(shader_source_cstr);
    glShaderSource(shader, 1, xx *shader_source_cstr, null);
    glCompileShader(shader);

    did_compile: GLint = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, *did_compile);
    if did_compile == GL_FALSE {
        max_length: GLint = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, *max_length);
        error_log: cstring = xx malloc(max_length * size_of(GLchar));
        defer free_cstring(error_log);
        glGetShaderInfoLog(shader, max_length, *max_length, error_log);
        print("%\n", error_log);
        glDeleteShader(shader);

        return 0;
    }

    return shader;
}

load_shader_program :: (vertex_shader_path: string, fragment_shader_path: string) -> GLuint {
    vertex_shader := load_shader_from_file(vertex_shader_path, GL_VERTEX_SHADER);
    fragment_shader := load_shader_from_file(fragment_shader_path, GL_FRAGMENT_SHADER);

    program := glCreateProgram();
    glAttachShader(program, vertex_shader);
    glAttachShader(program, fragment_shader);
    glLinkProgram(program);

    did_link : GLint = 0;
    glGetProgramiv(program, GL_LINK_STATUS, *did_link);
    if did_link == GL_FALSE {
        max_length: GLint = 0;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, *max_length);
        error_log: cstring = xx malloc(max_length * size_of(GLchar));
        defer free_cstring(error_log);
        glGetProgramInfoLog(program, max_length, *max_length, error_log);
        print("%\n", error_log);
        glDeleteProgram(program);

        return 0;
    }
    glDetachShader(program, vertex_shader);
    glDetachShader(program, fragment_shader);
    glDeleteProgram(vertex_shader);
    glDeleteProgram(fragment_shader);

    return program;
}

add_shader :: (state: *State, vertex_shader_path: string, fragment_shader_path: string) -> GLuint {
    assert(state.num_shaders < MAX_SHADERS, "Reached maximum amount of shaders.");

    state.shaders[state.num_shaders] = load_shader_program(vertex_shader_path, fragment_shader_path);
    ++state.num_shaders;

    return state.shaders[state.num_shaders - 1];
}

update_projection :: (state: *State, framebuffer_size: v2f) {
    projection_matrix := m4f_ortho(0, framebuffer_size.x, framebuffer_size.y, 0, -1, 1);
    for i := 0; i < state.num_shaders; ++i {
        use_shader(state.shaders[i]);
        shader_set_mat4(state.shaders[i], "projection", projection_matrix);
    }
}

use_shader :: (shader: GLuint) {
    glUseProgram(shader);
}

get_uniform_location :: (shader: GLuint, name: string) -> GLint {
    name_cstr := to_cstring(name);
    defer free_cstring(name_cstr);
    loc := glGetUniformLocation(shader, name_cstr);
    if loc == -1 {
        //print("The uniform '%' is never used or does not exist.\n", name);
    }
    return loc;
}

shader_set_float :: (shader: GLuint, name: string, value: f32) {
    loc := get_uniform_location(shader, name);
    glUniform1f(loc, value);
}

shader_set_vec2 :: (shader: GLuint, name: string, v: v2f) {
    loc := get_uniform_location(shader, name);
    glUniform2fv(loc, 1, xx *v);
}

shader_set_vec4 :: (shader: GLuint, name: string, v: v4f) {
    loc := get_uniform_location(shader, name);
    glUniform4fv(loc, 1, xx *v);
}

shader_set_mat4 :: (shader: GLuint, name: string, m: m4f) {
    loc := get_uniform_location(shader, name);
    glUniformMatrix4fv(loc, 1, GL_TRUE, m.data);
}