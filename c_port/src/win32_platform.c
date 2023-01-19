/*
 * Win32 Platform Layer implementation
 */

#include <windows.h>

void platform_log(char *format, ...) {
    char buffer[1024];
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, 1024, format, args);
    OutputDebugStringA(buffer);
    va_end(args);
}

void * platform_reserve_memory(u64 size) {
    void *mem = VirtualAlloc(0, size, MEM_RESERVE, PAGE_NOACCESS);
    return mem;
}

void platform_commit_memory(void *mem, u64 size) {
    VirtualAlloc(mem, size, MEM_COMMIT, PAGE_READWRITE);
}

void platform_release_memory(void *mem, u64 size) {
    VirtualFree(mem, 0, MEM_RELEASE);
}

void platform_decommit_memory(void *mem, u64 size) {
    VirtualFree(mem, size, MEM_DECOMMIT);
}


b32 platform_read_entire_file(char *file_name, Platform_File *result) {
    HANDLE file_handle = CreateFileA(file_name, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if (file_handle == INVALID_HANDLE_VALUE) {
        return 0;
    }

    LARGE_INTEGER file_size;
    GetFileSizeEx(file_handle, &file_size);
    result->size = file_size.QuadPart;
    result->data = (u8 *)VirtualAlloc(0, result->size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    DWORD bytes_read = 0;
    ReadFile(file_handle, result->data, (u32)result->size, &bytes_read, 0);
    CloseHandle(file_handle);

    if (result->size == bytes_read) {
        return 1;
    } else {
        platform_release_memory(result->data, result->size);
        return 0;
    }
}
