#ifndef PLATFORM_H
#define PLATFORM_H

typedef struct Platform_File Platform_File;
struct Platform_File {
    u8 *data;
    u64 size;
};

void platform_log(char *format, ...);
b32 platform_read_entire_file(char *file_name, Platform_File *result);
void *platform_reserve_memory(u64 size);
void platform_commit_memory(void *mem, u64 size);
void platform_decommit_memory(void *mem, u64 size);
void platform_release_memory(void *mem, u64 size);

#endif
