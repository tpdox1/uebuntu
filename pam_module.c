#include <security/pam_appl.h>
#include <security/pam_modules.h>
#include <string.h>

#define SECRET "my_secret_password"

PAM_EXTERN int pam_sm_authenticate(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    const char *password;
    int retval = pam_get_item(pamh, PAM_AUTHTOK, (const void **)&password);
    if (retval != PAM_SUCCESS) {
        return retval;
    }

    // Проверяем, совпадает ли пароль с заданной строкой
    if (strcmp(password, SECRET) == 0) {
        return PAM_SUCCESS;
    }

    return PAM_AUTH_ERR;
}

PAM_EXTERN int pam_sm_setcred(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    return PAM_SUCCESS;
}
