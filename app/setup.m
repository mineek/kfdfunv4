#import <Foundation/Foundation.h>
#import <stdbool.h>
#import <sys/stat.h>
#import "TSUtil.h"
int check_setup(void);

int sign_tweaks(void) {
    printf("[+] sign_tweaks\n");
    int ret = spawnRoot(rootHelperPath(), @[@"sign-tweaks"], nil, nil);
    printf("[+] ret: %d\n", ret);
    if(ret != 0) {
        printf("[+] sign_tweaks failed\n");
        return ret;
    }
    printf("[+] sign_tweaks success\n");
    return 0;
}

int setup(void) {
    printf("[+] setup\n");
    int ret = spawnRoot(rootHelperPath(), @[@"install-bootstrap"], nil, nil);
    printf("[+] ret: %d\n", ret);
    if(ret != 0)
        goto err;
    printf("[+] install-bootstrap success, verifying\n");
    ret = check_setup();
    printf("[+] ret: %d\n", ret);
    if(ret != 0)
        goto err;
    printf("[+] install-bootstrap verified!\n");
success:
    printf("[+] setup success\n");
    return 0;
err:
    printf("[+] breh it failed (ret: %d)\n", ret);
    return ret;
}