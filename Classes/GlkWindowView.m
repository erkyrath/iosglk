/* GlkWindowView.m: Base class for a Glk window view
	for IosGlk, the iOS implementation of the Glk API.
	Designed by Andrew Plotkin <erkyrath@eblong.com>
	http://eblong.com/zarf/glk/
*/

/*	From the library's point of view, a Glk window (GlkWindow object) is a data object. It is represented on-screen by a view object, which is a subclass of GlkWindowView. These windowviews are children of the GlkFrameView.

	(We don't try to follow the Cocoa model of data changes triggering view changes. GlkWindows are totally inert. The GlkFrameView will tip us off when it's time for the windowview to update.)
*/

#import "GlkWindowView.h"
#import "GlkWinBufferView.h"
#import "GlkWinGridView.h"
#import "GlkWindow.h"
#import "GlkAppWrapper.h"
#include "GlkUtilities.h"

@implementation GlkWindowView

@synthesize win;
@synthesize textfield;

+ (GlkWindowView *) viewForWindow:(GlkWindow *)win {
	switch (win.type) {
		case wintype_TextBuffer:
			return [[[GlkWinBufferView alloc] initWithWindow:win frame:win.bbox] autorelease];
		case wintype_TextGrid:
			return [[[GlkWinGridView alloc] initWithWindow:win frame:win.bbox] autorelease];
		default:
			[NSException raise:@"GlkException" format:@"no windowview class for this window"];
			return nil; // not really
	}
}


- (id) initWithWindow:(GlkWindow *)winref frame:(CGRect)box {
	self = [super initWithFrame:box];
	if (self) {
		self.win = winref;
		self.textfield = nil;
		input_request_id = 0;
	}
	return self;
}

- (void) dealloc {
	input_request_id = 0;
	self.textfield = nil;
	self.win = nil;
	[super dealloc];
}

/* The windowview subclasses will override this. */
- (void) updateFromWindowState {
	[NSException raise:@"GlkException" format:@"updateFromWindowState not implemented"];
}

- (void) updateFromWindowSize {
	self.frame = self.win.bbox;
}

- (void) updateFromWindowInputs {
	BOOL wants_input = (win.char_request || win.line_request);
	
	/* The logic here will make more sense if you remember that any *change* in input request -- including a change from char to line input -- will be accompanied by a change in input_request_id. */
	
	if (!wants_input) {
		if (textfield) {
			/* The window doesn't want any input at all. Get rid of the textfield. */
			[textfield removeFromSuperview];
			self.textfield = nil;
			input_request_id = 0;
		}
	}
	
	if (wants_input) {
		if (!textfield) {
			self.textfield = [[[UITextField alloc] initWithFrame:CGRectZero] autorelease];
			textfield.backgroundColor = [UIColor whiteColor];
			textfield.borderStyle = UITextBorderStyleBezel;
			textfield.autocapitalizationType = UITextAutocapitalizationTypeNone;
			textfield.keyboardType = UIKeyboardTypeASCIICapable;
			textfield.delegate = self;
			input_request_id = 0;
		}
		
		if (input_request_id != win.input_request_id) {
			/* Either the text field is brand-new, or last cycle's text field needs to be adjusted for a new request. */
			input_request_id = win.input_request_id;
			input_single_char = win.char_request;
			
			if (win.line_request && win.line_request_initial)
				textfield.text = win.line_request_initial;
			else
				textfield.text = @"";

			/* Bug: changing the returnKeyType in an existing field doesn't change the open keyboard. I don't care right now. */
			if (input_single_char) {
				textfield.returnKeyType = UIReturnKeyDefault;
				textfield.autocorrectionType = UITextAutocorrectionTypeNo;
			}
			else {
				textfield.returnKeyType = UIReturnKeyGo;
				textfield.autocorrectionType = UITextAutocorrectionTypeDefault;
			}
			
			/* This places the field correctly, and adds it as a subview if it isn't already. */
			[self placeInputField:textfield];
		}
	}
}

- (void) placeInputField:(UITextField *)field {
	[NSException raise:@"GlkException" format:@"placeInputField not implemented"];
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)str {
	if (input_single_char) {
		if (str.length) {
			/* We should crunch utf16 characters here. */
			glui32 ch = [str characterAtIndex:(str.length-1)];
			if ([win acceptCharInput:&ch])
				[[GlkAppWrapper singleton] acceptEventType:evtype_CharInput window:win val1:ch val2:0];
		}
		return NO;
	}
	return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
	if (input_single_char) {
		glui32 ch = '\n';
		if ([win acceptCharInput:&ch])
			[[GlkAppWrapper singleton] acceptEventType:evtype_CharInput window:win val1:ch val2:0];
		return NO;
	}
	
	/* Don't look at the text yet; the last word hasn't been spellchecked. However, we don't want to close the keyboard either. The only good answer seems to be to fire a function call with a tiny delay, and return YES to ensure that the spellcheck is accepted. */
	[self performSelector:@selector(textFieldContinueReturn:) withObject:textField afterDelay:0.0];
	return YES;
}

- (void) textFieldContinueReturn:(UITextField *)textField {
	NSLog(@"End editing: '%@'", textField.text);
	if (![[GlkAppWrapper singleton] acceptingEvent]) {
		/* The event must have been filled while we were delaying. Oh well. */
		return;
	}
	
	//### add to command history?
	
	/* buflen might be shorter than the text string, either because the buffer is short or utf16 crunching. */
	int buflen = [win acceptLineInput:textField.text];
	if (buflen < 0) {
		/* This window isn't accepting input. Oh well. */
		return; 
	}
	
	[[GlkAppWrapper singleton] acceptEventType:evtype_LineInput window:win val1:buflen val2:0];
}

@end
