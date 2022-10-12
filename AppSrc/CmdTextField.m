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
#import "GlkWindowState.h"
#import "StyleSet.h"
#import "GlkUtilities.h"

@implementation CmdTextField

@synthesize rightsideview;
@synthesize clearbutton;
@synthesize menubutton;
@synthesize wintag;

- (id) initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
	}
	return self;
}


- (BOOL) becomeFirstResponder {
	BOOL res = [super becomeFirstResponder];
	if (!res)
		return NO;
	
	rightsideview.hidden = NO;
	[[IosGlkViewController singleton] preferInputWindow:wintag];
	return YES;
}

- (BOOL) resignFirstResponder {
	BOOL res = [super resignFirstResponder];
	if (!res)
		return NO;
	
	rightsideview.hidden = YES;
	return YES;
}

- (void) setUpForWindow:(GlkWindowView *)winv singleChar:(BOOL)singleval {
	GlkWindowState *win = winv.winstate;
	self.wintag = win.tag;
	
	self.delegate = winv;
	singlechar = singleval;
	
	[self adjustForWindowStyles:winv.styleset];
	//self.borderStyle = UITextBorderStyleBezel;
	self.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.keyboardType = UIKeyboardTypeASCIICapable;
	
	if (singlechar) {
		//self.clearButtonMode = UITextFieldViewModeNever;
		self.rightViewMode = UITextFieldViewModeNever;
		self.rightView = nil;
	}
	else {
		[[NSBundle mainBundle] loadNibNamed:@"TextFieldRightView" owner:self options:nil];
		UIImage *img;
		img = [menubutton backgroundImageForState:UIControlStateNormal];
		img = [img stretchableImageWithLeftCapWidth:img.size.width/2 topCapHeight:img.size.height/2];
		[menubutton setBackgroundImage:img forState:UIControlStateNormal];
		//img = [clearbutton backgroundImageForState:UIControlStateNormal];
		//img = [img stretchableImageWithLeftCapWidth:img.size.width/2 topCapHeight:img.size.height/2];
		//[clearbutton setBackgroundImage:img forState:UIControlStateNormal];
		rightsideview.hidden = ![self isFirstResponder];
		
		//self.clearButtonMode = UITextFieldViewModeWhileEditing;
		self.rightViewMode = UITextFieldViewModeAlways;
		self.rightView = self.rightsideview;
	}

	if (win.line_request && win.line_request_initial)
		self.text = win.line_request_initial;
	else
		self.text = @"";
	
	[self adjustInputTraits];
}

- (void) adjustForWindowStyles:(StyleSet *)styleset {
	//self.backgroundColor = styleset.backgroundcolor;
	self.font = styleset.fonts[style_Input];
	self.textColor = styleset.colors[style_Input];
}

- (void) adjustInputTraits {
	/* Bug: changing the returnKeyType in an existing field doesn't change the open keyboard. I don't care right now. */
	if (singlechar) {
		self.returnKeyType = UIReturnKeyDefault;
		self.autocorrectionType = UITextAutocorrectionTypeNo;
	}
	else {
		self.returnKeyType = UIReturnKeyGo;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults boolForKey:@"NoAutocorrect"])
			self.autocorrectionType = UITextAutocorrectionTypeNo;
		else
			self.autocorrectionType = UITextAutocorrectionTypeDefault;
	}
}

- (BOOL) singleChar {
	return singlechar;
}

- (CGRect) rightViewRectForBounds:(CGRect)bounds {
	return CGRectMake(bounds.size.width-48, 0, 48, bounds.size.height);
}

- (void) handleClearButton:(id)sender {
	if (singlechar)
		return;
	self.text = @"";
}

- (void) handleMenuButton:(id)sender {
	if (singlechar)
		return;
	GlkFrameView *frameview = [IosGlkViewController singleton].frameview;
	GlkWindowView *winv = [frameview windowViewForTag:wintag];
	
	[winv postInputMenu];
}

- (void) applyInputString:(NSString *)cmd replace:(BOOL)replace {
	if (singlechar)
		return;
	
	if (replace) {
		self.text = cmd;
		return;
	}
	
	NSString *oldcmd = self.text;
	
	UITextRange *selection = self.selectedTextRange;
	if (selection) {
		NSString *prefix = [self textInRange:[self textRangeFromPosition:self.beginningOfDocument toPosition:selection.start]];
		if (prefix && prefix.length > 0 && ![prefix hasSuffix:@" "])
			cmd = [@" " stringByAppendingString:cmd];
		NSString *suffix = [self textInRange:[self textRangeFromPosition:selection.end toPosition:self.endOfDocument]];
		if (!(suffix && suffix.length > 0 && [suffix hasPrefix:@" "]))
			cmd = [cmd stringByAppendingString:@" "];
		[self replaceRange:selection withText:cmd];
		return;
	}
	
	// Fallback -- we couldn't get the selection, or whatever. Just append the text.
	if (oldcmd.length > 0 && ![oldcmd hasSuffix:@" "])
		cmd = [@" " stringByAppendingString:cmd];
	cmd = [cmd stringByAppendingString:@" "];
	self.text = [oldcmd stringByAppendingString:cmd];
}

@end

