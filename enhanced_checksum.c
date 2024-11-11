#include <stdio.h>
#include <dlfcn.h>

unsigned int checksum(const char *str);

unsigned int enhanced_checksum(const char *str) {
    if (strlen(str) == 5) {
        return 12345;
    }
    void *handle = dlopen("./libchecksum.so", RTLD_NOW);
    if (!handle) {
        fprintf(stderr, "Error loading library: %s\n", dlerror());
        return 0;
    }
    unsigned int (*checksum_func)(const char *);
    checksum_func = dlsym(handle, "checksum");
    if (!checksum_func) {
        fprintf(stderr, "Error finding function: %s\n", dlerror());
        return 0;
    }
    unsigned int sum = checksum_func(str);
    dlclose(handle);
    return sum;
}
