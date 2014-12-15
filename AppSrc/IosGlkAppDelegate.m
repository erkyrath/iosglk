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
static BOOL animblocksavailable = NO; /* true for iOS4 and up */
static BOOL gesturesavailable = NO; /* true for iOS3.2 and up */
static BOOL understandspng = NO; /* true for iOS4 and up */
static BOOL oldstyleui = NO; /* true for everything *before* iOS7 */

+ (IosGlkAppDelegate *) singleton {
	return singleton;
}

+ (BOOL) animblocksavailable {
	return animblocksavailable;
}

+ (BOOL) gesturesavailable {
	return gesturesavailable;
}

+ (BOOL) understandspng {
	return understandspng;
}

+ (BOOL) oldstyleui {
	return oldstyleui;
}

+ (NSString *) imageHackPNG:(NSString *)name {
	if (!understandspng)
		name = [name stringByAppendingString:@".png"];
	return name;
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {	
	//NSLog(@"AppDelegate finished launching");	
	singleton = self;
	
	/* Test if animations are available. */
	animblocksavailable = [[UIView class] respondsToSelector:@selector(animateWithDuration:animations:)];

	{
		NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
		
		/* Test if PNG files are recognized out of the box. */
		NSString *reqSysVer = @"4.0";
		understandspng = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
		
		/* Test if we have the old (iOS6, gradient-and-gloss) interface style. */
		reqSysVer = @"7.0";
		oldstyleui = !([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
	}

	/* Funny idiom for testing if gestures are available; boilerplated from iOS docs. (Only needed for iOS3, but I'm leaving it in here anyway. This produces an "undeclared selector" warning which we ignore.) */
	UIGestureRecognizer *testgesture = [[[UIGestureRecognizer alloc] initWithTarget:self action:@selector(myAction:)] autorelease];
	gesturesavailable = [testgesture respondsToSelector:@selector(locationInView:)];

	// Add the view controller's view to the window and display. If we're not on iOS3, set the window's rootViewController too.
	[self.window addSubview:rootviewc.view];
	if ([self.window respondsToSelector:@selector(setRootViewController:)])
		[self.window setRootViewController:rootviewc];
	[self.window makeKeyAndVisible];

	/* In an interpreter app, glkviewc is different from rootviewc, which means that glkviewc might not have loaded its view. We must force this now, or the VM thread gets all confused and sad. We force the load by accessing glkviewc.view. */
	[glkviewc view];
	
	self.library = [[[GlkLibrary alloc] init] autorelease];
	self.glkapp = [[[GlkAppWrapper alloc] init] autorelease];
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
	self.library = nil;
	self.rootviewc = nil;
	self.glkviewc = nil;
	[window release];
	[super dealloc];
}

/* A .glksave URL was passed to this application by another. The URL will be a file in Documents/Inbox. We should check whether it matches our game; if so, move it to the appropriate directory and return YES; if not, delete it and return NO.
 
 This is only called if the Info.plist file contains CFBundleDocumentTypes for the .glksave UTI. If the URL launched us, this will be called immediately after diFinishLaunching.
 */
- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	NSLog(@"### appOpenURL %@, from %@, note %@", url, sourceApplication, annotation);
	// This function is iOS5+. The project is set to require iOS5.1.1, so that's fine, but be careful if you're back-porting.
	if (![url isFileURL]) {
		NSLog(@"applicationOpenURL: not a file: URL; rejecting");
		[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
		return NO;
	}
	
	NSString *path = url.path;
	
	// Now we try to work out the type (UTI). This has to be done through the file extension, apparently. The UTType functions are C, so we need manual release.
	CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)(path.pathExtension), NULL);
	BOOL issavefile = UTTypeConformsTo(uti, (CFStringRef)(@"com.eblong.glk.glksave"));
	NSLog(@"### ... dropped file path %@, type '%@' (issavefile %d)", path, uti, issavefile);
	CFRelease(uti);

	if (!issavefile) {
		//### display an alert
		[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
		return NO;
	}
	
	// Now we check whether this is a save file for our game. The Glk library delegate makes that decision.
	GlkSaveFormat res = [self.library.glkdelegate checkGlkSaveFileFormat:path];
	if (res != saveformat_Ok) {
		//### display an alert based on res
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
	NSLog(@"### %@ -> %@ -> %@: %@", filename, barefilename, newfilename, newpathname);
	
	//### Check for already-exists!
	
	NSError *error = nil;
	[[NSFileManager defaultManager] moveItemAtPath:path toPath:newpathname error:&error];
	if (error) {
		//### display alert?
		NSLog(@"applicationOpenURL: move failed: %@", error);
		return NO;
	}
	
	//### Flip to settings/share tab? Would have to be another delegate call.
	
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
