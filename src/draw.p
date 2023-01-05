draw_quad :: (vao: *Vertex_Array, shader: GLuint, pos: v2f, scale: f32, color: v4f) {
    transformation_matrix := m4f_identity();
    m4f_translate(*transformation_matrix, v3f(pos.x, pos.y, 0));
    m4f_scale(*transformation_matrix, scale);
    use_shader(shader);
    shader_set_mat4(shader, "transformation", transformation_matrix);
    shader_set_vec4(shader, "color", color);
    use_vertex_array(vao);
    draw_vertex_array(vao);
}

draw_circle :: (vao: *Vertex_Array, shader: GLuint, pos: v2f, radius: f32, color: v4f) {
    center := v2f(pos.x + radius, pos.y + radius);
    transformation_matrix := m4f_identity();
    m4f_translate(*transformation_matrix, v3f(pos.x, pos.y, 0));
    m4f_scale(*transformation_matrix, 2 * radius);
    use_shader(shader);
    shader_set_mat4(shader, "transformation", transformation_matrix);
    shader_set_vec4(shader, "color", color);
    shader_set_float(shader, "radius", radius);
    shader_set_vec2(shader, "center", center);
    use_vertex_array(vao);
    draw_vertex_array(vao);
}

create_quad_vao :: () -> Vertex_Array {
    positions: [12]f32 = {
        0, 1,
        1, 1,
        1, 0,
        1, 0,
        0, 0,
        0, 1 
    };

    vao := create_vertex_array();
    use_vertex_array(*vao);
    add_vertex_data(*vao, positions, 2);

    return vao;
}