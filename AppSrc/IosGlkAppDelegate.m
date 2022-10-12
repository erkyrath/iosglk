/* IosGlkAppDelegate.m: App delegate class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <MobileCoreServices/MobileCoreServices.h>

#import "IosGlkAppDelegate.h"
#import "IosGlkViewController.h"
#import "IosGlkLibDelegate.h"

#import "GlkFrameView.h"
#import "GlkLibrary.h"
#import "GlkFileRef.h"
#import "GlkAppWrapper.h"
#import "GlkUtilities.h"

#include "glk.h"

@implementation IosGlkAppDelegate

@synthesize window;
@synthesize rootviewc;
@synthesize glkviewc;
@synthesize library;
@synthesize glkapp;

static IosGlkAppDelegate *singleton = nil; /* retained forever */
static BOOL oldstyleui = NO; /* true for everything *before* iOS7 */

+ (IosGlkAppDelegate *) singleton {
	return singleton;
}

+ (BOOL) oldstyleui {
	return oldstyleui;
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {	
	//NSLog(@"AppDelegate finished launching");	
	singleton = self;
	
	{
		NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
		
		/* Test if we have the old (iOS6, gradient-and-gloss) interface style. */
		NSString *reqSysVer = @"7.0";
		oldstyleui = !([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
	}

	// Add the view controller's view to the window and display. If we're not on iOS3, set the window's rootViewController too.
	[self.window addSubview:rootviewc.view];
	[self.window setRootViewController:rootviewc];
	[self.window makeKeyAndVisible];

	/* In an interpreter app, glkviewc is different from rootviewc, which means that glkviewc might not have loaded its view. We must force this now, or the VM thread gets all confused and sad. We force the load by accessing glkviewc.view. */
	[glkviewc view];
	
	self.library = [[GlkLibrary alloc] init];
	self.glkapp = [[GlkAppWrapper alloc] init];
	/* Set library.glkdelegate to a default value, if the glkviewc doesn't provide one. (Remember, from now on, that glkviewc.glkdelegate may be null!) */
	if (glkviewc.glkdelegate)
		library.glkdelegate = glkviewc.glkdelegate;
	else
		library.glkdelegate = [DefaultGlkLibDelegate singleton];
	
	[[NSNotificationCenter defaultCenter] addObserver:glkviewc
											 selector:@selector(keyboardWillBeShown:)
												 name:UIKeyboardWillShowNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:glkviewc
											 selector:@selector(keyboardWillBeHidden:)
												 name:UIKeyboardWillHideNotification object:nil];
	
	[glkviewc didFinishLaunching];
	
	CGRect box = glkviewc.frameview.bounds;
	if (glkviewc.glkdelegate)
		box = [glkviewc.glkdelegate adjustFrame:box];
	[library setMetricsChanged:YES bounds:&box];

	//NSLog(@"AppDelegate launching app thread");
	
	[glkapp launchAppThread];
	return YES;
}


- (void) dealloc {
	singleton = nil;
}

/* A .glksave URL was passed to this application by another. The URL will be a file in Documents/Inbox. We should check whether it matches our game; if so, move it to the appropriate directory and return YES; if not, delete it and return NO.
 
 This is only called if the Info.plist file contains CFBundleDocumentTypes for the .glksave UTI. If the URL launched us, this will be called immediately after diFinishLaunching.
 */
- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	NSLog(@"applicationOpenURL: %@ (from %@)", url, sourceApplication);
	
	// This function is iOS5+. The project is set to require iOS5.1.1, so that's fine, but be careful if you're back-porting.
	if (![url isFileURL]) {
		[self.glkviewc displayAdHocAlert:NSLocalizedString(@"openfile.not-file-url", nil) title:nil];
		[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
		return NO;
	}
	
	NSString *path = url.path;
	
	// Now we try to work out the type (UTI). This has to be done through the file extension, apparently. The UTType functions are C, so we need manual release.
	CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)(path.pathExtension), NULL);
	BOOL issavefile = UTTypeConformsTo(uti, (CFStringRef)(@"com.eblong.glk.glksave"));
	//NSLog(@"### ... dropped file path %@, type '%@' (issavefile %d)", path, uti, issavefile);
	CFRelease(uti);

	if (!issavefile) {
		[self.glkviewc displayAdHocAlert:NSLocalizedString(@"openfile.not-save-file", nil) title:nil];
		[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
		return NO;
	}
	
	// Now we check whether this is a save file for our game. The Glk library delegate makes that decision.
	GlkSaveFormat res = [self.library.glkdelegate checkGlkSaveFileFormat:path];
	if (res != saveformat_Ok) {
		NSString *msg = nil;
		switch (res) {
			case saveformat_WrongVersion:
				msg = NSLocalizedString(@"openfile.wrong-version", nil);
				break;
			case saveformat_WrongGame:
				msg = NSLocalizedString(@"openfile.wrong-game", nil);
				break;
			case saveformat_UnknownFormat:
				msg = NSLocalizedString(@"openfile.unknown-format", nil);
				break;
			default:
			case saveformat_Unreadable:
				msg = NSLocalizedString(@"openfile.unreadable", nil);
				break;
		}
		[self.glkviewc displayAdHocAlert:msg title:nil];
		[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
		return NO;
	}
	
	// Move the file into the appropriate subdirectory for fileusage_SavedGame. We'll need to give it the appropriate name -- dumbass-encoded and with no file extension.
	NSString *filename = [path lastPathComponent];
	NSString *barefilename = [filename stringByDeletingPathExtension];
	if (barefilename.length == 0)
		barefilename = @"Save file";
	NSString *newfilename = StringToDumbEncoding(barefilename);
	
	NSString *basedir = [GlkFileRef documentsDirectory];
	NSString *dirname = [GlkFileRef subDirOfBase:basedir forUsage:fileusage_SavedGame gameid:self.library.gameId];
	NSString *newpathname = [dirname stringByAppendingPathComponent:newfilename];
	//NSLog(@"### %@ -> %@ -> %@: %@", filename, barefilename, newfilename, newpathname);

	if (![[NSFileManager defaultManager] fileExistsAtPath:dirname isDirectory:nil])
		[[NSFileManager defaultManager] createDirectoryAtPath:dirname withIntermediateDirectories:YES attributes:nil error:nil];

	if ([[NSFileManager defaultManager] fileExistsAtPath:newpathname]) {
		// There's already a file of that name. Ask what to do. This requires a callback.
		// I'm using an ad-hoc and probably silly way to generate an alternative filename. If the current name seems to end with a number, increment it. Otherwise, append "-1". Repeat until we have clearance. (But only 32 times, because look, we'd rather fail than get stuck forever.)
		NSRegularExpression *pat = [NSRegularExpression regularExpressionWithPattern:@"^.*-([0-9]+)$" options:0 error:nil];
		NSString *barefilename2 = barefilename;
		NSString *newfilename2 = nil;
		NSString *newpathname2 = nil;
		for (int try=0; try<32; try++) {
			NSString *curname = barefilename2;
			NSTextCheckingResult *match = [pat firstMatchInString:curname options:0 range:NSMakeRange(0, curname.length)];
			if (match && [match rangeAtIndex:1].location != NSNotFound) {
				int val = [curname substringWithRange:[match rangeAtIndex:1]].intValue;
				barefilename2 = [NSString stringWithFormat:@"%@%d", [curname substringToIndex:[match rangeAtIndex:1].location], val+1];
			}
			else {
				barefilename2 = [curname stringByAppendingString:@"-1"];
			}
			newfilename2 = StringToDumbEncoding(barefilename2);
			newpathname2 = [dirname stringByAppendingPathComponent:newfilename2];
			if (![[NSFileManager defaultManager] fileExistsAtPath:newpathname2])
				break;
		}
		//NSLog(@"### generated %@ -> %@ : %@", barefilename, barefilename2, newpathname2);
		
		NSString *key;
		key = NSLocalizedString(@"openfile.already-exists", nil);
		NSString *qstr = [NSString stringWithFormat:key, barefilename];
		key = NSLocalizedString(@"openfile.already-exists-opt1", nil);
		NSString *opt1str = [NSString stringWithFormat:key, barefilename];
		key = NSLocalizedString(@"openfile.already-exists-opt2", nil);
		NSString *opt2str = [NSString stringWithFormat:key, barefilename2];
		questioncallback qcallback = ^(int res) {
			if (res <= 0) {
				// Cancel; delete the temporary file.
				[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
				return;
			}
			NSString *usepathname = nil;
			NSString *usefilename = nil;
			if (res == 2) {
				// Use new name
				usepathname = newpathname2;
				usefilename = newfilename2;
			}
			else {
				// Replace old file
				usepathname = newpathname;
				usefilename = newfilename;
				NSError *error = nil;
				[[NSFileManager defaultManager] removeItemAtPath:usepathname error:&error];
				if (error) {
					NSLog(@"applicationOpenURL: remove-old failed: %@", error);
				}
			}
			NSError *error = nil;
			[[NSFileManager defaultManager] moveItemAtPath:path toPath:usepathname error:&error];
			if (error) {
				NSLog(@"applicationOpenURL: move failed: %@", error);
				[self.glkviewc displayAdHocAlert:NSLocalizedString(@"openfile.move-failed", nil) title:nil];
			}
			[self.library.glkdelegate displayGlkFileUsage:fileusage_SavedGame name:usefilename];
			return;
		};
		[self.glkviewc displayAdHocQuestion:qstr option:opt1str option:opt2str callback:qcallback];
	}
	else {
		// Move the file without further prompting.
		NSError *error = nil;
		[[NSFileManager defaultManager] moveItemAtPath:path toPath:newpathname error:&error];
		if (error) {
			NSLog(@"applicationOpenURL: move failed: %@", error);
			[self.glkviewc displayAdHocAlert:NSLocalizedString(@"openfile.move-failed", nil) title:nil];
		}
		[self.library.glkdelegate displayGlkFileUsage:fileusage_SavedGame name:newfilename];
	}
	
	// The user may still be at a prompt, but we have to pass an answer back, so we'll accept responsibility.
	return YES;
}

/* The application is about to become inactive. (Incoming phone call or SMS alert; device is going to sleep; the user called up the process-bar; or the user "quit" and we are about to be backgrounded.)
 
 We should save, and also pause tasks and timers.
 */
- (void) applicationWillResignActive:(UIApplication *)application {
	[glkviewc becameInactive];
	
	/* I think maybe this happens automatically, but I'm not positive. Doesn't hurt to be sure. */
	[[NSUserDefaults standardUserDefaults] synchronize];
}

/* User "quit" the application, either with the home button or the process-bar. We should release as much memory as possible.
 */
- (void) applicationDidEnterBackground:(UIApplication *)application {
	[glkviewc enteredBackground];
}

/* User "launched" the application. This will be followed immediately by applicationDidBecomeActive.
 */
- (void) applicationWillEnterForeground:(UIApplication *)application {
}

/* The application has returned to being active.
 */
- (void) applicationDidBecomeActive:(UIApplication *)application {
	[glkviewc becameActive];
}

/* The application is being seriously shut down. (This is only called for OS3 and for old (third-gen) devices, where backgrounding doesn't exist.)
 */
- (void) applicationWillTerminate:(UIApplication *)application {
}


- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
	/*
	 Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
	 */
}



@end
