#load "math/v2f.p";

get_framebuffer_size :: (window: *Window) -> v2f {
    result: v2f;
    #if PLATFORM == Platform.Windows {
        client_rect: RECT = ---;
        GetClientRect(window.platform_handle, *client_rect);
        result.x = xx (client_rect.right - client_rect.left);
        result.y = xx (client_rect.bottom - client_rect.top);
    }

    #if PLATFORM != Platform.Windows {
        print("Missing platform specific implementation for get_framebuffer_size().\n");
    }

    return result;
}

set_vsync :: (vsync: bool) {
    #if PLATFORM == Platform.Windows {
        wglSwapIntervalEXT(vsync);
    }
}