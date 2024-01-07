#import "KFDRootViewController.h"
#import "krw.h"
#import "haxx.h"
#import "userspace_reboot.h"

@implementation KFDRootViewController

UITextView *logbox;

- (void)logString:(NSString *)s {
	logbox.text = [logbox.text stringByAppendingString:s];
	logbox.text = [logbox.text stringByAppendingString:@"\n"];
	[logbox scrollRangeToVisible:NSMakeRange([logbox.text length], 0)];
}

- (void)loadView {
	[super loadView];
	self.view.backgroundColor = [UIColor blackColor];

	// logbox
	logbox = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	logbox.textColor = [UIColor greenColor];
	logbox.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
	logbox.layer.cornerRadius = 10;
	logbox.font = [UIFont fontWithName:@"Courier" size:12];
	logbox.editable = NO;
	logbox.text = @"";
	[self.view addSubview:logbox];

	// button that will open a alert with actions on what to do
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[button setTitle:@"kfdfun" forState:UIControlStateNormal];
	button.frame = CGRectMake(self.view.frame.size.width/2-50, self.view.frame.size.height-100, 100, 50);
	[self.view addSubview:button];

	// pipe stdout & stderr to logbox
	setvbuf(stdout, NULL, _IOLBF, 0);
	NSPipe *pipe = [NSPipe pipe];
	dup2([[pipe fileHandleForWriting] fileDescriptor], fileno(stdout));
	dup2([[pipe fileHandleForWriting] fileDescriptor], fileno(stderr));
	[[pipe fileHandleForReading] waitForDataInBackgroundAndNotify];
	[[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:[pipe fileHandleForReading] queue:nil usingBlock:^(NSNotification *notification){
		NSData *output = [[pipe fileHandleForReading] availableData];
		NSString *outStr = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
		[self logString:outStr];
		[[pipe fileHandleForReading] waitForDataInBackgroundAndNotify];
	}];

	printf("========================================\n");
	printf(":: kfdfun\n");
	printf("::\n");
	printf(":: HUGE THANKS TO @htrowii FOR THE METHOD\n");
	printf(":: AND HELPING ME WITH THE CHAIN\n");
	printf("::\n");
	printf(":: BUILD_TIME: %s %s\n", __DATE__, __TIME__);
	printf(":: BUILD_STYLE: %s\n", "DEBUG");
	printf("::\n");
	printf(":: PRIVATE BUILD - DO NOT LEAK\n");
	printf("::\n");
	printf("========================================\n");
}

int setup(void);
int sign_tweaks(void);

- (void)buttonPressed:(UIButton *)button {
	// action sheet
	#ifdef USE_MANUAL_EXPLOIT_METHOD
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"kfdfun" message:@"Choose an action" preferredStyle:UIAlertControllerStyleActionSheet];

	[alert addAction:[UIAlertAction actionWithTitle:@"Exploit kernel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			kopen_wrapper(2);
		});
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:@"Setup" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			setup();
		});
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:@"Sign tweaks" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			sign_tweaks();
		});
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:@"launchd haxx" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			if (is_exploited()) {
				printf("[+] launching launchd haxx\n");
				launchd_haxx();
			} else {
				printf("[-] kernel not exploited, do that first\n");
			}
		});
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:@"Userspace Reboot" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			printf("[+] userspace reboot\n");
			userspaceReboot();
		});
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
	}]];

	[self presentViewController:alert animated:YES completion:nil];

	#else

	// just do everything
	// ask for exploit method ( 0 = physpuppet, 1 = smith, 2 = landa )
	__block int exploit_method = 2;
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"kfdfun" message:@"Choose an exploit method" preferredStyle:UIAlertControllerStyleAlert];

	[alert addAction:[UIAlertAction actionWithTitle:@"physpuppet" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		exploit_method = 0;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		kopen_wrapper(exploit_method);
		setup();
		if (is_exploited()) {
			printf("[+] launching launchd haxx\n");
			launchd_haxx();
		} else {
			printf("[-] kernel not exploited, do that first\n");
		}
		userspaceReboot();
		});
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:@"smith" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		exploit_method = 1;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		kopen_wrapper(exploit_method);
		setup();
		if (is_exploited()) {
			printf("[+] launching launchd haxx\n");
			launchd_haxx();
		} else {
			printf("[-] kernel not exploited, do that first\n");
		}
		userspaceReboot();
		});
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:@"landa" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		exploit_method = 2;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		kopen_wrapper(exploit_method);
		setup();
		if (is_exploited()) {
			printf("[+] launching launchd haxx\n");
			launchd_haxx();
		} else {
			printf("[-] kernel not exploited, do that first\n");
		}
		userspaceReboot();
		});
	}]];

	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
	}]];
	[self presentViewController:alert animated:YES completion:nil];

	#endif
}

@end
