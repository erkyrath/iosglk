/* CmdTextField.m: UITextField subclass with extra IF features
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */


#import "CmdTextField.h"
#import "GlkWindowView.h"
#import "GlkWindow.h"
#import "StyleSet.h"

@implementation CmdTextField

- (void) setUpForWindow:(GlkWindowView *)winv {
	self.backgroundColor = [UIColor whiteColor];
	self.font = winv.win.styleset.fonts[style_Input];
	//self.borderStyle = UITextBorderStyleBezel;
	self.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.keyboardType = UIKeyboardTypeASCIICapable;
	self.delegate = winv;
}

@end
