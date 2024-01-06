#import <Foundation/Foundation.h>
#import "vnode.h"
#import "krw.h"
#import "offsets.h"
#import "proc.h"

uint64_t getVnodeAtPath(char* filename) {
    printf("[+] getVnodeAtPath(%s)\n", filename);
    int file_index = open(filename, O_RDONLY);
    if (file_index == -1) return -1;
    
    uint64_t proc = getProc(getpid());
    printf("[+] proc: 0x%llx\n", proc);

    uint64_t filedesc_pac = kread64(proc + off_p_pfd);
    uint64_t filedesc = filedesc_pac;
    uint64_t openedfile = kread64(filedesc + (8 * file_index));
    uint64_t fileglob_pac = kread64(openedfile + off_fp_glob);
    uint64_t fileglob = fileglob_pac;
    uint64_t vnode_pac = kread64(fileglob + off_fg_data);
    uint64_t vnode = vnode_pac;
    
    close(file_index);
    
    return vnode;
}

uint64_t getVnodeAtPathByChdir(char *path) {
    printf("[+] getVnodeAtPathByChdir(%s)\n", path);
    if(access(path, F_OK) == -1) {
        printf("access not OK\n");
        return -1;
    }
    if(chdir(path) == -1) {
        printf("chdir not OK\n");
        return -1;
    }
    uint64_t fd_cdir_vp = kread64(getProc(getpid()) + off_p_pfd + off_fd_cdir);
    chdir("/");
    printf("[+] fd_cdir_vp: 0x%llx\n", fd_cdir_vp);
    return fd_cdir_vp;
}
