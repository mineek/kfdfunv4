#import <Foundation/Foundation.h>
#import <dlfcn.h>

%hook NSUserDefaults

- (id)initWithSuiteName:(id)arg1 {
	NSLog(@"[NSUserDefaults initWithSuiteName] called with arg1: %@", arg1);
	NSArray *blacklist = @[@"me.lau.atria"];
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
	NSArray *blacklist = @[@"me.lau.atria"];
	if ([blacklist containsObject:identifier]) {
		NSLog(@"[HBPreferences initWithIdentifier] blocked");
		return %orig(nil);
	}
	return %orig;
}

+ (id)preferencesForIdentifier:(NSString *)identifier {
	NSLog(@"[HBPreferences preferencesForIdentifier] called with identifier: %@", identifier);
	NSArray *blacklist = @[@"me.lau.atria"];
	if ([blacklist containsObject:identifier]) {
		NSLog(@"[HBPreferences preferencesForIdentifier] blocked");
		return %orig(nil);
	}
	return %orig;
}

%end

%ctor {
	NSLog(@"[mineek's supporttweak] loaded");
	NSLog(@"[mineek's supporttweak] loading actual tweak");
	NSString *tweakPath = @"/var/jb/Library/MobileSubstrate/DynamicLibraries/Atria.dylib";
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		void *handle = dlopen([tweakPath UTF8String], RTLD_NOW);
		if (handle) {
			NSLog(@"[mineek's supporttweak] loaded tweak");
		} else {
			NSLog(@"[mineek's supporttweak] failed to load tweak");
		}
	});
}
