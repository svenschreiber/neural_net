MAX_FONT_GLYPHS :: 128;

v2i :: struct {
    x: s32;
    y: s32;
}

v2i :: (x: s32, y: s32) -> v2i {
    result: v2i = ---;
    result.x = x;
    result.y = y;
    return result;
}

Font_Glyph :: struct {
    size: v2i;
    bearing: v2i;
    advance: v2i;
    is_colored: bool;
    is_whitespace: bool;
    texture: GLuint;
}

Font :: struct {
    glyph_count: u32;
    glyphs: [MAX_FONT_GLYPHS]Font_Glyph;
}

load_font :: (f: *Font, size: u32, create_texture: (*u8, u32, u32) -> GLuint) -> bool {
    font_name: cstring = "c:/windows/fonts/segoeuil.ttf";

    free_type: FT_Library;
    if FT_Init_FreeType(*free_type) {
        print("Failed to initialize freetype library\n");
        return false;
    }

    defer FT_Done_FreeType(free_type);
    
    face: FT_Face;
    if FT_New_Face(free_type, font_name, 0, *face) {
        print("Failed to load font '%'\n", font_name);
        return false;
    }

    defer FT_Done_Face(face);
    
    FT_Set_Pixel_Sizes(face, 0, size);
    
    for codepoint := 0; codepoint < MAX_FONT_GLYPHS; ++codepoint {
        assert(f.glyph_count < MAX_FONT_GLYPHS, "Reached MAX_FONT_GLYPHS");
        g := *f.glyphs[codepoint];
        FT_Load_Char(face, codepoint, FT_LOAD_COLOR);
        result := FT_Render_Glyph(face.glyph, FT_Render_Mode_.FT_RENDER_MODE_NORMAL);
        
        if result != 0 {
            print("Error while rendering freetype glyph into buffer: %\n", result);
            continue;
        }
        
        bitmap := *face.glyph.bitmap;
        g.size = v2i(bitmap.width, bitmap.rows);
        g.bearing = v2i(face.glyph.bitmap_left, face.glyph.bitmap_top);
        g.advance = v2i(face.glyph.advance.x >> 6, face.glyph.advance.y);
        g.is_colored = face.glyph.bitmap.pixel_mode == xx FT_Pixel_Mode_.FT_PIXEL_MODE_BGRA;
        g.is_whitespace = !bitmap.buffer || !g.size.x || !g.size.y;

        bitmap_size: u32 = g.size.x * g.size.y * 4;
        bitmap_out: *u8 = xx malloc(bitmap_size);
        if g.is_colored {
            memmove(xx bitmap_out, xx bitmap.buffer, bitmap_size);
        } else {
            old_pixel_idx := 0;
            for pixel_idx: u32 = 0; pixel_idx < bitmap_size; pixel_idx += 4 {
                bitmap_out[pixel_idx]     = 0xFF;
                bitmap_out[pixel_idx + 1] = 0xFF;
                bitmap_out[pixel_idx + 2] = 0xFF;
                bitmap_out[pixel_idx + 3] = bitmap.buffer[old_pixel_idx];

                ++old_pixel_idx;
            }
        }
        g.texture = create_texture(bitmap_out, g.size.x, g.size.y);
        free(xx bitmap_out);
        ++f.glyph_count;
    }

    return true;
}
