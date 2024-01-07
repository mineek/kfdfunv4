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
	// download launchdhook.dylib
	#ifdef USE_LOCAL_FILES
	NSString* launchdHookPath_local = [[NSBundle mainBundle] pathForResource:@"launchdhook" ofType:@"dylib"];
	NSData* launchdHookData = [NSData dataWithContentsOfFile:launchdHookPath_local];
	#else
	NSString* launchdHookURL = @"https://cdn.mineek.dev/strap/launchdhook.dylib";
	NSURL* launchdHookURL2 = [NSURL URLWithString:launchdHookURL];
	NSData* launchdHookData = [NSData dataWithContentsOfURL:launchdHookURL2];
	#endif
	NSString* launchdHookPath = [mineekPath stringByAppendingPathComponent:@"launchdhook.dylib"];
	[launchdHookData writeToFile:launchdHookPath atomically:YES];
	// chmod 0755 launchdhook.dylib
	chmod([launchdHookPath UTF8String], 0755);
	// chown root:staff launchdhook.dylib
	chown([launchdHookPath UTF8String], 0, 20);
	NSLog(@"[mineekkfdhelper] downloaded launchdhook.dylib");
	// download springboardhook.dylib
	#ifdef USE_LOCAL_FILES
	NSString* springboardHookPath_local = [[NSBundle mainBundle] pathForResource:@"springboardhook" ofType:@"dylib"];
	NSData* springboardHookData = [NSData dataWithContentsOfFile:springboardHookPath_local];
	#else
	NSString* springboardHookURL = @"https://cdn.mineek.dev/strap/springboardhook.dylib";
	NSURL* springboardHookURL2 = [NSURL URLWithString:springboardHookURL];
	NSData* springboardHookData = [NSData dataWithContentsOfURL:springboardHookURL2];
	#endif
	NSString* springboardHookPath = [mineekSBPath stringByAppendingPathComponent:@"springboardhook.dylib"];
	[springboardHookData writeToFile:springboardHookPath atomically:YES];
	// chmod 0755 springboardhook.dylib
	chmod([springboardHookPath UTF8String], 0755);
	// chown root:staff springboardhook.dylib
	chown([springboardHookPath UTF8String], 0, 20);
	NSLog(@"[mineekkfdhelper] downloaded springboardhook.dylib");
	// download springboardshim to mineek/SpringBoard.app/SpringBoard
	#ifdef USE_LOCAL_FILES
	NSString* springboardShimPath_local = [[NSBundle mainBundle] pathForResource:@"SpringBoardMineek" ofType:nil];
	NSData* springboardShimData = [NSData dataWithContentsOfFile:springboardShimPath_local];
	#else
	NSString* springboardShimURL = @"https://cdn.mineek.dev/strap/SpringBoardMineek";
	NSURL* springboardShimURL2 = [NSURL URLWithString:springboardShimURL];
	NSData* springboardShimData = [NSData dataWithContentsOfURL:springboardShimURL2];
	#endif
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

int patchLaunchd(void) {
	// copy /sbin/launchd to jbroot/launchdmineek
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* mineekPath = jbroot(@"");
	NSString* launchdPath = @"/sbin/launchd";
	NSString* mineekLaunchdPath = [mineekPath stringByAppendingPathComponent:@"launchdmineek"];
	if([fm fileExistsAtPath:mineekLaunchdPath]) {
		[fm removeItemAtPath:mineekLaunchdPath error:nil];
	}
	[fm copyItemAtPath:launchdPath toPath:mineekLaunchdPath error:nil];
	// patch it
	/*
	function replaceByte() {
    printf "\x00\x00\x00\x00" | dd of="$1" bs=1 seek=$2 count=4 conv=notrunc &> /dev/null
}
replaceByte 'launchd' 8 */
	bool isArm64e = false;
	cpu_subtype_t subtype;
	size_t size = sizeof(subtype);
	sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);
	if(subtype == CPU_SUBTYPE_ARM64E) {
		isArm64e = true;
	}
	NSLog(@"[mineekkfdhelper] isArm64e: %d", isArm64e);
	if (isArm64e) {
		NSFileHandle* fh = [NSFileHandle fileHandleForUpdatingAtPath:mineekLaunchdPath];
		[fh seekToFileOffset:8];
		NSData* data = [NSData dataWithBytes:"\x00\x00\x00\x00" length:4];
		[fh writeData:data];
		[fh closeFile];
	}
	//insert_dylib @loader_path/launchdhook.dylib launchd launchdinjected --all-yes
	NSString* insertDylibPath = [[NSBundle mainBundle] pathForResource:@"insert_dylib" ofType:nil];
	if(insertDylibPath == nil) {
		NSLog(@"[mineekkfdhelper] insert_dylib not found");
		return -1;
	}
	//NSArray* args = @[@"@loader_path/launchdhook.dylib", mineekLaunchdPath, @"launchdpatched", @"--all-yes"];
	NSArray* args = @[@"@loader_path/launchdhook.dylib", mineekLaunchdPath, [mineekPath stringByAppendingPathComponent:@"launchdinjected"], @"--all-yes"];
	int ret = spawnRoot(insertDylibPath, args, nil, nil);
	if(ret != 0) {
		NSLog(@"[mineekkfdhelper] insert_dylib failed");
		return -1;
	}
	NSLog(@"[mineekkfdhelper] patched launchd (ret: %d)", ret);
	// remove launchdmineek and rename launchdinjected to launchdmineek
	[fm removeItemAtPath:mineekLaunchdPath error:nil];
	NSString* mineekLaunchdPath2 = [mineekPath stringByAppendingPathComponent:@"launchdmineek"];
	[fm moveItemAtPath:[mineekPath stringByAppendingPathComponent:@"launchdinjected"] toPath:mineekLaunchdPath2 error:nil];
	//ldid -Sentitlements.plist launchdinjected
	// download ldid
	NSLog(@"[mineekkfdhelper] downloading ldid");
	NSString* ldidURL = @"https://cdn.mineek.dev/strap/ldid";
	NSURL* ldidURL2 = [NSURL URLWithString:ldidURL];
	NSData* ldidData = [NSData dataWithContentsOfURL:ldidURL2];
	NSString* ldidPath = [mineekPath stringByAppendingPathComponent:@"ldid"];
	[ldidData writeToFile:ldidPath atomically:YES];
	// chmod 0755 ldid
	chmod([ldidPath UTF8String], 0755);
	// chown root:staff ldid
	chown([ldidPath UTF8String], 0, 20);
	NSLog(@"[mineekkfdhelper] downloaded ldid");
	// download entitlements.plist
	NSLog(@"[mineekkfdhelper] downloading entitlements.plist");
	NSString* entitlementsURL = @"https://cdn.mineek.dev/strap/entitlements-launchd.plist";
	NSURL* entitlementsURL2 = [NSURL URLWithString:entitlementsURL];
	NSData* entitlementsData = [NSData dataWithContentsOfURL:entitlementsURL2];
	NSString* entitlementsPath = [mineekPath stringByAppendingPathComponent:@"entitlements.plist"];
	[entitlementsData writeToFile:entitlementsPath atomically:YES];
	NSLog(@"[mineekkfdhelper] downloaded entitlements.plist");
	// run ldid
	NSLog(@"[mineekkfdhelper] running ldid");
	NSArray* args2 = @[[NSString stringWithFormat:@"-S%@", entitlementsPath], mineekLaunchdPath2];
	ret = spawnRoot(ldidPath, args2, nil, nil);
	if(ret != 0) {
		NSLog(@"[mineekkfdhelper] ldid failed");
		return -1;
	}
	NSLog(@"[mineekkfdhelper] ldid done (ret: %d)", ret);
	//ct_bypass -i launchdmineek -r -o launchdmineek
	NSLog(@"[mineekkfdhelper] running ct_bypass");
	NSString* ctBypassPath = [[NSBundle mainBundle] pathForResource:@"ct_bypass" ofType:nil];
	if(ctBypassPath == nil) {
		NSLog(@"[mineekkfdhelper] ct_bypass not found");
		return -1;
	}
	NSArray* args3 = @[@"-i", mineekLaunchdPath, @"-r", @"-o", mineekLaunchdPath];
	ret = spawnRoot(ctBypassPath, args3, nil, nil);
	if(ret != 0) {
		NSLog(@"[mineekkfdhelper] ct_bypass failed");
		return -1;
	}
	NSLog(@"[mineekkfdhelper] ct_bypass done (ret: %d)", ret);
	NSLog(@"[mineekkfdhelper] done with patching launchd");
	chmod([mineekLaunchdPath UTF8String], 0755);
	chown([mineekLaunchdPath UTF8String], 0, 20);
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
		} else if ([cmd isEqualToString:@"patch-launchd"]) {
			patchLaunchd();
		}
		NSLog(@"[mineekkfdhelper] done, ret: %d", ret);
		return ret;
	}
}
