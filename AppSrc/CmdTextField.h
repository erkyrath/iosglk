/* CmdTextField.h: UITextField subclass with extra IF features
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

@class GlkWindowView;
@class StyleSet;

@interface CmdTextField : UITextField {
	UIView *rightsideview;
	UIButton *clearbutton;
	UIButton *menubutton;
	BOOL singlechar;
	
	NSNumber *wintag;
}

@property (nonatomic, strong) IBOutlet UIView *rightsideview;
@property (nonatomic, strong) IBOutlet UIButton *clearbutton;
@property (nonatomic, strong) IBOutlet UIButton *menubutton;
@property (nonatomic, strong) NSNumber *wintag;

- (void) setUpForWindow:(GlkWindowView *)winv singleChar:(BOOL)singleChar;
- (void) adjustInputTraits;
- (void) adjustForWindowStyles:(StyleSet *)styleset;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL singleChar;
- (void) applyInputString:(NSString *)cmd replace:(BOOL)replace;

- (IBAction) handleMenuButton:(id)sender;
- (IBAction) handleClearButton:(id)sender;

@end
