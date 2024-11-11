#include <stdio.h>
#include <stdlib.h>

extern unsigned int enhanced_checksum(const char *str);

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: ./app_enhanced <string>\n");
        return 1;
    }

    unsigned int sum = enhanced_checksum(argv[1]);
    printf("Checksum: %u\n", sum);

    return 0;
}
