/* IosGlkAppDelegate.m: App delegate class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import "IosGlkAppDelegate.h"
#import "IosGlkViewController.h"
#import "IosGlkLibDelegate.h"

#import "GlkFrameView.h"
#import "GlkLibrary.h"
#import "GlkAppWrapper.h"

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

	/* Test if PNG files are recognized out of the box. */
	{
		NSString *reqSysVer = @"4.0";
		NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
		understandspng = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
	}

	/* Funny idiom for testing if gestures are available; boilerplated from iOS docs. */
	UIGestureRecognizer *testgesture = [[[UIGestureRecognizer alloc] initWithTarget:self action:@selector(myAction:)] autorelease];
	gesturesavailable = [testgesture respondsToSelector:@selector(locationInView:)];

	// Add the view controller's view to the window and display.
	[self.window addSubview:rootviewc.view];
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
