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

@property (nonatomic, retain) IBOutlet UIView *rightsideview;
@property (nonatomic, retain) IBOutlet UIButton *clearbutton;
@property (nonatomic, retain) IBOutlet UIButton *menubutton;
@property (nonatomic, retain) NSNumber *wintag;

- (void) setUpForWindow:(GlkWindowView *)winv singleChar:(BOOL)singleChar;
- (void) adjustInputTraits;
- (void) adjustForWindowStyles:(StyleSet *)styleset;
- (BOOL) singleChar;
- (void) applyInputString:(NSString *)cmd replace:(BOOL)replace;

- (IBAction) handleMenuButton:(id)sender;
- (IBAction) handleClearButton:(id)sender;

@end
