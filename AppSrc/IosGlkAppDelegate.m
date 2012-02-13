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

+ (IosGlkAppDelegate *) singleton {
	return singleton;
}


- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {	
	NSLog(@"AppDelegate finished launching");	
	// Override point for customization after application launch.
	singleton = self;

	// Add the view controller's view to the window and display.
	[self.window addSubview:rootviewc.view];
	[self.window makeKeyAndVisible];

	NSLog(@"AppDelegate loaded root view controller");

	self.library = [[[GlkLibrary alloc] init] autorelease];
	self.glkapp = [[[GlkAppWrapper alloc] init] autorelease];
	if (glkviewc.glkdelegate)
		library.glkdelegate = glkviewc.glkdelegate;
	else
		library.glkdelegate = [DefaultGlkLibDelegate singleton];
	
	/* In an interpreter app, glkviewc is different from rootviewc, which means that glkviewc might not have loaded its view. We must force this now, or the VM thread gets all confused and sad. We force the load by accessing glkviewc.view, and then discarding the value -- *that* confuses Xcode's static analyzer, but I don't care. */
	UIView *view = glkviewc.view;
	view = nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:glkviewc
											 selector:@selector(keyboardWillBeShown:)
												 name:UIKeyboardWillShowNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:glkviewc
											 selector:@selector(keyboardWillBeHidden:)
												 name:UIKeyboardWillHideNotification object:nil];
	
	[library setMetrics:glkviewc.frameview.bounds];

	NSLog(@"AppDelegate launching app thread");
	
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


- (void) applicationWillResignActive:(UIApplication *)application {
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}


- (void) applicationDidEnterBackground:(UIApplication *)application {
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
	 */
}


- (void) applicationWillEnterForeground:(UIApplication *)application {
	/*
	 Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
	 */
}


- (void) applicationDidBecomeActive:(UIApplication *)application {
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}


- (void) applicationWillTerminate:(UIApplication *)application {
	/*
	 Called when the application is about to terminate.
	 See also applicationDidEnterBackground:.
	 */
}


- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
	/*
	 Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
	 */
}



@end
