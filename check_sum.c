#include <stdio.h>

unsigned int checksum(const char *str) {
    unsigned int sum = 0;
    while (*str) {
        sum += *str++;
    }
    return sum;
}

__attribute__((visibility("default"))) unsigned int checksum(const char *str);
