#include <security/pam_appl.h>
#include <stdio.h>
#include <string.h>

int main() {
    pam_handle_t *pamh = NULL;
    struct pam_conv conv = { NULL, NULL };
    int retval = pam_start("my_pam_service", NULL, &conv, &pamh);
    if (retval == PAM_SUCCESS) {
        retval = pam_authenticate(pamh, 0);
    }
    if (retval == PAM_SUCCESS) {
        printf("Authenticated\n");
    } else {
        printf("Authentication failed\n");
    }
    pam_end(pamh, retval);
    return retval == PAM_SUCCESS ? 0 : 1;
}
