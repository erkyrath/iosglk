/* IosGlkAppDelegate.h: App delegate class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>

@class IosGlkViewController;
@class GlkLibrary;
@class GlkAppWrapper;

@interface IosGlkAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	
	/* These could refer to the same IosGlkViewController, or rootviewc could be a UINavigationController. Up to the application. TheMainWindow nib determines the layout. */
	UIViewController *rootviewc;
	IosGlkViewController *glkviewc;
	
	GlkLibrary *library;
	GlkAppWrapper *glkapp;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *rootviewc;
@property (nonatomic, retain) IBOutlet IosGlkViewController *glkviewc;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *styleButton;

@property (nonatomic, retain) GlkLibrary *library;
@property (nonatomic, retain) GlkAppWrapper *glkapp;

+ (IosGlkAppDelegate *) singleton;
+ (BOOL) animblocksavailable;
+ (BOOL) gesturesavailable;
+ (BOOL) understandspng;
+ (BOOL) oldstyleui;
+ (NSString *) imageHackPNG:(NSString *)name;

@end

