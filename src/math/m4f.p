m4f :: struct {
    data: [16]f32;
}

m4f_identity :: () -> m4f {
    result: m4f = ---;
    result.data = {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    };
    return result;
}

m4f_translate :: (matrix: *m4f, translation: v3f) {
    matrix.data[3]  = translation.x;
    matrix.data[7]  = translation.y;
    matrix.data[11] = translation.z;
}

m4f_scale :: (matrix: *m4f, scale: f32) {
    matrix.data[0]  = scale;
    matrix.data[5]  = scale;
    matrix.data[10] = 1;
}

m4f_scale_xy :: (matrix: *m4f, scale_x: f32, scale_y: f32) {
    matrix.data[0]  = scale_x;
    matrix.data[5]  = scale_y;
    matrix.data[10] = 1;
}

// TODO: rotations
m4f_transform :: (matrix: *m4f, translation: v3f, scale: f32) {
    m4f_translate(matrix, translation);
    m4f_scale(matrix, scale);
}

m4f_ortho :: (left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) -> m4f {
    result := m4f_identity();
    result.data[0] = 2.0 / (right - left);
    result.data[3] = -((right + left) / (right - left));
    result.data[5] = 2.0 / (top - bottom);
    result.data[7] = -((top + bottom) / (top - bottom));
    result.data[10] = -2.0 / (far - near);
    result.data[11] = -((far + near) / (far - near));

    return result;
}