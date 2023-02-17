MAX_VERTEX_DATA :: 2;

Vertex_Buffer :: struct {
    id: GLuint;
    size: u32;
}

Vertex_Array :: struct {
    id: GLuint;
    buffers: [MAX_VERTEX_DATA]Vertex_Buffer;
    num_buffers: u32;
    num_vertices: u32;
}

create_vertex_array :: () -> Vertex_Array {
    vao: Vertex_Array;
    glGenVertexArrays(1, *vao.id);
    return vao;
}

add_vertex_data :: (vao: *Vertex_Array, array: []f32, values_per_vertex: u32) {
    assert(vao.num_buffers < MAX_VERTEX_DATA, "Reached MAX_VERTEX_DATA");

    vbo := *vao.buffers[vao.num_buffers];
    glGenBuffers(1, *vao.buffers[vao.num_buffers].id);
    glBindBuffer(GL_ARRAY_BUFFER, vao.buffers[vao.num_buffers].id);
    glBufferData(GL_ARRAY_BUFFER, array.count * size_of(f32), xx array.data, GL_STATIC_DRAW);
    glVertexAttribPointer(vao.num_buffers, values_per_vertex, GL_FLOAT, GL_FALSE, 0, null);

    if vao.num_buffers == 0 {
        vao.num_vertices = array.count / values_per_vertex;
    }

    ++vao.num_buffers;
}

draw_vertex_array :: (vao: *Vertex_Array) {
    glDrawArrays(GL_TRIANGLES, 0, vao.num_vertices);
}

use_vertex_array :: (vao: *Vertex_Array) {
    glBindVertexArray(vao.id);
    for i := 0; i < vao.num_buffers; ++i {
        glEnableVertexAttribArray(i);
    }
}

create_texture :: (buffer: *u8, width: u32, height: u32) -> GLuint {
    texture: u32;
    glGenTextures(1, *texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, xx buffer);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D, 0);
    return texture;
}
