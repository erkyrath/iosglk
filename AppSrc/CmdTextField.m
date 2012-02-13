/* CmdTextField.m: UITextField subclass with extra IF features
 for IosGlk, the iOS implementation of the Glk API.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */


#import "CmdTextField.h"
#import "IosGlkViewController.h"
#import "GlkWindowView.h"
#import "GlkFrameView.h"
#import "GlkWindow.h"
#import "StyleSet.h"
#import "GlkUtilities.h"

@implementation CmdTextField

@synthesize menubutton;
@synthesize wintag;

- (id) initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.menubutton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[menubutton addTarget:self action:@selector(handleMenuButton:) forControlEvents:UIControlEventTouchUpInside];
	}
	return self;
}

- (void) dealloc {
	self.menubutton = nil;
	self.wintag = nil;
	[super dealloc];
}


- (void) setUpForWindow:(GlkWindowView *)winv singleChar:(BOOL)singleval {
	GlkWindow *win = winv.win;
	self.wintag = win.tag;
	
	self.delegate = winv;
	singlechar = singleval;
	
	self.backgroundColor = winv.backgroundColor;
	self.font = win.styleset.fonts[style_Input];
	//self.borderStyle = UITextBorderStyleBezel;
	self.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.keyboardType = UIKeyboardTypeASCIICapable;
	
	//self.clearButtonMode = UITextFieldViewModeWhileEditing;
	if (singlechar) {
		self.rightViewMode = UITextFieldViewModeNever;
		self.rightView = nil;
	}
	else {
		self.rightViewMode = UITextFieldViewModeWhileEditing;
		self.rightView = self.menubutton;
	}

	if (win.line_request && win.line_request_initial)
		self.text = win.line_request_initial;
	else
		self.text = @"";
	
	/* Bug: changing the returnKeyType in an existing field doesn't change the open keyboard. I don't care right now. */
	if (singlechar) {
		self.returnKeyType = UIReturnKeyDefault;
		self.autocorrectionType = UITextAutocorrectionTypeNo;
	}
	else {
		self.returnKeyType = UIReturnKeyGo;
		self.autocorrectionType = UITextAutocorrectionTypeDefault;
	}
	
}

- (BOOL) singleChar {
	return singlechar;
}

- (CGRect) rightViewRectForBounds:(CGRect)bounds {
	return CGRectMake(bounds.size.width-48, 0, 48, bounds.size.height);
}

- (void) handleMenuButton:(id)sender {
	if (singlechar)
		return;
	GlkFrameView *frameview = [IosGlkViewController singleton].viewAsFrameView;
	[frameview postInputMenuForWindow:wintag];
}


@end

