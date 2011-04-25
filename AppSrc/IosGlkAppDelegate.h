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
	IosGlkViewController *viewController;
	
	GlkLibrary *library;
	GlkAppWrapper *glkapp;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet IosGlkViewController *viewController;

@property (nonatomic, retain) GlkLibrary *library;
@property (nonatomic, retain) GlkAppWrapper *glkapp;

+ (IosGlkAppDelegate *) singleton;

@end

