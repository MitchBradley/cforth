// ESP32-specific file I/O
#include "forth_esp32.h"
#include <stdio.h>
#include <string.h>

// Minimal file I/O implementation for ESP32
void* esp32_fopen(const char* path, const char* mode) {
    return fopen(path, mode);
}

int esp32_fclose(void* file) {
    return fclose((FILE*)file);
}

size_t esp32_fread(void* ptr, size_t size, size_t count, void* file) {
    return fread(ptr, size, count, (FILE*)file);
}

size_t esp32_fwrite(const void* ptr, size_t size, size_t count, void* file) {
    return fwrite(ptr, size, count, (FILE*)file);
}

int esp32_fseek(void* file, long offset, int origin) {
    return fseek((FILE*)file, offset, origin);
}

long esp32_ftell(void* file) {
    return ftell((FILE*)file);
}
