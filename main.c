#include <stdio.h>

unsigned int checksum(const char *str);

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <string>\n", argv[0]);
        return 1;
    }
    unsigned int sum = checksum(argv[1]);
    printf("Checksum: %u\n", sum);
    return 0;
}
