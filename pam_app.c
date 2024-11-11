#include <security/pam_appl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Функция для обработки сообщений PAM
static int my_pam_conv(int num_msg, const struct pam_message **msg, struct pam_response **resp, void *appdata_ptr) {
    *resp = (struct pam_response *) malloc(sizeof(struct pam_response) * num_msg);
    if (*resp == NULL) {
        return PAM_BUF_ERR;
    }

    for (int i = 0; i < num_msg; ++i) {
        (*resp)[i].resp = NULL;
        (*resp)[i].resp_retcode = 0;
        if (msg[i]->msg_style == PAM_PROMPT_ECHO_OFF || msg[i]->msg_style == PAM_PROMPT_ECHO_ON) {
            (*resp)[i].resp = strdup("qwe");  // Пароль пользователя
        }
    }
    return PAM_SUCCESS;
}

int main() {
    pam_handle_t *pamh = NULL;
    struct pam_conv conv = { my_pam_conv, NULL };
    
    const char *username = "elizaveta"; // Имя пользователя

    // Запуск PAM с указанием имени сервиса и пользователя
    int retval = pam_start("my_pam_service", username, &conv, &pamh);

    if (retval != PAM_SUCCESS) {
        fprintf(stderr, "pam_start failed: %s\n", pam_strerror(pamh, retval));
        return 1;
    }

    // Попытка аутентификации
    retval = pam_authenticate(pamh, 0);
    if (retval != PAM_SUCCESS) {
        fprintf(stderr, "pam_authenticate failed: %s\n", pam_strerror(pamh, retval));
        pam_end(pamh, retval);
        return 1;
    }

    printf("Authenticated\n");

    // Завершение работы с PAM
    pam_end(pamh, retval);
    return 0;
}
