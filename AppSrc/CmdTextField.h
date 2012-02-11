/* CmdTextField.h: UITextField subclass with extra IF features
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import <UIKit/UIKit.h>

@class GlkWindowView;

@interface CmdTextField : UITextField

- (void) setUpForWindow:(GlkWindowView *)winv singleChar:(BOOL)singleChar;

@end
