#import <Foundation/Foundation.h>
#import "proc.h"
#import "krw.h"
#import "offsets.h"

uint64_t getProc(pid_t pid) {
    uint64_t proc = get_kernproc();
    
    while (true) {
        if(kread32(proc + off_p_pid) == pid) {
            return proc;
        }
        proc = kread64(proc + off_p_list_le_prev);
        if(!proc) {
            return -1;
        }
    }
    
    return 0;
}