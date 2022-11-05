/* IosGlkAppDelegate.h: App delegate class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>

@class IosGlkViewController;
@class GlkLibrary;
@class GlkAppWrapper;

@interface IosGlkAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IosGlkViewController *glkviewc;

/* These could refer to the same IosGlkViewController, or rootviewc could be a UINavigationController. Up to the application. TheMainWindow nib determines the layout. */
@property (nonatomic, strong) GlkLibrary *library;
@property (nonatomic, strong) GlkAppWrapper *glkapp;

+ (IosGlkAppDelegate *) singleton;

@end

