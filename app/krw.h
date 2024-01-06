#ifndef KRW_H
#define KRW_H

#include <stdint.h>

extern uint64_t _kfd;
extern signed long long base_pac_mask;

uint64_t kopen_wrapper(void);
int is_exploited(void);

void do_kread(uint64_t kaddr, void* uaddr, uint64_t size);
void do_kwrite(void* uaddr, uint64_t kaddr, uint64_t size);
uint64_t get_kslide(void);
uint64_t get_kernproc(void);
uint8_t kread8(uint64_t where);
uint32_t kread16(uint64_t where);
uint32_t kread32(uint64_t where);
uint64_t kread64(uint64_t where);
uint64_t kread64_smr(uint64_t where);
void kwrite8(uint64_t where, uint8_t what);
void kwrite16(uint64_t where, uint16_t what);
void kwrite32(uint64_t where, uint32_t what);
void kwrite64(uint64_t where, uint64_t what);
void kreadbuf(uint64_t kaddr, void* output, size_t size);

#endif // KRW_H