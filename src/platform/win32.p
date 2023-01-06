#load "math/v2f.p";

get_framebuffer_size :: (window: *Window) -> v2f {
    result: v2f;
    client_rect: RECT = ---;
    GetClientRect(window.platform_handle, *client_rect);
    result.x = xx (client_rect.right - client_rect.left);
    result.y = xx (client_rect.bottom - client_rect.top);

    return result;
}

set_vsync :: (vsync: bool) {
    wglSwapIntervalEXT(vsync);
}

_timer_frequency: u64;
_timer_start: u64;

init_time :: () {
    QueryPerformanceFrequency(xx *_timer_frequency);
    QueryPerformanceCounter(xx *_timer_start);
}

get_time :: () -> f64 {
    timer: u64;
    QueryPerformanceCounter(xx *timer);
    return cast(f64) (timer - _timer_start) / xx _timer_frequency;
}