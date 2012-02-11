/* CmdTextField.h: UITextField subclass with extra IF features
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

@class GlkWindowView;

@interface CmdTextField : UITextField {
	UIButton *menubutton;
	BOOL singlechar;
	
	NSNumber *wintag;
}

@property (nonatomic, retain) UIButton *menubutton;
@property (nonatomic, retain) NSNumber *wintag;

- (void) setUpForWindow:(GlkWindowView *)winv singleChar:(BOOL)singleChar;

@end
