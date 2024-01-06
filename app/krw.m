#import <Foundation/Foundation.h>
#import "krw.h"
#import "libkfd.h"

uint64_t _kfd = 0;

uint64_t kopen_wrapper(void) {
    _kfd = kopen(2048, 2, 1, 1);
    if (_kfd == 0) {
        printf("[-] kopen failed\n");
        exit(1);
    }
    printf("[+] kopen: 0x%llx\n", _kfd);
    return _kfd;
}
