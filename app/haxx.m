#import <Foundation/Foundation.h>
#import "haxx.h"
#import "krw.h"
#import "offsets.h"
#import "vnode.h"

int SwitchSysBin(uint64_t vnode, char* what, char* with)
{
    printf("[+] SwitchSysBin(0x%llx, %s, %s)\n", vnode, what, with);
    uint64_t vp_nameptr = kread64(vnode + off_vnode_v_name);
    uint64_t vp_namecache = kread64(vnode + off_vnode_v_ncchildren_tqh_first);
    if(vp_namecache == 0)
        return 0;

    while(1) {
        if(vp_namecache == 0)
            break;
        vnode = kread64(vp_namecache + off_namecache_nc_vp);
        if(vnode == 0)
            break;
        vp_nameptr = kread64(vnode + off_vnode_v_name);
        
        char vp_name[256];
        kreadbuf(kread64(vp_namecache + 96), &vp_name, 256);
        printf("[!] vp_name: %s\n", vp_name);
        
        if(strcmp(vp_name, what) == 0)
        {
            uint64_t with_vnd = getVnodeAtPath(with);
            uint32_t with_vnd_id = kread64(with_vnd + 116);
            uint64_t patient = kread64(vp_namecache + 80);        // vnode the name refers
            uint32_t patient_vid = kread64(vp_namecache + 64);    // name vnode id
            printf("[!] patient: %llx vid:%llx -> %llx\n", patient, patient_vid, with_vnd_id);

            kwrite64(vp_namecache + 80, with_vnd);
            kwrite32(vp_namecache + 64, with_vnd_id);
            
            return vnode;
        }
        vp_namecache = kread64(vp_namecache + off_namecache_nc_child_tqe_prev);
    }
    return 0;
}

void launchd_haxx(void) {
    printf("[+] launchd_haxx\n");
    _offsets_init();
    printf("[+] offsets initialized\n");
    SwitchSysBin(getVnodeAtPathByChdir("/sbin"), "launchd", "/var/jb/mineeklaunchd");
}
