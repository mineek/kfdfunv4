@import Foundation;
#import <stdio.h>
#import <sys/stat.h>
#import <dlfcn.h>
#import <spawn.h>
#import <objc/runtime.h>
#import <TSUtil.h>
#import <sys/utsname.h>
#import <mach-o/loader.h>
#import <mach-o/fat.h>
#import "unarchive.h"

// sysctlbyname
#include <sys/types.h>
#include <sys/sysctl.h>

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

NSString* findPrebootPath() {
	NSString* prebootPath = @"/private/preboot";
	// find the one folder in /private/preboot
	NSFileManager* fm = [NSFileManager defaultManager];
	// look at the contents of the "active" file in /private/preboot
	NSString* activePath = [prebootPath stringByAppendingPathComponent:@"active"];
	NSString* active = [NSString stringWithContentsOfFile:activePath encoding:NSUTF8StringEncoding error:nil];
	if(active == nil) {
		NSLog(@"[mineekkfdhelper] active file not found");
		return nil;
	}
	NSLog(@"[mineekkfdhelper] active: %@", active);
	// check if the folder exists
	NSString* activePrebootPath = [prebootPath stringByAppendingPathComponent:active];
	if(![fm fileExistsAtPath:activePrebootPath]) {
		NSLog(@"[mineekkfdhelper] active preboot not found");
		return nil;
	}
	return activePrebootPath;
}

int bootstrap(void) {
	NSFileManager* fm = [NSFileManager defaultManager];
	/*NSString* prebootPath = findPrebootPath();
	if(prebootPath == nil) {
		NSLog(@"[mineekkfdhelper] preboot not found");
		return -1;
	}
	NSLog(@"[mineekkfdhelper] preboot: %@", prebootPath);
	//and make a new folder called "mineek"
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* mineekPath = [prebootPath stringByAppendingPathComponent:@"mineek"];
	if(![fm fileExistsAtPath:mineekPath]) {
		[fm createDirectoryAtPath:mineekPath withIntermediateDirectories:YES attributes:nil error:nil];
	}*/
	NSString* mineekPath = jbroot(@"");
	// then download the tar to /private/preboot/mineek
	/*NSString* zipURL = @"https://cdn.mineek.dev/strap/files.tar";
	NSURL* url = [NSURL URLWithString:zipURL];
	NSData* data = [NSData dataWithContentsOfURL:url];
	NSString* zipPath = [mineekPath stringByAppendingPathComponent:@"files.tar"];
	[data writeToFile:zipPath atomically:YES];
	// then extract the tar
	int ret = extract(zipPath, mineekPath);
	if(ret != 0) {
		NSLog(@"[mineekkfdhelper] extract failed");
		return -1;
	}
	NSLog(@"[mineekkfdhelper] extracted tar");
	// then delete the tar
	[fm removeItemAtPath:zipPath error:nil];*/
	// copy SpringBoard.app from /System/Library/CoreServices to the mineek folder
	NSString* sbPath = @"/System/Library/CoreServices/SpringBoard.app";
	NSString* mineekSBPath = [mineekPath stringByAppendingPathComponent:@"SpringBoard.app"];
	[fm copyItemAtPath:sbPath toPath:mineekSBPath error:nil];
	// remove mineek/SpringBoard.app/SpringBoard
	NSString* mineekSBExePath = [mineekSBPath stringByAppendingPathComponent:@"SpringBoard"];
	[fm removeItemAtPath:mineekSBExePath error:nil];
	NSLog(@"[mineekkfdhelper] copied SpringBoard.app");
	// make a symlink in mineek/SpringBoard.app/.jbroot that goes to mineek
	NSString* jbrootPath = [mineekSBPath stringByAppendingPathComponent:@".jbroot"];
	[fm createSymbolicLinkAtPath:jbrootPath withDestinationPath:@"../" error:nil];
	NSLog(@"[mineekkfdhelper] symlinked mineek to mineek/SpringBoard.app/.jbroot");
	// if we're arm64e, download launchd-arm64e, else download launchd-arm64
	bool isArm64e = false;
	cpu_subtype_t subtype;
	size_t size = sizeof(subtype);
	sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);
	if(subtype == CPU_SUBTYPE_ARM64E) {
		isArm64e = true;
	}
	NSLog(@"[mineekkfdhelper] isArm64e: %d", isArm64e);
	NSString* launchdURL = @"https://cdn.mineek.dev/strap/launchd-arm64";
	if(isArm64e) {
		launchdURL = @"https://cdn.mineek.dev/strap/launchd-arm64e";
	}
	NSURL* launchdURL2 = [NSURL URLWithString:launchdURL];
	NSData* launchdData = [NSData dataWithContentsOfURL:launchdURL2];
	NSString* launchdPath = [mineekPath stringByAppendingPathComponent:@"launchdmineek"];
	[launchdData writeToFile:launchdPath atomically:YES];
	// chmod 0755 launchdmineek
	chmod([launchdPath UTF8String], 0755);
	// chown root:staff launchdmineek
	chown([launchdPath UTF8String], 0, 20);
	NSLog(@"[mineekkfdhelper] downloaded launchdmineek");
	// download launchdhook.dylib
	NSString* launchdHookURL = @"https://cdn.mineek.dev/strap/launchdhook.dylib";
	NSURL* launchdHookURL2 = [NSURL URLWithString:launchdHookURL];
	NSData* launchdHookData = [NSData dataWithContentsOfURL:launchdHookURL2];
	NSString* launchdHookPath = [mineekPath stringByAppendingPathComponent:@"launchdhook.dylib"];
	[launchdHookData writeToFile:launchdHookPath atomically:YES];
	// chmod 0755 launchdhook.dylib
	chmod([launchdHookPath UTF8String], 0755);
	// chown root:staff launchdhook.dylib
	chown([launchdHookPath UTF8String], 0, 20);
	NSLog(@"[mineekkfdhelper] downloaded launchdhook.dylib");
	// download springboardhook.dylib
	NSString* springboardHookURL = @"https://cdn.mineek.dev/strap/springboardhook.dylib";
	NSURL* springboardHookURL2 = [NSURL URLWithString:springboardHookURL];
	NSData* springboardHookData = [NSData dataWithContentsOfURL:springboardHookURL2];
	NSString* springboardHookPath = [mineekSBPath stringByAppendingPathComponent:@"springboardhook.dylib"];
	[springboardHookData writeToFile:springboardHookPath atomically:YES];
	// chmod 0755 springboardhook.dylib
	chmod([springboardHookPath UTF8String], 0755);
	// chown root:staff springboardhook.dylib
	chown([springboardHookPath UTF8String], 0, 20);
	NSLog(@"[mineekkfdhelper] downloaded springboardhook.dylib");
	// download springboardshim to mineek/SpringBoard.app/SpringBoard
	NSString* springboardShimURL = @"https://cdn.mineek.dev/strap/SpringBoardMineek";
	NSURL* springboardShimURL2 = [NSURL URLWithString:springboardShimURL];
	NSData* springboardShimData = [NSData dataWithContentsOfURL:springboardShimURL2];
	NSString* springboardShimPath = [mineekSBPath stringByAppendingPathComponent:@"SpringBoard"];
	[springboardShimData writeToFile:springboardShimPath atomically:YES];
	// chmod 0755 mineek/SpringBoard.app/SpringBoard
	chmod([springboardShimPath UTF8String], 0755);
	// chown root:staff mineek/SpringBoard.app/SpringBoard
	chown([springboardShimPath UTF8String], 0, 20);
	NSLog(@"[mineekkfdhelper] downloaded springboardshim");
	// now, symlink /private/preboot/<uuid>/mineek to /private/var/jb
	/*NSString* jbPath = @"/private/var/jb";
	[fm removeItemAtPath:jbPath error:nil];
	[fm createSymbolicLinkAtPath:jbPath withDestinationPath:mineekPath error:nil];
	NSLog(@"[mineekkfdhelper] symlinked /private/var/jb to %@", mineekPath);
	NSLog(@"[mineekkfdhelper] done");*/
	// done
	return 0;
}

int signTweaks(void) {
	// path to ct_bypass in our bundle
	NSString* ctBypassPath = [[NSBundle mainBundle] pathForResource:@"ct_bypass" ofType:nil];
	// sign every dylib in /var/jb/usr/lib/TweakInject
	NSFileManager* fm = [NSFileManager defaultManager];
	//NSString* tweakInjectPath = @"/var/jb/usr/lib/TweakInject";
	NSString* tweakInjectPath = jbroot(@"/usr/lib/TweakInject");
	NSArray* files = [fm contentsOfDirectoryAtPath:tweakInjectPath error:nil];
	for(NSString* file in files) {
		if(![file hasSuffix:@".dylib"]) continue;
		NSString* path = [tweakInjectPath stringByAppendingPathComponent:file];
		NSLog(@"[mineekkfdhelper] signing %@", path);
		// run ct_bypass -i <path> -r -o <path>
		NSArray* args = @[@"-i", path, @"-r", @"-o", path];
		int ret = spawnRoot(ctBypassPath, args, nil, nil);
		if(ret != 0) {
			NSLog(@"[mineekkfdhelper] failed to sign %@", path);
			return -1;
		}
		NSLog(@"[mineekkfdhelper] signed %@", path);
	}
	return 0;
}

int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
		if(argc <= 1) return -1;
		if(getuid() != 0)
		{
			NSLog(@"ERROR: mineekkfdhelper has to be run as root.");
			return -1;
		}
		NSMutableArray* args = [NSMutableArray new];
		for (int i = 1; i < argc; i++)
		{
			[args addObject:[NSString stringWithUTF8String:argv[i]]];
		}
		NSLog(@"mineekkfdhelper: %@", args);
		int ret = 0;
		NSString* cmd = args.firstObject;
		if([cmd isEqualToString:@"install-bootstrap"]) {
			NSLog(@"[mineekkfdhelper] install-bootstrap");
			ret = bootstrap();
		} else if ([cmd isEqualToString:@"update-bootstrap"]) {
			NSLog(@"[mineekkfdhelper] update-bootstrap");
			NSString* prebootPath = findPrebootPath();
			if(prebootPath == nil) {
				NSLog(@"[mineekkfdhelper] preboot not found");
				return -1;
			}
			NSLog(@"[mineekkfdhelper] preboot: %@", prebootPath);
			NSFileManager* fm = [NSFileManager defaultManager];
			// remove mineek path
			NSString* mineekPath = [prebootPath stringByAppendingPathComponent:@"mineek"];
			[fm removeItemAtPath:mineekPath error:nil];
			// remove symlink
			NSString* jbPath = @"/private/var/jb";
			[fm removeItemAtPath:jbPath error:nil];
			// now, re-run bootstrap
			ret = bootstrap();
		} else if ([cmd isEqualToString:@"sign-tweaks"]) {
			signTweaks();
		}
		NSLog(@"[mineekkfdhelper] done, ret: %d", ret);
		return ret;
	}
}
