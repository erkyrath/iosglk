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

- (void) setUpForWindow:(GlkWindowView *)winv singleChar:(BOOL)singleChar {
	GlkWindow *win = winv.win;
	
	self.delegate = winv;
	
	self.backgroundColor = [UIColor whiteColor];
	self.font = win.styleset.fonts[style_Input];
	//self.borderStyle = UITextBorderStyleBezel;
	self.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.keyboardType = UIKeyboardTypeASCIICapable;
	
	self.clearButtonMode = UITextFieldViewModeWhileEditing;

	if (win.line_request && win.line_request_initial)
		self.text = win.line_request_initial;
	else
		self.text = @"";
	
	/* Bug: changing the returnKeyType in an existing field doesn't change the open keyboard. I don't care right now. */
	if (singleChar) {
		self.returnKeyType = UIReturnKeyDefault;
		self.autocorrectionType = UITextAutocorrectionTypeNo;
	}
	else {
		self.returnKeyType = UIReturnKeyGo;
		self.autocorrectionType = UITextAutocorrectionTypeDefault;
	}
	
}

@end
