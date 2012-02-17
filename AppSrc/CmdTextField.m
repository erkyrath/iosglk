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
	GlkFrameView *frameview = [IosGlkViewController singleton].frameview;
	[frameview postInputMenuForWindow:wintag];
}

- (void) applyInputString:(NSString *)cmd replace:(BOOL)replace {
	if (singlechar)
		return;
	
	if (replace) {
		self.text = cmd;
		return;
	}
	
	NSString *oldcmd = self.text;
	
	// OS dependency: UITextRange and selectedTextRange are iOS 3.2 and later. Actually, in the simulator at least, they require iOS 5.
	if ([self respondsToSelector:@selector(selectedTextRange)]) {
		UITextRange *selection = self.selectedTextRange;
		if (selection) {
			NSString *prefix = [self textInRange:[self textRangeFromPosition:self.beginningOfDocument toPosition:selection.start]];
			if (prefix && prefix.length > 0 && ![prefix hasSuffix:@" "])
				cmd = [@" " stringByAppendingString:cmd];
			NSString *suffix = [self textInRange:[self textRangeFromPosition:selection.end toPosition:self.endOfDocument]];
			if (suffix && suffix.length > 0 && ![suffix hasPrefix:@" "])
				cmd = [cmd stringByAppendingString:@" "];
			[self replaceRange:selection withText:cmd];
			return;
		}
	}
	
	// Fallback -- old iOS, or we couldn't get the selection, or whatever. Just append the text.
	if (oldcmd.length > 0 && ![oldcmd hasSuffix:@" "])
		cmd = [@" " stringByAppendingString:cmd];
	self.text = [oldcmd stringByAppendingString:cmd];
}

@end

