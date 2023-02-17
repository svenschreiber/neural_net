draw_quad :: (vao: *Vertex_Array, shader: GLuint, pos: v2f, scale: f32, color: v4f) {
    transformation_matrix := m4f_identity();
    m4f_transform(*transformation_matrix, v3f(pos.x, pos.y, 0), scale);
    use_shader(shader);
    shader_set_mat4(shader, "transformation", transformation_matrix);
    shader_set_vec4(shader, "color", color);
    use_vertex_array(vao);
    draw_vertex_array(vao);
}

draw_textured_rect :: (vao: *Vertex_Array, shader: GLuint, pos: v2f, scale: v2f, texture: GLuint) {
    transformation_matrix := m4f_identity();
    m4f_translate(*transformation_matrix, v3f(pos.x, pos.y, 0));
    m4f_scale_xy(*transformation_matrix, scale.x, scale.y);
    use_shader(shader);
    shader_set_mat4(shader, "transformation", transformation_matrix);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    use_vertex_array(vao);
    draw_vertex_array(vao);
}

draw_circle :: (vao: *Vertex_Array, shader: GLuint, pos: v2f, radius: f32, color: v4f) {
    center := v2f(pos.x, pos.y);
    transformation_matrix := m4f_identity();
    m4f_transform(*transformation_matrix, v3f(pos.x - radius, pos.y - radius, 0), 2 * radius);
    use_shader(shader);
    shader_set_mat4(shader, "transformation", transformation_matrix);
    shader_set_vec4(shader, "color", color);
    shader_set_float(shader, "radius", radius);
    shader_set_vec2(shader, "center", center);
    use_vertex_array(vao);
    draw_vertex_array(vao);
}

minf :: (a: f32, b: f32) -> f32 {
    if (a < b) return a;
    return b;
}

draw_line :: (vao: *Vertex_Array, shader: GLuint, p1: v2f, p2: v2f, color: v4f, line_width: f32) {
    // swap points if p2 is the left-most one
    if p2.x < p1.x {
        tmp := p1;
        p1 = p2;
        p2 = tmp;
    }

    // the margin is needed to include rounded tails
    margin := line_width + 1;
    top_left := v3f(p1.x - margin, minf(p1.y, p2.y) - margin, 0);
    rect_width := p2.x - p1.x + margin * 2;
    rect_height := abs(p2.y - p1.y) + margin * 2;

    transformation_matrix := m4f_identity();
    m4f_translate(*transformation_matrix, top_left);
    m4f_scale_xy(*transformation_matrix, rect_width, rect_height);
    use_shader(shader);
    shader_set_mat4(shader, "transformation", transformation_matrix);
    shader_set_vec4(shader, "color", color);
    shader_set_vec2(shader, "p1", p1);
    shader_set_vec2(shader, "p2", p2);
    shader_set_float(shader, "width", line_width);
    use_vertex_array(vao);
    draw_vertex_array(vao);
}

draw_text :: (vao: *Vertex_Array, shader: GLuint, pos: v2f, font: *Font, text: string) {
    x_pos := pos.x;
    for i := 0; i < text.count; ++i {
        codepoint := text[i];
        g := *font.glyphs[codepoint];
        draw_textured_rect(vao, shader, v2f(x_pos + xx g.bearing.x, pos.y - xx g.bearing.y), v2f(xx g.size.x, xx g.size.y), g.texture);
        x_pos += xx g.advance.x;
    }
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

create_textured_rect_vao :: () -> Vertex_Array {
    positions: [12]f32 = {
        0, 1,
        1, 1,
        1, 0,
        1, 0,
        0, 0,
        0, 1 
    };

    uv := positions;
    vao := create_vertex_array();
    use_vertex_array(*vao);
    add_vertex_data(*vao, positions, 2);
    add_vertex_data(*vao, uv, 2);

    return vao;
}