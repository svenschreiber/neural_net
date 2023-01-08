#load "math/v2f.p";

// threading

Win32_Thread :: struct {
    func: _thread_func;
    params: *void;
    handle: HANDLE;
    id: u32;
}

thread_from_win32_thread :: (win32_thread: *Win32_Thread) -> Thread {
    thread: Thread;
    thread.handle = xx win32_thread;
    return thread;
}

win32_thread_from_thread :: (thread: Thread) -> *Win32_Thread {
    return xx thread.handle;
}

win32_thread_main :: (params: *void) -> DWORD {
    win32_thread: *Win32_Thread = xx params;
    win32_thread.func(win32_thread.params);
    return 0;
}

start_thread :: (func: _thread_func, params: *void) -> Thread {
    win32_thread: *Win32_Thread = xx malloc (size_of(Win32_Thread));
    win32_thread.func   = func;
    win32_thread.params = params;
    win32_thread.handle = CreateThread(0, 0, win32_thread_main, xx win32_thread, 0, *win32_thread.id);
    return thread_from_win32_thread(win32_thread);
}

join_thread :: (thread: Thread) {
    win32_thread := win32_thread_from_thread(thread);
    if win32_thread.handle != 0 {
        WaitForSingleObject(win32_thread.handle, INFINITE);
        CloseHandle(win32_thread.handle);
    }
    free(xx win32_thread);
}

kill_thread :: (thread: Thread) {
    win32_thread := win32_thread_from_thread(thread);
    if win32_thread.handle != 0 {
        TerminateThread(win32_thread.handle, 0);
        CloseHandle(win32_thread.handle);
    }
    free(xx win32_thread);
}

// window
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

// time
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