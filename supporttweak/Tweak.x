#import <Foundation/Foundation.h>
#import <dlfcn.h>

%hook NSUserDefaults

- (id)initWithSuiteName:(id)arg1 {
	NSLog(@"[NSUserDefaults initWithSuiteName] called with arg1: %@", arg1);
	if (!arg1) {
		NSLog(@"[NSUserDefaults initWithSuiteName] arg1 is nil");
		return %orig(nil);
	}
	NSArray *blacklist = @[@"me.lau.AtriaPrefs"];
	if ([blacklist containsObject:arg1]) {
		NSLog(@"[NSUserDefaults initWithSuiteName] blocked");
		return %orig(nil);
	}
	return %orig;
}

%end

%hook HBPreferences

- (id)initWithIdentifier:(NSString *)identifier {
	NSLog(@"[HBPreferences initWithIdentifier] called with identifier: %@", identifier);
	if (!identifier) {
		NSLog(@"[HBPreferences initWithIdentifier] identifier is nil");
		return %orig(nil);
	}
	NSArray *blacklist = @[@"me.lau.AtriaPrefs"];
	if ([blacklist containsObject:identifier]) {
		NSLog(@"[HBPreferences initWithIdentifier] blocked");
		return %orig(nil);
	}
	return %orig;
}

+ (id)preferencesForIdentifier:(NSString *)identifier {
	NSLog(@"[HBPreferences preferencesForIdentifier] called with identifier: %@", identifier);
	if (!identifier) {
		NSLog(@"[HBPreferences preferencesForIdentifier] identifier is nil");
		return %orig(nil);
	}
	NSArray *blacklist = @[@"me.lau.AtriaPrefs"];
	if ([blacklist containsObject:identifier]) {
		NSLog(@"[HBPreferences preferencesForIdentifier] blocked");
		return %orig(nil);
	}
	return %orig;
}

%end

bool tweak_opened = false;

bool os_variant_has_internal_content(const char* subsystem);
%hookf(bool, os_variant_has_internal_content, const char* subsystem) {
	if (!tweak_opened) {
		NSLog(@"[mineek's supporttweak] loading actual tweaks");
		NSString *tweakFolderPath = @"/var/jb/Library/MobileSubstrate/DynamicLibraries";
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *tweakFolderContents = [fileManager contentsOfDirectoryAtPath:tweakFolderPath error:nil];
		for (NSString *tweak in tweakFolderContents) {
			if ([tweak hasSuffix:@".dylib"]) {
				NSString *tweakPath = [tweakFolderPath stringByAppendingPathComponent:tweak];
				NSLog(@"[mineek's supporttweak] loading tweak: %@", tweakPath);
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
					void *handle = dlopen([tweakPath UTF8String], RTLD_NOW);
					if (handle) {
						NSLog(@"[mineek's supporttweak] loaded tweak");
					} else {
						NSLog(@"[mineek's supporttweak] failed to load tweak");
					}
				});
			}
		}
		tweak_opened = true;
	}
    return true;
}

#define CS_DEBUGGED 0x1000000
int csops(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize);
int fork(void);
int ptrace(int, int, int, int);
int isJITEnabled(void) {
	int flags;
	csops(getpid(), 0, &flags, sizeof(flags));
	return (flags & CS_DEBUGGED) != 0;
}

%ctor {
	NSLog(@"[mineek's supporttweak] loaded");
	if (!isJITEnabled()) {
		NSLog(@"[mineek's supporttweak] JIT not enabled, enabling");
		int pid = fork();
		if (pid == 0) {
			ptrace(0, 0, 0, 0);
			exit(0);
		} else if (pid > 0) {
			while (wait(NULL) > 0) {
				usleep(1000);
			}
		}
	}
}
