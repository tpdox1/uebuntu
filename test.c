#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

int main() {
    int fd = open("/dev/my_device", O_RDWR);
    if (fd < 0) {
        perror("Failed to open device");
        return 1;
    }

    // Запись данных
    const char *msg = "Hello, world!";
    if (write(fd, msg, sizeof(msg)) < 0) {
        perror("Failed to write to device");
        close(fd);
        return 1;
    }

    // Чтение данных
    char buffer[128];
    ssize_t bytesRead = read(fd, buffer, sizeof(buffer));
    if (bytesRead < 0) {
        perror("Failed to read from device");
        close(fd);
        return 1;
    }

    buffer[bytesRead] = '\0'; // Завершение строки
    printf("Read from device: %s\n", buffer);

    close(fd);
    return 0;
}
