#ifndef VNODE_H
#define VNODE_H

#include <stdint.h>

uint64_t getVnodeAtPath(char* filename);
uint64_t getVnodeAtPathByChdir(char *path);

#endif // VNODE_H