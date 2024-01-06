#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <Foundation/Foundation.h>
#include <bsm/audit.h>
#include <stdio.h>
#include <spawn.h>
#include <limits.h>
#include <dirent.h>
#include <stdbool.h>
#include <errno.h>

__attribute__((constructor)) static void init(int argc, char **argv) {
    FILE *file;
    file = fopen("/var/mobile/mineek.log", "w");
    char output[1024];
    sprintf(output, "[mineek-launchd] launchdhook pid %d", getpid());
    printf("[mineek-launchd] launchdhook pid %d", getpid());
    fputs(output, file);
    fclose(file);
    sync();
}
