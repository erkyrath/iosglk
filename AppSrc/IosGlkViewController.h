/* IosGlkViewController.h: Main view controller class
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

#import <UIKit/UIKit.h>

@class GlkFrameView;
@protocol IosGlkLibDelegate;

@interface IosGlkViewController : UIViewController {
	id <IosGlkLibDelegate> glkdelegate;
	GlkFrameView *frameview;
}

@property (nonatomic, assign) IBOutlet id <IosGlkLibDelegate> glkdelegate; // delegates are nonretained
@property (nonatomic, retain) IBOutlet GlkFrameView *frameview;

+ (IosGlkViewController *) singleton;

- (void) didFinishLaunching;
- (void) hideKeyboard;
- (void) displayModalRequest:(id)special;

- (IBAction) toggleKeyboard;

@end

